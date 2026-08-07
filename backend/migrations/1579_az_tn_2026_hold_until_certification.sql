-- 1579_az_tn_2026_hold_until_certification.sql
--
-- Two holds, for opposite reasons. Arizona's canvass HAS happened and the row still cannot be
-- retired; Tennessee's has not happened and its dates say otherwise.
--
--   Rollback: AZ  — UPDATE ... SET provisional_until = '2026-08-06' WHERE id = 'a48d4bf8-…';
--             TN  — UPDATE ... SET provisional_until = '2026-08-07' WHERE id IN (<the 28>);
--                   UPDATE ... SET provisional_until = NULL WHERE <the other 60>;
--             and strip the appended ' | ' notes from `source`.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1579_az_tn_2026_hold_until_certification.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- ARIZONA — one row, and the canvass is not the blocker
-- ---------------------------------------------------------------------------------------------------
-- Curtis Goodwin, AZ-02, seeded from the Libertarian primary of 2026-07-21 with
-- `provisional_until = 2026-08-06`. That date was chosen correctly: Arizona's Official Statewide
-- Canvass of the July 21 primary was scheduled for 2026-08-06 (azsos.gov events listing). Unlike
-- Washington in migration 1577, this row was gated on the canvass, not on election day.
--
-- So the gate has opened — and the row still cannot be resolved, for two reasons that pull apart:
--
--   1. Ballotpedia's certified AZ-02 general field lists exactly TWO names: "Incumbent Eli Crane and
--      Jonathan Nez are running in the general election for U.S. House Arizona District 2 on
--      November 3, 2026." Goodwin is not among them.
--   2. But Ballotpedia's own Libertarian-primary table for that district is EMPTY — it says
--      "Curtis Goodwin and Alex Flores ran in the Libertarian primary … on July 21, 2026" and then
--      records no votes and marks no winner. The source that would tell us whether he won the
--      nomination has not been updated.
--
-- 🔴 A source that has not recorded the RESULT cannot be trusted to have recorded the CONSEQUENCE of
-- that result. The general field's silence about Goodwin and the primary table's silence about the
-- outcome are the same silence, one day after the canvass. Retiring him on the first while ignoring
-- the second would be reading one half of an un-updated page as fact.
--
-- 🚧 azsos.gov returns HTTP 403 to scripted fetches — both the canvass event page and the 2026
-- election-info page, with and without a browser User-Agent. Classified as a bot block, not a dead
-- link: the pages are publicly reachable in a browser. The official canvass result therefore could
-- not be read tonight, and this row waits for it rather than settling on a secondary source.
--
-- ---------------------------------------------------------------------------------------------------
-- TENNESSEE — the primary was YESTERDAY and the dates were set from election day
-- ---------------------------------------------------------------------------------------------------
-- Tennessee's primary was held 2026-08-06. Its 28 flagged rows carry `provisional_until = 2026-08-07`
-- — today — so by tonight the queue already calls them due. They are not:
--
--     Tennessee county election commissions certify no later than the THIRD MONDAY after the
--     election — for an 2026-08-06 primary, 2026-08-24.
--
-- One day of unofficial returns is not a certified nomination. Re-dated to 2026-08-27.
--
-- AND THE UNDERCOUNT AGAIN — for the fourth time in this sweep. The TN general shell holds 88 rows
-- across 10 races; only 28 were flagged. The other 60 are just as pre-primary: Tennessee runs
-- partisan primaries, so every major-party name on a November shell is contingent on the 2026-08-06
-- result exactly as the flagged minor-party ones are. All 88 are stamped.
--
--   Running tally of flagged-vs-actually-provisional in this sweep:
--     Virginia    8 flagged / 21 needing a decision
--     Kansas     26 flagged / 26  (correct, the only one)
--     Washington 20 flagged / 69
--     Tennessee  28 flagged / 88
--
-- 🔑 The pattern is consistent enough to be a rule: `provisional_until` gets set on rows whose
-- SOURCING felt shaky (independents, minor parties) rather than on rows whose FACTS are contingent.
-- Contingency is a property of the election calendar, not of the seeder's confidence.
-- ---------------------------------------------------------------------------------------------------

-- Arizona: hold the single AZ-02 row for the official canvass result.
UPDATE essentials.race_candidates
   SET provisional_until = '2026-08-21',
       source = source || ' | re-checked 2026-08-07 (AZ statewide canvass was 2026-08-06): absent'
                       || ' from the certified AZ-02 general field (Crane, Nez), BUT ballotpedia.org'
                       || ' records NO result for the CD2 Libertarian primary it says he ran in —'
                       || ' empty vote table, no winner marked. azsos.gov returns HTTP 403 to'
                       || ' scripted fetches (bot block), so the official canvass could not be read.'
                       || ' NOT retired on a source that has not recorded the result. Window extended'
                       || ' to 2026-08-21 by migration 1579.'
 WHERE id = 'a48d4bf8-b07d-4ce8-bda5-6bd6b8b5c359';

-- Tennessee: re-date the 28 flagged rows from election-day+1 to certification+3.
UPDATE essentials.race_candidates
   SET provisional_until = '2026-08-27',
       source = source || ' | 2026-08-07 hold: NOT culled. The TN primary was 2026-08-06 and county'
                       || ' election commissions certify no later than the third Monday after the'
                       || ' election (2026-08-24). The 2026-08-07 date was set from election day, not'
                       || ' certification. Re-dated to 2026-08-27 by migration 1579.'
 WHERE race_id IN (SELECT id FROM essentials.races
                    WHERE election_id = 'fee6619a-62dc-4cc7-b2fd-d8d289bc54cb')
   AND provisional_until IS NOT NULL;

-- Tennessee: bring the 60 unflagged rows into the queue.
UPDATE essentials.race_candidates
   SET provisional_until = '2026-08-27',
       source = source || ' | 2026-08-07: flagged provisional by migration 1579. TN runs partisan'
                       || ' primaries, so every major-party name on this November shell is contingent'
                       || ' on the 2026-08-06 primary exactly as the minor-party ones are. Awaiting'
                       || ' certification (2026-08-24).'
 WHERE race_id IN (SELECT id FROM essentials.races
                    WHERE election_id = 'fee6619a-62dc-4cc7-b2fd-d8d289bc54cb')
   AND provisional_until IS NULL;

-- ---------------------------------------------------------------------------------------------------
-- ▶ WORK OWED
-- ---------------------------------------------------------------------------------------------------
--   AZ, after the official canvass result is readable: settle Curtis Goodwin (AZ-02) — did he win the
--     Libertarian nomination, and is he on the certified November field?
--   TN, after 2026-08-24: full-shell reconcile of all 88 rows across 10 races against the certified
--     field, on the pattern of migrations 1575/1576/1578.
