-- Migration 597: Quincy city official stances (Phase 117-03)
-- 29 stances across 9 officials (Noel DiBona honest-skipped — no accessible public record)
-- Sources: wgbh.org, cbsnews.com/boston, nbcboston.com, quincyma.gov,
--          cms7files1.revize.com (Quincy City Council meeting minutes Jan–Apr 2026)

-- ============================================================
-- Thomas P. Koch (Mayor) — id: 9fb47aff-9128-4214-af78-a4d8321f9f83
-- ============================================================

-- economic-development = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9fb47aff-9128-4214-af78-a4d8321f9f83', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9fb47aff-9128-4214-af78-a4d8321f9f83',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  $$Koch led an aggressive downtown Quincy revitalization that attracted approximately $250M in private investment alongside $120M in local borrowing, with MBTA station upgrades and mixed-use towers. He describes maximizing 'undervalued real estate' through large developer partnerships. This is active recruitment of major investment with significant infrastructure backing — matching the chair of competing actively for major employers with significant infrastructure investment.$$,
  ARRAY['https://www.wgbh.org/news/local/2018-05-13/a-new-vision-for-quincy-the-city-goes-tall-with-redevelopment']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- growth-and-development = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9fb47aff-9128-4214-af78-a4d8321f9f83', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9fb47aff-9128-4214-af78-a4d8321f9f83',
  'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
  $$Koch paired Quincy's downtown revitalization with proactive infrastructure investment — $120M in local borrowing, MBTA station upgrades, and new public spaces — to attract and absorb development. He streamlined the process for major downtown projects and recruited private capital aggressively. This matches 'streamline permitting, reduce fees, and actively recruit development to grow the city's tax base.'$$,
  ARRAY['https://www.wgbh.org/news/local/2018-05-13/a-new-vision-for-quincy-the-city-goes-tall-with-redevelopment']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9fb47aff-9128-4214-af78-a4d8321f9f83', '669cac97-66a6-4087-b036-936fbe62efb3', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9fb47aff-9128-4214-af78-a4d8321f9f83',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  $$The Quincy downtown redevelopment under Koch produced primarily market-rate housing — a 15-story residential tower with 124 apartments. No affordable housing requirements were noted in the project. Koch's stated approach is to maximize private investment in underdeveloped land, leaning on private developers rather than affordability mandates. This best matches cutting regulations and zoning rules so private developers can build more housing.$$,
  ARRAY['https://www.wgbh.org/news/local/2018-05-13/a-new-vision-for-quincy-the-city-goes-tall-with-redevelopment']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9fb47aff-9128-4214-af78-a4d8321f9f83', '4938766b-b45a-46e3-93bd-b8b30651271a', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9fb47aff-9128-4214-af78-a4d8321f9f83',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  $$Koch's consistent position opposing the Long Island Bridge — which would have served a large homeless shelter and addiction treatment campus — reflects a view that prioritizes neighborhood protection over expanding access to shelter services. He did not advocate for decriminalizing public sleeping or investing in expanded regional capacity. His framing is about limiting the footprint of such services near Quincy, aligning with prohibiting encampments on public property with graduated warnings and penalties.$$,
  ARRAY['https://www.wgbh.org/news/local/2018-05-18/battle-of-the-bridge-a-sit-down-with-quincy-mayor-tom-koch', 'https://www.wgbh.org/news/local/2018/10/17/a-proposed-boston-harbor-bridge-creates-a-divide']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness-response = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9fb47aff-9128-4214-af78-a4d8321f9f83', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9fb47aff-9128-4214-af78-a4d8321f9f83',
  '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  $$Koch vigorously opposed rebuilding the Long Island Bridge that would connect Boston to an addiction treatment and homeless services campus, citing Quincy's interests. He argued Quincy already 'met the needs of the people we serve' on opioids and did not need additional regional recovery capacity nearby. His opposition prioritized neighborhood protection over expanding regional shelter capacity. This most closely matches enforcing anti-camping ordinances as the primary tool while maintaining basic outreach programs.$$,
  ARRAY['https://www.wgbh.org/news/local/2018-05-18/battle-of-the-bridge-a-sit-down-with-quincy-mayor-tom-koch', 'https://www.wgbh.org/news/local/2018/10/17/a-proposed-boston-harbor-bridge-creates-a-divide']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- religious-freedom = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9fb47aff-9128-4214-af78-a4d8321f9f83', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9fb47aff-9128-4214-af78-a4d8321f9f83',
  '6b9ba6d9-1001-43f5-b073-4d37130696fd',
  $$Koch championed installing Catholic patron saint statues (St. Michael and St. Florian) on Quincy city buildings over public opposition and an ACLU lawsuit. In a court affidavit he stated 'the selection had nothing to do with Catholic sainthood' but the SJC found the process was conducted without public input. Koch appealed the injunction, saying 'We will appeal this ruling so our city can continue to celebrate and inspire the men and women who protect us.' His actions reflect protecting faith-based symbolism in government spaces, aligning with protecting religious freedom and allowing faith-based exemptions from laws that conflict with sincere religious beliefs.$$,
  ARRAY['https://www.wgbh.org/news/local/2025-10-14/judge-blocks-quincy-from-installing-controversial-statues-as-lawsuit-moves-forward', 'https://www.cbsnews.com/boston/news/quincy-saint-statues-public-safety-court-lawsuit/', 'https://www.wgbh.org/news/local/2026-05-06/sjc-weighs-dispute-over-saint-statues-in-quincy']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- city-sanitation = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9fb47aff-9128-4214-af78-a4d8321f9f83', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9fb47aff-9128-4214-af78-a4d8321f9f83',
  '7687de4f-4d0b-462a-b803-bdfb23b16b42',
  $$Quincy's Department of Public Works provides trash collection, street sweeping, snow plowing, recycling, yard waste, and hazardous waste services to residents. The city emphasizes community cooperation in maintaining service quality. Koch has not articulated a transformative expansion or privatization stance on sanitation — the DPW operates in a standard municipal model. This fits maintaining current sanitation services while enforcing anti-dumping laws.$$,
  ARRAY['https://www.quincyma.gov/departments/public_works/index.php']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9fb47aff-9128-4214-af78-a4d8321f9f83', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9fb47aff-9128-4214-af78-a4d8321f9f83',
  '1935979c-b290-42e4-baa5-8cb0138b4ffa',
  $$Quincy's Natural Resources Department conducts annual tree planting (600+ trees per year), manages urban forests with certified arborists, and holds 'Cleaner Greener Quincy' events. Koch's development record includes MBTA transit upgrades and Hancock-Adams Green public space creation alongside private development — consistent environmental standards with reasonable developer flexibility.$$,
  ARRAY['https://www.quincyma.gov/departments/natural_resources/index.php', 'https://www.wgbh.org/news/local/2018-05-13/a-new-vision-for-quincy-the-city-goes-tall-with-redevelopment']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Anne Mahoney (At-Large Councillor) — id: 40769774-6c39-42bd-8f4d-4f26a6c36770
-- Sources: Quincy City Council meeting minutes Jan–Apr 2026
-- ============================================================

-- economic-development = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('40769774-6c39-42bd-8f4d-4f26a6c36770', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '40769774-6c39-42bd-8f4d-4f26a6c36770',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  $$Mahoney authored Ordinance 2026-009 to strengthen the City Auditor's independent oversight powers, and co-authored multiple fiscal transparency resolves covering ARP spending, pension accountability, city property transactions, and comprehensive debt review. She supported targeted CPC historic preservation funding and a solar PPA with community benefit safeguards. Her consistent focus on accountability and careful public investment aligns with targeted incentives with community benefit agreements and job quality requirements, not aggressive developer recruitment.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_02.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('40769774-6c39-42bd-8f4d-4f26a6c36770', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '40769774-6c39-42bd-8f4d-4f26a6c36770',
  '1935979c-b290-42e4-baa5-8cb0138b4ffa',
  $$Mahoney was present and voted YES on a unanimous 9-0 approval of a solar energy lease for Squantum Elementary School (April 6, 2026), designed to achieve net-zero energy. Councillors expressed support for renewable energy and net-zero goals. No evidence of stronger environmental restrictions on development or of weakening standards — consistent standards with reasonable developer flexibility.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- city-sanitation = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('40769774-6c39-42bd-8f4d-4f26a6c36770', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '40769774-6c39-42bd-8f4d-4f26a6c36770',
  '7687de4f-4d0b-462a-b803-bdfb23b16b42',
  $$On the April 6, 2026 sewer/discharge ordinance, Mahoney suggested and successfully moved an amendment to add written warnings as the first offense for discharge violations — a balanced enforcement-plus-education approach. During the March 2, 2026 snow operations review, she questioned pedestrian walkability around schools and bus stops and focused on improvement. Neither pure enforcement-first nor major sanitation staffing expansion; aligns with maintaining current services while enforcing anti-dumping laws.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_02.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('40769774-6c39-42bd-8f4d-4f26a6c36770', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '40769774-6c39-42bd-8f4d-4f26a6c36770',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  $$Mahoney supported the $2,646,730 firefighter turnout gear appropriation (voted 9-0 on March 23, 2026) and moved fiscal safeguard amendments ensuring PFAS litigation recoveries and grant funds offset bond costs. She engaged seriously with chemical safety and cost-benefit analysis without opposing the investment. No motions to redirect police budget to social services and no motions to expand police staffing — aligns with keeping current public safety funding while adding health and safety improvements.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_23.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_16.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Ziqiang Yuan (At-Large Councillor) — id: 560e1838-9f8f-4227-baa4-060ea62d38c0
-- ============================================================

-- city-sanitation = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('560e1838-9f8f-4227-baa4-060ea62d38c0', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '560e1838-9f8f-4227-baa4-060ea62d38c0',
  '7687de4f-4d0b-462a-b803-bdfb23b16b42',
  $$In the April 6, 2026 Joint Public Works and Ordinance Committee, Yuan submitted an amendment to the FOG/sewer ordinance adding a "City Responsibility and Fair Implementation" section with written warnings before fines and multilingual educational outreach requirements. She opposed removing the written-warning step, arguing the first $2,500 fine without notice was too severe. She also raised snow removal enforcement with senior/disability exemptions (March 2 meeting). These positions represent maintaining enforcement while adding procedural fairness protections — aligns with maintaining current sanitation services while enforcing anti-dumping laws.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_02.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- economic-development = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('560e1838-9f8f-4227-baa4-060ea62d38c0', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '560e1838-9f8f-4227-baa4-060ea62d38c0',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  $$At the April 6, 2026 council meeting, Yuan proposed an amendment requiring a formal, legally binding written agreement with the state (DCR) before releasing Community Preservation Committee funds for the Dorothy Quincy Homestead project. She questioned the lack of competitive bidding and whether the city should take on costs for a state-owned property without guaranteed reimbursement. She also co-sponsored a review of short-term rental regulation enforcement (2026-033). This cautious, accountability-focused stance — requiring community benefit agreements and clear cost/responsibility terms — matches targeted incentives with community benefit requirements.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_02_02.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('560e1838-9f8f-4227-baa4-060ea62d38c0', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '560e1838-9f8f-4227-baa4-060ea62d38c0',
  '1935979c-b290-42e4-baa5-8cb0138b4ffa',
  $$Yuan voted 9-0 in favor of a 20-year solar PPA for Squantum Elementary School (April 6, 2026) — part of the city's net-zero energy school initiative. She also raised chemical safety concerns (PFAS, brominated flame retardants) regarding firefighter gear purchases in March 2026, requesting chemical transparency and protective contract language. These actions reflect consistent environmental standards applied to both energy and procurement, with reasonable flexibility given to project developers and existing supplier constraints.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_16.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_23.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('560e1838-9f8f-4227-baa4-060ea62d38c0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '560e1838-9f8f-4227-baa4-060ea62d38c0',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  $$Yuan engaged substantively with firefighter PPE safety at the March 16 and March 23, 2026 Finance Committee meetings — seeking disclosure of flame retardant chemicals replacing PFAS, requesting protective purchase-agreement language, and raising physical burn risks from PFAS-free gear. She ultimately supported the $2.6M firefighter turnout gear appropriation. She also co-sponsored resolves investigating the Council on Aging department head theft (2026-056). These actions reflect keeping current public safety funding while adding accountability and safety safeguards.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_16.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_23.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- David Jacobs (Ward 1 Councillor) — id: b56123a8-952f-4c4a-aa4e-7e8c2fa92de1
-- ============================================================

-- city-sanitation = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b56123a8-952f-4c4a-aa4e-7e8c2fa92de1', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b56123a8-952f-4c4a-aa4e-7e8c2fa92de1',
  '7687de4f-4d0b-462a-b803-bdfb23b16b42',
  $$At the April 6, 2026 Joint Public Works and Ordinance Committee, Jacobs explicitly opposed the written-warning amendment to the sewer discharge ordinance, stating he does not support it and "wants the DPW to have the ability to fine those who blatantly violate city ordinances." He voted against softening enforcement language (amendment failed 1-8). His position prioritizes giving the department maximum enforcement authority over businesses and property owners who violate city ordinances.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b56123a8-952f-4c4a-aa4e-7e8c2fa92de1', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b56123a8-952f-4c4a-aa4e-7e8c2fa92de1',
  '1935979c-b290-42e4-baa5-8cb0138b4ffa',
  $$Jacobs moved the referral of 2026-017 (solar energy PPA for Squantum Elementary School) on January 20, 2026, and moved the final 9-0 approval on April 6, 2026 as Oversight Committee Chair. The project achieves net-zero energy for the school. He also seconded the referral of stormwater enforcement ordinances in January 2026. His actions reflect consistent support for clean energy standards and environmental enforcement with no evidence of pushing for more restrictive or more permissive development standards.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_01_20.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Richard Ash (Ward 2 Councillor) — id: 0f16bef4-ff4c-4200-a025-cd47548fc0c6
-- ============================================================

-- city-sanitation = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f16bef4-ff4c-4200-a025-cd47548fc0c6', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0f16bef4-ff4c-4200-a025-cd47548fc0c6',
  '7687de4f-4d0b-462a-b803-bdfb23b16b42',
  $$As Public Works Committee Chair, Ash drove the sewer discharge and stormwater enforcement ordinances (2026-010, 2026-011) through committee and moved final 9-0 approval on April 6, 2026. At the April 6 committee meeting he stated he had personally experienced repeat FOG discharge violations in his ward and that "the fines need to be substantial enough to deter the behavior." He opposed weakening enforcement language in favor of giving DPW maximum deterrence capacity.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_01_20.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f16bef4-ff4c-4200-a025-cd47548fc0c6', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0f16bef4-ff4c-4200-a025-cd47548fc0c6',
  '1935979c-b290-42e4-baa5-8cb0138b4ffa',
  $$Ash introduced and moved the sewer/water prohibited discharges ordinance (2026-010) and stormwater management enforcement ordinance (2026-011) at the January 20, 2026 council meeting, citing protection of city waterways from hazardous discharges. He chaired the April 6 joint committee that finalized both ordinances. He also voted 9-0 for the solar school lease. His approach is consistent enforcement of existing environmental standards with no evidence of seeking significant additional developer offsets or of weakening standards.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_01_20.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Walter Hubley (Ward 3 Councillor) — id: d9c1a224-8844-440c-b8ec-f1eec59783e6
-- ============================================================

-- city-sanitation = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9c1a224-8844-440c-b8ec-f1eec59783e6', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'd9c1a224-8844-440c-b8ec-f1eec59783e6',
  '7687de4f-4d0b-462a-b803-bdfb23b16b42',
  $$At the April 6, 2026 Joint Public Works and Ordinance Committee, Hubley offered a friendly amendment to remove the written-warning requirement from the sewer discharge ordinance, stating he does not want to limit DPW discretion. He argued fines should be "commensurate with the damage" and noted restaurants can profitably use grease upcycling companies, making violations avoidable. He wants DPW to retain maximum enforcement authority rather than mandating a warning step before fines.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9c1a224-8844-440c-b8ec-f1eec59783e6', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'd9c1a224-8844-440c-b8ec-f1eec59783e6',
  '1935979c-b290-42e4-baa5-8cb0138b4ffa',
  $$Hubley voted 9-0 for the solar energy PPA on Squantum Elementary School (April 6, 2026). In the April 6 committee on sewer discharges, he noted restaurants can use grease upcycling services and focused on fines being commensurate with environmental damage. No evidence of pushing for more stringent environmental review requirements or for removing existing standards — consistent standards with reasonable flexibility.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_02_02.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- transportation-priorities = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9c1a224-8844-440c-b8ec-f1eec59783e6', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'd9c1a224-8844-440c-b8ec-f1eec59783e6',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  $$At the March 2, 2026 snow operations briefing, Hubley requested that the DPW sidewalk priority list be made public and reviewed prioritization of sidewalks near schools and the four train stations. At the March 16 utility public hearing, he opposed a Taylor Street utility relocation because it would reduce on-street parking without adding off-street alternatives, citing neighborhood opposition. These actions reflect balancing road/parking maintenance with pedestrian infrastructure near transit hubs — maintaining roads while selectively adding pedestrian improvements where density supports it.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_02.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_16.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Virginia Ryan (Ward 4 Councillor) — id: e32d6ab5-fef1-4666-a16f-c21903008c89
-- ============================================================

-- city-sanitation = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e32d6ab5-fef1-4666-a16f-c21903008c89', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e32d6ab5-fef1-4666-a16f-c21903008c89',
  '7687de4f-4d0b-462a-b803-bdfb23b16b42',
  $$At the March 2, 2026 council meeting during the snow operations review, Ryan called for a taskforce to review fines for businesses and homeowners who fail to shovel their sidewalks, citing Home Depot as an example of a large business that was fined. She seconded both the sewer discharge enforcement ordinance (2026-010) and stormwater management ordinance (2026-011) at introduction (January 20) and voted 9-0 for final approval (April 6). Her positions consistently emphasize holding businesses and property owners responsible through enforcement.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_02.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_01_20.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e32d6ab5-fef1-4666-a16f-c21903008c89', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e32d6ab5-fef1-4666-a16f-c21903008c89',
  '1935979c-b290-42e4-baa5-8cb0138b4ffa',
  $$Ryan seconded 2026-010 (sewer/water prohibited discharges) and 2026-011 (stormwater management enforcement) at introduction on January 20, 2026, and voted 9-0 for final approval on April 6, 2026. She engaged on firefighter gear PFAS testing. No evidence of pushing for stronger environmental offsets from developers or for relaxing existing standards — consistent environmental standards with reasonable implementation flexibility.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_01_20.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Maggie McKee (Ward 5 Councillor) — id: 83bc7737-c296-487a-aa3c-643c4ad6b7af
-- ============================================================

-- city-sanitation = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('83bc7737-c296-487a-aa3c-643c4ad6b7af', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '83bc7737-c296-487a-aa3c-643c4ad6b7af',
  '7687de4f-4d0b-462a-b803-bdfb23b16b42',
  $$As Ordinance Committee Chair, McKee led the sewer discharge enforcement ordinance process. At the April 6, 2026 committee she expressed concern that using "shall" in the enforcement language was "a little bit worrisome" due to unclear responsibility, and moved (unsuccessfully, 2-7) to change it to "may." During the March 2 snow operations briefing she pushed for better interdepartmental communication, a centralized reporting system for sidewalk violations, and inclusion of Council on Aging services. This reflects maintaining enforcement of anti-dumping laws while adding procedural safeguards — the center of the scale.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_02.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('83bc7737-c296-487a-aa3c-643c4ad6b7af', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '83bc7737-c296-487a-aa3c-643c4ad6b7af',
  '1935979c-b290-42e4-baa5-8cb0138b4ffa',
  $$McKee voted 9-0 for the solar energy PPA on Squantum Elementary School (April 6, 2026) and co-authored the 2026-035 resolution supporting state legislation to modernize community media funding. She engaged in detail with PFAS chemical safety in firefighter gear procurement. As Ordinance Committee Chair she oversaw the stormwater and sewer enforcement ordinances. No evidence of advocating for more restrictive environmental review of development or for removing existing standards.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_02_02.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Deborah Riley (Ward 6 Councillor) — id: 2ae196f5-cbbc-4f36-aac6-749b75738a9b
-- ============================================================

-- city-sanitation = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2ae196f5-cbbc-4f36-aac6-749b75738a9b', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2ae196f5-cbbc-4f36-aac6-749b75738a9b',
  '7687de4f-4d0b-462a-b803-bdfb23b16b42',
  $$As Finance Committee Chair, Riley stated at the April 6, 2026 committee meeting that "the city has invested millions of dollars in our drains and sewers, and it is the Council's obligation to protect that investment. Fines need to be substantial enough to deter bad behavior, without them people are just going to pay the fine and continue not to pay to have their grease removed and those costs will be borne by the taxpayers." She also opposed the written-warning amendment as "too subjective." Her position is consistent enforcement-first to protect public infrastructure.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_03_02.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2ae196f5-cbbc-4f36-aac6-749b75738a9b', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2ae196f5-cbbc-4f36-aac6-749b75738a9b',
  '1935979c-b290-42e4-baa5-8cb0138b4ffa',
  $$Riley moved the positive recommendation on the Squantum Elementary School solar lease (approved 9-0, April 6, 2026). She authored the City Auditor powers ordinance (2026-009) stating "the auditor's role is critical in providing independent, accurate, and timely oversight of the city's finances" — including environmental enforcement oversight. No evidence of pushing for more restrictive or more permissive development environmental standards.$$,
  ARRAY['https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_04_06.pdf', 'https://cms7files1.revize.com/quincyma2024/Agendas%20and%20Minutes/City%20Council/City%20Council/Minutes/Council_Minutes_2026_01_20.pdf']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Post-verification
-- Expected: 29 politician_answers + 29 politician_context rows
-- for politicians in external_id range -255574510..-255574501
-- (excludes Noel DiBona who is an honest-skip with 0 stances)
-- ============================================================
DO $$
DECLARE
  v_answer_count  INTEGER;
  v_context_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_answer_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -255574510 AND -255574501;

  SELECT COUNT(*) INTO v_context_count
  FROM inform.politician_context pc
  JOIN essentials.politicians p ON p.id = pc.politician_id
  WHERE p.external_id BETWEEN -255574510 AND -255574501;

  IF v_answer_count <> 29 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 29 politician_answers, found %', v_answer_count;
  END IF;

  IF v_context_count <> 29 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 29 politician_context rows, found %', v_context_count;
  END IF;

  RAISE NOTICE 'Migration 597 post-verification PASSED: % answers, % context rows', v_answer_count, v_context_count;
END $$;

-- ============================================================
-- Ledger entry
-- ============================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('597')
ON CONFLICT (version) DO NOTHING;
