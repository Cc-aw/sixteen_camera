from prepare_gemmini import root,build,rtl,visit,files,ports,primitive
ps=ports('Gemmini');ip=ports('RegisteredIngressAtomicReserve')
outer=[f'{d} {w} {n}' for d,w,n in ps]+['input diagnostic']
wires=[];gcon=[];icon=[]
for d,w,n in ip:
 if n in ('clock','reset'):target=n
 elif n.startswith('io_in_'):target=n.replace('io_in_','io_cmd_')
 else:
  target='ingress_'+n;wires.append(f'wire {w} {target};')
 icon.append(f'.{n}({target})')
for d,w,n in ps:
 if n=='io_cmd_ready':target='ingress_io_out_ready'
 elif n.startswith('io_cmd_'):target=n.replace('io_cmd_','ingress_io_out_')
 elif n=='io_loopconv_request_accept':target='ingress_io_request_accept'
 elif n=='io_loopconv_request_queue_count':target='ingress_io_request_queue_count'
 elif n=='io_loopconv_assembler_partial':target='ingress_io_assembler_partial'
 else:target=n
 gcon.append(f'.{n}({target})')
# io_in_ready maps to outer io_cmd_ready. Other external observation inputs
# are deliberately unused because real ingress supplies them here.
s='module GemminiIngressTest(\n'+',\n'.join(outer)+'\n);\n'+'\n'.join(wires)+'\n'
s+='RegisteredIngressAtomicReserve ingress('+','.join(icon)+');\nGemmini dut('+','.join(gcon)+');\n'
old=(build/'GemminiTest.sv').read_text();s+=old[old.index('always @(posedge'):]
(build/'GemminiIngressTest.sv').write_text(s)
visit('RegisteredIngressAtomicReserve');(build/'rtl_ingress.f').write_text('\n'.join(map(str,files))+'\n'+primitive+'\n')
cpp=(root/'scripts/sim_loopconv/main_gemmini.cpp').read_text().replace('VGemminiTest','VGemminiIngressTest')
cpp=cpp.replace('// Direct serialized ingress: count one acceptance on launch. LazyRoCC itself\n  // is not instantiated here; each complete seven-command packet is preserved.',
 '// Real RegisteredIngressAtomicReserve supplies acceptance to Gemmini.\n  // The external synthetic acceptance input is unused by this wrapper.')
(build/'main_ingress.cpp').write_text(cpp)
