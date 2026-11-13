"""Sponsor cover in round one: every topic bill a roster member sponsored goes into the core set.

usage: python3 -I sponsor_cover.py <bills.json> --state XX --roster <tsv> [--roster <tsv>] --core <core.json>
         --ds <legiscan ds root> [--idmap <idmap.tsv>] [--since 2017]
         [--candidates <out.json>] [--triage <triage.json> --write <new core.json>]
         [--refile-tolerance 0.02 | --keep-refiled] [--refiled-out <json>] [--stubs-out <json>]

<bills.json> is the scan of the state's LegiScan datasets (scan_gun.py's output: one dict per bill with bill_id,
st, y, num, title, res, sponsors[{pid, name}]). <core.json> is the core set so far, a list of LegiScan bill_ids.

1. Without --triage it lists every non-resolution bill since --since that a roster member sponsored and that is not
   yet core, with its roster sponsors, and --candidates saves that list for a title triage.
2. The keyword scan is wide (Georgia: 164 such bills, among them storage tax credits, game and fish, juvenile
   court), and each core bill costs a bill-text fill. So one Opus pass reads the titles
   (templates/stage5-sponsor-triage-prompt.md) and writes <triage.json>: {"<bill_id>": "fill" | "skip", ...}, "fill"
   for any title that may be on the question and every one it is unsure of.
3. With --triage and --write it saves core + the "fill" bills, and refuses while any candidate is untriaged.
4. Re-file trim (on by default; --keep-refiled turns it off). Some states re-file the same bill every year: Missouri's
   sponsor cover gave 277 "fill" bills, mostly copies, and each costs a bill-text fill and coder reading. Among the
   "fill" bills, a copy is grouped with others of the same title (case and punctuation ignored) and the same prime
   sponsors. The newest copy is kept. An older copy is kept only when it adds a roster sponsor no kept copy has, or
   when its text differs from every kept copy. LegiScan's datasets hold no bill text, only each text's size, so
   "differs" means the introduced texts' sizes differ by more than --refile-tolerance (default 0.02, i.e. 2%); a copy
   with no size on file is kept. Missouri: copies of one text differed by at most 1.1%, changed ones by 2.8% or more.
   Core bills (floor votes) are never trimmed. Every dropped copy, with the copy kept instead, goes to --refiled-out
   (default <write>.refiled.json).

5. Text fill only where it can matter (round three, 2026-11-13). The triage may also answer "stub": the bill is on
   the topic, but its title and summary show it can carry no rung (a dealer business rule, a tax, a storage rule, a
   report or study, police carry, a gun crime's sentence). A stub is not filled and does not join the core set. It
   is listed for the runner in --stubs-out (default <write>.stubs.json) with its roster sponsors, so the runner can
   send any of them to a fill. Two guards, both applied here and never left to the triage:
   - a bill a roster member voted on in a floor roll call is always filled: "stub" is turned into "fill" and printed.
     A floor roll call is one that lists more than half of the largest roll call of its chamber in that session
     (a committee lists a handful of members; the floor lists the chamber). Each candidate carries `floor_voters`.
   - a stub is never trimmed, merged or guessed into a rung: no instrument, so a record on it cannot seat anyone and
     its sponsors go to an Opus coder in the record pass (record-script.ts lane "sponsor-no-rung").
   California replay: see README.md.

Why: Wisconsin, Arizona and Georgia each needed a second bill round after the search (5, 8 and 13 bills), because
the greedy cover stopped once a bill added fewer than two people (review 2026-11-12, change 7).
Prints the LegiScan people it matched by name, so they can be added to idmap.tsv once.
"""
import glob, json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, opts, positional
from _legiscan_people import Matcher, read_idmap, read_people, read_roster

USAGE = 'sponsor_cover.py <bills.json> --state XX --roster <tsv> --core <core.json> --ds <ds root> [--idmap <tsv>] [--since 2017] [--candidates <out.json>] [--triage <json> --write <out.json>] [--refile-tolerance 0.02 | --keep-refiled] [--refiled-out <json>] [--stubs-out <json>]'
TRIAGE = ('fill', 'stub', 'skip')


def text_sizes(ds, st, ids):
    """bill_id -> size of its introduced text (else its first text), from the LegiScan dataset files."""
    out = {}
    for f in glob.glob(os.path.join(ds, f'{st}-*', '*', '*', 'bill', '*.json')):
        b = json.load(open(f)).get('bill', {})
        if b.get('bill_id') not in ids: continue
        t = b.get('texts') or []
        pick = next((x for x in t if x.get('type') == 'Introduced'), t[0] if t else None)
        if pick and pick.get('text_size'): out[b['bill_id']] = pick['text_size']
    return out


def floor_voters(ds, st, ids, matcher):
    """bill_id -> roster members (politician ids) who cast a vote in a floor roll call on it.

    A floor roll call lists more than half as many members as the largest roll call of its chamber in that session.
    """
    out = {}
    for d in glob.glob(os.path.join(ds, f'{st}-*', '*', '*')):
        calls, top = [], {}
        for f in glob.glob(os.path.join(d, 'vote', '*.json')):
            r = json.load(open(f)).get('roll_call', {})
            n = len(r.get('votes') or [])
            top[r.get('chamber')] = max(top.get(r.get('chamber'), 0), n)
            if r.get('bill_id') in ids: calls.append((r, n))
        for r, n in calls:
            if n * 2 <= top.get(r.get('chamber'), 0): continue
            who = {matcher.match(v['people_id']) for v in r['votes'] if v.get('vote_text') in ('Yea', 'Nay')}
            out.setdefault(r['bill_id'], set()).update(x for x in who if x)
    return out


def trim_refiled(bills, matcher, sizes, tol):
    """(kept ids, {dropped id: why}) for bills of one state: the re-file rule in the module doc."""
    groups = {}
    for b in bills:
        prime = tuple(sorted(str(s.get('pid')) for s in b.get('sponsors', []) if s.get('t') == 1))
        groups.setdefault((re.sub(r'\W+', ' ', b['title'].lower()).strip(), prime), []).append(b)
    kept, dropped = [], {}
    for v in groups.values():
        have, mine = set(), []
        for b in sorted(v, key=lambda b: (-b['y'], -b['bill_id'])):
            who = {x for x in (matcher.match(s['pid']) for s in b.get('sponsors', [])) if x}
            n = sizes.get(b['bill_id'])
            differs = bool(mine) and (n is None or all(sizes.get(k['bill_id']) is None or abs(n - sizes[k['bill_id']]) > tol * sizes[k['bill_id']] for k in mine))
            if not mine or (who - have) or differs:
                kept.append(b['bill_id']); mine.append(b); have |= who
            else:
                k = mine[0]
                dropped[b['bill_id']] = {'num': b['num'], 'y': b['y'], 'kept_instead': f"{k['num']} ({k['y']})", 'kept_id': k['bill_id'],
                                         'why': 'same title and prime sponsor as a newer copy; no new roster sponsor; text size within '
                                                f'{tol:.0%}' + (f' ({n} vs {sizes.get(k["bill_id"])})' if n else '')}
    return kept, dropped


def main():
    bills_path = positional(1, USAGE)[0]
    st = opt('--state', required=True, usage=USAGE).upper()
    roster = read_roster(opts('--roster'))
    if not roster: raise SystemExit('--roster is required')
    core = set(json.load(open(opt('--core', required=True, usage=USAGE))))
    since = int(opt('--since', '2017'))
    m = Matcher(roster, read_idmap(opt('--idmap')), read_people(opt('--ds', required=True, usage=USAGE), st))
    bills = [b for b in json.load(open(bills_path)) if b.get('st') == st]
    add = []
    for b in sorted(bills, key=lambda b: (-b['y'], b['num'])):
        if b.get('res') or b['y'] < since or b['bill_id'] in core: continue
        who = sorted({x for x in (m.match(s['pid']) for s in b.get('sponsors', [])) if x})
        if who: add.append(dict(bill_id=b['bill_id'], y=b['y'], num=b['num'], title=b['title'], desc=b.get('desc') or '', sponsors=[roster[x]['full_name'] for x in who]))
    voters = floor_voters(opt('--ds'), st, {a['bill_id'] for a in add}, m)
    for a in add: a['floor_voters'] = len(voters.get(a['bill_id'], ()))
    core_sponsored = {x for b in bills if b['bill_id'] in core for x in (m.match(s['pid']) for s in b.get('sponsors', [])) if x}
    newly = {n for a in add for n in a['sponsors']} - {roster[x]['full_name'] for x in core_sponsored}
    print(f'{st}: core {len(core)}; sponsor cover adds {len(add)} bill(s) since {since}; '
          f'{len(newly)} roster member(s) gain their first sponsored core bill')
    for a in add: print(f"  {a['y']} {a['num']:8s} {a['title'][:70]}  [{', '.join(a['sponsors'][:4])}{' …' if len(a['sponsors']) > 4 else ''}]")
    if m.by_name_used:
        print(f'matched by name, not by idmap ({len(m.by_name_used)}); add to idmap.tsv once checked:')
        for ls, (pid, name) in sorted(m.by_name_used.items()): print(f'  {ls}\t{pid}\t# {name}')
    cand = opt('--candidates')
    if cand:
        json.dump(add, open(cand, 'w'), indent=1)
        print('wrote', cand, '(title triage next)')
    out, tri = opt('--write'), opt('--triage')
    if out:
        if not tri: raise SystemExit('--write needs --triage: the candidates are titles only until a triage reads them')
        t = {str(k): v for k, v in json.load(open(tri)).items()}
        bad = {k: v for k, v in t.items() if v not in TRIAGE}
        if bad: raise SystemExit(f'triage values must be fill, stub or skip: {bad}')
        left = [a for a in add if str(a['bill_id']) not in t]
        if left: raise SystemExit(f"{len(left)} candidate(s) not triaged, e.g. {left[0]['y']} {left[0]['num']}: triage every one")
        # A bill a roster member voted on is always filled, whatever the triage expects of its title.
        promoted = [a for a in add if t.get(str(a['bill_id'])) == 'stub' and a['floor_voters']]
        for a in promoted:
            t[str(a['bill_id'])] = 'fill'
            print(f"  stub -> fill: {a['y']} {a['num']} ({a['floor_voters']} roster member(s) voted on it on the floor)")
        fill = [a['bill_id'] for a in add if t.get(str(a['bill_id'])) == 'fill']
        stubs = [a for a in add if t.get(str(a['bill_id'])) == 'stub']
        dropped = {}
        if '--keep-refiled' not in sys.argv:
            tol = float(opt('--refile-tolerance', '0.02'))
            by_id = {b['bill_id']: b for b in bills}
            fill_bills = [by_id[i] for i in fill]
            fill, dropped = trim_refiled(fill_bills, m, text_sizes(opt('--ds'), st, set(fill)), tol)
            rpath = opt('--refiled-out') or re.sub(r'\.json$', '', out) + '.refiled.json'
            json.dump({str(k): v for k, v in sorted(dropped.items())}, open(rpath, 'w'), indent=1)
            print(f're-file trim: {len(fill) + len(dropped)} fill bills -> {len(fill)} kept, {len(dropped)} older copies dropped ({rpath})')
        json.dump(sorted(core | set(fill)), open(out, 'w'))
        spath = opt('--stubs-out') or re.sub(r'\.json$', '', out) + '.stubs.json'
        json.dump([dict(a, stub='Not read: no roster member voted on it and the title triage expects no rung. '
                        'A record on it cannot seat anyone; send it to a fill to change that.') for a in stubs], open(spath, 'w'), indent=1)
        print(f'wrote {out}: core {len(core)} + {len(fill)} sponsored (skipped {len(add) - len(fill) - len(dropped) - len(stubs)} by title, '
              f'{len(dropped)} re-filed copies, {len(stubs)} stubs)')
        if stubs:
            print(f'{len(stubs)} sponsor-only bill(s) not filled, for the runner to read ({spath}):')
            for a in stubs: print(f"  {a['y']} {a['num']:8s} {a['title'][:70]}  [{', '.join(a['sponsors'][:4])}{' …' if len(a['sponsors']) > 4 else ''}]")

if __name__ == '__main__':
    main()
