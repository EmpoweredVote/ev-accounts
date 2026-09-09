BEGIN;

-- =============================================================================
-- CC_0085: the Senate border-security batch - 12 answers from floor statements
-- =============================================================================
-- Slot CC_0085 reserved via `steward slot CC` before this file existed.
--
-- WHAT THIS IS. 12 border-security answers for sitting U.S. Senators, plus the 12
-- context rows that justify them. Third topic of the federal research pass, and the
-- FIRST built on the Congressional Record rather than on bill sponsorship.
--
--   9  chair 3  combine strong enforcement with a faster asylum process
--   3  chair 2  expand orderly, legal ways to seek asylum at the border
--
-- WHY A SECOND INSTRUMENT EXISTED AT ALL. Sponsorship reaches 43 of 100 senators on
-- this ladder and every one of them is a Republican or Angus King, because the
-- permissive caucus's immigration bills are detention standards, visa caps and
-- sponsor vetting rather than asylum-eligibility restrictions (PR #424, #426). That
-- is a fact about the INSTRUMENT, not the chamber. The Record is the second
-- instrument, and it inverts the asymmetry: 11 Democrats and one Republican here.
-- Neither instrument describes the Senate on its own, and this file is half a
-- picture on purpose.
--
-- 🟢 REVIEWED AND APPROVED 2026-09-08 by Chris Cantrell (chris@empowered.vote), on
-- the review page https://claude.ai/code/artifact/262b232b-062b-4b5b-9026-1b5f68e80b58
-- where the decision is recorded with its timestamp. Three rules were put to him and
-- all 12 rows hang off them:
--
--   1. APPROVED - "endorsing the 2024 bill is not enough; the senator must say what
--      it does to asylum." The nine at chair 3 each describe its mechanics in their
--      own words. Blumenthal supports the same bill and never does, so he is refused.
--   2. CHANGES  - Hirono moved from chair 1 to chair 2. Her passage is mostly what
--      she OPPOSES, and the ruling is that opposing one restrictive bill does not
--      reach the most permissive rung. 🔴 THE CONSEQUENCE IS THAT NOBODY SITS ON
--      CHAIR 1, and that is a decision rather than an absence of evidence.
--   3. APPROVED - a 2021 statement may be cited. Padilla's is from 2021-12-01, the
--      oldest citation seated in any federal batch. Kaine's 2019 passage is refused.
--
-- No chair was flagged and no refusal was contested.
--
-- -- WHY THE CITATIONS ARE SAFE ------------------------------------------------
--
-- 🔴 A CONGRESSIONAL RECORD PAGE CARRIES EVERY MEMBER WHO SPOKE ON IT. Bill-based
-- rows are tied to a person independently - the extend-by-bill pattern requires
-- their bioguide id in the BILLSTATUS roll - and the Record offers no such tie. A
-- row could cite a real page, satisfy every claim term in its raw HTML, and be
-- quoting somebody else. Measured: Padilla's surname and "asylum" co-occur in 90
-- granules and he speaks in 6.
--
-- `verify-reresearch-rows.mjs` closes that (check 5, PR #428): on a CREC citation
-- the page's contribution to the claim-term check narrows to that senator's own
-- SPEAKING TURNS. All 12 rows pass it. Two of them - Peters and Baldwin - cite the
-- same granule and are narrowed to 3,544 and 5,905 characters respectively.
--
-- ⚠ PRINTED TEXT IS NOT SPEECH (PR #430). A senator who asks that a bill be printed
-- in the Record "speaks" the whole bill; Durbin's 2023-05-15 turn was 24,000
-- characters of S. 1600. Those turns are truncated to the spoken part before
-- anything is read from them, which is why two of the refusals below are refusals.
--
-- -- WHAT IS ABSENT, AND WHY --------------------------------------------------
--
-- 15 of the 27 senators with an on-axis floor turn are REFUSED, and the refusals are
-- part of the work rather than a gap in it:
--
--   · Welch, Van Hollen, Schiff - real evidence, WRONG QUESTION. Deportation, ICE
--     conduct and due process, not who may claim asylum. Welch says outright that
--     "the border is secure... I support that".
--   · Capito, Wicker - crisis framing with no eligibility position. Capito is the
--     closest call in the batch and was NOT contested on review.
--   · Sanders, Merkley, Coons, Markey, Moody - one passage or one clause. Markey's
--     is a single clause inside a 40,000-character speech about healthcare.
--   · Durbin - 23 on-axis turns, more than anyone, and no rung they point at.
--   · Bennet, Wyden - motions to commit read into the Record. Not speech.
--   · Blumenthal - governed by rule 1 above.
--   · Kaine - January 2019, governed by rule 3.
--
-- A further 18 of the 45 off-axis-only senators have NO on-axis floor turn at all,
-- across up to 99 granules each plus every Senate granule from 15 asylum debate days.
--
-- -- PROVENANCE --------------------------------------------------------------
--
-- 🔴 editor_id IS NULL ON BOTH TABLES, DELIBERATELY, for CC_0074's reason: the prose
-- was drafted in an assisted research session and reviewed before this migration was
-- applied. Approval is not authorship, and no EV user account wrote it.
--
-- ⚠ EACH REASONING IS THE SENATOR'S OWN WORDS, lightly joined. Editing one will
-- break check 4: every distinctive term was found in that senator's speaking turn
-- because the string was written from it.

-- -----------------------------------------------------------------------------
-- The rows
-- -----------------------------------------------------------------------------
-- Reasoning is PER PERSON here, not per basis. On gun policy and Israel one bill
-- carried many senators and the prose was shared; a floor statement is one person's
-- words by definition, so there is nothing to share.
CREATE TEMPORARY TABLE _cc0085_rows (
  politician_id uuid    NOT NULL,
  who           text    NOT NULL,
  value         numeric NOT NULL,
  reasoning     text    NOT NULL,
  sources       text[]  NOT NULL
) ON COMMIT DROP;

INSERT INTO _cc0085_rows VALUES
  ('b700099a-8cab-44b6-81b8-d678d646ae88', 'Christopher Murphy', 3, 'The border is a mess. It is too chaotic. We can''t handle 10,000 people crossing on some days. And I believe the asylum system is broken. It reforms the asylum system, a comprehensive reform, so that it doesn''t take 10 years to get your asylum claim adjudicated; it will take months.',
   ARRAY['https://www.govinfo.gov/content/pkg/CREC-2024-02-06/html/CREC-2024-02-06-pt1-PgS406.htm']),
  ('2b8d4b89-2d7c-4b67-a5a1-72bd7c766e1e', 'James Lankford', 3, 'Asylum is very difficult to achieve. Only about 3 percent of the people that actually go through the hearings actually achieve asylum. So now we have thousands of people crossing our border asking for asylum, not because they believe they qualify but because they know they will stay here somewhere between 6 and 10 years while they wait for the hearing. When you cross the border, first person each day, they would have a much faster screening.',
   ARRAY['https://www.govinfo.gov/content/pkg/CREC-2024-09-12/html/CREC-2024-09-12-pt1-PgS6013.htm']),
  ('6160a29a-d896-4061-801a-e5c3d9f06c99', 'Jon Ossoff', 3, 'A border security bill that would surge enforcement resources to the southern border; that would tighten asylum standards; that would expedite the removal of those who abuse asylum to enter our country unlawfully; that would hire urgently needed Border Patrol officers.',
   ARRAY['https://www.govinfo.gov/content/pkg/CREC-2024-05-22/html/CREC-2024-05-22-pt1-PgS3838-4.htm']),
  ('7e1e1044-a98b-4c69-910e-73de8e818c48', 'Mark Kelly', 3, 'We would get more Border Patrol agents, more technology to stop fentanyl, more asylum officers to quickly screen asylum claims, and more judges to bring down this massive backlog of cases. We would have an updated asylum system, authorities to prevent the border from being overwhelmed, and more visas to keep families together. We would have a more secure and fair process at the border.',
   ARRAY['https://www.govinfo.gov/content/pkg/CREC-2024-02-08/html/CREC-2024-02-08-pt1-PgS463-7.htm']),
  ('0f06ced9-84c7-4020-98fd-82ac25d49027', 'Patty Murray', 2, 'Under our existing asylum laws, noncitizens may apply for asylum at our Nation''s ports of entry. By providing people with advanced travel authorization, it allows them to avoid human traffickers and drug cartels and other criminal organizations. We need an immigration system that creates new pathways for legal status, eliminates dysfunction and backlogs.',
   ARRAY['https://www.govinfo.gov/content/pkg/CREC-2024-03-22/html/CREC-2024-03-22-pt1-PgS2578-2.htm', 'https://www.govinfo.gov/content/pkg/CREC-2024-02-06/html/CREC-2024-02-06-pt1-PgS404-3.htm']),
  ('dc92c805-4734-4d4b-8ceb-597e59b0e268', 'Mazie Hirono', 2, 'This bill eliminates the section of the law that allows people present in the United States to apply for asylum. This bill would also require that anyone, including families, seeking asylum at a port of entry be arrested and held in custody for the entire time their request is pending. With a backlog of over 3.6 million immigration cases, we need more immigration judges, not less.',
   ARRAY['https://www.govinfo.gov/content/pkg/CREC-2025-03-10/html/CREC-2025-03-10-pt1-PgS1623-8.htm']),
  ('af01a7ec-9318-4862-ba78-553e5908182c', 'Chuck Schumer', 3, 'It contained many of the biggest issues that our Republican colleagues have demanded: fixes to asylum, more money for border agents, and it increased the President''s emergency powers to respond to high numbers of border crossings. Democrats know that the situation at the border is unacceptable. We know that the status quo cannot continue.',
   ARRAY['https://www.govinfo.gov/content/pkg/CREC-2024-05-09/html/CREC-2024-05-09-pt1-PgS3629-9.htm']),
  ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f', 'Alex Padilla', 2, 'It is unsafe for many of them to remain in their countries, and so they make the arduous journey to the United States to seek asylum. We must thoughtfully address the root causes of migration and reform our border to ensure an orderly, secure, and well-managed process that treats migrants fairly and humanely.',
   ARRAY['https://www.govinfo.gov/content/pkg/CREC-2021-12-01/html/CREC-2021-12-01-pt1-PgS8837-6.htm']),
  ('3d51cca6-7206-413b-ab8d-3199a58a6767', 'Amy Klobuchar', 3, 'It would have given the President emergency authority to shut down the border when our border agents are overwhelmed. It would have made changes to our asylum system. It would have addressed processing issues and backlogs. It would have actually expanded legal immigration for things like work permits and visas.',
   ARRAY['https://www.govinfo.gov/content/pkg/CREC-2024-02-09/html/CREC-2024-02-09-pt1-PgS565-7.htm']),
  ('100de02f-b44d-4587-9b90-19aa5081708c', 'Brian Schatz', 3, 'This bill will expedite the asylum process; it would provide immediate work authorizations; it would expand legal immigration pathways. It makes real reforms and meaningful investments to address a real crisis at the border that needs to be fixed.',
   ARRAY['https://www.govinfo.gov/content/pkg/CREC-2024-05-23/html/CREC-2024-05-23-pt1-PgS3865-2.htm']),
  ('7b77ec48-f6d0-4b10-84bf-d15607fcbd2d', 'Gary Peters', 3, 'This bill also aims to change the asylum application process, a priority that Congress has been unable to pass for decades. The bill would allow us to hire more than 2,000 CBP officers, addressing a critical shortage of frontline personnel who safeguard our national security at points of entry.',
   ARRAY['https://www.govinfo.gov/content/pkg/CREC-2024-05-22/html/CREC-2024-05-22-pt1-PgS3830.htm']),
  ('ac7faadb-52c2-4e13-9073-3a607a4f8e57', 'Tammy Baldwin', 3, 'The result was a strong measure, even endorsed by the largest Border Patrol union, that curbs the flow of fentanyl from coming across our border, expedites our asylum process, and boosts border security.',
   ARRAY['https://www.govinfo.gov/content/pkg/CREC-2024-05-22/html/CREC-2024-05-22-pt1-PgS3830.htm']);

CREATE TEMPORARY TABLE _cc0085_before (answers int NOT NULL, context int NOT NULL) ON COMMIT DROP;

-- -----------------------------------------------------------------------------
-- 1. Preconditions
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_s2 uuid;
  v_n  int;
  v_r2 text;
  v_r3 text;
BEGIN
  SELECT id INTO v_s2 FROM inform.seasons WHERE status = 'open';
  IF v_s2 IS NULL THEN
    RAISE EXCEPTION 'CC_0085: no season is open - every compass write path refuses in that state';
  END IF;
  IF (SELECT number FROM inform.seasons WHERE id = v_s2) <> 2 THEN
    RAISE EXCEPTION 'CC_0085: the open season is not Season 2';
  END IF;

  IF (SELECT count(*) FROM _cc0085_rows) <> 12 THEN
    RAISE EXCEPTION 'CC_0085: expected 12 rows, found %', (SELECT count(*) FROM _cc0085_rows);
  END IF;

  -- A name that disagrees with its id means the row was assembled wrongly.
  SELECT count(*) INTO v_n
    FROM _cc0085_rows r JOIN essentials.politicians p ON p.id = r.politician_id
   WHERE lower(p.full_name) <> lower(r.who);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0085: % row(s) name a different person than their politician_id resolves to', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM _cc0085_rows r
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = r.politician_id);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0085: % politician_id(s) match nobody', v_n;
  END IF;

  -- The topic must be one the OPEN SEASON asks, not merely is_live - the CC_0066
  -- defect. All 17 promoted Season 2 topics carry is_live = false.
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics_promoted pr
      JOIN inform.season_questions sq ON sq.topic_id = pr.id AND sq.season_id = v_s2
     WHERE pr.topic_key = 'border-security'
  ) THEN
    RAISE EXCEPTION 'CC_0085: border-security is not a question the open season asks';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics t
      JOIN inform.compass_topic_roles r ON r.topic_id = t.id
     WHERE t.topic_key = 'border-security' AND r.role_scope = 'federal'
  ) THEN
    RAISE EXCEPTION 'CC_0085: border-security does not admit the federal tier';
  END IF;

  -- No prior answer in ANY published season: this file INSERTs and must not shadow.
  SELECT count(*) INTO v_n
    FROM _cc0085_rows r
    JOIN inform.politician_answers a ON a.politician_id = r.politician_id
    JOIN inform.compass_topics t ON t.id = a.topic_id AND t.topic_key = 'border-security'
    JOIN inform.seasons s ON s.id = a.season_id AND s.status <> 'draft';
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0085: % of these senators already hold a border-security answer', v_n;
  END IF;

  -- Print the rungs this season SERVES (ADR 0006: a season binds to a VERSION and
  -- serves the latest published revision of it, which may be newer than the pin).
  SELECT sr.text INTO v_r2
    FROM inform.season_questions sq
    JOIN inform.compass_topics_promoted pr ON pr.id = sq.topic_id AND pr.topic_key = 'border-security'
    JOIN LATERAL (
      SELECT e.id FROM inform.compass_topic_revisions pin
       JOIN inform.compass_topic_revisions e
         ON e.topic_id = pin.topic_id AND e.version = pin.version
        AND e.status IN ('published','superseded')
       WHERE pin.id = sq.topic_revision_id ORDER BY e.revision DESC LIMIT 1
    ) eff ON true
    JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = eff.id AND sr.value = 2
   WHERE sq.season_id = v_s2;
  SELECT sr.text INTO v_r3
    FROM inform.season_questions sq
    JOIN inform.compass_topics_promoted pr ON pr.id = sq.topic_id AND pr.topic_key = 'border-security'
    JOIN LATERAL (
      SELECT e.id FROM inform.compass_topic_revisions pin
       JOIN inform.compass_topic_revisions e
         ON e.topic_id = pin.topic_id AND e.version = pin.version
        AND e.status IN ('published','superseded')
       WHERE pin.id = sq.topic_revision_id ORDER BY e.revision DESC LIMIT 1
    ) eff ON true
    JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = eff.id AND sr.value = 3
   WHERE sq.season_id = v_s2;

  INSERT INTO _cc0085_before
  SELECT (SELECT count(*) FROM inform.politician_answers a
            JOIN inform.seasons s ON s.id = a.season_id AND s.number = 2),
         (SELECT count(*) FROM inform.politician_context c
            JOIN inform.seasons s ON s.id = c.season_id AND s.number = 2);

  RAISE NOTICE 'CC_0085 preconditions OK: Season 2 open, 12 rows, names match ids, topic promoted and federal, no prior answers.';
  RAISE NOTICE 'CC_0085 served rung 2: %', v_r2;
  RAISE NOTICE 'CC_0085 served rung 3: %', v_r3;
  RAISE NOTICE 'CC_0085 baseline: Season 2 holds % answers / % context before this file.',
    (SELECT answers FROM _cc0085_before), (SELECT context FROM _cc0085_before);
END $$;

-- -----------------------------------------------------------------------------
-- 2. The answers
-- -----------------------------------------------------------------------------
-- The pin comes from season_questions and is never hand-typed, so
-- politician_answers_pin_fkey holds by construction.
INSERT INTO inform.politician_answers
  (politician_id, topic_id, value, season_id, topic_revision_id, editor_id)
SELECT r.politician_id, sq.topic_id, r.value, sq.season_id, sq.topic_revision_id, NULL
  FROM _cc0085_rows r
  CROSS JOIN (
    SELECT sq.season_id, sq.topic_id, sq.topic_revision_id
      FROM inform.season_questions sq
      JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
      JOIN inform.compass_topics_promoted pr ON pr.id = sq.topic_id AND pr.topic_key = 'border-security'
  ) sq;

-- -----------------------------------------------------------------------------
-- 3. The context
-- -----------------------------------------------------------------------------
-- CC_0058 §3f: every non-blank answer needs its context row, in the same season.
INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources, editor_id, updated_at)
SELECT r.politician_id, sq.topic_id, sq.season_id, sq.topic_revision_id, r.reasoning, r.sources, NULL, now()
  FROM _cc0085_rows r
  CROSS JOIN (
    SELECT sq.season_id, sq.topic_id, sq.topic_revision_id
      FROM inform.season_questions sq
      JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
      JOIN inform.compass_topics_promoted pr ON pr.id = sq.topic_id AND pr.topic_key = 'border-security'
  ) sq;

-- -----------------------------------------------------------------------------
-- 4. Post-verify
-- -----------------------------------------------------------------------------
-- 🔴 ASSERT THE DELTA, NEVER A CORPUS TOTAL. CC_0078 shipped absolute totals and
-- went stale before a human had finished reviewing its chairs; a file that waits for
-- review cannot know the total at apply time.
DO $$
DECLARE
  v_a int; v_c int; v_b_a int; v_b_c int; v_n int; v_topic uuid; v_s2 uuid;
BEGIN
  SELECT answers, context INTO v_b_a, v_b_c FROM _cc0085_before;
  SELECT id INTO v_s2 FROM inform.seasons WHERE status = 'open';
  SELECT pr.id INTO v_topic FROM inform.compass_topics_promoted pr WHERE pr.topic_key = 'border-security';

  SELECT count(*) INTO v_a FROM inform.politician_answers a
    JOIN inform.seasons s ON s.id = a.season_id AND s.number = 2;
  SELECT count(*) INTO v_c FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.number = 2;

  IF v_a - v_b_a <> 12 THEN
    RAISE EXCEPTION 'CC_0085: expected exactly 12 new answers, got %', v_a - v_b_a;
  END IF;
  IF v_c - v_b_c <> 12 THEN
    RAISE EXCEPTION 'CC_0085: expected exactly 12 new context rows, got %', v_c - v_b_c;
  END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE a.season_id = v_s2 AND a.topic_id = v_topic AND a.value NOT IN (2, 3);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0085: % border-security answer(s) at a value this file never writes', v_n;
  END IF;

  -- The CC_0058 §3f pair invariant, checked SEASON-WIDE rather than on the new rows:
  -- a file that satisfies it locally and breaks it globally is the failure to catch.
  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
   WHERE a.season_id = v_s2 AND a.value <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id = a.politician_id
                        AND c.topic_id = a.topic_id AND c.season_id = a.season_id);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0085: % non-blank Season 2 answer(s) have no context row', v_n;
  END IF;

  RAISE NOTICE 'CC_0085 OK: 12 answers + 12 context (9 at chair 3, 3 at chair 2). border-security now holds % Season 2 answers. Season 2 now % answers / % context - RAISE THE FLOORS TO THESE NUMBERS, in a separate PR, now that the file is applied.',
    (SELECT count(*) FROM inform.politician_answers a WHERE a.season_id = v_s2 AND a.topic_id = v_topic),
    v_a, v_c;
END $$;

COMMIT;
