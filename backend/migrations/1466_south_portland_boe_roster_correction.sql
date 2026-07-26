-- 1466_south_portland_boe_roster_correction.sql
-- Correct the two GUESSED occupants that migration 265 seeded onto the South Portland (ME) Board of
-- Education. Idempotent. Requires 1458 + 1459 + 1461 + 1463 (occupancy lives in office_terms).
--
-- WHY. Migration 265's own header confesses both errors: "South Portland: ... D1=Susan Rauscher
--   [ASSUMED spsd.org blocked]; At-Large Jennifer Ryan [ASSUMED]". spsdme.org served a JS client
--   challenge at seed time, so the roster was reconstructed from news coverage and two seats were
--   filled from a STALE ballot rather than the current board. The site is readable now.
--
-- SOURCES.
--   [S1] https://www.spsdme.org/page/members-of-the-board — the district's own roster, read
--        2026-07-26. Six adult members, plus two student representatives (not officeholders, and
--        correctly absent from the DB):
--          Rosemarie DeAngelis  Board Chair                     Term Expires 2027
--          Tyler Smith          Board Vice Chair   District 2   Term Expires 2028
--          Daniel Feller                           District 1   Term Expires 2028
--          Claire Holman                           At-Large     Term Expires 2026
--          Eleni Richardson                        At-Large     Term Expires 2026
--          George Risch                            District 4   Term Expires 2027
--        District 5 is absent from the roster (vacant; Adrian Dowling resigned effective
--        2026-04-06). D5 is migration 1465's business and is deliberately UNTOUCHED here.
--   [S2] ballotpedia.org/South_Portland_School_Department,_Maine,_elections — Daniel J. Feller ran
--        in the District 1 general election of 2025-11-04; Eleni C. Richardson ran in the At-large
--        SPECIAL general election the same day.
--   [S3] pressherald.com 2022-11-09, "Election results in South Portland and Cape Elizabeth" —
--        District 1: Susan W. Rauscher 6,426, Martha A. Riehle 3,906.
--   [S4] pressherald.com 2023-11-08, "Election results in South Portland" — two At-Large seats:
--        Jennifer Ryan 3,525, Claire Holman 3,299, Eleni Richardson 3,251.
--   [S5] City of South Portland charter summary (Appendix C, southportland.gov DocumentCenter/860)
--        — Article IX: Board of Education is seven members, one from each of five voting districts
--        plus two elected at-large, on three-year staggered terms.
--   [S6] ballotpedia.org/Rosemarie_DeAngelis_and_Adrian_Dowling_recall,_South_Portland_School_
--        Department,_Maine_(2026) — spells the chair "DeAngelis".
--
-- WHAT ACTUALLY HAPPENED, since neither wrong name was an invented person.
--   District 1: Rauscher genuinely won D1 in Nov 2022 [S3] and served the 2022-2025 term. That term
--     EXPIRED, D1 was back on the 2025-11-04 ballot, and Daniel Feller won it [S1 + S2] — hence his
--     term expiring 2028. Migration 265 recorded a real officeholder who was three years out of date.
--   At-Large: Ryan and Holman won the two at-large seats in Nov 2023; Richardson LOST that race by
--     48 votes [S4]. Ryan then left mid-term, and Richardson took her unexpired term via the
--     2025-11-04 SPECIAL election [S2] — which is why Richardson's term expires 2026, the tail of
--     the 2023-2026 span. So the board's two at-large seats are held by Holman and Richardson.
--     Migration 265 kept the departed Ryan and omitted Holman entirely.
--
--   NOTE THE CONSEQUENCE for the at-large fix: Holman did NOT succeed Ryan — Richardson did, and
--   Richardson already occupies the other at-large row. The two at-large offices are untitled
--   duplicates ('Board Member') with nothing to tell them apart, so the seat migration 265
--   mis-assigned to Ryan simply IS Holman's seat. This is therefore an occupant correction, not a
--   hand-off, and no succession is written between them.
--
-- WHY NOT seat_officeholder()/vacate_office(). Both refuse a NULL date, by design — and no source
--   states when any of these terms BEGAN. [S1] publishes expiry years only; [S2]/[S3]/[S4] publish
--   election dates, and an election date is not a term start. South Portland inaugurates newly
--   elected *Councilors* on the first Monday in December (southportland.gov/552), and the board
--   reorganised in early December 2025, but nothing found says the Board of Education's terms
--   commence on that date, so deriving 2025-12-01 would be the same species of guess this migration
--   exists to undo. Per ADR 0002 the corrected terms therefore carry term_start NULL with
--   start_precision 'unknown' — exactly the shape 1459's backfill gave every other seat on this
--   board. The correction is about WHO, which is what was wrong; it claims nothing about WHEN.
--   FOLLOW-UP available to anyone who confirms the commencement rule: Rauscher -> Feller on D1 is a
--   real dated hand-off and Ryan -> Richardson on the other at-large seat is another, and both can
--   then be recorded properly with seat_officeholder().
--
-- ALSO: the chair's SPELLING, 'Rosemarie De Angelis' -> 'Rosemarie DeAngelis' (-890033). Her seat
--   and occupancy were always right; only the rendering of her surname was wrong.
--   The evidence is genuinely split, so this records which way and why:
--     FOR 'DeAngelis'  — the district's own roster [S1] and Ballotpedia [S6].
--     FOR 'De Angelis' — pressherald.com, consistently and across years: the 2024-11-06 result
--                        "South Portland elects Pride, Walker to council; De Angelis to school
--                        board", plus letters 2023-10-23, 2024-10-15 and 2024-10-24.
--   Resolved for the closed-up form: the body's own roster is the subject's official self-
--   presentation and an independent reference agrees with it, whereas the Press Herald usages are
--   one outlet's house style repeated — many citations, one source. Migration 265 took the name
--   from that coverage, which is how the space got in.
--   'Rosemarie De Angelis' is preserved in essentials.politician_name_aliases so the discovery
--   fuzzy-matcher still resolves the old form. NOTE what that does NOT cover: the Essentials
--   search path ILIKEs full_name/preferred_name/first_name/last_name and never consults aliases,
--   so a user searching the spaced form stops getting a hit. Accepted — the roster is the name
--   the public sees on the board's own page.
--
-- Rauscher (-890031) and Ryan (-890036) are kept as politician rows: they are real people who
--   really served. They are unseated and marked is_incumbent = false, not deleted.
--
-- New external_ids take the -8900 3x band migration 265 reserved for South Portland (it used
--   -890031..-890037; -890038 and -890039 are free).
BEGIN;

-- =============================================================================
-- Pre-flight: the chamber and all seven of its offices must exist
-- =============================================================================
DO $$
DECLARE
  v_chamber uuid;
  v_offices int;
BEGIN
  SELECT ch.id INTO v_chamber
    FROM essentials.chambers ch
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.name = 'South Portland Public Schools, Maine, US'
     AND ch.name = 'Board of Education';
  IF v_chamber IS NULL THEN
    RAISE EXCEPTION 'South Portland Board of Education chamber not found — migration 265 not applied?';
  END IF;

  -- Seven is a charter fact [S5], not an incidental count: five district seats plus two at-large.
  -- A vacancy (D5) empties a seat, it does not remove one, so this holds regardless of 1465.
  SELECT count(*) INTO v_offices FROM essentials.offices WHERE chamber_id = v_chamber;
  IF v_offices <> 7 THEN
    RAISE EXCEPTION 'expected 7 South Portland Board of Education offices per charter Article IX, '
                    'found % — re-verify the roster shape before correcting occupants', v_offices;
  END IF;
END $$;

-- =============================================================================
-- 1. The two officeholders migration 265 missed
-- =============================================================================
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed,
   is_vacant, is_incumbent, external_id)
VALUES
  (gen_random_uuid(), 'Daniel Feller', 'Daniel', 'Feller', NULL, true, false, false, true, -890038),
  (gen_random_uuid(), 'Claire Holman', 'Claire', 'Holman', NULL, true, false, false, true, -890039)
ON CONFLICT (external_id) DO NOTHING;

-- =============================================================================
-- 2. Retire the two stale occupants (real former members, not fabrications)
-- =============================================================================
UPDATE essentials.politicians
   SET is_incumbent = false
 WHERE external_id IN (-890031, -890036)   -- Rauscher (D1 2022-2025), Ryan (At-Large from 2023)
   AND is_incumbent IS DISTINCT FROM false;

-- =============================================================================
-- 3a. District 1: Rauscher -> Feller
-- =============================================================================
DO $$
DECLARE
  v_chamber   uuid;
  v_office    uuid;
  v_feller    uuid;
  v_rauscher  uuid;
  v_stale     uuid;
  v_holder    uuid;
BEGIN
  SELECT ch.id INTO v_chamber
    FROM essentials.chambers ch
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.name = 'South Portland Public Schools, Maine, US'
     AND ch.name = 'Board of Education';

  SELECT o.id INTO v_office
    FROM essentials.offices o
   WHERE o.chamber_id = v_chamber
     AND o.title = 'Board Member (District 1)';
  IF v_office IS NULL THEN
    RAISE EXCEPTION 'District 1 office not found in the South Portland Board of Education chamber';
  END IF;

  SELECT id INTO v_feller   FROM essentials.politicians WHERE external_id = -890038;
  SELECT id INTO v_rauscher FROM essentials.politicians WHERE external_id = -890031;
  IF v_feller IS NULL THEN
    RAISE EXCEPTION 'Daniel Feller (-890038) missing — step 1 did not insert';
  END IF;

  -- The term currently resolving as District 1's holder, whoever that is.
  SELECT t.id, t.politician_id INTO v_stale, v_holder
    FROM essentials.office_terms t
   WHERE t.office_id = v_office
     AND (t.term_start IS NULL OR t.term_start <= CURRENT_DATE)
     AND (t.term_end   IS NULL OR t.term_end   >= CURRENT_DATE);

  IF v_holder IS NOT DISTINCT FROM v_feller THEN
    RAISE NOTICE 'District 1 already seats Daniel Feller — nothing to do';
    RETURN;
  END IF;

  -- Refuse to touch anything other than the known-wrong Rauscher row: an unexpected occupant means
  -- someone corrected this seat differently and this migration's premise no longer holds.
  IF v_stale IS NOT NULL AND v_holder IS DISTINCT FROM v_rauscher THEN
    RAISE EXCEPTION 'District 1 is held by politician % — expected Susan Rauscher (%) or Daniel '
                    'Feller (%). Re-verify before overwriting.', v_holder, v_rauscher, v_feller;
  END IF;

  -- Drop the stale term rather than closing it: closing needs an end date, and no source gives one.
  -- Rauscher's 2022-2025 service is documented in this header, not fabricated into a dated span.
  IF v_stale IS NOT NULL THEN
    DELETE FROM essentials.office_terms WHERE id = v_stale;
  END IF;

  INSERT INTO essentials.office_terms
    (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
  VALUES (v_office, v_feller, NULL, NULL, 'unknown', 'elected',
          'migration 1466: spsdme.org/page/members-of-the-board (read 2026-07-26) + Ballotpedia '
          'South Portland School Department District 1 general election 2025-11-04');

  RAISE NOTICE 'District 1: Susan Rauscher unseated, Daniel Feller seated on office %', v_office;
END $$;

-- =============================================================================
-- 3b. At-Large: the seat mis-assigned to Ryan is Holman's
-- =============================================================================
DO $$
DECLARE
  v_chamber uuid;
  v_office  uuid;
  v_holman  uuid;
  v_ryan    uuid;
  v_stale   uuid;
BEGIN
  SELECT ch.id INTO v_chamber
    FROM essentials.chambers ch
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.name = 'South Portland Public Schools, Maine, US'
     AND ch.name = 'Board of Education';

  SELECT id INTO v_holman FROM essentials.politicians WHERE external_id = -890039;
  SELECT id INTO v_ryan   FROM essentials.politicians WHERE external_id = -890036;
  IF v_holman IS NULL THEN
    RAISE EXCEPTION 'Claire Holman (-890039) missing — step 1 did not insert';
  END IF;

  -- Already corrected? Holman holding either at-large row is success: the two are interchangeable.
  IF EXISTS (
    SELECT 1
      FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
     WHERE o.chamber_id = v_chamber
       AND o.title = 'Board Member'
       AND t.politician_id = v_holman
       AND (t.term_start IS NULL OR t.term_start <= CURRENT_DATE)
       AND (t.term_end   IS NULL OR t.term_end   >= CURRENT_DATE)
  ) THEN
    RAISE NOTICE 'An at-large seat already seats Claire Holman — nothing to do';
    RETURN;
  END IF;

  -- Identify the seat by its wrong occupant, not by position: both at-large offices share the
  -- title 'Board Member' and nothing else distinguishes them.
  SELECT t.id, t.office_id INTO v_stale, v_office
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
   WHERE o.chamber_id = v_chamber
     AND o.title = 'Board Member'
     AND t.politician_id = v_ryan
     AND (t.term_start IS NULL OR t.term_start <= CURRENT_DATE)
     AND (t.term_end   IS NULL OR t.term_end   >= CURRENT_DATE);

  IF v_office IS NULL THEN
    RAISE EXCEPTION 'no current at-large term for Jennifer Ryan (%) and none for Claire Holman '
                    'either — the at-large seats are in an unexpected state; re-verify before '
                    'writing', v_ryan;
  END IF;

  DELETE FROM essentials.office_terms WHERE id = v_stale;

  INSERT INTO essentials.office_terms
    (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
  VALUES (v_office, v_holman, NULL, NULL, 'unknown', 'elected',
          'migration 1466: spsdme.org/page/members-of-the-board (read 2026-07-26); at-large seat '
          'won 2023-11-07 per pressherald.com South Portland results, term expires 2026');

  RAISE NOTICE 'At-Large: Jennifer Ryan unseated, Claire Holman seated on office %', v_office;
END $$;

-- =============================================================================
-- 4. District 3: spell the chair's surname the way her own board does
-- =============================================================================
-- Guarded on the pre-change value, so a re-run touches 0 rows. Pattern follows migration 1380,
-- which is the precedent for a rename: politicians first, then the DENORMALISED race_candidates
-- copies (essentials.race_candidates carries its own full_name/last_name for challengers with no
-- politician record, and it does not follow a politicians UPDATE).
UPDATE essentials.politicians
   SET full_name = 'Rosemarie DeAngelis', last_name = 'DeAngelis'
 WHERE external_id = -890033
   AND full_name = 'Rosemarie De Angelis';

-- Migration 265 seeded no races for these school boards, so this is expected to be a no-op today.
-- It is here because it must not be forgotten if a race is ever attached to this seat.
UPDATE essentials.race_candidates rc
   SET full_name = 'Rosemarie DeAngelis', last_name = 'DeAngelis', updated_at = now()
 WHERE rc.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -890033)
   AND rc.full_name = 'Rosemarie De Angelis';

-- Keep the displaced form resolvable for the discovery fuzzy-matcher (precedent: migration 1450).
INSERT INTO essentials.politician_name_aliases (politician_id, alias, source)
SELECT p.id, 'Rosemarie De Angelis', 'migration 1466: spelling superseded by spsdme.org roster'
  FROM essentials.politicians p
 WHERE p.external_id = -890033
ON CONFLICT (politician_id, lower(alias)) DO NOTHING;

-- Leaving essentials.politicians.slug alone ON PURPOSE: it is a plain column, not GENERATED, and
-- it is NULL on this row (265 never set one), so nothing keys off it and there is nothing to
-- restale. Do not opportunistically populate it here.

-- =============================================================================
-- Post-verify gate
-- =============================================================================
DO $$
DECLARE
  v_chamber   uuid;
  v_expected  int;
  v_atlarge   int;
  v_stale     int;
  v_fanout    int;
  v_d5        text;
BEGIN
  SELECT ch.id INTO v_chamber
    FROM essentials.chambers ch
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.name = 'South Portland Public Schools, Maine, US'
     AND ch.name = 'Board of Education';

  -- 1. The four district seats resolve, through the view, to the right PEOPLE. Keyed on
  --    external_id, not full_name: identity is stable, spelling is not (the district writes
  --    "DeAngelis", migration 265 seeded "De Angelis" from news coverage).
  SELECT count(*) INTO v_expected
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.chamber_id = v_chamber
     AND (o.title, p.external_id) IN (
       ('Board Member (District 1)', -890038),   -- Daniel Feller      (corrected here)
       ('Board Member (District 2)', -890032),   -- Tyler Smith
       ('Board Member (District 3)', -890033),   -- Rosemarie DeAngelis
       ('Board Member (District 4)', -890034)    -- George Risch
     );
  IF v_expected <> 4 THEN
    RAISE EXCEPTION 'expected 4 correctly-seated district offices (D1 Feller, D2 Smith, D3 '
                    'DeAngelis, D4 Risch), found %', v_expected;
  END IF;

  -- 2. The two at-large seats are held by exactly Holman and Richardson, one each.
  SELECT count(*) INTO v_atlarge
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.chamber_id = v_chamber
     AND o.title = 'Board Member'
     AND p.external_id IN (-890039, -890037);   -- Claire Holman, Eleni Richardson
  IF v_atlarge <> 2 THEN
    RAISE EXCEPTION 'expected the 2 at-large seats to hold Claire Holman and Eleni Richardson, '
                    'found % such holders', v_atlarge;
  END IF;

  -- 2b. The chair's surname is spelled the district's way, and the old form survives as an alias.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.politicians
     WHERE external_id = -890033
       AND full_name = 'Rosemarie DeAngelis'
       AND last_name = 'DeAngelis'
  ) THEN
    RAISE EXCEPTION 'D3 chair -890033 is not spelled "Rosemarie DeAngelis" (full_name=%, '
                    'last_name=%)',
                    (SELECT full_name FROM essentials.politicians WHERE external_id = -890033),
                    (SELECT last_name FROM essentials.politicians WHERE external_id = -890033);
  END IF;
  IF NOT EXISTS (
    SELECT 1
      FROM essentials.politician_name_aliases a
      JOIN essentials.politicians p ON p.id = a.politician_id
     WHERE p.external_id = -890033
       AND lower(a.alias) = lower('Rosemarie De Angelis')
  ) THEN
    RAISE EXCEPTION 'the displaced spelling "Rosemarie De Angelis" was not preserved as an alias';
  END IF;

  -- 3. Neither stale name holds anything, anywhere.
  SELECT count(*) INTO v_stale
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.external_id IN (-890031, -890036);
  IF v_stale <> 0 THEN
    RAISE EXCEPTION 'Rauscher/Ryan still resolve as current holder on % office(s)', v_stale;
  END IF;

  -- 4. The exclusion constraint's promise: no office in this chamber has two current terms.
  SELECT count(*) INTO v_fanout FROM (
    SELECT t.office_id
      FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
     WHERE o.chamber_id = v_chamber
       AND (t.term_start IS NULL OR t.term_start <= CURRENT_DATE)
       AND (t.term_end   IS NULL OR t.term_end   >= CURRENT_DATE)
     GROUP BY t.office_id HAVING count(*) > 1
  ) f;
  IF v_fanout <> 0 THEN
    RAISE EXCEPTION '% office(s) in this chamber have more than one current term', v_fanout;
  END IF;

  -- 5. District 5 is migration 1465's business — report it, do not assert on it.
  SELECT coalesce(p.full_name, '(no holder)') INTO v_d5
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.chamber_id = v_chamber
     AND o.title = 'Board Member (District 5)';

  RAISE NOTICE 'South Portland BoE correction PASSED: D1 Feller, D2 Smith, D3 DeAngelis, D4 '
               'Risch, 2 at-large = Holman + Richardson; Rauscher/Ryan unseated. D5 currently % '
               '(left to migration 1465).', v_d5;
END $$;

COMMIT;
