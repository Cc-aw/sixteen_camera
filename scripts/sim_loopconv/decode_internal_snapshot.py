#!/usr/bin/env python3
"""Summarize each ABI9 DBG page/data dump in a saved UART log."""
import re
import sys
from pathlib import Path


def decode(pages):
    if pages.get(0) != 0x4442475f00090050:
        raise ValueError('Expected diagnostic ABI9 signature')
    missing = set(range(80)) - pages.keys()
    if missing:
        raise ValueError(f'Incomplete snapshot, missing pages: {sorted(missing)}')
    names = ['LD bias', 'LD input', 'LD weight', 'EX', 'ST']
    print(f'accepted={pages[73]} retired={pages[74]} no_progress={pages[72] >> 32}')
    for slot in range(2):
        v = pages[slot + 2]
        running, configured = (v >> 33) & 1, (v >> 32) & 1
        started, completed = (v >> 34) & 31, (v >> 39) & 31
        if running or configured:
            waiting = [name for i, name in enumerate(names) if started >> i & 1 and not completed >> i & 1]
            not_started = [name for i, name in enumerate(names) if not started >> i & 1]
            print(f'slot{slot} seq={v & 0xffffffff} running={running}: started-but-incomplete={waiting}; not-started={not_started}')
    for name, page in [('LD', 76), ('ST', 77)]:
        v = pages[page]
        valid = v >> 48
        print(f'{name} DMA tracker valid_mask=0x{valid:x}', end='')
        if valid:
            print(f' slot={(v >> 40) & 255} ROB={(v >> 32) & 255} remaining_bytes={(v >> 8) & 0xffffff}', end='')
        print(f' completion_valid={(v >> 2) & 1} ready={(v >> 1) & 1}')
    v = pages[64]
    print(f'EX future_rows={v >> 48} buffered_results={(v >> 32) & 65535} completion_pending={(v >> 6) & 1} writeback_idle={(v >> 5) & 1} completion_ROB={(v >> 8) & 255}')
    for name, page in [('mesh-last / write-last', 66), ('write-completion / all-EX-completion', 67), ('Scale-in / Scale-out', 70)]:
        print(f'{name}: {pages[page] >> 32} / {pages[page] & 0xffffffff}')
    if pages[61] >> 63:
        print(f'Scale first fault: reason=0x{(pages[61] >> 48) & 255:x} lane={(pages[61] >> 40) & 255} fired=0x{pages[59]:016x} completed=0x{pages[60]:016x} fault_lanes=0x{pages[62]:016x} cycle={pages[63]}')
    for name, page in [('LD', 54), ('EX', 56), ('ST', 58)]:
        v = pages[page]
        print(f'RS {name} selected blocked entry dependency masks: LD=0x{v & 65535:04x} EX=0x{(v >> 16) & 0xffffffff:08x} ST=0x{(v >> 48) & 255:02x} (identity page {page - 1})')
    print('等待位置不等于根因；结合完整页中的 valid/身份/依赖信息判断。')


if __name__ == '__main__':
    pages = {}
    count = 0
    for line in Path(sys.argv[1]).read_text(errors='replace').splitlines():
        match = re.search(r'DBG page/data=(0x[0-9a-fA-F]+)\s*/\s*(0x[0-9a-fA-F]+)', line)
        if not match:
            continue
        page, value = (int(x, 16) for x in match.groups())
        if page == 0 and pages:
            decode(pages)
            count += 1
            pages = {}
        pages[page] = value
    if pages:
        decode(pages)
        count += 1
    if not count:
        raise SystemExit('No DBG page/data snapshot found')
