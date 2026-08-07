-- 1594_la_mayor_sheriff_june_field_and_november_runoffs.sql
--
-- Seed the LA City Mayor contest and complete the LA County Sheriff field, then create the two
-- November runoff races those two contests produced.
--
--   Re-parents 1 race, repairs 14 candidate rows, adds 4 politicians + 4 June candidate rows,
--   creates 2 races + 4 November candidate rows.
--
--   Rollback:
--     UPDATE essentials.races SET election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'
--      WHERE id='24bc3631-22cf-41ab-a731-672481502214';
--     -- the 12 statuses restored to 'withdrawn' are listed in the UPDATE below
--     DELETE FROM essentials.race_candidates WHERE race_id IN
--       ('9e888818-c50b-4c61-a106-a0839ff2479d','48dd101d-d795-49a0-9252-cf19bdb216ad');
--     DELETE FROM essentials.races WHERE id IN
--       ('9e888818-c50b-4c61-a106-a0839ff2479d','48dd101d-d795-49a0-9252-cf19bdb216ad');
--     DELETE FROM essentials.race_candidates WHERE race_id='df1e3b69-2c44-4f70-bbe1-7306db0ce248'
--       AND politician_id IN ('9410b8bf-c102-445a-bc2b-bd7cc4460a82','b2323ce2-3966-4293-b46d-878ded7a367d',
--                             'ff34e85a-d65d-45b9-8e48-6af790c87a7d','f88be9b6-dd62-4fbe-a5df-135e1e232c10');
--     DELETE FROM essentials.politicians WHERE id IN (the same four);
--
-- ⚠ MUST BE APPLIED AS `postgres` (over the supabase MCP). It was FIRST ATTEMPTED as ev_migrator and
-- failed on "new row violates row-level security policy for table politicians": every `essentials`
-- table has RLS enabled with no permissive policy, so a role without BYPASSRLS cannot read or write
-- them. See migration 1593, whose premise this corrects.
--
-- Source: LA County Registrar-Recorder certified results for the June 2 2026 election,
-- results.lavote.gov/text-results/4338 (certified 2026-06-26, fetched 2026-08-07).
--   "LOS ANGELES CITY PRIMARY NOMINATING ELECTION Mayor" -- 14 candidates, percentages sum to 100.01%
--   "SHERIFF"                                           --  8 candidates, percentages sum to  99.99%
-- Both fields are therefore complete as printed.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE MAYOR RACE ALREADY EXISTED -- ON THE WRONG ELECTION
-- ---------------------------------------------------------------------------------------------------
-- The handoff recorded "LA City MAYOR has no race row at all". Not so. Race
-- 24bc3631-22cf-41ab-a731-672481502214 existed on the 2026 LA County GENERAL (November 3) carrying
-- FOURTEEN candidates. Those fourteen names are an exact, complete match for the JUNE PRIMARY field in
-- the certified canvass -- Bass, Raman, Pratt, Miller, Huang, Lopez, A. Kim, S. Kim, Alnajjar, Acosta,
-- Logsdon, Hyman, Selivra, Cheng. It is the June primary field, parented to the November election.
--
-- A November runoff cannot have fourteen candidates. So this is a re-parent, not a new seed: the race
-- moves to the June primary where its candidates actually ran, and a REAL two-person November runoff is
-- created alongside it. Re-parenting (rather than deleting and re-seeding) preserves all 14 rows and
-- their politician_id links.
--
-- ⚠ AND THE OUTCOME WAS ENCODED IN THE WRONG COLUMN. Twelve of the fourteen were marked
-- candidate_status = 'withdrawn'. They did not withdraw -- they LOST a primary. Because
-- is_live_candidate() excludes 'withdrawn', the display happened to look right, which is exactly why
-- this survived: a wrong fact and a right rendering. `result` is the column for outcomes
-- (migration 1574), and every other finished June race on this election models it that way -- Long
-- Beach Mayor and LA County Sheriff both carry candidate_status='active' with the outcome in `result`.
-- So the twelve go back to 'active' and get result='lost'.
--
-- ---------------------------------------------------------------------------------------------------
-- THE SHERIFF FIELD WAS HALF MISSING, AND THE HANDOFF MIS-DESCRIBED THE RUNOFF
-- ---------------------------------------------------------------------------------------------------
-- The certified Sheriff field is EIGHT names; we held four (Luna, Carranza, Bornman, Corbett). Missing:
-- Villanueva (2nd, 21.70%), Strong (3rd, 14.96%), Martinez (4.16%) and White (3.91%). Adding only
-- Villanueva -- the literal request -- would have left a race whose recorded votes cover 55% of the
-- ballots cast and whose 3rd-place finisher is invisible, so all four are added.
--
-- The handoff also said Villanueva "is in the November runoff, but has no row -- that runoff currently
-- shows one participant". There was no November Sheriff runoff race at all: before this migration the
-- 2026 LA County General held EXACTLY ONE race, the mis-parented Mayor one. Nothing showed one
-- participant because nothing showed. Both November races are created here.
--
-- NO POLITICIAN ROWS EXISTED for the four. Searching `politicians` for "Villanueva" returns almost
-- nothing but FEC committee names ("VILLANUEVA FOR SHERIFF 2026", "...AMIGOS DEL SHERIFF SUPPORTING"),
-- because 77k committee rows share that table. The four person rows are created here in the same shape
-- as the existing lavote-2026 candidates (first/last split, source, is_incumbent explicitly false --
-- the column DEFAULTS TO TRUE, which would silently promote four losing candidates to officeholders).
-- photo_origin_url is left NULL: the existing rows carry campaign homepages, and inventing URLs for
-- these four would manufacture citations.
--
-- ---------------------------------------------------------------------------------------------------
-- THE RULE APPLIED, AND WHY IT IS RUNOFF AND NOT WON
-- ---------------------------------------------------------------------------------------------------
-- Both ballot titles decide it. "PRIMARY NOMINATING ELECTION" = >50% wins outright, otherwise the top
-- two go to a November runoff (contrast "GENERAL/REGULAR MUNICIPAL", plurality, where top N simply
-- win). Neither leader cleared 50%: Bass 34.27%, Luna 44.15%. So each contest sends two to November and
-- nobody has won anything yet.
--
-- `result` is per-race, not per-person (the Jaisen Rutledge precedent): Bass is `runoff` on the June
-- race and NULL on the November race, because November has not happened. NULL means "not recorded" and
-- must not be read as a loss.
-- ---------------------------------------------------------------------------------------------------

BEGIN;

-- ═══ 1. LA CITY MAYOR — re-parent the June primary field off the November election ═══
UPDATE essentials.races
   SET election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe',
       description = 'Los Angeles City Primary Nominating Election for Mayor, June 2 2026. Top two advance to a November 3 2026 runoff unless one candidate exceeds 50%.'
 WHERE id = '24bc3631-22cf-41ab-a731-672481502214';

-- The twelve did not withdraw; they lost. Restore the status and let `result` carry the outcome.
UPDATE essentials.race_candidates SET candidate_status = 'active'
 WHERE race_id = '24bc3631-22cf-41ab-a731-672481502214'
   AND candidate_status = 'withdrawn';   -- Miller, Selivra, A.Kim, Alnajjar, Acosta, Logsdon,
                                         -- Lopez, Cheng, Huang, Pratt, S.Kim, Hyman

UPDATE essentials.race_candidates SET result='runoff', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026, Los Angeles City Primary Nominating Election Mayor (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). No candidate reached a majority in a 14-candidate field, so the top two advance to the November 3 2026 runoff: Bass 292,593 / 34.27%; Raman 247,781 / 29.02%.'
 WHERE id IN (
  'c13cb353-780a-4cf4-97b5-d0556a09e7cd',  -- Karen Ruth Bass  292,593  34.27%  (incumbent)
  '4b01ee54-b812-4a67-9a0e-dfe973c6e3e3'   -- Nithya Raman     247,781  29.02%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026, Los Angeles City Primary Nominating Election Mayor (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). Finished outside the top two of a 14-candidate field and did not reach the November 3 2026 runoff.'
 WHERE id IN (
  '29a6c7d4-7f05-428d-8207-a48cfe50f4e2',  -- Spencer Pratt    217,977  25.53%
  '741a7357-160f-4408-b3a0-75bf93a157ce',  -- Adam Miller       30,008   3.51%
  'b7fefd79-9708-4165-9bd3-e1e4e426eff3',  -- Rae Chen Huang    25,220   2.95%
  '870168dd-1752-4d6c-9168-0dcb004879d2',  -- Juanita Lopez     13,033   1.53%
  '3686fc9c-b7ea-41c3-aaa5-db94c10f3622',  -- Andrew K. Kim      6,988   0.82%
  'd78743af-7ce8-4bd0-ba3c-9912e9b9e09a',  -- Suzy Kim           6,051   0.71%
  'e2c7f5e1-dc7b-4171-add2-9ed3c801b8a1',  -- Asaad Alnajjar     4,063   0.48%
  'b1155c48-7540-49f7-98ae-81493655ddb9',  -- Bryant Acosta      3,471   0.41%
  'fc8f76d7-f2b5-4efb-b1ba-2e599018124b',  -- John Logsdon       3,029   0.35%
  'e5fa9e64-24e0-4914-b04d-43ebb044b278',  -- Tish Hyman         1,640   0.19%
  '05d4a80e-68d0-46a1-914a-a03ec032d120',  -- Andrej A. Selivra  1,159   0.14%
  'd7d65f45-778b-4b9b-b9db-c0c5536288bb'   -- Nelson Cheng         881   0.10%
 );

-- ═══ 2. LA COUNTY SHERIFF — add the four missing candidates ═══
-- is_incumbent is stated explicitly because the column defaults to TRUE.
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, source, is_incumbent, is_active)
VALUES
  ('9410b8bf-c102-445a-bc2b-bd7cc4460a82', 'Alex Villanueva',        'Alex',   'Villanueva', 'lavote-2026', false, true),
  ('b2323ce2-3966-4293-b46d-878ded7a367d', 'Eric Strong',            'Eric',   'Strong',     'lavote-2026', false, true),
  ('ff34e85a-d65d-45b9-8e48-6af790c87a7d', 'Oscar Antonio Martinez', 'Oscar',  'Martinez',   'lavote-2026', false, true),
  ('f88be9b6-dd62-4fbe-a5df-135e1e232c10', 'Andre N. White',         'Andre',  'White',      'lavote-2026', false, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source,
   result, result_recorded_at, result_source)
VALUES
  ('df1e3b69-2c44-4f70-bbe1-7306db0ce248', '9410b8bf-c102-445a-bc2b-bd7cc4460a82',
   'Alex Villanueva', 'Alex', 'Villanueva', false, 'active', 'lavote-2026',
   'runoff', '2026-08-07T00:00:00Z',
   'LA County RR/CC certified results, June 2 2026, Sheriff (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). No candidate reached a majority in an 8-candidate field, so the top two advance to the November 3 2026 runoff: Luna 859,070 / 44.15%; Villanueva 422,272 / 21.70%.'),
  ('df1e3b69-2c44-4f70-bbe1-7306db0ce248', 'b2323ce2-3966-4293-b46d-878ded7a367d',
   'Eric Strong', 'Eric', 'Strong', false, 'active', 'lavote-2026',
   'lost', '2026-08-07T00:00:00Z',
   'LA County RR/CC certified results, June 2 2026, Sheriff (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). Finished third of eight with 291,045 / 14.96%; did not reach the November 3 2026 runoff.'),
  ('df1e3b69-2c44-4f70-bbe1-7306db0ce248', 'ff34e85a-d65d-45b9-8e48-6af790c87a7d',
   'Oscar Antonio Martinez', 'Oscar', 'Martinez', false, 'active', 'lavote-2026',
   'lost', '2026-08-07T00:00:00Z',
   'LA County RR/CC certified results, June 2 2026, Sheriff (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). Finished fifth of eight with 80,885 / 4.16%; did not reach the November 3 2026 runoff.'),
  ('df1e3b69-2c44-4f70-bbe1-7306db0ce248', 'f88be9b6-dd62-4fbe-a5df-135e1e232c10',
   'Andre N. White', 'Andre', 'White', false, 'active', 'lavote-2026',
   'lost', '2026-08-07T00:00:00Z',
   'LA County RR/CC certified results, June 2 2026, Sheriff (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). Finished seventh of eight with 76,162 / 3.91%; did not reach the November 3 2026 runoff.')
ON CONFLICT DO NOTHING;   -- unique (race_id, candidate_name_key(full_name)), migration 1586

-- ═══ 3. THE TWO NOVEMBER RUNOFF RACES ═══
-- Created AFTER the re-parent above, or the Mayor insert would collide with the moved race on the
-- unique index over (election_id, office_id, COALESCE(primary_party,'~nonpartisan~')).
-- `result` stays NULL on all four rows: November 3 2026 has not happened.
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description)
VALUES
  ('9e888818-c50b-4c61-a106-a0839ff2479d', 'd91a20ce-557e-4615-a31b-5b2b3df2ed14',
   'b8c4bd9d-05ba-4751-b947-7a3d2645d3ef', 'Los Angeles Mayor', NULL, 1,
   'November 3 2026 runoff between the top two finishers in the June 2 2026 Los Angeles City primary nominating election.'),
  ('48dd101d-d795-49a0-9252-cf19bdb216ad', 'd91a20ce-557e-4615-a31b-5b2b3df2ed14',
   'dd507d10-a106-42e6-a275-2385154aa072', 'LA County Sheriff', NULL, 1,
   'November 3 2026 runoff between the top two finishers in the June 2 2026 Los Angeles County Sheriff primary.')
ON CONFLICT DO NOTHING;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
VALUES
  ('9e888818-c50b-4c61-a106-a0839ff2479d', '21c9e711-fb18-4afb-884f-08acd2b598ba',
   'Karen Ruth Bass', 'Karen', 'Bass', true,  'active', 'lavote-2026-certified-runoff'),
  ('9e888818-c50b-4c61-a106-a0839ff2479d', '26dbe16a-9dff-42c0-939f-5b5e529063ca',
   'Nithya Raman', 'Nithya', 'Raman', false, 'active', 'lavote-2026-certified-runoff'),
  ('48dd101d-d795-49a0-9252-cf19bdb216ad', '21975878-739e-452b-8bf7-95919680462a',
   'Robert Luna', 'Robert', 'Luna', true,  'active', 'lavote-2026-certified-runoff'),
  ('48dd101d-d795-49a0-9252-cf19bdb216ad', '9410b8bf-c102-445a-bc2b-bd7cc4460a82',
   'Alex Villanueva', 'Alex', 'Villanueva', false, 'active', 'lavote-2026-certified-runoff')
ON CONFLICT DO NOTHING;

COMMIT;
