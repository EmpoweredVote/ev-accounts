-- 1671_upgrade_or_county_web_url_scheme.sql
--
-- Upgrades `official_web_url` from `http://` to `https://` on the 6 Oregon county rows whose HOST is
-- already correct. Data-only; no schema change. Companion to 1670, which repointed the 12 counties
-- that had moved host. Together those cover 18 of Oregon's 36 counties.
--
-- ── WHY THIS IS THE LOW-RISK CLASS ─────────────────────────────────────────────────────────────
-- Every other row in this backlog asks "is this the right entity?", which is the hard question and
-- the one that produced a recommendation for Grant County INDIANA and Lincoln County NORTH CAROLINA
-- during the audit. These 6 do not ask it. The registrable host does not change, so whatever entity
-- `www.clackamas.us` is, `https://www.clackamas.us/` is the same entity. Only liveness is in
-- question, and all 6 were rendered and verified on 2026-08-10 (re-confirmed immediately before this
-- migration was written; all 6 reproduced identically).
--
-- ── 🔴 SAME geo_id COLLISION AS 1670. SCOPE BY district_type. ──────────────────────────────────
-- Oregon county FIPS codes collide with its legislative district numbering: `41005` is Clackamas
-- County AND `State House District 5` AND `State Senate District 5`. Across these 6 geo_ids there
-- are 14 rows, only 6 of them counties; the 8 legislative rows carry `official_web_url IS NULL` and
-- nothing constrains that column, so an unscoped UPDATE would stamp a county homepage onto them
-- silently. Every statement is scoped `district_type = 'COUNTY' AND lower(state) = 'or'`.
--
-- ── 🔴 THREE OF THESE ALSO CHANGE `www`, AND THAT NEEDED DECIDING PER ROW ───────────────────────
-- `www` is part of the hostname, so "scheme-only" was not quite true of all six. Split by what the
-- SITE says, not by what looked tidy:
--
--   FOLLOWS THE SITE'S OWN CANONICAL REDIRECT (www dropped because the site drops it):
--     Coos       www.co.coos.or.us -> co.coos.or.us    (https on the www form 301s to the bare host)
--     Multnomah  www.multco.us     -> multco.us        (ditto)
--
--   SCHEME ONLY, HOST BYTE-FOR-BYTE UNCHANGED:
--     Clackamas  www.clackamas.us
--     Lincoln    www.co.lincoln.or.us
--     Malheur    www.malheurco.org
--     Marion     co.marion.or.us
--
-- 🔴 Marion is in the second group as a CORRECTION to the audit's own recommendation, which was
-- `https://www.co.marion.or.us/` -- i.e. it wanted to ADD `www`. Both `co.marion.or.us` and
-- `www.co.marion.or.us` serve independently and verify; the `www` form won only on the +3 bonus
-- `score()` gives a `www.` prefix when breaking ties among already-verified hosts. That is a
-- cosmetic ranking artefact, not a canonical signal, and the same audit had already demonstrated
-- (Jackson County: `jacksongov.org`, MISSOURI, beaten only because score() prefers `.gov`) that
-- ranking is the wrong instrument for deciding what a hostname should be. The stored host works;
-- it keeps its form and gains only the scheme.
--
-- ── WHY `https` IS WORTH A MIGRATION AT ALL ────────────────────────────────────────────────────
-- These URLs are voter-facing. A stored `http://` sends a reader to a plaintext redirect hop before
-- landing on the county's real site, and any of these hosts could stop answering on port 80 at any
-- time -- at which point the row is simply broken, with no error anywhere in this system to say so.
--
-- Idempotent: compare-and-swap on the exact value measured, so a second run matches 0 rows, and the
-- gate asserts END STATE rather than the delta.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

WITH upgrade(geo_id, old_url, new_url) AS (
  VALUES
    -- scheme only, host unchanged
    ('41005', 'http://www.clackamas.us',       'https://www.clackamas.us/'),
    ('41041', 'http://www.co.lincoln.or.us/',  'https://www.co.lincoln.or.us/'),
    ('41045', 'http://www.malheurco.org/',     'https://www.malheurco.org/'),
    ('41047', 'http://co.marion.or.us/',       'https://co.marion.or.us/'),
    -- scheme + the site's own canonical redirect drops `www`
    ('41011', 'http://www.co.coos.or.us/',     'https://co.coos.or.us/'),
    ('41051', 'http://www.multco.us',          'https://multco.us/')
)
UPDATE essentials.districts d
   SET official_web_url = u.new_url
  FROM upgrade u
 WHERE d.geo_id           = u.geo_id
   AND d.district_type    = 'COUNTY'        -- 🔴 without this, 41005 also matches two legislative rows
   AND lower(d.state)     = 'or'
   AND d.official_web_url = u.old_url;

-- ── POST-VERIFY GATE ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_expected CONSTANT int := 6;
  v_settled  int;
  v_plain    int;
  v_leaked   int;
  v_host     int;
  v_or_https int;
  v_row      record;
BEGIN
  -- 1. END STATE: all 6 hold exactly the intended value. Passes on a re-run.
  SELECT count(*) INTO v_settled
    FROM essentials.districts d
    JOIN (VALUES
      ('41005', 'https://www.clackamas.us/'),
      ('41011', 'https://co.coos.or.us/'),
      ('41041', 'https://www.co.lincoln.or.us/'),
      ('41045', 'https://www.malheurco.org/'),
      ('41047', 'https://co.marion.or.us/'),
      ('41051', 'https://multco.us/')
    ) AS w(geo_id, url)
      ON w.geo_id = d.geo_id AND d.official_web_url = w.url
   WHERE d.district_type = 'COUNTY' AND lower(d.state) = 'or';

  IF v_settled <> v_expected THEN
    RAISE EXCEPTION 'expected % OR county rows to hold their https URL, found %', v_expected, v_settled;
  END IF;

  -- 2. None of the 6 is still on http.
  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or'
     AND geo_id IN ('41005','41011','41041','41045','41047','41051')
     AND official_web_url LIKE 'http://%';
  IF v_plain <> 0 THEN
    RAISE EXCEPTION '% of the 6 rows are still on plain http', v_plain;
  END IF;

  -- 3. 🔴 THE POINT OF THIS MIGRATION: the registrable host must NOT have changed. This is what
  --    separates this change from 1670 -- if a host moved here, something wrote the wrong thing.
  SELECT count(*) INTO v_host
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or'
     AND geo_id IN ('41005','41011','41041','41045','41047','41051')
     AND official_web_url NOT IN (
       'https://www.clackamas.us/', 'https://co.coos.or.us/', 'https://www.co.lincoln.or.us/',
       'https://www.malheurco.org/', 'https://co.marion.or.us/', 'https://multco.us/');
  IF v_host <> 0 THEN
    RAISE EXCEPTION '% row(s) hold an unexpected host -- a repoint leaked into a scheme upgrade', v_host;
  END IF;

  -- 4. 🔴 COLLISION CHECK. Nothing leaked onto a legislative district sharing these geo_ids.
  SELECT count(*) INTO v_leaked
    FROM essentials.districts
   WHERE geo_id IN ('41005','41011','41041','41045','41047','41051')
     AND district_type <> 'COUNTY'
     AND official_web_url IS NOT NULL;
  IF v_leaked <> 0 THEN
    RAISE EXCEPTION 'geo_id collision: % non-COUNTY district(s) acquired an official_web_url', v_leaked;
  END IF;

  -- 5. Progress, not a gate.
  SELECT count(*) INTO v_or_https
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url LIKE 'https://%';
  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url LIKE 'http://%';

  RAISE NOTICE 'OK: % OR county rows upgraded to https on an unchanged host.', v_expected;
  RAISE NOTICE 'No leak onto the 8 legislative districts sharing these geo_ids.';
  RAISE NOTICE 'Oregon counties now: % on https, % still on http (of 36).', v_or_https, v_plain;

  -- The rows still storing something actively wrong. Named every run so this cannot read as done.
  FOR v_row IN
    SELECT geo_id, label, official_web_url
      FROM essentials.districts
     WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url IS NOT NULL
       AND (official_web_url ILIKE '%sherman-county.com%'       -- gambling squat
         OR official_web_url ILIKE '%unioncounty.org%'           -- tourism / chamber
         OR official_web_url ILIKE '%lakecountyor.org%'          -- tourism
         OR official_web_url ILIKE '%wallowa.co.or.us%'          -- NXDOMAIN
         OR official_web_url ILIKE '%wheelercountyoregon.gov%')  -- NXDOMAIN; do NOT auto-repoint
     ORDER BY geo_id
  LOOP
    RAISE NOTICE 'STILL BROKEN, left on purpose: % % -> %', v_row.geo_id, v_row.label, v_row.official_web_url;
  END LOOP;
  RAISE NOTICE 'Wheeler (41069) must NOT be auto-applied -- its only candidate is a same-name .com.';
END $$;

COMMIT;
