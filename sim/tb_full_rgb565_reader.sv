`timescale 1ns/1ps

module tb_full_rgb565_reader;
    reg clk = 0;
    reg resetn = 0;
    always #2 clk = ~clk;
    axi4_if #(.DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    axis_video_if #(.DATA_WIDTH(48)) axis();
    wire buffer_acquire, buffer_done, axi_error, fifo_underflow;
    wire [31:0] debug_status, debug_active_base;
    reg grant = 0;
    reg read_active = 0;
    reg [31:0] read_addr = 0;
    reg [7:0] read_len = 0;
    reg [7:0] read_beat = 0;
    integer cycles = 0;
    integer outputs = 0;
    integer row_start_cycle = 0;
    integer x, y, sx, sy;
    reg [47:0] expected_pair;

    function automatic [15:0] stored_pixel(input integer px,
                                            input integer py);
        stored_pixel = px >= 360 ? 0 : {5'(px), 6'(py), 5'(px ^ py)};
    endfunction
    function automatic [23:0] expand(input [15:0] p);
        expand = {p[15:11],p[15:13],p[10:5],p[10:9],p[4:0],p[4:2]};
    endfunction
    function automatic [255:0] memory_word(input [31:0] addr);
        integer offset, px, py, lane;
        reg [255:0] result;
        begin
            offset = addr - 32'h1000_0000;
            py = offset / 736;
            px = (offset % 736) / 2;
            result = 0;
            for (lane=0;lane<16;lane=lane+1)
                result[lane*16 +:16] = stored_pixel(px+lane,py);
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
    assign axi.arready = !read_active && cycles % 7 != 2;
    assign axi.rid = 0;
    assign axi.rdata = memory_word(read_addr + {19'd0, read_beat, 5'd0});
    assign axi.rresp = 0;
    assign axi.rlast = read_beat == read_len;
    assign axi.rvalid = read_active && cycles % 5 != 1;
    assign axis.tready = cycles % 13 != 3;

    full_rgb565_reader dut(
        .clk(clk), .resetn(resetn), .buffer_acquire(buffer_acquire),
        .buffer_grant(grant), .buffer_base(32'h1000_0000),
        .buffer_done(buffer_done), .m_axi(axi), .m_axis(axis),
        .axi_error(axi_error), .fifo_underflow(fifo_underflow),
        .debug_active_base(debug_active_base), .debug_status(debug_status)
    );

    initial begin
        repeat (5) @(negedge clk);
        resetn = 1;
        wait(buffer_acquire);
        @(negedge clk); grant = 1;
        @(negedge clk); grant = 0;
    end

    always @(posedge clk) if (resetn) begin
        cycles <= cycles + 1;
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
            x = outputs % 960;
            y = outputs / 960;
            if (x == 0)
                row_start_cycle = cycles;
            if (x == 959 && cycles - row_start_cycle > 1200)
                $fatal(1,"full-screen output rate too low: row=%0d cycles=%0d",
                       y, cycles - row_start_cycle);
            sx = ((x*3)/16)*2;
            sy = y/4;
            expected_pair = {expand(stored_pixel(sx+1,sy)),
                             expand(stored_pixel(sx,sy))};
            if (axis.tdata !== expected_pair ||
                axis.tuser !== (outputs == 0) ||
                axis.tlast !== (x == 959))
                $fatal(1,"bad output=%0d got=%012x expected=%012x",
                       outputs,axis.tdata,expected_pair);
            outputs <= outputs + 1;
        end
        if (buffer_done) begin
            if (outputs != 960*1080 || axi_error || fifo_underflow ||
                debug_active_base != 32'h1000_0000)
                $fatal(1,"bad completion count=%0d error=%0b",outputs,axi_error);
            $display("TB_FULL_RGB565_READER=PASS outputs=%0d",outputs);
            $finish;
        end
        if (cycles > 5000000)
            $fatal(1,"timeout outputs=%0d debug=%08x",outputs,debug_status);
    end
endmodule
