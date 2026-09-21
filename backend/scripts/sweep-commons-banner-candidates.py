"""
sweep-commons-banner-candidates.py -- sweep Wikimedia Commons categories for banner candidates.

🔴 SWEEP CATEGORIES AND THEIR SUBCATEGORIES, NOT KEYWORD SEARCH. The Bend banner's source was
missed by keyword search, by three relevant categories and by the Wikipedia article images; it was
found only by sweeping ~1,328 files and matching on dimensions. Recall matters more than precision.

Records licence, author, pixel size and aspect for every file, so the later filters (licence,
colour, band composition) run on measurements rather than on a search-result ranking.
"""
import json, sys, time, urllib.parse
import requests

API = "https://commons.wikimedia.org/w/api.php"
S = requests.Session()
S.headers["User-Agent"] = "EmpoweredVote-banner-sourcing/1.0 (chris@empowered.vote)"

def api(**p):
    p.update(format="json", formatversion=2)
    for attempt in range(4):
        r = S.get(API, params=p, timeout=60)
        if r.status_code == 200:
            return r.json()
        time.sleep(2 * (attempt + 1))
    r.raise_for_status()

def subcats(cat, depth=1, seen=None):
    """Category plus its subcategories, to `depth`. Commons buries good files one level down."""
    seen = seen if seen is not None else set()
    if cat in seen or depth < 0:
        return seen
    seen.add(cat)
    if depth == 0:
        return seen
    cont = {}
    while True:
        d = api(action="query", list="categorymembers", cmtitle=cat, cmtype="subcat",
                cmlimit=500, **cont)
        for m in d.get("query", {}).get("categorymembers", []):
            subcats(m["title"], depth - 1, seen)
        if "continue" not in d:
            break
        cont = d["continue"]
    return seen

def files_in(cat):
    out, cont = [], {}
    while True:
        d = api(action="query", generator="categorymembers", gcmtitle=cat, gcmtype="file",
                gcmlimit=200, prop="imageinfo",
                iiprop="url|size|extmetadata|mediatype", **cont)
        for p in d.get("query", {}).get("pages", []):
            ii = (p.get("imageinfo") or [{}])[0]
            if not ii.get("width"):
                continue
            md = ii.get("extmetadata", {})
            out.append(dict(
                title=p["title"], url=ii["url"], w=ii["width"], h=ii["height"],
                ratio=round(ii["width"] / ii["height"], 3),
                licence=(md.get("LicenseShortName", {}) or {}).get("value", ""),
                author=(md.get("Artist", {}) or {}).get("value", "")[:120],
                date=(md.get("DateTimeOriginal", {}) or {}).get("value", "")[:40],
                cat=cat))
        if "continue" not in d:
            break
        cont = d["continue"]
    return out

ROOTS = json.loads(sys.argv[1])
OUT = sys.argv[2]
allcats = set()
for r in ROOTS:
    allcats |= subcats(r, depth=int(__import__("os").environ.get("DEPTH","1")))
print(f"{len(allcats)} categories (roots + one level of subcategories)")
seen, files = set(), []
for c in sorted(allcats):
    try:
        got = files_in(c)
    except Exception as e:
        print(f"  ! {c}: {e}")
        continue
    new = [f for f in got if f["title"] not in seen]
    for f in new:
        seen.add(f["title"])
    files += new
    if new:
        print(f"  {len(new):>4} new  {c}")
json.dump(files, open(OUT, "w", encoding="utf-8"), indent=1)
print(f"\n{len(files)} distinct files -> {OUT}")
