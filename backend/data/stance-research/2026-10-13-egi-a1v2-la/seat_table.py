"""Build seat-table.csv (one row per roster person x county) from roster.csv, the coder labels and the lead files.
Run from this dir: python3 seat_table.py"""
import csv, json, os, glob, collections
COUNTY = {'06037': 'LA County CA'}
LEVEL = {'SCHOOL': 'school', 'STATE_UPPER': 'state', 'STATE_LOWER': 'state', 'NATIONAL_UPPER': 'federal', 'NATIONAL_LOWER': 'federal',
         'COUNTY': 'local', 'LOCAL': 'local', 'LOCAL_EXEC': 'local'}
BASIS = {'school': 'record', 'state': 'record', 'federal': 'own-words', 'local': 'own-words'}
R = [x for x in csv.DictReader(open('roster.csv')) if x['district_type'] in LEVEL]
labels = {}
for f in glob.glob('*/labels/coder-1.json'):
  if f.startswith('_'): continue
  r = json.load(open(f))['rows'][0]; labels[r['politician_id']] = (f.split('/')[0], r)
# Reviewer flags (this report, not the coder): V4.1 says a Yes on a MULTI-subject bill proves direction at most.
FLAG = {}   # reviewer flags, filled after review of the coder rows
dir_only = collections.defaultdict(list)
for f in glob.glob('leads/*.json'):
  j = json.load(open(f)) if f.endswith('.json') else {}
  # own-words items that name no rule were not coded (PR #950 practice); a coded person's label wins below
  for o in j.get('direction_only', []) + j.get('own_words', []): dir_only[o['person'].split(' (')[0]].append(os.path.basename(f))
STATE_SKIP = {n: 'no vote on AB 1955 final texts: not in office 2023-24' for n in json.load(open('leads/state.json'))['incumbent_votes'] and [x['person'] for x in json.load(open('leads/state.json'))['incumbent_votes'] if not x['records']]}
STATE_SKIP['Henry Stern'] = 'no-evidence: No Vote Recorded on the AB 1955 Senate final vote (2024-06-13)'
people = {}
for x in R:
  k = (x['county'], x['pid']); lv = LEVEL[x['district_type']]
  p = people.setdefault(k, {'county': COUNTY[x['county']], 'name': x['full_name'], 'pid': x['pid'], 'levels': set(), 'kinds': collections.defaultdict(set), 'names': set()})
  p['levels'].add(lv); p['kinds'][lv].add(x['kind']); p['names'].add(x['full_name'])
rows = []
for (c, pid), p in people.items():
  lv = sorted(p['levels'], key=['school', 'state', 'federal', 'local'].index)[0]
  # status at the level the person is listed under (a county supervisor running for the Assembly is a challenger there)
  status = 'incumbent' if 'holder' in p['kinds'][lv] else 'challenger'   # candidate_unlinked = challenger with no politicians row
  norm = lambda n: n.replace('-', ' ').replace('.', '').lower()
  dname = next((n for n in dir_only if norm(n) in {norm(m) for m in p['names']}), None)
  if pid in labels:
    unit, r = labels[pid]
    res = str(r['v6_value']) if r['v6_value'] else f"blank: {r['v6_blank_reason']}"
    why = r['reasoning']; coded = 'yes'; flag = FLAG.get(unit, '')
  else:
    coded, flag, unit = 'no', '', ''
    if dname: res, why = 'blank: direction-only (not coded)', 'lead files: ' + ','.join(dir_only[dname])
    elif lv == 'local': res, why = 'blank: no-source', 'area sweep (body votes + named statements) found nothing for this person (leads/local.json)'
    elif lv == 'school': res, why = 'blank: no-source', 'no board vote or statement found for the 40 boards in the roster; agendas (BoardDocs/Simbli) not searched (leads/school.json)'
    elif lv == 'state' and status == 'incumbent' and p['name'] in STATE_SKIP: res, why = 'blank: no-source', STATE_SKIP[p['name']]
    elif lv == 'state': res, why = 'blank: no-source', 'no instrument, vote or statement found (leads/state.json)'
    else: res, why = 'blank: no-source', 'no statement found; federal votes are context only (leads/federal.json)'
  rows.append({'county': p['county'], 'level': lv, 'status': status, 'name': p['name'], 'politician_id': pid, 'basis_at_level': BASIS[lv],
               'result': res, 'coded': coded, 'unit': unit, 'reviewer_flag': flag, 'why': why.replace('\n', ' ')})
rows.sort(key=lambda r: (r['county'], ['school', 'state', 'federal', 'local'].index(r['level']), r['status'], r['name']))
w = csv.DictWriter(open('seat-table.csv', 'w'), fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
# summary: county x level x status -> counts by result
S = collections.Counter((r['county'], r['level'], r['status'], r['result'].split(' (')[0]) for r in rows)
for k in sorted(S): print(' | '.join(k), '|', S[k])
print(len(rows), 'people')
