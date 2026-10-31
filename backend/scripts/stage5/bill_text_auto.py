"""Bill text as cited passages, found automatically (STAGE5 step 7.8). For every high quote-not-in-snippet gate
finding, look for the quoted words in the text of the bills the person's own findings name, and cite that bill's
text with a passage (25+ words, the gate's floor) that holds the quote word for word.
python3 -I scripts/stage5/bill_text_auto.py <batch dir> <store findings dir> --topic <key>
    [--instruments <store instruments dir>] [--saved-root <dir the saved copies' paths are relative to>]
Text sources, in order: the instrument's operative_text quote blocks (in the store, verbatim from the act), then its
saved copy (provenance.saved_copy; PDFs read with pdftotext; the sha256 is checked) when --saved-root is given.
The cited URL is the instrument URL whose file name is the saved copy's, else its first .pdf URL, else its first URL.
Reads gate-output.txt, politicians.json, research.csv, evidence.csv. Writes research.csv / evidence.csv (copies kept
as *-pre-billtext.csv) and bill-text.json: per person, each quote with the bill, URL, passage and text source, and
every quote it could not place. The bill names no voter, so the verifier does not count it as a source."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, positional
import csv, glob, hashlib, json, re, shutil, subprocess

USAGE = 'bill_text_auto.py <batch dir> <findings dir> --topic <key> [--instruments <dir>] [--saved-root <dir>]'
B, F = positional(2, USAGE); TOPIC = opt('--topic', required=True, usage=USAGE)
INSTR = opt('--instruments', os.path.join(os.path.dirname(os.path.abspath(F.rstrip('/'))), 'instruments'))
SAVED = opt('--saved-root')
MIN_WORDS = 25

QMAP = str.maketrans({'“': '"', '”': '"', '‘': "'", '’': "'", '–': '-', '—': '-'})
def norm(s): return re.sub(r'\s+', ' ', s.translate(QMAP)).strip().lower().rstrip('.')

def instrument(iid, _c={}):
    if iid not in _c:
        fp = glob.glob(os.path.join(INSTR, '**', iid + '.json'), recursive=True)
        _c[iid] = json.load(open(fp[0])) if fp else None
    return _c[iid]

def blocks(ins):
    """The operative_text quote blocks: each is verbatim act text ("(x) not stated" lines are notes, not text)."""
    out = []
    for m in re.finditer(r'^\(quote\) (.*?)(?=\n\s*\n|\n\([a-z_]+\) \(section\)|\Z)', ins.get('operative_text') or '', re.M | re.S):
        t = re.sub(r'\s+', ' ', m.group(1)).strip()
        if t and not t.startswith('(x)'): out.append(t)
    return out

def saved_text(ins, _c={}):
    sc = (ins.get('provenance') or {}).get('saved_copy') or {}
    if not SAVED or not sc.get('path'): return None
    p = os.path.join(SAVED, sc['path'])
    if p in _c: return _c[p]
    t = None
    if os.path.exists(p):
        raw = open(p, 'rb').read()
        if sc.get('sha256') and hashlib.sha256(raw).hexdigest() != sc['sha256']:
            print('saved copy sha256 differs, not used:', p)
        elif raw[:5] == b'%PDF-':
            t = subprocess.run(['pdftotext', '-layout', p, '-'], capture_output=True).stdout.decode('utf-8', 'replace')
        else: t = raw.decode('utf-8', 'replace')
    _c[p] = re.sub(r'\s+', ' ', t).strip() if t else None
    return _c[p]

def text_url(ins):
    urls = [u for u in ins.get('urls') or [] if isinstance(u, str) and ' ' not in u]
    name = os.path.basename(((ins.get('provenance') or {}).get('saved_copy') or {}).get('path') or '')
    return next((u for u in urls if name and u.endswith('/' + name)), None) or next((u for u in urls if u.lower().endswith('.pdf')), None) or (urls[0] if urls else None)

def cut(text, quote):
    """The shortest run of whole sentences of text that holds quote and has MIN_WORDS words; None if text cannot."""
    nt = text.translate(QMAP).lower()
    i = nt.find(quote.translate(QMAP).lower().rstrip('.'))
    if i < 0:
        nq = norm(quote); flat = re.sub(r'\s+', ' ', nt)
        if nq not in flat: return None
        i = flat.find(nq)  # text is already whitespace-collapsed, so offsets agree
    j = i + len(quote.rstrip('.'))
    starts = [0] + [m.end() for m in re.finditer(r'(?<=[.;:])\s+(?=\(?[A-Z0-9])', text)]
    ends = [m.start() + 1 for m in re.finditer(r'[.;:](?=\s|$)', text)] + [len(text)]
    a = max([s for s in starts if s <= i], default=0); b = min([e for e in ends if e >= j], default=len(text))
    while len(text[a:b].split()) < MIN_WORDS:  # widen a sentence at a time, forward first
        nb = min([e for e in ends if e > b], default=None); na = max([s for s in starts if s < a], default=None)
        if nb is not None: b = nb
        elif na is not None: a = na
        else: return None
    return text[a:b].strip()

pid = {p['full_name']: p['politician_id'] for p in json.load(open(f'{B}/politicians.json'))}
pat = re.compile(r'high\s+quote-not-in-snippet\s+(.*?) / ' + re.escape(TOPIC) + r': .*?: "(.*)"$')
need = {}
for l in open(f'{B}/gate-output.txt'):
    m = pat.search(l.rstrip())
    if m: need.setdefault(m.group(1), []).append(m.group(2))
for f in ('research', 'evidence'):
    if not os.path.exists(f'{B}/{f}-pre-billtext.csv'): shutil.copy(f'{B}/{f}.csv', f'{B}/{f}-pre-billtext.csv')
rows = list(csv.DictReader(open(f'{B}/research.csv'))); cols = list(rows[0].keys()); uc = [c for c in cols if c.startswith('source_url_')]
ev = list(csv.DictReader(open(f'{B}/evidence.csv')))
have = {(e['full_name'], e['source_url'], e['snippet']) for e in ev}
log = {}
for r in rows:
    n = r['full_name']
    if n not in need or n not in pid: continue
    fp = os.path.join(F, pid[n] + '.json')
    d = json.load(open(fp)) if os.path.exists(fp) else []
    iids = list(dict.fromkeys(f.get('instrument_id') for f in (d if isinstance(d, list) else d.get('findings', [])) if f.get('instrument_id')))
    placed, missed = [], []
    for q in dict.fromkeys(need[n]):
        hit = None
        for iid in iids:
            ins = instrument(iid)
            if not ins or not text_url(ins): continue
            for src, texts in (('operative_text', blocks(ins)), ('saved_copy', [saved_text(ins)])):
                for t in texts:
                    s = cut(t, q) if t else None
                    if s: hit = (iid, text_url(ins), s, src); break
                if hit: break
            if hit: break
        if not hit: missed.append(q); continue
        iid, url, s, src = hit
        placed.append({'quote': q, 'instrument': iid, 'url': url, 'passage': s, 'source': src})
        us = [r[c] for c in uc if r[c]]
        if url not in us: us.append(url)
        while len(us) > len(uc): uc.append(f'source_url_{len(uc) + 1}'); cols.append(uc[-1])
        for k, c in enumerate(uc): r[c] = us[k] if k < len(us) else ''
        if (n, url, s) not in have:
            ev.append({'full_name': n, 'topic_key': r['topic_key'], 'source_url': url, 'snippet': s, 'snippet_index': ''}); have.add((n, url, s))
    log[n] = {'placed': placed, 'not_placed': missed}
for r in rows:
    for c in cols: r.setdefault(c, '')
idx = {}
for e in ev:
    k = (e['full_name'], e['topic_key']); idx[k] = idx.get(k, 0) + 1; e['snippet_index'] = str(idx[k])
w = csv.DictWriter(open(f'{B}/research.csv', 'w', newline=''), fieldnames=cols); w.writeheader(); w.writerows(rows)
w = csv.DictWriter(open(f'{B}/evidence.csv', 'w', newline=''), fieldnames=['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index']); w.writeheader(); w.writerows(ev)
json.dump(log, open(f'{B}/bill-text.json', 'w'), indent=1)
pl = sum(len(v['placed']) for v in log.values()); mi = sum(len(v['not_placed']) for v in log.values())
print('people', len(log), 'quotes placed', pl, 'not placed', mi, 'evidence rows', len(ev))
