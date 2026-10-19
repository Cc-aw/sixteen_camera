// SPDX-License-Identifier: Apache-2.0
package freechips.rocketchip.tile.commandfrontend

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import org.chipsalliance.diplomacy.lazymodule._
import freechips.rocketchip.tilelink._

class CommandFrontendMemoryIO(val addrBits: Int, val sizeBits: Int, val sinkBits: Int, val sourceBits: Int) extends Bundle {
  val f_req_valid = Input(Bool()); val f_req_ready = Output(Bool()); val f_req_address = Input(UInt(32.W))
  val f_resp_valid = Output(Bool()); val f_resp_ready = Input(Bool())
  val f_resp_data = Output(UInt(256.W)); val f_resp_error = Output(Bool())
  val g_a_valid = Input(Bool()); val g_a_ready = Output(Bool())
  val g_a_opcode = Input(UInt(3.W)); val g_a_param = Input(UInt(3.W)); val g_a_size = Input(UInt(sizeBits.W))
  val g_a_source = Input(UInt(sourceBits.W)); val g_a_address = Input(UInt(addrBits.W)); val g_a_mask = Input(UInt(32.W))
  val g_a_data = Input(UInt(256.W)); val g_a_corrupt = Input(Bool())
  val g_d_valid = Output(Bool()); val g_d_ready = Input(Bool())
  val g_d_opcode = Output(UInt(3.W)); val g_d_param = Output(UInt(2.W)); val g_d_size = Output(UInt(sizeBits.W))
  val g_d_source = Output(UInt(sourceBits.W)); val g_d_sink = Output(UInt(sinkBits.W))
  val g_d_denied = Output(Bool()); val g_d_data = Output(UInt(256.W)); val g_d_corrupt = Output(Bool())
  val a_valid = Output(Bool()); val a_ready = Input(Bool())
  val a_opcode = Output(UInt(3.W)); val a_param = Output(UInt(3.W)); val a_size = Output(UInt(sizeBits.W))
  val a_source = Output(UInt(sourceBits.W)); val a_address = Output(UInt(addrBits.W)); val a_mask = Output(UInt(32.W))
  val a_data = Output(UInt(256.W)); val a_corrupt = Output(Bool())
  val d_valid = Input(Bool()); val d_ready = Output(Bool())
  val d_opcode = Input(UInt(3.W)); val d_param = Input(UInt(2.W)); val d_size = Input(UInt(sizeBits.W))
  val d_source = Input(UInt(sourceBits.W)); val d_sink = Input(UInt(sinkBits.W)); val d_denied = Input(Bool())
  val d_data = Input(UInt(256.W)); val d_corrupt = Input(Bool())
}

/** Lease source31 only while unused by the DMA; never silently reserve it away.
  * Full-width target addresses pass through untouched. Only fetch ABI is 32-bit.
  * Lock A across stalls/multibeat writes; release ID only at the final D beat.
  */
class CommandFrontendMemoryMux(addrBits: Int = 32, sizeBits: Int = 4, sinkBits: Int = 5, sourceBits: Int = 5) extends Module {
  require(addrBits >= 32 && sizeBits >= 3 && sizeBits <= 4 && sinkBits > 0)
  require(sourceBits >= 5)
  val io = IO(new CommandFrontendMemoryIO(addrBits, sizeBits, sinkBits, sourceBits))
  val locked = RegInit(false.B); val selectedF = RegInit(false.B); val preferF = RegInit(true.B)
  val aLeft = RegInit(0.U(11.W)); val dLeft = RegInit(0.U(11.W))
  val idBusy = RegInit(false.B); val idFrontend = RegInit(false.B)
  val eligibleF = io.f_req_valid && !idBusy
  val eligibleG = io.g_a_valid && (io.g_a_source =/= 31.U || !idBusy || aLeft =/= 0.U)
  val chooseF = Mux(locked, selectedF, eligibleF && (!eligibleG || preferF))
  io.a_valid := Mux(locked, Mux(chooseF, io.f_req_valid, io.g_a_valid), eligibleF || eligibleG)
  io.a_opcode := Mux(chooseF, 4.U, io.g_a_opcode); io.a_param := Mux(chooseF, 0.U, io.g_a_param)
  io.a_size := Mux(chooseF, 5.U, io.g_a_size); io.a_source := Mux(chooseF, 31.U, io.g_a_source)
  io.a_address := Mux(chooseF, io.f_req_address, io.g_a_address)
  io.a_mask := Mux(chooseF, "hffffffff".U, io.g_a_mask); io.a_data := Mux(chooseF, 0.U, io.g_a_data)
  io.a_corrupt := !chooseF && io.g_a_corrupt
  io.f_req_ready := io.a_ready && io.a_valid && chooseF
  io.g_a_ready := io.a_ready && io.a_valid && !chooseF
  val aFire = io.a_valid && io.a_ready
  val firstA = aLeft === 0.U
  val allocate = aFire && firstA && io.a_source === 31.U
  val responseF = io.d_source === 31.U && Mux(idBusy, idFrontend, allocate && chooseF)
  io.f_resp_valid := io.d_valid && responseF; io.f_resp_data := io.d_data
  io.f_resp_error := io.d_denied || io.d_corrupt || io.d_opcode =/= 1.U || io.d_size =/= 5.U
  io.g_d_valid := io.d_valid && !responseF
  io.g_d_opcode := io.d_opcode; io.g_d_param := io.d_param; io.g_d_size := io.d_size
  io.g_d_source := io.d_source; io.g_d_sink := io.d_sink; io.g_d_denied := io.d_denied
  io.g_d_data := io.d_data; io.g_d_corrupt := io.d_corrupt
  io.d_ready := Mux(responseF, io.f_resp_ready, io.g_d_ready)
  val dFire = io.d_valid && io.d_ready && io.d_source === 31.U
  def extra(size: UInt): UInt = Mux(size > 5.U, ((1.U(11.W) << (size-5.U))-1.U)(10,0), 0.U)
  val initA = Mux(io.a_opcode <= 1.U, extra(io.a_size), 0.U)
  val initD = Mux(io.d_opcode === 1.U, extra(io.d_size), 0.U)
  when(io.a_valid && !io.a_ready) { locked := true.B; selectedF := chooseF }
  when(aFire) {
    aLeft := Mux(firstA, initA, aLeft-1.U)
    locked := Mux(firstA, initA =/= 0.U, aLeft =/= 1.U)
    selectedF := chooseF; preferF := !chooseF
  }
  when(allocate) { idBusy := true.B; idFrontend := chooseF }
  when(dFire) {
    dLeft := Mux(dLeft === 0.U, initD, dLeft-1.U)
    when((dLeft === 0.U && initD === 0.U) || dLeft === 1.U) { idBusy := false.B }
  }
  assert(!(allocate && idBusy), "source31 reused before final response")
  assert(!(dFire && !idBusy && !allocate), "source31 response without owner")
}

class CommandFetchPort extends Bundle {
  val req_valid = Input(Bool()); val req_ready = Output(Bool()); val req_address = Input(UInt(32.W))
  val resp_valid = Output(Bool()); val resp_ready = Input(Bool())
  val resp_data = Output(UInt(256.W)); val resp_error = Output(Bool())
}

/** Same negotiated masters/IDs as the original lane. No extra global TL master. */
class CommandFrontendTL(implicit p: Parameters) extends LazyModule {
  val node = TLAdapterNode(clientFn = x => x, managerFn = x => x)
  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val fetch = IO(new CommandFetchPort)
    require(node.in.size == 1 && node.out.size == 1, "frontend requires one dedicated DMA port")
    val (in, edgeIn) = node.in.head; val (out, edgeOut) = node.out.head
    require(edgeOut.bundle.dataBits == 256 && edgeOut.bundle.sourceBits >= 5)
    require(edgeOut.client.masters.exists(_.sourceId.contains(31)) && !edgeOut.client.anySupportProbe,
      "source31 lease requires a non-caching DMA with existing source31")
    val mux = Module(new CommandFrontendMemoryMux(edgeOut.bundle.addressBits, edgeOut.bundle.sizeBits,
      edgeOut.bundle.sinkBits, edgeOut.bundle.sourceBits))
    val m = mux.io
    m.f_req_valid := fetch.req_valid; fetch.req_ready := m.f_req_ready; m.f_req_address := fetch.req_address
    fetch.resp_valid := m.f_resp_valid; m.f_resp_ready := fetch.resp_ready
    fetch.resp_data := m.f_resp_data; fetch.resp_error := m.f_resp_error
    m.g_a_valid := in.a.valid; in.a.ready := m.g_a_ready
    m.g_a_opcode := in.a.bits.opcode; m.g_a_param := in.a.bits.param; m.g_a_size := in.a.bits.size
    m.g_a_source := in.a.bits.source; m.g_a_address := in.a.bits.address; m.g_a_mask := in.a.bits.mask
    m.g_a_data := in.a.bits.data; m.g_a_corrupt := in.a.bits.corrupt
    in.d.valid := m.g_d_valid; m.g_d_ready := in.d.ready
    in.d.bits := 0.U.asTypeOf(in.d.bits)
    in.d.bits.opcode := m.g_d_opcode; in.d.bits.param := m.g_d_param; in.d.bits.size := m.g_d_size
    in.d.bits.source := m.g_d_source; in.d.bits.sink := m.g_d_sink; in.d.bits.denied := m.g_d_denied
    in.d.bits.data := m.g_d_data; in.d.bits.corrupt := m.g_d_corrupt
    out.a.valid := m.a_valid; m.a_ready := out.a.ready
    out.a.bits := 0.U.asTypeOf(out.a.bits)
    out.a.bits.opcode := m.a_opcode; out.a.bits.param := m.a_param; out.a.bits.size := m.a_size
    out.a.bits.source := m.a_source; out.a.bits.address := m.a_address; out.a.bits.mask := m.a_mask
    out.a.bits.data := m.a_data; out.a.bits.corrupt := m.a_corrupt
    m.d_valid := out.d.valid; out.d.ready := m.d_ready
    m.d_opcode := out.d.bits.opcode; m.d_param := out.d.bits.param; m.d_size := out.d.bits.size
    m.d_source := out.d.bits.source; m.d_sink := out.d.bits.sink; m.d_denied := out.d.bits.denied
    m.d_data := out.d.bits.data; m.d_corrupt := out.d.bits.corrupt
    in.b.valid := false.B; in.b.bits := 0.U.asTypeOf(in.b.bits)
    in.c.ready := true.B; in.e.ready := true.B
    out.b.ready := true.B; out.c.valid := false.B; out.c.bits := 0.U.asTypeOf(out.c.bits)
    out.e.valid := false.B; out.e.bits := 0.U.asTypeOf(out.e.bits)
  }
}
