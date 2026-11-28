-- CC_0525_coachella_valley_usd_board.sql
-- CC_0525: Coachella Valley Unified School District (Riverside + Imperial counties, CA; TIGER 0609070) -- the board.
-- Serves the eastern edge of Indio, plus Coachella, Thermal, Mecca, Oasis and the Salton Sea communities.
--
-- WHAT WAS THERE (read 2026-11-27). Only the TIGER G5420 outline (geo_id '0609070'). No government, chamber,
-- district, office or person.
--
-- THE BOARD. cvusd.us/trustees (read 2026-11-27); cvusd.us/trustee-area-boundaries: "represented by seven elected
-- members of the Board of Education who serve four trustee areas":
--   Coachella Trustee Area No. 1 (three seats): Valerie Garcia (Vice President, exp. 2026), Trinidad Arredondo
--     (Clerk, exp. 2028), Joey Acuña Jr. (exp. 2026)
--   Thermal Trustee Area No. 2 (two seats): Alena Callimanis (exp. 2026), Jesus Gonzalez (exp. 2028)
--   Oasis Trustee Area No. 3: Thomas Tortez (President, exp. 2028)
--   Mecca Trustee Area No. 4: Jocelyn Vargas (exp. 2028)
-- President / Vice President / Clerk are board officers, not offices. Multi-seat areas get one unnumbered office
-- per seat, all titled 'Board Member (Area N)' (the shared-title shape of the AZ Corporation Commission).
-- Terms open-ended, start_precision 'unknown': the roster gives expiry years only.
--
-- 🔴 GEOGRAPHY: ALL SEVEN OFFICES SIT ON THE WHOLE-DISTRICT OUTLINE, SO EVERY CVUSD ADDRESS SEES ALL SEVEN.
--   That is wrong for a by-area board, and it is knowingly the pre-CC_0519 Fremont shape. The district publishes its
--   trustee areas only as a PICTURE (a 910x1106 screenshot on cvusd.us/trustee-area-boundaries); no GIS layer,
--   KML or shapefile was found from the district, Riverside County GIS (Cloudflare-challenged) or the ROV, and the
--   ROV publishes precinct results only after certification. Digitising a screenshot was ruled out.
--   What the picture does settle: the part of Indio inside CVUSD is the city's southern edge, measured at
--   33.671-33.700 N, -116.269 to -116.182 W (about Avenue 48 to Avenue 52, from Jefferson Street east) -- north of
--   Avenue 54, the top of Thermal Area 2 on the map, so all of it in Coachella Trustee Area No. 1.
--   (EDITED AFTER APPLY, 2026-11-28: the applied copy placed this area "north of Avenue 50 near the northwest
--   corner"; the measurement above replaced that guess. Comment only.) So the three Area 1 trustees are the right
--   answer for every Indio address in CVUSD; the other four are shown in addition, and labelled by area.
--   ▶ FOLLOW-UP: when the ROV's precinct-level statement of votes for "Mbr Gov Bd Coachella Valley USD, TA 1" is
--   published, union its precincts into an Area 1 polygon (or request the trustee-area GIS from the district) and
--   repoint the offices to X0002 '0609070-ta-N' sub-districts, as CC_0519 did for Fremont.
--
-- 2026 ELECTION.
--   Area 1 (vote for 2). Riverside ROV final candidate list (2026-09-11): incumbents Valerie García and Jose "Joey"
--     Acuña Jr.; candidates included Valerie García -- Acuña did not file. Results, update #27 (2026-11-25): Valerie
--     García 8,753 (35.29%), Loretta Perez 8,371 (33.75%), Norma Flores Rivera 3,963 (15.98%), Rafael Medina 3,715
--     (14.98%). García re-elected (same holder, no term written); Loretta Perez succeeds Acuña.
--     THE DATE. Ed. Code 5017(a): a governing-board term begins on the second Friday in December after the election
--     -> 2026-12-11. A statutory day, so 'day' precision.
--     🔴 OVERWRITTEN VALUE: none before this file -- Acuña's term is created here (open-ended) and then closed at
--     2026-12-10 by seat_officeholder in the same transaction.
--   Area 2 (one seat, Callimanis). Not on the ballot: the Desert Sun's 2026 preview reports it uncontested, with
--     Callimanis (appointed August 2025) the lone candidate -> appointment in lieu; she continues. ▶ FOLLOW-UP:
--     confirm after 2026-12-11.
--
-- NAMES. 'Valerie García' as on the certified ballot (the district roster writes 'Valerie Garcia' -> alternate);
-- 'Joey Acuña Jr.' as on the roster ('Jose "Joey" Acuña Jr.' on the ballot -> alternate). No politician row
-- matched any of the eight names on 2026-11-27. external_id -4012014..-4012021 continue the Indio block, unused.
--
-- Apply with: node scripts/apply-migration-file.mjs migrations/CC_0525_coachella_valley_usd_board.sql
BEGIN;

-- ─── 0. Preconditions ───
DO $$
DECLARE n int;
BEGIN
  PERFORM 1 FROM essentials.geofence_boundaries WHERE mtfcc = 'G5420' AND geo_id = '0609070';
  IF NOT FOUND THEN RAISE EXCEPTION 'CC_0525 precondition: no G5420 outline for CVUSD (0609070)'; END IF;
  SELECT count(*) INTO n FROM essentials.governments
   WHERE (geo_id = '0609070' OR name ILIKE 'Coachella Valley Unified%') AND id <> 'f4848009-c694-42e5-9be9-356c1277564d';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0525 precondition: another CVUSD government row exists (%)', n; END IF;
  SELECT count(*) INTO n FROM essentials.districts WHERE geo_id = '0609070' AND id <> '35ffb8ef-2613-4d65-a0c1-899838514600';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0525 precondition: a district row on geo_id 0609070 already exists (%)', n; END IF;
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE external_id BETWEEN -4012021 AND -4012014
     AND id NOT IN (SELECT unnest(ARRAY['1280541b-a136-4e31-86ea-17976e201833','4ca4150d-e69c-4e82-900e-57220c37d7ae',
       '041e8979-7aec-422b-a536-9d57c9aeb039','ea334ce1-68cb-4bf8-8b9d-d821aeb0e75b','fe743dbf-d2f5-4948-93cf-706ee1e1b8a5',
       '649fbabe-eda0-4b05-a651-e39268b928a7','cc308e9e-d302-4d67-b3b3-6f3fa8dae8db','2c80074a-9481-4b99-a8b8-fcb018e27943']::uuid[]));
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0525 precondition: an external_id in -4012021..-4012014 belongs to someone else'; END IF;
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE ((first_name ILIKE 'valerie%' AND last_name ILIKE 'garc_a') OR (first_name ILIKE 'trinidad%' AND last_name ILIKE 'arredondo')
       OR (first_name ILIKE ANY (ARRAY['joey%','jose%']) AND last_name ILIKE 'acu_a%') OR last_name ILIKE 'callimanis'
       OR (first_name ILIKE 'jesus%' AND last_name ILIKE 'gonzalez') OR last_name ILIKE 'tortez'
       OR (first_name ILIKE 'jocelyn%' AND last_name ILIKE 'vargas') OR (first_name ILIKE 'loretta%' AND last_name ILIKE 'perez'))
     AND id NOT IN (SELECT unnest(ARRAY['1280541b-a136-4e31-86ea-17976e201833','4ca4150d-e69c-4e82-900e-57220c37d7ae',
       '041e8979-7aec-422b-a536-9d57c9aeb039','ea334ce1-68cb-4bf8-8b9d-d821aeb0e75b','fe743dbf-d2f5-4948-93cf-706ee1e1b8a5',
       '649fbabe-eda0-4b05-a651-e39268b928a7','cc308e9e-d302-4d67-b3b3-6f3fa8dae8db','2c80074a-9481-4b99-a8b8-fcb018e27943']::uuid[]));
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0525 precondition: % existing row(s) carry a CVUSD trustee''s name; check before inserting', n; END IF;
END $$;

-- ─── 1. Government, chamber, whole-district district ───
INSERT INTO essentials.governments (id, name, type, state, geo_id, mtfcc)
SELECT 'f4848009-c694-42e5-9be9-356c1277564d'::uuid, 'Coachella Valley Unified School District, California, US', 'LOCAL', 'CA', '0609070', 'G5420'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE id = 'f4848009-c694-42e5-9be9-356c1277564d'::uuid);

INSERT INTO essentials.chambers (id, government_id, name, name_formal, official_count, website_url, policy_engagement_level)
SELECT '8f85660c-97b6-4674-99c4-a2c85c2e83d6'::uuid, 'f4848009-c694-42e5-9be9-356c1277564d'::uuid, 'Board of Education',
       'Coachella Valley Unified School District Board of Education', 7, 'https://www.cvusd.us/trustees', 'full'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE id = '8f85660c-97b6-4674-99c4-a2c85c2e83d6'::uuid);

INSERT INTO essentials.districts (id, geo_id, district_id, label, district_type, state, mtfcc, num_officials, representation_basis,
                                  ocd_id, official_web_url)
SELECT '35ffb8ef-2613-4d65-a0c1-899838514600'::uuid, '0609070', '0', 'Coachella Valley Unified Board', 'SCHOOL', 'CA', 'G5420', 7,
       'residency', 'ocd-division/country:us/state:ca/school_district:coachella_valley_unified', 'https://www.cvusd.us/trustee-area-boundaries'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE id = '35ffb8ef-2613-4d65-a0c1-899838514600'::uuid);

-- ─── 2. Offices (one per seat) ───
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, seats, normalized_position_name,
                                is_appointed_position, is_vacant, faces_retention_vote, voting_powers, description)
SELECT v.oid, '8f85660c-97b6-4674-99c4-a2c85c2e83d6'::uuid, '35ffb8ef-2613-4d65-a0c1-899838514600'::uuid,
       'Board Member (Area ' || v.n || ')', 'CA', 1, 'Board Member', false, false, false, 'full',
       v.area || ' Trustee Area No. ' || v.n || ' (' || v.seats || '). Elected by the voters of that trustee area only; the district '
       || 'publishes its trustee-area map as an image, so every CVUSD address is shown all seven members (CC_0525).'
  FROM (VALUES
    ('2de364fc-e345-48fe-9aa2-f54ab8f9b485'::uuid, 1, 'Coachella', 'three seats'),
    ('cd882bab-c152-4a3b-9cd7-62fd06a94386'::uuid, 1, 'Coachella', 'three seats'),
    ('d693d6f5-0ebd-47a7-a874-0c9341c9c931'::uuid, 1, 'Coachella', 'three seats'),
    ('3d189882-76cb-41ff-a1de-35c71a8883c9'::uuid, 2, 'Thermal', 'two seats'),
    ('3bbca60e-42c6-4173-9d61-5fc907bad5fb'::uuid, 2, 'Thermal', 'two seats'),
    ('76bec74b-7146-4cdf-8c9a-8a765d739100'::uuid, 3, 'Oasis', 'one seat'),
    ('3dbed570-75a3-4221-8f99-1aaa2f8dae97'::uuid, 4, 'Mecca', 'one seat')
  ) AS v(oid, n, area, seats)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = v.oid);

-- ─── 3. People ───
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, alternate_names, is_active, source)
SELECT v.id, v.ext, v.n, v.f, v.l, v.alt, true, v.src
  FROM (VALUES
    ('1280541b-a136-4e31-86ea-17976e201833'::uuid, -4012014, 'Valerie García', 'Valerie', 'García', ARRAY['Valerie Garcia']::text[], 'cvusd.us/trustees (read 2026-11-27); Riverside ROV Nov 3 2026 results (CC_0525)'),
    ('4ca4150d-e69c-4e82-900e-57220c37d7ae'::uuid, -4012015, 'Trinidad Arredondo', 'Trinidad', 'Arredondo', ARRAY[]::text[], 'cvusd.us/trustees (read 2026-11-27) (CC_0525)'),
    ('041e8979-7aec-422b-a536-9d57c9aeb039'::uuid, -4012016, 'Joey Acuña Jr.', 'Joey', 'Acuña', ARRAY['Jose "Joey" Acuña Jr.','Joey Acuna Jr.']::text[], 'cvusd.us/trustees (read 2026-11-27) (CC_0525)'),
    ('ea334ce1-68cb-4bf8-8b9d-d821aeb0e75b'::uuid, -4012017, 'Alena Callimanis', 'Alena', 'Callimanis', ARRAY[]::text[], 'cvusd.us/trustees (read 2026-11-27) (CC_0525)'),
    ('fe743dbf-d2f5-4948-93cf-706ee1e1b8a5'::uuid, -4012018, 'Jesus Gonzalez', 'Jesus', 'Gonzalez', ARRAY[]::text[], 'cvusd.us/trustees (read 2026-11-27) (CC_0525)'),
    ('649fbabe-eda0-4b05-a651-e39268b928a7'::uuid, -4012019, 'Thomas Tortez', 'Thomas', 'Tortez', ARRAY[]::text[], 'cvusd.us/trustees (read 2026-11-27) (CC_0525)'),
    ('cc308e9e-d302-4d67-b3b3-6f3fa8dae8db'::uuid, -4012020, 'Jocelyn Vargas', 'Jocelyn', 'Vargas', ARRAY[]::text[], 'cvusd.us/trustees (read 2026-11-27) (CC_0525)'),
    ('2c80074a-9481-4b99-a8b8-fcb018e27943'::uuid, -4012021, 'Loretta Perez', 'Loretta', 'Perez', ARRAY[]::text[], 'Riverside ROV Nov 3 2026 results, Mbr Gov Bd Coachella Valley USD TA 1 (update #27, 2026-11-25) (CC_0525)')
  ) AS v(id, ext, n, f, l, alt, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id);

CREATE TEMP TABLE cc0525_plan ON COMMIT DROP AS
SELECT unnest(ARRAY['1280541b-a136-4e31-86ea-17976e201833','4ca4150d-e69c-4e82-900e-57220c37d7ae','041e8979-7aec-422b-a536-9d57c9aeb039',
                    'ea334ce1-68cb-4bf8-8b9d-d821aeb0e75b','fe743dbf-d2f5-4948-93cf-706ee1e1b8a5','649fbabe-eda0-4b05-a651-e39268b928a7',
                    'cc308e9e-d302-4d67-b3b3-6f3fa8dae8db','2c80074a-9481-4b99-a8b8-fcb018e27943']::uuid[]) AS politician_id;

-- ▼▼ BLOCK A (backend/migrations/_templates/office_terms_incumbency_guard.sql) ▼▼
-- @incumbency-decision: gated — opens seven undated CVUSD terms, then seats Loretta Perez on Acuña's Area 1 seat from 2026-12-11 (closing Acuña at 2026-12-10); none has a race row
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
   AND rc.politician_id IN (SELECT politician_id FROM cc0525_plan);
-- ▲▲ END OF BLOCK A ▲▲

-- ─── 4. Terms ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT v.oid, v.pid, NULL, 'unknown', v.how,
       'CVUSD trustee roster (cvusd.us/trustees, read 2026-11-27): Trustee Area No. ' || v.n || ', term expires ' || v.exp
       || '. Start of tenure not dated. (CC_0525)'
  FROM (VALUES
    ('2de364fc-e345-48fe-9aa2-f54ab8f9b485'::uuid, '1280541b-a136-4e31-86ea-17976e201833'::uuid, 1, 2026, 'elected'),
    ('cd882bab-c152-4a3b-9cd7-62fd06a94386'::uuid, '4ca4150d-e69c-4e82-900e-57220c37d7ae'::uuid, 1, 2028, 'elected'),
    ('d693d6f5-0ebd-47a7-a874-0c9341c9c931'::uuid, '041e8979-7aec-422b-a536-9d57c9aeb039'::uuid, 1, 2026, 'elected'),
    ('3d189882-76cb-41ff-a1de-35c71a8883c9'::uuid, 'ea334ce1-68cb-4bf8-8b9d-d821aeb0e75b'::uuid, 2, 2026, 'appointed'),
    ('3bbca60e-42c6-4173-9d61-5fc907bad5fb'::uuid, 'fe743dbf-d2f5-4948-93cf-706ee1e1b8a5'::uuid, 2, 2028, 'elected'),
    ('76bec74b-7146-4cdf-8c9a-8a765d739100'::uuid, '649fbabe-eda0-4b05-a651-e39268b928a7'::uuid, 3, 2028, 'elected'),
    ('3dbed570-75a3-4221-8f99-1aaa2f8dae97'::uuid, 'cc308e9e-d302-4d67-b3b3-6f3fa8dae8db'::uuid, 4, 2028, 'elected')
  ) AS v(oid, pid, n, exp, how)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v.oid);

SELECT essentials.seat_officeholder(
  'd693d6f5-0ebd-47a7-a874-0c9341c9c931'::uuid,
  '2c80074a-9481-4b99-a8b8-fcb018e27943'::uuid,
  DATE '2026-12-11',
  'Elected 2026-11-03, Mbr Gov Bd Coachella Valley USD TA 1 (vote for 2): García 8,753, Loretta Perez 8,371, Flores Rivera 3,963, '
  || 'Medina 3,715, Riverside County ROV (update #27, 2026-11-25). Succeeds Joey Acuña Jr., who did not file. Term begins the second '
  || 'Friday in December, Ed. Code 5017(a). (CC_0525)',
  'elected', 'day', 'term_expired', false);

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
  SELECT count(*) INTO v_planned FROM cc0525_plan;
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
DECLARE n int; bad text; v_next text; v_on date;
BEGIN
  -- every seat is held today by the trustee the district lists (fields, not counts)
  SELECT string_agg(coalesce(o.title, v.id::text) || ' -> ' || coalesce(p.full_name, 'NULL'), '; ') INTO bad
    FROM (VALUES ('2de364fc-e345-48fe-9aa2-f54ab8f9b485'::uuid, '1', 'Valerie García'),
                 ('cd882bab-c152-4a3b-9cd7-62fd06a94386'::uuid, '1', 'Trinidad Arredondo'),
                 ('d693d6f5-0ebd-47a7-a874-0c9341c9c931'::uuid, '1', CASE WHEN CURRENT_DATE < DATE '2026-12-11' THEN 'Joey Acuña Jr.' ELSE 'Loretta Perez' END),
                 ('3d189882-76cb-41ff-a1de-35c71a8883c9'::uuid, '2', 'Alena Callimanis'),
                 ('3bbca60e-42c6-4173-9d61-5fc907bad5fb'::uuid, '2', 'Jesus Gonzalez'),
                 ('76bec74b-7146-4cdf-8c9a-8a765d739100'::uuid, '3', 'Thomas Tortez'),
                 ('3dbed570-75a3-4221-8f99-1aaa2f8dae97'::uuid, '4', 'Jocelyn Vargas')) AS v(id, n, holder)
    LEFT JOIN essentials.offices o ON o.id = v.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.id IS NULL OR o.title <> 'Board Member (Area ' || v.n || ')' OR p.full_name IS DISTINCT FROM v.holder
      OR o.district_id <> '35ffb8ef-2613-4d65-a0c1-899838514600'::uuid OR o.chamber_id <> '8f85660c-97b6-4674-99c4-a2c85c2e83d6'::uuid;
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0525: office/holder mismatch: %', bad; END IF;

  -- the queued successor is Loretta Perez on Acuña's seat -- not on García's (the swap a count cannot see)
  IF CURRENT_DATE < DATE '2026-12-11' THEN
    SELECT p.full_name, ont.term_start INTO v_next, v_on FROM essentials.office_next_term ont JOIN essentials.politicians p ON p.id = ont.politician_id
     WHERE ont.office_id = 'd693d6f5-0ebd-47a7-a874-0c9341c9c931';
    IF v_next IS DISTINCT FROM 'Loretta Perez' OR v_on IS DISTINCT FROM DATE '2026-12-11' THEN
      RAISE EXCEPTION 'CC_0525: incoming on Acuña''s seat is % on %, expected Loretta Perez on 2026-12-11', v_next, v_on;
    END IF;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE politician_id = '2c80074a-9481-4b99-a8b8-fcb018e27943';
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0525: Loretta Perez has % terms, expected 1', n; END IF;
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE politician_id = '041e8979-7aec-422b-a536-9d57c9aeb039' AND term_end = DATE '2026-12-10';
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0525: Acuña''s term was not closed at 2026-12-10'; END IF;

  -- the board is whole: 7 offices, 7 held today (count the holder, not the row)
  SELECT count(och.politician_id) INTO n FROM essentials.offices o
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.chamber_id = '8f85660c-97b6-4674-99c4-a2c85c2e83d6'::uuid;
  IF n <> 7 THEN RAISE EXCEPTION 'CC_0525: % of 7 CVUSD seats held', n; END IF;

  RAISE NOTICE 'CC_0525 OK: CVUSD board, 7 trustees seated; Loretta Perez incoming on Area 1 on 2026-12-11';
END $$;

COMMIT;
