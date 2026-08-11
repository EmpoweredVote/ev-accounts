-- 1680_repoint_ca_municipal_urls_operator_confirmed.sql
--
-- Repoints `official_web_url` for the 5 California cities that could only be settled by a HUMAN
-- OPENING THEM IN A REAL BROWSER. 10 rows. Data-only. Fifth and last routine municipal migration,
-- after 1674 (43 rendered), 1675 (16 NXDOMAIN), 1676 (18 WAF-blocked) and 1679 (6 via the registry).
--
-- ── WHY A HUMAN WAS THE ONLY INSTRUMENT LEFT ───────────────────────────────
-- Every automated method in this series had been spent on these five: rendering (the stored URL was
-- empty, timed out, failed TLS, or served the wrong entity), the derived-hostname candidate sweep, and
-- the CISA .gov registry -- none of which lists any of them, because three sit on `.org`/`.com` and
-- one sits on a `.ca.gov` the federal registry does not cover. The operator opened each in an ordinary
-- browser profile and reported where it landed. That is the same instrument migration 1667 used for
-- eight California counties that were blocked to headless, and it remains the backstop when every
-- programmatic check is exhausted.
--
-- ── 🔴 A CORRECTION TO MIGRATION 1676 ─────────────────────────────────────
-- 1676 excluded Compton and recorded, as fact, that `comptoncity.org` "is not a city website" because
-- it served a redirect to `/sendio/login` titled "Sendio Opt-Inbox". **That was wrong.** The host is
-- the City of Compton's real site; what headless Chromium was shown is a bot-facing artifact of the
-- WAF in front of it, and the same URL rendered 403 "Access Denied" on two other attempts and 200 with
-- the Sendio page on a third. Opened in a real browser it is the city site. Compton therefore needs
-- only the scheme, on an unchanged host.
--
-- The narrower lesson stands and is worth keeping: a live 200 is not evidence of the right thing. The
-- wider inference drawn from it -- that the host was not the city's -- outran the evidence. **An
-- automated probe can be shown something no human visitor ever sees**, so a bot-facing artifact is not
-- grounds for a claim about what a site IS. The 'sendio' term in 1676's gate stays valid: no row
-- should ever store that login URL, and this migration stores the site root instead.
--
-- ── 🔴 TWO WRONG-ENTITY ROWS, BOTH INVISIBLE TO A HOSTNAME CHECK ─────────────────
--   * La Canada Flintridge stored `lacanadaflintridge.com`, which is the **CHAMBER OF COMMERCE** --
--     a plausible hostname for the city, and the auditor classified it NOT_GOVERNMENT correctly. The
--     city is at `lcf.ca.gov`: an INITIALISM. No template built from "La Canada Flintridge" reaches
--     `lcf`, and the federal registry does not list `.ca.gov` at all.
--   * Rolling Hills stored `rollinghills.org`, which is **Rolling Hills Community Church in
--     Tualatin, OREGON**. The city is `rolling-hills.org` -- the two differ by ONE HYPHEN, and the
--     church answers 200 with the town's name in it. Nothing short of reading the page separates them.
--
-- ── 🔴 SECOND SIGHTING OF THE `.ca.gov` GAP ────────────────────────────────
-- `lcf.ca.gov` is the second row in this series whose real site sits in California's own state-run
-- namespace, after Duarte's `cityofduarte.ca.gov` in 1676. 1675 had treated absence from the CISA
-- registry as proof a city had no .gov. Two counterexamples now: for California, check `.ca.gov`
-- before concluding a city has none.
--
-- ── BASIS FOR EVERY ROW ───────────────────────────────────────────────────
--   Compton               operator confirmed in a real browser; 403 to headless. Host unchanged, so identity is not reopened
--   La Canada Flintridge  operator confirmed; a .ca.gov (state-administered namespace, so only a CA government entity can hold it). 403 to headless. Stored host is the CHAMBER OF COMMERCE
--   Rolling Hills         rendered 200, "Rolling Hills, CA", city markers. Stored rollinghills.org is a CHURCH IN TUALATIN, OREGON -- one hyphen apart
--   Lomita                rendered 200, 3649 chars, "Home - City of Lomita". Stored lomita.com times out
--   Pico Rivera           rendered 200, 3867 chars, "Welcome to the City of Pico Rivera". Stored picorivera.org fails TLS
--
-- Compton and La Canada Flintridge answer 403 to headless and rest on the operator's real-browser
-- confirmation; `lcf.ca.gov` additionally carries the state-administered namespace guarantee. Rolling
-- Hills, Lomita and Pico Rivera were each re-rendered here and verified with city markers and a
-- self-identifying title.
--
-- Lomita's stored value was `http://www.lomita.com/cityhall` -- a PATH, not a homepage. Destinations
-- are bare `https://<host>/` roots throughout, per 1674.
--
-- ── STILL OPEN AFTER THIS ─────────────────────────────────────────────────
-- 23 CA municipal rows stay on http, and they are NOT all one thing:
--   * La Habra Heights (2 rows, `la-habra-heights.org`) -- answers 200 with ZERO characters of body
--     text; no alternative found by any method, including the operator's browser. A reading task.
--   * 21 rows across 6 places that VERIFIED but carry a caveat, held back since 1674: Long Beach (13,
--     state-unconfirmed + bare-name host), Artesia (2, governing body in navigation only), Gardena (2)
--     and Rancho Palos Verdes (2) and San Francisco (1) (both entity markers present -- normal for a
--     consolidated city-county), Sacramento (1, state-unconfirmed). Each needs a judgement call, not a
--     lookup, and Long Beach is 13 voter-facing rows on one decision.
--
-- geo_id: resolved from the STORED HOST rather than assumed -- two of five were guessed wrong first
-- (Rolling Hills, Pico Rivera). 10 rows, all CA LOCAL/LOCAL_EXEC; scoped by type and state anyway.
-- Idempotent: compare-and-swap on the exact value measured; the gate asserts END STATE.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

WITH repoint(geo_id, old_url, new_url) AS (
  VALUES
    ('0615044', 'http://www.comptoncity.org/',          'https://www.comptoncity.org/'    ),  -- Compton (2r, SCHEME)
    ('0639003', 'http://www.lacanadaflintridge.com',    'https://lcf.ca.gov/'             ),  -- La Canada Flintridge (2r, REPOINT)
    ('0662602', 'http://www.rollinghills.org',          'https://www.rolling-hills.org/'  ),  -- Rolling Hills (2r, REPOINT)
    ('0642468', 'http://www.lomita.com/cityhall',       'https://lomitacity.com/'         ),  -- Lomita (2r, REPOINT)
    ('0656924', 'http://www.picorivera.org',            'https://www.pico-rivera.org/'    )  -- Pico Rivera (2r, REPOINT)
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
  v_units CONSTANT int := 5;
  v_rows  CONSTANT int := 10;
  v_settled int;
  v_places  int;
  v_plain   int;
  v_path    int;
  v_wrong   int;
  v_left    int;
BEGIN
  SELECT count(*), count(DISTINCT d.geo_id) INTO v_settled, v_places
    FROM essentials.districts d
    JOIN (VALUES
      ('0615044', 'https://www.comptoncity.org/'),
      ('0639003', 'https://lcf.ca.gov/'),
      ('0662602', 'https://www.rolling-hills.org/'),
      ('0642468', 'https://lomitacity.com/'),
      ('0656924', 'https://www.pico-rivera.org/')
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
     AND geo_id IN ('0615044','0639003','0662602','0642468','0656924') AND official_web_url LIKE 'http://%';
  IF v_plain <> 0 THEN
    RAISE EXCEPTION '% row(s) are still on plain http', v_plain;
  END IF;

  SELECT count(*) INTO v_path
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca'
     AND geo_id IN ('0615044','0639003','0662602','0642468','0656924')
     AND (official_web_url LIKE '%?%' OR official_web_url ~ '^https://[^/]+/.+');
  IF v_path <> 0 THEN
    RAISE EXCEPTION '% row(s) hold a path or query rather than a site root', v_path;
  END IF;

  -- 🔴 The two wrong entities these rows were pointed at must never come back, anywhere in the table:
  --    a chamber of commerce, and a church in another state one hyphen away from the city.
  SELECT count(*) INTO v_wrong
    FROM essentials.districts
   WHERE official_web_url IS NOT NULL
     AND (official_web_url ILIKE '%lacanadaflintridge.com%'
       OR official_web_url ~* 'https?://(www\\.)?rollinghills\\.org'
       OR official_web_url ILIKE '%sendio%');
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION '% row(s) hold a chamber of commerce, an out-of-state church, or an email appliance', v_wrong;
  END IF;

  RAISE NOTICE 'OK: % CA city rows across % places settled by an operator in a real browser.', v_rows, v_units;
  RAISE NOTICE 'Correction to 1676: comptoncity.org IS the City of Compton. The Sendio login it served';
  RAISE NOTICE 'to headless was a bot-facing WAF artifact -- a probe can be shown what no visitor sees.';
  RAISE NOTICE 'La Canada Flintridge was pointed at its CHAMBER OF COMMERCE; the city is lcf.ca.gov, an';
  RAISE NOTICE 'initialism no template reaches, in the .ca.gov namespace CISA does not list.';
  RAISE NOTICE 'Rolling Hills was pointed at a CHURCH IN OREGON, one hyphen from the city.';

  SELECT count(*) INTO v_left
    FROM essentials.districts
   WHERE district_type IN ('LOCAL','LOCAL_EXEC') AND lower(state) = 'ca' AND official_web_url LIKE 'http://%';
  RAISE NOTICE '% CA municipal row(s) still on http: La Habra Heights (2, renders 200 with ZERO body', v_left;
  RAISE NOTICE 'text) + 21 caveated-VERIFIED rows held since 1674 (Long Beach 13, Artesia/Gardena/RPV 2 each,';
  RAISE NOTICE 'Sacramento 1, San Francisco 1). Judgement calls, not lookups.';
END $$;

COMMIT;
