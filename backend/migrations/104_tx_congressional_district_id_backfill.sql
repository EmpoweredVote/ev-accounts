-- Migration 104: Backfill district_id on TX NATIONAL_LOWER districts.
--
-- The load-us-congressional-boundaries.ts script populates geo_id/ocd_id/label/
-- district_type/state/mtfcc but leaves district_id NULL. Migration 054-style
-- election linking (and the politician migration in 19-03) expect district_id
-- to be the un-padded numeric string ('3' for TX-3, '23' for TX-23, etc.).
--
-- LTRIM(SUBSTRING(geo_id FROM 3), '0') strips the leading '48' state FIPS
-- prefix then strips leading zeros: '4803' → '3', '4823' → '23', '4838' → '38'.
--
-- Idempotent: only updates rows where district_id IS NULL or empty.

UPDATE essentials.districts
SET district_id = LTRIM(SUBSTRING(geo_id FROM 3), '0')
WHERE state = 'TX'
  AND district_type = 'NATIONAL_LOWER'
  AND (district_id IS NULL OR district_id = '');
