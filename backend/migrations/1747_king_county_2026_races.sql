-- 1747_king_county_2026_races.sql
-- The 7 King County races on the 2026 ballot, with their full filed fields.
--
-- WHY TWO SOURCES. King County offices are NONPARTISAN, and under WA law a
-- nonpartisan race with no more than twice as many candidates as positions
-- skips the primary entirely. So King County's contested races appear in the
-- county's own primary results feed, while its unopposed races appear ONLY in
-- the Secretary of State filing export. Using either source alone silently
-- drops half the county tier.
--
--   Had a primary  -> results.votewa.gov/results/public/api/elections/
--                     king-county-wa/20260804/data   (authoritative, with votes)
--   No primary     -> WA SoS candidate filings (voter.votewa.gov CandidateList
--                     e=898, CSV export), identified by races whose own name
--                     says "Metropolitan King County Council" / "Director of
--                     Elections" — unambiguous without needing a county column.
--
-- 4 of 9 council seats are up (the 2022 charter amendment moved King County to
-- even-year elections; 2026 is the first such cycle). D2 and D8 were contested
-- and had primaries; D4 and D6 drew a single filer each and had none. That
-- 4-seat total is corroborated independently by the county elections article.
--
-- PROSECUTING ATTORNEY was the one genuinely ambiguous race. Three filers in the
-- statewide export carry Seattle mailing addresses, but the office had NO
-- primary, so at most two could be King County's — and Manion shares a PO box
-- with one of the others, which is a campaign-services address, not a residence.
-- Mailing address is therefore NOT a valid county discriminator here; it happens
-- to work for Assessor only by coincidence. Resolved instead from the county
-- elections record, which lists Leesa Manion as the sole declared candidate —
-- consistent with no primary having been held. Seeded unopposed.
--
-- ASSESSOR is the cross-check that validates the pairing: the 4 filers with King
-- County addresses in the SoS export are exactly the 4 in the county's primary
-- feed.
--
-- NOT CULLED. provisional_until = 2026-08-24, matching the congressional and
-- legislative rows already on this election — deliberately past the 2026-08-21
-- state certification rather than on it. The cull gates on the CERTIFIED
-- canvass, and an unopposed race that vanishes from the ballot resolves to
-- 'won' rather than disappearing.
--
-- INCUMBENT vs POLITICIAN LINK are deliberately different things here.
-- Rebecca Saldana is the sitting State Senator for Legislative District 37 and
-- is running for County Council District 2. She is linked to her existing
-- politician row because she is the same person, but is_incumbent is FALSE
-- because she does not hold the county seat being contested. Linking on name
-- alone would be wrong in general (this database contains three different Mike
-- Rogers); each of the 6 links below is asserted by external_id, not matched.
--
-- Idempotency: NOT EXISTS throughout. race_candidates does carry a unique index
-- on (race_id, candidate_name_key(full_name)), but NOT EXISTS keeps the file
-- re-runnable without depending on index inference.

WITH e AS (SELECT '51e7a875-bff9-4e96-adcf-41736454d25d'::uuid AS id),
seed (position_name, chamber_name, office_title, cand_name, ext_id, incumbent) AS (
  VALUES
    -- Assessor (primary held: 4 candidates)
    ('King County Assessor','Assessor','Assessor','Rob Foxcurran',            NULL::bigint, false),
    ('King County Assessor','Assessor','Assessor','Dominique M Scarimbolo',   NULL, false),
    ('King County Assessor','Assessor','Assessor','Christopher Roberts',      NULL, false),
    ('King County Assessor','Assessor','Assessor','Al Dams',                  NULL, false),
    -- Council District 2 (primary held: 3 candidates; incumbent Rhonda Lewis not filed)
    ('King County Council District 2','County Council','Councilmember, District 2','Rebecca Saldaña', -5310037, false),
    ('King County Council District 2','County Council','Councilmember, District 2','Toshiko Grace Hasegawa', NULL, false),
    ('King County Council District 2','County Council','Councilmember, District 2','Miriam Mboya',    NULL, false),
    -- Council District 4 (no primary: sole filer, the incumbent)
    ('King County Council District 4','County Council','Councilmember, District 4','Jorge L. Barón',  -5303305, true),
    -- Council District 6 (no primary: sole filer, the incumbent)
    ('King County Council District 6','County Council','Councilmember, District 6','Claudia Balducci', -5303307, true),
    -- Council District 8 (primary held: 3 candidates incl. the incumbent)
    ('King County Council District 8','County Council','Councilmember, District 8','Teresa Mosqueda', -5303309, true),
    ('King County Council District 8','County Council','Councilmember, District 8','Nick Duda',       NULL, false),
    ('King County Council District 8','County Council','Councilmember, District 8','Mia Jacobson',    NULL, false),
    -- Director of Elections (no primary: sole filer, the incumbent)
    ('King County Director of Elections','Director of Elections','Director of Elections','Julie Wise', -5303313, true),
    -- Prosecuting Attorney (no primary: sole declared candidate, the incumbent)
    ('King County Prosecuting Attorney','Prosecuting Attorney','Prosecuting Attorney','Leesa Manion',  -5303311, true)
),
ins_races AS (
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  SELECT DISTINCT e.id, o.id, s.position_name, NULL, 1
  FROM seed s
  CROSS JOIN e
  JOIN essentials.governments g ON g.geo_id = '53033' AND g.type = 'County'
  JOIN essentials.chambers c ON c.government_id = g.id AND c.name = s.chamber_name
  JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = s.office_title
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.races r
    WHERE r.election_id = e.id AND r.position_name = s.position_name
  )
  RETURNING id, position_name
)
SELECT count(*) AS races_inserted FROM ins_races;

-- Candidates (separate statement so the races above are visible).
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, s.cand_name, s.incumbent, 'active', DATE '2026-08-24',
       'King County primary results feed (results.votewa.gov king-county-wa/20260804) for races that had a primary; WA SoS candidate filings (voter.votewa.gov CandidateList e=898 CSV export) for the unopposed races that skipped it, identified by explicit "Metropolitan King County Council" / "Director of Elections" race naming. Prosecuting Attorney resolved from the county elections record (sole declared candidate, no primary held) because mailing address is not a valid county discriminator — Manion shares a campaign PO box with an out-of-county filer. Pre-certification field; cull gates on the certified canvass. Retrieved 2026-08-13.'
FROM (VALUES
    ('King County Assessor','Rob Foxcurran',            NULL::bigint, false),
    ('King County Assessor','Dominique M Scarimbolo',   NULL, false),
    ('King County Assessor','Christopher Roberts',      NULL, false),
    ('King County Assessor','Al Dams',                  NULL, false),
    ('King County Council District 2','Rebecca Saldaña', -5310037, false),
    ('King County Council District 2','Toshiko Grace Hasegawa', NULL, false),
    ('King County Council District 2','Miriam Mboya',    NULL, false),
    ('King County Council District 4','Jorge L. Barón',  -5303305, true),
    ('King County Council District 6','Claudia Balducci', -5303307, true),
    ('King County Council District 8','Teresa Mosqueda', -5303309, true),
    ('King County Council District 8','Nick Duda',       NULL, false),
    ('King County Council District 8','Mia Jacobson',    NULL, false),
    ('King County Director of Elections','Julie Wise',   -5303313, true),
    ('King County Prosecuting Attorney','Leesa Manion',  -5303311, true)
  ) AS s(position_name, cand_name, ext_id, incumbent)
JOIN essentials.races r
  ON r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'
 AND r.position_name = s.position_name
LEFT JOIN essentials.politicians p ON p.external_id = s.ext_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = r.id
    AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key(s.cand_name)
);
