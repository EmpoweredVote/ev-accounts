-- CC_0529_la_quinta_city_government.sql
-- CC_0529: City of La Quinta, CA (place 0640354, Riverside County) -- the elected city government, which did not exist.
--
-- WHAT WAS THERE (read 2026-11-28). Only the TIGER G4110 outline 'La Quinta city' (geo_id '0640354'). No government,
-- chamber, district, office or person. (Schools: La Quinta is Desert Sands Unified, seated by CC_0524 -- City Hall is in
-- DSUSD Trustee Area 3 -- plus a sliver of Coachella Valley Unified, CC_0525.)
--
-- THE GOVERNMENT. laquintaca.gov (read 2026-11-28; Akamai blocks curl, read with headless Chrome):
--   business/city-council/council-member-profiles: "LINDA EVANS, MAYOR" ("elected Mayor in 2014, and is currently in
--   her sixth term"), "KATHLEEN FITZPATRICK, MAYOR PRO TEM", "DEBORAH McGARREY, COUNCIL MEMBER", John Peña, "STEVE
--   SANCHEZ, COUNCIL MEMBER".
--   business/city-council/frequently-asked-questions: "La Quinta City Councilmembers are elected 'at large' ...";
--   "City Councilmembers serve four-year terms, with the Mayor serving a two-year term"; "The Mayor is selected through
--   a public election process. The Mayor Pro Tem is selected by the City Council from among its own members ... Both
--   the Mayor and Mayor Pro Tem have the same voting power as any other Councilmember."
--   business: "The City Clerk is an appointed staff position" and "The City Treasurer is an appointed staff position"
--   -> NEITHER IS SEATED HERE (this corpus seats elected offices; contrast Indio and Coachella, which elect both).
-- SHAPE: the Hawthorne / Coachella (CC_0527) shape -- four councilmember offices on a LOCAL G4110 district, the Mayor in
-- its own chamber on a LOCAL_EXEC G4110 district, voting_powers 'full' (the FAQ: the same voting power as any other
-- Councilmember). Mayor Pro Tem is a council-assigned role, kept in Fitzpatrick's office description, not the title.
--
-- 2026 ELECTION -- NO CHANGE OF HOLDER. Riverside ROV, update #27 (2026-11-25):
--   Mayor: Linda Evans 11,296 (75.50%), Lynne Langdon 2,136, Suzanne Espinoza-Jimenez 1,529 -> Evans re-elected.
--   Council (vote for 2): John Pena 9,677 (40.21%), Deborah McGarrey 8,904 (36.99%), Carene Hensley 2,756, Julian
--   Herrera 2,732 -> both incumbents re-elected (the ROV final candidate list names incumbents "John J. Pena" and
--   "Deborah McGarrey"). Fitzpatrick and Sanchez were not up.
--   ⚠ The same candidate list names the Mayor contest's incumbent "Linda Marie Bender" while the ballot and the city say
--   Linda Evans. Recorded here only; NOT added as an alternate name, because nothing read proves it is the same person.
-- TERMS: open-ended, start_precision 'unknown' -- the city gives first-elected years (Evans Mayor 2014; Fitzpatrick and
-- Sanchez council 2016; Peña council 1984 with a gap), which are how they ARRIVED, not current-term starts.
--
-- PEOPLE. No politician row matched any of the five names on 2026-11-28. external_id -4012201..-4012205 (unused block).
-- 'John Peña' as the city writes it; the ROV writes 'John Pena' / 'John J. Pena' -> alternates. Party is never stored.
--
-- Apply with: node scripts/apply-migration-file.mjs migrations/CC_0529_la_quinta_city_government.sql
BEGIN;

-- ─── 0. Preconditions ───
DO $$
DECLARE n int;
BEGIN
  PERFORM 1 FROM essentials.geofence_boundaries WHERE mtfcc = 'G4110' AND geo_id = '0640354';
  IF NOT FOUND THEN RAISE EXCEPTION 'CC_0529 precondition: no G4110 outline for La Quinta (0640354)'; END IF;
  SELECT count(*) INTO n FROM essentials.governments
   WHERE (geo_id = '0640354' OR name ILIKE 'City of La Quinta%') AND id <> 'ddf5f2f5-8fce-4cdc-9f0a-87a287cc1c17';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0529 precondition: another City of La Quinta government exists (%)', n; END IF;
  SELECT count(*) INTO n FROM essentials.districts
   WHERE geo_id = '0640354' AND id NOT IN ('cda32654-0de8-43d5-8cc4-e0b222ffde5e', '6778ae00-1b99-445a-bdd9-206b53b9189a');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0529 precondition: a district on geo_id 0640354 already exists (%)', n; END IF;
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE external_id BETWEEN -4012205 AND -4012201
     AND id NOT IN ('ac2c538d-62f2-44fe-9522-04b0ba67471a','bda43e19-e04a-47ae-b057-224927e55ad0','1f3fffda-43d7-405f-8913-56ea9b0b0bbd',
                    '8098a198-d452-4e68-ab0f-b2c9ddc3d3f8','41208252-af67-4abf-bb02-7ca00f34221c');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0529 precondition: an external_id in -4012205..-4012201 belongs to someone else'; END IF;
END $$;

-- ─── 1. Government, districts, chambers ───
INSERT INTO essentials.governments (id, name, type, state, city, geo_id, mtfcc)
SELECT 'ddf5f2f5-8fce-4cdc-9f0a-87a287cc1c17'::uuid, 'City of La Quinta, California, US', 'City', 'CA', 'La Quinta', '0640354', 'G4110'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE id = 'ddf5f2f5-8fce-4cdc-9f0a-87a287cc1c17'::uuid);

INSERT INTO essentials.districts (id, label, district_type, district_id, state, num_officials, mtfcc, geo_id,
                                  is_judicial, has_unknown_boundaries, retention, representation_basis, ocd_id, official_web_url)
SELECT v.id, v.label, v.dtype, '0', 'CA', v.n, 'G4110', '0640354', false, false, false, 'residency',
       'ocd-division/country:us/state:ca/place:la_quinta', 'https://www.laquintaca.gov/business/city-council'
  FROM (VALUES
    ('cda32654-0de8-43d5-8cc4-e0b222ffde5e'::uuid, 'La Quinta City Council (At-Large)', 'LOCAL', 4),
    ('6778ae00-1b99-445a-bdd9-206b53b9189a'::uuid, 'La Quinta Mayor', 'LOCAL_EXEC', 1)
  ) AS v(id, label, dtype, n)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.id = v.id);

INSERT INTO essentials.chambers (id, government_id, name, name_formal, official_count, website_url, policy_engagement_level)
SELECT v.id, 'ddf5f2f5-8fce-4cdc-9f0a-87a287cc1c17'::uuid, v.name, v.nf, v.n, 'https://www.laquintaca.gov/business/city-council', 'full' FROM (VALUES
    ('a2e79dcc-af96-40e6-871e-f90bd542b51e'::uuid, 'City Council', 'La Quinta City Council', 4),
    ('865db17c-934c-4b39-b7c2-df400e33a6c1'::uuid, 'Mayor', 'Mayor of La Quinta', 1)
  ) AS v(id, name, nf, n) WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.id = v.id);

-- ─── 2. Offices ───
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, representing_city, seats, normalized_position_name,
                                is_appointed_position, is_vacant, faces_retention_vote, voting_powers, description)
SELECT v.oid, v.cid, v.did, v.title, 'CA', 'La Quinta', 1, v.title, false, false, false, 'full', v.descr
  FROM (VALUES
    ('b1f88e15-f727-4710-a82e-406ca829c071'::uuid, '865db17c-934c-4b39-b7c2-df400e33a6c1'::uuid, '6778ae00-1b99-445a-bdd9-206b53b9189a'::uuid, 'Mayor',
     'Directly elected citywide to a two-year term; presides over the City Council with the same vote as any other member (laquintaca.gov FAQ).'),
    ('de3ff0f8-e731-4683-a7a9-5dc967c355cf'::uuid, 'a2e79dcc-af96-40e6-871e-f90bd542b51e'::uuid, 'cda32654-0de8-43d5-8cc4-e0b222ffde5e'::uuid, 'Councilmember',
     'Elected at large to a four-year term. Serving as Mayor Pro Tem (selected by the council from its members; laquintaca.gov, 2026-11-28).'),
    ('a9b446e5-c388-42dd-bcb6-4e709c82e273'::uuid, 'a2e79dcc-af96-40e6-871e-f90bd542b51e'::uuid, 'cda32654-0de8-43d5-8cc4-e0b222ffde5e'::uuid, 'Councilmember',
     'Elected at large to a four-year term.'),
    ('bc270f01-1084-41c5-abba-f4474d273898'::uuid, 'a2e79dcc-af96-40e6-871e-f90bd542b51e'::uuid, 'cda32654-0de8-43d5-8cc4-e0b222ffde5e'::uuid, 'Councilmember',
     'Elected at large to a four-year term.'),
    ('39d074d1-559b-464b-80f7-52af9400bb2e'::uuid, 'a2e79dcc-af96-40e6-871e-f90bd542b51e'::uuid, 'cda32654-0de8-43d5-8cc4-e0b222ffde5e'::uuid, 'Councilmember',
     'Elected at large to a four-year term.')
  ) AS v(oid, cid, did, title, descr)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = v.oid);

-- ─── 3. People ───
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, alternate_names, is_active, source)
SELECT v.id, v.ext, v.n, v.f, v.l, v.alt, true,
       'laquintaca.gov council-member-profiles (read 2026-11-28); Riverside ROV Nov 3 2026 (CC_0529)'
  FROM (VALUES
    ('ac2c538d-62f2-44fe-9522-04b0ba67471a'::uuid, -4012201, 'Linda Evans', 'Linda', 'Evans', ARRAY[]::text[]),
    ('bda43e19-e04a-47ae-b057-224927e55ad0'::uuid, -4012202, 'Kathleen Fitzpatrick', 'Kathleen', 'Fitzpatrick', ARRAY[]::text[]),
    ('1f3fffda-43d7-405f-8913-56ea9b0b0bbd'::uuid, -4012203, 'Deborah McGarrey', 'Deborah', 'McGarrey', ARRAY[]::text[]),
    ('8098a198-d452-4e68-ab0f-b2c9ddc3d3f8'::uuid, -4012204, 'John Peña', 'John', 'Peña', ARRAY['John Pena','John J. Pena']::text[]),
    ('41208252-af67-4abf-bb02-7ca00f34221c'::uuid, -4012205, 'Steve Sanchez', 'Steve', 'Sanchez', ARRAY[]::text[])
  ) AS v(id, ext, n, f, l, alt)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id);

CREATE TEMP TABLE cc0529_plan ON COMMIT DROP AS
SELECT unnest(ARRAY['ac2c538d-62f2-44fe-9522-04b0ba67471a','bda43e19-e04a-47ae-b057-224927e55ad0','1f3fffda-43d7-405f-8913-56ea9b0b0bbd',
                    '8098a198-d452-4e68-ab0f-b2c9ddc3d3f8','41208252-af67-4abf-bb02-7ca00f34221c']::uuid[]) AS politician_id;

-- ▼▼ BLOCK A (backend/migrations/_templates/office_terms_incumbency_guard.sql) ▼▼
-- @incumbency-decision: gated — opens five undated La Quinta terms; no handover (all 2026 winners were incumbents); none has a race row
CREATE TEMP TABLE incumbency_before ON COMMIT DROP AS
SELECT rc.id              AS race_candidate_id,
       rc.politician_id,
       rc.is_incumbent    AS stored,
       EXISTS (SELECT 1 FROM essentials.office_terms t
                 JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id
                  AND (t.office_id = r.office_id
                       OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
              )            AS expected
  FROM essentials.race_candidates rc
  JOIN essentials.races     r  ON r.id  = rc.race_id
  JOIN essentials.offices   ro ON ro.id = r.office_id
  JOIN essentials.elections e  ON e.id  = r.election_id
 WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
   AND rc.politician_id IS NOT NULL
   AND rc.politician_id IN (SELECT politician_id FROM cc0529_plan);
-- ▲▲ END OF BLOCK A ▲▲

-- ─── 4. Terms (open-ended, start unknown) ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT v.oid, v.pid, NULL, 'unknown', 'elected', v.src || ' Start of current tenure not dated. (CC_0529)'
  FROM (VALUES
    ('b1f88e15-f727-4710-a82e-406ca829c071'::uuid, 'ac2c538d-62f2-44fe-9522-04b0ba67471a'::uuid, 'laquintaca.gov: Mayor, "elected Mayor in 2014 ... sixth term"; re-elected 2026-11-03 (11,296 votes, 75.50%).'),
    ('de3ff0f8-e731-4683-a7a9-5dc967c355cf'::uuid, 'bda43e19-e04a-47ae-b057-224927e55ad0'::uuid, 'laquintaca.gov: Council Member (Mayor Pro Tem), "elected to the City Council in 2016".'),
    ('a9b446e5-c388-42dd-bcb6-4e709c82e273'::uuid, '1f3fffda-43d7-405f-8913-56ea9b0b0bbd'::uuid, 'laquintaca.gov: Council Member; re-elected 2026-11-03 (8,904 votes).'),
    ('bc270f01-1084-41c5-abba-f4474d273898'::uuid, '8098a198-d452-4e68-ab0f-b2c9ddc3d3f8'::uuid, 'laquintaca.gov: Council Member, first elected 1984; re-elected 2026-11-03 (9,677 votes).'),
    ('39d074d1-559b-464b-80f7-52af9400bb2e'::uuid, '41208252-af67-4abf-bb02-7ca00f34221c'::uuid, 'laquintaca.gov: Council Member, "on the La Quinta City Council since 2016 ... third term".')
  ) AS v(oid, pid, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v.oid);

-- ▼▼ BLOCK B ▼▼
DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0529_plan;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;
  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the plan table is EMPTY, so this gate asserted nothing. '
      'Point it at the politicians whose office_terms rows this migration writes.';
  END IF;
  RAISE NOTICE 'incumbency guard: % person/people planned, % with a race row in the last year (% row(s))',
    v_planned, v_people, v_scoped;

  WITH after_state AS (
    SELECT rc.id              AS race_candidate_id,
           rc.is_incumbent    AS stored,
           EXISTS (SELECT 1 FROM essentials.office_terms t
                     JOIN essentials.offices o2 ON o2.id = t.office_id
                    WHERE t.politician_id = rc.politician_id
                      AND (t.office_id = r.office_id
                           OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                      AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                      AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
                  )            AS expected
      FROM essentials.race_candidates rc
      JOIN essentials.races     r  ON r.id  = rc.race_id
      JOIN essentials.offices   ro ON ro.id = r.office_id
      JOIN essentials.elections e  ON e.id  = r.election_id
     WHERE rc.id IN (SELECT race_candidate_id FROM incumbency_before)
  ),
  cmp AS (
    SELECT b.race_candidate_id,
           b.politician_id,
           a.stored,
           a.expected,
           (b.stored IS DISTINCT FROM b.expected) AS drifted_before,
           (a.stored IS DISTINCT FROM a.expected) AS drifted_after
      FROM incumbency_before b
      JOIN after_state a USING (race_candidate_id)
  )
  SELECT count(*) FILTER (WHERE NOT c.drifted_before AND c.drifted_after),
         count(*) FILTER (WHERE c.drifted_before AND NOT c.drifted_after),
         string_agg(
           format('    %s — race_candidate %s says is_incumbent=%s, office_terms now say %s',
                  coalesce(p.full_name, '(unnamed)'), c.race_candidate_id, c.stored, c.expected),
           E'\n' ORDER BY coalesce(p.full_name, ''))
           FILTER (WHERE NOT c.drifted_before AND c.drifted_after)
    INTO v_created, v_repaired, v_detail
    FROM cmp c
    LEFT JOIN essentials.politicians p ON p.id = c.politician_id;

  IF v_repaired > 0 THEN
    RAISE NOTICE 'incumbency guard: % race row(s) that drifted BEFORE this migration now agree with office_terms', v_repaired;
  END IF;

  IF v_created > 0 THEN
    RAISE EXCEPTION E'incumbency guard: % race row(s) agreed with essentials.office_terms before this migration and contradict it now.\n%\n\nThis is what `check:incumbency` will say on the NEXT push to master, under somebody else''s name. Settle it here.\n  • Newcomer — the date is right and the race row is wrong. Set race_candidates.is_incumbent = false IN THIS MIGRATION.\n  • Re-elected — the race row is right and the DATE is wrong: you have written their latest term''s start as the start of their whole tenure. Leave term_start NULL, or write the real first term.\nThe two look identical from the predicate. Read the person. See CC_0396''s header for the worked split of seven such rows.',
      v_created, coalesce(v_detail, '    (no detail)');
  END IF;
END $$;
-- ▲▲ END OF BLOCK B ▲▲

-- ─── 5. Post-verify ───
DO $$
DECLARE n int; bad text;
BEGIN
  SELECT string_agg(coalesce(o.title, v.id::text) || ' -> ' || coalesce(p.full_name, 'NULL'), '; ') INTO bad
    FROM (VALUES
      ('b1f88e15-f727-4710-a82e-406ca829c071'::uuid, 'Mayor',         'Linda Evans',          '865db17c-934c-4b39-b7c2-df400e33a6c1'::uuid, 'LOCAL_EXEC'),
      ('de3ff0f8-e731-4683-a7a9-5dc967c355cf'::uuid, 'Councilmember', 'Kathleen Fitzpatrick', 'a2e79dcc-af96-40e6-871e-f90bd542b51e'::uuid, 'LOCAL'),
      ('a9b446e5-c388-42dd-bcb6-4e709c82e273'::uuid, 'Councilmember', 'Deborah McGarrey',     'a2e79dcc-af96-40e6-871e-f90bd542b51e'::uuid, 'LOCAL'),
      ('bc270f01-1084-41c5-abba-f4474d273898'::uuid, 'Councilmember', 'John Peña',            'a2e79dcc-af96-40e6-871e-f90bd542b51e'::uuid, 'LOCAL'),
      ('39d074d1-559b-464b-80f7-52af9400bb2e'::uuid, 'Councilmember', 'Steve Sanchez',        'a2e79dcc-af96-40e6-871e-f90bd542b51e'::uuid, 'LOCAL')
    ) AS v(id, title, holder, chamber, dtype)
    LEFT JOIN essentials.offices o ON o.id = v.id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.id IS NULL OR o.title <> v.title OR p.full_name IS DISTINCT FROM v.holder OR o.chamber_id <> v.chamber
      OR d.district_type <> v.dtype OR d.geo_id <> '0640354' OR d.mtfcc <> 'G4110';
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0529: office/holder mismatch: %', bad; END IF;

  -- La Quinta City Hall (78495 Calle Tampico; Census Geocoder -116.294998, 33.678110) reaches all five offices
  SELECT count(DISTINCT o.id) INTO n
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE gb.mtfcc = 'G4110' AND gb.geo_id = '0640354' AND c.government_id = 'ddf5f2f5-8fce-4cdc-9f0a-87a287cc1c17'
     AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(-116.294998, 33.678110), 4326));
  IF n <> 5 THEN RAISE EXCEPTION 'CC_0529: City Hall point reaches % La Quinta offices, expected 5', n; END IF;

  RAISE NOTICE 'CC_0529 OK: City of La Quinta, Mayor + 4 councilmembers seated';
END $$;

COMMIT;
