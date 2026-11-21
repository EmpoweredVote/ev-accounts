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
# California, 2026-11-20: a bill a committee wrote names its author after the bill number ("3rd Reading SB843 Committee
# On B. & F.R. (Leno)", "Assembly 3rd Reading AB1602 Committee On BUDGET (Ting)"), and five floor votes of 2015 were held.
FLOOR = re.compile(r'Conference Committee|Committee of Conference|Conference Report|Committee Substitute|Committee Amendment|'
                   r'\b[A-Z]{1,4} ?\d+ Committee On\b', re.I)
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


def or_sponsor_named(by, full_name):
    """True when an Oregon sponsor line names the person. OLIS prints family names in capitals and adds the given
    names' initials only when two members share the family name ("LEVY B" Bobby Levy, "LEVY E" Emerson Levy,
    "SMITH DB" David Brock Smith, "SMITH G" Greg Smith). An entry with initials names the person only when they are
    the person's own: a family name alone never decides between two such members."""
    import unicodedata
    fold = lambda s: ''.join(c for c in unicodedata.normalize('NFKD', s) if not unicodedata.combining(c)).upper()
    toks = [x.strip(',.') for x in fold(full_name).replace('-', ' ').split() if x.strip(',.')]
    while len(toks) > 1 and toks[-1] in ('JR', 'SR', 'II', 'III', 'IV', 'V'): toks.pop()
    if not toks: return False
    # The legislature names each member as of today; a text prints the name of its day (legislatures/or.json).
    fam = [toks[-1:]] + [x.split() for x in OR_FORMER.get(' '.join(toks), [])]
    for e in re.split(r'[,;]|\bAND\b', fold(by).replace('-', ' ')):
        w = [x for x in e.replace('.', ' ').split() if x not in ('REPRESENTATIVE', 'REPRESENTATIVES', 'SENATOR', 'SENATORS', 'SPEAKER', 'PRESIDENT')]
        while len(w) > 1 and w[-1] in ('JR', 'SR', 'II', 'III', 'IV'): w.pop()  # "MANNING JR" is no initial
        if not w: continue
        ini = w.pop() if len(w) > 1 and len(w[-1]) <= 2 else ''
        k = len(w)
        if k <= len(toks) - 1 and toks[-k:] == w: given = ''.join(x[0] for x in toks[:-k])
        elif w in fam[1:]: given = toks[0][0]
        else: continue
        if not ini or given.startswith(ini): return True
    return False


# Members whose texts print an earlier family name (legislatures/or.json, "The Legislature's list names each member as
# of today"): Sheri Schouten voted as Sheri Malstrom in 2017, and so on.
OR_FORMER = {'SHERI SCHOUTEN': ['MALSTROM'], 'SARA GELSER BLOUIN': ['GELSER'], 'ELIZABETH STEINER': ['STEINER HAYWARD'],
             'COURTNEY NERON MISSLIN': ['NERON']}


def _text_line(bill_file, cited, full_name, pick=None):
    """(the converted bill's introduced text, its "Introduced by:" line, why there is no line) for a sponsorship;
    (None, None, None) when the bill's page is not an introduced text other than the cited page.
    South Dakota (runner, 2026-11-17): a sponsorship is cited on the bill's introduced text, and convert.py makes that
    PDF the bill's own page (sd_sponsors_from_text). The store's findings were written with the bill page
    (/Session/Bill/<id>, a script shell no reader can use) as their url, so the gate found no snippet for it (sd-01,
    44 high). The text is cited instead, and the line is the text's own words from the bill's name through
    "Introduced by: ..." into the title, at least 25 words, read as the verifier reads a PDF (pdftotext, spaces closed).
    The person's surname must be printed in the "Introduced by:" part, or there is no line (the person is held)."""
    import hashlib, subprocess, time
    b = json.load(open(bill_file))['bill']
    tl = b.get('state_link') or ''
    # convert.py points the bill's page at the introduced text's PDF; 2018 and 2019 bills still list the old HTML
    # address under texts[] (sd-01: 14 bills), so the PDF page itself, not the texts list, decides.
    has_intro = any(t.get('type') == 'Introduced' for t in b.get('texts') or [])
    # Nevada (runner, 2026-11-21): the bill's page is the NELIS Overview, whose sponsor panel loads by script and
    # prints no name. The introduced text prints the sponsors on its first line ("ASSEMBLY BILL NO. 167–ASSEMBLYMEN
    # HAFEN, TITUS, ..."), so it is cited. The dump types every reprint "Introduced": the as-introduced PDF is the one
    # whose file name carries no _R1/_EN suffix.
    if ST == 'NV':
        intro = [x.get('state_link') or '' for x in b.get('texts') or []]
        intro = [x for x in intro if re.search(r'/Bills/[A-Z]+/[A-Z]+\d+\.pdf$', x)]
        tl = pick or (intro[0] if intro else '')
    # Oregon (runner, 2026-11-21): the bill's page is the OLIS Overview, which our reader gets as a menu with no
    # sponsor names. The introduced text prints them ("Sponsored by Representative MORGAN; Representatives CATE,
    # LEVY B, ..."), so it is cited. OLIS text addresses carry no .pdf: the body's %PDF- mark decides.
    if ST == 'OR':
        intro = [x.get('state_link') or '' for x in b.get('texts') or []]
        intro = [x for x in intro if re.search(r'/Downloads/MeasureDocument/[A-Z]+\d+/Introduced$', x)]
        tl = pick or (intro[0] if intro else '')
    if not tl or tl == cited or not has_intro or not (tl.lower().endswith('.pdf') or ST == 'OR'): return None, None, None
    f = f'{B}/pages/{hashlib.sha1(tl.encode()).hexdigest()}.txt'
    if os.path.exists(f): t = open(f).read()
    else:
        time.sleep(1)
        r = subprocess.run(['curl', '-sL', '--compressed', '--max-time', '40', '-w', '\n%{http_code}', '-A', 'Mozilla/5.0', tl], capture_output=True)
        body, _, status = r.stdout.rpartition(b'\n')
        if body[:5] != b'%PDF-' or not status.startswith(b'2'): return tl, None, f'the introduced text {tl} did not load (HTTP {status.decode()})'
        t = re.sub(r'\s+', ' ', subprocess.run(['pdftotext', '-layout', '-', '-'], input=body, capture_output=True).stdout.decode('utf-8', 'replace')).strip()
        os.makedirs(os.path.dirname(f), exist_ok=True); open(f, 'w').write(t)
    # 2020 on prints "House Bill 1227 Introduced by: ..."; 2018 and 2019 print "HOUSE BILL NO. 1041 Introduced by: ...".
    if ST == 'NV':
        # "ASSEMBLY BILL NO. 167–ASSEMBLYMEN HAFEN, ...; HANSEN, ... AND WHEELER FEBRUARY 15, 2019" (or "Prefiled ...")
        m = re.search(r'(?:ASSEMBLY|SENATE)\s+(?:BILL|JOINT RESOLUTION|CONCURRENT RESOLUTION|RESOLUTION)\s+NO\.\s*\d+\s*[–—-]\s*', t)
        if not m: return tl, None, f'no "BILL NO. n–" sponsor line in {tl}'
        head = re.split(r'\s+(?:Referred to|SUMMARY)', t[m.end():], maxsplit=1)[0]
        by = re.split(r'\s+(?:(?:JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\s+\d|Prefiled|PREFILED)', head, maxsplit=1)[0]
        # A Senate bill can name Assembly members after the date ("JOINT SPONSORS: ASSEMBLYMEN TITUS, ELLISON; ..."), and the reverse.
        js = re.search(r'JOINT SPONSORS?:\s*(.*)', head)
        if js: by += ' JOINT SPONSORS: ' + js.group(1)
        end = m.end() + len(head if js else by)
    elif ST == 'OR':
        # "House Bill 2936 Sponsored by Representative MORGAN; Representatives CATE, LEVY B, SMITH DB, ..., Senators
        # FINDLEY, ... (Presession filed.) SUMMARY ..."; a committee bill prints "Sponsored by COMMITTEE ON ...".
        m = re.search(r'(?:(?:House|Senate)\s+(?:Bill|Joint Resolution|Concurrent Resolution|Joint Memorial|Memorial|Resolution)\s+\d+\s+)?Sponsored by\s*', t)
        if not m: return tl, None, f'no "Sponsored by" line in {tl}'
        by = re.split(r'\s*(?:\((?:at the request of|Presession|by order)|SUMMARY\b|The following summary|A BILL FOR AN ACT|Relating to|CHAPTER\b)', t[m.end():], maxsplit=1)[0]
        end = m.end() + len(by)
        # A name split at a line end ("GELSER BLOU-" / "IN") is rejoined for the match.
        by = re.sub(r'(\w)- (\w)', r'\1\2', by)
        return (tl, None, f'{full_name} is not printed in the sponsor line of {tl}') if not or_sponsor_named(by, full_name) else \
            (tl, ' '.join(t[m.start():].split(' ')[:min(max(len(t[m.start():end].split(' ')) + 8, 25), 80)]), None)
    else:
        m = re.search(r'(?:(?:House|Senate)\s+(?:Bill|Joint Resolution|Concurrent Resolution|Commemoration|Resolution)\s+(?:No\.\s*)?\d+\s+)?Introduced by:\s*', t, re.I)
        if not m: return tl, None, f'no "Introduced by:" line in {tl}'
        rest = t[m.end():]
        by = re.split(r'\s+(?:FOR AN ACT|An Act|A LEGISLATIVE|A (?:CONCURRENT|JOINT) RESOLUTION|ENTITLED)\b', rest, maxsplit=1)[0]
        end = m.end() + len(by)
    toks = [x.strip(',.') for x in full_name.split()]
    while len(toks) > 1 and toks[-1].lower() in ('jr', 'sr', 'ii', 'iii', 'iv', 'v'): toks.pop()
    sur = toks[-1] if toks else ''
    import unicodedata
    fold = lambda s: ''.join(c for c in unicodedata.normalize('NFKD', s) if not unicodedata.combining(c))
    # Nevada prints names in capitals without accents ("DONATE" for Doñate): compare with accents dropped.
    if not sur or not re.search(r'\b' + re.escape(fold(sur)) + r'\b', fold(by), re.I): return tl, None, f'{sur} is not printed in the sponsor line of {tl}'
    words = t[m.start():].split(' ')
    n = max(len(t[m.start():end].split(' ')) + 8, 25)
    return tl, ' '.join(words[:min(n, 80)]), None


def hi_introducer_line(cited, full_name):
    """Hawaii (runner, 2026-11-21, hi/desk/QUESTION-B-2.md "A"): bill texts print no sponsor names ("INTRODUCED BY:
    ____"), so a sponsorship stays cited on the bill's status page on www.capitol.hawaii.gov, and its line is the
    page's "Introducer(s): TARNAS, AMATO, ..." read from the same page on data.capitol.hawaii.gov (www answers a reader
    403), as votes are. The person's family name must be printed there, or there is no line (the person is held)."""
    import hashlib, subprocess, time, html as _h, unicodedata
    if 'measure_indiv' not in cited: return None, None, None
    rd = re.sub(r'^https?://www\.capitol\.hawaii\.gov', 'https://data.capitol.hawaii.gov', cited.split('#')[0])
    f = f'{B}/pages/{hashlib.sha1(rd.encode()).hexdigest()}.txt'
    if os.path.exists(f): t = open(f).read()
    else:
        time.sleep(1)
        r = subprocess.run(['curl', '-sL', '--compressed', '--max-time', '40', '-w', '\n%{http_code}', '-A', 'Mozilla/5.0', rd], capture_output=True)
        body, _, status = r.stdout.rpartition(b'\n')
        if not status.startswith(b'2'): return cited, None, f'the status page {rd} did not load (HTTP {status.decode()})'
        t = re.sub(r'\s+', ' ', _h.unescape(re.sub(r'<[^>]+>', ' ', body.decode('utf-8', 'replace')))).strip()
        os.makedirs(os.path.dirname(f), exist_ok=True); open(f, 'w').write(t)
    m = re.search(r'Introducer\(s\):\s*(.*?)\s+(?:Act:|Measure Status|Current Referral|Companion)', t)
    if not m: return cited, None, f'no "Introducer(s):" line on {rd}'
    by = m.group(1)
    toks = [x.strip(',.') for x in full_name.split()]
    while len(toks) > 1 and toks[-1].lower() in ('jr', 'sr', 'ii', 'iii', 'iv', 'v'): toks.pop()
    sur = toks[-1] if toks else ''
    fold = lambda s: ''.join(c for c in unicodedata.normalize('NFKD', s) if not unicodedata.combining(c)).replace('ʻ', '').replace("'", '')
    # Whole entries only, so "LEE" never matches inside "KEOHOKAPU-LEE LOY"; an entry's printed initial ("LEE, C.",
    # "S. CHANG"), printed when two members share a family name, must be the person's first initial.
    # "NAKAMURA (Introduced by request of another party)": the note is dropped for the match and kept in the snippet.
    ents, parts = [], [x.strip() for x in re.sub(r'\([^)]*\)', ' ', fold(by)).split(',') if x.strip()]
    for x in parts:
        if re.fullmatch(r'[A-Za-z]\.', x) and ents: ents[-1] = (ents[-1][0], x[0].upper())
        else:
            mi = re.match(r'([A-Za-z])\.\s*(.+)$', x)
            ents.append((mi.group(2), mi.group(1).upper()) if mi else (x, ''))
    names = {fold(sur).lower(), fold(' '.join(toks[-2:])).lower() if len(toks) > 2 else ''}
    first = fold(toks[0])[:1].upper() if toks else ''
    if not sur or not any(e.lower() in names and (not i or i == first) for e, i in ents):
        return cited, None, f'{sur} is not printed in the Introducer(s) line of {rd}'
    # The line runs from the page's own heading ("HB427 Measure details Measure Title: ...") through the Introducer(s)
    # list, so the snippet prints the bill number the gate looks for (hi-01 gate run 2: 46 instrument-not-cited).
    # The heading can carry the draft and a button: "SB308 SD2 Subscribe Measure details" (hi-01 replay 4: 61 short snippets).
    hs = [h for h in re.finditer(r'\b[HS][BR]\d+\b[^.:]{0,40}?Measure details\b', t[:m.start()])]
    st = hs[-1].start() if hs and m.start() - hs[-1].start() < 1500 else m.start()
    return cited, t[st:m.end(1)].strip(), None


def introduced_text_line(bill_file, cited, full_name):
    """See _text_line. Nevada: a member added as a joint sponsor after introduction is printed first on a reprint
    ("JOINT SPONSOR: SENATOR SCHEIBLE" on 2021 AB 286's third reprint, not on the introduced text), so when the
    introduced text does not print the person, the earliest reprint (_R1, _R2, ...) that does is cited."""
    if ST == 'HI': return hi_introducer_line(cited, full_name)
    first = _text_line(bill_file, cited, full_name)
    if ST not in ('NV', 'OR') or not first[0] or first[1]: return first
    if ST == 'OR':
        # Oregon: a sponsor added after introduction is printed first on an engrossed or the enrolled text (2023 HB 2005:
        # FAHEY on A-Engrossed, GAMBA and NELSON on Enrolled), so the earliest later text that prints the person is cited.
        # A proposed amendment ("House Amendments to A-Engrossed", /ProposedAmendment/) is not a bill text.
        vs = [x.get('state_link') or '' for x in json.load(open(bill_file))['bill'].get('texts') or []]
        vs = sorted({x for x in vs if re.search(r'/Downloads/MeasureDocument/[A-Z]+\d+/(?:[A-Z]-Engrossed|Enrolled)$', x)}, key=lambda x: (x.endswith('Enrolled'), x))
        for v in vs:
            got = _text_line(bill_file, cited, full_name, pick=v)
            if got[1]: return got
        return first
    reps = [x.get('state_link') or '' for x in json.load(open(bill_file))['bill'].get('texts') or []]
    reps = sorted({x for x in reps if re.search(r'/Bills/[A-Z]+/[A-Z]+\d+_R\d+\.pdf$', x)}, key=lambda x: int(re.search(r'_R(\d+)\.pdf$', x).group(1)))
    for r in reps:
        got = _text_line(bill_file, cited, full_name, pick=r)
        if got[1]: return got
    return first


VOTE = ('yea', 'nay', 'abstain'); AUTH =('author', 'coauthor', 'sponsor', 'cosponsor', 'co-sponsor', 'chief patron', 'patron', 'copatron')


def key(f):
    """bill, year, chamber, tally and date of a vote finding; None when any is missing."""
    m = re.match(ST + r'-([A-Z]+)(?:\d{2})?-(\d+)-(?:SP(\d)-)?(\d{4})$', f.get('instrument_id') or '')  # MO-HB-16-SP1-2020: a special session (mo-01); CO-SB25-003-2025: year in the number (co-01)
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
    rmap, needs, unmapped, pairs, own_page, text_lines, text_why = {}, {}, [], [], [], [], []
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
            # convert.py keeps a dump row the legislature's record did not place as "<Chamber> Committee or not placed
            # (...)", so that no step maps it; the record's own copy is the vote (co-01: SB25-003's House third reading
            # and Senate concurrence each had both, and the finding's motion wording matched neither, so 49 were held).
            hs = [h for h in hs if not (h.get('openstates') and re.match(r'\w+ Committee or not placed\b', h.get('desc') or ''))]
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
            m = re.match(ST + r'-([A-Z]+)(?:\d{2})?-(\d+)-(?:SP(\d)-)?(\d{4})$', ins)
            if m and (bf := openstates_bill(m.group(1), m.group(2), int(m.group(4)) + YS, m.group(3))):
                # A sponsorship on a bill converted from Open States data has no LegiScan page to line. It keeps the
                # official page it is cited on, and the verifier reads that page's own words as for any source,
                # unless the converted bill's page is its introduced text (South Dakota): then that text is cited.
                tl, line, why = introduced_text_line(bf, u, n)
                if tl:
                    e = {'url': tl, 'official': u, 'act': act, 'instrument': ins}
                    if e not in needs.setdefault(n, []): needs[n].append(e)
                    if line:
                        text_lines.append({'full_name': n, 'topic_key': TOPIC, 'source_url': tl, 'snippet': line, 'snippet_index': ''})
                    else: text_why.append([n, tl, ins, why])
                    continue
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
    # legiscan_merge.py reads these lines with legiscan-evidence.csv; a sponsorship with no line is in no-line.json.
    tw = csv.DictWriter(open(f'{B}/legiscan/sponsor-text-lines.csv', 'w', newline=''), fieldnames=['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index'])
    tw.writeheader(); tw.writerows(list({(x['full_name'], x['source_url']): x for x in text_lines}.values()))
    json.dump(text_why, open(f'{B}/legiscan/sponsor-text-no-line.json', 'w'), indent=1)
    if text_lines or text_why: print('sponsorships cited on the introduced text', len({(x['full_name'], x['source_url']) for x in text_lines}), 'with no line', len(text_why))
    w = csv.writer(open(f'{B}/legiscan/pairs.csv', 'w', newline='')); w.writerow(['full_name', 'last_name', 'topic_key', 'source_url']); w.writerows(pairs)
    print('people', len(needs), 'pairs', len(pairs), 'unmapped', len(unmapped), 'roll calls', len(rmap),
          *(['· sponsorships left on the official page (Open States bills, no LegiScan page)', len(own_page)] if own_page else []))
    by_why = {}
    for x in unmapped: by_why[re.sub(r'\d+', 'N', x[3].split(' (')[0])[:90]] = by_why.get(re.sub(r'\d+', 'N', x[3].split(' (')[0])[:90], 0) + 1
    for why, c in sorted(by_why.items(), key=lambda kv: -kv[1]): print(f'  unmapped {c}: {why}')
