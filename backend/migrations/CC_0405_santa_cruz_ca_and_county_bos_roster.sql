-- CC_0405_santa_cruz_ca_and_county_bos_roster.sql
-- Seats the people CC_0404 built offices for: the Mayor and six Councilmembers of the City of
-- Santa Cruz, and the five sitting Santa Cruz County supervisors. Twelve office_terms rows.
-- NOBODY WHO WON IN 2026 AND HAS NOT YET TAKEN OFFICE IS SEATED HERE.
--
-- @incumbency-decision: no-effect — all 12 offices are BRAND NEW (CC_0404, same PR) and carry
-- zero races; all 12 politicians are new rows and carry zero race_candidates; and every term row
-- written here has term_start AND term_end NULL, so it covers no election day and restates
-- nobody's incumbency.
--
-- That claim is checkable, and was checked against production on 2026-11-11 rather than assumed:
--
--   races whose office_id is one of these 12 .......... 0
--   race_candidates whose politician is one of these 12  0
--   term rows written with a non-NULL date bound ...... 0  (all 12 are NULL/NULL)
--
-- `race_candidates.is_incumbent` means "incumbent OF THIS SEAT on this race's own election date".
-- It is CACHED, and the way a migration corrupts it is by writing a term date that no longer
-- covers an election day some race row still assumes. There is no date here to do that with, and
-- no race row to do it to. This is the first of the two legitimate no-effect shapes the guard
-- names, not the "there are probably no recent races" guess it rejects.
--
-- ⚠ This changes WHEN the successor passes land. The December Mayor handover and the January
--   Supervisor D4 handover (see the TO DO at the foot of this file) WILL write dates on both
--   sides of a seating, and by then these offices may well have race rows. Those migrations need
--   the real `gated` delta gate from migrations/_templates/office_terms_incumbency_guard.sql.
--   Do not carry this line forward into them.
--
-- ═══ 🔴 NAMESAKE SAFETY — WHY EVERY LOOKUP CARRIES 'CC_0405 ' ═══
--
-- The Reno seed (CC_0387) nearly bound a Reno ward to an Oregon state senator because its
-- insert and its lookup shared a first+last predicate. Both ends here are keyed on first+last
-- AND `source LIKE 'CC_0405 %'`.
--
-- These surnames are commonplace and the corpus is full of them — 'Monica Hernandez',
-- 'Kimberly Martinez', 'Scott Hernandez', three other Cummingses, dozens of Martinezes. Checked
-- 2026-11-11: ZERO of the twelve first+last pairs collides with any existing row, so the
-- duplicate-name guard is not switched off. If it fires, a REAL collision appeared after this
-- was written and must be adjudicated, not suppressed.
--
-- 🔴 SANTA CRUZ HAS THE CAL-ACCESS TRAP IN BULK, AND IT CARRIES FOUR OF THESE NAMES.
--    `essentials.politicians` holds ELEVEN campaign-committee rows that look like people:
--      'DE SERPA FOR SANTA CRUZ COUNTY SUPERVISOR 2024; FRIENDS OF KIM'
--      'KALANTARI-JOHNSON FOR SANTA CRUZ CITY COUNCIL 2020; SHEBREH'       (x2)
--      'KALANTARI-JOHNSON FOR SANTA CRUZ COUNTY SUPERVISOR 2022'
--      'TRIGUEIRO FOR CITY COUNCIL 2024; FRIENDS OF'                       (x2)
--      'FRIENDS OF KIM DE SERPA ... DISTIRCT 3 2024'                       (x2, sic)
--      and four more. All is_active=false, first_name empty, zero images, zero answers, zero
--    office_terms. THEY ARE NOT PEOPLE. Nothing here matches on a LIKE, and nothing here binds
--    to one. See [[project_cal_access_lasttoken_mislinks]].
--
-- ═══ BOTH ROSTERS REST ON TWO INDEPENDENT AUTHORITIES, NOT ONE ═══
--
-- City  (1) santacruzca.gov "Meet the Mayor and City Council", read 2026-11-11
--       (2) the COUNTY ELECTIONS DEPARTMENT's own roster,
--           votescount.santacruzcountyca.gov/Home/Publicofficialsroster/
--           ElectedOfficialsofSantaCruzCounty/City/santacruz.aspx, read 2026-11-11
-- County (1) santacruzcountyca.gov/Government/BoardofSupervisors.aspx + District1..5.aspx
--       (2) the same elections roster, .../County.aspx
--       (3) the County's FY2025 ACFR Directory of Public Officials (read from the PDF itself,
--           SCC_ACFR_FINAL_FY25.pdf, which also uses the exact office titles CC_0404 created)
--
-- The two city sources agree district-for-district on all seven, which matters more than usual
-- here because of the trap below.
--
-- ═══ 🔑 THE CITY'S OWN ROSTER PAGE MISASSIGNS EVERY TERM IF YOU READ IT LINEARLY ═══
--
-- On "Meet the Mayor and City Council" each member sits in their own <article>, and the "Term
-- Expires" line is the LAST CHILD of that article. Flattened to text it therefore appears
-- BETWEEN two names, reading as though it belonged to the one that follows:
--
--     "... Term Expires December 2026 Shebreh Kalantari-Johnson Vice Mayor - District 3 ..."
--
-- That December 2026 is FRED KEELEY'S. Read naively, every term shifts by one person and
-- Kalantari-Johnson (who has until 2028) looks like she is up this cycle. The page was parsed
-- one <article> at a time (scripts/_sc-rig/parse-council.mjs), and the result was then
-- confirmed from a source with no shared lineage: the city's GIS council-district layer
-- carries a TermEnd field, and all six agree. load-santa-cruz-districts.mjs re-runs that
-- comparison as GATE 5 so the next reader sees it fail if either side moves.
--
-- ⚠ The ELECTIONS roster is a third, weaker check on the same thing — it gives "Next Election"
--   rather than a term end, and those agree too (Mayor/D4/D6 → Primary 2026; D1/D5 → Primary
--   2028). 🔴 But that page's STRUCTURAL text is STALE: it still heads the table "Santa Cruz
--   City Council - Elected at large" and gives the pre-Measure-E "Up to 10 consecutive years"
--   term limit. Its NAMES and DISTRICTS are current; its description of the system is four
--   years out of date. Names from it, structure from the charter.
--
-- ═══ 🔴 TERM STARTS AND ENDS ARE NULL, AND THAT IS THE HONEST RECORD ═══
--
-- `essentials.current_office_holders` reads
-- `(term_start IS NULL OR term_start <= CURRENT_DATE) AND (term_end IS NULL OR term_end >=
-- CURRENT_DATE)`, so NULL on both sides is a first-class "holds this office now, dates not
-- asserted". `start_precision` is set to 'unknown' rather than the column default 'day',
-- because an unknown date described as day-precise is a worse record than one described as
-- unknown.
--
-- ⚖ TERM START. No authority publishes one. The city's GIS layer has a TermBegin column
--   ("November 2022", "March 2024") but those are ELECTION months, and Charter s 601(b)-(c)
--   says a term begins "on the date of the City Council meeting, following his or her
--   election, at which the council receives the certification of election results from the
--   City Clerk" — weeks later, on a date none of these sources gives. The elections roster
--   gives "First Elected" years, which for Manu Koenig (2020) and Sonja Brunner (2020) is two
--   terms ago. Writing either in would manufacture a date.
--
-- ⚖ TERM END. The ACFR DOES publish these, at MONTH precision: supervisors 1, 2 and 5 to
--   January 2029 and 3 and 4 to January 2027; the city publishes December 2026 / December 2028.
--   🔴 `office_terms` HAS NO `end_precision` COLUMN — only `start_precision` — so any date
--   written there reads as day-precise. California supervisors take office in the first days
--   of January, so '2027-01-31' would keep a departed supervisor seated for three extra weeks
--   and '2027-01-01' would unseat a sitting one early. Both are wrong in a way that shows on
--   the site. The published expiry is recorded in each row's `source` instead, where it is
--   exact and auditable. Same ruling as CC_0393.
--
-- ═══ 🔴 TWO OF THESE TWELVE SEATS HAVE ALREADY CHANGED HANDS AT THE BALLOT BOX ═══
--
-- Neither successor is seated, and that is deliberate in both cases:
--
--   MAYOR. Ryan Coonerty won the 2026-11-03 runoff, 13,157 (52.95%) to Ami Chen Mills' 11,472
--   (46.17%), 220 write-in. Those results are published "-Unofficial Results-" and
--   certification is due about 2026-12-03. Under Charter s 601(c) his term does not begin
--   until the Council meeting that receives that certification, so FRED KEELEY IS THE MAYOR
--   TODAY and is seated as such.
--
--   SUPERVISOR, 4th DISTRICT. Tony Nuñez took 3,944 of 7,877 in the June 2 primary — 50.07%,
--   SIX VOTES above the majority line — so under the two-round system he was elected outright
--   in June and no November runoff was held. FELIPE HERNANDEZ WAS DEFEATED but holds the seat
--   until the new term begins in January 2027, which is what the ACFR's "January 2027" says
--   and what the County's own District 4 page still shows. He is seated; Nuñez is not.
--   ⚠ Arithmetic verified against the certified Official Results PDF dated 6/26/2026:
--     2,429 + 3,944 + 1,450 + 54 = 7,877 exactly. `pdftotext -layout` SHIFTS THAT PDF'S
--     PERCENTAGE COLUMN BY A ROW — every percentage here is computed from the counts.
--
-- Two seats were defended successfully in June and need no action: Justin Cummings
-- (Supervisor 3rd District, 12,642 with 428 write-ins) and the city's District 4 and
-- District 6 incumbents, Scott Newsome (1,472 to Hector Marin's 1,333) and Renee Golder
-- (1,971 to Gabriella Noack's 1,110).
--
-- ▶▶ TO DO, AND NEITHER IS AN OVERSIGHT:
--   (1) MAYOR, at the December certification meeting: end Keeley's term, seat Ryan Coonerty
--       from the CERTIFIED result, and use `essentials.office_swearing_in` (CC_0344) with
--       basis 'published'. 🔴 `office_terms_no_overlap` uses INCLUSIVE daterange bounds, so a
--       same-day succession is REJECTED — Keeley's term_end must be the day BEFORE Coonerty's
--       term_start, and which of the two is the verified fact must be recorded.
--   (2) SUPERVISOR, 4th DISTRICT, in January 2027: the same, for Tony Nuñez over Felipe
--       Hernandez, with `how_ended = 'defeated'` on Hernandez's row.
--
-- ═══ ⚖ VICE MAYOR IS NOT AN OFFICE ═══
-- Shebreh Kalantari-Johnson is Vice Mayor, chosen BY the Council and serving at its pleasure
-- (Charter s 604(f)) — see CC_0404. It is recorded in `politicians.notes`, where a rotating
-- title belongs, not in an office title that would need a migration every year.
-- 🔴 The city's GIS layer disagrees and is WRONG: its District 6 rows read "Vice Mayor Renee
--    Golder". Both the city's roster page and the County elections roster say Kalantari-Johnson.

BEGIN;

-- ══ CITY OF SANTA CRUZ ════════════════════════════════════════════════════════
-- district 0 = the at-large Mayor. City seeds take no external_id (the CC_0387/CC_0393
-- convention); the county block below does.

CREATE TEMP TABLE sc_city_roster(
  district int, full_name text, first_name text, last_name text, note text, source text,
  politician_id uuid) ON COMMIT DROP;

INSERT INTO sc_city_roster(district, full_name, first_name, last_name, note, source) VALUES
  (0, 'Fred Keeley', 'Fred', 'Keeley', NULL,
      'CC_0405 santacruzca.gov Meet the Mayor and City Council + votescount.santacruzcountyca.gov city roster, read 2026-11-11 — Mayor, elected at large, first elected 2022, term expires December 2026. DEFEATED FOR RE-ELECTION: Ryan Coonerty won the 2026-11-03 runoff (unofficial), taking office at the December certification meeting'),
  (1, 'Gabriela Trigueiro', 'Gabriela', 'Trigueiro', NULL,
      'CC_0405 santacruzca.gov Meet the Mayor and City Council + votescount.santacruzcountyca.gov city roster, read 2026-11-11 — Councilmember District 1, first elected 2024, term expires December 2028'),
  (2, 'Sonja Brunner', 'Sonja', 'Brunner', NULL,
      'CC_0405 santacruzca.gov Meet the Mayor and City Council + votescount.santacruzcountyca.gov city roster, read 2026-11-11 — Councilmember District 2, first elected 2020, term expires December 2028'),
  (3, 'Shebreh Kalantari-Johnson', 'Shebreh', 'Kalantari-Johnson',
      'Vice Mayor — a title chosen BY the City Council from among its own members, held at the Council''s pleasure (Charter s 604(f)), not an office any voter elects.',
      'CC_0405 santacruzca.gov Meet the Mayor and City Council + votescount.santacruzcountyca.gov city roster, read 2026-11-11 — Vice Mayor, Councilmember District 3, first elected 2020, term expires December 2028'),
  (4, 'Scott Newsome', 'Scott', 'Newsome', NULL,
      'CC_0405 santacruzca.gov Meet the Mayor and City Council + votescount.santacruzcountyca.gov city roster, read 2026-11-11 — Councilmember District 4, first elected 2022, term expires December 2026; RE-ELECTED outright in the 2026-06-02 first round, 1,472 to 1,333'),
  (5, 'Susie O''Hara', 'Susie', 'O''Hara', NULL,
      'CC_0405 santacruzca.gov Meet the Mayor and City Council + votescount.santacruzcountyca.gov city roster, read 2026-11-11 — Councilmember District 5, first elected 2024, term expires December 2028'),
  (6, 'Renee Golder', 'Renee', 'Golder', NULL,
      'CC_0405 santacruzca.gov Meet the Mayor and City Council + votescount.santacruzcountyca.gov city roster, read 2026-11-11 — Councilmember District 6, first elected 2022, term expires December 2026; RE-ELECTED outright in the 2026-06-02 first round, 1,971 to 1,110');

INSERT INTO essentials.politicians
  (full_name, first_name, last_name, is_active, is_incumbent, source, notes)
SELECT r.full_name, r.first_name, r.last_name, true, true, r.source,
       CASE WHEN r.note IS NULL THEN NULL ELSE ARRAY[r.note] END
  FROM sc_city_roster r
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
      AND p.source LIKE 'CC_0405 %');

UPDATE sc_city_roster r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
   AND p.source LIKE 'CC_0405 %';

-- ⚖ Unlike Corte Madera, the pairing here is a FACT, not a convention: every seat is numbered
--   and two independent rosters agree on who holds which. The join is on the office title.
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end,
                                     start_precision, how_started, source)
SELECT o.id, r.politician_id, NULL, NULL, 'unknown', 'elected', r.source
  FROM sc_city_roster r
  JOIN essentials.governments g ON g.name = 'City of Santa Cruz, California, US'
  JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'City Council'
  JOIN essentials.offices o ON o.chamber_id = c.id
   AND o.title = CASE WHEN r.district = 0 THEN 'Mayor'
                      ELSE 'Councilmember, District ' || r.district END
 WHERE r.politician_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

UPDATE essentials.politicians p SET office_id = ot.office_id
  FROM essentials.office_terms ot
 WHERE ot.politician_id = p.id AND p.source LIKE 'CC_0405 %' AND p.office_id IS NULL;

-- ══ SANTA CRUZ COUNTY BOARD OF SUPERVISORS ════════════════════════════════════
-- external_id continues the county's own block: -6 + county FIPS 087 + sequence. Migration
-- 1663 used -62087001..005 for the five countywide officers, so the board takes 006..010.

CREATE TEMP TABLE sc_sup_roster(
  district int, ordinal text, full_name text, first_name text, last_name text, ext bigint,
  source text, politician_id uuid) ON COMMIT DROP;

INSERT INTO sc_sup_roster(district, ordinal, full_name, first_name, last_name, ext, source) VALUES
  (1, '1st', 'Manu Koenig', 'Manu', 'Koenig', -62087006,
      'CC_0405 santacruzcountyca.gov District1.aspx + votescount county roster + FY2025 ACFR Directory of Public Officials, read 2026-11-11 — Supervisor 1st District, first elected 2020, term ends January 2029'),
  (2, '2nd', 'Kimberly De Serpa', 'Kimberly', 'De Serpa', -62087007,
      'CC_0405 santacruzcountyca.gov District2.aspx + votescount county roster + FY2025 ACFR Directory of Public Officials, read 2026-11-11 — Supervisor 2nd District, first elected 2024, term ends January 2029'),
  (3, '3rd', 'Justin Cummings', 'Justin', 'Cummings', -62087008,
      'CC_0405 santacruzcountyca.gov District3.aspx + votescount county roster + FY2025 ACFR Directory of Public Officials, read 2026-11-11 — Supervisor 3rd District, first elected 2022, term ends January 2027; RE-ELECTED outright in the 2026-06-02 first round, 12,642 votes with 428 write-ins'),
  (4, '4th', 'Felipe Hernandez', 'Felipe', 'Hernandez', -62087009,
      'CC_0405 santacruzcountyca.gov District4.aspx + votescount county roster + FY2025 ACFR Directory of Public Officials, read 2026-11-11 — Supervisor 4th District, first elected 2022, term ends January 2027. DEFEATED 2026-06-02: Tony Nunez won outright with 3,944 of 7,877 (50.07%) and takes office January 2027'),
  (5, '5th', 'Monica Martinez', 'Monica', 'Martinez', -62087010,
      'CC_0405 santacruzcountyca.gov District5.aspx + votescount county roster + FY2025 ACFR Directory of Public Officials, read 2026-11-11 — Supervisor 5th District, first elected 2024, term ends January 2029');

-- 🔴 DISTRICT 2's PAGE NAMES TWO SUPERVISORS. Alongside the heading "Second District
--    Supervisor Kimberly De Serpa" it still carries a stale committee-assignments block
--    reading "Supervisor Friend represents the Board on the following regional agencies" —
--    Zach Friend, her predecessor, who left in 2024. Grepping that page for "Supervisor X"
--    returns both names. De Serpa is confirmed by the elections roster AND the ACFR, neither of
--    which mentions Friend.

INSERT INTO essentials.politicians
  (full_name, first_name, last_name, external_id, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, r.ext, true, true, r.source
  FROM sc_sup_roster r
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
      AND p.source LIKE 'CC_0405 %');

UPDATE sc_sup_roster r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
   AND p.source LIKE 'CC_0405 %';

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end,
                                     start_precision, how_started, source)
SELECT o.id, r.politician_id, NULL, NULL, 'unknown', 'elected', r.source
  FROM sc_sup_roster r
  JOIN essentials.governments g
    ON g.name = 'Santa Cruz County, California, US' AND g.geo_id = '06087'
  JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Board of Supervisors'
  JOIN essentials.offices o ON o.chamber_id = c.id
   AND o.title = 'Supervisor, ' || r.ordinal || ' District'
 WHERE r.politician_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

UPDATE essentials.politicians p SET office_id = ot.office_id
  FROM essentials.office_terms ot, sc_sup_roster r
 WHERE ot.politician_id = p.id AND p.id = r.politician_id AND p.office_id IS NULL;

-- Offices are no longer vacant.
UPDATE essentials.offices o SET is_vacant = false
 WHERE o.is_vacant
   AND EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id)
   AND EXISTS (
     SELECT 1 FROM essentials.chambers c
       JOIN essentials.governments g ON g.id = c.government_id
      WHERE c.id = o.chamber_id
        AND (g.name = 'City of Santa Cruz, California, US'
             OR (g.name = 'Santa Cruz County, California, US'
                 AND c.name = 'Board of Supervisors')));

-- ── Post-conditions ───────────────────────────────────────────────────────────
DO $$
DECLARE v_city int; v_bos int; v_current int; v_vacant int; v_dupe int;
        v_committee int; v_mayor text; v_d4 text; v_badprec int;
BEGIN
  SELECT count(*) INTO v_city FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Santa Cruz, California, US';
  IF v_city <> 7 THEN
    RAISE EXCEPTION 'CC_0405 post: expected 7 city council terms, found %', v_city;
  END IF;

  SELECT count(*) INTO v_bos FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Santa Cruz County, California, US' AND c.name = 'Board of Supervisors';
  IF v_bos <> 5 THEN
    RAISE EXCEPTION 'CC_0405 post: expected 5 supervisor terms, found %', v_bos;
  END IF;

  -- The twelve must actually READ AS CURRENT through the view the site serves. A term row that
  -- exists but does not satisfy current_office_holders seats nobody and raises nothing.
  SELECT count(*) INTO v_current FROM essentials.current_office_holders h
    JOIN essentials.offices o ON o.id = h.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Santa Cruz, California, US'
      OR (g.name = 'Santa Cruz County, California, US' AND c.name = 'Board of Supervisors');
  IF v_current <> 12 THEN
    RAISE EXCEPTION 'CC_0405 post: % of 12 seats read as current — a term row exists that the '
                    'current_office_holders view does not accept', v_current;
  END IF;

  SELECT count(*) INTO v_vacant FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.is_vacant
     AND (g.name = 'City of Santa Cruz, California, US'
          OR (g.name = 'Santa Cruz County, California, US'
              AND c.name = 'Board of Supervisors'));
  IF v_vacant <> 0 THEN
    RAISE EXCEPTION 'CC_0405 post: % office(s) still flagged vacant', v_vacant;
  END IF;

  -- Exactly twelve people, each seated once.
  SELECT count(*) INTO v_dupe FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'City of Santa Cruz, California, US'
        OR (g.name = 'Santa Cruz County, California, US' AND c.name = 'Board of Supervisors')
     GROUP BY ot.politician_id HAVING count(*) > 1) t;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'CC_0405 post: % person(s) hold more than one of these seats', v_dupe;
  END IF;

  -- 🔴 No CAL-ACCESS committee row may have been seated. A committee has an EMPTY first_name;
  --    a person does not.
  SELECT count(*) INTO v_committee FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE (g.name = 'City of Santa Cruz, California, US'
          OR (g.name = 'Santa Cruz County, California, US' AND c.name = 'Board of Supervisors'))
     AND (btrim(coalesce(p.first_name, '')) = '' OR p.source = 'cal_access_discovery');
  IF v_committee <> 0 THEN
    RAISE EXCEPTION 'CC_0405 post: % seat(s) bound to a campaign committee rather than a '
                    'person', v_committee;
  END IF;

  -- Precision must say 'unknown', not the column default 'day' — see the header.
  SELECT count(*) INTO v_badprec FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE (g.name = 'City of Santa Cruz, California, US'
          OR (g.name = 'Santa Cruz County, California, US' AND c.name = 'Board of Supervisors'))
     AND (ot.term_start IS NULL AND ot.start_precision <> 'unknown');
  IF v_badprec <> 0 THEN
    RAISE EXCEPTION 'CC_0405 post: % row(s) have a NULL term_start described as %-precise',
                    v_badprec, 'day';
  END IF;

  -- The two seats whose occupant is about to change must hold the SITTING officer, not the
  -- winner. This is the assertion that would have caught seating a successor early.
  SELECT p.full_name INTO v_mayor FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE g.name = 'City of Santa Cruz, California, US' AND o.title = 'Mayor';
  IF v_mayor <> 'Fred Keeley' THEN
    RAISE EXCEPTION 'CC_0405 post: the Mayor seat holds "%", expected the SITTING mayor Fred '
                    'Keeley — Ryan Coonerty''s term begins at the December certification '
                    'meeting, not now', v_mayor;
  END IF;

  SELECT p.full_name INTO v_d4 FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE g.name = 'Santa Cruz County, California, US' AND c.name = 'Board of Supervisors'
     AND o.title = 'Supervisor, 4th District';
  IF v_d4 <> 'Felipe Hernandez' THEN
    RAISE EXCEPTION 'CC_0405 post: Supervisor 4th District holds "%", expected the SITTING '
                    'supervisor Felipe Hernandez — Tony Nunez takes office in January 2027',
                    v_d4;
  END IF;
END $$;

COMMIT;
