"""Native frontend/Gemmini/ASRAM wiring, derived from the existing P0 harness.
No experimental RTL overlays are used. Inputs are the selected generated SoC.
"""
from rtl_support import ports

def wrapper(rtl, observation=None):
    decls = ['input wire clock,reset,start,resume', 'input wire [31:0] table_count',
             'output wire done,host_wait,fault', 'output wire [63:0] host_tag',
             'output wire [31:0] cursor,completed_cursor', 'output wire [3:0] frontend_state',
             'output wire gem_busy', 'output wire [7:0] error_code',
             'output wire local_put', 'output wire [32:0] local_address',
             'output wire [31:0] local_mask', 'output wire [255:0] local_data',
             'output wire [3:0] local_size']
    mux_ports = ports(rtl / 'CommandFrontendMemoryMux.sv')
    for d, w, n in mux_ports:
        if n.startswith(('io_a_', 'io_d_')):
            decls.append(f'{d} wire {w} {n[3:]}')
    text = 'module S1TeamReplay(' + ',\n'.join(decls) + ');\nglbl glbl();\n'
    for d, w, n in mux_ports:
        if n.startswith(('io_g_', 'io_f_')):
            text += f'wire {w} {n[3:]};\n'
        elif n.startswith(('io_a_', 'io_d_')):
            text += f'wire {w} m_{n[3:]};\n'
    text += 'wire cmd_valid,cmd_ready;wire [6:0] cmd_funct;wire [63:0] cmd_rs1,cmd_rs2;wire gem_fault;\n'
    bindings = []
    for d, w, n in ports(rtl / 'Gemmini.sv'):
        v = '' if d == 'output' else "'0"
        if n in ('clock', 'reset'):
            v = n
        elif n.startswith('auto_spad_id_out_'):
            v = 'g_' + n.removeprefix('auto_spad_id_out_').replace('_bits_', '_')
        else:
            v = {'io_cmd_valid': 'cmd_valid', 'io_cmd_ready': 'cmd_ready',
                 'io_cmd_bits_inst_funct': 'cmd_funct', 'io_cmd_bits_rs1': 'cmd_rs1',
                 'io_cmd_bits_rs2': 'cmd_rs2', 'io_busy': 'gem_busy', 'io_interrupt': 'gem_fault',
                 'io_cmd_bits_inst_opcode': "7'h0b", 'io_cmd_bits_inst_xs1': "1'b1",
                 'io_cmd_bits_inst_xs2': "1'b1", 'io_resp_ready': "1'b1",
                 'io_dma_load_mode': "2'd2",
                 'io_loopconv_request_accept': 'cmd_valid && cmd_ready && cmd_funct==15'}.get(n, v)
            if n in ('io_cmd_bits_status_prv', 'io_cmd_bits_status_dprv', 'io_cmd_bits_status_mpp'):
                v = "2'd3"
        bindings.append(f'.{n}({v})')
    text += 'Gemmini dut(' + ',\n'.join(bindings) + ');\n'
    if not any(n == 'io_interrupt' for _, _, n in ports(rtl / 'Gemmini.sv')):
        text += "assign gem_fault=1'b0;\n"
    bindings = []
    for d, w, n in ports(rtl / 'CommandFrontendEngine.sv'):
        v = '' if d == 'output' else "'0"
        if n in ('clock', 'reset'):
            v = n
        elif n.startswith('io_mem_'):
            v = 'f_' + n.removeprefix('io_mem_')
        else:
            v = {'io_start': 'start', 'io_table_base': "32'hc0000000", 'io_table_count': 'table_count',
                 'io_timeout_cycles': "32'd100000000", 'io_resume': 'resume', 'io_resume_tag': 'host_tag',
                 'io_cmd_valid': 'cmd_valid', 'io_cmd_ready': 'cmd_ready', 'io_cmd_funct': 'cmd_funct',
                 'io_cmd_rs1': 'cmd_rs1', 'io_cmd_rs2': 'cmd_rs2', 'io_gemmini_busy': 'gem_busy',
                 'io_gemmini_fault': 'gem_fault', 'io_done': 'done', 'io_host_wait': 'host_wait',
                 'io_fault': 'fault', 'io_host_tag': 'host_tag', 'io_cursor': 'cursor',
                 'io_completed_cursor': 'completed_cursor', 'io_state_out': 'frontend_state',
                 'io_error_code': 'error_code'}.get(n, v)
        bindings.append(f'.{n}({v})')
    text += 'CommandFrontendEngine frontend(' + ',\n'.join(bindings) + ');\n'
    bindings = []
    for d, w, n in mux_ports:
        v = n if n in ('clock', 'reset') else (('m_' if n.startswith(('io_a_', 'io_d_')) else '') + n[3:])
        bindings.append(f'.{n}({v})')
    text += 'CommandFrontendMemoryMux mux(' + ',\n'.join(bindings) + ');\n'
    # This lane0 route follows production's split after the source31 mux.
    text += "wire local_target=m_a_address>=33'h20000000 && m_a_address<33'h20240000;\n"
    text += '''assign local_put=m_a_valid && m_a_ready && local_target && m_a_opcode<=1;
assign local_address=m_a_address;assign local_mask=m_a_mask;
assign local_data=m_a_data;assign local_size=m_a_size;
'''
    for d, w, n in mux_ports:
        if n.startswith('io_d_'):
            text += f'wire {w} s_{n[3:]};\n'
    text += 'wire s_a_ready;\n'
    bindings = []
    for d, w, n in ports(rtl / 'ActivationSramTL.sv'):
        v = '' if d == 'output' else "'0"
        if n in ('clock', 'reset'):
            v = n
        elif n.startswith('auto_port_in_0_'):
            f = n.removeprefix('auto_port_in_0_').replace('_bits_', '_')
            v = 'm_' + f if f.startswith('a_') and f != 'a_ready' else 's_' + f
            if f == 'a_valid':
                v = 'm_a_valid && local_target'
            if f == 'a_address':
                v = 'm_a_address[29:0]'
            if f == 'a_size':
                v = 'm_a_size[2:0]'
        elif n == 'auto_port_in_1_d_ready':
            v = "1'b1"
        bindings.append(f'.{n}({v})')
    text += 'ActivationSramTL asram(' + ',\n'.join(bindings) + ');\n'
    text += '''assign a_valid=m_a_valid && !local_target;
assign m_a_ready=local_target?s_a_ready:a_ready;
reg response_lock=0,response_local=0,response_second=0;
wire choose_local=response_lock?response_local:s_d_valid;
assign m_d_valid=choose_local?s_d_valid:d_valid;
assign s_d_ready=m_d_ready && choose_local;
assign d_ready=m_d_ready && !choose_local;
always @(posedge clock)begin
    if(reset)begin response_lock<=0;response_second<=0;end
    else if(m_d_valid)begin
        response_local<=choose_local;
        if(!m_d_ready)response_lock<=1;
        else if(m_d_opcode==1 && m_d_size==6 && !response_second)begin
            response_lock<=1;response_second<=1;
        end else begin response_lock<=0;response_second<=0;end
    end
end
'''
    for d, w, n in mux_ports:
        if n.startswith('io_a_') and n not in ('io_a_valid', 'io_a_ready'):
            text += f'assign {n[3:]}=m_{n[3:]};\n'
        if n.startswith('io_d_') and n not in ('io_d_valid', 'io_d_ready'):
            f = n[3:]
            text += f'assign m_{f}=choose_local?s_{f}:{f};\n'
    return text + (observation or '') + '\nendmodule\n'
