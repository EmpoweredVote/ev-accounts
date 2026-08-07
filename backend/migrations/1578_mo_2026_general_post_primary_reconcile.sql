-- 1578_mo_2026_general_post_primary_reconcile.sql
--
-- Reconcile Missouri's 2026 U.S. House general-election shells against the certified field after the
-- 2026-08-04 primary. 65 rows across all 8 districts.
--
--   Rollback: see the ROLLBACK block at the foot of this file.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1578_mo_2026_general_post_primary_reconcile.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 STRUCTURAL BUG FOUND, NOT FIXED HERE: MISSOURI IS SPLIT ACROSS TWO ELECTIONS
-- ---------------------------------------------------------------------------------------------------
-- Missouri's eight congressional districts do not live in one election row:
--
--     MO 2026 Statewide General ....................... 2026-11-03 ... districts 1, 7, 8
--     MO 2026 Congressional Redistricting -
--       Polygon Pending ............................... 2026-03-24 ... districts 2, 3, 4, 5, 6
--
-- The second is a placeholder created while the mid-decade map was unsettled, and it is dated
-- 2026-03-24 — a date now in the PAST. Five of Missouri's eight congressional races therefore hang off
-- an election that has, as far as any date-based query is concerned, already happened. The elections
-- view selects the nearest UPCOMING election and hides zero-candidate shells, so 46 candidates across
-- five districts are at best mis-dated and at worst invisible.
--
-- This migration does NOT move them. Re-parenting 46 rows between elections changes what the app
-- shows for five congressional districts and deserves an explicit decision, not a side effect of a
-- candidate reconcile. The 65 rows are reconciled where they sit.
--
-- ▶ FOLLOW-UP OWED: re-parent districts 2-6 onto MO 2026 Statewide General (or re-date the
--   placeholder to 2026-11-03) and retire the placeholder.
--
-- ---------------------------------------------------------------------------------------------------
-- CERTIFIED GENERAL FIELDS (ballotpedia.org per-district 2026 pages, all fetched 2026-08-07)
-- ---------------------------------------------------------------------------------------------------
--   MO-1  Wesley Bell (inc) · Paul Berry · Tom Schmitz · Xavier Phillips
--   MO-2  Ann Wagner (inc) · Frederick Wellman · Brandon Daugherty
--   MO-3  Bob Onder (inc) · Bethany Mann · Jim Higgins
--   MO-4  Mark Alford (inc) · Jordan Herrera · Thomas Holbrook
--   MO-5  Emanuel Cleaver (inc) · Rick Brattin · Randy Langkraehr · Todd Becker
--   MO-6  Josh Smead · Chris Stigall · Andy Maidment
--   MO-7  Eric Burlison (inc) · Missi Hesketh · Kevin Craig
--   MO-8  Jason Smith (inc) · Christopher Reichard · Rebecca Sharpe Lombard
--
-- ⚠️ A TRAP WORTH RECORDING. Ballotpedia district pages carry a "Withdrawn or disqualified candidates"
-- block for EVERY election cycle on the page — 2026, 2024, 2022 — and the blocks are not labelled with
-- their year in the extracted text. The MO-5 page shows "Withdrawn or disqualified candidates
-- Jordan Herrera (D)" while Herrera is simultaneously the 2026 MO-4 Democratic nominee, on the
-- certified MO-4 general field. Reading those blocks as 2026 data would have retired a nominee.
-- Nothing in this migration relies on them: every retirement below cites a dated
-- "X defeated Y ... on August 4, 2026" sentence instead.
-- ---------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------
-- PART 1 — 24 candidates CONFIRMED on the certified general field (3 per district)
-- ---------------------------------------------------------------------------------------------------
UPDATE essentials.race_candidates
   SET provisional_until = NULL,
       last_verified_at  = '2026-08-07T00:00:00Z',
       source = source || ' | re-verified 2026-08-07 against the certified post-primary'
                       || ' general-election field (ballotpedia.org per-district 2026 pages); ON the'
                       || ' field. Provisional window closed by migration 1578.'
 WHERE id IN (
   'c98448cd-b76e-472d-9b02-6c04f72f43c1','c8c9aba0-7874-4912-b2f6-a07eb625d2dd','e5679c6d-daf3-4ddf-bdb9-b131bd26028d', -- MO-1
   '3d147efd-f24c-44ce-811b-257e07888e2c','a6d2120f-1f19-4057-8cc9-4eec99b7590c','4651d39a-4984-4a94-850b-b81bf5bdf2e5', -- MO-2
   '0a4e2a13-8854-4aa9-9bac-97dec4d93c89','9d85e487-d826-4d80-90de-4dfc05b50598','6f63f44d-e228-4071-932c-3709f85355f1', -- MO-3
   '1327dfa3-011d-4a89-b381-8e30ac69f420','33f0521f-f9c0-4aa0-b52d-cf90f553371f','2d4577fe-bf33-4916-8c03-373fc3ff03c3', -- MO-4
   'c4e11a04-22de-4d3f-8854-723ef66f3e7b','912b3a6d-9418-4667-af0b-b341467ee576','ea8cbaeb-c358-4ff8-8c46-8d9c615b5e46', -- MO-5
   '13975820-14ce-462d-9ca5-e62d86318af8','b37d2c42-1155-4e8d-a935-d331262ba452','2ae7d549-2f26-46d9-8da9-eb7de2cc49e4', -- MO-6
   'fadce2d5-698d-4195-8862-cf759e1407c4','ac4b1944-11d0-4401-a51c-be23fbe55b89','27fdd4de-a1c9-44ed-83a6-53da25c90204', -- MO-7
   '76dc75a2-b2a6-4e8c-904d-cd6a5e0e07a7','b41ea11b-05bf-428c-851f-aad971f811f3','ac435b15-a923-4716-8117-c24ff2e971ff'  -- MO-8
 );

-- ---------------------------------------------------------------------------------------------------
-- PART 2 — 25 beaten in the 2026-08-04 primary, each citing its own result sentence
-- ---------------------------------------------------------------------------------------------------
UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='ballotpedia.org, Missouri''s 1st Congressional District election, 2026 — "Incumbent Wesley Bell defeated Cori Bush, Alissa Murphy, Carl Harris Sr., and Carl Henderson in the Democratic primary for U.S. House Missouri District 1 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id IN ('2cd55f76-ddf0-4be4-a640-6eba611142fa','da3a4537-22ce-43b8-9985-f5bcd1a742c7',
              'ceec4946-0b54-4917-9c30-46582adacdbf','c46c5d69-e191-411e-a1a3-c8904aca64b8');

UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='ballotpedia.org, Missouri''s 1st Congressional District election, 2026 — "Paul Berry defeated Andrew Jones Jr. in the Republican primary for U.S. House Missouri District 1 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id = '933df5bd-748b-4f19-942a-6af9545ba81b';

UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='ballotpedia.org, Missouri''s 2nd Congressional District election, 2026 — "Frederick Wellman defeated Joan VonDras and Timothy D. Bilash in the Democratic primary for U.S. House Missouri District 2 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id IN ('8f09e234-86ef-40e1-9910-7294cd7db768','e44bb84c-d8b9-4b57-b515-8c69c016c076');

UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='ballotpedia.org, Missouri''s 2nd Congressional District election, 2026 — "Incumbent Ann Wagner defeated Peter Pfeifer, Brandon Wilkinson, Matthew Grant, and Elizabeth Sparks-Holmes in the Republican primary for U.S. House Missouri District 2 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id IN ('e3584c71-f92e-4230-a296-769b9794145f','71d7f5aa-267e-4be9-b985-af8e0c0b992a',
              'd6316171-9fc6-4a9c-9e09-05b7752829ed');

UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='ballotpedia.org, Missouri''s 3rd Congressional District election, 2026 — "Bethany Mann defeated Tommy Holstein and Paul Wilson in the Democratic primary for U.S. House Missouri District 3 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id IN ('16fc9d42-af72-4572-9769-dedd215b6ee2','f3e2035c-bd22-42ad-82f1-5bbe2698c828');

UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='ballotpedia.org, Missouri''s 3rd Congressional District election, 2026 — "Incumbent Bob Onder defeated John Fraser in the Republican primary for U.S. House Missouri District 3 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id = '3a250ebc-035d-4c63-bcf4-835de7fa8d4b';

UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='ballotpedia.org, Missouri''s 4th Congressional District election, 2026 — "Incumbent Mark Alford defeated Heather Shelton and Scott Vera in the Republican primary for U.S. House Missouri District 4 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id IN ('2e1c3438-9f44-430d-a7e6-33ce0838eaa6','6bb9e297-b480-4018-bef9-b0c5aa7d9481');

UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='ballotpedia.org, Missouri''s 6th Congressional District election, 2026 — "Josh Smead defeated Matthew Levine and Scot Pondelick in the Democratic primary for U.S. House Missouri District 6 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id IN ('b5643690-cbf5-449d-92f5-7b095aff3a8a','e22b8c38-29c6-4839-abcb-00187b88ddb8');

UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='ballotpedia.org, Missouri''s 6th Congressional District election, 2026 — "Chris Stigall defeated Nathan Willett, Jim Ingram, Nathanael Schultz, and Cody Oshel in the Republican primary for U.S. House Missouri District 6 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id IN ('a11f9e18-b792-43e1-9e3d-f9614949307f','96baaaf7-700d-487e-ae6b-9e9f389c9f7c',
              '1c51dc23-23ae-4ab8-bd03-156c12c517d8','ba5402a4-ed44-43bc-a4f9-c56ea2fe6439');

UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='ballotpedia.org, Missouri''s 7th Congressional District election, 2026 — "Incumbent Eric Burlison defeated Grayson Hunt and John Casey in the Republican primary for U.S. House Missouri District 7 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id IN ('255a4a94-09de-4709-a655-f1caebd006ec','4f5024e0-608a-4175-a96f-988cec5c3917');

UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='ballotpedia.org, Missouri''s 8th Congressional District election, 2026 — "Christopher Reichard defeated Frank Barnitz in the Democratic primary for U.S. House Missouri District 8 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id = '1cff13e2-516e-47eb-bc95-0b931a25890b';

UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='ballotpedia.org, Missouri''s 8th Congressional District election, 2026 — "Incumbent Jason Smith defeated Gordon Heslop in the Republican primary for U.S. House Missouri District 8 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id = '38b0d600-f810-4c4d-ad7b-ca501f69ef03';

-- Close the provisional window on everything PART 2 just resolved.
UPDATE essentials.race_candidates
   SET provisional_until = NULL, last_verified_at = '2026-08-07T00:00:00Z'
 WHERE result = 'not_nominated' AND provisional_until IS NOT NULL
   AND race_id IN (SELECT id FROM essentials.races
                    WHERE election_id IN ('8e4e030d-2e4b-46d0-beea-2138b706513f',
                                          '25941a7b-a488-4289-9d8a-3e9ca3d275ad'));

-- ---------------------------------------------------------------------------------------------------
-- PART 3 — 16 minor-party rows unaccounted: HELD
-- ---------------------------------------------------------------------------------------------------
-- These 16 are absent from the certified general field AND from every 2026 primary result. Every one
-- was seeded as a "Declared minor-party candidate (Wikipedia 2026 MO US House / MO SOS candidate
-- filing list)".
--
-- 🔑 THEIR ABSENCE FROM THE PRIMARY RESULTS PROVES NOTHING, BY CONSTRUCTION. Missouri minor parties
-- nominate by convention, not in the August primary — so a Libertarian or Green candidate is SUPPOSED
-- to be missing from every "X defeated Y" sentence on the page. Applying the primary-loser test to
-- them would retire them for not doing something they were never eligible to do.
--
-- Their absence from the general field is weak evidence at best: Ballotpedia does list minor-party
-- nominees there (Tom Schmitz and Xavier Phillips in MO-1, Todd Becker in MO-5), but convention
-- nominations are certified late and are exactly the sort of thing a secondary source adds slowly.
-- Held for the MO SoS official November list.
--
-- ▶ FOLLOW-UP OWED: settle all 16 against the Missouri SoS certified general-election candidate list.

UPDATE essentials.race_candidates
   SET provisional_until = '2026-09-01',
       source = source || ' | re-checked 2026-08-07: absent from the certified general field and from'
                       || ' every 2026 primary result — but MO minor parties nominate by CONVENTION,'
                       || ' not in the August primary, so absence from primary results is expected and'
                       || ' carries no information. NOT retired. Window extended to 2026-09-01 by'
                       || ' migration 1578 pending the MO SoS official November candidate list.'
 WHERE id IN (
   '5cd41716-ad20-47d1-a6ac-d9e7c1fee632','347cc3a2-7dc4-4d1a-9698-f3fd973e4497','c785a714-8386-4d26-8466-debb86261aa2', -- MO-2
   '99acdb69-13f8-4fb3-9262-098ccd8fdf74',                                                                              -- MO-3
   '50ea8a95-2ab5-4a11-88b0-79efbefb9a42','22afe480-f749-4925-907a-6ebbb4fb3af7','940e82b6-c998-4f66-92e9-decfe16073fa',
   'db30b6ba-cd71-45bd-b6c1-120a3e47b2ea','8cd7a8ff-339b-43ee-88c2-939617e5bcfe','9dd5d29d-5e90-444c-a76a-efc99a5546d1', -- MO-4
   '301eebdf-23a5-410a-b268-48d946ab1bbd','6a8fab14-aae7-424c-a083-c79239e4af7f','85d39684-026b-45af-b609-53aea5b55fb0',
   'ca315d6d-79d5-4da6-805f-1f5c49ba5b06','29393f08-e294-4d78-b468-acd193a758d3',                                       -- MO-5
   '950d34be-5e4a-4afc-8aac-cff4e54e6622'                                                                               -- MO-8
 );

-- ---------------------------------------------------------------------------------------------------
-- NOT DONE HERE — two certified candidates MISSING from our shells
-- ---------------------------------------------------------------------------------------------------
--     Xavier Phillips (MO-1) · Todd Becker (MO-5)
--
-- ---------------------------------------------------------------------------------------------------
-- ROLLBACK
-- ---------------------------------------------------------------------------------------------------
--   UPDATE essentials.race_candidates
--      SET result = NULL, result_source = NULL, result_recorded_at = NULL,
--          provisional_until = '2026-08-05', last_verified_at = NULL
--    WHERE race_id IN (SELECT id FROM essentials.races
--                       WHERE election_id IN ('8e4e030d-2e4b-46d0-beea-2138b706513f',
--                                             '25941a7b-a488-4289-9d8a-3e9ca3d275ad'));
--   -- and strip the ' | re-verified…' / ' | re-checked…' suffixes from `source`.
