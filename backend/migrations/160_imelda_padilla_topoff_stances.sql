-- Migration 160: Imelda Padilla — topoff stances (6 new topics)
-- LA City Council CD6 (Van Nuys / Northeast San Fernando Valley)
-- Politician ID: d82a3080-0a11-4d73-bacb-a936e51c9fb3
-- Research date: 2026-05-16

DO $$
DECLARE
  v_pid UUID := 'd82a3080-0a11-4d73-bacb-a936e51c9fb3';
BEGIN

  -- politician_answers
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
    (v_pid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2),  -- childcare
    (v_pid, 'a22215c3-6693-4bc2-b248-01aebba14570', 2),  -- fossil-fuels
    (v_pid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2),  -- healthcare
    (v_pid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2),  -- medicare/aid
    (v_pid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 2),  -- jail-capacity
    (v_pid, '48cc9585-ec22-4f53-8d42-6839828dd36f', 2)   -- redistricting
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

  -- childcare
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
    'Padilla voted YES on CF 25-0002-S35 (Feb 2026), a city resolution supporting state legislation to reform Child Care Subsidy Reimbursement Rates through an Alternative Methodology under the Child Care Development Fund Plan. She also moved CF 25-0002-S37 (Jul 2025) supporting AB 495, which prohibits childcare facilities from collecting children''s immigration status. These votes demonstrate support for expanding childcare subsidies and access, aligning with stance 2 (expand subsidies for low- and middle-income families).',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S35', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S37'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- fossil-fuels
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'a22215c3-6693-4bc2-b248-01aebba14570',
    'Padilla voted YES on CF 25-0002-S44 (Jul 2025) supporting the Polluters Pay Climate Superfund Act, which would require fossil fuel companies to fund climate damage mitigation. She also voted YES on CF 25-0002-S25 (May 2025) supporting California''s Cap-and-Trade program and renewable portfolio standards. These votes reflect support for stopping new permits and requiring accountability from fossil fuel polluters, consistent with stance 2 (stop issuing new permits, hold companies accountable).',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S44', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S25'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- healthcare
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
    'Padilla voted YES on CF 25-0002-S43 (Aug 2025) supporting basic healthcare coverage and immigrant access to Medi-Cal. She also voted YES on CF 25-0002-S52 (Feb 2026) supporting state funding for supportive recovery residences, and moved CF 25-0002-S72 (Feb 2026) supporting improved licensing for residential alcohol treatment facilities. These votes reflect support for expanding coverage through public programs, consistent with stance 2 (public option + ACA expansion).',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S43', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S52', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S72'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- medicare/aid
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
    'Padilla voted YES on CF 25-0002-S43 (Aug 2025), a resolution supporting basic healthcare coverage and immigrant access to Medi-Cal, advocating for expanded Medicaid eligibility regardless of immigration status. This aligns with stance 2 (expand Medicaid significantly and lower barriers to access).',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S43'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- jail-capacity
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
    'Padilla voted YES on CF 25-0002-S69 (Aug 2025) urging the Governor to grant clemency and commute death row sentences. She voted YES on CF 25-0002-S27 (Sep 2025) supporting AB 812 allowing incarcerated firefighters to seek resentencing, and YES on CF 24-0002-S10 (Mar 2025) vacating sentences for survivors of intimate partner violence and human trafficking. These votes reflect a consistent preference for diversion and resentencing over expanding incarceration, consistent with stance 2.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S69', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S27', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=24-0002-S10'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- redistricting
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '48cc9585-ec22-4f53-8d42-6839828dd36f',
    'Padilla voted YES on CF 25-0002-S83 (Sep 2025) supporting ACA 8, AB 604, and SB 380 — California constitutional and statutory measures establishing independent redistricting reform (Proposition 50 / Election Rigging Response Act) to create new congressional district maps outside partisan legislative control. Supporting independent redistricting reform at the state level indicates preference for independent or bipartisan commissions over purely legislative redistricting, consistent with stance 2.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S83'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

END $$;
