import re, json
from pypdf import PdfReader
SMART = {0x2018:"'",0x2019:"'",0x201c:'"',0x201d:'"',0x2013:"-",0x2014:"-",0xfffd:"'"}
ORD  = re.compile(r"^(\d{1,2})(?:st|nd|rd|th)\s+(.+)$")
NAME_OK = re.compile(r"^[A-Z][A-Za-z'\.\-]*(\s+[A-Za-z'\.\-\(\)]+){0,3}$")

def lines_of(path, maxpage=5):
    r = PdfReader(path); out=[]
    for i in range(min(maxpage,len(r.pages))):
        out += [l.translate(SMART).strip() for l in (r.pages[i].extract_text() or "").splitlines()]
    m,k=[],0
    while k<len(out):
        if re.fullmatch(r"\d{1,2}", out[k]) and k+1<len(out) and re.match(r"^(st|nd|rd|th)\s", out[k+1]):
            m.append(out[k]+out[k+1]); k+=2
        else: m.append(out[k]); k+=1
    return m

def roster(path):
    """Returns {district: (name, elected_caption)} -- the Senate tags each list with its election."""
    out, cap = {}, None
    for raw in lines_of(path):
        if raw.lower().startswith("elected november"):
            cap = raw.strip(); continue
        m = ORD.match(raw)
        if not m: continue
        d = int(m.group(1))
        if not 1 <= d <= 34: continue
        name = re.sub(r"\s{2,}"," ", m.group(2)).strip().rstrip(",")
        if not NAME_OK.match(name): continue
        if d not in out: out[d] = (name, cap)
    return out

for y in ("2023","2025"):
    rr = roster(f"senate_{y}.pdf")
    miss = [d for d in range(1,35) if d not in rr]
    from collections import Counter
    print(f"senate_{y}: {len(rr)}/34   missing={miss}   by caption={dict(Counter(c for _,c in rr.values()))}")
    json.dump({str(k):v for k,v in rr.items()}, open(f"senate_{y}.json","w"), indent=1)
