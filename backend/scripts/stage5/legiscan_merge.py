"""Merge LegiScan lines into the batch (STAGE5 step 7.7): cite each person's LegiScan URL that has a line; uncite an
official page (--host) only when every vote or authorship of theirs on it now has a line; add the lines; re-index.
Cross-check each vote line against the finding's act -> legiscan/crosscheck.json: it must show 0 disagree.
python3 -I scripts/stage5/legiscan_merge.py <batch dir> --host <official host>
Reads legiscan/needs.json (legiscan_pairs.py) and legiscan/legiscan-evidence.csv (legiscan-evidence-lines.ts).
Log -> legiscan-merge-log.json. Exit 1 when any vote disagrees.
A vote or authorship with no LegiScan line keeps its official page and is listed in legiscan/no-line.json
([name, LegiScan URL, act, instrument]): the verifier cannot read that page, so the person is usually held later.
South Carolina, 2026-11-14: 101 pairs had no line (a bill page named with the wrong year or number, and four people who
go by a middle name) and only a warning in the log said so."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, opts, positional
import csv, json, re
B = positional(1, 'legiscan_merge.py <batch dir> --host <official host>')[0]; HOST = opt('--host', required=True, usage='--host <official host>')
lines = list(csv.DictReader(open(f'{B}/legiscan/legiscan-evidence.csv')))
needs = json.load(open(f'{B}/legiscan/needs.json'))
have = {(l['full_name'], l['source_url']) for l in lines}
rows = list(csv.DictReader(open(f'{B}/research.csv'))); cols = list(rows[0].keys()); uc = [c for c in cols if c.startswith('source_url_')]
log, cross = [], []
ACT = {'yea': 'Yea', 'nay': 'Nay', 'abstain': 'NV'}
for r in rows:
    n = r['full_name']; vs = needs.get(n, [])
    if not vs: continue
    urls = [r.get(c, '') for c in uc if r.get(c)]  # an earlier row may have added columns this row does not have yet
    for v in vs:
        if (n, v['url']) in have and v['url'] not in urls: urls.append(v['url']); log.append([n, 'cite LegiScan', v['url']])
    for off in {v['official'] for v in vs}:
        if off in urls and all((n, v['url']) in have for v in vs if v['official'] == off):
            urls.remove(off); log.append([n, f'uncite {HOST} (covered by a LegiScan line)', off])
    while len(urls) > len(uc): uc.append(f'source_url_{len(uc) + 1}'); cols.append(uc[-1])
    for i, c in enumerate(uc): r[c] = urls[i] if i < len(urls) else ''
    for v in vs:
        if v['act'] not in ACT: continue  # a sponsorship; a vote is cross-checked wherever its line is cited
        for l in lines:
            if l['full_name'] == n and l['source_url'] == v['url']:
                # a legislature's own roll-call page words an absence "was absent or not voting" (Utah), and South Dakota's
                # as its record lists it: "was excused", "was absent", "did not vote", "voted present", "was suspended"
                # (stateRollCallEvidence.ts). Each is no Yea and no Nay.
                got = (re.search(r'voted (Yea|Nay)\.?$', l['snippet']) or re.search(r'(?:was (absent) or not voting|was (?:excused|absent|suspended)|did not vote|voted present)\.$', l['snippet']))
                got = ('NV' if got.group(0).startswith(('was', 'did', 'voted present')) else got.group(1)) if got else '?'
                cross.append({'name': n, 'legiscan': v['url'], 'official': v['official'], 'legiscan_vote': got, 'finding_act': v['act'], 'agree': got == ACT.get(v['act'])})
for r in rows:
    for c in cols: r.setdefault(c, '')
cited = {(r['full_name'], r[c]) for r in rows for c in uc if r[c]}
ev = [e for e in csv.DictReader(open(f'{B}/evidence.csv')) if (e['full_name'], e['source_url']) in cited] + [l for l in lines if (l['full_name'], l['source_url']) in cited]
idx = {}
for e in ev:
    k = (e['full_name'], e['topic_key']); idx[k] = idx.get(k, 0) + 1; e['snippet_index'] = str(idx[k])
w = csv.DictWriter(open(f'{B}/research.csv', 'w', newline=''), fieldnames=cols); w.writeheader(); w.writerows(rows)
w = csv.DictWriter(open(f'{B}/evidence.csv', 'w', newline=''), fieldnames=['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index']); w.writeheader(); w.writerows(ev)
json.dump(log, open(f'{B}/legiscan-merge-log.json', 'w'), indent=1); json.dump(cross, open(f'{B}/legiscan/crosscheck.json', 'w'), indent=1)
noline = sorted({(n, v['url'], v['act'], v.get('instrument', '')) for n, vs in needs.items() for v in vs if (n, v['url']) not in have})
json.dump(noline, open(f'{B}/legiscan/no-line.json', 'w'), indent=1)
left = sorted({(r['full_name'], r[c]) for r in rows for c in uc if HOST in r[c]})
dis = [c for c in cross if not c['agree']]
print('evidence rows', len(ev), 'lines cited', sum(1 for l in lines if (l['full_name'], l['source_url']) in cited), 'official uncited', sum('uncite' in x[1] for x in log),
      'cross-checked', len(cross), 'disagree', len(dis), 'official still cited', len(left), 'no LegiScan line', len(noline))
[print(c) for c in dis]; [print('official left:', *x) for x in left]
sys.exit(1 if dis else 0)
