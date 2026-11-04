"""Cite a bill's own text where the reasoning quotes its words and the cited page cannot be read (STAGE5 step 7.8).
python3 -I scripts/stage5/add_bill_text.py <batch dir> --topic <key> --url <bill text URL> --sentences <json>
    [--text <plain text file>]
--sentences: a JSON list of passages copied from the bill text, each 25 words or more (the gate's snippet floor).
--text (default <batch>/bill-text/plain.txt): the bill text as fetched (pdftotext for a PDF); every passage must be
in it word for word, or the run stops. Check its sha256 against the source store's saved copy first.
Reads gate-output.txt: each high quote-not-in-snippet finding whose quote sits inside a passage gets that passage,
and the row cites --url. The bill names no voter, so the verifier does not count it as a source for the person.
Log -> bill-text.json."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, opts, positional
import csv, json, re
USAGE = 'add_bill_text.py <batch dir> --topic <key> --url <url> --sentences <json> [--text <file>]'
B = positional(1, USAGE)[0]
TOPIC, URL, SF = (opt(k, required=True, usage=USAGE) for k in ('--topic', '--url', '--sentences'))
SENT = json.load(open(SF)); TEXT = opt('--text', f'{B}/bill-text/plain.txt')
short = [s for s in SENT if len(s.split()) < 25]
if short: raise SystemExit(f'passages under 25 words: {short}')
flat = re.sub(r'\s+', ' ', open(TEXT).read())
missing = [s for s in SENT if s not in flat]
if missing: raise SystemExit(f'not in the bill text word for word: {missing}')
norm = lambda s: re.sub(r'\s+', ' ', s.replace('“', '"').replace('”', '"').replace('’', "'")).strip().lower().rstrip('.')
need = {}
pat = re.compile(r'high\s+quote-not-in-snippet\s+(.*?) / ' + re.escape(TOPIC) + r': .*?: "(.*)"$')
for l in open(f'{B}/gate-output.txt'):
    m = pat.search(l.rstrip())
    if m:
        hit = [s for s in SENT if norm(m.group(2)) in norm(s)]
        if hit: need.setdefault(m.group(1), set()).update(hit)
rows = list(csv.DictReader(open(f'{B}/research.csv'))); cols = list(rows[0].keys()); uc = [c for c in cols if c.startswith('source_url_')]
ev = list(csv.DictReader(open(f'{B}/evidence.csv'))); log = {}
for r in rows:
    n = r['full_name']
    if n not in need: continue
    us = [r[c] for c in uc if r[c]]
    if URL not in us: us.append(URL)
    while len(us) > len(uc): uc.append(f'source_url_{len(uc) + 1}'); cols.append(uc[-1])
    for i, c in enumerate(uc): r[c] = us[i] if i < len(us) else ''
    for s in SENT:
        if s in need[n]: ev.append({'full_name': n, 'topic_key': TOPIC, 'source_url': URL, 'snippet': s, 'snippet_index': ''})
    log[n] = sorted(need[n])
for r in rows:
    for c in cols: r.setdefault(c, '')
idx = {}
for e in ev:
    k = (e['full_name'], e['topic_key']); idx[k] = idx.get(k, 0) + 1; e['snippet_index'] = str(idx[k])
w = csv.DictWriter(open(f'{B}/research.csv', 'w', newline=''), fieldnames=cols); w.writeheader(); w.writerows(rows)
w = csv.DictWriter(open(f'{B}/evidence.csv', 'w', newline=''), fieldnames=['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index']); w.writeheader(); w.writerows(ev)
json.dump(log, open(f'{B}/bill-text.json', 'w'), indent=1)
print('rows cited', len(log), 'snippets added', sum(map(len, log.values())), 'evidence rows', len(ev))
