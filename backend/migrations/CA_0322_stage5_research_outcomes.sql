-- backend/migrations/CA_0322_stage5_research_outcomes.sql
BEGIN;

-- ⚠ NOT APPLIED until Chris Andrews says so. A BEGIN…ROLLBACK dry run needs his yes, and the real apply needs a
-- second yes, both after the Stage 5 early check passes (plan Task 9, Global Constraints).
-- =============================================================================
-- CA_0322: Stage 5 research outcomes and shown own-words passages
-- =============================================================================
-- Spec: docs/superpowers/specs/2026-10-22-season-topic-prep-stage5-code-everyone-design.md §8–§10.
-- Plan: docs/superpowers/plans/2026-10-22-season-topic-prep-stage5.md Task 9.
--
--   topic_research_outcomes  the "we researched" marker: one row per person, per topic, per season that Stage 5
--                            coded, with the outcome (seated / doesnt-fit / no-stance) and the research date.
--                            It is SEPARATE from politician_answers.value = 0, which also covers older blanks (a
--                            ladder moved under a seat) and people never researched. Voters are told "we
--                            researched" only when this row exists (spec §8).
--   own_words_passages       the passages shown as "own words, not a position on the scale" (spec §8 case 2):
--                            the person's exact words, or a local record described in plain words. A passage
--                            can be stored only with a passed AI quote check (CHECK quote_check = 'passed'):
--                            an unchecked or failed quote cannot reach the table, so it cannot reach a voter.
--
-- Both are keyed per person, per topic, per season, carry the closed-season trigger like the answer tables
-- (CC_0044), and are written only by `topic:stage5-write --season draft`. Draft rows stay hidden from voters
-- until the season opens: every reader gates on SEASON_IS_PUBLISHED.
--
-- 🔴 Duplicate-person merge migrations must re-point politician_id on both tables, as on politician_answers.
-- Purely additive. RLS default-deny (CTO decision 0015): the API reads through the pool.
-- =============================================================================

-- @zero-scope: counts-blanks — this table is the marker that a blank (value = 0, or no answer row) was
-- researched. Readers that show `doesnt-fit` / `no-stance` to voters must keep that filter OUTSIDE the
-- newest-season collapse, so a newer seat hides an older blank and never the other way round.
CREATE TABLE IF NOT EXISTS inform.topic_research_outcomes (
  politician_id  uuid NOT NULL REFERENCES essentials.politicians(id),
  topic_id       uuid NOT NULL REFERENCES inform.compass_topics(id),
  season_id      uuid NOT NULL REFERENCES inform.seasons(id),
  outcome        text NOT NULL CHECK (outcome IN ('seated', 'doesnt-fit', 'no-stance')),
  researched_on  date NOT NULL,
  -- What checked this row ('stage5-coder', 'stage5-quote-checker', later a Validation Quest id), spec §9.
  checked_by     text[] NOT NULL DEFAULT '{}',
  created_at     timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (politician_id, topic_id, season_id)
);

CREATE TABLE IF NOT EXISTS inform.own_words_passages (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  politician_id          uuid NOT NULL REFERENCES essentials.politicians(id),
  topic_id               uuid NOT NULL REFERENCES inform.compass_topics(id),
  season_id              uuid NOT NULL REFERENCES inform.seasons(id),
  -- The source store's finding id (sha256 over kind|url|passage|…, sourceStore.findingId).
  finding_id             text NOT NULL CHECK (finding_id ~ '^[0-9a-f]{64}$'),
  kind                   text NOT NULL CHECK (kind IN ('own-words', 'local-record')),
  -- own-words: the exact words, never edited. local-record: the plain-words description of the act.
  passage                text NOT NULL CHECK (btrim(passage) <> ''),
  source_url             text NOT NULL CHECK (source_url ~ '^https?://'),
  source_date            date,
  source_date_precision  text CHECK (source_date_precision IN ('day', 'month', 'year', 'unknown')),
  quote_check            text NOT NULL CHECK (quote_check = 'passed'),
  quote_checked_at       timestamptz NOT NULL,
  quote_checker          text NOT NULL,
  created_at             timestamptz NOT NULL DEFAULT now(),
  UNIQUE (politician_id, topic_id, season_id, finding_id),
  -- A passage is shown under a research outcome; it never stands without one.
  FOREIGN KEY (politician_id, topic_id, season_id)
    REFERENCES inform.topic_research_outcomes (politician_id, topic_id, season_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS own_words_passages_outcome_idx
  ON inform.own_words_passages (politician_id, topic_id, season_id);

-- Closed seasons are the historical record (CC_0044).
DROP TRIGGER IF EXISTS topic_research_outcomes_closed_season_immutable ON inform.topic_research_outcomes;
CREATE TRIGGER topic_research_outcomes_closed_season_immutable
  BEFORE INSERT OR UPDATE OR DELETE ON inform.topic_research_outcomes
  FOR EACH ROW EXECUTE FUNCTION inform.closed_season_is_immutable();

DROP TRIGGER IF EXISTS own_words_passages_closed_season_immutable ON inform.own_words_passages;
CREATE TRIGGER own_words_passages_closed_season_immutable
  BEFORE INSERT OR UPDATE OR DELETE ON inform.own_words_passages
  FOR EACH ROW EXECUTE FUNCTION inform.closed_season_is_immutable();

-- RLS default-deny.
ALTER TABLE inform.topic_research_outcomes ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.own_words_passages      ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON inform.topic_research_outcomes, inform.own_words_passages FROM anon, authenticated;

COMMENT ON TABLE inform.topic_research_outcomes IS
  'Stage 5 "we researched" marker (spec 2026-10-22 §8): one row per person, topic and season Stage 5 coded. '
  'Separate from politician_answers.value = 0. @zero-scope: counts-blanks. Duplicate-person merges must '
  're-point politician_id here.';
COMMENT ON TABLE inform.own_words_passages IS
  'Passages shown as own words, not a position on the scale (spec §8 case 2). Only a passed AI quote check '
  'may be stored (CHECK). Quotes are never edited. Duplicate-person merges must re-point politician_id here.';

-- -----------------------------------------------------------------------------
-- Verification.
-- -----------------------------------------------------------------------------
DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM pg_tables WHERE schemaname = 'inform' AND rowsecurity
     AND tablename IN ('topic_research_outcomes', 'own_words_passages');
  IF v <> 2 THEN RAISE EXCEPTION 'CA_0322: expected 2 new RLS-enabled tables, found %', v; END IF;

  SELECT count(*) INTO v FROM pg_trigger
   WHERE NOT tgisinternal
     AND tgname IN ('topic_research_outcomes_closed_season_immutable', 'own_words_passages_closed_season_immutable')
     AND tgrelid IN ('inform.topic_research_outcomes'::regclass, 'inform.own_words_passages'::regclass);
  IF v <> 2 THEN RAISE EXCEPTION 'CA_0322: expected 2 closed-season triggers, found %', v; END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'inform.own_words_passages'::regclass
                  AND contype = 'c' AND pg_get_constraintdef(oid) LIKE '%quote_check = ''passed''%') THEN
    RAISE EXCEPTION 'CA_0322: inform.own_words_passages is missing CHECK (quote_check = ''passed'')';
  END IF;

  IF has_table_privilege('anon', 'inform.topic_research_outcomes', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0322: REVOKE did not take — anon can SELECT inform.topic_research_outcomes';
  END IF;
  IF has_table_privilege('anon', 'inform.own_words_passages', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0322: REVOKE did not take — anon can SELECT inform.own_words_passages';
  END IF;
END $$;

COMMIT;
