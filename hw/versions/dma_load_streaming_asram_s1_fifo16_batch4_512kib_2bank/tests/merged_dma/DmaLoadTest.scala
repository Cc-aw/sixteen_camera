package gemmini

import chisel3._
import chisel3.util._
import chiseltest._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.tile.{TileKey, RocketTileParams, TileVisibilityNodeKey}
import freechips.rocketchip.diplomacy.{AddressSet, LazyModule, LazyModuleImp, IdRange, TransferSizes}
import freechips.rocketchip.tilelink._
import chipyard.fpga.xcvu13p_gemmini_32x32_packed_inference_ram.XCVU13PGemmini32x32PackedInferenceRamConfigs

object DmaLoadTest extends App {
  val shape = LazyModule(new LazyModule()(Parameters.empty) {
    val visible = TLEphemeralNode()
    val client = TLClientNode(Seq(TLMasterPortParameters.v1(Seq(TLClientParameters(
      name="dma-load-test", sourceId=IdRange(0, 32))))))
    val manager = TLManagerNode(Seq(TLSlavePortParameters.v1(Seq(TLSlaveParameters.v1(
      address=Seq(AddressSet(BigInt("80000000",16), BigInt("7fffffff",16))),
      supportsGet=TransferSizes(1,64))), beatBytes=32)))
    manager := visible; visible := client
    lazy val module = new LazyModuleImp(this) {}
  })
  implicit val p: Parameters = Parameters.empty.alterPartial {
    case TileKey => RocketTileParams()
    case TileVisibilityNodeKey => shape.visible
  }
  val backend = Seq(chiseltest.simulator.IcarusBackendAnnotation)
  def zero(data: Data): Unit = data match {
    case e: NormCmd.Type => e.poke(NormCmd.RESET)
    case b: Bool => b.poke(false.B)
    case u: UInt => u.poke(0.U)
    case s: SInt => s.poke(0.S)
    case v: Vec[_] => v.foreach(zero)
    case r: Record => r.elements.values.foreach(zero)
  }
  def reset(d: Module): Unit = { d.reset.poke(true.B); d.clock.step(4); d.reset.poke(false.B) }
  val cfg = XCVU13PGemmini32x32PackedInferenceRamConfigs.config.copy(dma_load_runtime_enable=true, dma_load_streaming_enable=true)

  RawTester.test(new DmaLoadReadPlanner(40), backend) { d =>
    var cases = 0
    for(c <- Seq(1,2,3,4,7,8,12,15,16,24,31); n <- Seq(1,2,3,31,32); r <- 0 until 64) {
      var address = BigInt("80000fc0",16) + r
      var left = c*n
      while(left > 0) {
        val choices = Seq(32,64).map(w => (math.min(left,w-(address%w).toInt),w))
        val expected = choices.maxBy(x => (x._1,-x._2))
        d.io.address.poke(address.U); d.io.remaining.poke(left.U)
        d.io.legal.expect(true.B); d.io.bytes.expect(expected._1.U)
        d.io.size.expect(log2Ceil(expected._2).U)
        address += expected._1; left -= expected._1
      }
      cases += 1
    }
    d.io.address.poke("h180000000".U); d.io.remaining.poke(32.U); d.io.legal.expect(false.B)
    println(s"DMA_LOAD_PLANNER_PASS,cases=$cases")
  }

  RawTester.test(new DmaLoadRowAssembler(SInt(8.W), cfg.local_addr_t, 32, cfg.mvin_scale_t_bits), backend) { d =>
    val rng = new scala.util.Random(161028)
    zero(d.io.in.bits); d.io.in.valid.poke(false.B); d.io.out.ready.poke(false.B); reset(d)
    var cases = 0
    for(c <- 1 to 32; n <- Seq(1,2,3,31,32);
        pixels <- 1 to (32/c);
        start <- Seq(0, 2, 64, cfg.local_addr_t.spRows/2, cfg.local_addr_t.spRows/2+2)) {
      val samples = Vector.fill(n)(Vector.fill(c)(rng.nextInt(256)))
      val low = if(start < cfg.local_addr_t.spRows/2) 0 else cfg.local_addr_t.spRows/2
      val addresses = (math.max(low,start-pixels+1) until start+n).toVector
      val original = addresses.map(a => a -> Array.fill(32)(0xa5)).toMap
      // Golden follows the original per-input/reverse-repeat mapping only.
      for(i <- samples.indices; k <- (0 until pixels).reverse if start+i-k >= low;
          j <- 0 until c) original(start+i-k)(k*c+j) = samples(i)(j)
      val actual = addresses.map(a => a -> Array.fill(32)(0xa5)).toMap
      var sent = 0; var received = 0; var finals = 0; var cycles = 0
      var stalled: Option[(BigInt,BigInt,BigInt,Boolean)] = None
      while((sent < n || finals == 0 || d.io.busy.peek().litToBoolean) && cycles < 600) {
        zero(d.io.in.bits)
        d.io.in.valid.poke((sent < n && (cycles%7 != 2)).B)
        if(sent < n) {
          d.io.in.bits.len.poke(c.U); d.io.in.bits.pixel_repeats.poke(pixels.U)
          d.io.in.bits.laddr.data.poke((start+sent).U)
          d.io.in.bits.tag.group_first.poke((sent==0).B)
          d.io.in.bits.tag.group_last.poke((sent==n-1).B)
          for(j <- 0 until 32) {
            // Deliberately dirty unmasked high bytes.
            val value = if(j<c) samples(sent)(j) else 0x7f
            d.io.in.bits.in(j).poke((if(value>=128)value-256 else value).S)
            d.io.in.bits.mask(j).poke((j<c).B)
          }
        }
        d.io.out.ready.poke((cycles%11!=0 && cycles%11!=1 && cycles%11!=2).B)
        val valid = d.io.out.valid.peek().litToBoolean
        val ready = d.io.out.ready.peek().litToBoolean
        if(valid) {
          val token = (d.io.out.bits.laddr.data.peek().litValue,
            d.io.out.bits.out.zipWithIndex.map { case (v,j) => (v.peek().litValue & 255) << (8*j) }.reduce(_|_),
            d.io.out.bits.mask.zipWithIndex.map { case (v,j) => v.peek().litValue << j }.reduce(_|_),
            d.io.out.bits.last.peek().litToBoolean)
          stalled.foreach(s => assert(s==token,"unstable stalled assembly token"))
          stalled = if(ready) None else Some(token)
          if(ready) {
            val (address,data,mask,last)=token
            assert(actual.contains(address.toInt),s"unexpected destination $address")
            for(j <- 0 until 32 if mask.testBit(j)) actual(address.toInt)(j)=((data>>(8*j))&255).toInt
            received += 1; if(last) finals += 1
          }
        } else { assert(stalled.isEmpty,"lost stalled assembly token") }
        if(d.io.in.valid.peek().litToBoolean && d.io.in.ready.peek().litToBoolean) sent += 1
        d.clock.step(); cycles += 1
      }
      assert(sent==n && finals==1 && received==addresses.size,s"tail/count c=$c n=$n p=$pixels a=$start")
      for(a <- addresses) assert(actual(a).sameElements(original(a)),s"SPAD mismatch c=$c n=$n p=$pixels a=$a")
      d.io.in.valid.poke(false.B); d.clock.step(3); cases += 1
    }
    println(s"DMA_LOAD_ASSEMBLER_PASS,cases=$cases,poison=checked,tails=checked,backpressure=checked")
  }

  for (mode <- Seq(2)) RawTester.test(new DmaLoadGroup(cfg.copy(dma_load_streaming_enable=true)), backend) { d =>
    case class Command(c: Int, n: Int, p: Int, stride: Int, zeros: Boolean=false)
    val commands = Vector(Command(3,32,6,3), Command(16,31,2,16), Command(12,3,2,29),
      Command(3,1,6,3,true),Command(7,32,4,7),Command(31,2,1,31),Command(16,32,1,16),
      Command(3,3,6,3),Command(16,1,2,16,true),Command(1,32,32,1))
    val rng = new scala.util.Random(162816)
    def memory(a: BigInt): Int = ((a*13+(a>>3)*7)&255).toInt
    zero(d.io.in.bits); zero(d.io.fragment.bits); zero(d.io.completed.bits)
    d.io.in.valid.poke(false.B); d.io.fragment.valid.poke(false.B)
    d.io.completed.valid.poke(false.B); d.io.request.ready.poke(false.B); d.io.replay.ready.poke(false.B)
    d.io.readerFault.poke(false.B); d.io.mode.poke(mode.U); d.io.counter.external_reset.poke(false.B); reset(d)
    // One P=1 row has no neighboring request to merge. Keep it on legacy.
    d.io.in.bits.vaddr.poke("h80000000".U);d.io.in.bits.cols.poke(16.U)
    d.io.in.bits.cmd_rows.poke(1.U);d.io.in.bits.cmd_stride_bytes.poke(16.U)
    d.io.in.bits.pixel_repeats.poke(1.U);d.io.eligible.expect(false.B)
    var command = 0; var row = 0; var emittedCommand = 0; var emittedRow = 0; var completed = 0
    var fragments = Vector.empty[(Int,Int,Int,BigInt,Boolean)]
    var credits = Vector.empty[(Int,Int,Int)]
    var cycles = 0
    var firstCommandGets = 0
    while((completed < commands.size || d.io.busy.peek().litToBoolean) && cycles < 8000) {
      zero(d.io.in.bits)
      d.io.in.valid.poke((command < commands.size).B)
      if(command < commands.size) {
        val c=commands(command); val b=d.io.in.bits
        b.vaddr.poke((if(c.zeros)BigInt(row*c.stride) else BigInt("80000ffb",16)+command*8192+row*c.stride).U)
        b.laddr.data.poke((64+row).U); b.cols.poke(c.c.U); b.pixel_repeats.poke(c.p.U)
        b.cmd_id.poke((command%2).U); b.scale.poke("h3c00".U); b.block_stride.poke(32.U)
        b.cmd_rows.poke(c.n.U); b.row_index.poke(row.U); b.cmd_stride_bytes.poke(c.stride.U)
        b.cmd_first.poke((row==0).B); b.cmd_last.poke((row==c.n-1).B); b.all_zeros.poke(c.zeros.B)
      }
      d.io.request.ready.poke((cycles%5!=1).B)
      d.io.replay.ready.poke((cycles%7!=0 && cycles%7!=1).B)
      d.io.fragment.valid.poke(fragments.nonEmpty.B)
      zero(d.io.fragment.bits)
      if(fragments.nonEmpty) {
        val (g,offset,n,data,last)=fragments.head
        d.io.fragment.bits.group_id.poke(g.U); d.io.fragment.bits.offset.poke(offset.U)
        d.io.fragment.bits.transaction_last.poke(last.B); d.io.fragment.bits.bytes.poke(n.U); d.io.fragment.bits.data.poke(data.U)
      }
      d.io.completed.valid.poke((credits.nonEmpty && credits.head._1<=cycles).B)
      zero(d.io.completed.bits)
      if(credits.nonEmpty) {
        d.io.completed.bits.group_id.poke(credits.head._2.U)
        d.io.completed.bits.bytes.poke(credits.head._3.U)
      }
      if(d.io.completed.valid.peek().litToBoolean) { credits=credits.tail; completed+=1 }
      if(d.io.fragment.valid.peek().litToBoolean && d.io.fragment.ready.peek().litToBoolean) fragments=fragments.tail
      if(d.io.request.valid.peek().litToBoolean && d.io.request.ready.peek().litToBoolean) {
        val b=d.io.request.bits
        val address=b.vaddr.peek().litValue
        if(address < BigInt("80000ffb",16)+8192) firstCommandGets += 1
        if(mode==3) {
          val offset=b.group_offset.peek().litValue.toInt
          // Look up accepted command identity via its unique address region.
          val ci=((address-BigInt("80000ffb",16))/8192).toInt
          val c=commands(ci)
          assert(b.len.peek().litValue <= c.c-offset%c.c,
            "SPAD-only request crossed a logical row")
        }
        val owner=b.group_id.peek().litValue.toInt
        var offset=b.group_offset.peek().litValue.toInt
        var left=b.len.peek().litValue.toInt
        var a=address
        var transaction=Vector.empty[(Int,Int,Int,BigInt,Boolean)]
        while(left>0) {
          val n=math.min(left,32-(a%32).toInt)
          val data=(0 until n).map(j => BigInt(memory(a+j))<<(j*8)).reduce(_|_)
          transaction :+= ((owner,offset,n,data,left==n)); offset+=n; a+=n; left-=n
        }
        // Return newer physical transactions first at random boundaries.
        if(rng.nextBoolean()) fragments=transaction++fragments else fragments=fragments++transaction
      }
      if(d.io.replay.valid.peek().litToBoolean && d.io.replay.ready.peek().litToBoolean) {
        val b=d.io.replay.bits; val c=commands(emittedCommand)
        b.assembled.expect(true.B)
        b.cmd_id.expect((emittedCommand%2).U); b.len.expect(c.c.U)
        b.addr.expect((64+emittedRow).U); b.group_first.expect((emittedRow==0).B)
        b.group_last.expect((emittedRow==c.n-1).B)
        val data=b.data.peek().litValue
        for(j <- 0 until 128) b.mask(j).expect((j<c.c).B)
        for(j <- 0 until 32) {
          val expected=if(c.zeros || j>=c.c)0 else memory(BigInt("80000ffb",16)+emittedCommand*8192+emittedRow*c.stride+j)
          assert(((data>>(j*8))&255)==expected,s"group replay cmd=$emittedCommand row=$emittedRow byte=$j")
        }
        emittedRow+=1
        if(emittedRow==c.n) {
          credits :+= ((cycles+9,b.group_id.peek().litValue.toInt,c.c*c.n))
          emittedCommand+=1; emittedRow=0
        }
      }
      if(d.io.in.valid.peek().litToBoolean && d.io.in.ready.peek().litToBoolean) {
        row+=1
        if(row==commands(command).n) { command+=1; row=0 }
      }
      d.io.fault.expect(false.B); d.clock.step(); cycles+=1
    }
    assert(completed==commands.size && emittedCommand==commands.size && fragments.isEmpty)
    assert(firstCommandGets == (if(mode==2)3 else 33),s"read ablation count $firstCommandGets mode=$mode")
    // Unowned response must fault and hold busy, never complete a recycled ID.
    d.io.completed.valid.poke(false.B)
    zero(d.io.fragment.bits); d.io.fragment.bits.bytes.poke(1.U)
    d.io.fragment.valid.poke(true.B); d.clock.step(); d.io.fragment.valid.poke(false.B)
    d.io.fault.expect(true.B); d.io.busy.expect(true.B)
    println(s"DMA_LOAD_GROUP_PASS,mode=$mode,first_command_gets=$firstCommandGets,commands=$completed,contexts=2,id_reuse=checked,reordered_returns=checked,fault=checked")
  }

  // Independent acceptance-order ledger, including mixed EX/DMA/zero writes,
  // partial masks, pointer wrap and the new nonEmpty drain observation.
  for (depth <- Seq(2,4)) RawTester.test(new OrderedBankWrites(6,256,depth),backend) { d =>
    val rng=new scala.util.Random(163200+depth)
    var pending=Vector.empty[(Int,BigInt,BigInt,Boolean,Boolean)]
    zero(d.io.enq.bits);d.io.enq.valid.poke(false.B);d.io.deq.ready.poke(false.B)
    d.io.readAddr.poke(0.U);reset(d)
    for(cycle <- 0 until 800) {
      val addr=rng.nextInt(8);val data=BigInt(256,rng);val mask=BigInt(32,rng)
      val ex=rng.nextBoolean();val isZero = !ex && rng.nextBoolean()
      d.io.enq.valid.poke((cycle<700 && rng.nextInt(4)!=0).B)
      d.io.enq.bits.addr.poke(addr.U);d.io.enq.bits.data.poke(data.U)
      d.io.enq.bits.ex.poke(ex.B);d.io.enq.bits.zero.poke(isZero.B)
      for(i <- 0 until 32)d.io.enq.bits.mask(i).poke(mask.testBit(i).B)
      d.io.deq.ready.poke((cycle>=700 || rng.nextBoolean()).B)
      val read=rng.nextInt(8);d.io.readAddr.poke(read.U)
      val push=d.io.enq.valid.peek().litToBoolean && d.io.enq.ready.peek().litToBoolean
      val pop=d.io.deq.valid.peek().litToBoolean && d.io.deq.ready.peek().litToBoolean
      d.io.nonEmpty.expect(pending.nonEmpty.B)
      d.io.readHazard.expect((pending.exists(_._1==read) || push && addr==read).B)
      d.io.exPending.expect(pending.exists(_._4).B)
      if(pop) {
        val (a,v,m,e,z)=pending.head
        d.io.deq.bits.addr.expect(a.U);d.io.deq.bits.data.expect(v.U)
        d.io.deq.bits.ex.expect(e.B);d.io.deq.bits.zero.expect(z.B)
        for(i <- 0 until 32)d.io.deq.bits.mask(i).expect(m.testBit(i).B)
        pending=pending.tail
      }
      if(push)pending :+= ((addr,data,mask,ex,isZero))
      d.clock.step()
    }
    assert(pending.isEmpty);d.io.nonEmpty.expect(false.B)
  }
  println("DMA_LOAD_BANK_QUEUE_PASS,cycles=1600,masks=checked,RAW_WAW=checked,drain=checked")

  RawTester.test(new CounterController(8,32),backend) { d =>
    zero(d.io.in.bits);d.io.in.valid.poke(false.B);d.io.out.ready.poke(true.B)
    zero(d.io.event_io.event_signal);zero(d.io.event_io.external_values);reset(d)
    def access(option: BigInt): BigInt = {
      d.io.in.bits.rs1.poke(option.U);d.io.in.valid.poke(true.B)
      d.io.in.ready.expect(true.B);d.clock.step();d.io.in.valid.poke(false.B)
      d.io.out.valid.expect(true.B);val result=d.io.out.bits.data.peek().litValue
      d.clock.step();result
    }
    for(id <- 8 to 34) {
      val expected=BigInt("fedc0000",16)+id
      d.io.event_io.external_values(id).poke(expected.U)
      access(BigInt("80000008",16)+(id<<12))
      assert(access(0)==expected,s"external counter address $id truncated")
    }
    access(4) // Hold a snapshot, then verify release before reconfiguration.
    val old=access(0);d.io.event_io.external_values(34).poke(12345.U)
    assert(access(0)==old);access(2);assert(access(0)==12345)
    println("DMA_LOAD_COUNTER_ABI_PASS,external_ids=8..34,snapshot_release=checked")
  }

  RawTester.test(new freechips.rocketchip.tile.commandfrontend.CommandFrontendCluster(
      allowTargetExtensions=true, dmaLoadBuildId=BigInt("123456789abcdef0",16)), backend) { d =>
    zero(d.io.control_funct); zero(d.io.control_rs1); zero(d.io.control_rs2); zero(d.io.control_rd)
    d.io.control_valid.poke(false.B); d.io.control_xd.poke(true.B); d.io.control_prv.poke(3.U)
    d.io.response_ready.poke(true.B)
    d.io.legacy_valid.poke(0.U); d.io.legacy_funct.poke(0.U); d.io.legacy_rs1.poke(0.U); d.io.legacy_rs2.poke(0.U)
    d.io.gemmini_cmd_ready.poke(7.U); d.io.gemmini_busy.poke(0.U); d.io.gemmini_fault.poke(0.U)
    d.io.mem_req_ready.poke(0.U); d.io.mem_resp_valid.poke(0.U)
    d.io.mem_resp_data.poke(0.U); d.io.mem_resp_error.poke(0.U)
    for(i <- 0 until 3) d.io.dma_load_capabilities(i).poke("h10004".U)
    reset(d)
    def control(lane: Int, op: Int, a: BigInt=0, b: BigInt=0, expected: BigInt=0): Unit = {
      d.io.control_funct.poke(((lane<<5)|op).U); d.io.control_rs1.poke(a.U); d.io.control_rs2.poke(b.U)
      d.io.control_valid.poke(true.B); d.io.control_ready.expect(true.B); d.clock.step()
      d.io.control_valid.poke(false.B); d.io.response_valid.expect(true.B)
      d.io.response_data.expect(expected.U); d.clock.step()
    }
    for(i <- 0 until 3) { d.io.dma_load_mode(i).expect(2.U); control(i,3,7,expected=0x10004) }
    control(0,3,10,expected=BigInt("123456789abcdef0",16))
    for(mode <- Seq(0,1,2,3); lane <- 0 until 3) {
      control(lane,9,mode,expected=if(mode==2)0 else 2); control(lane,3,8,expected=2)
    }
    control(0,9,3,expected=2); control(0,9,1,1,expected=2)
    d.io.gemmini_busy.poke(1.U); control(0,9,2,expected=1); d.io.gemmini_busy.poke(0.U)
    d.io.legacy_valid.poke(1.U); control(0,9,2,expected=1); d.io.legacy_valid.poke(0.U)
    d.io.gemmini_fault.poke(1.U); control(0,9,2,expected=4); d.io.gemmini_fault.poke(0.U)
    d.io.dma_load_capabilities(2).poke(0.U); control(2,9,1,expected=3)
    control(0,3,9,expected=8);control(2,3,9,expected=4)
    for(i <- 0 until 3) d.io.dma_load_mode(i).expect(2.U)
    control(0,9,4,expected=2)
    control(1,0,BigInt("80008000",16),1)
    control(1,1,BigInt("80000000",16),10000)
    control(1,2)
    d.io.stream_owner.expect(2.U)
    control(1,9,2,expected=1); d.io.dma_load_mode(1).expect(2.U)
    reset(d)
    for(i <- 0 until 3) d.io.dma_load_mode(i).expect(2.U)
    println("DMA_LOAD_CONTROL_PASS,modes=1,fixed=read_assembled,busy_fault_unsupported_invalid=reject,ownership=checked,reset=mode2")
  }
}
