-- CC_0361 — 2026-11-03 state executives: record Ballotpedia's called results on the 13 races
--           we ALREADY HOLD that carry candidates and no winner.
--
-- 🔴 THIS FILE OVERWRITES. CC_0360 only inserts; this one changes 34 rows that already exist,
--   and there is no history table and no replayable runner, so the previous values exist
--   nowhere the moment it commits. THEY ARE WRITTEN DOWN HERE, every one:
--
--     prior value   rows
--     NULL          21
--     advanced      13
--
--   🔴 'advanced' IS THE NORMAL SHAPE OF A PRIMARY WINNER ON A NOVEMBER RACE ROW. All 13 are
--     Arizona's, written when its primaries were recorded against these same November races.
--     Overwriting 'advanced' with the general-election outcome is the correct act; the gate
--     below refuses ANY OTHER prior value, so a row that already held a general result
--     cannot be silently replaced.
--   ⚠ result_source and result_recorded_at are replaced ALONGSIDE result, never left behind.
--     A stale timestamp is worse than a null, and CC_0354 had to repair 155 rows that had one.
--
-- WHAT IT WRITES — 34 UPDATEs, pinned by race_candidates.id. No INSERT, no DELETE.
--
--   AZ  Treasurer                          2 row(s), 1 winner(s): Nick Mansour
--   AZ  State Mine Inspector               2 row(s), 1 winner(s): Brian Matlock
--   AZ  Superintendent of Public Instruction 4 row(s), 1 winner(s): Teresa Ruiz
--   AZ  Commissioner                       5 row(s), 2 winner(s): Clara Pratte, Jonathon Hill
--   CA  Controller                         2 row(s), 1 winner(s): Malia M. Cohen
--   CA  Treasurer                          2 row(s), 1 winner(s): Eleni Kounalakis
--   CO  Treasurer                          4 row(s), 1 winner(s): Jeff Bridges
--   IN  Comptroller                        3 row(s), 1 winner(s): Jessica Bailey
--   IN  Treasurer                          2 row(s), 1 winner(s): Daniel Elliott
--   NV  Controller                         2 row(s), 1 winner(s): Michael MacDougall
--   NV  Treasurer                          2 row(s), 1 winner(s): Tya Mathis-Coleman
--   WI  Lieutenant Governor                2 row(s), 1 winner(s): Sarah Godlewski
--   WI  Treasurer                          2 row(s), 1 winner(s): Yee Leng Xiong
--
-- 🔴 ARIZONA'S CORPORATION COMMISSION ELECTS TWO, AND THE ONE-WINNER GATE IS INVALID THERE.
--   essentials.races.seats is 2 on that race and Ballotpedia marks two winners, Clara Pratte
--   and Jonathon Hill. The gate below compares each race's winner count against ITS OWN
--   seats column rather than against 1 — a fixed "exactly one winner" check, which every
--   other file in this series uses correctly, would fail this file for being right.
--   ⚠ Arizona holds FIVE offices plainly titled "Commissioner". Exactly one carries a
--     2026-11-03 race, and that race's five candidates are precisely Ballotpedia's five, so
--     the pin is to that race and not a guess among five.
--
-- ⚠ 7 ROWS IN THESE RACES ARE DELIBERATELY NOT TOUCHED, because Ballotpedia's
--   general-election ballot does not name them. They are primary losers and one withdrawal:
--     AZ Treasurer: Katherine Haley [not_nominated, active]
--     AZ Treasurer: Michael Zepeda [not_nominated, active]
--     AZ Superintendent of Public Instruction: Brett Newby [not_nominated, active]
--     AZ Superintendent of Public Instruction: Michael Butts [NULL, withdrawn]
--     AZ Superintendent of Public Instruction: Tom Horne [not_nominated, active]
--     AZ Commissioner: David Marshall [not_nominated, active]
--     AZ Commissioner: Nick Myers [not_nominated, active]
--   Leaving 'not_nominated' alone is the point: they did not reach this ballot.
--
-- ⚠ AND TWO PEOPLE ON BALLOTPEDIA'S BALLOT ARE ABSENT FROM OUR RACES. Both are declared
--   write-ins: Daniel Wagner (WI Lieutenant Governor, the independent ticket's running mate)
--   and Joseph Kexel (WI Treasurer). This file records results; it does not invent
--   candidacies. They are absent rather than wrong, and said out loud so nobody reads these
--   ballots as complete.
--
-- 🔴 WISCONSIN'S LIEUTENANT GOVERNOR IS A TICKET RACE AND BALLOTPEDIA'S WINNING ROW NAMES
--   THE GOVERNOR. The row reads "David Crowley / Sarah Godlewski" with the tick on Crowley,
--   who ran for GOVERNOR; the narrative names Sarah Godlewski, who ran for this seat and is
--   the row in our race. The running mate is taken, never the row. See CC_0360's header —
--   six states do this and each one would have seated a governor as lieutenant governor.
--
-- SOURCING: identical to CC_0360 and tested the same way. AP publishes no race for any of
--   these offices. Ballotpedia's winner flag agreed with AP's call on 71 of 71 races where
--   both name a winner, while its vote counts ran up to 32% short — so the flag is used and
--   NO NUMBER IS. result_certainty is 'called'.
--
-- Applied to production 2026-11-06 by Chris Cantrell. Slot reserved via steward.

BEGIN;

CREATE TEMP TABLE calls (
  rc_id uuid PRIMARY KEY, race_id uuid NOT NULL, seat text NOT NULL, who text NOT NULL,
  result text NOT NULL, prior text
) ON COMMIT DROP;
INSERT INTO calls (rc_id, race_id, seat, who, result, prior) VALUES
  ('aa19c814-4908-4fcf-acaf-15c317ad39f3'::uuid, '1aa02868-4568-4df3-88e6-0f972dab006f'::uuid,
   'AZ Commissioner',                         'Jonathon Hill',             'won',   'advanced'),
  ('7c3c1c0e-a208-4d5e-8429-27f2c8ea11bf'::uuid, '1aa02868-4568-4df3-88e6-0f972dab006f'::uuid,
   'AZ Commissioner',                         'Clara Pratte',              'won',   'advanced'),
  ('e4b506cc-9c06-48e7-b3ba-9b0cdb14fa08'::uuid, '1aa02868-4568-4df3-88e6-0f972dab006f'::uuid,
   'AZ Commissioner',                         'Kevin Thompson',            'lost',  'advanced'),
  ('e6b78946-64bc-419a-825e-1996945d9849'::uuid, '1aa02868-4568-4df3-88e6-0f972dab006f'::uuid,
   'AZ Commissioner',                         'Ralph Heap',                'lost',  'advanced'),
  ('54c365be-e380-4a22-ba13-508614c8c9a1'::uuid, '1aa02868-4568-4df3-88e6-0f972dab006f'::uuid,
   'AZ Commissioner',                         'Mike Cease',                'lost',  'advanced'),
  ('d930ae4d-8991-4815-a135-d02c94d710f7'::uuid, '51bfc726-b90a-4ac2-b0a6-c9305f01685b'::uuid,
   'AZ State Mine Inspector',                 'Brian Matlock',             'won',   'advanced'),
  ('4cca6a73-3bd8-4614-919d-cfbca7148509'::uuid, '51bfc726-b90a-4ac2-b0a6-c9305f01685b'::uuid,
   'AZ State Mine Inspector',                 'Les Presmyk',               'lost',  'advanced'),
  ('2bd5d9e9-9655-4120-a724-7bbccbc046d9'::uuid, '376d3c10-cbee-4f56-b534-e10ff508e6cc'::uuid,
   'AZ Superintendent of Public Instruction', 'Teresa Ruiz',               'won',   'advanced'),
  ('c380fe5a-e117-44dd-bd85-30ff609e274b'::uuid, '376d3c10-cbee-4f56-b534-e10ff508e6cc'::uuid,
   'AZ Superintendent of Public Instruction', 'Kimberly Yee',              'lost',  'advanced'),
  ('7e1b376e-7893-4a2e-9177-69622d1deb0b'::uuid, '376d3c10-cbee-4f56-b534-e10ff508e6cc'::uuid,
   'AZ Superintendent of Public Instruction', 'Stephen Neal Jr.',          'lost',  'advanced'),
  ('24670059-4257-491f-a966-7e12f32bfd6b'::uuid, '376d3c10-cbee-4f56-b534-e10ff508e6cc'::uuid,
   'AZ Superintendent of Public Instruction', 'Gerard Davis',              'lost',  'advanced'),
  ('5c91f031-c392-4d9e-9b13-e062fd3d7b70'::uuid, '7d9eb3e1-d633-487e-89b2-5cec4526eafa'::uuid,
   'AZ Treasurer',                            'Nick Mansour',              'won',   'advanced'),
  ('fa4c48e3-0f9d-42a2-b80a-748a50873d30'::uuid, '7d9eb3e1-d633-487e-89b2-5cec4526eafa'::uuid,
   'AZ Treasurer',                            'Elijah Norton',             'lost',  'advanced'),
  ('5b126582-92d1-42dd-89ef-75fa86c06c33'::uuid, '7f8b26b6-4349-4c50-930c-48083aa564fd'::uuid,
   'CA Controller',                           'Malia M. Cohen',            'won',   NULL),
  ('d29380e0-dde7-4bea-8d0a-8c09609b4c74'::uuid, '7f8b26b6-4349-4c50-930c-48083aa564fd'::uuid,
   'CA Controller',                           'Herb W. Morgan',            'lost',  NULL),
  ('92098672-ed73-4f9e-8fe7-ee80c1d8f27b'::uuid, 'e226b3af-31ba-4304-9a86-f0c741165ce9'::uuid,
   'CA Treasurer',                            'Eleni Kounalakis',          'won',   NULL),
  ('852e074e-fd90-4cad-82d5-0d5fc9221e53'::uuid, 'e226b3af-31ba-4304-9a86-f0c741165ce9'::uuid,
   'CA Treasurer',                            'Jennifer Hawks',            'lost',  NULL),
  ('1c1f3903-4dbe-4bc9-afeb-aa1634324aee'::uuid, '0eae2357-d723-46de-b9d5-9caec4b6b545'::uuid,
   'CO Treasurer',                            'Jeff Bridges',              'won',   NULL),
  ('bf09f49a-9149-4286-8807-cd77756a82b4'::uuid, '0eae2357-d723-46de-b9d5-9caec4b6b545'::uuid,
   'CO Treasurer',                            'Kevin Grantham',            'lost',  NULL),
  ('31a92eec-f7fc-43bf-9ac3-5d21501db6c7'::uuid, '0eae2357-d723-46de-b9d5-9caec4b6b545'::uuid,
   'CO Treasurer',                            'Jodie Barr',                'lost',  NULL),
  ('7ded092f-178b-41a8-99c4-838ae8ef1445'::uuid, '0eae2357-d723-46de-b9d5-9caec4b6b545'::uuid,
   'CO Treasurer',                            'Marilee Langner Sturgis',   'lost',  NULL),
  ('58ed48f9-ec36-48e7-97b4-0102b979af23'::uuid, '0f1bd30c-1cce-4a23-8ecd-a79c087171c6'::uuid,
   'IN Comptroller',                          'Jessica Bailey',            'won',   NULL),
  ('5a96cdb3-b3d9-4667-8734-ffca310a4597'::uuid, '0f1bd30c-1cce-4a23-8ecd-a79c087171c6'::uuid,
   'IN Comptroller',                          'Elise Nieshalla',           'lost',  NULL),
  ('8c4d3563-58e4-4b69-8d5c-ffef2e93ce29'::uuid, '0f1bd30c-1cce-4a23-8ecd-a79c087171c6'::uuid,
   'IN Comptroller',                          'John Schick',               'lost',  NULL),
  ('bf1c25a3-034b-4aa5-a521-937b97dff044'::uuid, '5bb5cb37-3508-49fa-a006-c8076ee83959'::uuid,
   'IN Treasurer',                            'Daniel Elliott',            'won',   NULL),
  ('cb1562c5-66ff-44d1-98e3-436cc3413228'::uuid, '5bb5cb37-3508-49fa-a006-c8076ee83959'::uuid,
   'IN Treasurer',                            'Coumba Kebe',               'lost',  NULL),
  ('a77d60df-eb32-4243-97f8-17c536038dc2'::uuid, '0180490c-b2e0-4b9b-9514-92382279fc9f'::uuid,
   'NV Controller',                           'Michael MacDougall',        'won',   NULL),
  ('fac22020-6643-49e7-8307-ddc1c357097d'::uuid, '0180490c-b2e0-4b9b-9514-92382279fc9f'::uuid,
   'NV Controller',                           'Andy Matthews',             'lost',  NULL),
  ('b9b91000-1dcf-4465-a7fa-c326e6cf9460'::uuid, '1dc513cd-30d0-4eb6-9af6-917a8525c14e'::uuid,
   'NV Treasurer',                            'Tya Mathis-Coleman',        'won',   NULL),
  ('c0f6c872-9493-46e0-bc44-6cbdcebebf2e'::uuid, '1dc513cd-30d0-4eb6-9af6-917a8525c14e'::uuid,
   'NV Treasurer',                            'Drew Johnson',              'lost',  NULL),
  ('e38da949-4be6-4e2b-bb19-8b2ea521166d'::uuid, '41b4e388-4b0b-4d5e-8557-c2d8c38a2bfe'::uuid,
   'WI Lieutenant Governor',                  'Sarah Godlewski',           'won',   NULL),
  ('07ea84bd-6269-41d1-9a35-788ac922e83d'::uuid, '41b4e388-4b0b-4d5e-8557-c2d8c38a2bfe'::uuid,
   'WI Lieutenant Governor',                  'David Varnam',              'lost',  NULL),
  ('6b299443-b91a-4a00-9751-8069dc488319'::uuid, '464a0947-7961-4e00-a5f6-0c3abc5d34a7'::uuid,
   'WI Treasurer',                            'Yee Leng Xiong',            'won',   NULL),
  ('310a8178-77d8-48b5-a31e-e927ac4cf34c'::uuid, '464a0947-7961-4e00-a5f6-0c3abc5d34a7'::uuid,
   'WI Treasurer',                            'John S. Leiber',            'lost',  NULL);

-- every candidacy in the races this file touches, as it stands BEFORE the write
CREATE TEMP TABLE before_rows ON COMMIT DROP AS
SELECT rc.id, rc.race_id, rc.full_name, rc.result, rc.result_certainty, rc.result_source, rc.candidate_status
  FROM essentials.race_candidates rc
 WHERE rc.race_id IN (SELECT DISTINCT race_id FROM calls);

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM calls;
  IF n <> 34 THEN RAISE EXCEPTION 'expected 34 pinned rows, found %', n; END IF;

  -- every pinned row must exist, and sit in the race this file says it does
  SELECT string_agg(c.seat || ' ' || c.who || ' (' || c.rc_id || ')', '; ') INTO txt
    FROM calls c LEFT JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.id IS NULL OR rc.race_id <> c.race_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned candidacy is missing or sits in another race: %', txt; END IF;

  -- 🔴 and it must still carry the NAME this file recorded against it. The pin is a uuid;
  --    without this the file could update a row that had been repointed at someone else.
  SELECT string_agg(c.seat || ': pinned as ' || c.who || ' but the row reads ' || rc.full_name, '; ') INTO txt
    FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.full_name <> c.who;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned candidacy no longer names the person this file read: %', txt; END IF;

  -- 🔴 THE OVERWRITE GATE: only NULL or a primary outcome may be replaced, and the prior
  --    value must be the one written in this header. Anything else means the row moved.
  SELECT string_agg(c.seat || ' ' || c.who || ' = ' || coalesce(rc.result, 'NULL') || ' (this file expected ' || coalesce(c.prior, 'NULL') || ')', '; ') INTO txt
    FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result IS DISTINCT FROM c.prior;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned row does not hold the prior value this file recorded: %', txt; END IF;
  SELECT string_agg(DISTINCT coalesce(c.prior, 'NULL'), ', ') INTO txt FROM calls c
   WHERE c.prior IS NOT NULL AND c.prior <> 'advanced';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file would overwrite a result that is not NULL and not a primary outcome: %', txt; END IF;

  -- 🔴 WINNERS PER RACE ARE COMPARED AGAINST THAT RACE'S OWN seats COLUMN, not against 1.
  --    Arizona's Corporation Commission elects two and a fixed check would fail a correct file.
  SELECT string_agg(z.seat || ': ' || z.w || ' winner(s) for ' || z.seats || ' seat(s)', '; ') INTO txt FROM (
    SELECT c.seat, r.seats, count(*) FILTER (WHERE c.result = 'won') AS w
      FROM calls c JOIN essentials.races r ON r.id = c.race_id
     GROUP BY c.seat, r.seats) z WHERE z.w <> z.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race does not elect as many winners as it has seats: %', txt; END IF;
END $$;

UPDATE essentials.race_candidates rc
   SET result             = c.result,
       result_certainty   = 'called',
       result_source      = 'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0361',
       result_recorded_at = now()
  FROM calls c
 WHERE rc.id = c.rc_id
   AND (rc.result IS NULL OR rc.result = 'advanced');

-- ─── Post-verify ───
DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result = c.result AND rc.result_certainty = 'called'
     AND rc.result_source = 'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0361' AND rc.result_recorded_at >= TIMESTAMPTZ '2026-11-05';
  IF n <> 34 THEN RAISE EXCEPTION 'only % of the 34 pinned rows hold their stated result', n; END IF;

  -- 🔴 NOTHING OUTSIDE THE PINS MOVED. Every other row in these races must be byte-identical
  --    to its before-image — this is what catches an UPDATE whose WHERE clause is too wide.
  SELECT string_agg(b.full_name || ': ' || coalesce(b.result,'NULL') || ' -> ' || coalesce(rc.result,'NULL'), '; ') INTO txt
    FROM before_rows b JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE b.id NOT IN (SELECT rc_id FROM calls)
     AND (rc.result IS DISTINCT FROM b.result OR rc.result_certainty IS DISTINCT FROM b.result_certainty
       OR rc.result_source IS DISTINCT FROM b.result_source OR rc.candidate_status IS DISTINCT FROM b.candidate_status);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a row this file does not pin was changed: %', txt; END IF;
  SELECT count(*) INTO n FROM before_rows WHERE id NOT IN (SELECT rc_id FROM calls);
  IF n <> 7 THEN RAISE EXCEPTION 'expected 7 untouched rows in these races, found %', n; END IF;

  -- each race now holds exactly as many winners as it has seats, and nobody undecided
  SELECT count(*) INTO n FROM (
    SELECT r.id FROM essentials.races r JOIN essentials.race_candidates rc ON rc.race_id = r.id
     WHERE r.id IN (SELECT DISTINCT race_id FROM calls) GROUP BY r.id, r.seats
    HAVING count(*) FILTER (WHERE rc.result = 'won') <> r.seats) z;
  IF n <> 0 THEN RAISE EXCEPTION '% race(s) do not hold one winner per seat', n; END IF;

  -- one measured timestamp across the whole write
  SELECT count(DISTINCT rc.result_recorded_at) INTO n FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id;
  IF n <> 1 THEN RAISE EXCEPTION 'the % pinned rows carry % distinct timestamps', (SELECT count(*) FROM calls), n; END IF;
  RAISE NOTICE 'CC_0361 OK — 34 rows updated across 13 races, 7 rows deliberately untouched.';
END $$;

COMMIT;
