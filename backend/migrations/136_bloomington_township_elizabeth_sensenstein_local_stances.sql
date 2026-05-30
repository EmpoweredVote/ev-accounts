-- Migration 136: Local Lens compass stances for Elizabeth Sensenstein
-- Bloomington Township Board Member, Monroe County, Indiana
-- politician_id: 15c278e1-20d8-4a2c-9575-2e130a0ec37f
-- Researched: 2026-05-11
-- Result: All 8 topics not found.
-- Rationale: Indiana Township Board members approve the Township Trustee's budget and
-- assist with poor relief administration. They have no governing authority over zoning,
-- police, transportation, immigration, or economic development. No candidate questionnaire
-- responses, candidate survey completions, interviews, social media posts, or news coverage
-- found for Elizabeth Sensenstein in her township board capacity on any Local Lens topic.
-- Sensenstein's public record relates exclusively to her role as Monroe County HR/personnel
-- administrator (health clinic vendor selection, workplace HR matters) — not to board policy.
-- Sources checked: Ballotpedia, bloomingtontownship.in.gov, Herald-Times archives,
-- Indiana Public Media / WTIU / WFIU, League of Women Voters VOTE411 (excludes township
-- races per their published policy), Bloomington B-Square Bulletin, The Bloomingtonian,
-- Monroe County Democratic Party, LinkedIn public profile — no policy positions found.

BEGIN;

-- 1. Affordable Housing (topic_id: 669cac97-66a6-4087-b036-936fbe62efb3)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '15c278e1-20d8-4a2c-9575-2e130a0ec37f',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Township Board members have no authority over housing policy; they approve the Trustee''s poor-relief budget only. No candidate questionnaire, interview, or public statement found. Checked: Ballotpedia, bloomingtontownship.in.gov, Herald-Times, Indiana Public Media, LWV VOTE411 (excludes township races), Bloomington B-Square Bulletin, The Bloomingtonian, Monroe County Dems, LinkedIn.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '15c278e1-20d8-4a2c-9575-2e130a0ec37f',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Township Board has no authority over policing or encampment enforcement. No public statement found. Checked: same sources as above.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 3. Residential Zoning (topic_id: d4f18138-a2e0-4110-b925-7387d9d0d16d)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '15c278e1-20d8-4a2c-9575-2e130a0ec37f',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. Township Board has no zoning authority. No candidate survey, interview, or public statement found. Checked: same sources as above.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '15c278e1-20d8-4a2c-9575-2e130a0ec37f',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Township Board has no civil rights enforcement authority. No public statement found in her township board capacity. Checked: same sources as above.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 5. Public Safety Approach (topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '15c278e1-20d8-4a2c-9575-2e130a0ec37f',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. Township Board has no authority over police budgets or public safety staffing. No public statement found. Checked: same sources as above.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (topic_id: b9ccee94-ad96-4f10-b655-889d8e5abe92)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '15c278e1-20d8-4a2c-9575-2e130a0ec37f',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Township Board has no immigration enforcement authority. No public statement found. Checked: same sources as above.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 7. Economic Development Incentives (topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '15c278e1-20d8-4a2c-9575-2e130a0ec37f',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Township Board has no authority over economic development incentives or tax abatements. No public statement found. Checked: same sources as above.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- 8. Transportation Priorities (topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '15c278e1-20d8-4a2c-9575-2e130a0ec37f',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. Township Board has no transportation planning authority. No public statement found. Checked: same sources as above.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

COMMIT;
