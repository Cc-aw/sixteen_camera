"""Annotate only native WS-helper/caller waits with no intervening command."""
from pathlib import Path
import json
import re
from fixed_plans import graph_stages

STAGES = (14, 33, 57, 71, 79, 85, 93, 99, 107, 118, 130, 141, 153)
SITES_PER_WORKER = len(STAGES)
BASELINE_WAITS = 1062


def annotate(model, plans):
    stages = graph_stages(model)
    sites = []
    replacements = []
    for stage in STAGES:
        plan = plans.get(str(stage))
        if (plan is None or not plan['helper'].startswith('gemmini_splitk_') or
                not plan['steps'] or plan['steps'][-1] != [3, 0] or plan['packets'] <= 0):
            raise ValueError(f'No final native WS completion at stage {stage}')
        body = stages[stage]
        # Exact, unconditional adjacency: no profile helper, branch, command,
        # or other call is permitted between the final helper and caller wait.
        pattern = (r'(yolo32_prepared_ws\(&prepared_ws_plan_' + str(stage) +
                   r',\s*\(const void \*const\[10\]\)\{[^{};]+\}\);)' +
                   r'(\s*)gemmini_fence\(\);')
        matches = list(re.finditer(pattern, body))
        if len(matches) != 1 or model.count(matches[0][0]) != 1:
            raise ValueError(f'WS/caller wait adjacency changed at stage {stage}')
        match = matches[0]
        prefix = re.sub(r'/\*.*?\*/|//[^\n]*|"(?:\\.|[^"\\])*"',
                        lambda m: ' '*len(m[0]), body[:match.start()], flags=re.S)
        if re.search(r'\b(if|for|while|switch|goto)\b', prefix):
            raise ValueError(f'Conditional WS/caller wait at stage {stage}')
        replacement = match[1] + match[2] + f'yolo32_reused_fence({stage}U);'
        replacements.append((match[0], replacement))
        sites.append(dict(stage=stage, helper=plan['helper'],
                          final_step=len(plan['steps'])-1,
                          proof='final native local wait; no intervening call'))
    for old, new in replacements:
        model = model.replace(old, new, 1)
    return model, sites


def bake(out: Path, model):
    manifest = json.loads((out/'fixed_plans.json').read_text())
    external_waits=sum(body.count('gemmini_fence();') for body in graph_stages(model).values())
    helper_waits=sum(sum(kind==3 for kind,index in plan['steps'])
                     for plan in manifest['prepared_ws'].values())
    if 3*(external_waits+helper_waits)!=BASELINE_WAITS:
        raise ValueError('Native wait count changed; audit the wait reuse plan')
    model, sites = annotate(model, manifest['prepared_ws'])
    (out/'wait_reuse.json').write_text(json.dumps(dict(
        sites=sites, sites_per_worker=SITES_PER_WORKER,
        external_waits_per_worker=external_waits, helper_waits_per_worker=helper_waits,
        baseline_batch_waits=BASELINE_WAITS,
        expected_batch_waits=BASELINE_WAITS-3*SITES_PER_WORKER), indent=2)+'\n')
    with (out/'fixed_plans_guard.inc').open('a') as guard:
        guard.write('_Static_assert(YOLO32_WAIT_REUSE == 1, "Annotated graph requires wait reuse build");\n')
    return model
