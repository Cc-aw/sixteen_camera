package gemmini

import chisel3._
import chisel3.util._
import chiseltest._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.tile.{TileKey, RocketTileParams, TileVisibilityNodeKey}
import freechips.rocketchip.diplomacy.{AddressSet, LazyModule, LazyModuleImp, IdRange, TransferSizes}
import freechips.rocketchip.tilelink._
import chipyard.fpga.xcvu13p_gemmini_32x32_packed_inference_ram.XCVU13PGemmini32x32PackedInferenceRamConfigs

object DmaLoadStreamingTest extends App {
  val shape = LazyModule(new LazyModule()(Parameters.empty) {
    val visible = TLEphemeralNode()
    val client = TLClientNode(Seq(TLMasterPortParameters.v1(Seq(TLClientParameters(
      name="dma-load-test", sourceId=IdRange(0, 32))))))
    val manager = TLManagerNode(Seq(TLSlavePortParameters.v1(Seq(TLSlaveParameters.v1(
      address=Seq(AddressSet(BigInt("80000000",16), BigInt("7fffffff",16))),
      supportsGet=TransferSizes(1,64))), beatBytes=32)))
    manager := visible; visible := client
    lazy val module = new LazyModuleImp(this) {}
  })
  implicit val p: Parameters = Parameters.empty.alterPartial {
    case TileKey => RocketTileParams()
    case TileVisibilityNodeKey => shape.visible
  }
  val backend = Seq(chiseltest.simulator.IcarusBackendAnnotation)
  def zero(data: Data): Unit = data match {
    case e: NormCmd.Type => e.poke(NormCmd.RESET)
    case b: Bool => b.poke(false.B)
    case u: UInt => u.poke(0.U)
    case s: SInt => s.poke(0.S)
    case v: Vec[_] => v.foreach(zero)
    case r: Record => r.elements.values.foreach(zero)
  }
  def reset(d: Module): Unit = { d.reset.poke(true.B); d.clock.step(4); d.reset.poke(false.B) }
  val cfg = XCVU13PGemmini32x32PackedInferenceRamConfigs.config.copy(dma_load_runtime_enable=true, dma_load_streaming_enable=true)


  for(streaming <- Seq(false,true)) RawTester.test(new DmaLoadGroup(cfg.copy(dma_load_streaming_enable=streaming)),backend) { d =>
    for(mode <- Seq(1,2,3); c <- Seq(3,12); faultKind <- 0 until (if(streaming)5 else 1)) {
      val n=32;val pixels=if(c==3)6 else 2
      zero(d.io.in.bits);zero(d.io.fragment.bits);zero(d.io.completed.bits)
      d.io.in.valid.poke(false.B);d.io.fragment.valid.poke(false.B);d.io.completed.valid.poke(false.B)
      d.io.request.ready.poke(true.B);d.io.replay.ready.poke(true.B);d.io.readerFault.poke(false.B)
      d.io.mode.poke(mode.U);d.io.counter.external_reset.poke(false.B);reset(d)
      var cycle=0;var requests=Vector.empty[(Int,Int)];var replays=0;var credits=0
      var creditQueue=Vector.empty[(Int,Int)];var early=0;var returned=0
      def tick():Unit={
        val finalCredit=creditQueue.nonEmpty && credits+creditQueue.head._2==n*c
        val creditValid=creditQueue.nonEmpty && creditQueue.head._1<=cycle &&
          (!finalCredit || d.io.terminalReady(0).peek().litToBoolean)
        d.io.completed.valid.poke(creditValid.B);zero(d.io.completed.bits)
        if(creditValid){d.io.completed.bits.bytes.poke(creditQueue.head._2.U);credits+=creditQueue.head._2;creditQueue=creditQueue.tail}
        if(d.io.request.valid.peek().litToBoolean && d.io.request.ready.peek().litToBoolean)
          requests :+= ((d.io.request.bits.group_offset.peek().litValue.toInt,d.io.request.bits.len.peek().litValue.toInt))
        if(d.io.replay.valid.peek().litToBoolean && d.io.replay.ready.peek().litToBoolean){
          val b=d.io.replay.bits;b.addr.expect((64+replays).U);b.len.expect(c.U)
          for(j<-0 until 32)assert(((b.data.peek().litValue>>(8*j))&255)==(if(j<c)(replays*c+j)&255 else 0))
          if(returned<n*c)early+=1
          replays+=1
          if(mode==1)creditQueue :+= ((cycle+8,c))
          else if(replays==n)creditQueue :+= ((cycle+8,n*c))
        }
        if(d.io.fragment.valid.peek().litToBoolean && d.io.fragment.ready.peek().litToBoolean)
          returned+=d.io.fragment.bits.bytes.peek().litValue.toInt
        d.clock.step();cycle+=1
      }
      for(r<-0 until n){
        zero(d.io.in.bits);val b=d.io.in.bits
        b.vaddr.poke((BigInt("8000003f",16)+r*c).U);b.laddr.data.poke((64+r).U)
        b.cols.poke(c.U);b.pixel_repeats.poke(pixels.U);b.cmd_rows.poke(n.U)
        b.cmd_stride_bytes.poke(c.U);b.row_index.poke(r.U);b.cmd_first.poke((r==0).B)
        b.cmd_last.poke((r==n-1).B);b.scale.poke("h3c00".U);b.block_stride.poke(32.U)
        d.io.in.valid.poke(true.B);assert(d.io.in.ready.peek().litToBoolean);tick()
      }
      d.io.in.valid.poke(false.B)
      while(requests.map(_._2).sum<n*c && cycle<1000)tick()
      assert(requests.map(_._2).sum==n*c)
      def fragment(offset:Int,bytes:Int,last:Boolean,error:Boolean=false):Unit={
        zero(d.io.fragment.bits);val b=d.io.fragment.bits
        b.offset.poke(offset.U);b.bytes.poke(bytes.U);b.transaction_last.poke(last.B);b.error.poke(error.B)
        val data=(0 until bytes).map(j=>BigInt((offset+j)&255)<<(8*j)).foldLeft(BigInt(0))(_|_)
        b.data.poke(data.U);d.io.fragment.valid.poke(true.B);tick();d.io.fragment.valid.poke(false.B)
      }
      def transaction(req:(Int,Int)):Unit={
        val (offset,len)=req;var pos=offset
        while(pos<offset+len){val bytes=math.min(32,offset+len-pos);fragment(pos,bytes,pos+bytes==offset+len);pos+=bytes}
      }
      // Return a later transaction first: total bytes alone cannot make row 0 ready.
      val late=requests.last;transaction(requests(1));for(i<-0 until 8)tick();assert(replays==0)
      for(req<-requests.dropRight(1).zipWithIndex if req._2!=1)transaction(req._1)
      d.io.replay.ready.poke(false.B);for(i<-0 until 12)tick()
      d.io.replay.ready.poke(true.B);for(i<-0 until 80)tick()
      assert(credits<n*c && !d.io.terminalReady(0).peek().litToBoolean)
      if(streaming)assert(early>0,"all-return barrier was not removed") else assert(replays==0)
      if(faultKind==0){
        transaction(late)
        while(d.io.busy.peek().litToBoolean && cycle<2500)tick()
        assert(replays==n && credits==n*c && !d.io.busy.peek().litToBoolean)
        d.io.fault.expect(false.B)
      }else{
        // A late duplicate, bounds violation, return error, or Reader fault
        // cannot publish the terminal credit even after earlier rows escaped.
        faultKind match {
          case 1 => fragment(0,1,false)
          case 2 => fragment(n*c,1,false)
          case 3 => fragment(late._1,1,true,true)
          case 4 =>
            transaction(late)
            while(replays<n && cycle<2000)tick()
            assert(replays==n && credits<n*c)
            d.io.terminalReady(0).expect(true.B)
            // A terminal token could now commit. A concurrent Reader fault
            // must defeat that successful completion combinationally.
            d.io.readerFault.poke(true.B)
            d.io.terminalReady(0).expect(false.B)
            tick()
        }
        d.io.fragment.valid.poke(false.B);d.io.readerFault.poke(false.B)
        for(i<-0 until 12)tick()
        d.io.fault.expect(true.B);d.io.busy.expect(true.B);assert(credits<n*c)
        d.io.terminalReady(0).expect(false.B)
      }
      println(s"DMA_LOAD_STREAMING_CASE_PASS,streaming=$streaming,mode=$mode,c=$c,fault=$faultKind,early_rows=$early,requests=${requests.size},credits=$credits")
    }
  }
  println("DMA_LOAD_STREAMING_PASS,early_replay=checked,missing_prefix=checked,backpressure=checked,late_fault=checked,buffered_control=checked")
}
