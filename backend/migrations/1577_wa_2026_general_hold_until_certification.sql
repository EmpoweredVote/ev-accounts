-- 1577_wa_2026_general_hold_until_certification.sql
--
-- Washington's 2026 general shell is NOT culled here. It is re-dated to the certification it
-- actually depends on, and the 49 rows the queue could not see are brought into it.
--
--   Rollback: UPDATE essentials.race_candidates SET provisional_until = '2026-08-05'
--              WHERE id IN (<the 20 originally-provisional rows>);
--             UPDATE essentials.race_candidates SET provisional_until = NULL
--              WHERE race_id IN (SELECT id FROM essentials.races
--                                 WHERE election_id = '51e7a875-bff9-4e96-adcf-41736454d25d')
--                AND provisional_until = '2026-08-24' AND id NOT IN (<those 20>);
--             -- and strip the ' | 2026-08-07 hold…' suffix from `source`.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1577_wa_2026_general_hold_until_certification.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 WHY WASHINGTON IS NOT CULLED TODAY
-- ---------------------------------------------------------------------------------------------------
-- The 20 provisional rows came due on 2026-08-05 and it is now 2026-08-07, so on the queue's logic
-- they are two days overdue and ready to work. They are not. The queue is measuring the wrong event.
--
-- Washington runs a TOP-TWO primary: exactly two candidates per district advance to November
-- regardless of party, so "who is on the general ballot" is entirely a function of the primary COUNT.
-- And Washington votes by mail:
--
--     County canvassing boards certify ...... 2026-08-18 (equipment check deadline; county certs)
--     Secretary of State certifies .......... 2026-08-21
--                                             (www2.sos.wa.gov/elections/calendar_list.aspx?y=2026)
--
-- That is FOURTEEN DAYS from today. Washington's late-arriving mail ballots routinely move margins
-- for a week or more after election night, and second place — the seat that decides who advances —
-- is exactly where a top-two race is most likely to flip. Culling 49 people off a November ballot on
-- a three-days-in count would be guessing dressed as a reconcile.
--
-- 🔑 GATE ON THE CANVASS DATE, NOT THE ELECTION DATE. This project already learned this once, in the
-- Arizona 2026 reconcile, which was deliberately blocked on the state canvass rather than the
-- 2026-07-21 election day. `provisional_until` was set here from the election date plus a day; the
-- honest value is the certification date plus a margin.
--
-- ---------------------------------------------------------------------------------------------------
-- THE QUEUE WAS ALSO UNDERCOUNTING, AGAIN
-- ---------------------------------------------------------------------------------------------------
-- Of the 69 rows on this shell, only 20 carried `provisional_until` — the ones seeded as
-- "Declared indep/minor-party". The other 49 were seeded as "qualified pre-primary field" with no
-- flag at all. But top-two makes NO distinction between a major-party candidate and an independent:
-- Suzan DelBene and Pramila Jayapal are on this shell on exactly the same footing as everyone else,
-- and 8 of the 10 districts have more than two candidates. The whole shell is pre-primary; the whole
-- shell needs the cull.
--
-- This is the third time in this sweep that the flagged rows were a subset of the broken rows
-- (Virginia 8-of-21, Kansas 26-of-26-but-2-unflagged-classes, now Washington 20-of-69). Rather than
-- leave 49 rows invisible until someone notices, they are stamped so the queue reports the real
-- number.
-- ---------------------------------------------------------------------------------------------------

-- Re-date the 20 already-flagged rows to the certification they actually depend on.
UPDATE essentials.race_candidates
   SET provisional_until = '2026-08-24',
       source = source || ' | 2026-08-07 hold: NOT culled. WA runs a top-two primary and the'
                       || ' 2026-08-04 count is not certified until 2026-08-18 (county canvass) /'
                       || ' 2026-08-21 (Secretary of State). The 2026-08-05 date was set from'
                       || ' election day, not the canvass. Re-dated to 2026-08-24 by migration 1577.'
 WHERE race_id IN (SELECT id FROM essentials.races
                    WHERE election_id = '51e7a875-bff9-4e96-adcf-41736454d25d')
   AND provisional_until IS NOT NULL;

-- Bring the 49 unflagged rows into the queue: under top-two they are provisional too.
UPDATE essentials.race_candidates
   SET provisional_until = '2026-08-24',
       source = source || ' | 2026-08-07: flagged provisional by migration 1577. WA is a TOP-TWO'
                       || ' primary, so a major-party candidate on this shell is exactly as'
                       || ' pre-primary as an independent — only two per district advance. Awaiting'
                       || ' the 2026-08-21 state certification of the 2026-08-04 primary.'
 WHERE race_id IN (SELECT id FROM essentials.races
                    WHERE election_id = '51e7a875-bff9-4e96-adcf-41736454d25d')
   AND provisional_until IS NULL;

-- ---------------------------------------------------------------------------------------------------
-- ▶ WORK OWED AFTER 2026-08-21
-- ---------------------------------------------------------------------------------------------------
-- For each of the 10 districts, take the certified top two from the WA SoS results and mark every
-- other row `result = 'not_nominated'` with a results citation. Expected scale: 69 rows in, 20 out,
-- ~49 marked. Districts with more than two candidates today: 1 (7), 3 (9), 4 (12), 5 (13), 6 (5),
-- 7 (4), 8 (6), 9 (5), 10 (5); district 2 has 4.
