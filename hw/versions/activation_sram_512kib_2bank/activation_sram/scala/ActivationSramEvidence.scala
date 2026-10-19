package freechips.rocketchip.tile.commandfrontend

import freechips.rocketchip.tilelink._
import freechips.rocketchip.diplomacy.RegionType
import freechips.rocketchip.util.ElaborationArtefacts

/** Negotiation evidence is separate from CPU/RVV execution. No new JSON dependency. */
object ActivationSramEvidence {
  private def quote(s: String): String = "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
  private def obj(fields: (String, String)*): String = fields.map { case (k,v) => quote(k) + ":" + v }.mkString("{", ",", "}")
  private def arr(values: Seq[String]): String = values.mkString("[", ",", "]")
  def emit(cpu: TLEdgeOut, external: TLEdgeOut, banks: Seq[ActivationSramTL],
           frontends: Seq[CommandFrontendTL], rvvUsesDcache: Boolean): Unit = {
    def managers(edge: TLEdgeOut): String = arr(edge.manager.managers.map { m =>
      obj("path" -> quote(m.nodePath.map(_.name).mkString("/")),
        "address_sets" -> arr(m.address.map(a => obj("base" -> quote(a.base.toString(16)), "mask" -> quote(a.mask.toString(16))))),
        "cacheable" -> (!m.supportsAcquireB.none).toString, "executable" -> m.executable.toString,
        "readable" -> (!m.supportsGet.none).toString, "writable" -> (!m.supportsPutFull.none).toString,
        "partial_write" -> (!m.supportsPutPartial.none).toString)
    })
    for(base <- ActivationSramMap.bases) {
      val visible = cpu.manager.managers.filter(_.address.exists(_.contains(base)))
      require(visible.size == 1, "CPU must see exactly one ASRAM manager")
      val m = visible.head
      require(m.supportsAcquireB.none && m.supportsAcquireT.none && !m.executable)
      require(!m.supportsGet.none && !m.supportsPutFull.none && !m.supportsPutPartial.none)
      require(m.supportsArithmetic.none && m.supportsLogical.none && m.regionType == RegionType.IDEMPOTENT)
    }
    require(!external.manager.managers.exists(m => m.address.exists(a =>
      ActivationSramMap.reserved.exists(_.overlaps(a)))), "ASRAM address escaped into shared external path")
    val rows = (0 until 3).map { i =>
      val bank = banks(i)
      val dma = frontends(i).node.edges.out.head
      val local = dma.manager.managers.filter(_.address.exists(_.contains(ActivationSramMap.bases(i))))
      require(local.size == 1 && !local.head.supportsGet.none)
      obj("frontend_lane" -> i.toString, "native_opcode" -> Seq(11, 43, 91)(i).toString,
        "build_rocc_index" -> i.toString, "target_slr" -> Seq(0, 1, 3)(i).toString,
        "dma_node_path" -> quote(dma.client.masters.map(_.name).mkString(",")),
        "cpu_service_node_path" -> quote(bank.serviceNode.edges.in.head.manager.managers.head.nodePath.map(_.name).mkString("/")),
        "local_manager_path" -> quote(local.head.nodePath.map(_.name).mkString("/")),
        "external_manager_path" -> quote(external.manager.managers.map(_.nodePath.map(_.name).mkString("/")).mkString(",")),
        "visible_dma_managers" -> managers(dma))
    }
    ElaborationArtefacts.add("activation_sram_topology.json", obj(
      "status" -> quote("NEGOTIATED"), "three_lane_behavior" -> quote("NOT_RUN"), "lanes" -> arr(rows)))
    ElaborationArtefacts.add("activation_sram_pma.json", obj(
      "status" -> quote("PMA_NEGOTIATION_PASS"), "cpu_execution" -> quote("NOT_RUN"), "rvv_execution" -> quote("NOT_RUN"),
      "rvv_uses_dcache" -> rvvUsesDcache.toString,
      "cpu_managers" -> managers(cpu), "external_managers" -> managers(external)))
  }
}
