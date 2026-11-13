"""Cite the person's own record on a bill the research text names (STAGE5 step 9, before step 7's LegiScan lines).
python3 -I scripts/stage5/cite_named.py <batch dir> <gate output> <store findings dir> --state XX
For each gate instrument-not-cited finding (person, bill), add to the person's research row the official URL of their
OWN record finding on that bill (a vote or a sponsorship), so the roll-call step can line it. Research sources only.
The (person, bill) pairs with no such finding go to cite-named-none.json: the bill is a side-list one the seat does
not rest on, and needs a trim (step 9), never a guessed source."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, positional
import csv, json, re
USAGE = 'cite_named.py <batch dir> <gate output> <findings dir> --state XX'
B, G, F = positional(3, USAGE); ST = opt('--state', required=True, usage=USAGE)
pol = json.load(open(f'{B}/politicians.json')); pol = pol if isinstance(pol, list) else pol['politicians']
pid = {p['full_name']: p['politician_id'] for p in pol}
canon = lambda iid: (lambda m: (m.group(1) + m.group(2)).lower() if m else None)(re.match(re.escape(ST) + r'-([A-Z]+)-(\d+)-', iid or ''))
rows = list(csv.DictReader(open(f'{B}/research.csv'))); cols = list(rows[0].keys()); by = {r['full_name']: r for r in rows}
added, none = 0, []
for l in open(G):
    m = re.search(r'instrument-not-cited\s+(.*?) / [a-z-]+: .*?canonical "([^"]+)"', l)
    if not m: continue
    n, can = m.groups(); r = by[n]
    d = json.load(open(f'{F}/{pid[n]}.json')); fs = d if isinstance(d, list) else d['findings']
    # Same topic only: a gun row naming "SJR 2" must not cite the person's voting-rights SJR 2 roll call (wi-01).
    fs = [f for f in fs if f.get('kind') == 'record' and canon(f.get('instrument_id')) == can and f.get('url')
          and (not f.get('topic_keys') or r['topic_key'] in f['topic_keys'])]
    if not fs: none.append((n, can)); continue
    uc = [c for c in cols if c.startswith('source_url_')]; urls = [r[c] for c in uc if r.get(c)]
    for f in fs:
        if f['url'] not in urls: urls.append(f['url']); added += 1
    while len(urls) > len(uc): cols.append(f'source_url_{len(uc) + 1}'); uc.append(cols[-1])
    for k, c in enumerate(uc): r[c] = urls[k] if k < len(urls) else ''
for r in rows:
    for c in cols: r.setdefault(c, '')
w = csv.DictWriter(open(f'{B}/research.csv', 'w', newline=''), fieldnames=cols); w.writeheader(); w.writerows(rows)
json.dump(none, open(f'{B}/cite-named-none.json', 'w'), indent=1)
print('urls added', added, '· no own finding', len(none), none[:12])
