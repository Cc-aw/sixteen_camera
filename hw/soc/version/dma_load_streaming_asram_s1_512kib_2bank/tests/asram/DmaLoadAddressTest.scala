package gemmini

import chisel3._
import chiseltest._

/** Both fast paths must retain local physical-range guards after A1 merge. */
object DmaLoadAddressTest extends App {
  val backend=Seq(chiseltest.simulator.IcarusBackendAnnotation)
  var cases=0
  for(enabled <- Seq(false,true)) {
    RawTester.test(new DmaLoadReadPlanner(33,allowActivationSram=enabled),backend) { d =>
      def check(address: BigInt, remaining: Int, legal: Boolean): Unit = {
        d.io.address.poke(address.U);d.io.remaining.poke(remaining.U)
        d.io.legal.expect(legal.B)
        if(legal) {
          val bytes=d.io.bytes.peek().litValue
          val size=d.io.size.peek().litValue.toInt
          assert(bytes>0 && bytes<=remaining && (address%(BigInt(1)<<size))+bytes<=(BigInt(1)<<size))
        }
        cases+=1
      }
      for(lane<-0 until 3) {
        val base=BigInt("20000000",16)+lane*BigInt("400000",16)
        for(offset<-0 until 64;remaining<-Seq(1,3,12,31,32,64)) {
          check(base+offset,remaining,enabled)
          check(base+0x240000-64+offset,remaining,enabled)
        }
        for(offset<-Seq(0x240000,0x240001,0x3ffff8))check(base+offset,8,false)
        check(base,0,false)
      }
      for(address<-Seq(BigInt("20c00000",16),BigInt("10000",16),BigInt("100000000",16)))check(address,32,false)
      for(offset<-0 until 64)check(BigInt("80000000",16)+offset,64,true)
    }
  }
  println(s"DMA_STREAM_ASRAM_ADDRESS_PASS,cases=$cases,three_windows=checked,holes=reject,control=reject,disabled=reject,DDR=preserved")
}
