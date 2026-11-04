"""Seated rows: every vote or authorship cited on an official page the verifier cannot use -> a LegiScan URL to cite
instead (STAGE5 step 7.7). Writes legiscan/needs.json, legiscan/pairs.csv (input of scripts/legiscan-evidence-lines.ts)
and legiscan/unmapped.json.
python3 -I scripts/stage5/legiscan_pairs.py <batch dir> <store findings dir> --topic <key> --state XX --host <official host>
    --rollcalls <rollcall-map.json> [--bill-pad N]
rollcall-map.json: [{"instrument": "IN-SB-10-2025", "chamber": "H", "roll_call": "340",
                     "legiscan": "https://legiscan.com/IN/rollcall/SB0010/id/1532383", "note": "official 66-26"}]
  — one entry per official roll call, checked by hand or with legiscan-rollcalls.ts (bill, chamber, counts, date).
--bill-pad: zero-pad the bill number in LegiScan bill URLs to N digits (IN prints SB0010: 4; most states: 0).
Authorship acts go to the LegiScan bill page; committee votes are never mapped (unmapped.json)."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, opts, positional
import csv, json, re
USAGE = 'legiscan_pairs.py <batch dir> <findings dir> --topic <key> --state XX --host <host> --rollcalls <json> [--bill-pad N]'
B, F = positional(2, USAGE)
TOPIC, ST, HOST = (opt(k, required=True, usage=USAGE) for k in ('--topic', '--state', '--host'))
RCF = opt('--rollcalls', required=True, usage=USAGE); PAD = int(opt('--bill-pad', '0'))
RC = {(x['instrument'], x['chamber'], str(x['roll_call'])): x['legiscan'] for x in json.load(open(RCF))}
def bill_url(iid):
    m = re.match(ST + r'-([A-Z]+)-(\d+)-(\d{4})$', iid)
    return f"https://legiscan.com/{ST}/bill/{m.group(1)}{m.group(2).zfill(PAD)}/{m.group(3)}" if m else None
HOUSE = re.compile(rf'\b{ST} House\b|House (?:third reading|concurrence|floor|roll call|vote)|House Committee|_H\.pdf', re.I)
SENATE = re.compile(rf'\b{ST} Senate\b|Senate (?:third reading|concurrence|floor|roll call|vote)|Senate Committee|_S\.pdf', re.I)
SUF = {'Jr.', 'Sr.', 'II', 'III', 'IV', 'Jr', 'Sr'}
last = lambda n: [x for x in n.replace(',', ' ').split() if x not in SUF][-1]
pid = {p['full_name']: p['politician_id'] for p in json.load(open(f'{B}/politicians.json'))}
needs, unmapped, pairs = {}, [], []
os.makedirs(f'{B}/legiscan', exist_ok=True)
for r in csv.DictReader(open(f'{B}/research.csv')):
    if r['evidence_type'] == 'blank': continue
    urls = [r[c] for c in r if c.startswith('source_url_') and r[c]]
    d = json.load(open(os.path.join(F, pid[r['full_name']] + '.json'))); fs = d if isinstance(d, list) else d['findings']
    for f in fs:
        u = f.get('url') or ''
        if f.get('kind') != 'record' or u not in urls or HOST not in u: continue
        act, ins = f.get('act'), f.get('instrument_id') or ''
        if act in ('author', 'coauthor', 'sponsor', 'cosponsor'): ls = bill_url(ins)
        elif act in ('yea', 'nay', 'abstain'):
            txt = (f.get('note') or '') + ' ' + (f.get('motion') or '') + ' ' + u
            ch = f.get('chamber') or ('H' if HOUSE.search(txt) else 'S' if SENATE.search(txt) else '?')
            m = re.search(r'roll call (\d+)', txt, re.I); ls = RC.get((ins, ch, m.group(1) if m else ''))
            if 'Committee' in (f.get('motion') or ''): ls = None
        else: unmapped.append([r['full_name'], u, ins, f'act {act} (not a vote or authorship)']); continue
        if not ls: unmapped.append([r['full_name'], u, ins, f"{act}: {(f.get('motion') or '')[:90]}"]); continue
        n = {'url': ls, 'official': u, 'act': act, 'instrument': ins}
        needs.setdefault(r['full_name'], [])
        if n not in needs[r['full_name']]: needs[r['full_name']].append(n)
        pairs.append((r['full_name'], last(r['full_name']), TOPIC, ls))
pairs = list(dict.fromkeys(pairs))
json.dump(needs, open(f'{B}/legiscan/needs.json', 'w'), indent=1); json.dump(unmapped, open(f'{B}/legiscan/unmapped.json', 'w'), indent=1)
w = csv.writer(open(f'{B}/legiscan/pairs.csv', 'w', newline='')); w.writerow(['full_name', 'last_name', 'topic_key', 'source_url']); w.writerows(pairs)
print('people', len(needs), 'pairs', len(pairs), 'unmapped', len(unmapped))
