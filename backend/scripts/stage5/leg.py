"""Run one Stage 5 session leg (A set-up, B run) as a SLIM Opus session, started and resumed by a small desk session
(three-state review 2026-11-13, change 1; runner's decision 2026-11-13: slim for both legs).

usage: python3 -I scripts/stage5/leg.py A|B --profile <topic-profile.json> --state xx --state-name <Name>
                                        [--answer <file>] [--worktree <dir>] [--cap N] [--print]
       python3 -I scripts/stage5/leg.py sessions --profile <topic-profile.json> --state xx
       python3 -I scripts/stage5/leg.py log "<one line>"        (run by the slim session itself)

Why: a desktop session starts at 110,000 to 126,000 tokens and re-reads all of it on every step; that was 38% to 45%
of a state's cost. A slim session (`claude -p --safe-mode`) with the same tools starts at about 7,000 tokens, 13,000
with its card (measured 2026-11-13). Same model, same card, same rules.

A leg's prompt is its session card (session_card.py) followed by templates/stage5-slim-rules.md. The leg runs until it
needs the runner, then ends with one last line, which this tool turns into its exit code:

  DONE <leg>                 exit 0
  STOP question <file>       exit 10   show the runner the file; resume with --answer <file holding their words>
  STOP write <PREVIEW.md>    exit 11   the desk shows the preview and runs the write on the runner's yes
  STOP blocked <why>         exit 12
  STOP handover <file>       (never reaches the desk: this tool starts the next session of the leg itself)
  (anything else)            exit 2    the reply is in <desk>/leg-<leg>.out.txt

--answer resumes the SAME session (`claude --resume`), so the leg keeps what it knows; the file's text is its first
message. The session id and every run are kept in <stage5>/<xx>/desk/leg-<leg>.json.
`sessions` prints `--session <transcript>` for every session of every leg on file, for close_state.py.

The size cap (2026-11-14). A slim session starts small but nothing clears it, so every step re-reads all the steps
before it: Tennessee's leg A grew from 14,000 to 322,000 tokens over 159 steps, leg B to 233,000 over 152. So a leg
is now a CHAIN of sessions. The session adds each log line with `leg.py log`, which answers with the session's size
(read from its own transcript). Past the cap it writes `<desk>/CONTINUE-<leg>-<n>.md` and ends with `STOP handover
<file>`; this tool then starts a fresh session with the card, the rules and that file, and the desk never wakes.
An `--answer` goes to a fresh session too when the stopped one is past the cap and left a CONTINUE file.
`--cap N` sets the cap in tokens (default: the profile's "slim_cap", else 100,000; 0 turns it off). Replayed over
Tennessee's two legs, a cap of 100,000 costs 43% to 45% less than the sessions as they ran. A hand-over inside
MIN_TURNS steps of a session's start means the cap is too low for the card: the leg stops as blocked.

🔴 A slim session is unattended: nothing asks before a command runs. Every leg is started with STAGE5_NO_DB_WRITE=1,
which makes the Stage 5 write tools refuse (scripts/lib/noWriteGuard.ts). The write and the approval are run by the
desk session, on the runner's yes. That guard covers those tools only; see noWriteGuard.ts.
"""
import datetime, glob, json, os, re, subprocess, sys, uuid
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, positional
from session_card import load_profile
import stage5_usage as U

USAGE = 'leg.py A|B --profile <json> --state xx --state-name <Name> [--answer <file>] [--worktree <dir>] [--cap N] [--print]   |   leg.py sessions --profile <json> --state xx   |   leg.py log "<line>"'
HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = 'Bash,Read,Write,Edit,WebFetch,WebSearch'
LAST = re.compile(r'^(DONE [AB]|STOP (question|write|approve|blocked|handover) .+)$')
CODES = {'DONE': 0, 'question': 10, 'write': 11, 'approve': 11, 'blocked': 12, 'handover': 13}
ROOTS = ['~/.claude/projects', '~/.claude-ev/projects']
CAP, MIN_TURNS, MAX_HANDOVERS = 100000, 8, 12


def context(path):
    """Tokens the session's latest step read: the size every further step pays for. None when the transcript has no step."""
    size = None
    for line in open(path, errors='replace'):
        if '"usage"' not in line: continue
        try: o = json.loads(line)
        except ValueError: continue
        u = (o.get('message') or {}).get('usage') if o.get('type') == 'assistant' else None
        if u: size = (u.get('input_tokens') or 0) + (u.get('cache_read_input_tokens') or 0) + (u.get('cache_creation_input_tokens') or 0)
    return size


def size_of(sid):
    p = U.find_session(sid, ROOTS) if sid else None
    return context(p) if p else None


def log_line():
    """`leg.py log <line>`: add the line to the leg's log and say how large the session is. Run by the slim session."""
    log, sid, cap = os.environ.get('STAGE5_LEG_LOG'), os.environ.get('STAGE5_LEG_SESSION'), int(os.environ.get('STAGE5_LEG_CAP') or 0)
    if not log: raise SystemExit('leg.py log: not inside a slim leg (STAGE5_LEG_LOG is not set). Add the line to the log file yourself.')
    text = ' '.join(sys.argv[2:]).strip() or sys.stdin.read().strip()
    if not text: raise SystemExit('leg.py log: no line given')
    with open(log, 'a') as fh: fh.write((text if text.startswith(('- ', '#')) else f'- {text}') + '\n')
    size = size_of(sid)
    if size is None: print('logged. Session size unknown (no transcript found): carry on.')
    elif not cap or size < cap: print(f'logged. Session size {size:,}' + (f' of {cap:,}' if cap else '') + ' tokens: carry on.')
    else: print(f'logged. 🔴 Session size {size:,} of {cap:,} tokens: HAND OVER NOW (the slim rules, "When the session is large").')
    return 0


def last_line(text):
    """(exit code, line) from a leg's reply: the last non-empty line must be one of the lines the rules list."""
    lines = [l.strip().strip('`') for l in (text or '').strip().splitlines() if l.strip().strip('`')]
    m = LAST.match(lines[-1]) if lines else None
    if not m: return 2, lines[-1][:200] if lines else '(empty reply)'
    return CODES['DONE' if m.group(1).startswith('DONE') else m.group(2)], lines[-1]


def main():
    if len(sys.argv) > 1 and sys.argv[1] == 'log': return log_line()
    leg = positional(1, USAGE)[0]
    prof = load_profile(os.path.abspath(opt('--profile', required=True, usage=USAGE)))
    xx = opt('--state', required=True, usage=USAGE).lower(); S = prof['stage5'].rstrip('/'); desk = f'{S}/{xx}/desk'
    if leg == 'sessions':
        out = []
        for L in 'AB':
            f = f'{desk}/leg-{L}.json'
            if not os.path.exists(f): continue
            st = json.load(open(f))
            for sid in st.get('sessions') or [st['session_id']]:
                p = U.find_session(sid, ROOTS)
                if not p: raise SystemExit(f'leg {L}: no transcript on this machine for session {sid}')
                out += ['--session', p]
        if not out: raise SystemExit(f'no leg on file in {desk}')
        print(' '.join(out)); return 0
    leg = leg.upper()
    if leg not in ('A', 'B'): raise SystemExit(USAGE)
    wt = os.path.abspath(opt('--worktree') or os.path.join(HERE, '..', '..', '..'))
    state_file = f'{desk}/leg-{leg}.json'; state = json.load(open(state_file)) if os.path.exists(state_file) else None
    answer = opt('--answer'); cap = int(opt('--cap') or prof.get('slim_cap') or CAP); card = f'{S}/{xx}/CARD-{leg}.md'
    if cap < 0: raise SystemExit('--cap is a number of tokens (0 turns the cap off)')
    base = ['--model', 'opus', '--output-format', 'json', '--tools', TOOLS, '--allowedTools', TOOLS, '--permission-mode', 'acceptEdits',
            '--strict-mcp-config', '--safe-mode', '--disable-slash-commands',
            '--add-dir', os.path.dirname(prof['research'].rstrip('/')), '--add-dir', wt]

    def opening():
        rules = open(os.path.join(wt, '.claude', 'skills', 'season-topic-prep', 'templates', 'stage5-slim-rules.md')).read()
        for k, v in {'DESK': desk, 'LEG': leg, 'S': S, 'xx': xx, 'CAP': f'{cap:,}' if cap else 'no cap'}.items(): rules = rules.replace('{{' + k + '}}', v)
        if '{{' in rules: raise SystemExit('unfilled slot in stage5-slim-rules.md. Nothing started.')
        return open(card).read() + rules

    def carry_on(file):
        return (f'\n\n# You are continuing this leg\n\nAn earlier session ran part of this card and handed over because it had grown large. Read `{file}` '
                f'first, then `{desk}/LOG-{leg}.md`. Start at the step the hand-over names. Do not repeat a finished step, and do not read again what '
                'the hand-over already tells you.\n')

    def fresh(prompt):
        sid = str(uuid.uuid4()); return ['claude', '-p', prompt, '--session-id', sid] + base, sid

    said = lambda text: f"The runner's answer, word for word:\n\n{text}\n\nCarry on from where you stopped. End with one of the lines the rules list."
    if answer:
        if not state: raise SystemExit(f'--answer: leg {leg} has not been started for {xx} ({state_file} is missing)')
        text = open(answer).read().strip()
        if not text: raise SystemExit(f'{answer} is empty: write the runner\'s words in it')
        # a stopped session past the cap that left a hand-over is not resumed: the answer goes to a fresh one
        notes = [f for f in glob.glob(f'{desk}/CONTINUE-{leg}-*.md') if os.path.getsize(f)]
        note = max(notes, key=os.path.getmtime) if notes else None
        begun = datetime.datetime.fromisoformat(state['runs'][-1]['started']).timestamp() if state.get('runs') else 0
        size = size_of(state['session_id']) if cap and note and os.path.getmtime(note) >= begun else None
        if size is not None and size >= cap: cmd, sid = fresh(opening() + carry_on(note) + '\n' + said(text))
        else: cmd, sid = ['claude', '-p', said(text), '--resume', state['session_id']] + base, state['session_id']
    else:
        if state and state.get('last', '').startswith('DONE'): raise SystemExit(f'leg {leg} is already DONE for {xx} ({state_file}). Remove that file to run it again.')
        if state: raise SystemExit(f'leg {leg} was already started for {xx} and stopped with "{state.get("last")}". Resume it with --answer <file>.')
        os.makedirs(desk, exist_ok=True)
        name = opt('--state-name', required=True, usage=USAGE)
        r = subprocess.run([sys.executable, '-I', os.path.join(HERE, 'session_card.py'), leg, '--profile', os.path.abspath(opt('--profile')), '--state', xx,
                            '--state-name', name, '--worktree', wt, '--out', card], capture_output=True, text=True)
        if r.returncode: raise SystemExit(f'session_card.py failed: {(r.stderr or r.stdout).strip()[-400:]}')
        cmd, sid = fresh(opening())
    if '--print' in sys.argv:
        print(' '.join(c if len(c) < 200 else f'<{len(c):,} characters: the card and the slim rules>' for c in cmd)); return 0
    handovers = 0
    while True:
        env = dict(os.environ, STAGE5_NO_DB_WRITE='1', STAGE5_LEG_SESSION=sid, STAGE5_LEG_CAP=str(cap), STAGE5_LEG_LOG=f'{desk}/LOG-{leg}.md')
        started = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds')
        p = subprocess.run(cmd, cwd=os.path.join(wt, 'backend'), capture_output=True, text=True, env=env)
        try: res = json.loads(p.stdout)
        except ValueError: res = {}
        reply = res.get('result') or ''
        open(f'{desk}/leg-{leg}.out.txt', 'w').write(reply or (p.stdout + p.stderr))
        ran = res.get('session_id')
        code, line = last_line(reply) if p.returncode == 0 and ran else (2, f'the session did not run (exit {p.returncode}): see {desk}/leg-{leg}.out.txt')
        note = line.split(' ', 2)[2].strip() if code == 13 else None
        if code == 13:
            if not (os.path.exists(note) and os.path.getsize(note)): code, line = 2, f'the session handed over, but {note} is missing or empty'
            elif handovers >= MAX_HANDOVERS or (res.get('num_turns') or MIN_TURNS) < MIN_TURNS:
                code, line = 12, (f'STOP blocked the leg handed over again after {res.get("num_turns")} steps ({handovers + 1} hand-overs this run): the cap of '
                                  f'{cap:,} is too low for this card, or the session cannot shrink. Read {note}')
        if ran:
            ids = (state or {}).get('sessions') or ([state['session_id']] if state else [])
            runs = (state or {}).get('runs', []) + [{'started': started, 'ended': datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'),
                                                     'answer': answer, 'last': line, 'turns': res.get('num_turns'), 'session': ran}]
            state = {'leg': leg, 'state': xx, 'session_id': ran, 'sessions': ids + [ran] * (ran not in ids), 'last': line, 'runs': runs}
            json.dump(state, open(state_file, 'w'), indent=1)
        if code != 13: break
        handovers += 1; answer = None; cmd, sid = fresh(opening() + carry_on(note))
    print(line); return code


if __name__ == '__main__':
    sys.exit(main())
