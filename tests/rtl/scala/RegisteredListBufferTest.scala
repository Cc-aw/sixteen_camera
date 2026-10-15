package autonomoustest
import chisel3._
import chiseltest._
import sifive.blocks.inclusivecache._

object RegisteredListBufferTest extends App {
  RawTester.test(new RegisteredListBuffer(ListBufferParameters(UInt(96.W),102,34,false)),
    Seq(chiseltest.simulator.VerilatorBackendAnnotation)) { d=>
    d.io.push.valid.poke(false.B);d.io.push.bits.index.poke(0.U);d.io.push.bits.data.poke(0.U)
    d.io.pop.valid.poke(false.B);d.io.pop.bits.poke(0.U);d.io.result.ready.poke(false.B)
    d.reset.poke(true.B);d.clock.step(4);d.reset.poke(false.B)
    val qs=Array.fill(102)(scala.collection.mutable.Queue.empty[BigInt])
    val expected=scala.collection.mutable.Queue.empty[(Int,BigInt)]
    val rng=new scala.util.Random(151034)
    var token=BigInt(1);var pushes=0;var pops=0;var replies=0;var lastPushPop=0
    def tick(push:Int,pop:Int,ready:Boolean):Unit={
      d.io.push.valid.poke((push>=0).B);d.io.push.bits.index.poke(push.max(0).U)
      d.io.push.bits.data.poke(token.U)
      d.io.pop.valid.poke((pop>=0).B);d.io.pop.bits.poke(pop.max(0).U)
      d.io.result.ready.poke(ready.B)
      val pf=push>=0&&d.io.push.ready.peek().litToBoolean
      val rf=pop>=0&&d.io.pop.ready.peek().litToBoolean
      if(d.io.result.valid.peek().litToBoolean && ready){
        require(expected.nonEmpty,"unexpected secondary response")
        val (q,v)=expected.dequeue();d.io.result.bits.index.expect(q.U);d.io.result.bits.data.expect(v.U);replies+=1
      }
      if(rf){
        require(qs(pop).nonEmpty);if(pf&&push==pop&&qs(pop).size==1)lastPushPop+=1
        expected.enqueue((pop,qs(pop).dequeue()));pops+=1
      }
      if(pf){qs(push).enqueue(token);token+=1;pushes+=1}
      d.clock.step()
      val mask=(0 until 102).filter(qs(_).nonEmpty).foldLeft(BigInt(0))((m,i)=>m.setBit(i))
      d.io.valid.expect(mask.U)
    }
    // Pool full, blocked synchronous responses, and last-pop/push collision.
    for(_<-0 until 34)tick(0,-1,false)
    d.io.push.ready.expect(false.B)
    for(_<-0 until 12)tick(0,0,false)
    for(_<-0 until 80)tick(-1,if(qs(0).nonEmpty)0 else -1,true)
    tick(101,-1,true);tick(101,101,true)
    for(c<-0 until 4000){
      val live=(0 until 102).filter(qs(_).nonEmpty)
      val q=if(live.nonEmpty&&rng.nextInt(5)!=0)live(rng.nextInt(live.size))else -1
      val w=if(rng.nextInt(4)!=0){if(q>=0&&rng.nextBoolean())q else rng.nextInt(102)}else -1
      tick(w,q,c%19>=7 && rng.nextInt(5)!=0)
    }
    var drain=0
    while(qs.exists(_.nonEmpty)||expected.nonEmpty){
      tick(-1,qs.indexWhere(_.nonEmpty),true);drain+=1;require(drain<500)
    }
    require(pushes==pops&&pops==replies&&lastPushPop>0)
    println(s"REGISTERED_SECONDARY_POOL_PASS pushes=$pushes last_pop_push=$lastPushPop")
  }
}
