#!/usr/bin/env python3
"""A stale/partial simulation record cannot authorize a candidate build."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

FEATURE=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(FEATURE/'scripts'))
spec=importlib.util.spec_from_file_location('merge_launcher',FEATURE/'scripts/launch_bitstream.py')
launcher=importlib.util.module_from_spec(spec);spec.loader.exec_module(launcher)


class FunctionalGate(unittest.TestCase):
    def test_complete_identity_and_evidence_hashes(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);context=root/'context.json';context.write_text('{}')
            payload=root/'result.json';payload.write_text('{"status":"PASS"}')
            keys=('units','store','tl','first_ddr','first_local','layers','joint','fault_ddr','fault_local','memory','buffered_spad')
            report=dict(status='MERGED_FUNCTIONAL_SIMULATION_PASS',hardware_build_id='1234567890abcdef',
                        generation_context_sha256=launcher.candidate.sha(context),
                        evidence={key:dict(path=str(payload),sha256=launcher.candidate.sha(payload)) for key in keys})
            path=root/'gate.json';path.write_text(json.dumps(report))
            expected=dict(dma_load_build_id='1234567890abcdef')
            launcher.check_functional_evidence(path,context,expected)
            for field,value in (('status','NOT_RUN'),('hardware_build_id','0000000000000000'),('generation_context_sha256','bad')):
                altered=dict(report,**{field:value});path.write_text(json.dumps(altered))
                with self.assertRaises(ValueError):launcher.check_functional_evidence(path,context,expected)
            altered=dict(report,evidence=dict(report['evidence']));del altered['evidence']['joint'];path.write_text(json.dumps(altered))
            with self.assertRaises(ValueError):launcher.check_functional_evidence(path,context,expected)
            path.write_text(json.dumps(report));payload.write_text('modified')
            with self.assertRaises(ValueError):launcher.check_functional_evidence(path,context,expected)


if __name__=='__main__':unittest.main()
