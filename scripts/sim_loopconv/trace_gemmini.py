"""Optional handshake/data traces; no changes to production RTL."""
def trace_logic():
    s = 'reg [63:0] trace_cycle = 0;\nalways @(posedge clock) begin\ntrace_cycle <= trace_cycle + 1;\n'
    s += 'if (!reset && $test$plusargs("trace_internal")) begin\n'
    for name, inst in [('LC', 'mod'), ('LD', 'load_controller'), ('EX', 'ex_controller'), ('ST', 'store_controller')]:
        p = 'dut.' + inst + ('.io_out' if name == 'LC' else '.io_cmd')
        s += f'if ({p}_valid && {p}_ready) $display("TRACE {name} %0d %0d %h %h", trace_cycle, {p}_bits_cmd_inst_funct, {p}_bits_cmd_rs1, {p}_bits_cmd_rs2);\n'
    for bank in range(8):
        p = f'dut.spad.spad_mems_{bank}'
        mask = '{' + ','.join(f'{p}.io_write_mask_{i}' for i in reversed(range(64))) + '}'
        s += f'if ({p}.io_write_valid) $display("TRACE SW %0d {bank} %0d %h %h", trace_cycle, {p}.io_write_addr, {mask}, {p}.io_write_data);\n'
        s += f'if ({p}.io_read_req_valid && {p}.io_read_req_ready) $display("TRACE SR %0d {bank} %0d", trace_cycle, {p}.io_read_req_bits_addr);\n'
        s += f'if ({p}.io_read_resp_valid && {p}.io_read_resp_ready) $display("TRACE SD %0d {bank} %h", trace_cycle, {p}.io_read_resp_bits_data);\n'
    for bank in range(4):
        p = f'dut.spad.acc_mems_{bank}'
        data = '{' + ','.join(f'{p}.io_write_bits_data_{i//8}_{i%8}' for i in reversed(range(16))) + '}'
        s += f'if ({p}.io_write_valid && {p}.io_write_ready) $display("TRACE AW %0d {bank} %0d %0d %h", trace_cycle, {p}.io_write_bits_addr, {p}.io_write_bits_acc, {data});\n'
        data = '{' + ','.join(f'{p}.io_read_resp_bits_data_{i//8}_{i%8}' for i in reversed(range(16))) + '}'
        s += f'if ({p}.io_read_req_valid && {p}.io_read_req_ready) $display("TRACE AR %0d {bank} %0d", trace_cycle, {p}.io_read_req_bits_addr);\n'
        s += f'if ({p}.io_read_resp_valid && {p}.io_read_resp_ready) $display("TRACE AD %0d {bank} %h", trace_cycle, {data});\n'
    p = 'dut.ex_controller.mesh'
    data = '{' + ','.join(f'{p}.io_resp_bits_data_{i//8}_{i%8}' for i in reversed(range(16))) + '}'
    s += f'if ({p}.io_resp_valid && {p}.io_resp_bits_tag_rob_id_valid) $display("TRACE MR %0d %0d %0d %h", trace_cycle, {p}.io_resp_bits_tag_addr_data, {p}.io_resp_bits_last, {data});\n'
    for name in ['a', 'd']:
        data = '{' + ','.join(f'{p}.io_{name}_bits_{i}_0' if name == 'a' else f'{p}.io_{name}_bits_{i//8}_{i%8}' for i in reversed(range(64))) + '}'
        s += f'if ({p}.io_{name}_valid && {p}.io_{name}_ready) $display("TRACE M{name.upper()} %0d %h", trace_cycle, {data});\n'
    a = '{' + ','.join(f'{p}.a_buf_{i}_0' for i in reversed(range(64))) + '}'
    d = '{' + ','.join(f'{p}.d_buf_{i//8}_{i%8}' for i in reversed(range(64))) + '}'
    s += f'if ({p}.input_next_row_into_spatial_array) $display("TRACE MS %0d %0d %h %h", trace_cycle, {p}.fire_counter, {a}, {d});\n'
    s += f'if ({p}.io_req_valid && {p}.io_req_ready) $display("TRACE MQ %0d %0d %0d %0d", trace_cycle, {p}.io_req_bits_tag_addr_data, {p}.io_req_bits_pe_control_propagate, {p}.io_req_bits_flush);\n'
    s += 'end\nend\n'
    return s
