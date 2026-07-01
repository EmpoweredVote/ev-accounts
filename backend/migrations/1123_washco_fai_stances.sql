-- Migration 1123: Washington County Commission stances - Nafisa Fai (District 1) (AUDIT-ONLY)
--
-- Phase 175 (WASH-01). AUDIT-ONLY: NOT registered in the migration ledger.
-- Evidence-only compass stances (CHAIRS model - value is the discrete position
-- the evidence matches, not a polarity). 100% cited; every stance carries
-- reasoning + source URL(s). Topics with no county-level record are honest
-- blanks (absent). No defaulted values. Judicial topics skipped. topic_id
-- resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = a1fe6f71-0d44-4c85-957f-06ffb6a4f825 (external_id -410110, minted by mig 1120).
-- 13 cited stances.

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 3, 'Fai worked to close two District 1 encampments through housing placements, eviction prevention and mental-health/addiction service linkage rather than criminalization, and supported the county 2023 camping ordinance that allows enforcement only after shelter options are offered.', ARRAY['https://washcodems.org/2026/04/18/nafisa-fai-washington-county-commissioner-county-chair-candidate-interview/','https://www.washingtoncountyor.gov/housing/news/2023/07/18/regulations-public-camping-adopted-board-county-commissioners']::text[]),
    ('homelessness-response'::text, 2, 'Fai led construction of the CATT sobering and treatment center (86 beds), championed Metro Supportive Housing Services funding, and closed encampments via shelter-plus-services outreach - expanding shelter capacity and services as the primary strategy, with enforcement secondary.', ARRAY['https://washcodems.org/2026/04/18/nafisa-fai-washington-county-commissioner-county-chair-candidate-interview/','https://www.nafisaforwashingtoncounty.com/']::text[]),
    ('housing'::text, 3, 'Fai credits her first term with 1,200+ affordable units added and advocates fast-tracking permits, converting public land to affordable development, and first-time-buyer down-payment assistance - targeted public subsidy and streamlined permitting, not rent caps or direct public construction.', ARRAY['https://beavertonvalleytimes.com/2024/04/30/candidate-qa-washington-county-commission-candidates-talk-key-policy-issues/','https://www.nafisaforwashingtoncounty.com/']::text[]),
    ('transportation-priorities'::text, 2, 'Fai served as NACo Transportation Policy Steering Committee Vice Chair and championed the Allen Boulevard Complete Street plan, calling for safer roads and sidewalks, expanded bus routes and improved biking/walkability alongside road capacity - equal investment in roads and multimodal.', ARRAY['https://www.washingtoncountyor.gov/bcc/news/2023/08/29/commissioner-fai-appointed-national-leadership-position-transportation','https://beavertonvalleytimes.com/2024/04/30/candidate-qa-washington-county-commission-candidates-talk-key-policy-issues/']::text[]),
    ('public-safety-approach'::text, 3, 'Fai calls for community safety teams of mental-health professionals, medics and peer responders to handle crisis calls - not defunding police, but adding unarmed co-responder capacity alongside current law enforcement, and supported the county public-safety levy.', ARRAY['https://beavertonvalleytimes.com/2026/02/17/opinion-fais-approach-to-public-safety-gets-it-right/','https://washcodems.org/2026/04/18/nafisa-fai-washington-county-commissioner-county-chair-candidate-interview/']::text[]),
    ('local-immigration'::text, 1, 'Fai publicly opposed ICE enforcement in Washington County, called for the November 2025 state of emergency (unanimously approved), demanded a detainee release, championed Oregon sanctuary protections and proposed sanctuary amendment language, stating ICE has no place in our neighborhoods - refusing cooperation with federal immigration enforcement.', ARRAY['https://www.washingtoncountyor.gov/bcc/news/2025/11/04/washington-county-declares-state-emergency-response-federal-actions','https://katu.com/news/local/washington-county-leaders-unite-against-ice-activity-and-policy-changes']::text[]),
    ('deportation'::text, 2, 'Fai called ICE arrests racist, arbitrary and violent, backed the emergency declaration against the enforcement surge, and advocated protecting long-term residents from removal - opposing broad enforcement sweeps while not calling for removals of serious violent offenders to stop.', ARRAY['https://www.opb.org/article/2025/10/31/washington-county-leaders-callout-ice-arrests/','https://hillsboronewstimes.com/2025/11/04/washington-county-declares-states-of-emergency-over-ice-snap-concerns/']::text[]),
    ('data-centers'::text, 1, 'Fai supports a temporary moratorium on new data-center construction to protect agricultural land while the county develops a deliberate siting policy, criticizing the $120-128M/year in property-tax abatements and opposing expansion onto prime farmland.', ARRAY['https://alohafreepress.substack.com/p/three-washington-county-candidates','https://www.nafisaforwashingtoncounty.com/']::text[]),
    ('climate-change'::text, 3, 'Fai championed Washington County first Climate Action Plan, calls for a countywide Climate Action Task Force, clean-energy investment and expanded tree canopy, and is listed in the Center for Climate Integrity Leaders Network - proactive clean-energy investment and resilience rather than emergency bans.', ARRAY['https://climateintegrity.org/projects/leaders-network/nafisa-fai','https://www.nafisaforwashingtoncounty.com/']::text[]),
    ('local-environment'::text, 2, 'Fai calls for protecting agricultural land from data-center and other development, expanding tree canopy and green space, and opposes converting farmland - strictly protecting existing environmental/agricultural land and requiring developers to offset impacts.', ARRAY['https://hillsboronewstimes.com/2026/04/22/opinion-where-we-grow-matters-vote-nafisa-fai-for-washington-county-chair/','https://www.nafisaforwashingtoncounty.com/']::text[]),
    ('growth-and-development'::text, 3, 'Fai advocates building housing and infrastructure proactively while protecting farmland and managing where growth goes - fast-track permitting for affordable development paired with a data-center moratorium and farmland protection (invest in infrastructure ahead of responsible growth).', ARRAY['https://washcodems.org/2026/04/18/nafisa-fai-washington-county-commissioner-county-chair-candidate-interview/','https://alohafreepress.substack.com/p/three-washington-county-candidates']::text[]),
    ('economic-development'::text, 3, 'Fai supports targeted recruitment of businesses creating high-quality jobs, green-job programs and workforce training with community-benefit requirements, while opposing the current data-center tax-abatement regime - targeted incentives with conditions, not maximum-subsidy competition.', ARRAY['https://alohafreepress.substack.com/p/three-washington-county-candidates','https://www.nafisaforwashingtoncounty.com/']::text[]),
    ('civil-rights'::text, 2, 'Fai, the county first Black and first Muslim commissioner, fought to keep Washington County DEI equity resolution when the federal administration pressured its removal in 2025 and proposed explicit sanctuary language - actively strengthening civil-rights work and pushing back on systemic discrimination.', ARRAY['https://hillsboroherald.com/washington-county-rewrites-equity-policy-despite-significant-public-outcry/','https://www.opb.org/article/2025/07/23/washington-county-new-policy-comply-trump-dei-mandates-access-opportunity/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'a1fe6f71-0d44-4c85-957f-06ffb6a4f825'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT 'a1fe6f71-0d44-4c85-957f-06ffb6a4f825'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
