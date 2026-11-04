"""Drop the quote marks round act words no readable cited page prints (STAGE5 step 9).
python3 -I scripts/stage5/unquote.py <batch dir> <gate output> [--skip "<Name>"]...
For each high quote-not-in-snippet quote on a RECORD row, the quote marks come off and the words stay, so they read as
description (the official site is blocked or a script app, so no snippet can hold them). Own words are never
touched: a quote on a statement row, or one that speaks in the first person, is listed for a decision instead.
Research text only: appends trims to <batch>/overrides.json (creates it); apply them with apply_overrides.py."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opts, positional
import csv, json, re
B, G = positional(2, 'unquote.py <batch dir> <gate output> [--skip "<Name>"]...')
skip = set(opts('--skip'))
rows = {r['full_name']: r for r in csv.DictReader(open(f'{B}/research.csv'))}
O = json.load(open(f'{B}/overrides.json')) if os.path.exists(f'{B}/overrides.json') else {'trims': []}
done = {(t['name'], t['removed']) for t in O['trims']}; n = 0; ask = []
for l in open(G):
    m = re.search(r'high\s+quote-not-in-snippet\s+(.*?) / [a-z-]+: .*?: "(.*)"$', l.rstrip())
    if not m: continue
    nm, q = m.groups()
    if nm in skip or (nm, f'"{q}"') in done: continue
    if rows[nm]['evidence_type'] == 'statement' or re.search(r"\b(I|I've|I'm|we|my|our)\b", q): ask.append((nm, q)); continue
    O['trims'].append({'name': nm, 'removed': f'"{q}"', 'now': q, 'why': 'act words that no readable cited page prints (the official site is blocked or a script app); quote marks dropped so the words read as description; research.csv text only; code file unchanged'})
    done.add((nm, f'"{q}"')); n += 1
json.dump(O, open(f'{B}/overrides.json', 'w'), indent=1); print('unquote trims', n, '· own words to decide', len(ask))
for a in ask: print('  ', a[0], '|', a[1][:120])
