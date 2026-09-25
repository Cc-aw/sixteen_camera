`timescale 1ns/1ps
// II=1. 100I > 45(A+B-I) is exactly 29I > 9(A+B).
// Wide intermediates prevent overflow; equality never suppresses.
module yolov5nu_iou_pipeline (
    input wire clk,resetn,in_valid,
    input wire [127:0] selected,candidate,
    input wire [31:0] selected_area,candidate_area,
    input wire [8:0] in_index,
    output wire busy,out_valid,
    output wire [8:0] out_index,
    output wire suppress
);
    reg [3:0] valid,match;
    reg [8:0] tags[0:3];
    wire [15:0] left=selected[15:0]>candidate[15:0]?selected[15:0]:candidate[15:0];
    wire [15:0] top=selected[31:16]>candidate[31:16]?selected[31:16]:candidate[31:16];
    wire [15:0] right=selected[47:32]<candidate[47:32]?selected[47:32]:candidate[47:32];
    wire [15:0] bottom=selected[63:48]<candidate[63:48]?selected[63:48]:candidate[63:48];
    reg [15:0] dx,dy;
    reg [32:0] sum0,sum1;
    reg [31:0] intersection;
    reg [37:0] lhs,rhs;
    reg suppressed;
    assign busy=|valid;
    assign out_valid=valid[3];assign out_index=tags[3];assign suppress=suppressed;
    always @(posedge clk) begin
        if(!resetn) begin valid<=0;match<=0;suppressed<=0;end
        else begin
            valid<={valid[2:0],in_valid};
            match<={match[2:0],selected[86:80]==candidate[86:80]};
            tags[0]<=in_index;
            for(integer i=1;i<4;i=i+1) tags[i]<=tags[i-1];
            dx<=right>left?right-left:16'd0;dy<=bottom>top?bottom-top:16'd0;
            sum0<={1'b0,selected_area}+{1'b0,candidate_area};
            intersection<=dx*dy;sum1<=sum0;
            lhs<=({6'd0,intersection}<<5)-({6'd0,intersection}<<1)-{6'd0,intersection};
            rhs<=({5'd0,sum1}<<3)+{5'd0,sum1};
            suppressed<=match[2] && lhs>rhs;
        end
    end
endmodule
