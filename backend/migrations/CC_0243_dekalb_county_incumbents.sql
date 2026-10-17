-- CC_0243_dekalb_county_incumbents.sql
--
-- Atlanta full seed, stage 4b, DEKALB COUNTY OCCUPANCY half. Seats all 11 offices.
-- Depends on CC_0242_dekalb_county_structure.sql.
--
-- Roster: backend/data/seed-atlanta-2026/ROSTERS.md
-- Slot CC_0243 was RESERVED FROM THE ALLOCATOR before this file was named.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 FOUR OF THESE ELEVEN PEOPLE ARE SURNAMED JOHNSON, AND THEY ARE FOUR DIFFERENT PEOPLE.
--
--   Lorraine Cochran Johnson   Chief Executive Officer   first 'Lorraine', last 'Cochran Johnson'
--   Chakira Johnson            Commissioner, District 4  first 'Chakira',  last 'Johnson'
--   Mereda Davis Johnson       Commissioner, District 5  first 'Mereda',   last 'Davis Johnson'
--   Irvin J. Johnson           Tax Commissioner          first 'Irvin',    last 'Johnson'
--
-- The duplicate-name guard keys on (first_name, last_name), so these four do not collide — but
-- the splits above are LOAD-BEARING. "Cochran Johnson" and "Davis Johnson" are the surnames
-- their own county publishes; splitting either as last='Johnson' would create two pairs that
-- differ only by first name on the same board. 🔴 A LATER SURNAME OR full_name MATCH MUST NOT
-- MERGE ANY OF THEM.
--
-- ---------------------------------------------------------------------------
-- 🟢 SUPER DISTRICT 7 — THE FIRST ROUND INVERTED, AND THE INCUMBENCY MARKER CAUGHT IT.
--
-- The 2024 certified SPECIAL for Super District 7 was led by JACQUELINE ADAMS on 45.98% — no
-- majority, so it went to a runoff. Seating the leader of the first round would have installed
-- the wrong person. The county's roster names LaDena Bolton, and the arbiter is the 2026-05-19
-- primary return, where she appears as "LaDena Bolton (I)" and beats Adams 55.99% to 31.58%.
-- District 3 ran the same shape: Massiah led the 2024 special on 42.26%, won the runoff, and
-- appears in 2026 as "Nicole Massiah (I)".
--
-- 🔴 A CERTIFIED RESULT IS A FACT ABOUT AN ELECTION, NOT ABOUT WHO HOLDS THE SEAT TODAY.
--
-- ---------------------------------------------------------------------------
-- 🔴 TWO DATED STARTS, NINE 'unknown'.
--
-- Dated: Lorraine Cochran Johnson (CEO) and Chakira Johnson (District 4) both appear on the
-- 2024 certified general WITHOUT the SOS "(I)" marker that the other DeKalb incumbents carry,
-- so neither held the seat at that election; Georgia county officers take office the January
-- following. That gives January 2025 at 'year' precision — the inference fixes the year, not
-- the day, and both steps are recorded in the source string.
--
-- ⚠ MASSIAH AND BOLTON ARE **NOT** DATED THAT WAY, AND THAT IS THE POINT.
--   Both won SPECIAL elections for unexpired terms, and a special-election winner is seated ON
--   CERTIFICATION, not the following January — Columbus proved this twice (ga.md, GA-4), where
--   seating the certified winners would have installed a mayor four months early. Writing
--   2025-01-01 for these two would be wrong by weeks in a knowable direction. Their oath dates
--   are ROSTERS.md open item 5; until then, 'unknown'.
--
-- 🔴 The nine undated terms are tagged '| unverified CC_0243' so office_holders_as_of does not
--    let them answer every past date. ✅ VERIFIED: current_office_holders does NOT filter that
--    tag, so all nine remain current and visible to address search.
--
-- ---------------------------------------------------------------------------
-- ⚠ The three county officers (Maddox, DeBerry, Johnson) rest on a 2024 certified result and a
--   county web page — the stalest cohort here, the same shape as GA-3's retired coroner. They
--   need a freshness check on APPLY DAY, not just a source check.
--
-- Idempotent. Dry-run with BEGIN; ... ROLLBACK; and confirm the rollback reverted.

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_off int;
BEGIN
  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'DeKalb County, Georgia, US';
  IF v_off <> 11 THEN
    RAISE EXCEPTION 'ATL-6 pre-flight: expected 11 DeKalb offices from CC_0242, found % — apply CC_0242 first', v_off;
  END IF;
END $$;

-- ─── 1. Eleven people ────────────────────────────────────────────────────────

CREATE TEMP TABLE dek_people(external_id bigint, full_name text, first_name text, last_name text, alts text[])
  ON COMMIT DROP;

INSERT INTO dek_people(external_id, full_name, first_name, last_name, alts) VALUES
  (-2767941::bigint, 'Lorraine Cochran Johnson', 'Lorraine', 'Cochran Johnson', '{}'::text[]),
  (-2767942::bigint, 'Robert Patrick',           'Robert',   'Patrick',         '{}'::text[]),
  (-2767943::bigint, 'Michelle Long Spears',     'Michelle', 'Long Spears',     '{}'::text[]),
  (-2767944::bigint, 'Nicole Massiah',           'Nicole',   'Massiah',         '{}'::text[]),
  (-2767945::bigint, 'Chakira Johnson',          'Chakira',  'Johnson',         '{}'::text[]),
  (-2767946::bigint, 'Mereda Davis Johnson',     'Mereda',   'Davis Johnson',   '{}'::text[]),
  -- The county's roster says "Ted Terry"; the certified ballot says Edward "Ted" Terry.
  (-2767947::bigint, 'Edward "Ted" Terry',       'Edward',   'Terry',           ARRAY['Ted Terry']),
  -- The county's roster says "LaDena Bolton, PhD"; the certified ballot says LaDena Bolton.
  (-2767948::bigint, 'LaDena Bolton',            'LaDena',   'Bolton',          ARRAY['LaDena Bolton, PhD']),
  (-2767949::bigint, 'Melody M. Maddox',         'Melody',   'Maddox',          '{}'::text[]),
  (-2767950::bigint, 'Debra DeBerry',            'Debra',    'DeBerry',         '{}'::text[]),
  (-2767951::bigint, 'Irvin J. Johnson',         'Irvin',    'Johnson',         '{}'::text[]);

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'DeKalb County, Georgia — the Board of Commissioners roster at dekalbcountyga.gov/government/board-of-commissioners, cross-checked against the Georgia Secretary of State certified returns for the 2024-11-05 general and the 2026-05-19 primary. 🔴 Super District 7 is seated on the 2026 primary''s "(I)" incumbency marker and NOT on the 2024 special, which Jacqueline Adams LED on 45.98% before losing the runoff. Read 2026-10-17 (CC_0243)',
       true, true, n.alts
FROM dek_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. Eleven terms ─────────────────────────────────────────────────────────
-- 🔴 Four offices share the countywide district 13089/G4020 (the CEO and three county officers),
--    so every countywide row joins on the office TITLE as well. And '13089' is ALSO State House
--    District 89 under G5220, so district_type is in the join too.

CREATE TEMP TABLE dek_terms(
  geo_id text, mtfcc text, title text, external_id bigint,
  term_start date, start_precision text, how_started text, unverified boolean
) ON COMMIT DROP;

INSERT INTO dek_terms(geo_id, mtfcc, title, external_id, term_start, start_precision, how_started, unverified) VALUES
  -- 🟢 Dated: no "(I)" marker on the 2024 certified general, so the seat was not hers then.
  ('13089', 'G4020', 'Chief Executive Officer',  -2767941::bigint, '2025-01-01'::date, 'year', 'elected', false),
  ('dekalb-county-ga-commission-1','X0079','Commissioner, District 1', -2767942::bigint, NULL, 'unknown', 'elected', true),
  ('dekalb-county-ga-commission-2','X0079','Commissioner, District 2', -2767943::bigint, NULL, 'unknown', 'elected', true),
  -- ⚠ SPECIAL-election winner: seated on certification, NOT the following January. Date owed.
  ('dekalb-county-ga-commission-3','X0079','Commissioner, District 3', -2767944::bigint, NULL, 'unknown', 'elected', true),
  -- 🟢 Dated: no "(I)" marker on the 2024 certified general.
  ('dekalb-county-ga-commission-4','X0079','Commissioner, District 4', -2767945::bigint, '2025-01-01'::date, 'year', 'elected', false),
  ('dekalb-county-ga-commission-5','X0079','Commissioner, District 5', -2767946::bigint, NULL, 'unknown', 'elected', true),
  ('dekalb-county-ga-super-commission-6','X0080','Commissioner, Super District 6', -2767947::bigint, NULL, 'unknown', 'elected', true),
  -- ⚠ SPECIAL-election winner, via a runoff the first round did not predict. Date owed.
  ('dekalb-county-ga-super-commission-7','X0080','Commissioner, Super District 7', -2767948::bigint, NULL, 'unknown', 'elected', true),
  ('13089', 'G4020', 'Sheriff',                  -2767949::bigint, NULL, 'unknown', 'elected', true),
  ('13089', 'G4020', 'Clerk of Superior Court',  -2767950::bigint, NULL, 'unknown', 'elected', true),
  ('13089', 'G4020', 'Tax Commissioner',         -2767951::bigint, NULL, 'unknown', 'elected', true);

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       CASE WHEN t.unverified THEN
         'DeKalb County, Georgia — holder confirmed current by the county''s own Board of Commissioners roster and by the SOS "(I)" incumbency marker in the 2024-11-05 certified general or the 2026-05-19 primary. Read 2026-10-17 (CC_0243). The START of this occupancy is NOT established. For the two SPECIAL-election winners (District 3 and Super District 7) it is additionally known that January is the WRONG default — a special-election winner is seated on certification, not the following January — so no date is guessed. Written open-ended at ''unknown'' precision. | unverified CC_0243 (2026-10-17): the HOLDER is verified and current; only the start date is unknown, so this term is excluded from office_holders_as_of, where an undated term would otherwise answer every past date'
       ELSE
         'DeKalb County, Georgia — Georgia Secretary of State certified return for the 2024-11-05 general, in which this candidate appears WITHOUT the "(I)" incumbency marker that the sitting DeKalb officials on that ballot carry, so the seat was not theirs at that election; Georgia county officers take office the January following. That gives January 2025, written at ''year'' precision because the inference fixes the year and not the day. This was a REGULAR contest, not a special — the special-election winners on the same ballot are deliberately left undated. Read 2026-10-17 (CC_0243)'
       END
FROM dek_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.mtfcc = t.mtfcc AND d.district_type = 'COUNTY' AND lower(d.state) = 'ga'
JOIN essentials.offices o ON o.district_id = d.id AND o.title = t.title
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'DeKalb County, Georgia, US'
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_terms int; v_seated int; v_noninc int; v_dup int;
  v_untag int; v_tagged int; v_hist int; v_johnson int; v_leg int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2767951 AND -2767941;
  IF v_people <> 11 THEN RAISE EXCEPTION 'ATL-6 gate: expected 11 DeKalb people, found %', v_people; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'DeKalb County, Georgia, US';
  IF v_terms <> 11 THEN RAISE EXCEPTION 'ATL-6 gate: expected 11 DeKalb office_terms rows, found %', v_terms; END IF;

  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'DeKalb County, Georgia, US';
  IF v_seated <> 11 THEN
    RAISE EXCEPTION 'ATL-6 gate: expected 11 SEATED DeKalb offices, found % — DeKalb has no vacancies', v_seated;
  END IF;

  SELECT count(*) INTO v_noninc FROM essentials.politicians p
   WHERE p.external_id BETWEEN -2767951 AND -2767941
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_noninc <> 0 THEN
    RAISE EXCEPTION 'ATL-6 gate: % DeKalb official(s) are not is_incumbent/is_active — they would be HIDDEN from address search', v_noninc;
  END IF;

  SELECT count(*) INTO v_dup FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'DeKalb County, Georgia, US'
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'ATL-6 gate: % person(s) hold more than one DeKalb office', v_dup; END IF;

  -- 🔴 THE FOUR JOHNSONS MUST REMAIN FOUR DISTINCT (first_name, last_name) PAIRS.
  SELECT count(DISTINCT (p.first_name, p.last_name)) INTO v_johnson
    FROM essentials.politicians p
   WHERE p.external_id BETWEEN -2767951 AND -2767941
     AND p.last_name LIKE '%Johnson';
  IF v_johnson <> 4 THEN
    RAISE EXCEPTION 'ATL-6 gate: expected 4 DISTINCT Johnson name-pairs on the DeKalb roster, found % — two of these four people have been collapsed into one', v_johnson;
  END IF;

  SELECT count(*) INTO v_untag FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'DeKalb County, Georgia, US'
     AND ot.term_start IS NULL
     AND COALESCE(ot.source, '') NOT LIKE '%| unverified %';
  IF v_untag <> 0 THEN
    RAISE EXCEPTION 'ATL-6 gate: % DeKalb term(s) have a NULL term_start and are NOT tagged "| unverified " — each would answer EVERY past date', v_untag;
  END IF;

  SELECT count(*) INTO v_tagged FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'DeKalb County, Georgia, US'
     AND COALESCE(ot.source, '') LIKE '%| unverified %';
  IF v_tagged <> 9 THEN
    RAISE EXCEPTION 'ATL-6 gate: expected exactly 9 tagged-unverified DeKalb terms, found % — the CEO and District 4 are dated and must NOT carry the tag', v_tagged;
  END IF;

  -- 🔴 THE TAG MUST BITE. Nobody seated here began before 2025, so 2015 must return nothing.
  SELECT count(*) INTO v_hist FROM essentials.office_holders_as_of(DATE '2015-06-01') h
    JOIN essentials.offices o ON o.id = h.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'DeKalb County, Georgia, US';
  IF v_hist <> 0 THEN
    RAISE EXCEPTION 'ATL-6 gate: office_holders_as_of(2015-06-01) returns % DeKalb holder(s); expected 0 — an undated term is leaking into history', v_hist;
  END IF;

  SELECT count(*) INTO v_leg FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Georgia'
     AND c.name IN ('Georgia House of Representatives', 'Georgia State Senate');
  IF v_leg <> 236 THEN
    RAISE EXCEPTION 'ATL-6 gate CONTROL: expected 236 Georgia legislative offices, found % — wrong database', v_leg;
  END IF;

  RAISE NOTICE 'ATL-6 OK: 11 people, 11 terms, 11 seated, 0 vacancies, 4 distinct Johnsons, 2 dated + 9 tagged-unverified, history clean at 2015, control 236 legislative offices present';
END $$;
