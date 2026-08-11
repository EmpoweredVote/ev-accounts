-- 1681_repoint_ca_municipal_urls_caveats_cleared.sql
--
-- Clears 4 of the 6 California cities whose URL VERIFIED but carried a caveat, held back since 1674.
-- 19 rows -- 13 of them Long Beach, the largest single decision in this corpus. Data-only.
--
-- ── WHY THESE WERE HELD, AND WHAT CLEARED EACH ─────────────────────────────
-- All four destinations are exactly what the auditor recommended in 1674. They were withheld because
-- a caveat meant the evidence had a named weakness, not because the answer looked wrong -- and the
-- point of a caveat is that somebody resolves it rather than that it decays into permanent doubt.
--
-- 🔴 **LONG BEACH (13 rows) -- `longbeach.gov` NAMES NO STATE, AND LONG BEACH IS IN FOUR.**
-- The page never says "California" and the host is a bare place name, so the auditor flagged it
-- state-unconfirmed AND name-ambiguous, correctly: there are cities called Long Beach in New York,
-- Mississippi and Washington as well as California. The CISA .gov registry settles it outright, and
-- the shape of its answer is the useful part:
--     longbeach.gov     City of Long Beach California   Long Beach, CA   <- ours
--     longbeachms.gov   City of Long Beach              Long Beach, MS
--     longbeachny.gov   City of Long Beach              Long Beach, NY
--     longbeachwa.gov   City of Long Beach, Washington  Long Beach, WA
--     lbpdny.gov / longbeachfdny.gov  (Long Beach NY police and fire)
-- California holds the BARE name and every other Long Beach carries a state suffix. So the very fact
-- that made the host look ambiguous -- no state in it -- is what identifies it, once you can see the
-- whole namespace. A page read could never have established that; only the registry can.
--
-- The other three were each confirmed by the operator opening them in a real browser:
--   * Artesia -- governing body appeared in NAVIGATION only, not prose (the weaker evidence class
--     dealt with for Oregon in 1673). Host unchanged; this is a scheme upgrade.
--   * Gardena -- VERIFIED_MIXED: both "city council" and "board of supervisors" markers present.
--     Mixed markers are normal on a municipal site that links to county services, and are only
--     alarming when the county marker appears WITHOUT a city one.
--   * Rancho Palos Verdes -- also VERIFIED_MIXED, and additionally the row whose landing URL was the
--     `?searchPhrase=` query that prompted the root-canonicalisation rule in 1674. Registry confirms
--     `rpvca.gov` is the City of Rancho Palos Verdes, CA.
--
-- ── BASIS FOR EVERY ROW ───────────────────────────────────────────────────
--   Long Beach            registry: "City of Long Beach California", Long Beach, CA -- the other four Long Beaches hold longbeachms.gov / longbeachny.gov / longbeachwa.gov, so CA holds the bare name
--   Artesia               operator confirmed; rendered VERIFIED and state-confirmed (governing body in navigation only)
--   Gardena               operator confirmed; rendered VERIFIED, both entity markers present
--   Rancho Palos Verdes   registry: City of Rancho Palos Verdes, CA; operator confirmed
--
-- Rancho Palos Verdes' stored value was `http://www.palosverdes.com/rpv/` -- a PATH on a `.com`
-- shared with other peninsula cities, which is its own reason to move. Destinations are bare
-- `https://<host>/` roots throughout.
--
-- ── STILL OPEN AFTER THIS: 4 ROWS ─────────────────────────────────────────
--   * Sacramento (1 row) -- state-unconfirmed on `cityofsacramento.gov`. Sacramento is unique among
--     US cities, so the risk is low, but it has not been checked and is not being assumed.
--   * San Francisco (1 row) -- VERIFIED_MIXED on `sf.gov`, which is expected: SF is a CONSOLIDATED
--     CITY-COUNTY, so both marker sets genuinely apply. Worth one look precisely because the
--     inverted-discriminator rule this series relies on does not cleanly apply to it.
--   * La Habra Heights (2 rows) -- `la-habra-heights.org` answers 200 with ZERO body text and no
--     alternative has been found by any method, including the operator's browser. A reading task.
--
-- geo_id resolved from the STORED HOST, not assumed. 19 rows, all CA LOCAL/LOCAL_EXEC.
-- Idempotent: compare-and-swap on the exact value measured; the gate asserts END STATE.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

WITH repoint(geo_id, old_url, new_url) AS (
  VALUES
    ('0643000', 'http://www.longbeach.gov',           'https://www.longbeach.gov/'      ),  -- Long Beach (13r)
    ('0602896', 'http://www.cityofartesia.us',        'https://www.cityofartesia.us/'   ),  -- Artesia (2r)
    ('0628168', 'http://www.ci.gardena.ca.us/',       'https://cityofgardena.org/'      ),  -- Gardena (2r)
    ('0659514', 'http://www.palosverdes.com/rpv/',    'https://www.rpvca.gov/'          )  -- Rancho Palos Verdes (2r)
)
UPDATE essentials.districts d
   SET official_web_url = r.new_url
  FROM repoint r
 WHERE d.geo_id           = r.geo_id
   AND d.district_type    IN ('LOCAL', 'LOCAL_EXEC')
   AND lower(d.state)     = 'ca'
   AND d.official_web_url = r.old_url;

-- ── POST-VERIFY GATE ──────────────────────────────────────────────────────
DO $$
DECLARE
  v_units CONSTANT int := 4;
  v_rows  CONSTANT int := 19;
  v_settled int;
  v_places  int;
  v_plain   int;
  v_path    int;
  v_wrong   int;
  v_left    int;
BEGIN
  SELECT count(*), count(DISTINCT d.geo_id) INTO v_settled, v_places
    FROM essentials.districts d
    JOIN (VALUES
      ('0643000', 'https://www.longbeach.gov/'),
      ('0602896', 'https://www.cityofartesia.us/'),
      ('0628168', 'https://cityofgardena.org/'),
      ('0659514', 'https://www.rpvca.gov/')
    ) AS w(geo_id, url)
      ON w.geo_id = d.geo_id AND d.official_web_url = w.url
   WHERE d.district_type IN ('LOCAL', 'LOCAL_EXEC') AND lower(d.state) = 'ca';

  IF v_places <> v_units OR v_settled <> v_rows THEN
    RAISE EXCEPTION 'expected % rows across % places, found % rows across % places',
      v_rows, v_units, v_settled, v_places;
  END IF;

  -- Long Beach is 13 of these 19 rows; assert that fan-out explicitly rather than trusting the total.
  SELECT count(*) INTO v_settled
    FROM essentials.districts
   WHERE geo_id = '0643000' AND district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND official_web_url = 'https://www.longbeach.gov/';
  IF v_settled <> 13 THEN
    RAISE EXCEPTION 'expected 13 Long Beach rows on longbeach.gov, found %', v_settled;
  END IF;

  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0643000','0602896','0628168','0659514') AND official_web_url LIKE 'http://%';
  IF v_plain <> 0 THEN
    RAISE EXCEPTION '% row(s) are still on plain http', v_plain;
  END IF;

  SELECT count(*) INTO v_path
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0643000','0602896','0628168','0659514')
     AND (official_web_url LIKE '%?%' OR official_web_url ~ '^https://[^/]+/.+');
  IF v_path <> 0 THEN
    RAISE EXCEPTION '% row(s) hold a path or query rather than a site root', v_path;
  END IF;

  -- 🔴 The other four Long Beaches, and the shared peninsula .com RPV is leaving. None may appear on
  --    a California city row.
  SELECT count(*) INTO v_wrong
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND official_web_url IS NOT NULL
     AND (official_web_url ILIKE '%longbeachms%' OR official_web_url ILIKE '%longbeachny%'
       OR official_web_url ILIKE '%longbeachwa%' OR official_web_url ILIKE '%lbpdny%'
       OR official_web_url ILIKE '%longbeachfdny%'
       OR official_web_url ILIKE '%palosverdes.com%');
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION '% CA city row(s) point at another state''s Long Beach or the shared peninsula .com', v_wrong;
  END IF;

  RAISE NOTICE 'OK: % CA city rows across % places cleared of their caveats.', v_rows, v_units;
  RAISE NOTICE 'Long Beach (13 rows): longbeach.gov is registered to "City of Long Beach California".';
  RAISE NOTICE 'The other four Long Beaches carry a state suffix (MS/NY/WA), so the ABSENCE of a state';
  RAISE NOTICE 'in the host -- the thing that made it look ambiguous -- is what identifies ours.';

  SELECT count(*) INTO v_left
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca' AND official_web_url LIKE 'http://%';
  RAISE NOTICE '% CA municipal row(s) still on http: Sacramento (1, state-unconfirmed), San Francisco', v_left;
  RAISE NOTICE '(1, mixed markers -- it is a CONSOLIDATED CITY-COUNTY, so both genuinely apply), and';
  RAISE NOTICE 'La Habra Heights (2, answers 200 with ZERO body text; no alternative found).';
END $$;

COMMIT;
