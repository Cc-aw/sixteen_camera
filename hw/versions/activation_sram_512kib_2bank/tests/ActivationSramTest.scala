package freechips.rocketchip.tile.commandfrontend

import chisel3._
import chisel3.util._
import chiseltest._
import org.chipsalliance.cde.config.Parameters
import org.chipsalliance.diplomacy.lazymodule._
import freechips.rocketchip.diplomacy.IdRange
import freechips.rocketchip.tilelink._

class ActivationSramTestHarness(implicit p: Parameters) extends LazyModule {
  val bank = LazyModule(new ActivationSramTL(0))
  val masters = (0 until 2).map(i => TLClientNode(Seq(TLMasterPortParameters.v1(Seq(
    TLClientParameters(name = s"asram-test-$i", sourceId = IdRange(0, 64)))))))
  bank.dmaNode := masters(0); bank.serviceNode := masters(1)
  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val params = masters(0).out.head._2.bundle
    require(params == masters(1).out.head._2.bundle)
    val io = IO(new Bundle {
      val a = Vec(2, Flipped(Decoupled(new TLBundleA(params))))
      val d = Vec(2, Decoupled(new TLBundleD(params)))
      val clear = Input(Bool())
      val outstanding = Output(Vec(2, UInt(7.W)))
    })
    for(i <- 0 until 2) {
      val (tl, _) = masters(i).out.head
      tl.a <> io.a(i); io.d(i) <> tl.d
      tl.b.ready := true.B; tl.c.valid := false.B; tl.c.bits := 0.U.asTypeOf(tl.c.bits)
      tl.e.valid := false.B; tl.e.bits := 0.U.asTypeOf(tl.e.bits)
    }
    bank.module.clear := io.clear
    io.outstanding := bank.module.outstanding
  }
}

object ActivationSramTest extends App {
  implicit val p: Parameters = Parameters.empty
  val base = ActivationSramMap.bases.head
  val backend = Seq(chiseltest.simulator.IcarusBackendAnnotation)
  val rng = new scala.util.Random(171016)
  RawTester.test(LazyModule(new ActivationSramTestHarness).module, backend) { d =>
    d.io.clear.poke(false.B)
    for(i <- 0 until 2) { d.io.a(i).valid.poke(false.B); d.io.d(i).ready.poke(false.B) }
    d.reset.poke(true.B); d.clock.step(4); d.reset.poke(false.B)
    var cases = 0
    def fields(port: Int, opcode: Int, address: BigInt, size: Int, data: BigInt,
               mask: BigInt, source: Int, corrupt: Boolean): Unit = {
      val a = d.io.a(port).bits
      a.opcode.poke(opcode.U); a.param.poke(0.U); a.size.poke(size.U)
      a.source.poke(source.U); a.address.poke(address.U); a.data.poke(data.U)
      a.mask.poke(mask.U); a.corrupt.poke(corrupt.B)
    }
    def send(port: Int, opcode: Int, address: BigInt, size: Int, data: BigInt = 0,
             mask: BigInt = BigInt("ffffffff",16), source: Int = 31, corrupt: Boolean = false): Unit = {
      fields(port, opcode, address, size, data, mask, source, corrupt)
      d.io.a(port).valid.poke(true.B)
      var n = 0
      while(!d.io.a(port).ready.peek().litToBoolean && n < 500) { d.clock.step(); n += 1 }
      assert(n < 500, "A timeout")
      d.clock.step(); d.io.a(port).valid.poke(false.B)
    }
    def receive(port: Int, opcode: Int, size: Int, expected: Option[BigInt],
                denied: Boolean = false, source: Int = 31): Unit = {
      d.io.d(port).ready.poke(false.B)
      var n = 0
      while(!d.io.d(port).valid.peek().litToBoolean && n < 500) { d.clock.step(); n += 1 }
      assert(n < 500, "D timeout")
      val bits = d.io.d(port).bits
      def response = Seq(bits.opcode, bits.param, bits.size, bits.source, bits.sink,
        bits.denied, bits.data, bits.corrupt).map(_.peek().litValue)
      val held = response
      d.clock.step(1 + rng.nextInt(4))
      assert(response == held, "D changed under backpressure")
      bits.opcode.expect(opcode.U); bits.size.expect(size.U); bits.source.expect(source.U)
      bits.denied.expect(denied.B); bits.corrupt.expect((denied && opcode == 1).B)
      expected.foreach(x => bits.data.expect(x.U))
      d.io.d(port).ready.poke(true.B); d.clock.step(); d.io.d(port).ready.poke(false.B)
      cases += 1
    }
    // All 18 physical depth-group boundaries, including the final word.
    for(group <- 0 until 18; word <- Seq(group * 4096, group * 4096 + 4095)) {
      val address = base + word * 32
      val original = BigInt(256, rng)
      send(0, 0, address, 5, original); receive(0, 0, 5, None)
      send(1, 4, address, 5); receive(1, 1, 5, Some(original))
      val mask = BigInt(32, rng); val value = BigInt(256, rng)
      val bytesMask = (0 until 32).filter(mask.testBit).map(i => BigInt(255) << (8*i)).foldLeft(BigInt(0))(_|_)
      send(1, 1, address, 5, value, mask); receive(1, 0, 5, None)
      send(0, 4, address, 5); receive(0, 1, 5, Some((original & ~bytesMask) | (value & bytesMask)))
    }
    // Real two-beat Put64 has a constant A address. One Ack only after both
    // words commit; Get64 returns two contiguous, stable D beats.
    val a64 = base + 0x1800
    val first = BigInt(256, rng); val second = BigInt(256, rng)
    send(0, 0, a64, 6, first)
    d.clock.step(8); d.io.d(0).valid.expect(false.B)
    send(0, 0, a64, 6, second); receive(0, 0, 6, None)
    send(1, 4, a64, 6); receive(1, 1, 6, Some(first)); receive(1, 1, 6, Some(second))
    // All supported naturally aligned sub-word sizes, mask preservation and
    // cross-port access to identical backing bytes.
    for(size <- 0 to 5) {
      val address = base + 0x2000 + (if(size < 5) (1 << size) else 0)
      val offset = (address % 32).toInt
      val mask = ((BigInt(1) << (1 << size)) - 1) << offset
      val value = BigInt(256, rng)
      send(0, 0, base + 0x2000, 5, 0); receive(0, 0, 5, None)
      send(1, 1, address, size, value, mask); receive(1, 0, size, None)
      val wideMask = (0 until 32).filter(mask.testBit).map(i => BigInt(255) << (8*i)).foldLeft(BigInt(0))(_|_)
      send(0, 4, base + 0x2000, 5); receive(0, 1, 5, Some(value & wideMask))
    }
    // Legal last Get64; hole, foreign bank, and control-page DMA accesses deny.
    for(address <- Seq(base + ActivationSramMap.bytes, ActivationSramMap.bases(1),
        ActivationSramMap.controlBase)) {
      send(0, 4, address, 6); receive(0, 1, 6, Some(0), denied = true)
      receive(0, 1, 6, Some(0), denied = true)
      send(0, 0, address, 5, BigInt(256, rng)); receive(0, 0, 5, None, denied = true)
    }
    send(0, 0, base, 5, 123, corrupt = true); receive(0, 0, 5, None, denied = true)
    // Same-word WAW is serialized deterministically with alternating priority.
    // Both ingress A beats enter their independent request queues together.
    for(iteration <- 0 until 12) {
      val address = base + 0x4000
      fields(0, 0, address, 5, BigInt(100 + iteration), BigInt("ffffffff",16), 31, false)
      fields(1, 0, address, 5, BigInt(200 + iteration), BigInt("ffffffff",16), 31, false)
      d.io.a(0).valid.poke(true.B); d.io.a(1).valid.poke(true.B)
      d.io.a(0).ready.expect(true.B); d.io.a(1).ready.expect(true.B)
      d.clock.step(); d.io.a(0).valid.poke(false.B); d.io.a(1).valid.poke(false.B)
      receive(0, 0, 5, None); receive(1, 0, 5, None)
      val expected = if(iteration % 2 == 0) 200 + iteration else 100 + iteration
      send(0, 4, address, 5); receive(0, 1, 5, Some(BigInt(expected)))
      send(1, 4, address, 5); receive(1, 1, 5, Some(BigInt(expected)))
    }
    // Random independent addresses/masks cover different-word dual-port use
    // without relying on uninitialized RAM content as an oracle.
    for(iteration <- 0 until 100) {
      val address = base + rng.nextInt(ActivationSramMap.bytes / 64) * 64
      val original = BigInt(256, rng)
      send(0, 0, address, 5, original); receive(0, 0, 5, None)
      val mask = BigInt(32, rng); val value = BigInt(256, rng)
      val byteMask = (0 until 32).filter(mask.testBit).map(i => BigInt(255) << (8*i)).foldLeft(BigInt(0))(_|_)
      send(1, 1, address, 5, value, mask); receive(1, 0, 5, None)
      send(0, 4, address, 5); receive(0, 1, 5, Some((original & ~byteMask) | (value & byteMask)))
    }
    // Restore the known pair in case the randomized region reused its word.
    send(0, 0, a64, 6, first); send(0, 0, a64, 6, second); receive(0, 0, 6, None)
    // Fill all 32 transaction slots while D is stalled. Only eight physical
    // responses may be reserved, including in-flight RAM reads.
    for(source <- 0 until 32) { send(0, 4, a64, 6, source = source) }
    d.io.clear.poke(true.B); d.clock.step(); d.io.clear.poke(false.B)
    d.io.outstanding(0).expect(32.U)
    for(source <- 0 until 32) {
      receive(0, 1, 6, Some(first), source = source)
      receive(0, 1, 6, Some(second), source = source)
    }
    d.io.outstanding(0).expect(0.U); d.io.outstanding(1).expect(0.U)
    d.reset.poke(true.B); d.clock.step(3); d.reset.poke(false.B)
    d.io.d(0).valid.expect(false.B); d.io.d(1).valid.expect(false.B)
    send(1, 4, a64, 5); receive(1, 1, 5, Some(first)) // reset did not clear data
    println(s"ASRAM_REAL_TL_BEHAVIORAL_STORE_PASS cases=$cases seed=171016 banks=1 cpu_rvv_executed=0")
  }
}
