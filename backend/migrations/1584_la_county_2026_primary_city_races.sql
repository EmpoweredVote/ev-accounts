-- 1584_la_county_2026_primary_city_races.sql
--
-- Record outcomes for the 2026-06-02 LA County city contests that are safe to record: 97 candidate
-- rows across 26 races in Avalon, Covina, Glendale, Pasadena, Long Beach and Los Angeles City.
--
--   Rollback: UPDATE essentials.race_candidates SET result=NULL, result_source=NULL,
--                    result_recorded_at=NULL WHERE id IN (<the 97 ids below>);
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1584_la_county_2026_primary_city_races.sql`.
--
-- Source: LA County RR/CC certified results, June 2 2026 Statewide Direct Primary
--         (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07).
--
-- ---------------------------------------------------------------------------------------------------
-- 🔑 TWO DIFFERENT RULES, AND THE BALLOT TITLE IS WHAT DISTINGUISHES THEM
-- ---------------------------------------------------------------------------------------------------
-- These cities did not all hold the same kind of election, and the contest titles say so:
--
--   "GENERAL MUNICIPAL ELECTION"  (Avalon, Covina, Glendale) — a FINAL election. Highest vote total
--                                 wins, majority irrelevant. Top N win where the seat count is N.
--   "PRIMARY NOMINATING ELECTION" (Pasadena, Long Beach, Los Angeles) — >50% wins outright, otherwise
--                                 the top two advance to a November runoff.
--
-- Applying the wrong rule silently inverts outcomes. Victor Linares took Covina District 3 with
-- 42.54% — under the primary rule that is a runoff, but Covina held a GENERAL, so he is elected.
-- Timothy Gaspar led Los Angeles Council District 3 with 46.08% — under the general rule that is a
-- win, but Los Angeles held a PRIMARY, so he is only in a runoff. Neither is a close call once the
-- title is read; both are wrong if it is not.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 SIX RACES DELIBERATELY EXCLUDED — DUPLICATE CANDIDATE ROWS
-- ---------------------------------------------------------------------------------------------------
-- 32 of this election's 278 rows are duplicates of another row in the same race:
--
--   Beverly Hills City Council ..... Sharona R. Nazarian ×5 (two name forms), Clayton M. Saunders ×4,
--                                    John A. Mirisch ×3, Lester Friedman ×2
--   Beverly Hills City Treasurer ... Howard S. Fisher ×4
--   Glendale City Clerk ............ Susan Wolfson ×2, Suzie Abajian ×2
--   Glendale City Treasurer ........ Rafi Manoukian ×2
--   Pomona Council D2/D3/D5 ........ Preciado, Garcia, Cabrera, Rothman, Cobarrubias ×2 each
--   Covina City Treasurer .......... 'Thomas "TJ" Nass' and 'Thomas Nass'
--
-- Writing results onto these would produce FIVE winners of a three-seat Beverly Hills council. The
-- rows are not wrong about who ran — they are the same candidacy stored repeatedly — so a result on
-- each is individually true and collectively nonsense. Dedupe has to come first.
--
-- ⚠️ The Covina Treasurer pair is the one my own duplicate query MISSED: normalising on punctuation
-- and honorifics does not collapse a quoted nickname, so 'Thomas "TJ" Nass' and 'Thomas Nass' looked
-- like different people. The 32-row count is therefore a FLOOR, not a total. Any dedupe pass should
-- match on last name + race, not on a normalised full string.
--
-- ▶ FOLLOW-UP OWED: dedupe those races, then record their results (all six are decided and the
--   certified numbers are in the source above).
--
-- Also excluded: Long Beach City Attorney (Dawn McIntosh) and City Prosecutor (Doug Haubert). Neither
-- contest appears anywhere in the certified results — Long Beach reported an Auditor, a Mayor and
-- five council districts and nothing else — so these two seats were not on the June ballot at all.
-- Recording "lost" or "not_nominated" would both be false; they need to be checked against the
-- Long Beach City Clerk's own election calendar.
-- ---------------------------------------------------------------------------------------------------

-- ===================================================================================================
-- WON
-- ===================================================================================================
UPDATE essentials.race_candidates SET result='won', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). GENERAL municipal election — highest vote total is elected; no majority required.'
 WHERE id IN (
  '97e00c21-eed4-4d1a-a5ee-be2093321f7e',  -- Anni Marshall      Avalon Mayor        402  43.93%
  '080d71d0-10ea-447a-a37b-5112d1844272',  -- Michael Ponce      Avalon Council      487  31.42%  (2 seats)
  'f475f4cc-8170-4656-a6ee-11619bb74836',  -- Donna Lopez        Avalon Council      433  27.94%  (2 seats)
  'f4b5de30-77fd-46be-ab6d-43daabeb443f',  -- Susan Zermeno      Covina Clerk      5,439  52.73%
  '96bc6364-7abe-4273-b658-afefeeba1ce5',  -- Hector Delgado     Covina D1         1,575 100.00%
  '76f06981-a0e9-4086-95d8-2a13505d67de',  -- Victor Linares     Covina D3         1,086  42.54%  (general: plurality wins)
  '5ff15564-e1fc-448e-aafd-bee7b83e4585',  -- Andrew Aleman      Covina D5         1,343  59.14%
  '6f4994bf-4f97-4ef2-b68f-b8618f522d40',  -- Dan Brotman        Glendale Council 19,063  17.85%  (3 seats)
  '102357a8-4e9d-4377-adff-06efed563ce2',  -- Elen Asatryan      Glendale Council 17,358  16.25%  (3 seats)
  '7234d555-d0cf-4f12-98d2-f55adfb00ece'   -- Alek Bartrosouf    Glendale Council 15,420  14.44%  (3 seats)
 );

UPDATE essentials.race_candidates SET result='won', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). PRIMARY NOMINATING election — took more than 50% and is elected outright, avoiding the November runoff.'
 WHERE id IN (
  '417c5307-88d6-419c-8837-34180cdf64b9',  -- Justin Jones        Pasadena D3      3,065  76.70%
  'a109f1a6-8920-4242-ba81-0cbd95389929',  -- Jess Rivas          Pasadena D5      3,444 100.00%
  '0c03f294-b0b1-4f6d-81ff-4f59d8647a90',  -- Jason Lyon          Pasadena D7      5,184  84.31%
  'e67aa776-3760-4973-9998-64f0e25087b8',  -- Laura Doud          LB Auditor      65,572  70.53%
  '70e076fe-bc5b-4826-91b9-97b6bbb396d5',  -- Rex Richardson      LB Mayor        57,843  57.40%
  '6160989c-cf55-4a29-9d21-1251a335ebfe',  -- Mary Zendejas       LB D1            3,678  50.21%
  '37543904-3552-41f9-b1b4-8ab42e09d30b',  -- Kristina Duggan     LB D3           10,502  63.98%
  '2c2d2293-6736-4123-b848-694165a7cb8c',  -- Megan Kerr          LB D5           10,564  53.96%
  '6c3e132c-5b94-40b7-9615-dd92b1fb137c',  -- Vivian Malauulu     LB D7            6,015  74.12%
  'd3f1dde9-2bef-4c9d-96a0-5d99e8bcf4b3',  -- Joni Ricks-Oddie    LB D9            4,460  67.97%
  '1e6792a5-a940-449d-847b-b6391c44c04e',  -- Kenneth Mejia       LA Controller  473,226  63.02%
  '2764ec66-7020-4c5a-ae20-fa12a531f9dd',  -- Eunisses Hernandez  LA CD1          21,713  57.69%
  'ce08fd8b-52a8-41c7-b736-baa9f9518825',  -- Katy Yaroslavsky    LA CD5          45,177  64.15%
  'cf77e14b-141b-4d82-981f-f19dfa7efcec',  -- Monica Rodriguez    LA CD7          34,804 100.00%
  '1cd883b9-894a-41ba-b412-0cd61e7b2bed',  -- Traci Park          LA CD11         51,966  60.23%
  'cbc67914-2bcc-48bb-93da-78dfb65e702d',  -- Hugo Soto-Martinez  LA CD13         38,786  68.42%
  '3cd510ce-528d-4d96-9c22-9cff125826cc'   -- Tim McOsker         LA CD15         28,825  76.55%
 );

-- ===================================================================================================
-- RUNOFF (primary nominating election, no majority, top two)
-- ===================================================================================================
UPDATE essentials.race_candidates SET result='runoff', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). PRIMARY NOMINATING election — no candidate reached 50%; this candidate finished top two and advances to the November 3 2026 runoff.'
 WHERE id IN (
  'ec3666d5-1b21-4e39-94a8-22f7bdc024f6',  -- Marissa Roy         LA City Attorney 320,771  43.12%
  'caec4b5d-60d4-4317-8cc1-ab1713b4f082',  -- John McKinney       LA City Attorney 212,754  28.60%
  '595258e7-42c1-4797-9974-def3d75c6230',  -- Timothy Gaspar      LA CD3            22,266  46.08%
  '01cee35c-60b1-4882-b60b-251fd0aa23aa',  -- Barri Worth Girvan  LA CD3            20,541  42.51%
  '6720025b-191f-4998-8f62-88dc034be7cd',  -- Jose Ugarte         LA CD9             8,054  39.45%
  '46bdb945-1b7d-49b5-bbc2-ee62034970fa'   -- Estuardo Mazariegos LA CD9             5,351  26.21%
 );

-- ===================================================================================================
-- LOST
-- ===================================================================================================
UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07).'
 WHERE id IN (
  '74105328-5701-4072-a535-55a6b3c03909',  -- Cinde Cassidy          Avalon Mayor       225  24.59%
  'b5fb7863-1e0b-4a1b-9b35-62836fdc9de7',  -- Grayson Kline          Avalon Mayor       206  22.51%
  '2abfef61-1926-4494-97ae-521bbc749f2f',  -- Daniel Felts           Avalon Mayor        82   8.96%
  '06b6d8f2-52d0-4e0d-a1f4-f34dee3d008a',  -- Jessica Romero         Avalon Council     387  24.97%
  'd83800de-7aee-4d4f-bc30-dba8ae980711',  -- Bre Bussard            Avalon Council     243  15.68%
  'da7e7704-8f27-4bcd-b419-e3ee6a2598e5',  -- Rosie Richardson       Covina Clerk     4,875  47.27%
  '0d7d2b8c-e45b-4fbb-a437-c29ac3ff2871',  -- Adrian Fernandez       Covina D3          901  35.29%
  '679a653a-ecb6-4534-b4aa-91159bed4b12',  -- Sarah Rizvi            Covina D3          566  22.17%
  '363ca958-60fd-405c-9eb4-596630cdc130',  -- Bri Serrano            Covina D5          928  40.86%
  'd23526c5-fe4a-4c10-915b-59911ac440c9',  -- Patrick Murphy         Glendale Council 11,822  11.07%
  'f591c7ac-8f1d-474b-8005-34b5aa3fc3ef',  -- Alex Balekian          Glendale Council 10,968  10.27%
  '73ef9835-89cf-4372-b5e8-ee8ad447b9b2',  -- Beth Brooks            Glendale Council  8,258   7.73%
  '905be15e-1f94-4659-a106-fe2653afd228',  -- Vrej Agajanian         Glendale Council  6,394   5.99%
  '3357da78-b56f-42fb-b93e-c41731895264',  -- Carolyn Kaloostian     Glendale Council  5,190   4.86%
  'f8a7ee1f-e10c-41a5-921e-f0cde2dbac59',  -- Evelina Sarian         Glendale Council  5,072   4.75%
  'cf7bc4a8-200e-43a9-a095-84921c067452',  -- Ronnie Gharibian       Glendale Council  3,722   3.48%
  'd6e4b659-1092-4b4c-8078-750d40920c8e',  -- Gevorg Grigoryan       Glendale Council  2,103   1.97%
  'ab84b674-bdef-41f9-86db-119f7538c453',  -- Davit Mnatsakanyan     Glendale Council  1,431   1.34%
  '89bee32f-61c5-41bb-b030-737584a13124',  -- Erica Margarita Munoz  Pasadena D3        931  23.30%
  'b4b474e6-91a5-44f1-9e14-f9a9788ec175',  -- Alethea O'Toole        Pasadena D7        965  15.69%
  'fe29d50f-8bda-494f-ae28-46d6852ef48d',  -- Ginny Gonzales         LB Auditor      27,396  29.47%
  '0ff3cb54-814d-406b-b3fb-d6c8e2410058',  -- Joshua Rodriguez       LB Mayor        17,657  17.52%
  '9859f487-6803-4d45-913e-3060765259a6',  -- Chris Sweeney          LB Mayor         9,739   9.66%
  'fdcf21e3-f912-4a5e-a054-ef008457d9c9',  -- Lee Goldin             LB Mayor         7,122   7.07%
  '13257c28-e9f5-4913-9e5c-8c3aaacee003',  -- Terri Rivers           LB Mayor         5,485   5.44%
  '8ff84ca6-8ff1-4910-ab3c-0383e20c763f',  -- Oscar Cancio           LB Mayor         2,929   2.91%
  '34e28c14-4f5a-4869-ab51-1506dc954cff',  -- Anthony Bryson         LB D1            1,300  17.75%
  'ee883380-f9b6-464c-ae18-df0d3a2c7b42',  -- Deb Kahookele          LB D1              939  12.82%
  '53de0aae-ea53-4eaf-8f06-07ea89b1711c',  -- Tamika Wagner-Osio     LB D1              882  12.04%
  'bcc670d8-6f41-4e39-8c6d-f4a1241590e6',  -- Brock Goleman          LB D1              277   3.78%
  '315065cf-37ed-422f-b658-b57a3b2b30fa',  -- Lori Logan             LB D1              249   3.40%
  'cca21515-e677-4e31-8a10-071ca049fe9f',  -- Rebecca Hinderer       LB D3            4,259  25.95%
  'a7591044-0b14-476b-805a-0dd22e92f8cf',  -- Ronald Sampson         LB D3            1,291   7.86%
  '6f9ad60c-7e12-4459-89fc-e7a41f36701d',  -- Brian Cochrane         LB D3              363   2.21%
  'a4379352-30e7-4133-8aed-2cea257e5517',  -- Tara Riggi             LB D5            9,014  46.04%
  '2997fcee-447f-4daa-b077-915e3a547b0d',  -- Dameon Gordon          LB D7            1,546  19.05%
  'ee83404f-ae2f-4b01-8842-0969004b45af',  -- Jamies Shuford         LB D7              554   6.83%
  '541a12e0-848b-482e-a77a-6502ba1a70d4',  -- Sequoia Neff           LB D9            2,102  32.03%
  'f3ec44e4-073f-48ab-be7c-279d2b1e75cb',  -- Hydee Feldstein Soto   LA City Atty   133,799  17.99%
  '688dd4cd-8b75-4935-96a4-e0aec5b345f8',  -- Aida Ashouri           LA City Atty    76,546  10.29%
  '28233f8b-6002-48df-aa5c-8fc08367a1ce',  -- Zach Sokoloff          LA Controller  277,735  36.98%
  'c1c9936c-6eab-4050-9935-dd30f22f56f7',  -- Maria Lou Calanche     LA CD1           5,980  15.89%
  '540f4014-bbeb-4d39-9dd2-af195bb9702e',  -- Raul Claros            LA CD1           3,833  10.18%
  '1cf8daaa-4ff6-4c3e-a63d-b553c485fa58',  -- Nelson Grande          LA CD1           3,322   8.83%
  'd612bfdd-4ce0-49ce-b517-9a572f73286f',  -- Sylvia Robledo         LA CD1           2,791   7.42%
  'a1a49b7b-b224-4a69-83b3-3f05df04948a',  -- C.R. Celona            LA CD3           5,512  11.41%
  'cf93edbe-1a1e-453d-b957-dcf260a255c0',  -- Henry Mantel           LA CD5          18,023  25.59%
  '961e0075-6c6f-48d3-bfc8-e4c252159595',  -- Morgan Oyler           LA CD5           7,223  10.26%
  'ff3496d6-8a4c-45d3-a43c-12e79ec2d7f1',  -- Jorge Nuno             LA CD9           2,223  10.89%
  'b281e660-08a3-48de-a132-80b190d10902',  -- Elmer Roldan           LA CD9           1,954   9.57%
  'eb71dd32-355c-4d01-89e3-2c4fec3376b0',  -- Martha Sanchez         LA CD9           1,789   8.76%
  '289d3655-644a-4bbf-aff2-294be6f9db16',  -- Jorge Hernandez Rosas  LA CD9           1,046   5.12%
  '69684464-037d-4fdd-8401-4f47e08fdb82',  -- Faizah Malik           LA CD11         34,318  39.77%
  '9f57148c-f2aa-4d5f-a757-17c2dc19b10d',  -- Dylan Kendall          LA CD13          6,788  11.97%
  '6de20cdc-14c3-4d6b-a9c3-b18c1133225c',  -- Rich Sarian            LA CD13          6,571  11.59%
  '64514329-66c3-4887-bcd4-03cf2d4a00f5',  -- Colter Carlisle        LA CD13          4,543   8.01%
  'f0d9e291-cde0-403a-bf9e-638e7067acf8'   -- Jordan Rivers          LA CD15          8,831  23.45%
 );

-- ===================================================================================================
-- NOT NOMINATED — on our roster, absent from the certified ballot
-- ===================================================================================================
UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='Absent from the certified field for this contest in the LA County RR/CC official results for the June 2 2026 primary (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). The contest is fully reported (percentages sum to 100.00%), so this is absence from the ballot rather than a truncated source.'
 WHERE id IN (
  '1022b4a2-908b-4d31-9d52-813432c36b97',  -- Amadea Botel          Glendale Council (certified field: 12 names, none is Botel)
  'b8ba142e-e6aa-4215-8157-d4b9069bc790',  -- Andre Haghverdian     Glendale Council
  '9b0fcb39-2507-4f8a-a73d-4604eaa8316a',  -- Haig Aintablian       Glendale Council
  '7ea6bbbe-c193-476b-9393-aedb58c69375',  -- April Ronay           Long Beach Mayor (certified field: 6 names)
  'ad226be7-be9d-4b5e-bb77-4d66f0da03b3',  -- Jon Rawlings          LA CD3           (certified field: Gaspar, Girvan, Celona)
  '57ae56c9-9290-4b36-9e79-251e66b566c8',  -- Lehi White            LA CD3
  '2949d902-6bba-4326-ba52-e68380045324'   -- Phillip L. Crouch Jr. LA CD15          (certified field: McOsker, Rivers)
 );

-- ---------------------------------------------------------------------------------------------------
-- NOT DONE HERE — certified candidates missing from our roster
-- ---------------------------------------------------------------------------------------------------
-- The Los Angeles City MAYOR contest has no race row at all, and it is the highest-profile result in
-- the county: Karen Ruth Bass 292,593 (34.27%) and Nithya Raman 247,781 (29.02%) are in a November
-- runoff, with Spencer Pratt third on 25.53%. Fifteen candidates, none recorded.
-- Also absent from our rosters: Long Beach Council D1 has all six certified names but LA CD9's
-- certified field is complete, so no gap there. Recorded, not seeded.
