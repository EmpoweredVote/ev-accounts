-- Migration 1086: City of Henderson stances - Michelle Romero (Mayor) (AUDIT-ONLY)
--
-- Phase 163 (CLARK-03). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1084. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- city-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 494202b1-2cf0-4780-b164-7ae84a1c5185 (external_id -3206001, minted by mig 1084).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 5, 'Mayor Romero championed Henderson''s June 7, 2023 ordinance expanding the definition of public camping and banning it citywide; she called public support "overwhelming" and said it would provide "some level of safety" to business owners and residents. The ordinance is enforcement-backed (warning/arrest escalation), though officers must offer services/shelter first.', ARRAY['https://www.reviewjournal.com/local/henderson/henderson-council-passes-ordinance-outlawing-public-camping-2790502/']::text[]),
    ('homelessness-response'::text, 3, 'Romero backed the 2023 camping ban but framed it as services-first: officers must first inform the person, identify available shelter beds, and direct them to services before any warning or arrest, and she stressed it does not impede organizations/city initiatives from supporting homeless people - an outreach+shelter-then-rules posture, not enforcement-only.', ARRAY['https://www.reviewjournal.com/local/henderson/henderson-council-passes-ordinance-outlawing-public-camping-2790502/']::text[]),
    ('housing'::text, 2, 'In her Nov. 2025 State of the City address Romero stressed Henderson''s "significant housing shortfall" (a 6,000-unit deficit growing toward 40,000), called on state and federal officials to help, and touted city/partner affordable projects (Sunrise Ranch 144 low-income units; Ovation West 389-unit affordable project) - signaling active government intervention on affordability.', ARRAY['https://www.reviewjournal.com/local/henderson/henderson-mayor-touts-new-housing-declining-crime-but-warns-of-local-headwinds-3581185/']::text[]),
    ('growth-and-development'::text, 4, 'Romero''s stated core priority is to "manage the growth of the city," and her Nov. 2025 address celebrated large-scale development as accomplishments: ~$40M in 2025 private investment / ~600 jobs, two new casinos opening 2026, and the Aries (3,000 homes) and Meriden (940 homes) master-planned communities - a pro-development, growth-embracing record.', ARRAY['https://www.reviewjournal.com/local/henderson/henderson-mayor-touts-new-housing-declining-crime-but-warns-of-local-headwinds-3581185/','https://www.cityofhenderson.com/government/mayor-and-city-council/mayor-michelle-romero']::text[]),
    ('public-safety-approach'::text, 5, 'Romero consistently touts traditional policing and funding: her Nov. 2025 address highlighted Police Chief Rader cutting officer vacancies to 5%, reassigning 18 officers to patrol, and a record 46-cadet class, crediting investment in police for crime declines (violent crime down 18%, property crime down 15%).', ARRAY['https://www.reviewjournal.com/local/henderson/henderson-mayor-touts-new-housing-declining-crime-but-warns-of-local-headwinds-3581185/','https://lasvegassun.com/news/2025/nov/13/henderson-mayor-touts-crime-reduction-major-invest/']::text[]),
    ('economic-development'::text, 5, 'Romero''s career and mayoralty center on aggressive incentives: as Redevelopment Agency Manager she negotiated tax-increment Owner Participation Agreements for Cadence, Union Village, and Henderson Hospital, and as mayor she touts incentive-driven private investment and job creation as headline accomplishments.', ARRAY['https://www.cityofhenderson.com/government/mayor-and-city-council/mayor-michelle-romero','https://www.reviewjournal.com/local/henderson/henderson-mayor-touts-new-housing-declining-crime-but-warns-of-local-headwinds-3581185/']::text[]),
    ('transportation-priorities'::text, 2, 'In her Nov. 2025 State of the City address Romero touted the $172M "Reimagine Boulder Highway" project as a signature city accomplishment - a redesign that adds center-running Bus Rapid Transit, dedicated bike lanes, widened sidewalks, and mid-block pedestrian crossings while reducing car lanes - a clear endorsement of multimodal/transit-oriented investment.', ARRAY['https://www.reviewjournal.com/local/henderson/henderson-mayor-touts-new-housing-declining-crime-but-warns-of-local-headwinds-3581185/','https://www.reviewjournal.com/local/traffic/big-changes-coming-to-boulder-highway-as-safety-project-breaks-ground-3118789/']::text[]),
    ('taxes'::text, 4, 'Romero repeatedly emphasizes fiscal restraint, touting that Henderson maintains "the highest bond ratings and lowest tax rate" among major Nevada cities alongside balanced budgets and strong reserves (Nov. 2025 address).', ARRAY['https://www.reviewjournal.com/local/henderson/henderson-mayor-touts-new-housing-declining-crime-but-warns-of-local-headwinds-3581185/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '494202b1-2cf0-4780-b164-7ae84a1c5185'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '494202b1-2cf0-4780-b164-7ae84a1c5185'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
