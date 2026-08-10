-- 1670_repoint_or_county_official_web_urls.sql
--
-- Repoints `official_web_url` for 12 of Oregon's 36 county districts. Data-only; no schema change.
-- These are the 12 rows the 2026-08-10 audit settled with NO caveat of any kind. The other 24 are
-- deliberately excluded and listed at the bottom, because each needs a human read this migration is
-- not the place for.
--
-- ── WHY ────────────────────────────────────────────────────────────────────────────────────────
-- Oregon's counties left the old state-hosted `co.<name>.or.us` namespace for their own `.gov`, and
-- this table never followed. That is one event, not twelve independent defects: 9 of the 12 rows
-- below are literally the same rewrite (`co.<name>.or.us` -> `<name>countyor.gov` /
-- `<name>county.gov`). All 36 Oregon county rows still held a plain `http://` URL. Measured
-- 2026-08-10 by rendering every one in a real browser engine: `npm run audit:district-urls
-- --prefix backend -- --state or --type COUNTY` (report committed at
-- `backend/data/or-county-url-audit-final.json`, 36 units, 506 pages rendered).
--
-- ── 🔴🔴 EVERY geo_id IN THIS FILE IS AMBIGUOUS. SCOPE BY district_type OR CORRUPT THE LEGISLATURE.
-- Oregon's county FIPS codes collide head-on with its legislative district numbering. `41003` is
-- Benton County AND `State House District 3` AND `State Senate District 3`. Across the 12 geo_ids
-- below there are **29 rows**, only 12 of which are counties; the 17 legislative rows carry
-- `official_web_url IS NULL`. So a bare `WHERE geo_id = '41003'` matches three rows and would stamp
-- a county homepage onto two state legislative districts -- silently, since nothing constrains that
-- column. Every statement here is scoped `district_type = 'COUNTY' AND lower(state) = 'or'`, and the
-- post-verify gate asserts the legislative rows are still NULL.
--
-- ── 🔴 THE HARD PART IS IDENTITY, NOT LIVENESS ─────────────────────────────────────────────────
-- A URL that resolves is not evidence that it resolves to this county. The audit rendered and then
-- REJECTED 27 destinations that a ranking function would have accepted. Six of them named the right
-- county on the wrong state's website:
--   Grant      -> www.in.gov/counties/grant            (INDIANA)
--   Lincoln    -> www.lincolncountync.gov              (NORTH CAROLINA)
--   Sherman    -> www.shermancountyks.gov              (KANSAS)
--   Douglas    -> douglascounty.us                     (MINNESOTA / WISCONSIN)
--   Washington -> www.areaguides.com/WashingtonCounty  (MARYLAND)
--   Washington -> washingtongov.org                    (OHIO)
-- Fourteen states have a Grant County and 33 have a Washington County, so a page naming the county
-- and showing "County Commissioners" passes every entity marker while being the wrong government
-- entirely. Twenty more were tourism sites, parked domains or real-estate listings, and one -- the
-- value stored on Sherman County -- was a gambling squat serving 19,030 characters of casino
-- keywords. The post-verify gate below fails if any of these is ever stored on an OR county row.
--
-- ── 🔴 GRANT COUNTY IS THE ONE NON-`.gov` DESTINATION, AND THAT IS CORRECT HERE ─────────────────
-- `.gov` is administered, so a lapsed registration cannot be picked up by a squatter; every other
-- row here lands on one. Grant does not, and it is the only row that needed a judgement call rather
-- than a rewrite. All SEVEN `.gov` candidates are NXDOMAIN -- grantcounty.or.gov, grantcountyor.gov,
-- grantcounty.gov, countyofgrant.gov, countyofgrantor.gov, grant.or.gov, grantcountyoregon.gov --
-- so Grant County genuinely has no `.gov`, which is the documented condition for accepting a
-- non-`.gov` host. `grantcountyoregon.net` verified with its governing body in page PROSE (not
-- merely in navigation) and named Oregon. Its 1,250 rendered characters are thin; that is ordinary
-- for a county of ~7,200 people, but it is the one row here worth re-reading first if any is.
-- The value being replaced, `gcoregonlive2.com`, does not resolve at all.
--
-- ── WHAT THIS DOES NOT TOUCH ───────────────────────────────────────────────────────────────────
-- 24 rows are excluded on purpose:
--   * 6 scheme-only upgrades (Clackamas, Coos, Lincoln, Malheur, Marion, Multnomah) -- host
--     unchanged, lowest risk, but they belong in their own change.
--   * 15 repoints carrying a caveat: a governing body found only in NAVIGATION (Jefferson, Morrow,
--     Tillamook, Washington, Wallowa) or a WAF that blocked some probe in the unit (Clatsop, Curry,
--     Deschutes, Douglas, Jackson, Josephine, Polk, Sherman, Union).
--   * 3 with no destination found (Baker, Klamath, Lake) -- a reading queue, not a deletion queue.
--   * 🔴 1 REFUSED: Wheeler (41069). Its stored `wheelercountyoregon.gov` is NXDOMAIN and the only
--     destination found is the same name on `.com`. That is the Sierra County shape -- a lapsed
--     registration answering on a cheaper namespace -- running in the direction the preference order
--     forbids. A dead `.gov` is a reason to search, never a reason to accept the same name on `.com`.
--
-- Idempotent: the UPDATE is a compare-and-swap on the exact value the audit measured, so a second
-- run matches 0 rows, and the gate asserts END STATE rather than the delta.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

-- Compare-and-swap. `official_web_url = v.old_url` makes this idempotent AND makes it refuse to
-- overwrite a value some other session changed after the audit measured it.
WITH repoint(geo_id, old_url, new_url) AS (
  VALUES
    ('41003', 'http://www.co.benton.or.us/',     'https://www.bentoncountyor.gov/'),
    ('41009', 'http://www.co.columbia.or.us/',   'https://www.columbiacountyor.gov/'),
    ('41013', 'http://www.co.crook.or.us/',      'https://www.crookcountyor.gov/'),
    ('41021', 'http://www.co.gilliam.or.us',     'https://www.gilliamcountyor.gov/'),
    ('41023', 'http://www.gcoregonlive2.com',    'https://www.grantcountyoregon.net/'),
    ('41025', 'http://www.co.harney.or.us/',     'https://harneycountyor.gov/'),
    ('41027', 'http://www.co.hood-river.or.us/', 'https://www.hoodrivercounty.gov/'),
    ('41039', 'http://www.lanecounty.org',       'https://www.lanecountyor.gov/'),
    ('41043', 'http://www.co.linn.or.us/',       'https://www.linncountyor.gov/'),
    ('41059', 'http://www.umatillacounty.net',   'https://www.umatillacounty.gov/'),
    ('41065', 'http://www.co.wasco.or.us/',      'https://www.wascocountyor.gov/'),
    ('41071', 'http://www.co.yamhill.or.us/',    'https://www.yamhillcounty.gov/')
)
UPDATE essentials.districts d
   SET official_web_url = r.new_url
  FROM repoint r
 WHERE d.geo_id          = r.geo_id
   AND d.district_type   = 'COUNTY'          -- 🔴 without this, 41003 also matches two legislative rows
   AND lower(d.state)    = 'or'
   AND d.official_web_url = r.old_url;

-- ── POST-VERIFY GATE ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_expected CONSTANT int := 12;
  v_settled  int;
  v_legacy   int;
  v_leaked   int;
  v_bad      int;
  v_plain    int;
  v_row      record;
BEGIN
  -- 1. END STATE: all 12 county rows hold exactly the intended value. Passes on a re-run.
  SELECT count(*) INTO v_settled
    FROM essentials.districts d
    JOIN (VALUES
      ('41003', 'https://www.bentoncountyor.gov/'),
      ('41009', 'https://www.columbiacountyor.gov/'),
      ('41013', 'https://www.crookcountyor.gov/'),
      ('41021', 'https://www.gilliamcountyor.gov/'),
      ('41023', 'https://www.grantcountyoregon.net/'),
      ('41025', 'https://harneycountyor.gov/'),
      ('41027', 'https://www.hoodrivercounty.gov/'),
      ('41039', 'https://www.lanecountyor.gov/'),
      ('41043', 'https://www.linncountyor.gov/'),
      ('41059', 'https://www.umatillacounty.gov/'),
      ('41065', 'https://www.wascocountyor.gov/'),
      ('41071', 'https://www.yamhillcounty.gov/')
    ) AS w(geo_id, url)
      ON w.geo_id = d.geo_id AND d.official_web_url = w.url
   WHERE d.district_type = 'COUNTY' AND lower(d.state) = 'or';

  IF v_settled <> v_expected THEN
    RAISE EXCEPTION 'expected % OR county rows to hold their new URL, found %', v_expected, v_settled;
  END IF;

  -- 2. None of the 12 still holds a retired host.
  SELECT count(*) INTO v_legacy
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or'
     AND geo_id IN ('41003','41009','41013','41021','41023','41025','41027','41039','41043','41059','41065','41071')
     AND (official_web_url ILIKE '%co.%.or.us%' OR official_web_url ILIKE '%gcoregonlive2%'
          OR official_web_url ILIKE '%lanecounty.org%' OR official_web_url ILIKE '%umatillacounty.net%');
  IF v_legacy <> 0 THEN
    RAISE EXCEPTION '% of the 12 rows still hold a retired host', v_legacy;
  END IF;

  -- 3. 🔴 THE COLLISION CHECK. Nothing leaked onto a non-county district sharing these geo_ids.
  SELECT count(*) INTO v_leaked
    FROM essentials.districts
   WHERE geo_id IN ('41003','41009','41013','41021','41023','41025','41027','41039','41043','41059','41065','41071')
     AND district_type <> 'COUNTY'
     AND official_web_url IS NOT NULL;
  IF v_leaked <> 0 THEN
    RAISE EXCEPTION 'geo_id collision: % non-COUNTY district(s) acquired an official_web_url', v_leaked;
  END IF;

  -- 4. None of the 12 rows THIS migration writes holds a destination the audit rejected.
  --
  -- 🔴 Scoped to those 12 on purpose. A first draft of this gate checked every OR county row and
  -- could never have passed: three rows this migration deliberately does NOT touch are *currently*
  -- storing rejected values -- Sherman holds the gambling squat `sherman-county.com` itself, and
  -- Union and Lake hold tourism sites. That is the backlog, not a failure of this change, and a gate
  -- that cannot go green until an unrelated 24 rows are fixed is a gate that gets disabled. The
  -- untouched rows are counted in the NOTICE below so the fact stays visible instead.
  SELECT count(*) INTO v_bad
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url IS NOT NULL
     AND geo_id IN ('41003','41009','41013','41021','41023','41025','41027','41039','41043','41059','41065','41071')
     AND (official_web_url ILIKE '%in.gov/counties/grant%'   -- Indiana
       OR official_web_url ILIKE '%lincolncountync%'          -- North Carolina
       OR official_web_url ILIKE '%shermancountyks%'          -- Kansas
       OR official_web_url ILIKE '%douglascounty.us%'         -- Minnesota / Wisconsin
       OR official_web_url ILIKE '%areaguides.com%'           -- Maryland
       OR official_web_url ILIKE '%washingtongov.org%'        -- Ohio
       OR official_web_url ILIKE '%sherman-county.com%'       -- gambling squat
       OR official_web_url ILIKE '%forsale.dynadot%'          -- parked
       OR official_web_url ILIKE '%hugedomains%'              -- parked
       OR official_web_url ILIKE '%cascadelandandhomes%'      -- real estate
       OR official_web_url ILIKE '%wallowamountainproperties%'
       OR official_web_url ILIKE '%grantcounty.org%'          -- tourism / chamber
       OR official_web_url ILIKE '%bentoncounty.com%'
       OR official_web_url ILIKE '%gilliamcounty.com%'
       OR official_web_url ILIKE '%hoodrivercounty.net%');
  IF v_bad <> 0 THEN
    RAISE EXCEPTION '% of the 12 repointed row(s) hold a rejected destination', v_bad;
  END IF;

  -- 5. Progress report, not a gate: what rot is left on the rows this migration leaves alone.
  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url LIKE 'http://%';

  RAISE NOTICE 'OK: % OR county rows repointed to https .gov (Grant to .net, no .gov exists).', v_expected;
  RAISE NOTICE 'No leak onto the 17 legislative districts sharing these geo_ids.';
  RAISE NOTICE '% OR county row(s) still hold a plain http:// URL -- the rows left for a human read.', v_plain;

  -- Name the untouched rows that are storing something actively wrong, so this never reads as done.
  FOR v_row IN
    SELECT geo_id, label, official_web_url
      FROM essentials.districts
     WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url IS NOT NULL
       AND geo_id NOT IN ('41003','41009','41013','41021','41023','41025','41027','41039','41043','41059','41065','41071')
       AND (official_web_url ILIKE '%sherman-county.com%'    -- gambling squat
         OR official_web_url ILIKE '%unioncounty.org%'        -- tourism / chamber
         OR official_web_url ILIKE '%lakecountyor.org%'       -- tourism
         OR official_web_url ILIKE '%wallowa.co.or.us%'       -- NXDOMAIN
         OR official_web_url ILIKE '%wheelercountyoregon.gov%')  -- NXDOMAIN; do NOT auto-repoint
     ORDER BY geo_id
  LOOP
    RAISE NOTICE 'STILL BROKEN, left on purpose: % % -> %', v_row.geo_id, v_row.label, v_row.official_web_url;
  END LOOP;
  RAISE NOTICE 'Wheeler (41069) must NOT be auto-applied -- its only candidate is a same-name .com.';
END $$;

COMMIT;
