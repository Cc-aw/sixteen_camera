// SPDX-License-Identifier: Apache-2.0
package freechips.rocketchip.tile.commandfrontend

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import org.chipsalliance.diplomacy.lazymodule._
import freechips.rocketchip.resources.SimpleDevice
import freechips.rocketchip.diplomacy.AddressSet
import freechips.rocketchip.regmapper.RegField
import freechips.rocketchip.tilelink._

/** Separate extension page. All 64-bit diagnostic reads use a frozen snapshot.
  * CLEAR affects counters only: it cannot drop requests, credits or D replies.
  */
class ActivationSramControl(implicit p: Parameters) extends LazyModule {
  val device = new SimpleDevice("activation-sram-control", Seq("sixteen-camera,asram-1"))
  val node = TLRegisterNode(Seq(AddressSet(ActivationSramMap.controlBase, 4095)),
    device, beatBytes = 8, concurrency = 1)
  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val counts = IO(Input(Vec(3, Vec(2, Vec(20, UInt(64.W))))))
    val outstanding = IO(Input(Vec(3, Vec(2, UInt(7.W)))))
    val clear = IO(Output(Bool()))
    val action = RegInit(0.U(2.W))
    val snapshot = RegInit(VecInit(Seq.fill(120)(0.U(64.W))))
    val snapshotOutstanding = RegInit(VecInit(Seq.fill(6)(0.U(7.W))))
    clear := action(1)
    when(action =/= 0.U) { action := 0.U }
    when(action(0)) {
      for(lane <- 0 until 3; port <- 0 until 2) {
        snapshotOutstanding(lane * 2 + port) := outstanding(lane)(port)
        for(i <- 0 until 20) { snapshot(lane * 40 + port * 20 + i) := counts(lane)(port)(i) }
      }
    }
    val identity = Seq(
      0x00 -> Seq(RegField.r(64, "h41535231".U(64.W))),
      0x08 -> Seq(RegField.r(64, "h00010000".U(64.W))),
      0x10 -> Seq(RegField.r(64, 7.U(64.W))),
      0x18 -> Seq(RegField.r(64, ActivationSramMap.bytes.U(64.W))),
      0x20 -> Seq(RegField.r(64, ActivationSramMap.arenaBytes.U(64.W))),
      0x28 -> Seq(RegField.r(64, 256.U(64.W))),
      0x30 -> Seq(RegField.r(64, ActivationSramMap.clockHz.U(64.W))),
      0x38 -> Seq(RegField.r(64, 2.U(64.W))),
      0x40 -> Seq(RegField(2, action))) ++
      (0 until 3).map(i => (0x48 + i * 8) -> Seq(RegField.r(64, ActivationSramMap.bases(i).U(64.W)))) ++
      (0 until 6).map(i => (0x60 + i * 8) -> Seq(RegField.r(64, snapshotOutstanding(i).pad(64))))
    val performance = for(lane <- 0 until 3; port <- 0 until 2; i <- 0 until 20) yield
      (0x100 + lane * 0x400 + port * 0x100 + i * 8) -> Seq(RegField.r(64, snapshot(lane * 40 + port * 20 + i)))
    node.regmap((identity ++ performance): _*)
  }
}
