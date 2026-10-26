-- CC_0261_mirror_last_six_hotlinked_ballot_photos.sql
--
-- Repoints the LAST SIX published images that were served from somebody else's host at our
-- own bucket. After this, NOTHING we publish renders off-site: 9,159 profile images and 129
-- ballot images, all ours.
--
--   Ben Allen              s3.amazonaws.com (Ballotpedia)   200x300
--   David Serpa            s3.amazonaws.com (Ballotpedia)   200x300
--   Steven Craig Bradford  s3.amazonaws.com (Ballotpedia)   200x300
--   Robert P Howell        calmatters.org                   500x500
--   Merritt Farren         merrittfarrenca.com              1867x1902
--   Stacy A. Korsgaden     images.squarespace-cdn.com       2500x3122
--
-- All six are 2026 LA County Primary candidates for CA statewide office, all from the
-- 'ca-sos-2026' import, and ALL SIX HAVE NO politician_id -- which is why no mirroring step
-- ever reached them. The capability existed (upload-ut-candidate-photos.ts already handles a
-- candidate with no politician row; every ut/candidates/ object came from it) but it is Utah-
-- specific and TSV-driven, so the California import simply never ran anything like it.
-- Generalised into scripts/mirror-candidate-photos.py by the commit that carries this file.
--
-- 🔴 WHY THIS IS WORTH A MIGRATION AT ALL: A HOTLINK IS NOT A PHOTOGRAPH WE HAVE, IT IS A
-- PROMISE SOMEONE ELSE CAN WITHDRAW. CC_0260 blanked three published photographs that had
-- gone 404, 401 and 403 -- a rebuilt campaign site, a site moved behind auth, and a withdrawn
-- Google Sites image. Every one was live and correct when it was imported. No migration broke
-- them; the web did. All three were off-site. These six were the remaining exposure.
--
-- ⚠ NATIVE RESOLUTION, NOT THE 600x750 HOUSE CROP, AND THAT IS DELIBERATE. The 123 objects
-- already in this column are raw source bytes at their own size (456x336 up to 6016x4016).
-- Cropping here would have turned the three 200x300 Ballotpedia thumbnails into 3.00x
-- ENLARGEMENTS -- the defect class CC_0258 and CC_0260 spent the day removing -- to fix a
-- problem that is about WHO HOSTS THE FILE, not about how it is framed. Copying the bytes
-- cannot make an image worse. The three small ones are flagged below, not hidden.
--
-- Each file was face-checked before upload (0.93-0.95, one face each) and the script REFUSES
-- a frame with no face: upload-ut-candidate-photos.ts, which it generalises, uploaded raw
-- bytes unchecked, and that is exactly how three campaign YARD SIGNS reached ut/candidates/
-- and had to be replaced by CC_0255. Proven by control: pointed at one of those yard signs it
-- refuses, pointed at a real portrait it proceeds.
-- All six were looked at on a contact sheet: six real portraits of six different people.
-- Byte-verified served after upload: HTTP 200, sha256 identical, correct Content-Type
-- (Korsgaden's is WEBP and is stored .webp -- one existing object in this bucket is AVIF
-- served as .jpg, which is the mistake that avoids).
-- EXIF was checked too, because mirroring raw bytes would PRESERVE a sideways frame that a
-- crop pipeline would have fixed. None of the six carries a rotating orientation tag.
--
-- ▶ OWED, STATED NOT HIDDEN: Ben Allen, David Serpa and Steven Craig Bradford are 200x300
-- Ballotpedia thumbnails. Mirroring makes them OURS; it does not make them good. A better
-- source would be an improvement for all three.
--
-- 🔴 SEPARATE FINDING, DELIBERATELY NOT ACTED ON HERE: 'Ben Allen' (this ballot row, no
-- politician_id) and 'Benjamin Allen' (politician 4486f856-118b-475c-83f0-078581a7b268,
-- is_active, is_incumbent, and carrying OUR OWN 600x750 headshot) are visibly the same man,
-- and he advanced to the November general. Linking the rows would give that ballot page a
-- better picture for free. It is NOT done here because setting race_candidates.politician_id
-- is an identity assertion with much wider consequences than a photograph -- it attaches
-- stance research, campaign finance and occupancy to a person -- and the evidence here is a
-- name, a face and a press summary. That decision deserves its own migration and its own
-- sourcing. Mirroring the thumbnail is the reversible half.
--
-- Idempotent: re-running changes nothing. Nothing is deleted; the source hosts are untouched.

BEGIN;

CREATE TEMP TABLE _mirror (
  rc_id     uuid PRIMARY KEY,
  name_like text NOT NULL,
  url       text NOT NULL,
  was_host  text NOT NULL        -- the off-site host this replaces, for the guard
) ON COMMIT DROP;

INSERT INTO _mirror (rc_id, name_like, url, was_host) VALUES
  ('7e051229-78ac-4d73-842c-a570c108b4a5'::uuid, 'Ben Allen',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca/candidates/7e051229-78ac-4d73-842c-a570c108b4a5.jpg',
   '%s3.amazonaws.com%'),
  ('c4298104-0fe1-4e41-9047-d740e0245322'::uuid, 'David Serpa',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca/candidates/c4298104-0fe1-4e41-9047-d740e0245322.jpg',
   '%s3.amazonaws.com%'),
  ('6eddc523-7e09-4c0c-b2bf-b8fa2619844f'::uuid, 'Steven Craig Bradford',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca/candidates/6eddc523-7e09-4c0c-b2bf-b8fa2619844f.jpg',
   '%s3.amazonaws.com%'),
  ('a1c75c7e-2c3c-4b0d-a587-782be8b3fa70'::uuid, 'Robert P Howell',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca/candidates/a1c75c7e-2c3c-4b0d-a587-782be8b3fa70.jpg',
   '%calmatters.org%'),
  ('87a29ed4-cddc-45a0-985b-ee11d03cf1bf'::uuid, 'Merritt Farren',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca/candidates/87a29ed4-cddc-45a0-985b-ee11d03cf1bf.jpg',
   '%merrittfarrenca.com%'),
  ('b89d2130-4a3f-483d-9a51-38bc8224d647'::uuid, 'Stacy A. Korsgaden',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca/candidates/b89d2130-4a3f-483d-9a51-38bc8224d647.webp',
   '%squarespace-cdn.com%');

-- Guard: each row must still be the person and the off-site host this migration measured and
-- uploaded for. Already-mirrored is fine (idempotent); pointing somewhere ELSE is not.
DO $$
DECLARE r record; v_name text; v_url text;
BEGIN
  FOR r IN SELECT * FROM _mirror LOOP
    SELECT rc.full_name, rc.photo_url INTO v_name, v_url
      FROM essentials.race_candidates rc WHERE rc.id = r.rc_id;

    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0261: race_candidates row % does not exist', r.rc_id;
    END IF;
    IF v_name <> r.name_like THEN
      RAISE EXCEPTION 'CC_0261: % resolves to "%", expected "%"', r.rc_id, v_name, r.name_like;
    END IF;
    IF v_url IS DISTINCT FROM r.url AND v_url NOT LIKE r.was_host THEN
      RAISE EXCEPTION 'CC_0261: % now serves % - neither the mirror nor the % it replaces, REFUSING',
        r.name_like, v_url, r.was_host;
    END IF;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc
SET photo_url = m.url
FROM _mirror m
WHERE rc.id = m.rc_id AND rc.photo_url IS DISTINCT FROM m.url;

-- post-verify: these six point at the mirror, and NOTHING we publish renders off-site any more.
DO $$
DECLARE n_mirrored int; n_ballot_offsite int; n_profile_offsite int;
BEGIN
  SELECT count(*) INTO n_mirrored
    FROM _mirror m JOIN essentials.race_candidates rc ON rc.id = m.rc_id AND rc.photo_url = m.url;
  IF n_mirrored <> 6 THEN
    RAISE EXCEPTION 'CC_0261: expected 6 ballot rows on the mirror, found %', n_mirrored;
  END IF;

  -- the whole point: zero off-site, on BOTH columns, for everything that can render.
  SELECT count(*) INTO n_ballot_offsite
    FROM essentials.race_candidates rc
   WHERE NULLIF(rc.photo_url, '') IS NOT NULL
     AND rc.result IS DISTINCT FROM 'not_nominated'
     AND rc.photo_url NOT LIKE '%supabase.co/storage/v1/object/public/%';
  IF n_ballot_offsite <> 0 THEN
    RAISE EXCEPTION 'CC_0261: % live ballot row(s) still render off-site', n_ballot_offsite;
  END IF;

  SELECT count(*) INTO n_profile_offsite
    FROM essentials.politicians p
   WHERE p.is_active = true
     AND NULLIF(COALESCE(p.photo_custom_url, p.photo_origin_url), '') IS NOT NULL
     AND COALESCE(p.photo_custom_url, p.photo_origin_url)
         NOT LIKE '%supabase.co/storage/v1/object/public/%';
  IF n_profile_offsite <> 0 THEN
    RAISE EXCEPTION 'CC_0261: % active profile row(s) still render off-site', n_profile_offsite;
  END IF;

  RAISE NOTICE 'CC_0261 OK - six mirrored; 0 published images render from an outside host';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: MIRROR AT IMPORT, NOT WHEN THE LINK BREAKS.
-- Every one of these was fine until it wasn't, and the three that did break (CC_0260) gave no
-- warning at all -- the first symptom would have been a reader seeing a broken image. The
-- capability to mirror a politician-less candidate row existed in a Utah-shaped script for
-- months; what was missing was anything that MADE a new import use it.
-- 🟢 So the durable half of this change is not the six rows, it is the two things beside them:
--   scripts/mirror-candidate-photos.py   - state-agnostic, face-gated, byte-verified
--   the nightly CI sweep (--external-only) - which is now the thing that notices, instead of
--                                            a reader. With these six mirrored it has nothing
--                                            left to watch, and THAT is the goal state, not an
--                                            idle job.
-- ⚠ Do not read "0 off-site" as permanent. The next importer that writes a scraped URL into
-- race_candidates.photo_url puts it straight back, and the nightly only tells you AFTER it is
-- published. Mirror in the importer.
-- ───────────────────────────────────────────────────────────────────────────────────────────
