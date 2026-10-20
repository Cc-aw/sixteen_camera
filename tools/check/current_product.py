"""Repository-local paths shared by the default S1 build and checks."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'hw/manifests/current.json'


def product():
    return json.loads(MANIFEST.read_text())


def local_path(relative):
    path = (ROOT / relative).resolve()
    if Path(relative).is_absolute() or ROOT not in path.parents:
        raise ValueError('Nonlocal product path: ' + relative)
    return path


def sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()
