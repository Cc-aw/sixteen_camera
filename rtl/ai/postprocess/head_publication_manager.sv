`timescale 1ns/1ps
// Four worker/slot banks. Producer commits carry a generation; only completed
// clean transactions publish a head. A leased generation cannot be reallocated.
module head_publication_manager #(
    parameter integer TEST_HEAD_BYTES=0
)(
    input wire clk,resetn,
    input wire allocate,publish,abort_slot,release_slot,acquire,
    input wire [1:0] command_bank,lease_bank,
    input wire [31:0] command_version,lease_version,
    input wire [5:0] publish_mask,
    output reg [3:0] allocated,reading,fault,
    output reg [127:0] versions,
    output reg [23:0] ready_heads,producer_heads,
    output reg [31:0] rejected_commands,
    output reg clean_start,
    output wire clean_abort,
    output reg [32:0] clean_base,
    output reg [31:0] clean_bytes,
    input wire clean_busy,clean_done,clean_error,
    output wire active
);
    reg running;
    reg [1:0] active_bank;
    reg [2:0] active_head;
    reg [31:0] active_version;
    reg chosen;
    reg [1:0] chosen_bank;
    reg [2:0] chosen_head;
    assign active=running||clean_busy;
    assign clean_abort=running && (fault[active_bank] ||
        (abort_slot && command_bank==active_bank && command_version==active_version));
    function automatic [32:0] bank_base(input [1:0] bank);
        case(bank)
        0:bank_base=33'h0b2000000;1:bank_base=33'h0b2100000;
        2:bank_base=33'h0b2400000;default:bank_base=33'h0b2500000;
        endcase
    endfunction
    function automatic [19:0] head_offset(input [2:0] head);
        case(head)
        0:head_offset=20'h00000;1:head_offset=20'h5dc00;2:head_offset=20'h75300;
        3:head_offset=20'h7b0c0;4:head_offset=20'hc60c0;default:head_offset=20'hd8cc0;
        endcase
    endfunction
    function automatic [31:0] head_bytes(input [2:0] head);
        if(TEST_HEAD_BYTES!=0) head_bytes=TEST_HEAD_BYTES;
        else case(head)
        0:head_bytes=384000;1:head_bytes=96000;2:head_bytes=24000;
        3:head_bytes=307200;4:head_bytes=76800;default:head_bytes=19200;
        endcase
    endfunction
    always @* begin
        chosen=0;chosen_bank=0;chosen_head=0;
        for(integer b=0;b<4;b=b+1)
            for(integer h=0;h<6;h=h+1)
                if(!chosen && allocated[b] && !fault[b] && producer_heads[b*6+h] && !ready_heads[b*6+h]) begin
                    chosen=1;chosen_bank=2'(b);chosen_head=3'(h);
                end
    end
    always @(posedge clk) begin
        if(!resetn) begin
            allocated<=0;reading<=0;fault<=0;versions<=0;ready_heads<=0;producer_heads<=0;
            rejected_commands<=0;running<=0;clean_start<=0;clean_base<=0;clean_bytes<=0;
        end else begin
            clean_start<=0;
            if(allocate) begin
                if(!allocated[command_bank]) begin
                    allocated[command_bank]<=1;reading[command_bank]<=0;fault[command_bank]<=0;
                    versions[command_bank*32+:32]<=command_version;
                    ready_heads[command_bank*6+:6]<=0;producer_heads[command_bank*6+:6]<=0;
                end else rejected_commands<=rejected_commands+1'b1;
            end
            if(publish) begin
                if(allocated[command_bank] && versions[command_bank*32+:32]==command_version && !fault[command_bank])
                    producer_heads[command_bank*6+:6]<=producer_heads[command_bank*6+:6]|publish_mask;
                else rejected_commands<=rejected_commands+1'b1;
            end
            if(abort_slot) begin
                if(allocated[command_bank] && versions[command_bank*32+:32]==command_version)
                    fault[command_bank]<=1;
                else rejected_commands<=rejected_commands+1'b1;
            end
            if(acquire) begin
                if(allocated[lease_bank] && versions[lease_bank*32+:32]==lease_version &&
                   !fault[lease_bank] && |ready_heads[lease_bank*6+:6]) reading[lease_bank]<=1;
                else rejected_commands<=rejected_commands+1'b1;
            end
            if(release_slot) begin
                if(allocated[lease_bank] && versions[lease_bank*32+:32]==lease_version &&
                   !(running && active_bank==lease_bank) &&
                   (fault[lease_bank] || ready_heads[lease_bank*6+:6]==producer_heads[lease_bank*6+:6])) begin
                    allocated[lease_bank]<=0;reading[lease_bank]<=0;
                    ready_heads[lease_bank*6+:6]<=0;producer_heads[lease_bank*6+:6]<=0;
                end else rejected_commands<=rejected_commands+1'b1;
            end
            if(!running && !clean_busy && chosen && !release_slot && !abort_slot) begin
                active_bank<=chosen_bank;active_head<=chosen_head;
                active_version<=versions[chosen_bank*32+:32];
                clean_base<=bank_base(chosen_bank)+{13'd0,head_offset(chosen_head)};
                clean_bytes<=head_bytes(chosen_head);clean_start<=1;running<=1;
            end
            if(running && clean_done) begin
                running<=0;
                if(clean_error) fault[active_bank]<=1;
                else if(allocated[active_bank] && versions[active_bank*32+:32]==active_version &&
                        !fault[active_bank] && !clean_abort)
                    ready_heads[active_bank*6+active_head]<=1;
            end
        end
    end
endmodule
