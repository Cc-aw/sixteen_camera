#include "VLoopConvControllersTest.h"
#include "verilated.h"
#include <fstream>
#include <iostream>
#include <deque>
#include <array>
struct Event { uint64_t when; int type; };
int main(int argc,char**argv) {
 Verilated::commandArgs(argc,argv);
 VLoopConvControllersTest d;
 std::deque<Event> loads,stores;
 uint64_t cycle=0; unsigned retired=0,submitted=0,issued=0;
 unsigned delay=argc>2?std::stoul(argv[2]):8;
 unsigned stall=argc>3?std::stoul(argv[3]):0;

 auto tick=[&]() {
  d.clock=0;d.ld_io_dma_resp_valid=0;d.st_io_dma_resp_valid=0;
  d.ld_io_dma_resp_bits_cmd_id=0;d.st_io_dma_resp_bits_cmd_id=0;
  if(!loads.empty() && loads.front().when<=cycle) {
   d.ld_io_dma_resp_valid=1;d.ld_io_dma_resp_bits_bytesRead=loads.front().type;loads.pop_front();
  }
  if(!stores.empty() && stores.front().when<=cycle) {d.st_io_dma_resp_valid=1;stores.pop_front();}
  bool ready=(!stall || cycle%stall>=stall/2);
  d.memory_ready=ready;d.ld_io_dma_req_ready=ready;d.st_io_dma_req_ready=ready;d.eval();
  bool accepted=d.dut_io_in_valid && d.dut_io_in_ready;
  if(d.dut_io_request_retire) {retired++;std::cout<<"RETIRE "<<retired<<" cycle="<<cycle<<std::endl;}
  if(ready) {
   if(d.ld_io_dma_req_valid) {
    int bytes=d.ld_io_dma_req_bits_cols*(d.ld_io_dma_req_bits_has_acc_bitwidth?4:1);
    loads.push_back({cycle+delay,bytes});issued++;
   }
   if(d.st_io_dma_req_valid) {stores.push_back({cycle+delay,1});issued++;}
  }
  d.clock=1;d.eval();cycle++;return accepted;
 };
 d.dut_io_in_valid=0;d.diagnostic=0;d.reset=1;
 for(int i=0;i<5;i++)tick();d.reset=0;
 std::ifstream in(argv[1]);unsigned f;uint64_t a,b;
 while(in>>std::dec>>f>>std::hex>>a>>b) {
  // Match board single-outstanding admission; queued completions still drain.
  uint64_t start=cycle;
  while(submitted!=retired) {
   tick();if(cycle-start>500000) {d.diagnostic=1;tick();std::cerr<<"TIMEOUT retired="<<retired<<" submitted="<<submitted<<" issued="<<issued<<"\n";return 2;}
  }
  d.dut_io_in_bits_cmd_inst_funct=f;d.dut_io_in_bits_cmd_rs1=a;d.dut_io_in_bits_cmd_rs2=b;d.dut_io_in_valid=1;
  while(!tick()) {if(cycle-start>500000){d.diagnostic=1;tick();return 4;}}
  d.dut_io_in_valid=0;if(f==15)submitted++;
 }
 uint64_t start=cycle;
 while(submitted!=retired || (!loads.empty() || !stores.empty()) || d.dut_io_busy || d.backend_busy) {
  tick();if(cycle-start>500000){d.diagnostic=1;tick();std::cerr<<"DRAIN_TIMEOUT\n";return 2;}
 }
 std::cout<<"SIM_PASS tasks="<<submitted<<" retired="<<retired<<" issued="<<issued<<" cycles="<<cycle<<" delay="<<delay<<" stall="<<stall<<"\n";
}
