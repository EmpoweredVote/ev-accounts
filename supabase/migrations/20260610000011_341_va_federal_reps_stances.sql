-- Phase 113: VA Federal House Reps Stances
-- Requirements covered: VAST-04, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-113-va-federal-reps.csv
--
-- Pre-write cross-check:
--   Politician UUIDs verified against migration 311 (VA federal reps seed)
--   existing stances: 0 (clean slate confirmed 2026-06-10)
--   INSERT INTO inform.politician_answers:  105
--   INSERT INTO inform.politician_context:  105
--   max_migration at authoring: 358 (highest disk file: 340)
--   Next free migration: 341
--
-- Honest skips (limited documented evidence for newer members):
--   Vindman (VA-07): 1 topic only (ukraine-support) — sworn in Jan 2025, limited voting record
--   McGuire (VA-09): 2 topics only (civil-rights, voting-rights) — sworn in Jan 2025, limited record
--   Subramanyam (VA-10): 1 topic only (same-sex-marriage) — sworn in Jan 2025, limited record
--   Walkinshaw (VA-11): 7 topics — special election Sept 2025, limited record
--
-- Politician UUIDs (from migration 311):
--   Rob Wittman       (VA-01, R, ext_id -5102001) -> 8f4379fc-ae32-4f6a-8773-ac1d723106a5
--   Jen Kiggans       (VA-02, R, ext_id -5102002) -> 512f27a4-e24f-4f62-a288-18b1e37db463
--   Bobby Scott       (VA-03, D, ext_id -5102003) -> cc499c9a-d165-4cd7-831d-51611339ac29
--   Jennifer McClellan(VA-04, D, ext_id -5102004) -> 3e7c0e88-5e35-4d71-8022-98731af6461b
--   Ben Cline         (VA-05, R, ext_id -5102005) -> e4deeac3-b172-473d-9696-a07d874f4795
--   Morgan Griffith   (VA-06, R, ext_id -5102006) -> 12eef223-444e-4bed-8081-f1fd26c43e42
--   Eugene Vindman    (VA-07, D, ext_id -5102007) -> 9a9d6b64-60b3-40c9-b213-4088d9a51e68
--   Don Beyer         (VA-08, D, ext_id -5102008) -> 0c1eef2f-19be-440f-b3d9-bd99d44ec056
--   John McGuire      (VA-09, R, ext_id -5102009) -> e603fa67-7992-409e-a1e2-1385c32dc217
--   Suhas Subramanyam (VA-10, D, ext_id -5102010) -> 98b05c70-2a30-48ea-81f3-b3216ffb0ca0
--   James Walkinshaw  (VA-11, D, ext_id -5102011) -> 32ea954f-8bfa-4d28-9f9e-12d1929cb853
--
-- Migration number: 341
-- Timestamp: 20260610000011
-- Applied: 2026-06-10

BEGIN;

-- ============================================================
-- ROB WITTMAN (VA-01, R)
-- Sources: https://en.wikipedia.org/wiki/Rob_Wittman
--          https://www.ontheissues.org/VA/Rob_Wittman.htm
-- ============================================================

-- Wittman / abortion / value=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'), 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Wittman co-sponsored a personhood bill in Congress that defined life as beginning at conception, effectively opposing all abortion. OnTheIssues records he supports "protecting life beginning with fertilization" and voted to ban federal health coverage that includes abortion.',
  ARRAY['https://en.wikipedia.org/wiki/Rob_Wittman', 'https://www.ontheissues.org/VA/Rob_Wittman.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Wittman / civil-rights / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Wittman holds a 36% rating from the NAACP and voted against reauthorization of the Violence Against Women Act. OnTheIssues classifies him as limiting federal civil rights enforcement to clear cases of discrimination.',
  ARRAY['https://www.ontheissues.org/VA/Rob_Wittman.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Wittman / climate-change / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Wittman opposes green energy prioritization and voted against EPA greenhouse gas regulations. He authored an offshore wind streamlining bill but overall opposes mandated energy transitions, favoring market-led approaches.',
  ARRAY['https://www.ontheissues.org/VA/Rob_Wittman.htm', 'https://en.wikipedia.org/wiki/Rob_Wittman'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Wittman / deportation / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'Wittman opposes birthright citizenship and voted to ban DREAMER immigrants from military service. He is rated A+ by anti-amnesty groups and opposes any pathway to citizenship for undocumented immigrants.',
  ARRAY['https://www.ontheissues.org/VA/Rob_Wittman.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Wittman / fossil-fuels / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Wittman supports expanding offshore oil drilling and opposes renewable energy tax incentives. He supports energy independence through expanded domestic fossil fuel production.',
  ARRAY['https://www.ontheissues.org/VA/Rob_Wittman.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Wittman / healthcare / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Wittman voted to repeal the Affordable Care Act and supported the 2017 American Health Care Act. He believes Congress should provide market-based alternatives and supports Medicare choice rather than expanding public coverage.',
  ARRAY['https://en.wikipedia.org/wiki/Rob_Wittman', 'https://www.ontheissues.org/VA/Rob_Wittman.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Wittman / immigration / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Wittman is strongly anti-amnesty, rated A+ by restrictionist groups. He opposes any pathway to citizenship for undocumented immigrants, supports border fence construction, and opposes birthright citizenship.',
  ARRAY['https://www.ontheissues.org/VA/Rob_Wittman.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Wittman / medicare/aid / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  'Wittman supports Medicare choice programs (partial privatization) and opposed CHIP expansion. OnTheIssues records him as supporting market-based Medicare alternatives over expanding the current public program.',
  ARRAY['https://www.ontheissues.org/VA/Rob_Wittman.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Wittman / same-sex-marriage / value=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'), 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Wittman supports a constitutional amendment defining marriage as exclusively between one man and one woman. He also opposed federal anti-gay hate crime enforcement. OnTheIssues records a consistent pattern opposing same-sex marriage recognition.',
  ARRAY['https://www.ontheissues.org/VA/Rob_Wittman.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Wittman / social-security / value=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'), 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'),
  'OnTheIssues rates Wittman 13–15% by senior advocacy groups, indicating strong preference for reducing Social Security benefits and transitioning toward private accounts.',
  ARRAY['https://www.ontheissues.org/VA/Rob_Wittman.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Wittman / tariffs / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'),
  'Wittman sponsored legislation imposing import fees on countries with undervalued currency and supports tariffs against currency-manipulating nations. He opposes broad free trade agreements.',
  ARRAY['https://www.ontheissues.org/VA/Rob_Wittman.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Wittman / taxes / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Wittman opposes the estate tax ("death tax"), supports replacing the income tax with FairTax, and consistently opposes higher taxes on wealthy individuals. He favors cutting taxes and scaling back public spending.',
  ARRAY['https://www.ontheissues.org/VA/Rob_Wittman.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Wittman / voting-rights / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8f4379fc-ae32-4f6a-8773-ac1d723106a5', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Wittman opposes voter registration expansion and opposed pandemic-era voting accommodations. He signed an amicus brief supporting the Texas v. Pennsylvania lawsuit and objected to certifying Pennsylvania''s 2020 electoral votes.',
  ARRAY['https://www.ontheissues.org/VA/Rob_Wittman.htm', 'https://en.wikipedia.org/wiki/Rob_Wittman'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- JEN KIGGANS (VA-02, R)
-- Sources: https://en.wikipedia.org/wiki/Jen_Kiggans
--          https://www.ontheissues.org/VA/Jen_Kiggans.htm
-- ============================================================

-- Kiggans / abortion / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Kiggans supports banning abortions after 15 weeks with exceptions for rape, incest, and maternal life protection. She endorsed the Supreme Court''s 2022 Dobbs decision overturning Roe v. Wade.',
  ARRAY['https://en.wikipedia.org/wiki/Jen_Kiggans', 'https://www.ontheissues.org/VA/Jen_Kiggans.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kiggans / civil-rights / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Kiggans states "gender identity isn''t a protected class" and opposes reparations on the basis of race. OnTheIssues classifies her as favoring limited civil rights enforcement rather than expanded protections.',
  ARRAY['https://www.ontheissues.org/VA/Jen_Kiggans.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kiggans / climate-change / value=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'), 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Kiggans supports an "all-of-the-above approach to energy independence" that includes renewables alongside fossil fuels. She opposes exclusively prioritizing green energy but doesn''t reject clean energy investment.',
  ARRAY['https://www.ontheissues.org/VA/Jen_Kiggans.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kiggans / deportation / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'Kiggans ran on "Do more to physically secure the southern border" and supports questioning immigration status in law enforcement contexts. She co-sponsored DIGNIDAD Act with strict enforcement provisions alongside any pathway elements.',
  ARRAY['https://www.ontheissues.org/VA/Jen_Kiggans.htm', 'https://en.wikipedia.org/wiki/Jen_Kiggans'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kiggans / fossil-fuels / value=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'), 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Kiggans supports an "all-of-the-above" energy strategy that maintains current fossil fuel production alongside renewable development. She does not call for new drilling permits nor for phasing out fossil fuels.',
  ARRAY['https://www.ontheissues.org/VA/Jen_Kiggans.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kiggans / healthcare / value=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'), 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Kiggans led bipartisan efforts to extend ACA subsidies set to expire December 2025, breaking with her party on this issue. She holds a track record of crossing party lines on healthcare access while opposing government mandates.',
  ARRAY['https://en.wikipedia.org/wiki/Jen_Kiggans'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kiggans / immigration / value=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'), 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Kiggans co-sponsored the DIGNIDAD Act, which would create a pathway to legal status for approximately 12 million undocumented immigrants alongside stricter border enforcement and work requirements — a bipartisan centrist position.',
  ARRAY['https://en.wikipedia.org/wiki/Jen_Kiggans'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kiggans / school-vouchers / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Kiggans strongly supports school choice and voucher programs. OnTheIssues records her as a consistent advocate for expanding voucher eligibility so parents can choose the school that best fits their child.',
  ARRAY['https://www.ontheissues.org/VA/Jen_Kiggans.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kiggans / social-security / value=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'), 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'),
  'Kiggans opposes Social Security privatization and has focused on nursing home reform for seniors. Her position is to maintain current programs with adjustments to ensure stability, not to transition to private accounts.',
  ARRAY['https://www.ontheissues.org/VA/Jen_Kiggans.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kiggans / taxes / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Kiggans strongly opposes higher taxes on wealthy individuals and businesses, stating "businesses are hurt by overbearing tax regulations." She supports cutting taxes and reducing regulatory burdens on employers.',
  ARRAY['https://www.ontheissues.org/VA/Jen_Kiggans.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kiggans / trans-athletes / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'trans-athletes'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'trans-athletes'),
  'In 2022, Kiggans introduced a bill to prohibit transgender girls from competing in girls'' sports. She supports requiring transgender athletes to compete on teams matching their biological sex assigned at birth.',
  ARRAY['https://en.wikipedia.org/wiki/Jen_Kiggans'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kiggans / voting-rights / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('512f27a4-e24f-4f62-a288-18b1e37db463', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Kiggans supports requiring photo ID to vote and ending ballot drop boxes. She called for a forensic audit of Virginia''s 2020 election results. OnTheIssues documents consistent opposition to expanded voting access.',
  ARRAY['https://www.ontheissues.org/VA/Jen_Kiggans.htm', 'https://en.wikipedia.org/wiki/Jen_Kiggans'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- BOBBY SCOTT (VA-03, D)
-- Sources: https://en.wikipedia.org/wiki/Bobby_Scott_(politician)
--          https://www.ontheissues.org/VA/Bobby_Scott.htm
-- ============================================================

-- Scott / abortion / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Scott holds a 100% rating from NARAL and has voted against all abortion restrictions throughout his career, including partial-birth bans and parental notification requirements. He consistently supports full, unrestricted access.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / civil-rights / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Scott holds a 100% ACLU rating and 97% NAACP rating. He voted for the Matthew Shepard Hate Crimes Act, the Don''t Ask Don''t Tell Repeal Act (2010), and the Equality Act (2019). He supports affirmative action and systemic discrimination remedies.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm', 'https://en.wikipedia.org/wiki/Bobby_Scott_(politician)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / climate-change / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Scott supports the Green New Deal framework and a target of 50% clean electricity by 2030. He opposes offshore drilling and consistently votes for aggressive clean energy investment.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / deportation / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'Scott is rated 0% by FAIR (anti-restriction immigration group). He opposes immigration enforcement targeting and supports protecting undocumented residents from removal, consistent with stopping most deportations.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / fossil-fuels / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Scott opposes offshore drilling and oil subsidies, consistent with stopping new fossil fuel permits. He is rated 95% by the League of Conservation Voters.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / healthcare / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Scott holds a 100% rating from the American Public Health Association. He backs a public option and ACA expansion, and previously worked to allow poor and children greater healthcare access. He is a member of the Medicare for All Caucus.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm', 'https://en.wikipedia.org/wiki/Bobby_Scott_(politician)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / immigration / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Scott supports a pathway to citizenship for undocumented immigrants and is rated 0% by FAIR. He opposes the border wall and enforcement targeting, supporting full access to public services regardless of legal status.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / medicare/aid / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  'Scott is a member of the Medicare for All Caucus and holds a 100% rating from the Alliance for Retired Americans. He opposes privatization and supports expanding Medicare coverage broadly.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm', 'https://en.wikipedia.org/wiki/Bobby_Scott_(politician)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / same-sex-marriage / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Scott voted NO on the constitutional amendment banning same-sex marriage and supported LGBTQ employment discrimination protections. He supports same-sex marriage nationwide while maintaining a 75% rating from HRC.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / school-vouchers / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Scott is strongly opposed to school vouchers and is rated 100% by the NEA (teachers union). He opposes any diversion of public education funding to private institutions.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / social-security / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'),
  'Scott opposes Social Security privatization and holds a 100% rating from the Alliance for Retired Americans. He sponsored keeping the standard CPI for benefits rather than a lower Chained CPI, protecting benefit levels.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / tariffs / value=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'), 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'),
  'Scott sponsored legislation imposing import fees on countries with undervalued currency and supports reviewing free trade agreements biennially for labor and human rights violations — selective tariff use, not blanket protectionism.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / taxes / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Scott holds a 100% rating from Citizens for Tax Justice. He supports a 30% minimum tax on incomes over $1 million, opposed all Bush tax cuts, and consistently favors significantly raising taxes on wealthy individuals and corporations.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Scott / voting-rights / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc499c9a-d165-4cd7-831d-51611339ac29', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Scott supports automatic voter registration for all eligible citizens and opposes photo ID requirements, which he states suppress the vote. He has a long record opposing barriers to ballot access.',
  ARRAY['https://www.ontheissues.org/VA/Bobby_Scott.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- JENNIFER McCLELLAN (VA-04, D)
-- Sources: https://en.wikipedia.org/wiki/Jennifer_McClellan
--          https://www.ontheissues.org/VA/Jennifer_McClellan.htm
-- ============================================================

-- McClellan / abortion / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'McClellan led the fight for Virginia''s Reproductive Health Protection Act and co-sponsored the 2019 Repeal Act to lift restrictions through viability. She opposes mandatory sonograms and consistently supports legal, accessible abortion through the second trimester.',
  ARRAY['https://en.wikipedia.org/wiki/Jennifer_McClellan', 'https://www.ontheissues.org/VA/Jennifer_McClellan.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- McClellan / civil-rights / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'McClellan led the Virginia Values Act banning LGBTQ discrimination and led ratification of the Equal Rights Amendment in Virginia. She served as vice chair of the Virginia Legislative Black Caucus and championed systemic civil rights reforms.',
  ARRAY['https://en.wikipedia.org/wiki/Jennifer_McClellan', 'https://www.ontheissues.org/VA/Jennifer_McClellan.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- McClellan / climate-change / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'McClellan passed the Virginia Clean Economy Act, which requires Virginia to achieve 100% clean electricity by 2045 and aggressively phases out coal. She prioritizes green energy investment and environmental justice policies.',
  ARRAY['https://en.wikipedia.org/wiki/Jennifer_McClellan', 'https://www.ontheissues.org/VA/Jennifer_McClellan.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- McClellan / deportation / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'McClellan sponsored legislation barring local police from questioning immigration status of crime victims and witnesses. She opposed requiring local police to enforce federal immigration laws.',
  ARRAY['https://www.ontheissues.org/VA/Jennifer_McClellan.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- McClellan / fossil-fuels / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'The Virginia Clean Economy Act McClellan passed phases out coal-fired power plants and requires halting new fossil fuel permits for electricity generation. She opposes allowing businesses to pollute and prioritizes fossil fuel phase-down.',
  ARRAY['https://en.wikipedia.org/wiki/Jennifer_McClellan', 'https://www.ontheissues.org/VA/Jennifer_McClellan.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- McClellan / healthcare / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'McClellan helped expand Medicaid coverage to over 400,000 Virginians and supports expanding the Affordable Care Act. She advocates ensuring everyone has affordable coverage through expanded public programs and regulated private insurance.',
  ARRAY['https://www.ontheissues.org/VA/Jennifer_McClellan.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- McClellan / immigration / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'McClellan supports a pathway to citizenship for undocumented immigrants and opposed requiring local police to enforce federal immigration laws. She bars questioning immigration status of crime victims and witnesses.',
  ARRAY['https://www.ontheissues.org/VA/Jennifer_McClellan.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- McClellan / medicare/aid / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  'McClellan helped expand Medicaid to over 400,000 Virginians, demonstrating strong support for expanding the program. She advocates lowering the Medicare eligibility age and significant Medicaid expansion.',
  ARRAY['https://www.ontheissues.org/VA/Jennifer_McClellan.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- McClellan / same-sex-marriage / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'McClellan led the Virginia Values Act banning LGBTQ discrimination and voted against religious exemptions from same-sex marriage laws. She consistently supports nationwide marriage equality.',
  ARRAY['https://en.wikipedia.org/wiki/Jennifer_McClellan', 'https://www.ontheissues.org/VA/Jennifer_McClellan.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- McClellan / school-vouchers / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'McClellan strongly opposes school vouchers and advocates fully funding public schools. She opposes any diversion of public education funds to private or religious institutions.',
  ARRAY['https://www.ontheissues.org/VA/Jennifer_McClellan.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- McClellan / taxes / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'McClellan favors higher taxes on wealthy individuals and stated that eliminating Virginia''s state income tax "would blow a huge hole in the budget." She supports moderately raising taxes on high earners to fund public services.',
  ARRAY['https://www.ontheissues.org/VA/Jennifer_McClellan.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- McClellan / voting-rights / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e7c0e88-5e35-4d71-8022-98731af6461b', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'McClellan led passage of the Virginia Voting Rights Act, calling it "a huge victory for our democracy." She opposes photo ID requirements and supports no-excuse absentee voting, automatic registration, and expanded access.',
  ARRAY['https://en.wikipedia.org/wiki/Jennifer_McClellan', 'https://www.ontheissues.org/VA/Jennifer_McClellan.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- BEN CLINE (VA-05, R)
-- Sources: https://en.wikipedia.org/wiki/Ben_Cline
--          https://www.ontheissues.org/VA/Ben_Cline.htm
-- ============================================================

-- Cline / abortion / value=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'), 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Cline is described as "staunchly anti-abortion" and states "life begins at conception." He introduced bills requiring fetal anesthesia information for late-term abortions and sponsored legislation protecting infant survivors of abortion. He consistently supports a full ban.',
  ARRAY['https://en.wikipedia.org/wiki/Ben_Cline', 'https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / civil-rights / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Cline states "religious freedom supersedes the right to same-sex marriage" and opposed extending the Equal Rights Amendment ratification deadline. FiveThirtyEight analysis aligns his voting record with far-right obstructionists.',
  ARRAY['https://en.wikipedia.org/wiki/Ben_Cline', 'https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / climate-change / value=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'), 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Cline states "reducing fossil fuels sacrifices economic development" and opposes prioritizing green energy. He voted against assisting rural electric renewable energy and consistently rejects climate-driven energy transition policies.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / deportation / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'Cline supports border wall construction and states illegal immigrants must exit the country and re-enter legally. He supports immigration enforcement bans against non-cooperating nations.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / fossil-fuels / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Cline supports natural gas pipeline development and voted against assisting rural electric renewable energy projects. He consistently opposes restricting fossil fuel production in favor of economic development.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / healthcare / value=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'), 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Cline opposes the ACA and favors repeal, believes states rather than the federal government should manage Medicaid, and opposes all federal vaccine mandates. He favors minimal federal involvement in healthcare coverage decisions.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / immigration / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Cline supports border wall construction and requires illegal immigrants to exit and re-enter legally. While he supports increasing some visa caps, his overall stance is restrictionist — making it harder to immigrate and limiting public services to those with legal status.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / medicare/aid / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  'Cline believes states rather than the federal government should run Medicaid and opposes federal expansion of healthcare programs. His position favors devolving Medicare/Medicaid to states and reducing federal coverage mandates.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / religious-freedom / value=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'), 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  'Cline explicitly states "religious freedom supersedes the right to same-sex marriage" and supports businesses acting on their religious beliefs about marriage. He advocates for broad religious exemptions from civil rights laws.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / same-sex-marriage / value=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'), 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Cline states "religious freedom supersedes the right to same-sex marriage" and supports businesses acting on religious beliefs about marriage. He opposes nationwide same-sex marriage recognition and supports exemptions based on religious opposition.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / school-vouchers / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Cline supports school choice and voucher programs, believing states should decide education standards. He supports expanding voucher eligibility so parents can choose the school best for their child.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / social-security / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'),
  'Cline supports raising the retirement age as part of future Social Security reform. He favors gradual benefit reductions for future recipients to ensure program solvency rather than expanding benefits.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / tariffs / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'),
  'Cline supports "higher tariffs now to achieve lower tariffs later" — using current tariffs as leverage to force other countries to reduce trade barriers, consistent with increasing tariffs on countries that don''t trade fairly.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / taxes / value=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'), 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Cline states "don''t increase taxes to balance budget" and strongly opposes higher taxes on wealthy individuals. He favors drastically cutting taxes and shrinking government rather than raising revenue.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cline / voting-rights / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4deeac3-b172-473d-9696-a07d874f4795', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Cline requires photo ID for voting and absentee ballots, opposes same-day registration and expanded voter access, and voted against certifying the 2020 presidential election.',
  ARRAY['https://www.ontheissues.org/VA/Ben_Cline.htm', 'https://en.wikipedia.org/wiki/Ben_Cline'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- MORGAN GRIFFITH (VA-06, R)
-- Sources: https://en.wikipedia.org/wiki/Morgan_Griffith
--          https://www.ontheissues.org/VA/Morgan_Griffith.htm
-- ============================================================

-- Griffith / abortion / value=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'), 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Griffith supports legalized abortion in the first trimester and to save the life of the mother, while favoring parental notification laws and banning partial-birth abortion and procedures after 20 weeks. His position permits first-trimester access but restricts beyond.',
  ARRAY['https://en.wikipedia.org/wiki/Morgan_Griffith', 'https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / civil-rights / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Griffith voted against reauthorizing the Violence Against Women Act and opposed legislation prohibiting sexual orientation discrimination for government employees. He supports "faith-based opposition to same-sex marriage" while limiting broader civil rights enforcement.',
  ARRAY['https://en.wikipedia.org/wiki/Morgan_Griffith', 'https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / climate-change / value=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'), 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Griffith is skeptical of climate science, signed the No Climate Tax Pledge, and stated cap-and-trade "will result in massive job cuts." He voted against EPA greenhouse gas regulations. OnTheIssues documents consistent rejection of climate change policies.',
  ARRAY['https://en.wikipedia.org/wiki/Morgan_Griffith', 'https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / deportation / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'Griffith is strongly anti-amnesty and voted to ban DREAMer immigrants from military service. He supports allowing immigration enforcement bans from non-cooperating nations and opposes pathways to citizenship.',
  ARRAY['https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / fossil-fuels / value=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'), 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Griffith champions fossil fuel interests, particularly coal in his SW Virginia district. He introduced amendments prohibiting EPA regulation of surface coal mining operations, supported the EPA Regulatory Relief Act, and urged reconsideration of offshore drilling bans.',
  ARRAY['https://en.wikipedia.org/wiki/Morgan_Griffith', 'https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / healthcare / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Griffith opposes the ACA and supports market-based reforms. He voted for the Ryan Budget offering Medicare choice and voted to defund the ACA during the 2013 government shutdown. He opposes government-run healthcare.',
  ARRAY['https://en.wikipedia.org/wiki/Morgan_Griffith', 'https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / immigration / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Griffith is strongly anti-amnesty, voted to allow Virginia to enforce federal immigration laws criminalizing employment of undocumented workers, and opposed measures increasing visas and protecting undocumented sponsors of unaccompanied children.',
  ARRAY['https://en.wikipedia.org/wiki/Morgan_Griffith', 'https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / medicare/aid / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  'Griffith voted for the Ryan Budget which proposed converting Medicare to a choice/voucher system and reducing Medicaid coverage. He favors partially privatizing Medicare through a premium support model.',
  ARRAY['https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / religious-freedom / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  'Griffith supports "faith-based opposition to same-sex marriage" and voted to kill a bill prohibiting sexual orientation discrimination for government employees. He favors religious exemptions from anti-discrimination laws.',
  ARRAY['https://en.wikipedia.org/wiki/Morgan_Griffith', 'https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / same-sex-marriage / value=5
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'), 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Griffith supported a constitutional amendment to prohibit same-sex marriage by defining marriage as between one man and one woman while serving in the Virginia House. He opposes nationwide same-sex marriage recognition.',
  ARRAY['https://en.wikipedia.org/wiki/Morgan_Griffith', 'https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / school-vouchers / value=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'), 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Griffith supports the DC Opportunity Scholarship program (targeted low-income vouchers) but OnTheIssues records mixed signals on broader private/religious school voucher programs. His overall position reflects targeted, means-tested vouchers rather than universal choice.',
  ARRAY['https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / social-security / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'),
  'Griffith supports raising the retirement age and reducing overseas military presence to cut federal deficits. Wikipedia documents his support for raising the retirement age as part of fiscal reform.',
  ARRAY['https://en.wikipedia.org/wiki/Morgan_Griffith', 'https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / tariffs / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'),
  'Griffith supports imposing tariffs against countries that manipulate currency and sponsored legislation imposing import fees on countries with undervalued currency. He supports increasing tariffs on countries that don''t trade fairly.',
  ARRAY['https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / taxes / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Griffith opposes higher taxes, signed the Taxpayer Protection Pledge, and voted for the Tax Cuts and Jobs Act of 2017 reducing the corporate rate from 35% to 21%. He consistently opposes tax increases and supports cutting taxes.',
  ARRAY['https://en.wikipedia.org/wiki/Morgan_Griffith', 'https://www.ontheissues.org/VA/Morgan_Griffith.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Griffith / voting-rights / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12eef223-444e-4bed-8081-f1fd26c43e42', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Griffith strongly opposes expanding voter registration and same-day registration. He voted against certifying the 2020 presidential election over concerns about pandemic-era voting rule changes.',
  ARRAY['https://www.ontheissues.org/VA/Morgan_Griffith.htm', 'https://en.wikipedia.org/wiki/Morgan_Griffith'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- EUGENE VINDMAN (VA-07, D)
-- Source: https://en.wikipedia.org/wiki/Eugene_Vindman
-- NOTE: Sworn in Jan 2025 (119th Congress). Limited federal voting record.
-- Only 1 topic documented with sufficient sourced evidence.
-- ============================================================

-- Vindman / ukraine-support / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9a9d6b64-60b3-40c9-b213-4088d9a51e68', (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9a9d6b64-60b3-40c9-b213-4088d9a51e68', (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support'),
  'Prior to taking office, Vindman co-founded Trident Support, an organization providing weapon maintenance and training within Ukraine, and directed the Atrocity Crimes Advisory group focused on Ukraine. His post-military career reflects a deep commitment to significantly increasing military aid to Ukraine until complete victory.',
  ARRAY['https://en.wikipedia.org/wiki/Eugene_Vindman'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- DON BEYER (VA-08, D)
-- Sources: https://en.wikipedia.org/wiki/Don_Beyer
--          https://www.ontheissues.org/VA/Don_Beyer.htm
-- ============================================================

-- Beyer / abortion / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Beyer is strongly pro-choice, stating "politicians have no business interfering in the right to choose." He opposes all anti-abortion limitations on services and supports legal, accessible abortion.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Beyer / campaign-finance / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Beyer supports campaign finance reform via voter vouchers (democracy vouchers for every eligible voter) and backs making Election Day a national holiday. He supports strictly limiting corporate donations and dark money in politics.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Beyer / civil-rights / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Beyer supports the Paycheck Fairness Act for equal pay and backs LGBTQ equality including DOMA repeal and the Employment Non-Discrimination Act (ENDA). He has authored police accountability legislation including the Cost of Police Misconduct Act.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm', 'https://en.wikipedia.org/wiki/Don_Beyer'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Beyer / climate-change / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Beyer supports reducing carbon emissions through a carbon pollution tax, voted to ban offshore oil drilling in the Gulf of Mexico, and targets 50% clean and carbon-free electricity by 2030. He opposes fossil fuel expansion.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Beyer / deportation / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'Beyer fully supports the DREAM Act, voted to legalize DREAMer immigrants through military service, and supports legal representation for undocumented children facing deportation. He opposes deportation of established residents.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Beyer / fossil-fuels / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Beyer voted YES on banning offshore oil drilling in the Gulf of Mexico and opposes fossil fuel expansion. He supports stopping new permits for fossil fuel drilling as part of the clean energy transition.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Beyer / healthcare / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Beyer backs improving and expanding the Affordable Care Act and supports a public option. He argues the GOP cannot defeat the ACA and advocates for ensuring everyone has affordable coverage through expanded programs.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Beyer / immigration / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Beyer fully supports the DREAM Act and path to citizenship for undocumented residents, voted to legalize DREAMer immigrants through military service, supports increasing both high-skill and family-based visa caps, and supports legal representation for children facing deportation.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Beyer / same-sex-marriage / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Beyer backs LGBTQ equality, DOMA repeal, and the Employment Non-Discrimination Act. He supports same-sex marriage nationwide while protecting some organizations'' right to decline participation.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Beyer / school-vouchers / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Beyer opposes private and religious school vouchers, supports the Department of Education, and advocates making community college free. He favors fully funding public schools over diverting money to private institutions.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Beyer / social-security / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security'),
  'Beyer explicitly opposes any effort to privatize Social Security. He supports expanding benefits and removing the income cap on payroll taxes to strengthen funding.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Beyer / taxes / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Beyer supports restoring the highest personal income tax rate to 39.6%, raising the estate tax to 1990s levels, and closing corporate tax loopholes. He advocates moderately raising taxes on wealthy individuals and large companies.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Beyer / voting-rights / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c1eef2f-19be-440f-b3d9-bd99d44ec056', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Beyer supports automatic voter registration, backs making Election Day a national holiday, and supports campaign finance reform to reduce dark money. OnTheIssues records consistent support for expanded ballot access.',
  ARRAY['https://www.ontheissues.org/VA/Don_Beyer.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- JOHN McGUIRE (VA-09, R)
-- Source: https://en.wikipedia.org/wiki/Virginia%27s_5th_congressional_district
--         https://en.wikipedia.org/wiki/John_McGuire_(Virginia_politician)
-- NOTE: Sworn in Jan 2025 (119th Congress). Limited federal record.
-- Only 2 topics documented with sufficient sourced evidence.
-- ============================================================

-- McGuire / civil-rights / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e603fa67-7992-409e-a1e2-1385c32dc217', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e603fa67-7992-409e-a1e2-1385c32dc217', (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'McGuire publicly opposed Virginia''s ratification of the Equal Rights Amendment. He also cast the sole vote in the Virginia Senate against a ban on child marriage in 2024. His record indicates limiting rather than expanding civil rights protections.',
  ARRAY['https://en.wikipedia.org/wiki/John_McGuire_(Virginia_politician)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- McGuire / voting-rights / value=4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e603fa67-7992-409e-a1e2-1385c32dc217', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'), 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e603fa67-7992-409e-a1e2-1385c32dc217', (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'McGuire attended Stop the Steal rallies in 2020 and claimed the COVID-19 pandemic was a "plan-demic" designed to manipulate voting laws. He attended Trump''s January 6 rally. His record reflects opposition to expanded mail-in voting and election access.',
  ARRAY['https://en.wikipedia.org/wiki/John_McGuire_(Virginia_politician)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- SUHAS SUBRAMANYAM (VA-10, D)
-- Source: https://en.wikipedia.org/wiki/Suhas_Subramanyam
-- NOTE: Sworn in Jan 2025 (119th Congress). Limited federal record.
-- Only 1 topic documented with sufficient sourced evidence.
-- ============================================================

-- Subramanyam / same-sex-marriage / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98b05c70-2a30-48ea-81f3-b3216ffb0ca0', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98b05c70-2a30-48ea-81f3-b3216ffb0ca0', (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Subramanyam is a member of the Congressional Equality Caucus, which advocates for full LGBTQ equality including nationwide recognition of same-sex marriage. Caucus membership is an active legislative commitment documented in his Wikipedia page.',
  ARRAY['https://en.wikipedia.org/wiki/Suhas_Subramanyam'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- JAMES WALKINSHAW (VA-11, D)
-- Source: https://en.wikipedia.org/wiki/James_Walkinshaw
-- NOTE: Won special election Sept 2025. Limited federal record.
-- ============================================================

-- Walkinshaw / abortion / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Walkinshaw is pro-choice and supports abortion rights. Wikipedia documents his support for legal abortion access as part of his Democratic platform.',
  ARRAY['https://en.wikipedia.org/wiki/James_Walkinshaw'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Walkinshaw / deportation / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'Walkinshaw states "Trump''s agenda to terrorize and deport law-abiding families is a distraction from focusing on the small number who commit violent crimes." He supports deporting only people convicted of serious violent crimes.',
  ARRAY['https://en.wikipedia.org/wiki/James_Walkinshaw'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Walkinshaw / healthcare / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Walkinshaw opposes the One Big Beautiful Bill Act, stating that "over 320,000 Virginians would lose healthcare access" as a result and pledging to work toward its repeal. He supports ensuring everyone has affordable coverage.',
  ARRAY['https://en.wikipedia.org/wiki/James_Walkinshaw'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Walkinshaw / immigration / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Walkinshaw supports comprehensive immigration reform and a path to citizenship for undocumented immigrants. He criticizes Trump''s mass deportation approach and supports keeping most legal immigration pathways open.',
  ARRAY['https://en.wikipedia.org/wiki/James_Walkinshaw'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Walkinshaw / school-vouchers / value=1
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'), 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Walkinshaw believes curriculum decisions "are made and should be made at the local and to some degree state level" and opposes efforts to dismantle the Department of Education. He supports fully funding public schools.',
  ARRAY['https://en.wikipedia.org/wiki/James_Walkinshaw'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Walkinshaw / tariffs / value=3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'), 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'),
  'Walkinshaw opposes Trump''s broad tariff policies but acknowledges China "has been operating unfairly" within global trade systems. His position supports using tariffs selectively to protect key American industries rather than broad protectionism.',
  ARRAY['https://en.wikipedia.org/wiki/James_Walkinshaw'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Walkinshaw / ukraine-support / value=2
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support'), 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('32ea954f-8bfa-4d28-9f9e-12d1929cb853', (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support'),
  'Walkinshaw supports providing military aid to Ukraine and has criticized Trump''s inconsistent support as beneficial to Russia and harmful to European allies. He supports continuing current levels of military and economic aid.',
  ARRAY['https://en.wikipedia.org/wiki/James_Walkinshaw'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Verification block scoped to VA federal reps (external_id BETWEEN -5102011 AND -5102001)
-- ============================================================
DO $$
DECLARE
  rep_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO rep_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5102011 AND -5102001;
  RAISE NOTICE 'VA federal reps with stances: %', rep_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5102011 AND -5102001
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA federal rep stances: %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found -- migration blocked';
END $$;

COMMIT;
