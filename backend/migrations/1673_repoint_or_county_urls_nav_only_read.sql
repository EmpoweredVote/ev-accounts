-- 1673_repoint_or_county_urls_nav_only_read.sql
--
-- Repoints `official_web_url` for the last 5 routine Oregon county rows — the ones the audit flagged
-- `nav-only marker`, now read by hand and confirmed. Data-only; no schema change. Fourth of the
-- Oregon set after 1670 (12 clean), 1671 (6 scheme upgrades) and 1672 (9 WAF-caveat rows cleared).
-- Brings Oregon to 32 of 36.
--
-- ── WHY THESE WERE HELD BACK, AND WHY THAT WAS RIGHT ───────────────────────────────────────────
-- `nav-only marker` means the governing-body phrase was found in the page's NAVIGATION (anchor text
-- and hrefs) but not in its prose. That is genuinely weaker evidence than prose and it was flagged on
-- purpose — unlike the `WAF blocked a probe` caveat cleared in 1672, which turned out to be an
-- artefact of unit-scoped flagging. A link saying "Board of Commissioners" is not the same as a page
-- saying it, so these five were not batched. Each was read.
--
-- All five are the same vendor CMS, which is why they clustered: the homepage carries almost no body
-- text (Jefferson 311 chars, Morrow 482, Tillamook 661) and puts everything in navigation
-- (2,830-16,852 chars of links). The nav-only signal was describing the CMS, not the county.
--
-- ── THE READ: each county's OWN governing-body page, rendered, with prose ───────────────────────
-- Followed each site's own link to its board and confirmed the entity in PROSE on that subpage:
--
--   Jefferson  /countycommissioners  "County Commissioners | Jefferson County Oregon"
--              3,323 chars; names Commissioners Kelly Simmelink, Mark Wunsch, Seth Taylor.
--   Morrow     /boc                  "Board of Commissioners | Morrow County Oregon"      1,748 chars
--   Tillamook  /bocc/page/...        prose cites "the Board of Commissioners for Tillamook County
--              pursuant to ORS 203.045(3)" — a citation to Oregon Revised Statutes.        2,788 chars
--   Wallowa    /boc                  "Board of Commissioners | Wallowa County OR"         1,760 chars
--   Washington /bcc                  "Board of County Commissioners (BCC) | Washington County, OR"
--              1,539 chars: "Washington County is structured as a Council-Manager form of government,
--              giving the five-member Board of Commissioners legislative responsibility..."
--
-- All five homepage titles independently self-identify county AND state ("Home Page | Jefferson
-- County Oregon", "Washington County, OR", ...), and all five were state-confirmed by the auditor.
--
-- 🔴 Washington nearly failed this read for a tooling reason, not a data one: the first link-matcher
-- looked for "Board of Commissioners" and missed `/bcc`, whose anchor text is "Board of COUNTY
-- Commissioners" — an infix the pattern did not allow. Same shape as the bug where no candidate
-- hostname spelled the state out. When a scan of a government site finds NO governing body, suspect
-- the pattern before concluding anything about the site.
--
-- ── 🔴 WALLOWA (41063) IS NOT THE NAMESPACE MOVE — IT IS A TRANSPOSED HOSTNAME ──────────────────
-- Every other county in this Oregon set moved off `co.<name>.or.us`. Wallowa moves ONTO it, which
-- looks backwards until you check: all eleven `.gov` variants are NXDOMAIN
-- (wallowacounty.or.gov, wallowacountyor.gov, countyofwallowa.gov, wallowa.or.gov,
-- wallowacountyoregon.gov, ...), and `co.wallowa.or.us` is the only host that resolves and verifies.
-- Wallowa genuinely still lives on the legacy state namespace. The stored value
-- `wallowa.co.or.us` has its first two labels TRANSPOSED and has never resolved — this is a typo
-- fix, in the same family as Lake County's `www.w.co.lake.ca.us` in 1667, not a namespace decision.
--
-- Wallowa also carried a `name-ambiguous host` flag, which is a tool artefact: the COUNTY
-- disambiguation test accepts a host starting `co.` but the host is `www.co.wallowa.or.us`, so the
-- `^co\.` anchor misses it past the `www.` prefix. Not a fact about the row.
--
-- ── 🔴 SAME geo_id COLLISION GUARD AS 1670/1671/1672 ───────────────────────────────────────────
-- `41031` is Jefferson County AND State House District 31. Across these 5 geo_ids there are 8 rows,
-- 5 of them counties; the 3 legislative rows carry `official_web_url IS NULL` and nothing constrains
-- that column. Scoped `district_type = 'COUNTY' AND lower(state) = 'or'`.
--
-- Idempotent: compare-and-swap on the exact value measured; the gate asserts END STATE.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

WITH repoint(geo_id, old_url, new_url) AS (
  VALUES
    ('41031', 'http://www.co.jefferson.or.us',      'https://www.jeffersoncountyor.gov/'),
    ('41049', 'http://www.morrowcountyoregon.com/', 'https://www.morrowcountyor.gov/'),
    ('41057', 'http://www.co.tillamook.or.us/',     'https://www.tillamookcounty.gov/'),
    ('41067', 'http://www.co.washington.or.us',     'https://www.washingtoncountyor.gov/'),
    -- transposed hostname, never resolved; the county really is on the legacy namespace
    ('41063', 'http://www.wallowa.co.or.us',        'https://www.co.wallowa.or.us/')
)
UPDATE essentials.districts d
   SET official_web_url = r.new_url
  FROM repoint r
 WHERE d.geo_id           = r.geo_id
   AND d.district_type    = 'COUNTY'        -- 🔴 without this, 41031 also matches a legislative row
   AND lower(d.state)     = 'or'
   AND d.official_web_url = r.old_url;

-- ── POST-VERIFY GATE ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_expected CONSTANT int := 5;
  v_settled  int;
  v_leaked   int;
  v_bad      int;
  v_https    int;
  v_plain    int;
  v_row      record;
BEGIN
  -- 1. END STATE. Passes on a re-run.
  SELECT count(*) INTO v_settled
    FROM essentials.districts d
    JOIN (VALUES
      ('41031', 'https://www.jeffersoncountyor.gov/'),
      ('41049', 'https://www.morrowcountyor.gov/'),
      ('41057', 'https://www.tillamookcounty.gov/'),
      ('41063', 'https://www.co.wallowa.or.us/'),
      ('41067', 'https://www.washingtoncountyor.gov/')
    ) AS w(geo_id, url)
      ON w.geo_id = d.geo_id AND d.official_web_url = w.url
   WHERE d.district_type = 'COUNTY' AND lower(d.state) = 'or';

  IF v_settled <> v_expected THEN
    RAISE EXCEPTION 'expected % OR county rows to hold their new URL, found %', v_expected, v_settled;
  END IF;

  -- 2. The transposed Wallowa host must be gone. It never resolved, so it must never return.
  IF EXISTS (SELECT 1 FROM essentials.districts
              WHERE district_type = 'COUNTY' AND lower(state) = 'or'
                AND official_web_url ILIKE '%wallowa.co.or.us%') THEN
    RAISE EXCEPTION 'the transposed host wallowa.co.or.us is still stored';
  END IF;

  -- 3. 🔴 THE NEAR-MISSES across this whole Oregon wave. Each verified against a real county
  --    governing body while being the WRONG STATE, a squat, or a tourism site.
  SELECT count(*) INTO v_bad
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url IS NOT NULL
     AND (official_web_url ILIKE '%jacksongov.org%'        -- Jackson County MISSOURI
       OR official_web_url ILIKE '%shermancountyks%'        -- Sherman County KANSAS
       OR official_web_url ILIKE '%currycountynm%'          -- Curry County NEW MEXICO
       OR official_web_url ILIKE '%lincolncountync%'        -- Lincoln County NORTH CAROLINA
       OR official_web_url ILIKE '%in.gov/counties/grant%'  -- Grant County INDIANA
       OR official_web_url ILIKE '%douglascounty.us%'       -- MINNESOTA / WISCONSIN
       OR official_web_url ILIKE '%washingtongov.org%'      -- OHIO
       OR official_web_url ILIKE '%areaguides.com%'         -- MARYLAND
       OR official_web_url ILIKE '%sherman-county.com%'     -- gambling squat
       OR official_web_url ILIKE '%unioncounty.org%'        -- tourism / chamber
       OR official_web_url ILIKE '%forsale.godaddy%'
       OR official_web_url ILIKE '%forsale.dynadot%'
       OR official_web_url ILIKE '%hugedomains%');
  IF v_bad <> 0 THEN
    RAISE EXCEPTION '% OR county row(s) hold a rejected destination', v_bad;
  END IF;

  -- 4. 🔴 COLLISION CHECK.
  SELECT count(*) INTO v_leaked
    FROM essentials.districts
   WHERE geo_id IN ('41031','41049','41057','41063','41067')
     AND district_type <> 'COUNTY'
     AND official_web_url IS NOT NULL;
  IF v_leaked <> 0 THEN
    RAISE EXCEPTION 'geo_id collision: % non-COUNTY district(s) acquired an official_web_url', v_leaked;
  END IF;

  -- 5. Progress, not a gate.
  SELECT count(*) INTO v_https
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url LIKE 'https://%';
  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url LIKE 'http://%';

  RAISE NOTICE 'OK: % OR county rows repointed after a hand read of each governing-body page.', v_expected;
  RAISE NOTICE 'Oregon counties now: % on https, % still on http (of 36).', v_https, v_plain;

  FOR v_row IN
    SELECT geo_id, label, official_web_url
      FROM essentials.districts
     WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url LIKE 'http://%'
     ORDER BY geo_id
  LOOP
    RAISE NOTICE 'REMAINING: % % -> %', v_row.geo_id, v_row.label, v_row.official_web_url;
  END LOOP;
  RAISE NOTICE 'Wheeler (41069) must NOT be auto-applied -- its only candidate is a same-name .com.';
  RAISE NOTICE 'Baker / Klamath: no destination verified; they are a reading queue, not a delete queue.';
END $$;

COMMIT;
