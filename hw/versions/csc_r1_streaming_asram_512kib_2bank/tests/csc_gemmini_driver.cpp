#include "VFullGemmini.h"
#include "verilated.h"
#include <zlib.h>
#include <array>
#include <cstdint>
#include <deque>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <unordered_map>
#include <vector>

struct Command { unsigned frame,stage,funct; uint64_t a,b; };
struct Memory {
    std::unordered_map<uint64_t,std::array<uint8_t,4096>> pages;
    uint8_t get(uint64_t a) const { auto p=pages.find(a>>12);return p==pages.end()?0:p->second[a&4095]; }
    void put(uint64_t a,uint8_t v){pages[a>>12][a&4095]=v;}
    void init(const char *name) {
        std::ifstream input(name,std::ios::binary);if(!input)throw std::runtime_error("Missing memory image");
        uint64_t a;uint32_t n;
        while(input.read(reinterpret_cast<char *>(&a),8)) {
            if(!input.read(reinterpret_cast<char *>(&n),4))throw std::runtime_error("Bad memory header");
            for(unsigned i=0;i<n;++i){char b;if(!input.get(b))throw std::runtime_error("Truncated memory");put(a+i,uint8_t(b));}
        }
    }
    void pad(uint64_t src,uint64_t dst) {
        // Exact frozen memory_pool5 geometry, checked by the capture manifest.
        constexpr unsigned h=15,w=20,c=128,stride=(w+2)*c;
        for(unsigned i=0;i<(h+2)*stride;++i)put(dst+i,128);
        for(unsigned y=0;y<h;++y)for(unsigned i=0;i<w*c;++i)put(dst+(y+1)*stride+c+i,get(src+y*w*c+i));
    }
};
struct Response { uint64_t address;unsigned source,size,beat=0,beats,opcode; };
struct Write { unsigned address,mask,kind,id;std::array<uint32_t,8> data; };
struct Lane {
    VFullGemmini rtl;Memory memory;std::vector<Command> commands;size_t next=0;
    unsigned frame=0,stage=0,write_beat=0;uint64_t sequence=0,rows=0,gets=0,get_bytes=0,commits=0,reads=0;
    uint64_t tile_requests=0,tile_skips=0,skip_completions=0;
    std::deque<Response> responses;std::array<std::deque<Write>,8> pending;
    std::array<uint32_t,8> held_data{};bool held_valid=false,metric_live=false;
    std::array<uint64_t,8> metrics{};
    gzFile trace=nullptr;bool finished=false;
};
static void wide(gzFile f,const uint32_t *data){for(int i=7;i>=0;--i)gzprintf(f,"%08x",data[i]);}
static void flush_metrics(Lane &s,unsigned lane,uint64_t cycle){
    if(!s.metric_live)return;
    gzprintf(s.trace,"S,%llu,%u,%u,%u,%llu",(unsigned long long)cycle,lane,s.frame,s.stage,(unsigned long long)s.sequence++);
    for(auto value:s.metrics)gzprintf(s.trace,",%llu",(unsigned long long)value);
    gzprintf(s.trace,"\n");s.metrics.fill(0);s.metric_live=false;
}
int main(int argc,char **argv) {
    Verilated::commandArgs(argc,argv);
    if(argc<9){std::cerr<<"commands.txt memory.bin new_output lanes(1/3) frames(1/2) last_stage enabled mode [plusargs]\n";return 2;}
    unsigned lanes=std::stoul(argv[4]),frames=std::stoul(argv[5]),last_stage=std::stoul(argv[6]);
    unsigned enabled=std::stoul(argv[7]),mode=std::stoul(argv[8]);
    if(enabled>1||mode>3)return 2;
    if((lanes!=1&&lanes!=3)||frames<1||frames>4||last_stage>165)return 2;
    if(!std::filesystem::create_directory(argv[3]))throw std::runtime_error("Output exists");
    std::array<std::unique_ptr<Lane>,3> state;
    const bool compact=std::filesystem::is_directory(argv[2]);
    for(unsigned i=0;i<lanes;++i){state[i]=std::make_unique<Lane>();if(!compact)state[i]->memory.init(argv[2]);
        state[i]->trace=gzopen((std::filesystem::path(argv[3])/("full_lane"+std::to_string(i)+".csv.gz")).c_str(),"wb1");
        if(!state[i]->trace)throw std::runtime_error("Trace open failed");}
    std::ifstream input(argv[1]);if(!input)throw std::runtime_error("Missing commands");
    unsigned lane;Command command;
    while(input>>lane>>command.frame>>command.stage>>command.funct>>command.a>>command.b)
        if(lane<lanes && command.frame<frames && command.stage<=last_stage)state[lane]->commands.push_back(command);
    for(unsigned i=0;i<lanes;++i){state[i]->rtl.clock=0;state[i]->rtl.reset=1;state[i]->rtl.eval();}
    auto advance=[&](uint64_t step){
        uint64_t target=Verilated::time()+step;
        for(;;){uint64_t next=target+1;
            for(unsigned j=0;j<lanes;++j)if(!state[j]->finished&&state[j]->rtl.eventsPending())
                next=std::min(next,state[j]->rtl.nextTimeSlot());
            if(next>target)break;
            if(next<Verilated::time())throw std::runtime_error("Missed vendor timing slot");
            Verilated::timeInc(next-Verilated::time());
            for(unsigned j=0;j<lanes;++j)if(!state[j]->finished)state[j]->rtl.eval();
        }
        Verilated::timeInc(target-Verilated::time());
    };
    uint64_t cycle=0;
    for(;cycle<200000000;++cycle) {
        advance(5000);
        bool all_done=cycle>16;
        for(unsigned i=0;i<lanes;++i) {
            auto &s=*state[i];auto &d=s.rtl;
            if(s.finished)continue;
            d.clock=0;d.reset=cycle<16;d.io_cmd_valid=0;d.io_dma_load_mode=mode;
            d.csc_enabled=enabled;d.csc_clear=0;
            d.auto_spad_id_out_a_ready=!d.reset && s.responses.size()<8 && cycle%11!=i;
            d.auto_spad_id_out_d_valid=!s.responses.empty();
            if(!s.responses.empty()) {
                const auto &r=s.responses.front();d.auto_spad_id_out_d_bits_opcode=r.opcode;
                d.auto_spad_id_out_d_bits_size=r.size;d.auto_spad_id_out_d_bits_source=r.source;
                d.auto_spad_id_out_d_bits_denied=0;d.auto_spad_id_out_d_bits_corrupt=0;
                if(!s.held_valid){for(unsigned j=0;j<8;++j){uint32_t word=0;for(unsigned b=0;b<4;++b)
                    word|=uint32_t(s.memory.get(r.address+r.beat*32+j*4+b))<<(8*b);
                    s.held_data[j]=word;}s.held_valid=true;}
                std::copy(s.held_data.begin(),s.held_data.end(),d.auto_spad_id_out_d_bits_data.data());
            }
            d.eval();
            if(!d.reset && s.next<s.commands.size()) {
                const auto &c=s.commands[s.next];
                if(c.funct>=253) {
                    // Stage markers label events; only native fences/HOST drain.
                    if(c.funct==253 || (!d.io_busy && s.responses.empty())) {
                        d.csc_clear=c.funct!=253 || c.frame!=s.frame;
                        if(c.funct==253){flush_metrics(s,i,cycle);s.metric_live=true;}
                        s.frame=c.frame;s.stage=c.stage;
                        if(compact&&c.funct==253)s.memory.init((std::filesystem::path(argv[2])/("lane"+std::to_string(i)+"_stage"+std::to_string(c.stage)+".bin")).c_str());
                        gzprintf(s.trace,"B,%llu,%u,%u,%u,%llu,%u,%llu,%llu\n",(unsigned long long)cycle,i,s.frame,s.stage,
                                 (unsigned long long)s.sequence++,c.funct,(unsigned long long)c.a,(unsigned long long)c.b);
                        if(c.funct==254 && c.a && c.b){if(c.stage<75||c.stage>77)throw std::runtime_error("Unknown HOST");s.memory.pad(c.a,c.b);}
                        if(c.funct==253)std::cout<<"FULL_RTL_STAGE lane="<<i<<" frame="<<c.frame<<" stage="<<c.stage<<" cycle="<<cycle<<std::endl;
                        ++s.next;
                    }
                }else{d.io_cmd_valid=1;d.io_cmd_bits_inst_funct=c.funct;d.io_cmd_bits_rs1=c.a;d.io_cmd_bits_rs2=c.b;}
            }
            d.eval();
            auto prefix=[&](char event){gzprintf(s.trace,"%c,%llu,%u,%u,%u,%llu",event,(unsigned long long)cycle,i,s.frame,s.stage,(unsigned long long)s.sequence++);};
            if(!d.reset) {
                if(d.csc_accept){++s.tile_requests;s.tile_skips+=d.csc_skip;
                    prefix('K');gzprintf(s.trace,",%u,%u,%u,%u,",unsigned(d.csc_skip),unsigned(d.csc_supported),unsigned(d.csc_half),unsigned(d.csc_rows));
                    wide(s.trace,d.csc_key.data());gzprintf(s.trace,"\n");}
                if(d.csc_done){++s.skip_completions;prefix('N');gzprintf(s.trace,"\n");}
                if(d.io_interrupt)throw std::runtime_error("Real Gemmini interrupt");
                if(d.io_cmd_valid&&d.io_cmd_ready){const auto &c=s.commands[s.next++];prefix('C');
                    gzprintf(s.trace,",%u,%llu,%llu\n",c.funct,(unsigned long long)c.a,(unsigned long long)c.b);}
                if(d.complete_valid){prefix('X');gzprintf(s.trace,",%u\n",unsigned(d.complete_rob));}
                if(d.credit_valid){prefix('Y');gzprintf(s.trace,",%u,%u\n",unsigned(d.credit_id),unsigned(d.credit_bytes));}
                if(d.row_fire) {
                    prefix('R');gzprintf(s.trace,",%u,%u,%u,%u,%u,%llu,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u\n",
                        unsigned(d.row_cmd_first),unsigned(d.row_cmd_last),unsigned(d.row_row_index),unsigned(d.row_cmd_rows),
                        unsigned(d.row_cmd_id),(unsigned long long)d.row_vaddr,unsigned(d.row_laddr_data),unsigned(d.row_laddr_is_acc_addr),
                        unsigned(d.row_cols),unsigned(d.row_repeats),unsigned(d.row_scale),unsigned(d.row_has_acc_bitwidth),
                        unsigned(d.row_all_zeros),unsigned(d.row_block_stride),unsigned(d.row_pixel_repeats),unsigned(d.row_cmd_stride_bytes),unsigned(d.row_rob));++s.rows;
                }
                if(d.get_reserve){prefix('G');gzprintf(s.trace,",%u,%u\n",unsigned(d.get_source),unsigned(d.get_cmd));}
                for(unsigned b=0;b<8;++b) {
                    if(d.wc>>b&1) {
                        if(s.pending[b].empty())throw std::runtime_error("Commit without bank acceptance");
                        auto w=s.pending[b].front();s.pending[b].pop_front();
                        if(w.address!=d.wc_addr[b]||w.mask!=d.wc_mask[b]||!std::equal(w.data.begin(),w.data.end(),d.wc_data[b].data()))
                            throw std::runtime_error("Physical SRAM commit mismatch");
                        prefix('W');gzprintf(s.trace,",%u,%u,%u,%u,%u,",b,w.address,w.mask,w.kind,w.id);wide(s.trace,w.data.data());gzprintf(s.trace,"\n");++s.commits;
                    }
                    if(d.wa>>b&1) {
                        Write w{unsigned(d.wa_addr[b]),unsigned(d.wa_mask[b]),unsigned((d.wx>>b&1)?1:(d.wz>>b&1)?2:0),unsigned(d.wa_id[b]),{}};
                        std::copy(d.wa_data[b].data(),d.wa_data[b].data()+8,w.data.begin());s.pending[b].push_back(w);
                        prefix('A');gzprintf(s.trace,",%u,%u,%u,%u,%u,",b,w.address,w.mask,w.kind,w.id);wide(s.trace,w.data.data());gzprintf(s.trace,"\n");
                    }
                    if(d.ri>>b&1){prefix('I');gzprintf(s.trace,",%u,%u\n",b,unsigned(d.ri_addr[b]));}
                    if(d.rr>>b&1){prefix('Q');gzprintf(s.trace,",%u,%u\n",b,unsigned(d.rr_addr[b]));++s.reads;}
                    if(d.rd>>b&1){prefix('V');gzprintf(s.trace,",%u,",b);wide(s.trace,d.rd_data[b].data());gzprintf(s.trace,"\n");}
                }
                if(d.auto_spad_id_out_d_valid&&d.auto_spad_id_out_d_ready) {
                    prefix('D');const auto &r=s.responses.front();gzprintf(s.trace,",%u,%u,%u,%u,",r.source,r.size,r.opcode,r.beat);
                    wide(s.trace,d.auto_spad_id_out_d_bits_data.data());gzprintf(s.trace,"\n");
                    if(++s.responses.front().beat==s.responses.front().beats)s.responses.pop_front();
                    s.held_valid=false;
                }
                if(d.auto_spad_id_out_a_valid&&d.auto_spad_id_out_a_ready) {
                    unsigned opcode=d.auto_spad_id_out_a_bits_opcode,size=d.auto_spad_id_out_a_bits_size,source=d.auto_spad_id_out_a_bits_source;
                    uint64_t a=d.auto_spad_id_out_a_bits_address;unsigned mask=d.auto_spad_id_out_a_bits_mask;
                    if(size>6||d.auto_spad_id_out_a_bits_corrupt)throw std::runtime_error("Invalid TL A");
                    prefix('T');gzprintf(s.trace,",%u,%u,%u,%llu,%u,",opcode,source,size,(unsigned long long)a,mask);
                    wide(s.trace,d.auto_spad_id_out_a_bits_data.data());gzprintf(s.trace,"\n");
                    if(opcode==4){s.responses.push_back(Response{a&~uint64_t(31),source,size,0,size>5?2u:1u,1});++s.gets;s.get_bytes+=uint64_t(1)<<size;}
                    else if(opcode<=1) {
                        uint64_t base=(a&~uint64_t(31))+s.write_beat*32;
                        for(unsigned j=0;j<32;++j)if(mask>>j&1)s.memory.put(base+j,uint8_t(d.auto_spad_id_out_a_bits_data[j/4]>>(8*(j%4))));
                        if(size<=5||++s.write_beat==2){s.write_beat=0;s.responses.push_back(Response{0,source,size,0,1,0});}
                    }else throw std::runtime_error("Unknown TL opcode");
                }
            }
            if(!d.reset&&s.metric_live){++s.metrics[0];
                for(unsigned k=0;k<6;++k)s.metrics[k+1]+=(d.metric_signals>>k)&1;
                s.metrics[7]+=(d.metric_signals&14)!=0;}
            bool done=cycle>16&&s.next==s.commands.size()&&!d.io_busy&&s.responses.empty();
            for(auto &q:s.pending)done &= q.empty();
            all_done &= done;
            if(done){flush_metrics(s,i,cycle+1);s.finished=true;gzclose(s.trace);d.final();std::cout<<"FULL_GEMMINI_RTL_PASS lane="<<i<<" native_words="<<s.next
                <<" dma_rows="<<s.rows<<" real_gets="<<s.gets<<" real_get_bytes="<<s.get_bytes<<" physical_commits="<<s.commits
                <<" accepted_spad_reads="<<s.reads<<" functional_cycles="<<cycle
                <<" input_tiles="<<s.tile_requests<<" skipped_tiles="<<s.tile_skips<<" skip_completions="<<s.skip_completions<<std::endl;
                if(s.tile_skips!=s.skip_completions)throw std::runtime_error("CSC completion ledger mismatch");}
            if(i==0)advance(5000);
            d.clock=1;d.eval();
        }
        if(all_done)break;
    }
    if(cycle==200000000)throw std::runtime_error("Full Gemmini functional timeout");
}
