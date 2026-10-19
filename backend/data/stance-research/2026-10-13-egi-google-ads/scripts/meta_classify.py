import csv, re, sys, collections
IN, OUT = sys.argv[1:3]
SUF = {'jr','sr','ii','iii','iv','v'}
FILL = set('for to the of and elect reelect re committee campaign friends citizens people neighbors support supporters team vote volunteers inc llc pac official page office rep representative senator sen assemblymember assemblyman assemblywoman councilmember councilman councilwoman council member mayor judge supervisor commissioner trustee board school city county state district senate house assembly congress congressman congresswoman us u s dr md esq hon honorable director clerk sheriff attorney treasurer auditor recorder assessor controller governor lieutenant superintendent education unified general primary special election measure seat at large ward area utah indiana wisconsin california ca in ut wi la los angeles monroe racine bloomington'.split())
def toks(s): return re.findall(r"[a-z]+", (s or '').lower().replace("'", ''))
out = []
for r in csv.DictReader(open(IN)):
    if r['home_share'] == '' or float(r['home_share']) < 0.5: continue
    nt = [x for x in toks(r['full_name']) if x not in SUF]; first, last = nt[0], nt[-1]
    allowed = set(nt) | FILL
    def own_like(s):
        t = [x for x in toks(s) if not x.isdigit()]
        has_last = last in t
        has_first = first in t or any(min(len(x), len(first)) >= 3 and (x.startswith(first) or first.startswith(x)) for x in t if x != last)
        extra = [x for x in t if x not in allowed and not (min(len(x), len(first)) >= 3 and (x.startswith(first) or first.startswith(x)))]
        return has_last and has_first and len(extra) == 0, has_last and len(extra) == 0
    pn_full, pn_last = own_like(r['page_name']); dc_full, dc_last = own_like(r['disclaimer'])
    if pn_full or dc_full: cls = 'own_auto'
    elif (pn_last and dc_last) or (dc_last and r['strength'] == 'last_shape' and re.search(r'\bfor\b', r['disclaimer'].lower())): cls = 'own_surname'
    else: cls = 'other'
    if cls != 'other' and r['disclaimer'].startswith('These ads ran without a disclaimer') and int(r['total_spend'] or 0) <= 100: cls += '_nodisc100'
    r['auto_class'] = cls; out.append(r)
with open(OUT, 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=list(out[0])); w.writeheader(); w.writerows(out)
c = collections.Counter(r['auto_class'] for r in out)
pp = collections.defaultdict(set)
for r in out: pp[r['auto_class']].add((r['county'], r['pid']))
print(c, {k: len(v) for k, v in pp.items()})
