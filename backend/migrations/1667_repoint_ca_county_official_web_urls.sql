-- 1667_repoint_ca_county_official_web_urls.sql
--
-- Repoints `official_web_url` for 45 of California's 58 county districts. Data-only; no schema
-- change. The 13 untouched rows are the ones the CA county wave already repointed as it went
-- (1639 Ventura, 1644 Sonoma, 1645 Tulare, 1646 Sierra, 1650 Solano, 1656 Monterey, 1660 Merced,
-- 1662 San Luis Obispo, 1663 Santa Cruz, 1666 Marin) plus Placer, Sacramento and Santa Barbara,
-- which were already correct.
--
-- ── WHY ────────────────────────────────────────────────────────────────────────────────────────
-- Every CA county URL came from the migration-1619 import and most were never revisited: 45 of 58
-- still held a plain `http://` URL, and many pointed at `co.<county>.ca.us` legacy hosts that have
-- since been retired. Measured 2026-08-10: 12 hosts do not resolve at all (NXDOMAIN or connection
-- failure) and one -- Lake County's `http://www.w.co.lake.ca.us` -- is a literal `www.w.` typo that
-- has never resolved. This is the same rot that produced the two non-county URLs already fixed:
-- Sonoma's `sonomacounty.org` pointed at **winecountry.com**, a commercial tourism site (1644), and
-- Sierra's `sierracounty.ws` had been picked up as an **expired-domain squat serving "The
-- mampir123"** (1646).
--
-- ── 🔴🔴 THE HARD PART IS NOT LIVENESS, IT IS IDENTITY ─────────────────────────────────────────
-- A URL that resolves is not evidence that it resolves to the county. Two automated rankings were
-- built and **both produced dangerous recommendations, in opposite directions**:
--   * Ranking by government TLD recommended **www.sandiego.gov for San Diego County** and
--     **www.monterey.gov for Monterey County** -- the CITIES, not the counties.
--   * Correcting that by preferring a hostname containing "county" then recommended
--     **orangecounty.net** (a "Visitor and Community Guide") and **sanfranciscocounty.us** (a
--     611-byte shell) -- because "county" in a hostname is exactly what a tourism site or a
--     squatter also has. That is the Sierra `.ws` lesson restated.
-- So no destination in this migration was chosen by a ranking function. Each was read.
--
-- **The discriminator that works in California: a COUNTY is governed by a BOARD OF SUPERVISORS; a
-- CITY is governed by a CITY COUNCIL.** Requiring "board of supervisors" (or a title that names the
-- county) on the RENDERED page, and rejecting anything that self-identifies as a city, separates
-- sandiegocounty.gov from sandiego.gov and countyofmonterey.gov from monterey.gov.
--
-- Rejected destinations, recorded because they are the whole point of the exercise:
--   www.sandiego.gov (City of San Diego) · www.monterey.gov (City of Monterey) ·
--   www.orangecounty.net (commercial visitor guide) · plumascounty.org (tourism) ·
--   sanfranciscocounty.us (611-byte shell) · lakecounty.com (tourism) ·
--   losangelescounty.com (business directory) · www.slocal.com (tourism board) ·
--   sierracounty.ws (squat, already fixed in 1646).
-- The post-verify gate below fails if any of these is ever stored on a CA county row.
--
-- ── 🔴 A CHEAP CHECK IS NOT A CORRECT CHECK -- THREE DETECTOR FAILURES WORTH REMEMBERING ───────
-- 1. A raw-HTML (curl) classifier called **Sierra County NOT_COUNTY** and **Santa Barbara EMPTY**.
--    Both are correct county sites; their government vocabulary is in client-rendered nav. Judging
--    a county site from unrendered HTML produces false negatives. Everything here was rendered.
-- 2. Headless Chromium is itself blocked by some WAFs with a hard "Access Denied" on every path --
--    Amador, Kern, Kings, Madera, Mendocino, San Benito, Sutter, Yolo all returned ~200 bytes to
--    headless while rendering perfectly in a normal browser profile. Those eight were confirmed
--    by hand in a real browser (titles: "Amador County | Home", "Kern County, CA | Home",
--    "Kings County | Home", "Madera County | Home", "Mendocino County, CA | Home",
--    "San Benito County, CA | Home", "Sutter County, CA | Home", "Yolo County | Home").
-- 3. **Derived hostname patterns miss counties that brand differently.** Humboldt's site is
--    `humboldtgov.org` -- no pattern of the form <name>county.<tld> or countyof<name>.<tld> finds
--    it. It was found only by hand, and then confirmed hardest of any row: 69,673 characters with
--    a Board of Supervisors. Assume the generated candidate list has holes.
--
-- ── 🔴 TWO BARE PLACE-NAME `.gov` HOSTS NEEDED SPECIFIC DISAMBIGUATION ─────────────────────────
-- `yuba.gov` and `sutter.gov` are the riskiest-looking rows here, because **Yuba City is in SUTTER
-- county** -- so either host could plausibly have been a city, or the wrong county. Both were opened
-- and read: `yuba.gov` renders "Welcome to Yuba County CALIFORNIA" with a Board of Supervisors and
-- no city council; `sutter.gov` renders "Sutter County, CA | Home" likewise. `tehama.gov` was
-- checked the same way ("Tehama County | Welcome to the Tehama County Website!"). Confirmed, not
-- assumed from the name.
--
-- ── PREFERENCE ORDER APPLIED ───────────────────────────────────────────────────────────────────
-- 1. A verified `.gov` / `.ca.gov` host wins. The namespace is administered, so a lapsed
--    registration cannot be picked up by a squatter -- precisely what Sierra's `.ws` lacked.
-- 2. A non-`.gov` host is used only where the county genuinely has no `.gov` and the host verifies:
--    calaverasgov.us, co.del-norte.ca.us, imperialcounty.org, inyocounty.us, kerncounty.com,
--    maderacounty.com, ocgov.com, plumascounty.us, smcgov.org, stancounty.com, countyofglenn.net,
--    humboldtgov.org.
-- 3. `http://` -> `https://` on the same host is always taken.
--
-- 🔴 **GLENN IS THE ONE ROW WHOSE CONTENT COULD NOT BE VERIFIED.** `countyofglenn.net` sits behind a
-- Cloudflare interstitial that never cleared, in headless or in a real profile. Its change here is
-- therefore **scheme-only** -- same host, `http` -> `https`, which is risk-neutral because a
-- compromised host would be equally bad under either scheme -- and it is listed in the follow-up
-- queue rather than claimed as verified. It is the only row in this migration not read directly.
--
-- ── 🔴 geo_id COLLISIONS ───────────────────────────────────────────────────────────────────────
-- CA county geo_ids collide with synthesized STATE_LOWER (Assembly) geo_ids of the form
-- <state FIPS>||<3-digit district number>: 06041 is both Marin County and Assembly District 41,
-- 06075 both San Francisco County and AD-75, and so on. Every predicate below is scoped by
-- `district_type='COUNTY' AND lower(state)='ca'`, and the gate asserts no non-COUNTY district's
-- official_web_url was modified.
--
-- Idempotent: each row updates only when the stored value differs, so re-running is a no-op.

BEGIN;

CREATE TEMP TABLE _url (geo_id text PRIMARY KEY, county text, new_url text, verified text) ON COMMIT DROP;

INSERT INTO _url VALUES
  ('06001','Alameda',        'https://www.alamedacountyca.gov/',   'rendered: "Home | Alameda County Government"; stored co.alameda.ca.us is DEAD'),
  ('06003','Alpine',         'https://www.alpinecountyca.gov/',    'rendered: "Alpine County, CA - Official Website"; http->https, same .gov host'),
  ('06005','Amador',         'https://www.amadorcounty.gov/',      'real browser: "Amador County | Home"; .gov, reached by redirect from co.amador.ca.us'),
  ('06007','Butte',          'https://www.buttecounty.ca.gov/',    'rendered: "Butte County, CA | Official Website"; .gov preferred over the stored .net'),
  ('06009','Calaveras',      'https://www.calaverasgov.us/',       'rendered: "Calaveras County"; redirect target of co.calaveras.ca.us; no .gov exists'),
  ('06011','Colusa',         'https://www.countyofcolusaca.gov/',  'rendered: "Colusa County, CA - Official Website"; stored colusacounty.org is NXDOMAIN'),
  ('06013','Contra Costa',   'https://www.contracosta.ca.gov/',    'rendered: "Contra Costa County, CA Official Website"; stored is NXDOMAIN'),
  ('06015','Del Norte',      'https://www.co.del-norte.ca.us/',    'rendered: "County of Del Norte, California"; redirect target of dnco.org; no .gov'),
  ('06017','El Dorado',      'https://www.eldoradocounty.ca.gov/', 'rendered: "Home - El Dorado County"; stored co.eldorado.ca.us is NXDOMAIN'),
  ('06019','Fresno',         'https://www.fresnocountyca.gov/',    'rendered: "Home - County of Fresno"'),
  ('06021','Glenn',          'https://www.countyofglenn.net/',     'SCHEME-ONLY: same host, http->https. Content NOT verified -- Cloudflare interstitial never cleared. See header.'),
  ('06023','Humboldt',       'https://humboldtgov.org/',           'rendered: "Humboldt County''s Homepage", 69,673 chars, Board of Supervisors present. Not findable by hostname pattern.'),
  ('06025','Imperial',       'https://imperialcounty.org/',        'rendered: "Home - Imperial County"; stored co.imperial.ca.us is NXDOMAIN; no .gov found'),
  ('06027','Inyo',           'https://www.inyocounty.us/',         'rendered: "Inyo County California"; http->https, same host'),
  ('06029','Kern',           'https://www.kerncounty.com/',        'real browser: "Kern County, CA | Home"; redirect target of co.kern.ca.us; also used by migration 1638'),
  ('06031','Kings',          'https://www.countyofkingsca.gov/',   'real browser: "Kings County | Home"; .gov, redirect target of countyofkings.com'),
  ('06033','Lake',           'https://www.lakecountyca.gov/',      'rendered: "Lake County, CA | Official Website", 7,586 chars. Fixes the "www.w." typo. lakecounty.com REJECTED (tourism).'),
  ('06035','Lassen',         'https://www.lassencounty.gov/',      'rendered: "Lassen County, CA | Official Website"'),
  ('06037','Los Angeles',    'https://lacounty.gov/',              'rendered: "COUNTY OF LOS ANGELES"; http->https. losangelescounty.com REJECTED (business directory).'),
  ('06039','Madera',         'https://www.maderacounty.com/',      'real browser: "Madera County | Home"; http->https, same host (maderacounty.gov serves nothing)'),
  ('06043','Mariposa',       'https://www.mariposacounty.gov/',    'rendered: "Mariposa County, CA - Official Website"; .gov preferred over the stored .org'),
  ('06045','Mendocino',      'https://www.mendocinocounty.gov/',   'real browser: "Mendocino County, CA | Home"; .gov, redirect target of co.mendocino.ca.us'),
  ('06049','Modoc',          'https://www.countyofmodoc.gov/',     'rendered: "Modoc County, CA | Official Website"; stored modoccounty.ca.us is NXDOMAIN'),
  ('06051','Mono',           'https://www.monocounty.ca.gov/',     'rendered: "Mono County, CA | Official Website"; http->https, same .gov host'),
  ('06055','Napa',           'https://www.napacounty.gov/',        'rendered: "Napa County, CA | Official Website", 10,128 chars; stored co.napa.ca.us is DEAD'),
  ('06057','Nevada',         'https://www.nevadacountyca.gov/',    'rendered: "Nevada County, CA | Official Website"; .gov preferred over mynevadacounty.com'),
  ('06059','Orange',         'https://www.ocgov.com/',             'rendered: "Orange County"; http->https. 🔴 orangecounty.net REJECTED -- commercial visitor guide.'),
  ('06063','Plumas',         'https://www.plumascounty.us/',       'rendered: "Plumas County, CA - Official Website". 🔴 plumascounty.org REJECTED -- tourism site.'),
  ('06065','Riverside',      'https://rivco.gov/',                 'rendered: "Home | County of Riverside, CA"; stored co.riverside.ca.us redirects here'),
  ('06069','San Benito',     'https://www.sanbenitocountyca.gov/', 'real browser: "San Benito County, CA | Home"; .gov; stored san-benito.ca.us is DEAD'),
  ('06071','San Bernardino', 'https://www.sbcounty.gov/',          'rendered: "Welcome to San Bernardino County"; http->https, settles at main.sbcounty.gov (same .gov domain)'),
  ('06073','San Diego',      'https://www.sandiegocounty.gov/',    'rendered: "Welcome to the County of San Diego". 🔴 www.sandiego.gov REJECTED -- the CITY.'),
  ('06075','San Francisco',  'https://www.sf.gov/',                'real browser: "SF.gov", Board of Supervisors present -- consolidated CITY AND COUNTY, so city markers are correct here. 🔴 sanfranciscocounty.us REJECTED -- 611-byte shell.'),
  ('06077','San Joaquin',    'https://www.sanjoaquin.gov/',        'rendered: serves the same site as sjgov.org; .gov preferred'),
  ('06081','San Mateo',      'https://www.smcgov.org/',            'rendered: "Home | County of San Mateo, CA"; http->https, same host; no .gov exists'),
  ('06085','Santa Clara',    'https://www.santaclaracounty.gov/',  'rendered: "County of Santa Clara - Official Website"; root self-canonicalises to /home'),
  ('06089','Shasta',         'https://www.shastacounty.gov/',      'rendered: "Home Page | Shasta County CA"; stored co.shasta.ca.us is DEAD'),
  ('06093','Siskiyou',       'https://www.siskiyoucounty.gov/',    'rendered: "Siskiyou County California"'),
  ('06099','Stanislaus',     'https://www.stancounty.com/',        'rendered: "Stanislaus County"; http->https, same host; no .gov exists'),
  ('06101','Sutter',         'https://www.sutter.gov/',            'real browser: "Sutter County, CA | Home", Board of Supervisors, no city council. Disambiguated from Yuba City, which is IN this county.'),
  ('06103','Tehama',         'https://www.tehama.gov/',            'rendered: "Tehama County | Welcome to the Tehama County Website!", Board of Supervisors; stored co.tehama.ca.us is NXDOMAIN'),
  ('06105','Trinity',        'https://www.trinitycounty.ca.gov/',  'rendered: "Trinity County, CA | Official Website"; .gov serves the same site as the stored .org'),
  ('06109','Tuolumne',       'https://www.tuolumnecounty.ca.gov/', 'rendered: "Tuolumne County"; http->https, same .gov host'),
  ('06113','Yolo',           'https://www.yolocounty.gov/',        'real browser: "Yolo County | Home"; .gov, redirect target of yolocounty.org'),
  ('06115','Yuba',           'https://www.yuba.gov/',              'real browser: "Welcome to Yuba County CALIFORNIA", Board of Supervisors, no city council. Disambiguated from Yuba City (Sutter County).');

-- Refuse to run if the county set drifted (a renamed/removed district would silently no-op).
DO $$
DECLARE v_missing text;
BEGIN
  SELECT string_agg(u.geo_id || ' ' || u.county, ', ') INTO v_missing
    FROM _url u
   WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d
                      WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id=u.geo_id);
  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'No CA COUNTY district for: % -- refusing to run', v_missing;
  END IF;
END $$;

UPDATE essentials.districts d
   SET official_web_url = u.new_url
  FROM _url u
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca'
   AND d.geo_id = u.geo_id
   AND d.official_web_url IS DISTINCT FROM u.new_url;

DO $$
DECLARE v_bad text; v_n integer; v_http integer; v_null integer;
BEGIN
  -- 1. every intended row now holds exactly the intended value
  SELECT string_agg(u.geo_id || ' ' || u.county || ': is ' || coalesce(d.official_web_url,'NULL')
                    || ', expected ' || u.new_url, '; ') INTO v_bad
    FROM _url u
    JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id=u.geo_id
   WHERE d.official_web_url IS DISTINCT FROM u.new_url;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'URL not applied: %', v_bad; END IF;

  -- 2. all 58 CA counties present, none NULL, none left on plain http
  SELECT count(*), count(*) FILTER (WHERE official_web_url IS NULL),
         count(*) FILTER (WHERE official_web_url ILIKE 'http://%')
    INTO v_n, v_null, v_http
    FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca';
  IF v_n <> 58 THEN RAISE EXCEPTION 'Expected 58 CA county districts, found %', v_n; END IF;
  IF v_null <> 0 THEN RAISE EXCEPTION '% CA county rows have a NULL official_web_url', v_null; END IF;
  IF v_http <> 0 THEN RAISE EXCEPTION '% CA county rows still hold a plain http:// URL', v_http; END IF;

  -- 3. 🔴 none of the known WRONG-ENTITY destinations may ever be stored on a CA county row.
  --    These are cities, tourism boards, business directories and one expired-domain squat that a
  --    liveness check or a hostname ranking would happily have accepted. See header.
  SELECT string_agg(d.label || ' -> ' || d.official_web_url, '; ') INTO v_bad
    FROM essentials.districts d
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca'
     AND (d.official_web_url ~* '://(www\.)?sandiego\.gov'
       OR d.official_web_url ~* '://(www\.)?monterey\.gov'
       OR d.official_web_url ~* 'orangecounty\.net'
       OR d.official_web_url ~* 'plumascounty\.org'
       OR d.official_web_url ~* 'sanfranciscocounty\.us'
       OR d.official_web_url ~* 'lakecounty\.com'
       OR d.official_web_url ~* 'losangelescounty\.com'
       OR d.official_web_url ~* 'slocal\.com'
       OR d.official_web_url ~* 'sierracounty\.ws'
       OR d.official_web_url ~* 'winecountry\.com'
       OR d.official_web_url ~* 'mampir');
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'A NON-COUNTY destination is stored on a CA county row: % -- see migration 1667 header', v_bad;
  END IF;

  -- 4. the "www.w." typo class is gone
  IF EXISTS (SELECT 1 FROM essentials.districts d
              WHERE d.district_type='COUNTY' AND lower(d.state)='ca'
                AND d.official_web_url ~* '://www\.w\.') THEN
    RAISE EXCEPTION 'A "www.w." malformed host survives on a CA county row';
  END IF;

  -- 5. geo_id collisions: this migration must not have touched a non-COUNTY district. Every geo_id
  --    in _url is also a synthesized Assembly geo_id candidate (<FIPS>||<district number>).
  SELECT string_agg(d.district_type || ' ' || coalesce(d.label,'?') || ' (' || d.geo_id || ') -> ' || coalesce(d.official_web_url,'NULL'), '; ')
    INTO v_bad
    FROM essentials.districts d JOIN _url u ON u.geo_id = d.geo_id
   WHERE d.district_type <> 'COUNTY'
     AND d.official_web_url = u.new_url;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'A non-COUNTY district sharing a county geo_id received a county URL: %', v_bad;
  END IF;
END $$;

COMMIT;
