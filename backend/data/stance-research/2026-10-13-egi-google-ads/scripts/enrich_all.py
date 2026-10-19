import csv, sys, collections
G, IN, OUT = sys.argv[1:4]
csv.field_size_limit(10**9)
ST = {'18105':'IN','55101':'WI','49049':'UT','06037':'CA'}
rows = [r for r in csv.DictReader(open(IN)) if True]
ids = {r['advertiser_id'] for r in rows}
geo = collections.defaultdict(collections.Counter)
for r in csv.DictReader(open(f'{G}/google-political-ads-advertiser-geo-spend.csv', encoding='utf-8')):
    if r['Advertiser_ID'] in ids and r['Country']=='US': geo[r['Advertiser_ID']][r['Country_Subdivision_Primary']] += int(r['Spend_USD'] or 0)
wk = collections.defaultdict(list)
for r in csv.DictReader(open(f'{G}/google-political-ads-advertiser-weekly-spend.csv', encoding='utf-8')):
    if r['Advertiser_ID'] in ids: wk[r['Advertiser_ID']].append(r['Week_Start_Date'])
for r in rows:
    g = geo[r['advertiser_id']]; tot = sum(g.values()) or 1
    r['home_share'] = round(g[ST[r['county']]]/tot, 2); r['top_state'] = g.most_common(1)[0][0] if g else ''
    w = sorted(wk[r['advertiser_id']]); r['first_week'] = w[0] if w else ''; r['last_week'] = w[-1] if w else ''
    del r['states']
with open(OUT,'w',newline='') as fh:
    d = csv.DictWriter(fh, fieldnames=list(rows[0])); d.writeheader(); d.writerows(rows)
rows=[r for r in rows if r['strength']=='last_only' and r['top_state']==ST[r['county']]]
for r in sorted(rows, key=lambda r:(r['county'],r['full_name'])):
    print(r['county'], r['kind'][:4], r['full_name'][:24], '|', r['advertiser'][:70], '|', r['top_state'], r['home_share'], r['first_week'], r['last_week'], r['spend_usd'], r['advertiser_id'][-6:])
