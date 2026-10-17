#!/usr/bin/env python3
"""Offline regression for Adept IPC compatibility and owned server cleanup."""
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import MagicMock, patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('vivado_program', ROOT / 'program/vivado_program.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)

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
            server.poll.return_value = None
            with patch.object(runner, 'COMPAT', compat), \
                 patch.object(runner.socket, 'socket') as sock, \
                 patch.object(runner.socket, 'create_connection'), \
                 patch.object(runner.subprocess, 'Popen', return_value=server) as start, \
                 patch.object(runner.subprocess, 'run') as run:
                sock.return_value.__enter__.return_value.getsockname.return_value = ('127.0.0.1', 43567)
                run.return_value.returncode = status
                result = runner.program(str(tool_dir / 'vivado'), self.folder / 'test.bit',
                                        self.folder / 'test.tcl', self.folder / 'logs/program.log')
                self.assertEqual(result, status)
                self.assertTrue(start.call_args.kwargs['env']['LD_PRELOAD'].startswith(str(compat)))
                self.assertEqual(run.call_args.kwargs['env']['HW_SERVER_URL'], '127.0.0.1:43567')
                self.assertEqual(run.call_args.kwargs['env'].get('LD_PRELOAD'), os.environ.get('LD_PRELOAD'))
                server.terminate.assert_called_once()
                server.wait.assert_called_once_with(timeout=5)

    def test_server_cleanup_on_startup_failure(self):
        tool_dir = self.folder / 'startup_bin'
        tool_dir.mkdir(exist_ok=True)
        for name in ['vivado', 'hw_server']:
            path = tool_dir / name
            path.write_text('#!/bin/sh\nexit 0\n')
            path.chmod(0o700)
        server = MagicMock()
        server.poll.return_value = 2
        with patch.object(runner, 'COMPAT', self.compat), \
             patch.object(runner.socket, 'socket') as sock, \
             patch.object(runner.subprocess, 'Popen', return_value=server), \
             patch.object(runner.subprocess, 'run') as run:
            sock.return_value.__enter__.return_value.getsockname.return_value = ('127.0.0.1', 43568)
            with self.assertRaisesRegex(ValueError, 'exited before connection'):
                runner.program(str(tool_dir / 'vivado'), self.folder / 'test.bit',
                               self.folder / 'test.tcl', self.folder / 'startup/program.log')
            run.assert_not_called()
            server.terminate.assert_not_called()

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


if __name__ == '__main__':
    unittest.main(verbosity=2)
