`timescale 1ns/1ps

module tb_frame_preprocess_accel;
    localparam integer SRC_WIDTH = 72;
    localparam integer SRC_HEIGHT = 7;
    localparam integer DST_WIDTH = 32;
    localparam integer DST_HEIGHT = 4;
    localparam [31:0] SOURCE_BASE = 32'h0000_1000;
    localparam [31:0] DEST_BASE = 32'h0000_4000;
    localparam [31:0] ZERO_BASE = 32'h0000_5000;

    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    reg start = 1'b0;
    reg source_valid = 1'b1;
    reg [31:0] source_addr = SOURCE_BASE;
    reg [31:0] dest_addr = DEST_BASE;
    wire busy;
    wire done;
    wire error;
    wire [31:0] cycles;
    wire [31:0] read_beats;
    wire [31:0] write_beats;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();

    frame_preprocess_accel #(
        .SRC_WIDTH(SRC_WIDTH), .SRC_HEIGHT(SRC_HEIGHT),
        .SRC_STRIDE_BYTES(SRC_WIDTH*4), .DST_WIDTH(DST_WIDTH),
        .DST_HEIGHT(DST_HEIGHT), .MAX_BURST_BEATS(4)
    ) dut (
        .clk(clk), .resetn(resetn), .start(start),
        .source_valid(source_valid), .source_addr(source_addr),
        .dest_addr(dest_addr), .busy(busy), .done(done), .error(error),
        .cycles(cycles), .read_beats(read_beats),
        .write_beats(write_beats), .m_axi(axi)
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
    reg [7:0] output_mem [0:24575];
    integer index;
    integer lane;
    integer row;
    integer pixel_x;
    integer source_x;
    integer source_y;
    integer byte_addr;
    integer timeout;

    function automatic [255:0] make_source_word(input [31:0] address);
        integer word_row;
        integer first_x;
        integer word_lane;
        reg [7:0] red;
        reg [7:0] green;
        reg [7:0] blue;
        begin
            make_source_word = 256'd0;
            word_row = (address - SOURCE_BASE) / (SRC_WIDTH*4);
            first_x = ((address - SOURCE_BASE) % (SRC_WIDTH*4)) / 4;
            for (word_lane = 0; word_lane < 8; word_lane = word_lane + 1) begin
                red = first_x + word_lane;
                green = word_row;
                blue = first_x + word_lane + word_row;
                make_source_word[word_lane*32 +: 32] =
                    {8'd0, red, blue, green};
            end
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
            read_addr <= 32'd0;
            read_left <= 9'd0;
            rdata <= 256'd0;
            rvalid <= 1'b0;
            rlast <= 1'b0;
            write_active <= 1'b0;
            write_addr <= 32'd0;
            write_left <= 9'd0;
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
                rlast <= 1'b0;
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
                        output_mem[write_addr + lane] <=
                            axi.wdata[lane*8 +: 8];
                write_addr <= write_addr + 32;
                write_left <= write_left - 1'b1;
                if (write_left == 1) begin
                    if (!axi.wlast)
                        $fatal(1, "missing WLAST");
                    write_active <= 1'b0;
                    bvalid <= 1'b1;
                end else if (axi.wlast) begin
                    $fatal(1, "early WLAST");
                end
            end
            if (bvalid && axi.bready)
                bvalid <= 1'b0;
        end
    end

    task automatic run_transaction(input valid_source,
                                   input [31:0] destination);
        begin
            source_valid = valid_source;
            dest_addr = destination;
            start = 1'b1;
            @(posedge clk); #1;
            start = 1'b0;
            timeout = 0;
            while (!done) begin
                @(posedge clk); #1;
                timeout = timeout + 1;
                if (timeout > 20000)
                    $fatal(1, "preprocess timeout state=%0d", dut.state);
            end
            if (error)
                $fatal(1, "preprocess reported error");
        end
    endtask

    initial begin
        for (index = 0; index < 24576; index = index + 1)
            output_mem[index] = 8'ha5;
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        repeat (2) @(posedge clk);

        run_transaction(1'b1, DEST_BASE);
        if (read_beats != DST_HEIGHT * (SRC_WIDTH/8) ||
            write_beats != DST_HEIGHT * (DST_WIDTH*3/32))
            $fatal(1, "beat counts read/write=%0d/%0d", read_beats,
                   write_beats);
        for (row = 0; row < DST_HEIGHT; row = row + 1)
            for (pixel_x = 0; pixel_x < DST_WIDTH; pixel_x = pixel_x + 1) begin
                source_x = (pixel_x * SRC_WIDTH) / DST_WIDTH;
                source_y = (row * SRC_HEIGHT) / DST_HEIGHT;
                byte_addr = DEST_BASE + (row*DST_WIDTH + pixel_x)*3;
                if (output_mem[byte_addr] != (source_x >> 1) ||
                    output_mem[byte_addr+1] != (source_y >> 1) ||
                    output_mem[byte_addr+2] != ((source_x+source_y) >> 1))
                    $fatal(1,
                        "pixel %0d,%0d got=%0d/%0d/%0d expected=%0d/%0d/%0d",
                        pixel_x, row, output_mem[byte_addr],
                        output_mem[byte_addr+1], output_mem[byte_addr+2],
                        source_x>>1, source_y>>1,
                        (source_x+source_y)>>1);
            end

        run_transaction(1'b0, ZERO_BASE);
        if (read_beats != 0 || write_beats != DST_HEIGHT*(DST_WIDTH*3/32))
            $fatal(1, "zero-fill beat counts read/write=%0d/%0d", read_beats,
                   write_beats);
        for (index = 0; index < DST_HEIGHT*DST_WIDTH*3; index = index + 1)
            if (output_mem[ZERO_BASE+index] != 0)
                $fatal(1, "zero-fill byte %0d=%0d", index,
                       output_mem[ZERO_BASE+index]);

        $display("TB_FRAME_PREPROCESS_ACCEL=PASS cycles=%0d", cycles);
        $finish;
    end
endmodule
