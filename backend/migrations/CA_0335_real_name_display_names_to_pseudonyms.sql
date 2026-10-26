-- CA_0335 — Replace four real-name display names with pseudonyms.
--
-- Until PR #1189 (2026-10-26), workosProvisionService built public.users.display_name
-- from the AuthKit sign-up first/last name. display_name is public, so these four
-- Connected members showed their real name on the platform — the exact thing the
-- identity vault (ev-cto decision 0022, live 2026-10-26) exists to prevent.
-- Chris Andrews checked the four candidates by hand on 2026-10-26: all four are real
-- names. The names themselves are deliberately NOT written here (this repo is public).
--
-- The pseudonyms come from generateUniqueAutoName (backend/src/lib/displayName.ts),
-- checked unique against prod at generation time. Members can change them on their
-- profile page.
--
-- The name is copied in three tables: public.users, connect.connected_profiles, and
-- (for one member) civic_spaces.connected_profiles. None of the four has posts or
-- threads, so no author_display_name snapshot carries it.
--
-- Idempotent: each UPDATE only touches a row whose display_name is not already the
-- pseudonym. Re-running is a no-op.

BEGIN;

CREATE TEMP TABLE ca0335_map (user_id uuid PRIMARY KEY, pseudonym text NOT NULL) ON COMMIT DROP;
INSERT INTO ca0335_map (user_id, pseudonym) VALUES
  ('7e6be041-7242-41e7-9c63-5a1198c5eeb6', 'TealRobin'),
  ('781f754d-8e4e-4088-a689-8a51a5f8a019', 'TidalKestrel'),
  ('54ff4779-3d74-4749-9c15-861074fa85b4', 'SwiftQuail'),
  ('4264e82e-806f-4248-b9e1-8382177268eb', 'TidalMoose');

-- Pre-check: no OTHER user already holds one of these pseudonyms.
DO $$
DECLARE v_taken int;
BEGIN
  SELECT count(*) INTO v_taken
    FROM public.users u JOIN ca0335_map m ON lower(btrim(u.display_name)) = lower(m.pseudonym)
   WHERE u.id <> m.user_id;
  IF v_taken <> 0 THEN
    RAISE EXCEPTION 'CA_0335: % pseudonym(s) already taken by another user — regenerate', v_taken;
  END IF;
END $$;

UPDATE public.users u
   SET display_name = m.pseudonym, updated_at = now()
  FROM ca0335_map m
 WHERE u.id = m.user_id
   AND u.display_name IS DISTINCT FROM m.pseudonym;

UPDATE connect.connected_profiles c
   SET display_name = m.pseudonym
  FROM ca0335_map m
 WHERE c.user_id = m.user_id
   AND c.display_name IS DISTINCT FROM m.pseudonym;

UPDATE civic_spaces.connected_profiles c
   SET display_name = m.pseudonym
  FROM ca0335_map m
 WHERE c.user_id::text = m.user_id::text
   AND c.display_name IS DISTINCT FROM m.pseudonym;

-- Post-verify gate: every copy of the four display names is now the pseudonym.
DO $$
DECLARE v_users int; v_connect int; v_cs int;
BEGIN
  SELECT count(*) INTO v_users
    FROM public.users u JOIN ca0335_map m ON u.id = m.user_id
   WHERE u.display_name = m.pseudonym;
  IF v_users <> 4 THEN
    RAISE EXCEPTION 'CA_0335: expected 4 users carrying their pseudonym, found %', v_users;
  END IF;

  SELECT count(*) INTO v_connect
    FROM connect.connected_profiles c JOIN ca0335_map m ON c.user_id = m.user_id
   WHERE c.display_name IS DISTINCT FROM m.pseudonym;
  SELECT count(*) INTO v_cs
    FROM civic_spaces.connected_profiles c JOIN ca0335_map m ON c.user_id::text = m.user_id::text
   WHERE c.display_name IS DISTINCT FROM m.pseudonym;
  IF v_connect <> 0 OR v_cs <> 0 THEN
    RAISE EXCEPTION 'CA_0335: profile copies not updated (connect %, civic_spaces %)', v_connect, v_cs;
  END IF;
END $$;

COMMIT;
