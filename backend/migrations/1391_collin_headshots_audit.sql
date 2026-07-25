-- Phase 218 Plan 04: Audit-only migration recording politician_images rows for headshots sourced
-- and uploaded to Supabase Storage (bucket politician_photos) for the newly-seated Collin County,
-- TX officials from Plans 02/03 (migrations 1389/1390).
--
-- This migration does NOT upload images (that happened out-of-band via the Storage API). It only
-- idempotently INSERTs the essentials.politician_images row + backfills politicians.photo_origin_url
-- for each politician who now has a real, sourced 600x750 headshot in Storage. Guarded so a re-run
-- inserts nothing new (WHERE NOT EXISTS on politician_id, matching the [[section_split_check]]-style
-- idempotency convention used by migrations 1389/1390).
--
-- Honest blanks (per D-03, no row inserted, no image fabricated):
--   - Jessica Walden (Anna, Place 3) - official bio page has no photo widget; Ballotpedia (Cloudflare
--     202 challenge) and TML directory (406) both inaccessible.
--   - Zach Williams (Van Alstyne, Place 6) - personPhoto URL found in the site's membershipware
--     people-API JSON, but every fetch variant (both cityofvanalstyne.us and app.membershipware.com
--     hosts, encoded/double-encoded/raw slash forms of the blob id) was rejected: either an Azure WAF
--     400 (encoded-slash + rf=t combination) or an app-level "Access denied: item not accessible" once
--     the WAF was avoided by dropping rf=t. Genuinely inaccessible via automation.
--   - Blue Ridge (Rhonda Williams, David Apple, Keith Chitwood), Lowry Crossing (Muhanad Hijazen, Chris
--     Madrid, Agur Rios, Cindy Cash, Ollie Simpson), Nevada (Donald Deering, Mike Laye, Paul Baker) -
--     documented zero-photo cities per milestone convention (D-03); not attempted.
--   - Gary Chappell (Josephine) and Shun Thomas (Plano) already had a politician_images row before
--     this plan (preserved via Plan 02's candidate-row reuse / pre-existing migration 091) - excluded
--     from this migration's target list, no new row needed.

DO $$
DECLARE
  v_politician_id UUID;
  v_url TEXT;
  v_origin_url TEXT;
BEGIN
  -- 1. Elden Baker (Anna, Council Member Place 5)
  v_politician_id := '3842838e-2015-4136-95d2-97f4f20366b1';
  v_url := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3842838e-2015-4136-95d2-97f4f20366b1-headshot.jpg';
  v_origin_url := 'https://www.annatexas.gov/1426/Elden-Baker';
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = v_politician_id) THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_politician_id, v_url, 'default', 'press_use');
    UPDATE essentials.politicians SET photo_origin_url = v_origin_url WHERE id = v_politician_id AND photo_origin_url IS NULL;
  END IF;

  -- 2. Joe W. Boggs (Fairview, Council Member Seat 2)
  v_politician_id := '1a726799-8eb1-4479-b46a-83aacb0109e8';
  v_url := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1a726799-8eb1-4479-b46a-83aacb0109e8-headshot.jpg';
  v_origin_url := 'https://fairviewtexas.org/government/mayor-town-council/';
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = v_politician_id) THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_politician_id, v_url, 'default', 'press_use');
    UPDATE essentials.politicians SET photo_origin_url = v_origin_url WHERE id = v_politician_id AND photo_origin_url IS NULL;
  END IF;

  -- 3. Lakia Works (Fairview, Council Member Seat 6)
  v_politician_id := '9e80fff4-8b89-4c38-b33e-a1a0fff7e080';
  v_url := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9e80fff4-8b89-4c38-b33e-a1a0fff7e080-headshot.jpg';
  v_origin_url := 'https://fairviewtexas.org/government/mayor-town-council/';
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = v_politician_id) THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_politician_id, v_url, 'default', 'press_use');
    UPDATE essentials.politicians SET photo_origin_url = v_origin_url WHERE id = v_politician_id AND photo_origin_url IS NULL;
  END IF;

  -- 4. John Stanley (Fairview, Council Member Seat 4)
  v_politician_id := '194c1b38-e76c-4edb-a064-0a7e7e1ac195';
  v_url := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/194c1b38-e76c-4edb-a064-0a7e7e1ac195-headshot.jpg';
  v_origin_url := 'https://fairviewtexas.org/government/mayor-town-council/';
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = v_politician_id) THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_politician_id, v_url, 'default', 'press_use');
    UPDATE essentials.politicians SET photo_origin_url = v_origin_url WHERE id = v_politician_id AND photo_origin_url IS NULL;
  END IF;

  -- 5. Lee Pettle (Parker, Mayor)
  v_politician_id := '61f73b44-c46d-4f1b-91a7-0d35c83feecb';
  v_url := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/61f73b44-c46d-4f1b-91a7-0d35c83feecb-headshot.jpg';
  v_origin_url := 'https://www.parkertexas.us/76/City-Council';
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = v_politician_id) THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_politician_id, v_url, 'default', 'press_use');
    UPDATE essentials.politicians SET photo_origin_url = v_origin_url WHERE id = v_politician_id AND photo_origin_url IS NULL;
  END IF;

  -- 6. Buddy Pilgrim (Parker, Council Member Place 3)
  v_politician_id := '812359f8-3ea5-4815-91ca-7e5a4ba2ba0a';
  v_url := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/812359f8-3ea5-4815-91ca-7e5a4ba2ba0a-headshot.jpg';
  v_origin_url := 'https://www.parkertexas.us/76/City-Council';
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = v_politician_id) THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_politician_id, v_url, 'default', 'press_use');
    UPDATE essentials.politicians SET photo_origin_url = v_origin_url WHERE id = v_politician_id AND photo_origin_url IS NULL;
  END IF;

  -- 7. Billy Barron (Parker, Council Member Place 5)
  v_politician_id := 'e136a517-1772-4f16-9bd5-785828f524e8';
  v_url := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e136a517-1772-4f16-9bd5-785828f524e8-headshot.jpg';
  v_origin_url := 'https://www.parkertexas.us/76/City-Council';
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = v_politician_id) THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_politician_id, v_url, 'default', 'press_use');
    UPDATE essentials.politicians SET photo_origin_url = v_origin_url WHERE id = v_politician_id AND photo_origin_url IS NULL;
  END IF;

  -- 8. Jaisen Rutledge (Princeton, Council Member Place 4)
  v_politician_id := '53f97990-822e-46de-8e18-f09e5a160c2b';
  v_url := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/53f97990-822e-46de-8e18-f09e5a160c2b-headshot.jpg';
  v_origin_url := 'https://www.princetontx.gov/735/Jaisen-Rutledge';
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = v_politician_id) THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_politician_id, v_url, 'default', 'press_use');
    UPDATE essentials.politicians SET photo_origin_url = v_origin_url WHERE id = v_politician_id AND photo_origin_url IS NULL;
  END IF;

  -- 9. Jim Atchison (Van Alstyne, Mayor)
  v_politician_id := '4e7bc81e-1b24-4113-a839-3d87a2637df1';
  v_url := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4e7bc81e-1b24-4113-a839-3d87a2637df1-headshot.jpg';
  v_origin_url := 'https://www.cityofvanalstyne.us/council';
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = v_politician_id) THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_politician_id, v_url, 'default', 'press_use');
    UPDATE essentials.politicians SET photo_origin_url = v_origin_url WHERE id = v_politician_id AND photo_origin_url IS NULL;
  END IF;

  -- 10. Marla Johnston (Weston, Council Member Place 5)
  v_politician_id := 'bf89cead-3e7b-4f03-b5be-040c45aa7d07';
  v_url := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bf89cead-3e7b-4f03-b5be-040c45aa7d07-headshot.jpg';
  v_origin_url := 'https://www.westontexas.com/page/Mayor_Aldermen';
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = v_politician_id) THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_politician_id, v_url, 'default', 'press_use');
    UPDATE essentials.politicians SET photo_origin_url = v_origin_url WHERE id = v_politician_id AND photo_origin_url IS NULL;
  END IF;

  -- 11. Jonathan Underhill (Lucas, Council Member Place 1)
  v_politician_id := '4ad7d4e3-c0d2-4b7a-bc32-a8b3f41551a0';
  v_url := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4ad7d4e3-c0d2-4b7a-bc32-a8b3f41551a0-headshot.jpg';
  v_origin_url := 'https://www.lucastexas.us/164/City-Council';
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = v_politician_id) THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_politician_id, v_url, 'default', 'press_use');
    UPDATE essentials.politicians SET photo_origin_url = v_origin_url WHERE id = v_politician_id AND photo_origin_url IS NULL;
  END IF;

  -- 12. Rebecca B. Orr (Lucas, Council Member Place 2)
  v_politician_id := '3c839111-ed39-41fd-8e63-9c81b1e3e591';
  v_url := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3c839111-ed39-41fd-8e63-9c81b1e3e591-headshot.jpg';
  v_origin_url := 'https://www.lucastexas.us/164/City-Council';
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = v_politician_id) THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_politician_id, v_url, 'default', 'press_use');
    UPDATE essentials.politicians SET photo_origin_url = v_origin_url WHERE id = v_politician_id AND photo_origin_url IS NULL;
  END IF;

END $$;
