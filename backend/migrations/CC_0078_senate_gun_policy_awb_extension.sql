BEGIN;

-- =============================================================================
-- CC_0078: the Senate gun-policy pass — 45 answers off two bills
-- =============================================================================
-- Slot CC_0078 reserved via `steward slot CC` before this file existed.
--
-- WHAT THIS IS. 45 gun-policy answers for sitting U.S. Senators, plus the 45
-- context rows that justify them. It is the first BULK output of the federal
-- research pass, and where CC_0074 measured the per-row cost of researching a
-- senator one at a time, this measures what it costs to extend a chair that was
-- already reviewed to everyone who signed the same bill.
--
--   42  chair 2  cosponsors of an Assault Weapons Ban
--    3  chair 3  cosponsors of the Background Check Expansion Act who are on no ban
--
-- 🔴 DO NOT APPLY THIS UNTIL THE CHAIRS HAVE BEEN REVIEWED BY A HUMAN. 45 rows
-- are 45 published claims about named sitting senators. All 45 passed
-- `verify-reresearch-rows.mjs --tier=federal` end to end — right tier, promoted
-- topic, no prior answer, and every distinctive claim term present in the raw
-- HTML of the cited bill text (22/22 on the ban rows, 21/21 on the background
-- check rows) — but that gate proves the reasoning is CARRIED BY the source and
-- never that the chair is the right reading of it.
--
-- ── THE EXTENSION RULE, AND WHY IT IS SAFE ───────────────────────────────────
--
-- CC_0074 seated Padilla and Schiff at chair 2 as signatories of the Assault
-- Weapons Ban, and a person reviewed that chair. This file extends THAT REVIEWED
-- CHAIR to everyone else on the same bill. The rung is a property of the bill,
-- not of the senator: chair 2 is "ban semi-automatic assault-style weapons, while
-- allowing other firearms", and S. 1531 does precisely that — it makes the weapon
-- and the magazine unlawful and exempts the firearms in its Appendix A.
--
-- 🔑 WHAT MAKES THE EXTENSION CHECKABLE IS THE ROLL, NOT THE NAME. Each row was
-- gated on the senator's BIOGUIDE ID appearing in the sponsor/cosponsor roll of
-- the govinfo BILLSTATUS record. Not a surname — Lujan, Cortez Masto, Van Hollen
-- and Blunt Rochester all need hand-maintained spellings, and the next accented or
-- two-word surname would have been a silent miss. The id is what the record is
-- keyed by and what api.congress.gov joins on.
--
--   https://www.govinfo.gov/bulkdata/BILLSTATUS/119/s/BILLSTATUS-119s1531.xml
--   https://www.govinfo.gov/bulkdata/BILLSTATUS/118/s/BILLSTATUS-118s25.xml
--   https://www.govinfo.gov/bulkdata/BILLSTATUS/119/s/BILLSTATUS-119s3214.xml
--
-- ⚠ THOSE URLS ARE THE GATE AND ARE DELIBERATELY NOT CITED. Citing them failed all
-- 45 rows: the verifier reads a page through crawlSite, which extracts nothing
-- from a document with no HTML body and reports "thin body 0c" — UNREADABLE, which
-- it correctly refuses to treat as evidence. So the structured record authorises
-- the row at generation time and is recorded here for a reviewer, while the cited
-- source is the bill text, which is readable and is what the reasoning quotes.
--
-- ── THE REASONING MAKES NO CLAIM ABOUT ROLE, ON PURPOSE ──────────────────────
--
-- CC_0076 had to rewrite CC_0074's voter-facing prose because it described Schiff
-- as a "lead cosponsor" of a bill he SPONSORS, on the strength of a summary of a
-- press release. Its rule: the structured record settles a role.
--
-- These rows go further and make no role claim at all. Both texts describe only
-- what the BILL does, so sponsor and cosponsor sit on identical words and the
-- error CC_0076 corrected cannot recur through this batch. It also means the two
-- reasoning strings are shared rather than per-person, which is why the rows below
-- are keyed to a basis instead of carrying 45 near-identical copies.
--
-- ── WHAT IS DELIBERATELY ABSENT: 53 SENATORS, AND IT IS NOT AN OVERSIGHT ─────
--
-- 98 senators are owed a gun-policy answer. This file writes 45. The other 53 are
-- absent for three different reasons, and the largest is a defect in the LADDER
-- rather than a gap in the evidence:
--
--   49 · cosponsors of the Constitutional Concealed Carry Reciprocity Act, and no
--        rung describes them. Rung 4 is "keep current gun laws, adding no new
--        restrictions" — a status-quo position, and these senators are legislating
--        a change. Rung 5 is "repeal major gun restrictions AND let adults carry
--        without a permit" — reciprocity repeals nothing and works THROUGH the
--        permit system. Seating them at 4 understates and at 5 overstates.
--
--        🔴 THE GAP IS NOT RANDOMLY DISTRIBUTED. All 49 are Republicans, and every
--        one of the 47 members of the Democratic caucus is placeable. Applying this
--        file publishes a corpus where one caucus is seated and the other is blank.
--        That is a true reading of the record against this ladder and it will still
--        read as a thumb on the scale. It is with Chris Andrews as a wording
--        question; the rungs, not the research, are what has to move.
--
--    2 · Rand Paul and Lisa Murkowski, on none of the three marquee bills. They
--        need an individual read, not an extension.
--
--    2 · Susan M. Collins and Alan Armstrong, who produced NO gun-policy lead at
--        all in the 2026-09-05 sweep. That is missing evidence, not an unfittable
--        position, and Armstrong produced no lead on any of the nine topics — which
--        is the signature of a bioguide that did not resolve, not of a senator with
--        no record. Worth checking before either blank is read as meaningful.
--
-- ── THREE ROWS THAT NEARLY WENT MISSING ──────────────────────────────────────
--
-- Schatz, Ossoff and Cortez Masto are real cosponsors who are ABSENT from the bill
-- text this file cites, and an earlier gate that read that text refused them:
-- govinfo's "Introduced in Senate" print names only the signatures a bill carried
-- ON INTRODUCTION. S. 1531 was introduced 2025-04-30 with 41; Schatz joined
-- 2025-07-23 and Ossoff 2025-05-05, and Cortez Masto joined S. 25 on 2023-05-01.
-- BILLSTATUS carries the whole roll and clears all three.
--
-- ⚠ THE SWEEP'S `introduced` COLUMN IS THE MEMBER'S OWN ACTION DATE, not always
-- the bill's — the two coincide only for a sponsor or an original cosponsor. That
-- is the right semantic for --since and a trap for anything joining a lead to a
-- bill's text, and it is now documented in congress-sponsorship-leads.mjs.
--
-- Cortez Masto is on an assault weapons ban, so she is chair 2 here and NOT chair
-- 3, even though she also signs the background check bill. CC_0074's precedence
-- rule decides it: chair 3 stops at background checks and would understate a
-- signatory of the ban itself.
--
-- ── PROVENANCE ───────────────────────────────────────────────────────────────
--
-- 🔴 editor_id IS NULL ON BOTH TABLES, DELIBERATELY, for the reason CC_0074 gives:
-- the prose was drafted in an assisted research session and reviewed before this
-- migration was applied, and there is no EV user account that authored it.
-- Attributing it to whoever applies the migration would put a person's name on
-- words they did not write. The provenance is this file.
--
-- ⚠ EDITING THE REASONING STRINGS WILL BREAK THE GATE. Every distinctive term is
-- present in the cited bill text because the strings were written against it —
-- "enumerated" and "listed" both failed where the bill says "specified in Appendix
-- A". Re-run the verifier if you touch them.

-- -----------------------------------------------------------------------------
-- The two chairs, as editorial artefacts
-- -----------------------------------------------------------------------------
-- One reasoning per BASIS rather than per person: the claim is about the bill, and
-- 45 copies of the same sentence would hide that the batch is two texts.
CREATE TEMPORARY TABLE _cc0078_basis (
  basis     text    PRIMARY KEY,
  value     numeric NOT NULL,
  reasoning text    NOT NULL,
  sources   text[]  NOT NULL
) ON COMMIT DROP;

INSERT INTO _cc0078_basis VALUES
  ('awb-2025', 2, 'A bill to regulate assault weapons and to ensure that the right to keep and bear arms is not unlimited. It is unlawful to import, sell, manufacture, transfer, or possess a semiautomatic assault weapon or large capacity ammunition feeding device; a firearm specified in Appendix A is exempt.',
   ARRAY['https://www.govinfo.gov/content/pkg/BILLS-119s1531is/html/BILLS-119s1531is.htm']),
  ('bce-2025', 3, 'A bill to require a background check for every firearm sale. It is unlawful for a person who is not a licensed importer, licensed manufacturer, or licensed dealer to transfer a firearm to another person who is not so licensed, unless a licensee has first taken possession of the firearm for the purpose of complying with the background check requirements.',
   ARRAY['https://www.govinfo.gov/content/pkg/BILLS-119s3214is/html/BILLS-119s3214is.htm']),
  ('awb-2023', 2, 'A bill to regulate assault weapons and to ensure that the right to keep and bear arms is not unlimited. It is unlawful to import, sell, manufacture, transfer, or possess a semiautomatic assault weapon or large capacity ammunition feeding device; a firearm specified in Appendix A is exempt.',
   ARRAY['https://www.govinfo.gov/content/pkg/BILLS-118s25is/html/BILLS-118s25is.htm']);

-- -----------------------------------------------------------------------------
-- The people
-- -----------------------------------------------------------------------------
-- politician_id, not full_name: TWO ACTIVE PEOPLE ARE NAMED "ALEX PADILLA" — the
-- senator and an Inglewood city councilmember. `who` is a cross-check on the row
-- having been assembled correctly; the id decides.
CREATE TEMPORARY TABLE _cc0078_rows (
  politician_id uuid NOT NULL,
  who           text NOT NULL,
  basis         text NOT NULL REFERENCES _cc0078_basis(basis)
) ON COMMIT DROP;

INSERT INTO _cc0078_rows VALUES
  ('91f87a53-13bc-4d35-b3c8-49227ae80faa', 'Catherine Cortez Masto', 'awb-2023'),
  ('3d51cca6-7206-413b-ab8d-3199a58a6767', 'Amy Klobuchar', 'awb-2025'),
  ('e7c985f0-7804-485e-8ad7-8e71c0129a00', 'Andy Kim', 'awb-2025'),
  ('17f7729f-22a2-4346-9434-e5f545cfe8b4', 'Angela Alsobrooks', 'awb-2025'),
  ('27d57833-842f-427c-bedd-aa1695fe550f', 'Ben Ray Luján', 'awb-2025'),
  ('3cc5cece-cec0-4490-8faa-37a6b66231c7', 'Bernie Sanders', 'awb-2025'),
  ('100de02f-b44d-4587-9b90-19aa5081708c', 'Brian Schatz', 'awb-2025'),
  ('eaab08fa-c93d-44de-ad8e-06275658dddc', 'Chris Coons', 'awb-2025'),
  ('61a601c2-7faa-4889-abf2-bbb0066ce448', 'Chris Van Hollen', 'awb-2025'),
  ('b700099a-8cab-44b6-81b8-d678d646ae88', 'Christopher Murphy', 'awb-2025'),
  ('af01a7ec-9318-4862-ba78-553e5908182c', 'Chuck Schumer', 'awb-2025'),
  ('872f60a5-7ded-473b-87a8-a904d6ca4d6e', 'Cory Booker', 'awb-2025'),
  ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78', 'Edward J. Markey', 'awb-2025'),
  ('ebe10065-0025-46e5-897e-7a81e4c77ecf', 'Elissa Slotkin', 'awb-2025'),
  ('dd08c9de-076d-40ee-ab27-9298bbb72d1a', 'Elizabeth Warren', 'awb-2025'),
  ('7b77ec48-f6d0-4b10-84bf-d15607fcbd2d', 'Gary Peters', 'awb-2025'),
  ('afd8d31b-9f88-4eb9-8a88-46e5ef914267', 'Jack Reed', 'awb-2025'),
  ('e3a590be-1816-46bc-98f0-6a911dec9d9d', 'Jacky Rosen', 'awb-2025'),
  ('1d877e4d-8aaf-4db8-be5b-2a3de0a98783', 'Jeanne Shaheen', 'awb-2025'),
  ('0eabc969-c1a1-47b7-8d34-6113b723a170', 'Jeff Merkley', 'awb-2025'),
  ('e89abbed-b93c-4a07-a1b1-fe33060ebec7', 'John Fetterman', 'awb-2025'),
  ('2a6693c7-9149-4e71-85fe-003746f7d23d', 'John Hickenlooper', 'awb-2025'),
  ('6160a29a-d896-4061-801a-e5c3d9f06c99', 'Jon Ossoff', 'awb-2025'),
  ('463f8a89-e12c-4b92-8df1-0fed43dc4441', 'Kirsten Gillibrand', 'awb-2025'),
  ('f9abc9e1-e1d5-4cd9-9983-a403dc94a5fc', 'Lisa Blunt Rochester', 'awb-2025'),
  ('ec0aeea4-afb2-46b1-be2c-c226188cfbaa', 'Maggie Hassan', 'awb-2025'),
  ('750717e7-1f22-42a7-86fd-e065caf343de', 'Maria Cantwell', 'awb-2025'),
  ('85d27350-e1b6-45b8-aee3-509ca88c5af4', 'Mark Warner', 'awb-2025'),
  ('dc92c805-4734-4d4b-8ceb-597e59b0e268', 'Mazie Hirono', 'awb-2025'),
  ('535591bf-7151-48ba-81b4-e8d9983def72', 'Michael Bennet', 'awb-2025'),
  ('0f06ced9-84c7-4020-98fd-82ac25d49027', 'Patty Murray', 'awb-2025'),
  ('9a9874ab-159f-4ffb-b88e-f058df02d5fa', 'Peter Welch', 'awb-2025'),
  ('5fe0fed0-05b0-49e4-b7e2-99d2c8463a0d', 'Raphael Warnock', 'awb-2025'),
  ('bd630c8f-14da-4149-b95c-6da7eddaab8f', 'Richard Blumenthal', 'awb-2025'),
  ('2c3372a7-dadc-4622-944c-1783abe57b56', 'Richard Durbin', 'awb-2025'),
  ('2147281e-e1b1-4416-a5d9-dae9d4f31be0', 'Ron Wyden', 'awb-2025'),
  ('0fd03798-714d-4976-a9b6-448aa22d8a68', 'Ruben Gallego', 'awb-2025'),
  ('c19c488e-ae48-4ed2-ba7c-3092b847c192', 'Sheldon Whitehouse', 'awb-2025'),
  ('ac7faadb-52c2-4e13-9073-3a607a4f8e57', 'Tammy Baldwin', 'awb-2025'),
  ('059dab9f-a79a-4664-b4cf-26b0655c596f', 'Tammy Duckworth', 'awb-2025'),
  ('8cffe7a0-b56c-42fe-adbf-f57d63589973', 'Tim Kaine', 'awb-2025'),
  ('a8017fcc-f4c0-4b7d-a0fa-9d76ea3d56f6', 'Tina Smith', 'awb-2025'),
  ('4f4b2bff-0054-475f-8687-e83f68085f15', 'Angus S. King, Jr.', 'bce-2025'),
  ('7e1e1044-a98b-4c69-910e-73de8e818c48', 'Mark Kelly', 'bce-2025'),
  ('4fa06009-8f67-40f6-a8b3-d2d62712240d', 'Martin Heinrich', 'bce-2025');

-- -----------------------------------------------------------------------------
-- 1. Preconditions
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_s2 uuid;
  v_n  int;
BEGIN
  SELECT id INTO v_s2 FROM inform.seasons WHERE status = 'open';
  IF v_s2 IS NULL THEN
    RAISE EXCEPTION 'CC_0078: no season is open — every compass write path refuses in that state';
  END IF;
  IF (SELECT number FROM inform.seasons WHERE id = v_s2) <> 2 THEN
    RAISE EXCEPTION 'CC_0078: the open season is not Season 2 — these chairs were researched against Season 2 ladders';
  END IF;

  -- The id is authoritative, but a name that has drifted means the file was
  -- assembled against a different roster than the one in front of us.
  SELECT count(*) INTO v_n
    FROM _cc0078_rows r
    JOIN essentials.politicians p ON p.id = r.politician_id
   WHERE lower(p.full_name) <> lower(r.who);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0078: % row(s) name a different person than their politician_id resolves to', v_n;
  END IF;

  -- Every politician_id must resolve at all. A row keyed to a deleted or merged
  -- person would otherwise vanish silently from the INSERT's JOIN.
  SELECT count(*) INTO v_n
    FROM _cc0078_rows r
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = r.politician_id);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0078: % row(s) name a politician_id that resolves to nobody', v_n;
  END IF;

  -- gun-policy must be a topic the OPEN season asks — the CC_0066 rule. is_live is
  -- false on the new Season 2 topics and must not be consulted here.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE topic_key = 'gun-policy') THEN
    RAISE EXCEPTION 'CC_0078: the open season does not ask gun-policy — nothing would serve these answers';
  END IF;

  -- Federal tier, since this is a federal cohort and an out-of-tier row would
  -- never display for these officeholders.
  SELECT count(*) INTO v_n
    FROM inform.compass_topics t
   WHERE t.topic_key = 'gun-policy'
     AND EXISTS (SELECT 1 FROM inform.compass_topic_roles cr WHERE cr.topic_id = t.id)
     AND NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles cr
                      WHERE cr.topic_id = t.id AND cr.role_scope = 'federal');
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0078: gun-policy excludes the federal tier';
  END IF;

  -- Discrete chairs only. The CHECK permits 0.5 steps for a voter between rungs;
  -- a researched placement is always ON a rung.
  SELECT count(*) INTO v_n FROM _cc0078_basis WHERE value <> round(value) OR value < 1 OR value > 5;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0078: % basis row(s) carry a non-discrete or out-of-range chair', v_n;
  END IF;

  -- INSERT, not UPDATE. If any pair already holds a Season 2 answer this file has
  -- been run before, or somebody researched it in the meantime; either way stop
  -- rather than silently overwrite a stance.
  SELECT count(*) INTO v_n
    FROM _cc0078_rows r
    JOIN inform.compass_topics t ON t.topic_key = 'gun-policy'
    JOIN inform.politician_answers a
      ON a.politician_id = r.politician_id AND a.topic_id = t.id AND a.season_id = v_s2;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0078: % pair(s) already hold a Season 2 answer — this file has run, or the rows are stale', v_n;
  END IF;

  -- No senator twice. A duplicate would insert two answers for one pair and only
  -- surface as a confusing count at the end.
  SELECT count(*) INTO v_n FROM (
    SELECT politician_id FROM _cc0078_rows GROUP BY politician_id HAVING count(*) > 1) d;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0078: % politician(s) appear more than once', v_n;
  END IF;

  IF (SELECT count(*) FROM _cc0078_rows) <> 45 THEN
    RAISE EXCEPTION 'CC_0078: expected exactly 45 rows, found %', (SELECT count(*) FROM _cc0078_rows);
  END IF;

  RAISE NOTICE 'CC_0078 preconditions OK: Season 2 open, 45 rows, names match ids, gun-policy promoted and federal, no prior answers.';
END $$;

-- -----------------------------------------------------------------------------
-- 2. The answers
-- -----------------------------------------------------------------------------
-- season_id and topic_revision_id come from season_questions, NEVER hand-typed:
-- the row records which ladder text it is an answer to, and sourcing the pin from
-- the JOIN satisfies politician_answers_pin_fkey by construction.
INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value, write_in_text, editor_id, updated_at)
SELECT r.politician_id,
       t.id,
       sq.season_id,
       sq.topic_revision_id,
       b.value,
       NULL,
       NULL,
       now()
  FROM _cc0078_rows r
  JOIN _cc0078_basis b            ON b.basis = r.basis
  JOIN inform.compass_topics t    ON t.topic_key = 'gun-policy'
  JOIN inform.seasons s           ON s.status = 'open'
  JOIN inform.season_questions sq ON sq.season_id = s.id AND sq.topic_id = t.id;

-- -----------------------------------------------------------------------------
-- 3. The context
-- -----------------------------------------------------------------------------
-- Every non-blank answer carries reasoning — CC_0058 §3f enforces the pair, and
-- an answer with no context is an unsourced position, which is the one thing this
-- corpus must never publish.
INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources, editor_id, updated_at)
SELECT r.politician_id,
       t.id,
       sq.season_id,
       sq.topic_revision_id,
       b.reasoning,
       b.sources,
       NULL,
       now()
  FROM _cc0078_rows r
  JOIN _cc0078_basis b            ON b.basis = r.basis
  JOIN inform.compass_topics t    ON t.topic_key = 'gun-policy'
  JOIN inform.seasons s           ON s.status = 'open'
  JOIN inform.season_questions sq ON sq.season_id = s.id AND sq.topic_id = t.id;

-- -----------------------------------------------------------------------------
-- 4. Assert the outcome
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_s2       uuid;
  v_n        int;
  v_answers  int;
  v_context  int;
BEGIN
  SELECT id INTO v_s2 FROM inform.seasons WHERE status = 'open';

  -- 4a. every intended row landed, at the chair its basis names
  SELECT count(*) INTO v_n
    FROM _cc0078_rows r
    JOIN _cc0078_basis b ON b.basis = r.basis
    JOIN inform.compass_topics t ON t.topic_key = 'gun-policy'
    JOIN inform.politician_answers a
      ON a.politician_id = r.politician_id AND a.topic_id = t.id AND a.season_id = v_s2
   WHERE a.value = b.value;
  IF v_n <> 45 THEN
    RAISE EXCEPTION 'CC_0078: % of 45 answers landed at the intended chair', v_n;
  END IF;

  -- 4b. the split is the one this file describes, not merely the right total
  SELECT count(*) INTO v_n
    FROM _cc0078_rows r
    JOIN _cc0078_basis b ON b.basis = r.basis
    JOIN inform.compass_topics t ON t.topic_key = 'gun-policy'
    JOIN inform.politician_answers a
      ON a.politician_id = r.politician_id AND a.topic_id = t.id AND a.season_id = v_s2
   WHERE a.value = 2;
  IF v_n <> 42 THEN
    RAISE EXCEPTION 'CC_0078: % answers at chair 2, expected 42', v_n;
  END IF;

  -- 4c. each carries its reasoning and at least one source
  SELECT count(*) INTO v_n
    FROM _cc0078_rows r
    JOIN _cc0078_basis b ON b.basis = r.basis
    JOIN inform.compass_topics t ON t.topic_key = 'gun-policy'
    JOIN inform.politician_context c
      ON c.politician_id = r.politician_id AND c.topic_id = t.id AND c.season_id = v_s2
   WHERE c.reasoning = b.reasoning
     AND array_length(c.sources, 1) >= 1;
  IF v_n <> 45 THEN
    RAISE EXCEPTION 'CC_0078: % of 45 context rows landed with their reasoning and a source', v_n;
  END IF;

  -- 4d. the season-wide pair invariant still holds: no non-blank answer without
  --     context, and no blank carrying prose. CC_0058 §3f.
  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
   WHERE a.season_id = v_s2 AND a.value <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
                        AND c.season_id = a.season_id);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0078: % non-blank Season 2 answer(s) carry no reasoning', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id AND c.season_id = a.season_id
   WHERE a.season_id = v_s2 AND a.value = 0;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0078: % blanked answer(s) carry Season 2 reasoning', v_n;
  END IF;

  -- 4e. the corpus grew by exactly 45 and 45.
  --
  -- 🔴 RAISE THE SEASON 2 FLOORS TO 2734 / 2706 ONLY AFTER THIS IS APPLIED,
  --    AND NOT IN THE PR THAT MERGES THIS FILE — the ordering CC_0074 sets out. The
  --    same-PR rule in check-season-corpus-floor.mjs is about LOWERING; raising
  --    inverts it, because at merge time these rows do not exist yet and a floor
  --    above the live corpus fails the nightly gate. Apply first, then raise.
  SELECT count(*) INTO v_answers FROM inform.politician_answers WHERE season_id = v_s2;
  SELECT count(*) INTO v_context FROM inform.politician_context WHERE season_id = v_s2;
  IF v_answers <> 2734 THEN
    RAISE EXCEPTION 'CC_0078: Season 2 holds % answers, expected 2734 (2689 + 45)', v_answers;
  END IF;
  IF v_context <> 2706 THEN
    RAISE EXCEPTION 'CC_0078: Season 2 holds % context rows, expected 2706 (2661 + 45)', v_context;
  END IF;

  RAISE NOTICE 'CC_0078 OK: 45 answers + 45 context into Season 2 (42 at chair 2, 3 at chair 3). Season 2 now % answers / % context. Raise the floors to match.',
    v_answers, v_context;
END $$;

COMMIT;
