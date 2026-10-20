package sifive.blocks.inclusivecache

import chisel3._
import chisel3.util._

// Compare stored tags before the late MSHR arbiter. Storage and arbitration
// are unchanged: the late path selects booleans instead of a wide payload
// followed by a tag comparator. Entry comparisons are shared across A/B/C.
class ListBufferTagMatch(mshrs: Int, entries: Int, tagBits: Int) extends Module {
  val io = IO(new Bundle {
    val tags = Input(Vec(entries, UInt(tagBits.W)))
    val heads = Input(Vec(3 * mshrs, UInt(entries.W)))
    val valid = Input(UInt((3 * mshrs).W))
    val statusTags = Input(Vec(mshrs, UInt(tagBits.W)))
    val queuedMatch = Output(UInt(mshrs.W))
  })
  io.queuedMatch := VecInit((0 until mshrs).map { i =>
    val entryMatch = VecInit(io.tags.map(_ === io.statusTags(i))).asUInt
    val a = (entryMatch & io.heads(i)).orR
    val b = (entryMatch & io.heads(mshrs + i)).orR
    val c = (entryMatch & io.heads(2 * mshrs + i)).orR
    Mux(io.valid(2 * mshrs + i), c,
      Mux(io.valid(mshrs + i), b, a))
  }).asUInt
}
