`timescale 1ns/1ps

module tb_frame_preprocess_accel;
    localparam integer SRC_WIDTH = 640;
    localparam integer SRC_HEIGHT = 480;
    localparam integer DST_WIDTH = 416;
    localparam integer DST_HEIGHT = 416;
    localparam integer DST_416_BYTES = DST_WIDTH*DST_HEIGHT*3;
    localparam integer DST_640_BYTES = SRC_WIDTH*SRC_HEIGHT*3;
    localparam [31:0] SOURCE_BASE = 32'h0040_0000;
    localparam [31:0] DEST_416_BASE = 32'h0000_0000;
    localparam [31:0] DEST_640_BASE = 32'h0010_0000;
    localparam [31:0] ZERO_BASE = 32'h0020_0000;
    localparam integer OUTPUT_MEM_BYTES = ZERO_BASE + DST_416_BYTES;

    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    reg start = 1'b0;
    reg source_valid = 1'b1;
    reg [31:0] source_addr = SOURCE_BASE;
    reg [31:0] dest_addr = DEST_416_BASE;
    reg format_640x480 = 1'b0;
    wire busy;
    wire done;
    wire error;
    wire [31:0] cycles;
    wire [31:0] read_beats;
    wire [31:0] write_beats;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) read_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) write_axi();

    frame_preprocess_accel #(
        .SRC_WIDTH(SRC_WIDTH), .SRC_HEIGHT(SRC_HEIGHT),
        .SRC_STRIDE_BYTES(SRC_WIDTH*4), .DST_WIDTH(DST_WIDTH),
        .DST_HEIGHT(DST_HEIGHT), .MAX_BURST_BEATS(4)
    ) dut (
        .clk(clk), .resetn(resetn), .start(start),
        .source_valid(source_valid), .source_addr(source_addr),
        .dest_addr(dest_addr), .format_640x480(format_640x480),
        .busy(busy), .done(done), .error(error),
        .cycles(cycles), .read_beats(read_beats),
        .write_beats(write_beats), .m_read_axi(read_axi),
        .m_write_axi(write_axi)
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
    reg [7:0] output_mem [0:OUTPUT_MEM_BYTES-1];
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

    function automatic [7:0] quantized_component(input integer value);
        reg [7:0] component;
        begin
            component = value[7:0];
            quantized_component = {1'b0, component[7:1]};
        end
    endfunction

    // Reads model the DDR S02 port; writes model the coherent FBus path.
    assign read_axi.arready = !read_active;
    assign read_axi.rid = 3'd0;
    assign read_axi.rdata = rdata;
    assign read_axi.rresp = 2'b00;
    assign read_axi.rlast = rlast;
    assign read_axi.rvalid = rvalid;
    assign read_axi.awready = 1'b0;
    assign read_axi.wready = 1'b0;
    assign read_axi.bid = 3'd0;
    assign read_axi.bresp = 2'b00;
    assign read_axi.bvalid = 1'b0;
    assign write_axi.arready = 1'b0;
    assign write_axi.rid = 3'd0;
    assign write_axi.rdata = 256'd0;
    assign write_axi.rresp = 2'b00;
    assign write_axi.rlast = 1'b0;
    assign write_axi.rvalid = 1'b0;
    assign write_axi.awready = !write_active && !bvalid;
    assign write_axi.wready = write_active;
    assign write_axi.bid = 3'd0;
    assign write_axi.bresp = 2'b00;
    assign write_axi.bvalid = bvalid;

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
            if (read_axi.arvalid && read_axi.arready) begin
                read_active <= 1'b1;
                read_addr <= read_axi.araddr;
                read_left <= {1'b0, read_axi.arlen} + 1'b1;
            end
            if (read_active && !rvalid) begin
                rdata <= make_source_word(read_addr);
                rvalid <= 1'b1;
                rlast <= read_left == 1;
            end
            if (rvalid && read_axi.rready) begin
                rvalid <= 1'b0;
                rlast <= 1'b0;
                read_addr <= read_addr + 32;
                read_left <= read_left - 1'b1;
                if (read_left == 1)
                    read_active <= 1'b0;
            end

            if (write_axi.awvalid && write_axi.awready) begin
                write_active <= 1'b1;
                write_addr <= write_axi.awaddr;
                write_left <= {1'b0, write_axi.awlen} + 1'b1;
            end
            if (write_axi.wvalid && write_axi.wready) begin
                for (lane = 0; lane < 32; lane = lane + 1)
                    if (write_axi.wstrb[lane])
                        output_mem[write_addr + lane] <=
                            write_axi.wdata[lane*8 +: 8];
                write_addr <= write_addr + 32;
                write_left <= write_left - 1'b1;
                if (write_left == 1) begin
                    if (!write_axi.wlast)
                        $fatal(1, "missing WLAST");
                    write_active <= 1'b0;
                    bvalid <= 1'b1;
                end else if (write_axi.wlast) begin
                    $fatal(1, "early WLAST");
                end
            end
            if (bvalid && write_axi.bready)
                bvalid <= 1'b0;
        end
    end

    task automatic run_transaction(input format_640,
                                   input valid_source,
                                   input [31:0] destination);
        begin
            format_640x480 = format_640;
            source_valid = valid_source;
            dest_addr = destination;
            start = 1'b1;
            @(posedge clk); #1;
            start = 1'b0;
            timeout = 0;
            while (!done) begin
                @(posedge clk); #1;
                timeout = timeout + 1;
                if (timeout > 2000000)
                    $fatal(1, "preprocess timeout state=%0d", dut.state);
            end
            if (error)
                $fatal(1, "preprocess reported error");
        end
    endtask

    task automatic check_pixels(input integer width,
                                input integer height,
                                input [31:0] base);
        begin
            for (row = 0; row < height; row = row + 1)
                for (pixel_x = 0; pixel_x < width; pixel_x = pixel_x + 1) begin
                    source_x = (pixel_x * SRC_WIDTH) / width;
                    source_y = (row * SRC_HEIGHT) / height;
                    byte_addr = base + (row*width + pixel_x)*3;
                    if (output_mem[byte_addr] != quantized_component(source_x) ||
                        output_mem[byte_addr+1] != quantized_component(source_y) ||
                        output_mem[byte_addr+2] !=
                            quantized_component(source_x+source_y))
                        $fatal(1,
                            "mode %0dx%0d pixel %0d,%0d got=%0d/%0d/%0d expected=%0d/%0d/%0d",
                            width, height, pixel_x, row,
                            output_mem[byte_addr], output_mem[byte_addr+1],
                            output_mem[byte_addr+2],
                            quantized_component(source_x),
                            quantized_component(source_y),
                            quantized_component(source_x+source_y));
                end
        end
    endtask

    initial begin
        for (index = 0; index < OUTPUT_MEM_BYTES; index = index + 1)
            output_mem[index] = 8'ha5;
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        repeat (2) @(posedge clk);

        run_transaction(1'b0, 1'b1, DEST_416_BASE);
        if (read_beats != DST_HEIGHT * (SRC_WIDTH/8) ||
            write_beats != DST_HEIGHT * (DST_WIDTH*3/32))
            $fatal(1, "416 beat counts read/write=%0d/%0d", read_beats,
                   write_beats);
        check_pixels(DST_WIDTH, DST_HEIGHT, DEST_416_BASE);

        run_transaction(1'b1, 1'b1, DEST_640_BASE);
        if (read_beats != SRC_HEIGHT * (SRC_WIDTH/8) ||
            write_beats != SRC_HEIGHT * (SRC_WIDTH*3/32))
            $fatal(1, "640 beat counts read/write=%0d/%0d", read_beats,
                   write_beats);
        check_pixels(SRC_WIDTH, SRC_HEIGHT, DEST_640_BASE);

        run_transaction(1'b0, 1'b0, ZERO_BASE);
        if (read_beats != 0 || write_beats != DST_HEIGHT*(DST_WIDTH*3/32))
            $fatal(1, "zero-fill beat counts read/write=%0d/%0d", read_beats,
                   write_beats);
        for (index = 0; index < DST_HEIGHT*DST_WIDTH*3; index = index + 1)
            if (output_mem[ZERO_BASE+index] != 0)
                $fatal(1, "zero-fill byte %0d=%0d", index,
                       output_mem[ZERO_BASE+index]);

        $display("TB_FRAME_PREPROCESS_ACCEL=PASS modes=416x416,640x480 cycles=%0d",
                 cycles);
        $finish;
    end
endmodule
