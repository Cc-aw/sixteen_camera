`timescale 1ns/1ps
// Command-level ownership. Publication errors complete with error and never
// launch the PPU on a partially visible head.
module ppu_publication_gate (
    input wire clk,resetn,request,enable,
    input wire [1:0] command_bank,
    input wire [31:0] command_version,
    input wire [3:0] allocated,fault,
    input wire [127:0] versions,
    input wire [23:0] ready_heads,
    input wire publication_active,
    output reg [1:0] lease_bank,
    output reg [31:0] lease_version,
    output reg acquire,release_slot,core_start,
    input wire core_busy,core_done,core_error,
    output wire [5:0] core_heads,
    output wire core_abort,
    output reg busy,done,error
);
    localparam [2:0] IDLE=0,WAIT_READY=1,LAUNCH=2,RUN=3,RELEASE=4;
    reg [2:0] state;
    reg guarded;
    wire invalid_slot = !allocated[lease_bank] || versions[lease_bank*32+:32]!=lease_version || fault[lease_bank];
    assign core_heads = guarded ? ready_heads[lease_bank*6+:6] : 6'h3f;
    assign core_abort = guarded && busy && invalid_slot;
    always @(posedge clk) begin
        if(!resetn) begin
            state<=IDLE;busy<=0;done<=0;error<=0;acquire<=0;release_slot<=0;core_start<=0;
            lease_bank<=0;lease_version<=0;guarded<=0;
        end else begin
            acquire<=0;release_slot<=0;core_start<=0;
            case(state)
            IDLE:if(request) begin
                lease_bank<=command_bank;lease_version<=command_version;guarded<=enable;
                busy<=1;done<=0;error<=0;
                if(enable) state<=WAIT_READY;
                else begin core_start<=1;state<=LAUNCH;end
            end
            WAIT_READY:begin
                if(!allocated[lease_bank] || versions[lease_bank*32+:32]!=lease_version || fault[lease_bank]) begin
                    error<=1;state<=RELEASE;
                end else if(ready_heads[lease_bank*6]) begin
                    acquire<=1;core_start<=1;state<=LAUNCH;
                end
            end
            LAUNCH:if(core_busy) state<=RUN;
            RUN:if(core_done) begin error<=core_error;state<=RELEASE;end
            RELEASE:if(!guarded || (!publication_active && (invalid_slot || core_heads==6'h3f))) begin
                if(guarded && allocated[lease_bank] && versions[lease_bank*32+:32]==lease_version) release_slot<=1;
                busy<=0;done<=1;state<=IDLE;
            end
            endcase
        end
    end
endmodule
