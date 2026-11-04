"""Append the hand rows to research.csv (STAGE5 step 7.2; RULINGS.md "Mapping a blank to a V6 reason").
python3 -I scripts/stage5/add_hand_rows.py <batch dir> <stage5 dir> <store findings dir> --topic <key>
Reads <batch>/hand-rows.json: {"<politician_id>": "no-evidence" | "direction-only"} (write the reason for each in
hand-rows.md). Each row is built from the person's code file (<stage5>/codes/<id>.json: reasoning, finding_ids) and
the cited findings' URLs. A person already in research.csv is left alone."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, opts, positional
import csv, json
USAGE = 'add_hand_rows.py <batch dir> <stage5 dir> <store findings dir> --topic <key>'
B, S, F = positional(3, USAGE); TOPIC = opt('--topic', required=True, usage=USAGE)
ROWS = json.load(open(f'{B}/hand-rows.json'))
bad = {p: v for p, v in ROWS.items() if v not in ('no-evidence', 'direction-only')}
if bad: raise SystemExit(f'hand-rows.json: reason must be no-evidence or direction-only: {bad}')
names = {r['politician_id']: r['full_name'] for r in csv.DictReader(open(f'{S}/roster.tsv'), delimiter='\t')}
path = f'{B}/research.csv'; rows = list(csv.DictReader(open(path))); cols = list(rows[0].keys())
have = {r['full_name'] for r in rows}; added = 0
for pid, reason in ROWS.items():
    if names[pid] in have: continue
    c = json.load(open(f'{S}/codes/{pid}.json')); d = json.load(open(os.path.join(F, pid + '.json')))
    fs = d if isinstance(d, list) else d.get('findings', d)
    urls = list(dict.fromkeys(f['url'] for f in fs if f['id'] in c['finding_ids'] and f.get('url')))
    r = {k: '' for k in cols}
    r.update(full_name=names[pid], topic_key=TOPIC, value='0', reasoning=c['reasoning'], evidence_type='blank', blank_reason=reason)
    for i, u in enumerate(urls, 1):
        k = f'source_url_{i}'
        if k not in cols: cols.append(k)
        r[k] = u
    rows.append(r); added += 1
for r in rows:
    for k in cols: r.setdefault(k, '')
w = csv.DictWriter(open(path, 'w', newline=''), fieldnames=cols); w.writeheader(); w.writerows(rows)
print('added', added, 'rows', len(rows))
