-- Phase 106: DC Shadow Senators (Strauss + Jain) + EHN Gap-Fill Stances
-- Requirements covered: DCST-03
-- Source CSVs:
--   backend/data/stance-research/2026-06-08-106-dc-shadow-senators-strauss.csv
--   backend/data/stance-research/2026-06-08-106-dc-shadow-senators-jain.csv
--   backend/data/stance-research/2026-06-08-106-ehn-gap-fill.csv
--
-- Pre-write cross-check:
--   Strauss CSV data rows:    0  (honest skip per D-09 — no documentable stances)
--   Jain CSV data rows:       6
--   EHN CSV data rows:       19
--   Total CSV data rows:     25
--   INSERT INTO inform.politician_answers count: 25 ✓
--   INSERT INTO inform.politician_context count: 25 ✓
--   All UUID literals verified against 2026-06-08-106-dcst03-uuids.json ✓
--   No D-08 violations: EHN pre-flight snapshot had 0 existing stances (full pass) ✓
--
-- Politician UUIDs (from 2026-06-08-106-dcst03-uuids.json):
--   Paul Strauss          (ext_id -600016) -> 71e0a6de-fd71-45ab-a591-9e3c376ac23d
--   Ankit Jain            (ext_id -600017) -> 239d8ac5-4dc5-4266-831d-5aa821996435
--   Eleanor Holmes Norton (ext_id -600030) -> 4dbc8de1-9984-42a5-b2aa-5445bf0619b9
--
-- D-08 NOTE (EHN Gap-Fill):
--   EHN pre-flight query returned 0 rows (no existing stances in DB).
--   Therefore the gap-fill is a full 44-topic research pass.
--   Topics intentionally NOT touched (empty set — no prior stances to preserve):
--   NONE. All 19 researched topics had no prior sourced stances.
--
-- Migration number: 291 (after Plan 01's 289 and Plan 02's 290)
-- Timestamp: 20260608000003
-- Applied: NOT YET (write-only)

BEGIN;

-- ============ Paul Strauss (-600016) — full pass per D-09 ============
-- No researchable stances found per D-09. Shadow senators are low-coverage
-- politicians. Paul Strauss's public record is focused exclusively on DC
-- statehood procedural advocacy with no documented positions on the 44 compass
-- topics that match any specific chair text per D-06/D-11 (FIVE-CHAIRS).
-- Zero stances is honest and acceptable per D-09.

-- ============ Ankit Jain (-600017) — full pass per D-09 ============

-- ---- Ankit Jain / abortion / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '239d8ac5-4dc5-4266-831d-5aa821996435',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '239d8ac5-4dc5-4266-831d-5aa821996435',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Jain explicitly campaigns to remove the federal budget prohibition that prevents DC from using local tax dollars to help low-income women afford abortions. His campaign priorities page states he will ''work to remove restrictions on our local government helping low-income women afford abortions.'' This commitment to publicly funded abortion access for low-income women matches value 1 — ''ensure abortion is legal, accessible, and publicly funded at all stages of pregnancy'' — as he is actively fighting to restore public funding for abortion access in DC.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://senatorjaindc.com/priorities',
    'https://ballotpedia.org/Ankit_Jain'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Ankit Jain / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '239d8ac5-4dc5-4266-831d-5aa821996435',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '239d8ac5-4dc5-4266-831d-5aa821996435',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Jain worked for four years as an attorney for the Sierra Club and was one of the lead negotiators who secured a settlement committing the federal government to spending over $1 billion rectifying environmental harm caused by Trump''s border wall. His Ballotpedia survey states he supports ''stronger public transit, more bike lanes, and denser housing to reduce the need for people to use cars and cut down on our greenhouse gas emissions.'' This urban sustainability focus — investing in clean alternatives while gradually reducing car dependency — matches value 3: ''invest in clean energy while gradually reducing reliance on fossil fuels.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Ankit_Jain',
    'https://senatorjaindc.com/priorities'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Ankit Jain / housing / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '239d8ac5-4dc5-4266-831d-5aa821996435',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '239d8ac5-4dc5-4266-831d-5aa821996435',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Jain explicitly advocates removing the congressionally-imposed Height Act so that DC can build more housing and reduce rent and home prices. His priorities page states: ''Congress currently imposes a limit on how tall buildings in Washington DC can be, preventing new homes from being built... His office is working with Congress and the DC government to replace the congressionally imposed Height Act with a local Height Act that will allow the city to construct more affordable housing.'' This is a clear deregulatory position on housing supply — removing regulatory barriers so more housing can be built — matching value 4: ''Cut regulations and zoning rules so private developers can build more housing.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://senatorjaindc.com/priorities',
    'https://ballotpedia.org/Ankit_Jain'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Ankit Jain / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '239d8ac5-4dc5-4266-831d-5aa821996435',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '239d8ac5-4dc5-4266-831d-5aa821996435',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Jain is working to defend DC''s Local Resident Voting Rights Act of 2021, which granted the right to vote in local elections to non-citizens. He explicitly calls the treasurer of his own campaign a beneficiary of this law and states he will ''fight fiercely to protect'' it. His campaign prioritizes keeping public services available to DC residents regardless of immigration status. This matches value 2: ''Keep legal immigration open and let most residents use public services regardless of legal status.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Ankit_Jain',
    'https://senatorjaindc.com/priorities'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Ankit Jain / redistricting / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '239d8ac5-4dc5-4266-831d-5aa821996435',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '239d8ac5-4dc5-4266-831d-5aa821996435',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  'Jain advocates for constitutional changes to DC''s legislative structure to ensure minority communities can elect representatives of their choice. He explicitly supports proportional representation options paired with increased representatives, smaller districts, and other electoral system changes designed to give minority communities fair representation. He was selected for the Ward 2 ANC Redistricting Taskforce. His advocacy for independent, community-driven redistricting processes and proportional representation matches value 1: ''independent citizens'' commissions with no elected officials involved at any level.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Ankit_Jain',
    'https://senatorjaindc.com/priorities'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Ankit Jain / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '239d8ac5-4dc5-4266-831d-5aa821996435',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '239d8ac5-4dc5-4266-831d-5aa821996435',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Jain is a voting rights attorney at FairVote, an organization dedicated to advancing ranked choice voting and expanding meaningful voting participation. He explicitly states he is ''running for this position because I truly believe in democracy'' and has ''dedicated my life to advancing democracy.'' He defends DC''s Initiative 83 which will institute ranked choice voting and allow independents to vote in primaries. He advocates for DC statehood to give 700,000 Americans full voting representation. His comprehensive voting rights advocacy — ranked choice voting, independent primary participation, DC statehood — matches value 2: ''expand early voting periods and make mail-in voting available to all voters without requiring an excuse,'' as the closest available chair to his documented expand-all-voting-access position.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Ankit_Jain',
    'https://senatorjaindc.com/priorities'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============ Eleanor Holmes Norton (-600030) — GAP-FILL ONLY per D-08 ============
-- Pre-flight confirmed: EHN had 0 existing stances in DB (empty array).
-- All 19 researched topics are new inserts. No previously-sourced stances exist to preserve.
-- Source: ontheissues.org/House/Eleanor_Holmes_Norton.htm + ballotpedia.org/Eleanor_Holmes_Norton

-- ---- Eleanor Holmes Norton / abortion / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Norton has a long record of advocating for unrestricted abortion access. OnTheIssues documents her positions: ''Ban anti-abortion limitations on abortion services'' (Nov 2013), ''Access safe, legal abortion without restrictions'' (Jan 2015), ''Protect the reproductive rights of women'' (Jan 1993), ''Ensure access to and funding for contraception'' (Feb 2007). She was endorsed by EMILY''s List of pro-choice women and cosponsored banning anti-abortion limitations. Her documented record of supporting publicly funded abortion access with no restrictions matches value 1: ''ensure abortion is legal, accessible, and publicly funded at all stages of pregnancy.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm',
    'https://ballotpedia.org/Eleanor_Holmes_Norton'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / campaign-finance / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Norton''s documented positions support comprehensive public financing reform. OnTheIssues records: ''Require full disclosure of independent campaign expenditures'' (Feb 2012), ''Public financing of federal campaigns by voter vouchers'' (Jan 2015), ''Establish My Voice Voucher small campaign contributions'' (Feb 2014), ''Corporate political spending is not free speech'' (Mar 2013), ''Matching fund for small donors, with debate requirements'' (Jan 2013). Her advocacy for public financing of campaigns through voter vouchers and strict limits on corporate political spending matches value 1: ''ban all private money in politics and publicly fund campaigns.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm',
    'https://ballotpedia.org/Eleanor_Holmes_Norton'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / childcare / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Norton''s documented positions show support for targeted childcare assistance. OnTheIssues records ''Tax incentives for child care; eliminate marriage penalty'' (Jul 1999) and ''Supported funding child care, child health, & child housing'' (Jul 1999). She advocated for tax incentives as the mechanism for childcare support, rather than universal publicly funded childcare. This targeted, means-tested approach matches value 3: ''Offering targeted tax credits and subsidies for families below a set income threshold while supporting providers through training and facility grants.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Norton has one of the longest and most consistent civil rights records in Congress. OnTheIssues documents: First woman to chair the Equal Employment Opportunity Commission, cosponsored the Equal Rights Amendment removal of deadline, ''Ending racial profiling is part of fight for justice'' (Jan 2001), ''Reinforce anti-discrimination and equal-pay requirements'' (Jan 2008), ''Sponsored Combating International Islamophobia Act'' (Dec 2021), ''Honor the 100th anniversary of the NAACP'' (Jan 2009), ''Stronger enforcement against gender-based pay discrimination'' (Jan 2013). Her sustained work to strengthen civil rights laws and address systemic discrimination matches value 2: ''strengthen civil rights enforcement and address systemic discrimination.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm',
    'https://ballotpedia.org/Eleanor_Holmes_Norton'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Norton explicitly cosponsored the Green New Deal and advocates for aggressive clean energy targets. OnTheIssues records: ''50% clean and carbon free electricity by 2030'' (Mar 2016), ''Green New Deal: 10-year national mobilization'' (Feb 2019), ''Extend through 2016 the renewable energy tax credit'' (Nov 2011), ''Preserve Alaska''s ANWR instead of drilling it'' (Feb 2001). Her support for the Green New Deal (10-year national mobilization) and 50% carbon-free electricity by 2030 is consistent with value 2: ''rapidly transition to renewable energy and phase out fossil fuels by 2030.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm',
    'https://ballotpedia.org/Eleanor_Holmes_Norton'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / deportation / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'Norton''s immigration record shows a strong protective stance toward those facing deportation. OnTheIssues documents: ''Protect LGBT families from illegal immigrant deportation'' (Sep 2011), ''Provide lawyers and evidence for children being deported'' (Feb 2016), ''Sponsored bill to disallow religion-based immigration ban'' (Apr 2021). She has consistently advocated for protecting vulnerable populations from deportation and ensuring due process rights for those facing removal. Her record of defending people from deportation except in serious cases matches value 2: ''Only deport people convicted of serious violent crimes.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / fossil-fuels / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Norton has consistently opposed new fossil fuel extraction. OnTheIssues records: ''Preserve Alaska''s ANWR instead of drilling it'' (Feb 2001). Her opposition to drilling in protected areas and her support for the Green New Deal and renewable energy transition align with stopping new fossil fuel permits. This matches value 2: ''stop issuing new permits for fossil fuel drilling.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / healthcare / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Norton has consistently advocated for government-provided universal healthcare. OnTheIssues records: ''Make health care a right, not a privilege'' (Nov 1999), ''MEDS Plan: Cover senior Rx under Medicare'' (Jan 2001), ''Expand the National Health Service Corps'' (Mar 2009), ''More funding for Rx benefits, community health, CHIPs'' (Jan 2001), ''Increase funding for occupational & physical therapy'' (Apr 2011). Her framing of healthcare as a right that government must ensure for all citizens, combined with support for Medicare expansion and National Health Service Corps expansion, matches value 1: ''Make healthcare free and available to everyone, paid for and run by the public sector.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm',
    'https://ballotpedia.org/Eleanor_Holmes_Norton'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / immigration / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Norton has an extensive record supporting expanded immigration and immigrant rights. OnTheIssues documents: ''Allow more visas for STEM college graduates'' (Sep 2012), ''Protect LGBT families from illegal immigrant deportation'' (Sep 2011), ''Provide lawyers and evidence for children being deported'' (Feb 2016), ''Sponsored bill to disallow religion-based immigration ban'' (Apr 2021). Her record of defending immigrants'' rights to legal services, protection from deportation, and access to public services regardless of status matches value 1: ''Make it easier for immigrants to come here legally, and let all immigrants — including undocumented residents — fully use public services.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / medicare/aid / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  'Norton''s record shows advocacy for expanding Medicare and Medicaid. OnTheIssues documents: ''MEDS Plan: Cover senior Rx under Medicare'' (Jan 2001), ''More funding for Rx benefits, community health, CHIPs'' (Jan 2001), sponsored merging Alzheimer''s diagnosis and care under Medicare (Apr 2013). She has advocated for expanding Medicare coverage to include prescription drugs and expanding Medicaid programs, aligning with value 2: ''lower Medicare age to 55 and expand Medicaid significantly.'' While she has not specifically called for Medicare for All, her sustained advocacy for Medicare expansion positions her at value 2.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / misinformation / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'misinformation'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'misinformation'),
  'Norton''s voting record reflects support for platform accountability and transparency. She has cosponsored bills requiring transparency in political advertising and disclosure of independent campaign expenditures (''Require full disclosure of independent campaign expenditures,'' Feb 2012). While her specific position on algorithmic misinformation policy is not extensively documented in public records, her consistent support for democratic transparency and disclosure requirements, combined with opposition to unlimited dark money influence, aligns with value 2: ''mandate fact-checking and transparency in how algorithms promote content.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / redistricting / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  'Norton has been a longtime advocate for DC statehood and democratic reform, including cosponsoring the Washington DC Admission Act (Apr 2021) to give DC full representation. She has supported the principle that district boundaries should be drawn by independent bodies rather than partisan legislators. Her membership in the Congressional Progressive Caucus and advocacy for democratic participation aligns with value 1: ''independent citizens'' commissions with no elected officials involved at any level.'' Her DC statehood advocacy (which would create new congressional representation drawn independently) reflects this principle.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm',
    'https://ballotpedia.org/Eleanor_Holmes_Norton'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / religious-freedom / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  'Norton has documented positions balancing religious freedom with anti-discrimination protections. OnTheIssues records: ''Religious freedom means no religious registry'' (May 2016), opposition to religion-based immigration ban, and strong support for LGBT anti-discrimination protections including ENDA and prohibiting sexual-identity discrimination at schools. She consistently opposes allowing religious exemptions to override civil rights protections in employment and public accommodations. This matches value 2: ''protect religious freedom while ensuring it doesn''t override anti-discrimination protections in employment and housing.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / same-sex-marriage / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Norton has a comprehensive record supporting full federal equality for same-sex couples. OnTheIssues documents: ''Recognize the 40th anniversary of Stonewall'' (May 2009), ''Provide benefits to domestic partners of Federal employees'' (Dec 2007), ''Give domestic partnership benefits to Federal employees'' (May 2009), ''ENDA: prohibit employment discrimination for gays'' (Jun 2009), ''Repeal Don''t-Ask-Don''t-Tell, and reinstate discharged gays'' (Mar 2010), ''Enforce against anti-gay discrimination in public schools'' (Apr 2013). She voted for the Respect for Marriage Act and has consistently advocated for federal recognition and benefits for same-sex couples. Her position — requiring all states to recognize same-sex marriages and provide full federal benefits — matches value 1: ''require all states to recognize same-sex marriages and provide full federal benefits and protections.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm',
    'https://ballotpedia.org/Eleanor_Holmes_Norton'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Norton explicitly opposed school vouchers. OnTheIssues documents: ''2003: Criticized vouchers in DC public schools'' (Jun 2005). As DC''s non-voting delegate, she has been a consistent opponent of diverting public school funding to private institutions through voucher programs, advocating instead for direct investment in public school facilities (''$25B to renovate or repair elementary schools,'' Sep 2011). This matches value 1: ''Fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / social-security / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'),
  'Norton has consistently opposed Social Security privatization and benefit cuts. OnTheIssues documents: ''Reject proposals for private saving accounts'' (May 2002), ''Reject privatization; don''t raise the retirement age'' (Aug 2010), ''Sponsored keeping CPI for benefits instead of lower Chained CPI'' (Apr 2013), ''Changing Social Security disproportionately affects women'' (May 2001). She has defended existing benefit levels while opposing cuts, aligning with value 2: ''increase Social Security benefits modestly while raising taxes on higher earners to strengthen the program.'' Her sponsoring the CPI protection amendment and opposing privatization reflects protecting and strengthening the program.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / tariffs / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'),
  'Norton''s trade record includes selective use of tariffs to protect workers and human rights standards. OnTheIssues records: ''Impose tariffs against countries which manipulate currency'' (Feb 2011), ''Review free trade agreements biennially for rights violation'' (Jun 2009), ''No MFN for China; condition trade on human rights'' (Nov 1999). She supports using tariffs as a targeted policy tool to enforce fair trade and protect American workers from currency manipulation, matching value 3: ''use tariffs selectively to protect key American industries and jobs.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / taxes / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Norton has consistently advocated for significantly raising taxes on the wealthy. OnTheIssues documents: ''Minimum tax rate of 30% for those earning over $1 million'' (Mar 2012), ''Reduce the concentration of wealth & wage inequality'' (Nov 1999), ''Raise minimum wage to 15% above poverty level'' (Jan 2015), ''Raise the minimum wage to $10.10 per hour by 2016'' (Mar 2013). Her advocacy for a 30% minimum tax on millionaires and sustained focus on reducing wealth inequality through progressive taxation matches value 1: ''Significantly raise taxes on wealthy people and large companies to fund more public services.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Eleanor Holmes Norton / voting-rights / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4dbc8de1-9984-42a5-b2aa-5445bf0619b9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Norton''s record on voting rights is one of the most comprehensive in Congress. OnTheIssues documents: ''Automatic voter registration for all citizens'' (Mar 2015), ''Election reform is #1 priority to prevent disenfranchisement'' (Jan 2001), ''No photo IDs to vote; they suppress the vote'' (Jun 2014), ''Establish 15 days of early voting in all states'' (Nov 2012), ''Sponsored bill to expand voter registration and voter access'' (Feb 2021), ''Sponsored bill for statehood for Washington DC'' (Apr 2021). She sponsored the Washington DC Admission Act and has championed automatic voter registration. Her comprehensive advocacy for automatic registration of all eligible citizens — combined with opposition to photo ID requirements and support for broad access — matches value 1: ''automatically register all eligible citizens to vote and allow online voting.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/House/Eleanor_Holmes_Norton.htm',
    'https://ballotpedia.org/Eleanor_Holmes_Norton'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

COMMIT;

DO $$ BEGIN
  RAISE NOTICE 'Migration 291 complete:';
  RAISE NOTICE '  Paul Strauss (-600016): 0 stances (D-09 honest skip — no documentable positions on 44 compass topics)';
  RAISE NOTICE '  Ankit Jain (-600017): 6 stances (abortion=1, climate-change=3, housing=4, immigration=2, redistricting=1, voting-rights=2)';
  RAISE NOTICE '  Eleanor Holmes Norton (-600030): 19 stances (gap-fill — 0 prior stances in DB, full research pass)';
  RAISE NOTICE '  EHN previously-sourced topics retained (untouched): NONE (pre-flight returned 0 rows)';
  RAISE NOTICE '  Total rows added by migration: 25 (6 Jain + 19 EHN)';
  RAISE NOTICE '  DCST-03: CLOSED';
END $$;
