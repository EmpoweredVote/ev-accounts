"""Re-run the three headless coders over saved gold inputs after a codebook change (spec §3.4), without
re-fetching anything. Run from backend/:

    python3 scripts/gold-desk/rerun_coders.py <run-tag> <batches.txt> [--parallel 8]

For each batch named in batches.txt (one dir name per line, under data/stance-research/), it makes
<batch>-<run-tag>/ holding copies of the saved inputs only — sources.json (batch_id renamed),
snapshots.json, topics.json, topics.all.json, politicians.json, human-saved/ — then rebuilds the coder
inputs from the CURRENT codebook (coding:inputs) and runs the coders (slot 1 opus, 2-3 sonnet), exactly
as build_batch.py does. snapshots.json is copied unchanged: the coders cite the same snapshot ids, which
are already stored, so nothing is re-snapshotted. Never reads or prints coder output.
Store with: npm run -s coding:report -- --dir <batch>-<tag> --season-id ... --models ... --apply
Report with: npx tsx scripts/reliability-report.ts --run <tag>
"""
import json, os, shutil, subprocess, sys, time
sys.path.insert(0, os.path.dirname(__file__)); from repair import repair
tag, listfile = sys.argv[1], sys.argv[2]
par = int(sys.argv[sys.argv.index('--parallel') + 1]) if '--parallel' in sys.argv else 8
SP = os.environ.get('SCRATCH', '/tmp')
env = dict(os.environ, ADMIN_INGEST_TOKEN='x')
batches = [l.strip() for l in open(listfile) if l.strip() and not l.startswith('#')]
COPY = ['sources.json', 'snapshots.json', 'topics.json', 'topics.all.json', 'politicians.json']

def prepare(b):
  src, dst = f'data/stance-research/{b}', f'data/stance-research/{b}-{tag}'
  if os.path.exists(f'{dst}/coder-inputs/coder-3.md'): return dst  # resumable
  os.makedirs(dst, exist_ok=True)
  for f in COPY:
    if os.path.exists(f'{src}/{f}'): shutil.copy(f'{src}/{f}', f'{dst}/{f}')
  if os.path.isdir(f'{src}/human-saved'): shutil.copytree(f'{src}/human-saved', f'{dst}/human-saved', dirs_exist_ok=True)
  m = json.load(open(f'{dst}/sources.json')); m['batch_id'] = os.path.basename(dst); json.dump(m, open(f'{dst}/sources.json', 'w'), indent=2)
  seat = json.load(open(f'{src}/coding-context.json'))['seat']
  r = subprocess.run(['npm', 'run', '-s', 'coding:inputs', '--', '--dir', dst, '--politician', seat['politician_id'], '--office', seat['office_id']],
                     capture_output=True, text=True, env=env)
  if r.returncode != 0: sys.exit(f'coding:inputs failed for {dst}\n{r.stdout[-600:]}\n{r.stderr[-600:]}')
  return dst

def launch(dst, k):
  name = os.path.basename(dst); e = f'{SP}/empty-{name}-{k}'; os.makedirs(e, exist_ok=True)
  os.makedirs(f'{dst}/labels', exist_ok=True); os.makedirs(f'{dst}/coder-logs', exist_ok=True)
  return subprocess.Popen(['claude', '-p', '--model', 'opus' if k == 1 else 'sonnet', '--tools', 'Write', '--allowedTools', 'Write',
    '--permission-mode', 'acceptEdits', '--add-dir', os.path.abspath(f'{dst}/labels'), '--output-format', 'text'],
    stdin=open(f'{dst}/coder-inputs/coder-{k}.md'), stdout=open(f'{dst}/coder-logs/coder-{k}.out', 'w'),
    stderr=open(f'{dst}/coder-logs/coder-{k}.err', 'w'), cwd=e, env=dict(env, CLAUDE_CONFIG_DIR=os.path.expanduser('~/.claude-ev')))

jobs = []
for b in batches:
  dst = prepare(b)
  for k in (1, 2, 3):
    if not os.path.exists(f'{dst}/labels/coder-{k}.json'): jobs.append((dst, k))
print(f'{len(batches)} batch(es) prepared; {len(jobs)} coder run(s) to do', flush=True)
running, done = [], 0
while jobs or running:
  while jobs and len(running) < par * 3:
    dst, k = jobs.pop(0); running.append((dst, k, launch(dst, k)))
  time.sleep(5)
  for item in [x for x in running if x[2].poll() is not None]:
    running.remove(item); done += 1
    if not os.path.exists(f'{item[0]}/labels/coder-{item[1]}.json'): print(f'{os.path.basename(item[0])}: coder {item[1]} wrote no label', flush=True)
    else:
      st = repair(item[0], item[1], SP, env)
      if st != 'valid': print(f'{os.path.basename(item[0])}: coder {item[1]} {st}', flush=True)
  if done and done % 30 == 0: print(f'{done} run(s) finished', flush=True)
print(f'coders done: {done} run(s)', flush=True)
