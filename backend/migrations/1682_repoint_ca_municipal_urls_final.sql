-- 1682_repoint_ca_municipal_urls_final.sql
--
-- The last 4 California municipal rows on plain http. After this, **every CA LOCAL and LOCAL_EXEC
-- row holds an https URL** -- 231 rows across 95 places, closed by migrations 1674, 1675, 1676, 1679,
-- 1680, 1681 and this one. Data-only; no schema change.
--
-- ── BASIS FOR EVERY ROW ───────────────────────────────────────────────────
--   Sacramento        rendered 200, "Home | City of Sacramento"; registry: City | City of Sacramento | Sacramento, CA -- which resolves the state-unconfirmed caveat (the page never says California)
--   San Francisco     rendered 200; registry: Domain type COUNTY, "City and County of San Francisco" -- the registry itself confirms both markers legitimately apply
--   La Habra Heights  operator supplied; rendered 200, 4690 chars, "La Habra Heights, CA | Official Website". An INITIALISM (LHH); no .gov registered to this city
--
-- ── 🔴 SAN FRANCISCO: THE REGISTRY CONFIRMS THE "DEFECT" WAS CORRECT ────────────
-- `sf.gov` was held back as VERIFIED_MIXED -- both "city council" and "board of supervisors" markers
-- present, which everywhere else in this series is the wrong-entity signal. The .gov registry records
-- it as **Domain type: County, Organization: "City and County of San Francisco"**. So the mixed
-- markers are not noise and not a defect: SF genuinely is both, and the registry says so independently
-- of anything on the page. The inverted-discriminator rule that drove 1674-1681 -- city means CITY
-- COUNCIL, county means BOARD OF SUPERVISORS -- simply has an exception, and the exception is a real
-- feature of California local government rather than a hole in the method.
--
-- ── 🔴 LA HABRA HEIGHTS: WHY A SUBSTRING SEARCH WOULD HAVE PICKED THE WRONG CITY ─────
-- La Habra Heights had defeated every method: its stored `la-habra-heights.org` answers 200 with ZERO
-- characters of body text, no candidate template found anything, and it has no `.gov`. The operator
-- supplied `lhhcity.org` -- an INITIALISM, the second in this series after La Canada Flintridge's
-- `lcf.ca.gov`, and unreachable from the city's name by any generator.
--
-- The trap worth recording: the registry contains `lahabraca.gov`, `lahabra.gov` and
-- `cityoflahabra-ca.gov`, ALL registered to the **CITY OF LA HABRA** -- a DIFFERENT, ADJACENT CITY.
-- "La Habra" is a strict prefix of "La Habra Heights", so a substring or LIKE match on the city name
-- would have handed La Habra's .gov to La Habra Heights and produced a confident, verifiable-looking,
-- wrong answer -- the same failure family as Grant County Indiana and the Rolling Hills church. The
-- registry lookups in this series matched the organisation name EXACTLY ("city of <name>") for this
-- reason, and that is why they returned nothing here rather than something plausible. The gate below
-- refuses all three La Habra domains on the La Habra Heights rows.
--
-- ── SACRAMENTO ────────────────────────────────────────────────────────────
-- Held as state-unconfirmed because `cityofsacramento.gov` never prints "California". The registry
-- names it City of Sacramento, Sacramento, CA. Low risk all along -- no other US city is called
-- Sacramento -- but it was not assumed, and now it is not guesswork either.
--
-- Destinations are bare `https://<host>/` roots. geo_id resolved from the stored host.
-- Idempotent: compare-and-swap on the exact value measured; the gate asserts END STATE.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

WITH repoint(geo_id, old_url, new_url) AS (
  VALUES
    ('0664000', 'http://www.cityofsacramento.org',    'https://www.cityofsacramento.gov/' ),  -- Sacramento (1r)
    ('0667000', 'http://www.sfgov.org',               'https://www.sf.gov/'               ),  -- San Francisco (1r)
    ('0639304', 'http://www.la-habra-heights.org/',   'https://www.lhhcity.org/'          )  -- La Habra Heights (2r)
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
  v_units CONSTANT int := 3;
  v_rows  CONSTANT int := 4;
  v_settled int;
  v_places  int;
  v_left    int;
  v_path    int;
  v_wrong   int;
  v_total   int;
BEGIN
  SELECT count(*), count(DISTINCT d.geo_id) INTO v_settled, v_places
    FROM essentials.districts d
    JOIN (VALUES
      ('0664000', 'https://www.cityofsacramento.gov/'),
      ('0667000', 'https://www.sf.gov/'),
      ('0639304', 'https://www.lhhcity.org/')
    ) AS w(geo_id, url)
      ON w.geo_id = d.geo_id AND d.official_web_url = w.url
   WHERE d.district_type IN ('LOCAL', 'LOCAL_EXEC') AND lower(d.state) = 'ca';

  IF v_places <> v_units OR v_settled <> v_rows THEN
    RAISE EXCEPTION 'expected % rows across % places, found % rows across % places',
      v_rows, v_units, v_settled, v_places;
  END IF;

  -- 🔴 THE CLOSING ASSERTION FOR THE WHOLE CA MUNICIPAL WAVE: nothing left on http.
  SELECT count(*) INTO v_left
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND official_web_url LIKE 'http://%';
  IF v_left <> 0 THEN
    RAISE EXCEPTION '% CA municipal row(s) are still on plain http', v_left;
  END IF;

  -- Every CA municipal URL is a bare https root, wave-wide -- not just the rows touched here.
  SELECT count(*) INTO v_path
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND official_web_url IS NOT NULL
     AND official_web_url !~ '^https://[^/]+/$';
  IF v_path <> 0 THEN
    RAISE EXCEPTION '% CA municipal row(s) are not a bare https://<host>/ root', v_path;
  END IF;

  -- 🔴 LA HABRA is a different city from LA HABRA HEIGHTS. Its three .gov domains must never appear
  --    on the La Habra Heights rows, which a substring match on the city name would have caused.
  SELECT count(*) INTO v_wrong
    FROM essentials.districts
   WHERE geo_id = '0639304'
     AND official_web_url IS NOT NULL
     AND (official_web_url ILIKE '%lahabraca.gov%' OR official_web_url ILIKE '%//lahabra.gov%'
       OR official_web_url ILIKE '%www.lahabra.gov%' OR official_web_url ILIKE '%cityoflahabra%');
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION 'La Habra Heights points at the CITY OF LA HABRA (% row(s)) -- different city', v_wrong;
  END IF;

  SELECT count(*) INTO v_total
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca' AND official_web_url IS NOT NULL;

  RAISE NOTICE 'OK: the last % CA municipal rows moved to https.', v_rows;
  RAISE NOTICE 'CA MUNICIPAL WAVE CLOSED: all % rows now hold a bare https site root.', v_total;
  RAISE NOTICE 'San Francisco: the registry lists sf.gov as Domain type COUNTY, org "City and County of';
  RAISE NOTICE 'San Francisco" -- its mixed city/county markers were CORRECT, not a defect.';
  RAISE NOTICE 'La Habra Heights: lhhcity.org, an initialism. The registry holds THREE La Habra .govs';
  RAISE NOTICE 'for a DIFFERENT adjacent city -- a substring match would have picked one of them.';
END $$;

COMMIT;
