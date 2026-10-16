#!/usr/bin/env python3
"""Validate a complete finite SW-P3 UART suite and compare same-hardware runs."""
import argparse
from collections import defaultdict
import json
from pathlib import Path
import re


class InvalidLog(ValueError):
    pass


def parse(text,manifest=None):
    runs={};frames=defaultdict(list);metrics={};profiles={};identities=[];complete=0;builds=0;profile_count=4
    def fail(reason):raise InvalidLog(reason)
    for line in text.splitlines():
        line=line.strip()
        if ',FAIL,' in line or ',TRAP,' in line:fail('firmware failure')
        if not line.startswith('SWP3,'):continue
        parts=line.split(',');event=parts[1];f=dict(p.split('=',1) for p in parts[2:] if '=' in p)
        if event=='BUILD':
            builds+=1
            if f.get('schema')!='1' or f.get('passes')!='2' or f.get('profiles') not in ('1','4') or f.get('frames')!='12':fail('build schema')
            profile_count=int(f['profiles'])
        elif event=='IDENTITY':identities.append(f)
        elif event=='PROFILE':
            key=int(f['pass']),int(f['id'])
            if key in profiles:fail('duplicate profile')
            profiles[key]=f
        elif event in ('RUN','FRAME'):
            try:key=tuple(int(f[n]) for n in ('pass','profile','mode','serial_lane','matched'))
            except (KeyError,ValueError):fail('run identity')
            if event=='RUN':
                if key in runs:fail('duplicate run')
                if f.get('result40')!='PASS' or f.get('cache')!='warm_order_controlled':fail('result/cache policy')
                for n in ('cycles','frames','run_id','host_calls','launches','device0_frames','device1_frames','device2_frames'):
                    try:f[n]=int(f[n])
                    except (KeyError,ValueError):fail('missing run fields')
                if f['cycles']<=0 or f['frames']!=12 or f['host_calls']!=144:fail('incomplete workload')
                if f['launches']!=(0 if key[2]==0 else 12):fail('launches')
                expected=[4,4,4] if key[2]==2 or key[4] else [12 if d==key[3] else 0 for d in range(3)]
                if [f['device'+str(d)+'_frames'] for d in range(3)]!=expected:fail('lane quota')
                runs[key]=f
            else:
                try:frames[key].append({n:int(f[n]) for n in ('frame','lane','image','begin','end')})
                except (KeyError,ValueError):fail('frame fields')
        elif event=='METRIC':
            try:k=int(f['pass']),int(f['profile'])
            except (KeyError,ValueError):fail('metric identity')
            if k in metrics:fail('duplicate metric')
            metrics[k]=f
        elif event=='PASS':
            complete+=1
            if f.get('marker')!='ALL_COMPLETE' or f.get('result40')!='bit_exact':fail('completion')
    if builds!=1 or complete!=1 or len(identities)!=1:fail('missing/duplicate complete suite')
    if not {'input_sha256','model_sha256','plan_sha256','reference_plan_sha256','layout_sha256','frozen_lock_sha256'}<=identities[0].keys():fail('incomplete artifact identity')
    if set(profiles)!={(p,i) for p in range(2) for i in range(profile_count)}:fail('profile coverage')
    for (p,i),profile in profiles.items():
        expected_name=['reference','layout','cache_plan','cache_plan_gate'][i]
        expected_plan=identities[0].get('plan_sha256' if i>=2 else 'reference_plan_sha256')
        if profile.get('name')!=expected_name or profile.get('plan_hash')!=expected_plan:fail('profile plan identity')
    if manifest and identities[0]!=manifest:fail('input/model/plan identity mismatch')
    expected={(p,profile,*mode) for p in range(2) for profile in range(profile_count)
              for mode in [(0,0,0),(1,0,0),(2,0,0),(1,1,0),(1,2,0),(1,0,1)]}
    if set(runs)!=expected or set(metrics)!={(p,i) for p in range(2) for i in range(profile_count)}:fail('missing/extra runs')
    last_id=0
    # File insertion order is execution order: forward/reverse profile passes.
    order=[(p,profile) for p in range(2) for profile in (range(profile_count) if p==0 else reversed(range(profile_count)))]
    if [(k[0],k[1]) for k in runs if k[2:]==(0,0,0)]!=order:fail('profile order')
    for k,r in runs.items():
        if r['run_id']!=last_id+12:fail('reused/nonmonotonic frame version')
        last_id=r['run_id'];fs=frames[k]
        if len(fs)!=12 or {f['frame'] for f in fs}!=set(range(12)):fail('frame coverage')
        by_lane=defaultdict(list)
        for f in fs:
            if f['lane'] not in range(3) or f['image']!=f['frame']%3:fail('frame mapping')
            if not 0<=f['begin']<f['end']<=r['cycles']:fail('timing window')
            by_lane[f['lane']].append(f)
        for lane,ff in by_lane.items():
            ff.sort(key=lambda f:f['begin'])
            if any(a['end']>b['begin'] for a,b in zip(ff,ff[1:])):fail('lane overlap')
        for d in range(3):
            if len(by_lane[d])!=r['device'+str(d)+'_frames']:fail('frame/lane count')
        if k[4]:
            parallel={f['frame']:f['lane'] for f in frames[k[0],k[1],2,0,0]}
            if any(f['lane']!=parallel[f['frame']] for f in fs):fail('matched replay mapping')
            ff=sorted(fs,key=lambda f:f['begin'])
            if any(a['end']>b['begin'] for a,b in zip(ff,ff[1:])):fail('matched replay not serial')
    summary=[]
    for p,i in order:
        serial=runs[p,i,1,0,0]['cycles'];parallel=runs[p,i,2,0,0]['cycles']
        m=metrics[p,i]
        if int(m['serial'])!=serial or int(m['parallel'])!=parallel:fail('metric totals')
        if int(m['scaling_x1000'])!=serial*1000//parallel or int(m['efficiency_x1000'])!=serial*1000//(3*parallel):fail('metric ratios')
        summary.append(dict(pass_id=p,profile=i,Tserial=serial,Tparallel=parallel,
            Sfrontend=serial/parallel,efficiency=serial/parallel/3,
            absolute_gain=runs[p,0,2,0,0]['cycles']/parallel,
            matched_serial=runs[p,i,1,0,1]['cycles'],
            per_lane_serial=[runs[p,i,1,d,0]['cycles'] for d in range(3)]))
    return dict(schema=1,workload='12 complete frames per run',runs=len(runs),frames=12*len(runs),
                hardware_identity='download manifest declared; requires suite manifest',identity=identities[0],
                results=summary,performance_status='MEASURED_NOT_PROMOTED',
                selection='No automatic promotion from two order-controlled passes; inspect noise/repeatability')


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('log',type=Path)
    p.add_argument('--identity',type=Path);p.add_argument('--json',type=Path)
    a=p.parse_args();result=parse(a.log.read_text(),json.loads(a.identity.read_text()) if a.identity else None)
    text=json.dumps(result,indent=2)+'\n'
    if a.json:a.json.write_text(text)
    print(text,end='')

if __name__=='__main__':main()
