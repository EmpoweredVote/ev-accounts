"""Record first, then search only where the record leaves the seat open. MISSOURI PILOT ONLY (STAGE5.md "Pilot rule").

usage: python3 -I search_list.py plan    --record-codes <dir> --roster <tsv> [--roster <tsv>] --skip-rungs 5,2
                                         [--control 20] [--seed <text>] --out <dir>
       python3 -I search_list.py control --record-codes <dir> --codes <dir> --out <dir>
       python3 -I search_list.py adopt   --record-codes <dir> --codes <dir> --out <dir>

The record-only pass codes everyone from their voting and sponsor record alone (coder-inputs.ts --record-only), into
<record-codes>. Then:

plan     A person whose record-only code is a record seat at one of --skip-rungs is not searched. A seeded random
         --control of those (default 20) is searched anyway. Writes <out>/search.tsv (everyone to search: no
         record seat at a skip rung, plus the control), skipped.tsv, control.tsv and search-plan.md. The seed
         defaults to the roster file names, so a re-run gives the same control.
control  After the full search and code: compares each control person's full code in <codes> with their record-only
         code. A change of outcome or rung counts. Exit 4 when more than 1 in 20 changed: the rule is not safe here,
         so search the skipped people too. Exit 3 while a control person has no full code yet.
adopt    Runs `control` first and stops on its exit. Then copies each skipped person's record-only code into <codes>,
         never over an existing file, and lists what it copied.

Why: Georgia searched 100% of people, and for record seats at rung 5 (244 people) and rung 2 (12) the search
changed no seat (review 2026-11-12, section 6). Rungs 3 and 4 did change (2.3% and 10%), so they are always
searched. The rungs are a flag, not a default, because the measurement is for gun-policy only.
"""
import csv, hashlib, json, os, random, shutil, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, opts, positional
from _legiscan_people import read_roster

USAGE = 'search_list.py plan|control|adopt --record-codes <dir> [--roster <tsv> --skip-rungs 5,2] [--codes <dir>] --out <dir>'


def load_codes(d):
    out = {}
    for f in os.listdir(d) if d and os.path.isdir(d) else []:
        if f.endswith('.json'): out[f[:-5]] = json.load(open(os.path.join(d, f)))
    return out


def is_skip(c, rungs):
    return c.get('outcome') == 'seated' and c.get('value') in rungs and c.get('evidence_basis') == 'record'


def write_tsv(path, roster, pids, extra=None):
    with open(path, 'w', newline='') as fh:
        w = csv.writer(fh, delimiter='\t'); w.writerow(['politician_id', 'full_name'] + (['record_only'] if extra else []))
        for p in pids: w.writerow([p, roster.get(p, {}).get('full_name', '')] + ([extra[p]] if extra else []))


def label(c): return f"{c.get('outcome')}{'' if c.get('value') is None else ' ' + str(c.get('value'))}"


def plan(out):
    roster = read_roster(opts('--roster'))
    if not roster: raise SystemExit('--roster is required')
    rungs = {int(x) for x in opt('--skip-rungs', required=True, usage=USAGE).split(',') if x.strip()}
    rec = load_codes(opt('--record-codes', required=True, usage=USAGE))
    n = int(opt('--control', '20'))
    seed = opt('--seed') or '|'.join(sorted(os.path.basename(p) for p in opts('--roster')))
    skip = sorted(p for p in roster if p in rec and is_skip(rec[p], rungs))
    ctrl = sorted(random.Random(int(hashlib.sha256(seed.encode()).hexdigest(), 16)).sample(skip, min(n, len(skip))))
    search = sorted(p for p in roster if p not in set(skip)) + ctrl
    os.makedirs(out, exist_ok=True)
    write_tsv(f'{out}/search.tsv', roster, search)
    write_tsv(f'{out}/skipped.tsv', roster, [p for p in skip if p not in set(ctrl)], {p: label(rec[p]) for p in skip})
    write_tsv(f'{out}/control.tsv', roster, ctrl, {p: label(rec[p]) for p in ctrl})
    nocode = [p for p in roster if p not in rec]
    open(f'{out}/search-plan.md', 'w').write(
        f'# Search plan (pilot rule: skip record seats at rung {", ".join(map(str, sorted(rungs)))})\n\n'
        f'- roster: {len(roster)}\n- record seat at a skip rung: {len(skip)}\n- of those, control (searched anyway, seed `{seed}`): {len(ctrl)}\n'
        f'- to search: {len(search)} (includes {len(nocode)} with no record-only code)\n- not searched: {len(skip) - len(ctrl)}\n')
    print(f'roster {len(roster)}: search {len(search)} (control {len(ctrl)}), skip {len(skip) - len(ctrl)} -> {out}')


def control(out):
    rec = load_codes(opt('--record-codes', required=True, usage=USAGE))
    full = load_codes(opt('--codes', required=True, usage=USAGE))
    ctrl = [r['politician_id'] for r in csv.DictReader(open(f'{out}/control.tsv'), delimiter='\t')]
    missing = [p for p in ctrl if p not in full]
    if missing:
        print(f'{len(missing)} control person(s) have no full code yet, e.g. {missing[0]}'); return 3
    changed = [(p, label(rec[p]), label(full[p])) for p in ctrl if (rec[p].get('outcome'), rec[p].get('value')) != (full[p].get('outcome'), full[p].get('value'))]
    for p, a, b in changed: print(f'  changed {p}: record-only {a} -> full {b}')
    ok = len(changed) * 20 <= len(ctrl)
    print(f'control: {len(changed)} of {len(ctrl)} changed; ' + ('within 1 in 20, the rule holds' if ok else 'more than 1 in 20: search the skipped people too'))
    return 0 if ok else 4


def adopt(out):
    rc = control(out)
    if rc: return rc
    src, dst = opt('--record-codes'), opt('--codes')
    skipped = [r['politician_id'] for r in csv.DictReader(open(f'{out}/skipped.tsv'), delimiter='\t')]
    done = kept = 0
    for p in skipped:
        t = os.path.join(dst, f'{p}.json')
        if os.path.exists(t): kept += 1; continue
        shutil.copyfile(os.path.join(src, f'{p}.json'), t); done += 1
    print(f'adopted {done} record-only code(s) into {dst}; {kept} already had a code and were left alone')
    return 0


def main():
    cmd = positional(1, USAGE)[0]
    out = opt('--out', required=True, usage=USAGE)
    if cmd == 'plan': plan(out); return 0
    if cmd == 'control': return control(out)
    if cmd == 'adopt': return adopt(out)
    raise SystemExit(USAGE)


if __name__ == '__main__':
    sys.exit(main())
