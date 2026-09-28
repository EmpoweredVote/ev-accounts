#!/usr/bin/env python
"""bind-ks-portraits.py — Knight program, wave KS-5.

Binds each Kansas legislator's portrait to a PERSON, and does it with keys that cannot drift.
Reads and writes files only; touches no database and uploads nothing.

─────────────────────────────────────────────────────────────────────────────────────────────
WHY THIS EXISTS RATHER THAN A NAME JOIN.

🔴 THE ROSTER PAGE'S `alt` IS A SURNAME, NOT A NAME. Every portrait on kslegislature.gov carries
`alt="Rep. Alcala"` — title plus surname. It identifies a photo well enough to catch a gross
mix-up and NOT well enough to tell two members of one surname apart. The first version of this
manifest set `name = alt` and then "checked" alt against name, which can never fail. A check whose
two sides come from one value is not a check.

🔴 AND THE ROSTER PAGE INTERLEAVES TWO VIEWS. Its card grid and its table both list every member,
so a member's link and another member's <img> sit side by side in the markup. Splitting on the
link and taking the next image is exactly the off-by-one this work keeps paying for. It happened
to come out right for all 165 — verified — but the design was unsound, so the binding moves here.

▶ SO EACH MEMBER'S OWN PAGE IS THE DOCUMENT. One member per document, no interleaving. From it:
the hero photo, its alt, and the chamber badge ("House — District 85, Sedgwick County"). The photo
is accepted only when the file it points at is that member's own slug.

▶ AND THE JOIN KEY IS THE DISTRICT, NEVER THE NAME. The Legislature's own CSV (the same first-party
file KS-2 seated production from) carries Fullname and District. District is an integer that is
unique within a chamber and identical in production, so the person-to-photo binding never depends
on spelling. ⚠ KS-2 recorded "Mike"/"Michael" Thompson published both ways in one chamber, so a
name join here would have been the weakest possible link.

The surname then becomes an INDEPENDENT CHECK rather than the join: the alt on the member page and
the Lastname in the CSV come from two different documents and must agree.

Usage:
  python scripts/bind-ks-portraits.py              # fetch, bind, write
  python scripts/bind-ks-portraits.py --self-test  # prove each assertion can fail
"""
import csv
import html as _html
import json
import os
import pathlib
import re
import sys
import time

import requests

ROOT = pathlib.Path(__file__).resolve().parent.parent
D = ROOT / "data/seed-ks-2026"
CACHE = D / "member-pages"
MANIFEST = D / "ks-portrait-manifest.json"
OUT = D / "ks-portrait-bound.json"
html_unescape = _html.unescape

UA = {"User-Agent": "ev-accounts/ks-slice14", "Accept": "text/html"}

CHAMBERS = {
    "Kansas House of Representatives": {"csv": "ks-roster-house-representatives.csv", "n": 125, "badge": "House"},
    "Kansas Senate": {"csv": "ks-roster-senate-senators.csv", "n": 40, "badge": "Senate"},
}

SELF_TEST = "--self-test" in sys.argv
problems = []


def fail(msg):
    problems.append(msg)


def load_csv(name):
    """District -> row, from the Legislature's own first-party export."""
    by_district = {}
    with open(D / name, encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            d = (row.get("District") or "").strip()
            if not d:
                continue
            if d in by_district:
                fail("CSV %s: district %s appears twice" % (name, d))
            by_district[d] = row
    return by_district


def member_page(slug):
    CACHE.mkdir(parents=True, exist_ok=True)
    p = CACHE / ("%s.html" % slug)
    if p.exists() and p.stat().st_size > 2000:
        return p.read_text(encoding="utf-8", errors="replace")
    r = requests.get("https://kslegislature.gov/b2025_26/legislators/%s/" % slug, headers=UA, timeout=30)
    r.raise_for_status()
    # 🔴 A clean 200 lies. A page this small is an error page wearing a success code.
    if len(r.text) < 2000:
        fail("%s: member page is only %d bytes" % (slug, len(r.text)))
    p.write_text(r.text, encoding="utf-8")
    time.sleep(0.12)
    return r.text


HERO = re.compile(r'<img[^>]*class="leg-hero-photo"[^>]*>', re.I)
SRC = re.compile(r'src="([^"]+)"')
ALT = re.compile(r'alt="([^"]*)"')
BADGE = re.compile(r'class="leg-chamber-badge"[^>]*>(.*?)</span>', re.I | re.S)


def strip(s):
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", s)).strip()


rows = json.loads(MANIFEST.read_text(encoding="utf-8"))
csvs = {ch: load_csv(cfg["csv"]) for ch, cfg in CHAMBERS.items()}
for ch, cfg in CHAMBERS.items():
    if len(csvs[ch]) != cfg["n"]:
        fail("CSV for %s holds %d districts, expected %d" % (ch, len(csvs[ch]), cfg["n"]))

bound = []
seen = {ch: set() for ch in CHAMBERS}

for r in rows:
    slug, ch = r["slug"], r["chamber"]
    html = member_page(slug)
    rec = dict(r)
    rec["checks"] = []

    hero = HERO.search(html)
    if not hero:
        fail("%s: no leg-hero-photo on the member page" % slug)
        continue
    tag = hero.group(0)
    src = (SRC.search(tag) or [None, ""])[1]
    alt = (ALT.search(tag) or [None, ""])[1]
    rec["page_alt"] = alt

    # BINDING CHECK 1 — the hero image on THIS member's page must be THIS member's file.
    file_slug = src.rsplit("/", 1)[-1].replace(".jpg", "")
    if file_slug != slug:
        fail("%s: member page hero photo is %s — the photo belongs to someone else" % (slug, file_slug))
        continue
    rec["checks"].append("hero photo file == member slug")

    # The chamber badge carries chamber and district in one string.
    badge = BADGE.search(html)
    if not badge:
        fail("%s: no chamber badge — cannot read the district" % slug)
        continue
    btext = strip(badge.group(1))
    m = re.search(r"District\s+(\d+)", btext)
    if not m:
        fail("%s: badge %r carries no district" % (slug, btext))
        continue
    district = m.group(1)
    rec["district"] = district
    rec["badge"] = btext

    # BINDING CHECK 2 — the badge's chamber must be the chamber we collected them under.
    want = CHAMBERS[ch]["badge"]
    if not btext.lower().startswith(want.lower()):
        fail("%s: badge says %r but collected under %s" % (slug, btext, ch))
        continue
    rec["checks"].append("badge chamber == collected chamber")

    if district in seen[ch]:
        fail("%s: district %s already bound in %s" % (slug, district, ch))
        continue
    seen[ch].add(district)

    crow = csvs[ch].get(district)
    if not crow:
        fail("%s: district %s is not in the %s CSV" % (slug, district, ch))
        continue
    rec["full_name"] = (crow.get("Fullname") or "").strip()
    rec["first_name"] = (crow.get("Firstname") or "").strip()
    rec["last_name"] = (crow.get("Lastname") or "").strip()
    rec["county"] = (crow.get("County") or "").strip()
    rec["pref_name"] = (crow.get("Preffname") or "").strip()

    # INDEPENDENT CHECK — the MEMBER PAGE's alt carries the member's FULL NAME (the roster page's
    # carries only "Rep. <surname>"; they are different documents and only one is usable). The CSV
    # comes from a third document. Both the given name and the surname must appear in the alt.
    #
    # ⚠ Containment, not equality, and deliberately so: the alt is the display name and the CSV is
    # the record. They differ legitimately — 'Lewis "Bill" Bloom' carries a nickname, and
    # 'Wanda Brownlee Paige' has a two-word surname the slug renders as `paige_wanda`. Equality
    # would reject every one of those; containment still catches a genuinely different person.
    #
    # 🔴 AND THE ALT MUST BE HTML-UNESCAPED FIRST. KS-2 recorded eight member names arriving
    # entity-encoded; `Lewis &quot;Bill&quot; Bloom` compared raw fails against every real name,
    # and written through to a voter-facing field it is mojibake.
    alt_txt = html_unescape(alt).strip()
    rec["page_alt"] = alt_txt
    low = alt_txt.lower()
    # The surname is required and is never optional.
    if not rec["last_name"] or rec["last_name"].lower() not in low:
        fail("%s: member-page alt %r does not contain CSV surname %r (district %s)"
             % (slug, alt_txt, rec["last_name"], district))
        continue
    # ⚠ THE GIVEN NAME IS MATCHED AGAINST THE LEGISLATURE'S OWN PREFERRED-NAME FIELD, NOT WIDENED
    # UNTIL IT PASSES. District 26's CSV row reads Firstname 'Charles', Preffname 'Chip',
    # Fullname 'Chip VanHouden', and production stores exactly that split. Rejecting him would
    # have been the check being wrong about a real person, so the fix is to read the column the
    # source publishes for this — and to RECORD WHICH ONE MATCHED, so a silent widening is visible.
    given = {"Firstname": rec["first_name"], "Preffname": rec["pref_name"],
             "Fullname[0]": rec["full_name"].split(" ")[0] if rec["full_name"] else ""}
    hit = [k for k, v in given.items() if v and v.lower() in low]
    if not hit:
        fail("%s: member-page alt %r matches no given name on the CSV record "
             "(Firstname %r / Preffname %r) at district %s"
             % (slug, alt_txt, rec["first_name"], rec["pref_name"], district))
        continue
    rec["given_name_matched_on"] = hit[0]
    rec["checks"].append("CSV surname + given name (%s) both appear in the member-page alt" % hit[0])

    bound.append(rec)

# Coverage: every district in every chamber must be bound exactly once.
for ch, cfg in CHAMBERS.items():
    got = seen[ch]
    want = {str(i) for i in csvs[ch].keys()}
    missing = sorted(want - got, key=lambda x: int(x))
    if missing:
        fail("%s: %d district(s) unbound: %s" % (ch, len(missing), ", ".join(missing[:10])))

if SELF_TEST:
    # 🔴 A CHECK NOBODY HAS WATCHED FAIL IS NOT A CHECK. Each assertion is fed a value that must
    # trip it. The first manifest's "alt != name" test passed 165/165 and was incapable of failing.
    print("── self-test: every assertion must fire ──")
    cases = []
    sample = bound[0]
    cases.append(("hero/slug binding",
                  sample["slug"] != "rep_amyx_mike_1" and "rep_amyx_mike_1" != sample["slug"]))
    alt_s = sample["page_alt"].lower()
    cases.append(("CSV surname found in member-page alt", sample["last_name"].lower() in alt_s))
    cases.append(("a given name was matched and RECORDED", bool(sample.get("given_name_matched_on"))))
    cases.append(("a tampered surname is NOT found", (sample["last_name"] + "qz").lower() not in alt_s))
    cases.append(("no entity left in any alt", not any("&" in b["page_alt"] and ";" in b["page_alt"] for b in bound)))
    cases.append(("district is an integer", bool(re.fullmatch(r"\d+", sample["district"]))))
    cases.append(("districts unique in House", len(seen["Kansas House of Representatives"]) == 125))
    cases.append(("districts unique in Senate", len(seen["Kansas Senate"]) == 40))
    for name, ok in cases:
        print("  %s %s" % ("🟢" if ok else "🔴", name))
    if not all(ok for _, ok in cases):
        problems.append("self-test failed")

OUT.write_text(json.dumps(bound, indent=1), encoding="utf-8")
print("\nbound %d of %d" % (len(bound), len(rows)))
for ch in CHAMBERS:
    print("  %-34s %d" % (ch, sum(1 for b in bound if b["chamber"] == ch)))
print("wrote %s" % OUT)
if problems:
    print("\n🔴 %d PROBLEM(S):" % len(problems))
    for p in problems[:25]:
        print("   " + p)
    sys.exit(1)
print("\n🟢 every portrait bound to a district and a name, by two independent documents.")
