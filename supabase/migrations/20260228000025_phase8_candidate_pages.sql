BEGIN;

-- Migration 025: Phase 8 — Public Candidate Pages
--
-- Adds jurisdiction fields and photo_origin_url to empower.empowered_profiles
-- so that candidate pages can display a civic leader's office, district, and
-- government context without joining the inform.politicians table.
--
-- Also adds:
--   - Partial index on representing_zip for the Essentials ZIP lookup endpoint
--     (GET /api/candidates/essentials?zip=XXXXX filters active candidates by ZIP)
--   - Named UNIQUE constraint on candidate_page_slug so the Phase 8 service layer
--     can reference it by name (migration 006 created an anonymous inline UNIQUE)
--
-- NO RLS changes are needed:
--   - The existing "public read active" policy (migration 009) hides inactive rows
--     from non-owners. The service layer uses supabaseAdmin to bypass RLS when
--     the slug endpoint must return inactive candidates.
--   - The existing "owner read own" policy covers full row access for the profile owner.

-- -------------------------------------------------------------------------
-- New columns on empower.empowered_profiles
-- -------------------------------------------------------------------------

-- Jurisdiction fields (all nullable TEXT — not all candidates fill every field)
ALTER TABLE empower.empowered_profiles
  ADD COLUMN IF NOT EXISTS representing_city    TEXT,
  ADD COLUMN IF NOT EXISTS representing_state   TEXT,
  ADD COLUMN IF NOT EXISTS representing_zip     TEXT,   -- TEXT not INTEGER: leading zeros (e.g., "01234")
  ADD COLUMN IF NOT EXISTS district_type        TEXT,   -- e.g., 'city_council', 'congressional'
  ADD COLUMN IF NOT EXISTS district_id          TEXT,   -- opaque identifier
  ADD COLUMN IF NOT EXISTS government_name      TEXT,   -- e.g., 'City of Austin'
  ADD COLUMN IF NOT EXISTS chamber_name         TEXT,   -- e.g., 'City Council'
  ADD COLUMN IF NOT EXISTS chamber_name_formal  TEXT;   -- e.g., 'Austin City Council'

-- Photo URL (nullable; column does not exist on empowered_profiles in migration 006)
ALTER TABLE empower.empowered_profiles
  ADD COLUMN IF NOT EXISTS photo_origin_url TEXT;

-- -------------------------------------------------------------------------
-- Partial index: representing_zip for the Essentials ZIP lookup
--
-- Only indexes active candidates with a ZIP — keeps the index small and
-- aligns with the query filter: WHERE is_active = true AND representing_zip = $1
-- -------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_empowered_profiles_zip
  ON empower.empowered_profiles(representing_zip)
  WHERE representing_zip IS NOT NULL AND is_active = true;

-- -------------------------------------------------------------------------
-- Named UNIQUE constraint on candidate_page_slug
--
-- Migration 006 defined candidate_page_slug as TEXT UNIQUE (inline), which
-- Postgres auto-names as something like empowered_profiles_candidate_page_slug_key.
-- Adding a named constraint gives the service layer a stable reference name.
-- The exception-safe block is idempotent: no-ops if the constraint already exists.
-- -------------------------------------------------------------------------

DO $$ BEGIN
  ALTER TABLE empower.empowered_profiles
    ADD CONSTRAINT empowered_profiles_candidate_page_slug_unique
    UNIQUE (candidate_page_slug);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

COMMIT;
