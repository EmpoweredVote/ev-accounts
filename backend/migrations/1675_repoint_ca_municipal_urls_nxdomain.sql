-- 1675_repoint_ca_municipal_urls_nxdomain.sql
--
-- Repoints `official_web_url` for 16 California cities whose stored hostname DOES NOT RESOLVE.
-- 34 rows. Data-only; no schema change. Follows 1674, which fixed the 43 municipal units whose
-- stored host still worked.
--
-- ── WHAT WAS BROKEN ────────────────────────────────────────────────────────────
-- Twelve of the sixteen were on `ci.<name>.ca.us`, California's retired municipal namespace -- the
-- exact counterpart of the `co.<name>.or.us` namespace that migrations 1670-1673 moved Oregon's
-- counties off. The other four were never valid hostnames at all:
--
--   Agoura Hills   ciagoura-hills.ca.us       missing the dot after `ci`
--   Norwalk        ci-norwalk.ca.us           a hyphen where the dot belongs
--   Calabasas      cityofcalabases.com        misspells CALABASAS as "calabases"
--   Santa Monica   pen.ci.santa-monica.ca.us  a `pen.` subdomain of a dead host
--
-- All four were flagged from the hostname alone, before any network call. None has ever resolved, so
-- every one of these 34 rows has been a dead link for as long as the data has existed.
--
-- ── 🔴🔴 THE .gov REGISTRY IS THE AUTHORITY THIS TASK HAS BEEN MISSING ──────────────────
-- Six of the sixteen could not be settled by rendering, and both failure modes were fatal to the
-- render-only method:
--
--   1. **A WAF hides a live site from headless Chromium.** `pomonaca.gov`, `monroviaca.gov`,
--      `rollinghillsestates.gov` and `calabasasca.gov` all answer "Access Denied" in 196-217 bytes.
--      The auditor correctly refuses to conclude anything from that -- a BLOCKED row is not a licence
--      to repoint -- so it reported `(none)`, which on this task reads as "no site exists".
--   2. **The candidate generator cannot invent a brand.** Los Angeles' site is `lacity.gov` and
--      Agoura Hills' is `agourahillscity.gov`. No pattern of the form `<name>.gov`,
--      `cityof<name>.gov` or `<name>ca.gov` produces either, exactly as no pattern produced
--      Humboldt County's `humboldtgov.org` in 1667.
--
-- Both are answered by CISA's authoritative .gov registry
-- (github.com/cisagov/dotgov-data, `current-full.csv`, 16,457 domains), which names the REGISTRANT
-- ORGANISATION, city and state for every .gov. Because `.gov` is an administered namespace, a domain
-- listed there as "City of Pomona / Pomona, CA" cannot belong to anyone else -- that is a stronger
-- identity guarantee than any page read, and it is precisely the property that made the preference
-- order favour `.gov` in the first place (Sierra County's `.ws` had no such backstop).
--
-- So the four WAF-blocked rows are NOT being repointed on the strength of a block. They are being
-- repointed on the registry, with the block noted as evidence that a server is answering at all. In
-- the worst case a registry-verified city-owned `.gov` that refuses bots is still strictly better
-- than a hostname that does not resolve.
--
-- Registry search also resolved an ambiguity no render could: Rolling Hills Estates owns FOUR .gov
-- domains. `pvpready.gov` is an emergency-preparedness site; `rollinghillsestatesca.gov` and
-- `rollinghillsestates-ca.gov` both redirect to `rollinghillsestates.gov`, which is therefore the
-- canonical one. And it confirmed `lacounty.gov` is the COUNTY of Los Angeles, a different entity
-- from `lacity.gov` -- the city/county trap this whole series keeps walking into, here settled by
-- registrant name rather than by page vocabulary.
--
-- ── 🔴 TWO CITIES HAVE NO .gov AT ALL, AND THAT IS A FINDING, NOT A GAP ──────────────
-- Los Alamitos and South El Monte have NO domain registered to them in the .gov registry, which is
-- why they land on `cityoflosalamitos.org` and `cityofsouthelmonte.org`. Both rendered and verified
-- as city governments. This is the documented condition for accepting a non-`.gov` host, and having
-- checked the registry it is now a verified absence rather than an assumption.
--
-- ── BASIS FOR EVERY ROW ────────────────────────────────────────────────────────
--   Agoura Hills           rendered 200, 10164 chars, city markers; registry: City of Agoura Hills, CA
--   Arcadia                sweep VERIFIED; registry: City of Arcadia, CA
--   Azusa                  sweep VERIFIED; registry: City of Azusa, CA
--   Calabasas              WAF 403; registry: City Of Calabasas, CA (redirects to their cityofcalabasas.com)
--   Huntington Beach       sweep VERIFIED; registry: City of Huntington Beach, CA
--   Irwindale              sweep VERIFIED; registry: City of Irwindale, CA
--   La Verne               sweep VERIFIED; registry: City of La Verne, CA
--   Los Alamitos           sweep VERIFIED; NO .gov registered to this city
--   Los Angeles            rendered 200 "Home | City of Los Angeles"; registry: City of Los Angeles, CA
--   Monrovia               WAF 403; registry: City of Monrovia, CA
--   Norwalk                sweep VERIFIED; registry: City of Norwalk, CA
--   Pomona                 WAF 403; registry: City of Pomona, CA
--   Rolling Hills Estates  WAF 403; registry: City of Rolling Hills Estates, CA; its 2 sibling .govs redirect here
--   Santa Monica           rendered 200; registry: City of Santa Monica, CA
--   South El Monte         sweep VERIFIED; NO .gov registered to this city
--   South Pasadena         sweep VERIFIED (canonicalised from /Home); registry: City of South Pasadena, CA
--
-- Every destination is a bare `https://<host>/` root, re-verified as a root before acceptance -- see
-- 1674 for why (a redirect landing URL was about to be stored as a city's official address, including
-- one search-results query).
--
-- geo_id: these 16 are 7-digit Census PLACE codes carrying 34 rows, all CA LOCAL/LOCAL_EXEC; no
-- other district type shares them. Scoped by type and state regardless -- `geo_id` has no uniqueness
-- constraint and collisions are live in 13 states.
--
-- Idempotent: compare-and-swap on the exact value measured; the gate asserts END STATE.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

WITH repoint(geo_id, old_url, new_url) AS (
  VALUES
    ('0600394', 'http://www.ciagoura-hills.ca.us',        'https://www.agourahillscity.gov/'      ),  -- Agoura Hills (2r)
    ('0602462', 'http://www.ci.arcadia.ca.us/',           'https://www.arcadiaca.gov/'            ),  -- Arcadia (2r)
    ('0603386', 'http://www.ci.azusa.ca.us/',             'https://www.azusaca.gov/'              ),  -- Azusa (2r)
    ('0609598', 'http://www.cityofcalabases.com',         'https://www.calabasasca.gov/'          ),  -- Calabasas (2r)
    ('0636000', 'http://www.ci.huntington-beach.ca.us/',  'https://www.huntingtonbeachca.gov/'    ),  -- Huntington Beach (1r)
    ('0636826', 'http://www.ci.irwindale.ca.us',          'https://www.irwindaleca.gov/'          ),  -- Irwindale (2r)
    ('0640830', 'http://www.ci.laverne.ca.us',            'https://www.laverneca.gov/'            ),  -- La Verne (2r)
    ('0643224', 'http://www.ci.losalamitos.ca.us/',       'https://www.cityoflosalamitos.org/'    ),  -- Los Alamitos (2r)
    ('0644000', 'http://www.ci.la.ca.us/',                'https://lacity.gov/'                   ),  -- Los Angeles (1r)
    ('0648648', 'http://www.ci.monrovia.ca.us',           'https://www.monroviaca.gov/'           ),  -- Monrovia (2r)
    ('0652526', 'http://www.ci-norwalk.ca.us',            'https://www.norwalkca.gov/'            ),  -- Norwalk (1r)
    ('0658072', 'http://www.ci.pomona.ca.us/',            'https://www.pomonaca.gov/'             ),  -- Pomona (7r)
    ('0662644', 'http://www.ci.rollinghillsestates.ca.us','https://www.rollinghillsestates.gov/'  ),  -- Rolling Hills Estates (2r)
    ('0670000', 'http://pen.ci.santa-monica.ca.us',       'https://www.santamonica.gov/'          ),  -- Santa Monica (2r)
    ('0672996', 'http://www.ci.southelmonte.ca.us/',      'https://www.cityofsouthelmonte.org/'   ),  -- South El Monte (2r)
    ('0673220', 'http://www.ci.southpasadena.ca.us',      'https://www.southpasadenaca.gov/'      )  -- South Pasadena (2r)
)
UPDATE essentials.districts d
   SET official_web_url = r.new_url
  FROM repoint r
 WHERE d.geo_id           = r.geo_id
   AND d.district_type    IN ('LOCAL', 'LOCAL_EXEC')
   AND lower(d.state)     = 'ca'
   AND d.official_web_url = r.old_url;

-- ── POST-VERIFY GATE ───────────────────────────────────────────────────────────
DO $$
DECLARE
  v_units CONSTANT int := 16;
  v_rows  CONSTANT int := 34;
  v_settled int;
  v_places  int;
  v_dead    int;
  v_plain   int;
  v_path    int;
  v_county  int;
BEGIN
  -- 1. END STATE. Passes on a re-run.
  SELECT count(*), count(DISTINCT d.geo_id) INTO v_settled, v_places
    FROM essentials.districts d
    JOIN (VALUES
      ('0600394', 'https://www.agourahillscity.gov/'),
      ('0602462', 'https://www.arcadiaca.gov/'),
      ('0603386', 'https://www.azusaca.gov/'),
      ('0609598', 'https://www.calabasasca.gov/'),
      ('0636000', 'https://www.huntingtonbeachca.gov/'),
      ('0636826', 'https://www.irwindaleca.gov/'),
      ('0640830', 'https://www.laverneca.gov/'),
      ('0643224', 'https://www.cityoflosalamitos.org/'),
      ('0644000', 'https://lacity.gov/'),
      ('0648648', 'https://www.monroviaca.gov/'),
      ('0652526', 'https://www.norwalkca.gov/'),
      ('0658072', 'https://www.pomonaca.gov/'),
      ('0662644', 'https://www.rollinghillsestates.gov/'),
      ('0670000', 'https://www.santamonica.gov/'),
      ('0672996', 'https://www.cityofsouthelmonte.org/'),
      ('0673220', 'https://www.southpasadenaca.gov/')
    ) AS w(geo_id, url)
      ON w.geo_id = d.geo_id AND d.official_web_url = w.url
   WHERE d.district_type IN ('LOCAL', 'LOCAL_EXEC') AND lower(d.state) = 'ca';

  IF v_places <> v_units OR v_settled <> v_rows THEN
    RAISE EXCEPTION 'expected % rows across % places, found % rows across % places',
      v_rows, v_units, v_settled, v_places;
  END IF;

  -- 2. 🔴 THE FOUR HOSTNAMES THAT NEVER RESOLVED MUST NEVER RETURN, in any row of this table.
  SELECT count(*) INTO v_dead
    FROM essentials.districts
   WHERE official_web_url IS NOT NULL
     AND (official_web_url ILIKE '%ciagoura-hills%'      -- missing dot after ci
       OR official_web_url ILIKE '%ci-norwalk%'           -- hyphen for dot
       OR official_web_url ILIKE '%calabases%'            -- misspelled Calabasas
       OR official_web_url ILIKE '%pen.ci.santa-monica%'  -- dead subdomain
       OR official_web_url ILIKE '%ci.la.ca.us%');        -- retired LA host
  IF v_dead <> 0 THEN
    RAISE EXCEPTION '% row(s) still hold a hostname that has never resolved', v_dead;
  END IF;

  -- 3. Nothing in scope left on http, and no landing path or query stored as a homepage.
  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0600394','0602462','0603386','0609598','0636000','0636826','0640830','0643224','0644000','0648648','0652526','0658072','0662644','0670000','0672996','0673220') AND official_web_url LIKE 'http://%';
  IF v_plain <> 0 THEN
    RAISE EXCEPTION '% row(s) are still on plain http', v_plain;
  END IF;

  SELECT count(*) INTO v_path
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0600394','0602462','0603386','0609598','0636000','0636826','0640830','0643224','0644000','0648648','0652526','0658072','0662644','0670000','0672996','0673220')
     AND (official_web_url LIKE '%?%' OR official_web_url ~ '^https://[^/]+/.+');
  IF v_path <> 0 THEN
    RAISE EXCEPTION '% row(s) hold a path or query rather than a site root', v_path;
  END IF;

  -- 4. 🔴 THE INVERTED DISCRIMINATOR. A city row must never point at a county site. `lacity.gov` and
  --    `lacounty.gov` differ by four characters and are different governments.
  SELECT count(*) INTO v_county
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0600394','0602462','0603386','0609598','0636000','0636826','0640830','0643224','0644000','0648648','0652526','0658072','0662644','0670000','0672996','0673220')
     AND (official_web_url ILIKE '%lacounty%' OR official_web_url ILIKE '%countyof%'
       OR official_web_url ILIKE '%county.ca.gov%' OR official_web_url ~ 'https?://(www\\.)?co\\.');
  IF v_county <> 0 THEN
    RAISE EXCEPTION '% city row(s) point at a COUNTY site', v_county;
  END IF;

  RAISE NOTICE 'OK: % CA city rows across % places moved off hostnames that did not resolve.', v_rows, v_units;
  RAISE NOTICE '12 left the retired ci.<name>.ca.us namespace; 4 had hostnames that were never valid.';
  RAISE NOTICE '4 were confirmed by the CISA .gov registry rather than by rendering, because a WAF';
  RAISE NOTICE 'hides them from headless: Pomona, Monrovia, Rolling Hills Estates, Calabasas.';
  RAISE NOTICE '2 have no .gov registered to them at all (Los Alamitos, South El Monte) and keep a .org.';

  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca' AND official_web_url LIKE 'http://%';
  RAISE NOTICE '% CA municipal row(s) still on http, still held for a read.', v_plain;
END $$;

COMMIT;
