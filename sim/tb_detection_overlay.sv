`timescale 1ns/1ps

module tb_detection_overlay;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg resetn = 1'b0;
    reg enable = 1'b1;
    reg cfg_commit = 1'b0;
    reg [3:0] cfg_stream = 4'd0;
    reg [3:0] cfg_count = 4'd0;
    reg [511:0] cfg_boxes = 512'd0;
    reg [1023:0] cfg_labels = 1024'd0;
    reg [47:0] s_tdata = 48'd0;
    reg s_tvalid = 1'b0;
    wire s_tready;
    reg s_tuser = 1'b0;
    reg s_tlast = 1'b0;
    wire [47:0] m_tdata;
    wire m_tvalid;
    reg m_tready = 1'b1;
    wire m_tuser;
    wire m_tlast;

    detection_overlay dut (
        .clk(clk), .resetn(resetn), .enable(enable),
        .cfg_commit(cfg_commit), .cfg_stream(cfg_stream),
        .cfg_count(cfg_count), .cfg_boxes(cfg_boxes),
        .cfg_labels(cfg_labels),
        .s_tdata(s_tdata), .s_tvalid(s_tvalid), .s_tready(s_tready),
        .s_tuser(s_tuser), .s_tlast(s_tlast),
        .m_tdata(m_tdata), .m_tvalid(m_tvalid), .m_tready(m_tready),
        .m_tuser(m_tuser), .m_tlast(m_tlast)
    );

    task automatic send_beat;
        input [47:0] data;
        input user_value;
        input last_value;
        begin
            @(negedge clk);
            s_tdata = data;
            s_tuser = user_value;
            s_tlast = last_value;
            s_tvalid = 1'b1;
            @(posedge clk);
            while (!s_tready) @(posedge clk);
            @(negedge clk);
            s_tvalid = 1'b0;
            s_tuser = 1'b0;
            s_tlast = 1'b0;
        end
    endtask

    integer y;
    integer wait_cycles;
    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;

        cfg_stream = 0;
        cfg_count = 1;
        cfg_boxes[0 +: 11] = 11'd0;
        cfg_boxes[11 +: 11] = 11'd0;
        cfg_boxes[22 +: 11] = 11'd20;
        cfg_boxes[33 +: 11] = 11'd20;
        cfg_boxes[44 +: 8] = 8'd0;
        cfg_labels[0 +: 8] = "d";
        cfg_labels[8 +: 8] = "o";
        cfg_labels[16 +: 8] = "g";
        @(posedge clk); #1; cfg_commit = 1'b1;
        @(posedge clk); #1; cfg_commit = 1'b0;

        // Advance line state to the last line, where shadow becomes active.
        for (y = 0; y < 1080; y = y + 1)
            send_beat(48'h112233_445566, y == 0, 1'b1);

        if (dut.active_label[0][23:0] !== {8'h67, 8'h6f, 8'h64})
            $fatal(1, "label did not promote atomically with box");
        if (!dut.pixel_hits_label(11'd0, 11'd0, 11'd0, 11'd0,
                                  4'd0, cfg_labels[127:0]))
            $fatal(1, "label background hit missing");
        if (dut.label_x_for(11'd1900, 4'd3) != 11'd1792)
            $fatal(1, "right-edge label escaped channel tile");
        if (!dut.glyph_pixel(dut.font5x7("d"), 3'd2, 4'd1))
            $fatal(1, "font glyph lookup failed");

        // Drain the three-stage pipeline before testing a stalled output.
        repeat (4) @(posedge clk);
        m_tready = 1'b0;
        send_beat(48'h112233_445566, 1'b1, 1'b0);
        wait_cycles = 0;
        while (!m_tvalid && wait_cycles < 8) begin
            @(posedge clk); #1;
            wait_cycles = wait_cycles + 1;
        end
        if (!m_tvalid)
            $fatal(1, "overlay output missing after pipeline latency");
        if (m_tdata != 48'h00ff00_00ff00)
            $fatal(1, "box border not drawn: %012x", m_tdata);

        repeat (3) begin
            @(posedge clk); #1;
            if (!m_tvalid || m_tdata !== 48'h00ff00_00ff00)
                $fatal(1, "overlay did not hold output under backpressure");
        end
        m_tready = 1'b1;
        @(posedge clk); #1;
        $display("TB_DETECTION_OVERLAY=PASS");
        $finish;
    end
endmodule
