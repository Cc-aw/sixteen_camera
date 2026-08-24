`timescale 1ns/1ps

module tb_batch_preprocess_engine;
    localparam integer CHANNELS = 4;
    localparam integer SRC_WIDTH = 64;
    localparam integer SRC_HEIGHT = 8;
    localparam integer DST_WIDTH = 32;
    localparam integer DST_HEIGHT = 4;
    localparam integer MEMBER_BYTES = DST_WIDTH*DST_HEIGHT*3;
    localparam [31:0] ARENA0_BASE = 32'h0000_8000;
    localparam [31:0] ARENA1_BASE = 32'h0000_9000;

    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    reg start = 1'b0;
    reg recycle = 1'b0;
    reg [1:0] recycle_mask = 2'b00;
    reg snapshot_active = 1'b1;
    reg [CHANNELS-1:0] snapshot_valid_mask = 4'b0101;
    reg [CHANNELS-1:0] snapshot_fresh_mask = 4'b0001;
    reg [CHANNELS*32-1:0] snapshot_addrs;
    reg [63:0] snapshot_batch_id = 64'h1234;
    wire command_done;
    wire command_error;
    wire busy;
    wire [1:0] ready_mask;
    wire active_arena;
    wire [4:0] active_channel;
    wire [4:0] completed_channels;
    wire [31:0] active_tensor_base;
    wire [63:0] arena0_batch_id;
    wire [63:0] arena1_batch_id;
    wire [CHANNELS-1:0] arena0_valid_mask;
    wire [CHANNELS-1:0] arena1_valid_mask;
    wire [CHANNELS-1:0] arena0_fresh_mask;
    wire [CHANNELS-1:0] arena1_fresh_mask;
    wire [31:0] batch_cycles;
    wire [31:0] last_batch_cycles;
    wire [31:0] last_read_beats;
    wire [31:0] last_write_beats;
    wire [31:0] start_count;
    wire [31:0] complete_count;
    wire [31:0] error_count;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();

    batch_preprocess_engine #(
        .CHANNELS(CHANNELS), .SRC_WIDTH(SRC_WIDTH),
        .SRC_HEIGHT(SRC_HEIGHT), .SRC_STRIDE_BYTES(SRC_WIDTH*4),
        .DST_WIDTH(DST_WIDTH), .DST_HEIGHT(DST_HEIGHT),
        .MEMBER_BYTES(MEMBER_BYTES), .ARENA0_BASE(ARENA0_BASE),
        .ARENA1_BASE(ARENA1_BASE)
    ) dut (
        .clk(clk), .resetn(resetn), .start(start),
        .snapshot_active(snapshot_active),
        .snapshot_valid_mask(snapshot_valid_mask),
        .snapshot_fresh_mask(snapshot_fresh_mask),
        .snapshot_addrs(snapshot_addrs),
        .snapshot_batch_id(snapshot_batch_id),
        .recycle(recycle), .recycle_mask(recycle_mask),
        .command_done(command_done), .command_error(command_error),
        .busy(busy), .ready_mask(ready_mask),
        .active_arena(active_arena), .active_channel(active_channel),
        .completed_channels(completed_channels),
        .active_tensor_base(active_tensor_base),
        .arena0_batch_id(arena0_batch_id),
        .arena1_batch_id(arena1_batch_id),
        .arena0_valid_mask(arena0_valid_mask),
        .arena1_valid_mask(arena1_valid_mask),
        .arena0_fresh_mask(arena0_fresh_mask),
        .arena1_fresh_mask(arena1_fresh_mask),
        .batch_cycles(batch_cycles), .last_batch_cycles(last_batch_cycles),
        .last_read_beats(last_read_beats),
        .last_write_beats(last_write_beats), .start_count(start_count),
        .complete_count(complete_count), .error_count(error_count),
        .m_axi(axi)
    );

    reg read_active;
    reg [31:0] read_addr;
    reg [8:0] read_left;
    reg [255:0] rdata;
    reg rvalid;
    reg rlast;
    reg write_active;
    reg [31:0] write_addr;
    reg [8:0] write_left;
    reg bvalid;
    reg [7:0] memory [0:65535];
    integer lane;
    integer index;
    integer channel;
    integer timeout;

    function automatic [255:0] make_source_word(input [31:0] address);
        integer source_channel;
        integer word_lane;
        reg [7:0] value;
        begin
            source_channel = (address >> 12) - 1;
            value = 8'(source_channel * 32 + 8);
            make_source_word = 256'd0;
            for (word_lane = 0; word_lane < 8; word_lane = word_lane + 1)
                make_source_word[word_lane*32 +: 32] =
                    {8'd0, value, value+2, value+4};
        end
    endfunction

    assign axi.arready = !read_active;
    assign axi.rid = 3'd0;
    assign axi.rdata = rdata;
    assign axi.rresp = 2'b00;
    assign axi.rlast = rlast;
    assign axi.rvalid = rvalid;
    assign axi.awready = !write_active && !bvalid;
    assign axi.wready = write_active;
    assign axi.bid = 3'd0;
    assign axi.bresp = 2'b00;
    assign axi.bvalid = bvalid;

    always @(posedge clk) begin
        if (!resetn) begin
            read_active <= 1'b0;
            rvalid <= 1'b0;
            write_active <= 1'b0;
            bvalid <= 1'b0;
        end else begin
            if (axi.arvalid && axi.arready) begin
                read_active <= 1'b1;
                read_addr <= axi.araddr;
                read_left <= {1'b0, axi.arlen} + 1'b1;
            end
            if (read_active && !rvalid) begin
                rdata <= make_source_word(read_addr);
                rvalid <= 1'b1;
                rlast <= read_left == 1;
            end
            if (rvalid && axi.rready) begin
                rvalid <= 1'b0;
                read_addr <= read_addr + 32;
                read_left <= read_left - 1'b1;
                if (read_left == 1)
                    read_active <= 1'b0;
            end
            if (axi.awvalid && axi.awready) begin
                write_active <= 1'b1;
                write_addr <= axi.awaddr;
                write_left <= {1'b0, axi.awlen} + 1'b1;
            end
            if (axi.wvalid && axi.wready) begin
                for (lane = 0; lane < 32; lane = lane + 1)
                    if (axi.wstrb[lane])
                        memory[write_addr+lane] <= axi.wdata[lane*8 +: 8];
                write_addr <= write_addr + 32;
                write_left <= write_left - 1'b1;
                if (write_left == 1) begin
                    write_active <= 1'b0;
                    bvalid <= 1'b1;
                end
            end
            if (bvalid && axi.bready)
                bvalid <= 1'b0;
        end
    end

    task automatic launch_and_wait;
        begin
            @(negedge clk);
            start = 1'b1;
            @(posedge clk); #1;
            start = 1'b0;
            if (!command_done || command_error)
                $fatal(1, "start command rejected");
            timeout = 0;
            while (busy) begin
                @(posedge clk); #1;
                timeout = timeout + 1;
                if (timeout > 100000)
                    $fatal(1, "batch timeout channel=%0d", active_channel);
            end
        end
    endtask

    initial begin
        snapshot_addrs = {32'h0000_4000, 32'h0000_3000,
                          32'h0000_2000, 32'h0000_1000};
        for (index = 0; index < 65536; index = index + 1)
            memory[index] = 8'ha5;
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        repeat (2) @(posedge clk);

        launch_and_wait();
        if (ready_mask != 2'b01 || complete_count != 1 ||
            completed_channels != CHANNELS || arena0_batch_id != 64'h1234 ||
            arena0_valid_mask != 4'b0101 || arena0_fresh_mask != 4'b0001)
            $fatal(1, "arena0 metadata mismatch");
        if (last_read_beats != 2*DST_HEIGHT*(SRC_WIDTH/8) ||
            last_write_beats != CHANNELS*DST_HEIGHT*(DST_WIDTH*3/32))
            $fatal(1, "batch beat totals %0d/%0d", last_read_beats,
                   last_write_beats);
        for (channel = 0; channel < CHANNELS; channel = channel + 1)
            for (index = 0; index < MEMBER_BYTES; index = index + 1)
                if (!snapshot_valid_mask[channel] &&
                    memory[ARENA0_BASE + channel*MEMBER_BYTES + index] != 0)
                    $fatal(1, "invalid member %0d byte %0d not zero",
                           channel, index);

        snapshot_batch_id = 64'h5678;
        launch_and_wait();
        if (ready_mask != 2'b11 || arena1_batch_id != 64'h5678)
            $fatal(1, "arena1 allocation mismatch");

        @(negedge clk);
        start = 1'b1;
        @(posedge clk); #1;
        start = 1'b0;
        if (!command_done || !command_error || error_count != 1)
            $fatal(1, "full pool was not rejected");

        @(negedge clk);
        recycle_mask = 2'b01;
        recycle = 1'b1;
        @(posedge clk); #1;
        recycle = 1'b0;
        if (!command_done || command_error || ready_mask != 2'b10)
            $fatal(1, "recycle failed");

        $display("TB_BATCH_PREPROCESS_ENGINE=PASS cycles=%0d",
                 last_batch_cycles);
        $finish;
    end
endmodule
