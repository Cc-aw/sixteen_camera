"""Exercise the real device input monitor using deterministic MMIO counters."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class InputMonitorTests(unittest.TestCase):
    def test_live_mask_and_requested_mask(self):
        with tempfile.TemporaryDirectory() as directory:
            executable = Path(directory) / 'monitor'
            for mask in ('0xffff', '0xff'):
                with self.subTest(requested_mask=mask):
                    subprocess.run([os.environ.get('HOST_CC', 'cc'), '-std=c11', '-O2', '-Wall', '-Wextra', '-Werror',
                                    '-DVIDEO_STREAM_MASK='+mask, '-I'+str(ROOT/'tests/fakes'), '-I'+str(ROOT/'runtime'),
                                    str(ROOT/'tests/test_input_monitor.c'), str(ROOT/'runtime/drivers/tensor/ai_tensor_device.c'),
                                    '-o', str(executable)], check=True)
                    subprocess.run([str(executable)], check=True)

    def test_capture_quiesce(self):
        with tempfile.TemporaryDirectory() as directory:
            executable = Path(directory) / 'stop'
            subprocess.run([os.environ.get('HOST_CC', 'cc'), '-std=c11', '-O2', '-Wall', '-Wextra', '-Werror',
                            '-I'+str(ROOT/'tests/fakes'), '-I'+str(ROOT/'runtime'),
                            str(ROOT/'tests/test_capture_stop.c'), str(ROOT/'runtime/drivers/tensor/ai_tensor_device.c'),
                            '-o', str(executable)], check=True)
            subprocess.run([str(executable)], check=True)

if __name__ == '__main__':
    unittest.main()
