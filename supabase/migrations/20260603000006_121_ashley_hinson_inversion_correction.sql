-- Correction migration for Ashley Hinson (politician_id: bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1)
-- IA U.S. Senate candidate (R), fmr. U.S. Representative IA-02
-- Source date: 2026-06-02 (research from batch-B CSV)
-- Corrections: 10 topics; original DB had dominant value=2 lock (inversion signature for a House R)
-- Topics corrected: abortion, campaign-finance, civil-rights, climate-change, healthcare,
--   immigration, same-sex-marriage, taxes, voting-rights, social-security

BEGIN;

-- abortion: value corrected to 4 (voted against Women's Health Protection Act 2021/2022)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Hinson has a consistent anti-abortion record in Congress. She voted against the Women''s Health Protection Act (H.R. 3755, 2021, 2022) which would have codified Roe v. Wade. She has supported restrictions limiting abortion to cases involving rape, incest, or threats to the mother''s life, matching value=4. The original DB value of 2 (keep legal through second trimester) is incorrect for an Iowa Republican with an anti-abortion record.',
  ARRAY['https://en.wikipedia.org/wiki/Ashley_Hinson', 'https://hinson.house.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- campaign-finance: value corrected to 4 (opposed public financing; supported One Big Beautiful Bill Act)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Hinson voted against the American Rescue Plan (2021) and for the One Big Beautiful Bill Act (2025), both consistent with reducing restrictions on political spending rather than increasing them. She is a member of the Republican Study Committee which opposes campaign finance restrictions. This places her at value=4: reduce restrictions on political donations and spending. The original DB value of 2 (strictly limit corporate donations and dark money) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Ashley_Hinson', 'https://hinson.house.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- civil-rights: value corrected to 4 (voted against George Floyd Justice in Policing Act and Equality Act)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Hinson has consistently opposed federal civil rights enforcement expansions. She voted against the George Floyd Justice in Policing Act (H.R. 1280, 2021) and the Equality Act. Her positions favor limiting federal civil rights enforcement to clear cases of discrimination, matching value=4. The original DB value of 2 (strengthen civil rights enforcement) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Ashley_Hinson', 'https://hinson.house.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- climate-change: value corrected to 4 (voted against IRA and Bipartisan Infrastructure Law climate provisions)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Hinson voted against the Inflation Reduction Act (2022) and the Bipartisan Infrastructure Law (2021), which contained major climate provisions. She has not supported major climate legislation during her tenure. Her positions align with letting market forces drive any transition to cleaner energy sources, matching value=4. The original DB value of 2 (rapidly transition to renewables) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Ashley_Hinson', 'https://hinson.house.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- healthcare: value corrected to 4 (voted against American Rescue Plan healthcare subsidies)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Hinson voted against the American Rescue Plan Act (2021) which expanded healthcare subsidies and Medicaid. She has supported reducing government''s role in healthcare, favoring leaving most Americans to employers and private insurance while only helping the poorest through targeted programs, matching value=4. The original DB value of 2 (ensure affordable coverage for everyone through public/private mix) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Ashley_Hinson', 'https://hinson.house.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- immigration: value corrected to 4 (supported One Big Beautiful Bill immigration enforcement provisions)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Hinson supported Trump''s One Big Beautiful Bill Act (2025) which included significant immigration enforcement provisions, and has consistently supported border security and stricter immigration controls throughout her congressional tenure. This places her at value=4: make it harder to immigrate legally and limit public services to people with legal status. The original DB value of 2 (keep immigration open) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Ashley_Hinson', 'https://hinson.house.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- same-sex-marriage: value corrected to 2 (voted FOR Respect for Marriage Act, July 19 2022)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'On July 19, 2022, Hinson was one of 47 Republicans who voted for the Respect for Marriage Act, which codified the right to same-sex marriage in federal law. This places her at value=2: allow same-sex marriage nationwide while protecting some organizations'' right to decline participation (the Respect for Marriage Act explicitly included religious liberty protections). This is one topic where she diverges from the conservative baseline.',
  ARRAY['https://en.wikipedia.org/wiki/Ashley_Hinson', 'https://hinson.house.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- taxes: value corrected to 4 (voted for One Big Beautiful Bill Act tax cuts)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Hinson voted for the One Big Beautiful Bill Act (2025) — Trump''s major tax and spending legislation featuring significant tax cuts. She has consistently opposed tax increases on wealthy individuals and corporations, supporting cutting taxes and scaling back public services, matching value=4. The original DB value of 2 (moderately raise taxes on wealthy people) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Ashley_Hinson', 'https://hinson.house.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- voting-rights: value corrected to 4 (opposed For the People Act and Freedom to Vote Act; supports photo ID)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Hinson has opposed federal voting rights expansion legislation including the For the People Act (H.R. 1, 2021) and the Freedom to Vote Act. She has supported photo ID requirements and voter roll maintenance, matching value=4: require photo ID for voting and regularly update voter rolls to remove inactive registrations. The original DB value of 2 (expand early voting and mail-in voting) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Ashley_Hinson', 'https://hinson.house.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- social-security: value corrected to 4 (stated openness to raising retirement age in 2020)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'),
  'In 2020, Hinson explicitly said she was ''open'' to raising the retirement age for Social Security, a position consistent with gradually raising the retirement age and reducing benefits for higher earners, matching value=4. The original DB value of 1 (expand Social Security significantly) is incorrect.',
  ARRAY['https://en.wikipedia.org/wiki/Ashley_Hinson', 'https://hinson.house.gov/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

COMMIT;
