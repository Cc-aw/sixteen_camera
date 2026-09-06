`timescale 1ns/1ps

module tb_video_stream_cdc;
    reg s_clk = 0;
    reg m_clk = 0;
    always #10 s_clk = ~s_clk;
    always #5 m_clk = ~m_clk;
    video_stream_if #(.DATA_WIDTH(48), .STREAM_ID_WIDTH(4)) s_stream();
    video_stream_if #(.DATA_WIDTH(48), .STREAM_ID_WIDTH(4)) m_stream();
    reg m_resetn = 0;
    integer sent = 0;
    integer received = 0;
    reg [31:0] lfsr = 32'h9e37_79b9;
    reg stalled = 0;
    reg [87:0] stalled_payload;
    assign s_stream.aclk = s_clk;

    video_stream_cdc #(.FIFO_DEPTH(16)) dut (
        .s_stream(s_stream), .m_clk(m_clk), .m_resetn(m_resetn),
        .m_stream(m_stream)
    );

    always @(posedge m_clk) begin
        lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        m_stream.ready <= lfsr[0] | lfsr[4];
        if (m_stream.valid && !m_stream.ready) begin
            if (stalled && stalled_payload !==
                {m_stream.error, m_stream.frame_id, m_stream.stream_id,
                 m_stream.eof, m_stream.eol, m_stream.sof, m_stream.data})
                $fatal(1, "stream payload changed while stalled");
            stalled <= 1;
            stalled_payload <=
                {m_stream.error, m_stream.frame_id, m_stream.stream_id,
                 m_stream.eof, m_stream.eol, m_stream.sof, m_stream.data};
        end else begin
            stalled <= 0;
        end
        if (m_stream.valid && m_stream.ready) begin
            if (m_stream.data !== {16'h55aa, 32'(received)} ||
                m_stream.frame_id !== 32'(received / 4) ||
                m_stream.stream_id !== 4'd7 ||
                m_stream.sof !== (received % 4 == 0) ||
                m_stream.eol !== (received % 4 == 3) ||
                m_stream.eof !== (received == 19) || m_stream.error)
                $fatal(1, "stream beat %0d mismatch", received);
            received <= received + 1;
        end
    end

    initial begin
        fork
            begin
                #100000;
                $fatal(1, "video_stream_cdc timeout sent=%0d received=%0d",
                       sent, received);
            end
        join_none
        s_stream.aresetn = 0;
        s_stream.valid = 0;
        s_stream.data = 0;
        s_stream.sof = 0;
        s_stream.eol = 0;
        s_stream.eof = 0;
        s_stream.stream_id = 0;
        s_stream.frame_id = 0;
        s_stream.error = 0;
        m_stream.ready = 0;
        repeat (6) @(posedge s_clk);
        m_resetn = 1;
        s_stream.aresetn = 1;
        repeat (8) @(posedge s_clk);
        while (sent < 20) begin
            @(negedge s_clk);
            s_stream.valid = 1;
            s_stream.data = {16'h55aa, 32'(sent)};
            s_stream.frame_id = 32'(sent / 4);
            s_stream.stream_id = 4'd7;
            s_stream.sof = (sent % 4 == 0);
            s_stream.eol = (sent % 4 == 3);
            s_stream.eof = (sent == 19);
            @(posedge s_clk);
            if (s_stream.ready)
                sent = sent + 1;
        end
        @(negedge s_clk);
        s_stream.valid = 0;
        wait (received == 20);
        repeat (3) @(posedge m_clk);
        $display("TB_VIDEO_STREAM_CDC=PASS");
        $finish;
    end
endmodule
