-- Migration 1126: Washington County Commission stances - Jerry Willey (District 4) (AUDIT-ONLY)
--
-- Phase 175 (WASH-01). AUDIT-ONLY: NOT registered in the migration ledger.
-- Evidence-only compass stances (CHAIRS model). 100% cited; reasoning + sources
-- per stance. Honest blanks where no record. No defaulted values. Judicial topics
-- skipped. topic_id resolved LIVE by topic_key (is_live=true). Includes his
-- documented Hillsboro mayoral record as evidence.
-- politician_id = f010b78a-9050-4bba-baed-0070037cd2da (external_id -410113, minted by mig 1120).
-- 11 cited stances.

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('economic-development'::text, 4, 'As Hillsboro Mayor, Willey championed Intel''s $100 billion Strategic Investment Program agreement (calling Hillsboro a global center for high-tech manufacturing jobs), pushed the county to hire its first economic-development director, and backed the Hillsboro Technology Park UGB expansion for semiconductors - actively competing for major employers with infrastructure and incentive support.', ARRAY['https://beavertonvalleytimes.com/2014/08/14/officials-see-intel-pledge-as-legacy/','https://hillsboronewstimes.com/2022/05/10/washco-commissioner-willey-is-coasting-to-election-day/']::text[]),
    ('growth-and-development'::text, 4, 'Willey led the groundbreaking for South Hillsboro (1,400 acres, 8,000 homes, $450M in development-funded infrastructure) as mayor, backed the Hillsboro Technology Park UGB expansion, and called for ending hidden fees and red tape that are barriers to growth - streamlining permitting and actively recruiting development.', ARRAY['https://hillsboronewstimes.com/2022/05/10/washco-commissioner-willey-is-coasting-to-election-day/','https://bikeportland.org/2012/11/16/hillsboro-mayor-pushes-massive-new-westside-freeway-project-80215']::text[]),
    ('transportation-priorities'::text, 4, 'As Hillsboro Mayor, Willey drafted legislation to fund a feasibility study for the Westside Transportation Corridor - a new freeway alternative to I-5/I-205 - framing it as a congestion and economic-development necessity; his primary orientation is road capacity for the driving majority.', ARRAY['https://bikeportland.org/2012/11/16/hillsboro-mayor-pushes-massive-new-westside-freeway-project-80215']::text[]),
    ('public-safety-approach'::text, 4, 'Willey donated $5,000 to DA Kevin Barton''s re-election, agreeing with his prosecution philosophy and saying the public should feel safe and know that if you break the law you will be arrested and prosecuted, and backed the public-safety levy funding expanded jail operations and prosecution - increasing police/prosecution capacity.', ARRAY['https://hillsboronewstimes.com/2022/05/10/washco-commissioner-willey-is-coasting-to-election-day/','https://www.washingtoncountyor.gov/cao/2025-public-safety-levy-information']::text[]),
    ('homelessness-response'::text, 3, 'Willey chairs the Metro Supportive Housing Services Regional Policy Oversight Committee and supported Hillsboro''s 75-bed low-barrier shelter offering services and pathways, with county priorities including behavioral-healthcare access - investing in outreach, shelter and services while enforcing reasonable public-space rules.', ARRAY['https://www.oregonmetro.gov/committees/supportive-housing-services-regional-policy-oversight-committee','https://katu.com/news/local/hillsboro-to-open-year-round-homeless-shelter-with-75-capacity-pets-welcome-homelessness-oregon-portland-suburbs-baseline-bonamici-suzanne-project-funding']::text[]),
    ('homelessness'::text, 3, 'Willey supported the $17M Hillsboro shelter funded by the Metro SHS measure and chairs the SHS oversight committee governing shelter-plus-services programs; he has advocated neither full decriminalization nor criminalization of camping - enforcement conditioned on shelter availability with citations diverting to services.', ARRAY['https://katu.com/news/local/hillsboro-to-open-year-round-homeless-shelter-with-75-capacity-pets-welcome-homelessness-oregon-portland-suburbs-baseline-bonamici-suzanne-project-funding','https://www.oregonmetro.gov/committees/supportive-housing-services-regional-policy-oversight-committee']::text[]),
    ('housing'::text, 3, 'Willey serves on the Washington County Housing Authority Board and calls for expanding affordable residential inventory with smarter land-use policies, supporting implementation of the Metro regional affordable-housing bond - targeted subsidy and policy engagement rather than public construction or rent control.', ARRAY['https://hillsboronewstimes.com/2022/05/10/washco-commissioner-willey-is-coasting-to-election-day/','https://washco.granicus.com/boards/w/b7ebe19be8d33a24/boards/14832']::text[]),
    ('taxes'::text, 4, 'Willey campaigned to stop tax increases, hidden fees and red tape that are barriers to growth, informed by his CPA/business background; while he supported the voter-authorized public-safety levy, his general orientation is cutting barriers rather than raising taxes to expand services.', ARRAY['https://hillsboronewstimes.com/2022/05/10/washco-commissioner-willey-is-coasting-to-election-day/']::text[]),
    ('civil-rights'::text, 3, 'Willey voted for the revised Access and Opportunity resolution that replaced DEI language to protect $135M+ in federal funding, citing legal counsel, and declined a sanctuary-language amendment on legal-risk grounds; the vote maintained existing county programs while complying with new federal requirements - maintaining current civil-rights protections while promoting equal opportunity.', ARRAY['https://hillsboroherald.com/washington-county-rewrites-equity-policy-despite-significant-public-outcry/']::text[]),
    ('local-immigration'::text, 3, 'Willey voted against adding sanctuary-state language to the county DEI resolution on legal/funding-risk grounds (not enthusiasm for enforcement); county law enforcement has stated it does not collaborate with ICE or ask immigration status - following federal law as required without using county resources for proactive enforcement.', ARRAY['https://hillsboroherald.com/washington-county-rewrites-equity-policy-despite-significant-public-outcry/','https://katu.com/news/local/washington-county-law-enforcement-clarifies-stance-on-federal-immigration-involvement-forest-grove-hillsboro-beaverton-salem-woodburn-marion-ice']::text[]),
    ('jail-capacity'::text, 4, 'Willey endorsed DA Barton''s prosecutorial philosophy and backed the public-safety levy funding jail operations, crime investigation and enforcement alongside mental-health crisis teams - willing to invest in jail/detention capacity to address crime.', ARRAY['https://hillsboronewstimes.com/2022/05/10/washco-commissioner-willey-is-coasting-to-election-day/','https://www.washingtoncountyor.gov/sheriff/news/2025/11/05/washington-county-voters-show-strong-support-public-safety-levy']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'f010b78a-9050-4bba-baed-0070037cd2da'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT 'f010b78a-9050-4bba-baed-0070037cd2da'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
