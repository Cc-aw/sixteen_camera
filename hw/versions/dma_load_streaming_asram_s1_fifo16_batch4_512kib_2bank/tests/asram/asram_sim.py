"""Simulation wiring for actual candidate ASRAM banks, not a replacement RAM.

The generated Gemmini/frontend and both ports of each ActivationSramTL are
instantiated unchanged. Only the external DDR/local address decoder and D
arbiter are testbench wiring. Service TL transactions initialize/check bytes.
"""
from pathlib import Path
import re
import os


def bank_wrapper(rtl, ports):
    declarations = ['input wire clock,reset', 'input wire [2:0] service_opcode',
                    'input wire service_valid', 'output wire service_ready',
                    'input wire [29:0] service_address', 'input wire [255:0] service_data',
                    'output wire service_response', 'output wire [255:0] service_result',
                    'output wire service_error', 'output wire [6:0] pending_dma,pending_service',
                    'output wire [63:0] accepted,retired,gets,puts,denied']
    fields = {'a_ready': ('output',''), 'a_valid':('input',''),
              'a_bits_opcode':('input','[2:0]'), 'a_bits_param':('input','[2:0]'),
              'a_bits_size':('input','[2:0]'), 'a_bits_source':('input','[5:0]'),
              'a_bits_address':('input','[29:0]'), 'a_bits_mask':('input','[31:0]'),
              'a_bits_data':('input','[255:0]'), 'a_bits_corrupt':('input',''),
              'd_ready':('input',''), 'd_valid':('output',''),
              'd_bits_opcode':('output','[2:0]'), 'd_bits_param':('output','[1:0]'),
              'd_bits_size':('output','[2:0]'), 'd_bits_source':('output','[5:0]'),
              'd_bits_sink':('output',''), 'd_bits_denied':('output',''),
              'd_bits_data':('output','[255:0]'), 'd_bits_corrupt':('output','')}
    declarations += [f'{d} wire {w} s_{k}' for k,(d,w) in fields.items()]
    blocks=[]
    for lane in range(3):
        name='ActivationSramTL'+('' if lane==0 else '_'+str(lane))
        bindings=[]
        for direction,width,port in ports(rtl/(name+'.sv')):
            value=''
            if port in ('clock','reset'):value=port
            elif port=='clear':value="1'b0"
            elif port.startswith('auto_port_in_0_'):value='s_'+port.removeprefix('auto_port_in_0_')
            elif port.startswith('auto_port_in_1_'):
                f=port.removeprefix('auto_port_in_1_')
                value={'a_valid':'service_valid','a_ready':'service_ready',
                       'a_bits_opcode':'service_opcode','a_bits_size':"3'd5",'a_bits_source':"6'd31",
                       'a_bits_address':'service_address','a_bits_data':'service_data',
                       'a_bits_mask':"32'hffffffff",'d_ready':"1'b1",'d_valid':'service_response',
                       'd_bits_data':'service_result','d_bits_denied':'service_error'}.get(f,"'0" if direction=='input' else '')
            elif port in ('outstanding_0','outstanding_1'):value='pending_dma' if port.endswith('0') else 'pending_service'
            elif port in ('counters_0_0','counters_0_1','counters_0_2','counters_0_3','counters_0_4','counters_0_15'):
                value={'counters_0_0':'accepted','counters_0_1':'retired','counters_0_2':'gets','counters_0_3':'put_full','counters_0_4':'put_partial','counters_0_15':'denied'}[port]
            elif direction=='input':value="'0"
            bindings.append(f'.{port}({value})')
        blocks.append(f'if(ID=={lane})begin:b{lane}\n{name} bank('+','.join(bindings)+');\nend')
    return 'module TestAsramBank #(parameter ID=0)(\n'+',\n'.join(declarations)+');\nwire [63:0] put_full,put_partial;assign puts=put_full+put_partial;\ngenerate\n'+' else '.join(blocks)+'\nendgenerate\nendmodule\n'


def install(lane, out, rtl, ports):
    (out/'TestAsramBank.sv').write_text(bank_wrapper(rtl,ports))
    # Keep the original external DDR model and source31 command fetches.
    bus=['a_valid','a_ready','a_opcode','a_param','a_size','a_source','a_address','a_mask','a_data','a_corrupt',
         'd_valid','d_ready','d_opcode','d_param','d_size','d_source','d_sink','d_denied','d_data','d_corrupt']
    lane=lane.replace('GemminiFrontendMemoryMux mux(.*);','GemminiFrontendMemoryMux mux('+','.join(f'.{x}(m_{x})' for x in bus)+',.*);')
    code=r'''
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
      service_access(0,offset,data,unused);
    end
  endtask
  task local_collect;
    reg [255:0] data;
    if(storage_profile==1 || storage_profile==3)begin
      for(integer offset='h2000;offset<'h2200;offset=offset+32)begin
        service_access(4,offset,0,data);for(integer b=0;b<32;b=b+1)memory[offset+b]=data[b*8+:8];
      end
      for(integer offset='h5000;offset<'h5c00;offset=offset+32)begin
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
'''
    if os.environ.get('STREAM_ASRAM_COMPACT') == '1':
        code=code.replace('service_access(0,offset,data,unused);', "if((offset<((\'h103f+(input_rows-1)*source_stride+channels+63)&~63)) || (offset>=\'h2000 && offset<\'h2000+output_rows*32))service_access(0,offset,data,unused);")
        start=code.index("      for(integer offset='h2000;")
        end=code.index("      for(integer offset='h5000;",start)
        code=code[:start]+code[end:]
        code=code.replace("offset<'h5c00;offset=offset+32)begin\n        service_access", "offset<'h5000+output_rows*32;offset=offset+32)begin\n        service_access")
    elif os.environ.get('STREAM_ASRAM_COMPACT') == 'fault':
        code=code.replace('service_access(0,offset,data,unused);', "if(offset<\'h10c0)service_access(0,offset,data,unused);")
        start=code.index("      for(integer offset='h2000;")
        end=code.index("      for(integer offset='h5000;",start)
        code=code[:start]+code[end:]
        code=code.replace("offset<'h5c00;offset=offset+32)begin\n        service_access", "offset<'h5060;offset=offset+32)begin\n        service_access")
    if 'integer inject_fault=0' not in lane:code+='\ninteger inject_fault=0;\n'
    # The test fixture initializes via the independent service TL port.
    lane=lane.replace('  GemminiFrontendMemoryMux mux(',code+'\n  GemminiFrontendMemoryMux mux(')
    anchor="    entry({64'd0,b,a,46'd0,1'b0,relative,1'b0,f,8'd0});"
    assert anchor in lane
    lane=lane.replace(anchor,"""    if(f==1 || f==2 || f==3 || f==14)begin
      a=route_address(relative?64'(BASE)+a:a,f==3);relative=0;
    end
    if(f==20 || f==21)begin a=route_address(a,0);b=route_address(b,f==20);end
"""+anchor)
    return lane


def instrument_tb(tb):
    for task in ('initialize','initialize_raw','initialize_fault','modify_input'):
        tb=re.sub(r'(lanes\[(\d+)\]\.lane\.'+task+r'\(\);)',lambda m:m[1]+f'lanes[{m[2]}].lane.local_prepare();',tb)
    for task in ('check_raw','check_conv','check_matrix','check_recovered'):
        tb=re.sub(r'(lanes\[(\d+)\]\.lane\.'+task+r'\()',lambda m:f'lanes[{m[2]}].lane.local_collect();'+m[1],tb)
    for task in ('initialize','initialize_raw','initialize_fault'):
        seq=''.join(f'lanes[{i}].lane.{task}();lanes[{i}].lane.local_prepare();' for i in range(3))
        par='fork '+''.join(f'begin lanes[{i}].lane.{task}();lanes[{i}].lane.local_prepare();end ' for i in range(3))+'join'
        tb=tb.replace(seq,par)
    for task in ('check_raw','check_recovered'):
        seq=''.join(f'lanes[{i}].lane.local_collect();lanes[{i}].lane.{task}();' for i in range(3))
        par='fork '+''.join(f'begin lanes[{i}].lane.local_collect();lanes[{i}].lane.{task}();end ' for i in range(3))+'join'
        tb=tb.replace(seq,par)
    return tb
