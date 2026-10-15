
package gemmini

import chisel3._
import chisel3.util._
import chisel3.experimental._
import freechips.rocketchip.tile.RoCCCommand
import org.chipsalliance.cde.config.Parameters
import GemminiISA._
import LocalAddr._
import Util._

class LoopConvOuterBounds(val large_iterator_bitwidth: Int, val small_iterator_bitwidth: Int, val tiny_iterator_bitwidth: Int) extends Bundle {
  val batch_size = UInt(large_iterator_bitwidth.W)
  val in_row_dim = UInt(small_iterator_bitwidth.W)
  val in_col_dim = UInt(small_iterator_bitwidth.W)
  val in_channels = UInt(large_iterator_bitwidth.W)
  val out_channels = UInt(large_iterator_bitwidth.W)
  val out_col_dim = UInt(large_iterator_bitwidth.W)
  val out_row_dim = UInt(large_iterator_bitwidth.W)
  val out_stride = UInt(large_iterator_bitwidth.W) //stride for output activation
  val in_stride = UInt(large_iterator_bitwidth.W) //stride for input activation
  val weight_stride = UInt(large_iterator_bitwidth.W) //stride for weight
  val pool_out_row_dim = UInt(small_iterator_bitwidth.W)
  val pool_out_col_dim = UInt(small_iterator_bitwidth.W)
  val stride = UInt(tiny_iterator_bitwidth.W)
  val padding = UInt(tiny_iterator_bitwidth.W)
  val kernel_dim = UInt(tiny_iterator_bitwidth.W)
  val kernel_dilation = UInt(tiny_iterator_bitwidth.W)
  val pool_size = UInt(tiny_iterator_bitwidth.W)
  val pool_stride = UInt(tiny_iterator_bitwidth.W)
  val pool_padding = UInt(tiny_iterator_bitwidth.W)
}

class LoopConvInnerBounds(val large_iterator_bitwidth: Int, val small_iterator_bitwidth: Int, val tiny_iterator_bitwidth: Int) extends Bundle {
  val batches = UInt(large_iterator_bitwidth.W)
  val porows = UInt(small_iterator_bitwidth.W)
  val pocols = UInt(small_iterator_bitwidth.W)
  val pochs = UInt(large_iterator_bitwidth.W)
  val krows = UInt(tiny_iterator_bitwidth.W)
  val kcols = UInt(tiny_iterator_bitwidth.W)
  val kchs = UInt(large_iterator_bitwidth.W)
  val lpad = UInt(tiny_iterator_bitwidth.W)
  val rpad = UInt(tiny_iterator_bitwidth.W)
  val upad = UInt(tiny_iterator_bitwidth.W)
  val dpad = UInt(tiny_iterator_bitwidth.W)
  val plpad = UInt(tiny_iterator_bitwidth.W)
  val prad = UInt(tiny_iterator_bitwidth.W)
  val pupad = UInt(tiny_iterator_bitwidth.W)
  val pdpad = UInt(tiny_iterator_bitwidth.W)
  val orows = UInt(small_iterator_bitwidth.W)
  val ocols = UInt(small_iterator_bitwidth.W)
}

class LoopConvDerivedParams(val large_iterator_bitwidth: Int, val small_iterator_bitwidth: Int, val tiny_iterator_bitwidth: Int) extends Bundle {
  val ochs = UInt(large_iterator_bitwidth.W)

  val irows = UInt(small_iterator_bitwidth.W)
  val icols = UInt(small_iterator_bitwidth.W)
  val irows_unpadded = UInt(small_iterator_bitwidth.W)
  val icols_unpadded = UInt(small_iterator_bitwidth.W)
  val ichs = UInt(large_iterator_bitwidth.W)

  val out_channels_per_bank = UInt(small_iterator_bitwidth.W) // TODO this won't work for systolic arrays above 256 in size
  val in_channels_per_bank = UInt(small_iterator_bitwidth.W) // TODO this won't work for systolic arrays above 256 in size

  val bias_spad_stride = UInt(large_iterator_bitwidth.W)
  val input_spad_stride = UInt(large_iterator_bitwidth.W)
  val weight_spad_stride = UInt(large_iterator_bitwidth.W)

  // Cached two-dimensional strides. Keeping these products at loop setup
  // time prevents every LD/EX/ST command from rebuilding three-DSP chains.
  val input_row_stride = UInt(large_iterator_bitwidth.W)
  val input_plane_stride = UInt(large_iterator_bitwidth.W)
  val output_row_stride = UInt(large_iterator_bitwidth.W)
  val output_plane_stride = UInt(large_iterator_bitwidth.W)
  val weight_row_stride = UInt(large_iterator_bitwidth.W)

  // val ex_overwrite = Bool()
}

class LoopConvDerivedParamsPipeIn(val large_iterator_bitwidth: Int, val small_iterator_bitwidth: Int,
                                  val tiny_iterator_bitwidth: Int, val concurrent_loops: Int) extends Bundle {
  val outer_bounds = new LoopConvOuterBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val inner_bounds = new LoopConvInnerBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val input_dilated = Bool()
  val downsample = Bool()
  val trans_input_3120 = Bool()
  val trans_weight_0132 = Bool()
  val loop_id = UInt(log2Up(concurrent_loops).W)
}

class LoopConvDerivedParamsPipeOut(val large_iterator_bitwidth: Int, val small_iterator_bitwidth: Int,
                                   val tiny_iterator_bitwidth: Int, val concurrent_loops: Int) extends Bundle {
  val params = new LoopConvDerivedParams(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val loop_id = UInt(log2Up(concurrent_loops).W)
}

/**
  * Computes the immutable parameters of one configured convolution over
  * three registered stages. The former combinational method chained geometry
  * calculation, two-dimensional products and channel/batch products between
  * loop-state selection and every LD/EX/ST request (three DSP levels at
  * 300 MHz). This module performs the same unsigned-width operations once per
  * configuration and stores the result in the selected loop slot.
  */
class LoopConvDerivedParamsPipe(block_size: Int, large_iterator_bitwidth: Int,
                                small_iterator_bitwidth: Int, tiny_iterator_bitwidth: Int,
                                concurrent_loops: Int) extends Module {
  val io = IO(new Bundle {
    val in = Input(Valid(new LoopConvDerivedParamsPipeIn(
      large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, concurrent_loops)))
    val out = Output(Valid(new LoopConvDerivedParamsPipeOut(
      large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, concurrent_loops)))
  })

  val in = io.in.bits
  val stride = in.outer_bounds.stride
  val dilation = in.outer_bounds.kernel_dilation
  val krows = in.inner_bounds.krows
  val kcols = in.inner_bounds.kcols
  val orows = in.inner_bounds.orows
  val ocols = in.inner_bounds.ocols
  val upad = in.inner_bounds.upad
  val dpad = in.inner_bounds.dpad
  val lpad = in.inner_bounds.lpad
  val rpad = in.inner_bounds.rpad

  val dilatedKRows = krows + (dilation - 1.U) * (krows - 1.U)
  val dilatedKCols = kcols + (dilation - 1.U) * (kcols - 1.U)
  val irowsWithoutDilation = orows * stride +& dilatedKRows -& 1.U
  val icolsWithoutDilation = ocols * stride +& dilatedKCols -& 1.U
  val irowsUnpaddedWithoutDilation = irowsWithoutDilation -& upad -& dpad
  val icolsUnpaddedWithoutDilation = icolsWithoutDilation -& lpad -& rpad
  def undilated(x: UInt): UInt = (x +& in.input_dilated) >> in.input_dilated
  val irowsUnpadded = undilated(irowsUnpaddedWithoutDilation)
  val icolsUnpadded = undilated(icolsUnpaddedWithoutDilation)
  val irows = Mux(in.input_dilated,
    irowsUnpadded +& undilated(upad) +& undilated(dpad), irowsWithoutDilation)
  val icols = Mux(in.input_dilated,
    icolsUnpadded +& undilated(lpad) +& undilated(rpad), icolsWithoutDilation)

  val s1Valid = RegNext(io.in.valid, false.B)
  val s1LoopId = RegEnable(in.loop_id, io.in.valid)
  val s1Irows = RegEnable(irows, io.in.valid)
  val s1Icols = RegEnable(icols, io.in.valid)
  val s1IrowsUnpadded = RegEnable(irowsUnpadded, io.in.valid)
  val s1IcolsUnpadded = RegEnable(icolsUnpadded, io.in.valid)
  val s1Ochs = RegEnable(in.inner_bounds.pochs, io.in.valid)
  val s1Ichs = RegEnable(in.inner_bounds.kchs, io.in.valid)
  val s1Batches = RegEnable(in.inner_bounds.batches, io.in.valid)
  val s1Orows = RegEnable(orows, io.in.valid)
  val s1Ocols = RegEnable(ocols, io.in.valid)
  val s1Krows = RegEnable(krows, io.in.valid)
  val s1Kcols = RegEnable(kcols, io.in.valid)
  val s1Pochs = RegEnable(in.inner_bounds.pochs, io.in.valid)
  val s1Kchs = RegEnable(in.inner_bounds.kchs, io.in.valid)
  val s1Downsample = RegEnable(in.downsample, io.in.valid)
  val s1TransInput = RegEnable(in.trans_input_3120, io.in.valid)
  val s1TransWeight = RegEnable(in.trans_weight_0132, io.in.valid)

  // Stage two contains only parallel two-dimensional products.
  val s2Valid = RegNext(s1Valid, false.B)
  val s2LoopId = RegEnable(s1LoopId, s1Valid)
  val s2Irows = RegEnable(s1Irows, s1Valid)
  val s2Icols = RegEnable(s1Icols, s1Valid)
  val s2IrowsUnpadded = RegEnable(s1IrowsUnpadded, s1Valid)
  val s2IcolsUnpadded = RegEnable(s1IcolsUnpadded, s1Valid)
  val s2Ochs = RegEnable(s1Ochs, s1Valid)
  val s2Ichs = RegEnable(s1Ichs, s1Valid)
  val s2Batches = RegEnable(s1Batches, s1Valid)
  val s2TransInput = RegEnable(s1TransInput, s1Valid)
  val s2TransWeight = RegEnable(s1TransWeight, s1Valid)
  val s2InputRowStride = RegEnable(s1Icols >> s1Downsample, s1Valid)
  val s2InputArea = RegEnable((s1Irows >> s1Downsample) * (s1Icols >> s1Downsample), s1Valid)
  val s2BiasArea = RegEnable(s1Orows * s1Ocols, s1Valid)
  val s2OutputRowStride = RegEnable(s1Ocols, s1Valid)
  val s2WeightRowStride = RegEnable(
    s1Kcols * Mux(s1TransWeight, s1Pochs, s1Kchs), s1Valid)
  val s2Krows = RegEnable(s1Krows, s1Valid)
  val s2Pochs = RegEnable(s1Pochs, s1Valid)
  val s2Kchs = RegEnable(s1Kchs, s1Valid)

  val finalParams = Wire(new LoopConvDerivedParams(
    large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth))
  finalParams.ochs := s2Ochs
  finalParams.irows := s2Irows
  finalParams.icols := s2Icols
  finalParams.irows_unpadded := s2IrowsUnpadded
  finalParams.icols_unpadded := s2IcolsUnpadded
  finalParams.ichs := s2Ichs
  finalParams.out_channels_per_bank :=
    (s2Ochs >> log2Up(block_size)) +& (s2Ochs(log2Up(block_size)-1, 0).orR)
  finalParams.in_channels_per_bank :=
    (s2Ichs >> log2Up(block_size)) +& (s2Ichs(log2Up(block_size)-1, 0).orR)
  finalParams.input_row_stride := s2InputRowStride
  finalParams.input_plane_stride := s2InputArea
  finalParams.output_row_stride := s2OutputRowStride
  finalParams.output_plane_stride := s2BiasArea
  finalParams.weight_row_stride := s2WeightRowStride
  finalParams.bias_spad_stride := s2Batches * s2BiasArea
  finalParams.input_spad_stride := Mux(s2TransInput,
    s2Ichs * s2InputArea, s2Batches * s2InputArea)
  finalParams.weight_spad_stride := s2Krows * s2WeightRowStride

  io.out.valid := RegNext(s2Valid, false.B)
  io.out.bits.loop_id := RegEnable(s2LoopId, s2Valid)
  io.out.bits.params := RegEnable(finalParams, s2Valid)
}

class LoopConvLdBiasReq(val coreMaxAddrBits: Int, val large_iterator_bitwidth: Int, val small_iterator_bitwidth: Int, val tiny_iterator_bitwidth: Int, val max_acc_addr: Int, val concurrent_loops: Int)  extends Bundle {
  val outer_bounds = new LoopConvOuterBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val inner_bounds = new LoopConvInnerBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val derived_params = new LoopConvDerivedParams(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val addr_start = UInt(log2Up(max_acc_addr).W)
  val dram_addr = UInt(coreMaxAddrBits.W)
  val no_bias = Bool()
  val loop_id = UInt(log2Up(concurrent_loops).W)
}

class LoopConvLdBias(block_size: Int, coreMaxAddrBits: Int, large_iterator_bitwidth: Int, small_iterator_bitwidth: Int, tiny_iterator_bitwidth: Int, max_acc_addr: Int, acc_w: Int,
                     max_block_len_acc: Int, concurrent_loops: Int, latency: Int,
                     config_mvin_rs1_t: ConfigMvinRs1, mvin_rs2_t: MvinRs2)(implicit p: Parameters) extends Module {
  val MVIN_SCALE_IDENTITY = (if (config_mvin_rs1_t.scale.getWidth == 16) 0x3c00.U else 0x3f800000.U)
  val io = IO(new Bundle {
    val req = Flipped(Decoupled(new LoopConvLdBiasReq(coreMaxAddrBits, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth: Int, max_acc_addr, concurrent_loops)))
    val cmd = Decoupled(Output(new RoCCCommand))

    val idle = Output(Bool())
    val rob_overloaded = Input(Bool())
    val wait_for_prev_loop = Input(Bool())

    val loop_id = Output(UInt(log2Up(concurrent_loops).W))
    val deadlock_debug = Output(UInt(64.W))
  })

  object State extends ChiselEnum {
    val idle, config, ld = Value
  }
  import State._
  val state = RegInit(idle)

  val req = Reg(new LoopConvLdBiasReq(coreMaxAddrBits, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth: Int, max_acc_addr, concurrent_loops))
  import req.inner_bounds._
  import req.derived_params._

  val acc_addr_start = req.addr_start

  // Derived parameters
  val max_ochs_per_mvin = Mux(ochs < (max_block_len_acc * block_size).U, ochs, (max_block_len_acc * block_size).U)

  val skip = req.dram_addr === 0.U

  // Iterators
  val b = Reg(UInt(large_iterator_bitwidth.W))
  val orow = Reg(UInt(small_iterator_bitwidth.W))
  val ocol = Reg(UInt(small_iterator_bitwidth.W))
  val och = Reg(UInt(large_iterator_bitwidth.W))

  // Addresses
  val dram_offset = och * (acc_w/8).U
  val dram_addr = Mux(req.no_bias, 0.U, req.dram_addr + LoopConv.castDramOffset(dram_offset))

  // Sizes
  val I = Mux(ocols - ocol > block_size.U, block_size.U, ocols - ocol)
  val J = Mux(ochs - och > max_ochs_per_mvin, max_ochs_per_mvin, ochs - och)

  class RoCCCommandWithAddr extends Bundle {
    val cmd = new RoCCCommand
    val dram_addr = UInt()
    val spad_addr = UInt()
    val I = UInt()
    val J = UInt()
  }
  val command_p = Module(new Pipeline[RoCCCommandWithAddr](new RoCCCommandWithAddr, latency)())
  class BiasAddressStage extends Bundle {
    val is_config = Bool()
    val dram_addr = UInt()
    val I = UInt()
    val J = UInt()
    val bank = UInt(32.W)
    val plane = UInt(32.W)
    val row = UInt(32.W)
    val col = UInt(32.W)
  }
  val spatial_p = Module(new Pipeline(new BiasAddressStage, 1)())
  val linear_p = Module(new Pipeline(new BiasAddressStage, 1)())
  val address_p = Module(new Pipeline(new BiasAddressStage, 1)())
  val first = spatial_p.io.in.bits
  first.is_config := state === config
  first.dram_addr := dram_addr
  first.I := I
  first.J := J
  first.bank := (och >> log2Up(block_size)) * batches
  first.plane := b * orows
  first.row := orow * ocols
  first.col := ocol
  linear_p.io.in <> spatial_p.io.out
  linear_p.io.in.bits.bank := spatial_p.io.out.bits.bank * orows
  linear_p.io.in.bits.plane := spatial_p.io.out.bits.plane * ocols
  address_p.io.in <> linear_p.io.out
  address_p.io.in.bits.bank := linear_p.io.out.bits.bank * ocols
  val addresses = address_p.io.out.bits

  // Commands
  val config_cmd = Wire(new RoCCCommand)
  config_cmd := DontCare
  config_cmd.inst.funct := CONFIG_CMD

  val config_cmd_rs1 = Wire(config_mvin_rs1_t.cloneType)
  config_cmd_rs1 := DontCare
  config_cmd_rs1.scale := MVIN_SCALE_IDENTITY
  config_cmd_rs1.stride := req.derived_params.bias_spad_stride
  config_cmd_rs1.pixel_repeats := 1.U
  config_cmd_rs1.state_id := 2.U
  config_cmd_rs1.shrink := 0.U
  config_cmd_rs1._unused := 1.U
  config_cmd.rs1 := config_cmd_rs1.asUInt

  config_cmd.rs2 := 0.U

  val mvin_cmd = Wire(new RoCCCommand)
  mvin_cmd := DontCare
  mvin_cmd.inst.funct := LOAD3_CMD
  mvin_cmd.rs1 := 0.U
  mvin_cmd.rs2 := 0.U

  // Inputs and outputs
  io.req.ready := state === idle && !spatial_p.io.busy && !linear_p.io.busy &&
    !address_p.io.busy && !command_p.io.busy
  io.idle := state === idle && !spatial_p.io.busy && !linear_p.io.busy &&
    !address_p.io.busy && !command_p.io.busy
  io.loop_id := req.loop_id

  spatial_p.io.in.valid := state =/= idle && !io.wait_for_prev_loop && !skip
  address_p.io.out.ready := command_p.io.in.ready
  command_p.io.in.valid := address_p.io.out.valid
  command_p.io.in.bits.cmd := Mux(addresses.is_config, config_cmd, mvin_cmd)
  command_p.io.in.bits.dram_addr := addresses.dram_addr
  command_p.io.in.bits.spad_addr := (addresses.bank + addresses.plane) + (addresses.row + addresses.col) + acc_addr_start
  command_p.io.in.bits.I := addresses.I
  command_p.io.in.bits.J := addresses.J

  command_p.io.out.ready := io.cmd.ready && !io.rob_overloaded
  io.cmd.valid := command_p.io.out.valid && !io.rob_overloaded
  io.cmd.bits := command_p.io.out.bits.cmd
  when (command_p.io.out.bits.cmd.inst.funct === LOAD3_CMD) {
    val o = command_p.io.out.bits
    io.cmd.bits.rs1 := o.dram_addr
    val mvin_cmd_rs2 = Wire(mvin_rs2_t.cloneType)
    mvin_cmd_rs2 := DontCare
    mvin_cmd_rs2.num_rows := o.I.asUInt
    mvin_cmd_rs2.num_cols := o.J.asUInt
    mvin_cmd_rs2.local_addr := cast_to_acc_addr(mvin_cmd_rs2.local_addr, o.spad_addr, accumulate = false.B, read_full = false.B)
    io.cmd.bits.rs2 := mvin_cmd_rs2.asUInt
  }

  // Sending outputs
  when (skip) {
    state := idle
  }.elsewhen(spatial_p.io.in.fire) {
    when (state === config) {
      state := ld
    }.otherwise {
      val next_och = floorAdd(och, max_ochs_per_mvin, ochs)
      val next_ocol = floorAdd(ocol, block_size.U, ocols, next_och === 0.U)
      val next_orow = floorAdd(orow, 1.U, orows, next_ocol === 0.U && next_och === 0.U)
      val next_b = floorAdd(b, 1.U, batches, next_orow === 0.U && next_ocol === 0.U && next_och === 0.U)

      och := next_och
      ocol := next_ocol
      orow := next_orow
      b := next_b

      state := Mux(next_b === 0.U && next_orow === 0.U && next_ocol === 0.U && next_och === 0.U,
        idle, ld)
    }
  }

  // Accepting requests
  when (io.req.fire) {
    req := io.req.bits
    state := config
    b := 0.U
    orow := 0.U
    ocol := 0.U
    och := 0.U
  }

  /** IPOAT：Bias 子生成器阻塞快照
    * I（Input 输入）：状态、loop、等待/过载、pipeline 与当前迭代坐标。
    * P（Process 处理）：只读压缩为 64-bit，不参与任何握手。
    * O（Output 输出）：可区分依赖等待、RS 满和 pipeline 出口反压。
    * A（Author 作者）：王志瑞
    * T（Time 时间）：2026-09-19
    */
  io.deadlock_debug := Cat(0.U(24.W), b(7, 0), orow(7, 0), ocol(7, 0), och(7, 0),
    state.asUInt.pad(2), io.loop_id, io.wait_for_prev_loop, io.rob_overloaded,
    command_p.io.busy, io.cmd.valid, io.cmd.ready)
}

class LoopConvLdInputReq(val coreMaxAddrBits: Int, val large_iterator_bitwidth: Int, val small_iterator_bitwidth: Int, val tiny_iterator_bitwidth: Int, val max_acc_addr: Int, val concurrent_loops: Int)  extends Bundle {
  val outer_bounds = new LoopConvOuterBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val inner_bounds = new LoopConvInnerBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val derived_params = new LoopConvDerivedParams(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val addr_start = UInt(log2Up(max_acc_addr).W)
  val dram_addr = UInt(coreMaxAddrBits.W)
  val downsample = Bool()
  val max_pixels_per_row = UInt(small_iterator_bitwidth.W)
  val input_dilated = Bool()
  val trans_input_3120 = Bool()
  val loop_id = UInt(log2Up(concurrent_loops).W)
}

class LoopConvLdInput(block_size: Int, coreMaxAddrBits: Int, large_iterator_bitwidth: Int, small_iterator_bitwidth: Int,
                      tiny_iterator_bitwidth: Int, max_addr: Int, input_w: Int, max_block_len: Int,
                      concurrent_loops: Int, latency: Int, config_mvin_rs1_t: ConfigMvinRs1, mvin_rs2_t: MvinRs2)
                     (implicit p: Parameters) extends Module {
  val MVIN_SCALE_IDENTITY = (if (config_mvin_rs1_t.scale.getWidth == 16) 0x3c00.U else 0x3f800000.U)

  val io = IO(new Bundle {
    val req = Flipped(Decoupled(new LoopConvLdInputReq(coreMaxAddrBits, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, max_addr, concurrent_loops)))
    val cmd = Decoupled(Output(new RoCCCommand))

    val idle = Output(Bool())
    val rob_overloaded = Input(Bool())
    val wait_for_prev_loop = Input(Bool())

    val loop_id = Output(UInt(log2Up(concurrent_loops).W))
    val deadlock_debug = Output(UInt(64.W))
  })

  object State extends ChiselEnum {
    val idle, config, ld = Value
  }
  import State._
  val state = RegInit(idle)

  val req = Reg(new LoopConvLdInputReq(coreMaxAddrBits, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, max_addr, concurrent_loops))
  import req.outer_bounds._
  import req.inner_bounds._
  import req.derived_params._

  def undilated(x: UInt): UInt = (x +& req.input_dilated) >> req.input_dilated

  // Derived parameters
  val max_ichs_per_mvin = Mux(ichs < (max_block_len * block_size).U, ichs, (max_block_len * block_size).U).zext
  val max_batches_per_mvin = Mux(batches < (max_block_len * block_size).U, batches, (max_block_len * block_size).U).zext
  val max_chs_per_mvin = Mux(req.trans_input_3120, max_batches_per_mvin, max_ichs_per_mvin)

  // Iterators
  val b = Reg(SInt(large_iterator_bitwidth.W))
  val irow = Reg(SInt(small_iterator_bitwidth.W))
  val icol = Reg(SInt(small_iterator_bitwidth.W))
  val ich = Reg(SInt(large_iterator_bitwidth.W))

  // Calculated params
  val irow_padded = irow +& undilated(upad).zext
  val icol_padded = icol +& undilated(lpad).zext
  val is_zeros = irow < 0.S || irow >= irows_unpadded.zext || icol < 0.S || icol >= icols_unpadded.zext

  val dram_stride = Mux(req.trans_input_3120, batch_size * (input_w/8).U, in_stride * (input_w/8).U)

  // Sizes
  val block_size_downsampled = (block_size.U << req.downsample).asUInt.zext

  val I = MuxCase(
    Mux(icols_unpadded.zext -& icol > block_size_downsampled, block_size_downsampled, icols_unpadded.zext -& icol),
    Seq(
      (icol < 0.S) -> Mux((0.S-&icol) > block_size.S, block_size.S, 0.S-&icol),
      (icol >= icols_unpadded.zext) -> Mux(icols_unpadded.zext +& undilated(rpad).zext -& icol > block_size.S, block_size.S, icols_unpadded.zext +& undilated(rpad).zext -& icol)
    )
  )
  val K = Mux(req.trans_input_3120,
    Mux(batches.zext -& b > max_chs_per_mvin, max_chs_per_mvin, batches.zext -& b),
    Mux(ichs.zext -& ich > max_chs_per_mvin, max_chs_per_mvin, ichs.zext -& ich))

  class RoCCCommandWithAddr extends Bundle {
    val cmd = new RoCCCommand
    val dram_addr = UInt()
    val spad_addr = SInt()
    val I = SInt()
    val K = SInt()
  }
  val command_p = Module(new Pipeline[RoCCCommandWithAddr](new RoCCCommandWithAddr, latency)())
  // The API deliberately wraps DRAM offsets to 32 bits. Do every partial
  // product in that same ring, then add the full request base at the end.
  // Keeping data, zero-padding, command kind and sizes in the same elastic
  // pipeline also preserves correctness when the ROB or command port stalls.
  class InputAddressStage extends Bundle {
    val is_config = Bool()
    val is_zeros = Bool()
    val I = SInt()
    val K = SInt()
    val dram_plane = UInt(32.W)
    val dram_row = UInt(32.W)
    val dram_col = UInt(32.W)
    val dram_inner = UInt(32.W)
    val spad_plane = UInt(32.W)
    val spad_bank = UInt(32.W)
    val spad_row = UInt(32.W)
    val spad_col = UInt(32.W)
  }
  val spatial_p = Module(new Pipeline(new InputAddressStage, 1)())
  val linear_p = Module(new Pipeline(new InputAddressStage, 1)())
  val offset_p = Module(new Pipeline(new InputAddressStage, 1)())
  val byte_p = Module(new Pipeline(new InputAddressStage, 1)())
  val first = spatial_p.io.in.bits
  first.is_config := state === config
  first.is_zeros := is_zeros
  first.I := I
  first.K := K
  first.dram_plane := (Mux(req.trans_input_3120, ich, b) * in_row_dim).pad(32).asUInt
  first.dram_row := (irow * in_col_dim).pad(32).asUInt
  first.dram_col := icol.pad(32).asUInt
  first.dram_inner := Mux(req.trans_input_3120, b, ich).pad(32).asUInt
  first.spad_plane := (Mux(req.trans_input_3120, ich, b) * (irows >> req.downsample)).pad(32).asUInt
  first.spad_bank := ((Mux(req.trans_input_3120, b, ich) >> log2Up(block_size)) * input_spad_stride).pad(32).asUInt
  first.spad_row := ((irow_padded >> req.downsample) * (icols >> req.downsample)).pad(32).asUInt
  first.spad_col := (icol_padded >> req.downsample).pad(32).asUInt

  linear_p.io.in <> spatial_p.io.out
  linear_p.io.in.bits.dram_plane := spatial_p.io.out.bits.dram_plane * in_col_dim
  linear_p.io.in.bits.spad_plane := spatial_p.io.out.bits.spad_plane * (icols >> req.downsample)

  offset_p.io.in <> linear_p.io.out
  val linear = linear_p.io.out.bits
  offset_p.io.in.bits.dram_plane := linear.dram_plane + linear.dram_row + linear.dram_col
  offset_p.io.in.bits.spad_plane :=
    (linear.spad_plane + linear.spad_bank) + (linear.spad_row + linear.spad_col) + req.addr_start

  byte_p.io.in <> offset_p.io.out
  val offset = offset_p.io.out.bits
  byte_p.io.in.bits.dram_plane :=
    (offset.dram_plane * Mux(req.trans_input_3120, batches, in_stride) + offset.dram_inner) * (input_w / 8).U
  val addresses = byte_p.io.out.bits
  // Commands
  val config_cmd = Wire(new RoCCCommand)
  config_cmd := DontCare
  config_cmd.inst.funct := CONFIG_CMD

  val config_cmd_rs1 = Wire(config_mvin_rs1_t.cloneType)
  config_cmd_rs1 := DontCare
  config_cmd_rs1.scale := MVIN_SCALE_IDENTITY
  config_cmd_rs1.stride := input_spad_stride
  config_cmd_rs1.pixel_repeats := req.max_pixels_per_row
  config_cmd_rs1.state_id := 0.U
  config_cmd_rs1.shrink := 0.U
  config_cmd_rs1._unused := 1.U
  config_cmd.rs1 := config_cmd_rs1.asUInt

  config_cmd.rs2 := dram_stride << req.downsample

  val mvin_cmd = Wire(new RoCCCommand)
  mvin_cmd := DontCare
  mvin_cmd.inst.funct := LOAD_CMD
  mvin_cmd.rs1 := 0.U // dram_addr
  mvin_cmd.rs2 := 0.U // mvin_cmd_rs2

  // Inputs and outputs
  io.req.ready := state === idle && !spatial_p.io.busy && !linear_p.io.busy &&
    !offset_p.io.busy && !byte_p.io.busy && !command_p.io.busy
  io.idle := state === idle && !spatial_p.io.busy && !linear_p.io.busy &&
    !offset_p.io.busy && !byte_p.io.busy && !command_p.io.busy
  io.loop_id := req.loop_id

  spatial_p.io.in.valid := state =/= idle && !io.wait_for_prev_loop && (req.dram_addr =/= 0.U)
  byte_p.io.out.ready := command_p.io.in.ready
  command_p.io.in.valid := byte_p.io.out.valid
  command_p.io.in.bits.cmd := Mux(addresses.is_config, config_cmd, mvin_cmd)
  command_p.io.in.bits.dram_addr := Mux(addresses.is_zeros, 0.U, req.dram_addr +& addresses.dram_plane)
  command_p.io.in.bits.spad_addr := addresses.spad_plane.asSInt
  command_p.io.in.bits.I := addresses.I
  command_p.io.in.bits.K := addresses.K

  command_p.io.out.ready := io.cmd.ready && !io.rob_overloaded
  io.cmd.valid := command_p.io.out.valid && !io.rob_overloaded
  io.cmd.bits := command_p.io.out.bits.cmd
  when (command_p.io.out.bits.cmd.inst.funct === LOAD_CMD) {
    val o = command_p.io.out.bits
    io.cmd.bits.rs1 := o.dram_addr
    val mvin_cmd_rs2 = Wire(mvin_rs2_t.cloneType)
    mvin_cmd_rs2 := DontCare
    mvin_cmd_rs2.num_rows := (o.I >> req.downsample).asUInt
    mvin_cmd_rs2.num_cols := o.K.asUInt
    mvin_cmd_rs2.local_addr := cast_to_sp_addr(mvin_cmd_rs2.local_addr, o.spad_addr)
    io.cmd.bits.rs2 := mvin_cmd_rs2.asUInt
  }

  // Sending outputs
  when(req.dram_addr === 0.U){
    state := idle
  }.elsewhen(spatial_p.io.in.fire) {
    when (state === config) {
      state := ld
    }.otherwise {
      val b_it = Mux(req.trans_input_3120, max_chs_per_mvin.asUInt, 1.U)
      val ich_it = Mux(req.trans_input_3120, 1.U, max_chs_per_mvin.asUInt)

      val next_ich = sFloorAdd(ich, ich_it, ichs.zext, 0.S)
      val next_icol = sFloorAdd(icol, I.asUInt, (icols_unpadded +& undilated(rpad)).zext, 0.S-&undilated(lpad).zext,
        next_ich === 0.S)
      val next_irow = sFloorAdd(irow, 1.U << req.downsample, (irows_unpadded +& undilated(dpad)).zext, 0.S-&undilated(upad).zext,
        next_icol === 0.S-&undilated(lpad).zext && next_ich === 0.S)
      val next_b = sFloorAdd(b, b_it, batches.zext, 0.S,
        next_irow === 0.S-&undilated(upad).zext && next_icol === 0.S-&undilated(lpad).zext && next_ich === 0.S)

      ich := next_ich
      icol := next_icol
      irow := next_irow
      b := next_b

      state := Mux(next_b === 0.S && next_irow === 0.S-&undilated(upad).zext && next_icol === 0.S-&undilated(lpad).zext && next_ich === 0.S,
        idle, ld)
    }
  }

  // Accepting requests
  when (io.req.fire) {
    req := io.req.bits
    state := config
    b := 0.S
    irow := 0.S -& ((io.req.bits.inner_bounds.upad +& io.req.bits.input_dilated) >> io.req.bits.input_dilated).zext
    icol := 0.S -& ((io.req.bits.inner_bounds.lpad +& io.req.bits.input_dilated) >> io.req.bits.input_dilated).zext
    ich := 0.S
  }

  /** IPOAT：Input 子生成器阻塞快照
    * I（Input 输入）：状态、依赖/RS 背压、pipeline 与 b/irow/icol/ich。
    * P（Process 处理）：保留各坐标低 8 位并组合控制状态，仅作观察。
    * O（Output 输出）：输入加载生成器停滞的精确位置和阻塞类别。
    * A（Author 作者）：王志瑞
    * T（Time 时间）：2026-09-19
    */
  io.deadlock_debug := Cat(0.U(24.W), b.asUInt.pad(8)(7, 0), irow.asUInt.pad(8)(7, 0),
    icol.asUInt.pad(8)(7, 0), ich.asUInt.pad(8)(7, 0), state.asUInt.pad(2), io.loop_id,
    io.wait_for_prev_loop, io.rob_overloaded, command_p.io.busy, io.cmd.valid, io.cmd.ready)
}

class LoopConvLdWeightReq(val coreMaxAddrBits: Int, val large_iterator_bitwidth: Int, val small_iterator_bitwidth: Int, val tiny_iterator_bitwidth: Int, val max_addr: Int, val concurrent_loops: Int)  extends Bundle {
  val outer_bounds = new LoopConvOuterBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val inner_bounds = new LoopConvInnerBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val derived_params = new LoopConvDerivedParams(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val addr_end = UInt(log2Up(max_addr+1).W)
  val dram_addr = UInt(coreMaxAddrBits.W)
  val trans_weight_1203 = Bool()
  val trans_weight_0132 = Bool()
  val dw = Bool()
  val loop_id = UInt(log2Up(concurrent_loops).W)
}

class LoopConvLdWeight(block_size: Int, coreMaxAddrBits: Int, large_iterator_bitwidth: Int,
                       small_iterator_bitwidth: Int, tiny_iterator_bitwidth: Int, max_addr: Int, input_w: Int,
                       max_block_len: Int, concurrent_loops: Int, latency: Int, config_mvin_rs1_t: ConfigMvinRs1,
                       mvin_rs2_t: MvinRs2, has_dw_convs: Boolean)(implicit p: Parameters) extends Module {
  val MVIN_SCALE_IDENTITY = (if (config_mvin_rs1_t.scale.getWidth == 16) 0x3c00.U else 0x3f800000.U)

  val io = IO(new Bundle {
    val req = Flipped(Decoupled(new LoopConvLdWeightReq(coreMaxAddrBits, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, max_addr, concurrent_loops)))
    val cmd = Decoupled(Output(new RoCCCommand))

    val idle = Output(Bool())
    val rob_overloaded = Input(Bool())
    val wait_for_prev_loop = Input(Bool())

    val loop_id = Output(UInt(log2Up(concurrent_loops).W))
    val deadlock_debug = Output(UInt(64.W))
    // （Author 作者：王志瑞）：导出权重 LOAD2 的区间计算量，仅用于片上被动记录。
  })

  object State extends ChiselEnum {
    val idle, config, ld = Value
  }
  import State._
  val state = RegInit(idle)

  val req = Reg(new LoopConvLdWeightReq(coreMaxAddrBits, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, max_addr, concurrent_loops))
  import req.outer_bounds._
  import req.inner_bounds._
  import req.derived_params._

  // Derived parameters
  val max_chs_per_mvin = {
    val max_ochs_per_mvin = Mux(ochs < (max_block_len * block_size).U, ochs, (max_block_len * block_size).U)
    val max_kchs_per_mvin = Mux(kchs < (max_block_len * block_size).U, kchs, (max_block_len * block_size).U)
    Mux(req.trans_weight_0132, max_kchs_per_mvin, max_ochs_per_mvin)
  }

  // Iterators
  val och = Reg(UInt(large_iterator_bitwidth.W))
  val krow = Reg(UInt(tiny_iterator_bitwidth.W))
  val kcol = Reg(UInt(tiny_iterator_bitwidth.W))
  val kch = Reg(UInt(large_iterator_bitwidth.W))

  // Sizes
  val J = Mux(req.trans_weight_0132,
    Mux(kchs - kch > max_chs_per_mvin, max_chs_per_mvin, kchs - kch),
    Mux(ochs - och > max_chs_per_mvin, max_chs_per_mvin, ochs - och))
  val K = Mux(req.trans_weight_0132,
    Mux(ochs - och > block_size.U, block_size.U, ochs - och),
    Mux(kchs - kch > block_size.U, block_size.U, kchs - kch))

  class RoCCCommandWithAddr extends Bundle {
    val cmd = new RoCCCommand
    val dram_addr = UInt()
    val spad_addr = UInt()
    val K = UInt()
    val J = UInt()
  }
  val command_p = Module(new Pipeline[RoCCCommandWithAddr](new RoCCCommandWithAddr, latency)())
  // All three weight layouts use a staged Horner calculation. Preserve
  // the original priority of 1203 over 0132 for DRAM, and the independent
  // 0132 selection for SPAD. The final DRAM offset remains modulo 2^32.
  class WeightAddressStage extends Bundle {
    val is_config = Bool()
    val J = UInt()
    val K = UInt()
    val dram_plane = UInt(32.W)
    val dram_row = UInt(32.W)
    val dram_col = UInt(32.W)
    val dram_inner = UInt(32.W)
    val dw_offset = UInt(32.W)
    val config_stride = UInt(64.W)
    val spad_base = UInt(32.W)
    val spad_bank = UInt(32.W)
    val spad_row = UInt(32.W)
    val spad_col = UInt(32.W)
    val spad_lane = UInt(32.W)
  }
  val spatial_p = Module(new Pipeline(new WeightAddressStage, 1)())
  val linear_p = Module(new Pipeline(new WeightAddressStage, 1)())
  val offset_p = Module(new Pipeline(new WeightAddressStage, 1)())
  val byte_p = Module(new Pipeline(new WeightAddressStage, 1)())
  val t1203 = req.trans_weight_1203
  val t0132 = req.trans_weight_0132
  val dw = if (has_dw_convs) req.dw else false.B
  val spad_stride = Mux(t0132, ochs, kchs)
  val first = spatial_p.io.in.bits
  first.is_config := state === config
  first.J := J
  first.K := K
  first.dram_plane := Mux(t1203, kch, krow) * kernel_dim
  first.dram_row := Mux(t1203, krow, kcol) * Mux(t1203, kernel_dim, Mux(t0132, out_channels, in_channels))
  first.dram_col := Mux(t1203, kcol, Mux(t0132, och, kch))
  first.dram_inner := Mux(!t1203 && t0132, kch, och)
  first.dw_offset := (krow * kernel_dim +& kcol) * (input_w / 8).U
  first.config_stride := kernel_dim * kernel_dim
  first.spad_base := Mux(t0132, in_channels_per_bank, out_channels_per_bank) * kcols
  first.spad_bank := (Mux(t0132, kch, och) >> log2Up(block_size)) * krows
  first.spad_row := krow * kcols
  first.spad_col := kcol * spad_stride
  first.spad_lane := Mux(t0132, och, kch)

  linear_p.io.in <> spatial_p.io.out
  val spatial = spatial_p.io.out.bits
  linear_p.io.in.bits.dram_plane := spatial.dram_plane * Mux(t1203, kernel_dim, Mux(t0132, out_channels, in_channels))
  linear_p.io.in.bits.config_stride := Mux(dw, 1.U,
    Mux(t1203, spatial.config_stride * out_channels, Mux(t0132, in_channels, weight_stride))) * (input_w / 8).U
  linear_p.io.in.bits.spad_base := spatial.spad_base * krows
  linear_p.io.in.bits.spad_bank := spatial.spad_bank * kcols
  linear_p.io.in.bits.spad_row := spatial.spad_row * spad_stride

  offset_p.io.in <> linear_p.io.out
  val linear = linear_p.io.out.bits
  offset_p.io.in.bits.dram_plane := linear.dram_plane + linear.dram_row + linear.dram_col
  offset_p.io.in.bits.spad_base := linear.spad_base * spad_stride
  offset_p.io.in.bits.spad_bank := linear.spad_bank * spad_stride

  byte_p.io.in <> offset_p.io.out
  val offset = offset_p.io.out.bits
  byte_p.io.in.bits.dram_plane := Mux(dw, offset.dw_offset,
    (offset.dram_plane * Mux(t1203, out_channels, Mux(t0132, in_channels, weight_stride)) + offset.dram_inner) * (input_w / 8).U)
  byte_p.io.in.bits.spad_base := req.addr_end - offset.spad_base
  byte_p.io.in.bits.spad_bank := offset.spad_bank + offset.spad_row
  byte_p.io.in.bits.spad_col := offset.spad_col + offset.spad_lane
  val addresses = byte_p.io.out.bits

  // Commands
  val config_cmd = Wire(new RoCCCommand)
  config_cmd := DontCare
  config_cmd.inst.funct := CONFIG_CMD

  val config_cmd_rs1 = Wire(config_mvin_rs1_t.cloneType)
  config_cmd_rs1 := DontCare
  config_cmd_rs1.scale := MVIN_SCALE_IDENTITY
  config_cmd_rs1.stride := req.derived_params.weight_spad_stride
  config_cmd_rs1.pixel_repeats := 1.U
  config_cmd_rs1.state_id := 1.U
  config_cmd_rs1.shrink := 0.U
  config_cmd_rs1._unused := 1.U
  config_cmd.rs1 := config_cmd_rs1.asUInt

  config_cmd.rs2 := addresses.config_stride

  val mvin_cmd = Wire(new RoCCCommand)
  mvin_cmd := DontCare
  mvin_cmd.inst.funct := LOAD2_CMD
  mvin_cmd.rs1 := 0.U // dram_addr
  mvin_cmd.rs2 := 0.U // mvin_cmd_rs2

  // Inputs and outputs
  io.req.ready := state === idle && !spatial_p.io.busy && !linear_p.io.busy &&
    !offset_p.io.busy && !byte_p.io.busy && !command_p.io.busy
  io.idle := state === idle && !spatial_p.io.busy && !linear_p.io.busy &&
    !offset_p.io.busy && !byte_p.io.busy && !command_p.io.busy
  io.loop_id := req.loop_id

  spatial_p.io.in.valid := state =/= idle && !io.wait_for_prev_loop && (req.dram_addr =/= 0.U)
  byte_p.io.out.ready := command_p.io.in.ready
  command_p.io.in.valid := byte_p.io.out.valid
  command_p.io.in.bits.cmd := Mux(addresses.is_config, config_cmd, mvin_cmd)
  command_p.io.in.bits.dram_addr := req.dram_addr +& addresses.dram_plane
  command_p.io.in.bits.spad_addr := addresses.spad_base + addresses.spad_bank + addresses.spad_col
  command_p.io.in.bits.K := addresses.K
  command_p.io.in.bits.J := addresses.J

  command_p.io.out.ready := io.cmd.ready && !io.rob_overloaded
  io.cmd.valid := command_p.io.out.valid && !io.rob_overloaded
  io.cmd.bits := command_p.io.out.bits.cmd
  when (command_p.io.out.bits.cmd.inst.funct === LOAD2_CMD) {
    val o = command_p.io.out.bits
    io.cmd.bits.rs1 := o.dram_addr
    val mvin_cmd_rs2 = Wire(mvin_rs2_t.cloneType)
    mvin_cmd_rs2 := DontCare
    mvin_cmd_rs2.num_rows := o.K
    mvin_cmd_rs2.num_cols := o.J
    mvin_cmd_rs2.local_addr := cast_to_sp_addr(mvin_cmd_rs2.local_addr, o.spad_addr)
    io.cmd.bits.rs2 := mvin_cmd_rs2.asUInt
  }

  // Sending outputs
  when(req.dram_addr === 0.U){
    state := idle
  }.elsewhen(spatial_p.io.in.fire) {
    when (state === config) {
      state := ld
    }.otherwise {
      val och_it = Mux(req.trans_weight_0132, block_size.U, max_chs_per_mvin)
      val kch_it = Mux(req.trans_weight_0132, max_chs_per_mvin, block_size.U)

      val next_kch = floorAdd(kch, kch_it, kchs)
      val next_kcol = floorAdd(kcol, 1.U, kcols, next_kch === 0.U)
      val next_krow = floorAdd(krow, 1.U, krows, next_kcol === 0.U && next_kch === 0.U)
      val next_och = floorAdd(och, och_it, ochs, next_krow === 0.U && next_kcol === 0.U && next_kch === 0.U)

      kch := next_kch
      kcol := next_kcol
      krow := next_krow
      och := next_och

      state := Mux(next_och === 0.U && next_krow === 0.U && next_kcol === 0.U && next_kch === 0.U,
        idle, ld)
    }
  }

  // Accepting requests
  when (io.req.fire) {
    req := io.req.bits
    state := config
    kch := 0.U
    kcol := 0.U
    krow := 0.U
    och := 0.U
  }

  /** IPOAT：Weight 子生成器阻塞快照
    * I（Input 输入）：状态、依赖/RS 背压、pipeline 与 och/krow/kcol/kch。
    * P（Process 处理）：低 8 位迭代坐标和握手状态只读打包。
    * O（Output 输出）：权重加载生成器等待对象及最后迭代位置。
    * A（Author 作者）：王志瑞
    * T（Time 时间）：2026-09-19
    */
  io.deadlock_debug := Cat(0.U(24.W), och(7, 0), krow.pad(8)(7, 0), kcol.pad(8)(7, 0),
    kch(7, 0), state.asUInt.pad(2), io.loop_id, io.wait_for_prev_loop,
    io.rob_overloaded, command_p.io.busy, io.cmd.valid, io.cmd.ready)
}

class LoopConvExecuteReq(val large_iterator_bitwidth: Int, val small_iterator_bitwidth: Int, val tiny_iterator_bitwidth: Int, val max_addr: Int, val max_acc_addr: Int, val concurrent_loops: Int)  extends Bundle {
  val outer_bounds = new LoopConvOuterBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val inner_bounds = new LoopConvInnerBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val derived_params = new LoopConvDerivedParams(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val a_addr_start = UInt(log2Up(max_addr).W)
  val b_addr_end = UInt(log2Up(max_addr+1).W)
  val c_addr_start = UInt(log2Up(max_acc_addr).W)
  val wrot180 = Bool()
  val downsample = Bool()
  val max_pixels_per_row = UInt(small_iterator_bitwidth.W)
  val input_dilated = Bool()
  val trans_weight_0132 = Bool()
  val trans_input_3120 = Bool()
  val loop_id = UInt(log2Up(concurrent_loops).W)
}

class LoopConvExecute(block_size: Int, large_iterator_bitwidth: Int, small_iterator_bitwidth: Int, tiny_iterator_bitwidth: Int, max_addr: Int,
                      max_acc_addr: Int, concurrent_loops: Int, latency: Int,
                      config_ex_rs1_t: ConfigExRs1, preload_rs1_t: PreloadRs, preload_rs2_t: PreloadRs,
                      compute_rs1_t: ComputeRs, compute_rs2_t: ComputeRs)(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    val req = Flipped(Decoupled(new LoopConvExecuteReq(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, max_addr, max_acc_addr, concurrent_loops)))
    val cmd = Decoupled(Output(new RoCCCommand))

    val lda_completed = Input(Bool())
    val ldb_completed = Input(Bool())
    val ldd_completed = Input(Bool())

    val idle = Output(Bool())
    val rob_overloaded = Input(Bool())

    val loop_id = Output(UInt(log2Up(concurrent_loops).W))
    val deadlock_debug = Output(UInt(64.W))
  })

  object State extends ChiselEnum {
    val idle, config, pre, comp = Value
  }
  import State._
  val state = RegInit(idle)

  val req = Reg(new LoopConvExecuteReq(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth,
    max_addr, max_acc_addr, concurrent_loops))
  import req.outer_bounds._
  import req.inner_bounds._
  import req.derived_params._

  def undilated(x: UInt): UInt = (x +& req.input_dilated) >> req.input_dilated

  val a_addr_start = req.a_addr_start
  // B_rows is invariant for the lifetime of a request. Registering this base
  // at request acceptance removes one multiplier level from every command.
  val b_addr_start = Reg(UInt(log2Up(max_addr + 1).W))
  val c_addr_start = /*(BigInt(3) << 30).U |*/ req.c_addr_start

  // Iterators
  val och = Reg(UInt(large_iterator_bitwidth.W))
  val krow = Reg(UInt(tiny_iterator_bitwidth.W))
  val kcol = Reg(UInt(tiny_iterator_bitwidth.W))
  val kch = Reg(UInt(large_iterator_bitwidth.W))
  val b = Reg(UInt(large_iterator_bitwidth.W))
  val orow = Reg(UInt(small_iterator_bitwidth.W))
  val ocol = Reg(UInt(small_iterator_bitwidth.W))

  // TODO kernel-dilation and input-dilation can never be activated at the same time, so we can optimize out some multiplications by kernel_dilation
  val skip_iteration = state >= pre && req.input_dilated && (((krow * kernel_dilation +& orow -& upad)(0) & req.input_dilated).asBool ||
    ((kcol * kernel_dilation +& ocol -& lpad)(0) & req.input_dilated).asBool)

  val pixels = Mux(kcols - kcol > req.max_pixels_per_row, req.max_pixels_per_row, kcols - kcol)

  val irow = undilated(orow * stride +& krow * kernel_dilation)
  val icol = undilated(ocol * stride +& kcol * kernel_dilation)

  val I = Mux(req.trans_input_3120,
    Mux(batches - b > block_size.U, block_size.U, batches - b),
    undilated(Mux(ocols - ocol > (block_size.U << req.input_dilated).asUInt, (block_size.U << req.input_dilated).asUInt, ocols - ocol)))
  val J = Mux(ochs - och > block_size.U, block_size.U, ochs - och)
  val K = pixels * Mux(kchs - kch > block_size.U, block_size.U, kchs - kch)

  // val new_weights = b === 0.U && orow === 0.U && ocol === 0.U
  val new_weights = Reg(Bool())
  val krow_rot = Mux(req.wrot180, krows - krow - 1.U, krow)
  val kcol_rot = Mux(req.wrot180, kcols - kcol - 1.U, kcol)

  /** Register the iterator-to-spatial transform first. In particular this
    * separates (orow*stride + krow*dilation) from the later row-stride
    * multiply; without this stage the A address still contains two cascaded
    * DSPs even though the B address has been split.
    */
  class SpatialPrecalc extends Bundle {
    val state = UInt(2.W)
    val b = UInt(large_iterator_bitwidth.W)
    val orow = UInt(small_iterator_bitwidth.W)
    val ocol = UInt(small_iterator_bitwidth.W)
    val och = UInt(large_iterator_bitwidth.W)
    val krow_rot = UInt(tiny_iterator_bitwidth.W)
    val kcol_rot = UInt(tiny_iterator_bitwidth.W)
    val kch = UInt(large_iterator_bitwidth.W)
    val irow = UInt(small_iterator_bitwidth.W)
    val icol = UInt(small_iterator_bitwidth.W)
    val I = UInt(large_iterator_bitwidth.W)
    val J = UInt(large_iterator_bitwidth.W)
    val K = UInt(large_iterator_bitwidth.W)
    val new_weights = Bool()
  }
  val spatial_p = Module(new Pipeline[SpatialPrecalc](new SpatialPrecalc, 1)())
  spatial_p.io.in.bits.state := state.asUInt
  spatial_p.io.in.bits.b := b
  spatial_p.io.in.bits.orow := orow
  spatial_p.io.in.bits.ocol := ocol
  spatial_p.io.in.bits.och := och
  spatial_p.io.in.bits.krow_rot := krow_rot
  spatial_p.io.in.bits.kcol_rot := kcol_rot
  spatial_p.io.in.bits.kch := kch
  spatial_p.io.in.bits.irow := irow
  spatial_p.io.in.bits.icol := icol
  spatial_p.io.in.bits.I := I
  spatial_p.io.in.bits.J := J
  spatial_p.io.in.bits.K := K
  spatial_p.io.in.bits.new_weights := new_weights
  val sp = spatial_p.io.out.bits

  /** Second half of the EX address calculation. All products below are
    * independent single multipliers; the final half contains additions only.
    */
  class AddressPrecalc extends Bundle {
    val state = UInt(2.W)
    val a_bank = UInt(log2Up(max_addr + 1).W)
    val a_plane = UInt(log2Up(max_addr + 1).W)
    val a_row = UInt(log2Up(max_addr + 1).W)
    val b_bank = UInt(log2Up(max_addr + 1).W)
    val b_row = UInt(log2Up(max_addr + 1).W)
    val b_col = UInt(log2Up(max_addr + 1).W)
    val b_lane = UInt(log2Up(max_addr + 1).W)
    val c_bank = UInt(log2Up(max_acc_addr + 1).W)
    val c_batch = UInt(log2Up(max_acc_addr + 1).W)
    val c_row = UInt(log2Up(max_acc_addr + 1).W)
    val I = UInt(large_iterator_bitwidth.W)
    val J = UInt(large_iterator_bitwidth.W)
    val K = UInt(large_iterator_bitwidth.W)
    val new_weights = Bool()
  }
  val address_p = Module(new Pipeline[AddressPrecalc](new AddressPrecalc, 1)())
  address_p.io.in.bits.state := sp.state
  address_p.io.in.bits.a_bank := a_addr_start +& Mux(req.trans_input_3120,
    sp.b >> log2Up(block_size), sp.kch >> log2Up(block_size)) * input_spad_stride
  address_p.io.in.bits.a_plane := Mux(req.trans_input_3120, sp.kch, sp.b) * input_plane_stride
  address_p.io.in.bits.a_row := (sp.irow >> req.downsample) * input_row_stride +&
    (sp.icol >> req.downsample)
  address_p.io.in.bits.b_bank := b_addr_start +& Mux(req.trans_weight_0132,
    sp.kch >> log2Up(block_size), sp.och >> log2Up(block_size)) * weight_spad_stride
  address_p.io.in.bits.b_row := sp.krow_rot * weight_row_stride
  address_p.io.in.bits.b_col := sp.kcol_rot * Mux(req.trans_weight_0132, ochs, kchs)
  address_p.io.in.bits.b_lane := Mux(req.trans_weight_0132, sp.och, sp.kch)
  address_p.io.in.bits.c_bank := c_addr_start +&
    (sp.och >> log2Up(block_size)) * bias_spad_stride
  address_p.io.in.bits.c_batch := sp.b * output_plane_stride
  address_p.io.in.bits.c_row := sp.orow * output_row_stride +& sp.ocol
  address_p.io.in.bits.I := sp.I
  address_p.io.in.bits.J := sp.J
  address_p.io.in.bits.K := sp.K
  address_p.io.in.bits.new_weights := sp.new_weights

  class RoCCCommandWithAddr extends Bundle {
    val cmd = new RoCCCommand
    val a_addr = UInt()
    val b_addr = UInt()
    val c_addr = UInt()
    val I = UInt()
    val J = UInt()
    val K = UInt()
    val new_weights = Bool()
  }
  val command_p = Module(new Pipeline[RoCCCommandWithAddr](new RoCCCommandWithAddr, latency)())
  val ap = address_p.io.out.bits

  // Commands
  val config_cmd = Wire(new RoCCCommand)
  config_cmd := DontCare
  config_cmd.inst.funct := CONFIG_CMD

  val config_cmd_rs1 = Wire(config_ex_rs1_t.cloneType)
  config_cmd_rs1 := DontCare
  config_cmd_rs1.a_stride := input_plane_stride
  config_cmd_rs1.set_only_strides := 1.U
  config_cmd_rs1.cmd_type := 0.U

  val config_cmd_rs2 = Wire(new ConfigExRs2)
  config_cmd_rs2 := DontCare
  config_cmd_rs2.c_stride := output_plane_stride

  config_cmd.rs1 := config_cmd_rs1.asUInt
  config_cmd.rs2 := config_cmd_rs2.asUInt

  val pre_cmd = Wire(new RoCCCommand) // preload
  pre_cmd := DontCare
  pre_cmd.inst.funct := PRELOAD_CMD
  pre_cmd.rs1 := 0.U//(K << 48) | (J << 32) | pre_addr
  pre_cmd.rs2 := 0.U//(I << 48) | (J << 32) | c_addr

  val comp_cmd = Wire(new RoCCCommand()) // compute.preloaded
  comp_cmd := DontCare
  comp_cmd.inst.funct := Mux(ap.new_weights, COMPUTE_AND_FLIP_CMD, COMPUTE_AND_STAY_CMD)
  comp_cmd.rs1 := 0.U//(I << 48) | (K << 32) | a_addr
  comp_cmd.rs2 := 0.U//(I << 48) | (J << 32) | GARBAGE_ADDR

  val ld_ahead = io.lda_completed && io.ldb_completed && io.ldd_completed

  // Inputs and outputs
  io.req.ready := state === idle && !spatial_p.io.busy && !address_p.io.busy && !command_p.io.busy
  io.idle := state === idle && !spatial_p.io.busy && !address_p.io.busy && !command_p.io.busy
  io.loop_id := req.loop_id

  spatial_p.io.in.valid := state =/= idle && !skip_iteration && ld_ahead
  spatial_p.io.out.ready := address_p.io.in.ready
  address_p.io.in.valid := spatial_p.io.out.valid
  address_p.io.out.ready := command_p.io.in.ready
  command_p.io.in.valid := address_p.io.out.valid
  command_p.io.in.bits.cmd := MuxCase(config_cmd, Seq(
    (ap.state === pre.asUInt) -> pre_cmd,
    (ap.state === comp.asUInt) -> comp_cmd))
  // Registered stage A terms meet here; no multiplier is cascaded into the
  // command pipeline input.
  command_p.io.in.bits.a_addr := ap.a_bank +& ap.a_plane +& ap.a_row
  command_p.io.in.bits.b_addr := ap.b_bank +& ap.b_row +& ap.b_col +& ap.b_lane
  command_p.io.in.bits.c_addr := ap.c_bank +& ap.c_batch +& ap.c_row
  command_p.io.in.bits.I := ap.I
  command_p.io.in.bits.J := ap.J
  command_p.io.in.bits.K := ap.K
  command_p.io.in.bits.new_weights := ap.new_weights

  command_p.io.out.ready := io.cmd.ready && !io.rob_overloaded
  io.cmd.valid := command_p.io.out.valid && !io.rob_overloaded
  io.cmd.bits := command_p.io.out.bits.cmd
  when (command_p.io.out.bits.cmd.inst.funct === PRELOAD_CMD) {
    val o = command_p.io.out.bits

    val pre_cmd_rs1 = Wire(preload_rs1_t.cloneType)
    pre_cmd_rs1 := DontCare
    pre_cmd_rs1.num_rows := o.K.asUInt
    pre_cmd_rs1.num_cols := o.J.asUInt
    pre_cmd_rs1.local_addr := Mux(o.new_weights, cast_to_sp_addr(pre_cmd_rs1.local_addr, o.b_addr),
      garbage_addr(pre_cmd_rs1.local_addr))

    val pre_cmd_rs2 = Wire(preload_rs2_t.cloneType)
    pre_cmd_rs2 := DontCare
    pre_cmd_rs2.num_rows := o.I.asUInt
    pre_cmd_rs2.num_cols := o.J.asUInt
    pre_cmd_rs2.local_addr := cast_to_acc_addr(pre_cmd_rs2.local_addr, o.c_addr, accumulate = true.B, read_full = false.B)

    io.cmd.bits.rs1 := pre_cmd_rs1.asUInt
    io.cmd.bits.rs2 := pre_cmd_rs2.asUInt
  }.elsewhen(command_p.io.out.bits.cmd.inst.funct =/= CONFIG_CMD) {
    val o = command_p.io.out.bits
    val comp_cmd_rs1 = Wire(compute_rs1_t.cloneType)
    comp_cmd_rs1 := DontCare
    comp_cmd_rs1.num_rows := o.I.asUInt
    comp_cmd_rs1.num_cols := o.K.asUInt
    comp_cmd_rs1.local_addr := cast_to_sp_addr(comp_cmd_rs1.local_addr, o.a_addr)

    val comp_cmd_rs2 = Wire(compute_rs2_t.cloneType)
    comp_cmd_rs2 := DontCare
    comp_cmd_rs2.num_rows := o.I.asUInt
    comp_cmd_rs2.num_cols := o.J.asUInt
    comp_cmd_rs2.local_addr := garbage_addr(comp_cmd_rs2.local_addr)

    io.cmd.bits.rs1 := comp_cmd_rs1.asUInt
    io.cmd.bits.rs2 := comp_cmd_rs2.asUInt
  }

  // Updating "new_weights"
  when (state === comp && spatial_p.io.in.fire) {
    new_weights := false.B
  }

  // Sending outputs
  when (spatial_p.io.in.fire || skip_iteration) {
    when (state === config) {
      state := pre
    }.elsewhen (state === pre) {
      state := comp
    }.otherwise {
      val b_it = Mux(req.trans_input_3120, block_size.U, 1.U)
      val ocol_it = Mux(skip_iteration || req.trans_input_3120, 1.U, block_size.U << req.input_dilated).asUInt

      val next_ocol = floorAdd(ocol, ocol_it, ocols)
      val next_orow = floorAdd(orow, 1.U, orows, next_ocol === 0.U)
      val next_b = floorAdd(b, b_it, batches, next_orow === 0.U && next_ocol === 0.U)
      val next_kch = floorAdd(kch, block_size.U, kchs,
        next_b === 0.U && next_orow === 0.U && next_ocol === 0.U)
      val next_kcol = floorAdd(kcol, req.max_pixels_per_row, kcols,
        next_kch === 0.U && next_b === 0.U && next_orow === 0.U && next_ocol === 0.U)
      val next_krow = floorAdd(krow, 1.U, krows,
        next_kcol === 0.U && next_kch === 0.U && next_b === 0.U && next_orow === 0.U && next_ocol === 0.U)
      val next_och = floorAdd(och, block_size.U, ochs, next_krow === 0.U &&
        next_kcol === 0.U && next_kch === 0.U && next_b === 0.U && next_orow === 0.U && next_ocol === 0.U)

      ocol := next_ocol
      orow := next_orow
      b := next_b
      kch := next_kch
      kcol := next_kcol
      krow := next_krow
      och := next_och

      when (next_b === 0.U && next_orow === 0.U && next_ocol === 0.U) {
        new_weights := true.B
      }

      state := Mux(next_och === 0.U && next_krow === 0.U && next_kcol === 0.U && next_kch === 0.U && next_b === 0.U &&
        next_orow === 0.U && next_ocol === 0.U,
        idle, pre)
    }
  }

  // Accepting requests
  when (io.req.fire) {
    req := io.req.bits
    val weightBanks = Mux(io.req.bits.trans_weight_0132,
      io.req.bits.derived_params.in_channels_per_bank,
      io.req.bits.derived_params.out_channels_per_bank)
    b_addr_start := io.req.bits.b_addr_end -&
      weightBanks * io.req.bits.derived_params.weight_spad_stride
    state := Mux(io.req.bits.trans_input_3120, config, pre)

    b := 0.U
    orow := 0.U
    ocol := 0.U
    och := 0.U
    krow := 0.U
    kcol := 0.U
    kch := 0.U

    new_weights := true.B
  }

  /** IPOAT：Execute 子生成器阻塞快照
    * I（Input 输入）：状态、load-ahead、RS/pipeline 背压和七级卷积迭代坐标。
    * P（Process 处理）：控制位与各坐标低 8 位组合，不改变 PRELOAD/COMPUTE 调度。
    * O（Output 输出）：执行生成器究竟等待 load、RS ready 还是内部 pipeline。
    * A（Author 作者）：王志瑞
    * T（Time 时间）：2026-09-19
    */
  io.deadlock_debug := Cat(b(7, 0), orow(7, 0), ocol(7, 0), och(7, 0),
    krow.pad(8)(7, 0), kcol.pad(8)(7, 0), kch(7, 0), state.asUInt.pad(2),
    io.loop_id, ld_ahead, io.rob_overloaded, command_p.io.busy, io.cmd.valid, io.cmd.ready)
}

class LoopConvStReq(val coreMaxAddrBits: Int, val large_iterator_bitwidth: Int, val small_iterator_bitwidth: Int, val tiny_iterator_bitwidth: Int, val max_acc_addr: Int, val concurrent_loops: Int)  extends Bundle {
  val outer_bounds = new LoopConvOuterBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val inner_bounds = new LoopConvInnerBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val derived_params = new LoopConvDerivedParams(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val addr_start = UInt(log2Up(max_acc_addr).W)
  val dram_addr = UInt(coreMaxAddrBits.W)
  val no_pool = Bool()
  val activation = UInt(Activation.bitwidth.W)
  val trans_output_1203 = Bool()
  val loop_id = UInt(log2Up(concurrent_loops).W)
}

class LoopConvSt(block_size: Int, coreMaxAddrBits: Int, large_iterator_bitwidth: Int, small_iterator_bitwidth: Int, tiny_iterator_bitwidth: Int, max_acc_addr: Int, input_w: Int, concurrent_loops: Int, latency: Int, config_mvout_rs2_t: ConfigMvoutRs2, mvout_rs2_t: MvoutRs2)(implicit p: Parameters) extends Module {
  val ACC_SCALE_NO_CHANGE = ~(0.U(32.W)) // TODO get this from ISA description somehow

  val io = IO(new Bundle {
    val req = Flipped(Decoupled(new LoopConvStReq(coreMaxAddrBits, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth: Int, max_acc_addr, concurrent_loops)))
    val cmd = Decoupled(Output(new RoCCCommand))

    val ex_completed = Input(Bool())

    val idle = Output(Bool())
    val rob_overloaded = Input(Bool())

    val loop_id = Output(UInt(log2Up(concurrent_loops).W))
    val deadlock_debug = Output(UInt(64.W))
  })

  object State extends ChiselEnum {
    val idle, st, pre_pool_config, pool, post_pool_config = Value
  }
  import State._
  val state = RegInit(idle)

  val req = Reg(new LoopConvStReq(coreMaxAddrBits, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth: Int, max_acc_addr, concurrent_loops))
  import req.outer_bounds._
  import req.inner_bounds._
  import req.derived_params._

  val acc_addr_start = req.addr_start

  // Derived parameters
  val skip = req.dram_addr === 0.U

  // Iterators
  val b = Reg(UInt(large_iterator_bitwidth.W))
  val orow = Reg(UInt(small_iterator_bitwidth.W))
  val ocol = Reg(UInt(small_iterator_bitwidth.W))
  val och = Reg(UInt(large_iterator_bitwidth.W))

  // Sizes
  val I = Mux(ocols - ocol > block_size.U, block_size.U, ocols - ocol)
  val J = Mux(ochs - och > block_size.U, block_size.U, ochs - och)

  val channels = J

  class RoCCCommandWithAddr extends Bundle {
    val cmd = new RoCCCommand
    val dram_addr = UInt()
    val spad_addr = UInt()
    val pool_dram_addr = UInt()
    val pool_spad_addr = UInt()
    val channels = UInt()
    val is_pool = Bool()
    val I = UInt()
    val J = UInt()
  }
  val command_p = Module(new Pipeline[RoCCCommandWithAddr](new RoCCCommandWithAddr, latency)())
  // Split independent products, linearization, and byte scaling. Normal
  // DRAM offsets retain the existing 32-bit wrap; pooling offsets keep all
  // 64 bits because the original pooling path has no castDramOffset mask.
  class StoreAddressStage extends Bundle {
    val state = UInt(3.W)
    val I = UInt()
    val J = UInt()
    val och = UInt(large_iterator_bitwidth.W)
    val dram_plane = UInt(32.W)
    val dram_row = UInt(32.W)
    val dram_col = UInt(32.W)
    val pool_plane = UInt(64.W)
    val spad_bank = UInt(32.W)
    val spad_plane = UInt(32.W)
    val spad_row = UInt(32.W)
    val spad_col = UInt(32.W)
  }
  val spatial_p = Module(new Pipeline(new StoreAddressStage, 1)())
  val linear_p = Module(new Pipeline(new StoreAddressStage, 1)())
  val offset_p = Module(new Pipeline(new StoreAddressStage, 1)())
  val byte_p = Module(new Pipeline(new StoreAddressStage, 1)())
  val first = spatial_p.io.in.bits
  first.state := state.asUInt
  first.I := I
  first.J := J
  first.och := och
  first.dram_plane := Mux(req.trans_output_1203, orow, b) *
    Mux(req.trans_output_1203, out_col_dim, out_row_dim)
  first.dram_row := Mux(req.trans_output_1203, ocol, orow) *
    Mux(req.trans_output_1203, batch_size, out_col_dim)
  first.dram_col := Mux(req.trans_output_1203, b, ocol)
  first.pool_plane := b * pool_out_col_dim
  first.spad_bank := (och >> log2Up(block_size)) * batches
  first.spad_plane := b * orows
  first.spad_row := orow * ocols
  first.spad_col := ocol

  linear_p.io.in <> spatial_p.io.out
  val spatial = spatial_p.io.out.bits
  linear_p.io.in.bits.dram_plane := spatial.dram_plane *
    Mux(req.trans_output_1203, batch_size, out_col_dim)
  linear_p.io.in.bits.pool_plane := spatial.pool_plane * pool_out_row_dim
  linear_p.io.in.bits.spad_bank := spatial.spad_bank * orows
  linear_p.io.in.bits.spad_plane := spatial.spad_plane * ocols

  offset_p.io.in <> linear_p.io.out
  val linear = linear_p.io.out.bits
  offset_p.io.in.bits.dram_plane := linear.dram_plane + linear.dram_row + linear.dram_col
  offset_p.io.in.bits.spad_bank := linear.spad_bank * ocols

  byte_p.io.in <> offset_p.io.out
  val offset = offset_p.io.out.bits
  byte_p.io.in.bits.dram_plane :=
    (offset.dram_plane * Mux(req.trans_output_1203, out_channels, out_stride) + offset.och) * (input_w / 8).U
  byte_p.io.in.bits.pool_plane := (offset.pool_plane * out_stride + offset.och) * (input_w / 8).U
  byte_p.io.in.bits.spad_bank := offset.spad_bank + offset.spad_plane + acc_addr_start
  byte_p.io.in.bits.spad_plane :=
    (offset.spad_bank + offset.spad_plane) + (offset.spad_row + offset.spad_col) + acc_addr_start
  val addresses = byte_p.io.out.bits
  // Commands
  val mvout_cmd = Wire(new RoCCCommand)
  mvout_cmd := DontCare
  mvout_cmd.inst.funct := STORE_CMD
  mvout_cmd.rs1 := 0.U // dram_addr
  mvout_cmd.rs2 := 0.U // mvout_cmd_rs2

  val pre_pool_config_cmd = Wire(new RoCCCommand)
  pre_pool_config_cmd := DontCare
  pre_pool_config_cmd.inst.funct := CONFIG_CMD
  val pre_pool_config_cmd_rs1 = Wire(new ConfigMvoutRs1)
  pre_pool_config_cmd_rs1 := DontCare
  pre_pool_config_cmd_rs1.ocols := ocols
  pre_pool_config_cmd_rs1.orows := orows
  pre_pool_config_cmd_rs1.pocols := pocols
  pre_pool_config_cmd_rs1.porows := porows
  pre_pool_config_cmd_rs1.pool_out_dim := pool_out_col_dim
  pre_pool_config_cmd_rs1.lpad := plpad
  pre_pool_config_cmd_rs1.upad := pupad
  pre_pool_config_cmd_rs1.pool_size := pool_size
  pre_pool_config_cmd_rs1.pool_stride := pool_stride
  pre_pool_config_cmd_rs1.activation := req.activation
  pre_pool_config_cmd_rs1.cmd_type := CONFIG_STORE
  pre_pool_config_cmd.rs1 := pre_pool_config_cmd_rs1.asUInt

  val pre_pool_config_cmd_rs2 = Wire(config_mvout_rs2_t.cloneType)
  pre_pool_config_cmd_rs2 := DontCare
  pre_pool_config_cmd_rs2.acc_scale := ACC_SCALE_NO_CHANGE
  pre_pool_config_cmd_rs2.stride := out_stride * (input_w / 8).U
  pre_pool_config_cmd.rs2 := pre_pool_config_cmd_rs2.asUInt

  val post_pool_config_cmd = Wire(new RoCCCommand)
  post_pool_config_cmd := DontCare
  post_pool_config_cmd.inst.funct := CONFIG_CMD

  val post_pool_config_cmd_rs1 = Wire(new ConfigMvoutRs1)
  post_pool_config_cmd_rs1 := DontCare
  post_pool_config_cmd_rs1.activation := req.activation
  post_pool_config_cmd_rs1.cmd_type := CONFIG_STORE
  post_pool_config_cmd.rs1 := post_pool_config_cmd_rs1.asUInt

  val post_pool_config_cmd_rs2 = Wire(config_mvout_rs2_t.cloneType)
  post_pool_config_cmd_rs2 := DontCare
  post_pool_config_cmd_rs2.acc_scale := ACC_SCALE_NO_CHANGE
  post_pool_config_cmd_rs2.stride := out_stride * (input_w / 8).U
  post_pool_config_cmd.rs2 := post_pool_config_cmd_rs2.asUInt

  val pool_cmd = Wire(new RoCCCommand)
  pool_cmd := DontCare
  pool_cmd.inst.funct := STORE_CMD
  pool_cmd.rs1 := 0.U//pool_dram_addr
  pool_cmd.rs2 := 0.U//(channels << 32.U) | pool_spad_addr

  // Inputs and outputs
  io.req.ready := state === idle && !spatial_p.io.busy && !linear_p.io.busy &&
    !offset_p.io.busy && !byte_p.io.busy && !command_p.io.busy
  io.idle := state === idle && !spatial_p.io.busy && !linear_p.io.busy &&
    !offset_p.io.busy && !byte_p.io.busy && !command_p.io.busy
  io.loop_id := req.loop_id

  spatial_p.io.in.valid := state =/= idle && !skip && io.ex_completed
  byte_p.io.out.ready := command_p.io.in.ready
  command_p.io.in.valid := byte_p.io.out.valid
  command_p.io.in.bits.cmd := MuxLookup(addresses.state, mvout_cmd)(Seq(
    pre_pool_config.asUInt -> pre_pool_config_cmd,
    pool.asUInt -> pool_cmd,
    post_pool_config.asUInt -> post_pool_config_cmd)
  )
  command_p.io.in.bits.is_pool := addresses.state === pool.asUInt
  command_p.io.in.bits.dram_addr := req.dram_addr +& addresses.dram_plane
  command_p.io.in.bits.spad_addr := addresses.spad_plane
  command_p.io.in.bits.pool_spad_addr := addresses.spad_bank
  command_p.io.in.bits.pool_dram_addr := req.dram_addr +& addresses.pool_plane
  command_p.io.in.bits.channels := addresses.J
  command_p.io.in.bits.I := addresses.I
  command_p.io.in.bits.J := addresses.J

  command_p.io.out.ready := io.cmd.ready && !io.rob_overloaded
  io.cmd.valid := command_p.io.out.valid && !io.rob_overloaded
  io.cmd.bits := command_p.io.out.bits.cmd
  when (command_p.io.out.bits.cmd.inst.funct === STORE_CMD) {
    val o = command_p.io.out.bits
    when (o.is_pool) {
      val pool_mvout_cmd_rs2 = Wire(mvout_rs2_t.cloneType)
      pool_mvout_cmd_rs2 := DontCare
      pool_mvout_cmd_rs2.num_cols := o.channels
      pool_mvout_cmd_rs2.local_addr := cast_to_acc_addr(pool_mvout_cmd_rs2.local_addr, o.pool_spad_addr, accumulate = false.B, read_full = false.B)

      io.cmd.bits.rs1 := o.pool_dram_addr
      io.cmd.bits.rs2 := pool_mvout_cmd_rs2.asUInt
    } .otherwise {
      val mvout_cmd_rs2 = Wire(mvout_rs2_t.cloneType)
      mvout_cmd_rs2 := DontCare
      mvout_cmd_rs2.num_rows := o.I.asUInt
      mvout_cmd_rs2.num_cols := o.J.asUInt
      mvout_cmd_rs2.local_addr := cast_to_acc_addr(mvout_cmd_rs2.local_addr, o.spad_addr, accumulate = false.B, read_full = false.B)

      io.cmd.bits.rs1 := o.dram_addr
      io.cmd.bits.rs2 := mvout_cmd_rs2.asUInt
    }
  }

  // Sending outputs
  when (skip) {
    state := idle
  }.elsewhen(spatial_p.io.in.fire) {
    when (req.no_pool) {
      val next_och = floorAdd(och, block_size.U, ochs)
      val next_ocol = floorAdd(ocol, block_size.U, ocols, next_och === 0.U)
      val next_orow = floorAdd(orow, 1.U, orows, next_ocol === 0.U && next_och === 0.U)
      val next_b = floorAdd(b, 1.U, batches, next_orow === 0.U && next_ocol === 0.U && next_och === 0.U)

      och := next_och
      ocol := next_ocol
      orow := next_orow
      b := next_b

      state := Mux(next_b === 0.U && next_orow === 0.U && next_ocol === 0.U && next_och === 0.U,
        idle, st)
    }.elsewhen(state === pre_pool_config) {
      state := pool
    }.elsewhen(state === post_pool_config) {
      state := idle
    }.otherwise {
      val next_och = floorAdd(och, block_size.U, ochs)
      val next_b = floorAdd(b, 1.U, batches, next_och === 0.U)

      och := next_och
      b := next_b

      state := Mux(next_b === 0.U && next_och === 0.U,
        post_pool_config, pool)
    }
  }

  // Accepting requests
  when (io.req.fire) {
    req := io.req.bits
    state := Mux(io.req.bits.no_pool, st, pre_pool_config)

    b := 0.U
    orow := 0.U
    ocol := 0.U
    och := 0.U
  }

  /** IPOAT：Store 子生成器阻塞快照
    * I（Input 输入）：状态、execute-ahead、RS/pipeline 背压和 b/orow/ocol/och。
    * P（Process 处理）：只读组合为固定 64-bit 页。
    * O（Output 输出）：Store 生成器是否在等 EX、RS 或 pipeline 出口。
    * A（Author 作者）：王志瑞
    * T（Time 时间）：2026-09-19
    */
  io.deadlock_debug := Cat(0.U(24.W), b(7, 0), orow(7, 0), ocol(7, 0), och(7, 0),
    state.asUInt.pad(3), io.loop_id, io.ex_completed, io.rob_overloaded,
    command_p.io.busy, io.cmd.valid)
}

class LoopConvState(val block_size: Int, val large_iterator_bitwidth: Int, val small_iterator_bitwidth: Int, val tiny_iterator_bitwidth: Int, val coreMaxAddrBits: Int, val max_addr: Int, val max_acc_addr: Int) extends Bundle {
  val request_seq = UInt(32.W)
  val outer_bounds = new LoopConvOuterBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)
  val inner_bounds = new LoopConvInnerBounds(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)

  val bias_dram_addr = UInt(coreMaxAddrBits.W)
  val weights_dram_addr = UInt(coreMaxAddrBits.W)
  val input_dram_addr = UInt(coreMaxAddrBits.W)
  val output_dram_addr = UInt(coreMaxAddrBits.W)

  val no_bias = Bool()
  val wrot180 = Bool()
  val no_pool = Bool()
  val downsample = Bool()
  val input_dilated = Bool()
  val activation = UInt(Activation.bitwidth.W)
  val trans_output_1203 = Bool()
  val trans_weight_1203 = Bool()
  val trans_weight_0132 = Bool()
  val trans_input_3120 = Bool()
  val dw = Bool()

  val max_pixels_per_row = UInt(small_iterator_bitwidth.W)
  val a_ex_spad_id = UInt(2.W)
  val b_ex_spad_id = UInt(2.W)

  val configured = Bool()
  val derive_pending = Bool()
  val deriving = Bool()
  val cached_derived_params = new LoopConvDerivedParams(
    large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth)

  val running = Bool()

  val ld_bias_started = Bool()
  val ld_input_started = Bool()
  val ld_weights_started = Bool()
  val ex_started = Bool()
  val st_started = Bool()

  val ld_bias_completed = Bool()
  val ld_input_completed = Bool()
  val ld_weights_completed = Bool()
  val ex_completed = Bool()
  val st_completed = Bool()

  def all_completed(dummy: Int=0): Bool = ld_bias_completed && ld_input_completed && ld_weights_completed && ex_completed && st_completed

  val a_addr_start = UInt(log2Up(max_addr).W)
  val b_addr_end = UInt(log2Up(max_addr+1).W)

  def derived_params(dummy: Int=0): LoopConvDerivedParams = {
    import outer_bounds.{stride, kernel_dilation}
    import inner_bounds.{batches, pochs, orows, ocols, krows, kcols, upad, dpad, lpad, rpad, kchs}

    val result = Wire(new LoopConvDerivedParams(large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth))

    result.ochs := pochs

    val dilated_krows = krows + (kernel_dilation - 1.U)*(krows - 1.U)
    val dilated_kcols = kcols + (kernel_dilation - 1.U)*(kcols - 1.U)

    val irows_without_dilation = orows * stride +& dilated_krows -& 1.U
    val icols_without_dilation = ocols * stride +& dilated_kcols -& 1.U
    val irows_unpadded_without_dilation = irows_without_dilation -& upad -& dpad
    val icols_unpadded_without_dilation = icols_without_dilation -& lpad -& rpad

    def undilated(x: UInt): UInt = (x +& input_dilated) >> input_dilated

    val irows_unpadded = undilated(irows_unpadded_without_dilation)
    val icols_unpadded = undilated(icols_unpadded_without_dilation)

    result.irows := Mux(input_dilated, irows_unpadded +& undilated(upad) +& undilated(dpad), irows_without_dilation)
    result.icols := Mux(input_dilated, icols_unpadded +& undilated(lpad) +& undilated(rpad), icols_without_dilation)

    result.irows_unpadded := irows_unpadded
    result.icols_unpadded := icols_unpadded

    result.ichs := kchs

    result.out_channels_per_bank := result.ochs / block_size.U(result.ochs.getWidth.W) +& (result.ochs % block_size.U =/= 0.U)
    result.in_channels_per_bank := result.ichs / block_size.U(result.ochs.getWidth.W) +& (result.ichs % block_size.U =/= 0.U)

    result.input_row_stride := result.icols >> downsample
    result.input_plane_stride := (result.irows >> downsample) * result.input_row_stride
    result.output_row_stride := ocols
    result.output_plane_stride := orows * ocols
    result.weight_row_stride := kcols * Mux(trans_weight_0132, pochs, kchs)

    result.bias_spad_stride := batches * result.output_plane_stride
    result.input_spad_stride := Mux(trans_input_3120,
      result.ichs * result.input_plane_stride,
      batches * result.input_plane_stride)
    result.weight_spad_stride := krows * result.weight_row_stride

    // result.ex_overwrite := bias_dram_addr =/= 0.U && no_bias

    result
  }

  def reset(): Unit = {
    request_seq := 0.U
    configured := false.B
    derive_pending := false.B
    deriving := false.B

    running := false.B

    ld_bias_started := false.B
    ld_input_started := false.B
    ld_weights_started := false.B
    ex_started := false.B
    st_started := false.B

    ld_bias_completed := false.B
    ld_input_completed := false.B
    ld_weights_completed := false.B
    ex_completed := false.B
    st_completed := false.B
  }
}

class LoopConv (block_size: Int, coreMaxAddrBits: Int, reservation_station_size: Int, max_lds: Int, max_exs: Int, max_sts: Int,
                max_addr: Int, max_acc_addr: Int, input_w: Int, acc_w: Int, dma_max_bytes: Int,
                config_mvin_rs1_t: ConfigMvinRs1, mvin_rs2_t: MvinRs2, config_mvout_rs2_t: ConfigMvoutRs2, mvout_rs2_t: MvoutRs2,
                config_ex_rs1_t: ConfigExRs1, preload_rs1_t: PreloadRs, preload_rs2_t: PreloadRs,
                compute_rs1_t: ComputeRs, compute_rs2_t: ComputeRs,
                has_training_convs: Boolean, has_max_pool: Boolean, has_first_layer_optimizations: Boolean,
                has_dw_convs: Boolean)
  (implicit p: Parameters) extends Module {
  val large_iterator_bitwidth = 16
  val small_iterator_bitwidth = 16 // 8
  val tiny_iterator_bitwidth = 16 // 4

  val max_block_len = (dma_max_bytes / (block_size * (input_w / 8))) max 1
  val max_block_len_acc = (dma_max_bytes / (block_size * (acc_w / 8))) max 1

  val io = IO(new Bundle {
    val in = Flipped(Decoupled(new GemminiCmd(reservation_station_size)))
    val out = Decoupled(new GemminiCmd(reservation_station_size))
    val ld_completed = Input(UInt(log2Up(reservation_station_size+1).W))
    val st_completed = Input(UInt(log2Up(reservation_station_size+1).W))
    val ex_completed = Input(UInt(log2Up(reservation_station_size+1).W))
    val busy = Output(Bool())
    val request_retire = Output(Bool())
    val running_slot_count = Output(UInt(2.W))
    val deadlock_debug = Output(Vec(10, UInt(64.W)))
  })

  // Create states
  val concurrent_loops = 2
  val requestSeq = RegInit(0.U(32.W))
  val loops = Reg(Vec(concurrent_loops, new LoopConvState(block_size, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, coreMaxAddrBits, max_addr, max_acc_addr)))
  val head_loop_id = RegInit(0.U(log2Up(concurrent_loops).W))
  val tail_loop_id = (~head_loop_id).asUInt // This is the loop that we always try to configure if available
  val head_loop = loops(head_loop_id)
  val tail_loop = loops(tail_loop_id)

  io.running_slot_count := PopCount(loops.map(_.running))
  val loop_configured = loops.map(_.configured).reduce(_ || _)
  val loop_active = loops.map(l => l.configured || l.derive_pending || l.deriving).reduce(_ || _)

  val head_loop_unavailable = head_loop.configured || head_loop.derive_pending || head_loop.deriving
  val loop_being_configured_id = Mux(head_loop_unavailable, tail_loop_id, head_loop_id)
  val loop_being_configured = loops(loop_being_configured_id)

  val derivedParamsPipe = Module(new LoopConvDerivedParamsPipe(
    block_size, large_iterator_bitwidth, small_iterator_bitwidth,
    tiny_iterator_bitwidth, concurrent_loops))
  val derivePending = VecInit(loops.map(_.derive_pending))
  val deriveLoopId = PriorityEncoder(derivePending)
  val deriveLoop = loops(deriveLoopId)
  derivedParamsPipe.io.in.valid := derivePending.asUInt.orR
  derivedParamsPipe.io.in.bits.outer_bounds := deriveLoop.outer_bounds
  derivedParamsPipe.io.in.bits.inner_bounds := deriveLoop.inner_bounds
  derivedParamsPipe.io.in.bits.input_dilated := deriveLoop.input_dilated
  derivedParamsPipe.io.in.bits.downsample := deriveLoop.downsample
  derivedParamsPipe.io.in.bits.trans_input_3120 := deriveLoop.trans_input_3120
  derivedParamsPipe.io.in.bits.trans_weight_0132 := deriveLoop.trans_weight_0132
  derivedParamsPipe.io.in.bits.loop_id := deriveLoopId
  when (derivedParamsPipe.io.in.valid) {
    deriveLoop.derive_pending := false.B
    deriveLoop.deriving := true.B
  }
  when (derivedParamsPipe.io.out.valid) {
    val completed = loops(derivedParamsPipe.io.out.bits.loop_id)
    completed.cached_derived_params := derivedParamsPipe.io.out.bits.params
    completed.deriving := false.B
    completed.configured := true.B
  }

  // Create inner modules
  val latency = 2
  val ld_bias = Module(new LoopConvLdBias(block_size, coreMaxAddrBits, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, max_acc_addr, acc_w, max_block_len_acc, concurrent_loops, latency, config_mvin_rs1_t, mvin_rs2_t))
  val ld_input = Module(new LoopConvLdInput(block_size, coreMaxAddrBits, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, max_addr, input_w, max_block_len, concurrent_loops, latency, config_mvin_rs1_t, mvin_rs2_t))
  val ld_weights = Module(new LoopConvLdWeight(block_size, coreMaxAddrBits, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, max_addr, input_w, max_block_len, concurrent_loops, latency, config_mvin_rs1_t, mvin_rs2_t, has_dw_convs))
  val ex = Module(new LoopConvExecute(block_size, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, max_addr, max_acc_addr, concurrent_loops, latency, config_ex_rs1_t, preload_rs1_t, preload_rs2_t, compute_rs1_t, compute_rs2_t))
  val st = Module(new LoopConvSt(block_size, coreMaxAddrBits, large_iterator_bitwidth, small_iterator_bitwidth, tiny_iterator_bitwidth, max_acc_addr, input_w, concurrent_loops, latency, config_mvout_rs2_t, mvout_rs2_t))

  // Create command queue
  val cmd = Queue(io.in)

  io.busy := cmd.valid || loop_active

  // Create arbiter
  val arb = Module(new Arbiter(new RoCCCommand, 5))
  arb.io.in(0) <> st.io.cmd
  arb.io.in(1) <> ex.io.cmd
  arb.io.in(2) <> ld_bias.io.cmd
  arb.io.in(3) <> ld_weights.io.cmd
  arb.io.in(4) <> ld_input.io.cmd
  val unrolled_cmd = arb.io.out

  // Create reservation station utilization counters
  val ld_utilization = RegInit(0.U(log2Up(max_lds+1).W))
  val st_utilization = RegInit(0.U(log2Up(max_sts+1).W))
  val ex_utilization = RegInit(0.U(log2Up(max_exs+1).W))

  ld_utilization := ld_utilization +& (ld_bias.io.cmd.fire || ld_weights.io.cmd.fire || ld_input.io.cmd.fire) -& io.ld_completed
  st_utilization := st_utilization +& st.io.cmd.fire -& io.st_completed
  ex_utilization := ex_utilization +& ex.io.cmd.fire -& io.ex_completed

  assert(ld_utilization >= io.ld_completed, "ld utilization underflow")
  assert(st_utilization >= io.st_completed, "st utilization underflow")
  assert(ex_utilization >= io.ex_completed, "ex utilization underflow")

  // Wire up unrolled command output
  val is_loop_run_cmd = cmd.bits.cmd.inst.funct === LOOP_CONV_WS
  val is_loop_config_cmd = cmd.bits.cmd.inst.funct >= LOOP_CONV_WS_CONFIG_1 && cmd.bits.cmd.inst.funct <= LOOP_CONV_WS_CONFIG_6
  val is_loop_cmd = is_loop_run_cmd || is_loop_config_cmd

  io.out.bits.cmd := Mux(loop_configured, unrolled_cmd.bits, cmd.bits.cmd)
  io.out.bits.cmd.status := cmd.bits.cmd.status // TODO This is not guaranteed to be the correct fix! We must fix this
  io.out.bits.rob_id := DontCare
  io.out.bits.from_matmul_fsm := Mux(loop_configured, false.B, cmd.bits.from_matmul_fsm)
  io.out.bits.from_conv_fsm := Mux(loop_configured, true.B, cmd.bits.from_conv_fsm)
  // The pass-through branch must observe the same stall as cmd.ready. While a
  // loop is still deriving its parameters, loop_configured is false but the
  // queue is held, so a valid here without a matching dequeue would issue the
  // same command on every cycle of the derivation window.
  io.out.valid := Mux(loop_configured, unrolled_cmd.valid,
    cmd.valid && !is_loop_config_cmd && !is_loop_run_cmd && !loop_active)

  val config_slot_available = !loop_being_configured.configured &&
    !loop_being_configured.derive_pending && !loop_being_configured.deriving
  cmd.ready := Mux(is_loop_cmd, config_slot_available, !loop_active && io.out.ready)
  arb.io.out.ready := io.out.ready

  // Wire up waiting-for-loads signals
  val ex_is_waiting_for_loads = loops(ex.io.loop_id).ex_started && !loops(ex.io.loop_id).ex_completed &&
    !(loops(ex.io.loop_id).ld_input_completed && loops(ex.io.loop_id).ld_weights_completed &&
      loops(ex.io.loop_id).ld_bias_completed)

  ld_bias.io.wait_for_prev_loop := ex_is_waiting_for_loads && ld_bias.io.loop_id =/= ex.io.loop_id
  ld_weights.io.wait_for_prev_loop := ex_is_waiting_for_loads && ld_weights.io.loop_id =/= ex.io.loop_id
  ld_input.io.wait_for_prev_loop := ex_is_waiting_for_loads && ld_input.io.loop_id =/= ex.io.loop_id

  // Wire up overloaded signals
  ld_bias.io.rob_overloaded := ld_utilization >= max_lds.U
  ld_input.io.rob_overloaded := ld_utilization >= max_lds.U
  ld_weights.io.rob_overloaded := ld_utilization >= max_lds.U
  ex.io.rob_overloaded := ex_utilization >= max_exs.U
  st.io.rob_overloaded := st_utilization >= max_sts.U

  // Wire up iterator inputs
  ex.io.lda_completed := (ld_input.io.loop_id =/= ex.io.loop_id) || ld_input.io.idle
  ex.io.ldb_completed := (ld_weights.io.loop_id =/= ex.io.loop_id) || ld_weights.io.idle
  ex.io.ldd_completed := (ld_bias.io.loop_id =/= ex.io.loop_id) || ld_bias.io.idle
  st.io.ex_completed := (ex.io.loop_id =/= st.io.loop_id) || ex.io.idle

  // Create config registers
  when(cmd.valid && is_loop_cmd && config_slot_available) {

    switch (cmd.bits.cmd.inst.funct) {
      is (LOOP_CONV_WS_CONFIG_1) {
        loop_being_configured.outer_bounds.out_channels := cmd.bits.cmd.rs1(63, 48)
        loop_being_configured.outer_bounds.in_channels := cmd.bits.cmd.rs1(47, 32)
        loop_being_configured.outer_bounds.in_row_dim := cmd.bits.cmd.rs1(31, 16)
        loop_being_configured.outer_bounds.batch_size := cmd.bits.cmd.rs1(15, 0)

        loop_being_configured.outer_bounds.padding := cmd.bits.cmd.rs2(63, 56)
        loop_being_configured.outer_bounds.stride := cmd.bits.cmd.rs2(55, 48)
        loop_being_configured.outer_bounds.out_col_dim := cmd.bits.cmd.rs2(47, 32)
        loop_being_configured.outer_bounds.pool_out_row_dim := cmd.bits.cmd.rs2(31, 16)
        loop_being_configured.outer_bounds.out_row_dim := cmd.bits.cmd.rs2(15, 0)
      }

      is (LOOP_CONV_WS_CONFIG_2) {
        loop_being_configured.outer_bounds.kernel_dim := cmd.bits.cmd.rs1(63, 48)
        loop_being_configured.outer_bounds.pool_out_col_dim := cmd.bits.cmd.rs1(47, 32)
        loop_being_configured.outer_bounds.pool_size := (if (!has_max_pool) 1.U else cmd.bits.cmd.rs1(31, 16))
        loop_being_configured.outer_bounds.pool_stride := (if (!has_max_pool) 1.U else cmd.bits.cmd.rs1(15, 8))
        loop_being_configured.outer_bounds.pool_padding := (if (!has_max_pool) 0.U else cmd.bits.cmd.rs1(7, 0))

        loop_being_configured.inner_bounds.batches := cmd.bits.cmd.rs2(63, 48)
        loop_being_configured.inner_bounds.porows := cmd.bits.cmd.rs2(47, 32)
        loop_being_configured.inner_bounds.pocols := cmd.bits.cmd.rs2(31, 16)
        loop_being_configured.inner_bounds.pochs := cmd.bits.cmd.rs2(15, 0)
      }

      is (LOOP_CONV_WS_CONFIG_3) {
        loop_being_configured.inner_bounds.krows := cmd.bits.cmd.rs1(63, 48)
        loop_being_configured.inner_bounds.kcols := cmd.bits.cmd.rs1(47, 32)
        loop_being_configured.inner_bounds.kchs := cmd.bits.cmd.rs1(31, 16)
        loop_being_configured.inner_bounds.lpad := cmd.bits.cmd.rs1(15, 0)

        loop_being_configured.inner_bounds.rpad := cmd.bits.cmd.rs2(63, 48)
        loop_being_configured.inner_bounds.upad := cmd.bits.cmd.rs2(47, 32)
        loop_being_configured.inner_bounds.dpad := cmd.bits.cmd.rs2(31, 24)
        loop_being_configured.inner_bounds.plpad := cmd.bits.cmd.rs2(23, 16)
        loop_being_configured.outer_bounds.in_col_dim := cmd.bits.cmd.rs2(15, 0)
      }

      is (LOOP_CONV_WS_CONFIG_4) {
        loop_being_configured.inner_bounds.orows := cmd.bits.cmd.rs1(63, 48)
        loop_being_configured.inner_bounds.prad := cmd.bits.cmd.rs1(47, 32)
        loop_being_configured.inner_bounds.pupad := cmd.bits.cmd.rs1(31, 21)
        loop_being_configured.inner_bounds.pdpad := cmd.bits.cmd.rs1(20, 10)
        loop_being_configured.outer_bounds.kernel_dilation := cmd.bits.cmd.rs1(9, 0)

        loop_being_configured.inner_bounds.ocols := cmd.bits.cmd.rs2(15, 0)
        loop_being_configured.outer_bounds.in_stride := cmd.bits.cmd.rs2(63, 48)
        loop_being_configured.outer_bounds.weight_stride := cmd.bits.cmd.rs2(47, 32)
        loop_being_configured.outer_bounds.out_stride := cmd.bits.cmd.rs2(31, 16)
      }

      is (LOOP_CONV_WS_CONFIG_5) {
        loop_being_configured.weights_dram_addr := cmd.bits.cmd.rs1

        loop_being_configured.output_dram_addr := cmd.bits.cmd.rs2
      }

      is (LOOP_CONV_WS_CONFIG_6) {
        loop_being_configured.bias_dram_addr := cmd.bits.cmd.rs1

        loop_being_configured.input_dram_addr := cmd.bits.cmd.rs2
      }

      is (LOOP_CONV_WS) {
        when (cmd.fire) {
          requestSeq := requestSeq + 1.U
          loop_being_configured.request_seq := requestSeq
        }
        loop_being_configured.no_bias := cmd.bits.cmd.rs1(0)

        // TODO we added a default value for max_pixels_per_row just to maintain backwards compatibility. we should deprecate and remove it later
        val config_max_pixels_per_row = cmd.bits.cmd.rs1(15, 8)
        loop_being_configured.max_pixels_per_row := Mux(
          !has_first_layer_optimizations.B || config_max_pixels_per_row === 0.U,
          1.U, config_max_pixels_per_row)

        loop_being_configured.a_ex_spad_id := cmd.bits.cmd.rs1(19, 18)
        loop_being_configured.b_ex_spad_id := cmd.bits.cmd.rs1(17, 16) 
        
        loop_being_configured.wrot180 := has_training_convs.B && cmd.bits.cmd.rs1(1)
        loop_being_configured.input_dilated := has_training_convs.B && cmd.bits.cmd.rs2(2)
        loop_being_configured.trans_output_1203 := has_training_convs.B && cmd.bits.cmd.rs1(2)
        loop_being_configured.trans_weight_1203 := has_training_convs.B && cmd.bits.cmd.rs1(3)
        loop_being_configured.trans_weight_0132 := has_training_convs.B && cmd.bits.cmd.rs1(4)
        loop_being_configured.trans_input_3120 := has_training_convs.B && cmd.bits.cmd.rs1(5)
        // Keep the request shape compatible, but make the disabled feature a
        // true elaboration-time constant instead of an uninitialised state bit.
        loop_being_configured.dw := (if (has_dw_convs) cmd.bits.cmd.rs1(6) else false.B)

        loop_being_configured.no_pool := !has_max_pool.B || cmd.bits.cmd.rs2(0)
        loop_being_configured.activation := cmd.bits.cmd.rs2(Activation.bitwidth + 2, 3)

        loop_being_configured.downsample := cmd.bits.cmd.rs2(1)

        loop_being_configured.derive_pending := true.B

        // assert(!loop_being_configured.input_dilated || loop_being_configured.outer_bounds.stride === 1.U)
        // assert(!loop_being_configured.downsample || (loop_being_configured.outer_bounds.kernel_dim === 1.U && loop_being_configured.outer_bounds.stride === 2.U)) // TODO add the rest of the conditions that must be true for "downsample" to be enabled
      }
    }
  }

  // Wire up request signals
  val ld_bias_addr_start = RegInit(0.U(log2Up(max_acc_addr).W))
  val ex_c_addr_start = RegInit(0.U(log2Up(max_acc_addr).W))
  val st_addr_start = RegInit(0.U(log2Up(max_acc_addr).W))

  val loop_requesting_ld_bias_id = Mux(head_loop.ld_bias_started, tail_loop_id, head_loop_id)
  val loop_requesting_ld_bias = loops(loop_requesting_ld_bias_id)
  ld_bias.io.req.bits.outer_bounds := loop_requesting_ld_bias.outer_bounds
  ld_bias.io.req.bits.inner_bounds := loop_requesting_ld_bias.inner_bounds
  ld_bias.io.req.bits.derived_params := loop_requesting_ld_bias.cached_derived_params
  ld_bias.io.req.bits.addr_start := ld_bias_addr_start
  ld_bias.io.req.bits.dram_addr := loop_requesting_ld_bias.bias_dram_addr
  ld_bias.io.req.bits.no_bias := loop_requesting_ld_bias.no_bias
  ld_bias.io.req.bits.loop_id := loop_requesting_ld_bias_id

  ld_bias.io.req.valid := !loop_requesting_ld_bias.ld_bias_started && loop_requesting_ld_bias.configured

  when (ld_bias.io.req.fire) {
    loop_requesting_ld_bias.running := true.B
    loop_requesting_ld_bias.ld_bias_started := true.B

    // when (loop_requesting_ld_bias.bias_dram_addr =/= 0.U) {
    when (loop_requesting_ld_bias.output_dram_addr =/= 0.U) {
      ld_bias_addr_start := floorAdd(ld_bias_addr_start, (max_acc_addr / concurrent_loops).U, max_acc_addr.U)
    }
  }

  val loop_requesting_ld_input_id = Mux(head_loop.ld_input_started, tail_loop_id, head_loop_id)
  val loop_requesting_ld_input = loops(loop_requesting_ld_input_id)
  ld_input.io.req.bits.outer_bounds := loop_requesting_ld_input.outer_bounds
  ld_input.io.req.bits.inner_bounds := loop_requesting_ld_input.inner_bounds
  ld_input.io.req.bits.derived_params := loop_requesting_ld_input.cached_derived_params
  ld_input.io.req.bits.addr_start := Mux(loop_requesting_ld_input.a_ex_spad_id === 0.U, loop_requesting_ld_input.a_addr_start, (loop_requesting_ld_input.a_ex_spad_id - 1.U) * (max_addr / concurrent_loops).U)
  ld_input.io.req.bits.dram_addr := loop_requesting_ld_input.input_dram_addr
  ld_input.io.req.bits.downsample := loop_requesting_ld_input.downsample
  ld_input.io.req.bits.max_pixels_per_row := loop_requesting_ld_input.max_pixels_per_row
  ld_input.io.req.bits.input_dilated := loop_requesting_ld_input.input_dilated
  ld_input.io.req.bits.trans_input_3120 := loop_requesting_ld_input.trans_input_3120
  ld_input.io.req.bits.loop_id := loop_requesting_ld_input_id

  ld_input.io.req.valid := !loop_requesting_ld_input.ld_input_started && loop_requesting_ld_input.configured

  when (ld_input.io.req.fire) {
    loop_requesting_ld_input.running := true.B
    loop_requesting_ld_input.ld_input_started := true.B
  }

  val loop_requesting_ld_weights_id = Mux(head_loop.ld_weights_started, tail_loop_id, head_loop_id)
  val loop_requesting_ld_weights = loops(loop_requesting_ld_weights_id)
  ld_weights.io.req.bits.outer_bounds := loop_requesting_ld_weights.outer_bounds
  ld_weights.io.req.bits.inner_bounds := loop_requesting_ld_weights.inner_bounds
  ld_weights.io.req.bits.derived_params := loop_requesting_ld_weights.cached_derived_params
  ld_weights.io.req.bits.addr_end :=  Mux(loop_requesting_ld_weights.b_ex_spad_id === 0.U, loop_requesting_ld_weights.b_addr_end, (loop_requesting_ld_weights.b_ex_spad_id) * (max_addr / concurrent_loops).U)
  ld_weights.io.req.bits.dram_addr := loop_requesting_ld_weights.weights_dram_addr
  ld_weights.io.req.bits.trans_weight_1203 := loop_requesting_ld_weights.trans_weight_1203
  ld_weights.io.req.bits.trans_weight_0132 := loop_requesting_ld_weights.trans_weight_0132
  ld_weights.io.req.bits.dw := loop_requesting_ld_weights.dw
  ld_weights.io.req.bits.loop_id := loop_requesting_ld_weights_id

  ld_weights.io.req.valid := !loop_requesting_ld_weights.ld_weights_started && loop_requesting_ld_weights.configured

  when (ld_weights.io.req.fire) {
    loop_requesting_ld_weights.running := true.B
    loop_requesting_ld_weights.ld_weights_started := true.B
  }

  val loop_requesting_ex_id = Mux(head_loop.ex_started, tail_loop_id, head_loop_id)
  val loop_requesting_ex = loops(loop_requesting_ex_id)
  ex.io.req.bits.outer_bounds := loop_requesting_ex.outer_bounds
  ex.io.req.bits.inner_bounds := loop_requesting_ex.inner_bounds
  ex.io.req.bits.derived_params := loop_requesting_ex.cached_derived_params
  ex.io.req.bits.a_addr_start := Mux(loop_requesting_ex.a_ex_spad_id === 0.U, loop_requesting_ex.a_addr_start, (loop_requesting_ex.a_ex_spad_id - 1.U) * (max_addr / concurrent_loops).U)
  ex.io.req.bits.b_addr_end := Mux(loop_requesting_ex.b_ex_spad_id === 0.U, loop_requesting_ex.b_addr_end, (loop_requesting_ex.b_ex_spad_id) * (max_addr / concurrent_loops).U)
  ex.io.req.bits.c_addr_start := ex_c_addr_start
  ex.io.req.bits.wrot180 := loop_requesting_ex.wrot180
  ex.io.req.bits.downsample := loop_requesting_ex.downsample
  ex.io.req.bits.max_pixels_per_row := loop_requesting_ex.max_pixels_per_row
  ex.io.req.bits.input_dilated := loop_requesting_ex.input_dilated
  ex.io.req.bits.trans_weight_0132 := loop_requesting_ex.trans_weight_0132
  ex.io.req.bits.trans_input_3120 := loop_requesting_ex.trans_input_3120
  ex.io.req.bits.loop_id := loop_requesting_ex_id

  ex.io.req.valid := !loop_requesting_ex.ex_started && loop_requesting_ex.ld_bias_started &&
    loop_requesting_ex.ld_input_started && loop_requesting_ex.ld_weights_started && loop_requesting_ex.configured

  when (ex.io.req.fire) {
    loop_requesting_ex.running := true.B
    loop_requesting_ex.ex_started := true.B

    when (loop_requesting_ex.output_dram_addr =/= 0.U) {
      ex_c_addr_start := floorAdd(ex_c_addr_start, (max_acc_addr / concurrent_loops).U, max_acc_addr.U)
    }
  }

  val loop_requesting_st_id = Mux(head_loop.st_started, tail_loop_id, head_loop_id)
  val loop_requesting_st = loops(loop_requesting_st_id)
  st.io.req.bits.outer_bounds := loop_requesting_st.outer_bounds
  st.io.req.bits.inner_bounds := loop_requesting_st.inner_bounds
  st.io.req.bits.derived_params := loop_requesting_st.cached_derived_params
  st.io.req.bits.addr_start := st_addr_start
  st.io.req.bits.dram_addr := loop_requesting_st.output_dram_addr
  st.io.req.bits.no_pool := loop_requesting_st.no_pool
  st.io.req.bits.activation := loop_requesting_st.activation
  st.io.req.bits.trans_output_1203 := loop_requesting_st.trans_output_1203
  st.io.req.bits.loop_id := loop_requesting_st_id

  st.io.req.valid := !loop_requesting_st.st_started && loop_requesting_st.ex_started && loop_requesting_st.configured

  when (st.io.req.fire) {
    loop_requesting_st.running := true.B
    loop_requesting_st.st_started := true.B

    when (loop_requesting_st.output_dram_addr =/= 0.U) {
      st_addr_start := floorAdd(st_addr_start, (max_acc_addr / concurrent_loops).U, max_acc_addr.U)
    }
  }

  // Handle completed signals
  when (ld_bias.io.idle && loops(ld_bias.io.loop_id).running && loops(ld_bias.io.loop_id).ld_bias_started) {
    loops(ld_bias.io.loop_id).ld_bias_completed := true.B
  }

  when (ld_input.io.idle && loops(ld_input.io.loop_id).running && loops(ld_input.io.loop_id).ld_input_started) {
    loops(ld_input.io.loop_id).ld_input_completed := true.B
  }

  when (ld_weights.io.idle && loops(ld_weights.io.loop_id).running && loops(ld_weights.io.loop_id).ld_weights_started) {
    loops(ld_weights.io.loop_id).ld_weights_completed := true.B
  }

  when (ex.io.idle && loops(ex.io.loop_id).running && loops(ex.io.loop_id).ex_started) {
    loops(ex.io.loop_id).ex_completed := true.B
  }

  when (st.io.idle && loops(st.io.loop_id).running && loops(st.io.loop_id).st_started) {
    loops(st.io.loop_id).st_completed := true.B
  }

  val requestRetire = head_loop.running && head_loop.all_completed()
  io.request_retire := requestRetire
  when (requestRetire) {
    head_loop.reset()
    head_loop_id := ~head_loop_id
  }

  /** IPOAT：LoopConv 四页死锁快照
    * I（Input 输入）：两个 slot 的序号/started/completed、五个子引擎握手、RS utilization 和完成计数。
    * P（Process 处理）：计算阻塞原因位与距上次进展周期数；逻辑仅扇出观察，绝不回接 ready/valid。
    * O（Output 输出）：页0全局状态、页1/2 slot0/1、页3子引擎及完成事件。
    * A（Author 作者）：王志瑞
    * T（Time 时间）：2026-09-17
    */
  val debugProgress = cmd.fire || io.out.fire || requestRetire ||
    io.ld_completed.orR || io.ex_completed.orR || io.st_completed.orR ||
    ld_bias.io.req.fire || ld_input.io.req.fire || ld_weights.io.req.fire ||
    ex.io.req.fire || st.io.req.fire
  val debugCyclesSinceProgress = RegInit(0.U(32.W))
  when (debugProgress) {
    debugCyclesSinceProgress := 0.U
  }.elsewhen (io.busy && debugCyclesSinceProgress =/= "hffffffff".U) {
    debugCyclesSinceProgress := debugCyclesSinceProgress + 1.U
  }

  def startedMask(l: LoopConvState): UInt = Cat(l.st_started, l.ex_started,
    l.ld_weights_started, l.ld_input_started, l.ld_bias_started)
  def completedMask(l: LoopConvState): UInt = Cat(l.st_completed, l.ex_completed,
    l.ld_weights_completed, l.ld_input_completed, l.ld_bias_completed)
  def slotBlockMask(id: Int): UInt = Cat(
    loops(id).st_started && !loops(id).st_completed && !st.io.idle,
    loops(id).ex_started && !loops(id).ex_completed && !ex.io.idle,
    st.io.rob_overloaded,
    ex.io.rob_overloaded,
    ld_weights.io.wait_for_prev_loop || ld_input.io.wait_for_prev_loop || ld_bias.io.wait_for_prev_loop,
    ld_weights.io.rob_overloaded || ld_input.io.rob_overloaded || ld_bias.io.rob_overloaded,
    loops(id).configured && !loops(id).running,
    !loops(id).configured)

  io.deadlock_debug(0) := Cat(debugCyclesSinceProgress, requestSeq(7, 0),
    io.out.fire,
    arb.io.chosen, io.running_slot_count, tail_loop_id, head_loop_id,
    st_utilization.pad(5), ex_utilization.pad(6), ld_utilization.pad(5))
  for (i <- 0 until concurrent_loops) {
    io.deadlock_debug(i + 1) := Cat(0.U(12.W), slotBlockMask(i),
      completedMask(loops(i)), startedMask(loops(i)), loops(i).running,
      loops(i).configured, loops(i).request_seq)
  }
  io.deadlock_debug(3) := Cat(0.U(27.W),
    st.io.loop_id, ex.io.loop_id, ld_weights.io.loop_id, ld_input.io.loop_id, ld_bias.io.loop_id,
    st.io.idle, ex.io.idle, ld_weights.io.idle, ld_input.io.idle, ld_bias.io.idle,
    st.io.req.valid, st.io.req.ready, ex.io.req.valid, ex.io.req.ready,
    ld_weights.io.req.valid, ld_weights.io.req.ready,
    ld_input.io.req.valid, ld_input.io.req.ready,
    ld_bias.io.req.valid, ld_bias.io.req.ready,
    io.st_completed.pad(4), io.ex_completed.pad(4), io.ld_completed.pad(4))
  /** IPOAT：五个子生成器详细页
    * I（Input 输入）：Bias/Input/Weight/Execute/Store 各自的状态、迭代器和阻塞握手。
    * P（Process 处理）：按固定顺序透传子模块的 64-bit 被动观测页。
    * O（Output 输出）：deadlock_debug[4..8]，用于从未退休 slot 追到具体生成器等待条件。
    * A（Author 作者）：王志瑞
    * T（Time 时间）：2026-09-19
    */
  io.deadlock_debug(4) := ld_bias.io.deadlock_debug
  io.deadlock_debug(5) := ld_input.io.deadlock_debug
  io.deadlock_debug(6) := ld_weights.io.deadlock_debug
  io.deadlock_debug(7) := ex.io.deadlock_debug
  io.deadlock_debug(8) := st.io.deadlock_debug
  io.deadlock_debug(9) := Cat(0.U(54.W),
    derivedParamsPipe.io.in.valid, derivedParamsPipe.io.out.valid,
    loops(1).deriving, loops(1).derive_pending, loops(1).configured, loops(1).running,
    loops(0).deriving, loops(0).derive_pending, loops(0).configured, loops(0).running)

  // Resets
  when (reset.asBool) {
    loops.zipWithIndex.foreach { case (l, i) =>
      l.reset()
      l.a_addr_start := (i * (max_addr / concurrent_loops)).U
      l.b_addr_end := ((i+1) * (max_addr / concurrent_loops)).U
    }
  }
}

object LoopConv {
  def apply(in: DecoupledIO[GemminiCmd], ld_completed: UInt, st_completed: UInt, ex_completed: UInt,
            block_size: Int, coreMaxAddrBits: Int, rob_size: Int, max_lds: Int, max_exs: Int, max_sts: Int,
            max_addr: Int, max_acc_addr: Int, input_w: Int, acc_w: Int, dma_max_bytes: Int,
            config_mvin_rs1_t: ConfigMvinRs1, mvin_rs2_t: MvinRs2, config_mvout_rs2_t: ConfigMvoutRs2,
            mvout_rs2_t: MvoutRs2, config_ex_rs1_t: ConfigExRs1, preload_rs1_t: PreloadRs, preload_rs2_t: PreloadRs,
            compute_rs1_t: ComputeRs, compute_rs2_t: ComputeRs, has_training_convs: Boolean, has_max_pool: Boolean,
            has_first_layer_optimizations: Boolean, has_dw_convs: Boolean)
           (implicit p: Parameters): (DecoupledIO[GemminiCmd], Bool, Bool, UInt, Vec[UInt]) = {

    val mod = Module(new LoopConv(block_size, coreMaxAddrBits, rob_size, max_lds, max_exs, max_sts,
      max_addr, max_acc_addr, input_w, acc_w, dma_max_bytes,
      config_mvin_rs1_t, mvin_rs2_t, config_mvout_rs2_t, mvout_rs2_t, config_ex_rs1_t, preload_rs1_t, preload_rs2_t,
      compute_rs1_t, compute_rs2_t, has_training_convs, has_max_pool, has_first_layer_optimizations, has_dw_convs))

    mod.io.in <> in
    mod.io.ld_completed := ld_completed
    mod.io.st_completed := st_completed
    mod.io.ex_completed := ex_completed
    (mod.io.out, mod.io.busy, mod.io.request_retire, mod.io.running_slot_count, mod.io.deadlock_debug)
  }

  def castDramOffset(dram_offset: UInt): UInt = {
    // Cast dram offsets to 32 bits max
    dram_offset & "hFFFFFFFF".U
  }
}
