// SPDX-License-Identifier: Apache-2.0
package freechips.rocketchip.tile.commandfrontend

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.tile._

object CommandFrontendAttach {
  def connect(frontend: CommandFrontendCluster, router: RoccCommandRouter,
              arb: RRArbiter[RoCCResponse], roccs: Seq[LazyRoCC],
              memory: Seq[CommandFrontendTL])(implicit p: Parameters): Unit = {
    require(roccs.size == 3 && memory.size == 3)
    val f = frontend.io
    val ctl = router.io.out(3)
    f.control_valid := ctl.valid; ctl.ready := f.control_ready
    f.control_funct := ctl.bits.inst.funct; f.control_rs1 := ctl.bits.rs1; f.control_rs2 := ctl.bits.rs2
    f.control_rd := ctl.bits.inst.rd; f.control_xd := ctl.bits.inst.xd; f.control_prv := ctl.bits.status.prv
    arb.io.in(3).valid := f.response_valid; f.response_ready := arb.io.in(3).ready
    arb.io.in(3).bits.rd := f.response_rd; arb.io.in(3).bits.data := f.response_data
    def pack(xs: Seq[UInt]): UInt = Cat(xs.reverse)
    f.legacy_valid := VecInit((0 until 3).map(router.io.out(_).valid)).asUInt
    f.legacy_funct := pack((0 until 3).map(router.io.out(_).bits.inst.funct))
    f.legacy_rs1 := pack((0 until 3).map(router.io.out(_).bits.rs1))
    f.legacy_rs2 := pack((0 until 3).map(router.io.out(_).bits.rs2))
    f.gemmini_cmd_ready := VecInit(roccs.map(_.module.io.cmd.ready)).asUInt
    f.gemmini_busy := VecInit(roccs.map(_.module.io.busy)).asUInt
    f.gemmini_fault := VecInit(roccs.map(_.module.io.interrupt)).asUInt
    f.mem_req_ready := VecInit(memory.map(_.module.fetch.req_ready)).asUInt
    f.mem_resp_valid := VecInit(memory.map(_.module.fetch.resp_valid)).asUInt
    f.mem_resp_data := pack(memory.map(_.module.fetch.resp_data))
    f.mem_resp_error := VecInit(memory.map(_.module.fetch.resp_error)).asUInt
    f.mem_resp_last := VecInit(memory.map(_.module.fetch.resp_last)).asUInt
    for (i <- 0 until 3) {
      val g = roccs(i).module.io
      g.dma_load_mode := f.dma_load_mode(i)
      f.dma_load_capabilities(i) := g.dma_load_capabilities
      val automatic = Wire(new RoCCCommand)
      automatic := 0.U.asTypeOf(automatic)
      automatic.inst.opcode := Seq(0x0b,0x2b,0x5b)(i).U
      automatic.inst.xs1 := true.B; automatic.inst.xs2 := true.B
      automatic.status.prv := 3.U; automatic.status.dprv := 3.U; automatic.status.mpp := 3.U
      automatic.inst.funct := f.gemmini_cmd_funct(i*7+6,i*7)
      automatic.rs1 := f.gemmini_cmd_rs1(i*64+63,i*64)
      automatic.rs2 := f.gemmini_cmd_rs2(i*64+63,i*64)
      g.cmd.bits := Mux(f.stream_owner(i), automatic, router.io.out(i).bits)
      g.cmd.valid := f.gemmini_cmd_valid(i)
      router.io.out(i).ready := f.legacy_ready(i)
      // Old ingress FIFO is absent. Accept means the actual RUN handshake.
      g.loopconv_request_accept := g.cmd.fire && g.cmd.bits.inst.funct === 15.U
      g.loopconv_request_queue_count := 0.U
      g.loopconv_assembler_partial := false.B
      g.loopconv_ingress_debug := 0.U
      val m = memory(i).module.fetch
      m.req_valid := f.mem_req_valid(i); m.req_address := f.mem_req_address(32*i+31,32*i)
      m.req_size := f.mem_req_size(3*i+2,3*i)
      m.resp_ready := f.mem_resp_ready(i)
    }
  }
}
