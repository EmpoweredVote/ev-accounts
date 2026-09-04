BEGIN;

-- =============================================================================
-- CC_0074: the Senate pilot's first four researched answers
-- =============================================================================
-- Slot CC_0074 reserved via `steward slot CC` before this file existed.
--
-- WHAT THIS IS. Four answers for California's two U.S. Senators on two of the
-- nine topics Season 2 added for federal officeholders, plus the four context
-- rows that justify them. It is the first output of the federal research pass,
-- and it is deliberately small: the pilot exists to measure the real per-row
-- cost, not to fill the corpus.
--
--   Alex Padilla    gun-policy      chair 2
--   Alex Padilla    minimum-wage    chair 1
--   Adam B. Schiff  gun-policy      chair 2
--   Adam B. Schiff  minimum-wage    chair 1
--
-- 🔴 DO NOT APPLY THIS UNTIL THE CHAIRS HAVE BEEN REVIEWED BY A HUMAN. Every row
-- here is a published claim about a named sitting senator. The rows passed
-- `verify-reresearch-rows.mjs --tier=federal` end to end — right tier, promoted
-- topic, and every distinctive claim term in the reasoning present in the raw
-- HTML of the cited page (13/13, 10/10, 14/14, 10/10) — but that gate proves the
-- reasoning is CARRIED BY the source, never that the chair is the right reading
-- of it. The chair is an editorial judgement and needs a person to agree with it.
--
-- ── WHY THESE CHAIRS ─────────────────────────────────────────────────────────
--
-- gun-policy = 2 ("Ban semi-automatic assault-style weapons, while allowing
--   other firearms"). Both senators lead the Assault Weapons Ban of 2025,
--   introduced 2025-04-30, which prohibits the sale, transfer, manufacture and
--   import of assault weapons and high-capacity magazines while leaving other
--   firearms legal. Chair 3 stops at universal background checks and would
--   understate a lead sponsor of the ban itself; chair 1 would overstate badly,
--   since nothing on either record proposes banning civilian ownership.
--
-- minimum-wage = 1 ("Raise the wage floor and tie it to the cost of living, so
--   it rises automatically each year without new legislation"). Both are ORIGINAL
--   cosponsors of S. 1332, the Raise the Wage Act of 2025, whose text raises the
--   floor to $17.00 and then adjusts it "annually thereafter" by the annual
--   percentage increase in the median hourly wage of all employees. Chair 2
--   requires that the floor "adjust only when lawmakers vote to", which this bill
--   explicitly does not.
--
--   ⚠ ONE HONEST GLOSS, recorded so a reviewer meets it here rather than later:
--     the chair says "tied to the cost of living" and the bill indexes to MEDIAN
--     WAGE GROWTH. The distinction the ladder actually draws is automatic-versus-
--     legislated, and on that the bill text is unambiguous. If the reviewer reads
--     the chair as strictly CPI, these two rows become chair 2 and the answer
--     floor below still holds.
--
--   ⚠ Padilla's own issues page says "$15 an hour" and stops there, which reads
--     as chair 2. The bill he cosponsors says $17 WITH indexing. The office page
--     is dated and incomplete; the bill text wins. This is why the pass reads
--     bill text and not issue pages.
--
-- ── WHAT IS DELIBERATELY ABSENT ──────────────────────────────────────────────
--
-- Fourteen of the eighteen (senator, topic) pairs are NOT here, and their absence
-- is a finding rather than a gap. Two are worth naming because the obvious
-- inference points the wrong way:
--
--   defense-spending — both voted Nay on the FY2026 NDAA (roll call 570,
--     2025-10-09). Their joint statement gives the reason as DOMESTIC TROOP
--     DEPLOYMENT and describes the NDAA's purpose as giving the military "the
--     resources it needs". Reading "wants less defense spending" out of that vote
--     would have been exactly backwards.
--
--   military-intervention — a war powers cosponsorship (S.J.Res. 104) and an
--     Article I letter are about WHO AUTHORIZES force; the ladder asks WHEN force
--     is warranted. Real evidence, wrong question.
--
-- No row is written for either. `CC_0057`'s value 0 is for "researched, and no
-- rung states what they hold"; these are "not researched to a conclusion", which
-- is an absent row, not a blank.
--
-- ── PROVENANCE ───────────────────────────────────────────────────────────────
--
-- 🔴 editor_id IS NULL ON BOTH TABLES, DELIBERATELY. The prose here was drafted
-- in an assisted research session and reviewed before this migration was applied;
-- there is no EV user account that authored it. Attributing it to whoever applies
-- the migration would put a person's name on words they did not write, which is
-- the same defect CC_0058 avoided from the other direction. The provenance is
-- this file.
--
-- ⚠ THE REASONING READS AS CLIPPED, AND THAT IS THE GATE'S DOING. The verifier
-- requires every distinctive term to appear in the cited page's RAW HTML, so the
-- prose is written in each source's own vocabulary. A first draft failed on
-- "supports", "cosponsored" and "rises" — all words a summary of the page used
-- and the page itself does not. Editing these strings for flow WILL break the
-- gate; re-run the verifier if you touch them.

-- -----------------------------------------------------------------------------
-- The rows, as one editorial artefact
-- -----------------------------------------------------------------------------
-- politician_id, not full_name: TWO ACTIVE PEOPLE ARE NAMED "ALEX PADILLA" — the
-- senator and an Inglewood city councilmember. A name-keyed row for him is
-- ambiguous, which is why the research CSV grew a politician_id column.
CREATE TEMPORARY TABLE _cc0074_rows (
  politician_id uuid    NOT NULL,
  who           text    NOT NULL,   -- cross-check only; the id decides
  topic_key     text    NOT NULL,
  value         numeric NOT NULL,
  reasoning     text    NOT NULL,
  sources       text[]  NOT NULL
) ON COMMIT DROP;

INSERT INTO _cc0074_rows VALUES
  ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f', 'Alex Padilla', 'gun-policy', 2,
   'Expanding background checks for the sale or transfer of all firearms; banning military-style assault weapons and high-capacity ammunition magazines; reintroduction of the Assault Weapons Ban.',
   ARRAY['https://www.padilla.senate.gov/issues/gun-violence/']),

  ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f', 'Alex Padilla', 'minimum-wage', 1,
   'The Raise the Wage Act ties the minimum wage, annually thereafter, to the annual percentage increase in the median hourly wage of all employees.',
   ARRAY['https://www.govinfo.gov/content/pkg/BILLS-119s1332is/html/BILLS-119s1332is.htm']),

  ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032', 'Adam B. Schiff', 'gun-policy', 2,
   'Lead cosponsor of legislation to prohibit the sale, transfer, manufacture, and import of assault weapons, high-capacity magazines, and other high-capacity ammunition feeding devices.',
   ARRAY['https://www.padilla.senate.gov/newsroom/press-releases/padilla-schiff-murphy-blumenthal-mcbath-reintroduce-assault-weapons-ban/']),

  ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032', 'Adam B. Schiff', 'minimum-wage', 1,
   'The Raise the Wage Act ties the minimum wage, annually thereafter, to the annual percentage increase in the median hourly wage of all employees.',
   ARRAY['https://www.govinfo.gov/content/pkg/BILLS-119s1332is/html/BILLS-119s1332is.htm']);

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
    RAISE EXCEPTION 'CC_0074: no season is open — every compass write path refuses in that state';
  END IF;
  IF (SELECT number FROM inform.seasons WHERE id = v_s2) <> 2 THEN
    RAISE EXCEPTION 'CC_0074: the open season is not Season 2 — these chairs were researched against Season 2 ladders';
  END IF;

  -- The id is authoritative, but a name that has drifted means the file was
  -- assembled against a different roster than the one in front of us.
  SELECT count(*) INTO v_n
    FROM _cc0074_rows r
    JOIN essentials.politicians p ON p.id = r.politician_id
   WHERE lower(p.full_name) <> lower(r.who);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0074: % row(s) name a different person than their politician_id resolves to', v_n;
  END IF;

  -- Every topic must be one the OPEN season asks — the CC_0066 rule. is_live is
  -- false on all 17 new Season 2 topics and must not be consulted here.
  SELECT count(*) INTO v_n
    FROM _cc0074_rows r
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.compass_topics_promoted pr WHERE pr.topic_key = r.topic_key);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0074: % row(s) name a topic the open season does not ask', v_n;
  END IF;

  -- Federal tier, since this is a federal cohort and an out-of-tier row would
  -- never display for these officeholders.
  SELECT count(*) INTO v_n
    FROM _cc0074_rows r
    JOIN inform.compass_topics t ON t.topic_key = r.topic_key
   WHERE EXISTS (SELECT 1 FROM inform.compass_topic_roles cr WHERE cr.topic_id = t.id)
     AND NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles cr
                      WHERE cr.topic_id = t.id AND cr.role_scope = 'federal');
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0074: % row(s) sit on a topic that excludes the federal tier', v_n;
  END IF;

  -- INSERT, not UPDATE. If any pair already holds a Season 2 answer this file has
  -- been run before, or somebody researched it in the meantime; either way stop
  -- rather than silently overwrite a stance.
  SELECT count(*) INTO v_n
    FROM _cc0074_rows r
    JOIN inform.compass_topics t ON t.topic_key = r.topic_key
    JOIN inform.politician_answers a
      ON a.politician_id = r.politician_id AND a.topic_id = t.id AND a.season_id = v_s2;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0074: % pair(s) already hold a Season 2 answer — this file has run, or the rows are stale', v_n;
  END IF;

  IF (SELECT count(*) FROM _cc0074_rows) <> 4 THEN
    RAISE EXCEPTION 'CC_0074: expected exactly 4 rows, found %', (SELECT count(*) FROM _cc0074_rows);
  END IF;

  RAISE NOTICE 'CC_0074 preconditions OK: Season 2 open, 4 rows, names match ids, all topics promoted and federal, no prior answers.';
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
       r.value,
       NULL,
       NULL,
       now()
  FROM _cc0074_rows r
  JOIN inform.compass_topics t    ON t.topic_key = r.topic_key
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
       r.reasoning,
       r.sources,
       NULL,
       now()
  FROM _cc0074_rows r
  JOIN inform.compass_topics t    ON t.topic_key = r.topic_key
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

  -- 4a. every intended row landed, at the intended value
  SELECT count(*) INTO v_n
    FROM _cc0074_rows r
    JOIN inform.compass_topics t ON t.topic_key = r.topic_key
    JOIN inform.politician_answers a
      ON a.politician_id = r.politician_id AND a.topic_id = t.id AND a.season_id = v_s2
   WHERE a.value = r.value;
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0074: % of 4 answers landed at the intended chair', v_n;
  END IF;

  -- 4b. each carries its reasoning and at least one source
  SELECT count(*) INTO v_n
    FROM _cc0074_rows r
    JOIN inform.compass_topics t ON t.topic_key = r.topic_key
    JOIN inform.politician_context c
      ON c.politician_id = r.politician_id AND c.topic_id = t.id AND c.season_id = v_s2
   WHERE c.reasoning = r.reasoning
     AND array_length(c.sources, 1) >= 1;
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CC_0074: % of 4 context rows landed with their reasoning and a source', v_n;
  END IF;

  -- 4c. the season-wide pair invariant still holds: no non-blank answer without
  --     context, and no blank carrying prose. This is CC_0058 §3f, re-checked
  --     because this migration is the first thing to add to that season since.
  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
   WHERE a.season_id = v_s2 AND a.value <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
                        AND c.season_id = a.season_id);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0074: % non-blank Season 2 answer(s) carry no reasoning', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id AND c.season_id = a.season_id
   WHERE a.season_id = v_s2 AND a.value = 0;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0074: % blanked answer(s) carry Season 2 reasoning', v_n;
  END IF;

  -- 4d. the corpus grew by exactly four and four.
  --
  -- 🔴 RAISE THE SEASON 2 FLOORS TO 2689 / 2661 ONLY AFTER THIS IS APPLIED, AND
  --    NOT IN THE PR THAT MERGES THIS FILE. The same-PR rule in
  --    check-season-corpus-floor.mjs is about LOWERING: a blanking migration cuts
  --    the count the moment it is applied ad hoc, so the gate goes red hours later
  --    unless its own PR drops the floor with it. Raising inverts the ordering —
  --    migrations here are never replayed by a deploy, so at merge time these four
  --    rows do not exist yet, and a floor of 2689 against a corpus of 2685 fails
  --    the nightly gate for the opposite reason. Apply first, then raise.
  SELECT count(*) INTO v_answers FROM inform.politician_answers WHERE season_id = v_s2;
  SELECT count(*) INTO v_context FROM inform.politician_context WHERE season_id = v_s2;
  IF v_answers <> 2689 THEN
    RAISE EXCEPTION 'CC_0074: Season 2 holds % answers, expected 2689 (2685 + 4)', v_answers;
  END IF;
  IF v_context <> 2661 THEN
    RAISE EXCEPTION 'CC_0074: Season 2 holds % context rows, expected 2661 (2657 + 4)', v_context;
  END IF;

  RAISE NOTICE 'CC_0074 OK: 4 answers + 4 context into Season 2. Season 2 now % answers / % context. Raise the floors to match.',
    v_answers, v_context;
END $$;

COMMIT;
