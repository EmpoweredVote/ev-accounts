-- CC_0534_indian_wells_city_government.sql
-- CC_0534: City of Indian Wells, CA (place 0636434, Riverside County) -- the city council, which did not exist.
--
-- WHAT WAS THERE (read 2026-11-28). Only the TIGER G4110 outline 'Indian Wells city' (geo_id '0636434'). No government,
-- chamber, district, office or person. (Schools: Desert Sands Unified, CC_0524.)
--
-- THE COUNCIL. indianwellsca.gov (the old cityofindianwells.org redirects there), read 2026-11-28:
--   city_government/city_council/index.php: "governed by a five-member city council ... The Council elects a mayor from
--   its membership to serve as its presiding officer for a one-year term." -> NO separately elected Mayor; Mayor and
--   Mayor Pro Tem are council-chosen roles, kept in office descriptions, not titles (Duvall ruling 5).
--   Member pages: "Dr. Toper Taylor -- Mayor -- Elected 2024, Current Term of Office 2028"; "Brian M Penna -- Mayor Pro
--   Tem -- Elected 2024, Current Term of Office 2028"; "Bruce Whitman -- Elected 2022, Current Term of Office 2026";
--   "Dana Reed -- Elected 2014, Current Term of Office 2026"; "Greg Sanders -- Elected 2020, Current Term of Office 2028".
-- AT LARGE: the Riverside ROV contest is "Indian Wells City Council, VOTE FOR 2", citywide, no districts, and the
--   county's 2026 election calendar (Board of Supervisors item 2.15, 2026-09-22) lists only "City Council" for the city.
-- CITY CLERK: the city's clerk page describes a staff office ("The City Clerk's Office is responsible for ..."), no
--   source read calls the clerk elected, and the county calendar lists no Indian Wells clerk -- not seated here.
-- SHAPE: five councilmember offices on one LOCAL district on the city's G4110 outline (Hawthorne's council half).
--
-- 2026 ELECTION. Riverside ROV, update #27 (2026-11-25), Indian Wells City Council (vote for 2): Rob Zwemmer 1,459
-- (41.19%), Michael Hazelton 1,137 (32.10%), Karlyn Neel 946. The ROV final candidate list (printed 2026-09-11) names the
-- incumbents Bruce Whitman and Dana Reed, neither of them a candidate (the office "goes into extension").
-- So Zwemmer and Hazelton replace Whitman and Reed. The seats are unnumbered: Zwemmer is placed on Whitman's office and
-- Hazelton on Reed's, an arbitrary but fixed pairing.
-- THE DATE IS AN ESTIMATE. The county had certified by 2026-11-25 (Indio's 2026-12-02 packet presents the certified
-- results), and indianwellsca.gov/city_government/meeting_agendas.php lists a "City Council Meeting" on 2026-12-03 with no
-- agenda posted yet on 2026-11-28 -- the first December meeting. start_precision 'month' (the CC_0521 treatment).
-- ▶ FOLLOW-UP: confirm from the 2026-12-03 agenda/minutes; move both dates together if the oath was another day.
-- 🔴 OVERWRITTEN VALUE: none before this file -- Whitman's and Reed's terms are created here, open-ended, and closed at
-- 2026-12-02 by seat_officeholder in the same transaction.
--
-- TERMS: open-ended, start_precision 'unknown' ("Elected YYYY" is how each member arrived, not a current-term start).
-- PEOPLE: no active politician row carried any of the seven names on 2026-11-28. external_id -4012401..-4012407 (unused
-- block). Party is never stored.
--
-- Apply with: node scripts/apply-migration-file.mjs migrations/CC_0534_indian_wells_city_government.sql
BEGIN;

-- ─── 0. Preconditions ───
DO $$
DECLARE n int;
BEGIN
  PERFORM 1 FROM essentials.geofence_boundaries WHERE mtfcc = 'G4110' AND geo_id = '0636434';
  IF NOT FOUND THEN RAISE EXCEPTION 'CC_0534 precondition: no G4110 outline for Indian Wells (0636434)'; END IF;
  SELECT count(*) INTO n FROM essentials.governments
   WHERE (geo_id = '0636434' OR name ILIKE 'City of Indian Wells%') AND id <> '73f461ec-748c-43f6-ba39-c22a67b5531e';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0534 precondition: another City of Indian Wells government exists (%)', n; END IF;
  SELECT count(*) INTO n FROM essentials.districts WHERE geo_id = '0636434' AND id <> '7735dc21-26ab-41a9-8f7a-d351385067ed';
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0534 precondition: a district on geo_id 0636434 already exists (%)', n; END IF;
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE external_id BETWEEN -4012407 AND -4012401
     AND id NOT IN ('9539b162-ee7f-4b3a-aa2b-69e87c0f348b','669e5a51-68b9-4f18-a81d-12d433f9e443','5d0f3b5c-72f5-4b5f-95ac-2b2ae40e09b1',
                    '479f2b6d-2491-4898-95fc-caddfedce6ab','5780646e-5522-4bd3-8c73-3a753ec49307','ed890863-8e45-4f8d-907f-54ade496ce58',
                    '528923f2-fc62-4c1c-b853-d6a098cc2005');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0534 precondition: an external_id in -4012407..-4012401 belongs to someone else'; END IF;
END $$;

-- ─── 1. Government, district, chamber ───
INSERT INTO essentials.governments (id, name, type, state, city, geo_id, mtfcc)
SELECT '73f461ec-748c-43f6-ba39-c22a67b5531e'::uuid, 'City of Indian Wells, California, US', 'City', 'CA', 'Indian Wells', '0636434', 'G4110'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE id = '73f461ec-748c-43f6-ba39-c22a67b5531e'::uuid);

INSERT INTO essentials.districts (id, label, district_type, district_id, state, num_officials, mtfcc, geo_id,
                                  is_judicial, has_unknown_boundaries, retention, representation_basis, ocd_id, official_web_url)
SELECT '7735dc21-26ab-41a9-8f7a-d351385067ed'::uuid, 'Indian Wells City Council (At-Large)', 'LOCAL', '0', 'CA', 5, 'G4110', '0636434',
       false, false, false, 'residency', 'ocd-division/country:us/state:ca/place:indian_wells',
       'https://www.indianwellsca.gov/city_government/city_council/index.php'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE id = '7735dc21-26ab-41a9-8f7a-d351385067ed'::uuid);

INSERT INTO essentials.chambers (id, government_id, name, name_formal, official_count, website_url, policy_engagement_level)
SELECT '2334497c-6a07-400d-829a-079d227c8794'::uuid, '73f461ec-748c-43f6-ba39-c22a67b5531e'::uuid, 'City Council',
       'Indian Wells City Council', 5, 'https://www.indianwellsca.gov/city_government/city_council/index.php', 'full'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE id = '2334497c-6a07-400d-829a-079d227c8794'::uuid);

-- ─── 2. Offices ───
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, representing_city, seats, normalized_position_name,
                                is_appointed_position, is_vacant, faces_retention_vote, voting_powers, description)
SELECT v.oid, '2334497c-6a07-400d-829a-079d227c8794'::uuid, '7735dc21-26ab-41a9-8f7a-d351385067ed'::uuid, 'Councilmember', 'CA', 'Indian Wells', 1,
       'Councilmember', false, false, false, 'full', v.descr
  FROM (VALUES
    ('f0b8e96a-70bb-4a74-8307-2c422bac08f9'::uuid, 'Elected at large to a four-year term. Serving as Mayor (the council elects the Mayor from its members for a one-year term; indianwellsca.gov, 2026-11-28).'),
    ('0c9df71b-4edd-4e30-8431-525fa95af1c2'::uuid, 'Elected at large to a four-year term. Serving as Mayor Pro Tem (indianwellsca.gov, 2026-11-28).'),
    ('4555a224-c5b3-41f2-90aa-94ae5a0bae08'::uuid, 'Elected at large to a four-year term.'),
    ('36507dae-d75c-4d95-a625-5cc99755ba87'::uuid, 'Elected at large to a four-year term.'),
    ('7577fcde-9919-4446-ac47-4b3093a0e688'::uuid, 'Elected at large to a four-year term.')
  ) AS v(oid, descr)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = v.oid);

-- ─── 3. People ───
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, preferred_name, alternate_names, is_active, source)
SELECT v.id, v.ext, v.n, v.f, v.l, v.pref, v.alt, true, v.src
  FROM (VALUES
    ('9539b162-ee7f-4b3a-aa2b-69e87c0f348b'::uuid, -4012401, 'Toper Taylor', 'Toper', 'Taylor', 'Dr. Toper Taylor', ARRAY['Dr. Toper Taylor']::text[], 'indianwellsca.gov city council member page (read 2026-11-28) (CC_0534)'),
    ('669e5a51-68b9-4f18-a81d-12d433f9e443'::uuid, -4012402, 'Brian M. Penna', 'Brian', 'Penna', NULL, ARRAY['Brian Penna']::text[], 'indianwellsca.gov city council member page (read 2026-11-28) (CC_0534)'),
    ('5d0f3b5c-72f5-4b5f-95ac-2b2ae40e09b1'::uuid, -4012403, 'Bruce Whitman', 'Bruce', 'Whitman', NULL, ARRAY[]::text[], 'indianwellsca.gov city council member page (read 2026-11-28) (CC_0534)'),
    ('479f2b6d-2491-4898-95fc-caddfedce6ab'::uuid, -4012404, 'Dana Reed', 'Dana', 'Reed', NULL, ARRAY[]::text[], 'indianwellsca.gov city council member page (read 2026-11-28) (CC_0534)'),
    ('5780646e-5522-4bd3-8c73-3a753ec49307'::uuid, -4012405, 'Greg Sanders', 'Greg', 'Sanders', NULL, ARRAY[]::text[], 'indianwellsca.gov city council member page (read 2026-11-28) (CC_0534)'),
    ('ed890863-8e45-4f8d-907f-54ade496ce58'::uuid, -4012406, 'Rob Zwemmer', 'Rob', 'Zwemmer', NULL, ARRAY[]::text[], 'Riverside ROV Nov 3 2026 results, Indian Wells City Council (update #27, 2026-11-25) (CC_0534)'),
    ('528923f2-fc62-4c1c-b853-d6a098cc2005'::uuid, -4012407, 'Michael Hazelton', 'Michael', 'Hazelton', NULL, ARRAY[]::text[], 'Riverside ROV Nov 3 2026 results, Indian Wells City Council (update #27, 2026-11-25) (CC_0534)')
  ) AS v(id, ext, n, f, l, pref, alt, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id);

CREATE TEMP TABLE cc0534_plan ON COMMIT DROP AS
SELECT unnest(ARRAY['9539b162-ee7f-4b3a-aa2b-69e87c0f348b','669e5a51-68b9-4f18-a81d-12d433f9e443','5d0f3b5c-72f5-4b5f-95ac-2b2ae40e09b1',
                    '479f2b6d-2491-4898-95fc-caddfedce6ab','5780646e-5522-4bd3-8c73-3a753ec49307','ed890863-8e45-4f8d-907f-54ade496ce58',
                    '528923f2-fc62-4c1c-b853-d6a098cc2005']::uuid[]) AS politician_id;

-- ▼▼ BLOCK A (backend/migrations/_templates/office_terms_incumbency_guard.sql) ▼▼
-- @incumbency-decision: gated — opens five undated Indian Wells terms, then seats Rob Zwemmer and Michael Hazelton from 2026-12-03 (closing Whitman and Reed at 2026-12-02); none has a race row
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
   AND rc.politician_id IN (SELECT politician_id FROM cc0534_plan);
-- ▲▲ END OF BLOCK A ▲▲

-- ─── 4. Terms ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT v.oid, v.pid, NULL, 'unknown', 'elected', 'indianwellsca.gov member page (read 2026-11-28): ' || v.src || ' Start of current tenure not dated. (CC_0534)'
  FROM (VALUES
    ('f0b8e96a-70bb-4a74-8307-2c422bac08f9'::uuid, '9539b162-ee7f-4b3a-aa2b-69e87c0f348b'::uuid, 'Mayor, "Elected 2024, Current Term of Office 2028".'),
    ('0c9df71b-4edd-4e30-8431-525fa95af1c2'::uuid, '669e5a51-68b9-4f18-a81d-12d433f9e443'::uuid, 'Mayor Pro Tem, "Elected 2024, Current Term of Office 2028".'),
    ('4555a224-c5b3-41f2-90aa-94ae5a0bae08'::uuid, '5d0f3b5c-72f5-4b5f-95ac-2b2ae40e09b1'::uuid, '"Elected 2022, Current Term of Office 2026".'),
    ('36507dae-d75c-4d95-a625-5cc99755ba87'::uuid, '479f2b6d-2491-4898-95fc-caddfedce6ab'::uuid, '"Elected 2014, Current Term of Office 2026".'),
    ('7577fcde-9919-4446-ac47-4b3093a0e688'::uuid, '5780646e-5522-4bd3-8c73-3a753ec49307'::uuid, '"Elected 2020, Current Term of Office 2028".')
  ) AS v(oid, pid, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v.oid);

SELECT essentials.seat_officeholder(v.oid, v.pid, DATE '2026-12-03',
  'Elected 2026-11-03, Indian Wells City Council (vote for 2): Zwemmer 1,459, Hazelton 1,137, Neel 946, Riverside County ROV (update #27, '
  || '2026-11-25). START DATE ESTIMATED: 2026-12-03 is the first December council meeting (indianwellsca.gov meeting agendas); '
  || 'replace when its agenda/minutes are posted. (CC_0534)',
  'elected', 'month', 'term_expired', false)
  FROM (VALUES ('4555a224-c5b3-41f2-90aa-94ae5a0bae08'::uuid, 'ed890863-8e45-4f8d-907f-54ade496ce58'::uuid),
               ('36507dae-d75c-4d95-a625-5cc99755ba87'::uuid, '528923f2-fc62-4c1c-b853-d6a098cc2005'::uuid)) AS v(oid, pid);

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
  SELECT count(*) INTO v_planned FROM cc0534_plan;
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
  SELECT string_agg(v.id::text || ' -> ' || coalesce(p.full_name, 'NULL'), '; ') INTO bad
    FROM (VALUES
      ('f0b8e96a-70bb-4a74-8307-2c422bac08f9'::uuid, 'Toper Taylor'),
      ('0c9df71b-4edd-4e30-8431-525fa95af1c2'::uuid, 'Brian M. Penna'),
      ('4555a224-c5b3-41f2-90aa-94ae5a0bae08'::uuid, CASE WHEN CURRENT_DATE < DATE '2026-12-03' THEN 'Bruce Whitman' ELSE 'Rob Zwemmer' END),
      ('36507dae-d75c-4d95-a625-5cc99755ba87'::uuid, CASE WHEN CURRENT_DATE < DATE '2026-12-03' THEN 'Dana Reed' ELSE 'Michael Hazelton' END),
      ('7577fcde-9919-4446-ac47-4b3093a0e688'::uuid, 'Greg Sanders')
    ) AS v(id, holder)
    LEFT JOIN essentials.offices o ON o.id = v.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.id IS NULL OR p.full_name IS DISTINCT FROM v.holder OR o.title <> 'Councilmember'
      OR o.district_id <> '7735dc21-26ab-41a9-8f7a-d351385067ed'::uuid OR o.chamber_id <> '2334497c-6a07-400d-829a-079d227c8794'::uuid;
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0534: office/holder mismatch: %', bad; END IF;

  -- incoming successors sit on the two departing members' seats, not on Taylor's, Penna's or Sanders'
  IF CURRENT_DATE < DATE '2026-12-03' THEN
    SELECT string_agg(v.oid::text || ' -> ' || coalesce(p.full_name, 'NONE'), '; ') INTO bad
      FROM (VALUES ('4555a224-c5b3-41f2-90aa-94ae5a0bae08'::uuid, 'Rob Zwemmer'), ('36507dae-d75c-4d95-a625-5cc99755ba87'::uuid, 'Michael Hazelton'),
                   ('f0b8e96a-70bb-4a74-8307-2c422bac08f9'::uuid, NULL), ('0c9df71b-4edd-4e30-8431-525fa95af1c2'::uuid, NULL),
                   ('7577fcde-9919-4446-ac47-4b3093a0e688'::uuid, NULL)) AS v(oid, want)
      LEFT JOIN essentials.office_next_term ont ON ont.office_id = v.oid
      LEFT JOIN essentials.politicians p ON p.id = ont.politician_id
     WHERE p.full_name IS DISTINCT FROM v.want OR (v.want IS NOT NULL AND ont.term_start <> DATE '2026-12-03');
    IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0534: incoming holders wrong: %', bad; END IF;
  END IF;

  -- City Hall (44950 Eldorado Dr; Census Geocoder -116.338944, 33.713478) reaches all five council offices
  SELECT count(DISTINCT o.id) INTO n
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id AND o.chamber_id = '2334497c-6a07-400d-829a-079d227c8794'::uuid
   WHERE gb.mtfcc = 'G4110' AND gb.geo_id = '0636434'
     AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(-116.338944, 33.713478), 4326));
  IF n <> 5 THEN RAISE EXCEPTION 'CC_0534: City Hall point reaches % Indian Wells offices, expected 5', n; END IF;

  RAISE NOTICE 'CC_0534 OK: City of Indian Wells, 5 councilmembers seated; Zwemmer and Hazelton incoming 2026-12-03';
END $$;

COMMIT;
