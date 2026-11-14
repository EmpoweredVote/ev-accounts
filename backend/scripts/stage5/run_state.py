"""Run one state's Stage 5 record pass, search, second pass and early check in order, and stop only where a person is
needed (three-state review 2026-11-13, change 4). It does for session B's steps B1 to B8 what run_recipe.py does for
the write: in three states these were about 60 single commands, each one a full-price step of the main session.

usage: python3 -I scripts/stage5/run_state.py --profile <topic-profile.json> --state xx [--from N] [--to N] [--print]
                                              [--worktree <dir>] [--tools <dir>]
       python3 -I scripts/stage5/run_state.py --profile <topic-profile.json> --state xx --round <name> [--ids <file>] [--why <file>]

Run it in the background from a worktree's `backend/` whose `.env` is linked. It wakes the session once per stop.
Everything about the topic comes from the profile: the topic key, the ladder's sides, whether the record pass by script
is approved, and the skip rule's control groups. A topic with no control groups is refused here: with no skip rule
the flow is "search everyone, then code once" (STAGE5.md sections 3 and 4), which this tool does not run.

  1 record   [script: record-script plan] → coder-inputs --record-only → Opus wave → split-codes → [record-script adopt]
  2 plan     search_list.py plan with the profile's control groups
  3 search   search briefs → Sonnet wave → import from <stage5>/<xx>/find only
  4 recode   search_list.py recode --apply; people to search again get ONE second search (own folder), import, recode
  5 code     coder-inputs on recode-ids.txt → Opus wave → split-codes into codes/
  6 adopt    search_list.py adopt, then search_effect.py over the state's id list
  7 check    early check report → theme prompt → Opus theme pass → report with themes

It stops with the file to read and the `--from` to resume with:
  exit 2   a command failed.
  exit 4   a check a person must rule on: the record script's standing check (step 1), a control that changed
           (step 6: the group is re-opened, see reopened.tsv), or the early check's bar (step 7: runner stop 2).
  exit 10  work for the session: codes sent back by split-codes, or search files the import refused.
Each step's full output is in <stage5>/<xx>/run/step-<n>.log; <stage5>/<xx>/run/log.json records when each step ended.
A step is never skipped because its files exist: `--from` is the only way to resume. Waves skip agents already done.
The state's own search note, if any, is <stage5>/<xx>/search-note.md (added to every search brief).

`--round <name>` codes some people AGAIN, as one command (2026-11-14): a send-back round (no --ids: everyone named in
an unanswered `<batch>.sendback.md` of this state, each with the code check's reasons) or a re-code after a ruling
(--ids <file>, with --why <file> for one or two sentences the coders should know). It builds a brief that holds ONLY
those people (coder-inputs.ts), runs the Opus wave, and splits with --replace. A person with a second-pass code
(search-plan-<xx>/recode-ids.txt) is coded from all their findings into codes/; anyone else from their record into
record-codes/, and into codes/ too when their record code was already adopted there. Each code replaced is kept in
<stage5>/<xx>/codes-before-<name>/. The round's files are in <stage5>/<xx>/rounds/<name>/, away from the steps' own
batches. Why: in Tennessee a send-back coder was pointed at the whole batch's brief and findings to code one person
(three such coders cost 0.89M units), and each round was about six hand-built commands in the main session.
Exit 10 when the round itself sends a code back: run another round, under a new name.
"""
import csv, datetime, glob, json, os, re, shutil, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt
from session_card import load_profile, skip_rungs

USAGE = ('run_state.py --profile <topic-profile.json> --state xx [--from N] [--to N] [--print] [--worktree <dir>] [--tools <dir>]\n'
         '       run_state.py --profile <topic-profile.json> --state xx --round <name> [--ids <file>] [--why <file>] [--print]')
PID = r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'


def sent_back(path):
    """{politician id: [the code check's reasons]} from one <batch>.sendback.md (split-codes.ts)."""
    out, head = {}, None
    for line in open(path).read().splitlines():
        if line.startswith('### '): head = line[4:].strip(); continue
        if not line.startswith('- ') or head is None: continue
        if re.fullmatch(PID, head): out.setdefault(head, []).append(line[2:].strip())
        elif head == 'missing from the file':
            m = re.match(PID, line[2:])
            if m: out.setdefault(m.group(0), []).append('no code was given for this person')
    return out
HERE = os.path.dirname(os.path.abspath(__file__))
NAMES = {1: 'record', 2: 'plan', 3: 'search', 4: 'recode', 5: 'code', 6: 'adopt', 7: 'check'}


class Stop(Exception):
    def __init__(self, code, msg): self.code, self.msg = code, msg


class Run:
    def __init__(self):
        self.path = os.path.abspath(opt('--profile', required=True, usage=USAGE))
        self.prof = load_profile(self.path)
        self.xx = opt('--state', required=True, usage=USAGE).lower()
        if not self.prof['control_groups']:
            raise SystemExit('this topic\'s profile names no control groups, so no skip rule is approved for it: search everyone, '
                             'then code once (STAGE5.md sections 3 and 4). run_state.py runs the record-first flow only.')
        self.S = self.prof['stage5'].rstrip('/'); self.topic = self.prof['topic_key']
        self.wt = os.path.abspath(opt('--worktree') or os.path.join(HERE, '..', '..', '..'))
        self.backend = os.path.join(self.wt, 'backend'); self.tools = os.path.abspath(opt('--tools') or HERE)
        self.dry = '--print' in sys.argv; self.step = 0
        self.dir = f'{self.S}/{self.xx}/run'
        self.py = f'python3 -I {self.tools}'
        self.common = (f'--config {self.S}/coder-config.json --rulings {self.S}/coder-rulings.md --roster {self.S}/roster.tsv '
                       f'--unit state:{self.xx}')
        self.table = f'--bill-table {self.S}/bill-table-{self.xx}.json'
        self.add = f'--add-dir {os.path.dirname(self.prof["research"].rstrip("/"))} --add-dir {self.wt}'

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

    def wave(self, name, jobs=None):
        w = f'{self.S}/waves/{self.xx}-{name}'
        self.sh(f'{self.py}/wave.py {jobs or w + "/jobs.tsv"} --out {w}/out {self.add}')
        return w

    def split(self, coded, briefs, name, codes, then=''):
        """split-codes.ts for every coded batch file; a sent-back code stops the run for the session."""
        files = sorted(glob.glob(f'{briefs}/{name}-*.ids.txt')) if not self.dry else [f'{briefs}/{name}-NN.ids.txt']
        if not files: raise Stop(2, f'no {name}-NN.ids.txt in {briefs}: coder-inputs.ts wrote no batch')
        back = []
        for ids in files:
            b = os.path.basename(ids)[:-len('.ids.txt')]
            rc, out = self.sh(f'npx tsx scripts/stage5/split-codes.ts {coded}/{b}.json --config {self.S}/coder-config.json --codes {codes} --ids {ids}', ok=(0, 1, 3))
            if rc: back.append(b)
        if back:
            raise Stop(10, f'split-codes sent codes back in {", ".join(back)}: read {self.dir}/step-{self.step}.log, then code those people again with '
                           f'`run_state.py --profile {self.path} --state {self.xx} --round sb1` (a coder, never by hand; a new name for each round)'
                           + then + f', then resume with --from {self.step + 1}')

    def ids(self, path): return open(path).read().split() if os.path.exists(path) else []

    # --- the steps -----------------------------------------------------------------------------------------------
    def s1(self):
        S, xx, B = self.S, self.xx, f'{self.S}/record-briefs-{self.xx}'; name = f'{xx}-rec'; who = f'{S}/batches/{xx}-ids.txt'
        if self.prof['record_script']:
            self.sh(f'npx tsx scripts/stage5/record-script.ts plan {self.common} --ids {who} {self.table} --sides {self.prof["sides"]} '
                    f'--skip-rungs {",".join(skip_rungs(self.prof["control_groups"]))} --name {name} --out {B}')
            who = f'{B}/{name}-coder-ids.txt'
        self.sh(f'npx tsx scripts/stage5/coder-inputs.ts {self.common} --ids {who} --name {name} --out {B} --coded-dir {S}/record-coded --record-only {self.table}')
        self.sh(f'{self.py}/stage5_prompts.py coder-jobs --briefs {B} --name {name} --wave {S}/waves/{xx}-rec')
        adopt = f'npx tsx scripts/stage5/record-script.ts adopt --out {B} --name {name} --codes {S}/record-codes'
        # a send-back stops the step before the standing check: the resume must not skip it (found in Tennessee, 2026-11-14)
        self.wave('rec'); self.split(f'{S}/record-coded', B, name, f'{S}/record-codes',
                                     then=f'; then run the standing check yourself, from backend/ (`{adopt}`; exit 4 = it failed, a runner stop)' if self.prof['record_script'] else '')
        if self.prof['record_script']:
            rc, out = self.sh(adopt, ok=(0, 4))
            if rc == 4:
                raise Stop(4, 'the standing check failed: a blind Opus code differs from the script\'s, and no script code was released. Show the '
                              f'runner both codes ({self.dir}/step-1.log). Until the runner rules, code every script person with Opus.')
        return 'record codes in ' + f'{S}/record-codes'

    def s2(self):
        groups = ' '.join(f'--control-group {g.replace(" ", "")}' for g in self.prof['control_groups'])
        _, out = self.sh(f'{self.py}/search_list.py plan --record-codes {self.S}/record-codes --roster {self.S}/batches/{self.xx}-roster.tsv {groups} --out {self.S}/search-plan-{self.xx}')
        return (out.strip().splitlines() or ['planned'])[-1]

    def search(self, ids, rnd):
        S, xx = self.S, self.xx; note = f'{S}/{xx}/search-note.md'; tail = '' if rnd == 1 else f'-{rnd}'
        self.sh(f'{self.py}/stage5_prompts.py search-briefs --profile {self.path} --state {xx} --roster {S}/batches/{xx}-roster.tsv --ids {ids}'
                + (f' --round {rnd}' if rnd > 1 else '') + (f' --note-file {note}' if os.path.exists(note) else '') + f' --worktree {self.wt}')
        self.wave(f'search{tail}')
        _, out = self.sh(f'npm run topic:stage5-find --prefix {self.backend} -- import --topic {self.topic} --season draft --dir {S}/{xx}/find{tail} --roster {S}/roster.tsv')
        refused = re.findall(r'(?im)^.*\brefused\b.*[0-9a-f]{8}-[0-9a-f]{4}-.*$', out)
        if refused:
            raise Stop(10, f'the import refused {len(refused)} search file(s): fix each file or brief the person again, import {S}/{xx}/find{tail} again, '
                           f'then resume with --from 4. First: {refused[0].strip()[:160]}')

    def s3(self): self.search(f'{self.S}/search-plan-{self.xx}/search.tsv', 1); return 'searched and imported'

    def recode(self, wave):
        P = f'{self.S}/search-plan-{self.xx}'
        self.sh(f'{self.py}/search_list.py recode --record-codes {self.S}/record-codes --record-briefs {self.S}/record-briefs-{self.xx} '
                f'--out {P} --wave-dir {self.S}/waves/{self.xx}-{wave}/out --codes {self.S}/codes --apply')
        return P

    def s4(self):
        P = self.recode('search'); again = self.ids(f'{P}/research-again-ids.txt')
        if again and not os.path.isdir(f'{self.S}/{self.xx}/find-2'):
            self.search(f'{P}/research-again-ids.txt', 2); P = self.recode('search-2')
        return f'second pass {len(self.ids(P + "/recode-ids.txt"))}, searched again {len(again)}'

    def s5(self):
        S, xx = self.S, self.xx; who = f'{S}/search-plan-{xx}/recode-ids.txt'
        if not self.dry and not self.ids(who): return 'nobody has a new finding: no second pass'
        self.sh(f'npx tsx scripts/stage5/coder-inputs.ts {self.common} --ids {who} --name {xx} --out {S}/code-briefs --coded-dir {S}/coded {self.table}')
        self.sh(f'{self.py}/stage5_prompts.py coder-jobs --briefs {S}/code-briefs --name {xx} --wave {S}/waves/{xx}-code')
        self.wave('code'); self.split(f'{S}/coded', f'{S}/code-briefs', xx, f'{S}/codes')
        return 'second-pass codes in ' + f'{S}/codes'

    def s6(self):
        S, xx = self.S, self.xx; P = f'{S}/search-plan-{xx}'
        rc, out = self.sh(f'{self.py}/search_list.py adopt --record-codes {S}/record-codes --codes {S}/codes --out {P}', ok=(0, 4))
        self.sh(f'{self.py}/search_effect.py --roster {S}/roster.tsv --unit state:{xx} --ids {S}/batches/{xx}-ids.txt --record-codes {S}/record-codes '
                f'--codes {S}/codes --plan {P} --json {S}/search-effect-{xx}.json')
        if rc == 4:
            raise Stop(4, f'a control person changed: {P}/reopened.tsv lists the skipped people of the group that failed. Search and code them '
                          f'(put their ids in a file and run steps 3 to 5 for them), run `search_list.py adopt` again, and report it. Then --from 7.')
        return (out.strip().splitlines() or ['adopted'])[-1]

    def s7(self):
        S, xx = self.S, self.xx; notes = f'{S}/{xx}/notes-{xx}.jsonl'; themes = f'{S}/{xx}/themes-{xx}.json'; W = f'{S}/waves/{xx}-theme'
        report = (f'npm run topic:stage5-report --prefix {self.backend} -- --topic {self.topic} --research {self.prof["research"].rstrip("/")} '
                  f'--units state:{xx} --notes-out {notes} --out {S}/early-check-{xx}1.md --early')
        rc, _ = self.sh(report, ok=(0, 3, 4))
        if rc == 3: raise Stop(10, f'some codes failed their check: read {self.dir}/step-7.log, send them back to a coder, then --from 7')
        self.sh(f'npm run topic:stage5-theme-prompt --prefix {self.backend} -- --topic {self.topic} --season draft --notes {notes} --out {W}/theme-prompt.md')
        if not self.dry:
            with open(f'{W}/theme-prompt.md', 'a') as fh: fh.write(f'\n\nThe notes are in `{notes}`. Write the result to `{themes}`.\n')
            open(f'{W}/jobs.tsv', 'w').write(f'name\tprompt_file\tmodel\ttools\ntheme-{xx}\t{W}/theme-prompt.md\topus\tRead,Write\n')
        self.wave('theme', f'{W}/jobs.tsv')
        rc, out = self.sh(report + f' --themes {themes}', ok=(0, 4))
        if rc == 4:
            raise Stop(4, f'🛑 runner stop 2: the early check is over its bar. Show the runner the split and the themes ({S}/early-check-{xx}1.md), '
                          'ask one question (fix the rungs first, or carry on), and recommend one answer.')
        return 'early check passed: ' + f'{S}/early-check-{xx}1.md'


    # --- a round: some people coded again ----------------------------------------------------------------------
    def round(self, name, ids_file, why_file):
        S, xx = self.S, self.xx; self.step = f'round-{name}'; R = f'{S}/{xx}/rounds/{name}'; keep = f'{S}/{xx}/codes-before-{name}'
        if not re.fullmatch(r'[a-z0-9]+', name): raise Stop(2, '--round is a short name of letters and digits, e.g. sb1 or r2')
        if os.path.isdir(R) and not self.dry: raise Stop(2, f'round "{name}" was already run for {xx} ({R}): give the next round a new name')
        second = set(self.ids(f'{S}/search-plan-{xx}/recode-ids.txt')); why = {}; files = []; groups = {True: [], False: []}  # True = record-only
        if ids_file:
            for p in dict.fromkeys(self.ids(ids_file)): groups[p not in second].append(p)
        else:
            for rec, pat in ((True, f'{S}/record-coded/{xx}-rec-*.sendback.md'), (False, f'{S}/coded/{xx}-*.sendback.md'),
                             (True, f'{S}/{xx}/rounds/*/coded-rec/*.sendback.md'), (False, f'{S}/{xx}/rounds/*/coded/*.sendback.md')):
                for f in sorted(glob.glob(pat)):
                    files.append(f)
                    for p, reasons in sent_back(f).items():
                        if p not in groups[rec]: groups[rec].append(p)
                        why.setdefault(p, []).extend(reasons)
        if not groups[True] and not groups[False]:
            raise Stop(2, f'nobody to code again: {ids_file} is empty' if ids_file else f'nobody to code again: no unanswered .sendback.md for {xx} (pass --ids for a re-code after a ruling)')
        note = open(why_file).read().strip() if why_file else ''
        t0, back, done = time.time(), [], []
        for rec in (True, False):
            who = groups[rec]
            if not who: continue
            kind = 'rec' if rec else 'code'; n = f'{xx}-{kind}-{name}'; briefs = f'{R}/briefs-{kind}'; coded = f'{R}/coded' + ('-rec' if rec else '')
            codes = f'{S}/record-codes' if rec else f'{S}/codes'; ids = f'{R}/{kind}-ids.txt'
            if not self.dry:
                os.makedirs(briefs, exist_ok=True); open(ids, 'w').write('\n'.join(who) + '\n')
                for d in {codes, f'{S}/codes'}:   # every code this round may replace is kept first
                    for p in who:
                        if os.path.exists(f'{d}/{p}.json'):
                            os.makedirs(f'{keep}/{os.path.basename(d)}', exist_ok=True); shutil.copyfile(f'{d}/{p}.json', f'{keep}/{os.path.basename(d)}/{p}.json')
            self.sh(f'npx tsx scripts/stage5/coder-inputs.ts {self.common} --ids {ids} --name {n} --out {briefs} --coded-dir {coded}'
                    + (' --record-only' if rec else '') + f' {self.table}')
            for b in sorted(glob.glob(f'{briefs}/{n}-*.ids.txt')):
                mine = self.ids(b); lines = [f'- `{p}`: ' + '; '.join(dict.fromkeys(why[p])) for p in mine if why.get(p)]
                with open(b[:-len('.ids.txt')] + '.md', 'a') as fh:
                    fh.write(f'\n\n## This is a second coding round ({name})\n\nCode these people afresh from their findings, by every rule above. '
                             'Do not open any earlier code for them.\n' + (f'\n{note}\n' if note else '')
                             + ('\nThe code check refused an earlier code for these people. Make sure yours does not do the same:\n\n' + '\n'.join(lines) + '\n' if lines else ''))
            self.sh(f'{self.py}/stage5_prompts.py coder-jobs --briefs {briefs} --name {n} --wave {S}/waves/{xx}-{kind}-{name}')
            self.wave(f'{kind}-{name}')
            for b in sorted(glob.glob(f'{briefs}/{n}-*.ids.txt')) if not self.dry else [f'{briefs}/{n}-NN.ids.txt']:
                base = os.path.basename(b)[:-len('.ids.txt')]
                rc, _ = self.sh(f'npx tsx scripts/stage5/split-codes.ts {coded}/{base}.json --config {S}/coder-config.json --codes {codes} --ids {b} --replace', ok=(0, 1, 3))
                if rc: back.append(f'{coded}/{base}.sendback.md')
            for p in who if not self.dry else []:
                new = os.path.exists(f'{codes}/{p}.json') and os.path.getmtime(f'{codes}/{p}.json') >= t0 - 1
                if new: done.append(p)
                if new and rec and os.path.exists(f'{S}/codes/{p}.json'): shutil.copyfile(f'{codes}/{p}.json', f'{S}/codes/{p}.json')   # an adopted record code follows its source
        for f in files if not self.dry else []: os.replace(f, f[:-len('.md')] + '.answered.md')
        said = f'round {name}: {len(groups[True])} record-only, {len(groups[False])} second-pass; {len(done)} coded again'
        if back: raise Stop(10, f'{said}; the round sent codes back ({", ".join(back)}): run another round under a new name')
        return f'{said}, 0 sent back. Codes replaced are kept in {keep}'


def main():
    r = Run(); first, last = int(opt('--from', '1')), int(opt('--to', '7'))
    if opt('--round'):
        if not r.dry: os.makedirs(r.dir, exist_ok=True)
        try: print(r.round(opt('--round'), opt('--ids'), opt('--why'))); return 0
        except Stop as e: print(f'STOP in round {opt("--round")}, exit {e.code}:\n{e.msg}'); return e.code
    if not (1 <= first <= last <= 7): raise SystemExit(USAGE)
    if not r.dry: os.makedirs(r.dir, exist_ok=True); os.makedirs(f'{r.S}/waves/{r.xx}-theme', exist_ok=True)
    log_path = f'{r.dir}/log.json'; log = json.load(open(log_path)) if os.path.exists(log_path) else {}
    for n in range(first, last + 1):
        r.step = n
        if r.dry: print(f'# step {n}: {NAMES[n]}')
        elif os.path.exists(f'{r.dir}/step-{n}.log'): os.replace(f'{r.dir}/step-{n}.log', f'{r.dir}/step-{n}.log.prev')
        try: summary = getattr(r, f's{n}')()
        except Stop as e:
            print(f'STOP at step {n} ({NAMES[n]}), exit {e.code}:\n{e.msg}'); return e.code
        if not r.dry:
            log[str(n)] = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'); json.dump(log, open(log_path, 'w'), indent=1)
            print(f'step {n} {NAMES[n]}: {summary}')
    if not r.dry and last == 7: print('Next: bills the searchers named with no stored bill (card step B7), then the write recipe (run_recipe.py).')
    return 0


if __name__ == '__main__':
    sys.exit(main())
