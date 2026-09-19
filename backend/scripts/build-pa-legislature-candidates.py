"""
build-pa-legislature-candidates.py -- Knight program, wave PA-5a.

Builds the headshot candidate list for Pennsylvania's 253 seated legislators and writes
.tmp-pa-candidates.json in the shape render-headshot-contact-sheet.py expects. Reads the
database read-only and writes NOTHING to it.

THE LICENCE POSITION, MEASURED 2026-09-18 BEFORE ANY IMAGE WAS FETCHED
  The Pennsylvania General Assembly publishes NO use policy -- legis.state.pa.us/.../copyright.cfm
  is a DMCA complaint procedure and nothing else, and palegis.us carries no terms-of-use page at
  all. That is the Florida / Georgia / Colorado position the programme has shipped five times:
  absence of a policy is not a licence, but a published refusal IS a refusal, and there is none
  here. (Philadelphia is the opposite case and is NOT in this cohort -- see pa.md.)

THE ORIGINAL IS 7.5x LARGER THAN ANYTHING THE SITE LINKS
  The member list serves /resources/images/members/200/<id>.jpg   (200x280)
  the member's own page serves            /members/300/<id>.jpg   (300x420)
  and nothing at all links                /members/original/<id>.jpg  (1500x2100)
  Probing the bucket names found it. 200x280 would have to be upscaled 3x to reach the 600x750
  production crop; the original is downscaled 0.4x. MN-6 found the same shape -- the high-res
  file sitting beside the one the page links -- and it is worth a probe every time.

  🔴 AND THE ORIGINAL'S IDENTITY IS PROVED, NOT ASSUMED. A bucket is a path, not a promise: if
  /original/ were keyed differently from /300/ every member would get a stranger's face and every
  count would still be green. Each pair is compared as a downscaled mean absolute difference, the
  worst offenders are listed for the contact sheet to show, and a pair that disagrees is dropped
  rather than shipped.

USAGE (from C:/EV-Accounts/backend):
  py scripts/build-pa-legislature-candidates.py
  py scripts/build-pa-legislature-candidates.py --limit 20     # a quick pass while iterating
"""
import argparse
import json
import os
from io import BytesIO

import psycopg2
import requests
from PIL import Image
from dotenv import load_dotenv

load_dotenv()

ROSTER = "data/pa-legislature-roster.json"
OUT_JSON = ".tmp-pa-candidates.json"
BASE = "https://www.palegis.us/resources/images/members"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0"}
LICENSE = ("Pennsylvania General Assembly official member portrait (palegis.us). "
           "The chambers publish no use policy; the site's only copyright page is a DMCA "
           "complaint procedure.")
# A pair this far apart is not the same photograph. 0-255 scale; identical files score 0.
MAD_REJECT = 18.0
# Written as byte lists on purpose: an escape sequence in a patch is one more thing that can be
# mangled, and this check is the one that decides whether a real portrait is thrown away.
JPEG_MAGIC = bytes([0xFF, 0xD8, 0xFF])
PNG_MAGIC = bytes([0x89, 0x50, 0x4E, 0x47])

ap = argparse.ArgumentParser()
ap.add_argument("--limit", type=int, default=0, help="stop after N members (iteration only)")
ARGS = ap.parse_args()

roster = json.load(open(ROSTER, encoding="utf-8"))
by_geo = {}
for chamber in roster["chambers"].values():
    for m in chamber["members"]:
        by_geo[(m["geo_id"], chamber["district_type"])] = m

conn = psycopg2.connect(os.environ["DATABASE_URL"], sslmode="require")
cur = conn.cursor()
cur.execute("""
    SELECT p.id, p.full_name, o.title, d.geo_id, d.district_type::text,
           p.photo_custom_url IS NOT NULL AS already_hosted
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
    WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER', 'STATE_UPPER')
    ORDER BY d.district_type::text, length(d.geo_id), d.geo_id
""")
seats = cur.fetchall()
cur.close()
conn.close()
print(f"{len(seats)} seated Pennsylvania legislators in production")

session = requests.Session()
session.headers.update(UA)


def fetch(url):
    """Return (bytes, width, height) or raise. A clean 200 can carry a truncated body, and a
    WAF rejection can arrive as 200 with HTML -- so the status, the declared length AND the
    magic number are all checked."""
    r = session.get(url, timeout=30)
    if r.status_code != 200:
        raise RuntimeError(f"HTTP {r.status_code}")
    declared = int(r.headers.get("content-length") or 0)
    if declared and declared != len(r.content):
        raise RuntimeError(f"TRUNCATED: content-length {declared}, got {len(r.content)}")
    # THE MAGIC NUMBER IS THE TRUTH -- NOT THE EXTENSION, AND NOT THE HEADER. Senator Michele
    # Brooks' "original" is served at a .jpg path with content-type image/jpeg and is a PNG
    # (89 50 4e 47). Refusing it as "not a JPEG" was right about the bytes and wrong about the
    # decision: it is a perfectly good 2.4 MB portrait. Both formats are accepted here, and the
    # importer already flattens alpha onto white.
    if not (r.content.startswith(JPEG_MAGIC) or r.content.startswith(PNG_MAGIC)):
        raise RuntimeError(f"not an image (magic {r.content[:4].hex()}, content-type "
                           f"{r.headers.get('content-type')})")
    im = Image.open(BytesIO(r.content))
    im.load()
    return r.content, im.width, im.height


def mad(a_bytes, b_bytes):
    """Mean absolute difference of the two images at 64x64 greyscale. Scale-independent, so a
    1500x2100 original and a 300x420 thumbnail of the same photograph score near zero."""
    a = Image.open(BytesIO(a_bytes)).convert("L").resize((64, 64))
    b = Image.open(BytesIO(b_bytes)).convert("L").resize((64, 64))
    pa, pb = a.load(), b.load()
    total = 0
    for y in range(64):
        for x in range(64):
            total += abs(pa[x, y] - pb[x, y])
    return total / 4096.0


rows, scores, problems = [], [], []
for i, (pid, name, title, geo_id, dtype, already) in enumerate(seats):
    if ARGS.limit and i >= ARGS.limit:
        break
    m = by_geo.get((geo_id, dtype))
    cohort = "Pennsylvania House" if dtype == "STATE_LOWER" else "Pennsylvania Senate"
    rec = dict(politician_id=pid, name=name, office=title, cohort=cohort,
               url=None, page=None, license=LICENSE, positional=False)
    if not m:
        problems.append(f"{name} ({geo_id}/{dtype}): no roster row")
        rows.append(rec)
        continue
    rec["page"] = m["bio_url"]
    mid = m["member_id"]
    try:
        big, w, h = fetch(f"{BASE}/original/{mid}.jpg")
    except Exception as e:                       # noqa: BLE001 - reported, never swallowed
        problems.append(f"{name}: original unavailable ({e})")
        rows.append(rec)
        continue
    try:
        small, _, _ = fetch(f"{BASE}/300/{mid}.jpg")
        score = mad(big, small)
    except Exception as e:                       # noqa: BLE001
        problems.append(f"{name}: identity check impossible ({e})")
        rows.append(rec)
        continue
    scores.append((score, name, mid))
    if score > MAD_REJECT:
        problems.append(f"{name}: /original/ and /300/ differ (MAD {score:.1f}) — NOT the same photograph")
        rows.append(rec)
        continue
    rec["url"] = f"{BASE}/original/{mid}.jpg"
    rec["source_dimensions"] = f"{w}x{h}"
    rec["identity_mad"] = round(score, 2)
    rec["already_hosted"] = already
    rows.append(rec)
    if (i + 1) % 25 == 0:
        print(f"  {i + 1}/{len(seats)}")

have = [r for r in rows if r["url"]]
print(f"\n{len(rows)} seats -> {len(have)} with a candidate, {len(rows) - len(have)} without")
if scores:
    scores.sort(reverse=True)
    med = sorted(s for s, _, _ in scores)[len(scores) // 2]
    print(f"identity check: median MAD {med:.2f}, worst {scores[0][0]:.2f} ({scores[0][1]})")
    print("  the five widest pairs, which are the only places a swap could hide:")
    for s, n, mid in scores[:5]:
        print(f"    {s:6.2f}  {n}  ({BASE}/original/{mid}.jpg)")
if problems:
    print(f"\n{len(problems)} problem(s):")
    for p in problems[:20]:
        print(f"  !! {p}")

json.dump(rows, open(OUT_JSON, "w", encoding="utf-8"), indent=1)
print(f"\nwrote {OUT_JSON}")
