"""Logical command address/extent analysis; these are NOT measured DDR bytes."""
from collections import defaultdict
from pathlib import Path
import argparse
import hashlib
import json

NULL = 0xffffffff


def union_bytes(intervals):
    end = total = 0
    for begin, stop in sorted(intervals):
        if stop < begin or begin < 0:
            raise ValueError('invalid logical address extent')
        total += max(0, stop-max(begin,end))
        end = max(end,stop)
    return total


def matrix(offset, rows, columns, stride, width=1):
    if min(offset,rows,columns,stride,width)<0:
        raise ValueError('negative matrix extent')
    if not rows or not columns: return []
    if not stride: rows=1  # bias broadcast; one row is described.
    return [(offset+r*stride*width,offset+(r*stride+columns)*width) for r in range(rows)]


def analyze(manifest):
    results={}
    for stage, plan in manifest['fixed_packets'].items():
        requests=defaultdict(list)
        for packet in plan['tiles']:
            g=packet['geometry']; flags, mode=packet['launch']; offsets=packet['offsets']
            batches=(g[1]>>48)&65535; porows=(g[1]>>32)&65535
            pocols=(g[1]>>16)&65535; pochs=g[1]&65535
            krows=(g[2]>>48)&65535; kcols=(g[2]>>32)&65535; kchs=(g[2]>>16)&65535
            orows=(g[4]>>48)&65535; ocols=g[5]&65535; dilation=g[4]&1023
            in_stride=(g[5]>>48)&65535; weight_stride=(g[5]>>32)&65535; out_stride=(g[5]>>16)&65535
            kernel=(g[0]>>48)&65535; in_cols=g[3]&65535
            in_rows=(plan['config'][4]>>16)&65535; in_channels=(plan['config'][4]>>32)&65535
            out_channels=(plan['config'][4]>>48)&65535; stride=(plan['config'][5]>>48)&255
            out_cols=(g[0]>>32)&65535
            rows=orows*stride+(krows-1)*dilation-((g[3]>>32)&65535)-((g[3]>>24)&255)
            cols=ocols*stride+(kcols-1)*dilation-(g[2]&65535)-((g[3]>>48)&65535)
            supported=not (flags&0x7e or mode&6)  # transposes, DW, input dilation/downsample.
            input_ranges=weight_ranges=output_ranges=None
            if supported:
                input_ranges=[]
                if rows<0 or cols<0: raise ValueError('negative Conv logical input window')
                for batch in range(batches):
                    for row in range(rows):
                        base=offsets[3]+((batch*in_rows+row)*in_cols)*in_stride
                        if kchs==in_stride: input_ranges.append((base,base+cols*kchs))
                        else: input_ranges.extend(matrix(base,cols,kchs,in_stride))
                weight_ranges=[]
                for row in range(krows):
                    for col in range(kcols):
                        base=offsets[0]+(row*kernel+col)*in_channels*weight_stride
                        weight_ranges.extend(matrix(base,kchs,pochs,weight_stride))
                output_ranges=[]
                for batch in range(batches):
                    for row in range(porows):
                        base=offsets[1]+((batch*((plan['config'][5]>>16)&65535)+row)*out_cols)*out_stride
                        if pochs==out_stride: output_ranges.append((base,base+pocols*pochs))
                        else: output_ranges.extend(matrix(base,pocols,pochs,out_stride))
            for name,index,ranges in (('input',3,input_ranges),('weight',0,weight_ranges),('output',1,output_ranges)):
                identity=(offsets[index],tuple(g),tuple(packet['launch']))
                requests[name].append((index,offsets[index],name,identity,ranges))
        results[stage]=summarize('conv',len(plan['tiles']),requests)
    for stage, plan in manifest['prepared_ws'].items():
        requests=defaultdict(list)
        for kind,index in plan['steps']:
            if kind!=1: continue
            packet=manifest['prepared_ws_packets'][index]
            pad, bound=packet['bounds']; flags, mode=packet['launch']
            i=(bound&65535)*32-(pad&65535)
            j=((bound>>16)&65535)*32-((pad>>16)&65535)
            k=((bound>>32)&65535)*32-((pad>>32)&65535)
            resadd=bool(mode&4)
            a=(i,j) if resadd else ((k,i) if mode&1 else (i,k))
            b=(i,j) if resadd else ((j,k) if mode&2 else (k,j))
            dims=(a,b,(i,j),(i,j)); widths=(1,1,1 if flags&4 else 4,4 if flags&2 else 1)
            for operand in range(4):
                role=packet['roles'][operand]; offset=packet['offsets'][operand]
                null=role==255
                name='output' if operand==3 else 'weight' if operand==1 and not resadd else 'bias' if operand==2 else 'input'
                key=plan['bases'][role] if not null else 'NULL'
                ranges=matrix(offset,*dims[operand],packet['strides'][operand],widths[operand]) if not null else []
                identity=(role,offset,dims[operand],packet['strides'][operand],widths[operand])
                requests[name].append((operand,NULL if null else offset,key,identity,ranges))
        results[stage]=summarize('resadd' if plan['helper'].startswith('add_') else 'splitk',plan['packets'],requests)
    return results


def summarize(kind,packets,requests):
    row={'kind':kind,'packets':packets}
    for name,values in requests.items():
        live=[v for v in values if v[1]!=NULL]
        groups=defaultdict(list)
        for _,_,key,_,ranges in live:
            if ranges is not None: groups[key].extend(ranges)
        known=[v for v in live if v[4] is not None]
        span=sum(stop-begin for v in known for begin,stop in v[4])
        unique=sum(union_bytes(intervals) for intervals in groups.values())
        row[name]={'references':len(values),'nonnull':len(live),'null_reuse_or_no_transfer':len(values)-len(live),
                   'repeated_exact_descriptors':len(live)-len({(v[2],v[3]) for v in live}),
                   'logical_span_bytes':span,'logical_unique_bytes':unique,'logical_overlap_bytes':span-unique,
                   'unknown_extent_references':len(live)-len(known)}
    return row


def generate(source,destination):
    raw=Path(source).read_bytes(); manifest=json.loads(raw)
    stages=analyze(manifest)
    if sum(r['packets'] for r in stages.values() if r['kind']=='conv')!=469 or sum(r['packets'] for r in stages.values() if r['kind']!='conv')!=224:
        raise ValueError('traffic map differs from 469 Conv + 224 WS baseline')
    result={'schema':1,'manifest_sha256':hashlib.sha256(raw).hexdigest(),
            'meaning':'Logical command references and unaligned native-helper tensor extents; NOT DDR transactions, padded DMA bytes or measured bandwidth.',
            'scope':'One worker; within each stage and logical operand. No claim of cross-worker physical caching or cross-stage arena data equivalence.',
            'stages':stages}
    Path(destination).write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
    return result


def report(run,path):
    path=Path(path)
    if not path.exists():
        print('  Logical traffic map unavailable: build supply-diag or run diagnostic_traffic.py.')
        return
    table=json.loads(path.read_text())['stages']
    for w in range(3):
        for stage,r in table.items():
            command=run['rocc_layer_stats'].get((w,int(stage),15 if r['kind']=='conv' else 11))
            if command is None or int(command['count'],0)!=r['packets']:
                print('  Traffic map command counts differ from captured run; skip logical extent join.')
                return
    print('  Logical traffic candidates (one worker; inferred tensor spans, NOT measured DDR bytes):')
    for name in ('input','weight','output'):
        print('    '+name+': stage packets nonnull repeated_descriptor span_bytes overlap_bytes')
        for stage,r in sorted(table.items(),key=lambda p:p[1].get(name,{}).get('logical_overlap_bytes',0) if name!='output' else p[1].get(name,{}).get('logical_span_bytes',0),reverse=True)[:8]:
            v=r.get(name,{})
            if not v: continue
            print(f"      {stage:>3} {r['packets']:>4} {v['nonnull']:>4} {v['repeated_exact_descriptors']:>4} {v['logical_span_bytes']:>10} {v['logical_overlap_bytes']:>10} unknown={v['unknown_extent_references']}")


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('manifest',type=Path); parser.add_argument('output',type=Path)
    args=parser.parse_args()
    result=generate(args.manifest,args.output)
    print(f"Logical traffic map: {len(result['stages'])} stages; 469 Conv + 224 WS packets/worker; inferred extents, not DDR bytes")
