-- 1031_tamala_takahashi_stances.sql
-- Phase 154 Burbank deep-seed Wave 4 — evidence-only compass stances for Tamala Takahashi
-- AUDIT-ONLY: raw SQL applied live via Supabase MCP, NOT registered in supabase_migrations.schema_migrations (ledger stays 1027).
-- CHAIRS model (value = the chair the evidence matches, never a polarity axis). 100% citation (paired
-- inform.politician_answers + inform.politician_context, every stance with reasoning + >=1 real source URL).
-- No defaulted/neutral values; honest blank spokes omitted. NO judicial-* topics (council-manager city).
-- politician_id ea6f7109-6067-4a48-bbdf-2a8b9cffe05f | 10 stances.

BEGIN;

-- local-environment = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 'Takahashi co-founded ''Reusable Burbank'' and co-authored Burbank''s comprehensive plastics ordinance (approved 2023), led the gas-powered leaf blower ban (adopted Dec 2025), and championed the city''s first large-scale municipal solar array at the airport. LALCV endorsed her in 2022 for her environmental record. This level of proactive environmental ordinance-authorship — requiring developers and businesses to meet strict environmental standards and banning polluting equipment — most closely matches chair 2: ''Protect existing parks and tree canopy strictly; require developers to fully offset any environmental impact.''', ARRAY['https://www.burbankca.gov/newsroom/-/newsdetail/20124/burbank-city-council-adopts-ordinance-prohibiting-gas-powered-leaf-blowers', 'https://www.burbankca.gov/newsroom/-/newsdetail/20124/burbank-city-council-approves-waste-reduction-regulations-ordinance', 'https://lalcv.org/lalcv-endorses-tamala-takahashi-for-burbank-city-council/', 'https://tamala4burbank.com/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Takahashi worked with fellow advocates to incorporate the Green New Deal framework into the city''s greenhouse gas emissions plan, championed Burbank''s first municipal solar array, pushed leaf blower bans and plastics ordinances, and was appointed to the 2023 SCAG Energy and Environment Committee. Her climate record focuses on practical city-level clean-energy investments and emissions ordinances rather than calling for an emergency declaration or a hard 2030 fossil fuel phase-out. Chair 3 — ''invest in clean energy while gradually reducing reliance on fossil fuels'' — best matches her documented approach.', ARRAY['https://tamala4burbank.com/', 'https://myburbank.com/tamala-takahashi-appointed-to-2023-scag-energy-and-environment-committee/', 'https://lalcv.org/lalcv-endorses-tamala-takahashi-for-burbank-city-council/', 'https://www.burbankca.gov/newsroom/-/newsdetail/20124/burbank-water-and-power-celebrates-ribbon-cutting-of-burbank-s-largest-solar-battery-system-at-the-hollywood-burbank-airport-regional-intermodal-transportation-center']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- transportation-priorities = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 'Takahashi is a declared active-transportation advocate who personally uses Burbank''s bus (route 94) and e-bikes, successfully pushed LA Metro to bring the Metro Micro pilot to Burbank, advocates for a full-city bike network and BRT, and framed multimodal streets as a way to address traffic, air quality, and cost of living. She explicitly stated that safe mobility means ''cars, bikes, buses, pedestrians, and horses'' — an all-modes approach. Chair 2 — ''Invest equally in roads and multimodal options; require bike lanes and sidewalks on all new road projects'' — best matches her documented position.', ARRAY['https://tamala4burbank.com/', 'https://bluevaluesburbank.org/city-council-candidates/tamala-takahashi/', 'https://myburbank.com/tamala-takahashi-elevated-to-position-of-burbank-mayor-for-2026/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- rent-regulation = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 'In October 2024, as Vice Mayor, Takahashi voted YES on Burbank''s 4% soft rent cap — the key vote in a 3-1 decision. She personally moved the council toward this compromise, stating ''the people in this community, they need a frickin'' place to live'' and defending the 4% rate as urgently needed to prevent displacement. She expressed openness to strengthening it over time. Voting for a soft cap with stated purpose of tenant protection (preventing displacement) while acknowledging it could be improved places her at chair 2: ''Strengthen existing rent stabilization and extend coverage to more units.''', ARRAY['https://outlooknewspapers.com/burbankleader/burbank-city-council-votes-for-soft-rent-cap/article_7ab49793-bbb8-410a-84d1-0de1911a0cb3.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness-response = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 'Takahashi cut the ribbon on four family transition suites alongside Burbank''s first integrated case-management homelessness resource center (with Home Again LA), advocates for permanent supportive housing with end-to-end case management, and broke ground on a Homeless Solutions Center. Her public statements describe a strategy centered on expanding shelter capacity and outreach-led services. This matches chair 2: ''Expand shelter capacity and services as the primary strategy; use enforcement only after services are offered.''', ARRAY['https://tamala4burbank.com/', 'https://outlooknewspapers.com/burbankleader/takahashi-kicks-off-term-as-burbank-mayor/article_dea1cf41-87dd-474d-8b36-86c5dce75eae.html', 'https://www.homeagainla.org/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 'Takahashi — a licensed therapist by training — expanded the Burbank Mental Health Evaluation Team, placed two social workers in the library and Parks & Rec, and as Mayor set ''public safety that includes a focus on mental health and wellness'' as a stated priority. Her campaign site describes ''protected first-responder funding'' alongside a ''mental-health-informed approach.'' She supports keeping existing police funding while adding crisis response capacity. Chair 3 — ''Keep current public safety funding while adding crisis response teams for mental health and addiction calls'' — best matches her documented position.', ARRAY['https://tamala4burbank.com/', 'https://outlooknewspapers.com/burbankleader/takahashi-kicks-off-term-as-burbank-mayor/article_dea1cf41-87dd-474d-8b36-86c5dce75eae.html', 'https://www.burbankca.gov/web/police-department/mental-health-evaluation-team']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', '669cac97-66a6-4087-b036-936fbe62efb3', 'Takahashi stated she is ''a general advocate for more housing,'' supports focused high-density housing near transit and services, advocates for rent-to-own and community-shared housing incentives, and voted yes on the 4% soft rent cap. She also called for a housing task force and supports meeting Burbank''s RHNA goals. Her approach — subsidized/permitting-eased affordable projects plus tenant protections while emphasizing the private market for general supply — most closely matches chair 3: ''Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits.''', ARRAY['https://myburbank.com/city-council-election-question-4-affordable-housing/', 'https://tamala4burbank.com/', 'https://outlooknewspapers.com/burbankleader/burbank-city-council-votes-for-soft-rent-cap/article_7ab49793-bbb8-410a-84d1-0de1911a0cb3.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- growth-and-development = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 'Takahashi supports focused high-density housing near transit and services with ''gentle density near R1 areas'' and ''protected walkable neighborhoods,'' and she called for proactive city planning (housing task force, housing element review) to accommodate RHNA requirements. She explicitly dismissed traffic-increase fears by noting Burbank''s population hasn''t grown since 1990. This proactive plan-ahead-of-growth stance matches chair 3: ''Plan proactively — invest in infrastructure ahead of growth to support responsible expansion.''', ARRAY['https://myburbank.com/city-council-election-question-4-affordable-housing/', 'https://tamala4burbank.com/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- residential-zoning = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 'Takahashi explicitly described a housing plan with ''focused high density housing near transit and services, gentle density near R1 areas, protected walkable neighborhoods.'' This is a targeted upzoning approach — multifamily and mixed-use allowed near commercial corridors and transit, while most residential zones are protected. Chair 3 — ''Allow multifamily and mixed-use near commercial corridors while protecting most residential zones'' — exactly matches her stated plan.', ARRAY['https://myburbank.com/city-council-election-question-4-affordable-housing/', 'https://tamala4burbank.com/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-immigration = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('ea6f7109-6067-4a48-bbdf-2a8b9cffe05f', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 'In February 2025, the Burbank City Council voted 5-0 (including Takahashi) to adopt a resolution aligning with SB 54, restricting all City personnel from involvement in federal immigration enforcement and prohibiting collection or disclosure of immigration status information. Separately, Takahashi moved to place SB 805 (No Vigilantes Act) on the council agenda and voted in favor of endorsing it, stating ''We cannot sit idly by while we watch our neighbors deal with it.'' She also described protecting residents from federal agencies acting ''without legal restraint.'' This aligns with chair 2: ''Comply only with court-ordered detainers; protect undocumented crime victims and witnesses from referral.''', ARRAY['https://publicnow.com/view/89B781A960D443BBA3EBDED73791637E21C3A14E?1739411240=', 'https://outlooknewspapers.com/burbankleader/news/burbank-council-deadlocks-on-move-to-ban-unmarked-law-enforcement/article_d3b2f77f-48bc-466a-803e-ed118f0c21c9.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Post-apply verification:
--   SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id='ea6f7109-6067-4a48-bbdf-2a8b9cffe05f'; -> 10
--   every answer has a paired context row (0 unpaired); 0 judicial-* topics; ledger MAX unchanged (1027).
