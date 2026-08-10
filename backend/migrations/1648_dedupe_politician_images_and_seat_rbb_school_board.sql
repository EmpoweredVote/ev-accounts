-- 1648_dedupe_politician_images_and_seat_rbb_school_board.sql
--
-- Follows 1647. Two cleanups from the same 2026-08-09 session:
--   (A) remove genuinely redundant politician_images rows, and
--   (B) finish the Richland-Bean Blossom (Edgewood Schools, IN) board, which had a nameless record
--       holding two different people's photos.
-- Already applied to production by direct MCP execution as `postgres`; guarded on END STATE.
--
-- ── 🔴 A COUNTING TRAP, RECORDED SO IT IS NOT REPEATED ──────────────────────────────────────────
-- Counting image rows while JOINed to race_candidates MULTIPLIES rows for any candidate appearing
-- in both a primary and a general. That produced a false "55 people with duplicate images, 20 with
-- conflicting photos". Counting essentials.politician_images ALONE gives the truth:
--   5,635 politicians with images; 200 with >1 row; 191 of those are a LEGITIMATE
--   type='default' + type='thumb' PAIR -- the same photo at two sizes (e.g. 450x450 + 200x200)
--   in the same <uuid>/ folder. That pairing is BY DESIGN. Do not "dedupe" it.
-- Only 9 were real, and only those are touched here.
--
-- ── (A) THE 9 REAL ONES ────────────────────────────────────────────────────────────────────────
-- Exact duplicate rows (identical url twice): Ali Taj, Lana Negrete, Rita Soto.
-- Traci Park: same url stored twice under two different licences. The Commons file
--   "File:Traci Park, 2024 (cropped).jpg" is Public domain, so the cc_by_sa_4.0 row is the wrong
--   one -- checked against the Commons API, not inferred.
-- Same photograph kept twice, once as a city-scrape copy: Arturo Flores, Patricia Cortez,
--   Scarlet Peralta. The canonical <uuid>/ or -headshot.jpg copy is kept.
-- (The two Alex Padilla wrong-person rows were handled in 1647.)
--
-- ── (B) RICHLAND-BEAN BLOSSOM CSC / EDGEWOOD SCHOOLS ───────────────────────────────────────────
-- politician 55dc950c had full_name NULL and carried BOTH angie-jacobs.jpg and dana-kerr.jpg.
-- 🔑 It was not actually unidentified: first_name/last_name already said "Dana Kerr". A NULL
-- full_name does NOT mean an unknown record -- check first_name/last_name first.
-- Board (https://www.rbbschools.net/school-board): Kerr President, Durnil Vice President, DeMoss,
-- Jacobs, Tucker. Seats are 2 Richland Township + 2 Bean Blossom Township + 1 At-Large.
-- Angie Jacobs had NO politician record and NO seat; hers is Bean Blossom Township, per
-- Ballotpedia's canonical page name for her 2022 run
-- (Angela_A._Jacobs_(..._District_Bean_Blossom,_Indiana,_candidate_2022)). Her legal name is
-- Angela A. Jacobs; stored as "Angie Jacobs" to match the district's own roster.
--
-- 🔑 essentials.office_current_holder is a VIEW (offices LEFT JOIN current_office_holders, itself a
-- view over essentials.office_terms filtered to term_start <= today AND term_end >= today, NULLs
-- passing). Occupancy is inserted into office_terms. A multi-seat office is modelled as ONE offices
-- ROW PER HOLDER -- Richland Township already had two identical rows -- so seating a new member
-- means cloning the office row first. UUIDs below are hard-coded to match production exactly.
--
-- All 5 members' photos were pixel-matched against the district page's own schoolboardheadshots-N
-- files before their photo_origin_url was set, including Tucker's and Durnil's, which reached us via
-- source='ballotready' but are the same district headshots.
-- ⚠ That page is finalsite JS-rendered (curl returns 0 images), its headshots have NO alt text, and
-- DOM order != text order -- mapping by position would have mislabelled 4 of the 5. Compare faces.

BEGIN;

-- ── A. redundant image rows ────────────────────────────────────────────────────────────────────
-- Keep the lowest id per (politician_id, url) where the exact same url is stored more than once.
DELETE FROM essentials.politician_images pi
 WHERE pi.politician_id IN (
         '2382e3c5-f6ff-4aeb-88c6-8538df3ea05d'::uuid,  -- Ali Taj
         '5604c5ae-d10d-4ca3-920d-dd3592278777'::uuid,  -- Lana Negrete
         '08bf0f81-2f3f-4fd1-98d1-d3c4ae77c5c7'::uuid,  -- Rita Soto
         'd0977350-df68-4cfe-822e-816ba13f9213'::uuid)  -- Traci Park
   AND pi.id <> (SELECT min(k.id) FROM essentials.politician_images k
                  WHERE k.politician_id = pi.politician_id AND k.url = pi.url);

-- Traci Park: of the two rows on the same url, keep public_domain (the Commons file really is PD).
DELETE FROM essentials.politician_images
 WHERE politician_id = 'd0977350-df68-4cfe-822e-816ba13f9213'::uuid
   AND photo_license = 'cc_by_sa_4.0';

-- Same photograph, redundant city-scrape copy.
DELETE FROM essentials.politician_images
 WHERE url IN (
   'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/cities/huntington_park/arturo-flores.png',
   'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/cities/covina/patricia-cortez.jpg',
   'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/cities/montebello/scarlet-peralta.png'
 );

-- ── B1. the nameless record was Dana Kerr all along ────────────────────────────────────────────
UPDATE essentials.politicians
   SET full_name = 'Dana Kerr'
 WHERE id = '55dc950c-cd52-4460-ae3f-630c1c4f771a'::uuid
   AND full_name IS NULL AND first_name = 'Dana' AND last_name = 'Kerr';

-- Angie Jacobs' photo was hanging off Kerr's record.
DELETE FROM essentials.politician_images
 WHERE politician_id = '55dc950c-cd52-4460-ae3f-630c1c4f771a'::uuid
   AND url ILIKE '%rbb_school_board/angie-jacobs.jpg';

-- ── B2. create Angie Jacobs and seat her ───────────────────────────────────────────────────────
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, is_active, is_incumbent,
                                    source, photo_origin_url)
SELECT '234cb50f-b0fb-4902-b807-da06ac2faddf'::uuid, 'Angie Jacobs', 'Angie', 'Jacobs', true, true,
       'rbbschools.net', 'https://www.rbbschools.net/school-board'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians
                    WHERE id = '234cb50f-b0fb-4902-b807-da06ac2faddf'::uuid
                       OR (first_name ILIKE 'Angie' AND last_name ILIKE 'Jacobs'));

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '234cb50f-b0fb-4902-b807-da06ac2faddf'::uuid,
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/rbb_school_board/angie-jacobs.jpg',
       'default', 'press_use'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                    WHERE politician_id = '234cb50f-b0fb-4902-b807-da06ac2faddf'::uuid);

-- second Bean Blossom Township seat (the office row is per-holder; seats was already 2)
INSERT INTO essentials.offices (id, chamber_id, district_id, title, representing_state,
                                representing_city, description, seats, normalized_position_name,
                                partisan_type, is_appointed_position, is_vacant, faces_retention_vote)
SELECT 'c8bca79d-4319-49a4-925a-7580c74d3800'::uuid, o.chamber_id, o.district_id, o.title,
       o.representing_state, o.representing_city, o.description, o.seats,
       o.normalized_position_name, o.partisan_type, o.is_appointed_position, false,
       o.faces_retention_vote
  FROM essentials.offices o
 WHERE o.id = '64065558-9cc0-4b09-b9d0-79f1770976e8'::uuid
   AND NOT EXISTS (SELECT 1 FROM essentials.offices
                    WHERE id = 'c8bca79d-4319-49a4-925a-7580c74d3800'::uuid);

INSERT INTO essentials.office_terms (id, office_id, politician_id, term_start, term_end,
                                     start_precision, source)
SELECT 'f6e0b27e-a747-4a55-abb2-159528c029f1'::uuid,
       'c8bca79d-4319-49a4-925a-7580c74d3800'::uuid,
       '234cb50f-b0fb-4902-b807-da06ac2faddf'::uuid,
       NULL, NULL, 'unknown',
       'rbbschools.net school-board roster + ballotpedia Bean Blossom district page (2026-08-09)'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms
                    WHERE politician_id = '234cb50f-b0fb-4902-b807-da06ac2faddf'::uuid);

-- ── B3. provenance + licence for the whole board ───────────────────────────────────────────────
UPDATE essentials.politicians p
   SET photo_origin_url = 'https://www.rbbschools.net/school-board'
 WHERE p.id IN (SELECT och.politician_id
                  FROM essentials.office_current_holder och
                  JOIN essentials.offices o ON o.id = och.office_id
                 WHERE o.title ILIKE '%Richland%Bean%Blossom%')
   AND (p.photo_origin_url IS NULL OR p.photo_origin_url = '');

UPDATE essentials.politician_images pi
   SET photo_license = 'press_use'
 WHERE pi.politician_id IN (SELECT och.politician_id
                              FROM essentials.office_current_holder och
                              JOIN essentials.offices o ON o.id = och.office_id
                             WHERE o.title ILIKE '%Richland%Bean%Blossom%')
   AND pi.photo_license IS NULL;

-- Inglewood Alex Padilla already had his own record; point provenance at the directory PAGE rather
-- than a raw ImageRepository document link (which is an image, not a page).
UPDATE essentials.politicians
   SET photo_origin_url = 'https://www.cityofinglewood.org/m/directory/employee?eid=103'
 WHERE id = '123c9a42-5715-4ab2-a8bd-76e7adbca27b'::uuid
   AND photo_origin_url IS DISTINCT FROM 'https://www.cityofinglewood.org/m/directory/employee?eid=103';

-- ── VERIFY ─────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_dupe integer; v_board integer; v_nolic integer; v_pairs integer;
BEGIN
  -- no politician stores the same url twice anywhere in the corpus
  SELECT count(*) INTO v_dupe FROM (
    SELECT politician_id, url FROM essentials.politician_images
     GROUP BY politician_id, url HAVING count(*) > 1) d;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'Still % (politician_id, url) pairs stored more than once', v_dupe;
  END IF;

  -- the legitimate default+thumb pairs must SURVIVE -- this migration must not eat them
  SELECT count(*) INTO v_pairs FROM (
    SELECT politician_id FROM essentials.politician_images
     GROUP BY politician_id
    HAVING count(*) = 2
       AND count(*) FILTER (WHERE type = 'default') = 1
       AND count(*) FILTER (WHERE type = 'thumb') = 1
       AND count(DISTINCT regexp_replace(url, '/(default|thumb)\.jpg$', '')) = 1) p;
  IF v_pairs < 150 THEN
    RAISE EXCEPTION 'Only % default+thumb pairs remain; expected ~191 -- legitimate pairs were deleted', v_pairs;
  END IF;

  -- all five RBB board seats filled, each with a named holder and an origin
  SELECT count(*) INTO v_board
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.title ILIKE '%Richland%Bean%Blossom%'
     AND p.full_name IS NOT NULL
     AND p.photo_origin_url = 'https://www.rbbschools.net/school-board';
  IF v_board <> 5 THEN
    RAISE EXCEPTION 'Expected 5 named RBB board holders with district provenance, found %', v_board;
  END IF;

  SELECT count(*) INTO v_nolic FROM essentials.politician_images pi
   WHERE pi.politician_id IN (SELECT och.politician_id
                                FROM essentials.office_current_holder och
                                JOIN essentials.offices o ON o.id = och.office_id
                               WHERE o.title ILIKE '%Richland%Bean%Blossom%')
     AND pi.photo_license IS NULL;
  IF v_nolic <> 0 THEN
    RAISE EXCEPTION '% RBB image rows still have a NULL photo_license', v_nolic;
  END IF;
END $$;

COMMIT;
