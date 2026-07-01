-- Migration 1124: Washington County Commission stances - Pam Treece (District 2) (AUDIT-ONLY)
--
-- Phase 175 (WASH-01). AUDIT-ONLY: NOT registered in the migration ledger.
-- Evidence-only compass stances (CHAIRS model). 100% cited; reasoning + sources
-- per stance. Honest blanks where no county-level record. No defaulted values.
-- Judicial topics skipped. topic_id resolved LIVE by topic_key (is_live=true).
-- politician_id = 0cb0bffc-efea-4e0b-93e0-7a53eae10a42 (external_id -410111, minted by mig 1120).
-- 12 cited stances.

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 3, 'Treece championed shelter expansion (Metro SHS, the CATT center, more shelter beds) while negotiating good-neighbor agreements at shelter sites - supporting enforcement only when adequate shelter options exist and pairing it with service referrals, not pure decriminalization or pure enforcement.', ARRAY['https://www.pamforwashingtoncounty.com/priorities/','https://hillsboroherald.com/nafisa-fai-jenny-kamprath-and-pam-treece-square-off-in-town-hall-event-video-coverage-2/']::text[]),
    ('homelessness-response'::text, 3, 'Treece championed the CATT ($63M behavioral-health and addiction treatment center in Beaverton), expanded shelter capacity through SHS, and backed wraparound outreach and mental-health services alongside public-safety co-responders - a balanced invest-in-services-with-reasonable-enforcement posture.', ARRAY['https://www.washingtoncountyor.gov/behavioral-health/center-addictions-triage-treatment','https://www.pamforwashingtoncounty.com/priorities/']::text[]),
    ('housing'::text, 3, 'Treece led creation of thousands of affordable homes (The Opal via Metro bond and SHS revenue), championed preserving existing affordable units, and works through public-private partnerships and targeted subsidy rather than rent caps or public housing construction.', ARRAY['https://www.washingtoncountyor.gov/housing/news/2024/04/10/opal-apartments-opens-cedar-mills-55-community','https://www.pamforwashingtoncounty.com/priorities/']::text[]),
    ('economic-development'::text, 4, 'Treece frames the county as the economic engine of the state, prioritizes manufacturing and high-wage job recruitment to Hillsboro, testified for SB4 (CHIPS Act industrial-land UGB expansion for semiconductors), and is endorsed by the Washington County Chamber PAC and Phil Knight - actively competing for major employers with significant infrastructure investment.', ARRAY['https://hillsboroherald.com/herald-endorses-nafisa-fai-over-pam-treece-washington-county/','https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/SB4']::text[]),
    ('growth-and-development'::text, 3, 'Treece said she would work with Metro and cities to strike the right balance on UGB expansion, supports infrastructure investment ahead of growth, and her SB4 testimony sought limits on governor authority and a meaningful-need criterion before expanding onto prime farmland - cautious pro-growth, not deregulation.', ARRAY['https://www.opb.org/article/2026/05/07/growth-immigration-key-factors-in-race-for-washington-county-chair/','https://hillsboroherald.com/herald-endorses-nafisa-fai-over-pam-treece-washington-county/']::text[]),
    ('public-safety-approach'::text, 3, 'Treece backed both 2025 public-safety levies (Measures 34-345/34-346) to maintain staffing while championing mental-health crisis co-responders through CATT and opposing defunding - maintaining current funding while adding dedicated crisis response.', ARRAY['https://www.washingtoncountyor.gov/cao/measure-34-346-proposed-local-option-levy-2025','https://www.pamforwashingtoncounty.com/priorities/']::text[]),
    ('local-immigration'::text, 2, 'At the November 2025 board meeting Treece called ICE activity horrific, voted to declare a state of emergency and allocate $200,000 for immigration services, pledged to aggressively oppose enforcement while acknowledging the Supremacy Clause, and supports Oregon sanctuary law, legal aid and know-your-rights trainings - court-ordered compliance only, protecting residents.', ARRAY['https://www.opb.org/article/2025/11/05/washington-county-emergency-increased-ice-activity/','https://beavertonvalleytimes.com/2025/11/04/washington-county-declares-states-of-emergency-over-ice-snap-concerns/']::text[]),
    ('civil-rights'::text, 2, 'Treece led the 2020 Racial Equity Resolution establishing the county Equity Office, Leadership Equity Council and Communities of Color Advisory Board, co-chairs ACRE, and defended county DEI policy against federal funding threats in 2025 - actively strengthening civil-rights enforcement.', ARRAY['https://forestgrovenewstimes.com/2025/06/27/washington-county-dei-policy-stands-despite-federal-funding-concerns/','https://hillsboroherald.com/nafisa-fai-jenny-kamprath-and-pam-treece-square-off-in-town-hall-event-video-coverage-2/']::text[]),
    ('healthcare'::text, 3, 'Treece testified for SB 610 to fix behavioral-health funding-formula inequities and championed CATT (substance-use and mental-health treatment for vulnerable residents), targeting expanded county-funded treatment access for those who cannot afford care rather than broad insurance overhaul.', ARRAY['https://olis.oregonlegislature.gov/liz/2025R1/Downloads/PublicTestimonyDocument/137830','https://www.washingtoncountyor.gov/behavioral-health/center-addictions-triage-treatment']::text[]),
    ('childcare'::text, 3, 'Treece promoted the ARPA-funded West Side Works program connecting Beaverton childcare businesses with PCC Early Childhood Education students and covering wages for the first 300 hours - targeted public subsidy for the childcare workforce and providers, not universal nor purely private-market.', ARRAY['https://www.washingtoncountyor.gov/home/news/2023/06/05/west-side-works-launches-new-workforce-program-connecting-beaverton-childcare-businesses-with-early-education-pcc-students']::text[]),
    ('data-centers'::text, 3, 'Treece testified for SB4 (Oregon CHIPS Act) semiconductor industrial land but insisted on meaningful need-criteria, time limits on governor authority, and caution before expanding onto prime farmland - allowing development with impact assessment and conditions rather than a moratorium or open-door incentives.', ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/SB4','https://hillsboroherald.com/senate-bill-1586-definitions-assure-mega-ai-data-centers-on-farm-land-so-who-is-supporting-this-bill/']::text[]),
    ('taxes'::text, 3, 'Treece campaigns on being an effective steward of tax dollars and backed the 2025 public-safety replacement levy (a modest 66 cents/$1000 increase) but has not proposed general tax increases or cuts - emphasizing stability and careful management of the existing budget.', ARRAY['https://www.washingtoncountyor.gov/cao/measure-34-346-proposed-local-option-levy-2025','https://hillsboroherald.com/nafisa-fai-jenny-kamprath-and-pam-treece-square-off-in-town-hall-event-video-coverage-2/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '0cb0bffc-efea-4e0b-93e0-7a53eae10a42'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '0cb0bffc-efea-4e0b-93e0-7a53eae10a42'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
