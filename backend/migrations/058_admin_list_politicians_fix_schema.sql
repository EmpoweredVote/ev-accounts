-- =============================================================================
-- Migration 058: Fix admin_list_politicians to read from essentials.politicians
--
-- The RPC was originally written against inform.politicians, a 2-record stub
-- created during early development. The real politician data (2,577+ rows) lives
-- in essentials.politicians. The GrantRoleModal campaign_manager picker was
-- therefore showing only 2 choices.
--
-- Changes:
--   1. Rewrite admin_list_politicians() to SELECT from essentials.politicians
--      with a LEFT JOIN to essentials.offices for office title / location.
--   2. Preserve the exact return column names and types for API compatibility.
--      Fields not available in essentials are returned as NULL.
--   3. Filter to is_active = true to exclude historical/inactive records.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.admin_list_politicians()
RETURNS TABLE(
  id                  uuid,
  first_name          text,
  last_name           text,
  preferred_name      text,
  full_name           text,
  office_title        text,
  photo_origin_url    text,
  is_active           boolean,
  is_candidate        boolean,
  is_vacant           boolean,
  representing_city   text,
  representing_state  text,
  district_type       text,
  district_label      text,
  district_id         text,
  chamber_name        text,
  chamber_name_formal text,
  government_name     text,
  created_at          timestamptz,
  answer_count        bigint
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT DISTINCT ON (p.id)
    p.id,
    p.first_name,
    p.last_name,
    p.preferred_name,
    p.full_name,
    o.title                     AS office_title,
    p.photo_origin_url,
    p.is_active,
    false                       AS is_candidate,   -- not tracked in essentials schema
    p.is_vacant,
    o.representing_city,
    o.representing_state,
    NULL::text                  AS district_type,  -- available via district join if needed
    NULL::text                  AS district_label,
    NULL::text                  AS district_id,
    NULL::text                  AS chamber_name,
    NULL::text                  AS chamber_name_formal,
    NULL::text                  AS government_name,
    NULL::timestamptz           AS created_at,
    (
      SELECT COUNT(*)
      FROM inform.politician_answers pa
      WHERE pa.politician_id = p.id
    )                           AS answer_count
  FROM essentials.politicians p
  LEFT JOIN essentials.offices o ON o.politician_id = p.id
  WHERE p.is_active = true
  ORDER BY p.id, o.id
$$;
