import json
import os
from pathlib import Path
import subprocess
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from analyze import parse


class Suite(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.out=ROOT/'build/tests'; cls.out.mkdir(parents=True,exist_ok=True)
        cls.binary=cls.out/'suite'
        subprocess.run([os.environ.get('HOST_CC','cc'),'-std=c11','-O2','-Wall','-Wextra','-Werror',
                        '-DASRAM_HOST_TEST','-fno-tree-vectorize','-I'+str(ROOT/'include'),
                        '-I'+str(ROOT/'build/generated'),str(ROOT/'src/main.c'),
                        str(ROOT/'src/reference.c'),str(ROOT/'tests/fake_device.c'),
                        '-o',str(cls.binary)],check=True)
        cls.manifest=json.loads((ROOT/'build/manifest.json').read_text())

    def execute(self,**extra):
        return subprocess.run([str(self.binary)],text=True,capture_output=True,timeout=20,
                              env=dict(os.environ,**extra))

    def test_full_matrix_and_strict_synthetic_boundary(self):
        r=self.execute(); self.assertEqual(r.returncode,0,r.stdout[-2000:]+r.stderr)
        (self.out/'synthetic.log').write_text(r.stdout)
        result=parse(r.stdout,self.manifest,allow_synthetic=True)
        self.assertEqual(result['status'],'SYNTHETIC_TEST_PASS')
        self.assertEqual(len(result['samples']),108)
        self.assertEqual(result['denied_hole_probes'],12)
        self.assertEqual(result['expected_cpu_traps'],0)
        with self.assertRaises(ValueError): parse(r.stdout,self.manifest)
        # Test parser board path only with an explicitly synthetic fixture.
        board_fixture=r.stdout.replace('hardware=0','hardware=1',1)
        self.assertEqual(parse(board_fixture,self.manifest)['status'],'BOARD_PASS')
        rows=r.stdout.splitlines()
        i=next(i for i,x in enumerate(rows) if x.startswith('ASRAM1,DMA,'))
        for broken in ('\n'.join(rows[:i]+rows[i+1:]), '\n'.join(rows[:i]+[rows[i]]+rows[i:]),
                       r.stdout[:r.stdout.rfind('ASRAM1,PASS,')],
                       r.stdout.replace(',get=0,',',get=1,',1),
                       r.stdout.replace(',get=0,',',',1),
                       r.stdout.replace(',get=0,',',get=0,unknown=1,',1),
                       r.stdout.replace('hardware_id='+self.manifest['config']['target']['hardware_build_id'],'hardware_id=0000000000000001',1),
                       r.stdout+'ASRAM1,PASS,cases=15,dma=432,parallel=4,denied=12,traps=0\n'):
            with self.assertRaises((ValueError,KeyError)): parse(broken,self.manifest,allow_synthetic=True)

    def test_independent_failures_stop_without_pass(self):
        for fault in ('FAKE_ID','FAKE_ALIAS','FAKE_RVV','FAKE_HOLE','FAKE_DATA',
                      'FAKE_GUARD','FAKE_COUNTER','FAKE_TIMEOUT','FAKE_HOLE_ALIAS',
                      'FAKE_HOLE_DATA','FAKE_HOLE_ROUTE','FAKE_HOLE_RETIRED'):
            with self.subTest(fault=fault):
                r=self.execute(**{fault:'1'})
                self.assertEqual(r.returncode,1,r.stdout[-1000:]+r.stderr)
                self.assertIn('ASRAM1,FAIL,',r.stdout)
                self.assertNotIn('ASRAM1,PASS,',r.stdout)
                with self.assertRaises(ValueError): parse(r.stdout,self.manifest,allow_synthetic=True)

    def test_bad_parallel_or_memory_summary_rejected(self):
        r=self.execute(); self.assertEqual(r.returncode,0)
        for broken in (r.stdout.replace(',lanes=7,',',lanes=3,',1),
                       r.stdout.replace('traps=0','traps=1'),
                       r.stdout.replace('denied=12','denied=11'),
                       r.stdout.replace('bytes=2359296','bytes=524288',1),
                       r.stdout.replace(',mode=2,',',mode=4,',1)):
            with self.assertRaises(ValueError): parse(broken,self.manifest,allow_synthetic=True)

    def test_hole_counter_evidence_is_required(self):
        r=self.execute(); self.assertEqual(r.returncode,0)
        rows=r.stdout.splitlines()
        i=next(i for i,x in enumerate(rows) if x.startswith('ASRAM1,HOLE,'))
        for field,value in (('denied','0'),('physical_reads','1'),('physical_writes','1'),
                            ('retired','0'),('address','536870912'),('value','1')):
            with self.subTest(field=field):
                parts=rows[i].split(',')
                changed=','.join(field+'='+value if x.startswith(field+'=') else x for x in parts)
                broken='\n'.join(rows[:i]+[changed]+rows[i+1:])
                with self.assertRaises(ValueError): parse(broken,self.manifest,allow_synthetic=True)
        for broken in ('\n'.join(rows[:i]+rows[i+1:]), '\n'.join(rows[:i]+[rows[i]]+rows[i:])):
            with self.assertRaises(ValueError): parse(broken,self.manifest,allow_synthetic=True)

    def test_preflight_never_invokes_board_tools(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); sentinel=root/'accessed'; tool=root/'fake-tool'
            tool.write_text('#!/bin/sh\ntouch "'+str(sentinel)+'"\nexit 1\n'); tool.chmod(0o755)
            r=subprocess.run([sys.executable,'-B',str(ROOT/'scripts/program.py'),'preflight'],
                text=True,capture_output=True,env=dict(os.environ,VIVADO_BIN=str(tool),
                    OPENOCD_BIN=str(tool),GDB_BIN=str(tool)))
            self.assertEqual(r.returncode,0,r.stdout+r.stderr)
            self.assertIn('board_accessed=0',r.stdout)
            self.assertFalse(sentinel.exists())


if __name__=='__main__': unittest.main()
