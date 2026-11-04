"""Make a held follow-up batch (STAGE5 "Held people"): <batch>/pids.txt holds the given ids, and <batch>/moved.txt
every other coded id in the unit, so write-batch.sh sets their code files aside and only these people are written.
python3 -I scripts/stage5/setup_batch.py <stage5 dir> <new batch dir> --level federal|state [--state XX] <pid>...
A unit is one level (federal) or one level and state; "coded" means <stage5>/codes/<pid>.json exists. Every given id
must be coded and in the unit, or nothing is written."""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, positional
import csv
USAGE = 'setup_batch.py <stage5 dir> <new batch dir> --level federal|state [--state XX] <pid>...'
S, B, *pids = positional(3, USAGE)
level = opt('--level', required=True, usage=USAGE); st = opt('--state')
if level != 'federal' and not st: raise SystemExit('a state batch needs --state XX. usage: ' + USAGE)
coded = {f[:-5] for f in os.listdir(f'{S}/codes') if f.endswith('.json')}
unit = set()
for r in csv.DictReader(open(f'{S}/roster.tsv'), delimiter='\t'):
    if r['level'] == level and (level == 'federal' or r['state'] == st) and r['politician_id'] in coded:
        unit.add(r['politician_id'])
missing = [p for p in pids if p not in unit]
if missing: sys.exit(f'not coded in unit: {missing}')
os.makedirs(B, exist_ok=True)
open(f'{B}/pids.txt', 'w').write(''.join(p + '\n' for p in pids))
open(f'{B}/moved.txt', 'w').write(''.join(p + '\n' for p in sorted(unit - set(pids))))
print(f'{B}: {len(pids)} in batch, {len(unit) - len(pids)} set aside')
