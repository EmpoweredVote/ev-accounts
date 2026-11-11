-- CC_0393_corte_madera_ca_and_marin_bos_roster.sql
-- Seats the people CC_0392 built offices for: five Corte Madera councilmembers and the five
-- sitting Marin County supervisors. Ten office_terms rows; NOBODY from the 2026 general.
--
-- ═══ 🔴 NAMESAKE SAFETY — WHY EVERY LOOKUP CARRIES 'CC_0393 ' ═══
--
-- `essentials.politicians` holds a sitting Oregon State Senator called Kathleen Taylor and a
-- South Carolina commissioner called Matthew Johnson; the Reno seed (CC_0387) nearly bound a
-- Reno ward to the Oregon senator because its insert and its lookup used the same
-- first+last predicate. Both ends here are keyed on first+last AND `source LIKE 'CC_0393 %'`.
--
-- 🔴 Marin ALSO has the cal_access trap in bulk. `full_name ILIKE '%Rodoni%'` returns ten rows
--    and NINE of them are campaign committees — 'RODONI FOR SUPERVISOR 2024',
--    'RODONI, COMMITTEE TO RE-ELECT SUPERVISOR ROGER', 'MOULTON-PETERS FOR SUPERVISOR 2028'
--    and so on, all `source = 'cal_access_discovery'`, `is_active = false`, `external_id` NULL,
--    zero office_terms. THEY ARE NOT PEOPLE. Nothing here matches on a LIKE.
--
-- ═══ ⚖ ERIC LUCAN IS RESEATED, NOT RECREATED ═══
--
-- `27335378-1ca6-4502-8e8f-37d9c1d4b71e` already exists, from CC_0269
-- ('ca-sos-2026-general ... certified candidate list; no office asserted'), with no
-- external_id and no term. Creating a second Eric Lucan would duplicate a sitting official.
--
-- Identification, stated because a namesake bind is exactly what this file is defending
-- against: the County's own District 5 page names Supervisor Eric Lucan, and his County
-- biography gives Novato Parks Commissioner 2007-2011, Novato City Council from 2011, Mayor in
-- 2014/2019/2022, first elected to the Board of Supervisors in 2022. Cal-Access holds the
-- matching committee chain under one name — 'LUCAN FOR CITY COUNCIL, ERIC',
-- 'LUCAN FOR SUPERVISOR 2022; ERIC', 'LUCAN FOR MARIN COUNTY SUPERVISOR 2026; ERIC' and
-- 'LUCAN FOR ASSEMBLY 2026; ERIC'. The last of those is why CC_0269 has him at all: he stood
-- for the Assembly in 2026, which is also why District 5 was an OPEN seat in June.
--
-- ═══ 🔴 TERM STARTS ARE MOSTLY NULL, ON PURPOSE ═══
--
-- `essentials.current_office_holders` reads `term_start IS NULL OR term_start <= CURRENT_DATE`,
-- so a NULL start is a first-class "holds this office now, start date not asserted" — and that
-- is the honest record here. Marin publishes no term dates on any page reachable from this
-- network: assets.marincounty.gov (the Statement of Votes Cast, the ACFR) answers 403 to every
-- tier, and the County bios give an election year at best. Only Mary Sackett's bio states a
-- date — "elected ... in June 2022, and she was sworn in to her first term in December 2022" —
-- so only hers is set, at month precision.
--
-- ⚖ `term_end` is NULL for all ten, including the three Corte Madera seats the Town itself
--   says expire in November 2026. Writing a guessed end date is worse than writing none: a
--   term_end in the past empties the seat in `current_office_holders`, and the real handover
--   is the Town's December reorganisation, whose date is not yet published. The published
--   expiry is recorded in each row's `source` instead.
--
-- ═══ 🔴 NOTHING FROM THE NOVEMBER 3 2026 ELECTION IS SEATED ═══
--
-- Marin had counted ~70% of ballots as of 2026-11-10 with ~41,670 left; certification is in
-- December. Three Corte Madera seats were on that ballot (5 candidates: Beckman**, Ravasio**,
-- Bell, Fruin, Gallegos — ** = incumbent; Rosa Thomas did not file). The five seated here are
-- the five sitting today and remain correct until the December reorganisation.
--
-- ▶▶ TO DO, AND IT IS NOT AN OVERSIGHT:
--   (1) DISTRICT 5 HAS A SUCCESSOR ARRIVING IN JANUARY 2027. No supervisor race was on the
--       November ballot, so the June 2 2026 primary settled it, and reporting put Magali Limeta
--       at ~50.3% — just over the outright-win line, which is why a recount was requested. That
--       name is NOT seated here because the certified Statement of Votes Cast could not be
--       read: assets.marincounty.gov → HTTP 403, and both County recount news releases fail
--       every fetch tier with no Wayback snapshot. Seat it from the certified SOV, or from the
--       Board's own swearing-in record, and use `essentials.office_swearing_in` (CC_0344) with
--       basis 'published' — never from a search summary.
--   (2) Corte Madera's December reorganisation sets the next Mayor and Vice Mayor and seats the
--       three winners. Both are one pass, after certification.
--
-- ═══ ⚖ MAYOR AND VICE MAYOR ARE NOT RECORDED AS OFFICES ═══
-- Rosa Thomas is Mayor and Fred Casissa Vice Mayor today, chosen by the Council for one-year
-- terms and rotating each December (see CC_0392). They are recorded in `politicians.notes`,
-- where a one-year rotation belongs, not in an office title that would need a migration every
-- December.

BEGIN;

-- The duplicate-name guard raises DUPLICATE_POLITICIAN_NAME on a first+last collision with a
-- live row. None of these ten collides (checked 2026-11-11), so this is not switched off: if it
-- fires, a REAL collision appeared and must be adjudicated, not suppressed.

CREATE TEMP TABLE cm_roster(
  seq int, full_name text, first_name text, last_name text, note text, source text,
  politician_id uuid) ON COMMIT DROP;

INSERT INTO cm_roster(seq, full_name, first_name, last_name, note, source) VALUES
  (1, 'James Andrews', 'James', 'Andrews', NULL,
      'CC_0393 townofcortemadera.org/140/Town-Council, read 2026-11-11 — Councilmember, term expires November 2028'),
  (2, 'Eli Beckman', 'Eli', 'Beckman', NULL,
      'CC_0393 townofcortemadera.org/140/Town-Council, read 2026-11-11 — Councilmember, term expires November 2026; candidate for re-election 11/03/26'),
  (3, 'Fred Casissa', 'Fred', 'Casissa', 'Vice Mayor for 2026 — a one-year title chosen by the Council, rotating each December.',
      'CC_0393 townofcortemadera.org/140/Town-Council, read 2026-11-11 — Vice Mayor, term expires November 2028'),
  (4, 'Pat Ravasio', 'Pat', 'Ravasio', NULL,
      'CC_0393 townofcortemadera.org/140/Town-Council, read 2026-11-11 — Councilmember, term expires November 2026; candidate for re-election 11/03/26'),
  (5, 'Rosa Thomas', 'Rosa', 'Thomas', 'Mayor for 2026 — a one-year title chosen by the Council, rotating each December.',
      'CC_0393 townofcortemadera.org/140/Town-Council, read 2026-11-11 — Mayor, term expires November 2026; did not file for re-election 11/03/26');

INSERT INTO essentials.politicians
  (full_name, first_name, last_name, is_active, is_incumbent, source, notes)
SELECT r.full_name, r.first_name, r.last_name, true, true, r.source,
       CASE WHEN r.note IS NULL THEN NULL ELSE ARRAY[r.note] END
  FROM cm_roster r
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
      AND p.source LIKE 'CC_0393 %');

UPDATE cm_roster r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
   AND p.source LIKE 'CC_0393 %';

-- ⚠ The five council offices are IDENTICAL — Corte Madera does not number its seats, so there
--   is no fact that says which member holds which row. Pairing is therefore arbitrary but
--   DETERMINISTIC: offices ordered by id, members ordered by surname. Nothing downstream reads
--   the pairing; the office rows differ only by who sits in them.
WITH off AS (
  SELECT o.id, row_number() OVER (ORDER BY o.id) AS rn
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Town of Corte Madera, California, US' AND c.name = 'Town Council'
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision,
                                     how_started, source)
SELECT off.id, r.politician_id, NULL, 'day', 'elected', r.source
  FROM cm_roster r
  JOIN off ON off.rn = r.seq
 WHERE r.politician_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = off.id);

UPDATE essentials.politicians p SET office_id = ot.office_id
  FROM essentials.office_terms ot
 WHERE ot.politician_id = p.id AND p.source LIKE 'CC_0393 %' AND p.office_id IS NULL;

-- ══ MARIN COUNTY SUPERVISORS ══════════════════════════════════════════════════
-- external_id continues the county's own block: -6 + county FIPS 041 + sequence. Migration
-- 1666 used -62041001..003 for the three countywide officers, so the board takes 004..008.
-- (Corte Madera's five take no external_id — the current city-seed convention, as CC_0387 did
-- for all of Reno.)

CREATE TEMP TABLE marin_roster(
  district int, full_name text, first_name text, last_name text, ext bigint,
  term_start date, start_precision text, source text, politician_id uuid) ON COMMIT DROP;

INSERT INTO marin_roster(district, full_name, first_name, last_name, ext, term_start, start_precision, source) VALUES
  (1, 'Mary Sackett', 'Mary', 'Sackett', -62041004, DATE '2022-12-01', 'month',
      'CC_0393 marincounty.gov/departments/board/district-1/mary-sackett, read 2026-11-11 — "District 1 elected Mary Sackett ... in June 2022, and she was sworn in to her first term in December 2022"; Board President'),
  (2, 'Brian Colbert', 'Brian', 'Colbert', -62041005, NULL, 'day',
      'CC_0393 marincounty.gov/departments/board/district-2 + /about-board-supervisors, read 2026-11-11 — occupancy only; the County publishes no term dates on any page reachable here (assets.marincounty.gov 403)'),
  (3, 'Stephanie Moulton-Peters', 'Stephanie', 'Moulton-Peters', -62041006, NULL, 'day',
      'CC_0393 marincounty.gov/departments/board/district-3/stephanie-moulton-peters, read 2026-11-11 — occupancy only, no term dates published; Board 2nd Vice President'),
  (4, 'Dennis Rodoni', 'Dennis', 'Rodoni', -62041007, NULL, 'day',
      'CC_0393 marincounty.gov/departments/board/district-4/dennis-rodoni, read 2026-11-11 — occupancy only, no term dates published'),
  (5, 'Eric Lucan', 'Eric', 'Lucan', -62041008, NULL, 'day',
      'CC_0393 marincounty.gov/departments/board/district-5/eric-lucan, read 2026-11-11 — "first elected to the Marin County Board of Supervisors in 2022"; Board 1st Vice President. Row RESEATED from CC_0269, not recreated');

-- District 5: bind to the EXISTING Eric Lucan row (CC_0269) rather than inserting a second one.
UPDATE marin_roster r SET politician_id = '27335378-1ca6-4502-8e8f-37d9c1d4b71e'::uuid
 WHERE r.district = 5
   AND EXISTS (SELECT 1 FROM essentials.politicians p
                WHERE p.id = '27335378-1ca6-4502-8e8f-37d9c1d4b71e'::uuid
                  AND p.full_name = 'Eric Lucan');

INSERT INTO essentials.politicians
  (full_name, first_name, last_name, external_id, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, r.ext, true, true, r.source
  FROM marin_roster r
 WHERE r.politician_id IS NULL
   AND NOT EXISTS (
     SELECT 1 FROM essentials.politicians p
      WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
        AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
        AND p.source LIKE 'CC_0393 %');

UPDATE marin_roster r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE r.politician_id IS NULL
   AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
   AND p.source LIKE 'CC_0393 %';

-- Carry the reseated Lucan row forward: give it the county external_id and mark it incumbent,
-- while preserving the CC_0269 provenance alongside the new one.
UPDATE essentials.politicians p
   SET external_id = r.ext,
       is_incumbent = true,
       is_active = true,
       source = r.source || ' (was: ' || p.source || ')'
  FROM marin_roster r
 WHERE p.id = r.politician_id AND r.district = 5 AND p.external_id IS NULL;

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision,
                                     how_started, source)
SELECT o.id, r.politician_id, r.term_start, r.start_precision, 'elected', r.source
  FROM marin_roster r
  JOIN essentials.governments g ON g.name = 'Marin County, California, US' AND g.geo_id = '06041'
  JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Board of Supervisors'
  JOIN essentials.offices o ON o.chamber_id = c.id
   AND o.title = 'County Supervisor, District ' || r.district
 WHERE r.politician_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

UPDATE essentials.politicians p SET office_id = ot.office_id
  FROM essentials.office_terms ot, marin_roster r
 WHERE ot.politician_id = p.id AND p.id = r.politician_id AND p.office_id IS NULL;

-- Offices are no longer vacant.
UPDATE essentials.offices o SET is_vacant = false
 WHERE EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id)
   AND o.is_vacant
   AND EXISTS (
     SELECT 1 FROM essentials.chambers c
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE c.id = o.chamber_id
       AND (g.name = 'Town of Corte Madera, California, US'
            OR (g.name = 'Marin County, California, US' AND c.name = 'Board of Supervisors')));

-- ── Post-conditions ───────────────────────────────────────────────────────────
DO $$
DECLARE v_cm int; v_bos int; v_current int; v_lucan int; v_dupe int; v_nov int;
BEGIN
  SELECT count(*) INTO v_cm FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Town of Corte Madera, California, US';
  IF v_cm <> 5 THEN RAISE EXCEPTION 'CC_0393 post: expected 5 Corte Madera terms, found %', v_cm; END IF;

  SELECT count(*) INTO v_bos FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id AND c.name = 'Board of Supervisors'
    JOIN essentials.governments g ON g.id = c.government_id AND g.geo_id = '06041';
  IF v_bos <> 5 THEN RAISE EXCEPTION 'CC_0393 post: expected 5 supervisor terms, found %', v_bos; END IF;

  -- 🔴 The point of a NULL term_start is that the holder still resolves as CURRENT. Assert it
  --    on the view the app actually reads, not on the table.
  SELECT count(*) INTO v_current FROM essentials.office_current_holder h
    JOIN essentials.offices o ON o.id = h.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE h.politician_id IS NOT NULL
     AND (g.name = 'Town of Corte Madera, California, US'
          OR (g.geo_id = '06041' AND c.name = 'Board of Supervisors'));
  IF v_current <> 10 THEN
    RAISE EXCEPTION 'CC_0393 post: expected 10 CURRENT holders through office_current_holder, '
                    'found % — a NULL term_start that does not resolve as current is a silent '
                    'empty seat', v_current;
  END IF;

  -- Exactly one Eric Lucan.
  SELECT count(*) INTO v_lucan FROM essentials.politicians WHERE full_name = 'Eric Lucan';
  IF v_lucan <> 1 THEN
    RAISE EXCEPTION 'CC_0393 post: expected exactly 1 Eric Lucan, found % — the reseat created a '
                    'duplicate instead of binding the CC_0269 row', v_lucan;
  END IF;

  -- No duplicate external_ids in the Marin block.
  SELECT count(*) INTO v_dupe FROM (
    SELECT external_id FROM essentials.politicians
     WHERE external_id BETWEEN -62041999 AND -62041001
     GROUP BY external_id HAVING count(*) > 1) t;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'CC_0393 post: % duplicated Marin external_id(s)', v_dupe; END IF;

  -- Nobody from the 2026 general was seated: no term may start in the future.
  SELECT count(*) INTO v_nov FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE ot.term_start > CURRENT_DATE
     AND (g.name = 'Town of Corte Madera, California, US'
          OR (g.geo_id = '06041' AND c.name = 'Board of Supervisors'));
  IF v_nov <> 0 THEN
    RAISE EXCEPTION 'CC_0393 post: % future-dated term(s) — the 2026 general is still being '
                    'counted and nothing from it belongs here yet', v_nov;
  END IF;
END $$;

COMMIT;
