-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch S5 (14 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-S5.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Flavio Bravo (State Senate District 26) / same-sex-marriage = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4046a3d6-87ba-41bb-afd8-422f017c851b', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'same-sex-marriage'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4046a3d6-87ba-41bb-afd8-422f017c851b', ct.id, $ctx$Cosponsored SCR1018 (2026), a resolution proposing a state constitutional amendment that repeals Arizona's existing marriage-restriction clause (Art. XXX, Sec. 1) and replaces it with language guaranteeing that marriage between two individuals may not be prohibited on the basis of sex, race, ethnicity, or national origin. A full, no-carve-out constitutional guarantee of marriage equality aligns with stance 1 (require recognition and full protections).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/scr1018p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2399']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'same-sex-marriage'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Flavio Bravo (State Senate District 26) / trans-athletes = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4046a3d6-87ba-41bb-afd8-422f017c851b', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4046a3d6-87ba-41bb-afd8-422f017c851b', ct.id, $ctx$Cosponsored SB1612 (2026), which fully repeals Arizona's 2022 law (A.R.S. Sec. 15-120.02 and related 2022 session laws) requiring school sports teams to be designated by biological sex, with no substitute documentation or eligibility requirement. An unconditional repeal of the biological-sex-only requirement aligns with stance 1 (allow transgender athletes to compete on teams matching gender identity without restriction).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/sb1612p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2399']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Flavio Bravo (State Senate District 26) / civil-rights = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4046a3d6-87ba-41bb-afd8-422f017c851b', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4046a3d6-87ba-41bb-afd8-422f017c851b', ct.id, $ctx$Cosponsored SB1341 (2026), which adds 'sexual orientation, gender identity and gender expression' as protected classes under Arizona's civil rights statutes governing employment, housing, and public-accommodations discrimination and the state Civil Rights Division's enforcement powers. Directly expanding statutory nondiscrimination coverage aligns with stance 2 (strengthen civil rights enforcement and address systemic discrimination).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/sb1341p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2399']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Flavio Bravo (State Senate District 26) / climate-change = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4046a3d6-87ba-41bb-afd8-422f017c851b', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4046a3d6-87ba-41bb-afd8-422f017c851b', ct.id, $ctx$As a state legislator, joined a March 2024 press conference (with Sen. Juan Mendez) urging the strongest possible federal vehicle-emissions standards and citing Arizona's 61,500+ clean-energy jobs as of 2022 (Arizona Mirror, 3/13/2024). In the current session cosponsored SB1383 (2026), which repeals Arizona's statutory prohibition on state or local greenhouse-gas emissions programs (A.R.S. Title 49, Ch. 1, Art. 6), restoring the state's ability to regulate emissions. Together these support an aggressive clean-energy/emissions posture, aligning with stance 2 (rapidly transition to renewable energy).$ctx$,
       ARRAY['https://azmirror.com/2024/03/13/democrats-push-for-strongest-ever-vehicle-emissions-standards-transition-to-evs/', 'https://www.azleg.gov/legtext/57leg/2R/bills/sb1383p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2399']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Payne (State Senate District 27) / climate-change = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0b0dc6ea-ed45-45e6-9a59-41d1c8aeb53c', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0b0dc6ea-ed45-45e6-9a59-41d1c8aeb53c', ct.id, $ctx$Cosponsored SCM1004 (2026), a formal memorial urging Congress to 'clearly define the EPA's powers and duties and end the EPA's regulation overreach on the economy,' arguing there is 'no consensus as to whether global warming is a problem or a benefit' and that global temperatures, droughts, floods, and hurricanes 'have not increased with increasing global CO2 emissions.' This explicit rejection of climate/emissions regulation aligns with stance 5 (reject climate change policies and focus on economic growth).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/scm1004p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2387']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Payne (State Senate District 27) / deportation = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '0b0dc6ea-ed45-45e6-9a59-41d1c8aeb53c', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'deportation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '0b0dc6ea-ed45-45e6-9a59-41d1c8aeb53c', ct.id, $ctx$Cosponsored SB1444 (2026), which creates a sheriff-administered 'deportation task force' authorizing local law enforcement to coordinate with ICE to deport any unlawfully-present person who has been convicted of, alleged to have committed, or merely detained on suspicion of a criminal offense, and appropriates state funds for it. Tying removal to any criminal-justice contact point (not just violent-crime convictions) aligns with stance 4 (deport everyone without legal status, starting with those who have criminal records).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/sb1444p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2387']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'deportation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank Carroll (State Senate District 28) / climate-change = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '376698b5-a276-4977-b2c3-3d15a822f7d8', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '376698b5-a276-4977-b2c3-3d15a822f7d8', ct.id, $ctx$Prime sponsor of SCM1004 (2026), a memorial urging Congress to 'clearly define the EPA's powers and duties and end the EPA's regulation overreach on the economy' and asserting there is 'no consensus as to whether global warming is a problem or a benefit.' This direct rejection of climate/emissions regulation aligns with stance 5 (reject climate change policies and focus on economic growth).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/scm1004p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2375']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank Carroll (State Senate District 28) / immigration = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '376698b5-a276-4977-b2c3-3d15a822f7d8', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '376698b5-a276-4977-b2c3-3d15a822f7d8', ct.id, $ctx$Prime sponsor of SB1511 (2026), which bars a person from operating a commercial motor vehicle in Arizona without proof of lawful presence in the U.S., authorizes officers to demand such proof, and requires impoundment of the vehicle and cargo if proof is not provided until all citations/charges are cleared. Restricting a specific public commercial privilege to those with legal status aligns with stance 4 (limit public services/privileges to people with legal status).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/sb1511p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2375']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janae Shamp (State Senate District 29) / climate-change = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '687e6f07-f71a-41b4-8525-b509b2cebb42', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '687e6f07-f71a-41b4-8525-b509b2cebb42', ct.id, $ctx$Cosponsored SCM1004 (2026), a memorial urging Congress to end 'the EPA's regulation overreach on the economy' regarding greenhouse gases and asserting there is 'no consensus as to whether global warming is a problem or a benefit.' Aligns with stance 5 (reject climate change policies and focus on economic growth).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/scm1004p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2395']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janae Shamp (State Senate District 29) / deportation = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '687e6f07-f71a-41b4-8525-b509b2cebb42', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'deportation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '687e6f07-f71a-41b4-8525-b509b2cebb42', ct.id, $ctx$Prime sponsor of SB1213 (2026), which requires courts to immediately notify ICE/CBP whenever an unlawfully-present person is convicted of ANY state or local law violation, makes such persons categorically ineligible for probation, bars sanctuary-style limits on cooperation with federal immigration enforcement, and imposes $500-$5,000/day civil penalties on jurisdictions that adopt such limits. Tying mandatory referral to any conviction (not only violent crimes) and eliminating local discretion aligns with stance 4 (deport everyone without legal status, starting with those who have criminal records).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/sb1213p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2395']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'deportation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Janae Shamp (State Senate District 29) / medicare/aid = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '687e6f07-f71a-41b4-8525-b509b2cebb42', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '687e6f07-f71a-41b4-8525-b509b2cebb42', ct.id, $ctx$Prime sponsor of SB1398 (2026), which requires AHCCCS (Arizona's Medicaid program) to redetermine adult enrollees' eligibility at least every six months (versus the standard annual cycle) using available data, and to report application and verification volumes to the legislature annually. This is a program-integrity/cost-control measure that does not eliminate any benefit category, aligning with stance 3 (improve current programs while controlling costs).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/sb1398p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2395']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hildy Angius (State Senate District 30) / healthcare = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4fe779de-6a47-4321-82f1-ced096543a68', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4fe779de-6a47-4321-82f1-ced096543a68', ct.id, $ctx$Prime sponsor of SB1165 (2026, cosponsored by Sen. Carroll), which bars all categories of health insurers operating in Arizona (hospital/medical service corporations, health care services organizations, disability insurers, and group/blanket disability insurers) from imposing cost-sharing (deductibles, copays) on diagnostic and supplemental breast examinations beginning 2027. Regulating private insurance broadly, not means-tested, to expand affordable coverage of a specific service aligns with stance 2 (affordable coverage through regulated private insurance).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/sb1165p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2373']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hildy Angius (State Senate District 30) / climate-change = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4fe779de-6a47-4321-82f1-ced096543a68', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4fe779de-6a47-4321-82f1-ced096543a68', ct.id, $ctx$Cosponsored SCM1004 (2026), a memorial urging Congress to end 'the EPA's regulation overreach on the economy' regarding greenhouse gases and arguing there is 'no consensus as to whether global warming is a problem or a benefit.' Aligns with stance 5 (reject climate change policies and focus on economic growth).$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/scm1004p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2373']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Timothy "Tim" Dunn (State Senate District 25) / abortion = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ebef00e8-7722-4e9b-b5dc-ef95a41a9a40', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ebef00e8-7722-4e9b-b5dc-ef95a41a9a40', ct.id, $ctx$As HD-25 state representative on April 24, 2024, Dunn was one of only three House Republicans (with Gress and Wilmeth) who voted with Democrats to pass HB2677 (32-28), repealing Arizona's near-total 1864 abortion ban and preserving the state's 15-week gestational-limit framework instead. Named individually in AZ Mirror's vote report. Vote-only evidence (no stated rationale found); scored at the first-trimester/exceptions chair consistent with the other named crossovers (Bolick, Shope, Wilmeth). Row added by orchestrator 2026-07-13 after the S5 batch returned Dunn empty — his 2026 Senate bill record is non-topical, but this House-era named vote passes the individual-vote bar.$ctx$,
       ARRAY['https://azmirror.com/2024/04/24/az-house-has-voted-to-repeal-the-1864-abortion-ban-upheld-by-the-supreme-court/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
