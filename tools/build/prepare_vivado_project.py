#!/usr/bin/env python3
"""Stage the XPR, BD and IP inputs before Vivado opens the build project."""
from pathlib import Path
import argparse
import shutil
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--work-dir', type=Path, required=True)
    work = parser.parse_args().work_dir.resolve()
    # Vivado can put its bundled Python 3.8 first in PATH.
    try:
        work.relative_to(ROOT / 'build')
    except ValueError:
        parser.error('Working project must be inside build/')
    work.mkdir(parents=True, exist_ok=True)
    template = ROOT / 'hw/vivado'
    bd = work / 'sixteen_camera.srcs'
    if not bd.exists():
        shutil.copytree(template / 'sixteen_camera.srcs', bd)
    ip = work / 'ip'
    if not ip.exists():
        shutil.copytree(ROOT / 'hw/ip', ip)
    tree = ET.parse(template / 'sixteen_camera.xpr')
    tree.getroot().set('Path', str(work / 'sixteen_camera.xpr'))
    for element in tree.iter():
        for key, value in list(element.attrib.items()):
            if '$PPRDIR/../ip/' in value:
                value = value.replace('$PPRDIR/../ip/', '$PPRDIR/ip/')
            for folder in ['rtl', 'soc', 'constraints']:
                value = value.replace(f'$PPRDIR/../{folder}/', str(ROOT / 'hw' / folder) + '/')
            element.set(key, value)
    tree.write(work / 'sixteen_camera.xpr', encoding='UTF-8', xml_declaration=True)
    print(f'VIVADO_WORK_PROJECT={work / "sixteen_camera.xpr"}')


if __name__ == '__main__':
    main()
