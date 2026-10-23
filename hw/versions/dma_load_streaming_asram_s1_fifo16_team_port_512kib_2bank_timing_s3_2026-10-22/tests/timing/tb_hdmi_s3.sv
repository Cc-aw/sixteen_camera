`timescale 1ns/1ps
module tb_hdmi_s3;
    reg clk=0;
    always #5 clk=~clk;
    reg resetn=0;
    reg capture_enable=1;
    reg [31:0] lfsr=32'h62a4f103;
    axis_video_if source();
    axis_video_if reference_source();
    video_stream_if #(.STREAM_ID_WIDTH(4)) channels[8]();
    video_stream_if #(.STREAM_ID_WIDTH(4)) reference_channels[8]();
    wire [31:0] frames,malformed,reference_frames,reference_malformed;
    wire [255:0] overflow_counts,channel_frames,reference_overflow,reference_channel_frames;
    assign source.aclk=clk;
    assign source.aresetn=resetn;
    assign reference_source.aclk=clk;
    assign reference_source.aresetn=resetn;
    assign reference_source.tdata=source.tdata;
    assign reference_source.tvalid=source.tvalid;
    assign reference_source.tuser=source.tuser;
    assign reference_source.tlast=source.tlast;
    hdmi_4k_spatial_demux dut(source,channels,capture_enable,frames,malformed,overflow_counts,channel_frames);
    hdmi_4k_spatial_demux_s2 reference_dut(reference_source,reference_channels,capture_enable,
        reference_frames,reference_malformed,reference_overflow,reference_channel_frames);
    reg [31:0] previous_frames=0,previous_malformed=0;
    integer beats=0,events=0;
    always @(posedge clk) begin
        if(resetn && source.tvalid) beats<=beats+1;
        #1;
        if(resetn) begin
            if(frames!==previous_frames || malformed!==previous_malformed)
                $fatal(1,"transport diagnostic count differs from S2 by more than the declared one clock");
            if(overflow_counts!==reference_overflow || channel_frames!==reference_channel_frames)
                $fatal(1,"channel diagnostic changed");
            if(!source.tready || !reference_source.tready) $fatal(1,"HDMI backpressured");
            if(frames!=previous_frames || malformed!=previous_malformed) events<=events+1;
        end else if(frames!==0 || malformed!==0) $fatal(1,"reset did not clear counters");
        previous_frames=reference_frames;previous_malformed=reference_malformed;
    end
    for(genvar ch=0;ch<8;ch++) begin:g_compare
        assign channels[ch].ready=lfsr[ch] || lfsr[ch+8];
        assign reference_channels[ch].ready=channels[ch].ready;
        always @(posedge clk) begin
            #1;
            if(resetn) begin
                if(channels[ch].valid!==reference_channels[ch].valid ||
                   channels[ch].error!==reference_channels[ch].error)
                    $fatal(1,"stream validity/error changed ch=%0d",ch);
                if(channels[ch].valid &&
                   {channels[ch].data,channels[ch].sof,channels[ch].eol,channels[ch].eof,
                    channels[ch].stream_id,channels[ch].frame_id} !==
                   {reference_channels[ch].data,reference_channels[ch].sof,reference_channels[ch].eol,
                    reference_channels[ch].eof,reference_channels[ch].stream_id,reference_channels[ch].frame_id})
                    $fatal(1,"stream data/metadata changed ch=%0d",ch);
            end
        end
    end
    task automatic beat(input bit valid,input bit sof,input bit eol);
        @(negedge clk);
        lfsr={lfsr[30:0],lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
        source.tvalid=valid;source.tuser=sof;source.tlast=eol;
        source.tdata={lfsr,lfsr[15:0]};
    endtask
    initial begin
        source.tvalid=0;source.tuser=0;source.tlast=0;source.tdata=0;
        repeat(5) @(negedge clk);resetn=1;
        // One full 4K transport exercises all eight crop outputs, end-of-frame
        // events and independent channel overflow. Random input bubbles do not
        // change the transport geometry.
        for(integer y=0;y<2160;y++) begin
            for(integer x=0;x<1920;x++) begin
                if(lfsr[5:0]==0) beat(0,0,0);
                beat(1,(x==0 && y==0),(x==1919));
            end
        end
        repeat(8) beat(0,0,0);
        if(frames!=1 || malformed!=0 || overflow_counts==0)
            $fatal(1,"full frame/overflow coverage missing");
        // Early SOF, malformed EOL and capture disable.
        beat(1,1,0);repeat(17) beat(1,0,0);beat(1,1,0);
        repeat(31) beat(1,0,0);beat(1,0,1);
        capture_enable=0;repeat(10)beat(1,0,0);capture_enable=1;
        beat(1,1,0);repeat(18)beat(1,0,0);beat(1,1,0);
        repeat(8)beat(0,0,0);
        if(malformed<2) $fatal(1,"malformed transport coverage missing");
        @(negedge clk);resetn=0;repeat(4)beat(0,0,0);
        resetn=1;repeat(8)beat(0,0,0);
        if(frames!=0 || malformed!=0) $fatal(1,"counter reset recovery failed");
        $display("HDMI_S3_S2_STREAM_EQUIVALENCE_PASS beats=%0d channels=8 counters_delayed=1 full_frame=1 overflow=checked malformed=checked reset=checked",beats);
        $finish;
    end
    initial begin #100000000;$fatal(1,"HDMI test timeout");end
endmodule
