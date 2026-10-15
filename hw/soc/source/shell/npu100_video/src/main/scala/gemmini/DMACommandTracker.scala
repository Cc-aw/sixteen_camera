package gemmini

import chisel3._
import chisel3.util._


// This module is meant to go inside the Load controller, where it can track which commands are currently
// in flight and which are completed
class DMACommandTracker[T <: Data](val nCmds: Int, val maxBytes: Int, tag_t: => T) extends Module {
  def cmd_id_t = UInt((log2Ceil(nCmds) max 1).W)

  val io = IO(new Bundle {
    // TODO is there an existing decoupled interface in the standard library which matches this use-case?
    val alloc = new Bundle {
      val valid = Input(Bool())
      val ready = Output(Bool())

      class BitsT(tag_t: => T, cmd_id_t: UInt) extends Bundle {
        // This was only spun off as its own class to resolve CloneType errors
        val tag = Input(tag_t.cloneType)
        val bytes_to_read = Input(UInt(log2Up(maxBytes+1).W))
        val cmd_id = Output(cmd_id_t.cloneType)
      }

      val bits = new BitsT(tag_t.cloneType, cmd_id_t.cloneType)

      def fire(dummy: Int = 0) = valid && ready
    }

    class RequestReturnedT(cmd_id_t: UInt) extends Bundle {
      // This was only spun off as its own class to resolve CloneType errors
      val bytes_read = UInt(log2Up(maxBytes+1).W)
      val cmd_id = cmd_id_t.cloneType

    }

    val request_returned = Flipped(Valid(new RequestReturnedT(cmd_id_t.cloneType)))

    class CmdCompletedT(cmd_id_t: UInt, tag_t: T) extends Bundle {
      val cmd_id = cmd_id_t.cloneType
      val tag = tag_t.cloneType

    }

    val cmd_completed = Decoupled(new CmdCompletedT(cmd_id_t.cloneType, tag_t.cloneType))

    val busy = Output(Bool())
    val debug = Output(UInt(64.W))
  })

  class Entry extends Bundle {
    val valid = Bool()
    val tag = tag_t.cloneType
    val bytes_left = UInt(log2Up(maxBytes+1).W)

    def init(dummy: Int = 0): Unit = {
      valid := false.B
    }
  }

  // val cmds = RegInit(VecInit(Seq.fill(nCmds)(entry_init)))
  val cmds = Reg(Vec(nCmds, new Entry))
  val cmd_valids = cmds.map(_.valid)

  val completed_oh = VecInit(cmds.map(cmd => cmd.valid && cmd.bytes_left === 0.U))
  val cmd_completed_id = MuxCase(0.U, completed_oh.zipWithIndex.map { case (v, i) => v -> i.U })
  val complete_fire = io.cmd_completed.valid && io.cmd_completed.ready

  val reusable_oh = VecInit(cmds.zipWithIndex.map { case (cmd, i) =>
    !cmd.valid || (complete_fire && completed_oh(i))
  })
  val next_empty_alloc = MuxCase(0.U, reusable_oh.zipWithIndex.map { case (v, i) => v -> i.U })

  io.alloc.ready := reusable_oh.reduce(_ || _)
  io.alloc.bits.cmd_id := next_empty_alloc

  io.busy := cmd_valids.reduce(_ || _)

  io.cmd_completed.valid := completed_oh.reduce(_ || _)
  io.cmd_completed.bits.cmd_id := cmd_completed_id
  io.cmd_completed.bits.tag := cmds(cmd_completed_id).tag

  val next_cmds = Wire(Vec(nCmds, new Entry))
  for (i <- 0 until nCmds) {
    val request_hit = io.request_returned.valid && io.request_returned.bits.cmd_id === i.U
    val complete_hit = complete_fire && io.cmd_completed.bits.cmd_id === i.U
    val alloc_hit = io.alloc.fire() && next_empty_alloc === i.U

    next_cmds(i) := cmds(i)

    when (request_hit) {
      next_cmds(i).bytes_left := cmds(i).bytes_left - io.request_returned.bits.bytes_read
    }

    when (complete_hit) {
      next_cmds(i).valid := false.B
    }

    when (alloc_hit) {
      next_cmds(i).valid := true.B
      next_cmds(i).tag := io.alloc.bits.tag
      next_cmds(i).bytes_left := io.alloc.bits.bytes_to_read
    }
  }

  when (io.request_returned.fire) {
    val cmd_id = io.request_returned.bits.cmd_id
    assert(cmds(cmd_id).valid)
    assert(cmds(cmd_id).bytes_left >= io.request_returned.bits.bytes_read)
  }

  // Lowest live slot: remaining bytes and identity, plus all occupied slots.
  val debugValid = Wire(UInt(16.W))
  debugValid := VecInit(cmds.map(_.valid)).asUInt
  val debugId = Wire(UInt(8.W))
  debugId := PriorityEncoder(debugValid)
  io.debug := Cat(debugValid.pad(16)(15, 0), debugId.pad(8)(7, 0),
    cmds(debugId).tag.asUInt.pad(8)(7, 0), cmds(debugId).bytes_left.pad(24)(23, 0),
    0.U(1.W), io.busy, io.alloc.valid, io.alloc.ready, io.request_returned.valid,
    io.cmd_completed.valid, io.cmd_completed.ready, complete_fire)
  cmds := next_cmds

  when (reset.asBool) {
    cmds.foreach(_.init())
  }
}
