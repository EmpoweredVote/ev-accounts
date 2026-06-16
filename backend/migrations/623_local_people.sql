-- Migration 623: Non-roster participants for debates, forums, and school boards.
--
-- Implements D-05 and D-06 from Phase 7 (Beyond Council Meetings).
--
-- D-05: meetings.local_people — site-local person records for speakers who are not
-- in the essentials.politicians roster. Candidates, moderators, and panelists at
-- debate/forum/school-board events are entered here during pipeline review.
-- politician_slug is nullable so a local_people record can later be linked to an
-- essentials politician without losing the local identity.
--
-- D-06: meetings.speakers.local_slug — nullable FK to meetings.local_people(slug).
-- Invariant: either politician_slug OR local_slug is set on a speaker row, never
-- both. A speaker with neither value is unidentified (existing behavior preserved).
-- ON DELETE SET NULL ensures that deleting a local_people row leaves dependent
-- speaker rows intact and unidentified rather than raising a FK violation.

BEGIN;

-- 1. Create meetings.local_people table
CREATE TABLE IF NOT EXISTS meetings.local_people (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            TEXT        NOT NULL UNIQUE,
  name            TEXT        NOT NULL,
  role            TEXT        NOT NULL,       -- 'candidate' | 'moderator' | 'panelist'
  politician_slug TEXT,                       -- nullable; links to essentials.politicians.slug
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. CHECK constraint: restrict role to the three permitted values.
-- Wrapped in a DO block so re-running the migration is a no-op.
DO $$ BEGIN
  ALTER TABLE meetings.local_people
    ADD CONSTRAINT local_people_role_check
    CHECK (role IN ('candidate', 'moderator', 'panelist'));
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

-- 3. Index on politician_slug for linking local records to essentials politicians
CREATE INDEX IF NOT EXISTS local_people_politician_slug_idx
  ON meetings.local_people(politician_slug)
  WHERE politician_slug IS NOT NULL;

-- 4. Add local_slug column to meetings.speakers with ON DELETE SET NULL FK
ALTER TABLE meetings.speakers
  ADD COLUMN IF NOT EXISTS local_slug TEXT
    REFERENCES meetings.local_people(slug) ON DELETE SET NULL;

-- 5. Index on local_slug for efficient meeting-page speaker lookups
CREATE INDEX IF NOT EXISTS speakers_local_slug_idx
  ON meetings.speakers(local_slug)
  WHERE local_slug IS NOT NULL;

-- 6. Enable Row Level Security on meetings.local_people
ALTER TABLE meetings.local_people ENABLE ROW LEVEL SECURITY;

-- 7. RLS policy: public read only; writes are service-role only (no write policy created)
-- Wrapped in a DO block so re-running the migration is a no-op.
DO $$ BEGIN
  CREATE POLICY "local_people: public read"
    ON meetings.local_people FOR SELECT TO anon, authenticated USING (true);
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

-- 8. Explicit GRANT: ensure anon and authenticated roles can SELECT
-- (ALTER DEFAULT PRIVILEGES covers future tables; new tables still need explicit grants)
GRANT SELECT ON meetings.local_people TO anon, authenticated;

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('623') ON CONFLICT DO NOTHING;

COMMIT;
