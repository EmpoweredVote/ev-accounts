-- 1676_repoint_ca_municipal_urls_waf_blocked.sql
--
-- Resolves the 18 California cities whose stored URL was WAF-BLOCKED to headless Chromium, so the
-- auditor could not read the page and correctly refused to draw a conclusion. 38 rows. Data-only.
-- Third municipal migration, after 1674 (43 units that rendered) and 1675 (16 that did not resolve).
--
-- ── 🔴 HOW A BLOCKED ROW WAS SETTLED WITHOUT EVER READING THE PAGE ────────────────
-- 17 of these 18 answer "Access Denied" or "403 Forbidden" in 197-219 bytes. The standing rule is
-- that a BLOCKED row is not a licence to repoint, and it still holds: not one row here was decided by
-- a block. Three other instruments did the work, none of which needs page content.
--
-- 1. **THE REDIRECT TARGET.** A 403 still reports its final URL, so a blocked host will happily tell
--    you where it forwards. That is how five were settled -- `ci.commerce.ca.us` forwards to
--    `commerceca.gov`, `elsegundo.org` to `elsegundo.gov`, `hermosabch.org` to
--    `hermosabeach.gov`, `ci.manhattan-beach.ca.us` to `manhattanbeach.gov`, `cityofvernon.org`
--    to `cityofvernonca.gov`. A site's own redirect is the strongest possible statement about where
--    it now lives, and it survives a WAF.
--
-- 2. **THE .gov REGISTRY** (CISA dotgov-data, as introduced in 1675) names the registrant of every
--    federal .gov, confirming each destination above belongs to that city and not a namesake.
--
-- 3. **THE REDIRECT RUN BACKWARDS, which reversed four decisions.** Four cities own a .gov that
--    REDIRECTS TO THEIR OWN NON-.gov HOST: `hgcityca.gov` -> `hgcity.org`,
--    `cityoflancasterca.gov` -> `cityoflancasterca.org`, `weho.gov` -> `weho.org`,
--    `cityofwhittier.gov` -> `cityofwhittier.org`. The preference order says `.gov` wins, and
--    following it mechanically would have repointed all four AWAY from the canonical site the city
--    actually publishes. Two more are worse than that: `hawthorneca.gov` returns a 522
--    connection-timed-out and `paramountcity.gov` times out entirely, while both cities' `.org`/
--    `.com` hosts answer. **Owning a .gov is not the same as serving from it.** So those six keep
--    their existing host and take only the scheme.
--
-- ── 🔴 REGISTRY SILENCE IS NOT "NO .gov" -- CALIFORNIA RUNS ITS OWN NAMESPACE ──────────
-- Duarte's `accessduarte.com` redirects to `cityofduarte.ca.gov`, which the CISA registry does not
-- list, because `.ca.gov` is administered by the State of California rather than federally. 1675
-- treated absence from that registry as proof a city had no .gov; that inference is too strong, and
-- this row is the counterexample. It is still an administered namespace, so it carries the same
-- squatter-resistance that makes `.gov` preferable.
--
-- ── 🔴 COMPTON IS EXCLUDED: ITS URL IS NOW AN EMAIL APPLIANCE ─────────────────
-- `comptoncity.org` is the one row here that answers 200 rather than 403, and what it serves is a
-- redirect to `/sendio/login?returnUrl=...` titled "Sendio Opt-Inbox" -- an email quarantine login,
-- 44 characters of body text. It is not a city website and has not been repointed anywhere, because
-- no candidate for Compton has been verified yet and no .gov is registered to the city. Compton stays
-- on the backlog as a reading task. A live 200 is not evidence of the right thing; that is the same
-- lesson as Sonoma's tourism site and Sherman County's casino squat, in a new costume.
--
-- ── BASIS FOR EVERY ROW ───────────────────────────────────────────────────
--   Commerce              REPOINT  stored ci.commerce.ca.us redirects here; registry: City of Commerce, CA
--   Duarte                REPOINT  stored accessduarte.com redirects here; a .ca.gov (state-administered, absent from the CISA federal registry)
--   El Segundo            REPOINT  stored elsegundo.org redirects here; registry: City of El Segundo, CA
--   Hermosa Beach         REPOINT  stored hermosabch.org redirects here; registry: City of Hermosa Beach, CA
--   Lynwood               REPOINT  RENDERED 200, 5503 chars, city markers, "Lynwood, CA | Official Website"; stored lynwood.ca.us is NXDOMAIN
--   Manhattan Beach       REPOINT  stored ci.manhattan-beach.ca.us redirects here; registry: City of Manhattan Beach, CA
--   Vernon                REPOINT  stored cityofvernon.org redirects here; registry: City of Vernon, CA
--   Bell Gardens          SCHEME   no .gov registered; host unchanged
--   Downey                SCHEME   no .gov registered; host unchanged
--   Fremont               SCHEME   stored host IS the registered .gov (City of Fremont, CA)
--   Hawaiian Gardens      SCHEME   its own hgcityca.gov REDIRECTS to this host, so this is canonical
--   Hawthorne             SCHEME   its hawthorneca.gov returns 522 connection-timed-out; this host is the working one
--   Lancaster             SCHEME   its own cityoflancasterca.gov REDIRECTS to this host
--   Palos Verdes Estates  SCHEME   no .gov registered; host unchanged
--   Paramount             SCHEME   its paramountcity.gov times out; this host is the working one
--   San Jose              SCHEME   stored host IS the registered .gov (City of San Jose, CA)
--   West Hollywood        SCHEME   its own weho.gov REDIRECTS to this host
--   Whittier              SCHEME   its own cityofwhittier.gov REDIRECTS to this host
--
-- For the 11 scheme-only rows the registrable host is byte-identical to what is stored, so identity is
-- not reopened -- whatever entity `bellgardens.org` is, `https://bellgardens.org/` is the same
-- entity, exactly the argument 1671 used for Oregon. A 403 over TLS also proves a server is answering
-- on 443, which is all a scheme change needs to know.
--
-- Every destination is a bare `https://<host>/` root, taken from the redirect chain's final URL so
-- the `www` form is the site's own. geo_id: 7-digit Census PLACE codes, 38 rows, all CA
-- LOCAL/LOCAL_EXEC; scoped by type and state regardless.
--
-- Idempotent: compare-and-swap on the exact value measured; the gate asserts END STATE.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

WITH repoint(geo_id, old_url, new_url) AS (
  VALUES
    -- ── host CHANGES: the stored host's own redirect, or a rendered .gov, names the destination ──
    ('0614974', 'http://www.ci.commerce.ca.us/',        'https://www.commerceca.gov/'         ),  -- Commerce (2r)
    ('0619990', 'http://www.accessduarte.com/',         'https://www.cityofduarte.ca.gov/'    ),  -- Duarte (1r)
    ('0622412', 'http://www.elsegundo.org',             'https://www.elsegundo.gov/'          ),  -- El Segundo (2r)
    ('0633364', 'http://hermosabch.org',                'https://www.hermosabeach.gov/'       ),  -- Hermosa Beach (2r)
    ('0644574', 'http://www.lynwood.ca.us/',            'https://www.lynwoodca.gov/'          ),  -- Lynwood (2r)
    ('0645400', 'http://www.ci.manhattan-beach.ca.us',  'https://www.manhattanbeach.gov/'     ),  -- Manhattan Beach (2r)
    ('0682422', 'http://www.cityofvernon.org/',         'https://www.cityofvernonca.gov/'     ),  -- Vernon (2r)
    -- ── host UNCHANGED: scheme upgrade only, so identity is not reopened ──
    ('0604996', 'http://www.bellgardens.org',           'https://www.bellgardens.org/'        ),  -- Bell Gardens (2r)
    ('0619766', 'http://www.downeyca.org/',             'https://www.downeyca.org/'           ),  -- Downey (6r)
    ('0626000', 'http://www.fremont.gov',               'https://www.fremont.gov/'            ),  -- Fremont (1r)
    ('0632506', 'http://hgcity.org/',                   'https://www.hgcity.org/'             ),  -- Hawaiian Gardens (2r)
    ('0632548', 'http://www.cityofhawthorne.org',       'https://www.cityofhawthorne.org/'    ),  -- Hawthorne (2r)
    ('0640130', 'http://www.cityoflancasterca.org/',    'https://www.cityoflancasterca.org/'  ),  -- Lancaster (3r)
    ('0655380', 'http://www.pvestates.org',             'https://www.pvestates.org/'          ),  -- Palos Verdes Estates (2r)
    ('0655618', 'http://www.paramountcity.com/',        'https://www.paramountcity.com/'      ),  -- Paramount (2r)
    ('0668000', 'http://www.sanjoseca.gov',             'https://www.sanjoseca.gov/'          ),  -- San Jose (1r)
    ('0684410', 'http://www.weho.org',                  'https://www.weho.org/'               ),  -- West Hollywood (2r)
    ('0685292', 'http://www.cityofwhittier.org',        'https://www.cityofwhittier.org/'     )  -- Whittier (2r)
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
  v_units CONSTANT int := 18;
  v_rows  CONSTANT int := 38;
  v_settled int;
  v_places  int;
  v_plain   int;
  v_path    int;
  v_county  int;
  v_sendio  int;
BEGIN
  SELECT count(*), count(DISTINCT d.geo_id) INTO v_settled, v_places
    FROM essentials.districts d
    JOIN (VALUES
      ('0614974', 'https://www.commerceca.gov/'),
      ('0619990', 'https://www.cityofduarte.ca.gov/'),
      ('0622412', 'https://www.elsegundo.gov/'),
      ('0633364', 'https://www.hermosabeach.gov/'),
      ('0644574', 'https://www.lynwoodca.gov/'),
      ('0645400', 'https://www.manhattanbeach.gov/'),
      ('0682422', 'https://www.cityofvernonca.gov/'),
      ('0604996', 'https://www.bellgardens.org/'),
      ('0619766', 'https://www.downeyca.org/'),
      ('0626000', 'https://www.fremont.gov/'),
      ('0632506', 'https://www.hgcity.org/'),
      ('0632548', 'https://www.cityofhawthorne.org/'),
      ('0640130', 'https://www.cityoflancasterca.org/'),
      ('0655380', 'https://www.pvestates.org/'),
      ('0655618', 'https://www.paramountcity.com/'),
      ('0668000', 'https://www.sanjoseca.gov/'),
      ('0684410', 'https://www.weho.org/'),
      ('0685292', 'https://www.cityofwhittier.org/')
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
     AND geo_id IN ('0614974','0619990','0622412','0633364','0644574','0645400','0682422','0604996','0619766','0626000','0632506','0632548','0640130','0655380','0655618','0668000','0684410','0685292') AND official_web_url LIKE 'http://%';
  IF v_plain <> 0 THEN
    RAISE EXCEPTION '% row(s) are still on plain http', v_plain;
  END IF;

  SELECT count(*) INTO v_path
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0614974','0619990','0622412','0633364','0644574','0645400','0682422','0604996','0619766','0626000','0632506','0632548','0640130','0655380','0655618','0668000','0684410','0685292')
     AND (official_web_url LIKE '%?%' OR official_web_url ~ '^https://[^/]+/.+');
  IF v_path <> 0 THEN
    RAISE EXCEPTION '% row(s) hold a path or query rather than a site root', v_path;
  END IF;

  -- 🔴 The email-appliance URL must never be stored on any row of this table, and neither must the
  --    two .gov hosts that do not serve (Hawthorne 522, Paramount timeout).
  SELECT count(*) INTO v_sendio
    FROM essentials.districts
   WHERE official_web_url IS NOT NULL
     AND (official_web_url ILIKE '%sendio%'
       OR official_web_url ILIKE '%hawthorneca.gov%'
       OR official_web_url ILIKE '%paramountcity.gov%');
  IF v_sendio <> 0 THEN
    RAISE EXCEPTION '% row(s) hold a non-serving host or an email appliance', v_sendio;
  END IF;

  -- 🔴 The inverted discriminator: a city row must never point at a county site.
  SELECT count(*) INTO v_county
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0614974','0619990','0622412','0633364','0644574','0645400','0682422','0604996','0619766','0626000','0632506','0632548','0640130','0655380','0655618','0668000','0684410','0685292')
     AND (official_web_url ILIKE '%lacounty%' OR official_web_url ILIKE '%countyof%'
       OR official_web_url ILIKE '%county.ca.gov%' OR official_web_url ~ 'https?://(www\\.)?co\\.');
  IF v_county <> 0 THEN
    RAISE EXCEPTION '% city row(s) point at a COUNTY site', v_county;
  END IF;

  RAISE NOTICE 'OK: % CA city rows across % WAF-blocked places settled without reading a page.', v_rows, v_units;
  RAISE NOTICE '% repointed on a redirect target + .gov registry; % took the scheme only.', 7, 11;
  RAISE NOTICE '4 cities own a .gov that REDIRECTS to their own non-.gov host, and 2 own one that does';
  RAISE NOTICE 'not serve at all -- owning a .gov is not the same as serving from it.';
  RAISE NOTICE 'Compton (0615044) is deliberately NOT included: comptoncity.org now serves a Sendio';
  RAISE NOTICE 'email-quarantine login, and no verified candidate for Compton exists yet.';

  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca' AND official_web_url LIKE 'http://%';
  RAISE NOTICE '% CA municipal row(s) still on http.', v_plain;
END $$;

COMMIT;
