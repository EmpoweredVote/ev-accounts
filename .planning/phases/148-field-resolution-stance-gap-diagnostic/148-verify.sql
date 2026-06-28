-- 148-verify.sql — Phase 148 Plan 02 read-only production gate (USHC-01).
--
-- SELECT-only. Asserts the live DB still matches the locked field table:
--   1. Every Wave-1 NATIONAL_LOWER non-vacant district maps to exactly one
--      incumbent politician_id by geo_id  (142 mapped incumbents).
--   2. FL-20 (1220) and TX-23 (4823) are still 0-holder (open-seat vacancies).
--   3. All 52 CA general House races in "CA 2026 Statewide General"
--      (728d0074-...) still have 0 race_candidates (the pre-seed baseline).
--   4. Each of the 52 CA existing_race_id values recorded in 148-field-table.csv
--      resolves to a live races.id within the CA general election whose geo_id
--      matches the CSV row's geo_id (encoded (geo_id, race_id) pairs diffed
--      against the live JOIN).
--
-- NEVER mutates. Run read-only:
--   psql "$DATABASE_URL" -f backend/scripts/148-verify.sql
--
-- Wave-1 states (FIPS): CA=06, TX=48, FL=12, NY=36.
-- CA general election id prefix: 728d0074-...
-- Join path: races.office_id -> offices.id, offices.district_id -> districts.id.

\set ON_ERROR_STOP on

DO $$
DECLARE
  v_eid          uuid;
  v_mapped       int;
  v_fl20_holders int;
  v_tx23_holders int;
  v_ca_races     int;
  v_ca_seeded    int;
  v_csv_pairs    int;
  v_mismatch     int;
  v_missing      int;
BEGIN
  -- Resolve the CA 2026 Statewide General election id.
  SELECT id INTO v_eid
  FROM essentials.elections
  WHERE id::text LIKE '728d0074%';
  IF v_eid IS NULL THEN
    RAISE EXCEPTION '[148-verify] CA 2026 Statewide General election (728d0074-...) not found';
  END IF;

  -- ===== Assertion 1: 142 non-vacant Wave-1 incumbents, exactly one holder each =====
  SELECT COUNT(*) INTO v_mapped FROM (
    SELECT d.geo_id
    FROM essentials.districts d
    JOIN essentials.offices o     ON o.district_id = d.id
    JOIN essentials.politicians p ON p.id = o.politician_id
    WHERE d.district_type = 'NATIONAL_LOWER'
      AND substr(d.geo_id,1,2) IN ('06','48','12','36')
    GROUP BY d.geo_id
    HAVING COUNT(o.politician_id) = 1
  ) q;
  IF v_mapped <> 142 THEN
    RAISE EXCEPTION '[148-verify] expected 142 single-holder Wave-1 districts, got %', v_mapped;
  END IF;
  RAISE NOTICE '[148-verify] PASS 1: 142 Wave-1 incumbents each map to exactly one politician_id';

  -- ===== Assertion 2: FL-20 (1220) and TX-23 (4823) still 0-holder =====
  SELECT COALESCE(SUM(CASE WHEN o.politician_id IS NOT NULL THEN 1 ELSE 0 END),0)
    INTO v_fl20_holders
  FROM essentials.districts d
  LEFT JOIN essentials.offices o ON o.district_id = d.id
  WHERE d.district_type='NATIONAL_LOWER' AND d.geo_id='1220';

  SELECT COALESCE(SUM(CASE WHEN o.politician_id IS NOT NULL THEN 1 ELSE 0 END),0)
    INTO v_tx23_holders
  FROM essentials.districts d
  LEFT JOIN essentials.offices o ON o.district_id = d.id
  WHERE d.district_type='NATIONAL_LOWER' AND d.geo_id='4823';

  IF v_fl20_holders <> 0 THEN
    RAISE EXCEPTION '[148-verify] FL-20 (1220) expected 0 holders, got %', v_fl20_holders;
  END IF;
  IF v_tx23_holders <> 0 THEN
    RAISE EXCEPTION '[148-verify] TX-23 (4823) expected 0 holders, got %', v_tx23_holders;
  END IF;
  RAISE NOTICE '[148-verify] PASS 2: FL-20 and TX-23 still 0-holder (open-seat vacancies)';

  -- ===== Assertion 3: 52 CA general House races, all 0 race_candidates =====
  SELECT COUNT(*) INTO v_ca_races
  FROM essentials.races r
  JOIN essentials.offices o   ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE r.election_id = v_eid
    AND d.district_type='NATIONAL_LOWER'
    AND substr(d.geo_id,1,2)='06';
  IF v_ca_races <> 52 THEN
    RAISE EXCEPTION '[148-verify] expected 52 CA general House races, got %', v_ca_races;
  END IF;

  SELECT COUNT(*) INTO v_ca_seeded
  FROM essentials.races r
  JOIN essentials.offices o   ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE r.election_id = v_eid
    AND d.district_type='NATIONAL_LOWER'
    AND substr(d.geo_id,1,2)='06'
    AND EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id);
  IF v_ca_seeded <> 0 THEN
    RAISE EXCEPTION '[148-verify] expected 0 CA races with race_candidates (pre-seed baseline), got %', v_ca_seeded;
  END IF;
  RAISE NOTICE '[148-verify] PASS 3: all 52 CA general races still have 0 race_candidates';

  -- ===== Assertion 4: 52 CSV (geo_id, existing_race_id) pairs match a live CA-general race by geo_id =====
  -- Encoded pairs from 148-field-table.csv:
  CREATE TEMP TABLE _csv_ca (geo_id text, race_id uuid) ON COMMIT DROP;
  INSERT INTO _csv_ca (geo_id, race_id) VALUES
    ('0601', '74a5b509-8904-430a-9630-e48d2889db62'),
    ('0602', '00a7bf9a-96b5-4818-9ff3-3de3a4048068'),
    ('0603', '873ea4ce-52ed-475f-bd4c-006946eeeb99'),
    ('0604', 'eabbb909-51bc-4498-ab4f-10b0f1d83ad3'),
    ('0605', '9889c3b7-f1f5-427b-bef5-90331856451f'),
    ('0606', '17eaf24e-1ab0-4457-a786-787fbcd39157'),
    ('0607', '143ffa3e-701f-46dc-ba19-f67c557b58eb'),
    ('0608', '3714f671-f75b-4f3f-981c-53df319f886c'),
    ('0609', 'f1f491b1-14b9-494b-b2fc-9955e9ee81c6'),
    ('0610', '63afb822-dc57-4d03-b616-e77ebc2b6080'),
    ('0611', '586d8394-217f-4321-ad9e-4da4634202d4'),
    ('0612', '0f99903c-9862-4ef9-b607-d760e8a87cf1'),
    ('0613', '3bff8b9f-03d4-4431-afb1-ec56a0f1c4d3'),
    ('0614', 'f6579e2c-0012-4e01-be52-f202e3aa25c2'),
    ('0615', '21a3ca1e-00a9-47c2-b756-889cd55a84cd'),
    ('0616', '429ad566-e2c3-43f5-bab6-bfbab56bfb18'),
    ('0617', 'd306c5b6-5203-4955-9657-edcc886320a3'),
    ('0618', 'ff4b7da5-25fa-4496-a5f0-decb024d0c2a'),
    ('0619', 'e98beacf-6a5b-4039-b977-eb1c30d53c8d'),
    ('0620', '8f40ae37-39c3-42cd-9bf8-851d6a967bac'),
    ('0621', '1cbd9d96-519c-45e0-a0c2-3cab2b5894fe'),
    ('0622', '43105b49-ecdf-41ce-9309-38a0aef1b81d'),
    ('0623', '7740b4c3-587b-4823-a530-8c229e20debd'),
    ('0624', 'a7de60d2-605c-4db1-88cf-97b12eccf582'),
    ('0625', '295705e5-3254-4d75-bdb3-bf19f46ba099'),
    ('0626', 'c116e2e6-9512-4462-8633-d2a1373161cb'),
    ('0627', '368aba08-e456-4b87-bd65-6d90e09a6d08'),
    ('0628', '61682c04-9730-4528-a50b-7ffed0044016'),
    ('0629', '40190b91-ec57-4da9-9955-1cb3b8b06486'),
    ('0630', 'fc8ac036-1ab5-4012-aa67-16b334137509'),
    ('0631', '19a88b8b-5260-4c7b-b9a5-5217fc306b67'),
    ('0632', 'dd326b64-5a46-4d71-b404-a9d9469cfbc5'),
    ('0633', 'b88178d8-23ac-4ab9-a73c-0687534da38a'),
    ('0634', 'bed3e589-1f6d-4693-93af-5b05c9abc842'),
    ('0635', 'ed452e1f-56aa-4a44-99a1-20fcf6bde43e'),
    ('0636', '40e4571a-7492-4012-b244-70e2b185d15b'),
    ('0637', '232fac06-8757-45c6-9c1b-6b492ec79657'),
    ('0638', '2910e7f6-11f2-4496-a651-056991895606'),
    ('0639', '83f9b284-404b-4869-bb33-a61a27f073ba'),
    ('0640', 'ce3d2c4f-42b2-40bc-9e40-4f96ca1446bb'),
    ('0641', '7ade7f08-0d2e-42e3-b7e4-ac2b5b8c58dd'),
    ('0642', '6113b008-3a56-49e1-8d22-9236af5e7a6d'),
    ('0643', '740e83a7-aba3-4c2c-8137-33502453503e'),
    ('0644', '81365b4a-d1c9-4a4a-ad85-49d9e2640987'),
    ('0645', '69d64aab-bcdb-497f-9392-4e939efe7d95'),
    ('0646', '27130e86-b66f-4c50-9aa1-1a6e5b1887ec'),
    ('0647', 'ccdca7a6-eb1c-4c20-8651-0c1ba6c30d6c'),
    ('0648', '9770ac95-8777-41a2-9006-937ba5e14ba3'),
    ('0649', '92e327ec-a49e-4e85-8516-6778e6712efb'),
    ('0650', '613e48d5-86f9-4a82-811b-f9d1c3b091bd'),
    ('0651', '70c0bbe6-ae6e-462e-bfbf-741c34810fe0'),
    ('0652', '959c4e27-ef9b-4dea-be87-a5ff8d42bb8f');

  SELECT COUNT(*) INTO v_csv_pairs FROM _csv_ca;
  IF v_csv_pairs <> 52 THEN
    RAISE EXCEPTION '[148-verify] expected 52 encoded CA CSV pairs, got %', v_csv_pairs;
  END IF;

  -- Build the live (geo_id, race_id) set for the CA general election, then diff.
  -- (a) CSV race_id must exist as a live CA-general race AND its live geo_id must match the CSV geo_id.
  SELECT COUNT(*) INTO v_mismatch
  FROM _csv_ca c
  LEFT JOIN (
    SELECT r.id AS race_id, d.geo_id
    FROM essentials.races r
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE r.election_id = v_eid
      AND d.district_type='NATIONAL_LOWER'
      AND substr(d.geo_id,1,2)='06'
  ) live ON live.race_id = c.race_id
  WHERE live.race_id IS NULL OR live.geo_id <> c.geo_id;
  IF v_mismatch <> 0 THEN
    RAISE EXCEPTION '[148-verify] % CA existing_race_id value(s) are blank, missing in the CA general election, or map to a different geo_id', v_mismatch;
  END IF;

  -- (b) Every live CA-general geo_id must be covered by the CSV (no CA district left without a recorded race_id).
  SELECT COUNT(*) INTO v_missing
  FROM (
    SELECT d.geo_id
    FROM essentials.races r
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE r.election_id = v_eid
      AND d.district_type='NATIONAL_LOWER'
      AND substr(d.geo_id,1,2)='06'
  ) live
  WHERE NOT EXISTS (SELECT 1 FROM _csv_ca c WHERE c.geo_id = live.geo_id);
  IF v_missing <> 0 THEN
    RAISE EXCEPTION '[148-verify] % live CA-general geo_id(s) have no recorded existing_race_id in the CSV', v_missing;
  END IF;

  RAISE NOTICE '[148-verify] PASS 4: all 52 CA existing_race_id values resolve to a live CA-general race with matching geo_id';

  RAISE NOTICE '[148-verify] ALL ASSERTIONS PASSED';
END $$;
