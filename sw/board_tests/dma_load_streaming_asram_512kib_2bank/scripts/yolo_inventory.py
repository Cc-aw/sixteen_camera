#!/usr/bin/env python3
"""Export native plan address anchors and exact HOST/DMA spans where decoded."""
import json
from pathlib import Path
import re

from build import ROOT, BUILD, sha, write

ARENA = 2217600


def region(address):
    if not address: return dict(region='null',offset=0)
    if address>>63:
        group=(address>>40)&0x7fffff
        return dict(region=('arena','conv_input_scratch','conv_output_scratch','memory_pad',
                            'memory_intermediate','head')[group],offset=address&((1<<40)-1))
    if address>>62: return dict(region='input',offset=address&((1<<62)-1))
    if address>>61: return dict(region='constant',constant=(address>>40)&0x1fffff,
                              offset=address&((1<<40)-1))
    raise ValueError('Unnormalized address')


def main():
    plan=BUILD/'ddr_plan.txt';lines=plan.read_text().splitlines()
    if not all((BUILD/name).read_bytes()==plan.read_bytes() for name in
               ('local_plan.txt','native_ddr_plan.txt','native_local_plan.txt')):
        raise ValueError('DDR/local/native plans differ')
    phases=dict(tuple(map(int,line.split())) for line in plan.with_suffix('.txt.stages').read_text().splitlines())
    tensor_symbols={name:int(offset) for name,offset in re.findall(
        r'^#define (tensor_\d+) \(activation_arena \+ (\d+)\)',
        (ROOT/'model/parallel_model.inc').read_text(),re.M)}
    accesses=[];commands=0;hosts=[];load_stride=[0]*3;load_shrunk=[False]*3;store_stride=0
    store_config=0
    for line in lines:
        if line.startswith('host '):
            f=line.split();kind,stage,head,h,w,c=map(int,f[1:7])
            if kind==1:
                src,dst=map(lambda x:int(x,16),f[7:9])
                for role,addr,size in (('read',src,h*w*c),('write',dst,(h+2)*(w+2)*c)):
                    item=dict(producer='cpu_rvv',phase=stage,role=role,bytes=size,span='exact',**region(addr))
                    if item['region']=='arena' and item['offset']+size>ARENA:raise ValueError('HOST exceeds arena')
                    accesses.append(item)
                hosts.append(dict(phase=stage,src=region(src),dst=region(dst),source_bytes=h*w*c,
                                  destination_bytes=(h+2)*(w+2)*c))
            continue
        control,a,b,_=map(lambda x:int(x,16),line.split());index=commands;commands+=1
        if control&255:continue
        funct=control>>8;span=None
        if funct==0:
            if a&3==1:load_stride[(a>>3)&3]=b;load_shrunk[(a>>3)&3]=bool(a&4)
            if a&3==2:store_stride=b&0xffffffff;store_config=a
        roles=[]
        if funct in (20,21,10,11):
            roles=[('rs1','read',a),('rs2','write' if funct in (20,11) else 'read',b)]
        elif funct in (1,2,3,14):
            roles=[('rs1','write' if funct==3 else 'read',a)]
            rows=(b>>48)&65535;cols=(b>>32)&65535
            if funct!=3:
                stream={2:0,1:1,14:2}[funct]
                element_bytes=4 if b&0x80000000 and not load_shrunk[stream] else 1
                span=(rows-1)*load_stride[stream]+cols*element_bytes if rows else None
            elif rows:span=(rows-1)*store_stride+cols
            elif (store_config>>5)&3:
                porows=(store_config>>32)&255;pool_out=(store_config>>24)&255
                pocols=(store_config>>40)&255
                span=((porows-1)*pool_out+pocols-1)*store_stride+cols
        for operand,role,address in roles:
            item=dict(producer='gemmini',index=index,phase=phases[index],funct=funct,
                      operand=operand,role=role,bytes=span,
                      span='exact_stride_envelope' if span is not None else 'unknown_loop_footprint',**region(address))
            if item['region']=='null':continue
            if item['region']=='arena':
                if item['offset']>=ARENA or (span is not None and item['offset']+span>ARENA):
                    raise ValueError('Native DMA exceeds arena: '+str(item))
                item['logical_tensor_aliases']=[name for name,off in tensor_symbols.items() if off==item['offset']]
            accesses.append(item)
    write(BUILD/'activation_access_inventory.json',dict(schema=1,scope='one native lane/slot/image; all 18 normalized tables equal',
        command_count=commands,normalized_plan_sha256=sha(plan),arena_bytes=ARENA,
        tensor_offsets=tensor_symbols,pad_hosts=hosts,accesses=accesses,
        unknown_spans=sum(a['bytes'] is None for a in accesses),
        limitations='LoopConv/LoopWS address anchors are recorded; their aggregate DMA footprints are not expanded. '
                    'No cycle-level trace or exact DDR savings is claimed. Local physical tail is guarded on board.'))
    print('YOLO_ACCESS_INVENTORY=PASS commands='+str(commands)+' pad_hosts='+str(len(hosts)))


if __name__=='__main__':main()
