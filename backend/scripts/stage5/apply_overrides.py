"""Apply overrides.json trims to research.csv (reasoning only; never a stance or value). STAGE5 step 7.9.
python3 -I scripts/stage5/apply_overrides.py <batch dir>
overrides.json: {"trims": [{"name": "<full_name>", "removed": "<exact words>", "now": "<new words>", "why": "..."}]}
Each "removed" must be in that row's reasoning, or the run stops. Log -> overrides-applied.json."""
import csv, json, sys
B = sys.argv[1]; O = json.load(open(f'{B}/overrides.json'))
rows = list(csv.DictReader(open(f'{B}/research.csv'))); cols = list(rows[0].keys()); log = []
for r in rows:
    for t in O['trims']:
        if t['name'] == r['full_name']:
            assert t['removed'] in r['reasoning'], t; r['reasoning'] = r['reasoning'].replace(t['removed'], t['now']); log.append(['trim', r['full_name'], t['removed']])
w = csv.DictWriter(open(f'{B}/research.csv', 'w', newline=''), fieldnames=cols); w.writeheader(); w.writerows(rows)
json.dump(log, open(f'{B}/overrides-applied.json', 'w'), indent=1); print('applied', len(log))
