-- Full coverage sprint for Andrej Selivra (politician_id: f2e91286-8dbc-477a-88be-458dffe774a2)
-- LA City Council CD13 candidate
-- NOTE: candidate website offline; no press coverage found. All sources resolve to
--       Ballotpedia elections page. Coverage capped until candidate gains more visibility.
-- Group A: add ballotpedia source to 6 thin context rows
--          (economic-development, growth-and-development, immigration, local-immigration,
--           public-safety-approach, residential-zoning)
-- Group B: 1 new insert (homelessness=2 — well-supported by Public Dormitories platform)
-- Skipped: all other topics — insufficient evidence

-- ── GROUP A: Add sources to existing thin context rows ───────────────────────

UPDATE inform.politician_context SET
  sources = ARRAY['https://ballotpedia.org/Los_Angeles_City_Council_elections,_2026']
WHERE politician_id = 'f2e91286-8dbc-477a-88be-458dffe774a2'
  AND topic_id IN (
    'eb3d1247-0de1-4b7f-baec-7259861efd53',  -- economic-development
    'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',  -- growth-and-development
    '4e2c69ce-591e-4197-9cd5-7aceff79d390',  -- immigration
    'b9ccee94-ad96-4f10-b655-889d8e5abe92',  -- local-immigration
    'e9ebefcd-c496-45e8-b816-a79f8442ba85',  -- public-safety-approach
    'd4f18138-a2e0-4110-b925-7387d9d0d16d'   -- residential-zoning
  );

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2e91286-8dbc-477a-88be-458dffe774a2', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f2e91286-8dbc-477a-88be-458dffe774a2',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Selivra''s signature proposal — City-operated Public Dormitories providing high-density hostel-style housing with wraparound services including addiction counseling, mental health support, childcare, and job training — reflects a decriminalization-and-service approach rather than enforcement. Having lived in his car as a teenager, he frames homelessness as a systemic failure requiring housing solutions. This aligns with decriminalizing public sleeping while investing in shelter capacity, outreach, and voluntary service connections.',
  ARRAY['https://ballotpedia.org/Los_Angeles_City_Council_elections,_2026']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
