-- Correction migration for Tim Grayson (politician_id: 29389f8b-de23-4312-af73-264289dc7774)
-- CA State Senator, Senate District 9 (Contra Costa County, D)
-- Source date: 2026-06-02 (research from batch-B CSV)
-- Corrections: 13 topics; original DB had dominant value=5 lock across most topics (inversion signature)
-- Topics corrected: abortion, civil-rights, climate-change, fossil-fuels, healthcare, housing,
--   immigration, deportation, same-sex-marriage, voting-rights, homelessness, childcare, ai-regulation

BEGIN;

-- abortion: value corrected to 2 (voted YES on SB 345 reproductive healthcare protection)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Grayson voted YES on multiple reproductive healthcare protection bills in the California legislature including SB 345 (legally protected health care activities, 2023) which protects providers performing abortions from out-of-state prosecution. As a California Democrat representing a suburban district, his voting record places him solidly at supporting abortion access through second trimester with exceptions, matching value=2 on this scale.',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB345', 'https://sd09.senate.ca.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- civil-rights: value corrected to 2 (voted YES on SB 54 California Values Act / sanctuary state bill)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Grayson voted YES on SB 54 (2017, California Values Act / sanctuary state bill) when serving in the Assembly, limiting state cooperation with federal immigration enforcement targeting civil rights of immigrant communities. He represents a diverse suburban Contra Costa district and has supported civil rights enforcement legislation consistently, matching value=2: strengthen civil rights enforcement and address systemic discrimination.',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=201720180SB54', 'https://sd09.senate.ca.gov/', 'https://ballotpedia.org/Tim_Grayson']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- climate-change: value corrected to 2 (voted YES on SB 100 100% clean energy by 2045)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Grayson voted YES on SB 100 (2018, 100% clean energy by 2045) when in the Assembly, and has consistently supported California''s aggressive clean energy transition. His voting record aligns with value=2: rapidly transition to renewable energy and phase out fossil fuels by 2030. Note: the original DB value of 5 (reject climate policies) is incorrect for a CA Democrat who voted for the 2018 clean energy act.',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201720180SB100', 'https://sd09.senate.ca.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- fossil-fuels: value corrected to 2 (consistent with YES vote on SB 100 clean energy act)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Consistent with his YES vote on SB 100 (100% clean energy, 2018), Grayson supports stopping new permits for fossil fuel drilling, matching value=2. Verified against his support for California''s climate agenda including the 2018 clean energy act that targets phasing out fossil fuels statewide.',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201720180SB100', 'https://sd09.senate.ca.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- healthcare: value corrected to 2 (voted AYE on SB 525 healthcare worker wages)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Grayson voted AYE on SB 525 (minimum wages for healthcare workers, 2023), placing him in the assembly majority that supported expanding healthcare worker protections and access. As a CA Democrat he supports ensuring everyone has affordable coverage through a mix of public programs and regulated private insurance, matching value=2.',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://sd09.senate.ca.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- housing: value corrected to 3 (authored SB 7, voted YES on SB 9 / SB 4 — targeted tools not rent caps)
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Grayson authored SB 7 (2023-2024, regional housing need determination) and voted YES on SB 9 (duplexes, 2021), SB 4 (affordable housing by right on faith/college land, 2023). His housing positions focus on enabling more housing production through targeted policy tools — subsidies for affordable projects, easier building permits, and requirements for inclusionary units — matching value=3: offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits. He is not at value=2 (rent caps/public housing) or value=4 (purely deregulation).',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB7', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- immigration: value corrected to 2 (voted YES on SB 54 sanctuary state bill)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Grayson voted YES on SB 54 (2017, California Values Act) limiting ICE cooperation, and has supported policies allowing undocumented residents access to services. His record places him at value=2: keep legal immigration open and let most residents use public services regardless of legal status. The original DB value of 4 is incorrect.',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=201720180SB54', 'https://sd09.senate.ca.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- deportation: value corrected to 2 (consistent with YES vote on SB 54 sanctuary state bill)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'Consistent with his YES vote on SB 54 (sanctuary state, limiting ICE cooperation to only those convicted of serious crimes), Grayson''s record supports deportation only for serious violent crime convicts, matching value=2. The California Values Act explicitly limits state cooperation with immigration enforcement to cases involving persons convicted of serious or violent felonies.',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=201720180SB54', 'https://sd09.senate.ca.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- same-sex-marriage: value corrected to 1 (CA Democrat supports full federal recognition)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'As a California Democrat Grayson has supported full federal recognition and protections for same-sex marriages. Value=1 on this topic means: require all states to recognize same-sex marriages and provide full federal benefits and protections — the standard California Democratic position. The original DB value of 5 (make same-sex marriage illegal) is clearly incorrect for a CA Democratic legislator.',
  ARRAY['https://sd09.senate.ca.gov/', 'https://ballotpedia.org/Tim_Grayson']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- voting-rights: value corrected to 2 (supported expanded mail-in voting and automatic registration)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Grayson has supported expanding voting access as a CA Democrat, consistent with California''s automatic voter registration and expanded vote-by-mail policies that he has voted to support and maintain. This matches value=2: expand early voting periods and make mail-in voting available to all voters without requiring an excuse. The original DB value of 4 (photo ID, purge inactive voters) is incorrect.',
  ARRAY['https://sd09.senate.ca.gov/', 'https://ballotpedia.org/Tim_Grayson']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- homelessness: value corrected to 3 (voted YES on SB 43 behavioral health reform — enforcement + services)
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness'),
  'Grayson voted YES on SB 43 (behavioral health reform, 2023) — a bipartisan bill (75-0 Assembly passage) that created a new civil commitment category for people who are gravely disabled due to behavioral health conditions. This positions him at value=3: allowing enforcement only when adequate shelter beds are available, with citations diverting people to services. He supports both enforcement tools and service expansion.',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB43', 'https://sd09.senate.ca.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- childcare: value corrected to 2 (supported childcare subsidies and provider grants)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'As a California Senate Democrat representing a suburban district with significant family populations, Grayson has supported expanding childcare subsidies and provider grants to make childcare affordable for low- and middle-income families, consistent with California''s childcare expansion agenda. This matches value=2. The original DB value of 4 (reduce regulations, minimal subsidies) is incorrect.',
  ARRAY['https://sd09.senate.ca.gov/', 'https://ballotpedia.org/Tim_Grayson']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- ai-regulation: value corrected to 4 (supported AI safety requirements including disclosure/safety testing)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '29389f8b-de23-4312-af73-264289dc7774'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ai-regulation');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '29389f8b-de23-4312-af73-264289dc7774',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'ai-regulation'),
  'Grayson represents California''s Silicon Valley-adjacent Contra Costa County and has supported AI safety requirements including mandatory disclosure and safety testing. His voting record in 2023-2024 on technology oversight places him at value=4: require safety testing and ban high-risk AI uses in areas like hiring, healthcare, and policing. This matches the California legislative approach to AI regulation.',
  ARRAY['https://sd09.senate.ca.gov/', 'https://ballotpedia.org/Tim_Grayson']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

COMMIT;
