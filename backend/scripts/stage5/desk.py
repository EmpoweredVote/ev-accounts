"""The desk's start-up and close-out, each as ONE command. Read-only apart from what the desk already did by hand.

  python3 -I scripts/stage5/desk.py start --profile <topic-profile.json> [--queue <STATE-QUEUE-<topic>.md>] [--state xx]
  python3 -I scripts/stage5/desk.py close --profile <topic-profile.json> --state xx [--batch xx-01] [--session <desk .jsonl>] [--release]

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

USAGE = 'desk.py start --profile <json> [--queue <md>] [--state xx] | close --profile <json> --state xx [--batch xx-01] [--session <jsonl>] [--release]'
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
    elif cmd == 'close': close()
    else: raise SystemExit('usage: ' + USAGE)
