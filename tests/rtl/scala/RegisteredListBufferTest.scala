package autonomoustest
import chisel3._
import chiseltest._
import sifive.blocks.inclusivecache._

object RegisteredListBufferTest extends App {
  for(entries <- Seq(34,68)) {
    RawTester.test(new RegisteredListBuffer(ListBufferParameters(UInt(96.W),102,entries,false)),
      Seq(chiseltest.simulator.VerilatorBackendAnnotation,
          firrtl2.options.TargetDirAnnotation(s"sim_e$entries"))) { d=>
      for(seed <- Seq(151034,151035,151036,151037,151038)) {
        d.io.push.valid.poke(false.B);d.io.push.bits.index.poke(0.U);d.io.push.bits.data.poke(0.U)
        d.io.pop.valid.poke(false.B);d.io.pop.bits.poke(0.U);d.io.result.ready.poke(false.B)
        d.reset.poke(true.B);d.clock.step(4);d.reset.poke(false.B)
        val qs=Array.fill(102)(scala.collection.mutable.Queue.empty[BigInt])
        val expected=scala.collection.mutable.Queue.empty[(Int,BigInt)]
        val rng=new scala.util.Random(seed)
        var token=BigInt(1);var pushes=0;var pops=0;var replies=0;var lastPushPop=0;var peak=0
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
          peak=peak.max(qs.map(_.size).sum)
          d.clock.step()
          val mask=(0 until 102).filter(qs(_).nonEmpty).foldLeft(BigInt(0))((m,i)=>m.setBit(i))
          d.io.valid.expect(mask.U)
        }
        // L01/02/06/07: full physical pool, all high entry bits, pending
        // synchronous read credit, and conservative full-pop allocation.
        for(_<-0 until entries)tick(0,-1,false)
        require(pushes==entries);d.io.push.ready.expect(false.B)
        tick(101,-1,false);require(pushes==entries)
        tick(101,0,false);require(pushes==entries)
        tick(101,0,false);require(pushes==entries+1)
        for(_<-0 until 20)tick(0,0,false)
        for(_<-0 until entries+20)tick(-1,qs.indexWhere(_.nonEmpty),true)
        while(expected.nonEmpty)tick(-1,-1,true)
        // Every logical index, including 33/34/67/68/101; last-pop/push.
        for(q<-0 until 102){tick(q,-1,true);tick(q,q,true);tick(-1,q,true)}
        for(c<-0 until 20000){
          val live=(0 until 102).filter(qs(_).nonEmpty)
          val q=if(live.nonEmpty&&rng.nextInt(5)!=0)live(rng.nextInt(live.size))else -1
          val w=if(rng.nextInt(4)!=0){if(q>=0&&rng.nextBoolean())q else rng.nextInt(102)}else -1
          tick(w,q,c%37>=17 && rng.nextInt(5)!=0)
        }
        var drain=0
        while(qs.exists(_.nonEmpty)||expected.nonEmpty){
          tick(-1,qs.indexWhere(_.nonEmpty),true);drain+=1;require(drain<1000)
        }
        require(pushes==pops&&pops==replies&&lastPushPop>0&&peak==entries)
        println(s"REGISTERED_SECONDARY_POOL_PASS entries=$entries queues=102 seed=$seed random_cycles=20000 pushes=$pushes replies=$replies peak=$peak last_pop_push=$lastPushPop")
      }
    }
  }
}
