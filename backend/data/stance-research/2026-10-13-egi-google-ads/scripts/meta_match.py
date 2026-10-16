import csv, re, sys, collections
M, R, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
csv.field_size_limit(10**9)
ST = {'18105':('IN','Indiana'),'55101':('WI','Wisconsin'),'49049':('UT','Utah'),'06037':('CA','California')}
SUF = {'jr','sr','ii','iii','iv','v'}
def toks(s): return re.findall(r"[a-z]+", (s or '').lower().replace("'", ''))
def num(x):
    x = (x or '').replace(',', '').strip()
    return 50 if x.startswith('≤') else int(x) if x.isdigit() else 0
pre = f'{M}/FacebookAdLibraryReport_2026-10-09_US_lifelong'
nat = {}
for r in csv.DictReader(open(f'{pre}_advertisers.csv', encoding='utf-8-sig')):
    nat[(r['Page ID'], r['Disclaimer'])] = (r['Page name'], num(r['Amount spent (USD)']), num(r['Number of ads in Library']))
people = collections.defaultdict(list)
for f in R.split(','):
    seen = set()
    for r in csv.DictReader(open(f)):
        if (r['county'], r['pid']) in seen: continue
        seen.add((r['county'], r['pid']))
        t = [x for x in toks(r['full_name']) if x not in SUF]
        if len(t) >= 2: people[r['county']].append((r, t[0], t[-1]))
rows = []
for cty, plist in people.items():
    st, stname = ST[cty]
    bylast = collections.defaultdict(list)
    for p in plist: bylast[p[2]].append(p)
    for r in csv.DictReader(open(f'{M}/regions/{pre.split("/")[-1]}_{stname}.csv', encoding='utf-8-sig')):
        tk = set(toks(r['Page name'])) | set(toks(r['Disclaimer']))
        for last in tk & bylast.keys():
            for p, first, _ in bylast[last]:
                fm = first in tk or any(len(first) >= 3 and x[:3] == first[:3] for x in tk if x != last)
                low = (r['Page name'] + ' | ' + r['Disclaimer']).lower()
                shape = re.search(rf"(^|\| |friends of |elect |re-?elect )(the )?{last}\b(\s+(for|20\d\d|4|campaign|committee|inc)\b|$| \|)", low)
                if not (fm or shape): continue
                k = (r['Page ID'], r['Disclaimer']); n = nat.get(k, (r['Page name'], 0, 0))
                ss = num(r['Amount spent (USD)'])
                rows.append(dict(county=cty, pid=p['pid'], full_name=p['full_name'], kind=p['kind'], district_type=p['district_type'],
                    title=p['title'], strength='first+last' if fm else 'last_shape', page_id=r['Page ID'], page_name=r['Page name'],
                    disclaimer=r['Disclaimer'], state_spend=ss, total_spend=n[1], n_ads=n[2], home_share=round(ss / n[1], 2) if n[1] else ''))
with open(OUT, 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
print(len(rows), collections.Counter(r['strength'] for r in rows))
