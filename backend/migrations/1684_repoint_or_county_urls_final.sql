-- 1684_repoint_or_county_urls_final.sql
--
-- The last 4 rows on plain http anywhere in `essentials.districts`. After this, **every
-- official_web_url in the table is an https site root** -- 349 rows across CA and OR, closed by
-- migrations 1667 and 1670-1683. Data-only; no schema change.
--
-- ── 🔴🔴 WHEELER COUNTY: I REFUSED THIS ROW IN 1672 AND 1673, AND I WAS WRONG ──────────
-- Both migrations recorded that Wheeler must NOT be auto-repointed, on this reasoning: its stored
-- `wheelercountyoregon.gov` is NXDOMAIN and the only candidate found was the same name on `.com`,
-- which is "the Sierra County shape -- a lapsed registration answering on a cheaper namespace".
--
-- That was a shape argument applied without checking the value, which is the exact failure this
-- series keeps warning about. What is actually true:
--   * The stored `.gov` was never a lapsed county site. It does not resolve and there is no evidence
--     it ever did; the county's REGISTERED .gov is `wheelercountyor.gov` (`or`, not `oregon`) --
--     the same abbreviated-vs-spelled-out variance that broke Forest Grove and Tigard in 1683.
--   * 🔴 AND `wheelercountyor.gov` DOES NOT RESOLVE EITHER -- not bare, not `www`, not http. It is
--     listed in the CISA registry with no working DNS. **Registry ownership does not even guarantee
--     the domain resolves**, which is a harder limit than "owning a .gov is not serving from it"
--     (1676, where Hawthorne's returned 522 and Paramount's timed out -- those at least resolved).
--   * `wheelercountyoregon.com` is the county's own current site. Its `/county-court` page reads:
--     "The Wheeler County Court sets policy and manages the business affairs of the County, including
--     apportioning and levying taxes, and overseeing the organization and budgeting of all County
--     programs." A County Court IS Oregon's statutory governing body for a small county. The site also
--     carries County Resolutions & Ordinances, Public Records Requests, ORS citations, and names
--     Fossil, the county seat. A squat serves gambling, pharma or a parked lander -- Sherman County's
--     did, and that is what the Sierra comparison was reaching for. This serves county ordinances.
--
-- The heuristic fired on the PATTERN (dead .gov -> same-name .com) and never asked what the .com
-- contained. Refusing was the safe default at the time and cost nothing but a delay; recording the
-- refusal as a standing rule in two migrations was the error, because it turned one unverified
-- inference into settled doctrine.
--
-- ── LAKE COUNTY: NOT A REPOINT, AND NOT TOURISM ────────────────────────────
-- 1672 and 1676 listed Lake as "STILL BROKEN -- tourism". Its prose is recreation-led, which is
-- ordinary for a rural county, and the auditor's NOT_GOVERNMENT verdict was driven by that prose with
-- only a nav-level government marker to counter it -- deliberately not enough under the rule set in
-- 1674. Read properly, its navigation carries `/government/county_commissioners/` and NAMES SITTING
-- COMMISSIONERS (Barry Shullanberger, James Williams). It is the county's site. No .gov is registered
-- to Lake County OR -- and the registry lists a dozen other states' Lake Counties that must never be
-- substituted -- so the host stays and takes only the scheme.
--
-- ── BAKER AND KLAMATH ──────────────────────────────────────────────────────
-- Both were NAME_ONLY: their stored `.org` redirects to a `<name>countyor.gov` that named the county
-- but showed no governing body. Baker now verifies fully (200, "Baker County - Official Website",
-- commissioners in prose AND nav, a /commissioners/ page). Klamath still shows no governing body in
-- either prose or nav, so its identity rests on the administered namespace plus a self-identifying
-- title, "Klamath County, OR | Official Website" -- recorded plainly rather than dressed up.
--
-- ── BASIS FOR EVERY ROW ───────────────────────────────────────────────────
--   Baker    REPOINT  registry: County | Baker County | Baker City, OR. Rendered 200 "Baker County - Official Website" with the governing body in PROSE and NAV and a /commissioners/ page
--   Klamath  REPOINT  registry: County | Klamath County | Klamath Falls, OR. Rendered 200, 5379 chars, title "Klamath County, OR | Official Website". Governing body absent from the homepage in both prose and nav -- identity rests on the administered namespace plus the self-identifying title
--   Lake     SCHEME   host unchanged. Nav carries /government/county_commissioners/ and NAMES sitting commissioners (Barry Shullanberger, James Williams). NO .gov is registered to Lake County OR
--   Wheeler  REPOINT  operator confirmed. /county-court reads "The Wheeler County Court sets policy and manages the business affairs of the County, including apportioning and levying taxes" -- Oregon statutory county governing body; also County Resolutions & Ordinances, Public Records Requests, ORS citations, names Fossil (the county seat)
--
-- Idempotent: compare-and-swap on the exact value measured; the gate asserts END STATE.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

WITH repoint(geo_id, old_url, new_url) AS (
  VALUES
    ('41001', 'http://www.bakercounty.org',           'https://www.bakercountyor.gov/'        ),  -- Baker (REPOINT)
    ('41035', 'http://www.klamathcounty.org',         'https://www.klamathcountyor.gov/'      ),  -- Klamath (REPOINT)
    ('41037', 'http://www.lakecountyor.org/',         'https://www.lakecountyor.org/'         ),  -- Lake (SCHEME)
    ('41069', 'http://www.wheelercountyoregon.gov',   'https://www.wheelercountyoregon.com/'  )  -- Wheeler (REPOINT)
)
UPDATE essentials.districts d
   SET official_web_url = r.new_url
  FROM repoint r
 WHERE d.geo_id           = r.geo_id
   AND d.district_type    = 'COUNTY'
   AND lower(d.state)     = 'or'
   AND d.official_web_url = r.old_url;

-- ── POST-VERIFY GATE ──────────────────────────────────────────────────────
DO $$
DECLARE
  v_rows  CONSTANT int := 4;
  v_settled int;
  v_http    int;
  v_root    int;
  v_dead    int;
  v_leaked  int;
  v_total   int;
BEGIN
  SELECT count(*) INTO v_settled
    FROM essentials.districts d
    JOIN (VALUES
      ('41001', 'https://www.bakercountyor.gov/'),
      ('41035', 'https://www.klamathcountyor.gov/'),
      ('41037', 'https://www.lakecountyor.org/'),
      ('41069', 'https://www.wheelercountyoregon.com/')
    ) AS w(geo_id, url)
      ON w.geo_id = d.geo_id AND d.official_web_url = w.url
   WHERE d.district_type = 'COUNTY' AND lower(d.state) = 'or';
  IF v_settled <> v_rows THEN
    RAISE EXCEPTION 'expected % rows settled, found %', v_rows, v_settled;
  END IF;

  -- 🔴 THE CLOSING ASSERTION FOR THE WHOLE PROGRAMME: no http and no non-root anywhere in the table.
  SELECT count(*) INTO v_http FROM essentials.districts WHERE official_web_url LIKE 'http://%';
  IF v_http <> 0 THEN
    RAISE EXCEPTION '% row(s) still on plain http table-wide', v_http;
  END IF;

  SELECT count(*) INTO v_root
    FROM essentials.districts
   WHERE official_web_url IS NOT NULL AND official_web_url !~ '^https://[^/]+/$';
  IF v_root <> 0 THEN
    RAISE EXCEPTION '% row(s) are not a bare https://<host>/ root', v_root;
  END IF;

  -- 🔴 Every .gov hostname this programme proved does not resolve. All look plausible, which is why
  --    they need a gate rather than a convention.
  SELECT count(*) INTO v_dead
    FROM essentials.districts
   WHERE official_web_url IS NOT NULL
     AND (official_web_url ILIKE '%wheelercountyoregon.gov%'   -- never resolved
       OR official_web_url ILIKE '%wheelercountyor.gov%'       -- registered, no DNS
       OR official_web_url ILIKE '%forestgroveor.gov%'         -- missing hyphen (1683)
       OR official_web_url ILIKE '%tigardor.gov%'              -- missing hyphen (1683)
       OR official_web_url ILIKE '%hawthorneca.gov%'           -- 522 (1676)
       OR official_web_url ILIKE '%paramountcity.gov%');       -- timeout (1676)
  IF v_dead <> 0 THEN
    RAISE EXCEPTION '% row(s) hold a .gov that does not serve', v_dead;
  END IF;

  -- 🔴 Other states' Lake Counties must never land on Oregon's row.
  --
  -- 🔴🔴 NOTE THE `[.]` INSTEAD OF `\.` — AND WHY EVERY REGEX HERE USES IT.
  -- This gate is written `[.]` because `\.` does not survive the layers between a generator script and
  -- Postgres. Six guards in migrations 1675, 1676, 1679, 1680 and 1683 were generated with a DOUBLED
  -- backslash and reached the database as `\\.`, which matches a literal backslash and therefore
  -- matches NOTHING. Every one of them was a POSITIVE guard (`count(*) = 0` expected), so a pattern
  -- that can never match reports zero, the gate passes, and the migration looks verified. **A broken
  -- positive guard is worse than no guard: it reads as protection and provides none.** The affected
  -- checks were the city-points-at-a-county test (1675, 1676, 1679, 1683), the Oregon-church test
  -- (1680) and the two never-resolving `.gov` hostnames (1683). This migration re-asserts all of them
  -- below in a form that cannot break. The DATA was never wrong — end state was verified directly by
  -- query after each apply — only the future-regression guards were inert.
  SELECT count(*) INTO v_leaked
    FROM essentials.districts
   WHERE geo_id = '41037' AND official_web_url IS NOT NULL
     AND official_web_url !~* 'lakecountyor[.]org';
  IF v_leaked <> 0 THEN
    RAISE EXCEPTION 'Lake County OR points somewhere unexpected (% row)', v_leaked;
  END IF;

  -- ── RE-ASSERTED GUARDS THAT WERE INERT IN 1675/1676/1679/1680/1683 ──────
  -- 1. No city row may point at a county site (the inverted discriminator, both states).
  SELECT count(*) INTO v_leaked
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND official_web_url IS NOT NULL
     AND (official_web_url ~* '^https?://(www[.])?co[.]'
       OR official_web_url ILIKE '%lacounty%' OR official_web_url ILIKE '%countyof%'
       OR official_web_url ILIKE '%multco%');
  IF v_leaked <> 0 THEN
    RAISE EXCEPTION '% city row(s) point at a COUNTY site', v_leaked;
  END IF;

  -- 2. The out-of-state church one hyphen from Rolling Hills, CA (1680).
  SELECT count(*) INTO v_leaked
    FROM essentials.districts
   WHERE official_web_url IS NOT NULL
     AND official_web_url ~* '^https?://(www[.])?rollinghills[.]org';
  IF v_leaked <> 0 THEN
    RAISE EXCEPTION '% row(s) point at Rolling Hills Community Church, Tualatin OREGON', v_leaked;
  END IF;

  -- 3. Every .gov this programme proved does not serve. All of them look plausible.
  SELECT count(*) INTO v_dead
    FROM essentials.districts
   WHERE official_web_url IS NOT NULL
     AND (official_web_url ~* 'forestgroveor[.]gov'        -- missing hyphen, NXDOMAIN (1683)
       OR official_web_url ~* 'tigardor[.]gov'             -- missing hyphen, NXDOMAIN (1683)
       OR official_web_url ~* 'wheelercountyoregon[.]gov'  -- never resolved
       OR official_web_url ~* 'wheelercountyor[.]gov'      -- in the CISA registry, no DNS
       OR official_web_url ~* 'hawthorneca[.]gov'          -- HTTP 522 (1676)
       OR official_web_url ~* 'paramountcity[.]gov');      -- connection timeout (1676)
  IF v_dead <> 0 THEN
    RAISE EXCEPTION '% row(s) hold a .gov that does not serve', v_dead;
  END IF;

  SELECT count(*) INTO v_total FROM essentials.districts WHERE official_web_url IS NOT NULL;

  RAISE NOTICE 'OK: the last % http rows are gone. ALL % official_web_url values in this table are', v_rows, v_total;
  RAISE NOTICE 'now a bare https site root -- CA 289 rows, OR 60 rows, closed by 1667 and 1670-1684.';
  RAISE NOTICE '🔴 Wheeler: 1672 and 1673 recorded a standing refusal to repoint this row. That was';
  RAISE NOTICE 'wrong -- a shape argument (dead .gov -> same-name .com = squat) applied without reading';
  RAISE NOTICE 'the .com, which serves the County Court, ordinances and ORS citations.';
  RAISE NOTICE '🔴 wheelercountyor.gov is IN the CISA registry with NO working DNS -- registry ownership';
  RAISE NOTICE 'does not even guarantee a domain resolves.';
  RAISE NOTICE 'Lake was listed as "tourism" in 1672/1676; its nav names sitting commissioners.';
END $$;

COMMIT;
