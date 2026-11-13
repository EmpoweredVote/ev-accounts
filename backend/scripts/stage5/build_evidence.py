"""Stage 5 -> research-stances bridge (STAGE5 step 7.4).
python3 -I scripts/stage5/build_evidence.py <batch dir> <roster.tsv> <store findings dir> [--fetch] [--level state --state XX]
    [--max-urls N]  (default 8 federal, 20 state)
Rewrites <batch>/research.csv in place (original kept as research-pre-evidence.csv) and writes <batch>/evidence.csv:
- full_name -> the bundle's spelling (politicians.json), joined by politician_id through the roster;
- blank rows: no source URLs (a blank claims no chair; the gate allows it), URLs in reasoning reduced to host names;
- seated rows: one snippet per cited URL, cut from the page fetched once (pages/<sha1>.txt), >= 30 words, around the
  person's quoted passage, else their surname, else the instrument named in the reasoning.
--from-research / --from-pre: see the research.built.sha256 check below (a replaced research.csv stops the run).
--fetch fetches missing pages one at a time (curl, 1 s apart); iga.in.gov and congress.gov pages through their official
APIs instead (_iga.py, _congress.py). A congress.gov page cached by an older run holds a bot check: delete it first.
A page the live site refuses (non-2xx, or a page the verifier's looksLikeRealPage refuses) is read from its archive.org
snapshot through the verifier's own reader instead (_archive.py → archive-pages.ts); with no usable snapshot it is unread."""
import csv, json, sys, os, re, hashlib, subprocess, time, html
B, ROSTER, FIND = sys.argv[1:4]; FETCH = '--fetch' in sys.argv
pol = json.load(open(f'{B}/politicians.json')); pol = pol if isinstance(pol, list) else pol.get('politicians', pol)
bname = {p['politician_id']: p['full_name'] for p in pol}
ro = {r['politician_id']: r for r in csv.DictReader(open(ROSTER), delimiter='\t')}
src = f'{B}/research-pre-evidence.csv'
# A re-run rebuilds from research-pre-evidence.csv. When research.csv is no longer the file this tool last wrote (a new
# dry run was copied over it, or a later step edited it), that silently threw the new text away (oh-01, 2026-11-06: a
# second build after dry run 2 brought back dry run 1's dates and finding ids). So the written file's sha256 is kept in
# research.built.sha256, and a changed research.csv stops the run until the runner picks: --from-research (rebuild from
# the current research.csv; the old saved copy is kept as research-pre-evidence.prev.csv) or --from-pre (rebuild from
# the saved copy, as before). A batch built before this check has no hash file: it warns and keeps the old behaviour.
SHA = f'{B}/research.built.sha256'
_sha = lambda f: hashlib.sha256(open(f, 'rb').read()).hexdigest()
if os.path.exists(src) and os.path.exists(f'{B}/research.csv'):
    changed = os.path.exists(SHA) and open(SHA).read().strip() != _sha(f'{B}/research.csv')
    if '--from-research' in sys.argv:
        os.replace(src, f'{B}/research-pre-evidence.prev.csv'); os.rename(f'{B}/research.csv', src)
        print('build_evidence: rebuilding from the current research.csv (old saved copy: research-pre-evidence.prev.csv)')
    elif changed and '--from-pre' not in sys.argv:
        raise SystemExit('build_evidence: research.csv is not the file this tool last wrote (a new dry run, or a later step '
                         'edited it). Re-run with --from-research to rebuild from it, or --from-pre to rebuild from '
                         'research-pre-evidence.csv and drop the changes.')
    elif not os.path.exists(SHA) and os.path.getmtime(f'{B}/research.csv') > os.path.getmtime(src) + 1:
        print('build_evidence: WARNING research.csv is newer than research-pre-evidence.csv and this batch has no '
              'research.built.sha256; rebuilding from research-pre-evidence.csv as before. If research.csv holds a new '
              'dry run, re-run with --from-research.')
if not os.path.exists(src): os.rename(f'{B}/research.csv', src)
rows = list(csv.DictReader(open(src))); cols = list(rows[0].keys())
LEVEL = sys.argv[sys.argv.index('--level') + 1] if '--level' in sys.argv else 'federal'
STATE = sys.argv[sys.argv.index('--state') + 1] if '--state' in sys.argv else None
# Most source URLs a seated row keeps. stance-gate reads any number of source_url_N columns; the federal default of 8
# dropped cited acts on a federal batch (2026-11-03), which then ran with 20. --max-urls N sets it for any level.
MAXU = int(sys.argv[sys.argv.index('--max-urls') + 1]) if '--max-urls' in sys.argv else (8 if LEVEL == 'federal' else 20)
cols += [f'source_url_{i}' for i in range(1, MAXU + 1) if f'source_url_{i}' not in cols]
for _r in rows:
    for _k in cols: _r.setdefault(_k, '')
by_name = {}
for p, r in ro.items():
    if r['level'] == LEVEL and (STATE is None or r['state'] == STATE): by_name.setdefault(r['full_name'], []).append(p)
os.makedirs(f'{B}/pages', exist_ok=True)
PRE = {}
for x in csv.DictReader(open(f'{B}/research-pre-evidence.csv')):
    n0 = x['full_name'][1:-1].replace('""', '"') if x['full_name'].startswith('"') and x['full_name'].endswith('"') else x['full_name']
    ps = by_name.get(n0, [])
    PRE[bname.get(ps[0], n0) if len(ps) == 1 else n0] = x
# ⚠ BROWSER USER-AGENT — a deliberate exception to decision 0003 (ev-cto knowledge/decisions/0003-scraping-toolchain.md), ruled
# 2026-10-31 by Chris Andrews: kept for LOCAL research runs only, never in a live or scheduled fetch path. A page read
# this way is NOT proof the verifier can read it: the verifier sends the honest EmpoweredVoteBot identity
# (src/lib/verificationFetch.ts), so it may still fail there. iga.in.gov is NOT fetched this way: it goes through the
# official MyIGA API (_iga.py → iga-pages.ts, the same reader the verifier uses); congress.gov through the official
# api.congress.gov reader (_congress.py → congress-pages.ts, what the verifier reads; a plain fetch gets a bot check).

def _surname(full):
    """Last name without a generational suffix ('Joel R. Carter, Jr.' -> 'Carter', 'Henry Zuber III' -> 'Zuber')."""
    toks = [x.strip(',.') for x in (full or '').split()]
    while len(toks) > 1 and toks[-1].lower() in ('jr', 'sr', 'ii', 'iii', 'iv', 'v'):
        toks.pop()
    return toks[-1] if toks else ''

def text_of(url):
    f = f'{B}/pages/{hashlib.sha1(url.encode()).hexdigest()}.txt'
    if not os.path.exists(f):
        if not FETCH: return None
        if is_iga(url): return iga_text(url, f'{B}/pages')
        if is_congress(url): return congress_text(url, f'{B}/pages')
        time.sleep(1)
        r = subprocess.run(['curl', '-sL', '--compressed', '--max-time', '40', '-w', '\n%{http_code}', '-A', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36', url], capture_output=True)
        body, _, status = r.stdout.rpartition(b'\n')
        if body[:5] == b'%PDF-' and status.startswith(b'2'):  # a PDF is read with pdftotext, never stripped as HTML
            t = subprocess.run(['pdftotext', '-layout', '-', '-'], input=body, capture_output=True).stdout.decode('utf-8', 'replace')
            t = re.sub(r'\s+', ' ', t).strip(); open(f, 'w').write(t); return t
        raw = body.decode('utf-8', 'replace')
        raw = re.sub(r'(?is)<(script|style|noscript)[^>]*>.*?</\1>', ' ', raw)
        t = html.unescape(re.sub(r'<[^>]+>', ' ', raw)); t = re.sub(r'\s+', ' ', t).strip()
        # A refused, thin or challenge page: read the archive.org snapshot, as the verifier does (_archive.py). With no
        # snapshot, a page that loaded (2xx) is kept as before, the verifier's best effort; a refused one is unread.
        if live_failed(status, t):
            a = archive_text(url, f'{B}/pages')
            if a or not status.startswith(b'2') or not t: return a
        open(f, 'w').write(t)
    return open(f).read()

INSTR_DIR = os.path.join(os.path.dirname(FIND.rstrip('/')), 'instruments')
_inst_cache = {}
def instrument(iid):
    if iid not in _inst_cache:
        import glob as _g
        fp = _g.glob(os.path.join(INSTR_DIR, '**', iid + '.json'), recursive=True)
        _inst_cache[iid] = json.load(open(fp[0])) if fp else None
    return _inst_cache[iid]
def raw_xml(url):
    f = f'{B}/pages/{hashlib.sha1(url.encode()).hexdigest()}.xml'
    if not os.path.exists(f):
        if not FETCH: return None
        time.sleep(1)
        r = subprocess.run(['curl', '-sL', '--compressed', '--max-time', '40', '-A', 'Mozilla/5.0', url], capture_output=True)
        open(f, 'wb').write(r.stdout)
    return open(f, encoding='utf-8', errors='replace').read()
ROLL_URL = re.compile(r'^https://clerk\.house\.gov/evs/(\d{4})/roll(\d{1,4})(\.xml)?$')
def roll_lines(pid, fs):
    """(url, line) for each Yea/Nay House roll call this person cast on a stored instrument."""
    out = []
    for f in fs:
        if f.get('kind') != 'record' or f.get('act') not in ('yea', 'nay', 'aye', 'no'): continue
        ins = instrument(f.get('instrument_id') or '')
        if not ins: continue
        for u in ins.get('urls') or []:
            m = ROLL_URL.match(u.strip())
            if not m: continue
            xu = f'https://clerk.house.gov/evs/{m.group(1)}/roll{m.group(2)}.xml'
            x = raw_xml(xu)
            if not x: continue
            printed = None
            for v in ins.get('votes') or []:
                for mem in v.get('members') or []:
                    if mem.get('politician_id') == pid: printed = mem.get('name')
            if not printed and f.get('url', '').startswith(xu.rsplit('.xml', 1)[0]):
                # The vote finding cites this roll call but the instrument's member list is not linked:
                # take the person's surname, and only when exactly one member on the roll carries it.
                sur0 = _surname(ro.get(pid, {}).get('full_name') or '')
                cands = [mm.group(1).strip() for mm in re.finditer(r'<legislator\b[^>]*>([^<]*)</legislator>', x)
                         if re.sub(r'\s*\([A-Z]{2}\)\s*$', '', mm.group(1).strip()) == sur0]
                if len(cands) == 1: printed = cands[0]
            if not printed: continue
            g = lambda t: (re.search(f'<{t}>\\s*([^<]*?)\\s*</{t}>', x) or [None, None])[1]
            for rm in re.finditer(r'<recorded-vote>\s*<legislator\b([^>]*)>([^<]*)</legislator>\s*<vote>([^<]*)</vote>', x):
                if rm.group(2).strip() != printed.strip(): continue
                st = re.search(r'state="([A-Z]{2})"', rm.group(1)).group(1)
                sur = re.sub(r'\s*\([A-Z]{2}\)\s*$', '', html.unescape(rm.group(2).strip()))
                line = f"House roll call {int(g('rollcall-num'))} ({m.group(1)}), {g('legis-num')}, {html.unescape(g('vote-question'))}: {sur} ({st}) voted {rm.group(3).strip()}."
                out.append((xu, line)); break
            break
    return out
norm = lambda s: re.sub(r'\s+', ' ', s.replace('’', "'").replace('‘', "'").replace('“', '"').replace('”', '"').replace('–', '-').replace('—', '-')).strip().lower()
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _party.py sits beside this file
from _party import names_party  # the one party test the sweep and the writer use (party-check.ts)
from _window import verifiable_window  # a passage the verifier itself accepts (window-check.ts)
from _iga import is_iga, iga_text  # iga.in.gov through the official API, never the browser UA
from _congress import is_congress, congress_text  # congress.gov through api.congress.gov, never the browser UA
from _ballotpedia import ballotpedia_non_survey  # survey answers only (ruling 2026-11-02)
from _archive import live_failed, archive_text  # archive.org when the live page is refused, as the verifier
def window(t, i, j, n=30):
    w = t.split(' '); pos = len(t[:i].split(' ')) - 1; end = len(t[:j].split(' '))
    span = end - pos
    for size in (max(n, span + 4), max(26, span + 1)):
        starts = [max(0, pos - k) for k in (6, 0, 2, 12, 20)] + [max(0, end - size + d) for d in range(0, max(1, size - span + 1))]
        for a in dict.fromkeys(starts):
            if a > pos or a + size < end: continue
            x = ' '.join(w[a:a + size])
            if len(x.split()) >= 25 and not names_party(x): return x
    return None
def _cites(num, u):
    # Federal: the old substring test. State: the bill number must stand alone in the URL ("Bill=SB1", "/SB00001F.htm"),
    # so SB 1 is not taken as cited by a URL for SB 14.
    if LEVEL == 'federal': return num in u
    return bool(re.search(r'(?:Bill=[A-Z]+|/[A-Z]{2,3}0*)' + num + r'(?![0-9])', u))
INST = re.compile(r'\b(Senate Bill|House Bill|H\.?\s?R\.?|S\.|SB|HB|H\.R\.|SJR|HJR)\s?(\d{1,5})\b', re.I)
if STATE == 'NC':  # NC prints bills as "S 921" / "H 958" (nc-01)
    INST = re.compile(r'\b(Senate Bill|House Bill|S\.|SB|HB|SJR|HJR|S|H)\s?(\d{1,5})\b')
ev = []; out = []; miss = []; edits = []
REPL = set(json.load(open(f'{B}/blank-replaces-chair.json'))) if os.path.exists(f'{B}/blank-replaces-chair.json') else set()
REQ = json.load(open(f'{B}/blank-required-urls.json')) if os.path.exists(f'{B}/blank-required-urls.json') else {}
OVR = json.load(open(f'{B}/overrides.json')) if os.path.exists(f'{B}/overrides.json') else {}
for r in rows:
    if r['full_name'] in OVR:
        for k, v in OVR[r['full_name']].items():
            if k.startswith('_'): continue
            r[k] = v
        edits.append((r['full_name'], 'override: ' + OVR[r['full_name']].get('_why', '')))
    if r['full_name'].startswith('"') and r['full_name'].endswith('"'): r['full_name'] = r['full_name'][1:-1].replace('""', '"')  # stage5-write double-escapes quoted nicknames
    pids = by_name.get(r['full_name'], []); pid = pids[0] if len(pids) == 1 else None
    if pid and pid in bname: r['full_name'] = bname[pid]
    urls = [r[k] for k in cols if k.startswith('source_url') and r[k]]
    if r['value'] == '0':
        r['reasoning'] = re.sub(r'https?://([^/\s;)]+)[^\s;)]*', r'\1', r['reasoning'])
        for k in cols:
            if k.startswith('source_url'): r[k] = ''
        # The old chair's own-site and record pages this blank must have examined (verifier rule; summary
        # sites exempt by the 2026-10-29 ruling): cite each, with a party-free window around the name.
        need = list(REQ.get(r['full_name'], []))
        if r['full_name'] in REPL:
            # A blank that replaces a chair voters see needs a verified source of its own: the pages the
            # coder examined (stage5-write's list), skipping summary sites and search pages.
            _pr = PRE.get(r['full_name']) or {}
            pre_urls = [_pr[kk] for kk in cols if kk.startswith('source_url') and _pr.get(kk)]
            for u in pre_urls:
                if u not in need and not re.search(r'ontheissues|wikipedia|google\.|bing\.|duckduckgo|congress\.gov/search', u): need.append(u)
        need = need[:MAXU]
        sur = _surname(r['full_name']); idx = 0; k = 0
        for u in need:
            # A party word in the ADDRESS is fine (RULINGS.md "A party word in a source address is fine", W3-R15).
            t = text_of(u)
            if not t: miss.append((r['full_name'], u, 'blank fallback: no page')); continue
            # First a passage the verifier itself accepts (window-check.ts), else the party-free window around the name.
            snip = verifiable_window(None, r['full_name'], text=t)
            if not snip:
                nt = norm(t); i = nt.find(norm(r['full_name']))
                if i < 0: i = nt.find(sur.lower())
                snip = window(t, i, i + len(sur)) if i >= 0 else None
            if not snip: miss.append((r['full_name'], u, 'blank fallback: no name window')); continue
            k += 1; r[f'source_url_{k}'] = u; idx += 1
            ev.append({'full_name': r['full_name'], 'topic_key': r['topic_key'], 'source_url': u, 'snippet': snip, 'snippet_index': idx})
        out.append(r); continue
    fs = json.load(open(f'{FIND}/{pid}.json'))['findings'] if pid and os.path.exists(f'{FIND}/{pid}.json') else []
    sur = _surname(ro.get(pid, {}).get('full_name') or r['full_name'])
    # Split a quote that holds an ellipsis into its exact parts ("a ... b" -> "a" ... "b"); log each change.
    def _split(m):
        q = m.group(2); parts = [p.strip(' ,;') for p in re.split(r'\s*(?:\.\.\.|\u2026)\s*', q) if p.strip(' ,;')]
        return m.group(1) + (m.group(1) + ' … ' + m.group(1)).join(parts) + m.group(1)
    new_r = re.sub(r'(["\'])([^"\']*?(?:\.\.\.|\u2026)[^"\']*?)\1', _split, r['reasoning'])
    if new_r != r['reasoning']: edits.append((r['full_name'], 'ellipsis split')); r['reasoning'] = new_r
    for q in [q for q in re.findall(r'["\u201c]([^"\u201d]+)["\u201d]', r['reasoning']) if len(q) >= 12]:
        if len(q.split()) < 4: continue
        for f in fs:
            if f.get('passage') and norm(q)[:60] in norm(f['passage']) and f.get('url') and f['url'] not in urls and len(urls) < MAXU:
                urls.append(f['url']); r[f'source_url_{len(urls)}'] = f['url']; edits.append((r['full_name'], 'added quote source ' + f['url'])); break
    rolls = roll_lines(pid, fs) if pid else []
    for xu, line in rolls:
        if xu not in urls and len(urls) < MAXU:
            urls.append(xu); r[f'source_url_{len(urls)}'] = xu; edits.append((r['full_name'], 'added roll call ' + xu))
    idx = 0
    # Instruments the reasoning names but no cited URL carries: add the person's own record URL for it.
    for m in INST.finditer(r['reasoning']):
        num = m.group(2)
        if any(_cites(num, r.get(k) or '') for k in cols if k.startswith('source_url')): continue
        for f in fs:
            iid = f.get('instrument_id') or ''
            # Same topic only: "SB 7 (2017)" in a gun row must not pull in the person's AB 7 (2011) voter-ID roll call (wi-01).
            if f.get('topic_keys') and r['topic_key'] not in f['topic_keys']: continue
            if f.get('kind') == 'record' and re.search(r'-' + num + r'-', iid) and f.get('url') and f['url'] not in urls and len(urls) < MAXU:
                urls.append(f['url']); r[f'source_url_{len(urls)}'] = f['url']; break
    TEXTURL = r'govinfo\.gov/content|BillLookUp|/Bills/.*\.pdf|/billtext/'
    STATETEXT = r'/billtext/|ncleg\.gov/Sessions/\d+/Bills/(?:Senate|House)/PDF/'  # TX bill-text pages; NC bill PDFs (nc-01)
    for m in INST.finditer(r['reasoning']):
        num = m.group(2)
        # A cited page counts only if it carries the bill's text (a TX Authors/History page names the bill, not its words).
        if any(_cites(num, r.get(k) or '') and (LEVEL == 'federal' or re.search(STATETEXT, r.get(k) or '')) for k in cols if k.startswith('source_url')): continue
        for f in fs:
            iid = f.get('instrument_id') or ''
            if not re.search(r'-' + num + r'-', iid): continue
            import glob as _g
            fp = _g.glob(os.path.join(os.path.dirname(FIND.rstrip('/')), 'instruments', '**', iid + '.json'), recursive=True)
            _tus = (json.load(open(fp[0])).get('urls') or []) if fp else []
            if isinstance(_tus, str):  # some instrument files store the list as its printed form (NC)
                import ast; _tus = ast.literal_eval(_tus)
            for tu in _tus:
                if ' ' in tu or tu in urls or len(urls) >= MAXU or not re.search(TEXTURL, tu) or (LEVEL != 'federal' and not re.search(STATETEXT, tu)): continue
                urls.append(tu); r[f'source_url_{len(urls)}'] = tu; edits.append((r['full_name'], 'added instrument text ' + tu)); break
            break
    for u in urls:
        if ROLL_URL.match(u) and u.endswith('.xml'):
            mine = [ln for xu, ln in rolls if xu == u]
            if not mine:
                miss.append((r['full_name'], u, 'roll call: no vote line; source dropped'))
                for k in cols:
                    if r.get(k) == u: r[k] = ''
                continue
            for ln in mine:
                idx += 1; ev.append({'full_name': r['full_name'], 'topic_key': r['topic_key'], 'source_url': u, 'snippet': ln, 'snippet_index': idx})
            continue
        t = text_of(u)
        if not t: miss.append((r['full_name'], u, 'no page')); continue
        nt = norm(t); anchors = []
        for f in fs:
            if f.get('url') == u and f.get('passage'): anchors.append(norm(f['passage'])[:120])
        _qs = [q for q in re.findall(r'["\u201c]([^"\u201d]+)["\u201d]', r['reasoning']) if len(q) >= 12] + re.findall(r"(?<![A-Za-z])'([^']{12,}?)'(?![A-Za-z])", r['reasoning'])
        anchors += [norm(q) for q in _qs if len(q.split()) >= 4]
        got = []
        for q in anchors:
            i = nt.find(q[:100])
            if i >= 0: got.append(window(t, i, i + len(q)))
        i = nt.find(sur.lower())
        if i >= 0: got.append(window(t, i, i + len(sur)))
        for m in INST.finditer(r['reasoning']):
            num = m.group(2)
            for mm in re.finditer(r'\b(H\.?\s?R\.?|S\.|SB|HB|SJR|HJR|Senate Bill|House Bill)\s?' + num + r'\b', t, re.I):
                got.append(window(t, mm.start(), mm.end())); break
        got = [x for x in got if x]
        if not got: miss.append((r['full_name'], u, 'no anchor')); continue
        kept = list(dict.fromkeys(got))
        for snip in kept:
            idx += 1; ev.append({'full_name': r['full_name'], 'topic_key': r['topic_key'], 'source_url': u, 'snippet': snip, 'snippet_index': idx})
    out.append(r)
# A Ballotpedia page other than a Candidate Connection survey is never cited, on any row (ruling 2026-11-02).
for r in out:
    for k in cols:
        if k.startswith('source_url') and ballotpedia_non_survey(r.get(k)):
            miss.append((r['full_name'], r[k], 'Ballotpedia non-survey page: not cited (ruling 2026-11-02)')); r[k] = ''
ev = [e for e in ev if not ballotpedia_non_survey(e['source_url'])]
with open(f'{B}/research.csv', 'w', newline='') as _f:
    w = csv.DictWriter(_f, fieldnames=cols); w.writeheader(); w.writerows(out)
open(SHA, 'w').write(_sha(f'{B}/research.csv') + '\n')
w = csv.DictWriter(open(f'{B}/evidence.csv', 'w', newline=''), fieldnames=['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index']); w.writeheader(); w.writerows(ev)
json.dump(miss, open(f'{B}/evidence-missing.json', 'w'), indent=1)
json.dump(edits, open(f'{B}/research-edits.json', 'w'), indent=1)
own = []
for r in out:
    if r['value'] == '0': continue
    sur = _surname(r['full_name']).lower()
    for k in cols:
        u = r.get(k) or ''
        if k.startswith('source_url') and u:
            host = u.split('/')[2].lower()
            if len(sur) >= 4 and sur in host.replace('-', '') and 'ballotpedia' not in host: own.append({'url': u, 'source_kind': 'own-site'})
json.dump({'sources': own}, open(f'{B}/sources.json', 'w'), indent=1)
print('own-site urls', len(own))
print('edits', len(edits), 'rows', len(out), 'snippets', len(ev), 'missing', len(miss))
