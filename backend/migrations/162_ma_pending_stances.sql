-- Migration 162: MA 2026-05-17 pending stances
-- Sal N. DiDomenico (c7e94dda — canonical record with 18 existing answers): 13 topics
-- Deborah B. Goldberg (eb88bdd6): 2 topics

-- Sal DiDomenico — healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
  'DiDomenico has sponsored multiple MassHealth expansion bills including S.854 (continuity of coverage for children), S.855 (equitable health coverage for children), S.856 (access for dually eligible Medicare/Medicaid individuals), and S.852 (restoring health safety net eligibility to prevent medical debt). His approach consistently expands public coverage and regulated private options rather than advocating for full single-payer.',
  ARRAY['https://malegislature.gov/Bills/194/S854', 'https://malegislature.gov/Bills/194/S856', 'https://malegislature.gov/Bills/194/S852'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sal DiDomenico — childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'DiDomenico has sponsored S.339 (high-quality pre-K education), S.341 (expanding access to family/friend/neighbor childcare), S.1956 (employer-provided childcare tax credits), S.346 (commission to study early education funding), and S.344 (support for expectant/parenting students), reflecting a strong commitment to significantly expanding childcare subsidies and public investment in early education.',
  ARRAY['https://malegislature.gov/Bills/194/S339', 'https://malegislature.gov/Bills/194/S341', 'https://malegislature.gov/Bills/194/S1956'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sal DiDomenico — climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
  'DiDomenico co-authored a May 2025 op-ed defending Massachusetts climate resilience projects against federal cuts, writing ''we can''t allow it to be a fatal blow'' to climate infrastructure. He also sponsored S.572 (sustainable and equitable funding for climate adaptation and mitigation) and S.3846 (Mystic River climate resilience), reflecting sustained investment in clean energy while not calling for an immediate phase-out of fossil fuels.',
  ARRAY['https://commonwealthbeacon.org/energy-environment/we-cant-let-trump-cuts-stop-critical-climate-resilience-projects/', 'https://malegislature.gov/Bills/194/S572', 'https://malegislature.gov/Bills/194/S3846'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sal DiDomenico — fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', 'a22215c3-6693-4bc2-b248-01aebba14570', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', 'a22215c3-6693-4bc2-b248-01aebba14570',
  'DiDomenico co-authored a 2020 op-ed criticizing the Baker administration for approving a gas power plant in an environmental justice community, but his legislative record focuses on climate resilience investment rather than banning or stopping new fossil fuel permits outright. His approach aligns with maintaining current environmental regulations while pushing for cleaner alternatives.',
  ARRAY['https://commonwealthbeacon.org/energy-environment/we-cant-let-trump-cuts-stop-critical-climate-resilience-projects/', 'https://malegislature.gov/Bills/194/S572'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sal DiDomenico — immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
  'DiDomenico publicly advocates for the Safe Communities Act (S.1681/H.2580), which would prohibit local law enforcement from inquiring about immigration status and limit cooperation with ICE. He represents Everett and Chelsea, communities with large immigrant populations, and is quoted as calling ICE ''a rogue agency'' while supporting expanded legal status and basic needs assistance for immigrants (S.117).',
  ARRAY['https://commonwealthbeacon.org/tag/sal-didomenico/', 'https://malegislature.gov/Bills/194/S117', 'https://malegislature.gov/Bills/194/S1681'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sal DiDomenico — housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '669cac97-66a6-4087-b036-936fbe62efb3',
  'DiDomenico sponsored S.968 (statewide right to counsel for evictions to prevent homelessness), S.969 (accessory dwelling unit trust fund), S.971 (housing development incentive reform), and S.956 (eviction record sealing/HOMES Act) — collectively reflecting support for rent assistance, expanded affordable housing programs, and strong tenant protections including legal aid.',
  ARRAY['https://malegislature.gov/Bills/194/S968', 'https://malegislature.gov/Bills/194/S969', 'https://malegislature.gov/Bills/194/S971'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sal DiDomenico — homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'DiDomenico sponsored S.968, which establishes a statewide right-to-counsel program for evictions to prevent homelessness, emphasizing that evictions contribute to housing instability and disrupted schooling. His approach prioritizes legal assistance and outreach as the primary homelessness prevention strategy rather than criminalization.',
  ARRAY['https://malegislature.gov/Bills/194/S968'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sal DiDomenico — taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
  'DiDomenico sponsored S.1957 (''Act supporting families through enhanced tax credits'') and S.1958 (tax incentives for micro businesses to hire formerly incarcerated individuals), along with S.118 (''Act lifting kids out of deep poverty''), reflecting a pattern of supporting targeted tax relief for families and low-income workers funded by higher taxes on the wealthy.',
  ARRAY['https://malegislature.gov/Bills/194/S1957', 'https://malegislature.gov/Bills/194/S118', 'https://commonwealthbeacon.org/economy/give-all-employees-access-to-retirement-savings-accounts/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sal DiDomenico — jail-capacity
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
  'Massachusetts''s 2018 criminal justice reform bill (H.4012, Chapter 72) passed the Senate unanimously 37-0 and DiDomenico voted yes. DiDomenico also sponsors S.1065 (prohibiting deception in juvenile interrogations), S.116 (updating juvenile justice policy), and S.1958 (tax incentives to hire formerly incarcerated individuals), reflecting a consistent approach of reducing incarceration through diversion and reform rather than expanding jail capacity.',
  ARRAY['https://malegislature.gov/Bills/190/H4012', 'https://malegislature.gov/Bills/194/S1065', 'https://malegislature.gov/Bills/194/S116'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sal DiDomenico — judicial-criminal-justice
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '9db07b16-1076-4b7d-ad89-ebe7b51f4336', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
  'DiDomenico''s legislative record — including the 2018 criminal justice reform bill (passed unanimously), bills prohibiting deception in juvenile interrogations (S.1065), updating juvenile justice policy (S.116), and creating tax incentives for hiring formerly incarcerated individuals (S.1958) — reflects a ''fair chance to make things right'' philosophy prioritizing treatment, community reentry, and diversion over punishment.',
  ARRAY['https://malegislature.gov/Bills/190/H4012', 'https://malegislature.gov/Bills/194/S1065', 'https://malegislature.gov/Bills/194/S1958'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sal DiDomenico — judicial-access-to-justice
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '9d45acaf-1ba4-4cb8-95e1-5ed985223b91', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
  'DiDomenico sponsored S.968 (right to counsel in eviction proceedings statewide) and S.1068 (''Act providing for equity within the judicial branch''), reflecting a philosophy that court access should be broadly available. His eviction right-to-counsel bill specifically addresses the power imbalance when low-income tenants face corporate landlords without legal representation.',
  ARRAY['https://malegislature.gov/Bills/194/S968', 'https://malegislature.gov/Bills/194/S1068'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sal DiDomenico — judicial-transparency
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '6674d87e-999d-433a-aab7-3f626f59fd5f', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '6674d87e-999d-433a-aab7-3f626f59fd5f',
  'DiDomenico sponsored S.1068 (''Act providing for equity within the judicial branch'') and his legislative record emphasizes accountability in public institutions. His support for civil rights enforcement restoration (S.1064) and criminal justice transparency (S.1066, addressing discriminatory police reporting) reflect a default-to-openness philosophy with compelling reasons required to limit public access.',
  ARRAY['https://malegislature.gov/Bills/194/S1068', 'https://malegislature.gov/Bills/194/S1064', 'https://malegislature.gov/Bills/194/S1066'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sal DiDomenico — judicial-police-accountability
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '7bad33eb-e93e-4d94-8822-97212d49bde5', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536', '7bad33eb-e93e-4d94-8822-97212d49bde5',
  'DiDomenico co-authored a 2020 op-ed calling for the Environmental Justice Act and criticizing administration decisions that harmed communities of color, and sponsored S.1066 (''Act addressing discriminatory police reporting'') requiring accountability for racially biased police practices. His support for the 2020 police reform bill and civil rights enforcement restoration (S.1064) reflect a settle-valid-claims approach to government accountability.',
  ARRAY['https://malegislature.gov/Bills/194/S1066', 'https://malegislature.gov/Bills/194/S1064'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Deborah Goldberg — childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'Goldberg''s campaign site explicitly lists awarding grants to new childcare providers and developing new revenue sources for early education costs as core Treasurer initiatives. This reflects a significant public investment approach targeting affordability for working families — major subsidies and grants rather than a fully universal publicly funded system.',
  ARRAY['https://www.debgoldberg.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Deborah Goldberg — housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb88bdd6-d1c7-4e08-aff8-bb7517ad24b5', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Goldberg''s campaign site states she is ''combating housing affordability head-on by supporting investments in shovel-ready projects throughout the state.'' As Treasurer she directs state financial resources toward affordable housing investment — a targeted subsidy/investment approach rather than direct public housing construction or rent regulation.',
  ARRAY['https://www.debgoldberg.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
