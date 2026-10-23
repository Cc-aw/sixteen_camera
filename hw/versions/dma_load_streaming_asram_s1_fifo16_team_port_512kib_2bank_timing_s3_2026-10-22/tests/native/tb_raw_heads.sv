`timescale 1ns/1ps
// Consume the complete six raw heads emitted by the native graph replay.
module tb_raw_heads;
    reg clk=0;
    always #5 clk=~clk;
    reg resetn=0,start=0;
    wire read_start,stream_ready,busy,done,error;
    wire [32:0] read_base;
    wire [31:0] read_bytes,cycles;
    reg read_busy=0,read_done=0;
    reg [31:0] offset=0,consumed=0,bytes=0,ticks=0;
    reg [7:0] raw [0:907199];
    wire [255:0] stream_data;
    wire stream_valid=read_busy && ticks%7!=0;
    wire stream_last=consumed+32==bytes;
    reg [4:0] result_index=0;
    wire [127:0] result_word;
    wire [5:0] result_count;
    wire [12:0] positions_seen,candidates_seen;
    wire [15:0] nms_candidates_seen;
    wire [575:0] perf_values;
    localparam [32:0] BASE=33'h10000000;
    yolov5nu_postprocessor dut (
        .clk(clk),.resetn(resetn),.start(start),
        .class0(BASE),.class1(BASE+33'h5dc00),.class2(BASE+33'h75300),
        .dfl0(BASE+33'h7b0c0),.dfl1(BASE+33'hc60c0),.dfl2(BASE+33'hd8cc0),
        .read_start(read_start),.read_base(read_base),.read_bytes(read_bytes),
        .read_busy(read_busy),.read_done(read_done),.read_error(1'b0),
        .stream_data(stream_data),.stream_keep(32'hffffffff),
        .stream_valid(stream_valid),.stream_last(stream_last),.stream_ready(stream_ready),
        .result_index(result_index),.result_word(result_word),.result_count(result_count),
        .busy(busy),.done(done),.error(error),.positions_seen(positions_seen),
        .candidates_seen(candidates_seen),.nms_candidates_seen(nms_candidates_seen),
        .perf_values(perf_values),.cycles(cycles)
    );
    for(genvar b=0;b<32;b++)begin
        assign stream_data[8*b+:8]=raw[offset+consumed+b];
    end
    always @(posedge clk)begin
        ticks<=ticks+1;
        read_done<=0;
        if(!resetn)begin read_busy<=0;consumed<=0;end
        else if(read_start)begin
            if(read_busy || read_base<BASE || read_base+read_bytes>BASE+907200 ||
               !read_bytes || read_bytes%32)$fatal(1,"Invalid raw head read");
            offset<=32'(read_base-BASE);bytes<=read_bytes;consumed<=0;read_busy<=1;
        end else if(stream_valid && stream_ready)begin
            consumed<=consumed+32;
            if(stream_last)begin read_busy<=0;read_done<=1;end
        end
    end
    string input_path,result_path;
    integer fd;
    initial begin
        if(!$value$plusargs("heads=%s",input_path) || !$value$plusargs("result=%s",result_path))
            $fatal(1,"heads/result arguments required");
        $readmemh(input_path,raw);
        repeat(5)@(negedge clk);
        resetn=1;start=1;
        @(negedge clk);start=0;
        wait(done);repeat(3)@(negedge clk);
        if(error || positions_seen!=6300 || result_count>10 || busy)
            $fatal(1,"PPU completion/count mismatch");
        fd=$fopen(result_path,"w");
        if(!fd)$fatal(1,"Cannot write results");
        $fdisplay(fd,"%0d",result_count);
        for(integer r=0;r<10;r++)begin
            result_index=5'(r);@(negedge clk);
            $fdisplay(fd,"%032h",result_word);
        end
        $fclose(fd);
        $display("S1_RAW_HEAD_PPU_PASS positions=%0d candidates=%0d results=%0d cycles=%0d",
            positions_seen,candidates_seen,result_count,cycles);
        $finish;
    end
    initial begin repeat(3000000)@(posedge clk);$fatal(1,"PPU timeout");end
endmodule
