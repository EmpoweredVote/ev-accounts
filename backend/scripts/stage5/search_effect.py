"""What the own-words search changed, per state, split by the rung the record gave (process-efficiency addendum,
round two, change 6). Companion to stage5_usage.py; reads files only.

usage: python3 -I scripts/stage5/search_effect.py --roster <tsv> --unit state:xx --record-codes <dir> --codes <dir>
                                                  --plan <search plan dir> [--ids <file>] [--json <out>]

--plan  the folder `search_list.py plan` wrote (search.tsv, control.tsv, skipped.tsv). When control.tsv carries a
        `group` column (`plan --control-group`), each control is also reported apart, under "controls".
--ids   the state's id list (batches/xx-ids.txt): count only these people. Pass it whenever roster.tsv still holds
        people dropped from scope; without it Washington counted 274 people for 160 and gave 0.74 codings per person.

For every SEARCHED person in the unit it compares the record-only code (<record-codes>) with the final code (<codes>):
- "changed" = the outcome or the rung differs (seated 4 -> seated 3 counts; doesn't fit -> seated counts);
- grouped by the record-only result: seated 5, 4, 3, 2, 1, doesnt-fit, or "no record" (no record-only code).
It also counts codings per person: record-only codes plus final codes a coder made (a final code identical to the
record-only code was kept by `search_list.py recode` or `adopt`, not coded again), over the unit's roster count.
Send-backs are not counted (each is a partial re-code of one person). The control people are shown apart too.

Why: the pilot rule skips the search for record seats at rungs 5 and 2. Before any lighter search for rung 3 record
seats (4 of 171 changed in the first five states), two or three states of this count must exist (addendum change 6).
"""
import collections as C, csv, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt

USAGE = 'search_effect.py --roster <tsv> --unit state:xx --record-codes <dir> --codes <dir> --plan <dir> [--ids <file>] [--json <out>]'
ORDER = ['seated 5', 'seated 4', 'seated 3', 'seated 2', 'seated 1', 'doesnt-fit', 'no-stance', 'no record']


def codes(d):
    return {f[:-5]: json.load(open(os.path.join(d, f))) for f in os.listdir(d) if f.endswith('.json')} if os.path.isdir(d) else {}


def label(c):
    if not c: return 'no record'
    v = c.get('value')
    return c['outcome'] + ('' if v is None else f' {v:g}' if isinstance(v, (int, float)) else f' {v}')


def ids(path): return [r['politician_id'] for r in csv.DictReader(open(path), delimiter='\t')] if os.path.exists(path) else []


def main():
    unit = opt('--unit', required=True, usage=USAGE).lower()
    level, _, st = unit.partition(':')
    roster = [r for r in csv.DictReader(open(opt('--roster', required=True, usage=USAGE)), delimiter='\t')
              if r['level'] == level and (not st or r['state'].lower() == st)]
    people = {r['politician_id'] for r in roster}
    if opt('--ids'):
        only = set(open(opt('--ids')).read().split())
        if not only & people: raise SystemExit(f"--ids {opt('--ids')}: none of its ids is in the unit's roster")
        people &= only
    rec, fin = codes(opt('--record-codes', required=True, usage=USAGE)), codes(opt('--codes', required=True, usage=USAGE))
    plan = opt('--plan', required=True, usage=USAGE)
    searched = [p for p in ids(f'{plan}/search.tsv') if p in people]
    ctrl = set(ids(f'{plan}/control.tsv'))
    ctrl_group = {r['politician_id']: r['group'] for r in csv.DictReader(open(f'{plan}/control.tsv'), delimiter='\t') if r.get('group')} if os.path.exists(f'{plan}/control.tsv') else {}
    missing = [p for p in searched if p not in fin]
    by = C.defaultdict(lambda: {'searched': 0, 'changed': 0, 'outcome_changed': 0, 'rung_only': 0, 'people': []})
    for p in searched:
        if p not in fin: continue
        a, b = rec.get(p), fin[p]
        row = by[label(a)]; row['searched'] += 1
        if a and (a.get('outcome'), a.get('value')) == (b.get('outcome'), b.get('value')): continue
        if not a: row.setdefault('final', C.Counter())[label(b)] += 1; continue  # nothing to compare against
        row['changed'] += 1
        row['outcome_changed' if a.get('outcome') != b.get('outcome') else 'rung_only'] += 1
        row['people'].append({'politician_id': p, 'record_only': label(a), 'final': label(b), 'control': p in ctrl})
    rec_n = sum(1 for p in people if p in rec)
    second = sum(1 for p in people if p in fin and (p not in rec or fin[p] != rec[p]))
    out = {'unit': unit, 'roster': len(people), 'searched': len(searched), 'searched_without_final_code': len(missing),
           'control': len([p for p in searched if p in ctrl]),
           'control_changed': sum(1 for r in by.values() for x in r['people'] if x['control']),
           'by_record_result': {k: dict(by[k]) for k in ORDER if k in by},
           'controls': {g: {'searched': sum(1 for p in searched if p in fin and ctrl_group.get(p) == g),
                            'changed': sum(1 for r in by.values() for x in r['people'] if ctrl_group.get(x['politician_id']) == g)}
                        for g in dict.fromkeys(ctrl_group.values())},
           'codings': {'record_only': rec_n, 'second_pass': second, 'total': rec_n + second,
                       'per_person': round((rec_n + second) / len(people), 2) if people else None}}
    print(f"{unit}: roster {len(people)}, searched {len(searched)} (control {out['control']}, changed {out['control_changed']})")
    for g, c in out['controls'].items(): print(f"  control, rung {g}: {c['changed']} of {c['searched']} changed")
    print(f"{'record-only result':20s} {'searched':>8s} {'changed':>8s} {'outcome':>8s} {'rung':>6s}")
    for k, r in out['by_record_result'].items():
        if k == 'no record':
            print(f"{k:20s} {r['searched']:8d}        -  (final: {', '.join(f'{n} {v}' for n, v in sorted(r.get('final', {}).items()))})"); continue
        print(f"{k:20s} {r['searched']:8d} {r['changed']:8d} {r['outcome_changed']:8d} {r['rung_only']:6d}")
        for x in r['people']: print(f"    {x['politician_id']}: {x['record_only']} -> {x['final']}{' (control)' if x['control'] else ''}")
    c = out['codings']
    print(f"codings: record-only {c['record_only']} + second pass {c['second_pass']} = {c['total']}, {c['per_person']} per person")
    if missing: print(f'{len(missing)} searched person(s) have no final code yet, e.g. {missing[0]}')
    if opt('--json'): json.dump(out, open(opt('--json'), 'w'), indent=1)
    return 0


if __name__ == '__main__':
    sys.exit(main())
