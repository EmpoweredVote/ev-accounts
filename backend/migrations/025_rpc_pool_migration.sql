-- =============================================================================
-- Migration 025: RPC functions to replace pg pool queries
--
-- All functions are SECURITY DEFINER so they bypass RLS, matching the
-- behavior of the pg pool queries they replace.
-- Called via supabaseAdmin.rpc('function_name', params).
-- =============================================================================

-- =============================================================================
-- ADMIN FUNCTIONS
-- =============================================================================

-- admin_get_dashboard_stats
-- Returns cohort-level counts: tier distribution, account standing,
-- pending verifications, recent invite activity, active invite codes.
CREATE OR REPLACE FUNCTION public.admin_get_dashboard_stats()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tier_counts jsonb;
  v_standing_counts jsonb;
  v_pending_verifications int;
  v_recent_invites_7d int;
  v_active_invite_codes int;
BEGIN
  SELECT jsonb_agg(row_to_json(t))
  INTO v_tier_counts
  FROM (
    SELECT
      CASE
        WHEN ep.user_id IS NOT NULL THEN 'empowered'
        WHEN cp.user_id IS NOT NULL THEN 'connected'
        ELSE 'inform'
      END AS tier,
      COUNT(*)::int AS count
    FROM public.users u
    LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
    LEFT JOIN empower.empowered_profiles ep ON ep.user_id = u.id AND ep.is_active = true
    WHERE u.deleted_at IS NULL
    GROUP BY 1
  ) t;

  SELECT jsonb_agg(row_to_json(t))
  INTO v_standing_counts
  FROM (
    SELECT account_standing, COUNT(*)::int AS count
    FROM connect.connected_profiles
    GROUP BY account_standing
  ) t;

  SELECT COUNT(*)::int INTO v_pending_verifications
  FROM connect.verification_sessions
  WHERE step_reached != 'complete';

  SELECT COUNT(*)::int INTO v_recent_invites_7d
  FROM connect.invite_codes
  WHERE created_at >= now() - interval '7 days';

  SELECT COUNT(*)::int INTO v_active_invite_codes
  FROM connect.invite_codes
  WHERE is_claimed = false
    AND (expires_at IS NULL OR expires_at > now());

  RETURN jsonb_build_object(
    'users_by_tier', COALESCE(v_tier_counts, '[]'::jsonb),
    'users_by_standing', COALESCE(v_standing_counts, '[]'::jsonb),
    'pending_verifications', v_pending_verifications,
    'recent_invites_7d', v_recent_invites_7d,
    'active_invite_codes', v_active_invite_codes
  );
END;
$$;

-- admin_list_accounts
-- Returns paginated account list with optional search, tier, and standing filters.
-- p_tier: 'empowered' | 'connected' | 'inform' | NULL
-- p_standing: 'active' | 'suspended' | NULL
-- p_search: substring search on display_name or email (ILIKE)
CREATE OR REPLACE FUNCTION public.admin_list_accounts(
  p_search text DEFAULT NULL,
  p_tier text DEFAULT NULL,
  p_standing text DEFAULT NULL,
  p_page int DEFAULT 1
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_limit constant int := 25;
  v_offset int;
  v_total int;
  v_accounts jsonb;
BEGIN
  v_offset := (p_page - 1) * v_limit;

  -- Count query
  SELECT COUNT(*)::int INTO v_total
  FROM public.users u
  LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
  LEFT JOIN empower.empowered_profiles ep ON ep.user_id = u.id AND ep.is_active = true
  WHERE u.deleted_at IS NULL
    AND (p_search IS NULL OR u.display_name ILIKE '%' || p_search || '%' OR u.email ILIKE '%' || p_search || '%')
    AND (p_standing IS NULL OR cp.account_standing = p_standing)
    AND (
      p_tier IS NULL
      OR (p_tier = 'empowered' AND ep.user_id IS NOT NULL)
      OR (p_tier = 'connected' AND cp.user_id IS NOT NULL AND ep.user_id IS NULL)
      OR (p_tier = 'inform' AND cp.user_id IS NULL)
    );

  -- Data query
  SELECT jsonb_agg(row_to_json(t))
  INTO v_accounts
  FROM (
    SELECT
      u.id,
      u.display_name,
      u.email,
      u.created_at,
      cp.account_standing,
      cp.verification_status,
      CASE
        WHEN ep.user_id IS NOT NULL THEN 'empowered'
        WHEN cp.user_id IS NOT NULL THEN 'connected'
        ELSE 'inform'
      END AS tier
    FROM public.users u
    LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
    LEFT JOIN empower.empowered_profiles ep ON ep.user_id = u.id AND ep.is_active = true
    WHERE u.deleted_at IS NULL
      AND (p_search IS NULL OR u.display_name ILIKE '%' || p_search || '%' OR u.email ILIKE '%' || p_search || '%')
      AND (p_standing IS NULL OR cp.account_standing = p_standing)
      AND (
        p_tier IS NULL
        OR (p_tier = 'empowered' AND ep.user_id IS NOT NULL)
        OR (p_tier = 'connected' AND cp.user_id IS NOT NULL AND ep.user_id IS NULL)
        OR (p_tier = 'inform' AND cp.user_id IS NULL)
      )
    ORDER BY u.created_at DESC
    LIMIT v_limit OFFSET v_offset
  ) t;

  RETURN jsonb_build_object(
    'accounts', COALESCE(v_accounts, '[]'::jsonb),
    'total', v_total
  );
END;
$$;

-- admin_get_account_detail
-- Returns full account detail including connected/empowered profiles, active roles,
-- recent audit log (last 20), and calibration lapse info.
-- Raises 'NOT_FOUND' if user does not exist.
CREATE OR REPLACE FUNCTION public.admin_get_account_detail(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user jsonb;
  v_connected_profile jsonb;
  v_empowered_profile jsonb;
  v_roles jsonb;
  v_audit_log jsonb;
  v_lapse jsonb;
  v_tier text;
  v_ep_active bool;
  v_ep_exists bool;
  v_cp_exists bool;
BEGIN
  -- Base user record
  SELECT row_to_json(t) INTO v_user
  FROM (
    SELECT id, display_name, email, avatar_url, created_at, deleted_at
    FROM public.users WHERE id = p_user_id
  ) t;

  IF v_user IS NULL THEN
    RAISE EXCEPTION 'NOT_FOUND';
  END IF;

  -- Connected profile (includes tolerance_rating and legal_name — admin only)
  SELECT row_to_json(t) INTO v_connected_profile
  FROM (SELECT * FROM connect.connected_profiles WHERE user_id = p_user_id) t;

  v_cp_exists := v_connected_profile IS NOT NULL;

  -- Empowered profile
  SELECT row_to_json(t) INTO v_empowered_profile
  FROM (SELECT * FROM empower.empowered_profiles WHERE user_id = p_user_id) t;

  -- Determine tier
  IF v_empowered_profile IS NOT NULL THEN
    v_ep_active := (v_empowered_profile->>'is_active')::bool;
  ELSE
    v_ep_active := false;
  END IF;

  IF v_ep_active THEN
    v_tier := 'empowered';
  ELSIF v_cp_exists THEN
    v_tier := 'connected';
  ELSE
    v_tier := 'inform';
  END IF;

  -- Active user roles
  SELECT jsonb_agg(row_to_json(t))
  INTO v_roles
  FROM (
    SELECT ur.role_id, r.slug, r.name, ur.granted_at
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = p_user_id AND ur.revoked_at IS NULL
    ORDER BY ur.granted_at DESC
  ) t;

  -- Recent admin audit log (last 20)
  SELECT jsonb_agg(row_to_json(t))
  INTO v_audit_log
  FROM (
    SELECT id, actor_id, action, details, created_at
    FROM public.admin_audit_log
    WHERE target_user_id = p_user_id
    ORDER BY created_at DESC
    LIMIT 20
  ) t;

  -- Calibration lapse info
  SELECT jsonb_build_object(
    'overdue_count', COUNT(*)::int,
    'overdue_topic_ids', COALESCE(jsonb_agg(ct.id::text), '[]'::jsonb),
    'min_days_overdue', MIN((CURRENT_DATE - ct.went_live_at::date)::integer)
  )
  INTO v_lapse
  FROM inform.compass_topics ct
  WHERE ct.is_live = true
    AND ct.went_live_at IS NOT NULL
    AND ct.went_live_at <= now() - interval '25 days'
    AND NOT EXISTS (
      SELECT 1 FROM inform.compass_responses cr
      WHERE cr.user_id = p_user_id AND cr.topic_id = ct.id
    );

  RETURN v_user
    || jsonb_build_object(
        'tier', v_tier,
        'connected_profile', v_connected_profile,
        'empowered_profile', v_empowered_profile,
        'roles', COALESCE(v_roles, '[]'::jsonb),
        'recent_audit_log', COALESCE(v_audit_log, '[]'::jsonb),
        'calibration_lapse', v_lapse
       );
END;
$$;

-- admin_list_invites
-- Returns paginated invite codes with creator and claimer display names.
CREATE OR REPLACE FUNCTION public.admin_list_invites(p_page int DEFAULT 1)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_limit constant int := 25;
  v_offset int;
  v_total int;
  v_invites jsonb;
BEGIN
  v_offset := (p_page - 1) * v_limit;

  SELECT COUNT(*)::int INTO v_total FROM connect.invite_codes;

  SELECT jsonb_agg(row_to_json(t))
  INTO v_invites
  FROM (
    SELECT
      ic.id,
      ic.code,
      ic.is_claimed,
      ic.claimed_at,
      ic.expires_at,
      ic.created_at,
      creator.display_name AS created_by_display_name,
      ic.created_by AS created_by_id,
      COALESCE(claimer.display_name, cp.legal_name) AS claimed_by_display_name,
      ic.claimed_by AS claimed_by_id
    FROM connect.invite_codes ic
    LEFT JOIN public.users creator ON creator.id = ic.created_by
    LEFT JOIN public.users claimer ON claimer.id = ic.claimed_by
    LEFT JOIN connect.connected_profiles cp ON cp.user_id = ic.claimed_by
    ORDER BY ic.created_at DESC
    LIMIT v_limit OFFSET v_offset
  ) t;

  RETURN jsonb_build_object(
    'invites', COALESCE(v_invites, '[]'::jsonb),
    'total', v_total
  );
END;
$$;

-- admin_get_invite_tree
-- Returns React Flow-compatible nodes and edges for the invite chain.
-- If p_root_user_id is NULL, returns the full cohort tree.
-- If p_root_user_id is set, returns the subtree rooted at that user.
CREATE OR REPLACE FUNCTION public.admin_get_invite_tree(p_root_user_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rows jsonb;
  v_nodes jsonb;
  v_edges jsonb;
BEGIN
  IF p_root_user_id IS NOT NULL THEN
    -- Subtree rooted at a specific user
    WITH RECURSIVE tree AS (
      SELECT ic.inviter_id, ic.invitee_id
      FROM connect.invite_chains ic
      WHERE ic.inviter_id = p_root_user_id

      UNION ALL

      SELECT ic.inviter_id, ic.invitee_id
      FROM connect.invite_chains ic
      JOIN tree t ON t.invitee_id = ic.inviter_id
    )
    SELECT jsonb_agg(row_to_json(r))
    INTO v_rows
    FROM (
      SELECT DISTINCT
        u.id,
        u.display_name,
        cp.account_standing,
        CASE
          WHEN ep.user_id IS NOT NULL THEN 'empowered'
          WHEN cp.user_id IS NOT NULL THEN 'connected'
          ELSE 'inform'
        END AS tier,
        tree.inviter_id AS parent_id
      FROM tree
      JOIN public.users u ON u.id = tree.invitee_id
      LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
      LEFT JOIN empower.empowered_profiles ep ON ep.user_id = u.id AND ep.is_active = true

      UNION ALL

      SELECT
        u.id,
        u.display_name,
        cp.account_standing,
        CASE
          WHEN ep.user_id IS NOT NULL THEN 'empowered'
          WHEN cp.user_id IS NOT NULL THEN 'connected'
          ELSE 'inform'
        END AS tier,
        NULL::uuid AS parent_id
      FROM public.users u
      LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
      LEFT JOIN empower.empowered_profiles ep ON ep.user_id = u.id AND ep.is_active = true
      WHERE u.id = p_root_user_id
    ) r;
  ELSE
    -- Full cohort tree
    WITH RECURSIVE tree AS (
      SELECT ic.inviter_id, ic.invitee_id
      FROM connect.invite_chains ic

      UNION ALL

      SELECT ic.inviter_id, ic.invitee_id
      FROM connect.invite_chains ic
      JOIN tree t ON t.invitee_id = ic.inviter_id
    )
    SELECT jsonb_agg(row_to_json(r))
    INTO v_rows
    FROM (
      SELECT DISTINCT
        u.id,
        u.display_name,
        cp.account_standing,
        CASE
          WHEN ep.user_id IS NOT NULL THEN 'empowered'
          WHEN cp.user_id IS NOT NULL THEN 'connected'
          ELSE 'inform'
        END AS tier,
        (SELECT inviter_id FROM connect.invite_chains WHERE invitee_id = u.id LIMIT 1) AS parent_id
      FROM (
        SELECT invitee_id AS user_id FROM connect.invite_chains
        UNION
        SELECT inviter_id AS user_id FROM connect.invite_chains
      ) ids
      JOIN public.users u ON u.id = ids.user_id
      LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
      LEFT JOIN empower.empowered_profiles ep ON ep.user_id = u.id AND ep.is_active = true
    ) r;
  END IF;

  -- Build nodes
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', r->>'id',
      'type', 'default',
      'data', jsonb_build_object(
        'label', COALESCE(r->>'display_name', 'Unknown'),
        'tier', r->>'tier',
        'account_standing', r->>'account_standing'
      ),
      'position', jsonb_build_object('x', 0, 'y', 0)
    )
  )
  INTO v_nodes
  FROM jsonb_array_elements(COALESCE(v_rows, '[]'::jsonb)) r;

  -- Build edges (only for rows with a parent_id)
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', (r->>'parent_id') || '-' || (r->>'id'),
      'source', r->>'parent_id',
      'target', r->>'id'
    )
  )
  INTO v_edges
  FROM jsonb_array_elements(COALESCE(v_rows, '[]'::jsonb)) r
  WHERE r->>'parent_id' IS NOT NULL;

  RETURN jsonb_build_object(
    'nodes', COALESCE(v_nodes, '[]'::jsonb),
    'edges', COALESCE(v_edges, '[]'::jsonb)
  );
END;
$$;

-- admin_create_invite
-- Generates an 8-char invite code in XXXX-XXXX format with collision retry.
-- Charset: ABCDEFGHJKLMNPQRSTUVWXYZ23456789 (no O, I, L, 0, 1)
-- Inserts into connect.invite_codes with expires_at = now() + 30 days.
CREATE OR REPLACE FUNCTION public.admin_create_invite(
  p_created_by uuid,
  p_recipient_email text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_charset constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
  v_attempt int := 0;
  v_result jsonb;
  v_row connect.invite_codes;
BEGIN
  WHILE v_attempt < 3 LOOP
    v_attempt := v_attempt + 1;

    -- Generate 8-char code from charset (4-4 format)
    v_code := '';
    FOR i IN 1..8 LOOP
      v_code := v_code || substr(v_charset, (floor(random() * 32))::int + 1, 1);
    END LOOP;
    v_code := substr(v_code, 1, 4) || '-' || substr(v_code, 5, 4);

    BEGIN
      INSERT INTO connect.invite_codes (code, created_by, expires_at)
      VALUES (v_code, p_created_by, now() + interval '30 days')
      RETURNING * INTO v_row;

      v_result := row_to_json(v_row)::jsonb;

      IF p_recipient_email IS NOT NULL THEN
        v_result := v_result || jsonb_build_object('recipient_email', p_recipient_email);
      END IF;

      RETURN v_result;
    EXCEPTION WHEN unique_violation THEN
      -- Collision — retry
      CONTINUE;
    END;
  END LOOP;

  RAISE EXCEPTION 'Failed to generate invite code after 3 collision retries';
END;
$$;

-- admin_list_politicians
-- Returns all politicians (including inactive) with their answer counts.
CREATE OR REPLACE FUNCTION public.admin_list_politicians()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_agg(row_to_json(t))
  INTO v_result
  FROM (
    SELECT
      p.id,
      p.first_name,
      p.last_name,
      p.preferred_name,
      p.full_name,
      p.office_title,
      p.photo_origin_url,
      p.is_active,
      p.created_at,
      COUNT(pa.topic_id)::int AS answer_count
    FROM inform.politicians p
    LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
    GROUP BY p.id
    ORDER BY p.last_name, p.first_name
  ) t;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- admin_update_politician_answers
-- Upserts an array of {topic_id, value} answers for a politician atomically.
-- p_answers: jsonb array of {topic_id: uuid, value: int}
CREATE OR REPLACE FUNCTION public.admin_update_politician_answers(
  p_politician_id uuid,
  p_answers jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_answer jsonb;
BEGIN
  FOR v_answer IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    INSERT INTO inform.politician_answers (politician_id, topic_id, value)
    VALUES (
      p_politician_id,
      (v_answer->>'topic_id')::uuid,
      (v_answer->>'value')::int
    )
    ON CONFLICT (politician_id, topic_id) DO UPDATE
      SET value = EXCLUDED.value;
  END LOOP;
END;
$$;

-- admin_get_cron_log
-- Returns paginated calibration lapse run history.
CREATE OR REPLACE FUNCTION public.admin_get_cron_log(p_page int DEFAULT 1)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_limit constant int := 25;
  v_offset int;
  v_total int;
  v_runs jsonb;
BEGIN
  v_offset := (p_page - 1) * v_limit;

  SELECT COUNT(*)::int INTO v_total FROM public.calibration_lapse_runs;

  SELECT jsonb_agg(row_to_json(t))
  INTO v_runs
  FROM (
    SELECT run_date, started_at, finished_at, users_warned_25, users_warned_30,
           users_demoted, error_message
    FROM public.calibration_lapse_runs
    ORDER BY run_date DESC
    LIMIT v_limit OFFSET v_offset
  ) t;

  RETURN jsonb_build_object(
    'runs', COALESCE(v_runs, '[]'::jsonb),
    'total', v_total
  );
END;
$$;

-- admin_update_topic
-- Updates a compass topic with COALESCE for partial updates.
-- When is_live transitions true→false→true, sets went_live_at if not already set.
-- Raises 'NOT_FOUND' if topic does not exist.
CREATE OR REPLACE FUNCTION public.admin_update_topic(
  p_topic_id uuid,
  p_title text DEFAULT NULL,
  p_short_title text DEFAULT NULL,
  p_question_text text DEFAULT NULL,
  p_is_live boolean DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result inform.compass_topics;
BEGIN
  UPDATE inform.compass_topics
  SET
    title = COALESCE(p_title, title),
    short_title = COALESCE(p_short_title, short_title),
    question_text = COALESCE(p_question_text, question_text),
    is_live = COALESCE(p_is_live, is_live),
    went_live_at = CASE
      WHEN p_is_live = true AND NOT is_live AND went_live_at IS NULL THEN now()
      ELSE went_live_at
    END,
    updated_at = now()
  WHERE id = p_topic_id
  RETURNING * INTO v_result;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND';
  END IF;

  RETURN row_to_json(v_result)::jsonb;
END;
$$;

-- =============================================================================
-- SOCIAL / CONNECT FUNCTIONS
-- =============================================================================

-- claim_invite_code
-- Atomically claims an invite code with FOR UPDATE locking.
-- Prevents double-claim from concurrent requests.
-- Returns { success, error?, inviter_id?, code_id? }
CREATE OR REPLACE FUNCTION public.claim_invite_code(
  p_code text,
  p_claimant_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_row connect.invite_codes;
BEGIN
  -- Lock the row
  SELECT * INTO v_row
  FROM connect.invite_codes
  WHERE code = p_code
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'INVALID_CODE');
  END IF;

  IF v_row.is_claimed THEN
    RETURN jsonb_build_object('success', false, 'error', 'CODE_ALREADY_CLAIMED');
  END IF;

  IF v_row.expires_at IS NOT NULL AND v_row.expires_at < now() THEN
    RETURN jsonb_build_object('success', false, 'error', 'CODE_EXPIRED');
  END IF;

  IF v_row.created_by IS NOT NULL AND v_row.created_by = p_claimant_user_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'SELF_INVITE_BLOCKED');
  END IF;

  -- Mark claimed
  UPDATE connect.invite_codes
  SET is_claimed = true,
      claimed_by = p_claimant_user_id,
      claimed_at = now(),
      updated_at = now()
  WHERE id = v_row.id;

  -- Record invite chain (only for user-created codes, not admin codes)
  IF v_row.created_by IS NOT NULL THEN
    INSERT INTO connect.invite_chains (inviter_id, invitee_id, invite_code_id)
    VALUES (v_row.created_by, p_claimant_user_id, v_row.id);
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'inviter_id', v_row.created_by,
    'code_id', v_row.id
  );
END;
$$;

-- create_invite_codes
-- Batch-creates p_count invite codes for a user with collision retry.
-- Returns array of generated code strings.
CREATE OR REPLACE FUNCTION public.create_invite_codes(p_user_id uuid, p_count int)
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_charset constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_codes text[] := '{}';
  v_code text;
  v_attempt int;
  v_inserted bool;
BEGIN
  FOR i IN 1..p_count LOOP
    v_inserted := false;
    v_attempt := 0;

    WHILE NOT v_inserted AND v_attempt < 3 LOOP
      v_attempt := v_attempt + 1;

      -- Generate code
      v_code := '';
      FOR j IN 1..8 LOOP
        v_code := v_code || substr(v_charset, (floor(random() * 32))::int + 1, 1);
      END LOOP;
      v_code := substr(v_code, 1, 4) || '-' || substr(v_code, 5, 4);

      BEGIN
        INSERT INTO connect.invite_codes (code, created_by, expires_at)
        VALUES (v_code, p_user_id, now() + interval '30 days');

        v_codes := array_append(v_codes, v_code);
        v_inserted := true;
      EXCEPTION WHEN unique_violation THEN
        CONTINUE;
      END;
    END LOOP;

    IF NOT v_inserted THEN
      RAISE EXCEPTION 'Failed to insert invite code after 3 collision retries (slot %)', i;
    END IF;
  END LOOP;

  RETURN v_codes;
END;
$$;

-- block_user
-- Atomically blocks a user: updates or inserts a peer relationship as blocked,
-- then removes all follow relationships between the two users.
CREATE OR REPLACE FUNCTION public.block_user(p_actor_id uuid, p_target_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_existing_id uuid;
BEGIN
  -- Check if any peer relationship exists between the two users (either direction)
  SELECT id INTO v_existing_id
  FROM connect.social_relationships
  WHERE connection_type = 'peer'
    AND ((actor_id = p_actor_id AND target_id = p_target_id)
      OR (actor_id = p_target_id AND target_id = p_actor_id))
  LIMIT 1;

  IF v_existing_id IS NOT NULL THEN
    -- Update existing relationship — blocker becomes actor_id
    UPDATE connect.social_relationships
    SET status = 'blocked', actor_id = p_actor_id, target_id = p_target_id, updated_at = now()
    WHERE id = v_existing_id AND connection_type = 'peer';
  ELSE
    -- Insert new blocked row
    INSERT INTO connect.social_relationships (actor_id, target_id, connection_type, status)
    VALUES (p_actor_id, p_target_id, 'peer', 'blocked')
    ON CONFLICT (actor_id, target_id, connection_type) DO UPDATE
      SET status = 'blocked', updated_at = now();
  END IF;

  -- Remove all follow relationships between the two users (either direction)
  DELETE FROM connect.social_relationships
  WHERE connection_type = 'follow'
    AND ((actor_id = p_actor_id AND target_id = p_target_id)
      OR (actor_id = p_target_id AND target_id = p_actor_id));
END;
$$;

-- follow_user
-- Validates target is an active Empowered account and no block exists,
-- then inserts a follow relationship (idempotent via ON CONFLICT DO NOTHING).
-- Raises 'NOT_EMPOWERED' or 'BLOCKED' exceptions.
CREATE OR REPLACE FUNCTION public.follow_user(p_actor_id uuid, p_target_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Validate target is Empowered
  IF NOT EXISTS (
    SELECT 1 FROM empower.empowered_profiles
    WHERE user_id = p_target_id AND is_active = true
  ) THEN
    RAISE EXCEPTION 'NOT_EMPOWERED';
  END IF;

  -- Check for blocks in either direction
  IF EXISTS (
    SELECT 1 FROM connect.social_relationships
    WHERE connection_type = 'peer' AND status = 'blocked'
      AND ((actor_id = p_actor_id AND target_id = p_target_id)
        OR (actor_id = p_target_id AND target_id = p_actor_id))
  ) THEN
    RAISE EXCEPTION 'BLOCKED';
  END IF;

  -- Insert follow (idempotent)
  INSERT INTO connect.social_relationships (actor_id, target_id, connection_type)
  VALUES (p_actor_id, p_target_id, 'follow')
  ON CONFLICT (actor_id, target_id, connection_type) DO NOTHING;
END;
$$;

-- get_connections
-- Returns the authenticated user's peer connections (pending and accepted).
-- Includes direction (inbound/outbound) for pending requests.
CREATE OR REPLACE FUNCTION public.get_connections(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_agg(row_to_json(t))
  INTO v_result
  FROM (
    SELECT
      sr.id,
      CASE WHEN sr.actor_id = p_user_id THEN sr.target_id ELSE sr.actor_id END AS peer_id,
      up.display_name,
      sr.status,
      CASE WHEN sr.actor_id = p_user_id THEN 'outbound' ELSE 'inbound' END AS direction,
      sr.created_at
    FROM connect.social_relationships sr
    JOIN public.users_public up
      ON up.id = CASE WHEN sr.actor_id = p_user_id THEN sr.target_id ELSE sr.actor_id END
    WHERE sr.connection_type = 'peer'
      AND (sr.actor_id = p_user_id OR sr.target_id = p_user_id)
      AND sr.status IN ('pending', 'accepted')
    ORDER BY sr.updated_at DESC
  ) t;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- get_following
-- Returns the list of Empowered accounts the user is following.
CREATE OR REPLACE FUNCTION public.get_following(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_agg(row_to_json(t))
  INTO v_result
  FROM (
    SELECT sr.id, sr.target_id, up.display_name, sr.created_at
    FROM connect.social_relationships sr
    JOIN public.users_public up ON up.id = sr.target_id
    WHERE sr.actor_id = p_user_id AND sr.connection_type = 'follow'
    ORDER BY sr.created_at DESC
  ) t;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- =============================================================================
-- ROLE FUNCTIONS
-- =============================================================================

-- grant_role
-- Multi-step role grant: fetch role, check active, check tier eligibility,
-- check conflict groups (empty for Alpha), INSERT into user_roles.
-- Raises: ROLE_NOT_FOUND, ROLE_INACTIVE, TIER_INELIGIBLE, ROLE_ALREADY_GRANTED, ROLE_CONFLICT
CREATE OR REPLACE FUNCTION public.grant_role(p_user_id uuid, p_role_slug text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_role_id uuid;
  v_role_required_tier text;
  v_role_is_active bool;
BEGIN
  -- 1. Fetch role by slug
  SELECT id, required_tier, is_active
  INTO v_role_id, v_role_required_tier, v_role_is_active
  FROM public.roles
  WHERE slug = p_role_slug;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ROLE_NOT_FOUND';
  END IF;

  IF NOT v_role_is_active THEN
    RAISE EXCEPTION 'ROLE_INACTIVE';
  END IF;

  -- 2. Enforce tier eligibility
  IF v_role_required_tier = 'empowered' THEN
    IF NOT EXISTS (
      SELECT 1 FROM empower.empowered_profiles
      WHERE user_id = p_user_id AND is_active = true
    ) THEN
      RAISE EXCEPTION 'TIER_INELIGIBLE';
    END IF;
  ELSIF v_role_required_tier = 'connected' THEN
    IF NOT EXISTS (
      SELECT 1 FROM connect.connected_profiles
      WHERE user_id = p_user_id AND verification_status = 'verified'
    ) THEN
      RAISE EXCEPTION 'TIER_INELIGIBLE';
    END IF;
  END IF;

  -- 3. CIVIC-04: Conflict groups (empty for Alpha — skip)
  -- Future: check ROLE_CONFLICT_GROUPS map here

  -- 4. INSERT new row (partial unique index prevents duplicate active grants)
  BEGIN
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES (p_user_id, v_role_id);
  EXCEPTION WHEN unique_violation THEN
    RAISE EXCEPTION 'ROLE_ALREADY_GRANTED';
  END;
END;
$$;

-- revoke_role
-- Soft-revokes a role by setting revoked_at on the active grant row.
-- Idempotent — no error if no matching active grant exists.
CREATE OR REPLACE FUNCTION public.revoke_role(p_user_id uuid, p_role_slug text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.user_roles ur
  SET revoked_at = now()
  FROM public.roles r
  WHERE ur.role_id = r.id
    AND ur.user_id = p_user_id
    AND r.slug = p_role_slug
    AND ur.revoked_at IS NULL;
END;
$$;

-- get_user_roles
-- Returns all active (non-revoked) roles for a user.
CREATE OR REPLACE FUNCTION public.get_user_roles(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_agg(row_to_json(t))
  INTO v_result
  FROM (
    SELECT ur.role_id, r.slug, r.name, ur.granted_at
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = p_user_id AND ur.revoked_at IS NULL
    ORDER BY ur.granted_at DESC
  ) t;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- =============================================================================
-- COMPASS FUNCTIONS
-- =============================================================================

-- promote_compass_import_draft
-- Moves Phase 3 calibration data from verification_sessions.compass_import_draft
-- into inform.compass_responses (ON CONFLICT DO NOTHING — never overwrites manual entries).
-- Also inserts compass_change_history records for newly inserted rows.
-- Clears the draft after successful promotion.
-- Non-fatal: errors are swallowed (caller should not surface to user).
CREATE OR REPLACE FUNCTION public.promote_compass_import_draft(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_draft jsonb;
  v_cal jsonb;
  v_stance_value int;
  v_rows_inserted int;
BEGIN
  SELECT compass_import_draft INTO v_draft
  FROM connect.verification_sessions
  WHERE user_id = p_user_id;

  -- Exit early if no draft
  IF v_draft IS NULL OR jsonb_array_length(v_draft) = 0 THEN
    RETURN;
  END IF;

  BEGIN
    FOR v_cal IN SELECT * FROM jsonb_array_elements(v_draft)
    LOOP
      -- Resolve stance_id → value
      SELECT value INTO v_stance_value
      FROM inform.compass_stances
      WHERE id = (v_cal->>'stance_id')::uuid
        AND topic_id = (v_cal->>'topic_id')::uuid;

      IF NOT FOUND THEN
        CONTINUE; -- Stance removed or topic changed — skip silently
      END IF;

      -- Upsert — DO NOTHING if user has already manually calibrated this topic
      INSERT INTO inform.compass_responses (user_id, topic_id, value, inverted)
      VALUES (
        p_user_id,
        (v_cal->>'topic_id')::uuid,
        v_stance_value,
        COALESCE((v_cal->>'inverted')::boolean, false)
      )
      ON CONFLICT (user_id, topic_id) DO NOTHING;

      GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;

      -- Only create history when INSERT actually wrote a row
      IF v_rows_inserted > 0 THEN
        INSERT INTO inform.compass_change_history (user_id, topic_id, old_value, new_value)
        VALUES (p_user_id, (v_cal->>'topic_id')::uuid, NULL, v_stance_value);
      END IF;
    END LOOP;

    -- Clear draft after successful promotion
    UPDATE connect.verification_sessions
    SET compass_import_draft = NULL, updated_at = now()
    WHERE user_id = p_user_id;

  EXCEPTION WHEN OTHERS THEN
    -- Non-fatal: draft preserved for retry on next GET /compass/answers
    RAISE WARNING '[promote_compass_import_draft] error for user %: %', p_user_id, SQLERRM;
  END;
END;
$$;

-- get_compass_completeness
-- Calculates how many live topics a user has answered, optionally filtered
-- by role scope (compass_topic_roles.is_required = true for that scope).
-- Returns { required, answered, percent, complete }
CREATE OR REPLACE FUNCTION public.get_compass_completeness(
  p_user_id uuid,
  p_role_scope text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_topic_ids uuid[];
  v_required int;
  v_answered int;
  v_percent int;
BEGIN
  IF p_role_scope IS NOT NULL THEN
    SELECT array_agg(ct.id) INTO v_topic_ids
    FROM inform.compass_topics ct
    JOIN inform.compass_topic_roles ctr ON ctr.topic_id = ct.id
    WHERE ct.is_live = true
      AND ctr.role_scope = p_role_scope
      AND ctr.is_required = true;
  ELSE
    SELECT array_agg(id) INTO v_topic_ids
    FROM inform.compass_topics
    WHERE is_live = true;
  END IF;

  v_required := COALESCE(array_length(v_topic_ids, 1), 0);

  IF v_required = 0 THEN
    RETURN jsonb_build_object('required', 0, 'answered', 0, 'percent', 100, 'complete', true);
  END IF;

  SELECT COUNT(*)::int INTO v_answered
  FROM inform.compass_responses
  WHERE user_id = p_user_id AND topic_id = ANY(v_topic_ids);

  v_percent := ROUND((v_answered::numeric / v_required) * 100);

  RETURN jsonb_build_object(
    'required', v_required,
    'answered', v_answered,
    'percent', v_percent,
    'complete', v_answered >= v_required
  );
END;
$$;

-- =============================================================================
-- EMPOWER FUNCTIONS
-- =============================================================================

-- run_empower_preflight
-- Validates all empowerment conditions and returns structured result.
-- Slug generation stays in TypeScript (uses crypto.randomUUID).
-- Returns { eligible, failures?, demotion_context?, connected_profile? }
CREATE OR REPLACE FUNCTION public.run_empower_preflight(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_connected jsonb;
  v_empowered jsonb;
  v_failures jsonb := '[]'::jsonb;
  v_is_demoted bool := false;
  v_demotion_context jsonb;
  v_candidate_role text;
  v_verification_status text;
  v_legal_name text;
  v_completeness jsonb;
BEGIN
  -- 1. Fetch connected profile
  SELECT row_to_json(t) INTO v_connected
  FROM (
    SELECT id, verification_status, legal_name, candidate_role
    FROM connect.connected_profiles WHERE user_id = p_user_id
  ) t;

  IF v_connected IS NULL THEN
    RAISE EXCEPTION 'No connected profile found for user';
  END IF;

  v_verification_status := v_connected->>'verification_status';
  v_legal_name := v_connected->>'legal_name';
  v_candidate_role := v_connected->>'candidate_role';

  -- 2. Fetch existing empowered profile (including demoted)
  SELECT row_to_json(t) INTO v_empowered
  FROM (
    SELECT id, is_active, demoted_at, demotion_reason, candidate_page_slug
    FROM empower.empowered_profiles WHERE user_id = p_user_id
  ) t;

  -- 3. Check for demotion context
  IF v_empowered IS NOT NULL AND NOT (v_empowered->>'is_active')::bool THEN
    v_is_demoted := true;
    v_demotion_context := jsonb_build_object(
      'previously_demoted', true,
      'demoted_at', v_empowered->>'demoted_at',
      'demotion_reason', v_empowered->'demotion_reason'
    );
  END IF;

  -- 4. Collect failures
  IF v_verification_status != 'verified' THEN
    v_failures := v_failures || jsonb_build_array(
      jsonb_build_object('code', 'NOT_VERIFIED', 'message', 'Connected account must be verified')
    );
  END IF;

  IF v_candidate_role IS NULL THEN
    v_failures := v_failures || jsonb_build_array(
      jsonb_build_object('code', 'ROLE_NOT_SET', 'message', 'Candidate role must be set before empowerment')
    );
  END IF;

  IF v_legal_name IS NULL THEN
    v_failures := v_failures || jsonb_build_array(
      jsonb_build_object('code', 'LEGAL_NAME_MISSING', 'message', 'Legal name is required for empowerment')
    );
  END IF;

  -- Check compass completeness if we have a role
  IF v_candidate_role IS NOT NULL THEN
    v_completeness := public.get_compass_completeness(p_user_id, v_candidate_role);
    IF NOT (v_completeness->>'complete')::bool THEN
      v_failures := v_failures || jsonb_build_array(
        jsonb_build_object(
          'code', 'CALIBRATION_INCOMPLETE',
          'message', 'Compass calibration is not complete for your role',
          'threshold', (v_completeness->>'required')::int,
          'current', (v_completeness->>'answered')::int
        )
      );
    END IF;
  END IF;

  -- 5. Return result
  IF jsonb_array_length(v_failures) > 0 THEN
    RETURN jsonb_build_object(
      'eligible', false,
      'failures', v_failures,
      'demotion_context', v_demotion_context,
      'connected_profile', v_connected
    );
  END IF;

  RETURN jsonb_build_object(
    'eligible', true,
    'connected_profile', v_connected,
    'empowered_profile', v_empowered,
    'compass_completeness', v_completeness,
    'demotion_context', v_demotion_context,
    'is_demoted', v_is_demoted
  );
END;
$$;

-- =============================================================================
-- NOTIFICATION / CRON FUNCTIONS
-- =============================================================================

-- insert_notification
-- Simple INSERT into public.notifications.
CREATE OR REPLACE FUNCTION public.insert_notification(
  p_user_id uuid,
  p_type text,
  p_payload jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.notifications (user_id, type, payload)
  VALUES (p_user_id, p_type, p_payload);
END;
$$;

-- cron_upsert_lapse_run
-- Inserts today's run row ON CONFLICT DO NOTHING.
-- Returns true if inserted (first run today), false if already ran.
CREATE OR REPLACE FUNCTION public.cron_upsert_lapse_run(p_run_date date)
RETURNS bool
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.calibration_lapse_runs (run_date)
  VALUES (p_run_date)
  ON CONFLICT (run_date) DO NOTHING;

  RETURN FOUND;
END;
$$;

-- cron_update_lapse_run
-- Updates the calibration_lapse_runs row with final stats after job completes.
CREATE OR REPLACE FUNCTION public.cron_update_lapse_run(
  p_run_date date,
  p_warned_25 int,
  p_warned_30 int,
  p_demoted int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.calibration_lapse_runs
  SET finished_at = now(),
      users_warned_25 = p_warned_25,
      users_warned_30 = p_warned_30,
      users_demoted = p_demoted
  WHERE run_date = p_run_date;
END;
$$;

-- cron_record_lapse_error
-- Records an error message on the calibration_lapse_runs row.
CREATE OR REPLACE FUNCTION public.cron_record_lapse_error(p_run_date date, p_error text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.calibration_lapse_runs
  SET error_message = p_error
  WHERE run_date = p_run_date;
END;
$$;

-- =============================================================================
-- CONNECT FLOW FUNCTIONS
-- =============================================================================

-- complete_connect_flow
-- Atomically completes the Connect verification flow for a user.
-- Validates session state, prevents duplicate connected_profiles, creates the
-- connected_profiles record, advances session to 'complete', and syncs
-- display_name to public.users.
-- Raises: 'NO_SESSION', 'INCOMPLETE_SESSION', 'MISSING_REQUIRED_FIELDS', 'ALREADY_CONNECTED'
CREATE OR REPLACE FUNCTION public.complete_connect_flow(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_session connect.verification_sessions;
BEGIN
  -- Lock the verification_session row for this transaction
  SELECT * INTO v_session
  FROM connect.verification_sessions
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SESSION';
  END IF;

  IF v_session.step_reached != 'review' THEN
    RAISE EXCEPTION 'INCOMPLETE_SESSION';
  END IF;

  IF v_session.display_name_draft IS NULL
     OR v_session.legal_name_draft IS NULL
     OR v_session.region_draft IS NULL
     OR v_session.home_address_draft IS NULL
  THEN
    RAISE EXCEPTION 'MISSING_REQUIRED_FIELDS';
  END IF;

  -- Idempotency check
  IF EXISTS (SELECT 1 FROM connect.connected_profiles WHERE user_id = p_user_id) THEN
    RAISE EXCEPTION 'ALREADY_CONNECTED';
  END IF;

  -- Create connected_profiles record
  INSERT INTO connect.connected_profiles
    (user_id, display_name, legal_name, home_address, account_standing, verification_status, tolerance_rating, verified_region)
  VALUES
    (p_user_id, v_session.display_name_draft, v_session.legal_name_draft,
     v_session.home_address_draft, 'active', 'verified', 10.00, v_session.region_draft);

  -- Advance session to complete
  UPDATE connect.verification_sessions
  SET step_reached = 'complete', updated_at = now()
  WHERE user_id = p_user_id;

  -- Sync display_name to public.users
  UPDATE public.users
  SET display_name = v_session.display_name_draft, updated_at = now()
  WHERE id = p_user_id;

  RETURN jsonb_build_object(
    'connected', true,
    'verification_status', 'verified',
    'tier', 'connected'
  );
END;
$$;

-- upsert_compass_answer
-- Atomically upserts a compass response and appends to change_history.
-- Validates topic exists and is live before writing.
-- change_history record is ALWAYS inserted (full audit log).
-- Raises 'TOPIC_NOT_FOUND' if topic is missing or not live.
CREATE OR REPLACE FUNCTION public.upsert_compass_answer(
  p_user_id uuid,
  p_topic_id uuid,
  p_value int,
  p_write_in_text text DEFAULT NULL,
  p_inverted boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_old_value int;
  v_result inform.compass_responses;
BEGIN
  -- Validate topic exists and is live
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_topics WHERE id = p_topic_id AND is_live = true
  ) THEN
    RAISE EXCEPTION 'TOPIC_NOT_FOUND';
  END IF;

  -- Capture old value for change_history (NULL on first calibration)
  SELECT value INTO v_old_value
  FROM inform.compass_responses
  WHERE user_id = p_user_id AND topic_id = p_topic_id;

  -- UPSERT the response
  INSERT INTO inform.compass_responses (user_id, topic_id, value, write_in_text, inverted, updated_at)
  VALUES (p_user_id, p_topic_id, p_value, p_write_in_text, p_inverted, now())
  ON CONFLICT (user_id, topic_id) DO UPDATE
    SET value         = EXCLUDED.value,
        write_in_text = EXCLUDED.write_in_text,
        inverted      = EXCLUDED.inverted,
        updated_at    = now()
  RETURNING * INTO v_result;

  -- Append to change_history (always — even same-value recalibration)
  INSERT INTO inform.compass_change_history (user_id, topic_id, old_value, new_value)
  VALUES (p_user_id, p_topic_id, v_old_value, p_value);

  RETURN row_to_json(v_result)::jsonb;
END;
$$;
