-- 1649_deconflate_padilla_senate_vs_inglewood_records.sql
--
-- Move the Inglewood councilmember's identity fields OFF U.S. Senator Alex Padilla's record and ON
-- TO the Inglewood Alex Padilla's own record, where they belong and were missing.
-- Already applied to production by direct MCP execution as `postgres`; guarded on END STATE.
--
-- ── 🔴 WHAT WAS STORED ─────────────────────────────────────────────────────────────────────────
-- Two different men named Alex Padilla:
--   2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f  source=cicero              office = U.S. Senate - California
--   123c9a42-5715-4ab2-a8bd-76e7adbca27b  source=cityofinglewood.org office = Councilmember @ Inglewood
-- The SENATOR's record carried the COUNCILMEMBER's:
--   email_addresses  {apadilla@cityofinglewood.org}
--   urls             {https://www.cityofinglewood.org/587/District-2}
--   notes            a bio of an LA Board of Police Commissioners / Office of the Inspector General
--                    Special Investigator, ex-One West Bank VP of Corporate Security, University of
--                    Redlands -- none of which is Sen. Padilla (LA City Council, state senate, CA
--                    Secretary of State)
--   valid_from/to    2022-12-18 -> 2026-12-20
-- ...while the Inglewood record held NONE of it: all five fields were NULL. The data was not
-- duplicated, it was simply on the wrong man. Voter-visible: a U.S. Senator's profile showing a
-- city-hall email address and a police-commission biography.
--
-- ── VERIFICATION ───────────────────────────────────────────────────────────────────────────────
-- https://www.cityofinglewood.org/m/directory/employee?eid=103 carries that bio VERBATIM (all four
-- of Police Commissioners/Inspector General, One West Bank, University of Redlands, POST Command
-- College), the same APadilla@cityofinglewood.org address, and City Council District 2. It also
-- states he was first elected in 2013 and re-elected in 2017 and 2022 -- so 2022-12 -> 2026-12 is a
-- four-year COUNCIL term. Sen. Padilla's term runs to January 2029, so those dates were never his.
-- Checked 2026-08-09.
--
-- ── SCOPE ──────────────────────────────────────────────────────────────────────────────────────
-- The office links were already correct and are NOT touched: 2717ff94 holds the CA Senate seat
-- alongside Adam Schiff, which is right. Migration 1647 already removed two images of the
-- councilmember from the Senator's record and nulled its cityofinglewood.org photo_origin_url.
-- This migration finishes the job on the text fields.
-- The Senator's record is deliberately left with NULL contact/bio rather than invented values:
-- blank is correct-and-incomplete, whereas the old state was confidently wrong. Sourcing real
-- Senate contact details is a separate task.
-- ⚠ NOT resolved here, deliberately: the Senator's finance_summary is an FEC **2026** cycle block
-- with total_raised 0 though he is not up until 2029; bioguide_id is empty; and party='Democratic'
-- cannot disambiguate the two men because Inglewood's council is nonpartisan.

BEGIN;

-- 1. copy onto the Inglewood record, only while its fields are still empty
UPDATE essentials.politicians tgt
   SET email_addresses = src.email_addresses,
       urls            = src.urls,
       notes           = src.notes,
       valid_from      = src.valid_from,
       valid_to        = src.valid_to
  FROM essentials.politicians src
 WHERE tgt.id = '123c9a42-5715-4ab2-a8bd-76e7adbca27b'::uuid
   AND src.id = '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid
   AND tgt.email_addresses IS NULL
   AND tgt.urls IS NULL
   AND tgt.notes IS NULL
   AND tgt.valid_from IS NULL
   AND tgt.valid_to IS NULL
   AND src.email_addresses IS NOT NULL;

-- 2. clear from the Senator, ONLY once the Inglewood record demonstrably holds the same values.
--    On a fresh replay where step 1 already ran, the EXISTS still matches and this is a no-op.
UPDATE essentials.politicians sen
   SET email_addresses = NULL, urls = NULL, notes = NULL, valid_from = NULL, valid_to = NULL
 WHERE sen.id = '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid
   AND EXISTS (SELECT 1 FROM essentials.politicians ing
                WHERE ing.id = '123c9a42-5715-4ab2-a8bd-76e7adbca27b'::uuid
                  AND ing.email_addresses = sen.email_addresses
                  AND ing.urls            = sen.urls
                  AND ing.notes           = sen.notes
                  AND ing.valid_from      = sen.valid_from
                  AND ing.valid_to        = sen.valid_to);

-- ── VERIFY ─────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_email text[]; v_urls text[]; v_notes text[]; v_from timestamp; v_to timestamp;
        v_office text;
BEGIN
  SELECT email_addresses, urls, notes, valid_from, valid_to
    INTO v_email, v_urls, v_notes, v_from, v_to
    FROM essentials.politicians WHERE id = '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid;
  IF v_email IS NOT NULL OR v_urls IS NOT NULL OR v_notes IS NOT NULL
     OR v_from IS NOT NULL OR v_to IS NOT NULL THEN
    RAISE EXCEPTION 'Sen. Padilla record still carries Inglewood contact/bio/term fields';
  END IF;

  -- nothing anywhere on the Senator may still reference the city
  IF EXISTS (SELECT 1 FROM essentials.politicians
              WHERE id = '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid
                AND (coalesce(photo_origin_url,'') ILIKE '%cityofinglewood%'
                  OR coalesce(photo_custom_url,'') ILIKE '%inglewood%')) THEN
    RAISE EXCEPTION 'Sen. Padilla record still references cityofinglewood.org';
  END IF;

  -- the councilmember must now hold his own data
  SELECT email_addresses, urls INTO v_email, v_urls
    FROM essentials.politicians WHERE id = '123c9a42-5715-4ab2-a8bd-76e7adbca27b'::uuid;
  IF v_email IS NULL OR NOT ('apadilla@cityofinglewood.org' = ANY(v_email)) THEN
    RAISE EXCEPTION 'Inglewood Padilla record is missing his own email address';
  END IF;
  IF v_urls IS NULL OR array_length(v_urls,1) IS NULL THEN
    RAISE EXCEPTION 'Inglewood Padilla record is missing his own district URL';
  END IF;

  -- and the office links must be untouched
  SELECT string_agg(o.title, ' | ' ORDER BY o.title) INTO v_office
    FROM essentials.office_current_holder och JOIN essentials.offices o ON o.id = och.office_id
   WHERE och.politician_id = '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid;
  IF v_office IS DISTINCT FROM 'U.S. Senate - California' THEN
    RAISE EXCEPTION 'Sen. Padilla office link changed: %', v_office;
  END IF;

  SELECT string_agg(o.title, ' | ' ORDER BY o.title) INTO v_office
    FROM essentials.office_current_holder och JOIN essentials.offices o ON o.id = och.office_id
   WHERE och.politician_id = '123c9a42-5715-4ab2-a8bd-76e7adbca27b'::uuid;
  IF v_office IS DISTINCT FROM 'Councilmember' THEN
    RAISE EXCEPTION 'Inglewood Padilla office link changed: %', v_office;
  END IF;
END $$;

COMMIT;
