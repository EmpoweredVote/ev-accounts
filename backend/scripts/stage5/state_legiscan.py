"""State votes and sponsorships cited on an official page the verifier cannot use -> LegiScan URLs (STAGE5 step 7.1).
For a state whose findings print NO roll-call number (so legiscan_pairs.py cannot key on one): a vote is matched by
bill, chamber, DATE and TALLY through legiscan-rollcalls.ts. Only a single LegiScan roll call on the finding's date
with its tally is used; same-day ties are broken on the motion text, then on a "Roll Call #N" (Kentucky: "RSN# N" / "RCS# N") in the motion, then
(identical descriptions) on the lowest roll-call id. Anything else goes to legiscan/unmapped.json: hold the person; do
not guess. Committee votes are never mapped (a "Conference Committee Report", and in Kentucky a "Committee Substitute"
or "Committee Amendment" adopted on the floor, is a floor vote and is).
  python3 -I scripts/stage5/state_legiscan.py plan <batch dir> <store findings dir> --state XX --host <host>[,<host>]
      [--bill-pad N] [--year-shift N]                                                    -> legiscan/vote-pages.json
  npx tsx --env-file=.env scripts/stage5/legiscan-rollcalls.ts XX <batch>/legiscan/vote-pages.json <batch>/legiscan/rollcall-hits.json
  python3 -I scripts/stage5/state_legiscan.py pairs <batch dir> <store findings dir> --state XX --host <host>[,<host>]
      --topic <key> [--bill-pad N] [--year-shift N]   -> legiscan/pairs.csv, needs.json, unmapped.json, rollcall-map.json
Then legiscan-evidence-lines.ts and legiscan_merge.py as for legiscan_pairs.py.
--bill-pad: zero-pad bill numbers to N digits (LegiScan prints IN SB0010: 4). --year-shift: add N to the instrument
year when the store's year is not LegiScan's session year. --session-start odd: the state's regular sessions start in odd
years (Ohio): a sponsorship's LegiScan bill page is named by the session's start year, so an even instrument year
maps to the year before (HB472/2026 → https://legiscan.com/OH/bill/HB472/2025). Roll calls need no shift any more:
legiscan-rollcalls.ts matches a vote to every session whose span covers its year."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, positional
import csv, json, re
USAGE = 'state_legiscan.py plan|pairs <batch dir> <findings dir> --state XX --host <host>[,<host>] [--topic <key>] [--bill-pad N] [--year-shift N] [--session-start odd]'
mode, B, F = positional(3, USAGE)
if mode not in ('plan', 'pairs'): raise SystemExit('usage: ' + USAGE)
PAD = int(opt('--bill-pad', '0')); YS = int(opt('--year-shift', '0')); ODD = opt('--session-start', '') == 'odd'
ST = opt('--state', required=True, usage=USAGE); HOSTS = opt('--host', required=True, usage=USAGE).split(',')
TOPIC = opt('--topic', required=mode == 'pairs', usage=USAGE)
SUF = {'Jr.', 'Sr.', 'II', 'III', 'IV', 'Jr', 'Sr'}
# A degree set off by a comma ("Grant L. Campbell, MD") is never the surname: dropped as the verifier's
# lastNameOf does (src/lib/researchVerifier.ts DEGREE), else the pair asks LegiScan for a member named "MD".
DEGREE = re.compile(r'^(m\.?d|ph\.?d|d\.?d\.?s|d\.?m\.?d|d\.?o|d\.?v\.?m|r\.?n|j\.?d|ed\.?d|esq|c\.?p\.?a|m\.?p\.?h|m\.?b\.?a)\.?$', re.I)
def _strip_degrees(n):
    while ',' in n and DEGREE.match(n.rsplit(',', 1)[1].strip()): n = n.rsplit(',', 1)[0]
    return n
last = lambda n: [x for x in _strip_degrees(n).replace(',', ' ').split() if x not in SUF][-1]
pol = json.load(open(f'{B}/politicians.json')); pol = pol if isinstance(pol, list) else pol['politicians']
pid = {p['full_name']: p['politician_id'] for p in pol}
VOTE = ('yea', 'nay', 'abstain'); AUTH = ('author', 'coauthor', 'sponsor', 'cosponsor', 'co-sponsor', 'chief patron', 'patron', 'copatron')


def key(f):
    """bill, year, chamber, tally and date of a vote finding; None when any is missing."""
    m = re.match(ST + r'-([A-Z]+)-(\d+)-(?:SP(\d)-)?(\d{4})$', f.get('instrument_id') or '')  # MO-HB-16-SP1-2020: a special session (mo-01)
    if not m: return None
    txt = (f.get('note') or '') + ' ' + (f.get('motion') or '')
    ch = f.get('chamber') or ('H' if re.search(rf'\b{ST} House\b|\bHouse\b', txt) and not re.search(rf'\b{ST} Senate\b', txt)
                              # a lower chamber named the Assembly (WI, CA, NY, NV, NJ) is chamber 'A' in LegiScan
                              else 'A' if re.search(r'\bAssembly\b', txt) and not re.search(r'\bSenate\b', txt)
                              else 'S' if re.search(r'\bSenate\b', txt) else None)
    t = re.search(r'tally (\d+)\s*[–-]\s*(\d+)', txt) or re.search(r', (\d+)-(\d+)\) on ', txt)  # notes that print '(<motion>, 76-17) on HB139' carry no 'tally' word (ky-01)
    if not ch or not t or not f.get('date'): return None
    return {'bill': m.group(1) + m.group(2).zfill(PAD), 'year': int(m.group(4)) + YS, 'sp': m.group(3), 'chamber': ch, 'yea': int(t.group(1)), 'nay': int(t.group(2)), 'date': f['date'], 'instrument': f['instrument_id']}


def acts():
    """(research row, finding, url) for every record finding cited on a seated row from one of the hosts."""
    for r in csv.DictReader(open(f'{B}/research.csv')):
        if r.get('evidence_type') == 'blank': continue
        urls = [r[c] for c in r if c.startswith('source_url_') and r[c]]
        d = json.load(open(os.path.join(F, pid[r['full_name']] + '.json'))); fs = d if isinstance(d, list) else d['findings']
        for f in fs:
            u = f.get('url') or ''
            if f.get('kind') == 'record' and u in urls and any(h in u for h in HOSTS): yield r, f, u


kid = lambda k: f"{k['instrument']}|{k['chamber']}|{k['date']}|{k['yea']}-{k['nay']}"
if mode == 'plan':
    pages = {}
    for r, f, u in acts():
        if f.get('act') in VOTE and (k := key(f)): pages[kid(k)] = {'url': kid(k), 'bill': k['bill'], 'year': k['year'], 'chamber': k['chamber'], 'yea': k['yea'], 'nay': k['nay']}
    os.makedirs(f'{B}/legiscan', exist_ok=True)
    json.dump(list(pages.values()), open(f'{B}/legiscan/vote-pages.json', 'w'), indent=1); print('vote pages', len(pages))
else:
    hits = {h['url']: h for h in json.load(open(f'{B}/legiscan/rollcall-hits.json'))}
    rmap, needs, unmapped, pairs = {}, {}, [], []
    for r, f, u in acts():
        n, act, ins = r['full_name'], (f.get('act') or '').lower(), f.get('instrument_id') or ''
        if act in VOTE:
            k = key(f)
            if (re.search(r'\bCommittee\b', f.get('motion') or '') and not re.search(r'Conference Committee Report|Committee Substitute|Committee Amendment', f.get('motion') or '', re.I)) or not k: unmapped.append([n, u, ins, f'{act}: no chamber/tally/date or committee']); continue
            hs = [h for h in hits.get(kid(k), {}).get('hits', []) if h['date'] == k['date']]
            # A special session reuses the regular session's bill numbers: keep only the hits from the matching
            # session (LegiScan's special-session bill URL ends /X<n>; a regular one ends with the year).
            hs = [h for h in hs if (re.search(r'/X(\d+)/?$', h['bill_url']) or [None, None])[1] == k['sp']]
            if len(hs) > 1:  # same day, same tally: break the tie on the motion text, then on identical duplicates
                mo = re.sub(r'[^a-z0-9 ]', '', (f.get('motion') or '').lower()).strip()
                by = [h for h in hs if mo and re.sub(r'[^a-z0-9 ]', '', (h.get('desc') or '').lower()).startswith(mo)]
                if by: hs = by
                rc = re.search(r'(?:Roll Call|RSN|RCS) ?#?\s*(\d+)', f.get('motion') or '', re.I)  # KY numbers roll calls RSN#/RCS# (ky-01)
                if len(hs) > 1 and rc: hs = [h for h in hs if re.search(r'#\s*' + rc.group(1) + r'\b', h.get('desc') or '')] or hs
                if len({(h.get('desc') or '').lower() for h in hs}) == 1: hs = sorted(hs, key=lambda h: int(h['roll_call_id']))[:1]
            if len(hs) != 1: unmapped.append([n, u, ins, f'{act}: {len(hs)} LegiScan roll calls on {k["date"]} with {k["yea"]}-{k["nay"]}']); continue
            bill = re.search(r'/bill/([^/]+)/', hs[0]['bill_url']).group(1)  # .../bill/HB16/2020 or .../bill/HB16/2020/X1
            ls = f"https://legiscan.com/{ST}/rollcall/{bill}/id/{hs[0]['roll_call_id']}"; rmap[kid(k)] = {**hs[0], 'legiscan': ls}
        elif act in AUTH:
            m = re.match(ST + r'-([A-Z]+)-(\d+)-(?:SP(\d)-)?(\d{4})$', ins)
            yr = int(m.group(4)) + YS if m else 0
            if ODD and yr % 2 == 0: yr -= 1  # LegiScan's bill page names the session's start year (oh-01, 2026-11-06)
            ls = f"https://legiscan.com/{ST}/bill/{m.group(1)}{m.group(2).zfill(PAD)}/{yr}" + (f"/X{m.group(3)}" if m.group(3) else '') if m else None
            if not ls: unmapped.append([n, u, ins, f'{act}: no bill id']); continue
        else: unmapped.append([n, u, ins, f'act {act} (not a vote or authorship)']); continue
        e = {'url': ls, 'official': u, 'act': act, 'instrument': ins}
        if e not in needs.setdefault(n, []): needs[n].append(e)
        pairs.append((n, last(n), TOPIC, ls))
    pairs = list(dict.fromkeys(pairs))
    json.dump(needs, open(f'{B}/legiscan/needs.json', 'w'), indent=1); json.dump(unmapped, open(f'{B}/legiscan/unmapped.json', 'w'), indent=1)
    json.dump(rmap, open(f'{B}/legiscan/rollcall-map.json', 'w'), indent=1)
    w = csv.writer(open(f'{B}/legiscan/pairs.csv', 'w', newline='')); w.writerow(['full_name', 'last_name', 'topic_key', 'source_url']); w.writerows(pairs)
    print('people', len(needs), 'pairs', len(pairs), 'unmapped', len(unmapped), 'roll calls', len(rmap))
