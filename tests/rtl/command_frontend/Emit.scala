package frontendtest

import circt.stage.ChiselStage
import freechips.rocketchip.tile.commandfrontend._

object Emit extends App {
  val target = args(0)
  val kind = args(1)
  val options = Array("--target-dir", target)
  val firtool = Array("--disable-all-randomization", "--lowering-options=disallowLocalVariables,noAlwaysComb")
  kind match {
    case "engine" => ChiselStage.emitSystemVerilogFile(new CommandFrontendEngine, options, firtool)
    case "cluster" => ChiselStage.emitSystemVerilogFile(new CommandFrontendCluster, options, firtool)
    case "memory" => ChiselStage.emitSystemVerilogFile(new CommandFrontendMemoryMux, options, firtool)
  }
}
