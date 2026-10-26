"""Pre-write gate for the voting-rights Season 3 run. Run from backend/:

    python3 data/stance-research/voting-rights-s3-2026-10-22/gate.py

For each person: labels_to_research.py turns the Opus label into research.csv (the coder's answer, copied).
The rows are joined into combined-research.csv here, which audit-chair-evidence.mjs --csv gates, and
results.json records each person's chair, blank reason, queue reasons and the Stage 3 expected chair.
"""
import csv, glob, json, os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SR = os.path.dirname(HERE)
# Stage 3 expected chair per record (stage3/expert-queue.json; None = blank under D1 / DC1).
EXP = {'VA-HB-19-2020': 2, 'TX-SB-1-2021': 4, 'TX-SB-5-2017': 3, 'TX-SB-14-2011': 4, 'VA-SB-1256-2013': 4,
       'KY-SB-2-2020': 3, 'NC-S-824-2018': 3, 'SC-H-3003-2011': 3, 'US-HR-22-2025': 5, 'US-S-1383-2026': 5,
       'MA-H-4359-AMDT-7-2022': 4, 'TX-SB-16-2025': 5, 'VA-HB-1444-2023': None, 'MI-SB-303-2021': None, 'VA-HB-46-2022': 4}

spec = json.load(open(os.path.join(HERE, 'spec-all.json')))
rows, results = [], []
for b in spec['batches']:
  d = os.path.join(SR, f"2026-10-22-shadow-{b['name']}")
  one = os.path.join(d, '_spec-person.json')
  json.dump({'date': '2026-10-22', 'season': 'draft', 'batches': [b]}, open(one, 'w'))
  r = subprocess.run([sys.executable, 'scripts/gold-desk/labels_to_research.py', d, one], capture_output=True, text=True)
  if r.returncode != 0: sys.exit(f"{b['name']}: labels_to_research failed\n{r.stdout[-600:]}\n{r.stderr[-600:]}")
  with open(os.path.join(d, 'research.csv'), newline='') as f: rows += list(csv.DictReader(f))
  label = json.load(open(os.path.join(d, 'labels', 'coder-1.json')))['rows'][0]
  q = open(os.path.join(d, '_queue-dry.log')).read()
  aff = [x for x in b['records'] if x[2] in ('yea', 'sponsor')]
  results.append({'name': b['name'], 'person': b['person'], 'politician_id': b['politician_id'], 'level': b['level'],
                  'chair': label['v6_value'], 'blank_reason': label.get('v6_blank_reason'),
                  'expected': sorted({EXP.get(x[0]) for x in aff}, key=str), 'records': b['records'],
                  'needs_source': label.get('needs_source') or [],
                  'queue': re.findall(r'^(queue .*|skip .*)$', q, re.M)})
fields = list(rows[0].keys())
for r in rows:
  for k in r:
    if k not in fields: fields.append(k)
with open(os.path.join(HERE, 'combined-research.csv'), 'w', newline='') as f:
  w = csv.DictWriter(f, fieldnames=fields); w.writeheader(); w.writerows(rows)
json.dump(results, open(os.path.join(HERE, 'results.json'), 'w'), indent=2)
print(f"{len(rows)} research row(s) from {len(results)} people -> combined-research.csv, results.json")
