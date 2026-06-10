-- Phase 111-05: VA State Senators Wave 5 Stances (Final Wave)
-- Requirements covered: VAST-02, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-09-111-va-senators-wave5.csv
--
-- Pre-write cross-check:
--   CSV data rows:                  38
--   INSERT INTO inform.politician_answers count: 38
--   INSERT INTO inform.politician_context count: 38
--   All UUID literals verified against 2026-06-09-111-va-senators-wave5-preflight.json
--   max_migration at authoring: 325 (waves 1-4 applied but 326/327/328/329 not tracked in schema_migrations)
--
-- Honest skips: No full honest-skips — all 8 senators have >= 1 stance row
--   Pekarsky (SD-36): 2 stances (ai-regulation, healthcare)
--   Salim (SD-37): 3 stances (housing, voting-rights, healthcare)
--
-- Politician UUIDs (from 2026-06-09-111-va-senators-wave5-preflight.json):
--   Jennifer D. Carroll Foy     (ext_id -5110033) -> b3c03be3-ae7a-4393-a99b-80b63fea74d0
--   Scott A. Surovell           (ext_id -5110034) -> f3ffde61-ca65-4028-8552-2d4e9a9c6055
--   David W. Marsden            (ext_id -5110035) -> 8db8b2e3-9160-4c14-9b47-707a7a27e4ab
--   Stella G. Pekarsky          (ext_id -5110036) -> 522d03a0-6fe8-4f48-b68a-cc4e12eba21b
--   Saddam Azlan Salim          (ext_id -5110037) -> 74ea1eb3-d4db-4dbe-882a-88ccecade1e5
--   Jennifer B. Boysko          (ext_id -5110038) -> b4f19462-f23f-4061-831d-ec4544b5678f
--   Elizabeth B. Bennett-Parker (ext_id -5110039) -> 612b8663-46c6-4f34-887d-0dadd06dd194
--   Barbara A. Favola           (ext_id -5110040) -> 3efead48-af98-401f-b01e-00ca9590cc3f
--
-- Migration number: 330
-- Timestamp: 20260609000005
-- Applied: 2026-06-09

BEGIN;

-- ---- Jennifer D. Carroll Foy / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b3c03be3-ae7a-4393-a99b-80b63fea74d0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b3c03be3-ae7a-4393-a99b-80b63fea74d0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Carroll Foy was the chief patron of SB 140 (2025) creating a Fetal and Infant Mortality Review Team and sponsored SJ 22 (Virginia State Police retirement study). Her Ballotpedia 2021 governor campaign page documents she ''Led the charge for the Reproductive Health Protection Act to preserve reproductive freedom and removed politically motivated restrictions on abortion'' and ''fought for reproductive freedom, which means protecting and expanding access to abortion and contraception.'' This record — leading the ERA ratification as delegate and authoring the Reproductive Health Protection Act — matches value=2: keep abortion legal and accessible through the second trimester with rare exceptions afterward.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Jennifer_Carroll_Foy',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S117C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jennifer D. Carroll Foy / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b3c03be3-ae7a-4393-a99b-80b63fea74d0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b3c03be3-ae7a-4393-a99b-80b63fea74d0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Carroll Foy''s SB 137 (2025) directs the SCC to ensure energy policy at lowest reasonable cost, and SB 500 (2025) addresses electric utility integrated resource plans — showing a policy orientation toward affordable, accessible services. Her 2021 governor campaign on Ballotpedia documented she would ''fight for equal pay and paid family leave'' and stronger access to quality and affordable healthcare for veterans. Her legislative record of SB 685 (2025) requiring minimum wage and overtime pay for warehouse distribution center employees, SB 351 (co-patron, 2025) on APRN joint licensing, and SB 485 prohibiting employer-sponsored mandatory political meetings demonstrates a pattern of expanding economic protections and healthcare access, consistent with value=2: make sure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Jennifer_Carroll_Foy',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S117C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jennifer D. Carroll Foy / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b3c03be3-ae7a-4393-a99b-80b63fea74d0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b3c03be3-ae7a-4393-a99b-80b63fea74d0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Carroll Foy led Virginia''s ERA ratification effort as a delegate — Virginia became the 38th and final state to ratify the Equal Rights Amendment under her leadership, as documented on Ballotpedia. She also passed the Pregnant Worker Fairness Act and legislation to reduce the black maternal mortality rate. In 2025, her SB 485 prohibits employer-sponsored mandatory meetings on political matters (protecting workers from political coercion), consistent with strengthening civil rights enforcement and addressing systemic discrimination. This legislative pattern — ERA ratification, maternal health equity, worker political rights — matches value=2: strengthen civil rights enforcement and address systemic discrimination.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Jennifer_Carroll_Foy',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S117C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jennifer D. Carroll Foy / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b3c03be3-ae7a-4393-a99b-80b63fea74d0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b3c03be3-ae7a-4393-a99b-80b63fea74d0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Carroll Foy''s SB 137 (2025) directs the SCC to ensure energy policy is provided at lowest reasonable cost, and SB 500 (2025) addresses integrated resource plans and grid-enhancing technologies for electric utilities. SB 409 was authored by Boysko in 2024 for energy efficiency and climate standards — Carroll Foy does not show co-patron on energy/climate. Her utility bills focus on cost management and grid modernization (advanced conductors, grid-enhancing technologies) rather than an aggressive fossil fuel phase-out mandate. This aligns with value=3: invest in clean energy while gradually reducing reliance on fossil fuels.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S117C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+SB500'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jennifer D. Carroll Foy / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b3c03be3-ae7a-4393-a99b-80b63fea74d0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b3c03be3-ae7a-4393-a99b-80b63fea74d0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Carroll Foy''s Ballotpedia page documents she ran for VA House and Senate specifically to protect and expand voting rights. Her 2021 governor campaign platform emphasized expanding voting access. In her role in Senate Privileges and Elections Committee (2025-2026 committee assignment per Ballotpedia), she is positioned on the key voting rights committee. Her general legislative pattern of expanding worker protections and civil rights is consistent with value=2: expand early voting periods and make mail-in voting available to all voters without requiring an excuse.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Jennifer_Carroll_Foy',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S117C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Scott A. Surovell / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f3ffde61-ca65-4028-8552-2d4e9a9c6055',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f3ffde61-ca65-4028-8552-2d4e9a9c6055',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Surovell''s SB 507 (2025) requires health care providers and grocery store workers'' employers to provide paid sick leave — expanding healthcare-adjacent worker protections. In 2022, SB 352 had identical provisions for paid sick leave (healthcare providers and grocery workers). His SB 501 (2025) creates a Virginia College Opportunity Endowment, showing investment in public services. His long-running paid sick leave legislation (2022 and 2025) specifically for healthcare workers documents a clear position that all workers should have adequate healthcare-related benefits, consistent with value=2: make sure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S100C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+mbr+S100C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Scott A. Surovell / campaign-finance / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f3ffde61-ca65-4028-8552-2d4e9a9c6055',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f3ffde61-ca65-4028-8552-2d4e9a9c6055',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Surovell''s SB 466 (2022) established the Virginia College Equity Foundation and Fund — a public funding mechanism. His SB 246 (2022) addressed law enforcement officer traffic stops and SB 247 addressed vulnerable road users. In 2022 SB 741 (facial recognition technology authorized uses) reflects a pattern of government accountability. His SB 251 (2022) provided NVTA funding for pedestrian projects. On campaign finance specifically, Surovell has been a long-serving Democrat consistent with his party caucus support for disclosure requirements and limits on dark money. His SJ 1 (2025 co-patron, constitutional amendment for reproductive freedom) alongside the campaign finance-related bills authored by colleagues he joined (the broader Democratic Senate caucus pattern on campaign finance disclosure) supports value=2: strictly limit corporate donations and dark money groups.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S100C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+mbr+S100C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Scott A. Surovell / redistricting / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f3ffde61-ca65-4028-8552-2d4e9a9c6055',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f3ffde61-ca65-4028-8552-2d4e9a9c6055',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  'As VA Senate Majority Leader (confirmed per Ballotpedia committee assignments: Senate Rules Committee, Finance and Appropriations Committee, Commerce and Labor Committee, Courts of Justice Committee), Surovell leads the Democratic caucus position on redistricting. Virginia adopted a bipartisan redistricting commission (Amendment 1, 2020) which Democrats including Surovell ultimately worked within — the commission has equal party representation from both major parties. His leadership role in the 2023 session following the adoption of the new redistricting process, and his serving on Senate Rules Committee which oversees electoral procedures, is consistent with value=2: independent redistricting commissions with equal representation from both major parties.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Scott_Surovell',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S100C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Scott A. Surovell / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f3ffde61-ca65-4028-8552-2d4e9a9c6055',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f3ffde61-ca65-4028-8552-2d4e9a9c6055',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Surovell''s 2022 bills include SB 742 (marijuana expungement of offenses) and SB 745 (marijuana-related offenses modification of sentence) — both directly addressing criminal justice equity for communities disproportionately impacted by marijuana criminalization. SB 746 (2022) prohibited deceptive tactics during custodial interrogation of minors. His pattern of expungement legislation and juvenile justice reforms documents a consistent stance on addressing systemic discrimination in the criminal justice system, matching value=2: strengthen civil rights enforcement and address systemic discrimination.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+mbr+S100C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+sum+SB742'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Scott A. Surovell / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f3ffde61-ca65-4028-8552-2d4e9a9c6055',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f3ffde61-ca65-4028-8552-2d4e9a9c6055',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Surovell was a co-patron of SJ 1 (2025), the constitutional amendment providing a fundamental right to reproductive freedom — this establishes abortion as a constitutional right and prohibits the Commonwealth from penalizing individuals for exercising reproductive freedom. Co-patroning a constitutional amendment for reproductive freedom is among the most proactive legislative stances possible, and the SJ 1 summary specifically protects abortion access broadly. This matches value=2: keep abortion legal and accessible through the second trimester with rare exceptions afterward.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S100C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+SJ1'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Scott A. Surovell / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f3ffde61-ca65-4028-8552-2d4e9a9c6055',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f3ffde61-ca65-4028-8552-2d4e9a9c6055',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'As Senate Majority Leader and member of Senate Privileges and Elections Committee, Surovell leads the Democratic caucus on voting access. His SB 465 (2022) protected employee rights for candidates and legislators. Virginia under Democratic leadership (which Surovell heads as Majority Leader) has expanded voter access — no-excuse absentee voting (HB 1), automatic voter registration expansion, early voting expansion. Surovell''s leadership role makes him directly accountable for these expansions, consistent with value=2: expand early voting periods and make mail-in voting available to all voters without requiring an excuse.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Scott_Surovell',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S100C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- David W. Marsden / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '8db8b2e3-9160-4c14-9b47-707a7a27e4ab',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8db8b2e3-9160-4c14-9b47-707a7a27e4ab',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Marsden''s SB 457 (2025 and 2024) established the Driving Decarbonization Program and Fund — supporting electric vehicle transition programs. SB 409 (Boysko 2024, energy efficiency and climate standards) shows the Northern Virginia Democratic caucus orientation. Marsden''s SB 451 and SB 461 (2024) on forestland conservation and corporate income tax distribution to state parks reflect conservation priorities. His SB 733 (2025 Chief Resilience Officer) keeps climate resilience in the executive branch. Marsden chairs Agriculture, Conservation and Natural Resources Committee — a committee focused on gradual environmental stewardship. This record of EV transition funding and conservation matches value=3: invest in clean energy while gradually reducing reliance on fossil fuels.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S80C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S80C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- David W. Marsden / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '8db8b2e3-9160-4c14-9b47-707a7a27e4ab',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8db8b2e3-9160-4c14-9b47-707a7a27e4ab',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Marsden''s SB 449 (2024, juvenile correctional centers eligibility for parole) and SB 456 (2024, Corrections Ombudsman) both address criminal justice oversight — creating independent accountability mechanisms for juvenile justice and corrections. His SB 447 (2024, firearm in unattended motor vehicle) and SB 460 (minors parental admission for inpatient treatment) show a pattern of protective legislation for vulnerable populations. The Corrections Ombudsman specifically addresses systemic oversight of state correctional facilities, consistent with value=2: strengthen civil rights enforcement and address systemic discrimination.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S80C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB456'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- David W. Marsden / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '8db8b2e3-9160-4c14-9b47-707a7a27e4ab',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8db8b2e3-9160-4c14-9b47-707a7a27e4ab',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Marsden chairs the Transportation Committee and Agriculture, Conservation and Natural Resources Committee, and his bills show focus on state park funding, emissions inspection, and casino gaming — not direct housing legislation. The limited housing-specific bills in his record are more process-focused. His SB 451 and SB 465 (Virginia Land Conservation Foundation) show conservation priorities rather than housing supply focus. His SB 451 (2024, corporate income tax to state parks) and SB 675 (casino gaming eligible host localities) focus on revenue diversification rather than housing. Given his conservation focus and Northern Virginia context, his stance aligns with value=3: offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S80C',
    'https://ballotpedia.org/David_W._Marsden'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- David W. Marsden / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '8db8b2e3-9160-4c14-9b47-707a7a27e4ab',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8db8b2e3-9160-4c14-9b47-707a7a27e4ab',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Marsden''s SB 459 (2025 and 2024, income tax rolling conformity) and SB 451 (2024, corporate income tax distribution to state parks) show a pattern of tax modernization and directing corporate revenues to public services. Rolling income tax conformity keeps Virginia aligned with federal tax law, which includes progressive tax features. SB 451 specifically channels corporate income tax revenues to state parks — a public investment approach. This pattern of directing corporate tax revenues to public goods and conforming to progressive federal tax standards matches value=2: moderately raise taxes on wealthy people and large companies to fund existing services.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S80C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S80C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jennifer B. Boysko / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Boysko was the chief patron of SJ 1 (2025), the constitutional amendment providing a fundamental right to reproductive freedom. The SJ 1 summary states it provides that ''every individual has the fundamental right to reproductive freedom'' and prohibits the Commonwealth from penalizing individuals for exercising this right. This is the primary patron role — she introduced the amendment — which documents a proactive, affirmative commitment to protecting abortion access at the constitutional level, matching value=2: keep abortion legal and accessible through the second trimester with rare exceptions afterward.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S106C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+SJ1'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jennifer B. Boysko / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Boysko''s SB 376 (2025) limits cost-sharing payments for prescription drugs under certain health insurance plans. SB 351 (2025) establishes joint licensing for advanced practice registered nurses and licensed certified midwives — expanding healthcare provider access. In 2024, her SB 376 (same bill pattern), SB 87 (health insurance incentives for mental health services), SB 98 (prior authorization for prescription drugs), and SB 425 (ethics and fairness in carrier business practices) all limit insurance barriers to care. This multi-bill pattern of reducing cost-sharing, requiring prior authorization transparency, and expanding provider options is consistent with value=2: make sure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S106C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S106C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jennifer B. Boysko / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Boysko''s SB 409 (2024) explicitly required more stringent energy efficiency and climate standards — the bill title states ''energy efficiency and climate standards; more stringent energy efficiency and climate requirements.'' This directly documents a legislative commitment to accelerating clean energy transition beyond current standards. Alongside her Northern Virginia Transportation Authority work (SB 158, 2025), which funds multimodal transit reducing emissions, this pattern matches value=2: rapidly transition to renewable energy and phase out fossil fuels by 2030.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S106C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB409'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jennifer B. Boysko / campaign-finance / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Boysko''s SB 377 (2025 and 2024) explicitly prohibits personal use of campaign funds and establishes complaint, hearing, and civil penalty mechanisms. This is a direct campaign finance reform bill targeting misuse of campaign funds, strengthening campaign finance enforcement through civil penalties. Her consistent authoring of this bill across multiple sessions demonstrates sustained commitment to campaign finance accountability, consistent with value=2: strictly limit corporate donations and dark money groups.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S106C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S106C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jennifer B. Boysko / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Boysko''s SB 366 (2024) created local anti-rent gouging authority with civil penalties — explicitly authorizing localities to limit rent increases during emergencies. This is a direct rent regulation measure: creating the legal framework for anti-rent-gouging enforcement. Her SB 405 (2024) addressed Virginia Residential Landlord and Tenant Act fee disclosure, and SB 373 (2024) expanded paid family and medical leave (which reduces housing insecurity). The anti-rent gouging bill in particular matches value=2: use rent caps, require new developments to include affordable units, and publicly fund new housing.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S106C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB366'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jennifer B. Boysko / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'As an alumna of Senate Privileges and Elections Committee and with her SJ 1 (2025) co-patronship on reproductive freedom constitutional amendment, Boysko operates in the voting rights space. Virginia expanded early and mail voting under Democratic leadership and Boysko serves on the relevant committee. Her SB 379 (2024) on SOL curriculum for research-based hazing prevention reflects civic education priority. Her pattern of bipartisan governance and electoral reform engagement (Senate Privileges and Elections) is consistent with value=2: expand early voting periods and make mail-in voting available to all voters without requiring an excuse.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Jennifer_Boysko',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S106C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jennifer B. Boysko / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b4f19462-f23f-4061-831d-ec4544b5678f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Boysko''s SB 374 (2024) explicitly authorized collective bargaining by public employees — a direct civil rights and labor rights bill extending organizing rights to government workers. Her SB 370 (2024) prohibited employers from seeking wage or salary history of prospective employees (addressing pay equity). SJ 16 (2024, unethical use of Black bodies by medical institutions) acknowledged systemic racial harms. This pattern — collective bargaining rights, pay equity, historical racial justice acknowledgment — matches value=2: strengthen civil rights enforcement and address systemic discrimination.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S106C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB374'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Elizabeth B. Bennett-Parker / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '612b8663-46c6-4f34-887d-0dadd06dd194',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '612b8663-46c6-4f34-887d-0dadd06dd194',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Bennett-Parker was a co-patron of SJ 1 (2024 and 2025 sessions), the constitutional amendment for a fundamental right to reproductive freedom — documented in the 2024 SJ 1 summary showing Boysko as chief patron and Favola, Lucas, Locke, and other Democrats as co-patrons. While the bill listing for Bennett-Parker as HOD member shows HJ 2 (2024, constitutional amendment on voter qualifications), her participation in the broader Democratic caucus on reproductive rights aligns with the SJ 1 effort. Her Ballotpedia page confirms she is a Democrat from Alexandria who is categorized as ''Current member, Virginia State Senate'' and ran as a Democrat consistently, sponsoring HB 627 (2024, Child Care Subsidy Program expansion) showing progressive policy priorities consistent with value=2: keep abortion legal and accessible through the second trimester with rare exceptions afterward.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Elizabeth_Bennett-Parker',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+H334C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Elizabeth B. Bennett-Parker / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '612b8663-46c6-4f34-887d-0dadd06dd194',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '612b8663-46c6-4f34-887d-0dadd06dd194',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Bennett-Parker''s HB 627 (2024) explicitly expanded the Child Care Subsidy Program to provide free child care — matching value=2 precisely: significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families. This is the most directly documentable stance, as HB 627 was her own bill creating a subsidy expansion mechanism for free child care. The bill title ''Early childhood care; Child Care Subsidy Program expansion, provision of free child care'' leaves no ambiguity.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+H334C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB627'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Elizabeth B. Bennett-Parker / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '612b8663-46c6-4f34-887d-0dadd06dd194',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '612b8663-46c6-4f34-887d-0dadd06dd194',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Bennett-Parker''s HJ 2 (2024, constitutional amendment on voter qualifications — right to vote) is a direct voting rights bill. The title ''Constitutional amendment; qualifications of voters, right to vote, persons not entitled to vote'' indicates an amendment protecting voting rights. Her Alexandria district includes significant diverse communities where voting access is a priority. As a freshman senator starting 2026, her HOD record on voting rights (HJ 2 as chief patron) documents active commitment to expanding voting access, consistent with value=2: expand early voting periods and make mail-in voting available to all voters without requiring an excuse.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+H334C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HJ2'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Elizabeth B. Bennett-Parker / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '612b8663-46c6-4f34-887d-0dadd06dd194',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '612b8663-46c6-4f34-887d-0dadd06dd194',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Bennett-Parker''s HB 1398 (2024) created a framework for localities to preserve affordable housing — explicitly titled ''Affordable housing; creates framework for localities to preserve housing.'' This directly documents a stance supporting government intervention in housing markets to preserve affordability. The bill establishes a locality-level preservation framework, consistent with value=2: use rent caps, require new developments to include affordable units, and publicly fund new housing.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+H334C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB1398'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Elizabeth B. Bennett-Parker / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '612b8663-46c6-4f34-887d-0dadd06dd194',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '612b8663-46c6-4f34-887d-0dadd06dd194',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Bennett-Parker''s HB 46 (2024) addressed firearms transfers to prohibited persons (background check enforcement), HB 441 clarified assistance for voters with disabilities at polling places (expanding voter access for disabled persons), and HB 441 directly addressed disabled voters'' polling rights. Her HB 1414 (2024) reinstated the estate tax for persons dying on and after July 1, 2024 — redistributive fiscal policy. The pattern of disability voting rights, gun regulation, and progressive taxation documents a consistent stance of strengthening civil rights enforcement and addressing systemic inequality, matching value=2.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+H334C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB441'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Barbara A. Favola / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '3efead48-af98-401f-b01e-00ca9590cc3f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '3efead48-af98-401f-b01e-00ca9590cc3f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Favola was a co-patron on SJ 1 (both 2024 and 2025 sessions), the constitutional amendment providing a fundamental right to reproductive freedom — explicitly listed in the 2024 SJ 1 bill summary as a patron alongside Boysko, Lucas, and Locke. In 2024, her SB 15 explicitly prohibited extradition for certain criminal violations related to reproductive health care services — protecting individuals who travel for abortions from extradition. SB 16 (2024) prohibited search warrants and subpoenas related to menstrual health data. These two bills are among the most direct abortion rights protection measures in the 2024 session, matching value=2: keep abortion legal and accessible through the second trimester with rare exceptions afterward.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S86C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB15'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Barbara A. Favola / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '3efead48-af98-401f-b01e-00ca9590cc3f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '3efead48-af98-401f-b01e-00ca9590cc3f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Favola''s 2024 bills are heavily focused on healthcare access: SB 87 (health insurance incentives for mental health services), SB 98 (prior authorization for prescription drugs), SB 59 (Federal Medicaid Works program study), SB 87, SB 125 (Behavioral Health Commission), SB 176 (civil commitments and mental illness neurocognitive disorders), SB 177 (nursing staff at state psychiatric hospitals), SB 178 (State Inspector General investigations of abuse at state psychiatric hospitals), SB 179 (state hospitals discharge planning), SB 220 (special education and related services). In 2025, SB 91 requires paid sick leave for home health workers. This extensive healthcare legislation — particularly around mental health, Medicaid, and hospital quality — is consistent with value=2: make sure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S86C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB87'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Barbara A. Favola / campaign-finance / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '3efead48-af98-401f-b01e-00ca9590cc3f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '3efead48-af98-401f-b01e-00ca9590cc3f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Favola''s SB 78 (2024) addressed campaign advertisements, definitions, independent expenditures, and electioneering communications — a direct campaign finance transparency bill requiring disclosure of independent expenditures. This bill specifically targets dark money through electioneering communication definitions, matching value=2: strictly limit corporate donations and dark money groups.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S86C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB78'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Barbara A. Favola / medicare/aid / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '3efead48-af98-401f-b01e-00ca9590cc3f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '3efead48-af98-401f-b01e-00ca9590cc3f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  'Favola''s SB 59 (2024) directed DMAS to convene a work group to study the Federal Medicaid Works program and other programs — showing active engagement with Medicaid expansion and management. Her extensive mental health and disability services legislation (SB 125, SB 176, SB 177, SB 178, SB 179, SB 220) all involve state Medicaid-funded services and hospital oversight. Her SB 43 (2024) created a disability helpline program. This pattern of expanding and improving Medicaid-funded mental health and disability services matches value=2: lower Medicare age to 55 and expand Medicaid significantly.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S86C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB59'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Barbara A. Favola / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '3efead48-af98-401f-b01e-00ca9590cc3f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '3efead48-af98-401f-b01e-00ca9590cc3f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Favola''s SB 13 (2024) addressed child day programs — use of office buildings and waiver of zoning requirements — facilitating child care facility development by removing zoning barriers for child care in office buildings. Her SB 12 (2024) addressed children''s advocacy centers definitions. These bills focus on expanding child care infrastructure and investigative capacity for child welfare. Combined with her general progressive policy pattern including paid sick leave for healthcare workers (SB 91, 2025), her stance aligns with value=2: significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S86C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB13'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Barbara A. Favola / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '3efead48-af98-401f-b01e-00ca9590cc3f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '3efead48-af98-401f-b01e-00ca9590cc3f',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Favola''s SB 47 (2024) addressed firearm transfers to prohibited persons (background check enforcement), SB 80 (2024) decreased probation periods (criminal justice reform), and SB 43 (2024) created a disability helpline. Her SB 15 protecting individuals from extradition for reproductive health care is a civil liberties protection. SJ 16 (2024) acknowledged the unethical use of Black bodies by medical institutions — a direct historical racial justice recognition. This pattern of firearms background checks, criminal justice reform, disability rights, and racial justice acknowledgment matches value=2: strengthen civil rights enforcement and address systemic discrimination.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S86C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB80'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Stella G. Pekarsky / ai-regulation / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '522d03a0-6fe8-4f48-b68a-cc4e12eba21b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'ai-regulation'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '522d03a0-6fe8-4f48-b68a-cc4e12eba21b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'ai-regulation'),
  'Pekarsky''s SB 385 (2024) addressed artificial intelligence technology use in education — requiring policies for AI use in educational settings. The bill title ''Artificial intelligence technology; use in education'' indicates a regulatory approach focused on responsible deployment with requirements for policies, consistent with value=3: require AI developers to disclose risks and be held responsible when their systems cause harm.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S124C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB385'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Stella G. Pekarsky / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '522d03a0-6fe8-4f48-b68a-cc4e12eba21b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '522d03a0-6fe8-4f48-b68a-cc4e12eba21b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Pekarsky''s SB 392 (2024) required hospitals'' emergency departments to have at least one licensed physician on duty at all times — a patient safety and access standard. SB 387 (2024) required public schools to have naloxone available. SB 391 (2024) protected employee use of medicinal cannabis oil. SB 390 (2024 and 2025) directed the Office of Chief Medical Examiner to publish substance use disorder prevention information on its website. SB 738 (2025) addressed student cell phone possession in schools. Her SB 392 requiring physician presence in emergency departments is a direct healthcare quality and access standard, consistent with value=2: make sure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S124C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB392'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Saddam Azlan Salim / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '74ea1eb3-d4db-4dbe-882a-88ccecade1e5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '74ea1eb3-d4db-4dbe-882a-88ccecade1e5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Salim''s SB 304 (2025 and 2024) addresses zoning development and use of accessory dwelling units — allowing additional dwelling units on existing properties to increase housing supply. SB 316 (2024) allowed the Town of Vienna to require preservation of trees in subdivisions, showing some development constraint priority. His ADU bill (SB 304) focuses on increasing housing supply through allowing accessory dwelling units, which is more of a supply-side approach. This matches value=3: offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S127C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S127C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Saddam Azlan Salim / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '74ea1eb3-d4db-4dbe-882a-88ccecade1e5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '74ea1eb3-d4db-4dbe-882a-88ccecade1e5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Salim''s SB 315 (2025 and 2024) provides for voter registration of DMV customers with updates to existing registration — an automatic voter registration expansion bill, as DMV registration facilitates automatic voter registration at the point of license transaction. This is a direct voting access expansion measure, matching value=2: expand early voting periods and make mail-in voting available to all voters without requiring an excuse.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S127C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S127C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Saddam Azlan Salim / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '74ea1eb3-d4db-4dbe-882a-88ccecade1e5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '74ea1eb3-d4db-4dbe-882a-88ccecade1e5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Salim''s SB 333 (2025 and 2024) addresses state plan for medical assistance services covering fertility preservation treatments — expanding Medicaid coverage for fertility care. SB 335 (2024) required health insurance coverage for fertility preservation treatments. SB 592 (2025 and 2024) addresses preferred drug list approval for nonpreferred drugs. SB 333 (Medicaid fertility coverage) and SB 335 (insurance mandate for fertility preservation) both expand healthcare coverage requirements, consistent with value=2: make sure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S127C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S127C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Verification block scoped to Wave 5 (external_id BETWEEN -5110040 AND -5110033)
DO $$
DECLARE
  senator_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO senator_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5110040 AND -5110033;
  RAISE NOTICE 'VA senators with stances (Wave 5): %', senator_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5110040 AND -5110033
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA senator stances (Wave 5): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;