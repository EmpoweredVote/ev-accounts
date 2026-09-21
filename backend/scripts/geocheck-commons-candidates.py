"""
geocheck-commons-candidates.py -- keep only Commons files whose COORDINATES fall inside the city.

🔴🔴 WHY THIS EXISTS. Sweeping "Category:Maumee River" for Fort Wayne returned Defiance, OHIO;
sweeping the Indiana Dunes categories for Gary returned Porter County. A category name is not a
jurisdiction, and a banner of the wrong city is the same defect class as the Lake County roster
that came from a Lake County in another state. The city's own TIGER place polygon is the arbiter.

Files with no coordinates are kept SEPARATELY as `unlocated` -- absence of a coordinate is not
evidence the photo is elsewhere, and some of the best candidates are older uploads with no GPS.
They just cannot be cleared automatically.
"""
import json, sys, time
import requests

API = "https://commons.wikimedia.org/w/api.php"
S = requests.Session()
S.headers["User-Agent"] = "EmpoweredVote-banner-sourcing/1.0 (chris@empowered.vote)"

src, out = sys.argv[1], sys.argv[2]
files = json.load(open(src, encoding="utf-8"))
titles = [f["title"] for f in files]
coords = {}
for i in range(0, len(titles), 50):
    batch = titles[i:i + 50]
    for attempt in range(4):
        r = S.get(API, params=dict(action="query", titles="|".join(batch), prop="coordinates",
                                   coprimary="all", colimit=500, format="json", formatversion=2), timeout=60)
        if r.status_code == 200:
            break
        time.sleep(2 * (attempt + 1))
    for p in r.json().get("query", {}).get("pages", []):
        c = (p.get("coordinates") or [{}])[0]
        if c.get("lat") is not None:
            coords[p["title"]] = (c["lat"], c["lon"])
    print(f"  {min(i+50,len(titles))}/{len(titles)} -- {len(coords)} with coordinates", end="\r")
print()
for f in files:
    f["lat"], f["lon"] = coords.get(f["title"], (None, None))
json.dump(files, open(out, "w", encoding="utf-8"), indent=1)
n = sum(1 for f in files if f["lat"] is not None)
print(f"{n} of {len(files)} carry coordinates -> {out}")
