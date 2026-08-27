BEGIN;

-- ✅ APPLIED TO PRODUCTION. Landed on master 2026-08-27, AFTER the fact, to close
-- a record gap: all four views were live in prod while this file existed only on
-- the unmerged branch `wip/ca0013-repoint`. Prod carried four objects with no
-- source anywhere on master. Verified live 2026-08-27 from pg_views — all four
-- present, definitions matching this file, and read by ZERO callers in
-- backend/src, admin/src and app/src.
--
-- ⚠ `CA_0017`'s header says "CA_0013 and CA_0014 stay unused". That was true when
-- CA_0017 was written and is false now. Do not trust it.
--
-- 🔴 TWO OF THESE FOUR VIEWS ARE SUPERSEDED BY CA_0021. Read that file before
-- using either. This one is preserved AS APPLIED, not corrected in place — the
-- reasoning below was written before anyone here knew the season model had
-- already shipped in PR #177, and rewriting it would hide that.
--   · `compass_topics_promoted`   — redefined season-based. Its `is_live = true`
--     definition below has the right name and the WRONG AUTHORITY: is_live can
--     never notice a season dropping a topic.
--   · `compass_topics_answerable` — DROPPED. It filters nothing (it is a bare
--     column-narrowed alias for compass_topics_current), and the permissiveness
--     its name asserts is overruled by the shipped season gate. See ADR 0004 §12
--     as corrected, and ADR 0005.
-- `compass_topics_current` and `compass_stances_current` stand unchanged. They
-- are content views, they are season-independent, and they were right.
--
-- =============================================================================
-- CA_0013: split compass_topics_live into content / promotion / answerability
-- =============================================================================
-- Implements ADR 0004 §12. Requires CA_0011/CA_0012.
--
-- PURELY ADDITIVE. Replaces two views that nothing reads yet (verified) with
-- four correctly-scoped ones. No column is dropped, no data moves, no existing
-- read path changes until the code repoint that ships alongside this.
--
-- WHY FOUR VIEWS AND NOT ONE
-- CA_0012 created `compass_topics_live`, which answered two questions at once —
-- "what does this topic say" and "should we show it" — and implied a third by
-- exposing is_live. Classifying all 13 backend readers showed they ask three
-- genuinely different questions, and `is_live` gets away with conflating them
-- today only because all 44 topics happen to be live.
--
--   content       what does this topic SAY?        never season-dependent
--   promotion     should we ASK this person?       season-dependent (ADR 0005)
--   answerability may an answer EXIST for this?    deliberately permissive
--
-- 🔴 THE ONE THAT MATTERS. routes/compassContributor.ts refuses to seat a
-- politician's stance unless is_live = true. If that check ever becomes "unless
-- it is in the current season", a topic leaving a season becomes impossible to
-- record stances on — contradicting ADR 0004 §5 ("retiring never deletes
-- answers") and blocking historical comparison on topics already carrying
-- 32,887 seated answers. Promotion decides what we ASK. It must never decide
-- what may be RECORDED. Hence a separate `answerable` view whose whole job is to
-- stay permissive when `promoted` narrows.
--
-- 🔴 SCOPE CORRECTION vs the plan in ADR 0004 §12: is_live is NOT dropped, here
-- or by the follow-up. It is not a duplicated column — there is no equivalent in
-- compass_topic_revisions. It is promotion state, and the admin Topics page both
-- READS and WRITES it (a live archive/unarchive toggle). ADR 0005 says it becomes
-- redundant *under seasons*; seasons do not exist. Dropping it now would delete
-- the only promotion control with nothing to replace it. It stays until a season
-- resolver can take its place.
--
-- The genuinely duplicated columns — title, short_title, question_text, version,
-- went_live_at — are dropped by the FOLLOW-UP migration, after the code that
-- reads these views has deployed. A single migration cannot span a deploy, and
-- dropping them while running code still reads them would break production.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- Section 1: retire the two conflated views
-- ---------------------------------------------------------------------------
-- Verified unread on 2026-08-24: no occurrence of compass_topics_live or
-- compass_stances_live anywhere in backend/src or admin/src. They were created
-- by CA_0012 as a migration target and never wired up, so replacing them costs
-- nothing.
-- ---------------------------------------------------------------------------

DROP VIEW IF EXISTS inform.compass_topics_live;
DROP VIEW IF EXISTS inform.compass_stances_live;


-- ---------------------------------------------------------------------------
-- Section 2: CONTENT — what does this topic say?
-- ---------------------------------------------------------------------------
-- Every topic, resolved to its current revision. No promotion semantics, no
-- is_live, nothing jurisdiction-aware. ADR 0005's seasons will never touch this
-- view, which is the point: the majority of readers only want a title.
--
-- Deliberately includes topics that are NOT promoted. `adminService.adminListTopics`
-- documents itself as "includes non-live drafts", and the stats page wants every
-- topic. A content view that hid unpromoted topics would be answering the
-- promotion question again.
-- ---------------------------------------------------------------------------

CREATE VIEW inform.compass_topics_current AS
SELECT
  t.id,
  t.topic_key,
  r.title,
  r.short_title,
  r.question_text,
  r.version,
  r.revision,
  r.id            AS revision_id,
  r.change_class,
  r.public_note,
  r.published_at,
  t.fc_community_slug,
  t.judicial_role,
  t.created_at,
  t.updated_at
FROM inform.compass_topics t
JOIN inform.compass_topic_revisions r
  ON r.topic_id = t.id AND r.is_current;

COMMENT ON VIEW inform.compass_topics_current IS
  'ADR 0004 sec 12. CONTENT: every topic resolved to its current revision. Carries no promotion semantics and is never season-dependent. Use this when you want a title, a question, or a version number.';


-- ---------------------------------------------------------------------------
-- Section 3: PROMOTION — should we ask this person?
-- ---------------------------------------------------------------------------
-- Today: promotion is inform.compass_topics.is_live, which is the only promotion
-- mechanism that exists. All 44 topics are live, so this currently returns the
-- same rows as compass_topics_current — but they diverge the moment an admin
-- archives a topic, which is a supported action right now.
--
-- 🔴 ADR 0005 CHANGES THIS VIEW'S DEFINITION AND NOTHING ELSE. When seasons
-- land, promotion becomes f(season, jurisdiction) and this becomes a function
-- taking a geoid. Callers pointed here are pointed correctly today and will not
-- be repointed twice. That is the entire reason for splitting the views before
-- building seasons.
-- ---------------------------------------------------------------------------

CREATE VIEW inform.compass_topics_promoted AS
SELECT c.*, t.is_live
FROM inform.compass_topics_current c
JOIN inform.compass_topics t ON t.id = c.id
WHERE t.is_live = true;

COMMENT ON VIEW inform.compass_topics_promoted IS
  'ADR 0004 sec 12 / ADR 0005. PROMOTION: which topics to ASK. Today = is_live. Seasons will replace this definition with a jurisdiction-aware resolver; callers stay put. Never use this to decide whether an answer may be recorded.';


-- ---------------------------------------------------------------------------
-- Section 4: ANSWERABILITY — may an answer exist for this?
-- ---------------------------------------------------------------------------
-- Deliberately permissive: any topic with a current revision. Identical to
-- compass_topics_current today, and that is fine — it exists as a separate NAME
-- so the intent is explicit at every call site and so a future change to
-- promotion cannot silently narrow it.
--
-- Read Section 1's note before ever adding a filter here. A politician's stance
-- on a topic that has left a season is still a fact worth recording, and 32,887
-- seated answers already sit on topics a future season may drop.
-- ---------------------------------------------------------------------------

CREATE VIEW inform.compass_topics_answerable AS
SELECT c.id, c.topic_key, c.version, c.revision, c.revision_id, c.title
FROM inform.compass_topics_current c;

COMMENT ON VIEW inform.compass_topics_answerable IS
  'ADR 0004 sec 12. ANSWERABILITY: which topics may hold an answer. Permissive by design — identical to compass_topics_current, named separately so promotion can never silently narrow it. Do not add a season filter here.';


-- ---------------------------------------------------------------------------
-- Section 5: the ladder, content only
-- ---------------------------------------------------------------------------
-- A ladder has no promotion question of its own; it inherits its topic's. So
-- there is one stance view, not three.
-- ---------------------------------------------------------------------------

CREATE VIEW inform.compass_stances_current AS
SELECT
  sr.id,
  r.topic_id,
  sr.value,
  sr.text,
  sr.description,
  sr.supporting_points,
  sr.example_perspectives,
  sr.topic_revision_id
FROM inform.compass_stance_revisions sr
JOIN inform.compass_topic_revisions r
  ON r.id = sr.topic_revision_id AND r.is_current;

COMMENT ON VIEW inform.compass_stances_current IS
  'ADR 0004 sec 12. The five rungs of each topic''s current revision, keyed by topic_id for drop-in use where inform.compass_stances was read.';


-- ---------------------------------------------------------------------------
-- Section 6: Grants
-- ---------------------------------------------------------------------------
-- Matches the base tables: anon and authenticated may read. ev_api carries
-- rolbypassrls so pool.query sees everything regardless; access is gated at the
-- route, not by RLS (ADR 0004 sec 11c).
-- ---------------------------------------------------------------------------

GRANT SELECT ON inform.compass_topics_current    TO anon, authenticated;
GRANT SELECT ON inform.compass_topics_promoted   TO anon, authenticated;
GRANT SELECT ON inform.compass_topics_answerable TO anon, authenticated;
GRANT SELECT ON inform.compass_stances_current   TO anon, authenticated;


-- ---------------------------------------------------------------------------
-- Section 7: Post-verify gate
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  v_topics     INT;
  v_current    INT;
  v_promoted   INT;
  v_answerable INT;
  v_stances    INT;
  v_rungs      INT;
  v_drift      INT;
  v_missing    TEXT[] := '{}';
  v_v          TEXT;
BEGIN
  FOREACH v_v IN ARRAY ARRAY[
    'compass_topics_current', 'compass_topics_promoted',
    'compass_topics_answerable', 'compass_stances_current'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.views
      WHERE table_schema = 'inform' AND table_name = v_v
    ) THEN
      v_missing := v_missing || v_v;
    END IF;
  END LOOP;

  IF array_length(v_missing, 1) > 0 THEN
    RAISE EXCEPTION 'CA_0013 INCOMPLETE: missing view(s) %', array_to_string(v_missing, ', ');
  END IF;

  -- The two conflated views must be gone, or a later reader could pick the wrong one.
  IF EXISTS (SELECT 1 FROM information_schema.views
             WHERE table_schema='inform' AND table_name IN ('compass_topics_live','compass_stances_live')) THEN
    RAISE EXCEPTION 'CA_0013: the old conflated views still exist';
  END IF;

  SELECT count(*) INTO v_topics     FROM inform.compass_topics;
  SELECT count(*) INTO v_current    FROM inform.compass_topics_current;
  SELECT count(*) INTO v_promoted   FROM inform.compass_topics_promoted;
  SELECT count(*) INTO v_answerable FROM inform.compass_topics_answerable;
  SELECT count(*) INTO v_stances    FROM inform.compass_stances;
  SELECT count(*) INTO v_rungs      FROM inform.compass_stances_current;

  -- Every topic must resolve to exactly one current revision. A count below the
  -- topic count means a topic has no current revision; above means two do, which
  -- the partial unique index should make impossible.
  IF v_current <> v_topics THEN
    RAISE EXCEPTION 'CA_0013: % topics but compass_topics_current returns %', v_topics, v_current;
  END IF;
  IF v_answerable <> v_topics THEN
    RAISE EXCEPTION 'CA_0013: answerable returns % for % topics — it must stay permissive',
      v_answerable, v_topics;
  END IF;
  IF v_rungs <> v_stances THEN
    RAISE EXCEPTION 'CA_0013: % rungs in compass_stances but % in compass_stances_current',
      v_stances, v_rungs;
  END IF;

  -- Promotion must equal the is_live count exactly — no more, no less.
  IF v_promoted <> (SELECT count(*) FROM inform.compass_topics WHERE is_live) THEN
    RAISE EXCEPTION 'CA_0013: promoted returns % but % topics are is_live',
      v_promoted, (SELECT count(*) FROM inform.compass_topics WHERE is_live);
  END IF;

  -- 🔴 The assertion that actually matters: the views must agree with the legacy
  -- columns they are about to replace. If they disagree, the follow-up drop would
  -- silently change published content.
  SELECT count(*) INTO v_drift
  FROM inform.compass_topics t
  JOIN inform.compass_topics_current c ON c.id = t.id
  WHERE t.title         IS DISTINCT FROM c.title
     OR t.short_title   IS DISTINCT FROM c.short_title
     OR t.question_text IS DISTINCT FROM c.question_text;
  IF v_drift > 0 THEN
    RAISE EXCEPTION 'CA_0013: % topics where the view disagrees with the legacy columns — DO NOT DROP THEM', v_drift;
  END IF;

  SELECT count(*) INTO v_drift
  FROM inform.compass_stances s
  LEFT JOIN inform.compass_stances_current cs
         ON cs.topic_id = s.topic_id AND cs.value = s.value
  WHERE cs.id IS NULL
     OR s.text        IS DISTINCT FROM cs.text
     OR s.description IS DISTINCT FROM cs.description;
  IF v_drift > 0 THEN
    RAISE EXCEPTION 'CA_0013: % rungs where the view disagrees with inform.compass_stances', v_drift;
  END IF;

  RAISE NOTICE 'CA_0013 OK — 4 views; content % / promoted % / answerable % of % topics; % rungs; zero drift vs legacy columns',
    v_current, v_promoted, v_answerable, v_topics, v_rungs;
END $$;

COMMIT;
