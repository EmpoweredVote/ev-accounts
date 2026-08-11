-- 1688_null_photo_origin_research_breadcrumbs.sql
--
-- Clear the 148 `essentials.politicians.photo_origin_url` values that are not URLs at all, but
-- research breadcrumbs left in the column by portrait-sweep tooling:
--
--     searched:no_results                     97
--     explored                                48
--     local:public/images/HollyHarvey_.jfif     1
--     wvc-ut.gov/city-council                  1   (a host with no scheme — not fetchable)
--     searched:circular_crop_only               1
--
-- WHY
--
-- Two separate problems, one cause.
--
--   * Coverage lies. coverageService/coverageMapService counted `photo_origin_url IS NOT NULL` as
--     "has a photo", so these 148 plus 82 empty-string rows were reported as portrait coverage.
--     For seated officeholders that was 4,336 reported where only 4,121 can render one. The
--     predicate is fixed in src/lib/photoCoverage.ts (HAS_RENDERABLE_PHOTO_SQL) in the same change;
--     this migration removes the bad data the predicate was papering over.
--   * The headshot backlog cannot see them. Any backlog query keyed on `photo_origin_url IS NOT NULL`
--     treats these officials as done. 139 of the 148 are seated right now with no portrait from any
--     source. After this runs they become visible as what they are: missing.
--
-- WHAT A VOTER SEES: NOTHING CHANGES. Verified 2026-08-11 against production. Every render site
-- carries an onError fallback to an initials placeholder — ev-ui PoliticianProfile.jsx:686,
-- PoliticianCard.jsx:275, CompassCard*.jsx, essentials Landing.jsx:202. Today `explored` is emitted
-- as an <img src>, resolves relative to the SPA origin, returns 200 text/html (2,164 b from the
-- Netlify catch-all), fails to decode, and paints the placeholder. After this migration the src is
-- empty and the same placeholder paints directly. The only delta is one junk request that stops
-- being made. This is NOT a fix for a broken-portrait bug; that bug was investigated and does not
-- reproduce.
--
-- SCOPE — deliberately only the non-URL values.
--
-- 2,604 rows hold a real URL that points at a roster page rather than a portrait, and those are
-- NOT touched here. They cannot be separated from working portraits by shape: verified same day,
-- `cityofinglewood.org/ImageRepository/Document?documentID=20637` returns 200 image/jpeg while
-- `dccouncil.gov/councilmembers/` returns 200 text/html — a CMS image handler and a roster page,
-- indistinguishable by URL. Separating them needs a per-row content-type fetch. That is a
-- re-pointing project like the district-URL wave (1670-1684), not a bulk clear. The 82
-- empty-string rows are also left alone; they are already handled by the coverage predicate and
-- carry no information either way.
--
-- The breadcrumbs themselves are preserved out-of-band in
-- data/photo-origin-breadcrumbs-2026-08-11.json (see scripts/dump-photo-origin-breadcrumbs.mts)
-- so "somebody already searched for this one" stays recoverable. They are deliberately NOT moved
-- into politicians.notes: that column holds biographies and birthdates and is serialized to the
-- client, so putting scratch state there would recreate exactly the defect this migration removes.
--
-- 5 of the 148 already have a working photo_custom_url (Dean Francois, Debra Martin, Elen Asatryan,
-- Holly M Harvey, Lars Nordfelt). They render a real portrait today and will continue to; only the
-- dead value behind it goes away.
--
-- Idempotent: the gate asserts an END STATE, so a second run updates nothing and still passes.
-- No regex is used anywhere below -- `NOT LIKE 'http%'` is sufficient and avoids the escaping trap
-- that left six gates inert in migration 1684.

BEGIN;

-- Pre-state, so the gate can prove nothing outside the intended set moved.
CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT p.id,
       p.photo_origin_url,
       p.photo_custom_url
  FROM essentials.politicians p;

CREATE UNIQUE INDEX ON _before (id);

UPDATE essentials.politicians p
   SET photo_origin_url = NULL
 WHERE p.photo_origin_url IS NOT NULL
   AND btrim(p.photo_origin_url) <> ''
   AND p.photo_origin_url NOT LIKE 'http%';

DO $$
DECLARE
  v_cleared    integer;
  v_remaining  integer;
  v_urls_lost  integer;
  v_custom_chg integer;
  v_other_chg  integer;
BEGIN
  -- How many this run cleared. 148 on the first run, 0 on a re-run -- both are success.
  SELECT count(*) INTO v_cleared
    FROM essentials.politicians p
    JOIN _before bf ON bf.id = p.id
   WHERE bf.photo_origin_url IS NOT NULL
     AND p.photo_origin_url IS NULL;

  -- END STATE: no non-URL value may survive anywhere in the column.
  SELECT count(*) INTO v_remaining
    FROM essentials.politicians p
   WHERE p.photo_origin_url IS NOT NULL
     AND btrim(p.photo_origin_url) <> ''
     AND p.photo_origin_url NOT LIKE 'http%';
  IF v_remaining <> 0 THEN
    RAISE EXCEPTION '1688: % non-URL photo_origin_url values still present', v_remaining;
  END IF;

  -- A real URL must never have been cleared. This is the one irreversible mistake available here.
  SELECT count(*) INTO v_urls_lost
    FROM essentials.politicians p
    JOIN _before bf ON bf.id = p.id
   WHERE bf.photo_origin_url LIKE 'http%'
     AND p.photo_origin_url IS DISTINCT FROM bf.photo_origin_url;
  IF v_urls_lost <> 0 THEN
    RAISE EXCEPTION '1688: % rows had a real URL cleared', v_urls_lost;
  END IF;

  -- photo_custom_url is the column that actually paints portraits. It must be untouched.
  SELECT count(*) INTO v_custom_chg
    FROM essentials.politicians p
    JOIN _before bf ON bf.id = p.id
   WHERE p.photo_custom_url IS DISTINCT FROM bf.photo_custom_url;
  IF v_custom_chg <> 0 THEN
    RAISE EXCEPTION '1688: % rows had photo_custom_url modified', v_custom_chg;
  END IF;

  -- Nothing may have changed except a non-URL origin becoming NULL.
  SELECT count(*) INTO v_other_chg
    FROM essentials.politicians p
    JOIN _before bf ON bf.id = p.id
   WHERE p.photo_origin_url IS DISTINCT FROM bf.photo_origin_url
     AND NOT (p.photo_origin_url IS NULL
              AND bf.photo_origin_url IS NOT NULL
              AND btrim(bf.photo_origin_url) <> ''
              AND bf.photo_origin_url NOT LIKE 'http%');
  IF v_other_chg <> 0 THEN
    RAISE EXCEPTION '1688: % rows changed outside the intended set', v_other_chg;
  END IF;

  RAISE NOTICE '1688 OK: % breadcrumb values cleared, 0 remaining, 0 real URLs lost', v_cleared;
END $$;

COMMIT;
