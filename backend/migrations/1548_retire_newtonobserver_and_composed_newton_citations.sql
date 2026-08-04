-- 1548_retire_newtonobserver_and_composed_newton_citations.sql
--
-- Retire all 48 Newton stance rows whose entire citation set is unreachable-by-construction: an
-- invented outlet paired with a composed city path.
--
--   Review:   data/stance-research/reresearch-newton/FINDINGS.md
--   Rollback: data/stance-retirement/2026-08-04-newtonobserver-rollback.{json,md} carries every
--             retired row verbatim -- politician, topic, value, reasoning and sources -- so each can be
--             reinserted exactly. 17 of the 18 politicians drop to zero answers.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1548_retire_newtonobserver_and_composed_newton_citations.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY
-- ---------------------------------------------------------------------------------------------------
-- Found while roster-checking Newton for the re-research worklist. The 57 owed rows concentrate on
-- Environmental Protection (14) and Climate Change (12) -- the single-source clustering shape that
-- flagged the TCJA cluster -- and following it surfaced a larger defect OUTSIDE the worklist.
--
-- **48 rows across 18 Newton politicians cite `newtonobserver.com`, and NONE is sole-sourced.** That is
-- precisely why every prior sweep missed this host: **45 of the 48 pair it with
-- `newtonma.gov/government/city-council/agendas-minutes`**, so each row always had a second source that
-- looked resolvable. Identical row-level blind spot to the 2026-08-01 host sweep, whose query required
-- *every* source on a row to be a bare host.
--
-- Both citations were verified absent, each against a control verified IN THE SAME RUN rather than
-- assumed -- the clark.house.gov lesson, where an assumed control nearly buried a real finding:
--
--   * `newtonobserver.com` **does not resolve** (fetch failure on all three URLs tried). Wayback holds
--     **5 URLs ever**, dated 2011-02-08, and the samples are the bare root plus `?epl=...` **parking-page**
--     query strings -- the signature of an expired/parked domain, not a newspaper. Both cited article
--     paths came back ABSENT, reproduced across 3 successful probes each.
--     Controls, same run, same conditions: `figcitynews.com` and `newtonbeacon.org` -- Newton's real
--     outlets -- both HTTP 200 at ~200KB and archived within days, CDX capped at the 400-row limit.
--     This is a SIXTH invented outlet, after medfordmirror.com, newtonvillearea.com, alhambraource.com,
--     walthamtribunenews.com and walthamatch.com.
--     ⚠ The earlier "EXACTLY ONE invented hostname" bound was **congressional-surface only** and is not
--     contradicted by this.
--
--   * `newtonma.gov/government/city-council/agendas-minutes` came back ABSENT across 3 rounds, and
--     **sibling coverage decides it**: the cited directory `government/city-council/*` has **3** archived
--     URLs, under a different slug (`city-council-and-friday-packet`), while the real family
--     `government/city-clerk/city-council/*` has **300** (my query limit) -- including the 2026-04-22
--     capture this cluster's roster was read from. Composed, not merely unreadable.
--     ⚠ Separately, the live host is behind an **Akamai edge block** -- 403 to plain fetch, to a browser
--     UA, AND to Playwright. That is a bot block, NOT absence; the page renders fine for a voter. The
--     verdict above rests on Wayback sibling coverage, never on the 403.
--
-- So not one of these 48 rows has a citation a reader can check, which is the same standard migrations
-- 1494/1507/1508/1538 retired rows under, and the operator's standing rule applies: **verified absent ->
-- retire; never unsure -> retire.**
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 SEVEN OF THESE ROWS ARE ALSO FALSE ON THE MERITS -- THE 1537 DEFECT IN LOCAL GOVERNMENT
-- ---------------------------------------------------------------------------------------------------
-- Seven rows assert a vote "in October 2023" by **Sean Roche (3), Julie Irish (2), Jacob Silber (2)** --
-- all three elected 2025-11-04 and **sworn in 2026-01-01**, verified verbatim in Fig City News' newcomers
-- piece. They could not have cast it. Migration 1537 retired 36 pre-tenure rows but was scoped to
-- FEDERAL legislators via congressional roll calls; nothing has ever swept local officeholders, and a
-- tenure-shaped detector was impossible anyway because `office_terms.term_start` is NULL for essentially
-- every local official. Caught by reading, like everything else on this workstream.
-- ⚠ They also misdate the event: the council vote was **2023-12-04 (21-2-1**, Leary and Noel opposed,
-- Ryan absent); the October 2023 action was the **ZAP committee** vote (5-1-1).
--
-- ---------------------------------------------------------------------------------------------------
-- WHAT THIS COSTS, STATED PLAINLY
-- ---------------------------------------------------------------------------------------------------
-- Newton goes from **55 answers to 7**. **17 of the 19** people holding any answer drop to zero; only
-- R. Lisle Baker keeps anything (4 of 5). So Newton's purple "compass stances seeded" chip will be making
-- a promise the database no longer backs, exactly as Beverly Hills did after 1538 --
-- ⏳ **a coverage.js follow-up is owed in the essentials repo** (the Beverly Hills fix is commit ca993e74;
-- join occupancy through `essentials.office_terms`, NOT `politicians.office_id`).
--
-- ⚠ **12 of the 18 affected people were NOT in the re-research worklist**, because they kept these rows
-- and coverage is defined as "has >=1 answer", so they read as researched. After this they become
-- visible as unresearched, which is honest but expands the queue from 57 owed rows to ~105.
--
-- ⚠ NO `last_stances_researched_at` nulling is needed: measured before writing, **0 of the 17 emptied
-- politicians carries one** (it is already NULL for all of them), so the 1494/1507/1508 rule is already
-- satisfied and this migration deliberately updates no timestamps.

BEGIN;

-- The target set, defined by the invented host and materialised so both DELETEs hit exactly the same pairs.
CREATE TEMP TABLE _targets_1548 AS
SELECT c.politician_id, c.topic_id
  FROM inform.politician_context c
 WHERE EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s ILIKE '%newtonobserver.com%');

-- Snapshot the counts AND the pre-existing orphan population. 🔴 The first version of the verify block
-- asserted "0 context rows without an answer" corpus-wide and failed the dry run at **546** -- a
-- condition that predates this migration entirely (33,718 context - 33,172 answers = exactly 546). That
-- is the recurring shape on this workstream: an over-broad check that fires on something real but
-- unrelated. The right invariant is that THIS migration creates no NEW orphans, so the count is
-- snapshotted and asserted unchanged.
-- ⚠ Those 546 context rows are a separate, untouched finding: voter-facing `reasoning` stored for a
-- (politician, topic) pair with no answer. Not diagnosed here, deliberately not altered here.
CREATE TEMP TABLE _before_1548 AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS n_answers,
       (SELECT count(*) FROM inform.politician_context) AS n_context,
       (SELECT count(*) FROM inform.politician_context c
          LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
         WHERE a.politician_id IS NULL) AS n_context_orphans;

-- ---- pre-flight ------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_p int;
BEGIN
  SELECT count(*), count(DISTINCT politician_id) INTO v_n, v_p FROM _targets_1548;
  IF v_n <> 48 THEN RAISE EXCEPTION 'expected 48 target rows, found % — re-measure before deleting anything', v_n; END IF;
  IF v_p <> 18 THEN RAISE EXCEPTION 'expected 18 distinct politicians, found %', v_p; END IF;

  -- Every target must have BOTH an answer and a context row, or a DELETE would leave an orphan behind.
  SELECT count(*) INTO v_n FROM _targets_1548 t
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id=t.politician_id AND a.topic_id=t.topic_id);
  IF v_n <> 0 THEN RAISE EXCEPTION '% target(s) have context but no answer — handle separately', v_n; END IF;

  -- Blast radius: every target must be a Newton officeholder. A host-defined set could in principle
  -- reach someone else, and that would mean the host is cited outside this city.
  SELECT count(*) INTO v_n
    FROM _targets_1548 t
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.office_terms ot
       JOIN essentials.offices o ON o.id = ot.office_id
       JOIN essentials.chambers ch ON ch.id = o.chamber_id
       JOIN essentials.governments g ON g.id = ch.government_id
      WHERE ot.politician_id = t.politician_id
        AND g.name = 'City of Newton, Massachusetts, US');
  IF v_n <> 0 THEN RAISE EXCEPTION '% target(s) are not Newton officeholders — stop and re-scope', v_n; END IF;

  -- The rollback record must already exist as a committed artifact. Assert the shape it claims.
  SELECT count(*) INTO v_n FROM inform.politician_context c
   WHERE EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s ILIKE '%newtonobserver.com%')
     AND array_length(c.sources, 1) = 1;
  IF v_n <> 0 THEN RAISE EXCEPTION 'expected 0 sole-sourced rows (all 48 pair the host with a second citation), found %', v_n; END IF;
END $$;

-- ---- delete ----------------------------------------------------------------------------------------
DELETE FROM inform.politician_answers a
 USING _targets_1548 t
 WHERE a.politician_id = t.politician_id AND a.topic_id = t.topic_id;

DELETE FROM inform.politician_context c
 USING _targets_1548 t
 WHERE c.politician_id = t.politician_id AND c.topic_id = t.topic_id;

-- ---- verify ----------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_a int; v_c int; v_o int;
BEGIN
  -- The host is gone from the corpus entirely.
  SELECT count(*) INTO v_n FROM inform.politician_context c
   WHERE EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s ILIKE '%newtonobserver.com%');
  IF v_n <> 0 THEN RAISE EXCEPTION '% row(s) still cite newtonobserver.com', v_n; END IF;

  -- And so is the composed city path: this proves the 45 were a subset of the 48 rather than a
  -- separate population needing its own migration.
  SELECT count(*) INTO v_n FROM inform.politician_context c
   WHERE EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s ILIKE '%newtonma.gov/government/city-council/agendas-minutes%');
  IF v_n <> 0 THEN RAISE EXCEPTION '% row(s) still cite the composed agendas-minutes path — it has its own population', v_n; END IF;

  -- Exactly 48 removed from each table, measured against this transaction's own snapshot rather than a
  -- hard-coded total another session can invalidate.
  SELECT n_answers, n_context, n_context_orphans INTO v_a, v_c, v_o FROM _before_1548;
  SELECT count(*) INTO v_n FROM inform.politician_answers;
  IF v_n <> v_a - 48 THEN RAISE EXCEPTION 'politician_answers went % -> %, expected exactly -48', v_a, v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context;
  IF v_n <> v_c - 48 THEN RAISE EXCEPTION 'politician_context went % -> %, expected exactly -48', v_c, v_n; END IF;

  -- No orphans in either direction, corpus-wide.
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    LEFT JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE c.politician_id IS NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '% answer(s) left without context', v_n; END IF;
  -- Context-without-answer must be UNCHANGED, not zero: 546 such rows predate this migration.
  SELECT count(*) INTO v_n FROM inform.politician_context c
    LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
   WHERE a.politician_id IS NULL;
  IF v_n <> v_o THEN RAISE EXCEPTION 'context-without-answer moved % -> %; this migration must not create orphans', v_o, v_n; END IF;

  -- The 1494 rule: nobody emptied to zero may keep a last_stances_researched_at. Verified rather than
  -- assumed, and no UPDATE is issued because it is already NULL for all of them.
  SELECT count(*) INTO v_n
    FROM essentials.politicians p
   WHERE p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = p.id)
     AND EXISTS (SELECT 1 FROM essentials.office_terms ot
                   JOIN essentials.offices o ON o.id=ot.office_id
                   JOIN essentials.chambers ch ON ch.id=o.chamber_id
                   JOIN essentials.governments g ON g.id=ch.government_id
                  WHERE ot.politician_id=p.id AND g.name='City of Newton, Massachusetts, US');
  IF v_n <> 0 THEN RAISE EXCEPTION '% Newton politician(s) hold a research timestamp with zero answers', v_n; END IF;
END $$;

DROP TABLE _before_1548;

-- Report: what Newton has left, and who now reads as unresearched.
SELECT p.full_name, o.title,
       (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = p.id) AS answers_left
  FROM essentials.governments g
  JOIN essentials.chambers ch ON ch.government_id = g.id
  JOIN essentials.offices o ON o.chamber_id = ch.id
  JOIN essentials.office_terms ot ON ot.office_id = o.id
  JOIN essentials.politicians p ON p.id = ot.politician_id
 WHERE g.name = 'City of Newton, Massachusetts, US'
 ORDER BY answers_left DESC, p.full_name;

COMMIT;
