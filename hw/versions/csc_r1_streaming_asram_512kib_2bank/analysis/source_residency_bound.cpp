// Optimistic source-identity bound, not a numerical SRAM or completion model.
#include <zlib.h>
#include <algorithm>
#include <array>
#include <charconv>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <limits>
#include <map>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

static constexpr unsigned CELLS=16384*32;
static constexpr uint64_t UNKNOWN=std::numeric_limits<uint64_t>::max();
struct Stats {
    uint64_t commands=0,spad=0,zeros=0,acc=0,gets=0,bytes=0,logical=0;
    uint64_t exact=0,exact_data=0,exact_bytes=0,exact_zero=0,written=0,relocatable=0,partial=0,spad_stores=0;
};
struct Row {
    uint64_t address; unsigned dest,acc,cols,repeats,scale,wide,zero,stride,pixels;
};

static std::vector<uint64_t> parse(const char *line) {
    std::vector<uint64_t> values;
    const char *p=line+2;
    while (*p && *p!='\n') {
        uint64_t value=0;auto result=std::from_chars(p,p+std::char_traits<char>::length(p),value);
        if(result.ec!=std::errc())throw std::runtime_error("Malformed numeric trace");
        values.push_back(value);p=result.ptr;if(*p==',')++p;else break;
    }
    return values;
}
static std::pair<uint64_t,uint64_t> fragments(uint64_t address,unsigned count) {
    uint64_t gets=0,bytes=0;
    while(count) {
        unsigned a=std::min(count,32-unsigned(address%32)), b=std::min(count,64-unsigned(address%64));
        unsigned useful=b>a?b:a,size=b>a?64:32;
        ++gets;bytes+=size;address+=useful;count-=useful;
    }
    return {gets,bytes};
}
int main(int argc,char **argv) {
    if(argc!=3){std::cerr<<"trace.csv.gz new_report.csv\n";return 2;}
    gzFile file=gzopen(argv[1],"rb");if(!file)throw std::runtime_error("Missing trace");
    std::vector<uint64_t> resident(CELLS,UNKNOWN), expected(CELLS,UNKNOWN);
    std::vector<unsigned> stamps(CELLS,0),touched;
    std::unordered_map<uint64_t,unsigned> token_counts;
    std::map<std::pair<unsigned,unsigned>,Stats> stats;
    std::vector<Row> rows;unsigned command_id=0,command_rows=0;uint64_t sequence=0;
    unsigned frame=0,stage=0,lane=0;bool in_command=false;
    char line[2048];
    while(gzgets(file,line,sizeof(line))) {
        auto v=parse(line);if(v.size()<6)throw std::runtime_error("Short trace");
        if(v[4]!=sequence++)throw std::runtime_error("Noncontiguous sequence");
        lane=v[1];frame=v[2];stage=v[3];auto &s=stats[{frame,stage}];
        if(line[0]=='C') {
            if(v[5]==23)++s.spad_stores;
            continue;
        }
        if(line[0]=='B') {
            if(in_command)throw std::runtime_error("Boundary within Load");
            continue;
        }
        if(line[0]!='R' || v.size()!=21)throw std::runtime_error("Unknown row event");
        if(v[5]) {
            if(in_command)throw std::runtime_error("Nested Load");
            in_command=true;rows.clear();command_rows=v[8];++command_id;touched.clear();
        }
        if(!in_command || v[7]!=rows.size())throw std::runtime_error("Row gap");
        rows.push_back(Row{v[10],unsigned(v[11]),unsigned(v[12]),unsigned(v[13]),unsigned(v[14]),
                           unsigned(v[15]),unsigned(v[16]),unsigned(v[17]),unsigned(v[18]),unsigned(v[19])});
        if(!v[6])continue;
        if(rows.size()!=command_rows)throw std::runtime_error("Truncated Load");
        in_command=false;++s.commands;const auto &first=rows[0];
        uint64_t get_count=0,get_bytes=0;
        s.logical+=uint64_t(rows.size())*first.cols*(first.wide?4:1);
        bool group=!first.acc && !first.wide && !first.repeats && first.cols>0 && first.cols<32 &&
                   first.pixels>0 && first.pixels*first.cols<=32 && rows.size()<=32 &&
                   first.dest+rows.size()<=16384 && first.dest/8192==(first.dest+rows.size()-1)/8192 &&
                   ((rows.size()>1 && v[20]==first.cols)||first.pixels>1);
        if(!first.zero) {
            if(group && v[20]==first.cols) {
                auto f=fragments(first.address,first.cols*rows.size());get_count=f.first;get_bytes=f.second;
            } else {
                for(const auto &r:rows){auto f=fragments(r.address,r.cols*(r.wide?4:1));get_count+=f.first;get_bytes+=f.second;}
            }
        }
        s.gets+=get_count;s.bytes+=get_bytes;
        if(first.acc){++s.acc;continue;}
        ++s.spad;if(first.zero)++s.zeros;
        // Reconstruct final per-byte source origin using the original channel
        // block stride and PixelRepeater's half-boundary clipping. Versions,
        // EX overwrites, pending writes and dependency checks are ignored.
        for(const auto &r:rows) {
            if(!r.pixels || r.wide)throw std::runtime_error("Unsupported SPAD geometry");
            for(unsigned block=0;block<(r.cols+31)/32;++block) {
                unsigned length=std::min(32u,r.cols-block*32);
                for(unsigned repeat=0;repeat<=r.repeats;++repeat) {
                    unsigned address=(r.dest+block*r.stride+repeat)%16384, floor=address<8192?0:8192;
                    for(int pixel=int(r.pixels)-1;pixel>=0;--pixel) {
                        if(address<unsigned(pixel)+floor)continue;
                        unsigned target=address-pixel;
                        for(unsigned byte=0;byte<length && unsigned(pixel)*length+byte<32;++byte) {
                            unsigned cell=target*32+unsigned(pixel)*length+byte;
                            if(stamps[cell]!=command_id){stamps[cell]=command_id;touched.push_back(cell);}
                            expected[cell]=r.zero?0:((r.address+block*32+byte+1)<<16)|r.scale;
                        }
                    }
                }
            }
        }
        bool exact=!touched.empty(),all_available=true;uint64_t available=0;
        for(unsigned cell:touched) {
            exact &= resident[cell]==expected[cell];
            bool present=token_counts.find(expected[cell])!=token_counts.end();
            all_available &= present;available+=present;
        }
        if(exact){++s.exact;s.exact_bytes+=get_bytes;if(first.zero)++s.exact_zero;else ++s.exact_data;}
        if(!exact && all_available)++s.relocatable;
        if(!all_available) s.partial+=available;
        s.written+=touched.size();
        for(unsigned cell:touched) {
            auto old=resident[cell], value=expected[cell];
            if(old==value)continue;
            if(old!=UNKNOWN) {
                auto it=token_counts.find(old);if(it==token_counts.end())throw std::runtime_error("Token ledger");
                if(--it->second==0)token_counts.erase(it);
            }
            resident[cell]=value;++token_counts[value];
        }
    }
    int error=Z_OK;gzerror(file,&error);gzclose(file);
    if(error!=Z_OK || in_command)throw std::runtime_error("Incomplete gzip/command");
    if(std::ifstream(argv[2]).good())throw std::runtime_error("Report already exists");
    std::ofstream report(argv[2]);
    report<<"lane,frame,stage,mvin_commands,spad_commands,zero_commands,acc_commands,modeled_gets,modeled_get_bytes,logical_bytes,optimistic_exact_commands,optimistic_exact_data_commands,optimistic_exact_get_bytes,optimistic_exact_zero_commands,spad_byte_footprint,same_source_diff_destination_upper_commands,partial_source_overlap_upper_bytes,ignored_spad_store_commands\n";
    for(const auto &entry:stats) {
        const auto &s=entry.second;
        report<<lane<<','<<entry.first.first<<','<<entry.first.second<<','<<s.commands<<','<<s.spad<<','<<s.zeros<<','<<s.acc<<','<<s.gets<<','<<s.bytes<<','<<s.logical<<','<<s.exact<<','<<s.exact_data<<','<<s.exact_bytes<<','<<s.exact_zero<<','<<s.written<<','<<s.relocatable<<','<<s.partial<<','<<s.spad_stores<<'\n';
    }
    std::cout<<"SOURCE_IDENTITY_OPTIMISTIC_BOUND_COMPLETE lane="<<lane<<" events="<<sequence<<"\n";
}
