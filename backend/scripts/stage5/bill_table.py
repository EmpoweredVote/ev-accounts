"""The bill table: one Opus reading of each core bill, made once per state before coding, then checked here.

usage: python3 -I bill_table.py check <table.json> [--store <source-store dir>] [--ids <ids file>] [--rungs 5]
       python3 -I bill_table.py questions <table.json> --ids <ids file> [--store <dir>] [--rungs 5] [--out <questions.md>]
       python3 -I bill_table.py join <table.json> <part file>... [--force]
       python3 -I bill_table.py settle <table.json> (<bill id>... | --all) --answer "<the ruling, or the runner's words>"

<table.json> is what the bill-table prompt (templates/stage5-bill-table-prompt.md) writes:
  {"topic_key": "gun-policy", "bills": {"MO-HB-1-2025": {"rung": 4, "deciding_words": "...", "why": "...", "flag": ""}}}
- rung: the rung a Yes on the bill supports, 1..--rungs, or null when a Yes supports no rung (direction only, off the
  question, or too mixed). A null rung needs a `why`.
- deciding_words: words copied from the bill's operative_text that decide the rung. They must be found there.
- flag: an OPEN question for the runner, or "". Any text here keeps the bill, and every person with an act on it, out
  of the record script (lane `flagged-bill`). Never write the answer into `flag`: use `settle`.
- question, answered (written by `settle`): the question that was asked and the answer that closed it.
- per_vote (optional, round three): {"rungs": [3, null], "note": "..."} when a ruling reads some vote on the bill differently
  from the row (a vote taken on an earlier text). `rungs` lists every rung one of its votes may carry, the row's own
  included. record-script.ts sends a person to Opus when one of those rungs would change their result. Write it at stop 1,
  with the ruling.
  per_vote.votes (optional, 2026-11-19): [{"date": "2018-02-02", "chamber": "House", "tally": "76-44", "rung": null}, ...]: the rung a
  Yes on THAT vote supports. record-script.ts reads a vote that fits exactly one entry (date, chamber, and tally when
  given) at that rung, so the person is not sent to Opus for it. Any other act on the bill is read as above. List every
  floor vote the ruling settles; take date, chamber and tally from the bill's stored votes.

votes      (set-up, before stop 1) lists every bill with a rung that an in-scope person has a Yea or Nay finding on and
           the datasets on disk (--ds, --state) hold no roll call for. Such a vote cannot be cited at the write, so the
           person is held: Maryland 2026-11-18, 20 people held at the write for a 2013 bill older than the data, and a
           second batch. It cannot tell whether the vote's own page is one the verifier reads (Kansas cited a 2015 bill page
           and held no one): it lists the bills, and the session checks. Exit 0 none, 1 some (listed, people to --out), 2 no verdict (no dataset, or no vote examined).
check      validates the table against the store: each bill has an instrument file, each rung is in range, each
           `deciding_words` is found in the bill's operative_text (whitespace and case folded). With --ids it also lists
           every on-topic bill those people have a finding on that the table leaves out. Exit 2 on any problem.
questions  writes the runner's questions: every flagged bill, then every person with a Yes act (yea, sponsor, author,
           signed) on ungated bills on BOTH sides of the middle rung — e.g. a Yes on a rung 2 bill and a Yes on a
           rung 4 bill. Gated votes (multi-subject, near-unanimous) are left out, as the coder leaves them out.
           Exit 0 always; the count is printed. It also runs `votes` (below) and adds its lines to the file.
settle     closes a flag: moves `flag` to `question`, writes --answer to `answered`, and empties `flag`. Name the bills,
           or pass --all for every flagged bill (one answer that covers them all). A named bill with no flag, an
           unknown bill or an empty answer is refused (exit 2) and nothing is written. The rung is not changed: when
           the answer changes it, edit `rung`, `deciding_words` and `why` and run `check` again.
affected   after bills joined the table late (a searcher named them): `affected <table.json> <bill id>... --ids <ids
           file> [--out <ids file>]` lists who must be coded again: a person with a counted Yes act on one of
           those bills that HAS a rung, and a person whose ONLY findings on the topic are on them (their "no stance"
           can no longer stand, whatever the act). A no-rung bill moves no one else. A flagged bill is
           refused: settle it first. No one holds a finding on a named bill: exit 2, the pre-fill has not run since
           the bills joined the store.

Why: in Georgia the coders read the same 47 bills 204 times, and the rung each bill supports was argued afresh in
each batch; the both-sides people were found only at the early check (review 2026-11-12, change 2).
Florida, 2026-11-14: with no `settle`, a session appended "[Settled ...]" to the `flag` of all 149 rows, the record
script read every bill as unanswered and coded 0 of 154 people. `check` now refuses a flag that reads as answered.
"""
import glob, json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, positional
from _against import act_for_bill

HERE = os.path.dirname(os.path.abspath(__file__))
STORE = os.path.normpath(os.path.join(HERE, '..', '..', 'data', 'source-store'))
USAGE = 'bill_table.py check|questions|join|settle|affected|votes <table.json> [--ds <datasets dir> --state XX] [<bill id>... | --all] [--answer <text>] [--store <dir>] [--ids <file>] [--rungs 5] [--out <md>]'
ANSWERED = re.compile(r'\[\s*(settled|answered|resolved|ruled)\b|\bas recommended\b', re.I)  # an answer note, not a question that mentions a ruling
YES = {'yea', 'sponsor', 'author', 'signed'}


def fold(s): return re.sub(r'\s+', ' ', (s or '').replace('’', "'").replace('“', '"').replace('”', '"')).strip().lower()


def instrument_paths(store):
    return {os.path.basename(p)[:-5]: p for p in glob.glob(os.path.join(store, 'instruments', '*', '*.json'))}


def read_ids(path): return [x for x in open(path).read().split() if x]


def person_findings(store, pid, topic):
    p = os.path.join(store, 'findings', f'{pid}.json')
    if not os.path.exists(p): return []
    return [f for f in json.load(open(p))['findings'] if topic in (f.get('topic_keys') or [])]


def gated(f, topic): return (f.get('gate_by_topic') or {}).get(topic, 'none') != 'none'


def check(table, store, ids, rungs):
    paths, problems = instrument_paths(store), []
    for bid, row in table['bills'].items():
        if bid not in paths: problems.append(f'{bid}: no instrument file in the store'); continue
        r = row.get('rung')
        if r is not None and (not isinstance(r, int) or not 1 <= r <= rungs): problems.append(f'{bid}: rung {r!r} is not 1..{rungs} or null')
        if r is None and not (row.get('why') or '').strip(): problems.append(f'{bid}: a null rung needs a why')
        pv = row.get('per_vote')
        if pv is not None and not (isinstance(pv, dict) and isinstance(pv.get('rungs'), list) and len(pv['rungs']) >= 2
                                   and all(x is None or (isinstance(x, int) and 1 <= x <= rungs) for x in pv['rungs']) and r in pv['rungs']):
            problems.append(f'{bid}: per_vote needs "rungs": two or more of 1..{rungs} or null, the row\'s own rung among them')
        vs = pv.get('votes') if isinstance(pv, dict) else None
        if vs is not None:
            ok = isinstance(vs, list) and vs and all(isinstance(v, dict) and re.fullmatch(r'\d{4}-\d\d-\d\d', str(v.get('date') or '')) and v.get('chamber') in ('House', 'Senate')
                                                      and 'rung' in v and v['rung'] in (pv.get('rungs') or []) and (v.get('tally') is None or re.fullmatch(r'\d+\D+\d+', str(v['tally']))) for v in vs)
            if not ok: problems.append(f'{bid}: per_vote "votes" needs entries {{"date": "YYYY-MM-DD", "chamber": "House"|"Senate", "rung": one of "rungs", "tally": "76-44" (optional)}}')
            else:
                keys = [(v['date'], v['chamber'], re.sub(r'\D+', '-', str(v.get('tally') or ''))) for v in vs]
                # two votes of one chamber on one day are told apart only by their tallies
                if len(set(keys)) < len(keys) or any(not k[2] and sum(1 for x in keys if x[:2] == k[:2]) > 1 for k in keys):
                    problems.append(f'{bid}: per_vote "votes" has two entries for one chamber on one day; give each its tally')
        flag = row.get('flag') or ''
        # Colorado 2026-11-19: the newest session's texts could not be fetched and seven bills were stored from the
        # legislature's own summary. A rung read from a summary is the runner's to check, bill by bill.
        if not flag.strip() and not (row.get('answered') or '').strip() and 'NO BILL TEXT READ' in str((json.load(open(paths[bid])).get('provenance') or {}).get('fetched_by') or ''):
            problems.append(f'{bid}: stored from a summary, no bill text read: its row needs a flag (the runner checks the rung at stop 1), then `settle`')
        if flag.strip() and ANSWERED.search(flag): problems.append(f'{bid}: the flag reads as answered ("{flag.strip()[-60:]}"); a flag is an open question. Close it with `settle`')
        elif flag and not flag.strip(): problems.append(f'{bid}: the flag is blank space, not ""')
        elif flag.strip() and (row.get('answered') or '').strip(): problems.append(f'{bid}: flagged and answered at once; a new question on a settled bill replaces `answered`')
        words = (row.get('deciding_words') or '').strip()
        if r is not None and not words: problems.append(f'{bid}: rung {r} with no deciding_words')
        if words:
            text = fold(json.load(open(paths[bid])).get('operative_text'))
            for piece in re.split(r'\s*(?:\.\.\.|…|\[…\])\s*', words):
                if piece.strip() and fold(piece) not in text:
                    problems.append(f'{bid}: deciding_words not in the operative text: "{piece.strip()[:80]}"')
    if ids:
        seen = {}
        for pid in ids:
            for f in person_findings(store, pid, table['topic_key']):
                if f.get('instrument_id') and f['instrument_id'] not in table['bills']: seen.setdefault(f['instrument_id'], set()).add(pid)
        for bid, who in sorted(seen.items(), key=lambda x: -len(x[1])):
            problems.append(f'{bid}: {len(who)} person(s) have a finding on it; the table leaves it out')
    return problems


def questions(table, store, ids, rungs):
    mid, topic, out = (1 + rungs) / 2, table['topic_key'], []
    flagged = [(b, r) for b, r in table['bills'].items() if (r.get('flag') or '').strip()]
    out.append(f'# Bill table questions ({topic})\n\n## Flagged bills ({len(flagged)})\n')
    out += [f"- **{b}** (rung {r.get('rung')}): {r['flag'].strip()}" for b, r in flagged] or ['- none']
    both = []
    for pid in ids:
        lo, hi = set(), set()
        for f in person_findings(store, pid, topic):
            row = table['bills'].get(f.get('instrument_id') or '')
            act = act_for_bill(f)  # a Yea to kill the bill is a No (_against.py)
            if not row or row.get('rung') is None or act not in YES or gated(f, topic): continue
            (lo if row['rung'] < mid else hi if row['rung'] > mid else set()).add(f"{f['instrument_id']} r{row['rung']} {f['act']}" + (' (against the bill)' if f.get('against_bill') else ''))
        if lo and hi: both.append((pid, sorted(lo), sorted(hi)))
    out.append(f'\n## Yes on both sides of rung {mid:g} ({len(both)})\n')
    out += [f"- {pid}: {', '.join(lo)} | {', '.join(hi)}" for pid, lo, hi in both] or ['- none']
    return '\n'.join(out) + '\n', len(flagged), len(both)


def affected(table, store, ids, bills):
    """Who must be coded again after `bills` joined the table. (1) A person with a counted Yes act on one of them that
    has a rung: a No, an absence, or any act on a no-rung bill cannot change a rung. Ohio 2026-11-16: three late bills,
    all no rung, 25 people coded again, 0 changed. (2) A person whose only findings on the topic are on these bills:
    before them the person had nothing on file and was coded "no stance", which an on-topic finding ends whatever the act.
    Colorado 2026-11-19: two members who sat only in the newest session voted No on the late bills, were not listed,
    and the early check stopped on their "no stance" codes."""
    unknown = [b for b in bills if b not in table['bills']]
    if unknown: raise SystemExit(f'not in the table: {", ".join(unknown)}')
    open_q = [b for b in bills if (table['bills'][b].get('flag') or '').strip()]
    if open_q: raise SystemExit(f'still flagged, settle first (the rung is not known yet): {", ".join(open_q)}')
    hit, touched, first = {}, set(), set()
    for pid in ids:
        other = False
        for f in person_findings(store, pid, table['topic_key']):
            bid = f.get('instrument_id')
            if bid not in bills:
                other = True  # any other finding on the topic, a vote or the person's own words: they were coded on it
                continue
            touched.add(pid)
            if table['bills'][bid].get('rung') is not None and act_for_bill(f) in YES and not gated(f, table['topic_key']):
                hit.setdefault(pid, set()).add(bid)
        if pid in touched and not other: first.add(pid)
    return hit, touched, first


def join(out, parts):
    """One table from the parts the bill-table wave wrote. Until 2026-11-21 every state joined them with a one-off script."""
    if os.path.exists(out) and '--force' not in sys.argv: raise SystemExit(f'{out} exists: a joined table is edited in place (settle, per_vote). Pass --force to join again; the old one is kept as .bak-join.')
    if len(parts) < 1: raise SystemExit('join needs the part files')
    topic, bills = None, {}
    for p in parts:
        t = json.load(open(p))
        if not isinstance(t.get('bills'), dict) or not t.get('topic_key'): raise SystemExit(f'{p} is not a bill-table part (topic_key and a "bills" object)')
        if topic not in (None, t['topic_key']): raise SystemExit(f'{p} is for {t["topic_key"]!r}, the parts before it for {topic!r}')
        topic = t['topic_key']; twice = sorted(set(bills) & set(t['bills']))
        if twice: raise SystemExit(f'{p} repeats {len(twice)} bill(s) of an earlier part, e.g. {twice[0]}. Nothing written.')
        bills.update(t['bills'])
    if os.path.exists(out): os.replace(out, out + '.bak-join')
    json.dump({'topic_key': topic, 'bills': bills}, open(out, 'w'), indent=2, ensure_ascii=False)
    print(f'joined {len(parts)} part(s): {len(bills)} bill(s) -> {out}')


def settle(table, bills, every, answer):
    rows = table['bills']
    if not answer.strip(): raise SystemExit('settle needs --answer: the ruling, or the runner\'s words')
    if every == bool(bills): raise SystemExit('settle takes bill ids or --all, one of the two')
    if every: bills = [b for b, r in rows.items() if (r.get('flag') or '').strip()]
    bad = [f'{b}: not in the table' for b in bills if b not in rows] + [f'{b}: has no flag to settle' for b in bills if b in rows and not (rows[b].get('flag') or '').strip()]
    if bad or not bills:
        for x in bad or ['no bill is flagged']: print(' ', x)
        sys.exit(2)
    for b in bills: rows[b]['question'] = rows[b]['flag'].strip(); rows[b]['answered'] = answer.strip(); rows[b]['flag'] = ''
    return bills


def votes_on_disk(table, store, ids, ds, state):
    """Votes of in-scope people on a bill WITH a rung, whose bill has no roll call in the datasets on disk.
    Returns (misses {bill: (reason, {person ids}, {those with no other such vote at that rung on disk})}, votes examined, bill files indexed, (first year, last year) with a roll call)."""
    idx, years = {}, set()
    for d in glob.glob(os.path.join(ds, f'{state.upper()}-*', '*', '*', 'bill')):
        for n in sorted(os.listdir(d)):
            m = re.match(r'([A-Z]+)0*(\d+)\.json$', n)
            if not m: continue
            b = json.load(open(os.path.join(d, n)))['bill']; ss = b['session']
            span = (int(ss['year_start']), int(ss.get('year_end') or ss['year_start']), 1 if int(ss.get('special') or 0) else 0)
            idx.setdefault((m.group(1), int(m.group(2))), []).append((span, len(b.get('votes') or [])))
            if b.get('votes'): years.update(range(span[0], span[1] + 1))
    miss, seen = {}, 0
    for pid in ids:
        off, on_disk = [], set()   # this person's votes: (bill, why) with no roll call; (rung, act) that has one
        for f in person_findings(store, pid, table['topic_key']):
            bid, row = f.get('instrument_id') or '', table['bills'].get(f.get('instrument_id') or '')
            if f.get('act') not in ('yea', 'nay') or not row or row.get('rung') is None or gated(f, table['topic_key']): continue
            m = re.match(state.upper() + r'-([A-Z]+)-(\d+)-(?:SP(\d)-)?(\d{4})$', bid)
            if not m: continue   # another state's bill, or a federal one: not this state's datasets
            seen += 1
            y, sp = int(m.group(4)), 1 if m.group(3) else 0
            on = [v for (a, z, s), v in idx.get((m.group(1), int(m.group(2))), []) if a <= y <= z and s == sp]
            if any(on): on_disk.add((row['rung'], act_for_bill(f)))
            else: off.append((bid, 'the bill is on disk with no roll call' if on else 'the bill is not in the datasets on disk', (row['rung'], act_for_bill(f))))
        for bid, why, k in off:
            # "only": the person has no other vote of that kind at that rung with a roll call, so the seat would rest on it
            e = miss.setdefault(bid, (why, set(), set())); e[1].add(pid)
            if k not in on_disk: e[2].add(pid)
    return miss, seen, sum(len(v) for v in idx.values()), (min(years), max(years)) if years else None


def votes_report(table, store, ids, ds, state):
    """(lines, exit code, people) of the `votes` check: 0 none, 1 some, 2 no verdict."""
    miss, seen, nbills, span = votes_on_disk(table, store, ids, ds, state)
    # blind: no dataset for the state, or not one vote examined, would read as "nothing missing"
    if not nbills or not span: return [f'votes: NO VERDICT. No bill with a roll call for {state.upper()} under {ds}.'], 2, set()
    if not seen: return [f'votes: NO VERDICT. Not one vote of the {len(ids)} people on a bill with a rung was examined (wrong --ids, --store or table?).'], 2, set()
    L = [f'votes: {seen} vote(s) of {len(ids)} people on bills with a rung; roll calls on disk cover {span[0]} to {span[1]} ({nbills} bill files).']
    if not miss: return L + ['Every one is on a bill with a roll call on disk.'], 0, set()
    people = set().union(*(v[1] for v in miss.values()))
    L.append(f'{len(miss)} bill(s) with a rung have votes on file and NO roll call on disk; {len(people)} people ({len(set().union(*(v[2] for v in miss.values())))} have no other such vote at that rung).')
    for b, (why, who, alone) in sorted(miss.items(), key=lambda kv: -len(kv[1][1])): L.append(f'  {b}: {len(who)} people ({len(alone)} with no other such vote at that rung); {why}')
    L.append('CHECK before stop 1: can a vote on each bill be cited on a page the verifier reads (the profile\'s votes.floor_rule and gaps; the finding\'s own url)? '
             'Kansas 2015: yes, the bill page was cited and no one was held. Maryland 2013: no, 20 people were held at the write. '
             'If no, or not known: ask at stop 1 (read these votes now, or hold these people for a later batch).')
    return L, 1, people


def main():
    every = '--all' in sys.argv
    if every: sys.argv.remove('--all')  # positional() reads the word after any --flag as its value
    cmd, path = positional(2, USAGE)[:2]
    if cmd == 'join': join(path, [a for a in sys.argv[3:] if not a.startswith('--')]); return
    table = json.load(open(path))
    store, rungs = opt('--store', STORE), int(opt('--rungs', '5'))
    ids = read_ids(opt('--ids')) if opt('--ids') else []
    if cmd == 'check':
        p = check(table, store, ids, rungs)
        for x in p: print(' ', x)
        nf = sum(1 for r in table['bills'].values() if (r.get('flag') or '').strip())
        print(f"{len(table['bills'])} bills, {len(p)} problem(s), {nf} flagged (open questions)" + (': the record script codes nobody with an act on a flagged bill' if nf else ''))
        sys.exit(2 if p else 0)
    if cmd == 'affected':
        if not ids: raise SystemExit('affected needs --ids')
        bills = positional(3, USAGE)[2:]
        hit, touched, first = affected(table, store, ids, bills)
        if not touched and opt('--none-ok') != 'yes':
            # Colorado 2026-11-19: `affected` said 0 for seven voted bills, because no finding existed on them yet
            print(f'NO VERDICT: none of {len(ids)} people holds a finding on any of the {len(bills)} bill(s). Findings are written by the '
                  'pre-fill: run topic:stage5-prefill for this unit again, now that the bills are in the store, then ask again. '
                  '(Bills nobody in the batch voted on or sponsored: pass `--none-ok yes`.)')
            sys.exit(2)
        again = sorted(set(hit) | first)
        dest = opt('--out')
        if dest: open(dest, 'w').write(''.join(p + '\n' for p in again))
        only_first = sorted(first - set(hit))
        print(f'{len(bills)} bill(s): {len(touched)} of {len(ids)} people hold a finding on one; {len(hit)} hold a counted Yes act on one WITH a rung; '
              f'{len(only_first)} more hold their first finding on the topic here; {len(again)} to code again' + (f' -> {dest}' if dest else ''))
        for b in bills: print(f"  {b}: rung {table['bills'][b].get('rung')}; {sum(1 for v in hit.values() if b in v)} with a counted Yes")
        if only_first: print('  first finding (a "no stance" code cannot stand): ' + ', '.join(only_first))
        print('Code again only the people listed. ' + ('None: no code can change, so no round is needed.' if not again else 'Run them as one round (run_state.py --round …).'))
        return
    if cmd == 'votes':
        ds, state = opt('--ds', required=True, usage=USAGE), opt('--state', required=True, usage=USAGE)
        if not ids: raise SystemExit('votes needs --ids')
        L, code, people = votes_report(table, store, ids, ds, state)
        dest = opt('--out')
        if dest and people: open(dest, 'w').write(''.join(x + '\n' for x in sorted(people))); L.append(f'People -> {dest}')
        print('\n'.join(L)); sys.exit(code)
    if cmd == 'questions':
        if not ids: raise SystemExit('questions needs --ids')
        md, nf, nb = questions(table, store, ids, rungs)
        # the `votes` check rides along: the datasets sit beside the table (<stage5>/legiscan/ds) and the table is
        # bill-table-<xx>.json, unless --ds and --state say otherwise. Its lines join the questions file.
        ds = opt('--ds', os.path.join(os.path.dirname(os.path.abspath(path)), 'legiscan', 'ds'))
        st = opt('--state', (re.match(r'bill-table-([a-z]{2})\.json$', os.path.basename(path)) or [None, ''])[1])
        vl, vcode, _ = votes_report(table, store, ids, ds, st) if st and os.path.isdir(ds) else (['votes: NOT CHECKED (no --ds/--state, and none found beside the table).'], 2, set())
        md += '\n## Votes with no roll call on disk\n\n' + '\n'.join(vl) + '\n'
        dest = opt('--out')
        if dest: open(dest, 'w').write(md)
        else: print(md)
        print(f'{nf} flagged bill(s), {nb} both-sides person(s)' + (f' -> {dest}' if dest else ''))
        if vcode: print('\n'.join(vl))
        return
    if cmd == 'settle':
        done = settle(table, positional(2, USAGE)[2:], every, opt('--answer', ''))
        json.dump(table, open(path, 'w'), indent=1, ensure_ascii=False); open(path, 'a').write('\n')
        left = sum(1 for r in table['bills'].values() if (r.get('flag') or '').strip())
        print(f'settled {len(done)} bill(s); {left} still flagged')
        return
    raise SystemExit(USAGE)


if __name__ == '__main__':
    main()
