-- 1679_repoint_ca_municipal_urls_registry_found.sql
--
-- Repoints `official_web_url` for 6 California cities whose stored URL rendered as EMPTY, FAIL,
-- NAME_ONLY or a reset connection, and whose real site was found via the .gov registry. 23 rows.
-- Data-only. Fourth municipal migration, after 1674 (43 units that rendered), 1675 (16 NXDOMAIN) and
-- 1676 (18 WAF-blocked).
--
-- ── WHY RENDERING ALONE FAILED ON THESE SIX ────────────────────────────────
-- These are the leftovers whose stored URL produced a verdict that looked like a dead end:
--   Pasadena    ci.pasadena.ca.us    EMPTY -- rendered, but with no usable content
--   El Monte    elmonte.org          FAIL  -- failed even after the transport retry
--   Cudahy      cudahy.ca.us         FAIL
--   Glendale    ci.glendale.ca.us    FAIL
--   Avalon      CITYOFAVALON.COM     NAME_ONLY -- names Avalon, shows no city government
--   South Gate  sogate.org           connection reset over TLS
-- None of those verdicts identifies a replacement, and the candidate generator had already been run.
-- What found all six was searching CISA's .gov registry BY ORGANISATION NAME
-- (github.com/cisagov/dotgov-data) for "City of <name>" in CA, then rendering what it returned. Five
-- of the six own a .gov that no hostname template would have produced from the city's name alone.
--
-- ── BASIS FOR EVERY ROW ───────────────────────────────────────────────────
--   Pasadena    rendered 200 "City of Pasadena - California", city markers; registry: City of Pasadena, CA. Redirects on to their cityofpasadena.net
--   El Monte    rendered 200, 2689 chars, "El Monte, CA | Official Website"; registry: City of El Monte, CA
--   Avalon      rendered 200, 4301 chars, "Avalon, CA | Official Website"; registry: City of Avalon, CA
--   Cudahy      rendered 200, 4236 chars, "Cudahy, CA | Official Website"; registry: City of Cudahy, CA
--   Glendale    WAF 403 to headless; registry: City of Glendale, CA
--   South Gate  rendered 200, "Home City of South Gate", city markers; NO .gov registered to this city
--
-- Glendale is the only row not confirmed by rendering: it answers 403 "Access Denied" to headless
-- Chromium. It rests on the registry, exactly as the four blocked rows in 1676 did -- and note the
-- registry is what disambiguates it, because GLENDALE EXISTS IN ARIZONA TOO and `glendaleaz.gov` is a
-- different city government. A name match alone could not have told them apart.
--
-- ── 🔴 PASADENA: WHY THE `.gov` AND NOT THE `.net` IT REDIRECTS TO ─────────────────
-- `pasadena.gov` serves 200 with the title "City of Pasadena - California" and then forwards to
-- `cityofpasadena.net`. Migration 1676 faced the mirror of this and chose the other way, keeping
-- `weho.org` over `weho.gov` and `cityofwhittier.org` over `cityofwhittier.gov`. The two are
-- distinguishable and the distinction is the whole reason to write it down:
--   * In 1676 the non-.gov host was ALREADY STORED and working, so switching to a .gov that merely
--     redirects back would have been change for its own sake.
--   * Here the stored host is DEAD, so the host changes no matter what. Given a free choice between an
--     administered `.gov` that serves and a squattable `.net`, the preference order picks `.gov` --
--     the same reasoning that made Sierra County's lapsed `.ws` a squat risk in the first place.
-- A voter reaches the same site either way; one of the two cannot be taken over by a stranger.
--
-- 🔴 South Gate is the one city here with NO .gov registered to it, so it keeps a `.org`
-- (`cityofsouthgate.org`, rendered, city markers present) -- a verified absence, not an assumption.
-- Its stored `sogate.org` resets the connection over TLS and is not recoverable.
--
-- Destinations are bare `https://<host>/` roots. South Gate's root forwards to `/Home`; the ROOT is
-- stored, per 1674 -- a redirect landing path is not a homepage.
--
-- geo_id: 7-digit Census PLACE codes, 23 rows, all CA LOCAL/LOCAL_EXEC; scoped by type and state anyway.
-- Idempotent: compare-and-swap on the exact value measured; the gate asserts END STATE.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

WITH repoint(geo_id, old_url, new_url) AS (
  VALUES
    ('0656000', 'http://www.ci.pasadena.ca.us/',    'https://www.pasadena.gov/'         ),  -- Pasadena (8r)
    ('0622230', 'http://www.elmonte.org',           'https://www.elmonteca.gov/'        ),  -- El Monte (7r)
    ('0603274', 'http://WWW.CITYOFAVALON.COM',      'https://www.cityofavalon.gov/'     ),  -- Avalon (2r)
    ('0617498', 'http://www.cudahy.ca.us/',         'https://www.cityofcudahyca.gov/'   ),  -- Cudahy (2r)
    ('0630000', 'http://www.ci.glendale.ca.us',     'https://www.glendaleca.gov/'       ),  -- Glendale (2r)
    ('0673080', 'http://www.sogate.org',            'https://www.cityofsouthgate.org/'  )  -- South Gate (2r)
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
  v_units CONSTANT int := 6;
  v_rows  CONSTANT int := 23;
  v_settled int;
  v_places  int;
  v_plain   int;
  v_path    int;
  v_wrong   int;
BEGIN
  SELECT count(*), count(DISTINCT d.geo_id) INTO v_settled, v_places
    FROM essentials.districts d
    JOIN (VALUES
      ('0656000', 'https://www.pasadena.gov/'),
      ('0622230', 'https://www.elmonteca.gov/'),
      ('0603274', 'https://www.cityofavalon.gov/'),
      ('0617498', 'https://www.cityofcudahyca.gov/'),
      ('0630000', 'https://www.glendaleca.gov/'),
      ('0673080', 'https://www.cityofsouthgate.org/')
    ) AS w(geo_id, url)
      ON w.geo_id = d.geo_id AND d.official_web_url = w.url
   WHERE d.district_type IN ('LOCAL', 'LOCAL_EXEC') AND lower(d.state) = 'ca';

  IF v_places <> v_units OR v_settled <> v_rows THEN
    RAISE EXCEPTION 'expected % rows across % places, found % rows across % places',
      v_rows, v_units, v_settled, v_places;
  END IF;

  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0656000','0622230','0603274','0617498','0630000','0673080') AND official_web_url LIKE 'http://%';
  IF v_plain <> 0 THEN
    RAISE EXCEPTION '% row(s) are still on plain http', v_plain;
  END IF;

  SELECT count(*) INTO v_path
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0656000','0622230','0603274','0617498','0630000','0673080')
     AND (official_web_url LIKE '%?%' OR official_web_url ~ '^https://[^/]+/.+');
  IF v_path <> 0 THEN
    RAISE EXCEPTION '% row(s) hold a path or query rather than a site root', v_path;
  END IF;

  -- 🔴 Same-name cities in other states, and the county/city confusion. Glendale AZ is the live risk
  --    on this batch; Pasadena TX is the other. Neither may ever be stored on a CA city row.
  SELECT count(*) INTO v_wrong
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND official_web_url IS NOT NULL
     AND (official_web_url ILIKE '%glendaleaz%' OR official_web_url ILIKE '%pasadenatx%'
       OR official_web_url ILIKE '%.az.gov%'    OR official_web_url ILIKE '%.tx.gov%'
       OR official_web_url ILIKE '%lacounty%'   OR official_web_url ILIKE '%countyof%'
       OR official_web_url ~ 'https?://(www\\.)?co\\.');
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION '% CA city row(s) point at another state or at a county', v_wrong;
  END IF;

  RAISE NOTICE 'OK: % CA city rows across % places found via the .gov registry, not by rendering.', v_rows, v_units;
  RAISE NOTICE 'Glendale rests on the registry alone (403 to headless) -- and GLENDALE AZ is a';
  RAISE NOTICE 'different city government, which only the registrant name could separate.';
  RAISE NOTICE 'South Gate has no .gov registered to it and keeps a verified .org.';

  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca' AND official_web_url LIKE 'http://%';
  RAISE NOTICE '% CA municipal row(s) still on http. Remaining need a human read in a real browser:', v_plain;
  RAISE NOTICE 'Compton (comptoncity.org serves a Sendio email login), La Canada Flintridge (the site';
  RAISE NOTICE 'stored is the CHAMBER OF COMMERCE), La Habra Heights (renders empty), Lomita (timeout),';
  RAISE NOTICE 'Pico Rivera (SSL error), Rolling Hills (rollinghills.org is a CHURCH IN OREGON).';
END $$;

COMMIT;
