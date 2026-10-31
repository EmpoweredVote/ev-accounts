"""List each loadable old-season source as examined on the blank that replaces that answer (STAGE5 step 7.5).
python3 -I scripts/stage5/add_fallback.py <batch dir> --topic <key> --gloss "<what the question asks, in a few words>"
    [--hold "Full Name"]... [--seen "Full Name"]... [--date YYYY-MM-DD]
Per blank: the source URL goes on the row, plus a party-free snippet (25+ words) cut from the saved copy
(fallback/pages, loaded by fallback-fetch.ts) around the surname, else the page start, and one sentence on the
reasoning: "Old Season 1 sources examined (<date>): <hosts> — nothing on <gloss>."
Reads fallback/fallback-required.json (s1-sources.ts), fallback/fallback-read.json (the reader agent:
{name: {urls: [{url, verdict: on-topic | nothing-on-topic | not-loadable | excluded-source}]}}) and fallback/pages/index.json.
Not-loadable and excluded (OnTheIssues, Wikipedia) URLs are skipped. Anyone in --hold, or with an on-topic page that
is not in --seen (pages the coder already weighed), is NOT touched: hold them for a re-code check.
Log -> fallback/blank-examined-log.json."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, opts, positional
import csv, json, re, datetime
USAGE = 'add_fallback.py <batch dir> --topic <key> --gloss "<question gloss>" [--hold Name]... [--seen Name]... [--date D]'
B = positional(1, USAGE)[0]; F = f'{B}/fallback'
TOPIC, GLOSS = opt('--topic', required=True, usage=USAGE), opt('--gloss', required=True, usage=USAGE)
HELD, SEEN = set(opts('--hold')), set(opts('--seen')); DATE = opt('--date', datetime.date.today().isoformat())
# Party labels in a snippet window: names, "(R)", "R-12", "R-LD", and "(D-Bloomington)" / "R-Goshen" city tags.
PARTY = re.compile(r'Republican|Democrat|\bGOP\b|\bParty\b|\((?:R|D|I)\)|\b[DR]-\d|\b(?:R|D)\s*-\s*(?:LD|District)|\b[DR]-[A-Z][a-z]', re.I)
req = json.load(open(f'{F}/fallback-required.json')); rd = json.load(open(f'{F}/fallback-read.json'))
idx = json.load(open(f'{F}/pages/index.json'))
rows = list(csv.DictReader(open(f'{B}/research.csv'))); cols = list(rows[0].keys()); uc = [c for c in cols if c.startswith('source_url_')]
ev = list(csv.DictReader(open(f'{B}/evidence.csv'))); ec = list(ev[0].keys())
def snip(t, sur, n=34):
    w = t.split(); ats = [len(t[:m.start()].split()) for m in re.finditer(re.escape(sur), t)]
    for a in [max(0, x - k) for x in ats for k in (n // 2, 8, 1, -2)] + list(range(0, max(1, len(w) - n), 8)):
        s = ' '.join(w[a:a + n])
        if len(s.split()) >= 25 and not PARTY.search(s): return s
    return None
held, none, nowin, done, log = [], [], [], 0, []
for name, q in req.items():
    vs = rd[name]['urls']
    if name in HELD or any(v['verdict'] == 'on-topic' for v in vs) and name not in SEEN:
        held.append(name); continue
    use = [v['url'] for v in vs if v['verdict'] in ('nothing-on-topic', 'on-topic')]
    if not use: none.append(name); continue
    r = next(x for x in rows if x['full_name'] == name)
    surname = re.sub(r',.*$', '', name).replace('"', '').split()[-1]
    us = [r[c] for c in uc if r[c]]; hosts = []; adds = []
    for u in use:
        s = snip(open(f'{F}/pages/{idx[u]}').read(), surname)
        if not s: nowin.append([name, u]); continue
        if u not in us: us.append(u)
        k = 1 + max([int(e['snippet_index']) for e in ev if e['full_name'] == name and e['source_url'] == u] or [0])
        adds.append({'full_name': name, 'topic_key': TOPIC, 'source_url': u, 'snippet': s, 'snippet_index': str(k)})
        hosts.append(re.sub(r'^https?://(www\.)?', '', u).split('/')[0])
    if not hosts: none.append(name); continue
    ev += adds
    while len(us) > len(uc): uc.append(f'source_url_{len(uc) + 1}'); cols.append(uc[-1])
    for k, c in enumerate(uc): r[c] = us[k] if k < len(us) else ''
    tail = ' — the same records weighed above.' if name in SEEN else f' — nothing on {GLOSS}.'
    r['reasoning'] = r['reasoning'].rstrip() + f' Old Season 1 sources examined ({DATE}): ' + '; '.join(dict.fromkeys(hosts)) + tail
    done += 1; log.append({'name': name, 'urls': use, 'skipped': [v['url'] for v in vs if v['url'] not in use]})
for r in rows:
    for c in cols: r.setdefault(c, '')
w = csv.DictWriter(open(f'{B}/research.csv', 'w', newline=''), fieldnames=cols); w.writeheader(); w.writerows(rows)
w = csv.DictWriter(open(f'{B}/evidence.csv', 'w', newline=''), fieldnames=ec); w.writeheader(); w.writerows(ev)
json.dump({'examined': log, 'held': held, 'no_loadable_source': none, 'no_party_free_window': nowin}, open(f'{F}/blank-examined-log.json', 'w'), indent=1)
print('examined', done, 'held', held, 'no loadable source', none, 'no party-free window', nowin)
