#!/usr/bin/env python3
"""Explicit operator-only board operations; preflight never opens hardware."""
import argparse
import datetime
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

from package import ROOT, BUILD, ELFS, check, local, sha, write_json


def tool(name, default):
    value = os.environ.get(name) or default
    if not shutil.which(value):
        raise ValueError('Missing tool ' + name + ': ' + value + '; configure config.local.mk')
    return value


def run_directory(label):
    if not re.fullmatch(r'[A-Za-z0-9_-]+', label):
        raise ValueError('Run label must use letters, numbers, underscore or hyphen')
    path = ROOT / 'logs' / label
    path.mkdir(parents=True, exist_ok=True)
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('preflight', 'bitstream', 'load', 'uart'))
    parser.add_argument('--test', choices=ELFS, default='smoke')
    parser.add_argument('--run', default=datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
    parser.add_argument('--port', default='/dev/ttyACM0')
    parser.add_argument('--bitstream', type=Path, help='Optional baseline bitstream copied inside this directory')
    args = parser.parse_args()
    if args.action == 'uart':
        directory = run_directory(args.run)
        log = directory / (args.test + '.log')
        if log.exists():
            raise ValueError('Existing UART log retained; use a new RUN label')
        print('UART_LOG=' + str(log), flush=True)
        print('Exit with Ctrl+T then Q; finish capture before parsing.', flush=True)
        return subprocess.call([tool('TIO_BIN', 'tio'), '-b', '115200', '-d', '8', '-s', '1',
                                '-p', 'none', '-f', 'none', '-l', str(log), args.port])
    manifest = check()
    env = dict(os.environ)
    env['OPENOCD_CFG'] = str(ROOT / 'program/openocd/openocd-bscan.cfg')
    env['TCL_SCRIPT'] = str(ROOT / 'program/program_bitstream.tcl')
    if args.action == 'preflight':
        vivado = tool('VIVADO_BIN', 'vivado')
        tool('OPENOCD_BIN', 'openocd'); tool('GDB_BIN', 'riscv64-unknown-elf-gdb')
        subprocess.run(['bash', str(ROOT / 'program/download_bitstream.sh'), '--check',
                        '--vivado', vivado, '--bitstream', str(ROOT / manifest['target']['bitstream'])], env=env, check=True)
        for test, name in ELFS.items():
            env['ELF_FILE'] = str(BUILD / name)
            subprocess.run(['bash', str(ROOT / 'program/run_firmware.sh'), '--check', '--no-build'], env=env, check=True)
        print('L2_BOARD_PREFLIGHT=PASS board_accessed=0')
        return 0
    directory = run_directory(args.run)
    if args.action == 'bitstream':
        bit = local(args.bitstream) if args.bitstream else ROOT / manifest['target']['bitstream']
        if not bit.is_file():
            raise ValueError('Missing local bitstream: ' + str(bit))
        receipt = directory / 'bitstream.json'
        if receipt.exists():
            raise ValueError('Existing bitstream receipt retained; choose a new RUN label')
        env['LOG_FILE'] = str(directory / 'vivado_program.log')
        subprocess.run(['bash', str(ROOT / 'program/download_bitstream.sh'), '--vivado',
                        tool('VIVADO_BIN', 'vivado'), '--bitstream', str(bit)], env=env, check=True)
        record = dict(schema=1, file=str(bit.relative_to(ROOT)), sha256=sha(bit), run=args.run,
                      programmed_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                      identity='Host programming receipt; not a software-readable bitstream fingerprint')
        write_json(receipt, record)
        write_json(ROOT / 'logs/last_programmed_bitstream.json', record)
        return 0
    receipt = directory / (args.test + '.load.json')
    if receipt.exists():
        raise ValueError('Existing ELF receipt retained; use a new RUN label')
    env['ELF_FILE'] = str(BUILD / ELFS[args.test])
    env['OPENOCD_LOG'] = str(directory / (args.test + '.openocd.log'))
    subprocess.run(['bash', str(ROOT / 'program/run_firmware.sh'), '--no-build'], env=env, check=True)
    bit_receipt = ROOT / 'logs/last_programmed_bitstream.json'
    bit = None
    if bit_receipt.exists():
        import json
        bit = json.loads(bit_receipt.read_text())
    record = dict(schema=1, test=args.test, build_id=manifest['build_id'],
                  elf_sha256=sha(BUILD / ELFS[args.test]), bitstream=bit,
                  loaded_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
    write_json(receipt, record)
    print('L2_BOARD_ELF_STARTED=' + args.test + ' UART capture must run in another terminal')
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as error:
        print('L2_BOARD_PROGRAM=FAIL child_exit=' + str(error.returncode) + '; see the run logs above', file=sys.stderr)
        raise SystemExit(error.returncode)
    except (OSError, ValueError) as error:
        print('L2_BOARD_PROGRAM=FAIL ' + str(error), file=sys.stderr)
        raise SystemExit(1)
