-- CC_0533_palm_desert_district_transition.sql
-- CC_0533: Palm Desert, CA -- finish the switch to five single-member districts: create District 4 and 5, seat Evan
-- Trubee (D4) and John Greenwood (D5), and retire the two at-large seats CC_0531 created.
--
-- 🔴 NOT APPLIED WHEN WRITTEN (2026-11-28). APPLY ON OR AFTER THE INSTALLATION MEETING -- the file refuses to run before
-- the date in cc0533_install (step 0). Written ahead so the next session only has to confirm the date and run it.
--
-- THE DATE. palmdesert.gov: the council meets on Thursdays; eScribe (pub-palmdesert.escribemeetings.com) lists every
-- 2026 regular meeting on the 2nd and 4th Thursday, and last year's organizational meeting (Mayor selection) was
-- 2025-12-11, the 2nd Thursday of December. So the installation is expected on 2026-12-10. On 2026-11-28 no December
-- council agenda was posted. ▶ BEFORE APPLYING: read the 2026-12-10 agenda/minutes. If the oath was another day, change
-- the ONE date in cc0533_install below, and change start_precision from 'month' to 'day' once the day is confirmed.
--
-- THE RESULT. Riverside ROV, update #27 (2026-11-25): District 4 Evan Trubee 2,240 (57.29%) v Jonathon Polly 1,670;
-- District 5 John Greenwood 2,799 (59.76%) v Ralph E. Perry 1,885. Harnik was not a candidate.
--
-- WHAT CHANGES (one transaction, so no district is ever empty -- see CC_0531's header for why that matters):
--   1. Districts 4 and 5 (X0001 'palm-desert-council-district-4/5'; the polygons were loaded by CC_0531).
--   2. Offices for D4 and D5; person row for John Greenwood (external_id -4012306, reserved by CC_0531).
--   3. Terms: Trubee on D4 and Greenwood on D5 from the install date.
--   4. The at-large terms close the day before: Trubee 'redistricted' (he continues, in D4), Harnik 'term_expired'.
--   5. The two at-large offices are DETACHED (district_id -> NULL) and the at-large district row deleted. They keep their
--      office_terms history (deleting the offices would cascade it away). A detached office with no current holder is
--      invisible to address search and is not a reachability finding.
-- 🔴 OVERWRITTEN VALUES:
--   office_terms for office 446c72cc-5ccd-495f-aec1-b1752b151fc1 (Trubee, at-large) and bd0e85af-891c-4aca-9ae2-e8132baf79e3
--     (Harnik, at-large): term_end NULL, how_ended NULL (as written by CC_0531).
--   offices.district_id for those two offices: 784372e6-3c96-4db3-a83c-7b507b649132 (the at-large district, which this
--     file deletes: geo_id '0655184', mtfcc 'G4110', label 'Palm Desert City Council (At-Large, until the 2026 district
--     transition)', num_officials 2).
--   The two at-large offices' descriptions (CC_0531 text) are rewritten to say the seat ended.
--
-- Apply with: node scripts/apply-migration-file.mjs migrations/CC_0533_palm_desert_district_transition.sql
BEGIN;

CREATE TEMP TABLE cc0533_install ON COMMIT DROP AS SELECT DATE '2026-12-10' AS d;

-- ─── 0. Preconditions ───
DO $$
DECLARE n int; v_d date;
BEGIN
  SELECT d INTO v_d FROM cc0533_install;
  IF CURRENT_DATE < v_d THEN
    RAISE EXCEPTION 'CC_0533: not before %. This file seats the District 4 and 5 winners and retires the at-large seats; run it on or after the installation meeting (see header).', v_d;
  END IF;
  -- CC_0531 is in place, unchanged: two at-large seats held by Trubee and Harnik, open-ended
  SELECT count(*) INTO n FROM essentials.office_terms t JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE (t.office_id, p.full_name) IN (('446c72cc-5ccd-495f-aec1-b1752b151fc1'::uuid, 'Evan Trubee'), ('bd0e85af-891c-4aca-9ae2-e8132baf79e3'::uuid, 'Jan Harnik'))
     AND (t.term_end IS NULL OR t.term_end = v_d - 1);
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0533 precondition: the at-large terms are not in the state CC_0531 left (found %)', n; END IF;
  SELECT count(*) INTO n FROM essentials.geofence_boundaries WHERE mtfcc = 'X0001' AND geo_id IN ('palm-desert-council-district-4','palm-desert-council-district-5');
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0533 precondition: D4/D5 polygons missing (found %)', n; END IF;
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE (external_id = -4012306 AND id <> 'c70d6462-0dbc-467f-b56b-9b341a845c70')
      OR (is_active AND first_name ILIKE 'john%' AND last_name ILIKE 'greenwood' AND id <> 'c70d6462-0dbc-467f-b56b-9b341a845c70');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0533 precondition: another John Greenwood row or a clash on external_id -4012306 (%); check before inserting', n; END IF;
END $$;

-- ─── 1. Districts 4 and 5 ───
INSERT INTO essentials.districts (id, geo_id, district_id, label, district_type, state, mtfcc, num_officials, representation_basis,
                                  is_judicial, has_unknown_boundaries, retention, ocd_id, official_web_url)
SELECT v.id, 'palm-desert-council-district-' || v.n, v.n, 'Palm Desert City Council District ' || v.n, 'LOCAL', 'CA', 'X0001', 1, 'residency',
       false, false, false, 'ocd-division/country:us/state:ca/place:palm_desert/council_district:' || v.n,
       'https://www.palmdesert.gov/government/city-council'
  FROM (VALUES ('6dd17bb3-bb5f-4341-8b87-d8ceff322f84'::uuid, '4'), ('0259dc10-2ade-4387-8884-f6e1748397c9'::uuid, '5')) AS v(id, n)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.id = v.id);

-- ─── 2. Offices and the new member ───
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, representing_city, seats, normalized_position_name,
                                is_appointed_position, is_vacant, faces_retention_vote, voting_powers, description)
SELECT v.oid, 'a67fdb55-661f-481c-8636-912266a8e6e3'::uuid, v.did, 'Councilmember', 'CA', 'Palm Desert', 1, 'Councilmember',
       false, false, false, 'full', 'Elected by District ' || v.n || ' to a four-year term.'
  FROM (VALUES ('4751be2d-9c2d-4461-8b18-03714c21f8cc'::uuid, '6dd17bb3-bb5f-4341-8b87-d8ceff322f84'::uuid, '4'),
               ('99642daa-1a33-4099-a641-aa94abcc0138'::uuid, '0259dc10-2ade-4387-8884-f6e1748397c9'::uuid, '5')) AS v(oid, did, n)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = v.oid);

INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, alternate_names, is_active, source)
SELECT 'c70d6462-0dbc-467f-b56b-9b341a845c70'::uuid, -4012306, 'John Greenwood', 'John', 'Greenwood', ARRAY[]::text[], true,
       'Riverside ROV Nov 3 2026 results, Palm Desert City Council District 5 (update #27, 2026-11-25) (CC_0533)'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = 'c70d6462-0dbc-467f-b56b-9b341a845c70'::uuid);

CREATE TEMP TABLE cc0533_plan ON COMMIT DROP AS
SELECT unnest(ARRAY['27b019ff-125a-473c-9a64-40233ce81968','0edc51b8-8c6b-4897-9b5c-a90587aad946','c70d6462-0dbc-467f-b56b-9b341a845c70']::uuid[]) AS politician_id;

-- ▼▼ BLOCK A (backend/migrations/_templates/office_terms_incumbency_guard.sql) ▼▼
-- @incumbency-decision: gated — closes the two Palm Desert at-large terms the day before installation and opens Trubee (D4) and Greenwood (D5) from it
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
   AND rc.politician_id IN (SELECT politician_id FROM cc0533_plan);
-- ▲▲ END OF BLOCK A ▲▲

-- ─── 3. Terms ───
UPDATE essentials.office_terms t
   SET term_end = (SELECT d FROM cc0533_install) - 1,
       how_ended = CASE WHEN t.office_id = '446c72cc-5ccd-495f-aec1-b1752b151fc1'::uuid THEN 'redistricted' ELSE 'term_expired' END
 WHERE t.office_id IN ('446c72cc-5ccd-495f-aec1-b1752b151fc1', 'bd0e85af-891c-4aca-9ae2-e8132baf79e3')
   AND t.term_end IS NULL;

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT v.oid, v.pid, (SELECT d FROM cc0533_install), 'month', 'elected',
       'Elected 2026-11-03, ' || v.contest || ', Riverside County ROV (update #27, 2026-11-25). Term starts at the installation meeting '
       || '(expected the first December regular meeting; see CC_0533 header). (CC_0533)'
  FROM (VALUES
    ('4751be2d-9c2d-4461-8b18-03714c21f8cc'::uuid, '27b019ff-125a-473c-9a64-40233ce81968'::uuid, 'Palm Desert City Council District 4: Trubee 2,240 v Polly 1,670'),
    ('99642daa-1a33-4099-a641-aa94abcc0138'::uuid, 'c70d6462-0dbc-467f-b56b-9b341a845c70'::uuid, 'Palm Desert City Council District 5: Greenwood 2,799 v Perry 1,885')
  ) AS v(oid, pid, contest)
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
  SELECT count(*) INTO v_planned FROM cc0533_plan;
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

-- ─── 4. Retire the at-large seats (history kept) ───
UPDATE essentials.offices
   SET district_id = NULL,
       description = 'At-large seat that ended when Palm Desert completed its switch to five single-member districts (2026). Kept for its term history; no successor seat (CC_0533).'
 WHERE id IN ('446c72cc-5ccd-495f-aec1-b1752b151fc1', 'bd0e85af-891c-4aca-9ae2-e8132baf79e3')
   AND district_id = '784372e6-3c96-4db3-a83c-7b507b649132'::uuid;
DELETE FROM essentials.districts d
 WHERE d.id = '784372e6-3c96-4db3-a83c-7b507b649132'::uuid
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- ─── 5. Post-verify ───
DO $$
DECLARE n int; bad text;
BEGIN
  -- five districts, each with exactly the current holder the 2024/2026 elections put there (fields, not counts)
  SELECT string_agg(v.geo || ' -> ' || coalesce(p.full_name, 'NONE'), '; ') INTO bad
    FROM (VALUES ('palm-desert-council-district-1', 'Karina Moreno'), ('palm-desert-council-district-2', 'Joe Pradetto'),
                 ('palm-desert-council-district-3', 'Gina Nestande'), ('palm-desert-council-district-4', 'Evan Trubee'),
                 ('palm-desert-council-district-5', 'John Greenwood')) AS v(geo, holder)
    LEFT JOIN essentials.districts d ON d.geo_id = v.geo AND d.mtfcc = 'X0001'
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.full_name IS DISTINCT FROM v.holder;
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0533: district holders wrong: %', bad; END IF;

  -- the at-large seats are closed the day before installation, detached, and their district is gone
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE office_id IN ('446c72cc-5ccd-495f-aec1-b1752b151fc1','bd0e85af-891c-4aca-9ae2-e8132baf79e3')
     AND term_end = (SELECT d FROM cc0533_install) - 1;
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0533: expected both at-large terms closed at install-1, found %', n; END IF;
  SELECT count(*) INTO n FROM essentials.offices
   WHERE id IN ('446c72cc-5ccd-495f-aec1-b1752b151fc1','bd0e85af-891c-4aca-9ae2-e8132baf79e3') AND district_id IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0533: % at-large office(s) still attached to a district', n; END IF;
  PERFORM 1 FROM essentials.districts WHERE id = '784372e6-3c96-4db3-a83c-7b507b649132'::uuid;
  IF FOUND THEN RAISE EXCEPTION 'CC_0533: the at-large district row still exists'; END IF;

  -- City Hall now resolves to exactly one councilmember: District 1, Karina Moreno
  SELECT string_agg(p.full_name, ',') INTO bad
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id AND o.chamber_id = 'a67fdb55-661f-481c-8636-912266a8e6e3'::uuid
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(-116.382312, 33.728917), 4326));
  IF bad IS DISTINCT FROM 'Karina Moreno' THEN RAISE EXCEPTION 'CC_0533: City Hall resolves to [%], expected Karina Moreno only', bad; END IF;

  RAISE NOTICE 'CC_0533 OK: Palm Desert now five districts; at-large seats retired';
END $$;

COMMIT;
