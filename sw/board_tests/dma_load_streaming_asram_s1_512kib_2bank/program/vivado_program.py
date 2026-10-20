#!/usr/bin/env python3
"""Program through an owned, short-lived hw_server with local Adept compatibility."""
import argparse
import os
from pathlib import Path
import shutil
import signal
import socket
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
COMPAT = ROOT / 'build/program/libdigilent_ipc_compat.so'


def stop(server):
    # Vivado's hw_server entry point launches a loader and a real server child.
    # Killing only Popen's PID leaves that child holding the cable. The child
    # may also survive an already-exited loader, so do not gate this on poll().
    try:
        os.killpg(server.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        server.wait(timeout=5)
    except subprocess.TimeoutExpired:
        pass
    finally:
        # Finish any descendants that did not exit with the launcher. This
        # group belongs solely to the session created below, never the caller.
        try:
            os.killpg(server.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    server.wait()


def program(vivado, bitstream, tcl, log):
    executable = shutil.which(vivado)
    if executable is None:
        raise ValueError('Vivado not found: ' + vivado)
    hw_server = Path(executable).resolve().with_name('hw_server')
    if not hw_server.is_file() or not os.access(hw_server, os.X_OK):
        raise ValueError('Missing hw_server beside Vivado: ' + str(hw_server))
    if not COMPAT.is_file():
        raise ValueError('Missing local JTAG compatibility library; run make all')
    log = Path(log).resolve()
    log.parent.mkdir(parents=True, exist_ok=True)
    server_log = log.with_name('hw_server.log')
    adept_log = log.with_name('digilent_adept.log')
    with socket.socket() as listener:
        listener.bind(('127.0.0.1', 0))
        port = listener.getsockname()[1]
    server_env = dict(os.environ)
    server_env['LD_PRELOAD'] = str(COMPAT) + (':' + server_env['LD_PRELOAD'] if server_env.get('LD_PRELOAD') else '')
    server_env['ADEPT_RT_LOGFILE'] = str(adept_log)
    server_env['ADEPT_RT_LOGDETAIL'] = '1'
    client_env = dict(os.environ)
    client_env['HW_SERVER_URL'] = f'127.0.0.1:{port}'
    client_env['BITSTREAM_FILE'] = str(Path(bitstream).resolve())
    print('JTAG_SERVER=' + client_env['HW_SERVER_URL'] + ' private=1', flush=True)
    print('JTAG_SERVER_LOG=' + str(server_log), flush=True)
    with server_log.open('w') as output:
        # Vivado can take several minutes to load on a memory-constrained
        # host. An idle timeout starts before Vivado connects and can kill the
        # private server during startup. Its lifetime is owned by finally.
        server = subprocess.Popen([str(hw_server), f'-stcp:127.0.0.1:{port}', '-p0'],
                                  env=server_env, stdout=output, stderr=subprocess.STDOUT,
                                  start_new_session=True)
        try:
            deadline = time.monotonic() + 30
            while True:
                if server.poll() is not None:
                    raise ValueError('hw_server exited before connection; see ' + str(server_log))
                try:
                    with socket.create_connection(('127.0.0.1', port), timeout=0.2):
                        break
                except OSError:
                    if time.monotonic() >= deadline:
                        raise ValueError('hw_server startup timed out; see ' + str(server_log))
                    time.sleep(0.1)
            result = subprocess.run([executable, '-mode', 'batch', '-log', str(log), '-source', str(tcl)],
                                    env=client_env, cwd=log.parent)
            if result.returncode:
                print('JTAG_DOWNLOAD=FAIL log=' + str(log) + ' server_log=' + str(server_log) +
                      ' server_exit_code=' + str(server.poll()), file=sys.stderr)
            return result.returncode
        finally:
            stop(server)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--vivado', required=True)
    parser.add_argument('--bitstream', required=True, type=Path)
    parser.add_argument('--tcl', required=True, type=Path)
    parser.add_argument('--log', required=True, type=Path)
    args = parser.parse_args()
    # Preserve the same cleanup path when the caller terminates the download.
    def terminated(signum, _frame):
        raise SystemExit(128 + signum)
    signal.signal(signal.SIGTERM, terminated)
    try:
        return program(args.vivado, args.bitstream, args.tcl, args.log)
    except (OSError, ValueError) as error:
        print('JTAG_DOWNLOAD=FAIL ' + str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
