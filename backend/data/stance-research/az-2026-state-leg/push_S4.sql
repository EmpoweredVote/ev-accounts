-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch S4 (14 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-S4.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- David Gowan (State Senate District 19) / abortion = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'e71471f4-bef5-46ef-a1f2-f19f275b558d', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'e71471f4-bef5-46ef-a1f2-f19f275b558d', ct.id, $ctx$Gowan voted Nay on the Senate Third Reading of HB2677 (May 1, 2024), the repeal of Arizona's 1864 near-total abortion ban — verified by the orchestrator against the LegiScan roll-call record on 2026-07-13 (the same roll call independently confirms the Bolick/Shope crossover Yeas). His vote to preserve a law permitting abortion only to save the mother's life is scored at the most restrictive chair containing any exception, consistent with the Mesnard/Hoffman/Farnsworth vote-only calibration, since chair 5 requires a no-exceptions ban with patient criminal penalties. Row added by orchestrator after the S4 batch returned Gowan empty.$ctx$,
       ARRAY['https://legiscan.com/AZ/rollcall/HB2677/id/1437377']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sally Ann Gonzales (State Senate District 20) / healthcare = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '82f31f9c-754b-4417-bc21-af295b2b4d2b', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '82f31f9c-754b-4417-bc21-af295b2b4d2b', ct.id, $ctx$Prime sponsor of SB1771 (57th Leg, "health insurance; requirements; essential benefits"), which mandates essential health benefit coverage requirements for private health insurance plans. This regulates private insurance to guarantee coverage rather than pursuing single-payer or leaving coverage unregulated, matching a mixed public/regulated-private approach.$ctx$,
       ARRAY['https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2381']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sally Ann Gonzales (State Senate District 20) / housing = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '82f31f9c-754b-4417-bc21-af295b2b4d2b', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '82f31f9c-754b-4417-bc21-af295b2b4d2b', ct.id, $ctx$Prime sponsor of SB1779 (2026, "mandatory inclusionary zoning; prohibition"), verified via full bill text: it REPEALS Arizona Revised Statutes section 9-461.16 and related sections 11-819 and 33-1329, which currently prohibit municipalities from requiring inclusionary zoning. Repealing the state prohibition would allow cities to require developers to include affordable units in new developments, matching the "require new developments to include affordable units" chair.$ctx$,
       ARRAY['https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2381', 'https://www.azleg.gov/legtext/57leg/2R/bills/SB1779P.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rosanna Gabaldón (State Senate District 21) / abortion = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8cbc6c91-4147-4831-ae0e-f4658ce282e8', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8cbc6c91-4147-4831-ae0e-f4658ce282e8', ct.id, $ctx$Co-sponsor of a consistent bloc of 11 companion bills repealing Arizona abortion restrictions in the 2025-2026 session: HB2522/SB1396 (contraception rights), HB2524 (repeal of advertising restriction), HB2525/SB1395 (repeal of reporting requirements), HB2526 (repeal of medication-mailing restriction), HB2527 (repeal of telemedicine abortion prohibition), HB2530 (repeal of waiting period/mandatory ultrasound), and HB2528/SB1394 (fertility treatment access). This is a co-sponsorship pattern, not a vote or prime sponsorship, but its volume and directional consistency (uniformly removing procedural abortion restrictions) supports a pro-access position; it does not address public funding, so it falls short of the "publicly funded at all stages" chair.$ctx$,
       ARRAY['https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2380']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rosanna Gabaldón (State Senate District 21) / voting-rights = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8cbc6c91-4147-4831-ae0e-f4658ce282e8', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8cbc6c91-4147-4831-ae0e-f4658ce282e8', ct.id, $ctx$Co-sponsor of six voting-access-expansion bills: SB1343 ("state voting rights act"), SB1344 ("permanent early voting list"), SB1262 ("voting centers; early voting; security"), SB1358 ("polling places; drop boxes; campuses"), SB1690 (visually impaired voter access), and HCR2024 ("constitutional right to vote"). This is a co-sponsorship pattern rather than a personal vote, but the volume and consistency across six separate access-expansion measures supports a stance of expanding early/mail voting access.$ctx$,
       ARRAY['https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2380']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rosanna Gabaldón (State Senate District 21) / same-sex-marriage = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8cbc6c91-4147-4831-ae0e-f4658ce282e8', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'same-sex-marriage'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8cbc6c91-4147-4831-ae0e-f4658ce282e8', ct.id, $ctx$Co-sponsor of SCR1018, "same-sex marriage; constitutional right," an Arizona constitutional resolution that repeals the state's marriage-restriction clause (Art. XXX Sec. 1) and replaces it with a guarantee that marriage between two individuals may not be prohibited based on sex, race, ethnicity, or national origin. The resolution text (verified via bill PDF in a parallel batch) contains no religious or organizational carve-out, so this full, unqualified constitutional guarantee matches the require-recognition-and-full-protections chair. (Re-chaired 2-to-1 by orchestrator for cross-batch consistency with the same resolution's other co-sponsors, 2026-07-13.)$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/scr1018p.pdf', 'https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2380']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'same-sex-marriage'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rosanna Gabaldón (State Senate District 21) / local-immigration = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8cbc6c91-4147-4831-ae0e-f4658ce282e8', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8cbc6c91-4147-4831-ae0e-f4658ce282e8', ct.id, $ctx$Co-sponsor of SB1342 (2026, "immigration; government agencies; prohibited acts"), verified via full bill text: it bars Arizona municipal law enforcement from stopping/detaining people based on immigration status, honoring ICE detainers, sharing databases with federal immigration authorities, or entering 287(g)-style enforcement agreements. Also co-sponsored SB1660 ("attorney general; policies; immigration"). Evidence is co-sponsorship, not prime sponsorship, but the bill is squarely on-topic and she is one of a small named cosponsor list.$ctx$,
       ARRAY['https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2380', 'https://www.azleg.gov/legtext/57leg/2R/bills/SB1342P.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Eva Diaz (State Senate District 22) / school-vouchers = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '901398ea-3180-4b6d-8ba4-9f0dd85d7bb1', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '901398ea-3180-4b6d-8ba4-9f0dd85d7bb1', ct.id, $ctx$Prime sponsor of a bloc of Empowerment Scholarship Account (ESA/voucher) accountability bills in the 2025-2026 session: SB1691 (assessments/standards/accreditation), SB1692 (tutor safety rules), SB1698 (evaluations for children with disabilities), SB1699 (distribution intervals), SB1700 (fingerprinting requirements for qualified schools), SB1702 (qualified-school audits/reporting), SB1703 (parental notification of waived rights), and SB1704 (requirements for children with disabilities). These add oversight, audits, and accountability requirements to Arizona's universal ESA program rather than eliminating it or expanding it further, matching the accountability-requirements chair.$ctx$,
       ARRAY['https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2376']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Fernandez (State Senate District 23) / healthcare = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '2aa0cf37-6c3a-405d-9cd2-0fafc7cf8636', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '2aa0cf37-6c3a-405d-9cd2-0fafc7cf8636', ct.id, $ctx$Prime sponsor of a cluster of health-insurance regulation bills in the 2025-2026 session: SB1225 ("pharmacies; cost sharing requirement; rebates"), SB1226 ("pricing; covered goods; requirements"), SB1227 ("prior authorization; gold card exemption," verified via full text - requires insurers to exempt high-performing providers from prior authorization), SB1228 ("health insurers; provisional provider credentialing"), and SB1296 ("health insurance; private employers; coverage"). This pattern regulates private insurance/pharmacy costs and access without proposing single-payer or deregulation, matching a mixed public-program/regulated-private-insurance approach.$ctx$,
       ARRAY['https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2379', 'https://www.azleg.gov/legtext/57leg/2R/bills/SB1227P.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Fernandez (State Senate District 23) / voting-rights = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '2aa0cf37-6c3a-405d-9cd2-0fafc7cf8636', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '2aa0cf37-6c3a-405d-9cd2-0fafc7cf8636', ct.id, $ctx$Prime sponsor of SB1229 (2026, "early voting; identification; emergency voting"), verified via full bill text: it amends A.R.S. 16-542 to change county recorders' early voting location duty from "MAY establish" to "SHALL establish," mandating on-site early voting locations be available starting the same day early ballots go out. This expands guaranteed early voting access statewide.$ctx$,
       ARRAY['https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2379', 'https://www.azleg.gov/legtext/57leg/2R/bills/SB1229P.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Analise Ortiz (State Senate District 24) / abortion = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'bb540c4b-e5d2-40b9-bdaf-e41a721572f8', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'bb540c4b-e5d2-40b9-bdaf-e41a721572f8', ct.id, $ctx$Prime sponsor of SB1218 (2026, "abortion; repeals"), verified via full bill text: an omnibus repeal spanning A.R.S. 35-196.02 (state public-funding restriction on abortion), Title 36 Chapter 4 Article 10 (informed-consent/waiting-period requirements), and Title 36 Chapter 23 Articles 1 and 3 (procedure-based restrictions), among ~20 other sections. Because the repeal reaches the public-funding restriction specifically alongside procedural and gestational-stage restrictions, it best matches legal, accessible, and publicly funded abortion access at all stages rather than a second-trimester cutoff.$ctx$,
       ARRAY['https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2384', 'https://www.azleg.gov/legtext/57leg/2R/bills/SB1218P.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Analise Ortiz (State Senate District 24) / local-immigration = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'bb540c4b-e5d2-40b9-bdaf-e41a721572f8', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'bb540c4b-e5d2-40b9-bdaf-e41a721572f8', ct.id, $ctx$Prime sponsor of SB1342 (2026, "immigration; government agencies; prohibited acts"), verified via full bill text: bars Arizona municipal law enforcement agencies/officials from stopping, questioning, arresting, or prolonging detention based on immigration status; from honoring ICE civil detainers; from sharing municipal databases or facility access with federal immigration authorities; and from entering 287(g)-style federal immigration enforcement agreements.$ctx$,
       ARRAY['https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2384', 'https://www.azleg.gov/legtext/57leg/2R/bills/SB1342P.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Analise Ortiz (State Senate District 24) / immigration = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'bb540c4b-e5d2-40b9-bdaf-e41a721572f8', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'bb540c4b-e5d2-40b9-bdaf-e41a721572f8', ct.id, $ctx$Same bill, SB1342 (2026), section 9-1002 ("Collection and disclosure of records") restricts municipalities and health care facilities from disclosing a person's immigration status collected to assess eligibility for public services, benefits, or programs. This supports letting residents access public services regardless of immigration status.$ctx$,
       ARRAY['https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2384', 'https://www.azleg.gov/legtext/57leg/2R/bills/SB1342P.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Analise Ortiz (State Senate District 24) / housing = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'bb540c4b-e5d2-40b9-bdaf-e41a721572f8', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'bb540c4b-e5d2-40b9-bdaf-e41a721572f8', ct.id, $ctx$Prime sponsor of SB1441 (2026, "single-family residence purchases; limitations"), verified via full bill text: caps corporate/LLC purchases of single-family homes at 5% of a census tract's total and 50 units/year statewide, caps total corporate ownership at 2,000 units, requires registration with the Corporation Commission, and directs civil penalties into the state Housing Trust Fund. This is a market-regulation intervention aimed at housing affordability, matching a regulated-market approach to housing.$ctx$,
       ARRAY['https://www.azleg.gov/Senate/Senate-member/?legislature=57&session=130&legislator=2384', 'https://www.azleg.gov/legtext/57leg/2R/bills/SB1441P.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
