#include "VGemminiTest.h"
#include "verilated.h"
#include <fstream>
#include <iostream>
#include <deque>
#include <array>
#include <algorithm>
#include <vector>
struct Response {uint64_t when;unsigned op,size,source;std::array<uint32_t,8> data;};
int main(int argc,char**argv) {
 if(argc<2)return 1;
 Verilated::commandArgs(argc,argv); VGemminiTest d;
 unsigned delay=argc>2?std::stoul(argv[2]):8;
 unsigned stall=argc>3?std::stoul(argv[3]):0;
 unsigned limit=argc>4?std::stoul(argv[4]):0;
 uint64_t cycle=0;unsigned submitted=0,retired=0,gets=0,puts=0;
 std::deque<Response> responses;
 const int height=std::string(argv[1]).find("480")!=std::string::npos?480:16;
 const int width=height==480?640:20;
 std::vector<uint8_t> output(height/2*width/2*16,99);
 std::vector<unsigned> writes(output.size(),0);
 auto read_byte=[&](uint64_t addr)->uint8_t {
  if(addr>=0x83000000ULL && addr<0x83000000ULL+height*width*3) {
   unsigned i=addr-0x83000000ULL;return (int)((i*7+i/31)%17)-8;
  }
  if(addr>=0x83200000ULL && addr<0x83200000ULL+6*6*3*16) {
   unsigned i=addr-0x83200000ULL,c=i%16,ic=i/16%3,kc=i/48%6,kr=i/288;
   return kr==c%6 && kc==(c*5+1)%6 && ic==c%3 ? (c&1 ? -1:1):0;
  }
  if(addr>=0x83210000ULL && addr<0x83210040ULL) {
   unsigned i=addr-0x83210000ULL;return ((uint32_t)((int)(i/4)%5-2)>>(8*(i%4)))&255;
  }
  if(addr>=0x83400000ULL && addr<0x83400000ULL+output.size()) return output[addr-0x83400000ULL];
  return 0;
 };
 unsigned put_remaining=0; uint64_t put_address=0;unsigned put_size=0,put_source=0;
 auto tick=[&]() {
  d.clock=0;d.auto_spad_id_out_d_valid=0;
  bool ready=!stall || cycle%stall>=stall/2;
  d.auto_spad_id_out_a_ready=ready;
  if(!responses.empty() && responses.front().when<=cycle) {
   auto &r=responses.front();d.auto_spad_id_out_d_valid=1;
   d.auto_spad_id_out_d_bits_opcode=r.op;d.auto_spad_id_out_d_bits_size=r.size;
   d.auto_spad_id_out_d_bits_source=r.source;
   for(int i=0;i<8;i++)d.auto_spad_id_out_d_bits_data[i]=r.data[i];
  }
  d.io_loopconv_request_accept=0;
  d.eval();bool accepted=d.io_cmd_valid&&d.io_cmd_ready;
  d.io_loopconv_request_accept=accepted && d.io_cmd_bits_inst_funct==15;d.eval();
  if(d.auto_spad_id_out_d_valid && d.auto_spad_id_out_d_ready)responses.pop_front();
  if(d.auto_spad_id_out_a_valid && ready) {
   unsigned op=d.auto_spad_id_out_a_bits_opcode,size=d.auto_spad_id_out_a_bits_size;
   unsigned src=d.auto_spad_id_out_a_bits_source;uint64_t addr=d.auto_spad_id_out_a_bits_address;
   unsigned beats=std::max(1u,(1u<<size)/32);
   if(op==4) {
    gets++;
    for(unsigned beat=0;beat<beats;beat++) {
     Response r={cycle+delay,1,size,src,{}};
     for(unsigned byte=0;byte<32;byte++)r.data[byte/4]|=(uint32_t)read_byte((addr&~31ULL)+beat*32+byte)<<(8*(byte%4));
     responses.push_back(r);
    }
   } else if(op==0 || op==1) {
    if(!put_remaining) {put_remaining=beats;put_address=addr;put_size=size;put_source=src;}
    if(put_source!=src||put_size!=size||put_address!=addr) {std::cerr<<"PUT protocol mismatch\n";exit(5);}
    unsigned beat=beats-put_remaining;
    for(unsigned byte=0;byte<32;byte++)if(d.auto_spad_id_out_a_bits_mask & (1u<<byte)) {
     uint64_t dest=(put_address&~31ULL)+beat*32+byte;
     if(dest<0x83400000ULL || dest>=0x83400000ULL+output.size()) {std::cerr<<"Store outside output buffer\n";exit(6);}
     output[dest-0x83400000ULL]=(d.auto_spad_id_out_a_bits_data[byte/4]>>(8*(byte%4)))&255;
     writes[dest-0x83400000ULL]++;
    }
    if(--put_remaining==0) {responses.push_back({cycle+delay,0,size,src,{}});puts++;}
   } else {std::cerr<<"Unsupported TL opcode "<<op<<"\n";exit(4);}
  }
  if(d.io_csrs_3_sdata!=retired) {retired=d.io_csrs_3_sdata;std::cout<<"RETIRE "<<retired<<" cycle="<<cycle<<" gets="<<gets<<" puts="<<puts<<std::endl;}
  d.clock=1;d.eval();cycle++;return accepted;
 };
 d.io_csrs_4_wen=0;d.io_csrs_4_wdata=0;d.io_csrs_6_value=0;
 d.io_loopconv_ingress_debug=0;
 d.reset=1;d.io_cmd_valid=0;d.io_resp_ready=1;d.diagnostic=0;
 d.io_cmd_bits_status_prv=3;d.io_cmd_bits_status_dprv=3;
 for(int i=0;i<8;i++)tick();d.reset=0;
 auto debug_page=[&](unsigned page)->uint64_t {
  d.io_csrs_6_value=page;d.eval();return d.io_csrs_7_sdata;
 };
 auto debug_control=[&](unsigned value) {
  d.io_csrs_4_wen=1;d.io_csrs_4_wdata=value;tick();d.io_csrs_4_wen=0;d.eval();
 };
 auto debug_test=[&]() {
  if(debug_page(0)!=0x4442475f00090050ULL) {std::cerr<<"Bad diagnostic ABI\n";exit(9);}
  debug_control(1);
  if(!(d.io_csrs_5_sdata&1)) {std::cerr<<"Snapshot did not freeze\n";exit(9);}
  std::array<uint64_t,80> snapshot;
  for(unsigned p=0;p<80;p++)snapshot[p]=debug_page(p);
  for(unsigned i=0;i<40;i++)tick();
  for(unsigned p=0;p<80;p++)if(debug_page(p)!=snapshot[p]) {std::cerr<<"Frozen page changed "<<p<<"\n";exit(9);}
  if(debug_page(127)!=0) {std::cerr<<"Invalid diagnostic page\n";exit(9);}
  debug_control(2);
  if(d.io_csrs_5_sdata&1) {std::cerr<<"Snapshot did not clear\n";exit(9);}
  // Exercise automatic capture with the real ingress sideband at its threshold.
  d.io_loopconv_ingress_debug=1ULL<<58;tick();d.io_loopconv_ingress_debug=0;d.eval();
  if((d.io_csrs_5_sdata&0x20001)!=0x20001 || debug_page(45)!=(1ULL<<58)) {
   std::cerr<<"Automatic snapshot failed\n";exit(9);
  }
  tick();
  if(!(d.io_csrs_5_sdata&1)) {std::cerr<<"Automatic snapshot was not sticky\n";exit(9);}
  debug_control(2);
  std::cout<<"DIAGNOSTIC_SNAPSHOT_PASS pages=80 busy="<<unsigned(d.io_busy)<<"\n";
 };
 auto timeout=[&]() {d.diagnostic=1;tick();std::cerr<<"TIMEOUT accepted="<<d.io_csrs_2_sdata<<" retired="<<retired<<" status="<<std::hex<<d.io_csrs_1_sdata<<std::dec<<" gets="<<gets<<" puts="<<puts<<" pending="<<responses.size()<<"\n";};
 std::ifstream in(argv[1]);if(!in)return 1;unsigned f;uint64_t a,b;
 while(in>>std::dec>>f>>std::hex>>a>>b) {
  if(limit && submitted>=limit)break;
  uint64_t start=cycle;
  while(submitted!=retired) {tick();if(cycle-start>300000){timeout();return 2;}}
  d.io_cmd_bits_inst_funct=f;d.io_cmd_bits_rs1=a;d.io_cmd_bits_rs2=b;
  d.io_cmd_bits_inst_xs1=1;d.io_cmd_bits_inst_xs2=1;d.io_cmd_valid=1;
  // Direct serialized ingress: count one acceptance on launch. LazyRoCC itself
  // is not instantiated here; each complete seven-command packet is preserved.

  while(!tick()) {if(cycle-start>300000){timeout();return 2;}}
  d.io_loopconv_request_accept=0;d.io_cmd_valid=0;if(f==15) {submitted++;if(submitted==1)debug_test();}
 }
 uint64_t start=cycle;
 while(submitted!=retired || d.io_busy || !responses.empty()) {
  tick();if(cycle-start>300000){timeout();return 2;}
 }
 if(debug_page(61) >> 63) {std::cerr<<"SCALE_FAULT "<<std::hex<<debug_page(61)<<"\n";return 10;}
 std::cout<<"DIAGNOSTIC_SCALE_NO_FAULT\n";
 std::ofstream dump(std::string(argv[1])+".output.bin",std::ios::binary);
 dump.write(reinterpret_cast<const char*>(output.data()),output.size());
 unsigned mismatches=0,checked=0,unwritten=0,rewritten=0;
 for(int r=0;r<height/2;r++)for(int col=0;col<width/2;col++)for(int c=0;c<16;c++) {
  unsigned pos=(r*(width/2)+col)*16+c;
  if(!writes[pos]) {unwritten++;if(limit)continue;}
  if(writes[pos]>1)rewritten++;
  checked++;
  int ir=r*2-2+c%6,ic=col*2-2+(c*5+1)%6,value=c%5-2;
  if(ir>=0 && ir<height && ic>=0 && ic<width)
   value+=(int8_t)read_byte(0x83000000ULL+(ir*width+ic)*3+c%3)*(c&1?-1:1);
  int expected=value/2,actual=(int8_t)output[(r*(width/2)+col)*16+c];
  if(expected!=actual) {
   if(mismatches<5)std::cerr<<"OUTPUT_MISMATCH r="<<r<<" col="<<col<<" c="<<c<<" expected="<<expected<<" actual="<<actual<<"\n";
   mismatches++;
  }
 }
 std::cout<<"OUTPUT_COVERAGE checked="<<checked<<" unwritten="<<unwritten<<" rewritten="<<rewritten<<"\n";
 if(mismatches){std::cerr<<"OUTPUT_MISMATCH_COUNT="<<mismatches<<"\n";return 7;}
 if((!limit && unwritten) || !checked)return 8;
 std::cout<<(limit?"PARTIAL_OUTPUT_CHECK_PASS elements=":"OUTPUT_CHECK_PASS elements=")<<checked<<"\n";
 std::cout<<"GEMMINI_SIM_PASS submitted="<<submitted<<" retired="<<retired<<" cycles="<<cycle<<" gets="<<gets<<" puts="<<puts<<"\n";
}
