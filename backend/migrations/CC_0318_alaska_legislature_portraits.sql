-- CC_0318_alaska_legislature_portraits.sql
-- Portraits for all 60 Alaska legislators seated by CC_0317.
--
-- The VALUES block is generated, not hand-typed:
--   node data/seed-ak-legislature-2026/gen-migration-values.mjs
-- Sources, inspection notes and the two odd sizes: data/seed-ak-legislature-2026/ROSTERS.md
--
-- ═══ ALL THREE FIELDS, AND WHY ═══
--
--   politicians.photo_custom_url   THE FIELD THAT RENDERS. The address-search read path builds
--                                  its photo from COALESCE(photo_custom_url, photo_origin_url)
--                                  and never reads politician_images.
--   essentials.politician_images   carries photo_license, which the API returns to the frontend,
--                                  and the grid reads images[] FIRST.
--   politicians.photo_origin_url   provenance: the akleg.gov file the photograph came from.
--
-- ═══ 🔴 BOUND BY SEAT, AND THE RESOLVED NAME IS ASSERTED ═══
--
-- Every row resolves (chamber, district geo_id + mtfcc, office title) -> office ->
-- office_current_holder, never by name. The gate then asserts that the person it resolved to is
-- the person the file was generated against. That second half is the one that matters: binding by
-- seat stops a namesake collision, and asserting the name stops a silently re-seated office from
-- getting the previous holder's face.
-- ⚠ G5220 shares a geo_id with G4020 in Alaska (House 13/16/20 are 02013/02016/02020, and so are
--   three boroughs), so every join pairs geo_id with mtfcc.
--
-- ═══ 🔴 ALL 60 WERE LOOKED AT ═══
--
-- Rendered to two contact sheets (data/seed-ak-legislature-2026/contact-sheet.mjs) and inspected
-- before this file was written. Nothing in this repo asks whether a headshot contains a FACE — a
-- seal, a logo, a map, a banner or a blank passes every automated check — so the sheet is the
-- check. All 60 are genuine, distinct, individual headshots of a person.
--   * All 60 files are distinct by MD5. No placeholder is repeated across seats.
--   * Several are candid or outdoor rather than the studio set — Carolyn Hall (House 16) in a
--     knitted hat, Ted Eischeid (House 22) in a cap, Garret Nelson (House 29) outdoors, Robyn
--     Niayuq Frier (House 40) in a fur-ruffed parka. All are real portraits of the right person.
--   * Measured, not eyeballed: 58 of 60 are exactly 450x600.
--
-- ═══ ⚠ TWO SIZES ARE NOT 450x600, AND BOTH ARE DELIBERATE ═══
--
--   George Rauscher (Senate O)   400x600 — narrower, full detail, nothing to do.
--   Bryce Edgmon (House 37)      150x200 — a NINTH of the area of every other portrait, and he
--                                is the Speaker of the House.
-- 🔴 150x200 IS ALL ALASKA PUBLISHES FOR HIM, and that was tested rather than assumed: the
--    /450x600/ path, the bare path and the /rounded/ path all serve the SAME 150x200 image (the
--    server does not resize — the directory name is a label, not a transform), and the only other
--    picture of him on the site is a 222x159 LANDSCAPE leadership banner, which is not a headshot
--    shape. Mirrored at native size. NOT upscaled — upscaling invents detail. Don't re-hunt it.
--
-- ═══ MIRRORED, NOT HOTLINKED ═══
--
-- All 60 are in Supabase storage under politician_photos/ak-legislature-2026/, uploaded by
-- data/seed-ak-legislature-2026/mirror-portraits.mjs as the exact bytes akleg.gov served —
-- nothing resized or re-encoded. Four were fetched back from the public CDN and compared: MD5
-- identical to source in every case.
--
-- ═══ LICENCE ═══
--
-- press_use. These are the Alaska Legislature's own official photographs of its own members,
-- published on its own member pages. Not federal works, no free licence.

BEGIN;

CREATE TEMP TABLE ak_photos (
  chamber       text,
  geo_id        text,
  mtfcc         text,
  title         text,
  expected_name text,
  file          text,
  origin        text,
  politician_id uuid,
  resolved_name text
) ON COMMIT DROP;

INSERT INTO ak_photos (chamber, geo_id, mtfcc, title, expected_name, file, origin) VALUES
-- @generated-by data/seed-ak-legislature-2026/gen-migration-values.mjs from roster-final.json
    ('Alaska House of Representatives', '02010', 'G5220', 'Representative', 'Chuck Kopp', 'ak-legislature-2026/hse-10.jpg', 'https://akleg.gov/images/legislators/450x600/KOP.jpg'),
    ('Alaska House of Representatives', '02037', 'G5220', 'Representative', 'Bryce Edgmon', 'ak-legislature-2026/hse-37.jpg', 'https://akleg.gov/images/legislators/450x600/EDG.jpg'),
    ('Alaska House of Representatives', '02025', 'G5220', 'Representative', 'DeLena Johnson', 'ak-legislature-2026/hse-25.jpg', 'https://akleg.gov/images/legislators/450x600/JHS.jpg'),
    ('Alaska House of Representatives', '02023', 'G5220', 'Representative', 'Jamie Allard', 'ak-legislature-2026/hse-23.jpg', 'https://akleg.gov/images/legislators/450x600/ALR.jpg'),
    ('Alaska House of Representatives', '02001', 'G5220', 'Representative', 'Jeremy Bynum', 'ak-legislature-2026/hse-01.jpg', 'https://akleg.gov/images/legislators/450x600/BYN.jpg'),
    ('Alaska House of Representatives', '02035', 'G5220', 'Representative', 'Ashley Carrick', 'ak-legislature-2026/hse-35.jpg', 'https://akleg.gov/images/legislators/450x600/CAI.jpg'),
    ('Alaska House of Representatives', '02015', 'G5220', 'Representative', 'Mia Costello', 'ak-legislature-2026/hse-15.jpg', 'https://akleg.gov/images/legislators/450x600/COS.jpg'),
    ('Alaska House of Representatives', '02011', 'G5220', 'Representative', 'Julie Coulombe', 'ak-legislature-2026/hse-11.jpg', 'https://akleg.gov/images/legislators/450x600/COU.jpg'),
    ('Alaska House of Representatives', '02031', 'G5220', 'Representative', 'Maxine Dibert', 'ak-legislature-2026/hse-31.jpg', 'https://akleg.gov/images/legislators/450x600/DIB.jpg'),
    ('Alaska House of Representatives', '02022', 'G5220', 'Representative', 'Ted Eischeid', 'ak-legislature-2026/hse-22.jpg', 'https://akleg.gov/images/legislators/450x600/EIS.jpg'),
    ('Alaska House of Representatives', '02008', 'G5220', 'Representative', 'Bill Elam', 'ak-legislature-2026/hse-08.jpg', 'https://akleg.gov/images/legislators/450x600/ELA.jpg'),
    ('Alaska House of Representatives', '02017', 'G5220', 'Representative', 'Zack Fields', 'ak-legislature-2026/hse-17.jpg', 'https://akleg.gov/images/legislators/450x600/FIE.jpg'),
    ('Alaska House of Representatives', '02039', 'G5220', 'Representative', 'Neal Foster', 'ak-legislature-2026/hse-39.jpg', 'https://akleg.gov/images/legislators/450x600/FON.jpg'),
    ('Alaska House of Representatives', '02040', 'G5220', 'Representative', 'Robyn Niayuq Frier', 'ak-legislature-2026/hse-40.jpg', 'https://akleg.gov/images/legislators/450x600/FRB.jpg'),
    ('Alaska House of Representatives', '02014', 'G5220', 'Representative', 'Alyse Galvin', 'ak-legislature-2026/hse-14.jpg', 'https://akleg.gov/images/legislators/450x600/GAL.jpg'),
    ('Alaska House of Representatives', '02020', 'G5220', 'Representative', 'Andrew Gray', 'ak-legislature-2026/hse-20.jpg', 'https://akleg.gov/images/legislators/450x600/GRY.jpg'),
    ('Alaska House of Representatives', '02016', 'G5220', 'Representative', 'Carolyn Hall', 'ak-legislature-2026/hse-16.jpg', 'https://akleg.gov/images/legislators/450x600/HLL.jpg'),
    ('Alaska House of Representatives', '02004', 'G5220', 'Representative', 'Sara Hannan', 'ak-legislature-2026/hse-04.jpg', 'https://akleg.gov/images/legislators/450x600/HNN.jpg'),
    ('Alaska House of Representatives', '02002', 'G5220', 'Representative', 'Rebecca Himschoot', 'ak-legislature-2026/hse-02.jpg', 'https://akleg.gov/images/legislators/450x600/HMS.jpg'),
    ('Alaska House of Representatives', '02009', 'G5220', 'Representative', 'Ky Holland', 'ak-legislature-2026/hse-09.jpg', 'https://akleg.gov/images/legislators/450x600/HLA.jpg'),
    ('Alaska House of Representatives', '02038', 'G5220', 'Representative', 'Nellie Unangiq Jimmie', 'ak-legislature-2026/hse-38.jpg', 'https://akleg.gov/images/legislators/450x600/JIM.jpg'),
    ('Alaska House of Representatives', '02013', 'G5220', 'Representative', 'Andy Josephson', 'ak-legislature-2026/hse-13.jpg', 'https://akleg.gov/images/legislators/450x600/JOS.jpg'),
    ('Alaska House of Representatives', '02030', 'G5220', 'Representative', 'Kevin McCabe', 'ak-legislature-2026/hse-30.jpg', 'https://akleg.gov/images/legislators/450x600/MCA.jpg'),
    ('Alaska House of Representatives', '02021', 'G5220', 'Representative', 'Donna Mears', 'ak-legislature-2026/hse-21.jpg', 'https://akleg.gov/images/legislators/450x600/MEA.jpg'),
    ('Alaska House of Representatives', '02019', 'G5220', 'Representative', 'Genevieve Mina', 'ak-legislature-2026/hse-19.jpg', 'https://akleg.gov/images/legislators/450x600/MNA.jpg'),
    ('Alaska House of Representatives', '02028', 'G5220', 'Representative', 'Elexie Moore', 'ak-legislature-2026/hse-28.jpg', 'https://akleg.gov/images/legislators/450x600/MOO.jpg'),
    ('Alaska House of Representatives', '02018', 'G5220', 'Representative', 'David Nelson', 'ak-legislature-2026/hse-18.jpg', 'https://akleg.gov/images/legislators/450x600/NED.jpg'),
    ('Alaska House of Representatives', '02029', 'G5220', 'Representative', 'Garret Nelson', 'ak-legislature-2026/hse-29.jpg', 'https://akleg.gov/images/legislators/450x600/NEG.jpg'),
    ('Alaska House of Representatives', '02033', 'G5220', 'Representative', 'Mike Prax', 'ak-legislature-2026/hse-33.jpg', 'https://akleg.gov/images/legislators/450x600/PRA.jpg'),
    ('Alaska House of Representatives', '02007', 'G5220', 'Representative', 'Justin Ruffridge', 'ak-legislature-2026/hse-07.jpg', 'https://akleg.gov/images/legislators/450x600/RUF.jpg'),
    ('Alaska House of Representatives', '02024', 'G5220', 'Representative', 'Dan Saddler', 'ak-legislature-2026/hse-24.jpg', 'https://akleg.gov/images/legislators/450x600/SAD.jpg'),
    ('Alaska House of Representatives', '02012', 'G5220', 'Representative', 'Calvin Schrage', 'ak-legislature-2026/hse-12.jpg', 'https://akleg.gov/images/legislators/450x600/SCG.jpg'),
    ('Alaska House of Representatives', '02036', 'G5220', 'Representative', 'Rebecca Schwanke', 'ak-legislature-2026/hse-36.jpg', 'https://akleg.gov/images/legislators/450x600/SCW.jpg'),
    ('Alaska House of Representatives', '02026', 'G5220', 'Representative', 'Steve St. Clair', 'ak-legislature-2026/hse-26.jpg', 'https://akleg.gov/images/legislators/450x600/STC.jpg'),
    ('Alaska House of Representatives', '02032', 'G5220', 'Representative', 'Will Stapp', 'ak-legislature-2026/hse-32.jpg', 'https://akleg.gov/images/legislators/450x600/SPP.jpg'),
    ('Alaska House of Representatives', '02003', 'G5220', 'Representative', 'Andi Story', 'ak-legislature-2026/hse-03.jpg', 'https://akleg.gov/images/legislators/450x600/STO.jpg'),
    ('Alaska House of Representatives', '02005', 'G5220', 'Representative', 'Louise Stutes', 'ak-legislature-2026/hse-05.jpg', 'https://akleg.gov/images/legislators/450x600/STS.jpg'),
    ('Alaska House of Representatives', '02034', 'G5220', 'Representative', 'Frank Tomaszewski', 'ak-legislature-2026/hse-34.jpg', 'https://akleg.gov/images/legislators/450x600/TMZ.jpg'),
    ('Alaska House of Representatives', '02027', 'G5220', 'Representative', 'Jubilee Underwood', 'ak-legislature-2026/hse-27.jpg', 'https://akleg.gov/images/legislators/450x600/UND.jpg'),
    ('Alaska House of Representatives', '02006', 'G5220', 'Representative', 'Sarah Vance', 'ak-legislature-2026/hse-06.jpg', 'https://akleg.gov/images/legislators/450x600/VAN.jpg'),
    ('Alaska Senate', '0200E', 'G5210', 'Senator', 'Cathy Giessel', 'ak-legislature-2026/sen-e.jpg', 'https://akleg.gov/images/legislators/450x600/GIE.jpg'),
    ('Alaska Senate', '0200C', 'G5210', 'Senator', 'Gary Stevens', 'ak-legislature-2026/sen-c.jpg', 'https://akleg.gov/images/legislators/450x600/STG.jpg'),
    ('Alaska Senate', '0200R', 'G5210', 'Senator', 'Mike Cronk', 'ak-legislature-2026/sen-r.jpg', 'https://akleg.gov/images/legislators/450x600/CRN.jpg'),
    ('Alaska Senate', '0200D', 'G5210', 'Senator', 'Jesse Bjorkman', 'ak-legislature-2026/sen-d.jpg', 'https://akleg.gov/images/legislators/450x600/BJK.jpg'),
    ('Alaska Senate', '0200H', 'G5210', 'Senator', 'Matt Claman', 'ak-legislature-2026/sen-h.jpg', 'https://akleg.gov/images/legislators/450x600/CLA.jpg'),
    ('Alaska Senate', '0200J', 'G5210', 'Senator', 'Forrest Dunbar', 'ak-legislature-2026/sen-j.jpg', 'https://akleg.gov/images/legislators/450x600/DNB.jpg'),
    ('Alaska Senate', '0200G', 'G5210', 'Senator', 'Elvi Gray-Jackson', 'ak-legislature-2026/sen-g.jpg', 'https://akleg.gov/images/legislators/450x600/GRA.jpg'),
    ('Alaska Senate', '0200S', 'G5210', 'Senator', 'Lyman Hoffman', 'ak-legislature-2026/sen-s.jpg', 'https://akleg.gov/images/legislators/450x600/HOF.jpg'),
    ('Alaska Senate', '0200F', 'G5210', 'Senator', 'James Kaufman', 'ak-legislature-2026/sen-f.jpg', 'https://akleg.gov/images/legislators/450x600/KAU.jpg'),
    ('Alaska Senate', '0200P', 'G5210', 'Senator', 'Scott Kawasaki', 'ak-legislature-2026/sen-p.jpg', 'https://akleg.gov/images/legislators/450x600/KAW.jpg'),
    ('Alaska Senate', '0200B', 'G5210', 'Senator', 'Jesse Kiehl', 'ak-legislature-2026/sen-b.jpg', 'https://akleg.gov/images/legislators/450x600/KIE.jpg'),
    ('Alaska Senate', '0200L', 'G5210', 'Senator', 'Kelly Merrick', 'ak-legislature-2026/sen-l.jpg', 'https://akleg.gov/images/legislators/450x600/MRR.jpg'),
    ('Alaska Senate', '0200Q', 'G5210', 'Senator', 'Robert Myers', 'ak-legislature-2026/sen-q.jpg', 'https://akleg.gov/images/legislators/450x600/MYE.jpg'),
    ('Alaska Senate', '0200T', 'G5210', 'Senator', 'Donny Olson', 'ak-legislature-2026/sen-t.jpg', 'https://akleg.gov/images/legislators/450x600/OLS.jpg'),
    ('Alaska Senate', '0200O', 'G5210', 'Senator', 'George Rauscher', 'ak-legislature-2026/sen-o.jpg', 'https://akleg.gov/images/legislators/450x600/RAC.jpg'),
    ('Alaska Senate', '0200A', 'G5210', 'Senator', 'Bert Stedman', 'ak-legislature-2026/sen-a.jpg', 'https://akleg.gov/images/legislators/450x600/SMN.jpg'),
    ('Alaska Senate', '0200M', 'G5210', 'Senator', 'Cathy Tilton', 'ak-legislature-2026/sen-m.jpg', 'https://akleg.gov/images/legislators/450x600/TTN.jpg'),
    ('Alaska Senate', '0200I', 'G5210', 'Senator', 'Loki Tobin', 'ak-legislature-2026/sen-i.jpg', 'https://akleg.gov/images/legislators/450x600/TOB.jpg'),
    ('Alaska Senate', '0200K', 'G5210', 'Senator', 'Bill Wielechowski', 'ak-legislature-2026/sen-k.jpg', 'https://akleg.gov/images/legislators/450x600/WIE.jpg'),
    ('Alaska Senate', '0200N', 'G5210', 'Senator', 'Robert Yundt', 'ak-legislature-2026/sen-n.jpg', 'https://akleg.gov/images/legislators/450x600/YUN.jpg')
;

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_rows int; v_seated int; v_already int;
BEGIN
  SELECT count(*) INTO v_rows FROM ak_photos;
  IF v_rows <> 60 THEN
    RAISE EXCEPTION 'CC_0318 pre-flight: expected 60 portrait rows, found %', v_rows;
  END IF;

  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER');
  IF v_seated <> 60 THEN
    RAISE EXCEPTION 'CC_0318 pre-flight: expected 60 seated Alaska legislative seats from CC_0317, '
                    'found % — run CC_0316 and CC_0317 first', v_seated;
  END IF;

  SELECT count(*) INTO v_already
    FROM essentials.politicians p
   WHERE p.source LIKE '%CC_0317%' AND p.photo_custom_url IS NOT NULL;
  IF v_already <> 0 THEN
    RAISE EXCEPTION 'CC_0318 pre-flight: % Alaska legislator(s) already carry a photo_custom_url. '
                    'This migration does not overwrite an existing portrait — a migration that '
                    'overwrites a value must record the value it overwrote.', v_already;
  END IF;
END $$;

-- ── Resolve each row to its seat's CURRENT holder ─────────────────────────────
UPDATE ak_photos h
   SET politician_id = och.politician_id,
       resolved_name = p.full_name
  FROM essentials.offices o
  JOIN essentials.chambers c   ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.districts d  ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE g.geo_id = '02' AND g.mtfcc = 'G4000'
   AND c.name = h.chamber
   AND o.title = h.title
   AND d.geo_id = h.geo_id
   AND d.mtfcc = h.mtfcc
   AND lower(d.state) = 'ak';

-- 🔴 The identity gate, BEFORE anything is written to a person.
DO $$
DECLARE v_unresolved int; v_wrong int; v_list text;
BEGIN
  SELECT count(*) INTO v_unresolved FROM ak_photos WHERE politician_id IS NULL;
  IF v_unresolved <> 0 THEN
    RAISE EXCEPTION 'CC_0318: % portrait row(s) did not resolve to a seated officeholder', v_unresolved;
  END IF;

  SELECT count(*), string_agg(expected_name || ' -> ' || resolved_name, '; ')
    INTO v_wrong, v_list
    FROM ak_photos WHERE resolved_name IS DISTINCT FROM expected_name;
  IF v_wrong <> 0 THEN
    RAISE EXCEPTION 'CC_0318: % seat(s) are held by someone other than the person this file was '
                    'generated against: %. The portrait would be painted onto the wrong face. '
                    'Re-read the roster before re-running.', v_wrong, v_list;
  END IF;

  IF (SELECT count(DISTINCT politician_id) FROM ak_photos) <> 60 THEN
    RAISE EXCEPTION 'CC_0318: 60 rows resolved to % distinct people — two seats share a holder',
                    (SELECT count(DISTINCT politician_id) FROM ak_photos);
  END IF;
  IF (SELECT count(DISTINCT file) FROM ak_photos) <> 60 THEN
    RAISE EXCEPTION 'CC_0318: 60 rows carry % distinct files — a portrait is reused across seats',
                    (SELECT count(DISTINCT file) FROM ak_photos);
  END IF;
END $$;

-- ── Write all three fields ────────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/' || h.file,
       photo_origin_url = h.origin
  FROM ak_photos h
 WHERE p.id = h.politician_id;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT h.politician_id,
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/' || h.file,
       'default', 'press_use'
  FROM ak_photos h
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politician_images pi
    WHERE pi.politician_id = h.politician_id AND pi.type = 'default'
 );

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE v_custom int; v_origin int; v_images int; v_lic int; v_badhost int; v_distinct int;
BEGIN
  SELECT count(*) INTO v_custom
    FROM essentials.politicians p
   WHERE p.source LIKE '%CC_0317%' AND p.photo_custom_url IS NOT NULL;
  IF v_custom <> 60 THEN
    RAISE EXCEPTION 'CC_0318 post-verify: % of 60 Alaska legislators carry photo_custom_url — that '
                    'is THE FIELD THAT RENDERS', v_custom;
  END IF;

  SELECT count(*) INTO v_origin
    FROM essentials.politicians p
   WHERE p.source LIKE '%CC_0317%' AND p.photo_origin_url IS NOT NULL;
  IF v_origin <> 60 THEN
    RAISE EXCEPTION 'CC_0318 post-verify: % of 60 carry photo_origin_url (provenance)', v_origin;
  END IF;

  SELECT count(*) INTO v_images
    FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE p.source LIKE '%CC_0317%' AND pi.type = 'default';
  IF v_images <> 60 THEN
    RAISE EXCEPTION 'CC_0318 post-verify: % of 60 carry a type=default politician_images row — the '
                    'grid reads images[] FIRST, so a missing row is a blank card even with '
                    'photo_custom_url set', v_images;
  END IF;

  SELECT count(*) INTO v_lic
    FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE p.source LIKE '%CC_0317%' AND pi.type = 'default' AND pi.photo_license IS DISTINCT FROM 'press_use';
  IF v_lic <> 0 THEN
    RAISE EXCEPTION 'CC_0318 post-verify: % Alaska portrait(s) do not carry photo_license press_use', v_lic;
  END IF;

  -- 🔴 MIRRORED, NOT HOTLINKED. Match the PATH, never the host — storage has two hostnames, and a
  -- host-based LIKE once called 1,279 of this repo's OWN headshots "hotlinked".
  SELECT count(*) INTO v_badhost
    FROM essentials.politicians p
   WHERE p.source LIKE '%CC_0317%'
     AND p.photo_custom_url NOT LIKE '%supabase.co/storage/v1/object/public/%';
  IF v_badhost <> 0 THEN
    RAISE EXCEPTION 'CC_0318 post-verify: % Alaska legislator(s) point photo_custom_url outside '
                    'Supabase storage — these must be mirrored, not hotlinked to akleg.gov', v_badhost;
  END IF;

  SELECT count(DISTINCT p.photo_custom_url) INTO v_distinct
    FROM essentials.politicians p WHERE p.source LIKE '%CC_0317%';
  IF v_distinct <> 60 THEN
    RAISE EXCEPTION 'CC_0318 post-verify: 60 legislators share only % distinct portraits', v_distinct;
  END IF;

  RAISE NOTICE 'CC_0318 OK: 60 of 60 Alaska legislators carry a mirrored portrait — '
               'photo_custom_url, photo_origin_url and a type=default politician_images row at '
               'press_use, all 60 distinct, every one bound by seat and name-checked.';
END $$;

COMMIT;
