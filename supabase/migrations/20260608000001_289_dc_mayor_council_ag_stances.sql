-- Phase 106: DC Mayor + Council + AG Stances
-- Requirements covered: DCST-01
-- Source CSV: backend/data/stance-research/2026-06-08-106-dc-mayor-council-ag.csv
-- Pre-write cross-check:
--   CSV data rows: 33
--   politician_answers row count: 33 (matches CSV)
--   politician_context row count: 33 (matches CSV)
--   All UUID literals match 15 locked DC official UUIDs
--   Doni Crawford (UUID: 0719a80b-0d23-4492-b125-f51be48c0cf7) had zero documentable stances (D-06 honest skip)
--
-- DC Official UUIDs (from backend/data/stance-research/2026-06-08-106-dc-mayor-council-ag-uuids.json):
--   Muriel Bowser                       (ext_id -600001 ) -> f0711297-5348-4f50-b8fa-10cebafe410c
--   Phil Mendelson                      (ext_id -600002 ) -> ffc08e57-d17b-484e-a829-689287c5be77
--   Anita Bonds                         (ext_id -600003 ) -> 846e83a4-ba11-4241-904e-f011108ca7c3
--   Robert C. White, Jr.                (ext_id -600004 ) -> 934c4013-9631-475d-8749-67dc942a3111
--   Christina Henderson                 (ext_id -600005 ) -> 04a0fd9a-6ed5-4f4e-93de-249081d4bdac
--   Doni Crawford                       (ext_id -600006 ) -> 0719a80b-0d23-4492-b125-f51be48c0cf7
--   Brianne K. Nadeau                   (ext_id -600007 ) -> 90f6856a-3328-43ec-8b7f-c57f4eb2e6fb
--   Brooke Pinto                        (ext_id -600008 ) -> 604a53c8-1b98-419f-8e63-cc128df4ba60
--   Matthew Frumin                      (ext_id -600009 ) -> 674babd9-9812-41f3-aeae-0c11dbb4456e
--   Janeese Lewis George                (ext_id -600010 ) -> 5744694e-1e6b-4aee-a029-6fb0f01b4aac
--   Zachary Parker                      (ext_id -600011 ) -> 6188851b-7cb7-4718-942d-49b40594386a
--   Charles Allen                       (ext_id -600012 ) -> d38df660-3481-45d2-98cb-682d0404de80
--   Wendell Felder                      (ext_id -600013 ) -> 07a70461-06e5-47b1-815b-adac316280f7
--   Trayon White, Sr.                   (ext_id -600014 ) -> acbbfc14-8fa0-4b81-8660-bf385701c160
--   Brian Schwalb                       (ext_id -600015 ) -> 00bcdb0e-8bf2-4997-9642-ed3d14a2a5f8
--
-- Migration number: 289
-- Timestamp: 20260608000001
-- Applied: NOT YET (write-only)

BEGIN;

-- ============================================================
-- INSERT BLOCK -- 33 rows (from 2026-06-08-106-dc-mayor-council-ag.csv)
-- Plain overwrite ON CONFLICT (not ARRAY_CAT) -- DC officials
-- have no prior context rows (first-time DC stance ingestion).
-- ============================================================

-- ============================================================
-- Muriel Bowser
-- ============================================================

-- ---- Muriel Bowser / local-immigration / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f0711297-5348-4f50-b8fa-10cebafe410c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'local-immigration'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f0711297-5348-4f50-b8fa-10cebafe410c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'local-immigration'),
  'Bowser reaffirmed Washington D.C.''s status as a sanctuary city following Trump''s 2017 executive order threatening to withhold federal funding from sanctuary cities. She refused to cooperate with ICE detainers and in September 2022 established the Office of Migrant Services to assist migrants arriving from Texas and Arizona. Value=1 matches ''Refuse all ICE detainers; prohibit city employees from sharing immigration status information with federal agencies.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Muriel_Bowser']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Muriel Bowser / immigration / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f0711297-5348-4f50-b8fa-10cebafe410c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f0711297-5348-4f50-b8fa-10cebafe410c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Bowser affirmed sanctuary city status and joined a partnership with the National Immigration Forum to help D.C. government green card holders and family members apply for U.S. citizenship. She has consistently supported open access to city services for immigrants regardless of legal status. Value=1 matches ''Make it easier for immigrants to come here legally and let all immigrants including undocumented residents fully use public services.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Muriel_Bowser']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Muriel Bowser / homelessness-response / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f0711297-5348-4f50-b8fa-10cebafe410c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness-response'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f0711297-5348-4f50-b8fa-10cebafe410c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness-response'),
  'Bowser pledged to end chronic homelessness and pursued a shelter-based approach placing families in motel rooms and building smaller shelters across all 8 wards. She also enforced encampment clearings in later years under pressure to address visible homelessness. Her approach invested in outreach and shelter while also enforcing public space rules. Value=3 matches ''Invest in outreach, shelter, and mental health services while enforcing reasonable public space rules.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Muriel_Bowser']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Muriel Bowser / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f0711297-5348-4f50-b8fa-10cebafe410c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f0711297-5348-4f50-b8fa-10cebafe410c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Bowser renamed the stretch of 16th Street NW in front of the White House ''Black Lives Matter Plaza'' following George Floyd''s murder and demonstrated strong public support for the BLM movement. She championed civil rights enforcement in D.C. Value=2 matches ''strengthen civil rights enforcement and address systemic discrimination.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Muriel_Bowser']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Muriel Bowser / public-safety-approach / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f0711297-5348-4f50-b8fa-10cebafe410c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'public-safety-approach'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f0711297-5348-4f50-b8fa-10cebafe410c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'public-safety-approach'),
  'Bowser supported outfitting the Metropolitan Police Department with body cameras and maintained the police budget while adding crisis response elements. She did not support defunding the police but also demonstrated support for some reform. Value=3 matches ''Keep current public safety funding while adding crisis response teams for mental health and addiction calls.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Muriel_Bowser']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Muriel Bowser / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f0711297-5348-4f50-b8fa-10cebafe410c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f0711297-5348-4f50-b8fa-10cebafe410c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Bowser invested in affordable housing initiatives including the Good Food Markets project with 195 units of affordable housing. She announced the Homeward DC strategic plan and committed to ending family homelessness through housing programs and championed inclusionary zoning. Value=2 matches ''Use rent caps, require new developments to include affordable units, and publicly fund new housing.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Muriel_Bowser']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Phil Mendelson
-- ============================================================

-- ---- Phil Mendelson / campaign-finance / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ffc08e57-d17b-484e-a829-689287c5be77',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ffc08e57-d17b-484e-a829-689287c5be77',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Mendelson received national attention for his work on the D.C. Fair Elections Act (enacted 2018) which uses public funds to match campaign contributions and requires candidates to accept lower maximum contribution limits. He has consistently championed campaign finance reform. Value=1 matches ''ban all private money in politics and publicly fund campaigns.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Phil_Mendelson']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Phil Mendelson / same-sex-marriage / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ffc08e57-d17b-484e-a829-689287c5be77',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ffc08e57-d17b-484e-a829-689287c5be77',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Mendelson received national attention for his work to advance D.C.''s same-sex marriage legalization law and worked with regional counterparts to support full marriage equality. As Council chairman he shepherded pro-equality legislation. Value=1 matches ''require all states to recognize same-sex marriages and provide full federal benefits and protections.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Phil_Mendelson']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Phil Mendelson / homelessness-response / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ffc08e57-d17b-484e-a829-689287c5be77',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness-response'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ffc08e57-d17b-484e-a829-689287c5be77',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness-response'),
  'In 2016 Mendelson overhauled Mayor Bowser''s plan to close DC General homeless shelter and shepherded an alternative plan that expanded shelter capacity and services rather than dispersing shelters without community input. Value=2 matches ''Expand shelter capacity and services as the primary strategy; use enforcement only after services are offered.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Phil_Mendelson']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Anita Bonds
-- ============================================================

-- ---- Anita Bonds / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '846e83a4-ba11-4241-904e-f011108ca7c3',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '846e83a4-ba11-4241-904e-f011108ca7c3',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Bonds introduced legislation to limit property taxes on senior citizens who have lived in D.C. for 15 consecutive years. She also attended an affordable housing roundtable in 2016. Activists protested her for mixed support of affordable housing measures. Value=3 matches ''Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Anita_Bonds']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Robert C. White, Jr.
-- ============================================================

-- ---- Robert C. White, Jr. / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '934c4013-9631-475d-8749-67dc942a3111',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '934c4013-9631-475d-8749-67dc942a3111',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'White campaigned on improving access to affordable housing and was endorsed by tenants'' rights groups. He championed using zoning laws to bring redevelopment and supported legislation ensuring affordable units in new developments. Value=2 matches ''Use rent caps, require new developments to include affordable units, and publicly fund new housing.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Robert_C._White_Jr.']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Robert C. White, Jr. / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '934c4013-9631-475d-8749-67dc942a3111',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '934c4013-9631-475d-8749-67dc942a3111',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'White is a Moms Demand Action Gun Sense Candidate and spoke at a protest against Trump''s proposed immigration bans in January 2017. He was endorsed by DC NOW, DC for Democracy, and Capital Stonewall Democrats. Value=2 matches ''strengthen civil rights enforcement and address systemic discrimination.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Robert_C._White_Jr.']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Robert C. White, Jr. / campaign-finance / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '934c4013-9631-475d-8749-67dc942a3111',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '934c4013-9631-475d-8749-67dc942a3111',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'In June 2016 White endorsed a DC campaign finance reform proposal to prohibit any person or corporation from receiving a city contract worth $100,000 or more if they donate to a city council election — one of the strictest proposals to address corruption and ethics. Value=1 matches ''ban all private money in politics and publicly fund campaigns.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Robert_C._White_Jr.']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Christina Henderson
-- ============================================================

-- ---- Christina Henderson / public-safety-approach / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '04a0fd9a-6ed5-4f4e-93de-249081d4bdac',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'public-safety-approach'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '04a0fd9a-6ed5-4f4e-93de-249081d4bdac',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'public-safety-approach'),
  'Henderson explicitly said the Metropolitan Police Department should keep its current size and stated skepticism about defunding the police. She supports mental health resources alongside policing. Value=3 matches ''Keep current public safety funding while adding crisis response teams for mental health and addiction calls.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Christina_Henderson_(politician)']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Christina Henderson / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '04a0fd9a-6ed5-4f4e-93de-249081d4bdac',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '04a0fd9a-6ed5-4f4e-93de-249081d4bdac',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Henderson said she supports tax increases on the wealthy. Value=2 matches ''Moderately raise taxes on wealthy people and large companies to fund existing services.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Christina_Henderson_(politician)']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Christina Henderson / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '04a0fd9a-6ed5-4f4e-93de-249081d4bdac',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '04a0fd9a-6ed5-4f4e-93de-249081d4bdac',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Henderson supports reforms to rent control and is documented as backing tenant protections. Value=2 matches ''Use rent caps, require new developments to include affordable units, and publicly fund new housing.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Christina_Henderson_(politician)']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Brianne K. Nadeau
-- ============================================================

-- ---- Brianne K. Nadeau / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '90f6856a-3328-43ec-8b7f-c57f4eb2e6fb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '90f6856a-3328-43ec-8b7f-c57f4eb2e6fb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Nadeau voted against a bill that would exempt all single-family homes from tenant protections of the Tenant Opportunity to Purchase Act saying it was too broad and failed to balance homeowner and renter rights. She serves on the Committee on Housing and Neighborhood Revitalization. Value=2 matches ''Use rent caps, require new developments to include affordable units, and publicly fund new housing.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Brianne_Nadeau']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Brianne K. Nadeau / campaign-finance / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '90f6856a-3328-43ec-8b7f-c57f4eb2e6fb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '90f6856a-3328-43ec-8b7f-c57f4eb2e6fb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Nadeau co-introduced the D.C. Fair Elections Act in December 2015 which uses public funds to match campaign contributions. The bill passed the DC Council and was signed into law by Mayor Bowser in March 2018. Value=1 matches ''ban all private money in politics and publicly fund campaigns.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Brianne_Nadeau']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Brianne K. Nadeau / public-safety-approach / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '90f6856a-3328-43ec-8b7f-c57f4eb2e6fb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'public-safety-approach'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '90f6856a-3328-43ec-8b7f-c57f4eb2e6fb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'public-safety-approach'),
  'Nadeau supported disbanding police Vice Squads in 2015 after a study showed 83% of those stopped were Black, facing resistance from the DC Police Union. She has consistently been critical of police practices and supported redirecting enforcement budgets. Value=1 matches ''Redirect a significant portion of the police budget to social services, mental health, and community programs.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Brianne_Nadeau']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Brianne K. Nadeau / homelessness-response / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '90f6856a-3328-43ec-8b7f-c57f4eb2e6fb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness-response'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '90f6856a-3328-43ec-8b7f-c57f4eb2e6fb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness-response'),
  'Nadeau chaired the Human Services Committee and oversaw the Homeless Services Reform Act (2018) which addressed the District''s emergency homelessness system. She focused on service-based approaches and shelter access. Value=2 matches ''Expand shelter capacity and services as the primary strategy; use enforcement only after services are offered.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Brianne_Nadeau']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Brooke Pinto
-- ============================================================

-- ---- Brooke Pinto / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '604a53c8-1b98-419f-8e63-cc128df4ba60',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '604a53c8-1b98-419f-8e63-cc128df4ba60',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Pinto introduced the HOMES Act (April 2026) which creates a housing lease-to-own program, provides a tax credit for first-time home buyers, and accelerates the lot splitting process. Value=3 matches ''Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Brooke_Pinto']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Matthew Frumin
-- ============================================================

-- ---- Matthew Frumin / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '674babd9-9812-41f3-aeae-0c11dbb4456e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '674babd9-9812-41f3-aeae-0c11dbb4456e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Frumin said in his 2022 campaign that alleviating school overcrowding and increasing access to affordable housing were the most pressing issues facing Ward 3. He serves on the Committee on Housing. Value=3 matches ''Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Matthew_Frumin']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Janeese Lewis George
-- ============================================================

-- ---- Janeese Lewis George / housing / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '5744694e-1e6b-4aee-a029-6fb0f01b4aac',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5744694e-1e6b-4aee-a029-6fb0f01b4aac',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Lewis George proposed a social housing model in 2021 of publicly owned and subsidized mixed-income housing. In April 2022 she introduced two bills inspired by the Green New Deal including one to create an agency to construct and maintain mixed-income social housing. Value=1 matches ''Directly build and operate public housing so anyone who needs a home can get one.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Janeese_Lewis_George']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Janeese Lewis George / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '5744694e-1e6b-4aee-a029-6fb0f01b4aac',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5744694e-1e6b-4aee-a029-6fb0f01b4aac',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Lewis George introduced two Green New Deal-inspired bills in April 2022 including one to create a social housing agency and accelerate removal of lead pipes. She also introduced the Extreme Heat Eviction Prevention Act of 2025. Value=2 matches ''rapidly transition to renewable energy and phase out fossil fuels by 2030.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Janeese_Lewis_George']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Janeese Lewis George / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '5744694e-1e6b-4aee-a029-6fb0f01b4aac',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5744694e-1e6b-4aee-a029-6fb0f01b4aac',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Lewis George was endorsed by Black Lives Matter, the Working Families Party, and the Metro DC Democratic Socialists of America. Her opponents falsely accused her of wanting to defund the police demonstrating her progressive civil rights orientation. Value=2 matches ''strengthen civil rights enforcement and address systemic discrimination.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Janeese_Lewis_George']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Trayon White, Sr.
-- ============================================================

-- ---- Trayon White, Sr. / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'acbbfc14-8fa0-4b81-8660-bf385701c160',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'acbbfc14-8fa0-4b81-8660-bf385701c160',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'White attended demonstrations in favor of better public housing and job training and against gentrification in Ward 8. He championed public housing investment and opposed policies that could displace residents. Value=2 matches ''Use rent caps, require new developments to include affordable units, and publicly fund new housing.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Trayon_White']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Charles Allen
-- ============================================================

-- ---- Charles Allen / public-safety-approach / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'd38df660-3481-45d2-98cb-682d0404de80',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'public-safety-approach'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'd38df660-3481-45d2-98cb-682d0404de80',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'public-safety-approach'),
  'Allen codified many of MPD''s General Orders into law including banning neck restraints and removed disciplinary processes for officer misconduct from collective bargaining agreements making it easier to fire officers guilty of serious misconduct. The Police Union criticized Allen for these reforms. Value=2 matches ''Maintain current police staffing but shift non-violent calls to unarmed mental health co-responders.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Charles_Allen_(Washington', '_D.C.', '_politician)']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Charles Allen / campaign-finance / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'd38df660-3481-45d2-98cb-682d0404de80',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'd38df660-3481-45d2-98cb-682d0404de80',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Allen championed campaign finance reform and was a supporter of DC''s Initiative 70 in 2012. He opted for a campaign model that did not accept corporate donations. Value=1 matches ''ban all private money in politics and publicly fund campaigns.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Charles_Allen_(Washington', '_D.C.', '_politician)']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Brian Schwalb
-- ============================================================

-- ---- Brian Schwalb / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '00bcdb0e-8bf2-4997-9642-ed3d14a2a5f8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '00bcdb0e-8bf2-4997-9642-ed3d14a2a5f8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Schwalb began investigating the political funding networks of Leonard Leo and Arabella Advisors in 2023 targeting dark money groups that fund conservative legal and political causes. He filed suit against military deployment to D.C. in September 2025 to protect residents'' civil liberties. Value=2 matches ''strengthen civil rights enforcement and address systemic discrimination.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://en.wikipedia.org/wiki/Brian_Schwalb']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Brian Schwalb / judicial-prosecution-priorities / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '00bcdb0e-8bf2-4997-9642-ed3d14a2a5f8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-prosecution-priorities'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '00bcdb0e-8bf2-4997-9642-ed3d14a2a5f8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-prosecution-priorities'),
  'As AG Schwalb''s office focuses on consumer protection, housing rights, worker rights, environmental protection, and civil rights enforcement using the office''s resources to address systemic issues rather than maximizing prosecutorial caseload. Value=2 matches ''Use diversion when it is available and makes sense. Reserve prosecution for when community safety actually requires it.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://oag.dc.gov/newsroom']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Zachary Parker
-- ============================================================

-- ---- Zachary Parker / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '6188851b-7cb7-4718-942d-49b40594386a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '6188851b-7cb7-4718-942d-49b40594386a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Parker''s DC Council bio states his mission is to help Ward 5 neighbors ''combat displacement, growing wealth and health disparities'' and describes his passion for disrupting ''inequitable systems that fail Black and brown working-class families.'' DCist described him as a ''favorite among progressive advocates for his housing and public safety platforms.'' Anti-displacement focus and progressive housing credentials match value=2: ''Use rent caps, require new developments to include affordable units, and publicly fund new housing.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://dccouncil.gov/council/ward-5-councilmember-zachary-parker/', 'https://dcist.com/story/22/06/21/dc-2022-primary-election-results-bowser-victory/']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Wendell Felder
-- ============================================================

-- ---- Wendell Felder / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '07a70461-06e5-47b1-815b-adac316280f7',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '07a70461-06e5-47b1-815b-adac316280f7',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Felder''s campaign platform (Washington Informer interview) stated he would ''transform vacant, abandoned and foreclosed properties in Ward 7 into affordable housing, community spaces, and commercial developments.'' He also wanted to ''establish a Ward 7 Business Incubator Fund.'' This reflects a targeted, community-development approach rather than broad public housing construction or strict rent control — matching value=3: ''Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://www.washingtoninformer.com/ward-7-dc-council-race-wendell-felder/']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Wendell Felder / public-safety-approach / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '07a70461-06e5-47b1-815b-adac316280f7',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'public-safety-approach'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '07a70461-06e5-47b1-815b-adac316280f7',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'public-safety-approach'),
  'Felder''s campaign platform centered on ''expand resources to new and existing community-based violence prevention programs'' alongside traditional public safety investment. His campaign emphasized unifying constituencies around public safety while adding community-based violence prevention — matching value=3: ''Keep current public safety funding while adding crisis response teams for mental health and addiction calls.''',
  ARRAY(SELECT u FROM unnest(ARRAY['https://www.washingtoninformer.com/ward-7-dc-council-race-wendell-felder/']) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- Post-state reporting
-- ============================================================

DO $$ BEGIN
  RAISE NOTICE
    'Phase 106 Plan 01 -- DC Mayor + Council + AG stances ingested: % politician_answers rows, % politician_context rows, covering % politicians',
    (SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id IN (SELECT id FROM essentials.politicians WHERE external_id BETWEEN -600015 AND -600001)),
    (SELECT COUNT(*) FROM inform.politician_context WHERE politician_id IN (SELECT id FROM essentials.politicians WHERE external_id BETWEEN -600015 AND -600001)),
    (SELECT COUNT(DISTINCT politician_id) FROM inform.politician_answers WHERE politician_id IN (SELECT id FROM essentials.politicians WHERE external_id BETWEEN -600015 AND -600001));
END $$;

COMMIT;