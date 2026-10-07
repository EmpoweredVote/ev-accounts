"""Build shadow batches for a Blind Gold Desk round from one spec file, without the hand-typed shell
steps (round 1 lost IDs to zsh's `$P:state` modifier). Run from backend/:

    python3 scripts/gold-desk/build_batch.py <spec.json> [--coders] [--slots 1] [--season open|draft|<uuid>]

spec.json: {"batches": [{"name": "kavanagh", "politician_id": "...", "office_id": "...", "level": "state",
  "topic_key": "school-vouchers", "instrument": "HB 2853 (2022)",
  "sources": [{"url": "...", "human_saved_path": "human-saved/x.txt" | null}]}]}
A batch may give "topic_keys": [...] instead of "topic_key" to code several topics in one call (a
production batch's no-source topics). A source may also carry "instruments" (overrides the batch instrument; evidence-bank rows cite several bills), "source_kind" (default public-record; news/pointer are excerpt-only and need
"pointer_passages" or "candidate_quotes" as anchors), and a statement-only batch may omit "instrument".
Batch dir: data/stance-research/<date>-shadow-<name>. Steps: sources.json -> topic bundle (filtered to
the one topic, full list kept as topics.all.json) -> snapshots -> coder inputs; with --coders, the three
headless coders too (slot 1 opus, 2-3 sonnet). It never reads or prints coder output.
--slots takes a comma list (default 1,2,3) and runs only those coders, each followed by the same
format-repair round. `--slots 1` is the Opus-alone production run (ruling 2026-10-07); report it with
`coding:report --models "opus"`.
Coder stdout is the CLI's JSON result (coder-logs/coder-N.out: duration, token usage, cost) — never the label.
--coders-only skips sources, bundle, snapshot and inputs and runs the coders on each batch's saved
coder-inputs (use it after a snapshot-only build). --parallel N caps concurrent coder runs (default 6).
"""
import json, os, subprocess, sys, datetime, time
sys.path.insert(0, os.path.dirname(__file__)); from repair import repair
spec = json.load(open(sys.argv[1])); run_coders = '--coders' in sys.argv
SLOTS = (1, 2, 3)
if '--slots' in sys.argv:
  i = sys.argv.index('--slots')
  if i + 1 >= len(sys.argv): sys.exit('--slots needs a value, e.g. --slots 1')
  SLOTS = tuple(int(x) for x in sys.argv[i + 1].split(','))
  if not SLOTS or any(k not in (1, 2, 3) for k in SLOTS) or len(set(SLOTS)) != len(SLOTS): sys.exit(f'--slots: each slot must be 1, 2 or 3, once: {sys.argv[i + 1]}')
  if not run_coders and '--coders-only' not in sys.argv: sys.exit('--slots only applies with --coders')
CODERS_ONLY = '--coders-only' in sys.argv
# --season open|draft|<uuid> (or "season" in the spec) builds the bundle against that season; absent = the open
# season, exactly as before. The later steps (code-stance-batch, verify, queue) take the same --season.
SEASON = sys.argv[sys.argv.index('--season') + 1] if '--season' in sys.argv else spec.get('season')
if CODERS_ONLY: run_coders = True
PAR = int(sys.argv[sys.argv.index('--parallel') + 1]) if '--parallel' in sys.argv else 6
DATE = spec.get('date') or datetime.date.today().isoformat()
SP = os.environ.get('SCRATCH', '/tmp')
env = dict(os.environ, ADMIN_INGEST_TOKEN='x')
def sh(args, check=True):
  r = subprocess.run(args, capture_output=True, text=True, env=env)
  if check and r.returncode != 0: sys.exit(f"FAILED {' '.join(args)}\n{r.stdout[-800:]}\n{r.stderr[-800:]}")
  return r.stdout + r.stderr
def build(b, d, keys):
  """sources.json -> bundle (filtered to keys) -> snapshots -> coder inputs. False when a snapshot failed."""
  os.makedirs(d + '/human-saved', exist_ok=True)
  for s in b['sources']:
    if s.get('human_saved_path'): assert os.path.exists(f"{d}/{s['human_saved_path']}"), f"missing {d}/{s['human_saved_path']}"
  json.dump({'batch_id': os.path.basename(d), 'sources': [dict({'url': s['url'], 'source_kind': s.get('source_kind', 'public-record'), 'politician_id': b['politician_id'],
    'office_id': b['office_id'], 'topic_keys': keys, 'instruments': s.get('instruments') or ([b['instrument']] if b.get('instrument') else []),
    'pointer_passages': s.get('pointer_passages', []), 'candidate_quotes': s.get('candidate_quotes', [])},
    **({'human_saved_path': s['human_saved_path']} if s.get('human_saved_path') else {})) for s in b['sources']]}, open(d + '/sources.json', 'w'), indent=2)
  # A candidate needs --race so the bundle records the race (build-coder-inputs codes the race's office).
  sh(['npx', 'tsx', 'scripts/build-stance-topic-bundle.ts', '--dir', d, '--politician', f"{b['politician_id']}:{b.get('level', 'state')}"]
     + (['--race', b['race_id']] if b.get('race_id') else []) + (['--season', SEASON] if SEASON else []))
  t = json.load(open(d + '/topics.json')); json.dump(t, open(d + '/topics.all.json', 'w'), indent=2)
  f = [x for x in t if x['topic_key'] in keys]
  missing = set(keys) - {x['topic_key'] for x in f}
  assert not missing, f"{b['name']}: topic(s) {sorted(missing)} not in the bundle"
  json.dump(f, open(d + '/topics.json', 'w'), indent=2)
  sh(['npm', 'run', '-s', 'coding:snapshot', '--', '--dir', d])
  snaps = json.load(open(d + '/snapshots.json'))
  bad = [(s['url'], s['failure']) for s in snaps if not s['ok']]
  print(f"{b['name']}: {len(snaps)} snapshot(s), markup {[s['amendment_markup'] for s in snaps]}" + (f", FAILED {bad}" if bad else ''), flush=True)
  if bad: return False
  sh(['npm', 'run', '-s', 'coding:inputs', '--', '--dir', d, '--politician', b['politician_id'], '--office', b['office_id']])
  return True

jobs = []
for b in spec['batches']:
  keys = b.get('topic_keys') or [b['topic_key']]
  d = f"data/stance-research/{DATE}-shadow-{b['name']}"
  if CODERS_ONLY:
    if not os.path.exists(f"{d}/coder-inputs/coder-1.md"): print(f"{b['name']}: no coder inputs — build it first"); continue
  elif not build(b, d, keys): continue
  if run_coders: jobs += [(b['name'], d, k) for k in SLOTS]

def finish(name, d, k):
  if not os.path.exists(f"{d}/labels/coder-{k}.json"): print(f"{name}: coder {k} wrote no label (see coder-logs/coder-{k}.err)", flush=True)
  else:
    st = repair(d, k, SP, env)
    if st not in ('valid',): print(f"{name}: coder {k} {st}", flush=True)

running = []
for name, d, k in jobs:
  while len(running) >= PAR:
    for r in running[:]:
      if r[3].poll() is not None: running.remove(r); finish(*r[:3])
    time.sleep(5)
  os.makedirs(d + '/labels', exist_ok=True); os.makedirs(d + '/coder-logs', exist_ok=True)
  e = f"{SP}/empty-{name}-{k}"; os.makedirs(e, exist_ok=True)
  running.append((name, d, k, subprocess.Popen(['claude', '-p', '--model', 'opus' if k == 1 else 'sonnet', '--tools', 'Write', '--allowedTools', 'Write',
    '--permission-mode', 'acceptEdits', '--add-dir', os.path.abspath(d + '/labels'), '--output-format', 'json'],
    stdin=open(f"{d}/coder-inputs/coder-{k}.md"), stdout=open(f"{d}/coder-logs/coder-{k}.out", 'w'), stderr=open(f"{d}/coder-logs/coder-{k}.err", 'w'),
    cwd=e, env=dict(env, CLAUDE_CONFIG_DIR=os.path.expanduser('~/.claude-ev')))))
for r in running: r[3].wait(); finish(*r[:3])
if jobs: print(f"coders done: {len(jobs)} run(s)")
