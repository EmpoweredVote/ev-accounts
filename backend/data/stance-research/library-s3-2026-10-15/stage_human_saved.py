"""Copy each batch's human-saved files from ./human-saved/ into data/stance-research/<date>-shadow-<name>/human-saved/."""
import json, os, shutil, sys
spec = json.load(open(sys.argv[1])); here = os.path.dirname(os.path.abspath(__file__)); date = spec.get('date') or sys.argv[2]
for b in spec['batches']:
  for s in b['sources']:
    if s.get('human_saved_path'):
      d = f"data/stance-research/{date}-shadow-{b['name']}/human-saved"; os.makedirs(d, exist_ok=True)
      shutil.copy(os.path.join(here, s['human_saved_path']), d); print(b['name'], s['human_saved_path'])
