-- 1683_repoint_or_municipal_official_web_urls.sql
--
-- Repoints `official_web_url` for all 12 Oregon CITY jurisdictions -- 24 rows, the entire OR
-- LOCAL/LOCAL_EXEC set. Data-only; no schema change. After this, **the only rows left on plain http
-- anywhere in this table are 4 Oregon counties** (Baker, Klamath, Lake, Wheeler).
--
-- ── 🔴🔴 TWO ROWS WERE ONE HYPHEN FROM WORKING, ON A `.gov` THAT NEVER RESOLVED ──────
-- The most valuable finding in this batch, because it is invisible to every heuristic this series has
-- used. Two cities were stored on a `.gov` hostname that looks exactly right and has never existed:
--
--     Forest Grove   stored `forestgroveor.gov`   NXDOMAIN   real: `forestgrove-or.gov`
--     Tigard         stored `tigardor.gov`        NXDOMAIN   real: `tigard-or.gov`
--
-- A `.gov` in the stored value is normally the strongest signal a row is FINE -- the namespace is
-- administered, so it cannot be squatted, and the preference order treats reaching one as the goal.
-- Here it was the opposite: a plausible `.gov` that has never resolved, which a check for "is this
-- already a .gov?" would wave straight through. Only DNS says otherwise. Oregon cities hyphenate
-- (`forestgrove-or`, `tigard-or`, `hillsboro-oregon`) and the candidate generator produces no
-- hyphens at all, so neither real host was reachable from the city name by any template in this tool.
--
-- ── HOW THE REST WERE FOUND ────────────────────────────────────────────────
-- Five needed nothing but the scheme: their stored `<name>oregon.gov` host is correct and rendered
-- (Beaverton, Fairview, Gresham, Sherwood, Troutdale). Five sat on `ci.<name>.or.us`, Oregon's retired
-- municipal namespace -- the same move 1670-1673 documented for its counties and 1675 for California's
-- `ci.<name>.ca.us`. Every destination was located in CISA's .gov registry by REGISTRANT
-- ORGANISATION and then rendered; two answer 403 to headless (Hillsboro, Tigard) and rest on the
-- registry, as in 1676 and 1679.
--
-- 🔴 A refinement to the registry method, learned here: matching the organisation name EXACTLY as
-- "city of <name>" MISSED both Tigard and Cornelius, whose registrants are "City of Tigard, **Oregon**"
-- and "City of Cornelius, **Oregon**" -- the state is appended. Exact matching is what kept La Habra
-- off La Habra Heights in 1682, so it should not simply be loosened to a substring; match
-- "city of <name>" OR "city of <name>, <state>" and keep rejecting a longer city name.
--
-- 🔴 Tualatin owns TWO .gov domains (`tualatin.gov` and `tualatinoregon.gov`) and `tualatin.gov`
-- redirects to `tualatinoregon.gov`, so the latter is canonical -- the redirect-direction check from
-- 1676, which is also what the stored `ci.tualatin.or.us` forwards to.
--
-- Troutdale's nav-only caveat (governing body in navigation, not prose) is cleared: it renders 200 with
-- the title "Home Page | Troutdale OR" and city markers present.
--
-- ── BASIS FOR EVERY ROW ───────────────────────────────────────────────────
--   Beaverton     SCHEME   rendered VERIFIED; registry: City of Beaverton, OR
--   Bend          REPOINT  registry: City of Bend, OR; rendered 200 "City of Bend - Home" (www redirects to the bare host)
--   Cornelius     REPOINT  registry: "City of Cornelius, Oregon"; rendered 200, 5463 chars, "Cornelius, OR | Official Website"
--   Fairview      SCHEME   rendered VERIFIED; registry: City of Fairview, OR
--   Forest Grove  REPOINT  stored host NXDOMAIN and differs from the real one by ONE HYPHEN; registry: City of Forest Grove, OR; rendered 200, 9821 chars
--   Gresham       SCHEME   rendered VERIFIED; registry: City of Gresham, OR
--   Hillsboro     REPOINT  registry: City of Hillsboro, OR (403 to headless, so registry is the basis)
--   Sherwood      SCHEME   rendered VERIFIED; registry: City of Sherwood, OR
--   Tigard        REPOINT  stored host NXDOMAIN and differs from the real one by ONE HYPHEN; registry: "City of Tigard, Oregon" (403 to headless)
--   Troutdale     SCHEME   rendered 200 "Home Page | Troutdale OR" with city markers, clearing the nav-only caveat; registry: City of Troutdale, OR
--   Tualatin      REPOINT  stored host redirects here; registry lists BOTH tualatin.gov and tualatinoregon.gov, and tualatin.gov redirects to this one
--   Wood Village  REPOINT  registry: City of Wood Village, OR; rendered 200, "City of Wood Village"
--
-- Destinations are bare `https://<host>/` roots; Bend's `www` form redirects to the bare host, so the
-- bare host is stored. geo_id: 7-digit Census PLACE codes, 24 rows, all OR LOCAL/LOCAL_EXEC -- no
-- other district type shares them, and the type/state scope is kept regardless.
--
-- Idempotent: compare-and-swap on the exact value measured; the gate asserts END STATE.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

WITH repoint(geo_id, old_url, new_url) AS (
  VALUES
    -- ── host CHANGES ──
    ('4105800', 'http://www.ci.bend.or.us/',          'https://bendoregon.gov/'           ),  -- Bend (2r)
    ('4115550', 'http://www.ci.cornelius.or.us/',     'https://www.corneliusor.gov/'      ),  -- Cornelius (2r)
    ('4126200', 'http://www.forestgroveor.gov',       'https://www.forestgrove-or.gov/'   ),  -- Forest Grove (2r)
    ('4134100', 'http://www.ci.hillsboro.or.us/',     'https://www.hillsboro-oregon.gov/' ),  -- Hillsboro (2r)
    ('4173650', 'http://www.tigardor.gov/',           'https://www.tigard-or.gov/'        ),  -- Tigard (2r)
    ('4174950', 'http://www.ci.tualatin.or.us/',      'https://tualatinoregon.gov/'       ),  -- Tualatin (2r)
    ('4183950', 'http://www.ci.woodvillage.or.us',    'https://www.woodvillageor.gov/'    ),  -- Wood Village (2r)
    -- ── host UNCHANGED: scheme upgrade only ──
    ('4105350', 'http://www.beavertonoregon.gov/',    'https://www.beavertonoregon.gov/'  ),  -- Beaverton (2r)
    ('4124250', 'http://www.fairvieworegon.gov',      'https://www.fairvieworegon.gov/'   ),  -- Fairview (2r)
    ('4131250', 'http://www.greshamoregon.gov',       'https://www.greshamoregon.gov/'    ),  -- Gresham (2r)
    ('4167100', 'http://www.sherwoodoregon.gov',      'https://www.sherwoodoregon.gov/'   ),  -- Sherwood (2r)
    ('4174850', 'http://www.troutdaleoregon.gov',     'https://www.troutdaleoregon.gov/'  )  -- Troutdale (2r)
)
UPDATE essentials.districts d
   SET official_web_url = r.new_url
  FROM repoint r
 WHERE d.geo_id           = r.geo_id
   AND d.district_type    IN ('LOCAL', 'LOCAL_EXEC')
   AND lower(d.state)     = 'or'
   AND d.official_web_url = r.old_url;

-- ── POST-VERIFY GATE ──────────────────────────────────────────────────────
DO $$
DECLARE
  v_units CONSTANT int := 12;
  v_rows  CONSTANT int := 24;
  v_settled int;
  v_places  int;
  v_left    int;
  v_path    int;
  v_dead    int;
  v_county  int;
  v_all     int;
BEGIN
  SELECT count(*), count(DISTINCT d.geo_id) INTO v_settled, v_places
    FROM essentials.districts d
    JOIN (VALUES
      ('4105350', 'https://www.beavertonoregon.gov/'),
      ('4105800', 'https://bendoregon.gov/'),
      ('4115550', 'https://www.corneliusor.gov/'),
      ('4124250', 'https://www.fairvieworegon.gov/'),
      ('4126200', 'https://www.forestgrove-or.gov/'),
      ('4131250', 'https://www.greshamoregon.gov/'),
      ('4134100', 'https://www.hillsboro-oregon.gov/'),
      ('4167100', 'https://www.sherwoodoregon.gov/'),
      ('4173650', 'https://www.tigard-or.gov/'),
      ('4174850', 'https://www.troutdaleoregon.gov/'),
      ('4174950', 'https://tualatinoregon.gov/'),
      ('4183950', 'https://www.woodvillageor.gov/')
    ) AS w(geo_id, url)
      ON w.geo_id = d.geo_id AND d.official_web_url = w.url
   WHERE d.district_type IN ('LOCAL', 'LOCAL_EXEC') AND lower(d.state) = 'or';

  IF v_places <> v_units OR v_settled <> v_rows THEN
    RAISE EXCEPTION 'expected % rows across % places, found % rows across % places',
      v_rows, v_units, v_settled, v_places;
  END IF;

  -- No OR municipal row left on http, and every one a bare https root.
  SELECT count(*) INTO v_left
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'or'
     AND official_web_url LIKE 'http://%';
  IF v_left <> 0 THEN
    RAISE EXCEPTION '% OR municipal row(s) are still on plain http', v_left;
  END IF;

  SELECT count(*) INTO v_path
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'or'
     AND official_web_url IS NOT NULL AND official_web_url !~ '^https://[^/]+/$';
  IF v_path <> 0 THEN
    RAISE EXCEPTION '% OR municipal row(s) are not a bare https://<host>/ root', v_path;
  END IF;

  -- 🔴 THE TWO NEVER-RESOLVING .gov HOSTNAMES MUST NEVER RETURN. They look correct, which is
  --    exactly why they need a gate: no vocabulary or TLD check would reject either.
  SELECT count(*) INTO v_dead
    FROM essentials.districts
   WHERE official_web_url IS NOT NULL
     AND (official_web_url ~* '//(www\\.)?forestgroveor\\.gov'
       OR official_web_url ~* '//(www\\.)?tigardor\\.gov');
  IF v_dead <> 0 THEN
    RAISE EXCEPTION '% row(s) hold a .gov hostname that has never resolved (missing hyphen)', v_dead;
  END IF;

  -- 🔴 A city row must never point at a county site -- Oregon counties are BOARD OF COMMISSIONERS.
  SELECT count(*) INTO v_county
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'or'
     AND official_web_url IS NOT NULL
     AND (official_web_url ILIKE '%county%' OR official_web_url ~ 'https?://(www\\.)?co\\.'
       OR official_web_url ILIKE '%multco%' OR official_web_url ILIKE '%clackamas.us%');
  IF v_county <> 0 THEN
    RAISE EXCEPTION '% OR city row(s) point at a COUNTY site', v_county;
  END IF;

  RAISE NOTICE 'OK: all % OR city rows across % places now hold a bare https site root.', v_rows, v_units;
  RAISE NOTICE '🔴 Forest Grove and Tigard were stored on a .gov ONE HYPHEN from the real host';
  RAISE NOTICE '(forestgroveor.gov / tigardor.gov) that has NEVER resolved -- a .gov in the stored value';
  RAISE NOTICE 'is normally the strongest sign a row is fine, and here it was the opposite.';
  RAISE NOTICE '5 kept their host and took the scheme; 5 left the retired ci.<name>.or.us namespace.';

  SELECT count(*) INTO v_all
    FROM essentials.districts WHERE official_web_url LIKE 'http://%';
  RAISE NOTICE '% row(s) remain on http in the WHOLE table: Baker, Klamath, Lake and Wheeler counties.', v_all;
  RAISE NOTICE 'Wheeler must NOT be auto-repointed -- its only candidate is a same-name .com.';
END $$;

COMMIT;
