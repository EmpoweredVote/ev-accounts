-- CA_0190_season2_reresearch_ca0184_duplicate_conflicts.sql
-- Season 2 re-research of the 8 compass conflicts that CA_0184 left on two deactivated duplicate rows
-- (Nanette Barragán, U.S. House CA-44; Tony Strickland, CA Senate SD-36). Writes the Season 2 answers the evidence
-- supports on the SEATED rows, and a Season 2 blank (value 0) where no rung of the Season 2 ladder states the
-- position. 5 chairs seated, 2 blanks, 1 topic not asked in Season 2.
-- Slot CA_0190 reserved via `steward slot CA` before this file existed. Author: Chris Andrews.
--
-- WHY. CA_0184 (applied 2026-09-23) merged duplicate person rows into their seated twins. Where both rows answered the
-- same (topic, Season 1) with DIFFERENT values it moved nothing, so 8 conflicting Season 1 answers stayed on the
-- deactivated duplicates as a stance-review lead. Operator ruling 2026-09-23 (Chris Andrews): do NOT change Season 1 --
-- it is closed and it is the record. Research the topics again in Season 2 (open) for the seated rows, use the
-- instruments cited on BOTH rows as leads, and blank where the evidence does not describe a chair.
--
-- 🔴 SEASON 1 IS NOT TOUCHED, AND NEITHER IS EITHER DUPLICATE. Both are asserted by fingerprint at the bottom: every
-- Season 1 answer, context and evidence row in the corpus, every row of either duplicate in any season, and every other
-- Season 2 row of the two seated people must hash the same after this file as before it.
--
-- 🔴 A BLANK IS value 0, NOT AN ABSENT ROW. The read path (compassService getPoliticianAnswers and siblings) collapses
-- to the NEWEST PUBLISHED season per topic and filters value 0 AFTER the collapse. With no Season 2 row the Season 1
-- chair still shows -- for Strickland's Clean Energy spoke that would be his Season 1 Climate Change chair 4 rendered
-- against a different ladder. Same reasoning as migration 1888 ("WHY BLANK AND NOT DELETE"). Each blank carries the
-- sources it examined: the source gate joins answers to context without a season predicate, so a Season 1 answer
-- joined to a sourceless Season 2 context would read as EMPTY_SOURCES (zero-tolerance).
--
-- THE LADDERS ARE THE ONES SEASON 2 SERVES (ADR 0006: the latest published revision of the pinned version), not the
-- Season 1 wording the old reasoning was written against:
--   campaign-finance  pin r3 (v2). Chair 3 is now "keep contribution limits at current levels" (was full disclosure).
--   climate-change    pin r3 (v2) "Clean Energy": a NEW ladder -- 1 mandate, 2 fund, 3 enable (permitting, grid),
--                     4 neutral, 5 end subsidies and mandates. Season 1 reasoning about climate priority does not transfer.
--   fossil-fuels      pin r1, serves r3 (v1 clarifying): 1 phase out entirely, 2 no new drilling and let production
--                     decline, 3 steady, 4 expand with new drilling and permits, 5 maximize and open more public land.
--   social-security   pin r2 (v2). Chairs 1-3 keep their Season 1 text; chair 4 was rewritten.
--   tariffs           pin r1, serves r3 (v1 clarifying). Chair 2 is now "reduce most tariffs, keeping only limited
--                     exceptions".
--   housing           pin r3 (v2). CC_0058 carried Season 1 answers across by rung_map {1:1,2:3,3:4,4:5,5:5}.
--   immigration       NOT ASKED in Season 2 (no season_questions row), so politician_answers_pin_fkey forbids a
--                     Season 2 row. Nothing is written; the Season 1 conflict stays for the Season 3 decision on the
--                     topic (the same position migration 1888 records for its immigration siblings).
-- The pre-flight re-reads each seated chair's served text and refuses if it differs from the text researched against.
--
-- THE EVIDENCE (S1 values: seated / duplicate -> Season 2):
--   Barragán  Campaign Finance  1 / 2 -> 2  Cosponsor of H.J.Res. 13 (118th: Congress and states may limit spending and
--                                           may prohibit corporate election spending) and H.J.Res. 54 (119th,
--                                           2026-08-31: governments shall regulate, limit or prohibit contributions);
--                                           original cosponsor, End Dark Money Act (H.R. 142). Not 1: H.J.Res. 54 keeps
--                                           "permissible contributions"; H.J.Res. 13's public financing offsets private
--                                           money. The seated S1 row rested on a voucher plan and ideology scores.
--   Barragán  Fossil Fuels      2 / 1 -> 2  "The state of California must stop issuing new drilling permits"
--                                           (2021-10-21); original cosponsor, Keep It in the Ground Act (H.R. 2519).
--                                           ⚖ JUDGMENT CALL: she also backs the Future Generations Protection Act
--                                           (H.R. 5489: fracking ban from 2029, export ban), which goes beyond chair 2,
--                                           but nothing found reaches chair 1's "entirely" -- her own stated goal is
--                                           ending "all urban oil drilling and production".
--   Barragán  Social Security   2 / 1 -> 2  Original cosponsor of the Social Security 2100 Act in the 115th-118th
--                                           Congresses; H.R. 4583 raises the formula 90% -> 93% (2025-2034) and taxes
--                                           earnings over $400,000. It leaves the cap gap, so not chair 1. Her single
--                                           2017 cosponsorship of the Social Security Expansion Act (H.R. 1114, tax above
--                                           $250,000) also leaves a gap; she is on none of its four later versions.
--   Barragán  Tariffs           3 / 2 -> 3  "Tariffs should be a precision tool, not a sledgehammer" and "smart,
--                                           strategic trade policies" (2025-04-03); Yea on H.J.Res. 72 (2026-02-11,
--                                           ends the EO 14193 Canada-duty emergency); cosponsor, RELIEF Act (H.R. 7615).
--                                           Not 4: she asks for no increase. Not 1/2: she defends targeted tariffs.
--                                           The duplicate's H.R. 5673 is NOT a tariff bill (it reinstates DOE awards).
--   Strickland Climate Change   4 / 5 -> 0  BLANK on the new Clean Energy ladder: Aye on SBX1 2 (2011, 33% renewables
--                                           mandate), Aye on SB 540 (2025, regional grid), against the gas-car ban.
--                                           SB 1035 is a ONE-YEAR suspension that refills the GGRF, not a repeal.
--   Strickland Fossil Fuels     4 / 5 -> 4  Aye on SB 237 (2025-09-13, 28-0: Kern County oil and gas production
--                                           permits without further CEQA review); his 2026-01-27 op-ed calls reliance on
--                                           foreign crude "reckless" and deplores the 75% fall in in-state production.
--                                           The op-ed, not the bipartisan vote, is what separates 4 from 3. Nothing
--                                           asks to open more public land or waters, so not 5.
--   Strickland Immigration      4 / 5 ->  -  Not asked in Season 2 (above). For the record: the duplicate's 5 is party
--                                           inference (Trump delegate, super PAC) and would be refused.
--   Strickland Housing          4 / 5 -> 0  The Season 2 row held 5, carried by CC_0058's rung_map, never researched on
--                                           this ladder. BLANK: No twice on SB 417 ($11.25B affordable-housing bond)
--                                           rules out 1, 2 and 4; No on SB 79 (transit upzoning) and SB 979 ("without
--                                           overriding the voice of local communities") contradict 5's market-only
--                                           premise; The Nation (2024-10-21) reports he backed Prop 33 rent caps as a
--                                           way to stop new development, which is not chair 3's affordability position.
--
-- ⚠ NOT IN THIS FILE: Barragán's Season 2 Housing row (value 3, carried by CC_0058). Its reasoning still says "aligns
-- with new stance 2" and its evidence (YIGBY Act, Returning Home Act, federal funding) does not describe chair 3
-- ("binding rules like rent caps or required affordable units"). It is not one of the 8 conflicts; it is a lead for a
-- separate Season 2 housing pass.
--
-- No migration runner exists; this file records SQL applied by hand. Pure DML.
-- STATUS: APPLIED to prod 2026-09-23 (operator approval: Chris Andrews, "approve as written"). Before the apply: dry run
--   x3 (BEGIN ... ROLLBACK; the second ran the body twice to prove the re-run is a no-op), each with a whole-corpus
--   snapshot control that read identical afterwards, and a positive control (a planted 1-second change to a duplicate's
--   Season 1 row) that the fingerprint gate caught. After: a re-run wrote nothing; the control differs only in Season 2
--   (+6 answers, +6 context); check:stance-sources at baseline (0 / 50 / 179 / 670); audit-chair-evidence --check OK
--   on the 5 seated rows once scoped to Season 2 (the season_id support added to that script in this change).
--
-- ROLLBACK: backend/data/stance-retirement/2026-09-23-ca0190-dup-conflicts-rollback.json lists every pair with its
-- Season 2 pre-image. Delete the 6 inserted Season 2 answer + context rows; set Strickland's Season 2 Housing answer back
-- to 5 and restore its context from the file.
-- IDEMPOTENT: each write is guarded on its pre-image; a re-run writes nothing and every gate still passes.

BEGIN;

-- ─── The rows ──────────────────────────────────────────────────────────────────────────────────────
-- served_text is the Season 2 rung the chair was researched against (NULL for a blank). The pre-flight compares it with
-- what the season serves at apply time.
CREATE TEMP TABLE _ca0190_rows (
  politician_id uuid NOT NULL,
  who           text NOT NULL,
  topic_key     text NOT NULL,
  s1_seated     int  NOT NULL,     -- the conflict this row resolves, as CA_0184 left it
  s1_dup        int  NOT NULL,
  value         int  NOT NULL,
  mode          text NOT NULL CHECK (mode IN ('insert', 'blank-update')),
  served_text   text,
  reasoning     text NOT NULL,
  sources       text[] NOT NULL,
  PRIMARY KEY (politician_id, topic_key)
) ON COMMIT DROP;

INSERT INTO _ca0190_rows VALUES
-- Nanette Diaz Barragán (seated; duplicate 6f5db776-afcb-40c3-87a5-83e9408d3044)
('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', 'Nanette Diaz Barragán', 'campaign-finance', 1, 2, 2, 'insert',
 'Strictly limit corporate and dark-money spending',
 $r$Barragán backs strict limits on corporate and dark-money spending in campaigns. Since 2017 she has cosponsored a constitutional amendment on campaign money in every Congress. H.J.Res. 13 (118th Congress, cosponsored 2023-01-13) would let Congress and the states set reasonable limits on the raising and spending of money to influence elections, and would let them prohibit corporations and other artificial entities from spending money to influence elections. H.J.Res. 54 (119th Congress, cosponsored 2026-08-31) states that corporations have no constitutional rights and requires federal, state and local governments to regulate, limit or prohibit election contributions and expenditures. She was an original cosponsor of the End Dark Money Act (H.R. 142, 118th Congress), which would lift the budget rider that stops the IRS from writing rules on which nonprofits qualify as social-welfare organizations, the tax status used by dark-money groups. None of these instruments bans private money in campaigns: H.J.Res. 54 still provides for "permissible contributions and expenditures", and the public financing in H.J.Res. 13 offsets private money with public funds rather than replacing it.$r$,
 ARRAY[$r$https://www.congress.gov/bill/118th-congress/house-joint-resolution/13/cosponsors$r$,
       $r$https://www.govinfo.gov/content/pkg/BILLS-118hjres13ih/html/BILLS-118hjres13ih.htm$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-joint-resolution/54/cosponsors$r$,
       $r$https://www.govinfo.gov/content/pkg/BILLS-119hjres54ih/html/BILLS-119hjres54ih.htm$r$,
       $r$https://www.congress.gov/bill/118th-congress/house-bill/142/cosponsors$r$]),
('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', 'Nanette Diaz Barragán', 'fossil-fuels', 2, 1, 2, 'insert',
 'Allow no new drilling and let production decline over time.',
 $r$Barragán's stated position is no new drilling. On 2021-10-21 she said: "The state of California must stop issuing new drilling permits," adding that there is "no safe way to drill and produce oil." She was an original cosponsor of the Keep It in the Ground Act (H.R. 2519, 117th Congress), which bars new and non-producing fossil fuel leases on federal lands and waters. She goes further on one production method: she is an original cosponsor of the Future Generations Protection Act (H.R. 5489, 119th Congress, 2025), which bans hydraulic fracturing on all onshore and offshore land from 2029 and bans exports of crude oil and natural gas. No bill or statement found commits her to ending all fossil fuel production; in the same 2021 statement she set the goal as ending "all urban oil drilling and production."$r$,
 ARRAY[$r$https://barragan.house.gov/2021/10/21/barragan-statement-on-governors-proposed-oil-well-setback/$r$,
       $r$https://www.congress.gov/bill/117th-congress/house-bill/2519/cosponsors$r$,
       $r$https://www.govinfo.gov/content/pkg/BILLS-119hr5489ih/html/BILLS-119hr5489ih.htm$r$]),
('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', 'Nanette Diaz Barragán', 'social-security', 2, 1, 2, 'insert',
 'increase Social Security benefits modestly while raising taxes on higher earners to strengthen the program.',
 $r$Barragán has been an original cosponsor of the Social Security 2100 Act in four Congresses: H.R. 1902 (2017), H.R. 860 (2019), H.R. 5723 (2021) and H.R. 4583 (2023). H.R. 4583 raises the benefit formula for all beneficiaries from 90 percent to 93 percent for 2025 through 2034, and it applies the Social Security payroll tax to earnings over $400,000. That is a modest benefit increase paid for by higher earners. The bill does not remove the cap on taxable earnings: wages between the current cap and $400,000 stay untaxed.$r$,
 ARRAY[$r$https://www.congress.gov/bill/118th-congress/house-bill/4583/cosponsors$r$,
       $r$https://www.govinfo.gov/content/pkg/BILLS-118hr4583ih/html/BILLS-118hr4583ih.htm$r$]),
('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', 'Nanette Diaz Barragán', 'tariffs', 3, 2, 3, 'insert',
 'use tariffs selectively to protect key American industries and jobs.',
 $r$Barragán treats tariffs as a tool to use selectively, not across the board. On 2025-04-03 she said: "Tariffs should be a precision tool, not a sledgehammer," called for "targeted policies that hold bad actors accountable," and said that many in Congress "still support smart, strategic trade policies." Her votes and bills oppose broad tariffs without opposing tariffs as such: she voted for H.J.Res. 72 on 2026-02-11, which ends the national emergency declared in Executive Order 14193 (the February 2025 duties on Canada), and she cosponsored the RELIEF Act (H.R. 7615, 119th Congress), which requires refunds of tariffs collected under the International Emergency Economic Powers Act.$r$,
 ARRAY[$r$https://barragan.house.gov/2025/04/03/press-release-rep-barragan-meets-with-mexican-officials-in-mexico-city-amid-trump-tariff-and-trade-chaos/$r$,
       $r$https://clerk.house.gov/Votes/202665$r$,
       $r$https://www.govinfo.gov/content/pkg/BILLS-119hjres72eh/html/BILLS-119hjres72eh.htm$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-bill/7615/cosponsors$r$]),
-- Tony Strickland (seated; duplicate b156be63-59f0-4caa-98d9-44ae7afccf79)
('863ef272-ea35-482b-aee2-447c06bd469d', 'Tony Strickland', 'climate-change', 4, 5, 0, 'insert', NULL,
 $r$Blank in Season 2 — researched on 2026-09-23, and Strickland's record points to different rungs of this ladder, so no one rung states his position. He has voted for a clean-energy mandate: SBX1 2, California's 33 percent renewables portfolio standard (Senate floor, 2011-02-24). He has voted to upgrade the grid: SB 540, which lets California's grid operator join a regional electricity market (Senate floor, 2025-06-04). He opposes other mandates: he called the repeal of California's ban on new gas-powered car sales "a step in the right direction" (2025-06-12), and he voted against SB 127 (2025), a climate budget bill. His own SB 1035 (2026) would suspend the Low Carbon Fuel Standard and fuel suppliers' cap-and-trade compliance for one year and would refill the Greenhouse Gas Reduction Fund from the General Fund; it is a temporary fuel-price measure, not a repeal of clean-energy subsidies or mandates. The Season 1 row answered a different question (what priority climate change should get), and Season 1 keeps it unchanged. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,
 ARRAY[$r$https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=201120121SB2$r$,
       $r$https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB540$r$,
       $r$https://sr36.senate.ca.gov/content/senator-strickland-repealing-californias-extreme-ban-gas-powered-cars-step-right-direction$r$,
       $r$https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB127$r$,
       $r$https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260SB1035$r$]),
('863ef272-ea35-482b-aee2-447c06bd469d', 'Tony Strickland', 'fossil-fuels', 4, 5, 4, 'insert',
 'Expand fossil fuel production with new drilling and permits.',
 $r$Strickland voted for SB 237 (2025), which lets Kern County approve permits for oil and gas production operations under its local ordinance with no further review under the California Environmental Quality Act (Senate concurrence, 2025-09-13, 28-0). That vote had support from senators of both parties, so his own words are what place him. In a 2026-01-27 op-ed he wrote that in-state oil production "has fallen by 75%, while foreign oil imports are up 67%," that "it is reckless to rely so heavily on foreign crude oil to keep our refineries running," and that the state must "strengthen our fuel supply and refining capacity, reduce dependence on foreign sources." He supports more in-state production through new permits. No bill or statement found asks to open more public land or waters to drilling.$r$,
 ARRAY[$r$https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB237$r$,
       $r$https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260SB237$r$,
       $r$https://sr36.senate.ca.gov/content/californias-green-virtue-signaling-red-alert-americas-safety$r$]),
('863ef272-ea35-482b-aee2-447c06bd469d', 'Tony Strickland', 'housing', 4, 5, 0, 'blank-update', NULL,
 $r$Blank in Season 2 — researched on 2026-09-23, and nothing on record reaches any rung of this ladder. Strickland opposes public money for affordable housing: he voted against SB 417, the $11.25 billion Veterans and Affordable Housing Bond Act of 2026 (Senate floor, 2026-01-27 and 2026-06-25). That rules out the rungs that build or subsidize housing. It does not place him on the market rung, because he also opposes the state removing local zoning limits: he voted against SB 79 (2025), which allows denser housing near transit (Senate floor, 2025-06-03 and 2025-09-12), and he introduced SB 979 (2026), saying "California can meet its housing needs without overriding the voice of local communities." The Nation (2024-10-21) reported that as a Huntington Beach council member he supported Proposition 33, the 2024 rent-control measure, and said it would let cities set rent caps that stop new housing development — a binding rule used to limit building, not to make housing affordable. The Season 2 answer this row replaces was carried across from Season 1 when the ladder changed and was never researched against this ladder. Season 1 keeps its row unchanged. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,
 ARRAY[$r$https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB417$r$,
       $r$https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB79$r$,
       $r$https://sr36.senate.ca.gov/content/senator-strickland-calls-fairness-local-housing-requirements-introduces-sb-979$r$,
       $r$https://www.thenation.com/article/politics/rent-control-prop-33-costa-hawkins-california/$r$]);

-- The pin each row writes against: read from season_questions, never hand-typed, so the pin FK holds by construction.
CREATE TEMP TABLE _ca0190_target ON COMMIT DROP AS
SELECT r.*, sq.season_id, sq.topic_id, sq.topic_revision_id
  FROM _ca0190_rows r
  JOIN inform.compass_topics_promoted pr ON pr.topic_key = r.topic_key
  JOIN inform.season_questions sq ON sq.topic_id = pr.id
  JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open';

-- Fingerprints of everything this file must NOT change. Hard-coded ids (no temp-table references) so the view can be
-- dropped cleanly before COMMIT.
CREATE OR REPLACE TEMP VIEW _ca0190_fp_now AS
WITH a AS (SELECT * FROM inform.politician_answers), c AS (SELECT * FROM inform.politician_context),
     e AS (SELECT * FROM inform.politician_context_evidence),
     mine(pid, tid) AS (VALUES
       ('5bd54ac0-c8b9-486c-844c-ecc4313e5de7'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),  -- campaign-finance
       ('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', 'a22215c3-6693-4bc2-b248-01aebba14570'),              -- fossil-fuels
       ('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', '87d20824-a6e9-407b-983c-65440084a0ab'),              -- social-security
       ('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', '683c8084-2281-4920-a07c-18439b2dd413'),              -- tariffs
       ('863ef272-ea35-482b-aee2-447c06bd469d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),              -- climate-change
       ('863ef272-ea35-482b-aee2-447c06bd469d', 'a22215c3-6693-4bc2-b248-01aebba14570'),              -- fossil-fuels
       ('863ef272-ea35-482b-aee2-447c06bd469d', '669cac97-66a6-4087-b036-936fbe62efb3'))              -- housing
SELECT 'season1 answers' AS k, count(*) AS n, md5(coalesce(string_agg(concat_ws('|', politician_id, topic_id, value, write_in_text, topic_revision_id, editor_id, updated_at), E'\n' ORDER BY politician_id, topic_id), '')) AS h
  FROM a WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
UNION ALL
SELECT 'season1 context', count(*), md5(coalesce(string_agg(concat_ws('|', politician_id, topic_id, reasoning, sources::text, topic_revision_id, editor_id, updated_at), E'\n' ORDER BY politician_id, topic_id), ''))
  FROM c WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
UNION ALL
SELECT 'season1 evidence', count(*), md5(coalesce(string_agg(concat_ws('|', id, politician_id, topic_id, source_url, snippet, snippet_index, verified_at, batch_id), E'\n' ORDER BY id), ''))
  FROM e WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
UNION ALL
SELECT 'duplicates answers', count(*), md5(coalesce(string_agg(concat_ws('|', politician_id, topic_id, season_id, value, write_in_text, topic_revision_id, updated_at), E'\n' ORDER BY politician_id, topic_id, season_id), ''))
  FROM a WHERE politician_id IN ('6f5db776-afcb-40c3-87a5-83e9408d3044', 'b156be63-59f0-4caa-98d9-44ae7afccf79')
UNION ALL
SELECT 'duplicates context', count(*), md5(coalesce(string_agg(concat_ws('|', politician_id, topic_id, season_id, reasoning, sources::text, topic_revision_id, updated_at), E'\n' ORDER BY politician_id, topic_id, season_id), ''))
  FROM c WHERE politician_id IN ('6f5db776-afcb-40c3-87a5-83e9408d3044', 'b156be63-59f0-4caa-98d9-44ae7afccf79')
UNION ALL
SELECT 'duplicates evidence', count(*), md5(coalesce(string_agg(concat_ws('|', id, source_url, snippet), E'\n' ORDER BY id), ''))
  FROM e WHERE politician_id IN ('6f5db776-afcb-40c3-87a5-83e9408d3044', 'b156be63-59f0-4caa-98d9-44ae7afccf79')
UNION ALL
SELECT 'seated rows, other pairs', count(*), md5(coalesce(string_agg(concat_ws('|', a.politician_id, a.topic_id, a.season_id, a.value, a.topic_revision_id, a.updated_at, c.reasoning, c.sources::text, c.updated_at), E'\n' ORDER BY a.politician_id, a.topic_id, a.season_id), ''))
  FROM a LEFT JOIN c USING (politician_id, topic_id, season_id)
 WHERE a.politician_id IN ('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', '863ef272-ea35-482b-aee2-447c06bd469d')
   AND NOT (a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND (a.politician_id, a.topic_id) IN (SELECT pid, tid FROM mine));

CREATE TEMP TABLE _ca0190_fp_before ON COMMIT DROP AS SELECT * FROM _ca0190_fp_now;
CREATE TEMP TABLE _ca0190_state (run text NOT NULL, s2_answers int NOT NULL, s2_context int NOT NULL) ON COMMIT DROP;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int; v_fresh int; v_done int; rec record; v_served text;
BEGIN
  IF (SELECT status FROM inform.seasons WHERE id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3') IS DISTINCT FROM 'closed'
  OR (SELECT status FROM inform.seasons WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194') IS DISTINCT FROM 'open' THEN
    RAISE EXCEPTION 'CA_0190: expected Season 1 closed and Season 2 open';
  END IF;

  IF (SELECT count(*) FROM _ca0190_rows) <> 7 OR (SELECT count(*) FROM _ca0190_target) <> 7 THEN
    RAISE EXCEPTION 'CA_0190: expected 7 rows each resolving to one open-season question, got % / %',
      (SELECT count(*) FROM _ca0190_rows), (SELECT count(*) FROM _ca0190_target);
  END IF;
  IF (SELECT count(*) FROM _ca0190_target WHERE season_id <> '86d893a1-c1a2-4bbf-b4e5-69ec43221194') > 0 THEN
    RAISE EXCEPTION 'CA_0190: a row resolved to a season other than Season 2';
  END IF;

  -- Immigration is the 8th conflict and is NOT asked in Season 2, which is why there are 7 rows.
  IF EXISTS (SELECT 1 FROM inform.season_questions
              WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390') THEN
    RAISE EXCEPTION 'CA_0190: Immigration is now a Season 2 question -- its conflict needs a row; re-research it first';
  END IF;

  -- The people: the seated rows hold a seat and are active; the duplicates are inactive and hold none.
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id IN ('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', '863ef272-ea35-482b-aee2-447c06bd469d')
     AND p.is_active AND EXISTS (SELECT 1 FROM essentials.office_current_holder h WHERE h.politician_id = p.id);
  IF v_n <> 2 THEN RAISE EXCEPTION 'CA_0190: expected both seated rows active and holding a seat, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id IN ('6f5db776-afcb-40c3-87a5-83e9408d3044', 'b156be63-59f0-4caa-98d9-44ae7afccf79')
     AND NOT p.is_active AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder h WHERE h.politician_id = p.id);
  IF v_n <> 2 THEN RAISE EXCEPTION 'CA_0190: expected both duplicates inactive and seatless, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM _ca0190_rows r JOIN essentials.politicians p ON p.id = r.politician_id WHERE p.full_name <> r.who;
  IF v_n > 0 THEN RAISE EXCEPTION 'CA_0190: % row(s) name a different person than their politician_id', v_n; END IF;

  -- The tier: every topic must admit the seat's tier (Barragán federal, Strickland state).
  SELECT count(*) INTO v_n FROM _ca0190_target t
   WHERE NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles cr WHERE cr.topic_id = t.topic_id
                        AND cr.role_scope::text = CASE t.politician_id WHEN '5bd54ac0-c8b9-486c-844c-ecc4313e5de7' THEN 'federal' ELSE 'state' END);
  IF v_n > 0 THEN RAISE EXCEPTION 'CA_0190: % topic(s) do not admit the politician''s tier', v_n; END IF;

  -- The conflict each row resolves is still the one CA_0184 left (Season 1, seated vs duplicate, all 8 pairs).
  SELECT count(*) INTO v_n FROM (VALUES
      ('5bd54ac0-c8b9-486c-844c-ecc4313e5de7'::uuid, '6f5db776-afcb-40c3-87a5-83e9408d3044'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 1, 2),
      ('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', '6f5db776-afcb-40c3-87a5-83e9408d3044', 'a22215c3-6693-4bc2-b248-01aebba14570', 2, 1),
      ('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', '6f5db776-afcb-40c3-87a5-83e9408d3044', '87d20824-a6e9-407b-983c-65440084a0ab', 2, 1),
      ('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', '6f5db776-afcb-40c3-87a5-83e9408d3044', '683c8084-2281-4920-a07c-18439b2dd413', 3, 2),
      ('863ef272-ea35-482b-aee2-447c06bd469d', 'b156be63-59f0-4caa-98d9-44ae7afccf79', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 4, 5),
      ('863ef272-ea35-482b-aee2-447c06bd469d', 'b156be63-59f0-4caa-98d9-44ae7afccf79', 'a22215c3-6693-4bc2-b248-01aebba14570', 4, 5),
      ('863ef272-ea35-482b-aee2-447c06bd469d', 'b156be63-59f0-4caa-98d9-44ae7afccf79', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 4, 5),
      ('863ef272-ea35-482b-aee2-447c06bd469d', 'b156be63-59f0-4caa-98d9-44ae7afccf79', '669cac97-66a6-4087-b036-936fbe62efb3', 4, 5)
    ) x(keep, dup, tid, v_keep, v_dup)
   JOIN inform.politician_answers k ON k.politician_id = x.keep AND k.topic_id = x.tid AND k.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND k.value = x.v_keep
   JOIN inform.politician_answers d ON d.politician_id = x.dup  AND d.topic_id = x.tid AND d.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND d.value = x.v_dup;
  IF v_n <> 8 THEN RAISE EXCEPTION 'CA_0190: expected the 8 CA_0184 Season 1 conflicts unchanged, found %', v_n; END IF;

  -- The ladder: each seated chair's served text (latest published revision of the pinned version) is the text the
  -- evidence was read against. A ladder edit after this file was written must stop it.
  FOR rec IN SELECT * FROM _ca0190_target WHERE value <> 0 LOOP
    SELECT sr.text INTO v_served
      FROM inform.compass_topic_revisions pin
      JOIN LATERAL (SELECT e.id FROM inform.compass_topic_revisions e
                     WHERE e.topic_id = pin.topic_id AND e.version = pin.version AND e.status IN ('published', 'superseded')
                     ORDER BY e.revision DESC LIMIT 1) eff ON true
      JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = eff.id AND sr.value = rec.value
     WHERE pin.id = rec.topic_revision_id;
    IF v_served IS DISTINCT FROM rec.served_text THEN
      RAISE EXCEPTION 'CA_0190: % / % chair % now serves "%", researched against "%"', rec.who, rec.topic_key, rec.value, v_served, rec.served_text;
    END IF;
  END LOOP;

  -- No evidence rows hang off the Season 2 context this file writes or rewrites.
  SELECT count(*) INTO v_n FROM _ca0190_target t JOIN inform.politician_context_evidence e
      ON e.politician_id = t.politician_id AND e.topic_id = t.topic_id AND e.season_id = t.season_id;
  IF v_n > 0 THEN RAISE EXCEPTION 'CA_0190: % evidence row(s) on the target Season 2 context -- not expected', v_n; END IF;

  -- State of each target: 'fresh' (this file has not run) or 'done' (it has). Anything else is a state this file did
  -- not create and must not overwrite.
  SELECT count(*) FILTER (WHERE st = 'fresh'), count(*) FILTER (WHERE st = 'done') INTO v_fresh, v_done
    FROM (
      SELECT CASE
        WHEN t.mode = 'insert' AND a.politician_id IS NULL AND c.politician_id IS NULL THEN 'fresh'
        WHEN t.mode = 'blank-update' AND a.value = 5 AND c.reasoning <> t.reasoning
             AND c.reasoning LIKE 'Strickland voted NO on SB-79 (June 3 and September 12, 2025)%' THEN 'fresh'
        WHEN a.value = t.value AND a.topic_revision_id = t.topic_revision_id
             AND c.reasoning = t.reasoning AND c.sources = t.sources THEN 'done'
        ELSE 'other' END AS st
        FROM _ca0190_target t
        LEFT JOIN inform.politician_answers a ON a.politician_id = t.politician_id AND a.topic_id = t.topic_id AND a.season_id = t.season_id
        LEFT JOIN inform.politician_context c ON c.politician_id = t.politician_id AND c.topic_id = t.topic_id AND c.season_id = t.season_id
    ) s;
  IF NOT (v_fresh = 7 OR v_done = 7) THEN
    RAISE EXCEPTION 'CA_0190: targets are neither all fresh nor all done (fresh %, done %) -- someone else has written here', v_fresh, v_done;
  END IF;

  INSERT INTO _ca0190_state
  SELECT CASE WHEN v_fresh = 7 THEN 'fresh' ELSE 'rerun' END,
         (SELECT count(*) FROM inform.politician_answers WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'),
         (SELECT count(*) FROM inform.politician_context WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194');

  RAISE NOTICE 'CA_0190 pre-flight OK (%): seasons, people, tiers, 8 conflicts, served ladders. Season 2 holds % answers / % context.',
    (SELECT run FROM _ca0190_state), (SELECT s2_answers FROM _ca0190_state), (SELECT s2_context FROM _ca0190_state);
END $$;

-- ─── Writes ─────────────────────────────────────────────────────────────────────────────────────
-- 1. Six new Season 2 answers: four Barragán chairs, Strickland's fossil-fuels chair, Strickland's Clean Energy blank.
INSERT INTO inform.politician_answers (politician_id, topic_id, value, season_id, topic_revision_id, editor_id)
SELECT t.politician_id, t.topic_id, t.value, t.season_id, t.topic_revision_id, NULL
  FROM _ca0190_target t
 WHERE t.mode = 'insert'
   AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                    WHERE a.politician_id = t.politician_id AND a.topic_id = t.topic_id AND a.season_id = t.season_id);

INSERT INTO inform.politician_context (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources, editor_id, updated_at)
SELECT t.politician_id, t.topic_id, t.season_id, t.topic_revision_id, t.reasoning, t.sources, NULL, now()
  FROM _ca0190_target t
 WHERE t.mode = 'insert'
   AND NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id = t.politician_id AND c.topic_id = t.topic_id AND c.season_id = t.season_id);

-- 2. Strickland's Season 2 Housing: the CC_0058 carry (5) becomes a blank (0). An UPDATE, not a DELETE: a deleted
--    Season 2 row would let his Season 1 chair show again. Guarded on the pre-image.
UPDATE inform.politician_answers a
   SET value = 0, write_in_text = NULL, updated_at = now()
  FROM _ca0190_target t
 WHERE t.mode = 'blank-update'
   AND a.politician_id = t.politician_id AND a.topic_id = t.topic_id AND a.season_id = t.season_id
   AND a.value = 5;

UPDATE inform.politician_context c
   SET reasoning = t.reasoning, sources = t.sources, updated_at = now()
  FROM _ca0190_target t
 WHERE t.mode = 'blank-update'
   AND c.politician_id = t.politician_id AND c.topic_id = t.topic_id AND c.season_id = t.season_id
   AND c.reasoning LIKE 'Strickland voted NO on SB-79 (June 3 and September 12, 2025)%';

-- ─── Post-verify ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int; v_run text; v_a0 int; v_c0 int; v_a int; v_c int; v_exp int;
BEGIN
  SELECT run, s2_answers, s2_context INTO v_run, v_a0, v_c0 FROM _ca0190_state;

  -- Every target holds exactly what this file says, against the Season 2 pin.
  SELECT count(*) INTO v_n
    FROM _ca0190_target t
    JOIN inform.politician_answers a ON a.politician_id = t.politician_id AND a.topic_id = t.topic_id AND a.season_id = t.season_id
    JOIN inform.politician_context c ON c.politician_id = t.politician_id AND c.topic_id = t.topic_id AND c.season_id = t.season_id
   WHERE a.value = t.value AND a.write_in_text IS NULL
     AND a.topic_revision_id = t.topic_revision_id AND c.topic_revision_id = t.topic_revision_id
     AND c.reasoning = t.reasoning AND c.sources = t.sources AND cardinality(c.sources) > 0;
  IF v_n <> 7 THEN RAISE EXCEPTION 'CA_0190: expected 7 target pairs exactly as written, found %', v_n; END IF;

  -- Deltas: 6 inserts on a fresh run, nothing on a re-run. The Housing update changes no count.
  v_exp := CASE v_run WHEN 'fresh' THEN 6 ELSE 0 END;
  SELECT count(*) INTO v_a FROM inform.politician_answers WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  SELECT count(*) INTO v_c FROM inform.politician_context WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF v_a - v_a0 <> v_exp OR v_c - v_c0 <> v_exp THEN
    RAISE EXCEPTION 'CA_0190: Season 2 delta answers % / context %, expected % each (%)', v_a - v_a0, v_c - v_c0, v_exp, v_run;
  END IF;

  -- Season 1, the duplicates, and every other row of the two seated people: unchanged, by fingerprint.
  SELECT count(*) INTO v_n
    FROM _ca0190_fp_before b JOIN _ca0190_fp_now n USING (k)
   WHERE b.n <> n.n OR b.h <> n.h;
  IF v_n > 0 OR (SELECT count(*) FROM _ca0190_fp_now) <> 7 THEN
    RAISE EXCEPTION 'CA_0190: % protected fingerprint(s) changed (Season 1 / duplicates / other seated rows)', v_n;
  END IF;

  -- The CC_0058 §3f pair invariant, season-wide: every non-blank Season 2 answer has its context row.
  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.value <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id AND c.season_id = a.season_id);
  IF v_n > 0 THEN RAISE EXCEPTION 'CA_0190: % non-blank Season 2 answer(s) have no context row', v_n; END IF;

  -- The seated compasses now read the Season 2 value: the newest-season collapse the read path uses.
  SELECT count(*) INTO v_n
    FROM _ca0190_target t
    JOIN LATERAL (SELECT a.value FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id AND s.status <> 'draft'
                   WHERE a.politician_id = t.politician_id AND a.topic_id = t.topic_id
                   ORDER BY s.number DESC LIMIT 1) latest ON true
   WHERE latest.value = t.value;
  IF v_n <> 7 THEN RAISE EXCEPTION 'CA_0190: the newest published season does not serve all 7 values (got %)', v_n; END IF;

  RAISE NOTICE 'CA_0190 OK (%): 5 chairs seated (Barragán CF 2, FF 2, SS 2, Tariffs 3; Strickland FF 4), 2 blanks (Strickland Clean Energy, Housing). Season 2 now % answers / % context. Season 1, duplicates and other seated rows unchanged.',
    v_run, v_a, v_c;
END $$;

DROP VIEW _ca0190_fp_now;

COMMIT;
