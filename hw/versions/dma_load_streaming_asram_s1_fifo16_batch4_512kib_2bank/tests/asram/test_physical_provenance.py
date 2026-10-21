#!/usr/bin/env python3
"""Physical-only changes may retain an RTL identity; RTL input changes may not."""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

FEATURE = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('asram_audit', FEATURE / 'scripts/audit.py')
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class PhysicalProvenanceTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.feature = Path(self.temp.name)
        files = {}
        for name in ('activation_sram/scala/controller.scala', 'scripts/build_soc.py',
                     'constraints/placement.tcl'):
            path = self.feature / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('original\n')
            files[name] = {'sha256': audit.digest(path)}
        self.snapshot = self.feature / 'manifests/rtl_snapshots/build.sources.json'
        self.snapshot.parent.mkdir(parents=True)
        self.snapshot.write_text(json.dumps({'files': files}))
        self.context = {'feature_source_origins_sha256': audit.digest(self.snapshot)}
        (self.feature / 'manifests/SOURCE_ORIGINS.json').write_text('{"new_physical_revision": 2}')

    def test_physical_revision_accepts_original_generation_identity(self):
        (self.feature / 'constraints/placement.tcl').write_text('new placement\n')
        self.assertEqual(audit.verify_generation_sources(self.context, self.feature), self.snapshot)

    def test_modified_generation_input_rejected(self):
        (self.feature / 'activation_sram/scala/controller.scala').write_text('changed RTL\n')
        with self.assertRaises(SystemExit):
            audit.verify_generation_sources(self.context, self.feature)

    def test_added_generation_input_rejected(self):
        (self.feature / 'activation_sram/scala/extra.scala').write_text('new RTL\n')
        with self.assertRaises(SystemExit):
            audit.verify_generation_sources(self.context, self.feature)

    def test_altered_archive_rejected(self):
        self.snapshot.write_text('{}')
        with self.assertRaises(SystemExit):
            audit.verify_generation_sources(self.context, self.feature)


if __name__ == '__main__':
    unittest.main()
