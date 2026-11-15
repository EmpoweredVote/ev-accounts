"""The bill table: one Opus reading of each core bill, made once per state before coding, then checked here.

usage: python3 -I bill_table.py check <table.json> [--store <source-store dir>] [--ids <ids file>] [--rungs 5]
       python3 -I bill_table.py questions <table.json> --ids <ids file> [--store <dir>] [--rungs 5] [--out <questions.md>]
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

check      validates the table against the store: each bill has an instrument file, each rung is in range, each
           `deciding_words` is found in the bill's operative_text (whitespace and case folded). With --ids it also lists
           every on-topic bill those people have a finding on that the table leaves out. Exit 2 on any problem.
questions  writes the runner's questions: every flagged bill, then every person with a Yes act (yea, sponsor, author,
           signed) on ungated bills on BOTH sides of the middle rung — e.g. a Yes on a rung 2 bill and a Yes on a
           rung 4 bill. Gated votes (multi-subject, near-unanimous) are left out, as the coder leaves them out.
           Exit 0 always; the count is printed.
settle     closes a flag: moves `flag` to `question`, writes --answer to `answered`, and empties `flag`. Name the bills,
           or pass --all for every flagged bill (one answer that covers them all). A named bill with no flag, an
           unknown bill or an empty answer is refused (exit 2) and nothing is written. The rung is not changed: when
           the answer changes it, edit `rung`, `deciding_words` and `why` and run `check` again.

Why: in Georgia the coders read the same 47 bills 204 times, and the rung each bill supports was argued afresh in
each batch; the both-sides people were found only at the early check (review 2026-11-12, change 2).
Florida, 2026-11-14: with no `settle`, a session appended "[Settled ...]" to the `flag` of all 149 rows, the record
script read every bill as unanswered and coded 0 of 154 people. `check` now refuses a flag that reads as answered.
"""
import glob, json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, positional

HERE = os.path.dirname(os.path.abspath(__file__))
STORE = os.path.normpath(os.path.join(HERE, '..', '..', 'data', 'source-store'))
USAGE = 'bill_table.py check|questions|settle <table.json> [<bill id>... | --all] [--answer <text>] [--store <dir>] [--ids <file>] [--rungs 5] [--out <md>]'
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
        flag = row.get('flag') or ''
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
            if not row or row.get('rung') is None or f.get('act') not in YES or gated(f, topic): continue
            (lo if row['rung'] < mid else hi if row['rung'] > mid else set()).add(f"{f['instrument_id']} r{row['rung']} {f['act']}")
        if lo and hi: both.append((pid, sorted(lo), sorted(hi)))
    out.append(f'\n## Yes on both sides of rung {mid:g} ({len(both)})\n')
    out += [f"- {pid}: {', '.join(lo)} | {', '.join(hi)}" for pid, lo, hi in both] or ['- none']
    return '\n'.join(out) + '\n', len(flagged), len(both)


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


def main():
    every = '--all' in sys.argv
    if every: sys.argv.remove('--all')  # positional() reads the word after any --flag as its value
    cmd, path = positional(2, USAGE)[:2]
    table = json.load(open(path))
    store, rungs = opt('--store', STORE), int(opt('--rungs', '5'))
    ids = read_ids(opt('--ids')) if opt('--ids') else []
    if cmd == 'check':
        p = check(table, store, ids, rungs)
        for x in p: print(' ', x)
        nf = sum(1 for r in table['bills'].values() if (r.get('flag') or '').strip())
        print(f"{len(table['bills'])} bills, {len(p)} problem(s), {nf} flagged (open questions)" + (': the record script codes nobody with an act on a flagged bill' if nf else ''))
        sys.exit(2 if p else 0)
    if cmd == 'questions':
        if not ids: raise SystemExit('questions needs --ids')
        md, nf, nb = questions(table, store, ids, rungs)
        dest = opt('--out')
        if dest: open(dest, 'w').write(md)
        else: print(md)
        print(f'{nf} flagged bill(s), {nb} both-sides person(s)' + (f' -> {dest}' if dest else ''))
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
