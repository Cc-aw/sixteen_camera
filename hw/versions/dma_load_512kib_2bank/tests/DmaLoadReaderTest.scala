package gemmini

import chisel3._
import chisel3.util._
import chiseltest._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.tile.{TileKey, RocketTileParams, TileVisibilityNodeKey}
import freechips.rocketchip.diplomacy.{AddressSet, LazyModule, LazyModuleImp, IdRange, TransferSizes}
import freechips.rocketchip.tilelink._
import chipyard.fpga.xcvu13p_gemmini_32x32_packed_inference_ram.XCVU13PGemmini32x32PackedInferenceRamConfigs

class DmaLoadReaderHarness(implicit p: Parameters) extends LazyModule {
  val cfg=XCVU13PGemmini32x32PackedInferenceRamConfigs.config.copy(dma_load_runtime_enable=true)
  val reader=LazyModule(new StreamReader(cfg,32,256,64,256,1024,1,16384,2048,32,false,false))
  val memory=TLManagerNode(Seq(TLSlavePortParameters.v1(Seq(TLSlaveParameters.v1(
    address=Seq(AddressSet(0,BigInt("1ffffffff",16))),supportsGet=TransferSizes(1,64),mayDenyGet=true)),beatBytes=32,minLatency=1)))
  memory := reader.node
  lazy val module=new Impl
  class Impl extends LazyModuleImp(this) {
    val io=IO(new Bundle {
      val req=Flipped(Decoupled(chiselTypeOf(reader.module.io.req.bits)))
      val row=Decoupled(chiselTypeOf(reader.module.io.resp.bits))
      val fragment=Decoupled(new DmaLoadFragment)
      val fault=Output(Bool());val busy=Output(Bool())
      val mem=new TLBundle(memory.in(0)._1.params)
    })
    reader.module.io.req<>io.req;io.row<>reader.module.io.resp;io.fragment<>reader.module.io.group_resp
    io.fault:=reader.module.io.fault;io.busy:=reader.module.io.busy
    reader.module.io.flush:=false.B
    reader.module.io.tlb.resp:=0.U.asTypeOf(reader.module.io.tlb.resp)
    reader.module.io.counter.external_reset:=false.B
    io.mem<>memory.in(0)._1
  }
}

object DmaLoadReaderTest extends App {
  val shape=LazyModule(new LazyModule()(Parameters.empty) {
    val visible=TLEphemeralNode()
    val client=TLClientNode(Seq(TLMasterPortParameters.v1(Seq(TLClientParameters(name="visibility",sourceId=IdRange(0,32))))))
    val manager=TLManagerNode(Seq(TLSlavePortParameters.v1(Seq(TLSlaveParameters.v1(
      address=Seq(AddressSet(0,BigInt("1ffffffff",16))),supportsGet=TransferSizes(1,64))),beatBytes=32)))
    manager:=visible;visible:=client
    lazy val module=new LazyModuleImp(this) {}
  })
  implicit val p: Parameters=Parameters.empty.alterPartial {
    case TileKey=>RocketTileParams()
    case TileVisibilityNodeKey=>shape.visible
  }
  def zero(data: Data): Unit=data match {
    case b:Bool=>b.poke(false.B);case u:UInt=>u.poke(0.U);case s:SInt=>s.poke(0.S)
    case v:Vec[_]=>v.foreach(zero);case r:Record=>r.elements.values.foreach(zero)
  }
  def pattern(address:BigInt):Int=((address*13+(address>>32)*57+5)&255).toInt
  val top=LazyModule(new DmaLoadReaderHarness)
  RawTester.test(top.module,Seq(chiseltest.simulator.IcarusBackendAnnotation)) { d =>
    case class Reply(source:BigInt,size:Int,address:BigInt,denied:Boolean=false,corrupt:Boolean=false)
    zero(d.io.req.bits);zero(d.io.mem.d.bits)
    d.io.req.valid.poke(false.B);d.io.mem.d.valid.poke(false.B)
    d.io.mem.a.ready.poke(false.B);d.io.fragment.ready.poke(false.B);d.io.row.ready.poke(false.B)
    d.reset.poke(true.B);d.clock.step(4);d.reset.poke(false.B)
    var pending=Vector.empty[Reply];var active:Option[(Reply,Int)]=None
    var cycles=0;var groups=Map.empty[(Int,Int),Int];var rows=Map.empty[(Int,Int),Int]
    var errorMode=0;var errors=0;var gets=0
    def tick():Unit={
      d.io.mem.a.ready.poke((cycles%7!=2).B)
      d.io.fragment.ready.poke((cycles%11<8).B);d.io.row.ready.poke((cycles%13<9).B)
      if(active.isEmpty && pending.nonEmpty && cycles>100 && cycles%5!=0) {
        active=Some((pending.last,0));pending=pending.dropRight(1)
      }
      d.io.mem.d.valid.poke(active.nonEmpty.B);zero(d.io.mem.d.bits)
      active.foreach { case (r,beat)=>
        d.io.mem.d.bits.opcode.poke(1.U);d.io.mem.d.bits.source.poke(r.source.U)
        d.io.mem.d.bits.size.poke(r.size.U);d.io.mem.d.bits.denied.poke(r.denied.B)
        d.io.mem.d.bits.corrupt.poke(r.corrupt.B)
        val word=(0 until 32).map(j=>BigInt(pattern(r.address+beat*32+j))<<(8*j)).reduce(_|_)
        d.io.mem.d.bits.data.poke(word.U)
      }
      if(d.io.mem.a.valid.peek().litToBoolean && d.io.mem.a.ready.peek().litToBoolean) {
        val a=d.io.mem.a.bits;a.opcode.expect(4.U)
        pending :+= Reply(a.source.peek().litValue,a.size.peek().litValue.toInt,a.address.peek().litValue,errorMode==1,errorMode!=0)
        gets+=1
      }
      if(d.io.mem.d.valid.peek().litToBoolean && d.io.mem.d.ready.peek().litToBoolean) {
        val (r,beat)=active.get
        if((beat+1)*32 >= (1<<r.size))active=None else active=Some((r,beat+1))
      }
      if(d.io.fragment.valid.peek().litToBoolean && d.io.fragment.ready.peek().litToBoolean) {
        val b=d.io.fragment.bits
        if(b.error.peek().litToBoolean)errors+=1
        else for(j <- 0 until b.bytes.peek().litValue.toInt) {
          val key=(b.group_id.peek().litValue.toInt,b.offset.peek().litValue.toInt+j)
          assert(!groups.contains(key),s"duplicate fragment $key")
          groups+=key->((b.data.peek().litValue>>(8*j))&255).toInt
        }
      }
      if(d.io.row.valid.peek().litToBoolean && d.io.row.ready.peek().litToBoolean) {
        val b=d.io.row.bits
        for(j <- 0 until 32 if b.mask(j).peek().litToBoolean)
          rows+=(b.addr.peek().litValue.toInt,j)->((b.data.peek().litValue>>(8*j))&255).toInt
      }
      d.clock.step();cycles+=1
    }
    val requests=Vector.tabulate(16)(i=>(BigInt("80000fe1",16)+i*64+i%3,(i%3+1)*13,i%2,(i/2)*64))
    var sent=0
    while((sent<requests.size || d.io.busy.peek().litToBoolean) && cycles<3000) {
      zero(d.io.req.bits);d.io.req.valid.poke((sent<requests.size).B)
      if(sent<requests.size) {
        val (a,n,g,o)=requests(sent)
        d.io.req.bits.vaddr.poke(a.U);d.io.req.bits.len.poke(n.U)
        d.io.req.bits.group.poke(true.B);d.io.req.bits.group_id.poke(g.U);d.io.req.bits.group_offset.poke(o.U)
      }
      val fire=sent<requests.size && d.io.req.ready.peek().litToBoolean
      tick();if(fire)sent+=1
    }
    assert(sent==requests.size && !d.io.busy.peek().litToBoolean && rows.isEmpty)
    for((a,n,g,o)<-requests;j<-0 until n)assert(groups(g,o+j)==pattern(a+j))
    assert(groups.size==requests.map(_._2).sum && gets<32)
    // Physical bit32 must survive unchanged on the ordinary fallback path.
    d.io.req.valid.poke(true.B);zero(d.io.req.bits)
    d.io.req.bits.vaddr.poke("h10000103f".U);d.io.req.bits.len.poke(3.U)
    d.io.req.bits.spaddr.poke(17.U);d.io.req.bits.pixel_repeats.poke(1.U);d.io.req.bits.block_stride.poke(32.U)
    while(!d.io.req.ready.peek().litToBoolean)tick()
    tick();d.io.req.valid.poke(false.B)
    while(d.io.busy.peek().litToBoolean && cycles<4000)tick()
    for(j<-0 until 3)assert(rows(17,j)==pattern(BigInt("10000103f",16)+j))
    d.io.fault.expect(false.B)
    for(kind<-Seq(1,2)) {
      d.reset.poke(true.B);d.clock.step(4);d.reset.poke(false.B)
      pending=Vector.empty;active=None;errorMode=kind
      zero(d.io.req.bits);d.io.req.valid.poke(true.B)
      d.io.req.bits.vaddr.poke("h80000000".U);d.io.req.bits.len.poke(64.U);d.io.req.bits.group.poke(true.B)
      while(!d.io.req.ready.peek().litToBoolean)tick()
      tick();d.io.req.valid.poke(false.B)
      for(i<-0 until 100)tick()
      d.io.fault.expect(true.B);d.io.busy.expect(true.B)
      assert(pending.isEmpty && active.isEmpty,"fault must still drain D")
    }
    assert(errors>=2)
    println(s"DMA_LOAD_READER_PASS,group_requests=${requests.size},gets=$gets,reordered_sources=checked,high_physical_bit=checked,denied_corrupt=checked")
  }
}
