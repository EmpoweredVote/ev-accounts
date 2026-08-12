-- 1721_md_classc_sourcing.sql
-- CLASS-C SOURCING for the instrument-free Maryland rows left by migration 1714.
--
-- These rows named no bill and no act. Each member's own mgaleg sponsored-legislation list was
-- read per session, filtered to the topic, and every shortlisted bill's SYNOPSIS was read; the
-- citation is chosen per row by reading, not by score.
--
-- 🔑 CHAIRS ARE NOT TOUCHED. Reasoning and sources only.
--
-- 🔴 WHAT THE OLD TEXT WAS. Every healthcare row said the member "backed Medicaid expansion" —
-- template text. Maryland expanded Medicaid in 2013, before most of these members were seated,
-- so for them it was not merely unsourced but impossible. The housing rows run the same shape.
--
-- 🔴 9 ROWS ARE DELIBERATELY LEFT OWED rather than sourced to something weak:
--   · Kevin M. Harris / Healthcare Access: only broad co-sponsorships (preventive-services recommendations); 3 pre-switch sessions unreadable
--   · Sara Love / Healthcare Access: only co-sponsorships of preventive-services bills; 6 pre-switch sessions unreadable
--   · Ron Watson / Healthcare Access: lead bills are paternity testing and sickle cell — public health, not coverage or access; 3 sessions unreadable
--   · Ron Watson / Affordable Housing: no on-topic bill in readable sessions; 3 sessions unreadable
--   · Arthur Ellis / Same-Sex Marriage: entire tenure readable and contains no same-sex-marriage bill — Maryland settled the question in 2012, before he was seated
--   · Kevin M. Harris / Same-Sex Marriage: only hit is a financial-disclosure ethics bill mentioning domestic partners; not a marriage position
--   · Benjamin F. Kramer / Same-Sex Marriage: no on-topic bill in readable sessions; 6 pre-switch sessions unreadable
--   · Ron Watson / Same-Sex Marriage: no on-topic bill in readable sessions; 3 sessions unreadable
--   · C. Anthony Muse / Childcare Affordability & Access: no on-topic bill in readable sessions; 7 sessions unreadable
--
-- 🔴🔴 THE UNREADABLE-SESSION TRAP. mgaleg member records are CHAMBER-SCOPED: asking a current
-- senator's record for a session when they sat in the House returns an EMPTY LIST, not an error.
-- Alonzo T. Washington's ten House sessions read as "sponsored nothing". So "no bill found" is
-- never reported as a fact about a member with unreadable sessions — it is reported as owed.
--
-- ✓ Kevin M. Harris / Childcare Affordability & Access: already cites SB0664 (2026), which he leads, and SB0402 (2026), enacted as Chapter 641 — both confirmed by slug — left unchanged.
--
-- Rollback: data/stance-retirement/2026-08-12-classc-1721-rollback.json
BEGIN;

CREATE TEMP TABLE cc_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT coalesce(sum(value), 0) FROM inform.politician_answers) AS chair_sum_before;

CREATE TEMP TABLE cc_intent (pid uuid, tid uuid, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO cc_intent (pid, tid, reasoning, sources) VALUES
-- Joanne C. Benson / Healthcare Access — lead on 2023RS:sb0965
('4a7dc8a6-2138-4472-8197-8b878034f029', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Benson was the lead sponsor of SB0965 (2023), requiring health insurers to cover lung cancer screening and diagnostic imaging and capping what they may charge for it. It was enacted as Chapter 353 of 2023.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0965?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson','https://ballotpedia.org/Joanne_Benson']::text[]),
-- Nick Charles / Healthcare Access — lead on 2025RS:sb0518
('cf190bac-9369-4175-bd4b-8ba776697d9c', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Charles was the lead sponsor of SB0518 (2025), requiring insurers to cover preventive ovarian cancer screening and prohibiting them from imposing a copayment, coinsurance or deductible for it.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0518?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02','https://ballotpedia.org/Nick_Charles']::text[]),
-- Arthur Ellis / Healthcare Access — lead on 2025RS:sb0094
('4754dede-4a3b-4280-a8b1-7497530107f7', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Ellis was the lead sponsor of SB0094 (2025), requiring the Maryland Medical Assistance Program to cover self-measured blood pressure monitoring for maternal health, and to reimburse the provider time it takes. It was enacted as Chapter 715 of 2025.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0094?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]),
-- Shaneka Henson / Healthcare Access — lead on 2025RS:sb0508
('05c9b5b9-cb2b-4387-ab6b-350b69553fac', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Henson was the lead sponsor of SB0508 (2025), requiring the Maryland Medical Assistance Program and private insurers to cover medically necessary restorative care for victims of domestic violence.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0508?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02','https://ballotpedia.org/Shaneka_Henson']::text[]),
-- William C. Smith, Jr. / Healthcare Access — lead on 2019RS:sb0765
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Smith was the lead sponsor of SB0765 (2019), extending from 18 to 36 months the period for which group health plans must offer continuation coverage to people who lose their job.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0765?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02','https://ballotpedia.org/William_C._Smith']::text[]),
-- Cheryl C. Kagan / Healthcare Access — lead on 2020RS:sb0402
('e35d5990-55c7-42e2-94bc-27cb1c49b5f1', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Kagan was the lead sponsor of SB0402 (2020), letting health care practitioners establish a patient relationship by telehealth, which widens access where providers are scarce. It was enacted as Chapter 16 of 2020.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0402?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01','https://ballotpedia.org/Cheryl_C._Kagan']::text[]),
-- C. Anthony Muse / Healthcare Access — lead on 2025RS:sb0646
('47823046-7dea-4a4f-a11b-0c5890539891', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Muse was the lead sponsor of SB0646 (2025), barring insurers from imposing step-therapy or fail-first protocols on insulin. It was enacted as Chapter 689 of 2025.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0646?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01','https://ballotpedia.org/C._Anthony_Muse']::text[]),
-- Jim Rosapepe / Healthcare Access — lead on 2018RS:sb0858
('9c400214-f007-4a8d-92fe-5f5d23b3838e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Rosapepe was the lead sponsor of SB0858 (2018), requiring carriers to let enrollees use local health departments as in-network providers. It was enacted as Chapter 488 of 2018.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0858?ys=2018RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe','https://ballotpedia.org/Jim_Rosapepe']::text[]),
-- Alonzo T. Washington / Healthcare Access — cosp on 2025RS:sb0372
('8c8b0896-dfd0-4d3c-8492-e594d93b78ca', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Washington co-sponsored SB0372 (2025), the Preserve Telehealth Access Act of 2025, which keeps telehealth coverage and payment parity in place. It was enacted as Chapter 481 of 2025.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0372?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02','https://ballotpedia.org/Alonzo_Washington']::text[]),
-- Joanne C. Benson / Affordable Housing — lead on 2024RS:sb0992
('4a7dc8a6-2138-4472-8197-8b878034f029', '669cac97-66a6-4087-b036-936fbe62efb3', 'Benson was the lead sponsor of SB0992 (2024), requiring a landlord to notify a tenant once a court has issued a warrant of restitution for failure to pay rent, before the tenant can be put out.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0992?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson','https://ballotpedia.org/Joanne_Benson']::text[]),
-- Nick Charles / Affordable Housing — lead on 2024RS:sb0671
('cf190bac-9369-4175-bd4b-8ba776697d9c', '669cac97-66a6-4087-b036-936fbe62efb3', 'Charles was the lead sponsor of SB0671 (2024), establishing access to counsel so homeowners have legal representation in foreclosure proceedings.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0671?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02','https://ballotpedia.org/Nick_Charles']::text[]),
-- Arthur Ellis / Affordable Housing — lead on 2021RS:sb0937
('4754dede-4a3b-4280-a8b1-7497530107f7', '669cac97-66a6-4087-b036-936fbe62efb3', 'Ellis was the lead sponsor of SB0937 (2021), requiring the Department of Housing and Community Development to weigh a family’s student loan debt when setting eligibility for mortgage, down payment and settlement expense assistance.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0937?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]),
-- Kevin M. Harris / Affordable Housing — cosp on 2026RS:sb0389
('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1', '669cac97-66a6-4087-b036-936fbe62efb3', 'Harris co-sponsored SB0389 (2026), automatically designating qualifying transit-oriented developments as enterprise zones to speed housing construction near transit.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0389?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03','https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]),
-- Shaneka Henson / Affordable Housing — lead on 2025RS:sb0856
('05c9b5b9-cb2b-4387-ab6b-350b69553fac', '669cac97-66a6-4087-b036-936fbe62efb3', 'Henson was the lead sponsor of SB0856 (2025), the Maryland Tenant Mold Protection Act, setting landlord obligations and regulations for mold in rental housing. It was enacted as Chapter 539 of 2025.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0856?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02','https://ballotpedia.org/Shaneka_Henson']::text[]),
-- William C. Smith, Jr. / Affordable Housing — lead on 2018RS:sb1218
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc', '669cac97-66a6-4087-b036-936fbe62efb3', 'Smith was the lead sponsor of SB1218 (2018), the Ending Youth Homelessness Act, establishing a grant program to prevent and end youth homelessness. It was enacted as Chapter 748 of 2018.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1218?ys=2018RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02','https://ballotpedia.org/William_C._Smith']::text[]),
-- Cheryl C. Kagan / Affordable Housing — cosp on 2023RS:sb0848
('e35d5990-55c7-42e2-94bc-27cb1c49b5f1', '669cac97-66a6-4087-b036-936fbe62efb3', 'Kagan co-sponsored SB0848 (2023), establishing a Statewide Rental Assistance Voucher Program to provide housing vouchers through the Department of Housing and Community Development. It was enacted as Chapter 446 of 2023.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0848?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01','https://ballotpedia.org/Cheryl_C._Kagan']::text[]),
-- Benjamin F. Kramer / Affordable Housing — cosp on 2022RS:sb0592
('7a2d1548-3268-4767-97a8-bb8b142d5a33', '669cac97-66a6-4087-b036-936fbe62efb3', 'Kramer co-sponsored SB0592 (2022), preserving a tenant’s right to redeem leased premises after a judgment for failure to pay rent. It was enacted as Chapter 672 of 2022.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0592?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02','https://ballotpedia.org/Benjamin_Kramer']::text[]),
-- Sara Love / Affordable Housing — lead on 2026RS:sb0335
('c5d2cd24-170a-4f87-8fde-84216fe62806', '669cac97-66a6-4087-b036-936fbe62efb3', 'Love was the lead sponsor of SB0335 (2026), barring a landlord from refusing to rent to a tenant because they pay with an income-based housing subsidy. It was enacted as Chapter 773 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0335?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02','https://ballotpedia.org/Sara_Love']::text[]),
-- C. Anthony Muse / Affordable Housing — lead on 2024RS:sb0356
('47823046-7dea-4a4f-a11b-0c5890539891', '669cac97-66a6-4087-b036-936fbe62efb3', 'Muse was the lead sponsor of SB0356 (2024), requiring local jurisdictions to run an expedited development review process for proposed affordable housing developments.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0356?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01','https://ballotpedia.org/C._Anthony_Muse']::text[]),
-- Jim Rosapepe / Affordable Housing — cosp on 2015RS:sb0372
('9c400214-f007-4a8d-92fe-5f5d23b3838e', '669cac97-66a6-4087-b036-936fbe62efb3', 'Rosapepe co-sponsored SB0372 (2015), creating a tax subtraction for First-Time Homebuyer Savings Accounts.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0372?ys=2015RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe','https://ballotpedia.org/Jim_Rosapepe']::text[]),
-- Jeff Waldstreicher / Affordable Housing — lead on 2024RS:sb0199
('da75c207-bb23-477e-b3c0-7c462394b570', '669cac97-66a6-4087-b036-936fbe62efb3', 'Waldstreicher was the lead sponsor of SB0199 (2024), authorizing a condominium regime on land owned by an affordable housing land trust, so trusts can hold land under permanently affordable homes. It was enacted as Chapter 288 of 2024.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0199?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1','https://ballotpedia.org/Jeff_Waldstreicher']::text[]),
-- Alonzo T. Washington / Affordable Housing — cosp on 2023RS:sb0807
('8c8b0896-dfd0-4d3c-8492-e594d93b78ca', '669cac97-66a6-4087-b036-936fbe62efb3', 'Washington co-sponsored SB0807 (2023), deeming a rented dwelling warranted fit for human habitation and giving tenants remedies when a landlord fails to repair serious and dangerous defects.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0807?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02','https://ballotpedia.org/Alonzo_Washington']::text[]),
-- Sara Love / Rent Regulation — lead on 2025RS:sb0609
('c5d2cd24-170a-4f87-8fde-84216fe62806', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 'Love was the lead sponsor of SB0609 (2025), prohibiting a landlord from using algorithmic devices to set the rent charged to residential tenants.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0609?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02','https://ballotpedia.org/Sara_Love']::text[]),
-- Jeff Waldstreicher / Rent Regulation — lead on 2024RS:sb0354
('da75c207-bb23-477e-b3c0-7c462394b570', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 'Waldstreicher was the lead sponsor of SB0354 (2024), establishing a Rent Court Workforce Solutions Pilot Program for tenants facing failure-to-pay-rent proceedings in Montgomery and Prince George’s counties. It was enacted as Chapter 295 of 2024.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0354?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1','https://ballotpedia.org/Jeff_Waldstreicher']::text[]),
-- Cheryl C. Kagan / Misinformation and the Role of Algorithms in Democracy — cosp on 2026RS:sb0141
('e35d5990-55c7-42e2-94bc-27cb1c49b5f1', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 'Kagan co-sponsored SB0141 (2026), empowering the State Administrator of Elections to act on credible reports of election misinformation and disinformation. It was enacted as Chapter 444 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0141?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01','https://ballotpedia.org/Cheryl_C._Kagan']::text[]);

UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources
FROM cc_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;

-- Guard 1: every targeted row holds its intended text and cites an mgaleg bill page.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM cc_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE c.reasoning IS DISTINCT FROM i.reasoning OR c.sources IS DISTINCT FROM i.sources
     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Legislation/Details/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) wrong', bad; END IF;
END $$;

-- Guard 2: exactly 25 rows touched, nothing created or deleted, NO CHAIR MOVED, no orphans.
DO $$
DECLARE n int; ctx_after int; ans_after int; chair_sum_after numeric; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM cc_snapshot;
  SELECT count(*) INTO n FROM cc_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid;
  IF n <> 25 THEN RAISE EXCEPTION 'guard 2 failed: matched % rows, expected 25', n; END IF;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT coalesce(sum(value), 0) INTO chair_sum_after FROM inform.politician_answers;
  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 2 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;
  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 2 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;
  IF chair_sum_after <> snap.chair_sum_before THEN RAISE EXCEPTION 'guard 2 failed: a chair moved (% -> %)', snap.chair_sum_before, chair_sum_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans; END IF;
  RAISE NOTICE 'class-C sourcing ok: % rows, context=% answers=% orphans=%', n, ctx_after, ans_after, orphans;
END $$;

COMMIT;
