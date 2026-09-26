"""Build the KY-5 headshot candidate list for the Kentucky General Assembly.

Joins the route sweep (backend/data/seed-ky-2026/ky-portrait-route.json, written by
sweep-ky-portraits.py) to the 138 people KY-2 seated, and emits the candidates JSON that
render-headshot-contact-sheet.py and import-headshot-candidates.py both read.

WHY THE NAME GATE LIVES HERE
  The portrait filenames are POSITIONAL -- house1.jpg encodes a SEAT, not a person, and
  senate137.jpg is Senate district 37 because DistrictNumber is a flat 1-138 index. That is
  the off-by-one class that has cost this programme repeatedly (CivicPatch off by one,
  kitsap.gov alt text off by one, D1.jpg/1.png).

  What defuses it is that legislature.ky.gov states alt="<Name> photo" on every profile, so
  the PUBLISHER binds each positional file to a named human. This script re-checks all 138
  of those alts against the roster WE seated and ABORTS on any disagreement, rather than
  leaving the check as a one-off someone ran once. --self-test proves the check can fail.

  KY-2 found this same publisher's GIS layer carrying a STALE roster beside correct
  geometry (Senate 37 still reads 'Yates, David'). The profile pages are current and the
  images track the seat -- but that is exactly why the binding is re-asserted every run.

LICENCE, ruled by Cantrell 2026-09-26
  The LRC publishes no photo policy. Its terms of use restrict COMMERCIAL use only, under
  KRS 61.874; KRS 61.870(4)(a) defines that as a use by which the user expects a profit.
  Our use is not commercial, so the clause does not bite. The portrait bytes themselves
  carry no copyright field and no by-line (EXIF, IPTC and XMP all read). A permission
  letter goes to the LRC Public Information Office anyway, on the Tennessee pattern.

USAGE (from C:/EV-Accounts/backend, or the KY worktree's backend):
  py scripts/build-ky-legislature-candidates.py --self-test
  py scripts/build-ky-legislature-candidates.py
"""
import argparse
import json
import os
import re
import sys
import unicodedata

import psycopg2
from dotenv import load_dotenv

load_dotenv()

HERE = os.path.dirname(os.path.abspath(__file__))
ROUTE = os.path.join(HERE, "..", "data", "seed-ky-2026", "ky-portrait-route.json")
BASE = "https://legislature.ky.gov"
PROFILE = BASE + "/Legislators/Pages/Legislator-Profile.aspx?DistrictNumber={}"

# The portraits are the LRC's own; the only restriction its terms state is commercial use.
LICENSE = ("Kentucky General Assembly official member portrait (legislature.ky.gov). "
           "The LRC publishes no photo policy and the files carry no embedded rights "
           "statement; its terms restrict COMMERCIAL use only, under KRS 61.874. "
           "Non-commercial use ruled 2026-09-26.")

# The people KY-2/3/4 created. The legislature is the first block.
EXTERNAL_ID_LO, EXTERNAL_ID_HI = -2763000, -2762863

ROSTER_SQL = """
SELECT (CASE WHEN c.name LIKE '%%Senate%%' THEN 'S' ELSE 'H' END
        || regexp_replace(d.label, '^.*District ', ''))  AS seat,
       p.id::text, p.full_name, o.title, d.label
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices   o ON o.id = och.office_id
  JOIN essentials.chambers  c ON c.id = o.chamber_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE p.external_id BETWEEN %s AND %s
"""


def norm(s):
    s = unicodedata.normalize("NFKD", s or "").replace(".", "").replace(",", "").lower()
    s = re.sub(r"\b(jr|sr|ii|iii|iv)\b", "", s)
    return re.sub(r"\s+", " ", s).strip()


def name_key(s):
    """First and last token only. Publishers disagree on middle names and initials --
    'Keturah J. Herron' on our side is 'Keturah Herron' on the chamber's page -- and that
    disagreement is not a wrong-person signal. A swapped PERSON changes both tokens."""
    t = norm(s).split()
    return (t[0], t[-1]) if len(t) >= 2 else (norm(s),)


def alt_name(alt):
    return re.sub(r"\s*photo\s*$", "", alt or "", flags=re.I)


def disagreements(route_rows, roster):
    """Seats where the publisher's own alt text and our seated roster name a different
    person. Anything but an empty list stops the wave."""
    out = []
    for r in route_rows:
        seat = ("H" if r["chamber"] == "House" else "S") + str(r["district"])
        ours = roster.get(seat)
        theirs = alt_name(r.get("alt"))
        if ours is None or not theirs or name_key(ours["full_name"]) != name_key(theirs):
            out.append((seat, ours["full_name"] if ours else None, theirs or None))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "..", ".tmp-ky-legislature-candidates.json"))
    ap.add_argument("--self-test", action="store_true",
                    help="prove the name gate can fail before trusting that it passed")
    args = ap.parse_args()

    route = json.load(open(ROUTE, encoding="utf-8"))["rows"]
    conn = psycopg2.connect(os.environ["DATABASE_URL"], sslmode="require")
    cur = conn.cursor()
    cur.execute(ROSTER_SQL, (EXTERNAL_ID_LO, EXTERNAL_ID_HI))
    roster = {row[0]: {"id": row[1], "full_name": row[2], "office": f"{row[3]}, {row[4]}"}
              for row in cur.fetchall()}

    print(f"route rows {len(route)} · seated roster {len(roster)}")
    if len(route) != 138 or len(roster) != 138:
        sys.exit(f"ABORT: expected 138 and 138, got {len(route)} and {len(roster)}")

    if args.self_test:
        # A control that passes may be passing for the wrong reason. Watch it fail first.
        import copy
        t = copy.deepcopy(route)
        t[0]["alt"] = "Imposter Person photo"          # publisher disagrees with us
        t[60]["district"] = 999                         # seat absent from our roster
        planted = disagreements(t, roster)
        print(f"SELF-TEST: planted 2 faults, gate reported {len(planted)} -> {planted}")
        if len(planted) != 2:
            sys.exit("ABORT: the name gate did not catch both planted faults")

    bad = disagreements(route, roster)
    if bad:
        for b in bad:
            print(f"  MISMATCH {b[0]}: we seated {b[1]!r}, the page's alt says {b[2]!r}")
        sys.exit(f"ABORT: {len(bad)} seat(s) where the portrait is bound to a different person")
    print(f"name gate: {len(route)}/{len(route)} alts agree with the seated roster")

    cands = []
    for r in route:
        seat = ("H" if r["chamber"] == "House" else "S") + str(r["district"])
        who = roster[seat]
        if r.get("fullResStatus") != 200 or not r.get("fullResHref"):
            cands.append({"politician_id": who["id"], "name": who["full_name"],
                          "office": who["office"], "cohort": f"Kentucky {r['chamber']}",
                          "url": None, "page": PROFILE.format(r["districtNumber"])})
            continue
        cands.append({
            "politician_id": who["id"],
            "name": who["full_name"],
            "office": who["office"],
            "cohort": f"Kentucky {r['chamber']}",
            # The page's own "Download Full Resolution Image" href, never a constructed URL.
            "url": BASE + r["fullResHref"],
            "page": PROFILE.format(r["districtNumber"]),
            "license": LICENSE,
            # houseN.jpg / senateN.jpg encode the SEAT. Flagged for a face check even though
            # the publisher's alt cleared every one of them -- the filename is still positional.
            "positional": True,
        })

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(cands, f, indent=1)
    have = sum(1 for c in cands if c.get("url"))
    print(f"wrote {args.out}: {len(cands)} subjects, {have} with a portrait, "
          f"{len(cands) - have} without")


if __name__ == "__main__":
    main()
