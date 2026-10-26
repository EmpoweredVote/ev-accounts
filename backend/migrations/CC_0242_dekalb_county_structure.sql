-- CC_0242_dekalb_county_structure.sql
--
-- Atlanta full seed, stage 4b, DEKALB COUNTY STRUCTURE half.
--   * 1 government, 3 chambers
--   * 7 new districts -- 5 single-member (X0079) + 2 SUPER (X0080); countywide reuses 13089/G4020
--   * 11 offices -- CEO + 5 district commissioners + 2 super commissioners + 3 county officers
--
-- Roster: backend/data/seed-atlanta-2026/ROSTERS.md
-- Boundaries: scripts/load-dekalb-commission-districts.mjs MUST RUN FIRST (X0079 and X0080).
-- Slot CC_0242 was RESERVED FROM THE ALLOCATOR before this file was named.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 EVERY DEKALB ADDRESS HAS **TWO** COMMISSIONERS, AND THAT IS CORRECT.
--
-- Districts 1-5 are single-member. Super Districts 6 and 7 each overlay about half the county,
-- so the two layers DELIBERATELY OVERLAP and sit on separate MTFCCs. Measured 2026-10-17:
-- each single-member district holds 152,106-154,029 people; each super holds 381,445 and
-- 382,937. Both sets tile the county to the same 702.303 km².
--
-- 🔴 A PER-DISTRICT POSITIVE CONTROL ASSERTING "EXACTLY ONE HOLDER" IS WRONG HERE and fails on
--    correct data. Assert exactly one DISTRICT commissioner AND exactly one SUPER commissioner.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 DEKALB AND FULTON ARE STRUCTURALLY OPPOSITE. DO NOT STANDARDISE THEM.
--
--            at-large chair   county-wide executive   super districts
--   Fulton        YES                  no                   no
--   DeKalb         no          YES, an elected CEO         YES, two
--
-- DeKalb is the only Georgia county that elects a CEO. The CEO is a county-wide elected
-- executive and is NOT a commission chair — the board has 7 members and no at-large chair.
-- Describing either county in the other's shape misdescribes both.
--
-- ---------------------------------------------------------------------------
-- 🔴 THREE COUNTY OFFICERS, READ OFF THE CERTIFIED BALLOT, NOT INHERITED FROM FULTON.
--
-- Sheriff, Clerk of Superior Court and Tax Commissioner are on DeKalb's 2024 certified general.
-- Excluded, each for a stated reason:
--
--   Solicitor General, District Attorney (Stone Mountain Judicial Circuit)
--       prosecutors — the FL-5 rule. ⚠ As in Fulton, the multi-county leg of that rule does not
--       apply: the Stone Mountain circuit is DeKalb alone. They stay out on the prosecutor rule.
--   Chief Magistrate, State Court and Superior Court judges
--       judicial branch, Ga. Const. Art. VI. DeKalb elects its Chief Magistrate on the general
--       ballot; Georgia's Chief Magistrate was already excluded in GA-3.
--   County Board of Education   spec §11.
--
-- 🔴 NO SURVEYOR. Fulton elects one; DeKalb does not, and no Surveyor contest appears in any
--    DeKalb return 2020-2026. ga.md: Coroner and Surveyor are seated only where the county
--    GENUINELY elects them, never inherited from another county's template.
--
-- 🔴 NO PROBATE JUDGE and NO CORONER, for the same reasons as Fulton (CC_0240): a certified
--    return enumerates CONTESTS, not OFFICES, and Georgia declares an unopposed nonpartisan
--    candidate elected without a ballot. Recorded as owed, ROSTERS.md open items 1 and 2.
--    Creating either office with no term row would make it INVISIBLE.
--
-- ---------------------------------------------------------------------------
-- Idempotent. Dry-run with BEGIN; ... ROLLBACK; and confirm the rollback reverted.

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_d int; v_s int; v_dup int; v_cty int;
BEGIN
  SELECT count(*) INTO v_d FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0079' AND state = '13' AND geo_id LIKE 'dekalb-county-ga-commission-%';
  IF v_d <> 5 THEN
    RAISE EXCEPTION 'ATL-5 pre-flight: expected 5 X0079 DeKalb commission polygons, found % — run scripts/load-dekalb-commission-districts.mjs first. An office on a district with no polygon is unreachable by any address and nothing errors.', v_d;
  END IF;

  SELECT count(*) INTO v_s FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0080' AND state = '13' AND geo_id LIKE 'dekalb-county-ga-super-commission-%';
  IF v_s <> 2 THEN
    RAISE EXCEPTION 'ATL-5 pre-flight: expected 2 X0080 DeKalb SUPER commission polygons, found %', v_s;
  END IF;

  SELECT count(*) INTO v_dup FROM essentials.geofence_boundaries
   WHERE (mtfcc = 'X0079' AND geo_id NOT LIKE 'dekalb-county-ga-commission-%')
      OR (mtfcc = 'X0080' AND geo_id NOT LIKE 'dekalb-county-ga-super-commission-%');
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'ATL-5 pre-flight: % X0079/X0080 polygon(s) are not DeKalb commission districts — somebody else took a code', v_dup;
  END IF;

  -- 🔴 geo_id '13089' is BOTH DeKalb County (G4020) AND State House District 89 (G5220) in this
  --    very database, and the G5220 row already carries an office. The pair is the key.
  SELECT count(*) INTO v_cty FROM essentials.districts
   WHERE geo_id = '13089' AND mtfcc = 'G4020' AND district_type = 'COUNTY' AND lower(state) = 'ga';
  IF v_cty <> 1 THEN
    RAISE EXCEPTION 'ATL-5 pre-flight: expected exactly 1 DeKalb COUNTY district 13089/G4020, found %', v_cty;
  END IF;
END $$;

-- ─── 1. The government ───────────────────────────────────────────────────────

INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'DeKalb County, Georgia, US', 'County', 'GA', NULL, '13089', 'G4020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'DeKalb County, Georgia, US');

-- ─── 2. Three chambers ───────────────────────────────────────────────────────
-- Board official_count 7 = 5 single-member + 2 super. The CEO is NOT on the board.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT g.id, v.name, v.name, v.official_count, '4'
FROM essentials.governments g
JOIN (VALUES
  ('Board of Commissioners',                7),
  ('Office of the Chief Executive Officer', 1),
  ('DeKalb County Elected Officials',       3)
) AS v(name, official_count) ON true
WHERE g.name = 'DeKalb County, Georgia, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ─── 3. Seven districts (the countywide row already exists) ─────────────────

CREATE TEMP TABLE dek_districts(geo_id text, label text, mtfcc text) ON COMMIT DROP;
INSERT INTO dek_districts(geo_id, label, mtfcc) VALUES
  ('dekalb-county-ga-commission-1',       'DeKalb County Commission District 1',       'X0079'),
  ('dekalb-county-ga-commission-2',       'DeKalb County Commission District 2',       'X0079'),
  ('dekalb-county-ga-commission-3',       'DeKalb County Commission District 3',       'X0079'),
  ('dekalb-county-ga-commission-4',       'DeKalb County Commission District 4',       'X0079'),
  ('dekalb-county-ga-commission-5',       'DeKalb County Commission District 5',       'X0079'),
  ('dekalb-county-ga-super-commission-6', 'DeKalb County Super Commission District 6', 'X0080'),
  ('dekalb-county-ga-super-commission-7', 'DeKalb County Super Commission District 7', 'X0080');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT n.geo_id, n.label, 'COUNTY', 'ga', n.mtfcc, 1
FROM dek_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'COUNTY');

-- Countywide: the CEO plus the three county officers.
UPDATE essentials.districts
   SET num_officials = 4
 WHERE geo_id = '13089' AND mtfcc = 'G4020' AND district_type = 'COUNTY' AND lower(state) = 'ga'
   AND num_officials IS DISTINCT FROM 4;

-- ─── 4. Eleven offices ───────────────────────────────────────────────────────

CREATE TEMP TABLE dek_offices(geo_id text, mtfcc text, chamber_name text, title text) ON COMMIT DROP;
INSERT INTO dek_offices(geo_id, mtfcc, chamber_name, title) VALUES
  ('13089',                              'G4020', 'Office of the Chief Executive Officer', 'Chief Executive Officer'),
  ('dekalb-county-ga-commission-1',      'X0079', 'Board of Commissioners', 'Commissioner, District 1'),
  ('dekalb-county-ga-commission-2',      'X0079', 'Board of Commissioners', 'Commissioner, District 2'),
  ('dekalb-county-ga-commission-3',      'X0079', 'Board of Commissioners', 'Commissioner, District 3'),
  ('dekalb-county-ga-commission-4',      'X0079', 'Board of Commissioners', 'Commissioner, District 4'),
  ('dekalb-county-ga-commission-5',      'X0079', 'Board of Commissioners', 'Commissioner, District 5'),
  ('dekalb-county-ga-super-commission-6','X0080', 'Board of Commissioners', 'Commissioner, Super District 6'),
  ('dekalb-county-ga-super-commission-7','X0080', 'Board of Commissioners', 'Commissioner, Super District 7'),
  ('13089',                              'G4020', 'DeKalb County Elected Officials', 'Sheriff'),
  ('13089',                              'G4020', 'DeKalb County Elected Officials', 'Clerk of Superior Court'),
  ('13089',                              'G4020', 'DeKalb County Elected Officials', 'Tax Commissioner');

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, n.title, 'GA', NULL, 1, false, 'full'
FROM dek_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'COUNTY' AND lower(d.state) = 'ga'
JOIN essentials.governments g ON g.name = 'DeKalb County, Georgia, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = n.title);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_ch int; v_d int; v_s int; v_off int;
  v_board int; v_ceo int; v_offs int;
  v_vacant int; v_titles int; v_nogeom int; v_overlay int; v_super_hits int; v_leg int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'DeKalb County, Georgia, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'ATL-5 gate: expected 1 DeKalb government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'DeKalb County, Georgia, US';
  IF v_ch <> 3 THEN RAISE EXCEPTION 'ATL-5 gate: expected 3 DeKalb chambers, found %', v_ch; END IF;

  SELECT count(*) FILTER (WHERE mtfcc = 'X0079'), count(*) FILTER (WHERE mtfcc = 'X0080')
    INTO v_d, v_s
    FROM essentials.districts
   WHERE mtfcc IN ('X0079','X0080') AND district_type = 'COUNTY' AND lower(state) = 'ga';
  IF v_d <> 5 OR v_s <> 2 THEN
    RAISE EXCEPTION 'ATL-5 gate: expected 5 single-member and 2 SUPER DeKalb districts, found % and %', v_d, v_s;
  END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'DeKalb County, Georgia, US';
  IF v_off <> 11 THEN RAISE EXCEPTION 'ATL-5 gate: expected 11 DeKalb offices, found %', v_off; END IF;

  SELECT
    count(*) FILTER (WHERE c.name = 'Board of Commissioners'),
    count(*) FILTER (WHERE c.name = 'Office of the Chief Executive Officer'),
    count(*) FILTER (WHERE c.name = 'DeKalb County Elected Officials')
    INTO v_board, v_ceo, v_offs
  FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'DeKalb County, Georgia, US';
  IF v_board <> 7 OR v_ceo <> 1 OR v_offs <> 3 THEN
    RAISE EXCEPTION 'ATL-5 gate: expected 7 board + 1 CEO + 3 county officers, found % / % / %', v_board, v_ceo, v_offs;
  END IF;

  SELECT count(*) INTO v_vacant FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'DeKalb County, Georgia, US' AND o.is_vacant;
  IF v_vacant <> 0 THEN RAISE EXCEPTION 'ATL-5 gate: expected 0 vacant DeKalb offices, found %', v_vacant; END IF;

  SELECT count(DISTINCT o.title) INTO v_titles FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'DeKalb County, Georgia, US';
  IF v_titles <> 11 THEN RAISE EXCEPTION 'ATL-5 gate: expected 11 DISTINCT DeKalb office titles, found %', v_titles; END IF;

  SELECT count(*) INTO v_nogeom FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'DeKalb County, Georgia, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'ATL-5 gate: % DeKalb office(s) sit on a district with NO polygon — unreachable by any address', v_nogeom;
  END IF;

  -- 🔴🔴 THE OVERLAY ASSERTION, IN THE DATABASE, AT AN ADDRESS.
  --    1300 Commerce Dr, Decatur (the DeKalb County HQ, geocoded) must resolve to EXACTLY ONE
  --    single-member district AND EXACTLY ONE super district. The usual "exactly one holder"
  --    control would fail here on correct data, which is the whole point of writing it this way.
  SELECT count(*) FILTER (WHERE d.mtfcc = 'X0079'),
         count(*) FILTER (WHERE d.mtfcc = 'X0080')
    INTO v_overlay, v_super_hits
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries b ON b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
   WHERE d.mtfcc IN ('X0079','X0080')
     AND public.ST_Contains(b.geometry, public.ST_SetSRID(public.ST_MakePoint(-84.298959, 33.774513), 4326));
  IF v_overlay <> 1 OR v_super_hits <> 1 THEN
    RAISE EXCEPTION 'ATL-5 gate: the DeKalb County HQ resolves to % single-member district(s) and % super district(s); expected exactly 1 of EACH. Every DeKalb address must have TWO commissioners.', v_overlay, v_super_hits;
  END IF;

  SELECT count(*) INTO v_leg FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Georgia'
     AND c.name IN ('Georgia House of Representatives', 'Georgia State Senate');
  IF v_leg <> 236 THEN
    RAISE EXCEPTION 'ATL-5 gate CONTROL: expected 236 Georgia legislative offices, found % — wrong database', v_leg;
  END IF;

  RAISE NOTICE 'ATL-5 OK: 1 government, 3 chambers, 5+2 districts, 11 offices (7 board + CEO + 3 officers), 0 vacant, county HQ resolves to one district AND one super, control 236 legislative offices present';
END $$;
