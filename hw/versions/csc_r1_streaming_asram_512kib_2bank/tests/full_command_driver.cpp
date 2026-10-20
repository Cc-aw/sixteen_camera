#include "VCscCommandTrace.h"
#include "verilated.h"
#include <zlib.h>
#include <array>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <vector>

struct Command { unsigned frame, stage, funct; uint64_t a, b; };
struct Lane {
    VCscCommandTrace rtl;
    std::vector<Command> commands;
    size_t next = 0;
    unsigned frame = 0, stage = 0;
    uint64_t sequence = 0, rows = 0, emitted = 0;
    gzFile trace = nullptr;
};

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    if (argc != 4) { std::cerr << "commands.txt new_output_directory lanes(1/3)\n"; return 2; }
    const unsigned lanes = std::stoul(argv[3]);
    if (lanes != 1 && lanes != 3) return 2;
    const std::filesystem::path output(argv[2]);
    if (!std::filesystem::create_directory(output)) throw std::runtime_error("Output already exists");
    std::array<std::unique_ptr<Lane>, 3> state;
    for (unsigned i = 0; i < lanes; ++i) {
        state[i] = std::make_unique<Lane>();
        state[i]->trace = gzopen((output / ("commands_lane" + std::to_string(i) + ".csv.gz")).c_str(), "wb1");
        if (!state[i]->trace) throw std::runtime_error("Cannot open trace");
    }
    std::ifstream input(argv[1]);
    if (!input) throw std::runtime_error("Missing command file");
    unsigned lane; Command command;
    while (input >> lane >> command.frame >> command.stage >> command.funct >> command.a >> command.b) {
        if (lane < lanes) state[lane]->commands.push_back(command);
    }
    uint64_t cycle = 0;
    for (; cycle < 100000000; ++cycle) {
        bool all_done = cycle > 8;
        for (unsigned i = 0; i < lanes; ++i) {
            auto &s = *state[i]; auto &d = s.rtl;
            d.clock = 0; d.reset = cycle < 8; d.in_valid = 0;
            // Deterministic handshake stalls exercise the elastic pipelines.
            d.stall = cycle % 11 == i;
            d.eval();
            if (!d.reset && s.next < s.commands.size()) {
                const auto &c = s.commands[s.next];
                if (c.funct >= 253) {
                    if (!d.busy) {
                        s.frame = c.frame; s.stage = c.stage;
                        gzprintf(s.trace, "B,%llu,%u,%u,%u,%llu,%u\n", (unsigned long long)cycle, i, s.frame, s.stage,
                                 (unsigned long long)s.sequence++, c.funct);
                        ++s.next;
                    }
                } else {
                    d.in_valid = 1; d.in_funct = c.funct; d.in_rs1 = c.a; d.in_rs2 = c.b;
                }
            }
            d.eval();
            if (!d.reset) {
                if (d.in_valid && d.in_ready) ++s.next;
                if (d.cmd_fire) {
                    gzprintf(s.trace, "C,%llu,%u,%u,%u,%llu,%u,%llu,%llu,%u,%u\n", (unsigned long long)cycle,
                             i, s.frame, s.stage, (unsigned long long)s.sequence++, unsigned(d.cmd_funct),
                             (unsigned long long)d.cmd_rs1, (unsigned long long)d.cmd_rs2,
                             unsigned(d.cmd_conv), unsigned(d.cmd_ws));
                    ++s.emitted;
                }
                if (d.row_fire) {
                    gzprintf(s.trace, "R,%llu,%u,%u,%u,%llu,%u,%u,%u,%u,%u,%llu,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u\n",
                             (unsigned long long)cycle, i, s.frame, s.stage, (unsigned long long)s.sequence++,
                             unsigned(d.row_cmd_first), unsigned(d.row_cmd_last), unsigned(d.row_row_index),
                             unsigned(d.row_cmd_rows), unsigned(d.row_cmd_id), (unsigned long long)d.row_vaddr,
                             unsigned(d.row_laddr_data), unsigned(d.row_laddr_is_acc_addr), unsigned(d.row_cols),
                             unsigned(d.row_repeats), unsigned(d.row_scale), unsigned(d.row_has_acc_bitwidth),
                             unsigned(d.row_all_zeros), unsigned(d.row_block_stride), unsigned(d.row_pixel_repeats),
                             unsigned(d.row_cmd_stride_bytes));
                    ++s.rows;
                }
            }
            all_done &= s.next == s.commands.size() && !d.busy;
            d.clock = 1; d.eval();
        }
        if (all_done) break;
    }
    if (cycle == 100000000) throw std::runtime_error("RTL command enumeration timeout");
    for (unsigned i = 0; i < lanes; ++i) {
        auto &s = *state[i]; gzclose(s.trace); s.rtl.final();
        std::cout << "FULL_COMMAND_RTL_PASS lane=" << i << " native_words=" << s.commands.size()
                  << " emitted=" << s.emitted << " dma_rows=" << s.rows << " enumeration_ticks=" << cycle << "\n";
    }
}
