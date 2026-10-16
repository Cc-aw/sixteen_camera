package memoryv3test

import chisel3._
import chisel3.util._
import chiseltest._
import org.chipsalliance.cde.config.Parameters
import org.chipsalliance.diplomacy.lazymodule._
import freechips.rocketchip.diplomacy.{AddressSet, IdRange, TransferSizes}
import freechips.rocketchip.tilelink._
import sifive.blocks.inclusivecache._
import freechips.rocketchip.subsystem._
import tsmcchip.fpga.taihangsoc.{TaihangTensorIngress, TensorWriteIO}

class TensorCacheTestHarness(implicit p: Parameters) extends LazyModule {
  val clients = TLClientNode((0 until 3).map(i => TLMasterPortParameters.v1(Seq(TLClientParameters(
    name=s"tester$i", sourceId=IdRange(0,32), supportsProbe=if(i==2) TransferSizes(64,64) else TransferSizes.none)))))
  val control = TLClientNode(Seq(TLMasterPortParameters.v1(Seq(TLClientParameters(name="control",sourceId=IdRange(0,1))))))
  val front = LazyModule(new TLXbar)
  val back = LazyModule(new TLXbar)
  val controlXbar = LazyModule(new TLXbar)
  val writer = LazyModule(new TaihangTensorIngress(8))
  val l2 = LazyModule(new InclusiveCache(
    CacheParameters(level=2, ways=8, sets=512, blockBytes=64, beatBytes=32,hintsSkipProbe=false),
    InclusiveCacheMicroParameters(writeBytes=8,portFactor=4,memCycles=64,secondaryEntries=Some(68),
      innerBuf=InclusiveCachePortParameters.full),
    Some(InclusiveCacheControlParameters(address=0x2010000,beatBytes=8,bankedControl=false))) {
      val simultaneousTest = InModuleBody {
        val result = IO(Output(Bool()))
        result := node.in.map(_._1.d.fire).reduce(_&&_)
        result
      }
    })
  val ram = LazyModule(new TLRAM(AddressSet(0xb0000000L, 0xfffff), beatBytes=64) {
    val observedGets = InModuleBody {
      val result = IO(Output(UInt(32.W)))
      val count = RegInit(0.U(32.W))
      val mem = node.in.head._1
      when(mem.a.fire && mem.a.bits.opcode === TLMessages.Get) { count := count + 1.U }
      result := count
      result
    }
  })
  front.node :=* clients
  front.node := writer.node
  l2.node :*= front.node
  back.node :=* BankBinder(BigInt(0x1000)) :*= TLCacheCork() :*= l2.node
  ram.node := TLBuffer(4) := back.node
  controlXbar.node := control
  l2.ctrls.head.ctrlnode := controlXbar.node
  writer.control := controlXbar.node
  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val io = IO(new Bundle {
      val ports = MixedVec(clients.out.map { case (_,e) => Flipped(new TLBundle(e.bundle)) })
      val ctrl = Flipped(new TLBundle(control.out.head._2.bundle))
      val tensor = new TensorWriteIO
      val memoryGets = Output(UInt(32.W))
      val simultaneous = Output(Bool())
    })
    clients.out.zipWithIndex.foreach { case ((b,e),i) => b <> io.ports(i) }
    control.out.head._1 <> io.ctrl
    io.tensor <> writer.module.io
    io.memoryGets := ram.observedGets
    io.simultaneous := l2.simultaneousTest
    require(l2.node.in.size == 2)
  }
}

object MemoryV3TensorTest extends App {
  implicit val p: Parameters = Parameters.empty.alterPartial {
    case SubsystemBankedCoherenceKey => BankedCoherenceParams(nBanks=2, bankMask=Some(BigInt(0x1000)))
  }
  val output = args(0)
  val annotations = Seq(chiseltest.simulator.VerilatorBackendAnnotation,
    firrtl2.options.TargetDirAnnotation(output))
  def zero(d: Data): Unit = d match {
    case b: Bool => b.poke(false.B)
    case u: UInt => u.poke(0.U)
    case v: Vec[_] => v.foreach(zero)
    case r: Record => r.elements.values.foreach(zero)
  }
  RawTester.test(LazyModule(new TensorCacheTestHarness).module, annotations) { d =>
    val queues = Array.fill(3)(scala.collection.mutable.Queue.empty[(Int,Int,BigInt,Int)])
    var cycles=0; var parallel=0; var probeCount=0; var tensorOverlap=0
    var holdResponses=false; var tensorInFlight=false
    var dirtyAddress=BigInt(-1); var dirtyData=BigInt(0); var permission=0
    var probe: Option[(BigInt,Int,Int,Int,Boolean)] = None
    val random = new scala.util.Random(407)
    d.io.ports.foreach { x =>
      zero(x.a.bits); x.a.valid.poke(false.B); x.d.ready.poke(true.B)
      if(x.params.hasBCE) {
        zero(x.c.bits); x.c.valid.poke(false.B); x.b.ready.poke(true.B)
        zero(x.e.bits); x.e.valid.poke(false.B)
      }
    }
    zero(d.io.ctrl.a.bits); d.io.ctrl.a.valid.poke(false.B); d.io.ctrl.d.ready.poke(false.B)
    zero(d.io.tensor.aw.bits); d.io.tensor.aw.valid.poke(false.B)
    zero(d.io.tensor.w.bits); d.io.tensor.w.valid.poke(false.B)
    d.io.tensor.b.ready.poke(false.B)
    d.reset.poke(true.B); d.clock.step(5); d.reset.poke(false.B)
    def tick(): Unit = {
      cycles+=1; require(cycles<150000, "cache test timeout")
      for(i <- 0 until 3) {
        val x=d.io.ports(i)
        x.d.ready.poke((!holdResponses && cycles%7 != 1 && cycles%13 != 2).B)
        if(i==2) x.b.ready.poke(probe.isEmpty.B)
      }
      val cpu=d.io.ports(2)
      cpu.c.valid.poke(probe.nonEmpty.B)
      probe.foreach { case (addr,src,param,beat,hasData) =>
        zero(cpu.c.bits); cpu.c.bits.opcode.poke((if(hasData) 5 else 4).U)
        cpu.c.bits.param.poke(param.U); cpu.c.bits.size.poke(6.U)
        cpu.c.bits.source.poke(src.U); cpu.c.bits.address.poke(addr.U)
        cpu.c.bits.data.poke((dirtyData + beat).U)
      }
      if(d.io.simultaneous.peek().litToBoolean) parallel+=1
      if ((tensorInFlight || d.io.tensor.aw.valid.peek().litToBoolean || d.io.tensor.w.valid.peek().litToBoolean ||
           d.io.tensor.b.valid.peek().litToBoolean) &&
          d.io.ports.exists(x => x.d.valid.peek().litToBoolean && x.d.ready.peek().litToBoolean)) tensorOverlap+=1
      for(i <- 0 until 3) {
        val x=d.io.ports(i)
        if(x.d.valid.peek().litToBoolean && x.d.ready.peek().litToBoolean) {
          require(!x.d.bits.denied.peek().litToBoolean && !x.d.bits.corrupt.peek().litToBoolean)
          queues(i).enqueue((x.d.bits.opcode.peek().litValue.toInt,x.d.bits.source.peek().litValue.toInt,
            x.d.bits.data.peek().litValue,x.d.bits.sink.peek().litValue.toInt))
        }
        if(i==2 && x.b.valid.peek().litToBoolean && x.b.ready.peek().litToBoolean) {
          require(i==2 && x.b.bits.address.peek().litValue==dirtyAddress, "Probe address restoration failed")
          val target=x.b.bits.param.peek().litValue.toInt
          val shrink=if(permission==2) {if(target==2) 1 else 0} else {if(target==2) 2 else 4}
          probe=Some((dirtyAddress,x.b.bits.source.peek().litValue.toInt,shrink,0,permission==2))
          permission=if(target==2) 0 else 1
          probeCount+=1
        }
      }
      if(cpu.c.valid.peek().litToBoolean && cpu.c.ready.peek().litToBoolean) {
        probe=probe.flatMap { case (a,s,p,b,data) => if(!data || b==1) None else Some((a,s,p,b+1,data)) }
      }
      d.clock.step()
    }
    def send(i:Int, opcode:Int, addr:BigInt, source:Int=0, value:BigInt=0, param:Int=0, size:Int=6, mask:BigInt=0xffffffffL):Unit = {
      val x=d.io.ports(i); zero(x.a.bits)
      x.a.bits.opcode.poke(opcode.U); x.a.bits.param.poke(param.U); x.a.bits.size.poke(size.U)
      x.a.bits.address.poke(addr.U); x.a.bits.source.poke(source.U); x.a.bits.mask.poke(mask.U)
      val beats=if(opcode<=1 && size==6) 2 else 1
      for(b <- 0 until beats) {
        x.a.bits.data.poke((value+b).U); x.a.valid.poke(true.B)
        while(!x.a.ready.peek().litToBoolean) tick()
        tick()
      }
      x.a.valid.poke(false.B)
    }
    def recv(i:Int):(Int,Int,BigInt,Int) = { while(queues(i).isEmpty) tick(); queues(i).dequeue() }
    def line(i:Int) = BigInt(0xb0000000L) + (i%2)*4096 + (i/2)*64
    def tensorWrite(addr:BigInt, value:BigInt):Unit = {
      val t=d.io.tensor
      tensorInFlight=true
      zero(t.aw.bits); t.aw.bits.addr.poke(addr.U); t.aw.bits.len.poke(1.U)
      t.aw.bits.size.poke(5.U); t.aw.bits.burst.poke(1.U); t.aw.valid.poke(true.B)
      while(!t.aw.ready.peek().litToBoolean) tick()
      tick(); t.aw.valid.poke(false.B)
      for (beat <- 0 until 2) {
        t.w.bits.data.poke((value+beat).U); t.w.bits.strb.poke(BigInt("ffffffff",16).U)
        t.w.bits.last.poke((beat==1).B); t.w.valid.poke(true.B)
        while(!t.w.ready.peek().litToBoolean) tick()
        tick()
      }
      t.w.valid.poke(false.B)
      while(!t.b.valid.peek().litToBoolean) tick()
      require(t.b.bits.resp.peek().litValue==0 && t.b.bits.id.peek().litValue==0)
      t.b.ready.poke(true.B); tick(); t.b.ready.poke(false.B)
      tensorInFlight=false
    }
    def tensorLine(i:Int) = BigInt(0xb0080000L)+(i%2)*4096+(i/2)*64
    for (i <- 0 until 32) tensorWrite(tensorLine(i), BigInt(0x20000+i*2))
    require(d.io.memoryGets.peek().litValue==0, "Cold full-line Tensor write fetched old DDR data")
    for (i <- 0 until 32) {
      send(i%2,4,tensorLine(i))
      require(recv(i%2)._3==0x20000+i*2 && recv(i%2)._3==0x20001+i*2)
    }
    require(d.io.memoryGets.peek().litValue==0, "Tensor readback missed freshly written L2 lines")
    for(i <- 0 until 64) {
      send(i%2,0,line(i),value=BigInt(0x10000+i*2))
      require(recv(i%2)._1==0)
    }
    // Two independent bank returns must be possible, with randomized stalls
    // and 32 active source IDs at each requester.
    for(i <- 0 until 32) {
      send(0,4,line(2*i),source=i); send(1,4,line(2*i+1),source=i)
    }
    for(port <- 0 until 2) {
      val seen=Array.fill(32)(0)
      for(_ <- 0 until 64) {
        val (op,src,value,_) = recv(port)
        require(op==1 && src<32)
        require(value == 0x10000+(src*2+port)*2+seen(src), s"wrong bank/source data: $port $src $value")
        seen(src)+=1
      }
      require(seen.forall(_==2))
    }
    require(parallel>0, "banks never returned simultaneously")
    // Three simultaneous request streams, including repeated same-bank sets.
    for(i <- 0 until 16) {
      // Keep replies pending until the Tensor transaction starts. Registered
      // cache boundaries change latency; concurrency must not depend on one
      // accidental overlap between an AXI valid pulse and a TL D handshake.
      holdResponses=true
      for(port <- 0 until 3) send(port,4,line(3*i+port),source=i)
      holdResponses=false
      tensorWrite(tensorLine(i), BigInt(0x30000+i*2))
    }
    require(tensorOverlap>0, "Tensor traffic never overlapped another client completion")
    for(port <- 0 until 3) {
      val seen=Array.fill(16)(0)
      for(_ <- 0 until 32) {
        val (op,src,value,_) = recv(port)
        require(op==1 && value==0x10000+(3*src+port)*2+seen(src))
        seen(src)+=1
      }
      require(seen.forall(_==2))
    }
    for(i <- 0 until 16) {
      send(i%2,4,tensorLine(i))
      require(recv(i%2)._3==0x30000+i*2 && recv(i%2)._3==0x30001+i*2)
    }
    send(0,1,line(2)+32,value=0xabcdef,size=5,mask=15); require(recv(0)._1==0)
    send(1,4,line(2)); require(recv(1)._3==0x10004 && recv(1)._3==0xabcdef)
    send(0,0,BigInt(0xb0000fc0L),value=0xb00); require(recv(0)._1==0)
    send(1,4,BigInt(0xb0000fc0L)); require(recv(1)._3==0xb00 && recv(1)._3==0xb01)
    // Bank-1 CPU ownership, dirty intervention, then a CPU-issued flush.
    dirtyAddress=line(1)
    send(2,6,dirtyAddress,param=1)
    val g0=recv(2); val g1=recv(2)
    require(g0._1==5 && g1._1==5 && g0._3==0x10002 && g1._3==0x10003)
    d.io.ports(2).e.bits.sink.poke(g0._4.U); d.io.ports(2).e.valid.poke(true.B)
    while(!d.io.ports(2).e.ready.peek().litToBoolean) tick()
    tick(); d.io.ports(2).e.valid.poke(false.B)
    dirtyData=BigInt("fedcba9876543210",16); permission=2
    send(0,4,dirtyAddress)
    require(recv(0)._3==dirtyData && recv(0)._3==dirtyData+1)
    require(probeCount==1)
    def flush(addr:BigInt,invalidate:Boolean=false):Unit = {
      val c=d.io.ctrl; zero(c.a.bits)
      c.a.bits.opcode.poke(0.U); c.a.bits.size.poke(3.U); c.a.bits.mask.poke(255.U)
      c.a.bits.address.poke((0x2010000+(if(invalidate) 0x280 else 0x200)).U)
      c.a.bits.data.poke(addr.U); c.a.valid.poke(true.B)
      while(!c.a.ready.peek().litToBoolean) tick()
      tick(); c.a.valid.poke(false.B)
      while(!c.d.valid.peek().litToBoolean) tick()
      require(!c.d.bits.denied.peek().litToBoolean)
      c.d.ready.poke(true.B); tick(); c.d.ready.poke(false.B)
    }
    tensorWrite(dirtyAddress, BigInt(0xcafe00))
    require(probeCount==2 && permission==0, "Tensor overwrite did not probe CPU ownership")
    dirtyData=BigInt(0xcafe00)
    flush(dirtyAddress); require(probeCount==2 && permission==0)
    send(1,4,dirtyAddress); require(recv(1)._3==dirtyData && recv(1)._3==dirtyData+1)
    flush(line(0)); flush(line(2),invalidate=true)
    send(0,4,line(0)); require(recv(0)._3==0x10000 && recv(0)._3==0x10001)
    // Ten tags in one eight-way set force dirty eviction through the 512-bit exit.
    for(tag <- 0 until 10) tensorWrite(BigInt(0xb0000040L)+tag*65536, BigInt(0x40000+tag*2))
    for(tag <- 0 until 10) {
      send(tag%2,4,BigInt(0xb0000040L)+tag*65536)
      require(recv(tag%2)._3==0x40000+tag*2 && recv(tag%2)._3==0x40001+tag*2)
    }
    println(s"MEMORY_V3_TENSOR_CACHE_PASS cycles=$cycles simultaneous=$parallel tensor_overlap=$tensorOverlap probes=$probeCount dirty_flush=yes dirty_eviction=yes source_ids=32")
  }
}
