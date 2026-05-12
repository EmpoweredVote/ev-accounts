-- Migration 134: Local Lens compass stances for Barbara E McKinney
-- Bloomington Township Board Member, Monroe County, Indiana
-- politician_id: c8a73d2a-205d-482e-bc78-8c81d965a28c
-- Researched: 2026-05-11
--
-- Indiana Township Board members approve the Township Trustee's budget and assist
-- with poor relief administration. They do NOT control zoning, police budgets,
-- transportation investment, or economic development incentives.
-- McKinney previously served as Bloomington Human Rights Commission Director /
-- Assistant City Attorney (retired 2022). No public statements found for any of
-- the 8 Local Lens topics in her township board capacity.
-- Sources checked: Ballotpedia, Monroe County Dems, Bloomington Township website,
-- Herald-Times archives, Limestone Post, Bloom Magazine, League of Women Voters
-- (explicitly excludes township board from voter guide), Greater Bloomington Chamber
-- 2026 election guide (excludes township board), B Square Bulletin, The Bloomingtonian,
-- Indiana Public Media / WTIU / WFIU search results.

BEGIN;

-- 1. Affordable Housing (topic_id: 669cac97-66a6-4087-b036-936fbe62efb3)
-- Not found: Township board has no authority over housing policy.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c8a73d2a-205d-482e-bc78-8c81d965a28c',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Indiana Township Boards have no authority over housing policy; they approve the Trustee''s budget and assist with poor relief only. No candidate questionnaires, interviews, or public statements on affordable housing found. The League of Women Voters Keys to the Candidates explicitly excludes township board races. Checked: Ballotpedia, Monroe County Democratic Party site, Bloomington Township website, Herald-Times, Limestone Post, Bloom Magazine, B Square Bulletin, The Bloomingtonian, Greater Bloomington Chamber 2026 election guide.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a)
-- Not found: Township board has no authority over law enforcement or shelter policy.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c8a73d2a-205d-482e-bc78-8c81d965a28c',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Indiana Township Boards have no authority over law enforcement or homelessness policy. No public statements on criminalization of homelessness found. Checked: Ballotpedia, Monroe County Democratic Party site, Bloomington Township website, Herald-Times, Limestone Post, Bloom Magazine, B Square Bulletin, The Bloomingtonian.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 3. Residential Zoning (topic_id: d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Not found: Township board has no authority over zoning.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c8a73d2a-205d-482e-bc78-8c81d965a28c',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. Indiana Township Boards have no zoning authority whatsoever. No public statements on residential zoning found. Checked: Ballotpedia, Monroe County Democratic Party site, Bloomington Township website, Herald-Times, Limestone Post, Bloom Magazine, B Square Bulletin, The Bloomingtonian.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Not found: McKinney's prior career at the Bloomington Human Rights Commission
-- involved enforcing anti-discrimination law, but those were professional duties
-- as a city employee, not personal policy positions as a township board member.
-- No direct, specific public statement qualifying for placement found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c8a73d2a-205d-482e-bc78-8c81d965a28c',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no placeable public record found. McKinney served as Bloomington Human Rights Commission Director and Assistant City Attorney 1989–2022 enforcing the city''s Human Rights Ordinance. However, those were professional duties as a city employee, not personal policy stances as a township board candidate. No direct statements on civil rights policy positions (e.g. reparations, affirmative action, systemic discrimination reform) found in any candidate materials or interviews. Township board has no civil rights enforcement authority. Checked: Ballotpedia, Bloom Magazine (2016, 2019 articles), Monroe County Democratic Party site, Bloomington Township website, Herald-Times, Limestone Post, B Square Bulletin.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 5. Public Safety Approach (topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Not found: Township board has no authority over police budgets or public safety.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c8a73d2a-205d-482e-bc78-8c81d965a28c',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. Indiana Township Boards have no authority over police budgets or public safety spending. No public statements on public safety approach found. Checked: Ballotpedia, Monroe County Democratic Party site, Bloomington Township website, Herald-Times, Limestone Post, Bloom Magazine, B Square Bulletin, The Bloomingtonian.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (topic_id: b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Not found: Township board has no authority over immigration enforcement policy.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c8a73d2a-205d-482e-bc78-8c81d965a28c',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Indiana Township Boards have no authority over immigration enforcement or sanctuary policies. No public statements on local immigration enforcement found. Checked: Ballotpedia, Monroe County Democratic Party site, Bloomington Township website, Herald-Times, Limestone Post, Bloom Magazine, B Square Bulletin, The Bloomingtonian.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 7. Economic Development Incentives (topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Not found: Township board has no authority over economic development or tax incentives.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c8a73d2a-205d-482e-bc78-8c81d965a28c',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Indiana Township Boards have no authority over economic development incentives or tax abatements. No public statements on economic development found. Checked: Ballotpedia, Monroe County Democratic Party site, Bloomington Township website, Herald-Times, Limestone Post, Bloom Magazine, B Square Bulletin, The Bloomingtonian.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 8. Transportation Priorities (topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Not found: Township board has no authority over transportation investment.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c8a73d2a-205d-482e-bc78-8c81d965a28c',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. Indiana Township Boards have no authority over transportation investment or infrastructure. No public statements on transportation priorities found. Checked: Ballotpedia, Monroe County Democratic Party site, Bloomington Township website, Herald-Times, Limestone Post, Bloom Magazine, B Square Bulletin, The Bloomingtonian.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

COMMIT;

-- Idempotency check / verification query:
-- SELECT ct.topic_key, pa.value, array_length(pc.sources,1) as n_sources
-- FROM inform.politician_context pc
-- JOIN inform.compass_topics ct ON ct.id = pc.topic_id
-- LEFT JOIN inform.politician_answers pa ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
-- WHERE pc.politician_id = 'c8a73d2a-205d-482e-bc78-8c81d965a28c'
-- ORDER BY ct.topic_key;
