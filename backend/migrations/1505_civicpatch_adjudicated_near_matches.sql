-- 1505_civicpatch_adjudicated_near_matches.sql
--
-- Backfill office contacts for 12 municipal officials we ALREADY HOLD, from the
-- vendored CC0 CivicPatch snapshot 928579c0 (backend/data/civicpatch/).
-- Approved scope: .planning/decisions/2026-07-30-civicpatch-api-decision.md
--
-- OPERATOR-ADJUDICATED NEAR-MATCHES. Every row here was REFUSED by the automatic matcher
-- because the normalised names differ — the "Ben"/"Benjamin" shape that has produced real
-- errors before. Each was then confirmed by hand and approved by the operator on
-- 2026-07-30. Each is 1:1 within its city (exactly one surname+initial candidate on each
-- side) and each carries a corroborating office title, so name and seat agree
-- independently. THE MATCHER WAS NOT LOOSENED — it still refuses these, by design.
--
-- ADDITIVE ONLY. Each insert is guarded on the politician having no contact_type='office'
-- row at all, so nothing we already hold is overwritten. Re-running is a no-op.
--

BEGIN;

-- ca/place:carson · theirs "Arleen Bocatija Rojas"  ->  ours "Arleen B. Rojas" (Council Member (District 4))
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '258b185a-5b28-45a0-9e7f-a05a58080197'::uuid, 'civicpatch:928579c0', 'arojas@carsonca.gov', '(310) 952-1700', 'https://carsonca.gov/government/elected_officials/district_4.php', 'office', '2025-07-18T21:09:36+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '258b185a-5b28-45a0-9e7f-a05a58080197'::uuid AND c.contact_type = 'office');

-- ca/place:compton · theirs "Lillie Darden"  ->  ours "Lillie P. Darden" (Council Member (District 4))
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '10429226-b00b-4b96-b306-753c2094d719'::uuid, 'civicpatch:928579c0', 'ldarden@comptoncity.org', '(310) 605-5511', 'https://www.comptoncity.org/our-city/elected-officials/district-4-lillie-darden', 'office', '2025-07-18T21:05:41+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '10429226-b00b-4b96-b306-753c2094d719'::uuid AND c.contact_type = 'office');

-- ca/place:glendale · theirs "Dan Brotman"  ->  ours "Daniel Brotman" (Councilmember)
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '9db24324-3d82-4c2b-8404-078a53708447'::uuid, 'civicpatch:928579c0', 'DBrotman@GlendaleCA.gov', '(818) 548-4844 ext. 1', 'https://www.glendaleca.gov/government/city-council/councilmember-dan-brotman', 'office', '2025-07-17T17:29:06+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '9db24324-3d82-4c2b-8404-078a53708447'::uuid AND c.contact_type = 'office');

-- ca/place:glendale · theirs "Ardashes "Ardy" Kassakhian"  ->  ours "Ardy Kassakhian" (Mayor)
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '9b2e0e78-91b0-4e8a-882c-7660da792004'::uuid, 'civicpatch:928579c0', 'AKassakhian@GlendaleCA.gov', '(818) 548-4844 ext. 1', 'https://www.glendaleca.gov/government/city-council/councilmember-ardy-kassakhian', 'office', '2025-07-17T17:29:06+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '9b2e0e78-91b0-4e8a-882c-7660da792004'::uuid AND c.contact_type = 'office');

-- ca/place:inglewood · theirs "Gloria Gray"  ->  ours "Gloria D. Gray" (Councilwoman)
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '7a04bf87-ab95-4ae7-a142-9899662637b1'::uuid, 'civicpatch:928579c0', 'ggray@cityofinglewood.org', '(310) 412-8602', 'https://www.cityofinglewood.org/directory.aspx?EID=105', 'office', '2025-07-18T20:16:11+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '7a04bf87-ab95-4ae7-a142-9899662637b1'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · theirs "Karen Bass"  ->  ours "Karen Ruth Bass" (Mayor)
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid, 'civicpatch:928579c0', NULL, '(213) 473-3231', 'https://mayor.lacity.gov/about-mayor-karen-bass', 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid AND c.contact_type = 'office');

-- ca/place:los_angeles · theirs "Ysabel Jurado"  ->  ours "Ysabel J. Jurado" (Council Member)
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '04d12540-8075-4263-894a-6575f7c9bd14'::uuid, 'civicpatch:928579c0', 'Councilmember.Jurado@lacity.org', NULL, NULL, 'office', '2025-07-17T03:10:23+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '04d12540-8075-4263-894a-6575f7c9bd14'::uuid AND c.contact_type = 'office');

-- ca/place:san_diego · theirs "Henry Foster III"  ->  ours "Henry L. Foster III" (Council Member)
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '296b5d71-954a-46db-8055-17299abb86fa'::uuid, 'civicpatch:928579c0', 'HenryFoster@sandiego.gov', '(619) 236-6644', 'https://www.sandiego.gov/citycouncil/cd4', 'office', '2025-07-17T03:15:38+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '296b5d71-954a-46db-8055-17299abb86fa'::uuid AND c.contact_type = 'office');

-- ma/place:springfield · theirs "Victor Davila"  ->  ours "Victor G. Davila" (City Councilor (Ward 6))
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'f55836a5-4525-4142-9773-1bc08b21cc63'::uuid, 'civicpatch:928579c0', 'vdavila@springfieldcityhall.com', '(413) 297-8614', 'https://www.springfield-ma.gov/cos/city-council-members', 'office', '2026-07-11T15:24:19+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'f55836a5-4525-4142-9773-1bc08b21cc63'::uuid AND c.contact_type = 'office');

-- tx/place:lowry_crossing · theirs "Eusebio Trujillo III"  ->  ours "Eusebio "Joe" Trujillo III" (Council Member Place 3)
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'c765ca48-4960-42c9-bf31-a4e074227e14'::uuid, 'civicpatch:928579c0', 'etrujillo@lowrycrossingtexas.org', NULL, 'https://www.lowrycrossingtexas.org/operations/city_council.php', 'office', '2026-03-28T21:39:16+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'c765ca48-4960-42c9-bf31-a4e074227e14'::uuid AND c.contact_type = 'office');

-- tx/place:van_alstyne · theirs "Ryan T. Neal"  ->  ours "Ryan Neal" (Council Member Place 1)
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT '1c178f04-87e5-4b27-9793-3afbff6e7ae5'::uuid, 'civicpatch:928579c0', 'aldermanplace1@cityofvanalstyne.us', '(903) 482-5426', 'https://www.cityofvanalstyne.us/council', 'office', '2026-03-31T05:21:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = '1c178f04-87e5-4b27-9793-3afbff6e7ae5'::uuid AND c.contact_type = 'office');

-- tx/place:van_alstyne · theirs "Marla E. Butler"  ->  ours "Marla Butler" (Council Member Place 2)
INSERT INTO essentials.politician_contacts
  (politician_id, source, email, phone, website_url, contact_type, contact_synced_at)
SELECT 'a710f944-a299-4ffd-9c4f-b110474b0560'::uuid, 'civicpatch:928579c0', 'aldermanplace2@cityofvanalstyne.us', '(903) 482-5426', 'https://www.cityofvanalstyne.us/council', 'office', '2026-03-31T05:21:30+00:00'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts c
   WHERE c.politician_id = 'a710f944-a299-4ffd-9c4f-b110474b0560'::uuid AND c.contact_type = 'office');

-- Post-verify gate: every intended politician must now carry an 'office' contact, and this
-- migration must not have created a second one for anybody.
DO $$
DECLARE
  expected int := 12;
  covered  int;
  dupes    int;
BEGIN
  SELECT count(*) INTO covered
    FROM essentials.politician_contacts
   WHERE contact_type = 'office'
     AND politician_id IN ('258b185a-5b28-45a0-9e7f-a05a58080197'::uuid, '10429226-b00b-4b96-b306-753c2094d719'::uuid, '9db24324-3d82-4c2b-8404-078a53708447'::uuid, '9b2e0e78-91b0-4e8a-882c-7660da792004'::uuid, '7a04bf87-ab95-4ae7-a142-9899662637b1'::uuid, '21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid, '04d12540-8075-4263-894a-6575f7c9bd14'::uuid, '296b5d71-954a-46db-8055-17299abb86fa'::uuid, 'f55836a5-4525-4142-9773-1bc08b21cc63'::uuid, 'c765ca48-4960-42c9-bf31-a4e074227e14'::uuid, '1c178f04-87e5-4b27-9793-3afbff6e7ae5'::uuid, 'a710f944-a299-4ffd-9c4f-b110474b0560'::uuid);
  IF covered <> expected THEN
    RAISE EXCEPTION 'expected % politicians with an office contact, found %', expected, covered;
  END IF;

  -- Scoped to THIS batch: prod may hold unrelated duplicate office contacts elsewhere,
  -- and this gate must fail only on damage we caused.
  SELECT count(*) INTO dupes FROM (
    SELECT politician_id FROM essentials.politician_contacts
     WHERE contact_type = 'office'
       AND politician_id IN ('258b185a-5b28-45a0-9e7f-a05a58080197'::uuid, '10429226-b00b-4b96-b306-753c2094d719'::uuid, '9db24324-3d82-4c2b-8404-078a53708447'::uuid, '9b2e0e78-91b0-4e8a-882c-7660da792004'::uuid, '7a04bf87-ab95-4ae7-a142-9899662637b1'::uuid, '21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid, '04d12540-8075-4263-894a-6575f7c9bd14'::uuid, '296b5d71-954a-46db-8055-17299abb86fa'::uuid, 'f55836a5-4525-4142-9773-1bc08b21cc63'::uuid, 'c765ca48-4960-42c9-bf31-a4e074227e14'::uuid, '1c178f04-87e5-4b27-9793-3afbff6e7ae5'::uuid, 'a710f944-a299-4ffd-9c4f-b110474b0560'::uuid)
     GROUP BY politician_id HAVING count(*) > 1) d;
  IF dupes > 0 THEN
    RAISE EXCEPTION 'duplicate office contacts for % politicians', dupes;
  END IF;
END $$;

COMMIT;
