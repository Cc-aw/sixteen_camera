package gemmini

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

/** Sliding destination window. Each accepted scaled sample advances once;
  * no loop serializes its P individual byte-mask updates. The final sample
  * owns the P-1 tail steps, even if no subsequent command ever arrives. */
class DmaLoadRowAssembler[T <: Data](t: T, local: LocalAddr, columns: Int,
                                    scaleBits: Int)(implicit p: Parameters) extends Module {
  require(t.getWidth == 8 && columns == 32)
  val tag = new StreamReadResponse(256, 1024, local.spRows, local.accRows, 1, scaleBits)
  val io = IO(new Bundle {
    val in = Flipped(Decoupled(new PixelRepeaterReq(t, local, columns, 1, tag)))
    val out = Decoupled(new PixelRepeaterResp(t, local, columns, 1, tag))
    val busy = Output(Bool())
    val tailStep = Output(Bool())
  })
  val window = Reg(UInt(256.W))
  val mask = Reg(UInt(32.W))
  val tail = RegInit(0.U(8.W))
  val cols = Reg(UInt(6.W))
  val nextAddress = Reg(SInt((log2Ceil(local.spRows) + 2).W))
  val floor = Reg(UInt((log2Ceil(local.spRows) + 1).W))
  val savedTag = Reg(tag.cloneType)
  val output = Module(new BankedShallowQueue(chiselTypeOf(io.out.bits), 2,
    pipe = false, flow = false))
  io.out <> output.io.deq
  val in = io.in.bits
  val first = in.tag.group_first
  val c = Mux(tail =/= 0.U, cols, in.len)
  val sampleMask = ((1.U(33.W) << in.len) - 1.U)(31, 0)
  val inputMask = in.mask.asUInt & sampleMask
  val cleanInput = in.in.asUInt & FillInterleaved(8, inputMask)
  val highShift = (in.pixel_repeats - 1.U) * in.len
  val oldWindow = Mux(first && tail === 0.U, 0.U, window)
  val oldMask = Mux(first && tail === 0.U, 0.U, mask)
  val newWindow = (oldWindow >> (c << 3)) |
    Mux(tail =/= 0.U, 0.U, (cleanInput << (highShift << 3))(255, 0))
  val newMask = (oldMask >> c) |
    Mux(tail =/= 0.U, 0.U, (inputMask << highShift)(31, 0))
  val addrBits = log2Ceil(local.spRows) + 1
  val sourceAddress = in.laddr.full_sp_addr().pad(addrBits)
  val lower = Mux(sourceAddress < (local.spRows / 2).U, 0.U, (local.spRows / 2).U)
  val underflow = sourceAddress < lower + (in.pixel_repeats - 1.U)
  val target = Mux(tail =/= 0.U, nextAddress, sourceAddress.zext - (in.pixel_repeats - 1.U).zext)
  val discard = Mux(tail =/= 0.U, target < floor.zext, underflow) || !newMask.orR
  val stepReady = output.io.enq.ready || discard
  io.in.ready := tail === 0.U && stepReady
  val advance = Mux(tail =/= 0.U, stepReady, io.in.fire)
  output.io.enq.valid := Mux(tail =/= 0.U, true.B, io.in.valid) && !discard
  output.io.enq.bits.out := newWindow.asTypeOf(output.io.enq.bits.out)
  output.io.enq.bits.mask := newMask.asTypeOf(output.io.enq.bits.mask)
  output.io.enq.bits.laddr := target.asUInt.asTypeOf(local)
  output.io.enq.bits.tag := Mux(tail =/= 0.U, savedTag, in.tag)
  output.io.enq.bits.last := Mux(tail =/= 0.U, tail === 1.U,
    in.tag.group_last && in.pixel_repeats === 1.U)
  when(advance) { window := newWindow; mask := newMask }
  when(io.in.fire) {
    assert(in.pixel_repeats =/= 0.U && in.pixel_repeats * in.len <= columns.U)
    cols := in.len
    floor := lower
    nextAddress := target + 1.S
    when(in.tag.group_last) {
      tail := in.pixel_repeats - 1.U
      savedTag := in.tag
    }
  }
  when(tail =/= 0.U && stepReady) { tail := tail - 1.U; nextAddress := nextAddress + 1.S }
  io.tailStep := tail =/= 0.U && stepReady
  io.busy := tail =/= 0.U || output.io.deq.valid
}
