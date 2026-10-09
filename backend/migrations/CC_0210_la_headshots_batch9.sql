-- CC_0210 — the last four Los Angeles headshots (LA replenish, batch 9)
--
-- Brignano · Jurado · Becerra · Mota. This closes the 19-row worklist opened on 2026-10-07.
-- Three of the four are PURE CROPS with no resize. The fourth (Becerra) is a crop-free 2x
-- downscale. NOTHING IS ENLARGED and nothing is composited.
--
-- Proof sheet the operator approved: https://claude.ai/artifact/YSu7TgnzbadRwtv3FhXXgb
--
--
-- 1. HOUSTON BRIGNANO (b7c00468) — Candidate, U.S. House California District 36
--    🔴 THE WORKLIST FIGURE FOR THIS ROW WAS WRONG. It recorded "full-body standing shot, head
--    ≈10% of frame". Measured, his head is 27.3% of the frame — inside the 20–62% bar. The live
--    600x750 is also NOT an enlargement: it is a 1.36x DOWNSCALED CROP of the Ballotpedia frame
--    below (mean absolute difference 3.1 against the reconstructed crop; edge energy at a matched
--    200 px face 3.79 against 3.85).
--    So this is a framing improvement, not a rescue, and it was shipped on that basis.
--    Now: `Houston_Brignano_20260428_022543.jpg`, 1024x1024, cropped to 496x620. A PURE CROP WITH
--    NO RESIZE. Head 45.0% of frame, air above the hair 9.0%, face centre 50.0% of the width,
--    chroma 32.3. The face box grows from 169 px to 230 px — 1.36x more face — although the frame
--    itself is smaller in pixels than the file it replaces. 496 px clears the 300 px floor.
--    🔴 REJECTED, AND MEASURED: voteforhouston.com publishes a 2135x2996 studio portrait of him.
--    It is a TRANSPARENT-BACKGROUND CUTOUT (36.9% of its pixels transparent), so shipping it would
--    need a composited backdrop — the thing the operator rejected on Girvan in CC_0198 — AND his
--    hair is clipped flat by the top edge (row 0 is 36%, 91% and 35% opaque across the crown),
--    which no crop can undo. Its rim is darker than its interior (86.5 against 132.7), so there is
--    no white matte baked in; that part was sound. Every other image on that site is a letter.
--
-- 2. YSABEL J. JURADO (04d12540) — Los Angeles City Council, District 14
--    🔴 TWO DEFECTS, NEITHER OF THEM ON THE WORKLIST, WHICH LISTED ONLY "loud mural background".
--    (a) The live file is an ENLARGEMENT. Its face box is 204 px, upscaled from the 144 px face in
--        cd14.lacity.gov's own `Cd14-Ysabeljurado_960x530.png` — a 960x530 LANDSCAPE derivative.
--        Edge energy at a matched 200 px face is the same either way, 5.19 against 5.11: more
--        pixels, no more detail.
--    (b) Its photo_license read `cc_by_sa_4.0`, asserted over a Drupal CMS derivative path. Nobody
--        licensed that file CC BY-SA. This is the FOURTH licence in this programme written from
--        the shape of a URL, after Price (CC_0195), Schmerelson (CC_0204) and McOsker (CC_0209).
--    Now: Wikimedia Commons `Ysabel Jurado, 2025.jpg`, 1920x1280, cropped to 777x971. A PURE CROP
--    WITH NO RESIZE. Head 45.0%, air above the hair 9.0%, face centre 50.1%, chroma 47.1. The face
--    box grows from 204 px to 349 px — 1.7x more face — and the mural behind her is thrown out of
--    focus in this frame instead of sharp.
--    Author: Los Angeles's 14th City Council district, 12 February 2025. Public domain under the
--    California Public Records Act (PD-CAGov) — her own council district is the author, the same
--    statutory basis CC_0209 used for McOsker.
--    Rejected, measured: Commons also holds `Ysabel Jurado, 2024.jpg`, 708x944 and also public
--    domain, but it is a video still caught mid-sentence with edge energy 1.44.
--
-- 3. XAVIER BECERRA (0f74219c) — Candidate, Governor of California
--    Was: 600x750, a candid at a campaign event. A microphone intrudes at the bottom and his face
--    sits at 65.2% of the frame width, so the production card — which crops the sides — cut him
--    off centre. photo_origin_url held a campaign HOME PAGE, not an image.
--    Now: Wikimedia Commons `HHS Xavier Becerra.jpg`, 2400x3000, already exactly 4:5, downscaled
--    2x to 1200x1500. NO CROP AND NO ENLARGEMENT. Head 42.8% of frame, air above the hair 4.4%,
--    face centre 49.2%, chroma 44.4. Face box 1011 px.
--    Author: United States Department of Health and Human Services, 30 August 2021. Public domain
--    as a work of the United States federal government.
--    ⚠ OPERATOR RULING 2026-10-08: this is his official portrait in a FEDERAL office he no longer
--    holds, made five years ago, while he is running for Governor. Put to the operator against the
--    current campaign photograph and the official portrait was chosen.
--    Rejected, measured: xavierbecerra2026.com's `homepage-2000x1328.webp` is current and
--    on-message, but he looks away from the camera in a three-quarter environmental shot and its
--    face box is 295 px against 1011 px here. A 4:5 crop of it yields about 982x1227.
--
-- 4. SAMANTHA MOTA (a3f12544) — Candidate, U.S. House California District 37
--    Was: 600x750, arm raised against a mural. Not a portrait.
--    🟢 NOT AN ENLARGEMENT — her campaign publishes that same frame at 5184x3456. It was simply
--    the wrong frame. A DIFFERENT FRAME FROM THE SAME SHOOT is a head-and-shoulders portrait.
--    Now: `motaforcongress.com`'s hero image, 2304x1536, cropped to 1126x1407. A PURE CROP WITH NO
--    RESIZE. Head 51.9%, air above the hair 7.8%, face centre 50.0%, chroma 80.8. The raised arm,
--    the tattoo and most of the mural fall outside the crop.
--
--
-- 🔴 THE HEAD TOP WAS READ OFF EACH PHOTOGRAPH AT 4x, NOT TAKEN FROM A DETECTOR. Both automatic
-- detectors failed again, each on what the other gets right: the background-departure column scan
-- put Brignano's head top 229 px too high (it latched onto the eagle finial on the flagpole above
-- him) and Mota's 193 px too high (the painted mural shapes), while GrabCut returned 0 on both
-- Becerra and Jurado. The face-box centre and the eye midpoint agreed on all four subjects, so
-- those are what the crops are centred on. NEITHER DETECTOR IS RIGHT EVERYWHERE — the picture is
-- the control, and that is what this programme has now learned three times.
--
-- 🔴 WRITES BOTH FIELDS. The browse grid reads essentials.politician_images first and falls back to
-- politicians.photo_custom_url; the backend read paths do the reverse. The gate below requires the
-- pair to agree, and requires exactly one type='default' row per person — two make the grid's
-- find() pick an arbitrary one. That is the rule CC_0195 paid for.
--
-- Idempotent: each UPDATE is guarded on the value differing, and re-running verifies and changes
-- nothing. No DDL, so it applies as `ev_api` or as `postgres`.
--
-- Every old object was left in the bucket, so rollback is one UPDATE per person:
--   b7c00468 … photo_custom_url .../politician_photos/b7c00468-c2b4-4e48-876b-d218f3b53eac-headshot.jpg
--              photo_origin_url https://ballotpedia.org/California%27s_36th_Congressional_District_election,_2026
--              photo_license    press_use
--   04d12540 … photo_custom_url .../politician_photos/04d12540-8075-4263-894a-6575f7c9bd14-headshot.jpg
--              photo_origin_url https://cd14.lacity.gov/sites/g/files/wph2351/files/styles/large_hero_image_jumbotron_full_height_1_2_800x530_/public/2024-11/Cd14-Ysabeljurado_960x530.png.webp?itok=yT94rhWU
--              photo_license    cc_by_sa_4.0
--   0f74219c … photo_custom_url .../politician_photos/0f74219c-7d10-4d29-85fe-0f1d834df8a7-headshot.jpg?v=20260623
--              photo_origin_url https://www.xavierbecerra2026.com
--              photo_license    press_use
--   a3f12544 … photo_custom_url .../politician_photos/a3f12544-4d18-41da-a69e-9585219985d5-headshot.jpg
--              photo_origin_url https://ballotpedia.org/California%27s_37th_Congressional_District_election,_2026
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
  FOR r IN
    SELECT b.pid::uuid AS pid, b.nm, b.origin, b.lic,
           p.id AS found, p.full_name AS db_name,
           coalesce(p.photo_custom_url_manual_override, false) AS override,
           p.photo_restriction_code AS restriction,
           (SELECT count(*) FROM essentials.politician_images i
             WHERE i.politician_id = b.pid::uuid AND i.type = 'default') AS n_default
      FROM (VALUES
        ('b7c00468-c2b4-4e48-876b-d218f3b53eac', 'Houston Brignano',
         'https://s3.amazonaws.com/ballotpedia-api4/files/Houston_Brignano_20260428_022543.jpg',
         'Candidate photograph published by Ballotpedia (ballotpedia.org) on the page titled "Houston Brignano". Cropped only — no resize, nothing composited. Replaces a photo_origin_url that named a Ballotpedia ELECTION PAGE rather than the image; the file published here until now was a 1.36x downscaled crop of this same frame.'),
        ('04d12540-8075-4263-894a-6575f7c9bd14', 'Ysabel J. Jurado',
         'https://upload.wikimedia.org/wikipedia/commons/3/3f/Ysabel_Jurado%2C_2025.jpg',
         'Official photograph published on Wikimedia Commons as "Ysabel Jurado, 2025.jpg". Author: Los Angeles''s 14th City Council district, 12 February 2025. PUBLIC DOMAIN under the California Public Records Act (PD-CAGov; County of Santa Clara v. CFAC), the author being the government body itself. Cropped only — no resize, nothing composited. Replaces a cc_by_sa_4.0 claim that had been asserted over a cd14.lacity.gov Drupal derivative path; nobody had licensed that file CC BY-SA, and the file it was made from is a 960x530 landscape derivative that the published image had been enlarged from.'),
        ('0f74219c-7d10-4d29-85fe-0f1d834df8a7', 'Xavier Becerra',
         'https://upload.wikimedia.org/wikipedia/commons/8/85/HHS_Xavier_Becerra.jpg',
         'Official portrait of the Secretary of Health and Human Services, published on Wikimedia Commons as "HHS Xavier Becerra.jpg". Author: United States Department of Health and Human Services, 30 August 2021. PUBLIC DOMAIN as a work of the United States federal government. Downscaled 2x from 2400x3000; not cropped, not enlarged, not composited. Operator ruled on 2026-10-08 that this official portrait is preferred over the current campaign photograph, although it shows a federal office he no longer holds.'),
        ('a3f12544-4d18-41da-a69e-9585219985d5', 'Samantha Mota',
         'https://run.imgix.net/ec69a75a-edd3-44fc-b4d0-98626793b4c4/88a5d80a-a07a-4e69-811b-0dd98d53a2b1/88a5d80a-a07a-4e69-811b-0dd98d53a2b1.png',
         'Campaign photograph published on the candidate''s own site, motaforcongress.com, as the page hero. Cropped only — no resize, nothing composited. A different frame from the same shoot as the image published here until now; that one was the wrong frame rather than an enlargement, as her campaign serves it at 5184x3456.')
      ) AS b(pid, nm, origin, lic)
      LEFT JOIN essentials.politicians p ON p.id = b.pid::uuid
  LOOP
    n_seen := n_seen + 1;
    IF r.found IS NULL THEN
      RAISE EXCEPTION 'CC_0210: politician % (%) not found', r.nm, r.pid;
    END IF;
    IF r.db_name IS DISTINCT FROM r.nm THEN
      RAISE EXCEPTION 'CC_0210: % is named "%" in the database, expected "%" — refusing to touch the wrong row',
        r.pid, r.db_name, r.nm;
    END IF;
    IF r.override THEN
      RAISE EXCEPTION 'CC_0210: % carries photo_custom_url_manual_override — refusing', r.nm;
    END IF;
    IF r.restriction IS NOT NULL THEN
      RAISE EXCEPTION 'CC_0210: % carries photo_restriction_code % — refusing', r.nm, r.restriction;
    END IF;
    IF r.n_default <> 1 THEN
      RAISE EXCEPTION 'CC_0210: % has % rows of type=default, expected exactly 1', r.nm, r.n_default;
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
      RAISE EXCEPTION 'CC_0210: % has % rows of type=default after the write, expected exactly 1',
        r.nm, v_ndef;
    END IF;
    IF v_url IS DISTINCT FROM v_base || r.pid::text || '.jpg' THEN
      RAISE EXCEPTION 'CC_0210: % has photo_custom_url %, expected %',
        r.nm, coalesce(v_url, '<null>'), v_base || r.pid::text || '.jpg';
    END IF;
    -- The grid reads images[] and the backend reads the scalar. If they disagree the API can look
    -- correct while the page does not change at all — that is CC_0195, and it cost a second
    -- migration to discover.
    IF v_grid IS DISTINCT FROM v_url THEN
      RAISE EXCEPTION 'CC_0210: % renders % in the grid but % through the API — they must agree',
        r.nm, coalesce(v_grid, '<null>'), coalesce(v_url, '<null>');
    END IF;
    IF v_origin IS DISTINCT FROM r.origin THEN
      RAISE EXCEPTION 'CC_0210: % has photo_origin_url %, expected %',
        r.nm, coalesce(v_origin, '<null>'), r.origin;
    END IF;
    -- Provenance must name an external image FILE, never a page and never our own bucket. Three of
    -- the four rows here arrived carrying a PAGE url in this column.
    IF v_origin LIKE '%kxsdzaojfaibhuzmclfq%' OR v_origin !~* '\.(png|jpe?g|webp)$' THEN
      RAISE EXCEPTION 'CC_0210: % has photo_origin_url %, expected an external image file',
        r.nm, v_origin;
    END IF;
    -- No social media source may survive this migration (the guard CC_0205 introduced).
    IF v_origin ~* '(instagram|facebook|twitter|x\.com|linkedin|tiktok)' THEN
      RAISE EXCEPTION 'CC_0210: % still points at a social media source: %', r.nm, v_origin;
    END IF;
    IF v_lic IS DISTINCT FROM r.lic THEN
      RAISE EXCEPTION 'CC_0210: % carries the wrong licence text', r.nm;
    END IF;
    -- Jurado's old licence is the specific claim this migration exists to retract.
    IF r.nm = 'Ysabel J. Jurado' AND v_lic = 'cc_by_sa_4.0' THEN
      RAISE EXCEPTION 'CC_0210: Jurado still carries the cc_by_sa_4.0 claim this migration retracts';
    END IF;

    n_ok := n_ok + 1;
  END LOOP;

  IF n_seen <> 4 OR n_ok <> 4 THEN
    RAISE EXCEPTION 'CC_0210: saw % rows and verified %, expected 4 and 4', n_seen, n_ok;
  END IF;

  RAISE NOTICE 'CC_0210: 4 LA headshots repointed; grid and API agree on every one. The 19-row Los Angeles worklist is closed.';
END $$;

COMMIT;
