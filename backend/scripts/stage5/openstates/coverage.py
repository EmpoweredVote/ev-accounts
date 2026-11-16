"""Which sessions of an Open States extract hold bills and NO roll calls, before a state is run from it.

  python3 -I scripts/stage5/openstates/coverage.py <extracts/YYYY-MM/st> [<more extract dirs>] [--since 2017] [--min-bills 50] [--json <out.json>]

Why: a dump can hold a session's bills and sponsors and none of its votes, and nothing errors. Utah, 2026-11-15: the
2025 General Session had 962 bills and 0 roll calls; a member's whole 2025 record would have read as "no vote". The
converter builds the session folder anyway, so the scan, the pre-fill and the record script all see an empty record.

Per session from --since on it prints: bills, roll calls, roll calls that list a voter, the share of member votes
linked to a person, and the roll-call hosts with one sample address each (the page a state reader has to read).
A session is a GAP when it has at least 50 bills and
  - no roll call at all, or
  - roll calls of which fewer than 1 in 10 list a voter (tallies only: no member's vote can be read from them).
A special session is held to the same rule only when it has 50 bills; most pass a handful by voice.
⚠ A session that ended less than 30 days before the dump's month may simply not be loaded yet: it is still a gap.

Exit 0: no gap. Exit 1: at least one gap, each named. Exit 2: usage, or the check was blind for a state (a table is missing, or
no session with a bill from --since on was read): that state gets no verdict, and the others are still printed.
"""
import os, sys; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))  # -I drops the script dir
import csv, json, collections
from urllib.parse import urlsplit

csv.field_size_limit(1 << 30)
USAGE = 'coverage.py <extract dir> [<extract dir> ...] [--since 2017] [--min-bills 50] [--json <out.json>]'
MIN_BILLS = 50


def args():
    a = sys.argv[1:]; opts = {}
    for flag in ('--since', '--json', '--min-bills'):
        if flag in a:
            i = a.index(flag)
            if i + 1 >= len(a): print(USAGE); sys.exit(2)
            opts[flag] = a[i + 1]; del a[i:i + 2]
    if not a: print(USAGE); sys.exit(2)
    return a, int(opts.get('--since', 2017)), opts.get('--json'), int(opts.get('--min-bills', MIN_BILLS))


def rows(d, table):
    p = os.path.join(d, f'{table}.tsv')
    if not os.path.exists(p): print(f'coverage: NO VERDICT. {p} is missing'); sys.exit(2)
    with open(p, newline='') as fh:
        yield from csv.DictReader(fh, delimiter='\t', quoting=csv.QUOTE_NONE)


def shape(url):
    """An address with its digits blanked, so one line stands for every roll call of that kind."""
    u = urlsplit(url); out = []
    for ch in (u.path + ('?' + u.query if u.query else '')):
        out.append('#' if ch.isdigit() else ch)
    s = ''.join(out)
    while '##' in s: s = s.replace('##', '#')
    return f'{u.netloc}{s}'


def state(d, since, min_bills):
    sess = {}
    for r in rows(d, 'legislativesession'):
        year = (r.get('start_date') or r.get('identifier') or '')[:4]
        if not year.isdigit():
            digits = ''.join(c for c in r.get('identifier', '') if c.isdigit())[:4]; year = digits if len(digits) == 4 else '0'
        sess[r['id']] = {'id': r['identifier'], 'name': r['name'], 'kind': r.get('classification') or '', 'year': int(year), 'end': r.get('end_date') or '',
                         'bills': 0, 'rollcalls': 0, 'with_voters': 0, 'votes': 0, 'linked': 0, 'shapes': collections.Counter(), 'sample': {}}
    for r in rows(d, 'bill'):
        if r['legislative_session_id'] in sess: sess[r['legislative_session_id']]['bills'] += 1
    ve = {}
    for r in rows(d, 'voteevent'):
        if r['legislative_session_id'] in sess: ve[r['id']] = r['legislative_session_id']; sess[r['legislative_session_id']]['rollcalls'] += 1
    seen = set()
    for r in rows(d, 'personvote'):
        s = sess.get(ve.get(r['vote_event_id']))
        if not s: continue
        s['votes'] += 1
        if r.get('voter_id') not in (None, '', '\\N'): s['linked'] += 1
        if r['vote_event_id'] not in seen: seen.add(r['vote_event_id']); s['with_voters'] += 1
    for r in rows(d, 'votesource'):
        s = sess.get(ve.get(r['vote_event_id']))
        if not s or not r.get('url'): continue
        k = shape(r['url']); s['shapes'][k] += 1; s['sample'].setdefault(k, r['url'])
    out = [s for s in sess.values() if s['year'] >= since]
    for s in out:
        s['gap'] = ''
        if s['bills'] >= min_bills:
            if not s['rollcalls']: s['gap'] = 'no roll call'
            elif s['with_voters'] * 10 < s['rollcalls']: s['gap'] = 'roll calls list no voter'
    return sorted(out, key=lambda s: (s['year'], s['id']))


def main():
    dirs, since, out_json, min_bills = args()
    report, gaps, blind = {}, [], []
    for d in dirs:
        st = os.path.basename(os.path.normpath(d)).upper()
        ss = state(d, since, min_bills)
        if not ss or not sum(x['bills'] for x in ss): blind.append(st); print(f'{st}: NO VERDICT. {d} holds no session with a bill from {since} on'); continue
        report[st] = ss
        print(f'{st}: {len(ss)} session(s) from {since}')
        hosts = collections.Counter(); sample = {}
        for s in ss:
            link = f"{100 * s['linked'] // s['votes']}%" if s['votes'] else '-'
            mark = f"   <-- GAP: {s['gap']}" if s['gap'] else ''
            print(f"  {s['id']:<14} {s['kind'] or '?':<8} bills {s['bills']:>5}  roll calls {s['rollcalls']:>6}  with voters {s['with_voters']:>6}  linked {link:>4}{mark}")
            if s['gap']: gaps.append((st, s))
            for k, n in s['shapes'].items(): hosts[k] += n; sample.setdefault(k, s['sample'][k])
        for k, n in hosts.most_common(4): print(f'    roll-call address ({n}): {sample[k]}')
        if not hosts: print('    no roll-call address in the data')
    if out_json:
        json.dump({st: [{k: (dict(v) if isinstance(v, collections.Counter) else v) for k, v in s.items()} for s in ss] for st, ss in report.items()}, open(out_json, 'w'), indent=1)
    if blind: print(f"coverage: NO VERDICT for {', '.join(blind)} (nothing was read)")
    if not gaps: print('coverage: no gap in the states read.'); sys.exit(2 if blind else 0)
    print(f'coverage: {len(gaps)} GAP(S). A member\'s record for these sessions is NOT on disk; it is not "no vote".')
    for st, s in gaps: print(f"- {st} {s['id']} ({s['name']}): {s['bills']} bills, {s['rollcalls']} roll calls, {s['with_voters']} with voters: {s['gap']}")
    print('Fix: read the missing roll calls from the legislature\'s own site for the bills the scan finds (fetch-legislature-rollcalls.ts), convert again, and say so in the legislature profile under votes.gaps.')
    sys.exit(2 if blind else 1)


if __name__ == '__main__': main()
