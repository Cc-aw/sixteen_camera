`timescale 1ns/1ps
module tb_yolov5nu_bbox_pipeline;
    reg clk=0;always #5 clk=~clk;
    reg resetn=0;
    integer sent=0,received=0,tick=0;
    wire in_valid=sent<6300 && tick%11!=0;
    wire out_ready=tick%7>1;
    wire in_ready,out_valid;
    wire [12:0] position=13'(sent);
    wire [1:0] head=sent<4800?0:sent<6000?1:2;
    wire [12:0] local_pos=sent<4800?13'(sent):sent<6000?13'(sent-4800):13'(sent-6000);
    wire [6:0] grid_x=7'(local_pos%(head==0?80:head==1?40:20));
    wire [5:0] grid_y=6'(local_pos/(head==0?80:head==1?40:20));
    wire [6:0] class_id=7'(sent%80);
    wire [7:0] score_i8=8'(sent);
    wire [31:0] distances={8'(sent*13),8'(sent*7),8'(sent*3),8'(sent)};
    wire [127:0] candidate,reference_word;
    wire [7:0] raw_score;
    reg [127:0] expected[0:6299];
    reg [7:0] expected_raw[0:6299];
    reg stalled=0;
    reg [127:0] held;
    yolov5nu_bbox_pipeline dut(.*);
    yolov5nu_bbox_decoder reference_decoder(
        .position(position),.class_id(class_id),.score_i8(score_i8),
        .distance_left(distances[7:0]),.distance_top(distances[15:8]),
        .distance_right(distances[23:16]),.distance_bottom(distances[31:24]),
        .candidate(reference_word)
    );
    always @(posedge clk) if(resetn) begin
        tick<=tick+1;
        if(in_valid && in_ready) begin
            expected[sent]=reference_word;expected_raw[sent]=score_i8;sent<=sent+1;
        end
        if(stalled && (!out_valid || candidate!==held)) $fatal(1,"bbox backpressure instability");
        stalled<=out_valid&&!out_ready;held<=candidate;
        if(out_valid && out_ready) begin
            if(candidate!==expected[received] || raw_score!==expected_raw[received])
                $fatal(1,"bbox mismatch position=%0d got=%h expected=%h",received,candidate,expected[received]);
            received<=received+1;
        end
    end
    initial begin
        repeat(3) @(negedge clk);resetn=1;
        wait(received==6300);$display("BBOX_PIPELINE=PASS positions=6300 signed_distances=256 scores=256");$finish;
    end
    initial begin repeat(20000) @(posedge clk);$fatal(1,"bbox timeout");end
endmodule
