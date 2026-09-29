from prepare_controllers import ports,root,build,rtl,visit,files,wrapper
import re
from trace_gemmini import trace_logic
name='Gemmini'
ps=ports(name)
outer=[f'{d} {w} {n}' for d,w,n in ps]+['input diagnostic']
conns=[f'.{n}({n})' for d,w,n in ps]
s='module GemminiTest(\n'+',\n'.join(outer)+'\n);\nGemmini dut('+','.join(conns)+');\n'
s+=wrapper[wrapper.index('always @(posedge'):].replace('endmodule','').replace('dut.', 'dut.mod.')
s+='always @(posedge clock) if(diagnostic) begin\n'
for inst in ['load_controller','store_controller','ex_controller']:
 mod={'load_controller':'LoadController','store_controller':'StoreController','ex_controller':'ExecuteController'}[inst]
 text=(rtl/(mod+'.sv')).read_text()
 for field in re.findall(r'^\s*reg\s+(?:\[[^]]+\]\s+)?(\w+)\s*;',text,re.M):
  if field in ['control_state','row_counter','a_row_counter','b_row_counter','d_row_counter','in_prop_flush']:
   s+=f'$display("CTRL {inst}.{field}=%0h",dut.{inst}.{field});\n'
s+='end\n'+trace_logic()+'endmodule\n';(build/'GemminiTest.sv').write_text(s)
visit('Gemmini');(build/'rtl_gemmini.f').write_text('\n'.join(map(str,files))+'\n')
for h in [16,480]:
 prefix='7 0 0\n'
 for base in range(0,256,8):
  packed=sum((int((i if i<128 else i-256)/2)&255)<<(8*(i-base)) for i in range(base,base+8))
  prefix+=f'26 {base:016x} {packed:016x}\n'
 (build/f'commands_gemmini_{h}.txt').write_text(prefix+(build/f'commands_{h}.txt').read_text())
print('GEMMINI_RTL_FILES',len(files))
# Vivado functional/formal primitive model; no device timing in this RTL run.
primitive='/mnt/data/Vivado/Vivado/2023.2/data/verilog/src/xeclib/RAMB36E2.v'
with (build/'rtl_gemmini.f').open('a') as f:f.write(primitive+'\n')
