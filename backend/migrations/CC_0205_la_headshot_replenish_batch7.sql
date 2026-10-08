-- CC_0205 — four Los Angeles headshots (LA replenish, batch 7)
--
-- McKinney · Morales · Hernandez · Gonzales-Torres. All four replacements are crops of files
-- measured at their own origin. NOTHING IS ENLARGED and nothing is composited.
--
-- Proof sheet the operator approved: https://claude.ai/artifact/PCsCQZJQ7fCv2bzqUjXsYD
--
--
-- 1. JOHN McKINNEY (6cd2e87b) — Candidate, Los Angeles City Attorney
--    Was: 600x750, an enlargement of mckinney4la.com's `John-McKinney-steps.jpg`, whose ORIGIN is
--    only 540x751 — a full-length shot on the City Hall steps with the head at about a fifth of
--    the frame. Measured edge energy 2.62.
--    Now: Ballotpedia's `JohnMcKinney_CA.png`, 680x723, cropped to 578x723. A PURE CROP WITH NO
--    RESIZE — the source height is the binding constraint, so the crop uses all of it. Head 48.3%
--    of frame, air above the hair 8.7%, face centre 49.5% of the width, chroma 27.5.
--    ⚠ 578 px on the short side is the smallest output in this batch. It clears the 300 px floor
--    and it is the largest file of him that exists: his own site's other four images were measured
--    and are a handshake candid (675x750), a landscape hero with the head clipped (1200x540), and
--    two full-length shots (540x751 each).
--    The PNG's alpha channel is fully opaque — 0 transparent pixels — so this is a photograph, not
--    a cutout composited onto a backdrop.
--
-- 2. CRISTIAN MORALES (a4dd0a2c) — Candidate, U.S. House California District 43
--    🔴 THIS ONE IS A LICENCE FIX AS WELL AS A QUALITY FIX. Today his photo_origin_url is
--    `https://www.instagram.com/cmoralescagov/`. A social media profile is not a permitted source:
--    the standard is press, official or campaign. The image itself was also the least detailed file
--    in the whole Los Angeles set — measured edge energy 1.48 — an enlargement with the top of his
--    head cut off by the frame.
--    Now: Ballotpedia's `ChristianMorales26-2_2026-09-03_181854.jpg`, 3024x4032 — a portrait
--    between the United States and California flags. Cropped to 2589x3236 and downscaled 2.16x to
--    1200x1500. Head 45.0%, eye line 31.6%, air above the hair 7.0%, face centre 50.5%, chroma 31.8.
--    Rejected, measured: the hero on forallvoices.com (his District 43 campaign site) is 1200x799
--    and MONOCHROME; `meet-christian_b1.png` is 493x740 and shot inside an aircraft; and
--    cmoralesforcagovernor.com, his former governor-campaign site, now returns 404.
--
-- 3. SARA HERNANDEZ (3ce8b7fa) — President, LACCD Board of Trustees, Seat 4
-- 4. ANGELA GONZALES-TORRES (7b99c301) — Candidate, U.S. House California District 34
--    Both were 200x300 — under the 300 px floor on the short side. THE FRAMING WAS NEVER THE
--    DEFECT, and neither is a change of photograph.
--    🟢 BOTH LIVE FILES ARE BYTE-IDENTICAL TO BALLOTPEDIA'S 200x300 THUMBNAIL of the originals
--    below. Verified by downloading both and comparing bytes. So the subject pixels do not change;
--    only the resolution does, and identity cannot be at risk here.
--    Hernandez: `SaraHernandez2022.jpg`, 8192x5464, cropped to 3738x4673 and downscaled 3.12x to
--    1200x1500. Head 45.0%, eye line 32.1%, air above the hair 8.0%, face centre 50.5%, chroma 35.7.
--    Gonzales-Torres: `Angela_GonzalesTorres_20250814_062216.jpg`, 4094x5337, cropped to 3037x3796
--    and downscaled 2.53x to 1200x1500. Head 45.0%, eye line 31.8%, air above the hair 9.0%,
--    face centre 50.0%, chroma 41.5.
--    laccd.edu/board/sara-hernandez publishes no portrait of her. It does confirm the seat: she is
--    President of the Board of Trustees for Seat 4.
--
--
-- 🔴 THE CROPS ARE CENTRED ON A MEASURED FACE BOX, NOT ON A POSITION READ OFF A GRID. Every
-- reading was drawn back onto its photograph and looked at before a crop was cut, and that is how
-- two detector failures were caught: a skin-tone centroid put McKinney's face centre 115 px off
-- (his skin falls outside the usual Cb/Cr box), and a background-departure scan read Morales' head
-- 236 px too tall against his flags and Hernandez' 262 px too tall against a building. The
-- face-box centre and the eye midpoint agreed on all four subjects, so those are what the crops
-- use. NEITHER DETECTOR IS RIGHT EVERYWHERE — the picture is the control.
--
-- 🔴 WRITES BOTH FIELDS. The browse grid reads essentials.politician_images first and falls back to
-- politicians.photo_custom_url; the backend read paths do the reverse. The gate below requires the
-- pair to agree, and requires exactly one type='default' row per person — two make the grid's
-- find() pick an arbitrary one.
--
-- Idempotent: each UPDATE is guarded on the value differing, and re-running verifies and changes
-- nothing. No DDL, so it applies as `ev_api` or as `postgres`.
--
-- Every old object was left in the bucket, so rollback is one UPDATE per person:
--   6cd2e87b … photo_custom_url .../politician_photos/6cd2e87b-7366-429a-a049-990751bd647f-headshot.jpg
--              photo_origin_url https://mckinney4la.com/wp-content/uploads/John-McKinney-steps.jpg
--              photo_license    press_use
--   a4dd0a2c … photo_custom_url .../politician_photos/a4dd0a2c-564f-4e5c-9e1b-9bb942964cab-headshot.jpg
--              photo_origin_url https://www.instagram.com/cmoralescagov/
--              photo_license    press_use
--   3ce8b7fa … photo_custom_url .../politician_photos/3ce8b7fa-a703-45be-9e07-71b1a8ebfa8d-headshot.jpg
--              photo_origin_url https://ballotpedia.org/Sara_Hernandez
--              photo_license    press_use
--   7b99c301 … photo_custom_url .../politician_photos/7b99c301-222a-4ebf-8427-c7290685e245-headshot.jpg
--              photo_origin_url https://ballotpedia.org/Angela_Gonzales-Torres
--              photo_license    press_use

BEGIN;

DO $$
DECLARE
  v_base    constant text :=
    'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/';
  r         record;
  n_seen    int := 0;
  n_ok      int := 0;
  v_url     text;
  v_grid    text;
  v_origin  text;
  v_lic     text;
  v_ndef    int;
BEGIN
  -- ---------------------------------------------------------------- preconditions
  FOR r IN
    SELECT b.pid::uuid AS pid, b.nm, b.origin, b.lic,
           p.id AS found, p.full_name AS db_name,
           coalesce(p.photo_custom_url_manual_override, false) AS override,
           p.photo_restriction_code AS restriction,
           (SELECT count(*) FROM essentials.politician_images i
             WHERE i.politician_id = b.pid::uuid AND i.type = 'default') AS n_default
      FROM (VALUES
        ('6cd2e87b-7366-429a-a049-990751bd647f', 'John McKinney',
         'https://s3.amazonaws.com/ballotpedia-api4/files/JohnMcKinney_CA.png',
         'Candidate photograph published by Ballotpedia (ballotpedia.org), alt text "Image of John McKinney" on the page titled "John McKinney (California)". Cropped only — no resize, nothing composited; the source PNG has 0 transparent pixels.'),
        ('a4dd0a2c-564f-4e5c-9e1b-9bb942964cab', 'Cristian Morales',
         'https://s3.amazonaws.com/ballotpedia-api4/files/ChristianMorales26-2_2026-09-03_181854.jpg',
         'Candidate photograph published by Ballotpedia (ballotpedia.org), alt text "Image of Cristian Morales" on the page naming the office, Candidate U.S. House California District 43. Cropped and downscaled only; not composited. (Replaces a photo_origin_url that pointed at an Instagram profile, which the source standard does not permit.)'),
        ('3ce8b7fa-a703-45be-9e07-71b1a8ebfa8d', 'Sara Hernandez',
         'https://s3.amazonaws.com/ballotpedia-api4/files/SaraHernandez2022.jpg',
         'Photograph published by Ballotpedia (ballotpedia.org). The same photograph, at full size: the 200x300 file published here until now was byte-identical to Ballotpedia''s thumbnail of this original. Cropped and downscaled only; not composited.'),
        ('7b99c301-222a-4ebf-8427-c7290685e245', 'Angela Gonzales-Torres',
         'https://s3.amazonaws.com/ballotpedia-api4/files/Angela_GonzalesTorres_20250814_062216.jpg',
         'Candidate photograph published by Ballotpedia (ballotpedia.org), alt text "Image of Angela Gonzales-Torres". The same photograph, at full size: the 200x300 file published here until now was byte-identical to Ballotpedia''s thumbnail of this original. Cropped and downscaled only; not composited.')
      ) AS b(pid, nm, origin, lic)
      LEFT JOIN essentials.politicians p ON p.id = b.pid::uuid
  LOOP
    n_seen := n_seen + 1;
    IF r.found IS NULL THEN
      RAISE EXCEPTION 'CC_0205: politician % (%) not found', r.nm, r.pid;
    END IF;
    IF r.db_name IS DISTINCT FROM r.nm THEN
      RAISE EXCEPTION 'CC_0205: % is named "%" in the database, expected "%" — refusing to touch the wrong row',
        r.pid, r.db_name, r.nm;
    END IF;
    IF r.override THEN
      RAISE EXCEPTION 'CC_0205: % carries photo_custom_url_manual_override — refusing', r.nm;
    END IF;
    IF r.restriction IS NOT NULL THEN
      RAISE EXCEPTION 'CC_0205: % carries photo_restriction_code % — refusing', r.nm, r.restriction;
    END IF;
    IF r.n_default <> 1 THEN
      RAISE EXCEPTION 'CC_0205: % has % rows of type=default, expected exactly 1', r.nm, r.n_default;
    END IF;

    -- ------------------------------------------------------------------- write
    v_url := v_base || r.pid::text || '.jpg';

    UPDATE essentials.politicians
       SET photo_custom_url = v_url,
           photo_origin_url = r.origin,
           last_update_date = now()
     WHERE id = r.pid
       AND (photo_custom_url IS DISTINCT FROM v_url
            OR photo_origin_url IS DISTINCT FROM r.origin);

    UPDATE essentials.politician_images
       SET url = v_url,
           photo_license = r.lic
     WHERE politician_id = r.pid
       AND type = 'default'
       AND (url IS DISTINCT FROM v_url OR photo_license IS DISTINCT FROM r.lic);

    -- ------------------------------------------------------------------ verify
    SELECT p.photo_custom_url, p.photo_origin_url,
           (SELECT count(*) FROM essentials.politician_images i
             WHERE i.politician_id = r.pid AND i.type = 'default'),
           (SELECT i.url FROM essentials.politician_images i
             WHERE i.politician_id = r.pid AND i.type = 'default' LIMIT 1),
           (SELECT i.photo_license FROM essentials.politician_images i
             WHERE i.politician_id = r.pid AND i.type = 'default' LIMIT 1)
      INTO v_url, v_origin, v_ndef, v_grid, v_lic
      FROM essentials.politicians p
     WHERE p.id = r.pid;

    IF v_ndef <> 1 THEN
      RAISE EXCEPTION 'CC_0205: % has % rows of type=default after the write, expected exactly 1',
        r.nm, v_ndef;
    END IF;
    IF v_url IS DISTINCT FROM v_base || r.pid::text || '.jpg' THEN
      RAISE EXCEPTION 'CC_0205: % has photo_custom_url %, expected %',
        r.nm, coalesce(v_url, '<null>'), v_base || r.pid::text || '.jpg';
    END IF;
    -- The grid reads images[] and the backend reads the scalar. If they disagree the API can look
    -- correct while the page does not change at all — that is CC_0195, and it cost a second
    -- migration to discover.
    IF v_grid IS DISTINCT FROM v_url THEN
      RAISE EXCEPTION 'CC_0205: % renders % in the grid but % through the API — they must agree',
        r.nm, coalesce(v_grid, '<null>'), coalesce(v_url, '<null>');
    END IF;
    IF v_origin IS DISTINCT FROM r.origin THEN
      RAISE EXCEPTION 'CC_0205: % has photo_origin_url %, expected %',
        r.nm, coalesce(v_origin, '<null>'), r.origin;
    END IF;
    -- Provenance must name an external image FILE, never a page and never our own bucket.
    IF v_origin LIKE '%kxsdzaojfaibhuzmclfq%' OR v_origin !~* '\.(png|jpe?g|webp)$' THEN
      RAISE EXCEPTION 'CC_0205: % has photo_origin_url %, expected an external image file',
        r.nm, v_origin;
    END IF;
    -- No social media source may survive this migration. That is the defect Morales carried.
    IF v_origin ~* '(instagram|facebook|twitter|x\.com|linkedin|tiktok)' THEN
      RAISE EXCEPTION 'CC_0205: % still points at a social media source: %', r.nm, v_origin;
    END IF;
    IF v_lic IS DISTINCT FROM r.lic THEN
      RAISE EXCEPTION 'CC_0205: % carries the wrong licence text', r.nm;
    END IF;

    n_ok := n_ok + 1;
  END LOOP;

  IF n_seen <> 4 OR n_ok <> 4 THEN
    RAISE EXCEPTION 'CC_0205: saw % rows and verified %, expected 4 and 4', n_seen, n_ok;
  END IF;

  RAISE NOTICE 'CC_0205: 4 LA headshots repointed; grid and API agree on every one';
END $$;

COMMIT;
