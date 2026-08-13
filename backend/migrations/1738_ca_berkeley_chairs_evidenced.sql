-- 1738_ca_berkeley_chairs_evidenced.sql
-- Berkeley City Council rows from the chairs-owed-evidence pass: 3 re-seated, 11 re-sourced,
-- 3 blanked. Every citation verified by reading the ORDINANCE or the ANNOTATED AGENDA, never a title.
--
-- 🔴 CALIFORNIA WAS NEVER A LEGISLATURE PROBLEM. All of these are city officials, and the instrument
-- is the annotated agenda: it names the Author and every Co-Sponsor of each item and records the
-- roll call. 211 meetings (2021-01-19 → 2026-07-28), 3,423 items, built by
-- scripts/berkeley-agenda-corpus.mjs. Coverage is stated per member in
-- .planning/todos/2026-08-13-ca-berkeley-chairs-findings.md, and it decides who is blankable:
-- Tregub/Blackaby complete; Taplin missing ~5 of ~200; **Kesarwani's 2019-2020 are NOT PUBLISHED,
-- so she is NOT BLANKABLE** — she appears here only for positive sourcing.
--
-- ── ONE ORDINANCE CLOSED FOUR IMMIGRATION ROWS ───────────────────────────────────────────────
-- Sanctuary City Ordinance, BMC Ch. 13.114, **Ordinance No. 7,984-N.S.**, second reading adopted
-- 2025-09-30 on "Absent: None. Vote: All Ayes". Reading the TEXT is what separates chair 1 from
-- chair 2, and the title could not have:
--   · 13.114.030(C)(5) forbids "complying with any civil immigration warrant or request to detain,
--     transfer, or notify" — and unlike (C)(4) and (C)(8) it carries NO judicial-warrant carve-out.
--     That is chair 1's "refuse ALL ICE detainers", not chair 2's "comply only with COURT-ORDERED".
--   · 13.114.030(C)(4) forbids disclosing protected personal information to immigration authorities
--     and (C)(3) forbids even COLLECTING immigration status = chair 1's information clause.
--   · The protection is universal, not chair 2's narrower "crime victims and witnesses".
--
-- ── 3 RE-SEATED (2 -> 1) ─────────────────────────────────────────────────────────────────────
--  · Igor Tregub, Brent Blackaby, Terry Taplin / Local Immigration Enforcement.
--    Blackaby is the strongest: he AUTHORED Res. 71,658-N.S. reaffirming sanctuary status
--    (2025-01-21) and co-sponsored the 2025-04-15 referral that produced the ordinance.
--
-- ── 11 RE-SOURCED (chair unchanged; the reasoning now names the instrument) ───────────────────
-- 🔴 Tregub / Rent Regulation previously cited an item that WAS NEVER ADOPTED: the 2025-03-11
--    Item 15 annotated agenda reads "Item removed from the agenda by Councilmember Tregub."
--    A withdrawn referral is not an act. Replaced with Res. 72,378-N.S., which he MOVED,
--    co-sponsored, and was designated to write the ballot argument for.
-- 🔑 What rules out chair 1 there is in the document itself: the adopted measure PRESERVES the
--    Golden Duplex Exemption and ~330 projects "would remain exempt" — coverage extended to MORE
--    units, not to ALL.
-- 🔴 Tregub / Fossil Fuel previously cited Golden State Energy and a buildings gas ban — a UTILITY
--    instrument and a BUILDINGS instrument, on a DRILLING ladder. Replaced with Res. 72,156-N.S.
-- ⚠ Taplin / Rent Regulation carries a genuine tension, kept visible rather than laundered: on
--    2022-07-12 he voted to PRESERVE the golden duplex exemption and against ending it. The 2026
--    measure he voted for preserves that same exemption while extending coverage elsewhere, so the
--    two votes are one consistent position and the later one is operative.
-- ⚠ Taplin / Transportation stays at chair 2 on a correction: he co-sponsored two street-maintenance
--    pavement referrals AND leads the Vision 2050 COMPLETE STREETS programme. Road investment plus
--    bike-lanes-with-repaving is chair 2's pair of clauses; an earlier draft of this pass wrongly
--    proposed re-seating him to chair 1 on the claim that nothing supported road parity.
--
-- ── 3 BLANKED (answer DELETED, politician_context KEPT) ──────────────────────────────────────
--  · Brent Blackaby / Deportation Priorities. All 52 of his items read. TWO independent reasons,
--    not one: (a) chair 2 is "only deport people convicted of serious violent crimes" and the
--    ordinance he backed is CATEGORICAL — no criminal-conviction carve-out anywhere — which
--    contradicts chair 2 rather than supporting it; (b) his cited instrument (the $200k deportation
--    defence fund) is the SAME ACT already carrying his Local Immigration Enforcement row. The
--    ladder asks WHO should be deported; city instruments answer WHETHER THE CITY COOPERATES.
--    Same structural mismatch that blanked all five MD Immigration rows.
--  · Igor Tregub / Public Safety Approach (chair 3, "adding crisis response teams"). His cited
--    Proposition 6 resolution is about FORCED PRISON LABOUR; the only Specialized Care Unit item in
--    his tenure is a City Manager contract to EVALUATE the existing unit (2024-11-19).
--  · Terry Taplin / Public Safety Approach (chair 2, "shift non-violent calls to unarmed mental
--    health co-responders"). His sole mental-health item is a CEREMONIAL PROCLAMATION,
--    Res. 69,853-N.S. "May 2021 as Mental Health Month". On-topic by vocabulary, not by rationale.
--
-- Rollback: data/stance-retirement/2026-08-13-ca-berkeley-1738-rollback.json
BEGIN;

CREATE TEMP TABLE bk_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

CREATE TEMP TABLE bk_intent (pid uuid, tid uuid, chair numeric, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO bk_intent (pid, tid, chair, reasoning, sources) VALUES

-- ─────────── RE-SEATED 2 -> 1: Local Immigration Enforcement ───────────
-- Igor Tregub
('9f9a35a9-0226-45f0-9fd8-ef46163f7245','b9ccee94-ad96-4f10-b655-889d8e5abe92', 1,
 'Tregub voted for Ordinance No. 7,984-N.S., adopted on second reading on September 30, 2025 with no members absent and all ayes, which adds Chapter 13.114 to the Berkeley Municipal Code. Section 13.114.030(C)(5) forbids city agencies and personnel from complying with any civil immigration warrant or request to detain, transfer or notify a federal authority, with no judicial-warrant exception, and Section 13.114.030(C)(3) and (C)(4) forbid collecting immigration status information or disclosing protected personal information to immigration authorities. He also co-sponsored the April 29, 2025 budget referral allocating $200,000 for deportation defence legal and education funds.',
 ARRAY['https://berkeleyca.gov/sites/default/files/documents/2025-09-09%20Item%2025%20Proposed%20Sanctuary%20City%20Ordinance.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-09-30%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-04-29%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Brent Blackaby
('424eb63b-9976-4059-8049-365c09719cc6','b9ccee94-ad96-4f10-b655-889d8e5abe92', 1,
 'Blackaby authored Resolution No. 71,658-N.S. reaffirming Berkeley as a sanctuary city (January 21, 2025), co-sponsored the April 15, 2025 referral to the City Attorney to draft a sanctuary city ordinance, and voted for the resulting Ordinance No. 7,984-N.S., adopted on second reading on September 30, 2025 with no members absent and all ayes. Section 13.114.030(C)(5) of that ordinance forbids complying with any civil immigration warrant or request to detain, transfer or notify a federal authority, with no judicial-warrant exception, and Section 13.114.030(C)(3) and (C)(4) forbid collecting immigration status information or disclosing protected personal information to immigration authorities. He also authored the April 29, 2025 budget referral allocating $200,000 for deportation defence legal and education funds.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-01-21%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/documents/2025-09-09%20Item%2025%20Proposed%20Sanctuary%20City%20Ordinance.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-09-30%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-04-29%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Terry Taplin
('bcdb549a-48bf-400f-9d23-c93e2e71007c','b9ccee94-ad96-4f10-b655-889d8e5abe92', 1,
 'Taplin co-sponsored Resolution No. 71,658-N.S. reaffirming Berkeley as a sanctuary city (January 21, 2025) and the April 15, 2025 referral to the City Attorney to draft a sanctuary city ordinance, and voted for the resulting Ordinance No. 7,984-N.S., adopted on second reading on September 30, 2025 with no members absent and all ayes. Section 13.114.030(C)(5) of that ordinance forbids complying with any civil immigration warrant or request to detain, transfer or notify a federal authority, with no judicial-warrant exception, and Section 13.114.030(C)(3) and (C)(4) forbid collecting immigration status information or disclosing protected personal information to immigration authorities.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-01-21%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/documents/2025-09-09%20Item%2025%20Proposed%20Sanctuary%20City%20Ordinance.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-09-30%20Annotated%20Agenda%20-%20Council.pdf']::text[]),

-- ─────────── RE-SOURCED, chair unchanged ───────────
-- Rashi Kesarwani / Local Immigration Enforcement (chair 1 kept)
('d2013613-769f-4374-809e-a018dbc1e683','b9ccee94-ad96-4f10-b655-889d8e5abe92', 1,
 'Kesarwani voted for Ordinance No. 7,984-N.S., adopted on second reading on September 30, 2025 with no members absent and all ayes, which adds Chapter 13.114 to the Berkeley Municipal Code. Section 13.114.030(C)(5) forbids city agencies and personnel from complying with any civil immigration warrant or request to detain, transfer or notify a federal authority, with no judicial-warrant exception, and Section 13.114.030(C)(3) and (C)(4) forbid collecting immigration status information or disclosing protected personal information to immigration authorities. She also co-sponsored the resolution supporting SB 1257 (Arreguin) on reporting federal immigration enforcement activity (April 21, 2026).',
 ARRAY['https://berkeleyca.gov/sites/default/files/documents/2025-09-09%20Item%2025%20Proposed%20Sanctuary%20City%20Ordinance.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-09-30%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Igor Tregub / Fossil Fuel Policy (chair 2 kept)
('9f9a35a9-0226-45f0-9fd8-ef46163f7245','a22215c3-6693-4bc2-b248-01aebba14570', 2,
 'Tregub was the author of Resolution No. 72,156-N.S., adopted March 10, 2026, opposing the Bureau of Land Management''s proposed oil and gas leasing and development on approximately 1.6 million acres of California public lands and urging the Secretary of the Interior and California''s congressional delegation to withdraw the draft supplemental environmental impact statements and cease all new oil and gas lease sales on California public lands. The resolution addresses new lease sales and asks nothing about existing extraction.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2026-03-10%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Igor Tregub / Rent Regulation (chair 2 kept)
('9f9a35a9-0226-45f0-9fd8-ef46163f7245','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2,
 'Tregub co-sponsored and moved Resolution No. 72,378-N.S., adopted July 7, 2026 on an all-ayes vote, submitting to the voters an ordinance amending the Rent Stabilization Ordinance to make most rent control and registration exemptions inapplicable to units that were not exempt when the current tenancy began, to limit annual rent increases to ten percent, and to allow tenant associations in smaller properties; he was designated to file the ballot argument in its favour. The adopted measure retains the owner-occupied golden duplex exemption, so it extends stabilization coverage to more units rather than to all units. He also voted for Ordinance No. 7,956-N.S. prohibiting algorithmic rent-setting devices (March 11, 2025) and authored the referral to remove the on-site manager exemption loophole (approved February 24, 2026).',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2026-07-07%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/2026-07/2026-07-07%20SUPPLEMENTAL%20Cover%20Sheet%20Item%20A%20Rent%20stabilization%20ordinance.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2026-02-24%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Igor Tregub / Criminalization of Homelessness (chair 3 kept)
('9f9a35a9-0226-45f0-9fd8-ef46163f7245','4938766b-b45a-46e3-93bd-b8b30651271a', 3,
 'Tregub voted for Ordinance No. 7,935-N.S., adopted on second reading September 24, 2024 on a recorded roll call (ayes Kesarwani, Taplin, Bartlett, Tregub, Hahn, Wengraf, Humbert, Arreguin; noes Lunaparra). The accompanying encampment policy affirms that the city will continue to offer interim housing when closing encampments and authorises enforcement, including citation and arrest, only under six enumerated fire, health, nuisance and location exceptions. Conditioning enforcement on a shelter offer distinguishes this from decriminalising public sleeping, and retaining citation and arrest distinguishes it from prohibiting encampments outright.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2024-09-24%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Igor Tregub / Homelessness Response (chair 2 kept)
('9f9a35a9-0226-45f0-9fd8-ef46163f7245','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2,
 'Tregub voted for Ordinance No. 7,935-N.S., adopted on second reading September 24, 2024 on a recorded roll call (ayes Kesarwani, Taplin, Bartlett, Tregub, Hahn, Wengraf, Humbert, Arreguin; noes Lunaparra). The accompanying encampment policy states that it will continue to be the city''s practice to make shelter offers whenever practicable and to invest in more shelter options, and authorises enforcement only where a shelter offer cannot be made and one of six enumerated exceptions applies. That sequencing, services offered before enforcement, is what distinguishes it from enforcing public space rules alongside investment.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2024-09-24%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Igor Tregub / Affordable Housing (chair 3 kept)
('9f9a35a9-0226-45f0-9fd8-ef46163f7245','669cac97-66a6-4087-b036-936fbe62efb3', 3,
 'Tregub was the author of the referral approved March 11, 2025 directing the City Manager to study a transfer tax exemption for 100 percent affordable housing projects owned and operated by non-profit entities or community land trusts, covering rehabilitation, acquisition and conversion of market-rate housing into deed-restricted affordable housing, and donated land. A targeted tax exemption for affordable projects is neither a rent cap, an inclusionary requirement on new development, nor public funding of construction. He also co-sponsored the referral to establish a citywide local density bonus programme for lower-cost ownership homes (April 14, 2026).',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-03-11%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Terry Taplin / Criminalization of Homelessness (chair 3 kept)
('bcdb549a-48bf-400f-9d23-c93e2e71007c','4938766b-b45a-46e3-93bd-b8b30651271a', 3,
 'Taplin voted for Ordinance No. 7,935-N.S., adopted on second reading September 24, 2024 on a recorded roll call (ayes Kesarwani, Taplin, Bartlett, Tregub, Hahn, Wengraf, Humbert, Arreguin; noes Lunaparra). The accompanying encampment policy affirms that the city will continue to offer interim housing when closing encampments and authorises enforcement, including citation and arrest, only under six enumerated fire, health, nuisance and location exceptions. Conditioning enforcement on a shelter offer distinguishes this from decriminalising public sleeping, and retaining citation and arrest distinguishes it from prohibiting encampments outright.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2024-09-24%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Terry Taplin / Homelessness Response (chair 2 kept)
('bcdb549a-48bf-400f-9d23-c93e2e71007c','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2,
 'Taplin voted for Ordinance No. 7,935-N.S., adopted on second reading September 24, 2024 on a recorded roll call (ayes Kesarwani, Taplin, Bartlett, Tregub, Hahn, Wengraf, Humbert, Arreguin; noes Lunaparra), whose encampment policy states that it will continue to be the city''s practice to make shelter offers whenever practicable and to invest in more shelter options, and authorises enforcement only where a shelter offer cannot be made and one of six enumerated exceptions applies. He also authored the letter supporting SB 692 (Arreguin) relating to vehicles and homelessness (May 20, 2025).',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2024-09-24%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Terry Taplin / Rent Regulation (chair 2 kept)
('bcdb549a-48bf-400f-9d23-c93e2e71007c','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2,
 'Taplin voted for Resolution No. 72,378-N.S., adopted July 7, 2026 on an all-ayes vote, submitting to the voters an ordinance amending the Rent Stabilization Ordinance to make most rent control and registration exemptions inapplicable to units that were not exempt when the current tenancy began, to limit annual rent increases to ten percent, and to allow tenant associations in smaller properties. He also voted for Ordinance No. 7,956-N.S. prohibiting algorithmic rent-setting devices (March 11, 2025). His support for extending coverage is bounded: on July 12, 2022 he voted to retain the owner-occupied golden duplex exemption and against the amendment that would have ended it, and the 2026 measure he supported likewise retains that exemption.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2026-07-07%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/2026-07/2026-07-07%20SUPPLEMENTAL%20Cover%20Sheet%20Item%20A%20Rent%20stabilization%20ordinance.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-03-11%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Terry Taplin / Transportation Priorities (chair 2 kept)
('bcdb549a-48bf-400f-9d23-c93e2e71007c','ba59337e-30e2-4aba-a39a-426b3366eb27', 2,
 'Taplin was the author of the Vision 2050 Complete Streets budget referral approved March 14, 2023, referring $400,000 to develop a programme plan for complete streets and climate-resilient infrastructure revenue measures, and co-sponsored the street maintenance funding referrals of May 24, 2022 and June 6, 2023 to improve pavement condition. He also authored the parking minima referral approved June 28, 2022, reducing off-street parking requirements under BMC 23.322 for mixed-use, live/work and manufacturing uses. Investing in road pavement alongside complete-streets requirements, rather than prioritising one over the other, is what distinguishes this from prioritising pedestrian, cycling and transit investment.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2023-03-14%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2022-05-24%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2023-06-06%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2022-06-28%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Rashi Kesarwani / Transportation Priorities (chair 2 kept)
('d2013613-769f-4374-809e-a018dbc1e683','ba59337e-30e2-4aba-a39a-426b3366eb27', 2,
 'Kesarwani was the author of the street maintenance funding referrals approved May 24, 2022 and June 6, 2023 to prevent further deterioration of pavement condition, and of the referral considered July 28, 2026 to schedule Hopkins Street for repaving with one-way Class IV separated bikeways on each side, Class II buffered bike lanes on the remaining segment, traffic calming and a raised intersection. Coupling a repaving project to required separated bikeways and pedestrian treatments, while also funding pavement condition generally, is what distinguishes this from prioritising pedestrian, cycling and transit investment over roads.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2022-05-24%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2023-06-06%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2026-07-28%20Annotated%20Agenda%20-%20Council.pdf']::text[]);

-- The three rows whose seated chair has no instrument behind it. The ANSWER goes; the CONTEXT stays.
CREATE TEMP TABLE bk_blank (pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO bk_blank (pid, tid) VALUES
 ('424eb63b-9976-4059-8049-365c09719cc6','44905f3b-e105-4f6c-afc7-5d223813dbac'), -- Blackaby / Deportation Priorities
 ('9f9a35a9-0226-45f0-9fd8-ef46163f7245','e9ebefcd-c496-45e8-b816-a79f8442ba85'), -- Tregub / Public Safety Approach
 ('bcdb549a-48bf-400f-9d23-c93e2e71007c','e9ebefcd-c496-45e8-b816-a79f8442ba85'); -- Taplin / Public Safety Approach

UPDATE inform.politician_answers a SET value = i.chair
FROM bk_intent i WHERE a.politician_id = i.pid AND a.topic_id = i.tid;

UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources
FROM bk_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;

DELETE FROM inform.politician_answers a
USING bk_blank b WHERE a.politician_id = b.pid AND a.topic_id = b.tid;

-- Guard 1: every re-sourced row sits at its intended chair with its intended text and sources.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM bk_intent i
  LEFT JOIN inform.politician_answers a ON a.politician_id=i.pid AND a.topic_id=i.tid
  LEFT JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE a.value IS DISTINCT FROM i.chair
     OR c.reasoning IS DISTINCT FROM i.reasoning
     OR c.sources IS DISTINCT FROM i.sources;
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) not as intended', bad; END IF;
END $$;

-- Guard 2: the gate's own test. Every re-sourced reasoning names a municipal instrument, and every
-- source set carries a berkeleyca.gov ordinance, agenda or minutes document.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM bk_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE c.reasoning !~* '(ordinance no\.|resolution no\.|referral|recorded roll call)'
     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s
                    WHERE s LIKE '%berkeleyca.gov%'
                      AND (s ILIKE '%agenda%' OR s ILIKE '%ordinance%' OR s ILIKE '%minutes%'));
  IF bad > 0 THEN RAISE EXCEPTION 'guard 2 failed: % row(s) name no instrument or cite no city record', bad; END IF;
END $$;

-- Guard 3: the three blanks are answer-free and their context SURVIVED. A blank that also destroyed
-- the research would be a deletion, not a finding of absence.
DO $$
DECLARE seated int; ctx_missing int;
BEGIN
  SELECT count(*) INTO seated FROM inform.politician_answers a
    JOIN bk_blank b ON b.pid=a.politician_id AND b.tid=a.topic_id;
  IF seated > 0 THEN RAISE EXCEPTION 'guard 3 failed: % blanked row(s) still seated', seated; END IF;
  SELECT count(*) INTO ctx_missing FROM bk_blank b
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                     WHERE c.politician_id=b.pid AND c.topic_id=b.tid);
  IF ctx_missing > 0 THEN RAISE EXCEPTION 'guard 3 failed: % blanked row(s) lost their context', ctx_missing; END IF;
END $$;

-- Guard 4: row-count arithmetic. Answers fall by exactly 3 (the blanks); context never moves.
DO $$
DECLARE ans_after int; ctx_after int; orphans int; s record;
BEGIN
  SELECT * INTO s FROM bk_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before - 3 THEN
    RAISE EXCEPTION 'guard 4 failed: answers % -> %, expected -3', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before THEN
    RAISE EXCEPTION 'guard 4 failed: context moved % -> %', s.ctx_before, ctx_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 4 failed: % orphan answer(s)', orphans; END IF;
END $$;

-- Guard 5: this pass moved EXACTLY three chairs, all of them Local Immigration Enforcement 2 -> 1,
-- and it moved no other chair. Kesarwani was already at chair 1 and must still be.
DO $$
DECLARE moved int; kes numeric;
BEGIN
  SELECT count(*) INTO moved FROM inform.politician_answers a
   WHERE a.topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'
     AND a.politician_id IN ('9f9a35a9-0226-45f0-9fd8-ef46163f7245',
                             '424eb63b-9976-4059-8049-365c09719cc6',
                             'bcdb549a-48bf-400f-9d23-c93e2e71007c')
     AND a.value = 1;
  IF moved <> 3 THEN RAISE EXCEPTION 'guard 5 failed: % of 3 re-seats landed at chair 1', moved; END IF;
  SELECT value INTO kes FROM inform.politician_answers
   WHERE politician_id='d2013613-769f-4374-809e-a018dbc1e683'
     AND topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92';
  IF kes IS DISTINCT FROM 1 THEN RAISE EXCEPTION 'guard 5 failed: Kesarwani left chair 1'; END IF;
  RAISE NOTICE 'Berkeley chairs: 3 re-seated 2->1, 11 re-sourced, 3 blanked';
END $$;

-- Guard 6: Tregub / Transportation Priorities is UNTOUCHED and still owed. His record prioritises
-- pedestrian, cycling and transit and contains no road-investment item, so chair 2 is contradicted;
-- but chair 1's "reduce parking requirements communitywide" has no instrument of his behind it
-- either. Neither chair is evidenced, so this migration must not quietly settle it.
DO $$
DECLARE v numeric;
BEGIN
  SELECT value INTO v FROM inform.politician_answers
   WHERE politician_id='9f9a35a9-0226-45f0-9fd8-ef46163f7245'
     AND topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27';
  IF v IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'guard 6 failed: Tregub/Transportation was changed; it is an open question'; END IF;
END $$;

COMMIT;
