-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch H4 (8 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-H4.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Junelle Cavero (State House District 11) / local-immigration = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '2b044f08-b5ce-4b15-993e-b90c16603c25', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '2b044f08-b5ce-4b15-993e-b90c16603c25', ct.id, $ctx$Prime sponsor of HB4093 (2026), which amends A.R.S. 41-192 to direct the Arizona Attorney General to prosecute any U.S. Immigration and Customs Enforcement officer operating in Arizona for criminal violations committed while conducting official duties. This is an adversarial, maximal non-cooperation stance toward federal immigration enforcement, closest to the scale's most restrictive-of-ICE chair (state-level analog to the city-police-cooperation question the topic asks about).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4093p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2351']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Oscar De Los Santos (State House District 11) / housing = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fb949bda-e2f5-49ab-9069-a70da1fb13bd', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fb949bda-e2f5-49ab-9069-a70da1fb13bd', ct.id, $ctx$Prime sponsor of HB2705 (2026), which caps the number of single-family homes a corporation or LLC may purchase per census tract (5%) and per year (50 units statewide), requires registration and disclosure with the Corporation Commission, and imposes civil penalties up to $20,000 per violation for noncompliance. This is an interventionist regulatory approach aimed at protecting single-family housing supply and affordability from corporate consolidation, closest to the scale's active-market-regulation chair.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2705p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2303']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Oscar De Los Santos (State House District 11) / civil-rights = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fb949bda-e2f5-49ab-9069-a70da1fb13bd', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fb949bda-e2f5-49ab-9069-a70da1fb13bd', ct.id, $ctx$Prime sponsor of HB2141 (2026, cosponsored by Rep. Patty Contreras), which creates new environmental-justice permitting requirements — impact assessments, mandatory public hearings, and permit-denial authority — for industrial facility siting in low-income 'burdened communities' (bottom third of census tracts by median household income). This adds enforcement/process protections against systemic environmental and economic inequity rather than merely maintaining existing law, matching the scale's civil-rights-enforcement-strengthening chair.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2141p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2303']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Oscar De Los Santos (State House District 11) / abortion = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'fb949bda-e2f5-49ab-9069-a70da1fb13bd', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'fb949bda-e2f5-49ab-9069-a70da1fb13bd', ct.id, $ctx$Led a House floor protest in April 2024 demanding a vote on repealing Arizona's 1864 near-total abortion ban, was removed from House committees by the Speaker for it, and said afterward he would keep fighting to protect reproductive freedom; the ban was repealed 32-28 the next day. This places him solidly in the legal-and-accessible camp, though no source found specifies whether he supports public funding or access limits beyond the second trimester, so scored at the more conservative pro-access chair rather than the maximal chair.$ctx$,
       ARRAY['https://azmirror.com/2024/04/24/az-house-has-voted-to-repeal-the-1864-abortion-ban-upheld-by-the-supreme-court/', 'https://azmirror.com/2024/06/04/ethics-panel-concludes-2-dems-broke-az-house-rules-by-yelling-at-republicans-amid-abortion-uproar/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patty Contreras (State House District 12) / housing = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8dcf58fe-fea2-4dd4-81ac-542432b154cf', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8dcf58fe-fea2-4dd4-81ac-542432b154cf', ct.id, $ctx$Prime sponsor of HB2561 (2026, cosponsored by 8 colleagues including Rep. Cavero), which appropriates $7,000,000 in FY2026-2027 from the state general fund to the Department of Economic Security for housing assistance to Arizonans age 60 and older, distributed through area agencies on aging, with legislative intent that the funding continue in future years. This is a targeted assistance program for one population rather than rent regulation or broad public housing construction, matching the targeted-help/subsidies chair. (Re-chaired 2-to-3 by orchestrator on review, 2026-07-13.)$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2561p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2302']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patty Contreras (State House District 12) / civil-rights = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8dcf58fe-fea2-4dd4-81ac-542432b154cf', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8dcf58fe-fea2-4dd4-81ac-542432b154cf', ct.id, $ctx$Sole named cosponsor of Rep. Oscar De Los Santos's HB2141 (2026), which creates environmental-justice permitting requirements — impact assessments, mandatory public hearings, and permit-denial authority — for industrial facility siting in low-income 'burdened communities.' As the only cosponsor on a bill she did not prime-sponsor, this is a clearly-owned policy position addressing systemic environmental and economic inequity, matching the scale's civil-rights-enforcement-strengthening chair.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2141p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2302']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stacey Travers (State House District 12) / voting-rights = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'c2c49ac4-8d5e-46e3-b663-ac1677021a1b', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'c2c49ac4-8d5e-46e3-b663-ac1677021a1b', ct.id, $ctx$Prime sponsor of HB2037 (2026), which converts Arizona's driver-license-office voter registration from an opt-in offer to true automatic (opt-out) registration for driver license and nonoperating ID applicants and renewals — the strongest form of automatic registration described on the scale.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2037p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2340']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stacey Travers (State House District 12) / civil-rights = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'c2c49ac4-8d5e-46e3-b663-ac1677021a1b', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'c2c49ac4-8d5e-46e3-b663-ac1677021a1b', ct.id, $ctx$Prime sponsor of HB2931 (2026), which repeals the sunset date on the Arizona Civil Rights Advisory Board and continues its hearings/investigations function through July 2034 rather than letting it terminate. The bill maintains existing anti-discrimination enforcement infrastructure without adding new powers, matching the scale's 'maintain current civil rights laws while promoting equal opportunity' chair rather than an enforcement-strengthening chair.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2931p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2340']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
