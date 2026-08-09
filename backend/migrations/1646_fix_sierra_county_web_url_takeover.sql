-- 1646_fix_sierra_county_web_url_takeover.sql
--
-- Sierra County, CA (geo_id 06091): repoint districts.official_web_url away from an EXPIRED-DOMAIN
-- TAKEOVER and onto the county's real site.
--
-- ── 🔴 WHAT WAS STORED ─────────────────────────────────────────────────────────────────────────
-- migration 1619 imported "http://www.sierracounty.ws". The county no longer holds that domain.
-- As of 2026-08-09 it 301s to https://mampir123.org/, an unrelated site ("The mampir123") of the
-- kind that squats lapsed government domains. It answers HTTP 200 the whole way, so every
-- status-code check scores it as healthy -- this is the Sonoma failure (migration 1644, which
-- pointed at winecountry.com) in a worse form: Sonoma's landed on a real commercial brand, this one
-- lands on a domain nobody in the county controls. **A URL that resolves is not evidence that it
-- resolves to the county.**
--
-- Found by the 2026-08-09 sweep of all 58 CA county rows:
--   .planning/todos/2026-08-09-ca-county-url-rot.md
--   .planning/todos/data/2026-08-09-ca-county-url-sweep.tsv
-- Two of the 58 pointed at non-county sites; Sonoma was fixed in 1644 and this is the other one.
-- The remaining classes in that file (14 dead hosts, 13 possible-WAF 403s, 1 typo -- Lake County's
-- "www.w.co.lake.ca.us") are NOT touched here: the 403s need a browser check each, because a WAF
-- rejection is not a dead site. Do not bulk-replace them.
--
-- ── VERIFICATION OF THE REPLACEMENT ────────────────────────────────────────────────────────────
-- https://sierracounty.ca.gov/ returns HTTP 200 on the stored host with no cross-host redirect, and
-- the page is the county's: <title>Sierra County, CA - Official Website</title>, a CivicPlus county
-- site whose content is specific to this county (Downieville, Loyalton, Sierra Valley, Sierra
-- Buttes, Sierra County Waterworks District, Downieville Fire Protection District). It is also a
-- .ca.gov host, which is state-administered and cannot be registered by a squatter -- the precise
-- property the old .ws domain lacked. Checked 2026-08-09.
--
-- ── SCOPE ──────────────────────────────────────────────────────────────────────────────────────
-- Sierra County (pop. 3,200) has NO offices seeded and is not part of the countywide-officials
-- wave; this migration only repairs the URL. Scoped by district_type because geo_id is not unique
-- (1,159 collisions corpus-wide: a state-house district's synthesized geo_id can equal a county
-- FIPS). Guarded on END STATE, not on the delta, so re-running is a no-op.

BEGIN;

UPDATE essentials.districts d
   SET official_web_url = 'https://sierracounty.ca.gov/'
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06091'
   AND d.official_web_url IS DISTINCT FROM 'https://sierracounty.ca.gov/';

DO $$
DECLARE v_rows integer; v_url text;
BEGIN
  SELECT count(*) INTO v_rows FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06091';
  IF v_rows <> 1 THEN
    RAISE EXCEPTION 'Expected exactly 1 Sierra County district row, found %', v_rows;
  END IF;

  SELECT d.official_web_url INTO v_url FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06091';
  IF v_url IS DISTINCT FROM 'https://sierracounty.ca.gov/' THEN
    RAISE EXCEPTION 'Sierra official_web_url is %, expected https://sierracounty.ca.gov/', v_url;
  END IF;

  -- Nothing anywhere in the corpus should still point at the squatted domain.
  IF EXISTS (SELECT 1 FROM essentials.districts d
              WHERE d.official_web_url ILIKE '%sierracounty.ws%'
                 OR d.official_web_url ILIKE '%mampir123%') THEN
    RAISE EXCEPTION 'A district still points at the squatted sierracounty.ws / mampir123.org domain';
  END IF;
END $$;

COMMIT;
