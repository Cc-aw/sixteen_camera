"""Hardware-only logs must prove PPU completion and preserve integer words."""
import sys
from pathlib import Path
import unittest
HERE=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(HERE))
from analyze_log import parse
from check_log import fields, latest_session
from test_benchmark import benchmark_fixture


def hardware_fixture():
    lines=[]
    for line in benchmark_fixture().splitlines():
        if line.startswith('YOLO32_BEGIN '):
            line=line.replace(' mode=', ' postprocess=hardware mode=')
        elif line.startswith('YOLO32_TIMING '):
            line=line.replace('post_cycles=', 'ppu_tail_cycles=')+' ppu_core_cycles=300'
        elif line.startswith('YOLO32_WORKER '):
            r=fields(line)
            line=(f"YOLO32_WORKER worker={r['worker']} image={r['image']} raw_fnv={r['raw_fnv']} "
                  f"ppu_fnv={r['mask_fnv']} detections=1 ppu_core_cycles=100 ppu_wall_cycles=200 cycles=300")
        elif line.startswith('YOLO32_DETECTION '):
            r=fields(line);w=int(r['worker'])
            line=f"YOLO32_DETECTION worker={w} index=0 xy0={w} xy1={w+1} score_class={(w<<16)|1234} word3=0"
        lines.append(line)
    return '\n'.join(lines)


class HardwareLogTests(unittest.TestCase):
    def test_latest_session_excludes_old_boots_but_preserves_new_failures(self):
        good='YOLO32_FIRMWARE v6\n'+hardware_fixture()
        log='YOLO32_FIRMWARE v5\nYOLO32_RESULT FAIL reason=old\n'+good
        self.assertEqual(parse(latest_session(log))[0],[])
        self.assertEqual(latest_session(log+'\nYOLO32_FIRMWARE v6\nYOLO32_RESULT FAIL reason=new'),
                         'YOLO32_FIRMWARE v6\nYOLO32_RESULT FAIL reason=new')
        self.assertTrue(parse(latest_session(log+'\nYOLO32_FIRMWARE v6\nYOLO32_RESULT FAIL reason=new'))[0])
        self.assertTrue(parse(latest_session(log+'\nYOLO32_FIRMWARE v6\n'))[0])

    def test_full_hardware_benchmark_passes(self):
        errors,runs=parse(hardware_fixture())
        self.assertEqual(errors,[])
        self.assertEqual(len(runs),29)
        self.assertTrue(all(r['hardware'] and r['ppu_core']==300 for r in runs))

    def test_missing_ppu_and_cpu_fields_are_rejected(self):
        log=hardware_fixture()
        for old,new in [('ppu_core_cycles=300','ppu_core_cycles=299'),('ppu_core_cycles=100','ppu_core_cycles=0'),
                        ('ppu_tail_cycles=','post_cycles='),('ppu_fnv=2','logits_fnv=2'),
                        ('word3=0','word3=0x100000000'),('score_class=132306','score_class=0x007f0001')]:
            with self.subTest(field=old):
                self.assertTrue(parse(log.replace(old,new))[0])

    def test_result_words_must_match_corresponding_serial_image(self):
        log=hardware_fixture()
        marker='YOLO32_DETECTION worker=2 index=0 xy0=2 xy1=3'
        # Leave the baseline intact; corrupt a later result despite firmware PASS.
        first=log.index(marker)
        log=log[:first+len(marker)]+log[first+len(marker):].replace(marker,marker.replace('xy1=3','xy1=4'),1)
        self.assertTrue(parse(log)[0])


if __name__=='__main__':unittest.main()
