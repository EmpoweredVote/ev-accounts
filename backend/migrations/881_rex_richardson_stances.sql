-- Migration 881: Rex Richardson (Mayor of Long Beach, -200813) — evidence-only compass stances
-- Phase 142 Wave 4. AUDIT-ONLY (raw SQL apply; NOT registered in schema_migrations; counter stays 879).
-- 19 evidence-backed placements; 100% citation. Applied 2026-06-19.

BEGIN;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, d.value
FROM (VALUES
  ('housing',2),('homelessness',2),('homelessness-response',1),('rent-regulation',3),
  ('residential-zoning',4),('growth-and-development',4),('economic-development',4),
  ('climate-change',2),('fossil-fuels',2),('local-environment',2),('transportation-priorities',1),
  ('public-safety-approach',2),('jail-capacity',2),('local-immigration',1),('immigration',1),
  ('abortion',1),('healthcare',2),('civil-rights',1),('campaign-finance',2)
) AS d(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = -200813
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, d.reasoning, d.sources::text[]
FROM (VALUES
  ('housing', $$Backs a $4B housing bond, transit-oriented development, voucher assistance and public funding to expand affordable units rather than leaving it to the market.$$, ARRAY['https://forthe.org/richardson-questionnaire-2022/','https://www.longbeach.gov/mayor/press-releases/mayor-rex-richardson-shares-progress-update-on-the-opportunity-beach-agenda-100-day-plan-publishes-detailed-report/']),
  ('homelessness', $$Declared a homelessness state of emergency and invests in shelter/services, saying 'we cannot simply prosecute our way out of this problem.'$$, ARRAY['https://forthe.org/richardson-questionnaire-2022/','https://patch.com/california/longbeach-ca/long-beach-declare-state-emergency-homelessness']),
  ('homelessness-response', $$Champions a Housing First strategy paired with mental health and substance-use services as the city's primary approach.$$, ARRAY['https://forthe.org/richardson-questionnaire-2022/','https://www.joinrexrichardson.com/housing']),
  ('rent-regulation', $$Voted for tenant relocation/eviction protections but stated he opposes additional rent control measures.$$, ARRAY['https://lbpost.com/news/long-beach-mayoral-candidates-stake-out-positions-on-rent-control-queen-mary-in-east-long-beach-debate/','https://lbforward.org/news/long-beach-approves-more-protections-for-tenants-aligning-with-state-law/']),
  ('residential-zoning', $$His administration implements SB9 two-unit development on single-family lots and broad ADU expansion, top per-capita ADU producer in California.$$, ARRAY['https://www.longbeach.gov/press-releases/city-of-long-beach-updating-regulations-to--better-support-development-of-secondary-and-accessory-dwelling-units/','https://forthe.org/richardson-questionnaire-2022/']),
  ('growth-and-development', $$Pledges to 'cut red tape to attract more businesses and investment' and created a 'Grow Long Beach' team and AnchorLB strategy.$$, ARRAY['https://forthe.org/richardson-questionnaire-2022/','https://www.verdexchange.org/vxnews/long-beach-mayor-rex-richardson-on-prioritizing-economic-opportunity']),
  ('economic-development', $$Launched Acceler8 by '28 and AnchorLB public-private partnerships and a business-recruitment team to aggressively attract employers.$$, ARRAY['https://www.longbeach.gov/mayor/news/long-beach-mayor-rex-richardson-hosts-state-of-the-city-address-january-13-2026/','https://forthe.org/richardson-questionnaire-2022/']),
  ('climate-change', $$Implements the city Climate Action and Adaptation Plan and requires net-zero carbon for new buildings by 2030 with all-electric hookups.$$, ARRAY['https://www.longbeach.gov/mayor/mayor-priorities/climate-action-and-sustainability/','https://forthe.org/richardson-questionnaire-2022/']),
  ('fossil-fuels', $$Committed to ending Long Beach's reliance on local oil revenue by 2030 and co-authored SB 1425 to fund decommissioning of oil operations.$$, ARRAY['https://www.longbeach.gov/mayor/mayor-priorities/climate-action-and-sustainability/']),
  ('local-environment', $$Advancing restoration of 150+ acres of Los Cerritos Wetlands and a Westside Promise environmental-justice initiative to cut port-area pollution.$$, ARRAY['https://www.longbeach.gov/mayor/mayor-priorities/climate-action-and-sustainability/','https://www.longbeach.gov/mayor/press-releases/mayor-rex-richardson-convenes-leaders-to-discuss-develompent-of-a-westside-promise-zone-initiative/']),
  ('transportation-priorities', $$Backs fare-free transit, protected bike lanes, sidewalk repair and Vision Zero traffic-calming, prioritizing pedestrian/cycling/transit.$$, ARRAY['https://forthe.org/richardson-questionnaire-2022/','https://www.longbeach.gov/goactivelb/programs/safe-streets-lb/what-is-vision-zero/']),
  ('public-safety-approach', $$Authored the 2020 Framework for Reconciliation that shifted budgeted funds away from policing toward community services and added unarmed safety ambassadors.$$, ARRAY['https://www.lbreport.com/news/jun20/counafrt1.htm','https://forthe.org/richardson-questionnaire-2022/']),
  ('jail-capacity', $$Frames public safety around prevention and services, stating 'we cannot simply prosecute our way out of this problem,' emphasizing diversion over incarceration.$$, ARRAY['https://forthe.org/richardson-questionnaire-2022/']),
  ('local-immigration', $$Championed expansions of the Long Beach Values Act that refuse most ICE detainers, bar city/contractor data-sharing with immigration enforcement, and limit ICE building access.$$, ARRAY['https://laist.com/news/long-beach-will-discipline-city-employees-who-disobey-sanctuary-policies','https://lbpost.com/news/immigration/long-beach-strengthens-its-sanctuary-city-laws-ahead-of-second-trump-term']),
  ('immigration', $$Proposed reserving $5 million for immigrant legal defense and assistance and says the city steps up to support local immigrant families.$$, ARRAY['https://laist.com/news/long-beach-will-discipline-city-employees-who-disobey-sanctuary-policies']),
  ('abortion', $$Endorsed by the Planned Parenthood Advocacy Project for protecting abortion access and spoke at a 'Bans Off Our Bodies' rally.$$, ARRAY['https://www.joinrexrichardson.com/rex_richardson_endorsed_by_planned_parenthood','https://lbpost.com/news/hundreds-gather-in-long-beach-to-rally-for-abortion-rights-in-wake-of-draft-supreme-court-ruling']),
  ('healthcare', $$Established a local mental health bureau in the city health department and backs safe consumption sites and behavioral-health infrastructure.$$, ARRAY['https://forthe.org/richardson-questionnaire-2022/','https://www.longbeach.gov/mayor/press-releases/long-beach-city-council-backs-mayor-rex-richardsons-call-for-support-on-proposition-1/']),
  ('civil-rights', $$Authored and led the city's Racial Equity and Reconciliation Initiative, an equity-driven framework to address systemic racism.$$, ARRAY['https://www.longbeach.gov/press-releases/city-council-unanimously-approves-racial-equity-and-reconciliation-initiative--initial-report/','https://lbpost.com/news/city-council-approves-framework-for-reconciliation-plan-to-address-racial-inequity/']),
  ('campaign-finance', $$Opposes Citizens United, supports campaign finance reform, and returned fossil-fuel-industry donations on principle.$$, ARRAY['https://forthe.org/richardson-questionnaire-2022/'])
) AS d(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = -200813
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
