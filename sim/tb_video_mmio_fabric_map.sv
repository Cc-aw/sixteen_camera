`timescale 1ns/1ps

module tb_video_mmio_fabric_map;
    video_mmio_fabric dut();

    task automatic check_map(
        input logic [30:0] cpu_address,
        input logic [30:0] internal_address,
        input logic [2:0] expected_target,
        input logic [17:0] expected_offset
    );
        logic [30:0] normalized;
        logic [2:0] target;
        begin
            normalized = dut.normalize_address(cpu_address);
            target = dut.decode_address(normalized);
            if (normalized !== internal_address) begin
                $error("normalize %08h: got %08h expected %08h",
                       cpu_address, normalized, internal_address);
                $fatal(1);
            end
            if (target !== expected_target) begin
                $error("decode %08h: got %0d expected %0d",
                       cpu_address, target, expected_target);
                $fatal(1);
            end
            if (normalized[17:0] !== expected_offset) begin
                $error("offset %08h: got %05h expected %05h",
                       cpu_address, normalized[17:0], expected_offset);
                $fatal(1);
            end
        end
    endtask

    initial begin
        // The RVV bridge restores the CPU-visible 0x40000000 base before
        // reaching this fabric, so canonical addresses decode directly.
        check_map(31'h40000000, 31'h40000000, 3'd0, 18'h00000);
        check_map(31'h40010040, 31'h40010040, 3'd1, 18'h10040);
        check_map(31'h40111000, 31'h40111000, 3'd5, 18'h11000);

        // Former Taihang addresses remain compatibility aliases.
        check_map(31'h10040000, 31'h40000000, 3'd0, 18'h00000);
        check_map(31'h10050000, 31'h40010000, 3'd1, 18'h10000);
        check_map(31'h10060000, 31'h40020000, 3'd2, 18'h20000);
        check_map(31'h10070000, 31'h40030000, 3'd3, 18'h30000);
        check_map(31'h10080000, 31'h40040000, 3'd4, 18'h00000);
        check_map(31'h10090000, 31'h40050000, 3'd4, 18'h10000);
        check_map(31'h10140000, 31'h40100000, 3'd5, 18'h00000);

        // Camera software accesses the control bank at block base + 0x1000.
        check_map(31'h10151000, 31'h40111000, 3'd5, 18'h11000);
        check_map(31'h1016D000, 31'h4012D000, 3'd5, 18'h2D000);

        check_map(31'h1003FFFF, 31'h1003FFFF, 3'd7, 18'h3FFFF);
        check_map(31'h1023FFFF, 31'h401FFFFF, 3'd7, 18'h3FFFF);

        $display("TB_VIDEO_MMIO_FABRIC_MAP=PASS");
        $finish;
    end
endmodule
