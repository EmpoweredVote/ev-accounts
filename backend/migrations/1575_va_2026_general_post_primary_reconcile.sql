-- 1575_va_2026_general_post_primary_reconcile.sql
--
-- Reconcile the Virginia 2026 general-election shells against the field as it stands after the
-- 2026-08-04 primary and the 2026-08-04 7:00 pm independent filing deadline.
--
--   Rollback: see the ROLLBACK block at the foot of this file.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1575_va_2026_general_post_primary_reconcile.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE STALE-PROVISIONAL QUEUE IS AN UNDERCOUNT
-- ---------------------------------------------------------------------------------------------------
-- `essentials.stale_provisional_candidates` flagged 8 Virginia rows — the independents seeded with
-- `provisional_until = 2026-08-04`. Working those 8 surfaced 13 MORE broken rows the queue cannot see,
-- because they were never stamped provisional at all:
--
--     Elaine Luria defeated Nila Devanath, Bill Fleming and Patrick Mosolf on 2026-08-04 —
--     and all three are still sitting on the NOVEMBER GENERAL shell as `active`.
--
-- The queue only catches rows somebody remembered to mark. The real defect class is "person on a
-- general-election shell who did not become a nominee", and membership in that class is decided by
-- the primary result, not by whether a `provisional_until` was set. Any state whose primary has now
-- happened needs the full-shell check, not just its queue rows. 21 of Virginia's rows needed a
-- decision; the queue named 8.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY `not_nominated` AND NOT `withdrawn`
-- ---------------------------------------------------------------------------------------------------
-- `withdrawn` asserts the candidate quit. Devanath, Fleming and Mosolf did not quit — they ran and
-- were beaten. Migration 1457 had no better value available and had to write prose to disambiguate
-- ("withdrawn/disqualified, OR absent after the filing deadline"). Migration 1574 added the `result`
-- axis so that no longer has to happen; this migration extends its vocabulary with the one value the
-- August primaries actually require.
--
--   not_nominated — appeared on a general-election shell but did not become that race's nominee,
--                   whether by losing the primary or by never qualifying for the primary ballot.
--
-- NOTE: `candidate_status` is deliberately LEFT UNTOUCHED on these 13 rows. Hiding them from the
-- general-election field needs a front-end filter (`ElectionsView.jsx` currently branches only on
-- `candidate_status === 'withdrawn'`), so flipping a status here would either do nothing or paint a
-- false "Withdrawn" badge on someone who was defeated. The truth goes in `result` now; the display
-- change is a separate, deliberate commit.
--
-- ---------------------------------------------------------------------------------------------------
-- SOURCES (all fetched 2026-08-07, not inferred)
-- ---------------------------------------------------------------------------------------------------
--   * VA DOE candidate bulletin, "How to Run for Member, United States House of Representatives"
--     (2/23/2026): 2026 Election Calendar gives the GENERAL last-day-to-file as
--     "Tuesday, August 4, 2026, 7:00 pm" (Va. Code §§ 24.2-503, 24.2-507). The `provisional_until`
--     dates on the 8 independents were therefore CORRECT, not mis-stamped.
--   * ballotpedia.org per-district 2026 election pages (VA-02/03/04/05/07/09), which carry both the
--     2026-08-04 primary results and the current general-election field.
--   * FEC /candidates/search for the two identity questions below.
--
-- ⚠️ VA DOE has NOT yet published its official November 2026 candidate list — the Candidates &
-- Referendums page still shows only the August 4 primary lists. Every "confirmed" row below rests on
-- Ballotpedia's post-deadline district field, which carries its own "may not be complete" caveat.
-- That caveat is why the two ABSENT independents are held rather than retired: see below.
-- ---------------------------------------------------------------------------------------------------

-- Extend the result vocabulary (see rationale above).
ALTER TABLE essentials.race_candidates
  DROP CONSTRAINT IF EXISTS race_candidates_result_check;
ALTER TABLE essentials.race_candidates
  ADD CONSTRAINT race_candidates_result_check
  CHECK (result IS NULL OR result IN ('won', 'lost', 'advanced', 'runoff', 'withdrew', 'not_nominated'));

COMMENT ON COLUMN essentials.race_candidates.result IS
  'How the race ended for this candidate: won | lost | advanced | runoff | withdrew | not_nominated. NULL = not yet recorded, NOT lost. Orthogonal to candidate_status.';

-- ---------------------------------------------------------------------------------------------------
-- PART 1 — six independents CONFIRMED on the post-deadline general field
-- ---------------------------------------------------------------------------------------------------
-- Each was found by name on its own Ballotpedia district-election page, in the "…are running in the
-- general election … on November 3, 2026" field:
--   VA-02  Kiggans, Luria, Albritton, Makiba Gaines, Bishop Staten
--   VA-03  Scott, Rivera, James Taylor, Vasquez
--   VA-04  McClellan, Jason Brown
--   VA-05  McGuire, Perriello, Harvey, Chris Register
--   VA-09  Griffith, Powers, Michael Jackson
--
-- 🔎 IDENTITY, not just presence. Two rows needed a second source before being confirmed:
--   * `James "Zeb" Taylor` (VA-03) — Ballotpedia lists the candidate as plain "James Taylor" and its
--     bio page never uses "Zeb". FEC /candidates/search returns EXACTLY ONE Taylor filed in VA-03 for
--     2026: TAYLOR, JAMES L (H2VA03096, IND). One filing, one candidacy — same person. The stored
--     name form keeps its nickname; only the ballot presence is asserted here.
--   * `Jason Brown II` (VA-04) — Ballotpedia lists "Jason Brown". Same seat, same party posture, no
--     competing Brown in the district field.

UPDATE essentials.race_candidates
   SET provisional_until = NULL,
       last_verified_at  = '2026-08-07T00:00:00Z',
       source = source || ' | re-verified 2026-08-07 against the post-deadline general-election field'
                       || ' (ballotpedia.org per-district 2026 pages); VA general filing deadline'
                       || ' 2026-08-04 7:00pm has passed and this candidate is ON the field.'
                       || ' Provisional window closed by migration 1575.'
 WHERE id IN (
   '6e7c7e28-b63a-4bfe-86f1-4948e07014bd',  -- Makiba Gaines        VA-02
   '5a09b563-8a40-4774-9a72-d3899f15c305',  -- Bishop Staten        VA-02
   'efc8179c-6cfd-46e7-8bb5-28453a3a6df0',  -- James "Zeb" Taylor   VA-03  (FEC H2VA03096)
   '6bf39e15-ec62-4a85-8b6f-6fcc3ee49c99',  -- Jason Brown II       VA-04
   '4028986c-d9af-4be2-a08f-85b1e65ff9df',  -- Chris Register       VA-05
   '7e805b22-547e-4c58-9e2f-c94480e5487c'   -- Michael Jackson      VA-09
 );

-- ---------------------------------------------------------------------------------------------------
-- PART 2 — two independents ABSENT from the field: HELD, deliberately not retired
-- ---------------------------------------------------------------------------------------------------
-- Andre Kersey (VA-04) and Randall Terry (VA-07) do not appear anywhere on their district pages —
-- the string "Kersey" and the string "Terry" each return zero hits on the respective page. Both are
-- nonetheless real, federally-filed candidacies:
--     KERSEY, ANDRE ODELL — VA-04, committee "KERSEY FOR CONGRESS"
--     TERRY, RANDALL      — VA-07, IND, H6VA07312, last filing 2026-06-29
--
-- 🔴 AN FEC FILING IS NOT BALLOT ACCESS, and ABSENCE IS NOT EVIDENCE. Virginia independents need
-- 1,000 valid signatures by the deadline; failing that is common and would explain both absences.
-- But the only list that settles it — VA DOE's official November candidate list — is not published,
-- and Ballotpedia's own field notice says it "may not be complete". Retiring a real candidate off a
-- ballot he qualified for is a worse error than carrying a flagged provisional row for three more
-- weeks. So the re-verification date is pushed, and the finding is written into the source note for
-- whoever picks it up.
--
-- ▶ FOLLOW-UP OWED: re-check both against elections.virginia.gov once the November list posts.

UPDATE essentials.race_candidates
   SET provisional_until = '2026-09-01',
       source = source || ' | re-checked 2026-08-07 after the 2026-08-04 filing deadline: NOT present'
                       || ' on the Ballotpedia district general-election field, but federally filed'
                       || ' with the FEC and VA DOE has not yet published its official November'
                       || ' candidate list. NOT retired on absence alone — provisional window'
                       || ' extended to 2026-09-01 by migration 1575 pending the official list.'
 WHERE id IN (
   '3b60a06b-4410-4150-a9c5-b40538361f25',  -- Andre Kersey   VA-04
   '44005981-fcc5-49f9-8a5c-dfd94cdb68d2'   -- Randall Terry  VA-07
 );

-- ---------------------------------------------------------------------------------------------------
-- PART 3 — thirteen non-nominees still sitting on the November general shells
-- ---------------------------------------------------------------------------------------------------
-- Ten lost the 2026-08-04 primary outright; three never made the primary ballot. None was flagged
-- provisional, so none appeared in the stale queue.

-- Lost the 2026-08-04 primary.
UPDATE essentials.race_candidates
   SET result = 'not_nominated',
       result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Virginia''s 2nd Congressional District election, 2026 — '
                    || '"Elaine Luria defeated Nila Devanath, Bill Fleming, and Patrick Mosolf in the '
                    || 'Democratic primary for U.S. House Virginia District 2 on August 4, 2026." '
                    || '(fetched 2026-08-07)'
 WHERE id IN (
   '14309d71-e4e0-4d7f-b5a6-b5da67d802a0',  -- Nila Devanath
   '65ff9632-8080-40e8-a180-17accbbdd217',  -- Bill Fleming
   'cee1f524-accf-4519-bacf-293f7cc689b2'   -- Patrick Mosolf
 );

UPDATE essentials.race_candidates
   SET result = 'not_nominated',
       result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Virginia''s 5th Congressional District election, 2026 — '
                    || '"Tom Perriello defeated Suzanne Krzyzanowski and Robert Tracinski in the '
                    || 'Democratic primary for U.S. House Virginia District 5 on August 4, 2026." '
                    || '(fetched 2026-08-07)'
 WHERE id IN (
   '6bfa8149-196a-41c2-a1d3-09ccae6e629b',  -- Suzanne Krzyzanowski
   'ec3d739a-f25f-46e1-919b-4772c5b97448'   -- Robert Tracinski
 );

UPDATE essentials.race_candidates
   SET result = 'not_nominated',
       result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Virginia''s 5th Congressional District election, 2026 — '
                    || '"Incumbent John McGuire defeated Melanie Lucero in the Republican primary for '
                    || 'U.S. House Virginia District 5 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id = '5ab63c97-19f1-4568-ad74-c802b859f304';  -- Melanie Lucero

UPDATE essentials.race_candidates
   SET result = 'not_nominated',
       result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Virginia''s 7th Congressional District election, 2026 — '
                    || '"Douglas Ollivant defeated Philip Harding and Rick Smithers in the Republican '
                    || 'primary for U.S. House Virginia District 7 on August 4, 2026." '
                    || '(fetched 2026-08-07; stored name form "Ricky Smithers")'
 WHERE id IN (
   '73883ba2-a020-4d46-8bc6-913af40d2134',  -- Philip Harding
   '4741f1ae-418e-4cb3-9d8d-030e253a420b'   -- Ricky Smithers
 );

UPDATE essentials.race_candidates
   SET result = 'not_nominated',
       result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Virginia''s 9th Congressional District election, 2026 — '
                    || '"Joy Powers defeated Adam Murphy and Douglas Crockett in the Democratic '
                    || 'primary for U.S. House Virginia District 9 on August 4, 2026." '
                    || '(fetched 2026-08-07)'
 WHERE id IN (
   '8b238106-5eb2-439a-b51c-81a4f562c8ec',  -- Adam Murphy
   '93d5f715-4888-45f4-b00a-77cc4ef4dba3'   -- Douglas Crockett
 );

-- Never made the primary ballot ("Did not make the ballot" on the Ballotpedia primary field).
UPDATE essentials.race_candidates
   SET result = 'not_nominated',
       result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, United States House of Representatives elections in '
                    || 'Virginia, 2026 — listed under "Did not make the ballot" for the 2026 primary '
                    || 'field in this district (fetched 2026-08-07)'
 WHERE id IN (
   '6f6e68d3-ceb7-4f66-9f71-f5efda73b064',  -- Bob Good      VA-05 R
   '0e47f9f4-4f67-4473-8a7f-3c095685c5b5',  -- Brandi Hall   VA-09 D
   '493d2fec-c50b-42f6-ba1d-91a3badcb40e'   -- Brandon Cook  VA-09 R
 );

-- ---------------------------------------------------------------------------------------------------
-- NOT DONE HERE — four certified independents are MISSING from our shells
-- ---------------------------------------------------------------------------------------------------
-- The district fields list four independents with no row in `essentials.race_candidates`:
--     DeVinche Albritton (VA-02) · Dawn Vasquez (VA-03) · Cooke Harvey (VA-05) · Alaha Ahrar (VA-07)
-- Seeding new candidates is additive work with its own sourcing bar, not part of a reconcile, so it
-- is recorded rather than done. A cull that only removes is a cull that quietly biases the field.
--
-- ---------------------------------------------------------------------------------------------------
-- ROLLBACK
-- ---------------------------------------------------------------------------------------------------
--   UPDATE essentials.race_candidates
--      SET result = NULL, result_source = NULL, result_recorded_at = NULL
--    WHERE id IN ('14309d71-e4e0-4d7f-b5a6-b5da67d802a0','65ff9632-8080-40e8-a180-17accbbdd217',
--                 'cee1f524-accf-4519-bacf-293f7cc689b2','6bfa8149-196a-41c2-a1d3-09ccae6e629b',
--                 'ec3d739a-f25f-46e1-919b-4772c5b97448','5ab63c97-19f1-4568-ad74-c802b859f304',
--                 '73883ba2-a020-4d46-8bc6-913af40d2134','4741f1ae-418e-4cb3-9d8d-030e253a420b',
--                 '8b238106-5eb2-439a-b51c-81a4f562c8ec','93d5f715-4888-45f4-b00a-77cc4ef4dba3',
--                 '6f6e68d3-ceb7-4f66-9f71-f5efda73b064','0e47f9f4-4f67-4473-8a7f-3c095685c5b5',
--                 '493d2fec-c50b-42f6-ba1d-91a3badcb40e');
--   -- Part 1: restore provisional_until = '2026-08-04', last_verified_at = NULL
--   -- Part 2: restore provisional_until = '2026-08-04'
--   -- and strip the ' | re-verified…' / ' | re-checked…' suffixes from `source` in both.
