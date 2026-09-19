`timescale 1ns/1ps

module tb_head_uram_local_reader;
    localparam integer DATA_WIDTH = 256;
    localparam integer BYTE_LANES = DATA_WIDTH / 8;
    localparam integer SLOT_BYTES = 4096;
    localparam integer OFFSET_WIDTH = $clog2(SLOT_BYTES);
    localparam integer WORD_ADDR_WIDTH =
        $clog2(SLOT_BYTES / BYTE_LANES);

    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    reg write_valid = 1'b0;
    wire write_ready;
    reg [OFFSET_WIDTH-1:0] write_addr = '0;
    reg [DATA_WIDTH-1:0] write_data = '0;
    reg [BYTE_LANES-1:0] write_strb = '0;
    reg start = 1'b0;
    reg [32:0] base_addr = '0;
    reg [31:0] byte_count = 0;
    wire busy, done, error;
    wire [2:0] error_flags;
    wire [31:0] bytes_read;
    wire memory_req_valid, memory_req_ready;
    wire [WORD_ADDR_WIDTH-1:0] memory_req_word_addr;
    wire [DATA_WIDTH-1:0] memory_rsp_data;
    wire memory_rsp_valid, memory_rsp_ready;
    wire [DATA_WIDTH-1:0] stream_data;
    wire [BYTE_LANES-1:0] stream_keep;
    wire stream_valid, stream_last;
    reg stream_ready = 1'b0;

    head_uram_store #(.SLOT_BYTES(SLOT_BYTES)) store (
        .clk(clk), .resetn(resetn),
        .write_valid(write_valid), .write_ready(write_ready),
        .write_addr(write_addr), .write_data(write_data),
        .write_strb(write_strb), .read_req_valid(memory_req_valid),
        .read_req_ready(memory_req_ready),
        .read_req_word_addr(memory_req_word_addr),
        .read_rsp_data(memory_rsp_data), .read_rsp_valid(memory_rsp_valid),
        .read_rsp_ready(memory_rsp_ready)
    );

    head_local_reader #(.SLOT_BYTES(SLOT_BYTES)) reader (
        .clk(clk), .resetn(resetn), .start(start), .base_addr(base_addr),
        .byte_count(byte_count), .busy(busy), .done(done), .error(error),
        .error_flags(error_flags), .bytes_read(bytes_read),
        .memory_req_valid(memory_req_valid),
        .memory_req_ready(memory_req_ready),
        .memory_req_word_addr(memory_req_word_addr),
        .memory_rsp_data(memory_rsp_data),
        .memory_rsp_valid(memory_rsp_valid),
        .memory_rsp_ready(memory_rsp_ready), .stream_data(stream_data),
        .stream_keep(stream_keep), .stream_valid(stream_valid),
        .stream_ready(stream_ready), .stream_last(stream_last)
    );

    reg [7:0] expected_memory [0:SLOT_BYTES-1];
    reg [31:0] lfsr = 32'h6d2b_79f5;
    integer received;
    integer expected_offset;
    integer cycles;

    always @(posedge clk)
        lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};

    task automatic write_word(input integer offset,
                              input [BYTE_LANES-1:0] strobes,
                              input integer salt);
        begin
            @(negedge clk);
            write_addr = OFFSET_WIDTH'(offset);
            write_strb = strobes;
            for (integer lane = 0; lane < BYTE_LANES; lane = lane + 1) begin
                write_data[lane*8 +: 8] = 8'((offset + lane) ^ salt);
                if (strobes[lane])
                    expected_memory[(offset / BYTE_LANES) * BYTE_LANES + lane] =
                        8'((offset + lane) ^ salt);
            end
            write_valid = 1'b1;
            @(negedge clk);
            write_valid = 1'b0;
            write_strb = '0;
        end
    endtask

    task automatic run_read(input integer offset, input integer length,
                            input bit random_backpressure);
        begin
            wait (!busy);
            @(negedge clk);
            base_addr = 33'h0_3200_0000 + offset;
            byte_count = length;
            expected_offset = offset;
            received = 0;
            stream_ready = !random_backpressure;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            cycles = 0;
            while (!done) begin
                @(negedge clk);
                if (random_backpressure)
                    stream_ready = lfsr[0] || lfsr[5];
                cycles = cycles + 1;
                if (cycles > 2000)
                    $fatal(1, "local reader timeout offset=%0d length=%0d",
                           offset, length);
            end
            stream_ready = 1'b0;
            if (error || received != length || bytes_read != length)
                $fatal(1,
                    "local read result mismatch error=%0d received=%0d bytes=%0d expected=%0d",
                    error, received, bytes_read, length);
            if (!random_backpressure &&
                cycles > ((offset % BYTE_LANES + length + BYTE_LANES - 1) /
                           BYTE_LANES) + 2)
                $fatal(1, "continuous local reader inserted bubbles cycles=%0d",
                       cycles);
        end
    endtask

    always @(posedge clk) begin
        if (resetn && stream_valid && stream_ready) begin
            for (integer lane = 0; lane < BYTE_LANES; lane = lane + 1) begin
                if (stream_keep[lane]) begin
                    if (stream_data[lane*8 +: 8] !==
                        expected_memory[expected_offset])
                        $fatal(1,
                            "local data mismatch byte=%0d offset=%0d got=%02x expected=%02x",
                            received, expected_offset,
                            stream_data[lane*8 +: 8],
                            expected_memory[expected_offset]);
                    expected_offset = expected_offset + 1;
                    received = received + 1;
                end
            end
            if (stream_last !== (received == byte_count))
                $fatal(1, "stream_last mismatch received=%0d total=%0d",
                       received, byte_count);
        end
    end

    initial begin
        for (integer index = 0; index < SLOT_BYTES; index = index + 1)
            expected_memory[index] = 8'h00;
        repeat (5) @(negedge clk);
        resetn = 1'b1;

        for (integer offset = 0; offset < SLOT_BYTES;
             offset = offset + BYTE_LANES)
            write_word(offset, {BYTE_LANES{1'b1}}, 32'h0000_005a);

        // Verify aligned streaming at one beat per cycle, then unaligned head,
        // unaligned tail and randomized downstream backpressure.
        run_read(64, 256, 1'b0);
        run_read(13, 1, 1'b1);
        run_read(29, 97, 1'b1);
        run_read(2017, 777, 1'b1);
        run_read(SLOT_BYTES - 37, 37, 1'b1);

        // Partial writes must preserve bytes with a cleared WSTRB lane.
        write_word(96, 32'h00ff_0f0f, 32'h0000_00a5);
        run_read(91, 53, 1'b1);

        // A zero-byte command completes without touching the memory port.
        @(negedge clk);
        base_addr = 33'h0_3200_007b;
        byte_count = 0;
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        if (!done || busy || error || bytes_read != 0)
            $fatal(1, "zero-byte command semantics failed");

        // A request may end at the slot boundary, but may not cross it.
        @(negedge clk);
        base_addr = 33'h0_3200_0000 + SLOT_BYTES - 16;
        byte_count = 17;
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        if (!done || busy || !error || error_flags != 3'b001)
            $fatal(1, "out-of-range command was not rejected flags=%b",
                   error_flags);

        $display("HEAD_URAM_LOCAL_READER=PASS slot_bytes=%0d", SLOT_BYTES);
        $finish;
    end

    initial begin
        repeat (20000) @(posedge clk);
        $fatal(1, "head URAM/local reader test timeout");
    end
endmodule
