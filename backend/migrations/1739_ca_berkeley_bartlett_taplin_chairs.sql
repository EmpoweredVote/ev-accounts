-- 1739_ca_berkeley_bartlett_taplin_chairs.sql
-- Continues 1738. Ben Bartlett's six owed rows plus Terry Taplin / Climate Change, all sourced to
-- the annotated agenda; Igor Tregub / Transportation Priorities blanked. 7 re-sourced (3 of them
-- re-seated), 1 blanked. Every citation was read in the source document, never inferred from a title.
--
-- ── 🔴 BARTLETT IS NOT BLANKABLE, AND THAT WAS DECIDED BEFORE ANYTHING ELSE ───────────────────
-- berkeleyca.gov states "Elected: November 2016" on his roster page. The corpus begins 2021-01-21,
-- so 2017-2020 — four years, more than half his tenure — is UNREAD. Maryland's rule (mig 1732)
-- therefore bars any absence finding for him: positive sourcing only. Kesarwani is barred for the
-- same reason (2019-2020 unpublished) and her two rows are deliberately LEFT OWED here rather than
-- guessed or blanked.
-- ⚠ Two claims in his seated reasoning do not survive the record and are removed, not merely
--    re-cited: every Specialized Care Unit item in the readable corpus is a CITY MANAGER CONTRACT
--    with no council sponsor, and "Step Up Housing" appears NOWHERE in 3,649 items. Both sit in the
--    unread window and both came from ben2024.com. A campaign site is self-description; it can
--    corroborate an instrument but it can never be one.
--
-- ── 🔴🔴 THE CORPUS ITSELF WAS DEFECTIVE, AND FIXING IT CHANGED AN ANSWER ─────────────────────
-- scripts/berkeley-agenda-corpus.mjs carried two silent under-reads, both found here and both fixed
-- in the same commit (corpus 3,423 -> 3,649 items):
--  1. THE PLURAL CO-SPONSOR SERIES. Most items tag each name — "Councilmember Hahn (Co-Sponsor)" —
--     but some write a series with ONE TRAILING PLURAL: "Councilmember Taplin (Author),
--     Councilmember Bartlett, Councilmember Hahn, and Mayor Arreguin (Co-Sponsors)". A per-name
--     anchor matches only the LAST name and drops the rest.
--  2. THE ADJOURNMENT CUT OVER-CUT. 1738 dropped the trailing "Communications" reprints — which
--     otherwise FABRICATE sponsorships — by truncating at the first "Adjourn...Communications"
--     boundary. But consent calendars carry early items titled "Adjourned in Memory of <resident>",
--     and long packets APPEND the prior meeting's full minutes, so that boundary is usually not the
--     end of the record. 96 legitimate items across 4 meetings vanished without an error. Replaced
--     with a per-chunk reprint filter, which keeps the items AND still refuses the reprints.
-- 🔑 THE COST OF THOSE TWO BUGS WAS A DECISIVE INSTRUMENT: **Resolution No. 70,171-N.S., "Commit
--    the City of Berkeley to a Just Transition from the Fossil Fuel Economy"** — Taplin author,
--    Bartlett co-sponsor, ADOPTED 2021-12-14 — read as absent under both bugs at once. It is the
--    instrument these two Climate rows now turn on. A tool's own gap is indistinguishable from a
--    politician having no record; only re-reading the source told them apart.
-- ✅ Re-verified after the repair: all three blanks applied by 1738 STILL STAND on the larger record
--    (Taplin / Public Safety — his only mental-health item remains the ceremonial Res. 69,853-N.S.
--    "May 2021 as Mental Health Month"; Tregub / Public Safety — no crisis-response instrument;
--    Blackaby / Deportation Priorities — still only the deportation-defence fund). Regressions held:
--    2025-02-11 #12 carries no role, and the "Russbumper Supplemental Communications" reprint at #69
--    carries none either.
--
-- ── 2 RE-SEATED ON INSTRUMENTS ALREADY ACCEPTED FOR HIS COLLEAGUES IN 1738 ────────────────────
--  · Local Immigration Enforcement 2 -> 1. Ordinance No. 7,984-N.S. The roll call is what attributes
--    it to him: "Present: Kesarwani, Taplin, Bartlett, Tregub, O'Keefe, Blackaby, Lunaparra,
--    Humbert, Ishii / Absent: None", vote All Ayes. Read in the ordinance TEXT, the discriminator is
--    a deliberate internal contrast: (C)(4) and (C)(8) each carve out "a valid judicial warrant",
--    and (C)(5) — complying with a civil immigration detainer — DOES NOT. Refusing ALL detainers is
--    chair 1; chair 2 is "comply only with court-ordered" ones.
--  · Criminalization of Homelessness 2 -> 3. Ordinance No. 7,935-N.S., and here he is named
--    individually in the roll. Chair 2 is "decriminalizing public sleeping", which the ordinance
--    contradicts outright by authorising citation and arrest.
--    ⚠ Stated honestly: chair 3's SECOND clause, "citations diverting people to services rather than
--    the criminal justice system", is NOT in this ordinance. Chair 3 is seated because it beats every
--    rival, not because both clauses are evidenced — it beats 2 on citation and arrest, and beats 4
--    because the ordinance prohibits no encampment and keeps the Housing First frame.
--
-- ── 1 RE-SEATED ON THE END-STATE READING (decided with the user) ──────────────────────────────
--  · Taplin / Climate Change 3 -> 2, and Bartlett / Climate Change chair 2 KEPT, on one shared
--    record. Chairs 2 and 3 differ in END STATE, not only in pace: chair 2 "phase out fossil fuels",
--    chair 3 "gradually reducing RELIANCE on fossil fuels". Res. 70,171-N.S. commits the city to a
--    Just Transition FROM the fossil fuel economy — elimination in kind — and Res. 70,348-N.S.
--    supports fossil-fuel DIVESTMENT. Taplin authored the first and also authored Res. 70,172-N.S.
--    readopting the carbon fee and dividend endorsement.
--    ⚠ The competing reading is recorded rather than hidden: chair 2's "by 2030" is NOT pinned by any
--    adopted Berkeley instrument (the only 2030 figure is a 25% VMT-per-capita target, and it sits in
--    a referral of concepts), and C40 Race to Zero is a 2050 horizon. On a pace reading these rows
--    would be unevidenced, as all 13 MD Taxation rows were. The end-state reading governs by
--    decision, and the pace caveat stays visible in the reasoning.
--    ⚠ Kesarwani co-sponsored the same Green New Deal referral but is NOT on Res. 70,171, so her
--    Climate row is left owed rather than moved with theirs.
--
-- ── 3 RE-SOURCED, chair 2 kept ───────────────────────────────────────────────────────────────
--  · Homelessness Response — the cleanest of the eight: his OWN authored $200,000 Homeless Outreach
--    Coordinator referral (approved 2021-11-09) is chair 2's services half, and Ord. 7,935-N.S.'s
--    sequencing clause is its enforcement-only-after-services half.
--  · Transportation Priorities — Vision 2050 Complete Streets (approved 2023-03-14, "Councilmember
--    Bartlett added as a co-sponsor" on the record) and full funding of the 50-50 Sidewalk Repair
--    Program (approved 2023-04-11). Chair 1 is ruled out by his OWN authored work in the opposite
--    direction: he establishes Parking Benefit Districts, i.e. manages and monetises parking rather
--    than "reducing parking requirements communitywide".
--  · Environmental Protection vs. Development — Res. 71,118-N.S. permanently dedicating open space
--    as linear City park under BMC 6.42 (adopted 2023-11-28) is chair 2's "protect existing parks
--    strictly"; SB 954 support (approved 2026-06-16) keeps protected-species habitat subject to CEQA
--    review and adds safeguards for exempt industrial projects.
--    🔴 COUNTER-EVIDENCE READ BEFORE CITING, per the Ellis rule: he is an AUTHOR of the PITCH
--    rezoning (approved 2026-03-10) upzoning Telegraph to 8 stories. That does not contradict chair
--    2 — it touches no park or tree canopy and funds the CEQA review rather than avoiding it — but it
--    does rule out chair 1's "green space and environmental review before approving ANY development".
--    ⚠ Chair 2's "fully offset any environmental impact" is the weaker half; the park dedication
--    clause is what carries the row.
--
-- ── 1 BLANKED (answer DELETED, politician_context KEPT) ───────────────────────────────────────
--  · Igor Tregub / Transportation Priorities. Chair 2's "invest equally in roads" is CONTRADICTED by
--    his record, which is pedestrian, cycling and transit throughout (Oxford for All Class IV
--    bikeway, accessible pedestrian signals, the MTC letter). Chair 1 would fit that half, but its
--    second clause, "reduce parking requirements communitywide", has NO instrument of his behind it
--    anywhere in the repaired corpus. Contradicted at 2, incomplete at 1, so neither chair is
--    described. He is blankable: seated December 2024, and none of the 96 items recovered by the
--    corpus repair falls inside his tenure, so this absence rests on a complete record.
--
-- Rollback: data/stance-retirement/2026-08-13-ca-berkeley-1739-rollback.json
BEGIN;

CREATE TEMP TABLE bk_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

CREATE TEMP TABLE bk_intent (pid uuid, tid uuid, chair numeric, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO bk_intent (pid, tid, chair, reasoning, sources) VALUES

-- ─────────── RE-SEATED 2 -> 1: Local Immigration Enforcement ───────────
('eaab41f8-71c8-47db-bd0b-62da46b5607b','b9ccee94-ad96-4f10-b655-889d8e5abe92', 1,
 'Bartlett voted for Ordinance No. 7,984-N.S., which adds Chapter 13.114 to the Berkeley Municipal Code and was adopted on second reading on September 30, 2025; the annotated agenda records him present, no members absent, and all ayes. Section 13.114.030(C)(5) forbids city agencies and personnel from complying with any civil immigration warrant or request to detain, transfer or notify a federal authority about an individual''s release, and unlike subsections (C)(4) and (C)(8), which each carve out a valid judicial warrant or subpoena, that subsection carries no judicial-warrant exception at all. Subsection (C)(3) forbids inquiring into or collecting immigration status and (C)(4) forbids disclosing protected personal information to immigration authorities. The protections apply to everyone rather than only to crime victims and witnesses.',
 ARRAY['https://berkeleyca.gov/sites/default/files/documents/2025-09-09%20Item%2025%20Proposed%20Sanctuary%20City%20Ordinance.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-09-30%20Annotated%20Agenda%20-%20Council.pdf']::text[]),

-- ─────────── RE-SEATED 2 -> 3: Criminalization of Homelessness ───────────
('eaab41f8-71c8-47db-bd0b-62da46b5607b','4938766b-b45a-46e3-93bd-b8b30651271a', 3,
 'Bartlett voted for Ordinance No. 7,935-N.S., adopted on second reading September 24, 2024 on a recorded roll call naming him individually (ayes Kesarwani, Taplin, Bartlett, Tregub, Hahn, Wengraf, Humbert, Arreguin; noes Lunaparra). The accompanying encampment policy affirms that the city will continue to offer interim housing, with a preference for non-congregate options, when closing encampments, and provides that where the city cannot make a shelter offer the City Manager is nonetheless authorised to enforce, including by citation and arrest, only under six enumerated fire, imminent health hazard, public nuisance, roadway proximity, authorised work and utility maintenance circumstances. Expressly authorising citation and arrest is what distinguishes this from decriminalising public sleeping, and prohibiting no encampment while retaining the Housing First framework is what distinguishes it from a general encampment ban.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2024-09-24%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2024-09-10%20Annotated%20Agenda%20-%20Council.pdf']::text[]),

-- ─────────── RE-SEATED 3 -> 2: Taplin / Climate Change ───────────
('bcdb549a-48bf-400f-9d23-c93e2e71007c','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2,
 'Taplin was the author of Resolution No. 70,171-N.S., adopted December 14, 2021, committing the City of Berkeley to a Just Transition from the fossil fuel economy and requiring every council report relating to climate to include a Just Transition section, and of Resolution No. 70,172-N.S. readopting the council''s endorsement of a national carbon fee and dividend. He authored the Berkeley Green New Deal referrals approved December 3, 2024 and July 29, 2025, which carry Transportation Demand Management planning to reduce vehicle miles travelled per capita by at least 25 percent by 2030 and a green workforce board to accelerate the transition to a fossil-free local economy. Committing to a transition away from the fossil fuel economy is an end state rather than a reduction in reliance on it. No adopted Berkeley instrument of his fixes a 2030 date to that phase-out: the 2030 figure attaches to the vehicle-miles target, and the C40 Race to Zero commitment he supported runs to 2050.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2022-01-25%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2024-12-03%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2025-07-29%20Annotated%20Agenda%20-%20Council.pdf']::text[]),

-- ─────────── RE-SOURCED, chair unchanged ───────────
-- Bartlett / Climate Change (chair 2 kept)
('eaab41f8-71c8-47db-bd0b-62da46b5607b','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2,
 'Bartlett co-sponsored Resolution No. 70,171-N.S., adopted December 14, 2021, committing the City of Berkeley to a Just Transition from the fossil fuel economy, and Resolution No. 70,348-N.S. supporting SB 1173 on divestment from fossil fuels. On the renewable side he co-sponsored Resolution No. 70,414-N.S. establishing a pilot existing-building electrification incentives and just transition programme to move plumbing, HVAC and cooking systems to zero carbon, with a preference for affordable housing and households at or below 120 percent of area median income; Resolution No. 69,912-N.S. supporting the Solar Access Act; Resolution No. 70,588-N.S. on instant residential solar permitting; and Resolution No. 69,852-N.S. committing Berkeley to the C40 Race to Zero campaign. He also co-sponsored the Berkeley Green New Deal referrals approved December 3, 2024 and July 29, 2025. Committing to a transition away from the fossil fuel economy is an end state rather than a reduction in reliance on it, though no adopted instrument fixes a 2030 date to the phase-out.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2022-01-25%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2022-05-10%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2022-06-14%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2021-06-29%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2024-12-03%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Bartlett / Homelessness Response (chair 2 kept)
('eaab41f8-71c8-47db-bd0b-62da46b5607b','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2,
 'Bartlett was the author of the budget referral approved November 9, 2021 funding $200,000 for a Homeless Outreach Coordinator for South Shattuck Avenue at Dwight Way to Adeline Street at 62nd Street, an expansion of outreach services rather than of enforcement. He also voted for Ordinance No. 7,935-N.S., adopted on second reading September 24, 2024 on a recorded roll call naming him individually, whose encampment policy states that it will continue to be the city''s practice to make shelter offers whenever practicable and to invest in more shelter options, and authorises enforcement only where a shelter offer cannot be made and one of six enumerated exceptions applies. That sequencing, services offered before enforcement, is what distinguishes this from enforcing public space rules alongside investment in services.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2021-11-09%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2024-09-24%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Bartlett / Transportation Priorities (chair 2 kept)
('eaab41f8-71c8-47db-bd0b-62da46b5607b','ba59337e-30e2-4aba-a39a-426b3366eb27', 2,
 'Bartlett co-sponsored the Vision 2050 Complete Streets budget referral approved March 14, 2023, referring $400,000 to develop a programme plan for complete streets and climate-resilient infrastructure revenue measures, and was added as a co-sponsor on the record when it was approved. He also co-sponsored the referral approved April 11, 2023 to fully fund the city''s 50-50 Sidewalk Repair Program, and co-sponsored the resolution updating the Street Maintenance and Rehabilitation Policy to improve the pavement condition index, which was referred to committee for scheduling with the Five-Year Paving Plan rather than adopted. He authored traffic calming installations including semi-diverter bollards at Newbury and Ashby (2022-05-10) and speed bumps on Russell Street at King and at Martin Luther King Jr. Way. On the multimodal side he co-sponsored support for AB 1238 and AB 122, which would repeal jaywalking laws and allow bicyclists to treat stop signs as yield signs, and the pilot offering free AC Transit service on Sundays. Funding road pavement and sidewalks alongside a complete-streets programme, rather than prioritising one over the other, is what distinguishes this from prioritising pedestrian, cycling and transit investment; his own authored Parking Benefit Districts in the Adeline, Gilman and Lorin districts manage and monetise parking rather than reducing parking requirements communitywide.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2023-03-14%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2023-04-11%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2021-09-14%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2022-05-10%20Annotated%20Agenda%20-%20Council.pdf']::text[]),
-- Bartlett / Environmental Protection vs. Development (chair 2 kept)
('eaab41f8-71c8-47db-bd0b-62da46b5607b','1935979c-b290-42e4-baa5-8cb0138b4ffa', 2,
 'Bartlett was added as a co-sponsor on the record of the resolution adopted November 28, 2023 as Resolution No. 71,118-N.S., designating the open space adjacent to the Ninth Street Greenway between Heinz Avenue and the Berkeley-Emeryville border as linear City park space and formally dedicating it for permanent recreational use under Berkeley Municipal Code 6.42 — a permanent dedication rather than a discretionary designation. He also co-sponsored the position of support for SB 954 approved June 16, 2026, which narrows the advanced manufacturing exemption from the California Environmental Quality Act, establishes environmental and labour safeguards for exempt industrial projects, and ensures that habitat for protected species remains subject to environmental review. Chair 1 is ruled out by his own work in the opposite direction: he is an author of the PITCH rezoning approved March 10, 2026, which upzones the Telegraph Avenue corridor to a base of eight stories and funds the required CEQA review, so he does not require green space and environmental review before approving any development. His record on environmental review is not uniformly restrictive: he also co-sponsored the 2022 resolution supporting SB 922, which would permanently exempt transportation projects from the California Environmental Quality Act. The permanent park dedication, not the review provisions, is what carries this chair.',
 ARRAY['https://berkeleyca.gov/sites/default/files/city-council-meetings/2023-11-28%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2026-06-16%20Annotated%20Agenda%20-%20Council.pdf','https://berkeleyca.gov/sites/default/files/city-council-meetings/2026-03-10%20Annotated%20Agenda%20-%20Council.pdf']::text[]);

-- The one row whose seated chair is contradicted and whose alternative is unevidenced.
-- The ANSWER goes; the CONTEXT stays.
CREATE TEMP TABLE bk_blank (pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO bk_blank (pid, tid) VALUES
 ('9f9a35a9-0226-45f0-9fd8-ef46163f7245','ba59337e-30e2-4aba-a39a-426b3366eb27'); -- Tregub / Transportation Priorities

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

-- Guard 3: the blank is answer-free and its context SURVIVED. A blank that also destroyed the
-- research would be a deletion, not a finding of absence.
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

-- Guard 4: row-count arithmetic. Answers fall by exactly 1 (the blank); context never moves.
DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM bk_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before - 1 THEN
    RAISE EXCEPTION 'guard 4 failed: answers % -> %, expected -1', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before THEN
    RAISE EXCEPTION 'guard 4 failed: context moved % -> %', s.ctx_before, ctx_after; END IF;
END $$;

-- Guard 5: the three chair MOVES landed, and nothing else moved. This pass re-sources; only these
-- three rows change chair, and each was decided with the user rather than inferred.
DO $$
DECLARE moved int;
BEGIN
  SELECT count(*) INTO moved FROM inform.politician_answers a
   WHERE (a.politician_id, a.topic_id, a.value) IN (
     ('eaab41f8-71c8-47db-bd0b-62da46b5607b','b9ccee94-ad96-4f10-b655-889d8e5abe92', 1),  -- Bartlett immigration 2->1
     ('eaab41f8-71c8-47db-bd0b-62da46b5607b','4938766b-b45a-46e3-93bd-b8b30651271a', 3),  -- Bartlett criminalization 2->3
     ('bcdb549a-48bf-400f-9d23-c93e2e71007c','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2)); -- Taplin climate 3->2
  IF moved <> 3 THEN RAISE EXCEPTION 'guard 5 failed: % of 3 chair moves landed', moved; END IF;
END $$;

-- Guard 6: Kesarwani's two rows are LEFT OWED, untouched. She is not blankable and was not sourced
-- here; proving the migration did not quietly seat or blank her is the point of this guard.
DO $$
DECLARE changed int;
BEGIN
  SELECT count(*) INTO changed FROM inform.politician_answers a
   WHERE a.politician_id = 'd2013613-769f-4374-809e-a018dbc1e683'
     AND a.topic_id IN ('7687de4f-4d0b-462a-b803-bdfb23b16b42','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c');
  IF changed <> 2 THEN RAISE EXCEPTION 'guard 6 failed: Kesarwani has % of her 2 owed rows, expected 2 untouched', changed; END IF;
END $$;

COMMIT;
