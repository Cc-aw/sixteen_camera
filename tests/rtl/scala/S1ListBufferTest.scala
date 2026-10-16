package autonomoustest

import chisel3._
import chiseltest._
import sifive.blocks.inclusivecache._

/** Scoreboard the actual S1 shared pool, including full and last-pop/push edges. */
object S1ListBufferTest extends App {
  val entries = 34
  val queues = 102
  RawTester.test(new ListBuffer(ListBufferParameters(UInt(96.W), queues, entries, false, fastPeek=true)),
    Seq(chiseltest.simulator.VerilatorBackendAnnotation,
        firrtl2.options.TargetDirAnnotation("sim_s1_pool"))) { d =>
    for(seed <- Seq(151034,151035,151036,151037,151038)) {
      d.io.push.valid.poke(false.B);d.io.push.bits.index.poke(0.U);d.io.push.bits.data.poke(0.U)
      d.io.pop.valid.poke(false.B);d.io.pop.bits.poke(0.U);d.io.peekOH.get.poke(0.U)
      d.reset.poke(true.B);d.clock.step(4);d.reset.poke(false.B)
      val qs=Array.fill(queues)(scala.collection.mutable.Queue.empty[BigInt])
      val rng=new scala.util.Random(seed)
      var token=BigInt(1);var pushes=0;var pops=0;var peak=0;var lastPushPop=0
      def tick(push:Int,pop:Int):Unit={
        d.io.push.valid.poke((push>=0).B);d.io.push.bits.index.poke(push.max(0).U)
        d.io.push.bits.data.poke(token.U)
        d.io.pop.valid.poke((pop>=0).B);d.io.pop.bits.poke(pop.max(0).U)
        d.io.peekOH.get.poke((if(pop>=0) BigInt(1)<<pop else BigInt(0)).U)
        val pf=push>=0 && d.io.push.ready.peek().litToBoolean
        if(pop>=0) {
          require(qs(pop).nonEmpty)
          d.io.data.expect(qs(pop).front.U)
          if(pf && push==pop && qs(pop).size==1)lastPushPop+=1
          qs(pop).dequeue();pops+=1
        }
        if(pf){qs(push).enqueue(token);token+=1;pushes+=1}
        peak=peak.max(qs.map(_.size).sum)
        d.clock.step()
        val mask=(0 until queues).filter(qs(_).nonEmpty).foldLeft(BigInt(0))((m,i)=>m.setBit(i))
        d.io.valid.expect(mask.U)
        d.io.push.ready.expect((qs.map(_.size).sum<entries).B)
      }
      for(_<-0 until entries)tick(0,-1)
      d.io.push.ready.expect(false.B)
      tick(101,0);require(pushes==entries)
      tick(101,0)
      while(qs.exists(_.nonEmpty))tick(-1,qs.indexWhere(_.nonEmpty))
      for(q<-0 until queues){tick(q,-1);tick(q,q);tick(-1,q)}
      for(_<-0 until 20000){
        val live=(0 until queues).filter(qs(_).nonEmpty)
        val pop=if(live.nonEmpty && rng.nextInt(5)!=0)live(rng.nextInt(live.size))else -1
        val push=if(rng.nextInt(4)!=0){if(pop>=0 && rng.nextBoolean())pop else rng.nextInt(queues)}else -1
        tick(push,pop)
      }
      while(qs.exists(_.nonEmpty))tick(-1,qs.indexWhere(_.nonEmpty))
      require(pushes==pops && peak==entries && lastPushPop>0)
      println(s"S1_SECONDARY_POOL_PASS entries=$entries queues=$queues seed=$seed random_cycles=20000 pushes=$pushes pops=$pops peak=$peak last_pop_push=$lastPushPop")
    }
  }
}
