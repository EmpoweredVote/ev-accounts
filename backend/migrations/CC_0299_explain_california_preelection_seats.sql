-- CC_0299: say what the 20 California seats flagged vacant actually are — seats first filled at
-- the election on 2026-11-03, in eight bodies part-way through a by-district conversion.
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- 🔴 THIS CORRECTS A DIAGNOSIS THIS REPO PUBLISHED EIGHT DAYS' WORK AGO, IN CC_0298 AND IN CLAUDE.md
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- `CC_0298` classified these 20 offices as "not vacant, a DUPLICATE SEAT" and wrote, in its own
-- header and into CLAUDE.md, that an At-Large row and a district row in these bodies are "the same
-- chair counted twice". **THAT WAS WRONG**, and it was wrong in a way that would have justified
-- deleting real offices.
--
-- What they actually are: eight Los Angeles County bodies converting from at-large to by-district
-- elections under the California Voting Rights Act, caught mid-conversion. The conversions are
-- STAGGERED across election cycles. The at-large rows are the last holdovers, still legitimately
-- in office; the empty district rows are their successors, on the ballot NEXT WEEK. Nothing is
-- counted twice — one set is being replaced by the other, on a published schedule.
--
-- 🟢 WHAT MADE THE DIFFERENCE WAS READING THE RACES, WHICH WERE IN OUR OWN DATABASE THE WHOLE TIME.
-- All 20 unseated offices carry exactly one race, every one dated 2026-11-03, with 1 to 5
-- candidates already filed. Almost no seated office in these bodies has a race. The counting
-- argument ("at-large + seated-district = body size") was true and still pointed at the wrong
-- conclusion; the race dates settled it in one query.
-- ▶ **A COUNT CAN BE RIGHT AND STILL MEAN SOMETHING ELSE. ASK WHAT IS ON THE BALLOT.**
--
-- Confirmed against three bodies' own records, independently of the race data:
--   · Azusa — Ordinance 2024-01 moved the city to by-district elections; Districts 2, 4 and 5
--     voted in November 2024 and Districts 1 and 3 vote in November 2026. That is EXACTLY our
--     data: Bow (D2), Avila (D4) and Gonzales (D5) seated, D1 and D3 empty with 2026 races.
--   · Santa Clarita — Districts 1 and 3 elected December 2024 (Ayala, Gibbs, both seated here);
--     the remaining three at-large seats convert at the 2026-11-03 election, which the city's
--     notice of election lists as Districts 2, 4 and 5. Again exactly our three empty rows.
--   · Montebello Unified — the district's own redistricting site: five members are elected
--     at-large today, and "Beginning in November 2026, voters will vote for one Board Member who
--     lives in their Trustee Area."
-- The other five bodies are not individually sourced here. This migration therefore asserts only
-- what is measured for all 20 — no holder, one race on 2026-11-03, seated at-large colleagues —
-- and says nothing about the legal mechanism in the text it writes.
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- WHY THIS WRITES A SENTENCE AND DOES NOT CLEAR THE FLAG
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- Unflagging would be the better voter-facing answer: an unseated, unflagged office is invisible
-- to address search (`buildStatewideQuery` ends `AND (p.is_active = true OR o.is_vacant = true)`),
-- so the card would simply stop appearing until the winner is seated.
--
-- 🔴 IT WOULD ALSO TURN THE MASTER-ONLY REACHABILITY GATE RED ON SOMEBODY ELSE'S MERGE.
-- `check-address-reachability.mjs` reports DEAD_GEOGRAPHY for a district with
-- `active_holders = 0 AND vacant_offices = 0`. The `is_vacant` flag is the ONLY thing keeping
-- these 20 out of it. Clearing it would create two NEW baseline buckets — ca|SCHOOL and ca|LOCAL,
-- neither of which exists in `address-reachability-baseline.json` today — and that gate fires on
-- any new bucket. It runs on master push, not on PRs, so the red would land on the next person to
-- merge anything. Operator's decision, 2026-10-26: explain now, seat in December.
--
-- So the flag stays and the seat gets a sentence. `office_description` already flows to the API —
-- `COALESCE(NULLIF(o.description, ''), pd_specific.description, pd_generic.description, '')` in
-- essentialsService.ts — and all 20 return an EMPTY string today, so nothing is displaced.
--
-- ⚠ WHETHER THE CARD RENDERS IT CANNOT BE CHECKED FROM THIS REPO. The essentials frontend is a
-- separate codebase and is not on this machine. This migration can prove the sentence reaches the
-- API, and does (live probe recorded in the PR); it cannot prove a voter sees it.
--
-- ⚠ AND IT IS A CORRECTION OF SCALE, TOO: a voter sees ONE of these empty chairs, not three. A
-- Montebello address resolves to the one trustee area containing the point, so it returns the five
-- at-large members plus Trustee Area 1 — measured, not assumed. CC_0298's write-up implied all
-- three showed at once.
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- ▶ THE REAL FIX IS A DECEMBER 2026 OPERATION, AND THIS IS NOT IT
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- After 2026-11-03 and the December swearing-in:
--   1. Seat the 20 winners (`essentials.seat_officeholder`), which clears is_vacant and drops
--      `offices_missing_terms` unflagged by up to 20.
--   2. Retire the at-large holdover offices in the bodies whose conversion then completes —
--      Azusa (2), Santa Clarita (3), Montebello (5 of 5, if all five areas are then seated).
--      Check each body: several conversions are staggered further and keep at-large seats.
--   3. DELETE THESE DESCRIPTIONS. They name a past election and become false the moment the
--      winner is seated. The post-verify of the seating migration should assert they are gone.
--
-- Measured 2026-10-26: 65 offices flagged is_vacant, 25 of them undated, 20 of those are these.
-- This migration changes no flag, no term, no district and no race.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 1. The twenty, and the sentence each one gets.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 KEYED ON (government, title), NOT ON A uuid LIST. These offices were created by a bulk
-- candidate load and carry no migration provenance, so a hand-copied uuid has nothing to check it
-- against. Matching on the body and the title is self-describing and the pre-flight asserts the
-- set resolves to exactly 20 rows that are all flagged, undated, unseated and race-bearing.
CREATE TEMP TABLE _seats ON COMMIT DROP AS
SELECT o.id AS office_id, g.name AS govt, o.title, d.geo_id,
       -- Only facts measured for every row: no holder, one 2026-11-03 race, seated at-large
       -- colleagues on the same body. No claim about the legal mechanism.
       'No one holds this seat yet. It is filled at the election on 3 November 2026, and the '
       || 'winner takes office in December 2026. Until then this area is represented by the '
       || cnt.at_large::text || ' at-large members of the '
       -- "City of Azusa" + " City Council" reads "City of Azusa City Council", so the prefix goes
       -- too. Rendered and read before applying — the first draft shipped that exact stutter.
       || CASE
            WHEN g.name LIKE 'City of %'
              THEN replace(replace(g.name, ', California, US', ''), 'City of ', '') || ' City Council'
            WHEN g.name LIKE 'Altadena Library%' THEN 'Altadena Library District Board of Trustees'
            ELSE replace(g.name, ', California, US', '') || ' board'
          END
       || ', who are listed alongside it.' AS new_description
  FROM essentials.governments g
  JOIN essentials.chambers  c ON c.government_id = g.id
  JOIN essentials.offices   o ON o.chamber_id = c.id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL (
    SELECT count(*) AS at_large
      FROM essentials.offices o2
      JOIN essentials.chambers c2 ON c2.id = o2.chamber_id
      JOIN essentials.office_current_holder och2 ON och2.office_id = o2.id
     WHERE c2.government_id = g.id
       AND o2.title LIKE '%(At-Large)%'
       AND och2.politician_id IS NOT NULL
  ) cnt
 WHERE o.is_vacant
   AND o.vacant_since IS NULL
   AND g.name IN ('Acton-Agua Dulce Unified, California, US',
                  'Altadena Library District, California, US',
                  'City of Azusa, California, US',
                  'City of Santa Clarita, California, US',
                  'Keppel Union Elementary, California, US',
                  'Montebello Unified, California, US',
                  'Palmdale Elementary, California, US',
                  'Paramount Unified, California, US');

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 2. Pre-flight.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad text;
BEGIN
  SELECT count(*) INTO n FROM _seats;
  IF n <> 20 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: expected 20 pre-election seats, found % — re-triage before '
                    'running; the 20 were classified one at a time', n;
  END IF;

  -- 🔴 THE CLAIM THE SENTENCE MAKES, ASSERTED BEFORE IT IS WRITTEN. Every one of these must have
  -- exactly one race, dated 2026-11-03. Without this the migration would cheerfully tell a voter
  -- an election date that is not on the ballot.
  SELECT string_agg(format('%s / %s: %s race(s), dates %s',
                           s.govt, s.title, q.n, coalesce(q.dates, '<none>')), E'\n  ')
    INTO bad
    FROM _seats s
    CROSS JOIN LATERAL (
      SELECT count(*) AS n,
             string_agg(DISTINCT e.election_date::text, ',') AS dates
        FROM essentials.races r
        LEFT JOIN essentials.elections e ON e.id = r.election_id
       WHERE r.office_id = s.office_id
    ) q
   WHERE q.n <> 1 OR q.dates IS DISTINCT FROM '2026-11-03';
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'PRE-FLIGHT: a seat does not have exactly one 2026-11-03 race:%s  %s',
      E'\n  ', bad;
  END IF;

  -- No holder, now or ever. A seat with a term row is not a seat awaiting its first election.
  SELECT string_agg(format('%s / %s', s.govt, s.title), ', ') INTO bad
    FROM _seats s
   WHERE EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = s.office_id);
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'PRE-FLIGHT: seat has term history, so it is not awaiting a first election: %',
      bad;
  END IF;

  -- 🔴 NOTHING IS OVERWRITTEN. All 20 carry an empty description today; if one has gained text
  -- since measurement, stop rather than discard somebody else's sentence.
  SELECT string_agg(format('%s / %s: %L', s.govt, s.title, left(o.description, 60)), ', ')
    INTO bad
    FROM _seats s JOIN essentials.offices o ON o.id = s.office_id
   WHERE coalesce(o.description, '') <> '';
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'PRE-FLIGHT: description already set, refusing to overwrite: %', bad;
  END IF;

  -- The sentence names a count of at-large colleagues. If a body has none, the sentence is false.
  SELECT string_agg(format('%s / %s', s.govt, s.title), ', ') INTO bad
    FROM _seats s
   WHERE s.new_description LIKE '%by the 0 at-large%';
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'PRE-FLIGHT: body has no seated at-large member, so the sentence would be '
                    'false for: %', bad;
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 3. Snapshot, in this transaction, for a delta gate.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices WHERE is_vacant)                              AS vac_total,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NULL)     AS undated,
       (SELECT count(*) FROM essentials.offices WHERE coalesce(description,'') <> '')         AS with_descr,
       (SELECT count(*) FROM essentials.office_terms)                                         AS terms_total,
       (SELECT count(*) FROM essentials.races)                                                AS races_total,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant)              AS omt_unflagged,
       (SELECT count(*) FROM _seats s JOIN essentials.offices o ON o.id = s.office_id
         WHERE coalesce(o.description,'') = '')                                               AS to_write;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 4. Write. One column, 20 rows.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.offices o
   SET description = s.new_description
  FROM _seats s
 WHERE o.id = s.office_id
   AND coalesce(o.description, '') = '';   -- idempotent: a re-run writes nothing

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 5. Post-verify.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE b record; bad text; n int;
BEGIN
  SELECT * INTO b FROM _before;

  -- (a) Every seat carries its sentence, and the sentence names the right election.
  SELECT string_agg(format('%s / %s', s.govt, s.title), ', ') INTO bad
    FROM _seats s JOIN essentials.offices o ON o.id = s.office_id
   WHERE o.description IS DISTINCT FROM s.new_description;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'POST-VERIFY: description not written as intended on: %', bad;
  END IF;

  SELECT count(*) INTO n
    FROM _seats s JOIN essentials.offices o ON o.id = s.office_id
   WHERE o.description NOT LIKE '%3 November 2026%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'POST-VERIFY: % seat(s) got a sentence that does not name the election date', n;
  END IF;

  -- (b) 🔴 THE FLAG IS UNTOUCHED. Clearing it is what would turn the master-only reachability
  --     gate red; this migration must not do it by accident.
  SELECT count(*) INTO n
    FROM _seats s JOIN essentials.offices o ON o.id = s.office_id
   WHERE o.is_vacant IS DISTINCT FROM true OR o.vacant_since IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'POST-VERIFY: % seat(s) are no longer flagged-and-undated — the flag must '
                    'stay until the winner is seated, or DEAD_GEOGRAPHY fires on master', n;
  END IF;

  IF (SELECT count(*) FROM essentials.offices WHERE is_vacant) IS DISTINCT FROM b.vac_total
     OR (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NULL)
          IS DISTINCT FROM b.undated THEN
    RAISE EXCEPTION 'POST-VERIFY: the vacant population moved (was % flagged / % undated)',
      b.vac_total, b.undated;
  END IF;

  -- (c) Exactly `to_write` descriptions appeared repo-wide. Catches a stray UPDATE that caught
  --     an office outside the eight bodies.
  IF ((SELECT count(*) FROM essentials.offices WHERE coalesce(description,'') <> '') - b.with_descr)
       IS DISTINCT FROM b.to_write THEN
    RAISE EXCEPTION 'POST-VERIFY: offices with a description rose by %, expected %',
      (SELECT count(*) FROM essentials.offices WHERE coalesce(description,'') <> '') - b.with_descr,
      b.to_write;
  END IF;

  -- (d) No term, race or occupancy-baseline movement. This migration writes prose, nothing else.
  IF (SELECT count(*) FROM essentials.office_terms) IS DISTINCT FROM b.terms_total THEN
    RAISE EXCEPTION 'POST-VERIFY: office_terms moved % -> %',
      b.terms_total, (SELECT count(*) FROM essentials.office_terms);
  END IF;
  IF (SELECT count(*) FROM essentials.races) IS DISTINCT FROM b.races_total THEN
    RAISE EXCEPTION 'POST-VERIFY: races moved % -> %',
      b.races_total, (SELECT count(*) FROM essentials.races);
  END IF;
  IF (SELECT count(*) FROM essentials.offices_missing_terms m
        JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant)
       IS DISTINCT FROM b.omt_unflagged THEN
    RAISE EXCEPTION 'POST-VERIFY: the unflagged occupancy baseline moved from %', b.omt_unflagged;
  END IF;

  -- (e) The 16 seats CC_0298 dated keep their dates and gain no prose. Different defect, different
  --     fix; mixing them would blur both.
  SELECT count(*) INTO n
    FROM essentials.offices
   WHERE is_vacant AND vacant_since IS NOT NULL AND coalesce(description,'') LIKE '%3 November 2026%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'POST-VERIFY: % dated vacancy(ies) got a pre-election sentence', n;
  END IF;

  RAISE NOTICE 'CC_0299 OK: % seat(s) explained; flag untouched (% flagged, % undated); '
               'unflagged occupancy baseline % unchanged',
    b.to_write, b.vac_total, b.undated, b.omt_unflagged;
END $$;

COMMIT;
