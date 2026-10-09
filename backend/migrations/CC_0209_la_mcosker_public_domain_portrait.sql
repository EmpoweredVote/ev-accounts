-- CC_0209 — Tim McOsker to the official public-domain portrait (LA replenish, batch 8)
--
-- Councilmember, Los Angeles Council District 15. The last "needs a new source" item on the LA
-- list that had a concrete lead, and the lead paid off sideways: it proved the city's own file was
-- a dead end and pointed somewhere better.
--
-- WAS. 600x750, an ENLARGEMENT of a 400x267 original. A street scene — arms folded on a pavement,
-- parked cars and trees behind, head about 15% of frame. At the production card size (95x127,
-- object-fit cover) his face is clipped at the left edge because the frame is not centred on him.
--
-- 🔴 THE CITY WAS NEVER THE CEILING; IT WAS A COPY OF A COPY. cd15.lacity.gov/meet-tim serves
-- `.../styles/landscape_wide_medium_636x358_/public/2022-12/51857445559_77ab216038_w (1) (1).jpg.webp`
-- — a Drupal 636x358 derivative of a file the city had itself downloaded from Flickr at the `_w`
-- size, which is 400 px wide. So the "400x267 ceiling at lacity.gov" recorded on the worklist was
-- real but misleading: it was the ceiling of a borrowed thumbnail, not of the photograph.
--
-- THE FLICKR LEAD, AND WHY IT IS REJECTED. The filename is a Flickr id, so it resolved:
-- flickr.com/photos/193472024@N08/51857445559 — HIS OWN account, so a permitted source class.
-- But the file is titled `©CourtneyLindbergPhotography_082421_3326`, the page states
-- **All rights reserved**, and the largest size Flickr will serve is `_b` at 1024x683 (`_h` and
-- `_k` both 410). It is also LANDSCAPE and a street scene: measured, a compliant 4:5 crop of it
-- yields only about 350x438. Worse licence, worse picture, smaller output.
--
-- NOW. `Tim_McOsker_full_portrait_(cropped).jpg` from Wikimedia Commons, 1045x1393 — the official
-- studio portrait: suit, tie, the city flag behind him, plain backdrop. The same frame the other
-- nineteen Los Angeles officeholders are shot in.
--   Author:  Los Angeles City Council District 15
--   Date:    13 January 2023
--   Licence: PUBLIC DOMAIN. "This work was created by a government unit ... that derives its
--            powers from the laws of the State of California and is subject to disclosure under
--            the California Public Records Act (Government Code § 7920 et seq.). It is a public
--            record that was not created by an agency which state law has allowed to claim
--            copyright, and is therefore in the public domain in the United States."
--            (Commons PD-CAGov, citing County of Santa Clara v. CFAC.)
--
-- ⚠ COMMONS RECORDS THE ORIGIN AS A COUNCIL-DISTRICT FACEBOOK POST, AND THE OPERATOR RULED ON IT
-- (2026-10-09). The house rule is press/official only, no Facebook photographs. That rule guards
-- against unlicensed personal pictures; it does not reach this one. The AUTHOR is the government
-- body, the work is public domain BY STATUTE rather than by anyone's permission, and Facebook is
-- the venue the city published in, not the rights holder. Recorded here so the next person meets
-- the reasoning rather than the exception.
--
-- THE CROP. 1032x1290, A PURE CROP WITH NO RESIZE — the output is native pixels. Head 49.5% of
-- frame, air above the hair 7.8%, FACE CENTRE EXACTLY 50.0% of the width, chroma 36.5 (passes the
-- no-monochrome gate). The crop is the full height minus the bottom, and 13 px off the right, which
-- is what centring the face on a 1045-wide frame costs.
--
-- 🔴 THE MEASUREMENTS WERE CHECKED AGAINST THE PICTURE, NOT JUST COMPUTED. On the Flickr street
-- scene the head-top scan read row 9 against a true hair line near row 51 — busy background, the
-- same failure as CC_0205's flags and brickwork. On THIS portrait the backdrop is plain and all
-- three horizontal readings agree for once: face box 516, skin centroid 521, five pixels apart.
--
-- 🔴 THIS ALSO RETIRES A FALSE LICENCE CLAIM. The row being replaced asserts `cc_by_sa_4.0`. That
-- was never true: the file is a Drupal derivative of a Flickr photograph whose own page says
-- **All rights reserved** and whose title carries a photographer's copyright notice. Nobody
-- licensed it CC BY-SA. Same defect class as Price's `cc_by_sa_4.0` (CC_0195) and Schmerelson's
-- `government-official` asserted over a NULL origin (CC_0204) — a licence written from the shape of
-- a URL rather than from anything the source said. The replacement is public domain by statute and
-- says which statute.
--
-- 🔴 WRITES BOTH FIELDS. The browse grid reads essentials.politician_images first and falls back to
-- politicians.photo_custom_url; the backend read paths do the reverse. The gate requires the pair
-- to agree, and exactly one type='default' row.
--
-- Idempotent. No DDL. Rollback is one UPDATE; the old object is still in the bucket:
--   photo_custom_url was .../politician_photos/5cf02835-9024-4a00-80f7-bc2dcc3165df-headshot.jpg
--   photo_origin_url was https://cd15.lacity.gov/sites/g/files/wph2096/files/styles/landscape_wide_medium_636x358_/public/2022-12/51857445559_77ab216038_w%20%281%29%20%281%29.jpg.webp?itok=pWpR7D5K

BEGIN;

DO $$
DECLARE
  c_pid     constant uuid := '5cf02835-9024-4a00-80f7-bc2dcc3165df';
  c_name    constant text := 'Tim McOsker';
  c_url     constant text :=
    'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/5cf02835-9024-4a00-80f7-bc2dcc3165df.jpg';
  c_origin  constant text :=
    'https://upload.wikimedia.org/wikipedia/commons/3/3e/Tim_McOsker_full_portrait_%28cropped%29.jpg';
  c_licence constant text :=
    'Public domain. Official portrait by Los Angeles City Council District 15, 13 January 2023, via Wikimedia Commons (Tim_McOsker_full_portrait_(cropped).jpg, 1045x1393). PD-CAGov: a public record of a California government unit under the California Public Records Act, Gov. Code s 7920 et seq.; County of Santa Clara v. CFAC holds such an entity cannot enforce copyright. Cropped 4:5 to 1032x1290 with NO resize; nothing composited. Commons records the origin as a council-district Facebook post — the author is the government body and the licence is statutory, which the operator ruled is outside the no-Facebook-photographs rule (2026-10-09).';
  r         record;
  v_ndef    int;
BEGIN
  SELECT p.full_name, coalesce(p.photo_custom_url_manual_override,false) AS override,
         p.photo_restriction_code AS restriction,
         (SELECT count(*) FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default') AS n_default
    INTO r FROM essentials.politicians p WHERE p.id = c_pid;

  IF r.full_name IS NULL THEN
    RAISE EXCEPTION 'CC_0209: politician % not found', c_pid;
  END IF;
  IF r.full_name IS DISTINCT FROM c_name THEN
    RAISE EXCEPTION 'CC_0209: % is named "%" in the database, expected "%" — refusing to touch the wrong row',
      c_pid, r.full_name, c_name;
  END IF;
  IF r.override THEN
    RAISE EXCEPTION 'CC_0209: % carries photo_custom_url_manual_override — refusing', c_name;
  END IF;
  IF r.restriction IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0209: % carries photo_restriction_code % — refusing', c_name, r.restriction;
  END IF;
  IF r.n_default <> 1 THEN
    RAISE EXCEPTION 'CC_0209: % has % rows of type=default, expected exactly 1', c_name, r.n_default;
  END IF;

  UPDATE essentials.politicians
     SET photo_custom_url = c_url, photo_origin_url = c_origin, last_update_date = now()
   WHERE id = c_pid
     AND (photo_custom_url IS DISTINCT FROM c_url OR photo_origin_url IS DISTINCT FROM c_origin);

  UPDATE essentials.politician_images
     SET url = c_url, photo_license = c_licence
   WHERE politician_id = c_pid AND type = 'default'
     AND (url IS DISTINCT FROM c_url OR photo_license IS DISTINCT FROM c_licence);

  -- verify
  SELECT p.photo_custom_url, p.photo_origin_url,
         (SELECT count(*) FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default'),
         (SELECT i.url FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default' LIMIT 1),
         (SELECT i.photo_license FROM essentials.politician_images i
           WHERE i.politician_id = p.id AND i.type = 'default' LIMIT 1)
    INTO r FROM essentials.politicians p WHERE p.id = c_pid;

  IF r.count <> 1 THEN
    RAISE EXCEPTION 'CC_0209: % has % default image rows after the write, expected 1', c_name, r.count;
  END IF;
  IF r.photo_custom_url IS DISTINCT FROM c_url THEN
    RAISE EXCEPTION 'CC_0209: % has photo_custom_url %, expected %',
      c_name, coalesce(r.photo_custom_url,'<null>'), c_url;
  END IF;
  -- The grid reads images[] and the backend the scalar. If they disagree the API looks correct
  -- while the page does not change at all — that is CC_0195.
  IF r.url IS DISTINCT FROM r.photo_custom_url THEN
    RAISE EXCEPTION 'CC_0209: % renders % in the grid but % through the API — they must agree',
      c_name, coalesce(r.url,'<null>'), coalesce(r.photo_custom_url,'<null>');
  END IF;
  IF r.photo_origin_url IS DISTINCT FROM c_origin THEN
    RAISE EXCEPTION 'CC_0209: % has photo_origin_url %, expected %',
      c_name, coalesce(r.photo_origin_url,'<null>'), c_origin;
  END IF;
  -- Provenance must name an external image FILE, never a page and never our own bucket.
  IF r.photo_origin_url LIKE '%kxsdzaojfaibhuzmclfq%'
     OR r.photo_origin_url !~* '\.(png|jpe?g|webp)$' THEN
    RAISE EXCEPTION 'CC_0209: % has photo_origin_url %, expected an external image file',
      c_name, r.photo_origin_url;
  END IF;
  -- No social media source may survive (CC_0205's rule). The Facebook ORIGIN is described in the
  -- licence prose; the citation itself must point at Commons.
  IF r.photo_origin_url ~* '(instagram|facebook|twitter|x\.com|linkedin|tiktok)' THEN
    RAISE EXCEPTION 'CC_0209: % still cites a social media source: %', c_name, r.photo_origin_url;
  END IF;
  IF r.photo_license IS DISTINCT FROM c_licence THEN
    RAISE EXCEPTION 'CC_0209: % carries the wrong licence text', c_name;
  END IF;

  RAISE NOTICE 'CC_0209: McOsker on the public-domain official portrait; grid and API agree';
END $$;

COMMIT;
