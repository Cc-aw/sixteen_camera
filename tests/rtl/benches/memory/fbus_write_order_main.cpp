#include "Vfbus_write_order_top.h"
#include "verilated.h"

#include <cstdint>
#include <iostream>

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vfbus_write_order_top top;
    top.s_clk = 0;
    top.m_clk = 0;
    top.s_resetn = 0;
    top.m_resetn = 0;
    top.eval();

    for (uint64_t tick = 1; tick < 200000 && !top.done; ++tick) {
        if (tick == 24) {
            top.s_resetn = 1;
            top.m_resetn = 1;
        }
        if ((tick % 2) == 0)
            top.s_clk = !top.s_clk;
        if ((tick % 3) == 0)
            top.m_clk = !top.m_clk;
        top.eval();
    }

    if (!top.done || top.failed || top.aw_count != 8 || top.w_count != 8 ||
        top.b_count != 8 || top.outstanding_current != 0 ||
        top.outstanding_max != 8 || top.write_id_mask != 0xff000000U ||
        top.protocol_errors != 0 || top.destination_aw_count_debug != 8 ||
        top.destination_w_count_debug != 8 || top.source_b_count_debug != 8) {
        std::cerr << "WRITE_ORDER_FAIL done=" << unsigned(top.done)
                  << " failed=" << unsigned(top.failed)
                  << " AW=" << top.aw_count << " W=" << top.w_count
                  << " B=" << top.b_count
                  << " current=" << top.outstanding_current
                  << " max=" << top.outstanding_max
                  << " mask=0x" << std::hex << top.write_id_mask << std::dec
                  << " protocol_errors=" << top.protocol_errors << '\n';
        return 1;
    }
    std::cout << "WRITE_ORDER_PASS AW=8 W=8 B=8 max_outstanding=8 "
                 "physical_ids=24..31 b_order=31,29,30,24,26,25,27,28 "
                 "upstream_order=restored error_id=26\n";
    return 0;
}
