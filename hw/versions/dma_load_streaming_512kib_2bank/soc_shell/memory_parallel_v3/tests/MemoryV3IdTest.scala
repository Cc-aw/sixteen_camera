package memoryv3test
import chisel3._
import chiseltest._
import org.chipsalliance.cde.config.Parameters
import org.chipsalliance.diplomacy.lazymodule._
import freechips.rocketchip.diplomacy.{AddressSet,IdRange,TransferSizes}
import freechips.rocketchip.amba.axi4._

class IdTestHarness(implicit p:Parameters) extends LazyModule {
  val source=AXI4MasterNode(Seq(AXI4MasterPortParameters(Seq(AXI4MasterParameters(
    name="l2-test",id=IdRange(0,128),maxFlight=Some(1))))))
  val sink=AXI4SlaveNode(Seq(AXI4SlavePortParameters(Seq(AXI4SlaveParameters(
    address=Seq(AddressSet(0,0xffffffffL)),supportsRead=TransferSizes(1,64),supportsWrite=TransferSizes(1,64))),beatBytes=64)))
  sink := AXI4UserYanker() := AXI4IdIndexer(2) := source
  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val io=IO(new Bundle {
      val in=Flipped(new AXI4Bundle(source.out.head._2.bundle))
      val out=new AXI4Bundle(sink.in.head._2.bundle)
    })
    source.out.head._1 <> io.in
    io.out <> sink.in.head._1
    require(sink.in.head._2.bundle.idBits==2)
  }
}
object MemoryV3IdTest extends App {
  implicit val p:Parameters=Parameters.empty
  def zero(d:Data):Unit=d match {
    case b:Bool=>b.poke(false.B)
    case u:UInt=>u.poke(0.U)
    case v:Vec[_]=>v.foreach(zero)
    case r:Record=>r.elements.values.foreach(zero)
  }
  RawTester.test(LazyModule(new IdTestHarness).module,Seq(chiseltest.simulator.VerilatorBackendAnnotation,
    firrtl2.options.TargetDirAnnotation("sim"))) { d =>
    zero(d.io.in.ar.bits);zero(d.io.in.aw.bits);zero(d.io.in.w.bits)
    zero(d.io.out.r.bits);zero(d.io.out.b.bits)
    d.io.in.ar.valid.poke(false.B);d.io.in.aw.valid.poke(false.B);d.io.in.w.valid.poke(false.B)
    d.io.in.r.ready.poke(false.B);d.io.in.b.ready.poke(false.B)
    d.io.out.ar.ready.poke(true.B);d.io.out.aw.ready.poke(true.B);d.io.out.w.ready.poke(true.B)
    d.io.out.r.valid.poke(false.B);d.io.out.b.valid.poke(false.B)
    d.reset.poke(true.B);d.clock.step(4);d.reset.poke(false.B)
    for(i<-0 until 32) {
      d.io.in.ar.bits.id.poke((i*4).U);d.io.in.ar.bits.addr.poke((i*64).U)
      d.io.in.ar.bits.size.poke(6.U);d.io.in.ar.bits.burst.poke(1.U);d.io.in.ar.valid.poke(true.B)
      d.io.in.aw.bits.id.poke((i*4+1).U);d.io.in.aw.bits.addr.poke((4096+i*64).U)
      d.io.in.aw.bits.size.poke(6.U);d.io.in.aw.bits.burst.poke(1.U);d.io.in.aw.valid.poke(true.B)
      d.io.in.w.valid.poke(true.B);d.io.in.w.bits.last.poke(true.B);d.io.in.w.bits.strb.poke(((BigInt(1)<<64)-1).U)
      assert(d.io.in.ar.ready.peek().litToBoolean && d.io.in.aw.ready.peek().litToBoolean,
        s"ID metadata window capped below 32: $i")
      d.io.out.ar.bits.id.expect(0.U);d.io.out.aw.bits.id.expect(1.U)
      d.clock.step()
    }
    d.io.in.ar.valid.poke(false.B);d.io.in.aw.valid.poke(false.B);d.io.in.w.valid.poke(false.B)
    for(i<-0 until 32) {
      d.io.out.r.bits.id.poke(0.U);d.io.out.r.bits.data.poke((BigInt(i)<<480).U)
      d.io.out.r.bits.last.poke(true.B);d.io.out.r.valid.poke(true.B)
      d.io.out.b.bits.id.poke(1.U);d.io.out.b.valid.poke(true.B)
      d.io.in.r.ready.poke(false.B);d.io.in.b.ready.poke(false.B)
      d.clock.step(2)
      d.io.in.r.bits.id.expect((i*4).U);d.io.in.b.bits.id.expect((i*4+1).U)
      d.io.in.r.bits.data.expect((BigInt(i)<<480).U)
      d.io.in.r.ready.poke(true.B);d.io.in.b.ready.poke(true.B)
      d.clock.step()
    }
    d.io.out.r.valid.poke(false.B);d.io.out.b.valid.poke(false.B)
    println("MEMORY_V3_ID_PASS read=32 write=32 physical_ids=2bits same_id_fifo=yes original_ids_restored=yes data=512bits")
  }
}
