#!/usr/bin/env python3
"""Verify concrete candidate evidence before permitting a full private build."""
import argparse
import importlib.util
import json
from pathlib import Path
import re
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/soc'))
from dma_load_candidate import validate, sha, closure


def integration(context_path, directories):
    context,rtl=validate(context_path)
    hashes={}
    def record(path):
        path=Path(path).resolve();hashes[str(path)]=sha(path)
        return path
    def checked_json(path):
        return json.loads(record(path).read_text())
    expectations={
        'first':('rtl_evidence.json','COMPACT_REAL_DIM32_RTL_PASS','DMA_LOAD_REAL_RUNTIME_PASS'),
        'layers':('evidence.json','REPRESENTATIVE_LAYERS_PASS','REAL_CLUSTER_PASS,DMA_LAYERS=8'),
        'spad':('evidence.json','REAL_SPAD_RAW_POISON_PASS','REAL_CLUSTER_PASS,DMA_SPAD=1'),
        'fault':('evidence.json','REAL_FAULT_RECOVERY_PASS','REAL_CLUSTER_PASS,DMA_FAULT=1'),
        'memory':('evidence.json','MEMORY_MUX_WIDTH_LEASE_PASS','MEMORY_MUX_PASS,addr_bits=33,source_ids=64,sink_bits=7,'),
    }
    required=set(closure(rtl,['Gemmini','CommandFrontendCluster','CommandFrontendMemoryMux']))
    for name,directory in directories.items():
        directory=Path(directory).resolve()
        evidence_name,status,marker=expectations[name]
        evidence=checked_json(directory/evidence_name)
        if evidence['status']!=status or name!='first' and evidence['build_id']!=context['dma_load_build_id']:
            raise ValueError('Wrong candidate evidence: '+name)
        log=record(directory/'result.log').read_text()
        if marker not in log or re.search(r'Fatal:|Error:|Assertion failed:',log):
            raise ValueError('Failed/incomplete simulation: '+name)
        if evidence.get('log_sha256')!=sha(directory/'result.log'):
            if name!='spad':raise ValueError('Simulation result changed: '+name)
        if name=='memory':
            path=record(directory/'wrapper.sv');record(directory/'tb.sv')
            source=record(rtl/'CommandFrontendMemoryMux.sv')
            if evidence['rtl']!=str(source) or evidence['rtl_sha256']!=sha(source):
                raise ValueError('Memory lease test used a different mux')
            continue
        prj=record(directory/'simulation.prj').read_text()
        files={Path(p).resolve() for p in re.findall(r'^sv work "([^"]+)"$',prj,re.M)}
        if not required<=files:
            raise ValueError('Simulation omitted candidate RTL: '+name)
        if any(p not in files for p in required):
            raise ValueError('Candidate source closure mismatch')
        for path in files:record(path)
        for path in directory.glob('*.sv'):record(path)
        record(directory/'run.py')
        if name=='first':
            if evidence.get('runtime_modes')!='all' or evidence.get('candidate_rtl')!=str(rtl):
                raise ValueError('First layer did not use all modes of this candidate')
            for path,expected in evidence['rtl_sha256'].items():
                if sha(Path(path))!=expected:raise ValueError('First-layer source changed')
            if log.count('DMA_LOAD_REAL_MODE_PASS,')!=3 or log.count('S2D_RTL_LANE_PASS,')!=9:
                raise ValueError('Missing first-layer modes/lanes')
        elif name=='layers':
            trace=checked_json(directory/'trace_evidence.json')
            if trace['status']!='ROW_TRACE_GET_CLOSURE_PASS' or len(trace['results'])!=72:
                raise ValueError('Incomplete row/Get closure')
            for path,expected in trace['sha256'].items():
                if sha(record(path))!=expected:raise ValueError('Trace evidence changed')
        elif name=='spad':
            if evidence['parameter_cases']!=6 or log.count('DMA_SPAD_PASS,')!=54:
                raise ValueError('Incomplete parameterized SRAM/RAW/poison matrix')
        else:
            if log.count('DMA_FAULT_HOLD_PASS,')!=2 or log.count('DMA_FAULT_RECOVERY_PASS,')!=2:
                raise ValueError('Incomplete denied/corrupt/reset matrix')
    if set(directories)!=set(expectations):raise ValueError('Missing integration suites')
    record(context_path)
    validate(context_path)
    return dict(status='CANDIDATE_INTEGRATION_PASS',build_id=context['dma_load_build_id'],sha256=hashes)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--context',type=Path,required=True)
    p.add_argument('--units',type=Path,required=True)
    for name in ('first','layers','spad','fault','memory','ooc'):
        p.add_argument('--'+name,type=Path,required=True)
    p.add_argument('--firmware',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    args=p.parse_args()
    context,rtl=validate(args.context)
    report=integration(args.context,{k:getattr(args,k) for k in ('first','layers','spad','fault','memory')})
    hashes=report['sha256']
    def record(path):
        path=Path(path).resolve();hashes[str(path)]=sha(path)
        return path
    unit=json.loads(record(args.units/'unit_evidence.json').read_text())
    if unit['status']!='SOURCE_UNIT_PASS':raise ValueError('Unit tests did not pass')
    jar=record(Path(unit['workspace'])/'.classpath_cache/chipyard_fpga.jar')
    if sha(jar)!=unit['classpath_jar_sha256']:raise ValueError('Unit classpath changed')
    for path,expected in unit['source_sha256'].items():
        if sha(record(ROOT/path))!=expected:raise ValueError('Unit source changed')
    for name in ('unit.log','reader.log'):
        log=record(args.units/name).read_text()
        if 'Assertion failed:' in log or 'PASS' not in log:raise ValueError('Invalid source unit log')
        markers=('PLANNER','ASSEMBLER','GROUP','BANK_QUEUE','COUNTER_ABI','CONTROL') if name=='unit.log' else ('READER',)
        if any('DMA_LOAD_'+marker+'_PASS,' not in log for marker in markers):
            raise ValueError('Incomplete source unit coverage')
    timing=json.loads(record(args.ooc/'evidence.json').read_text())
    if timing['status']!='OOC_PASS' or timing['build_id']!=context['dma_load_build_id']:
        raise ValueError('Wrong OOC evidence')
    if {r['top'] for r in timing['results']}!={'DmaLoadGroup','DmaLoadRowAssembler','StreamReader'}:
        raise ValueError('Missing OOC modules')
    for result in timing['results']:
        if min(result['wns_ns'],result['whs_ns'],result['wpws_ns'])<0:raise ValueError('OOC timing violation')
        for path,expected in result['rtl_sha256'].items():
            if sha(record(path))!=expected:raise ValueError('OOC RTL changed')
        path=record(args.ooc/result['top']/'timing.rpt')
        if sha(path)!=result['timing_report_sha256']:raise ValueError('OOC timing report changed')
    firmware=json.loads(record(args.firmware).read_text())
    if (firmware.get('status')!='ELF_AUDIT_PASS' or firmware.get('build_id')!=context['dma_load_build_id'] or
            firmware.get('l2_kib')!=512 or firmware.get('l2_banks')!=2):
        raise ValueError('Wrong firmware identity')
    # The diagnostic manifest owns every ELF, disassembly and source hash.
    for field in ('sha256','files'):
        if field in firmware:
            for path,value in firmware[field].items():
                expected=value['sha256'] if isinstance(value,dict) else value
                if sha(record(path))!=expected:raise ValueError('Firmware input changed')
    for name in ('yolov5_dma_load_first.elf','yolov5_dma_load_model.elf'):
        record(args.firmware.parent/name)
    report.update(status='READY_FOR_BITSTREAM',full_chip_timing_proven=False,board_run='NOT_RUN',
                  scope='source units, candidate real RTL modes/layers/poison/RAW/fault, OOC, audited diagnostic ELFs')
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,indent=2)+'\n')
    print('DMA_LOAD_READY_FOR_BITSTREAM build_id='+context['dma_load_build_id'])


if __name__=='__main__':main()
