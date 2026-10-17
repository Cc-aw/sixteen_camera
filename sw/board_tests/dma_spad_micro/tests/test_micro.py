#!/usr/bin/env python3
"""Independent original-write oracle and real C suite loop/log checks."""
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from analyze import parse
from build import parameters
from spec import predict


class Micro(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.out=ROOT/'build/tests';cls.out.mkdir(parents=True,exist_ok=True)
        cls.compiler=os.environ.get('HOST_CC','cc')
        flags=['-std=gnu11','-O2','-Wall','-Wextra','-Werror','-I'+str(ROOT/'include'),
            '-I'+str(ROOT/'build/generated')]
        cls.driver=cls.out/'reference'
        subprocess.run([cls.compiler,*flags,str(ROOT/'tests/reference_driver.c'),
            str(ROOT/'src/reference.c'),'-o',str(cls.driver)],check=True)
        cls.suite=cls.out/'suite'
        subprocess.run([cls.compiler,*flags,'-DMICRO_HOST_TEST',str(ROOT/'src/main.c'),
            str(ROOT/'src/reference.c'),str(ROOT/'tests/fake_device.c'),'-o',str(cls.suite)],check=True)
        cls.manifest=json.loads((ROOT/'build/manifest.json').read_text())

    def test_independent_original_repeat_writes_scale_and_poison(self):
        cases=[(12,32,2,64,0,1),(12,32,2,12,0,1),(3,32,6,3,63,1),
            (1,2,32,64,7,0.5),(8,32,4,64,31,2),(12,3,2,64,0,-1),
            (16,32,2,16,63,0.25),(7,31,4,128,59,64),(3,1,6,64,0,0)]
        for c,n,p,stride,offset,scale in cases:
            bits=int.from_bytes(struct.pack('<e',scale),'little')
            q=dict(c=c,n=n,p=p,stride=stride,offset=offset,ops=3)
            for mode in range(3):
                raw=subprocess.check_output([str(self.driver),*map(str,(c,n,p,stride,offset,3,bits,mode))],text=True).splitlines()
                expected=bytearray([0xa5]*((n+p+1)*32))
                for row in range(n):
                    for k in reversed(range(p)):
                        for col in range(c):
                            value=(row*37+col*11+17)&255
                            if value>=128:value-=256
                            value=max(-128,min(127,round(value*scale)))
                            # Relative to guard row DEST-P; original writes.
                            expected[(p+row-k)*32+k*c+col]=value&255
                self.assertEqual(bytes.fromhex(raw[2]),bytes(expected),(c,n,p,stride,mode))
                t=predict(q,mode);v=t['values']
                want=[v[i] for i in (18,19,33,22,11,21,8,9)]+[t['read_merge'],t['assembly']]
                self.assertEqual(list(map(int,raw[0].split())),want)
                words=list(map(int,raw[1].split()))
                self.assertEqual(words,[bits<<32|32<<16|p<<8|1,n<<48|c<<32|64])

    def execute(self,**extra):
        return subprocess.run([str(self.suite)],text=True,capture_output=True,timeout=10,
            env=dict(os.environ,**extra))

    def test_real_suite_loops_exact_counts_and_strict_log(self):
        result=self.execute();self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        (self.out/'synthetic.log').write_text(result.stdout)
        parsed=parse(result.stdout,self.manifest,allow_synthetic=True)
        self.assertEqual(parsed['status'],'SYNTHETIC_TEST_PASS')
        self.assertEqual(len(parsed['aggregate']),6)
        for row in parsed['aggregate']:
            self.assertEqual(row['samples'],self.manifest['config']['case']['samples'])
        # A synthetic test must never silently become a board benchmark.
        with self.assertRaises(ValueError):parse(result.stdout,self.manifest)
        rows=result.stdout.splitlines()
        at=next(i for i,row in enumerate(rows) if row.startswith('SPADM1,RESULT,'))
        for broken in ('\n'.join(rows[:at]+rows[at+1:]),
            '\n'.join(rows[:at]+[rows[at]]+rows[at:]),
            result.stdout[:result.stdout.rfind('SPADM1,PASS,')],
            result.stdout.replace(',c22=','x,c22=',1),
            result.stdout.replace(',read_merge=0,',',read_merge=1,',1)):
            with self.assertRaises(ValueError):parse(broken,self.manifest,allow_synthetic=True)

    def test_output_counter_guard_and_capability_faults_stop(self):
        for fault in ('FAKE_BAD_BYTE','FAKE_BAD_COUNTER','FAKE_BAD_GUARD','FAKE_CAPABILITY'):
            result=self.execute(**{fault:'1'})
            self.assertEqual(result.returncode,1,(fault,result.stdout))
            self.assertIn('SPADM1,FAIL,',result.stdout)
            self.assertNotIn('SPADM1,PASS,',result.stdout)
            with self.assertRaises(ValueError):parse(result.stdout,self.manifest,allow_synthetic=True)

    def test_parameter_rejection_and_fp16_rounding(self):
        for env in ({'MICRO_C':'17','MICRO_P':'2'},{'MICRO_STRIDE':'12'},
            {'MICRO_SCALE':'nan'},{'MICRO_N':'33'},{'MICRO_SAMPLES':'0'}):
            from unittest.mock import patch
            with patch.dict(os.environ,dict(dict(MICRO_C="12",MICRO_N="32",MICRO_P="2",MICRO_STRIDE="64",MICRO_SCALE="1",MICRO_OFFSET="0",MICRO_LANE="0",MICRO_OPS="1",MICRO_SAMPLES="12",MICRO_WARMUPS="3"),**env)):
                with self.assertRaises(ValueError):parameters()

    def test_default_strided_case_expected_traffic(self):
        q=dict(c=12,n=32,p=2,stride=64,offset=0,ops=1)
        for mode in range(3):
            t=predict(q,mode)
            self.assertEqual(t['read_merge'],0)
            self.assertEqual(t['values'][18]+t['values'][19],32)
            self.assertEqual(t['values'][33],1024)
            self.assertEqual(t['values'][22],33 if mode==2 else 64)


if __name__=='__main__':unittest.main(verbosity=2)
