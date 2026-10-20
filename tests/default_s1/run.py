#!/usr/bin/env python3
"""Check default selection and S1 project closure without accessing the board."""
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/check'))
from check_current_product import validate

p = json.loads((ROOT / 'hw/manifests/current.json').read_text())
validate(p)
for key, value in [('hardware_alias', 'triple32_v3_tensor'),
                   ('hardware_build_id', '0000000000000000'),
                   ('l2', dict(banks=4, capacity_bytes=1048576)),
                   ('video_elf', 'build/firmware/video/video.elf')]:
    wrong = copy.deepcopy(p)
    wrong[key] = value
    try:
        validate(wrong)
    except ValueError:
        pass
    else:
        raise AssertionError('Accepted mismatched default: ' + key)

hw = ROOT / p['hardware_directory']
script = 'source {%s}\nputs [join $RTL_SOURCES "\\n"]\n' % (hw / 'manifests/donor/rtl_manifest.tcl')
declared = subprocess.check_output(['tclsh'], input=script, text=True).splitlines()
assert len(declared) == 123
(hw / 'build').mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='default_inputs_', dir=hw / 'build') as folder:
    subprocess.run([sys.executable, '-B', str(hw / 'scripts/project_inputs.py'), '--output', folder], check=True)
    text = (Path(folder) / 'version_inputs.tcl').read_text()
    paths = [Path(value) for value in re.findall(r'\{([^{}]+)\}', text)]
    board = [path for path in paths if hw / 'board/rtl' in path.parents]
    assert board == [hw / 'board' / name for name in declared], 'Reconstruction differs from Tcl manifest'
    assert all(path.is_file() for path in paths)
    assert all(hw in path.parents or Path(folder) in path.parents for path in paths)
    assert sum(path.suffix == '.xdc' for path in paths) == 6
    assert sum(path.suffix == '.xci' for path in paths) == 10

for target in ['program', 'program-bitstream', 'board-live', 'board-run']:
    output = subprocess.check_output(['make', '--no-print-directory', '-n', target,
                                      'RUN=default_dry_run', 'PORT=/dev/not-opened'], cwd=ROOT, text=True)
    assert p['software_directory'] in output and 'default_dry_run' in output
    assert 'build/firmware/video/video.elf' not in output
    if target.startswith('board-'):
        assert '--port /dev/not-opened' in output
    if target == 'board-live':
        assert '--live' in output

# Exercise build sequencing with a Tcl command mock; no Vivado process is run.
mock = r'''
proc open_project {args} {}
proc close_project {} {}
proc get_files {args} {
    if {[string match *top_wrapper.sv [lindex $args end]]} {
        return [file join $::env(S1_HARDWARE_DIRECTORY) board rtl top_wrapper.sv]
    }
    return [file join $::env(S1_HARDWARE_DIRECTORY) generated gen-collateral TaihangSoCFPGATestHarness.sv]
}
proc get_runs {run} {return $run}
array set status {synth_1 {Not started} impl_1 {Not started}}
proc get_property {name run} {
    if {$name eq "STATUS"} {return $::status($run)}
    if {$name eq "DIRECTORY"} {return /tmp/s1_mock_output}
    error "Unexpected property $name"
}
proc synth_design {args} {puts ELABORATED}
proc launch_runs {run args} {
    puts "LAUNCH:$run:$args"
    if {$run eq "synth_1"} {set ::status($run) {synth_design Complete!}}
    if {$run eq "impl_1"} {set ::status($run) {write_bitstream Complete!}}
    if {$::inject_failure} {set ::status($run) {ERROR}}
}
proc wait_on_run {args} {}
'''
for stage in ['elaborate', 'synth', 'bitstream']:
    for failure in ([False, True] if stage != 'elaborate' else [False]):
        env = dict(os.environ, S1_BUILD_PROJECT='/tmp/s1_mock.xpr',
                   S1_HARDWARE_DIRECTORY=str(hw), S1_BUILD_STAGE=stage, S1_BUILD_JOBS='2')
        script = ('set inject_failure %d\n' % failure) + mock
        script += '\nif {[catch {source {%s}} message]} {puts stderr $message; exit 1}\n' % (ROOT / 'tools/build/build_s1.tcl')
        result = subprocess.run(['tclsh'], input=script, text=True, capture_output=True, env=env)
        assert (result.returncode != 0) == failure, result.stderr
        if stage == 'bitstream' and not failure:
            assert 'LAUNCH:impl_1:-to_step write_bitstream -jobs 2' in result.stdout
spec = importlib.util.spec_from_file_location('s1_source_lock', hw / 'scripts/lock.py')
source_lock = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source_lock)
with tempfile.TemporaryDirectory(prefix='s1_source_lock_') as folder:
    root = Path(folder)
    (root / 'source').mkdir()
    (root / 'source/input.txt').write_bytes(b'input')
    for name in ['build', 'validation', 'bitstream', '.Xil', '__pycache__']:
        (root / name).mkdir()
        # Ignored outputs may contain arbitrary symlinks and must never be audited.
        (root / name / 'ignored').symlink_to(root / 'source/input.txt')
    source_lock.ROOT = root
    assert source_lock.files() == {'source/input.txt': hashlib.sha256(b'input').hexdigest()}
    (root / 'source/alias').symlink_to(root / 'source/input.txt')
    try:
        source_lock.files()
    except ValueError:
        pass
    else:
        raise AssertionError('Source symlink accepted')
print('DEFAULT_S1_REGRESSION=PASS selection_mismatches=4 board_rtl=123 ip=10 xdc=6 download_routes=4 build_sequences=5 source_lock_pruning=PASS board_accessed=0')
