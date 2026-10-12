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

import org.chipsalliance.cde.config._
import freechips.rocketchip.diplomacy._

import freechips.rocketchip.subsystem.{SubsystemBankedCoherenceKey, MemoryParallelPerfKey, MemoryParallelPerf}
import freechips.rocketchip.regmapper._
import freechips.rocketchip.tilelink._

class InclusiveCache(
  val cache: CacheParameters,
  val micro: InclusiveCacheMicroParameters,
  control: Option[InclusiveCacheControlParameters] = None
  )(implicit p: Parameters)
    extends LazyModule
{
  val access = TransferSizes(1, cache.blockBytes)
  val xfer = TransferSizes(cache.blockBytes, cache.blockBytes)
  val atom = TransferSizes(1, cache.beatBytes)

  var resourcesOpt: Option[ResourceBindings] = None

  val device: SimpleDevice = new SimpleDevice("cache-controller", Seq("sifive,inclusivecache0", "cache")) {
    def ofInt(x: Int) = Seq(ResourceInt(BigInt(x)))

    override def describe(resources: ResourceBindings): Description = {
      resourcesOpt = Some(resources)

      val Description(name, mapping) = super.describe(resources)
      // Find the outer caches
      val outer = node.edges.out
        .flatMap(_.manager.managers)
        .filter(_.supportsAcquireB)
        .flatMap(_.resources.headOption)
        .map(_.owner.label)
        .distinct
      val nextlevel: Option[(String, Seq[ResourceValue])] =
        if (outer.isEmpty) {
          None
        } else {
          Some("next-level-cache" -> outer.map(l => ResourceReference(l)).toList)
        }

      val extra = Map(
        "cache-level"            -> ofInt(2),
        "cache-unified"          -> Nil,
        "cache-size"             -> ofInt(cache.sizeBytes * node.edges.in.size),
        "cache-sets"             -> ofInt(cache.sets * node.edges.in.size),
        "cache-block-size"       -> ofInt(cache.blockBytes),
        "sifive,mshr-count"      -> ofInt(InclusiveCacheParameters.all_mshrs(cache, micro)))
      Description(name, mapping ++ extra ++ nextlevel)
    }
  }

  val node: TLAdapterNode = TLAdapterNode(
    clientFn  = { _ => TLClientPortParameters(Seq(TLClientParameters(
      name          = s"L${cache.level} InclusiveCache",
      sourceId      = IdRange(0, InclusiveCacheParameters.out_mshrs(cache, micro)),
      supportsProbe = xfer)))
    },
    managerFn = { m => TLManagerPortParameters(
      managers = m.managers.map { m => m.copy(
        regionType         = if (m.regionType >= RegionType.UNCACHED) RegionType.CACHED else m.regionType,
        resources          = Resource(device, "caches") +: m.resources,
        supportsAcquireB   = xfer,
        supportsAcquireT   = if (m.supportsAcquireT) xfer else TransferSizes.none,
        supportsArithmetic = if (m.supportsAcquireT) atom else TransferSizes.none,
        supportsLogical    = if (m.supportsAcquireT) atom else TransferSizes.none,
        supportsGet        = access,
        supportsPutFull    = if (m.supportsAcquireT) access else TransferSizes.none,
        supportsPutPartial = if (m.supportsAcquireT) access else TransferSizes.none,
        supportsHint       = access,
        alwaysGrantsT      = false,
        fifoId             = None)
      },
      beatBytes  = cache.beatBytes,
      endSinkId  = InclusiveCacheParameters.all_mshrs(cache, micro),
      minLatency = 2)
    })

  val ctrls = control.map { c =>
    val nCtrls = if (c.bankedControl) p(SubsystemBankedCoherenceKey).nBanks else 1
    Seq.tabulate(nCtrls) { i => LazyModule(new InclusiveCacheControl(this,
      c.copy(address = c.address + i * InclusiveCacheParameters.L2ControlSize))) }
  }.getOrElse(Nil)

  val perf = if(p(MemoryParallelPerfKey)) Some(LazyModule(new MemoryParallelPerf(control.get.beatBytes))) else None

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    // If you have a control port, you must have at least one cache port
    require (ctrls.isEmpty || !node.edges.in.isEmpty)

    // Extract the client IdRanges; must be the same on all ports!
    val clientIds = node.edges.in.headOption.map(_.client.clients.map(_.sourceId).sortBy(_.start))
    node.edges.in.foreach { e => require(e.client.clients.map(_.sourceId).sortBy(_.start) == clientIds.get) }

    // Use the natural ordering of clients (just like in Directory)
    node.edges.in.headOption.foreach { n =>
      println(s"L${cache.level} InclusiveCache Client Map:")
      n.client.clients.zipWithIndex.foreach { case (c,i) =>
        println(s"\t${i} <= ${c.name}")
      }
      println("")
    }

    // Create the L2 Banks
    val mods = (node.in zip node.out) map { case ((in, edgeIn), (out, edgeOut)) =>
      edgeOut.manager.managers.foreach { m =>
        require (m.supportsAcquireB.contains(xfer),
          s"All managers behind the L2 must support acquireB($xfer) " +
          s"but ${m.name} only supports (${m.supportsAcquireB})!")
        if (m.supportsAcquireT) require (m.supportsAcquireT.contains(xfer),
          s"Any probing managers behind the L2 must support acquireT($xfer) " +
          s"but ${m.name} only supports (${m.supportsAcquireT})!")
      }

      val params = InclusiveCacheParameters(cache, micro, !ctrls.isEmpty, edgeIn, edgeOut)
      val scheduler = Module(new InclusiveCacheBankScheduler(params, p(MemoryParallelPerfKey))).suggestName("inclusive_cache_bank_sched")

      scheduler.io.in <> in
      out <> scheduler.io.out
      scheduler.io.ways := DontCare
      scheduler.io.divs := DontCare

      // Tie down default values in case there is no controller
      scheduler.io.req.valid := false.B
      scheduler.io.req.bits.address := 0.U
      scheduler.io.req.bits.invalidate := false.B
      scheduler.io.resp.ready := true.B


      // Fix-up the missing addresses. We do this here so that the Scheduler can be
      // deduplicated by Firrtl to make hierarchical place-and-route easier.
      out.a.bits.address := params.restoreAddress(scheduler.io.out.a.bits.address)
      in .b.bits.address := params.restoreAddress(scheduler.io.in .b.bits.address)
      out.c.bits.address := params.restoreAddress(scheduler.io.out.c.bits.address)

      scheduler
    }

    perf.foreach { perf =>
      perf.module.io.events := 0.U.asTypeOf(perf.module.io.events)
      require(mods.size == 2 && cache.sets == 512 && cache.ways == 8 && cache.blockBytes == 64)
      require(InclusiveCacheParameters.out_mshrs(cache, micro) == 32)
      val clients = node.edges.in.head.client.clients
      val streams = clients.filter(c => c.name == "stream-reader" || c.name == "stream-writer")
      require(streams.size == 6, "Expected three Gemmini reader/writer pairs")
      streams.grouped(2).foreach(pair => require(pair.map(_.name) == Seq("stream-reader", "stream-writer")))
      println("V3_TENSOR_L2_CLIENTS=" + clients.map(c => s"${c.name}:${c.sourceId.start}-${c.sourceId.end}").mkString(","))
      val tensorClients = clients.filter(_.name == "tensor-writer")
      val groups = streams.grouped(2).toSeq ++ Seq(
        clients.filter(_.name.startsWith("Core ")),
        clients.filter(_.name.startsWith("slave-port-axi4"))) ++
        (if (tensorClients.nonEmpty) Seq(tensorClients) else Nil)
      require(groups.size == (if (tensorClients.nonEmpty) 6 else 5) && groups.forall(_.nonEmpty))
      require(clients.filterNot(groups.flatten.contains).forall(_.name == "debug"), "Unclassified L2 client")
      require(tensorClients.size <= 1, "Expected one independent Tensor writer")
      val blockIds = Seq(0, 1, 2, 3, 4, 13)
      println("MEMORY_PARALLEL_V3 source ranges (worker0..2, CPU, FBus): " +
        groups.map(_.map(c => s"${c.name}:${c.sourceId.start}-${c.sourceId.end}").mkString(",")).mkString(";"))
      val observations = node.in.zipWithIndex.map { case ((in, edge), bank) =>
        val firstA = edge.first(in.a)
        val doneD = edge.done(in.d)
        groups.map { clients =>
          val e = Wire(Vec(32, UInt(16.W)))
          e := 0.U.asTypeOf(e)
          val a = clients.map(_.sourceId.contains(in.a.bits.source)).reduce(_||_)
          val d = clients.map(_.sourceId.contains(in.d.bits.source)).reduce(_||_)
          val c = clients.map(_.sourceId.contains(in.c.bits.source)).reduce(_||_)
          val read = in.a.bits.opcode === TLMessages.Get || in.a.bits.opcode === TLMessages.AcquireBlock
          val write = in.a.bits.opcode === TLMessages.PutFullData || in.a.bits.opcode === TLMessages.PutPartialData
          val req = in.a.fire && firstA && a
          e(1) := req
          e(2) := req && read
          e(3) := req && write
          e(4) := Mux(req && read, 1.U << in.a.bits.size, 0.U)
          e(5) := Mux(in.a.fire && a && edge.hasData(in.a.bits), PopCount(in.a.bits.mask), 0.U)
          e(6) := in.a.valid && !in.a.ready && a
          e(7) := Mux(in.d.fire && d && edge.hasData(in.d.bits),
            Mux(in.d.bits.size < log2Ceil(edge.manager.beatBytes).U, 1.U << in.d.bits.size, edge.manager.beatBytes.U), 0.U)
          e(8) := in.d.valid && !in.d.ready && d
          e(9) := in.c.fire && c
          e(10) := in.c.valid && !in.c.ready && c
          e(11 + bank) := req
          e(13) := doneD && d
          e
        }
      }
      for(i <- groups.indices; j <- 0 until 32) {
        perf.module.io.events(blockIds(i))(j) := (if(j == 0) 1.U else observations.map(_(i)(j)).reduce(_+&_))
      }
      if (tensorClients.isEmpty) perf.module.io.events(13) := 0.U.asTypeOf(perf.module.io.events(13))
      for(i <- 0 until 2) {
        perf.module.io.events(5+i) := mods(i).io.perf.get
        perf.module.io.events(5+i)(19) := node.in.map(_._1.d.fire).reduce(_&&_)
      }
    }

    ctrls.foreach { ctrl =>
      ctrl.module.io.flush_req.ready := false.B
      ctrl.module.io.flush_resp := false.B
      ctrl.module.io.flush_match := false.B
    }

    mods.zip(node.edges.in).zipWithIndex.foreach { case ((sched, edgeIn), i) =>
      val ctrl = if (ctrls.size > 1) Some(ctrls(i)) else ctrls.headOption
      ctrl.foreach { ctrl => {
        val contained = edgeIn.manager.managers.flatMap(_.address)
          .map(_.contains(ctrl.module.io.flush_req.bits)).reduce(_||_)
        when (contained) { ctrl.module.io.flush_match := true.B }

        sched.io.req.valid := contained && ctrl.module.io.flush_req.valid
        sched.io.req.bits.address := ctrl.module.io.flush_req.bits
        sched.io.req.bits.invalidate := ctrl.module.io.invalidate_req
        when (contained && sched.io.req.ready) { ctrl.module.io.flush_req.ready := true.B }

        when (sched.io.resp.valid) { ctrl.module.io.flush_resp := true.B }
        sched.io.resp.ready := true.B
      }}
    }

    def json = s"""{"banks":[${mods.map(_.json).mkString(",")}]}"""
  }
}
