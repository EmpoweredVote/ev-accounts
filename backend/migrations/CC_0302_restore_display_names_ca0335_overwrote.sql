-- CC_0302 — Restore the four display names CA_0335 replaced with generated pseudonyms.
--
-- 🔴 CA_0335's PREMISE DID NOT HOLD. PR #1191 said all four accounts "showed their real
-- name", and on that basis replaced each with a generateUniqueAutoName pseudonym. They did
-- not. Two were plainly chosen handles — "Gray Mouser" is a Fritz Leiber character, and
-- "Boffrey the Destroyer" is nobody's legal name. The other two were first name plus last
-- initial, a deliberate partial. No real name was ever exposed by these four rows.
--
-- Likely cause of the misreading (HYPOTHESIS, not established): connect.connected_profiles
-- .legal_name held the real names at that time. An admin account view shows both fields.
--
-- Recovered 2026-10-27 from a Supabase "restore to a new project" clone of the E.V Backend
-- daily backup at ~2026-10-25 03:54 UTC, because CA_0335 overwrote the only live copy and
-- this database keeps no history of display_name.
--
-- 🔴 PROOF these are the values CA_0335 overwrote, not something older: all 28 accounts
-- present in that backup carry byte-identical display_name AND updated_at in production
-- today, EXCEPT these four, whose updated_at is 2026-10-27 06:39:38.630173+00 — the moment
-- CA_0335 ran. Nothing else wrote a display name in the window.
--
-- ▶ THE LESSON, AND WHY THE PSEUDONYMS ARE WRITTEN DOWN BELOW: a migration that overwrites
--   a value must record the value it overwrote. CA_0335 did not, so recovering four strings
--   cost a full production clone. The pseudonyms being replaced here are therefore named in
--   this file, so that undoing THIS migration never needs a backup.
--
--   user_id                                 was (restored)          CA_0335 set (removed)
--   7e6be041-7242-41e7-9c63-5a1198c5eeb6    Gray Mouser             TealRobin
--   781f754d-8e4e-4088-a689-8a51a5f8a019    Boffrey the Destroyer   TidalKestrel
--   54ff4779-3d74-4749-9c15-861074fa85b4    George P.               SwiftQuail
--   4264e82e-806f-4248-b9e1-8382177268eb    Simon F                 TidalMoose
--
-- Scope note: this restores display_name ONLY. legal_name was cleared on all 9 profiles
-- that carried it, platform-wide, between 2026-10-25 and 2026-10-27. That was NOT CA_0335
-- and is NOT reversed here — see the operator note in the PR.
--
-- Idempotent: each UPDATE only touches a row that is not already correct.

BEGIN;

CREATE TEMP TABLE cc0302_map (user_id uuid PRIMARY KEY, restore_to text NOT NULL, undo text NOT NULL)
  ON COMMIT DROP;
INSERT INTO cc0302_map (user_id, restore_to, undo) VALUES
  ('7e6be041-7242-41e7-9c63-5a1198c5eeb6', 'Gray Mouser',           'TealRobin'),
  ('781f754d-8e4e-4088-a689-8a51a5f8a019', 'Boffrey the Destroyer', 'TidalKestrel'),
  ('54ff4779-3d74-4749-9c15-861074fa85b4', 'George P.',             'SwiftQuail'),
  ('4264e82e-806f-4248-b9e1-8382177268eb', 'Simon F',               'TidalMoose');

-- Pre-flight: every target must currently hold the CA_0335 pseudonym. If one does not, the
-- person has changed their own name since, and this migration must not stamp over them.
DO $$
DECLARE v_wrong int;
BEGIN
  SELECT count(*) INTO v_wrong
    FROM public.users u JOIN cc0302_map m ON u.id = m.user_id
   WHERE u.display_name IS DISTINCT FROM m.undo;
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION 'CC_0302 PRE-FLIGHT: % target(s) do not hold their CA_0335 pseudonym — someone changed a name; re-check before running', v_wrong;
  END IF;
END $$;

-- Pre-flight: no OTHER user already holds a name we are about to restore.
DO $$
DECLARE v_taken int;
BEGIN
  SELECT count(*) INTO v_taken
    FROM public.users u JOIN cc0302_map m ON lower(btrim(u.display_name)) = lower(m.restore_to)
   WHERE u.id <> m.user_id;
  IF v_taken <> 0 THEN
    RAISE EXCEPTION 'CC_0302 PRE-FLIGHT: % restored name(s) are held by another user', v_taken;
  END IF;
END $$;

UPDATE public.users u
   SET display_name = m.restore_to, updated_at = now()
  FROM cc0302_map m
 WHERE u.id = m.user_id
   AND u.display_name IS DISTINCT FROM m.restore_to;

UPDATE connect.connected_profiles c
   SET display_name = m.restore_to
  FROM cc0302_map m
 WHERE c.user_id = m.user_id
   AND c.display_name IS DISTINCT FROM m.restore_to;

UPDATE civic_spaces.connected_profiles c
   SET display_name = m.restore_to
  FROM cc0302_map m
 WHERE c.user_id::text = m.user_id::text
   AND c.display_name IS DISTINCT FROM m.restore_to;

-- Post-verify: every copy carries the restored name, and no copy still carries a pseudonym.
DO $$
DECLARE v_users int; v_connect int; v_cs int; v_leftover int;
BEGIN
  SELECT count(*) INTO v_users
    FROM public.users u JOIN cc0302_map m ON u.id = m.user_id
   WHERE u.display_name = m.restore_to;
  IF v_users <> 4 THEN
    RAISE EXCEPTION 'CC_0302 POST-VERIFY: expected 4 restored users, found %', v_users;
  END IF;

  SELECT count(*) INTO v_connect
    FROM connect.connected_profiles c JOIN cc0302_map m ON c.user_id = m.user_id
   WHERE c.display_name IS DISTINCT FROM m.restore_to;
  SELECT count(*) INTO v_cs
    FROM civic_spaces.connected_profiles c JOIN cc0302_map m ON c.user_id::text = m.user_id::text
   WHERE c.display_name IS DISTINCT FROM m.restore_to;
  IF v_connect <> 0 OR v_cs <> 0 THEN
    RAISE EXCEPTION 'CC_0302 POST-VERIFY: profile copies not restored (connect %, civic_spaces %)', v_connect, v_cs;
  END IF;

  -- No generated pseudonym may survive anywhere in public.users.
  SELECT count(*) INTO v_leftover
    FROM public.users u JOIN cc0302_map m ON lower(btrim(u.display_name)) = lower(m.undo);
  IF v_leftover <> 0 THEN
    RAISE EXCEPTION 'CC_0302 POST-VERIFY: % CA_0335 pseudonym(s) still present', v_leftover;
  END IF;
END $$;

COMMIT;
