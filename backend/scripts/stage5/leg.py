"""Run one Stage 5 session leg (A set-up, B run) as a SLIM Opus session, started and resumed by a small desk session
(three-state review 2026-11-13, change 1; runner's decision 2026-11-13: slim for both legs).

usage: python3 -I scripts/stage5/leg.py A|B --profile <topic-profile.json> --state xx --state-name <Name>
                                        [--answer <file>] [--worktree <dir>] [--print]
       python3 -I scripts/stage5/leg.py sessions --profile <topic-profile.json> --state xx

Why: a desktop session starts at 110,000 to 126,000 tokens and re-reads all of it on every step; that was 38% to 45%
of a state's cost. A slim session (`claude -p --safe-mode`) with the same tools starts at about 7,000 tokens, 13,000
with its card (measured 2026-11-13). Same model, same card, same rules.

A leg's prompt is its session card (session_card.py) followed by templates/stage5-slim-rules.md. The leg runs until it
needs the runner, then ends with one last line, which this tool turns into its exit code:

  DONE <leg>                 exit 0
  STOP question <file>       exit 10   show the runner the file; resume with --answer <file holding their words>
  STOP write <PREVIEW.md>    exit 11   the desk shows the preview and runs the write on the runner's yes
  STOP blocked <why>         exit 12
  (anything else)            exit 2    the reply is in <desk>/leg-<leg>.out.txt

--answer resumes the SAME session (`claude --resume`), so the leg keeps what it knows; the file's text is its first
message. The session id and every run are kept in <stage5>/<xx>/desk/leg-<leg>.json.
`sessions` prints `--session <transcript>` for every leg on file, for close_state.py.

🔴 A slim session is unattended: nothing asks before a command runs. Every leg is started with STAGE5_NO_DB_WRITE=1,
which makes the Stage 5 write tools refuse (scripts/lib/noWriteGuard.ts). The write and the approval are run by the
desk session, on the runner's yes. That guard covers those tools only; see noWriteGuard.ts.
"""
import datetime, json, os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, positional
from session_card import load_profile
import stage5_usage as U

USAGE = 'leg.py A|B --profile <json> --state xx --state-name <Name> [--answer <file>] [--worktree <dir>] [--print]   |   leg.py sessions --profile <json> --state xx'
HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = 'Bash,Read,Write,Edit,WebFetch,WebSearch'
LAST = re.compile(r'^(DONE [AB]|STOP (question|write|approve|blocked) .+)$')
CODES = {'DONE': 0, 'question': 10, 'write': 11, 'approve': 11, 'blocked': 12}


def last_line(text):
    """(exit code, line) from a leg's reply: the last non-empty line must be one of the lines the rules list."""
    lines = [l.strip().strip('`') for l in (text or '').strip().splitlines() if l.strip().strip('`')]
    m = LAST.match(lines[-1]) if lines else None
    if not m: return 2, lines[-1][:200] if lines else '(empty reply)'
    return CODES['DONE' if m.group(1).startswith('DONE') else m.group(2)], lines[-1]


def main():
    leg = positional(1, USAGE)[0]
    prof = load_profile(os.path.abspath(opt('--profile', required=True, usage=USAGE)))
    xx = opt('--state', required=True, usage=USAGE).lower(); S = prof['stage5'].rstrip('/'); desk = f'{S}/{xx}/desk'
    if leg == 'sessions':
        out = []
        for L in 'AB':
            f = f'{desk}/leg-{L}.json'
            if not os.path.exists(f): continue
            p = U.find_session(json.load(open(f))['session_id'], ['~/.claude/projects', '~/.claude-ev/projects'])
            if not p: raise SystemExit(f'leg {L}: no transcript on this machine for session {json.load(open(f))["session_id"]}')
            out += ['--session', p]
        if not out: raise SystemExit(f'no leg on file in {desk}')
        print(' '.join(out)); return 0
    leg = leg.upper()
    if leg not in ('A', 'B'): raise SystemExit(USAGE)
    wt = os.path.abspath(opt('--worktree') or os.path.join(HERE, '..', '..', '..'))
    state_file = f'{desk}/leg-{leg}.json'; state = json.load(open(state_file)) if os.path.exists(state_file) else None
    answer = opt('--answer')
    base = ['--model', 'opus', '--output-format', 'json', '--tools', TOOLS, '--allowedTools', TOOLS, '--permission-mode', 'acceptEdits',
            '--strict-mcp-config', '--safe-mode', '--disable-slash-commands',
            '--add-dir', os.path.dirname(prof['research'].rstrip('/')), '--add-dir', wt]
    if answer:
        if not state: raise SystemExit(f'--answer: leg {leg} has not been started for {xx} ({state_file} is missing)')
        text = open(answer).read().strip()
        if not text: raise SystemExit(f'{answer} is empty: write the runner\'s words in it')
        prompt = f"The runner's answer, word for word:\n\n{text}\n\nCarry on from where you stopped. End with one of the lines the rules list."
        cmd = ['claude', '-p', prompt, '--resume', state['session_id']] + base
    else:
        if state and state.get('last', '').startswith('DONE'): raise SystemExit(f'leg {leg} is already DONE for {xx} ({state_file}). Remove that file to run it again.')
        if state: raise SystemExit(f'leg {leg} was already started for {xx} and stopped with "{state.get("last")}". Resume it with --answer <file>.')
        os.makedirs(desk, exist_ok=True); card = f'{S}/{xx}/CARD-{leg}.md'
        name = opt('--state-name', required=True, usage=USAGE)
        r = subprocess.run([sys.executable, '-I', os.path.join(HERE, 'session_card.py'), leg, '--profile', os.path.abspath(opt('--profile')), '--state', xx,
                            '--state-name', name, '--worktree', wt, '--out', card], capture_output=True, text=True)
        if r.returncode: raise SystemExit(f'session_card.py failed: {(r.stderr or r.stdout).strip()[-400:]}')
        rules = open(os.path.join(wt, '.claude', 'skills', 'season-topic-prep', 'templates', 'stage5-slim-rules.md')).read()
        for k, v in {'DESK': desk, 'LEG': leg, 'S': S, 'xx': xx}.items(): rules = rules.replace('{{' + k + '}}', v)
        if '{{' in rules: raise SystemExit('unfilled slot in stage5-slim-rules.md. Nothing started.')
        prompt = open(card).read() + rules
        cmd = ['claude', '-p', prompt] + base
    if '--print' in sys.argv:
        print(' '.join(c if len(c) < 200 else f'<{len(c):,} characters: the card and the slim rules>' for c in cmd)); return 0
    env = dict(os.environ, STAGE5_NO_DB_WRITE='1')
    started = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds')
    p = subprocess.run(cmd, cwd=os.path.join(wt, 'backend'), capture_output=True, text=True, env=env)
    try: res = json.loads(p.stdout)
    except ValueError: res = {}
    reply = res.get('result') or ''
    open(f'{desk}/leg-{leg}.out.txt', 'w').write(reply or (p.stdout + p.stderr))
    sid = res.get('session_id') or (state or {}).get('session_id')
    code, line = last_line(reply) if p.returncode == 0 and sid else (2, f'the session did not run (exit {p.returncode}): see {desk}/leg-{leg}.out.txt')
    if sid:
        runs = (state or {}).get('runs', []) + [{'started': started, 'ended': datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'),
                                                 'answer': answer, 'last': line, 'turns': res.get('num_turns')}]
        json.dump({'leg': leg, 'state': xx, 'session_id': sid, 'last': line, 'runs': runs}, open(state_file, 'w'), indent=1)
    print(line); return code


if __name__ == '__main__':
    sys.exit(main())
