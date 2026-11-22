"""Draw the local-official pilot sample (spec §8): 100 people from the gun-policy roster's local pool, stratified by
office group and spread across states, with California capped at its share. No database: office titles come from the
roster's `office` column.

usage: python3 -I scripts/stage5/local_pilot_sample.py --roster <roster.tsv> --out <dir> [--n 100]

The seed is read from <out>/seed.txt. The runner writes it BEFORE the draw, so the seed is on record first. Exit 2, with
nothing written, when it is missing. Same seed and same roster give an identical sample.tsv.
Writes <out>/sample.tsv (politician_id, full_name, state, office, stratum) and <out>/strata.md (pool and sample counts per
stratum and per state, duplicates dropped, and any state cap that had to give way).

Pool: roster rows with level 'local'. The roster may list one person more than once (several offices); the FIRST row
for each politician_id is kept and the count of dropped rows is reported in strata.md.

Strata, matched on the office title, case-insensitive, first match wins, in this order (STRATA is the output order):
  sheriff            title has "sheriff"
  other (forced)     title names a special district, school body, or an elected row officer (OTHER_FIRST), or is blank
  county             county commission(er), county board/council/legislature/court, board of supervisors,
                     supervisor (not "supervisor of elections"), judge-executive, fiscal court, "commissioner"
                     with no city/town word (COUNTY_WORDS)
  council-and-mayor  council, alder, aldermen, selectman, selectboard, mayor, town/village/city board or commission,
                     city commissioner, township trustees, town supervisor (COUNCIL_WORDS)
  other              anything else, including a blank or unrecognised title.
"County council" is county, not council-and-mayor, because the county words are tested first.

Allocation of n (default 100): each stratum gets min(10, its pool), and the rest is shared by pool size (largest
remainder), never above a stratum's pool. Because the roster's office column is mostly blank, `other` is large.

Spread: a state may hold at most ceil(its pool share x n) + 1 of the sample; California at most ceil(its pool share x n)
(no +1). People are taken from a seeded shuffle of each stratum, smallest pool first, skipping anyone whose state is full.
If a stratum cannot fill its quota under the caps (its pool sits in full states), the stratum minimum wins: the
remaining places go to non-California people from the least-filled state (ties: state code, then shuffle order),
and strata.md names the state that went over its cap. California is never relaxed; if it would have to be, exit 3.
"""
import csv, math, os, random, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt

USAGE = 'local_pilot_sample.py --roster <roster.tsv> --out <dir> [--n 100]'
STRATA = ['council-and-mayor', 'county', 'sheriff', 'other']
MIN_PER_STRATUM = 10

SHERIFF_WORDS = r'sheriff'
OTHER_FIRST = (r'soil|water|conservation|school|education|superintendent|park|fire|utility|utilities|port\b|hospital|library|drain|cemetery|'
               r'levee|irrigation|sanitary|transit|supervisor of elections|assessor|appraiser|clerk|coroner|treasurer|auditor|collector|'
               r'recorder|surveyor|constable|magistrate|probate|prosecut|attorney|judge(?!.?exec)|court(?! ?commission)|comptroller|register of deeds|'
               r'state (senate|house)|commonwealth')
COUNTY_WORDS = (r'county (commission|board|council|legislat|court|judge|executive|supervisor)|board of (county )?(commissioners|supervisors)|'
                r'\bsupervisor\b|judge.?executive|fiscal court|county executive|^commissioner|\bcommissioner\b(?!.*(city|town|village))|'
                r'^county\b')
COUNCIL_WORDS = (r'council|alder|selectman|selectmen|selectboard|select board|mayor|(town|village|city|borough) (board|commission|trustee)|'
                 r'city commission|township (trustee|board)|board of trustees|trustee|town supervisor|township supervisor|commission(er)? .*(city|town|village)|'
                 r'(city|town|village) commission')


def stratum(title):
    t = (title or '').strip().lower()
    if not t: return 'other'
    if re.search(SHERIFF_WORDS, t): return 'sheriff'
    if re.search(OTHER_FIRST, t) and not re.search(r'county (commission|board|council)|board of (county )?commissioners', t): return 'other'
    if re.search(r'town supervisor|township supervisor', t): return 'council-and-mayor'
    if re.search(COUNTY_WORDS, t) and not re.search(r'city commission|town commission', t): return 'county'
    if re.search(COUNCIL_WORDS, t): return 'council-and-mayor'
    return 'other'


def read_pool(path):
    seen, pool, dups = set(), [], 0
    for r in csv.DictReader(open(path, newline=''), delimiter='\t'):
        if (r.get('level') or '').strip() != 'local': continue
        pid = r['politician_id']
        if pid in seen: dups += 1; continue
        seen.add(pid)
        office = (r.get('office') or '').strip()
        pool.append({'politician_id': pid, 'full_name': r.get('full_name') or '', 'state': (r.get('state') or '').strip().upper(),
                     'office': office, 'stratum': stratum(office)})
    return pool, dups


def quotas(pool_sizes, n):
    q = {s: min(MIN_PER_STRATUM, pool_sizes[s]) for s in STRATA}
    rest = n - sum(q.values()); total = sum(pool_sizes.values())
    if rest < 0: raise SystemExit(f'--n {n} is smaller than the stratum minimums ({sum(q.values())})')
    while rest > 0:
        room = {s: pool_sizes[s] - q[s] for s in STRATA if pool_sizes[s] - q[s] > 0}
        if not room: break
        # largest remainder over what is left to share, by pool size
        share = {s: rest * pool_sizes[s] / sum(pool_sizes[x] for x in room) for s in room}
        add = {s: min(int(share[s]), room[s]) for s in room}
        if sum(add.values()) == 0:  # hand out the last places by largest fractional part, then STRATA order
            for s in sorted(room, key=lambda s: (-(share[s] - int(share[s])), STRATA.index(s)))[:rest]: add[s] = 1
        for s, a in add.items(): q[s] += a
        rest = n - sum(q.values())
    return q


def draw(pool, n, seed):
    if len(pool) < n: raise SystemExit(f'the local pool has {len(pool)} people, fewer than --n {n}')
    total = len(pool)
    by_state = {}
    for p in pool: by_state[p['state']] = by_state.get(p['state'], 0) + 1
    cap = {s: math.ceil(c / total * n) + (0 if s == 'CA' else 1) for s, c in by_state.items()}
    by_stratum = {s: [p for p in pool if p['stratum'] == s] for s in STRATA}
    q = quotas({s: len(v) for s, v in by_stratum.items()}, n)
    rng = random.Random(seed)
    count, chosen, over = {}, [], []
    for s in sorted(STRATA, key=lambda s: (len(by_stratum[s]), STRATA.index(s))):
        cand = list(by_stratum[s]); rng.shuffle(cand); got = []
        for p in cand:
            if len(got) == q[s]: break
            if count.get(p['state'], 0) < cap[p['state']]:
                got.append(p); count[p['state']] = count.get(p['state'], 0) + 1
        if len(got) < q[s]:
            left = [p for p in cand if p not in got and p['state'] != 'CA']
            while len(got) < q[s] and left:
                i = min(range(len(left)), key=lambda i: (count.get(left[i]['state'], 0) / cap[left[i]['state']], left[i]['state'], i))
                p = left.pop(i); got.append(p); count[p['state']] = count.get(p['state'], 0) + 1
                if count[p['state']] > cap[p['state']]: over.append((s, p['state']))
            if len(got) < q[s]:
                print(f'stratum {s}: only California people are left to fill it; refusing to break the California cap', file=sys.stderr); sys.exit(3)
        chosen += got
    return chosen, q, cap, over, by_state


def main():
    roster = opt('--roster', required=True, usage=USAGE); out = opt('--out', required=True, usage=USAGE); n = int(opt('--n', '100'))
    seed_path = os.path.join(out, 'seed.txt')
    if not os.path.exists(seed_path):
        print(f'{seed_path} is missing. Record the seed there before drawing the sample. Nothing written.', file=sys.stderr); return 2
    seed = open(seed_path).read().strip()
    if not seed: print(f'{seed_path} is empty. Nothing written.', file=sys.stderr); return 2
    pool, dups = read_pool(roster)
    chosen, q, cap, over, by_state = draw(pool, n, seed)
    chosen.sort(key=lambda p: p['politician_id'])
    with open(os.path.join(out, 'sample.tsv'), 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t', lineterminator='\n'); w.writerow(['politician_id', 'full_name', 'state', 'office', 'stratum'])
        for p in chosen: w.writerow([p['politician_id'], p['full_name'], p['state'], p['office'], p['stratum']])
    pool_by = {s: sum(p['stratum'] == s for p in pool) for s in STRATA}
    samp_by = {s: sum(p['stratum'] == s for p in chosen) for s in STRATA}
    lines = [f'# Local pilot sample', '', f'Seed: `{seed}`. Roster: `{os.path.basename(roster)}`. n = {len(chosen)}.', '',
             f'Pool: {len(pool)} local people. Duplicate rows dropped (first row per politician_id kept): {dups}.', '',
             '## By stratum', '', '| stratum | pool | sample |', '|---|---|---|']
    lines += [f'| {s} | {pool_by[s]} | {samp_by[s]} |' for s in STRATA] + [f'| total | {len(pool)} | {len(chosen)} |', '',
             '## By state', '', '| state | pool | pool share | cap | sample |', '|---|---|---|---|---|']
    for st in sorted(by_state, key=lambda s: (-by_state[s], s)):
        lines.append(f'| {st or "(blank)"} | {by_state[st]} | {by_state[st] / len(pool):.1%} | {cap[st]} | {sum(p["state"] == st for p in chosen)} |')
    lines += ['', '## Caps', '', 'A state holds at most ceil(pool share x n) + 1 people; California at most ceil(pool share x n).']
    lines.append('Stratum minimums forced these places over a cap: ' + (', '.join(f'{s} / {st}' for s, st in over) if over else 'none') + '.')
    open(os.path.join(out, 'strata.md'), 'w').write('\n'.join(lines) + '\n')
    print(f'{len(chosen)} people drawn from {len(pool)}; sample.tsv and strata.md in {out}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
