-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch S1 (9 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-S1.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Mark Finchem (State Senate District 1) / school-vouchers = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '489e2fc3-b47a-4304-b959-07e35f010da4', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '489e2fc3-b47a-4304-b959-07e35f010da4', ct.id, $ctx$In the final hours of the 2026 session, Finchem was an active floor defender of HCR2048/related GOP ballot referrals designed to block citizen-led initiatives from regulating or reforming Arizona's universal Empowerment Scholarship Account program, arguing more competing ballot referrals meant more voter "choice." This supports keeping the voucher system universal and unregulated, matching the most permissive chair.$ctx$,
       ARRAY['https://azmirror.com/2026/06/13/after-compromise-dies-arizona-gop-rushes-through-ballot-referral-to-block-voucher-reforms/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shawnna Bolick (State Senate District 2) / abortion = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '2785d691-2404-400e-8dde-bcc5a58e419b', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '2785d691-2404-400e-8dde-bcc5a58e419b', ct.id, $ctx$Bolick was one of only two Republican state senators who crossed party lines on May 1, 2024 to repeal Arizona's near-total 1864 abortion ban, allowing the 15-week gestational-limit law (permitting elective abortion up to 15 weeks) to take effect instead. That result sits closest to the first-trimester-plus-exceptions chair rather than the near-total ban Republican colleagues wanted to keep.$ctx$,
       ARRAY['https://azmirror.com/2024/05/01/the-az-senate-has-repealed-the-1864-abortion-ban-after-2-republicans-join-dems/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shawnna Bolick (State Senate District 2) / voting-rights = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '2785d691-2404-400e-8dde-bcc5a58e419b', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '2785d691-2404-400e-8dde-bcc5a58e419b', ct.id, $ctx$As a state representative in 2019-2020, Bolick served on the House Elections Committee and sponsored HB2200 limiting emergency voting centers, plus other election bills; in 2020-2021 she authored a bill letting a simple legislative majority revoke the secretary of state's certification of presidential electors with no cause required. Running for Secretary of State in 2021 she framed her platform explicitly around distrust of the 2020 result and restoring 'trust.' Scored at the photo-ID/roll-tightening chair rather than the maximal chair: none of her documented actions propose eliminating mail-in voting, which the most restrictive stance requires. (Re-chaired 5-to-4 by orchestrator on review, 2026-07-13.)$ctx$,
       ARRAY['https://azmirror.com/2021/06/22/shawnna-bolick-author-of-bill-to-reject-voters-presidential-choice-running-to-be-top-elections-official/', 'https://ballotpedia.org/Shawnna_Bolick']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Kavanagh (State Senate District 3) / deportation = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4f7db8ce-def5-4225-b183-654f8f64cb9a', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'deportation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4f7db8ce-def5-4225-b183-654f8f64cb9a', ct.id, $ctx$Kavanagh has been one of the legislature's leading proponents of strict immigration enforcement: in 2019 he defended SB1070's core provisions as 'heart and soul' constitutional and sponsored a bill imposing civil liability on Arizona cities/counties that fail to check the immigration status of people with a prior felony conviction who reoffend, or that ignore ICE detainers on them. This targeted-but-broad enforcement focus (criminal-history-first, but within an expansive 'show me your papers' framework) matches the chair closest to deporting everyone without legal status starting with criminal records.$ctx$,
       ARRAY['https://azmirror.com/2019/10/25/legislator-readies-defense-of-heart-and-soul-of-sb1070-as-tucson-voters-decide-on-sanctuary-city-measure/', 'https://azmirror.com/2020/02/25/ice-detainers-sanctuary-cities-bill-still-alive/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'deportation'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Kavanagh (State Senate District 3) / homelessness = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '4f7db8ce-def5-4225-b183-654f8f64cb9a', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'homelessness'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '4f7db8ce-def5-4225-b183-654f8f64cb9a', ct.id, $ctx$Kavanagh sponsored SB1022 (2023), criminalizing panhandling in medians/certain public areas, and SB1024 (2023), criminalizing sitting, lying down or sleeping on public sidewalks modeled on a Phoenix 'urban sleeping' ban, with no linkage to shelter-bed availability. This direct criminalization of public sleeping and solicitation, defended on public-safety grounds, matches the most enforcement-focused chair.$ctx$,
       ARRAY['https://azmirror.com/2023/01/18/pair-of-proposed-bills-would-criminalize-homelessness-in-arizona/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'homelessness'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carine Werner (State Senate District 4) / taxes = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'b769f53e-c9e5-4259-9e00-c20bfa945d15', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'b769f53e-c9e5-4259-9e00-c20bfa945d15', ct.id, $ctx$Werner's campaign platform states she will 'promote legislation to advance economic growth and opportunities for prosperity through low taxes' and pledges to 'stand firmly against legislation that attempts to increase the burden on families and businesses,' a general tax-cutting, anti-tax-increase position without a specific flat-tax or drastic-cut proposal.$ctx$,
       ARRAY['https://wernerforaz.com/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carine Werner (State Senate District 4) / housing = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'b769f53e-c9e5-4259-9e00-c20bfa945d15', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'b769f53e-c9e5-4259-9e00-c20bfa945d15', ct.id, $ctx$In the 2025 session Werner sponsored SB1729, which would have created a first-time homebuyer assistance program funded through the state (held in Senate Finance committee). This is a targeted-assistance approach rather than large-scale public housing or deregulation, matching the chair for subsidies/first-time buyer assistance.$ctx$,
       ARRAY['https://ballotpedia.org/Carine_Werner']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lela Alston (State Senate District 5) / abortion = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '64520134-c1e3-44b1-aeb5-ed3e8762972d', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '64520134-c1e3-44b1-aeb5-ed3e8762972d', ct.id, $ctx$Alston, Senate Minority Caucus Chair, co-filed an ethics complaint over Senate GOP leadership blocking a floor vote to repeal the 1864 near-total abortion ban and spoke at an April 2024 press conference recalling the era before Roe v. Wade to argue for restoring broad abortion access; she supported repealing the near-total ban in favor of the 15-week/broader-access framework that followed, consistent with legality through the second trimester with rare exceptions after.$ctx$,
       ARRAY['https://azmirror.com/2024/04/15/dems-say-republicans-broke-senate-rules-by-ignoring-attempts-to-force-a-vote-on-an-abortion-ban-repeal/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Theresa Hatathlie (State Senate District 6) / voting-rights = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '5443de2a-bad1-4271-a8ac-30e7443ff605', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '5443de2a-bad1-4271-a8ac-30e7443ff605', ct.id, $ctx$In a January 2026 Senate Judiciary and Elections Committee hearing, Hatathlie raised concerns about HCR2001, a GOP resolution that would end automatic mail-ballot mailing (requiring a request each election), cut off Election-Day/weekend mail-ballot drop-offs, and add a concurrent government-ID requirement for mail voters. Drawing on her own and family members' documented difficulty obtaining a state ID as tribal members without accessible birth certificates, she opposed the added ID/access barriers, consistent with defending broad mail-voting access rather than restricting it.$ctx$,
       ARRAY['https://azmirror.com/2026/02/09/arizona-house-approves-resolution-ending-election-day-ballot-drop-offs/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
