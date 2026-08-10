-- 1674_repoint_ca_municipal_official_web_urls.sql
--
-- Repoints `official_web_url` for 43 California CITY jurisdictions -- 103 rows, since a city holds
-- one row per council seat plus one for its citywide executive. Data-only; no schema change. First
-- municipal migration in this series; 1670-1673 covered Oregon's counties.
--
-- ── 🔴🔴 THE DISCRIMINATOR IS INVERTED FROM 1667 AND FROM EVERY OREGON MIGRATION ──────
-- Migration 1667 separated a California COUNTY from its like-named CITY by requiring a BOARD OF
-- SUPERVISORS and rejecting anything that self-identifies as a city. **These rows ARE the cities.**
-- Here "City Council" / "Mayor" is the CORRECT signal and "Board of Supervisors" is the wrong-entity
-- signal -- a city record pointed at its county's website is the same defect as a county record
-- pointed at its city's, mirrored. The auditor picks its marker set per `district_type`; applying
-- 1667's county rule to these rows would have rejected every correct answer.
--
-- ── WHAT THIS IS: CALIFORNIA'S CITIES MOVED TO `.gov`, AND THIS TABLE NEVER FOLLOWED ────────
-- 27 of the 43 change host, and they change it the same way: an old `.org`, `.com` or
-- `ci.<name>.ca.us` address now 301s to a `<name>ca.gov` / `<name>.gov` host. None of that was
-- guessed -- each stored URL was rendered and its redirect followed, so the destination is where the
-- city itself sends visitors. `burbankusa.com` -> `burbankca.gov`, `cityofberkeley.info` ->
-- `berkeleyca.gov`, `ci.walnut.ca.us` -> `walnutca.gov`, `huntingtonpark.org` -> `hpca.gov`.
-- The other 16 keep their host and gain only `https`.
--
-- ── 🔴 THE DESTINATION IS THE SITE ROOT, NOT WHERE THE REDIRECT LANDED ───────────────
-- `finalUrl` is a landing address. Storing it verbatim was about to write, for Rancho Palos Verdes,
--     https://www.rpvca.gov/search/?searchPhrase=&pageNumber=1&perPage=10&departmentId=-1
-- a SEARCH QUERY -- plus `/Home` on six cities and `/index.php` on Carson. Two chains also ended on
-- **http**: Monterey Park at `http://www.montereypark.ca.gov/` and Artesia at
-- `http://www.cityofartesia.us/`, so the "upgrade" would not have upgraded anything.
--
-- Every destination here is `https://<host>/`, and that root was SEPARATELY RENDERED AND RE-VERIFIED
-- before being accepted -- a root is never assumed to exist merely because a subpage does. 12 of the
-- 43 were canonicalised this way.
--
-- ── WHAT IS EXCLUDED, AND WHY (52 of the 95 municipal units) ──────────────────────
-- These 43 are the units whose stored URL verified with NO caveat. Held back:
--   * 19 units / 40 rows BLOCKED -- a WAF hid the page from headless Chromium. A BLOCKED row is not
--     a licence to repoint: eight California counties in 1667 were blocked to headless while
--     rendering perfectly in a real browser profile.
--   * 16 units / 34 rows NXDOMAIN -- the stored host does not resolve. Real repoints, but they need
--     a candidate sweep, not a redirect-follow.
--   * 4 EMPTY, 3 FAIL (Cudahy, El Monte, Glendale -- still failing after a retry), 2 NAME_ONLY,
--     1 NOT_GOVERNMENT, 1 UNRELATED.
--   * 6 VERIFIED but caveated: Long Beach (13 rows -- state-unconfirmed and a bare-name host),
--     Sacramento (state-unconfirmed), Gardena / Rancho Palos Verdes / San Francisco (both entity
--     markers present, which is normal for a consolidated city-county like SF but wants a look
--     elsewhere), Artesia (governing body in navigation only, not prose).
--
-- ── geo_id SCOPING ────────────────────────────────────────────────────
-- Each Oregon county migration had to dodge a live collision (41003 = Benton County AND State House
-- District 3). Checked here: these 43 geo_ids are 7-digit Census PLACE codes carrying 103 rows, ALL
-- of them CA LOCAL/LOCAL_EXEC -- no other district type shares them. The type/state scope is kept
-- anyway, because today's absence of a collision is not a property of the schema: `geo_id` has no
-- uniqueness constraint and collisions are live in 13 states.
--
-- Idempotent: compare-and-swap on the exact value measured; the gate asserts END STATE.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

WITH repoint(geo_id, old_url, new_url) AS (
  VALUES
    -- ── host UNCHANGED: scheme upgrade, plus a redirect path stripped back to the root ──
    ('0603666', 'http://www.baldwinpark.com',               'https://www.baldwinpark.com/'            ), -- Baldwin Park (2r)
    ('0606308', 'http://www.beverlyhills.org',              'https://www.beverlyhills.org/'           ), -- Beverly Hills (2r)
    ('0616742', 'http://www.covinaca.gov',                  'https://covinaca.gov/'                   ), -- Covina (2r)
    ('0619192', 'http://www.diamondbarca.gov',              'https://www.diamondbarca.gov/'           ), -- Diamond Bar (2r)
    ('0636490', 'http://www.cityofindustry.org',            'https://www.cityofindustry.org/'         ), -- Industry (2r)
    ('0636546', 'http://www.cityofinglewood.org/',          'https://www.cityofinglewood.org/'        ), -- Inglewood (6r)
    ('0640340', 'http://www.lapuente.org',                  'https://lapuente.org/'                   ), -- La Puente (2r)
    ('0645246', 'http://www.malibucity.org',                'https://www.malibucity.org/'             ), -- Malibu (2r)
    ('0646492', 'http://www.cityofmaywood.com',             'https://www.cityofmaywood.com/'          ), -- Maywood (2r)
    ('0660018', 'http://www.redondo.org',                   'https://www.redondo.org/'                ), -- Redondo Beach (2r)
    ('0666000', 'http://www.sandiego.gov/',                 'https://www.sandiego.gov/'               ), -- San Diego (1r)
    ('0667042', 'http://www.sangabrielcity.com/',           'https://www.sangabrielcity.com/'         ), -- San Gabriel (2r)
    ('0669088', 'http://www.santaclarita.com',              'https://www.santaclarita.com/'           ), -- Santa Clarita (4r)
    ('0671876', 'http://www.cityofsignalhill.org',          'https://www.cityofsignalhill.org/'       ), -- Signal Hill (2r)
    ('0680000', 'http://www.torranceca.gov',                'https://www.torranceca.gov/'             ), -- Torrance (7r)
    ('0684438', 'http://www.wlv.org',                       'https://www.wlv.org/'                    ), -- Westlake Village (2r)
    -- ── host CHANGES: the old host 301s to the city's new .gov ──
    ('0600884', 'http://www.cityofalhambra.org/',           'https://www.alhambraca.gov/'             ), -- Alhambra (2r)
    ('0604982', 'http://www.bellflower.org',                'https://bellflower.ca.gov/'              ), -- Bellflower (5r)
    ('0606000', 'http://www.cityofberkeley.info',           'https://berkeleyca.gov/'                 ), -- Berkeley (1r)
    ('0607946', 'http://www.cityofbradbury.org/',           'https://www.bradburyca.gov/'             ), -- Bradbury (2r)
    ('0608954', 'http://www.burbankusa.com',                'https://www.burbankca.gov/'              ), -- Burbank (2r)
    ('0611530', 'http://ci.carson.ca.us',                   'https://carsonca.gov/'                   ), -- Carson (2r)
    ('0612552', 'http://www.cerritos.us',                   'https://www.cerritos.gov/'               ), -- Cerritos (2r)
    ('0613756', 'http://www.ci.claremont.ca.us',            'https://www.claremontca.gov/'            ), -- Claremont (2r)
    ('0617568', 'http://www.culvercity.org',                'https://www.culvercity.gov/'             ), -- Culver City (2r)
    ('0630014', 'http://www.ci.glendora.ca.us/',            'https://www.cityofglendora.gov/'         ), -- Glendora (2r)
    ('0633518', 'http://www.hiddenhillscity.org',           'https://hiddenhills.gov/'                ), -- Hidden Hills (2r)
    ('0636056', 'http://www.huntingtonpark.org/',           'https://hpca.gov/'                       ), -- Huntington Park (1r)
    ('0639892', 'http://www.LakewoodCity.org',              'https://www.lakewoodca.gov/'             ), -- Lakewood (2r)
    ('0640032', 'http://www.cityoflamirada.org/',           'https://www.lamirada.gov/'               ), -- La Mirada (2r)
    ('0640256', 'http://WWW.CITYOFLAPALMA.ORG',             'https://www.lapalmaca.gov/'              ), -- La Palma (2r)
    ('0640886', 'http://www.lawndalecity.org/',             'https://www.lawndale.ca.gov/'            ), -- Lawndale (2r)
    ('0648816', 'http://www.cityofmontebello.com/',         'https://www.montebelloca.gov/'           ), -- Montebello (2r)
    ('0648914', 'http://www.ci.monterey-park.ca.us',        'https://www.montereypark.ca.gov/'        ), -- Monterey Park (2r)
    ('0655156', 'http://www.cityofpalmdale.org/',           'https://www.cityofpalmdaleca.gov/'       ), -- Palmdale (5r)
    ('0662896', 'http://www.cityofrosemead.org',            'https://rosemeadca.gov/'                 ), -- Rosemead (2r)
    ('0666070', 'http://cityofsandimas.com',                'https://sandimasca.gov/'                 ), -- San Dimas (2r)
    ('0666140', 'http://www.ci.san-fernando.ca.us/',        'https://www.sanfernando.gov/'            ), -- San Fernando (2r)
    ('0668224', 'http://www.cityofsanmarino.org',           'https://sanmarinoca.gov/'                ), -- San Marino (2r)
    ('0669154', 'http://santafesprings.org',                'https://www.santafesprings.gov/'         ), -- Santa Fe Springs (2r)
    ('0678148', 'http://www.templecity.us',                 'https://www.templecityca.gov/'           ), -- Temple City (2r)
    ('0683332', 'http://www.ci.walnut.ca.us',               'https://www.walnutca.gov/'               ), -- Walnut (2r)
    ('0684200', 'http://www.westcovina.org',                'https://www.westcovina.gov/'             ) -- West Covina (5r)
)
UPDATE essentials.districts d
   SET official_web_url = r.new_url
  FROM repoint r
 WHERE d.geo_id           = r.geo_id
   AND d.district_type    IN ('LOCAL', 'LOCAL_EXEC')   -- cities: council seats + citywide executive
   AND lower(d.state)     = 'ca'
   AND d.official_web_url = r.old_url;

-- ── POST-VERIFY GATE ──────────────────────────────────────────────
DO $$
DECLARE
  v_units CONSTANT int := 43;
  v_rows  CONSTANT int := 103;
  v_settled int;
  v_places  int;
  v_leaked  int;
  v_plain   int;
  v_path    int;
BEGIN
  -- 1. END STATE: every row of every unit holds the intended value. Passes on a re-run.
  SELECT count(*), count(DISTINCT d.geo_id) INTO v_settled, v_places
    FROM essentials.districts d
    JOIN (VALUES
      ('0600884', 'https://www.alhambraca.gov/'),
      ('0603666', 'https://www.baldwinpark.com/'),
      ('0604982', 'https://bellflower.ca.gov/'),
      ('0606000', 'https://berkeleyca.gov/'),
      ('0606308', 'https://www.beverlyhills.org/'),
      ('0607946', 'https://www.bradburyca.gov/'),
      ('0608954', 'https://www.burbankca.gov/'),
      ('0611530', 'https://carsonca.gov/'),
      ('0612552', 'https://www.cerritos.gov/'),
      ('0613756', 'https://www.claremontca.gov/'),
      ('0616742', 'https://covinaca.gov/'),
      ('0617568', 'https://www.culvercity.gov/'),
      ('0619192', 'https://www.diamondbarca.gov/'),
      ('0630014', 'https://www.cityofglendora.gov/'),
      ('0633518', 'https://hiddenhills.gov/'),
      ('0636056', 'https://hpca.gov/'),
      ('0636490', 'https://www.cityofindustry.org/'),
      ('0636546', 'https://www.cityofinglewood.org/'),
      ('0639892', 'https://www.lakewoodca.gov/'),
      ('0640032', 'https://www.lamirada.gov/'),
      ('0640256', 'https://www.lapalmaca.gov/'),
      ('0640340', 'https://lapuente.org/'),
      ('0640886', 'https://www.lawndale.ca.gov/'),
      ('0645246', 'https://www.malibucity.org/'),
      ('0646492', 'https://www.cityofmaywood.com/'),
      ('0648816', 'https://www.montebelloca.gov/'),
      ('0648914', 'https://www.montereypark.ca.gov/'),
      ('0655156', 'https://www.cityofpalmdaleca.gov/'),
      ('0660018', 'https://www.redondo.org/'),
      ('0662896', 'https://rosemeadca.gov/'),
      ('0666000', 'https://www.sandiego.gov/'),
      ('0666070', 'https://sandimasca.gov/'),
      ('0666140', 'https://www.sanfernando.gov/'),
      ('0667042', 'https://www.sangabrielcity.com/'),
      ('0668224', 'https://sanmarinoca.gov/'),
      ('0669088', 'https://www.santaclarita.com/'),
      ('0669154', 'https://www.santafesprings.gov/'),
      ('0671876', 'https://www.cityofsignalhill.org/'),
      ('0678148', 'https://www.templecityca.gov/'),
      ('0680000', 'https://www.torranceca.gov/'),
      ('0683332', 'https://www.walnutca.gov/'),
      ('0684200', 'https://www.westcovina.gov/'),
      ('0684438', 'https://www.wlv.org/')
    ) AS w(geo_id, url)
      ON w.geo_id = d.geo_id AND d.official_web_url = w.url
   WHERE d.district_type IN ('LOCAL', 'LOCAL_EXEC') AND lower(d.state) = 'ca';

  IF v_places <> v_units OR v_settled <> v_rows THEN
    RAISE EXCEPTION 'expected % rows across % places, found % rows across % places',
      v_rows, v_units, v_settled, v_places;
  END IF;

  -- 2. Nothing in scope is left on http.
  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0600884','0603666','0604982','0606000','0606308','0607946','0608954','0611530','0612552','0613756','0616742','0617568','0619192','0630014','0633518','0636056','0636490','0636546','0639892','0640032','0640256','0640340','0640886','0645246','0646492','0648816','0648914','0655156','0660018','0662896','0666000','0666070','0666140','0667042','0668224','0669088','0669154','0671876','0678148','0680000','0683332','0684200','0684438')
     AND official_web_url LIKE 'http://%';
  IF v_plain <> 0 THEN
    RAISE EXCEPTION '% row(s) are still on plain http', v_plain;
  END IF;

  -- 🔴 The bug this migration exists to avoid: storing a landing page instead of a homepage.
  SELECT count(*) INTO v_path
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0600884','0603666','0604982','0606000','0606308','0607946','0608954','0611530','0612552','0613756','0616742','0617568','0619192','0630014','0633518','0636056','0636490','0636546','0639892','0640032','0640256','0640340','0640886','0645246','0646492','0648816','0648914','0655156','0660018','0662896','0666000','0666070','0666140','0667042','0668224','0669088','0669154','0671876','0678148','0680000','0683332','0684200','0684438')
     AND (official_web_url LIKE '%?%' OR official_web_url LIKE '%index.php%'
       OR official_web_url ~ '^https://[^/]+/.+');
  IF v_path <> 0 THEN
    RAISE EXCEPTION '% row(s) hold a path or query rather than a site root', v_path;
  END IF;

  -- 3. 🔴 THE INVERTED-DISCRIMINATOR CHECK. A city row must never point at a county site -- the
  --    mirror of the gate 1667 used to keep county rows off city sites.
  SELECT count(*) INTO v_leaked
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0600884','0603666','0604982','0606000','0606308','0607946','0608954','0611530','0612552','0613756','0616742','0617568','0619192','0630014','0633518','0636056','0636490','0636546','0639892','0640032','0640256','0640340','0640886','0645246','0646492','0648816','0648914','0655156','0660018','0662896','0666000','0666070','0666140','0667042','0668224','0669088','0669154','0671876','0678148','0680000','0683332','0684200','0684438')
     AND (official_web_url ILIKE '%countyof%' OR official_web_url ILIKE '%county.ca.gov%'
       OR official_web_url ILIKE '%lacounty%'
       OR official_web_url ~ 'https?://(www\.)?co\.');
  IF v_leaked <> 0 THEN
    RAISE EXCEPTION '% city row(s) point at a COUNTY site', v_leaked;
  END IF;

  RAISE NOTICE 'OK: % CA city rows across % places repointed to a verified https site root.', v_rows, v_units;
  RAISE NOTICE '27 places moved host (old .org/.com/ci.<name>.ca.us -> the city''s new .gov); 16 kept theirs.';

  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca' AND official_web_url LIKE 'http://%';
  RAISE NOTICE '% CA municipal row(s) still on http -- the 52 units held back for a read.', v_plain;
  RAISE NOTICE 'Largest held-back groups: 19 units / 40 rows BLOCKED by a WAF (confirm in a real browser';
  RAISE NOTICE 'profile; a block is NOT a licence to repoint) and 16 units / 34 rows NXDOMAIN.';
END $$;

COMMIT;
