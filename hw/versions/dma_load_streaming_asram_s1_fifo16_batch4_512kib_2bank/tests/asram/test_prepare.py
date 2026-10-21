#!/usr/bin/env python3
"""Exercise real private-copy preparation without compiling a SoC."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile

FEATURE = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('dma_variant_generator', FEATURE / 'scripts/build_soc.py')
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


def main():
    with tempfile.TemporaryDirectory(prefix='dma-hw-source-prepare-') as directory:
        fixture = Path(directory)
        reference, workspace = fixture / 'reference', fixture / 'workspace'
        for relative in ('build.sbt', 'fpga/Makefile',
                         'generators/rocket-chip/src/main/scala/tile/LazyRoCC.scala',
                         'generators/gemmini/src/main/scala/gemmini/Placeholder.scala'):
            path = reference / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('// minimal prepare-only reference\n')

        def run(*args, success=True):
            result = subprocess.run([sys.executable, '-B', str(FEATURE / 'scripts/build_soc.py'),
                                     '--workspace', str(workspace), *args], capture_output=True, text=True)
            assert (result.returncode == 0) == success, result.stdout + result.stderr
            return result

        run('--reference', str(reference), '--prepare-only')
        run('--validate-workspace-only')
        config = workspace / 'fpga/src/main/scala/xcvu13p_gemmini_32x32_packed_inference_ram/Configs.scala'
        assert config.read_bytes() == (FEATURE / 'command_frontend/integration' /
                                      config.relative_to(workspace)).read_bytes()
        # Checking a source-modified workspace must reject it before elaboration.
        original = config.read_bytes()
        config.write_bytes(original + b'// stale overlay\n')
        assert 'Stale generation workspace source' in run('--validate-workspace-only', success=False).stderr
        config.write_bytes(original)
        build = workspace / 'build.sbt'
        original_build = build.read_bytes()
        build.write_bytes(original_build + b'// changed source filters\n')
        assert 'build.sbt changed' in run('--validate-workspace-only', success=False).stderr
        build.write_bytes(original_build)
        marker = workspace / '.triple32-v3-tensor.json'
        prepared = marker.read_text()
        wrong = json.loads(prepared)
        wrong['hardware_variant'] = 'other_variant'
        marker.write_text(json.dumps(wrong))
        assert 'different hardware variant' in run('--validate-workspace-only', success=False).stderr
        marker.write_text(prepared)
        run('--reference', str(reference), '--prepare-only', success=False)
        assert (reference / 'build.sbt').read_text() == '// minimal prepare-only reference\n'
        generator.validate_workspace_sources(workspace)
        protected = subprocess.run([sys.executable, '-B', str(FEATURE / 'scripts/build_soc.py'),
                                    '--workspace', str(FEATURE / 'workspace'), '--prepare-only',
                                    '--reference', str(reference)], capture_output=True, text=True)
        assert protected.returncode != 0 and 'outside hw/soc and hw/versions' in protected.stderr
    print('DMA_LOAD_PREPARE_FIXTURE=PASS overlays=local frontend_precedence=PASS stale_rejected=1 '
          'build_filters_rejected=1 wrong_variant_rejected=1 overwrite_rejected=1 '
          'protected_path_rejected=1 reference_unchanged=1 rtl_generated=0')


if __name__ == '__main__':
    main()
