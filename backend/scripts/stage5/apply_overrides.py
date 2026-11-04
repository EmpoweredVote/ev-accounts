"""Apply overrides.json trims to research.csv (reasoning only; never a stance or value). STAGE5 step 7.9.
python3 -I scripts/stage5/apply_overrides.py <batch dir> [--file <overrides file>] [--skip-changed]
overrides.json: {"trims": [{"name": "<full_name>", "removed": "<exact words>", "now": "<new words>", "why": "..."}]}
Each "removed" must be in that row's reasoning, or the run stops. Log -> overrides-applied.json.
--skip-changed: trims run in file order, and a trim whose words are no longer there (an earlier trim already changed
them) is skipped and reported instead of stopping the run. Log -> {"applied": [...], "skipped": [...]}. Read the
skipped list: a skip is right only when an earlier trim covers the same words."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, positional
import csv, json
B = positional(1, 'apply_overrides.py <batch dir> [--file <overrides file>] [--skip-changed]')[0]
O = json.load(open(opt('--file', f'{B}/overrides.json')))
rows = list(csv.DictReader(open(f'{B}/research.csv'))); cols = list(rows[0].keys()); log = []
if '--skip-changed' in sys.argv:
    by, skipped = {}, []
    for r in rows: by.setdefault(r['full_name'], []).append(r)
    for t in O['trims']:
        hit = False
        for r in by.get(t['name'], []):
            if t['removed'] in r['reasoning']: r['reasoning'] = r['reasoning'].replace(t['removed'], t['now']); hit = True
        (log if hit else skipped).append(['trim', t['name'], t['removed']])
    out = {'applied': log, 'skipped': skipped}
else:
    for r in rows:
        for t in O['trims']:
            if t['name'] == r['full_name']:
                assert t['removed'] in r['reasoning'], t; r['reasoning'] = r['reasoning'].replace(t['removed'], t['now']); log.append(['trim', r['full_name'], t['removed']])
    out = log
w = csv.DictWriter(open(f'{B}/research.csv', 'w', newline=''), fieldnames=cols); w.writeheader(); w.writerows(rows)
json.dump(out, open(f'{B}/overrides-applied.json', 'w'), indent=1)
print('applied', len(log), 'skipped', len(out['skipped'])) if isinstance(out, dict) else print('applied', len(log))
