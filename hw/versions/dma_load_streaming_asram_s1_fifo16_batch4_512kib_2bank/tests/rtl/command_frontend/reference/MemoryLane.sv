// Simulation-only lane: real compute RTL + production memory arbiter + DDR model.
module MemoryLane #(parameter integer ID=0)(
  input wire clock,reset,
  input wire cmd_valid,output wire cmd_ready,input wire [6:0] cmd_funct,
  input wire [63:0] cmd_rs1,cmd_rs2,output wire gem_busy,gem_fault,
  input wire f_req_valid,output wire f_req_ready,input wire [31:0] f_req_address,
  output wire f_resp_valid,input wire f_resp_ready,output wire [255:0] f_resp_data,output wire f_resp_error
);
  localparam [31:0] BASE=32'h80000000 + ID*32'h10000;
  reg [7:0] memory[0:65535];
  integer command_count=0,cycles=0,reads=0,writes=0,acks=0,fetches=0;
  wire g_a_valid,g_a_ready,g_d_valid,g_d_ready;
  wire [2:0] g_a_opcode,g_a_param,g_d_opcode;
  wire [1:0] g_d_param;
  wire [3:0] g_a_size,g_d_size;
  wire [4:0] g_a_source,g_d_source,g_d_sink;
  wire [31:0] g_a_address,g_a_mask;
  wire [255:0] g_a_data,g_d_data;
  wire g_a_corrupt,g_d_denied,g_d_corrupt;
  wire a_valid,a_ready,d_ready;
  wire [2:0] a_opcode,a_param;
  wire [3:0] a_size;
  wire [4:0] a_source;
  wire [31:0] a_address,a_mask;
  wire [255:0] a_data;
  wire a_corrupt;
  reg d_valid=0;
  reg [2:0] d_opcode=0;
  wire [1:0] d_param=0;
  reg [3:0] d_size=0;
  reg [4:0] d_source=0;
  wire [4:0] d_sink=0;
  wire d_denied=0,d_corrupt=0;
  reg [255:0] d_data=0;
  integer remaining=0,response_delay=0,response_address=0,write_beat=0;
  integer n,idx;
  GemminiFrontendMemoryMux mux(.*);
  TestGemmini gemmini (
    .clock(clock),.reset(reset),.io_cmd_ready(cmd_ready),.io_cmd_valid(cmd_valid),
    .io_cmd_bits_inst_funct(cmd_funct),.io_cmd_bits_rs1(cmd_rs1),.io_cmd_bits_rs2(cmd_rs2),
    .io_busy(gem_busy),.io_interrupt(gem_fault),
    .auto_spad_id_out_a_valid(g_a_valid),.auto_spad_id_out_a_ready(g_a_ready),
    .auto_spad_id_out_a_bits_opcode(g_a_opcode),.auto_spad_id_out_a_bits_param(g_a_param),
    .auto_spad_id_out_a_bits_size(g_a_size),.auto_spad_id_out_a_bits_source(g_a_source),
    .auto_spad_id_out_a_bits_address(g_a_address),.auto_spad_id_out_a_bits_mask(g_a_mask),
    .auto_spad_id_out_a_bits_data(g_a_data),.auto_spad_id_out_a_bits_corrupt(g_a_corrupt),
    .auto_spad_id_out_d_ready(g_d_ready),.auto_spad_id_out_d_valid(g_d_valid),
    .auto_spad_id_out_d_bits_opcode(g_d_opcode),.auto_spad_id_out_d_bits_param(g_d_param),
    .auto_spad_id_out_d_bits_size(g_d_size),.auto_spad_id_out_d_bits_source(g_d_source),
    .auto_spad_id_out_d_bits_sink(g_d_sink),.auto_spad_id_out_d_bits_data(g_d_data),
    .auto_spad_id_out_d_bits_denied(g_d_denied),.auto_spad_id_out_d_bits_corrupt(g_d_corrupt)
  );
  assign a_ready=!reset && !d_valid && response_delay==0 && remaining==0 && cycles%4!=ID;
  always @(posedge clock) begin
    cycles<=cycles+1;
    if(!reset) begin
      if(gem_fault) $fatal(1,"Gemmini %0d fault",ID);
      if(a_valid && a_ready) begin
        if(a_address<BASE || a_address>=BASE+32'h10000 || a_size>6 || a_corrupt)
          $fatal(1,"bad DMA lane=%0d address=%h size=%d",ID,a_address,a_size);
        d_size<=a_size;d_source<=a_source;
        if(a_opcode==4) begin
          response_address=(a_address-BASE)&32'hffffffe0;
          remaining<=(a_size>5)?(1<<(a_size-5)):1;
          response_delay<=7+ID*3;d_opcode<=1;reads<=reads+1;
          if(a_source==31)fetches<=fetches+1;
        end else if(a_opcode==0 || a_opcode==1)begin
          idx=((a_address-BASE)&32'hffffffe0)+write_beat*32;
          for(n=0;n<32;n=n+1)if(a_mask[n])memory[idx+n]<=a_data[n*8+:8];
          if(a_size<=5 || write_beat+1==(1<<(a_size-5)))begin
            write_beat<=0;remaining<=1;response_delay<=30+ID*11;d_opcode<=0;writes<=writes+1;
          end else write_beat<=write_beat+1;
        end else $fatal(1,"unexpected TL opcode");
      end
      if(response_delay>0)begin
        response_delay<=response_delay-1;
        if(response_delay==1)begin
          d_valid<=1;
          for(n=0;n<32;n=n+1)d_data[n*8+:8]<=memory[response_address+n];
        end
      end
      if(d_valid && d_ready)begin
        remaining<=remaining-1;
        if(d_opcode==0)acks<=acks+1;
        if(remaining==1)d_valid<=0;
        else begin
          response_address=response_address+32;
          for(n=0;n<32;n=n+1)d_data[n*8+:8]<=memory[response_address+n];
        end
      end
    end
  end
  task entry(input [255:0] value);
    for(integer b=0;b<32;b=b+1)memory['h8000+command_count*32+b]=value[b*8+:8];
    command_count=command_count+1;
  endtask
  task raw(input [6:0] f,input [63:0] a,b,input bit relative);
    entry({64'd0,b,a,46'd0,1'b0,relative,1'b0,f,8'd0});
  endtask
  task matmul(input [63:0] output_offset);
    raw(0,64'h3f80000000040101,4,0);
    raw(0,64'h3f80000000010004,64'h0001000000000000,0);
    raw(0,2,64'h3f80000000000010,0);
    raw(2,64'h1000,64'h0004000400000000,1);
    raw(2,64'h1100,64'h0004000400000004,1);
    entry(256'd1);
    raw(6,64'h0004000400000004,64'h0004000480000000,0);
    raw(4,64'h0004000400000000,64'h00040004ffffffff,0);
    entry(256'd1);
    raw(3,output_offset,64'h00040004a0000000,1);
  endtask
  task initialize;
    for(integer i=0;i<65536;i=i+1)memory[i]=8'ha5;
    for(integer i=0;i<16;i=i+1)begin memory['h1000+i]=8'(i-7+ID);memory['h1100+i]=8'((i%5)-2-ID);end
    for(integer i=0;i<20;i=i+1)raw(0,64'h3f80000000040101,4,0);
    matmul('h2000);
    if(ID==0)entry({64'd0,64'd0,64'd77,64'd2});
    matmul('h2100);
  endtask
  task modify_input;
    for(integer i=0;i<16;i=i+1)memory['h1000+i]=8'(6-i);
  endtask
  task check_matrix(input integer offset);
    integer expected,actual,p;
    if(writes!=acks || gem_busy) $fatal(1,"completion before DMA ack lane=%0d",ID);
    for(integer i=0;i<4;i=i+1)for(integer j=0;j<4;j=j+1)begin
      expected=0;
      for(integer k=0;k<4;k=k+1)expected=expected+$signed(memory['h1000+i*4+k])*$signed(memory['h1100+k*4+j]);
      p=offset+(i*4+j)*4;
      actual=$signed({memory[p+3],memory[p+2],memory[p+1],memory[p]});
      if(actual!==expected)$fatal(1,"lane%0d matrix mismatch [%0d,%0d] expected=%0d actual=%0d",ID,i,j,expected,actual);
    end
  endtask
endmodule
