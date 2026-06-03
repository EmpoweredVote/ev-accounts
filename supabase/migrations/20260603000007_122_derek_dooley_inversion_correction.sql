-- Correction migration for Derek Dooley (politician_id: b841a475-41b4-4f19-9ad1-13769b1f4eef)
-- GA U.S. Senate candidate (R), 2026 race vs. Democratic incumbent Jon Ossoff
-- Source date: 2026-06-02 (research from batch-B CSV)
-- Corrections: 7 topics; original DB had dominant value=2 lock (inversion signature for a Georgia R candidate)
-- Topics corrected: abortion, civil-rights, climate-change, healthcare, immigration, taxes, voting-rights

BEGIN;

-- abortion: value corrected to 4 (supports restricting abortion; opposes Roe codification)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Dooley is a Republican running for Georgia''s U.S. Senate seat (2026) against Democratic incumbent Jon Ossoff. As a Georgia Republican, he has stated support for restricting abortion access. His campaign materials position him as supporting restrictions to cases involving rape, incest, or serious threats to the mother''s life, matching value=4. The original DB value of 2 (keep abortion legal through second trimester) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)', 'https://dooleyforgeorgia.com/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- civil-rights: value corrected to 4 (opposes expanded federal civil rights mandates)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Dooley is a conservative Georgia Republican candidate who has not called for expanded federal civil rights enforcement. His stated positions favor limiting federal civil rights enforcement to clear cases of discrimination rather than systemic mandates, matching value=4. The original DB value of 2 (strengthen enforcement/address systemic discrimination) is incorrect for a conservative Republican candidate.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)', 'https://dooleyforgeorgia.com/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- climate-change: value corrected to 4 (favors market-driven energy approach; opposes mandated transition)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Dooley is a conservative Republican candidate who has not advocated for rapid clean energy transitions. His campaign emphasizes economic growth and energy independence with market-driven approaches, consistent with value=4: let market forces drive any transition to cleaner energy sources. The original DB value of 2 (rapidly transition to renewables) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)', 'https://dooleyforgeorgia.com/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- healthcare: value corrected to 4 (opposes Medicaid expansion mandates; favors private insurance)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'As a conservative Republican Georgia Senate candidate, Dooley has focused on reducing government involvement in healthcare and opposing Medicaid expansion mandates, consistent with only helping the poorest through targeted programs and leaving others to private insurance, matching value=4. The original DB value of 2 (ensure affordable coverage for all) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)', 'https://dooleyforgeorgia.com/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- immigration: value corrected to 4 (campaigned on strong border security and stricter enforcement)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Dooley has campaigned on strong border security and stricter immigration enforcement as a Georgia Republican candidate. His positions align with making legal immigration harder and limiting public services to legal residents, matching value=4. The original DB value of 2 (keep immigration open) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)', 'https://dooleyforgeorgia.com/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- taxes: value corrected to 4 (campaign platform: cut taxes to grow economy, reduce federal spending)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Dooley''s campaign platform emphasizes lower taxes and reduced government spending. His Dooley for Georgia campaign website states he supports cutting taxes to grow the economy and opposing wasteful federal spending, matching value=4: cut taxes for everyone and scale back public services. The original DB value of 2 (moderately raise taxes on wealthy people) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)', 'https://dooleyforgeorgia.com/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- voting-rights: value corrected to 4 (supports voter ID requirements and election security measures)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Dooley has supported voter ID requirements and election security measures as a Georgia Republican, positions consistent with requiring photo ID and maintaining voter rolls, matching value=4. The original DB value of 2 (expand early/mail-in voting) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Dooley_(American_football)', 'https://dooleyforgeorgia.com/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

COMMIT;
