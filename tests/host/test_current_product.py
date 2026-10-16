"""Reject incompatible production identities using isolated generated-header fixtures."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('current_product', ROOT / 'tools/check/check_current_product.py')
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class CurrentProductTests(unittest.TestCase):
    def setUp(self):
        self.product = json.loads((ROOT / 'hw/manifests/current.json').read_text())
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        files = [self.product[k] for k in ('model_rules', 'model_source', 'generator', 'frozen_input', 'generation_context', 'tensor_ingress_source', 'soc_generator', 'reference_manifest')]
        files += [self.product['collateral_directory'] + '/' + name + '.sv' for name in ('Gemmini', 'Gemmini_1', 'Gemmini_2')]
        files += self.product['parameter_headers'] + self.product['source_locks'] + ['sw/src/board/xparameters.h', 'sw/src/platform/platform.h']
        files += [self.product['collateral_directory'] + '/RocketTile.sv']
        files += [self.product['frontend_benchmark'][key] for key in ('source','rules','generator','source_lock','import_manifest')]
        files += [str(p.relative_to(ROOT)) for p in (ROOT/self.product['soc_directory']).glob('*.l2.json')]
        for name in files:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        self.addCleanup(patch.stopall)
        patch.dict(os.environ, {'SOC_VARIANT': '', 'SOC_CONFIG': ''}).start()

    def validate(self):
        checker.validate(self.product, self.root, evaluate=False)

    def test_current_identity(self):
        self.validate()

    def test_reject_each_worker_geometry_or_credit_mismatch(self):
        for name in self.product['parameter_headers']:
            header = self.root / name
            original = header.read_text()
            for old, new in (('#define DIM 32', '#define DIM 16'),
                             ('#define GEMMINI_LOOPCONV_SAFE_MAX 4', '#define GEMMINI_LOOPCONV_SAFE_MAX 3'),
                             ('#define GEMMINI_LOOPCONV_STATUS_CSR ', '#define GEMMINI_LOOPCONV_STATUS_CSR 0x0 // ')):
                with self.subTest(header=name, macro=old):
                    self.assertIn(old, original)
                    header.write_text(original.replace(old, new))
                    with self.assertRaises(ValueError):
                        self.validate()
                    header.write_text(original)

    def test_reject_wrong_generated_identity(self):
        path = self.root / self.product['generation_context']
        path.write_text(json.dumps({'config': 'retired'}))
        with self.assertRaisesRegex(ValueError, 'Generation identity'):
            self.validate()

    def test_reject_retired_selectors(self):
        for name, value in (('SOC_VARIANT', 'dual16'), ('SOC_VARIANT', 'single4'), ('SOC_CONFIG', '../old')):
            with self.subTest(selector=name, value=value), patch.dict(os.environ, {name: value}):
                with self.assertRaisesRegex(ValueError, 'Unsupported'):
                    self.validate()

    def test_reject_manifest_redefining_production(self):
        for key, value in (('worker_count', 2), ('credit_limit', 3), ('runtime_profile', 'v28')):
            with self.subTest(field=key):
                product = copy.deepcopy(self.product)
                product[key] = value
                with self.assertRaises(ValueError):
                    checker.validate(product, self.root, evaluate=False)

    def test_reject_stale_l2_geometry(self):
        for key, value in (('banks',2),('capacity_bytes',524288),('bank_mask',4096),('statistics_abi','1.1')):
            with self.subTest(field=key):
                product=copy.deepcopy(self.product)
                product['l2'][key]=value
                with self.assertRaisesRegex(ValueError,'L2 geometry mismatch'):
                    checker.validate(product,self.root,evaluate=False)


if __name__ == '__main__':
    unittest.main()
