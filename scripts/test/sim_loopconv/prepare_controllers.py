"""Extend existing RTL liveness fixture with all three real controllers.
Scratchpad data and DMA backing memory remain explicitly modeled.
"""
from prepare import root,build,rtl,wrapper
import re

def ports(name):
 s=(rtl/(name+'.sv')).read_text();s=s[s.index('module '+name+'('):];s=s[:s.index('\n);')]
 s=re.sub(r'//[^\n]*','',s)+'\n'
 return [(d,w or '',n) for d,w,n in re.findall(r'^\s*(input|output)\s*(\[[^]]+\])?\s*(\w+)\s*[,\n]',s,re.M)]
mods={'dut':'LoopConv','rs':'ReservationStation','ld':'LoadController','st':'StoreController','ex':'ExecuteController'}
outer=['input clock','input reset','input diagnostic','input memory_ready']
wires=[];assign=[];instances=[];known={}
for inst,mod in mods.items():
 for d,w,n in ports(mod):
  if n in ('clock','reset'):continue
  sig=inst+'_'+n;known[(inst,n)]=sig
  if inst=='dut' and (n.startswith('io_in_') or n in ['io_busy','io_request_retire','io_running_slot_count']):outer.append(f'{d} {w} {sig}')
  elif inst in ('ld','st') and n.startswith('io_dma_'):outer.append(f'{d} {w} {sig}')
  else:wires.append(f'wire {w} {sig};')

def connect(inst,n,expr):assign.append(f'assign {inst}_{n} = {expr};')
for inst,mod in mods.items():
 for d,w,n in ports(mod):
  if d!='input' or n in ('clock','reset'):continue
  if inst=='dut':
   if n.startswith('io_in_'):continue
   if n=='io_out_ready':v='rs_io_alloc_ready'
   elif n in ['io_ld_completed','io_st_completed','io_ex_completed']:v='rs_'+n.replace('io_','io_conv_',1)
   else:raise ValueError(n)
  elif inst=='rs':
   if n=='io_alloc_valid':v='dut_io_out_valid'
   elif n.startswith('io_alloc_bits_'):
    v=known.get(('dut',n.replace('io_alloc_bits_','io_out_bits_')), "'0")
   elif n=='io_completed_valid':v='ex_io_completed_valid | ld_io_completed_valid | st_io_completed_valid'
   elif n=='io_completed_bits':v='ex_io_completed_valid ? ex_io_completed_bits : ld_io_completed_valid ? ld_io_completed_bits : st_io_completed_bits'
   elif n.startswith('io_issue_') and n.endswith('_ready'):v=n.split('_')[2]+'_io_cmd_ready'
   else:v="'0"
  else:
   if n.startswith('io_dma_'):continue
   if n=='io_cmd_valid':v=f'rs_io_issue_{inst}_valid'
   elif n=='io_cmd_bits_rob_id_bits':v=f'rs_io_issue_{inst}_rob_id'
   elif n=='io_cmd_bits_rob_id_valid':v="1'b1"
   elif n.startswith('io_cmd_bits_'):v=known.get(('rs',n.replace('io_cmd_bits_',f'io_issue_{inst}_cmd_')), "'0")
   elif n=='io_completed_ready':v='!ex_io_completed_valid'+(' && !ld_io_completed_valid' if inst=='st' else '')
   elif n in ('io_silu_lut_ready','io_writeback_idle'):v="1'b1"
   elif n.endswith('_ready'):v='memory_ready'
   elif re.match(r'io_srams_read_\d+_resp_valid',n) or re.match(r'io_acc_read_resp_\d+_valid',n):continue
   else:v="'0"
  connect(inst,n,v)
 for bank in (range(8) if inst=='ex' else []):
  req=f'io_srams_read_{bank}_req';resp=f'io_srams_read_{bank}_resp'
  # Override the generated always-ready expression with an elastic one-entry response.
  assign.remove(f'assign ex_{req}_ready = memory_ready;')
  wires.append(f'reg sram_pending_{bank};')
  connect('ex',req+'_ready',f'memory_ready && (!sram_pending_{bank} || ex_{resp}_ready)')
  connect('ex',resp+'_valid',f'sram_pending_{bank}')
  assign.append(f'always @(posedge clock) if(reset) sram_pending_{bank} <= 0; else if(ex_{req}_ready) sram_pending_{bank} <= ex_{req}_valid; else if(ex_{resp}_ready) sram_pending_{bank} <= 0;')
 for bank in (range(4) if inst=='ex' else []):
  req=f'io_acc_read_req_{bank}';resp=f'io_acc_read_resp_{bank}'
  assign.remove(f'assign ex_{req}_ready = memory_ready;')
  wires.append(f'reg acc_pending_{bank};')
  connect('ex',req+'_ready',f'memory_ready && (!acc_pending_{bank} || ex_{resp}_ready)')
  connect('ex',resp+'_valid',f'acc_pending_{bank}')
  assign.append(f'always @(posedge clock) if(reset) acc_pending_{bank} <= 0; else if(ex_{req}_ready) acc_pending_{bank} <= ex_{req}_valid; else if(ex_{resp}_ready) acc_pending_{bank} <= 0;')
 conns=[f'.{n}({n if n in ("clock","reset") else inst+"_"+n})' for d,w,n in ports(mod)]
 instances.append(mod+' '+inst+'('+','.join(conns)+');')
outer.append('output backend_busy');assign.append('assign backend_busy = rs_io_busy | ld_io_busy | st_io_busy | ex_io_busy;')
diagnostic=wrapper[wrapper.index('always @(posedge'):].replace('endmodule','')
for inst,mod in [('ld','LoadController'),('st','StoreController'),('ex','ExecuteController')]:
 s=(rtl/(mod+'.sv')).read_text();fields=re.findall(r'^\s*reg\s+(?:\[[^]]+\]\s+)?(\w+)\s*;',s,re.M)
 selected=[n for n in fields if any(k in n for k in ['control_state','row_counter','state','in_prop_flush'])][:10]
 diagnostic+='always @(posedge clock) if(diagnostic) begin\n'
 for field in selected:diagnostic+=f'$display("CTRL {inst}.{field}=%0h",{inst}.{field});\n'
 diagnostic+='end\n'
text='module LoopConvControllersTest(\n'+',\n'.join(outer)+'\n);\n'+'\n'.join(wires+assign+instances)+'\n'+diagnostic+'endmodule\n'
(build/'LoopConvControllersTest.sv').write_text(text)
# Resolve actual instance dependencies, including parameterized blackboxes/memory.
seen=set();files=[]
mem=next(rtl.glob('*.top.mems.v'))
memmods=set(re.findall(r'module\s+(\w+)\s*\(',mem.read_text()))
def visit(n):
 if n in seen:return
 seen.add(n)
 p=rtl/(n+'.sv')
 if not p.exists():p=rtl/(n+'.v')
 if not p.exists():
  if n in memmods:
   if mem not in files:files.append(mem)
   return
  raise ValueError('Missing dependency '+n)
 files.append(p)
 for typ in re.findall(r'^\s*(\w+)\s+(?:#\s*\([\s\S]*?\)\s*)?\w+\s*\(',p.read_text(),re.M):
  if typ in ('module','if','else','for','while','case','end','assign'):continue
  if (rtl/(typ+'.sv')).exists() or (rtl/(typ+'.v')).exists() or typ in memmods:visit(typ)
for n in mods.values():visit(n)
(build/'rtl_controllers.f').write_text('\n'.join(map(str,files))+'\n')
print('CONTROLLER_RTL_FILES',len(files))
