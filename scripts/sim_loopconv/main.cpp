#include "VLoopConvTest.h"
#include "verilated.h"
#include <fstream>
#include <iostream>
#include <deque>
#include <array>
struct Event { uint64_t when; int type; };
int main(int argc,char**argv) {
 Verilated::commandArgs(argc,argv);
 VLoopConvTest d;
 std::deque<Event> events;
 uint64_t cycle=0; unsigned retired=0,submitted=0,issued=0;
 unsigned delay=argc>2?std::stoul(argv[2]):8;
 unsigned stall=argc>3?std::stoul(argv[3]):0;
 std::ofstream trace;
 if(argc>4)trace.open(argv[4]);
 auto tick=[&]() {
  d.clock=0;d.io_ld_completed=0;d.io_st_completed=0;d.io_ex_completed=0;
  std::array<unsigned,3> completed={0,0,0};
  for(auto it=events.begin();it!=events.end();) {
   if(it->when<=cycle && completed[it->type]<1) {completed[it->type]++;it=events.erase(it);} else ++it;
  }
  d.io_ld_completed=completed[0];d.io_ex_completed=completed[1];d.io_st_completed=completed[2];
  d.io_out_ready=(!stall || cycle%stall>=stall/2);d.eval();
  bool accepted=d.io_in_valid && d.io_in_ready;
  if(d.io_request_retire) {retired++; std::cout<<"RETIRE "<<retired<<" cycle="<<cycle<<"\n";}
  if(d.io_out_valid && d.io_out_ready && d.io_out_bits_from_conv_fsm) {
   unsigned f=d.io_out_bits_cmd_inst_funct; int type=-1;
   if(trace.is_open())trace<<std::dec<<f<<" "<<std::hex<<d.io_out_bits_cmd_rs1<<" "<<d.io_out_bits_cmd_rs2<<"\n";
   if(f==1||f==2||f==14)type=0;
   else if(f==3)type=2;
   else if(f==4||f==5||f==6)type=1;
   else if(f==0) {unsigned kind=d.io_out_bits_cmd_rs1&3;type=kind==1?0:kind==2?2:1;}
   if(type<0) {std::cerr<<"unknown funct "<<f<<"\n";exit(3);}
   events.push_back({cycle+delay,type}); issued++;
  }
  d.clock=1;d.eval();cycle++;return accepted;
 };
 d.io_in_valid=0;d.io_out_ready=1;d.diagnostic=0;d.reset=1;
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
 while(submitted!=retired || !events.empty() || d.io_busy) {
  tick();if(cycle-start>500000){d.diagnostic=1;tick();std::cerr<<"DRAIN_TIMEOUT\n";return 2;}
 }
 std::cout<<"SIM_PASS tasks="<<submitted<<" retired="<<retired<<" issued="<<issued<<" cycles="<<cycle<<" delay="<<delay<<" stall="<<stall<<"\n";
}
