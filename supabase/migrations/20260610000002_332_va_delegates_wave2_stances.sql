-- Phase 112-02: VA House Delegate Stances — Wave 2 (HD-53/54/55 + HD-37-42, non-contiguous)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-112-va-delegates-wave2.csv
--
-- Pre-write cross-check:
--   CSV data rows:                  20
--   INSERT INTO inform.politician_answers count: 20
--   INSERT INTO inform.politician_context count: 20
--   max_migration at authoring: 325 (psql-applied waves 326–331 not tracked in schema_migrations)
--
-- Stances written (5 delegates with documentable positions):
--   Timothy P. Griffin (HD-53, R): 5 stances — abortion(4), religious-freedom(4), taxes(4), school-vouchers(4), voting-rights(4)
--   Katrina E. Callsen (HD-54, D): 2 stances — abortion(2), school-vouchers(1)
--   Amy J. Laufer     (HD-55, D): 3 stances — abortion(2), climate-change(3), healthcare(2)
--   Terry L. Austin   (HD-37, R): 3 stances — abortion(4), taxes(4), religious-freedom(4)
--   Sam Rasoul        (HD-38, D): 7 stances — climate-change(1), fossil-fuels(1), abortion(2), same-sex-marriage(1), civil-rights(2), voting-rights(2), healthcare(2)
--
-- Honest skips (4 delegates — no documentable policy positions found):
--   Will P. Davis     (HD-39, R): no survey completions 2023/2025; endorsement-only (Patriot Parents)
--   Joseph P. McNamara(HD-40, R): no survey completions 2019/2021/2023/2025
--   Lily V. Franklin  (HD-41, D): no survey completions 2023/2025 (newly elected 2025)
--   Jason S. Ballard  (HD-42, R): no survey completions 2021/2023/2025
--
-- Politician UUIDs (from 2026-06-10-112-va-delegates-wave2-preflight.json):
--   Timothy P. Griffin  (HD-53, ext_id -5120053) -> 8123c0d7-aaf6-4abe-bb8d-5d835463f733
--   Katrina E. Callsen  (HD-54, ext_id -5120054) -> 13a9c6b7-d781-415b-b44f-3f8ca06aa763
--   Amy J. Laufer       (HD-55, ext_id -5120055) -> 80b9fe48-9f8c-4585-91ab-4d0ed1bc2229
--   Terry L. Austin     (HD-37, ext_id -5120037) -> 3049ed75-9743-42f4-8c9e-037a41f9bdc3
--   Sam Rasoul          (HD-38, ext_id -5120038) -> 307597bd-3a05-41ad-a991-a7325ece5b5f
--   Will P. Davis       (HD-39, ext_id -5120039) -> 7b11e4bb-330b-4fb6-999e-b72974f3549c  [skip]
--   Joseph P. McNamara  (HD-40, ext_id -5120040) -> 61e69826-c7d3-492b-a319-d2a34a33f92e  [skip]
--   Lily V. Franklin    (HD-41, ext_id -5120041) -> f4257ee4-57c8-47dd-81ed-4abfa71a2e24  [skip]
--   Jason S. Ballard    (HD-42, ext_id -5120042) -> 03b1536c-8724-4e7e-a9ae-e07dcd07aba5  [skip]
--
-- Migration number: 332
-- Timestamp: 20260610000002
-- Applied: 2026-06-10

BEGIN;

-- ============================================================
-- Timothy P. Griffin (HD-53, R) — 5 stances
-- Source: https://www.griffinforvirginia.com/issues + https://ballotpedia.org/Tim_Griffin_(Virginia)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('8123c0d7-aaf6-4abe-bb8d-5d835463f733', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4), -- abortion
  ('8123c0d7-aaf6-4abe-bb8d-5d835463f733', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 4), -- religious-freedom
  ('8123c0d7-aaf6-4abe-bb8d-5d835463f733', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4), -- taxes
  ('8123c0d7-aaf6-4abe-bb8d-5d835463f733', '00b95a6a-75db-4521-b523-3326bba938de', 4), -- school-vouchers
  ('8123c0d7-aaf6-4abe-bb8d-5d835463f733', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4)  -- voting-rights
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('8123c0d7-aaf6-4abe-bb8d-5d835463f733', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Describes himself as pro-life and states he will pursue policies that support all human life; no exceptions mentioned in published issue positions.',
   ARRAY['https://www.griffinforvirginia.com/issues', 'https://ballotpedia.org/Tim_Griffin_(Virginia)']),
  ('8123c0d7-aaf6-4abe-bb8d-5d835463f733', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
   'States he will make sure Virginia is a friendly place for churches and religious organizations to worship God and practice freely — supports faith-based exemptions.',
   ARRAY['https://www.griffinforvirginia.com/issues', 'https://ballotpedia.org/Tim_Griffin_(Virginia)']),
  ('8123c0d7-aaf6-4abe-bb8d-5d835463f733', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
   'Committed to cutting taxes and burdensome regulations — supports cutting taxes for everyone.',
   ARRAY['https://www.griffinforvirginia.com/issues', 'https://ballotpedia.org/Tim_Griffin_(Virginia)']),
  ('8123c0d7-aaf6-4abe-bb8d-5d835463f733', '00b95a6a-75db-4521-b523-3326bba938de',
   'Explicitly states he will pass school choice legislation — expanding voucher eligibility so parents can choose the school that best fits their child.',
   ARRAY['https://www.griffinforvirginia.com/issues', 'https://ballotpedia.org/Tim_Griffin_(Virginia)']),
  ('8123c0d7-aaf6-4abe-bb8d-5d835463f733', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
   'States he will save the election system by strengthening in-person voting and photo ID requirements — aligns with photo ID mandate and removing inactive registrations.',
   ARRAY['https://www.griffinforvirginia.com/issues', 'https://ballotpedia.org/Tim_Griffin_(Virginia)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Katrina E. Callsen (HD-54, D) — 2 stances
-- Source: https://ballotpedia.org/Katrina_Callsen (2023 Candidate Connection survey)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('13a9c6b7-d781-415b-b44f-3f8ca06aa763', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2), -- abortion
  ('13a9c6b7-d781-415b-b44f-3f8ca06aa763', '00b95a6a-75db-4521-b523-3326bba938de', 1)  -- school-vouchers
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('13a9c6b7-d781-415b-b44f-3f8ca06aa763', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Ballotpedia 2023 survey: explicit priorities include codifying reproductive rights in the state Constitution and increasing access to reproductive health care — keep abortion legal and accessible through second trimester.',
   ARRAY['https://ballotpedia.org/Katrina_Callsen']),
  ('13a9c6b7-d781-415b-b44f-3f8ca06aa763', '00b95a6a-75db-4521-b523-3326bba938de',
   'Ballotpedia 2023 survey: explicitly lists Fund Our Public Schools as top campaign priority and calls for fully funding public schools — eliminating vouchers that divert taxpayer money.',
   ARRAY['https://ballotpedia.org/Katrina_Callsen'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Amy J. Laufer (HD-55, D) — 3 stances
-- Source: https://ballotpedia.org/Amy_Laufer (2019 Candidate Connection survey)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2), -- abortion
  ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3), -- climate-change
  ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)  -- healthcare
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Ballotpedia 2019 survey: states she is deeply concerned about preserving women''s reproductive rights in Virginia — keep abortion legal and accessible.',
   ARRAY['https://ballotpedia.org/Amy_Laufer']),
  ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
   'Ballotpedia 2019 survey: advocates for investing in renewable energy infrastructure to protect the environment and stimulate economic growth by creating new jobs — invest in clean energy while gradually reducing fossil fuel reliance, not declaring emergency.',
   ARRAY['https://ballotpedia.org/Amy_Laufer']),
  ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   'Ballotpedia 2019 survey: states everyone needs access to affordable healthcare and is invested in ensuring protections for people with pre-existing conditions — make sure everyone has affordable coverage through public programs and regulated private insurance.',
   ARRAY['https://ballotpedia.org/Amy_Laufer'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Terry L. Austin (HD-37, R) — 3 stances
-- Source: https://ballotpedia.org/Terry_Austin (Candidate Connection survey)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('3049ed75-9743-42f4-8c9e-037a41f9bdc3', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4), -- abortion
  ('3049ed75-9743-42f4-8c9e-037a41f9bdc3', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4), -- taxes
  ('3049ed75-9743-42f4-8c9e-037a41f9bdc3', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 4)  -- religious-freedom
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('3049ed75-9743-42f4-8c9e-037a41f9bdc3', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Ballotpedia survey: describes himself as proudly pro-life and states he will support additional efforts to protect the unborn — restrict to serious threats to the mother''s life.',
   ARRAY['https://ballotpedia.org/Terry_Austin']),
  ('3049ed75-9743-42f4-8c9e-037a41f9bdc3', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
   'Ballotpedia survey: campaign theme explicitly listed as Keeping Taxes Low with commitment to reduce taxes and spending — cut taxes for everyone.',
   ARRAY['https://ballotpedia.org/Terry_Austin']),
  ('3049ed75-9743-42f4-8c9e-037a41f9bdc3', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
   'Ballotpedia survey: states he supports laws that protect every Virginian''s right to openly proclaim and practice their faith — protect religious freedom and allow faith-based exemptions.',
   ARRAY['https://ballotpedia.org/Terry_Austin'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Sam Rasoul (HD-38, D) — 7 stances
-- Source: https://ballotpedia.org/Sam_Rasoul (2021 LG campaign website + 2023 endorsements)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1), -- climate-change
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', 'a22215c3-6693-4bc2-b248-01aebba14570', 1), -- fossil-fuels
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2), -- abortion
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1), -- same-sex-marriage
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2), -- civil-rights
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2), -- voting-rights
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)  -- healthcare
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
   'Ballotpedia 2021 LG campaign website: explicitly calls to declare a climate crisis in Virginia and enact a Green New Deal to get Virginia to 100% clean energy by 2036 — declare climate emergency and ban activities increasing carbon emissions.',
   ARRAY['https://ballotpedia.org/Sam_Rasoul']),
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', 'a22215c3-6693-4bc2-b248-01aebba14570',
   'Ballotpedia 2021 LG campaign website: explicitly calls to establish a moratorium on new fossil fuel projects — immediately ban all new fossil fuel drilling and extraction.',
   ARRAY['https://ballotpedia.org/Sam_Rasoul']),
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Ballotpedia: endorsed by Planned Parenthood Advocates of Virginia in 2023; 2021 campaign described fighting for a woman''s right to choose — keep abortion legal and accessible.',
   ARRAY['https://ballotpedia.org/Sam_Rasoul']),
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
   'Ballotpedia 2021 campaign: supported removing the constitutional amendment that banned same-sex marriage in Virginia — require all states to recognize same-sex marriages with full protections.',
   ARRAY['https://ballotpedia.org/Sam_Rasoul']),
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', '0bc588c6-39e1-4084-b5de-cac909b8b762',
   'Ballotpedia 2021 campaign: states too many people still face discrimination and that Virginia must take every opportunity to stand up and fight for equality — strengthen civil rights enforcement and address systemic discrimination.',
   ARRAY['https://ballotpedia.org/Sam_Rasoul']),
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
   'Ballotpedia 2021 campaign: explicitly called for going farther than restoring felon voting rights upon release to ensure the ability to vote is never taken away plus ideas to make voting more accessible — expand early voting and mail-in access.',
   ARRAY['https://ballotpedia.org/Sam_Rasoul']),
  ('307597bd-3a05-41ad-a991-a7325ece5b5f', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   'Ballotpedia 2021 LG campaign website: calls for high-quality affordable healthcare for every Virginian as a basic right and lowering prescription drug costs through public programs and regulated insurance — make sure everyone has affordable coverage through mix of public programs and regulated private insurance.',
   ARRAY['https://ballotpedia.org/Sam_Rasoul'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Verification block scoped to Wave 2 (non-contiguous IN() — Pitfall 7)
-- external_id IN: HD-53,54,55 + HD-37,38,39,40,41,42
-- ============================================================
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id IN (-5120053, -5120054, -5120055, -5120037, -5120038, -5120039, -5120040, -5120041, -5120042);
  RAISE NOTICE 'VA delegates with stances (Wave 2): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id IN (-5120053, -5120054, -5120055, -5120037, -5120038, -5120039, -5120040, -5120041, -5120042)
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 2): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;
