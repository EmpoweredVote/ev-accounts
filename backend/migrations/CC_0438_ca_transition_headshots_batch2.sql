-- CC_0438 — 7 California legislative headshots for 2026-11-03 winners. Batch 2, after CC_0383.
--
-- WHO, AND WHY THESE 7. Of the 2026-11-03 winners, 73 in the four legislative tiers
-- (STATE_LOWER, STATE_UPPER, NATIONAL_LOWER, NATIONAL_UPPER) have no photograph in ANY of the
-- three places one can live. These are the first 7 of that 73 for whom a portrait published by
-- the body that employs them could be found and downloaded. The remaining 66 are still open;
-- data/transition-headshots-2026/NOTES.md carries the queue.
--
-- Measured against production before this file was written, with a positive control: 1,339
-- legislative winners DO read as having a photo, so the 73-strong missing list means something
-- rather than being a query that cannot see photos at all.
--
--   Brian Pacheco     CA Assembly 27  Fresno County Supervisor, District 1
--   Nathan Magsig     CA Senate 12    Fresno County Supervisor, District 5
--   Annalisa Perea    CA Assembly 31  Fresno City Council, District 1
--   Robert Garcia     CA Assembly 50  sitting Assemblymember, re-elected
--   Paul Seo          CA Assembly 66  Mayor, Rancho Palos Verdes
--   David Couch       CA Assembly 32  Kern County Supervisor, District 4
--   Jackie Elward     CA Assembly 12  Vice Mayor, Rohnert Park, District 4
--
-- EVERY ROW WRITES BOTH SIDES. politicians.photo_custom_url is what the backend read paths
-- render; the politician_images row of type='default' is what the browse grid reads. Writing
-- one without the other renders on one surface and blanks on the other (CC_0195/CC_0196), and
-- it is also how CC_0384 found Steve Hobbs showing a real portrait on the grid and the State
-- Seal of Washington everywhere else for three weeks.
--
-- SOURCE AND LICENCE, read per site and never inferred from the host. EVERY ONE IS `unknown`,
-- and that is a finding rather than an omission: not one of these publishers grants reuse.
-- fresno.gov and garcia.asmdc.org both assert a blanket copyright (© 2026 City of Fresno;
-- © 2026 California State Assembly Democratic Caucus); fresnocountyca.gov, rpvca.gov,
-- rpcity.ca.gov and kerncounty.com publish no photo policy at all on the pages that carry
-- these portraits. Only FEDERAL US government work is public domain under 17 USC §105 — a
-- city, county or state portrait is not — and SILENCE IS NOT A GRANT. `unknown` is findable
-- by the query that looks for missing provenance; a guessed `press_use` is not, and it would
-- tell the public they may reuse a photograph nobody cleared. This is the same disposition
-- CC_0383 gave the two cvwd.com rows.
--
--   Brian Pacheco   unknown  https://www.fresnocountyca.gov/files/sharedassets/county/v/1/board-of-supervisors/supervisor-brian-pacheco/brian-pacheco_final_2017-002.jpg
--   Nathan Magsig   unknown  https://www.fresnocountyca.gov/files/sharedassets/county/v/2/board-of-supervisors/supervisor-nathan-magsig/supervisor-nathan-magsig.png
--   Annalisa Perea  unknown  https://www.fresno.gov/wp-content/uploads/2022/12/annalisa_perea.jpg
--   Robert Garcia   unknown  https://garcia.asmdc.org/sites/garcia.asmdc.org/files/AsmGarcia_Robert%20Studio%20Headshots%2003-03-26%20-1016_0.jpg
--   Paul Seo        unknown  https://rpvca.gov/ImageRepository/Document?documentID=20164
--   David Couch     unknown  https://www.kerncounty.com/home/showpublishedimage/2316/637114240200370000
--   Jackie Elward   unknown  https://www.rpcity.ca.gov/ImageRepository/Document?documentID=1011
--
-- 🔴 THREE SOURCE URLS CARRY NO NAME, WHICH IS THE OFF-BY-ONE CLASS. Seo, Couch and Elward
-- come from CMS endpoints keyed on an id or a seat (documentID=20164, showpublishedimage/2316,
-- documentID=1011). A positional filename encodes a SLOT, not a PERSON, so each was bound to
-- its subject by the alt text AND by the body's own roster entry — never by a name search:
--   * Seo    — alt "City Council 2023 - Seo", on rpvca.gov/1582 titled "Mayor Paul Seo", and
--              the city's 2025-12-02 reorganization notice names Seo as Mayor.
--   * Couch  — alt "david couch", on the county's own District 4 page.
--   * Elward — alt "Profile picture of Jackie Elward", reached from the council roster's
--              District 4 entry (directory eid=108), not from a search for her name.
-- All seven renders were opened and looked at before publication. This repo has shipped the
-- late President of Yemen as a Bell CA councilman; the alt text alone is not enough.
--
-- 🔴 THE BARE PAGE URL IS NOT THE ORIGINAL — THE RESIZE HIDES IN THE QUERY STRING. Fresno
-- County serves Pacheco's portrait as `...?dimension=pageimage&w=480`. Stripping the query
-- returns the native 2400x3200. Taking the page's own src would have mirrored a 480px copy of
-- a file five times that size.
--
-- CROP. Shared 4:5 geometry, Lanczos, quality 90. NOTHING IS ENLARGED: where the publisher's
-- own file is smaller than 600x750 the stored object is NATIVE size — Magsig 480x600,
-- Perea 339x424, Couch and Elward 200x250. Kern County and Rohnert Park publish nothing larger
-- than 200x250; that is their practice and the answer to the question, not a search failure.
--   * ROBERT GARCIA IS RE-CROPPED AND THE DEFAULT WINDOW WAS WRONG. His source is landscape
--     (1500x999) and he stands left of frame, so the centre 799px window clipped his shoulder.
--     The stored crop is flush to the LEFT edge. Measured, not eyeballed.
--
-- 🔴 ONE OBJECT WAS OVERWRITTEN, AND THIS IS THE VALUE IT OVERWROTE. The storage path
-- 8bfb459b-9823-4b0d-81f4-49cb97831a80-headshot.jpg ALREADY EXISTED and answered HTTP 200,
-- although the database held no photo for Robert Garcia on any of the three surfaces — a file
-- nobody ever wired up. The old object: 600x750 JPEG, 80,453 bytes,
-- sha256 42d4f8942379…, an outdoor portrait of the SAME man against greenery. It was opened
-- and compared before being replaced; the new file is his current official Assembly studio
-- portrait. Because that path was not fresh, HIS URL AND ONLY HIS CARRIES ?v=20261116 — an
-- x-upsert at an existing path returns 200 while the public CDN goes on serving the old bytes.
--   * THE FIRST VERIFY RUN PROVED THIS AND CAUGHT MY OWN MISTAKE. It fetched the un-keyed URL
--     and came back cf-cache HIT with sha 42d4f894 — the OLD photograph — against a local
--     6bb14a9b. The script was asserting on a URL this migration does not store. Re-pointed at
--     the exact stored URL it reads MISS and 6bb14a9b. VERIFY THE URL YOU ARE WRITING DOWN.
--
-- VERIFIED AGAINST THE PUBLIC CDN, NOT THE UPLOAD'S OWN 200. Before the run, a known-good
-- object returned 200 as the positive control and six of the seven target paths were absent
-- (the seventh is Garcia's, above). After the run all 7 were re-fetched from the exact URL
-- written below and compared by sha256 to the local file: 7 of 7 byte-identical.
--
-- NO FACE DETECTOR RAN. check-headshot-faces.py needs Python and there is none on this
-- machine. Every frame was opened and looked at instead. The Sunday CI sweep is the first
-- automated face check these seven will get.

BEGIN;

CREATE TEMP TABLE cc_0438_imported (politician_id uuid, name text, url text, origin text, photo_license text) ON COMMIT DROP;
INSERT INTO cc_0438_imported (politician_id, name, url, origin, photo_license) VALUES
  ('24d28aaa-5420-482b-9a6f-58b5a99f207c'::uuid, 'Brian Pacheco',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/24d28aaa-5420-482b-9a6f-58b5a99f207c-headshot.jpg',
   'https://www.fresnocountyca.gov/Departments/Board-of-Supervisors/Supervisor-Brian-Pacheco', 'unknown'),
  ('cd54f7db-c118-40e5-ab80-afac68b16c94'::uuid, 'Nathan Magsig',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cd54f7db-c118-40e5-ab80-afac68b16c94-headshot.jpg',
   'https://www.fresnocountyca.gov/Departments/Board-of-Supervisors/Supervisor-Nathan-Magsig', 'unknown'),
  ('00a441bc-358d-41f7-802e-58442ccfcfe1'::uuid, 'Annalisa Perea',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/00a441bc-358d-41f7-802e-58442ccfcfe1-headshot.jpg',
   'https://www.fresno.gov/citycouncil/district-1/', 'unknown'),
  ('8bfb459b-9823-4b0d-81f4-49cb97831a80'::uuid, 'Robert Garcia',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8bfb459b-9823-4b0d-81f4-49cb97831a80-headshot.jpg?v=20261116',
   'https://garcia.asmdc.org/', 'unknown'),
  ('cb39159d-d293-41c7-a1ac-a379c39de3c4'::uuid, 'Paul Seo',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cb39159d-d293-41c7-a1ac-a379c39de3c4-headshot.jpg',
   'https://rpvca.gov/1582/Mayor-Paul-Seo', 'unknown'),
  ('fa4d31f3-85b6-4acb-89d0-ec7f0a63cc31'::uuid, 'David Couch',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fa4d31f3-85b6-4acb-89d0-ec7f0a63cc31-headshot.jpg',
   'https://www.kerncounty.com/government/board-of-supervisors/district-4', 'unknown'),
  ('84ff1de0-3b92-45dc-a49b-e6c17af01495'::uuid, 'Jackie Elward',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/84ff1de0-3b92-45dc-a49b-e6c17af01495-headshot.jpg',
   'https://www.rpcity.ca.gov/m/directory/employee?eid=108', 'unknown');

-- The DELTA this file creates, captured in its OWN transaction. A total can be moved by
-- another session between the measurement and the write; a before/after pair inside one
-- transaction cannot be.
CREATE TEMP TABLE cc_0438_before ON COMMIT DROP AS
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
  FROM cc_0438_imported i
 WHERE p.id = i.politician_id
   AND p.photo_custom_url IS DISTINCT FROM i.url;

UPDATE essentials.politicians p
   SET photo_origin_url = i.origin
  FROM cc_0438_imported i
 WHERE p.id = i.politician_id
   AND p.photo_origin_url IS DISTINCT FROM i.origin;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT i.politician_id, i.url, 'default', i.photo_license
  FROM cc_0438_imported i
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                    WHERE pi.politician_id = i.politician_id AND pi.type = 'default');

DO $$
DECLARE
  missing_scalar int;
  missing_origin int;
  wrong_default  int;
  disagreeing    int;
  third_surface  int;
  before_n       int;
  after_n        int;
BEGIN
  -- 1. every one of the 7 renders from the scalar the backend read paths use
  SELECT count(*) INTO missing_scalar
    FROM cc_0438_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE btrim(coalesce(p.photo_custom_url, '')) = '';
  IF missing_scalar <> 0 THEN
    RAISE EXCEPTION 'CC_0438: % of 7 carry no photo_custom_url - they would render blank on address search', missing_scalar;
  END IF;

  -- 2. provenance is recorded. An `unknown` licence is only honest if the page it was read
  --    from is written down beside it.
  SELECT count(*) INTO missing_origin
    FROM cc_0438_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.photo_origin_url IS DISTINCT FROM i.origin;
  IF missing_origin <> 0 THEN
    RAISE EXCEPTION 'CC_0438: % of 7 do not carry the source page in photo_origin_url', missing_origin;
  END IF;

  -- 3. EXACTLY ONE default row each. Two make the grid's find() pick an arbitrary one.
  SELECT count(*) INTO wrong_default FROM (
    SELECT i.politician_id FROM cc_0438_imported i
      LEFT JOIN essentials.politician_images pi
        ON pi.politician_id = i.politician_id AND pi.type = 'default'
     GROUP BY i.politician_id HAVING count(pi.*) <> 1) x;
  IF wrong_default <> 0 THEN
    RAISE EXCEPTION 'CC_0438: % of 7 do not have exactly one type=default image row', wrong_default;
  END IF;

  -- 4. THE TWO SIDES AGREE (CC_0195/CC_0196).
  SELECT count(*) INTO disagreeing
    FROM cc_0438_imported i
    JOIN essentials.politicians p ON p.id = i.politician_id
    JOIN essentials.politician_images pi
      ON pi.politician_id = i.politician_id AND pi.type = 'default'
   WHERE pi.url IS DISTINCT FROM p.photo_custom_url;
  IF disagreeing <> 0 THEN
    RAISE EXCEPTION 'CC_0438: % of 7 have a default image row that disagrees with photo_custom_url', disagreeing;
  END IF;

  -- 5. THE THIRD SURFACE. race_candidates.photo_url is swept by nothing and BEATS the fixed
  --    image on ballot pages, so a stale value there outranks everything written above.
  --    CC_0384 had to name it explicitly for exactly this reason.
  SELECT count(*) INTO third_surface
    FROM cc_0438_imported i
    JOIN essentials.race_candidates rc ON rc.politician_id = i.politician_id
   WHERE btrim(coalesce(rc.photo_url, '')) <> ''
     AND rc.photo_url IS DISTINCT FROM i.url;
  IF third_surface <> 0 THEN
    RAISE EXCEPTION 'CC_0438: % race_candidates rows carry a DIFFERENT photo_url and would outrank the import on ballot pages', third_surface;
  END IF;

  -- 6. THE DELTA. Exactly 7 legislative winners must leave the faceless set, measured inside
  --    this transaction against the snapshot taken before the writes.
  SELECT faceless INTO before_n FROM cc_0438_before;
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
  IF before_n - after_n <> 7 THEN
    RAISE EXCEPTION 'CC_0438: the faceless legislative count moved by % (% -> %), not the 7 this file imports', before_n - after_n, before_n, after_n;
  END IF;

  RAISE NOTICE 'CC_0438 ok: 7 headshots, scalar + origin set, exactly one default row each, both sides agree, third surface clear, faceless legislative winners % -> %', before_n, after_n;
END
$$;

COMMIT;
