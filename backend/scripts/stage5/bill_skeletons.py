"""Set-up: one instrument skeleton per core bill of a state run from Open States data. Shared by every state.

  python3 -I scripts/stage5/bill_skeletons.py --stage5 <stage5 dir> --state xx --topic <key>
      [--vote-source "<text>"] [--sponsor-version "<text>"] [--no-note-link] [--out <dir>] [--store <instruments dir>]

Why: each state copied `legiscan/scripts/build_skeletons_<xx>.py` from the state before and edited it. The copies
differed only in the state's code and name, and each carried what it forgot to edit: the store path of another
session's worktree (Maryland's copy of Mississippi's), a header that described the state before (Kansas). This is the
one copy. It writes nothing outside --out (default `<stage5>/legiscan/inst-<xx>`), and reads the store of THIS checkout.

Reads, under `<stage5>/legiscan`: `bills-<xx>.json` (scan_bills.py), `core-bills-<xx>.json`, `idmap.tsv`, the datasets
`ds/<XX>-<sid>/<XX>/<session>/`, and `<stage5>/<xx>/scope.tsv` (politician_id, name). The state's name and its
roll-call host come from the legislature profile (`data/legislatures/<xx>.json`).
- Floor votes: only the roll calls convert.py placed from the legislature's own record (`_openstates.from_legislature`),
  in chamber H or S. Every other dump vote is a committee vote or not placed. Two roll calls with one date, body and
  tally are one vote (the later roll call is kept).
- Sponsors: the dump's list, committee sponsors left out. --sponsor-version says where the list is from when the state's
  reader proved it against the text ("introduced text (By:)"); the default is "Open States sponsor list".
- Ids: <XX>-<type>-<n>-<year>, plus -S<n> for a special session.
- Identity: idmap.tsv, then an exact first (or nickname) and last name that fits one person of the scope.
Exit 2 when it would overwrite a skeleton it did not make in this run, or an input is missing.
"""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt
import collections, csv, datetime, glob, json, re, unicodedata

USAGE = 'bill_skeletons.py --stage5 <dir> --state xx --topic <key> [--vote-source <text>] [--sponsor-version <text>] [--no-note-link] [--out <dir>] [--store <dir>]'
HERE = os.path.dirname(os.path.abspath(__file__))
S, xx, TOPIC = (opt(f, required=True, usage=USAGE) for f in ('--stage5', '--state', '--topic'))
xx = xx.lower(); XX = xx.upper(); L = os.path.join(S, 'legiscan')
prof = json.load(open(os.path.join(HERE, '..', '..', 'data', 'legislatures', f'{xx}.json')))
NAME, HOST = prof['name'], ((prof.get('votes') or {}).get('official_hosts') or [''])[0]
STORE = opt('--store', os.path.normpath(os.path.join(HERE, '..', '..', 'data', 'source-store', 'instruments')))
OUT = opt('--out', os.path.join(L, f'inst-{xx}'))
VOTE_SRC = opt('--vote-source', f'{HOST} roll call (read from the legislature)')
SPONSOR_VER = opt('--sponsor-version', 'Open States sponsor list')
NOTE_LINK = '--no-note-link' not in sys.argv

for need in (f'{L}/bills-{xx}.json', f'{L}/core-bills-{xx}.json', f'{L}/idmap.tsv', f'{S}/{xx}/scope.tsv'):
    if not os.path.exists(need): print(f'bill skeletons: {need} is missing'); sys.exit(2)
bills = {b['bill_id']: b for b in json.load(open(f'{L}/bills-{xx}.json'))}
core = json.load(open(f'{L}/core-bills-{xx}.json'))
idmap = {int(p[0]): p[1] for p in (l.rstrip('\n').split('\t') for l in open(f'{L}/idmap.tsv')) if len(p) >= 2 and p[0].strip().isdigit()}
norm = lambda s: re.sub(r'[^a-z]', '', unicodedata.normalize('NFD', s or '').encode('ascii', 'ignore').decode().lower())
byname = {}
for r in csv.DictReader(open(f'{S}/{xx}/scope.tsv'), delimiter='\t'):
    p = [x for x in re.sub(r'"[^"]*"', '', r['name']).replace(',', '').split() if norm(x) not in ('jr', 'sr', 'ii', 'iii', 'iv', 'dr') and not re.match(r'^[A-Z]\.$', x)]
    byname.setdefault((norm(p[0]), norm(p[-1])), set()).add(r['politician_id'])


def pid_for(lsid, first, last, nick=''):
    if lsid in idmap: return idmap[lsid]
    for fn in (first, nick):
        c = byname.get((norm(fn), norm(last)), set())
        if fn and len(c) == 1: return next(iter(c))
    return None


VOTE = {1: 'yea', 2: 'nay', 3: 'absent', 4: 'absent'}
now = datetime.datetime.now(datetime.timezone.utc).isoformat().replace('+00:00', 'Z')
os.makedirs(OUT, exist_ok=True)
made, existing, unnamed = [], [], collections.Counter()
for bid in core:
    x = bills[bid]
    sess = glob.glob(f"{L}/ds/{XX}-{x['sid']}/{XX}/*")[0]
    b = json.load(open(f"{sess}/bill/{x['num']}.json"))['bill']
    people = {}
    for f in glob.glob(f'{sess}/people/*.json'):
        p = json.load(open(f))['person']; people[p['people_id']] = p
    texts = [t for t in b['texts'] if t.get('state_link')]
    sponsors = []
    for s in b['sponsors']:
        if s.get('committee_sponsor'): continue
        e = {'name': s['name'], 'role': 'prime' if s['sponsor_type_id'] in (1, 3) else 'co', 'version': SPONSOR_VER}
        pid = pid_for(s['people_id'], s['first_name'], s['last_name'], (people.get(s['people_id']) or {}).get('nickname', ''))
        if pid: e['politician_id'] = pid
        sponsors.append(e)
    votes = []
    for v in b['votes']:
        f = f"{sess}/vote/{v['roll_call_id']}.json"
        if not os.path.exists(f): continue
        rc = json.load(open(f))['roll_call']
        if not (rc.get('_openstates') or {}).get('from_legislature') or rc['chamber'] not in ('H', 'S'): continue
        mem = []
        for mv in rc['votes']:
            p = people.get(mv['people_id'], {}); e = {'name': p.get('name', str(mv['people_id'])), 'vote': VOTE.get(mv['vote_id'], 'absent')}
            pid = pid_for(mv['people_id'], p.get('first_name', ''), p.get('last_name', ''), p.get('nickname', ''))
            if pid: e['politician_id'] = pid
            elif not p: unnamed[x['num']] += 1
            mem.append(e)
        votes.append({'date': rc['date'], 'body': f"{XX} {'House' if rc['chamber'] == 'H' else 'Senate'}", 'motion': re.sub(r'\s+', ' ', rc['desc']).strip(), 'kind': 'roll-call',
                      'yes': rc['yea'], 'no': rc['nay'], 'absent': rc['absent'] + rc['nv'],
                      'note': f"{VOTE_SRC} {rc['roll_call_id']}" + (f" {rc.get('state_link', '')}" if NOTE_LINK else ''), 'members': mem, '_rc': rc['roll_call_id']})
    seen = {}
    for v in sorted(votes, key=lambda v: (v['date'], v['_rc'])): seen[(v['date'], v['body'], v['yes'], v['no'])] = v
    votes = list(seen.values())
    for v in votes: v.pop('_rc')
    m = re.match(r'([A-Z]+)(\d+)$', x['num']); iid = f"{XX}-{m.group(1)}-{int(m.group(2))}-{x['y']}" + (f"-S{x['special']}" if x['special'] else '')
    if os.path.exists(f'{STORE}/state-{xx}/{iid}.json'): existing.append(iid)
    t = ([t for t in texts if t['type'] in ('Enrolled', 'Chaptered')] or texts or [None])[-1]
    enrolled = any(t['type'] in ('Enrolled', 'Chaptered') for t in texts)
    # `bill_file` is written as the older per-state scripts wrote it, relative to <stage5>/legiscan
    inst = {'id': iid, 'scope': f'state:{xx}', 'title': f"{x['num']} ({x['sess'].replace(' Session', '')}): {b['title']}", 'urls': [b['state_link']] + ([t['state_link']] if t else []),
            'version': 'enrolled' if enrolled else 'as-filed', 'sponsors': sponsors, 'single_subject': [], 'votes': votes,
            'provenance': {'fetched_by': f'Open States bulk data ({NAME}) ({TOPIC} Stage 5, {NAME})', 'fetched_at': now, 'method': 'api'},
            '_legiscan': {'bill_id': bid, 'bill_file': os.path.relpath(f"{sess}/bill/{x['num']}.json", L), 'status': x['status'], 'desc': b.get('description', ''),
                          'read': [{'type': t['type'], 'date': t.get('date', ''), 'doc_id': t.get('doc_id'), 'url': t['state_link']}] if t else [],
                          'text_docs': [{'type': t['type'], 'mime': t.get('mime'), 'doc_id': t.get('doc_id')} for t in texts]}}
    p = f'{OUT}/{iid}.json'
    if os.path.exists(p) and iid not in made and '--replace' not in sys.argv:
        print(f'bill skeletons: {p} exists and this run did not make it. Nothing more is written; pass --replace to rebuild every skeleton.'); sys.exit(2)
    json.dump(inst, open(p, 'w'), indent=1, ensure_ascii=False); made.append(iid)
read = lambda i: json.load(open(f'{OUT}/{i}.json'))
print('made', len(made), 'already in store', existing)
print('floor-vote bills', sum(1 for i in made if read(i)['votes']), 'no-text', [i for i in made if not read(i)['_legiscan']['read']])
if unnamed: print('votes by people missing from the people files', dict(unnamed))
