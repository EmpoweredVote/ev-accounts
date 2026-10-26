-- Migration 1923 — cite the instrument in the six rows the chair-evidence gate could not see,
-- and blank the two of them that turn out to have no instrument to cite.
--
-- WHAT THIS IS. Migration 1922 closed the three rows migration 1921 seated on inadmissible
-- evidence, and recorded that SIX more failed the chair-evidence gate for a different reason: each
-- appeared to name a real act or vote in a form the lexical pattern cannot match. 1922's own note
-- said the remedy was "an identifier, not a blank", and 🔴 THAT NOTE WAS RIGHT FOR FOUR OF THE SIX
-- AND WRONG FOR TWO. Reading the source to find the identifier is what established which.
--
-- ⚖⚖ THE LESSON, AND IT IS THE POINT OF THIS MIGRATION. "The gate is lexically blind here" is a
-- claim about the PATTERN. "The row names a real instrument" is a claim about the WORLD, and only
-- the source can settle it. 1922 asserted the second from the first, for all six at once, without
-- opening a single page. Two of the six name no instrument at all once you look: one rests on a
-- union's internal staffing decision, and the other asserts a vote that the roll call shows went
-- THE OTHER WAY. ▶ A GATE'S FALSE NEGATIVE IS NOT A LICENCE TO ASSUME THE ROW IS SOUND.
--
-- Every page here was FETCHED and read at the PRIMARY source wherever one exists — the Virginia
-- Legislative Information System's own roll calls, the Los Angeles City Clerk's own council file.
-- No call rests on a search summary.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 R36  DEEDS / SAME-SEX-MARRIAGE  — BLANKED. THE ROW ASSERTS A VOTE THAT WENT THE OTHER WAY.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Migration 1921 re-seated him 3 -> 2 on "his recorded 2006 vote AGAINST the Virginia
-- constitutional amendment banning same-sex marriage". The Senate roll call says the opposite.
-- Read at lis.virginia.gov, all three of his recorded votes on that amendment are FOR it:
--   · HJ 586 (2005, first reference), 02/18/05, AGREE TO (27-Y 10-N) — "YEAS--... Deeds ...--27."
--   · HJ 586 conference committee report, 02/26/05 (30-Y 10-N) — Deeds again in the YEAS.
--   · HJ 41 (2006, second resolution), 02/17/06, Agreed to by Senate (29-Y 11-N) —
--     "YEAS--Bell, Blevins, Chichester, Colgan, Cuccinelli, DEEDS, Devolites Davis, ...--29."
--     HJ 41 became Chapter 944 and put the ban before the voters in November 2006.
-- ⚠ WHERE THE WRONG CLAIM CAME FROM, because the shape matters more than the row: the cited
-- Wikipedia sentence says he "was part of the unanimous Democratic coalition that voted to oppose"
-- the amendment, and its two references are a June 2006 PARTY position and an October 2006
-- announcement that he would vote NO on BALLOT QUESTION #1 — the referendum, as a voter. Neither
-- is a legislative vote. A reader who does not open the roll call cannot tell those apart.
-- 🔴 This is the most serious defect class in the corpus: a voter-facing row asserting a named
-- living person cast a vote he did not cast. It cannot be repaired into rung 2, and it is not the
-- audit's business to re-seat him at rung 5 on a twenty-year-old vote he has since moved away
-- from (he announced against the referendum in 2006, said in 2009 that "marriage is between a man
-- and a woman", and has since supported LGBTQ workplace protections). A blank is correct, and the
-- row routes to re-research.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 R24  SOTO-MARTINEZ / JAIL-CAPACITY — BLANKED. A UNION'S STAFFING DECISION IS NOT A RECORD.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 1921 re-seated him 2 -> 1 on "supporting Measure J". The cited page says something narrower and
-- different: "In 2020, he was DESIGNATED BY HIS UNION to be the labor liaison on Measure J." He
-- held no office in 2020 — he was elected to the Council in November 2022 — so this is neither his
-- vote nor his bill nor his motion. `compass_topic_roles` marks jail-capacity at LOCAL level
-- evidence_basis 'record'. Being assigned to a campaign by one's employer is the same shape as the
-- Marcus Simon row THIS QUEUE ALREADY BLANKED (1921, ledger R30: appointment to a redistricting
-- commission "is an office duty, not a position").
-- ⚠ 1921 justified the re-seat by noting "Hernandez sits at rung 1 on the same measure" — but the
-- same page records Hernandez as a CO-CHAIR of the Measure J campaign, which is an act of her own.
-- Two people connected to one ballot measure in different capacities are not the same evidence.
-- 🔑 OPEN QUESTION RECORDED, NOT ACTED ON: jails in California are a COUNTY function, and
-- `role_scope` 'local' covers city and county alike. A city councilmember has no lever on county
-- jail capacity at all, which is the 2026-10-06 test for marking a (topic, level) 'own-words'.
-- `compass_topic_roles` is NOT touched here; that is a ruling.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE FOUR REPAIRS. ⚠ A REPAIR MUST NOT MOVE A CHAIR, AND NONE OF THESE DOES.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- R25 Soto-Martinez / public-safety-approach, chair stays 1. LOS ANGELES COUNCIL FILE 23-0862,
--     "2023-27 Memorandum of Understanding / Police Officers, Lieutenant and Below Representation
--     Unit (MOU 24) / Los Angeles Police Protective League (LAPPL)". Council vote 08/23/2023,
--     12-3-0: "EUNISSES HERNANDEZ 1 NO ... NITHYA RAMAN 4 NO ... HUGO SOTO-MARTINEZ 13 NO".
--     ⚠ The same file carries a SECOND vote, 08/19/2025 (12-0-3), in which he voted YES on a later
--     action; the date is therefore part of the citation, not decoration.
-- R28 Tran / abortion, chair stays 1. VIRGINIA HB 2491 (2019), "Abortion; eliminate certain
--     requirements", LIS: "Introduced by: Kathy K.L. Tran". The summary is the rung-1 evidence in
--     the Commonwealth's own words: it "eliminates the requirement that two other physicians
--     certify that a third trimester abortion is necessary", removes the "substantial and
--     irremediable" threshold, and eliminates the second-trimester hospital requirement.
--     ⚠ HONEST ABOUT OUTCOME: it did not pass — "Left in Courts of Justice" 02/05/19. Sponsorship
--     evidences the bill AS FILED, which is what a position is.
-- R39 VanValkenburg / housing, chair stays 5. Both instruments now named, both chief-patroned by
--     him in the 2026 session: VIRGINIA SB 346, "Zoning; manufactured housing", which passed the
--     Senate 38-2 and the House 92-6 and was APPROVED BY THE GOVERNOR as Chapter 20, effective
--     07/01/2026; and VIRGINIA SB 454, "Zoning; by-right multifamily residential development",
--     which passed the Senate and FAILED in the House ("Left in Counties, Cities and Towns",
--     03/10/2026). ⚠ 1921 described both without numbering either and did not say the second one
--     died; the status is now in the row.
-- R05 Chen / growth-and-development, chair stays 1. Her recorded NO on the Family Zoning Plan
--     rezoning at the San Francisco Board of Supervisors, 02 December 2025 — the SF Standard's
--     report names all four opponents: "Progressive Supervisors Connie Chan, Shamann Walton,
--     Jackie Fielder, and Chyanne Chen ... All four voted against the measure", and records that
--     she and Chan "unsuccessfully pushed for amendments that would have exempted coastal areas,
--     all residential neighborhoods, and low-income communities from the plan."
--     ⚠ THE BOARD FILE NUMBER IS NOT CITED, AND THE REASON IS RECORDED RATHER THAN HIDDEN: San
--     Francisco's public Legistar API (webapi.legistar.com/v1/sfgov) is STALE — its newest
--     MatterIntroDate is 2005 and its newest "Rezoning" matter is 2018, so every date-filtered
--     query returns an empty array that looks exactly like "no such record". A positive control on
--     the same endpoint returned rows, which is how the staleness was found rather than believed.
--     Searching the Legistar web UI for "Family Zoning" returns the unrelated ordinance that
--     redefines "Family" as "Household" (File 250719) — a near-miss that would have been cited as
--     the rezoning by anyone matching on the name alone.
--
-- 🔑 WHY SEASON 2, and why the blanks are 0 rather than deletions: a blank writes 0, which
-- SUPPRESSES (NULLIF(pa.value, 0)). The row and its citations stay, so coverage still counts the
-- research as having happened. Season 1 is closed and is not touched.
--
-- Applied by hand via psql; no migration runner exists in this repo, so "applied" means its data
-- effects are live. Guards below fail the whole transaction rather than write a partial result.

CREATE TEMP TABLE mig1923_decisions (
  politician_id uuid NOT NULL,
  topic_id      uuid NOT NULL,
  value_before  int  NOT NULL,
  new_value     int  NOT NULL,
  add_source    text,
  reasoning     text NOT NULL,
  ledger_no     text NOT NULL
) ON COMMIT DROP;

INSERT INTO mig1923_decisions
  (politician_id, topic_id, value_before, new_value, add_source, reasoning, ledger_no)
VALUES
-- R36  R. Creigh Deeds / same-sex-marriage  2 -> BLANK  (the asserted vote went the other way)
('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,2,0,
 'https://lis.virginia.gov/cgi-bin/legp604.exe?061+vot+SV1450HJ0041+HJ0041',
 'INTERNAL RECORD - blanked: the row asserted a vote that the roll call shows went the other way. Shape: EVIDENCE POINTS AWAY - the cited record is real, and it is on the opposite side of this ladder from the seat. WHY: migration 1921 re-seated this row 3 -> 2 on "his recorded 2006 vote against the Virginia constitutional amendment banning same-sex marriage". FETCHED at the Virginia Legislative Information System, every recorded vote he cast on that amendment was FOR it: HJ 586 (2005, first reference) agreed to 02/18/2005 by 27-Y 10-N with Deeds in the YEAS; the HJ 586 conference committee report 02/26/2005, 30-Y 10-N, Deeds again in the YEAS; and HJ 41 (2006, the second resolution) agreed to by the Senate 02/17/2006 by 29-Y 11-N, "YEAS--Bell, Blevins, Chichester, Colgan, Cuccinelli, Deeds, Devolites Davis, ... --29." HJ 41 became Chapter 944 and placed the ban on the November 2006 ballot. WHERE THE WRONG CLAIM CAME FROM: the cited page says he "was part of the unanimous Democratic coalition that voted to oppose" the amendment, and its references are a June 2006 party position and an October 2006 announcement that he would vote NO on Ballot Question #1 - the referendum, as a voter. Neither is a legislative vote, and a reader who does not open the roll call cannot tell them apart. The chair cannot be repaired into rung 2 on a vote for the ban, and it is not this audit''s business to seat him at rung 5 on a twenty-year-old vote he has since moved away from. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Routed to re-research. Identifier pass, migration 1923, ledger row R36.','R36'),
-- R24  Hugo Soto-Martinez / jail-capacity  1 -> BLANK  (a union staffing decision is not a record)
('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid,'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid,1,0,
 NULL,
 'INTERNAL RECORD - blanked: there is no instrument to cite, because the evidence is an assignment rather than an act of his own. Shape: ROLE, NOT A POSITION - being designated to a role is offered as advocating for it. WHY: migration 1921 re-seated this row 2 -> 1 on "supporting Measure J". The cited page says something narrower: "In 2020, he was DESIGNATED BY HIS UNION to be the labor liaison on Measure J." He held no office in 2020 - he was elected to the Los Angeles City Council in November 2022 - so this is neither his vote, nor his bill, nor his motion, and compass_topic_roles marks jail-capacity at LOCAL level evidence_basis "record". Being assigned to a campaign by one''s employer is the same shape as the Marcus Simon row this queue already blanked, where appointment to a redistricting commission was ruled an office duty and not a position. 1921 justified the re-seat by noting that Hernandez sits at rung 1 on the same measure, but the same page records Hernandez as a CO-CHAIR of the Measure J campaign, which is an act of her own; two people connected to one ballot measure in different capacities are not the same evidence. OPEN QUESTION RECORDED, NOT ACTED ON: jails in California are a county function and role_scope "local" covers city and county alike, so a city councilmember has no lever here at all. That is a ruling, and compass_topic_roles is not touched. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Identifier pass, migration 1923, ledger row R24.','R24'),
-- R25  Hugo Soto-Martinez / public-safety-approach  1 -> 1  (citation repair; the chair does NOT move)
('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid,1,1,
 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0862',
 'Citation repaired 2026-10-21 (migration 1923). THE CHAIR IS UNCHANGED at 1; only the evidence is. Migration 1921 described the vote without naming the file, so it is named here from the primary source: LOS ANGELES COUNCIL FILE 23-0862, "2023-27 Memorandum of Understanding / Police Officers, Lieutenant and Below Representation Unit (MOU 24) / Los Angeles Police Protective League (LAPPL)". At the Council meeting of 23 August 2023 the item carried 12-3-0, and the recorded vote reads "EUNISSES HERNANDEZ 1 NO ... NITHYA RAMAN 4 NO ... HUGO SOTO-MARTINEZ 13 NO" - he voted NO on the four-year package of raises and bonuses for rank-and-file police officers, arguing it would pull money away from mental health clinicians, homeless outreach workers and other city needs. THE DATE IS PART OF THE CITATION: the same council file carries a second vote on 19 August 2025, 12-0-3, in which he voted YES on a later action, so a reference to "council file 23-0862" without the date does not identify this vote. WHY THIS MATTERS TO THE CHAIR: redirecting money from the police budget to social services is rung 1''s own text, and it is his own recorded vote with his own stated reason. Rung 2 asserts maintaining staffing with unarmed co-responders, which he is not shown advocating. Identifier pass, migration 1923, ledger row R25.','R25'),
-- R28  Kathy KL Tran / abortion  1 -> 1  (citation repair; the chair does NOT move)
('f224a300-8b54-4b57-b988-5c340667f99b'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,1,1,
 'https://lis.virginia.gov/cgi-bin/legp604.exe?191+sum+HB2491',
 'Citation repaired 2026-10-21 (migration 1923). THE CHAIR IS UNCHANGED at 1; only the evidence is. Migration 1921 named the instrument as "the Repeal Act", which identifies no bill; it is numbered here from the primary source: VIRGINIA HB 2491 (2019 session), "Abortion; eliminate certain requirements", which the Legislative Information System records as "Introduced by: Kathy K.L. Tran". The Commonwealth''s own summary is the rung-1 evidence: the bill "eliminates the requirement that two other physicians certify that a third trimester abortion is necessary to prevent the woman''s death or impairment of her mental or physical health, as well as the need to find that any such impairment to the woman''s health would be substantial and irremediable", eliminates the requirement that a second-trimester abortion be performed in a hospital, and eliminates the procedures - including the ultrasound - required to effect informed written consent. HONEST ABOUT THE OUTCOME: the bill did not pass. The subcommittee recommended laying it on the table on 28 January 2019 and it was "Left in Courts of Justice" on 5 February 2019. Sponsorship evidences the bill AS FILED, which is what a position is. WHY THIS MATTERS TO THE CHAIR: removing the third-trimester certification threshold is rung 1''s "at all stages of pregnancy", and her Planned Parenthood funding quote supplies rung 1''s funding limb. Identifier pass, migration 1923, ledger row R28.','R28'),
-- R39  Schuyler T. VanValkenburg / housing  5 -> 5  (citation repair; the chair does NOT move)
('38b9461f-2f5b-45d8-ae99-626c75ae305d'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,5,5,
 'https://lis.virginia.gov/bill-details/20261/SB346',
 'Citation repaired 2026-10-21 (migration 1923). THE CHAIR IS UNCHANGED at 5; only the evidence is. Migrations 1921 and 1922 described two bills without numbering either; both are numbered here from the primary source, and he is Chief Patron of both in the 2026 Virginia session. VIRGINIA SB 346, "Zoning; manufactured housing", amends the requirement that localities permit manufactured homes in agricultural zones by expanding it to all zoning districts where site-built housing is allowed, and bars localities from treating manufactured homes more restrictively than a single-family site-built dwelling in the same district; it passed the Senate 38-Y 2-N and the House 92-Y 6-N and was APPROVED BY THE GOVERNOR as Chapter 20, effective 1 July 2026. VIRGINIA SB 454, "Zoning; by-right multifamily residential development", requires local zoning ordinances to permit multifamily and mixed-use residential development as a by-right use on at least 75 percent of commercially zoned land in qualifying areas and bars localities from requiring a special exception or conditional use permit for it; HONEST ABOUT THE OUTCOME, it passed the Senate and then FAILED, "Left in Counties, Cities and Towns" on 10 March 2026. WHY THIS MATTERS TO THE CHAIR: two independent zoning-liberalisation instruments that he chief-patroned, with nothing on the housing axis about binding rules, subsidies or public building, is rung 5''s "at most, cut the regulations and zoning limits that block private building". One bill could not establish that negative; two of the same shape, with nothing else, can. Identifier pass, migration 1923, ledger row R39.','R39'),
-- R05  Chyanne Chen / growth-and-development  1 -> 1  (citation repair; the chair does NOT move)
('8f59c9fd-03f9-4652-bc4a-418bd8764a1f'::uuid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid,1,1,
 'https://sfstandard.com/2025/12/02/family-zoning-supervisors-vote-daniel-lurie/',
 'Citation repaired 2026-10-21 (migration 1923). THE CHAIR IS UNCHANGED at 1; only the evidence is. Migration 1921 described the vote only as "the December 2025 bill to upzone 60% of San Francisco". The instrument is the Family Zoning Plan rezoning, adopted by the San Francisco Board of Supervisors on 2 December 2025, and her opposition is a recorded vote: the contemporaneous report names every opponent - "Progressive Supervisors Connie Chan, Shamann Walton, Jackie Fielder, and Chyanne Chen tried to water down the legislation with amendments ... All four voted against the measure." She voted No. The same report records her own amendments: she and Chan "unsuccessfully pushed for amendments that would have exempted coastal areas, all residential neighborhoods, and low-income communities from the plan", and she joined amendments pressing for more multi-bedroom units. THE BOARD FILE NUMBER IS NOT CITED, AND THE REASON IS RECORDED RATHER THAN HIDDEN: San Francisco''s public Legistar API is stale - its newest introduction date is 2005 and its newest rezoning matter is 2018 - so date-filtered queries return an empty result that is indistinguishable from "no such record"; a positive control on the same endpoint returned rows, which is how the staleness was established. Searching the Legistar web interface for "Family Zoning" returns instead the unrelated ordinance redefining "Family" as "Household" (File 250719), a near-miss that a name-only match would have cited as the rezoning. WHY THIS MATTERS TO THE CHAIR: amendments to exempt all residential neighbourhoods and coastal areas from the plan, and a vote against the largest upzoning in the city''s recent history, are rung 1''s holding the pace of growth down. JUDGMENT CALL CARRIED FORWARD FROM 1921: her stated reason is process and affordability rather than pace, and rung 1''s referendum clause is not evidenced; it is the nearest rung on a single-choice ladder. Identifier pass, migration 1923, ledger row R05.','R05');

-- GUARD 1 — the decision table arrived whole and says what the ledger says.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1923_decisions;
  IF n <> 6 THEN RAISE EXCEPTION 'migration 1923: expected 6 decisions, found %', n; END IF;
  SELECT count(*) INTO n FROM (SELECT DISTINCT politician_id, topic_id FROM mig1923_decisions) s;
  IF n <> 6 THEN RAISE EXCEPTION 'migration 1923: duplicate (politician, topic) pairs; % distinct of 6', n; END IF;
  SELECT count(*) INTO n FROM mig1923_decisions WHERE new_value = 0;
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1923: expected 2 blanks, found %', n; END IF;
  -- 🔴 A repair may not move a chair. This is the rule the whole queue exists because of.
  SELECT count(*) INTO n FROM mig1923_decisions WHERE new_value <> 0 AND new_value <> value_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1923: % repair(s) would MOVE a chair', n; END IF;
END $$;

-- GUARD 2 — the picture is current: every target still sits where 1921/1922 left it.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1923_decisions d
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_answers pa
      WHERE pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id
        AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
        AND pa.value = d.value_before);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1923: % target(s) do not sit at the expected value - re-measure', n; END IF;
END $$;

-- GUARD 3 — every target is a row 1921 wrote and 1922 left alone.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1923_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning NOT LIKE '%migration 1921%' OR pc.reasoning LIKE '%migration 1922%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1923: % target(s) are not untouched 1921 rows - wrong rows', n; END IF;
END $$;

-- GUARD 4 — the evidence bases this pass reasons from are what it claims. Read them, do not assume.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.compass_topic_roles r
   WHERE (r.topic_id = 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid AND r.role_scope = 'local' AND r.evidence_basis = 'record')
      OR (r.topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND r.role_scope = 'state' AND r.evidence_basis = 'record');
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1923: expected 2 record-basis rows underpinning the blanks, found % - the ruling moved', n; END IF;
END $$;

-- GUARD 5 — nothing may lose its citations.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1923_decisions d
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_context pc
      WHERE pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
        AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
        AND coalesce(cardinality(pc.sources), 0) > 0);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1923: % target(s) have no citations to carry forward', n; END IF;
END $$;

-- The answer. Two blanks write 0; the four repairs rewrite their own unchanged value.
UPDATE inform.politician_answers pa
   SET value = d.new_value, updated_at = now()
  FROM mig1923_decisions d
 WHERE pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- The record of WHY.
UPDATE inform.politician_context pc
   SET reasoning = d.reasoning, updated_at = now()
  FROM mig1923_decisions d
 WHERE pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- The primary source goes into sources, so a repaired row stops resting on a generic page alone.
-- Idempotent — appends only where the URL is not already cited. The Deeds blank gets its roll call
-- too: a blank that says the record points the other way must cite the record it read.
UPDATE inform.politician_context pc
   SET sources = pc.sources || ARRAY[d.add_source], updated_at = now()
  FROM mig1923_decisions d
 WHERE pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   AND d.add_source IS NOT NULL
   AND NOT (pc.sources @> ARRAY[d.add_source]);

-- GUARD 6 — verify the RESULT, not the absence of an error.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1923_decisions d
    JOIN inform.politician_answers pa
      ON pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND pa.value = d.new_value;
  IF n <> 6 THEN RAISE EXCEPTION 'migration 1923: expected 6 rows at their new value, found %', n; END IF;

  SELECT count(*) INTO n
    FROM mig1923_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1923: % row(s) lost their citations', n; END IF;

  -- Every source this pass promised to add is present.
  SELECT count(*) INTO n
    FROM mig1923_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE d.add_source IS NOT NULL AND NOT (pc.sources @> ARRAY[d.add_source]);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1923: % row(s) did not receive their primary source', n; END IF;

  -- A blank must say which kind of nothing it is; a repair must say the chair did not move.
  SELECT count(*) INTO n
    FROM mig1923_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE (d.new_value =  0 AND pc.reasoning NOT LIKE '%Shape:%')
      OR (d.new_value <> 0 AND pc.reasoning NOT LIKE '%THE CHAIR IS UNCHANGED%');
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1923: % row(s) do not record what was done to them', n; END IF;

  -- 🔑 THE POINT OF THE PASS: every repaired row must now name an identifier the lexical gate can
  -- see. This is the gate's own test, asserted here so the migration cannot claim a fix it did not
  -- make. Checked against the four repairs only — a blank seats no chair and owes no instrument.
  SELECT count(*) INTO n
    FROM mig1923_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE d.new_value <> 0
     AND pc.reasoning !~ '(\mHB ?[0-9]|\mSB ?[0-9]|voted (YES|Yes|NO|No)|Council File [0-9])';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1923: % repaired row(s) still name no citable identifier', n; END IF;

  -- 🔴 BLAST RADIUS. Of 1921's nine re-seats: 1922 rewrote three, this pass rewrites four more
  -- (R05, R24, R25, R28 — R36 is a re-seat too, so five), leaving only Harris-Dawson's
  -- own-words row carrying the original re-seat prefix with a live chair.
  SELECT count(*) INTO n
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id AND pa.season_id = pc.season_id
   WHERE pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pc.reasoning LIKE 'CHAIR MOVED%migration 1921%'
     AND pa.value > 0;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1923: expected 1 of 1921''s re-seats left standing, found % - wrong blast radius', n; END IF;

  -- Season 1 is closed and must not have moved.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 1'
    JOIN mig1923_decisions d ON d.politician_id = pa.politician_id AND d.topic_id = pa.topic_id
   WHERE pa.updated_at > now() - interval '5 minutes';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1923: % Season 1 answer(s) were modified — Season 1 is closed', n; END IF;
END $$;
