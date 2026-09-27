-- CC_0158 — Patrick Schmidt / Social Security: a documented BLANK in the open season.
--
-- ⚠ THE RESERVED PURPOSE STRING FOR THIS SLOT SAYS "re-point ... to the archived campaign issue
-- page". That was the plan and it was wrong. The slot is reused rather than abandoned because it is
-- the same work item and no file was ever written under the old purpose; what changed is the
-- disposition, and this header is the record of why.
--
-- ── HOW THIS STARTED ────────────────────────────────────────────────────────────────────────────
-- The master-push job `stance sourcing` went red on 2026-09-27 with
--   BALLOTPEDIA_ONLY  ks  observed 1 (NEW state — this state was clean before)
-- The row had not changed; CC_0157 seated Schmidt and its state bucket moved. That is the gate's
-- defect and is fixed separately, in the same branch. This file is about the ROW, which was a real
-- BALLOTPEDIA_ONLY violation all along and simply had no state to be counted under.
--
-- ── WHY THIS IS NOT A CITATION REPAIR ───────────────────────────────────────────────────────────
-- The obvious fix was to re-point the citation at the primary Ballotpedia was quoting. Reading the
-- page and the ladder killed that plan twice over.
--
-- 🔴 FIRST: the row is in SEASON 1, WHICH IS CLOSED. An UPDATE raises CLOSED_SEASON_IMMUTABLE
-- (ADR 0005 §1.6 step 5) — proven by dry run, not assumed. The schema's own remedy is to write a row
-- in the OPEN season, which shadows the old one on read without destroying it. That is what this
-- migration does.
--
-- 🔴🔴 SECOND, AND THE REAL REASON: THE CHAIR IS UNDER-EVIDENCED, SO RE-POINTING WOULD HAVE
-- LAUNDERED A GUESS. Season 2 chair 2 reads, verbatim from the season pin:
--     "increase Social Security benefits modestly WHILE RAISING TAXES ON HIGHER EARNERS to
--      strengthen the program."
-- It is a compound chair, and CLAUDE.md requires every clause. The only evidence is his 2022
-- congressional campaign site, which says:
--     "I will fight to make sure we never have to raise the retirement age and that Social Security
--      always keeps up with inflation. And you can be sure that I will oppose any efforts by
--      Republicans to cut or privatize Social Security and Medicare."
-- That establishes a DIRECTION — against a higher retirement age, against cuts, against
-- privatisation — and neither clause of chair 2. "Keeps up with inflation" is maintaining purchasing
-- power, not increasing benefits, and there is no tax clause at all. The stored Season 1 reasoning
-- even reaches for the tiebreaker CLAUDE.md names as the tell: "matched to the modest-strengthening
-- chair RATHER THAN full expansion".
-- ▶ "Evidence that establishes only the direction under-determines which chair applies. The honest
--   alternative to a guessed chair is a blank spoke. A blank spoke is correct."
--
-- ⚠ AND THE CARVE-OUT WOULD HAVE ACCEPTED THE WRONG THING. The gate treats a Ballotpedia URL
-- anchored at #Campaign_themes as the candidate's own words. Under that one heading Ballotpedia
-- renders the per-year Candidate Connection blocks AND a separate `Campaign website` block
-- introduced by "Schmidt's campaign website stated the following:". The Social Security text is in
-- the latter. Schmidt did NOT complete the 2024 or 2026 survey. So a #Campaign_themes deep link
-- would have satisfied the gate while citing a conduit. The carve-out regex is deliberately NOT
-- touched here — CLAUDE.md forbids making rows fall out by widening it.
--
-- ── WHY NO BETTER SOURCE EXISTS ─────────────────────────────────────────────────────────────────
-- Chased and recorded so nobody repeats it:
--   * https://patrickforkansas.com/issue/seniors/ — the page Ballotpedia quoted — is now a hard 404
--     (HTTP 404, 47,797 bytes, a styled error page, not a soft-404).
--   * The live domain is a donation splash for his 2026 U.S. Senate run: 1,656 characters of text,
--     ZERO occurrences of "Social Security", "retirement age" or "Medicare".
--   * He completed neither the 2024 nor the 2026 Candidate Connection survey (the page says so).
--   * Social Security is FEDERAL. His Kansas Senate service cannot produce a record on it, so the
--     seat CC_0157 gave him is no help.
-- The archived copy is therefore the best primary there is, and it is cited here as the record of
-- what was read — not as support for a chair, because it does not support one.
--
-- ── WHAT A VOTER SEES AFTER THIS ────────────────────────────────────────────────────────────────
-- The Season 2 row wins the read path's newest-season collapse and is then dropped by the zero
-- filter, so the spoke goes blank instead of showing an unevidenced chair 2. Verified against the
-- code before writing, not assumed:
--   * SEASON_IS_PUBLISHED is `s.status <> 'draft'`, so the OPEN season is served;
--   * every collapse is `DISTINCT ON (a.topic_id) ... ORDER BY a.topic_id, s.number DESC`, and
--     Season 2 is number 2 against Season 1's 1;
--   * `WHERE value != 0` sits OUTSIDE the collapse at all four sites (compassService.ts:421, 428,
--     516, 536 and the per-politician fetch at 661), which is the placement CLAUDE.md requires —
--     inside it, a blank would silently fall back to the Season 1 rung.
-- Season 1 keeps its row. That is the point of seasons: "We will remember the difference between
-- seasons 1 and 2" (ruling 2026-09-02).
--
-- ⚠ THIS DOES NOT LOWER THE GATE COUNT, AND THAT IS EXPECTED. check-stance-sources.mjs has no season
-- filter, so the Season 1 row keeps counting as BALLOTPEDIA_ONLY. 159 of that backlog sit in the
-- closed season and 152 are unsuperseded, which makes the baseline's "these numbers should only ever
-- go DOWN" unachievable for them by the route the trigger recommends. Reported, not papered over:
-- no baseline is touched by this migration.
--
-- Idempotent: both writes are ON CONFLICT DO NOTHING, guarded on the season pin.

BEGIN;

-- The answer: a blank. value = 0 is "researched, no chair the evidence names", NOT rung 0.
-- write_in_text must stay NULL — politician_answers_blank_has_no_write_in enforces it.
INSERT INTO inform.politician_answers (politician_id, topic_id, season_id, topic_revision_id, value)
SELECT 'b21b5e5e-3359-4692-a60d-47d459bbb198',
       '87d20824-a6e9-407b-983c-65440084a0ab',
       sq.season_id,
       sq.topic_revision_id,
       0
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
 WHERE sq.topic_id = '87d20824-a6e9-407b-983c-65440084a0ab'
ON CONFLICT (politician_id, topic_id, season_id) DO NOTHING;

-- The context: what was read, and why it does not reach a chair. `reasoning` is voter-facing
-- (Citations.jsx), so it is written to be read by a voter, not by an editor.
INSERT INTO inform.politician_context (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
SELECT 'b21b5e5e-3359-4692-a60d-47d459bbb198',
       '87d20824-a6e9-407b-983c-65440084a0ab',
       sq.season_id,
       sq.topic_revision_id,
       'No position on this scale is established by the available record. Patrick Schmidt''s 2022 '
       'congressional campaign site said he would "fight to make sure we never have to raise the '
       'retirement age and that Social Security always keeps up with inflation", and would "oppose '
       'any efforts by Republicans to cut or privatize Social Security and Medicare". That shows a '
       'clear direction — against a higher retirement age, against benefit cuts and against '
       'privatisation — but it does not show which of the options on this scale he holds: keeping '
       'benefits level with inflation is not the same as increasing them, and he has not said '
       'whether he would raise taxes to fund the program. He did not complete Ballotpedia''s 2024 '
       'or 2026 candidate survey, and Social Security is decided federally, so his service in the '
       'Kansas Senate does not add a record on it. We would rather leave this blank than state a '
       'position he has not taken.',
       ARRAY[
         'https://web.archive.org/web/20220524215906/https://patrickforkansas.com/issue/seniors/',
         'https://ballotpedia.org/Patrick_Schmidt'
       ]
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
 WHERE sq.topic_id = '87d20824-a6e9-407b-983c-65440084a0ab'
ON CONFLICT (politician_id, topic_id, season_id) DO NOTHING;

-- Post-verify gate. Asserts the END STATE, so a re-run that inserts nothing still passes.
DO $$
DECLARE
  v_open     uuid;
  v_value    numeric;
  v_write_in text;
  v_sources  text[];
  v_s1_value numeric;
  v_served   numeric;
BEGIN
  SELECT id INTO v_open FROM inform.seasons WHERE status = 'open';
  IF v_open IS NULL THEN
    RAISE EXCEPTION 'CC_0158: no open season — refusing to guess which season to write';
  END IF;

  SELECT pa.value, pa.write_in_text, pc.sources
    INTO v_value, v_write_in, v_sources
    FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
     AND pc.season_id = pa.season_id
   WHERE pa.politician_id = 'b21b5e5e-3359-4692-a60d-47d459bbb198'
     AND pa.topic_id      = '87d20824-a6e9-407b-983c-65440084a0ab'
     AND pa.season_id     = v_open;

  IF v_value IS NULL THEN
    RAISE EXCEPTION 'CC_0158: the open-season answer+context pair was not written';
  END IF;
  IF v_value <> 0 THEN
    RAISE EXCEPTION 'CC_0158: the open-season answer is %, not a blank', v_value;
  END IF;
  IF v_write_in IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0158: a blank must carry no write_in_text';
  END IF;
  IF cardinality(v_sources) <> 2 THEN
    RAISE EXCEPTION 'CC_0158: expected 2 sources on the blank, found %', cardinality(v_sources);
  END IF;

  -- 🔴 SEASON 1 MUST BE UNTOUCHED. This migration shadows history; it does not edit it. If this
  -- assertion ever fails, something wrote through the closed-season trigger.
  SELECT value INTO v_s1_value
    FROM inform.politician_answers pa
    JOIN inform.seasons s ON s.id = pa.season_id AND s.number = 1
   WHERE pa.politician_id = 'b21b5e5e-3359-4692-a60d-47d459bbb198'
     AND pa.topic_id      = '87d20824-a6e9-407b-983c-65440084a0ab';
  IF v_s1_value IS DISTINCT FROM 2.0 THEN
    RAISE EXCEPTION 'CC_0158: the Season 1 row changed (now %) — history must survive', v_s1_value;
  END IF;

  -- The assertion that actually matters to a voter: reproduce the read path's newest-season collapse
  -- and confirm it now lands on the blank, so the spoke stops showing chair 2.
  SELECT l.value INTO v_served FROM (
    SELECT DISTINCT ON (a.topic_id) a.topic_id, a.value
      FROM inform.politician_answers a
      JOIN inform.seasons s ON s.id = a.season_id AND s.status <> 'draft'
     WHERE a.politician_id = 'b21b5e5e-3359-4692-a60d-47d459bbb198'
       AND a.topic_id      = '87d20824-a6e9-407b-983c-65440084a0ab'
     ORDER BY a.topic_id, s.number DESC
  ) l;
  IF v_served <> 0 THEN
    RAISE EXCEPTION 'CC_0158: the newest published season still serves % — the blank is not winning '
                    'the collapse', v_served;
  END IF;

  RAISE NOTICE 'CC_0158 OK — open-season blank written; Season 1 still reads %; the collapse now '
               'serves a blank, so the spoke renders empty', v_s1_value;
END $$;

COMMIT;
