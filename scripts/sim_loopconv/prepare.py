from pathlib import Path
import re,subprocess
root=Path(__file__).resolve().parents[2]
build=root/'build/sim_loopconv';build.mkdir(parents=True,exist_ok=True)
rtl=next((root/'generated/soc').glob('*TaihangSoC1Rocket1RVV3Gemmini64x64PackedInference100MHzConfig/gen-collateral'))
abi=root/'soc_shell/npu100_video/software/gemmini-rocc-tests'
stub=build/'rocc-software/src';stub.mkdir(parents=True,exist_ok=True)
(stub/'xcustom.h').write_text('''#define STR1(x) #x
#define STR(x) STR1(x)
#define ROCC_INSTRUCTION_0_R_R(x,a,b,f) { capture(f,(uint64_t)(a),(uint64_t)(b)); }
#define ROCC_INSTRUCTION(x,r,a,b,f) { (r)=0; }
''')
params=next((rtl/'include').glob('*custom3*.h'))
subprocess.run(['gcc','-O2','-I'+str(build),'-I'+str(abi),'-include',str(params),str(root/'scripts/sim_loopconv/capture.c'),'-lm','-o',str(build/'capture')],check=True)
for h in (16,480):
 with (build/f'commands_{h}.txt').open('w') as f: subprocess.run([str(build/'capture'),str(h)],stdout=f,check=True)
 print('CAPTURE',h,'tasks',sum(l.startswith('15 ') for l in (build/f'commands_{h}.txt').read_text().splitlines()))
seen=set()
def visit(name):
 if name in seen:return
 p=rtl/(name+'.sv')
 if not p.exists():raise RuntimeError(name)
 seen.add(name)
 for typ,inst in re.findall(r'^\s*(\w+)\s+(\w+)\s*\(',p.read_text(),re.M):
  if (rtl/(typ+'.sv')).exists():visit(typ)
visit('LoopConv')
(build/'rtl.f').write_text('\n'.join(str(rtl/(n+'.sv')) for n in sorted(seen))+'\n')
print('RTL_MODULES',len(seen))
sv=(rtl/'LoopConv.sv').read_text(); ports=sv[sv.index('module LoopConv(')+len('module LoopConv('):sv.index('\n);',sv.index('module LoopConv('))]
# Keep the exact generated interface and observe internal state without modifying RTL.
ports=ports.split('\n',1)[1]
ports=re.sub(r'//[^\n]*','',ports).rstrip()
wrapper='module LoopConvTest(\n'+ports+',\n input diagnostic\n);\nLoopConv dut(.*);\nalways @(posedge clock) if(diagnostic) begin\n'
for name,expr in [('head','dut.head_loop_id'),('ld_util','dut.ld_utilization'),('ex_util','dut.ex_utilization'),('st_util','dut.st_utilization')]: wrapper+=f'$display("STATE {name}=%0d", {expr});\n'
for slot in range(2):
 for field in ['running','ld_bias_completed','ld_input_completed','ld_weights_completed','ex_completed','st_completed']:
  wrapper+=f'$display("STATE slot{slot}_{field}=%0d", dut.loops_{slot}_{field});\n'
for inst in ['ld_bias','ld_input','ld_weights','ex','st']:
 for field in ['state','io_idle','io_cmd_valid','io_cmd_ready','io_rob_overloaded']:
  wrapper+=f'$display("STATE {inst}_{field}=%0d", dut.{inst}.{field});\n'
wrapper+='end\nendmodule\n';(build/'LoopConvTest.sv').write_text(wrapper)
# Second wrapper includes the real reservation station and exposes only controller
# issue/complete handshakes to the latency model.
def ports_of(name):
 text=(rtl/(name+'.sv')).read_text(); text=text[text.index('module '+name+'('):];text=text[:text.index('\n);')]
 return re.findall(r'^\s*(input|output)\s*(\[[^]]+\])?\s*(\w+)\s*[,\n]',text,re.M)
lc=ports_of('LoopConv'); rs=ports_of('ReservationStation')
outer=[]; wires=[]; lc_conn=[]; rs_conn=[]
for direction,width,name in lc:
 width=width or ''
 if name in ('io_out_ready','io_ld_completed','io_st_completed','io_ex_completed'):
  wires.append(f'wire {width} {name};')
 else:outer.append(f'{direction} {width} {name}')
 lc_conn.append(f'.{name}({name})')
for direction,width,name in rs:
 width=width or ''; target=''
 if name in ('clock','reset'):target=name
 elif name=='io_alloc_ready':target='io_out_ready'
 elif name=='io_alloc_valid':target='io_out_valid'
 elif name.startswith('io_alloc_bits_'):
  target=name.replace('io_alloc_bits_','io_out_bits_')
  if target not in {p[2] for p in lc}:target="'0"
 elif name.startswith('io_conv_'):
  target=name.replace('io_conv_','io_')
  wires.append(f"wire [1:0] rs_{name}; assign {target} = {{5'b0, rs_{name}}};")
  target='rs_'+name
 elif name.startswith('io_issue_') or name.startswith('io_completed_') or name=='io_busy':
  target='rs_'+name;outer.append(f'{direction} {width} {target}')
 elif direction=='input':target="'0"
 rs_conn.append(f'.{name}({target})')
text='module LoopConvRSTest(\n'+',\n'.join(outer+['input diagnostic'])+'\n);\n'+'\n'.join(wires)+'\n'
text+='LoopConv dut('+','.join(lc_conn)+');\nReservationStation rs('+','.join(rs_conn)+');\n'
text+=wrapper[wrapper.index('always @(posedge'):]
(build/'LoopConvRSTest.sv').write_text(text)
visit('ReservationStation');(build/'rtl_rs.f').write_text('\n'.join(str(rtl/(n+'.sv')) for n in sorted(seen))+'\n')
with (build/'rtl_rs.f').open('a') as f:f.write(str(rtl/'plusarg_reader.v')+'\n')
