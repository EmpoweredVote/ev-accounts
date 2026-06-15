-- Migration 579: Link events to chambers or races and remove body_slug.
--
-- This migration intentionally aborts unless every non-null legacy body_slug
-- resolves to exactly one essentials.chambers row.

BEGIN;

DO $$
DECLARE
  v_problem RECORD;
BEGIN
  SELECT
    m.body_slug,
    COUNT(DISTINCT c.id) AS match_count,
    COUNT(*) AS meeting_count
  INTO v_problem
  FROM meetings.meetings m
  LEFT JOIN essentials.chambers c ON c.slug = m.body_slug
  WHERE m.body_slug IS NOT NULL
  GROUP BY m.body_slug
  HAVING COUNT(DISTINCT c.id) <> 1
  ORDER BY m.body_slug
  LIMIT 1;

  IF FOUND THEN
    RAISE EXCEPTION
      'Cannot migrate body_slug=%: expected exactly one chamber match, found % across % meeting(s)',
      v_problem.body_slug,
      v_problem.match_count,
      v_problem.meeting_count;
  END IF;
END $$;

ALTER TABLE meetings.meetings
  ADD COLUMN IF NOT EXISTS chamber_id UUID
    REFERENCES essentials.chambers(id),
  ADD COLUMN IF NOT EXISTS race_id UUID
    REFERENCES essentials.races(id);

UPDATE meetings.meetings m
SET chamber_id = c.id
FROM essentials.chambers c
WHERE m.body_slug IS NOT NULL
  AND c.slug = m.body_slug
  AND m.chamber_id IS DISTINCT FROM c.id;

DO $$
DECLARE
  v_remaining BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_remaining
  FROM meetings.meetings
  WHERE body_slug IS NOT NULL
    AND chamber_id IS NULL;

  IF v_remaining <> 0 THEN
    RAISE EXCEPTION
      'Refusing to drop body_slug: % non-null slug row(s) remain unlinked',
      v_remaining;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS meetings_meetings_chamber_id_idx
  ON meetings.meetings(chamber_id);

CREATE INDEX IF NOT EXISTS meetings_meetings_race_id_idx
  ON meetings.meetings(race_id);

ALTER TABLE meetings.meetings
  DROP COLUMN body_slug;

COMMIT;
