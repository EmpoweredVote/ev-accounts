-- CC_0059_san_jose_council_term_starts.sql
--
-- San José, CA — date all eleven council occupancies. Wave CA-2 of the Knight Foundation
-- cities program. Apply AFTER CC_0056 (the Santa Clara Board of Supervisors).
--
-- Spec:    docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
-- Roster:  backend/data/seed-santa-clara-2026/ROSTERS.md
-- Notes:   .planning/knight-foundation/ca.md
-- Tracker: .planning/knight-foundation/PROGRAM.md
--
-- ── WHAT IS WRONG ────────────────────────────────────────────────────────────────────────
-- All ELEVEN San José office_terms rows read:
--
--     term_start NULL, start_precision 'unknown', how_started NULL,
--     source 'backfill from essentials.offices.politician_id (ADR 0002 phase 2)'
--
-- The people are right and were re-confirmed today; nothing recorded WHEN any of them took
-- office, or that anyone had looked.
--
-- ── THE COMMENCEMENT RULE IS IN THE CHARTER, AND IT IS NOT WHAT THE REGISTRAR'S PAGE SAYS ─
-- 🔴 The Registrar's San José page states: "Term Begins: The jurisdiction will hold a meeting
--    following the completion of the canvass of votes to swear-in new members. Contact the
--    City Clerk's office ... (Elections Code § 10263(b))". Read alone that says there is no
--    fixed date — and for a REGULAR election, for this city, it is wrong. It is county-wide
--    boilerplate describing the ceremony.
--
-- 🟢 The instrument is the City Charter, and it is explicit. SECTION 1600:
--
--      "Each member's term shall commence on the first day of January next following, and end
--       on the last day of December in the fourth calendar year succeeding, the date of the
--       member's election"
--
--    and SECTION 500 for the Mayor: "for a term of four (4) years from and after the first
--    day of January following the year of the election", plus, in terms, "the term for the
--    office of Mayor beginning on January 1, 2023".
--
--    ⚠ BOTH ARE TRUE, FOR DIFFERENT CASES. The charter's 1 January governs a REGULAR
--      election. The Registrar's swearing-in-after-canvass governs a SPECIAL election, which
--      is exactly why District 3 below is dated in August and not in January.
--
-- ⚠ THE CA-2 RESEARCH RECORD INFERRED "1 January" FROM TWO LEGISTAR TURNOVERS THAT HAPPENED
--   TO LAND THERE. The conclusion was right and the reasoning was not: a pattern is not an
--   instrument. It is written down here from Section 1600 so nobody has to re-derive it.
--
-- ── SOURCES ─────────────────────────────────────────────────────────────────────────────
-- Every date below is a CERTIFIED RESULT plus the charter rule, cross-checked independently.
--
--   * Certified results: the Registrar's own Clarity feed. Reached via
--     /{election}/current_ver.txt then /{election}/{ver}/json/en/summary.json.
--   * The city's Legistar office records, for the two members it still covers.
--   * Ballotpedia, used ONLY as a redundancy check on dates already derived. It agrees on
--     ten of eleven; the eleventh is discussed below.
--
-- 🔴 TWO SAN JOSÉ SEATS ARE NOT ON THE FOUR-YEAR RHYTHM, AND BOTH WOULD HAVE BEEN WRONG BY
--    YEARS IF THE RULE HAD BEEN APPLIED MECHANICALLY:
--
--   D8 CANDELAS WAS APPOINTED, NOT ELECTED, INTO A VACANCY. Sylvia Arenas left District 8 for
--   the county Board of Supervisors, and the Council appointed Candelas, who ASSUMED OFFICE
--   2023-01-30 and served as the interim member before winning the 2024 general outright
--   (57.27%). His CONTINUOUS occupancy therefore begins 2023-01-30 — not 2025-01-01, which is
--   what his election year alone would have produced. Two years wrong.
--
--   D3 TORDILLOS CAME IN THROUGH A SPECIAL ELECTION. The seat fell vacant on Omar Torres's
--   resignation in November 2024. Tordillos took the April 8 2025 special to a runoff and won
--   it on 2025-06-24 (64.36%); the result was certified 2025-07-28 and he TOOK THE OATH ON
--   2025-08-12. This is the case the Registrar's swearing-in rule actually governs.
--   ⚠ The research record guessed the "December 30, 2025 Special Runoff Election" was D3.
--     It was NOT — that contest was the county ASSESSOR runoff (Fligor 65.16% over Kumar).
--     The right principle, the wrong election.
--
-- ⚠ D10 IS THE NEAR MISS THAT CAME OUT CLEAN. District 10 fell vacant the same way when Matt
--   Mahan became Mayor, and Arjun Batra was appointed, beginning 2023-01-30. But Batra then
--   LOST the 2024 general to George Casey, so Casey is a fresh occupancy at 2025-01-01. The
--   D8 shape and the D10 shape look identical until you ask who won.
--
-- ⚠ D4 COHEN IS ABSENT FROM THE 2024 BALLOT ENTIRELY, and that is not an error: no San José
--   council contest appears in the March 2024 primary and District 4 is not in the November
--   2024 certified results. Whatever the mechanism, it cannot move his CONTINUOUS occupancy,
--   which the city's own Legistar record and the 2020 certified result both put at
--   2021-01-01.
--
-- ⚠ D9 FOLEY IS THE ONE ROW BALLOTPEDIA DISAGREES WITH, and Ballotpedia is wrong. It prints
--   "Tenure 2018 - Present". 2018 is her ELECTION year; Charter Section 1600 commences the
--   term the following 1 January, and the city's own Legistar office record reads
--   2019-01-01 .. 2022-12-31. The charter and the city agree, so 2019-01-01 is written.
--   This is the "a published term year is EXPIRY" error with the sign flipped — a published
--   tenure year is not necessarily a commencement either.
--
-- ── PRECISION ───────────────────────────────────────────────────────────────────────────
-- All eleven are written at 'day'. The rule is stated in an instrument (Charter Sections 1600
-- and 500), the election is certified, and the two irregular seats have a published assumption
-- date and a published oath date respectively. This is the Macon-Bibb shape (a charter stating
-- the commencement rule in terms), NOT the Muscogee shape where the day was only a rule
-- applied to a sourced year and CC_0055 wrote 'year'.
--
-- 🔴 NO term_end IS WRITTEN. Districts 1, 3, 5, 7 and 9 are on the November 2026 ballot; a
--    future term_end would make those seats silently self-vacate on the day it arrived.
--
-- Idempotent: every UPDATE is guarded on the row still being undated, so a re-run is a no-op.

BEGIN;

-- ── PRE-FLIGHT ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n integer;
BEGIN
  SELECT count(*) INTO v_n
    FROM essentials.governments g
    JOIN essentials.chambers c ON c.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = c.id
   WHERE g.geo_id = '0668000';
  IF v_n <> 11 THEN
    RAISE EXCEPTION 'pre-flight: expected 11 San José offices, found %. The council has changed shape — re-read ca.md before running this.', v_n;
  END IF;
END $$;

UPDATE essentials.office_terms ot
   SET term_start      = v.start_date,
       start_precision = v.prec,
       how_started     = v.how,
       source          = v.src
  FROM (VALUES
    ('0668000',               'Matt Mahan',       DATE '2023-01-01', 'day', 'elected',
     'scc-clarity-2022-11-general-115971 (Mahan 128,376 / 51.21% over Chávez 122,329) + San José City Charter Section 500, which names the date in terms: "the term for the office of Mayor beginning on January 1, 2023". ⚠ Mayor is a SEPARATE OFFICE from his District 10 council seat (2021-01-01 .. 2022-12-31); this row is the mayoral occupancy only.'),
    ('sj-council-district-1',  'Rosemary Kamei',   DATE '2023-01-01', 'day', 'elected',
     'scc-clarity-2022-06-primary-113941 (Kamei 9,943 / 65.69% — an OUTRIGHT majority, so District 1 never appeared on the November ballot; Charter Section 1600(7)) + Charter Section 1600 commencement.'),
    ('sj-council-district-2',  'Pamela Campos',    DATE '2025-01-01', 'day', 'elected',
     'scc-clarity-2024-11-general-122582 (Campos 16,883 / 54.03% over Lopez 14,362) + Charter Section 1600 commencement. Succeeded Sergio Jimenez.'),
    ('sj-council-district-3',  'Anthony Tordillos',DATE '2025-08-12', 'day', 'elected',
     'scc-clarity-2025-06-24-special-runoff-123874 (Tordillos 5,355 / 64.36% over Chavez-Lopez 2,966), certified 2025-07-28, OATH TAKEN 2025-08-12 (San José Spotlight, published that day). ⚠ A SPECIAL election, so the Registrar''s swearing-in-after-canvass rule governs and the charter''s 1 January does NOT. Seat fell vacant on Omar Torres''s resignation, November 2024.'),
    ('sj-council-district-4',  'David Cohen',      DATE '2021-01-01', 'day', 'elected',
     'sanjose-legistar-officeRecords-body138 (Cohen 2021-01-01 .. 2024-12-31) + scc-clarity-2020-11-general-106043 (Cohen 20,030 / 51.33% over Diep 18,993) + Charter Section 1600. ⚠ District 4 does not appear in the 2024 certified results at all; that cannot move a CONTINUOUS occupancy already established in 2021.'),
    ('sj-council-district-5',  'Peter Ortiz',      DATE '2023-01-01', 'day', 'elected',
     'scc-clarity-2022-11-general-115971 (Ortiz 9,074 / 54.82% over Nora Campos 7,479) + Charter Section 1600. ⚠ Ortiz placed SECOND in the June primary (22.48%) and won the November general — reading the primary alone names the wrong member.'),
    ('sj-council-district-6',  'Michael Mulcahy',  DATE '2025-01-01', 'day', 'elected',
     'scc-clarity-2024-11-general-122582 (Mulcahy 19,629 / 51.30% over Navarro 18,632) + Charter Section 1600. Succeeded Devora "Dev" Davis.'),
    ('sj-council-district-7',  'Bien Doan',        DATE '2023-01-01', 'day', 'elected',
     'scc-clarity-2022-11-general-115971 (Doan 9,170 / 53.79% over the sitting member Maya Esparza 7,877) + Charter Section 1600. ⚠ Doan also placed second in the June primary (28.76%).'),
    ('sj-council-district-8',  'Domingo Candelas', DATE '2023-01-30', 'day', 'appointed',
     'APPOINTED to the vacancy left when Sylvia Arenas took the county Board of Supervisors seat; assumed office 2023-01-30 (Ballotpedia officeholder record, corroborated by San José Spotlight/San Jose Inside reporting of the 7-2 council vote), served as interim member, then won scc-clarity-2024-11-general-122582 outright (23,363 / 57.27%). CONTINUOUS occupancy runs from the APPOINTMENT — his election year alone would have produced 2025-01-01, two years late.'),
    ('sj-council-district-9',  'Pam Foley',        DATE '2019-01-01', 'day', 'elected',
     'sanjose-legistar-officeRecords-body138 (Foley 2019-01-01 .. 2022-12-31) + Charter Section 1600, applied to her 2018 election; re-elected unopposed in the 2022 June primary (16,051 / 100.00%). ⚠ Ballotpedia prints "Tenure 2018" — that is the ELECTION year, not the commencement, and it is the one row where it disagrees with the city''s own record.'),
    ('sj-council-district-10', 'George Casey',     DATE '2025-01-01', 'day', 'elected',
     'scc-clarity-2024-11-general-122582 (Casey 23,977 / 57.80%) + Charter Section 1600. ⚠ He DEFEATED the appointed incumbent Arjun Batra, who had held the seat from 2023-01-30 after Matt Mahan became Mayor. District 10 and District 8 look structurally identical — both vacated in January 2023, both filled by appointment — and they resolve differently because Batra lost and Candelas won.')
  ) AS v(geo_id, full_name, start_date, prec, how, src)
 WHERE ot.office_id IN (
         SELECT o.id
           FROM essentials.offices o
           JOIN essentials.districts d ON d.id = o.district_id
           JOIN essentials.chambers c ON c.id = o.chamber_id
           JOIN essentials.governments g ON g.id = c.government_id
          WHERE g.geo_id = '0668000' AND d.geo_id = v.geo_id)
   AND EXISTS (SELECT 1 FROM essentials.politicians p
                WHERE p.id = ot.politician_id AND p.full_name = v.full_name)
   AND ot.term_start IS NULL            -- the guard: a re-run is a no-op
   AND ot.start_precision = 'unknown';

-- ── POST-VERIFY ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n   integer;
  v_bad text;
BEGIN
  -- 1. All eleven dated, none left at 'unknown'.
  SELECT count(*) INTO v_n
    FROM essentials.governments g
    JOIN essentials.chambers c ON c.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = c.id
    JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE g.geo_id = '0668000' AND ot.term_start IS NOT NULL;
  IF v_n <> 11 THEN
    RAISE EXCEPTION 'san josé dates: expected 11 dated terms, found %', v_n;
  END IF;

  -- 2. The exact seat/person/date/precision set. Fails loudly after the November 2026
  --    turnover, which is the intended behaviour: five of these seats are on that ballot.
  SELECT string_agg(d.label || ' = ' || coalesce(p.full_name, '(vacant)') || ' @ ' ||
                    coalesce(ot.term_start::text, 'NULL') || '/' || ot.start_precision ||
                    '/' || coalesce(ot.how_started, 'NULL'), '; ' ORDER BY d.label)
    INTO v_bad
    FROM essentials.governments g
    JOIN essentials.chambers c ON c.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = c.id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_terms ot ON ot.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE g.geo_id = '0668000'
     AND (d.geo_id, coalesce(p.full_name,''), coalesce(ot.term_start::text,''),
          ot.start_precision, coalesce(ot.how_started,'')) NOT IN (
       ('0668000',               'Matt Mahan',       '2023-01-01', 'day', 'elected'),
       ('sj-council-district-1',  'Rosemary Kamei',   '2023-01-01', 'day', 'elected'),
       ('sj-council-district-2',  'Pamela Campos',    '2025-01-01', 'day', 'elected'),
       ('sj-council-district-3',  'Anthony Tordillos','2025-08-12', 'day', 'elected'),
       ('sj-council-district-4',  'David Cohen',      '2021-01-01', 'day', 'elected'),
       ('sj-council-district-5',  'Peter Ortiz',      '2023-01-01', 'day', 'elected'),
       ('sj-council-district-6',  'Michael Mulcahy',  '2025-01-01', 'day', 'elected'),
       ('sj-council-district-7',  'Bien Doan',        '2023-01-01', 'day', 'elected'),
       ('sj-council-district-8',  'Domingo Candelas', '2023-01-30', 'day', 'appointed'),
       ('sj-council-district-9',  'Pam Foley',        '2019-01-01', 'day', 'elected'),
       ('sj-council-district-10', 'George Casey',     '2025-01-01', 'day', 'elected'));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'san josé dates: seat/date mismatch -- %. Districts 1, 3, 5, 7 and 9 are on the November 2026 ballot; re-run the change-check in ROSTERS.md before changing this list.', v_bad;
  END IF;

  -- 3. Exactly one 'appointed' start, and it is District 8. This is the row that a mechanical
  --    application of the charter rule gets wrong by two years, so it is pinned by itself.
  SELECT count(*) INTO v_n
    FROM essentials.governments g
    JOIN essentials.chambers c ON c.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = c.id
    JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE g.geo_id = '0668000' AND ot.how_started = 'appointed';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'san josé dates: expected exactly 1 appointed start (District 8), found %', v_n;
  END IF;

  -- 4. No term_end anywhere. Five of these seats turn over in January 2027.
  SELECT count(*) INTO v_n
    FROM essentials.governments g
    JOIN essentials.chambers c ON c.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = c.id
    JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE g.geo_id = '0668000' AND ot.term_end IS NOT NULL;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'san josé dates: % term row(s) carry a term_end; none should', v_n;
  END IF;

  RAISE NOTICE 'san josé dates: 11 occupancies dated at day precision, 2019-01-01 .. 2025-08-12; 10 elected and 1 appointed (District 8, 2023-01-30); no term_end written';
END $$;

COMMIT;
