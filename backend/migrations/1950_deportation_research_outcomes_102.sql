-- 1950_deportation_research_outcomes_102.sql
--
-- WHAT THIS IS
-- 102 active politicians hold a non-zero Season 1 `immigration` stance, were researched on a live
-- successor topic (`deportation` or `local-immigration`) and were BLANKED there. `immigration` has
-- no Season 2 pin, so nothing of theirs on this subject reaches a voter: the compass draws no spoke
-- and the citations block is gated on verified evidence most of them do not have. They are the
-- "473 with no successor" cohort's sharpest 102 — the ones we researched twice and still show
-- nothing for.
--
-- This migration writes the RESULT OF THAT RESEARCH, not a position. It inserts one
-- `inform.topic_research_outcomes` row per person for `deportation` in Season 2, outcome
-- 'no-stance', so `getResearchStates` renders "We researched {name} and found no public stance on
-- {topic}" in place of silence. 🔴 NO ANSWER AND NO CONTEXT ROW IS TOUCHED. No chair moves, and
-- none is created: this migration INSERTs into exactly one table.
--
-- A. WHY EVERY ONE OF THE 102 CAME BACK 'no-stance'
--
-- `inform.compass_topic_roles` for `deportation`:
--     federal → 'record'   state → 'own-words'   local → 'own-words'
-- Per CLAUDE.md "Scope decides the evidence" (ruling 2026-10-06, option B) and
-- backend/src/lib/topicApplicability.ts, 'own-words' means NO LEVER at that level: a bill, a vote,
-- a co-sponsorship or a signing CANNOT seat the chair there. 85 of the 102 are state or local, so
-- for them only their own words about FEDERAL REMOVAL POLICY could have seated anything.
--
-- The Season 2 ladder (q9, revision 55c3167e) separates its rungs by WHO IS LEFT ALONE:
--     1 stop deportations entirely and protect undocumented immigrants from removal
--     2 only deport undocumented immigrants convicted of serious violent crimes
--     3 focus deportation on recent arrivals while leaving long-settled immigrants in place
--     4 deport all undocumented immigrants, starting with those who have criminal records
--     5 a mass-deportation program removing all, including long-settled families and workers
--
-- That boundary is the one thing public officials almost never state. Measured across all 102:
-- pro-enforcement evidence reads "deport illegal immigrants" / "criminal illegal aliens" with no
-- upper bound, which fits rungs 3, 4 and 5 at once; restriction-sceptical evidence reads "due
-- process", "protect families", "pathway for Dreamers" with no lower bound, which fits 1, 2 and 3
-- at once. Picking one anyway is the "least extreme option the reasoning supports" tiebreaker that
-- [[feedback_chair_needs_evidence_for_that_chair]] names as the signal a row is NOT evidenced.
--
-- The closest misses, all refused on the same clause, are in the ledger:
--   · Greg Abbott — his own 2025-01-29 release directs agencies to "investigate, arrest, detain,
--     and deport illegal immigrants in Texas", UNQUALIFIED. Reaches "remove all"; cannot separate
--     rung 4 from rung 5, and the "starting with those who have criminal records" clause is absent.
--   · Jack Bergman — "deporting criminal illegal aliens", "end illegal immigration", opposes "any
--     form of amnesty". Criminal-first plus no-amnesty still never says who is NOT removed.
--   · Melissa Hurtado — "people with criminal pasts have no place in our communities": one-sided,
--     never "only", and silent on everyone else.
--
-- B. WHY 'no-stance' AND NOT 'doesnt-fit'
-- 'doesnt-fit' renders the person's checked own words beside the topic, and those passages live in
-- `inform.own_words_passages` with a source_url each. About 30 of the 102 do have public words on
-- immigration that simply do not reach this ladder — but writing them as passages would mean
-- quoting pages this pass read through search summaries rather than fetching. Under the project's
-- "never cite an unfetched URL" rule those quotes are not citable yet, so every row here is
-- 'no-stance', which is accurate on its own terms: no public stance on THIS question was found.
-- Upgrading a subset to 'doesnt-fit' later is additive and needs only the fetches.
--
-- C. WHAT WAS CHECKED, PER PERSON
-- One targeted own-words search each, plus the official issues page where one could be reached, and
-- a primary-source fetch wherever a search suggested a rung-reaching statement. Ballotpedia was
-- swept for all 102 first: 70 pages reachable, 57 "did not complete" the Candidate Connection
-- survey, 0 completed one, 32 name-slug 404s. That survey is the one source type proven to reach an
-- own-words ladder (it seated Wein at 1 and Patterson at 4) and this cohort has none.
-- Per-person source and verdict: backend/data/stance-research/2026-10-26-deportation-102/
--
-- ⚠ THREE MISATTRIBUTIONS WERE CAUGHT AND NOT WRITTEN. A search returned a senate.texas.gov letter
-- as Molly Cook's; the fetched PDF is signed SARAH ECKHARDT (D14; Cook is D15). The Starr County
-- deportation-facility land offer is Land Commissioner Dawn Buckingham's, not Abbott's. Searches
-- also surfaced Susan Collins for Nick Collins, Will Cain for Briscoe Cain, Gabe Evans for Dwight
-- Evans, the filmmaker Michael Moore for Senator Michael O. Moore, and Mayra Flores for Lulu
-- Flores. None was used. This is the defect class of migrations 1896/1897.
--
-- D. NOT RESEARCHED HERE
-- The three unreachable federal issue pages (Guthrie, Bergman, Ezell) were covered by search
-- instead; their house.gov immigration sub-pages 404 on every common path.
--
-- Applied by: chris@empowered.vote      Researched on: 2026-10-26

BEGIN;

CREATE TEMP TABLE mig1950_targets (politician_id uuid PRIMARY KEY, full_name text) ON COMMIT DROP;

INSERT INTO mig1950_targets (politician_id, full_name) VALUES
    ('f2e91286-8dbc-477a-88be-458dffe774a2'::uuid, 'Andrej Selivra')
  , ('00f01100-f964-4489-86da-6379a8ca1c5e'::uuid, 'Brian Burley')
  , ('6cd2e87b-7366-429a-a049-990751bd647f'::uuid, 'John McKinney')
  , ('a123c59e-694b-43cc-af03-6610b645e6d2'::uuid, 'Mónica García')
  , ('0fa047d2-ffd4-4a87-b59a-ebf5946ac9af'::uuid, 'Tish Hyman')
  , ('c7f798b2-8304-44ac-84fd-be7eff81ce31'::uuid, 'Tony Sabio')
  , ('7b36e7d8-f8da-4c97-b268-04d59e9b69cc'::uuid, 'Robert B. Aderholt')
  , ('96cc507d-bb3a-4e25-ae6c-4b937f68f9f4'::uuid, 'Laurel M. Lee')
  , ('056b7a21-bdf1-4d7d-a992-be0f5db74fb0'::uuid, 'Brett Guthrie')
  , ('4fbc85b6-5d8b-4ee6-8328-adb433897b2e'::uuid, 'James Comer')
  , ('98c51f29-fa5d-4368-8330-cb2420746f45'::uuid, 'Jack Bergman')
  , ('6d0241d8-0408-4a0d-a159-62e1fe5d8fab'::uuid, 'Ann Wagner')
  , ('0fd6132b-eb62-461d-98f7-8449fb3adbf2'::uuid, 'Mike Ezell')
  , ('0f8bb5ea-8d89-4cfb-9291-04b54c128b82'::uuid, 'Kurt Alme')
  , ('09a47b4e-566f-46dc-b14b-547b93282f09'::uuid, 'John W. Mannion')
  , ('23cc5b70-f133-4b32-a785-ee6445fb70d7'::uuid, 'Tom Cole')
  , ('3c962502-99c7-46ec-ae6b-0c69143f571c'::uuid, 'Dwight Evans')
  , ('10678016-146d-4543-941c-00414b4c4ad2'::uuid, 'Katy Yaroslavsky')
  , ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c'::uuid, 'Edward M. Flynn')
  , ('41ced04d-7403-4170-a267-c339191e6fcd'::uuid, 'Jake Wilson')
  , ('8566674a-3a3b-4c88-bba0-c9f42e4ff810'::uuid, 'Alexandra M. Macedo')
  , ('190c3584-0826-4a5f-a2ad-104ff70ff259'::uuid, 'Gail Pellerin')
  , ('97285c92-b664-4687-a1e4-6d88cf9c7fe4'::uuid, 'Jacqui Irwin')
  , ('01dd07dc-ded1-4ba5-aff3-2dc2b386af12'::uuid, 'James C. Ramos')
  , ('539874fc-489f-4643-9b1a-923aca6cc2c1'::uuid, 'Jasmeet Kaur Bains')
  , ('0267f457-cd3f-4790-b0c8-76ec616de3f0'::uuid, 'Jerry McNerney')
  , ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26'::uuid, 'Melissa Hurtado')
  , ('e2daa3aa-02b6-4a4d-859b-fb75f674625b'::uuid, 'Aaron L. Saunders')
  , ('15f59b0c-f71c-4199-b195-7b653a05a310'::uuid, 'Barry R. Finegold')
  , ('1e83f9fc-43c9-4568-937d-94383acdc117'::uuid, 'Brian M. Ashe')
  , ('4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'Brian W. Murray')
  , ('3582a053-ee20-4391-904f-3905a2d13a52'::uuid, 'Bruce J. Ayers')
  , ('bca54df2-f059-44ce-81c3-f208f1e20752'::uuid, 'Christopher J. Worrell')
  , ('fd3bf15c-265b-46a9-aa72-c9097749d762'::uuid, 'Chynah Tyler')
  , ('248f76d7-e76a-49e5-88b7-dc43a3131329'::uuid, 'Cynthia F. Friedman')
  , ('3d9354a8-e7ee-4381-b91a-a40d0a2e8d3a'::uuid, 'Danielle W. Gregoire')
  , ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f'::uuid, 'David Biele')
  , ('a743a9a0-711c-40cf-b6e2-0ce2b587949a'::uuid, 'David F. DeCoste')
  , ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04'::uuid, 'David Robertson')
  , ('35f10acb-fe09-40eb-a847-195fffee6f25'::uuid, 'David T. Vieira')
  , ('44ca0b25-e4b9-4409-8407-f5119568be3e'::uuid, 'Donald H. Wong')
  , ('329212d4-14ef-4685-9d95-cc7473aad949'::uuid, 'Donald R. Berthiaume')
  , ('8e125ae2-3101-49b1-b228-f172ad9c70d9'::uuid, 'Estela A. Reyes')
  , ('77ceaab2-846e-4bc8-b09d-faff40ddbc60'::uuid, 'Francisco E. Paulino')
  , ('03e35156-c179-4dd5-9c8c-8d418976914e'::uuid, 'Hadley Luddy')
  , ('f392e7c6-0ab2-4834-9a57-df86541f55d3'::uuid, 'James Arciero')
  , ('6148f954-b8cc-4204-96ca-34f2afc1d24a'::uuid, 'Jennifer Balinsky Armini')
  , ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb'::uuid, 'Jessica A. Giannino')
  , ('6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, 'Joan B. Lovely')
  , ('973d60e2-fca7-4185-bd2a-84a686e925ab'::uuid, 'John C. Velis')
  , ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'John F. Keenan')
  , ('ef888471-24a9-4a9f-9115-e530c16986ae'::uuid, 'John J. Cronin')
  , ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'Michael D. Brady')
  , ('62764b2a-5b54-4edb-9c69-06320cbebbad'::uuid, 'Michael F. Rush')
  , ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5'::uuid, 'Michael J. Moran')
  , ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, 'Michael J. Rodrigues')
  , ('c0b79f82-6ce7-413a-a18a-286c9a8fa5fd'::uuid, 'Michael O. Moore')
  , ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'Nick Collins')
  , ('e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid, 'Patrick M. O''Connor')
  , ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'Paul R. Feeney')
  , ('f530be83-6f1b-4b04-a8c4-3a83dc35099f'::uuid, 'Paul W. Mark')
  , ('e47f2082-6fcb-4961-9df5-c5fb94004b59'::uuid, 'Robyn K. Kennedy')
  , ('916afe40-4061-476f-9a54-b271b32778d2'::uuid, 'Jamila J. Woods')
  , ('70f63959-f51d-4411-adc1-f1c429bbc397'::uuid, 'Jeffrie E. Long, Jr.')
  , ('7a76712a-38cd-41de-b260-cd0127284f16'::uuid, 'Veronica Turner')
  , ('b7318128-42e4-4285-989d-11a849f76e95'::uuid, 'Denny Hoskins')
  , ('79276956-dfa1-4bca-9820-ab7c78dd57c8'::uuid, 'Frank LaRose')
  , ('066f7bc5-6e3d-4d17-9878-73d896a2369e'::uuid, 'Stacy Garrity')
  , ('f6570c10-effb-41e1-b559-ef9ca41a2bf1'::uuid, 'Ana Hernandez')
  , ('d9486e4a-490a-4d87-a495-655cce9700e2'::uuid, 'Armando Martinez')
  , ('c456d802-e836-4208-8d18-33402c807429'::uuid, 'Armando Walle')
  , ('1a94bee0-7418-4b75-ba17-f3cf97d888aa'::uuid, 'Barbara Gervin-Hawkins')
  , ('d701afd5-c15c-48c4-8f16-54aa142a6769'::uuid, 'Brad Buckley')
  , ('9d6eae75-9400-46bf-a2f1-34de55db3d49'::uuid, 'Briscoe Cain')
  , ('625ec7a8-10b3-446d-a935-a8bee51e72fd'::uuid, 'Chris Turner')
  , ('3a310d29-093f-417b-a23f-885aa3658b12'::uuid, 'Diego Bernal')
  , ('481d7dae-0a6f-4e54-917c-72a2c6be6731'::uuid, 'Don McLaughlin')
  , ('155a62d8-9e8e-4231-94dc-823b9f15b30b'::uuid, 'Eddie Morales')
  , ('8b1a1407-4774-41c1-80f4-193a401d3c86'::uuid, 'Greg Abbott')
  , ('f6e50487-d839-479d-8efd-9937a09f9ab4'::uuid, 'Jeffrey Barry')
  , ('6af34442-997a-4b8d-8c19-3ae65519fa38'::uuid, 'Lulu Flores')
  , ('e9ae7dbc-e266-4d10-ad47-4cd63efc5d0d'::uuid, 'Molly Cook')
  , ('2d3e3416-fb12-455b-9010-4185010fb3aa'::uuid, 'Oscar Longoria')
  , ('933d4df6-d2ac-4d2c-82b9-a7676bf2c269'::uuid, 'Paul Dyson')
  , ('81d931a9-5906-4ff4-9ac8-15b49c4ae38a'::uuid, 'Penny Morales Shaw')
  , ('fd716f6e-aa75-4829-ae39-43e31516b3a5'::uuid, 'Philip Cortez')
  , ('217dbd01-bbb3-45ef-afc3-a1a94a937583'::uuid, 'Rafael Anchia')
  , ('ff0ce995-51b0-42fd-ae1a-458062b0ce1f'::uuid, 'Ramon Romero Jr.')
  , ('a436b52d-8801-4588-b676-bd101bb2bdeb'::uuid, 'Ray Lopez')
  , ('f4286f1f-dda7-4fe4-9473-455772f40fae'::uuid, 'Rhetta Bowers')
  , ('76fb2373-43c5-4f18-9e0f-18da31e0f863'::uuid, 'Richard Raymond')
  , ('1ea8b603-7f4d-40e5-b8c7-0ba19af17717'::uuid, 'Robert Nichols')
  , ('1ff93be4-a2d0-432b-af59-ef6ace1eb77b'::uuid, 'Royce West')
  , ('b6ea3b73-5664-462f-bc99-6c377418c34f'::uuid, 'Ryan Guillen')
  , ('32cd74d7-cd2a-4420-8e96-7f34c253dba6'::uuid, 'Salman Bhojani')
  , ('c783e709-2cef-460e-af1e-8b4f8e8339b0'::uuid, 'Senfronia Thompson')
  , ('579a5a6f-c12e-4f01-af74-ec30f6bfbafe'::uuid, 'Steve Toth')
  , ('02691090-c16c-4216-ac3b-1caa89a618a8'::uuid, 'Terry Canales')
  , ('56b91150-194f-4699-ba31-e944443eacae'::uuid, 'Terry Wilson')
  , ('d66fb5fd-7b56-47a5-9762-e29b7403bb39'::uuid, 'Todd Hunter')
  , ('43567dd1-db59-40af-928e-03708237eb98'::uuid, 'Toni Rose')
  , ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'Ghazala Hashmi')
;

DO $$
DECLARE
  n           int;
  topic       uuid;
  s2          uuid := '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;
  answers_before int;
  context_before int;
BEGIN
  -- GUARD 1: the topic resolves, and Season 2 actually asks it. A research outcome written against
  -- a season that does not ask the question renders nothing and means nothing.
  SELECT id INTO topic FROM inform.compass_topics WHERE topic_key = 'deportation';
  IF topic IS NULL THEN
    RAISE EXCEPTION 'migration 1950: no compass topic with topic_key = deportation';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.season_questions WHERE season_id = s2 AND topic_id = topic) THEN
    RAISE EXCEPTION 'migration 1950: Season 2 does not ask deportation — STOP';
  END IF;

  -- GUARD 2: all 102 targets exist and are active. An inactive person is not voter-facing and does
  -- not belong in a research-outcome write.
  SELECT count(*) INTO n FROM mig1950_targets;
  IF n <> 102 THEN
    RAISE EXCEPTION 'migration 1950: expected 102 targets, found %', n;
  END IF;
  SELECT count(*) INTO n
    FROM mig1950_targets t
    LEFT JOIN essentials.politicians p ON p.id = t.politician_id AND p.is_active
   WHERE p.id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1950: % target(s) missing or inactive', n;
  END IF;

  -- GUARD 3 🔴 THE LOAD-BEARING ONE. A research outcome must never contradict a seat. If any target
  -- holds a non-zero deportation answer in any published season, this cohort was built wrong — the
  -- 102 are defined as people with NO serving successor position.
  SELECT count(*) INTO n
    FROM mig1950_targets t
   WHERE EXISTS (
     SELECT 1 FROM (
       SELECT DISTINCT ON (a.topic_id) a.value
         FROM inform.politician_answers a
         JOIN inform.seasons s ON s.id = a.season_id AND s.status <> 'draft'
        WHERE a.politician_id = t.politician_id AND a.topic_id = topic
        ORDER BY a.topic_id, s.number DESC
     ) newest WHERE newest.value <> 0);
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1950: % target(s) hold a seated deportation answer — STOP, the outcome would contradict the compass', n;
  END IF;

  -- GUARD 4: nothing is being overwritten. The table is empty in production as of 2026-10-26; if a
  -- row already exists for one of these pairs, someone else researched it and this pass must not
  -- silently replace their verdict.
  SELECT count(*) INTO n
    FROM inform.topic_research_outcomes ro
    JOIN mig1950_targets t ON t.politician_id = ro.politician_id
   WHERE ro.topic_id = topic AND ro.season_id = s2;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1950: % outcome row(s) already exist for these pairs — STOP', n;
  END IF;

  -- Baselines for the post-flight. This migration must not change a single answer or context row.
  SELECT count(*) INTO answers_before FROM inform.politician_answers;
  SELECT count(*) INTO context_before FROM inform.politician_context;

  INSERT INTO inform.topic_research_outcomes
    (politician_id, topic_id, season_id, outcome, researched_on, checked_by)
  SELECT t.politician_id, topic, s2, 'no-stance', DATE '2026-10-26',
         ARRAY['own-words search', 'official issues page where reachable', 'ballotpedia candidate connection sweep']
    FROM mig1950_targets t;

  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 102 THEN
    RAISE EXCEPTION 'migration 1950: inserted % rows, expected 102', n;
  END IF;

  -- POST-FLIGHT 1: every target now carries exactly one 'no-stance' outcome for this pair.
  SELECT count(*) INTO n
    FROM inform.topic_research_outcomes ro
    JOIN mig1950_targets t ON t.politician_id = ro.politician_id
   WHERE ro.topic_id = topic AND ro.season_id = s2 AND ro.outcome = 'no-stance';
  IF n <> 102 THEN
    RAISE EXCEPTION 'migration 1950: post-flight found % outcome rows, expected 102', n;
  END IF;

  -- POST-FLIGHT 2 🔴 NO CHAIR MOVED, BECAUSE NO ANSWER OR CONTEXT ROW WAS TOUCHED AT ALL.
  SELECT count(*) INTO n FROM inform.politician_answers;
  IF n <> answers_before THEN
    RAISE EXCEPTION 'migration 1950: politician_answers changed (% -> %) — STOP', answers_before, n;
  END IF;
  SELECT count(*) INTO n FROM inform.politician_context;
  IF n <> context_before THEN
    RAISE EXCEPTION 'migration 1950: politician_context changed (% -> %) — STOP', context_before, n;
  END IF;

  -- POST-FLIGHT 3: no outcome row anywhere contradicts a seat (the invariant getResearchStates
  -- relies on), checked across the whole table rather than just this write.
  SELECT count(*) INTO n
    FROM inform.topic_research_outcomes ro
   WHERE ro.outcome IN ('doesnt-fit', 'no-stance')
     AND EXISTS (
       SELECT 1 FROM (
         SELECT DISTINCT ON (a.topic_id) a.value
           FROM inform.politician_answers a
           JOIN inform.seasons s ON s.id = a.season_id AND s.status <> 'draft'
          WHERE a.politician_id = ro.politician_id AND a.topic_id = ro.topic_id
          ORDER BY a.topic_id, s.number DESC
       ) newest WHERE newest.value <> 0);
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1950: % outcome row(s) contradict a seated answer', n;
  END IF;

  RAISE NOTICE 'migration 1950: 102 deportation research outcomes written, no answer or context row touched';
END $$;

COMMIT;
