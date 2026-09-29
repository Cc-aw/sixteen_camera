"""A/B experiment on a build-local RTL copy; never edits generated production RTL."""
from prepare_gemmini import build, rtl
import re

source = rtl / 'ExecuteController.sv'
s = source.read_text()
registers = ''
for operand, suffix in [('a', '1'), ('b', '6'), ('d', '12')]:
    sent = 'experiment_sent_' + operand
    registers += f'reg {sent};\nalways @(posedge clock) begin\n'
    registers += f'if (reset || (_mesh_cntl_signals_q_io_deq_valid && mesh_cntl_signals_q_io_deq_ready)) {sent} <= 0;\n'
    registers += f'else if (_mesh_cntl_signals_q_io_deq_ready_T_{suffix}) {sent} <= 1;\nend\n'
    prefix = f'assign mesh_io_{operand}_valid = '
    assert s.count(prefix) == 1
    s = s.replace(prefix, prefix + f'!{sent} & (~_mesh_cntl_signals_q_io_deq_bits_first | _mesh_io_req_ready) & ')
match = re.search(r'wire\s+mesh_cntl_signals_q_io_deq_ready = [^;]+;', s)
assert match
old = match.group()
new = old
for operand in ['a', 'b', 'd']:
    new = new.replace(f'~_mesh_io_{operand}_ready', f'experiment_sent_{operand}')
s = s.replace(old, registers + new)
# Retire the supplying response at that operand's handshake, even if another
# operand keeps the shared control token waiting. The sent bits prevent replay.
s, n = re.subn(r'(assign io_(?:srams_read_\d+_resp|acc_read_resp_\d+)_ready = )_mesh_io_req_valid_T_1',
               r'\1_mesh_cntl_signals_q_io_deq_valid', s)
assert n == 12, n
out = build / 'handshake_experiment'
out.mkdir(exist_ok=True)
copy = out / source.name
copy.write_text(s)
filelist = (build / 'rtl_gemmini.f').read_text()
assert filelist.count(str(source)) == 1
(build / 'rtl_handshake.f').write_text(filelist.replace(str(source), str(copy)))
print('Experimental RTL copy:', copy)
