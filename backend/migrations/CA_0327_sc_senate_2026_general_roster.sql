-- CA_0327 — SC U.S. Senate (Class II) 2026-11-03 general: match the race to the State Election
-- Commission's candidate list. Lindsey Graham -> withdrawn (deceased after primary); add Darline Graham.
-- Refs #1089 (filed by the ev-qa bot). Follows CA_0325, which ended Lindsey Graham's term (died 2026-07-11) and seated
-- Darline Graham (2026-07-14 .. 2027-01-03).
--
-- ===========================================================================================
-- SOURCE (the only source for the list)
-- ===========================================================================================
--   South Carolina State Election Commission, VREMS Candidate Search, "11/03/2026 Statewide General
--   Election" (electionId 22596), Office = U.S. Senate:
--     https://vrems.scvotes.sc.gov/Candidate/CandidateSearch?electionId=22596
--   Read 2026-10-26 15:55Z. Fourteen U.S. Senate filings. Status 'Active' (the general ballot):
--     Annie Andrews · Darline Graham · Mark Hackett · Kasie Whitener
--   Lindsey Graham: 'Deceased After Primary'. The other nine are primary or convention filings
--   ('Defeated In Primary', 'Defeated At Convention', 'Withdrew Before Primary') — none is on our race,
--   and none belongs on a general roster.
--
-- ===========================================================================================
-- BEFORE (prod, 2026-10-26): race 29b5764f-2953-4274-9c46-9be584602037 ("U.S. Senate South Carolina",
-- primary_party '', office af90499c = the Class II seat) holds four rows, all 'active':
--   Lindsey Graham (is_incumbent true) · Annie Andrews · Kasie Whitener · Mark Hackett
-- So the list disagrees with us only on the two Grahams.
-- ===========================================================================================
--
-- 1. Lindsey Graham's row (71bafe26): candidate_status 'active' -> 'withdrawn', is_incumbent -> false.
--    'withdrawn' is the only word the CHECK has for "no longer on the ballot" (vocabulary: active,
--    withdrawn, filed); Roth's Idaho row (CA_0222 step 4) and Platner's Maine row are the precedent.
--    result stays NULL: the result vocabulary has no word for a death, and he was not defeated.
--    is_incumbent false because he no longer holds the seat (CA_0325).
-- 2. Darline Graham (politician a82fec1e): new row, 'active', is_incumbent true — she holds the seat
--    now (CA_0325's term). The guard below refuses to run unless that term is current.
--
-- NOT CHANGED: politicians.is_active for either Graham (ruling 2026-09-24: closed candidacies stay
-- active); party (antipartisan — never stored); the race; elections; office_terms (CA_0325's job).
--
-- No answers are deleted or rewritten by this migration, so no @context-decision declaration is required.
--
-- IDEMPOTENT: the UPDATE is guarded on the row still reading 'active'; the INSERT on NOT EXISTS.
-- Dry run: the body wrapped BEGIN; ... ROLLBACK; against prod, applied twice in one transaction, then
-- the rollback confirmed by re-reading the rows.
-- ROLLBACK (once applied): DELETE the race_candidates row whose source ends '(CA_0327)'; set row
-- 71bafe26 back to candidate_status 'active', is_incumbent true.

BEGIN;

-- ---------------------------------------------------------------------------
-- PRE: the race is the one we think it is, and CA_0325 has seated Darline Graham.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.races r
                   JOIN essentials.elections e ON e.id = r.election_id
                  WHERE r.id = '29b5764f-2953-4274-9c46-9be584602037'
                    AND r.position_name = 'U.S. Senate South Carolina'
                    AND r.office_id = 'af90499c-0219-4a7a-bd89-fb9ac20392ae'
                    AND e.election_date = '2026-11-03') THEN
    RAISE EXCEPTION 'PRE: race 29b5764f is not the SC U.S. Senate 2026-11-03 general on office af90499c';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder
                  WHERE office_id = 'af90499c-0219-4a7a-bd89-fb9ac20392ae'
                    AND politician_id = 'a82fec1e-3b94-4f7f-8931-fafb9787def3') THEN
    RAISE EXCEPTION 'PRE: Darline Graham does not hold office af90499c — apply CA_0325 first';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Lindsey Graham: off the ballot.
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates
   SET candidate_status = 'withdrawn',
       is_incumbent     = false,
       source           = 'SC State Election Commission VREMS Candidate Search, electionId 22596, U.S. Senate: '
                          || 'Lindsey Graham status "Deceased After Primary" (read 2026-10-26) (CA_0327)',
       last_verified_at = now(),
       updated_at       = now()
 WHERE id = '71bafe26-3bb2-482c-b8db-ef7ead121365'
   AND race_id = '29b5764f-2953-4274-9c46-9be584602037'
   AND politician_id = '20aa1064-bbe7-484c-b779-28d99e92e608'
   AND candidate_status = 'active';

-- ---------------------------------------------------------------------------
-- 2. Darline Graham: on the ballot.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent,
                                        candidate_status, source, last_verified_at)
SELECT '29b5764f-2953-4274-9c46-9be584602037', p.id, 'Darline Graham', 'Darline', 'Graham', true, 'active',
       'SC State Election Commission VREMS Candidate Search, https://vrems.scvotes.sc.gov/Candidate/CandidateSearch?electionId=22596, '
       || 'U.S. Senate: Darline Graham status "Active" (read 2026-10-26) (CA_0327)',
       now()
  FROM essentials.politicians p
 WHERE p.id = 'a82fec1e-3b94-4f7f-8931-fafb9787def3'
   AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                    WHERE rc.race_id = '29b5764f-2953-4274-9c46-9be584602037' AND rc.politician_id = p.id);

-- ---------------------------------------------------------------------------
-- VERIFY — THE POINT: the race's live candidates are exactly the certified four.
-- ---------------------------------------------------------------------------
DO $$
DECLARE got text;
BEGIN
  SELECT string_agg(rc.full_name, ' · ' ORDER BY rc.last_name, rc.first_name) INTO got
    FROM essentials.race_candidates rc
   WHERE rc.race_id = '29b5764f-2953-4274-9c46-9be584602037'
     AND essentials.is_live_candidate(rc.candidate_status, rc.result);
  IF got IS DISTINCT FROM 'Annie Andrews · Darline Graham · Mark Hackett · Kasie Whitener' THEN
    RAISE EXCEPTION 'POST: live field is "%"', got;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates
                  WHERE id = '71bafe26-3bb2-482c-b8db-ef7ead121365'
                    AND candidate_status = 'withdrawn' AND is_incumbent = false AND result IS NULL) THEN
    RAISE EXCEPTION 'POST: Lindsey Graham row not withdrawn';
  END IF;

  IF (SELECT count(*) FROM essentials.race_candidates
       WHERE race_id = '29b5764f-2953-4274-9c46-9be584602037' AND is_incumbent) <> 1 THEN
    RAISE EXCEPTION 'POST: expected exactly one incumbent row (Darline Graham)';
  END IF;

  IF (SELECT count(*) FROM essentials.race_candidates WHERE race_id = '29b5764f-2953-4274-9c46-9be584602037') <> 5 THEN
    RAISE EXCEPTION 'POST: expected 5 rows on the race (4 live + Lindsey Graham withdrawn)';
  END IF;
END $$;

COMMIT;
