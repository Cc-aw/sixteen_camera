package gemmini

import chisel3._
import chiseltest._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.tile.{TileKey, RocketTileParams, TileVisibilityNodeKey}
import freechips.rocketchip.diplomacy.{AddressSet, LazyModule, LazyModuleImp, IdRange, TransferSizes}
import freechips.rocketchip.tilelink._
import chipyard.fpga.xcvu13p_gemmini_32x32_packed_inference_ram.XCVU13PGemmini32x32PackedInferenceRamConfigs

/** Independent arithmetic oracle and request-order scoreboard. Tests real
  * elastic queues with full/stalled/reset/fault traffic, not a cycle mirror.
  */
object DmaLoadIngressTest extends App {
  val shape = LazyModule(new LazyModule()(Parameters.empty) {
    val visible = TLEphemeralNode()
    val client = TLClientNode(Seq(TLMasterPortParameters.v1(Seq(TLClientParameters(
      name="ingress-test", sourceId=IdRange(0,32))))))
    val manager = TLManagerNode(Seq(TLSlavePortParameters.v1(Seq(TLSlaveParameters.v1(
      address=Seq(AddressSet(BigInt("80000000",16),BigInt("7fffffff",16))),
      supportsGet=TransferSizes(1,64))),beatBytes=32)))
    manager := visible; visible := client
    lazy val module = new LazyModuleImp(this) {}
  })
  implicit val p: Parameters = Parameters.empty.alterPartial {
    case freechips.rocketchip.tile.commandfrontend.ActivationSramKey => true
    case TileKey => RocketTileParams()
    case TileVisibilityNodeKey => shape.visible
  }
  val cfg = XCVU13PGemmini32x32PackedInferenceRamConfigs.config.copy(
    dma_load_runtime_enable=true,dma_load_streaming_enable=true)
  def zero(d: Data): Unit = d match {
    case e: NormCmd.Type => e.poke(NormCmd.RESET)
    case u: UInt => u.poke(0.U)
    case s: SInt => s.poke(0.S)
    case v: Vec[_] => v.foreach(zero)
    case r: Record => r.elements.values.foreach(zero)
  }
  def snapshot(d: Data): Vector[BigInt] = d match {
    case e: NormCmd.Type => Vector(e.peek().litValue)
    case u: UInt => Vector(u.peek().litValue)
    case s: SInt => Vector(s.peek().litValue)
    case v: Vec[_] => v.toVector.flatMap(snapshot)
    case r: Record => r.elements.values.toVector.flatMap(snapshot)
  }
  val rng = new scala.util.Random(221003)
  RawTester.test(new DmaLoadIngress(cfg), Seq(chiseltest.simulator.IcarusBackendAnnotation)) { d =>
    val q = scala.collection.mutable.Queue.empty[(Vector[BigInt],Boolean)]
    var expectedEligible = false
    var accepted=0; var retired=0; var stalls=0
    var previousStall: Option[(Vector[BigInt],Boolean)] = None
    def drive(n:Int):Unit = {
      val b=d.io.in.bits; zero(b)
      val cols=Vector(0,1,3,7,12,16,31,32,33,65535)(n%10)
      val rows=Vector(0,1,2,3,31,32,33,63)((n/10)%8)
      val pixels=Vector(0,1,2,3,6,32,33,255)((n/3)%8)
      val stride=Vector(BigInt(cols),BigInt(cols+1),BigInt(0),BigInt(1)<<39)((n/7)%4)
      val address=Vector(BigInt("80000000",16),BigInt("fffffff0",16),
        BigInt("20000000",16),BigInt("2023fff0",16),BigInt("20400000",16),
        BigInt("20800000",16),BigInt("20c00000",16),BigInt("7fffffff",16),
        (BigInt(1)<<40)-1)((n/5)%9)
      val half=cfg.local_addr_t.spRows/2
      val local=Vector(0,half-1,half, cfg.local_addr_t.spRows-1,64)((n/11)%5)
      val zeros=n%13==0;val acc=n%17==0;val accumulate=n%19==0
      val wide=n%23==0;val dual=n%29==0;val high=n%31==0;val repeats=if(n%37==0)1 else 0
      b.vaddr.poke(address.U);b.cols.poke(cols.U);b.cmd_rows.poke(rows.U)
      b.cmd_stride_bytes.poke(stride.U);b.pixel_repeats.poke(pixels.U)
      b.laddr.data.poke(local.U);b.laddr.is_acc_addr.poke(acc.B);b.laddr.accumulate.poke(accumulate.B)
      b.all_zeros.poke(zeros.B);b.has_acc_bitwidth.poke(wide.B);b.dual.poke(dual.B)
      b.lane_high.poke(high.B);b.repeats.poke(repeats.U)
      b.row_index.poke((n%32).U);b.cmd_id.poke((n%256).U);b.scale.poke((n%65536).U)
      b.cmd_first.poke((n%32==0).B);b.cmd_last.poke((n%32==31).B)
      b.block_stride.poke((n%65536).U);b.status.prv.poke((n%4).U)
      // Unbounded software arithmetic must not wrap at the physical address
      // width. Invalid rows cannot become eligible through overflow.
      val end=address+BigInt(rows-1)*stride+cols
      val localEnd=local+rows-1
      val inHalf=localEnd<cfg.local_addr_t.spRows && ((local<half)==(localEnd<half))
      val ddr=address>=BigInt("80000000",16) && end<=BigInt("100000000",16)
      val asram=Seq("20000000","20400000","20800000").exists { a =>
        val base=BigInt(a,16); address>=base && end>address && end<=base+2359296 }
      expectedEligible = !dual && !high && !acc && !accumulate && !wide && repeats==0 &&
        cols>0 && cols<32 && rows>0 && rows<=32 && pixels>0 &&
        pixels<=cfg.dma_load_max_pixel_repeats && pixels*cols<=32 && inHalf &&
        (zeros || ((ddr||asram) && ((stride==cols && rows>1)||pixels>1)))
    }
    def step():Unit = {
      val valid=d.io.out.valid.peek().litToBoolean
      val ready=d.io.out.ready.peek().litToBoolean
      if(valid) {
        val token=(snapshot(d.io.out.bits.request),d.io.out.bits.eligible.peek().litToBoolean)
        previousStall.foreach(s=>assert(s==token,"changed a stalled output"))
        assert(q.nonEmpty && q.front==token,"request/eligibility mismatch or ordering error")
        previousStall=if(ready)None else Some(token)
        if(ready){q.dequeue();retired+=1}else stalls+=1
      } else assert(previousStall.isEmpty,"lost a stalled output")
      if(d.io.in.valid.peek().litToBoolean && d.io.in.ready.peek().litToBoolean){
        q.enqueue((snapshot(d.io.in.bits),expectedEligible));accepted+=1
      }
      d.clock.step()
    }
    zero(d.io.in.bits);d.io.in.valid.poke(false.B);d.io.out.ready.poke(false.B);d.io.fault.poke(false.B)
    d.reset.poke(true.B);d.clock.step(4);d.reset.poke(false.B)
    var sent=0;var cycles=0
    while((sent<2400 || q.nonEmpty) && cycles<15000){
      if(sent<2400)drive(sent)
      d.io.in.valid.poke((sent<2400 && cycles%9!=2).B)
      d.io.out.ready.poke((cycles%23>=7 && rng.nextInt(5)!=0).B)
      val fire=d.io.in.valid.peek().litToBoolean && d.io.in.ready.peek().litToBoolean
      step();if(fire)sent+=1;cycles+=1
    }
    assert(sent==2400 && q.isEmpty && accepted==retired && stalls>0)
    d.io.out.ready.poke(true.B);d.io.in.valid.poke(true.B)
    for(i<-0 until 128){drive(i+2500);d.io.in.ready.expect(true.B);step()}
    d.io.in.valid.poke(false.B);for(_<-0 until 5)step();assert(q.isEmpty)
    // Fill both stages, latch fault with pending work, then recover by reset.
    d.io.out.ready.poke(false.B);d.io.in.valid.poke(true.B)
    for(i<-0 until 10){drive(i+3000);step()}
    d.io.in.ready.expect(false.B);d.io.busy.expect(true.B)
    d.io.fault.poke(true.B);d.io.out.ready.poke(true.B)
    for(_<-0 until 8){d.io.in.ready.expect(false.B);d.io.out.valid.expect(false.B);d.clock.step()}
    d.reset.poke(true.B);d.clock.step(4);d.reset.poke(false.B)
    q.clear();previousStall=None;d.io.fault.poke(false.B);d.io.in.valid.poke(false.B)
    d.io.out.valid.expect(false.B);d.io.busy.expect(false.B)
    for(i<-0 until 32){drive(i+4000);d.io.in.valid.poke(true.B);step()}
    d.io.in.valid.poke(false.B);for(_<-0 until 5)step();assert(q.isEmpty)
    println(s"DMA_LOAD_INGRESS_PASS random_requests=2400 full_rate=128 stalled_cycles=$stalls fault_reset=checked")
  }
}
