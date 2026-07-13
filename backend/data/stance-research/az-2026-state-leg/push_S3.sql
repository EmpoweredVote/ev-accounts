-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch S3 (12 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-S3.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- J.D. Mesnard (State Senate District 13) / abortion = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '09ae25a4-9244-455a-960a-b95223bb52d8', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '09ae25a4-9244-455a-960a-b95223bb52d8', ct.id, $ctx$Mesnard cast a recorded vote against repealing Arizona's near-total 19th-century abortion ban when the Arizona Senate took up its repeal in 2024, per a Wikipedia-cited AZ Central report. That law permitted abortion only to save the mother's life, with no rape or incest exception. His vote to keep it in force is scored at the most restrictive available chair that still contains any listed exception, though the actual law he defended lacked a rape/incest carve-out present in that chair's text.$ctx$,
       ARRAY['https://en.wikipedia.org/wiki/J.D._Mesnard']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.D. Mesnard (State Senate District 13) / school-vouchers = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '09ae25a4-9244-455a-960a-b95223bb52d8', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '09ae25a4-9244-455a-960a-b95223bb52d8', ct.id, $ctx$As Speaker of the Arizona House, Mesnard was a documented key backer of the 2017 ESA voucher-expansion law that appeared on the 2018 ballot as Proposition 305, which voters ultimately rejected (per Wikipedia). The expansion broadened ESA eligibility well beyond the original narrow low-income/special-needs criteria without eliminating public school funding, matching the chair for expanding voucher eligibility to most families while maintaining baseline public funding.$ctx$,
       ARRAY['https://en.wikipedia.org/wiki/J.D._Mesnard']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.D. Mesnard (State Senate District 13) / healthcare = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '09ae25a4-9244-455a-960a-b95223bb52d8', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '09ae25a4-9244-455a-960a-b95223bb52d8', ct.id, $ctx$Mesnard opposed the Affordable Care Act and Arizona's 2013 Medicaid expansion, joining 35 other Republican lawmakers as a plaintiff in a 2015 lawsuit to overturn the expansion on tax-authorization grounds (the Arizona Supreme Court unanimously rejected the suit in 2017, per Wikipedia). Opposing expansion of Medicaid to more low-income adults, without opposing the pre-expansion program itself, matches the chair limiting government help to the poorest while routing everyone else to employer/private insurance.$ctx$,
       ARRAY['https://en.wikipedia.org/wiki/J.D._Mesnard']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- J.D. Mesnard (State Senate District 13) / taxes = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '09ae25a4-9244-455a-960a-b95223bb52d8', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '09ae25a4-9244-455a-960a-b95223bb52d8', ct.id, $ctx$On his official campaign site's Fiscal Responsibility page, Mesnard ties tax cuts explicitly to spending restraint, describing a household-budget approach of spending 'only what's necessary' and finding 'responsible ways to trim' government spending when times get tough. This pairing of low taxes with active spending cuts (rather than closing loopholes within the current system) matches the chair for cutting taxes and scaling back services to match.$ctx$,
       ARRAY['https://www.jdmesnard.com/fiscal-responsibility']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Warren Petersen (State Senate District 14) / voting-rights = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '49b806b1-f15d-4998-a94e-de542d9e323e', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '49b806b1-f15d-4998-a94e-de542d9e323e', ct.id, $ctx$Petersen sponsored HB2492 (2022), which required documentary proof of citizenship for state-form voter registration, and as Senate Judiciary Committee chair issued subpoenas that launched the 2020 Maricopa County 'Arizona Audit' (per Wikipedia). Both actions demonstrate an individual push toward tightening registration/eligibility verification and heightened scrutiny of election rolls, matching the chair requiring photo ID and regularly updated voter rolls.$ctx$,
       ARRAY['https://en.wikipedia.org/wiki/Warren_Petersen']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Warren Petersen (State Senate District 14) / taxes = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '49b806b1-f15d-4998-a94e-de542d9e323e', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '49b806b1-f15d-4998-a94e-de542d9e323e', ct.id, $ctx$Petersen's official Senate Republicans caucus bio lists his priorities as 'limited government, reduced regulations, fiscally conservative initiatives, low taxes, and free market principles,' and his legislative record includes sponsoring HB2212 (2015), which closed the Arizona Department of Weights and Measures. The combination of a stated low-tax/free-market platform with an actual vote to eliminate a state agency supports the chair pairing tax cuts with scaled-back public services.$ctx$,
       ARRAY['https://www.azsenaterepublicans.gov/petersen', 'https://en.wikipedia.org/wiki/Warren_Petersen']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jake Hoffman (State Senate District 15) / abortion = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '66ca210e-deab-4d07-8a18-48f7079f6f9b', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '66ca210e-deab-4d07-8a18-48f7079f6f9b', ct.id, $ctx$Hoffman voted against HB2677 (2024), which repealed Arizona's near-total 1864 abortion ban (life-only exception, no rape or incest carve-out) in favor of restoring the state's 15-week gestational-limit law. On the Senate floor he defended the law he was voting to preserve, calling it one of the strongest pro-life measures in the country. His vote and floor statement support keeping the most restrictive available chair containing any exception at all, though the specific 1864 law he defended lacked a rape/incest exception present in that chair's text.$ctx$,
       ARRAY['https://www.phoenixnewtimes.com/news/1864-abortion-ban-repealed-arizona-senate-18877099/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas "T.J." Shope (State Senate District 16) / abortion = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8bbf9f70-adee-4801-ab19-7b78f9e70aa1', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8bbf9f70-adee-4801-ab19-7b78f9e70aa1', ct.id, $ctx$On April 17, 2024, Sen. Shope was one of only two Senate Republicans (with Shawnna Bolick) who crossed party lines to vote for HB2677, repealing Arizona's near-total 1864 abortion ban, in a 16-14 Senate vote. His vote restored the state's prior 15-week gestational-limit law (exception only for the mother's life) in place of the near-total ban his party otherwise defended. He declined to explain his vote to reporters, so this is a recorded-floor-vote evidence base, not a stated rationale. The closest scale chair to a vote preserving a defined-window abortion allowance (rather than a near-total ban) is the first-trimester/rape-incest/health-risk chair; note Arizona's actual resulting law (15-week limit, life-only exception, no rape/incest carve-out) does not exactly match any single chair, but this is the closest fit relative to the complete-ban chair he voted against.$ctx$,
       ARRAY['https://www.12news.com/article/news/politics/arizona-senate-passes-bill-repeal-1864-abortion-ban/75-c1decb98-b688-4ac6-8f97-bae65652b371', 'https://www.governing.com/politics/arizona-senate-repeals-the-1864-abortion-ban', 'https://www.phoenixnewtimes.com/news/1864-abortion-ban-repealed-arizona-senate-18877099/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas "T.J." Shope (State Senate District 16) / campaign-finance = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8bbf9f70-adee-4801-ab19-7b78f9e70aa1', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'campaign-finance'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8bbf9f70-adee-4801-ab19-7b78f9e70aa1', ct.id, $ctx$In February 2025, Sen. Shope introduced his own bill requiring companies bidding on Arizona state contracts to disclose political campaign contributions made within the preceding five years, aimed at addressing pay-to-play concerns in state contracting. This is his own sponsored legislation mandating disclosure of political money tied to government business; the full article text could not be independently re-verified by fetch (azcentral.com is blocked to direct retrieval in this environment) but the specific bill description was corroborated via search snippet. Closest chair: full disclosure of all political donations, though his bill's scope (state contract bidders specifically) is narrower than the chair's general framing.$ctx$,
       ARRAY['https://www.azcentral.com/story/news/politics/legislature/2025/02/05/arizona-republican-contract-bidders-disclose-political-donations/78217936007/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'campaign-finance'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Venden "Vince" Leach (State Senate District 17) / healthcare = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'c2ee942d-72dc-4e50-8b78-dfe0a6ce8f93', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'c2ee942d-72dc-4e50-8b78-dfe0a6ce8f93', ct.id, $ctx$Leach voted Yea on the Senate Third Reading of SB1109 (2019, 'short-term limited duration insurance; notice'), which expanded access to short-term health insurance plans exempt from ACA pre-existing-condition protections — verified by the orchestrator against the LegiScan roll-call record on 2026-07-13. This individual vote to expand deregulated, non-ACA-compliant private plans as an alternative to standard coverage, rather than expanding public programs, matches the chair limiting government help to the poorest and routing everyone else to employer/private insurance.$ctx$,
       ARRAY['https://legiscan.com/AZ/rollcall/SB1109/id/799206', 'https://en.wikipedia.org/wiki/Vince_Leach']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Venden "Vince" Leach (State Senate District 17) / voting-rights = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'c2ee942d-72dc-4e50-8b78-dfe0a6ce8f93', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'c2ee942d-72dc-4e50-8b78-dfe0a6ce8f93', ct.id, $ctx$Leach voted Yea on the final Senate Third Reading of SB1485 (2021), which converted Arizona's Permanent Early Voting List to an 'active' list and made it easier to remove voters for inactivity — verified by the orchestrator against the LegiScan roll-call record on 2026-07-13. This individual vote for stricter inactive-voter roll maintenance matches the chair requiring photo ID and regularly updating voter rolls to remove inactive registrations.$ctx$,
       ARRAY['https://legiscan.com/AZ/rollcall/SB1485/id/1075824', 'https://en.wikipedia.org/wiki/Vince_Leach']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Priya Sundareshan (State Senate District 18) / voting-rights = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '179e2cdb-395e-4f7f-a5e1-775ff176ce64', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '179e2cdb-395e-4f7f-a5e1-775ff176ce64', ct.id, $ctx$Sundareshan's own 2026 campaign platform (priya4az.com, "My Vision for Arizona" issues page) states her priority to safeguard democracy by making voting easy and accessible to all. Arizona already provides no-excuse mail voting and multi-week early voting; Republican-authored bills in recent sessions have sought to restrict mail voting or add stricter ID/roll-purge requirements. Her platform statement, framed as protecting/expanding existing broad access rather than proposing new mechanisms like automatic registration or online voting (neither mentioned), best fits the chair supporting expanded early voting and no-excuse mail voting for all voters.$ctx$,
       ARRAY['https://www.priya4az.com/?page_id=13']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
