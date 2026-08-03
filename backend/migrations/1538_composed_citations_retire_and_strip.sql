-- 1538_composed_citations_retire_and_strip.sql
--
-- Composed citations: URLs that return a hard 404 today, that Wayback has NEVER captured in any
-- query form, on hosts where Wayback holds 3,000+ sibling URLs in the same directory. A page a
-- continuously-crawled host never served and the archive never saw was composed, not visited, so
-- re-pointing cannot fix it -- there is no real page to point at.
--   Rollback record: data/stance-retirement/2026-08-02-composed-rollback.json
--   Reviews:         data/stance-retirement/2026-08-02-composed-secondsource.md
--                    data/stance-retirement/2026-08-02-dead-url-tail.md
--
-- RETIRE 209 rows with no citation a reader can check · STRIP the dead URL from 505 rows that
-- keep a working one · LEAVE 187 rows untouched pending a fetch pass.
--
-- 🔴 THE DECISION SET IS 209, NOT THE 61 IN NEXT-composed-citations.md. That 61 is exactly
-- reproducible and validates the method, but it counts only rows whose SINGLE source is composed.
-- It misses 138 rows citing TWO OR THREE composed URLs and nothing else -- more citations, the
-- same zero evidence -- plus 10 whose other sources are hard 404s. Breakdown:
--   61 SOLE_SOURCED_COMPOSED · 138 ALL_SOURCES_COMPOSED · 10 ALL_OTHERS_ALSO_BAD
--
-- ⚠ THE 187 UNTOUCHED ROWS ARE NOT CLEARED, THEY ARE UNDECIDED. Their only other citations
-- are all BOT_BLOCKED or FETCH_FAILED, and the tail pass established that a 403 says nothing --
-- ten such URLs returned one identical 4,215-byte block page. They need a real fetch, not a
-- verdict inferred from a status code.
--
-- ⚠ STRIPPING IS NOT COSMETIC. A composed URL shown next to a working one still invites a reader
-- to check evidence that does not exist. The rows keep their chair and every other citation.
--
-- ⚠ NOT APPLIED TO THE FOUR THIN HOSTS. lynnma.gov, alhambraca.gov, carsonca.gov and
-- medfordma.org are a genuine Wayback coverage gap rather than composed URLs (0/7/67/78 archived
-- siblings), so their 24 URLs are excluded from the composed set entirely. ⚠ They must be held out
-- by HOST, not by directory prefix: the prefixes named in the write-up catch only 6 of the 24.

BEGIN;

-- ---- retire ----------------------------------------------------------------------------------
CREATE TEMP TABLE _retire_1538 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1538 (politician_id, topic_id) VALUES
  ('dee11bee-c034-49b1-ba4c-30f94622ddd3', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Brittany Hume Charm: Residential Zoning [ALL_SOURCES_COMPOSED]
  ('dee11bee-c034-49b1-ba4c-30f94622ddd3', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Brittany Hume Charm: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('dee11bee-c034-49b1-ba4c-30f94622ddd3', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Brittany Hume Charm: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('dee11bee-c034-49b1-ba4c-30f94622ddd3', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Brittany Hume Charm: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('929346a2-8037-4b14-af33-4820eb365323', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),  -- Micah Beckwith: Misinformation and the Role of Algorithms in Democracy [SOLE_SOURCED_COMPOSED]
  ('583a5fab-16d5-40c5-8c6c-25b9ea4b97ae', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Cyrus Dahmubed: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('d7479ffb-177a-44cd-aaac-d86d91522fc3', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Rena Getz: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('d7479ffb-177a-44cd-aaac-d86d91522fc3', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Rena Getz: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('41c14549-89c4-451c-91d7-22a578a4dc7d', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Brian Golden: Residential Zoning [ALL_SOURCES_COMPOSED]
  ('41c14549-89c4-451c-91d7-22a578a4dc7d', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Brian Golden: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('41c14549-89c4-451c-91d7-22a578a4dc7d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Brian Golden: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('41c14549-89c4-451c-91d7-22a578a4dc7d', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Brian Golden: Transportation Priorities [ALL_SOURCES_COMPOSED]
  ('41c14549-89c4-451c-91d7-22a578a4dc7d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Brian Golden: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('41c14549-89c4-451c-91d7-22a578a4dc7d', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Brian Golden: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4', 'eb3d1247-0de1-4b7f-baec-7259861efd53'),  -- Paul Coogan: Economic Development Incentives [ALL_SOURCES_COMPOSED]
  ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Paul Coogan: Growth and Development Pace [ALL_SOURCES_COMPOSED]
  ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Paul Coogan: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Paul Coogan: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Paul Coogan: Taxation and Public Spending [ALL_SOURCES_COMPOSED]
  ('5b590765-e701-41cf-b0c3-e7efdeea16d3', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Lisa Gordon: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('5b590765-e701-41cf-b0c3-e7efdeea16d3', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Lisa Gordon: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('5b590765-e701-41cf-b0c3-e7efdeea16d3', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Lisa Gordon: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('5b590765-e701-41cf-b0c3-e7efdeea16d3', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Lisa Gordon: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('72dd5219-490f-48bb-986e-183a6098d602', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'),  -- Matt Pierce: Same-Sex Marriage [SOLE_SOURCED_COMPOSED]
  ('b3231976-f6f0-4f7f-960e-4ba5cdac9700', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Becky Grossman: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f', '4559b513-0fd8-4ed1-babd-f3b554162f40'),  -- Alex Padilla: Data Center Development & Energy Costs [SOLE_SOURCED_COMPOSED]
  ('fbec8ba0-4a3c-4704-b4a5-9cddc42a3635', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Andrea Kelley: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('fbec8ba0-4a3c-4704-b4a5-9cddc42a3635', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Andrea Kelley: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Josh Krintzman: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Josh Krintzman: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('b39524df-ef91-48dc-a1a8-1880c271bd7c', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Brian Livingston: Residential Zoning [SOLE_SOURCED_COMPOSED]
  ('780b7f22-755a-4a92-8bd3-78978edbc564', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Eddie Cawlfield: Growth and Development Pace [SOLE_SOURCED_COMPOSED]
  ('c36e6f78-4828-49cd-9010-988c8a7c7be4', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Andy Hopkins: Growth and Development Pace [SOLE_SOURCED_COMPOSED]
  ('3e616ef8-0ca7-4171-8d73-2cbb61d696f6', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Baine Brooks: Affordable Housing [SOLE_SOURCED_COMPOSED]
  ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Amir Omar: Taxation and Public Spending [SOLE_SOURCED_COMPOSED]
  ('b39524df-ef91-48dc-a1a8-1880c271bd7c', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Brian Livingston: Affordable Housing [SOLE_SOURCED_COMPOSED]
  ('51060129-8709-451d-90c4-ce03e7fcc788', 'eb3d1247-0de1-4b7f-baec-7259861efd53'),  -- Cliff Ponte: Economic Development Incentives [ALL_SOURCES_COMPOSED]
  ('51060129-8709-451d-90c4-ce03e7fcc788', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Cliff Ponte: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('bc313a82-8b30-4ca7-acdb-47d2cc6906e3', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Allison Leary: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('bc313a82-8b30-4ca7-acdb-47d2cc6906e3', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Allison Leary: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('44a2b39e-4127-446e-adc2-8f48a2e6fdac', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Michelle Dionne: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('44a2b39e-4127-446e-adc2-8f48a2e6fdac', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Michelle Dionne: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('c6a65ddf-9c48-4683-9100-28ce1c9f7983', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- John Oliver: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('e9abe848-ca92-4197-924d-294e7ed92100', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Sean Roche: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('e9abe848-ca92-4197-924d-294e7ed92100', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Sean Roche: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('1a7720f9-49b0-4e5d-a0ec-7fb32fba2c2e', 'eb3d1247-0de1-4b7f-baec-7259861efd53'),  -- Joseph Camara: Economic Development Incentives [ALL_SOURCES_COMPOSED]
  ('8a35fe01-8450-4726-a9b3-b61b7a967475', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Pamela Wright: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('8a35fe01-8450-4726-a9b3-b61b7a967475', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Pamela Wright: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('8a35fe01-8450-4726-a9b3-b61b7a967475', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Pamela Wright: Public Safety Approach [ALL_OTHERS_ALSO_BAD]
  ('558811b6-e13c-4222-8042-0cdfe32cea01', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Shawn Cadime: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('e89e4ae3-b3e4-4f09-8fe4-e3877d24653d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Christopher Peckham: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('e89e4ae3-b3e4-4f09-8fe4-e3877d24653d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Christopher Peckham: Taxation and Public Spending [ALL_SOURCES_COMPOSED]
  ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', '0bc588c6-39e1-4084-b5de-cac909b8b762'),  -- Seth Moulton: Civil Rights and Social Justice [ALL_SOURCES_COMPOSED]
  ('9d34705c-0a66-4c08-8936-7e63629ce435', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- R. Lisle Baker: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('9d34705c-0a66-4c08-8936-7e63629ce435', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- R. Lisle Baker: Public Safety Approach [ALL_OTHERS_ALSO_BAD]
  ('ef936b01-3409-4b17-96ff-48b08c3cfdea', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Martha Bixby: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('ef936b01-3409-4b17-96ff-48b08c3cfdea', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Martha Bixby: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('ef936b01-3409-4b17-96ff-48b08c3cfdea', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Martha Bixby: Public Safety Approach [ALL_OTHERS_ALSO_BAD]
  ('3d68627c-c4cb-44f5-8b13-b48cd0edcd7a', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Maria S. Greenberg: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('3d68627c-c4cb-44f5-8b13-b48cd0edcd7a', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Maria S. Greenberg: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('3d68627c-c4cb-44f5-8b13-b48cd0edcd7a', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Maria S. Greenberg: Public Safety Approach [ALL_OTHERS_ALSO_BAD]
  ('236fb3c1-b473-407f-b8a0-d76039b28087', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Ayah A. Al-Zubi: Climate Change and Environmental Protection [SOLE_SOURCED_COMPOSED]
  ('21e534c8-c0c0-42f5-b52b-5eb2f246d632', '44905f3b-e105-4f6c-afc7-5d223813dbac'),  -- Wes Moore: Deportation Priorities [ALL_SOURCES_COMPOSED]
  ('65bdba41-859d-41ba-bb25-65e8ba50f5ad', '44905f3b-e105-4f6c-afc7-5d223813dbac'),  -- Sergio Munoz: Deportation Priorities [SOLE_SOURCED_COMPOSED]
  ('a9e04e1e-92d4-44e4-a411-b6fe4814290a', '48cc9585-ec22-4f53-8d42-6839828dd36f'),  -- Steve Marshall: State Redistricting and Gerrymandering [SOLE_SOURCED_COMPOSED]
  ('f72689da-fe02-4bdd-977f-bb7760a42fb2', '683c8084-2281-4920-a07c-18439b2dd413'),  -- Deidre M. Henderson: United States Tariff Policy [SOLE_SOURCED_COMPOSED]
  ('3b3b6525-7a40-4d01-a1cb-3270ed166919', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Eric Guerra: Growth and Development Pace [ALL_SOURCES_COMPOSED]
  ('3b3b6525-7a40-4d01-a1cb-3270ed166919', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Eric Guerra: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('3b3b6525-7a40-4d01-a1cb-3270ed166919', 'a22215c3-6693-4bc2-b248-01aebba14570'),  -- Eric Guerra: Fossil Fuel Policy [SOLE_SOURCED_COMPOSED]
  ('3b3b6525-7a40-4d01-a1cb-3270ed166919', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Eric Guerra: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('3b3b6525-7a40-4d01-a1cb-3270ed166919', '0bc588c6-39e1-4084-b5de-cac909b8b762'),  -- Eric Guerra: Civil Rights and Social Justice [ALL_SOURCES_COMPOSED]
  ('b9c5dd29-eeb5-4903-af31-d4ab09041b0a', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Jared Nicholson: Residential Zoning [ALL_SOURCES_COMPOSED]
  ('b9c5dd29-eeb5-4903-af31-d4ab09041b0a', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Jared Nicholson: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('66c3bd97-94d1-4287-b1b8-86605a38cb97', '87d20824-a6e9-407b-983c-65440084a0ab'),  -- Tina Kotek: Social Security [SOLE_SOURCED_COMPOSED]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'eb3d1247-0de1-4b7f-baec-7259861efd53'),  -- Val Hoyle: Economic Development Incentives [SOLE_SOURCED_COMPOSED]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', '44905f3b-e105-4f6c-afc7-5d223813dbac'),  -- Val Hoyle: Deportation Priorities [SOLE_SOURCED_COMPOSED]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),  -- Val Hoyle: Healthcare Access [SOLE_SOURCED_COMPOSED]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),  -- Val Hoyle: Medicare / Medicaid [SOLE_SOURCED_COMPOSED]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', '87d20824-a6e9-407b-983c-65440084a0ab'),  -- Val Hoyle: Social Security [SOLE_SOURCED_COMPOSED]
  ('6d30fb7c-99cb-4705-86bc-c3d13ffd44d4', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Brian M. Field: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('6d30fb7c-99cb-4705-86bc-c3d13ffd44d4', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Brian M. Field: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('a24baf50-54d3-4319-9bfb-f354c3f5ca03', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Brian P. LaPierre: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('a24baf50-54d3-4319-9bfb-f354c3f5ca03', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Brian P. LaPierre: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Nicole D. McClain: Residential Zoning [ALL_SOURCES_COMPOSED]
  ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Nicole D. McClain: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Nicole D. McClain: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('ddb4ff9a-d17a-4db7-9d70-b326aaf72e05', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Hong L. Net: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('ddb4ff9a-d17a-4db7-9d70-b326aaf72e05', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Hong L. Net: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Lester Friedman: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Lester Friedman: Residential Zoning [ALL_SOURCES_COMPOSED]
  ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),  -- Lester Friedman: Homelessness Response [ALL_SOURCES_COMPOSED]
  ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Lester Friedman: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Lester Friedman: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Lester Friedman: Transportation Priorities [ALL_SOURCES_COMPOSED]
  ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Lester Friedman: Taxation and Public Spending [ALL_SOURCES_COMPOSED]
  ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Lester Friedman: Growth and Development Pace [ALL_SOURCES_COMPOSED]
  ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Lester Friedman: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('1221c215-2b80-46f7-b980-c04f25c5866f', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Craig A. Corman: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('1221c215-2b80-46f7-b980-c04f25c5866f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Craig A. Corman: Residential Zoning [ALL_SOURCES_COMPOSED]
  ('1221c215-2b80-46f7-b980-c04f25c5866f', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),  -- Craig A. Corman: Homelessness Response [ALL_SOURCES_COMPOSED]
  ('1221c215-2b80-46f7-b980-c04f25c5866f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Craig A. Corman: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('1221c215-2b80-46f7-b980-c04f25c5866f', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Craig A. Corman: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('1221c215-2b80-46f7-b980-c04f25c5866f', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Craig A. Corman: Transportation Priorities [ALL_SOURCES_COMPOSED]
  ('1221c215-2b80-46f7-b980-c04f25c5866f', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Craig A. Corman: Taxation and Public Spending [ALL_SOURCES_COMPOSED]
  ('34ef5b52-ee2c-436f-93c6-110f286cc2bf', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),  -- Ellis Raskin: Rent Regulation [SOLE_SOURCED_COMPOSED]
  ('34ef5b52-ee2c-436f-93c6-110f286cc2bf', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Ellis Raskin: Public Safety Approach [SOLE_SOURCED_COMPOSED]
  ('30f6667d-a88b-46e4-91d8-678130ae37b6', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- John A. Mirisch: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('30f6667d-a88b-46e4-91d8-678130ae37b6', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- John A. Mirisch: Residential Zoning [ALL_SOURCES_COMPOSED]
  ('30f6667d-a88b-46e4-91d8-678130ae37b6', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),  -- John A. Mirisch: Homelessness Response [ALL_SOURCES_COMPOSED]
  ('30f6667d-a88b-46e4-91d8-678130ae37b6', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- John A. Mirisch: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('30f6667d-a88b-46e4-91d8-678130ae37b6', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- John A. Mirisch: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('30f6667d-a88b-46e4-91d8-678130ae37b6', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- John A. Mirisch: Transportation Priorities [ALL_SOURCES_COMPOSED]
  ('30f6667d-a88b-46e4-91d8-678130ae37b6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- John A. Mirisch: Taxation and Public Spending [ALL_SOURCES_COMPOSED]
  ('30f6667d-a88b-46e4-91d8-678130ae37b6', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- John A. Mirisch: Growth and Development Pace [ALL_SOURCES_COMPOSED]
  ('30f6667d-a88b-46e4-91d8-678130ae37b6', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- John A. Mirisch: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('30f6667d-a88b-46e4-91d8-678130ae37b6', '92730f69-ae57-401c-8ad1-2d07834a895d'),  -- John A. Mirisch: Campaign Finance Reform [ALL_SOURCES_COMPOSED]
  ('30f6667d-a88b-46e4-91d8-678130ae37b6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- John A. Mirisch: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('ee18fc57-9d65-4f6a-a376-035539ff3e79', '0bc588c6-39e1-4084-b5de-cac909b8b762'),  -- Ryan Reyna: Civil Rights and Social Justice [SOLE_SOURCED_COMPOSED]
  ('a0e4e813-6c10-45d8-8f59-f444c6747b61', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),  -- William Francis Galvin: Healthcare Access [ALL_SOURCES_COMPOSED]
  ('a0e4e813-6c10-45d8-8f59-f444c6747b61', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'),  -- William Francis Galvin: Same-Sex Marriage [ALL_SOURCES_COMPOSED]
  ('a0e4e813-6c10-45d8-8f59-f444c6747b61', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- William Francis Galvin: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('15c27efb-0402-4a3a-bfad-9df152874046', '666bf03d-81fc-4138-ab15-69ae734c9023'),  -- Tricia Farley-Bouvier: Artificial Intelligence Oversight [ALL_OTHERS_ALSO_BAD]
  ('756298b0-4628-408a-8568-6e8369425569', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Anthony LaFauci: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('f617fda8-15c7-47d6-8fbf-0a39e6db3071', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Caren Dunn: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('c526a928-ab27-424f-a809-c6ed26bf26d3', '0bc588c6-39e1-4084-b5de-cac909b8b762'),  -- Sharona R. Nazarian: Civil Rights and Social Justice [ALL_SOURCES_COMPOSED]
  ('c526a928-ab27-424f-a809-c6ed26bf26d3', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Sharona R. Nazarian: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('c526a928-ab27-424f-a809-c6ed26bf26d3', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Sharona R. Nazarian: Residential Zoning [ALL_SOURCES_COMPOSED]
  ('e45d22f7-fdac-436a-8923-3cbfc4a77bd3', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Bill Hanley: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('c526a928-ab27-424f-a809-c6ed26bf26d3', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),  -- Sharona R. Nazarian: Homelessness Response [ALL_SOURCES_COMPOSED]
  ('c526a928-ab27-424f-a809-c6ed26bf26d3', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Sharona R. Nazarian: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('c526a928-ab27-424f-a809-c6ed26bf26d3', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Sharona R. Nazarian: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('c526a928-ab27-424f-a809-c6ed26bf26d3', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Sharona R. Nazarian: Taxation and Public Spending [ALL_SOURCES_COMPOSED]
  ('f4eabcb1-33d0-4150-a2de-597014f1186b', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Ian Abreu: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('4b0e72f4-15f8-495a-b90a-e5b8b987cd63', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Shane Burgo: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('9b6c7f25-b1dc-42ab-84d1-83d0728014ec', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- John McLaughlin: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('97a9f873-8af9-41a2-a62f-3ad3952459bd', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Joseph LaCava: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('4870519a-0d42-435c-8574-c72669fe8090', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Sean Durkee: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('b4f9688b-add0-44d6-bab8-e923d17d105e', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Mary N. Wells: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('b4f9688b-add0-44d6-bab8-e923d17d105e', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'),  -- Mary N. Wells: Residential Zoning [ALL_SOURCES_COMPOSED]
  ('b4f9688b-add0-44d6-bab8-e923d17d105e', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),  -- Mary N. Wells: Homelessness Response [ALL_SOURCES_COMPOSED]
  ('b4f9688b-add0-44d6-bab8-e923d17d105e', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Mary N. Wells: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('c2eac407-10ce-4f4e-8796-1acb3feb42ac', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Erik R. Gitschier: Affordable Housing [ALL_OTHERS_ALSO_BAD]
  ('b4f9688b-add0-44d6-bab8-e923d17d105e', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Mary N. Wells: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('b4f9688b-add0-44d6-bab8-e923d17d105e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Mary N. Wells: Taxation and Public Spending [ALL_SOURCES_COMPOSED]
  ('b4f9688b-add0-44d6-bab8-e923d17d105e', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Mary N. Wells: Growth and Development Pace [ALL_SOURCES_COMPOSED]
  ('9c64b145-cce4-4b31-a4e0-c041a12af62b', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Marc C. Laredo: Environmental Protection vs. Development [ALL_OTHERS_ALSO_BAD]
  ('9c64b145-cce4-4b31-a4e0-c041a12af62b', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Marc C. Laredo: Climate Change and Environmental Protection [ALL_OTHERS_ALSO_BAD]
  ('9c64b145-cce4-4b31-a4e0-c041a12af62b', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Marc C. Laredo: Public Safety Approach [ALL_OTHERS_ALSO_BAD]
  ('773aa577-9e09-4721-80ee-6219edb151e7', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Susan Albright: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('773aa577-9e09-4721-80ee-6219edb151e7', '1935979c-b290-42e4-baa5-8cb0138b4ffa'),  -- Susan Albright: Environmental Protection vs. Development [ALL_SOURCES_COMPOSED]
  ('773aa577-9e09-4721-80ee-6219edb151e7', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Susan Albright: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('773aa577-9e09-4721-80ee-6219edb151e7', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Susan Albright: Transportation Priorities [ALL_SOURCES_COMPOSED]
  ('773aa577-9e09-4721-80ee-6219edb151e7', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Susan Albright: Public Safety Approach [ALL_SOURCES_COMPOSED]
  ('773aa577-9e09-4721-80ee-6219edb151e7', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Susan Albright: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('978a43f2-f384-48aa-8e93-9784a3e5fdd0', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Naomi Carney: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('9a4c4152-70f4-4056-be19-9ff3236e060d', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Brian Gomes: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('9a4c4152-70f4-4056-be19-9ff3236e060d', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),  -- Brian Gomes: Rent Regulation [ALL_SOURCES_COMPOSED]
  ('73a11a8c-6b57-4803-b786-961e83705fd8', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- James Roy: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('a6006e68-1607-4fe5-9346-27abe389c7f4', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Paul Katz: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('96a1408d-dc35-406d-a1cb-7730dc24b658', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Cathyann Harris: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('84ca82d9-c7be-47de-8f5a-61221dbb08b8', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Robert Logan: Affordable Housing [ALL_SOURCES_COMPOSED]
  ('b4f9688b-add0-44d6-bab8-e923d17d105e', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Mary N. Wells: Transportation Priorities [ALL_SOURCES_COMPOSED]
  ('6d7a04e3-28c9-4e04-a6ec-855a096323ba', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Cathy Warner: Transportation Priorities [SOLE_SOURCED_COMPOSED]
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99', '6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Carlos A. Gimenez: Religious Freedom [SOLE_SOURCED_COMPOSED]
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'),  -- Carlos A. Gimenez: Transgender Athletes [SOLE_SOURCED_COMPOSED]
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),  -- Carlos A. Gimenez: Medicare / Medicaid [ALL_SOURCES_COMPOSED]
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99', '87d20824-a6e9-407b-983c-65440084a0ab'),  -- Carlos A. Gimenez: Social Security [ALL_SOURCES_COMPOSED]
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99', '666bf03d-81fc-4138-ab15-69ae734c9023'),  -- Carlos A. Gimenez: Artificial Intelligence Oversight [SOLE_SOURCED_COMPOSED]
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99', '0bc588c6-39e1-4084-b5de-cac909b8b762'),  -- Carlos A. Gimenez: Civil Rights and Social Justice [SOLE_SOURCED_COMPOSED]
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Carlos A. Gimenez: Affordable Housing [SOLE_SOURCED_COMPOSED]
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99', '92730f69-ae57-401c-8ad1-2d07834a895d'),  -- Carlos A. Gimenez: Campaign Finance Reform [SOLE_SOURCED_COMPOSED]
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99', '48cc9585-ec22-4f53-8d42-6839828dd36f'),  -- Carlos A. Gimenez: State Redistricting and Gerrymandering [SOLE_SOURCED_COMPOSED]
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99', '00b95a6a-75db-4521-b523-3326bba938de'),  -- Carlos A. Gimenez: School Vouchers & Public Education Funding [SOLE_SOURCED_COMPOSED]
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99', 'c1ac1330-47f7-44ec-baf3-c913d926b97c'),  -- Carlos A. Gimenez: Childcare Affordability & Access [SOLE_SOURCED_COMPOSED]
  ('44e1f38c-a135-41db-a96a-b67412e246e8', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),  -- Wendy Davis: Healthcare Access [SOLE_SOURCED_COMPOSED]
  ('44e1f38c-a135-41db-a96a-b67412e246e8', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),  -- Wendy Davis: Medicare / Medicaid [SOLE_SOURCED_COMPOSED]
  ('44e1f38c-a135-41db-a96a-b67412e246e8', '00b95a6a-75db-4521-b523-3326bba938de'),  -- Wendy Davis: School Vouchers & Public Education Funding [ALL_SOURCES_COMPOSED]
  ('44e1f38c-a135-41db-a96a-b67412e246e8', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Wendy Davis: Affordable Housing [SOLE_SOURCED_COMPOSED]
  ('44e1f38c-a135-41db-a96a-b67412e246e8', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Wendy Davis: Taxation and Public Spending [ALL_SOURCES_COMPOSED]
  ('44e1f38c-a135-41db-a96a-b67412e246e8', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Wendy Davis: Climate Change and Environmental Protection [ALL_SOURCES_COMPOSED]
  ('44e1f38c-a135-41db-a96a-b67412e246e8', 'a22215c3-6693-4bc2-b248-01aebba14570'),  -- Wendy Davis: Fossil Fuel Policy [ALL_SOURCES_COMPOSED]
  ('44e1f38c-a135-41db-a96a-b67412e246e8', '44905f3b-e105-4f6c-afc7-5d223813dbac'),  -- Wendy Davis: Deportation Priorities [ALL_SOURCES_COMPOSED]
  ('44e1f38c-a135-41db-a96a-b67412e246e8', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Wendy Davis: Local Immigration Enforcement [ALL_SOURCES_COMPOSED]
  ('44e1f38c-a135-41db-a96a-b67412e246e8', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Wendy Davis: Transportation Priorities [SOLE_SOURCED_COMPOSED]
  ('44e1f38c-a135-41db-a96a-b67412e246e8', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),  -- Wendy Davis: Growth and Development Pace [SOLE_SOURCED_COMPOSED]
  ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),  -- Erin Jemison: Healthcare Access [SOLE_SOURCED_COMPOSED]
  ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4', '00b95a6a-75db-4521-b523-3326bba938de'),  -- Erin Jemison: School Vouchers & Public Education Funding [SOLE_SOURCED_COMPOSED]
  ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4', '48cc9585-ec22-4f53-8d42-6839828dd36f'),  -- Erin Jemison: State Redistricting and Gerrymandering [SOLE_SOURCED_COMPOSED]
  ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'),  -- Erin Jemison: Voting Rights and Electoral Integrity [SOLE_SOURCED_COMPOSED]
  ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Erin Jemison: Climate Change and Environmental Protection [SOLE_SOURCED_COMPOSED]
  ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Erin Jemison: Taxation and Public Spending [SOLE_SOURCED_COMPOSED]
  ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4', 'c1ac1330-47f7-44ec-baf3-c913d926b97c'),  -- Erin Jemison: Childcare Affordability & Access [SOLE_SOURCED_COMPOSED]
  ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),  -- Erin Jemison: Jail Capacity and Incarceration Alternatives [SOLE_SOURCED_COMPOSED]
  ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'),  -- Erin Jemison: Public Safety Approach [SOLE_SOURCED_COMPOSED]
  ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4', '4e2c69ce-591e-4197-9cd5-7aceff79d390'),  -- Erin Jemison: Immigration and Treatment of Immigrants [SOLE_SOURCED_COMPOSED]
  ('6e5d3005-07e5-4c57-a3e0-033a2b17bbdc', 'eb3d1247-0de1-4b7f-baec-7259861efd53'),  -- Richard J. Loa: Economic Development Incentives [ALL_OTHERS_ALSO_BAD]
  ('92d68971-8cc2-480b-8e29-9938f7a280f1', '4938766b-b45a-46e3-93bd-b8b30651271a'),  -- Hector Sosa: Criminalization of Homelessness [SOLE_SOURCED_COMPOSED]
  ('92d68971-8cc2-480b-8e29-9938f7a280f1', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),  -- Hector Sosa: Homelessness Response [SOLE_SOURCED_COMPOSED]
  ('92d68971-8cc2-480b-8e29-9938f7a280f1', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Hector Sosa: Local Immigration Enforcement [SOLE_SOURCED_COMPOSED]
  ('71c35909-e5b5-40ca-883f-21af5c287b5e', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Dorothy Pemberton: Local Immigration Enforcement [SOLE_SOURCED_COMPOSED]
  ('13dc32dd-fac5-440d-9f10-f1f1892acf68', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'),  -- Horacio Ortiz: Local Immigration Enforcement [SOLE_SOURCED_COMPOSED]
  ('a1d5e9fa-1b1a-4a25-b698-21032b43fe6d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Joseph Cinquemani: Taxation and Public Spending [SOLE_SOURCED_COMPOSED]
  ('a1d5e9fa-1b1a-4a25-b698-21032b43fe6d', 'a22215c3-6693-4bc2-b248-01aebba14570'),  -- Joseph Cinquemani: Fossil Fuel Policy [SOLE_SOURCED_COMPOSED]
  ('a1d5e9fa-1b1a-4a25-b698-21032b43fe6d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),  -- Joseph Cinquemani: Healthcare Access [SOLE_SOURCED_COMPOSED]
  ('a1d5e9fa-1b1a-4a25-b698-21032b43fe6d', '24e9212c-b011-422a-865c-093e35050901'),  -- Joseph Cinquemani: Ukraine - Russia Conflict [SOLE_SOURCED_COMPOSED]
  ('38aa9579-5fdf-40a5-8f7a-738f16b3d655', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),  -- Rob Harris: Homelessness Response [SOLE_SOURCED_COMPOSED]
  ('b0ff1c08-80fc-4746-a147-fa201f689cce', '0bc588c6-39e1-4084-b5de-cac909b8b762'),  -- Yoshi D. Matthews: Civil Rights and Social Justice [SOLE_SOURCED_COMPOSED]
  ('1c9edb0f-f3b9-480b-b04b-fd20908fcaae', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Blake Miguez: Taxation and Public Spending [SOLE_SOURCED_COMPOSED]
  ('7c8e4442-e13e-485a-8993-b05ca110410d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529')  -- Marco Rubio: Healthcare Access [SOLE_SOURCED_COMPOSED]
;

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    JOIN _retire_1538 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_n <> 209 THEN RAISE EXCEPTION 'expected 209 targeted answers, found % — target set has moved', v_n; END IF;
END $$;

DELETE FROM inform.politician_context c USING _retire_1538 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1538 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

-- 28 politicians are emptied by the retirement. Clear last_stances_researched_at so they
-- read as UNRESEARCHED and resurface, rather than asserting "we looked and found nothing" on the
-- strength of the very pass being corrected (rule from 1494, reaffirmed in 1525).
UPDATE essentials.politicians SET last_stances_researched_at = NULL
 WHERE id IN ('1221c215-2b80-46f7-b980-c04f25c5866f',
               '1a7720f9-49b0-4e5d-a0ec-7fb32fba2c2e',
               '30f6667d-a88b-46e4-91d8-678130ae37b6',
               '3e616ef8-0ca7-4171-8d73-2cbb61d696f6',
               '44a2b39e-4127-446e-adc2-8f48a2e6fdac',
               '4870519a-0d42-435c-8574-c72669fe8090',
               '4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
               '51060129-8709-451d-90c4-ce03e7fcc788',
               '558811b6-e13c-4222-8042-0cdfe32cea01',
               '73a11a8c-6b57-4803-b786-961e83705fd8',
               '756298b0-4628-408a-8568-6e8369425569',
               '84ca82d9-c7be-47de-8f5a-61221dbb08b8',
               '96a1408d-dc35-406d-a1cb-7730dc24b658',
               '978a43f2-f384-48aa-8e93-9784a3e5fdd0',
               '97a9f873-8af9-41a2-a62f-3ad3952459bd',
               '9a4c4152-70f4-4056-be19-9ff3236e060d',
               '9b6c7f25-b1dc-42ab-84d1-83d0728014ec',
               'a1d5e9fa-1b1a-4a25-b698-21032b43fe6d',
               'a6006e68-1607-4fe5-9346-27abe389c7f4',
               'b0ff1c08-80fc-4746-a147-fa201f689cce',
               'b39524df-ef91-48dc-a1a8-1880c271bd7c',
               'b4f9688b-add0-44d6-bab8-e923d17d105e',
               'c526a928-ab27-424f-a809-c6ed26bf26d3',
               'd7479ffb-177a-44cd-aaac-d86d91522fc3',
               'e45d22f7-fdac-436a-8923-3cbfc4a77bd3',
               'e89e4ae3-b3e4-4f09-8fe4-e3877d24653d',
               'f4eabcb1-33d0-4150-a2de-597014f1186b',
               'f617fda8-15c7-47d6-8fbf-0a39e6db3071');

-- ---- strip the composed URL, keep the rest ---------------------------------------------------
-- David Biele / Same-Sex Marriage: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241030235828/https://actonmass.org/legislators/david-biele/']::text[]
 WHERE politician_id = 'f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- David Biele / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241030235828/https://actonmass.org/legislators/david-biele/']::text[]
 WHERE politician_id = 'f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- David Biele / Criminalization of Homelessness: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241030235828/https://actonmass.org/legislators/david-biele/']::text[]
 WHERE politician_id = 'f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
-- Sydney Kamlager-Dove / Voting Rights and Electoral Integrity: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.congress.gov/bill/119th-congress/house-bill/14', 'https://en.wikipedia.org/wiki/John_Lewis_Voting_Rights_Advancement_Act']::text[]
 WHERE politician_id = 'a2c6adc7-7689-49b9-964f-8f2aeb243a83' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Sydney Kamlager-Dove / Ukraine - Russia Conflict: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.congress.gov/bill/118th-congress/house-bill/8035', 'https://en.wikipedia.org/wiki/21st_Century_Peace_through_Strength_Act']::text[]
 WHERE politician_id = 'a2c6adc7-7689-49b9-964f-8f2aeb243a83' AND topic_id = '24e9212c-b011-422a-865c-093e35050901';
-- Eleni Kounalakis / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://sd13.senate.ca.gov/index.php/news/press-release/march-31-2022/acting-governor-eleni-kounalakis-signs-senator-beckers-voter']::text[]
 WHERE politician_id = '03df7cce-7502-4089-acd5-139841002cbe' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Danillo Sena / Same-Sex Marriage: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/193/H2288/Cosponsor']::text[]
 WHERE politician_id = 'f8986c05-2e32-4184-bfb2-9d4c244ffd3a' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Norma Torres / State Redistricting and Gerrymandering: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/House_Administration_Committee', 'https://www.ontheissues.org/CA/Norma_Torres.htm']::text[]
 WHERE politician_id = 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';
-- Norma Torres / Campaign Finance Reform: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/CA/Norma_Torres.htm', 'https://en.wikipedia.org/wiki/DISCLOSE_Act']::text[]
 WHERE politician_id = 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';
-- Norma Torres / Voting Rights and Electoral Integrity: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/CA/Norma_Torres.htm', 'https://en.wikipedia.org/wiki/Norma_Torres']::text[]
 WHERE politician_id = 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Jorge Nuño / City Sanitation and Cleanliness: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-councilmember-district-9']::text[]
 WHERE politician_id = '93613d15-1098-423b-9e18-81f125ac2408' AND topic_id = '7687de4f-4d0b-462a-b803-bdfb23b16b42';
-- Kathryn Barger / Homelessness Response: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]
 WHERE politician_id = '122f1897-2dae-4f21-bee0-1c02c95e9e3a' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
-- Kathryn Barger / Rent Regulation: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]
 WHERE politician_id = '122f1897-2dae-4f21-bee0-1c02c95e9e3a' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
-- Kathryn Barger / Public Safety Approach: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]
 WHERE politician_id = '122f1897-2dae-4f21-bee0-1c02c95e9e3a' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Kathryn Barger / Reproductive Rights and Abortion Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]
 WHERE politician_id = '122f1897-2dae-4f21-bee0-1c02c95e9e3a' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Kathryn Barger / Local Immigration Enforcement: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]
 WHERE politician_id = '122f1897-2dae-4f21-bee0-1c02c95e9e3a' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
-- Kathryn Barger / Criminal Justice Approach: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]
 WHERE politician_id = '122f1897-2dae-4f21-bee0-1c02c95e9e3a' AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336';
-- Kathryn Barger / Transportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Kathryn_Barger']::text[]
 WHERE politician_id = '122f1897-2dae-4f21-bee0-1c02c95e9e3a' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Isabel Piedmont-Smith / Transportation Priorities: drop 1, keep 4
UPDATE inform.politician_context
   SET sources = ARRAY['https://bsquarebulletin.com/bloomington-city-council-district-1-democratic-party-primary-joe-lee-isabel-piedmont-smith/', 'https://bsquarebulletin.com/2020/05/14/bloomington-council-committee-digs-into-road-funding-to-weigh-repaving-of-college-mall-road-against-other-transportation-goals/', 'https://www.idsnews.com/article/2023/08/bloomington-transit-expansion-approved-by-city-council', 'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning']::text[]
 WHERE politician_id = '91f6d45d-5e7e-48f6-aab1-9476d81946b5' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- David R Rollo / Criminalization of Homelessness: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ipm.org/2023-09-14/city-council-rejects-effort-to-prevent-camping-on-sidewalks-streets']::text[]
 WHERE politician_id = '85741f19-1c12-43ad-8504-d615522725d7' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
-- David R Rollo / Public Safety Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://bsquarebulletin.com/2021/08/24/bloomington-city-council-critical-on-first-night-of-2022-budget-hearings-police-parking-sidewalks/', 'https://daverollo.com/issues/']::text[]
 WHERE politician_id = '85741f19-1c12-43ad-8504-d615522725d7' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Michael J. Rodrigues / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MJR0']::text[]
 WHERE politician_id = 'f865995d-ad3a-4d2d-827f-ed8a1a67af18' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Michael J. Rodrigues / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MJR0']::text[]
 WHERE politician_id = 'f865995d-ad3a-4d2d-827f-ed8a1a67af18' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Jeff Cheney / Affordable Housing: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://friscochronicles.com/who-is-jeff-cheney/']::text[]
 WHERE politician_id = 'ac1ed3c9-db6c-4931-bc55-4d53c6c81b35' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Jeff Cheney / Transportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://communityimpact.com/dallas-fort-worth/frisco/government/2025/09/18/frisco-keeps-tax-rate-flat-in-3047m-budget-raises-water-and-sewer-rates/']::text[]
 WHERE politician_id = 'ac1ed3c9-db6c-4931-bc55-4d53c6c81b35' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Marissa Roy / Criminal Justice Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://patch.com/california/los-angeles/meet-marissa-roy-candidate-los-angeles-city-attorney', 'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney']::text[]
 WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336';
-- Marissa Roy / Police Accountability: drop 1, keep 3
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.spna-dtla.org/blog/la-city-attorney-race-4-candidates-their-views', 'https://patch.com/california/los-angeles/meet-marissa-roy-candidate-los-angeles-city-attorney', 'https://www.aol.com/news/guide-l-city-attorneys-race-100000010.html']::text[]
 WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = '7bad33eb-e93e-4d94-8822-97212d49bde5';
-- Marissa Roy / Access to Justice: drop 1, keep 3
UPDATE inform.politician_context
   SET sources = ARRAY['https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney', 'https://patch.com/california/los-angeles/meet-marissa-roy-candidate-los-angeles-city-attorney', 'https://www.marissaroy.com/']::text[]
 WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = '9d45acaf-1ba4-4cb8-95e1-5ed985223b91';
-- Marissa Roy / Judicial & Prosecutorial Discretion: drop 1, keep 3
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.marissaroy.com/', 'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney', 'https://patch.com/california/los-angeles/meet-marissa-roy-candidate-los-angeles-city-attorney']::text[]
 WHERE politician_id = '7157dd95-0f1b-4e05-bd4f-39317345b47c' AND topic_id = 'e5e48f0e-8f3a-40e1-8080-889fea389603';
-- Paul Coogan / Residential Zoning: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.heraldnews.com/story/news/local/2022/08/10/fall-river-zoning-development-mayor-coogan/7811234001/']::text[]
 WHERE politician_id = 'c62e5d6a-0115-4f2d-9084-b0c3980e6db4' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
-- Shirley N. Weber / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.sos.ca.gov/administration/about']::text[]
 WHERE politician_id = '4ba62f32-dd20-48ce-8d84-d09bb129ad59' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Traci Park / Childcare Affordability & Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://tracipark.com/supporting-women-in-business-leadership/']::text[]
 WHERE politician_id = 'd0977350-df68-4cfe-822e-816ba13f9213' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Brooke Lierman / Taxation and Public Spending: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Brooke_Lierman', 'https://marylandmatters.org/brooke-lierman-taxes/']::text[]
 WHERE politician_id = 'b26fb5d2-90eb-4108-8ce5-838df719473d' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Micah Beckwith / Childcare Affordability & Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.heraldbulletin.com/news/anderson-child-care-director-lt-gov-beckwith-called-struggling-parents-deadbeats/article_76dce2ba-e272-44cd-abf3-e7be602f5e1f.html']::text[]
 WHERE politician_id = '929346a2-8037-4b14-af33-4820eb365323' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Gavin Newsom / Artificial Intelligence Oversight: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.npr.org/2024/09/20/nx-s1-5119792/newsom-ai-bill-california-sb1047-tech', 'https://calmatters.org/politics/2026/04/newsom-moves-for-california-ai-startups/']::text[]
 WHERE politician_id = 'f26309c8-2525-49b2-bdaf-62980cbb1853' AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';
-- Fiona Ma / Deportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://fionama.com/state-fiscal-officers-icluding-fiona-ma-cpa-push-back-a-letter-to-trump-on-the-economic-toll-of-ice-enforcement/']::text[]
 WHERE politician_id = '41ef8aaa-b604-4725-b46d-dab1656cc198' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
-- Jeff Gonzalez / Deportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ognsc.com/smallwood-cuevas-town-hall-warns-ice-risks-extend-beyond-immigrants/']::text[]
 WHERE politician_id = '5ad32852-789e-4013-995b-6f0aa6a5a5d4' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
-- Nelson Grande / Homelessness Response: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://thelalocal.org/government/election/voter-guide-la-district-1/']::text[]
 WHERE politician_id = '15cb5825-649a-4cc5-b14b-ccd4b4402c87' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
-- Nelson Grande / Public Safety Approach: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://thelalocal.org/government/election/voter-guide-la-district-1/']::text[]
 WHERE politician_id = '15cb5825-649a-4cc5-b14b-ccd4b4402c87' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Nelson Grande / Criminalization of Homelessness: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://thelalocal.org/government/election/voter-guide-la-district-1/']::text[]
 WHERE politician_id = '15cb5825-649a-4cc5-b14b-ccd4b4402c87' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
-- Nelson Grande / Local Immigration Enforcement: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.theeastsiderla.com/news/government_and_politics/nelson-grande-l-a-city-council-district-1-candidate/article_bd020452-5e48-46be-91da-0afca58d764d.html']::text[]
 WHERE politician_id = '15cb5825-649a-4cc5-b14b-ccd4b4402c87' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
-- Nelson Grande / Affordable Housing: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://thelalocal.org/government/election/voter-guide-la-district-1/']::text[]
 WHERE politician_id = '15cb5825-649a-4cc5-b14b-ccd4b4402c87' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Nelson Grande / Economic Development Incentives: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.theeastsiderla.com/news/government_and_politics/nelson-grande-l-a-city-council-district-1-candidate/article_bd020452-5e48-46be-91da-0afca58d764d.html']::text[]
 WHERE politician_id = '15cb5825-649a-4cc5-b14b-ccd4b4402c87' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Aruna Miller / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller']::text[]
 WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Jasmeet Kaur Bains / Civil Rights and Social Justice: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maria_Elena_Durazo']::text[]
 WHERE politician_id = '539874fc-489f-4643-9b1a-923aca6cc2c1' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Hilda L. Solis / Childcare Affordability & Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.hildasolis.com/2022/jobs/', 'https://www.ontheissues.org/Hilda_Solis.htm']::text[]
 WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Justin Beller / Residential Zoning: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2021/07/08/meet-mckinneys-newest-city-council-members-justin-beller-and-gere-feltus/']::text[]
 WHERE politician_id = 'bcdbeae4-04c9-4ea1-8942-bac3ce1a8723' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
-- David F. Bristol / Public Safety Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://davidfbristol.com/', 'https://starlocalmedia.com/checkout/prosper/news/three-takeaways-from-prosper-mayor-david-bristol-s-state-of-the-community-address/article_40b622fa-cad1-11ee-ab28-67360121190b.html']::text[]
 WHERE politician_id = 'd65e3760-95f3-4ad5-ba29-be01a76ae23b' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Sydney Kamlager-Dove / Public Safety Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202120220AB118', 'https://www.congress.gov/bill/117th-congress/house-bill/7120']::text[]
 WHERE politician_id = 'a2c6adc7-7689-49b9-964f-8f2aeb243a83' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Gavin Newsom / Economic Development Incentives: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Governor/Gavin_Newsom_Budget_+_Economy.htm', 'https://calmatters.org/politics/2026/05/gavin-newsom-final-budget-plan/']::text[]
 WHERE politician_id = 'f26309c8-2525-49b2-bdaf-62980cbb1853' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Norma Torres / Misinformation and the Role of Algorithms in Democracy: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/House_Administration_Committee', 'https://en.wikipedia.org/wiki/New_Democrat_Coalition']::text[]
 WHERE politician_id = 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';
-- Patricia D. Jehlen / Reproductive Rights and Abortion Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/191/S2090']::text[]
 WHERE politician_id = 'd40a0eda-36fc-4032-8382-20c76a36d6a6' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Paul R. Feeney / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/PRF0']::text[]
 WHERE politician_id = 'c435ab14-5d64-46e4-a59f-bba18ed483c9' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Patricia D. Jehlen / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0']::text[]
 WHERE politician_id = 'd40a0eda-36fc-4032-8382-20c76a36d6a6' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Patricia D. Jehlen / Rent Regulation: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0']::text[]
 WHERE politician_id = 'd40a0eda-36fc-4032-8382-20c76a36d6a6' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
-- Patricia D. Jehlen / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0']::text[]
 WHERE politician_id = 'd40a0eda-36fc-4032-8382-20c76a36d6a6' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Patricia D. Jehlen / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/PDJ0']::text[]
 WHERE politician_id = 'd40a0eda-36fc-4032-8382-20c76a36d6a6' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- William N. Brownsberger / Public Safety Approach: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/WNB0']::text[]
 WHERE politician_id = '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- William N. Brownsberger / Criminal Justice Approach: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/190/S2185']::text[]
 WHERE politician_id = '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7' AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336';
-- William N. Brownsberger / Bail and Pretrial Decisions: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/190/S2185']::text[]
 WHERE politician_id = '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7' AND topic_id = '1fab5edf-6151-4da0-9704-a7f2113ba54c';
-- William N. Brownsberger / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/WNB0']::text[]
 WHERE politician_id = '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- William N. Brownsberger / Transportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/WNB0']::text[]
 WHERE politician_id = '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- William N. Brownsberger / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/WNB0']::text[]
 WHERE politician_id = '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Edward J. Markey / Climate Change and Environmental Protection: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Ed_Markey', 'https://www.ontheissues.org/Senate/Ed_Markey.htm']::text[]
 WHERE politician_id = 'faf86b5b-5add-4afb-a8e2-96b3e8be4b78' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Ayanna Pressley / Reproductive Rights and Abortion Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h346', 'https://www.naral.org/scorecards/']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Ayanna Pressley / Campaign Finance Reform: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.opensecrets.org/members-of-congress/ayanna-pressley/summary?cid=N00044039', 'https://www.govtrack.us/congress/votes/116-2019/h118']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';
-- Ayanna Pressley / Childcare Affordability & Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://congress.gov/bill/117th-congress/house-bill/1876', 'https://www.govtrack.us/congress/votes/117-2021/h369']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Ayanna Pressley / Civil Rights and Social Justice: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.aclu.org/scorecard', 'https://www.govtrack.us/congress/votes/117-2021/h118']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Ayanna Pressley / Climate Change and Environmental Protection: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://scorecard.lcv.org/moc/ayanna-pressley', 'https://www.govtrack.us/congress/votes/116-2019/h109']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Ayanna Pressley / Deportation Priorities: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://pressley.house.gov/issues/immigration', 'https://breatheact.org/']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
-- Ayanna Pressley / Fossil Fuel Policy: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://scorecard.lcv.org/moc/ayanna-pressley', 'https://congress.gov/bill/116th-congress/house-bill/3671']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Ayanna Pressley / Healthcare Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/bills/116/hr1384', 'https://congress.gov/bill/117th-congress/house-bill/1384']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Ayanna Pressley / Police Accountability: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h118', 'https://breatheact.org/']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = '7bad33eb-e93e-4d94-8822-97212d49bde5';
-- Ayanna Pressley / Medicare / Medicaid: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://congress.gov/bill/117th-congress/house-bill/1384', 'https://www.govtrack.us/congress/votes/117-2022/h373']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';
-- Ayanna Pressley / State Redistricting and Gerrymandering: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/116-2019/h118', 'https://www.govtrack.us/congress/votes/117-2021/h147']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';
-- Ayanna Pressley / Same-Sex Marriage: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2022/h460', 'https://www.hrc.org/resources/congressional-scorecard']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Ayanna Pressley / School Vouchers & Public Education Funding: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://pressley.house.gov/issues/education', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';
-- Ayanna Pressley / Transgender Athletes: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/118-2023/h108', 'https://www.hrc.org/resources/congressional-scorecard']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';
-- Ayanna Pressley / Voting Rights and Electoral Integrity: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h147', 'https://www.govtrack.us/congress/votes/117-2021/h252']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Seth Moulton / Reproductive Rights and Abortion Access: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h346']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Seth Moulton / Campaign Finance Reform: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/116-2019/h118', 'https://www.opensecrets.org/members-of-congress/seth-moulton/summary?cid=N00035492']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';
-- Seth Moulton / Deportation Priorities: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/members/seth_moulton/412595']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
-- Seth Moulton / Healthcare Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20191120204507/https://moulton.house.gov/issues/health-care', 'https://www.govtrack.us/congress/votes/117-2021/h72']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Seth Moulton / Immigration and Treatment of Immigrants: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/116-2019/h358']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Seth Moulton / Jail Capacity and Incarceration Alternatives: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/116-2019/h656', 'https://congress.gov/member/seth-moulton/M001196']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0';
-- Seth Moulton / Medicare / Medicaid: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20191120204507/https://moulton.house.gov/issues/health-care', 'https://www.govtrack.us/congress/votes/117-2022/h373']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';
-- Seth Moulton / State Redistricting and Gerrymandering: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/116-2019/h118', 'https://www.govtrack.us/congress/votes/117-2021/h147']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';
-- Seth Moulton / Religious Freedom: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h185']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';
-- Seth Moulton / Same-Sex Marriage: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2022/h460', 'https://www.hrc.org/resources/congressional-scorecard']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Seth Moulton / School Vouchers & Public Education Funding: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20220928161759/https://moulton.house.gov/issues/education', 'https://www.govtrack.us/congress/bills/116/hconres14']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';
-- Seth Moulton / Social Security: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20191120195210/https://moulton.house.gov/issues/seniors', 'https://congress.gov/bill/117th-congress/house-bill/4583']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = '87d20824-a6e9-407b-983c-65440084a0ab';
-- Seth Moulton / United States Tariff Policy: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/116-2020/h9', 'https://congress.gov/member/seth-moulton/M001196']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = '683c8084-2281-4920-a07c-18439b2dd413';
-- Seth Moulton / Taxation and Public Spending: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/115-2017/h637']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Seth Moulton / Transgender Athletes: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.nbcnews.com/politics/2020-election/moulton-transgender-athletes-women-sports-n1070441']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';
-- Seth Moulton / Ukraine - Russia Conflict: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2022/h111', 'https://armedservices.house.gov/press-releases/moulton-ukraine']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = '24e9212c-b011-422a-865c-093e35050901';
-- Seth Moulton / Voting Rights and Electoral Integrity: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h147', 'https://www.govtrack.us/congress/votes/117-2021/h252']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Stephen Lynch / Campaign Finance Reform: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.opensecrets.org/members-of-congress/stephen-lynch/summary?cid=N00013620', 'https://www.govtrack.us/congress/votes/116-2019/h118']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';
-- Stephen Lynch / Civil Rights and Social Justice: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.aclu.org/scorecard', 'https://www.govtrack.us/congress/votes/117-2021/h118']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Stephen Lynch / Climate Change and Environmental Protection: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2022/h373']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Stephen Lynch / Fossil Fuel Policy: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2022/h373']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Stephen Lynch / Healthcare Access: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/111-2010/h165']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Stephen Lynch / Same-Sex Marriage: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2022/h460', 'https://www.ontheissues.org/MA/Steve_Lynch.htm']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Stephen Lynch / United States Tariff Policy: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/116-2020/h9']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = '683c8084-2281-4920-a07c-18439b2dd413';
-- Stephen Lynch / Taxation and Public Spending: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/115-2017/h637']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Stephen Lynch / Ukraine - Russia Conflict: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2022/h111', 'https://congress.gov/member/stephen-lynch/L000562']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = '24e9212c-b011-422a-865c-093e35050901';
-- Stephen Lynch / Voting Rights and Electoral Integrity: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h147', 'https://congress.gov/member/stephen-lynch/L000562']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- R. Lisle Baker / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://law.suffolk.edu/faculty-research/faculty-profiles/r-lisle-baker/']::text[]
 WHERE politician_id = '9d34705c-0a66-4c08-8936-7e63629ce435' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- R. Lisle Baker / Residential Zoning: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://law.suffolk.edu/faculty-research/faculty-profiles/r-lisle-baker/']::text[]
 WHERE politician_id = '9d34705c-0a66-4c08-8936-7e63629ce435' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
-- R. Lisle Baker / Environmental Protection vs. Development: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://law.suffolk.edu/faculty-research/faculty-profiles/r-lisle-baker/']::text[]
 WHERE politician_id = '9d34705c-0a66-4c08-8936-7e63629ce435' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa';
-- R. Lisle Baker / Growth and Development Pace: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://law.suffolk.edu/faculty-research/faculty-profiles/r-lisle-baker/']::text[]
 WHERE politician_id = '9d34705c-0a66-4c08-8936-7e63629ce435' AND topic_id = 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
-- Kim Driscoll / Reproductive Rights and Abortion Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.wbur.org/news/2022/09/06/2022-massachusetts-democratic-lieutenant-governor-primary-result']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Kim Driscoll / Civil Rights and Social Justice: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Kim Driscoll / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Kim Driscoll / Fossil Fuel Policy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Kim Driscoll / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Kim Driscoll / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Kim Driscoll / Deportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
-- Kim Driscoll / Same-Sex Marriage: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Karen E. Spilka / Reproductive Rights and Abortion Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/KES0']::text[]
 WHERE politician_id = '167d272b-fc1b-4a72-a44d-dfa1a9a42fcf' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Karen E. Spilka / Childcare Affordability & Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/KES0']::text[]
 WHERE politician_id = '167d272b-fc1b-4a72-a44d-dfa1a9a42fcf' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Karen E. Spilka / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/KES0']::text[]
 WHERE politician_id = '167d272b-fc1b-4a72-a44d-dfa1a9a42fcf' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Karen E. Spilka / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/KES0']::text[]
 WHERE politician_id = '167d272b-fc1b-4a72-a44d-dfa1a9a42fcf' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Karen E. Spilka / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2545']::text[]
 WHERE politician_id = '167d272b-fc1b-4a72-a44d-dfa1a9a42fcf' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Lydia M. Edwards / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/LME0']::text[]
 WHERE politician_id = '11d73e67-bcd9-419a-8b0d-a26447eb0c0b' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Lydia M. Edwards / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2745']::text[]
 WHERE politician_id = '11d73e67-bcd9-419a-8b0d-a26447eb0c0b' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Lydia M. Edwards / Deportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/LME0']::text[]
 WHERE politician_id = '11d73e67-bcd9-419a-8b0d-a26447eb0c0b' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
-- Lydia M. Edwards / Civil Rights and Social Justice: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/LME0']::text[]
 WHERE politician_id = '11d73e67-bcd9-419a-8b0d-a26447eb0c0b' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Lydia M. Edwards / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/LME0']::text[]
 WHERE politician_id = '11d73e67-bcd9-419a-8b0d-a26447eb0c0b' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Jason M. Lewis / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/jml0']::text[]
 WHERE politician_id = 'a40f234e-1790-4b52-8670-090b6379eb03' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Jason M. Lewis / Fossil Fuel Policy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/jml0']::text[]
 WHERE politician_id = 'a40f234e-1790-4b52-8670-090b6379eb03' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Jason M. Lewis / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/jml0']::text[]
 WHERE politician_id = 'a40f234e-1790-4b52-8670-090b6379eb03' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Jason M. Lewis / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = 'a40f234e-1790-4b52-8670-090b6379eb03' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Jason M. Lewis / Childcare Affordability & Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/jml0']::text[]
 WHERE politician_id = 'a40f234e-1790-4b52-8670-090b6379eb03' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Lydia M. Edwards / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = '11d73e67-bcd9-419a-8b0d-a26447eb0c0b' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Joan B. Lovely / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JBL0']::text[]
 WHERE politician_id = '6d8717ca-45f9-42cf-bd28-6786a50d254f' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Joan B. Lovely / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2745']::text[]
 WHERE politician_id = '6d8717ca-45f9-42cf-bd28-6786a50d254f' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Joan B. Lovely / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JBL0']::text[]
 WHERE politician_id = '6d8717ca-45f9-42cf-bd28-6786a50d254f' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Liz Miranda / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0']::text[]
 WHERE politician_id = '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Liz Miranda / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2745']::text[]
 WHERE politician_id = '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Liz Miranda / Deportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0']::text[]
 WHERE politician_id = '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
-- Liz Miranda / Civil Rights and Social Justice: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0']::text[]
 WHERE politician_id = '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Liz Miranda / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0']::text[]
 WHERE politician_id = '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Nick Collins / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/N_C0']::text[]
 WHERE politician_id = '2c53dc2c-38ae-4f39-873d-9ea1841b1c4c' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Nick Collins / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/N_C0']::text[]
 WHERE politician_id = '2c53dc2c-38ae-4f39-873d-9ea1841b1c4c' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Dylan A. Fernandes / Fossil Fuel Policy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/DAF0']::text[]
 WHERE politician_id = '8c7d04dc-f567-4759-b99b-0ae8f26d6f32' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Dylan A. Fernandes / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/DAF0']::text[]
 WHERE politician_id = '8c7d04dc-f567-4759-b99b-0ae8f26d6f32' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Dylan A. Fernandes / Civil Rights and Social Justice: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/DAF0']::text[]
 WHERE politician_id = '8c7d04dc-f567-4759-b99b-0ae8f26d6f32' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Dylan A. Fernandes / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/DAF0']::text[]
 WHERE politician_id = '8c7d04dc-f567-4759-b99b-0ae8f26d6f32' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Julian A. Cyr / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JAC0']::text[]
 WHERE politician_id = 'bd451748-111f-461d-9752-95e7c243769e' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Julian A. Cyr / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JAC0']::text[]
 WHERE politician_id = 'bd451748-111f-461d-9752-95e7c243769e' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Julian A. Cyr / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JAC0']::text[]
 WHERE politician_id = 'bd451748-111f-461d-9752-95e7c243769e' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Julian A. Cyr / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = 'bd451748-111f-461d-9752-95e7c243769e' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Bruce E. Tarr / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/BET0']::text[]
 WHERE politician_id = 'b1bd9a21-a37e-49f4-907b-9fba480a1ca2' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Bruce E. Tarr / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/BET0']::text[]
 WHERE politician_id = 'b1bd9a21-a37e-49f4-907b-9fba480a1ca2' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Bruce E. Tarr / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/BET0']::text[]
 WHERE politician_id = 'b1bd9a21-a37e-49f4-907b-9fba480a1ca2' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Bruce E. Tarr / Fossil Fuel Policy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/BET0']::text[]
 WHERE politician_id = 'b1bd9a21-a37e-49f4-907b-9fba480a1ca2' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Joan B. Lovely / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JBL0']::text[]
 WHERE politician_id = '6d8717ca-45f9-42cf-bd28-6786a50d254f' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Joan B. Lovely / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = '6d8717ca-45f9-42cf-bd28-6786a50d254f' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Brendan P. Crighton / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/BPC0']::text[]
 WHERE politician_id = '99457307-afa4-4045-aebf-06ee8b39d28f' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Brendan P. Crighton / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = '99457307-afa4-4045-aebf-06ee8b39d28f' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Brendan P. Crighton / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/BPC0']::text[]
 WHERE politician_id = '99457307-afa4-4045-aebf-06ee8b39d28f' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- John F. Keenan / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JFK0']::text[]
 WHERE politician_id = '5cd1c798-31dc-4e53-b578-7e2d81378478' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- John F. Keenan / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JFK0']::text[]
 WHERE politician_id = '5cd1c798-31dc-4e53-b578-7e2d81378478' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- William J. Driscoll / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/WJD0']::text[]
 WHERE politician_id = 'ab975fdf-b4f1-4955-94a4-97681a2a8d08' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- William J. Driscoll / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/WJD0']::text[]
 WHERE politician_id = 'ab975fdf-b4f1-4955-94a4-97681a2a8d08' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- William J. Driscoll / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = 'ab975fdf-b4f1-4955-94a4-97681a2a8d08' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Michael D. Brady / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MDB0']::text[]
 WHERE politician_id = '67ea7814-b7aa-42de-aba8-2230c181d15a' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Michael D. Brady / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MDB0']::text[]
 WHERE politician_id = '67ea7814-b7aa-42de-aba8-2230c181d15a' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Michael D. Brady / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MDB0']::text[]
 WHERE politician_id = '67ea7814-b7aa-42de-aba8-2230c181d15a' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Paul R. Feeney / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = 'c435ab14-5d64-46e4-a59f-bba18ed483c9' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Kelly A. Dooner / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/KAD0']::text[]
 WHERE politician_id = '247cf8e5-426a-4104-9027-6a2a0b1b61c9' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Kelly A. Dooner / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/KAD0']::text[]
 WHERE politician_id = '247cf8e5-426a-4104-9027-6a2a0b1b61c9' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Kelly A. Dooner / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = '247cf8e5-426a-4104-9027-6a2a0b1b61c9' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Mark C. Montigny / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MCM0']::text[]
 WHERE politician_id = '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Mark C. Montigny / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MCM0']::text[]
 WHERE politician_id = '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Mark C. Montigny / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MCM0']::text[]
 WHERE politician_id = '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Mark C. Montigny / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Jake Wilson / Deportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/H1266']::text[]
 WHERE politician_id = '41ced04d-7403-4170-a267-c339191e6fcd' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
-- Ronald Mariano / Reproductive Rights and Abortion Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/191/H3320']::text[]
 WHERE politician_id = '5fdefd59-b543-4221-b6ed-b33532f9bd5f' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Ronald Mariano / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/H4264']::text[]
 WHERE politician_id = '5fdefd59-b543-4221-b6ed-b33532f9bd5f' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Ronald Mariano / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/R_M1']::text[]
 WHERE politician_id = '5fdefd59-b543-4221-b6ed-b33532f9bd5f' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Ronald Mariano / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/R_M1']::text[]
 WHERE politician_id = '5fdefd59-b543-4221-b6ed-b33532f9bd5f' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Ronald Mariano / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/R_M1']::text[]
 WHERE politician_id = '5fdefd59-b543-4221-b6ed-b33532f9bd5f' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Jake Wilson / Reproductive Rights and Abortion Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/191/H3320']::text[]
 WHERE politician_id = '41ced04d-7403-4170-a267-c339191e6fcd' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Christopher Hendricks / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20260119052118/https://actonmass.org/legislators/christopher-hendricks/']::text[]
 WHERE politician_id = '9cb46542-a671-4bdd-bfcb-98fc1bc79415' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Christopher Hendricks / Fossil Fuel Policy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20260119052118/https://actonmass.org/legislators/christopher-hendricks/']::text[]
 WHERE politician_id = '9cb46542-a671-4bdd-bfcb-98fc1bc79415' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Sal N. DiDomenico / Childcare Affordability & Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/SND0']::text[]
 WHERE politician_id = 'c7e94dda-1862-40fe-bda5-5fa2fe68f536' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Aruna Miller / Public Safety Approach: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Aruna_Miller']::text[]
 WHERE politician_id = 'ea9fc2d6-3b26-469a-978c-e8c846d2d49a' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Wes Moore / Reproductive Rights and Abortion Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore', 'https://www.marylandmatters.org/2023/04/11/governor-moore-signs-abortion-access-expansion-bill/']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Wes Moore / Climate Change and Environmental Protection: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore', 'https://www.marylandmatters.org/2023/02/climate-solutions-now-act/']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Wes Moore / Healthcare Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/04/healthcare-expansion/']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Wes Moore / Affordable Housing: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2024/05/housing-affordability-act/']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Wes Moore / Taxation and Public Spending: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2024/01/moore-fy2025-budget/']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Wes Moore / Immigration and Treatment of Immigrants: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/05/maryland-way-act-signed/']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Wes Moore / Voting Rights and Electoral Integrity: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/05/voting-rights-maryland/']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Wes Moore / Civil Rights and Social Justice: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Wes Moore / Public Safety Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/public-safety-moore/']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Wes Moore / Economic Development Incentives: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/lead-economic-development/']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Wes Moore / Childcare Affordability & Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/childcare-moore/']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Wes Moore / Fossil Fuel Policy: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore', 'https://marylandmatters.org/2023/moore-clean-energy-buildings/']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Wes Moore / State Redistricting and Gerrymandering: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';
-- Wes Moore / Same-Sex Marriage: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Wes Moore / Transgender Athletes: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';
-- Wes Moore / School Vouchers & Public Education Funding: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';
-- Wes Moore / Criminalization of Homelessness: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Wes_Moore']::text[]
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
-- Adrienne A. Jones / Reproductive Rights and Abortion Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Adrienne A. Jones / Climate Change and Environmental Protection: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Adrienne A. Jones / Healthcare Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Adrienne A. Jones / Voting Rights and Electoral Integrity: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Adrienne A. Jones / Civil Rights and Social Justice: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Adrienne A. Jones / Public Safety Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Adrienne A. Jones / Criminal Justice Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336';
-- Adrienne A. Jones / Taxation and Public Spending: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Adrienne A. Jones / Affordable Housing: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Adrienne A. Jones / Same-Sex Marriage: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Adrienne A. Jones / School Vouchers & Public Education Funding: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';
-- Adrienne A. Jones / Campaign Finance Reform: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';
-- Adrienne A. Jones / Immigration and Treatment of Immigrants: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Adrienne A. Jones / State Redistricting and Gerrymandering: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';
-- Adrienne A. Jones / Childcare Affordability & Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Adrienne A. Jones / Fossil Fuel Policy: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Adrienne A. Jones / Medicare / Medicaid: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';
-- Adrienne A. Jones / Economic Development Incentives: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01', 'https://ballotpedia.org/Adrienne_A._Jones']::text[]
 WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Pete Flores / Fossil Fuel Policy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://senate.texas.gov/member.php?d=24']::text[]
 WHERE politician_id = '29fcdf7e-e3e2-4463-b461-ffd7a34a8754' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Katie Britt / Artificial Intelligence Oversight: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Katie_Britt']::text[]
 WHERE politician_id = '0ba1cecc-8493-495b-8d58-34d50bbacfba' AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';
-- Katie Britt / Healthcare Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Senate/Katie_Britt.htm', 'https://en.wikipedia.org/wiki/Katie_Britt']::text[]
 WHERE politician_id = '0ba1cecc-8493-495b-8d58-34d50bbacfba' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Katie Britt / Medicare / Medicaid: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.britt.senate.gov/issues/fiscal-responsibility/']::text[]
 WHERE politician_id = '0ba1cecc-8493-495b-8d58-34d50bbacfba' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';
-- Katie Britt / Social Security: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.britt.senate.gov/issues/fiscal-responsibility/']::text[]
 WHERE politician_id = '0ba1cecc-8493-495b-8d58-34d50bbacfba' AND topic_id = '87d20824-a6e9-407b-983c-65440084a0ab';
-- Ted Budd / Fossil Fuel Policy: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://budd.senate.gov/2024/01/24/budd-leads-colleagues-to-introduce-strategically-lowering-gas-prices-act/', 'https://budd.senate.gov/2024/01/26/budd-joins-coalition-blasting-biden-for-pausing-lng-permits/']::text[]
 WHERE politician_id = '401f1fab-c996-4b1a-92f7-2817c5dd4619' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Ted Budd / School Vouchers & Public Education Funding: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://budd.senate.gov/2023/01/27/budd-sponsors-a-plus-act/', 'https://www.ontheissues.org/Senate/Ted_Budd.htm']::text[]
 WHERE politician_id = '401f1fab-c996-4b1a-92f7-2817c5dd4619' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';
-- Wray Wade / Growth and Development Pace: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.longviewtexas.gov/AgendaCenter/ViewFile/Minutes/_04092026-2237']::text[]
 WHERE politician_id = 'ae9c740d-5910-414c-aa3d-7e9bf374a9b7' AND topic_id = 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
-- Wray Wade / Transportation Priorities: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.longviewtexas.gov/2204/District-3---Wray-Wade', 'https://www.longviewtexas.gov/AgendaCenter/ViewFile/Minutes/_04092026-2237']::text[]
 WHERE politician_id = 'ae9c740d-5910-414c-aa3d-7e9bf374a9b7' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Ben Ray Luján / Civil Rights and Social Justice: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Senate/Ben_Ray_Lujan.htm']::text[]
 WHERE politician_id = '27d57833-842f-427c-bedd-aa1695fe550f' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Ben Ray Luján / Same-Sex Marriage: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Senate/Ben_Ray_Lujan.htm']::text[]
 WHERE politician_id = '27d57833-842f-427c-bedd-aa1695fe550f' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Ben Ray Luján / Transgender Athletes: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Senate/Ben_Ray_Lujan.htm']::text[]
 WHERE politician_id = '27d57833-842f-427c-bedd-aa1695fe550f' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';
-- John Hickenlooper / Artificial Intelligence Oversight: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/John_Hickenlooper.htm']::text[]
 WHERE politician_id = '2a6693c7-9149-4e71-85fe-003746f7d23d' AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';
-- Jesse Clingan / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.somervillema.gov/somervision']::text[]
 WHERE politician_id = '13f3e9dc-67fc-4115-99a5-77c4647f1b3c' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Ben Ray Luján / Religious Freedom: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Senate/Ben_Ray_Lujan.htm']::text[]
 WHERE politician_id = '27d57833-842f-427c-bedd-aa1695fe550f' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';
-- Steve Marshall / Reproductive Rights and Abortion Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm']::text[]
 WHERE politician_id = 'a9e04e1e-92d4-44e4-a411-b6fe4814290a' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Steve Marshall / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm']::text[]
 WHERE politician_id = 'a9e04e1e-92d4-44e4-a411-b6fe4814290a' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Steve Marshall / Civil Rights and Social Justice: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm']::text[]
 WHERE politician_id = 'a9e04e1e-92d4-44e4-a411-b6fe4814290a' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Steve Marshall / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Senate/Steve_Marshall.htm']::text[]
 WHERE politician_id = 'a9e04e1e-92d4-44e4-a411-b6fe4814290a' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Jackie Fielder / Economic Development Incentives: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://missionlocal.org/2025/10/s-f-has-a-plan-for-a-public-bank-one-supervisor-wants-to-act-on-it/', 'https://www.sf.gov/profile--jackie-fielder/']::text[]
 WHERE politician_id = '02f88a57-ccf5-4fe1-a693-7fc949321fb1' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Jackie Fielder / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://missionlocal.org/2025/07/district-9-supervisor-jackie-fielder/']::text[]
 WHERE politician_id = '02f88a57-ccf5-4fe1-a693-7fc949321fb1' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Matt Mahan / State Redistricting and Gerrymandering: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan']::text[]
 WHERE politician_id = '41949a2b-563a-4608-91c6-951c63252a91' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';
-- Matt Mahan / Local Immigration Enforcement: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://calmatters.org/immigration/']::text[]
 WHERE politician_id = '41949a2b-563a-4608-91c6-951c63252a91' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
-- Matt Mahan / Transportation Priorities: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Matt_Mahan', 'https://www.vta.org/']::text[]
 WHERE politician_id = '41949a2b-563a-4608-91c6-951c63252a91' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Deidre M. Henderson / Voting Rights and Electoral Integrity: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ksltv.com/local-news/fear-sells-facts-are-boring-utah-lt-gov-henderson-defends-election-security/906208/', 'https://www.sltrib.com/opinion/letters/2026/02/26/letter-lt-gov-henderson-leads-way/']::text[]
 WHERE politician_id = 'f72689da-fe02-4bdd-977f-bb7760a42fb2' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Ann Millner / School Vouchers & Public Education Funding: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://le.utah.gov/~2023/bills/static/HB0215.html']::text[]
 WHERE politician_id = '8aeb0ff5-e0b0-4933-8e97-5be1339e4729' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';
-- Ann Millner / Medicare / Medicaid: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://le.utah.gov/~2025/bills/static/HB0324.html']::text[]
 WHERE politician_id = '8aeb0ff5-e0b0-4933-8e97-5be1339e4729' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';
-- Dea Theodore / Public Safety Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.fox13now.com/news/politics/salt-lake-county-council-passes-sales-tax-increase-for-transportation-public-safety', 'https://www.saltlakecounty.gov/council/contact/dea-theodore/']::text[]
 WHERE politician_id = 'dd90ac18-7613-4a2f-bfc1-2eddfebb4daf' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Dea Theodore / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://slco.legistar.com/PersonDetail.aspx?ID=248314&GUID=F2511035-39F3-4926-8CB0-FA303038663E']::text[]
 WHERE politician_id = 'dd90ac18-7613-4a2f-bfc1-2eddfebb4daf' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Jenny Wilson / Local Immigration Enforcement: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.saltlakecounty.gov/newsroom/mayor-jenny-wilson-opposes-proposed-ice-detention-facility-in-utah--news/']::text[]
 WHERE politician_id = '1e25123b-7f6c-47c3-b597-bbd626c185ae' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
-- Jenny Wilson / Economic Development Incentives: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20250513180522/https://www.saltlakecounty.gov/newsroom/secc-salt-palace-land-sale-release/', 'https://www.utahbusiness.com/press-releases/2025/05/02/salt-lake-county-sale-downtown-property-economic-growth-revitalize-urban-core-capital-city-smith-entertainment-group/']::text[]
 WHERE politician_id = '1e25123b-7f6c-47c3-b597-bbd626c185ae' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Jenny Wilson / Public Safety Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://utahnewsdispatch.com/2024/10/25/republicans-democrats-urge-support-of-507-million-jail-bond/', 'https://www.deseret.com/utah/2025/02/12/salt-lake-county-council-approves-new-sales-tax-to-fund-jail-transportation-improvements/']::text[]
 WHERE politician_id = '1e25123b-7f6c-47c3-b597-bbd626c185ae' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Eric Guerra / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.sacramentocityexpress.com/2025/01/29/city-of-sacramento-reaffirms-commitment-to-sanctuary-city-policies/']::text[]
 WHERE politician_id = '3b3b6525-7a40-4d01-a1cb-3270ed166919' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Eric Guerra / Criminalization of Homelessness: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.sacramentocityexpress.com/2025/01/15/new-shelter-and-service-campus-for-people-experiencing-homelessness-opens-in-south-sacramento/']::text[]
 WHERE politician_id = '3b3b6525-7a40-4d01-a1cb-3270ed166919' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
-- Eric Guerra / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://sacramento.newsreview.com/2020/04/01/innovation-without-gentrification/']::text[]
 WHERE politician_id = '3b3b6525-7a40-4d01-a1cb-3270ed166919' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Eric Guerra / Transportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.sacramentocityexpress.com/2025/03/city-adopts-plan-to-improve-walking-biking-and-public-transit-access/']::text[]
 WHERE politician_id = '3b3b6525-7a40-4d01-a1cb-3270ed166919' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Eric Guerra / Environmental Protection vs. Development: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://sacramento.newsreview.com/2020/04/01/innovation-without-gentrification/']::text[]
 WHERE politician_id = '3b3b6525-7a40-4d01-a1cb-3270ed166919' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa';
-- Rick Jennings II / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://sacramentocityexpress.com/2025/03/19/city-receives-1-68-million-cannabis-equity-grant-from-state/']::text[]
 WHERE politician_id = 'f20601e0-0728-4c33-803c-28c88e170286' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Arthur Ellis / Reproductive Rights and Abortion Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Arthur Ellis / Civil Rights and Social Justice: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Arthur Ellis / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Arthur Ellis / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Arthur Ellis / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Arthur Ellis / Environmental Protection vs. Development: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa';
-- Arthur Ellis / Fossil Fuel Policy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Arthur Ellis / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Arthur Ellis / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Arthur Ellis / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Arthur Ellis / School Vouchers & Public Education Funding: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';
-- Arthur Ellis / Childcare Affordability & Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Arthur Ellis / Same-Sex Marriage: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Arthur Ellis / Public Safety Approach: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Arthur Ellis / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
 WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Michelle Kaufusi / Affordable Housing: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.kuer.org/politics-government/2025-10-13/kaufusi-judkins-parse-budgets-public-safety-at-provo-mayoral-candidate-forum', 'https://www.sltrib.com/news/2025/10/15/provo-election-2025-michelle/']::text[]
 WHERE politician_id = 'abf34eb9-8b81-4c9f-8db6-25ba036419c9' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Michele Botelho / Transgender Athletes: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://michelebotelhoforcongress.com/about']::text[]
 WHERE politician_id = 'c6af7e50-b937-4c1e-b397-ac2606d39b7f' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';
-- Andre V. Johnson, Jr. / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]
 WHERE politician_id = 'b592e432-6411-48b3-bca3-d5596d0d81e9' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Abigail Spanberger / Reproductive Rights and Abortion Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Abigail_Spanberger', 'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]
 WHERE politician_id = '46c6ebb0-137a-46aa-b6fa-17af31aa4ef1' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Abigail Spanberger / Climate Change and Environmental Protection: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Abigail_Spanberger', 'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]
 WHERE politician_id = '46c6ebb0-137a-46aa-b6fa-17af31aa4ef1' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Abigail Spanberger / Data Center Development & Energy Costs: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Abigail_Spanberger']::text[]
 WHERE politician_id = '46c6ebb0-137a-46aa-b6fa-17af31aa4ef1' AND topic_id = '4559b513-0fd8-4ed1-babd-f3b554162f40';
-- Abigail Spanberger / Growth and Development Pace: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Abigail_Spanberger', 'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]
 WHERE politician_id = '46c6ebb0-137a-46aa-b6fa-17af31aa4ef1' AND topic_id = 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
-- Abigail Spanberger / Affordable Housing: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Abigail_Spanberger', 'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]
 WHERE politician_id = '46c6ebb0-137a-46aa-b6fa-17af31aa4ef1' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Abigail Spanberger / School Vouchers & Public Education Funding: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Abigail_Spanberger', 'https://ontheissues.org/VA/Abigail_Spanberger.htm']::text[]
 WHERE politician_id = '46c6ebb0-137a-46aa-b6fa-17af31aa4ef1' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';
-- Ghazala Hashmi / Reproductive Rights and Abortion Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?241+sum+SJ0002', 'https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Ghazala Hashmi / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Ghazala Hashmi / Civil Rights and Social Justice: drop 1, keep 3
UPDATE inform.politician_context
   SET sources = ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?201+sum+HB1049', 'https://lis.virginia.gov/cgi-bin/legp604.exe?201+sum+SJ0001', 'https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Ghazala Hashmi / Same-Sex Marriage: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?201+sum+SJ0029', 'https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Ghazala Hashmi / Transgender Athletes: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?221+sum+SB0766', 'https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';
-- Ghazala Hashmi / School Vouchers & Public Education Funding: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?231+sum+HB1508', 'https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';
-- Ghazala Hashmi / Childcare Affordability & Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Ghazala Hashmi / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Ghazala Hashmi / Deportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
-- Ghazala Hashmi / Climate Change and Environmental Protection: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?201+sum+SB0851', 'https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Ghazala Hashmi / Fossil Fuel Policy: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?201+sum+SB0851', 'https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Ghazala Hashmi / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Ghazala Hashmi / State Redistricting and Gerrymandering: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://lis.virginia.gov/cgi-bin/legp604.exe?201+sum+SJ0018', 'https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';
-- Ghazala Hashmi / Campaign Finance Reform: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';
-- Ghazala Hashmi / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Ghazala Hashmi / Public Safety Approach: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Ghazala Hashmi / Criminal Justice Approach: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336';
-- Ghazala Hashmi / Police Accountability: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = '7bad33eb-e93e-4d94-8822-97212d49bde5';
-- Ghazala Hashmi / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Ghazala Hashmi / Religious Freedom: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';
-- Ghazala Hashmi / Medicare / Medicaid: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';
-- Ghazala Hashmi / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]
 WHERE politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Maura Healey / Reproductive Rights and Abortion Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.ontheissues.org/Maura_Healey.htm']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Maura Healey / Artificial Intelligence Oversight: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';
-- Maura Healey / Childcare Affordability & Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Maura Healey / Civil Rights and Social Justice: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.ontheissues.org/Maura_Healey.htm']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Maura Healey / Climate Change and Environmental Protection: drop 2, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.ontheissues.org/Maura_Healey.htm']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Maura Healey / Data Center Development & Energy Costs: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = '4559b513-0fd8-4ed1-babd-f3b554162f40';
-- Maura Healey / Deportation Priorities: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.ontheissues.org/Maura_Healey.htm']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
-- Maura Healey / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Maura Healey / Fossil Fuel Policy: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.ontheissues.org/Maura_Healey.htm']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Maura Healey / Growth and Development Pace: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
-- Maura Healey / Healthcare Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.ontheissues.org/Maura_Healey.htm']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Maura Healey / Criminalization of Homelessness: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
-- Maura Healey / Homelessness Response: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.mass.gov/orgs/executive-office-of-housing-and-livable-communities']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
-- Maura Healey / Affordable Housing: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Maura Healey / Immigration and Treatment of Immigrants: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.ontheissues.org/Maura_Healey.htm']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Maura Healey / Local Immigration Enforcement: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
-- Maura Healey / Medicare / Medicaid: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.ontheissues.org/Maura_Healey.htm']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';
-- Maura Healey / Rent Regulation: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
-- Maura Healey / Residential Zoning: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
-- Maura Healey / Same-Sex Marriage: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.ontheissues.org/Maura_Healey.htm']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Maura Healey / United States Tariff Policy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = '683c8084-2281-4920-a07c-18439b2dd413';
-- Maura Healey / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Maura Healey / Transgender Athletes: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.ontheissues.org/Maura_Healey.htm']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';
-- Maura Healey / Transportation Priorities: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.mass.gov/orgs/massachusetts-bay-transportation-authority', 'https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Maura Healey / Ukraine - Russia Conflict: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = '24e9212c-b011-422a-865c-093e35050901';
-- Maura Healey / Voting Rights and Electoral Integrity: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Maura_Healey', 'https://www.ontheissues.org/Maura_Healey.htm']::text[]
 WHERE politician_id = '7cf1080e-6e7e-4f5b-be00-6fb170896a7c' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Kim Driscoll / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Kim Driscoll / Environmental Protection vs. Development: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa';
-- Kim Driscoll / Local Immigration Enforcement: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
-- Kim Driscoll / Medicare / Medicaid: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';
-- Kim Driscoll / Residential Zoning: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
-- Kim Driscoll / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Kim Driscoll / Transgender Athletes: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';
-- Kim Driscoll / Transportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Kim_Driscoll']::text[]
 WHERE politician_id = 'e687c089-f00d-464c-aa37-3b021a3aba2c' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- William Francis Galvin / Misinformation and the Role of Algorithms in Democracy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.sec.state.ma.us/ele/elepdf/2022-election-information.pdf']::text[]
 WHERE politician_id = 'a0e4e813-6c10-45d8-8f59-f444c6747b61' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';
-- Elizabeth Warren / Data Center Development & Energy Costs: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]
 WHERE politician_id = 'dd08c9de-076d-40ee-ab27-9298bbb72d1a' AND topic_id = '4559b513-0fd8-4ed1-babd-f3b554162f40';
-- Elizabeth Warren / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]
 WHERE politician_id = 'dd08c9de-076d-40ee-ab27-9298bbb72d1a' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Elizabeth Warren / Judicial & Prosecutorial Discretion: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]
 WHERE politician_id = 'dd08c9de-076d-40ee-ab27-9298bbb72d1a' AND topic_id = 'e5e48f0e-8f3a-40e1-8080-889fea389603';
-- Elizabeth Warren / Rent Regulation: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Elizabeth_Warren.htm']::text[]
 WHERE politician_id = 'dd08c9de-076d-40ee-ab27-9298bbb72d1a' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
-- Elizabeth Warren / Residential Zoning: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Political_positions_of_Elizabeth_Warren']::text[]
 WHERE politician_id = 'dd08c9de-076d-40ee-ab27-9298bbb72d1a' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
-- Edward J. Markey / Data Center Development & Energy Costs: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.markey.senate.gov/news/press-releases/senators-markey-booker-introduce-algorithmic-accountability-act', 'https://en.wikipedia.org/wiki/Ed_Markey']::text[]
 WHERE politician_id = 'faf86b5b-5add-4afb-a8e2-96b3e8be4b78' AND topic_id = '4559b513-0fd8-4ed1-babd-f3b554162f40';
-- Edward J. Markey / Fossil Fuel Policy: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Senate/Ed_Markey.htm', 'https://en.wikipedia.org/wiki/Ed_Markey']::text[]
 WHERE politician_id = 'faf86b5b-5add-4afb-a8e2-96b3e8be4b78' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Richard Neal / Data Center Development & Energy Costs: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Richard_Neal']::text[]
 WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id = '4559b513-0fd8-4ed1-babd-f3b554162f40';
-- Richard Neal / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Richard_Neal']::text[]
 WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Richard Neal / Growth and Development Pace: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Richard_Neal']::text[]
 WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id = 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
-- Richard Neal / Criminalization of Homelessness: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]
 WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
-- Richard Neal / Homelessness Response: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]
 WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
-- Richard Neal / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]
 WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Richard Neal / Judicial & Prosecutorial Discretion: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Richard_Neal']::text[]
 WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id = 'e5e48f0e-8f3a-40e1-8080-889fea389603';
-- Richard Neal / Transparency in Legal Proceedings: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Richard_Neal']::text[]
 WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id = '6674d87e-999d-433a-aab7-3f626f59fd5f';
-- Richard Neal / Misinformation and the Role of Algorithms in Democracy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Richard_Neal']::text[]
 WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';
-- Richard Neal / Rent Regulation: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/ma/Richard_Neal.htm']::text[]
 WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
-- Richard Neal / Residential Zoning: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Richard_Neal']::text[]
 WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
-- Richard Neal / Transportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Richard_Neal']::text[]
 WHERE politician_id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Seth Moulton / Artificial Intelligence Oversight: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://armedservices.house.gov/press-releases/moulton-ai-defense', 'https://www.congress.gov/member/seth-moulton/M001196']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';
-- Seth Moulton / Childcare Affordability & Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h369', 'https://congress.gov/bill/117th-congress/house-bill/4346']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Seth Moulton / Economic Development Incentives: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h395', 'https://congress.gov/bill/117th-congress/house-bill/4346']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Seth Moulton / Criminalization of Homelessness: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h72', 'https://congress.gov/member/seth-moulton/M001196']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
-- Seth Moulton / Public Safety Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h118', 'https://www.nbcnews.com/politics/politics-news/moulton-defund-police-n1234567']::text[]
 WHERE politician_id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Ayanna Pressley / Artificial Intelligence Oversight: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://congress.gov/bill/117th-congress/house-bill/3907', 'https://www.govtrack.us/congress/members/ayanna_pressley/412786']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';
-- Ayanna Pressley / Environmental Protection vs. Development: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://congress.gov/bill/117th-congress/house-bill/2021', 'https://scorecard.lcv.org/moc/ayanna-pressley']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa';
-- Ayanna Pressley / Misinformation and the Role of Algorithms in Democracy: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://congress.gov/member/ayanna-pressley/P000617', 'https://www.govtrack.us/congress/votes/117-2021/h268']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';
-- Ayanna Pressley / Public Safety Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://breatheact.org/', 'https://www.govtrack.us/congress/votes/117-2021/h118']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Ayanna Pressley / Religious Freedom: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h185', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';
-- Ayanna Pressley / United States Tariff Policy: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/116-2020/h9', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = '683c8084-2281-4920-a07c-18439b2dd413';
-- Ayanna Pressley / Ukraine - Russia Conflict: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2022/h111', 'https://congress.gov/member/ayanna-pressley/P000617']::text[]
 WHERE politician_id = 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id = '24e9212c-b011-422a-865c-093e35050901';
-- Stephen Lynch / Childcare Affordability & Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h369', 'https://congress.gov/member/stephen-lynch/L000562']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Stephen Lynch / Economic Development Incentives: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h395', 'https://congress.gov/member/stephen-lynch/L000562']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Stephen Lynch / Criminalization of Homelessness: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://congress.gov/member/stephen-lynch/L000562', 'https://www.govtrack.us/congress/votes/117-2021/h72']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';
-- Stephen Lynch / Affordable Housing: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h369', 'https://congress.gov/member/stephen-lynch/L000562']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Stephen Lynch / Jail Capacity and Incarceration Alternatives: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/116-2019/h656', 'https://congress.gov/member/stephen-lynch/L000562']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0';
-- Stephen Lynch / Medicare / Medicaid: drop 2, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2022/h373']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';
-- Stephen Lynch / Public Safety Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h118', 'https://congress.gov/member/stephen-lynch/L000562']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Stephen Lynch / Religious Freedom: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20201028031400/https://lynch.house.gov/issues', 'https://www.ontheissues.org/MA/Steve_Lynch.htm']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';
-- Stephen Lynch / Transgender Athletes: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/118-2023/h108', 'https://congress.gov/member/stephen-lynch/L000562']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';
-- Stephen Lynch / Transportation Priorities: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.govtrack.us/congress/votes/117-2021/h369', 'https://congress.gov/member/stephen-lynch/L000562']::text[]
 WHERE politician_id = '62b453da-3dea-4177-82ba-9e4b78eb7691' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- John C. Velis / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JCV0']::text[]
 WHERE politician_id = '973d60e2-fca7-4185-bd2a-84a686e925ab' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Bruce E. Tarr / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/BET0']::text[]
 WHERE politician_id = 'b1bd9a21-a37e-49f4-907b-9fba480a1ca2' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Bruce E. Tarr / State Redistricting and Gerrymandering: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/BET0']::text[]
 WHERE politician_id = 'b1bd9a21-a37e-49f4-907b-9fba480a1ca2' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';
-- Bruce E. Tarr / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = 'b1bd9a21-a37e-49f4-907b-9fba480a1ca2' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Bruce E. Tarr / Transportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/BET0']::text[]
 WHERE politician_id = 'b1bd9a21-a37e-49f4-907b-9fba480a1ca2' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Joan B. Lovely / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JBL0']::text[]
 WHERE politician_id = '6d8717ca-45f9-42cf-bd28-6786a50d254f' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Joan B. Lovely / Childcare Affordability & Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JBL0']::text[]
 WHERE politician_id = '6d8717ca-45f9-42cf-bd28-6786a50d254f' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Jason M. Lewis / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/jml0']::text[]
 WHERE politician_id = 'a40f234e-1790-4b52-8670-090b6379eb03' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Jason M. Lewis / Public Safety Approach: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/191/S2800']::text[]
 WHERE politician_id = 'a40f234e-1790-4b52-8670-090b6379eb03' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Jason M. Lewis / Transportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/jml0']::text[]
 WHERE politician_id = 'a40f234e-1790-4b52-8670-090b6379eb03' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Lydia M. Edwards / Rent Regulation: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/LME0']::text[]
 WHERE politician_id = '11d73e67-bcd9-419a-8b0d-a26447eb0c0b' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
-- Lydia M. Edwards / Transportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/LME0']::text[]
 WHERE politician_id = '11d73e67-bcd9-419a-8b0d-a26447eb0c0b' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Sal N. DiDomenico / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/SND0']::text[]
 WHERE politician_id = 'c7e94dda-1862-40fe-bda5-5fa2fe68f536' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Sal N. DiDomenico / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/SND0']::text[]
 WHERE politician_id = 'c7e94dda-1862-40fe-bda5-5fa2fe68f536' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Sal N. DiDomenico / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/SND0']::text[]
 WHERE politician_id = 'c7e94dda-1862-40fe-bda5-5fa2fe68f536' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Sal N. DiDomenico / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = 'c7e94dda-1862-40fe-bda5-5fa2fe68f536' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Liz Miranda / Public Safety Approach: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0']::text[]
 WHERE politician_id = '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Liz Miranda / Rent Regulation: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0']::text[]
 WHERE politician_id = '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
-- Liz Miranda / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0']::text[]
 WHERE politician_id = '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Nick Collins / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/N_C0']::text[]
 WHERE politician_id = '2c53dc2c-38ae-4f39-873d-9ea1841b1c4c' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Nick Collins / Transportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/N_C0']::text[]
 WHERE politician_id = '2c53dc2c-38ae-4f39-873d-9ea1841b1c4c' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Patrick M. O'Connor / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/PMO']::text[]
 WHERE politician_id = 'e1f72270-5809-4d0e-969c-48d1ab34fbdc' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Patrick M. O'Connor / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/PMO']::text[]
 WHERE politician_id = 'e1f72270-5809-4d0e-969c-48d1ab34fbdc' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Patrick M. O'Connor / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = 'e1f72270-5809-4d0e-969c-48d1ab34fbdc' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- John F. Keenan / Transportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JFK0']::text[]
 WHERE politician_id = '5cd1c798-31dc-4e53-b578-7e2d81378478' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- John F. Keenan / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JFK0']::text[]
 WHERE politician_id = '5cd1c798-31dc-4e53-b578-7e2d81378478' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Michael D. Brady / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MDB0']::text[]
 WHERE politician_id = '67ea7814-b7aa-42de-aba8-2230c181d15a' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Paul R. Feeney / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/PRF0']::text[]
 WHERE politician_id = 'c435ab14-5d64-46e4-a59f-bba18ed483c9' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Paul R. Feeney / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/PRF0']::text[]
 WHERE politician_id = 'c435ab14-5d64-46e4-a59f-bba18ed483c9' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Michael J. Rodrigues / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MJR0']::text[]
 WHERE politician_id = 'f865995d-ad3a-4d2d-827f-ed8a1a67af18' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Michael J. Rodrigues / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MJR0']::text[]
 WHERE politician_id = 'f865995d-ad3a-4d2d-827f-ed8a1a67af18' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Michael J. Rodrigues / Transportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MJR0']::text[]
 WHERE politician_id = 'f865995d-ad3a-4d2d-827f-ed8a1a67af18' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Mark C. Montigny / Environmental Protection vs. Development: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MCM0']::text[]
 WHERE politician_id = '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa';
-- Mark C. Montigny / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MCM0']::text[]
 WHERE politician_id = '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Dylan A. Fernandes / Environmental Protection vs. Development: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/DAF0']::text[]
 WHERE politician_id = '8c7d04dc-f567-4759-b99b-0ae8f26d6f32' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa';
-- Dylan A. Fernandes / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/192/S2294']::text[]
 WHERE politician_id = '8c7d04dc-f567-4759-b99b-0ae8f26d6f32' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Julian A. Cyr / Environmental Protection vs. Development: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/JAC0']::text[]
 WHERE politician_id = 'bd451748-111f-461d-9752-95e7c243769e' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa';
-- Hadley Luddy / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/H_L1']::text[]
 WHERE politician_id = '03e35156-c179-4dd5-9c8c-8d418976914e' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Thomas W. Moakley / Childcare Affordability & Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/TWM1']::text[]
 WHERE politician_id = '35cf0880-be86-45bb-97e9-4ef2097feba1' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Leigh S. Davis / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/LSD1']::text[]
 WHERE politician_id = 'ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Michael S. Chaisson / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MSC1']::text[]
 WHERE politician_id = '69a4aaa2-5265-45e0-87c7-8cea22b2dc18' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Lisa M. Field / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/LMF1']::text[]
 WHERE politician_id = 'acf7819a-3e36-4d17-8828-3238adb894b0' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Lisa M. Field / Childcare Affordability & Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/LMF1']::text[]
 WHERE politician_id = 'acf7819a-3e36-4d17-8828-3238adb894b0' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Justin Thurber / Climate Change and Environmental Protection: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/J_T2', 'https://malegislature.gov/Bills/194/H3574']::text[]
 WHERE politician_id = 'a485b386-65a5-4c6c-aaa1-a441facd45fc' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Steven J. Ouellette / Artificial Intelligence Oversight: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/SJO1']::text[]
 WHERE politician_id = 'a4e6e14a-46f7-4574-94c6-5b7edd484d91' AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';
-- Mark D. Sylvia / Climate Change and Environmental Protection: drop 1, keep 3
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/MDS1', 'https://malegislature.gov/Bills/194/H450', 'https://malegislature.gov/Bills/194/H3256']::text[]
 WHERE politician_id = '8658e02a-1456-45ba-96bb-19ff438d8e1b' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Christopher Hendricks / School Vouchers & Public Education Funding: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20260119052118/https://actonmass.org/legislators/christopher-hendricks/']::text[]
 WHERE politician_id = '9cb46542-a671-4bdd-bfcb-98fc1bc79415' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';
-- Christopher Hendricks / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20260119052118/https://actonmass.org/legislators/christopher-hendricks/']::text[]
 WHERE politician_id = '9cb46542-a671-4bdd-bfcb-98fc1bc79415' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Christopher Hendricks / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20260119052118/https://actonmass.org/legislators/christopher-hendricks/']::text[]
 WHERE politician_id = '9cb46542-a671-4bdd-bfcb-98fc1bc79415' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Christopher Hendricks / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20260119052118/https://actonmass.org/legislators/christopher-hendricks/']::text[]
 WHERE politician_id = '9cb46542-a671-4bdd-bfcb-98fc1bc79415' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Tram T. Nguyen / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/TTN1']::text[]
 WHERE politician_id = 'fc1d7143-1be8-49b0-be31-6dbc5874230d' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Tram T. Nguyen / Local Immigration Enforcement: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/TTN1']::text[]
 WHERE politician_id = 'fc1d7143-1be8-49b0-be31-6dbc5874230d' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
-- Ronald Mariano / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Legislators/Profile/R_M1']::text[]
 WHERE politician_id = '5fdefd59-b543-4221-b6ed-b33532f9bd5f' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Ronald Mariano / Criminal Justice Approach: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://malegislature.gov/Bills/191/S2700']::text[]
 WHERE politician_id = '5fdefd59-b543-4221-b6ed-b33532f9bd5f' AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336';
-- Jon Mitchell / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Jon_Mitchell_(politician)']::text[]
 WHERE politician_id = '5114097d-c06a-4147-85bc-f9a6646f5c46' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Edward M. Flynn / City Sanitation and Cleanliness: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.wbur.org/news/2023/04/26/boston-rat-czar-ed-flynn-newsletter', 'https://en.wikipedia.org/wiki/Ed_Flynn_(politician)']::text[]
 WHERE politician_id = 'b8c7510c-20d7-4bd7-a765-07b77d3a5b6c' AND topic_id = '7687de4f-4d0b-462a-b803-bdfb23b16b42';
-- Rita Mercier / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.lowellma.gov/council']::text[]
 WHERE politician_id = 'ef52f3fd-dc4d-4a4a-8320-fbae613a4baa' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Corey Robinson / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.lowellma.gov/council']::text[]
 WHERE politician_id = '246e6b71-e8ad-44bb-aa5c-10228d2c056a' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- John Descoteaux / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.lowellma.gov/council']::text[]
 WHERE politician_id = 'b7015fbc-6173-48bc-99ba-d0363b771048' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Shane Burgo / Rent Regulation: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.wbsm.com/search/?s=burgo+rent+stabilization']::text[]
 WHERE politician_id = '4b0e72f4-15f8-495a-b90a-e5b8b987cd63' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
-- Sarah Young / Transportation Priorities: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ksl.com/article/51473126/uta-set-to-extend-s-line-deeper-into-sugar-house-with-resolution-in-place', 'https://sarahforslc.com/issues/']::text[]
 WHERE politician_id = 'c8befa3a-280a-4ad5-af75-d8ca11498222' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Randy Fine / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Randy_Fine']::text[]
 WHERE politician_id = 'a5a58bc3-e654-4a35-8418-84e1ba57506f' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Randy Fine / Fossil Fuel Policy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Randy_Fine']::text[]
 WHERE politician_id = 'a5a58bc3-e654-4a35-8418-84e1ba57506f' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Carlos A. Gimenez / Healthcare Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Carlos_A._Gimenez', 'https://www.ontheissues.org/FL/Carlos_Gimenez.htm']::text[]
 WHERE politician_id = '3030383b-2aaf-40fd-9dfb-8867d1d02f99' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Carlos A. Gimenez / Reproductive Rights and Abortion Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Carlos_A._Gimenez']::text[]
 WHERE politician_id = '3030383b-2aaf-40fd-9dfb-8867d1d02f99' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Carlos A. Gimenez / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/FL/Carlos_Gimenez.htm']::text[]
 WHERE politician_id = '3030383b-2aaf-40fd-9dfb-8867d1d02f99' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Carlos A. Gimenez / Same-Sex Marriage: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Carlos_A._Gimenez']::text[]
 WHERE politician_id = '3030383b-2aaf-40fd-9dfb-8867d1d02f99' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Carlos A. Gimenez / Ukraine - Russia Conflict: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Carlos_A._Gimenez']::text[]
 WHERE politician_id = '3030383b-2aaf-40fd-9dfb-8867d1d02f99' AND topic_id = '24e9212c-b011-422a-865c-093e35050901';
-- Carlos A. Gimenez / Fossil Fuel Policy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.lcv.org/congressional-scorecard/moc/carlos-gimenez']::text[]
 WHERE politician_id = '3030383b-2aaf-40fd-9dfb-8867d1d02f99' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Carlos A. Gimenez / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Carlos_A._Gimenez']::text[]
 WHERE politician_id = '3030383b-2aaf-40fd-9dfb-8867d1d02f99' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Carlos A. Gimenez / Deportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Carlos_A._Gimenez']::text[]
 WHERE politician_id = '3030383b-2aaf-40fd-9dfb-8867d1d02f99' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
-- Carlos A. Gimenez / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.lcv.org/congressional-scorecard/moc/carlos-gimenez']::text[]
 WHERE politician_id = '3030383b-2aaf-40fd-9dfb-8867d1d02f99' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Carlos A. Gimenez / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Carlos_A._Gimenez']::text[]
 WHERE politician_id = '3030383b-2aaf-40fd-9dfb-8867d1d02f99' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Darin LaHood / Same-Sex Marriage: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/IL/Darin_LaHood_Civil_Rights.htm']::text[]
 WHERE politician_id = 'f0d27c86-02f3-4014-9162-e4e940f2afdd' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Wendy Davis / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://wendydavisutah.com/home-wend-davis-utah']::text[]
 WHERE politician_id = '44e1f38c-a135-41db-a96a-b67412e246e8' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Wendy Davis / Homelessness Response: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://wendydavisutah.com/home-wend-davis-utah']::text[]
 WHERE politician_id = '44e1f38c-a135-41db-a96a-b67412e246e8' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
-- Wendy Davis / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://wendydavisutah.com/home-wend-davis-utah']::text[]
 WHERE politician_id = '44e1f38c-a135-41db-a96a-b67412e246e8' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Erin Jemison / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.qsaltlake.com/news/2026/04/20/utah-stonewall-democrats-endorsements/']::text[]
 WHERE politician_id = '0695eddd-6fb4-40f7-8daa-f5d6d10d6db4' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Erin Jemison / Same-Sex Marriage: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.qsaltlake.com/news/2026/04/20/utah-stonewall-democrats-endorsements/']::text[]
 WHERE politician_id = '0695eddd-6fb4-40f7-8daa-f5d6d10d6db4' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';
-- Thomas P. Tiffany / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Tom_Tiffany.htm']::text[]
 WHERE politician_id = 'a8f96324-50ac-4fa1-b57b-47a998306fe8' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Thomas P. Tiffany / Fossil Fuel Policy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Tom_Tiffany']::text[]
 WHERE politician_id = 'a8f96324-50ac-4fa1-b57b-47a998306fe8' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Victor Preciado / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://la.streetsblog.org/2025/11/07/pomona-approves-rent-control']::text[]
 WHERE politician_id = '56cecf7c-6de0-440f-b8e2-34945ec52333' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Victor Preciado / Economic Development Incentives: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20260202082224/https://victorforpomona.com/about-victor/']::text[]
 WHERE politician_id = '56cecf7c-6de0-440f-b8e2-34945ec52333' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Mario Trujillo - / Local Immigration Enforcement: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://thedowneypatriot.com/articles/council-decides-against-stricter-rent-control']::text[]
 WHERE politician_id = '06b1dae6-5fcf-4a1f-ba89-d06cbae5c19d' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
-- Ron DeSantis / Transgender Athletes: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Political_positions_of_Ron_DeSantis']::text[]
 WHERE politician_id = '358d0829-8d2b-46ea-9af2-251f48960014' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';
-- Letitia James / Reproductive Rights and Abortion Access: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Letitia_James', 'https://www.ontheissues.org/Letitia_James.htm']::text[]
 WHERE politician_id = '406dd9be-a751-4685-a946-44806bd01548' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
-- Chris Carr / Deportation Priorities: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://law.georgia.gov/press-releases/2025-04-02/carr-takes-new-action-deport-violent-tren-de-aragua-gang-members']::text[]
 WHERE politician_id = 'd90f754e-c3c6-44f9-890d-a8f2a9a00d22' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';
-- Chris Carr / Immigration and Treatment of Immigrants: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.georgiapol.com/tag/chris-carr/']::text[]
 WHERE politician_id = 'd90f754e-c3c6-44f9-890d-a8f2a9a00d22' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
-- Steve Marshall / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.alabamaag.gov/?s=climate']::text[]
 WHERE politician_id = 'd33b1fb5-bac7-48b9-9628-8169e28f4e16' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Tony Wu / Public Safety Approach: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://wuforwestcovina.com/']::text[]
 WHERE politician_id = '1bb5c062-9b9d-44de-820b-c3efe0d08222' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Nancy Landry / Voting Rights and Electoral Integrity: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20260629201456/https://www.sos.la.gov/ElectionsAndVoting/Vote/Pages/default.aspx']::text[]
 WHERE politician_id = '0ed76bd2-273d-4057-9c4e-4259d6cb9ebc' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Phil McGrane / Voting Rights and Electoral Integrity: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://voteidaho.gov/casting-your-ballot/', 'https://en.wikipedia.org/wiki/Phil_McGrane']::text[]
 WHERE politician_id = 'ade5ce47-25a7-4332-848f-877404875f0e' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
-- Phil McGrane / Misinformation and the Role of Algorithms in Democracy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Phil_McGrane']::text[]
 WHERE politician_id = 'ade5ce47-25a7-4332-848f-877404875f0e' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';
-- Nithya Raman / Local Immigration Enforcement: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.nithyaforthecity.com/issues', 'https://en.wikipedia.org/wiki/Nithya_Raman']::text[]
 WHERE politician_id = '26dbe16a-9dff-42c0-939f-5b5e529063ca' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
-- Nithya Raman / Public Safety Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Nithya_Raman', 'https://www.nithyaforthecity.com/issues']::text[]
 WHERE politician_id = '26dbe16a-9dff-42c0-939f-5b5e529063ca' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Nithya Raman / Rent Regulation: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.nithyaforthecity.com/issues', 'https://en.wikipedia.org/wiki/Nithya_Raman']::text[]
 WHERE politician_id = '26dbe16a-9dff-42c0-939f-5b5e529063ca' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
-- Doris Matsui / Climate Change and Environmental Protection: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/CA/Doris_Matsui.htm', 'https://en.wikipedia.org/wiki/Doris_Matsui']::text[]
 WHERE politician_id = '5be0c642-33b3-4ea4-8bb1-2eb25df2b4ef' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Lou Correa / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/CA/Lou_Correa_Energy_+_Oil.htm']::text[]
 WHERE politician_id = 'c06165d2-008c-4fe3-93cd-e31fbd6e377f' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Chris Rabb / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://en.wikipedia.org/wiki/Chris_Rabb']::text[]
 WHERE politician_id = '013bf70b-627c-4699-b11d-67924e6916a2' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Kathryn Harrington / Local Immigration Enforcement: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.washingtoncountyor.gov/cao/sanctuary-promise-and-immigration-support']::text[]
 WHERE politician_id = '76b00811-8bf8-46c0-bb0c-9867c90fe9d4' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
-- Jason Snider / Civil Rights and Social Justice: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://tigardlife.com/featured/former-mayor-snider-reflects-on-decade-in-public-office-as-he-passes-the-mantle/']::text[]
 WHERE politician_id = 'a98aeea6-c7cf-475c-96f2-100119c9037a' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Amanda Hollowell / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.amandaforga.com/about']::text[]
 WHERE politician_id = 'c3415ffe-b1c8-44e7-a520-023bc0e82eec' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Amanda Hollowell / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.amandaforga.com/about']::text[]
 WHERE politician_id = 'c3415ffe-b1c8-44e7-a520-023bc0e82eec' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Addison P. McDowell / Climate Change and Environmental Protection: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.isidewith.com/candidates/addison-mcdowell/policies']::text[]
 WHERE politician_id = '74579547-1454-475e-ab35-12cf88a998b9' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
-- Addison P. McDowell / Fossil Fuel Policy: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.isidewith.com/candidates/addison-mcdowell/policies']::text[]
 WHERE politician_id = '74579547-1454-475e-ab35-12cf88a998b9' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
-- Lacey Beaty / Public Safety Approach: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://beavertonpolice.org/198/Mental-Health-Response-Team', 'https://katu.com/news/local/beaverton-faces-107-million-budget-shortfall-plans-cuts-to-police-and-public-works-library-street-repair-resident-portland-oregon-washington-county-finances-economy-consumer']::text[]
 WHERE politician_id = '6f4e9c86-1c23-4569-ad1a-7614463420f1' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
-- Steven Welzer / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.gp.org/social_justice']::text[]
 WHERE politician_id = '2e18007e-0d6a-4f2c-8ca4-1d42bf40b9b7' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Beach Pace / Homelessness Response: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.washingtoncountyor.gov/housing/news/2025/03/03/hillsboro-year-round-shelter-celebrates-groundbreaking', 'https://outnw.com/queer-politicians-q-a-beach-pace-for-mayor-of-hillsboro-or/']::text[]
 WHERE politician_id = '95a6d0c4-2b0e-4c4f-9f53-02eb55543fb7' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
-- Byron H. Nolen / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['http://www.telegramnews.net/story/2024/09/19/news/city-leaders-in-inkster-working-to-adopt-2024-master-plan/2797.html']::text[]
 WHERE politician_id = 'ae6bd84c-2899-459d-99f1-25c3bdb0d666' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
-- Frank Bubenik / Growth and Development Pace: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://tualatinlife.com/featured/state-of-the-city-tualatin-is-going-full-steam-ahead/', 'https://tualatinlife.com/featured/state-of-the-city-busy/']::text[]
 WHERE politician_id = '8fbc9fc7-6840-450f-b490-24c41b2a153f' AND topic_id = 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
-- Frank Bubenik / Economic Development Incentives: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://tualatinlife.com/business/two-year-report-shows-mostly-sunny-snapshot-of-tualatins-economy/', 'https://tualatinlife.com/featured/state-of-the-city-tualatin-is-going-full-steam-ahead/']::text[]
 WHERE politician_id = '8fbc9fc7-6840-450f-b490-24c41b2a153f' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Frank Bubenik / Transportation Priorities: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.tualatinmovingforward.com/', 'https://tigardlife.com/featured/how-tigard-and-tualatin-will-be-impacted-by-the-southwest-corridor-light-rail-project/']::text[]
 WHERE politician_id = '8fbc9fc7-6840-450f-b490-24c41b2a153f' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Cyndy Hillier / Growth and Development Pace: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://tualatinlife.com/featured/tualatin-votes-2024-2/', 'https://www.newsbreak.com/news/3638717425073-candidate-q-a-tualatin-city-council-candidates-talk-economics-housing-and-more']::text[]
 WHERE politician_id = '2c2c74d5-017d-4889-9fad-907f0f556271' AND topic_id = 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
-- Cyndy Hillier / Economic Development Incentives: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.newsbreak.com/news/3638717425073-candidate-q-a-tualatin-city-council-candidates-talk-economics-housing-and-more', 'https://tualatinlife.com/featured/tualatin-votes-2024-2/']::text[]
 WHERE politician_id = '2c2c74d5-017d-4889-9fad-907f0f556271' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
-- Cyndy Hillier / Transportation Priorities: drop 1, keep 2
UPDATE inform.politician_context
   SET sources = ARRAY['https://tualatinlife.com/politics/cyndy-hillier/', 'https://www.newsbreak.com/news/3638717425073-candidate-q-a-tualatin-city-council-candidates-talk-economics-housing-and-more']::text[]
 WHERE politician_id = '2c2c74d5-017d-4889-9fad-907f0f556271' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
-- Jeffrey Hulum III / School Vouchers & Public Education Funding: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://jeffreyhulumiiiforcongress.com/issues']::text[]
 WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';
-- Jeffrey C. Dalin / Local Immigration Enforcement: drop 1, keep 3
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-169', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Minutes/_11172025-171', 'https://www.corneliusor.gov/AgendaCenter/ViewFile/Item/283?fileID=1401']::text[]
 WHERE politician_id = '856f7e70-a846-4ba3-a0df-e7d8146ed11a' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';
-- Micah Quinney Jones / Civil Rights and Social Justice: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.foxnews.com/politics/ex-democrat-reveals-why-he-ditched-party-running-republican-blue-stronghold']::text[]
 WHERE politician_id = 'ae2c73b0-8a44-4c1e-a641-0da9c7f8552a' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';
-- Alex Eaton / Healthcare Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://smarter.vote/races/mn-house-01-2026/alex-eaton/']::text[]
 WHERE politician_id = '3567d4a2-5be4-4470-b27b-b43a1c87e20c' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
-- Alex Eaton / Taxation and Public Spending: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://smarter.vote/races/mn-house-01-2026/alex-eaton/']::text[]
 WHERE politician_id = '3567d4a2-5be4-4470-b27b-b43a1c87e20c' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
-- Alex Eaton / Childcare Affordability & Access: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://smarter.vote/races/mn-house-01-2026/alex-eaton/']::text[]
 WHERE politician_id = '3567d4a2-5be4-4470-b27b-b43a1c87e20c' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
-- Patrick Mcauley / Affordable Housing: drop 1, keep 1
UPDATE inform.politician_context
   SET sources = ARRAY['https://libertyfirst.org/2026-candidates-patrick-mcauley-r-indiana-7th-congressional-district/']::text[]
 WHERE politician_id = 'cda9e16f-b175-42ee-bc16-a8f110512392' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

DO $$
DECLARE v_left int; v_ctx int; v_bad text;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1538 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left; END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1538 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx; END IF;

  -- 🔴 NO COMPOSED URL MAY SURVIVE ON A STRIPPED ROW, and no stripped row may end up sourceless.
  SELECT count(*) INTO v_left FROM inform.politician_context
   WHERE (politician_id, topic_id) IN (('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f','4938766b-b45a-46e3-93bd-b8b30651271a'), ('a2c6adc7-7689-49b9-964f-8f2aeb243a83','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('a2c6adc7-7689-49b9-964f-8f2aeb243a83','24e9212c-b011-422a-865c-093e35050901'), ('03df7cce-7502-4089-acd5-139841002cbe','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6','48cc9585-ec22-4f53-8d42-6839828dd36f'), ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6','92730f69-ae57-401c-8ad1-2d07834a895d'), ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('93613d15-1098-423b-9e18-81f125ac2408','7687de4f-4d0b-462a-b803-bdfb23b16b42'), ('122f1897-2dae-4f21-bee0-1c02c95e9e3a','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'), ('122f1897-2dae-4f21-bee0-1c02c95e9e3a','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'), ('122f1897-2dae-4f21-bee0-1c02c95e9e3a','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('122f1897-2dae-4f21-bee0-1c02c95e9e3a','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('122f1897-2dae-4f21-bee0-1c02c95e9e3a','b9ccee94-ad96-4f10-b655-889d8e5abe92'), ('122f1897-2dae-4f21-bee0-1c02c95e9e3a','9db07b16-1076-4b7d-ad89-ebe7b51f4336'), ('122f1897-2dae-4f21-bee0-1c02c95e9e3a','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('91f6d45d-5e7e-48f6-aab1-9476d81946b5','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('85741f19-1c12-43ad-8504-d615522725d7','4938766b-b45a-46e3-93bd-b8b30651271a'), ('85741f19-1c12-43ad-8504-d615522725d7','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('f865995d-ad3a-4d2d-827f-ed8a1a67af18','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('f865995d-ad3a-4d2d-827f-ed8a1a67af18','669cac97-66a6-4087-b036-936fbe62efb3'), ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35','669cac97-66a6-4087-b036-936fbe62efb3'), ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('7157dd95-0f1b-4e05-bd4f-39317345b47c','9db07b16-1076-4b7d-ad89-ebe7b51f4336'), ('7157dd95-0f1b-4e05-bd4f-39317345b47c','7bad33eb-e93e-4d94-8822-97212d49bde5'), ('7157dd95-0f1b-4e05-bd4f-39317345b47c','9d45acaf-1ba4-4cb8-95e1-5ed985223b91'), ('7157dd95-0f1b-4e05-bd4f-39317345b47c','e5e48f0e-8f3a-40e1-8080-889fea389603'), ('c62e5d6a-0115-4f2d-9084-b0c3980e6db4','d4f18138-a2e0-4110-b925-7387d9d0d16d'), ('4ba62f32-dd20-48ce-8d84-d09bb129ad59','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('d0977350-df68-4cfe-822e-816ba13f9213','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('b26fb5d2-90eb-4108-8ce5-838df719473d','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('929346a2-8037-4b14-af33-4820eb365323','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('f26309c8-2525-49b2-bdaf-62980cbb1853','666bf03d-81fc-4138-ab15-69ae734c9023'), ('41ef8aaa-b604-4725-b46d-dab1656cc198','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('5ad32852-789e-4013-995b-6f0aa6a5a5d4','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('15cb5825-649a-4cc5-b14b-ccd4b4402c87','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'), ('15cb5825-649a-4cc5-b14b-ccd4b4402c87','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('15cb5825-649a-4cc5-b14b-ccd4b4402c87','4938766b-b45a-46e3-93bd-b8b30651271a'), ('15cb5825-649a-4cc5-b14b-ccd4b4402c87','b9ccee94-ad96-4f10-b655-889d8e5abe92'), ('15cb5825-649a-4cc5-b14b-ccd4b4402c87','669cac97-66a6-4087-b036-936fbe62efb3'), ('15cb5825-649a-4cc5-b14b-ccd4b4402c87','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('539874fc-489f-4643-9b1a-923aca6cc2c1','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('f1f3e6ca-5532-4f33-8ec2-64791b08f59b','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723','d4f18138-a2e0-4110-b925-7387d9d0d16d'), ('d65e3760-95f3-4ad5-ba29-be01a76ae23b','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('a2c6adc7-7689-49b9-964f-8f2aeb243a83','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('f26309c8-2525-49b2-bdaf-62980cbb1853','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'), ('d40a0eda-36fc-4032-8382-20c76a36d6a6','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('c435ab14-5d64-46e4-a59f-bba18ed483c9','669cac97-66a6-4087-b036-936fbe62efb3'), ('d40a0eda-36fc-4032-8382-20c76a36d6a6','669cac97-66a6-4087-b036-936fbe62efb3'), ('d40a0eda-36fc-4032-8382-20c76a36d6a6','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'), ('d40a0eda-36fc-4032-8382-20c76a36d6a6','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('d40a0eda-36fc-4032-8382-20c76a36d6a6','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7','9db07b16-1076-4b7d-ad89-ebe7b51f4336'), ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7','1fab5edf-6151-4da0-9704-a7f2113ba54c'), ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7','669cac97-66a6-4087-b036-936fbe62efb3'), ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','92730f69-ae57-401c-8ad1-2d07834a895d'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','a22215c3-6693-4bc2-b248-01aebba14570'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','7bad33eb-e93e-4d94-8822-97212d49bde5'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','48cc9585-ec22-4f53-8d42-6839828dd36f'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','00b95a6a-75db-4521-b523-3326bba938de'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','92730f69-ae57-401c-8ad1-2d07834a895d'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','48cc9585-ec22-4f53-8d42-6839828dd36f'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','6b9ba6d9-1001-43f5-b073-4d37130696fd'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','00b95a6a-75db-4521-b523-3326bba938de'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','87d20824-a6e9-407b-983c-65440084a0ab'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','683c8084-2281-4920-a07c-18439b2dd413'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','24e9212c-b011-422a-865c-093e35050901'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','92730f69-ae57-401c-8ad1-2d07834a895d'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','a22215c3-6693-4bc2-b248-01aebba14570'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','683c8084-2281-4920-a07c-18439b2dd413'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','24e9212c-b011-422a-865c-093e35050901'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('9d34705c-0a66-4c08-8936-7e63629ce435','669cac97-66a6-4087-b036-936fbe62efb3'), ('9d34705c-0a66-4c08-8936-7e63629ce435','d4f18138-a2e0-4110-b925-7387d9d0d16d'), ('9d34705c-0a66-4c08-8936-7e63629ce435','1935979c-b290-42e4-baa5-8cb0138b4ffa'), ('9d34705c-0a66-4c08-8936-7e63629ce435','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','a22215c3-6693-4bc2-b248-01aebba14570'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','669cac97-66a6-4087-b036-936fbe62efb3'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','669cac97-66a6-4087-b036-936fbe62efb3'), ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b','669cac97-66a6-4087-b036-936fbe62efb3'), ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('a40f234e-1790-4b52-8670-090b6379eb03','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('a40f234e-1790-4b52-8670-090b6379eb03','a22215c3-6693-4bc2-b248-01aebba14570'), ('a40f234e-1790-4b52-8670-090b6379eb03','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('a40f234e-1790-4b52-8670-090b6379eb03','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('a40f234e-1790-4b52-8670-090b6379eb03','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('6d8717ca-45f9-42cf-bd28-6786a50d254f','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('6d8717ca-45f9-42cf-bd28-6786a50d254f','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('6d8717ca-45f9-42cf-bd28-6786a50d254f','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe','669cac97-66a6-4087-b036-936fbe62efb3'), ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c','669cac97-66a6-4087-b036-936fbe62efb3'), ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32','a22215c3-6693-4bc2-b248-01aebba14570'), ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32','669cac97-66a6-4087-b036-936fbe62efb3'), ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('bd451748-111f-461d-9752-95e7c243769e','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('bd451748-111f-461d-9752-95e7c243769e','669cac97-66a6-4087-b036-936fbe62efb3'), ('bd451748-111f-461d-9752-95e7c243769e','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('bd451748-111f-461d-9752-95e7c243769e','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2','669cac97-66a6-4087-b036-936fbe62efb3'), ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2','a22215c3-6693-4bc2-b248-01aebba14570'), ('6d8717ca-45f9-42cf-bd28-6786a50d254f','669cac97-66a6-4087-b036-936fbe62efb3'), ('6d8717ca-45f9-42cf-bd28-6786a50d254f','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('99457307-afa4-4045-aebf-06ee8b39d28f','669cac97-66a6-4087-b036-936fbe62efb3'), ('99457307-afa4-4045-aebf-06ee8b39d28f','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('99457307-afa4-4045-aebf-06ee8b39d28f','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('5cd1c798-31dc-4e53-b578-7e2d81378478','669cac97-66a6-4087-b036-936fbe62efb3'), ('5cd1c798-31dc-4e53-b578-7e2d81378478','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('ab975fdf-b4f1-4955-94a4-97681a2a8d08','669cac97-66a6-4087-b036-936fbe62efb3'), ('ab975fdf-b4f1-4955-94a4-97681a2a8d08','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('ab975fdf-b4f1-4955-94a4-97681a2a8d08','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('67ea7814-b7aa-42de-aba8-2230c181d15a','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('67ea7814-b7aa-42de-aba8-2230c181d15a','669cac97-66a6-4087-b036-936fbe62efb3'), ('67ea7814-b7aa-42de-aba8-2230c181d15a','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('c435ab14-5d64-46e4-a59f-bba18ed483c9','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('247cf8e5-426a-4104-9027-6a2a0b1b61c9','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('247cf8e5-426a-4104-9027-6a2a0b1b61c9','669cac97-66a6-4087-b036-936fbe62efb3'), ('247cf8e5-426a-4104-9027-6a2a0b1b61c9','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','669cac97-66a6-4087-b036-936fbe62efb3'), ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('41ced04d-7403-4170-a267-c339191e6fcd','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','669cac97-66a6-4087-b036-936fbe62efb3'), ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('41ced04d-7403-4170-a267-c339191e6fcd','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('9cb46542-a671-4bdd-bfcb-98fc1bc79415','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('9cb46542-a671-4bdd-bfcb-98fc1bc79415','a22215c3-6693-4bc2-b248-01aebba14570'), ('c7e94dda-1862-40fe-bda5-5fa2fe68f536','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('ea9fc2d6-3b26-469a-978c-e8c846d2d49a','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','669cac97-66a6-4087-b036-936fbe62efb3'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','a22215c3-6693-4bc2-b248-01aebba14570'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','48cc9585-ec22-4f53-8d42-6839828dd36f'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','00b95a6a-75db-4521-b523-3326bba938de'), ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','4938766b-b45a-46e3-93bd-b8b30651271a'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','9db07b16-1076-4b7d-ad89-ebe7b51f4336'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','669cac97-66a6-4087-b036-936fbe62efb3'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','00b95a6a-75db-4521-b523-3326bba938de'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','92730f69-ae57-401c-8ad1-2d07834a895d'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','48cc9585-ec22-4f53-8d42-6839828dd36f'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','a22215c3-6693-4bc2-b248-01aebba14570'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), ('760cd4a7-235c-472f-a0ba-fb07098dfd57','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('29fcdf7e-e3e2-4463-b461-ffd7a34a8754','a22215c3-6693-4bc2-b248-01aebba14570'), ('0ba1cecc-8493-495b-8d58-34d50bbacfba','666bf03d-81fc-4138-ab15-69ae734c9023'), ('0ba1cecc-8493-495b-8d58-34d50bbacfba','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('0ba1cecc-8493-495b-8d58-34d50bbacfba','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), ('0ba1cecc-8493-495b-8d58-34d50bbacfba','87d20824-a6e9-407b-983c-65440084a0ab'), ('401f1fab-c996-4b1a-92f7-2817c5dd4619','a22215c3-6693-4bc2-b248-01aebba14570'), ('401f1fab-c996-4b1a-92f7-2817c5dd4619','00b95a6a-75db-4521-b523-3326bba938de'), ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'), ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('27d57833-842f-427c-bedd-aa1695fe550f','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('27d57833-842f-427c-bedd-aa1695fe550f','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('27d57833-842f-427c-bedd-aa1695fe550f','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), ('2a6693c7-9149-4e71-85fe-003746f7d23d','666bf03d-81fc-4138-ab15-69ae734c9023'), ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c','669cac97-66a6-4087-b036-936fbe62efb3'), ('27d57833-842f-427c-bedd-aa1695fe550f','6b9ba6d9-1001-43f5-b073-4d37130696fd'), ('a9e04e1e-92d4-44e4-a411-b6fe4814290a','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('a9e04e1e-92d4-44e4-a411-b6fe4814290a','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('a9e04e1e-92d4-44e4-a411-b6fe4814290a','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('a9e04e1e-92d4-44e4-a411-b6fe4814290a','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('02f88a57-ccf5-4fe1-a693-7fc949321fb1','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('02f88a57-ccf5-4fe1-a693-7fc949321fb1','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('41949a2b-563a-4608-91c6-951c63252a91','48cc9585-ec22-4f53-8d42-6839828dd36f'), ('41949a2b-563a-4608-91c6-951c63252a91','b9ccee94-ad96-4f10-b655-889d8e5abe92'), ('41949a2b-563a-4608-91c6-951c63252a91','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('f72689da-fe02-4bdd-977f-bb7760a42fb2','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('8aeb0ff5-e0b0-4933-8e97-5be1339e4729','00b95a6a-75db-4521-b523-3326bba938de'), ('8aeb0ff5-e0b0-4933-8e97-5be1339e4729','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), ('dd90ac18-7613-4a2f-bfc1-2eddfebb4daf','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('dd90ac18-7613-4a2f-bfc1-2eddfebb4daf','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('1e25123b-7f6c-47c3-b597-bbd626c185ae','b9ccee94-ad96-4f10-b655-889d8e5abe92'), ('1e25123b-7f6c-47c3-b597-bbd626c185ae','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('1e25123b-7f6c-47c3-b597-bbd626c185ae','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('3b3b6525-7a40-4d01-a1cb-3270ed166919','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('3b3b6525-7a40-4d01-a1cb-3270ed166919','4938766b-b45a-46e3-93bd-b8b30651271a'), ('3b3b6525-7a40-4d01-a1cb-3270ed166919','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('3b3b6525-7a40-4d01-a1cb-3270ed166919','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('3b3b6525-7a40-4d01-a1cb-3270ed166919','1935979c-b290-42e4-baa5-8cb0138b4ffa'), ('f20601e0-0728-4c33-803c-28c88e170286','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('4754dede-4a3b-4280-a8b1-7497530107f7','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('4754dede-4a3b-4280-a8b1-7497530107f7','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('4754dede-4a3b-4280-a8b1-7497530107f7','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('4754dede-4a3b-4280-a8b1-7497530107f7','669cac97-66a6-4087-b036-936fbe62efb3'), ('4754dede-4a3b-4280-a8b1-7497530107f7','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('4754dede-4a3b-4280-a8b1-7497530107f7','1935979c-b290-42e4-baa5-8cb0138b4ffa'), ('4754dede-4a3b-4280-a8b1-7497530107f7','a22215c3-6693-4bc2-b248-01aebba14570'), ('4754dede-4a3b-4280-a8b1-7497530107f7','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('4754dede-4a3b-4280-a8b1-7497530107f7','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('4754dede-4a3b-4280-a8b1-7497530107f7','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('4754dede-4a3b-4280-a8b1-7497530107f7','00b95a6a-75db-4521-b523-3326bba938de'), ('4754dede-4a3b-4280-a8b1-7497530107f7','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('4754dede-4a3b-4280-a8b1-7497530107f7','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('4754dede-4a3b-4280-a8b1-7497530107f7','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('4754dede-4a3b-4280-a8b1-7497530107f7','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('abf34eb9-8b81-4c9f-8db6-25ba036419c9','669cac97-66a6-4087-b036-936fbe62efb3'), ('c6af7e50-b937-4c1e-b397-ac2606d39b7f','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), ('b592e432-6411-48b3-bca3-d5596d0d81e9','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1','4559b513-0fd8-4ed1-babd-f3b554162f40'), ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'), ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1','669cac97-66a6-4087-b036-936fbe62efb3'), ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1','00b95a6a-75db-4521-b523-3326bba938de'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','00b95a6a-75db-4521-b523-3326bba938de'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','a22215c3-6693-4bc2-b248-01aebba14570'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','48cc9585-ec22-4f53-8d42-6839828dd36f'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','92730f69-ae57-401c-8ad1-2d07834a895d'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','9db07b16-1076-4b7d-ad89-ebe7b51f4336'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','7bad33eb-e93e-4d94-8822-97212d49bde5'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','669cac97-66a6-4087-b036-936fbe62efb3'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','6b9ba6d9-1001-43f5-b073-4d37130696fd'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), ('9e3f9d94-ec56-4d9e-811f-8b4672494362','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','666bf03d-81fc-4138-ab15-69ae734c9023'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','4559b513-0fd8-4ed1-babd-f3b554162f40'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','a22215c3-6693-4bc2-b248-01aebba14570'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','4938766b-b45a-46e3-93bd-b8b30651271a'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','669cac97-66a6-4087-b036-936fbe62efb3'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','b9ccee94-ad96-4f10-b655-889d8e5abe92'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','d4f18138-a2e0-4110-b925-7387d9d0d16d'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','683c8084-2281-4920-a07c-18439b2dd413'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','24e9212c-b011-422a-865c-093e35050901'), ('7cf1080e-6e7e-4f5b-be00-6fb170896a7c','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','1935979c-b290-42e4-baa5-8cb0138b4ffa'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','b9ccee94-ad96-4f10-b655-889d8e5abe92'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','d4f18138-a2e0-4110-b925-7387d9d0d16d'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), ('e687c089-f00d-464c-aa37-3b021a3aba2c','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('a0e4e813-6c10-45d8-8f59-f444c6747b61','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'), ('dd08c9de-076d-40ee-ab27-9298bbb72d1a','4559b513-0fd8-4ed1-babd-f3b554162f40'), ('dd08c9de-076d-40ee-ab27-9298bbb72d1a','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('dd08c9de-076d-40ee-ab27-9298bbb72d1a','e5e48f0e-8f3a-40e1-8080-889fea389603'), ('dd08c9de-076d-40ee-ab27-9298bbb72d1a','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'), ('dd08c9de-076d-40ee-ab27-9298bbb72d1a','d4f18138-a2e0-4110-b925-7387d9d0d16d'), ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','4559b513-0fd8-4ed1-babd-f3b554162f40'), ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','a22215c3-6693-4bc2-b248-01aebba14570'), ('a0cb697c-3158-4680-8e70-c154c3a15cc4','4559b513-0fd8-4ed1-babd-f3b554162f40'), ('a0cb697c-3158-4680-8e70-c154c3a15cc4','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('a0cb697c-3158-4680-8e70-c154c3a15cc4','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'), ('a0cb697c-3158-4680-8e70-c154c3a15cc4','4938766b-b45a-46e3-93bd-b8b30651271a'), ('a0cb697c-3158-4680-8e70-c154c3a15cc4','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'), ('a0cb697c-3158-4680-8e70-c154c3a15cc4','669cac97-66a6-4087-b036-936fbe62efb3'), ('a0cb697c-3158-4680-8e70-c154c3a15cc4','e5e48f0e-8f3a-40e1-8080-889fea389603'), ('a0cb697c-3158-4680-8e70-c154c3a15cc4','6674d87e-999d-433a-aab7-3f626f59fd5f'), ('a0cb697c-3158-4680-8e70-c154c3a15cc4','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'), ('a0cb697c-3158-4680-8e70-c154c3a15cc4','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'), ('a0cb697c-3158-4680-8e70-c154c3a15cc4','d4f18138-a2e0-4110-b925-7387d9d0d16d'), ('a0cb697c-3158-4680-8e70-c154c3a15cc4','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','666bf03d-81fc-4138-ab15-69ae734c9023'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','4938766b-b45a-46e3-93bd-b8b30651271a'), ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','666bf03d-81fc-4138-ab15-69ae734c9023'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','1935979c-b290-42e4-baa5-8cb0138b4ffa'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','6b9ba6d9-1001-43f5-b073-4d37130696fd'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','683c8084-2281-4920-a07c-18439b2dd413'), ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','24e9212c-b011-422a-865c-093e35050901'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','4938766b-b45a-46e3-93bd-b8b30651271a'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','669cac97-66a6-4087-b036-936fbe62efb3'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','6b9ba6d9-1001-43f5-b073-4d37130696fd'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), ('62b453da-3dea-4177-82ba-9e4b78eb7691','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('973d60e2-fca7-4185-bd2a-84a686e925ab','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2','48cc9585-ec22-4f53-8d42-6839828dd36f'), ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('b1bd9a21-a37e-49f4-907b-9fba480a1ca2','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('6d8717ca-45f9-42cf-bd28-6786a50d254f','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('6d8717ca-45f9-42cf-bd28-6786a50d254f','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('a40f234e-1790-4b52-8670-090b6379eb03','669cac97-66a6-4087-b036-936fbe62efb3'), ('a40f234e-1790-4b52-8670-090b6379eb03','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('a40f234e-1790-4b52-8670-090b6379eb03','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'), ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('c7e94dda-1862-40fe-bda5-5fa2fe68f536','669cac97-66a6-4087-b036-936fbe62efb3'), ('c7e94dda-1862-40fe-bda5-5fa2fe68f536','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('c7e94dda-1862-40fe-bda5-5fa2fe68f536','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('c7e94dda-1862-40fe-bda5-5fa2fe68f536','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'), ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('e1f72270-5809-4d0e-969c-48d1ab34fbdc','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('e1f72270-5809-4d0e-969c-48d1ab34fbdc','669cac97-66a6-4087-b036-936fbe62efb3'), ('e1f72270-5809-4d0e-969c-48d1ab34fbdc','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('5cd1c798-31dc-4e53-b578-7e2d81378478','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('5cd1c798-31dc-4e53-b578-7e2d81378478','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('67ea7814-b7aa-42de-aba8-2230c181d15a','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('c435ab14-5d64-46e4-a59f-bba18ed483c9','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('c435ab14-5d64-46e4-a59f-bba18ed483c9','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('f865995d-ad3a-4d2d-827f-ed8a1a67af18','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('f865995d-ad3a-4d2d-827f-ed8a1a67af18','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('f865995d-ad3a-4d2d-827f-ed8a1a67af18','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','1935979c-b290-42e4-baa5-8cb0138b4ffa'), ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32','1935979c-b290-42e4-baa5-8cb0138b4ffa'), ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('bd451748-111f-461d-9752-95e7c243769e','1935979c-b290-42e4-baa5-8cb0138b4ffa'), ('03e35156-c179-4dd5-9c8c-8d418976914e','669cac97-66a6-4087-b036-936fbe62efb3'), ('35cf0880-be86-45bb-97e9-4ef2097feba1','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('ca9208b4-47c6-4a4e-8d8f-62d6e179d7f4','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('69a4aaa2-5265-45e0-87c7-8cea22b2dc18','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('acf7819a-3e36-4d17-8828-3238adb894b0','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('acf7819a-3e36-4d17-8828-3238adb894b0','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('a485b386-65a5-4c6c-aaa1-a441facd45fc','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('a4e6e14a-46f7-4574-94c6-5b7edd484d91','666bf03d-81fc-4138-ab15-69ae734c9023'), ('8658e02a-1456-45ba-96bb-19ff438d8e1b','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('9cb46542-a671-4bdd-bfcb-98fc1bc79415','00b95a6a-75db-4521-b523-3326bba938de'), ('9cb46542-a671-4bdd-bfcb-98fc1bc79415','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('9cb46542-a671-4bdd-bfcb-98fc1bc79415','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('9cb46542-a671-4bdd-bfcb-98fc1bc79415','669cac97-66a6-4087-b036-936fbe62efb3'), ('fc1d7143-1be8-49b0-be31-6dbc5874230d','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('fc1d7143-1be8-49b0-be31-6dbc5874230d','b9ccee94-ad96-4f10-b655-889d8e5abe92'), ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','9db07b16-1076-4b7d-ad89-ebe7b51f4336'), ('5114097d-c06a-4147-85bc-f9a6646f5c46','669cac97-66a6-4087-b036-936fbe62efb3'), ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c','7687de4f-4d0b-462a-b803-bdfb23b16b42'), ('ef52f3fd-dc4d-4a4a-8320-fbae613a4baa','669cac97-66a6-4087-b036-936fbe62efb3'), ('246e6b71-e8ad-44bb-aa5c-10228d2c056a','669cac97-66a6-4087-b036-936fbe62efb3'), ('b7015fbc-6173-48bc-99ba-d0363b771048','669cac97-66a6-4087-b036-936fbe62efb3'), ('4b0e72f4-15f8-495a-b90a-e5b8b987cd63','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'), ('c8befa3a-280a-4ad5-af75-d8ca11498222','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('a5a58bc3-e654-4a35-8418-84e1ba57506f','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('a5a58bc3-e654-4a35-8418-84e1ba57506f','a22215c3-6693-4bc2-b248-01aebba14570'), ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','24e9212c-b011-422a-865c-093e35050901'), ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','a22215c3-6693-4bc2-b248-01aebba14570'), ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('f0d27c86-02f3-4014-9162-e4e940f2afdd','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('44e1f38c-a135-41db-a96a-b67412e246e8','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('44e1f38c-a135-41db-a96a-b67412e246e8','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'), ('44e1f38c-a135-41db-a96a-b67412e246e8','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4','669cac97-66a6-4087-b036-936fbe62efb3'), ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('a8f96324-50ac-4fa1-b57b-47a998306fe8','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('a8f96324-50ac-4fa1-b57b-47a998306fe8','a22215c3-6693-4bc2-b248-01aebba14570'), ('56cecf7c-6de0-440f-b8e2-34945ec52333','669cac97-66a6-4087-b036-936fbe62efb3'), ('56cecf7c-6de0-440f-b8e2-34945ec52333','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('06b1dae6-5fcf-4a1f-ba89-d06cbae5c19d','b9ccee94-ad96-4f10-b655-889d8e5abe92'), ('358d0829-8d2b-46ea-9af2-251f48960014','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), ('406dd9be-a751-4685-a946-44806bd01548','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('d90f754e-c3c6-44f9-890d-a8f2a9a00d22','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('d90f754e-c3c6-44f9-890d-a8f2a9a00d22','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('d33b1fb5-bac7-48b9-9628-8169e28f4e16','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('1bb5c062-9b9d-44de-820b-c3efe0d08222','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('0ed76bd2-273d-4057-9c4e-4259d6cb9ebc','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('ade5ce47-25a7-4332-848f-877404875f0e','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('ade5ce47-25a7-4332-848f-877404875f0e','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'), ('26dbe16a-9dff-42c0-939f-5b5e529063ca','b9ccee94-ad96-4f10-b655-889d8e5abe92'), ('26dbe16a-9dff-42c0-939f-5b5e529063ca','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('26dbe16a-9dff-42c0-939f-5b5e529063ca','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'), ('5be0c642-33b3-4ea4-8bb1-2eb25df2b4ef','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('c06165d2-008c-4fe3-93cd-e31fbd6e377f','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('013bf70b-627c-4699-b11d-67924e6916a2','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('76b00811-8bf8-46c0-bb0c-9867c90fe9d4','b9ccee94-ad96-4f10-b655-889d8e5abe92'), ('a98aeea6-c7cf-475c-96f2-100119c9037a','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('c3415ffe-b1c8-44e7-a520-023bc0e82eec','669cac97-66a6-4087-b036-936fbe62efb3'), ('c3415ffe-b1c8-44e7-a520-023bc0e82eec','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('74579547-1454-475e-ab35-12cf88a998b9','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('74579547-1454-475e-ab35-12cf88a998b9','a22215c3-6693-4bc2-b248-01aebba14570'), ('6f4e9c86-1c23-4569-ad1a-7614463420f1','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('2e18007e-0d6a-4f2c-8ca4-1d42bf40b9b7','669cac97-66a6-4087-b036-936fbe62efb3'), ('95a6d0c4-2b0e-4c4f-9f53-02eb55543fb7','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'), ('ae6bd84c-2899-459d-99f1-25c3bdb0d666','669cac97-66a6-4087-b036-936fbe62efb3'), ('8fbc9fc7-6840-450f-b490-24c41b2a153f','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'), ('8fbc9fc7-6840-450f-b490-24c41b2a153f','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('8fbc9fc7-6840-450f-b490-24c41b2a153f','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('2c2c74d5-017d-4889-9fad-907f0f556271','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'), ('2c2c74d5-017d-4889-9fad-907f0f556271','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('2c2c74d5-017d-4889-9fad-907f0f556271','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('6ff3ff30-00b9-4077-8cde-700cf687d106','00b95a6a-75db-4521-b523-3326bba938de'), ('856f7e70-a846-4ba3-a0df-e7d8146ed11a','b9ccee94-ad96-4f10-b655-889d8e5abe92'), ('ae2c73b0-8a44-4c1e-a641-0da9c7f8552a','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('3567d4a2-5be4-4470-b27b-b43a1c87e20c','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('3567d4a2-5be4-4470-b27b-b43a1c87e20c','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('3567d4a2-5be4-4470-b27b-b43a1c87e20c','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('cda9e16f-b175-42ee-bc16-a8f110512392','669cac97-66a6-4087-b036-936fbe62efb3'))
     AND (sources IS NULL OR cardinality(sources) = 0);
  IF v_left <> 0 THEN RAISE EXCEPTION '% stripped rows left with no sources at all', v_left; END IF;

  -- Every emptied politician must be timestamp-free; every other must still hold stances.
  SELECT count(*) INTO v_left FROM essentials.politicians
   WHERE id IN ('1221c215-2b80-46f7-b980-c04f25c5866f', '1a7720f9-49b0-4e5d-a0ec-7fb32fba2c2e', '30f6667d-a88b-46e4-91d8-678130ae37b6', '3e616ef8-0ca7-4171-8d73-2cbb61d696f6', '44a2b39e-4127-446e-adc2-8f48a2e6fdac', '4870519a-0d42-435c-8574-c72669fe8090', '4f69ba91-d6f4-400e-aa46-10f1706d2f3c', '51060129-8709-451d-90c4-ce03e7fcc788', '558811b6-e13c-4222-8042-0cdfe32cea01', '73a11a8c-6b57-4803-b786-961e83705fd8', '756298b0-4628-408a-8568-6e8369425569', '84ca82d9-c7be-47de-8f5a-61221dbb08b8', '96a1408d-dc35-406d-a1cb-7730dc24b658', '978a43f2-f384-48aa-8e93-9784a3e5fdd0', '97a9f873-8af9-41a2-a62f-3ad3952459bd', '9a4c4152-70f4-4056-be19-9ff3236e060d', '9b6c7f25-b1dc-42ab-84d1-83d0728014ec', 'a1d5e9fa-1b1a-4a25-b698-21032b43fe6d', 'a6006e68-1607-4fe5-9346-27abe389c7f4', 'b0ff1c08-80fc-4746-a147-fa201f689cce', 'b39524df-ef91-48dc-a1a8-1880c271bd7c', 'b4f9688b-add0-44d6-bab8-e923d17d105e', 'c526a928-ab27-424f-a809-c6ed26bf26d3', 'd7479ffb-177a-44cd-aaac-d86d91522fc3', 'e45d22f7-fdac-436a-8923-3cbfc4a77bd3', 'e89e4ae3-b3e4-4f09-8fe4-e3877d24653d', 'f4eabcb1-33d0-4150-a2de-597014f1186b', 'f617fda8-15c7-47d6-8fbf-0a39e6db3071') AND last_stances_researched_at IS NOT NULL;
  IF v_left <> 0 THEN RAISE EXCEPTION '% emptied politicians still carry a research timestamp', v_left; END IF;

  SELECT string_agg(DISTINCT p.full_name, ', ') INTO v_bad
    FROM essentials.politicians p
   WHERE p.id IN ('0695eddd-6fb4-40f7-8daa-f5d6d10d6db4', '13dc32dd-fac5-440d-9f10-f1f1892acf68', '15c27efb-0402-4a3a-bfad-9df152874046', '1c9edb0f-f3b9-480b-b04b-fd20908fcaae', '21e534c8-c0c0-42f5-b52b-5eb2f246d632', '236fb3c1-b473-407f-b8a0-d76039b28087', '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f', '3030383b-2aaf-40fd-9dfb-8867d1d02f99', '34ef5b52-ee2c-436f-93c6-110f286cc2bf', '38aa9579-5fdf-40a5-8f7a-738f16b3d655', '3b3b6525-7a40-4d01-a1cb-3270ed166919', '3d68627c-c4cb-44f5-8b13-b48cd0edcd7a', '41c14549-89c4-451c-91d7-22a578a4dc7d', '44e1f38c-a135-41db-a96a-b67412e246e8', '4b0e72f4-15f8-495a-b90a-e5b8b987cd63', '583a5fab-16d5-40c5-8c6c-25b9ea4b97ae', '5b590765-e701-41cf-b0c3-e7efdeea16d3', '65bdba41-859d-41ba-bb25-65e8ba50f5ad', '66c3bd97-94d1-4287-b1b8-86605a38cb97', '67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2', '6d30fb7c-99cb-4705-86bc-c3d13ffd44d4', '6d7a04e3-28c9-4e04-a6ec-855a096323ba', '6e5d3005-07e5-4c57-a3e0-033a2b17bbdc', '71c35909-e5b5-40ca-883f-21af5c287b5e', '72dd5219-490f-48bb-986e-183a6098d602', '773aa577-9e09-4721-80ee-6219edb151e7', '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', '780b7f22-755a-4a92-8bd3-78978edbc564', '7c8e4442-e13e-485a-8993-b05ca110410d', '8a35fe01-8450-4726-a9b3-b61b7a967475', '929346a2-8037-4b14-af33-4820eb365323', '92d68971-8cc2-480b-8e29-9938f7a280f1', '9c64b145-cce4-4b31-a4e0-c041a12af62b', '9d34705c-0a66-4c08-8936-7e63629ce435', 'a0e4e813-6c10-45d8-8f59-f444c6747b61', 'a24baf50-54d3-4319-9bfb-f354c3f5ca03', 'a9e04e1e-92d4-44e4-a411-b6fe4814290a', 'b3231976-f6f0-4f7f-960e-4ba5cdac9700', 'b9c5dd29-eeb5-4903-af31-d4ab09041b0a', 'bc313a82-8b30-4ca7-acdb-47d2cc6906e3', 'c0ba9af7-714c-44c7-a3e4-abf735fb0ad9', 'c2eac407-10ce-4f4e-8796-1acb3feb42ac', 'c36e6f78-4828-49cd-9010-988c8a7c7be4', 'c62e5d6a-0115-4f2d-9084-b0c3980e6db4', 'c6a65ddf-9c48-4683-9100-28ce1c9f7983', 'ddb4ff9a-d17a-4db7-9d70-b326aaf72e05', 'dee11bee-c034-49b1-ba4c-30f94622ddd3', 'e9abe848-ca92-4197-924d-294e7ed92100', 'e9b9877d-c4dc-482e-b52a-cd015a4a6850', 'ee18fc57-9d65-4f6a-a376-035539ff3e79', 'ef936b01-3409-4b17-96ff-48b08c3cfdea', 'f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'f72689da-fe02-4bdd-977f-bb7760a42fb2', 'fbec8ba0-4a3c-4704-b4a5-9cddc42a3635')
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers x WHERE x.politician_id = p.id);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'unexpectedly emptied: %', v_bad; END IF;
END $$;

COMMIT;
