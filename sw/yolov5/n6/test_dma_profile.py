#!/usr/bin/env python3
"""I: real baseline log plus synthetic ABI records. P: validate parser failure modes.
O: host regression only; no claim of FPGA execution. A: 王志瑞. T: 2026-09-11.
"""
import copy,re,unittest
from pathlib import Path
from analyze_dma_profile import parse_records
from analyze_timing import analyze
ROOT=Path(__file__).resolve().parents[3]
class TestProfile(unittest.TestCase):
    def setUp(self):
        self.text=(ROOT/'log/gemmini64_yolov5_v8_ddr_v6_run1.log').read_text().replace('n6_port_v8_ddr_v6','n6_port_dma_profile_v6')
        self.memory=[dict(re.findall(r'(\w+)=([^\s]+)',s)) for s in self.text.splitlines() if s.startswith('N6_MEMORY ')]
        self.records=[]
        for i,m in enumerate(self.memory):
            for w in range(2):
                c=[0]*35;c[0]=0x4e36505200010000|w
                c[1]=1;c[2]=3 if w==0 else 16;c[3]=1;c[4]=64;c[5]=2 if w==0 else 1
                c[6]=64 if w==0 else 0;c[7]=16 if w else 0
                c[11]=10;c[12]=1;c[15]=10;c[18 if w==0 else 20]=1;c[31]=1
                self.records.append((i,m['op'],'write' if w else 'read',c))
    def log(self,records=None):
        return self.text+'\n'+'\n'.join(f'N6_DMA_PROFILE id={i} op={op} direction={d} abi=1 ddr_bytes_measured=0 '+
            ' '.join(f'c{j}={v}' for j,v in enumerate(c)) for i,op,d,c in (records if records is not None else self.records))
    def test_complete(self):
        result=analyze(self.log());self.assertTrue(result['correct']);self.assertEqual(len(result['dma_profile']),156)
        self.assertEqual(result['dma_profile'][0]['read_response_bytes'],64)
    def test_missing(self):
        with self.assertRaises(ValueError): analyze(self.log(self.records[:-1]))
    def test_invalid_counters(self):
        for idx,val in [(0,0),(16,1),(33,1),(18,2),(4,128),(5,1),(6,128),(12,33),(32,1)]:
            records=copy.deepcopy(self.records);records[0][3][idx]=val
            with self.subTest(counter=idx),self.assertRaises(ValueError): analyze(self.log(records))
    def test_legacy(self):
        result=analyze(self.text.replace('n6_port_dma_profile_v6','n6_port_v8_ddr_v6'))
        self.assertTrue(result['correct']);self.assertNotIn('dma_profile',result)
    def test_math_unchanged(self):
        for image in ['025','036','142','404','650']:
            baseline=(ROOT/f'build/yolov5nu_n6_v8_ddr_v6/{image}/main.c').read_text()
            current=(ROOT/f'build/yolov5nu_n6_dma_profile_v6/{image}/main.c').read_text()
            self.assertEqual(baseline.replace('n6_port_v8_ddr_v6','n6_port_dma_profile_v6'),current)
if __name__=='__main__': unittest.main()
