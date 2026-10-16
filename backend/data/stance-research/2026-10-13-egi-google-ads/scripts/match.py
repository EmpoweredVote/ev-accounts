import csv, re, sys, json, collections
G, R, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
csv.field_size_limit(10**9)
ST = {'18105':'IN','55101':'WI','49049':'UT','06037':'CA'}
SUF = {'jr','sr','ii','iii','iv','v'}
def toks(s): return re.findall(r"[a-z]+", (s or '').lower().replace("'", ''))
# advertiser -> states with spend, names
adv = {}
for r in csv.DictReader(open(f'{G}/google-political-ads-advertiser-geo-spend.csv', encoding='utf-8')):
    if r['Country'] != 'US': continue
    a = adv.setdefault(r['Advertiser_ID'], {'names': set(), 'states': set(), 'spend': 0})
    a['names'].add(r['Advertiser_Name']); a['states'].add(r['Country_Subdivision_Primary'])
for r in csv.DictReader(open(f'{G}/google-political-ads-advertiser-stats.csv', encoding='utf-8')):
    if r['Advertiser_ID'] in adv:
        adv[r['Advertiser_ID']]['spend'] = int(r['Spend_USD'] or 0); adv[r['Advertiser_ID']]['creatives'] = int(r['Total_Creatives'] or 0)
for r in csv.DictReader(open(f'{G}/google-political-ads-advertiser-declared-stats.csv', encoding='utf-8')):
    if r['Advertiser_ID'] in adv:
        adv[r['Advertiser_ID']]['names'] |= {r['Advertiser_Declared_Name'], r['Advertiser_Declared_Scope']}
for a in adv.values(): a['tok'] = set(t for n in a['names'] for t in toks(n))
people = {}
for f in R.split(','):
    for r in csv.DictReader(open(f)):
        k = (r['county'], r['pid']); p = people.setdefault(k, dict(r, kinds=set()))
        p['kinds'].add(r['kind'])
rows = []
for (cty, pid), p in people.items():
    t = [x for x in toks(p['full_name']) if x not in SUF]
    if len(t) < 2: continue
    first, last = t[0], t[-1]
    st = ST[cty]
    for aid, a in adv.items():
        if st not in a['states'] or last not in a['tok']: continue
        fm = first in a['tok'] or any(len(first) >= 3 and x[:3] == first[:3] for x in a['tok'] if x != last)
        rows.append(dict(county=cty, pid=pid, full_name=p['full_name'], kind='holder' if 'holder' in p['kinds'] else 'candidate',
            district_type=p['district_type'], title=p['title'], strength='first+last' if fm else 'last_only',
            advertiser_id=aid, advertiser=' | '.join(sorted(n for n in a['names'] if n)), states=','.join(sorted(a['states'])),
            spend_usd=a['spend'], creatives=a.get('creatives', 0)))
with open(OUT, 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
print('people', len(people), 'us advertisers', len(adv), 'candidate matches', len(rows),
      collections.Counter(r['strength'] for r in rows))
