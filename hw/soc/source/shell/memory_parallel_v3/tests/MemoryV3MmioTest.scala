package memoryv3test
import chisel3._
import chiseltest._
import org.chipsalliance.cde.config.Parameters
import org.chipsalliance.diplomacy.lazymodule._
import org.chipsalliance.diplomacy.bundlebridge._
import freechips.rocketchip.diplomacy.IdRange
import freechips.rocketchip.subsystem._
import freechips.rocketchip.tilelink._

class MmioTestHarness(implicit p:Parameters) extends LazyModule {
  val client=TLClientNode(Seq(TLMasterPortParameters.v1(Seq(TLClientParameters(name="cpu",sourceId=IdRange(0,1))))))
  val perf=LazyModule(new MemoryParallelPerf(8))
  perf.node := client
  val external=BundleBridgeSink[MemoryParallelPerfExternal]()
  external := perf.external
  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val io=IO(new Bundle {
      val cpu=Flipped(new TLBundle(client.out.head._2.bundle))
      val ext=new MemoryParallelPerfExternal
    })
    client.out.head._1 <> io.cpu
    io.ext <> external.bundle
    perf.module.io.events := 0.U.asTypeOf(perf.module.io.events)
    for(b<-0 until 7) {
      perf.module.io.events(b)(0) := 1.U
      perf.module.io.events(b)(1) := 3.U
      perf.module.io.events(b)(11) := 7.U
    }
  }
}
object MemoryV3MmioTest extends App {
  implicit val p:Parameters=Parameters.empty
  RawTester.test(LazyModule(new MmioTestHarness).module,
    Seq(chiseltest.simulator.VerilatorBackendAnnotation,firrtl2.options.TargetDirAnnotation("sim"))) { d =>
    val x=d.io.cpu
    x.a.valid.poke(false.B);x.d.ready.poke(false.B)
    x.a.bits.opcode.poke(4.U);x.a.bits.param.poke(0.U);x.a.bits.size.poke(3.U)
    x.a.bits.source.poke(0.U);x.a.bits.address.poke(0.U);x.a.bits.mask.poke(255.U)
    x.a.bits.data.poke(0.U);x.a.bits.corrupt.poke(false.B)
    d.io.ext.available.poke(false.B);d.io.ext.acknowledge.poke(false.B);d.io.ext.data.poke(0.U)
    d.reset.poke(true.B);d.clock.step(4);d.reset.poke(false.B)
    val ack=scala.collection.mutable.Queue.fill(6)(false)
    val externalValue=BigInt("fedcba9876543210",16)
    def tick():Unit={
      ack.enqueue(d.io.ext.request.peek().litToBoolean)
      d.io.ext.acknowledge.poke(ack.dequeue().B)
      d.io.ext.data.poke(externalValue.U)
      d.clock.step()
    }
    def access(offset:Int,write:Boolean=false,value:BigInt=0,size:Int=3):BigInt={
      x.a.bits.opcode.poke((if(write)0 else 4).U);x.a.bits.size.poke(size.U)
      x.a.bits.address.poke((0x2020000+offset).U)
      x.a.bits.mask.poke((if(size==3)255 else if((offset&4)!=0)240 else 15).U)
      x.a.bits.data.poke((value << (if((offset&4)!=0)32 else 0)).U);x.a.valid.poke(true.B)
      var timeout=0
      while(!x.a.ready.peek().litToBoolean){tick();timeout+=1;require(timeout<100)}
      tick();x.a.valid.poke(false.B)
      while(!x.d.valid.peek().litToBoolean){tick();timeout+=1;require(timeout<100)}
      require(!x.d.bits.denied.peek().litToBoolean)
      val result=x.d.bits.data.peek().litValue
      x.d.ready.poke(true.B);tick();x.d.ready.poke(false.B)
      if(size==3)result else (result >> (if((offset&4)!=0)32 else 0))&0xffffffffL
    }
    def cmd(n:Int):Unit={
      access(8,true,n,2)
      var timeout=0
      while((access(0x10)&1)!=0){timeout+=1;require(timeout<30)}
    }
    def counter(block:Int,slot:Int):BigInt={access(0x20,true,block*32+slot,2);access(0x28)}
    require(access(0)==BigInt("4d50563300010000",16))
    require(access(0x30)==0x1000 && access(0x38)==524288 && access(0x60)==512)
    d.io.ext.available.poke(true.B);tick()
    cmd(3);cmd(1);for(_<-0 until 73)tick();cmd(2);cmd(4)
    val cycles=counter(0,0)
    require(cycles>=73 && counter(0,1)==cycles*3 && counter(5,11)==7)
    val whole=counter(0,31)
    val low=access(0x28,size=2);for(_<-0 until 11)tick();val high=access(0x2c,size=2)
    require((high<<32|low)==whole, "32-bit split snapshot read tore")
    require(counter(9,3)==externalValue)
    val sequence=access(0x18);require(sequence==1)
    cmd(1);for(_<-0 until 23)tick();require(counter(0,0)==cycles,"live counter leaked into frozen snapshot")
    cmd(4);require(counter(0,0)>cycles && access(0x18)==2)
    cmd(3);require(access(0x28)==0 && (access(0x10)&7)==0)
    cmd(9);require((access(0x10)&16)!=0,"invalid command status missing")
    d.io.ext.available.poke(false.B);tick();tick()
    require((access(0x10)&15)==0)
    println("MEMORY_V3_MMIO_PASS base=0x02020000 commands=yes local_and_external=yes split32_snapshot=yes peak=yes reset_status=yes")
  }
}
