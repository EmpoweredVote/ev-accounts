import json, re, unicodedata
from collections import Counter
cur  = json.load(open(r"C:\ev-accounts-mo\backend\data\seed-st-louis-mo-2026\mo-house-roster-2026-09-28.json", encoding="utf-8"))
j102 = {int(k):v for k,v in json.load(open("house_102nd.json")).items()}
j103 = {int(k):v for k,v in json.load(open("house_103rd.json")).items()}

NICK = {"ken":"kenneth","jon":"jonathan","brad":"bradley","bill":"william","mike":"michael",
        "matt":"matthew","chris":"christopher","dave":"david","tony":"anthony","greg":"gregory",
        "jeff":"jeffrey","dan":"daniel","steve":"steven","rick":"richard","don":"donald"}
def key(n):
    n = unicodedata.normalize("NFKD", n)
    n = re.sub(r"\([^)]*\)", " ", n)
    n = re.sub(r"\b(Jr|Sr|II|III|IV)\b\.?", " ", n)
    n = re.sub(r"\b[A-Za-z]\.", " ", n)                 # middle initials
    t = re.sub(r"[^a-z ]", "", n.lower()).split()
    t = [w for w in t if len(w) > 1]
    return t
def canon(t):  return [NICK.get(w, w) for w in t]
def same(a, b):
    ka, kb = canon(key(a)), canon(key(b))
    if not ka or not kb: return False
    # surname: compare with spaces removed, so "Van Schoiack" == "VanSchoiack"
    sa, sb = "".join(ka[1:]) or ka[0], "".join(kb[1:]) or kb[0]
    return ka[0] == kb[0] and (sa == sb or sa.endswith(sb) or sb.endswith(sa))

VACANT = re.compile(r"vacan", re.I)
out, contradictions = [], []
for r in cur:
    d = int(r["district"]); name = r["name"].strip(); el = (r["elected"] or "").strip()
    if VACANT.search(name):
        out.append((d, name, el, "VACANT — is_vacant, no term row")); continue
    ey = int(el) if el.isdigit() else None
    held103 = same(name, j103[d])
    cont    = same(j103[d], j102[d])
    if not held103:
        v = "MID-TERM ARRIVAL"
    elif cont:
        v = "2023-01-04"
    else:
        v = "2025-01-08"
    # independent cross-check: the roster's own `elected` year
    flag = None
    if v == "2023-01-04" and ey is not None and ey >= 2024: flag = f"journal says continuous, but elected={ey}"
    if v == "2025-01-08" and ey is not None and ey <= 2022: flag = f"journal says new at 103rd, but elected={ey}"
    if v == "MID-TERM ARRIVAL":                             flag = f"not in 103rd first-day list (103rd={j103[d]!r})"
    out.append((d, name, el, v))
    if flag: contradictions.append((d, name, el, j103[d], j102[d], v, flag))

print(Counter(v for *_ , v in out))
print(f"\nCONTRADICTIONS to read individually: {len(contradictions)}\n")
for d,n,el,b,a,v,f in contradictions:
    print(f"  HD-{d:<4} {n:22.22} elected={el:5} 103rd={b:22.22} 102nd={a:22.22}\n        -> {f}")
