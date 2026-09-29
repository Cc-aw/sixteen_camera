`timescale 1ns/1ps

module tb_mosaic_frame_reader_16ch;
    localparam integer AR_QUEUE_DEPTH = 16;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #2 clk = ~clk;

    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    axis_video_if #(.DATA_WIDTH(48)) axis();
    wire buffer_acquire;
    reg buffer_grant = 1'b0;
    reg [511:0] buffer_bases = 512'd0;
    reg [15:0] buffer_valid_mask = 16'hffff;
    wire buffer_done;
    wire axi_error;
    wire fifo_underflow;
    wire [31:0] debug_status;

    reg [31:0] ar_addr_queue [0:AR_QUEUE_DEPTH-1];
    reg [7:0] ar_len_queue [0:AR_QUEUE_DEPTH-1];
    integer ar_wr_ptr = 0;
    integer ar_rd_ptr = 0;
    integer ar_queue_count = 0;
    reg read_active = 1'b0;
    reg [31:0] read_addr = 32'd0;
    reg [7:0] read_len = 8'd0;
    reg [8:0] read_beat = 9'd0;
    integer slave_cycle = 0;
    integer channel;
    integer output_beat;
    integer output_line;
    integer timeout;

    function automatic [255:0] make_read_word(input [31:0] address);
        integer pixel;
        integer channel_number;
        integer pixel_base;
        integer pixel_number;
        reg [255:0] value;
        begin
            channel_number = address[27:24];
            pixel_base = (address - (32'h1000_0000 +
                         channel_number * 32'h0100_0000)) >> 2;
            value = 256'd0;
            for (pixel = 0; pixel < 8; pixel = pixel + 1) begin
                pixel_number = pixel_base + pixel;
                value[pixel*32 +: 24] =
                    {channel_number[7:0], pixel_number[15:0]};
            end
            make_read_word = value;
        end
    endfunction

    mosaic_frame_reader dut (
        .clk(clk), .resetn(resetn),
        .buffer_acquire(buffer_acquire), .buffer_grant(buffer_grant),
        .buffer_bases(buffer_bases),
        .buffer_valid_mask(buffer_valid_mask), .buffer_done(buffer_done),
        .m_axi(axi), .m_axis(axis), .axi_error(axi_error),
        .fifo_underflow(fifo_underflow), .debug_status(debug_status)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            axi.arready <= 1'b1;
            axi.rid <= 3'd0;
            axi.rdata <= 256'd0;
            axi.rresp <= 2'b00;
            axi.rlast <= 1'b0;
            axi.rvalid <= 1'b0;
            axi.awready <= 1'b1;
            axi.wready <= 1'b1;
            axi.bid <= 3'd0;
            axi.bresp <= 2'b00;
            axi.bvalid <= 1'b0;
            ar_wr_ptr <= 0;
            ar_rd_ptr <= 0;
            ar_queue_count <= 0;
            read_active <= 1'b0;
            read_addr <= 32'd0;
            read_len <= 8'd0;
            read_beat <= 9'd0;
            slave_cycle <= 0;
        end else begin
            slave_cycle <= slave_cycle + 1;
            axi.arready <= (ar_queue_count < AR_QUEUE_DEPTH) &&
                           ((slave_cycle % 5) != 1);
            if (axi.arvalid && axi.arready) begin
                if ((axi.araddr[11:0] + ((axi.arlen + 1) << 5)) > 4096)
                    $fatal(1, "read burst crosses 4 KiB");
                ar_addr_queue[ar_wr_ptr] <= axi.araddr;
                ar_len_queue[ar_wr_ptr] <= axi.arlen;
                ar_wr_ptr <= (ar_wr_ptr == AR_QUEUE_DEPTH-1) ? 0 : ar_wr_ptr+1;
            end
            if (!read_active && (ar_queue_count != 0)) begin
                read_active <= 1'b1;
                read_addr <= ar_addr_queue[ar_rd_ptr];
                read_len <= ar_len_queue[ar_rd_ptr];
                read_beat <= 9'd0;
                ar_rd_ptr <= (ar_rd_ptr == AR_QUEUE_DEPTH-1) ? 0 : ar_rd_ptr+1;
            end
            case ({axi.arvalid && axi.arready,
                   !read_active && (ar_queue_count != 0)})
                2'b10: ar_queue_count <= ar_queue_count + 1;
                2'b01: ar_queue_count <= ar_queue_count - 1;
                default: ;
            endcase
            if (read_active && !axi.rvalid && ((slave_cycle % 3) != 0)) begin
                axi.rdata <= make_read_word(read_addr + (read_beat << 5));
                axi.rlast <= (read_beat == read_len);
                axi.rvalid <= 1'b1;
            end
            if (axi.rvalid && axi.rready) begin
                axi.rvalid <= 1'b0;
                axi.rlast <= 1'b0;
                if (axi.rlast) begin
                    read_active <= 1'b0;
                    read_beat <= 9'd0;
                end else begin
                    read_beat <= read_beat + 1'b1;
                end
            end
        end
    end

    task automatic check_pixels(input [23:0] p0, input [23:0] p1);
        begin
            if (axis.tdata !== {p1, p0})
                $fatal(1, "got %012x expected %06x/%06x debug=%08x",
                       axis.tdata, p0, p1, debug_status);
        end
    endtask

    task automatic check_source(input integer source_channel,
                                input integer source_y,
                                input integer source_x);
        integer pixel0;
        integer pixel1;
        begin
            pixel0 = source_y * 640 + source_x;
            pixel1 = pixel0 + 1;
            check_pixels({source_channel[7:0], pixel0[15:0]},
                         {source_channel[7:0], pixel1[15:0]});
        end
    endtask

    initial begin
        axi.aclk = clk;
        axi.aresetn = resetn;
        axis.tready = 1'b1;
        for (channel = 0; channel < 16; channel = channel + 1)
            buffer_bases[channel*32 +: 32] =
                32'h1000_0000 + channel * 32'h0100_0000;
        repeat (5) @(posedge clk);
        resetn = 1'b1;
        wait (buffer_acquire);
        @(negedge clk); buffer_grant = 1'b1;
        @(negedge clk); buffer_grant = 1'b0;

        timeout = 0;
        while (!(axis.tvalid && axis.tready && axis.tuser)) begin
            @(posedge clk);
            timeout = timeout + 1;
            if (timeout > 20000)
                $fatal(1, "timeout waiting for SOF debug=%08x", debug_status);
        end

        output_beat = 0;
        output_line = 0;
        while (!buffer_done) begin
            if (axis.tvalid && axis.tready) begin
                if (output_line == 0 && output_beat == 0 &&
                    axis.tdata !== 48'd0)
                    $fatal(1, "left pillarbox is not black");
                if (output_line == 0 && output_beat == 30)
                    check_source(0, 0, 0);
                if (output_line == 0 && output_beat == 209)
                    check_source(0, 0, 636);
                if (output_line == 0 && output_beat == 210 &&
                    axis.tdata !== 48'd0)
                    $fatal(1, "right pillarbox is not black");
                if (output_line == 0 && output_beat == 270)
                    check_source(1, 0, 0);
                if (output_line == 0 && output_beat == 510)
                    check_source(2, 0, 0);
                if (output_line == 0 && output_beat == 750)
                    check_source(3, 0, 0);
                if (output_line == 3 && output_beat == 30)
                    check_source(0, 5, 0);
                if (output_line == 269 && output_beat == 30)
                    check_source(0, 478, 0);
                if (output_line == 270 && output_beat == 30)
                    check_source(4, 0, 0);
                if (output_line == 540 && output_beat == 30)
                    check_source(8, 0, 0);
                if (output_line == 810 && output_beat == 30)
                    check_source(12, 0, 0);
                if (output_line == 810 && output_beat == 750)
                    check_source(15, 0, 0);
                if (output_line == 1079 && output_beat == 30)
                    check_source(12, 478, 0);

                if (output_beat == 959) begin
                    if (!axis.tlast) $fatal(1, "missing TLAST");
                    output_beat = 0;
                    output_line = output_line + 1;
                end else begin
                    output_beat = output_beat + 1;
                end
            end
            @(posedge clk);
        end
        if (output_line != 1080)
            $fatal(1, "frame ended at line %0d", output_line);
        if (axi_error) $fatal(1, "mosaic reader AXI/scaler error");
        $display("TB_MOSAIC_FRAME_READER_16CH=PASS");
        $finish;
    end
endmodule
