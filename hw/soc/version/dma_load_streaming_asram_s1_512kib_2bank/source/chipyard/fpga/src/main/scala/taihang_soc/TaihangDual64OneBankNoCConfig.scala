package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config
import scala.collection.immutable.ListMap

import constellation.channel._
import constellation.noc._
import constellation.protocol._
import constellation.routing._
import constellation.topology._

/** One 512-KiB L2 bank with the same four-router SBus NoC as the two-bank variants. */
class TaihangSoC1Rocket1RVV2Gemmini64x64PackedFullOps256Bit1BankSbusNoCConfig extends Config(
  new constellation.soc.WithSbusNoC(SimpleTLNoCParams(
    DiplomaticNetworkNodeMapping(
      inNodeMapping = ListMap(
        "Core 0" -> 0,
        "stream-reader[0]" -> 0,
        "stream-reader[1]" -> 1,
        "slave-port-axi4" -> 1),
      outNodeMapping = ListMap(
        "system[0]" -> 2,
        "pbus" -> 1)),
    NoCParams(
      topology = TerminalRouter(BidirectionalLine(4)),
      channelParamGen = (a, b) => UserChannelParams(Seq.fill(8) { UserVirtualChannelParams(4) }),
      routingRelation = NonblockingVirtualSubnetworksRouting(
        TerminalRouterRouting(BidirectionalLineRouting()), 5, 1))
  )) ++
  new TaihangSoC1Rocket1RVV2Gemmini64x64PackedFullOps256BitConfig)
