"""
build-in-stage5-candidates.py -- assemble the IN stage-5 contact-sheet candidate set.

186 faces: 150 legislators + 36 local/county, plus 12 rows carrying no candidate so the
blanks are approved as blanks rather than quietly absent.

Two things this file is careful about:

  1. THE LEGISLATOR JOIN IS ON (chamber, geo_id), NEVER geo_id ALONE. HD-1 and SD-1 are both
     '18001'. Keying on geo_id paired 63 representatives with senators' rows -- the wrong-person
     defect, at scale, produced by a join.

  2. The positional flag IS DERIVED, NOT TYPED. It is true whenever the source filename does NOT
     contain the surname -- an opaque CivicPlus documentID, a WordPress IMG_0546.jpeg, an
     Uploadcare UUID. Those are exactly where GA-3's off-by-one hid (Baldwin served portraits
     as documentID and the page order was not district order). The sheet flags them for a face
     check; a filename carrying the name evidences itself.

The cache is pre-seeded with bytes already fetched and decoded, because iga.in.gov answers
 with 691 bytes of React shell.
"""
import hashlib, json, os, re, shutil, sys, unicodedata

SP = r"C:/Users/Chris/AppData/Local/Temp/claude/C--EV-Accounts/5ff1f913-f183-4ce1-9618-3905c7931f4d/scratchpad"
OUT_JSON = ".tmp-all-candidates.json"
CACHE = ".tmp-headshot-cache"
os.makedirs(CACHE, exist_ok=True)

def norm(s):
    return re.sub(r"[^a-z]", "", unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().lower())

def seed(url, path):
    """Put already-verified bytes where the renderer's cache expects them."""
    ck = os.path.join(CACHE, hashlib.sha1(url.encode()).hexdigest() + ".bin")
    if not os.path.exists(ck) or os.path.getsize(ck) == 0:
        shutil.copyfile(path, ck)

rows = []

# ---- legislature -------------------------------------------------------------------
CH = {"Indiana State Senate": "STATE_UPPER", "Indiana House of Representatives": "STATE_LOWER"}
db = {}
for line in open(os.path.join(SP, "leg150.txt"), encoding="utf-8").read().strip().split("\n"):
    geo, name, pid, cham = line.split("|")
    db[(CH[cham], geo)] = (pid, name)
assert len(db) == 150, len(db)

LEG = "data/seed-in-legislature-2026/headshots"
chosen = {c["iga_lpid"]: c for c in json.load(open(f"{LEG}/chosen.json"))}
for m in json.load(open("data/in-legislature-roster.json"))["roster"]:
    pid, dbname = db[(m["chamber"], m["geo_id"])]
    c = chosen[m["iga_lpid"]]
    path = f"{LEG}/chosen/{c['file']}"
    seed(c["source_url"], path)
    rows.append(dict(
        politician_id=pid, name=dbname, cohort="Indiana Senate" if m["chamber"] == "STATE_UPPER" else "Indiana House",
        office=f"{'Senator' if m['chamber']=='STATE_UPPER' else 'Representative'}, District {m['district']}",
        url=c["source_url"],
        page=(f"https://iga.in.gov/legislative/2026/legislators/{m['iga_lpid']}"
              if c["source"] == "iga" else c["source_url"]),
        license=f"{c['host_class']} ({c['source']})",
        positional=norm(m["last_name"]) not in norm(c["source_url"])))

# ---- local and county --------------------------------------------------------------
LOC = "data/seed-in-local-headshots-2026"
PAGE_URL = {}
for h in json.load(open(f"{LOC}/harvest.json")):
    PAGE_URL.setdefault(h["page"], h["url"])
SITE = {"City of Fort Wayne, Indiana, US": "Fort Wayne", "City of Gary, Indiana, US": "Gary",
        "Allen County, Indiana, US": "Allen County", "Lake County, Indiana, US": "Lake County"}
pid48 = {}
for line in open(os.path.join(SP, "in48.txt"), encoding="utf-8").read().strip().split("\n"):
    gov, cham, title, name = line.split("|")
    pid48[(gov, title, name)] = None
ids = {}
for line in open(os.path.join(SP, "in48ids.txt"), encoding="utf-8").read().strip().split("\n"):
    gov, title, name, pid = line.split("|")
    ids[(gov, title, name)] = pid

# Per-person crop overrides, from the 2026-09-11 approval pass. The centre 4:5 crop is right
# for a studio portrait and wrong for these three, each in a different way.
CROPS = {
 # A transparent border, which flatten() renders WHITE on the sheet and which bbox then trims.
 # (Converted straight to RGB it reads BLACK -- same file, opposite artefact.)
 "Jacquelynn Scheuman": {"bbox": True},
 # 428x244 landscape: he stands right of centre against a skyline, so a centre crop clipped him.
 # No zoom -- the source is small and this keeps 195x244 rather than 156x195.
 "Jon Brandenberger": {"anchor_x": 0.635, "anchor_y": 0.45},
 # Environmental shot: an open book across the bottom and window sky behind. Zoom past both.
 # 1.7 not 2.1 -- 2.1 put her hair on the top edge, against the one-ear-above-hair rule.
 "Gina Pimentel": {"anchor_x": 0.675, "anchor_y": 0.42, "zoom": 1.7},
}

# Rejected on inspection -- renderable files that are not portraits, and the monochrome rule.
REJECT = {
 "Oscar Martinez": "county site serves user-icon-placeholder.png -- a silhouette, not a portrait",
 "Suzette Raggs": "the only image is a 1920x600 photograph of the clerk's counter, no face",
 "John Petalas": "monochrome -- standing rule skips black-and-white",
 "Michael McAlexander": "monochrome -- standing rule skips black-and-white",
 "Peggy Holinga Katona": "monochrome -- standing rule skips black-and-white",
}
NOSOURCE = "Allen County publishes no portrait (council page carries only site chrome); Ballotpedia stub"
for f in json.load(open(f"{LOC}/fetched.json")):
    gov, title, name = f["gov"], f["title"], f["name"]
    rec = dict(politician_id=ids[(gov, title, name)], name=name, office=title, cohort=SITE[gov])
    if name in REJECT:
        rec.update(url=None, page=None, reason=REJECT[name], license=None, positional=False)
    elif not f.get("file"):
        rec.update(url=None, page=None, license=None, positional=False,
                   reason=NOSOURCE if gov.startswith("Allen") else "no published page for this office")
    else:
        seed(f["src"], f"{LOC}/raw/{f['file']}")
        rec.update(url=f["src"], page=PAGE_URL.get(f["page"], f["src"]), license=f["page"],
                   positional=norm(name.split()[-1]) not in norm(f["src"]))
        if name in CROPS:
            rec["crop"] = CROPS[name]
    rows.append(rec)

order = ["Fort Wayne", "Gary", "Allen County", "Lake County", "Indiana House", "Indiana Senate"]
rows.sort(key=lambda r: (order.index(r["cohort"]), r["name"]))
json.dump(rows, open(OUT_JSON, "w", encoding="utf-8"), indent=1)
have = [r for r in rows if r["url"]]
print(f"{len(rows)} rows -> {OUT_JSON}: {len(have)} with a candidate, {len(rows)-len(have)} blank")
print(f"positional (opaque filename, needs a face check): {sum(1 for r in have if r['positional'])}")
for c in order:
    n = [r for r in rows if r["cohort"] == c]
    print(f"   {c:<16}{len([r for r in n if r['url']]):>4} of {len(n)}")
