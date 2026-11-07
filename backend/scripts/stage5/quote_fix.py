"""Trims for bill-text quotes the coder edited so they no longer match the act word for word (STAGE5 step 9).
python3 -I scripts/stage5/quote_fix.py <batch dir> <gate output> <store findings dir> --saved-root <dir>
    [--instruments <store instruments dir>]
Each high quote-not-in-snippet quote is split at "...", "…" and [..] edits (an ellipsis gap, a bracketed letter). When
every piece of 3+ words is found verbatim in the text of an instrument the person has a finding on (operative_text, or
the sha256-checked saved copy under --saved-root), the quote is rewritten as those pieces, each in its own quote
marks, joined by " … ". Research text only: appends trims to <batch>/overrides.json (creates it); apply them with
apply_overrides.py. Prints the quotes it could not fix."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, positional
import csv, glob, hashlib, json, re, subprocess
USAGE = 'quote_fix.py <batch dir> <gate output> <findings dir> --saved-root <dir> [--instruments <dir>]'
B, G, F = positional(3, USAGE); SAVED = opt('--saved-root', required=True, usage=USAGE)
I = opt('--instruments', os.path.join(os.path.dirname(os.path.abspath(F.rstrip('/'))), 'instruments'))
QMAP = str.maketrans({'‘': "'", '’': "'", '“': '"', '”': '"', '–': '-', '—': '-'})
norm = lambda s: re.sub(r'\s+', ' ', s.translate(QMAP)).strip().lower()


def ins_text(iid, _c={}):
    if iid in _c: return _c[iid]
    fs = glob.glob(f'{I}/**/{iid}.json', recursive=True); t = ''
    if fs:
        d = json.load(open(fs[0])); t = d.get('operative_text') or ''
        sc = (d.get('provenance') or {}).get('saved_copy') or {}
        p = os.path.join(SAVED, sc.get('path') or '_none_')
        if os.path.exists(p):
            raw = open(p, 'rb').read()
            if not sc.get('sha256') or hashlib.sha256(raw).hexdigest() == sc['sha256']:
                t += ' ' + (subprocess.run(['pdftotext', '-layout', p, '-'], capture_output=True).stdout.decode('utf-8', 'replace') if raw[:5] == b'%PDF-' else raw.decode('utf-8', 'replace'))
    _c[iid] = norm(t); return _c[iid]


pol = json.load(open(f'{B}/politicians.json')); pol = pol if isinstance(pol, list) else pol['politicians']
pid = {p['full_name']: p['politician_id'] for p in pol}
rows = {r['full_name']: r for r in csv.DictReader(open(f'{B}/research.csv'))}
O = json.load(open(f'{B}/overrides.json')) if os.path.exists(f'{B}/overrides.json') else {'trims': []}
fixed, left, seen = 0, [], set()
for l in open(G):
    m = re.search(r'high\s+quote-not-in-snippet\s+(.*?) / [a-z-]+: .*?: "(.*)"$', l.rstrip())
    if not m: continue
    n, q = m.groups(); t = rows[n]['reasoning']
    if (n, q) in seen: continue
    seen.add((n, q))
    if f'"{q}"' not in t: left.append((n, q, 'quote marks not straight')); continue
    d = json.load(open(f'{F}/{pid[n]}.json'))
    iids = {f.get('instrument_id') for f in (d if isinstance(d, list) else d['findings']) if f.get('instrument_id')}
    texts = [ins_text(i) for i in iids]
    parts = [p.strip(' ,;') for p in re.split(r'\s*(?:\.\.\.|…)\s*|\[[^\]]*\]', q)]
    parts = [p for p in parts if len(p.split()) >= 3]
    if not parts or not all(any(norm(p) in tx for tx in texts) for p in parts): left.append((n, q, 'not in act text')); continue
    new = ' … '.join(f'"{p}"' for p in parts)
    if new == f'"{q}"': left.append((n, q, 'already exact; act text holds it but no cited page does')); continue
    O['trims'].append({'name': n, 'removed': f'"{q}"', 'now': new, 'why': 'coder-edited bill-text quote (ellipsis gap or bracketed letter) split into the exact pieces of the act text; research.csv text only; code file unchanged'})
    fixed += 1
json.dump(O, open(f'{B}/overrides.json', 'w'), indent=1)
print('fixed', fixed, 'left', len(left))
for x in left: print(' ', x[0], '|', x[1][:110], '|', x[2])
