-- CC_0241_fulton_county_incumbents.sql
--
-- Atlanta full seed, stage 4a, FULTON COUNTY OCCUPANCY half. Seats 10 of 11 offices.
-- Depends on CC_0240_fulton_county_structure.sql.
--
-- Roster: backend/data/seed-atlanta-2026/ROSTERS.md
-- Slot CC_0241 was RESERVED FROM THE ALLOCATOR before this file was named.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 TEN PEOPLE FOR ELEVEN OFFICES. DISTRICT 4 GETS NO TERM ROW, ON PURPOSE.
--
-- It is vacant (CC_0240), the vacancy date is not sourced, and CLAUDE.md forbids writing a
-- vacancy span whose start you do not know. is_vacant carries the fact; the span stays unwritten.
--
-- 🔴 So the seated gate below counts och.politician_id and expects 10, NOT count(*) = 11.
--    office_current_holder LEFT JOINs from offices, so count(*) would PASS VACUOUSLY on a
--    missing term row — which is exactly the shape this wave is trying not to create by accident.
--
-- ---------------------------------------------------------------------------
-- 🔴 NINE OF TEN STARTS ARE 'unknown', AND THEY ARE TAGGED.
--
-- Every one of these ten is confirmed CURRENT — six by the county's own commissioners page plus
-- the 2026 primary return, and the four county officers by the SOS certified 2024 general where
-- each carries the SOS's own "(I)" incumbency marker. What is NOT established is when each
-- occupancy began: the "(I)" marker says they held the seat BEFORE November 2024 and says
-- nothing about how long before.
--
-- 🔴 They are tagged '| unverified CC_0241' because essentials.office_holders_as_of matches
--    `term_start IS NULL OR term_start <= as_of`, so an undated term answers EVERY past date.
--    ✅ VERIFIED: essentials.current_office_holders does NOT filter that tag, so all ten remain
--    current and visible to address search.
--
-- ⚠ ONE START IS DATED, BY AN INFERENCE THAT IS STATED RATHER THAN HIDDEN.
--   Fred Quinn, Jr. (Surveyor) appears on the 2024 certified general WITHOUT the "(I)" marker
--   every other Fulton officer carries, so he did not hold the seat at that election. Georgia
--   county officers take office the following January. That gives January 2025 — written as
--   2025-01-01 at 'year' precision, never at 'day'. The inference has two steps and both are
--   recorded in the source string.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 THE COUNTY OFFICERS ARE THE STALEST COHORT IN THE WAVE.
--
-- Labat, Alexander, Ferdinand and Quinn rest on a 2024 certified result and a county web page.
-- GA-3 put a RETIRED coroner into production because every source agreed and all of them
-- predated the retirement. These four need a freshness check on APPLY DAY, not just a source
-- check — asking again on apply day is cheap and it is the only thing that catches a departure.
--
-- Idempotent. Dry-run with BEGIN; ... ROLLBACK; and confirm the rollback reverted.

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_off int; v_vac int;
BEGIN
  SELECT count(*), count(*) FILTER (WHERE o.is_vacant) INTO v_off, v_vac
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Fulton County, Georgia, US';
  IF v_off <> 11 THEN
    RAISE EXCEPTION 'ATL-4 pre-flight: expected 11 Fulton offices from CC_0240, found % — apply CC_0240 first', v_off;
  END IF;
  IF v_vac <> 1 THEN
    RAISE EXCEPTION 'ATL-4 pre-flight: expected exactly 1 vacant Fulton office, found %', v_vac;
  END IF;
END $$;

-- ─── 1. Ten people ───────────────────────────────────────────────────────────

CREATE TEMP TABLE ful_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO ful_people(external_id, full_name, first_name, last_name) VALUES
  (-2767921::bigint, 'Robb Pitts',               'Robb',     'Pitts'),
  (-2767922::bigint, 'Bridget Thorne',           'Bridget',  'Thorne'),
  (-2767923::bigint, 'Bob Ellis',                'Bob',      'Ellis'),
  (-2767924::bigint, 'Dana Barrett',             'Dana',     'Barrett'),
  (-2767925::bigint, 'Marvin S. Arrington, Jr.', 'Marvin',   'Arrington'),
  (-2767926::bigint, 'Khadijah Abdur-Rahman',    'Khadijah', 'Abdur-Rahman'),
  (-2767927::bigint, 'Patrick "Pat" Labat',      'Patrick',  'Labat'),
  (-2767928::bigint, 'Che'' Alexander',          'Che''',    'Alexander'),
  (-2767929::bigint, 'Arthur E. Ferdinand',      'Arthur',   'Ferdinand'),
  (-2767930::bigint, 'Fred Quinn, Jr.',          'Fred',     'Quinn');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Fulton County, Georgia — the Board of Commissioners is the county''s own roster at fultoncountyga.gov/Commissioners, cross-checked against the Georgia Secretary of State certified returns for the 2024-11-05 general and the 2026 primary and runoff. The four county officers are from the 2024 certified general, each carrying the SOS "(I)" incumbency marker except the Surveyor. 🔴 The county''s GIS layers name "Natalie Hall" in District 4 — two holders out of date — and are used for GEOMETRY ONLY. Read 2026-10-17 (CC_0241)',
       true, true, '{}'::text[]
FROM ful_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. Ten terms ────────────────────────────────────────────────────────────
-- 🔴 Five offices share the countywide district 13121/G4020 (the Chairperson and four county
--    officers), so a term CANNOT be joined through (geo_id, mtfcc) alone. Every row joins on
--    the office TITLE as well. And '13121' is ALSO State House District 121 under G5220, so
--    district_type is in the join too.

CREATE TEMP TABLE ful_terms(
  geo_id text, mtfcc text, title text, external_id bigint,
  term_start date, start_precision text, how_started text, unverified boolean
) ON COMMIT DROP;

INSERT INTO ful_terms(geo_id, mtfcc, title, external_id, term_start, start_precision, how_started, unverified) VALUES
  ('13121',                        'G4020', 'Commission Chairperson',   -2767921::bigint, NULL, 'unknown', 'elected', true),
  ('fulton-county-ga-commission-1','X0078', 'Commissioner, District 1', -2767922::bigint, NULL, 'unknown', 'elected', true),
  ('fulton-county-ga-commission-2','X0078', 'Commissioner, District 2', -2767923::bigint, NULL, 'unknown', 'elected', true),
  ('fulton-county-ga-commission-3','X0078', 'Commissioner, District 3', -2767924::bigint, NULL, 'unknown', 'elected', true),
  -- District 4: NO ROW. Vacant, date unknown. See CC_0240.
  ('fulton-county-ga-commission-5','X0078', 'Commissioner, District 5', -2767925::bigint, NULL, 'unknown', 'elected', true),
  ('fulton-county-ga-commission-6','X0078', 'Commissioner, District 6', -2767926::bigint, NULL, 'unknown', 'elected', true),
  ('13121',                        'G4020', 'Sheriff',                  -2767927::bigint, NULL, 'unknown', 'elected', true),
  ('13121',                        'G4020', 'Clerk of Superior Court',  -2767928::bigint, NULL, 'unknown', 'elected', true),
  ('13121',                        'G4020', 'Tax Commissioner',         -2767929::bigint, NULL, 'unknown', 'elected', true),
  -- 🟢 The one dated start. Not marked "(I)" on the 2024 certified general, so he did not hold
  --    the seat then; Georgia county officers take office the following January. 'year', not 'day'.
  ('13121',                        'G4020', 'Surveyor',                 -2767930::bigint, '2025-01-01'::date, 'year', 'elected', false);

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       CASE WHEN t.unverified THEN
         'Fulton County, Georgia — holder confirmed current by the county''s own Board of Commissioners roster and, for the commission seats on the 2026 ballot, by the SOS "(I)" incumbency marker in the 2026-05-19 primary; the four county officers by the SOS "(I)" marker in the 2024-11-05 certified general. Read 2026-10-17 (CC_0241). The START of this occupancy is NOT established — an "(I)" marker says the person held the seat before that election and nothing about how long before. Written open-ended at ''unknown'' precision rather than guessed. | unverified CC_0241 (2026-10-17): the HOLDER is verified and current; only the start date is unknown, so this term is excluded from office_holders_as_of, where an undated term would otherwise answer every past date'
       ELSE
         'Fulton County, Georgia — Georgia Secretary of State certified return for the 2024-11-05 general, in which this candidate appears WITHOUT the "(I)" incumbency marker that every other Fulton county officer on that ballot carries, so the seat was not his at that election; Georgia county officers take office the January following. That gives January 2025, written at ''year'' precision because the inference fixes the year and not the day. Read 2026-10-17 (CC_0241)'
       END
FROM ful_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.mtfcc = t.mtfcc AND d.district_type = 'COUNTY' AND lower(d.state) = 'ga'
JOIN essentials.offices o ON o.district_id = d.id AND o.title = t.title
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'Fulton County, Georgia, US'
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int;
  v_terms  int;
  v_seated int;
  v_d4     int;
  v_noninc int;
  v_dup    int;
  v_untag  int;
  v_tagged int;
  v_hist   int;
  v_leg    int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2767930 AND -2767921;
  IF v_people <> 10 THEN RAISE EXCEPTION 'ATL-4 gate: expected 10 Fulton people, found %', v_people; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Fulton County, Georgia, US';
  IF v_terms <> 10 THEN RAISE EXCEPTION 'ATL-4 gate: expected 10 Fulton office_terms rows, found %', v_terms; END IF;

  -- 🔴 count(och.politician_id), never count(*).
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Fulton County, Georgia, US';
  IF v_seated <> 10 THEN
    RAISE EXCEPTION 'ATL-4 gate: expected 10 SEATED Fulton offices (11 offices less the vacant District 4), found %', v_seated;
  END IF;

  -- 🔴 And the UNSEATED one must be District 4 specifically.
  SELECT count(*) INTO v_d4
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Fulton County, Georgia, US'
     AND och.politician_id IS NULL
     AND o.title = 'Commissioner, District 4';
  IF v_d4 <> 1 THEN
    RAISE EXCEPTION 'ATL-4 gate: the unseated Fulton office is not District 4 — some other seat lost its holder';
  END IF;

  SELECT count(*) INTO v_noninc FROM essentials.politicians p
   WHERE p.external_id BETWEEN -2767930 AND -2767921
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_noninc <> 0 THEN
    RAISE EXCEPTION 'ATL-4 gate: % Fulton official(s) are not is_incumbent/is_active — they would be HIDDEN from address search', v_noninc;
  END IF;

  SELECT count(*) INTO v_dup FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'Fulton County, Georgia, US'
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'ATL-4 gate: % person(s) hold more than one Fulton office', v_dup; END IF;

  SELECT count(*) INTO v_untag FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Fulton County, Georgia, US'
     AND ot.term_start IS NULL
     AND COALESCE(ot.source, '') NOT LIKE '%| unverified %';
  IF v_untag <> 0 THEN
    RAISE EXCEPTION 'ATL-4 gate: % Fulton term(s) have a NULL term_start and are NOT tagged "| unverified " — each would answer EVERY past date', v_untag;
  END IF;

  SELECT count(*) INTO v_tagged FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Fulton County, Georgia, US'
     AND COALESCE(ot.source, '') LIKE '%| unverified %';
  IF v_tagged <> 9 THEN
    RAISE EXCEPTION 'ATL-4 gate: expected exactly 9 tagged-unverified Fulton terms, found % — the Surveyor is dated and must NOT carry the tag', v_tagged;
  END IF;

  -- 🔴 THE TAG MUST BITE. At 2015 nobody here is datable, so history must return nothing.
  SELECT count(*) INTO v_hist FROM essentials.office_holders_as_of(DATE '2015-06-01') h
    JOIN essentials.offices o ON o.id = h.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Fulton County, Georgia, US';
  IF v_hist <> 0 THEN
    RAISE EXCEPTION 'ATL-4 gate: office_holders_as_of(2015-06-01) returns % Fulton holder(s); expected 0 — an undated term is leaking into history', v_hist;
  END IF;

  SELECT count(*) INTO v_leg FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Georgia'
     AND c.name IN ('Georgia House of Representatives', 'Georgia State Senate');
  IF v_leg <> 236 THEN
    RAISE EXCEPTION 'ATL-4 gate CONTROL: expected 236 Georgia legislative offices, found % — wrong database', v_leg;
  END IF;

  RAISE NOTICE 'ATL-4 OK: 10 people, 10 terms, 10 seated of 11 offices, District 4 correctly unseated, 1 dated + 9 tagged-unverified, history clean at 2015, control 236 legislative offices present';
END $$;
