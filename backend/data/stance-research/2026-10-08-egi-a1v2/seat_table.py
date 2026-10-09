"""Build seat-table.csv (one row per roster person x county) from roster.csv, the coder labels and the lead files.
Run from this dir: python3 seat_table.py"""
import csv, json, os, glob, collections
COUNTY = {'18105': 'Monroe IN', '55101': 'Racine WI', '49049': 'Utah County UT'}
LEVEL = {'SCHOOL': 'school', 'STATE_UPPER': 'state', 'STATE_LOWER': 'state', 'NATIONAL_UPPER': 'federal', 'NATIONAL_LOWER': 'federal',
         'COUNTY': 'local', 'LOCAL': 'local', 'LOCAL_EXEC': 'local'}
BASIS = {'school': 'record', 'state': 'record', 'federal': 'own-words', 'local': 'own-words'}
R = [x for x in csv.DictReader(open('roster.csv')) if x['district_type'] in LEVEL]
labels = {}
for f in glob.glob('*/labels/coder-1.json'):
  if f.startswith('_'): continue
  r = json.load(open(f))['rows'][0]; labels[r['politician_id']] = (f.split('/')[0], r)
# Reviewer flags (this report, not the coder): V4.1 says a Yes on a MULTI-subject bill proves direction at most.
FLAG = {u: 'V4.1: HEA 1608 is multi-subject (K-3 sexuality instruction + counselor privilege + notice); reviewer reads direction-only'
        for u in ('bob-heaton', 'dave-hall', 'peggy-mayfield', 'eric-a-koch')}
dir_only = collections.defaultdict(list)
for f in glob.glob('leads/*.json'):
  for o in json.load(open(f)).get('direction_only', []): dir_only[o['person']].append(os.path.basename(f))
people = {}
for x in R:
  k = (x['county'], x['pid']); lv = LEVEL[x['district_type']]
  p = people.setdefault(k, {'county': COUNTY[x['county']], 'name': x['full_name'], 'pid': x['pid'], 'levels': set(), 'kinds': collections.defaultdict(set), 'names': set()})
  p['levels'].add(lv); p['kinds'][lv].add(x['kind']); p['names'].add(x['full_name'])
rows = []
for (c, pid), p in people.items():
  lv = sorted(p['levels'], key=['school', 'state', 'federal', 'local'].index)[0]
  # status at the level the person is listed under (a county supervisor running for the Assembly is a challenger there)
  status = 'incumbent' if 'holder' in p['kinds'][lv] else 'challenger'
  norm = lambda n: n.replace('-', ' ').replace('.', '').lower()
  dname = next((n for n in dir_only if norm(n) in {norm(m) for m in p['names']}), None)
  if pid in labels:
    unit, r = labels[pid]
    res = str(r['v6_value']) if r['v6_value'] else f"blank: {r['v6_blank_reason']}"
    why = r['reasoning']; coded = 'yes'; flag = FLAG.get(unit, '')
  else:
    coded, flag, unit = 'no', '', ''
    if dname: res, why = 'blank: direction-only (not coded)', 'lead files: ' + ','.join(dir_only[dname])
    elif lv == 'local': res, why = 'blank: no-source', 'area sweep of local news/official sites found no statement (leads/local.json)'
    elif lv == 'school' and c == '49049': res, why = 'blank: no-source', 'no board vote attributable to a member found; Provo Policy 3300 (2025) adoption vote not in posted minutes (leads/utah.json)'
    elif lv == 'school': res, why = 'blank: no-source', 'no board act or statement found (leads/indiana.json)'
    elif status == 'challenger': res, why = 'blank: no-source', 'campaign-site sweep found nothing (leads/challengers.json)'
    elif lv == 'state': res, why = 'blank: no-source', 'no instrument stating a rung voted on or sponsored in their tenure, and no statement (state lead files)'
    else: res, why = 'blank: no-source', 'no bill, vote or statement found (leads/federal.json)'
  rows.append({'county': p['county'], 'level': lv, 'status': status, 'name': p['name'], 'politician_id': pid, 'basis_at_level': BASIS[lv],
               'result': res, 'coded': coded, 'unit': unit, 'reviewer_flag': flag, 'why': why.replace('\n', ' ')})
rows.sort(key=lambda r: (r['county'], ['school', 'state', 'federal', 'local'].index(r['level']), r['status'], r['name']))
w = csv.DictWriter(open('seat-table.csv', 'w'), fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
# summary: county x level x status -> counts by result
S = collections.Counter((r['county'], r['level'], r['status'], r['result'].split(' (')[0]) for r in rows)
for k in sorted(S): print(' | '.join(k), '|', S[k])
print(len(rows), 'people')
