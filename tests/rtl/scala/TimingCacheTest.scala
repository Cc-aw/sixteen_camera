package autonomoustest

import chisel3._
import chisel3.util._
import chiseltest._
import org.chipsalliance.cde.config.Parameters
import org.chipsalliance.diplomacy.lazymodule._
import freechips.rocketchip.diplomacy.{AddressSet, IdRange, TransferSizes}
import freechips.rocketchip.tilelink._
import sifive.blocks.inclusivecache._
import freechips.rocketchip.subsystem._

class TimingCacheTestHarness(implicit p: Parameters) extends LazyModule {
  val banks = p(SubsystemBankedCoherenceKey).nBanks
  val clients = TLClientNode((0 until 4).map(i => TLMasterPortParameters.v1(Seq(TLClientParameters(
    name=s"tester$i", sourceId=IdRange(0,32), supportsProbe=if(i==2) TransferSizes(64,64) else TransferSizes.none)))))
  val control = TLClientNode(Seq(TLMasterPortParameters.v1(Seq(TLClientParameters(name="control",sourceId=IdRange(0,1))))))
  val front = LazyModule(new TLXbar)
  val back = LazyModule(new TLXbar)
  val l2 = LazyModule(new InclusiveCache(
    CacheParameters(level=2, ways=8, sets=512, blockBytes=64, beatBytes=32,hintsSkipProbe=false),
    InclusiveCacheMicroParameters(writeBytes=8,portFactor=4,memCycles=64,innerBuf=InclusiveCachePortParameters.full,outerBuf=InclusiveCachePortParameters.full),
    Some(InclusiveCacheControlParameters(address=0x2010000,beatBytes=8,bankedControl=false))) {
      val simultaneousTest = InModuleBody {
        val result = IO(Output(Bool()))
        result := node.in.map(_._1.d.fire).reduce(_&&_)
        result
      }
    })
  val ram = LazyModule(new TLRAM(AddressSet(0x80000000L, 0x1fffff), beatBytes=64))
  front.node :=* clients
  l2.node :*= front.node
  back.node :=* BankBinder(BigInt(banks - 1) << 12) :*= TLCacheCork() :*= l2.node
  ram.node := TLBuffer(4) := back.node
  l2.ctrls.head.ctrlnode := control
  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val secondaryUsed = l2.module.mods.map(s => chiseltest.experimental.expose(s.requests.used))
    val ordinaryActive = l2.module.mods.map(s => s.mshrs.take(32).map(m =>
      chiseltest.experimental.expose(m.io.status.valid)))
    val io = IO(new Bundle {
      val ports = MixedVec(clients.out.map { case (_,e) => Flipped(new TLBundle(e.bundle)) })
      val ctrl = Flipped(new TLBundle(control.out.head._2.bundle))
      val simultaneous = Output(Bool())
    })
    clients.out.zipWithIndex.foreach { case ((b,e),i) => b <> io.ports(i) }
    control.out.head._1 <> io.ctrl
    io.simultaneous := l2.simultaneousTest
    require(l2.node.in.size == banks)
  }
}

object TimingCacheTest extends App {
  val banks = if(args.length > 1) args(1).toInt else 4
  require(banks == 2 || banks == 4)
  val period = banks * 32768
  implicit val p: Parameters = Parameters.empty.alterPartial {
    case SubsystemBankedCoherenceKey => BankedCoherenceParams(nBanks=banks, bankMask=Some(BigInt(banks - 1) << 12))
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
  RawTester.test(LazyModule(new TimingCacheTestHarness).module, annotations) { d =>
    val queues = Array.fill(4)(scala.collection.mutable.Queue.empty[(Int,Int,BigInt,Int)])
    var cycles=0; var parallel=0; var probeCount=0; var secondaryPeak=0
    val poolPeaks=Array.fill(banks)(0)
    val mshrPeaks=Array.fill(banks)(0)
    var holdResponses=false
    var saturationBank = -1
    var dirtyAddress=BigInt(-1); var dirtyData=BigInt(0); var permission=0
    var probe: Option[(BigInt,Int,Int,Int,Boolean)] = None
    var voluntaryRelease=false
    val random = new scala.util.Random(407)
    d.io.ports.foreach { x =>
      zero(x.a.bits); x.a.valid.poke(false.B); x.d.ready.poke(true.B)
      if(x.params.hasBCE) {
        zero(x.c.bits); x.c.valid.poke(false.B); x.b.ready.poke(true.B)
        zero(x.e.bits); x.e.valid.poke(false.B)
      }
    }
    zero(d.io.ctrl.a.bits); d.io.ctrl.a.valid.poke(false.B); d.io.ctrl.d.ready.poke(false.B)
    d.reset.poke(true.B); d.clock.step(5); d.reset.poke(false.B)
    def tick(): Unit = {
      secondaryPeak=secondaryPeak.max(d.secondaryUsed.map(_.peek().litValue.bitCount).max)
      for(bank <- 0 until banks) {
        poolPeaks(bank)=poolPeaks(bank).max(d.secondaryUsed(bank).peek().litValue.bitCount)
        mshrPeaks(bank)=mshrPeaks(bank).max(d.ordinaryActive(bank).count(_.peek().litToBoolean))
      }
      if(holdResponses && saturationBank>=0 && mshrPeaks(saturationBank)==32)
        holdResponses=false
      cycles+=1; require(cycles<150000, "cache test timeout")
      for(i <- 0 until 4) {
        val x=d.io.ports(i)
        x.d.ready.poke((!holdResponses && cycles%7 != 1 && cycles%13 != 2).B)
        if(i==2) x.b.ready.poke(probe.isEmpty.B)
      }
      val cpu=d.io.ports(2)
      cpu.c.valid.poke(probe.nonEmpty.B)
      probe.foreach { case (addr,src,param,beat,hasData) =>
        zero(cpu.c.bits); cpu.c.bits.opcode.poke((if(voluntaryRelease) 7 else if(hasData) 5 else 4).U)
        cpu.c.bits.param.poke(param.U); cpu.c.bits.size.poke(6.U)
        cpu.c.bits.source.poke(src.U); cpu.c.bits.address.poke(addr.U)
        cpu.c.bits.data.poke((dirtyData + beat).U)
      }
      if(d.io.simultaneous.peek().litToBoolean) parallel+=1
      for(i <- 0 until 4) {
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
        if(probe.isEmpty) voluntaryRelease=false
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
    def line(i:Int) = BigInt(0x80000000L) + (i%banks)*4096 + (i/banks)*64
    for(i <- 0 until 64) {
      send(i%2,0,line(i),value=BigInt(0x10000+i*2))
      require(recv(i%2)._1==0)
    }
    // Each bank has an independent requester; exercise genuinely concurrent
    // returns, including the fourth bank instead of a three-port surrogate.
    val requestsPerBank = 64 / banks
    for(i <- 0 until requestsPerBank; port <- 0 until banks) {
      send(port,4,line(banks*i+port),source=i)
    }
    for(port <- 0 until banks) {
      val seen=Array.fill(requestsPerBank)(0)
      for(_ <- 0 until 2*requestsPerBank) {
        val (op,src,value,_) = recv(port)
        require(op==1 && src<32)
        require(value == 0x10000+(src*banks+port)*2+seen(src), s"wrong bank/source data: $port $src $value")
        seen(src)+=1
      }
      require(seen.forall(_==2))
    }
    require(parallel>0, "banks never returned simultaneously")
    // Three simultaneous request streams, including repeated same-bank sets.
    for(i <- 0 until 16; port <- 0 until 3) send(port,4,line(3*i+port),source=i)
    for(port <- 0 until 3) {
      val seen=Array.fill(16)(0)
      for(_ <- 0 until 32) {
        val (op,src,value,_) = recv(port)
        require(op==1 && value==0x10000+(3*src+port)*2+seen(src))
        seen(src)+=1
      }
      require(seen.forall(_==2))
    }
    send(0,1,line(2)+32,value=0xabcdef,size=5,mask=15); require(recv(0)._1==0)
    send(1,4,line(2)); require(recv(1)._3==0x10004 && recv(1)._3==0xabcdef)
    send(0,0,BigInt(0x80000fc0L),value=0xb00); require(recv(0)._1==0)
    send(1,4,BigInt(0x80000fc0L)); require(recv(1)._3==0xb00 && recv(1)._3==0xb01)
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
    flush(dirtyAddress); require(probeCount==2 && permission==0)
    send(1,4,dirtyAddress); require(recv(1)._3==dirtyData && recv(1)._3==dirtyData+1)
    // Dirty ReleaseData must pass concurrent hot same-set secondary requests.
    // Check the restored S1 C/B/A priority and direct refill path.
    send(2,6,dirtyAddress,param=1)
    val again0=recv(2);val again1=recv(2)
    require(again0._1==5 && again1._1==5 && again0._3==dirtyData)
    d.io.ports(2).e.bits.sink.poke(again0._4.U);d.io.ports(2).e.valid.poke(true.B)
    while(!d.io.ports(2).e.ready.peek().litToBoolean) tick()
    tick();d.io.ports(2).e.valid.poke(false.B)
    permission=2;dirtyData+=0x1000
    val peer=dirtyAddress+period
    send(0,4,peer);require(recv(0)._3==0 && recv(0)._3==0)
    // Replacement is random even while another way is invalid. Establish
    // both residents before issuing a legal voluntary release; never release
    // a line after the cache has already probed its CPU owner to N.
    var residentAttempts=0
    while(permission!=2) {
      residentAttempts+=1;require(residentAttempts<=16,"could not establish same-set residents")
      send(2,6,dirtyAddress,param=1)
      val r0=recv(2);val r1=recv(2)
      require(r0._1==5 && r1._1==5 && r0._3==dirtyData && r1._3==dirtyData+1)
      d.io.ports(2).e.bits.sink.poke(r0._4.U);d.io.ports(2).e.valid.poke(true.B)
      while(!d.io.ports(2).e.ready.peek().litToBoolean) tick()
      tick();d.io.ports(2).e.valid.poke(false.B);permission=2
      send(0,4,peer);require(recv(0)._3==0 && recv(0)._3==0)
    }
    for(src<-0 until 16) send(0,4,peer,source=src)
    require(permission==2,s"CPU dirty owner was evicted before voluntary release: probes=$probeCount")
    voluntaryRelease=true;probe=Some((dirtyAddress,0,1,0,true))
    while(probe.nonEmpty) tick()
    permission=0;require(recv(2)._1==6,"dirty release was not acknowledged")
    val hotSeen=Array.fill(16)(0)
    for(_<-0 until 32) {
      val (op,src,value,_)=recv(0)
      require(op==1 && src<16 && value==0);hotSeen(src)+=1
    }
    require(hotSeen.forall(_==2))
    send(1,4,dirtyAddress);require(recv(1)._3==dirtyData && recv(1)._3==dirtyData+1)
    flush(line(0)); flush(line(2),invalidate=true)
    send(0,4,line(0)); require(recv(0)._3==0x10000 && recv(0)._3==0x10001)
    // 96 outstanding reads share one bank and one set, alternate tags, and
    // force secondary queues/refills through replacement. No cached owner
    // exists after the prior flush, so every untouched line contains zero.
    for(bank<-0 until banks) {
      for(src<-0 until 32; port<-0 until 3) {
        send(port,4,BigInt(0x80008000L)+bank*4096+BigInt(src%16)*period,source=src)
      }
      for(port<-0 until 3) {
        val seen=Array.fill(32)(0)
        for(_<-0 until 64) {
          val (op,src,value,_)=recv(port)
          require(op==1 && src<32 && value==0,s"same-set refill corrupted bank=$bank port=$port source=$src data=$value")
          seen(src)+=1
        }
        require(seen.forall(_==2))
      }
    }
    require(poolPeaks.forall(_==34), s"S1 pool capacity not exercised in every bank: ${poolPeaks.mkString(",")}")
    // Hold client responses while allocating distinct-set misses. Each bank
    // must expose all 32 ordinary MSHRs, then drain without losing a response.
    for(bank<-0 until banks) {
      saturationBank=bank
      holdResponses=true
      // Buffered completed D beats may retire an MSHR before client acceptance.
      // Forty-eight misses leave enough pending work to fill all 32 entries.
      for(n<-0 until 48) send(if(n<32)0 else 1,4,
        BigInt(0x80100000L)+bank*4096+n*64,source=n%32)
      for(_<-0 until 64) tick()
      holdResponses=false
      saturationBank = -1
      for(port<-0 until 2) {
        val sources=if(port==0)32 else 16
        val seen=Array.fill(sources)(0)
        for(_<-0 until 2*sources) {
          val(op,src,value,_)=recv(port)
          require(op==1 && src<sources && value==0);seen(src)+=1
        }
        require(seen.forall(_==2))
      }
    }
    require(mshrPeaks.forall(_==32),s"Ordinary MSHRs not exhausted in every bank: ${mshrPeaks.mkString(",")}")
    // Address-directed flush and refetch must reach every bank.
    for(bank <- 0 until banks) {
      val addr=BigInt(0x80040000L)+bank*4096
      send(0,0,addr,value=BigInt(0x70000+bank*2));require(recv(0)._1==0)
      // S1 invalidate intentionally discards dirty data. Publish with flush
      // before testing invalidate on the subsequently fetched clean line.
      flush(addr)
      send(1,4,addr)
      require(recv(1)._3==0x70000+bank*2 && recv(1)._3==0x70001+bank*2)
      flush(addr,invalidate=true)
      send(1,4,addr)
      require(recv(1)._3==0x70000+bank*2 && recv(1)._3==0x70001+bank*2)
      // Verify restored Probe addresses and CPU dirty ownership in every bank,
      // including the newly introduced A13 bank-select bit.
      dirtyAddress=addr
      send(2,6,addr,param=1)
      val grant0=recv(2);val grant1=recv(2)
      require(grant0._1==5 && grant1._1==5 && grant0._3==0x70000+bank*2)
      d.io.ports(2).e.bits.sink.poke(grant0._4.U);d.io.ports(2).e.valid.poke(true.B)
      while(!d.io.ports(2).e.ready.peek().litToBoolean) tick()
      tick();d.io.ports(2).e.valid.poke(false.B)
      val probesBefore=probeCount
      dirtyData=BigInt(0x90000+bank*2);permission=2
      send(3,4,addr)
      require(recv(3)._3==dirtyData && recv(3)._3==dirtyData+1)
      flush(addr)
      require(probeCount==probesBefore+2 && permission==0)
      send(1,4,addr);require(recv(1)._3==dirtyData && recv(1)._3==dirtyData+1)
    }
    println(s"MEMORY_V3_CACHE_PASS banks=$banks secondary_peak=$secondaryPeak pool_peaks=${poolPeaks.mkString(",")} mshr_peaks=${mshrPeaks.mkString(",")} cycles=$cycles simultaneous=$parallel probes=$probeCount dirty_flush=all_banks dirty_release_with_queued_reads=yes source_ids=32 same_set_requests_per_bank=96")
  }
}
