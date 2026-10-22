-- CC_0283_westbrook_me_council_and_school_committee.sql
--
-- Seats all 15 elected offices of the City of Westbrook, Maine, and clears `is_vacant` on exactly
-- the seats it fills. Second Maine city; `CC_0282` (Augusta) set the pattern and
-- `backend/data/seed-me-municipal-2026/ROSTERS.md` is the ruling.
--
--   people created 15 · terms 15 · is_vacant cleared 15 · offices created 0
--   2 of the 15 are DATED to the day (both appointed to filled vacancies); 13 are 'unknown'
--
-- `offices_missing_terms`: before 415 / 176 / 239 → after **400 / 161 / 239**.
-- 🔴 Unflagged is unchanged at 239 and a gate asserts it. Total falls by exactly 15.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ 🟢 WESTBROOK IS NOT AUGUSTA, AND THE DIFFERENCES ARE THE POINT ═══
--
-- 1. **THE MAYOR IS NOT ON THE COUNCIL HERE.** Westbrook's own page: *"The Westbrook City Council
--    consists of SEVEN elected members, one from each of the five wards within the City, plus two
--    at-large members elected city-wide."* Augusta's says *"nine elected citizens, INCLUDING the
--    Mayor"*. Our schema already has it right in both cities — 8 council offices here (7 + Mayor),
--    9 there — so nothing needed changing. **It needed checking.**
--
-- 2. **THERE IS NO CHAIR OFFICE HERE, AND THAT IS ALSO CORRECT.** Augusta elects its school board
--    chair citywide, so `CC_0282` kept that office. Westbrook's council President and Vice
--    President are rotating roles — the city says *"The City Council President is elected by a
--    majority of the City Council"* — so they are NOT offices, and our schema correctly has none.
--    Jennifer Munro (Ward 5) is President and Michael Shaughnessy (At-Large) is Vice President;
--    both are recorded as parentheticals in ROSTERS.md, not as seats.
--    ▶ Two cities, opposite answers, both from reading the city's own words. The rotating-role
--    rule is right in general and must still be checked in particular.
--
-- 3. **Terms are THREE years, staggered** (Augusta's council is two). Nothing in this migration
--    depends on that, because no term length is stored — but it is why the roster dates come in
--    two waves, 2024 and 2025.
--
-- ═══ 🔴🔴 WESTBROOK PUBLISHES A "Date Elected" TABLE. IT IS A TERM SCHEDULE, NOT OCCUPANCY. ═══
-- The City Clerk's Elected Officials page gives every seat a **Date Elected** and a **Next
-- Election**, and the two are always exactly three years apart (11/4/25 → 11/7/28). That is the
-- CURRENT TERM, not the start of continuous occupancy.
--
-- 🔴 `term_start` is the start of continuous occupancy, and a re-election never opens a new
-- `office_terms` row. For anyone re-elected, "Date Elected" is their LATEST win, and writing it
-- would publish a false start date — the exact failure the house rule names. The table cannot
-- distinguish a first win from a re-election, and establishing that per person needs each city's
-- election archive going back in three-year steps.
-- ▶ **So the 13 elected members get `start_precision => 'unknown'`**, as Augusta's 18 did. The
-- table is recorded in ROSTERS.md as a term schedule for a later dating pass.
-- ⚠ **This warning is reusable: other Maine cities publish the same kind of table, and it will
-- look like free data every time.**
--
-- ═══ 🟢 BUT TWO SEATS ARE DATED TO THE DAY, BECAUSE A VACANCY BROKE CONTINUITY ═══
-- The same page carries two footnotes, and they are a different class of fact entirely:
--
--   * *"On October 8, 2025, Brittany Barr resigned from the School Committee. The School Committee
--     filled the vacancy on October 29, 2025 for the remainder of the term."*
--     → **Allison Brunette, School Committee At-Large: 2025-10-29, day, APPOINTED.**
--   * *"On December 1, 2025, the School Committee, At-Large seat became vacant as their were no
--     qualified candidates on the ballot in November 2025. The school committee filled the vacancy
--     on December 18, 2025."*
--     → **Flynn Ross, School Committee At-Large: 2025-12-18, day, APPOINTED.**
--
-- 🟢 **A VACANCY IS WHAT MAKES A DATE SAFE HERE.** Both seats were demonstrably EMPTY immediately
-- before these dates — Barr resigned, and the other seat had no qualified candidate. So whoever
-- sits there now began a NEW continuous occupancy on the day the committee filled it, and that
-- holds even if the appointee had sat on the committee before. The re-election ambiguity that
-- blocks the other 13 cannot arise.
-- ▶ `how_started = 'appointed'`, not 'elected'. Neither of these two won an election for this seat.
--
-- ═══ THE ROSTER (westbrookmaine.gov/323/City-Council and /200/Elected-Officials, read 2026-10-21) ═══
--   Mayor                David Morse
--   Council At-Large     Michael Shaughnessy (Vice President) · Gary Rairdon
--   Council Ward 1-5     Brian McCambridge · Victor Chau · Anna A. Turcotte ·
--                        Amy Faulkingham · Jennifer Munro (President)
--   School At-Large      Flynn Ross · Allison Brunette
--   School Ward 1-5      Katy Rice · Erin Cavallaro · Noreen Poitras ·
--                        Andrea Mancuso · Brooke Reed
--
-- ⚠ **KATY RICE IS NOT KATHY RICE.** The dedupe pass surfaced `Kathy Rice`, a sitting SOUTH DAKOTA
-- State Representative. Different first name, different state, different person — and note the
-- duplicate-name guard would NOT have caught it either way, because it keys on (first_name,
-- last_name) and "Katy" ≠ "Kathy". It is listed here because a one-letter difference is exactly
-- the shape that gets waved through.
-- 🟢 The pass was run with controls that FIRED: it found `Mark O'Brien` and `Martha Witham`, both
-- created by CC_0282 one migration earlier. Against the 15 Westbrook names it returns zero
-- collisions on the guard's own key.
--
-- ⚠ **ONE WESTBROOK ELECTED OFFICE IS NOT MODELLED AT ALL:** `Portland Water District Rep.`
-- (Malory Shaughnessy, elected 11/5/24). It is on the Clerk's list and we hold no office for it.
-- Creating it would mean modelling a regional water district that spans several municipalities —
-- out of scope for a seating migration. Recorded in ROSTERS.md.
-- ⚠ Michael Shaughnessy (council) and Malory Shaughnessy (water district) are different people.
--
-- Safe to re-run: every insert is guarded and the flag clear is idempotent.

BEGIN;

CREATE TEMP TABLE _roster (
  office_id     uuid NOT NULL,
  seat          text NOT NULL,
  full_name     text NOT NULL,
  first_name    text NOT NULL,
  last_name     text NOT NULL,
  term_start    date,
  precision     text NOT NULL,
  how_started   text NOT NULL,
  src           text NOT NULL,
  politician_id uuid
) ON COMMIT DROP;

INSERT INTO _roster (office_id, seat, full_name, first_name, last_name, term_start, precision, how_started, src) VALUES
-- ── City Council ──
('67212021-3450-407d-8f23-65758a2fc3be','Mayor','David Morse','David','Morse',NULL,'unknown','unknown','westbrookmaine.gov/200/Elected-Officials, read 2026-10-21; the published Date Elected 11/4/25 is the current TERM, not continuous occupancy (CC_0283)'),
('ac756d2f-8072-4d07-901a-6786ac15dcfc','Council At-Large 1','Michael Shaughnessy','Michael','Shaughnessy',NULL,'unknown','unknown','westbrookmaine.gov/323/City-Council and /200/Elected-Officials, read 2026-10-21; Council Vice President (a rotating role, not a seat); at-large seat number is ours (CC_0283)'),
('e303c648-4f0b-47f6-8db8-bf503e894785','Council At-Large 2','Gary Rairdon','Gary','Rairdon',NULL,'unknown','unknown','westbrookmaine.gov/323/City-Council and /200/Elected-Officials, read 2026-10-21; at-large seat number is ours (CC_0283)'),
('b681946f-b8bf-421c-926c-e04636b2edb6','Council Ward 1','Brian McCambridge','Brian','McCambridge',NULL,'unknown','unknown','westbrookmaine.gov/323/City-Council, read 2026-10-21 (CC_0283)'),
('8404009f-78e7-49b3-8b4f-f263845f6732','Council Ward 2','Victor Chau','Victor','Chau',NULL,'unknown','unknown','westbrookmaine.gov/323/City-Council, read 2026-10-21 (CC_0283)'),
('aea0040c-2d43-4454-b9ed-777358b8332d','Council Ward 3','Anna A. Turcotte','Anna A.','Turcotte',NULL,'unknown','unknown','westbrookmaine.gov/323/City-Council, read 2026-10-21 (CC_0283)'),
('9587bd36-2051-4729-83a2-5abc4ac90bed','Council Ward 4','Amy Faulkingham','Amy','Faulkingham',NULL,'unknown','unknown','westbrookmaine.gov/323/City-Council, read 2026-10-21 (CC_0283)'),
('b604a537-ed87-4b16-b32d-59d34d1353b8','Council Ward 5','Jennifer Munro','Jennifer','Munro',NULL,'unknown','unknown','westbrookmaine.gov/323/City-Council, read 2026-10-21; Council President (a rotating role, not a seat) (CC_0283)'),
-- ── School Committee ──
('293cc9b3-bf32-4e7a-8440-e09c4a3c138a','School At-Large 1','Flynn Ross','Flynn','Ross','2025-12-18','day','appointed','westbrookmaine.gov/200/Elected-Officials, read 2026-10-21: the At-Large seat became vacant 2025-12-01 with no qualified candidate on the November 2025 ballot, and the School Committee filled it on 2025-12-18 - a vacancy broke continuity, so this date is an occupancy start (CC_0283)'),
('72695dcc-2a50-44f1-905d-54c472019c51','School At-Large 2','Allison Brunette','Allison','Brunette','2025-10-29','day','appointed','westbrookmaine.gov/200/Elected-Officials, read 2026-10-21: Brittany Barr resigned 2025-10-08 and the School Committee filled the vacancy on 2025-10-29 for the remainder of the term - a vacancy broke continuity, so this date is an occupancy start (CC_0283)'),
('1c5afa63-8243-4e0a-83fb-2eb2a990a0bf','School Ward 1','Katy Rice','Katy','Rice',NULL,'unknown','unknown','westbrookmaine.gov/200/Elected-Officials, read 2026-10-21; NOT Kathy Rice, the South Dakota State Representative (CC_0283)'),
('a05e44b3-6ea1-4220-ae66-9b0b8d49ac93','School Ward 2','Erin Cavallaro','Erin','Cavallaro',NULL,'unknown','unknown','westbrookmaine.gov/200/Elected-Officials, read 2026-10-21 (CC_0283)'),
('8b0e158a-1d28-41f9-9268-cee05ce1d36d','School Ward 3','Noreen Poitras','Noreen','Poitras',NULL,'unknown','unknown','westbrookmaine.gov/200/Elected-Officials, read 2026-10-21 (CC_0283)'),
('e127a75d-eb9f-4d19-917b-1e21147f3133','School Ward 4','Andrea Mancuso','Andrea','Mancuso',NULL,'unknown','unknown','westbrookmaine.gov/200/Elected-Officials, read 2026-10-21 (CC_0283)'),
('6d54094e-ae05-43a4-a26c-6d8a7fa65304','School Ward 5','Brooke Reed','Brooke','Reed',NULL,'unknown','unknown','westbrookmaine.gov/200/Elected-Officials, read 2026-10-21 (CC_0283)');

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int;
BEGIN
  SELECT count(*) INTO n FROM _roster;
  IF n <> 15 THEN RAISE EXCEPTION 'CC_0283: expected 15 roster rows, found %', n; END IF;

  SELECT count(*) INTO bad FROM _roster r
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.offices o
       JOIN essentials.chambers c ON c.id = o.chamber_id
       JOIN essentials.governments g ON g.id = c.government_id
      WHERE o.id = r.office_id AND g.name = 'City of Westbrook, Maine, US');
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0283: % office id(s) are not Westbrook offices', bad; END IF;

  SELECT count(*) INTO bad FROM _roster r JOIN essentials.offices o ON o.id = r.office_id WHERE NOT o.is_vacant;
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0283: % Westbrook office(s) are already unflagged - an unflagged, unseated '
                    'office is a DEAD_GEOGRAPHY bucket. Investigate before seating', bad;
  END IF;

  SELECT count(*) INTO bad FROM _roster r
   WHERE EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id);
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0283: % Westbrook office(s) already carry a term', bad; END IF;

  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Westbrook, Maine, US';
  IF n <> 15 THEN RAISE EXCEPTION 'CC_0283: Westbrook holds % offices, expected 15', n; END IF;

  -- a dated row must be dated and an undated row must not be
  SELECT count(*) INTO bad FROM _roster
   WHERE (precision = 'unknown') <> (term_start IS NULL);
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0283: % row(s) disagree about having a date', bad; END IF;

  -- 🔴 exactly two dated, and both must be the APPOINTED vacancy fills - a date on an elected
  -- seat would mean someone read the Date Elected table as occupancy.
  SELECT count(*) INTO n FROM _roster WHERE term_start IS NOT NULL;
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0283: expected exactly 2 dated seats, found %', n; END IF;
  SELECT count(*) INTO bad FROM _roster WHERE term_start IS NOT NULL AND how_started <> 'appointed';
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0283: % dated seat(s) are not appointments - only the two vacancy fills '
                    'have a documented occupancy start; "Date Elected" is a TERM schedule', bad;
  END IF;

  SELECT count(*) INTO bad FROM _roster r
   WHERE EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
                    AND lower(btrim(p.last_name))  = lower(btrim(r.last_name)));
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0283: % name(s) collide with an existing person - the dedupe pass measured '
                    'ZERO against controls that fired. REFUSING', bad;
  END IF;

  SELECT count(*) INTO bad FROM (SELECT full_name FROM _roster GROUP BY full_name HAVING count(*) > 1) q;
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0283: % name(s) repeated within the batch', bad; END IF;
END $$;

-- ─── People ──────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, true, true, r.src FROM _roster r;

UPDATE _roster r SET politician_id = p.id
FROM essentials.politicians p
WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
  AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
  AND p.is_active;

-- ─── Seat them ───────────────────────────────────────────────────────────────────────────
-- The two dated appointments go through the helper; the 13 undated use its own column list,
-- because `seat_officeholder` refuses a NULL term_start by design.
DO $$
DECLARE r record; n_helper int := 0; n_direct int := 0;
BEGIN
  FOR r IN SELECT * FROM _roster ORDER BY seat LOOP
    IF r.politician_id IS NULL THEN
      RAISE EXCEPTION 'CC_0283: % did not resolve to a person', r.seat;
    END IF;
    IF r.term_start IS NOT NULL THEN
      PERFORM essentials.seat_officeholder(
        r.office_id, r.politician_id, r.term_start, r.src, r.how_started, r.precision);
      n_helper := n_helper + 1;
    ELSE
      IF NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id) THEN
        INSERT INTO essentials.office_terms
          (office_id, politician_id, term_start, start_precision, how_started, source)
        VALUES (r.office_id, r.politician_id, NULL, 'unknown', r.how_started, r.src);
      END IF;
      n_direct := n_direct + 1;
    END IF;
  END LOOP;
  IF n_helper <> 2 OR n_direct <> 13 THEN
    RAISE EXCEPTION 'CC_0283: expected 2 dated and 13 undated, got % and %', n_helper, n_direct;
  END IF;
END $$;

-- ─── 🔴 Clear the flag on exactly the seats filled, in the same transaction ───────────────
UPDATE essentials.offices o SET is_vacant = false, vacant_since = NULL
FROM _roster r WHERE o.id = r.office_id AND o.is_vacant;

-- ─── Post-verify ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int; v_unflagged int; v_total int;
BEGIN
  SELECT count(*) INTO n FROM _roster r
    JOIN essentials.office_terms t ON t.office_id = r.office_id AND t.politician_id = r.politician_id;
  IF n <> 15 THEN RAISE EXCEPTION 'CC_0283: expected 15 terms, found %', n; END IF;

  SELECT count(*) INTO bad FROM _roster r JOIN essentials.politicians p ON p.id = r.politician_id
   WHERE p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0283: % seated person(s) are not active incumbents', bad; END IF;

  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Westbrook, Maine, US' AND o.is_vacant;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0283: % Westbrook office(s) are still flagged vacant', bad; END IF;

  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Westbrook, Maine, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0283: % Westbrook office(s) are unflagged AND unseated - a new me|LOCAL '
                    'DEAD_GEOGRAPHY bucket that will redden the reachability gate', bad;
  END IF;

  -- 🔴 the global invariant, measured zero before Augusta and after it
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.is_vacant AND och.politician_id IS NOT NULL;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0283: % office(s) are seated AND flagged - the is_vacant trap', bad; END IF;

  SELECT count(*) FILTER (WHERE NOT o.is_vacant), count(*) INTO v_unflagged, v_total
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 239 THEN
    RAISE EXCEPTION 'CC_0283: unflagged offices_missing_terms is %, expected the 239 baseline', v_unflagged;
  END IF;
  IF v_total <> 400 THEN
    RAISE EXCEPTION 'CC_0283: total offices_missing_terms is %, expected 415 - 15 = 400', v_total;
  END IF;

  RAISE NOTICE 'CC_0283 OK - Westbrook 15 seated, 15 unflagged; missing_terms 400/161/239';
END $$;

DROP TABLE _roster;
COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THIS CITY ADDS: A PUBLISHED DATE IS ONLY AN OCCUPANCY START IF SOMETHING BROKE
-- CONTINUITY BEFORE IT.
-- Westbrook publishes a "Date Elected" for all 15 seats, and 13 of them are unusable: a
-- re-election never opens a new term row, so that column is the current TERM and would write a
-- false start for anyone re-elected. The two that ARE usable are usable precisely because the
-- seat was demonstrably EMPTY the day before — one resignation, one ballot with no qualified
-- candidate — so a new occupancy provably began when the committee filled it.
-- ▶ Ask what happened immediately BEFORE the date, not how authoritative the page is.
-- ───────────────────────────────────────────────────────────────────────────────────────────
