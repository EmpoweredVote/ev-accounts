import csv, sys, collections
MA, DEC, OUT, *ROS = sys.argv[1:]
LEV = {'NATIONAL_UPPER':'federal','NATIONAL_LOWER':'federal','STATE_UPPER':'state','STATE_LOWER':'state','STATE_EXEC':'state',
       'COUNTY':'county','LOCAL':'city','LOCAL_EXEC':'city','SCHOOL':'school','JUDICIAL':'judicial'}
CN = {'18105':'Monroe IN','55101':'Racine WI','49049':'Utah UT','06037':'LA CA'}
dec = {}
for l in open(DEC):
    if l.startswith('#') or not l.strip(): continue
    n, a, c = l.strip().split('|'); dec[(n, a)] = c
people = {}
for f in ROS:
    for r in csv.DictReader(open(f)):
        p = people.setdefault((r['county'], r['pid']), dict(r, kinds=set())); p['kinds'].add(r['kind'])
for p in people.values():
    p['lev'] = LEV.get(p['district_type'], 'other'); p['inc'] = 'incumbent' if 'holder' in p['kinds'] else 'challenger'; p['cls'] = set(); p['ads'] = []
used = set()
for r in csv.DictReader(open(MA)):
    k = (r['full_name'], r['advertiser_id'][-6:])
    if k in dec:
        p = people[(r['county'], r['pid'])]; p['cls'].add(dec[k]); used.add(k)
        p['ads'].append(dict(r, cls=dec[k]))
missing = set(dec) - used
assert not missing, missing
den = collections.Counter(); num = collections.defaultdict(collections.Counter)
for p in people.values():
    s = (p['lev'], p['inc']); den[s] += 1
    own = bool(p['cls'] & {'own', 'own_ctrl'}); own26 = any(a['cls'] in ('own','own_ctrl') and a['last_week'] >= '2025-07-01' for a in p['ads'])
    num[s]['own'] += own; num[s]['own_since_2025H2'] += own26; num[s]['third_only'] += (not own and 'third' in p['cls'])
order = ['federal','state','county','city','school','judicial','other']
print('level|status|people|own ads ever|own ads since 2025-07|named only by third party')
for l in order:
    for i in ['incumbent','challenger']:
        if den[(l,i)]: n = num[(l,i)]; print(f"{l}|{i}|{den[(l,i)]}|{n['own']}|{n['own_since_2025H2']}|{n['third_only']}")
T = lambda k: sum(n[k] for n in num.values())
print('TOTAL', len(people), T('own'), T('own_since_2025H2'), T('third_only'))
print('by county:', {CN[c]: (sum(1 for (cc,_),p in people.items() if cc==c), sum(1 for (cc,_),p in people.items() if cc==c and p['cls'] & {'own','own_ctrl'})) for c in CN})
with open(OUT, 'w', newline='') as fh:
    w = csv.writer(fh); w.writerow(['county','pid','full_name','status','level','district_type','title','class','advertiser_id','advertiser','top_state','home_share','first_week','last_week','spend_usd','creatives'])
    for (c, pid), p in sorted(people.items(), key=lambda x: (x[0][0], x[1]['full_name'])):
        for a in p['ads']:
            w.writerow([c, pid, p['full_name'], p['inc'], p['lev'], p['district_type'], p['title'], a['cls'], a['advertiser_id'], a['advertiser'], a['top_state'], a['home_share'], a['first_week'], a['last_week'], a['spend_usd'], a['creatives']])
