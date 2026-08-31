"""
build-fl-legislature-candidates.py

Build .tmp-all-candidates.json for Florida's sitting STATE legislators, from each
chamber's own roster page. Feeds the shared, hardened pipeline unchanged:

    py scripts/build-fl-legislature-candidates.py
    py scripts/render-headshot-contact-sheet.py --title "..." --out ...
    py scripts/import-headshot-candidates.py --dry-run

WHY THIS SHAPE. A legislature is the easy tier: one URL per chamber carries an
official portrait for the whole body, so this is a roster parse, not 155 per-person
hunts. Everything downstream -- the 4:5 crop, the approve-what-ships cache, the
external_id+full_name import guard -- already exists and is NOT re-implemented here.

WHY THESE ROWS EXIST AT ALL. All 155 already read as photo-covered because
photo_origin_url starts with 'http'. That field is meant to be the SOURCE PAGE;
holding a raw image URL there makes a hotlink count as coverage, and a hotlink to a
host that can redesign is how 7 Colorado portraits silently became 404s. This pass
makes the bytes ours and puts the real provenance page in photo_origin_url.

MEASURED FACTS (2026-08-30), so the next reader does not re-probe them:
  * www.flhouse.gov sits behind an F5 BIG-IP WAF. It answers Node's fetch with a
    244-byte "Request Rejected" page AS HTTP 200 regardless of headers -- the block
    is a TLS fingerprint, not a User-Agent. Python requests passes fine. Do not
    "fix" a dead-looking sweep here without checking one row by hand first.
  * Every Senate roster portrait is a 50x66 _Thumbnail.jpg. The full-size sibling is
    the same path with _Thumbnail removed; all 39 were confirmed present.
  * FULL SIZE IS STILL SMALL: House ~208x279 (some 150x200), Senate ~185x246.
    Ballotpedia is NOT a way out -- it re-hosts the identical state file (185x244).
    So these import at NATIVE cropped size. import-headshot-candidates.py already
    does exactly that and never enlarges; storing real pixels keeps the recorded
    resolution honest. Do not pass --max-upscale to make the numbers look better.
"""
import html as htmllib
import json
import os
import re
import unicodedata

import psycopg2
import requests
from dotenv import load_dotenv

load_dotenv()

HOUSE_ROSTER = "https://www.flhouse.gov/Sections/Representatives/representatives.aspx"
SENATE_ROSTER = "https://www.flsenate.gov/Senators/"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                    "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
      "Accept": "text/html,application/xhtml+xml,*/*;q=0.8"}
LICENSE = "public_domain"   # matches the 4 Florida STATE_EXEC rows already in the corpus
OUT = ".tmp-all-candidates.json"


def fold(s):
    """NFD-strip diacritics and punctuation so 'Susan L. Valdes' matches 'Valdes, Susan L.'.
    Combining marks are DELETED, never replaced with a space.

    Entities are unescaped FIRST. The roster writes accented names as '&#225;', and
    comparing that raw refused Fabian Basabe and Johanna Lopez -- a correct refusal by a
    guard reading the wrong bytes. The fix is to decode, never to loosen the guard."""
    s = htmllib.unescape(s or "")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"[^a-z ]", " ", s.lower()).split()


def get(url):
    r = requests.get(url, headers=UA, timeout=60)
    r.raise_for_status()
    return r.text


def parse_house(html):
    """One record per team-box: member id, displayed name, district, portrait."""
    out = {}
    for box in html.split('class="team-box"')[1:]:
        mid = re.search(r"MemberId=(\d+)", box)
        img = (re.search(r'data-src="([^"]*Imaging/Member/[^"]+)"', box)
               or re.search(r'src="([^"]*Imaging/Member/[^"]+)"', box))
        name = re.search(r"<h5>\s*(.*?)\s*</h5>", box, re.S)
        dist = re.search(r"District:\s*([0-9]+)", box)
        if not (mid and img and name):
            continue
        fname = img.group(1).rsplit("/", 1)[-1]
        out[fname] = {
            "roster_name": htmllib.unescape(re.sub(r"\s+", " ", name.group(1)).strip()),
            "district": dist.group(1) if dist else None,
            "url": "https://www.flhouse.gov" + img.group(1),
            "page": ("https://www.flhouse.gov/Sections/Representatives/details.aspx"
                     "?MemberId=" + mid.group(1)),
        }
    return out


def parse_senate(html):
    """The roster serves 50x66 thumbnails; take the full-size sibling. alt= carries the name."""
    out = {}
    pat = (r'<a class="senatorLink" href="(/Senators/[^"]+)">'
           r'<img[^>]*alt="([^"]*)"[^>]*src="([^"]*Photos/[^"]+)"')
    for m in re.finditer(pat, html):
        href, alt, src = m.groups()
        fname = src.rsplit("/", 1)[-1]
        full = src.replace("_Thumbnail.jpg", ".jpg").replace("_Thumbnail.JPG", ".JPG")
        seat = re.search(r"Photos/S(\d+)_", src)
        out[fname] = {
            "roster_name": htmllib.unescape(re.sub(r"^Senator\s+", "", alt).strip()),
            "district": str(int(seat.group(1))) if seat else None,
            "url": "https://www.flsenate.gov" + full,
            "page": "https://www.flsenate.gov" + href,
        }
    return out


conn = psycopg2.connect(os.environ["DATABASE_URL"], sslmode="require")
cur = conn.cursor()
cur.execute("""
    SELECT p.id, p.full_name, d.district_type, d.label, p.photo_origin_url,
           EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = p.id)
      FROM essentials.politicians p
      JOIN essentials.office_current_holder och ON och.politician_id = p.id
      JOIN essentials.offices o  ON o.id = och.office_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'fl'
       AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
       AND och.politician_id IS NOT NULL
     ORDER BY d.district_type, p.full_name
""")
rows = cur.fetchall()
conn.close()

roster = {"STATE_LOWER": parse_house(get(HOUSE_ROSTER)),
          "STATE_UPPER": parse_senate(get(SENATE_ROSTER))}
print("roster: House %d, Senate %d" % (len(roster["STATE_LOWER"]), len(roster["STATE_UPPER"])))

cands, problems = [], []
for pid, name, dtype, label, origin, has_img in rows:
    if has_img:
        problems.append("%s: already has an image row, skipped" % name)
        continue
    fname = (origin or "").rsplit("/", 1)[-1]
    r = roster[dtype].get(fname)
    if not r:
        problems.append("%s: stored portrait %r is no longer on the %s roster" % (name, fname, dtype))
        continue

    # GUARD: the roster must agree on WHO this is. Names are compared as folded tokens
    # and at least two must match, so a surname alone cannot seat a stranger's face.
    shared = set(fold(name)) & set(fold(r["roster_name"]))
    if len(shared) < 2:
        problems.append("%s: roster says %r -- name disagreement, skipped" % (name, r["roster_name"]))
        continue
    seat = re.search(r"([0-9]+)\s*$", label or "")
    if r["district"] and seat and r["district"] != seat.group(1):
        problems.append("%s: roster district %s != our %s, skipped" % (name, r["district"], seat.group(1)))
        continue

    cands.append({
        "politician_id": pid,
        "name": name,
        "office": label,
        "cohort": ("Florida House of Representatives" if dtype == "STATE_LOWER"
                   else "Florida Senate"),
        "url": r["url"],
        "page": r["page"],
        "license": LICENSE,
        # The filename keys a PERSON (House member id; Senate seat_memberid) and the
        # binding was confirmed twice -- the roster's own alt/h5 text names the subject,
        # and the seat number agrees with our district. Not positional.
        "positional": False,
    })

json.dump(cands, open(OUT, "w", encoding="utf-8"), indent=2)
print("\nwrote %d candidates to %s" % (len(cands), OUT))
by = {}
for c in cands:
    by[c["cohort"]] = by.get(c["cohort"], 0) + 1
for k in sorted(by):
    print("  %-36s %d" % (k, by[k]))
if problems:
    print("\n%d not included:" % len(problems))
    for p in problems:
        print("  " + p)
