package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config
import scala.collection.immutable.ListMap

import constellation.channel._
import constellation.noc._
import constellation.protocol._
import constellation.routing._
import constellation.topology._

/** A separate 2-bank L2 + SBus NoC variant of the routed dual-Gemmini64 baseline. */
class TaihangSoC1Rocket1RVV2Gemmini64x64PackedFullOps256Bit2BankSbusNoCConfig extends Config(
  new freechips.rocketchip.subsystem.WithNBanks(2) ++
  new constellation.soc.WithSbusNoC(SimpleTLNoCParams(
    DiplomaticNetworkNodeMapping(
      inNodeMapping = ListMap(
        "Core 0" -> 0,
        "stream-reader[0]" -> 0,
        "stream-reader[1]" -> 1,
        "slave-port-axi4" -> 1),
      outNodeMapping = ListMap(
        "system[0]" -> 2,
        "system[1]" -> 3,
        "pbus" -> 1)),
    NoCParams(
      topology = TerminalRouter(BidirectionalLine(4)),
      channelParamGen = (a, b) => UserChannelParams(Seq.fill(8) { UserVirtualChannelParams(4) }),
      routingRelation = NonblockingVirtualSubnetworksRouting(
        TerminalRouterRouting(BidirectionalLineRouting()), 5, 1))
  )) ++
  new TaihangSoC1Rocket1RVV2Gemmini64x64PackedFullOps256BitConfig)

/** Same two-bank NoC topology with the original 512-KiB total L2 capacity. */
class TaihangSoC1Rocket1RVV2Gemmini64x64PackedFullOps256Bit2Bank512KiBSbusNoCConfig extends Config(
  new TaihangSoC1Rocket1RVV2Gemmini64x64PackedFullOps256Bit2BankSbusNoCConfig ++
  // InclusiveCacheParams uses up(SubsystemBankedCoherenceKey) to size each bank.
  new freechips.rocketchip.subsystem.WithNBanks(2))
