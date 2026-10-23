"""Read the selected generated RTL without rewriting production modules."""
from pathlib import Path
import re


def ports(path):
    header = re.sub(r'//[^\n]*', '', path.read_text().split(');', 1)[0])
    return re.findall(r'^\s*(input|output)\s+(\[[^]]+\]\s*)?(\w+)\s*[,\n]', header, re.M)


def module_closure(rtl, roots):
    mapping = {}
    contents = {}
    for path in Path(rtl).rglob('*'):
        if path.suffix not in ('.v', '.sv'):
            continue
        contents[path] = path.read_text()
        for name in re.findall(r'^module\s+(\w+)', contents[path], re.M):
            mapping[name] = path
    seen = set()

    def visit(name):
        path = mapping[name]
        if path in seen:
            return
        seen.add(path)
        for dep in re.findall(r'^\s*(\w+)\s+(?:#\s*\(|\w+\s*\()', contents[path], re.M):
            if dep in mapping:
                visit(dep)

    for name in roots:
        visit(name)
    return sorted(seen)
