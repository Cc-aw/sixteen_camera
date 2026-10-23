// Native table replay through the actual S1 Frontend/MemoryMux/Gemmini/ASRAM.
// External DDR is a private deterministic functional service, not a MIG/L2.
#include "VS1TeamReplay.h"
#include "verilated.h"
#include <array>
#include <cstdint>
#include <deque>
#include <fstream>
#include <iostream>
#include <limits>
#include <map>
#include <string>
#include <stdexcept>
#include <unordered_map>
#include <vector>

struct Memory {
    std::unordered_map<uint64_t, std::array<uint8_t, 4096>> pages;
    uint8_t get(uint64_t a) const {
        auto p = pages.find(a >> 12);
        return p == pages.end() ? 0 : p->second[a & 4095];
    }
    void put(uint64_t a, uint8_t v) { pages[a >> 12][a & 4095] = v; }
    void word(uint64_t a, uint64_t v) {
        for (unsigned i = 0; i < 8; ++i) put(a + i, uint8_t(v >> (8 * i)));
    }
    void init(const char *path) {
        std::ifstream in(path, std::ios::binary);
        if (!in) throw std::runtime_error("Missing memory image");
        uint64_t a;
        uint32_t n;
        while (in.read(reinterpret_cast<char *>(&a), 8)) {
            if (!in.read(reinterpret_cast<char *>(&n), 4)) throw std::runtime_error("Truncated image header");
            for (unsigned i = 0; i < n; ++i) {
                char v;
                if (!in.get(v)) throw std::runtime_error("Truncated image data");
                put(a + i, uint8_t(v));
            }
        }
        if (!in.eof()) throw std::runtime_error("Bad memory image");
    }
    void dump(uint64_t address, unsigned bytes, const std::string &path) const {
        std::ofstream out(path, std::ios::binary);
        if (!out) throw std::runtime_error("Cannot create tensor dump");
        for (unsigned i=0;i<bytes;++i) out.put(char(get(address+i)));
        if (!out) throw std::runtime_error("Failed tensor dump");
    }
    void pad(uint64_t src, uint64_t dst) {
        constexpr unsigned h = 15, w = 20, c = 128, stride = (w + 2) * c;
        for (unsigned i = 0; i < (h + 2) * stride; ++i) put(dst + i, 128);
        for (unsigned y = 0; y < h; ++y)
            for (unsigned i = 0; i < w * c; ++i) put(dst + (y + 1) * stride + c + i, get(src + y * w * c + i));
    }
};
struct Entry { unsigned stage, funct; uint64_t a, b; };
struct Response { uint64_t address, available; unsigned source, size, opcode, beat, beats; };
struct Snapshot { std::string name; uint64_t address; unsigned bytes; };
struct Metrics {
    uint64_t cycle, gets, fetches, scale, bank_wait;
    uint32_t logical_bytes, path_switch, completion_wait;
};
struct Stage {
    size_t first=std::numeric_limits<size_t>::max(), last=0;
    bool started=false, completed=false;
    Metrics begin{}, end{};
};

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    if (argc < 7) {
        std::cerr << "table.txt memory.bin max_cycles ddr_delay summary.txt outputs.txt\n";
        return 2;
    }
    Memory memory;
    memory.init(argv[2]);
    const uint64_t max_cycles = std::stoull(argv[3]), delay = std::stoull(argv[4]);
    std::vector<Entry> table;
    std::ifstream commands(argv[1]);
    if (!commands) throw std::runtime_error("Missing table");
    Entry e;
    while (commands >> e.stage >> e.funct >> e.a >> e.b) table.push_back(e);
    if (!commands.eof() || table.empty()) throw std::runtime_error("Bad/empty table");
    std::vector<Snapshot> snapshots;
    std::ifstream layout(argv[6]);
    if (!layout) throw std::runtime_error("Missing tensor layout");
    Snapshot snapshot;
    while (layout >> snapshot.name >> snapshot.address >> snapshot.bytes) snapshots.push_back(snapshot);
    if (!layout.eof() || snapshots.empty()) throw std::runtime_error("Bad tensor layout");
    std::map<unsigned,Stage> stages;
    for (size_t i = 0; i < table.size(); ++i) {
        const auto &c = table[i];
        auto &stage=stages[c.stage];stage.first=std::min(stage.first,i);stage.last=i+1;
        const auto base = 0xc0000000ULL + i * 32;
        const auto kind = c.funct == 255 ? 1 : c.funct == 254 ? 2 : 0;
        memory.word(base, kind ? kind : uint64_t(c.funct) << 8);
        memory.word(base + 8, kind == 2 ? i : c.a);
        memory.word(base + 16, kind ? 0 : c.b);
        memory.word(base + 24, 0);
    }
    VS1TeamReplay d;
    d.clock = 0;
    d.reset = 1;
    d.table_count = table.size();
    std::deque<Response> responses;
    unsigned write_beat = 0, local_beat = 0;
    bool host_serviced = false;
    uint64_t gets = 0, puts = 0, acks = 0, cycles = 0;
    uint64_t frontend_gets=0, scale_tasks=0, bank_wait=0;
    unsigned max_rs_idle=0;
    auto metrics = [&]() {return Metrics{cycles,gets,frontend_gets,scale_tasks,bank_wait,
        d.logical_read_bytes,d.path_switch_cycles,d.completion_wait_cycles};};
    // Keep the selected D beat stable across a stalled acceptance and stores.
    std::array<uint32_t, 8> held{};
    bool held_valid = false;
    auto advance = [&](uint64_t delta) {
        const auto target = Verilated::time() + delta;
        while (d.eventsPending() && d.nextTimeSlot() <= target) {
            const auto next = d.nextTimeSlot();
            if (next < Verilated::time()) throw std::runtime_error("Missed timing event");
            Verilated::timeInc(next - Verilated::time());
            d.eval();
        }
        Verilated::timeInc(target - Verilated::time());
    };
    for (; cycles < max_cycles; ++cycles) {
        d.clock = 0;
        d.reset = cycles < 16;
        d.start = cycles == 20;
        d.resume = 0;
        d.a_ready = !d.reset && responses.size() < 8 && cycles % 11 != 0;
        d.d_valid = !responses.empty() && responses.front().available <= cycles;
        if (d.d_valid) {
            const auto &r = responses.front();
            d.d_opcode = r.opcode;
            d.d_size = r.size;
            d.d_source = r.source;
            d.d_param = 0;
            d.d_sink = 0;
            d.d_denied = 0;
            d.d_corrupt = 0;
            if (!held_valid) {
                for (unsigned j = 0; j < 8; ++j) {
                    uint32_t v = 0;
                    for (unsigned b = 0; b < 4; ++b) v |= uint32_t(memory.get(r.address + r.beat * 32 + j * 4 + b)) << (8 * b);
                    held[j] = v;
                }
                held_valid = true;
            }
            std::copy(held.begin(), held.end(), d.d_data.data());
        }
        d.eval();
        for (auto &item:stages) {
            auto &stage=item.second;
            if (!stage.started && d.cursor>stage.first) {stage.started=true;stage.begin=metrics();}
        }
        if (d.host_wait && !host_serviced) {
            const auto &c = table.at(d.host_tag);
            if (c.funct != 254) throw std::runtime_error("Unknown HOST tag");
            if (c.a || c.b) {
                if (!c.a || !c.b || c.stage < 75 || c.stage > 77) throw std::runtime_error("Unknown HOST geometry");
                memory.pad(c.a, c.b);
            }
            host_serviced = true;
            d.resume = 1;
            d.eval();
        } else if (!d.host_wait) host_serviced = false;
        if (!d.reset) {
            max_rs_idle=std::max(max_rs_idle,unsigned(d.rs_idle));
            if(d.rs_idle==9990 || d.rs_idle==19990 || d.rs_idle==39990)
                std::cout<<"S1_LONG_COMMAND cycle="<<cycles<<" cursor="<<d.cursor
                    <<" completed="<<d.completed_cursor<<" rs_idle="<<d.rs_idle
                    <<" gets="<<gets<<" puts="<<puts<<" pending="<<responses.size()<<std::endl;
            scale_tasks+=d.scale_tasks;bank_wait+=d.bank_write_wait;
            if (d.fault) throw std::runtime_error("Frontend fault " + std::to_string(d.error_code));
            if (d.d_valid && d.d_ready) {
                auto &r = responses.front();
                if (r.opcode == 0) ++acks;
                if (++r.beat == r.beats) responses.pop_front();
                held_valid = false;
            }
            if (d.a_valid && d.a_ready) {
                const unsigned opcode = d.a_opcode, size = d.a_size, source = d.a_source;
                if (size > 6 || d.a_corrupt || (d.a_address & ((1ULL << size) - 1))) throw std::runtime_error("Invalid TL A");
                if (opcode == 4) {
                    responses.push_back({d.a_address & ~31ULL, cycles + delay + 1, source, size, 1, 0, size > 5 ? 2u : 1u});
                    ++gets;
                    if(source==31)++frontend_gets;
                } else if (opcode <= 1) {
                    const auto base = (d.a_address & ~31ULL) + write_beat * 32;
                    for (unsigned b = 0; b < 32; ++b)
                        if ((d.a_mask >> b) & 1) memory.put(base + b, uint8_t(d.a_data[b / 4] >> (8 * (b % 4))));
                    if (size <= 5 || ++write_beat == 2) {
                        write_beat = 0;
                        responses.push_back({0, cycles + delay + 1, source, size, 0, 0, 1});
                        ++puts;
                    }
                } else throw std::runtime_error("Unknown TL opcode");
            }
            // Mirror accepted local writes for the drained CPU HOST padding
            // service only. DMA local reads always use the actual ASRAM RTL.
            if (d.local_put) {
                const auto base = (d.local_address & ~31ULL) + local_beat * 32;
                for (unsigned b = 0; b < 32; ++b)
                    if ((d.local_mask >> b) & 1) memory.put(base + b, uint8_t(d.local_data[b / 4] >> (8 * (b % 4))));
                if (d.local_size <= 5 || ++local_beat == 2) local_beat = 0;
            }
        }
        advance(5000);
        d.clock = 1;
        d.eval();
        advance(5000);
        for (auto &item:stages) {
            auto &stage=item.second;
            if (!stage.completed && d.completed_cursor>=stage.last) {
                if(!stage.started) {stage.started=true;stage.begin=metrics();}
                stage.completed=true;stage.end=metrics();
                for(const auto &s:snapshots)if(s.name=="stage"+std::to_string(item.first))
                    memory.dump(s.address,s.bytes,std::string(argv[5])+"."+s.name+".bin");
            }
        }
        if(cycles && cycles%1000000==0)
            std::cout<<"S1_TEAM_REPLAY_PROGRESS cycles="<<cycles<<" cursor="<<d.cursor<<std::endl;
        if (d.done) {
            if (d.gem_busy || !responses.empty() || write_beat || local_beat || puts != acks || d.completed_cursor != table.size())
                throw std::runtime_error("Completion before drain");
            d.final();
            for(const auto &s:snapshots)if(s.name.rfind("stage",0)!=0)
                memory.dump(s.address,s.bytes,std::string(argv[5])+"."+s.name+".bin");
            std::ofstream stage_csv(std::string(argv[5])+".stages.csv");
            stage_csv<<"stage,first_cycle,last_cycle,cycles,ddr_data_gets,frontend_gets,scale_tasks,logical_read_bytes,path_switch_cycles,bank_write_wait_cycles,completion_wait_cycles\n";
            for(const auto &item:stages) {
                const auto &s=item.second;const auto &a=s.begin;const auto &b=s.end;
                if(!s.completed)throw std::runtime_error("Incomplete stage accounting");
                stage_csv<<item.first<<","<<a.cycle<<","<<b.cycle<<","<<b.cycle-a.cycle<<","
                    <<(b.gets-a.gets)-(b.fetches-a.fetches)<<","<<b.fetches-a.fetches<<","
                    <<b.scale-a.scale<<","<<uint32_t(b.logical_bytes-a.logical_bytes)<<","
                    <<uint32_t(b.path_switch-a.path_switch)<<","<<b.bank_wait-a.bank_wait<<","
                    <<uint32_t(b.completion_wait-a.completion_wait)<<"\n";
            }
            std::ofstream summary(argv[5]);
            summary << "S1_TEAM_REPLAY_PASS cycles=" << cycles + 1 << " entries=" << table.size()
                    << " ddr_gets=" << gets << " ddr_puts=" << puts << " ddr_acks=" << acks << "\n";
            summary<<"frontend_gets="<<frontend_gets<<" scale_tasks="<<scale_tasks
                   <<" bank_write_wait_cycles="<<bank_wait<<" max_rs_idle="<<max_rs_idle<<"\n";
            std::cout << "S1_TEAM_REPLAY_PASS cycles=" << cycles + 1 << std::endl;
            return 0;
        }
    }
    throw std::runtime_error("P0 replay timeout cursor=" + std::to_string(d.cursor));
}
