`timescale 1ns/1ps

module tb_fbus_read_engine;
    localparam integer ADDR_WIDTH = 33;
    localparam integer DATA_WIDTH = 256;
    localparam integer BYTE_LANES = DATA_WIDTH / 8;

    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    reg start = 1'b0;
    reg [ADDR_WIDTH-1:0] base_addr = '0;
    reg [31:0] byte_count = 0;
    wire busy;
    wire done;
    wire error;
    wire [31:0] bytes_read;
    wire [31:0] ar_requests;
    wire [31:0] read_beats;
    wire [DATA_WIDTH-1:0] stream_data;
    wire [BYTE_LANES-1:0] stream_keep;
    wire stream_valid;
    reg stream_ready = 1'b0;
    wire stream_last;
    axi4_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
              .ID_WIDTH(4)) axi();

    fbus_read_engine dut (
        .clk(clk), .resetn(resetn), .start(start), .base_addr(base_addr),
        .byte_count(byte_count), .busy(busy), .done(done), .error(error),
        .error_flags(),
        .bytes_read(bytes_read), .ar_requests(ar_requests),
        .read_beats(read_beats), .stream_data(stream_data),
        .stream_keep(stream_keep), .stream_valid(stream_valid),
        .stream_ready(stream_ready), .stream_last(stream_last), .m_axi(axi)
    );

    reg [31:0] lfsr = 32'h91e1_0da5;
    reg read_active = 1'b0;
    reg [ADDR_WIDTH-1:0] response_addr = '0;
    reg [8:0] response_left = 0;
    reg rvalid = 1'b0;
    reg [DATA_WIDTH-1:0] rdata = '0;
    reg rlast = 1'b0;
    reg inject_error = 1'b0;
    integer request_count = 0;
    reg [ADDR_WIDTH-1:0] request_addr [0:15];
    reg [8:0] request_beats [0:15];

    function automatic [DATA_WIDTH-1:0] memory_word(
        input [ADDR_WIDTH-1:0] address);
        integer lane;
        begin
            for (lane = 0; lane < BYTE_LANES; lane = lane + 1)
                memory_word[lane*8 +: 8] = 8'(address + lane);
        end
    endfunction

    assign axi.arready = !read_active && (lfsr[0] || lfsr[5]);
    assign axi.rid = 4'd0;
    assign axi.rdata = rdata;
    assign axi.rresp = inject_error && response_left == 1 ? 2'b10 : 2'b00;
    assign axi.rlast = rlast;
    assign axi.rvalid = rvalid;
    assign axi.awready = 1'b0;
    assign axi.wready = 1'b0;
    assign axi.bid = 4'd0;
    assign axi.bresp = 2'b00;
    assign axi.bvalid = 1'b0;

    always @(posedge clk) begin
        lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        stream_ready <= lfsr[3] || lfsr[11];
        if (!resetn) begin
            read_active <= 1'b0;
            rvalid <= 1'b0;
            request_count <= 0;
        end else begin
            if (axi.arvalid && axi.arready) begin
                if (axi.araddr[4:0] != 0 || axi.arsize != 3'd5 ||
                    axi.arburst != 2'b01)
                    $fatal(1, "illegal AR request");
                if (32'(axi.araddr[11:0]) +
                    (32'(axi.arlen) + 1'b1) * BYTE_LANES > 4096)
                    $fatal(1, "burst crosses 4 KiB boundary");
                request_addr[request_count] <= axi.araddr;
                request_beats[request_count] <= {1'b0, axi.arlen} + 1'b1;
                request_count <= request_count + 1;
                response_addr <= axi.araddr;
                response_left <= {1'b0, axi.arlen} + 1'b1;
                read_active <= 1'b1;
            end
            if (rvalid && axi.rready) begin
                rvalid <= 1'b0;
                if (rlast)
                    read_active <= 1'b0;
                else begin
                    response_addr <= response_addr + BYTE_LANES;
                    response_left <= response_left - 1'b1;
                end
            end
            if (read_active && !rvalid && (lfsr[2] || lfsr[7])) begin
                rdata <= memory_word(response_addr);
                rlast <= response_left == 1;
                rvalid <= 1'b1;
            end
        end
    end

    integer received;
    reg [ADDR_WIDTH-1:0] expected_addr;
    always @(posedge clk) begin
        if (resetn && stream_valid && stream_ready) begin
            for (integer lane = 0; lane < BYTE_LANES; lane = lane + 1) begin
                if (stream_keep[lane]) begin
                    if (stream_data[lane*8 +: 8] !== expected_addr[7:0])
                        $fatal(1, "data mismatch byte=%0d expected=%02x got=%02x",
                               received, expected_addr[7:0],
                               stream_data[lane*8 +: 8]);
                    expected_addr = expected_addr + 1'b1;
                    received = received + 1;
                end
            end
            if (stream_last !== (received == byte_count))
                $fatal(1, "stream_last mismatch received=%0d total=%0d",
                       received, byte_count);
        end
    end

    task automatic run_case(input [ADDR_WIDTH-1:0] address,
                            input [31:0] length,
                            input bit expect_error);
        integer requests_before;
        integer expected_read_beats;
        begin
            wait (!busy);
            @(negedge clk);
            base_addr = address;
            byte_count = length;
            expected_addr = address;
            received = 0;
            inject_error = expect_error;
            requests_before = request_count;
            expected_read_beats = (32'(address[4:0]) + length +
                                  BYTE_LANES - 1) /
                                  BYTE_LANES;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            wait (done);
            if (received != length || bytes_read != length)
                $fatal(1, "byte count mismatch got=%0d counter=%0d expected=%0d",
                       received, bytes_read, length);
            if (error !== expect_error)
                $fatal(1, "error mismatch got=%0b expected=%0b",
                       error, expect_error);
            if (length != 0 && ar_requests != request_count-requests_before)
                $fatal(1, "AR counter mismatch");
            if (read_beats != expected_read_beats)
                $fatal(1, "read beat mismatch got=%0d expected=%0d",
                       read_beats, expected_read_beats);
            @(posedge clk);
        end
    endtask

    initial begin
        repeat (6) @(posedge clk);
        resetn = 1'b1;
        run_case(33'h0_1000_0040, 64, 1'b0);
        run_case(33'h0_1000_001d, 70, 1'b0);
        run_case(33'h0_1000_1ff5, 100, 1'b0);
        if (request_addr[2][11:0] != 12'hfe0 || request_beats[2] != 1 ||
            request_addr[3][11:0] != 12'h000)
            $fatal(1, "4 KiB split mismatch");
        run_case(33'h1_0000_0013, 40, 1'b0);
        run_case(33'h0_2000_0000, 32, 1'b1);
        run_case(33'h0_3000_0000, 0, 1'b0);
        $display("TB_FBUS_READ_ENGINE=PASS requests=%0d", request_count);
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "timeout state busy=%0b requests=%0d", busy, request_count);
    end
endmodule
