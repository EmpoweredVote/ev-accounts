"""Respell store instrument ids in research text as the bill numbers the gate and readers know (STAGE5 step 9):
"VA-HB-2767-2025" -> "HB 2767 (2025)"; a special session id "-SP1-" adds " Special Session I"; an amendment id is
respelled as its bill. Research text only: appends trims to <batch>/overrides.json (creates it); apply them with
apply_overrides.py. The code file keeps the store id.
python3 -I scripts/stage5/respell_ids.py <batch dir> --state XX"""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir; _args.py sits beside this file
from _args import opt, positional
import csv, json, re
USAGE = 'respell_ids.py <batch dir> --state XX'
B = positional(1, USAGE)[0]; ST = opt('--state', required=True, usage=USAGE)
O = json.load(open(f'{B}/overrides.json')) if os.path.exists(f'{B}/overrides.json') else {'trims': []}
rx = re.compile(re.escape(ST) + r'-([A-Z]+)-(\d+)(?:-SP(\d))?(?:-AMDT-[\w-]+?)?-(\d{4})\b')
n = 0
for r in csv.DictReader(open(f'{B}/research.csv')):
    t = r['reasoning']
    for m in dict.fromkeys(x.group(0) for x in rx.finditer(t)):
        g = rx.match(m).groups()
        new = f"{g[0]} {g[1]} ({g[3]}{' Special Session ' + 'I' * int(g[2]) if g[2] else ''})"
        O['trims'].append({'name': r['full_name'], 'removed': m, 'now': new, 'why': 'store instrument id respelled as the bill number (the gate does not read store ids); research.csv text only; code file unchanged'})
        n += 1
json.dump(O, open(f'{B}/overrides.json', 'w'), indent=1); print('respell trims', n)
