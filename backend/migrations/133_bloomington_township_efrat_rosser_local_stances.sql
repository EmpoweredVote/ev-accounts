-- Migration 133: Local Lens compass stances for Efrat Rosser
-- Monroe County Bloomington Township Trustee, Indiana
-- politician_id: c7dee89b-1ee2-4858-a11e-b3775a4b4bfd
-- Researched: 2026-05-11
--
-- Indiana Township Trustees have very limited authority: poor relief/financial
-- assistance, food pantry, representative payee, cemetery maintenance, and some
-- fire protection coordination. They do NOT control zoning, police budgets,
-- transportation investment, or economic development incentives.
--
-- Result: 0 placed stances, 8 not-found entries.
-- Rosser's public statements are exclusively about township relief operations,
-- state consolidation legislation, and food/utility assistance programs.
-- No direct public statements found on any of the 8 Local Lens policy topics.

BEGIN;

-- 1. Affordable Housing (topic_id: 669cac97-66a6-4087-b036-936fbe62efb3)
-- Rosser stated: "I think the role that townships play nowadays in preventing
-- evictions and keeping people fed, clothed and housed...is more important than
-- ever as support from federal programs and other state programs is dwindling."
-- This describes the township's emergency relief function (paying rent/utilities
-- to prevent eviction), not a policy stance on government's role in housing supply,
-- rent caps, zoning, or public housing construction. Cannot map to 1-5.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c7dee89b-1ee2-4858-a11e-b3775a4b4bfd',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Rosser has described the township role in "preventing evictions and keeping people housed" but this refers to emergency financial assistance (the township''s statutory poor-relief function), not a policy stance on housing supply, rent control, zoning, or public housing construction. Indiana Township Trustees do not control housing policy. Checked: Bloomington Township website, Indiana Daily Student (IDS), Indiana Public Media (IPM), Bloomingtonian, B-Square Bulletin, Heading Home Indiana, Heading Home Guide.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a)
-- Township Trustees have no authority over police, encampment enforcement, or
-- shelter policy. No public statements found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c7dee89b-1ee2-4858-a11e-b3775a4b4bfd',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Indiana Township Trustees have no authority over police, encampment enforcement, shelter policy, or homelessness enforcement. No statements from Rosser found on this topic. Checked: Bloomington Township website, IDS, IPM, Bloomingtonian, B-Square Bulletin, Heading Home Indiana.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (topic_id: d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Township Trustees in Indiana have no zoning authority. No public statements found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c7dee89b-1ee2-4858-a11e-b3775a4b4bfd',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. Indiana Township Trustees have no zoning authority; zoning decisions rest with the city and county. No statements from Rosser found on residential zoning, density, or neighborhood character. Checked: Bloomington Township website, IDS, IPM, Bloomingtonian, B-Square Bulletin.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762)
-- No public statements found from Rosser on civil rights or racial equity policy.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c7dee89b-1ee2-4858-a11e-b3775a4b4bfd',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements from Rosser found on racial equity, civil rights enforcement, affirmative action, or systemic discrimination policy. Checked: Bloomington Township website, IDS, IPM, Bloomingtonian, B-Square Bulletin, Heading Home Indiana.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Township Trustees have no authority over police budgets or public safety funding.
-- No public statements found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c7dee89b-1ee2-4858-a11e-b3775a4b4bfd',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. Indiana Township Trustees have no authority over police budgets, staffing, or public safety funding allocation. No statements from Rosser found on policing, mental health co-responders, or public safety approach. Checked: Bloomington Township website, IDS, IPM, Bloomingtonian, B-Square Bulletin.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (topic_id: b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Rosser noted that "anyone like refugees and certain immigrants have lost their
-- SNAP benefits" under federal legislation — a factual observation about service
-- impacts, not a policy stance on ICE detainers or local law enforcement cooperation.
-- Township Trustees have no authority over police or immigration enforcement.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c7dee89b-1ee2-4858-a11e-b3775a4b4bfd',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Rosser noted factually that refugees and certain immigrants lost SNAP benefits under federal legislation, describing service demand impact on the township. This is not a policy stance on ICE detainers or local immigration enforcement. Indiana Township Trustees have no authority over police or immigration enforcement. Checked: Bloomington Township website, B-Square Bulletin, IDS, IPM, Bloomingtonian.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Township Trustees have no authority over economic development, tax abatements,
-- or business incentives. No public statements found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c7dee89b-1ee2-4858-a11e-b3775a4b4bfd',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Indiana Township Trustees have no authority over economic development incentives, tax abatements, or business attraction. No statements from Rosser found on this topic. Checked: Bloomington Township website, IDS, IPM, Bloomingtonian, B-Square Bulletin.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Rosser opposed HB 1461's mandate to transfer township unrestricted funds to
-- local road projects — but this was opposition to forced revenue diversion,
-- not a policy stance on transit vs. roads vs. cycling investment priorities.
-- Township Trustees have no transportation authority.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c7dee89b-1ee2-4858-a11e-b3775a4b4bfd',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. Rosser opposed HB 1461 requiring townships to transfer 30% of unrestricted funds to local road projects, but her objection was about protecting township relief budgets from forced diversion, not a stance on transportation investment priorities. Indiana Township Trustees have no transportation authority. Checked: Bloomington Township website, B-Square Bulletin, IDS, IPM, Bloomingtonian.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
