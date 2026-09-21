-- CA_0130_seed_la_boe_district3_2026_general.sql
-- California 2026 general: State Board of Equalization, District 3. After the 2020
-- redistricting, BOE District 3 IS Los Angeles County, so only LA County voters vote in it.
-- Adds it to 'CA 2026 Statewide General' (id 728d0074-8a8d-49e3-a68c-78ccdd15434f).
--
-- 🔴 MODELING — this is a DISTRICT-based statewide-board seat, so it must be matched by
-- geofence (Part A) ONLY, and must NOT leak to the whole state via the Part B statewide
-- fallback (which pulls any race whose district_type is STATE_EXEC/NATIONAL_UPPER/NATIONAL_EXEC
-- for the state). Therefore:
--   * geofence the district to LA County (geo_id '06037'), NOT the all-CA '06' district the
--     executive offices use, and
--   * use district_type 'STATE_BOARD' — it starts with 'STATE' so the app tiers it under
--     "State" (getTier), but it is NOT in STATEWIDE_DISTRICT_TYPES, so Part B ignores it.
-- Net: an LA-County address matches it via geofence; no other California address sees it.
--
-- ADDS 1 RACE / 2 CANDIDATES (certified top-two; D-vs-D; primary_party NULL; antipartisan):
--   State Board of Equalization, 3rd District   Mike Gipson (D), Samuel P. Sukaton (D)
-- Both open-seat challengers -> politician_id NULL.
--
-- SOURCE: California Secretary of State Official Certified List of Candidates, 8/27/2026;
-- BOE-3 = Los Angeles County per the SoS BOE district map. Retrieved 2026-09-21.
--
-- IDEMPOTENCY: district guard (district_type,state,label); office (district,title);
-- race (election_id,position_name); candidates (race_id,lower(full_name)).

BEGIN;

-- ─── District (geofenced to LA County) + office ─────────────────────────────────────────
INSERT INTO essentials.districts (district_type, state, geo_id, label, mtfcc, district_id, ocd_id)
SELECT 'STATE_BOARD', 'CA', '06037', 'California Board of Equalization District 3', '', '',
       'ocd-division/country:us/state:ca/sboe:3'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type='STATE_BOARD' AND state='CA' AND label='California Board of Equalization District 3'
);

INSERT INTO essentials.offices
  (title, district_id, partisan_type, representing_state, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT 'Board of Equalization District 3', d.id, NULL, 'CA', 1, false, false, false
FROM essentials.districts d
WHERE d.district_type='STATE_BOARD' AND d.state='CA' AND d.label='California Board of Equalization District 3'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title='Board of Equalization District 3'
  );

-- ─── Race ───────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid, o.id, 'State Board of Equalization, 3rd District', NULL, 1
FROM essentials.offices o
JOIN essentials.districts d ON d.id=o.district_id
WHERE d.district_type='STATE_BOARD' AND d.state='CA' AND d.label='California Board of Equalization District 3'
  AND o.title='Board of Equalization District 3'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r
    WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
      AND r.position_name='State Board of Equalization, 3rd District'
  );

-- ─── Candidates ─────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE boe_cand_seed (full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO boe_cand_seed VALUES
  ('Mike Gipson',       'Mike',   'Gipson'),
  ('Samuel P. Sukaton', 'Samuel', 'Sukaton');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, NULL::uuid, cs.full_name, cs.first_name, cs.last_name, false, 'active',
       'California Secretary of State Official Certified List of Candidates, 8/27/2026 (BOE District 3 = Los Angeles County per SoS BOE map). Retrieved 2026-09-21.'
FROM boe_cand_seed cs
JOIN essentials.races r
  ON r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
 AND r.position_name='State Board of Equalization, 3rd District'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_race int; v_cands int; v_geo int; v_leak int; v_party int;
BEGIN
  SELECT count(*) INTO v_race FROM essentials.races
   WHERE election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND position_name='State Board of Equalization, 3rd District';

  SELECT count(*) INTO v_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND r.position_name='State Board of Equalization, 3rd District';

  -- office must sit on the LA-County geofence
  SELECT count(*) INTO v_geo FROM essentials.races r
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND r.position_name='State Board of Equalization, 3rd District'
     AND d.geo_id='06037'
     AND EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id='06037');

  -- must NOT be a Part B statewide type (would leak to all CA)
  SELECT count(*) INTO v_leak FROM essentials.races r
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND r.position_name='State Board of Equalization, 3rd District'
     AND d.district_type = ANY(ARRAY['STATE_EXEC','NATIONAL_UPPER','NATIONAL_EXEC']);

  SELECT count(*) INTO v_party FROM essentials.races
   WHERE election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND position_name='State Board of Equalization, 3rd District' AND primary_party IS NOT NULL;

  IF v_race  <> 1 THEN RAISE EXCEPTION 'BOE-3 race: expected 1, got %', v_race; END IF;
  IF v_cands <> 2 THEN RAISE EXCEPTION 'BOE-3 candidates: expected 2, got %', v_cands; END IF;
  IF v_geo   <> 1 THEN RAISE EXCEPTION 'BOE-3 not on the LA-County (06037) geofence'; END IF;
  IF v_leak  <> 0 THEN RAISE EXCEPTION 'BOE-3 uses a Part B statewide district_type — would leak to all CA'; END IF;
  IF v_party <> 0 THEN RAISE EXCEPTION 'BOE-3 race carries primary_party'; END IF;
END $$;

COMMIT;
