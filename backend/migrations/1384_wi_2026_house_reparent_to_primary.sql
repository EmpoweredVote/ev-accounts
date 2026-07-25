-- 1384_wi_2026_house_reparent_to_primary.sql
-- Fix the WI U.S. House pre-primary field: move the 31 party-affiliated candidates off the
-- Nov-3 GENERAL races and onto proper Aug-11 PARTISAN PRIMARY races, split by ballot party.
--
-- THE BUG: 1220/1221 seeded the full pre-primary qualified field onto the GENERAL election,
--   because no primary election record existed yet (source text: "provisional pre-primary
--   field, cull >= 2026-08-12"). The result is a general-election card that lists Democrats
--   and Republicans together as if they were all running against each other in November --
--   e.g. WI-1 showed Steil alongside all four Democrats. 1380 has since created the
--   'WI 2026 Partisan Primary' election, so the field now has a correct home.
--
-- NOT A DELETE: the 31 rows are RE-PARENTED with UPDATE ... SET race_id, preserving row
--   identity and any downstream references. No candidate record is destroyed. Re-running is a
--   no-op because the UPDATE only matches rows still attached to a general race.
--
-- INDEPENDENTS STAY ON THE GENERAL -- this is correct, not an oversight. Wisconsin
--   independents do not appear on the partisan primary ballot at all (Wis. Stat. § 8.20); they
--   are nominated directly to the November ballot. So Provance (CD3), Burks (CD4), Fitzgibbon
--   (CD6) and Thurow (CD6) have no primary race to move to and remain where they are.
--   CONSEQUENCE, worth knowing: CD3, CD4 and CD6 general races will show ONLY independents
--   until the party nominees are attached after 2026-08-11, so those three cards are
--   INCOMPLETE (though not wrong) in the interim. CD1/2/5/7/8 general races go empty and are
--   hidden by ElectionsView. The alternative -- deleting verified ballot-qualified candidates
--   to force every general race empty for consistency with 1383 -- was rejected as the worse
--   trade. Attach all November fields together after the primary.
--
-- ALSO FIXES TWO OMISSIONS found by re-parsing the WEC Ballot Access Report 6.9.2026 against
--   the seeded data: 1221 is missing two ballot-qualified candidates.
--     - Don Raihala (Republican, CD7) -- absent entirely; added to the CD7 Republican primary.
--     - Alexander Valiensi Kent (Independent, CD3) -- absent entirely; added to the CD3
--       general. NOTE he ALSO filed for Governor, where he was DENIED (1731 valid signatures);
--       his CD3 filing was approved. Two filings, two different outcomes -- do not let the
--       Governor denial suppress the CD3 candidacy.
--
-- BALLOT vs STORED NAMES: the WEC ballot names differ from the names 1221 stored for four
--   candidates (Lorenzo J. Santos / Lorenzo Santos, Elizabeth Anne Fitzgibbon / Elizabeth
--   Fitzgibbon, Mike Thurow / Michael Thurow, Mark Christopher Scheffler / Mark Scheffler).
--   The mapping below keys on the STORED name so the UPDATE actually matches; stored names
--   are left as-is rather than churned.
--
-- Challenged rows resolved at the WEC meetings: Provance (CD3), Fitzgibbon (CD6), Clark,
--   Hermening and Alfonso (CD7), Scheffler (CD8) were all APPROVED -- the CD7 trio and
--   Aleckson by the June 10 memo (Recommended Motion #1), the others on June 9.
--
-- ANTIPARTISAN: party is written ONLY to races.primary_party. The two new politician rows get
--   no party, and no race_candidates row carries one.
BEGIN;

-- ── 1. 16 partisan-primary races on the 8 existing WI NATIONAL_LOWER offices ──
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       v.primary_party, 1,
       'WEC Ballot Access Report 6.9.2026; ballot-qualified filers only'
FROM (VALUES
    ('5501'::text, 'Democratic'::text), ('5501', 'Republican'),
    ('5502', 'Democratic'),
    ('5503', 'Democratic'), ('5503', 'Republican'),
    ('5504', 'Democratic'), ('5504', 'Republican'),
    ('5505', 'Democratic'), ('5505', 'Republican'),
    ('5506', 'Democratic'), ('5506', 'Republican'), ('5506', 'Wisconsin Green'),
    ('5507', 'Democratic'), ('5507', 'Republican'),
    ('5508', 'Democratic'), ('5508', 'Republican')
  ) AS v(geo_id, primary_party)
JOIN essentials.elections el ON el.name = 'WI 2026 Partisan Primary'
JOIN essentials.districts d
  ON d.geo_id = v.geo_id AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices o ON o.district_id = d.id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
   WHERE r.election_id = el.id AND r.office_id = o.id
     AND coalesce(r.primary_party,'') = v.primary_party
);

-- ── 2. Don Raihala (R, CD7) -- omitted by 1221 ──
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550708, 'Don Raihala', 'Don', 'Raihala', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550708);

-- ── 3. Alexander Valiensi Kent (Ind, CD3) -- omitted by 1221 ──
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -550304, 'Alexander Valiensi Kent', 'Alexander', 'Kent', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -550304);

-- ── 4. RE-PARENT the 31 party-affiliated candidates onto their primary race ──
--    Matches only rows still sitting on a general race, so this is idempotent.
UPDATE essentials.race_candidates rc
   SET race_id = pr.id,
       source  = 'WEC Ballot Access Report 6.9.2026; placed on the Aug-11 partisan primary by migration 1384 (was seeded onto the Nov-3 general by 1221)'
FROM (VALUES
    ('5501'::text, 'Bryan Steil'::text,          'Republican'::text),
    ('5501', 'Lorenzo Santos',          'Democratic'),
    ('5501', 'Miguel Aranda',           'Democratic'),
    ('5501', 'Mitchell Berman',         'Democratic'),
    ('5501', 'Peter Burgelis',          'Democratic'),
    ('5502', 'Mark Pocan',              'Democratic'),
    ('5502', 'Douglas Alexander',       'Democratic'),
    ('5503', 'Derrick Van Orden',       'Republican'),
    ('5503', 'Emily Berge',             'Democratic'),
    ('5503', 'Rebecca Cooke',           'Democratic'),
    ('5504', 'Purnima Nath',            'Republican'),
    ('5504', 'Tim Rogers',              'Republican'),
    ('5504', 'Amy Donahue',             'Democratic'),
    ('5504', 'Gwen Moore',              'Democratic'),
    ('5505', 'Scott Fitzgerald',        'Republican'),
    ('5505', 'Andrew Beck',             'Democratic'),
    ('5506', 'Glenn Grothman',          'Republican'),
    ('5506', 'Amanda Bell',             'Democratic'),
    ('5506', 'Brad Smith',              'Democratic'),
    ('5506', 'Matthew Arndt',           'Wisconsin Green'),
    ('5507', 'Kevin Hermening',         'Republican'),
    ('5507', 'Jessi Ebben',             'Republican'),
    ('5507', 'Niina Baum',              'Republican'),
    ('5507', 'Michael Alfonso',         'Republican'),
    ('5507', 'Fred Clark',              'Democratic'),
    ('5507', 'Ginger Murray',           'Democratic'),
    ('5507', 'Chris Armstrong',         'Democratic'),
    ('5508', 'Tony Wied',               'Republican'),
    ('5508', 'Katrina deVille',         'Democratic'),
    ('5508', 'Mark Scheffler',          'Democratic'),
    ('5508', 'Rick Crosson',            'Democratic')
  ) AS v(geo_id, full_name, primary_party)
JOIN essentials.districts d
  ON d.geo_id = v.geo_id AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.elections pe ON pe.name = 'WI 2026 Partisan Primary'
JOIN essentials.races pr ON pr.election_id = pe.id AND pr.office_id = o.id
                        AND pr.primary_party = v.primary_party
-- the row must currently be on THIS district's general race
JOIN essentials.elections ge ON ge.name = 'WI 2026 Statewide General'
JOIN essentials.races gr ON gr.election_id = ge.id AND gr.office_id = o.id
                        AND gr.primary_party IS NULL
WHERE rc.race_id = gr.id
  AND lower(rc.full_name) = lower(v.full_name);

-- ── 5. Don Raihala onto the CD7 Republican primary ──
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Don Raihala', 'Don', 'Raihala', false, 'active',
       'WEC Ballot Access Report 6.9.2026 (approved); omitted by 1221, added by 1384'
FROM essentials.elections el
JOIN essentials.districts d ON d.geo_id = '5507' AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.races r ON r.election_id = el.id AND r.office_id = o.id
                       AND r.primary_party = 'Republican'
JOIN essentials.politicians p ON p.external_id = -550708
WHERE el.name = 'WI 2026 Partisan Primary'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
     WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Don Raihala')
  );

-- ── 6. Alexander Valiensi Kent onto the CD3 GENERAL (independent: bypasses the primary) ──
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Alexander Valiensi Kent', 'Alexander', 'Kent', false, 'active',
       'WEC Ballot Access Report 6.9.2026 (approved for CD3; separately DENIED for Governor); omitted by 1221, added by 1384'
FROM essentials.elections el
JOIN essentials.districts d ON d.geo_id = '5503' AND d.district_type = 'NATIONAL_LOWER'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.races r ON r.election_id = el.id AND r.office_id = o.id
                       AND r.primary_party IS NULL
JOIN essentials.politicians p ON p.external_id = -550304
WHERE el.name = 'WI 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
     WHERE rc.race_id = r.id AND lower(rc.full_name) = lower('Alexander Valiensi Kent')
  );

-- ── 7. Post-verify gate ──
DO $$
DECLARE n_prim_races int; n_prim_cands int; n_gen_cands int; n_mixed int;
BEGIN
  SELECT count(*) INTO n_prim_races FROM essentials.races r
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Partisan Primary' AND d.district_type='NATIONAL_LOWER';
  IF n_prim_races <> 16 THEN
    RAISE EXCEPTION 'CD primary races: got %, want 16', n_prim_races;
  END IF;

  SELECT count(*) INTO n_prim_cands FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Partisan Primary' AND d.district_type='NATIONAL_LOWER';
  IF n_prim_cands <> 32 THEN
    RAISE EXCEPTION 'CD primary candidates: got %, want 32 (31 re-parented + Raihala)', n_prim_cands;
  END IF;

  -- only the 5 independents may remain on CD general races
  SELECT count(*) INTO n_gen_cands FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Statewide General' AND d.district_type='NATIONAL_LOWER';
  IF n_gen_cands <> 5 THEN
    RAISE EXCEPTION 'CD general candidates: got %, want 5 (4 independents + Kent)', n_gen_cands;
  END IF;

  -- nothing party-affiliated may be left behind on a general race
  SELECT count(*) INTO n_mixed FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Statewide General' AND d.district_type='NATIONAL_LOWER'
     AND rc.full_name NOT IN ('Rustin Provance','Arthur Burks','Elizabeth Fitzgibbon',
                              'Michael Thurow','Alexander Valiensi Kent');
  IF n_mixed <> 0 THEN
    RAISE EXCEPTION '% party-affiliated candidates still on a CD general race', n_mixed;
  END IF;

  RAISE NOTICE 'WI House re-parent PASSED: 16 primary races, 32 primary candidates, 5 independents on general.';
END $$;

COMMIT;
