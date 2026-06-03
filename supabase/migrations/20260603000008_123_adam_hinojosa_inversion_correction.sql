-- Correction migration for Adam Hinojosa (politician_id: 0c6c482a-feba-45bc-821b-02769a810063)
-- TX State Senator, Senate District 27 (Rio Grande Valley / Corpus Christi, R)
-- Source date: 2026-06-02 (research from batch-B CSV)
-- PARTY CORRECTION: DB had party = 'Democrat'; Wikipedia + Texas Senate bio confirm party = 'Republican'
--   Hinojosa won the 2024 SD-27 election as a Republican against Democratic incumbent Morgan LaMantia.
--   Source: https://en.wikipedia.org/wiki/Adam_Hinojosa
-- Corrections: party tag + 6 stance topics: abortion, civil-rights, immigration,
--   religious-freedom, school-vouchers, taxes

BEGIN;

-- PARTY CORRECTION: Democrat → Republican (verified via Wikipedia + Texas Senate official bio)
UPDATE essentials.politicians SET party = 'Republican'
WHERE id = '0c6c482a-feba-45bc-821b-02769a810063';

-- abortion: value corrected to 4 (TX Republican, supported state near-total abortion ban)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '0c6c482a-feba-45bc-821b-02769a810063'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0c6c482a-feba-45bc-821b-02769a810063',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Hinojosa is a Republican Texas State Senator representing SD-27 who ran explicitly as a conservative Republican. Texas Republicans overwhelmingly supported the state''s near-total abortion ban (SB 8, SB 4). His committee assignment on State Affairs (which oversees such legislation) and his campaign as a conservative Republican in South Texas position him at value=4: restrict abortion to only cases involving rape, incest, or serious threats to the mother''s life.',
  ARRAY['https://en.wikipedia.org/wiki/Adam_Hinojosa', 'https://senate.texas.gov/member.php?d=27']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- civil-rights: value corrected to 4 (conservative Republican; opposes expanded federal civil rights mandates)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '0c6c482a-feba-45bc-821b-02769a810063'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0c6c482a-feba-45bc-821b-02769a810063',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Hinojosa is a conservative Republican Texas Senator who campaigned capitalizing on Trump''s strong 2020 performance in the Rio Grande Valley. His positions align with limiting federal civil rights enforcement to clear cases of discrimination rather than systemic mandates, matching value=4.',
  ARRAY['https://en.wikipedia.org/wiki/Adam_Hinojosa', 'https://senate.texas.gov/member.php?d=27']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- immigration: value corrected to 4 (vice chair TX Senate Border Security Committee; campaigned on enforcement)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '0c6c482a-feba-45bc-821b-02769a810063'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0c6c482a-feba-45bc-821b-02769a810063',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Hinojosa serves on the Texas Senate Border Security Committee (vice chair). His campaign focused on border security as a key issue. He supports stricter immigration enforcement and limiting public services to those with legal status, consistent with value=4: make it harder to immigrate legally and limit public services to people with legal status.',
  ARRAY['https://en.wikipedia.org/wiki/Adam_Hinojosa', 'https://senate.texas.gov/member.php?d=27']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- religious-freedom: value corrected to 4 (conservative Republican; supports faith-based exemptions)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '0c6c482a-feba-45bc-821b-02769a810063'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0c6c482a-feba-45bc-821b-02769a810063',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  'Hinojosa is a conservative Republican from South Texas with strong Catholic faith-community ties. His positions support protecting religious freedom including allowing faith-based exemptions from laws that conflict with sincere religious beliefs, matching value=4.',
  ARRAY['https://en.wikipedia.org/wiki/Adam_Hinojosa', 'https://senate.texas.gov/member.php?d=27']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- school-vouchers: value corrected to 5 (TX Education K-16 Committee member; championed universal voucher program)
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = '0c6c482a-feba-45bc-821b-02769a810063'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0c6c482a-feba-45bc-821b-02769a810063',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Hinojosa serves on the Texas Senate Education K-16 Committee. Texas Republicans under Governor Abbott championed universal school choice/voucher programs (HB 1, SB 2 in 2023-2024 special sessions, ultimately passed in 2025). As a member of the Education committee and consistent Republican, Hinojosa has supported providing universal vouchers so education funding follows the student to any school, matching value=5.',
  ARRAY['https://en.wikipedia.org/wiki/Adam_Hinojosa', 'https://senate.texas.gov/member.php?d=27']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- taxes: value corrected to 4 (TX conservative Republican; supports tax cuts and reduced government spending)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '0c6c482a-feba-45bc-821b-02769a810063'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0c6c482a-feba-45bc-821b-02769a810063',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Hinojosa is a conservative Republican who has supported tax cuts and reducing government spending, consistent with the Texas Republican fiscal agenda of cutting taxes for everyone and scaling back public services, matching value=4.',
  ARRAY['https://en.wikipedia.org/wiki/Adam_Hinojosa', 'https://senate.texas.gov/member.php?d=27']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

COMMIT;
