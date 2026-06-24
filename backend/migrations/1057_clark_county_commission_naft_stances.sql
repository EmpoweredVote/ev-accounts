-- Migration 1057: Clark County Commission stances - Michael Naft (District A, Chair) (AUDIT-ONLY)
--
-- Phase 161 (CLARK-01). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1055. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- county-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 033cf882-aa31-4f1f-b9e0-3b601da1703a (external_id -3200301, minted by mig 1055).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 4, 'Nov 5, 2024: voted yes on Clark County''s ordinance banning sleeping in public rights-of-way (enforceable only when shelter beds are available, 10-day max penalty); said he was uncomfortable moving forward but called it a very necessary time to act while continuing to fund shelter and services.', ARRAY['https://lasvegassun.com/news/2024/nov/06/clark-county-commissioners-approve-ban-on-sleeping/']::text[]),
    ('homelessness-response'::text, 3, 'Alongside his Nov 2024 vote for the shelter-bed-contingent camping ban, Naft pledged to keep advocating for emergency housing, social services, wraparound programs and mental-health/substance-abuse resources to address root causes (enforcement paired with outreach and services).', ARRAY['https://lasvegassun.com/news/2024/nov/06/clark-county-commissioners-approve-ban-on-sleeping/','https://news3lv.com/news/local/clark-county-ramps-up-efforts-to-address-homelessness-amid-resident-complaints-on-safety']::text[]),
    ('housing'::text, 3, 'As Chair, championed the Welcome Home Community Housing Fund; on Feb 17, 2026 the Board approved $20M in targeted subsidies for 10 projects converting 500+ units to 50% AMI and below, with Naft saying the county is targeting those who are struggling the most to find an affordable place to live (targeted public subsidy).', ARRAY['https://www.clarkcountynv.gov/news/021725-bcc-approves-additional-chf-funding','https://www.fox5vegas.com/2026/02/18/20-million-clark-county-funding-approved-toward-attainable-housing/']::text[]),
    ('data-centers'::text, 3, 'June 17, 2026: made the motion to approve Switch''s LAS 19 data center expansion (unanimous), citing the county''s adopted sustainability point system (6.5/7), near-zero-water dry cooling, the SNWA evaporative-cooling ban and 100% renewable supply, explicitly noting this is not applicable to every data center (conditional approval tied to impact/sustainability standards).', ARRAY['https://www.fox5vegas.com/2026/06/18/clark-county-approves-switch-data-center-project-southwest-valley-after-public-opposition/','https://lasvegassun.com/news/2026/jun/23/switch-wins-las-vegas-expansion-approval-even-as-d/']::text[]),
    ('transportation-priorities'::text, 2, 'Brought the 2022 Safe Sidewalk ordinance (detached sidewalks on future 60ft+ roadways), expanded school crossing guards in 2024, and backed the Maryland Parkway Bus Rapid Transit project ($150M federal grant) adding wider sidewalks and pedestrian crossings (roads plus multimodal/transit and pedestrian infrastructure).', ARRAY['https://newdealleaders.org/leader/michael-naft/','https://nevadacurrent.com/2024/08/13/buttigieg-marks-groundbreaking-on-maryland-parkway-transit-project/']::text[]),
    ('public-safety-approach'::text, 4, 'States he is committed to ensuring first responders have the tools they need to protect us, supported funding ShotSpotter gunfire-detection technology, and touts endorsements from law-enforcement organizations representing 4,000+ first responders (favoring increased police resources/equipment).', ARRAY['https://michaelnaft.com/goals/']::text[]),
    ('growth-and-development'::text, 3, 'Advocates sustainable growth where future development should compliment our community, balancing innovative development with what is appropriate for existing neighborhoods and requiring builders to consider landscaping, architectural enhancements and public safety (proactive planning with standards).', ARRAY['https://michaelnaft.com/goals/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '033cf882-aa31-4f1f-b9e0-3b601da1703a'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '033cf882-aa31-4f1f-b9e0-3b601da1703a'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
