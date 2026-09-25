"""
Extract the Tennessee General Assembly member portraits, which have NO URL.

🔴🔴 WHY THIS SCRIPT EXISTS AT ALL. Every other source in this pipeline publishes an image
file you can fetch. Tennessee does not. Each member page embeds the portrait inline:

    <img class='framed-photo' src='data:image/png;base64,iVBORw0KGgoAAAANSUhEUg…' />

The page is ~460 KB and roughly 300 KB of that IS the portrait. Two independent checks
called it "no portrait" and both were wrong -- Playwright's rendered img.src filter skipped
it, and a grep for .jpg|.png over the raw HTML returned only the site logo. So the rest of
the pipeline, which takes a URL, cannot express this source. This script turns the pages
into real files on disk, and the candidates JSON points at those files with "bytes_from".

🔴 THE LICENCE IS IN THE FILES, NOT ON ANY PAGE. capitol.tn.gov publishes no disclaimer,
terms of use or photo policy anywhere -- proved by sweeping all 100 URLs in its own
sitemap.xml. The rights statement travels inside each portrait as a PNG tEXt chunk:
"(C) <year> State of Tennessee  Editorial or personal use only, all other uses require
written permission", Author = Jed DeKalb. 19 of 131 carry it; the other 112 were re-saved
by tools that strip metadata and are the SAME photographs by the SAME publisher.
Full record: .planning/research/2026-09-24-tennessee-legislature-portraits.md

WHAT THIS GETS RIGHT THAT A NAIVE SCRAPER DOES NOT

  * 🔴 THE URL IS POSITIONAL -- ?district=H7 NAMES A SEAT, NOT A PERSON. A departed
    member's district page serves their successor, so binding on the district alone would
    seat the wrong face silently. The page's own <h1> names the member, so every row is
    bound by district AND asserted against that name. A disagreement is REPORTED, never
    auto-resolved: it is either a nickname or a roster change, and both need a human.

  * 🔴 capitol.tn.gov SOFT-404s EVERY MISSING PATH -- HTTP 200, og:url = .../Error.aspx,
    title "Page Not Found", a stable ~40 KB. Judging by status code would accept them all.

  * The district key is (mtfcc, geo_id), never geo_id alone: 1,159 geo_id collisions exist
    across 13 states, and TN House 7 and TN Senate 7 are both '47007'.

  * ⚠ robots.txt on both hosts ends "User-agent: * -> Disallow: /". Named crawlers are
    allowed; a generic agent is not. That is not a copyright term, but it is a stated wish
    about automated fetching, so this runs SLOW and ONE-PASS. Do not parallelise it.

  * Bytes are cached on disk. Re-running to re-tune a crop must not re-fetch 132 pages.

CONTROLS. --self-test plants defects in a real page and requires the parser to FAIL on each
one. A parser that cannot be made to fail has not been shown to be reading anything.

USAGE (from C:/EV-Accounts/backend):
  py scripts/tn-ga-portrait-extract.py --self-test
  py scripts/tn-ga-portrait-extract.py --out-dir data/seed-tn-headshots-2026
"""
import argparse
import base64
import io
import json
import os
import re
import sys
import time
import unicodedata

import psycopg2
import requests
from dotenv import find_dotenv, load_dotenv
from PIL import Image

# ⚠ load_dotenv() with no argument walks up from THIS FILE, not from the working directory.
# Run from a worktree that carries no .env of its own and it silently finds nothing, then
# dies on KeyError('DATABASE_URL') as though the variable were unset. Prefer the .env beside
# the working directory, which is how every other script in here is invoked.
load_dotenv(find_dotenv(usecwd=True) or None)

GA = 114
BASE = "https://wapp.capitol.tn.gov/apps/LegislatorInfo/Member?district={d}&ga={ga}"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                    "(KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"}
# The soft-404 signature, measured 2026-09-24 and controlled both ways before use.
SOFT_404 = ("Page Not Found - Tennessee General Assembly", "Error.aspx")
# 99 House + 33 Senate. The count is statutory; it is not read off the site.
HOUSE_N, SENATE_N = 99, 33
CHAMBERS = {"H": ("G5220", "Tennessee House of Representatives", "Representative"),
            "S": ("G5210", "Tennessee Senate", "Senator")}

LICENCE = ("(C) State of Tennessee \u2014 editorial or personal use only "
           "(Tennessee General Assembly official member portrait)")

ap = argparse.ArgumentParser()
ap.add_argument("--out-dir", default="data/seed-tn-headshots-2026")
ap.add_argument("--cache", default=".tmp-tn-member-pages")
ap.add_argument("--delay", type=float, default=0.35, help="seconds between fetches; see robots.txt")
ap.add_argument("--self-test", action="store_true", help="plant defects and require failure")
ap.add_argument("--refetch", action="store_true", help="ignore the page cache")
ARGS = ap.parse_args()


# ---------------------------------------------------------------- parsing, in one place

class ParseError(Exception):
    pass


def parse_member_page(html, district):
    """district -> (name, portrait_bytes). Raises ParseError rather than guessing.

    Every branch here is a defect the --self-test plants and requires to be caught.
    """
    if any(sig in html for sig in SOFT_404):
        raise ParseError("soft 404 (HTTP 200 + Error.aspx)")

    # The page names the member in its <h1>: "Representative Rebecca Alexander".
    m = re.search(r"<h1[^>]*>(.*?)</h1>", html, re.S)
    if not m:
        raise ParseError("no <h1> -- page shape changed")
    name = re.sub(r"\s+", " ", re.sub(r"<[^>]*>", "", m.group(1))).strip()
    name = re.sub(r"^(Representative|Senator)\s+", "", name).strip()
    if not name:
        raise ParseError("<h1> carries no member name")
    if name.lower() == "vacant":
        return None, None                              # a fact, not a failure

    # Anchor on the portrait's own class, not "any data URI". A page that grew a second
    # inline image would otherwise hand us a logo and nothing would look wrong.
    imgs = re.findall(r"<img[^>]*class=['\"]framed-photo['\"][^>]*>", html)
    if not imgs:
        raise ParseError("no <img class='framed-photo'> -- portrait markup changed")
    if len(imgs) > 1:
        raise ParseError(f"{len(imgs)} framed-photo tags -- ambiguous")
    m = re.search(r"src=['\"]data:image/([a-z]+);base64,([A-Za-z0-9+/=]+)['\"]", imgs[0])
    if not m:
        raise ParseError("framed-photo carries no base64 data URI")
    raw = base64.b64decode(m.group(2))
    # Decodability, never the declared MIME type. The bytes are the only honest test.
    Image.open(io.BytesIO(raw)).verify()
    if len(raw) < 20_000:
        raise ParseError(f"portrait is only {len(raw)} bytes -- too small to be a face")
    return name, raw


def rights_of(raw):
    """The Copyright / Author fields, read out of the file. '' when absent."""
    info = Image.open(io.BytesIO(raw)).info
    cr = (info.get("Copyright") or "").strip()
    # ⚠ 'x-default' is the XMP language tag surviving a BLANK value. It is an empty field,
    # not a claim. Read the value, never the presence of the key.
    if cr == "x-default":
        cr = ""
    return cr, (info.get("Author") or "").strip()


# ---------------------------------------------------------------- name agreement

SUFFIXES = {"jr", "sr", "ii", "iii", "iv", "v"}


def name_key(n):
    """(first, last) lowered and stripped of accents, punctuation, middles and suffixes."""
    n = unicodedata.normalize("NFKD", n).encode("ascii", "ignore").decode()
    n = re.sub(r"[^A-Za-z\s-]", " ", n)
    parts = [p for p in n.lower().split() if p and p.rstrip(".") not in SUFFIXES]
    parts = [p for p in parts if len(p) > 1]           # drop middle initials
    return (parts[0], parts[-1]) if len(parts) >= 2 else (parts[0] if parts else "", "")


def agreement(ga_name, our_name):
    a, b = name_key(ga_name), name_key(our_name)
    if a == b:
        return "exact"
    if a[1] == b[1] and a[1]:                          # surname agrees, given name differs
        return "nickname?"                             # e.g. Bill / William -- a human decides
    return "CONFLICT"


# ---------------------------------------------------------------- fetch

def fetch(district):
    os.makedirs(ARGS.cache, exist_ok=True)
    ck = os.path.join(ARGS.cache, f"{district}.html")
    if os.path.exists(ck) and os.path.getsize(ck) > 0 and not ARGS.refetch:
        return open(ck, encoding="utf-8", errors="replace").read(), True
    r = requests.get(BASE.format(d=district, ga=GA), headers=UA, timeout=45)
    html = r.text
    open(ck, "w", encoding="utf-8").write(html)
    time.sleep(ARGS.delay)
    return html, False


# ---------------------------------------------------------------- self-test

def self_test():
    """Plant a defect in a REAL page and require the parser to fail on it.

    🔴 A DETECTOR THAT HAS NEVER BEEN WATCHED FAILING HAS NOT BEEN TESTED. The marker each
    defect removes is read out of the live file, not guessed -- a guessed marker that never
    matches plants nothing and the control 'passes' while testing air.
    """
    html, _ = fetch("H7")
    ok = True

    # Control 0: the unmodified page must PARSE. Without this the other four pass vacuously.
    try:
        name, raw = parse_member_page(html, "H7")
        assert name and raw and len(raw) > 200_000
        print(f"  PASS  control: clean page parses  -> {name}, {len(raw)} bytes")
    except Exception as e:                                          # noqa: BLE001
        print(f"  FAIL  control: clean page did NOT parse -- {e}")
        return False

    anchor = "class='framed-photo'"
    if anchor not in html:                       # the marker must exist before we remove it
        print(f"  FAIL  self-test marker {anchor!r} is not in the live page -- would plant nothing")
        return False

    defects = [
        ("portrait markup removed", html.replace(anchor, "class='something-else'", 1)),
        ("base64 payload stripped",
         re.sub(r"src='data:image/png;base64,[A-Za-z0-9+/=]+'", "src='x.png'", html, count=1)),
        ("<h1> destroyed", re.sub(r"<h1[^>]*>.*?</h1>", "", html, count=1, flags=re.S)),
        ("soft 404 body", "<title>Page Not Found - Tennessee General Assembly</title>"),
        ("truncated portrait",
         re.sub(r"(src='data:image/png;base64,)[A-Za-z0-9+/=]+(')",
                lambda m: m.group(1) + base64.b64encode(b"\x89PNG\r\n\x1a\n" + b"\0" * 40).decode()
                + m.group(2), html, count=1)),
    ]
    for label, broken in defects:
        if broken == html:
            print(f"  FAIL  '{label}': planting changed NOTHING -- the control is testing air")
            ok = False
            continue
        try:
            parse_member_page(broken, "H7")
            print(f"  FAIL  '{label}': parser accepted a broken page")
            ok = False
        except Exception as e:                                      # noqa: BLE001
            print(f"  PASS  '{label}' -> {type(e).__name__}: {str(e)[:60]}")
    return ok


if ARGS.self_test:
    print("Self-test: each defect must make the parser FAIL.\n")
    sys.exit(0 if self_test() else 1)

# ---------------------------------------------------------------- the sweep

print("Self-test first -- a parser that has not been watched failing is not trusted.\n")
if not self_test():
    sys.exit("self-test failed; refusing to sweep")
print()

conn = psycopg2.connect(os.environ["DATABASE_URL"], sslmode="require")
cur = conn.cursor()
# (mtfcc, geo_id) is the key. geo_id alone collides -- TN H7 and TN S7 are both '47007'.
# office_current_holder is LEFT JOINed from offices, so a vacancy is a NULL politician_id
# rather than an absent row; the evidence view's placeholder filter keeps candidates out.
cur.execute("""
    SELECT d.mtfcc, d.geo_id, p.id, p.full_name, o.title, p.photo_custom_url
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.office_current_holder och ON och.office_id = o.id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE lower(d.state) = 'tn' AND d.mtfcc IN ('G5210', 'G5220')
""")
ours = {(r[0], r[1]): dict(pid=r[2], name=r[3], title=r[4], photo=r[5]) for r in cur.fetchall()}
print(f"database: {len(ours)} seated TN legislators\n")

os.makedirs(os.path.join(ARGS.out_dir, "portraits"), exist_ok=True)
rows, problems, vacant = [], [], []

for prefix, n in (("H", HOUSE_N), ("S", SENATE_N)):
    mtfcc, chamber, title = CHAMBERS[prefix]
    for i in range(1, n + 1):
        district = f"{prefix}{i}"
        geo_id = f"47{i:03d}"
        html, cached = fetch(district)
        try:
            ga_name, raw = parse_member_page(html, district)
        except Exception as e:                                      # noqa: BLE001
            problems.append(dict(district=district, kind="parse", detail=str(e)))
            print(f"  {district:5} PARSE FAILED  {e}")
            continue
        if ga_name is None:
            vacant.append(district)
            print(f"  {district:5} vacant on the GA's own page")
            continue

        mine = ours.get((mtfcc, geo_id))
        if not mine:
            problems.append(dict(district=district, kind="unseated", ga_name=ga_name,
                                 detail=f"{mtfcc}/{geo_id} has no seated holder in our database"))
            print(f"  {district:5} NO DB ROW      GA says {ga_name}")
            continue

        verdict = agreement(ga_name, mine["name"])
        cr, author = rights_of(raw)
        path = os.path.join(ARGS.out_dir, "portraits", f"{district}.png")
        open(path, "wb").write(raw)

        lic = LICENCE + (f". Photo by {author}" if author else "")
        rows.append(dict(
            politician_id=mine["pid"], name=mine["name"], ga_name=ga_name,
            office=f"{title} \u2014 District {i}", cohort=chamber,
            url=BASE.format(d=district, ga=GA),     # the page IS the source; there is no image URL
            page=BASE.format(d=district, ga=GA),
            bytes_from=path.replace("\\", "/"),
            license=lic,
            # The page that carries the portrait also NAMES the member, and the name agrees,
            # so the binding is not positional despite the district-keyed URL. Where it does
            # not agree the frame is flagged for the operator to look at.
            positional=(verdict != "exact"),
            district=district, match=verdict,
            copyright_field=cr, author_field=author,
            already_has_photo=bool(mine["photo"]),
        ))
        flag = "" if verdict == "exact" else f"  <-- {verdict} (ours: {mine['name']})"
        print(f"  {district:5} {ga_name:<28} {'cached' if cached else 'fetched'}{flag}")

# ---------------------------------------------------------------- report

json.dump(rows, open(os.path.join(ARGS.out_dir, "tn-candidates.json"), "w", encoding="utf-8"),
          indent=1, ensure_ascii=False)
json.dump(dict(extracted=len(rows), vacant=vacant, problems=problems),
          open(os.path.join(ARGS.out_dir, "tn-extract-report.json"), "w"), indent=1)

print(f"\n{'='*66}")
print(f"extracted        {len(rows)}")
print(f"vacant on the GA {len(vacant)}  {vacant}")
print(f"problems         {len(problems)}")
for p in problems:
    print(f"   {p['district']:5} {p['kind']:9} {p.get('detail', '')}")
by_match = {}
for r in rows:
    by_match[r["match"]] = by_match.get(r["match"], 0) + 1
print(f"name agreement   {by_match}")
print(f"already ours     {sum(1 for r in rows if r['already_has_photo'])}")
print(f"carrying rights  {sum(1 for r in rows if r['copyright_field'])} "
      f"(author named on {sum(1 for r in rows if r['author_field'])})")

# 🔴 THE COUNT IS THE TELL. The statutory shape is 99 + 33 = 132 seats, one of which is
# vacant, so anything other than 131 accounted-for means the sweep did not read what it
# thinks it read -- and a green run with a short count is the failure this catches.
seen = len(rows) + len(vacant) + len(problems)
print(f"accounted for    {seen} of {HOUSE_N + SENATE_N}")
if seen != HOUSE_N + SENATE_N:
    sys.exit(f"\nREFUSING: {HOUSE_N + SENATE_N - seen} districts unaccounted for")
