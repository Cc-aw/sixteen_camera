`timescale 1ns/1ps
module tb_tensor_ingress_l2;
    reg clk = 0, video_clk = 0;
    always #5 clk = ~clk;
    always #3.333 video_clk = ~video_clk;
    reg reset = 1;
    axi4_if #(.ADDR_WIDTH(32),.DATA_WIDTH(256),.ID_WIDTH(3)) video_axi();
    assign video_axi.aclk = video_clk;
    assign video_axi.aresetn = !reset;
    reg test_a_valid = 0, test_d_ready = 0;
    wire test_a_ready, test_d_valid;
    reg [2:0] test_a_opcode = 4, test_a_param = 0;
    reg [8:0] test_a_source = 9'h140;
    reg [32:0] test_a_address = 0;
    wire [2:0] test_d_opcode;
    wire [4:0] test_d_sink;
    wire [255:0] test_d_data;
    wire probe_valid;
    wire [32:0] probe_address;
    reg probe_ready = 1, c_valid = 0, e_valid = 0;
    wire c_ready;
    reg [2:0] c_opcode = 5, c_param = 1;
    reg [32:0] c_address = 0;
    reg [255:0] c_data = 0;
    reg [4:0] e_sink = 0;
    reg partial_mode = 0;
    wire mem_a_valid, mem_d_ready;
    wire [2:0] mem_a_opcode;
    wire [5:0] mem_a_source;
    wire [32:0] mem_a_address;
    wire [255:0] mem_a_data;
    wire mem_a_ready;
    reg mem_d_valid = 0;
    reg [2:0] mem_d_opcode = 0;
    reg [5:0] mem_d_source = 0;
    reg [255:0] mem_d_data = 0;
    reg csr_a_valid = 0, csr_d_ready = 0;
    wire csr_a_ready, csr_d_valid;
    reg [2:0] csr_a_opcode = 4;
    reg [25:0] csr_a_address = 0;
    reg [63:0] csr_a_data = 0;
    reg [1:0] csr_a_size = 3;
    wire [63:0] csr_d_data;
    tensor_ingress_l2_wrapper dut(.*);

    reg [255:0] memory [longint unsigned];
    int read_count = 0, write_count = 0, b_count = 0, probes = 0;
    int write_beat = 0;
    bit read_second = 0;
    longint unsigned read_address = 0;
    bit dirty_cpu = 0, probe_responding = 0, probe_second = 0;
    function automatic [255:0] data_word(input int seed, input int beat);
        return {8{32'(seed + beat)}};
    endfunction
    assign mem_a_ready = !mem_d_valid;

    always @(posedge clk) begin
        if (!reset) begin
            if ($test$plusargs("trace")) begin
                if (dut.writer_a_valid && dut.writer_a_ready)
                    $display("TRACE %t writer A src=%h addr=%h", $time, dut.writer_a_source, dut.writer_a_address);
                if (dut.l2_d_valid && dut.l2_d_ready)
                    $display("TRACE %t L2 D src=%h op=%d", $time, dut.l2_d_source, dut.l2_d_opcode);
                if (test_a_valid && test_a_ready)
                    $display("TRACE %t test A src=%h op=%d", $time, test_a_source, test_a_opcode);
                if (mem_a_valid && mem_a_ready)
                    $display("TRACE %t memory A op=%d", $time, mem_a_opcode);
            end
            if (mem_a_valid && mem_a_ready) begin
                longint unsigned address;
                address = longint'(mem_a_address);
                if (mem_a_opcode == 4) begin
                    read_count <= read_count + 1;
                    mem_d_valid <= 1;
                    mem_d_opcode <= 1;
                    mem_d_source <= mem_a_source;
                    mem_d_data <= memory.exists(address) ? memory[address] : 0;
                    read_address <= address + 32;
                    read_second <= 1;
                end else if (mem_a_opcode == 0) begin
                    memory[address + longint'(write_beat * 32)] = mem_a_data;
                    write_beat <= 1 - write_beat;
                    if (write_beat == 1) begin
                        write_count <= write_count + 1;
                        mem_d_valid <= 1;
                        mem_d_opcode <= 0;
                        mem_d_source <= mem_a_source;
                    end
                end else $fatal(1, "Unexpected downstream opcode %0d", mem_a_opcode);
            end
            if (mem_d_valid && mem_d_ready) begin
                if (read_second) begin
                    mem_d_data <= memory.exists(read_address) ? memory[read_address] : 0;
                    read_second <= 0;
                end else mem_d_valid <= 0;
            end
            if (probe_valid && probe_ready) begin
                if (!dirty_cpu || probe_address != 33'hb0000000)
                    $fatal(1, "Unexpected coherent probe");
                probes <= probes + 1;
                c_address <= probe_address;
                c_data <= data_word('hdead0000, 0);
                c_valid <= 1;
                probe_responding <= 1;
                probe_second <= 0;
            end
            if (c_valid && c_ready) begin
                if (!probe_second) begin
                    c_data <= data_word('hdead0000, 1);
                    probe_second <= 1;
                end else begin
                    c_valid <= 0;
                    probe_responding <= 0;
                    dirty_cpu <= 0;
                end
            end
        end
    end
    always @(posedge video_clk)
        if (!reset && video_axi.bvalid && video_axi.bready) begin
            if (video_axi.bresp != 0 || video_axi.bid != 0) $fatal(1, "Tensor B failure");
            b_count <= b_count + 1;
        end

    task automatic tensor_write(input int line_index, input int seed);
        @(negedge video_clk);
        video_axi.awaddr = 32'h30000000 + 32'(line_index * 64);
        video_axi.awvalid = 1;
        do @(posedge video_clk); while (!video_axi.awready);
        @(negedge video_clk); video_axi.awvalid = 0;
        for (int b = 0; b < 2; b++) begin
            video_axi.wdata = data_word(seed, b);
            video_axi.wlast = b == 1;
            video_axi.wvalid = 1;
            do @(posedge video_clk); while (!video_axi.wready);
            @(negedge video_clk);
        end
        video_axi.wvalid = 0;
    endtask
    task automatic wait_b(input int expected);
        while (b_count < expected) @(negedge video_clk);
    endtask
    task automatic read_line(input int index, input int seed, input bit acquire = 0);
        @(negedge clk);
        test_a_opcode = acquire ? 6 : 4;
        test_a_param = acquire ? 1 : 0; // NtoT
        test_a_source = acquire ? 9'h120 : 9'h140;
        test_a_address = 33'hb0000000 + 33'(index * 64);
        test_a_valid = 1;
        do @(posedge clk); while (!test_a_ready);
        @(negedge clk); test_a_valid = 0; test_d_ready = 1;
        for (int b = 0; b < 2; b++) begin
            do @(posedge clk); while (!test_d_valid);
            if (test_d_opcode != (acquire ? 5 : 1) || test_d_data !== data_word(seed, b))
                $fatal(1, "L2 readback mismatch index=%0d beat=%0d opcode=%0d", index, b, test_d_opcode);
            e_sink = test_d_sink;
            @(negedge clk);
        end
        test_d_ready = 0;
        if (acquire) begin
            e_valid = 1;
            @(negedge clk); e_valid = 0;
            dirty_cpu = 1;
        end
    endtask
    task automatic csr_access(input bit write, input int offset, input longint unsigned value,
                              output longint unsigned result);
        bit immediate_response;
        @(negedge clk);
        csr_a_valid = 1; csr_a_opcode = write ? 0 : 4;
        csr_a_address = 26'h2012000 + 26'(offset);
        csr_a_data = value;
        csr_a_size = 3;
        // TLRegisterNode can return D in the same cycle as A (concurrency=0).
        csr_d_ready = 1;
        do @(posedge clk); while (!csr_a_ready);
        immediate_response = csr_d_valid;
        if (immediate_response) result = csr_d_data;
        @(negedge clk); csr_a_valid = 0;
        if (!immediate_response) begin
            do @(posedge clk); while (!csr_d_valid);
            result = csr_d_data;
            @(negedge clk);
        end
        csr_d_ready = 0;
    endtask

    initial begin
        longint unsigned value, completed_bytes;
        video_axi.awvalid = 0; video_axi.wvalid = 0; video_axi.bready = 1;
        video_axi.awid = 0; video_axi.awaddr = 0; video_axi.awlen = 1;
        video_axi.awsize = 5; video_axi.awburst = 1; video_axi.awlock = 0;
        video_axi.awcache = 15; video_axi.awprot = 0; video_axi.awqos = 0;
        video_axi.wdata = 0; video_axi.wstrb = '1; video_axi.wlast = 0;
        repeat (10) @(negedge clk); reset = 0;
        // The real 1024-set directory wipes after reset.
        repeat (1100) @(negedge clk);
        tensor_write(0, 'h12340000); wait_b(1);
        $display("L2 cold-line full write completed");
        if (read_count != 0) $fatal(1, "Cold full-line write fetched old DDR contents");
        read_line(0, 'h12340000);
        $display("L2 cold-line readback completed");
        tensor_write(0, 'h23450000); wait_b(2);
        read_line(0, 'h23450000);
        read_line(0, 'h23450000, 1);
        tensor_write(0, 'h34560000); wait_b(3);
        read_line(0, 'h34560000);
        if (probes != 1 || dirty_cpu) $fatal(1, "Dirty CPU line was not coherently invalidated");
        // Nine lines mapping to the same set exceed the real L2's eight ways.
        for (int n = 1; n <= 9; n++) begin
            tensor_write(n * 1024, 'h45670000 + n * 2);
            wait_b(3 + n);
        end
        repeat (100) @(negedge clk);
        if (write_count == 0) $fatal(1, "Dirty L2 eviction not exercised");
        read_line(0, 'h34560000); // May refill from DDR after replacement.
        partial_mode = 1;
        begin
            int before_reads;
            before_reads = read_count;
            tensor_write(500, 'h56780000); wait_b(13);
            if (read_count != before_reads + 1)
                $fatal(1, "Control PutPartialData did not fetch its missing old line");
        end
        partial_mode = 0;
        read_line(500, 'h56780000);
        csr_access(0, 'h08, 0, value);
        if (value != 64'h54454e5300000001) $fatal(1, "CSR version mismatch");
        csr_access(1, 'h00, 1, value);
        csr_access(0, 'h30, 0, completed_bytes);
        if (completed_bytes != 13 * 64) $fatal(1, "Completed-byte snapshot mismatch");
        tensor_write(501, 'h67890000); wait_b(14);
        csr_access(0, 'h30, 0, value);
        if (value != completed_bytes) $fatal(1, "Snapshot changed without a new command");
        csr_access(1, 'h00, 1, value);
        csr_access(0, 'h30, 0, value);
        if (value != 14 * 64) $fatal(1, "Snapshot did not refresh");
        // Exercise simultaneous same-ID transactions against the real L2,
        // crossing both record-ring wraps without waiting for B per burst.
        for (int n = 600; n < 728; n++) tensor_write(n, 'h789a0000 + n * 2);
        wait_b(142);
        for (int n = 600; n < 728; n += 8) read_line(n, 'h789a0000 + n * 2);
        csr_access(1, 'h00, 1, value);
        csr_access(0, 'h70, 0, value);
        if (value <= 1) $fatal(1, "Real-L2 outstanding window was not exercised");
        $display("TENSOR_INGRESS_L2=PASS cold_full_no_get resident_overwrite dirty_cpu_probe eviction_writeback partial_control cdc csr_snapshot concurrent_same_id");
        $finish;
    end
    initial begin #2000000; $fatal(1, "Tensor ingress L2 timeout"); end
endmodule
