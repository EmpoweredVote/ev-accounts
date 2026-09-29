# District-keyed roster from a Missouri House Journal.
# Source block: "SECRETARY OF STATE / MISSOURI HOUSE OF REPRESENTATIVES /
# Elected <date> / District Name" then 163 "NNth  Full Name" lines.
# pypdf quirks handled: (a) "1st" splits as '1' + 'st Jeff Farnan';
# (b) page furniture glues onto a name.
import re, sys, json
from pypdf import PdfReader

S = r"C:\Users\Chris\AppData\Local\Temp\claude\C--EV-Accounts\b95df6fc-f25c-49fd-86a2-94cb2880001d\scratchpad\mo"
ORD  = re.compile(r"^(\d{1,3})(?:st|nd|rd|th)\s+(.+)$")
TAIL = re.compile(r"\s*\d*\s*(Journal of the House|First Day[^\n]*)\s*$", re.I)
# a name is a person, not prose: <= 5 words, no lowercase-only opener
NAME_OK = re.compile(r"^[A-Z][A-Za-z'\.\-]*(\s+[A-Za-z'\.\-\(\)]+){0,4}$")

SMART = {0x2018:"'",0x2019:"'",0x201c:'"',0x201d:'"',0x2013:"-",0x2014:"-",0xfffd:"'"}

def lines_of(path, maxpage=12):
    r = PdfReader(path)
    out = []
    for i in range(min(maxpage, len(r.pages))):
        out += [l.translate(SMART).strip() for l in (r.pages[i].extract_text() or "").splitlines()]
    # rejoin a bare-number line with the ordinal suffix on the next line
    merged, k = [], 0
    while k < len(out):
        if re.fullmatch(r"\d{1,3}", out[k]) and k+1 < len(out) and re.match(r"^(st|nd|rd|th)\s", out[k+1]):
            merged.append(out[k] + out[k+1]); k += 2
        else:
            merged.append(out[k]); k += 1
    return merged

def roster(path):
    out, elected = {}, None
    for raw in lines_of(path):
        if raw.lower().startswith("elected ") and elected is None:
            elected = raw.strip()
        m = ORD.match(raw)
        if not m: continue
        d = int(m.group(1))
        if not 1 <= d <= 163: continue
        name = re.sub(r"\s{2,}", " ", TAIL.sub("", m.group(2))).strip().rstrip(",")
        if not NAME_OK.match(name):        # reject prose that begins with an ordinal
            continue
        if d in out and out[d] != name:
            print(f"  !! {path[-13:]} d{d}: {out[d]!r} vs {name!r}", file=sys.stderr)
        out.setdefault(d, name)
    return out, elected

for tag, yy in (("102nd","231"), ("103rd","251")):
    rr, el = roster(rf"{S}\house_{yy}.pdf")
    missing = [d for d in range(1,164) if d not in rr]
    print(f"{tag} GA  ({el})  ->  {len(rr)}/163 districts   missing={missing}")
    json.dump(rr, open(rf"{S}\house_{tag}.json","w"), indent=1)
