package gemmini

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

/** Two ordered command contexts. Physical fragments return by owner/offset;
  * logical row replay and command credits use separate identities. */
class DmaLoadGroup[T <: Data, U <: Data, V <: Data](config: GemminiArrayConfig[T, U, V])
    (implicit p: Parameters) extends Module {
  import config._
  val local = local_addr_t
  val io = IO(new Bundle {
    val in = Flipped(Decoupled(new ScratchpadMemReadRequest(local, mvin_scale_t_bits)))
    val mode = Input(UInt(2.W))
    val eligible = Output(Bool())
    val request = Decoupled(new StreamReadRequest(local.spRows, local.accRows, mvin_scale_t_bits))
    val fragment = Flipped(Decoupled(new DmaLoadFragment))
    val replay = Decoupled(new StreamReadResponse(256, 1024, local.spRows, local.accRows, 1, mvin_scale_t_bits))
    val completed = Flipped(Valid(new Bundle {
      val group_id = UInt(1.W)
      val bytes = UInt(16.W)
    }))
    val busy = Output(Bool())
    val fault = Output(Bool())
    val readerFault = Input(Bool())
    val terminalReady = Output(Vec(2, Bool()))
    val accepted = Output(Bool())
    val occupancy = Output(UInt(2.W))
    val counter = new CounterEventIO
  })
  val free :: collect :: fetch :: emit :: retire :: Nil = Enum(5)
  val state = RegInit(VecInit(Seq.fill(2)(free)))
  val descriptor = Reg(Vec(2, chiselTypeOf(io.in.bits)))
  val modes = Reg(Vec(2, UInt(2.W)))
  val rows = Reg(Vec(2, UInt(6.W)))
  val issued = Reg(Vec(2, UInt(11.W)))
  val received = Reg(Vec(2, UInt(11.W)))
  val credited = Reg(Vec(2, UInt(11.W)))
  val inflight = RegInit(VecInit(Seq.fill(2)(0.U(7.W))))
  val validBytes = RegInit(VecInit(Seq.fill(2)(VecInit(Seq.fill(32)(0.U(32.W))))))
  val replayed = RegInit(VecInit(Seq.fill(2)(0.U(6.W))))
  val faultNow = Wire(Bool())
  val fetchAddress = Reg(Vec(2, UInt(io.in.bits.vaddr.getWidth.W)))
  val fetchRow = Reg(Vec(2, UInt(6.W)))
  val rowLeft = Reg(Vec(2, UInt(6.W)))
  val head = RegInit(0.U(1.W))
  val tail = RegInit(0.U(1.W))
  val collecting = RegInit(false.B)
  val fault = RegInit(false.B)
  val first = io.in.bits
  val endAddress = first.vaddr +& (first.cmd_rows - 1.U) * first.cmd_stride_bytes +& first.cols
  val endLocal = first.laddr.full_sp_addr() +& first.cmd_rows - 1.U
  val half = local.spRows / 2
  val sameHalf = endLocal < local.spRows.U &&
    ((first.laddr.full_sp_addr() < half.U) === (endLocal < half.U))
  val allowLocal = p(freechips.rocketchip.tile.commandfrontend.ActivationSramKey)
  val normalMemory = (first.vaddr >= "h80000000".U && endAddress <= "h100000000".U) ||
    (allowLocal.B && ActivationSramDmaAddress.localRange(first.vaddr, endAddress))
  val continuous = first.cmd_stride_bytes === first.cols
  val readMerge = continuous && first.cmd_rows > 1.U
  val assemble = io.mode === 2.U || io.mode === 3.U
  io.eligible := io.mode =/= 0.U && !first.laddr.is_acc_addr && !first.laddr.accumulate &&
    !first.has_acc_bitwidth && first.repeats === 0.U && first.cols =/= 0.U && first.cols < 32.U &&
    first.cmd_rows =/= 0.U && first.cmd_rows <= 32.U && first.pixel_repeats =/= 0.U &&
    first.pixel_repeats <= dma_load_max_pixel_repeats.U && first.pixel_repeats * first.cols <= 32.U &&
    sameHalf && Mux(first.all_zeros, assemble,
      normalMemory && (readMerge || (assemble && first.pixel_repeats > 1.U)))
  // tail cannot advance until the complete command has been collected.
  io.in.ready := !faultNow && Mux(collecting, true.B, state(tail) === free)
  io.accepted := io.in.fire && first.cmd_first
  when(io.in.fire) {
    when(!collecting) {
      assert(first.cmd_first && first.row_index === 0.U && io.eligible)
      descriptor(tail) := first
      modes(tail) := io.mode
      validBytes(tail) := VecInit(Seq.fill(32)(0.U(32.W)))
      replayed(tail) := 0.U
      inflight(tail) := 0.U
      rows(tail) := 1.U
      issued(tail) := 0.U; received(tail) := 0.U; credited(tail) := 0.U
      fetchAddress(tail) := first.vaddr; fetchRow(tail) := 0.U; rowLeft(tail) := first.cols
      state(tail) := Mux(first.cmd_last, fetch, collect)
    }.otherwise {
      val original = descriptor(tail)
      assert(!first.cmd_first && first.row_index === rows(tail))
      assert(first.cmd_id === original.cmd_id && first.cols === original.cols &&
        first.has_acc_bitwidth === original.has_acc_bitwidth && first.repeats === original.repeats &&
        first.scale === original.scale && first.pixel_repeats === original.pixel_repeats &&
        first.cmd_stride_bytes === original.cmd_stride_bytes && first.cmd_rows === original.cmd_rows &&
        first.all_zeros === original.all_zeros && first.status.asUInt === original.status.asUInt &&
        first.block_stride === original.block_stride)
      assert(first.laddr.asUInt === (original.laddr + rows(tail)).asUInt)
      assert(first.vaddr === original.vaddr + rows(tail) * original.cmd_stride_bytes)
      rows(tail) := rows(tail) + 1.U
      when(first.cmd_last) {
        assert(first.row_index +& 1.U === original.cmd_rows)
        state(tail) := fetch
      }
    }
    collecting := !first.cmd_last
    when(first.cmd_last) { tail := ~tail }
  }

  val total = Wire(Vec(2, UInt(11.W)))
  for(g <- 0 until 2) { total(g) := descriptor(g).cols * descriptor(g).cmd_rows }
  val wants = VecInit((0 until 2).map(g => (state(g) === fetch || state(g) === emit || state(g) === retire) &&
    !descriptor(g).all_zeros && issued(g) < total(g)))
  val preferred = RegInit(0.U(1.W))
  val held = RegInit(false.B)
  val heldSelection = Reg(UInt(1.W))
  val selected = Mux(held, heldSelection, Mux(wants(preferred), preferred, ~preferred))
  val selectedDescriptor = descriptor(selected)
  // Mode 3 keeps the same ordered collection/replay and SPAD assembler,
  // but forbids a physical request from consuming bytes of adjacent rows.
  // This isolates cross-row TL merging; it does not bypass group buffering.
  val contiguous = selectedDescriptor.cmd_stride_bytes === selectedDescriptor.cols && modes(selected) =/= 3.U
  val planner = Module(new DmaLoadReadPlanner(first.vaddr.getWidth, allowActivationSram = allowLocal))
  planner.io.address := fetchAddress(selected)
  planner.io.remaining := Mux(contiguous, total(selected) - issued(selected), rowLeft(selected))
  io.request.valid := wants.asUInt.orR && !faultNow && planner.io.legal
  io.request.bits := 0.U.asTypeOf(io.request.bits)
  io.request.bits.vaddr := planner.io.address
  io.request.bits.len := planner.io.bytes
  io.request.bits.status := selectedDescriptor.status
  io.request.bits.group := true.B
  io.request.bits.group_id := selected
  io.request.bits.group_offset := issued(selected)
  when(io.request.valid && !io.request.ready) { held := true.B; heldSelection := selected }
  // The core creates exactly one bounded TL transaction for this fragment.
  // spaddr/block_stride are irrelevant to the explicitly separated return.
  when(io.request.fire) {
    held := false.B
    issued(selected) := issued(selected) + planner.io.bytes
    preferred := ~selected
    when(!contiguous && planner.io.bytes === rowLeft(selected)) {
      fetchRow(selected) := fetchRow(selected) + 1.U
      fetchAddress(selected) := selectedDescriptor.vaddr +
        (fetchRow(selected) + 1.U) * selectedDescriptor.cmd_stride_bytes
      rowLeft(selected) := selectedDescriptor.cols
    }.otherwise {
      fetchAddress(selected) := fetchAddress(selected) + planner.io.bytes
      rowLeft(selected) := rowLeft(selected) - planner.io.bytes
    }
  }
  when(wants.asUInt.orR && !planner.io.legal) { fault := true.B }

  // Thirty-two byte banks provide one write and one synchronous read per
  // cycle. A fragment/row crosses at most two adjacent 32-byte words.
  val memory = Seq.fill(32)(SyncReadMem(64, UInt(8.W)))
  val f = io.fragment.bits
  io.fragment.ready := true.B // capacity was reserved at command acceptance
  val returnOwnerValid = state(f.group_id) =/= free && state(f.group_id) =/= collect
  val returnWord = f.offset(9, 5)
  val returnMask = (((1.U(33.W) << f.bytes) - 1.U)(31, 0).pad(64) << f.offset(4, 0))(63, 0)
  val returnHave = Cat(Mux(returnWord === 31.U, 0.U(32.W),
    validBytes(f.group_id)(returnWord + 1.U)), validBytes(f.group_id)(returnWord))
  val duplicate = (returnHave & returnMask).orR
  val badFragment = io.fragment.valid && (f.error || !returnOwnerValid ||
    f.bytes > 32.U || f.offset +& f.bytes > total(f.group_id) || duplicate ||
    (f.transaction_last && inflight(f.group_id) === 0.U))
  faultNow := fault || io.readerFault || badFragment
  when(faultNow) { fault := true.B }
  val acceptData = io.fragment.fire && !badFragment && !fault
  when(acceptData) {
    received(f.group_id) := received(f.group_id) + f.bytes
    assert(received(f.group_id) +& f.bytes <= total(f.group_id))
  }
  for(g <- 0 until 2) {
    val add = io.request.fire && selected === g.U
    val remove = io.fragment.fire && f.transaction_last && returnOwnerValid && f.group_id === g.U && inflight(g) =/= 0.U
    when(add || remove) {
      assert(inflight(g) +& add.asUInt >= remove.asUInt, "physical transaction underflow")
      inflight(g) := inflight(g) + add.asUInt - remove.asUInt
    }
    for(w <- 0 until 32) {
      val mask = Mux(returnWord === w.U, returnMask(31, 0),
        Mux(returnWord +& 1.U === w.U, returnMask(63, 32), 0.U(32.W)))
      when(acceptData && f.group_id === g.U) { validBytes(g)(w) := validBytes(g)(w) | mask }
    }
    // A1 starts replay as soon as collection is complete. With the switch
    // disabled the same source retains the original all-return barrier.
    when(state(g) === fetch && (dma_load_streaming_enable.B || descriptor(g).all_zeros ||
      (issued(g) === total(g) && received(g) === total(g) && inflight(g) === 0.U))) {
      state(g) := emit
    }
  }
  for(b <- 0 until 32) {
    val delta = (b.U(5.W) - f.offset(4, 0))(4, 0)
    val pos = f.offset +& delta
    when(acceptData && delta < f.bytes) {
      memory(b).write(Cat(f.group_id, pos(9, 5)), (f.data >> (delta << 3))(7, 0))
    }
  }

  val rowIndex = RegInit(0.U(6.W))
  val bytePointer = RegInit(0.U(11.W))
  val output = Module(new BankedShallowQueue(chiselTypeOf(io.replay.bits), 2,
    pipe = false, flow = false))
  io.replay.valid := output.io.deq.valid && !faultNow
  io.replay.bits := output.io.deq.bits
  output.io.deq.ready := io.replay.ready && !faultNow
  when(io.replay.fire) { replayed(head) := replayed(head) + 1.U }
  val pending = RegInit(false.B)
  val saved = Reg(chiselTypeOf(io.replay.bits))
  val savedOffset = Reg(UInt(5.W))
  val current = descriptor(head)
  val readWord = bytePointer(9, 5)
  // Only the low 32 mask bits are observable. Saturate before shifting so
  // the 16-bit descriptor cannot infer a 65,568-bit intermediate barrel.
  val maskCols = Mux(current.cols > 32.U, 32.U(6.W), current.cols(5, 0))
  val need = (((1.U(33.W) << maskCols) - 1.U)(31, 0).pad(64) << bytePointer(4, 0))(63, 0)
  val have = Cat(Mux(readWord === 31.U, 0.U(32.W), validBytes(head)(readWord + 1.U)),
    validBytes(head)(readWord))
  val rowReady = current.all_zeros || (have & need) === need
  val canRead = state(head) === emit && rowReady && !faultNow &&
    (output.io.count +& pending.asUInt < 2.U || output.io.deq.fire)
  val readData = Cat(memory.zipWithIndex.map { case (bank, b) =>
    val word = bytePointer(9, 5) + (b.U < bytePointer(4, 0))
    val byteSelected = (b.U(5.W) - bytePointer(4, 0))(4, 0) < current.cols
    val enabled = canRead && !current.all_zeros && byteSelected
    val writing = acceptData && (b.U(5.W) - f.offset(4, 0))(4, 0) < f.bytes
    val writeWord = (f.offset +& (b.U(5.W) - f.offset(4, 0))(4, 0))(9, 5)
    assert(!(enabled && writing && head === f.group_id && word(4, 0) === writeWord),
      "undefined SyncReadMem read/write collision")
    bank.read(Cat(head, word(4, 0)), enabled)
  }.reverse)
  val rotated = (Cat(readData, readData) >> (savedOffset << 3))(255, 0)
  val logicalMask = ((1.U(33.W) << maskCols) - 1.U)(31, 0)
  pending := canRead
  when(canRead) {
    saved := 0.U.asTypeOf(saved)
    saved.addr := (current.laddr + rowIndex).full_sp_addr()
    saved.mask := logicalMask.pad(128).asTypeOf(saved.mask)
    saved.scale := current.scale; saved.pixel_repeats := current.pixel_repeats
    saved.len := current.cols; saved.last := true.B; saved.bytes_read := current.cols
    saved.cmd_id := current.cmd_id
    saved.grouped := true.B; saved.assembled := modes(head) === 2.U || modes(head) === 3.U
    saved.group_id := head; saved.group_first := rowIndex === 0.U
    saved.group_last := rowIndex === current.cmd_rows - 1.U
    saved.group_zeros := current.all_zeros; saved.group_bytes := total(head)
    savedOffset := bytePointer(4, 0)
    bytePointer := bytePointer + current.cols
    rowIndex := rowIndex + 1.U
    when(rowIndex === current.cmd_rows - 1.U) { state(head) := retire }
  }
  output.io.enq.valid := pending
  output.io.enq.bits := saved
  val byteMask = FillInterleaved(8, saved.mask.asUInt(31, 0))
  output.io.enq.bits.data := Mux(saved.group_zeros, 0.U, rotated & byteMask)
  assert(!pending || output.io.enq.ready)

  for(g <- 0 until 2) {
    io.terminalReady(g) := !faultNow && state(g) === retire &&
      (descriptor(g).all_zeros || (issued(g) === total(g) && received(g) === total(g) && inflight(g) === 0.U)) &&
      replayed(g) === descriptor(g).cmd_rows && !pending && !output.io.deq.valid &&
      !(held && heldSelection === g.U)
  }
  when(io.completed.valid) {
    val g = io.completed.bits.group_id
    val next = credited(g) +& io.completed.bits.bytes
    assert(g === head && state(g) =/= free && next <= total(g))
    credited(g) := next
    when(next === total(g)) {
      assert(io.terminalReady(g), "terminal credit before group drain")
      state(g) := free
      head := ~head; rowIndex := 0.U; bytePointer := 0.U
    }
  }
  io.occupancy := PopCount(state.map(_ =/= free))
  io.busy := state.map(_ =/= free).reduce(_ || _) || pending || output.io.deq.valid || fault
  io.fault := faultNow
  CounterEventIO.init(io.counter)
  DmaLoadCount(io.counter, CounterExternal.LOAD_COLLECT_CYCLES, collecting.asUInt)
  DmaLoadCount(io.counter, CounterExternal.LOAD_FETCH_WAIT_CYCLES,
    VecInit((0 until 2).map(g => state(g) =/= free && state(g) =/= collect &&
      !descriptor(g).all_zeros && (received(g) < total(g) || inflight(g) =/= 0.U))).asUInt.orR.asUInt)
  DmaLoadCount(io.counter, CounterExternal.LOAD_GROUP_OCCUPANCY_PEAK, io.occupancy, peak = true)
}
