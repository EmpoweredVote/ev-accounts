-- Phase 112-09: VA House Delegate Stances — Wave 9 (HD-1 through HD-10, NoVA Core)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-112-va-delegates-wave9.csv
--
-- Pre-write cross-check:
--   CSV data rows:                          44
--   INSERT INTO inform.politician_answers:  44
--   INSERT INTO inform.politician_context:  44
--   All UUID literals verified against 2026-06-10-112-va-delegates-wave9-preflight.json
--   max_migration at authoring: 356
--
-- Honest skips (0 stances, no documentable evidence found):
--   R. Kirk McPike (HD-5) — b85d17af-a823-413c-b79c-aa4e7cfab730 — LIS member code H0406 returned no bill records across sessions 221/231/241/251; insufficient web presence to document stances without party inference
--
-- Politician UUIDs (from 2026-06-10-112-va-delegates-wave9-preflight.json):
--   Patrick A. Hope           (HD-1,  ext_id -5120001) -> af6e165b-4668-449b-97a5-6b25c01c572a
--   Adele Y. McClure          (HD-2,  ext_id -5120002) -> 8461412e-6413-4f44-ae5e-b7c8e7f736a5
--   Alfonso H. Lopez          (HD-3,  ext_id -5120003) -> 5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba
--   Charniele L. Herring      (HD-4,  ext_id -5120004) -> 51f5dd85-abb6-4f50-bcb9-e5e6b82376b7
--   R. Kirk McPike            (HD-5,  ext_id -5120005) -> b85d17af-a823-413c-b79c-aa4e7cfab730  (honest-skip)
--   Richard C. Sullivan, Jr.  (HD-6,  ext_id -5120006) -> 1964984f-1751-4ac7-ae94-69e50b0c2968
--   Karen Keys-Gamarra        (HD-7,  ext_id -5120007) -> c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e
--   Irene Shin                (HD-8,  ext_id -5120008) -> 98023fc8-d83b-43ba-b7e1-5bd132122bbe
--   Karrie K. Delaney         (HD-9,  ext_id -5120009) -> b17426e3-d363-44fd-a2b7-a04f54f6d7cb
--   Dan Helmer                (HD-10, ext_id -5120010) -> 090cebbd-19b5-41ed-9c9a-5f537cdb5470
--
-- Migration number: 339
-- Timestamp: 20260610000009
-- Applied: 2026-06-10

BEGIN;

-- ---- Patrick A. Hope / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Hope co-patronized HB 980 (2020) expanding who can perform first-trimester abortions and HB 1445 mandating health plan coverage for reproductive health services — demonstrating support for accessible abortion through the second trimester.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+sum+HB980',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+mbr+H0219S'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Patrick A. Hope / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Hope co-sponsored the VA Green New Deal Act (HB 77 2020) mandating 80-100% clean energy by 2036 and a moratorium on new fossil fuel infrastructure — demonstrating support for rapid renewable energy transition.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+sum+HB77'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Patrick A. Hope / fossil-fuels / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Hope co-sponsored VA Green New Deal Act (HB 77 2020) imposing a moratorium on state approval of new fossil fuel infrastructure projects starting January 2021 including pipelines and generating facilities.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+sum+HB77'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Patrick A. Hope / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Hope chiefly patronized HB 796 (2024) enabling electronic ballot return for disabled/military voters and HB 841 (2024) expanding ranked choice voting — showing consistent support for expanding voting access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB796',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB841'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Patrick A. Hope / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Hope chiefly patronized HB 353 (2024) requiring licensed physicians in hospital emergency departments at all times and co-sponsored HB 529 (2020) directing a universal healthcare financing study.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB353',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+sum+HB529'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Patrick A. Hope / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Hope chiefly patronized HB 386 (2020) banning conversion therapy by healthcare providers and co-sponsored HB 3 (2020) adding sexual orientation and gender identity protections to VA Fair Housing Law.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+sum+HB386',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+sum+HB3'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Patrick A. Hope / same-sex-marriage / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Hope co-sponsored HJ 9 (2025) — a constitutional amendment to repeal VA ban on same-sex marriage and recognize marriage as a fundamental right for any two individuals while protecting religious organizations right to decline ceremonies.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ9'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Patrick A. Hope / judicial-criminal-justice / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'af6e165b-4668-449b-97a5-6b25c01c572a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice'),
  'Hope chiefly patronized HB 555 (2024) creating a Corrections Ombudsman to inspect facilities and handle inmate complaints and HB 260 (2024) expanding expungement rights for reduced charges — showing a rehabilitation-oriented approach to justice.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB555',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB260'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Adele Y. McClure / childcare / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '8461412e-6413-4f44-ae5e-b7c8e7f736a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8461412e-6413-4f44-ae5e-b7c8e7f736a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'McClure chiefly patronized HB 1216 (2024) establishing an employer matching pilot program with state funds for childcare costs — a targeted employer/state cost-sharing approach rather than universal subsidies.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB1216'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Adele Y. McClure / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '8461412e-6413-4f44-ae5e-b7c8e7f736a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8461412e-6413-4f44-ae5e-b7c8e7f736a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'McClure chiefly patronized HB 1253 (2024) allowing localities to require that a percentage of new affordable development units meet accessibility standards for persons with physical disabilities — mandating inclusion in new developments.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB1253'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Adele Y. McClure / judicial-criminal-justice / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '8461412e-6413-4f44-ae5e-b7c8e7f736a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8461412e-6413-4f44-ae5e-b7c8e7f736a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice'),
  'McClure chiefly patronized HB 1252 (2024) limiting incarceration for technical parole/probation violations to a maximum of 30 days and requiring swift hearings — reducing punitive detention for non-criminal violations.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB1252'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Adele Y. McClure / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '8461412e-6413-4f44-ae5e-b7c8e7f736a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8461412e-6413-4f44-ae5e-b7c8e7f736a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'McClure chiefly patronized HB 405 (2024) directing state agencies to provide technical assistance for electric vehicle charging infrastructure in new residential developments — supporting incremental clean energy infrastructure expansion.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB405'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Adele Y. McClure / same-sex-marriage / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '8461412e-6413-4f44-ae5e-b7c8e7f736a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8461412e-6413-4f44-ae5e-b7c8e7f736a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'McClure co-sponsored HJ 9 (2025) — a constitutional amendment to repeal VA ban on same-sex marriage and recognize marriage as a fundamental right for any two individuals while protecting religious organizations right to decline ceremonies.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ9'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Adele Y. McClure / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '8461412e-6413-4f44-ae5e-b7c8e7f736a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8461412e-6413-4f44-ae5e-b7c8e7f736a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'McClure co-sponsored HB 1490 (2025) expanding voter satellite offices for in-person absentee voting and co-sponsored HJ 2 — a constitutional amendment enshrining the right to vote — demonstrating support for expanded voting access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HB1490',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ2'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Alfonso H. Lopez / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Lopez chiefly patronized HB 954 (2024) adding citizenship/immigration status as a protected class under the VA Human Rights Act and HB 962 removing the term aliens from the Virginia Code — protecting immigrants full access to public services regardless of status.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB954',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB962'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Alfonso H. Lopez / deportation / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'Lopez chiefly patronized HB 972 (2024) prohibiting courts from inquiring into or disclosing a defendants immigration status — shielding undocumented individuals in legal proceedings from immigration consequences except in serious violent crime contexts.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB972'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Alfonso H. Lopez / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Lopez chiefly patronized HB 968 (2024) creating the Virginia Green Infrastructure Bank to fund projects lowering emissions and advancing environmental justice and HB 953 creating a Local Environmental Impact Fund — demonstrating support for rapid clean energy investment.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB968',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB953'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Alfonso H. Lopez / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Lopez chiefly patronized HB 952 (2024) expanding C-PACE green financing to residential dwellings and HB 957 strengthening tenant remedies when dwelling units are condemned — showing support for affordable and accessible housing.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB952',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB957'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Alfonso H. Lopez / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Lopez chiefly patronized HB 954 (2024) adding citizenship and immigration status as protected classes in the VA Human Rights Act prohibiting discrimination — strengthening civil rights protections for non-citizen residents.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB954'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Alfonso H. Lopez / same-sex-marriage / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Lopez co-sponsored HJ 9 (2025) — a constitutional amendment to repeal VA ban on same-sex marriage and recognize marriage as a fundamental right for any two individuals while protecting religious organizations right to decline ceremonies.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ9'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Alfonso H. Lopez / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Lopez co-sponsored HJ 2 (2025) — a constitutional amendment enshrining the right to vote and clarifying voter qualifications — demonstrating support for protecting and expanding voting rights.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ2'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Charniele L. Herring / abortion / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51f5dd85-abb6-4f50-bcb9-e5e6b82376b7',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51f5dd85-abb6-4f50-bcb9-e5e6b82376b7',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Herring was chief patron of HJ 1 (2024) — a constitutional amendment establishing a fundamental right to reproductive freedom in Virginia — and chief patron of HB 980 (2020) expanding abortion provider access in the first trimester.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HJ1',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+sum+HB980'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Charniele L. Herring / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51f5dd85-abb6-4f50-bcb9-e5e6b82376b7',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51f5dd85-abb6-4f50-bcb9-e5e6b82376b7',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Herring was chief patron of HB 1 (2020) — the no-excuse absentee voting bill that eliminated the requirement for a reason to vote absentee — significantly expanding mail-in voting access for all Virginia voters.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+sum+HB1'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Charniele L. Herring / judicial-criminal-justice / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51f5dd85-abb6-4f50-bcb9-e5e6b82376b7',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51f5dd85-abb6-4f50-bcb9-e5e6b82376b7',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice'),
  'Herring chiefly patronized HB 773 (2024) modifying marijuana criminal penalties and has a history of criminal justice reform legislation including expungement and sentencing reform — demonstrating a rehabilitation-oriented approach.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB773'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Charniele L. Herring / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51f5dd85-abb6-4f50-bcb9-e5e6b82376b7',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51f5dd85-abb6-4f50-bcb9-e5e6b82376b7',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Herring chiefly patronized HB 781 (2024) re-establishing the Maternal Health Data and Quality Measures Task Force and was patron of the 2020 abortion access expansion — demonstrating priority on women''s healthcare access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB781',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+sum+HB980'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Richard C. Sullivan, Jr. / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '1964984f-1751-4ac7-ae94-69e50b0c2968',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1964984f-1751-4ac7-ae94-69e50b0c2968',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Sullivan chiefly patronized HB 107 (2024) creating an EV Rural Infrastructure Program and HB 108 and HB 117 establishing shared solar programs and solar interconnection standards showing strong support for rapid renewable energy transition.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB107',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB108'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Richard C. Sullivan, Jr. / fossil-fuels / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '1964984f-1751-4ac7-ae94-69e50b0c2968',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1964984f-1751-4ac7-ae94-69e50b0c2968',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Sullivan chiefly patronized HB 107 (2024) creating VA EV Rural Infrastructure Program and HB 117 expanding solar interconnection and net metering - actively replacing fossil fuel dependence with renewable energy infrastructure.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB117',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB107'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karen Keys-Gamarra / judicial-police-accountability / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-police-accountability'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-police-accountability'),
  'Keys-Gamarra chiefly patronized HB 167 (2024) requiring courts to impanel a special grand jury when an unarmed person is killed by law enforcement - mandating independent public accountability for police use of force resulting in death.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB167'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karen Keys-Gamarra / judicial-criminal-justice / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice'),
  'Keys-Gamarra chiefly patronized HB 1471 (2024) renaming the Drug Treatment Court Act as the Recovery Court Act - emphasizing treatment and recovery over punishment as the goal of drug-related criminal proceedings.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB1471'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karen Keys-Gamarra / same-sex-marriage / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Keys-Gamarra co-sponsored HJ 9 (2025) a constitutional amendment to repeal VA ban on same-sex marriage and recognize marriage as a fundamental right for any two individuals while protecting religious organizations right to decline ceremonies.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ9'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karen Keys-Gamarra / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Keys-Gamarra co-sponsored HB 1490 (2025) expanding voter satellite offices for in-person absentee voting and HJ 2 a constitutional amendment enshrining the right to vote.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HB1490',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ2'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Irene Shin / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '98023fc8-d83b-43ba-b7e1-5bd132122bbe',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '98023fc8-d83b-43ba-b7e1-5bd132122bbe',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Shin chiefly patronized HB 908 (2024) expanding financial eligibility for developmental disabilities services and HB 909 strengthening 1915(c) Medicaid Home and Community Based Services waivers - expanding Medicaid access for vulnerable populations.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB908',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB909'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Irene Shin / judicial-criminal-justice / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '98023fc8-d83b-43ba-b7e1-5bd132122bbe',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '98023fc8-d83b-43ba-b7e1-5bd132122bbe',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice'),
  'Shin chiefly patronized HB 912 (2024) limiting fees that local correctional facilities can charge inmates for commissary and phone systems - reducing punitive financial burdens on incarcerated individuals.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB912'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Irene Shin / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '98023fc8-d83b-43ba-b7e1-5bd132122bbe',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '98023fc8-d83b-43ba-b7e1-5bd132122bbe',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Shin co-sponsored HB 627 (2025) expanding the Child Care Subsidy Program to provide free childcare and HB 408 improving child care subsidy vendor reimbursements - supporting significant public expansion of affordable childcare access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HB627',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HB408'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Irene Shin / same-sex-marriage / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '98023fc8-d83b-43ba-b7e1-5bd132122bbe',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '98023fc8-d83b-43ba-b7e1-5bd132122bbe',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Shin co-sponsored HJ 9 (2025) a constitutional amendment to repeal VA ban on same-sex marriage and recognize marriage as a fundamental right for any two individuals while protecting religious organizations right to decline ceremonies.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ9'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Irene Shin / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '98023fc8-d83b-43ba-b7e1-5bd132122bbe',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '98023fc8-d83b-43ba-b7e1-5bd132122bbe',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Shin co-sponsored HJ 2 (2025) a constitutional amendment enshrining the right to vote and clarifying voter qualifications - demonstrating support for constitutional protection of voting rights.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ2'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karrie K. Delaney / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b17426e3-d363-44fd-a2b7-a04f54f6d7cb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b17426e3-d363-44fd-a2b7-a04f54f6d7cb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Delaney chiefly patronized HB 570 (2024) establishing a Prescription Drug Affordability Board and HB 760 requiring insurance coverage for insulin and diabetes supplies - prioritizing affordable healthcare access through regulated insurance and pricing oversight.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB570',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB760'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karrie K. Delaney / judicial-criminal-justice / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b17426e3-d363-44fd-a2b7-a04f54f6d7cb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b17426e3-d363-44fd-a2b7-a04f54f6d7cb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'judicial-criminal-justice'),
  'Delaney chiefly patronized HB 1268 (2024) establishing a community corrections alternative program with eligibility evaluation and diagnosis - supporting diversion to rehabilitation programs over incarceration.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB1268'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karrie K. Delaney / same-sex-marriage / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b17426e3-d363-44fd-a2b7-a04f54f6d7cb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b17426e3-d363-44fd-a2b7-a04f54f6d7cb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Delaney co-sponsored HJ 9 (2025) a constitutional amendment to repeal VA ban on same-sex marriage and recognize marriage as a fundamental right for any two individuals while protecting religious organizations right to decline ceremonies.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ9'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karrie K. Delaney / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b17426e3-d363-44fd-a2b7-a04f54f6d7cb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b17426e3-d363-44fd-a2b7-a04f54f6d7cb',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Delaney co-sponsored HJ 2 (2025) a constitutional amendment enshrining the right to vote and clarifying voter qualifications - demonstrating support for constitutional protection of voting rights.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ2'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Dan Helmer / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090cebbd-19b5-41ed-9c9a-5f537cdb5470',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090cebbd-19b5-41ed-9c9a-5f537cdb5470',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Helmer chiefly patronized HB 18 (2024) strengthening hate crime penalties to include ethnic animosity and prohibiting employment discrimination based on ethnicity - expanding civil rights protections and enforcement.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB18'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Dan Helmer / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090cebbd-19b5-41ed-9c9a-5f537cdb5470',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090cebbd-19b5-41ed-9c9a-5f537cdb5470',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Helmer chiefly patronized HB 278 (2024) requiring the state Medicaid plan to cover fertility preservation treatments for patients facing medical procedures that may impair fertility - expanding healthcare access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB278'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Dan Helmer / campaign-finance / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090cebbd-19b5-41ed-9c9a-5f537cdb5470',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090cebbd-19b5-41ed-9c9a-5f537cdb5470',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Helmer chiefly patronized HB 276 (2024) requiring disclosure of funding sources for campaign advertisements and independent expenditures - promoting transparency in political spending without imposing contribution limits.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB276'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Dan Helmer / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090cebbd-19b5-41ed-9c9a-5f537cdb5470',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090cebbd-19b5-41ed-9c9a-5f537cdb5470',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Helmer co-sponsored HJ 2 (2025) a constitutional amendment enshrining the right to vote and clarifying voter qualifications - demonstrating support for constitutional protection of voting rights.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ2'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Verification block scoped to Wave 9 (external_id BETWEEN -5120010 AND -5120001)
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5120010 AND -5120001;
  RAISE NOTICE 'VA delegates with stances (Wave 9): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5120010 AND -5120001
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 9): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;
