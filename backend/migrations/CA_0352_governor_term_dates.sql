BEGIN;

-- =============================================================================
-- CA_0352: date the other 49 governor terms (first day in office), and set Utah Governor's state
-- =============================================================================
-- Why: the LegiScan signing line (src/lib/legiscanEvidence.ts, heldGovernorship) ties "Signed by the
-- Governor" to a politician only through a DATED governor term covering the signing day, matched on
-- offices.representing_state (src/lib/governorTerms.ts). Migration 1459 backfilled every governor term
-- undated (term_start NULL, start_precision 'unknown'). CA_0340 dated Indiana (Braun) alone. This dates
-- the remaining 49, so a future governor-signing seat in any state can verify.
-- Chris Andrews, 2026-11-03: governor terms open item; "First day in office" (one row covers an
-- unbroken run of service, so re-election does not start a new row); Utah: "Yes, set UT here".
--
-- What term_start means here: the day the person's CURRENT UNBROKEN RUN as that state's governor began
-- (not the latest re-inauguration). how_started: 'succeeded' for the six who moved up mid-term
-- (AL Ivey, IA Reynolds, NY Hochul, RI McKee, SC McMaster, SD Rhoden); 'elected' for the rest.
--
-- Sources (each row's `source` names both; all fetched 2026-11-03 and the date string checked on the
-- page by script): an official state page (or statute) and the National Governors Association page.
-- Conflicts found and how they were settled:
--   * AL Ivey: the NGA governor page says 2017-04-19; governor.alabama.gov ("On April 10, 2017, Governor
--     Ivey was sworn in as the 54th Governor") and the NGA roster PDF both say 2017-04-10. Used 04-10.
--   * IA Reynolds: the NGA governor page says 2017-05-27; the NGA roster PDF ("became governor on May 24,
--     2017") and the Iowa Publications oath-of-office record (file dated 05242017) say 05-24. Used 05-24.
--   * NV Lombardo: NRS 223.030 (oath on the first Monday of January = 2023-01-02) and NGA say 01-02; the
--     Nevada State Library governors list says 2023-01-03. Used 01-02 (the statutory day).
--   * SD Rhoden: the governor resigned and the office passed to him on 2025-01-25 (S.D. Const. art. IV
--     sec. 6; NGA 01-25); governor.sd.gov says he took the oath on January 27. Chris Andrews, 2026-11-03:
--     "Jan 25". The oath day is recorded in the source.
--   * ND Armstrong took office early, 2024-12-15 (NGA), not on the usual January date.
--
-- Writes, per row: term_start, start_precision 'day', how_started, source appended. term_end stays NULL
-- (all are serving). And offices.representing_state = 'UT' on the Utah Governor office only (its
-- district already says UT; it was the one governor office with the field empty). The other four Utah
-- statewide offices (AG, Lt Gov, Auditor, Treasurer) are also empty; left alone here.
-- Idempotent: a re-run matches rows already dated with the same day and changes nothing.
-- =============================================================================

CREATE TEMP TABLE gov_dates (term_id uuid, politician_id uuid, full_name text, st text,
                             term_start date, how_started text, src text) ON COMMIT DROP;
INSERT INTO gov_dates VALUES
  ('502e3489-d9a6-4c7a-924b-a1498205dec1'::uuid, '33a51039-958f-40c2-974f-e04ea064b419'::uuid, 'Mike Dunleavy', 'AK', DATE '2018-12-03', 'elected', 'term_start 2018-12-03 (first day in office, elected): https://gov.alaska.gov/governor-dunleavy-takes-the-oath-of-office-to-become-alaskas-12th-governor/ and https://www.nga.org/governors/alaska/, read 2026-11-03 (CA_0352)'),
  ('0509651e-f555-4273-8189-217ac2c82d9d'::uuid, 'fd26d6ce-979e-4485-9e35-7d4c179c3c4c'::uuid, 'Kay Ivey', 'AL', DATE '2017-04-10', 'succeeded', 'term_start 2017-04-10 (first day in office, succeeded): https://governor.alabama.gov/governor/ and https://www.nga.org/wp-content/uploads/2024/12/Governors-Roster.pdf, read 2026-11-03 (CA_0352)'),
  ('98f32499-7bb6-47ed-b628-4d584e2388a8'::uuid, 'b4f849ef-ce62-45ad-b5af-be0a54e3fa95'::uuid, 'Sarah Huckabee Sanders', 'AR', DATE '2023-01-10', 'elected', 'term_start 2023-01-10 (first day in office, elected): https://governor.arkansas.gov/administration/governor-sanders/ and https://www.nga.org/governors/arkansas/, read 2026-11-03 (CA_0352)'),
  ('7d22fb53-28ae-404a-826b-9eeebd91ad9b'::uuid, 'ca092ddd-8ce5-4521-bbbe-38f453650b04'::uuid, 'Katie Hobbs', 'AZ', DATE '2023-01-02', 'elected', 'term_start 2023-01-02 (first day in office, elected): https://azgovernor.gov/office-arizona-governor/news/2023/01/katie-hobbs-sworn-arizonas-24th-governor and https://www.nga.org/governors/arizona/, read 2026-11-03 (CA_0352)'),
  ('8b362604-890b-4b61-961a-be0ecea6a6c5'::uuid, 'f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid, 'Gavin Newsom', 'CA', DATE '2019-01-07', 'elected', 'term_start 2019-01-07 (first day in office, elected): https://governors.library.ca.gov/40-newsom.html and https://www.nga.org/governors/california/, read 2026-11-03 (CA_0352)'),
  ('fd42cfa7-2c1b-4f40-b4a5-9473a3de37ad'::uuid, 'ea2ea8af-7b16-48da-a70f-9752b0ca0db8'::uuid, 'Jared Polis', 'CO', DATE '2019-01-08', 'elected', 'term_start 2019-01-08 (first day in office, elected): https://governorsoffice.colorado.gov/governor/news/governor-polis-marks-2-years-office and https://www.nga.org/governors/colorado/, read 2026-11-03 (CA_0352)'),
  ('f6ce4b6e-9cf0-4cff-a6d4-ce50a5d989ea'::uuid, 'eca2c4af-c882-42f6-bcb9-e656e1264758'::uuid, 'Ned Lamont', 'CT', DATE '2019-01-09', 'elected', 'term_start 2019-01-09 (first day in office, elected): https://portal.ct.gov/governor/knowledge-base/articles/about-governor-lamont/governor-lamont-biography and https://www.nga.org/governors/connecticut/, read 2026-11-03 (CA_0352)'),
  ('f1e47a4a-7b35-44e9-8d10-d6c420bc5b1a'::uuid, '8c54630e-3054-468b-a686-96da6b9ba814'::uuid, 'Matt Meyer', 'DE', DATE '2025-01-21', 'elected', 'term_start 2025-01-21 (first day in office, elected): https://news.delaware.gov/2025/01/21/mathew-s-meyer-sworn-in-as-the-76th-governor-of-the-state-of-delaware/ and https://www.nga.org/governors/delaware/, read 2026-11-03 (CA_0352)'),
  ('ac099dc7-5c8f-40f7-8207-164042a332c8'::uuid, '358d0829-8d2b-46ea-9af2-251f48960014'::uuid, 'Ron DeSantis', 'FL', DATE '2019-01-08', 'elected', 'term_start 2019-01-08 (first day in office, elected): https://www.flgov.com/eog/leadership/open-government and https://www.nga.org/governors/florida/, read 2026-11-03 (CA_0352)'),
  ('a4848351-e84f-4915-b981-cddf94a738e5'::uuid, 'd76a1a8b-5316-4e84-b64b-e66843c4763b'::uuid, 'Brian Kemp', 'GA', DATE '2019-01-14', 'elected', 'term_start 2019-01-14 (first day in office, elected): https://gov.georgia.gov/executive-action/executive-orders/2019-executive-orders (first orders dated 01.14.19) and https://www.nga.org/governors/georgia/, read 2026-11-03 (CA_0352)'),
  ('6e7ad4da-db1f-4e55-a39d-338c821a8eec'::uuid, '76307cf7-47dd-4b0a-ac4b-ed218095bf47'::uuid, 'Josh Green', 'HI', DATE '2022-12-05', 'elected', 'term_start 2022-12-05 (first day in office, elected): https://governor.hawaii.gov/featured/hawaii-begins-a-new-chapter-with-inauguration-of-governor-josh-b-green-m-d/ and https://www.nga.org/governors/hawaii/, read 2026-11-03 (CA_0352)'),
  ('400f947e-7599-4b2a-9aed-373dd3f77aa4'::uuid, '108874f4-314b-44fc-83df-31eea167064b'::uuid, 'Kim Reynolds', 'IA', DATE '2017-05-24', 'succeeded', 'term_start 2017-05-24 (first day in office, succeeded): https://www.nga.org/wp-content/uploads/2024/12/Governors-Roster.pdf and https://publications.iowa.gov/24264 (oath-of-office speech, file dated 05242017), read 2026-11-03 (CA_0352)'),
  ('0fac25f2-857a-4e50-a306-17ee9872953f'::uuid, 'd36ab4ef-dbf4-4b60-9f8b-db497dfb5de4'::uuid, 'Brad Little', 'ID', DATE '2019-01-07', 'elected', 'term_start 2019-01-07 (first day in office, elected): https://gov.idaho.gov/past-governors/ and https://www.nga.org/governors/idaho/, read 2026-11-03 (CA_0352)'),
  ('184f27c3-8de1-49e7-bf56-d17d9e478fa7'::uuid, '557dc739-3701-443c-ab97-7d9c5c3d40db'::uuid, 'JB Pritzker', 'IL', DATE '2019-01-14', 'elected', 'term_start 2019-01-14 (first day in office, elected): https://gov.illinois.gov/ and https://www.nga.org/governors/illinois/, read 2026-11-03 (CA_0352)'),
  ('4e22aa5d-0171-4aff-8314-45f38df05606'::uuid, 'd01a39ea-94bf-4064-b3dd-56d3878aab6b'::uuid, 'Laura Kelly', 'KS', DATE '2019-01-14', 'elected', 'term_start 2019-01-14 (first day in office, elected): K.S.A. 25-313(a) https://www.kslegislature.gov/li_2020/b2019_20/statute/025_000_0000_chapter/025_003_0000_article/025_003_0013_section/025_003_0013_k/ (terms begin the second Monday in January) and https://www.nga.org/governors/kansas/, read 2026-11-03 (CA_0352)'),
  ('54c07d71-cc04-4f96-8cfa-f7906d5926df'::uuid, '2a6ca553-2e25-450c-a819-c515c7544dad'::uuid, 'Andy Beshear', 'KY', DATE '2019-12-10', 'elected', 'term_start 2019-12-10 (first day in office, elected): https://governor.ky.gov/attachments/20191210_Inaugural-Address_Gov-Beshear.pdf and https://www.nga.org/governors/kentucky/, read 2026-11-03 (CA_0352)'),
  ('77be1c02-53c8-41d8-9792-067f9c03236e'::uuid, 'c2a6cf9d-deb7-4ec7-9f97-cf300da8da6c'::uuid, 'Jeff Landry', 'LA', DATE '2024-01-08', 'elected', 'term_start 2024-01-08 (first day in office, elected): https://gov.louisiana.gov/news/governor-jeff-landry-assumes-office and https://www.nga.org/governors/louisiana/, read 2026-11-03 (CA_0352)'),
  ('83265a9f-1f76-4080-b0d1-2153659f9bd4'::uuid, '7cf1080e-6e7e-4f5b-be00-6fb170896a7c'::uuid, 'Maura Healey', 'MA', DATE '2023-01-05', 'elected', 'term_start 2023-01-05 (first day in office, elected): https://malegislature.gov/Bills/193/S1.pdf and https://www.nga.org/governors/massachusetts/, read 2026-11-03 (CA_0352)'),
  ('9bbd3100-3caa-4642-bda9-96b2281f29fc'::uuid, '21e534c8-c0c0-42f5-b52b-5eb2f246d632'::uuid, 'Wes Moore', 'MD', DATE '2023-01-18', 'elected', 'term_start 2023-01-18 (first day in office, elected): https://msa.maryland.gov/msa/mdmanual/08conoff/gov/html/msa18374.html and https://www.nga.org/governors/maryland/, read 2026-11-03 (CA_0352)'),
  ('c4132dc6-bcb0-40f1-b26d-47adc4012ede'::uuid, 'baffe39e-4bf9-4956-9d59-92fe8d473fd8'::uuid, 'Janet T. Mills', 'ME', DATE '2019-01-02', 'elected', 'term_start 2019-01-02 (first day in office, elected): https://www.maine.gov/governor/mills/about and https://www.nga.org/governors/maine/, read 2026-11-03 (CA_0352)'),
  ('9accc698-715c-4732-906c-de9f6111aeb0'::uuid, 'a4a239ad-98ab-4fa9-9d56-7781f46821a4'::uuid, 'Gretchen Whitmer', 'MI', DATE '2019-01-01', 'elected', 'term_start 2019-01-01 (first day in office, elected): https://www.michigan.gov/whitmer/news/press-releases/2018/12/19/whitmer-to-be-sworn-in-as-michigans-49th-governor-announces-inauguration-event-schedule and https://www.nga.org/governors/michigan/, read 2026-11-03 (CA_0352)'),
  ('855e4e8e-0129-4fe3-86ce-e5b68449c905'::uuid, 'd9b4d757-aa43-458d-9ecc-973338bceee4'::uuid, 'Tim Walz', 'MN', DATE '2019-01-07', 'elected', 'term_start 2019-01-07 (first day in office, elected): https://www.lrl.mn.gov/mngov/govbio?govid=44 and https://www.nga.org/governors/minnesota/, read 2026-11-03 (CA_0352)'),
  ('a58dce89-127b-4727-bf15-3b8d4765ea66'::uuid, '48b91703-7fda-4995-9ebb-de3146d24e1d'::uuid, 'Mike Kehoe', 'MO', DATE '2025-01-13', 'elected', 'term_start 2025-01-13 (first day in office, elected): https://governor.mo.gov/press-releases/archive/mike-kehoe-sworn-58th-governor-missouri and https://www.nga.org/governors/missouri/, read 2026-11-03 (CA_0352)'),
  ('4c33918c-9494-4148-bd07-0af608b64de5'::uuid, 'a0ae5161-c204-47ab-a858-4a685ec51613'::uuid, 'Tate Reeves', 'MS', DATE '2020-01-14', 'elected', 'term_start 2020-01-14 (first day in office, elected): https://billstatus.ls.state.ms.us/documents/2020/html/HC/HC0001IN.htm and https://www.nga.org/governors/mississippi/, read 2026-11-03 (CA_0352)'),
  ('95f5a888-8e91-4285-b560-2b7d2e787d86'::uuid, '1021e185-125e-4004-91bb-436a9727e4a9'::uuid, 'Greg Gianforte', 'MT', DATE '2021-01-04', 'elected', 'term_start 2021-01-04 (first day in office, elected): https://news.mt.gov/Governors-Office/gianforte-sworn-in-as-montanas-25th-governor and https://www.nga.org/governors/montana/, read 2026-11-03 (CA_0352)'),
  ('b4bac799-9370-4c57-b8b0-32070479eb8c'::uuid, '05889a4f-f4e5-4fb3-87a4-984bc9c23131'::uuid, 'Josh Stein', 'NC', DATE '2025-01-01', 'elected', 'term_start 2025-01-01 (first day in office, elected): https://governor.nc.gov/news/press-releases/2025/01/01/josh-stein-sworn-north-carolinas-76th-governor and https://www.nga.org/governors/north-carolina/, read 2026-11-03 (CA_0352)'),
  ('8023af46-95b2-4258-82da-0dd3918004bc'::uuid, '7544a9ec-53aa-4ed1-86a3-5f5f4d399544'::uuid, 'Kelly Armstrong', 'ND', DATE '2024-12-15', 'elected', 'term_start 2024-12-15 (first day in office, elected): https://www.governor.nd.gov/news/armstrong-takes-oath-office-begins-term-34th-governor-north-dakotas-135-year-history and https://www.nga.org/governors/north-dakota/, read 2026-11-03 (CA_0352)'),
  ('3abcadab-681e-499c-841c-00112fe56897'::uuid, '5751ccd5-8b7a-4ce4-9247-e308c703a809'::uuid, 'Jim Pillen', 'NE', DATE '2023-01-05', 'elected', 'term_start 2023-01-05 (first day in office, elected): https://update.legislature.ne.gov/?p=32896 and https://www.nga.org/governors/nebraska/, read 2026-11-03 (CA_0352)'),
  ('37d1da3f-2fba-4810-bf92-606e2ea2a88f'::uuid, '13d45047-8183-46bd-a04a-5f5420b710cc'::uuid, 'Kelly Ayotte', 'NH', DATE '2025-01-09', 'elected', 'term_start 2025-01-09 (first day in office, elected): https://gc.nh.gov/house/calendars_journals/Journals/2025/HJ%2003%20January%209,%202025.PDF and https://www.nga.org/governors/new-hampshire/, read 2026-11-03 (CA_0352)'),
  ('fd8842de-0e4d-45c1-ad4c-778f4d6aa01b'::uuid, '6609f174-6c1e-4fe9-afe6-2ed20f5f2463'::uuid, 'Mikie Sherrill', 'NJ', DATE '2026-01-20', 'elected', 'term_start 2026-01-20 (first day in office, elected): https://www.nj.gov/governor/news/2026/approved/20260120b.shtml and https://www.nga.org/governors/new-jersey/, read 2026-11-03 (CA_0352)'),
  ('ce54b0f8-153b-4f6f-b5da-42ab1f567d50'::uuid, 'd23c3cc7-61e8-4dc3-8a5a-9347546dc0f2'::uuid, 'Michelle Lujan Grisham', 'NM', DATE '2019-01-01', 'elected', 'term_start 2019-01-01 (first day in office, elected): https://www.governor.state.nm.us/2019/01/01/governor-lujan-grisham-sworn-in/ and https://www.nga.org/governors/new-mexico/, read 2026-11-03 (CA_0352)'),
  ('8a5096cb-cf53-4578-a126-81eaefbf944a'::uuid, 'f8e66045-33cc-4f0e-ae31-58f58e148f94'::uuid, 'Joe Lombardo', 'NV', DATE '2023-01-02', 'elected', 'term_start 2023-01-02 (first day in office, elected): NRS 223.030 https://www.leg.state.nv.us/nrs/NRS-223.html (oath on the first Monday of January) and https://www.nga.org/governors/nevada/, read 2026-11-03 (CA_0352)'),
  ('75811a54-bea8-408a-b2e1-fd6166206bd7'::uuid, '90369b67-99c3-4e29-9f6c-8529350cf1eb'::uuid, 'Kathy Hochul', 'NY', DATE '2021-08-24', 'succeeded', 'term_start 2021-08-24 (first day in office, succeeded): https://www.nga.org/wp-content/uploads/2024/12/Governors-Roster.pdf and https://www.nga.org/governors/new-york/, read 2026-11-03 (CA_0352)'),
  ('d7199e8a-9094-4445-ad87-41c65af22e9f'::uuid, '9739fb00-209f-4ed0-ad06-b9d97d74ced1'::uuid, 'Mike DeWine', 'OH', DATE '2019-01-14', 'elected', 'term_start 2019-01-14 (first day in office, elected): https://governor.ohio.gov/media/news-and-media/011419 and https://www.nga.org/governors/ohio/, read 2026-11-03 (CA_0352)'),
  ('c8efc98d-cc0e-45fc-83ab-428774590642'::uuid, '7044cbb7-0669-4ecc-80a5-058a52472e4b'::uuid, 'Kevin Stitt', 'OK', DATE '2019-01-14', 'elected', 'term_start 2019-01-14 (first day in office, elected): https://oklahoma.gov/governor/newsroom/newsroom/2019/january/governor-j--kevin-stitt-inaugural-address.html and https://www.nga.org/governors/oklahoma/, read 2026-11-03 (CA_0352)'),
  ('c86e6f64-6f84-4a8a-909d-4688fba3f9da'::uuid, '66c3bd97-94d1-4287-b1b8-86605a38cb97'::uuid, 'Tina Kotek', 'OR', DATE '2023-01-09', 'elected', 'term_start 2023-01-09 (first day in office, elected): https://sos.oregon.gov/blue-book/government/pages/governor-bio.aspx and https://www.nga.org/governors/oregon/, read 2026-11-03 (CA_0352)'),
  ('676c861a-8914-4a0f-b145-521f568f3e21'::uuid, 'c3956e15-01f6-46cf-95bd-edd43f0ae8f3'::uuid, 'Josh Shapiro', 'PA', DATE '2023-01-17', 'elected', 'term_start 2023-01-17 (first day in office, elected): https://www.pa.gov/governor/newsroom/2023-press-releases/governor-shapiro-inaugural-address-as-prepared and https://www.nga.org/governors/pennsylvania/, read 2026-11-03 (CA_0352)'),
  ('4a9ddb31-3d30-47a9-90f4-6e3c564bc4ba'::uuid, '125d1783-6548-496c-9499-fbd79a0e4a4e'::uuid, 'Dan McKee', 'RI', DATE '2021-03-02', 'succeeded', 'term_start 2021-03-02 (first day in office, succeeded): https://www.rilegislature.gov/Special/comdoc/Senate%20Finance%205212020/Lieutenant%20Governor.pdf and https://www.nga.org/governors/rhode-island/, read 2026-11-03 (CA_0352)'),
  ('0e71933b-b093-4d52-9c06-d67027304218'::uuid, '3043a446-7107-4532-bd90-9f1a5a2f58a1'::uuid, 'Henry McMaster', 'SC', DATE '2017-01-24', 'succeeded', 'term_start 2017-01-24 (first day in office, succeeded): https://governor.sc.gov/news/2017-01/mcmaster-sworn-sc-governor-after-haley-resigns and https://www.nga.org/governors/south-carolina/, read 2026-11-03 (CA_0352)'),
  ('6408681f-412b-44e1-8be7-0ae2b0ea95fc'::uuid, '0a283b10-918c-4251-899b-5385c9174b6d'::uuid, 'Larry Rhoden', 'SD', DATE '2025-01-25', 'succeeded', 'term_start 2025-01-25 (first day in office, succeeded): https://www.nga.org/governors/south-dakota/ and https://governor.sd.gov/news/speeches.aspx (oath taken January 27; office passed on the governor''s resignation January 25, S.D. Const. art. IV sec. 6), read 2026-11-03 (CA_0352)'),
  ('55b6e07d-2c8d-414e-82f0-dfc1417d08f5'::uuid, 'f5b283b7-8415-47cd-9bbe-e909760a67a3'::uuid, 'Bill Lee', 'TN', DATE '2019-01-19', 'elected', 'term_start 2019-01-19 (first day in office, elected): https://capitol.tn.gov/bills/111/Senate/Journals/01192019od5.pdf and https://www.nga.org/governors/tennessee/, read 2026-11-03 (CA_0352)'),
  ('14441895-737f-4a0a-96f4-539c9a6bf652'::uuid, '8b1a1407-4774-41c1-80f4-193a401d3c86'::uuid, 'Greg Abbott', 'TX', DATE '2015-01-20', 'elected', 'term_start 2015-01-20 (first day in office, elected): https://lrl.texas.gov/legeleaders/governors/govPage.cfm?governorID=45 and https://www.nga.org/governors/texas/, read 2026-11-03 (CA_0352)'),
  ('6679a466-e801-4c1a-8287-83b0c01129be'::uuid, 'b86213f8-abd8-46e7-80b6-3ae7bd2bf1a6'::uuid, 'Spencer J. Cox', 'UT', DATE '2021-01-04', 'elected', 'term_start 2021-01-04 (first day in office, elected): https://governor.utah.gov/press/inauguration-2021-gov-spencer-cox-lt-gov-deidre-henderson-and-other-statewide-elected-officials-take-the-oath-of-office-at-tuacahn-center-of-the-arts/ and https://www.nga.org/governors/utah/, read 2026-11-03 (CA_0352)'),
  ('81c9d21c-ca89-4935-85b3-1f3e15fdf7e1'::uuid, '46c6ebb0-137a-46aa-b6fa-17af31aa4ef1'::uuid, 'Abigail Spanberger', 'VA', DATE '2026-01-17', 'elected', 'term_start 2026-01-17 (first day in office, elected): https://uncommonwealth.lva.virginia.gov/blog/2026/01/14/taking-office/ and https://www.nga.org/governors/virginia/, read 2026-11-03 (CA_0352)'),
  ('487dbcf9-f8e7-416f-b5fc-a62534033fe0'::uuid, '963f2c91-9563-444e-9487-91822cd3e6cf'::uuid, 'Phil Scott', 'VT', DATE '2017-01-05', 'elected', 'term_start 2017-01-05 (first day in office, elected): https://legislature.vermont.gov/statutes/section/03APPENDIX/003/00076 and https://www.nga.org/governors/vermont/, read 2026-11-03 (CA_0352)'),
  ('a88fd384-4132-4ca7-a58b-cd18d838813e'::uuid, 'b8427e5d-f570-45bd-945f-c192e78b4d12'::uuid, 'Bob Ferguson', 'WA', DATE '2025-01-15', 'elected', 'term_start 2025-01-15 (first day in office, elected): https://governor.wa.gov/news/2025/governor-ferguson-signs-three-executive-orders-moments-after-inauguration and https://www.nga.org/governors/washington/, read 2026-11-03 (CA_0352)'),
  ('6538e00b-b203-4cb6-a954-475ff642a1e7'::uuid, '0ef0cb58-09c9-4c21-b81e-5b676cae23f8'::uuid, 'Tony Evers', 'WI', DATE '2019-01-07', 'elected', 'term_start 2019-01-07 (first day in office, elected): https://evers.wi.gov/Pages/Newsroom/Press-Releases/010719-Governor-Evers-Sworn-in.aspx and https://www.nga.org/governors/wisconsin/, read 2026-11-03 (CA_0352)'),
  ('e65016ee-0a66-4b24-9a70-afe0f0525baa'::uuid, 'af0e81ec-b2dd-42eb-80b9-aa73c62c2741'::uuid, 'Patrick Morrisey', 'WV', DATE '2025-01-13', 'elected', 'term_start 2025-01-13 (first day in office, elected): https://governor.wv.gov/about-us and https://www.nga.org/governors/west-virginia/, read 2026-11-03 (CA_0352)'),
  ('6f7b00ac-0129-4dec-a1ac-5739003e6ca7'::uuid, '163b9f2f-8170-4d5a-947d-ef5a3c8fb4c8'::uuid, 'Mark Gordon', 'WY', DATE '2019-01-07', 'elected', 'term_start 2019-01-07 (first day in office, elected): https://wyospcr.wyo.gov/index.php/administration/boards-commissions/commissioners/139-spcr/commissioners/252-governor-mark-gordon and https://www.nga.org/governors/wyoming/, read 2026-11-03 (CA_0352)')
;

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM gov_dates;
  IF v_n <> 49 THEN RAISE EXCEPTION 'CA_0352: pre-flight — expected 49 rows, got %', v_n; END IF;
  -- Every row must be that person's open governor term in that state, undated or already on the same day.
  SELECT count(*) INTO v_n FROM gov_dates g
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.office_terms t
       JOIN essentials.offices o ON o.id = t.office_id
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.politicians p ON p.id = t.politician_id
      WHERE t.id = g.term_id AND p.id = g.politician_id AND p.full_name = g.full_name
        AND o.role_canonical = 'governor' AND d.state = g.st
        AND COALESCE(o.representing_state, g.st) = g.st
        AND t.term_end IS NULL
        AND (t.term_start IS NULL OR t.term_start = g.term_start));
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0352: pre-flight — % row(s) do not match an open governor term as expected', v_n; END IF;
  -- Each office has only this one term: nothing to trim or overlap.
  SELECT count(*) INTO v_n FROM gov_dates g
    JOIN essentials.office_terms t ON t.id = g.term_id
    JOIN essentials.office_terms t2 ON t2.office_id = t.office_id AND t2.id <> t.id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0352: pre-flight — % governor office(s) have another term row; reconcile first', v_n; END IF;
END $$;

UPDATE essentials.office_terms t
   SET term_start = g.term_start,
       start_precision = 'day',
       how_started = g.how_started,
       source = CASE WHEN t.source IS NULL OR t.source = '' THEN g.src ELSE t.source || ' | ' || g.src END
  FROM gov_dates g
 WHERE t.id = g.term_id
   AND t.term_start IS NULL;

UPDATE essentials.offices
   SET representing_state = 'UT'
 WHERE id = '3b1e9d4a-a68e-43df-a14a-7f3a82c40c3d'
   AND role_canonical = 'governor' AND title = 'Utah Governor'
   AND representing_state IS NULL;

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM gov_dates g JOIN essentials.office_terms t ON t.id = g.term_id
   WHERE t.term_start = g.term_start AND t.start_precision = 'day' AND t.how_started = g.how_started
     AND t.term_end IS NULL AND t.source LIKE '%(CA_0352)%';
  IF v_n <> 49 THEN RAISE EXCEPTION 'CA_0352: post-verify — % of 49 terms dated', v_n; END IF;
  -- All 50 governor offices now carry a state and a dated open term.
  SELECT count(*) INTO v_n FROM essentials.offices o JOIN essentials.office_terms t ON t.office_id = o.id
   WHERE o.role_canonical = 'governor' AND o.representing_state IS NOT NULL
     AND t.term_start IS NOT NULL AND t.term_end IS NULL;
  IF v_n <> 50 THEN RAISE EXCEPTION 'CA_0352: post-verify — % of 50 governor offices dated with a state', v_n; END IF;
END $$;

COMMIT;
