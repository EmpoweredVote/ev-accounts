import json, re, html
from collections import Counter
src = open("join2.py").read().split("VACANT = re.compile")[0]
ns={}; exec(src, ns); ns["NICK"]["stephen"]="steven"; same=ns["same"]
D = r"C:\ev-accounts-mo\backend\data\seed-st-louis-mo-2026"

house = json.load(open(rf"{D}\mo-house-roster-2026-09-28.json", encoding="utf-8"))
sen   = json.load(open(rf"{D}\mo-senate-roster-2026-09-28.json", encoding="utf-8"))
h102  = {int(k):v for k,v in json.load(open("house_102nd.json")).items()}
h103  = {int(k):v for k,v in json.load(open("house_103rd.json")).items()}
s23   = {int(k):tuple(v) for k,v in json.load(open("senate_2023.json")).items()}
s25   = {int(k):tuple(v) for k,v in json.load(open("senate_2025.json")).items()}

GA102, GA103 = "2023-01-04", "2025-01-08"
OVERRIDE = {("house",2): (GA102, "surname change: the 102nd Journal certifies 'Mazzie Boyd'; "
    "house.mo.gov/MemberDetails.aspx?district=002&year=2023 names Mazzie Christensen at the same seat. "
    "Control: the same URL at year=2023 returns Kyle Marquart for HD-109 and John Simmons at year=2025, "
    "so the year parameter is honoured and the page is not serving the current holder retroactively.")}

out = []
for r in house:
    d=int(r["district"]); n=r["name"].strip()
    if re.search(r"vacan", n, re.I):
        out.append(dict(chamber="house", district=d, holder=None, is_vacant=True,
                        term_start=None, basis="vacant: is_vacant only, no term row (start date unknown)")); continue
    if ("house",d) in OVERRIDE:
        ts, why = OVERRIDE[("house",d)]
    elif same(n, h103[d]) and same(h103[d], h102[d]):
        ts, why = GA102, "certified at this district in the 102nd GA first-day Journal and continuous since"
    else:
        ts, why = GA103, "first certified at this district in the 103rd GA first-day Journal"
    out.append(dict(chamber="house", district=d, holder=n, is_vacant=False, term_start=ts,
                    elected_field=r["elected"], j102=h102[d], j103=h103[d], basis=why))

now={}
for r in sen:
    d=int(r["district"]); now[d]=re.sub(r"\s+District\s+\d+$","",re.sub(r"^Senator\s+","",html.unescape(r["text"]))).strip()
for d in range(1,35):
    n25,cap = s25[d]; n23,_ = s23[d]
    if d not in now:
        out.append(dict(chamber="senate", district=d, holder=None, is_vacant=True, term_start=None,
                        basis="vacant: senate.mo.gov/senators/ carries VacantSenator?district=10 and 'Vacant District 10'")); continue
    ts = GA102 if same(n25,n23) else GA103
    out.append(dict(chamber="senate", district=d, holder=now[d], is_vacant=False, term_start=ts,
                    seated_by=cap, j102=n23, j103=n25,
                    basis=("certified at this district in the 102nd GA first-day Journal and continuous since"
                           if ts==GA102 else "first certified at this district in the 103rd GA first-day Journal")))

json.dump(out, open(rf"{D}\mo-occupancy-2026-09-28.json","w",encoding="utf-8"), indent=1, ensure_ascii=False)
for ch in ("house","senate"):
    rows=[r for r in out if r["chamber"]==ch]
    print(f"{ch:7} {len(rows):>4} seats  " + "  ".join(f"{k or 'VACANT'}={v}" for k,v in sorted(Counter(r['term_start'] for r in rows).items(), key=lambda x:(x[0] or 'z'))))
print(f"\ntotal {len(out)} offices, {sum(1 for r in out if not r['is_vacant'])} seated, {sum(1 for r in out if r['is_vacant'])} vacant")
