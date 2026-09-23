`timescale 1ns/1ps

// Tensor payloads enter the SoC through coherent FBus.  Address aliasing and
// completion ordering remain implemented by the proven AXI write bridge.
module tensor_memory_bridge (
    axi4_if.slave  tensor_write_axi,
    input wire     soc_clk,
    input wire     soc_resetn,
    axi4_if.master fbus_write_axi
);
    axi4_write_cdc #(
        // Read and write TL source tags carry an independent direction bit,
        // so tensor writes may use all 32 AXI ID groups without reducing the
        // postprocess reader's ID space.
        .FIFO_ADDR_WIDTH(5), .FBUS_WRITE_ID(0),
        .FBUS_WRITE_ID_COUNT(32)
    ) u_tensor_fbus_write_cdc (
        .s_axi(tensor_write_axi), .m_clk(soc_clk),
        .m_resetn(soc_resetn), .m_axi(fbus_write_axi)
    );
endmodule
