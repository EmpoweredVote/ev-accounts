-- CC_0527_coachella_city_government.sql
-- CC_0527: City of Coachella, CA (place 0614260, Riverside County) -- the whole city government, which did not exist.
--
-- WHAT WAS THERE (read 2026-11-28). Only the TIGER G4110 outline 'Coachella city' (geo_id '0614260'). No government,
-- chamber, district, office or person: a Coachella address showed no city official at all.
-- (Schools: most of Coachella is Coachella Valley Unified, seated by CC_0525.)
--
-- THE GOVERNMENT. coachella.org/city-government/city-council (read 2026-11-28; Akamai blocks curl, read with
-- headless Chrome):
--   "Dr. Frank Figueroa / Mayor / Term End Date: December 2026"
--   "Yadira Perez / Mayor Pro Tem / Term End Date: December 2028"
--   "Stephanie Virgen / City Councilmember / Term End Date: December 2026"
--   "Denise Delgado / City Councilmember / Term End Date: December 2028"
--   "Juan M. Martinez / City Councilmember / Term End Date: December 2026"
-- coachella.org/departments/city-clerk: "Angela M. Zepeda / Elected City Clerk / Term End Date: November 2028".
-- coachella.org/departments/city-treasurer: "Mayra Perez / City Treasurer".
-- ELECTED, ALL OF THEM, AND HOW: the city's "Final List of Qualified Candidates for City Mayor, City Council, City
-- Clerk, and City Treasurer ... November 5, 2024" (coachella.org showpublisheddocument 9871, certified 2024-08-29)
-- lists all four offices on the ballot, including "Angela Zepeda, City Clerk" and "Mayra Perez, Business Owner" for
-- City Treasurer. coachella.org/city-government/city-council/how-to-run-for-office: "The Council Members serve a
-- four-year term and the Mayor serves a two-year term." The Mayor is directly elected; the council is elected AT
-- LARGE -- the ROV contest is "Coachella City Council, VOTE FOR 2", citywide, with no districts.
-- SHAPE copied from Hawthorne (an elected-mayor, at-large CA city already in the corpus): four councilmember offices on
-- a LOCAL G4110 district; Mayor, City Clerk and City Treasurer each in their own chamber on a LOCAL_EXEC G4110
-- district. Mayor voting_powers 'full': a directly elected mayor in a California general-law city is a member of the
-- council (Gov. Code 34900 ff.), as Hawthorne's row says. "Mayor Pro Tem" is a role the council assigns from its own
-- members (Yadira Perez now) -- not an office (Duvall ruling 5), so all four council seats are titled
-- 'Councilmember' and the role sits in Perez's office description.
--
-- HOW THE CURRENT HOLDERS ARRIVED (context; no start dates are written). 2024: Steven A. Hernandez re-elected
-- Mayor over then-Councilmember Figueroa; Delgado and Yadira Perez elected to council. Riverside ROV final candidate
-- list for Nov 3 2026 (printed 2026-09-11) marks Figueroa (Mayor) and Juan M. Martinez (Council) "Appointed to
-- Vacancy" -- Hernandez left, Figueroa was appointed Mayor, and Martinez was appointed to Figueroa's council seat.
-- The appointment dates were not found, so every term is open-ended with start_precision 'unknown'.
--
-- 2026 ELECTION. Riverside ROV, update #27 (2026-11-25):
--   Mayor (vote for 1): Frank Figueroa 2,612 (32.14%), Jesus "Kino" Gonzalez 2,447, Denise Delgado 2,433,
--     Francisco "Frankie" Molina 636. Figueroa re-elected -> same holder, nothing written. Delgado ran for Mayor and
--     lost; she keeps her council seat (term to December 2028).
--   Council (vote for 2): Yavonne Zapata 3,429 (29.37%), Vicente Zamora 3,265 (27.97%), Juan M. Martinez 2,667,
--     Ambar De La Herran 1,825, Andrew Gallegos 489. Incumbents on that contest: Stephanie Virgen (did not file --
--     the ROV marks the office "goes into extension") and Juan M. Martinez (lost).
--   So Zapata and Zamora replace Virgen and Martinez. The two seats are unnumbered at-large seats; Zapata is placed on
--   Virgen's office and Zamora on Martinez's, an arbitrary but fixed pairing.
--   THE DATE IS AN ESTIMATE. coachella.org how-to-run-for-office: after the ROV certifies, the City Clerk prepares the
--   resolution "for the City Council to officially adopt the certified results. This will occur at the first
--   available meeting in December", and the newly elected officer may be sworn in "at a time convenient to the
--   official". The council meets the 2nd and 4th Wednesdays: the first December meeting is 2026-12-09. Its agenda was
--   not posted on 2026-11-28 (meetings.municode.com, COACHELACA). start_precision 'month' -- the Fremont (CC_0521)
--   treatment. ▶ FOLLOW-UP: confirm from the 2026-12-09 agenda/minutes; move both dates together if they differ.
--   🔴 OVERWRITTEN VALUE: none before this file -- Virgen's and Martinez's terms are created here, open-ended, and
--   closed at 2026-12-08 by seat_officeholder in the same transaction.
--
-- PEOPLE. No active politician row carried any of the nine names on 2026-11-28. external_id -4012101..-4012109 (an
-- unused block). Party is never stored.
--
-- Apply with: node scripts/apply-migration-file.mjs migrations/CC_0527_coachella_city_government.sql
BEGIN;

-- ─── 0. Preconditions ───
DO $$
DECLARE n int;
BEGIN
  PERFORM 1 FROM essentials.geofence_boundaries WHERE mtfcc = 'G4110' AND geo_id = '0614260';
  IF NOT FOUND THEN RAISE EXCEPTION 'CC_0527 precondition: no G4110 outline for Coachella (0614260)'; END IF;
  SELECT count(*) INTO n FROM essentials.governments
   WHERE (geo_id = '0614260' OR name ILIKE 'City of Coachella%') AND id <> '71a9f926-2e19-41ac-86a7-60e834c83a60';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0527 precondition: another City of Coachella government exists (%)', n; END IF;
  SELECT count(*) INTO n FROM essentials.districts
   WHERE geo_id = '0614260' AND id NOT IN ('921ff2b0-9c50-433e-89d2-2f4527363940', '89229973-cb16-4905-b7a5-ecf5c0802e33');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0527 precondition: a district on geo_id 0614260 already exists (%)', n; END IF;
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE external_id BETWEEN -4012109 AND -4012101
     AND id NOT IN (SELECT unnest(ARRAY['73d6844b-850d-43c7-ae74-2eb274fb83ad','4adead28-7a33-4c8c-80b6-c1d3211e6082','171263cc-12f0-4151-be88-7ce4da1d9048',
       'e7f3f51b-a89e-44a1-ac7a-fce2992c4aef','b3fef4b0-9849-479b-9964-21e46fe44eed','e5756dba-35d9-4f11-b625-9eb24b149fb5',
       'b8030f58-9d58-434f-8efd-897302c6f244','1f414806-e070-485f-946c-9465c90b461b','39115154-35c3-44f4-a509-bf8df322fe8a']::uuid[]));
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0527 precondition: an external_id in -4012109..-4012101 belongs to someone else'; END IF;
END $$;

-- ─── 1. Government, districts, chambers ───
INSERT INTO essentials.governments (id, name, type, state, city, geo_id, mtfcc)
SELECT '71a9f926-2e19-41ac-86a7-60e834c83a60'::uuid, 'City of Coachella, California, US', 'City', 'CA', 'Coachella', '0614260', 'G4110'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE id = '71a9f926-2e19-41ac-86a7-60e834c83a60'::uuid);

INSERT INTO essentials.districts (id, label, district_type, district_id, state, num_officials, mtfcc, geo_id,
                                  is_judicial, has_unknown_boundaries, retention, representation_basis, ocd_id, official_web_url)
SELECT v.id, v.label, v.dtype, '0', 'CA', v.n, 'G4110', '0614260', false, false, false, 'residency',
       'ocd-division/country:us/state:ca/place:coachella', v.url
  FROM (VALUES
    ('921ff2b0-9c50-433e-89d2-2f4527363940'::uuid, 'Coachella City Council (At-Large)', 'LOCAL', 4, 'https://www.coachella.org/city-government/city-council'),
    ('89229973-cb16-4905-b7a5-ecf5c0802e33'::uuid, 'Coachella City Officers', 'LOCAL_EXEC', 3, 'https://www.coachella.org/city-government')
  ) AS v(id, label, dtype, n, url)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.id = v.id);

INSERT INTO essentials.chambers (id, government_id, name, name_formal, official_count, website_url, policy_engagement_level)
SELECT v.id, '71a9f926-2e19-41ac-86a7-60e834c83a60'::uuid, v.name, v.nf, v.n, v.url, 'full' FROM (VALUES
    ('f6ea2d6a-4b14-4a51-92ca-758922b40a6c'::uuid, 'City Council', 'Coachella City Council', 4, 'https://www.coachella.org/city-government/city-council'),
    ('55122b71-68ec-44d7-b1cb-9942343b2303'::uuid, 'Mayor', 'Mayor of Coachella', 1, 'https://www.coachella.org/city-government/city-council'),
    ('a23dc234-81b2-4113-bcfe-0c3b2159307f'::uuid, 'City Clerk', 'Coachella City Clerk', 1, 'https://www.coachella.org/departments/city-clerk'),
    ('cd733ce9-e04a-4bb9-beca-bf5c5fc8efdd'::uuid, 'City Treasurer', 'Coachella City Treasurer', 1, 'https://www.coachella.org/departments/city-treasurer')
  ) AS v(id, name, nf, n, url) WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.id = v.id);

-- ─── 2. Offices ───
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, representing_city, seats, normalized_position_name,
                                is_appointed_position, is_vacant, faces_retention_vote, voting_powers, description)
SELECT v.oid, v.cid, v.did, v.title, 'CA', 'Coachella', 1, v.title, false, false, false, 'full', v.descr
  FROM (VALUES
    ('93525728-0d48-4cd2-9509-111e06be022c'::uuid, '55122b71-68ec-44d7-b1cb-9942343b2303'::uuid, '89229973-cb16-4905-b7a5-ecf5c0802e33'::uuid, 'Mayor',
     'Directly elected citywide to a two-year term; presides over and votes as a member of the City Council.'),
    ('2562ce54-2ee2-4d84-9c14-461546122a70'::uuid, 'f6ea2d6a-4b14-4a51-92ca-758922b40a6c'::uuid, '921ff2b0-9c50-433e-89d2-2f4527363940'::uuid, 'Councilmember',
     'Elected at large to a four-year term. Serving as Mayor Pro Tem (a role the council assigns; coachella.org, 2026-11-28).'),
    ('7206b34c-1ab2-448c-81fd-a2a1a8eb5302'::uuid, 'f6ea2d6a-4b14-4a51-92ca-758922b40a6c'::uuid, '921ff2b0-9c50-433e-89d2-2f4527363940'::uuid, 'Councilmember',
     'Elected at large to a four-year term.'),
    ('297908ed-ca0f-458e-b806-77bde94e07b6'::uuid, 'f6ea2d6a-4b14-4a51-92ca-758922b40a6c'::uuid, '921ff2b0-9c50-433e-89d2-2f4527363940'::uuid, 'Councilmember',
     'Elected at large to a four-year term.'),
    ('9499b848-7fd2-4c68-936a-2fc88b1731b0'::uuid, 'f6ea2d6a-4b14-4a51-92ca-758922b40a6c'::uuid, '921ff2b0-9c50-433e-89d2-2f4527363940'::uuid, 'Councilmember',
     'Elected at large to a four-year term.'),
    ('5ba593fd-3e27-499e-a089-4f63e970f8d1'::uuid, 'a23dc234-81b2-4113-bcfe-0c3b2159307f'::uuid, '89229973-cb16-4905-b7a5-ecf5c0802e33'::uuid, 'City Clerk',
     'Elected citywide to a four-year term.'),
    ('1837bc7f-d323-48f7-9203-2a32f8814672'::uuid, 'cd733ce9-e04a-4bb9-beca-bf5c5fc8efdd'::uuid, '89229973-cb16-4905-b7a5-ecf5c0802e33'::uuid, 'City Treasurer',
     'Elected citywide to a four-year term.')
  ) AS v(oid, cid, did, title, descr)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = v.oid);

-- ─── 3. People ───
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, preferred_name, alternate_names, is_active, source)
SELECT v.id, v.ext, v.n, v.f, v.l, v.pref, v.alt, true, v.src
  FROM (VALUES
    ('73d6844b-850d-43c7-ae74-2eb274fb83ad'::uuid, -4012101, 'Frank Figueroa', 'Frank', 'Figueroa', 'Dr. Frank Figueroa', ARRAY['Frank Cervera Figueroa','Dr. Frank Figueroa']::text[], 'coachella.org city council page (read 2026-11-28); Riverside ROV Nov 3 2026 (CC_0527)'),
    ('4adead28-7a33-4c8c-80b6-c1d3211e6082'::uuid, -4012102, 'Yadira Perez', 'Yadira', 'Perez', NULL, ARRAY[]::text[], 'coachella.org city council page (read 2026-11-28) (CC_0527)'),
    ('171263cc-12f0-4151-be88-7ce4da1d9048'::uuid, -4012103, 'Denise Delgado', 'Denise', 'Delgado', NULL, ARRAY[]::text[], 'coachella.org city council page (read 2026-11-28) (CC_0527)'),
    ('e7f3f51b-a89e-44a1-ac7a-fce2992c4aef'::uuid, -4012104, 'Stephanie Virgen', 'Stephanie', 'Virgen', NULL, ARRAY[]::text[], 'coachella.org city council page (read 2026-11-28) (CC_0527)'),
    ('b3fef4b0-9849-479b-9964-21e46fe44eed'::uuid, -4012105, 'Juan M. Martinez', 'Juan', 'Martinez', NULL, ARRAY['Juan Martinez']::text[], 'coachella.org city council page (read 2026-11-28) (CC_0527)'),
    ('e5756dba-35d9-4f11-b625-9eb24b149fb5'::uuid, -4012106, 'Angela M. Zepeda', 'Angela', 'Zepeda', NULL, ARRAY['Angela Zepeda']::text[], 'coachella.org/departments/city-clerk (read 2026-11-28) (CC_0527)'),
    ('b8030f58-9d58-434f-8efd-897302c6f244'::uuid, -4012107, 'Mayra Perez', 'Mayra', 'Perez', NULL, ARRAY[]::text[], 'coachella.org/departments/city-treasurer (read 2026-11-28) (CC_0527)'),
    ('1f414806-e070-485f-946c-9465c90b461b'::uuid, -4012108, 'Yavonne Zapata', 'Yavonne', 'Zapata', NULL, ARRAY[]::text[], 'Riverside ROV Nov 3 2026 results, Coachella City Council (update #27, 2026-11-25) (CC_0527)'),
    ('39115154-35c3-44f4-a509-bf8df322fe8a'::uuid, -4012109, 'Vicente Zamora', 'Vicente', 'Zamora', NULL, ARRAY[]::text[], 'Riverside ROV Nov 3 2026 results, Coachella City Council (update #27, 2026-11-25) (CC_0527)')
  ) AS v(id, ext, n, f, l, pref, alt, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id);

CREATE TEMP TABLE cc0527_plan ON COMMIT DROP AS
SELECT unnest(ARRAY['73d6844b-850d-43c7-ae74-2eb274fb83ad','4adead28-7a33-4c8c-80b6-c1d3211e6082','171263cc-12f0-4151-be88-7ce4da1d9048',
                    'e7f3f51b-a89e-44a1-ac7a-fce2992c4aef','b3fef4b0-9849-479b-9964-21e46fe44eed','e5756dba-35d9-4f11-b625-9eb24b149fb5',
                    'b8030f58-9d58-434f-8efd-897302c6f244','1f414806-e070-485f-946c-9465c90b461b','39115154-35c3-44f4-a509-bf8df322fe8a']::uuid[]) AS politician_id;

-- ▼▼ BLOCK A (backend/migrations/_templates/office_terms_incumbency_guard.sql) ▼▼
-- @incumbency-decision: gated — opens seven undated Coachella terms, then seats Yavonne Zapata and Vicente Zamora from 2026-12-09 (closing Virgen and Martinez at 2026-12-08); none has a race row
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
   AND rc.politician_id IN (SELECT politician_id FROM cc0527_plan);
-- ▲▲ END OF BLOCK A ▲▲

-- ─── 4. Terms ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT v.oid, v.pid, NULL, 'unknown', v.how, v.src || ' Start of tenure not dated. (CC_0527)'
  FROM (VALUES
    ('93525728-0d48-4cd2-9509-111e06be022c'::uuid, '73d6844b-850d-43c7-ae74-2eb274fb83ad'::uuid, 'appointed', 'coachella.org (read 2026-11-28): Mayor, term end December 2026; ROV Nov 2026 candidate list marks him "Appointed to Vacancy"; re-elected 2026-11-03.'),
    ('2562ce54-2ee2-4d84-9c14-461546122a70'::uuid, '4adead28-7a33-4c8c-80b6-c1d3211e6082'::uuid, 'elected',   'coachella.org (read 2026-11-28): Councilmember (Mayor Pro Tem), term end December 2028.'),
    ('7206b34c-1ab2-448c-81fd-a2a1a8eb5302'::uuid, '171263cc-12f0-4151-be88-7ce4da1d9048'::uuid, 'elected',   'coachella.org (read 2026-11-28): Councilmember, term end December 2028.'),
    ('297908ed-ca0f-458e-b806-77bde94e07b6'::uuid, 'e7f3f51b-a89e-44a1-ac7a-fce2992c4aef'::uuid, 'elected',   'coachella.org (read 2026-11-28): Councilmember, term end December 2026.'),
    ('9499b848-7fd2-4c68-936a-2fc88b1731b0'::uuid, 'b3fef4b0-9849-479b-9964-21e46fe44eed'::uuid, 'appointed', 'coachella.org (read 2026-11-28): Councilmember, term end December 2026; ROV Nov 2026 candidate list marks him "Appointed to Vacancy".'),
    ('5ba593fd-3e27-499e-a089-4f63e970f8d1'::uuid, 'e5756dba-35d9-4f11-b625-9eb24b149fb5'::uuid, 'elected',   'coachella.org/departments/city-clerk (read 2026-11-28): Elected City Clerk, term end November 2028.'),
    ('1837bc7f-d323-48f7-9203-2a32f8814672'::uuid, 'b8030f58-9d58-434f-8efd-897302c6f244'::uuid, 'elected',   'coachella.org/departments/city-treasurer (read 2026-11-28); qualified candidate for City Treasurer, Nov 5 2024 (coachella.org document 9871).')
  ) AS v(oid, pid, how, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v.oid);

SELECT essentials.seat_officeholder(v.oid, v.pid, DATE '2026-12-09',
  'Elected 2026-11-03, Coachella City Council (vote for 2): Zapata 3,429, Zamora 3,265, Martinez 2,667, De La Herran 1,825, Gallegos 489, '
  || 'Riverside County ROV (update #27, 2026-11-25). START DATE ESTIMATED: the city adopts certified results "at the first available meeting '
  || 'in December" (coachella.org) -- 2026-12-09, the second Wednesday. Replace when that agenda is posted. (CC_0527)',
  'elected', 'month', 'term_expired', false)
  FROM (VALUES ('297908ed-ca0f-458e-b806-77bde94e07b6'::uuid, '1f414806-e070-485f-946c-9465c90b461b'::uuid),
               ('9499b848-7fd2-4c68-936a-2fc88b1731b0'::uuid, '39115154-35c3-44f4-a509-bf8df322fe8a'::uuid)) AS v(oid, pid);

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
  SELECT count(*) INTO v_planned FROM cc0527_plan;
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
  -- each office holds today the person the city lists, in the right chamber and district (fields, not counts)
  SELECT string_agg(coalesce(o.title, v.id::text) || ' -> ' || coalesce(p.full_name, 'NULL'), '; ') INTO bad
    FROM (VALUES
      ('93525728-0d48-4cd2-9509-111e06be022c'::uuid, 'Mayor',          'Frank Figueroa',   '55122b71-68ec-44d7-b1cb-9942343b2303'::uuid, 'LOCAL_EXEC'),
      ('2562ce54-2ee2-4d84-9c14-461546122a70'::uuid, 'Councilmember',  'Yadira Perez',     'f6ea2d6a-4b14-4a51-92ca-758922b40a6c'::uuid, 'LOCAL'),
      ('7206b34c-1ab2-448c-81fd-a2a1a8eb5302'::uuid, 'Councilmember',  'Denise Delgado',   'f6ea2d6a-4b14-4a51-92ca-758922b40a6c'::uuid, 'LOCAL'),
      ('297908ed-ca0f-458e-b806-77bde94e07b6'::uuid, 'Councilmember',  CASE WHEN CURRENT_DATE < DATE '2026-12-09' THEN 'Stephanie Virgen' ELSE 'Yavonne Zapata' END, 'f6ea2d6a-4b14-4a51-92ca-758922b40a6c'::uuid, 'LOCAL'),
      ('9499b848-7fd2-4c68-936a-2fc88b1731b0'::uuid, 'Councilmember',  CASE WHEN CURRENT_DATE < DATE '2026-12-09' THEN 'Juan M. Martinez' ELSE 'Vicente Zamora' END, 'f6ea2d6a-4b14-4a51-92ca-758922b40a6c'::uuid, 'LOCAL'),
      ('5ba593fd-3e27-499e-a089-4f63e970f8d1'::uuid, 'City Clerk',     'Angela M. Zepeda', 'a23dc234-81b2-4113-bcfe-0c3b2159307f'::uuid, 'LOCAL_EXEC'),
      ('1837bc7f-d323-48f7-9203-2a32f8814672'::uuid, 'City Treasurer', 'Mayra Perez',      'cd733ce9-e04a-4bb9-beca-bf5c5fc8efdd'::uuid, 'LOCAL_EXEC')
    ) AS v(id, title, holder, chamber, dtype)
    LEFT JOIN essentials.offices o ON o.id = v.id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.id IS NULL OR o.title <> v.title OR p.full_name IS DISTINCT FROM v.holder OR o.chamber_id <> v.chamber
      OR d.district_type <> v.dtype OR d.geo_id <> '0614260' OR d.mtfcc <> 'G4110';
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0527: office/holder mismatch: %', bad; END IF;

  -- the queued successors sit on the two departing members' seats -- not on Perez's or Delgado's
  IF CURRENT_DATE < DATE '2026-12-09' THEN
    SELECT string_agg(v.oid::text || ' -> ' || coalesce(p.full_name, 'NONE') || ' ' || coalesce(ont.term_start::text, ''), '; ') INTO bad
      FROM (VALUES ('297908ed-ca0f-458e-b806-77bde94e07b6'::uuid, 'Yavonne Zapata'), ('9499b848-7fd2-4c68-936a-2fc88b1731b0'::uuid, 'Vicente Zamora'),
                   ('2562ce54-2ee2-4d84-9c14-461546122a70'::uuid, NULL), ('7206b34c-1ab2-448c-81fd-a2a1a8eb5302'::uuid, NULL)) AS v(oid, want)
      LEFT JOIN essentials.office_next_term ont ON ont.office_id = v.oid
      LEFT JOIN essentials.politicians p ON p.id = ont.politician_id
     WHERE p.full_name IS DISTINCT FROM v.want OR (v.want IS NOT NULL AND ont.term_start <> DATE '2026-12-09');
    IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0527: incoming holders wrong: %', bad; END IF;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE politician_id IN ('e7f3f51b-a89e-44a1-ac7a-fce2992c4aef','b3fef4b0-9849-479b-9964-21e46fe44eed') AND term_end = DATE '2026-12-08';
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0527: expected Virgen and Martinez closed at 2026-12-08, found %', n; END IF;

  -- City Hall (1515 Sixth Street; Census Geocoder -116.17638, 33.67896) reaches all seven offices through the G4110 districts
  SELECT count(DISTINCT o.id) INTO n
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE gb.mtfcc = 'G4110' AND gb.geo_id = '0614260' AND c.government_id = '71a9f926-2e19-41ac-86a7-60e834c83a60'
     AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(-116.17638, 33.67896), 4326));
  IF n <> 7 THEN RAISE EXCEPTION 'CC_0527: City Hall point reaches % Coachella offices, expected 7', n; END IF;

  RAISE NOTICE 'CC_0527 OK: City of Coachella, 7 offices seated; Zapata and Zamora incoming 2026-12-09';
END $$;

COMMIT;
