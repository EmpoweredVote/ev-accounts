"""Run one state's Stage 5 SET-UP (session A, steps A1 to A5) in order, and stop only where a person is needed.
It does for session A what run_state.py does for session B's steps and run_recipe.py for the write.

usage: python3 -I scripts/stage5/run_setup.py --profile <topic-profile.json> --state xx [--from N] [--to N] [--print]
                                              [--seats <lower>,<upper>] [--election "<name>"] [--date YYYY-MM-DD]
                                              [--worktree <dir>] [--tools <dir>]

Why (review 2026-11-21, eight states): session A took 132 to 151 steps and 1.36M to 1.77M units in seven of eight
states, whatever the state's size. Each step re-reads the session, and about half of them were the same small
commands every time, found again in the last state's log: 12 to 22 steps a state opened the previous state's scripts
to copy them (the roster check, the triage prompt, the store copy, the table join), and the copies kept what nobody
edited. Each of those is now one shared tool, and this runs them in order. A step is one command of the session.

  1 roster     topic:stage5-roster -> results-scope-data.ts (read-only) -> results_scope.py: scope.tsv, the id list and
               the scoped roster. Hints for the state, when it needs any: <stage5>/<xx>/scope-hints.json.
  2 scan       openstates/coverage.py (when the profile names the extracts) -> scan_bills.py.
               STOPS for the core set, which is picked by hand from contested floor votes: core-bills-<xx>.json.
  3 link       link_check.py --add. STOPS while a member, or a second record of a linked member, has no line. It runs
               BEFORE the sponsor cover: a sponsorship reaches a person only through that line (Nevada: two bills
               never reached the cover; Oregon replayed with the lines in place lists 13 bills' sponsors more fully).
  4 sponsors   sponsor_cover.py --candidates -> the triage prompt (stage5_prompts.py triage) -> one Opus agent ->
               sponsor_cover.py --triage --write. The hand-picked core is kept as <xx>/core-bills-<xx>.hand.json.
  5 texts      bill_skeletons.py -> the state's own text fetch, <stage5>/legiscan/scripts/fetch_texts_<xx>.py.
               STOPS when that script does not exist yet: which version to read is a fact of the legislature.
  6 fill       bill_fill_wave.py -> the Sonnet wave -> check_fill_quotes.py, and its control: one number changed in a
               real quote of a scratch copy must fail. STOPS on a miss, or when the control passes (a blind check).
               Needs <stage5>/legiscan/FILL-BRIEF-<xx>.md (STOPS without it).
  7 store      bill_merge.py -> setup_store.py -> source-store validate -> the pre-fill.
  8 table      stage5_prompts.py bill-table -> the Opus wave -> bill_table.py join, check (and its control: a planted
               wrong deciding phrase must fail), questions. STOPS with the flags to settle and the stop 1 sheet to write.

It stops with what to do and the `--from` to resume with:
  exit 2   a command failed, or a control did not fail when it should have.
  exit 4   the runner's material is ready: settle what the rulings settle, write the stop 1 sheet (step 8).
  exit 10  work for the session: the core set, a link, the text fetch, the fill brief, a quote the text does not hold.
Each step's full output is in <stage5>/<xx>/setup/step-<n>.log; <stage5>/<xx>/setup/log.json records when each ended.
A step is never skipped because its files exist: `--from` is the only way to resume. Waves skip agents already done.

From the profile: the topic key, `since`, "fill_flag" (the fill brief's on-topic key), "triage" (stage5_prompts.py),
and optionally "openstates_extracts" (a path with {xx}) and "topic_list_hash" (else the one hash the topic's stored
records carry). The chambers' sizes are --seats, or "seats": [lower, upper] in the legislature profile.
Everything else about the state comes from its legislature profile. No topic word is written in this file.
"""
import collections, datetime, glob, json, os, re, shutil, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt
from session_card import load_profile
import legislature
from stage5_prompts import STATES

USAGE = ('run_setup.py --profile <topic-profile.json> --state xx [--from N] [--to N] [--print] [--seats <lower>,<upper>] '
         '[--election "<name>"] [--date YYYY-MM-DD] [--worktree <dir>] [--tools <dir>]')
HERE = os.path.dirname(os.path.abspath(__file__))
NAMES = {1: 'roster', 2: 'scan', 3: 'link', 4: 'sponsors', 5: 'texts', 6: 'fill', 7: 'store', 8: 'table'}


class Stop(Exception):
    def __init__(self, code, msg): self.code, self.msg = code, msg


def plant_number(fill_path, texts_dir, out_dir):
    """A scratch copy of one fill with ONE number of a real quote changed, and the texts it is checked against.
    The new number is one the bill prints nowhere, and the number changed stands between words (not a label such as
    "(3)" or "Sec. 4"), so the fault is plain: a check that passes it is blind. Returns (fills dir, texts dir, what
    was changed), or None when no quote of this fill holds such a number."""
    x = json.load(open(fill_path)); lines = (x.get('operative_text') or '').split('\n')
    texts = glob.glob(os.path.join(texts_dir, f"{x['id']}.*.txt"))
    printed = set(re.findall(r'\d+', ' '.join(open(t).read() for t in texts)))
    for i, line in enumerate(lines):
        if len(line.split()) < 12: continue
        for m in list(re.finditer(r'(?<= )(\d{1,3})(?= [a-z])', line))[::-1]:
            if m.start() < len(line) // 3: continue
            new = next((str(int(m.group(1)) + d) for d in (4, 7, 13, 31, 97) if str(int(m.group(1)) + d) not in printed), None)
            if not new: continue
            lines[i] = line[:m.start()] + new + line[m.end():]
            os.makedirs(f'{out_dir}/fill', exist_ok=True); os.makedirs(f'{out_dir}/texts', exist_ok=True)
            json.dump({**x, 'operative_text': '\n'.join(lines)}, open(f"{out_dir}/fill/{x['id']}.json", 'w'))
            for t in texts: shutil.copy(t, f'{out_dir}/texts/')
            return f'{out_dir}/fill', f'{out_dir}/texts', f"{x['id']}: {m.group(1)} -> {new} in \"{line[max(0, m.start() - 40):m.end() + 20].strip()}\""
    return None


class Run:
    def __init__(self):
        self.path = os.path.abspath(opt('--profile', required=True, usage=USAGE)); self.prof = load_profile(self.path)
        self.xx = opt('--state', required=True, usage=USAGE).lower(); self.XX = self.xx.upper()
        self.S = self.prof['stage5'].rstrip('/'); self.R = os.path.dirname(self.S); self.L = f'{self.S}/legiscan'; self.topic = self.prof['topic_key']
        self.wt = os.path.abspath(opt('--worktree') or os.path.join(HERE, '..', '..', '..'))
        self.backend = os.path.join(self.wt, 'backend'); self.tools = os.path.abspath(opt('--tools') or HERE)
        self.dry = '--print' in sys.argv; self.step = 0; self.dir = f'{self.S}/{self.xx}/setup'; self.M = f'{self.S}/{self.xx}'
        self.py = f'python3 -I {self.tools}'; self.date = opt('--date') or datetime.date.today().isoformat()
        self.leg = legislature.load(self.xx, self.wt) or {}
        self.name = self.leg.get('name') or STATES.get(self.XX)
        if not self.name: raise SystemExit(f'no name on file for {self.XX}: start its legislature profile (legislature.py new {self.xx} --name "<Name>")')
        self.add = f'--add-dir {os.path.dirname(self.prof["research"].rstrip("/"))} --add-dir {self.wt}'
        self.roster = f'{self.S}/batches/{self.xx}-roster.tsv'; self.ids = f'{self.S}/batches/{self.xx}-ids.txt'
        self.cover = (f'{self.py}/sponsor_cover.py {self.L}/bills-{self.xx}.json --state {self.XX} --roster {self.roster} --core {self.L}/core-bills-{self.xx}.json '
                      f'--ds {self.L}/ds --idmap {self.L}/idmap.tsv --since {self.prof.get("since") or ""} --candidates {self.S}/sponsor-candidates-{self.xx}.json')

    def need(self, key, why):
        v = self.prof.get(key)
        if not v: raise Stop(2, f'the topic profile has no "{key}" ({why}). Add it to {self.path}, then resume with --from {self.step}.')
        return v

    def sh(self, cmd, ok=(0,)):
        """Run one command from backend/, add its output to the step's log, and return (exit code, output)."""
        if self.dry: print(cmd); return 0, ''
        p = subprocess.run(cmd, shell=True, cwd=self.backend, capture_output=True, text=True)
        out = p.stdout + p.stderr
        os.makedirs(self.dir, exist_ok=True)
        with open(f'{self.dir}/step-{self.step}.log', 'a') as fh: fh.write(f'$ {cmd}\n{out}\n[exit {p.returncode}]\n\n')
        if p.returncode not in ok:
            raise Stop(2, f'command failed (exit {p.returncode}): {cmd}\n' + '\n'.join(out.strip().splitlines()[-8:]))
        return p.returncode, out

    def wave(self, name):
        w = f'{self.S}/waves/{self.xx}-{name}'
        self.sh(f'{self.py}/wave.py {w}/jobs.tsv --out {w}/out {self.add}')
        return w

    last = staticmethod(lambda out, n=1: ' | '.join(l.strip() for l in out.strip().splitlines()[-n:])[:400])

    # --- the steps -----------------------------------------------------------------------------------------------
    def s1(self):
        S, xx, M = self.S, self.xx, self.M; fresh = f'{M}/roster-{self.date}.tsv'
        if not self.dry: os.makedirs(f'{M}/results', exist_ok=True)
        self.sh(f'npm run topic:stage5-roster --prefix . -- --topic {self.topic} --out {fresh}')
        self.sh(f'npx tsx scripts/stage5/results-scope-data.ts --state {self.XX} --state-name "{self.name}" --roster {fresh} --out {M}/results --year {self.date[:4]}')
        hints = f'{M}/scope-hints.json'; el = opt('--election')
        rc, out = self.sh(f'{self.py}/results_scope.py --state {self.XX} --roster {fresh} --cands {M}/results/db-cands.json --offices {M}/results/db-offices.json '
                          f'--out {M} --batches {S}/batches' + (f' --hints {hints}' if os.path.exists(hints) else '') + (f' --election "{el}"' if el else ''), ok=(0, 1, 2))
        if rc:
            raise Stop(10, f'the results check gave no clean result (exit {rc}): {self.last(out, 3)}\nFix it with {hints} (keys in results_scope.py\'s header) '
                           f'or --election, then resume with --from 1.')
        said = [l for l in out.splitlines() if l.startswith(('NAME-MATCH', 'HAND-MATCH', 'CLOSE', 'DROP'))]
        return f'{self.last(out)}. {len(said)} line(s) to read in {self.dir}/step-1.log (name matches, close races, sitting people dropped): check each name match by hand'

    def s2(self):
        ex = (self.prof.get('openstates_extracts') or '').replace('{xx}', self.xx)
        note = 'no "openstates_extracts" in the profile: coverage.py not run'
        if ex and (self.dry or os.path.isdir(ex)):
            rc, out = self.sh(f'{self.py}/openstates/coverage.py {ex} --since {self.prof.get("since") or ""}', ok=(0, 1))
            note = f'coverage exit {rc}' + (f' (sessions with no roll calls: read {self.dir}/step-2.log)' if rc else '')
        elif ex: note = f'no extract folder at {ex}: coverage.py not run (put that on the stop 1 sheet if this state is read from Open States)'
        rc, out = self.sh(f'{self.py}/scan_bills.py {self.L}/ds {self.XX} {self.L}/bills-{self.xx}.json --topic {self.topic}')
        core = f'{self.L}/core-bills-{self.xx}.json'
        if not self.dry and not os.path.exists(core):
            raise Stop(10, f'{note}; scan: {self.last(out)}\nPick the core set by hand from the contested floor votes in {self.L}/bills-{self.xx}.json and write '
                           f'{core} (Opus decides; STAGE5 §3a). Then resume with --from 3.')
        return f'{note}; scan: {self.last(out)}; core set on file'

    def s4(self):
        S, xx, core = self.S, self.xx, f'{self.L}/core-bills-{self.xx}.json'; hand = f'{self.M}/core-bills-{xx}.hand.json'
        if not self.dry and not os.path.exists(hand): shutil.copyfile(core, hand)   # the hand-picked set, before the sponsored bills join it
        self.sh(self.cover)
        note = f'{self.M}/triage-note.md'
        self.sh(f'{self.py}/stage5_prompts.py triage --profile {self.path} --state {xx} --state-name "{self.name}"' + (f' --note-file {note}' if os.path.exists(note) else ''))
        self.wave('triage')
        tri = f'{S}/sponsor-triage-{xx}.json'
        if not self.dry and not os.path.exists(tri): raise Stop(2, f'the triage agent wrote no {tri}: read {S}/waves/{xx}-triage/out')
        rc, out = self.sh(f'{self.cover} --triage {tri} --write {core}')
        keep = [l.strip() for l in out.splitlines() if re.search(r're-file trim|stub|final core|kept|dropped', l, re.I)][-4:]
        return ' | '.join(keep)[:500] or self.last(out, 2)

    def s3(self):
        none = f'{self.M}/no-legiscan-record.tsv'
        rc, out = self.sh(f'{self.py}/link_check.py --state {self.XX} --roster {self.roster} --ds {self.L}/ds --idmap {self.L}/idmap.tsv --add'
                          + (f' --no-record {none}' if os.path.exists(none) else ''), ok=(0, 1, 2))
        line = next((l for l in out.splitlines() if l.startswith('link check')), self.last(out))
        if rc:
            raise Stop(10, f'{line}\nSomeone has no line, or a linked member has another record with none (exit {rc}): read {self.dir}/step-3.log, add each line to '
                           f'{self.L}/idmap.tsv by hand (name AND chamber), list a member with no record in {none}, then resume with --from 3.')
        added = len(re.findall(r'(?m)^  .*<-  ', out))
        return f'{line}; {added} line(s) added or named: check each on name and chamber'

    def s5(self):
        rc, out = self.sh(f'{self.py}/bill_skeletons.py --stage5 {self.S} --state {self.xx} --topic {self.topic}')
        fetch = f'{self.L}/scripts/fetch_texts_{self.xx}.py'
        if not self.dry and not os.path.exists(fetch):
            raise Stop(10, f'skeletons: {self.last(out)}\nNo text fetch for this state yet. Write {fetch} (the newest fetch_texts_*.py beside it is the model; '
                           f'which version to read, and how new and struck words are marked, are this legislature\'s own), run it, then resume with --from 6.')
        rc2, out2 = self.sh(f'python3 -I {fetch} > {self.M}/fetch-texts.log 2>&1; tail -3 {self.M}/fetch-texts.log')
        return f'skeletons: {self.last(out)}; texts: {self.last(out2, 2)}'

    def s6(self):
        S, xx, L = self.S, self.xx, self.L; flag = self.need('fill_flag', 'the fill brief\'s on-topic key')
        if not self.dry and not os.path.exists(f'{L}/FILL-BRIEF-{xx}.md'):
            raise Stop(10, f'{L}/FILL-BRIEF-{xx}.md is missing. Write it from the newest FILL-BRIEF-*.md (this legislature\'s marks; no other state\'s words), then resume with --from 6.')
        w = f'{S}/waves/{xx}-fill'
        if self.dry or not os.path.exists(f'{w}/jobs.tsv'): self.sh(f'{self.py}/bill_fill_wave.py --stage5 {S} --state {xx}')
        self.wave('fill')
        check = f'{self.py}/check_fill_quotes.py --fills {L}/fill --texts {L}/texts --state {xx} --flag {flag}'
        rc, out = self.sh(check, ok=(0, 1))
        if rc:
            raise Stop(10, f'the fills quote words the saved texts do not hold: {self.last(out)}\nRead the MISS lines in {self.dir}/step-6.log. Fix the text fetch '
                           f'(a mark it should strip) or the fill, never the check. Then resume with --from 6.')
        if self.dry: print('# then: one number changed in a scratch copy of a fill must FAIL check_fill_quotes.py'); return ''
        # the control: a clean result means nothing until the check has been seen to fail on a real fault
        with tempfile.TemporaryDirectory() as tmp:
            planted = None
            for f in sorted(glob.glob(f'{L}/fill/{self.XX}-*.json')):
                if json.load(open(f)).get(flag): planted = plant_number(f, f'{L}/texts', tmp)
                if planted: break
            if not planted: return f'{self.last(out)}; control NOT run: no quote of this state\'s fills holds a number (plant a fault by hand once)'
            rc2, out2 = self.sh(f'{self.py}/check_fill_quotes.py --fills {planted[0]} --texts {planted[1]} --state {xx}', ok=(0, 1))
            if rc2 != 1 or 'MISS' not in out2:
                raise Stop(2, f'the quote check is BLIND: a planted wrong number passed ({planted[2]}). Its clean result on the fills proves nothing. Tell the runner.')
        return f'{self.last(out)}; control: a planted wrong number failed ({planted[2][:120]})'

    def s7(self):
        S, xx = self.S, self.xx; flag = self.need('fill_flag', 'the fill brief\'s on-topic key')
        seats = opt('--seats') or ','.join(str(n) for n in self.leg.get('seats') or [])
        if not re.fullmatch(r'\d+,\d+', seats or ''): raise Stop(2, f'the chambers\' sizes are not on file: pass --seats <lower>,<upper>, or add "seats": [lower, upper] to the legislature profile. Then --from 7.')
        h = self.prof.get('topic_list_hash')
        if not h and not self.dry:
            seen = collections.Counter()
            for f in sorted(glob.glob(os.path.join(self.backend, 'data', 'source-store', 'instruments', 'state-*', '*.json')))[::7][:600]:
                m = re.search(r'"topic_list_hash":\s*"([0-9a-f]{64})"', open(f).read())
                if m: seen[m.group(1)] += 1
            if len(seen) != 1: raise Stop(2, f'{len(seen)} topic-list hashes in the stored records ({dict(seen)}): name this topic\'s as "topic_list_hash" in the profile. Then --from 7.')
            h = next(iter(seen))
        cfg = json.load(open(f'{S}/coder-config.json')) if os.path.exists(f'{S}/coder-config.json') else {}
        rc, out = self.sh(f'{self.py}/bill_merge.py --stage5 {S} --state {xx} --seats {seats} --date {self.date} --flag {flag} --topic-list-hash {h or "<hash>"}'
                          + (f" --season {cfg['season']}" if cfg.get('season') else '') + (f" --codebook {cfg['codebook']}" if cfg.get('codebook') else ''))
        merged = self.last(out, 2)
        rc, out = self.sh(f'{self.py}/setup_store.py --stage5 {S} --state {xx} --date {self.date}')
        stored = self.last(out)
        self.sh('npm run source-store --prefix . -- validate')
        rc, out = self.sh(f'npm run topic:stage5-prefill --prefix . -- --topic {self.topic} --research {self.R} --subjects {S}/subjects.json --units state:{xx}')
        return f'merge: {merged} · {stored} · validate OK · pre-fill: {self.last(out, 2)}'

    def s8(self):
        S, xx = self.S, self.xx; table = f'{S}/bill-table-{xx}.json'; bills = f'{self.M}/billtable-ids.json'
        if not self.dry:
            rep = json.load(open(f'{self.L}/merge-report-{xx}.json')); kept = rep.get('kept')
            if not kept: raise Stop(2, f'{self.L}/merge-report-{xx}.json lists no kept bill: run step 7 first')
            json.dump(sorted(kept), open(bills, 'w'))
        note = f'{self.M}/billtable-note.md'
        self.sh(f'{self.py}/stage5_prompts.py bill-table --profile {self.path} --state {xx} --state-name "{self.name}" --bills {bills} --parts 3'
                + (f' --note-file {note}' if os.path.exists(note) else ''))
        self.wave('billtable')
        parts = sorted(glob.glob(f'{S}/bill-table-{xx}.part[0-9]*.json')) if not self.dry else [f'{S}/bill-table-{xx}.part<k>.json']
        if not parts: raise Stop(2, f'the bill-table wave wrote no part file: read {S}/waves/{xx}-billtable/out')
        self.sh(f'{self.py}/bill_table.py join {table} {" ".join(parts)}' + (' --force' if os.path.exists(table) else ''))
        check = f'{self.py}/bill_table.py check {table} --ids {self.ids}'
        rc, out = self.sh(check, ok=(0, 2)); verdict = self.last(out)
        if self.dry: print('# then: a wrong deciding phrase planted in a scratch copy of the table must FAIL bill_table.py check'); rc2 = 2
        else:
            # the control, as in step 6: plant words that are in no bill, in the first row that has a rung
            t = json.load(open(table)); bid = next((b for b, r in t['bills'].items() if r.get('rung') is not None and (r.get('deciding_words') or '').strip()), None)
            if bid:
                with tempfile.TemporaryDirectory() as tmp:
                    t['bills'][bid]['deciding_words'] = 'a phrase planted by the set-up control that no bill prints'
                    json.dump(t, open(f'{tmp}/t.json', 'w'))
                    rc2, out2 = self.sh(f'{self.py}/bill_table.py check {tmp}/t.json --ids {self.ids}', ok=(0, 2))
                if rc2 != 2: raise Stop(2, f'the bill-table check is BLIND: a planted deciding phrase on {bid} passed. Its verdict proves nothing. Tell the runner.')
        rc3, out3 = self.sh(f'{self.py}/bill_table.py questions {table} --ids {self.ids} --out {S}/bill-questions-{xx}.md')
        said = f'{verdict}; control: a planted deciding phrase failed; questions: {self.last(out3)}'
        if self.dry: return ''
        raise Stop(4 if not rc else 10,
                   said + ('\nThe check lists problems: fix each (a bill people hold findings on that the table leaves out needs a row), then --from 8 is NOT needed: run the check again.' if rc else '')
                   + f'\nNext, by hand (card step A5): settle each flag the rulings in {S}/coder-rulings.md settle (`bill_table.py settle`), put every bill '
                     f'the questions file lists as older than the data on the stop 1 sheet with its people, write {self.M}/STOP1-QUESTIONS.md, then the probes (A5b) and the hand-over (A6).')


def main():
    r = Run(); first, last = int(opt('--from', '1')), int(opt('--to', '8'))
    if not (1 <= first <= last <= 8): raise SystemExit(USAGE)
    if not r.dry: os.makedirs(r.dir, exist_ok=True)
    log_path = f'{r.dir}/log.json'; log = json.load(open(log_path)) if os.path.exists(log_path) else {}
    for n in range(first, last + 1):
        r.step = n
        if r.dry: print(f'# step {n}: {NAMES[n]}')
        elif os.path.exists(f'{r.dir}/step-{n}.log'): os.replace(f'{r.dir}/step-{n}.log', f'{r.dir}/step-{n}.log.prev')
        try: summary = getattr(r, f's{n}')()
        except Stop as e:
            if not r.dry and e.code == 4:
                log[str(n)] = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'); json.dump(log, open(log_path, 'w'), indent=1)
            print(f'STOP at step {n} ({NAMES[n]}), exit {e.code}:\n{e.msg}'); return e.code
        if not r.dry:
            log[str(n)] = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'); json.dump(log, open(log_path, 'w'), indent=1)
            print(f'step {n} {NAMES[n]}: {summary}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
