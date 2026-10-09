#!/usr/bin/env python3
"""Check the actual generated FBus coupling, not unrelated AXI adapters."""
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
coupler = (root / 'TLInterconnectCoupler_fbus_from_port_named_slave_port_axi4.sv').read_text()
def instance(name):
    match = re.search(r'^  (\w+) ' + name + r' \(', coupler, re.M)
    if not match:
        raise SystemExit(f'Missing FBus instance {name}')
    return (root / (match[1] + '.sv')).read_text()

def require(pattern, text, message):
    if not re.search(pattern, text):
        raise SystemExit(message)

require(r'input\s+\[255:0\]\s+auto_tl_out_d_bits_data', coupler,
        'FBus return path must remain 256-bit')
require(r'input\s+\[4:0\]\s+auto_axi4index_in_ar_bits_id', coupler,
        'FBus external ID width must be five bits')
indexer = instance('axi4index')
converter = instance('axi42tl')
require(r'assign auto_out_ar_bits_id = auto_in_ar_bits_id;', indexer,
        'FBus must preserve all five AXI ID bits')
require(r'output\s+\[6:0\]\s+auto_out_a_bits_source', converter,
        'FBus must retain seven TL source bits')
for group in range(32):
    require(r'reg\s+\[1:0\]\s+r_count_' + str(group) + r';', converter,
            f'Missing two-source read counter for group {group}')
print('FBUS_ID_GROUPS=PASS groups=32 read_sources_per_group=2 total_read_sources=64 fbus_bits=256')
