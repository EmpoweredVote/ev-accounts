-- CA_0215_la_city_palos_verdes_estates_2026.sql
-- LA-cities slice: Palos Verdes Estates (at large, 5 members, council-chosen mayor). Held earlier because the RR/CC
-- list 4348 shows one candidate for three seats. The City Clerk's own Candidate Nomination Status table shows three
-- qualified: Victoria Lozzi (8/12/2026), Mark Saroyen (7/27/2026), Michael Kemps (8/7/2026). The council held no
-- meeting in August 2026 (Granicus archive: Jul 28, then Sep 8), so no EC 10229 appointment was made by the 75th day
-- and the election is held (3 candidates, 3 seats). David McGowan (elected 2022) did not file -> extension to Aug 12.
--
-- ROSTER FIX (the 2025 CA Roster import is two elections stale here):
--   Jim Roos, Dawn Murdock  -- did not run in 2024; terms closed 2024-12-09 (successors seated 12-10; Res. R24-59)
--   Derek Lazzaro, Craig Quinn -- elected 2024-11-05, seated 2024-12-10 on those two offices
--   Victoria A. Lozzi       -- re-elected 2022-11-08, oath 2022-12-13; new office cloned from the council office
-- Current council = Kemps (Mayor), Lazzaro (Mayor Pro Tem), Lozzi, McGowan, Quinn (city council page, read 2026-09-23).
--
-- CONTEST: Palos Verdes Estates City Council, 3 seats, 3 candidates, incumbents Kemps + Lozzi linked. The city list
-- gives no ballot designations, so none are stored.
-- RACE goes on '2026 LA County General' (d91a20ce-557e-4615-a31b-5b2b3df2ed14); primary_party NULL; no party stored.
-- IDEMPOTENT: fixed ids; the closes only touch open terms; every insert NOT EXISTS-guarded.

BEGIN;

-- ─── P1. Close the two holders whose seats turned over in Dec 2024 ───────────────────────────────────
UPDATE essentials.office_terms t SET term_end = v.te, how_ended = v.how, source = t.source || v.src
  FROM (VALUES
    ('5bf50ffe-14e6-4f80-a4d8-7dad817831e7'::uuid, '31409962-7388-40da-bb5c-07146fb353bd'::uuid, '2024-12-09'::date, 'term_expired', ' | CA_0215: did not seek re-election in Nov 2024 (term 2020-2024); successors Lazzaro and Quinn were seated 2024-12-10 (Resolution R24-59, https://pvestates.granicus.com/AgendaViewer.php?view_id=1&clip_id=2170); term_end = the last day before that seating (office_terms ranges are inclusive). The Dec 10 2024 agenda roll call already omits Roos, so his last day may be earlier; exact date not confirmed.'),
    ('dac0ebe9-8b38-405a-8261-1a6a9e301190'::uuid, 'bde02cb9-cace-4daa-b239-89c83af2b851'::uuid, '2024-12-09'::date, 'term_expired', ' | CA_0215: did not seek re-election in Nov 2024 (term 2020-2024); successors Lazzaro and Quinn were seated 2024-12-10 (Resolution R24-59, https://pvestates.granicus.com/AgendaViewer.php?view_id=1&clip_id=2170); term_end = the last day before that seating (office_terms ranges are inclusive). She presided as Mayor until that seating.')
  ) AS v(oid, pid, te, how, src)
 WHERE t.office_id = v.oid AND t.politician_id = v.pid AND t.term_end IS NULL;
UPDATE essentials.politicians p SET is_incumbent = false WHERE p.id IN ('31409962-7388-40da-bb5c-07146fb353bd', 'bde02cb9-cace-4daa-b239-89c83af2b851')
   AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id);

-- ─── P2. Politician rows for the three sitting members the 2025 roster import left out (party never stored) ─
INSERT INTO essentials.politicians (id, first_name, last_name, full_name, party, is_active, is_incumbent, is_vacant,
                                    is_appointed, data_source, alternate_names)
SELECT v.id, v.f, v.l, v.n, NULL, true, true, false, false, v.url, v.alt FROM (VALUES
    ('456e92f8-2fac-48a3-a9e1-bf4bfa292d32'::uuid, 'Victoria', 'Lozzi', 'Victoria A. Lozzi', 'https://www.pvestates.org/government/city-council', ARRAY['Victoria Lozzi']::text[]),
    ('51dc895d-c01d-4b09-bee8-1364f102bd68'::uuid, 'Derek', 'Lazzaro', 'Derek Lazzaro', 'https://www.pvestates.org/government/city-council', '{}'::text[]),
    ('56a9a9ef-9969-4e1e-bc31-14049bd094d9'::uuid, 'Craig', 'Quinn', 'Craig Quinn', 'https://www.pvestates.org/government/city-council', '{}'::text[])
  ) AS v(id, f, l, n, url, alt) WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id);

-- ─── P3. Lozzi's seat: clone the council office onto the same whole-city LOCAL row ─────────────────
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state, representing_city, description, seats,
                                normalized_position_name, partisan_type, salary, is_appointed_position, is_vacant, vacant_since,
                                faces_retention_vote, role_canonical, voting_powers, representation_note)
SELECT v.oid, t.chamber_id, t.district_id, t.title, t.representing_state, t.representing_city, t.description, 1,
       t.normalized_position_name, t.partisan_type, t.salary, t.is_appointed_position, false, NULL,
       t.faces_retention_vote, t.role_canonical, t.voting_powers, t.representation_note
  FROM (VALUES ('712b3caa-1596-4e0a-8c9c-af96498d6e12'::uuid, 'e94b82a8-b0ef-47aa-b2c1-5d2ad0b5b1ce'::uuid)) AS v(oid, tpl) JOIN essentials.offices t ON t.id = v.tpl
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices x WHERE x.id = v.oid);

-- ─── P4. Seat Lazzaro + Quinn on the two turned-over offices, Lozzi on her new one ────────────────────
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, start_precision, how_started, source)
SELECT v.oid, v.pid, v.ts, v.prec, v.how, v.src FROM (VALUES
    ('5bf50ffe-14e6-4f80-a4d8-7dad817831e7'::uuid, '51dc895d-c01d-4b09-bee8-1364f102bd68'::uuid, '2024-12-10'::date, 'day', 'elected', 'CA_0215: elected at large 2024-11-05 (LA County RR/CC 4324: Quinn, Lazzaro, Myers for 2 seats); sworn in and seated 2024-12-10 after Resolution R24-59 certified the result (Dec 10 2024 agenda item 6a, https://pvestates.granicus.com/AgendaViewer.php?view_id=1&clip_id=2170); council page lists them.'),
    ('dac0ebe9-8b38-405a-8261-1a6a9e301190'::uuid, '56a9a9ef-9969-4e1e-bc31-14049bd094d9'::uuid, '2024-12-10'::date, 'day', 'elected', 'CA_0215: elected at large 2024-11-05 (LA County RR/CC 4324: Quinn, Lazzaro, Myers for 2 seats); sworn in and seated 2024-12-10 after Resolution R24-59 certified the result (Dec 10 2024 agenda item 6a, https://pvestates.granicus.com/AgendaViewer.php?view_id=1&clip_id=2170); council page lists them.'),
    ('712b3caa-1596-4e0a-8c9c-af96498d6e12'::uuid, '456e92f8-2fac-48a3-a9e1-bf4bfa292d32'::uuid, '2022-12-13'::date, 'day', 'elected', 'CA_0215: re-elected at large 2022-11-08 (LA County RR/CC 4300: McGowan, Myers, Kemps, Lozzi for 3 seats); oath of office for elected officials 2022-12-13 (Dec 13 2022 meeting items 2 and 7, https://pvestates.granicus.com/MinutesViewer.php?view_id=1&clip_id=1868&doc_id=5671524a-0af3-11ee-95dd-0050569183fa); the 2025 CA Roster import omitted her.')
  ) AS v(oid, pid, ts, prec, how, src)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v.oid AND t.politician_id = v.pid);
UPDATE essentials.politicians SET party = NULL WHERE party IS NOT NULL AND id IN ('2213867b-8542-45df-bf57-37463cbe548d', '27bf2707-875b-45c0-93fd-76b93c21f9b4', '456e92f8-2fac-48a3-a9e1-bf4bfa292d32', '51dc895d-c01d-4b09-bee8-1364f102bd68', '56a9a9ef-9969-4e1e-bc31-14049bd094d9');

-- ─── 0. Pre-flight: every binding target exists ───────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM (VALUES
    ('0655380', 'LOCAL', NULL, 'Palos Verdes Estates City Council')
  ) AS v(place, dtype, otitle, pos)
   WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
                      WHERE d.geo_id = v.place AND d.district_type = v.dtype AND (v.otitle IS NULL OR o.title = v.otitle));
  IF n <> 0 THEN RAISE EXCEPTION 'pre-flight: % race(s) with no office to bind to', n; END IF;
END $$;

-- ─── 1. Races ─────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid, t.office_id, t.pos, NULL, t.seats
  FROM (SELECT v.pos, v.seats,
               (SELECT o.id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
                 WHERE d.geo_id = v.place AND d.district_type = v.dtype AND (v.otitle IS NULL OR o.title = v.otitle)
                 ORDER BY o.id LIMIT 1) AS office_id
          FROM (VALUES
    ('0655380', 'LOCAL', NULL, 'Palos Verdes Estates City Council', 3)
          ) AS v(place, dtype, otitle, pos, seats)) t
 WHERE t.office_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = t.pos);

-- ─── 2. Candidates ────────────────────────────────────────────────────────────────────
INSERT INTO essentials.race_candidates
       (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, occupational_designation, source)
SELECT r.id, v.pid, v.full_name, v.first_name, v.last_name, v.inc, 'active', v.desig, v.src
  FROM (VALUES
    ('Palos Verdes Estates City Council', 'Victoria Lozzi', 'Victoria', 'Lozzi', '456e92f8-2fac-48a3-a9e1-bf4bfa292d32'::uuid, true, NULL, 'City of Palos Verdes Estates City Clerk, November 3 2026 General Municipal Election, Candidate Nomination Status (Date Qualified column: Lozzi 8/12/2026, Saroyen 7/27/2026, Kemps 8/7/2026) (https://www.pvestates.org/government/city-clerk/elections). Retrieved 2026-09-23.'),
    ('Palos Verdes Estates City Council', 'Mark Saroyen', 'Mark', 'Saroyen', NULL::uuid, false, NULL, 'City of Palos Verdes Estates City Clerk, November 3 2026 General Municipal Election, Candidate Nomination Status (Date Qualified column: Lozzi 8/12/2026, Saroyen 7/27/2026, Kemps 8/7/2026) (https://www.pvestates.org/government/city-clerk/elections). Retrieved 2026-09-23.'),
    ('Palos Verdes Estates City Council', 'Michael Kemps', 'Michael', 'Kemps', '2213867b-8542-45df-bf57-37463cbe548d'::uuid, true, NULL, 'City of Palos Verdes Estates City Clerk, November 3 2026 General Municipal Election, Candidate Nomination Status (Date Qualified column: Lozzi 8/12/2026, Saroyen 7/27/2026, Kemps 8/7/2026) (https://www.pvestates.org/government/city-clerk/elections). Retrieved 2026-09-23.')
  ) AS v(pos, full_name, first_name, last_name, pid, inc, desig, src)
  JOIN essentials.races r ON r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = v.pos
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(v.full_name));

-- ─── 3. Antipartisan: clear the stored party on every linked candidate row ──────────
UPDATE essentials.politicians SET party = NULL
 WHERE party IS NOT NULL AND id IN ('2213867b-8542-45df-bf57-37463cbe548d', '456e92f8-2fac-48a3-a9e1-bf4bfa292d32');

-- ─── 4. Post-verify gate ──────────────────────────────────────────────────────────────
DO $$
DECLARE
  pos text[] := ARRAY['Palos Verdes Estates City Council'];
  n_races int; n_cands int; n_null int; n_party int; n_badcount int; n_inc int; n_badinc int; n_extralink int; n_linked int; n_incseat int;
  n_overinc int; n_unreach int; n_pparty int; n_seat int; n_council int; n_gone int;
BEGIN
  SELECT count(*), count(*) FILTER (WHERE r.office_id IS NULL), count(*) FILTER (WHERE r.primary_party IS NOT NULL)
    INTO n_races, n_null, n_party FROM essentials.races r WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  SELECT count(*) INTO n_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  -- each race carries exactly the clerk's field, on the expected seat count
  SELECT count(*) INTO n_badcount FROM (VALUES
      ('Palos Verdes Estates City Council', 3, 3, 2)
    ) AS v(pos, seats, n_cand, n_inc)
    LEFT JOIN essentials.races r ON r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = v.pos
   WHERE r.id IS NULL OR r.seats <> v.seats
      OR (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id) <> v.n_cand
      OR (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.is_incumbent) <> v.n_inc;
  -- incumbents: linked, and holding THIS race's own seat (for a district race: that district's office)
  -- any linked candidate (incl. a sitting official running for another seat): a current holder somewhere in the city
  SELECT count(*) FILTER (WHERE rc.is_incumbent),
         count(*) FILTER (WHERE rc.is_incumbent AND rc.politician_id IS NULL),
         count(*) FILTER (WHERE rc.politician_id IS NOT NULL AND NOT EXISTS (
           SELECT 1 FROM essentials.office_current_holder och JOIN essentials.offices o2 ON o2.id = och.office_id
             JOIN essentials.districts d2 ON d2.id = o2.district_id
            WHERE och.politician_id = rc.politician_id
              AND (d2.geo_id = cm.place OR (cm.pat <> '' AND d2.geo_id LIKE cm.pat)
                   OR d2.geo_id = (SELECT d.geo_id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id WHERE o.id = r.office_id)))),
         count(*) FILTER (WHERE rc.politician_id IS NOT NULL),
         count(*) FILTER (WHERE rc.is_incumbent AND rc.politician_id IS NOT NULL AND NOT EXISTS (
           SELECT 1 FROM essentials.office_current_holder och JOIN essentials.offices o2 ON o2.id = och.office_id
             JOIN essentials.districts d2 ON d2.id = o2.district_id
            WHERE och.politician_id = rc.politician_id
              AND d2.geo_id = (SELECT d.geo_id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id WHERE o.id = r.office_id)))
    INTO n_inc, n_badinc, n_extralink, n_linked, n_incseat
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
    JOIN (VALUES
      ('Palos Verdes Estates City Council', '0655380', '')
    ) AS cm(cpos, place, pat) ON cm.cpos = r.position_name
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  SELECT count(*) INTO n_overinc FROM essentials.races r WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos)
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.is_incumbent) > r.seats;
  -- END TO END: an interior point of each race's own polygon reaches that race
  SELECT count(*) INTO n_unreach FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.geofence_boundaries me ON me.geo_id = d.geo_id AND me.mtfcc = d.mtfcc
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos)
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND (d.mtfcc IS NULL OR gb.mtfcc = d.mtfcc)
                        AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(me.geometry)));
  SELECT count(*) INTO n_pparty FROM essentials.politicians p WHERE p.party IS NOT NULL AND p.id IN (
    SELECT rc.politician_id FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
     WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos) AND rc.politician_id IS NOT NULL);
  IF n_races <> 1 THEN RAISE EXCEPTION 'expected 1 races, got %', n_races; END IF;
  IF n_cands <> 3 THEN RAISE EXCEPTION 'expected 3 candidates, got %', n_cands; END IF;
  IF n_null <> 0 OR n_party <> 0 THEN RAISE EXCEPTION 'office-less (%) or partisan (%) race', n_null, n_party; END IF;
  IF n_badcount <> 0 THEN RAISE EXCEPTION '% race(s) whose seats / candidates / incumbents differ from the clerk list', n_badcount; END IF;
  IF n_inc <> 2 THEN RAISE EXCEPTION 'expected 2 incumbents, got %', n_inc; END IF;
  IF n_badinc <> 0 THEN RAISE EXCEPTION '% incumbent(s) left unlinked', n_badinc; END IF;
  IF n_extralink <> 0 THEN RAISE EXCEPTION '% linked candidate(s) are not a current holder in their city', n_extralink; END IF;
  IF n_linked <> 2 THEN RAISE EXCEPTION 'expected 2 linked candidates, got %', n_linked; END IF;
  IF n_incseat <> 0 THEN RAISE EXCEPTION '% incumbent(s) do not hold the seat their race is for', n_incseat; END IF;
  IF n_overinc <> 0 THEN RAISE EXCEPTION '% race(s) with more incumbents than seats', n_overinc; END IF;
  IF n_unreach <> 0 THEN RAISE EXCEPTION '% race(s) not reached from inside their own city', n_unreach; END IF;
  IF n_pparty <> 0 THEN RAISE EXCEPTION '% linked candidate row(s) still carry a party', n_pparty; END IF;
  -- the council is exactly its five sitting members, each on the expected office
  SELECT count(*) INTO n_seat FROM (VALUES ('e94b82a8-b0ef-47aa-b2c1-5d2ad0b5b1ce'::uuid, '2213867b-8542-45df-bf57-37463cbe548d'::uuid), ('ad8563ea-474c-43d0-a57d-a7121ddd4aa3'::uuid, '27bf2707-875b-45c0-93fd-76b93c21f9b4'::uuid), ('712b3caa-1596-4e0a-8c9c-af96498d6e12'::uuid, '456e92f8-2fac-48a3-a9e1-bf4bfa292d32'::uuid), ('5bf50ffe-14e6-4f80-a4d8-7dad817831e7'::uuid, '51dc895d-c01d-4b09-bee8-1364f102bd68'::uuid), ('dac0ebe9-8b38-405a-8261-1a6a9e301190'::uuid, '56a9a9ef-9969-4e1e-bc31-14049bd094d9'::uuid)) AS v(oid, pid)
    JOIN essentials.office_current_holder och ON och.office_id = v.oid AND och.politician_id = v.pid;
  SELECT count(DISTINCT och.politician_id) INTO n_council FROM essentials.districts d JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id WHERE d.geo_id = '0655380' AND d.district_type IN ('LOCAL', 'LOCAL_EXEC');
  SELECT count(*) INTO n_gone FROM essentials.office_current_holder WHERE politician_id IN ('31409962-7388-40da-bb5c-07146fb353bd', 'bde02cb9-cace-4daa-b239-89c83af2b851');
  IF n_seat <> 5 THEN RAISE EXCEPTION 'PVE: % of 5 sitting members on their office', n_seat; END IF;
  IF n_council <> 5 THEN RAISE EXCEPTION 'PVE: council has % sitting members, expected 5', n_council; END IF;
  IF n_gone <> 0 THEN RAISE EXCEPTION 'PVE: % departed holder(s) still seated', n_gone; END IF;
  RAISE NOTICE 'CA_0215 applied: % races, % candidates, % incumbents linked', n_races, n_cands, n_inc;
END $$;

COMMIT;
