-- CA_0003_local_people_role_shape.sql
--
-- Replaces local_people_role_check with a SHAPE constraint, so the DB stops dictating the role
-- vocabulary.
--
-- WHY. Migration 623 constrained role to ('candidate','moderator','panelist'). on-the-record's
-- src/event_kinds.py offers council / school_board / community_meeting reviewers
-- 'public_comment', 'staff', 'official', 'presenter' — a disjoint set — and resolve_local_role()
-- can emit normalised free text besides. 38 of the 40 role values in the local corpus are
-- unpublishable, and because publish runs in one transaction, republishing 2026-02-04-council
-- (19 local people) aborts entirely. The value CHECK was never the real authority; it only ever
-- blocked what the application actually produced.
--
-- A shape CHECK still keeps garbage out — empty strings, spaces, mixed case, long pastes — without
-- deciding the vocabulary. Whether a role is ever shown to a reader is an open question, and this
-- migration deliberately does not answer it. If roles later become a display contract, a closed
-- enum becomes the better choice and this should be revisited.
--
-- The pattern is the SQL twin of LOCAL_ROLE_PATTERN in on-the-record src/event_kinds.py. A regex
-- cannot be shared between Python and SQL; they are kept in sync BY HAND. The Python side is
-- guaranteed to satisfy this shape: resolve_local_role() strips leading non-letters, truncates to
-- 40 characters, and falls back to the event kind's default when nothing survives, so the app
-- cannot emit a role this constraint would refuse.
--
-- role stays NULLable (CA_0001): NULL means no role was recorded, which is not a claim about the
-- person. A CHECK is satisfied when it evaluates to NULL, so the guard below admits NULL as-is —
-- the explicit `role IS NULL OR` is written for the reader, not the planner.
--
-- ✅ APPLIED TO PROD 2026-08-21. Dry-run first with COMMIT swapped for ROLLBACK: the gate passed
-- inside the transaction and the rollback was confirmed to have reverted (constraint list still
-- showed local_people_role_check) before the real run. After applying, probes confirmed the
-- intent from both sides: 'public_comment' — the value that had blocked every civic publish — is
-- now accepted, and 'Public Comment' (spaces, mixed case) is still rejected. Both probes were
-- rolled back; no probe row persisted.
--
-- 2026-02-04-council was then republished, landing its 19 local people: public_comment 13,
-- staff 6. Zero stored roles fail the new shape, zero speakers carry a dual identity, and the
-- meeting's summary sections still align (max end_segment 659 = max published segment_index 659).

BEGIN;

ALTER TABLE meetings.local_people
  DROP CONSTRAINT IF EXISTS local_people_role_check;

DO $$ BEGIN
  ALTER TABLE meetings.local_people
    ADD CONSTRAINT local_people_role_shape
    CHECK (role IS NULL OR role ~ '^[a-z][a-z0-9_]{0,39}$');
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

-- post-verify gate
DO $$
DECLARE
  v_old int;
  v_new int;
  v_bad int;
BEGIN
  SELECT count(*) INTO v_old FROM pg_constraint
   WHERE conrelid = 'meetings.local_people'::regclass AND conname = 'local_people_role_check';
  IF v_old <> 0 THEN
    RAISE EXCEPTION 'local_people_role_check still present';
  END IF;

  SELECT count(*) INTO v_new FROM pg_constraint
   WHERE conrelid = 'meetings.local_people'::regclass AND conname = 'local_people_role_shape';
  IF v_new <> 1 THEN
    RAISE EXCEPTION 'local_people_role_shape missing (found %)', v_new;
  END IF;

  SELECT count(*) INTO v_bad FROM meetings.local_people
   WHERE role IS NOT NULL AND role !~ '^[a-z][a-z0-9_]{0,39}$';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION '% stored role(s) fail the new shape', v_bad;
  END IF;
END $$;

COMMIT;
