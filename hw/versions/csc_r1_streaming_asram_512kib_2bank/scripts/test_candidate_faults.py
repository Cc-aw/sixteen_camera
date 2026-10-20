#!/usr/bin/env python3
"""Inject a real late TL denied/corrupt, reset Gemmini, and replay normally.

Relinks only the test driver against the exact already compiled C1a RTL.
Every real RTL assertion remains enabled. Faults are held stable while stalled.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys

from candidate_rtl import sha, once


def run(build, commands, memory, output, kind):
    manifest = json.loads((build / 'build_manifest.json').read_text())
    for name, digest in manifest['sha256'].items():
        if sha(Path(name)) != digest:
            raise ValueError('Build input changed: ' + name)
    output.mkdir(parents=True, exist_ok=False)
    source = (build / 'csc_gemmini_driver.cpp').read_text()
    source = once(source, 'uint64_t tile_requests=0,tile_skips=0,skip_completions=0;',
                  'uint64_t tile_requests=0,tile_skips=0,skip_completions=0; bool fault_injected=false,fault_active=false,fault_observed=false;')
    source = once(source, 'uint64_t cycle=0;', 'uint64_t cycle=0,reset_until=16;')
    source = once(source, 'd.reset=cycle<16;', 'd.reset=cycle<reset_until;')
    source = once(source, 's.held_data[j]=word;}s.held_valid=true;}', '''s.held_data[j]=word;}s.held_valid=true;
                    s.fault_active=!s.fault_injected && !s.fault_observed && s.tile_skips>0 && r.opcode==1 && r.beats==2 && r.beat==1;
                }
                d.auto_spad_id_out_d_bits_denied=s.fault_active && FAULT_KIND==1;
                d.auto_spad_id_out_d_bits_corrupt=s.fault_active && FAULT_KIND==2;''')
    source = once(source, 'if(d.io_interrupt)throw std::runtime_error("Real Gemmini interrupt");', '''if(d.io_interrupt) {
                    if(!s.fault_injected || s.fault_observed || d.csc_skip)
                        throw std::runtime_error("Unexpected fault or CSC skip after fault");
                    std::cout<<"CSC_REAL_LATE_FAULT_DETECTED kind="<<FAULT_KIND<<" cycle="<<cycle<<" prior_skips="<<s.tile_skips<<std::endl;
                    s.fault_observed=true; s.fault_active=false;
                    reset_until=cycle+16; s.next=0; s.frame=0; s.stage=0;
                    s.sequence=0; s.rows=0; s.gets=0; s.get_bytes=0; s.commits=0; s.reads=0;
                    s.tile_requests=0; s.tile_skips=0; s.skip_completions=0;
                    s.responses.clear(); for(auto &q:s.pending)q.clear();
                    s.write_beat=0; s.held_valid=false; s.metric_live=false; s.metrics.fill(0);
                    gzclose(s.trace);
                    s.trace=gzopen((std::filesystem::path(argv[3])/"recovered_lane0.csv.gz").c_str(),"wb1");
                    if(!s.trace)throw std::runtime_error("Recovery trace open failed");
                    d.reset=1; d.io_cmd_valid=0; d.auto_spad_id_out_d_valid=0; d.eval();
                    all_done=false; continue;
                }''')
    source = once(source, "prefix('D');const auto &r=s.responses.front();", "if(s.fault_active)s.fault_injected=true; prefix('D');const auto &r=s.responses.front();")
    source = once(source, 'if(done){flush_metrics(s,i,cycle+1);', '''if(done){
                if(!s.fault_observed)throw std::runtime_error("Late fault was never exercised");
                std::cout<<"CSC_REAL_RESET_RECOVERY_PASS kind="<<FAULT_KIND<<std::endl;
                flush_metrics(s,i,cycle+1);''')
    driver = output / 'late_fault_driver.cpp'
    driver.write_text(source)
    obj = build / 'obj'
    prefix = Path(sys.executable).resolve().parents[1]
    compiler = shutil.which('x86_64-conda-linux-gnu-c++') or shutil.which('g++')
    objects = [obj / 'VFullGemmini__ALL.a', obj / 'verilated.o', obj / 'verilated_timing.o', obj / 'verilated_threads.o']
    executable = output / 'VFullGemminiLateFault'
    compile_command = [compiler, '-O2', '-std=c++17', '-fcoroutines', f'-DFAULT_KIND={kind}', '-I'+str(obj),
                       '-I'+str(prefix / 'share/verilator/include'), '-I'+str(prefix / 'share/verilator/include/vltstd'),
                       '-I'+str(prefix / 'include'), str(driver), *map(str, objects),
                       '-L'+str(prefix / 'lib'), '-Wl,-rpath,'+str(prefix / 'lib'), '-lz', '-pthread', '-latomic', '-o', str(executable)]
    subprocess.run(compile_command, check=True)
    sources = [Path(__file__).resolve(), driver, executable, commands, build / 'build_manifest.json', *objects]
    sources += sorted(memory.iterdir()) if memory.is_dir() else [memory]
    command = [str(executable), str(commands), str(memory), str(output / 'simulation'),
               '1', '3', '7', '1', '2', '+gemmini_timeout=60000']
    execution = dict(schema=1, late_fault='denied' if kind==1 else 'corrupt',
                     all_rtl_assertions_enabled=True, command=command, compile_command=compile_command,
                     sha256={str(p): sha(p) for p in sources})
    (output / 'execution_manifest.json').write_text(json.dumps(execution, indent=2)+'\n')
    with (output / 'simulation.log').open('w') as log:
        code = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT).returncode
    text = (output / 'simulation.log').read_text()
    passed = code==0 and text.count('CSC_REAL_LATE_FAULT_DETECTED')==1 and text.count('CSC_REAL_RESET_RECOVERY_PASS')==1
    for name, digest in execution['sha256'].items():
        if sha(Path(name)) != digest:
            raise ValueError('Fault test input changed: '+name)
    result = dict(schema=1, status='PASS' if passed else 'FAIL', returncode=code,
                  late_fault_detected='CSC_REAL_LATE_FAULT_DETECTED' in text,
                  reset_recovery='CSC_REAL_RESET_RECOVERY_PASS' in text,
                  numerical_comparison_required=True)
    (output / 'fault_result.json').write_text(json.dumps(result, indent=2)+'\n')
    if not passed:
        raise RuntimeError('Real late fault/reset failed; inspect '+str(output / 'simulation.log'))
    print('CSC_REAL_LATE_FAULT_RESET_PASS', kind)


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path, required=True)
    parser.add_argument('--commands', type=Path, required=True)
    parser.add_argument('--memory', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--kind', choices=('denied','corrupt'), required=True)
    args=parser.parse_args()
    run(args.build.resolve(),args.commands.resolve(),args.memory.resolve(),args.output.resolve(),1 if args.kind=='denied' else 2)
