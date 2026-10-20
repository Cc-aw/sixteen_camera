#!/usr/bin/env python3
"""Offline regression for Adept IPC compatibility and owned server cleanup."""
import importlib.util
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import MagicMock, patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('vivado_program', ROOT / 'program/vivado_program.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)
sys.path.insert(0, str(ROOT / 'scripts'))
import program as package_program

FAULT = r'''
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
int open(const char *path, int flags, ...) {
    mode_t mode = 0;
    if (flags & O_CREAT) {
        va_list args; va_start(args, flags); mode = va_arg(args, mode_t); va_end(args);
    }
    const char *root = getenv("FAKE_IPC_ROOT");
    if (root && !strncmp(path, root, strlen(root)) && (flags & O_CREAT)) {
        errno = EACCES; return -1;
    }
    int (*next)(const char *, int, ...) = dlsym(RTLD_NEXT, "open");
    return next(path, flags, mode);
}
'''
PROBE = r'''
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
int main(int argc, char **argv) {
    if (argc != 3) return 99;
    int fd = open(argv[1], atoi(argv[2]), 0777);
    if (fd < 0) return errno;
    int flags = fcntl(fd, F_GETFL);
    close(fd);
    if (flags & O_NONBLOCK) return 98;
    puts("OPEN=PASS"); return 0;
}
'''


class Programming(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='adept_compat_')
        cls.folder = Path(cls.temp.name)
        cls.compat, cls.fault, cls.probe_exe = [cls.folder / name for name in ['compat.so', 'fault.so', 'probe']]
        (cls.folder / 'fault.c').write_text(FAULT)
        (cls.folder / 'probe.c').write_text(PROBE)
        cc = os.environ.get('HOST_CC', 'cc')
        flags = [cc, '-std=gnu11', '-Wall', '-Wextra', '-Werror']
        subprocess.run(flags + ['-fPIC', '-shared', '-DADEPT_IPC_DIRECTORY="' + str(cls.folder) + '"',
                       str(ROOT / 'program/digilent_ipc_compat.c'), '-ldl', '-pthread', '-o', str(cls.compat)], check=True)
        subprocess.run(flags + ['-fPIC', '-shared', str(cls.folder / 'fault.c'), '-ldl', '-o', str(cls.fault)], check=True)
        subprocess.run(flags + [str(cls.folder / 'probe.c'), '-o', str(cls.probe_exe)], check=True)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def probe(self, path, flags=os.O_RDWR | os.O_CREAT):
        env = dict(os.environ, LD_PRELOAD=str(self.compat) + ':' + str(self.fault), FAKE_IPC_ROOT=str(self.folder))
        return subprocess.run([str(self.probe_exe), str(path), str(flags)], env=env, capture_output=True, text=True, timeout=5)

    def test_existing_regular_ipc_reopens_without_creation(self):
        path = self.folder / 'digilent-adept2-shm-dvtbl'
        path.write_text('existing-IPC-key')
        result = self.probe(path)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('DIGILENT_IPC_COMPAT=ACTIVE', result.stderr)
        self.assertEqual(path.read_text(), 'existing-IPC-key')

    def test_other_paths_exclusive_and_truncation_are_not_retried(self):
        ipc = self.folder / 'digilent-adept2-mtx-dvtbl'
        ipc.write_text('retained')
        other = self.folder / 'unrelated'
        other.write_text('retained')
        for path, flags in [(other, os.O_RDWR | os.O_CREAT),
                            (ipc, os.O_RDWR | os.O_CREAT | os.O_EXCL),
                            (ipc, os.O_RDWR | os.O_CREAT | os.O_TRUNC),
                            (ipc, os.O_RDONLY | os.O_CREAT)]:
            with self.subTest(path=path, flags=flags):
                result = self.probe(path, flags)
                self.assertEqual(result.returncode, 13)
                self.assertNotIn('COMPAT=ACTIVE', result.stderr)
                self.assertEqual(path.read_text(), 'retained')

    def test_symlink_fifo_and_missing_file_are_not_retried(self):
        path = self.folder / 'digilent-adept2-shm-dvtopn'
        target = self.folder / 'untouched'
        target.write_text('retained')
        path.symlink_to(target)
        self.assertEqual(self.probe(path).returncode, 13)
        path.unlink()
        os.mkfifo(path)
        self.assertEqual(self.probe(path).returncode, 13)
        path.unlink()
        self.assertEqual(self.probe(path).returncode, 13)
        self.assertFalse(path.exists())
        self.assertEqual(target.read_text(), 'retained')

    def test_private_server_env_and_cleanup_on_success_and_failure(self):
        tool_dir = self.folder / 'bin'
        tool_dir.mkdir(exist_ok=True)
        for name in ['vivado', 'hw_server']:
            path = tool_dir / name
            path.write_text('#!/bin/sh\nexit 0\n')
            path.chmod(0o700)
        compat = self.folder / 'existing_compat.so'
        compat.write_bytes(b'fixture')
        for status in [0, 1]:
            server = MagicMock()
            server.pid = 43569
            server.poll.return_value = None
            with patch.object(runner, 'COMPAT', compat), \
                 patch.object(runner.socket, 'socket') as sock, \
                 patch.object(runner.socket, 'create_connection'), \
                 patch.object(runner.os, 'killpg') as kill_group, \
                 patch.object(runner.subprocess, 'Popen', return_value=server) as start, \
                 patch.object(runner.subprocess, 'run') as run:
                sock.return_value.__enter__.return_value.getsockname.return_value = ('127.0.0.1', 43567)
                run.return_value.returncode = status
                result = runner.program(str(tool_dir / 'vivado'), self.folder / 'test.bit',
                                        self.folder / 'test.tcl', self.folder / 'logs/program.log')
                self.assertEqual(result, status)
                self.assertTrue(start.call_args.kwargs['env']['LD_PRELOAD'].startswith(str(compat)))
                self.assertTrue(start.call_args.kwargs['start_new_session'])
                self.assertFalse(any(arg.startswith('-I') for arg in start.call_args.args[0]),
                                 'Server must survive slow Vivado startup; finally owns cleanup')
                self.assertEqual(run.call_args.kwargs['env']['HW_SERVER_URL'], '127.0.0.1:43567')
                self.assertEqual(run.call_args.kwargs['env'].get('LD_PRELOAD'), os.environ.get('LD_PRELOAD'))
                self.assertEqual(kill_group.call_args_list,
                                 [unittest.mock.call(server.pid, signal.SIGTERM),
                                  unittest.mock.call(server.pid, signal.SIGKILL)])
                server.terminate.assert_not_called()
                server.wait.assert_any_call(timeout=5)

    def test_server_cleanup_on_startup_failure(self):
        tool_dir = self.folder / 'startup_bin'
        tool_dir.mkdir(exist_ok=True)
        for name in ['vivado', 'hw_server']:
            path = tool_dir / name
            path.write_text('#!/bin/sh\nexit 0\n')
            path.chmod(0o700)
        server = MagicMock()
        server.pid = 43570
        server.poll.return_value = 2
        with patch.object(runner, 'COMPAT', self.compat), \
             patch.object(runner.socket, 'socket') as sock, \
             patch.object(runner.os, 'killpg') as kill_group, \
             patch.object(runner.subprocess, 'Popen', return_value=server), \
             patch.object(runner.subprocess, 'run') as run:
            sock.return_value.__enter__.return_value.getsockname.return_value = ('127.0.0.1', 43568)
            with self.assertRaisesRegex(ValueError, 'exited before connection'):
                runner.program(str(tool_dir / 'vivado'), self.folder / 'test.bit',
                               self.folder / 'test.tcl', self.folder / 'startup/program.log')
            run.assert_not_called()
            server.terminate.assert_not_called()
            kill_group.assert_any_call(server.pid, signal.SIGTERM)

    def test_real_launcher_descendant_is_stopped_even_if_launcher_exited(self):
        # No hardware or installed tool is invoked. Reproduce the real Vivado
        # shell -> loader -> server lifetime with a disposable local process.
        for exited in [False, True]:
            with self.subTest(launcher_already_exited=exited):
                child_file = self.folder / ('child_' + str(exited))
                script = ('trap "" TERM\n'
                          'sleep 120 &\n'
                          'echo $! > "$1"\n' + ('exit 0\n' if exited else 'wait\n'))
                server = subprocess.Popen(['bash', '-c', script, 'fixture', str(child_file)],
                                          start_new_session=True)
                child = None
                try:
                    deadline = time.monotonic() + 3
                    while not child_file.exists() or not child_file.read_text().strip():
                        if time.monotonic() >= deadline:
                            self.fail('fixture did not start')
                        time.sleep(0.01)
                    child = int(child_file.read_text())
                    if exited:
                        server.wait(timeout=3)
                    # Exercise the escalation path without a five-second test.
                    real_wait = server.wait
                    with patch.object(server, 'wait', side_effect=lambda *a, **k:
                                      real_wait(timeout=0.1) if k else real_wait(*a)):
                        runner.stop(server)
                    deadline = time.monotonic() + 3
                    while True:
                        stat = Path('/proc') / str(child) / 'stat'
                        try:
                            exited = stat.read_text().split(') ')[1].split()[0] == 'Z'
                        except FileNotFoundError:
                            exited = True
                        if exited:
                            break
                        if time.monotonic() >= deadline:
                            self.fail('server descendant survived cleanup')
                        time.sleep(0.01)
                    self.assertIsNotNone(server.poll())
                finally:
                    try:
                        os.killpg(server.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                    server.wait()

    def test_shell_check_resolves_relative_bitstream_without_starting_tools(self):
        work = self.folder / 'check_only'
        (work / 'hardware').mkdir(parents=True)
        bit = work / 'hardware/test.bit'
        bit.write_bytes(b'fixture')
        invoked = work / 'tool_invoked'
        vivado = work / 'vivado'
        vivado.write_text('#!/bin/sh\ntouch "' + str(invoked) + '"\nexit 99\n')
        vivado.chmod(0o700)
        env = dict(os.environ, TCL_SCRIPT=str(ROOT / 'program/program_bitstream.tcl'),
                   LOG_FILE='check_logs/program.log')
        result = subprocess.run(['bash', str(ROOT / 'program/download_bitstream.sh'),
                                 '--vivado', str(vivado), '--bitstream', 'hardware/test.bit', '--check'],
                                cwd=work, env=env, text=True, capture_output=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('DOWNLOAD_BITSTREAM_CHECK=PASS', result.stdout)
        self.assertIn('BITSTREAM=' + str(bit), result.stdout)
        self.assertFalse(invoked.exists())
        self.assertFalse((work / 'check_logs').exists())


class BitstreamBinding(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='asram_bitstream_')
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.root = self.repo / 'sw/board_tests/asram'
        self.root.mkdir(parents=True)
        self.bit = self.repo / 'build/target.bit'
        self.bit.parent.mkdir()
        self.bit.write_bytes(b'ASRAM bitstream fixture, never programmed')
        self.manifest = dict(build_id='software_fixture', config=dict(target=dict(
            bitstream='build/target.bit', hardware_build_id='e037701c8d7cfc59',
            bitstream_sha256=hashlib.sha256(self.bit.read_bytes()).hexdigest())))

    def test_target_bitstream_command_and_receipt(self):
        with patch.object(package_program, 'ROOT', self.root), \
             patch.object(package_program, 'check', return_value=self.manifest), \
             patch.object(package_program.shutil, 'which', return_value='/fake/vivado'), \
             patch.object(package_program.subprocess, 'run') as run, \
             patch.object(sys, 'argv', ['program.py', 'bitstream', '--run', 'fixture']):
            self.assertEqual(package_program.main(), 0)
            command = run.call_args.args[0]
            self.assertEqual(command[1], str(self.root / 'program/download_bitstream.sh'))
            self.assertEqual(command[-2:], ['--bitstream', str(self.bit)])
            self.assertEqual(run.call_args.kwargs['env']['TCL_SCRIPT'],
                             str(self.root / 'program/program_bitstream.tcl'))
        receipt = json.loads((self.root / 'logs/fixture/bitstream.json').read_text())
        self.assertEqual(receipt['sha256'], self.manifest['config']['target']['bitstream_sha256'])
        self.assertEqual(receipt['hardware_build_id'], 'e037701c8d7cfc59')
        self.assertEqual(receipt, json.loads((self.root / 'logs/last_programmed_bitstream.json').read_text()))

    def test_wrong_bitstream_stops_before_tools(self):
        self.bit.write_bytes(b'Wrong build')
        with patch.object(package_program, 'ROOT', self.root), \
             patch.object(package_program, 'check', return_value=self.manifest), \
             patch.object(package_program.subprocess, 'run') as run, \
             patch.object(sys, 'argv', ['program.py', 'bitstream', '--run', 'fixture']):
            with self.assertRaisesRegex(ValueError, 'SHA-256 mismatch'):
                package_program.main()
            run.assert_not_called()
            self.assertFalse((self.root / 'logs').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
