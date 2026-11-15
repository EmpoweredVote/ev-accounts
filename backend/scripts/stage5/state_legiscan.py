"""State votes and sponsorships cited on an official page the verifier cannot use -> LegiScan URLs (STAGE5 step 7.1).
For a state whose findings print NO roll-call number (so legiscan_pairs.py cannot key on one): a vote is matched by
bill, chamber, DATE and TALLY through legiscan-rollcalls.ts. Only a single LegiScan roll call on the finding's date
with its tally is used; same-day ties are broken on the motion text, then on a "Roll Call #N" (Kentucky: "RSN# N" / "RCS# N") in the motion, then
(identical descriptions) on the lowest roll-call id. Anything else goes to legiscan/unmapped.json: hold the person; do
not guess. Committee votes are never mapped (a conference report, however the motion words it: "Conference Committee
Report", "Conference Committee - Final Passage", "Committee of Conference report"; and in Kentucky a "Committee Substitute" or "Committee Amendment" adopted on
the floor, is a floor vote and is).
With LEGISCAN_DATASETS set (the datasets on disk), a bill's LegiScan number and its session's first year are read from
the datasets, so a state that pads bill numbers (SC prints S0109) or names a bill page by the session's first year
(SC H3594 of 2024 is /H3594/2023) needs no flag. --bill-pad and --session-start apply only to a bill the datasets do
not hold exactly once.
  python3 -I scripts/stage5/state_legiscan.py plan <batch dir> <store findings dir> --state XX --host <host>[,<host>]
      [--bill-pad N] [--year-shift N]                                                    -> legiscan/vote-pages.json
  npx tsx --env-file=.env scripts/stage5/legiscan-rollcalls.ts XX <batch>/legiscan/vote-pages.json <batch>/legiscan/rollcall-hits.json
  python3 -I scripts/stage5/state_legiscan.py pairs <batch dir> <store findings dir> --state XX --host <host>[,<host>]
      --topic <key> [--bill-pad N] [--year-shift N]   -> legiscan/pairs.csv, needs.json, unmapped.json, rollcall-map.json
Then legiscan-evidence-lines.ts and legiscan_merge.py as for legiscan_pairs.py.
A state run from Open States data (scripts/stage5/openstates/; its dataset folders carry .openstates.json) has no
legiscan.com pages. Its vote pairs name the legislature's own roll-call page, taken from the roll call on disk, and
legiscan-evidence-lines.ts reads the line from that page. Its sponsorships keep the official page they are cited on
(listed in legiscan/sponsor-own-page.json). `pairs` prints the unmapped votes grouped by cause.
--bill-pad: zero-pad bill numbers to N digits (LegiScan prints IN SB0010: 4). --year-shift: add N to the instrument
year when the store's year is not LegiScan's session year. --session-start odd: the state's regular sessions start in odd
years (Ohio): a sponsorship's LegiScan bill page is named by the session's start year, so an even instrument year
maps to the year before (HB472/2026 → https://legiscan.com/OH/bill/HB472/2025). Roll calls need no shift any more:
legiscan-rollcalls.ts matches a vote to every session whose span covers its year."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, positional
from _onfile import newest_roll_call
import csv, glob, json, re
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
# A vote on a conference report is a floor vote, however the motion words it. South Carolina, 2026-11-14: "Adopt
# Committee of Conference report" was read as a committee vote, and 23 senators were held for it. Washington,
# wa-01: "House Final Passage as recommended by the Conference Committee (#22)" held five people the same way.
# Utah, 2026-11-15: "House Conference Committee - Final Passage" is the chamber's vote on the report (63-8-4), and 90
# votes on a bill that became law were left out as committee votes.
FLOOR = re.compile(r'Conference Committee|Committee of Conference|Conference Report|Committee Substitute|Committee Amendment', re.I)
committee = lambda mo: bool(re.search(r'\bCommittee\b', mo or '') and not FLOOR.search(mo or ''))


def dataset_bills():
    """(letters, number) -> [(session first year, session last year, LegiScan's bill number)] for the regular sessions
    in the datasets on disk; {} when LEGISCAN_DATASETS is not set."""
    idx, root = {}, os.environ.get('LEGISCAN_DATASETS')
    for d in glob.glob(os.path.join(root, f'{ST}-*', '*', '*', 'bill')) if root else []:
        names = sorted(os.listdir(d))
        if not names: continue
        s = json.load(open(os.path.join(d, names[0])))['bill']['session']
        if int(s.get('special') or 0): continue
        for n in names:
            m = re.match(r'([A-Z]+)0*(\d+)\.json$', n)
            if m: idx.setdefault((m.group(1), int(m.group(2))), []).append((int(s['year_start']), int(s.get('year_end') or s['year_start']), n[:-5]))
    return idx


DS = dataset_bills()


def openstates_bills():
    """(letters, number) -> [(session first year, last year, special 0|1, bill file)] for the datasets on disk that
    were converted from Open States data (scripts/stage5/openstates/; each carries a .openstates.json). Such a bill
    has no legiscan.com page: its roll calls and sponsors are cited on the legislature's own pages."""
    idx, root = {}, os.environ.get('LEGISCAN_DATASETS')
    for top in glob.glob(os.path.join(root, f'{ST}-*')) if root else []:
        if not os.path.exists(os.path.join(top, '.openstates.json')): continue
        for d in glob.glob(os.path.join(top, '*', '*', 'bill')):
            names = sorted(os.listdir(d))
            if not names: continue
            ss = json.load(open(os.path.join(d, names[0])))['bill']['session']
            for n in names:
                m = re.match(r'([A-Z]+)0*(\d+)\.json$', n)
                if m: idx.setdefault((m.group(1), int(m.group(2))), []).append((int(ss['year_start']), int(ss.get('year_end') or ss['year_start']), 1 if int(ss.get('special') or 0) else 0, os.path.join(d, n)))
    return idx


OSB = openstates_bills()


def openstates_bill(letters, num, year, sp):
    """The bill file when the datasets hold this bill once, converted from Open States; else None."""
    hit = [e for e in OSB.get((letters, int(num)), []) if e[0] <= year <= e[1] and bool(e[2]) == bool(sp)]
    return hit[0][3] if len(hit) == 1 else None


def bill_of(letters, num, year, sp=None):
    """(LegiScan bill number, the year its bill page is named by). From the datasets when exactly one regular session
    covering the year holds the bill; else from the flags."""
    hit = [] if sp else [e for e in DS.get((letters, int(num)), []) if e[0] <= year <= e[1]]
    # An older store id form can carry 'HB'/'SB' where the datasets use one letter (fl-01: FL-HB-543-2023 is H0543).
    if not hit and not sp and len(letters) == 2 and letters[1] == 'B':
        hit = [e for e in DS.get((letters[0], int(num)), []) if e[0] <= year <= e[1]]
    if len(hit) == 1: return hit[0][2], hit[0][0]
    return letters + num.zfill(PAD), (year - 1 if ODD and year % 2 == 0 else year)


VOTE = ('yea', 'nay', 'abstain'); AUTH = ('author', 'coauthor', 'sponsor', 'cosponsor', 'co-sponsor', 'chief patron', 'patron', 'copatron')


def key(f):
    """bill, year, chamber, tally and date of a vote finding; None when any is missing."""
    m = re.match(ST + r'-([A-Z]+)-(\d+)-(?:SP(\d)-)?(\d{4})$', f.get('instrument_id') or '')  # MO-HB-16-SP1-2020: a special session (mo-01)
    if not m: return None
    txt = (f.get('note') or '') + ' ' + (f.get('motion') or '')
    # A note that opens with the voting body ("CA Assembly, SB 2 ... Senate Third Reading") names the chamber; the
    # motion text names the bill's house of origin, so it must not decide (ca-01: 10 Assembly votes on Senate bills).
    lead = re.match(rf'{ST} (House|Assembly|Senate)\b', f.get('note') or '')
    ch = f.get('chamber') or ({'House': 'H', 'Assembly': 'A', 'Senate': 'S'}[lead.group(1)] if lead else None) or ('H' if re.search(rf'\b{ST} House\b|\bHouse\b', txt) and not re.search(rf'\b{ST} Senate\b', txt)
                              # a lower chamber named the Assembly (WI, CA, NY, NV, NJ) is chamber 'A' in LegiScan
                              else 'A' if re.search(r'\bAssembly\b', txt) and not re.search(r'\bSenate\b', txt)
                              else 'S' if re.search(r'\bSenate\b', txt) else None)
    t = re.search(r'tally (\d+)\s*[–-]\s*(\d+)', txt) or re.search(r', (\d+)-(\d+)\) on ', txt)  # notes that print '(<motion>, 76-17) on HB139' carry no 'tally' word (ky-01)
    # a motion that ends '(RSN# 3461), 26-11' names its tally after the roll-call number (ky-02: Bledsoe's four votes)
    t = t or re.search(r'\((?:RSN|RCS)\s*#\s*\d+\),\s*(\d+)\s*[–-]\s*(\d+)', txt)
    if not ch or not t or not f.get('date'): return None
    return {'bill': bill_of(m.group(1), m.group(2), int(m.group(4)) + YS, m.group(3))[0], 'year': int(m.group(4)) + YS, 'sp': m.group(3), 'chamber': ch, 'yea': int(t.group(1)), 'nay': int(t.group(2)), 'date': f['date'], 'instrument': f['instrument_id']}


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
    rmap, needs, unmapped, pairs, own_page = {}, {}, [], [], []
    for r, f, u in acts():
        n, act, ins = r['full_name'], (f.get('act') or '').lower(), f.get('instrument_id') or ''
        if act in VOTE:
            k = key(f)
            if committee(f.get('motion')): unmapped.append([n, u, ins, f"{act}: a committee vote ({(f.get('motion') or '')[:60]})"]); continue
            if not k: unmapped.append([n, u, ins, f'{act}: the finding lacks a bill id, chamber, tally or date']); continue
            hs = [h for h in hits.get(kid(k), {}).get('hits', []) if h['date'] == k['date']]
            # A special session reuses the regular session's bill numbers: keep only the hits from the matching
            # session (LegiScan's special-session bill URL ends /X<n>; a regular one ends with the year).
            # An Open States hit has no LegiScan URL; it says itself whether its session is a special one.
            hs = [h for h in hs if (bool(h.get('special')) == bool(k['sp']) if h.get('openstates') else (re.search(r'/X(\d+)/?$', h['bill_url']) or [None, None])[1] == k['sp'])]
            if len(hs) > 1:  # same day, same tally: break the tie on the motion text, then on identical duplicates
                mo = re.sub(r'[^a-z0-9 ]', '', (f.get('motion') or '').lower()).strip()
                by = [h for h in hs if mo and re.sub(r'[^a-z0-9 ]', '', (h.get('desc') or '').lower()).startswith(mo)]
                if by: hs = by
                rc = re.search(r'(?:Roll Call|RSN|RCS) ?#?\s*(\d+)', f.get('motion') or '', re.I)  # KY numbers roll calls RSN#/RCS# (ky-01)
                if len(hs) > 1 and rc: hs = [h for h in hs if re.search(r'#\s*' + rc.group(1) + r'\b', h.get('desc') or '')] or hs
                if len({(h.get('desc') or '').lower() for h in hs}) == 1: hs = sorted(hs, key=lambda h: int(h['roll_call_id']))[:1]
            if len(hs) != 1:
                why = f'{act}: {len(hs)} LegiScan roll calls on {k["date"]} with {k["yea"]}-{k["nay"]}'
                # a dataset is a snapshot: say so when the vote is later than its last roll call
                last_day = newest_roll_call(os.environ['LEGISCAN_DATASETS'], ST)[0] if not hs and os.environ.get('LEGISCAN_DATASETS') else None
                if last_day and k['date'] > last_day: why += f' (the vote is NEWER than the datasets on disk, whose last roll call is {last_day}: it needs a newer download or the live API, on the runner\'s yes)'
                unmapped.append([n, u, ins, why]); continue
            if hs[0].get('openstates'):
                # No legiscan.com page exists for a roll call converted from Open States data: cite the
                # legislature's own roll-call page, which the verifier reads (src/lib/stateRollCallEvidence.ts).
                ls = hs[0].get('state_link') or ''
                if not ls: unmapped.append([n, u, ins, f'{act}: the roll call is from Open States data and names no page of the legislature']); continue
            else:
                bill = re.search(r'/bill/([^/]+)/', hs[0]['bill_url']).group(1)  # .../bill/HB16/2020 or .../bill/HB16/2020/X1
                ls = f"https://legiscan.com/{ST}/rollcall/{bill}/id/{hs[0]['roll_call_id']}"
            rmap[kid(k)] = {**hs[0], 'legiscan': ls}
        elif act in AUTH:
            m = re.match(ST + r'-([A-Z]+)-(\d+)-(?:SP(\d)-)?(\d{4})$', ins)
            if m and openstates_bill(m.group(1), m.group(2), int(m.group(4)) + YS, m.group(3)):
                # A sponsorship on a bill converted from Open States data has no LegiScan page to line. It keeps the
                # official page it is cited on, and the verifier reads that page's own words as for any source.
                own_page.append([n, u, ins, act]); continue
            # LegiScan's bill page names the session's start year (oh-01, 2026-11-06) and its own spelling of the number
            bn, yr = bill_of(m.group(1), m.group(2), int(m.group(4)) + YS, m.group(3)) if m else (None, 0)
            ls = f"https://legiscan.com/{ST}/bill/{bn}/{yr}" + (f"/X{m.group(3)}" if m.group(3) else '') if m else None
            if not ls: unmapped.append([n, u, ins, f'{act}: no bill id']); continue
        else: unmapped.append([n, u, ins, f'act {act} (not a vote or authorship)']); continue
        e = {'url': ls, 'official': u, 'act': act, 'instrument': ins}
        if e not in needs.setdefault(n, []): needs[n].append(e)
        pairs.append((n, last(n), TOPIC, ls))
    pairs = list(dict.fromkeys(pairs))
    json.dump(needs, open(f'{B}/legiscan/needs.json', 'w'), indent=1); json.dump(unmapped, open(f'{B}/legiscan/unmapped.json', 'w'), indent=1)
    json.dump(rmap, open(f'{B}/legiscan/rollcall-map.json', 'w'), indent=1)
    json.dump(own_page, open(f'{B}/legiscan/sponsor-own-page.json', 'w'), indent=1)
    w = csv.writer(open(f'{B}/legiscan/pairs.csv', 'w', newline='')); w.writerow(['full_name', 'last_name', 'topic_key', 'source_url']); w.writerows(pairs)
    print('people', len(needs), 'pairs', len(pairs), 'unmapped', len(unmapped), 'roll calls', len(rmap),
          *(['· sponsorships left on the official page (Open States bills, no LegiScan page)', len(own_page)] if own_page else []))
    by_why = {}
    for x in unmapped: by_why[re.sub(r'\d+', 'N', x[3].split(' (')[0])[:90]] = by_why.get(re.sub(r'\d+', 'N', x[3].split(' (')[0])[:90], 0) + 1
    for why, c in sorted(by_why.items(), key=lambda kv: -kv[1]): print(f'  unmapped {c}: {why}')
