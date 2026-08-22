#!/bin/sh
# The workspace provides a read-only .git mount. Keep project history in
# .git-local and expose normal Git commands through this small wrapper.
project_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec git --git-dir="$project_root/.git-local" --work-tree="$project_root" "$@"
