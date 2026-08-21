-- CA_0002_delete_orphaned_congress_local_people.sql
--
-- Deletes the 25 orphaned meetings.local_people rows that duplicated sitting members of the
-- U.S. House. Second migration in the CA_ namespace (see CLAUDE.md).
--
-- WHY THEY EXISTED
--
-- on-the-record's federal floor path stashed the bioguide in SpeakerMapping.local_slug for every
-- CREC-resolved member (src/crec_identify.py), then added an essentials politician_id on top when
-- the bridge matched, and never cleared the stash. src/publish.py minted a local_people row for any
-- local_slug, so each resolved member published twice: once as the essentials politician they are,
-- and once as a site-local person they are not. All 25 had local_people.politician_slug NULL, so
-- they were pure duplicates rather than links, and all 25 came from one meeting,
-- 2026-07-16-house-floor.
--
-- WHY IT IS SAFE TO DELETE THEM NOW, AND WAS NOT BEFORE
--
-- on-the-record PR #160 enforces migration 623's invariant at the publish boundary: a speaker with
-- politician_id or politician_slug publishes no local person and writes speakers.local_slug NULL.
-- That meeting was then republished, so prod now has 0 speakers carrying both identities and all 25
-- rows are unreferenced. Deleting them BEFORE that fix would have been futile — the next republish
-- re-minted them.
--
-- NOT A USER-VISIBLE FIX. web/.../MeetingView.tsx already guarded with
-- `.filter((sp) => sp.local_slug && !sp.politician_id)`, so those speakers always rendered as
-- properly linked politician profiles. What was actually wrong is the API: meetingsService LEFT
-- JOINs local_people unguarded, so GET /api/meetings/<id> emitted both politicianId and localName
-- for those speakers and only the web client filtered it out.
--
-- SCOPE IS DELIBERATELY NARROW. Only congress-* rows, only where politician_slug IS NULL (never a
-- linked record), and only where no speaker row references the slug. kathleen-donham — the one
-- genuinely reviewed local person, role 'moderator' — is asserted to survive. Idempotent: a second
-- run deletes 0 and the assertions still hold.
--
-- ✅ APPLIED TO PROD 2026-08-21. Dry-run first with COMMIT swapped for ROLLBACK: deleted 25,
-- all assertions passed, and the rollback was confirmed reverted (26 rows before and after) before
-- the real run. After applying, meetings.local_people holds exactly one row — kathleen-donham,
-- 'moderator' — with 0 speakers carrying a dual identity and 0 speakers pointing at a missing
-- local person.

BEGIN;

DO $$
DECLARE
  v_other_before int;
  v_other_after  int;
  v_deleted      int;
  v_orphans_left int;
BEGIN
  SELECT count(*) INTO v_other_before
    FROM meetings.local_people WHERE slug NOT LIKE 'congress-%';

  DELETE FROM meetings.local_people lp
   WHERE lp.slug LIKE 'congress-%'
     AND lp.politician_slug IS NULL
     AND NOT EXISTS (
           SELECT 1 FROM meetings.speakers sp WHERE sp.local_slug = lp.slug
         );
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RAISE NOTICE 'deleted % orphaned congress-* local_people row(s)', v_deleted;

  -- no orphaned duplicate may remain
  SELECT count(*) INTO v_orphans_left
    FROM meetings.local_people lp
   WHERE lp.slug LIKE 'congress-%'
     AND NOT EXISTS (
           SELECT 1 FROM meetings.speakers sp WHERE sp.local_slug = lp.slug
         );
  IF v_orphans_left <> 0 THEN
    RAISE EXCEPTION '% orphaned congress-* local_people row(s) remain', v_orphans_left;
  END IF;

  -- nothing outside the congress-* prefix may be touched
  SELECT count(*) INTO v_other_after
    FROM meetings.local_people WHERE slug NOT LIKE 'congress-%';
  IF v_other_after <> v_other_before THEN
    RAISE EXCEPTION 'non-congress local_people count changed: % -> %', v_other_before, v_other_after;
  END IF;

  -- the one genuinely reviewed local person must survive
  IF NOT EXISTS (SELECT 1 FROM meetings.local_people WHERE slug = 'kathleen-donham') THEN
    RAISE EXCEPTION 'kathleen-donham (reviewed moderator) was deleted — aborting';
  END IF;
END $$;

COMMIT;
