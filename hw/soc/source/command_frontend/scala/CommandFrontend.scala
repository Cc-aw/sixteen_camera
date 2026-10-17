// SPDX-License-Identifier: Apache-2.0
// Native Chisel port of the board-tested AtestRuntimev5 engine and cluster.
// Canonical editable source. scripts/sync_sources.py installs into Chipyard.
package freechips.rocketchip.tile.commandfrontend

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.{Field, Parameters}
import freechips.rocketchip.tile._

case object CommandFrontendKey extends Field[Boolean](false)
case object DmaLoadBuildIdKey extends Field[BigInt](BigInt(0))

/** ABI v2: M-mode, 32-bit physical descriptors in [0x80000000, 0xffffffff].
  * Each record is 32 bytes; kind=0 RAW, 1 DRAIN, 2 HOST. End is count-based.
  * No opaque Verilog BlackBox and no generated-RTL patch is used.
  */
class CommandFrontendEngineIO extends Bundle {
  val start = Input(Bool()); val start_ready = Output(Bool())
  val table_base = Input(UInt(32.W)); val table_count = Input(UInt(32.W))
  val frame_base = Input(UInt(32.W)); val timeout_cycles = Input(UInt(32.W))
  val resume = Input(Bool()); val acknowledge = Input(Bool()); val resume_tag = Input(UInt(64.W))
  val owns_gemmini = Output(Bool()); val fence_busy = Output(Bool())
  val done = Output(Bool()); val host_wait = Output(Bool()); val fault = Output(Bool())
  val error_code = Output(UInt(8.W))
  val fetched = Output(UInt(32.W)); val issued = Output(UInt(32.W))
  val cursor = Output(UInt(32.W)); val completed_cursor = Output(UInt(32.W))
  val host_tag = Output(UInt(64.W)); val state_out = Output(UInt(4.W)); val fifo_level = Output(UInt(32.W))
  val mem_req_valid = Output(Bool()); val mem_req_ready = Input(Bool())
  val mem_req_address = Output(UInt(32.W)); val mem_resp_valid = Input(Bool())
  val mem_resp_ready = Output(Bool()); val mem_resp_data = Input(UInt(256.W)); val mem_resp_error = Input(Bool())
  val cmd_valid = Output(Bool()); val cmd_ready = Input(Bool()); val cmd_funct = Output(UInt(7.W))
  val cmd_rs1 = Output(UInt(64.W)); val cmd_rs2 = Output(UInt(64.W))
  val gemmini_busy = Input(Bool()); val gemmini_fault = Input(Bool())
}

class CommandFrontendEngine(val fifoDepth: Int = 8, val quietCycles: Int = 4,
                            val allowTargetExtensions: Boolean = false) extends Module {
  require(fifoDepth >= 2 && quietCycles >= 2)
  val io = IO(new CommandFrontendEngineIO)
  val idle = 0.U(4.W); val run = 1.U(4.W); val drain = 2.U(4.W)
  val host = 3.U(4.W); val done = 4.U(4.W); val faultDrain = 5.U(4.W); val fault = 6.U(4.W)
  val state = RegInit(idle); val reason = RegInit(0.U(2.W))
  val base = RegInit(0.U(32.W)); val count = RegInit(0.U(32.W)); val frame = RegInit(0.U(32.W))
  val timeout = RegInit(0.U(32.W)); val elapsed = RegInit(0.U(32.W)); val fetchIndex = RegInit(0.U(32.W))
  val fetched = RegInit(0.U(32.W)); val issued = RegInit(0.U(32.W))
  val cursor = RegInit(0.U(32.W)); val completed = RegInit(0.U(32.W))
  val rd = RegInit(0.U(log2Ceil(fifoDepth).W)); val wr = RegInit(0.U(log2Ceil(fifoDepth).W))
  val used = RegInit(0.U(log2Ceil(fifoDepth+1).W))
  val quiet = RegInit(0.U(log2Ceil(quietCycles+1).W))
  val awaiting = RegInit(false.B); val reqValid = RegInit(false.B); val reqAddress = RegInit(0.U(32.W))
  val cmdValid = RegInit(false.B); val functReg = RegInit(0.U(7.W))
  val rs1Reg = RegInit(0.U(64.W)); val rs2Reg = RegInit(0.U(64.W))
  val error = RegInit(0.U(8.W)); val tag = RegInit(0.U(64.W))
  val fifo = Reg(Vec(fifoDepth, UInt(256.W)))
  val head = fifo(rd); val kind = head(7,0); val funct = head(14,8)
  val rs1 = head(127,64) +& frame; val rs2 = head(191,128) +& frame
  val rs1Bad = head(16) && (rs1(64,32).orR || !rs1(31))
  val rs2Bad = head(17) && (rs2(64,32).orR || !rs2(31))
  // Target adds STORE_SPAD, LoopWS SPAD placement and SiLU LUT writes (23..26).
  // Keep clock gating (22) and response-producing diagnostic commands CPU-only.
  val supportedFunct = funct <= 21.U ||
    (allowTargetExtensions.B && funct >= 23.U && funct <= 26.U)
  val bad = head(255,192).orR || head(63,18).orR || head(15) || kind > 2.U ||
    (kind === 0.U && (!supportedFunct || rs1Bad || rs2Bad)) ||
    (kind =/= 0.U && (head(17,8).orR || head(191,128).orR)) || (kind === 1.U && head(127,64).orR)
  val take = state === run && used =/= 0.U && !cmdValid && !bad
  val reqFire = reqValid && io.mem_req_ready
  val respFire = io.mem_resp_valid && io.mem_resp_ready
  val push = respFire && !io.mem_resp_error && state =/= faultDrain
  val cmdFire = cmdValid && io.cmd_ready
  val timeoutHit = (state === run || state === drain) && timeout =/= 0.U && elapsed >= timeout
  val formatError = state === run && used =/= 0.U && !cmdValid && bad
  val transportError = respFire && io.mem_resp_error
  val activeError = (state === run || state === drain || state === host) &&
    (transportError || formatError || timeoutHit || io.gemmini_fault)
  val drained = !io.gemmini_busy && !cmdValid && quiet === quietCycles.U
  val tableEnd = io.table_base +& Cat(io.table_count(15,0), 0.U(5.W))
  val descriptorBad = io.table_base(4,0).orR || !io.table_base(31) || io.table_count === 0.U ||
    io.table_count(31,16).orR || tableEnd > "h100000000".U(33.W)

  io.start_ready := (state === idle || state === done || state === fault) &&
    !io.gemmini_busy && !io.gemmini_fault && !reqValid && !awaiting && !cmdValid
  io.owns_gemmini := state === run || state === drain || state === host || state === faultDrain
  io.fence_busy := state === run || state === drain || state === faultDrain
  io.done := state === done; io.host_wait := state === host; io.fault := error =/= 0.U
  io.error_code := error; io.fetched := fetched; io.issued := issued
  io.cursor := cursor; io.completed_cursor := completed; io.host_tag := tag
  io.state_out := state; io.fifo_level := used
  io.mem_req_valid := reqValid; io.mem_req_address := reqAddress
  io.mem_resp_ready := awaiting || reqFire
  io.cmd_valid := cmdValid; io.cmd_funct := functReg; io.cmd_rs1 := rs1Reg; io.cmd_rs2 := rs2Reg

  when(reqFire) { reqValid := false.B; awaiting := true.B; fetchIndex := fetchIndex + 1.U }
  when(respFire) { awaiting := false.B; when(!io.mem_resp_error) { fetched := fetched + 1.U } }
  when(cmdFire) { cmdValid := false.B; issued := issued + 1.U }
  when(io.gemmini_busy || cmdValid) { quiet := 0.U }
    .elsewhen(quiet < quietCycles.U) { quiet := quiet + 1.U }
  when((state === run || state === drain) && elapsed =/= "hffffffff".U) { elapsed := elapsed + 1.U }
  when(state === run && !activeError && !reqValid && !awaiting && fetchIndex < count && used < fifoDepth.U) {
    reqAddress := base + (fetchIndex << 5); reqValid := true.B
  }
  when(push) { fifo(wr) := io.mem_resp_data; wr := Mux(wr === (fifoDepth-1).U, 0.U, wr+1.U) }
  when(take && !activeError) {
    rd := Mux(rd === (fifoDepth-1).U, 0.U, rd+1.U); cursor := cursor + 1.U
    when(kind === 0.U) {
      cmdValid := true.B; functReg := funct
      rs1Reg := Mux(head(16), rs1(63,0), head(127,64))
      rs2Reg := Mux(head(17), rs2(63,0), head(191,128))
    }.otherwise {
      state := drain; quiet := 0.U; reason := Mux(kind === 1.U, 0.U, 1.U)
      when(kind === 2.U) { tag := head(127,64) }
    }
  }
  switch(Cat(push, take && !activeError)) {
    is(2.U) { used := used+1.U }; is(1.U) { used := used-1.U }
  }
  when(state === run && cursor === count && !cmdValid) { state := drain; reason := 2.U; quiet := 0.U }
  when(state === drain && drained) {
    when(reason === 0.U) { completed := cursor; state := run }
      .elsewhen(!reqValid && !awaiting) { completed := cursor; state := Mux(reason === 1.U, host, done) }
  }
  when(state === host && io.resume && io.resume_tag === tag) { state := run; elapsed := 0.U; quiet := 0.U }
  when((state === done || state === fault) && io.acknowledge) { state := idle; error := 0.U }
  when(state === faultDrain && drained && !reqValid && !awaiting) { state := fault; used := 0.U }
  when(activeError) {
    state := faultDrain
    error := Mux(transportError, 2.U, Mux(formatError, 3.U, Mux(io.gemmini_fault, 5.U, 4.U)))
  }
  // Last-connect priority matches v5: a new, valid start reinitializes bookkeeping.
  when(io.start && io.start_ready) {
    state := Mux(descriptorBad, fault, run); error := Mux(descriptorBad, 1.U, 0.U)
    base := io.table_base; count := io.table_count; frame := io.frame_base; timeout := io.timeout_cycles
    elapsed := 0.U; fetchIndex := 0.U; fetched := 0.U; issued := 0.U; cursor := 0.U; completed := 0.U
    rd := 0.U; wr := 0.U; used := 0.U; quiet := 0.U; tag := 0.U
  }
  assert(used <= fifoDepth.U, "frontend FIFO overflow")
  assert(!(reqValid && awaiting), "multiple frontend reads outstanding")
  when(io.done) { assert(!io.gemmini_busy && !cmdValid && !reqValid && !awaiting, "premature frontend completion") }
}

/** Flat ports deliberately retain the proven cluster ABI for differential tests. */
class CommandFrontendClusterIO extends Bundle {
  val dma_load_capabilities = Input(Vec(3, UInt(32.W)))
  val dma_load_mode = Output(Vec(3, UInt(2.W)))
  val control_valid = Input(Bool()); val control_ready = Output(Bool())
  val control_funct = Input(UInt(7.W)); val control_rs1 = Input(UInt(64.W)); val control_rs2 = Input(UInt(64.W))
  val control_rd = Input(UInt(5.W)); val control_xd = Input(Bool()); val control_prv = Input(UInt(2.W))
  val response_valid = Output(Bool()); val response_ready = Input(Bool())
  val response_rd = Output(UInt(5.W)); val response_data = Output(UInt(64.W))
  val interrupt = Output(Bool()); val transport_busy = Output(Bool())
  val legacy_valid = Input(UInt(3.W)); val legacy_ready = Output(UInt(3.W))
  val legacy_funct = Input(UInt(21.W)); val legacy_rs1 = Input(UInt(192.W)); val legacy_rs2 = Input(UInt(192.W))
  val stream_owner = Output(UInt(3.W)); val gemmini_cmd_valid = Output(UInt(3.W)); val gemmini_cmd_ready = Input(UInt(3.W))
  val gemmini_cmd_funct = Output(UInt(21.W)); val gemmini_cmd_rs1 = Output(UInt(192.W)); val gemmini_cmd_rs2 = Output(UInt(192.W))
  val gemmini_busy = Input(UInt(3.W)); val gemmini_fault = Input(UInt(3.W))
  val mem_req_valid = Output(UInt(3.W)); val mem_req_ready = Input(UInt(3.W)); val mem_req_address = Output(UInt(96.W))
  val mem_resp_valid = Input(UInt(3.W)); val mem_resp_ready = Output(UInt(3.W))
  val mem_resp_data = Input(UInt(768.W)); val mem_resp_error = Input(UInt(3.W))
}

class CommandFrontendCluster(val allowTargetExtensions: Boolean = false,
                             val dmaLoadBuildId: BigInt = 0) extends Module {
  val io = IO(new CommandFrontendClusterIO)
  val cycle = RegInit(0.U(64.W)); cycle := cycle + 1.U
  val armed = RegInit(VecInit(Seq.fill(3)(false.B)))
  val dmaLoadMode = RegInit(VecInit(Seq.fill(3)(0.U(2.W))))
  val modeSwitchRejects = RegInit(VecInit(Seq.fill(3)(0.U(32.W))))
  io.dma_load_mode := dmaLoadMode
  val irqEnable = RegInit(VecInit(Seq.fill(3)(false.B)))
  val engines = Seq.fill(3)(Module(new CommandFrontendEngine(allowTargetExtensions = allowTargetExtensions)))
  val available = Wire(Vec(3, Bool())); val owner = Wire(Vec(3, Bool()))
  val launch = Wire(Vec(3, Bool())); val armPulse = Wire(Vec(3, Bool())); val cancel = Wire(Vec(3, Bool()))
  val complete = VecInit(engines.map(_.io.done)).asUInt
  val hostWait = VecInit(engines.map(_.io.host_wait)).asUInt
  val fault = VecInit(engines.map(_.io.fault)).asUInt
  val events = complete | hostWait | fault
  val pending = events & irqEnable.asUInt
  val responseValid = RegInit(false.B); val responseRd = RegInit(0.U(5.W)); val responseData = RegInit(0.U(64.W))
  io.control_ready := !responseValid || io.response_ready
  io.response_valid := responseValid; io.response_rd := responseRd; io.response_data := responseData
  io.interrupt := pending.orR; io.transport_busy := responseValid
  val fire = io.control_valid && io.control_ready && io.control_prv === 3.U
  val channel = io.control_funct(6,5); val op = io.control_funct(4,0)
  val globalArm = fire && channel === 3.U && op === 7.U && io.control_rs1 =/= 0.U &&
    !io.control_rs1(63,3).orR && !io.control_rs2(63,3).orR &&
    (io.control_rs1(2,0) & ~available.asUInt) === 0.U
  val readValue = Wire(Vec(3, UInt(64.W)))
  val selected = WireDefault("hfffffffffffffffe".U(64.W))
  when(channel =/= 3.U) { selected := readValue(channel) }.otherwise {
    switch(io.control_rs1) {
      is(0.U) { selected := Cat("h00020000".U(32.W), 0.U(13.W), events, 0.U(5.W), irqEnable.asUInt, 0.U(5.W), pending) }
      is(1.U) { selected := Cat(0.U(37.W), armed.asUInt, 0.U(5.W), available.asUInt, 0.U(5.W), io.gemmini_busy, 0.U(5.W), owner.asUInt) }
      is(2.U) { selected := cycle }
    }
  }
  when(io.response_ready) { responseValid := false.B }
  when(io.control_valid && io.control_ready) {
    responseValid := io.control_xd; responseRd := io.control_rd; responseData := "hffffffffffffffff".U
    when(fire) {
      when(op === 3.U && io.control_rs2 === 0.U) { responseData := selected }
        .elsewhen(globalArm) { responseData := 0.U }
        .elsewhen(channel =/= 3.U) {
          switch(op) {
            is(0.U,1.U) { when(available(channel) && !io.control_rs1(63,32).orR && !io.control_rs2(63,32).orR) { responseData := 0.U } }
            is(2.U) { when(launch(channel) && !armed(channel)) { responseData := 0.U } }
            is(4.U) { when(hostWait(channel) && io.control_rs1 === readValue(channel) && io.control_rs2 === 0.U) { responseData := 0.U } }
            is(5.U) { when((complete(channel) || fault(channel)) && !VecInit(engines.map(_.io.owns_gemmini))(channel) && io.control_rs1 === 0.U && io.control_rs2 === 0.U) { responseData := 0.U } }
            is(6.U) { when(available(channel) && io.control_rs2 === 0.U) { responseData := 0.U } }
            is(7.U) { when(armPulse(channel)) { responseData := 0.U } }
            is(8.U) { when(cancel(channel)) { responseData := 0.U } }
            // ABI2 additive diagnostic extension: op9 sets a drained lane;
            // read selectors 7/8 expose capability and effective mode.
            is(9.U) {
              responseData := Mux(io.dma_load_capabilities(channel) === 0.U, 3.U,
                Mux(io.control_rs1 > 2.U || io.control_rs2 =/= 0.U, 2.U,
                  Mux(io.gemmini_fault(channel), 4.U, Mux(available(channel), 0.U, 1.U))))
            }
          }
        }
    }
  }
  val legacyReady = Wire(Vec(3, Bool())); val cmdValid = Wire(Vec(3, Bool()))
  val cmdFunct = Wire(Vec(3, UInt(7.W))); val cmdRs1 = Wire(Vec(3, UInt(64.W))); val cmdRs2 = Wire(Vec(3, UInt(64.W)))
  for (g <- 0 until 3) {
    val e = engines(g).io
    val base = RegInit(0.U(32.W)); val length = RegInit(0.U(32.W)); val frame = RegInit(0.U(32.W)); val deadline = RegInit(0.U(32.W))
    val release = RegInit(0.U(64.W)); val lastStart = RegInit(0.U(64.W))
    val select = fire && channel === g.U
    available(g) := e.start_ready && !armed(g) && !io.legacy_valid(g) && !events(g)
    cancel(g) := select && op === 8.U && armed(g) && io.control_rs1 === 0.U && io.control_rs2 === 0.U
    armPulse(g) := (globalArm && io.control_rs1(g)) ||
      (select && op === 7.U && available(g) && !io.control_rs1(63,1).orR && io.control_rs2 === 0.U)
    launch(g) := (armed(g) && cycle >= release && e.start_ready && !cancel(g)) ||
      (select && op === 2.U && available(g) && !io.control_rs1(63,1).orR && io.control_rs2 === 0.U)
    owner(g) := e.owns_gemmini || armed(g)
    legacyReady(g) := !owner(g) && !launch(g) && !armPulse(g) && io.gemmini_cmd_ready(g)
    cmdValid(g) := Mux(e.owns_gemmini, e.cmd_valid, io.legacy_valid(g) && !armed(g) && !launch(g) && !armPulse(g))
    cmdFunct(g) := Mux(e.owns_gemmini, e.cmd_funct, io.legacy_funct(7*g+6,7*g))
    cmdRs1(g) := Mux(e.owns_gemmini, e.cmd_rs1, io.legacy_rs1(64*g+63,64*g))
    cmdRs2(g) := Mux(e.owns_gemmini, e.cmd_rs2, io.legacy_rs2(64*g+63,64*g))
    e.cmd_ready := e.owns_gemmini && io.gemmini_cmd_ready(g)
    val status = Cat("h00020000".U(32.W), e.fifo_level(15,0), e.error_code,
      armed(g), e.fence_busy, io.gemmini_busy(g), available(g), e.fault, e.host_wait, e.done, owner(g))
    readValue(g) := Mux(op === 4.U, e.host_tag, MuxLookup(io.control_rs1, "hfffffffffffffffe".U(64.W))(Seq(
      0.U -> status, 1.U -> Cat(e.fetched,e.issued), 2.U -> Cat(e.completed_cursor,e.cursor),
      3.U -> e.host_tag, 4.U -> Cat(0.U(60.W),e.state_out), 5.U -> release, 6.U -> lastStart,
      7.U -> io.dma_load_capabilities(g), 8.U -> dmaLoadMode(g),
      9.U -> modeSwitchRejects(g), 10.U -> dmaLoadBuildId.U(64.W))))
    when(select && op === 9.U && !(available(g) && !io.gemmini_fault(g) &&
      io.dma_load_capabilities(g) =/= 0.U && io.control_rs1 <= 2.U && io.control_rs2 === 0.U)) {
      modeSwitchRejects(g) := modeSwitchRejects(g) + 1.U
    }
    when(select && op === 9.U && available(g) && !io.gemmini_fault(g) &&
      io.dma_load_capabilities(g) =/= 0.U && io.control_rs1 <= 2.U && io.control_rs2 === 0.U) {
      dmaLoadMode(g) := io.control_rs1
    }
    val acknowledge = select && op === 5.U && !armed(g) && io.control_rs1 === 0.U && io.control_rs2 === 0.U
    when(select && available(g)) {
      when(!io.control_rs1(63,32).orR && !io.control_rs2(63,32).orR) {
        when(op === 0.U) { base := io.control_rs1; length := io.control_rs2 }
        when(op === 1.U) { frame := io.control_rs1; deadline := io.control_rs2 }
      }
      when(op === 6.U && io.control_rs2 === 0.U) { release := io.control_rs1 }
    }
    when(armPulse(g)) { armed(g) := true.B; irqEnable(g) := Mux(globalArm, io.control_rs2(g), io.control_rs1(0)) }
    when(launch(g)) { lastStart := cycle; armed(g) := false.B; when(!armed(g)) { irqEnable(g) := io.control_rs1(0) } }
    when(cancel(g)) { armed(g) := false.B; irqEnable(g) := false.B }
    when(acknowledge && (e.done || e.state_out === 6.U)) { irqEnable(g) := false.B }
    e.start := launch(g); e.table_base := base; e.table_count := length; e.frame_base := frame; e.timeout_cycles := deadline
    e.resume := select && op === 4.U && io.control_rs2 === 0.U; e.resume_tag := io.control_rs1; e.acknowledge := acknowledge
    e.mem_req_ready := io.mem_req_ready(g); e.mem_resp_valid := io.mem_resp_valid(g)
    e.mem_resp_data := io.mem_resp_data(g*256+255,g*256); e.mem_resp_error := io.mem_resp_error(g)
    e.gemmini_busy := io.gemmini_busy(g); e.gemmini_fault := io.gemmini_fault(g)
  }
  io.stream_owner := owner.asUInt; io.legacy_ready := legacyReady.asUInt; io.gemmini_cmd_valid := cmdValid.asUInt
  io.gemmini_cmd_funct := cmdFunct.asUInt; io.gemmini_cmd_rs1 := cmdRs1.asUInt; io.gemmini_cmd_rs2 := cmdRs2.asUInt
  io.mem_req_valid := VecInit(engines.map(_.io.mem_req_valid)).asUInt
  io.mem_req_address := VecInit(engines.map(_.io.mem_req_address)).asUInt
  io.mem_resp_ready := VecInit(engines.map(_.io.mem_resp_ready)).asUInt
}
