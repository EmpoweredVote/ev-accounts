BEGIN;

-- =============================================================================
-- CA_0328: date the TX-23 and FL-20 U.S. House vacancies; Everton Blair Jr.'s portrait and website
-- =============================================================================
-- Follow-ups from CA_0326 (issue #1088). After CA_0326 seated Blair in GA-13, two U.S. House seats are
-- still flagged is_vacant with NO vacant_since and no office_terms row. Both are real vacancies, not
-- un-seeded seats, so they get the date that tells the two apart (CLAUDE.md, "An undated flag cannot tell
-- you which kind of thing it is").
--
-- Facts and sources (read 2026-10-26):
--   * House Clerk, Vacancies of the 119th Congress (clerk.house.gov/Members/ViewVacancies):
--       Texas 23rd District   — "Resigned April 14, 2026 | Rep. Tony Gonzales"; Special Election Date TBD.
--       Florida 20th District — "Resigned April 21, 2026 | Rep. Sheila Cherfilus-McCormick";
--                               Special Election Date TBD.
--   * House Clerk MemberData.xml (publish-date October 1, 2026), TX23 / FL20: no member; footnotes
--     "Vacancy due to the resignation of Tony Gonzales, April 14, 2026." and "... of Sheila
--     Cherfilus-McCormick, April 21, 2026."
--   * The Clerk's date is the date of the VACANCY, which is what vacant_since records (the first vacant
--     day). It is used as given. (CC_0294 took the day after a withdrawal because its source dated the
--     member's last day, not the vacancy; the Clerk dates the vacancy itself.)
--   * Blair: official House portrait, bioguide.congress.gov/photo/B001328.jpg (625x750, a work of the
--     U.S. government — public domain, as for every other House portrait in politician_images), resized
--     and cropped to 600x750 and pre-uploaded to politician_photos/<id>-headshot.jpg. Official website
--     blair.house.gov (title "Representative Everton Blair Jr. | Representing Georgia's 13th District").
--
-- Writes:
--   1. offices.vacant_since = 2026-04-14 (TX-23) and 2026-04-21 (FL-20). No vacancy span: the departed
--      members were never seeded, so there is no term to close (CC_0294 shape). Nobody is seated.
--   2. Blair: politician_images row (public_domain), photo_custom_url / photo_origin_url, urls.
--      No bio: blair.house.gov/about says to contact the office for his biography, and no other House
--      member carries a bio_text. Left blank on purpose.
--
-- offices_missing_terms does NOT move (296 / 57 / 239). Within the flagged bucket, dated 15 -> 17 and
-- undated 42 -> 40.
-- Idempotent: every write is guarded; a re-run changes nothing and the post-verify passes.
-- =============================================================================

DO $$
DECLARE v int;
BEGIN
  -- Both seats are the NATIONAL_LOWER offices we think they are, with no term, flagged vacant, and
  -- either undated or already carrying exactly this date (a re-run).
  SELECT count(*) INTO v FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.district_type = 'NATIONAL_LOWER' AND o.is_vacant
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id)
     AND ((o.id = 'b746cfac-5e06-413e-abde-898c4e4b8a2d' AND d.geo_id = '4823'
           AND (o.vacant_since IS NULL OR o.vacant_since::date = DATE '2026-04-14'))
       OR (o.id = '5dd1387d-f8c9-4583-aaa3-09ab2ed538ba' AND d.geo_id = '1220'
           AND (o.vacant_since IS NULL OR o.vacant_since::date = DATE '2026-04-21')));
  IF v <> 2 THEN
    RAISE EXCEPTION 'CA_0328: pre-flight — TX-23 / FL-20 not in the expected state (matched % of 2); read the rows first', v;
  END IF;

  -- Blair is the CA_0326 row, and nothing hand-locked is in the way.
  SELECT count(*) INTO v FROM essentials.politicians
   WHERE id = '230d1dac-ddbc-472d-9314-89967917eb5a' AND external_id = -13013 AND bioguide_id = 'B001328'
     AND full_name = 'Everton Blair Jr.' AND photo_custom_url_manual_override IS NOT TRUE;
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0328: pre-flight — Blair row not as expected (run CA_0326 first)'; END IF;
END $$;

-- 1. Date the two vacancies.
UPDATE essentials.offices SET vacant_since = DATE '2026-04-14'
 WHERE id = 'b746cfac-5e06-413e-abde-898c4e4b8a2d' AND is_vacant AND vacant_since IS NULL;
UPDATE essentials.offices SET vacant_since = DATE '2026-04-21'
 WHERE id = '5dd1387d-f8c9-4583-aaa3-09ab2ed538ba' AND is_vacant AND vacant_since IS NULL;

-- 2. Blair's portrait and website.
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '230d1dac-ddbc-472d-9314-89967917eb5a',
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/230d1dac-ddbc-472d-9314-89967917eb5a-headshot.jpg',
       'default', 'public_domain'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '230d1dac-ddbc-472d-9314-89967917eb5a');

UPDATE essentials.politicians
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/230d1dac-ddbc-472d-9314-89967917eb5a-headshot.jpg',
       photo_origin_url = 'https://bioguide.congress.gov/photo/B001328.jpg'
 WHERE id = '230d1dac-ddbc-472d-9314-89967917eb5a'
   AND photo_custom_url_manual_override IS NOT TRUE
   AND coalesce(photo_custom_url, '') = ''
   AND coalesce(photo_origin_url, '') = '';

UPDATE essentials.politicians
   SET urls = ARRAY['https://blair.house.gov/']
 WHERE id = '230d1dac-ddbc-472d-9314-89967917eb5a'
   AND coalesce(array_length(urls, 1), 0) = 0;

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM essentials.offices
   WHERE (id = 'b746cfac-5e06-413e-abde-898c4e4b8a2d' AND is_vacant AND vacant_since::date = DATE '2026-04-14')
      OR (id = '5dd1387d-f8c9-4583-aaa3-09ab2ed538ba' AND is_vacant AND vacant_since::date = DATE '2026-04-21');
  IF v <> 2 THEN RAISE EXCEPTION 'CA_0328: % of 2 vacancies dated', v; END IF;
  -- Dating seats nobody.
  SELECT count(*) INTO v FROM essentials.office_terms
   WHERE office_id IN ('b746cfac-5e06-413e-abde-898c4e4b8a2d', '5dd1387d-f8c9-4583-aaa3-09ab2ed538ba');
  IF v <> 0 THEN RAISE EXCEPTION 'CA_0328: % term(s) on TX-23 / FL-20, expected 0', v; END IF;

  SELECT count(*) INTO v FROM essentials.politician_images
   WHERE politician_id = '230d1dac-ddbc-472d-9314-89967917eb5a' AND photo_license = 'public_domain'
     AND url LIKE '%/politician_photos/230d1dac-ddbc-472d-9314-89967917eb5a-headshot.jpg';
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0328: Blair image row not as expected (found %)', v; END IF;
  SELECT count(*) INTO v FROM essentials.politicians
   WHERE id = '230d1dac-ddbc-472d-9314-89967917eb5a'
     AND photo_custom_url LIKE '%/politician_photos/230d1dac-ddbc-472d-9314-89967917eb5a-headshot.jpg'
     AND photo_origin_url = 'https://bioguide.congress.gov/photo/B001328.jpg'
     AND urls = ARRAY['https://blair.house.gov/']
     AND bio_text IS NULL;
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0328: Blair portrait/website not as expected'; END IF;
END $$;

COMMIT;
