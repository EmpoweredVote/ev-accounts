-- CC_0443 — 3 headshots for 2026-11-03 winners in Colorado and Texas. Batch 7, after CC_0442.
--
-- WHO. Colorado had 2 faceless legislative winners and Texas 1; all three are imported here, at
-- 600x750 with NO UPSCALING. Utah's two stay open, with the reason recorded in
-- data/transition-headshots-2026/NOTES.md.
--
-- 🔴🔴 TREVER NEHLS IS THE IDENTICAL TWIN OF THE SITTING MEMBER TROY NEHLS, AND THIS IS THE MOST
-- DANGEROUS IDENTITY CASE IN THE WHOLE TRANSITION QUEUE.
--   * Both are Nehls. Both served as US Army officers. Both have en.wikipedia articles WITH
--     PHOTOGRAPHS. Troy held TX-22 before him, so the two men are attached to the SAME SEAT.
--   * Looking at the picture does not settle it, and NEITHER DOES THE UNIFORM: the name tape in
--     the photograph reads NEHLS, which is true of both brothers.
--   * 🟢 IT WAS SETTLED AT THE SOURCE. The Department of Defense caption for the original DVIDS
--     image (dvidshub.net/image/6139335) reads "Brig. Gen. Howard Geck ... hands COL. TREVER
--     NEHLS, civil affairs officer in charge, the 'Distinguished Member' plaque". The page names
--     Trever and NEVER MENTIONS TROY. Both brothers' Commons files were fetched deliberately and
--     compared rather than one being taken on trust.
--   ⚠ Troy's congressional portrait IS legitimately public domain and is a clean 1536x1920 — in
--     other words, exactly the high-quality, correctly-licensed file that would have been most
--     tempting to take. A good licence is not evidence of the right person.
--
-- 🟢 THE FIRST GENUINELY PUBLIC-DOMAIN PHOTOGRAPH IN THIS PROGRAMME, AND THE ONLY ROW SO FAR
-- THAT EARNS IT. Across CC_0383, CC_0438, CC_0439, CC_0440, CC_0441 and CC_0442 every single
-- licence came back `unknown`, and CC_0440/CC_0441 found Commons tags claiming "public domain"
-- for CITY work, which is wrong. Trever Nehls' portrait is different in kind: it was taken by
-- Spc. Dakota Vanidestine, a US ARMY photographer, and published through DVIDS. That is FEDERAL
-- work, so 17 USC §105 genuinely applies. It is recorded as `public_domain` on the evidence,
-- not on a Commons tag.
-- ▶ The licence split in this file is therefore 2 `unknown` + 1 `public_domain`, and gate 7
--   below asserts exactly that, so a future edit cannot quietly spread the public-domain claim
--   to the other two.
--
-- THE OTHER TWO, both Colorado and both re-sourced at native size:
--   Terri Carver   leg.colorado.gov member page, which NAMES HER IN ITS TEXT. 2215x3322. She
--                  served Colorado House District 20 (Colorado Springs) and has won Senate 9,
--                  also Colorado Springs. ⚠ Colorado serves Rails active_storage ORIGINALS, so
--                  what a member supplied is what you get: Carver is 2215x3322 and Vigil is
--                  314x432 on the same site.
--   Steph Vigil    campaign studio portrait, 3628x3628, IDENTITY CONFIRMED against her own
--                  official leg.colorado.gov portrait — 314x432, too small to publish and
--                  authoritative about who she is. That is the identity-reference pattern from
--                  CC_0440 used again.
--
-- SOURCE AND LICENCE, read per site and never inferred from the host.
--   Trever Nehls  public_domain  US Army / DVIDS — federal work, 17 USC §105
--   Terri Carver  unknown        leg.colorado.gov publishes no photo policy; COLORADO IS A
--                                STATE, and only federal work is public domain
--   Steph Vigil   unknown        stephanievigil.com carries only a "Paid for by the Committee…"
--                                campaign-finance disclaimer, which grants nothing
--
-- EVERY ROW WRITES BOTH SIDES. politicians.photo_custom_url is what the backend read paths
-- render; the politician_images row of type='default' is what the browse grid reads. Writing one
-- without the other renders on one surface and blanks on the other (CC_0195/CC_0196), and it is
-- how CC_0384 found Steve Hobbs showing a real portrait on the grid and the State Seal of
-- Washington everywhere else for three weeks.
--
-- NO ROW OVERWRITES ANYTHING. All 3 were measured faceless on all three surfaces before this
-- file was written, and all 3 storage objects were measured ABSENT before upload (positive
-- control: a known-good object answered 200 on the same sweep). All 3 were then verified
-- byte-identical against the PUBLIC CDN URL that goes into the database.
--
-- ROSTER (name, seat, native -> shipped, licence, source host):
--   Terri Carver   Colorado Senate 9     2215x3322 -> 600x750  unknown        leg.colorado.gov
--   Steph Vigil    Colorado House 16     3628x3628 -> 600x750  unknown        stephanievigil.com
--   Trever Nehls   Texas Congress. 22    1081x1442 -> 600x750  public_domain  www.dvidshub.net


BEGIN;

CREATE TEMP TABLE cc_0443_imported (politician_id uuid, name text, url text, origin text, photo_license text) ON COMMIT DROP;
INSERT INTO cc_0443_imported (politician_id, name, url, origin, photo_license) VALUES
  ('84dee0d9-6ca0-4af2-a4e0-a670b38c3f36'::uuid, 'Terri Carver',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/84dee0d9-6ca0-4af2-a4e0-a670b38c3f36-headshot.jpg',
   'https://leg.colorado.gov/legislators/terri-carver', 'unknown'),
  ('7a4a4418-f528-47d6-8714-b292d2d02496'::uuid, 'Steph Vigil',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7a4a4418-f528-47d6-8714-b292d2d02496-headshot.jpg',
   'https://stephanievigil.com/', 'unknown'),
  ('e1d222e5-559c-49d2-b7df-db7fbbf528c8'::uuid, 'Trever Nehls',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e1d222e5-559c-49d2-b7df-db7fbbf528c8-headshot.jpg',
   'https://www.dvidshub.net/image/6139335/blackjack-recognition-ceremony', 'public_domain');
-- The DELTA this file creates, captured in its OWN transaction. A total can be moved by
-- another session between the measurement and the write; a before/after pair inside one
-- transaction cannot be.
CREATE TEMP TABLE cc_0443_before ON COMMIT DROP AS
SELECT count(DISTINCT rc.politician_id) AS faceless
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = rc.politician_id
 WHERE e.election_date = DATE '2026-11-03' AND rc.result = 'won'
   AND d.district_type IN ('STATE_LOWER','STATE_UPPER','NATIONAL_LOWER','NATIONAL_UPPER')
   AND btrim(coalesce(p.photo_custom_url, '')) = ''
   AND btrim(coalesce(rc.photo_url, '')) = ''
   AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                    WHERE pi.politician_id = p.id AND pi.type = 'default');

-- Guarded, so a re-run is a no-op and the post-verify proves the END STATE, not row counts.
UPDATE essentials.politicians p
   SET photo_custom_url = i.url
  FROM cc_0443_imported i
 WHERE p.id = i.politician_id
   AND p.photo_custom_url IS DISTINCT FROM i.url;

UPDATE essentials.politicians p
   SET photo_origin_url = i.origin
  FROM cc_0443_imported i
 WHERE p.id = i.politician_id
   AND p.photo_origin_url IS DISTINCT FROM i.origin;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT i.politician_id, i.url, 'default', i.photo_license
  FROM cc_0443_imported i
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                    WHERE pi.politician_id = i.politician_id AND pi.type = 'default');

DO $$
DECLARE
  imported_n     int;
  missing_scalar int;
  missing_origin int;
  wrong_default  int;
  disagreeing    int;
  third_surface  int;
  before_n       int;
  wrong_licence  int;
  pd_n           int;
  after_n        int;
BEGIN
  -- 0. the import set is the size this file claims. A VALUES list that lost a row during
  --    editing would otherwise make every "% of 3" gate below count against the wrong total.
  SELECT count(*) INTO imported_n FROM cc_0443_imported;
  IF imported_n <> 3 THEN
    RAISE EXCEPTION 'CC_0443: the import set holds % rows, not the 3 this file documents', imported_n;
  END IF;

  -- 1. every one of the 3 renders from the scalar the backend read paths use
  SELECT count(*) INTO missing_scalar
    FROM cc_0443_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE btrim(coalesce(p.photo_custom_url, '')) = '';
  IF missing_scalar <> 0 THEN
    RAISE EXCEPTION 'CC_0443: % of 3 carry no photo_custom_url - they would render blank on address search', missing_scalar;
  END IF;

  -- 2. provenance is recorded. An `unknown` licence is only honest if the page it was read
  --    from is written down beside it.
  SELECT count(*) INTO missing_origin
    FROM cc_0443_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.photo_origin_url IS DISTINCT FROM i.origin;
  IF missing_origin <> 0 THEN
    RAISE EXCEPTION 'CC_0443: % of 3 do not carry the source page in photo_origin_url', missing_origin;
  END IF;

  -- 3. EXACTLY ONE default row each. Two make the grid's find() pick an arbitrary one.
  SELECT count(*) INTO wrong_default FROM (
    SELECT i.politician_id FROM cc_0443_imported i
      LEFT JOIN essentials.politician_images pi
        ON pi.politician_id = i.politician_id AND pi.type = 'default'
     GROUP BY i.politician_id HAVING count(pi.*) <> 1) x;
  IF wrong_default <> 0 THEN
    RAISE EXCEPTION 'CC_0443: % of 3 do not have exactly one type=default image row', wrong_default;
  END IF;

  -- 4. THE TWO SIDES AGREE (CC_0195/CC_0196).
  SELECT count(*) INTO disagreeing
    FROM cc_0443_imported i
    JOIN essentials.politicians p ON p.id = i.politician_id
    JOIN essentials.politician_images pi
      ON pi.politician_id = i.politician_id AND pi.type = 'default'
   WHERE pi.url IS DISTINCT FROM p.photo_custom_url;
  IF disagreeing <> 0 THEN
    RAISE EXCEPTION 'CC_0443: % of 3 have a default image row that disagrees with photo_custom_url', disagreeing;
  END IF;

  -- 5. THE THIRD SURFACE. race_candidates.photo_url is swept by nothing and BEATS the fixed
  --    image on ballot pages, so a stale value there outranks everything written above.
  --    CC_0384 had to name it explicitly for exactly this reason.
  SELECT count(*) INTO third_surface
    FROM cc_0443_imported i
    JOIN essentials.race_candidates rc ON rc.politician_id = i.politician_id
   WHERE btrim(coalesce(rc.photo_url, '')) <> ''
     AND rc.photo_url IS DISTINCT FROM i.url;
  IF third_surface <> 0 THEN
    RAISE EXCEPTION 'CC_0443: % race_candidates rows carry a DIFFERENT photo_url and would outrank the import on ballot pages', third_surface;
  END IF;

  -- 6. THE DELTA. Exactly 3 legislative winners must leave the faceless set, measured inside
  --    this transaction against the snapshot taken before the writes.
  SELECT faceless INTO before_n FROM cc_0443_before;
  SELECT count(DISTINCT rc.politician_id) INTO after_n
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.politicians p ON p.id = rc.politician_id
   WHERE e.election_date = DATE '2026-11-03' AND rc.result = 'won'
     AND d.district_type IN ('STATE_LOWER','STATE_UPPER','NATIONAL_LOWER','NATIONAL_UPPER')
     AND btrim(coalesce(p.photo_custom_url, '')) = ''
     AND btrim(coalesce(rc.photo_url, '')) = ''
     AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                      WHERE pi.politician_id = p.id AND pi.type = 'default');
  IF before_n - after_n <> 3 THEN
    RAISE EXCEPTION 'CC_0443: the faceless legislative count moved by % (% -> %), not the 3 this file imports', before_n - after_n, before_n, after_n;
  END IF;


  -- 7. THE LICENCE SPLIT. This file makes the programme's FIRST public_domain claim, on the one
  --    row where a US Army photographer makes it true. Assert the split exactly, so a later edit
  --    cannot spread that claim to the two state/campaign rows, which are .
  SELECT count(*) INTO wrong_licence
    FROM cc_0443_imported i
    JOIN essentials.politician_images pi
      ON pi.politician_id = i.politician_id AND pi.type = 'default'
   WHERE pi.photo_license IS DISTINCT FROM i.photo_license;
  IF wrong_licence <> 0 THEN
    RAISE EXCEPTION 'CC_0443: % image rows carry a licence other than the one this file documents', wrong_licence;
  END IF;

  SELECT count(*) INTO pd_n FROM cc_0443_imported WHERE photo_license = 'public_domain';
  IF pd_n <> 1 THEN
    RAISE EXCEPTION 'CC_0443: % rows claim public_domain, not the 1 this file justifies (US Army / DVIDS)', pd_n;
  END IF;

  RAISE NOTICE 'CC_0443 ok: 3 headshots, scalar + origin set, exactly one default row each, both sides agree, third surface clear, faceless legislative winners % -> %', before_n, after_n;
END
$$;

COMMIT;
