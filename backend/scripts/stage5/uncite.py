"""Take listed pages off their people's rows and drop their snippets (STAGE5 step 9).
python3 -I scripts/stage5/uncite.py <batch dir> [--file <uncite json>]   (default <batch>/uncite.json)
uncite.json: [{"name": "<full_name>", "url": "<source url>", "why": "..."}]: a page the research text does not rest
on, or one no snippet can be cut from. Source URLs are packed left in research.csv; evidence.csv loses that
(name, url)'s snippets. Re-index with the next tool that writes evidence.csv, or read snippet_index as unordered."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, positional
import csv, json
B = positional(1, 'uncite.py <batch dir> [--file <uncite json>]')[0]; U = json.load(open(opt('--file', f'{B}/uncite.json')))
rows = list(csv.DictReader(open(f'{B}/research.csv'))); cols = list(rows[0].keys()); uc = [c for c in cols if c.startswith('source_url_')]
for r in rows:
    drop = {u['url'] for u in U if u['name'] == r['full_name']}
    if not drop: continue
    urls = [r[c] for c in uc if r[c] and r[c] not in drop]
    for i, c in enumerate(uc): r[c] = urls[i] if i < len(urls) else ''
w = csv.DictWriter(open(f'{B}/research.csv', 'w', newline=''), fieldnames=cols); w.writeheader(); w.writerows(rows)
ev = list(csv.DictReader(open(f'{B}/evidence.csv'))); ecols = list(ev[0].keys())
pairs = {(u['name'], u['url']) for u in U}
ev = [e for e in ev if (e['full_name'], e['source_url']) not in pairs]
w = csv.DictWriter(open(f'{B}/evidence.csv', 'w', newline=''), fieldnames=ecols); w.writeheader(); w.writerows(ev)
print('uncited', len(U))
