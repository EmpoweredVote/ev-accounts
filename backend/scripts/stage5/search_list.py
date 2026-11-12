"""Record first, then search only where the record leaves the seat open; re-code only where the search found something
(STAGE5.md "Pilot rule"; pilot states only, approved for the state after Missouri on 2026-11-12).

usage: python3 -I search_list.py plan    --record-codes <dir> --roster <tsv> [--roster <tsv>] --skip-rungs 5,2
                                         [--control 20] [--seed <text>] --out <dir>
       python3 -I search_list.py control --record-codes <dir> --codes <dir> --out <dir>
       python3 -I search_list.py adopt   --record-codes <dir> --codes <dir> --out <dir>
       python3 -I search_list.py recode  --record-codes <dir> --record-briefs <dir> --out <dir> [--store <dir>]
                                         [--wave-dir <dir>]... [--codes <dir> --apply]

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
recode   After the search import, before the second coding pass. For each person in <out>/search.tsv it decides:
         - SECOND PASS (recode.tsv, recode-ids.txt): at least one on-topic finding in the store that their record-only
           coder was not shown (<record-briefs>/*.findings.json, written by coder-inputs.ts --record-only); or no
           record-only code. A control person follows the same rule: when the search found nothing new, the search
           changed nothing, and that is what the control measures. Run `recode --apply` before `adopt`.
         - SEARCH AGAIN (research-again.tsv, research-again-ids.txt): no search on file; or the search agent did not
           finish (its wave result, with --wave-dir); or the search found nothing while every one of the person's own
           pages it names (official, member, campaign) was blocked or not read, or it names none. Only the first search
           is sent back: once a second search is on file, the person goes to KEEP or SECOND PASS like anyone else.
         - KEEP (keep.tsv): searched, nothing new, search not cut short. Their record-only code stands. The writer
           reads the search's date and places from the store, so the code needs no new text.
         --apply copies the KEEP codes into --codes, never over an existing file. A record-only code whose text
         says it was made before the search is never kept (second pass instead).
         Never show a coder its first code: the second pass is built by coder-inputs.ts as usual, blind.

Why recode: Missouri searched 88 people and re-coded all 88; 44 had a new finding. Of the 44 with nothing new, one
changed (Scott Fitzpatrick, seated 4 -> doesn't fit): his record-only brief did not name his office, so its coder did
not see that his votes were cast in another office. coder-inputs.ts now prints the office and refuses a record-only
pass without one.

Why plan: Georgia searched 100% of people, and for record seats at rung 5 (244 people) and rung 2 (12) the search
changed no seat (review 2026-11-12, section 6). Rungs 3 and 4 did change (2.3% and 10%), so they are always
searched. The rungs are a flag, not a default, because the measurement is for gun-policy only.
"""
import csv, glob, hashlib, json, os, random, re, shutil, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, opts, positional
from _legiscan_people import read_roster

USAGE = 'search_list.py plan|control|adopt|recode --record-codes <dir> [--roster <tsv> --skip-rungs 5,2] [--codes <dir>] [--record-briefs <dir>] --out <dir>'
STORE = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'data', 'source-store'))
UUID = re.compile(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')
# A place that names one of the person's own pages, and the words a searcher writes when it could not read a page.
OWN_PAGE = re.compile(r'campaign|official|member page|memberdetails|\.gov\b|legislature|house\.|senate\.', re.I)
UNREAD = re.compile(r'blocked|not reviewed|not reached|not found|fetch failed|could not (be )?(read|load|fetch|reach)|'
                    r'returned (no|empty)|came back empty|no (usable )?content|does not resolve|\b40[34]\b|\b50\d\b', re.I)
# Text a record-only code must not carry into a final code.
PRE_SEARCH = re.compile(r'not (yet )?searched|before the search|record[- ](only|first)|own words have not|search(ed)? (next|later)', re.I)


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


def tsv_ids(path): return [r['politician_id'] for r in csv.DictReader(open(path), delimiter='\t')] if os.path.exists(path) else []


def own_pages_unread(places):
    """True when the search names none of the person's own pages, or every one it names went unread."""
    own = [p for p in places if OWN_PAGE.search(p) and not p.lower().startswith('sponsor list')]
    return not own or all(UNREAD.search(p) for p in own)


def wave_failures(dirs):
    """politician ids whose search agent did not finish, from wave.py result files (name holds the id)."""
    bad = set()
    for d in dirs:
        for f in glob.glob(os.path.join(d, '**', '*.result.json'), recursive=True):
            m = UUID.search(os.path.basename(f))
            if not m: continue
            try: r = json.load(open(f))
            except ValueError: bad.add(m.group(0)); continue
            if r.get('is_error') or r.get('subtype') not in (None, 'success'): bad.add(m.group(0))
    return bad


def recode(out):
    rec = load_codes(opt('--record-codes', required=True, usage=USAGE))
    briefs = opt('--record-briefs', required=True, usage=USAGE)
    shown = {}
    for f in glob.glob(os.path.join(briefs, '*.findings.json')):
        for p in json.load(open(f))['people']: shown.setdefault(p['politician_id'], set()).update(x['id'] for x in p['findings'])
    if not shown: raise SystemExit(f'no *.findings.json in {briefs}: point --record-briefs at the record-only pass\'s --out folder')
    keys = {(c.get('topic_key'), c.get('season')) for c in rec.values()}
    if len(keys) != 1: raise SystemExit(f'record-only codes are for more than one topic or season: {sorted(map(str, keys))}')
    topic, season = keys.pop()
    store = opt('--store', STORE)
    searched = tsv_ids(f'{out}/search.tsv')
    if not searched: raise SystemExit(f'{out}/search.tsv is missing or empty: run `plan` first')
    failed = wave_failures(opts('--wave-dir'))
    names = {r['politician_id']: r['full_name'] for r in csv.DictReader(open(f'{out}/search.tsv'), delimiter='\t')}
    again, second, keep = [], [], []
    for p in searched:
        fp = os.path.join(store, 'findings', f'{p}.json')
        pf = json.load(open(fp)) if os.path.exists(fp) else {'findings': [], 'searches': []}
        ss = sorted((s for s in pf.get('searches', []) if s.get('topic_key') == topic and s.get('season') == season), key=lambda s: s.get('at', ''))
        new = [f for f in pf.get('findings', []) if topic in f.get('topic_keys', []) and f['id'] not in shown.get(p, set())]
        first_only = len(ss) < 2
        if not ss: again.append((p, 'no search on file')); continue
        if p in failed and first_only: again.append((p, 'the search agent did not finish')); continue
        if p not in rec: second.append((p, 'no record-only code', len(new))); continue
        if new: second.append((p, 'new finding', len(new))); continue
        if first_only and own_pages_unread(ss[-1].get('places', [])):
            again.append((p, 'found nothing, and none of their own pages was read')); continue
        c = rec[p]
        if PRE_SEARCH.search(' '.join([c.get('reasoning', ''), c.get('open_note') or ''])):
            second.append((p, 'record-only text mentions the search', 0)); continue
        keep.append((p, label(c), ss[-1].get('at', '')[:10], len(ss[-1].get('places', []))))
    os.makedirs(out, exist_ok=True)
    def w(name, head, rows):
        with open(f'{out}/{name}', 'w', newline='') as fh:
            wr = csv.writer(fh, delimiter='\t'); wr.writerow(['politician_id', 'full_name'] + head)
            for r in rows: wr.writerow([r[0], names.get(r[0], '')] + list(r[1:]))
    w('recode.tsv', ['why', 'new_findings'], second)
    w('research-again.tsv', ['why'], again)
    w('keep.tsv', ['record_only', 'searched_on', 'places'], keep)
    open(f'{out}/recode-ids.txt', 'w').write(''.join(f'{r[0]}\n' for r in second))
    open(f'{out}/research-again-ids.txt', 'w').write(''.join(f'{r[0]}\n' for r in again))
    by = lambda rows: ', '.join(f'{k} {v}' for k, v in sorted(__import__('collections').Counter(r[1] for r in rows).items()))
    open(f'{out}/recode-plan.md', 'w').write(
        f'# After the search: who is coded again\n\n- searched: {len(searched)}\n'
        f'- second pass: {len(second)} ({by(second) or "none"})\n- search again: {len(again)} ({by(again) or "none"})\n'
        f'- keep the record-only code: {len(keep)}\n')
    print(f'searched {len(searched)}: second pass {len(second)}, search again {len(again)}, keep {len(keep)} -> {out}')
    for r in again: print(f'  search again {r[0]} {names.get(r[0], "")}: {r[1]}')
    if '--apply' in sys.argv:
        dst = opt('--codes', required=True, usage=USAGE)
        os.makedirs(dst, exist_ok=True)
        done = left = 0
        for r in keep:
            t = os.path.join(dst, f'{r[0]}.json')
            if os.path.exists(t): left += 1; continue
            shutil.copyfile(os.path.join(opt('--record-codes'), f'{r[0]}.json'), t); done += 1
        print(f'kept {done} record-only code(s) in {dst}; {left} already had a code and were left alone')
    return 0


def main():
    cmd = positional(1, USAGE)[0]
    out = opt('--out', required=True, usage=USAGE)
    if cmd == 'plan': plan(out); return 0
    if cmd == 'control': return control(out)
    if cmd == 'adopt': return adopt(out)
    if cmd == 'recode': return recode(out)
    raise SystemExit(USAGE)


if __name__ == '__main__':
    sys.exit(main())
