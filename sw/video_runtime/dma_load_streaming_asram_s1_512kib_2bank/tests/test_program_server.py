"""Private server lifetime regression; never launches Vivado or accesses JTAG."""
import importlib.util
import os
from pathlib import Path
import signal
import tempfile
import unittest
from unittest.mock import MagicMock, call, patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('private_server', ROOT / 'program/vivado_program.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)

class PrivateServerTests(unittest.TestCase):
    def test_server_survives_client_startup_and_is_cleaned_on_exit(self):
        with tempfile.TemporaryDirectory() as folder:
            directory = Path(folder)
            for name in ('vivado', 'hw_server'):
                path = directory / name
                path.write_text('#!/bin/sh\nexit 0\n')
                path.chmod(0o700)
            compat = directory / 'compat.so'
            compat.write_bytes(b'fixture')
            for status in (0, 1):
                with self.subTest(client_exit_code=status):
                    server = MagicMock()
                    server.pid = 48321
                    server.poll.return_value = None
                    with patch.object(runner, 'COMPAT', compat), \
                         patch.object(runner.socket, 'socket') as sock, \
                         patch.object(runner.socket, 'create_connection'), \
                         patch.object(runner.subprocess, 'Popen', return_value=server) as start, \
                         patch.object(runner.subprocess, 'run') as run, \
                         patch.object(runner.os, 'killpg') as kill_group:
                        sock.return_value.__enter__.return_value.getsockname.return_value = ('127.0.0.1', 43567)
                        run.return_value.returncode = status
                        self.assertEqual(runner.program(str(directory / 'vivado'), directory / 'test.bit',
                                                        directory / 'test.tcl', directory / 'program.log'), status)
                        args = start.call_args.args[0]
                        self.assertIn('-p0', args)
                        self.assertIn('-stcp:127.0.0.1:43567', args)
                        self.assertFalse(any(a.startswith('-I') for a in args))
                        self.assertTrue(start.call_args.kwargs['start_new_session'])
                        self.assertTrue(start.call_args.kwargs['env']['LD_PRELOAD'].startswith(str(compat)))
                        self.assertEqual(run.call_args.kwargs['env']['HW_SERVER_URL'], '127.0.0.1:43567')
                        self.assertEqual(run.call_args.kwargs['env'].get('LD_PRELOAD'), os.environ.get('LD_PRELOAD'))
                        self.assertEqual(kill_group.call_args_list,
                                         [call(server.pid, signal.SIGTERM), call(server.pid, signal.SIGKILL)])
                        server.wait.assert_any_call(timeout=5)

if __name__ == '__main__':
    unittest.main()
