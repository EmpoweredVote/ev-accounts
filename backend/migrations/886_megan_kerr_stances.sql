-- Migration 886: Megan Kerr (Long Beach Council D5, 665835) — evidence-only compass stances
-- Phase 142 Wave 4. AUDIT-ONLY (raw SQL; NOT in schema_migrations). 12 placements, 100% citation. 2026-06-19.

BEGIN;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, d.value
FROM (VALUES
  ('public-safety-approach',4),('housing',2),('homelessness-response',2),('homelessness',2),
  ('civil-rights',2),('same-sex-marriage',1),('transportation-priorities',2),('local-environment',2),
  ('climate-change',3),('economic-development',3),('taxes',3),('growth-and-development',3)
) AS d(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665835
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, d.reasoning, d.sources::text[]
FROM (VALUES
  ('public-safety-approach', $$Secured increased Fire Department funding, built a new police training center, added police academy classes, and pushed recruit/lateral incentives to grow LBPD staffing.$$, ARRAY['https://www.megankerr.com/platform','https://www.megankerr.com/accomplishments','https://lbpost.com/news/politics/elections/long-beach-voter-guide-city-council-district-5/']),
  ('housing', $$Advocates a full spectrum of affordable housing and supports inclusionary housing requirements for new development plus partnerships and public funding.$$, ARRAY['https://www.megankerr.com/platform']),
  ('homelessness-response', $$Supports more shelters and transitional housing plus diversion programs connecting unhoused people to supportive services, and stresses keeping people housed.$$, ARRAY['https://www.megankerr.com/platform','https://sigtrib.com/long-beach-measure-a-funds-homelessness-prevention-housing/']),
  ('homelessness', $$Emphasizes shelters, transitional housing, supportive-services diversion, and an emergency RV storage lot rather than criminal penalties for people sleeping outside.$$, ARRAY['https://www.megankerr.com/platform','https://www.megankerr.com/accomplishments']),
  ('civil-rights', $$Authored legislation recognizing Harvey Milk Day and LGBTQ+ Pride Month and advanced SOGI data collection to improve health equity.$$, ARRAY['https://www.megankerr.com/accomplishments']),
  ('same-sex-marriage', $$Authored official city recognition of Harvey Milk Day and LGBTQ+ Pride Month, signaling full support for LGBTQ+ recognition.$$, ARRAY['https://www.megankerr.com/accomplishments']),
  ('transportation-priorities', $$As Mobility, Ports & Infrastructure Committee chair she prioritized traffic calming, pedestrian safety, sidewalk repairs, and a speed-safety camera pilot alongside street upkeep.$$, ARRAY['https://www.megankerr.com/platform','https://www.megankerr.com/accomplishments']),
  ('local-environment', $$Secured permanent dedication of all 48 acres of Willow Springs Park as open space and pushed citywide tree planting and park improvements.$$, ARRAY['https://www.megankerr.com/platform','https://www.megankerr.com/accomplishments']),
  ('climate-change', $$Advocated against leaded aviation fuel and for subsidies to encourage unleaded fuel at Long Beach Airport, plus higher airport noise-violation fees.$$, ARRAY['https://www.megankerr.com/platform']),
  ('economic-development', $$Plans to grow economic drivers like the port, downtown, and airport and supports developing 'Space Beach' and business grant programs to attract jobs.$$, ARRAY['https://www.megankerr.com/platform','https://lbpost.com/news/politics/elections/long-beach-voter-guide-city-council-district-5/']),
  ('taxes', $$Calls for belt-tightening and a thorough department budget review to cut costs amid the deficit while protecting core resident services, without proposing tax changes.$$, ARRAY['https://lbpost.com/news/politics/elections/long-beach-voter-guide-city-council-district-5/']),
  ('growth-and-development', $$Works with developers to incorporate neighborhood input on housing projects while supporting planned, full-spectrum housing growth.$$, ARRAY['https://www.megankerr.com/platform','https://www.megankerr.com/accomplishments'])
) AS d(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665835
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
