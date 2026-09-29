#include "VLoopConvRSTest.h"
#include "verilated.h"
#include <fstream>
#include <iostream>
#include <deque>
#include <array>
struct Event { uint64_t when; int type; };
int main(int argc,char**argv) {
 Verilated::commandArgs(argc,argv);
 VLoopConvRSTest d;
 std::deque<Event> events;
 uint64_t cycle=0; unsigned retired=0,submitted=0,issued=0;
 unsigned delay=argc>2?std::stoul(argv[2]):8;
 unsigned stall=argc>3?std::stoul(argv[3]):0;
 bool drop_load=argc>4 && std::string(argv[4])=="drop-load-after-fourth";
 auto tick=[&]() {
  d.clock=0;d.rs_io_completed_valid=0;
  if(!events.empty() && events.front().when<=cycle) {
   d.rs_io_completed_valid=1;d.rs_io_completed_bits=events.front().type;events.pop_front();
  }
  bool ready=(!stall || cycle%stall>=stall/2);
  d.rs_io_issue_ld_ready=ready;d.rs_io_issue_ex_ready=ready;d.rs_io_issue_st_ready=ready;d.eval();
  bool accepted=d.io_in_valid && d.io_in_ready;
  if(d.io_request_retire) {retired++;std::cout<<"RETIRE "<<retired<<" cycle="<<cycle<<"\n";}
  if(ready) {
   if(d.rs_io_issue_ld_valid && d.rs_io_issue_ld_cmd_cmd_inst_funct!=0) {
    if(!(drop_load && submitted>=4)) events.push_back({cycle+delay,d.rs_io_issue_ld_rob_id});issued++;
   }
   if(d.rs_io_issue_ex_valid) {
    events.push_back({cycle+delay,d.rs_io_issue_ex_rob_id});issued++;
   }
   if(d.rs_io_issue_st_valid && d.rs_io_issue_st_cmd_cmd_inst_funct!=0) {
    events.push_back({cycle+delay,d.rs_io_issue_st_rob_id});issued++;
   }
  }
  d.clock=1;d.eval();cycle++;return accepted;
 };
 d.io_in_valid=0;d.diagnostic=0;d.reset=1;
 for(int i=0;i<5;i++)tick();d.reset=0;
 std::ifstream in(argv[1]);unsigned f;uint64_t a,b;
 while(in>>std::dec>>f>>std::hex>>a>>b) {
  // Match board single-outstanding admission; queued completions still drain.
  uint64_t start=cycle;
  while(submitted!=retired) {
   tick();if(cycle-start>500000) {d.diagnostic=1;tick();std::cerr<<"TIMEOUT retired="<<retired<<" submitted="<<submitted<<" issued="<<issued<<"\n";return 2;}
  }
  d.io_in_bits_cmd_inst_funct=f;d.io_in_bits_cmd_rs1=a;d.io_in_bits_cmd_rs2=b;d.io_in_valid=1;
  while(!tick()) {if(cycle-start>500000){d.diagnostic=1;tick();return 4;}}
  d.io_in_valid=0;if(f==15)submitted++;
 }
 uint64_t start=cycle;
 while(submitted!=retired || !events.empty() || d.io_busy || d.rs_io_busy) {
  tick();if(cycle-start>500000){d.diagnostic=1;tick();std::cerr<<"DRAIN_TIMEOUT\n";return 2;}
 }
 std::cout<<"SIM_PASS tasks="<<submitted<<" retired="<<retired<<" issued="<<issued<<" cycles="<<cycle<<" delay="<<delay<<" stall="<<stall<<"\n";
}
