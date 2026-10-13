import csv, sys, collections
MC, GA, OUT, *ROS = sys.argv[1:]
LEV = {'NATIONAL_UPPER':'federal','NATIONAL_LOWER':'federal','STATE_UPPER':'state','STATE_LOWER':'state','STATE_EXEC':'state',
       'COUNTY':'county','LOCAL':'city','LOCAL_EXEC':'city','SCHOOL':'school','JUDICIAL':'judicial'}
people = {}
for f in ROS:
    for r in csv.DictReader(open(f)):
        p = people.setdefault((r['county'], r['pid']), dict(r, kinds=set())); p['kinds'].add(r['kind'])
meta = collections.defaultdict(list)
for r in csv.DictReader(open(MC)):
    if r['auto_class'] == 'own_auto': meta[(r['county'], r['pid'])].append(r)
goog = {(r['county'], r['pid']) for r in csv.DictReader(open(GA)) if r['class'] in ('own', 'own_ctrl')}
den = collections.Counter(); n = collections.defaultdict(collections.Counter)
for k, p in people.items():
    s = (LEV.get(p['district_type'], 'other'), 'incumbent' if 'holder' in p['kinds'] else 'challenger'); den[s] += 1
    m = k in meta; g = k in goog
    n[s]['meta'] += m; n[s]['google'] += g; n[s]['either'] += (m or g); n[s]['meta_only'] += (m and not g)
    n[s]['meta_1k'] += m and sum(int(r['total_spend'] or 0) for r in meta[k]) >= 1000
print('level|status|people|Meta own page|Meta own >= $1k lifetime|Google own|either|Meta, not Google')
for l in ['federal','state','county','city','school','judicial']:
    for i in ['incumbent','challenger']:
        if den[(l, i)]: c = n[(l, i)]; print(f"{l}|{i}|{den[(l,i)]}|{c['meta']}|{c['meta_1k']}|{c['google']}|{c['either']}|{c['meta_only']}")
T = lambda x: sum(c[x] for c in n.values()); print('TOTAL', len(people), T('meta'), T('meta_1k'), T('google'), T('either'), T('meta_only'))
CN = {'18105':'Monroe','55101':'Racine','49049':'Utah','06037':'LA'}
print({CN[c]: sum(1 for k in meta if k[0] == c) for c in CN})
with open(OUT, 'w', newline='') as fh:
    w = csv.writer(fh); w.writerow(['county','pid','full_name','status','level','district_type','title','page_id','page_name','disclaimer','state_spend','total_spend_usd','n_ads','home_share'])
    for k in sorted(meta, key=lambda k: (k[0], people[k]['full_name'])):
        p = people[k]
        for r in meta[k]: w.writerow([k[0], k[1], p['full_name'], 'incumbent' if 'holder' in p['kinds'] else 'challenger', LEV.get(p['district_type']), p['district_type'], p['title'], r['page_id'], r['page_name'], r['disclaimer'], r['state_spend'], r['total_spend'], r['n_ads'], r['home_share']])
