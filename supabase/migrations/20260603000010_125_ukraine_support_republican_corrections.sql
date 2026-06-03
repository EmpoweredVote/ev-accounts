-- Ukraine-support value corrections for Republican politicians (2→4)
-- John Barrasso (e4b27d5e-59de-4e71-a8a7-28e7b9a80807): 2 → 4
-- Marsha Blackburn (808ab926-365f-4b8a-a42e-628f11ecc48e): 2 → 4
-- Jay Obernolte (18db5d61-6bce-4f55-ad45-bed01f329548): 2 → 4
-- Mike Collins (ce8d48a3-5137-4521-81cd-8a86c0999b37): 2 → 4
-- Basis: April 2024 roll call votes (Senate vote 118-2 #154 and House roll call 164)
-- Brian W. Jones excluded: insufficient direct evidence (CA state legislator, no federal vote record)

BEGIN;

-- John Barrasso: voted NAY on Senate vote 118-2 #154 (April 23 2024, $95B supplemental, 79-18)
UPDATE inform.politician_answers
SET value = 4
WHERE politician_id = 'e4b27d5e-59de-4e71-a8a7-28e7b9a80807'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e4b27d5e-59de-4e71-a8a7-28e7b9a80807',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support'),
  'Barrasso voted NAY on Senate vote 118-2 #154 (April 23 2024) the $95 billion Ukraine-Israel-Taiwan supplemental that passed 79-18. He was one of only 18 senators to vote against this package. Despite his 2022 visit to Kyiv and prior hawkish posture his 2024 NAY vote demonstrates a shift to opposing further large Ukraine aid packages. His NAY vote on the major supplemental aligns with value=4 (reduce aid focus domestic priorities) rather than value=2 (continue current levels). No evidence of value=5 (end all aid) advocacy.',
  ARRAY['https://www.senate.gov/legislative/LIS/roll_call_votes/vote1182/vote_118_2_00154.htm']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- Marsha Blackburn: voted NAY on Senate vote 118-2 #154 (April 23 2024, $95B supplemental, 79-18)
UPDATE inform.politician_answers
SET value = 4
WHERE politician_id = '808ab926-365f-4b8a-a42e-628f11ecc48e'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '808ab926-365f-4b8a-a42e-628f11ecc48e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support'),
  'Blackburn voted NAY on Senate vote 118-2 #154 (April 23 2024) the $95 billion Ukraine-Israel-Taiwan supplemental. She was one of only 18 senators to vote against this package. While her national security page previously described hawkish rhetoric against Russia her 2024 NAY vote on the largest Ukraine aid package of that Congress demonstrates a shift to restricting further aid. Her NAY vote aligns with value=4 (reduce aid focus domestic priorities) not value=2 (continue current levels). No evidence of value=5 (end all aid) advocacy.',
  ARRAY['https://www.senate.gov/legislative/LIS/roll_call_votes/vote1182/vote_118_2_00154.htm']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- Jay Obernolte: voted NAY on House roll call 164 H.R. 8035 (April 2024, $60B Ukraine, 311-112)
UPDATE inform.politician_answers
SET value = 4
WHERE politician_id = '18db5d61-6bce-4f55-ad45-bed01f329548'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '18db5d61-6bce-4f55-ad45-bed01f329548',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support'),
  'Obernolte voted NAY on the April 2024 House Ukraine supplemental (House roll call 164 H.R. 8035 passed 311-112). This directly contradicts his prior support: he voted YEA on the 2022 Ukraine Lend-Lease Act (House roll 103) but shifted to NAY on continued large aid packages by 2024. His NAY vote on a $60 billion Ukraine aid package demonstrates a move to reduce/oppose further aid consistent with value=4 (reduce aid focus on domestic priorities). No evidence of value=5 (end all aid) advocacy.',
  ARRAY['https://clerk.house.gov/evs/2024/roll164.xml', 'https://clerk.house.gov/evs/2022/roll103.xml']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- Mike Collins: voted NAY on House roll call 164 H.R. 8035 (April 2024, $60B Ukraine, 311-112)
UPDATE inform.politician_answers
SET value = 4
WHERE politician_id = 'ce8d48a3-5137-4521-81cd-8a86c0999b37'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ce8d48a3-5137-4521-81cd-8a86c0999b37',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support'),
  'Collins voted NAY on the April 2024 House Ukraine supplemental (House roll 164 H.R. 8035 passed 311-112). Wikipedia documents he voted against providing military aid to Ukraine during the Russian invasion. AP News (October 2023) reported Collins views China as a bigger threat than Russia and has voted against Ukraine military aid while advocating for more Taiwan arms sales. His position is to redirect military resources rather than continue Ukraine aid — consistent with value=4 (reduce aid focus on other priorities). The original CSV source (ontheissues.org/Senate/Ashley_Hinson.htm) was a data error (wrong politician page).',
  ARRAY['https://clerk.house.gov/evs/2024/roll164.xml', 'https://en.wikipedia.org/wiki/Mike_Collins_(politician)', 'https://apnews.com/article/ukraine-funding-taiwan-us-china-military-8cbb671399a51e0e34b9e40f72f51e56']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

COMMIT;
