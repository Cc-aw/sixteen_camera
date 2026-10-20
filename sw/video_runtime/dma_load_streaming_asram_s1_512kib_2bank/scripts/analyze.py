#!/usr/bin/env python3
"""Check live board sample completion, ownership and per-stream evidence."""
from pathlib import Path
import json,sys
from run_board import sample_result
log=Path(sys.argv[1]);result=sample_result([s.strip() for s in log.read_text(errors='replace').splitlines()])
if result is None:raise SystemExit('S1RT_ANALYSIS=FAIL_OR_INCOMPLETE log='+str(log))
print(json.dumps(result,indent=2));print('S1RT_ANALYSIS=PASS')
