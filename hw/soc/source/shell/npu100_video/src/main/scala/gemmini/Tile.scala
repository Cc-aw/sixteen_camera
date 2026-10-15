// See README.md for license details.

package gemmini

import chisel3._
import chisel3.util._
import Util._

/**
  * A Tile is a purely combinational 2D array of passThrough PEs.
  * a, b, s, and in_propag are broadcast across the entire array and are passed through to the Tile's outputs
  * @param width The data width of each PE in bits
  * @param rows Number of PEs on each row
  * @param columns Number of PEs on each column
  */
class Tile[T <: Data](inputType: T, weightType: T, outputType: T, accType: T,
                     df: Dataflow.Value, tree_reduction: Boolean,
                     max_simultaneous_matmuls: Int, val rows: Int, val columns: Int,
                     useDspOutputShift: Boolean = false,
                     useDspMacBlackBox: Boolean = false,
                     useDspMacPacking: Boolean = false,
                     macPipelineCycles: Int = 0,
                     retimeWeightForwarding: Boolean = false)(implicit ev: Arithmetic[T]) extends Module {
  val io = IO(new Bundle {
    val in_a        = Input(Vec(rows, inputType))
    val in_b        = Input(Vec(columns, outputType)) // This is the output of the tile next to it
    val in_d        = Input(Vec(columns, outputType))

    val in_control  = Input(Vec(columns, new PEControl(accType)))
    val in_id       = Input(Vec(columns, UInt(log2Up(max_simultaneous_matmuls).W)))
    val in_last  = Input(Vec(columns, Bool()))

    val out_a       = Output(Vec(rows, inputType))
    val out_c       = Output(Vec(columns, outputType))
    val out_b       = Output(Vec(columns, outputType))

    val out_control = Output(Vec(columns, new PEControl(accType)))
    val out_id      = Output(Vec(columns, UInt(log2Up(max_simultaneous_matmuls).W)))
    val out_last    = Output(Vec(columns, Bool()))

    val in_valid = Input(Vec(columns, Bool()))
    val out_valid = Output(Vec(columns, Bool()))

    val bad_dataflow = Output(Bool())
  })

  import ev._

  val useWsDualDspShell = useDspMacPacking ||
    (useDspMacBlackBox && df == Dataflow.WS && columns % 2 == 0 && !tree_reduction)

  if (useWsDualDspShell && macPipelineCycles > 0) {
    // The timing-closure configuration groups eight WS lanes behind one token
    // pipeline. This removes four redundant valid/control/id/last pipelines
    // compared with four independent dual-lane shells.
    require(rows == 1 && columns == 8)
    require(df == Dataflow.WS && (useDspMacPacking ^ useDspMacBlackBox))
    require(!tree_reduction && !useDspOutputShift)
    require(inputType.getWidth == 8 && weightType.getWidth == 8 &&
      outputType.getWidth >= 20 && outputType.getWidth <= 48 && macPipelineCycles == 2)

    val c1 = Reg(Vec(columns, inputType))
    val c2 = Reg(Vec(columns, inputType))
    val selectedWeight = Wire(Vec(columns, weightType))
    val forwardedWeight = Wire(Vec(columns, inputType))
    val sharedValid = io.in_valid.head
    val sharedProp = io.in_control.head.propagate
    val packedMacs = Seq.fill(columns / 2)(Module(new PipelinedDualMac(
      packed = useDspMacPacking, outputWidth = outputType.getWidth)))

    // At possible SLR boundaries, move the bank-select mux between the two
    // forwarding registers. Latency and all output bits stay identical, while
    // the forwarding path no longer consists of a direct Laguna TX/RX pair.
    // Only boundary rows pay for the extra bank snapshot registers.
    val forwarded = if (retimeWeightForwarding) {
      val bank1 = FabricShiftRegister(c1, 1)
      val bank2 = FabricShiftRegister(c2, 1)
      val propagate = FabricShiftRegister(sharedProp, 1)
      FabricShiftRegister(Mux(propagate === 1.U, bank1, bank2), 1)
    } else {
      FabricShiftRegister(forwardedWeight, macPipelineCycles)
    }
    for (lane <- 1 until columns) {
      assert(io.in_valid(lane) === sharedValid)
      assert(io.in_control(lane).asUInt === io.in_control.head.asUInt)
      assert(io.in_id(lane) === io.in_id.head)
      assert(io.in_last(lane) === io.in_last.head)
    }

    for (lane <- 0 until columns) {
      selectedWeight(lane) := Mux(sharedProp === 1.U, c2(lane), c1(lane)).asTypeOf(weightType)
      forwardedWeight(lane) := Mux(sharedProp === 1.U, c1(lane), c2(lane))
      when (sharedValid) {
        when (sharedProp === 1.U) { c1(lane) := io.in_d(lane).asTypeOf(inputType) }
          .otherwise { c2(lane) := io.in_d(lane).asTypeOf(inputType) }
      }
      // MACs are feed-forward pipelines: bubble data cannot change a later
      // valid token. The delayed valid already qualifies the result and bank
      // writes. Avoid broadcasting valid to every partial-sum/weight bit.
      val mac = packedMacs(lane / 2)
      mac.io.a := io.in_a.head.asUInt.asSInt
      if (lane % 2 == 0) {
        mac.io.b0 := selectedWeight(lane).asUInt.asSInt
        mac.io.c0 := io.in_b(lane).asUInt.asSInt
        io.out_b(lane) := mac.io.d0.asTypeOf(outputType)
      } else {
        mac.io.b1 := selectedWeight(lane).asUInt.asSInt
        mac.io.c1 := io.in_b(lane).asUInt.asSInt
        io.out_b(lane) := mac.io.d1.asTypeOf(outputType)
      }
      io.out_c(lane) := forwarded(lane)
    }

    val tokenControl = FabricShiftRegister(io.in_control.head, macPipelineCycles)
    val tokenId = FabricShiftRegister(io.in_id.head, macPipelineCycles)
    val tokenLast = FabricShiftRegister(io.in_last.head, macPipelineCycles)
    val tokenValid = FabricShiftRegister.valid(sharedValid, macPipelineCycles)
    for (lane <- 0 until columns) {
      io.out_control(lane) := tokenControl
      io.out_id(lane) := tokenId
      io.out_last(lane) := tokenLast
      io.out_valid(lane) := tokenValid
    }
    io.out_a.head := FabricShiftRegister(io.in_a.head, macPipelineCycles)
    io.bad_dataflow := false.B
  } else if (useWsDualDspShell) {
    require(df == Dataflow.WS, "dual DSP lanes are only supported for WS-only arrays")
    require(columns % 2 == 0, "dual DSP lanes require an even tile column count")
    require(!tree_reduction, "dual DSP lanes do not support tree reduction")
    require(!useDspOutputShift, "dual DSP lanes do not support DSP output shifting")
    require(!(useDspMacPacking && useDspMacBlackBox),
      "select either packed or individual DSP MACs for a tile")

    val pairs = Seq.fill(rows, columns / 2)(Module(new WSDualPackedPE(
      inputType, weightType, outputType, accType, max_simultaneous_matmuls,
      packMultipliers = useDspMacPacking, pipelineCycles = macPipelineCycles)))
    require(macPipelineCycles == 0 || (rows == 1 && columns == 2))

    for (r <- 0 until rows; pairCol <- 0 until columns / 2) {
      val pair = pairs(r)(pairCol)
      pair.io.in_a := io.in_a(r)
      for (lane <- 0 until 2) {
        val c = pairCol * 2 + lane
        pair.io.in_b(lane) := (if (r == 0) io.in_b(c)
          else pairs(r - 1)(pairCol).io.out_b(lane))
        pair.io.in_d(lane) := (if (r == 0) io.in_d(c)
          else pairs(r - 1)(pairCol).io.out_c(lane))
        pair.io.in_control(lane) := (if (r == 0) io.in_control(c)
          else pairs(r - 1)(pairCol).io.out_control(lane))
        pair.io.in_valid(lane) := (if (r == 0) io.in_valid(c)
          else pairs(r - 1)(pairCol).io.out_valid(lane))
        pair.io.in_id(lane) := (if (r == 0) io.in_id(c)
          else pairs(r - 1)(pairCol).io.out_id(lane))
        pair.io.in_last(lane) := (if (r == 0) io.in_last(c)
          else pairs(r - 1)(pairCol).io.out_last(lane))
      }
    }

    for (c <- 0 until columns) {
      val pair = pairs(rows - 1)(c / 2)
      val lane = c % 2
      io.out_b(c) := pair.io.out_b(lane)
      io.out_c(c) := pair.io.out_c(lane)
      io.out_control(c) := pair.io.out_control(lane)
      io.out_id(c) := pair.io.out_id(lane)
      io.out_last(c) := pair.io.out_last(lane)
      io.out_valid(c) := pair.io.out_valid(lane)
    }
    for (r <- 0 until rows) {
      io.out_a(r) := pairs(r).last.io.out_a
    }
    io.bad_dataflow := pairs.flatten.map(_.io.bad_dataflow).reduce(_ || _)
  } else {
    val tile = Seq.fill(rows, columns)(Module(new PE(
      inputType, weightType, outputType, accType, df, max_simultaneous_matmuls,
      useDspOutputShift, useDspMacBlackBox)))
    val tileT = tile.transpose

  // TODO: abstract hori/vert broadcast, all these connections look the same
  // Broadcast 'a' horizontally across the Tile
  for (r <- 0 until rows) {
    tile(r).foldLeft(io.in_a(r)) {
      case (in_a, pe) =>
        pe.io.in_a := in_a
        pe.io.out_a
    }
  }

  // Broadcast 'b' vertically across the Tile
  for (c <- 0 until columns) {
    tileT(c).foldLeft(io.in_b(c)) {
      case (in_b, pe) =>
        pe.io.in_b := (if (tree_reduction) in_b.zero else in_b)
        pe.io.out_b
    }
  }

  // Broadcast 'd' vertically across the Tile
  for (c <- 0 until columns) {
    tileT(c).foldLeft(io.in_d(c)) {
      case (in_d, pe) =>
        pe.io.in_d := in_d
        pe.io.out_c
    }
  }

  // Broadcast 'control' vertically across the Tile
  for (c <- 0 until columns) {
    tileT(c).foldLeft(io.in_control(c)) {
      case (in_ctrl, pe) =>
        pe.io.in_control := in_ctrl
        pe.io.out_control
    }
  }

  // Broadcast 'garbage' vertically across the Tile
  for (c <- 0 until columns) {
    tileT(c).foldLeft(io.in_valid(c)) {
      case (v, pe) =>
        pe.io.in_valid := v
        pe.io.out_valid
    }
  }

  // Broadcast 'id' vertically across the Tile
  for (c <- 0 until columns) {
    tileT(c).foldLeft(io.in_id(c)) {
      case (id, pe) =>
        pe.io.in_id := id
        pe.io.out_id
    }
  }

  // Broadcast 'last' vertically across the Tile
  for (c <- 0 until columns) {
    tileT(c).foldLeft(io.in_last(c)) {
      case (last, pe) =>
        pe.io.in_last := last
        pe.io.out_last
    }
  }

  // Drive the Tile's bottom IO
  for (c <- 0 until columns) {
    io.out_c(c) := tile(rows-1)(c).io.out_c
    io.out_control(c) := tile(rows-1)(c).io.out_control
    io.out_id(c) := tile(rows-1)(c).io.out_id
    io.out_last(c) := tile(rows-1)(c).io.out_last
    io.out_valid(c) := tile(rows-1)(c).io.out_valid

    io.out_b(c) := {
      if (tree_reduction) {
        val prods = tileT(c).map(_.io.out_b)
        accumulateTree(prods :+ io.in_b(c))
      } else {
        tile(rows - 1)(c).io.out_b
      }
    }
  }
    io.bad_dataflow := tile.map(_.map(_.io.bad_dataflow).reduce(_||_)).reduce(_||_)

  // Drive the Tile's right IO
    for (r <- 0 until rows) {
      io.out_a(r) := tile(r)(columns-1).io.out_a
    }
  }
}
