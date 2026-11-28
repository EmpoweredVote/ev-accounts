-- CC_0523_indio_clerk_treasurer_and_d4_incoming.sql
-- CC_0523: Indio, CA (place 0636448) -- the two missing elected city officers, and the incoming District 4
-- councilmember.
--
-- WHAT WAS ALREADY THERE (read 2026-11-27). City of Indio government d37dbc2b-760c-45e9-aadf-f5a3525631c6, chamber
-- 'City Council' 9669f389-..., five by-district offices on X0023 'indio-ca-council-district-1..5', all held
-- (Miller D1, Fermon D2 'Mayor Pro Tem', Holmes D3 'Mayor', Oscar Ortiz D4, Guitron IV D5), each term open-ended
-- from the ADR 0002 phase-2 backfill. Every name, district and title matches the city's roster
-- (indio.org/departments/city-council/meet-your-representatives and the five staff pages, read 2026-11-27) and the
-- city's "Notice of City Council Reorganization", 2025-12-05 (Holmes D3 Mayor, Fermon D2 Mayor Pro Tem, Ortiz D4,
-- Guitron IV D5, Miller D1). No races, no Clerk, no Treasurer.
--
-- 1. CITY CLERK AND CITY TREASURER -- both elected, both missing.
--    indio.org/departments/city-council/other-elected-officials (read 2026-11-27):
--      "Cynthia Hernandez / City Clerk / Term: 2024 - 2028 ... The City Clerk is elected to a four-year term and
--       acts in a ceremonial capacity. The responsibilities and duties of this office are performed by the City
--       Clerk Administrator."
--      "Rob Rockwell / City Treasurer / Term ending in 2028 ... The City Treasurer is elected to a four-year term
--       and acts in a ceremonial capacity."
--    The Clerk's own page adds "has served as the elected City Clerk for the City of Indio since 2004"; the
--    Treasurer's says "reappointed as the City Treasurer ... beginning his second term in December 2024" (an
--    uncontested seat filled by appointment in lieu of election). Neither page gives the day a term began, and
--    "since 2004" is how the Clerk ARRIVED, not a dated start -> both terms open-ended, start_precision 'unknown'.
--    Shape copied from West Covina (CA_0172): one LOCAL_EXEC district 'Indio City Officers' on the city's own G4110
--    outline (geo_id '0636448'), a chamber per office, voting_powers 'full' as every corpus clerk/treasurer row.
--    ⚠ A namesake exists: politician 00482c08-... 'Cynthia Hernandez' is an Antelope Valley Joint Union High
--    School trustee (CA_0158) -- a different person in LA County. Not reused; this file creates a new row.
--
-- 2. DISTRICT 4 HANDOVER. Oscar Ortiz did not run (he is a 2026 candidate for Assembly District 36).
--    - Riverside County ROV final candidate list, Nov 3 2026 (voteinfo.net, "Final candidate list nov 2026 eng.pdf",
--      printed 2026-09-11): "Indio City Council, District 4 ... Incumbent(s): Oscar Ortiz ... Candidate(s): Felipe
--      Ortiz, Legislative Aide / Businessman" and Jonathan Becerra.
--    - Result: Riverside ROV results, update #27 (2026-11-25): Felipe Ortiz 2,147 (63.99%), Jonathan Becerra 1,208
--      (36.01%). The same figures are in Indio's staff report for Resolution No. 10617 ("Accepting the Certified
--      Results ... Certified by the Riverside County Registrar of Voters"), City Council agenda of 2026-12-02,
--      item 13.1, whose Section 4 declares "FELIPE ORTIZ was elected as member of the City Council, District 4 for
--      the full term of four years".
--    - THE DATE. The same agenda (indio.civicweb.net document 200455, "City Council - 02 Dec 2026") lists 13.2
--      "Oath of Office for Incoming elected Officials" and 6.2 "Proclamation Honoring Outgoing City Councilmember
--      Oscar Ortiz". So the handover is SCHEDULED for 2026-12-02. 'day' precision because the meeting is fixed;
--      ⚠ it has not happened yet. ▶ FOLLOW-UP: confirm from the 2026-12-02 minutes; move both dates together if
--      the oath slipped.
--    - Districts 2 and 3: Fermon (1,935 v Gloria Hernandez 1,892) and Holmes (2,733 v Andrea "A.J." Dolan
--      Bouchard 1,754) were re-elected -- same holder, no term written.
--    🔴 OVERWRITTEN VALUE: office_terms ed5c3132-955d-41ca-937d-602ef2d8ed82 (Oscar Ortiz, D4) term_end was NULL,
--       how_ended NULL. seat_officeholder closes it at 2026-12-01 ('term_expired').
--
-- NOT CHANGED, AND WHY. Item 14.1 of the same agenda is "Transition of Mayor and Mayor Pro Tem Roles": the rotation
-- (Resolution No. 9507) moves both titles on 2026-12-02, and the agenda does not name the new holders. The office
-- titles 'Mayor' (D3) and 'Mayor Pro Tem' (D2) stay as they are -- true until that meeting -- the corpus convention
-- (Palm Springs carries the same shape). ▶ FOLLOW-UP with the D4 date: retitle from the 2026-12-02 minutes.
--
-- PEOPLE. external_id continues Indio's block (-4012001..-4012005 are the council): -4012006 Felipe Ortiz,
-- -4012007 Cynthia Hernandez, -4012008 Rob Rockwell. All three were unused on 2026-11-27, and no politician row
-- matched (first 'felipe%', last 'ortiz') or (first 'rob%', last 'rockwell'). Party is never stored.
--
-- Apply with: node scripts/apply-migration-file.mjs migrations/CC_0523_indio_clerk_treasurer_and_d4_incoming.sql
BEGIN;

-- The one active 'Cynthia Hernandez' (00482c08-..., Antelope Valley JUHSD Trustee Area 3, LA County, CA_0158) is a
-- DIFFERENT person from Indio's City Clerk (Riverside County, elected clerk since 2004). Declared, not guessed:
SET LOCAL essentials.allow_duplicate_name = 'on';

-- ─── 0. Preconditions ───
DO $$
DECLARE n int;
BEGIN
  -- D4 is held today by Oscar Ortiz, on the open-ended backfill term, with nothing queued after it
  SELECT count(*) INTO n
    FROM essentials.office_terms t JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.id = 'ed5c3132-955d-41ca-937d-602ef2d8ed82' AND t.office_id = '5342169e-dd41-4354-8f05-248b16e6ff5d'
     AND p.full_name = 'Oscar Ortiz' AND (t.term_end IS NULL OR t.term_end = DATE '2026-12-01');
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0523 precondition: Oscar Ortiz''s D4 term is not in the expected state'; END IF;

  -- the external ids are unused or already ours (an external_id collision seats the wrong person)
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE (external_id = -4012006 AND id <> '67b41cba-1524-49a1-a8b5-91624b5bbbee')
      OR (external_id = -4012007 AND id <> 'f4f88028-b420-4279-be23-47de511ef541')
      OR (external_id = -4012008 AND id <> '052aa5d2-4f68-47f3-8f24-6fb62afe8878');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0523 precondition: an external_id in -4012006..-4012008 belongs to someone else'; END IF;

  -- no Felipe Ortiz or Rob Rockwell row has appeared since the header was written
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE ((first_name ILIKE 'felipe%' AND last_name ILIKE 'ortiz') OR (first_name ILIKE 'rob%' AND last_name ILIKE 'rockwell'))
     AND id NOT IN ('67b41cba-1524-49a1-a8b5-91624b5bbbee', '052aa5d2-4f68-47f3-8f24-6fb62afe8878');
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0523 precondition: another Felipe Ortiz / Rob Rockwell row exists (%); reuse it', n; END IF;

  -- the city outline the officers' district keys on exists
  PERFORM 1 FROM essentials.geofence_boundaries WHERE mtfcc = 'G4110' AND geo_id = '0636448';
  IF NOT FOUND THEN RAISE EXCEPTION 'CC_0523 precondition: no G4110 geofence for Indio (0636448)'; END IF;
END $$;

-- ─── 1. City officers: district, chambers, offices ───
INSERT INTO essentials.districts (id, label, district_type, district_id, state, num_officials, mtfcc, geo_id,
                                  is_judicial, has_unknown_boundaries, retention, representation_basis, ocd_id)
SELECT '54edaa28-5124-4dca-ba29-8135c7f84a3c'::uuid, 'Indio City Officers', 'LOCAL_EXEC', '0', 'CA', 2, 'G4110', '0636448',
       false, false, false, 'residency', 'ocd-division/country:us/state:ca/place:indio'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE id = '54edaa28-5124-4dca-ba29-8135c7f84a3c'::uuid);

INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level)
SELECT v.id, 'd37dbc2b-760c-45e9-aadf-f5a3525631c6'::uuid, v.name, v.nf, 'full' FROM (VALUES
    ('a8115576-f847-4670-a3a0-4b8cb651f15b'::uuid, 'City Clerk', 'Indio City Clerk'),
    ('02b30b7c-b264-4547-8f84-ea80170f29f2'::uuid, 'City Treasurer', 'Indio City Treasurer')
  ) AS v(id, name, nf) WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.id = v.id);

INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, seats, normalized_position_name,
                                is_appointed_position, is_vacant, faces_retention_vote, voting_powers, description)
SELECT v.oid, v.cid, '54edaa28-5124-4dca-ba29-8135c7f84a3c'::uuid, v.title, 'CA', 1, v.title, false, false, false, 'full', v.descr
  FROM (VALUES
    ('a2e2e5d1-853c-4fdb-8588-a9bcb0fa625a'::uuid, 'a8115576-f847-4670-a3a0-4b8cb651f15b'::uuid, 'City Clerk',
     'Elected citywide to a four-year term. A ceremonial office: the City Clerk Administrator performs the duties (indio.org).'),
    ('da6bd480-899f-418f-b831-5a37b624b4ee'::uuid, '02b30b7c-b264-4547-8f84-ea80170f29f2'::uuid, 'City Treasurer',
     'Elected citywide to a four-year term. A ceremonial office: the Finance Department performs the duties; the Treasurer sits on the Citizens'' Finance Advisory Commission and the City Investment Committee (indio.org).')
  ) AS v(oid, cid, title, descr)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = v.oid);

-- ─── 2. People ───
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active, source)
SELECT v.id, v.ext, v.n, v.f, v.l, true, v.src FROM (VALUES
    ('67b41cba-1524-49a1-a8b5-91624b5bbbee'::uuid, -4012006, 'Felipe Ortiz', 'Felipe', 'Ortiz',
     'Riverside County ROV Nov 3 2026 results (update #27, 2026-11-25) and Indio Resolution No. 10617 (agenda 2026-12-02), Indio City Council District 4 (CC_0523)'),
    ('f4f88028-b420-4279-be23-47de511ef541'::uuid, -4012007, 'Cynthia Hernandez', 'Cynthia', 'Hernandez',
     'indio.org/departments/city-council/other-elected-officials, City Clerk (read 2026-11-27) (CC_0523)'),
    ('052aa5d2-4f68-47f3-8f24-6fb62afe8878'::uuid, -4012008, 'Rob Rockwell', 'Rob', 'Rockwell',
     'indio.org/departments/city-council/other-elected-officials, City Treasurer (read 2026-11-27) (CC_0523)')
  ) AS v(id, ext, n, f, l, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id);

CREATE TEMP TABLE cc0523_plan ON COMMIT DROP AS
SELECT unnest(ARRAY['67b41cba-1524-49a1-a8b5-91624b5bbbee', '4bbba476-c442-42d5-8b5d-07e8fac1481c',
                    'f4f88028-b420-4279-be23-47de511ef541', '052aa5d2-4f68-47f3-8f24-6fb62afe8878']::uuid[]) AS politician_id;

-- ▼▼ BLOCK A (backend/migrations/_templates/office_terms_incumbency_guard.sql) ▼▼
-- @incumbency-decision: gated — seats Felipe Ortiz on Indio D4 from 2026-12-02 (closing Oscar Ortiz at 2026-12-01) and opens undated terms for the City Clerk and City Treasurer
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
   AND rc.politician_id IN (SELECT politician_id FROM cc0523_plan);
-- ▲▲ END OF BLOCK A ▲▲

-- ─── 3. Terms ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT v.oid, v.pid, NULL, 'unknown', 'elected', v.src FROM (VALUES
    ('a2e2e5d1-853c-4fdb-8588-a9bcb0fa625a'::uuid, 'f4f88028-b420-4279-be23-47de511ef541'::uuid,
     'indio.org other-elected-officials (read 2026-11-27): "Cynthia Hernandez / City Clerk / Term: 2024 - 2028"; elected City Clerk "since 2004" (her page). Start of tenure not dated. (CC_0523)'),
    ('da6bd480-899f-418f-b831-5a37b624b4ee'::uuid, '052aa5d2-4f68-47f3-8f24-6fb62afe8878'::uuid,
     'indio.org other-elected-officials (read 2026-11-27): "Rob Rockwell / City Treasurer / Term ending in 2028"; "reappointed ... beginning his second term in December 2024" (his page). Start of tenure not dated. (CC_0523)')
  ) AS v(oid, pid, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v.oid);

SELECT essentials.seat_officeholder(
  '5342169e-dd41-4354-8f05-248b16e6ff5d'::uuid,
  '67b41cba-1524-49a1-a8b5-91624b5bbbee'::uuid,
  DATE '2026-12-02',
  'Elected 2026-11-03: Felipe Ortiz 2,147 (63.99%) v Jonathan Becerra 1,208, Riverside County ROV (update #27, 2026-11-25); '
  || 'declared elected by Indio Resolution No. 10617. Oath SCHEDULED for the 2026-12-02 council meeting (agenda item 13.2, '
  || 'indio.civicweb.net document 200455); confirm from the minutes. (CC_0523)',
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
  SELECT count(*) INTO v_planned FROM cc0523_plan;
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

-- ─── 4. Post-verify ───
DO $$
DECLARE n int; v_cur text; v_next text; v_on date; bad text;
BEGIN
  -- D4: Oscar Ortiz until 2026-12-01, Felipe Ortiz from 2026-12-02 (asserted by NAME)
  SELECT p.full_name INTO v_cur FROM essentials.office_current_holder och JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE och.office_id = '5342169e-dd41-4354-8f05-248b16e6ff5d';
  SELECT p.full_name, ont.term_start INTO v_next, v_on FROM essentials.office_next_term ont JOIN essentials.politicians p ON p.id = ont.politician_id
   WHERE ont.office_id = '5342169e-dd41-4354-8f05-248b16e6ff5d';
  IF CURRENT_DATE < DATE '2026-12-02' THEN
    IF v_cur IS DISTINCT FROM 'Oscar Ortiz' THEN RAISE EXCEPTION 'CC_0523: current D4 holder is %, expected Oscar Ortiz', v_cur; END IF;
    IF v_next IS DISTINCT FROM 'Felipe Ortiz' OR v_on IS DISTINCT FROM DATE '2026-12-02' THEN
      RAISE EXCEPTION 'CC_0523: incoming D4 holder is % on %, expected Felipe Ortiz on 2026-12-02', v_next, v_on;
    END IF;
  ELSIF v_cur IS DISTINCT FROM 'Felipe Ortiz' THEN
    RAISE EXCEPTION 'CC_0523: current D4 holder is %, expected Felipe Ortiz', v_cur;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE id = 'ed5c3132-955d-41ca-937d-602ef2d8ed82' AND term_end = DATE '2026-12-01';
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0523: Oscar Ortiz''s D4 term was not closed at 2026-12-01'; END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE politician_id = '67b41cba-1524-49a1-a8b5-91624b5bbbee';
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0523: Felipe Ortiz has % terms, expected 1', n; END IF;

  -- each officer office is held by the person its title names, on the city-wide district
  SELECT string_agg(o.title || ' -> ' || coalesce(p.full_name, 'NULL'), '; ') INTO bad
    FROM (VALUES ('a2e2e5d1-853c-4fdb-8588-a9bcb0fa625a'::uuid, 'City Clerk', 'Cynthia Hernandez'),
                 ('da6bd480-899f-418f-b831-5a37b624b4ee'::uuid, 'City Treasurer', 'Rob Rockwell')) v(id, title, holder)
    JOIN essentials.offices o ON o.id = v.id
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.title <> v.title OR p.full_name IS DISTINCT FROM v.holder OR d.geo_id <> '0636448' OR d.mtfcc <> 'G4110'
      OR o.chamber_id NOT IN (SELECT id FROM essentials.chambers WHERE government_id = 'd37dbc2b-760c-45e9-aadf-f5a3525631c6');
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0523: officer mismatch: %', bad; END IF;
  SELECT count(och.politician_id) INTO n FROM essentials.office_current_holder och
   WHERE och.office_id IN ('a2e2e5d1-853c-4fdb-8588-a9bcb0fa625a', 'da6bd480-899f-418f-b831-5a37b624b4ee');
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0523: expected 2 held officer seats, found %', n; END IF;

  -- the new Clerk is not the Antelope Valley namesake
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE politician_id = 'f4f88028-b420-4279-be23-47de511ef541';
  IF n <> 1 THEN RAISE EXCEPTION 'CC_0523: the Indio Clerk row holds % terms, expected 1', n; END IF;

  -- a point inside Indio (City Hall, 100 Civic Center Mall) reaches both officers through the G4110 district
  SELECT count(DISTINCT o.id) INTO n
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
   WHERE gb.mtfcc = 'G4110' AND gb.geo_id = '0636448' AND d.district_type = 'LOCAL_EXEC'
     AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(-116.2156, 33.7206), 4326));
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0523: City Hall point reaches % officer offices, expected 2', n; END IF;

  RAISE NOTICE 'CC_0523 OK: D4 current = %, incoming = % on %; Clerk and Treasurer seated', v_cur, v_next, v_on;
END $$;

COMMIT;
