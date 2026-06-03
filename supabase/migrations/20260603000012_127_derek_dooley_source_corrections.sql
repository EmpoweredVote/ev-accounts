-- Fix two data-quality issues with Derek Dooley (b841a475-41b4-4f19-9ad1-13769b1f4eef):
--
-- Issue A: 7 context rows cite https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)
--   — the Tennessee football coach Wikipedia page, not the 2026 Georgia Senate candidate.
--   Fix: strip that URL from sources arrays; keep https://dooleyforgeorgia.com/
--   Affected topics: abortion, civil-rights, climate-change, healthcare,
--                    immigration, taxes, voting-rights
--
-- Issue B: 3 context + answer rows contain Angie Nixon's data cross-applied to Dooley.
--   judicial-criminal-justice (value=2), school-vouchers (value=1), social-security (value=2)
--   all cite https://www.ontheissues.org/Senate/Angie_Nixon.htm and carry Nixon's liberal
--   reasoning ("supports fully funding public education for all Florida students").
--   Fix: DELETE both politician_answers and politician_context for these 3 topics.
--   These stances will be absent (no value) rather than wrong. Re-research required.

BEGIN;

-- A: Strip football-coach Wikipedia URL from the 7 corrected-value topics
UPDATE inform.politician_context
SET sources = array_remove(
    sources,
    'https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)'
)
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id IN (
    SELECT id FROM inform.compass_topics
    WHERE topic_key IN (
      'abortion', 'civil-rights', 'climate-change', 'healthcare',
      'immigration', 'taxes', 'voting-rights'
    )
  );

-- B: Delete the 3 Nixon-contaminated rows (context first, then answers)
DELETE FROM inform.politician_context
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id IN (
    SELECT id FROM inform.compass_topics
    WHERE topic_key IN ('judicial-criminal-justice', 'school-vouchers', 'social-security')
  );

DELETE FROM inform.politician_answers
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id IN (
    SELECT id FROM inform.compass_topics
    WHERE topic_key IN ('judicial-criminal-justice', 'school-vouchers', 'social-security')
  );

COMMIT;

-- Verification:
-- SELECT topic_key, sources FROM inform.politician_context pc
--   JOIN inform.compass_topics ct ON ct.id = pc.topic_id
--   WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
--   ORDER BY topic_key;
-- Expected: 7 rows; none with the _(American_football) URL; none citing Angie_Nixon.htm
