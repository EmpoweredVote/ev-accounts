-- Migration 1654: reunite Indiana's federal delegation with the canonical chambers,
--                 retire the phantom "U.S. Senator" offices, and link Schiff's office_id
--
-- ============================================================================
-- THE DEFECT
-- ============================================================================
-- A ballotready Indiana ingest minted a fresh government + chamber PER SEAT instead of
-- reusing the canonical ones. Six Indiana federal seats ended up on islands:
--
--   U.S. Senate     Jim Banks      office 53a9daed  chamber 6b4d9614  gov ee8432a9
--                   Todd Young     office fa8e5ddc  chamber ed0cb6a6  gov ee8432a9
--   U.S. House IN-4 Jim Baird      office 8d487bdc  chamber b180768f  gov 59ab25bb
--   U.S. House IN-7 Andre Carson   office ec985295  chamber 372ce763  gov 752d3d9e
--   U.S. House IN-8 Mark Messmer   office 19c50dbf  chamber 23fe686c  gov 21ae7187
--   U.S. House IN-9 Erin Houchin   office b343becb  chamber 0b467758  gov 85d3831b
--
-- Separately, a `federal_2026_bulk_seed` pass created TWO malformed offices titled
-- 'U.S. Senator' (b70e01a4, 240b270b) -- the ONLY offices in the U.S. Senate chamber with
-- district_id IS NULL and seats IS NULL -- and attached two 2026 FEC filers to them via
-- office_terms with NULL term_start AND NULL term_end.
--
-- current_office_holders treats NULL/NULL dates as CURRENTLY SERVING. So Indiana's two
-- U.S. Senate seats have been resolving to **Carmen Green** and **Douglas McGuire**
-- instead of Banks and Young. That is the user-visible damage.
--
-- ============================================================================
-- WHY THE FIX IS A RE-CHAMBER, NOT A MOVE OF PEOPLE
-- ============================================================================
-- Counter-intuitively the ISLAND offices are the well-formed ones. Banks/Young's offices
-- carry district 343b3268 (label 'Indiana', NATIONAL_UPPER, geo_id 18, seats 1) -- exactly
-- the shape of every other state's Senate offices (cf. Ohio -> 'Ohio', NATIONAL_UPPER,
-- geo_id 39). The four House offices likewise carry correct NATIONAL_LOWER districts
-- 1804/1807/1808/1809. So the offices only need their chamber_id corrected; their
-- districts, seats, office_terms and occupants are already right and stay untouched.
--
-- Verified there are NO duplicate district rows: exactly one row per geo_id 18 and
-- 1801-1809, each with the correct ocd_id. The canonical House chamber already holds
-- IN-1,2,3,5,6; the four islands supply 4,7,8,9. Together = Indiana's full 9-seat
-- delegation, no overlap.
--
-- Pre-verified safe to delete: 0 races reference the phantom offices; the 6 races that
-- reference the moving offices key on office_id (unchanged) so they are unaffected; the 6
-- duplicate chambers hold exactly these 6 offices and nothing else; the 5 duplicate
-- governments hold exactly those 6 chambers and 0 districts; and discovered_sources,
-- source_outlets and meetings.meetings all have 0 rows on the duplicate chambers.
--
-- ============================================================================
-- SCHIFF
-- ============================================================================
-- Adam B. Schiff resolves correctly on the site (office_terms -> 022f8c8f, the canonical
-- CA seat 2, term_start 2024-12-09), but his politicians.office_id is NULL while all 97
-- other senators have theirs set. office_terms is the ONLY source of occupancy since
-- Phase 5 dropped offices.politician_id, so office_id is a secondary column -- which is
-- exactly why migration 1653 (joined via office_id) skipped him. Setting it makes him
-- consistent and lets 1653 be re-run to pick him up.
--
-- After this migration, RE-RUN migration 1653 -- it is guarded and idempotent, and will
-- fill web_form_url for Banks/Young (currently '') and urls/web_form_url/valid_to for
-- Schiff, now that all three are reachable through the canonical chamber.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Re-chamber the two Indiana U.S. Senate offices onto the canonical chamber
-- ---------------------------------------------------------------------------
UPDATE essentials.offices
SET chamber_id = '7cbe07bc-84b8-433b-952b-540e7de18a92'
WHERE id IN ('53a9daed-6fde-403c-9c63-38769023aff1',
             'fa8e5ddc-cf1a-4aed-86c9-f7281e25e3c5');

-- ---------------------------------------------------------------------------
-- 2. Re-chamber the four Indiana U.S. House offices onto the canonical chamber
-- ---------------------------------------------------------------------------
UPDATE essentials.offices
SET chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
WHERE id IN ('8d487bdc-8180-4ba3-9909-af2a2700eae7',
             'ec985295-684a-49ad-b639-08d0b376b3d5',
             '19c50dbf-237b-4967-97d5-a5e7ffd1ca8e',
             'b343becb-af7d-4a19-a6a1-2e5df210f344');

-- ---------------------------------------------------------------------------
-- 3. Retire the bogus occupancy, then the two phantom 'U.S. Senator' offices.
--    The office_terms rows must go first (FK office_terms.office_id -> offices.id).
--    The Carmen Green / Douglas McGuire POLITICIAN rows are deliberately KEPT --
--    they are real 2026 FEC filers; only their false occupancy is removed.
-- ---------------------------------------------------------------------------
DELETE FROM essentials.office_terms
WHERE office_id IN ('b70e01a4-ba1d-4b76-b751-f605604c9d15',
                    '240b270b-9521-457d-b530-77402019abfc');

DELETE FROM essentials.offices
WHERE id IN ('b70e01a4-ba1d-4b76-b751-f605604c9d15',
             '240b270b-9521-457d-b530-77402019abfc');

-- ---------------------------------------------------------------------------
-- 4. Drop the six now-empty duplicate chambers.
--    Guarded: only deletes a chamber that has no offices left.
-- ---------------------------------------------------------------------------
DELETE FROM essentials.chambers c
WHERE c.id IN ('ed0cb6a6-30a1-47e0-9078-c86aea31e165',
               '6b4d9614-0c2f-496d-be13-db164bdba344',
               'b180768f-4714-4e1d-8759-062886e29af1',
               '372ce763-40ad-43dd-a122-0e54fce885bc',
               '23fe686c-3154-40ef-b078-46e96b6980dd',
               '0b467758-440c-4c2c-b286-3cd0a4b9ac3b')
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id);

-- ---------------------------------------------------------------------------
-- 5. Drop the five now-empty duplicate 'United States Federal Government' rows.
--    Guarded: only deletes a government with no chambers and no districts left.
--    The canonical federal government (0a6b51aa) and the SCOTUS government
--    (fd292119, a deliberate manual_scotus seed) are NOT touched.
-- ---------------------------------------------------------------------------
DELETE FROM essentials.governments g
WHERE g.id IN ('ee8432a9-7930-4086-8031-55f564698c7b',
               '21ae7187-9060-4eda-9252-44127a3058a5',
               '59ab25bb-1deb-4f9e-9b7e-7fb1e9c7fd4e',
               '752d3d9e-365b-43e4-af41-15657dfbe944',
               '85d3831b-2c3d-49d5-838f-39ad3f4ffb43')
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c  WHERE c.government_id = g.id)
  AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.government_id = g.id);

-- ---------------------------------------------------------------------------
-- 6. Sync Schiff's secondary office_id to the seat his office_terms already names.
--    Guarded on being NULL so this cannot clobber a later correction.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians
SET office_id = '022f8c8f-81f5-4e59-9465-520b9767ebb3'
WHERE id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032'
  AND office_id IS NULL;

COMMIT;
