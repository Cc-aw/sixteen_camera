`timescale 1ns/1ps
// Descriptor ABI [197:0] addresses, [199:198] bank (worker/slot),
// [231:200] slot generation, [235:232] stream, [299:236] frame,
// [331:300] frame version, [363:332] flags.
module ppu_command_queue(
    input wire clk,resetn,enable,enqueue,
    input wire [363:0] descriptor,
    output wire admission_ready,
    output wire [2:0] queued,
    output wire [31:0] rejected,
    output reg [363:0] active_descriptor,
    output reg request,
    input wire engine_busy,engine_done,
    input wire completion_ready,
    output wire completion_valid,
    output wire active
);
    wire valid;wire [363:0] next_descriptor;
    reg [1:0] state;
    wire pop=enable && state==0 && !engine_busy && valid;
    ppu_descriptor_fifo u_fifo(.clk(clk),.resetn(resetn),.in_valid(enqueue),
        .in_ready(admission_ready),.in_data(descriptor),.out_valid(valid),.out_ready(pop),
        .out_data(next_descriptor),.count(queued),.rejected(rejected));
    assign completion_valid=state==3;
    assign active=state!=0;
    always @(posedge clk) begin
        if(!resetn) begin state<=0;request<=0;active_descriptor<=0;end
        else begin
            request<=0;
            case(state)
            0:if(pop) begin active_descriptor<=next_descriptor;request<=1;state<=1;end
            1:if(engine_busy) state<=2;
            2:if(engine_done) state<=3;
            3:if(completion_ready) state<=0;
            endcase
        end
    end
endmodule
