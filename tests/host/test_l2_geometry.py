#!/usr/bin/env python3
"""Check complete index periods and geometry-bound software storage generation."""
import importlib.util
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/soc"))
from l2_geometry import L2Geometry, current_geometry


class GeometryTest(unittest.TestCase):
    def test_complete_period_and_tag_step(self):
        for banks, period in ((2, 65536), (4, 131072)):
            g = L2Geometry(banks)
            seen = set()
            for offset in range(0, period, 64):
                a = 0x82000000 + offset
                bank, index = g.bank(a), g.set_index(a)
                # Independent reference: remove the bank field from the line
                # number before taking the nine set bits.
                low = (a // 64) % 64
                upper = a // (4096 * banks)
                self.assertEqual(index, low + (upper % 8) * 64)
                self.assertEqual(bank, (a // 4096) % banks)
                self.assertNotIn((bank, index), seen)
                seen.add((bank, index))
                self.assertEqual((bank, index), (g.bank(a + period), g.set_index(a + period)))
            self.assertEqual(len(seen), banks * 512)
            self.assertEqual(g.capacity_bytes, banks * 262144)
            self.assertEqual(g.period_bytes, period)

    def test_new_high_set_bit(self):
        old, new = L2Geometry(2), L2Geometry(4)
        self.assertEqual(old.set_index(0x82000000), old.set_index(0x82010000))
        self.assertNotEqual(new.set_index(0x82000000), new.set_index(0x82010000))
        self.assertEqual(new.bank(0x82003000), 3)

    def test_generated_metadata_and_storage(self):
        geometry = current_geometry(ROOT)
        scripts = ROOT / "sw/benchmarks/frontend/scripts"
        sys.path.insert(0, str(scripts))
        import parallel_cache_plan as plan
        original = plan.PERIOD
        try:
            for banks in (2, 4):
                plan.PERIOD = L2Geometry(banks).period_bytes
                text = plan.storage_declarations()
                self.assertIn(f"#define SW_P3_L2_PERIOD {plan.PERIOD}u", text)
                self.assertEqual(text.count(f"aligned({plan.PERIOD})"), 5)
                self.assertEqual(text.count(f"+{plan.PERIOD}+128)"), 5)
                for _, cap in plan.BUFFERS:
                    storage = 3 * (cap + plan.PERIOD + 128)
                    for lane in range(3):
                        start = 64 + lane * (cap + plan.PERIOD + 128) + plan.PERIOD - 64
                        self.assertLessEqual(start + cap + 64, storage)
        finally:
            plan.PERIOD = original
        self.assertEqual(original, geometry.period_bytes)


if __name__ == "__main__":
    unittest.main()
