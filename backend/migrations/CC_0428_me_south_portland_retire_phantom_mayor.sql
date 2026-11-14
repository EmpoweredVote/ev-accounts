-- CC_0428: South Portland, Maine -- retire a phantom Mayor office. The charter says the council
--          is SEVEN; we held EIGHT, and the eighth was a second row for a councillor who already
--          had her seat.
--
-- The last of the three Maine rows `CC_0427` left open. `CC_0427` could not settle it because
-- library.municode.com serves this charter from a JavaScript shell and answers curl with ~7.5 KB
-- of nothing. 🟢 THE CITY'S OWN DOCUMENTCENTER CARRIES THE SAME CHARTER AS A PLAIN PDF, and plain
-- curl gets it. ▶ Before reaching for a browser, look for the publisher's own copy -- the
-- aggregator is often the only thing that needs one.
--
-- ═══ WHAT THE CITY SAYS (both sources committed under
--     backend/data/seed-me-municipal-2026/sources/) ═══
-- Charter, me-south-portland-charter-2026-11-14.txt -- 146,601 characters extracted, 9 "mayor":
--   "...shall be and are vested in one body of 7 members which shall constitute and be called the
--    city council..."
--   "The city council shall be composed of 7 members, each of whom shall be elected by the
--    registered voters of the entire city."
--   "Immediately after being sworn into office... the council shall elect, by majority vote of the
--    entire council, ONE OF ITS MEMBERS for the ensuing year as a chairman of the council..."
--   "The chairman of the council shall also be designated as mayor but shall have NO POWERS OR
--    DUTIES in such capacity other than those expressly recited in this section..."
-- Council page, me-south-portland-council-roster-2026-11-14.txt:
--   "The City Council consists of seven members who are elected to serve staggered three-year
--    terms. In addition to two At Large Councilors, there are five Councilors representing each of
--    the five City districts."
--   and it lists SEVEN people, one of them as "Elyse Tipton -- Mayor, District Five".
--
-- 🔴 THE CITY WRITES THE ROTATING ROLE AS A PARENTHETICAL ON THE SEAT, WHICH IS EXACTLY WHAT
--    ROSTERS.md R5 SAYS TO DO. "Mayor, District Five" is one row on their page and was two rows in
--    our schema. R8b had to recover this from Bath's contact addresses; South Portland prints it.
--
-- ═══ 🔴🔴 THE SAME DEFECT, THE OPPOSITE FIX -- AND THE DISCRIMINATOR IS ONE COUNT ═══
-- `CC_0427` retitled Bangor's `Mayor` into `Council Member (At-Large 9)`. This file DELETES South
-- Portland's. Both cities had a rotating chair modelled as an office; the fixes are opposites, and
-- choosing wrongly would damage a real seat either way.
--
--   Bangor           9 offices, 9 holders, NINE DISTINCT PEOPLE. The Mayor row was the ninth
--                    councillor's only seat. Deleting it would have UNSEATED a sitting member.
--                    -> RETITLE.
--   South Portland   8 offices, 8 holder rows, SEVEN DISTINCT PEOPLE. Elyse Tipton holds the Mayor
--                    row AND `Council Member (District 5)`. Retitling would have invented an
--                    eighth seat on a seven-member council and seated her in it twice.
--                    -> DELETE.
--
-- ▶ **ASK HOW MANY DISTINCT PEOPLE HOLD THE BODY'S OFFICES, NOT HOW MANY OFFICES ARE FILLED.**
--   Both councils read "every seat occupied". The counts that separate them are `count(DISTINCT
--   politician_id)` against the charter's number, and nothing in this repo computes that.
--
-- ═══ WHAT A VOTER SEES TODAY, MEASURED ON THE LIVE ENDPOINT ═══
-- A South Portland address returns EIGHT council rows, two of them the same person:
--   Elyse Tipton | Mayor                       | is_elected=false
--   Elyse Tipton | Council Member (District 5) | is_elected=true
-- So the duplicate is not theoretical, and the phantom row is also the one published as NOT
-- ELECTED (`is_elected` is `NOT is_appointed_position`). After this she appears once, correctly.
--
-- ⚠ AND THAT MEASUREMENT CORRECTS THIS REPO'S OWN NOTES. ROSTERS.md R11 says address search shows
--   AT MOST ONE SEAT PER PERSON and lists Tipton as a dual-seat control returning "1 row". It
--   returns two. The de-duplication key moved from the PERSON to the OFFICE on 2026-10-26
--   (`OFFICE_DEDUP_KEY = 'o.id'`, CLAUDE.md), the same day R11 was written. R11's table is stale
--   and is corrected in this file's ROSTERS.md change. 🔴 A NOTE THAT RECORDS A BUG OUTLIVES THE
--   BUG FIX -- re-measure a hazard before relying on it.
--
-- ═══ 🔴 DELETING AN OFFICE: THE TWO THINGS THAT CORRUPT IN SILENCE ═══
-- CLAUDE.md names both, and both are live here. Measured before writing:
--   1. `office_terms.office_id` is ON DELETE CASCADE. The delete eats Tipton's MAYOR term
--      (8b73b5ec-...), which is correct and intended -- it is not her council tenure. Her
--      District 5 term (970345ad-...) is a different row and must survive. Gated below.
--   2. `politicians.office_id` has NO FOREIGN KEY, and Tipton's snapshot points AT THE MAYOR
--      OFFICE. Deleting without repointing leaves it dangling and nothing complains. It is
--      repointed to District 5 FIRST.
-- Nothing else refers to the office: zero races (measured), and `essentials.districts` keeps its
-- other seven offices so no geography is emptied.
--
-- ═══ 🔴 VALUES OVERWRITTEN OR DESTROYED -- NO HISTORY TABLE FOR ANY OF THEM ═══
--
--   DELETED ROW, essentials.offices 411f3897-8727-4c01-9100-1f714a543308, in full:
--     title 'Mayor' · chamber_id 7549810c-ea17-420f-b60a-d9bdd7718dfa ·
--     district_id 89783302-1710-4470-9288-76188a881890 · representing_state 'ME' ·
--     voting_powers 'full' · role_canonical 'MAYOR' · is_appointed_position true ·
--     is_vacant false · faces_retention_vote false ·
--     seats, salary, description, vacant_since, partisan_type, representing_city,
--     representation_note, normalized_position_name all NULL.
--
--   DELETED BY CASCADE, essentials.office_terms 8b73b5ec-fb98-49d4-81a3-981c11df8a88, in full:
--     office_id 411f3897-... · politician_id b13ef429-452f-4aed-96b2-173f15c20b93 (Elyse Tipton) ·
--     term_start NULL · term_end NULL · start_precision 'unknown' · how_started NULL ·
--     how_ended NULL · created_at 2026-07-26T01:09:06.415146+00:00 ·
--     source 'backfill from essentials.offices.politician_id (ADR 0002 phase 2, migration 1459)'
--     ⚠ It dates nothing: an unknown-precision backfill row. No fact is lost with it.
--
--   politicians b13ef429-452f-4aed-96b2-173f15c20b93 (Elyse Tipton)
--     office_id  411f3897-8727-4c01-9100-1f714a543308  ->  81be9a52-3f5f-495f-9181-0a787d97403c
--                (the deprecated point-in-time snapshot, repointed to her District 5 seat)
--
--   chambers 7549810c-ea17-420f-b60a-d9bdd7718dfa  (South Portland City Council)
--     official_count  8  ->  7                      (charter: "one body of 7 members")
--     ⚠ The 8 was never independently sourced -- it equalled our own office count, so it
--       CONFIRMED the defect instead of catching it. 🔴 A SIZE COPIED FROM THE ROWS IT IS MEANT
--       TO CHECK IS NOT A CHECK. Bangor's 9 was right and agreed with its charter; this 8 agreed
--       with nothing but itself.
--
-- ═══ 🔴 FOUND BY THIS FILE'S OWN GATE FAILING: MAINE HAS NO COUNTY GOVERNMENT AT ALL ═══
-- The reachability gate below was first written unscoped and the dry run refused the migration,
-- reporting "16 districts holding no office". All 16 are Maine's COUNTY rows -- Androscoggin
-- through York, every county in the state -- each a district with a polygon and ZERO offices.
-- Maine county government has never been seeded.
--
-- ⚠ NOTHING IN CI CAN SEE THIS, AND IT IS THE SAME BLIND SPOT `CC_0426` NAMED. `DEAD_GEOGRAPHY`
--   requires `offices > 0`, so a district with none is not a finding; `offices_missing_terms`
--   starts FROM offices, so no office means no row; and the drift baseline therefore cannot move.
--   An office with no race is invisible rather than incomplete (CLAUDE.md) -- a DISTRICT WITH NO
--   OFFICE is invisible the same way, one level up. ▶ Written up in ROSTERS.md; not this file's
--   job, and sixteen counties is a wave.
-- 🟢 The gate being WRONG is how this was found. A check scoped by analogy rather than by
--    measurement failed loudly against real data before anything was applied, which is the
--    cheapest possible way to learn that Maine has a whole tier missing.
--
-- ═══ ⚪ STILL NOT DONE, AND DELIBERATELY ═══
-- Lewiston Public Schools `School Committee Member (Ward 5)` (Lynnea Hawkins) keeps its appointed
-- flag. The committee publishes its membership as an IMAGE -- no "Ward" string on the page at all
-- -- so nothing there says whether the flag describes the office or records how one person
-- arrived in it, and those want opposite fixes. See ROSTERS.md R9i.
--
-- Nothing here seats or unseats anybody: Tipton keeps her District 5 seat and its term row, and
-- the other six councillors are untouched.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 0. Pin the row by the fact that makes DELETE the right verb: its holder already has a seat.
--    If Tipton did NOT hold District 5, this office would be somebody's only seat and deleting it
--    would unseat a sitting councillor -- which is Bangor's case, and Bangor was retitled.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_distinct integer; v_offices integer;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_current_holder och
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE och.office_id = '411f3897-8727-4c01-9100-1f714a543308' AND p.full_name = 'Elyse Tipton'
  ) THEN RAISE EXCEPTION 'CC_0428: the Mayor office is not held by Elyse Tipton.'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_current_holder och
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE och.office_id = '81be9a52-3f5f-495f-9181-0a787d97403c' AND p.full_name = 'Elyse Tipton'
  ) THEN
    RAISE EXCEPTION 'CC_0428: Elyse Tipton does NOT hold District 5 -- deleting the Mayor office would unseat her. Retitle instead (see Bangor, CC_0427).';
  END IF;

  SELECT count(*), count(DISTINCT och.politician_id) INTO v_offices, v_distinct
    FROM essentials.offices o
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.chamber_id = '7549810c-ea17-420f-b60a-d9bdd7718dfa';
  IF v_offices <> 8 OR v_distinct <> 7 THEN
    RAISE EXCEPTION 'CC_0428: expected 8 offices held by 7 distinct people; found % and %.', v_offices, v_distinct;
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 1. 🔴 REPOINT THE FK-LESS SNAPSHOT BEFORE THE DELETE, or it dangles without complaint.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.politicians
   SET office_id = '81be9a52-3f5f-495f-9181-0a787d97403c'   -- Council Member (District 5)
 WHERE id = 'b13ef429-452f-4aed-96b2-173f15c20b93'
   AND office_id = '411f3897-8727-4c01-9100-1f714a543308';

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 2. Retire the phantom. Its one office_terms row goes with it, ON DELETE CASCADE.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DELETE FROM essentials.offices WHERE id = '411f3897-8727-4c01-9100-1f714a543308';

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 3. State the council's real size, from the charter rather than from our own row count.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.chambers
   SET official_count = 7
 WHERE id = '7549810c-ea17-420f-b60a-d9bdd7718dfa';

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- POST-VERIFY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_offices   integer;
  v_distinct  integer;
  v_titled    integer;
  v_named     integer;
  v_tipton    integer;
  v_count     integer;
  v_me_scope  integer;
  v_me_flag   integer;
  v_state_exec integer;
  v_me_dead   integer;
  v_me_scope_d integer;
  v_unflagged integer;
BEGIN
  -- Seven offices, seven people, one each, no role worn as a title.
  SELECT count(*), count(DISTINCT och.politician_id),
         count(*) FILTER (WHERE o.title LIKE 'Council Member (%')
    INTO v_offices, v_distinct, v_titled
    FROM essentials.offices o
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.chamber_id = '7549810c-ea17-420f-b60a-d9bdd7718dfa';
  IF v_offices <> 7 OR v_titled <> 7 THEN
    RAISE EXCEPTION 'CC_0428: South Portland holds % offices of which % are council seats; the charter says 7 and 7.', v_offices, v_titled;
  END IF;
  IF v_distinct <> 7 THEN
    RAISE EXCEPTION 'CC_0428: the 7 seats are held by % distinct people.', v_distinct;
  END IF;

  -- The seven the city lists, each on the seat it lists them on.
  SELECT count(*) INTO v_named
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
    JOIN essentials.offices o ON o.id = och.office_id
   WHERE o.chamber_id = '7549810c-ea17-420f-b60a-d9bdd7718dfa'
     AND ((o.title = 'Council Member (District 1)' AND p.full_name = 'Carter Scott')
       OR (o.title = 'Council Member (District 2)' AND p.full_name = 'Rachael Coleman')
       OR (o.title = 'Council Member (District 3)' AND p.full_name = 'Misha C. Pride')
       OR (o.title = 'Council Member (District 4)' AND p.full_name = 'Jessica L. Walker')
       OR (o.title = 'Council Member (District 5)' AND p.full_name = 'Elyse Tipton')
       OR (o.title = 'Council Member (At-Large 1)' AND p.full_name = 'Richard T. Matthews')
       OR (o.title = 'Council Member (At-Large 2)' AND p.full_name = 'Natalie West'));
  IF v_named <> 7 THEN
    RAISE EXCEPTION 'CC_0428: % of the 7 councillors the city lists sit on the seat it lists them on.', v_named;
  END IF;

  -- 🔴 Tipton keeps her seat and her term. The delete must have eaten the mayoralty and nothing else.
  SELECT count(*) INTO v_tipton
    FROM essentials.office_current_holder och
   WHERE och.politician_id = 'b13ef429-452f-4aed-96b2-173f15c20b93';
  IF v_tipton <> 1 THEN
    RAISE EXCEPTION 'CC_0428: Elyse Tipton now holds % current seats, not 1.', v_tipton;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms
                  WHERE id = '970345ad-6a2b-4292-ab1b-7d94225ba48e'
                    AND office_id = '81be9a52-3f5f-495f-9181-0a787d97403c'
                    AND politician_id = 'b13ef429-452f-4aed-96b2-173f15c20b93') THEN
    RAISE EXCEPTION 'CC_0428: the CASCADE took Tipton''s DISTRICT 5 term -- the wrong row.';
  END IF;

  -- 🔴 Nothing dangles: no term, and no FK-less snapshot, still points at the deleted office.
  IF EXISTS (SELECT 1 FROM essentials.office_terms WHERE office_id = '411f3897-8727-4c01-9100-1f714a543308') THEN
    RAISE EXCEPTION 'CC_0428: an office_terms row still points at the deleted office.';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE office_id = '411f3897-8727-4c01-9100-1f714a543308') THEN
    RAISE EXCEPTION 'CC_0428: politicians.office_id still points at the deleted office -- it has no FK and would never have errored.';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.offices WHERE id = '411f3897-8727-4c01-9100-1f714a543308') THEN
    RAISE EXCEPTION 'CC_0428: the Mayor office still exists.';
  END IF;

  SELECT official_count INTO v_count FROM essentials.chambers WHERE id = '7549810c-ea17-420f-b60a-d9bdd7718dfa';
  IF v_count IS DISTINCT FROM 7 OR v_count <> v_offices THEN
    RAISE EXCEPTION 'CC_0428: the chamber states its size as %, against % offices; the charter says 7.', v_count, v_offices;
  END IF;

  -- Maine-wide: one office fewer, one appointed flag fewer, and the three correct ones untouched.
  SELECT count(*), count(*) FILTER (WHERE o.is_appointed_position)
    INTO v_me_scope, v_me_flag
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me';
  IF v_me_scope <> 432 THEN
    RAISE EXCEPTION 'CC_0428: Maine holds % offices; expected 432 (433 minus this one).', v_me_scope;
  END IF;
  IF v_me_flag <> 4 THEN
    RAISE EXCEPTION 'CC_0428: Maine carries % appointed-flagged offices, not the 4 this file leaves.', v_me_flag;
  END IF;

  SELECT count(*) INTO v_state_exec
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me' AND d.district_type = 'STATE_EXEC'
     AND o.title IN ('Attorney General', 'Secretary of State', 'Treasurer')
     AND o.is_appointed_position = true;
  IF v_state_exec <> 3 THEN
    RAISE EXCEPTION 'CC_0428: % of the 3 legislature-chosen Maine state offices still carry the flag.', v_state_exec;
  END IF;

  -- 🔴 The master-only reachability gate, carried here. Maine has no bucket of any kind in
  --    address-reachability-baseline.json and that gate fires on any NEW one. Scoped to the two
  --    district types a MUNICIPAL migration can affect, and the scope is asserted so a zero
  --    cannot come back from an empty set.
  --    ⚠ THIS GATE WAS WRITTEN WRONG FIRST AND THE DRY RUN CAUGHT IT. Unscoped, it reported
  --      "16 districts holding no office" -- every Maine COUNTY row, a whole tier this repo has
  --      never seeded. Pre-existing, nothing to do with this file, and invisible to the real
  --      DEAD_GEOGRAPHY check because that one requires offices > 0. See the note in the header.
  SELECT count(*),
         count(*) FILTER (WHERE (offices > 0 AND active_holders = 0 AND vacant_offices = 0)
                             OR offices = 0)
    INTO v_me_scope_d, v_me_dead
    FROM (
      SELECT d.id, count(off.id) AS offices,
             count(*) FILTER (WHERE pp.is_active) AS active_holders,
             count(*) FILTER (WHERE off.is_vacant) AS vacant_offices
        FROM essentials.districts d
        LEFT JOIN essentials.offices off ON off.district_id = d.id
        LEFT JOIN essentials.office_current_holder och2 ON och2.office_id = off.id
        LEFT JOIN essentials.politicians pp ON pp.id = och2.politician_id
       WHERE lower(d.state) = 'me' AND d.representation_basis = 'residency'
         AND d.district_type IN ('LOCAL', 'SCHOOL')
       GROUP BY d.id
    ) s;
  IF v_me_scope_d < 28 THEN
    RAISE EXCEPTION 'CC_0428: the Maine municipal reachability check examined only % districts -- it is reading the wrong rows.', v_me_scope_d;
  END IF;
  IF v_me_dead <> 0 THEN
    RAISE EXCEPTION 'CC_0428: % Maine municipal district(s) now resolve nobody or hold no office; the master-only reachability gate would fire on the next PR.', v_me_dead;
  END IF;

  -- Retiring an office that HAD a term cannot move the drift baseline.
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 238 THEN
    RAISE EXCEPTION 'CC_0428: drift baseline reads %, not 238.', v_unflagged;
  END IF;

  RAISE NOTICE 'CC_0428 OK: South Portland is 7 council seats held by 7 people, no Mayor row, Tipton keeps District 5 and its term, nothing dangles, chamber states 7, Maine down to % offices and 4 flags (3 of them correct), drift baseline 238.', v_me_scope;
END $$;

COMMIT;
