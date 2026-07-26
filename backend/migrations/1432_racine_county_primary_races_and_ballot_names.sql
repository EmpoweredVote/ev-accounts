-- 1432_racine_county_primary_races_and_ballot_names.sql
-- Corrections found by auditing the seeded data against an OFFICIAL SAMPLE BALLOT
-- (Village of Caledonia Ward 4, 2026 Partisan Primary, Tuesday August 11 2026).
-- Idempotent.
--
-- THE AUDIT: 32 named candidate slots appear on that ballot across the statewide, congressional
--   and legislative contests. All 32 were present in the seeded data and 30 matched exactly —
--   every race, both parties, including the unusual Wisconsin Green Secretary of State contest
--   (Pete Karas), which the ballot confirms is real. The ballot also confirms five ballot-status
--   parties (Republican, Democratic, Constitution, Libertarian, Wisconsin Green); Constitution
--   and Libertarian carry NO candidates at all — every one of their contests is write-in only —
--   so the decision to create primary races for D/R/Wisconsin Green only was correct.
--   Routing cross-checked too: the ballot puts Caledonia Ward 4 in State Senate District 21 and
--   Assembly District 63, and our geofences put Caledonia village 100% in SD 21 and 87.7% in
--   AD 63 (the rest in AD 62). Consistent.
--
-- Two real gaps came out of it, fixed here.
--
-- ═══ 1. TWO COUNTY RACES WERE MISSING ═══
-- The ballot shows Racine County Sheriff and Racine County Clerk of Circuit Court as PARTISAN
--   PRIMARY contests. Earlier work concluded county races were unavailable because Wisconsin
--   county offices are filed with the COUNTY CLERK rather than the WEC, so they are absent from
--   the WEC Ballot Access Report every other race here was sourced from. The sample ballot
--   supplies them directly:
--     Racine County Sheriff              R: Cary A. Madrigal, Henry Perez
--                                        D: Donald E. Vandervest
--     Racine County Clerk of Circuit Ct  R: Amy Vanderhoef   (D: write-in only, no candidate)
--
--   Sheriff is an OPEN SEAT: incumbent Christopher Schmaling (-5510005) is not on the ballot and
--   is retiring at term end, so he gets no candidate row — the open-seat convention 1420 used
--   for Tiffany. Amy Vanderhoef (-5510006) IS the sitting Clerk of Circuit Court seeking
--   re-election, so her existing politician row is REUSED and flagged is_incumbent.
--
--   No Democratic race is created for Clerk of Circuit Court: the contest exists on the ballot
--   but has zero candidates (write-in only), and ElectionsView hides candidate-less races, so
--   the row would be invisible. Same reasoning as the Constitution/Libertarian columns.
--
--   ALSO SETTLED, and worth recording: only Sheriff and Clerk of Circuit Court are up in 2026.
--   County Executive, County Clerk, County Treasurer, Register of Deeds and District Attorney
--   are NOT on this ballot, so they are not on the 2026 cycle. Do not go looking for races that
--   do not exist. (County Executive and the Board of Supervisors are April/spring offices,
--   already elected this year.)
--
--   County races live inside the existing statewide election records, matching the UT precedent
--   where Salt Lake County contests sit in the '2026 Utah Primary'.
--
-- ═══ 2. TWO BALLOT NAMES WERE SHORTER THAN THE BALLOT ═══
--   ballot 'Lorenzo J. Santos'      <- stored 'Lorenzo Santos'      (inherited from 1221)
--   ballot 'Dylan Ray Helmenstine'  <- stored 'Dylan Helmenstine'   (WEC report's shorter form)
--   Same people; the ballot form is what a voter sees and searches for, so race_candidates.
--   full_name is aligned to it. The politician rows keep their own names — race_candidates
--   carrying the ballot name while the politician row differs is the established convention.
--   Aliases are added so the previous spellings still match.
--
-- ANTIPARTISAN: party is written to races.primary_party only. Nothing here puts a party on a
--   candidate or politician row — note Vanderhoef appears as "(Republican)" on the ballot and
--   her politician row still keeps party NULL.
BEGIN;

-- ── 1. Align two candidate names to the official ballot ──
UPDATE essentials.race_candidates rc
   SET full_name = 'Lorenzo J. Santos', first_name = 'Lorenzo', last_name = 'Santos'
 WHERE lower(rc.full_name) = lower('Lorenzo Santos');

UPDATE essentials.race_candidates rc
   SET full_name = 'Dylan Ray Helmenstine', first_name = 'Dylan', last_name = 'Helmenstine'
 WHERE lower(rc.full_name) = lower('Dylan Helmenstine');

-- keep the prior spellings searchable
INSERT INTO essentials.politician_name_aliases (politician_id, alias, source)
SELECT p.id, v.alias, 'prior stored spelling; ballot form adopted by migration 1432 per the 2026-08-11 sample ballot'
FROM (VALUES
    (-550104::bigint, 'Lorenzo Santos'::text),
    (-559041,         'Dylan Helmenstine')
  ) AS v(external_id, alias)
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_name_aliases a
   WHERE a.politician_id = p.id AND lower(a.alias) = lower(v.alias)
);

-- ── 2. Three county primary races (Sheriff R/D, Clerk of Circuit Court R) ──
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, v.position_name, v.primary_party, 1,
       'Official sample ballot, Village of Caledonia Ward 4, 2026 Partisan Primary (2026-08-11)'
FROM (VALUES
    ('Sheriff'::text,                'Racine County Sheriff'::text,               'Republican'::text),
    ('Sheriff',                      'Racine County Sheriff',                     'Democratic'),
    ('Clerk of Circuit Court',       'Racine County Clerk of Circuit Court',      'Republican')
  ) AS v(office_title, position_name, primary_party)
JOIN essentials.elections el ON el.name = 'WI 2026 Partisan Primary'
JOIN essentials.chambers c
  ON c.name = 'Countywide Elected Officials'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US')
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = v.office_title
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
   WHERE r.election_id = el.id AND r.office_id = o.id
     AND coalesce(r.primary_party,'') = v.primary_party
);

-- ── 3. Two general-election race shells (candidate-less until after Aug 11) ──
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, v.position_name, NULL, 1,
       'Nominees attached after the 2026-08-11 primary'
FROM (VALUES
    ('Sheriff'::text,          'Racine County Sheriff'::text),
    ('Clerk of Circuit Court', 'Racine County Clerk of Circuit Court')
  ) AS v(office_title, position_name)
JOIN essentials.elections el ON el.name = 'WI 2026 Statewide General'
JOIN essentials.chambers c
  ON c.name = 'Countywide Elected Officials'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US')
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = v.office_title
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
   WHERE r.election_id = el.id AND r.office_id = o.id AND r.primary_party IS NULL
);

-- ── 4. Three new candidates (Sheriff is an open seat; Schmaling is NOT running) ──
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
    (-5528001::bigint, 'Cary A. Madrigal'::text,    'Cary'::text,   'Madrigal'::text),
    (-5528002,         'Henry Perez',               'Henry',        'Perez'),
    (-5528003,         'Donald E. Vandervest',      'Donald',       'Vandervest')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);

-- ── 5. Candidate rows. Vanderhoef REUSES her sitting-officeholder record (-5510006). ──
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active',
       'Official sample ballot, Village of Caledonia Ward 4, 2026 Partisan Primary (2026-08-11)'
FROM (VALUES
    ('Sheriff'::text,          'Republican'::text, -5528001::bigint, 'Cary A. Madrigal'::text,     'Cary'::text,   'Madrigal'::text,   false),
    ('Sheriff',                'Republican',       -5528002,         'Henry Perez',                'Henry',        'Perez',            false),
    ('Sheriff',                'Democratic',       -5528003,         'Donald E. Vandervest',       'Donald',       'Vandervest',       false),
    ('Clerk of Circuit Court', 'Republican',       -5510006,         'Amy Vanderhoef',             'Amy',          'Vanderhoef',       true)
  ) AS v(office_title, primary_party, external_id, full_name, first_name, last_name, is_incumbent)
JOIN essentials.elections el ON el.name = 'WI 2026 Partisan Primary'
JOIN essentials.chambers c
  ON c.name = 'Countywide Elected Officials'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US')
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = v.office_title
JOIN essentials.races r ON r.election_id = el.id AND r.office_id = o.id
                       AND r.primary_party = v.primary_party
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
   WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(v.full_name)
);

-- ── 6. Post-verify gate ──
DO $$
DECLARE n_prim int; n_gen int; n_cand int; n_inc int; n_old int; n_sch int;
BEGIN
  SELECT count(*) INTO n_prim FROM essentials.races r
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Partisan Primary' AND d.district_type='COUNTY';
  IF n_prim <> 3 THEN RAISE EXCEPTION 'county primary races: got %, want 3', n_prim; END IF;

  SELECT count(*) INTO n_gen FROM essentials.races r
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Statewide General' AND d.district_type='COUNTY';
  IF n_gen <> 2 THEN RAISE EXCEPTION 'county general races: got %, want 2', n_gen; END IF;

  SELECT count(*) INTO n_cand FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Partisan Primary' AND d.district_type='COUNTY';
  IF n_cand <> 4 THEN RAISE EXCEPTION 'county primary candidates: got %, want 4', n_cand; END IF;

  -- Vanderhoef is the only county incumbent on the ballot
  SELECT count(*) INTO n_inc FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Partisan Primary' AND d.district_type='COUNTY' AND rc.is_incumbent;
  IF n_inc <> 1 THEN RAISE EXCEPTION 'county incumbent candidates: got %, want 1 (Vanderhoef)', n_inc; END IF;

  -- Schmaling must NOT appear as a candidate anywhere (open seat)
  SELECT count(*) INTO n_sch FROM essentials.race_candidates
   WHERE lower(full_name) LIKE '%schmaling%';
  IF n_sch <> 0 THEN RAISE EXCEPTION 'Schmaling appears as a candidate % times; Sheriff is an open seat', n_sch; END IF;

  -- the two short spellings must be gone from race_candidates
  SELECT count(*) INTO n_old FROM essentials.race_candidates
   WHERE full_name IN ('Lorenzo Santos','Dylan Helmenstine');
  IF n_old <> 0 THEN RAISE EXCEPTION '% candidate rows still carry a pre-ballot spelling', n_old; END IF;

  RAISE NOTICE 'Ballot audit corrections PASSED: 3 county primary races, 2 general shells, 4 candidates, 2 names aligned to the ballot.';
END $$;

COMMIT;
