package gemmini

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

/** Preserve the original read_assembled eligibility, including full-width
  * overflow checks. The span can be registered independently of its consumer.
  */
object DmaLoadEligibility {
  def apply[T <: Data, U <: Data, V <: Data](config: GemminiArrayConfig[T, U, V],
      first: ScratchpadMemReadRequest[_ <: Data], span: UInt)(implicit p: Parameters): Bool = {
    val local = config.local_addr_t
    val endAddress = first.vaddr +& span +& first.cols
    val endLocal = first.laddr.full_sp_addr() +& first.cmd_rows - 1.U
    val half = local.spRows / 2
    val sameHalf = endLocal < local.spRows.U &&
      ((first.laddr.full_sp_addr() < half.U) === (endLocal < half.U))
    val allowLocal = p(freechips.rocketchip.tile.commandfrontend.ActivationSramKey)
    val normalMemory = (first.vaddr >= "h80000000".U && endAddress <= "h100000000".U) ||
      (allowLocal.B && ActivationSramDmaAddress.localRange(first.vaddr, endAddress))
    val readMerge = first.cmd_stride_bytes === first.cols && first.cmd_rows > 1.U
    !first.dual && !first.lane_high && !first.laddr.is_acc_addr && !first.laddr.accumulate &&
      !first.has_acc_bitwidth && first.repeats === 0.U && first.cols =/= 0.U && first.cols < 32.U &&
      first.cmd_rows =/= 0.U && first.cmd_rows <= 32.U && first.pixel_repeats =/= 0.U &&
      first.pixel_repeats <= config.dma_load_max_pixel_repeats.U &&
      first.pixel_repeats * first.cols <= 32.U &&
      sameHalf && (first.all_zeros || (normalMemory && (readMerge || first.pixel_repeats > 1.U)))
  }
}

/** Two elastic stages before the optimized/legacy split.
  *
  * Stage 1 registers the request and (rows-1)*stride. Stage 2 registers the
  * address checks and route decision together with that SAME request. Both
  * queues have two entries, no flow-through and occupancy-only input ready;
  * the multiplier/comparators cannot propagate into downstream CE/reset or
  * back into the LoadController's ready chain. Sustained rate is one row per
  * clock. Payload is not reset; occupancy is reset. Fault stops external
  * acceptance and dispatch; reset discards all buffered requests.
  */
class DmaLoadIngress[T <: Data, U <: Data, V <: Data](config: GemminiArrayConfig[T, U, V])
    (implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    val in = Flipped(Decoupled(new ScratchpadMemReadRequest(config.local_addr_t, config.mvin_scale_t_bits)))
    val out = Decoupled(new Bundle {
      val request = new ScratchpadMemReadRequest(config.local_addr_t, config.mvin_scale_t_bits)
      val eligible = Bool()
    })
    val fault = Input(Bool())
    val busy = Output(Bool())
  })
  VivadoAttributes(this.toTarget, "keep_hierarchy = \"yes\"")
  val prepared = Module(new BankedShallowQueue(new Bundle {
    val request = chiselTypeOf(io.in.bits)
    val span = UInt((io.in.bits.cmd_rows.getWidth + io.in.bits.cmd_stride_bytes.getWidth).W)
  }, 2, pipe=false, flow=false, bankBits=32, registerPayload=true))
  val classified = Module(new BankedShallowQueue(chiselTypeOf(io.out.bits), 2,
    pipe=false, flow=false, bankBits=32, registerPayload=true))

  prepared.io.enq.valid := io.in.valid && !io.fault
  prepared.io.enq.bits.request := io.in.bits
  prepared.io.enq.bits.span := (io.in.bits.cmd_rows - 1.U) * io.in.bits.cmd_stride_bytes
  io.in.ready := prepared.io.enq.ready && !io.fault

  classified.io.enq.valid := prepared.io.deq.valid
  classified.io.enq.bits.request := prepared.io.deq.bits.request
  classified.io.enq.bits.eligible := DmaLoadEligibility(config,
    prepared.io.deq.bits.request, prepared.io.deq.bits.span)
  prepared.io.deq.ready := classified.io.enq.ready

  io.out.valid := classified.io.deq.valid && !io.fault
  io.out.bits := classified.io.deq.bits
  classified.io.deq.ready := io.out.ready && !io.fault
  io.busy := prepared.io.deq.valid || classified.io.deq.valid
}

/** Register metadata after the Group/legacy mux without expanding the wide
  * response payload into FFs. Both stores share handshakes and capacity;
  * only the 1024-bit payload uses LUTRAM. Control has a fixed FF queue head.
  */
class DmaLoadReplayBuffer[U <: Data](gen: StreamReadResponse[U]) extends Module {
  val io = IO(new Bundle {
    val enq = Flipped(Decoupled(gen.cloneType))
    val deq = Decoupled(gen.cloneType)
    val busy = Output(Bool())
  })
  val metadata = Module(new BankedShallowQueue(gen.cloneType, 2,
    pipe=false, flow=false, bankBits=32, registerPayload=true))
  val payload = Module(new BankedShallowQueue(UInt(gen.data.getWidth.W), 2,
    pipe=false, flow=false, bankBits=64, registerPayload=false))
  metadata.io.enq.valid := io.enq.valid
  metadata.io.enq.bits := io.enq.bits
  metadata.io.enq.bits.data := 0.U
  payload.io.enq.valid := io.enq.valid
  payload.io.enq.bits := io.enq.bits.data
  io.enq.ready := metadata.io.enq.ready
  metadata.io.deq.ready := io.deq.ready
  payload.io.deq.ready := io.deq.ready
  io.deq.valid := metadata.io.deq.valid
  io.deq.bits := metadata.io.deq.bits
  io.deq.bits.data := payload.io.deq.bits
  io.busy := metadata.io.deq.valid
  assert(metadata.io.count === payload.io.count)
}
