-- Migration 116: Maria Elena Durazo — compass stance ingestion
-- CA State Senator (SD-24) and LA County Supervisor D1 candidate (June 2026)
-- Research date: 2026-05-07. Sources: CA Senate bill authorship, labor leadership record,
-- campaign platforms, ontheissues.org.
-- Uses live topic IDs only. All 22 stances are MEDIUM-HIGH confidence.
-- Scale: 1=most progressive, 5=most conservative — matched to specific answer text.

BEGIN;

DO $$
DECLARE
  v_pid UUID := '539874fc-489f-4643-9b1a-923aca6cc2c1';
BEGIN

  PERFORM public.admin_update_politician_answers(v_pid, jsonb_build_array(
    jsonb_build_object('topic_id', '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 'value', 2),
    jsonb_build_object('topic_id', '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 'value', 2),
    jsonb_build_object('topic_id', '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 'value', 2),
    jsonb_build_object('topic_id', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 'value', 3),
    jsonb_build_object('topic_id', '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 'value', 2),
    jsonb_build_object('topic_id', '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'value', 2),
    jsonb_build_object('topic_id', 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 'value', 3),
    jsonb_build_object('topic_id', '1935979c-b290-42e4-baa5-8cb0138b4ffa'::uuid, 'value', 2),
    jsonb_build_object('topic_id', 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 'value', 2),
    jsonb_build_object('topic_id', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 'value', 2),
    jsonb_build_object('topic_id', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, 'value', 1),
    jsonb_build_object('topic_id', '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid, 'value', 1),
    jsonb_build_object('topic_id', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 'value', 2),
    jsonb_build_object('topic_id', 'b9ccee94-ad96-4f10-b655-889d8e5abe92'::uuid, 'value', 1),
    jsonb_build_object('topic_id', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 'value', 2),
    jsonb_build_object('topic_id', 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 'value', 2),
    jsonb_build_object('topic_id', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 'value', 2),
    jsonb_build_object('topic_id', 'd4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, 'value', 3),
    jsonb_build_object('topic_id', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 'value', 1),
    jsonb_build_object('topic_id', 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 'value', 2),
    jsonb_build_object('topic_id', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 'value', 2),
    jsonb_build_object('topic_id', '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'value', 1)
  ));

  -- Affordable Housing (housing=2): SB-567 capping rent hikes 5%; SB-21 preserving affordable units; opposes supply-only upzoning without affordability requirements
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '669cac97-66a6-4087-b036-936fbe62efb3',
    'Durazo authored SB-567 (Homelessness Prevention Act) capping rent increases at 5% and SB-21 to preserve existing affordable units. She explicitly opposes supply-only upzoning approaches that lack affordability requirements, aligning with answer [2]: rent caps, inclusionary requirements, and public funding for affordable housing.',
    ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB567', 'https://sd24.senate.ca.gov/'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Campaign Finance (campaign-finance=2): co-authored AB-259 wealth tax; backed strict limits on corporate spending
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '92730f69-ae57-401c-8ad1-2d07834a895d',
    'As a labor leader and state senator Durazo has consistently backed strict limits on corporate political spending. She co-authored AB-259 (wealth tax on $50M+ assets) targeting the donor class. Her record aligns with answer [2]: strictly limit corporate donations and dark money groups.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Civil Rights (civil-rights=2): UNITE HERE VP for Immigration/Diversity/Civil Rights; language-access bills; 13+ civil rights arrests
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '0bc588c6-39e1-4084-b5de-cac909b8b762',
    'Former UNITE HERE General VP for Immigration, Diversity & Civil Rights. Authored language-access legislation and has been arrested 13+ times in nonviolent civil rights protests. Consistently champions pay equity and racial justice. Aligns with answer [2]: strengthen civil rights enforcement and address systemic discrimination.',
    ARRAY['https://sd24.senate.ca.gov/about', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Climate Change (climate-change=3): SB-1020 (100% renewable by 2045); opposed Big Oil wildfire liability bill over worker impact
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
    'Co-authored SB-1020 targeting 100% clean energy by 2045 — a major climate commitment. However she opposed SB-222 (Big Oil wildfire liability bill) citing worker and union impact. This labor-climate balance places her at answer [3]: invest in clean energy while gradually reducing fossil fuel reliance.',
    ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB1020', 'https://sd24.senate.ca.gov/'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Criminalization of Homelessness (homelessness=2): SB-1500 removing barriers to housing; no criminalization advocacy
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '4938766b-b45a-46e3-93bd-b8b30651271a',
    'Authored SB-1500 removing income documentation barriers to permanent supportive housing access. Frames rent caps (SB-567) as homelessness prevention. Has not advocated criminalizing public sleeping. Aligns with answer [2]: decriminalize while investing in shelter and voluntary services.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Deportation Priorities (deportation=2): SB-580 prohibiting state resources for mass deportations; SB-635 protecting vendors
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '44905f3b-e105-4f6c-afc7-5d223813dbac',
    'Authored SB-580 prohibiting state resources from being used for mass deportations and SB-635 protecting street vendors from ICE enforcement. Co-sponsored resolutions denouncing federal immigration raids. Aligns with answer [2]: only deport people convicted of serious violent crimes.',
    ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB580', 'https://sd24.senate.ca.gov/'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Economic Development (economic-development=3): $10M clean-mobility/workforce; community benefit agreements
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'eb3d1247-0de1-4b7f-baec-7259861efd53',
    'Secured $10M in state budget for clean-mobility and workforce development. As a labor leader, supports economic development tied to job quality standards and community benefit agreements. Aligns with answer [3]: targeted incentives with community benefit and job quality requirements.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Environmental Protection vs Development (local-environment=2): pushed back on CEQA attacks; developer offset requirements
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '1935979c-b290-42e4-baa5-8cb0138b4ffa',
    'As chair of the Senate Local Government Committee, has pushed back on CEQA weakening efforts. Cited Vernon lead cleanup as an environmental justice priority. Advocates requiring developers to offset environmental impacts in frontline communities. Aligns with answer [2]: protect parks/environment strictly; require full developer offsets.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Fossil Fuel Policy (fossil-fuels=2): SB-1020 fossil-fuel phase-down benchmarks toward 100% renewable
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'a22215c3-6693-4bc2-b248-01aebba14570',
    'Co-authored SB-1020 which sets interim fossil-fuel phase-down benchmarks as part of a path to 100% clean energy by 2045. Participates in Senate Climate Workgroup focused on transitioning away from fossil fuels. Aligns with answer [2]: stop issuing new permits for fossil fuel drilling.',
    ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB1020', 'https://sd24.senate.ca.gov/'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Healthcare Access (healthcare=2): Health4All Medi-Cal expansion; SB-1422 Medi-Cal Restoration Act
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
    'Authored the landmark Health4All bill expanding Medi-Cal to approximately 2 million undocumented Californians regardless of immigration status. Also introduced SB-1422 to restore Medi-Cal after a budget enrollment freeze. Aligns with answer [2]: affordable coverage through public programs and regulated private insurance for all.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Homelessness Response (homelessness-response=1): SB-1500 housing-first; removes income documentation barriers
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
    'Authored SB-1500 removing income documentation barriers to permanent supportive housing — a core housing-first principle. Also authored SB-1333 creating employment pathways for people experiencing homelessness. Frames rent caps as homelessness prevention. Aligns with answer [1]: housing-first with permanent supportive housing; avoid criminalization.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Immigration (immigration=1): Health4All; SB-580; SB-635; undocumented residents fully use public services
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '4e2c69ce-591e-4197-9cd5-7aceff79d390',
    'Authored SB-580 (signed 2025) barring state resources from immigration enforcement, SB-635 protecting street vendors from ICE, and Health4All expanding full Medi-Cal access to undocumented Californians. Introduced SB-1422 restoring Medi-Cal enrollment. Aligns with answer [1]: make it easier to come legally; all immigrants including undocumented fully use public services.',
    ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB580', 'https://sd24.senate.ca.gov/'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Jail Capacity (jail-capacity=2): SB-731 broad record sealing; treatment over incarceration
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
    'Authored SB-731 enabling broad record sealing for over 1 million Californians. Advocates mental health care, substance use treatment, and housing as alternatives to incarceration. Has described incarceration as dehumanizing and counterproductive. Aligns with answer [2]: reduce incarcerated population through diversion and treatment alternatives.',
    ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB731', 'https://sd24.senate.ca.gov/'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Local Immigration Enforcement (local-immigration=1): SB-580 limits local agency ICE cooperation
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
    'SB-580 (signed into law 2025) requires all state and local agencies to limit immigration enforcement cooperation and restrict database sharing with ICE. Model policies are mandatory for agencies by January 2027. Aligns directly with answer [1]: refuse ICE detainers; prohibit sharing immigration status information.',
    ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB580', 'https://sd24.senate.ca.gov/'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Medicare/Medicaid (medicare/aid=2): Health4All Medi-Cal expansion to all income-eligible
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
    'Authored Health4All expanding Medi-Cal to all income-eligible Californians regardless of immigration status. Introduced SB-1422 to restore Medi-Cal enrollment after a budget-driven freeze. Consistent advocate for expanded public healthcare coverage. Aligns with answer [2]: lower age and significantly expand Medicaid.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Public Safety Approach (public-safety-approach=2): mental health co-responders; no defund stance
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
    'No documented stance calling for significant police budget redirections. Focuses on mental health services and social programs as complements to policing, consistent with maintaining current staffing. Aligns with answer [2]: maintain current police staffing but shift non-violent calls to mental health co-responders.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Reproductive Rights (abortion=2): CA abortion protection coalition; SB-590 paid leave for reproductive health
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
    'Listed as a coalition member supporting CA abortion protection legislation. Authored SB-590 expanding paid leave for reproductive and family health needs. Senate record is consistently supportive of abortion access. Aligns with answer [2]: keep abortion legal and accessible through the second trimester.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Residential Zoning (residential-zoning=3): yes on SB-79 density near transit; introduced LA Metro exemption over displacement
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
    'Voted yes on SB-79 allowing density near transit corridors. However, introduced an exemption bill for LA Metro station areas citing displacement and affordability concerns. Supports density only when paired with strong affordability and anti-gentrification protections. Aligns with answer [3]: allow multifamily near commercial corridors while protecting most residential zones.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Taxation (taxes=1): AB-259 wealth tax 1% on $50M+, 1.5% on $1B+; very wealthy must pay their share
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
    'Co-authored AB-259 imposing a 1% annual wealth tax on assets over $50M and 1.5% on assets over $1B. Explicitly stated "the very wealthy must pay their share." Also co-authored SB-951 raising Paid Family Leave wages for lower-income workers. Aligns with answer [1]: significantly raise taxes on wealthy people and large companies to fund more public services.',
    ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220AB259', 'https://sd24.senate.ca.gov/'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Transportation Priorities (transportation-priorities=2): SB-150 workforce equity in transit/infrastructure
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'ba59337e-30e2-4aba-a39a-426b3366eb27',
    'Co-authored SB-150 embedding workforce equity requirements into infrastructure and transit spending. Supported SB-79 allowing density near transit stations. Emphasizes public transit investment as a jobs and mobility priority. Aligns with answer [2]: invest equally in roads and multimodal options; require bike lanes and sidewalks on all new road projects.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Voting Rights (voting-rights=2): SB-52 redistricting reform; expanded ballot access
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
    'Authored SB-52 requiring an independent redistricting commission for LA City. Praises the CA independent commission as the "national gold standard." Supports expanded ballot access measures. Aligns with answer [2]: expand early voting and make mail-in voting available to all voters without requiring an excuse.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- State Redistricting (redistricting=1): SB-52 fully independent citizen commission; no elected officials
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '48cc9585-ec22-4f53-8d42-6839828dd36f',
    'Authored SB-52 requiring a fully independent citizen redistricting commission for LA City with no council involvement — directly responding to the LA City Council redistricting scandal. Cited the CA state independent commission as a nonpartisan gold standard. Aligns with answer [1]: independent citizens'' commissions with no elected officials involved at any level.',
    ARRAY['https://sd24.senate.ca.gov/', 'https://ballotpedia.org/Maria_Elena_Durazo'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

END $$;

COMMIT;
