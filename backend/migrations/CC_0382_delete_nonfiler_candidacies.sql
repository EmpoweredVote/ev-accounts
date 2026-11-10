-- CC_0382 — delete the seven candidacy rows that name somebody who took out nomination
--           papers for a Los Angeles County contest and never returned them.
--
-- WHY THIS FILE EXISTS. The Los Angeles RR/CC's candidate list publishes TWO dates per row:
--   nom_issue (papers taken out) and nom_file (papers returned and ACCEPTED). TAKING OUT PAPERS
--   IS NOT STANDING FOR ELECTION. The September seeding pass kept every name on that list,
--   filed or not, so production carries rows for people who were never candidates.
--   It is not cosmetic: Azusa Unified Area 3 showed TWO candidates for one seat, which made the
--   county's own cancellation of that election look impossible, and the same cause explains all
--   seven "not on the county ballot" and "contested yet cancelled" anomalies CC_0378 reported.
--   Full account: backend/data/ca-school-boards-2026-results/NOTES.md.
--
-- 🔴 THE DISPOSITION IS DELETE, NOT candidate_status = 'withdrew'. These people never filed, so
--   they never stood; "withdrew" is a false claim about somebody who did. That is the Troy
--   Nehls precedent (CC_0352), where the phantom candidacy was deleted and Chuck Edwards'
--   genuine withdrawal was recorded — the same shape, the opposite handling.
--   Operator's ruling, 2026-11-08: "Delete the 8 candidates if you're sure they never filed/ran."
--
-- 🔴🔴 IT IS SEVEN, NOT THE EIGHT THAT RULING NAMED. Re-verifying each row against the county's
--   RAW candidate list before deleting found that one of the eight was a DIFFERENT CONTEST:
--     RAYCINE ECTOR is NOT deleted. The county's non-filer of that name is on the PALMDALE
--     SCHOOL DISTRICT Governing Board, Trustee Area No. 5. The row we hold is PALMDALE CITY
--     COUNCIL, DISTRICT 5, and it cites the City of Palmdale City Clerk's *Final* Candidate
--     List — a source that says she qualified. The county's list carries NO Palmdale city
--     contest at all, because the city runs its own election. Same city, same number 5,
--     different office, and nothing about the school-board row is evidence about ours.
--   ▶ A NAME MATCH IS A HYPOTHESIS, AND THE SECOND HALF OF THAT SENTENCE IS "ASK WHICH CONTEST".
--     NOTES.md already carried this warning for Alfonso Morales and the same table got the very
--     next row wrong in the same way.
--
-- 🔴 EVERY VALUE THIS FILE DESTROYS IS WRITTEN DOWN HERE, because a DELETE is final, there is no
--   history table and no replayable runner. All seven carry result = NULL,
--   result_certainty = NULL, result_source = NULL, candidate_status = 'active',
--   is_write_in = false, photo_url = NULL.
--
--   rc_id                                 full_name            politician_id                         race / office
--   66ce5a47-667a-49e8-9a59-495046d73d63  Alan Reynolds        d870d032-755f-45e1-a8d8-3a793140aaea  South Pasadena Unified School Board - Trustee Area 4 / Board Member (Trustee Area 4)
--   324e48e3-eed6-4379-b418-56af9cda425e  Alfonso Morales      6c43482f-7ede-443a-aa87-072d1c555eb6  Lynwood Unified Board / Board Member
--   bff20d9a-37d8-4a94-9038-2ae791829998  Carissa Oldenburg    22b346de-8702-4513-a270-edca236ee3fe  Burbank Unified School Board - Trustee Area 4 / Board Member (Trustee Area 4)
--   a8a1af85-e78a-4f4d-b749-9a8d798b8215  Joe Radabaugh        42a6fdbb-efdd-4980-92f7-d878dd5d5cbf  La Canada Unified Board / Board Member
--   b1368c8a-1317-49e2-bb74-5e990ad27c59  Rick Phillips        cbb63cbf-135b-4e8c-8f16-a4e31f8a9f51  Palos Verdes Peninsula Unified Board / Board Member
--   9d0cf7f6-f6d4-4f6f-b86e-d5bd4c00fca6  Tavia Lorese Lawson  4a5a49a6-1a67-49b6-b1c3-ee6443872bbd  Azusa Unified School Board - Trustee Area 3 / Board Member (Trustee Area 3)
--   55953217-f94d-4560-a629-60914886edda  Tomas Ursua          603d3838-9eea-4b4c-ba0a-4661401ed945  Pomona Unified School Board - Trustee Area 1 / Board Member (Trustee Area 1)
--
--   Six carry the RR/CC candidate-list source string
--     'LA County Registrar-Recorder, Nov 3 2026 General Election certified candidate list
--      (lavote.gov/Apps/CandidateList/Index?id=4348). Retrieved 2026-09-22.'
--   and the three whole-board seats (Lynwood, La Cañada, Palos Verdes) carry that string with
--     '; seats per LACOE Informational Bulletin 7112 (2026-04-02)' before 'Retrieved'.
--
-- THE EVIDENCE, re-read from the primary source and not from this wave's derived file:
--   backend/data/ca-school-boards-2026-results/la-candidate-list-2026-11-08.html, the county's
--   own list, parsed by verify-nonfilers.mjs in the same directory. 505 candidate rows, of which
--   480 show a filing — that count is the POSITIVE CONTROL: without it, "none of these shows a
--   filing" would be indistinguishable from a parser that reads no dates at all. Each of the
--   seven matches exactly ONE row, on word boundaries, in the expected contest, with exactly one
--   date. ⚠ A bare substring match is not a name match: "Ector" is inside "Director" and matched
--   118 rows before the boundaries were added.
--
-- 🔴 ALFONSO MORALES HOLDS A SECOND CANDIDACY AND IT MUST SURVIVE.
--   5ca34dfd-f70e-4078-ad0a-cd38c70c0918 — City of Lynwood, At-Large Council Member — comes from
--   the CITY's own Qualified Candidate Filing List, a different office and a source that says
--   qualified. A gate below names it and asserts it is still there afterwards.
--
-- 🔴 NO PERSON IS DELETED. essentials.politicians rows are archived, never deleted (five of the
--   seven have no other candidacy and no term, so they become people this election no longer
--   references). Deleting them is a separate judgement nobody has asked for, and CLAUDE.md warns
--   that other subsystems hold placeholder candidates. Joe Radabaugh additionally HOLDS AN
--   OFFICE TERM and is a sitting official; only his phantom candidacy goes.
--
-- 🔴 THE ONLY INBOUND FOREIGN KEY IS essentials.candidate_staging.matched_candidate_id, and it
--   is NO ACTION — so a staging row pointing at one of these would ABORT this delete rather than
--   cascade. Measured: zero point at any of the seven. The gate re-asserts that in-transaction.
--
-- Slot CC_0382 reserved via steward. Applied to production 2026-11-__ by Chris Cantrell.

BEGIN;

-- ─── 1. What is being deleted ───
CREATE TEMP TABLE doomed (
  rc_id      uuid PRIMARY KEY,
  full_name  text NOT NULL,
  contest    text NOT NULL,   -- the county contest whose list shows papers issued and not filed
  nom_issue  date NOT NULL    -- the only date the county publishes for this person
) ON COMMIT DROP;

INSERT INTO doomed (rc_id, full_name, contest, nom_issue) VALUES
  ('9d0cf7f6-f6d4-4f6f-b86e-d5bd4c00fca6'::uuid, 'Tavia Lorese Lawson', 'AZUSA UNIFIED SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3', DATE '2026-07-16'),
  ('bff20d9a-37d8-4a94-9038-2ae791829998'::uuid, 'Carissa Oldenburg',   'BURBANK UNIFIED SCHOOL DISTRICT Governing Board Member, Trustee Area No. 4', DATE '2026-08-04'),
  ('66ce5a47-667a-49e8-9a59-495046d73d63'::uuid, 'Alan Reynolds',       'SOUTH PASADENA UNIFIED SCHOOL DISTRICT Governing Board Member, Trustee Area No. 4', DATE '2026-07-24'),
  ('a8a1af85-e78a-4f4d-b749-9a8d798b8215'::uuid, 'Joe Radabaugh',       'LA CAÑADA UNIFIED SCHOOL DISTRICT Governing Board Member', DATE '2026-07-14'),
  ('324e48e3-eed6-4379-b418-56af9cda425e'::uuid, 'Alfonso Morales',     'LYNWOOD UNIFIED SCHOOL DISTRICT Governing Board Member', DATE '2026-07-31'),
  ('b1368c8a-1317-49e2-bb74-5e990ad27c59'::uuid, 'Rick Phillips',       'PALOS VERDES PENINSULA UNIFIED SCHOOL DISTRICT Governing Board Member', DATE '2026-07-13'),
  ('55953217-f94d-4560-a629-60914886edda'::uuid, 'Tomas Ursua',         'POMONA UNIFIED SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1', DATE '2026-07-27');

-- Rows that MUST survive. A delete is judged by what it leaves as much as by what it removes.
CREATE TEMP TABLE must_survive (
  rc_id uuid PRIMARY KEY,
  why   text NOT NULL
) ON COMMIT DROP;
INSERT INTO must_survive (rc_id, why) VALUES
  ('5ca34dfd-f70e-4078-ad0a-cd38c70c0918'::uuid, 'Alfonso Morales, City of Lynwood At-Large Council Member — the CITY''s own Qualified Candidate Filing List, a different office and a source that says qualified'),
  ('35cf1184-43c9-424a-a557-7c2c8a6d4807'::uuid, 'Raycine Ector, Palmdale CITY COUNCIL District 5 — the county''s non-filer of that name is on the Palmdale SCHOOL DISTRICT board; the county runs no Palmdale city contest at all');

CREATE TEMP TABLE before_image AS
  SELECT rc.id AS rc_id, rc.full_name, rc.politician_id, rc.result, rc.result_certainty,
         rc.candidate_status, rc.race_id, rc.source
    FROM essentials.race_candidates rc
    JOIN doomed d ON d.rc_id = rc.id;

-- ─── 2. Everything that must be true before a single row is removed ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM doomed;
  IF n <> 7 THEN RAISE EXCEPTION 'expected 7 rows to delete, the file carries %', n; END IF;

  -- POSITIVE CONTROL: the before-image must actually see the rows, or every check below is
  -- a question asked of an empty table.
  SELECT count(*) INTO n FROM before_image;
  IF n <> 7 THEN RAISE EXCEPTION 'the before-image sees % of the 7 rows named — a gate that reads the wrong rows proves nothing', n; END IF;

  -- the pin must carry the name this file states
  SELECT string_agg(d.full_name || ' <> ' || b.full_name, ', ') INTO txt
    FROM doomed d JOIN before_image b ON b.rc_id = d.rc_id
   WHERE upper(b.full_name) <> upper(d.full_name);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'pinned rows do not carry the name this file states: %', txt; END IF;

  -- 🔴 NOTHING DECIDED MAY BE DELETED. A row carrying a result is a claim somebody recorded, and
  --   deleting it would destroy that claim rather than a phantom.
  SELECT string_agg(b.full_name || ' = ' || coalesce(b.result, '?'), ', ') INTO txt
    FROM before_image b WHERE b.result IS NOT NULL OR b.result_certainty IS NOT NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'rows named here already carry a result: %', txt; END IF;
  SELECT string_agg(b.full_name || ' = ' || coalesce(b.candidate_status, 'NULL'), ', ') INTO txt
    FROM before_image b WHERE coalesce(b.candidate_status, '') <> 'active';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'rows named here are not plain active candidacies: %', txt; END IF;

  -- 🔴 THE SOURCE MUST BE THE COUNTY'S LIST. That is what the evidence is about: a row seeded
  --   from a CITY's own qualified-candidate list is a different claim and is not this defect.
  SELECT string_agg(b.full_name, ', ') INTO txt
    FROM before_image b WHERE position('lavote.gov/Apps/CandidateList' in coalesce(b.source, '')) = 0;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'rows named here were not seeded from the county candidate list: %', txt; END IF;

  -- the rows that must survive have to exist BEFORE, or asserting they survive proves nothing
  SELECT count(*) INTO n FROM must_survive s JOIN essentials.race_candidates rc ON rc.id = s.rc_id;
  IF n <> 2 THEN RAISE EXCEPTION 'only % of the 2 must-survive rows exist — the survival gate would pass vacuously', n; END IF;
  SELECT count(*) INTO n FROM must_survive s JOIN doomed d ON d.rc_id = s.rc_id;
  IF n <> 0 THEN RAISE EXCEPTION 'a row listed as must-survive is also listed for deletion'; END IF;

  -- 🔴 THE ONLY INBOUND FK IS NO ACTION, so a staging row would abort this. Say so first.
  SELECT count(*) INTO n FROM essentials.candidate_staging cs JOIN doomed d ON d.rc_id = cs.matched_candidate_id;
  IF n <> 0 THEN RAISE EXCEPTION '% candidate_staging rows point at a row this file deletes', n; END IF;

  RAISE NOTICE 'pre-checks passed: deleting % phantom candidacies, 2 named rows must survive',
    (SELECT count(*) FROM doomed);
END $$;

-- ─── 3. The delete ───
DELETE FROM essentials.race_candidates rc USING doomed d WHERE rc.id = d.rc_id;

-- ─── 4. Post-verify ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN doomed d ON d.rc_id = rc.id;
  IF n <> 0 THEN RAISE EXCEPTION '% of the 7 rows are still present', n; END IF;

  -- 🔴 WHAT THE DELETE LEFT BEHIND IS HALF THE CLAIM
  SELECT string_agg(s.why, ' | ') INTO txt
    FROM must_survive s LEFT JOIN essentials.race_candidates rc ON rc.id = s.rc_id
   WHERE rc.id IS NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a row that had to survive was deleted: %', txt; END IF;

  -- NO PERSON MAY VANISH. politicians are archived, never deleted.
  SELECT count(*) INTO n FROM before_image b
    LEFT JOIN essentials.politicians p ON p.id = b.politician_id
   WHERE b.politician_id IS NOT NULL AND p.id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% people were removed — this file deletes candidacies, never people', n; END IF;

  -- and nothing else in these races may have gone with them
  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.race_id IN (SELECT race_id FROM before_image);
  IF n < 1 THEN RAISE EXCEPTION 'the affected races now hold no candidates at all'; END IF;

  -- 🟢 THE POINT OF THE EXERCISE: Azusa Unified Area 3 showed two candidates for one seat and
  --    the county had cancelled the election for insufficiency. It must now show one.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.race_id = '61cb3e5c-5a1e-420b-b3ed-2d07abc762dc'::uuid;
  IF n <> 1 THEN RAISE EXCEPTION 'Azusa Unified Area 3 holds % candidacies, expected exactly 1 after this file', n; END IF;

  RAISE NOTICE 'CC_0382 done: 7 phantom candidacies deleted, 2 named rows survive, 0 people removed';
END $$;

DROP TABLE IF EXISTS before_image;
DROP TABLE IF EXISTS must_survive;

COMMIT;
