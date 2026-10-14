import csv, sys, collections
PM, ADV, OUT, *ROS = sys.argv[1:]
def num(x):
    x = (x or '').replace(',', '').strip()
    return 50 if x.startswith('≤') else int(x) if x.isdigit() else 0
rec = {}
for r in csv.DictReader(open(ADV, encoding='utf-8-sig')):
    rec[(r['Page ID'], r['Disclaimer'])] = (num(r['Amount spent (USD)']), num(r['Number of ads in Library']))
rows = list(csv.DictReader(open(PM)))
for r in rows:
    s, n = rec.get((r['page_id'], r['disclaimer']), (0, 0)); r['spend_90d'] = s if (r['page_id'], r['disclaimer']) in rec else ''; r['ads_90d'] = n if s or n else ''
with open(OUT, 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
people = {}
for r in rows:
    k = (r['county'], r['pid']); p = people.setdefault(k, dict(level=r['level'], status=r['status'], recent=False, spend=0))
    if r['spend_90d'] != '': p['recent'] = True; p['spend'] += int(r['spend_90d'])
den = collections.Counter(); c = collections.Counter()
seen = {}
for f in ROS:
    for r in csv.DictReader(open(f)):
        k = (r['county'], r['pid']); seen.setdefault(k, [r['district_type'], set()])[1].add(r['kind'])
LEV = {'NATIONAL_UPPER':'federal','NATIONAL_LOWER':'federal','STATE_UPPER':'state','STATE_LOWER':'state','COUNTY':'county','LOCAL':'city','LOCAL_EXEC':'city','SCHOOL':'school','JUDICIAL':'judicial'}
for k, v in seen.items():
    dt, kinds = v
    s = (LEV.get(dt, 'other'), 'incumbent' if 'holder' in kinds else 'challenger'); den[s] += 1
    p = people.get(k); c[s] += bool(p and p['recent'])
print('level|status|people|Meta own ads in last 90 days')
for l in ['federal','state','county','city','school','judicial']:
    for i in ['incumbent','challenger']:
        if den[(l, i)]: print(f"{l}|{i}|{den[(l,i)]}|{c[(l,i)]}")
print('TOTAL', sum(den.values()), sum(c.values()))
CN = {'18105':'Monroe','55101':'Racine','49049':'Utah','06037':'LA'}
print({CN[cc]: sum(1 for k, p in people.items() if k[0] == cc and p['recent']) for cc in CN})
