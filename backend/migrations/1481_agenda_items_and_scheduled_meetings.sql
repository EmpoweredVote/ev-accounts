-- 1481: agenda_items table + scheduled-meeting support + votes->items FK
--
-- Part of the Bloomington item-centric civic coverage feature (spec:
-- on-the-record/docs/superpowers/specs/2026-07-27-bloomington-item-centric-civic-coverage-design.md).
-- The agenda ITEM is the product atom: published days before a meeting
-- (status='upcoming', plain-language interpretation) and enriched after video
-- processing (status='happened', outcome + segment bounds + votes).
--
-- Design notes:
-- * meetings.meetings.status gains a new VALUE ('scheduled') — no DDL needed
--   (status is unconstrained text, default 'processing'). The API-side guard is
--   getMeetings() defaulting to status='published' (this migration's companion
--   code change), because every pre-existing read path assumes all rows are
--   published.
-- * starts_at: meetings.date was deliberately downgraded to DATE (migration 364);
--   scheduled meetings need time-of-day. timestamptz; the writer (on-the-record
--   pipeline) resolves the body's IANA zone. date stays NOT NULL — writers derive
--   it from starts_at in the body's local zone.
-- * timezone: timestamptz normalizes to UTC at storage, so the original offset is
--   lost — the body's IANA zone must ride along for the UI to render starts_at in
--   meeting-local time.
-- * kind/status/outcome are CHECK-constrained (closed vocabularies from the spec).
-- * continued_from_item_id is the matter-tracking seed (spec: one lifecycle edge,
--   no matter entity). ON DELETE SET NULL: losing a lineage edge must not block
--   deleting an old item row.
-- * votes.agenda_item_id mirrors the existing la_council_votes.agenda_item_id
--   precedent (migration 167): nullable because procedural votes have no item.
--   ON DELETE SET NULL because the pipeline delete-then-inserts agenda_items per
--   meeting — with the default NO ACTION, deleting items would violate the FK
--   once votes reference them (same rationale as continued_from_item_id).
-- * RLS: enabled + public-read policy, matching phase-34 meetings pattern
--   (supabase/migrations/20260319000045). The API's ev_api role is BYPASSRLS
--   either way; the policy keeps direct-Supabase reads consistent with the
--   original meetings tables.
-- * Sole row writer is the on-the-record pipeline (delete-then-insert per
--   meeting, like meetings.votes). ev-accounts only reads.

BEGIN;

-- 1) scheduled-meeting support
ALTER TABLE meetings.meetings ADD COLUMN IF NOT EXISTS starts_at timestamptz;
COMMENT ON COLUMN meetings.meetings.starts_at IS
  'Scheduled start time (with zone). Set for status=scheduled rows published from agendas; null for legacy video-only rows.';

ALTER TABLE meetings.meetings ADD COLUMN IF NOT EXISTS timezone text;
COMMENT ON COLUMN meetings.meetings.timezone IS
  'IANA zone of the meeting''s body (e.g. America/Indiana/Indianapolis). Needed because timestamptz normalizes to UTC; the UI renders starts_at in this zone.';

CREATE INDEX IF NOT EXISTS idx_meetings_status_date
  ON meetings.meetings (status, date);

-- 2) agenda_items
CREATE TABLE IF NOT EXISTS meetings.agenda_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id uuid NOT NULL REFERENCES meetings.meetings(id) ON DELETE CASCADE,
  position integer NOT NULL,
  item_number text NOT NULL,
  title_raw text NOT NULL,
  kind text NOT NULL CHECK (kind IN
    ('ordinance','resolution','appointment','proclamation','report',
     'public-comment','minutes','procedural','other')),
  legislation_ref text,
  summary_plain text,
  decision_plain text,
  stage text,
  public_comment boolean NOT NULL DEFAULT false,
  public_comment_note text,
  status text NOT NULL DEFAULT 'upcoming' CHECK (status IN ('upcoming','happened')),
  outcome text CHECK (outcome IN ('passed','failed','continued','pulled','no-action')),
  segment_start_seconds numeric,
  segment_end_seconds numeric,
  continued_from_item_id uuid REFERENCES meetings.agenda_items(id) ON DELETE SET NULL,
  source_url text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT agenda_items_meeting_position_unique UNIQUE (meeting_id, position)
);

COMMENT ON TABLE meetings.agenda_items IS
  'One row per agenda item; the citizen-facing atom. Written only by the on-the-record pipeline (delete-then-insert per meeting).';
COMMENT ON COLUMN meetings.agenda_items.title_raw IS
  'Verbatim agenda title (government-speak), preserved for provenance.';
COMMENT ON COLUMN meetings.agenda_items.legislation_ref IS
  'e.g. "Ordinance 2026-16" — extracted from the agenda, never invented; joins to the city legislation pages.';
COMMENT ON COLUMN meetings.agenda_items.stage IS
  'Procedural stage from adapter-encoded body rules (e.g. "First reading"), never LLM-inferred.';
COMMENT ON COLUMN meetings.agenda_items.continued_from_item_id IS
  'Matter-tracking seed: points at the same matter''s item row on an earlier agenda.';
COMMENT ON COLUMN meetings.agenda_items.segment_start_seconds IS
  'Video-absolute seconds; null until the post-meeting alignment pass.';

CREATE INDEX IF NOT EXISTS idx_agenda_items_meeting_id
  ON meetings.agenda_items (meeting_id);

-- 3) votes -> items
ALTER TABLE meetings.votes
  ADD COLUMN IF NOT EXISTS agenda_item_id uuid REFERENCES meetings.agenda_items(id) ON DELETE SET NULL;
COMMENT ON COLUMN meetings.votes.agenda_item_id IS
  'Item the vote decided; null for procedural votes or pre-agenda-items rows.';
CREATE INDEX IF NOT EXISTS idx_meetings_votes_agenda_item_id
  ON meetings.votes (agenda_item_id) WHERE agenda_item_id IS NOT NULL;

-- 4) RLS (phase-34 pattern: on + public read)
ALTER TABLE meetings.agenda_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "agenda_items_public_read" ON meetings.agenda_items;
CREATE POLICY "agenda_items_public_read" ON meetings.agenda_items
  FOR SELECT TO anon, authenticated USING (true);
GRANT SELECT ON meetings.agenda_items TO anon, authenticated;

-- 5) post-verify gate
DO $$
DECLARE
  n_cols int;
  n_fk int;
BEGIN
  SELECT count(*) INTO n_cols FROM information_schema.columns
   WHERE table_schema = 'meetings' AND table_name = 'agenda_items';
  IF n_cols <> 20 THEN
    RAISE EXCEPTION 'agenda_items has % columns, expected 20', n_cols;
  END IF;

  SELECT count(*) INTO n_fk FROM pg_constraint
   WHERE conrelid = 'meetings.votes'::regclass
     AND contype = 'f'
     AND confrelid = 'meetings.agenda_items'::regclass;
  IF n_fk <> 1 THEN
    RAISE EXCEPTION 'votes.agenda_item_id FK missing';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'meetings' AND table_name = 'meetings'
      AND column_name = 'starts_at') THEN
    RAISE EXCEPTION 'meetings.starts_at missing';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'meetings' AND table_name = 'meetings'
      AND column_name = 'timezone') THEN
    RAISE EXCEPTION 'meetings.timezone missing';
  END IF;
END $$;

COMMIT;
