-- CA_0201_seed_ca_ad3_2026_general.sql
-- Seed the California State Assembly District 3 race onto 'CA 2026 Statewide General'
-- (2026-11-03), reusing the existing STATE_LOWER office. Same shape as CA_0133, which seeded the
-- 24 LA-County Assembly races and stopped there -- AD-3 is one of the 56 districts it never covered.
--
--   AD 3  Dom Belza (R) · James "Jamie" Johansson (R)                   [R-vs-R, open]
--
-- OPEN SEAT, NO INCUMBENT. The seat has been vacant since 2026-06-10: James Gallagher resigned it
-- for CA-01 (CA_0198). Neither candidate is flagged incumbent. primary_party NULL (general; CA
-- top-two, here R-vs-R). Party is never stored (antipartisan) -- it appears above only to explain
-- the pairing.
--
-- BOTH CANDIDATES ARE politician_id NULL, as CA_0133 does for challengers and open-seat
-- candidates. Neither has a real politicians row. The only name matches are ten INACTIVE rows
-- whose full_name is a campaign-committee title ("BELZA FOR ASSEMBLY 2026", "JOHANSSON FOR
-- ASSEMBLY 2026", "BELZA MARYSVILLE COUNCILMAN 2020; ..."); those are not people, and linking to
-- one would render a committee name as the candidate. No politicians row is inserted here.
--
-- Ballot designations ("Agricultural Businessman/Father", "Farmer") are left out, as every other
-- CA 2026 general candidate leaves occupational_designation NULL; a later fill should do all of
-- them at once.
--
-- SOURCE: California SoS Official Certified List of Candidates, 8/27/2026, "State Assembly Member
-- District 3", p. 18 of 41 (PDF page 19). Read 2026-09-23 from the copy CA_0133's session
-- retrieved 2026-09-21 (PDF ModDate 2026-08-27, sha256 prefix 0e514ae7b14378b1).
--
-- IDEMPOTENCY: race on (election_id, position_name); candidates on (race_id, lower(full_name)).

BEGIN;

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid,
       '1f799cc8-3663-40e6-9ee1-fcca6412884a'::uuid,
       'State Assembly District 3', NULL, 1
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
    AND r.position_name='State Assembly District 3'
);

CREATE TEMP TABLE ad3_cand_seed
  (full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO ad3_cand_seed VALUES
  ('Dom Belza','Dom','Belza'),
  ('James "Jamie" Johansson','James','Johansson');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, NULL, cs.full_name, cs.first_name, cs.last_name, false, 'active',
       'California Secretary of State Official Certified List of Candidates, 8/27/2026 (elections.cdn.sos.ca.gov/statewide-elections/2026-general/cert-list-candidates.pdf), State Assembly Member District 3, p. 18 of 41. Read 2026-09-23 (CA_0201).'
FROM ad3_cand_seed cs
JOIN essentials.races r
  ON r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.position_name='State Assembly District 3'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_race uuid; v_n int; v_names text;
BEGIN
  -- exactly one AD-3 race on the general, on the AD-3 office, no party
  SELECT count(*) INTO v_n FROM essentials.races r
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND r.office_id='1f799cc8-3663-40e6-9ee1-fcca6412884a'::uuid;
  IF v_n <> 1 THEN RAISE EXCEPTION 'AD-3 general races: expected 1, got %', v_n; END IF;

  SELECT r.id INTO v_race FROM essentials.races r
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND r.office_id='1f799cc8-3663-40e6-9ee1-fcca6412884a'::uuid
     AND r.position_name='State Assembly District 3' AND r.primary_party IS NULL AND r.seats=1;
  IF v_race IS NULL THEN RAISE EXCEPTION 'AD-3 race has the wrong position_name, party or seats'; END IF;

  -- exactly the two certified candidates, neither linked nor flagged incumbent
  SELECT count(*), string_agg(rc.full_name, ' | ' ORDER BY rc.full_name) INTO v_n, v_names
    FROM essentials.race_candidates rc WHERE rc.race_id=v_race;
  IF v_n <> 2 OR v_names IS DISTINCT FROM 'Dom Belza | James "Jamie" Johansson' THEN
    RAISE EXCEPTION 'AD-3 candidates: expected Belza and Johansson, got % (%)', v_n, v_names;
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.race_candidates rc
              WHERE rc.race_id=v_race AND (rc.is_incumbent OR rc.politician_id IS NOT NULL
                                           OR rc.candidate_status <> 'active')) THEN
    RAISE EXCEPTION 'an AD-3 candidate is linked, flagged incumbent, or not active';
  END IF;

  -- the seat is open: nobody currently holds AD-3 (CA_0198)
  IF EXISTS (SELECT 1 FROM essentials.office_current_holder och
              WHERE och.office_id='1f799cc8-3663-40e6-9ee1-fcca6412884a'::uuid
                AND och.politician_id IS NOT NULL) THEN
    RAISE EXCEPTION 'AD-3 has a current holder -- the open-seat premise no longer holds';
  END IF;

  -- the race resolves to a G5220 Assembly geofence (the CA_0133 mtfcc fix)
  IF NOT EXISTS (SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
                  WHERE o.id='1f799cc8-3663-40e6-9ee1-fcca6412884a'::uuid AND d.mtfcc='G5220'
                    AND EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                                 WHERE gb.geo_id=d.geo_id AND gb.mtfcc='G5220')) THEN
    RAISE EXCEPTION 'AD-3 race is not resolvable to a G5220 Assembly geofence';
  END IF;

  -- CA_0133's 24 races are untouched; the general now carries 25 Assembly races
  SELECT count(*) INTO v_n FROM essentials.races r
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.chambers c ON c.id=o.chamber_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND c.name='California State Assembly';
  IF v_n <> 25 THEN RAISE EXCEPTION 'CA 2026 general Assembly races: expected 25, got %', v_n; END IF;
END $$;

COMMIT;
