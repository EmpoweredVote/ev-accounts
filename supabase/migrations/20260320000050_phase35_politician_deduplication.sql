-- Phase 35: Politician Deduplication
-- Merges inform.politicians (30 records) into essentials.politicians (1,854 records)
-- as the single source of truth. Creates bridge table for audit trail.
-- All FK references in politician_answers and politician_context are reassigned.
-- RPCs confirm_vq_stance and admin_list_politicians are rebuilt.
-- inform.politicians is dropped.

BEGIN;

-- ============================================================
-- Step 1: INSERT 4 inform politicians not found in essentials
-- (Karen Bass, Nanette Barragan, Tony Cardenas, Gilbert Cisneros)
-- ============================================================

INSERT INTO essentials.politicians (id, first_name, last_name, full_name, photo_origin_url, is_active, is_incumbent, is_vacant, data_source)
VALUES
  ('2f96d5e2-8284-490d-8ba1-d204b649f45a', 'Karen',    'Bass',     'Karen Bass',    NULL, true,  true,  false, 'inform-migration'),
  ('6f5db776-afcb-40c3-87a5-83e9408d3044', 'Nanette',  'Barragan', 'Nanette Barragan', NULL, true, true, false, 'inform-migration'),
  ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c', 'Tony',     'Cardenas', 'Tony Cardenas', NULL, false, false, false, 'inform-migration'),
  ('65f08851-9336-4a38-a239-3f5bf3333095', 'Gilbert',  'Cisneros', 'Gilbert Cisneros', NULL, false, false, false, 'inform-migration');

-- ============================================================
-- Step 2: Create bridge table (permanent audit trail)
-- inform_id has no FK to inform.politicians because that table
-- is dropped later in this migration.
-- ============================================================

CREATE TABLE public.politician_id_bridge (
  essentials_id UUID NOT NULL REFERENCES essentials.politicians(id),
  inform_id     UUID NOT NULL,
  matched_by    TEXT NOT NULL DEFAULT 'name_match',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (essentials_id, inform_id)
);

-- ============================================================
-- Step 3: Populate bridge table with all 30 mappings
-- 4 politicians inserted into essentials using their original
-- inform UUIDs, so essentials_id = inform_id for those 4.
-- 26 matched by first_name + last_name in essentials.
-- ============================================================

INSERT INTO public.politician_id_bridge (essentials_id, inform_id, matched_by) VALUES
  -- 4 politicians inserted into essentials with same UUID (identity mapping)
  ('2f96d5e2-8284-490d-8ba1-d204b649f45a', '2f96d5e2-8284-490d-8ba1-d204b649f45a', 'identity_insert'),  -- Karen Bass
  ('6f5db776-afcb-40c3-87a5-83e9408d3044', '6f5db776-afcb-40c3-87a5-83e9408d3044', 'identity_insert'),  -- Nanette Barragan
  ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c', 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c', 'identity_insert'),  -- Tony Cardenas
  ('65f08851-9336-4a38-a239-3f5bf3333095', '65f08851-9336-4a38-a239-3f5bf3333095', 'identity_insert'),  -- Gilbert Cisneros
  -- 26 matched by name to existing essentials records
  ('822966a7-5f09-4151-ba43-630afbd676c2', '3e5be808-2dd0-4338-bfb3-fa0c4b8399d0', 'name_match'),       -- Pete Aguilar
  ('023c6644-356e-4afb-925b-e20f9c32209b', '3e39e91a-5d75-46b9-b401-e616c1508d80', 'name_match'),       -- Jim Banks
  ('929346a2-8037-4b14-af33-4820eb365323', '22bd1797-732d-43f6-9906-b655f51698d4', 'name_match'),       -- Micah Beckwith
  ('a73e7a2a-48b0-4636-8fa4-5324ede65833', '0fafda7d-b9f1-4ded-bb12-2a26778915a9', 'name_match'),       -- Mike Braun
  ('01147c2b-0f40-4255-b09e-b5a19a45fd31', '614a422a-b063-48ef-84e9-706232ab6adc', 'name_match'),       -- Julia Brownley
  ('d75dfa60-351b-4f0d-880a-45acf013c82a', '59df7b1d-4c0a-45cd-ad49-737984e2c8cc', 'name_match'),       -- Judy Chu
  ('e099da71-f9d9-445d-96d9-179952bd539c', '725738eb-b927-4e17-8a02-5dd07fdef2ce', 'name_match'),       -- Laura Friedman
  ('28a5f098-7f90-4fa9-af7e-c034d49cb538', '70ad4cff-f286-47a2-a82a-bfcaf5cf0505', 'name_match'),       -- Robert Garcia
  ('99d93781-7c5f-492c-b959-ee502ca05c29', '84e2c16b-8c3a-4853-b317-226529fb7f74', 'name_match'),       -- Jimmy Gomez
  ('68568faf-1e0f-4ca2-89d9-bda625665712', '7d51fd78-efec-4b72-adab-9c8b291bf201', 'name_match'),       -- Erin Houchin
  ('a2c6adc7-7689-49b9-964f-8f2aeb243a83', 'c0ab598a-2dd9-4f2b-9bc2-3d0c24f1ad9f', 'name_match'),       -- Sydney Kamlager-Dove
  ('03df7cce-7502-4089-acd5-139841002cbe', '131643ce-b93d-4380-9747-7ff573b657e9', 'name_match'),       -- Eleni Kounalakis
  ('3a39c313-b994-447b-b3fd-592e4994769b', '4d0d17c8-eef2-4570-8669-c2ffbb8ae94d', 'name_match'),       -- Ted Lieu
  ('f26309c8-2525-49b2-bdaf-62980cbb1853', 'd82e04d9-0526-4ef0-a5f5-5b8104cc25bf', 'name_match'),       -- Gavin Newsom
  ('18db5d61-6bce-4f55-ad45-bed01f329548', '3913e69e-1b47-4e53-b5a5-dc7c26f7b854', 'name_match'),       -- Jay Obernolte
  ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f', 'da265a43-2a9e-4389-a4ef-8ebc9e8d94fb', 'name_match'),       -- Alex Padilla (office_id variant)
  ('a1fc524b-7c90-43c0-83a7-c76664293913', 'bec47410-3f73-4ee6-9bba-b2dae3a50cfe', 'name_match'),       -- Luz Rivas
  ('bb73793e-ad67-431a-bb03-663b765204d8', '370005a4-afcc-4c78-9140-ab63f6a49a5b', 'name_match'),       -- Linda Sanchez
  ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032', '5cb64130-00ef-497e-9a00-46eda456b0f1', 'name_match'),       -- Adam Schiff
  ('96c77e2b-df35-4d56-a573-8bc0c15a142d', '6e303525-634d-4678-977a-045c4d0d9f90', 'name_match'),       -- Brad Sherman
  ('1c6dbdaf-e110-48d3-9b88-27f911d9521f', '3c31f081-f962-4e26-b460-7704c92fb7f9', 'name_match'),       -- Kerry Thomson
  ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6', 'd3336a90-d229-43d5-b2ee-f5c96956e96e', 'name_match'),       -- Norma Torres
  ('b7612f49-c914-4ea7-a6da-559d71f313c2', '0c583c4f-b6a1-40e7-8979-52b9105a6e97', 'name_match'),       -- Derek Tran
  ('203ab943-324d-4478-9093-d827d5d9c7da', '346e7ede-ad1c-44c7-b6ba-0364144594cd', 'name_match'),       -- Maxine Waters
  ('c2f8656e-f73a-42ec-996e-87fceedf0389', '9c9725dc-8473-4c57-891b-fa7f4361aab1', 'name_match'),       -- George Whitesides
  ('102b239c-0a3d-44b9-ae32-88d8179197e2', '325b3171-ff53-4ee0-9341-89c1d63524a0', 'name_match');       -- Todd Young

-- ============================================================
-- Step 4: Drop ALL FK constraints referencing inform.politicians
-- before any data migration or DROP TABLE.
-- empowered_profiles.politician_id is entirely NULL (no data to migrate).
-- ============================================================

ALTER TABLE inform.politician_answers DROP CONSTRAINT IF EXISTS politician_answers_politician_id_fkey;
ALTER TABLE inform.politician_context DROP CONSTRAINT IF EXISTS politician_context_politician_id_fkey;
ALTER TABLE empower.empowered_profiles DROP CONSTRAINT IF EXISTS empowered_profiles_politician_id_fkey;

-- ============================================================
-- Step 5: Reassign FKs in politician_answers
-- ============================================================

UPDATE inform.politician_answers pa
SET politician_id = bridge.essentials_id
FROM public.politician_id_bridge bridge
WHERE pa.politician_id = bridge.inform_id
  AND bridge.essentials_id <> bridge.inform_id;

-- ============================================================
-- Step 6: Reassign FKs in politician_context
-- ============================================================

UPDATE inform.politician_context pc
SET politician_id = bridge.essentials_id
FROM public.politician_id_bridge bridge
WHERE pc.politician_id = bridge.inform_id
  AND bridge.essentials_id <> bridge.inform_id;

-- ============================================================
-- Step 7: Add new FK constraints pointing to essentials.politicians
-- ============================================================

ALTER TABLE inform.politician_answers
  ADD CONSTRAINT politician_answers_politician_id_fkey
  FOREIGN KEY (politician_id) REFERENCES essentials.politicians(id);

ALTER TABLE inform.politician_context
  ADD CONSTRAINT politician_context_politician_id_fkey
  FOREIGN KEY (politician_id) REFERENCES essentials.politicians(id);

ALTER TABLE empower.empowered_profiles
  ADD CONSTRAINT empowered_profiles_politician_id_fkey
  FOREIGN KEY (politician_id) REFERENCES essentials.politicians(id);

-- ============================================================
-- Step 8: Rebuild confirm_vq_stance RPC
-- Only change: FROM inform.politicians p → FROM essentials.politicians p
-- ============================================================

CREATE OR REPLACE FUNCTION connect.confirm_vq_stance(
  p_politician_id    UUID,
  p_topic_id         UUID,
  p_confirmed_value  INTEGER,
  p_correct_users    UUID[],
  p_incorrect_users  UUID[],
  p_idempotency_key  TEXT,
  p_gems_amount      INTEGER
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_cached_result     JSONB;
  v_return_result     JSONB;
  v_politician_exists BOOLEAN;
  v_all_users         UUID[];
  v_sorted_users      UUID[];
  v_uid               UUID;
  v_vr                INTEGER;
  v_gem_balance_red   INTEGER;
  v_new_rating        INTEGER;
  v_rating_delta      INTEGER;
  v_user_results      JSONB[] := ARRAY[]::JSONB[];
  v_unresolved_users  UUID[]  := ARRAY[]::UUID[];
  v_correct_count     INTEGER := 0;
  v_incorrect_count   INTEGER := 0;
BEGIN
  IF p_confirmed_value < 1 OR p_confirmed_value > 5 THEN
    RAISE EXCEPTION 'INVALID_VALUE: confirmed_value must be between 1 and 5';
  END IF;
  SELECT result_json INTO v_cached_result FROM connect.vq_confirmation_results WHERE idempotency_key = p_idempotency_key;
  IF FOUND THEN RETURN v_cached_result || '{"replayed": true}'::JSONB; END IF;
  SELECT EXISTS (
    SELECT 1 FROM essentials.politicians p
     WHERE p.id = p_politician_id
       AND EXISTS (SELECT 1 FROM inform.compass_topics t WHERE t.id = p_topic_id)
  ) INTO v_politician_exists;
  IF NOT v_politician_exists THEN
    RAISE EXCEPTION 'QUESTION_NOT_FOUND: politician % or topic % does not exist', p_politician_id, p_topic_id;
  END IF;
  v_all_users := ARRAY(SELECT DISTINCT unnest(p_correct_users || p_incorrect_users));
  SELECT ARRAY(SELECT u FROM unnest(v_all_users) u ORDER BY u::TEXT) INTO v_sorted_users;
  FOREACH v_uid IN ARRAY v_sorted_users LOOP
    PERFORM pg_advisory_xact_lock(hashtext(v_uid::TEXT));
  END LOOP;
  FOREACH v_uid IN ARRAY p_correct_users LOOP
    SELECT verification_rating, gem_balance_red INTO v_vr, v_gem_balance_red FROM connect.connected_profiles WHERE user_id = v_uid FOR UPDATE;
    IF NOT FOUND THEN v_unresolved_users := v_unresolved_users || v_uid; CONTINUE; END IF;
    v_new_rating := LEAST(v_vr + 3, 150);
    v_rating_delta := v_new_rating - v_vr;
    UPDATE connect.connected_profiles SET verification_rating = v_new_rating WHERE user_id = v_uid;
    INSERT INTO connect.gem_transactions (user_id, gem_type, amount, transaction_type, idempotency_key, balance_after) VALUES (v_uid, 'red', p_gems_amount, 'vq_correct', p_idempotency_key || ':' || v_uid::TEXT, v_gem_balance_red + p_gems_amount);
    UPDATE connect.connected_profiles SET gem_balance_red = gem_balance_red + p_gems_amount WHERE user_id = v_uid;
    v_user_results := v_user_results || jsonb_build_object('user_id', v_uid, 'result', 'correct', 'gems_awarded', p_gems_amount, 'rating_delta', v_rating_delta, 'new_rating', v_new_rating);
    v_correct_count := v_correct_count + 1;
  END LOOP;
  FOREACH v_uid IN ARRAY p_incorrect_users LOOP
    SELECT verification_rating INTO v_vr FROM connect.connected_profiles WHERE user_id = v_uid FOR UPDATE;
    IF NOT FOUND THEN v_unresolved_users := v_unresolved_users || v_uid; CONTINUE; END IF;
    v_new_rating := GREATEST(v_vr - 10, 0);
    v_rating_delta := v_new_rating - v_vr;
    UPDATE connect.connected_profiles SET verification_rating = v_new_rating, vq_hold_until = CASE WHEN v_new_rating = 0 THEN now() + INTERVAL '30 days' ELSE vq_hold_until END WHERE user_id = v_uid;
    v_user_results := v_user_results || jsonb_build_object('user_id', v_uid, 'result', 'incorrect', 'gems_awarded', 0, 'rating_delta', v_rating_delta, 'new_rating', v_new_rating);
    v_incorrect_count := v_incorrect_count + 1;
  END LOOP;
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (p_politician_id, p_topic_id, p_confirmed_value) ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
  v_return_result := jsonb_build_object('politician_id', p_politician_id, 'topic_id', p_topic_id, 'confirmed_value', p_confirmed_value, 'correct_count', v_correct_count, 'incorrect_count', v_incorrect_count, 'users', to_jsonb(v_user_results), 'unresolved_users', to_jsonb(v_unresolved_users));
  INSERT INTO connect.vq_confirmation_results (idempotency_key, result_json) VALUES (p_idempotency_key, v_return_result);
  RETURN v_return_result;
END;
$$;

GRANT EXECUTE ON FUNCTION connect.confirm_vq_stance(UUID, UUID, INTEGER, UUID[], UUID[], TEXT, INTEGER) TO authenticated;

-- ============================================================
-- Step 9: Rebuild admin_list_politicians RPC
-- essentials.politicians has different columns than inform.politicians.
-- New return type uses essentials columns only.
-- answer_count subquery still references inform.politician_answers (that table stays).
-- ============================================================

DROP FUNCTION IF EXISTS public.admin_list_politicians();

CREATE OR REPLACE FUNCTION public.admin_list_politicians()
RETURNS TABLE(
  id               uuid,
  first_name       text,
  last_name        text,
  preferred_name   text,
  full_name        text,
  photo_origin_url text,
  is_active        boolean,
  is_vacant        boolean,
  is_incumbent     boolean,
  party            text,
  party_short_name text,
  slug             text,
  bio_text         text,
  answer_count     bigint
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.preferred_name,
    p.full_name,
    p.photo_origin_url,
    p.is_active,
    p.is_vacant,
    p.is_incumbent,
    p.party,
    p.party_short_name,
    p.slug,
    p.bio_text,
    (SELECT COUNT(*) FROM inform.politician_answers pa WHERE pa.politician_id = p.id) AS answer_count
  FROM essentials.politicians p
  WHERE (SELECT COUNT(*) FROM inform.politician_answers pa WHERE pa.politician_id = p.id) > 0
     OR (SELECT COUNT(*) FROM inform.politician_context pc WHERE pc.politician_id = p.id) > 0
  ORDER BY p.last_name, p.first_name;
$$;

GRANT EXECUTE ON FUNCTION public.admin_list_politicians() TO service_role, authenticated;

-- ============================================================
-- Step 10: Orphan check assertions
-- ============================================================

DO $$
DECLARE
  orphan_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO orphan_count
  FROM inform.politician_answers pa
  LEFT JOIN essentials.politicians ep ON pa.politician_id = ep.id
  WHERE ep.id IS NULL;

  IF orphan_count > 0 THEN
    RAISE EXCEPTION 'ORPHAN_CHECK_FAILED: % orphaned rows in politician_answers', orphan_count;
  END IF;

  SELECT COUNT(*) INTO orphan_count
  FROM inform.politician_context pc
  LEFT JOIN essentials.politicians ep ON pc.politician_id = ep.id
  WHERE ep.id IS NULL;

  IF orphan_count > 0 THEN
    RAISE EXCEPTION 'ORPHAN_CHECK_FAILED: % orphaned rows in politician_context', orphan_count;
  END IF;
END $$;

-- ============================================================
-- Step 11: Drop inform.politicians
-- ============================================================

DROP TABLE inform.politicians;

-- ============================================================
-- Step 12: RLS on bridge table
-- ============================================================

ALTER TABLE public.politician_id_bridge ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_politician_id_bridge"
  ON public.politician_id_bridge
  FOR SELECT
  USING (true);

-- ============================================================
-- Step 13: Grant permissions on bridge table
-- ============================================================

GRANT SELECT ON public.politician_id_bridge TO anon, authenticated, service_role;

COMMIT;
