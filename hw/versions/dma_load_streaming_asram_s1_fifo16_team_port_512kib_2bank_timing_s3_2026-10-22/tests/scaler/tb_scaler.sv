`timescale 1ns/1ps
module tb_scaler;
    reg clock=0;
    always #5 clock=~clock;
    reg reset=1,send_valid=0;
    wire ref_req_ready,new_req_ready;
    reg [255:0] in_data=0;
    reg [31:0] in_mask=0;
    reg [15:0] in_scale=0,in_repeats=0;
    reg [7:0] in_tag=0;
    reg in_last=0;
    wire ref_resp_valid,new_resp_valid;
    wire [255:0] ref_data,new_data;
    wire [31:0] ref_mask,new_mask,ref_tasks,new_tasks;
    wire [15:0] ref_row,new_row;
    wire [7:0] ref_tag,new_tag;
    wire ref_last,new_last;
    integer cycle=0,ref_count=0,new_count=0,ref_ops=0,new_ops=0;
    wire ref_resp_ready=cycle%7!=0 && cycle%11!=0;
`ifdef LOCKSTEP_RESP
    wire new_resp_ready=ref_resp_ready;
`else
    wire new_resp_ready=cycle%5!=0 && cycle%13!=0;
`endif
    ScalerRef reference_dut(.clock(clock),.reset(reset),
        .req_valid(send_valid&&new_req_ready),.req_ready(ref_req_ready),
        .in_data(in_data),.in_mask(in_mask),.in_scale(in_scale),
        .in_repeats(in_repeats),.in_tag(in_tag),.in_last(in_last),
        .resp_valid(ref_resp_valid),.resp_ready(ref_resp_ready),
        .out_data(ref_data),.out_mask(ref_mask),.out_row(ref_row),
        .out_tag(ref_tag),.out_last(ref_last),.scale_tasks(ref_tasks));
    ScalerNew candidate_dut(.clock(clock),.reset(reset),
        .req_valid(send_valid&&ref_req_ready),.req_ready(new_req_ready),
        .in_data(in_data),.in_mask(in_mask),.in_scale(in_scale),
        .in_repeats(in_repeats),.in_tag(in_tag),.in_last(in_last),
        .resp_valid(new_resp_valid),.resp_ready(new_resp_ready),
        .out_data(new_data),.out_mask(new_mask),.out_row(new_row),
        .out_tag(new_tag),.out_last(new_last),.scale_tasks(new_tasks));
    reg [335:0] requests[0:255];
    reg [255:0] golden[0:1023],ref_results[0:1023],new_results[0:1023];
    // Metadata: finite-reference bit, mask, tag, row, last.
    reg [63:0] metadata[0:1023];
    reg [312:0] old_ref,old_new;
    reg ref_stalled=0,new_stalled=0;
    task tick;
        @(posedge clock);#1;@(negedge clock);
    endtask
    always @(posedge clock)begin
        cycle<=cycle+1;
        if(!reset)begin
`ifdef LOCKSTEP_RESP
            if(ref_req_ready!==new_req_ready || ref_resp_valid!==new_resp_valid)
                $fatal(1,"full-mask/identity scaler cycle regression cycle=%0d",cycle);
`endif
            ref_ops=ref_ops+ref_tasks;new_ops=new_ops+new_tasks;
            if(ref_stalled && (!ref_resp_valid || {ref_data,ref_mask,ref_tag,ref_row,ref_last}!==old_ref))
                $fatal(1,"reference response changed while stalled");
            if(new_stalled && (!new_resp_valid || {new_data,new_mask,new_tag,new_row,new_last}!==old_new))
                $fatal(1,"candidate response changed while stalled");
            ref_stalled=ref_resp_valid&&!ref_resp_ready;
            new_stalled=new_resp_valid&&!new_resp_ready;
            old_ref={ref_data,ref_mask,ref_tag,ref_row,ref_last};
            old_new={new_data,new_mask,new_tag,new_row,new_last};
            if(ref_resp_valid && ref_resp_ready)begin
                if({ref_mask,ref_tag,ref_row,ref_last}!==metadata[ref_count][56:0])
                    $fatal(1,"reference tag/mask/repeat/last mismatch record=%0d",ref_count);
                ref_results[ref_count]=ref_data;
                if(metadata[ref_count][57] && ref_data!==golden[ref_count])
                    $fatal(1,"reference FP16 golden mismatch record=%0d",ref_count);
                ref_count=ref_count+1;
            end
            if(new_resp_valid && new_resp_ready)begin
                if({new_mask,new_tag,new_row,new_last}!==metadata[new_count][56:0])
                    $fatal(1,"candidate tag/mask/repeat/last mismatch record=%0d",new_count);
                new_results[new_count]=new_data;
                for(integer lane=0;lane<32;lane=lane+1)
                    if(new_mask[lane] && metadata[new_count][57] &&
                       new_data[lane*8+:8]!==golden[new_count][lane*8+:8])
                        $fatal(1,"candidate FP16 golden mismatch record=%0d lane=%0d",new_count,lane);
                new_count=new_count+1;
            end
        end
    end
    initial begin
        $readmemh("requests.mem",requests);
        $readmemh("golden.mem",golden);
        $readmemh("metadata.mem",metadata);
        repeat(4)tick();reset=0;
        for(integer i=0;i<`REQUESTS;i=i+1)begin
            {in_last,in_tag,in_repeats,in_scale,in_mask,in_data}=requests[i][328:0];
            send_valid=1;#1;
            while(!(ref_req_ready&&new_req_ready))tick();
            tick();send_valid=0;
            if(i%4==0)repeat(i%3+1)tick();
        end
        while(ref_count<`RESPONSES || new_count<`RESPONSES)tick();
        repeat(20)tick();
        if(ref_count!=`RESPONSES || new_count!=`RESPONSES)$fatal(1,"extra scaler response");
        for(integer i=0;i<`RESPONSES;i=i+1)
            for(integer lane=0;lane<32;lane=lane+1)
                if(metadata[i][25+lane] && new_results[i][8*lane+:8]!==ref_results[i][8*lane+:8])
                    $fatal(1,"S1 baseline/candidate mismatch record=%0d lane=%0d",i,lane);
        if(ref_ops!=`REF_OPS || new_ops!=`NEW_OPS)
            $fatal(1,"scale task count mismatch reference=%0d candidate=%0d",ref_ops,new_ops);
        $display("S1_SCALER_PASS,requests=%0d,responses=%0d,reference_tasks=%0d,candidate_tasks=%0d,fp16=1,masked_equal=1,repeat_tag=1,backpressure=1",`REQUESTS,`RESPONSES,ref_ops,new_ops);
        $finish;
    end
    initial begin #20000000;$fatal(1,"scaler timeout ref=%0d new=%0d",ref_count,new_count);end
endmodule
