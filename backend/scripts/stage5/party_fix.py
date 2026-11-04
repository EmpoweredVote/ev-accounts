"""Drop (or cut) every evidence snippet the party sweep listed, and uncite a page left with no snippet (STAGE5 step 7.6).
python3 -I scripts/stage5/party_fix.py <batch dir>
Reads <batch>/party-sweep.jsonl (party-sweep.ts output) and <batch>/evidence-pre-party.csv (made from evidence.csv on
the first run). A snippet is never edited inside: list a cut in <batch>/party-cuts.json, [{"name", "url", "before"}],
to keep the words before "before" when the person and the act are still in them; every other swept snippet is
dropped. Re-indexes. Log -> party-dropped.json. Run party-sweep.ts again afterwards: it must print nothing."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, opts, positional
import csv, json, shutil
B = positional(1, 'party_fix.py <batch dir>')[0]
if not os.path.exists(f'{B}/evidence-pre-party.csv'): shutil.copy(f'{B}/evidence.csv', f'{B}/evidence-pre-party.csv')
drop = [json.loads(l) for l in open(f'{B}/party-sweep.jsonl') if l.strip()]
key = {(d['n'], d['u'], str(d['i'])) for d in drop}
cuts = json.load(open(f'{B}/party-cuts.json')) if os.path.exists(f'{B}/party-cuts.json') else []
ev, log = [], []
for e in csv.DictReader(open(f'{B}/evidence-pre-party.csv')):
    k = (e['full_name'], e['source_url'], e['snippet_index'])
    if k in key:
        cut = next((c for c in cuts if c['name'] == e['full_name'] and c['url'] == e['source_url'] and c['before'] in e['snippet']), None)
        if cut:
            e['snippet'] = e['snippet'].split(cut['before'])[0].rstrip(); log.append([*k, 'cut']); ev.append(e); continue
        log.append([*k, 'dropped']); continue
    ev.append(e)
left = {(e['full_name'], e['source_url']) for e in ev}
gone = {(l[0], l[1]) for l in log if l[3] == 'dropped'} - left
rows = list(csv.DictReader(open(f'{B}/research.csv'))); cols = list(rows[0].keys()); uc = [c for c in cols if c.startswith('source_url_')]
for r in rows:
    us = [r[c] for c in uc if r[c]]; keep = [u for u in us if (r['full_name'], u) not in gone]
    for u in us:
        if u not in keep: log.append([r['full_name'], u, '', 'uncited'])
    for i, c in enumerate(uc): r[c] = keep[i] if i < len(keep) else ''
idx = {}
for e in ev:
    k = (e['full_name'], e['topic_key']); idx[k] = idx.get(k, 0) + 1; e['snippet_index'] = str(idx[k])
w = csv.DictWriter(open(f'{B}/evidence.csv', 'w', newline=''), fieldnames=['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index']); w.writeheader(); w.writerows(ev)
w = csv.DictWriter(open(f'{B}/research.csv', 'w', newline=''), fieldnames=cols); w.writeheader(); w.writerows(rows)
json.dump(log, open(f'{B}/party-dropped.json', 'w'), indent=1)
print('cut', sum(l[3] == 'cut' for l in log), 'dropped', sum(l[3] == 'dropped' for l in log), 'uncited', sum(l[3] == 'uncited' for l in log), 'evidence rows', len(ev))
