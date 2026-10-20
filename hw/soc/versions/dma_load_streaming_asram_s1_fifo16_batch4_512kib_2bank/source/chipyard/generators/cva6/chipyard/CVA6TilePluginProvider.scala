package chipyard.config

import cva6.CVA6TileAttachParams
import freechips.rocketchip.subsystem.HierarchicalElementPortParamsLike

// Discovered via Reflections from the chipyard.* package.
class CVA6TilePluginProvider extends TilePluginProvider {
  override def tileTraceEnableInjectors = Seq({
    case tp: CVA6TileAttachParams => tp.copy(tileParams = tp.tileParams.copy(trace = true))
  })

  override def tileTraceDisableInjectors = Seq({
    case tp: CVA6TileAttachParams => tp.copy(tileParams = tp.tileParams.copy(trace = false))
  })

  override def tilePrefetchInjectors(make: (Int, HierarchicalElementPortParamsLike) => HierarchicalElementPortParamsLike) = Seq({
    case tp: CVA6TileAttachParams => tp.copy(crossingParams = tp.crossingParams.copy(
      master = make(tp.tileParams.tileId, tp.crossingParams.master)))
  })
}
