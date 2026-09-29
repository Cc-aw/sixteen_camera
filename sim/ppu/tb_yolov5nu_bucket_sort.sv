`timescale 1ns/1ps
module tb_yolov5nu_bucket_sort;
    reg clk=0; always #5 clk=~clk;
    reg resetn=0,start=0,candidate_valid=0,candidates_finished=0,result_ready=0;
    reg [127:0] candidate_data=0;
    reg [7:0] candidate_score=0;
    wire candidate_ready,result_valid,result_last,busy,done,error,sort_active,nms_active;
    wire [127:0] result_data;
    wire [15:0] candidates_seen;
    wire [8:0] retained_count;
    wire [5:0] result_count;
    yolov5nu_bucket_nms dut(.*);
    reg [127:0] input_words[0:255],sorted[0:255],expected[0:9];
    reg [7:0] raw_score[0:255];
    reg suppressed[0:255];
    integer expected_count,received,sort_received,tick=0;
    reg stalled=0;
    reg [127:0] held;
    function automatic suppresses(input [127:0] a,b);
        integer l,t,r,bt,aa,bb,inter,un;
        begin
            l=a[15:0]>b[15:0]?a[15:0]:b[15:0];
            t=a[31:16]>b[31:16]?a[31:16]:b[31:16];
            r=a[47:32]<b[47:32]?a[47:32]:b[47:32];
            bt=a[63:48]<b[63:48]?a[63:48]:b[63:48];
            aa=(int'(a[47:32])-int'(a[15:0]))*(int'(a[63:48])-int'(a[31:16]));
            bb=(int'(b[47:32])-int'(b[15:0]))*(int'(b[63:48])-int'(b[31:16]));
            inter=r>l && bt>t?(r-l)*(bt-t):0; un=aa+bb-inter;
            suppresses=a[86:80]==b[86:80] && un>0 && 100*inter>45*un;
        end
    endfunction
    always @(negedge clk) begin
        tick=tick+1;
        result_ready=tick%7!=0 && tick%7!=1;
    end
    always @(posedge clk) if(resetn) begin
        if(stalled && (!result_valid || held!==result_data)) $fatal(1,"unstable result under stall");
        stalled<=result_valid&&!result_ready; held<=result_data;
        if(dut.sorted_valid && dut.sorted_ready) begin
            if(dut.sorted_data[127:0]!==sorted[sort_received]) $fatal(1,"bucket order index=%0d",sort_received);
            sort_received=sort_received+1;
        end
        if(result_valid && result_ready) begin
            if(received>=expected_count || result_data!==expected[received])
                $fatal(1,"NMS result index=%0d got=%h expected=%h",received,result_data,expected[received]);
            received=received+1;
        end
    end
    task automatic run_case(input integer n, input integer ties);
        reg [127:0] temp;
        integer x,y,w,h;
        reg [15:0] qscore;
        begin
            for(integer i=0;i<n;i=i+1) begin
                raw_score[i]=ties?8'd64:8'(34+(i*37)%94);
                x=(i*19)%600;y=(i*23)%440;w=20+(i%20);h=10+i%20;
                if(i<4) begin x=0;y=0;w=i==0?20:i==1?9:i==2?8:10;h=1;raw_score[i]=127;end
                qscore=16'((64'(raw_score[i])*16171270+32768)>>16);
                input_words[i]={28'd0,13'(i),7'(i<4?0:i%4),qscore,16'(y+h),16'(x+w),16'(y),16'(x)};
                sorted[i]=input_words[i]; suppressed[i]=0;
            end
            for(integer i=0;i<n;i=i+1)
                for(integer j=i+1;j<n;j=j+1)
                    if(sorted[j][79:64]>sorted[i][79:64] ||
                       (sorted[j][79:64]==sorted[i][79:64] && sorted[j][99:87]<sorted[i][99:87])) begin
                        temp=sorted[i];sorted[i]=sorted[j];sorted[j]=temp;
                    end
            expected_count=0;
            for(integer i=0;i<n;i=i+1) if(!suppressed[i] && expected_count<10) begin
                expected[expected_count]=sorted[i]; expected_count=expected_count+1;
                for(integer j=i+1;j<n;j=j+1) if(suppresses(sorted[i],sorted[j])) suppressed[j]=1;
            end
            received=0;sort_received=0;
            @(negedge clk);start=1;
            @(negedge clk);start=0;
            for(integer i=0;i<n;i=i+1) begin
                repeat(i%3) @(negedge clk);
                candidate_data=input_words[i];candidate_score=raw_score[i];candidate_valid=1;
                do @(posedge clk); while(!candidate_ready);
                @(negedge clk);candidate_valid=0;
            end
            wait(candidate_ready);
            @(negedge clk);candidates_finished=1;
            @(negedge clk);candidates_finished=0;
            wait(done);@(negedge clk);
            if(error || received!=expected_count || sort_received!=n || candidates_seen!=n || result_count!=expected_count)
                $fatal(1,"case failed n=%0d error=%b received=%0d expected=%0d sorted=%0d",n,error,received,expected_count,sort_received);
            $display("BUCKET_NMS_CASE=PASS n=%0d ties=%0d results=%0d",n,ties,received);
        end
    endtask
    initial begin
        repeat(3) @(negedge clk);resetn=1;
        run_case(0,0);run_case(1,0);run_case(255,0);run_case(256,0);run_case(256,1);
        $display("BUCKET_SORT_NMS=PASS");$finish;
    end
    initial begin repeat(30000) @(posedge clk);$fatal(1,"bucket/NMS timeout");end
endmodule
