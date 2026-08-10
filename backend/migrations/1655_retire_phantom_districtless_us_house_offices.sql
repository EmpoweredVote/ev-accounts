-- Migration 1655: retire the 84 phantom districtless U.S. House offices (CA 74, IN 10)
--
-- ============================================================================
-- THE DEFECT
-- ============================================================================
-- The same `federal_2026_bulk_seed` pass that produced the two bogus 'U.S. Senator'
-- offices retired in migration 1654 also minted one districtless office per candidate on
-- the House side: 84 offices titled 'U.S. Representative' with district_id IS NULL,
-- sitting in the canonical U.S. House chamber c2facc31, and attached 2026 FEC filers to
-- them via office_terms with NULL term_start AND NULL term_end.
--
-- current_office_holders reads NULL/NULL as CURRENTLY SERVING, so these filers present as
-- sitting members of Congress.
--
-- ============================================================================
-- WHY THIS IS SAFE -- ALL REAL SEATS ALREADY EXIST AND ARE FILLED
-- ============================================================================
-- Every genuine seat is a DIFFERENT office that carries a district_id, and is already
-- occupied. Verified before deleting:
--
--   CA   52 real seats (district_id set), 51 filled   + 74 districtless phantoms
--   IN    9 real seats,                    9 filled   + 10 districtless phantoms
--   NY   26 real seats,                   26 filled   +  0
--   TX   38 real seats,                   37 filled   +  0
--
-- NY and TX have zero phantoms -- the defect is confined to the two bulk-seeded states.
-- Of the 84: 82 are held by `federal_2026_bulk_seed` filers and 2 (CA) are completely
-- empty with 0 terms and 0 races. NONE is held by anyone from any other source.
--
-- Pre-verified: 0 races reference any of the 84; 0 politicians.office_id points at any of
-- them; and no affected filer has an office_term anywhere else.
--
-- ⚠ THE ONE REAL RECORD, AND WHY IT IS STILL SAFE TO DROP
-- Exactly one of the 82 terms had real dates rather than NULL/NULL: Gilbert Cisneros
-- (d26d3a2f, federal_2026_bulk_seed), term_start 2025-01-03, sourced from
-- unitedstates/congress-legislators via migration 1536. Gil Cisneros is a genuine sitting
-- member -- but he is ALREADY correctly seated: the `scraped` record be2943b7
-- (bioguide C001123, party D, photo) holds CA district 31 (geo 0631) on the real office
-- e1e70721 with the SAME term_start 2025-01-03. The bulk-seed row is a duplicate person
-- record carrying a duplicate term on a phantom office, so removing it loses nothing.
-- Had it been his only term, this migration would have had to move it instead.
--
-- The POLITICIAN rows are all KEPT -- they are real FEC filers. Only the phantom offices
-- and the false occupancy they carried are removed, matching migration 1654 §3.
--
-- Not addressed here (pre-existing, unrelated to the bulk seed):
--   * CA district 14 (geo 0614, office 4cb713ee) is a real seat with NO current holder.
--   * Gil Cisneros exists as 3 person rows (be2943b7 scraped / d26d3a2f bulk / 65f08851
--     inactive) -- a merge candidate, not touched here.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Drop the false occupancy on the phantom offices.
--    Must precede the office delete (FK office_terms.office_id -> offices.id).
-- ---------------------------------------------------------------------------
DELETE FROM essentials.office_terms t
USING essentials.offices o
WHERE t.office_id = o.id
  AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  AND o.district_id IS NULL;

-- ---------------------------------------------------------------------------
-- 2. Drop the phantom offices themselves.
--    Guarded on district_id IS NULL (every real House seat has one) and on having
--    no race and no remaining term, so this cannot touch a genuine seat.
-- ---------------------------------------------------------------------------
DELETE FROM essentials.offices o
WHERE o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  AND o.district_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.races r       WHERE r.office_id = o.id)
  AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);

COMMIT;
