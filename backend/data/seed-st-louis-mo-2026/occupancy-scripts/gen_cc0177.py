"""Generate CC_0177_mo_legislature_incumbents.sql from mo-occupancy-2026-09-28.json.

Run from the seed directory:  python occupancy-scripts/gen_cc0177.py
"""
import json, html, io, os

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rows = json.load(open(os.path.join(HERE, "mo-occupancy-2026-09-28.json"), encoding="utf-8"))
seated = [r for r in rows if not r["is_vacant"]]
vacant = [r for r in rows if r["is_vacant"]]
DT = {"house": "STATE_LOWER", "senate": "STATE_UPPER"}

# The one reuse: SD-31 Rick Brattin already exists, carrying 10 researched stances.
REUSE = {("senate", 31): ("e9ec322c-e997-486d-8202-48423671c800", -290502)}
# FIVE names that belong to DIFFERENT people already seated in other states.
# 🔴 The guard keys on (first_name, last_name), NOT full_name -- so a full_name sweep is not the
# same test. It found 4 of these; the guard itself found HD-46 (David Tyson Smith vs Florida's
# David Smith) and SD-14 (Brian Williams vs Indiana's Brian H Williams). _guardcheck.sql now
# applies the guard's exact predicate.
NAMESAKES = {("house", 12), ("house", 23), ("house", 40), ("house", 46), ("senate", 14)}


def q(s):
    return s.replace("'", "''")


def split(n):
    n = html.unescape(n).strip()
    t = n.split()
    return n, t[0], t[-1]


def geo(r):
    return "29" + "%03d" % r["district"]


new = [r for r in seated if (r["chamber"], r["district"]) not in REUSE]
assert len(new) == 187, len(new)
base = -2790202                       # band -2790388 .. -2790202, measured empty 2026-09-28
ids = {}
for i, r in enumerate(sorted(new, key=lambda x: (x["chamber"], x["district"]))):
    ids[(r["chamber"], r["district"])] = base - i
assert min(ids.values()) == -2790388, min(ids.values())

SRC = (
    "Missouri General Assembly. Membership from each chamber's own roster, read 2026-09-28 - "
    "house.mo.gov/MemberGridCluster.aspx?filter=compact&year=2026&code=R with all 163 member "
    "detail pages fetched (0 errors), and senate.mo.gov/senators/ (33 member cards; District 10 "
    "carries the Senate's own VacantSenator notice). OCCUPANCY IS DATED FROM THE SECRETARY OF "
    "STATE'S s 115.525 RSMo CERTIFICATION, KEYED BY DISTRICT NUMBER, printed in each chamber's "
    "first-day Journal on the day the oath was administered: Journal of the House and Journal of "
    "the Senate, 102nd General Assembly, FIRST DAY, WEDNESDAY, JANUARY 4, 2023 "
    "(documents.house.mo.gov/billtracking/bills231/jrnpdf/jrn001.pdf; "
    "senate.mo.gov/23info/Journals/RDay0101041-87.pdf), and 103rd General Assembly, FIRST DAY, "
    "WEDNESDAY, JANUARY 8, 2025 (documents.house.mo.gov/billtracking/bills251/jrnpdf/jrn001.pdf; "
    "senate.mo.gov/25info/Journals/RDay0101081-80.pdf). THIS IS AN OCCUPANCY START, NOT A TERM "
    "START: a member certified at this district in the 102nd carries 2023-01-04, the first day the "
    "2022 district plan had officeholders, and the floor is there because production holds only "
    "2022-plan polygons. (MO-2) (CC_0177, MO-2)")

HEADER = open(os.path.join(HERE, "occupancy-scripts", "cc0177_header.txt"), encoding="utf-8").read()

o = io.StringIO()
w = o.write
w(HEADER)

w("""
BEGIN;

-- --- 1. The 182 new people with no namesake in production --------------------

CREATE TEMP TABLE mo_new_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO mo_new_people(external_id, full_name, first_name, last_name) VALUES
""")

plain = [r for r in new if (r["chamber"], r["district"]) not in NAMESAKES]
nam = [r for r in new if (r["chamber"], r["district"]) in NAMESAKES]


def people_rows(rs):
    out = []
    for r in sorted(rs, key=lambda x: (x["chamber"], x["district"])):
        fn, f, l = split(r["holder"])
        out.append("  (%d::bigint, '%s', '%s', '%s')" % (
            ids[(r["chamber"], r["district"])], q(fn), q(f), q(l)))
    return out


w(",\n".join(people_rows(plain)) + ";\n")

w("""
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '%s', true, true
FROM mo_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- --- 2. The five namesakes - guard lifted for this statement only ------------
-- Each of these three names belongs to a DIFFERENT person who currently holds a seat in another
-- state, so no row is reused. Checked, not assumed.

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE mo_namesake_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO mo_namesake_people(external_id, full_name, first_name, last_name) VALUES
""" % q(SRC))
w(",\n".join(people_rows(nam)) + ";\n")

w("""
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '%s', true, true
FROM mo_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- --- 3. The one reused person - SD-31 Rick Brattin --------------------------
-- is_incumbent was false, which was correct while the row was only a congressional candidate
-- record. He is a sitting state senator, and the incumbents-only reads filter on this flag.

UPDATE essentials.politicians
   SET is_incumbent = true, is_active = true
 WHERE id = 'e9ec322c-e997-486d-8202-48423671c800'
   AND external_id = -290502
   AND is_incumbent IS DISTINCT FROM true;

-- --- 4. The 188 terms -------------------------------------------------------
-- Keyed on (geo_id, district_type). NEVER geo_id alone: 82 Missouri counties share a geo_id with
-- a House district, 17 with a Senate district, and all 34 Senate districts share one with a House
-- district. '29099' is Jefferson County AND House District 99.

CREATE TEMP TABLE mo_terms(
  geo_id text, district_type text, external_id bigint, term_start date, start_precision text, how_started text
) ON COMMIT DROP;

INSERT INTO mo_terms(geo_id, district_type, external_id, term_start, start_precision, how_started) VALUES
""" % q(SRC))

trows = []
for r in sorted(seated, key=lambda x: (x["chamber"], x["district"])):
    k = (r["chamber"], r["district"])
    eid = REUSE[k][1] if k in REUSE else ids[k]
    trows.append("  ('%s', '%s', %d::bigint, '%s'::date, 'day', 'elected')" % (
        geo(r), DT[r["chamber"]], eid, r["term_start"]))
w(",\n".join(trows) + ";\n")

w("""
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started, '%s'
FROM mo_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'mo'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- --- 5. The 9 vacancies - a flag, and deliberately NO term row --------------

CREATE TEMP TABLE mo_vacant(geo_id text, district_type text) ON COMMIT DROP;

INSERT INTO mo_vacant(geo_id, district_type) VALUES
""" % q(SRC))
w(",\n".join("  ('%s', '%s')" % (geo(r), DT[r["chamber"]])
             for r in sorted(vacant, key=lambda x: (x["chamber"], x["district"]))) + ";\n")

w("""
UPDATE essentials.offices o
   SET is_vacant = true
  FROM mo_vacant v, essentials.districts d
 WHERE d.geo_id = v.geo_id
   AND d.district_type::text = v.district_type
   AND lower(d.state) = 'mo'
   AND o.district_id = d.id
   AND o.is_vacant IS DISTINCT FROM true;
""")

w(open(os.path.join(HERE, "occupancy-scripts", "cc0177_gate.txt"), encoding="utf-8").read())

out = os.path.join(HERE, "..", "..", "migrations", "CC_0177_mo_legislature_incumbents.sql")
open(out, "w", encoding="utf-8", newline="\n").write(o.getvalue())
print("wrote %s  (%d chars)" % (os.path.normpath(out), len(o.getvalue())))
print("%d plain + %d namesakes + 1 reused = %d seated; %d vacant" % (
    len(plain), len(nam), len(plain) + len(nam) + 1, len(vacant)))
print("external_id band: %d .. %d" % (min(ids.values()), max(ids.values())))
from collections import Counter
print("term_start:", dict(Counter(r["term_start"] for r in seated)))
