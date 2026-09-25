`timescale 1ns/1ps
// Four globally stalled pipeline stages. Grid metadata comes from sparse scan,
// so no position division or general distance multiplier is in the datapath.
module yolov5nu_bbox_pipeline (
    input wire clk,resetn,
    input wire in_valid,
    output wire in_ready,
    input wire [12:0] position,
    input wire [1:0] head,
    input wire [6:0] grid_x,
    input wire [5:0] grid_y,
    input wire [6:0] class_id,
    input wire [7:0] score_i8,
    input wire [31:0] distances,
    output wire out_valid,
    input wire out_ready,
    output reg [127:0] candidate,
    output reg [7:0] raw_score
);
    reg [3:0] valid;
    wire advance=!valid[3] || out_ready;
    assign in_ready=advance;
    assign out_valid=valid[3];
    reg [1:0] head0;
    reg [31:0] dist0;
    reg [7:0] score0,score1,score2;
    reg [19:0] tag0,tag1,tag2;
    reg signed [47:0] bx0,by0,bx1,by1;
    wire [191:0] offsets;
    wire [15:0] q15;
    reg [15:0] q151,q152;
    reg signed [47:0] left1,top1,right1,bottom1;
    reg signed [47:0] x02,y02,x12,y12;
    yolov5nu_bbox_lut u_lut(.head(head0),.distances(dist0),.score(score0),
                           .offsets(offsets),.score_q15(q15));
    function automatic [15:0] clip(input signed [47:0] value, input integer bound);
        reg signed [47:0] rounded;
        begin
            rounded=(value+48'sd8388608)>>>24;
            if(value<=0) clip=0;
            else if(rounded>=bound) clip=16'(bound);
            else clip=rounded[15:0];
        end
    endfunction
    always @(posedge clk) begin
        if(!resetn) begin valid<=0;candidate<=0;raw_score<=0;end
        else if(advance) begin
            valid<={valid[2:0],in_valid};
            head0<=head;dist0<=distances;score0<=score_i8;tag0<={position,class_id};
            case(head)
            0: begin bx0<=($signed({1'b0,grid_x,3'b0})+48'sd4)<<<24;
                     by0<=($signed({1'b0,grid_y,3'b0})+48'sd4)<<<24;end
            1: begin bx0<=($signed({1'b0,grid_x,4'b0})+48'sd8)<<<24;
                     by0<=($signed({1'b0,grid_y,4'b0})+48'sd8)<<<24;end
            default: begin bx0<=($signed({1'b0,grid_x,5'b0})+48'sd16)<<<24;
                           by0<=($signed({1'b0,grid_y,5'b0})+48'sd16)<<<24;end
            endcase
            bx1<=bx0;by1<=by0;tag1<=tag0;score1<=score0;q151<=q15;
            left1<=offsets[0+:48];top1<=offsets[48+:48];
            right1<=offsets[96+:48];bottom1<=offsets[144+:48];
            x02<=bx1-left1;y02<=by1-top1;x12<=bx1+right1;y12<=by1+bottom1;
            tag2<=tag1;score2<=score1;q152<=q151;
            candidate<={28'd0,tag2,q152,clip(y12,480),clip(x12,640),clip(y02,480),clip(x02,640)};
            raw_score<=score2;
        end
    end
endmodule
