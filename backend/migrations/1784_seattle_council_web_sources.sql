-- 1784_seattle_council_web_sources.sql
-- Seattle's 11 city offices, re-researched from WEB sources. 42 seated rows + 5 documented blanks.
--
-- 🔴 WHY THIS EXISTS. Task 10 (migs 1754 + 1759) searched ONE SOURCE CLASS: Legistar roll calls and
-- ordinance PDFs. All 13 source URLs on its 11 rows were Legistar attachments. Across Seattle's 11
-- city offices that method produced TWO rows on ONE official (Strauss). The operator called it: a
-- blank there meant "no roll-call-provable chair", not "no evidenced position". Seattle
-- councilmembers demonstrably hold public positions on housing, policing, transit and taxes.
--
-- 🔑 THE SOURCE CLASS THAT CHANGED THE OUTCOME: THE URBANIST'S CANDIDATE QUESTIONNAIRES.
-- Long-form, verbatim, candidate-authored answers to specific policy questions -- the same shape as
-- the washcodems.org questionnaire that supplied 36 of Beaverton's citations. NINE of the eleven
-- officials have one. Kettle declined both questionnaire and interview and is sourced from a
-- PubliCola Q&A in his own words; Juarez served 2016-23 and is sourced from her record.
--
-- ── ✅ THE QUESTIONNAIRES WERE TESTED AGAINST THE RECORD, NOT TRUSTED ─────────────────────────────
-- A campaign promise abandoned in office is not a sincere chair-match. The September 2025
-- comprehensive plan vote is the sharpest available test and it CORROBORATED the 2023 answers:
--   · Saka said density belongs "along transit corridors and in urban villages" -> in 2025 he sought
--     to block docketing of neighbourhood-centre expansion. Consistent with chair 3.
--   · Rivera said "I do not support abolishing single-family zoning" -> in 2025 she proposed halving
--     the Bryant and Wedgwood centres. Consistent with chair 2.
--   · Rinck promised parking reform and more centres -> proposed restoring 8 centres the same year.
--   · Strauss sits at local-environment=3 from Ord. 126821 -> he OPPOSED the 2025 strict tree
--     amendment. An existing row corroborated from an entirely different source class.
-- Where the test FAILED it produced a blank, not a seating: Hollingsworth's 2023 "Alternative 5"
-- answer is in tension with her 2025 record as land use chair, so residential-zoning stays blank.
--
-- ── 🔑 housing CHAIR 2 IS REACHABLE AT CITY LEVEL AND WAS RULED UNREACHABLE AT STATE LEVEL ────────
-- The WA legislative sweep found housing chair 2 unreachable because it needs rent caps AND
-- inclusionary units AND public funding, and an anchored search of 3,411 bills found ZERO
-- inclusionary-zoning instruments. Seattle's MHA IS inclusionary zoning, so a city official can hold
-- all three limbs -- Dionne Foster does. UNREACHABILITY IS A PROPERTY OF A CHAIR MEETING A CORPUS,
-- NOT OF THE CHAIR TEXT ALONE. Re-test "unreachable" findings when the corpus changes.
--
-- ── 🔑 THE taxes DESTINATION RULE SPLIT THREE OFFICIALS WHO ALL "SUPPORT PROGRESSIVE REVENUE" ─────
-- Wilson lists new taxes to fund her housing and homelessness priorities -> chair 1. Foster frames
-- local progressive revenue as the answer to FEDERAL CUTS, i.e. holding existing services -> chair 2.
-- Juarez voted against JumpStart -> blank. Identical vocabulary, three different outcomes. The rule
-- from migration 1759 travels from a state legislature to a city council unchanged.
--
-- ⚠ A VAGUE CANDIDATE YIELDS FEW ROWS, AND THAT IS THE METHOD WORKING. Saka's questionnaire answers
-- progressive revenue with "collaboration and accountability" and impact fees with "a balanced and
-- equitable approach". He gets 2 rows. No coverage was manufactured from a record that has none.
--
-- ▶ OWED: Rivera is PRIME SPONSOR of the 2025 tree preservation amendment (passed 4-3). Sponsorship
-- outranks a vote, so that is the highest-value unseated row -- but chair 1 vs chair 2 turns on
-- whether it requires developers to fully offset impact, which needs the AMENDMENT TEXT, not the
-- news summary. Reading it would also place Saka, Juarez and Hollingsworth (for) and Strauss
-- (against) on local-environment.
--
-- Strauss's two pre-existing rows (taxes=1, local-environment=3) are DELIBERATELY UNTOUCHED: the
-- value-change guard returned CONFIRMED for both, so there is nothing to write.
BEGIN;

CREATE TEMP TABLE sc_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

CREATE TEMP TABLE sc_rows (pid uuid, tid uuid, val int, nm text, tk text) ON COMMIT DROP;
INSERT INTO sc_rows (pid, tid, val, nm, tk) VALUES
('90d1ac0b-efa6-42fc-abb2-34767380d607','f7e5678d-dadd-4556-a2fc-446e24642ceb',1,'Katie Wilson','taxes'),
('90d1ac0b-efa6-42fc-abb2-34767380d607','669cac97-66a6-4087-b036-936fbe62efb3',1,'Katie Wilson','housing'),
('90d1ac0b-efa6-42fc-abb2-34767380d607','d4f18138-a2e0-4110-b925-7387d9d0d16d',4,'Katie Wilson','residential-zoning'),
('90d1ac0b-efa6-42fc-abb2-34767380d607','ba59337e-30e2-4aba-a39a-426b3366eb27',1,'Katie Wilson','transportation-priorities'),
('90d1ac0b-efa6-42fc-abb2-34767380d607','e9ebefcd-c496-45e8-b816-a79f8442ba85',2,'Katie Wilson','public-safety-approach'),
('90d1ac0b-efa6-42fc-abb2-34767380d607','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',2,'Katie Wilson','homelessness-response'),
('9e33c647-967a-4dce-a900-ad7d066cc57f','f7e5678d-dadd-4556-a2fc-446e24642ceb',1,'Eddie Lin','taxes'),
('9e33c647-967a-4dce-a900-ad7d066cc57f','d4f18138-a2e0-4110-b925-7387d9d0d16d',4,'Eddie Lin','residential-zoning'),
('9e33c647-967a-4dce-a900-ad7d066cc57f','ba59337e-30e2-4aba-a39a-426b3366eb27',1,'Eddie Lin','transportation-priorities'),
('9e33c647-967a-4dce-a900-ad7d066cc57f','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',2,'Eddie Lin','homelessness-response'),
('9e33c647-967a-4dce-a900-ad7d066cc57f','e9ebefcd-c496-45e8-b816-a79f8442ba85',2,'Eddie Lin','public-safety-approach'),
('9e33c647-967a-4dce-a900-ad7d066cc57f','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',4,'Eddie Lin','growth-and-development'),
('9e33c647-967a-4dce-a900-ad7d066cc57f','669cac97-66a6-4087-b036-936fbe62efb3',4,'Eddie Lin','housing'),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','669cac97-66a6-4087-b036-936fbe62efb3',2,'Dionne Foster','housing'),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',2,'Dionne Foster','rent-regulation'),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','f7e5678d-dadd-4556-a2fc-446e24642ceb',2,'Dionne Foster','taxes'),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','d4f18138-a2e0-4110-b925-7387d9d0d16d',4,'Dionne Foster','residential-zoning'),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','ba59337e-30e2-4aba-a39a-426b3366eb27',1,'Dionne Foster','transportation-priorities'),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','e9ebefcd-c496-45e8-b816-a79f8442ba85',3,'Dionne Foster','public-safety-approach'),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',2,'Dionne Foster','homelessness-response'),
('5c98f25c-4d32-450c-8428-4e3647cbde4d','669cac97-66a6-4087-b036-936fbe62efb3',1,'Alexis Mercedes Rinck','housing'),
('5c98f25c-4d32-450c-8428-4e3647cbde4d','d4f18138-a2e0-4110-b925-7387d9d0d16d',4,'Alexis Mercedes Rinck','residential-zoning'),
('5c98f25c-4d32-450c-8428-4e3647cbde4d','ba59337e-30e2-4aba-a39a-426b3366eb27',1,'Alexis Mercedes Rinck','transportation-priorities'),
('5c98f25c-4d32-450c-8428-4e3647cbde4d','f7e5678d-dadd-4556-a2fc-446e24642ceb',1,'Alexis Mercedes Rinck','taxes'),
('1018a81d-652c-46bb-9e18-3adf91d1f474','4938766b-b45a-46e3-93bd-b8b30651271a',2,'Erika Evans','homelessness'),
('1018a81d-652c-46bb-9e18-3adf91d1f474','9db07b16-1076-4b7d-ad89-ebe7b51f4336',2,'Erika Evans','judicial-criminal-justice'),
('1018a81d-652c-46bb-9e18-3adf91d1f474','abb99d95-cbb1-4617-8f8b-f220ef6028ca',3,'Erika Evans','judicial-prosecution-priorities'),
('1018a81d-652c-46bb-9e18-3adf91d1f474','f7e5678d-dadd-4556-a2fc-446e24642ceb',1,'Erika Evans','taxes'),
('215f2142-c0a1-46fb-b78e-3204843ae3e5','d4f18138-a2e0-4110-b925-7387d9d0d16d',3,'Rob Saka','residential-zoning'),
('215f2142-c0a1-46fb-b78e-3204843ae3e5','e9ebefcd-c496-45e8-b816-a79f8442ba85',4,'Rob Saka','public-safety-approach'),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','4938766b-b45a-46e3-93bd-b8b30651271a',2,'Joy Hollingsworth','homelessness'),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',3,'Joy Hollingsworth','growth-and-development'),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','f7e5678d-dadd-4556-a2fc-446e24642ceb',1,'Joy Hollingsworth','taxes'),
('81057c65-d128-4712-8ded-52c4534b0d9b','d4f18138-a2e0-4110-b925-7387d9d0d16d',2,'Maritza Rivera','residential-zoning'),
('81057c65-d128-4712-8ded-52c4534b0d9b','e9ebefcd-c496-45e8-b816-a79f8442ba85',4,'Maritza Rivera','public-safety-approach'),
('81057c65-d128-4712-8ded-52c4534b0d9b','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',3,'Maritza Rivera','growth-and-development'),
('81057c65-d128-4712-8ded-52c4534b0d9b','ba59337e-30e2-4aba-a39a-426b3366eb27',2,'Maritza Rivera','transportation-priorities'),
('2e4714c6-feb4-443f-9cc0-08d866a0a99f','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',2,'Dan Strauss','homelessness-response'),
('2e4714c6-feb4-443f-9cc0-08d866a0a99f','e9ebefcd-c496-45e8-b816-a79f8442ba85',2,'Dan Strauss','public-safety-approach'),
('2e4714c6-feb4-443f-9cc0-08d866a0a99f','ba59337e-30e2-4aba-a39a-426b3366eb27',1,'Dan Strauss','transportation-priorities'),
('b510823d-e54b-40a5-92c0-09a6636359d5','d4f18138-a2e0-4110-b925-7387d9d0d16d',3,'Debora Juarez','residential-zoning'),
('8c15f6a8-2c28-4b34-a736-ca4d6340f615','e9ebefcd-c496-45e8-b816-a79f8442ba85',4,'Robert Kettle','public-safety-approach'),
('b510823d-e54b-40a5-92c0-09a6636359d5','f7e5678d-dadd-4556-a2fc-446e24642ceb',NULL,'Debora Juarez','taxes'),
('8c15f6a8-2c28-4b34-a736-ca4d6340f615','ba59337e-30e2-4aba-a39a-426b3366eb27',NULL,'Robert Kettle','transportation-priorities'),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','d4f18138-a2e0-4110-b925-7387d9d0d16d',NULL,'Joy Hollingsworth','residential-zoning'),
('9e33c647-967a-4dce-a900-ad7d066cc57f','1935979c-b290-42e4-baa5-8cb0138b4ffa',NULL,'Eddie Lin','local-environment'),
('1018a81d-652c-46bb-9e18-3adf91d1f474','7bad33eb-e93e-4d94-8822-97212d49bde5',NULL,'Erika Evans','judicial-police-accountability');

DO $$
DECLARE n int;
BEGIN
  -- Nothing here may overwrite an existing curated row.
  SELECT count(*) INTO n FROM sc_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % of these pairs already have an answer', n; END IF;
  SELECT count(*) INTO n FROM sc_rows r
    JOIN inform.politician_context c ON c.politician_id=r.pid AND c.topic_id=r.tid;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % of these pairs already have a context row', n; END IF;

  -- Strauss's two existing rows are the value-change guard's CONFIRMED no-ops. If either has moved
  -- since the diff was run, the confirmation in this header is stale and must be redone.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='2e4714c6-feb4-443f-9cc0-08d866a0a99f'
     AND ((topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND value=1)
       OR (topic_id='1935979c-b290-42e4-baa5-8cb0138b4ffa' AND value=3));
  IF n <> 2 THEN RAISE EXCEPTION 'pre-check: Strauss taxes=1 / local-environment=3 no longer both present (found %)', n; END IF;

  -- Chair-text tripwires for the three ladders carrying the most rows here.
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='d4f18138-a2e0-4110-b925-7387d9d0d16d' AND value=4 AND text ILIKE '%%parking requirements%%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: residential-zoning chair 4 is no longer the reduce-parking chair'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND value=1 AND text ILIKE '%%cycling networks%%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: transportation-priorities chair 1 has been reworded'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85' AND value=2 AND text ILIKE '%%co-responders%%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: public-safety-approach chair 2 has been reworded'; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('90d1ac0b-efa6-42fc-abb2-34767380d607','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Asked which progressive revenue sources she would add to fund her priorities, Wilson answered "Yes" and listed a capital gains tax ("we should have done that last year"), "turn[ing] the dials" on the JumpStart payroll expense tax to raise more, restructuring the B&O tax, a land value tax, and a professional services excise tax, a digital ad tax and a vacancy tax from the Progressive Tax Options for Seattle report she co-authored. Her stated priorities are affordable and abundant housing and a real reduction in homelessness, so the destination is new investment rather than backfilling existing services. That is chair 1 rather than chair 2, which funds existing services.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/katie-wilson-2025-urbanist-questionnaire-responses-for-publication.pdf']),
('90d1ac0b-efa6-42fc-abb2-34767380d607','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Wilson answers the housing question with "Build social housing!" alongside support for community land trusts, and separately proposes "granting social housing the same density bonus that other types of affordable housing get". Seattle social housing is publicly owned in perpetuity by the Social Housing Developer and available across a broad income range, which is chair 1 rather than chair 3 targeted assistance. Chair 2 is refuted from her own answer: she would "exempt smaller projects from MHA fees so they will pencil out", the opposite of requiring new development to include affordable units.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/katie-wilson-2025-urbanist-questionnaire-responses-for-publication.pdf']),
('90d1ac0b-efa6-42fc-abb2-34767380d607','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Wilson would "Zone for more housing in neighborhoods throughout Seattle" and "Reform permitting, design review, and other bureaucratic hurdles that make it so expensive and difficult to build right now", and on the comprehensive plan calls for "adding more neighborhood growth centers, expanding the definition of near transit" and "eliminating parking minimums". Broad upzoning, streamlined approvals and reduced parking are chair 4 verbatim. Chair 5 is not reached: she works through growth centers and transit proximity and nowhere proposes allowing any housing type on any lot citywide.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/katie-wilson-2025-urbanist-questionnaire-responses-for-publication.pdf']),
('90d1ac0b-efa6-42fc-abb2-34767380d607','ba59337e-30e2-4aba-a39a-426b3366eb27',
 $r$Wilson would prioritise "transforming our most dangerous corridors, from Aurora to Rainier, into people-centered streets with great public transit", and "Maximize efficient use of Keep Seattle Moving Levy dollars to build new sidewalks, improve transit infrastructure, and connect our bike network", together with eliminating parking minimums. Pedestrian infrastructure, cycling networks, transit and reduced parking are chair 1 in full. Chair 2 is refuted because she does not propose investing equally in roads.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/katie-wilson-2025-urbanist-questionnaire-responses-for-publication.pdf']),
('90d1ac0b-efa6-42fc-abb2-34767380d607','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Wilson would "Expand alternative crisis response and civilian roles, so police can focus on policing", specifically by creating "a better dispatch protocol so that the CARE team can respond to crisis calls independently when safe and appropriate" and "civilianizing ancillary work, from directing traffic at events to taking down crime reports". She proposes neither an increase nor a reduction in sworn staffing anywhere in the answer, which is what separates chair 2 from chair 4 and from chair 1. The mechanism she names is shifting call types away from armed officers, which is chair 2 rather than chair 3.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/katie-wilson-2025-urbanist-questionnaire-responses-for-publication.pdf']),
('90d1ac0b-efa6-42fc-abb2-34767380d607','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
 $r$Wilson would "Expand Tiny House Villages and other forms of shelter" as her housing-and-shelter answer, and would concentrate street-level enforcement of public order "mainly on collaboration with case managers through the evidence-based LEAD framework", ensuring the response to low-level drug-related crime "focuses on treatment, shelter, and ongoing supportive services". Expanding shelter capacity and services as the primary strategy with enforcement paired to services is chair 2. Chair 1 is not reached: her lead mechanism is shelter and tiny houses rather than permanent supportive housing with no preconditions.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/katie-wilson-2025-urbanist-questionnaire-responses-for-publication.pdf']),
('9e33c647-967a-4dce-a900-ad7d066cc57f','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Lin answers that he "absolutely support[s] new progressive revenues", would "defend (and potentially increase) the Jump Start Payroll Tax", would "support a local Capital Gains Tax and open to considering other taxes, like a vacancy tax", and supports a state Wealth Tax, calling the regressive state tax system "immoral and bad public policy". His priorities are lowering housing costs, getting people off the streets into shelter and treatment, and gun violence prevention, so the revenue funds new investment. That is chair 1 rather than chair 2.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/eddie-lin-urbanist-questionnaire-responses-for-publication.pdf']),
('9e33c647-967a-4dce-a900-ad7d066cc57f','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Lin would "reduce housing production barriers like design review, parking requirements, and overly restrictive limits around height, setbacks, floor area ratios (FARs) and lot coverage", would "eliminate parking requirements for housing developments", and says "We really should be allowing dense, walkable neighborhoods everywhere, and not just concentrating growth on arterials or in little pockets", pushing "to maximize density and growth as much as allowed". Broad upzoning, streamlined approvals and reduced parking are chair 4. Chair 5 is not reached: he never calls for eliminating single-family-only zoning or allowing any housing type on any lot.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/eddie-lin-urbanist-questionnaire-responses-for-publication.pdf']),
('9e33c647-967a-4dce-a900-ad7d066cc57f','ba59337e-30e2-4aba-a39a-426b3366eb27',
 $r$Lin would convert dangerous two-lane arterials to one lane each way, and calls for "protected bike lanes, more sidewalks, and raised crosswalks", the new Shared Streets law "to put pedestrians first", piloting car-free zones, congestion pricing, and eliminating parking requirements. Prioritising pedestrian infrastructure, cycling networks and transit while reducing parking is chair 1 in full.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/eddie-lin-urbanist-questionnaire-responses-for-publication.pdf']),
('9e33c647-967a-4dce-a900-ad7d066cc57f','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
 $r$Lin would "increase shelters and tiny home villages, by permitting more of them throughout the City, including on public property, and funding them, especially funding supportive services", and calls for "more Housing First options, with robust supportive services". Expanding shelter capacity and services as the primary strategy is chair 2. Chair 1 is not reached because his lead mechanism is shelter and tiny homes rather than permanent supportive housing with no preconditions, and chairs 4 and 5 are refuted because he proposes no enforcement tool at all.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/eddie-lin-urbanist-questionnaire-responses-for-publication.pdf']),
('9e33c647-967a-4dce-a900-ad7d066cc57f','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Lin calls for "better 911 responses, with more social workers and mental health specialists for situations that do not require an officer", and would "negotiate a SPOG contract without limits on the number of CARES or Health One responders", reasoning that this "will allow police the capacity to respond to dangerous crimes". Shifting the calls that do not need an armed officer to unarmed responders, without proposing a change to sworn staffing, is chair 2. Chair 3 is not reached: his mechanism is reallocating call types rather than adding teams on top of current funding.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/eddie-lin-urbanist-questionnaire-responses-for-publication.pdf']),
('9e33c647-967a-4dce-a900-ad7d066cc57f','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
 $r$Lin says the comprehensive plan "should allow for much more growth!!!" and blames underpredicted growth in the last plan for the housing cost and homelessness crisis. He would "streamline the permitting process, both in terms of timelines and substantive requirements", provide "more tax exemptions for housing production", and hold MHA payments on middle housing to at most a de minimis amount. He also states chair 4 rationale explicitly: incentivizing housing production "brings in revenues through sales taxes, REETA, and increased property taxes". Streamlined permitting, reduced fees and a tax-base rationale are the three limbs of chair 4.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/eddie-lin-urbanist-questionnaire-responses-for-publication.pdf']),
('9e33c647-967a-4dce-a900-ad7d066cc57f','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Lin's housing answer is a deregulatory supply programme: "We need a bold Comprehensive Plan and to reduce housing production barriers like design review, parking requirements, and overly restrictive limits around height, setbacks, floor area ratios (FARs) and lot coverage. We can streamline the permitting process". Cutting regulations and zoning rules so private developers can build more is chair 4. Chair 2 is refuted from his own words: he does "not support applying MHA to middle housing in formerly single-family zones", so he rejects requiring new development to include affordable units.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/eddie-lin-urbanist-questionnaire-responses-for-publication.pdf']),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Foster holds all three of chair 2's limbs. She would "Support statewide rent stabilization and tenant protections" (rent caps); on MHA she warns that "Allowing duplexes, triplexes, and other middle housing types without any affordability requirements risks missing an opportunity" and wants its benefits "shared equitably across the city" (requiring new development to include affordable units); and she would "Protect dedicated affordable housing funds" and invest in subsidised housing (publicly funding new housing). Chair 3 is the weaker fit because her programme is not limited to targeted assistance.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/dionne-foster-urbanist-questionnaire-responses-for-publication.pdf']),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Foster would "Support statewide rent stabilization and tenant protections to ensure a level playing field and provide safe, affordable housing for all renters in Seattle." Washington enacted statewide rent stabilisation in EHB 1217 in 2025, so supporting and extending it is chair 2, strengthening existing rent stabilization and extending coverage. This follows the ruling already made on EHB 1217 in the Washington legislative sweep, where chair 2 was chosen over chair 3 because "maintain current tenant protections" is the more serious mismatch for a first-ever statewide cap.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/dionne-foster-urbanist-questionnaire-responses-for-publication.pdf']),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Foster supports progressive revenue, but her stated destination is preservation rather than expansion: "The Trump administration and its massive budget cuts threaten our city. We need to get real about this threat and get serious about local progressive revenue," starting from the Revenue Stabilization Workgroup report with "a local capital gains tax or exploring partnership with the state for a mansion tax", and she would "work to protect our budgets from harmful federal overreach". Revenue raised to hold existing services against federal cuts is chair 2, not chair 1. This is the destination test that has governed this ladder since migration 1759.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/dionne-foster-urbanist-questionnaire-responses-for-publication.pdf']),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Foster would add "another group of centers" beyond the Mayor's plan and would "look at other areas where we can add additional density, flexibility, or options for housing including expanding corridor upzones, areas around transit facilities, along Highway 99 and other underutilized areas", concluding that "The neighborhood center approach has its limitations; the fundamental goal is housing abundance." Chair 3 is refuted by its second clause, since she does not protect most residential zones. Chair 4's main clause, broad upzoning, is positively evidenced; its by-right and parking limbs are unstated, which is incompleteness rather than contradiction.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/dionne-foster-urbanist-questionnaire-responses-for-publication.pdf']),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','ba59337e-30e2-4aba-a39a-426b3366eb27',
 $r$Foster would "frontload sidewalk construction in historically under resourced neighborhoods", target Vision Zero projects, build transit-ready infrastructure "continuing to make it easier to get around Seattle without a car", and deliver bike infrastructure; on street space she writes that "Reclaiming street space from car storage and car lanes creates room for more efficient, equitable, and sustainable uses--like dedicated bus lanes, protected bike lanes, wider sidewalks". Her mention of bridges and roadways is maintenance, not investment parity, so this is chair 1 rather than chair 2.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/dionne-foster-urbanist-questionnaire-responses-for-publication.pdf']),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Foster would "Advocate for smart workforce development policies that attract and retain the officers we need" and "Support continued investment in the city's CARE Team, gun violence prevention programs, and community-driven solutions", alongside treatment on demand and behavioral health investment. Retaining current staffing while adding and sustaining crisis response capacity is chair 3. Chair 4 is not reached because she nowhere proposes increasing the force, and chair 2 is not reached because she does not propose shifting call types away from officers.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/dionne-foster-urbanist-questionnaire-responses-for-publication.pdf']),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
 $r$Foster would "Prioritize getting people indoors by working with regional agencies to invest in treatment on demand, permanent supportive housing, and emergency shelter solutions - including tiny homes." Expanding shelter and services as the primary strategy is chair 2. Chair 1 is not reached because permanent supportive housing is one item in a list led by getting people indoors through shelter, and she states no position against enforcement, which chair 1 requires.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/dionne-foster-urbanist-questionnaire-responses-for-publication.pdf']),
('5c98f25c-4d32-450c-8428-4e3647cbde4d','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Rinck writes that "As a proud supporter of Prop 1A I believe social housing represents a vital tool", that it "provides a financially sustainable solution, ensuring stable and affordable homes for a broad range of incomes", and that "With Prop 1A passing decisively, I have already begun to work with the Seattle Social Housing Developer to expedite bringing new housing online." Publicly owned housing available across incomes rather than means-tested is chair 1, and she is acting on it in office rather than only endorsing it.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/03/early-endorsement-questionnaire-for-scc-alexis-mercedes-rinck-1.pdf']),
('5c98f25c-4d32-450c-8428-4e3647cbde4d','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Rinck would "Push for removing and/or reducing where possible all minimum parking requirements for residential and commercial spaces", "Allow more homes near transit... Specifically allowing 1/2 mile around bus stops, and 1/2 mile around light rail stations", "Align Seattle's middle housing standards with the Department of Commerce model ordinance", create FAR bonuses for fourplexes and six-plexes, and allow corner stores on all lots. Broad upzoning, streamlined standards and reduced parking are chair 4. Her 2025 comprehensive plan work corroborates it: she proposed restoring eight neighbourhood growth centres and pressed parking reform and ADU incentives.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/03/early-endorsement-questionnaire-for-scc-alexis-mercedes-rinck-1.pdf','https://www.theurbanist.org/2025/09/20/seattle-council-punts-on-housing-expansion-passes-strict-tree-preservation-rules/']),
('5c98f25c-4d32-450c-8428-4e3647cbde4d','ba59337e-30e2-4aba-a39a-426b3366eb27',
 $r$Rinck writes that "As a transit rider who chooses not to own a car" her focus "is on building an integrated network that prioritizes walking, biking, rolling, and public transit", including "expanding public transit, electrifying our transportation infrastructure, adding sidewalks, creating safer bike routes, and improving accessible pedestrian signals", and separately would remove all minimum parking requirements where possible. Prioritising pedestrian infrastructure, cycling networks and transit while reducing parking is chair 1 in full.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/03/early-endorsement-questionnaire-for-scc-alexis-mercedes-rinck-1.pdf','https://www.theurbanist.org/2025/09/20/seattle-council-punts-on-housing-expansion-passes-strict-tree-preservation-rules/']),
('5c98f25c-4d32-450c-8428-4e3647cbde4d','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Rinck names as a top priority "Enacting new progressive revenue options... and invest further into our city services to ensure Seattle can truly be a city that works for everyone", and in office authored and passed an amendment to Seattle's state legislative priorities "to increase funding for affordable housing" and another "to support new statewide progressive revenue options". The authored amendment increases funding rather than preserving it, which is what places her at chair 1 rather than chair 2. Note she also states a preservation purpose (preventing cuts to essential services); the increase is the discriminator and this is the row to revisit if that reading is rejected.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/03/early-endorsement-questionnaire-for-scc-alexis-mercedes-rinck-1.pdf']),
('1018a81d-652c-46bb-9e18-3adf91d1f474','4938766b-b45a-46e3-93bd-b8b30651271a',
 $r$Asked directly "Do you support camping bans or sweeps?", Evans answers "Absolutely not. Sweeping our unhoused neighbors... is cruel, ineffective, and unethical." She would "strongly support legislation or filing amicus briefs opposing the U.S. Supreme Court's decision in City of Grants Pass v. Johnson, which overturned Martin v. Boise and opened the door for cities to criminalize homelessness", and concludes "We should invest in housing and services, not push people further into crisis." Decriminalising public sleeping while investing in shelter and services is chair 2. Chair 1's second limb, redirecting enforcement budgets, is unstated.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/erika-evans-urbanist-questionnaire-responses-for-publication.pdf']),
('1018a81d-652c-46bb-9e18-3adf91d1f474','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Evans names "Restorative Justice" as her second stated priority and would bring "back a better version of Community Court--one that connects people to housing and services while still ensuring accountability", moving "from reactive prosecution to proactive justice... to address root causes of crime". A community court connecting people to treatment and services is chair 2, giving the person a fair chance to make things right. Because the purpose is STATED rather than inferred, the stated purpose governs over the structural reading of chair 3, following the boundary set in migration 1780.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/erika-evans-urbanist-questionnaire-responses-for-publication.pdf']),
('1018a81d-652c-46bb-9e18-3adf91d1f474','abb99d95-cbb1-4617-8f8b-f220ef6028ca',
 $r$Evans would "Clear the backlog. Prosecute wage theft, DUI, domestic violence, and assault cases swiftly", ensure "property crimes that hurt small businesses are taken seriously", and simultaneously "Rebuild Community Court to address root causes". Prosecuting strong cases while using diversion where it clearly benefits is chair 3. Chair 2 is refuted by her own commitments: she does not reserve prosecution for when community safety requires it but pledges to prosecute more of the backlog faster.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/erika-evans-urbanist-questionnaire-responses-for-publication.pdf']),
('1018a81d-652c-46bb-9e18-3adf91d1f474','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Evans notes that "The City Attorney doesn't set tax policy" and then states her position anyway: "I strongly support fixing Washington's regressive tax code. We need bold, progressive revenue sources--like taxing extreme wealth and excess corporate profits--to fund housing, public safety, and community services." Taxing wealth and large corporations to fund services is chair 1; the adverb "bold" and the expansion of the services named place it above chair 2.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/erika-evans-urbanist-questionnaire-responses-for-publication.pdf']),
('215f2142-c0a1-46fb-b78e-3204843ae3e5','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Asked his preferred comprehensive plan growth alternative, Saka answered that "my preferred approach is one that prioritizes density and affordability. Specifically, I support an approach that focuses on increasing the most density along transit corridors and in urban villages." Concentrating multifamily density on corridors and designated villages while leaving other residential zones alone is chair 3. His record corroborates the questionnaire rather than contradicting it: in the September 2025 comprehensive plan process he sought to block the study and docketing of neighbourhood centre expansion.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/rob-saka-urbanist-questionnaire-2023.pdf','https://www.theurbanist.org/2025/09/20/seattle-council-punts-on-housing-expansion-passes-strict-tree-preservation-rules/']),
('215f2142-c0a1-46fb-b78e-3204843ae3e5','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Saka answered that "we need to ensure that our police department is adequately staffed to provide efficient and effective law enforcement services to our residents and businesses. We need better response times," and would "offer competitive salary and benefits packages, invest in training and professional development opportunities" to recruit and retain officers. Increasing staffing and pay to improve response times is chair 4. He also mentions community-led initiatives addressing root causes; under the contradiction test that is incompleteness, not a refutation, because chair 4 claims no exclusivity.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/rob-saka-urbanist-questionnaire-2023.pdf']),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','4938766b-b45a-46e3-93bd-b8b30651271a',
 $r$Asked under what circumstances encampment removals are appropriate, Hollingsworth answered in full: "I oppose efforts to criminalize and stigmatize people that are experiencing homelessness, including homeless encampment sweeps." Elsewhere she would "invest in permanent supportive housing and affordable housing projects that prioritize evidence-based best practices". Opposing criminalisation while investing in housing and services is chair 2. Chair 1 is not reached because she does not propose redirecting enforcement budgets, and chairs 3 to 5 are refuted by her categorical opposition to sweeps.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/joy-hollingsworth-urbanist-questionnaire-2023.pdf']),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
 $r$On impact fees Hollingsworth answered that "With business and housing construction growing throughout the city, we will invite a denser population of Seattle residents and employees. We must invest in the infrastructure necessary to keep our city's services and programs sustainable and meet the needs of our growing population." Investing in infrastructure proactively to support expansion is chair 3. Chairs 1 and 2 are refuted because she imposes no growth limit and conditions no approvals on capacity; chairs 4 and 5 are refuted because she supports adding development fees rather than reducing them.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/joy-hollingsworth-urbanist-questionnaire-2023.pdf']),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Hollingsworth answered that she supports "the taxes recommended in the 2018 Report of the Progressive Revenue Task Force on Housing and Homelessness... such as a payroll tax, high-earners income tax, tax on large businesses, and real estate transfer tax, which would generate revenue to fund programs that address the critical issues of housing and homelessness in Seattle", and that "the wealthiest residents and businesses pay their fair share". The named destination is programmes addressing housing and homelessness, which is new investment, placing this at chair 1 rather than chair 2.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/joy-hollingsworth-urbanist-questionnaire-2023.pdf']),
('81057c65-d128-4712-8ded-52c4534b0d9b','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Rivera answered that "I do not support abolishing single-family zoning and believe that whatever changes we consider we need to be gradual and thoughtful in our approach to new development", and that allowing "development up to quad-plexes everywhere in the City while expanding transit-oriented development" would address the affordability crisis and "preserve the unique character of our neighborhoods". Modest, gradual density increases with neighbourhood character preserved is chair 2. Her record corroborates it: in the September 2025 comprehensive plan process she proposed cutting the Bryant and Wedgwood neighbourhood centres roughly in half.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/maritza-rivera-urbanist-questionnaire-2023.pdf','https://www.theurbanist.org/2025/09/20/seattle-council-punts-on-housing-expansion-passes-strict-tree-preservation-rules/']),
('81057c65-d128-4712-8ded-52c4534b0d9b','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Rivera answered that "The Seattle Police Department is down to the lowest staffing levels in at least 30 years. We must go beyond hiring and retention incentives to think innovatively about how to increase staffing," and that she will "work to ensure 5-minute response times for priority one calls, a return to full staffing at pre-2021 levels", adding that "the City Council's decision to defund the police was flat out wrong". Increasing staffing to improve response times is chair 4. She also wants alternatives to policing scaled up, which under the contradiction test is incompleteness rather than a refutation of chair 4.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/maritza-rivera-urbanist-questionnaire-2023.pdf']),
('81057c65-d128-4712-8ded-52c4534b0d9b','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
 $r$On impact fees Rivera answered that they "are used by more than 70 Washington State cities and many more across the nation to cover basic investments in infrastructure, transportation, and other essentials", quoting approvingly that it is "high time for Seattle to catch up to cities... that collect reasonable impact fees from for-profit real estate developments to ensure our infrastructure is strong and safe". Investing in infrastructure to support growth is chair 3. Chairs 4 and 5 are refuted because she would add development fees rather than reduce or remove them.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/maritza-rivera-urbanist-questionnaire-2023.pdf']),
('81057c65-d128-4712-8ded-52c4534b0d9b','ba59337e-30e2-4aba-a39a-426b3366eb27',
 $r$Rivera answered that "I am a strong advocate for increasing multi-modal transportation options including buses, light-rail, pedestrian infrastructure, and bike lanes" while also insisting "we cannot continue to kick the can down the road when it comes to maintenance and repairs including for our aging bridges, sidewalks, and existing infrastructure". Naming road and bridge investment alongside multimodal, rather than prioritising one over the other, is chair 2. Chair 1 is refuted because she does not subordinate road investment, and chair 4 because she does not privilege drivers.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/maritza-rivera-urbanist-questionnaire-2023.pdf']),
('2e4714c6-feb4-443f-9cc0-08d866a0a99f','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
 $r$Strauss answered that "We must continue moving to a system that resolves encampments by providing the right resources of shelter/housing, the time needed to make the move from the streets to a safer place, and relationships that allow people to trust outreach workers' offers", and that "My work at Ballard Commons and Woodland Parks resolved encampments without sweeps" using "a census, a needs assessment, and taking the time to get people inside". Shelter and services as the primary strategy, with enforcement only after services are offered, is chair 2. This is his own record, not a promise.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/dan-strauss-urbanist-questionnaire-2023-1.pdf']),
('2e4714c6-feb4-443f-9cc0-08d866a0a99f','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Strauss answered that "We need to focus police time on crime and interrupting criminal activity while continuing to expand public safety responses that do not require an armed officer to resolve", and set out which responder belongs to which call type, reporting that "despite staffing shortages Priority 1 calls have a 7 min response time in part because we have stopped asking them to respond to homelessness, mental health, and the parks". Holding sworn staffing while shifting non-violent calls to unarmed responders is chair 2. His support for competitive officer pay is incompleteness rather than a refutation.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/dan-strauss-urbanist-questionnaire-2023-1.pdf']),
('2e4714c6-feb4-443f-9cc0-08d866a0a99f','ba59337e-30e2-4aba-a39a-426b3366eb27',
 $r$Strauss answered that "Developing vision zero improvements, expanding safe streets, and creating safe pedestrian crossing and traffic slowing in neighborhoods are essential to the next Seattle transportation levy", naming the Burke-Gilman Missing Link and Aurora and Rainier Avenue safety improvements as his priorities, and elsewhere the Ballard Avenue cafe street pilot. Prioritising pedestrian infrastructure and cycling networks is chair 1. Chair 2 is not reached because he names no road capacity investment to balance against them.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/dan-strauss-urbanist-questionnaire-2023-1.pdf']),
('b510823d-e54b-40a5-92c0-09a6636359d5','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Juarez backed the 2019 Mandatory Housing Affordability upzones across the city's urban centres and villages, the concrete land use act of her two terms, and presents herself as pro-growth on housing. MHA raised density in designated urban centres and villages while leaving most single-family zones unchanged, which is chair 3. Chair 4 is not reached: her record is upzoning designated areas rather than broad by-right multifamily, and she supported the strict tree preservation amendment in September 2025.$r$,
 ARRAY['https://www.theurbanist.org/seattle-council-poised-to-appoint-debora-juarez-to-vacant-d5-seat/','https://www.theurbanist.org/2025/09/20/seattle-council-punts-on-housing-expansion-passes-strict-tree-preservation-rules/']),
('8c15f6a8-2c28-4b34-a736-ca4d6340f615','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Asked about police staffing, Kettle answered "We do need to have the [appropriate] number of officers based on city of our size. So I support the mayor's goal [of 1,400 officers]." SPD was at its lowest staffing in at least 30 years, so endorsing a 1,400-officer target is a commitment to increase the force, which is chair 4. His accompanying point that "We can't succeed in public safety if we don't also succeed in public health, and that primarily means behavioral health and addiction issues" is incompleteness rather than a refutation, since chair 4 claims no exclusivity.$r$,
 ARRAY['https://publicola.com/2023/10/24/publicola-questions-city-council-candidate-bob-kettle-district-7/']),
('b510823d-e54b-40a5-92c0-09a6636359d5','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Unable to place on this ladder. Juarez was one of only two councilmembers to vote against the 2020 JumpStart corporate payroll tax, Seattle's signature progressive revenue measure. That refutes chairs 1 and 2, which both require raising taxes on wealthy people and large companies. It does not evidence chairs 3, 4 or 5: a single vote against one tax states no alternative, proposes no cut, and says nothing about the level of public services. Direction is not a chair, and the fallback is a blank rather than the next chair along.$r$,
 ARRAY['https://www.theurbanist.org/seattle-council-poised-to-appoint-debora-juarez-to-vacant-d5-seat/']),
('8c15f6a8-2c28-4b34-a736-ca4d6340f615','ba59337e-30e2-4aba-a39a-426b3366eb27',
 $r$Unable to place on this ladder. Kettle authored a 2026 amendment cutting the Seattle Transit Measure renewal from the proposed 0.3 percent to 0.2 percent, eliminating about 1.1 million service hours and halting future city-funded bus service expansion, while reserving the remaining 0.1 percent of sales tax authority for the council to use without voter approval. His stated rationale is fiscal restraint, that "we must spend our public dollars strategically, rather than raising the sales tax simply because we can", plus Metro ridership at 70 percent of 2019 levels. Chairs 3 and 4 are separated by what he would fund instead, and he names only "any emergent transportation investment" with no priorities attached, so the ladder cannot discriminate. Maintaining current bus service and ORCA funding refutes chair 5.$r$,
 ARRAY['https://www.theurbanist.org/kettle-proposes-slashing-seattle-transit-measure-halting-city-funded-bus-service-growth/']),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 $r$Unable to place on this ladder. Her 2023 questionnaire preferred comprehensive plan "Alternative 5, as it allows the most amount of housing" and said she would lobby for a new alternative to "bring density to all around Seattle", which reads as chair 4 or 5. As land use chair in September 2025 she presided over a council that deferred the housing expansion decisions and she voted for the strict tree preservation amendment, which cuts the other way. Her individual votes on the density amendments were not obtained, so the stated position and the record are in tension and neither is established. Do not seat either reading without the roll call.$r$,
 ARRAY['https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2023/07/joy-hollingsworth-urbanist-questionnaire-2023.pdf','https://www.theurbanist.org/2025/09/20/seattle-council-punts-on-housing-expansion-passes-strict-tree-preservation-rules/']),
('9e33c647-967a-4dce-a900-ad7d066cc57f','1935979c-b290-42e4-baa5-8cb0138b4ffa',
 $r$Unable to place on this ladder. Lin holds a position no chair describes: add tree canopy on public land while removing tree-retention duties from private housing development. In his words, "We can increase tree canopy by putting more trees in public spaces, including rights-of-way, instead of trying to impose tree retention burdens on housing", and "I push back against the idea that trees have to be maintained on private property". Chairs 1 and 2 require preservation and offset duties on development, which he rejects; chairs 4 and 5 describe reducing environmental protection overall, which he also rejects since he would expand public canopy; chair 3 describes flexibility within consistent standards rather than relocating the duty from private lots to public land. Ladder gap, logged in COMPASS-LADDER-TROUBLE-SPOTS.md.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/eddie-lin-urbanist-questionnaire-responses-for-publication.pdf']),
('1018a81d-652c-46bb-9e18-3adf91d1f474','7bad33eb-e93e-4d94-8822-97212d49bde5',
 $r$Unable to place on this ladder. The ladder asks whether the office defends government employees or holds them accountable when they do wrong. Evans states that she "investigated law enforcement officers for misconduct and excessive force" as a federal prosecutor, which is her prior record rather than a statement about how this office should act, and her one forward-looking proposal is prevention: "expanding the role of precinct liaison attorneys... providing training, improving communication, helping prevent harm, and reducing costly legal claims." Reducing claims by preventing harm does not answer the defend-versus-accountability question, so no chair is evidenced. On-topic by vocabulary is not on-topic by rationale.$r$,
 ARRAY['https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/erika-evans-urbanist-questionnaire-responses-for-publication.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('90d1ac0b-efa6-42fc-abb2-34767380d607','f7e5678d-dadd-4556-a2fc-446e24642ceb', 1),
('90d1ac0b-efa6-42fc-abb2-34767380d607','669cac97-66a6-4087-b036-936fbe62efb3', 1),
('90d1ac0b-efa6-42fc-abb2-34767380d607','d4f18138-a2e0-4110-b925-7387d9d0d16d', 4),
('90d1ac0b-efa6-42fc-abb2-34767380d607','ba59337e-30e2-4aba-a39a-426b3366eb27', 1),
('90d1ac0b-efa6-42fc-abb2-34767380d607','e9ebefcd-c496-45e8-b816-a79f8442ba85', 2),
('90d1ac0b-efa6-42fc-abb2-34767380d607','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2),
('9e33c647-967a-4dce-a900-ad7d066cc57f','f7e5678d-dadd-4556-a2fc-446e24642ceb', 1),
('9e33c647-967a-4dce-a900-ad7d066cc57f','d4f18138-a2e0-4110-b925-7387d9d0d16d', 4),
('9e33c647-967a-4dce-a900-ad7d066cc57f','ba59337e-30e2-4aba-a39a-426b3366eb27', 1),
('9e33c647-967a-4dce-a900-ad7d066cc57f','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2),
('9e33c647-967a-4dce-a900-ad7d066cc57f','e9ebefcd-c496-45e8-b816-a79f8442ba85', 2),
('9e33c647-967a-4dce-a900-ad7d066cc57f','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4),
('9e33c647-967a-4dce-a900-ad7d066cc57f','669cac97-66a6-4087-b036-936fbe62efb3', 4),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','669cac97-66a6-4087-b036-936fbe62efb3', 2),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','d4f18138-a2e0-4110-b925-7387d9d0d16d', 4),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','ba59337e-30e2-4aba-a39a-426b3366eb27', 1),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','e9ebefcd-c496-45e8-b816-a79f8442ba85', 3),
('675e3f43-73e9-4de8-b514-d63b146a8fc7','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2),
('5c98f25c-4d32-450c-8428-4e3647cbde4d','669cac97-66a6-4087-b036-936fbe62efb3', 1),
('5c98f25c-4d32-450c-8428-4e3647cbde4d','d4f18138-a2e0-4110-b925-7387d9d0d16d', 4),
('5c98f25c-4d32-450c-8428-4e3647cbde4d','ba59337e-30e2-4aba-a39a-426b3366eb27', 1),
('5c98f25c-4d32-450c-8428-4e3647cbde4d','f7e5678d-dadd-4556-a2fc-446e24642ceb', 1),
('1018a81d-652c-46bb-9e18-3adf91d1f474','4938766b-b45a-46e3-93bd-b8b30651271a', 2),
('1018a81d-652c-46bb-9e18-3adf91d1f474','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 2),
('1018a81d-652c-46bb-9e18-3adf91d1f474','abb99d95-cbb1-4617-8f8b-f220ef6028ca', 3),
('1018a81d-652c-46bb-9e18-3adf91d1f474','f7e5678d-dadd-4556-a2fc-446e24642ceb', 1),
('215f2142-c0a1-46fb-b78e-3204843ae3e5','d4f18138-a2e0-4110-b925-7387d9d0d16d', 3),
('215f2142-c0a1-46fb-b78e-3204843ae3e5','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','4938766b-b45a-46e3-93bd-b8b30651271a', 2),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3),
('1187a22d-1064-4ff4-8193-189c34b4b6e8','f7e5678d-dadd-4556-a2fc-446e24642ceb', 1),
('81057c65-d128-4712-8ded-52c4534b0d9b','d4f18138-a2e0-4110-b925-7387d9d0d16d', 2),
('81057c65-d128-4712-8ded-52c4534b0d9b','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('81057c65-d128-4712-8ded-52c4534b0d9b','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3),
('81057c65-d128-4712-8ded-52c4534b0d9b','ba59337e-30e2-4aba-a39a-426b3366eb27', 2),
('2e4714c6-feb4-443f-9cc0-08d866a0a99f','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2),
('2e4714c6-feb4-443f-9cc0-08d866a0a99f','e9ebefcd-c496-45e8-b816-a79f8442ba85', 2),
('2e4714c6-feb4-443f-9cc0-08d866a0a99f','ba59337e-30e2-4aba-a39a-426b3366eb27', 1),
('b510823d-e54b-40a5-92c0-09a6636359d5','d4f18138-a2e0-4110-b925-7387d9d0d16d', 3),
('8c15f6a8-2c28-4b34-a736-ca4d6340f615','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4);

DO $$
DECLARE ans_after int; ctx_after int; s record; bad int; n int;
BEGIN
  SELECT * INTO s FROM sc_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 42 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +42', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 47 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +47', s.ctx_before, ctx_after; END IF;

  -- Every seated row: right chair, real reasoning, at least one source, and the source is one of the
  -- hosts this pass actually fetched. A count guard alone would pass if every row collapsed onto one
  -- chair, so the value is asserted against the per-row expectation in sc_rows.
  SELECT count(*) INTO bad
    FROM sc_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
    JOIN inform.politician_context c ON c.politician_id=r.pid AND c.topic_id=r.tid
   WHERE r.val IS NOT NULL
     AND (a.value <> r.val
          OR coalesce(cardinality(c.sources),0) = 0
          OR length(c.reasoning) < 200
          OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) u
                          WHERE u LIKE 'https://www.theurbanist.org/%'
                             OR u LIKE 'https://publicola.com/%'));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % seated row(s) wrong chair, thin reasoning or unsourced', bad; END IF;

  -- Assert the chair SPREAD separately: a bug collapsing everyone onto one value still satisfies the
  -- checks above. These are the four ladders where this pass seated more than one distinct chair.
  SELECT count(DISTINCT a.value) INTO n FROM sc_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
   WHERE r.tk = 'residential-zoning';
  IF n <> 3 THEN RAISE EXCEPTION 'guard 2: residential-zoning should hold 3 distinct chairs (2,3,4), found %', n; END IF;
  SELECT count(DISTINCT a.value) INTO n FROM sc_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
   WHERE r.tk = 'taxes';
  IF n <> 2 THEN RAISE EXCEPTION 'guard 2: taxes should hold 2 distinct chairs (1,2), found %', n; END IF;
  SELECT count(DISTINCT a.value) INTO n FROM sc_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
   WHERE r.tk = 'public-safety-approach';
  IF n <> 3 THEN RAISE EXCEPTION 'guard 2: public-safety-approach should hold 3 distinct chairs (2,3,4), found %', n; END IF;
  SELECT count(DISTINCT a.value) INTO n FROM sc_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
   WHERE r.tk = 'housing';
  IF n <> 3 THEN RAISE EXCEPTION 'guard 2: housing should hold 3 distinct chairs (1,2,4), found %', n; END IF;

  -- Every blank: context, NO answer, the carve-out phrase, and it must be TRUE of the row.
  SELECT count(*) INTO bad
    FROM sc_rows r
    JOIN inform.politician_context c ON c.politician_id=r.pid AND c.topic_id=r.tid
   WHERE r.val IS NULL
     AND (c.reasoning !~ '^Unable to place on this ladder'
          OR coalesce(cardinality(c.sources),0) = 0
          OR EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id=r.pid AND a.topic_id=r.tid));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % documented blank(s) malformed or carrying an answer', bad; END IF;

  -- All 11 Seattle officials must now hold at least one answer. This is the headline claim.
  SELECT count(*) INTO n FROM (
    SELECT DISTINCT r.pid FROM sc_rows r
      JOIN inform.politician_answers a ON a.politician_id=r.pid) x;
  IF n <> 11 THEN RAISE EXCEPTION 'guard 2: % of 11 Seattle officials hold an answer, expected 11', n; END IF;
END $$;

DO $$
DECLARE orphans int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'Seattle: 42 seated rows + 5 documented blanks across 11 of 11 city offices; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
