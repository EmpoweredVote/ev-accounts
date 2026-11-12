"""Sponsor cover in round one: every topic bill a roster member sponsored goes into the core set.

usage: python3 -I sponsor_cover.py <bills.json> --state XX --roster <tsv> [--roster <tsv>] --core <core.json>
         --ds <legiscan ds root> [--idmap <idmap.tsv>] [--since 2017]
         [--candidates <out.json>] [--triage <triage.json> --write <new core.json>]

<bills.json> is the scan of the state's LegiScan datasets (scan_gun.py's output: one dict per bill with bill_id,
st, y, num, title, res, sponsors[{pid, name}]). <core.json> is the core set so far, a list of LegiScan bill_ids.

1. Without --triage it lists every non-resolution bill since --since that a roster member sponsored and that is not
   yet core, with its roster sponsors, and --candidates saves that list for a title triage.
2. The keyword scan is wide (Georgia: 164 such bills, among them storage tax credits, game and fish, juvenile
   court), and each core bill costs a bill-text fill. So one Opus pass reads the titles
   (templates/stage5-sponsor-triage-prompt.md) and writes <triage.json>: {"<bill_id>": "fill" | "skip", ...}, "fill"
   for any title that may be on the question and every one it is unsure of.
3. With --triage and --write it saves core + the "fill" bills, and refuses while any candidate is untriaged.

Why: Wisconsin, Arizona and Georgia each needed a second bill round after the search (5, 8 and 13 bills), because
the greedy cover stopped once a bill added fewer than two people (review 2026-11-12, change 7).
Prints the LegiScan people it matched by name, so they can be added to idmap.tsv once.
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, opts, positional
from _legiscan_people import Matcher, read_idmap, read_people, read_roster

USAGE = 'sponsor_cover.py <bills.json> --state XX --roster <tsv> --core <core.json> --ds <ds root> [--idmap <tsv>] [--since 2017] [--candidates <out.json>] [--triage <json> --write <out.json>]'


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
        if who: add.append(dict(bill_id=b['bill_id'], y=b['y'], num=b['num'], title=b['title'], sponsors=[roster[x]['full_name'] for x in who]))
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
        bad = {k: v for k, v in t.items() if v not in ('fill', 'skip')}
        if bad: raise SystemExit(f'triage values must be fill or skip: {bad}')
        left = [a for a in add if str(a['bill_id']) not in t]
        if left: raise SystemExit(f"{len(left)} candidate(s) not triaged, e.g. {left[0]['y']} {left[0]['num']}: triage every one")
        fill = [a['bill_id'] for a in add if t.get(str(a['bill_id'])) == 'fill']
        json.dump(sorted(core | set(fill)), open(out, 'w'))
        print(f'wrote {out}: core {len(core)} + {len(fill)} sponsored (skipped {len(add) - len(fill)} by title)')

if __name__ == '__main__':
    main()
