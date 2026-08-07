-- 1576_ks_2026_general_post_primary_reconcile.sql
--
-- Reconcile the Kansas 2026 U.S. House general-election shells against the field as it stands after
-- the 2026-08-04 primary. All 26 rows on the shell were seeded pre-primary with the note
-- "provisional pre-primary field, cull >= 2026-08-05"; that date has passed.
--
--   Rollback: see the ROLLBACK block at the foot of this file.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1576_ks_2026_general_post_primary_reconcile.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHAT THE SHELL LOOKED LIKE
-- ---------------------------------------------------------------------------------------------------
-- Kansas is the clean version of the defect Virginia showed in migration 1575: the whole general
-- shell was the pre-primary field. District 4 listed ELEVEN candidates for a seat that has three on
-- the ballot. A voter opening KS-04 saw eight people who will not appear on their ballot.
--
--   Certified general fields (ballotpedia.org per-district 2026 pages, fetched 2026-08-07):
--     KS-01  Tracey Mann (inc) · Lauren Reinhold · Steven Jacob
--     KS-02  Derek Schmidt (inc) · Don Coover · John Hauer
--     KS-03  Sharice Davids (inc) · Eric Jenkins · Steve Hohe
--     KS-04  Ron Estes (inc) · Katy Tyndell · Drew Cranmer
--
-- ---------------------------------------------------------------------------------------------------
-- ONE VALUE, ONE MEANING: WHY EVERYTHING NON-QUALIFYING IS `not_nominated`
-- ---------------------------------------------------------------------------------------------------
-- These 14 rows failed to reach the ballot three different ways — beaten in the primary, withdrawn
-- before it, disqualified. Ballotpedia itself cannot always separate the last two: its heading is the
-- lumped "Withdrawn or disqualified candidates". Rather than guess which, every row gets the value
-- that is true under all readings — `not_nominated`, "did not become this race's nominee" — and the
-- specific reason goes in `result_source` where it can be read and checked.
--
-- 🔑 The alternative — picking `withdrew` whenever a source happened to use that word — would make
-- the column's meaning depend on which source got fetched, not on what happened. A vocabulary that
-- encodes source-phrasing instead of fact is worse than a coarser one that encodes fact.
-- ---------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------
-- PART 1 — ten candidates CONFIRMED on the certified general field
-- ---------------------------------------------------------------------------------------------------
UPDATE essentials.race_candidates
   SET provisional_until = NULL,
       last_verified_at  = '2026-08-07T00:00:00Z',
       source = source || ' | re-verified 2026-08-07 against the certified post-primary general-election'
                       || ' field (ballotpedia.org per-district 2026 pages); ON the field.'
                       || ' Provisional window closed by migration 1576.'
 WHERE id IN (
   '3e18bc7f-c550-4d07-bfa5-62d742993b7f',  -- Tracey Mann      KS-01 (inc)
   '5662afde-135d-4be6-83d2-12f3455157c4',  -- Lauren Reinhold  KS-01
   '37714128-27e3-4762-a8b1-3e47f89f3433',  -- Steven Jacob     KS-01
   'facd2505-65c7-4c6d-a59e-4d1461404602',  -- Derek Schmidt    KS-02 (inc)
   'e60f1378-905a-4eaa-a5ca-0eab80d977a8',  -- Don Coover       KS-02  (advanced from D primary)
   '1ff2b0d2-0e2c-4377-ad10-1cf79652c195',  -- Eric Jenkins     KS-03
   '8c349c87-6bc2-4737-a441-915cd4f73edf',  -- Sharice Davids   KS-03 (inc)
   '025a9ecc-5db0-465c-8b42-5e0aea994d41',  -- Ron Estes        KS-04 (inc)
   '651a06ca-318d-4c40-9f16-ddff0cc593cc',  -- Katy Tyndell     KS-04
   'b8eecbc8-18cd-456e-9cda-d67cbf652a28'   -- Drew Cranmer     KS-04
 );

-- ---------------------------------------------------------------------------------------------------
-- PART 2 — nine beaten in the 2026-08-04 primary
-- ---------------------------------------------------------------------------------------------------
UPDATE essentials.race_candidates
   SET result = 'not_nominated', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Kansas'' 1st Congressional District election, 2026 — '
                    || '"Lauren Reinhold defeated Colin McRoberts in the Democratic primary for '
                    || 'U.S. House Kansas District 1 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id = 'fd101416-447d-4b84-a111-b85c841818ad';  -- Colin McRoberts

UPDATE essentials.race_candidates
   SET result = 'not_nominated', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Kansas'' 1st Congressional District election, 2026 — '
                    || '"Incumbent Tracey Mann defeated Craig Musser in the Republican primary for '
                    || 'U.S. House Kansas District 1 on August 4, 2026." (fetched 2026-08-07). NOTE: '
                    || 'the seeded source note called this a "minor-party/independent filing"; the '
                    || 'primary result shows he ran in the Republican primary.'
 WHERE id = '29aba8fc-5793-4e7a-88cf-197282893f62';  -- Craig Musser

UPDATE essentials.race_candidates
   SET result = 'not_nominated', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Kansas'' 2nd Congressional District election, 2026 — '
                    || '"Incumbent Derek Schmidt defeated Chad Young in the Republican primary for '
                    || 'U.S. House Kansas District 2 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id = 'a33971e2-8956-4a10-9f15-08278b3aa6f1';  -- Chad Young

UPDATE essentials.race_candidates
   SET result = 'not_nominated', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Kansas'' 3rd Congressional District election, 2026 — '
                    || '"Incumbent Sharice Davids defeated Sarah Preu in the Democratic primary for '
                    || 'U.S. House Kansas District 3 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id = 'f0d9fbc0-f6f4-4751-be9f-18be759ae585';  -- Sarah Preu

UPDATE essentials.race_candidates
   SET result = 'not_nominated', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Kansas'' 3rd Congressional District election, 2026 — '
                    || '"Eric Jenkins defeated Chase LaPorte in the Republican primary for '
                    || 'U.S. House Kansas District 3 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id = 'd259b626-76a7-4b08-896d-5cec08991ca7';  -- Chase LaPorte

UPDATE essentials.race_candidates
   SET result = 'not_nominated', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Kansas'' 4th Congressional District election, 2026 — '
                    || '"Katy Tyndell defeated Chris Carmichael, Ryan Gilbert, and Cole Epley '
                    || '(Unofficially withdrew) in the Democratic primary for U.S. House Kansas '
                    || 'District 4 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id IN (
   'f1dfc34f-52ee-45ba-81e6-d50464606a86',  -- Chris Carmichael
   '6e8aeb0d-ebea-47ac-a128-aaa79137a0b1',  -- Ryan Gilbert
   '4068c753-f29e-494c-9e97-fddfc36ffa5c'   -- Cole Epley (unofficially withdrew)
 );

UPDATE essentials.race_candidates
   SET result = 'not_nominated', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Kansas'' 4th Congressional District election, 2026 — '
                    || '"Incumbent Ron Estes defeated Frank McCollum in the Republican primary for '
                    || 'U.S. House Kansas District 4 on August 4, 2026." (fetched 2026-08-07)'
 WHERE id = '7bc52286-80d2-4b7e-ba64-20fbbe1c445e';  -- Frank McCollum

-- ---------------------------------------------------------------------------------------------------
-- PART 3 — five withdrawn or disqualified before the primary
-- ---------------------------------------------------------------------------------------------------
UPDATE essentials.race_candidates
   SET result = 'not_nominated', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Kansas'' 2nd Congressional District election, 2026 — listed '
                    || 'under "Withdrawn or disqualified candidates": Braeden Curwick (D). '
                    || '(fetched 2026-08-07)'
 WHERE id = '412c3ab7-9a60-4f10-bdf2-daf53b049200';  -- Braeden Curwick

UPDATE essentials.race_candidates
   SET result = 'not_nominated', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Kansas'' 3rd Congressional District election, 2026 — listed '
                    || 'under "Withdrawn or disqualified candidates": Blake Stanley (R). '
                    || '(fetched 2026-08-07)'
 WHERE id = 'd28bf15f-c870-4790-af0c-0b96d2a38339';  -- Blake Stanley

UPDATE essentials.race_candidates
   SET result = 'not_nominated', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'en.wikipedia.org, 2026 United States House of Representatives elections in '
                    || 'Kansas — "Gavin Solomon, businessman from New York" listed under the '
                    || 'Republican primary "Withdrawn" section for District 3 (fetched 2026-08-07). '
                    || 'Absent from every Ballotpedia Kansas 2026 page.'
 WHERE id = '621c812f-7c4c-428d-af2a-e23c5f55c7d9';  -- Gavin Solomon

UPDATE essentials.race_candidates
   SET result = 'not_nominated', result_recorded_at = '2026-08-07T00:00:00Z',
       result_source = 'ballotpedia.org, Kansas'' 4th Congressional District election, 2026 — listed '
                    || 'under "Withdrawn or disqualified candidates": Jordan Mitchell (D), '
                    || 'Daniel Schneider (D). (fetched 2026-08-07)'
 WHERE id IN (
   '57aac4af-1ef9-42e8-9133-bac4839402ac',  -- Jordan Mitchell
   'dae1c23e-7c92-44b8-87c0-bf70998e4e52'   -- Daniel Schneider
 );

-- ---------------------------------------------------------------------------------------------------
-- PART 4 — two unaccounted: HELD, not retired
-- ---------------------------------------------------------------------------------------------------
-- Michael Gaynor and Paul Catanese (both KS-04) return ZERO hits across every Kansas 2026 Ballotpedia
-- page fetched — not on the general field, not in a primary result, not in a withdrawn/disqualified
-- list — and Wikipedia's Kansas article does not name them either. Our own seed sourced them from
-- "KS SoS 2026 federal filings" and a "minor-party/independent filing".
--
-- 🔴 Same rule as Virginia's Kersey and Terry in migration 1575: a name that is missing from a
-- secondary source is not a name that has been disproved. Two sources failing to mention someone is
-- the expected signature of a low-profile minor-party filing, which is exactly what the seed note
-- claims these are. Retiring them needs the Kansas SoS official general-election candidate list.
--
-- ▶ FOLLOW-UP OWED: settle both against votekansas.gov / the KS SoS official November list.

UPDATE essentials.race_candidates
   SET provisional_until = '2026-09-01',
       source = source || ' | re-checked 2026-08-07: absent from the certified general field AND from'
                       || ' every primary-result and withdrawn/disqualified list on ballotpedia.org'
                       || ' and en.wikipedia.org for Kansas 2026. NOT retired on absence alone —'
                       || ' provisional window extended to 2026-09-01 by migration 1576 pending the'
                       || ' KS SoS official November candidate list.'
 WHERE id IN (
   '42aef057-2dd9-4d18-80f5-93f7d1148460',  -- Michael Gaynor   KS-04
   '5c6aea64-3614-43af-9b8c-6bfd17781bda'   -- Paul Catanese    KS-04
 );

-- ---------------------------------------------------------------------------------------------------
-- PART 5 — close the provisional window on every row now RESOLVED
-- ---------------------------------------------------------------------------------------------------
-- 🔑 Recording a `result` answers the provisional question; it does not by itself clear the flag.
-- Without this step the 14 `not_nominated` rows keep `provisional_until = 2026-08-05` and go on
-- reporting themselves as overdue in `essentials.stale_provisional_candidates` forever — a queue that
-- never drains, listing work that is already done. Only the two genuinely-unresolved rows in PART 4
-- should still be in it.

UPDATE essentials.race_candidates
   SET provisional_until = NULL,
       last_verified_at  = '2026-08-07T00:00:00Z'
 WHERE race_id IN (SELECT id FROM essentials.races
                    WHERE election_id = '5aec8ba8-8f04-4368-9529-130ea489a4d3')
   AND result = 'not_nominated'
   AND provisional_until IS NOT NULL;

-- ---------------------------------------------------------------------------------------------------
-- NOT DONE HERE — two certified candidates are MISSING from our shells
-- ---------------------------------------------------------------------------------------------------
--     John Hauer (KS-02) · Steve Hohe (KS-03)
-- Both are on the certified general field with no row in `essentials.race_candidates`. Recorded, not
-- seeded — same reasoning as migration 1575.
--
-- ---------------------------------------------------------------------------------------------------
-- ROLLBACK
-- ---------------------------------------------------------------------------------------------------
--   UPDATE essentials.race_candidates
--      SET result = NULL, result_source = NULL, result_recorded_at = NULL
--    WHERE race_id IN (SELECT id FROM essentials.races
--                       WHERE election_id = '5aec8ba8-8f04-4368-9529-130ea489a4d3');
--   UPDATE essentials.race_candidates SET provisional_until = '2026-08-05', last_verified_at = NULL
--    WHERE race_id IN (SELECT id FROM essentials.races
--                       WHERE election_id = '5aec8ba8-8f04-4368-9529-130ea489a4d3');
--   -- and strip the ' | re-verified…' / ' | re-checked…' suffixes from `source`.
