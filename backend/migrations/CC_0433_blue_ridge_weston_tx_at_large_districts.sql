-- CC_0433 — Blue Ridge and Weston TX: two at-large council seats that no address can reach.
--
-- `CC_0432`'s header left finding (1) open for Lowry Crossing: council offices carrying
-- `district_id IS NULL`, which no geofence join can ever match, so their holders are returned
-- for NO address at all. Measured repo-wide on 2026-11-15, that condition holds **six** offices
-- and every one is in a small Collin County town:
--
--   Blue Ridge      Council Member Place 5    Keith Chitwood
--   Weston          Council Member Place 5    Marla Johnston
--   Lowry Crossing  Council Member Place 5-8  Madrid, Rios, Cash, Simpson
--
-- 🔴 THIS FILE FIXES THE FIRST TWO AND DELIBERATELY DOES NOT TOUCH LOWRY CROSSING, BECAUSE THE
-- RIGHT ANSWER THERE IS THE OPPOSITE ONE. Lowry Crossing's wards are ELECTORATES — settled by
-- turnout across two independent elections and recorded in `body-completeness-baseline.json` —
-- so repointing its four seats at the city-wide district would tell every voter that all eight
-- councilmembers represent them when they elect two. It needs four ward polygons and eight
-- retitles, which is real geography and its own migration. ▶ The shared symptom is the trap:
-- one `district_id IS NULL` pattern, two opposite correct fixes, and only the city's own roster
-- separates them. Each city below was read on its own, from its own sources.
--
-- ⚠ AND THE PATTERN THAT PROMPTED THIS WAS NOT THE WHOLE STORY. The working note read "every
-- district-less office is Place 5 or higher, so one generator stopped assigning districts past
-- Place 4". **Josephine, the fourth small Collin County town, has a Place 5 WITH a district**
-- (`dd8b9f0c`, Gary Chappell) and is clean. So the generator hypothesis has a counterexample in
-- the same county at the same council size, and the surviving claim is only the measured list
-- of six above. Nothing in this file depends on the cause.
--
-- ── BLUE RIDGE: AT LARGE, IN THE CITY'S OWN WORDS ───────────────────────────────────────────
-- blueridgecity.com/elections: "The City of Blue Ridge is a Type A General Law City with a
-- Mayor-Council form of government. The City Council consists of a Mayor and five Councilmembers
-- who are **elected at-large by majority vote**." The same page's May 2, 2026 notice lists
-- "Seats open: Mayor, **2 At-Large Council Seats**" — a second, independent statement.
--
-- 🟢 AND THE CITY'S OWN CONTACT LIST PINS OUR PLACE NUMBERS TO OUR EXACT ROWS, which is the
-- corroboration that matters most here because it tests identity and not just composition
-- (blueridgecity.com/council): council1@ David Apple, council2@ Linda Braly, council3@ Trenton
-- Sissom, council4@ Wendy Mattingly, **council5@ Keith Chitwood**. All five, in our order.
--
-- ⚠ THE CITY SPELLS HER BOTH "Linda Braly" (council page) AND "Linda Braley" (elections page).
-- Our row says Braly. Not changed here and not researched — recorded so the next pass does not
-- read it as new.
--
-- ── WESTON: AT LARGE, AND CONFIRMED BY THE BALLOT ITSELF ────────────────────────────────────
-- westontexas.com/page/Elections: "The City of Weston City Council, which consists of a Mayor
-- and five Alderman positions, are **elected at large**. The Mayor and two (2) Aldermen are
-- elected in odd numbered years and three (3) Aldermen are elected in even numbered years."
-- westontexas.com/page/about_us confirms the city is "located in Northern Collin County", which
-- is the check that this is not one of the other Westons.
--
-- 🟢 THE BALLOT IS THE INDEPENDENT MECHANISM, AND IT IS STRUCTURAL. Collin County's
-- **Summary Results Report, FINAL OFFICIAL**, November 3, 2026, page 20, carries ONE contest for
-- this city — "Alderman - City of Weston", **Vote For 3** — with no ward and no place in its
-- name. Three comparisons inside that same report settle what the shape means:
--   · **Josephine** prints "Alderman Place 3" and "Alderman Place 5" as SEPARATE contests.
--   · **Lowry Crossing** printed four separate ward contests (May 2026: "City Council, Ward 4").
--   · **Weston** prints one contest that every voter in the city gets, choosing three.
-- A single `Vote For 3` contest is structurally incompatible with wards: there is one electorate.
--
-- ⚠ READ THAT PDF BY COORDINATES, NOT BY STREAM ORDER. `pdftotext -layout` on this report pairs
-- a candidate's name with the NEXT line's figure — it rendered "Mike Hill" with no number beside
-- it and shifted the rest — which is the documented family of PDF misreadings in `CLAUDE.md`.
-- The figures below come from `backend/data/local-races-2026-audit/read-racine-pdf.mjs`, which
-- clusters glyph runs by `y`, and **the arithmetic closes**: 107+143+140+75+130 = 595 = Total
-- Votes Cast; 595 + 3 overvotes + 530 undervotes = 1,128 = Contest Totals; and 9 mail + 795
-- early + 324 election day = 1,128 down the other axis.
--
-- 🔴 A TRAP THIS CITY SETS FOR A TEXT SEARCH. Weston's elections page contains the word "ward"
-- four times — "must reside on election day in the **ward** from which the person may be
-- elected" — and that is the page quoting LGC Sec. 22.032(b) verbatim, the statute for Type A
-- general-law cities generally, NOT a statement that Weston has wards. A grep would have
-- convicted the one city on this list that most clearly says "elected at large" one paragraph
-- above. ▶ Read whose sentence it is before reading what it says.
--
-- ── WHAT THIS FILE OVERWRITES ───────────────────────────────────────────────────────────────
-- 🔴 OVERWRITTEN VALUES, recorded here because nothing else will (CLAUDE.md; there is no history
-- table and no replay): both offices' `district_id` was **NULL**.
--   79ad986b-8e55-4ea1-8970-7c5b4b83f5ba  Blue Ridge Place 5  NULL -> 19e78414 (City of Blue Ridge)
--   93c204ca-9a24-4027-8952-811ca792a088  Weston Place 5      NULL -> 68755158 (City of Weston)
-- Both targets are the `LOCAL`/`G4110` city-wide district that this city's Mayor and Places 1-4
-- already point at, each with exactly one `geofence_boundaries` row. No district is created.
--
-- ── MEASURED BEFORE, AND WHAT MUST BE TRUE AFTER ────────────────────────────────────────────
-- An `ST_Covers` probe at `ST_PointOnSurface` of each city's own geofence returned **5 offices**
-- for each city, holding the Mayor and Places 1-4 and missing exactly the Place 5 holder. That
-- the other five came back is the positive control: the probe is not blind, it is correct and
-- the data was short. The post-verify runs the same probe and requires **6**, by name.
--
-- ⚠ TWO THINGS THIS FILE DOES NOT DO, BOTH RECORDED RATHER THAN GUESSED:
--   (1) 🔴 NEITHER CITY USES PLACE NUMBERS ON ITS OWN BALLOT, AND OUR TITLES DO. Weston's 2026
--       county contest is plain "Alderman"; Blue Ridge's Certification of Unopposed Candidates
--       lists the office three times as plain "Council (Consejo)". So our `Place N` labels are
--       OURS, not the cities'. That is `ROSTERS.md` R8 — the titles themselves can be the defect
--       — pointing the OPPOSITE way to Lowry Crossing, where the city says Ward and we say Place.
--       It is a voter-facing rename of ten rows across two cities and it changes which row a
--       person is attached to, so it is a decision, not a cleanup. ▶ The district fix is correct
--       either way: every one of these seats is elected by the whole city.
--       ⚠ That Blue Ridge certificate is dated **May 6, 2023** and is served from the city's
--       CURRENT elections page. A source can be authoritative for one field and stale for
--       another; it is cited here only for the office DESIGNATION, never for who holds anything.
--   (2) 🔴 WESTON HELD AN ELECTION ON 2026-11-03 AND A SITTING ALDERMAN LOST. The official final
--       for that one `Vote For 3` contest: Tanner Bragg 143, John McManus 140, **Marla Johnston
--       130**, Epi Goldstein 107, **Mike Hill 75**. Three seats, so Bragg, McManus and Johnston
--       won and Hill did not. Johnston holds the very seat this file repoints, and she was
--       re-elected. ▶ **NOTHING IS SEATED ON THIS.** A certified result is not a fact about who
--       holds a seat, and a losing incumbent still holds it until his successor takes office —
--       the city's own roster, read 2026-11-15, still lists Metzger, Hill and Johnston with
--       "Term Expires Nov 2026". The handover is a separate migration against a source about the
--       OFFICEHOLDER. Bragg and McManus are in no `politicians` row we hold.
--
-- @incumbency-decision: no-effect — this migration writes no `essentials.office_terms` row. It
-- sets `district_id` on two existing `essentials.offices` rows and touches no term, no race and
-- no candidacy, so no cached `race_candidates.is_incumbent` answer can move.
--
-- Dry run: node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0433_blue_ridge_weston_tx_at_large_districts.sql

BEGIN;

-- ── Premise ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_br_office uuid := '79ad986b-8e55-4ea1-8970-7c5b4b83f5ba';  -- Blue Ridge Place 5
  v_we_office uuid := '93c204ca-9a24-4027-8952-811ca792a088';  -- Weston Place 5
  v_br_dist   uuid := '19e78414-c7c5-420e-a858-ab96c4125e7e';  -- City of Blue Ridge, LOCAL/G4110
  v_we_dist   uuid := '68755158-a11d-4b78-97ac-751661d10ded';  -- City of Weston,    LOCAL/G4110
  v_rec       record;
  v_n         int;
BEGIN
  -- 1. Both offices must still be district-less. An office that has already been repointed
  --    means somebody else has worked this since the research, and the header is stale.
  FOR v_rec IN
    SELECT o.id, o.title, o.district_id
      FROM essentials.offices o
     WHERE o.id IN (v_br_office, v_we_office)
  LOOP
    IF v_rec.district_id IS NOT NULL THEN
      RAISE EXCEPTION 'CC_0433: office % (%) already carries district_id % — somebody has changed '
        'this since the file was researched; re-read the header before proceeding.',
        v_rec.id, v_rec.title, v_rec.district_id;
    END IF;
  END LOOP;

  -- 2. And they must still be held by the people whose rosters were read. A seat that changed
  --    hands invalidates the identity half of the evidence, which is the half that is checked
  --    by name rather than by count.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE (o.id = v_br_office AND p.full_name = 'Keith Chitwood')
      OR (o.id = v_we_office AND p.full_name = 'Marla Johnston');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0433: expected Keith Chitwood on Blue Ridge Place 5 and Marla Johnston on '
      'Weston Place 5; matched % of 2. The rosters cited in the header name those two people.', v_n;
  END IF;

  -- 3. Each target district must be the city-wide seat its siblings already use: right layer,
  --    and exactly one geofence row, or address search still cannot answer.
  FOR v_rec IN
    SELECT d.id, d.label, d.district_type, d.mtfcc,
           (SELECT count(*) FROM essentials.geofence_boundaries gb
             WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc) AS fences,
           (SELECT count(*) FROM essentials.offices o2 WHERE o2.district_id = d.id) AS offices
      FROM essentials.districts d
     WHERE d.id IN (v_br_dist, v_we_dist)
  LOOP
    IF v_rec.district_type <> 'LOCAL' OR v_rec.mtfcc <> 'G4110' THEN
      RAISE EXCEPTION 'CC_0433: district % is %/%, expected LOCAL/G4110.',
        v_rec.id, v_rec.district_type, v_rec.mtfcc;
    END IF;
    IF v_rec.fences <> 1 THEN
      RAISE EXCEPTION 'CC_0433: district % (%) has % geofence rows, expected exactly 1. Pointing '
        'an office at a district with no boundary leaves it just as unreachable.',
        v_rec.id, v_rec.label, v_rec.fences;
    END IF;
    IF v_rec.offices <> 5 THEN
      RAISE EXCEPTION 'CC_0433: district % (%) already holds % offices, expected the 5 (Mayor + '
        'Places 1-4) measured when this file was written.', v_rec.id, v_rec.label, v_rec.offices;
    END IF;
  END LOOP;

  -- 4. 🔴 LOWRY CROSSING MUST BE UNTOUCHED GOING IN. Its four seats are the ones this file is
  --    deliberately NOT fixing, and they are the control that one symptom is not being treated
  --    as one class. If something has already repointed them at a city-wide district, that is
  --    the error the header argues against and it must be seen, not merged over.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.name = 'City of Lowry Crossing, Texas, US' AND o.district_id IS NULL;
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0433: expected Lowry Crossing to still have 4 district-less offices; '
      'found %. Read the header: those four need WARD POLYGONS, not the city-wide district.', v_n;
  END IF;
END $$;

-- ── Change ───────────────────────────────────────────────────────────────────────────────────
-- Idempotent: the WHERE clause is false once the row has been pointed.
UPDATE essentials.offices
   SET district_id = '19e78414-c7c5-420e-a858-ab96c4125e7e'
 WHERE id = '79ad986b-8e55-4ea1-8970-7c5b4b83f5ba'
   AND district_id IS NULL;

UPDATE essentials.offices
   SET district_id = '68755158-a11d-4b78-97ac-751661d10ded'
 WHERE id = '93c204ca-9a24-4027-8952-811ca792a088'
   AND district_id IS NULL;

-- ── Post-verify ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_br_office uuid := '79ad986b-8e55-4ea1-8970-7c5b4b83f5ba';
  v_we_office uuid := '93c204ca-9a24-4027-8952-811ca792a088';
  v_rec       record;
  v_n         int;
  v_hit       int;
BEGIN
  -- 1. Both rows point where the header says.
  SELECT count(*) INTO v_n FROM essentials.offices
   WHERE (id = v_br_office AND district_id = '19e78414-c7c5-420e-a858-ab96c4125e7e')
      OR (id = v_we_office AND district_id = '68755158-a11d-4b78-97ac-751661d10ded');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0433: expected both offices repointed; % of 2.', v_n;
  END IF;

  -- 2. 🔴 THE CLAIM IS "A VOTER CAN NOW REACH THEM", SO MEASURE THAT, NOT THE COLUMN.
  --    Probe each city at an interior point of its OWN geofence, the same way the before-state
  --    was measured. Six offices, and the Place 5 holder must be one of them BY NAME — a count
  --    alone would pass if the join returned some other row.
  FOR v_rec IN
    SELECT 'Blue Ridge'::text AS city, v_br_office AS office, '4808872'::text AS geoid,
           'Keith Chitwood'::text AS who
    UNION ALL
    SELECT 'Weston', v_we_office, '4877740', 'Marla Johnston'
  LOOP
    SELECT count(*), count(*) FILTER (WHERE p.full_name = v_rec.who AND o.id = v_rec.office)
      INTO v_n, v_hit
      FROM essentials.geofence_boundaries src
      CROSS JOIN LATERAL (SELECT ST_PointOnSurface(src.geometry) AS p) pt
      JOIN essentials.geofence_boundaries gb ON ST_Covers(gb.geometry, pt.p)
      JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.chambers ch ON ch.id = o.chamber_id
      JOIN essentials.governments g ON g.id = ch.government_id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE src.mtfcc = 'G4110' AND src.geo_id = v_rec.geoid
       AND g.name = 'City of ' || v_rec.city || ', Texas, US';

    IF v_n <> 6 THEN
      RAISE EXCEPTION 'CC_0433: an address inside % returns % of this city''s offices, expected 6 '
        '(Mayor + Places 1-5). It returned 5 before this migration.', v_rec.city, v_n;
    END IF;
    IF v_hit <> 1 THEN
      RAISE EXCEPTION 'CC_0433: % returns 6 offices but % is not among them on the repointed row '
        '— the count is right and the rows are wrong.', v_rec.city, v_rec.who;
    END IF;
  END LOOP;

  -- 3. 🔴 GATE ON THE DELTA THIS TRANSACTION CREATES, not on a repo-wide total another session
  --    can move while this file is being written (CLAUDE.md). Six held offices carried a NULL
  --    district when this was researched; this file resolves exactly the two in these two cities.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE o.district_id IS NULL
     AND och.politician_id IS NOT NULL
     AND g.name IN ('City of Blue Ridge, Texas, US', 'City of Weston, Texas, US');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0433: % held offices in Blue Ridge/Weston still have no district.', v_n;
  END IF;

  -- 4. And the four this file refuses to touch are still exactly as they were.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.name = 'City of Lowry Crossing, Texas, US' AND o.district_id IS NULL;
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0433: Lowry Crossing must still have its 4 district-less offices; found '
      '%. This file must not have touched them.', v_n;
  END IF;

  -- 5. Nothing else moved: each city-wide district gained exactly one office and no more.
  SELECT count(*) INTO v_n FROM essentials.offices
   WHERE district_id IN ('19e78414-c7c5-420e-a858-ab96c4125e7e',
                         '68755158-a11d-4b78-97ac-751661d10ded');
  IF v_n <> 12 THEN
    RAISE EXCEPTION 'CC_0433: expected 12 offices across the two city-wide districts (6 each); '
      'found %.', v_n;
  END IF;
END $$;

COMMIT;
