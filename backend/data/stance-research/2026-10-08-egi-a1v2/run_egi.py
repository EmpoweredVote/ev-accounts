"""Offline coding for education-gender-identity on the Season 3 draft ladder A1 v2 (ruling 2026-10-08).
NO database writes: the bundle and coder inputs read the DB read-only; snapshot-sources runs WITHOUT --apply;
no code-stance-batch / coding:report / queue / verify --apply. The ladder comes from topics.a1v2.json (alias
topic_key egi-draft-a1v2, which has no annex file, so no annex reaches the coder).

Run from backend/:  python3 data/stance-research/2026-10-08-egi-a1v2/run_egi.py <spec.json> [--build] [--code] [--parallel 3] [--only name,name]
spec.json: {"units": [{"name": "...", "politician_id": "...", "office_id": "...", "level": "state|school|federal|local",
  "race_id": null, "sources": [{"url": "...", "source_kind": "public-record|own-site|news|pointer", "instruments": ["HB 1"],
  "human_saved_path": null, "pointer_passages": [], "candidate_quotes": []}]}]}
"""
import json, os, subprocess, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
spec = json.load(open(sys.argv[1]))
BUILD, CODE = '--build' in sys.argv, '--code' in sys.argv
PAR = int(sys.argv[sys.argv.index('--parallel') + 1]) if '--parallel' in sys.argv else 3
ONLY = set(sys.argv[sys.argv.index('--only') + 1].split(',')) if '--only' in sys.argv else None
ALIAS = json.load(open(f'{HERE}/topics.a1v2.json'))
SP = os.environ.get('SCRATCH', '/tmp')
def sh(args):
  r = subprocess.run(args, capture_output=True, text=True, env=dict(os.environ, ADMIN_INGEST_TOKEN='x'))
  if r.returncode != 0: raise RuntimeError(f"FAILED {' '.join(args)}\n{r.stdout[-1500:]}\n{r.stderr[-1500:]}")
  return r.stdout + r.stderr
def build(u, d):
  os.makedirs(d + '/human-saved', exist_ok=True)
  for s in u['sources']:   # "saved": a page saved under saved-pages/ (e.g. a PDF a fetch tier could not read) -> copy into this batch
    if s.get('saved'):
      import shutil; shutil.copy(f"{HERE}/saved-pages/{s['saved']}", f"{d}/human-saved/{s['saved']}"); s['human_saved_path'] = f"human-saved/{s['saved']}"
  json.dump({'batch_id': os.path.basename(d), 'sources': [dict({'url': s['url'], 'source_kind': s.get('source_kind', 'public-record'),
    'politician_id': u['politician_id'], 'office_id': u['office_id'], 'topic_keys': ['egi-draft-a1v2'],
    'instruments': s.get('instruments', []), 'pointer_passages': s.get('pointer_passages', []), 'candidate_quotes': s.get('candidate_quotes', [])},
    **({'human_saved_path': s['human_saved_path']} if s.get('human_saved_path') else {})) for s in u['sources']]}, open(d + '/sources.json', 'w'), indent=2)
  sh(['npx', 'tsx', 'scripts/build-stance-topic-bundle.ts', '--dir', d, '--politician', f"{u['politician_id']}:{u['level']}"] + (['--race', u['race_id']] if u.get('race_id') else []))
  if os.path.exists(d + '/topics.json'): os.replace(d + '/topics.json', d + '/topics.served.json')
  json.dump(ALIAS, open(d + '/topics.json', 'w'), indent=2)   # the A1 v2 ladder, alias key, no annex
  sh(['npm', 'run', '-s', 'coding:snapshot', '--', '--dir', d])            # no --apply: nothing stored
  snaps = json.load(open(d + '/snapshots.json')); bad = [(s['url'], s['failure']) for s in snaps if not s['ok']]
  print(f"{u['name']}: {len(snaps)} snapshot(s)" + (f", FAILED {bad}" if bad else ''), flush=True)
  if len(bad) == len(snaps): return False
  sh(['npm', 'run', '-s', 'coding:inputs', '--', '--dir', d, '--politician', u['politician_id'], '--office', u['office_id']])
  p = open(d + '/coder-inputs/coder-1.md').read()
  assert 'egi-draft-a1v2' in p and 'Require schools to tell parents when parents ask' in p, f"{u['name']}: A1 v2 ladder not in prompt"
  assert 'no annex for this topic' in p, f"{u['name']}: an annex reached the prompt"
  return True
units = [u for u in spec['units'] if not ONLY or u['name'] in ONLY]
ready = []
for u in units:
  d = f"{HERE}/{u['name']}"
  if BUILD:
    try:
      if not build(u, d): continue
    except Exception as e: print(f"{u['name']}: BUILD ERROR {e}", flush=True); continue
  if os.path.exists(d + '/coder-inputs/coder-1.md'): ready.append((u['name'], d))
if CODE:
  todo = [(n, d) for n, d in ready if not os.path.exists(d + '/labels/coder-1.json')]
  print(f'{len(todo)} coder run(s)', flush=True); running = []
  def done(n, d): print(f"{n}: {'ok' if os.path.exists(d + '/labels/coder-1.json') else 'NO LABEL (see coder-logs)'}", flush=True)
  for n, d in todo:
    while len(running) >= PAR:
      for r in running[:]:
        if r[2].poll() is not None: running.remove(r); done(r[0], r[1])
      time.sleep(5)
    os.makedirs(d + '/labels', exist_ok=True); os.makedirs(d + '/coder-logs', exist_ok=True)
    e = f'{SP}/empty-egi-{n}'; os.makedirs(e, exist_ok=True)
    running.append((n, d, subprocess.Popen(['claude', '-p', '--model', 'opus', '--tools', 'Write', '--allowedTools', 'Write', '--permission-mode', 'acceptEdits',
      '--add-dir', os.path.abspath(d + '/labels'), '--output-format', 'json'], stdin=open(d + '/coder-inputs/coder-1.md'),
      stdout=open(d + '/coder-logs/coder-1.out', 'w'), stderr=open(d + '/coder-logs/coder-1.err', 'w'), cwd=e,
      env=dict(os.environ, CLAUDE_CONFIG_DIR=os.path.expanduser('~/.claude-ev')))))
  for r in running: r[2].wait(); done(r[0], r[1])
