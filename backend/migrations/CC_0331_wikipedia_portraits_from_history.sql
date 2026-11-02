-- CC_0331_wikipedia_portraits_from_history.sql
--
-- The last 4 recoverable rows of the unversioned CC BY-SA cohort. All four are PUBLIC DOMAIN;
-- none was Creative Commons. Origins move to the Commons file description page.
--
-- 🔴 THE VALUE THIS OVERWRITES: each row currently reads exactly 'cc_by-sa', and each row's old
--    photo_origin_url is carried in the staged table below. Nothing else records either.
--
-- WHY ONLY 4 OF 61, AND WHY THAT IS THE ANSWER RATHER THAN A SHORTFALL
--   CC_0330 corrected the 26 rows whose photograph is still the article's lead image. The other
--   61 were refused there. Four routes were then measured against those 61:
--
--     route                              tested   recovered   control
--     SHA1 reverse lookup on Commons        12         0       n/a -- our files are cropped
--     Commons name search                   12         0       4 of 5 KNOWN files found (~80% recall)
--     every image on the current article    61         2       --
--     infobox images across the history     61         2       Christian Menefee, 0.79
--
--   ⚠ The search route's control is what makes its zero mean anything: run against rows whose
--     Commons file CC_0330 had already confirmed, it found 4 of 5. It works; the photographs are
--     simply not there.
--
--   ▶ SO FOR THE REMAINING 57, THE PHOTOGRAPH IS NOT ON WIKIPEDIA IN ANY FORM -- not the current
--     lead image, not elsewhere on the article, not in the infobox at any point in its history,
--     and not findable on Commons by name. Their recorded Wikipedia origin therefore records
--     where somebody was LOOKING, not where the file came from. They are left untouched: there
--     is no licence to recover and the origin cannot be trusted either. See the PR.
--
-- 🔴🔴 EVERY ROW CARRIES ITS OWN PROOF THAT THE COMMONS FILE IS OUR PHOTOGRAPH, measured by mean
--     absolute difference after downscaling both to a common size -- the same test and the same
--     thresholds as CC_0330.
--     Christian Menefee      mad  0.79   via historic
--     Emma Sharif            mad  0.00   via on-page
--     Morgan Luttrell        mad  0.97   via on-page
--     Ronny Jackson          mad  0.90   via historic
--     negative controls on this cohort ran 49 - 121.
--
-- ⚠ A MEASUREMENT RUN THAT DEGRADES LOOKS EXACTLY LIKE A NEGATIVE RESULT. The first pass over
--   these 61 reported 0 matches: image downloads were failing and each failure was silently
--   becoming "no match". It was caught because a known match came back at 57.9 instead of 0.79
--   with an IDENTICAL candidate list. The cause was not rate limiting but .ogg recordings of
--   floor speeches, which are not images; they are filtered by MIME now, and the final pass
--   reported 0 fetch failures and 0 unjudged rows.
--
-- Read 2026-11-02 from the live Wikipedia and Commons APIs; file titles were asked for, never built.

BEGIN;

CREATE TEMP TABLE lic_before ON COMMIT DROP AS
  SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
    FROM essentials.politician_images GROUP BY 1;

CREATE TEMP TABLE hist_fix (
  image_id      uuid PRIMARY KEY,
  politician_id uuid NOT NULL,
  who           text NOT NULL,
  new_licence   text NOT NULL,
  old_origin    text NOT NULL,
  new_origin    text NOT NULL,
  artist        text NOT NULL,
  mad           numeric NOT NULL,
  route         text NOT NULL
) ON COMMIT DROP;

INSERT INTO hist_fix (image_id, politician_id, who, new_licence, old_origin, new_origin, artist, mad, route) VALUES
  ('28b9e10e-4c19-40af-b629-531aa922579b'::uuid, '76cfc903-921f-4c45-b10a-cbfa8bb1859f'::uuid, 'Christian Menefee', 'public_domain',
   'https://en.wikipedia.org/wiki/Christian_Menefee', 'https://commons.wikimedia.org/wiki/File:Christian_Menefee,_official_portrait_(119th_Congress).jpg', '', 0.79, 'historic'),
  ('b2ca3fcd-65c8-40cb-b0f9-32a34312026a'::uuid, '174f3f47-e4ee-4775-ab6f-f1039d608098'::uuid, 'Emma Sharif', 'public_domain',
   'https://en.wikipedia.org/wiki/Emma_Sharif', 'https://commons.wikimedia.org/wiki/File:Emma_Sharif,_mayor_of_Compton.jpg', '', 0.00, 'on-page'),
  ('9bd5ddde-40e6-44a8-bb52-b5fc77683717'::uuid, 'b638dec8-86d9-4741-959f-002e7850a630'::uuid, 'Morgan Luttrell', 'public_domain',
   'https://en.wikipedia.org/wiki/Morgan_Luttrell', 'https://commons.wikimedia.org/wiki/File:Rep._Morgan_Luttrell_official_photo.jpg', '', 0.97, 'on-page'),
  ('17c7559e-ebfd-4414-bf1b-521b456ff6c5'::uuid, '184670b8-6647-4f84-a5fb-f2a9cfae3f5a'::uuid, 'Ronny Jackson', 'public_domain',
   'https://en.wikipedia.org/wiki/Ronny_Jackson', 'https://commons.wikimedia.org/wiki/File:Ronny_Jackson_117th_U.S_Congress.jpg', '', 0.90, 'historic');

-- ---------------------------------------------------------------------------------------------
-- Pre-flight.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM hist_fix;
  IF v_n <> 4 THEN RAISE EXCEPTION 'pre-flight: expected 4 staged rows, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM hist_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id;
  IF v_n <> 4 THEN RAISE EXCEPTION 'pre-flight: % of 4 staged images exist', v_n; END IF;

  SELECT count(*) INTO v_n FROM hist_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.photo_license IS DISTINCT FROM 'cc_by-sa';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % staged row(s) no longer carry the unversioned cc_by-sa', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM hist_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.politician_id IS DISTINCT FROM f.politician_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % staged image(s) belong to another politician', v_n; END IF;

  -- 🔴 The recorded old origin must still be what the database holds, or this overwrite destroys
  --    a value the file does not record.
  SELECT count(*) INTO v_n FROM hist_fix f JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE coalesce(p.photo_origin_url, '') IS DISTINCT FROM f.old_origin;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % staged row(s) no longer carry their recorded old origin', v_n;
  END IF;

  -- Recomputed from the database, not from the staged column.
  SELECT count(*) INTO v_n FROM hist_fix f JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE coalesce(p.photo_origin_url, '') !~* '^https://en\.wikipedia\.org/wiki/';
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % staged row(s) are not Wikipedia-sourced', v_n; END IF;

  SELECT count(*) INTO v_n FROM hist_fix
   WHERE new_origin !~ '^https://commons\.wikimedia\.org/wiki/File:';
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % new origin(s) are not a Commons file page', v_n; END IF;

  SELECT count(*) INTO v_n FROM hist_fix WHERE new_licence NOT IN ('cc0', 'cc_by_2.0', 'cc_by_3.0', 'cc_by_4.0', 'cc_by-sa', 'cc_by-sa_2.0', 'cc_by-sa_3.0', 'cc_by-sa_4.0', 'public_domain');
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % row(s) target a non-canonical licence', v_n; END IF;

  -- 🔴 A CC licence other than CC0 requires attribution. None of these four is CC -- but the
  --    invariant is what is being asserted, not the current contents.
  SELECT count(*) INTO v_n FROM hist_fix
   WHERE new_licence LIKE 'cc\_%' AND new_licence <> 'cc0' AND btrim(artist) = '';
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % CC row(s) name no author', v_n; END IF;

  -- 🔴 THE SAME-PHOTOGRAPH PROOF.
  SELECT count(*) INTO v_n FROM hist_fix WHERE mad >= 6.0;
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % staged row(s) did not match their Commons file', v_n; END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
UPDATE essentials.politician_images pi
   SET photo_license = f.new_licence
  FROM hist_fix f
 WHERE pi.id = f.image_id AND pi.photo_license = 'cc_by-sa';

UPDATE essentials.politicians p
   SET photo_origin_url = f.new_origin
  FROM hist_fix f
 WHERE p.id = f.politician_id AND coalesce(p.photo_origin_url, '') = f.old_origin;

-- ---------------------------------------------------------------------------------------------
-- Post-verify.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_before int;
BEGIN
  SELECT count(*) INTO v_n FROM hist_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.photo_license = f.new_licence;
  IF v_n <> 4 THEN RAISE EXCEPTION 'post-verify: % of 4 carry their corrected licence', v_n; END IF;

  SELECT count(*) INTO v_n FROM hist_fix f JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE p.photo_origin_url = f.new_origin;
  IF v_n <> 4 THEN RAISE EXCEPTION 'post-verify: % of 4 point at their Commons file page', v_n; END IF;

  -- 🔴 Delta, not a total.
  SELECT coalesce((SELECT n FROM lic_before WHERE lic = 'cc_by-sa'), 0) INTO v_before;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE photo_license = 'cc_by-sa';
  IF v_before - v_n <> 4 THEN
    RAISE EXCEPTION 'post-verify: unversioned cc_by-sa fell by %, expected 4', v_before - v_n;
  END IF;

  SELECT count(*) INTO v_n FROM (
    SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
      FROM essentials.politician_images GROUP BY 1
  ) a
  FULL JOIN lic_before b ON b.lic = a.lic
   WHERE coalesce(a.n, 0) <> coalesce(b.n, 0)
     AND coalesce(a.lic, b.lic) <> 'cc_by-sa'
     AND coalesce(a.lic, b.lic) NOT IN (SELECT DISTINCT new_licence FROM hist_fix);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'post-verify: % licence value(s) outside the corrected set changed count', v_n;
  END IF;
END $$;

COMMIT;
