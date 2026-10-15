`timescale 1ns/1ps
module tb_ddr_register_slice;
  parameter MODE=1;
  localparam CHANNELS=5, WIDTH=577, BEATS=300;
  reg clk=0;always #1.6665 clk=~clk;
  reg reset=1;
  reg [WIDTH-1:0] source[CHANNELS];
  wire [WIDTH-1:0] result[CHANNELS];
  reg [CHANNELS-1:0] valid=0,ready=0;
  wire [CHANNELS-1:0] source_ready,result_valid;
  integer sent[CHANNELS],received[CHANNELS],streak[CHANNELS],longest[CHANNELS];
  reg blocked[CHANNELS];reg [WIDTH-1:0] held[CHANNELS];
  integer cycle=0;
  function automatic [WIDTH-1:0] pattern(input integer channel,input integer sequence_id);
    integer word;begin
      for(word=0;word<18;word=word+1)pattern[32*word+:32]=(sequence_id*32'h1020301)^(channel*32'h1234567)^word;
      pattern[WIDTH-1]=sequence_id[0];
    end
  endfunction
  for(genvar c=0;c<CHANNELS;c=c+1)begin
    axi_register_slice_v2_1_29_axic_register_slice #(.C_DATA_WIDTH(WIDTH),.C_REG_CONFIG(MODE)) dut(
      .ACLK(clk),.ARESET(reset),.S_PAYLOAD_DATA(source[c]),.S_VALID(valid[c]),.S_READY(source_ready[c]),
      .M_PAYLOAD_DATA(result[c]),.M_VALID(result_valid[c]),.M_READY(ready[c]));
  end
  initial begin
    for(integer c=0;c<CHANNELS;c=c+1)begin sent[c]=0;received[c]=0;streak[c]=0;longest[c]=0;blocked[c]=0;held[c]=0;source[c]=0;end
    repeat(6)@(negedge clk);reset=0;
  end
  always @(negedge clk)if(!reset)begin
    for(integer c=0;c<CHANNELS;c=c+1)begin
      valid[c]=sent[c]<BEATS;source[c]=pattern(c,sent[c]);
      ready[c]=(cycle<130)||(((cycle+c)%13)>3&&((cycle+2*c)%7)!=1);
    end
  end
  always @(posedge clk)if(!reset)begin
    cycle=cycle+1;
    for(integer c=0;c<CHANNELS;c=c+1)begin
      if(blocked[c]&&(!result_valid[c]||result[c]!==held[c]))$fatal(1,"payload changed under backpressure channel=%0d",c);
      blocked[c]=result_valid[c]&&!ready[c];held[c]=result[c];
      if(result_valid[c]&&ready[c])begin
        if(result[c]!==pattern(c,received[c]))$fatal(1,"lost/reordered beat channel=%0d beat=%0d",c,received[c]);
        received[c]=received[c]+1;streak[c]=streak[c]+1;
        if(streak[c]>longest[c])longest[c]=streak[c];
      end else streak[c]=0;
      if(valid[c]&&source_ready[c])sent[c]=sent[c]+1;
    end
    if(received[0]==BEATS&&received[1]==BEATS&&received[2]==BEATS&&received[3]==BEATS&&received[4]==BEATS)begin
      for(integer c=0;c<CHANNELS;c=c+1)begin
        if(sent[c]!=BEATS)$fatal(1,"unexpected transfer count");
        if(MODE==1&&longest[c]<96)$fatal(1,"full register mode inserted bubbles");
        if(MODE==7&&longest[c]!=1)$fatal(1,"old mode comparison unexpected");
      end
      $display("DDR_REGISTER_SLICE_PASS mode=%0d channels=5 beats=%0d consecutive=%0d cycles=%0d",MODE,BEATS,longest[0],cycle);
      $finish;
    end
    if(cycle>2000)$fatal(1,"register slice drain timeout");
  end
endmodule
