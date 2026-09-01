-- Persist the city, state and nation geoids that CC_0038 taught
-- connect.resolve_user_jurisdiction to return.
--
-- These are geoids, and they are NOT the same thing as the columns that sound like them:
--   jurisdiction_state  is a 2-letter USPS code from geocoding ('NC')
--   jurisdiction_city   is a human place name from geocoding ('ASHEVILLE')
--   state_geo_id        is a 2-digit state FIPS ('37')
--   city_geo_id         is a 7-digit place FIPS ('3702140'), null when unincorporated
-- Both pairs stay. The geocoded pair labels an address; the geoid pair addresses a
-- boundary, and only the geoid pair can key a Civic Spaces slice.
--
-- nation_geo_id is constant 'US' today. It is stored rather than derived so the slice
-- assigner reads all five levels through one uniform shape.

ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS city_geo_id   text,
  ADD COLUMN IF NOT EXISTS state_geo_id  text,
  ADD COLUMN IF NOT EXISTS nation_geo_id text;

COMMENT ON COLUMN connect.connected_profiles.city_geo_id IS
  '7-digit Census place FIPS (mtfcc G4110). NULL for unincorporated addresses -- that is a valid answer, not a failure. Not jurisdiction_city, which is a geocoded place NAME.';
COMMENT ON COLUMN connect.connected_profiles.state_geo_id IS
  '2-digit Census state FIPS (mtfcc G4000). Not jurisdiction_state, which is a 2-letter USPS code.';
COMMENT ON COLUMN connect.connected_profiles.nation_geo_id IS
  'Always ''US'' today. Stored so the Civic Spaces slice assigner reads all five levels through one shape.';

DO $verify$
DECLARE v_missing text;
BEGIN
  SELECT string_agg(c, ', ') INTO v_missing
  FROM unnest(ARRAY['city_geo_id', 'state_geo_id', 'nation_geo_id']) AS c
  WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'connect'
       AND table_name = 'connected_profiles'
       AND column_name = c
  );

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'connected_profiles is missing: %', v_missing;
  END IF;
END $verify$;

-- Back-fill every profile that already has a location.
--
-- Without this the columns are NULL until the member next changes their address, and
-- the Civic Spaces slice assigner reads them through /api/account/me: it would see three
-- nulls, skip the city/state/nation levels, and seat everyone in Unified alone. That is
-- the failure the taxonomy plan's deploy gate exists to prevent, and it would have been
-- reached by shipping this migration without the loop below.
--
-- Idempotent: only rows that have not been filled yet are touched, so a re-run is a
-- no-op rather than a second write.
DO $backfill$
DECLARE
  r record;
  j jsonb;
  n integer := 0;
BEGIN
  FOR r IN
    SELECT user_id FROM connect.connected_profiles
     WHERE encrypted_lat IS NOT NULL
       AND location_consent = true
       AND deleted_at IS NULL
       AND nation_geo_id IS NULL
  LOOP
    BEGIN
      j := connect.resolve_user_jurisdiction(r.user_id);
    EXCEPTION WHEN OTHERS THEN
      -- One unresolvable profile must not abort the other nine.
      RAISE WARNING 'skipped %: %', r.user_id, SQLERRM;
      CONTINUE;
    END;

    UPDATE connect.connected_profiles
       SET city_geo_id   = j ->> 'city',
           state_geo_id  = j ->> 'state',
           nation_geo_id = j ->> 'nation',
           updated_at    = now()
     WHERE user_id = r.user_id;
    n := n + 1;
  END LOOP;

  RAISE NOTICE 'back-filled % profile(s)', n;
END $backfill$;

DO $verify$
DECLARE v_unfilled integer;
BEGIN
  -- Every profile with a consented location sits inside the US today, so every one of
  -- them must now name a nation. A row left NULL means the RPC could not resolve the
  -- point at all -- which is a real answer for a point outside the US, and a bug for
  -- any address we actually hold.
  SELECT COUNT(*) INTO v_unfilled
    FROM connect.connected_profiles
   WHERE encrypted_lat IS NOT NULL
     AND location_consent = true
     AND deleted_at IS NULL
     AND nation_geo_id IS NULL;

  IF v_unfilled > 0 THEN
    RAISE EXCEPTION 'back-fill left % profile(s) with no nation_geo_id', v_unfilled;
  END IF;
END $verify$;
