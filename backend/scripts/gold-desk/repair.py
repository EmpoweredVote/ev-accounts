"""One format-repair round for a coder label that failed validation. Shared by build_batch.py and
rerun_coders.py.

The coder is given back its own file and the validator's errors, with the instruction to fix ONLY
those fields. The repair is kept only if every row keeps its answer (v6_value and v6_blank_reason);
if the coder changed an answer, the repair is discarded and the original (invalid) file stays — a
repair may fix format, never judgment. The original is kept as labels/coder-N.orig.json, and the
outcome is appended to coder-logs/repair.log.
"""
import json, os, shutil, subprocess

def validate(d, k, env):
  r = subprocess.run(['npx', 'tsx', 'scripts/gold-desk/validate-label.ts', d, str(k)], capture_output=True, text=True, env=env)
  try: return json.loads(r.stdout.strip().splitlines()[-1])
  except Exception: return None

def errors_of(v):
  return list(v['fileErrors']) + [e for r in v['rows'] for e in r['errors']]

def answers(v):
  return [(r['key'], r['value'], r['blank_reason']) for r in v['rows']]

def repair(d, k, scratch, env):
  """Run at most one repair round for labels/coder-k.json in batch dir d. Returns a status string."""
  lab = f'{d}/labels/coder-{k}.json'
  if not os.path.exists(lab): return 'no-label'
  v = validate(d, k, env)
  if v is None: return 'validator-failed'
  errs = errors_of(v)
  if not errs: return 'valid'
  if v['fileErrors']: return 'file-error-not-repaired'  # a broken file is not a format slip
  orig = f'{d}/labels/coder-{k}.orig.json'
  shutil.copy(lab, orig)
  os.remove(lab)  # the coders' Write tool refuses to overwrite a file they have not read (they have no Read tool)
  prompt = (open(f'{d}/coder-inputs/coder-{k}.md').read()
    + '\n\n---\n\nFORMAT REPAIR. You already coded this row and wrote the file below. The validator rejected it for these reasons:\n'
    + '\n'.join(f'- {e}' for e in errs)
    + f'\n\nWrite the corrected file to exactly this path (it replaces any path named above): {os.path.abspath(lab)}\n'
    + 'Fix ONLY the fields these errors name (for example add the missing record_kind, '
      'or make a quote verbatim). Do not change v6_value, v6_blank_reason, rests_on or your reasoning. Your previous file:\n\n'
    + open(orig).read())
  e = f'{scratch}/empty-{os.path.basename(d)}-{k}-repair'; os.makedirs(e, exist_ok=True)
  out = subprocess.run(['claude', '-p', '--model', 'opus' if k == 1 else 'sonnet', '--tools', 'Write', '--allowedTools', 'Write',
    '--permission-mode', 'acceptEdits', '--add-dir', os.path.abspath(f'{d}/labels'), '--output-format', 'text'],
    input=prompt, text=True, capture_output=True, cwd=e, env=dict(env, CLAUDE_CONFIG_DIR=os.path.expanduser('~/.claude-ev')))
  os.makedirs(f'{d}/coder-logs', exist_ok=True)
  open(f'{d}/coder-logs/coder-{k}.repair.out', 'w').write(out.stdout + out.stderr)
  v2 = validate(d, k, env) if os.path.exists(lab) else None
  if v2 is not None and not errors_of(v2) and answers(v2) == answers(v): status = 'repaired'
  else:
    shutil.copy(orig, lab)
    status = 'repair-rejected-answer-changed' if v2 is not None and answers(v2) != answers(v) else 'repair-failed'
  os.makedirs(f'{d}/coder-logs', exist_ok=True)
  with open(f'{d}/coder-logs/repair.log', 'a') as f: f.write(json.dumps({'slot': k, 'errors': errs, 'status': status}) + '\n')
  return status
