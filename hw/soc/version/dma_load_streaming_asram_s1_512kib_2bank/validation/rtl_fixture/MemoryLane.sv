// Simulation-only lane: real compute RTL + production memory arbiter + DDR model.
module MemoryLane #(parameter integer ID=0)(
  input wire clock,reset,input wire [1:0] dma_load_mode,output wire [31:0] dma_load_capabilities,
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
  wire [5:0] g_a_source,g_d_source; wire [6:0] g_d_sink;
  wire [32:0] g_a_address; wire [31:0] g_a_mask;
  wire [255:0] g_a_data,g_d_data;
  wire g_a_corrupt,g_d_denied,g_d_corrupt;
  wire a_valid,a_ready,d_ready;
  wire [2:0] a_opcode,a_param;
  wire [3:0] a_size;
  wire [5:0] a_source;
  wire [32:0] a_address; wire [31:0] a_mask;
  wire [255:0] a_data;
  wire a_corrupt;
  reg d_valid=0;
  reg [2:0] d_opcode=0;
  wire [1:0] d_param=0;
  reg [3:0] d_size=0;
  reg [5:0] d_source=0;
  wire [6:0] d_sink=0;
  wire d_denied=0,d_corrupt=0;
  reg [255:0] d_data=0;
  integer remaining=0,response_delay=0,response_address=0,write_beat=0;
  integer n,idx;

  localparam [31:0] LOCAL_BASE=32'h20000000+ID*32'h400000;
  wire m_a_valid,m_a_ready,m_d_valid,m_d_ready;
  wire [2:0] m_a_opcode,m_a_param,m_d_opcode;
  wire [1:0] m_d_param;wire [3:0] m_a_size,m_d_size;
  wire [5:0] m_a_source,m_d_source;wire [6:0] m_d_sink;
  wire [32:0] m_a_address;wire [31:0] m_a_mask;
  wire [255:0] m_a_data,m_d_data;wire m_a_corrupt,m_d_denied,m_d_corrupt;
  wire local_target=m_a_address>=33'h20000000 && m_a_address<33'h20c01000;
  wire s_a_ready,s_d_valid,s_d_ready,s_d_denied,s_d_corrupt,s_d_sink;
  wire [2:0] s_d_opcode,s_d_size;wire [1:0] s_d_param;wire [5:0] s_d_source;
  wire [255:0] s_d_data;
  reg service_valid=0;reg [2:0] service_opcode=0;
  reg [29:0] service_address=0;reg [255:0] service_data=0;
  wire service_ready,service_response,service_error;wire [255:0] service_result;
  wire [6:0] pending_dma,pending_service;
  wire [63:0] local_accepted,local_retired,local_gets,local_puts,local_denied;
  reg response_lock=0,response_local=0,response_second=0;
  reg [5:0] delayed_source=0;reg delayed_armed=0;integer local_delay=0;
  wire delayed=local_delay>0 && s_d_source==delayed_source;
  wire choose_local=response_lock?response_local:(s_d_valid && !delayed);
  wire visible_local=s_d_valid && !delayed;
  TestAsramBank #(.ID(ID)) local_bank(
    .clock(clock),.reset(reset),
    .s_a_valid(m_a_valid && local_target),.s_a_ready(s_a_ready),
    .s_a_bits_opcode(m_a_opcode),.s_a_bits_param(m_a_param),.s_a_bits_size(m_a_size[2:0]),
    .s_a_bits_source(m_a_source),.s_a_bits_address(m_a_address[29:0]),
    .s_a_bits_mask(m_a_mask),.s_a_bits_data(m_a_data),.s_a_bits_corrupt(m_a_corrupt),
    .s_d_valid(s_d_valid),.s_d_ready(s_d_ready),.s_d_bits_opcode(s_d_opcode),
    .s_d_bits_param(s_d_param),.s_d_bits_size(s_d_size),.s_d_bits_source(s_d_source),
    .s_d_bits_sink(s_d_sink),.s_d_bits_denied(s_d_denied),.s_d_bits_data(s_d_data),.s_d_bits_corrupt(s_d_corrupt),
    .service_valid(service_valid),.service_ready(service_ready),.service_opcode(service_opcode),
    .service_address(service_address),.service_data(service_data),.service_response(service_response),
    .service_result(service_result),.service_error(service_error),
    .pending_dma(pending_dma),.pending_service(pending_service),
    .accepted(local_accepted),.retired(local_retired),.gets(local_gets),.puts(local_puts),.denied(local_denied));
  assign a_valid=m_a_valid && !local_target;
  assign m_a_ready=local_target?s_a_ready:a_ready;
  assign a_opcode=m_a_opcode;assign a_param=m_a_param;assign a_size=m_a_size;
  assign a_source=m_a_source;assign a_address=m_a_address;assign a_mask=m_a_mask;
  assign a_data=m_a_data;assign a_corrupt=m_a_corrupt;
  assign m_d_valid=choose_local?visible_local:d_valid;
  assign m_d_opcode=choose_local?s_d_opcode:d_opcode;
  assign m_d_param=choose_local?s_d_param:d_param;assign m_d_size=choose_local?{1'b0,s_d_size}:d_size;
  assign m_d_source=choose_local?s_d_source:d_source;assign m_d_sink=choose_local?{6'd0,s_d_sink}:d_sink;
  assign m_d_data=choose_local?s_d_data:d_data;
  assign m_d_denied=choose_local?(s_d_denied || (inject_fault==1 && delayed_armed && s_d_source==delayed_source)):d_denied;
  assign m_d_corrupt=choose_local?(s_d_corrupt || (inject_fault==2 && delayed_armed && s_d_source==delayed_source)):d_corrupt;
  assign s_d_ready=m_d_ready && choose_local && !delayed;
  assign d_ready=m_d_ready && !choose_local;
  always @(posedge clock)begin
    if(reset)begin response_lock<=0;response_second<=0;local_delay<=0;delayed_armed<=0;end
    else begin
      if(local_delay>0)local_delay<=local_delay-1;
      if(m_a_valid && m_a_ready && local_target && m_a_opcode==4 &&
         ((m_a_address-LOCAL_BASE)=='h1080 || (m_a_address-LOCAL_BASE)=='h1180))begin
        delayed_source<=m_a_source;delayed_armed<=1;local_delay<=200;
      end
      if(m_d_valid)begin
        response_local<=choose_local;
        if(!m_d_ready)response_lock<=1;
        else if(m_d_opcode==1 && m_d_size==6 && !response_second)begin response_lock<=1;response_second<=1;end
        else begin response_lock<=0;response_second<=0;end
      end
    end
  end
  // Profiles: 0 DDR, 1 local read/write, 2 local reads, 3 local writes.
  integer storage_profile=1;
  function automatic [63:0] route_address(input [63:0] address,input bit store);
    if(address>=BASE && address<BASE+'h8000 &&
       (storage_profile==1 || (storage_profile==2 && !store) || (storage_profile==3 && store)))
      route_address=64'(LOCAL_BASE)+(address-BASE);
    else route_address=address;
  endfunction
  task service_access(input [2:0] op,input integer offset,input [255:0] data,output reg [255:0] result);
    integer timeout;
    @(negedge clock);service_opcode=op;service_address=LOCAL_BASE+offset;service_data=data;service_valid=1;
    timeout=0;
    do begin @(posedge clock);timeout=timeout+1;if(timeout>1000)$fatal(1,"service A timeout");end while(!service_ready);
    @(negedge clock);service_valid=0;timeout=0;
    while(!service_response)begin @(negedge clock);timeout=timeout+1;if(timeout>1000)$fatal(1,"service D timeout");end
    if(service_error)$fatal(1,"service denied offset=%h",offset);
    result=service_result;@(negedge clock);
  endtask
  reg [63:0] start_gets=0,start_puts=0;
  task local_prepare;
    reg [255:0] data,unused;
    start_gets=local_gets;start_puts=local_puts;
    if(storage_profile!=0)for(integer offset='h1000;offset<'h5c00;offset=offset+32)begin
      for(integer b=0;b<32;b=b+1)data[b*8+:8]=memory[offset+b];
      if((offset<(('h103f+(input_rows-1)*source_stride+channels+63)&~63)) || (offset>='h2000 && offset<'h2000+output_rows*32))service_access(0,offset,data,unused);
    end
  endtask
  task local_collect;
    reg [255:0] data;
    if(storage_profile==1 || storage_profile==3)begin
      for(integer offset='h5000;offset<'h5000+output_rows*32;offset=offset+32)begin
        service_access(4,offset,0,data);for(integer b=0;b<32;b=b+1)memory[offset+b]=data[b*8+:8];
      end
    end
    if(pending_dma || pending_service || local_accepted!=local_retired || local_denied)
      $fatal(1,"ASRAM did not drain or denied");
    if(storage_profile==0 && (local_gets!=start_gets || local_puts!=start_puts))$fatal(1,"DDR touched ASRAM");
    if(storage_profile==1 && (local_gets==start_gets || local_puts==start_puts))$fatal(1,"local read/write path unused");
    if(storage_profile==2 && (local_gets==start_gets || local_puts!=start_puts))$fatal(1,"local-read mixed route wrong");
    if(storage_profile==3 && (local_gets!=start_gets || local_puts==start_puts))$fatal(1,"local-write mixed route wrong");
    $display("ASRAM_REAL_LANE_PASS,lane=%0d,profile=%0d,accepted=%0d,retired=%0d,gets=%0d,puts=%0d,source31=external",ID,storage_profile,local_accepted,local_retired,local_gets,local_puts);
  endtask

integer inject_fault=0;

  GemminiFrontendMemoryMux mux(.a_valid(m_a_valid),.a_ready(m_a_ready),.a_opcode(m_a_opcode),.a_param(m_a_param),.a_size(m_a_size),.a_source(m_a_source),.a_address(m_a_address),.a_mask(m_a_mask),.a_data(m_a_data),.a_corrupt(m_a_corrupt),.d_valid(m_d_valid),.d_ready(m_d_ready),.d_opcode(m_d_opcode),.d_param(m_d_param),.d_size(m_d_size),.d_source(m_d_source),.d_sink(m_d_sink),.d_denied(m_d_denied),.d_data(m_d_data),.d_corrupt(m_d_corrupt),.*);
  TestGemmini gemmini (
    .io_dma_load_mode(dma_load_mode),.io_dma_load_capabilities(dma_load_capabilities),.clock(clock),.reset(reset),.io_cmd_ready(cmd_ready),.io_cmd_valid(cmd_valid),
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
      if(f_req_valid && f_req_ready)fetches<=fetches+1;
      if(gem_fault) $fatal(1,"Gemmini %0d fault",ID);
      if(a_valid && a_ready) begin
        if(a_address<BASE || a_address>=BASE+32'h10000 || a_size>6 || a_corrupt)
          $fatal(1,"bad DMA lane=%0d address=%h size=%d",ID,a_address,a_size);
        d_size<=a_size;d_source<=a_source;
        if(a_opcode==4) begin
          response_address=(a_address-BASE)&32'hffffffe0;
          remaining<=(a_size>5)?(1<<(a_size-5)):1;
          response_delay<=(a_source!=31 && ((a_address-BASE)=='h1080 || (a_address-BASE)=='h1180))?200:7+ID*3;d_opcode<=1;reads<=reads+1;
          
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
    if(f==1 || f==2 || f==3 || f==14)begin
      a=route_address(relative?64'(BASE)+a:a,f==3);relative=0;
    end
    if(f==20 || f==21)begin a=route_address(a,0);b=route_address(b,f==20);end
    entry({64'd0,b,a,46'd0,1'b0,relative,1'b0,f,8'd0});
  endtask
  task matmul(input [63:0] output_offset);
    raw(0,64'h00003c0000200101,4,0);
    raw(0,64'h00003c0000010004,64'h0001000000000000,0);
    raw(0,2,64'h00003c0000000010,0);
    raw(2,64'h1000,64'h0004000400000000,1);
    raw(2,64'h1100,64'h0004000400000020,1);
    entry(256'd1);
    raw(6,64'h0004000400000020,64'h0004000480000000,0);
    raw(4,64'h0004000400000000,64'h00040004ffffffff,0);
    entry(256'd1);
    raw(3,output_offset,64'h00040004a0000000,1);
  endtask
  task initialize;
 command_count=0;reads=0;writes=0;acks=0;fetches=0;
    for(integer i=0;i<65536;i=i+1)memory[i]=8'ha5;
    for(integer i=0;i<16;i=i+1)begin memory['h1000+i]=8'(i-7+ID);memory['h1100+i]=8'((i%5)-2-ID);end
    for(integer i=0;i<20;i=i+1)raw(0,64'h00003c0000200101,4,0);
    matmul('h2000);
    if(ID==0)entry({64'd0,64'd0,64'd77,64'd2});
    matmul('h2100); prepare_conv();
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

integer parameter_case=0,channels=3,repetitions=6,input_rows=32,source_stride=3,scale_bits='h3c00;
integer output_rows,first_row,fragments,expected_writes,expected_gets,unknown_value;
reg [7:0] baseline[0:24575];
function integer request_count(input [63:0] address,input integer bytes);
  reg [63:0] cursor;integer left,n32,n64,n;
  cursor=address;left=bytes;request_count=0;
  while(left>0)begin
    n32=(left<32-cursor[4:0])?left:32-cursor[4:0];
    n64=(left<64-cursor[5:0])?left:64-cursor[5:0];
    n=n64>n32?n64:n32;cursor=cursor+n;left=left-n;request_count=request_count+1;
  end
endfunction
task select_parameters(input integer index);
  parameter_case=index;
  case(index)
    0:begin channels=3;repetitions=6;input_rows=32;source_stride=3;scale_bits='h3c00;end
    1:begin channels=1;repetitions=32;input_rows=2;source_stride=1;scale_bits='h3c00;end
    2:begin channels=8;repetitions=4;input_rows=32;source_stride=8;scale_bits='h4000;end
    3:begin channels=12;repetitions=2;input_rows=32;source_stride=12;scale_bits='h3c00;end
    4:begin channels=16;repetitions=2;input_rows=32;source_stride=16;scale_bits='h4000;end
    5:begin channels=12;repetitions=2;input_rows=3;source_stride=32;scale_bits='h7e00;end
  endcase
  first_row=64-repetitions+1;output_rows=input_rows+repetitions-1+2;
endtask

task prepare_conv;endtask
task check_conv;endtask
reg [31:0] previous_writes=0;
integer observed_writes[0:3];integer observed_gets[0:3];integer previous_gets=0;
integer actual_gets=0;integer actual_return_bytes=0;
always @(posedge clock)if(!reset)begin
  if(g_a_valid && g_a_ready && g_a_opcode==4)actual_gets=actual_gets+1;
  if(g_d_valid && g_d_ready && g_d_opcode==1)actual_return_bytes=actual_return_bytes+32;
end
task initialize_raw;
  command_count=0;reads=0;writes=0;acks=0;fetches=0;stream_active=0;
  for(integer i=0;i<65536;i=i+1)memory[i]=8'ha5;

  for(integer row=0;row<input_rows;row=row+1)for(integer c=0;c<channels;c=c+1)
    memory['h103f+row*source_stride+c]=8'((row*channels+c)*7+11+ID*3);
  raw(0,64'h00003c0000200101,32,0);
  for(integer offset=0;offset<output_rows;offset=offset+32)
    raw(2,64'(BASE)+'h2000+offset*32,(64'((output_rows-offset)>32?32:(output_rows-offset))<<48)|(64'd32<<32)|64'(first_row+offset),0);
  entry(256'd1);
  raw(0,(64'(scale_bits)<<32)|(64'd32<<16)|(64'(repetitions)<<8)|1,64'(source_stride),0);
  raw(2,64'(BASE)+'h103f,(64'(input_rows)<<48)|(64'(channels)<<32)|64'd64,0);
  raw(2,0,(64'd2<<48)|(64'(channels)<<32)|64'(64+input_rows),0);
  raw(0,2,64'h00003c0000000020,0);
  for(integer offset=0;offset<output_rows;offset=offset+32)
    raw(3,64'(BASE)+'h5000+offset*32,(64'((output_rows-offset)>32?32:(output_rows-offset))<<48)|(64'd32<<32)|64'(first_row+offset),0);
  entry(256'd1);
endtask
task check_raw;
  integer expected,actual,offset,p;
  if(writes!=acks || gem_busy)$fatal(1,"RAW/store completion before ACK");

  for(integer row=first_row;row<first_row+output_rows;row=row+1)for(integer byte_index=0;byte_index<32;byte_index=byte_index+1)begin
    expected='ha5;unknown_value=0;
    for(integer input_row=0;input_row<input_rows;input_row=input_row+1)
      for(integer k=repetitions-1;k>=0;k=k-1)
        if(row==64+input_row-k && byte_index>=k*channels && byte_index<k*channels+channels)begin
          expected=((input_row*channels+byte_index-k*channels)*7+11+ID*3)&255;
          if(expected>=128)expected=expected-256;
          if(scale_bits=='h4000)begin
            expected=expected*2;if(expected>127)expected=127;if(expected< -128)expected= -128;
          end
          unknown_value=(scale_bits=='h7e00);
        end
    for(integer input_row=0;input_row<2;input_row=input_row+1)
      for(integer k=repetitions-1;k>=0;k=k-1)
        if(row==64+input_rows+input_row-k && byte_index>=k*channels && byte_index<k*channels+channels)begin expected=0;unknown_value=0;end
    offset=(row-first_row)*32+byte_index;actual=memory['h5000+offset];
    if(dma_load_mode==0)baseline[parameter_case*4096+offset]=actual;
    // HardFloat RecFNToIN maps NaN to signed INT8 maximum (excSign=false).
    // The fixed-mode test has no legacy-mode run to populate a baseline.
    if(unknown_value)expected=127;
    if(actual!==(expected&255))$fatal(1,"parameterized SPAD mismatch case=%0d mode=%0d lane=%0d row=%0d byte=%0d expected=%h actual=%h",parameter_case,dma_load_mode,ID,row,byte_index,expected&255,actual);
  end
  observed_writes[dma_load_mode]=gemmini.dut.spad.io_counter_external_values_22-previous_writes;
  previous_writes=gemmini.dut.spad.io_counter_external_values_22;
  observed_gets[dma_load_mode]=actual_gets-previous_gets;previous_gets=actual_gets;

  fragments=0;
  for(integer row=0;row<input_rows;row=row+1)fragments=fragments+request_count(64'(BASE)+'h103f+row*source_stride,channels);
  expected_writes=output_rows+fragments*repetitions+2*repetitions;
  expected_gets=output_rows+fragments;
  if(dma_load_mode!=0 && source_stride==channels)begin
    if(dma_load_mode!=3)expected_gets=output_rows+request_count(64'(BASE)+'h103f,input_rows*channels);
    expected_writes=output_rows+input_rows*repetitions+2*repetitions;
  end
  if(dma_load_mode>=2)expected_writes=output_rows+input_rows+repetitions-1+2+repetitions-1;
  if(observed_writes[dma_load_mode]!=expected_writes || observed_gets[dma_load_mode]!=expected_gets)
    $fatal(1,"parameterized traffic mismatch case=%0d mode=%0d writes=%0d/%0d gets=%0d/%0d",parameter_case,dma_load_mode,observed_writes[dma_load_mode],expected_writes,observed_gets[dma_load_mode],expected_gets);
  if(dma_load_mode!=0 && (parameter_case==0 || parameter_case==3))begin
    if(stream_early_rows==0 || stream_early_writes==0)$fatal(1,"Streaming did not write before final input return");
    $display("DMA_STREAMING_SPAD_PASS,lane=%0d,mode=%0d,case=%0d,early_rows=%0d,early_sram_writes=%0d",ID,dma_load_mode,parameter_case,stream_early_rows,stream_early_writes);
  end
  $display("DMA_SPAD_PASS,lane=%0d,case=%0d,mode=%0d,channels=%0d,rows=%0d,pixels=%0d,scale=%h,sram_writes=%0d,dma_gets=%0d,poison=checked,RAW=checked,zero=checked",ID,parameter_case,dma_load_mode,channels,input_rows,repetitions,scale_bits,observed_writes[dma_load_mode],observed_gets[dma_load_mode]);
endtask

integer stream_received=0,stream_group=0,stream_early_rows=0,stream_early_writes=0;
integer stream_previous_writes=0;reg stream_active=0;
always @(posedge clock)if(!reset)begin
  if(gemmini.dut.spad.group.io_in_valid && gemmini.dut.spad.group.io_in_ready &&
     gemmini.dut.spad.group.io_in_bits_cmd_first && !gemmini.dut.spad.group.io_in_bits_all_zeros)begin
    stream_received=0;stream_early_rows=0;stream_early_writes=0;stream_active=1;
  end
  if(stream_active && gemmini.dut.spad.group.io_replay_valid && gemmini.dut.spad.group.io_replay_ready &&
     !gemmini.dut.spad.group.io_replay_bits_group_zeros && stream_received<input_rows*channels)
    stream_early_rows=stream_early_rows+1;
  if(stream_active && stream_received<input_rows*channels &&
     gemmini.dut.spad.io_counter_external_values_22!=stream_previous_writes)
    stream_early_writes=stream_early_writes+gemmini.dut.spad.io_counter_external_values_22-stream_previous_writes;
  stream_previous_writes=gemmini.dut.spad.io_counter_external_values_22;
  if(stream_active && gemmini.dut.spad.group.io_fragment_valid)
    stream_received=stream_received+gemmini.dut.spad.group.io_fragment_bits_bytes;
end

endmodule
