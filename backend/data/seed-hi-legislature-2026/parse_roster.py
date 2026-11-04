"""Parse the Hawaii Legislature roster pages into one row per SITTING seat.

🔴 THE ROSTER PRINTS DEPARTED MEMBERS, UNDER THE "ACTIVE" REPEATER. Both pages put every
block in `MembersActive_RepeaterActive`, yet the Senate page carries 26 blocks for 25 seats
and the House 52 for 51. The extra one in each is a member whose term has ENDED — Kidani
(Senate 18, 06/30/2026) and Holt (House 28, 02/13/2026) — printed beside the person who
replaced them. Trusting the repeater's name would seat two people in one district.

The "Term of Office Ended" and "Appointed" lines sit AFTER the district <div> closes, so a
block is delimited by the NEXT member-link, not by any single element.

Usage:  py parse_roster.py <file.html> <S|H>
"""
import html
import json
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")

path, chamber = sys.argv[1], sys.argv[2]
want = "Senate" if chamber == "S" else "House"
seats = 25 if want == "Senate" else 51
raw = open(path, encoding="utf-8", errors="replace").read()

# Block boundaries: each member starts at a member-link and runs to the next one.
starts = [m.start() for m in re.finditer(r'<a id="member-link"', raw)]
bounds = list(zip(starts, starts[1:] + [len(raw)]))

rows = []
for a, b in bounds:
    seg = raw[a:b]
    mid = re.search(r"member=(\d+)", seg)
    photo = re.search(r"<img src='([^']*)'", seg)
    name_m = re.search(r'<h2 class="namecard"><strong>\s*(.*?)\s*</strong>', seg, re.S)
    dist_m = re.search(r'<div class="district">\s*(Senate|House) District (\d+)', seg)
    if not (mid and name_m and dist_m):
        continue
    name = html.unescape(re.sub(r"<[^>]+>", "", name_m.group(1))).strip()
    party = None
    pm = re.search(r"\(([A-Z])\)\s*$", name)
    if pm:
        party, name = pm.group(1), name[: pm.start()].strip()
    ended = re.search(r"Term of Office Ended:\s*([\d/]+)", seg)
    appointed = re.search(r"Appointed\s*([\d/]+)", seg)
    areas = re.search(r'<div class="district">.*?<strong>(.*?)</strong>', seg, re.S)
    rows.append(
        {
            "member_id": int(mid.group(1)),
            "chamber": dist_m.group(1),
            "district": int(dist_m.group(2)),
            "name_listed": name,
            "party_letter": party,
            "photo": photo.group(1) if photo else None,
            "appointed": appointed.group(1) if appointed else None,
            "term_ended": ended.group(1) if ended else None,
            "areas": html.unescape(re.sub(r"<[^>]+>", " ", areas.group(1))).strip() if areas else None,
        }
    )

rows = [r for r in rows if r["chamber"] == want]
departed = [r for r in rows if r["term_ended"]]
sitting = sorted((r for r in rows if not r["term_ended"]), key=lambda r: r["district"])

print(f"{len(rows)} block(s) -> {len(sitting)} sitting, {len(departed)} departed")
for r in departed:
    print(f"  DEPARTED, excluded: {want[0]}{r['district']} {r['name_listed']} (ended {r['term_ended']})")

by_district = {}
dupes = []
for r in sitting:
    if r["district"] in by_district:
        dupes.append(r["district"])
    by_district[r["district"]] = r

ok = True
if dupes:
    print(f"  🔴 STILL DUPLICATED: {sorted(set(dupes))}")
    ok = False
missing = [d for d in range(1, seats + 1) if d not in by_district]
if missing:
    print(f"  🔴 MISSING DISTRICTS: {missing}")
    ok = False
if len(sitting) != seats:
    print(f"  🔴 EXPECTED {seats} SITTING, GOT {len(sitting)}")
    ok = False

print()
for r in sitting:
    flag = f"   ← APPOINTED {r['appointed']}" if r["appointed"] else ""
    print(
        f"  {want[0]}{r['district']:>2}  id={r['member_id']:<5} {r['party_letter'] or '?'}  "
        f"{r['name_listed']:<34}{flag}"
    )

if not ok:
    print("\nREFUSED to write: the roster did not reconcile.")
    sys.exit(1)

json.dump(sitting, open(f"roster-{chamber}.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(f"\nwrote roster-{chamber}.json ({len(sitting)} rows, {sum(1 for r in sitting if r['appointed'])} appointed)")
