package gemmini

import chisel3._
import chisel3.util._
import chiseltest._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.tile.{TileKey, RocketTileParams, TileVisibilityNodeKey}
import freechips.rocketchip.diplomacy.{AddressSet, LazyModule, LazyModuleImp, TransferSizes}
import freechips.rocketchip.tilelink._
import chipyard.fpga.xcvu13p_gemmini_32x32_packed_inference_ram.XCVU13PGemmini32x32PackedInferenceRamConfigs

/** Real DMA cores and merger, with a test-controlled TileLink memory endpoint. */
class MemoryDmaHarness(prefetch: Int, coalesce: Boolean)(implicit p: Parameters) extends LazyModule {
  // Exercise the archived experiment explicitly, independent of board defaults.
  val config = XCVU13PGemmini32x32PackedInferenceRamConfigs.experimentalMemoryDmaV2Config.copy(
    dma_row_prefetch_entries = prefetch, dma_read_coalescing = coalesce)
  val reader = LazyModule(new StreamReader(config, 32, 256, 64, 256, 1024, 1,
    16384, 2048, 32, false, false))
  val writer = LazyModule(new StreamWriter(32, 256, 64, 1024, 1, SInt(8.W), 32,
    false, false, false, prefetch))
  val xbar = TLXbar()
  val memory = TLManagerNode(Seq(TLSlavePortParameters.v1(Seq(TLSlaveParameters.v1(
    address = Seq(AddressSet(0, 65535)), regionType = freechips.rocketchip.diplomacy.RegionType.UNCACHED,
    supportsGet = TransferSizes(1, 64), supportsPutFull = TransferSizes(1, 64),
    supportsPutPartial = TransferSizes(1, 64))), beatBytes = 32, minLatency = 1)))
  memory := xbar
  xbar := reader.node
  xbar := writer.node
  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val io = IO(new Bundle {
      val readReq = Flipped(Decoupled(chiselTypeOf(reader.module.io.req.bits)))
      val readResp = Decoupled(chiselTypeOf(reader.module.io.resp.bits))
      val writeReq = Flipped(Decoupled(chiselTypeOf(writer.module.io.req.bits)))
      val readBusy = Output(Bool())
      val writeBusy = Output(Bool())
      val mem = new TLBundle(memory.in(0)._1.params)
    })
    io.mem <> memory.in(0)._1
    reader.module.io.req <> io.readReq
    // Include the real first-layer repeater. A merged descriptor has len=64,
    // while this row-level interface is only six bits wide; pixel_repeats=1
    // must still preserve both independent rows and the final completion.
    val raw = reader.module.io.resp
    val pixel = Module(new PixelRepeater(SInt(8.W), config.local_addr_t, 32, 1,
      chiselTypeOf(raw.bits), passthrough=false))
    pixel.io.req.valid := raw.valid
    raw.ready := pixel.io.req.ready
    pixel.io.req.bits.in := raw.bits.data.asTypeOf(Vec(32,SInt(8.W)))
    pixel.io.req.bits.mask := VecInit(raw.bits.mask.take(32))
    pixel.io.req.bits.laddr := raw.bits.addr.asTypeOf(config.local_addr_t)
    pixel.io.req.bits.len := raw.bits.len
    pixel.io.req.bits.pixel_repeats := raw.bits.pixel_repeats
    pixel.io.req.bits.last := raw.bits.last
    pixel.io.req.bits.tag := raw.bits
    io.readResp.valid := pixel.io.resp.valid
    pixel.io.resp.ready := io.readResp.ready
    io.readResp.bits := pixel.io.resp.bits.tag
    io.readResp.bits.addr := pixel.io.resp.bits.laddr.full_sp_addr()
    io.readResp.bits.data := pixel.io.resp.bits.out.asUInt
    io.readResp.bits.mask := VecInit((0 until 128).map(i =>
      if(i<32) pixel.io.resp.bits.mask(i) else false.B))
    io.readResp.bits.last := pixel.io.resp.bits.last
    writer.module.io.req <> io.writeReq
    io.readBusy := reader.module.io.busy || pixel.io.resp.valid
    io.writeBusy := writer.module.io.busy
    reader.module.io.tlb.resp := 0.U.asTypeOf(reader.module.io.tlb.resp)
    writer.module.io.tlb.resp := 0.U.asTypeOf(writer.module.io.tlb.resp)
    reader.module.io.flush := false.B
    writer.module.io.flush := false.B
    reader.module.io.counter.external_reset := false.B
    writer.module.io.counter.external_reset := false.B
  }
}

object MemoryDmaTest extends App {
  // CoreBundle obtains physical address width from negotiated tile visibility.
  val shape = LazyModule(new LazyModule()(Parameters.empty) {
    val visible = TLEphemeralNode()
    val client = TLClientNode(Seq(TLMasterPortParameters.v1(Seq(TLClientParameters(
      name="test-parameters", sourceId=freechips.rocketchip.diplomacy.IdRange(0,32))))))
    val manager = TLManagerNode(Seq(TLSlavePortParameters.v1(Seq(TLSlaveParameters.v1(
      address=Seq(AddressSet(0,65535)), supportsGet=TransferSizes(1,64))), beatBytes=32)))
    manager := visible
    visible := client
    lazy val module = new LazyModuleImp(this) {}
  })
  implicit val p: Parameters = Parameters.empty.alterPartial {
    case TileKey => RocketTileParams()
    case TileVisibilityNodeKey => shape.visible
  }
  val backend = Seq(chiseltest.simulator.IcarusBackendAnnotation)
  def zero(d: Data): Unit = d match {
    case b: Bool => b.poke(false.B)
    case u: UInt => u.poke(0.U)
    case s: SInt => s.poke(0.S)
    case v: Vec[_] => v.foreach(x => zero(x))
    case r: Record => r.elements.values.foreach(zero)
  }
  def reset(d: Module): Unit = { d.reset.poke(true.B); d.clock.step(4); d.reset.poke(false.B) }

  // Distinct attributes, nonadjacent destinations, accumulator requests,
  // misalignment and odd tails must drain as separate descriptors.
  case class Row(addr: Int, dest: Int, cmd: Int = 7, scale: Int = 0,
                 len: Int = 32, acc: Boolean = false, repeat: Int = 0, pixel: Int = 1)
  RawTester.test(new DmaReadCoalescer(16384, 2048, 16, 32, 32, 64), backend) { d =>
    val rows = Vector(Row(0, 0), Row(32, 1), Row(64, 2), Row(96, 3, cmd=8),
      Row(128, 4), Row(160, 5, scale=1), Row(192, 6), Row(224, 8),
      Row(256, 9, acc=true), Row(288, 10), Row(352, 11), Row(384, 12),
      Row(416, 13, len=31), Row(448, 14, repeat=1), Row(480, 15, pixel=2),
      Row(512, 16), Row(544, 17), Row(576, 18))
    val expected = Vector((0,0,64,7,0),(64,2,32,7,0),(96,3,32,8,0),
      (128,4,32,7,0),(160,5,32,7,1),(192,6,32,7,0),(224,8,32,7,0),
      (256,9,32,7,0),(288,10,32,7,0),(352,11,32,7,0),(384,12,32,7,0),
      (416,13,31,7,0),(448,14,32,7,0),(480,15,32,7,0),
      (512,16,64,7,0),(576,18,32,7,0))
    zero(d.io.in.bits); d.io.in.valid.poke(false.B); d.io.out.ready.poke(false.B); reset(d)
    var sent = 0
    var received = Vector.empty[(Int,Int,Int,Int,Int)]
    for (cycle <- 0 until 180) {
      if(sent < rows.size) {
        val r = rows(sent); zero(d.io.in.bits)
        d.io.in.bits.vaddr.poke(r.addr.U); d.io.in.bits.spaddr.poke(r.dest.U)
        d.io.in.bits.cmd_id.poke(r.cmd.U); d.io.in.bits.scale.poke(r.scale.U)
        d.io.in.bits.len.poke(r.len.U); d.io.in.bits.is_acc.poke(r.acc.B)
        d.io.in.bits.repeats.poke(r.repeat.U); d.io.in.bits.pixel_repeats.poke(r.pixel.U)
        d.io.in.bits.block_stride.poke(32.U); d.io.in.valid.poke(true.B)
      } else d.io.in.valid.poke(false.B)
      d.io.out.ready.poke((cycle > 8 && cycle % 7 != 2 && cycle % 7 != 3).B)
      if(d.io.in.valid.peek().litToBoolean && d.io.in.ready.peek().litToBoolean) sent += 1
      if(d.io.out.valid.peek().litToBoolean && d.io.out.ready.peek().litToBoolean) {
        val b=d.io.out.bits
        received :+= ((b.vaddr.peek().litValue.toInt,b.spaddr.peek().litValue.toInt,
          b.len.peek().litValue.toInt,b.cmd_id.peek().litValue.toInt,b.scale.peek().litValue.toInt))
      }
      d.clock.step()
    }
    assert(received == expected, s"Coalescer changed order/payload: $received")
    d.io.busy.expect(false.B)
  }

  // Compare hazard visibility against an independent acceptance-order model,
  // including pointer wrap, stalls, partial masks and simultaneous push/pop.
  for (depth <- Seq(2,4)) RawTester.test(new OrderedBankWrites(6, 256, depth), backend) { d =>
    val rng = new scala.util.Random(1900 + depth)
    var pending = Vector.empty[(Int,BigInt,Boolean,BigInt)]
    zero(d.io.enq.bits); d.io.enq.valid.poke(false.B); d.io.deq.ready.poke(false.B)
    d.io.readAddr.poke(0.U); reset(d)
    for(cycle <- 0 until 600) {
      val addr=rng.nextInt(8); val ex=rng.nextBoolean()
      val data=BigInt(256,rng); val mask=BigInt(32,rng)
      d.io.enq.valid.poke((cycle < 550 && rng.nextInt(4)!=0).B)
      d.io.enq.bits.addr.poke(addr.U); d.io.enq.bits.ex.poke(ex.B)
      d.io.enq.bits.data.poke(data.U)
      for(i <- 0 until 32) d.io.enq.bits.mask(i).poke(mask.testBit(i).B)
      d.io.deq.ready.poke((cycle >= 550 || rng.nextBoolean()).B)
      val rd=rng.nextInt(8); d.io.readAddr.poke(rd.U)
      val push=d.io.enq.valid.peek().litToBoolean && d.io.enq.ready.peek().litToBoolean
      val pop=d.io.deq.valid.peek().litToBoolean && d.io.deq.ready.peek().litToBoolean
      d.io.readHazard.expect((pending.exists(_._1==rd) || (push && addr==rd)).B)
      d.io.exPending.expect(pending.exists(_._3).B)
      if(pop) {
        val (a,v,e,m)=pending.head
        d.io.deq.bits.addr.expect(a.U); d.io.deq.bits.data.expect(v.U); d.io.deq.bits.ex.expect(e.B)
        for(i <- 0 until 32) d.io.deq.bits.mask(i).expect(m.testBit(i).B)
        pending=pending.tail
      }
      if(push) pending :+= ((addr,data,ex,mask))
      d.clock.step()
    }
    assert(pending.isEmpty)
  }
  RawTester.test(new BoundedExPriority(3), backend) { d =>
    d.io.exValid.poke(true.B); d.io.dmaValid.poke(true.B); d.io.fire.poke(false.B); reset(d)
    for(access <- 0 until 24) {
      d.io.chooseEx.expect((access%4 != 3).B)
      d.io.fire.poke(false.B); d.clock.step(2)
      d.io.chooseEx.expect((access%4 != 3).B)
      d.io.fire.poke(true.B); d.clock.step()
    }
  }
  // Exercise actual single-port storage: competing writes must not erase a
  // read, and read response stalls must not corrupt the following request.
  RawTester.test(new ScratchpadBank(64,256,1,true,false,false,3), backend) { d =>
    d.io.read.req.valid.poke(false.B); d.io.read.resp.ready.poke(true.B)
    d.io.write.valid.poke(false.B); d.io.write.addr.poke(0.U); d.io.write.data.poke(0.U)
    d.io.write.mask.foreach(_.poke(true.B)); reset(d)
    d.io.write.valid.poke(true.B); d.io.write.data.poke(123.U); d.clock.step()
    d.io.write.addr.poke(1.U); d.io.write.data.poke(456.U)
    d.io.read.req.valid.poke(true.B); d.io.read.req.bits.addr.poke(0.U)
    d.io.read.req.bits.fromDMA.poke(true.B)
    var reads=0; var responses=0; var writes=0
    for(cycle <- 0 until 60) {
      d.io.read.resp.ready.poke((cycle%9 != 4 && cycle%9 != 5).B)
      val rd=d.io.read.req.ready.peek().litToBoolean
      val wr=d.io.write.ready.peek().litToBoolean
      assert(!(rd && wr), "Single-port read and write overlapped")
      if(rd) reads += 1
      if(wr) writes += 1
      if(d.io.read.resp.valid.peek().litToBoolean && d.io.read.resp.ready.peek().litToBoolean) {
        d.io.read.resp.bits.data.expect(123.U); d.io.read.resp.bits.fromDMA.expect(true.B); responses+=1
      }
      d.clock.step()
    }
    assert(reads>=10 && responses>=9 && writes>=25, s"Port arbitration starved: $reads/$writes/$responses")
  }
  println("MEMORY_DMA_HELPERS=PASS coalescing_guards odd_tail backpressure ordered_RAW fairness single_port")

  case class Reply(source: BigInt, size: Int, data: Vector[BigInt], opcode: Int)
  def pattern(addr: Int): Int = (addr * 13 + 5) & 255
  def word(addr: Int, bytes: Int): BigInt = (0 until bytes).foldLeft(BigInt(0))(
    (v,i) => v | (BigInt(pattern(addr+i)) << (8*i)))
  var measurements = Vector.empty[(Int,Boolean,Int,Int,Int)]
  for((prefetch,coalesce) <- Seq((0,false),(4,false),(4,true))) {
    val top=LazyModule(new MemoryDmaHarness(prefetch,coalesce))
    RawTester.test(top.module, backend) { d =>
      zero(d.io.readReq.bits); zero(d.io.writeReq.bits)
      zero(d.io.mem.d.bits)
      d.io.mem.d.valid.poke(false.B)
      d.io.mem.a.ready.poke(true.B)
      d.io.readReq.valid.poke(false.B); d.io.writeReq.valid.poke(false.B)
      d.io.readResp.ready.poke(true.B); reset(d)
      var replies = Vector.empty[Reply]
      var active: Option[(Reply,Int)] = None
      var returns = Map.empty[Int,BigInt]
      var returnedBytes=0
      var getCycles=Vector.empty[Int]
      var putCycles=Vector.empty[Int]
      var written=Map.empty[Int,Int]
      var writeBeat=Map.empty[BigInt,Int]
      var cycle=0
      var permitReturns=false
      var stalls=false
      def tick(): Unit = {
        d.io.mem.a.ready.poke((!stalls || cycle%7 != 3).B)
        d.io.readResp.ready.poke((!stalls || cycle%11 < 7).B)
        if(active.isEmpty && permitReturns && replies.nonEmpty && (!stalls || cycle%5 != 1)) {
          active=Some((replies.last,0)); replies=replies.dropRight(1)
        }
        d.io.mem.d.valid.poke(active.nonEmpty.B)
        active.foreach { case(r,beat) =>
          zero(d.io.mem.d.bits)
          d.io.mem.d.bits.opcode.poke(r.opcode.U); d.io.mem.d.bits.source.poke(r.source.U)
          d.io.mem.d.bits.size.poke(r.size.U); d.io.mem.d.bits.data.poke(r.data(beat).U)
        }
        if(d.io.mem.a.valid.peek().litToBoolean && d.io.mem.a.ready.peek().litToBoolean) {
          val a=d.io.mem.a.bits
          val op=a.opcode.peek().litValue.toInt; val size=a.size.peek().litValue.toInt
          val source=a.source.peek().litValue; val addr=a.address.peek().litValue.toInt
          val beats=(1 << size)/32 max 1
          if(op==4) {
            getCycles :+= cycle
            replies :+= Reply(source,size,Vector.tabulate(beats)(i=>word(addr+i*32,32)),1)
          } else {
            assert(op==0 || op==1, s"Unexpected TL operation $op")
            putCycles :+= cycle
            val beat=writeBeat.getOrElse(source,0)
            val mask=a.mask.peek().litValue; val data=a.data.peek().litValue
            for(i <- 0 until 32 if mask.testBit(i)) written += ((addr+beat*32+i)->((data>>(8*i))&255).toInt)
            if(beat==beats-1) {
              writeBeat -= source; replies :+= Reply(source,size,Vector(BigInt(0)),0)
            } else writeBeat += source -> (beat+1)
          }
        }
        if(d.io.mem.d.valid.peek().litToBoolean && d.io.mem.d.ready.peek().litToBoolean) {
          val (r,beat)=active.get
          if(beat==r.data.size-1) active=None else active=Some((r,beat+1))
        }
        if(d.io.readResp.valid.peek().litToBoolean && d.io.readResp.ready.peek().litToBoolean) {
          val b=d.io.readResp.bits
          val addr=b.addr.peek().litValue.toInt
          assert(!returns.contains(addr), s"Duplicate DMA row $addr")
          returns += addr -> (b.data.peek().litValue & ((BigInt(1)<<256)-1))
          b.cmd_id.expect(1.U)
          // The unified response has accumulator-width metadata. Scratchpad
          // storage consumes only the low 32 byte lanes of each emitted row.
          for(i <- 0 until 32) b.mask(i).expect(true.B)
          if(b.last.peek().litToBoolean) returnedBytes += b.bytes_read.peek().litValue.toInt
        }
        d.clock.step(); cycle += 1
      }
      // Hold all memory responses until requests are issued, then respond in
      // reverse transaction order, with stalls on both A and scratchpad output.
      var sent=0
      while(getCycles.size < (if(coalesce)12 else 24) && cycle<200) {
        d.io.readReq.valid.poke((sent<24).B)
        if(sent<24) {
          d.io.readReq.bits.vaddr.poke((sent*32).U)
          d.io.readReq.bits.spaddr.poke(sent.U); d.io.readReq.bits.len.poke(32.U)
          d.io.readReq.bits.pixel_repeats.poke(1.U); d.io.readReq.bits.block_stride.poke(32.U)
          d.io.readReq.bits.cmd_id.poke(1.U)
        }
        val accept=sent<24 && d.io.readReq.ready.peek().litToBoolean
        tick(); if(accept) sent += 1
      }
      assert(sent==24 && getCycles.size==(if(coalesce)12 else 24))
      d.io.readReq.valid.poke(false.B); permitReturns=true; stalls=true
      while((returns.size<24 || d.io.readBusy.peek().litToBoolean) && cycle<1000) tick()
      assert(returns.size==24 && returnedBytes==24*32, s"Missing/scattered rows or completion: ${returns.size}/$returnedBytes")
      for(i <- 0 until 24) assert(returns(i)==word(i*32,32), s"Incorrect row $i")
      d.io.readBusy.expect(false.B)
      // Writer payloads are queued while the active request is stalled.
      // The initial burst also checks whether the idle bubble was removed.
      stalls=false; permitReturns=false; sent=0
      val start=cycle
      while(putCycles.size<24 && cycle<start+200) {
        d.io.writeReq.valid.poke((sent<24).B)
        if(sent<24) {
          d.io.writeReq.bits.vaddr.poke((4096+sent*32).U)
          d.io.writeReq.bits.len.poke(32.U); d.io.writeReq.bits.data.poke(word(sent*32,32).U)
          d.io.writeReq.bits.store_en.poke(true.B)
        }
        val accept=sent<24 && d.io.writeReq.ready.peek().litToBoolean
        tick(); if(accept) sent+=1
      }
      assert(sent==24 && putCycles.size==24)
      d.io.writeReq.valid.poke(false.B); stalls=true; permitReturns=true
      while(d.io.writeBusy.peek().litToBoolean && cycle<start+700) tick()
      d.io.writeBusy.expect(false.B)
      for(i <- 0 until 24*32) assert(written(4096+i)==pattern(i), s"Writer overwrote prefetched row byte $i")
      // Multi-block gathering and a 128-byte full accumulator row, including
      // unaligned partial writes, must preserve masked bytes under A stalls.
      val extra=Vector((8192,0,32,false,word(0,32)),(8192,1,32,true,word(32,32)),
        (8448,0,128,true,word(128,128)),(8707,0,17,true,word(256,17)))
      var n=0; val extraStart=cycle
      while(n<extra.size && cycle<extraStart+400) {
        val (addr,block,len,store,data)=extra(n)
        d.io.writeReq.valid.poke(true.B); d.io.writeReq.bits.vaddr.poke(addr.U)
        d.io.writeReq.bits.block.poke(block.U); d.io.writeReq.bits.len.poke(len.U)
        d.io.writeReq.bits.data.poke(data.U); d.io.writeReq.bits.store_en.poke(store.B)
        val accept=d.io.writeReq.ready.peek().litToBoolean
        tick(); if(accept)n+=1
      }
      assert(n==extra.size)
      d.io.writeReq.valid.poke(false.B)
      while(d.io.writeBusy.peek().litToBoolean && cycle<extraStart+1000) tick()
      d.io.writeBusy.expect(false.B)
      for(i <- 0 until 64) assert(written(8192+i)==pattern(i), s"Block gathering byte $i")
      for(i <- 0 until 128) assert(written(8448+i)==pattern(128+i), s"Accumulator byte $i")
      for(i <- 0 until 17) assert(written(8707+i)==pattern(256+i), s"Partial byte $i")
      assert(!written.contains(8706) && !written.contains(8724), "Partial write changed masked bytes")
      val readSpan=getCycles.last-getCycles.head
      val writeSpan=putCycles(23)-putCycles.head
      measurements :+= ((prefetch,coalesce,getCycles.size,readSpan,writeSpan))
      println(s"DMA_CASE=PASS prefetch=$prefetch coalesce=$coalesce reads=${getCycles.size} read_span=$readSpan write_span=$writeSpan")
      if(prefetch==4 && coalesce) {
        // More than 32 transactions, concurrent read/write, an odd read tail,
        // and a long memory stall exercise credit exhaustion and source reuse.
        var rs=0; var ws=0
        val streamStart=cycle
        val getBefore=getCycles.size
        permitReturns=false
        while((rs<65 || ws<40 || d.io.readBusy.peek().litToBoolean ||
          d.io.writeBusy.peek().litToBoolean) && cycle<streamStart+3000) {
          permitReturns=cycle-streamStart>=130
          d.io.readReq.valid.poke((rs<65).B)
          if(rs<65) {
            d.io.readReq.bits.vaddr.poke((12288+rs*32).U)
            d.io.readReq.bits.spaddr.poke((128+rs).U)
          }
          d.io.writeReq.valid.poke((ws<40).B)
          if(ws<40) {
            d.io.writeReq.bits.vaddr.poke((16384+ws*32).U)
            d.io.writeReq.bits.block.poke(0.U); d.io.writeReq.bits.len.poke(32.U)
            d.io.writeReq.bits.data.poke(word(ws*32,32).U)
            d.io.writeReq.bits.store_en.poke(true.B)
          }
          val ra=rs<65 && d.io.readReq.ready.peek().litToBoolean
          val wa=ws<40 && d.io.writeReq.ready.peek().litToBoolean
          tick(); if(ra)rs+=1; if(wa)ws+=1
        }
        assert(rs==65 && ws==40 && returns.size==89 && returnedBytes==(24+65)*32)
        assert(getCycles.size-getBefore==33, "Odd tail must remain a single 32-byte read")
        for(i <- 0 until 65) assert(returns(128+i)==word(12288+i*32,32))
        for(i <- 0 until 40*32) assert(written(16384+i)==pattern(i))
        d.io.readBusy.expect(false.B); d.io.writeBusy.expect(false.B)
        println("DMA_STREAM=PASS rows_read=65 rows_written=40 stall_cycles=130 source_reuse concurrent odd_tail")
      }
    }
  }
  assert(measurements(1)._4 < measurements(0)._4 && measurements(1)._5 < measurements(0)._5,
    s"Prefetch did not remove row bubbles: $measurements")
  assert(measurements(2)._3 == measurements(0)._3/2, s"Compatible reads did not merge: $measurements")
  println("MEMORY_DMA_INTEGRATION=PASS payload masks scatter completion out_of_order multiblock accumulator partial prefetch")
}
