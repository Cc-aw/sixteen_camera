#!/usr/bin/env python3
"""Preserve the initial worktree and decision policy in a new run root."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[4]
FEATURE = Path(__file__).resolve().parents[1]


def freeze(out):
    out.mkdir(parents=True, exist_ok=False)

    def git(*args):
        return subprocess.check_output(['git', '-C', str(ROOT), *args])

    (out / 'repo_head.txt').write_bytes(git('rev-parse', 'HEAD'))
    (out / 'git_status.txt').write_bytes(git('status', '--short'))
    (out / 'dirty.patch').write_bytes(git('diff', '--binary', 'HEAD'))
    manifest = {}
    names = git('ls-files', '--modified', '--others', '--exclude-standard', '-z').decode().split('\0')
    for name in filter(None, names):
        source = ROOT / name
        if source.is_file():
            target = out / 'initial_files' / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
            manifest[name] = hashlib.sha256(source.read_bytes()).hexdigest()
    (out / 'initial_worktree_sha256.json').write_text(json.dumps(manifest, indent=2) + '\n')
    shutil.copyfile(FEATURE / 'manifests/decision_policy.json', out / 'decision_policy.json')
    print('CSC_R1_WORKTREE_FROZEN', out)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    freeze(args.output.resolve())
