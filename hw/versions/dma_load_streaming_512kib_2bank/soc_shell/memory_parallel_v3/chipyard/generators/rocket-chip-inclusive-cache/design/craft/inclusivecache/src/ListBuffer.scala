/*
 * Copyright 2019 SiFive, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You should have received a copy of LICENSE.Apache2 along with
 * this software. If not, you may obtain a copy at
 *
 *    https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package sifive.blocks.inclusivecache

import chisel3._
import chisel3.util._
import freechips.rocketchip.util._

case class ListBufferParameters[T <: Data](gen: T, queues: Int, entries: Int, bypass: Boolean, fastPeek: Boolean = false)
{
  require(!fastPeek || !bypass, "One-hot front pointers currently support non-bypass queues")
  val queueBits = log2Up(queues)
  val entryBits = log2Up(entries)
}

class ListBufferPush[T <: Data](params: ListBufferParameters[T]) extends Bundle
{
  val index = UInt(params.queueBits.W)
  val data  = Output(params.gen)
}

class ListBuffer[T <: Data](params: ListBufferParameters[T]) extends Module
{
  override def desiredName = s"ListBuffer_${params.gen.typeName}_q${params.queues}_e${params.entries}" + (if (params.fastPeek) "_fast" else "")
  val io = IO(new Bundle {
    // push is visible on the same cycle; flow queues
    val push  = Flipped(Decoupled(new ListBufferPush(params)))
    val valid = UInt(params.queues.W)
    val pop   = Flipped(Valid(UInt(params.queueBits.W)))
    // The scheduler already has a one-hot winner. Keep that selection on the
    // peek path instead of encoding it and reading two dependent memories.
    val peekOH = if (params.fastPeek) Some(Input(UInt(params.queues.W))) else None
    val data  = Output(params.gen)
  })

  val valid = RegInit(0.U(params.queues.W))
  val head  = Mem(params.queues, UInt(params.entryBits.W))
  val tail  = Mem(params.queues, UInt(params.entryBits.W))
  val used  = RegInit(0.U(params.entries.W))
  val next  = Mem(params.entries, UInt(params.entryBits.W))
  val data = if (!params.fastPeek) Some(Mem(params.entries, params.gen)) else None
  // A shared entry pool, not one replicated payload memory per logical queue.
  // One-hot front pointers eliminate binary encode/decode and dependent RAM
  // reads on the late scheduler selection. Payload capacity is unchanged.
  val dataSlots = if (params.fastPeek) Some(Reg(Vec(params.entries, params.gen))) else None
  val frontOH = if (params.fastPeek) Some(Reg(Vec(params.queues, UInt(params.entries.W)))) else None

  val freeOH = ~(leftOR(~used) << 1) & ~used
  val freeIdx = OHToUInt(freeOH)

  val valid_set = WireDefault(0.U(params.queues.W))
  val valid_clr = WireDefault(0.U(params.queues.W))
  val used_set  = WireDefault(0.U(params.entries.W))
  val used_clr  = WireDefault(0.U(params.entries.W))

  val push_tail = tail.read(io.push.bits.index)
  val push_valid = valid(io.push.bits.index)

  io.push.ready := !used.andR
  when (io.push.fire) {
    valid_set := UIntToOH(io.push.bits.index, params.queues)
    used_set := freeOH
    data.foreach(_.write(freeIdx, io.push.bits.data))
    dataSlots.foreach(_(freeIdx) := io.push.bits.data)
    when (push_valid) {
      next.write(push_tail, freeIdx)
    } .otherwise {
      head.write(io.push.bits.index, freeIdx)
      frontOH.foreach(_(io.push.bits.index) := freeOH)
    }
    tail.write(io.push.bits.index, freeIdx)
  }

  val pop_head = head.read(io.pop.bits)
  val pop_valid = valid(io.pop.bits)

  // Bypass push data to the peek port
  io.data := (if (params.fastPeek) Mux1H(Mux1H(io.peekOH.get, frontOH.get), dataSlots.get)
             else if (!params.bypass) data.get.read(pop_head)
             else Mux(!pop_valid, io.push.bits.data, data.get.read(pop_head)))
  io.valid := (if (!params.bypass) valid else (valid | valid_set))

  // It is an error to pop something that is not valid
  assert (!io.pop.fire || (io.valid)(io.pop.bits))
  if (params.fastPeek) {
    assert(PopCount(io.peekOH.get) <= 1.U)
    assert(!io.pop.fire || (io.peekOH.get.orR && OHToUInt(io.peekOH.get) === io.pop.bits))
  }

  when (io.pop.fire) {
    used_clr := UIntToOH(pop_head, params.entries)
    when (pop_head === tail.read(io.pop.bits)) {
      valid_clr := UIntToOH(io.pop.bits, params.queues)
    }
    head.write(io.pop.bits, Mux(io.push.fire && push_valid && push_tail === pop_head, freeIdx, next.read(pop_head)))
    // Update only pointers on the retiring edge. No new cycle, no dependent
    // payload refill path, and simultaneous last-pop/push selects the new
    // entry (next RAM has not been written yet on that edge).
    frontOH.foreach(_(io.pop.bits) := Mux(
      io.push.fire && push_valid && push_tail === pop_head,
      freeOH, UIntToOH(next.read(pop_head), params.entries)))
  }

  // Empty bypass changes no state
  when ((!params.bypass).B || !io.pop.valid || pop_valid) {
    used  := (used  & ~used_clr)  | used_set
    valid := (valid & ~valid_clr) | valid_set
  }
}
