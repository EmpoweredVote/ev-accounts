"""Set-up: skeletons + fills -> staged store instruments, gate rows and subjects. Shared by every state.

  python3 -I scripts/stage5/bill_merge.py --stage5 <stage5 dir> --state xx --seats <lower>,<upper> --date YYYY-MM-DD
      --flag <the fill brief's on-topic key> --topic-list-hash <sha256> [--season 3] [--codebook 0.6] [--out <dir>] [--store <instruments dir>]

Why: as bill_skeletons.py. Each state's `merge_fill_<xx>.py` was a copy of the last, and a copy keeps what nobody
edits: 235 Maryland records say their text was read "from the official Mississippi text". This is the one copy; the
state's name comes from its legislature profile.

Reads, under `<stage5>/legiscan`: `inst-<xx>/*.json` (bill_skeletons.py, then the state's text fetch), `fill/<id>.json`
(the fill wave) and `texts/<id>.*.txt` with the official file saved beside it. Writes, under --out (default
`<stage5>/legiscan`): `store-staging-<xx>/instruments/state-<xx>/<id>.json`, `gates-add-<xx>.tsv`,
`subjects-add-<xx>.json`, `merge-report-<xx>.json`. The staging folder is rebuilt on every run. Nothing is written to
the store: copying the staged files in, and validating, is the session's next step.
- A bill the fill marks off the topic (--flag false: the fill brief's on-topic key, as check_fill_quotes.py takes it) is
  dropped and listed with the fill's reason (`<flag less _policy>_reason`).
- A gate row per chamber, on its last floor vote (a conference or concurrence vote outranks a passage vote of the same
  day): `multi-subject` when the fill says so, else `near-unanimous` when the No votes are under 1 in 10. A bill with
  no floor vote gets a "sponsors only" row, so the pre-fill reads its sponsors.
- --seats: the size of the lower and of the upper chamber, written on each gate row.
Exit 2: a bill of this run is already in the store (merge that one by hand), a text is missing or saved twice, or the
saved file's hash is not the one its text names.
"""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt
import glob, hashlib, json, re, shutil

USAGE = 'bill_merge.py --stage5 <dir> --state xx --seats <lower>,<upper> --date YYYY-MM-DD --flag <key> --topic-list-hash <sha256> [--season 3] [--codebook 0.6] [--out <dir>] [--store <dir>] [--ids <file>]'
HERE = os.path.dirname(os.path.abspath(__file__))
S, xx, SEATS, DATE, HASH, FLAG = (opt(f, required=True, usage=USAGE) for f in ('--stage5', '--state', '--seats', '--date', '--topic-list-hash', '--flag'))
WHY = re.sub(r'_policy$', '', FLAG) + '_reason'
xx = xx.lower(); XX = xx.upper(); L = os.path.join(os.path.abspath(S), 'legiscan')
LOWER, UPPER = (int(n) for n in SEATS.split(','))
if not re.fullmatch(r'\d{4}-\d\d-\d\d', DATE) or not re.fullmatch(r'[0-9a-f]{64}', HASH): print(USAGE); sys.exit(2)
NAME = json.load(open(os.path.join(HERE, '..', '..', 'data', 'legislatures', f'{xx}.json')))['name']
STORE = opt('--store', os.path.normpath(os.path.join(HERE, '..', '..', 'data', 'source-store', 'instruments')))
OUT = opt('--out', L); ST = os.path.join(OUT, f'store-staging-{xx}')
SEASON, CODEBOOK = int(opt('--season', '3')), opt('--codebook', '0.6')
# a saved copy is cited by its path from the workspace root, as the store's other records are
REL = L[L.index('.planning'):] if '.planning' in L else L


def stop(msg):
    print(f'bill merge: {msg}'); sys.exit(2)


def rank(v): return 4 if re.search(r'conference|concur', v['motion'], re.I) else 3


def original(tf):
    """The official file a text was read from, and the text's first line."""
    head = open(tf).readline()
    own = [p for p in glob.glob(tf[:-4] + '.*') if p.endswith(('.htm', '.html', '.pdf'))]
    if own: return own[0], head
    m = re.search(r'(?:same official document as|copied from) (' + XX + r'-[\w-]+\.[\w-]+)\.txt', head)
    if not m: stop(f'{tf}: no official file beside it, and its first line names none')
    return original(f'{L}/texts/{m.group(1)}.txt')[0], head


insts = sorted(glob.glob(f'{L}/inst-{xx}/*.json'))
# --ids <file>: merge only these bills (a late run after the store already holds the rest; Colorado 2026A summaries)
IDS = opt('--ids', None)
if IDS:
    want = {l.strip() for l in open(IDS) if l.strip()}
    insts = [f for f in insts if os.path.basename(f)[:-5] in want]
    if len(insts) != len(want): stop(f'--ids names {len(want)} bills, {len(insts)} have a skeleton')
if not insts: stop(f'no skeleton in {L}/inst-{xx}')
if os.path.isdir(ST): shutil.rmtree(ST)
gates, subjects, dropped, kept, missing = [], {}, [], [], []
for f in insts:
    d = json.load(open(f)); iid = d['id']
    ff = f'{L}/fill/{iid}.json'
    if not os.path.exists(ff): missing.append(iid); continue
    x = json.load(open(ff))
    if FLAG not in x: stop(f'{ff} has no `{FLAG}` key: a wrong --flag would drop every bill')
    if not x[FLAG]: dropped.append((iid, x.get(WHY, ''))); continue
    d.pop('_legiscan')
    out = f'{ST}/instruments/state-{xx}/{iid}.json'; os.makedirs(os.path.dirname(out), exist_ok=True)
    ss = x['single_subject']; multi = ss['verdict'] == 'multi'
    if os.path.exists(f'{STORE}/state-{xx}/{iid}.json'): stop(f'{iid} is already in the store: merge it by hand')
    tfs = glob.glob(f'{L}/texts/{iid}.*.txt')
    if len(tfs) != 1: stop(f'{iid}: {len(tfs)} saved texts, expected 1')
    orig, head = original(tfs[0])
    sha = hashlib.sha256(open(orig, 'rb').read()).hexdigest()
    hs = re.search(r'sha256 ([0-9a-f]{64})', head)
    if hs and hs.group(1) != sha: stop(f'{iid}: the saved file is not the one its text names (sha256)')
    parts = [p.strip() for p in head.lstrip('# ').split(' | ')]
    vtype, vdate, route = parts[1], parts[2], parts[3]
    d['operative_text'] = x['operative_text']
    d['version'] = {'enrolled': 'enrolled', 'as-filed': 'as-filed'}.get(x.get('version_read'), 'other')
    d['single_subject'] = [{'season': SEASON, 'codebook': CODEBOOK, 'topic_list_hash': HASH, 'verdict': 'multi' if multi else 'single', 'other_topics': ss.get('other_topics', [])}]
    if x.get('higher_law_duty'): d['higher_law_duty'] = x['higher_law_duty']
    d['provenance']['saved_copy'] = {'path': f'{REL}/{os.path.relpath(orig, L)}', 'sha256': sha}
    if 'no bill text read' in vtype:  # a summary from the bill page stands in for a text the reader may not fetch
        d['version'] = 'other'
        d['provenance']['fetched_by'] += f"; NO BILL TEXT READ: operative words taken by a fill agent from the legislature's own bill summary ({NAME}) ({vtype}; read {vdate}; {route})"
    else:
        d['provenance']['fetched_by'] += f"; operative text read by a Sonnet fill agent from the official {NAME} text ({vtype}{', ' + vdate if vdate else ''}; {route})"
    if x.get('note'): d['provenance']['note'] = x['note']
    json.dump(d, open(out, 'w'), indent=2, ensure_ascii=False)
    subjects[iid] = x['subjects']
    last = {}
    for v in d['votes']:
        k = (v['date'], rank(v))
        if v['body'] not in last or k >= (last[v['body']]['date'], rank(last[v['body']])): last[v['body']] = v
    for v in last.values():
        tot = v['yes'] + v['no']; gate = 'multi-subject' if multi else ('near-unanimous' if tot and v['no'] / tot < 0.10 else '')
        gates.append([iid, v['date'], v['body'], v['motion'], 'roll-call', v['yes'], v['no'], v.get('absent', ''), UPPER if 'Senate' in v['body'] else LOWER, 'true', 'false',
                      'true' if multi else 'false', gate, f'Stage 5 bill check {DATE} ({XX}): final floor vote in this chamber'])
    if not last:
        gates.append([iid, '', '', 'sponsors only', 'roll-call', '', '', '', '', 'true', 'false', 'true' if multi else 'false', 'multi-subject' if multi else '',
                      f'Stage 5 bill check {DATE} ({XX}): no floor vote; row lets the pre-fill read sponsors'])
    kept.append(iid)
json.dump({'kept': kept, 'dropped': dropped, 'missing': missing, 'merged_existing': []}, open(f'{OUT}/merge-report-{xx}.json', 'w'), indent=1)
with open(f'{OUT}/gates-add-{xx}.tsv', 'w') as g:
    for r in gates: g.write('\t'.join(str(c) for c in r) + '\n')
json.dump(subjects, open(f'{OUT}/subjects-add-{xx}.json', 'w'), indent=1, ensure_ascii=False)
print('kept', len(kept), 'dropped', len(dropped), 'missing fill', len(missing), missing, 'gate rows', len(gates))
