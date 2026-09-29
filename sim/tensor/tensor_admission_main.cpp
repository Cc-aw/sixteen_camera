#include "Vtensor_admission_top.h"
#include "verilated.h"

#include <cstdint>
#include <iostream>

double sc_time_stamp() { return 0.0; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtensor_admission_top top;
    top.clk = 0;
    top.resetn = 0;
    top.eval();

    for (uint64_t tick = 0; tick < 200000 && !top.done; ++tick) {
        if (tick == 16)
            top.resetn = 1;
        top.clk = !top.clk;
        top.eval();
    }

    if (!top.done || top.failed) {
        std::cerr << "TENSOR_ADMISSION_FAIL done=" << unsigned(top.done)
                  << " failed=" << unsigned(top.failed)
                  << " code=0x" << std::hex << unsigned(top.failure_code)
                  << " state=" << std::dec << unsigned(top.state_debug)
                  << " permit=0x" << std::hex << top.permit_debug
                  << " ready=0x" << top.ready_debug << std::dec
                  << " AW/W/B=" << top.aw_count_debug << '/'
                  << top.w_count_debug << '/' << top.b_count_debug
                  << " max=" << top.max_outstanding_debug << '\n';
        return 1;
    }
    std::cout << "TENSOR_ADMISSION_PASS dynamic_limit=8_to_1 "
              << "simultaneous_sof=2 ready_after_b=1 "
              << "AW=" << top.aw_count_debug
              << " W=" << top.w_count_debug
              << " B=" << top.b_count_debug
              << " max_outstanding=" << top.max_outstanding_debug << '\n';
    return 0;
}
