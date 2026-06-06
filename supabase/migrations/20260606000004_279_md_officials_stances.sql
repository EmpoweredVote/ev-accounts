-- Phase 103: MD Officials Fresh Stances
-- Requirements covered: STAX-02, QUAL-01
-- Source CSV: backend/data/stance-research/2026-06-06-md-officials.csv
-- No deletion log: MD officials had zero existing stances before this migration (CONTEXT.md D-04)
--
-- MD officials (UUIDs from Phase 100 audit — UUID literals, not name lookup):
--   Wes Moore          → 21e534c8-c0c0-42f5-b52b-5eb2f246d632
--   Aruna Miller       → ea9fc2d6-3b26-469a-978c-e8c846d2d49a
--   Anthony G. Brown   → 60329719-1d5b-4bb4-8295-38ea18f6f378
--   Brooke Lierman     → b26fb5d2-90eb-4108-8ce5-838df719473d
--   Dereck E. Davis    → 75378a96-8886-46eb-b0c1-37cbe2579265
--
-- Migration number: 279 (verified MAX(version) = 277 at write time; Plan 02 reserves 278, Plan 03 uses 279)
-- Applied: 2026-06-06 via psql session pooler
--
-- Pre-write cross-check:
--   CSV data rows: 23 (one INSERT INTO inform.politician_answers per row)
--   INSERT INTO inform.politician_answers count: 23 ✓
--   INSERT INTO inform.politician_context count: 23 ✓
--   DELETE FROM statements: 0 (MD officials had zero existing stances) ✓
--   ARRAY_CAT occurrences: 0 (plain overwrite only — no prior context rows for MD) ✓
--   All UUID literals match 5 locked MD UUIDs ✓
--   No duplicate (politician_id, topic_id) pairs within file ✓

BEGIN;

-- ============================================================
-- INSERT BLOCK — 23 rows (from 2026-06-06-md-officials.csv)
-- Plain overwrite ON CONFLICT (not ARRAY_CAT) — MD officials
-- have no prior context rows (CONTEXT.md D-05 exception applies
-- to CA only; MD is pure fresh INSERT).
-- ============================================================

-- ---- Wes Moore / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Moore stated Maryland will protect reproductive health and rights and called for enshrining the right to abortion into Maryland''s Constitution. His campaign platform committed to keeping abortion legal and accessible through the second trimester with strong protections — consistent with value 2 (''keep abortion legal and accessible through the second trimester with rare exceptions afterward''). He also pledged to protect reproductive health care access and stockpiled mifepristone for years of supply.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/governor/Wes_Moore_Abortion.htm',
    'https://wesmoore.com/issues/reproductive-rights/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Wes Moore / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Moore pledged to take ''swift and bold action on climate change'' after the Supreme Court''s 2022 EPA ruling, promising Maryland would push back. He signed legislation to accelerate clean energy investment as governor. His approach centers on investing in clean energy while gradually reducing fossil fuel reliance — consistent with value 3 (''invest in clean energy while gradually reducing reliance on fossil fuels''). He has not declared a climate emergency or pledged to ban all fossil fuel activities.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/governor/Wes_Moore_Environment.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Wes Moore / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Moore said Maryland would ''follow the Constitution'' on ICE cooperation, expressing personal commitment to immigration as a child of an immigrant mother. He opposed mass deportations and supported open legal immigration pathways. His position aligns with value 2 (''Keep legal immigration open and let most residents use public services regardless of legal status''), not a full sanctuary position (value 1) but clearly opposing restrictive enforcement.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/governor/Wes_Moore_Immigration.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Wes Moore / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Moore acknowledged the ''10 to 1 racial wealth gap'' and called for policy measures to address historic discrimination. He committed to LGBTQ+-affirming school policies and supporting the Trans Health Equity Act. His position aligns with value 2 (''strengthen civil rights enforcement and address systemic discrimination'') — he advocates for addressing systemic causes, not just equal opportunity.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/governor/Wes_Moore_Civil_Rights.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Wes Moore / tariffs / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'),
  'Moore said ''tariffs are a tool, they''re not an ideology'' in criticizing Trump''s broad tariff approach. He opposed disruptive tariff policies but expressed support for selective use of tariffs to protect American industries. This matches value 3 (''use tariffs selectively to protect key American industries and jobs'') — he does not support eliminating tariffs (values 1-2) nor broad across-the-board tariffs (values 4-5).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/governor/Wes_Moore_Free_Trade.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Wes Moore / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Moore announced the ''largest increase in funding for child care in Maryland history'' supporting 45,000 children, and called for expanding the Child and Dependent Care Tax Credit and capping out-of-pocket expenses for families in need. This matches value 2 (''Significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families'') — well beyond targeted tax credits (value 3) but not universal publicly-funded childcare (value 1).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/governor/Wes_Moore_Families_+_Children.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Wes Moore / fossil-fuels / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Moore promised to take bold climate action but his official record shows investment in clean energy transition rather than banning new permits. Maryland has not stopped issuing fossil fuel permits under his governorship. His approach is maintaining current environmental regulation while investing in clean energy — consistent with value 3 (''maintain current levels of fossil fuel production with existing environmental regulations'').',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/governor/Wes_Moore_Environment.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Wes Moore / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Moore''s proposed budget included significant new childcare investments and housing programs. In 2024 State of the State address he noted these could be made ''without raising taxes on Marylanders,'' but his overall fiscal policy has supported moderately raising revenues from corporations and higher earners to fund expanded services. This aligns with value 2 (''Moderately raise taxes on wealthy people and large companies to fund existing services'').',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.ontheissues.org/governor/Wes_Moore_Families_+_Children.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Aruna Miller / same-sex-marriage / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'In 2012, Miller voted for the Civil Marriage Protection Act to legalize same-sex marriage in Maryland. She supports nationwide recognition while protecting religious freedom for organizations. This matches value 2 (''allow same-sex marriage nationwide while protecting some organizations'' right to decline participation'').',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Aruna_Miller'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Aruna Miller / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Miller co-sponsored Maryland''s fracking ban and supported aggressive environmental legislation including the Marcellus Shale Act of 2011. She introduced legislation to protect the Potomac River Basin. Her record reflects value 2 (''rapidly transition to renewable energy and phase out fossil fuels by 2030'') — banning fracking is a strong anti-fossil-fuel position.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Aruna_Miller'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Aruna Miller / fossil-fuels / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Miller co-sponsored Maryland''s fracking ban from the outset, beginning with the Marcellus Shale Act of 2011 that laid the groundwork for the eventual fracking ban she co-sponsored. Banning fracking is equivalent to stopping new permits for fossil fuel drilling — value 2 (''stop issuing new permits for fossil fuel drilling'').',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Aruna_Miller'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Aruna Miller / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'During her 2018 House campaign, Miller explicitly stated she supported moving toward a single-payer healthcare system, and signed an amicus brief supporting the Affordable Care Act. Her position of moving toward single-payer while supporting comprehensive coverage access aligns with value 2 (''Make sure everyone has affordable coverage through a mix of public programs and regulated private insurance'') — actively supporting expanded public coverage.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Aruna_Miller'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Aruna Miller / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Miller voted for the Civil Marriage Protection Act, supported LGBTQ+ rights, and pushed for equal treatment across multiple minority groups. Her legislative record shows consistent commitment to strengthening civil rights enforcement — value 2 (''strengthen civil rights enforcement and address systemic discrimination'').',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Aruna_Miller'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Anthony G. Brown / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '60329719-1d5b-4bb4-8295-38ea18f6f378',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '60329719-1d5b-4bb4-8295-38ea18f6f378',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'As Maryland AG, Brown secured legislation allowing his office to prosecute civil rights violations in housing and employment, and police-involved deaths. He pursued cases against police misconduct and filed numerous lawsuits against the Trump administration protecting civil rights. His work matches value 2 (''strengthen civil rights enforcement and address systemic discrimination'').',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Anthony_Brown_(Maryland_politician)'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Anthony G. Brown / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '60329719-1d5b-4bb4-8295-38ea18f6f378',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '60329719-1d5b-4bb4-8295-38ea18f6f378',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Brown filed multiple lawsuits against the Trump administration''s immigration enforcement actions as AG. He joined multi-state coalitions opposing travel bans and immigration restrictions. This reflects value 2 (''Keep legal immigration open and let most residents use public services regardless of legal status'') — opposing restrictive enforcement while not calling for stopping all deportations.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Anthony_Brown_(Maryland_politician)'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Anthony G. Brown / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '60329719-1d5b-4bb4-8295-38ea18f6f378',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '60329719-1d5b-4bb4-8295-38ea18f6f378',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Brown, as a Democratic Maryland AG, has consistently defended abortion access and joined coalition lawsuits protecting reproductive rights. As a candidate, he ran as a strong defender of abortion access. This aligns with value 2 (''keep abortion legal and accessible through the second trimester with rare exceptions afterward'') — consistent with Maryland''s protective stance on abortion access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Anthony_Brown_(Maryland_politician)'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Brooke Lierman / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'In 2019, Lierman added her name to a manifesto reaffirming commitment to protecting abortion rights. In 2022, she spoke in support of legislation to enshrine the right to abortion in Maryland''s constitution, sharing her personal experience. Value 2 (''keep abortion legal and accessible through the second trimester with rare exceptions afterward'') fits her documented position of constitutional protection for abortion access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Brooke_Lierman'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Brooke Lierman / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Lierman introduced legislation banning polystyrene products (became law 2019), sponsored plastic bag ban legislation, and required Maryland pension funds to consider climate change as a financial factor. Her approach is investing in clean energy and environmental protection while maintaining economic balance — value 3 (''invest in clean energy while gradually reducing reliance on fossil fuels'').',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Brooke_Lierman'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Brooke Lierman / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Lierman testified in support of a 2026 bill to ban Maryland counties from entering 287(g) program agreements with ICE, citing immigrants'' economic contributions to Maryland. Opposition to 287(g) agreements (which expand local police participation in immigration enforcement) is consistent with value 2 (''Keep legal immigration open and let most residents use public services regardless of legal status'').',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Brooke_Lierman'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Brooke Lierman / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Lierman co-sponsored a 2020 bill to research reparations for descendants of enslaved Africans in Maryland. She introduced protections against police officer sexual misconduct. Her civil rights record reflects value 2 (''strengthen civil rights enforcement and address systemic discrimination'').',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Brooke_Lierman'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Brooke Lierman / school-vouchers / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Lierman has consistently supported increased funding for Baltimore City schools and universal pre-K, and opposed diversion of public funds from public education. This aligns with value 2 (''Prioritizing public school funding while restricting vouchers to low-income families who lack adequate local options'').',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Brooke_Lierman'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Dereck E. Davis / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '75378a96-8886-46eb-b0c1-37cbe2579265',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '75378a96-8886-46eb-b0c1-37cbe2579265',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Davis was chair of Maryland''s Economic Matters Committee for nearly two decades and has consistently supported legislation protecting working people including minimum wage increases and has served in the Legislative Black Caucus of Maryland. As Treasurer he has placed scrutiny on contracts with inadequate participation from historically disadvantaged business owners — consistent with value 2 (''strengthen civil rights enforcement and address systemic discrimination'').',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Dereck_E._Davis'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Dereck E. Davis / taxes / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '75378a96-8886-46eb-b0c1-37cbe2579265',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '75378a96-8886-46eb-b0c1-37cbe2579265',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Wikipedia describes Davis as a centrist, and his legislative record shows support for some moderate tax-funded investments while opposing unnecessary spending. His role as state treasurer focuses on fiscal soundness. The most defensible match for his documented record is value 3 (''Keep the current tax system mostly as-is with small adjustments to close unfair loopholes'') — centrist fiscal approach.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Dereck_E._Davis'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============================================================
-- NO DELETE BLOCK — MD officials had zero existing stances
-- (CONTEXT.md D-04: no deletion log needed for MD)
-- ============================================================

-- POST-STATE verification — inline checks (informational, does NOT block commit)
DO $$
DECLARE v_zero_count integer; v_unsourced_count integer;
BEGIN
  -- V3: MD officials still with zero stances (target: 0)
  SELECT COUNT(*) INTO v_zero_count
  FROM essentials.politicians p
  LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
  WHERE p.id = ANY (ARRAY[
    '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
    'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
    '60329719-1d5b-4bb4-8295-38ea18f6f378',
    'b26fb5d2-90eb-4108-8ce5-838df719473d',
    '75378a96-8886-46eb-b0c1-37cbe2579265'
  ]::uuid[]) AND pa.topic_id IS NULL;
  RAISE NOTICE 'POST-MIGRATION MD officials with zero stances: %', v_zero_count;

  -- MD-sourced-check: MD stances with no real source URL (target: 0)
  SELECT COUNT(*) INTO v_unsourced_count
  FROM inform.politician_answers pa
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE pa.politician_id = ANY (ARRAY[
    '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
    'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
    '60329719-1d5b-4bb4-8295-38ea18f6f378',
    'b26fb5d2-90eb-4108-8ce5-838df719473d',
    '75378a96-8886-46eb-b0c1-37cbe2579265'
  ]::uuid[])
  AND (
    pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL
    OR NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s(u) WHERE u IS NOT NULL AND trim(u) != '')
  );
  RAISE NOTICE 'POST-MIGRATION MD stances without source URL: %', v_unsourced_count;
END $$;

INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('279', '279_md_officials_stances')
ON CONFLICT (version) DO NOTHING;

COMMIT;
