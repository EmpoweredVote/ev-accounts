"""Results check and scoped roster for one state (card A, step A1), shared by every state and topic.

  python3 -I scripts/stage5/results_scope.py --state XX --roster <fresh roster.tsv> --cands <db-cands.json> --offices <db-offices.json>
      --out <stage5>/<xx> --batches <stage5>/batches [--election "<election name>"] [--hints <stage5>/<xx>/scope-hints.json]

Why: this was `results_scope_<xx>.py` and `scoped_roster_<xx>.py`, copied from the state before with `sed` in every
state (review 2026-11-21: 12 to 22 leg A steps a state touched the previous state's files, and the header of Hawaii's
copy still said it came from Oregon's, which said Nevada's). The rules below are the ones those copies shared, word for
word; what differed between states is now three keys of a hints file. Replayed on Oregon, Hawaii and Nevada: the same
scope.tsv, ids and roster, byte for byte.

Reads (all written by results-scope-data.ts, read-only): --cands, every candidate row of the state's elections this
year; --offices, office -> district. --roster is the fresh `topic:stage5-roster` output. Matching is by politician id,
never by name, except where a candidate row carries no id (printed NAME-MATCH: check each). Party is never read.

Rules. A legislative seat is keyed by its district; any other office by its office id. A sitting official's own-seat
general row decides (won keep, lost drop, uncalled close). Own seat on the ballot without them: drop (left), unless
they won another state seat (keep). Won a federal seat: drop; ran for one, uncalled: close. No race on file for the
seat: keep, leaving unknown. A new winner of a state race keeps (a local official who wins a state seat is state:
runner 2026-11-15); a candidate in an uncalled state race is close; a winner with no politician record is `norecord`.

--election  the general election's name in the data. Without it: the one election of the state whose name holds
            "General" and that has candidate rows. Two such, or none: stop and name them.
--hints     {"election": "...",
             "hand": {"<roster full name>": ["<candidate row's full name>", "<position name>"]},   a row with no id the name rule misses
             "seat_groups": {"<key>": ["<office id>", ...]},     offices that are one seat for a multi-seat race
             "not_up": {"<office id>": "<why this seat is not on the ballot>"}}
            Every entry is a judgment someone made: say who and when in a "_why" key beside it.

Writes <out>/scope.tsv, <out>/keep-ids.txt, close-ids.txt, norecord-ids.txt, and <batches>/<xx>-ids.txt and
<xx>-roster.tsv (the keep rows; a new winner with no roster row gets one built from the race). Prints the counts and
every line a person should read. Exit 2: no verdict (no general election found, no roster row for the state).
"""
import collections, csv, json, os, re, sys, unicodedata
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt

USAGE = ('results_scope.py --state XX --roster <tsv> --cands <json> --offices <json> --out <dir> --batches <dir> '
         '[--election "<name>"] [--hints <json>]')
OUT = ('not_nominated', 'withdrew', 'lost')
STATE_DT = ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC', 'STATE_BOARD_EDUCATION', 'STATE_BOARD')
LEG = ('STATE_LOWER', 'STATE_UPPER')


def toks(n):
    n = unicodedata.normalize('NFKD', n).encode('ascii', 'ignore').decode().lower()
    return [t for t in re.split(r"[^a-z']+", n) if t and t not in ('jr', 'sr', 'ii', 'iii', 'iv')]


def main():
    ST = opt('--state', required=True, usage=USAGE).upper(); xx = ST.lower()
    ROSTER, M, BATCHES = (opt(k, required=True, usage=USAGE) for k in ('--roster', '--out', '--batches'))
    allc = json.load(open(opt('--cands', required=True, usage=USAGE)))
    offs = {o['office_id']: o for o in json.load(open(opt('--offices', required=True, usage=USAGE)))}
    hints = json.load(open(opt('--hints'))) if opt('--hints') and os.path.exists(opt('--hints')) else {}
    HAND = {k: tuple(v) for k, v in (hints.get('hand') or {}).items()}
    GROUP = {oid: key for key, oids in (hints.get('seat_groups') or {}).items() for oid in oids}
    NOT_UP = hints.get('not_up') or {}
    election = opt('--election') or hints.get('election')
    if not election:
        names = collections.Counter(c['election'] for c in allc if 'general' in c['election'].lower())
        if len(names) != 1:
            print(f'results scope {ST}: NO VERDICT. {len(names)} election(s) with "General" in the name hold candidate rows: '
                  f'{dict(names) or sorted({c["election"] for c in allc})}. Name the one to read with --election.'); return 2
        election = next(iter(names))
    gen = [c for c in allc if c['election'] == election]
    if not gen: print(f'results scope {ST}: NO VERDICT. No candidate row for "{election}". Elections on file: {sorted({c["election"] for c in allc})}'); return 2
    every = list(csv.DictReader(open(ROSTER), delimiter='\t'))
    roster = [r for r in every if r['state'] == ST and r['level'] == 'state']
    if not roster: print(f'results scope {ST}: NO VERDICT. The roster has no state-level row for {ST}.'); return 2
    ROSTER_LEVEL = {r['politician_id']: r['level'] for r in every}

    def seat(oid):
        if oid in GROUP: return ('o', GROUP[oid])
        o = offs.get(oid) or {}
        return ('d', o['district_id']) if o.get('district_type') in LEG else ('o', oid)
    races = collections.defaultdict(list)
    for c in gen: races[c['race_id']].append(c)
    by_seat = collections.defaultdict(set)
    for rid, rs in races.items(): by_seat[seat(rs[0]['office_id'])].add(rid)
    by_pid = collections.defaultdict(list)
    for c in gen: by_pid[c['politician_id']].append(c)
    # Many candidate rows carry no politician id (incumbents too). A sitting member with no id-linked row is matched to an
    # unlinked row of the same seat when the family name (last token) and the first given name or its initial agree.
    # Each such match is printed (NAME-MATCH) and must be checked by hand.
    NAME_MATCHED = set()

    def name_rows(r, s):
        a = toks(r['full_name']); out = []
        for rid in by_seat.get(s, ()):
            for c in races[rid]:
                if c['politician_id']: continue
                b = toks(c['full_name'])
                if a and b and a[-1] == b[-1] and (a[0] == b[0] or a[0][0] == b[0][0]): out.append(c)
        return out
    sitting = {r['politician_id'] for r in roster}
    fmt = lambda cs: ', '.join(f"{c['result'] or 'uncalled'} {c['position_name']}" for c in cs)
    rows = []
    for r in roster:
        pid, s = r['politician_id'], seat(r['office_id'])
        own = [c for c in by_pid.get(pid, []) if c['race_id'] in by_seat.get(s, ())]
        oth = [c for c in by_pid.get(pid, []) if c['race_id'] not in by_seat.get(s, ())]
        if not own and not oth and r['full_name'] in HAND:
            hn, hp = HAND[r['full_name']]
            hc = [c for c in gen if not c['politician_id'] and c['full_name'] == hn and c['position_name'] == hp]
            if len(hc) != 1: raise SystemExit(f"hints.hand: {len(hc)} candidate row(s) with no id named {hn!r} for {hp!r} (wanted exactly 1): fix the hint for {r['full_name']}")
            NAME_MATCHED.add(id(hc[0])); print('HAND-MATCH', r['full_name'], '=', hn, hp, hc[0]['result'], sep='\t')
            if seat(hc[0]['office_id']) == s: own = hc
            else: oth = hc
        if not own and not oth:
            own = name_rows(r, s)
            if len(own) > 1: raise SystemExit(f"two name matches for {r['full_name']}: {own}")
            for c in own: NAME_MATCHED.add(id(c)); print('NAME-MATCH', r['full_name'], '=', c['full_name'], c['position_name'], c['result'], sep='\t')
        if not own and not oth and r['office_id'] in NOT_UP:
            rows.append((pid, r['full_name'], r['office'], 'sitting', 'not up / not on file', 'keep', NOT_UP[r['office_id']])); continue
        if own:
            c = own[0]; res = 'ran for own seat'
            if c['result'] in OUT: dec, why = 'drop', f"general {c['result']} {c['position_name']}"
            elif c['result'] == 'won': dec, why = 'keep', f"general won {c['position_name']}"
            else: dec, why = 'close', f"general not called: {c['position_name']}"
        elif oth:
            st_won = [c for c in oth if c['district_type'] in STATE_DT and c['result'] == 'won']
            fed_won = [c for c in oth if (c['district_type'] or '').startswith('NATIONAL') and c['result'] == 'won']
            unc = [c for c in oth if not c['result']]
            if st_won: dec, res, why = 'keep', 'won another state seat', fmt(oth)
            elif fed_won: dec, res, why = 'drop', 'won federal seat; leaves state office', fmt(oth)
            elif unc: dec, res, why = 'close', 'ran elsewhere, not called', fmt(oth)
            elif s in by_seat: dec, res, why = 'drop', 'left', 'own seat on the ballot without them; also ' + fmt(oth)
            else: dec, res, why = 'keep', 'own seat not up; ran elsewhere', 'keeps current seat; also ' + fmt(oth)
        elif s in by_seat: dec, res, why = 'drop', 'left', f'own seat on the {election[3:7] if election[3:7].isdigit() else "this year\'s"} ballot without them'
        else: dec, res, why = 'keep', 'not up / not on file', f'no {election[3:7] if election[3:7].isdigit() else "current"} race on file for this seat (leaving unknown)'
        rows.append((pid, r['full_name'], r['office'], 'sitting', res, dec, why))
    for rid, rs in races.items():
        if rs[0]['district_type'] not in STATE_DT: continue
        pos = rs[0]['position_name']
        for c in rs:
            if c['politician_id'] in sitting or id(c) in NAME_MATCHED: continue
            if not c['politician_id']:
                rows.append(('', c['full_name'], pos, 'candidate', 'no politician record', 'drop' if c['result'] in OUT else 'norecord', f"{c['result'] or 'uncalled'} {pos}; candidate row has no politician id")); continue
            if c['result'] in OUT: rows.append((c['politician_id'], c['full_name'], pos, 'candidate', c['result'], 'drop', f"{c['result']} {pos}"))
            elif not c['result']: rows.append((c['politician_id'], c['full_name'], pos, 'candidate', 'race not called', 'close', f"race not called: {pos}"))
            elif ROSTER_LEVEL.get(c['politician_id']) == 'local':
                # Utah precedent (runner 2026-11-15, Silvia Catten): a local official who wins a state seat is state.
                rows.append((c['politician_id'], c['full_name'], pos, 'candidate', 'new winner, from local', 'keep', f"won {pos}; roster level local; Utah precedent (Catten, runner 2026-11-15): state"))
            elif ROSTER_LEVEL.get(c['politician_id'], 'state') != 'state':
                rows.append((c['politician_id'], c['full_name'], pos, 'candidate', 'new winner, other level', 'drop', f"won {pos}; roster level {ROSTER_LEVEL[c['politician_id']]}"))
            else: rows.append((c['politician_id'], c['full_name'], pos, 'candidate', 'new winner', 'keep', f"won {pos}"))
    os.makedirs(M, exist_ok=True); os.makedirs(BATCHES, exist_ok=True)
    with open(f'{M}/scope.tsv', 'w') as f:
        f.write('politician_id\tname\toffice\tkind\tresult\tdecision\twhy\n')
        for x in sorted(rows, key=lambda x: (x[5], x[3], x[2], x[1])): f.write('\t'.join(x) + '\n')
    for dec in ('keep', 'close', 'norecord'):
        open(f'{M}/{dec}-ids.txt', 'w').write(''.join(x[0] + '\n' for x in rows if x[5] == dec))
    print(f'results scope {ST}, "{election}":', dict(collections.Counter((x[5], x[3], x[4]) for x in rows)))
    for x in rows:
        if x[5] == 'close' or (x[5] == 'drop' and x[3] == 'sitting') or x[4].startswith('new winner, other'): print(x[5].upper(), *x[1:], sep='\t')
    # the scoped roster: the keep rows, from the fresh roster; a new winner not yet seated gets a row built from the race
    ros = {r['politician_id']: r for r in every}
    won = {c['politician_id']: c for c in allc if c['election'] == election and c['result'] == 'won'}
    cols = ['politician_id', 'full_name', 'office_id', 'level', 'state', 'scope', 'leaving', 'race_ids', 'office']
    out = []
    for x in sorted((x for x in rows if x[5] == 'keep'), key=lambda x: (x[5], x[3], x[2], x[1])):
        pid = x[0]
        if pid in ros and ros[pid]['level'] == 'state': out.append(ros[pid])
        else:
            c = won[pid]
            out.append(dict(politician_id=pid, full_name=c['full_name'], office_id=c['office_id'], level='state', state=ST,
                            scope='candidate', leaving='no', race_ids=c['race_id'], office=c['position_name']))
    with open(f'{BATCHES}/{xx}-roster.tsv', 'w') as f:
        f.write('\t'.join(cols) + '\n')
        for r in sorted(out, key=lambda r: r['full_name']): f.write('\t'.join(r[c] or '' for c in cols) + '\n')
    open(f'{BATCHES}/{xx}-ids.txt', 'w').write(''.join(r['politician_id'] + '\n' for r in out))
    blank = sum(not r['office'] for r in out)
    print(f'{len(out)} in scope ->', f'{BATCHES}/{xx}-ids.txt, {xx}-roster.tsv;', dict(collections.Counter(r['office'] for r in out)), '· blank office:', blank)
    if blank: print('🔴 a blank office blocks the record pass: fill it before going on'); return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
