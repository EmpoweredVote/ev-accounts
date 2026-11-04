"""Snippets for quotes the gate cannot place, cut from pages already fetched (STAGE5 step 9).
python3 -I scripts/stage5/quote_snippets.py <batch dir> <gate output> --topic <key>
For each quote-not-in-snippet finding, look for the quoted words in the cached text (pages/<sha1>.txt, from
build_evidence.py) of that person's cited URLs; when found, add an evidence row cut from that page: the quote plus up
to 20 whole words either side. Never edits research.csv. Log -> quote-snippets.json ({"added", "missing"}; plus
"not_in_research" for findings about people held or moved since that gate run, which are skipped)."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, positional
import csv, hashlib, json, re
USAGE = 'quote_snippets.py <batch dir> <gate output> --topic <key>'
B, G = positional(2, USAGE); TOPIC = opt('--topic', required=True, usage=USAGE)
norm = lambda s: re.sub(r'\s+', ' ', s.replace('’', "'").replace('“', '"').replace('”', '"').replace('—', '-').replace('–', '-')).strip()
rows = {r['full_name']: r for r in csv.DictReader(open(f'{B}/research.csv'))}
ev = list(csv.DictReader(open(f'{B}/evidence.csv'))); cols = list(ev[0].keys())
added, miss, gone = [], [], []
for l in open(G):
    if 'quote-not-in-snippet' not in l: continue
    m = re.search(r'quote-not-in-snippet\s+(.*?) / ' + re.escape(TOPIC) + r'\b', l)
    if not m: continue
    n = m.group(1)
    q = re.search(r'snippet: "(.*)"\s*$', l.rstrip()).group(1)
    if n not in rows: gone.append([n, q]); continue  # held or moved since this gate run
    urls = [rows[n][c] for c in rows[n] if c.startswith('source_url') and rows[n][c]]
    done = False
    for u in urls:
        f = f'{B}/pages/{hashlib.sha1(u.encode()).hexdigest()}.txt'
        if not os.path.exists(f): continue
        t = norm(open(f).read()); i = t.find(norm(q))
        if i < 0: continue
        w0 = t[:i].split(' '); w1 = t[i + len(norm(q)):].split(' ')
        snip = ' '.join(w0[-20:]) + t[i:i + len(norm(q))] + ' '.join(w1[:20])
        k = max([int(e['snippet_index']) for e in ev if e['full_name'] == n] + [0]) + 1
        ev.append({**{c: '' for c in cols}, 'full_name': n, 'topic_key': TOPIC, 'source_url': u, 'snippet': snip.strip(), 'snippet_index': str(k)})
        added.append([n, u, q]); done = True; break
    if not done: miss.append([n, q, urls])
w = csv.DictWriter(open(f'{B}/evidence.csv', 'w', newline=''), fieldnames=cols); w.writeheader(); w.writerows(ev)
json.dump({'added': added, 'missing': miss, **({'not_in_research': gone} if gone else {})}, open(f'{B}/quote-snippets.json', 'w'), indent=1)
print('added', len(added), 'missing', len(miss))
for m in miss: print(' ', m[0], '|', m[1][:80], '|', len(m[2]), 'urls')
if gone: print('skipped', len(gone), 'quotes of people no longer in research.csv:', sorted({g[0] for g in gone}))
