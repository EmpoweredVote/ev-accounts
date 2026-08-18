-- 1826_dc_shadow_senator_district.sql
--
-- DC's two U.S. Shadow Senators sat on the HOUSE DELEGATE's district.
--
-- Paul Strauss (Senior) and Ankit Jain (Junior) both pointed at district
-- fced59e7-cb65-46b1-aaf1-f99ce90e5441 -- "Delegate District (at Large)",
-- district_type NATIONAL_LOWER, ocd .../cd:98, geo_id 1198 -- which is Eleanor Holmes
-- Norton's seat. Three officeholders, one district row, two different offices.
--
-- HOW IT SURFACED: a headshot pass matched members of Congress on state + district and
-- resolved all three DC rows to Norton, i.e. it was one weaker guard away from putting
-- her face on both shadow senators. The name guard refused; the district stayed wrong.
--
-- WHY IT MATTERS BEYOND PHOTOS: any join that reasons "who represents this district"
-- now conflates a voting-eligible-by-geography House delegate seat with two Senate-side
-- advocacy posts. ADR 0003 gave us the axes to say this correctly and they were simply
-- pointed at the wrong row.
--
-- THE SHAPE, copied from how real Senate seats are already modelled (MD/VA/CA):
-- NATIONAL_UPPER, one statewide district per state carrying BOTH seats, label = the
-- jurisdiction name, geo_id = state FIPS, ocd = .../state:xx with no /cd: segment,
-- representation_basis = 'residency', government_id = the jurisdiction's government.
-- DC had no NATIONAL_UPPER district at all (there are exactly 50, one per state).
--
-- residency, not membership: these two are elected by DC voters at large, so the seat
-- IS inferable from an address and MUST carry a geo_id (ADR 0003 reserves 'membership'
-- for enrollment-based seats such as Maine's tribal representatives, which must NOT).
-- geo_id '11' is DC's FIPS, already present in geofence_boundaries and not used by any
-- district row, so this collides with nothing and is reachable by point-in-polygon.
--
-- The offices keep voting_powers='non_voting' and their representation_note -- nothing
-- about their powers changes here, only which district they hang from.

BEGIN;

-- 1. The DC statewide Senate-side district.
INSERT INTO essentials.districts
  (id, ocd_id, label, district_type, district_id, state, geo_id,
   government_id, representation_basis)
SELECT gen_random_uuid(),
       'ocd-division/country:us/state:dc',
       'District of Columbia',
       'NATIONAL_UPPER',
       'District of Columbia',
       'DC',
       '11',
       (SELECT government_id FROM essentials.districts
         WHERE id = 'fced59e7-cb65-46b1-aaf1-f99ce90e5441'),
       'residency'
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.districts
    WHERE state = 'DC' AND district_type = 'NATIONAL_UPPER');

-- 2. Move ONLY the two shadow-senator offices. Norton is untouched.
UPDATE essentials.offices o
   SET district_id = (SELECT id FROM essentials.districts
                       WHERE state = 'DC' AND district_type = 'NATIONAL_UPPER')
 WHERE o.title IN ('U.S. Shadow Senator (Senior)', 'U.S. Shadow Senator (Junior)')
   AND o.district_id = 'fced59e7-cb65-46b1-aaf1-f99ce90e5441';

-- 3. Post-verify. Every assertion states a POSITIVE fact about the end state, so it
--    cannot pass vacuously the way a "0 rows remain" check can before the data exists.
DO $$
DECLARE
  v_district uuid;
  v_shadow   int;
  v_norton   int;
  v_delegate int;
  v_geo      text;
  v_basis    text;
  v_notes    int;
BEGIN
  SELECT id, geo_id, representation_basis INTO v_district, v_geo, v_basis
    FROM essentials.districts WHERE state='DC' AND district_type='NATIONAL_UPPER';
  IF v_district IS NULL THEN
    RAISE EXCEPTION 'DC NATIONAL_UPPER district was not created';
  END IF;
  IF v_geo IS DISTINCT FROM '11' OR v_basis IS DISTINCT FROM 'residency' THEN
    RAISE EXCEPTION 'DC NATIONAL_UPPER has wrong geo_id/basis: geo=% basis=%', v_geo, v_basis;
  END IF;

  SELECT count(*) INTO v_shadow FROM essentials.offices
   WHERE title IN ('U.S. Shadow Senator (Senior)','U.S. Shadow Senator (Junior)')
     AND district_id = v_district;
  IF v_shadow <> 2 THEN
    RAISE EXCEPTION 'expected 2 shadow-senator offices on the new district, found %', v_shadow;
  END IF;

  -- Norton must still hold the delegate seat, and must be the ONLY office left on it.
  SELECT count(*) INTO v_norton FROM essentials.offices
   WHERE title = 'Delegate, District of Columbia'
     AND district_id = 'fced59e7-cb65-46b1-aaf1-f99ce90e5441';
  IF v_norton <> 1 THEN
    RAISE EXCEPTION 'delegate office missing from the delegate district (found %)', v_norton;
  END IF;

  SELECT count(*) INTO v_delegate FROM essentials.offices
   WHERE district_id = 'fced59e7-cb65-46b1-aaf1-f99ce90e5441';
  IF v_delegate <> 1 THEN
    RAISE EXCEPTION 'delegate district should carry exactly 1 office, carries %', v_delegate;
  END IF;

  -- ADR 0003: a non-full seat without a note must not exist.
  SELECT count(*) INTO v_notes FROM essentials.offices
   WHERE district_id = v_district
     AND (voting_powers <> 'non_voting' OR representation_note IS NULL);
  IF v_notes <> 0 THEN
    RAISE EXCEPTION '% shadow-senator office(s) lack non_voting + representation_note', v_notes;
  END IF;

  RAISE NOTICE 'OK: DC NATIONAL_UPPER % carries 2 shadow senators; delegate district carries only Norton', v_district;
END $$;

COMMIT;
