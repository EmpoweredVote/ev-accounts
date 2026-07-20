-- Migration 1377: GIN trigram indexes for the place-name resolver (Phase 212, Plan 01)
--
-- STRUCTURAL migration authored here; applied live in Plan 03 (this plan authors SQL only).
--
-- Purpose: Back the new GET /essentials/location-search resolver query
-- (locationSearchService.ts, Phase 212 Plan 02) with GIN trigram indexes on the two
-- existing "curated" name columns it searches: essentials.governments.name and
-- essentials.geofence_boundaries.name. Mirrors migration 040_pg_trgm_search.sql's
-- index idiom EXACTLY (public.f_unaccent(lower(name)) extensions.gin_trgm_ops).
--
-- CRITICAL: pg_trgm + unaccent extensions and the public.f_unaccent() IMMUTABLE wrapper
-- are already live since migration 040 — this migration does NOT re-create them.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id (see migration
-- 1288 note) — this index is on `name` only and does not affect that constraint gap.
-- IF NOT EXISTS guards make this idempotent — safe to re-run.

CREATE INDEX IF NOT EXISTS idx_governments_name_trgm
  ON essentials.governments
  USING GIN (public.f_unaccent(lower(name)) extensions.gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_geofence_boundaries_name_trgm
  ON essentials.geofence_boundaries
  USING GIN (public.f_unaccent(lower(name)) extensions.gin_trgm_ops);
