"""Build shadow batches for a Blind Gold Desk round from one spec file, without the hand-typed shell
steps (round 1 lost IDs to zsh's `$P:state` modifier). Run from backend/:

    python3 scripts/gold-desk/build_batch.py <spec.json> [--coders]

spec.json: {"batches": [{"name": "kavanagh", "politician_id": "...", "office_id": "...", "level": "state",
  "topic_key": "school-vouchers", "instrument": "HB 2853 (2022)",
  "sources": [{"url": "...", "human_saved_path": "human-saved/x.txt" | null}]}]}
A source may also carry "source_kind" (default public-record; news/pointer are excerpt-only and need
"pointer_passages" or "candidate_quotes" as anchors), and a statement-only batch may omit "instrument".
Batch dir: data/stance-research/<date>-shadow-<name>. Steps: sources.json -> topic bundle (filtered to
the one topic, full list kept as topics.all.json) -> snapshots -> coder inputs; with --coders, the three
headless coders too (slot 1 opus, 2-3 sonnet). It never reads or prints coder output.
"""
import json, os, subprocess, sys, datetime
sys.path.insert(0, os.path.dirname(__file__)); from repair import repair
spec = json.load(open(sys.argv[1])); run_coders = '--coders' in sys.argv
DATE = spec.get('date') or datetime.date.today().isoformat()
SP = os.environ.get('SCRATCH', '/tmp')
env = dict(os.environ, ADMIN_INGEST_TOKEN='x')
def sh(args, check=True):
  r = subprocess.run(args, capture_output=True, text=True, env=env)
  if check and r.returncode != 0: sys.exit(f"FAILED {' '.join(args)}\n{r.stdout[-800:]}\n{r.stderr[-800:]}")
  return r.stdout + r.stderr
procs = []
for b in spec['batches']:
  d = f"data/stance-research/{DATE}-shadow-{b['name']}"
  os.makedirs(d + '/human-saved', exist_ok=True)
  for s in b['sources']:
    if s.get('human_saved_path'): assert os.path.exists(f"{d}/{s['human_saved_path']}"), f"missing {d}/{s['human_saved_path']}"
  json.dump({'batch_id': os.path.basename(d), 'sources': [dict({'url': s['url'], 'source_kind': s.get('source_kind', 'public-record'), 'politician_id': b['politician_id'],
    'office_id': b['office_id'], 'topic_keys': [b['topic_key']], 'instruments': [b['instrument']] if b.get('instrument') else [],
    'pointer_passages': s.get('pointer_passages', []), 'candidate_quotes': s.get('candidate_quotes', [])},
    **({'human_saved_path': s['human_saved_path']} if s.get('human_saved_path') else {})) for s in b['sources']]}, open(d + '/sources.json', 'w'), indent=2)
  # A candidate needs --race so the bundle records the race (build-coder-inputs codes the race's office).
  sh(['npx', 'tsx', 'scripts/build-stance-topic-bundle.ts', '--dir', d, '--politician', f"{b['politician_id']}:{b.get('level', 'state')}"]
     + (['--race', b['race_id']] if b.get('race_id') else []))
  t = json.load(open(d + '/topics.json')); json.dump(t, open(d + '/topics.all.json', 'w'), indent=2)
  f = [x for x in t if x['topic_key'] == b['topic_key']]
  assert len(f) == 1, f"{b['name']}: topic {b['topic_key']} not in the bundle"
  json.dump(f, open(d + '/topics.json', 'w'), indent=2)
  out = sh(['npm', 'run', '-s', 'coding:snapshot', '--', '--dir', d])
  snaps = json.load(open(d + '/snapshots.json'))
  bad = [(s['url'], s['failure']) for s in snaps if not s['ok']]
  print(f"{b['name']}: {len(snaps)} snapshot(s), markup {[s['amendment_markup'] for s in snaps]}" + (f", FAILED {bad}" if bad else ''))
  if bad: continue
  sh(['npm', 'run', '-s', 'coding:inputs', '--', '--dir', d, '--politician', b['politician_id'], '--office', b['office_id']])
  if run_coders:
    os.makedirs(d + '/labels', exist_ok=True); os.makedirs(d + '/coder-logs', exist_ok=True)
    for k in (1, 2, 3):
      e = f"{SP}/empty-{b['name']}-{k}"; os.makedirs(e, exist_ok=True)
      procs.append((b['name'], k, subprocess.Popen(['claude', '-p', '--model', 'opus' if k == 1 else 'sonnet', '--tools', 'Write', '--allowedTools', 'Write',
        '--permission-mode', 'acceptEdits', '--add-dir', os.path.abspath(d + '/labels'), '--output-format', 'text'],
        stdin=open(f"{d}/coder-inputs/coder-{k}.md"), stdout=open(f"{d}/coder-logs/coder-{k}.out", 'w'), stderr=open(f"{d}/coder-logs/coder-{k}.err", 'w'),
        cwd=e, env=dict(env, CLAUDE_CONFIG_DIR=os.path.expanduser('~/.claude-ev')))))
for name, k, p in procs:
  p.wait()
  d = f"data/stance-research/{DATE}-shadow-{name}"
  if not os.path.exists(f"{d}/labels/coder-{k}.json"): print(f"{name}: coder {k} wrote no label (see coder-logs/coder-{k}.err)")
  else:
    st = repair(d, k, SP, env)
    if st not in ('valid',): print(f"{name}: coder {k} {st}")
if procs: print(f"coders done: {len(procs)} run(s)")
