-- Migration 1099: City of North Las Vegas stances - Richard Cherchio (Council Member, Ward 4) (AUDIT-ONLY)
--
-- Phase 164 (CLARK-04). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1093. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- city-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 806dbfb2-3e81-4d76-bd04-085bc523b76a (external_id -3207005, minted by mig 1093).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('housing'::text, 3, 'In May 24, 2019 Las Vegas Review-Journal candidate coverage, Cherchio said "an affordable housing shortage is a reality the city has to face" and that while he does not want dense developments next to existing single-family homes, he "would support a variety of housing options to cater to young people moving to the city and older people considering downsizing." Supporting a range of housing options to address affordability (rather than building public housing, imposing rent caps, or staying out) matches the targeted-help chair.', ARRAY['https://www.reviewjournal.com/news/politics-and-government/candidates-spar-on-housing-density-in-north-las-vegas-race-1671997/']::text[]),
    ('residential-zoning'::text, 3, 'Per the May 24, 2019 Review-Journal, Cherchio said he does not want dense developments placed around existing single-family neighborhoods but would support a variety of housing options for newcomers and downsizing seniors, citing developments like the 1,200-home Deer Springs/Losee project near the VA Medical Center. Protecting most existing single-family areas while allowing added density in targeted/corridor locations matches chair 3.', ARRAY['https://www.reviewjournal.com/news/politics-and-government/candidates-spar-on-housing-density-in-north-las-vegas-race-1671997/']::text[]),
    ('public-safety-approach'::text, 3, 'As Mayor Pro Tem, on May 25, 2022, Cherchio championed the new North Las Vegas police/community facility, emphasizing community policing: "We''ve always promoted and believed in community policing where we have an opportunity to get in with the neighbors... and them have access to us as well... We are not separate and distinct; we are part of a bigger community." His campaign site also lists adding more police and firefighters. This supports maintaining/growing police funding while integrating community-facing engagement.', ARRAY['https://www.reviewjournal.com/local/north-las-vegas/north-las-vegas-building-new-police-station-2582261/','https://richardcherchio4nlv.com/']::text[]),
    ('taxes'::text, 4, 'During the 2011 NLV budget crisis (Las Vegas Sun, May 28, 2011), Cherchio opposed a property-tax increase that police/firefighter unions proposed to cover salaries, calling the demand "greedy and unreasonable" and warning that letting public-safety spending dominate would let "all of the other services we provide - clean parks, code enforcement, working streetlights - fall by the wayside." His campaign site reiterates he helped add police/firefighters "without tax increases" and erased a deficit. Consistent opposition to raising taxes matches chair 4.', ARRAY['https://lasvegassun.com/news/2011/may/28/unions-speaking-loud-nlv-race/','https://richardcherchio4nlv.com/']::text[]),
    ('economic-development'::text, 3, 'On his campaign site, Cherchio states he "supported the establishment of a 137-acre Job Creation Zone on Pecos, aimed at providing essential services locally and creating jobs," and advocated attracting businesses (e.g., family sit-down restaurants along Craig Road) to diversify the city''s economy. Backing a targeted, jobs-focused development zone tied to local jobs/services matches chair 3 rather than blanket maximum incentives.', ARRAY['https://richardcherchio4nlv.com/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '806dbfb2-3e81-4d76-bd04-085bc523b76a'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '806dbfb2-3e81-4d76-bd04-085bc523b76a'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
