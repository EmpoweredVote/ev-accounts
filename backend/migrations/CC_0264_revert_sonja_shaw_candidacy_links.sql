-- CC_0264_revert_sonja_shaw_candidacy_links.sql
--
-- Reverts TWO of the eleven links CC_0263 made, both for Sonja Shaw:
--
--   4939c2c8-9bc4-4524-bdaf-daadff60f38c  CA Superintendent of Public Instruction, 2026 LA County Primary
--   3e2a7783-ebf5-4d35-b9cb-f396c30dceab  Superintendent of Public Instruction,    CA 2026 Statewide General
--     -> politician_id back to NULL (was 5f76110b-eb6c-59b4-8c6a-c97e8722cc05)
--
-- Operator ruling 2026-10-19: the evidence was too thin. CC_0263 said so itself and named
-- this as the row to revert if it was judged that way, so this is the migration that file
-- anticipated rather than a correction of a mistake it hid.
--
-- WHY IT WAS THE WEAKEST OF THE TEN. Every other link rested on one of two things: a ballot
-- designation naming an office we independently record ("Lieutenant Governor of California",
-- "Orange County Supervisor", "California State Assemblymember"), or a generic role backed by
-- a GEOGRAPHIC test -- ST_Intersects between the jurisdiction held and the district sought.
-- Shaw had neither:
--   * her designation, "School District President", names a ROLE TYPE and no district; and
--   * Superintendent of Public Instruction is a STATEWIDE race, so there is no district to
--     intersect and the geographic corroborator cannot run at all.
-- What remained was an exact unique name plus "we record a Sonja Shaw on a California school
-- board". That is a strong prior and it is not evidence. The whole point of CC_0262 and
-- CC_0263 was that a name is a lead.
--
-- ⚠ THIS IS NOT A STATEMENT THAT THEY ARE DIFFERENT PEOPLE. It is a statement that we have not
-- shown they are the same one. The honest state is unlinked, which is also the state the other
-- 117 unlinked CA general candidates are in -- she is now simply back among them rather than
-- being the one exception carried on a weaker standard than its neighbours.
--
-- ▶ WHAT WOULD SETTLE IT: anything naming the district beside the name. The Chino Valley USD
-- board roster, a CDE or county registrar filing, or a Shaw campaign page that states the
-- board seat. Then it links on the CC_0263 standard and this revert is itself reverted.
--
-- Nothing else is touched. No image, no answer, no other candidacy. Both rows carry no
-- photo_url of their own, so before CC_0263 and after this migration they render no
-- photograph -- unlinking takes nothing away that was there yesterday.
--
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _unlink (
  rc_id     uuid PRIMARY KEY,
  name_like text NOT NULL,
  was_pid   uuid NOT NULL
) ON COMMIT DROP;

INSERT INTO _unlink (rc_id, name_like, was_pid) VALUES
  ('4939c2c8-9bc4-4524-bdaf-daadff60f38c'::uuid, 'Sonja Shaw',
   '5f76110b-eb6c-59b4-8c6a-c97e8722cc05'::uuid),
  ('3e2a7783-ebf5-4d35-b9cb-f396c30dceab'::uuid, 'Sonja Shaw',
   '5f76110b-eb6c-59b4-8c6a-c97e8722cc05'::uuid);

-- Guard: each row must still be Sonja Shaw, and must either carry the link CC_0263 made or be
-- already unlinked. If something has since linked it to a DIFFERENT politician, that is a
-- decision this migration did not make and must not silently undo.
DO $$
DECLARE r record; v_name text; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _unlink LOOP
    SELECT rc.full_name, rc.politician_id INTO v_name, v_pid
      FROM essentials.race_candidates rc WHERE rc.id = r.rc_id;
    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0264: race_candidates row % does not exist', r.rc_id;
    END IF;
    IF v_name <> r.name_like THEN
      RAISE EXCEPTION 'CC_0264: row % is "%", expected "%"', r.rc_id, v_name, r.name_like;
    END IF;
    IF v_pid IS NOT NULL AND v_pid <> r.was_pid THEN
      RAISE EXCEPTION 'CC_0264: row % is linked to %, not the % CC_0263 set - REFUSING',
        r.rc_id, v_pid, r.was_pid;
    END IF;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc
SET politician_id = NULL
FROM _unlink u
WHERE rc.id = u.rc_id AND rc.politician_id IS NOT NULL;

-- post-verify: both rows unlinked, that politician holds no candidacy at all, and the other
-- NINE links CC_0263 made are untouched.
DO $$
DECLARE n_still int; n_pol int; n_kept int;
BEGIN
  SELECT count(*) INTO n_still
    FROM essentials.race_candidates rc JOIN _unlink u ON u.rc_id = rc.id
   WHERE rc.politician_id IS NOT NULL;
  IF n_still <> 0 THEN
    RAISE EXCEPTION 'CC_0264: % Shaw row(s) are still linked', n_still;
  END IF;

  SELECT count(*) INTO n_pol FROM essentials.race_candidates rc
   WHERE rc.politician_id = '5f76110b-eb6c-59b4-8c6a-c97e8722cc05'::uuid;
  IF n_pol <> 0 THEN
    RAISE EXCEPTION 'CC_0264: that politician still carries % candidacy row(s)', n_pol;
  END IF;

  -- the revert must be surgical: CC_0263's other nine links stay
  SELECT count(*) INTO n_kept FROM essentials.race_candidates rc
   WHERE rc.id IN ('92098672-ed73-4f9e-8fe7-ee80c1d8f27b'::uuid,
                   'd4da5724-bfbb-4862-9d6b-ed246cd50934'::uuid,
                   '62b18a26-5030-43df-9f70-05a76bd80374'::uuid,
                   '382f7d0e-9513-4814-b5a3-3d91ca632dc5'::uuid,
                   'fb0bd62e-d070-48b1-ab15-3b2516d97929'::uuid,
                   'd2844400-1923-4d9a-81c1-0f0641b070e4'::uuid,
                   'c0ebc8be-2514-4f72-a22c-64466b57546c'::uuid,
                   '8fb37db6-1429-496a-a51c-23d48310cd71'::uuid,
                   '94749547-4695-479c-a049-407cb5847eb1'::uuid)
     AND rc.politician_id IS NOT NULL;
  IF n_kept <> 9 THEN
    RAISE EXCEPTION 'CC_0264: expected CC_0263 to keep 9 links, found % - the revert was not surgical',
      n_kept;
  END IF;

  RAISE NOTICE 'CC_0264 OK - Shaw unlinked; CC_0263 keeps its other 9 links';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: NAME THE WEAKEST ROW WHEN YOU WRITE IT, NOT WHEN IT BREAKS.
-- CC_0263 shipped ten links and said in its own header which one was thinnest and why. That
-- is what made this revert a two-line decision instead of an audit. A batch migration that
-- presents every row as equally evidenced forces a reviewer to either accept all of it or
-- re-derive all of it.
-- ⚠ Unlinked is not "different people" -- it is "not shown to be the same person". Those are
-- different claims and only the second one is ours to make.
-- ───────────────────────────────────────────────────────────────────────────────────────────
