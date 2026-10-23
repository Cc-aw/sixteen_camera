package gemmini

import chisel3._

/** DIM32 partial-row placement after FP16 scaling and before pixel repeat.
  * The data and byte mask always move together; no read/modify/write is used.
  */
class S1MvinLanePlace extends Module {
  val io = IO(new Bundle {
    val data = Input(UInt(256.W))
    val mask = Input(UInt(32.W))
    val high = Input(Bool())
    val out_data = Output(UInt(256.W))
    val out_mask = Output(UInt(32.W))
  })
  io.out_data := Mux(io.high, io.data << 128, io.data)
  io.out_mask := Mux(io.high, io.mask << 16, io.mask)
}
