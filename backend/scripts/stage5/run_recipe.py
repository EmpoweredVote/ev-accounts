"""Run write-recipe steps 0-12 for one batch, in order, and stop at the first step that needs a person or fails a check.

usage: python3 -I scripts/stage5/run_recipe.py <batch dir> [--from N] [--to 12] [--print] [--check-only N]

Run from a worktree's `backend/` whose `.env` is linked to ev-accounts/backend/.env (STAGE5.md "Running them").
The batch folder holds `recipe.json`, written once by hand:

  {"stage5": "<abs>/stage5", "topic": "gun-policy", "unit": "state:mo", "level": "state", "state": "MO",
   "roster": "<abs>/stage5/roster.tsv", "codes": "<abs>/stage5/codes", "saved_root": "<abs>/.planning/research",
   "votes": "legiscan" | "legiscan-plan" | "iga" | "ma" | "federal" | "none", "official_host": "house.mo.gov",
   "max_urls": 20}

Each step's commands are the ones STAGE5.md names. After each step a check reads what it left; the run stops on:
- a command that fails, or a check that fails (exit 2), with the file to read;
- an AGENT step (1 quote check, 5 reading the old sources) or a HAND step (2 hand rows, 6 party cuts, 9 trims),
  which print what to do and the `--from` to resume with (exit 10).
`--print` shows the commands without running them. `--check-only N` runs step N's check on the files already there.

Order rule (review 2026-11-12, change 7): a LegiScan merge after the bill-text step drops the bill-text pages. So a
run of step 7 marks step 8 stale in `recipe-log.json`, and step 9 refuses to start while step 8 is stale.
Before each step that rewrites research.csv/evidence.csv, both are copied to `research-pre-<step>.csv` /
`evidence-pre-<step>.csv` (STAGE5.md "Save a copy").
At the end it prints the PREVIEW numbers (step 13 is still written by hand, and the write needs the runner's yes).
"""
import csv, glob, json, os, re, shutil, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, positional

BACKEND = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
FINDINGS = os.path.join(BACKEND, 'data', 'source-store', 'findings')
TSX = 'ADMIN_INGEST_TOKEN=placeholder npx tsx --env-file=.env'
PY = 'python3 -I'
AGENT, HAND = 10, 10


class Stop(Exception):
    def __init__(self, code, msg): super().__init__(msg); self.code = code


# ---- reading what a step left ----------------------------------------------------------------------------------

def read(b, f): return open(os.path.join(b, f)).read() if os.path.exists(os.path.join(b, f)) else ''


def section_count(text, head):
    """'refused (9):' -> 9; 0 when the section is absent."""
    m = re.search(rf'^{re.escape(head)} \((\d+)\)', text, re.M)
    return int(m.group(1)) if m else 0


def gate_high(text):
    m = re.search(r'high=(\d+)', text)
    if not m: raise Stop(2, 'no "high=" line in the gate output: the gate did not finish')
    return int(m.group(1))


def json_len(b, f):
    p = os.path.join(b, f)
    if not os.path.exists(p): return 0
    x = json.load(open(p))
    return len(x) if isinstance(x, (list, dict)) else 0


def disagree(b, f):
    p = os.path.join(b, f)
    return 0 if not os.path.exists(p) else sum(1 for r in json.load(open(p)) if r.get('agree') is False)


def lines(b, f): return [l for l in read(b, f).splitlines() if l.strip()]


# ---- steps -------------------------------------------------------------------------------------------------------

def steps(c, b):
    st, key, unit, lvl, state = c['stage5'], c['topic'], c['unit'], c['level'], c.get('state', '')
    scope = f"--level {lvl}" + (f" --state {state}" if lvl == 'state' else '')
    host = c.get('official_host', '')
    write = f"zsh scripts/stage5/write-batch.sh {st} {b} {key} {unit}"
    gate = f"npx tsx scripts/stance-gate.ts --dir {b}"
    verify = f"{TSX} scripts/verify-stance-research.ts --dir {b} --season draft --threshold 1 --batch-id {os.path.basename(b)}"
    votes = {
        'legiscan': [f"{TSX} scripts/stage5/legiscan-rollcalls.ts {state} {b}/legiscan/vote-pages.json {b}/legiscan/rollcall-map.json",
                     f"{PY} scripts/stage5/legiscan_pairs.py {b} {FINDINGS} --topic {key} --state {state} --host {host} --rollcalls {b}/legiscan/rollcall-map.json"],
        'legiscan-plan': [f"{PY} scripts/stage5/state_legiscan.py plan {b} {FINDINGS} --state {state} --host {host}",
                          f"{TSX} scripts/stage5/legiscan-rollcalls.ts {state} {b}/legiscan/vote-pages.json {b}/legiscan/rollcall-hits.json",
                          f"{PY} scripts/stage5/state_legiscan.py pairs {b} {FINDINGS} --state {state} --host {host} --topic {key}"],
        'iga': [f"{TSX} scripts/stage5/iga-votes.ts {b} {FINDINGS} --topic {key}"],
        'ma': [f"{TSX} scripts/stage5/ma-rollcall-votes.ts {b} {FINDINGS} --topic {key}"],
        'federal': [f"{TSX} scripts/stage5/federal-votes.ts {b} {FINDINGS} --topic {key}"],
        'none': [],
    }[c.get('votes', 'legiscan-plan')]
    if c.get('votes') in ('legiscan', 'legiscan-plan', 'federal'):
        votes += [f"{TSX} scripts/legiscan-evidence-lines.ts --in {b}/legiscan/pairs.csv --out {b}/legiscan/legiscan-evidence.csv",
                  f"{PY} scripts/stage5/legiscan_merge.py {b} --host {host}"]
    mx = f" --max-urls {c['max_urls']}" if c.get('max_urls') else ''
    return {
        0: ('dry run 0', [f"{write} 0"], None),
        1: ('quote check', [], 'agent'),
        2: ('dry run again; hand rows', [f"{write} 1"], None),
        3: ('bundle', ['PIDS'], None),
        4: ('evidence', [f"{PY} scripts/stage5/build_evidence.py {b} {c['roster']} {FINDINGS} --fetch {scope}{mx}",
                         f"{PY} scripts/stage5/pdf_pages.py {b}"], 'save'),
        5: ('old Season 1 sources', [f"{gate} > {b}/gate-output-0.txt || true", f"{verify} > {b}/verify-dry-run-0.txt",
                                     f"{TSX} scripts/stage5/s1-sources.ts --topic {key} {b}",
                                     f"{TSX} scripts/stage5/fallback-fetch.ts {b}/fallback"], None),
        6: ('party sweep', [f"npx tsx scripts/stage5/party-sweep.ts {b}/evidence.csv > {b}/party-sweep.jsonl"], None),
        7: ('roll calls', votes, 'save'),
        8: ('bill text', [f"{gate} > {b}/gate-output.txt || true",
                          f"{PY} scripts/stage5/bill_text_auto.py {b} {FINDINGS} --topic {key} --saved-root {c['saved_root']} --gate {b}/gate-output.txt"], 'save'),
        9: ('gate to 0 high', [f"{gate} > {b}/gate-output-final.txt || true"], None),
        10: ('party check on the research text', [f"npx tsx scripts/stage5/party-sweep.ts --research {b}/research.csv > {b}/party-sweep-research.jsonl"], None),
        11: ('audit', [f"node scripts/audit-chair-evidence.mjs --csv {b}/research.csv > {b}/audit-output.txt || true"], None),
        12: ('verifier dry run', [f"{verify} > {b}/verify-dry-run.txt"], None),
    }


def write_pids(c, b):
    """pids.txt: roster ids at this level (and state) with a code file (STAGE5.md step 3)."""
    have = {f[:-5] for f in os.listdir(c['codes']) if f.endswith('.json')}
    held = set(lines(b, 'held.txt')) | set(lines(b, 'moved.txt'))
    rows = [r for r in csv.DictReader(open(c['roster']), delimiter='\t')
            if r['level'] == c['level'] and (c['level'] != 'state' or r['state'].upper() == c['state'].upper())]
    ids = [r['politician_id'] for r in rows if r['politician_id'] in have and r['politician_id'] not in held]
    open(os.path.join(b, 'pids.txt'), 'w').write('\n'.join(ids) + '\n')
    return ids


def bundle_cmd(c, b, ids):
    args = ' '.join(f'--politician "{p}:{c["level"]}"' for p in ids)
    return f"{TSX} scripts/build-stance-topic-bundle.ts --dir {b} --season draft {args} > {b}/bundle-output.txt"


def check(n, c, b):
    """Raise Stop when step n left something a person must handle. Return a one-line summary."""
    if n == 0:
        t = read(b, 'dry-run-0.txt'); r = section_count(t, 'refused')
        codes = len(re.findall(r'^\s+\S+\s+CODE: ', t, re.M))
        if codes: raise Stop(2, f'{codes} refused code(s) in dry-run-0.txt: fix those codes before going on')
        return f"{re.search(r'outcomes:.*', t).group(0) if 'outcomes:' in t else 'no outcomes line'}; refused passages {r}"
    if n == 1:
        raise Stop(AGENT, 'AGENT: run templates/stage5-quote-check-prompt.md (a separate agent, about 20 findings each) on every '
                          'finding a doesnt-fit code cites that is own words or a local record; validate with readQuoteChecks and '
                          'append to stage5/quote-checks.jsonl. Then resume with --from 2.')
    if n == 2:
        t = read(b, 'dry-run-1.txt'); missing = section_count(t, 'not in research.csv')
        if missing and not os.path.exists(os.path.join(b, 'hand-rows.json')):
            raise Stop(HAND, f'HAND: {missing} blank(s) "not in research.csv": decide each by RULINGS.md "Mapping a blank to a V6 '
                             f'reason", write hand-rows.md and hand-rows.json, run add_hand_rows.py, then resume with --from 3.')
        return f'not in research.csv {missing}; refused {section_count(t, "refused")}'
    if n == 3: return f"pids {len(lines(b, 'pids.txt'))}"
    if n == 4:
        miss = json_len(b, 'evidence-missing.json')
        return f'evidence-missing {miss} (read it by host: a JavaScript or bot-check host needs steps 7 and 8)'
    if n == 5:
        need = json_len(os.path.join(b, 'fallback'), 'fallback-required.json')
        if need: raise Stop(AGENT, f'AGENT: {need} blank(s) over a shown answer. Drop OnTheIssues and Wikipedia; one agent reads '
                                   f'fallback/ pages for the question (fallback-read.json/.md); check its "nothing" answers; hold a person '
                                   f'with a new item; then add_fallback.py. Resume with --from 6.')
        return 'no blank over a shown answer'
    if n == 6:
        k = len(lines(b, 'party-sweep.jsonl'))
        if k: raise Stop(HAND, f'HAND: party sweep lists {k} snippet(s): cut or drop (party-cuts.json, party_fix.py), then resume with --from 6.')
        return 'party sweep 0'
    if n == 7:
        vd = {'iga': 'iga', 'ma': 'ma-rollcall', 'federal': 'federal'}.get(c.get('votes'), 'legiscan')
        d = disagree(b, f'{vd}/crosscheck.json') + (disagree(b, 'legiscan/crosscheck.json') if vd == 'federal' else 0)
        if d: raise Stop(2, f'{d} DISAGREE line(s) in the roll-call cross-check: hold those people; it must be 0')
        un = json_len(b, f'{vd}/unmapped.json') + (json_len(b, 'legiscan/unmapped.json') if vd == 'federal' else 0)
        if un: raise Stop(HAND, f'HAND: {un} unmapped vote(s) ({vd}/unmapped.json): hold those people (held.txt, drop_held.py); do not guess. Then --from 8.')
        return f'cross-check 0 disagree, 0 unmapped'
    if n == 8:
        p = os.path.join(b, 'bill-text.json')
        x = json.load(open(p)) if os.path.exists(p) else {}
        placed = sum(len(v.get('placed', [])) for v in x.values()); missed = sum(len(v.get('not_placed', [])) for v in x.values())
        return f'bill text: placed {placed}, not placed {missed} (a quote not placed is trimmed or its bill added, step 9)'
    if n == 9:
        h = gate_high(read(b, 'gate-output-final.txt'))
        if h: raise Stop(HAND, f'HAND: gate high={h} (gate-output-final.txt). Trim (overrides.json + apply_overrides.py, the tools in step 9) '
                               f'or hold; then resume with --from 9.')
        return 'gate high=0'
    if n == 10:
        k = len(lines(b, 'party-sweep-research.jsonl'))
        words = sum(1 for r in csv.DictReader(open(os.path.join(b, 'research.csv')))
                    for w in re.findall(r'republican|democrat|\bGOP\b', r.get('reasoning', ''), re.I))
        if k or words: raise Stop(HAND, f'HAND: party words in the research text (sweep {k}, grep {words}): reword, then --from 10.')
        return 'research party check 0'
    if n == 11:
        return f"audit flags {len(re.findall(r'^  ·', read(b, 'audit-output.txt'), re.M))} (seated rows on a record must not fail; read it)"
    if n == 12:
        m = re.search(r'AUTO-PUSH.*', read(b, 'verify-dry-run.txt'))
        if not m: raise Stop(2, 'no counts line in verify-dry-run.txt')
        return m.group(0)
    return ''


# ---- running -----------------------------------------------------------------------------------------------------

def log_path(b): return os.path.join(b, 'recipe-log.json')
def load_log(b): return json.load(open(log_path(b))) if os.path.exists(log_path(b)) else {}


def save_copies(b, n):
    for f in ('research', 'evidence'):
        src = os.path.join(b, f'{f}.csv')
        if os.path.exists(src): shutil.copyfile(src, os.path.join(b, f'{f}-pre-step{n}.csv'))


def run_step(n, c, b, dry):
    name, cmds, kind = steps(c, b)[n]
    log = load_log(b)
    if n == 9 and log.get('8_stale'):
        raise Stop(2, 'step 8 (bill text) is stale: step 7 ran after it, and a LegiScan merge drops bill-text pages. Run --from 8.')
    print(f'== step {n}: {name}')
    if kind == 'save' and not dry: save_copies(b, n)
    if n == 3:
        ids = write_pids(c, b) if not dry else []
        cmds = [bundle_cmd(c, b, ids or ['<pids.txt>'])]
    for cmd in cmds:
        print('  $', cmd if len(cmd) < 400 else cmd[:400] + ' …')
        if dry: continue
        p = subprocess.run(cmd, shell=True, cwd=BACKEND, text=True)
        if n == 2 and os.path.exists(os.path.join(b, 'research-stage5-1.csv')):
            shutil.copyfile(os.path.join(b, 'research-stage5-1.csv'), os.path.join(b, 'research.csv'))
        if p.returncode not in (0,) and not (n in (0, 2) and p.returncode == 3):
            raise Stop(2, f'step {n} command failed (exit {p.returncode}): {cmd[:200]}')
    if dry: return
    log[str(n)] = time.strftime('%Y-%m-%dT%H:%M:%S')
    if n == 7: log['8_stale'] = True
    if n == 8: log['8_stale'] = False
    json.dump(log, open(log_path(b), 'w'), indent=1)
    print('  ok:', check(n, c, b))


def preview(b):
    t2, g, v = read(b, 'dry-run-1.txt'), read(b, 'gate-output-final.txt'), read(b, 'verify-dry-run.txt')
    pick = lambda pat, t: (re.search(pat, t).group(0) if re.search(pat, t) else '—')
    print('\n== PREVIEW numbers')
    print('  ', pick(r'outcomes:.*', t2)); print('  ', pick(r'passages:.*', t2))
    print('  ', pick(r'stance-gate:.*', g)); print('  ', pick(r'AUTO-PUSH.*', v))
    print(f"   held {len(lines(b, 'held.txt'))}, moved {len(lines(b, 'moved.txt'))}, pids {len(lines(b, 'pids.txt'))}")
    print('   Write PREVIEW.md (step 13). Nothing is written to the database until the runner says yes for this batch.')


def main():
    b = os.path.abspath(positional(1, 'run_recipe.py <batch dir> [--from N] [--to 12] [--print] [--check-only N]')[0])
    c = json.load(open(os.path.join(b, 'recipe.json')))
    for k in ('stage5', 'topic', 'unit', 'level', 'roster', 'codes', 'saved_root'):
        if k not in c: raise SystemExit(f'recipe.json needs "{k}"')
    try:
        if opt('--check-only') is not None:
            print(check(int(opt('--check-only')), c, b)); return 0
        dry = '--print' in sys.argv
        for n in range(int(opt('--from', '0')), int(opt('--to', '12')) + 1):
            run_step(n, c, b, dry)
        if not dry: preview(b)
        return 0
    except Stop as s:
        print(('STOP: ' if s.code == AGENT else 'FAILED: ') + str(s))
        return s.code


if __name__ == '__main__':
    sys.exit(main())
