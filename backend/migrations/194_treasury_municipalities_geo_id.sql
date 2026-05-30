-- 194: Add geo_id to treasury.municipalities so budget data links to the same
-- TIGER geofence backbone that essentials uses (essentials.geofence_boundaries /
-- essentials.districts both key on geo_id: G4110 places, G4020 counties,
-- G5420 school districts).
--
-- WHY: treasury.municipalities previously had NO geo_id/ocd_id — coverageService
-- matched treasury budgets to coverage jurisdictions by a fuzzy name+state slug.
-- A real TIGER geo_id lets coverage join exactly and survives future data pulls.
--
-- NON-BREAKING: additive + nullable. No existing column changes, no treasury
-- read path touched. geo_id is populated by:
--   • scripts/backfill-treasury-geo-id.ts (existing rows), and
--   • the budget importers at insert time (resolveTreasuryGeoId in treasuryService.ts).
-- Rows that don't map to a TIGER geofence (townships, libraries, special/nonprofit)
-- legitimately stay NULL.
--
-- Forward-only; idempotent via IF NOT EXISTS.

ALTER TABLE treasury.municipalities
  ADD COLUMN IF NOT EXISTS geo_id text;

-- geo_id is the join key into essentials.geofence_boundaries(geo_id) — index it.
CREATE INDEX IF NOT EXISTS idx_treasury_municipalities_geo_id
  ON treasury.municipalities (geo_id);
