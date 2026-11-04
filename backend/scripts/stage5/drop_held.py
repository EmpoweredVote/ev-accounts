"""Drop held and moved people's rows from research.csv and evidence.csv (STAGE5 "Held people").
python3 -I scripts/stage5/drop_held.py <batch dir>
Reads the ids in held.txt and moved.txt, maps them to names through politicians.json, and filters the CURRENT files.
The full files are kept once as research-with-held.csv / evidence-with-held.csv and never read back, so running it
again after a later step keeps that step's work."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import positional
import csv, json, shutil
B = positional(1, 'drop_held.py <batch dir>')[0]
ids = set()
for f in ('held.txt', 'moved.txt'):
    if os.path.exists(f'{B}/{f}'):
        ids |= {l.strip() for l in open(f'{B}/{f}') if l.strip()}
pol = json.load(open(f'{B}/politicians.json')); pol = pol if isinstance(pol, list) else pol.get('politicians', pol)
names = {p['full_name'] for p in pol if p['politician_id'] in ids}
for base in ('research', 'evidence'):
    src, keep = f'{B}/{base}.csv', f'{B}/{base}-with-held.csv'
    if not os.path.exists(src): continue
    if not os.path.exists(keep): shutil.copy(src, keep)
    rows = list(csv.DictReader(open(src)))
    cols = list(rows[0].keys())
    out = [r for r in rows if r['full_name'] not in names]
    with open(src, 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=cols); w.writeheader(); w.writerows(out)
    print(base, len(rows), '->', len(out))
print('people dropped', len(names), 'of ids', len(ids))
