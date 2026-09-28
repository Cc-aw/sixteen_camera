#!/usr/bin/env bash
set -euo pipefail
rtl=$1
# Only POSIX tools here: Vivado sources this through `exec bash` with its own
# environment, where ripgrep is not guaranteed to be on PATH.
mapfile -t memories < <(find "$rtl" -type f -name '*.top.mems.v' | sort)
test "${#memories[@]}" -eq 1
memory=${memories[0]}
temp=$(mktemp "$rtl/result_bram.XXXXXX")
trap 'test ! -f "$temp" || unlink "$temp"' EXIT
# POSIX awk only: gawk's three-argument match() is unavailable under mawk,
# which is the default /usr/bin/awk on Debian and Ubuntu build hosts.
awk '
  match($0, /reg \[[0-9]+:0\] ram \[0:511\]/) {
    width = substr($0, RSTART, RLENGTH)
    sub(/^reg \[/, "", width)
    sub(/:0\] ram \[0:511\]$/, "", width)
    # INT24 mesh results plus metadata produce a 200-bit result-buffer row.
    if (width + 0 == 199) {
      if ($0 !~ /ram_style/) sub(/reg /, "(* ram_style = \"block\" *) reg ")
      count++
    }
  }
  {print}
  END {if (count != 1) exit 2}
' "$memory" > "$temp"
mv "$temp" "$memory"
printf 'RESULT_BUFFER_BRAM=PASS\n'
