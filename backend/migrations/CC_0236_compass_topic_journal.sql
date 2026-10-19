-- CC_0236 — inform.compass_topic_journal: the per-topic designer diary.
--
-- Applies with `DATABASE_URL` (`ev_api`). DDL.
-- Design: docs/superpowers/specs/2026-10-13-compass-topic-journal-design.md
-- Plan:   docs/superpowers/plans/2026-10-13-compass-topic-journal-phase1.md
--
-- 🔴 THIS IS NOT A FORUM AND MUST NOT BECOME ONE. The Compass PUBLISHES these
-- entries; Focused Communities will HOST the conversation about them, in its own
-- tables, keyed to these ids. FC has moderation, tier gating and pseudonymity
-- rules that this table has none of. A parent_id or reply_to column here is what
-- losing that decision looks like, and compassJournalNoForum.test.ts fails if one
-- appears.
--
-- 🔴 NO RENDERED NAME IS STORED. The row holds author_id and a PREFERENCE. What a
-- reader sees is resolved at read time from the author's tier, because a Connected
-- author's default is privacy to the world and an Empowered author's is
-- transparency — and either can change after an entry is published.

BEGIN;

CREATE TYPE inform.journal_kind        AS ENUM ('watching', 'changed');
CREATE TYPE inform.journal_attribution AS ENUM ('none', 'handle', 'real');
CREATE TYPE inform.journal_status      AS ENUM ('draft', 'published');

CREATE TABLE inform.compass_topic_journal (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id      uuid NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  -- NOT NULL: between seasons this is the season being PREPARED. Season 3 exists
  -- as 'draft' today, so there is always a row to point at.
  season_id     uuid NOT NULL REFERENCES inform.seasons(id),
  kind          inform.journal_kind NOT NULL,

  title         text,
  body          text NOT NULL,

  -- NULL on every 'watching' entry by definition; set when the predicted edit ships.
  revision_id   uuid REFERENCES inform.compass_topic_revisions(id),
  -- The 'watching' entry this one settles. ONE hop only — a chain is a thread.
  answers_id    uuid REFERENCES inform.compass_topic_journal(id),

  author_id     uuid NOT NULL REFERENCES auth.users(id),
  attribution   inform.journal_attribution NOT NULL DEFAULT 'handle',

  status        inform.journal_status NOT NULL DEFAULT 'draft',
  published_at  timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT watching_has_no_revision
    CHECK (kind <> 'watching' OR revision_id IS NULL),
  -- Readers filter on status; this stops the two disagreeing.
  CONSTRAINT published_has_a_timestamp
    CHECK (status <> 'published' OR published_at IS NOT NULL),
  CONSTRAINT body_is_not_blank
    CHECK (btrim(body) <> ''),
  CONSTRAINT answers_is_not_self
    CHECK (answers_id IS NULL OR answers_id <> id)
);

COMMENT ON TABLE inform.compass_topic_journal IS
  'Per-topic public designer diary. NOT a forum: no replies, ever — Focused '
  'Communities hosts discussion in its own tables keyed to these ids.';

-- The only read the public API performs.
CREATE INDEX compass_topic_journal_topic_published_idx
  ON inform.compass_topic_journal (topic_id, published_at DESC)
  WHERE status = 'published';
CREATE INDEX compass_topic_journal_season_idx
  ON inform.compass_topic_journal (season_id);
CREATE INDEX compass_topic_journal_revision_idx
  ON inform.compass_topic_journal (revision_id)
  WHERE revision_id IS NOT NULL;

-- RLS on with NO policy: every read and write goes through the API, as with
-- compass_topic_revisions. This exists so a future accidental grant cannot
-- expose drafts.
ALTER TABLE inform.compass_topic_journal ENABLE ROW LEVEL SECURITY;

COMMIT;
