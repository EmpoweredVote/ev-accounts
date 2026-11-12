"""Run one wave of Stage 5 agents headless (`claude -p`), at most 8 at a time, and wait for all of them.

usage: python3 -I scripts/stage5/wave.py <jobs.tsv> --out <dir> [--max 8] [--full] [--profile <config dir>]
                                         [--add-dir <dir>]... [--print]

<jobs.tsv> has a header and one row per agent:
  name    prompt_file    model    tools
  ga-01   <abs>/code-briefs/ga-01.md   opus   Read,Write
  find-a  <abs>/briefs/a.md            sonnet WebSearch,WebFetch,Read,Write
Each prompt file must be self-contained: it names every file the agent may read and the one file it writes (the
coder brief from coder-inputs.ts is). `tools` limits the agent to those tools (`--tools`), and only those are
allowed without a prompt.

Why (review 2026-11-12): the main session paid for every agent's start and every wake. Run this in the background
from the main session: it wakes once, when the whole wave is done, and reads one summary line per agent instead of
each agent's reply.
Agents start slim by default: `--safe-mode` (no CLAUDE.md, skills, plugins, hooks, MCP servers or custom agents)
and `--disable-slash-commands`. Measured 2026-11-12 in this repo: a headless agent's first turn was 175k tokens
by default and 4.9k slim. `--full` turns this off, for a prompt that relies on CLAUDE.md or a skill (none of the
Stage 5 prompts does). `--profile` sets CLAUDE_CONFIG_DIR instead; a new config folder needs its own `/login` first.
See backend/scripts/stage5/README.md "Slim agents".
Model choice is per row and is never lowered by this tool: coders and every judgment step stay on Opus.

Each agent's JSON result goes to <out>/<name>.result.json (with its session id, turns and token use, which
stage5_usage.py reads), its stderr to <name>.err. A row whose result file already shows success is skipped, so a
wave can be run again after a failure. Exit 0 when every agent succeeded, 1 otherwise, with the failed names.
"""
import concurrent.futures as cf, csv, json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, opts, positional

USAGE = 'wave.py <jobs.tsv> --out <dir> [--max 8] [--full] [--profile <config dir>] [--add-dir <dir>]... [--print]'
MODELS = {'opus': 'claude-opus-5-5', 'sonnet': 'claude-sonnet-5-5', 'haiku': 'claude-haiku-5-5'}
LIMIT = 8


def done(path):
    try: return json.load(open(path)).get('is_error') is False
    except Exception: return False


def command(row, add_dirs, full=False):
    tools = ','.join(t.strip() for t in row['tools'].split(',') if t.strip())
    cmd = ['claude', '-p', open(row['prompt_file']).read(), '--model', MODELS.get(row['model'], row['model']),
           '--output-format', 'json', '--tools', tools, '--allowedTools', tools, '--permission-mode', 'acceptEdits',
           '--strict-mcp-config'] + ([] if full else ['--safe-mode', '--disable-slash-commands'])
    for d in add_dirs: cmd += ['--add-dir', d]
    return cmd


def run(row, out, add_dirs, env, full):
    res, err = os.path.join(out, f"{row['name']}.result.json"), os.path.join(out, f"{row['name']}.err")
    if done(res): return row['name'], 'skipped (already done)', True
    t0 = time.time()
    p = subprocess.run(command(row, add_dirs, full), capture_output=True, text=True, env=env)
    open(res, 'w').write(p.stdout); open(err, 'w').write(p.stderr)
    ok = p.returncode == 0 and done(res)
    try:
        r = json.load(open(res)); line = (r.get('result') or '').strip().splitlines()[-1:] or ['']
        msg = f"{time.time() - t0:5.0f}s turns {r.get('num_turns', '?')}: {line[0][:160]}"
    except Exception:
        msg = f'exit {p.returncode}; no JSON result (see {err})'
    return row['name'], msg, ok


def main():
    jobs = positional(1, USAGE)[0]
    out = opt('--out', required=True, usage=USAGE)
    n = min(int(opt('--max', str(LIMIT))), LIMIT)
    add_dirs = opts('--add-dir')
    rows = list(csv.DictReader(open(jobs), delimiter='\t'))
    for r in rows:
        for k in ('name', 'prompt_file', 'model', 'tools'):
            if not (r.get(k) or '').strip(): raise SystemExit(f'{jobs}: row {r} has no {k}')
        if not os.path.exists(r['prompt_file']): raise SystemExit(f"no prompt file {r['prompt_file']}")
    if len({r['name'] for r in rows}) != len(rows): raise SystemExit('job names must be unique')
    full = '--full' in sys.argv
    env = dict(os.environ)
    if opt('--profile'): env['CLAUDE_CONFIG_DIR'] = os.path.expanduser(opt('--profile'))
    if '--print' in sys.argv:
        for r in rows:
            c = command(r, add_dirs, full); c[2] = f"<{r['prompt_file']}>"; print(r['name'], ' '.join(c))
        return 0
    os.makedirs(out, exist_ok=True)
    print(f'wave: {len(rows)} agent(s), {n} at a time -> {out}', flush=True)
    failed = []
    with cf.ThreadPoolExecutor(n) as ex:
        for name, msg, ok in (f.result() for f in cf.as_completed([ex.submit(run, r, out, add_dirs, env, full) for r in rows])):
            print(f"{'ok  ' if ok else 'FAIL'} {name}: {msg}", flush=True)
            if not ok: failed.append(name)
    print(f'{len(rows) - len(failed)}/{len(rows)} succeeded' + (f"; failed: {' '.join(failed)}" if failed else ''))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
