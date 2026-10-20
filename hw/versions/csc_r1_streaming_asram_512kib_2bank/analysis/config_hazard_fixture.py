#!/usr/bin/env python3
"""Expose stale load config and raw-writer invalidation after real CSC hits."""
import argparse
import json
from pathlib import Path

from compare_candidate import sha
from directed_reuse_fixture import prepare


def build(reference, output):
    prepare(reference, output)
    command_file=output/'commands.txt'
    result=json.loads((output/'fixture.json').read_text())
    commands=[]
    previous=None
    packets=0
    for line in command_file.read_text().splitlines():
        row=list(map(int,line.split()))
        lane,frame,stage,funct,*_=row
        group=(lane,frame,stage)
        if group!=previous:
            packets=0
            previous=group
        commands.append(row)
        if funct==15:
            packets+=1
            if packets==1:
                # Verified ConfigMvinRs1 fields: FP16 scale [47:32], block
                # stride [29:16], pixels [13:8], state [4:3], kind [1:0].
                commands.append([lane,frame,stage,0,(0x3800<<32)|(16<<16)|(1<<8)|1,64])
            elif packets==2:
                source=0x80004000+lane*0x100000
                # The generated/native Mvin/Mvout ABI has rows [53:48],
                # columns starting at bit 32, and the physical local address.
                shape=(1<<48)|(32<<32)|7
                commands.append([lane,frame,stage,2,source+32,shape])
                commands.append([lane,frame,stage,3,source+0x4000,shape])
    command_file.write_text(''.join(' '.join(map(str,row))+'\n' for row in commands))
    result.update(status='NATIVE_RAW_CONFIG_AND_WRITER_HAZARD_FIXTURE',
                  expected_skips_per_lane=3,
                  hazard='Raw scale=0.5/stride=64 before a resident hit; following raw Mvin+Mvout observes the restored Input config and overwrites SPAD row 7',
                  raw_writer_quarantine_required=True)
    result['sha256'].update({str(command_file):sha(command_file), str(Path(__file__).resolve()):sha(Path(__file__).resolve())})
    (output/'fixture.json').write_text(json.dumps(result,indent=2)+'\n')
    print('CSC_RAW_CONFIG_WRITER_HAZARD_FIXTURE_COMPLETE')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reference',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    build(args.reference.resolve(),args.output.resolve())
