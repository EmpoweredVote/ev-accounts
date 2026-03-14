-- =============================================================================
-- Migration 033: Politician schema — new columns + admin_list_politicians RPC update
--
-- Adds 9 new columns to inform.politicians to carry the full field set required
-- by Essentials and Validation Quests (district, jurisdiction, vacancy):
--
--   representing_city      TEXT    nullable  — city/town the politician represents
--   representing_state     TEXT    nullable  — state abbreviation (e.g. "IN", "CA")
--   district_type          TEXT    nullable  — e.g. "congressional", "state_senate"
--   district_label         TEXT    nullable  — human-readable label, e.g. "IN-05"
--   district_id            TEXT    nullable  — TIGER/Line or OCD district identifier
--   chamber_name           TEXT    nullable  — e.g. "House", "Senate"
--   chamber_name_formal    TEXT    nullable  — e.g. "U.S. House of Representatives"
--   government_name        TEXT    nullable  — e.g. "U.S. Federal Government"
--   is_vacant              BOOLEAN NOT NULL DEFAULT false — seat vacancy flag
--
-- All ADD COLUMN statements use IF NOT EXISTS for idempotency (safe to re-run).
--
-- The admin_list_politicians() RPC RETURNS TABLE signature is extended to include
-- all 9 new columns. Because the return type changes, CREATE OR REPLACE alone
-- would raise ERROR: cannot change return type of existing function. Therefore:
--   1. DROP FUNCTION IF EXISTS public.admin_list_politicians()  ← required
--   2. CREATE OR REPLACE FUNCTION public.admin_list_politicians() ← new signature
--
-- This matches the pattern documented in 17-03-SUMMARY.md Issue 4 and used
-- consistently across migrations that modify RPC return shapes.
--
-- All table references in the function body are fully qualified (schema.table).
-- SECURITY DEFINER with SET search_path = '' prevents search_path injection.
-- =============================================================================

BEGIN;

-- =============================================================================
-- Step 1: Add 9 new columns to inform.politicians
-- =============================================================================

ALTER TABLE inform.politicians
  ADD COLUMN IF NOT EXISTS representing_city   TEXT,
  ADD COLUMN IF NOT EXISTS representing_state  TEXT,
  ADD COLUMN IF NOT EXISTS district_type       TEXT,
  ADD COLUMN IF NOT EXISTS district_label      TEXT,
  ADD COLUMN IF NOT EXISTS district_id         TEXT,
  ADD COLUMN IF NOT EXISTS chamber_name        TEXT,
  ADD COLUMN IF NOT EXISTS chamber_name_formal TEXT,
  ADD COLUMN IF NOT EXISTS government_name     TEXT,
  ADD COLUMN IF NOT EXISTS is_vacant           BOOLEAN NOT NULL DEFAULT false;


-- =============================================================================
-- Step 2: Drop the existing admin_list_politicians() function
--
-- Required because the RETURNS TABLE signature is changing (new columns added).
-- CREATE OR REPLACE cannot change the return type of an existing function.
-- =============================================================================

DROP FUNCTION IF EXISTS public.admin_list_politicians();


-- =============================================================================
-- Step 3: Recreate admin_list_politicians() with the full column set
--
-- Returns one row per politician ordered by last_name, first_name.
-- answer_count is a correlated subquery counting rows in politician_answers.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.admin_list_politicians()
RETURNS TABLE(
  id                   uuid,
  first_name           text,
  last_name            text,
  preferred_name       text,
  full_name            text,
  office_title         text,
  photo_origin_url     text,
  is_active            boolean,
  is_candidate         boolean,
  is_vacant            boolean,
  representing_city    text,
  representing_state   text,
  district_type        text,
  district_label       text,
  district_id          text,
  chamber_name         text,
  chamber_name_formal  text,
  government_name      text,
  created_at           timestamptz,
  answer_count         bigint
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
    p.office_title,
    p.photo_origin_url,
    p.is_active,
    p.is_candidate,
    p.is_vacant,
    p.representing_city,
    p.representing_state,
    p.district_type,
    p.district_label,
    p.district_id,
    p.chamber_name,
    p.chamber_name_formal,
    p.government_name,
    p.created_at,
    (SELECT COUNT(*) FROM inform.politician_answers pa WHERE pa.politician_id = p.id) AS answer_count
  FROM inform.politicians p
  ORDER BY p.last_name, p.first_name;
$$;


-- =============================================================================
-- Step 4: Grant execute permissions
-- =============================================================================

GRANT EXECUTE ON FUNCTION public.admin_list_politicians() TO service_role, authenticated;

COMMIT;
