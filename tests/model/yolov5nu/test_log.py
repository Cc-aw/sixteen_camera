from paths import HERE, source_path, RISCV_LINUX_CC
import sys
import unittest
from pathlib import Path

from check_log import validate


def fixture(detections=1):
    lines = ["YOLO32_BEGIN run=1 image=025 dim=32 workers=3 mode=interleaved reference=worker0"]
    for worker in range(3):
        lines.append(f"YOLO32_WORKER worker={worker} raw_fnv=0x1 mask_fnv=0x2 "
                     "logits_sum=0x3 logits_fnv=0x4 scores_sum=0x5 scores_fnv=0x6 "
                     f"dfl_sum=0x7 dfl_fnv=0x8 candidates=15 detections={detections} cycles={100 + worker}")
        for index in range(detections):
            lines.append(f"YOLO32_DETECTION worker={worker} index={index} class=4 "
                         "score=0x3f000000 cx=0x43000000 cy=0x43000000 width=0x42000000 height=0x42000000")
    for worker in (1, 2):
        lines.append(f"YOLO32_COMPARE worker={worker} reference=0 mismatches=0 first=none index=0")
    lines.append("YOLO32_RESULT PASS workers=bit_exact reference=worker0")
    return "\n".join(lines)


class LogTests(unittest.TestCase):
    def parallel_fixture(self):
        evidence = ('YOLO32_PARALLEL conv_groups=58 tile_groups=500 requests0=500 requests1=500 '
                    'requests2=500 overlap_samples=20 triple_overlap_samples=10 busy_mask_seen=7\n'
                    'YOLO32_PARALLEL_RESULT PASS\n')
        return fixture().replace('mode=interleaved', 'mode=parallel').replace('YOLO32_WORKER worker=0', evidence+'YOLO32_WORKER worker=0')

    def test_parallel_evidence(self):
        self.assertEqual(validate(self.parallel_fixture()), [])
        for old, new in [('triple_overlap_samples=10', 'triple_overlap_samples=0'),
                         ('requests2=500', 'requests2=499'), ('conv_groups=58', 'conv_groups=57'),
                         ('busy_mask_seen=7', 'busy_mask_seen=3'),
                         ('PARALLEL_RESULT PASS', 'PARALLEL_RESULT FAIL')]:
            with self.subTest(field=old):
                self.assertTrue(validate(self.parallel_fixture().replace(old, new)))

    def test_consistency_alone_cannot_prove_parallel(self):
        self.assertTrue(validate(fixture().replace('mode=interleaved', 'mode=parallel')))
        self.assertTrue(validate('\n'.join(line for line in self.parallel_fixture().splitlines()
                                          if not line.startswith('YOLO32_PARALLEL_RESULT'))))

    def test_equal_new_signatures_pass(self):
        self.assertEqual(validate(fixture()), [])

    def test_equal_zero_detections_pass(self):
        self.assertEqual(validate(fixture(0)), [])

    def test_worker2_difference_fails(self):
        self.assertTrue(validate(fixture().replace("worker=2 raw_fnv=0x1", "worker=2 raw_fnv=0x9")))

    def test_missing_worker_fails(self):
        self.assertTrue(validate("\n".join(line for line in fixture().splitlines()
                                            if not line.startswith("YOLO32_WORKER worker=2"))))

    def test_detection_difference_fails(self):
        self.assertTrue(validate(fixture().replace("worker=2 index=0 class=4", "worker=2 index=0 class=7")))

    def test_missing_detection_fails(self):
        self.assertTrue(validate("\n".join(line for line in fixture().splitlines()
                                            if not line.startswith("YOLO32_DETECTION worker=2"))))

    def test_forged_pass_with_byte_mismatch_fails(self):
        self.assertTrue(validate(fixture().replace("mismatches=0", "mismatches=1")))

    def test_truncated_and_duplicate_fails(self):
        self.assertTrue(validate(fixture().rsplit("\n", 1)[0]))
        record = fixture().splitlines()[1]
        self.assertTrue(validate(fixture().replace(record, record + "\n" + record)))

    def test_all_runs_checked(self):
        self.assertEqual(validate(fixture() + "\n" + fixture()), [])
        self.assertTrue(validate(fixture().replace("RESULT PASS workers=bit_exact reference=worker0",
                                                  "RESULT FAIL reason=worker_mismatch") + "\n" + fixture()))

    def test_wrong_hardware_or_old_log_fails(self):
        self.assertTrue(validate(fixture().replace("dim=32", "dim=64")))
        self.assertTrue(validate("YOLOV5NU_TEST_RESULT PASS reference=bit_exact workers=bit_exact"))

    def test_missing_comparison_and_empty_fails(self):
        self.assertTrue(validate("\n".join(line for line in fixture().splitlines()
                                            if not line.startswith("YOLO32_COMPARE worker=2"))))
        self.assertTrue(validate(""))


if __name__ == "__main__":
    unittest.main()
