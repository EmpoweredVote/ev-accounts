-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch H10 (13 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-H10.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Beverly Pingerelli (State House District 28) / civil-rights = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '184bd445-9f61-4bd3-859f-22522c9ccabd', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '184bd445-9f61-4bd3-859f-22522c9ccabd', ct.id, $ctx$Cosponsor of HCR2044 (2026), a proposed state constitutional amendment that bans 'preferential treatment' and any consideration of race/ethnicity in public employment, education, and contracting, and bars DEI/diversity training and programming in public institutions. This matches the scale's most conservative chair, eliminating affirmative action and race-based government programs.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2044p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2333']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Beverly Pingerelli (State House District 28) / voting-rights = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '184bd445-9f61-4bd3-859f-22522c9ccabd', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '184bd445-9f61-4bd3-859f-22522c9ccabd', ct.id, $ctx$Named cosponsor of both HCR2001 (2026 'Arizona Secure Elections Act,' mandating concurrent photo ID with ballot casting, a Friday-before-election early-voting cutoff, and mail-in ballots only on affirmative request) and HCR2016 (2026, bars counties from using flexible voting centers in place of assigned precinct polling places). Both bills tighten voter-access mechanics without eliminating mail voting outright, matching the scale's photo-ID/roll-tightening chair.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2001p.pdf', 'https://www.azleg.gov/legtext/57leg/2R/bills/hcr2016p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2333']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Livingston (State House District 28) / civil-rights = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '43e734b4-4417-4dcd-91c9-f420f3a1b702', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '43e734b4-4417-4dcd-91c9-f420f3a1b702', ct.id, $ctx$Cosponsor of HCR2044 (2026), a proposed state constitutional amendment that bans 'preferential treatment' and any consideration of race/ethnicity in public employment, education, and contracting, and bars DEI/diversity training and programming in public institutions. This matches the scale's most conservative chair, eliminating affirmative action and race-based government programs.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2044p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2319']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Taylor (State House District 29) / civil-rights = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ee80504a-fe2d-45e1-8bbe-ce0a5042d2b8', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ee80504a-fe2d-45e1-8bbe-ce0a5042d2b8', ct.id, $ctx$Cosponsor of HCR2044 (2026), a proposed state constitutional amendment that bans 'preferential treatment' and any consideration of race/ethnicity in public employment, education, and contracting, and bars DEI/diversity training and programming in public institutions. This matches the scale's most conservative chair, eliminating affirmative action and race-based government programs.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2044p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2370']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Taylor (State House District 29) / growth-and-development = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ee80504a-fe2d-45e1-8bbe-ce0a5042d2b8', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'growth-and-development'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ee80504a-fe2d-45e1-8bbe-ce0a5042d2b8', ct.id, $ctx$Sole prime sponsor of HB2492 (2026), which voids any city, county, or state law, rule, ordinance, or contract that establishes urban growth boundaries preventing new development, restraining trade, or blocking extension of public services -- a total prohibition on growth-boundary regulation. This matches the scale's chair calling for removing regulatory barriers to development entirely and letting market demand set growth pace.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2492p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2370']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'growth-and-development'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Taylor (State House District 29) / immigration = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ee80504a-fe2d-45e1-8bbe-ce0a5042d2b8', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ee80504a-fe2d-45e1-8bbe-ce0a5042d2b8', ct.id, $ctx$Named cosponsor of HB2806 (2026, Rep. Gillette prime), which mandates federal SAVE-program verification of lawful presence before a person can register to vote, obtain a driver's license/ID, or qualify for AHCCCS (state Medicaid), and bars issuance/eligibility without it. The bill's core action -- restricting public programs and services to those with verified legal status -- matches the scale's chair limiting public services to people with legal status.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2806p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2370']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Montenegro (State House District 29) / civil-rights = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '47071c20-df9d-4f9d-9329-25faf64cd163', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '47071c20-df9d-4f9d-9329-25faf64cd163', ct.id, $ctx$Prime sponsor of HCR2044 (2026), a proposed state constitutional amendment that bans 'preferential treatment' and any consideration of race/ethnicity in public employment, education, and contracting, and bars DEI/diversity training and programming in public institutions. This matches the scale's most conservative chair, eliminating affirmative action and race-based government programs.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2044p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2325']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Gillette (State House District 30) / civil-rights = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '50d00238-5334-4616-ac43-72375f53df71', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '50d00238-5334-4616-ac43-72375f53df71', ct.id, $ctx$Cosponsor of HCR2044 (2026), a proposed state constitutional amendment that bans 'preferential treatment' and any consideration of race/ethnicity in public employment, education, and contracting, and bars DEI/diversity training and programming in public institutions. This matches the scale's most conservative chair, eliminating affirmative action and race-based government programs.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2044p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2306']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Gillette (State House District 30) / immigration = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '50d00238-5334-4616-ac43-72375f53df71', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '50d00238-5334-4616-ac43-72375f53df71', ct.id, $ctx$Prime sponsor of HB2806 (2026), which mandates federal SAVE-program verification of lawful presence before a person can register to vote, obtain a driver's license/ID, or qualify for AHCCCS (state Medicaid), and bars issuance/eligibility without it. The bill's core action -- restricting public programs and services to those with verified legal status -- matches the scale's chair limiting public services to people with legal status.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2806p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2306']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Gillette (State House District 30) / voting-rights = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '50d00238-5334-4616-ac43-72375f53df71', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '50d00238-5334-4616-ac43-72375f53df71', ct.id, $ctx$Named cosponsor of HCR2016 (2026), which bars county boards of supervisors from authorizing flexible voting centers in place of, or in addition to, assigned precinct polling places -- reverting to strict precinct-only voting. This tightens voter-access mechanics without eliminating mail voting outright, matching the scale's photo-ID/roll-tightening chair.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2016p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2306']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Leo Biasiucci (State House District 30) / civil-rights = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'b1b97401-d1a9-4442-9f78-2749f1853f6e', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'b1b97401-d1a9-4442-9f78-2749f1853f6e', ct.id, $ctx$Cosponsor of HCR2044 (2026), a proposed state constitutional amendment that bans 'preferential treatment' and any consideration of race/ethnicity in public employment, education, and contracting, and bars DEI/diversity training and programming in public institutions. This matches the scale's most conservative chair, eliminating affirmative action and race-based government programs.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2044p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2294']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Leo Biasiucci (State House District 30) / immigration = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'b1b97401-d1a9-4442-9f78-2749f1853f6e', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'b1b97401-d1a9-4442-9f78-2749f1853f6e', ct.id, $ctx$Named cosponsor of HB2806 (2026, Rep. Gillette prime), which mandates federal SAVE-program verification of lawful presence before a person can register to vote, obtain a driver's license/ID, or qualify for AHCCCS (state Medicaid), and bars issuance/eligibility without it. The bill's core action -- restricting public programs and services to those with verified legal status -- matches the scale's chair limiting public services to people with legal status.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2806p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2294']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Leo Biasiucci (State House District 30) / transportation-priorities = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'b1b97401-d1a9-4442-9f78-2749f1853f6e', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'transportation-priorities'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'b1b97401-d1a9-4442-9f78-2749f1853f6e', ct.id, $ctx$As Transportation & Infrastructure Committee chairman, sole prime sponsor of HB2304 (2026), a FY2026-27 appropriations bill directing roughly $40M+ across about 15 line items entirely to road, street, and bridge paving/improvement projects in cities, towns, and counties statewide, with no transit, pedestrian, or bike-infrastructure allocations. Matches the scale's chair focused on road capacity for the driving majority.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2304p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2294']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'transportation-priorities'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
