-- Migration 1378: Nationwide Census Gazetteer reference tables (Phase 212, Plan 01)
--
-- STRUCTURAL migration authored here; applied live in Plan 03 (this plan authors SQL only).
--
-- Purpose: essentials.gazetteer_places + essentials.gazetteer_counties are the canonical
-- nationwide place-name reference tables for the place-name resolver's Gazetteer-fallback
-- branch (RSLV-02/D-08). This is the column-set CONTRACT that the Phase 212 Plan 02 ingest
-- script (backend/scripts/ingest-gazetteer-places-counties.ts) writes to — do not alter the
-- column set without updating that script in lockstep.
--
-- Amended D-06 (2026-07-20 planning decision): these tables intentionally carry NO
-- population column. The resolver's tertiary ranking tiebreak is name A->Z (alphabetical),
-- not population — the Census Gazetteer Places/Counties files ship no population column,
-- and sourcing a separate population dataset was judged disproportionate for a rare
-- tertiary tiebreak. Do NOT add a population column without a corresponding decision reversal.
--
-- `state` columns hold the Gazetteer USPS 2-letter abbreviation (uppercase), matching the
-- Gazetteer file's own USPS column — NOT the lowercase 'az'-style convention used by
-- essentials.districts for LOCAL/COUNTY/STATE_* district rows (see migration 1288 note).
--
-- IF NOT EXISTS guards make this idempotent — safe to re-run.

CREATE TABLE IF NOT EXISTS essentials.gazetteer_places (
  geo_id       text PRIMARY KEY,
  name         text NOT NULL,
  state        text NOT NULL,
  lsad         text,
  aland_sqmi   numeric,
  intptlat     double precision,
  intptlong    double precision
);

CREATE TABLE IF NOT EXISTS essentials.gazetteer_counties (
  geo_id       text PRIMARY KEY,
  name         text NOT NULL,
  state        text NOT NULL,
  aland_sqmi   numeric,
  intptlat     double precision,
  intptlong    double precision
);

CREATE INDEX IF NOT EXISTS idx_gazetteer_places_name_trgm
  ON essentials.gazetteer_places
  USING GIN (public.f_unaccent(lower(name)) extensions.gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_gazetteer_counties_name_trgm
  ON essentials.gazetteer_counties
  USING GIN (public.f_unaccent(lower(name)) extensions.gin_trgm_ops);
