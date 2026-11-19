-- CA_0396 — seat the 33 Indiana legislators whose terms began on 2026-11-04 and are still missing.
--
-- WHY. Indiana legislators take office the day after the general election: "Senators shall be
--   elected for the term of four years, and Representatives for the term of two years, from the day
--   next after their general election" (Indiana Constitution, Art. 4 §3). CA_0374 seated four seats
--   on that basis (House 45, 62, 63, Senate 39). On 2026-11-18 our API still showed the member who
--   left on 2026-11-03 on 33 more seats — e.g. Fishers returned Kyle Walker for Senate 31 and the
--   Statehouse returned Andrea Hunley for Senate 46. Found while building an Indiana page that had
--   to read the member list from the legislature instead of from us.
--   ⚠ The brief that started this said "only 18 of 150 Indiana seats exist". That was a query bug,
--   not a data gap: districts.state holds 'IN' on 18 legislative districts and 'in' on the other
--   132. All 150 offices exist, all held. A filter on state = 'IN' sees 18.
--
-- SOURCE. The General Assembly's own roster, which says who HOLDS each seat (not who won a count):
--     GET https://api.iga.in.gov/2027/legislators  (x-api-key / IGA_API_KEY), read 2026-11-18,
--     itemCount 150, one member per district.
--   Cross-checked against GET https://api.iga.in.gov/2026/legislators, read the same day: our
--   holders matched the 2026-session roster on all 150 seats except the four CA_0374 already moved.
--   So every one of the 33 changes below is the 2026 → 2027 turnover, nothing mid-term.
--   Each incoming term's source carries the member's own 2027 roster URL.
--
-- HOW IT IS MODELLED. Each seat: seat_officeholder(office, member, 2026-11-04, ..., 'elected', 'day',
--   'term_expired'). The helper closes the outgoing term at 2026-11-03.
--   ⚠ how_ended is 'term_expired' for all 33. That is true of every one of them; WHY each did not
--   return (retired, lost a primary, lost the general, ran for another office) was not read seat by
--   seat, and this file does not claim it. 'defeated'/'retired' would each be wrong somewhere.
--   ⚠ how_started 'elected' rests on the roster, not on a read result. No 2026 general-election race
--   exists in our data for any of these 33 seats (Indiana's legislative races were never loaded; see
--   CC_0381, "IN 4 races"), so there is no candidacy row to mark won and none is written.
--
-- WHO. Matched to existing people before anyone is created (3-letter first-name prefix + surname):
--   16 reused —
--     13 inactive 'indiana_discovery' rows (created 2026-05-22, no terms, no races): Natasha Baker,
--        Wesley Bennett (roster "Wes"), Racheal Bleicher, William Colteryahn, Paula Davis, Lindsay
--        Gramlich, Gabrianna Gratzol, Scott Houldieson, Ryan Kominakis, Nicholas Neal (roster
--        "Nick"), Tracey Powell, Tiffany Stoner, Stephanie Yocum. This is how CA_0374 found Streeter,
--        Kippenbrock and Ellington.
--     3 active: Michelle Davis (moves from House 58, which John Reed takes in this same file, to
--        Senate 41); Kerry Forestal (holds the Marion County Sheriff office in our data) and Allissa
--        Impink (holds IPS board District 4). Those two local seats are settled in CA_0397, a
--        separate file: one migration per file.
--   17 new, none with an active or inactive namesake anywhere in essentials.politicians (checked
--   2026-11-18 with a positive control): David Boyd, Lauren Cole, Blake Fiechter, Scott Fluhr, Sara
--   Gullion, Michele Henry, Jarren Hurt, Julie McGill, Misti Meehan, Kristina Moorhead, Chris
--   Parker, John Reed, Randy Retter, Eva Rosberg, Jay Starkey, Kim Townsend, Alex Wait.
--   Names are written as the roster prints them; no middle names were read.
--
-- 🔴 PRIOR VALUES (an UPDATE is final; there is no history table). Measured on production 2026-11-18.
--   politicians.is_active was FALSE on the 13 reused 'indiana_discovery' rows listed above and is set
--   TRUE here; it was already true on Michelle Davis, Kerry Forestal and Allissa Impink.
--   The 33 outgoing terms are open (term_end NULL). seat_officeholder fills how_ended only when NULL.
--   office_terms.source values are appended to, never replaced. Party is not written (132 of the
--   150 sitting Indiana legislators carry none; party lives on races.primary_party).
--
-- NOT WRITTEN. No race, candidacy, transition-tracker or headshot row. The deprecated
--   politicians.office_id snapshot. Party. Any change to the outgoing members' is_active.
--   Every office stays unflagged: all 33 were held before and are held after, so the 238
--   unflagged-drift baseline cannot move.
--
-- Idempotent: seat_officeholder is idempotent on (office, person, start); the insert, source
-- appends and flag writes are guarded on the values they change. The pre-gate accepts the end state.

-- Applied to production 2026-11-18 with apply-migration-file.mjs: 17 people inserted, 33 terms closed
-- at 2026-11-03, 33 opened from 2026-11-04, 13 discovery rows set active. Afterwards all 150 Indiana
-- legislative seats matched the 2027 roster, the unflagged drift baseline read 238 (total/flagged/
-- unflagged 286/48/238), check:incumbency read 0 drift rows, check:seating held, and
-- check:duplicate-people found no new pair. The live coordinate lookup returned Impink (Senate 46) at
-- the Statehouse and Forestal (Senate 31) in Fishers.

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- The plan. Generated from the two roster reads above; reuse_id NULL means "insert a new person".
-- ---------------------------------------------------------------------------------------------
CREATE TEMP TABLE ca0396_seats ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('5f584301-def4-4b05-bba8-e017dc2273e0'::uuid, 'State House District 4', '79bb9e5a-a74a-44ef-a1c4-5b956ad36e5e'::uuid, 'Edmond Soliday', 'Ryan Kominakis', 'Ryan', 'Kominakis', 'c4e35129-c551-40d6-909c-5d548b8d1f4a'::uuid, 'https://api.iga.in.gov/2027/legislators/ryan_kominakis_1'),
  ('74994b69-aba7-4c30-9e2b-0ab9a4e89f54'::uuid, 'State House District 5', 'eae88f55-a772-4aa7-9bae-8bc4e6c55ced'::uuid, 'Dale Devon', 'Alex Wait', 'Alex', 'Wait', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/alex_wait_1'),
  ('d59ccbcd-abf2-4d11-89dd-c3ea056046d7'::uuid, 'State House District 19', 'befd0035-e611-4d14-9da9-227156bb2c10'::uuid, 'Julie Olthoff', 'Nick Neal', 'Nick', 'Neal', '347c367c-ec8c-44c5-8b92-85ac13c8986a'::uuid, 'https://api.iga.in.gov/2027/legislators/nick_neal_1'),
  ('973e4fed-bfdb-44a1-82b0-415e3c8057df'::uuid, 'State House District 24', '452300b4-c6da-4866-be08-7462421673f1'::uuid, 'Hunter Smith', 'Racheal Bleicher', 'Racheal', 'Bleicher', '228786e5-8dd0-4be4-ae94-5ebdf286e198'::uuid, 'https://api.iga.in.gov/2027/legislators/racheal_bleicher_1'),
  ('441a4e01-78a9-479c-a215-8ce67033a772'::uuid, 'State House District 25', '445af4b4-7d6f-4d11-8e7c-a629113604b7'::uuid, 'Becky Cash', 'Tiffany Stoner', 'Tiffany', 'Stoner', 'ebd339e5-0b0a-4b54-9f32-fd2954098566'::uuid, 'https://api.iga.in.gov/2027/legislators/tiffany_stoner_1'),
  ('6941c0bb-eb53-4312-b370-2d17df4fd3b7'::uuid, 'State House District 30', '9c4aa310-5706-42e8-b3f1-b5dee9b6f6fa'::uuid, 'Michael Karickhoff', 'Paula Davis', 'Paula', 'Davis', 'c2ea11d6-b6a8-45b4-8dcb-b9d80e955123'::uuid, 'https://api.iga.in.gov/2027/legislators/paula_davis_1'),
  ('e2318196-2db7-40d6-b8e3-142e52475926'::uuid, 'State House District 34', '627467eb-e823-4bf1-b97d-026a36d55f43'::uuid, 'Sue Errington', 'Sara Gullion', 'Sara', 'Gullion', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/sara_gullion_1'),
  ('4aec3e97-8522-40a6-8e81-588908fc20e6'::uuid, 'State House District 36', 'aa2ee278-9763-4a30-90a9-9231331ac129'::uuid, 'Kyle Pierce', 'Kim Townsend', 'Kim', 'Townsend', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/kim_townsend_1'),
  ('c662f892-d685-4c9b-9461-2ca0d26e60a3'::uuid, 'State House District 37', 'd2b8e2ab-dc6b-42a9-9aea-b6b661e0476e'::uuid, 'Todd Huston', 'Lauren Cole', 'Lauren', 'Cole', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/lauren_cole_1'),
  ('acab121f-1cfa-44b4-bb4b-d0d6f8c06413'::uuid, 'State House District 39', 'fed420a8-8d89-48d2-bccc-62ba0a330237'::uuid, 'Danny Lopez', 'Lindsay Gramlich', 'Lindsay', 'Gramlich', '9ad1db62-bd80-4aa1-a59c-63be14917321'::uuid, 'https://api.iga.in.gov/2027/legislators/lindsay_gramlich_1'),
  ('88ca1f76-e2b8-4f75-ad29-1e36cefa6cee'::uuid, 'State House District 40', '946f7bc2-48ed-447e-a9a5-cb99aae00b31'::uuid, 'Gregory Steuerwald', 'William Colteryahn', 'William', 'Colteryahn', '15a1a3f8-10e5-4c08-93be-af38f7a71e00'::uuid, 'https://api.iga.in.gov/2027/legislators/william_colteryahn_1'),
  ('6f1c705d-0db3-47b9-b59b-3b5be294338f'::uuid, 'State House District 56', '64652750-ddd9-434f-b869-e95290d9eea4'::uuid, 'Brad Barrett', 'Randy Retter', 'Randy', 'Retter', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/randy_retter_1'),
  ('791af72a-df9d-4521-878c-0bba6f9fbd11'::uuid, 'State House District 57', 'a8ef5f09-5bd2-4acb-9e83-549466878901'::uuid, 'Craig Haggard', 'Wes Bennett', 'Wes', 'Bennett', 'f3c7b671-a50a-4d3a-9e60-7a169a2aeb21'::uuid, 'https://api.iga.in.gov/2027/legislators/wes_bennett_1'),
  ('582c74bf-443a-442a-9c7b-e612480c3dd4'::uuid, 'State House District 58', '2f768304-a6f6-4b5a-b41d-000727f225a1'::uuid, 'Michelle Davis', 'John Reed', 'John', 'Reed', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/john_reed_1'),
  ('49a53ab9-754c-4871-81be-303e29557c87'::uuid, 'State House District 70', '066daefa-0c25-447b-8a80-e4007ee3103d'::uuid, 'Karen Engleman', 'Scott Fluhr', 'Scott', 'Fluhr', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/scott_fluhr_1'),
  ('96d9e3b2-b607-4c64-bcbf-e2e0fedb0bf9'::uuid, 'State House District 72', 'f58ce6de-755d-448f-9c0c-b21f9d386dad'::uuid, 'Edward Clere', 'Michele Henry', 'Michele', 'Henry', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/michele_henry_1'),
  ('7f3aa504-262d-4509-aabf-f2e8cac682b1'::uuid, 'State House District 84', 'fb5368e7-35c6-4ae0-b97b-b2e1fb5fb9a6'::uuid, 'Robert Morris', 'Misti Meehan', 'Misti', 'Meehan', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/misti_meehan_1'),
  ('e7d4ab8d-c4b9-40c9-a606-20de622fc1e8'::uuid, 'State House District 88', '4e30ee0d-4b36-4337-889e-7a26e1fff510'::uuid, 'Chris Jeter', 'Stephanie Yocum', 'Stephanie', 'Yocum', '2938f29e-8356-4280-baf6-e2b5e4f2540f'::uuid, 'https://api.iga.in.gov/2027/legislators/stephanie_yocum_1'),
  ('f2d497b2-005e-4a6d-8abf-fe5459254537'::uuid, 'State House District 90', 'c68d71a3-1ed0-4f20-804e-8d39fe0930e9'::uuid, 'Andrew Ireland', 'David Boyd', 'David', 'Boyd', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/david_boyd_1'),
  ('dd704aff-ea11-4e9c-a290-3debbe40671e'::uuid, 'State House District 91', '5922a7c4-65a4-46da-acb2-6df183e596b2'::uuid, 'Robert Behning', 'Jarren Hurt', 'Jarren', 'Hurt', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/jarren_hurt_1'),
  ('724bbb31-22d9-4cda-b126-4bbea4621b75'::uuid, 'State House District 93', 'cfcb73c9-7689-4df6-b29f-0a8112af1336'::uuid, 'Julie Mcguire', 'Eva Rosberg', 'Eva', 'Rosberg', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/eva_rosberg_1'),
  ('f6e34822-a2f9-4dc2-a289-61df36a1a98a'::uuid, 'State Senate District 1', 'b2b02a48-c4e0-4acd-a4c4-b0aecbba7a18'::uuid, 'Dan Dernulc', 'Scott Houldieson', 'Scott', 'Houldieson', 'fb9b5604-3963-49de-bed7-3150903c146a'::uuid, 'https://api.iga.in.gov/2027/legislators/scott_houldieson_1'),
  ('e07feaea-4d6f-4167-a8b9-1ae9180f0ff8'::uuid, 'State Senate District 6', '6e1a895d-a956-4806-8938-4977e34cac9a'::uuid, 'Rick Niemeyer', 'Jay Starkey', 'Jay', 'Starkey', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/jay_starkey_1'),
  ('6eb6b42c-67f9-48a4-97af-65294cc842a7'::uuid, 'State Senate District 11', 'fe167afd-f670-4f13-9fee-2aa3fd6d048e'::uuid, 'Linda Rogers', 'Gabrianna Gratzol', 'Gabrianna', 'Gratzol', '9deb156e-8038-4dff-bae4-d3e4ff371681'::uuid, 'https://api.iga.in.gov/2027/legislators/gabrianna_gratzol_1'),
  ('670f8b2c-76f5-4f08-82a9-e71a423278d5'::uuid, 'State Senate District 15', 'cdae21e5-88a2-4c55-aaa5-abe050abf4a3'::uuid, 'Liz Brown', 'Julie McGill', 'Julie', 'McGill', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/julie_mcgill_1'),
  ('8d185c37-1e77-4a10-973f-1ea8559983c4'::uuid, 'State Senate District 17', 'c348cec4-a31b-419e-8906-1f1b4dfaaff3'::uuid, 'Nick McKinley', 'Chris Parker', 'Chris', 'Parker', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/chris_parker_1'),
  ('8d0b1e43-d2c5-4c83-8f73-566bc82237e0'::uuid, 'State Senate District 19', '8b98d8e9-c41c-4722-80de-3bc5192656ee'::uuid, 'Travis Holdman', 'Blake Fiechter', 'Blake', 'Fiechter', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/blake_fiechter_1'),
  ('61108337-2703-425b-8504-c3433eaaf2d1'::uuid, 'State Senate District 21', '6280a36a-9c26-4c22-a0d8-3ac06693fbfb'::uuid, 'James Buck', 'Tracey Powell', 'Tracey', 'Powell', 'cfa043c0-3be3-47b6-bc71-f61e77c678d2'::uuid, 'https://api.iga.in.gov/2027/legislators/tracey_powell_1'),
  ('32e7397b-3825-487b-b2cf-6760bb213541'::uuid, 'State Senate District 22', '27844ca9-5243-48e1-8053-c3ef4e12c0fe'::uuid, 'Ron Alting', 'Natasha Baker', 'Natasha', 'Baker', 'd28881ad-377f-41dd-8da2-a1660d238119'::uuid, 'https://api.iga.in.gov/2027/legislators/natasha_baker_1'),
  ('b4ab3354-c6e8-4a29-8aae-938ec2da84dd'::uuid, 'State Senate District 29', '5e7e232c-25e2-46ea-a511-4b9a7ab58b21'::uuid, 'J.D. Ford', 'Kristina Moorhead', 'Kristina', 'Moorhead', NULL::uuid, 'https://api.iga.in.gov/2027/legislators/kristina_moorhead_1'),
  ('60f81720-a5c5-4ee3-ad17-b83a73f63f58'::uuid, 'State Senate District 31', 'eb94127d-d394-4704-a53b-1efb2db3bc60'::uuid, 'Kyle Walker', 'Kerry Forestal', 'Kerry', 'Forestal', '71ee4905-3eac-4b8b-8890-322edcad7517'::uuid, 'https://api.iga.in.gov/2027/legislators/kerry_forestal_1'),
  ('9ef15737-c7a4-4782-9fda-408da7bc1642'::uuid, 'State Senate District 41', 'e93bb9f1-8f60-4f56-a492-0e40d7d49647'::uuid, 'Greg Walker', 'Michelle Davis', 'Michelle', 'Davis', '2f768304-a6f6-4b5a-b41d-000727f225a1'::uuid, 'https://api.iga.in.gov/2027/legislators/michelle_davis_1'),
  ('f30271df-0d04-4c78-8479-1862c46a4b40'::uuid, 'Indiana State Senate - District 46', '3def4add-c5bb-44df-95af-ea2de6899b6c'::uuid, 'Andrea Hunley', 'Allissa Impink', 'Allissa', 'Impink', '7c709450-21ee-41dd-9f45-08c860af7f5d'::uuid, 'https://api.iga.in.gov/2027/legislators/allissa_impink_1')
) v(office_id, seat, outgoing_id, outgoing_name, incoming_name, first_name, last_name, reuse_id, roster_url);

-- ---------------------------------------------------------------------------------------------
-- Pre-gate: every seat is still in the state this was written against (or already the end state).
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad text; v_n int;
BEGIN
  IF (SELECT count(*) FROM ca0396_seats) <> 33
     OR (SELECT count(DISTINCT office_id) FROM ca0396_seats) <> 33 THEN
    RAISE EXCEPTION 'CA_0396 pre-gate: the plan is not 33 distinct seats';
  END IF;

  -- Each office is an Indiana legislative seat; the outgoing member holds it open-ended (before)
  -- or through 2026-11-03 (a re-run).
  SELECT string_agg(s.seat || ' / ' || s.outgoing_name, '; ') INTO v_bad
    FROM ca0396_seats s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.offices f
                       JOIN essentials.districts d ON d.id = f.district_id
                      WHERE f.id = s.office_id AND lower(d.state) = 'in'
                        AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER'))
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians p
                      WHERE p.id = s.outgoing_id AND p.full_name = s.outgoing_name)
      OR NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                      WHERE t.office_id = s.office_id AND t.politician_id = s.outgoing_id
                        AND (t.term_end IS NULL OR t.term_end = '2026-11-03'));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0396 pre-gate: seat not in the expected state: %', v_bad;
  END IF;

  -- Nobody else holds any of these seats on or after 2026-11-04, except this file on a re-run.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t JOIN ca0396_seats s ON s.office_id = t.office_id
   WHERE t.politician_id IS DISTINCT FROM s.outgoing_id
     AND (t.term_end IS NULL OR t.term_end >= '2026-11-04')
     AND coalesce(t.source, '') NOT LIKE 'CA_0396:%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0396 pre-gate: % other term(s) already cover these seats after 2026-11-03 — another session may have seated them', v_n;
  END IF;

  -- No seat is flagged vacant (the helper would not clear it).
  SELECT count(*) INTO v_n
    FROM essentials.offices f JOIN ca0396_seats s ON s.office_id = f.id
   WHERE f.is_vacant OR f.vacant_since IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0396 pre-gate: % seat(s) flagged vacant', v_n; END IF;

  -- Each reused row exists and carries the roster surname and a matching first-name prefix.
  SELECT string_agg(s.incoming_name, ', ') INTO v_bad
    FROM ca0396_seats s
   WHERE s.reuse_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.politicians p
                      WHERE p.id = s.reuse_id
                        AND lower(p.last_name) = lower(s.last_name)
                        AND left(lower(p.first_name), 3) = left(lower(s.first_name), 3));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0396 pre-gate: reuse_id missing or names someone else: %', v_bad;
  END IF;

  -- A reused row holds no current seat except the ones this plan or CA_0397 settles: Michelle Davis
  -- on House 58 (closed by this file), Forestal's sheriff office and Impink's IPS seat (CA_0397).
  SELECT string_agg(s.incoming_name || ' holds ' || f.title, '; ') INTO v_bad
    FROM ca0396_seats s
    JOIN essentials.office_current_holder och ON och.politician_id = s.reuse_id
    JOIN essentials.offices f ON f.id = och.office_id
   WHERE och.office_id NOT IN (SELECT office_id FROM ca0396_seats)
     AND och.office_id NOT IN ('ad15e649-a298-4333-9569-cdf72b48a0ee',   -- Marion County Sheriff
                               '763f6b8e-122a-4f30-bf20-4446e2a9e909');  -- IPS School Board District 4
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0396 pre-gate: a reused person already holds another seat: %', v_bad;
  END IF;

  -- A new person must not already exist (3-letter prefix + surname), unless this file made it.
  SELECT string_agg(format('%s (existing: %s %s source=%s)', s.incoming_name, p.id, p.full_name,
                           coalesce(p.source, '∅')), '; ')
    INTO v_bad
    FROM ca0396_seats s
    JOIN essentials.politicians p
      ON lower(p.last_name) = lower(s.last_name)
     AND left(lower(p.first_name), 3) = left(lower(s.first_name), 3)
   WHERE s.reuse_id IS NULL
     AND coalesce(p.source, '') NOT LIKE 'CA_0396 %';
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0396 pre-gate: a same-name person already exists — decide reuse or a different person: %', v_bad;
  END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
-- The 17 new people (only once).
-- ---------------------------------------------------------------------------------------------
INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_appointed, source)
SELECT s.incoming_name, s.first_name, s.last_name, true, false,
       'CA_0396 Indiana ' || s.seat || ', member of the 2027 General Assembly from 2026-11-04 ('
       || s.roster_url || ', read 2026-11-18)'
  FROM ca0396_seats s
 WHERE s.reuse_id IS NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.politicians p
                    WHERE p.last_name = s.last_name AND p.first_name = s.first_name
                      AND p.source LIKE 'CA_0396 %');

ALTER TABLE ca0396_seats ADD COLUMN incoming_id uuid;

UPDATE ca0396_seats s
   SET incoming_id = coalesce(s.reuse_id,
                              (SELECT p.id FROM essentials.politicians p
                                WHERE p.last_name = s.last_name AND p.first_name = s.first_name
                                  AND p.source LIKE 'CA_0396 %'));

CREATE TEMP TABLE ca0396_people ON COMMIT DROP AS
SELECT outgoing_id AS politician_id FROM ca0396_seats
UNION
SELECT incoming_id FROM ca0396_seats;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM ca0396_seats WHERE incoming_id IS NULL) THEN
    RAISE EXCEPTION 'CA_0396: a member did not resolve to a person: %',
      (SELECT string_agg(incoming_name, ', ') FROM ca0396_seats WHERE incoming_id IS NULL);
  END IF;
  -- 33 outgoing + 33 incoming, less Michelle Davis who is both.
  IF (SELECT count(*) FROM ca0396_people WHERE politician_id IS NOT NULL) <> 65 THEN
    RAISE EXCEPTION 'CA_0396: expected 65 people in scope, found %', (SELECT count(*) FROM ca0396_people);
  END IF;
END $$;

-- ▼▼ BLOCK A — PASTE BEFORE YOUR FIRST WRITE TO essentials.office_terms ▼▼

-- @incumbency-decision: gated — closes 33 outgoing Indiana legislators at 2026-11-03 and seats 33 members from 2026-11-04; any 2026 race row of anyone in scope (e.g. Michelle Davis, who leaves House 58 for Senate 41) is checked for a new contradiction

-- Snapshot what the cached column says, and what office_terms says, for every race row belonging to
-- a person this migration touches. `expected` is reconcile-incumbency.mjs's own SQL.
--
-- ⚠ KEEP THE `expected` EXPRESSION AND THE THREE WHERE CLAUSES CHARACTER-IDENTICAL TO THE SCRIPT
-- (backend/scripts/reconcile-incumbency.mjs, computeIncumbencyDrift). If they drift apart, this
-- passes while CI fails, which is worse than having no guard — you would then believe the question
-- had been asked.
CREATE TEMP TABLE incumbency_before ON COMMIT DROP AS
SELECT rc.id              AS race_candidate_id,
       rc.politician_id,
       rc.is_incumbent    AS stored,
       EXISTS (SELECT 1 FROM essentials.office_terms t
                 JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id
                  AND (t.office_id = r.office_id
                       OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
              )            AS expected
  FROM essentials.race_candidates rc
  JOIN essentials.races     r  ON r.id  = rc.race_id
  JOIN essentials.offices   ro ON ro.id = r.office_id
  JOIN essentials.elections e  ON e.id  = r.election_id
 WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
   AND rc.politician_id IS NOT NULL
   AND rc.politician_id IN (SELECT politician_id FROM ca0396_people);

-- 🔴 `o2` IS THE SCRIPT'S OWN ALIAS AND IT IS A TRAP. Never write `o2.politician_id` anywhere near
-- this block. `check:occupancy` reads `o<digits>.politician_id` as the dropped essentials.offices
-- column — that is the repo's offices alias convention — and CC_0394 turned the "static guards" job
-- red on exactly that. Here `o2` is only ever read for `chamber_id`, which is safe. Rename it to
-- something not starting with `o` if you need any other column off it.

-- ▲▲ END OF BLOCK A ▲▲

-- ---------------------------------------------------------------------------------------------
-- Write: seat each member from 2026-11-04 (closes the outgoing term at 2026-11-03).
-- ---------------------------------------------------------------------------------------------
SELECT s.seat, essentials.seat_officeholder(
         s.office_id, s.incoming_id, '2026-11-04',
         'CA_0396: member of the 2027 Indiana General Assembly for ' || s.seat || ' ('
           || s.roster_url || ', the legislature''s own roster, read 2026-11-18); term begins "from the day next after their general election" (Ind. Const. art. 4 §3)',
         'elected', 'day', 'term_expired')
  FROM ca0396_seats s
 ORDER BY s.seat;

-- Say on each closed term why it closed.
UPDATE essentials.office_terms t
   SET source = coalesce(t.source, '') || ' | CA_0396: not on the 2027 roster (https://api.iga.in.gov/2027/legislators, read 2026-11-18; '
                || s.incoming_name || ' holds ' || s.seat || '); term ended 2026-11-03 (Ind. Const. art. 4 §3)'
  FROM ca0396_seats s
 WHERE t.office_id = s.office_id
   AND t.politician_id = s.outgoing_id
   AND t.term_end = '2026-11-03'
   AND coalesce(t.source, '') NOT LIKE '%CA_0396:%';

-- The 13 reused discovery rows become active (prior value false, recorded in the header).
UPDATE essentials.politicians p
   SET is_active = true
  FROM ca0396_seats s
 WHERE p.id = s.incoming_id
   AND p.is_active IS DISTINCT FROM true;

-- ▼▼ BLOCK B — PASTE AFTER YOUR LAST WRITE TO essentials.office_terms, BEFORE COMMIT ▼▼

DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM ca0396_people;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;

  -- 🔴 AN EMPTY SCOPE PASSES EVERYTHING BELOW VACUOUSLY, AND IT HAS TWO OPPOSITE CAUSES. Either
  -- nobody you touched has run recently — the common, correct case — or your plan table is not the
  -- one the scope subquery reads, in which case this gate is switched off and looks identical.
  -- Counting the PLAN separately is what tells them apart: "4 planned, 0 with a race" is the first,
  -- "0 planned" is the second. Reading `incumbency_before` alone cannot distinguish them, which is
  -- how an earlier draft of this template reported a deliberately mis-pointed plan as fine.
  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the plan table is EMPTY, so this gate asserted nothing. '
      'Point it at the politicians whose office_terms rows this migration writes.';
  END IF;
  RAISE NOTICE 'incumbency guard: % person/people planned, % with a race row in the last year (% row(s))',
    v_planned, v_people, v_scoped;

  WITH after_state AS (
    SELECT rc.id              AS race_candidate_id,
           rc.is_incumbent    AS stored,
           EXISTS (SELECT 1 FROM essentials.office_terms t
                     JOIN essentials.offices o2 ON o2.id = t.office_id
                    WHERE t.politician_id = rc.politician_id
                      AND (t.office_id = r.office_id
                           OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                      AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                      AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
                  )            AS expected
      FROM essentials.race_candidates rc
      JOIN essentials.races     r  ON r.id  = rc.race_id
      JOIN essentials.offices   ro ON ro.id = r.office_id
      JOIN essentials.elections e  ON e.id  = r.election_id
     WHERE rc.id IN (SELECT race_candidate_id FROM incumbency_before)
  ),
  cmp AS (
    SELECT b.race_candidate_id,
           b.politician_id,
           a.stored,
           a.expected,
           (b.stored IS DISTINCT FROM b.expected) AS drifted_before,
           (a.stored IS DISTINCT FROM a.expected) AS drifted_after
      FROM incumbency_before b
      JOIN after_state a USING (race_candidate_id)
  )
  SELECT count(*) FILTER (WHERE NOT c.drifted_before AND c.drifted_after),
         count(*) FILTER (WHERE c.drifted_before AND NOT c.drifted_after),
         string_agg(
           format('    %s — race_candidate %s says is_incumbent=%s, office_terms now say %s',
                  coalesce(p.full_name, '(unnamed)'), c.race_candidate_id, c.stored, c.expected),
           E'\n' ORDER BY coalesce(p.full_name, ''))
           FILTER (WHERE NOT c.drifted_before AND c.drifted_after)
    INTO v_created, v_repaired, v_detail
    FROM cmp c
    LEFT JOIN essentials.politicians p ON p.id = c.politician_id;

  IF v_repaired > 0 THEN
    RAISE NOTICE 'incumbency guard: % race row(s) that drifted BEFORE this migration now agree with office_terms', v_repaired;
  END IF;

  IF v_created > 0 THEN
    RAISE EXCEPTION E'incumbency guard: % race row(s) agreed with essentials.office_terms before this migration and contradict it now.\n%\n\nThis is what `check:incumbency` will say on the NEXT push to master, under somebody else''s name. Settle it here.\n  • Newcomer — the date is right and the race row is wrong. Set race_candidates.is_incumbent = false IN THIS MIGRATION.\n  • Re-elected — the race row is right and the DATE is wrong: you have written their latest term''s start as the start of their whole tenure. Leave term_start NULL, or write the real first term.\nThe two look identical from the predicate. Read the person. See CC_0396''s header for the worked split of seven such rows.',
      v_created, coalesce(v_detail, '    (no detail)');
  END IF;
END $$;

-- ▲▲ END OF BLOCK B ▲▲

-- ---------------------------------------------------------------------------------------------
-- Post-gate, on the end state.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad text; v_n int;
BEGIN
  -- Each seat resolves to exactly its member today.
  SELECT string_agg(s.seat || ' resolves to ' || coalesce(p.full_name, '(nobody)'), '; ') INTO v_bad
    FROM ca0396_seats s
    LEFT JOIN essentials.office_current_holder och ON och.office_id = s.office_id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE och.politician_id IS DISTINCT FROM s.incoming_id;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CA_0396 gate: %', v_bad; END IF;

  -- Each outgoing term is closed at 2026-11-03 with how_ended, and says why.
  SELECT count(*) INTO v_n
    FROM ca0396_seats s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                      WHERE t.office_id = s.office_id AND t.politician_id = s.outgoing_id
                        AND t.term_end = '2026-11-03' AND t.how_ended IS NOT NULL
                        AND t.source LIKE '%CA_0396:%');
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0396 gate: % outgoing term(s) not closed as described', v_n; END IF;

  -- Each member's term starts 2026-11-04, open-ended, elected, at day precision.
  SELECT count(*) INTO v_n
    FROM ca0396_seats s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                      WHERE t.office_id = s.office_id AND t.politician_id = s.incoming_id
                        AND t.term_start = '2026-11-04' AND t.term_end IS NULL
                        AND t.how_started = 'elected' AND t.start_precision = 'day');
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0396 gate: % member term(s) missing', v_n; END IF;

  -- Every member is active, and exactly 17 rows carry this file's source.
  SELECT count(*) INTO v_n
    FROM ca0396_seats s JOIN essentials.politicians p ON p.id = s.incoming_id
   WHERE p.is_active IS DISTINCT FROM true;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0396 gate: % member(s) not active', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians WHERE source LIKE 'CA_0396 %';
  IF v_n <> 17 THEN RAISE EXCEPTION 'CA_0396 gate: % CA_0396 person rows (expected 17)', v_n; END IF;

  -- No seat is flagged vacant.
  SELECT count(*) INTO v_n
    FROM essentials.offices f JOIN ca0396_seats s ON s.office_id = f.id
   WHERE f.is_vacant OR f.vacant_since IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0396 gate: % seat(s) flagged vacant', v_n; END IF;

  -- The whole legislature, both state-code spellings: 150 offices, 150 held, nobody on two seats.
  SELECT count(*) INTO v_n
    FROM essentials.offices f JOIN essentials.districts d ON d.id = f.district_id
    JOIN essentials.office_current_holder och ON och.office_id = f.id
   WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND och.politician_id IS NOT NULL;
  IF v_n <> 150 THEN RAISE EXCEPTION 'CA_0396 gate: % held Indiana legislative seats (expected 150)', v_n; END IF;

  SELECT count(*) INTO v_n FROM (
    SELECT och.politician_id
      FROM essentials.offices f JOIN essentials.districts d ON d.id = f.district_id
      JOIN essentials.office_current_holder och ON och.office_id = f.id
     WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
       AND och.politician_id IS NOT NULL
     GROUP BY och.politician_id HAVING count(*) > 1) x;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0396 gate: % person/people hold two Indiana legislative seats', v_n; END IF;
END $$;

COMMIT;
