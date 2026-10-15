package freechips.rocketchip.tile
import chisel3._
import chiseltest._
import org.chipsalliance.cde.config.Parameters
object ReplayTest extends App {
  implicit val p: Parameters = Parameters.empty.alterPartial { case TileKey => RocketTileParams() }
  for (worker <- 0 until 3; packet <- Seq(false, true)) {
    RawTester.test(new RoccCommandRouter(Seq(OpcodeSet.custom1, OpcodeSet.custom2, OpcodeSet.custom3)),
      Seq(chiseltest.simulator.IcarusBackendAnnotation)) { d =>
      val opcode = Seq(0x2b, 0x5b, 0x7b)(worker)
      var observed = Vector.empty[(Int, Int)]
      var accepted = 0
      def step(): Unit = {
        for (i <- 0 until 3) {
          if (d.io.out(i).valid.peek().litToBoolean && d.io.out(i).ready.peek().litToBoolean)
            observed :+= ((i, d.io.out(i).bits.inst.funct.peek().litValue.toInt))
          if (d.io.loopconv_request_accept(i).peek().litToBoolean) accepted += 1
        }
        d.clock.step()
      }
      def send(f: Int): Unit = {
        d.io.in.bits.inst.opcode.poke(opcode.U)
        d.io.in.bits.inst.funct.poke(f.U)
        d.io.in.valid.poke(true.B)
        d.io.in.ready.expect(true.B)
        step()
        d.io.in.valid.poke(false.B)
      }
      d.io.in.valid.poke(false.B)
      d.io.in.bits.inst.opcode.poke(0.U)
      d.io.in.bits.inst.funct.poke(0.U)
      d.io.out.foreach(_.ready.poke(false.B))
      d.reset.poke(true.B); d.clock.step(4); d.reset.poke(false.B)
      send(1); send(2) // Fill both complete-request FIFO entries.
      if (packet) (16 to 21).foreach(send)
      val blocked = if (packet) 15 else 3
      d.io.in.bits.inst.funct.poke(blocked.U)
      d.io.in.valid.poke(true.B)
      d.io.in.ready.expect(false.B); step()
      // Rocket drops valid AND opcode/funct while rocc_blocked is set.
      d.io.in.valid.poke(false.B)
      d.io.in.bits.inst.opcode.poke(0.U)
      d.io.in.bits.inst.funct.poke(127.U)
      for (_ <- 0 until 4) { d.io.in.ready.expect(false.B); step() }
      d.io.out(worker).ready.poke(true.B)
      var cycles = 0
      while (!d.io.in.ready.peek().litToBoolean && cycles < 20) { step(); cycles += 1 }
      assert(cycles < 20, "Rocket never released after FIFO space recovered")
      assert(accepted == 0, "Replay wakeup must not accept a request")
      send(blocked)
      d.io.in.bits.inst.opcode.poke(0.U)
      d.io.in.ready.expect(false.B) // Blocked latch cleared by the real handshake.
      for (_ <- 0 until 40) step()
      val expected = Vector(1, 2) ++ (if (packet) (16 to 21).toVector :+ 15 else Vector(3))
      assert(observed == expected.map(worker -> _), s"Wrong/duplicate output: $observed")
      assert(accepted == (if (packet) 1 else 0))
      d.io.busy.expect(false.B)
    }
  }
  println("LAZYROCC_REPLAY=PASS workers=3 cases=6 normal_and_packet exactly_once")
}
