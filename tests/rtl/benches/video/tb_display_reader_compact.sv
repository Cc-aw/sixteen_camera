`timescale 1ns/1ps

module tb_display_reader_compact;
    reg clk = 0;
    reg resetn = 0;
    always #2 clk = ~clk;
    axi4_if #(.DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    axis_video_if #(.DATA_WIDTH(48)) axis();
    reg grant = 0;
    reg mode = 0;
    reg [511:0] bases = 0;
    wire acquire, done, axi_error, underflow;
    wire [31:0] debug_base, debug_status;
    reg read_active = 0;
    reg [31:0] read_addr = 0;
    reg [7:0] read_len = 0;
    reg [7:0] read_beat = 0;
    integer cycles = 0;
    integer frame_number = 0;
    integer output_count = 0;
    integer ch, x, y, tile, tile_x, sx, sy;
    reg [47:0] expected_pair;

    function automatic [15:0] pixel(input integer channel,
                                     input integer px, input integer py);
        pixel = px >= 360 ? 0 : {5'(channel), 6'(py), 5'(px)};
    endfunction
    function automatic [23:0] expand(input [15:0] p);
        expand = {p[15:11],p[15:13],p[10:5],p[10:9],p[4:0],p[4:2]};
    endfunction
    function automatic [255:0] memory_word(input [31:0] addr);
        integer channel, offset, px, py, lane;
        reg [255:0] result;
        begin
            channel = (addr - 32'h1000_0000) >> 20;
            offset = addr - (32'h1000_0000 + channel*32'h0010_0000);
            py = offset / 736;
            px = (offset % 736)/2;
            result = 0;
            for (lane=0;lane<16;lane=lane+1)
                result[lane*16 +:16] = pixel(channel,px+lane,py);
            memory_word = result;
        end
    endfunction

    assign axi.aclk = clk;
    assign axi.aresetn = resetn;
    assign axi.awready = 0;
    assign axi.wready = 0;
    assign axi.bid = 0;
    assign axi.bresp = 0;
    assign axi.bvalid = 0;
    assign axi.arready = !read_active && cycles%7 != 2;
    assign axi.rid = 0;
    assign axi.rdata = memory_word(read_addr + {19'd0,read_beat,5'd0});
    assign axi.rresp = 0;
    assign axi.rlast = read_beat == read_len;
    assign axi.rvalid = read_active && cycles%5 != 1;
    assign axis.tready = cycles%13 != 3;

    display_reader_subsystem dut (
        .clk(clk), .resetn(resetn), .buffer_acquire(acquire),
        .buffer_grant(grant), .buffer_base(32'h1050_0000),
        .buffer_bases(bases), .buffer_valid_mask(16'hff7f),
        .buffer_mode(mode), .buffer_done(done),
        .frame_width(32'd368), .frame_height(32'd270),
        .frame_stride_bytes(32'd736),
        .overlay_commit(1'b0), .overlay_stream(4'd0),
        .overlay_count(4'd0), .overlay_boxes(512'd0),
        .overlay_labels(1024'd0), .m_axi(axi), .m_axis(axis),
        .axi_error(axi_error), .fifo_underflow(underflow),
        .debug_active_base(debug_base), .debug_status(debug_status)
    );

    initial begin
        for (integer i=0;i<16;i=i+1)
            bases[i*32 +:32] = 32'h1000_0000 + i*32'h0010_0000;
        repeat (5) @(negedge clk);
        resetn = 1;
        wait(acquire);
        @(negedge clk); grant = 1;
        @(negedge clk); grant = 0;
    end

    always @(posedge clk) if (resetn) begin
        cycles <= cycles + 1;
        if (axi.arvalid && axi.arready) begin
            if (axi.araddr[4:0] != 0 ||
                (axi.araddr[11:0] + (axi.arlen+1)*32) > 4096)
                $fatal(1,"bad AR %08x/%0d",axi.araddr,axi.arlen);
            read_active <= 1;
            read_addr <= axi.araddr;
            read_len <= axi.arlen;
            read_beat <= 0;
        end
        if (axi.rvalid && axi.rready) begin
            if (axi.rlast) begin
                read_active <= 0;
                read_beat <= 0;
            end else
                read_beat <= read_beat + 1'b1;
        end
        if (axis.tvalid && axis.tready) begin
            x = output_count%960;
            y = output_count/960;
            if (frame_number == 0) begin
                tile = x/240;
                tile_x = x%240;
                ch = (y/270)*4+tile;
                sx = (tile_x-30)*2;
                sy = y%270;
                expected_pair = tile_x<30 || tile_x>=210 || ch==7 ?
                    48'd0 : {expand(pixel(ch,sx+1,sy)),
                             expand(pixel(ch,sx,sy))};
            end else begin
                ch = 5;
                sx = ((x*3)/16)*2;
                sy = y/4;
                expected_pair = {expand(pixel(ch,sx+1,sy)),
                                 expand(pixel(ch,sx,sy))};
            end
            if (axis.tdata !== expected_pair ||
                axis.tuser !== (output_count == 0) ||
                axis.tlast !== (x == 959))
                $fatal(1,"bad mode=%0d output=%0d got=%012x want=%012x",
                       frame_number,output_count,axis.tdata,expected_pair);
            output_count <= output_count + 1;
        end
        if (done) begin
            if (output_count != 960*1080 || axi_error || underflow)
                $fatal(1,"bad done frame=%0d count=%0d error=%0b",
                       frame_number,output_count,axi_error);
            if (frame_number == 1) begin
                $display("TB_DISPLAY_READER_COMPACT=PASS modes=2");
                $finish;
            end
            frame_number <= 1;
            output_count <= 0;
        end
        if (cycles > 11000000)
            $fatal(1,"timeout frame=%0d output=%0d debug=%08x",
                   frame_number,output_count,debug_status);
    end

    always @(negedge clk) if (resetn && frame_number == 1 &&
                             output_count == 0 && acquire && !grant) begin
        mode = 1;
        grant = 1;
    end else if (grant && frame_number == 1) begin
        grant = 0;
    end
endmodule
