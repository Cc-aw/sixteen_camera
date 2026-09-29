
package gemmini

import chisel3.{Bool, _}
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy.{LazyModule, LazyModuleImp, BufferParams}
import freechips.rocketchip.rocket._
import freechips.rocketchip.tile._
import freechips.rocketchip.tilelink._
import Util._

class ScratchpadMemReadRequest[U <: Data](local_addr_t: LocalAddr, scale_t_bits: Int)(implicit p: Parameters) extends CoreBundle {
  val vaddr = UInt(coreMaxAddrBits.W)
  val laddr = local_addr_t.cloneType

  val cols = UInt(16.W) // TODO don't use a magic number for the width here
  val repeats = UInt(16.W) // TODO don't use a magic number for the width here
  val scale = UInt(scale_t_bits.W)
  val has_acc_bitwidth = Bool()
  val all_zeros = Bool()
  val block_stride = UInt(16.W) // TODO magic numbers
  val pixel_repeats = UInt(8.W) // TODO magic numbers
  val cmd_id = UInt(8.W) // TODO don't use a magic number here
  val status = new MStatus

}

class ScratchpadMemWriteRequest(local_addr_t: LocalAddr, acc_t_bits: Int, scale_t_bits: Int)
                              (implicit p: Parameters) extends CoreBundle {
  val vaddr = UInt(coreMaxAddrBits.W)
  val laddr = local_addr_t.cloneType

  val dest = UInt(1.W)

  val acc_act = UInt(Activation.bitwidth.W) // TODO don't use a magic number for the width here
  val acc_scale = UInt(scale_t_bits.W)
  val acc_igelu_qb = UInt(acc_t_bits.W)
  val acc_igelu_qc = UInt(acc_t_bits.W)
  val acc_iexp_qln2 = UInt(acc_t_bits.W)
  val acc_iexp_qln2_inv = UInt(acc_t_bits.W)
  val acc_norm_stats_id = UInt(8.W) // TODO magic number

  val len = UInt(16.W) // TODO don't use a magic number for the width here
  val block = UInt(8.W) // TODO don't use a magic number for the width here

  val cmd_id = UInt(8.W) // TODO don't use a magic number here
  val status = new MStatus

  // Pooling variables
  val pool_en = Bool()
  val store_en = Bool()

}

class ScratchpadMemWriteResponse extends Bundle {
  val cmd_id = UInt(8.W) // TODO don't use a magic number here
}

class ScratchpadMemReadResponse extends Bundle {
  val bytesRead = UInt(16.W) // TODO magic number here
  val cmd_id = UInt(8.W) // TODO don't use a magic number here
}

class ScratchpadReadMemIO[U <: Data](local_addr_t: LocalAddr, scale_t_bits: Int)(implicit p: Parameters) extends CoreBundle {
  val req = Decoupled(new ScratchpadMemReadRequest(local_addr_t, scale_t_bits))
  val resp = Flipped(Valid(new ScratchpadMemReadResponse))
}

class ScratchpadWriteMemIO(local_addr_t: LocalAddr, acc_t_bits: Int, scale_t_bits: Int)
                         (implicit p: Parameters) extends CoreBundle {
  val req = Decoupled(new ScratchpadMemWriteRequest(local_addr_t, acc_t_bits, scale_t_bits))
  val resp = Flipped(Valid(new ScratchpadMemWriteResponse))
}

class ScratchpadReadReq(val n: Int) extends Bundle {
  val addr = UInt(log2Ceil(n).W)
  val fromDMA = Bool()
}

class ScratchpadReadResp(val w: Int) extends Bundle {
  val data = UInt(w.W)
  val fromDMA = Bool()
}

class ScratchpadReadIO(val n: Int, val w: Int) extends Bundle {
  val req = Decoupled(new ScratchpadReadReq(n))
  val resp = Flipped(Decoupled(new ScratchpadReadResp(w)))
}

class ScratchpadWriteIO(val n: Int, val w: Int, val mask_len: Int) extends Bundle {
  val valid = Output(Bool())
  val ready = Input(Bool())
  val addr = Output(UInt(log2Ceil(n).W))
  val mask = Output(Vec(mask_len, Bool()))
  val data = Output(UInt(w.W))
  def fire = valid && ready
}

class ScratchpadBank(n: Int, w: Int, aligned_to: Int, single_ported: Boolean, use_shared_ext_mem: Boolean, is_dummy: Boolean) extends Module {
  // This is essentially a pipelined SRAM with the ability to stall pipeline stages

  require(w % aligned_to == 0 || w < aligned_to)
  val mask_len = (w / (aligned_to * 8)) max 1 // How many mask bits are there?
  val mask_elem = UInt((w min (aligned_to * 8)).W) // What datatype does each mask bit correspond to?

  val io = IO(new Bundle {
    val read = Flipped(new ScratchpadReadIO(n, w))
    val write = Flipped(new ScratchpadWriteIO(n, w, mask_len))
    val ext_mem = if (use_shared_ext_mem) Some(new ExtMemIO) else None
  })

  val ren = io.read.req.fire
  val fromDMA = io.read.req.bits.fromDMA

  // Make a queue which buffers the result of an SRAM read if it can't immediately be consumed
  val q = Module(new Queue(new ScratchpadReadResp(w), 1, true, true))
  val q_will_be_empty = (q.io.count +& q.io.enq.fire) - q.io.deq.fire === 0.U
  // When the scratchpad is single-ported, the writes take precedence
  val singleport_busy_with_write = single_ported.B && io.write.fire

  if (is_dummy) {
    q.io.enq.valid := RegNext(ren)
    q.io.enq.bits.data := 0.U
    q.io.enq.bits.fromDMA := RegNext(fromDMA)
    io.read.req.ready := q_will_be_empty && !singleport_busy_with_write
  } else if (use_shared_ext_mem) { // use ready-valid interface
    val ext_mem = io.ext_mem.get

    /* READ */
    ext_mem.read_req.valid := q_will_be_empty && io.read.req.valid
    ext_mem.read_req.bits := io.read.req.bits.addr
    io.read.req.ready := q_will_be_empty && ext_mem.read_req.ready

    // TODO (richard): the number of entries here should be configurable
    val dma_q = Module(new Queue(Bool(), 4, false, true))
    dma_q.io.enq.valid := ren
    dma_q.io.enq.bits := fromDMA
    dma_q.io.deq.ready := q.io.enq.fire
    assert(dma_q.io.enq.fire === ren, "DMA queue does not have enough entries") // TODO (richard): do backpressure
    assert(dma_q.io.deq.fire === q.io.enq.fire, "fromDMA should be dequeued only when read resp comes back")

    q.io.enq.valid := ext_mem.read_resp.valid
    q.io.enq.bits.data := ext_mem.read_resp.bits
    q.io.enq.bits.fromDMA := dma_q.io.deq.bits
    ext_mem.read_resp.ready := q.io.enq.ready

    /* WRITE */
    val wq = Module(new Queue(ext_mem.write_req.bits.cloneType, 4, pipe=true, flow=true))
    ext_mem.write_req <> wq.io.deq

    wq.io.enq.valid := io.write.valid
    io.write.ready := wq.io.enq.ready
    wq.io.enq.bits.addr := io.write.addr
    wq.io.enq.bits.data := io.write.data
    if (aligned_to >= w) {
      wq.io.enq.bits.mask := VecInit((~(0.U(mask_len.W))).asBools).asUInt
    } else {
      wq.io.enq.bits.mask := io.write.mask.asUInt
    }
    // assert(wq.io.enq.ready || (!io.write.en), "TODO (richard): fix this if triggered")
  } else { // use valid only interface
    val mem = SyncReadMem(n, Vec(mask_len, mask_elem))

    val raddr = io.read.req.bits.addr
    val rdata = if (single_ported) {
      assert(!(ren && io.write.fire))
      mem.read(raddr, ren && !io.write.fire).asUInt
    } else {
      mem.read(raddr, ren).asUInt
    }
    q.io.enq.valid := RegNext(ren)
    q.io.enq.bits.data := rdata
    q.io.enq.bits.fromDMA := RegNext(fromDMA)

    io.read.req.ready := q_will_be_empty && !singleport_busy_with_write

    io.write.ready := true.B
    when(io.write.fire) {
      if (aligned_to >= w)
        mem.write(io.write.addr, io.write.data.asTypeOf(Vec(mask_len, mask_elem)), VecInit((~(0.U(mask_len.W))).asBools))
      else
        mem.write(io.write.addr, io.write.data.asTypeOf(Vec(mask_len, mask_elem)), io.write.mask)
    }
  }

  io.read.resp <> q.io.deq
}


class Scratchpad[T <: Data, U <: Data, V <: Data](config: GemminiArrayConfig[T, U, V])
    (implicit p: Parameters, ev: Arithmetic[T]) extends LazyModule {

  import config._
  import ev._

  val maxBytes = dma_maxbytes
  val dataBits = dma_buswidth

  val block_rows = meshRows * tileRows
  val block_cols = meshColumns * tileColumns
  val spad_w = inputType.getWidth *  block_cols
  val acc_w = accType.getWidth * block_cols

  val id_node = TLIdentityNode()
  val xbar_node = TLXbar()

  val reader = LazyModule(new StreamReader(config, max_in_flight_mem_reqs, dataBits, maxBytes, spad_w, acc_w, aligned_to,
    sp_banks * sp_bank_entries, acc_banks * acc_bank_entries, block_rows, use_tlb_register_filter,
    use_firesim_simulation_counters))
  val writer = LazyModule(new StreamWriter(max_in_flight_mem_reqs, dataBits, maxBytes,
    if (acc_read_full_width) acc_w else spad_w, aligned_to, inputType, block_cols, use_tlb_register_filter,
    use_firesim_simulation_counters, use_tlb))
  val spad_writer = Option.when(config.use_tl_ext_mem)(LazyModule(new StreamWriter(max_in_flight_mem_reqs, dataBits, maxBytes,
    if (acc_read_full_width) acc_w else spad_w, aligned_to, inputType, block_cols, use_tlb_register_filter,
    use_firesim_simulation_counters, use_tlb)))

  // TODO make a cross-bar vs two separate ports a config option
  // id_node :=* reader.node
  // id_node :=* writer.node

  xbar_node := TLBuffer() := reader.node // TODO
  xbar_node := TLBuffer() := writer.node
  val boundary0 = LazyModule(new TLBuffer(BufferParams(2, flow = false, pipe = false)))
  val boundary1 = LazyModule(new TLBuffer(BufferParams(2, flow = false, pipe = false)))
  val boundary2 = LazyModule(new TLBuffer(BufferParams(2, flow = false, pipe = false)))
  id_node := TLWidthWidget(config.dma_buswidth/8) := boundary2.node := boundary1.node := boundary0.node := xbar_node

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) with HasCoreParameters {
    // The board config distributes the three large memory subsystems across
    // SLRs. Emit the placement intent from Scala; no XDC clock/timing exception
    // is added. Preserve this hierarchy so the property has a stable target.
    config.fpgaScratchpadSlr.foreach { slr =>
      VivadoAttributes(this.toTarget,
        s"""keep_hierarchy = "yes", USER_SLR_ASSIGNMENT = "SLR$slr"""")
    }
    val exPendingSignals = scala.collection.mutable.ArrayBuffer.empty[Bool]
    val io = IO(new Bundle {
      val writeback_idle = Output(Bool())
      // DMA ports
      val dma = new Bundle {
        val read = Flipped(new ScratchpadReadMemIO(local_addr_t, mvin_scale_t_bits))
        val write = Flipped(new ScratchpadWriteMemIO(local_addr_t, accType.getWidth, acc_scale_t_bits))
      }

      // SRAM ports
      val srams = new Bundle {
        val read = Flipped(Vec(sp_banks, new ScratchpadReadIO(sp_bank_entries, spad_w)))
        val write = Flipped(Vec(sp_banks, new ScratchpadWriteIO(sp_bank_entries, spad_w, (spad_w / (aligned_to * 8)) max 1)))
      }

      // Accumulator ports
      val acc = new Bundle {
        val read_req = Flipped(Vec(acc_banks, Decoupled(new AccumulatorReadReq(
          acc_bank_entries, accType, acc_scale_t.asInstanceOf[V]
        ))))
        val read_resp = Vec(acc_banks, Decoupled(new AccumulatorScaleResp(
          Vec(meshColumns, Vec(tileColumns, inputType)),
          Vec(meshColumns, Vec(tileColumns, accType))
        )))
        val write = Flipped(Vec(acc_banks, Decoupled(new AccumulatorWriteReq(
          acc_bank_entries, Vec(meshColumns, Vec(tileColumns, accType))
        ))))
      }

      val ext_mem = if (use_shared_ext_mem) {
        Some(new ExtSpadMemIO(sp_banks, acc_banks, acc_sub_banks))
      } else {
        None
      }

      // TLB ports
      val tlb = Vec(2 + spad_writer.map(_ => 1).getOrElse(0), new FrontendTLBIO)

      // Misc. ports
      val busy = Output(Bool())
      val deadlock_debug = Output(Vec(21, UInt(64.W)))
      val flush = Input(Bool())
      val silu_lut_write = Flipped(Valid(new SiluLutWrite))
      val silu_lut_ready = Output(Bool())
      val counter = new CounterEventIO()
    })

    val debugSpadHazards = WireInit(0.U(16.W))
    val debugAccHazards = WireInit(0.U(16.W))
    val write_dispatch_q = Queue(io.dma.write.req)
    // Write norm/scale queues are necessary to maintain in-order requests to accumulator norm/scale units
    // Writes from main SPAD just flow directly between scale_q and issue_q, while writes
    // From acc are ordered
    val write_norm_q = Module(new Queue(new ScratchpadMemWriteRequest(local_addr_t, accType.getWidth, acc_scale_t_bits), spad_read_delay+2))
    val write_scale_q = Module(new Queue(new ScratchpadMemWriteRequest(local_addr_t, accType.getWidth, acc_scale_t_bits), spad_read_delay+2))
    val write_issue_q = Module(new Queue(new ScratchpadMemWriteRequest(local_addr_t, accType.getWidth, acc_scale_t_bits), spad_read_delay+1, pipe=true))
    val read_issue_q = Module(new Queue(new ScratchpadMemReadRequest(local_addr_t, mvin_scale_t_bits), spad_read_delay+1, pipe=true)) // TODO can't this just be a normal queue?

    write_dispatch_q.ready := false.B

    write_norm_q.io.enq.valid := false.B
    write_norm_q.io.enq.bits := write_dispatch_q.bits
    write_norm_q.io.deq.ready := false.B

    write_scale_q.io.enq.valid := false.B
    write_scale_q.io.enq.bits  := write_norm_q.io.deq.bits
    write_scale_q.io.deq.ready := false.B

    write_issue_q.io.enq.valid := false.B
    write_issue_q.io.enq.bits := write_scale_q.io.deq.bits

    // Garbage can immediately fire from dispatch_q -> norm_q
    when (write_dispatch_q.bits.laddr.is_garbage()) {
      write_norm_q.io.enq <> write_dispatch_q
    }

    // Non-acc or garbage can immediately fire between norm_q and scale_q
    when (write_norm_q.io.deq.bits.laddr.is_garbage() || !write_norm_q.io.deq.bits.laddr.is_acc_addr) {
      write_scale_q.io.enq <> write_norm_q.io.deq
    }

    // Non-acc or garbage can immediately fire between scale_q and issue_q
    when (write_scale_q.io.deq.bits.laddr.is_garbage() || !write_scale_q.io.deq.bits.laddr.is_acc_addr) {
      write_issue_q.io.enq <> write_scale_q.io.deq
    }

    val writeData = Wire(Valid(UInt((spad_w max acc_w).W)))
    writeData.valid := write_issue_q.io.deq.bits.laddr.is_garbage()
    writeData.bits := DontCare
    val fullAccWriteData = Wire(UInt(acc_w.W))
    fullAccWriteData := DontCare
    val writeData_is_full_width = !write_issue_q.io.deq.bits.laddr.is_garbage() &&
      write_issue_q.io.deq.bits.laddr.is_acc_addr && write_issue_q.io.deq.bits.laddr.read_full_acc_row
    val writeData_is_all_zeros = write_issue_q.io.deq.bits.laddr.is_garbage()

    writer.module.io.req.valid := write_issue_q.io.deq.valid && writeData.valid && !write_issue_q.io.deq.bits.dest.asBool
    // write_issue_q.io.deq.ready := writer.module.io.req.ready && writeData.valid
    writer.module.io.req.bits.vaddr := write_issue_q.io.deq.bits.vaddr
    writer.module.io.req.bits.physical := write_issue_q.io.deq.bits.dest
    writer.module.io.req.bits.len := Mux(writeData_is_full_width,
      write_issue_q.io.deq.bits.len * (accType.getWidth / 8).U,
      write_issue_q.io.deq.bits.len * (inputType.getWidth / 8).U)
    writer.module.io.req.bits.data := MuxCase(writeData.bits, Seq(
       writeData_is_all_zeros -> 0.U,
       writeData_is_full_width -> fullAccWriteData
    ))
    writer.module.io.req.bits.block := write_issue_q.io.deq.bits.block
    writer.module.io.req.bits.status := write_issue_q.io.deq.bits.status
    writer.module.io.req.bits.pool_en := write_issue_q.io.deq.bits.pool_en
    writer.module.io.req.bits.store_en := write_issue_q.io.deq.bits.store_en

    write_issue_q.io.deq.ready := writer.module.io.req.ready &&
      spad_writer.map(_.module.io.req.ready).getOrElse(true.B) && writeData.valid
    spad_writer.foreach { spad_writer =>
      spad_writer.module.io.req.valid := write_issue_q.io.deq.valid && writeData.valid && write_issue_q.io.deq.bits.dest.asBool
      spad_writer.module.io.req.bits.vaddr := config.tl_ext_mem_base.U |
        (write_issue_q.io.deq.bits.vaddr.asUInt << log2Ceil(config.DIM * config.inputType.getWidth / 8).U).asUInt
      spad_writer.module.io.req.bits.physical := write_issue_q.io.deq.bits.dest
      spad_writer.module.io.req.bits.len := Mux(writeData_is_full_width,
        write_issue_q.io.deq.bits.len * (accType.getWidth / 8).U,
        write_issue_q.io.deq.bits.len * (inputType.getWidth / 8).U)
      spad_writer.module.io.req.bits.data := MuxCase(writeData.bits, Seq(
        writeData_is_all_zeros -> 0.U,
        writeData_is_full_width -> fullAccWriteData
      ))
      spad_writer.module.io.req.bits.block := write_issue_q.io.deq.bits.block
      spad_writer.module.io.req.bits.status := write_issue_q.io.deq.bits.status
      spad_writer.module.io.req.bits.pool_en := write_issue_q.io.deq.bits.pool_en
      spad_writer.module.io.req.bits.store_en := write_issue_q.io.deq.bits.store_en
    }

    io.dma.write.resp.valid := false.B
    io.dma.write.resp.bits.cmd_id := write_dispatch_q.bits.cmd_id
    when (write_dispatch_q.bits.laddr.is_garbage() && write_dispatch_q.fire) {
      io.dma.write.resp.valid := true.B
    }

    read_issue_q.io.enq <> io.dma.read.req

    val zero_writer = Module(new ZeroWriter(config, new ScratchpadMemReadRequest(local_addr_t, mvin_scale_t_bits)))

    when (io.dma.read.req.bits.all_zeros) {
      read_issue_q.io.enq.valid := false.B
      io.dma.read.req.ready := zero_writer.io.req.ready
    }

    zero_writer.io.req.valid := io.dma.read.req.valid && io.dma.read.req.bits.all_zeros
    zero_writer.io.req.bits.laddr := io.dma.read.req.bits.laddr
    zero_writer.io.req.bits.cols := io.dma.read.req.bits.cols
    zero_writer.io.req.bits.block_stride := io.dma.read.req.bits.block_stride
    zero_writer.io.req.bits.tag := io.dma.read.req.bits

    val zero_writer_pixel_repeater = Module(new PixelRepeater(inputType, local_addr_t, block_cols, aligned_to, new ScratchpadMemReadRequest(local_addr_t, mvin_scale_t_bits), passthrough = !has_first_layer_optimizations))
    // Capture payload and metadata before the wide bank-write arbitration.
    val zeroWriteBuffer = Module(new BankedShallowQueue(chiselTypeOf(zero_writer_pixel_repeater.io.resp.bits),
      2, pipe = false, flow = false))
    zeroWriteBuffer.io.enq <> zero_writer_pixel_repeater.io.resp
    val zero_writer_out = zeroWriteBuffer.io.deq
    zero_writer_pixel_repeater.io.req.valid := zero_writer.io.resp.valid
    zero_writer_pixel_repeater.io.req.bits.in := 0.U.asTypeOf(Vec(block_cols, inputType))
    zero_writer_pixel_repeater.io.req.bits.laddr := zero_writer.io.resp.bits.laddr
    zero_writer_pixel_repeater.io.req.bits.len := zero_writer.io.resp.bits.tag.cols
    zero_writer_pixel_repeater.io.req.bits.pixel_repeats := zero_writer.io.resp.bits.tag.pixel_repeats
    zero_writer_pixel_repeater.io.req.bits.last := zero_writer.io.resp.bits.last
    zero_writer_pixel_repeater.io.req.bits.tag := zero_writer.io.resp.bits.tag
    zero_writer_pixel_repeater.io.req.bits.mask := {
      val n = inputType.getWidth / 8
      val mask = zero_writer.io.resp.bits.mask
      val expanded = VecInit(mask.flatMap(e => Seq.fill(n)(e)))
      expanded
    }

    zero_writer.io.resp.ready := zero_writer_pixel_repeater.io.req.ready
    zero_writer_out.ready := false.B

    reader.module.io.req.valid := read_issue_q.io.deq.valid
    read_issue_q.io.deq.ready := reader.module.io.req.ready
    reader.module.io.req.bits.vaddr := read_issue_q.io.deq.bits.vaddr
    reader.module.io.req.bits.spaddr := Mux(read_issue_q.io.deq.bits.laddr.is_acc_addr,
      read_issue_q.io.deq.bits.laddr.full_acc_addr(), read_issue_q.io.deq.bits.laddr.full_sp_addr())
    reader.module.io.req.bits.len := read_issue_q.io.deq.bits.cols
    reader.module.io.req.bits.repeats := read_issue_q.io.deq.bits.repeats
    reader.module.io.req.bits.pixel_repeats := read_issue_q.io.deq.bits.pixel_repeats
    reader.module.io.req.bits.scale := read_issue_q.io.deq.bits.scale
    reader.module.io.req.bits.is_acc := read_issue_q.io.deq.bits.laddr.is_acc_addr
    reader.module.io.req.bits.accumulate := read_issue_q.io.deq.bits.laddr.accumulate
    reader.module.io.req.bits.has_acc_bitwidth := read_issue_q.io.deq.bits.has_acc_bitwidth
    reader.module.io.req.bits.block_stride := read_issue_q.io.deq.bits.block_stride
    reader.module.io.req.bits.status := read_issue_q.io.deq.bits.status
    reader.module.io.req.bits.cmd_id := read_issue_q.io.deq.bits.cmd_id

    val (mvin_scale_in, mvin_scale_out) = VectorScalarMultiplier(
      config.mvin_scale_args,
      config.inputType, config.meshColumns * config.tileColumns, chiselTypeOf(reader.module.io.resp.bits),
      is_acc = false
    )
    val (mvin_scale_acc_in, mvin_scale_acc_raw_out) = if (mvin_scale_shared) (mvin_scale_in, mvin_scale_out) else (
      VectorScalarMultiplier(
        config.mvin_scale_acc_args,
        config.accType, config.meshColumns * config.tileColumns, chiselTypeOf(reader.module.io.resp.bits),
        is_acc = true
      )
    )

    val mvin_scale_acc_out = if (mvin_scale_shared) mvin_scale_acc_raw_out else {
      val accMvinWriteBuffer = Module(new BankedShallowQueue(chiselTypeOf(mvin_scale_acc_raw_out.bits),
        2, pipe = false, flow = false))
      accMvinWriteBuffer.io.enq <> mvin_scale_acc_raw_out
      accMvinWriteBuffer.io.deq
    }

    mvin_scale_in.valid := reader.module.io.resp.valid && (mvin_scale_shared.B || !reader.module.io.resp.bits.is_acc ||
      (reader.module.io.resp.bits.is_acc && !reader.module.io.resp.bits.has_acc_bitwidth))

    mvin_scale_in.bits.in := reader.module.io.resp.bits.data.asTypeOf(chiselTypeOf(mvin_scale_in.bits.in))
    mvin_scale_in.bits.scale := reader.module.io.resp.bits.scale.asTypeOf(mvin_scale_t)
    mvin_scale_in.bits.repeats := reader.module.io.resp.bits.repeats
    mvin_scale_in.bits.pixel_repeats := reader.module.io.resp.bits.pixel_repeats
    mvin_scale_in.bits.last := reader.module.io.resp.bits.last
    mvin_scale_in.bits.tag := reader.module.io.resp.bits

    val mvin_scale_pixel_repeater = Module(new PixelRepeater(inputType, local_addr_t, block_cols, aligned_to, mvin_scale_out.bits.tag.cloneType, passthrough = !has_first_layer_optimizations))
    // Capture payload and metadata before the wide bank-write arbitration.
    val mvinWriteBuffer = Module(new BankedShallowQueue(chiselTypeOf(mvin_scale_pixel_repeater.io.resp.bits),
      2, pipe = false, flow = false))
    mvinWriteBuffer.io.enq <> mvin_scale_pixel_repeater.io.resp
    val mvin_scale_write_out = mvinWriteBuffer.io.deq
    mvin_scale_pixel_repeater.io.req.valid := mvin_scale_out.valid
    mvin_scale_pixel_repeater.io.req.bits.in := mvin_scale_out.bits.out
    mvin_scale_pixel_repeater.io.req.bits.mask := mvin_scale_out.bits.tag.mask take mvin_scale_pixel_repeater.io.req.bits.mask.size
    mvin_scale_pixel_repeater.io.req.bits.laddr := mvin_scale_out.bits.tag.addr.asTypeOf(local_addr_t) + mvin_scale_out.bits.row
    mvin_scale_pixel_repeater.io.req.bits.len := mvin_scale_out.bits.tag.len
    mvin_scale_pixel_repeater.io.req.bits.pixel_repeats := mvin_scale_out.bits.tag.pixel_repeats
    mvin_scale_pixel_repeater.io.req.bits.last := mvin_scale_out.bits.last
    mvin_scale_pixel_repeater.io.req.bits.tag := mvin_scale_out.bits.tag

    mvin_scale_out.ready := mvin_scale_pixel_repeater.io.req.ready
    mvin_scale_write_out.ready := false.B

    if (!mvin_scale_shared) {
      mvin_scale_acc_in.valid := reader.module.io.resp.valid &&
        (reader.module.io.resp.bits.is_acc && reader.module.io.resp.bits.has_acc_bitwidth)
      mvin_scale_acc_in.bits.in := reader.module.io.resp.bits.data.asTypeOf(chiselTypeOf(mvin_scale_acc_in.bits.in))
      mvin_scale_acc_in.bits.scale := reader.module.io.resp.bits.scale.asTypeOf(mvin_scale_acc_t)
      mvin_scale_acc_in.bits.repeats := reader.module.io.resp.bits.repeats
      mvin_scale_acc_in.bits.pixel_repeats := 1.U
      mvin_scale_acc_in.bits.last := reader.module.io.resp.bits.last
      mvin_scale_acc_in.bits.tag := reader.module.io.resp.bits

      mvin_scale_acc_out.ready := false.B
    }

    reader.module.io.resp.ready := Mux(reader.module.io.resp.bits.is_acc && reader.module.io.resp.bits.has_acc_bitwidth,
      mvin_scale_acc_in.ready, mvin_scale_in.ready)

    val mvin_scale_finished = mvin_scale_write_out.fire && mvin_scale_write_out.bits.last
    val mvin_scale_acc_finished = mvin_scale_acc_out.fire && mvin_scale_acc_out.bits.last
    val zero_writer_finished = zero_writer_out.fire && zero_writer_out.bits.last

    val zero_writer_bytes_read = Mux(zero_writer_out.bits.laddr.is_acc_addr,
      zero_writer_out.bits.tag.cols * (accType.getWidth / 8).U,
      zero_writer_out.bits.tag.cols * (inputType.getWidth / 8).U)

    // For DMA read responses, mvin_scale gets first priority, then mvin_scale_acc, and then zero_writer
    io.dma.read.resp.valid := mvin_scale_finished || mvin_scale_acc_finished || zero_writer_finished

    // io.dma.read.resp.bits.cmd_id := MuxCase(zero_writer.io.resp.bits.tag.cmd_id, Seq(
    io.dma.read.resp.bits.cmd_id := MuxCase(zero_writer_out.bits.tag.cmd_id, Seq(
      // mvin_scale_finished -> mvin_scale_out.bits.tag.cmd_id,
      mvin_scale_finished -> mvin_scale_write_out.bits.tag.cmd_id,
      mvin_scale_acc_finished -> mvin_scale_acc_out.bits.tag.cmd_id))

    io.dma.read.resp.bits.bytesRead := MuxCase(zero_writer_bytes_read, Seq(
      // mvin_scale_finished -> mvin_scale_out.bits.tag.bytes_read,
      mvin_scale_finished -> mvin_scale_write_out.bits.tag.bytes_read,
      mvin_scale_acc_finished -> mvin_scale_acc_out.bits.tag.bytes_read))

    io.tlb(0) <> writer.module.io.tlb
    io.tlb(1) <> reader.module.io.tlb
    spad_writer match {
      case Some(sw) => {
        io.tlb(2) <> sw.module.io.tlb
        sw.module.io.flush := io.flush
      }
      case None => {}
    }

    writer.module.io.flush := io.flush
    reader.module.io.flush := io.flush

    io.busy := writer.module.io.busy || spad_writer.map(_.module.io.busy).getOrElse(false.B) || reader.module.io.busy ||
      write_issue_q.io.deq.valid || write_norm_q.io.deq.valid || write_scale_q.io.deq.valid || write_dispatch_q.valid

    val spad_mems = {
      val banks = Seq.fill(sp_banks) { Module(new ScratchpadBank(
        sp_bank_entries, spad_w,
        aligned_to, config.sp_singleported,
        use_shared_ext_mem, is_dummy
      )) }
      val bank_ios = VecInit(banks.map(_.io))
      val spadBufferedReadHazards = Wire(Vec(sp_banks, Bool()))
      // Reading from the SRAM banks
      bank_ios.zipWithIndex.foreach { case (bio, i) =>
        if (use_shared_ext_mem) {
          io.ext_mem.get.spad(i) <> bio.ext_mem.get
        }

        // Register the ExecuteController request before bank arbitration and
        // the OrderedBankWrites hazard CAM. A one-entry, non-flowing elastic
        // stage is sufficient to break the address path and costs half the
        // payload registers of the failed 0910/0911 two-entry experiment.
        val ex_read_skid = Module(new Queue(
          chiselTypeOf(io.srams.read(i).req.bits), 1,
          pipe = true, flow = false))
        ex_read_skid.io.enq <> io.srams.read(i).req
        val ex_read_req = ex_read_skid.io.deq
        val exread = ex_read_req.valid

        // TODO we tie the write dispatch queue's, and write issue queue's, ready and valid signals together here
        val dmawrite = write_dispatch_q.valid && write_norm_q.io.enq.ready &&
          !write_dispatch_q.bits.laddr.is_garbage() &&
          !(bio.write.fire && config.sp_singleported.B) &&
          !write_dispatch_q.bits.laddr.is_acc_addr && write_dispatch_q.bits.laddr.sp_bank() === i.U

        bio.read.req.valid := (exread || dmawrite) && !spadBufferedReadHazards(i)
        ex_read_req.ready := bio.read.req.ready && !spadBufferedReadHazards(i)

        // The ExecuteController gets priority when reading from SRAMs
        when (exread) {
          bio.read.req.bits.addr := ex_read_req.bits.addr
          bio.read.req.bits.fromDMA := false.B
        }.elsewhen (dmawrite) {
          bio.read.req.bits.addr := write_dispatch_q.bits.laddr.sp_row()
          bio.read.req.bits.fromDMA := true.B

          when (bio.read.req.fire) {
            write_dispatch_q.ready := true.B
            write_norm_q.io.enq.valid := true.B

            io.dma.write.resp.valid := true.B
          }
        }.otherwise {
          bio.read.req.bits := DontCare
        }

        val dma_read_resp = Wire(Decoupled(new ScratchpadReadResp(spad_w)))
        dma_read_resp.valid := bio.read.resp.valid && bio.read.resp.bits.fromDMA
        dma_read_resp.bits := bio.read.resp.bits
        val ex_read_resp = Wire(Decoupled(new ScratchpadReadResp(spad_w)))
        ex_read_resp.valid := bio.read.resp.valid && !bio.read.resp.bits.fromDMA
        ex_read_resp.bits := bio.read.resp.bits

        // Full response queues must not propagate ExecuteController/DMA ready
        // through another bank's arbitration back to the SRAM address pins.
        // Capacity is unchanged; only full-queue recovery may take one bubble.
        val dma_read_pipe = Module(new BankedShallowQueue(dma_read_resp.bits.cloneType,
          spad_read_delay, flow = false, pipe = false))
        val ex_read_pipe = Module(new BankedShallowQueue(ex_read_resp.bits.cloneType,
          spad_read_delay, flow = false, pipe = false))

        dma_read_pipe.io.enq <> dma_read_resp
        ex_read_pipe.io.enq <> ex_read_resp

        bio.read.resp.ready := Mux(bio.read.resp.bits.fromDMA, dma_read_resp.ready, ex_read_resp.ready)

        dma_read_pipe.io.deq.ready := writer.module.io.req.ready &&
          spad_writer.map(_.module.io.req.ready).getOrElse(true.B) &&
          (!write_issue_q.io.deq.bits.laddr.is_acc_addr && write_issue_q.io.deq.bits.laddr.sp_bank() === i.U && // I believe we don't need to check that write_issue_q is valid here, because if the SRAM's resp is valid, then that means that the write_issue_q's deq should also be valid
          write_issue_q.io.deq.valid) && !write_issue_q.io.deq.bits.laddr.is_garbage()
        when (dma_read_pipe.io.deq.fire) {
          writeData.valid := true.B
          writeData.bits := dma_read_pipe.io.deq.bits.data
        }

        io.srams.read(i).resp <> ex_read_pipe.io.deq
      }

      // Writing to the SRAM banks
      bank_ios.zipWithIndex.foreach { case (bio, i) =>
        val pending = Module(new OrderedBankWrites(log2Ceil(sp_bank_entries), spad_w))
        val ex = io.srams.write(i)
        val dma = mvin_scale_write_out
        val zero = zero_writer_out
        val dmaValid = dma.valid && !dma.bits.tag.is_acc && dma.bits.laddr.sp_bank() === i.U
        val zeroValid = zero.valid && !zero.bits.laddr.is_acc_addr &&
          zero.bits.laddr.sp_bank() === i.U &&
          !((dma.valid && dma.bits.last) || (mvin_scale_acc_out.valid && mvin_scale_acc_out.bits.last))
        val selected = Mux(ex.valid, 0.U, Mux(dmaValid, 1.U, 2.U))
        pending.io.enq.valid := ex.valid || dmaValid || zeroValid
        pending.io.enq.bits.addr := Mux(ex.valid, ex.addr,
          Mux(dmaValid, dma.bits.laddr.sp_row(), zero.bits.laddr.sp_row()))
        pending.io.enq.bits.data := Mux(ex.valid, ex.data, Mux(dmaValid, dma.bits.out.asUInt, 0.U))
        pending.io.enq.bits.mask := Mux(ex.valid, ex.mask,
          Mux(dmaValid, VecInit(dma.bits.mask.take(spad_w / 8)), zero.bits.mask))
        pending.io.enq.bits.acc := false.B
        pending.io.enq.bits.ex := ex.valid
        ex.ready := pending.io.enq.ready
        when(pending.io.enq.fire && selected === 1.U) { dma.ready := true.B }
        when(pending.io.enq.fire && selected === 2.U) { zero.ready := true.B }
        bio.write.valid := pending.io.deq.valid
        bio.write.addr := pending.io.deq.bits.addr
        bio.write.data := pending.io.deq.bits.data
        bio.write.mask := pending.io.deq.bits.mask
        pending.io.deq.ready := bio.write.ready
        pending.io.readAddr := bio.read.req.bits.addr
        // An accepted DMA write may still be in the ordered buffer.
        spadBufferedReadHazards(i) := pending.io.readHazard
        debugSpadHazards := spadBufferedReadHazards.asUInt
        exPendingSignals += pending.io.exPending
      }
      banks
    }

    val acc_row_t = Vec(meshColumns, Vec(tileColumns, accType))
    val spad_row_t = Vec(meshColumns, Vec(tileColumns, inputType))

    val (acc_norm_unit_in, acc_norm_unit_out) = Normalizer(
      is_passthru = !config.has_normalizations,
      max_len = block_cols,
      num_reduce_lanes = -1,
      num_stats = 2,
      latency = 4,
      fullDataType = acc_row_t,
      scale_t = acc_scale_t,
    )

    acc_norm_unit_in.valid := false.B
    acc_norm_unit_in.bits.len := write_norm_q.io.deq.bits.len
    acc_norm_unit_in.bits.stats_id := write_norm_q.io.deq.bits.acc_norm_stats_id
    acc_norm_unit_in.bits.cmd := write_norm_q.io.deq.bits.laddr.norm_cmd
    acc_norm_unit_in.bits.acc_read_resp := DontCare

    val acc_scale_unit = Module(new AccumulatorScale(
      acc_row_t,
      spad_row_t,
      acc_scale_t.asInstanceOf[V],
      acc_read_small_width,
      acc_read_full_width,
      acc_scale_func,
      acc_scale_num_units,
      acc_scale_latency,
      has_nonlinear_activations,
      has_normalizations,
      has_silu_lut,
      silu_only,
    ))
    acc_scale_unit.io.silu_lut_write := io.silu_lut_write
    io.silu_lut_ready := acc_scale_unit.io.silu_lut_ready

    val acc_waiting_to_be_scaled = write_scale_q.io.deq.valid &&
      !write_scale_q.io.deq.bits.laddr.is_garbage() &&
      write_scale_q.io.deq.bits.laddr.is_acc_addr &&
      write_issue_q.io.enq.ready

    val scaleInput = Module(new BankedShallowQueue(acc_scale_unit.io.in.bits.cloneType, 2,
      pipe = false, flow = false))
    acc_norm_unit_out.ready := scaleInput.io.enq.ready && acc_waiting_to_be_scaled
    scaleInput.io.enq.valid := acc_norm_unit_out.valid && acc_waiting_to_be_scaled
    scaleInput.io.enq.bits := acc_norm_unit_out.bits
    acc_scale_unit.io.in <> scaleInput.io.deq

    when (scaleInput.io.enq.fire) {
      write_issue_q.io.enq <> write_scale_q.io.deq
    }

    val scaleOutput = Module(new BankedShallowQueue(acc_scale_unit.io.out.bits.cloneType, 2,
      pipe = false, flow = false))
    scaleOutput.io.enq <> acc_scale_unit.io.out
    scaleOutput.io.deq.ready := false.B

    val dma_resp_ready =
      (writer.module.io.req.ready && spad_writer.map(_.module.io.req.ready).getOrElse(true.B)) &&
        write_issue_q.io.deq.bits.laddr.is_acc_addr &&
        !write_issue_q.io.deq.bits.laddr.is_garbage()

    when (scaleOutput.io.deq.bits.fromDMA && dma_resp_ready) {
      // Send the acc-scale result into the DMA
      scaleOutput.io.deq.ready := true.B
      writeData.valid := scaleOutput.io.deq.valid
      writeData.bits  := scaleOutput.io.deq.bits.data.asUInt
      fullAccWriteData := scaleOutput.io.deq.bits.full_data.asUInt
    }
    for (i <- 0 until acc_banks) {
      // Send the acc-sccale result to the ExController
      io.acc.read_resp(i).valid := false.B
      io.acc.read_resp(i).bits  := scaleOutput.io.deq.bits
      when (!scaleOutput.io.deq.bits.fromDMA && scaleOutput.io.deq.bits.acc_bank_id === i.U) {
        scaleOutput.io.deq.ready := io.acc.read_resp(i).ready
        io.acc.read_resp(i).valid := scaleOutput.io.deq.valid
      }
    }

    require(acc_latency == 4, "local accumulator pipeline is RAM + capture + two add stages")

    val acc_mems = {
      val banks = Seq.fill(acc_banks) { Module(new AccumulatorMem(
        acc_bank_entries, acc_row_t, acc_scale_func, acc_scale_t.asInstanceOf[V],
        acc_singleported, acc_sub_banks,
        use_shared_ext_mem, use_tl_ext_mem,
        acc_latency, accType, is_dummy
      )) }
      val bank_ios = VecInit(banks.map(_.io))

      // Getting the output of the bank that's about to be issued to the writer
      val bank_issued_io = bank_ios(write_issue_q.io.deq.bits.laddr.acc_bank())

      val accBufferedReadHazards = Wire(Vec(acc_banks, Bool()))
      // Reading from the Accumulator banks
      bank_ios.zipWithIndex.foreach { case (bio, i) =>
        if (use_shared_ext_mem) {
          io.ext_mem.get.acc(i) <> bio.ext_mem.get
        }

        bio.adder.sum := VecInit((0 until meshColumns).map { r =>
          VecInit((0 until tileColumns).map { c =>
            val add = Module(new LocalAccAdder)
            add.io.a := RegNext(bio.adder.op1(r)(c).asUInt)
            add.io.b := RegNext(bio.adder.op2(r)(c).asUInt)
            add.io.sum.asTypeOf(accType)
          })
        })

        // Apply the same low-area registered boundary to accumulator reads.
        val ex_read_skid = Module(new Queue(
          chiselTypeOf(io.acc.read_req(i).bits), 1,
          pipe = true, flow = false))
        ex_read_skid.io.enq <> io.acc.read_req(i)
        val ex_read_req = ex_read_skid.io.deq
        val exread = ex_read_req.valid

        // TODO we tie the write dispatch queue's, and write issue queue's, ready and valid signals together here
        val dmawrite = write_dispatch_q.valid && write_norm_q.io.enq.ready &&
          !write_dispatch_q.bits.laddr.is_garbage() &&
          write_dispatch_q.bits.laddr.is_acc_addr && write_dispatch_q.bits.laddr.acc_bank() === i.U

        bio.read.req.valid := (exread || dmawrite) && !accBufferedReadHazards(i)
        ex_read_req.ready := bio.read.req.ready && !accBufferedReadHazards(i)

        // The ExecuteController gets priority when reading from accumulator banks
        when (exread) {
          bio.read.req.bits.addr := ex_read_req.bits.addr
          bio.read.req.bits.act := ex_read_req.bits.act
          bio.read.req.bits.igelu_qb := ex_read_req.bits.igelu_qb
          bio.read.req.bits.igelu_qc := ex_read_req.bits.igelu_qc
          bio.read.req.bits.iexp_qln2 := ex_read_req.bits.iexp_qln2
          bio.read.req.bits.iexp_qln2_inv := ex_read_req.bits.iexp_qln2_inv
          bio.read.req.bits.scale := ex_read_req.bits.scale
          bio.read.req.bits.full := false.B
          bio.read.req.bits.fromDMA := false.B
        }.elsewhen (dmawrite) {
          bio.read.req.bits.addr := write_dispatch_q.bits.laddr.acc_row()
          bio.read.req.bits.full := write_dispatch_q.bits.laddr.read_full_acc_row
          bio.read.req.bits.act := write_dispatch_q.bits.acc_act
          bio.read.req.bits.igelu_qb := write_dispatch_q.bits.acc_igelu_qb.asTypeOf(bio.read.req.bits.igelu_qb)
          bio.read.req.bits.igelu_qc := write_dispatch_q.bits.acc_igelu_qc.asTypeOf(bio.read.req.bits.igelu_qc)
          bio.read.req.bits.iexp_qln2 := write_dispatch_q.bits.acc_iexp_qln2.asTypeOf(bio.read.req.bits.iexp_qln2)
          bio.read.req.bits.iexp_qln2_inv := write_dispatch_q.bits.acc_iexp_qln2_inv.asTypeOf(bio.read.req.bits.iexp_qln2_inv)
          bio.read.req.bits.scale := write_dispatch_q.bits.acc_scale.asTypeOf(bio.read.req.bits.scale)
          bio.read.req.bits.fromDMA := true.B

          when (bio.read.req.fire) {
            write_dispatch_q.ready := true.B
            write_norm_q.io.enq.valid := true.B

            io.dma.write.resp.valid := true.B
          }
        }.otherwise {
          bio.read.req.bits := DontCare
        }
        bio.read.resp.ready := false.B

        when (write_norm_q.io.deq.valid &&
          acc_norm_unit_in.ready &&
          bio.read.resp.valid &&
          write_scale_q.io.enq.ready &&
          write_norm_q.io.deq.bits.laddr.is_acc_addr &&
          !write_norm_q.io.deq.bits.laddr.is_garbage() &&
          write_norm_q.io.deq.bits.laddr.acc_bank() === i.U)
        {
          write_norm_q.io.deq.ready := true.B
          acc_norm_unit_in.valid := true.B
          bio.read.resp.ready := true.B

          // Some normalizer commands don't write to main memory, so they don't need to be passed on to the scaling units
          write_scale_q.io.enq.valid := NormCmd.writes_to_main_memory(write_norm_q.io.deq.bits.laddr.norm_cmd)

          acc_norm_unit_in.bits.acc_read_resp := bio.read.resp.bits
          acc_norm_unit_in.bits.acc_read_resp.acc_bank_id := i.U
        }
      }

      // Writing to the accumulator banks
      bank_ios.zipWithIndex.foreach { case (bio, i) =>
        val pending = Module(new OrderedBankWrites(log2Ceil(acc_bank_entries), acc_w))
        val ex = io.acc.write(i)
        val dma = mvin_scale_write_out
        val dmaAcc = mvin_scale_acc_out
        val zero = zero_writer_out
        val fromInput = dma.valid && dma.bits.tag.is_acc
        val fromAcc = dmaAcc.valid && dmaAcc.bits.tag.is_acc
        val dmaAddr = Mux(fromInput, dma.bits.laddr,
          dmaAcc.bits.tag.addr.asTypeOf(local_addr_t) + dmaAcc.bits.row)
        val spadLast = dma.valid && dma.bits.last && !dma.bits.tag.is_acc
        val dmaValid = (fromInput || fromAcc) && dmaAddr.acc_bank() === i.U && !spadLast
        val zeroValid = zero.valid && zero.bits.laddr.is_acc_addr &&
          zero.bits.laddr.acc_bank() === i.U &&
          !((dma.valid && dma.bits.last) || (dmaAcc.valid && dmaAcc.bits.last))
        val dmaData = Mux(fromInput,
          VecInit(dma.bits.out.map(_.withWidthOf(accType))).asUInt, dmaAcc.bits.out.asUInt)
        val dmaMask = Mux(fromInput,
          VecInit(dma.bits.mask.take(spad_w / 8).flatMap(b => Seq.fill(4)(b))), dmaAcc.bits.tag.mask)
        val selected = Mux(ex.valid, 0.U, Mux(dmaValid, 1.U, 2.U))
        pending.io.enq.valid := ex.valid || dmaValid || zeroValid
        pending.io.enq.bits.addr := Mux(ex.valid, ex.bits.addr,
          Mux(dmaValid, dmaAddr.acc_row(), zero.bits.laddr.acc_row()))
        pending.io.enq.bits.data := Mux(ex.valid, ex.bits.data.asUInt, Mux(dmaValid, dmaData, 0.U))
        pending.io.enq.bits.mask := Mux(ex.valid, ex.bits.mask,
          Mux(dmaValid, dmaMask, VecInit(zero.bits.mask.flatMap(b => Seq.fill(4)(b)))))
        pending.io.enq.bits.acc := Mux(ex.valid, ex.bits.acc, Mux(dmaValid,
          Mux(fromInput, dma.bits.tag.accumulate, dmaAcc.bits.tag.accumulate),
          zero.bits.laddr.accumulate))
        pending.io.enq.bits.ex := ex.valid
        ex.ready := pending.io.enq.ready
        when(pending.io.enq.fire && selected === 1.U) {
          when(fromInput) { dma.ready := true.B }.otherwise { dmaAcc.ready := true.B }
        }
        when(pending.io.enq.fire && selected === 2.U) { zero.ready := true.B }
        bio.write.valid := pending.io.deq.valid
        bio.write.bits.addr := pending.io.deq.bits.addr
        bio.write.bits.data := pending.io.deq.bits.data.asTypeOf(acc_row_t)
        bio.write.bits.mask := pending.io.deq.bits.mask
        bio.write.bits.acc := pending.io.deq.bits.acc
        pending.io.deq.ready := bio.write.ready
        pending.io.readAddr := bio.read.req.bits.addr
        // Export ordering hazard to the earlier read arbitration.
        accBufferedReadHazards(i) := pending.io.readHazard
        debugAccHazards := accBufferedReadHazards.asUInt
        val exCommitPipe = RegInit(VecInit(Seq.fill(acc_latency)(false.B)))
        exCommitPipe(0) := bio.write.fire && pending.io.deq.bits.ex
        for (stage <- 1 until acc_latency) { exCommitPipe(stage) := exCommitPipe(stage - 1) }
        exPendingSignals += (pending.io.exPending || exCommitPipe.asUInt.orR)
      }
      banks
    }

    for (i <- 0 until 4) {
      io.deadlock_debug(i) := reader.module.io.deadlock_debug(i)
      io.deadlock_debug(i + 4) := writer.module.io.deadlock_debug(i)
      io.deadlock_debug(i + 8) := acc_scale_unit.io.deadlock_debug(i)
    }
    for (i <- 0 until 5) { io.deadlock_debug(i + 12) := acc_scale_unit.io.scale_fault_debug(i) }
    io.deadlock_debug(17) := Cat(write_norm_q.io.count.pad(8), write_scale_q.io.count.pad(8),
      write_issue_q.io.count.pad(8), scaleInput.io.count.pad(8), scaleOutput.io.count.pad(8),
      mvinWriteBuffer.io.count.pad(8), zeroWriteBuffer.io.count.pad(8),
      0.U(2.W), scaleInput.io.enq.fire, scaleInput.io.deq.fire,
      scaleOutput.io.enq.fire, scaleOutput.io.deq.fire, writer.module.io.req.fire, io.writeback_idle)
    io.deadlock_debug(18) := Cat(0.U(16.W), VecInit(exPendingSignals.toSeq).asUInt.pad(16),
      debugSpadHazards, debugAccHazards)
    def debugRows(event: Bool): UInt = {
      val count = RegInit(0.U(32.W))
      when(event) { count := count + 1.U }
      count
    }
    io.deadlock_debug(19) := Cat(debugRows(scaleInput.io.enq.fire), debugRows(scaleOutput.io.deq.fire))
    io.deadlock_debug(20) := Cat(debugRows(io.dma.read.resp.valid), debugRows(io.dma.write.resp.valid))
    io.writeback_idle := !exPendingSignals.reduce(_ || _)

    // Counter connection
    io.counter := DontCare
    io.counter.collect(reader.module.io.counter)
    io.counter.collect(writer.module.io.counter)
    spad_writer.foreach(_.module.io.counter := DontCare)
//    io.counter.collect(spad_writer.module.io.counter)
  }
}
