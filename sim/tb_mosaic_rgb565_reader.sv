`timescale 1ns/1ps

module tb_mosaic_rgb565_reader #(
    parameter integer STALL_TEST = 0
);
    reg clk = 0;
    reg resetn = 0;
    always #2 clk = ~clk;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    axis_video_if #(.DATA_WIDTH(48)) axis();
    wire buffer_acquire, buffer_done, axi_error, fifo_underflow;
    wire [31:0] debug_status;
    reg buffer_grant = 0;
    reg [511:0] buffer_bases = 0;
    reg [15:0] buffer_valid_mask = 16'hff7f;
    reg read_active = 0;
    reg [31:0] read_addr = 0;
    reg [7:0] read_len = 0;
    reg [7:0] read_beat = 0;
    integer cycles = 0;
    integer underflow_seen = 0;
    reg stall_started = 0;
    integer release_cycle = 0;
    integer output_count = 0;
    integer row_start_cycle = 0;
    integer channel;
    integer output_x, output_y, tile, tile_x, source_x, source_y;
    reg [47:0] expected_pair;

    function automatic [15:0] stored_pixel(input integer ch,
                                            input integer x,
                                            input integer y);
        stored_pixel = (x >= 360) ? 16'd0 :
            {5'(ch), 6'(y), 5'(x)};
    endfunction
    function automatic [23:0] expand(input [15:0] p);
        expand = {p[15:11],p[15:13],p[10:5],p[10:9],p[4:0],p[4:2]};
    endfunction
    function automatic [255:0] memory_word(input [31:0] addr);
        integer ch, offset, x, y, lane;
        reg [255:0] result;
        begin
            ch = (addr - 32'h1000_0000) >> 20;
            offset = addr - (32'h1000_0000 + ch*32'h0010_0000);
            y = offset / 736;
            x = (offset % 736) / 2;
            result = 0;
            for (lane=0; lane<16; lane=lane+1)
                result[lane*16 +:16] = stored_pixel(ch,x+lane,y);
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
    assign axi.arready = !read_active && (cycles % 7 != 2);
    assign axi.rid = 0;
    assign axi.rdata = memory_word(read_addr + {19'd0,read_beat,5'd0});
    assign axi.rresp = 0;
    assign axi.rlast = read_beat == read_len;
    assign axi.rvalid = read_active && (cycles % 5 != 1) &&
        (STALL_TEST == 0 || !stall_started || cycles >= release_cycle);
    assign axis.tready = cycles % 13 != 3;

    mosaic_rgb565_reader dut(
        .clk(clk), .resetn(resetn),
        .buffer_acquire(buffer_acquire), .buffer_grant(buffer_grant),
        .buffer_bases(buffer_bases), .buffer_valid_mask(buffer_valid_mask),
        .buffer_done(buffer_done), .m_axi(axi), .m_axis(axis),
        .axi_error(axi_error), .fifo_underflow(fifo_underflow),
        .debug_status(debug_status)
    );

    initial begin
        for (channel=0;channel<16;channel=channel+1)
            buffer_bases[channel*32 +:32] =
                32'h1000_0000 + channel*32'h0010_0000;
        repeat (5) @(negedge clk);
        resetn = 1;
        wait(buffer_acquire);
        @(negedge clk); buffer_grant = 1;
        @(negedge clk); buffer_grant = 0;
    end

    always @(posedge clk) if (resetn) begin
        cycles <= cycles + 1;
        if (STALL_TEST != 0 && !stall_started && dut.bank_ready[0] &&
            !dut.bank_ready[1] && dut.output_y == 0 && dut.output_x > 0) begin
            stall_started <= 1;
            release_cycle <= cycles + 5000;
        end
        if (fifo_underflow)
            underflow_seen <= underflow_seen + 1;
        if (axi.arvalid && axi.arready) begin
            if (axi.araddr[4:0] != 0 ||
                (axi.araddr[11:0] + (axi.arlen+1)*32) > 4096 ||
                axi.arlen > 22)
                $fatal(1,"bad AR %08x len=%0d",axi.araddr,axi.arlen);
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
            output_x = output_count % 960;
            output_y = output_count / 960;
            if (output_x == 0)
                row_start_cycle = cycles;
            if (output_x == 959 && cycles - row_start_cycle > 1200)
                $fatal(1,"mosaic output rate too low: row=%0d cycles=%0d",
                       output_y, cycles - row_start_cycle);
            tile = output_x / 240;
            tile_x = output_x % 240;
            source_x = (tile_x-30)*2;
            source_y = output_y % 270;
            channel = (output_y/270)*4+tile;
            expected_pair = (tile_x < 30 || tile_x >= 210 || channel == 7) ?
                48'd0 :
                {expand(stored_pixel(channel,source_x+1,source_y)),
                 expand(stored_pixel(channel,source_x,source_y))};
            if (axis.tdata !== expected_pair ||
                axis.tuser !== (output_count == 0) ||
                axis.tlast !== (output_x == 959))
                $fatal(1,"bad output=%0d got=%012x expected=%012x debug=%08x",
                       output_count,axis.tdata,expected_pair,debug_status);
            output_count <= output_count + 1;
        end
        if (buffer_done) begin
            if (output_count != 960*1080 || axi_error ||
                (STALL_TEST != 0 && underflow_seen == 0) ||
                (STALL_TEST == 0 && underflow_seen != 0))
                $fatal(1,"bad completion count=%0d error=%0b underflow=%0b",
                       output_count,axi_error,fifo_underflow);
            $display("TB_MOSAIC_RGB565_READER=PASS outputs=%0d underflows=%0d",
                     output_count,underflow_seen);
            $finish;
        end
        if (cycles > 5000000)
            $fatal(1,"timeout output=%0d debug=%08x",output_count,debug_status);
    end
endmodule
