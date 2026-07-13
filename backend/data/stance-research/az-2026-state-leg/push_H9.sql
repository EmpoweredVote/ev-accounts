-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch H9 (12 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-H9.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Michael Carbone (State House District 25) / civil-rights = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '86b6bbf3-cb81-4f8e-a44b-5c4ffe46df7a', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '86b6bbf3-cb81-4f8e-a44b-5c4ffe46df7a', ct.id, $ctx$Cosponsored HCR2044 (2026), a constitutional amendment referral prohibiting preferential treatment/discrimination based on race or ethnicity in public employment, education, and contracting, and barring DEI/race-based programming funded with public monies. This is a clear match to eliminating affirmative action and race-based government programs.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2044p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2298']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Carbone (State House District 25) / medicare/aid = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '86b6bbf3-cb81-4f8e-a44b-5c4ffe46df7a', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '86b6bbf3-cb81-4f8e-a44b-5c4ffe46df7a', ct.id, $ctx$Prime sponsor of HB2796 (2026), which requires aggressive AHCCCS (Arizona Medicaid) eligibility verification via monthly data-matching against lottery winnings, death records, and income/residency changes, bars self-attestation of eligibility factors, and directs the state to seek a federal waiver eliminating mandatory hospital presumptive eligibility for all but children and pregnant women. The bill's substantive effect is to tighten and reduce Medicaid enrollment access rather than expand or merely stabilize the program.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2796p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2298']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Kupper (State House District 25) / housing = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4176f760-3c74-4a55-8edc-b7897ee80e21', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4176f760-3c74-4a55-8edc-b7897ee80e21', ct.id, $ctx$Prime sponsor of HB2325 (2026), the 'Own Something and Be Happy Act,' which bars institutional investors from owning more than 50 single-family homes statewide, bars them from bidding within the first 60 days a home is listed, and bars bulk purchases, with AG/county/city enforcement and mandatory disclosure filings. This is an active government market intervention aimed at housing affordability for individual buyers, the same type of institutional-investor restriction that Democratic HB2705 (Rep. De Los Santos) used to score housing=2 in a prior batch this wave.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2325p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2367']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cesar Aguilar (State House District 26) / taxes = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '49b2db49-6438-437c-90ce-36b97670e30a', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '49b2db49-6438-437c-90ce-36b97670e30a', ct.id, $ctx$Prime sponsor of HB4095 (2026), which imposes a new 3.5% income-tax surtax on federal AGI above $250,000 (single)/$500,000 (joint), with the resulting revenue split 50/50 between the classroom site teacher-compensation fund and an emergency school-facilities fund. This is a significant new tax increment targeted at high earners specifically to fund additional public services (education), matching the most progressive tax stance.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4095p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2293']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Quantá Crews (State House District 26) / climate-change = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1482a2bc-75d8-4aee-865c-53378c415210', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1482a2bc-75d8-4aee-865c-53378c415210', ct.id, $ctx$Prime sponsor of HB2356 (2026), which repeals A.R.S. 49-191, the sole Arizona statute prohibiting state agencies from adopting or enforcing any program to regulate greenhouse gas emissions. Removing this legal bar is the only currently available legislative vehicle for enabling state climate regulation; the same 'repeal the state's GHG-regulation prohibition' bill type (SB1383) was used to score another Democratic senator climate-change=2 earlier in this wave.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2356p.pdf', 'https://www.azleg.gov/ars/49/00191.htm', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2345']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Quantá Crews (State House District 26) / ai-regulation = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1482a2bc-75d8-4aee-865c-53378c415210', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'ai-regulation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1482a2bc-75d8-4aee-865c-53378c415210', ct.id, $ctx$Prime sponsor of HB2737 (2026), the 'ChatBot Protection Act,' which requires AI chatbot providers to disclose to users that they are interacting with AI, bars processing personal chat data for advertising/profiling without affirmative consent, treats chatbots as products for product-liability purposes, and creates AG/county-attorney enforcement plus a private right of action with civil penalties up to $5,000 per violation. This combination of mandatory risk disclosure and legal responsibility for harm matches requiring AI developers to disclose risks and be held responsible when their systems cause harm.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2737p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2345']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'ai-regulation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Quantá Crews (State House District 26) / data-centers = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1482a2bc-75d8-4aee-865c-53378c415210', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1482a2bc-75d8-4aee-865c-53378c415210', ct.id, $ctx$Prime sponsor of HB2738 (2026), which amends Arizona's computer-data-center tax-relief statute (A.R.S. 41-1519) to require, as a condition of the tax break, a 'cost responsibility agreement' under which the data center owner/operator must pay ALL costs of dedicated electric-utility upgrades needed to serve the facility, with annual reporting and recapture of tax relief for noncompliance. This shifts infrastructure cost onto the data center rather than ratepayers, matching the data-center-self-funds-its-own-dedicated-infrastructure stance; an identical-purpose bill (HB2949) was used to score three other legislators data-centers=2 earlier in this wave.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2738p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2345']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Quantá Crews (State House District 26) / civil-rights = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1482a2bc-75d8-4aee-865c-53378c415210', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1482a2bc-75d8-4aee-865c-53378c415210', ct.id, $ctx$Prime sponsor of HB2742 (2026), the Arizona CROWN Act, which adds protective hairstyles (braids, locks, twists) and hair texture to the state's employment and school anti-discrimination statutes as protected traits historically associated with race. This directly strengthens civil rights enforcement against a specific, documented form of race-based discrimination.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2742p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2345']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lisa Fink (State House District 27) / civil-rights = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '558dc1d6-0365-4707-8373-4ef188aff71c', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '558dc1d6-0365-4707-8373-4ef188aff71c', ct.id, $ctx$Cosponsored HCR2044 (2026), a constitutional amendment referral prohibiting preferential treatment/discrimination based on race or ethnicity in public employment, education, and contracting, and barring DEI/race-based programming funded with public monies. This is a clear match to eliminating affirmative action and race-based government programs.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2044p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2369']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tony Rivero (State House District 27) / civil-rights = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '9c481b8d-e373-4409-bccb-bde6534882da', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '9c481b8d-e373-4409-bccb-bde6534882da', ct.id, $ctx$Cosponsored HCR2044 (2026), a constitutional amendment referral prohibiting preferential treatment/discrimination based on race or ethnicity in public employment, education, and contracting, and barring DEI/race-based programming funded with public monies. This is a clear match to eliminating affirmative action and race-based government programs.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2044p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2368']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tony Rivero (State House District 27) / ai-regulation = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '9c481b8d-e373-4409-bccb-bde6534882da', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'ai-regulation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '9c481b8d-e373-4409-bccb-bde6534882da', ct.id, $ctx$Prime sponsor of HB2311 (2026), which requires AI 'conversational' service operators to disclose to minor users that they are interacting with AI, bars specific harmful outputs to minors (sexual content, romantic/emotional-dependence simulation, claims of providing professional mental-health care), and creates AG-enforced civil penalties up to $500,000 per operator. The disclosure-plus-liability structure matches requiring AI developers to disclose risks and be held responsible when their systems cause harm.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2311p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2368']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'ai-regulation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tony Rivero (State House District 27) / medicare/aid = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '9c481b8d-e373-4409-bccb-bde6534882da', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '9c481b8d-e373-4409-bccb-bde6534882da', ct.id, $ctx$Prime sponsor of HCR2058 (2026), a referred measure requiring a comprehensive claim-level forensic audit of Arizona's AHCCCS (Medicaid) program covering the prior three years, with negotiated settlements and AG referral for unresolved misappropriated claims, self-repealing in 2030. This is a fraud/waste-recovery cost-control measure that does not touch eligibility or benefit levels, matching improving current programs while controlling costs.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2058p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2368']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
