package chipyard.config

import sodor.common.SodorTileAttachParams
import freechips.rocketchip.subsystem.HierarchicalElementPortParamsLike

class SodorTilePluginProvider extends TilePluginProvider {
  override def tileTraceEnableInjectors = Seq({
    case tp: SodorTileAttachParams => tp.copy(tileParams = tp.tileParams.copy(trace = true))
  })

  override def tileTraceDisableInjectors = Seq({
    case tp: SodorTileAttachParams => tp.copy(tileParams = tp.tileParams.copy(trace = false))
  })

  override def tilePrefetchInjectors(make: (Int, HierarchicalElementPortParamsLike) => HierarchicalElementPortParamsLike) = Seq({
    case tp: SodorTileAttachParams => tp.copy(crossingParams = tp.crossingParams.copy(
      master = make(tp.tileParams.tileId, tp.crossingParams.master)))
  })
}

