-- 1589_retire_la_roster_bos_shells_and_race_uniqueness.sql
--
-- Retire the five `la_roster` Board of Supervisors race shells, and add the uniqueness constraint
-- that makes the class impossible — keyed correctly, which is not where I first pointed.
--
--   Rollback: rows archived in full in essentials._retired_1589_races and _retired_1589_candidates.
--             DROP INDEX essentials.races_election_office_party_uniq to undo the constraint.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1589_retire_la_roster_bos_shells_and_race_uniqueness.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 CORRECTING THE DIAGNOSIS FIRST
-- ---------------------------------------------------------------------------------------------------
-- These five races were described as sharing an office_id. They do not. Every district has its own:
--   D1 ab608cce · D2 d39c0bfe · D3 a38babc0 · D4 1bce4c37 · D5 e8603d4c
-- The office model is correct. The defect is that TWO `races` rows point at the same
-- (election_id, office_id) pair — a `la_roster` shell holding only the sitting supervisor, alongside
-- the real candidate field:
--
--   ab608cce  "Board of Supervisors District 1"                    1 cand: Hilda L. Solis      la_roster
--             "Los Angeles County Board of Supervisors District 1" 6 cands                     manual   ← real
--   a38babc0  "Board of Supervisors District 3"                    1 cand: Lindsey P. Horvath  la_roster
--             "Los Angeles County Board of Supervisors District 3" 3 cands                     manual   ← real
--
-- Voter-facing consequence: Hilda Solis reads as a 2026 candidate for the seat Maria Elena Durazo
-- won outright with 60.58% (migration 1583).
--
-- ---------------------------------------------------------------------------------------------------
-- 🔑 AND CORRECTING THE PROPOSED FIX — A UNIQUE INDEX ON (election_id, office_id) WOULD BE WRONG
-- ---------------------------------------------------------------------------------------------------
-- That was the suggestion. Checking it against the data first: there are 198 duplicate
-- (election_id, office_id) pairs in the database, covering 399 races. If the rule were
-- "one race per office per election", nearly four hundred rows would be violations.
--
-- They are not. 196 of the 198 pairs have DISTINCT primary_party values — they are PARTISAN
-- PRIMARIES, where a Democratic race and a Republican race for the same office in the same election
-- are two legitimately separate contests with separate candidate fields. Kansas Governor is one row
-- for the Democratic primary and one for the Republican; both are correct and both must survive.
--
-- Only 2 of the 198 pairs share a party value (both NULL), and they are precisely the LA Board of
-- Supervisors D1 and D3 pairs above. So the real invariant is:
--
--     one race per (election, office, primary_party)
--
-- An index on (election_id, office_id) would have failed to build, and had it somehow been forced
-- through it would have destroyed every partisan primary in the corpus. The narrower key is not a
-- technicality — it is the difference between a constraint that encodes how elections work and one
-- that encodes how this single bug looked.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY ALL FIVE SHELLS GO, NOT JUST THE TWO DUPLICATES
-- ---------------------------------------------------------------------------------------------------
-- D1 and D3 are redundant with a real race. D2, D4 and D5 have no competing race, so they do not
-- block the index — but they are the same artefact and are wrong for their own reasons:
--
--   D2 (Holly J. Mitchell) and D4 (Janice Hahn) — these seats are NOT UP in 2026. Los Angeles County
--   elects supervisors for districts 1, 3 and 5 in gubernatorial years and 2 and 4 in presidential
--   years. Both rows put a sitting supervisor on a ballot that does not exist.
--
--   D5 (Kathryn Barger) — this seat IS up in 2026, and the shell is still wrong: it shows the
--   incumbent as the sole candidate, which asserts an unopposed race we have no evidence for. The
--   certified LA County results contain no Supervisor 5th District contest at all, because that seat
--   is not on the June primary ballot in the same cycle as 1 and 3.
--
-- Removing a wrong race is better than keeping it: an empty seat reads as "we have no data", while a
-- shell reads as "this person is running".
--
-- ▶ FOLLOW-UP OWED: District 5 needs a real candidate field sourced before November.
--
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════
-- 🔴 CORRECTED 2026-08-07 BY MIGRATION 1596 — THE TWO CLAIMS ABOUT D5 ABOVE ARE FALSE.
-- Nothing about the DELETEs below changes; retiring all five shells was right. What is wrong is the
-- reasoning, and the "FOLLOW-UP OWED" line, which was an instruction to fabricate a race. It was acted
-- on: a later session was asked to seed the D5 field and found there was nothing to seed.
--
--   * D5 IS NOT UP IN 2026. Kathryn Barger won D5 outright in the March 5 2024 primary (cancelling
--     that general) and holds the seat to 2028 — her third and final term under the county's
--     three-term limit.
--   * "1, 3 and 5 in gubernatorial years" IS NOT THE CYCLE. It is D1 and D3 in gubernatorial years
--     (2022, 2026) and D2, D4 AND D5 in presidential years (2024, 2028). Barger and Hahn were both
--     elected in 2016/2020/2024, which is the presidential cycle.
--
-- ⚠ NOTE THE SELF-CONTRADICTION, because it is the lesson. Four lines above, this file states that
-- "the certified LA County results contain no Supervisor 5th District contest at all" — the correct
-- and decisive fact — and in the same sentence concludes the seat "IS up in 2026". The evidence was
-- already in hand and the conclusion was written past it. When a certified list of contests does not
-- contain a race, the seat is not up; no theory about staggered cycles outranks that.
--
-- The `_retired_1589_races.reason` annotations have been amended in place (appended, not overwritten)
-- so the archive carries this correction too.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════
-- ---------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS essentials._retired_1589_races AS
  SELECT r.*, NULL::text AS reason, now() AS removed_at FROM essentials.races r WHERE false;
CREATE TABLE IF NOT EXISTS essentials._retired_1589_candidates AS
  SELECT rc.*, now() AS removed_at FROM essentials.race_candidates rc WHERE false;

INSERT INTO essentials._retired_1589_candidates
  SELECT rc.*, now() FROM essentials.race_candidates rc
   WHERE rc.race_id IN ('f782ce44-df81-43f8-b62f-41f0ced6bc9f','ed52d4ef-2529-4329-ab34-d44d34da0c6a',
                        '8353e7b3-f7ae-410a-9e34-15f4018785e8','49e7d76f-dcb8-42dc-a10a-187c3a8b3f91',
                        '9e2a96b8-5010-4e84-a011-a67ff2dd82e7');

INSERT INTO essentials._retired_1589_races
  SELECT r.*,
         'la_roster synthetic shell: attached the sitting supervisor to an election as though a candidate. D1/D3 duplicated the real race on the same office; D2/D4 are not up in 2026; D5 is up but the shell asserted an unopposed incumbent with no evidence.',
         now()
  FROM essentials.races r
   WHERE r.id IN ('f782ce44-df81-43f8-b62f-41f0ced6bc9f','ed52d4ef-2529-4329-ab34-d44d34da0c6a',
                  '8353e7b3-f7ae-410a-9e34-15f4018785e8','49e7d76f-dcb8-42dc-a10a-187c3a8b3f91',
                  '9e2a96b8-5010-4e84-a011-a67ff2dd82e7');

DELETE FROM essentials.race_candidates
 WHERE race_id IN ('f782ce44-df81-43f8-b62f-41f0ced6bc9f','ed52d4ef-2529-4329-ab34-d44d34da0c6a',
                   '8353e7b3-f7ae-410a-9e34-15f4018785e8','49e7d76f-dcb8-42dc-a10a-187c3a8b3f91',
                   '9e2a96b8-5010-4e84-a011-a67ff2dd82e7');

DELETE FROM essentials.races
 WHERE id IN ('f782ce44-df81-43f8-b62f-41f0ced6bc9f','ed52d4ef-2529-4329-ab34-d44d34da0c6a',
              '8353e7b3-f7ae-410a-9e34-15f4018785e8','49e7d76f-dcb8-42dc-a10a-187c3a8b3f91',
              '9e2a96b8-5010-4e84-a011-a67ff2dd82e7');

-- The invariant: one race per office per election PER PARTY. NULL primary_party is folded to a
-- sentinel so nonpartisan races compare equal to each other rather than always being distinct.
CREATE UNIQUE INDEX IF NOT EXISTS races_election_office_party_uniq
  ON essentials.races (election_id, office_id, COALESCE(primary_party, '~nonpartisan~'))
  WHERE office_id IS NOT NULL;

COMMENT ON INDEX essentials.races_election_office_party_uniq IS
  'One race per (election, office, primary_party). primary_party is part of the key because partisan primaries legitimately place a Democratic AND a Republican race on the same office in the same election — 196 such pairs exist. Added by migration 1589 after five la_roster shells duplicated real LA County Board of Supervisors races.';
