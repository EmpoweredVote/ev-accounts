"""The desk's start-up and close-out, each as ONE command. Read-only apart from what the desk already did by hand.

  python3 -I scripts/stage5/desk.py start --profile <topic-profile.json> [--queue <STATE-QUEUE-<topic>.md>] [--state xx]
  python3 -I scripts/stage5/desk.py write --profile <topic-profile.json> --state xx [--batch xx-01] (--standing | --yes "<runner's words>")
                                          [--approve | --approve-yes "<runner's words>"] [--editor-id <uuid>] [--print]
  python3 -I scripts/stage5/desk.py close --profile <topic-profile.json> --state xx [--batch xx-01] [--session <desk .jsonl>] [--release]
  python3 -I scripts/stage5/desk.py slim  --profile <topic-profile.json> --queue <STATE-QUEUE-<topic>.md> --next <NEXT.md> [--name <worktree name>]

Why (2026-11-19): the desk is the one session left in the desktop app. It starts at about 135,000 tokens before it
reads a word and re-reads all of that on every step: Kansas's desk took 63 steps and cost 0.97M units, of which
about 0.85M was that re-reading (Maryland 1.13M, Colorado 0.98M: 8 to 13% of a state). About ten of those steps
were the start-up and ten the close-out, each a small command the hand-off lists. One command each is one step each.

start   does, in order, and prints one short report:
  1. fetches, and fast-forwards this worktree to origin/master when it is behind and clean (never a merge);
  2. links backend/.env to the main checkout's when it is missing (never reads it) and runs `npm ci` when
     backend/node_modules is missing;
  3. runs the tracker (progress.ts) and picks the state: --state, or the first row of --queue not marked 🛑 that the
     tracker shows as `not started` or `part`. A state shown `to approve` comes first: stop and tell the runner;
  4. decides the step from what is on disk and on origin/master: a lease someone holds (stop), no reader yet
     (reader session), or the desk;
  5. for the desk only: takes the steward lease (`--if-held fail`, never a takeover) and makes the desk card.
  Exit 0: desk, card made, the last line names it. Exit 3: this is a reader session, the last line says so.
  Exit 2: stop and tell the runner what the report says. It never asks which state, and never takes a held lease.

write   the write stop, as one command (2026-11-21: 18 to 24 desk steps and 0.37M to 0.52M units in four states, most of
  them the desk finding the commands, the editor id and the file names again). 🔴 It writes the database, so it needs
  the runner's yes and says which one it is acting on:
    --yes "<words>"   the runner's own answer to this batch's preview, word for word; or
    --standing        the runner's own message gave a standing yes for this state. Then `standing_yes.py write` must
                      hold (it wants the desk's own `desk-check.json`); if it does not, nothing is written (exit 4).
  It runs write-batch.sh apply, the verifier with --apply, and the read-back, and then checks the read-back against
  what the write wrote (`standing_yes.py approve`'s conditions, whichever yes it has). It adds the WRITTEN lines to
  PREVIEW.md. With --approve (under --standing) or --approve-yes "<words>" (the runner's separate yes to approve) it
  goes on, only when that check holds: approve-batch.ts, the read-back again, and the APPROVED line.
  The editor id is --editor-id, or the profile's "editor_id". --print shows the commands and runs nothing.
  Exit 0: done as far as asked. Exit 4: a condition does not hold; each is printed; ask the runner. Exit 2: a
  command failed, or no yes was given. It refuses in a slim session (STAGE5_NO_DB_WRITE), as every write tool does.

slim    prints the two commands that start the desk in a TERMINAL instead of the desktop app: a fresh worktree, then a
  slim interactive session (no connectors, no skills, the five tools the desk uses). A desktop session starts at about
  135,000 tokens and the desk re-reads them on each of its 60 to 79 steps (about 1.5M units a state, eight states); a
  slim one starts at 6,470 (measured). It starts nothing itself: the runner runs the commands, and answers in that terminal.

close   after leg B ended `DONE B`: runs close_state.py with every leg's transcripts and this desk's own, then
  gathers what the final report needs into `<stage5>/<xx>/desk/DESK-REPORT.md` and prints it: the written counts,
  every question and the runner's answer, each line a leg logged as off its card, the record script's line, the
  step 9 repair, the desk check, the measures, anything still marked `__`, the commits not on origin/master, and the
  tracker's first lines. --release gives the lease back as the last act. It opens no pull request and writes
  nothing to the database: those stay the desk's own acts, on the runner's word.
  Exit 0: report written. Exit 2: leg B has not ended, or close_state.py failed (its output is shown).
"""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt
import glob, json, re, subprocess

USAGE = ('desk.py start --profile <json> [--queue <md>] [--state xx] | write --profile <json> --state xx (--standing | --yes "<words>") [--approve | --approve-yes "<words>"] '
         '| close --profile <json> --state xx [--batch xx-01] [--session <jsonl>] [--release] | slim --profile <json> --queue <md> --next <NEXT.md>')
HERE = os.path.dirname(os.path.abspath(__file__))
BACKEND = os.path.dirname(os.path.dirname(HERE))
ROOT = os.path.dirname(BACKEND)
OPEN = ('not started', 'part')


def sh(cmd, cwd=BACKEND, env=None):
    p = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True, env={**os.environ, **(env or {})})
    return p.returncode, (p.stdout + p.stderr).strip()


def read(path): return open(path).read() if os.path.exists(path) else ''


def tracker_status(text):
    """{'KS': 'done', ...} from progress.ts's table. Empty when the tracker gave no table (no verdict)."""
    out = {}
    for line in text.splitlines():
        c = [x.strip() for x in line.split('|')]
        if len(c) > 3 and re.fullmatch(r'[A-Z]{2}', c[1]) and c[2] in ('done', 'to approve', 'part', 'not started', 'no roster'): out[c[1]] = c[2]
    return out


def queue_rows(text):
    """[(order, State, xx, stopped)] from the queue's table, in its order. A row whose first cell is 🛑 is stopped."""
    rows = []
    for line in text.splitlines():
        c = [x.strip() for x in line.split('|')]
        if len(c) > 4 and re.fullmatch(r'[a-z]{2}', c[3]) and (c[1].isdigit() or '🛑' in c[1]): rows.append((c[1], c[2], c[3], '🛑' in c[1]))
    return rows


def pick_state(rows, status):
    """(state row or None, why). The runner orders the queue; a session never does."""
    waiting = [xx for xx, s in status.items() if s == 'to approve']
    if waiting: return None, f"{', '.join(sorted(waiting))} is written and waits for approval: tell the runner, and start nothing"
    for r in rows:
        if not r[3] and status.get(r[2].upper()) in OPEN: return r, f'tracker: {r[2].upper()} {status[r[2].upper()]}; first open row of the queue'
    left = [f'{r[1]} ({r[0]})' for r in rows if r[3] and status.get(r[2].upper()) in OPEN]
    return None, 'no open state in the queue is free to start' + (f": {', '.join(left)} each wait on the runner (see the queue file)" if left else '')


def decide_step(f):
    """'desk' | 'reader' | 'stop', and why. f: lease (the holder's line or ''), legiscan (LegiScan folders on disk),
    openstates (Open States folders on disk), profile, proved, reader (the three marks of a merged, proved reader)."""
    if f['lease']: return 'stop', f"someone holds the lease: {f['lease']}. Tell the runner; do not take the next state instead"
    if f['legiscan'] and not f['openstates']: return 'desk', 'LegiScan data on disk'
    missing = [n for n, ok in (('legislature profile on origin/master', f['profile']), ('READER-PROVED.md', f['proved']), ('its reader in stateRollCallEvidence.ts', f['reader'])) if not ok]
    if missing: return 'reader', 'no reader yet: missing ' + ', '.join(missing)
    return 'desk', 'reader merged and proved' + ('' if f['openstates'] else '; no data folders linked yet (leg A converts)')


def start():
    prof = json.load(open(opt('--profile', required=True, usage=USAGE))); S, topic = prof['stage5'], prof['topic_key']
    L, stop = [], lambda why: (print('\n'.join(L + [f'STOP: {why}'])), sys.exit(2))
    rc, _ = sh('git fetch -q origin', ROOT)
    if rc: stop('git fetch failed')
    behind, dirty = int(sh('git rev-list --count HEAD..origin/master', ROOT)[1] or 0), bool(sh('git status --porcelain', ROOT)[1])
    if behind and not dirty:
        rc, out = sh('git merge --ff-only -q origin/master', ROOT)
        L.append(f'git: was {behind} behind origin/master; ' + ('fast-forwarded' if not rc else f'NOT fast-forwarded ({out[-120:]})'))
    else: L.append(f"git: {behind} behind origin/master{', uncommitted changes here (a desk starts in a fresh worktree)' if dirty else ''}")
    env = os.path.join(BACKEND, '.env')
    if not os.path.lexists(env):
        main = sh('git worktree list --porcelain', ROOT)[1].split('\n')[0].replace('worktree ', '')
        src = os.path.join(main, 'backend', '.env')
        if not os.path.exists(src): stop(f'no backend/.env here and none in the main checkout ({main})')
        os.symlink(src, env); L.append('.env: linked to the main checkout (not read)')
    if not os.path.isdir(os.path.join(BACKEND, 'node_modules')):
        rc, out = sh('npm ci --silent')
        if rc: stop(f'npm ci failed: {out[-300:]}')
        L.append('node_modules: installed (npm ci)')
    need = [f for f in ('scripts/stage5/standing_yes.py', 'scripts/stage5/progress.ts', 'scripts/stage5/leg.py') if not os.path.exists(os.path.join(BACKEND, f))]
    if need: stop(f"this checkout lacks {', '.join(need)}")
    rc, out = sh(f'npx tsx --env-file=.env scripts/stage5/progress.ts --topic {topic} --roster {S}/roster.tsv --batches {S}/batches --ds {S}/legiscan/ds --out {S}/PROGRESS.md', env={'ADMIN_INGEST_TOKEN': 'placeholder'})
    status = tracker_status(out)
    if rc or not status: stop(f'the tracker gave no table (exit {rc}): {out[-300:]}')
    L.append(next((l for l in out.splitlines() if l.startswith('**')), 'tracker: no summary line'))
    xx, qfile = (opt('--state') or '').lower(), opt('--queue')
    rows = queue_rows(read(qfile)) if qfile else []
    if xx: row, why = next((r for r in rows if r[2] == xx), ('', '', xx, False)), f'named by --state; tracker: {status.get(xx.upper(), "not on the roster")}'
    else:
        if not rows: stop(f'no queue to read ({qfile or "--queue not given"}): the topic is not set up for this flow, or name the state with --state')
        row, why = pick_state(rows, status)
        if not row: stop(why)
    xx = row[2]; XX = xx.upper()
    pf = os.path.join(BACKEND, 'data', 'legislatures', f'{xx}.json')
    name = row[1] or (json.load(open(pf)).get('name') if os.path.exists(pf) else '') or XX
    ds = glob.glob(f'{S}/legiscan/ds/{XX}-*')
    who = sh('npm run steward --silent -- who')[1]
    f = {'lease': next((' '.join(l.split()) for l in who.splitlines() if re.search(rf'\bstate:{xx}\b', l)), ''),
         'openstates': any(os.path.exists(os.path.join(d, '.openstates.json')) for d in ds), 'legiscan': any(not os.path.exists(os.path.join(d, '.openstates.json')) for d in ds),
         'profile': not sh(f'git cat-file -e origin/master:backend/data/legislatures/{xx}.json', ROOT)[0], 'proved': os.path.exists(f'{S}/{xx}/READER-PROVED.md'),
         'reader': name in read(os.path.join(BACKEND, 'src', 'lib', 'stateRollCallEvidence.ts'))}
    step, because = decide_step(f)
    L.append(f'data on disk: {len(ds)} folder(s) for {XX}' + (' (Open States)' if f['openstates'] else ' (LegiScan)' if f['legiscan'] else ''))
    line = f'Next for {topic}: {name}. Step: {step}. Because: {why}; {because}.'
    if step == 'stop': print('\n'.join(L + [line])); sys.exit(2)
    if step == 'reader': print('\n'.join(L + [line, f'READER SESSION for {name} ({xx}): follow the reader hand-off. No lease taken, no card made.'])); sys.exit(3)
    rc, out = sh(f'npm run steward --silent -- claim state:{xx} --label "{prof["label"]} {name} desk" --if-held fail')
    if rc: stop(f'the lease on state:{xx} was not taken: {out[-300:]}')
    L.append(f'lease: state:{xx} taken')
    rc, out = sh(f'python3 -I scripts/stage5/session_card.py desk --profile {opt("--profile")} --state {xx} --state-name "{name}"')
    if rc: stop(f'session_card.py failed: {out[-300:]}')
    if f['proved']: L.append(f'reader proof: {S}/{xx}/READER-PROVED.md (read it: it is what the reader session proved)')
    print('\n'.join(L + [line, f'DESK for {name} ({xx}): read {S}/{xx}/CARD-DESK.md and follow it. It is all you read.']))


def own_transcript():
    """This desk session's transcript: the newest .jsonl of the project folder Claude Code keeps for this worktree."""
    slug = re.sub(r'[^A-Za-z0-9]', '-', ROOT)
    files = sorted(glob.glob(os.path.expanduser(f'~/.claude/projects/{slug}/*.jsonl')), key=os.path.getmtime)
    return files[-1] if files else ''


def digest(S, xx, batch):
    """The facts the desk's final report needs, as markdown lines. Every part says so when its file is absent."""
    D, B = f'{S}/{xx}/desk', f'{S}/write/{batch}'
    part = lambda title, lines: [f'\n## {title}\n'] + (lines or ['- nothing on file'])
    pv = read(f'{B}/PREVIEW.md'); L = [f'# {xx} · desk report facts ({batch})']
    L += part('Written and approved (the preview, from "WRITTEN" on)', pv[pv.index('WRITTEN'):].splitlines()[:14] if 'WRITTEN' in pv else ['- 🔴 PREVIEW.md has no "WRITTEN" part: was the batch written?'])
    stops = []
    for q in sorted(glob.glob(f'{D}/QUESTION-*.md')):
        a = q.replace('QUESTION-', 'ANSWER-'); first = next((l.strip() for l in read(q).splitlines() if l.strip()), '')
        stops.append(f"- `{os.path.basename(q)}`: {first[:200]} → answer: {(read(a).strip() or 'NO ANSWER FILE')[:200]!r}")
    L += part('Questions and the runner\'s answers', stops)
    off = [f'- {leg}: {l[2:300] if l.startswith("- ") else l[:300]}' for leg in ('A', 'B') for l in read(f'{D}/LOG-{leg}.md').splitlines()
           if re.search(r'NOT ON CARD|unlisted|REFUSED|FAILED|\bSTOP\b', l)]
    L += part('Lines a leg logged as off its card, refused or failed', off)
    rec = [f'- {l.strip()[:300]}' for l in read(f'{S}/{xx}/run/step-1.log').splitlines() if not l.lstrip().startswith('$') and re.search(r'standing check|script code|one reason|bill table|refused', l, re.I)][-6:]
    L += part('Record script (run/step-1.log)', rec)
    late = [f'- {l[2:300]}' for l in read(f'{D}/LOG-B.md').splitlines() if 'affected' in l]
    L += part('Late bills (`affected`)', late)
    for title, f in (('Step 9 repair', f'{B}/step9-repair.json'), ('Desk check', f'{B}/desk-check.json')):
        L += part(title, [f'- `{read(f).strip()[:600]}`'] if os.path.exists(f) else [])
    votes = [f'- {l[2:300]}' for l in read(f'{D}/LOG-B.md').splitlines() if re.search(r'unmapped|no.line|cross-check|\b403\b|\b429\b', l)][-5:]
    L += part('Votes: cross-check, unmapped, no line, blocked pages', votes)
    ms = read(f'{S}/{xx}/MEASURES.md')
    keep = [l for l in ms.splitlines() if re.match(r'\| (People|Weighted|Main-session share|Codings|People searched|Searched people|Control|Script-coded|Standing check|People sent|Gate runs|Runner stops|Elapsed|People held) ', l)]
    L += part('Measures', keep) + part('Measures rows still to fill (`__`)', [l for l in ms.splitlines() if '__' in l and l.startswith('|')] or ['- none'])
    return L


def write():
    """The write stop in one step. See the header: it never writes without one of the runner's two kinds of yes."""
    pfile = opt('--profile', required=True, usage=USAGE); prof = json.load(open(pfile)); S = prof['stage5'].rstrip('/')
    xx = opt('--state', required=True, usage=USAGE).lower(); batch = opt('--batch', f'{xx}-01'); B = f'{S}/write/{batch}'
    yes, standing, dry = opt('--yes'), '--standing' in sys.argv, '--print' in sys.argv
    ayes, approve = opt('--approve-yes'), '--approve' in sys.argv or opt('--approve-yes') is not None
    stop = lambda code, why: (print(f'STOP: {why}'), sys.exit(code))
    if os.environ.get('STAGE5_NO_DB_WRITE') == '1': stop(5, 'REFUSED: desk.py write. STAGE5_NO_DB_WRITE=1: this is a slim leg, which never writes the database.')
    done = read(f'{B}/PREVIEW.md').split('## On yes')[-1]
    written = '## WRITTEN' in done; later = written and ayes is not None and not yes and not standing   # the approval alone, after an earlier write
    if written and 'APPROVED' in done: stop(2, f'{B}/PREVIEW.md says this batch is written and approved. Nothing run.')
    if not later and bool(yes and yes.strip()) == standing: stop(2, 'the write needs the runner\'s yes for this batch, one kind of it: --yes "<their words>", or --standing when their own message gave a standing yes.')
    if '--approve' in sys.argv and not standing: stop(2, '--approve goes with --standing. Without a standing yes the approval needs its own: --approve-yes "<the runner\'s words>".')
    if ayes is not None and not ayes.strip(): stop(2, '--approve-yes is empty: pass the runner\'s words')
    if not os.path.exists(f'{B}/PREVIEW.md') or not os.path.exists(f'{B}/recipe.json'): stop(2, f'{B} has no PREVIEW.md or recipe.json: leg B has not reached the write stop.')
    if written and not later and not dry: stop(2, f'{B}/PREVIEW.md already has a WRITTEN part: this batch was written. To approve it, pass only --approve-yes "<the runner\'s words>".')
    editor = opt('--editor-id') or prof.get('editor_id')
    if not editor or not re.fullmatch(r'[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}', editor): stop(2, 'no editor id: pass --editor-id <uuid>, or set "editor_id" in the topic profile.')
    c = json.load(open(f'{B}/recipe.json'))
    from _onfile import onfile_env
    env = {'ADMIN_INGEST_TOKEN': 'placeholder', **(onfile_env(c['stage5'], c.get('state', '')) if not c.get('legiscan_live') else {})}
    tsx = 'npx tsx --env-file=.env'
    back = lambda n: f"{tsx} scripts/stage5/readback.ts --topic {c['topic']} {B}/pids-write.txt --batch-id {batch} > {B}/readback-{n}.txt 2>&1"
    steps = [('write', f"zsh scripts/stage5/write-batch.sh {c['stage5']} {B} {c['topic']} {c['unit']} apply"),
             ('verify', f"{tsx} scripts/verify-stance-research.ts --dir {B} --season draft --threshold 1 --batch-id {batch} --apply --editor-id {editor} > {B}/verify-apply.txt 2>&1"),
             ('read-back', back(1))]
    more = [('approve', f"{tsx} scripts/stage5/approve-batch.ts {editor} {batch} > {B}/approve.txt 2>&1"), ('read-back again', back(2))]
    check = lambda which: sh(f'python3 -I scripts/stage5/standing_yes.py {which} {B}')
    if later: steps = []
    if dry:
        print('\n'.join([f'on: {"the standing yes" if standing else "the runner said " + repr((yes or ayes).strip())}'] + ([f'standing_yes.py write {B}'] if standing else [])
                        + [cmd for _, cmd in steps] + [f'standing_yes.py approve {B}'] + ([cmd for _, cmd in more] if approve else []))); return
    if standing:
        rc, out = check('write')
        if rc: print(out); stop(4, 'the standing yes does not cover this write. Nothing was written. Show the runner the lines above and ask.')
    pick = lambda pat, text: (re.search(pat, text, re.M).group(0).strip() if re.search(pat, text, re.M) else '?')
    for name, cmd in steps:
        rc, out = sh(cmd, env=env)
        # the writer exits 3 when it lists refused passages or held people beside what it wrote: that is a finished write
        if rc and not (name == 'write' and rc == 3 and 'WROTE' in read(f'{B}/stage5-write-apply.txt')):
            stop(2, f'{name} failed (exit {rc}). {"Nothing" if name == "write" else "The write is"} in the database{"" if name == "write" else ": do not run it again"}. Tail:\n'
                    + (out or read(f"{B}/{'stage5-write-apply.txt' if name == 'write' else 'verify-apply.txt' if name == 'verify' else 'readback-1.txt'}"))[-900:])
    w, v, r1 = read(f'{B}/stage5-write-apply.txt'), read(f'{B}/verify-apply.txt'), read(f'{B}/readback-1.txt')
    rc, cond = check('approve')
    on = 'the runner\'s standing yes' if standing else f'the runner\'s answer at the write stop: "{(yes or "").strip()}"'
    lines = [f'\n## WRITTEN (desk.py write, {sh("date -u +%Y-%m-%d")[1]}, on {on})',
             f"- write-batch.sh apply: {pick(r'^outcomes:.*', w)}; {pick(r'^passages:.*', w)}",
             f"- verify-stance-research --apply: {pick(r'^SUMMARY:.*', v)}",
             '- read-back: ' + ' '.join(l.strip() for l in r1.splitlines() if re.match(r'(outcomes|passages|review) ', l)),
             f"- read-back against the write: {'matches' if not rc else 'DOES NOT MATCH, see below'}"]
    if not later: open(f'{B}/PREVIEW.md', 'a').write('\n'.join(lines) + '\n'); print('\n'.join(lines))
    if rc: print(cond); stop(4, 'the batch is WRITTEN, and the read-back does not match what the write wrote. Not approved. Show the runner the lines above.')
    if not approve:
        print('WRITTEN, not approved. Ask the runner for the separate yes to approve; then run this command again with only --approve-yes "<their words>".'); return
    for name, cmd in more:
        rc, out = sh(cmd, env=env)
        if rc: stop(2, f'{name} failed (exit {rc}). The batch is written; the approval may be part done. Tail:\n' + (out or read(f'{B}/approve.txt'))[-900:])
    a, r2 = read(f'{B}/approve.txt'), read(f'{B}/readback-2.txt')
    lines = [f"- APPROVED (on {'the standing yes' if standing else 'the runner: ' + repr(ayes.strip())}): {pick(r'.*approved \d+.*', a)}",
             '- read-back again: ' + ' '.join(l.strip() for l in r2.splitlines() if re.match(r'(outcomes|passages|review) ', l))]
    open(f'{B}/PREVIEW.md', 'a').write('\n'.join(lines) + '\n'); print('\n'.join(lines))
    print('WRITTEN and APPROVED. Resume leg B: leg.py B … --say "written and approved"')


def slim():
    """Print the commands for a desk in a terminal. Starts nothing."""
    pfile = os.path.abspath(opt('--profile', required=True, usage=USAGE)); prof = json.load(open(pfile))
    queue, nxt = (os.path.abspath(opt(k, required=True, usage=USAGE)) for k in ('--queue', '--next'))
    for f in (queue, nxt):
        if not os.path.exists(f): raise SystemExit(f'{f} does not exist')
    rc, main = sh('git rev-parse --path-format=absolute --git-common-dir', ROOT)
    if rc: raise SystemExit('not inside a git checkout')
    repo = os.path.dirname(main.strip()); name = opt('--name') or f"desk-{prof['topic_key']}-{sh('date +%m%d-%H%M')[1]}"
    wt = os.path.join(os.path.dirname(repo), '_worktrees', os.path.basename(repo), name)
    tools = 'Bash,Read,Write,Edit,AskUserQuestion'   # a session with these starts at 6,470 tokens (measured 2026-11-21)
    first = (f"You are the desk for Stage 5 of the topic {prof['topic_key']}. Read {nxt} and do what it says. The topic profile is {pfile} "
             f"and the queue is {queue}. This is a terminal session with no pull-request tools: use `gh` when the runner says to open one.")
    print('\n'.join([
        '# The desk, from a terminal (run both lines yourself; answer the desk\'s questions in that terminal):',
        f'git -C {repo} fetch -q origin && git -C {repo} worktree add -b {name} {wt} origin/master',
        f"cd {wt} && claude --model opus --tools {tools} --allowedTools {tools} --permission-mode acceptEdits --strict-mcp-config "
        f"--safe-mode --disable-slash-commands --add-dir {os.path.dirname(prof['research'].rstrip('/'))} {json.dumps(first)}",
        f'# Add your standing yes, or leave to open a pull request, to that first message in your own words if you mean to give them.',
        f'# When the pull request has merged: git -C {repo} worktree remove {wt}']))


def close():
    pfile = opt('--profile', required=True, usage=USAGE); prof = json.load(open(pfile)); S, topic = prof['stage5'], prof['topic_key']
    xx = opt('--state', required=True, usage=USAGE).lower(); batch = opt('--batch', f'{xx}-01'); D = f'{S}/{xx}/desk'
    state = json.load(open(f'{D}/leg-B.json')) if os.path.exists(f'{D}/leg-B.json') else {}
    if 'DONE B' not in read(f'{D}/leg-B.out.txt') and 'DONE B' not in json.dumps(state):
        print(f'STOP: leg B has not ended with "DONE B" ({D}/leg-B.out.txt). Close out after the run, not before.'); sys.exit(2)
    mine = opt('--session') or own_transcript()
    if not mine or not os.path.exists(mine): print('STOP: this desk session\'s transcript was not found; pass --session <.jsonl>'); sys.exit(2)
    rc, legs = sh(f'python3 -I scripts/stage5/leg.py sessions --profile {pfile} --state {xx}')
    if rc: print(f'STOP: leg.py sessions failed: {legs[-300:]}'); sys.exit(2)
    rc, out = sh(f'python3 -I scripts/stage5/close_state.py --profile {pfile} --state {xx} --batch {batch} {legs} --session {mine}')
    if rc: print(f'STOP: close_state.py exit {rc}:\n{out[-1500:]}'); sys.exit(2)
    L = digest(S, xx, batch)
    L += ['\n## This checkout\n', f'- desk transcript counted: `{mine}`',
          '- commits not on origin/master: ' + (sh('git log --oneline origin/master..HEAD', ROOT)[1].replace('\n', '; ') or 'none'),
          '- uncommitted: ' + (sh('git status --porcelain', ROOT)[1].replace('\n', '; ')[:600] or 'none')]
    rc, out = sh(f'npx tsx --env-file=.env scripts/stage5/progress.ts --topic {topic} --roster {S}/roster.tsv --batches {S}/batches --ds {S}/legiscan/ds --out {S}/PROGRESS.md', env={'ADMIN_INGEST_TOKEN': 'placeholder'})
    L += ['\n## Tracker\n'] + ([l for l in out.splitlines() if l.startswith('**') or re.match(rf'\| ({xx.upper()}) \|', l) or re.search(r'\| (to approve|part|not started) \|', l)] or [f'- 🔴 the tracker gave nothing (exit {rc})'])
    if '--release' in sys.argv:
        rc, out = sh(f'npm run steward --silent -- release state:{xx}'); L += ['\n## Lease\n', f"- state:{xx} {'released' if not rc else 'NOT released: ' + out[-200:]}"]
    text = '\n'.join(L) + '\n'
    open(f'{D}/DESK-REPORT.md', 'w').write(text); print(text + f'written to {D}/DESK-REPORT.md')


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'start': start()
    elif cmd == 'write': write()
    elif cmd == 'slim': slim()
    elif cmd == 'close': close()
    else: raise SystemExit('usage: ' + USAGE)
