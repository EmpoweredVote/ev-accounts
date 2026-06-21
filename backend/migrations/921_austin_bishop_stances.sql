-- 921_austin_bishop_stances.sql — Phase 146 Wave 4 — AUDIT-ONLY (NOT registered in schema_migrations)
-- Evidence-only compass stances for Austin Bishop (external_id -201331, Palmdale D1, Mayor Pro Tem).
-- Chairs model (value = the discrete position statement the evidence matches, NOT a polarity axis).
-- 100% citation: paired inform.politician_answers + inform.politician_context (reasoning + real source URLs).
-- Honest blanks: only topics with a documented public record are included; national topics left blank.
-- NO judicial topics (Palmdale = appointed City Attorney, council-manager; D-13).
-- Apply via raw SQL; on-disk counter authoritative, ledger stays 919.
BEGIN;

-- public-safety-approach = 4 (championed 2024 nuisance-abatement ordinance; pro-deputy resources)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, 4 FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=-201331 AND t.topic_key='public-safety-approach' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, $$As Mayor, Bishop championed a 2024 nuisance-abatement ordinance (adopted unanimously) explicitly giving sheriff's deputies more local tools to prosecute misdemeanors the LA DA was declining to charge, stating Palmdale "places a priority on public safety" and is "using innovative new local laws to provide tools to our deputies." He serves on the AV Sheriff's Boosters board to ensure deputies "have the resources they need." Matches chair 4 (increase/strengthen police resources and enforcement capacity).$$,
ARRAY['https://www.publicceo.com/2024/02/palmdale-city-council-takes-aggressive-steps-to-expand-crime-enforcement-newly-adopted-ordinance-bypasses-district-attorneys-soft-on-crime-policies/','https://www.cityofpalmdaleca.gov/306/Councilmember-Austin-Bishop']::text[]
FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=-201331 AND t.topic_key='public-safety-approach' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- homelessness = 3 (backed Pathway Home encampment operations pairing clearing with interim housing/services)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, 3 FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=-201331 AND t.topic_key='homelessness' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, $$Bishop publicly supported the LA County "Pathway Home" operations that disbanded large Palmdale encampments by moving 121 people into interim housing, framing it as bringing assistance to the unhoused surviving life-threatening desert heat while restoring neighborhood quality of life. His framing pairs removal of encampments with housing/services and outreach rather than purely punitive penalties — matches chair 3 (enforcement of reasonable rules alongside outreach/shelter once housing is offered).$$,
ARRAY['https://lacounty.gov/2024/09/05/los-angeles-county-conducts-pathway-home-operations-in-palmdale/','https://www.avpress.com/news/count-shows-number-of-palmdale-homeless-down/article_fcc20030-d3a0-11ea-9c2d-671eb0e36d2f.html']::text[]
FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=-201331 AND t.topic_key='homelessness' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- homelessness-response = 3 (same documented record: outreach/shelter plus enforcement)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, 3 FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=-201331 AND t.topic_key='homelessness-response' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, $$Bishop backed coordinated encampment-clearing operations that simultaneously connected people to interim housing and services, framing it as compassion plus restoring quality of life — an outreach/shelter-plus-enforcement posture (chair 3) rather than housing-first-only (1) or strict camping-ban-first (5).$$,
ARRAY['https://lacounty.gov/2024/09/05/los-angeles-county-conducts-pathway-home-operations-in-palmdale/']::text[]
FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=-201331 AND t.topic_key='homelessness-response' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- economic-development = 4 (actively recruits major employers — Trader Joe's DC, Metro railcar plant)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, 4 FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=-201331 AND t.topic_key='economic-development' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, $$As Mayor, Bishop's central economic message is recruiting large employers to create local jobs so residents stop super-commuting down the 14 freeway. He touted the Trader Joe's distribution center (~1,000 jobs) and the Metro railcar production facility, saying "once a large company like this comes in, it's the domino effect." Actively competing to land major employers as the growth strategy matches chair 4.$$,
ARRAY['https://spectrumnews1.com/ca/southern-california/politics/2024/11/01/in-a-city-of-super-commuters--palmdale-officials-look-to-create-local-jobs']::text[]
FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=-201331 AND t.topic_key='economic-development' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- local-environment = 3 (promotes solar/sustainability (Power Choice) while also pro-development jobs; balanced)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, 3 FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=-201331 AND t.topic_key='local-environment' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, $$As Mayor, Bishop promoted Palmdale EPIC's "Power Choice" program (rooftop solar + battery storage), calling it a commitment to sustainability and affordable energy, and serves as a delegate to the AV Air Quality Management District and a director of the Palmdale Recycled Water Authority. He pairs clean-energy advocacy with active pro-development job recruitment, indicating a balanced standards-with-flexibility posture (chair 3) rather than strict preservation-first (1-2) or removing environmental rules (5).$$,
ARRAY['https://www.cityofpalmdaleca.gov/m/newsflash/home/detail/1670','https://www.cityofpalmdaleca.gov/306/Councilmember-Austin-Bishop']::text[]
FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=-201331 AND t.topic_key='local-environment' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

COMMIT;
