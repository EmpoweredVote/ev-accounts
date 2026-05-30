BEGIN;

-- SCOTT BRADLEY — Mayor, City of Murphy TX
-- ID: e8841ac4-bcae-4783-b24a-e6fb82f46da7

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8841ac4-bcae-4783-b24a-e6fb82f46da7', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org, LegiStorm, Facebook page, State of the City 2025 article.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8841ac4-bcae-4783-b24a-e6fb82f46da7', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Homelessness is not a visible issue in Murphy TX (~22k pop, fully built-out suburb). Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e8841ac4-bcae-4783-b24a-e6fb82f46da7', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8841ac4-bcae-4783-b24a-e6fb82f46da7', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'In January 2026, Bradley voted to deny a 32-townhome proposal that the Planning & Zoning Commission had unanimously approved 7-0. He stated "I''m tired of all this crowding" and directed staff to look at lower-density single-family development as the standard. This consistent opposition to density increases near residential zones aligns with protecting existing neighborhood character strictly (Answer 1).',
  ARRAY['https://murphymonitor.com/2026/01/15/townhome-plan-on-hold/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8841ac4-bcae-4783-b24a-e6fb82f46da7', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org, LegiStorm, Facebook page.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8841ac4-bcae-4783-b24a-e6fb82f46da7', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found with specific public safety funding positions. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8841ac4-bcae-4783-b24a-e6fb82f46da7', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found with specific economic development incentive positions. Checked: Murphy Monitor, murphytx.org, State of the City 2025.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8841ac4-bcae-4783-b24a-e6fb82f46da7', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found with specific transportation investment positions. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8841ac4-bcae-4783-b24a-e6fb82f46da7', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Immigration enforcement has not surfaced as a Murphy city council topic. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- SCOTT SMITH — Council Member Place 2, City of Murphy TX
-- ID: bcd556db-a139-4b87-8887-a1bad73726ea

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcd556db-a139-4b87-8887-a1bad73726ea', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: smithformurphy.com, Murphy Monitor, Ballotpedia, LegiStorm.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcd556db-a139-4b87-8887-a1bad73726ea', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Homelessness not a visible issue in Murphy TX. Checked: smithformurphy.com, Murphy Monitor.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcd556db-a139-4b87-8887-a1bad73726ea', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no direct public record of specific zoning position found. Smith emphasizes proactive planning for growth and protecting residents from development impacts, but no literal compass-answer match identified. Checked: smithformurphy.com, Murphy Monitor.',
  ARRAY['https://smithformurphy.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcd556db-a139-4b87-8887-a1bad73726ea', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: smithformurphy.com, Murphy Monitor, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcd556db-a139-4b87-8887-a1bad73726ea', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found with specific public safety positions. Checked: smithformurphy.com, Murphy Monitor.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcd556db-a139-4b87-8887-a1bad73726ea', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcd556db-a139-4b87-8887-a1bad73726ea', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Smith highlights the FM544 economic zone as a successful model generating growing sales tax revenue. He states "We have limited space left for economic development remaining and we need to ensure that we use our resources and tools to encourage positive growth." This targeted, zone-specific approach — using available tools to encourage growth in specific corridors — aligns with targeted incentives for specific areas (Answer 3) rather than maximum incentive recruitment.',
  ARRAY['https://smithformurphy.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcd556db-a139-4b87-8887-a1bad73726ea', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found with specific transportation investment positions. Checked: smithformurphy.com, Murphy Monitor.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcd556db-a139-4b87-8887-a1bad73726ea', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: smithformurphy.com, Murphy Monitor.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ANDREW CHASE — Council Member Place 3, City of Murphy TX
-- ID: b6cc39bb-f246-4e2b-8f90-252d907badd5

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6cc39bb-f246-4e2b-8f90-252d907badd5', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org, Ballotpedia, vote-usa.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6cc39bb-f246-4e2b-8f90-252d907badd5', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6cc39bb-f246-4e2b-8f90-252d907badd5', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no direct record of specific zoning vote or statement found. Chase emphasizes traffic management and proactive planning but no literal compass-answer match identified. Checked: Murphy Monitor, murphytx.org, Ballotpedia.',
  ARRAY['https://murphymonitor.com/2023/04/13/councilman-would-be-a-voice-for-all-residents/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6cc39bb-f246-4e2b-8f90-252d907badd5', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6cc39bb-f246-4e2b-8f90-252d907badd5', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6cc39bb-f246-4e2b-8f90-252d907badd5', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6cc39bb-f246-4e2b-8f90-252d907badd5', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — Chase emphasizes traffic flow improvement and mentions DART participation for commuter relief, but statements do not literally match a single compass answer. Checked: Murphy Monitor, murphytx.org.',
  ARRAY['https://murphymonitor.com/2023/04/13/councilman-would-be-a-voice-for-all-residents/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6cc39bb-f246-4e2b-8f90-252d907badd5', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- KEN OLTMANN — Council Member Place 4, City of Murphy TX
-- ID: 965000e5-54b5-40d4-9bae-6f70519536db

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965000e5-54b5-40d4-9bae-6f70519536db', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org, Ballotpedia, LegiStorm.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965000e5-54b5-40d4-9bae-6f70519536db', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('965000e5-54b5-40d4-9bae-6f70519536db', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965000e5-54b5-40d4-9bae-6f70519536db', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'In January 2026, Oltmann cast the sole dissenting vote against denying a 32-townhome proposal on FM544 (a commercial corridor). He explained: "What I didn''t want was two-story retail, which was what was allowed by rights there. I don''t like this density either, Mayor, I''m just saying I''m playing all the cards out." His willingness to allow multifamily/attached housing near commercial corridors while acknowledging density concerns fits Answer 3 (allow multifamily and mixed-use near commercial corridors while protecting most residential zones).',
  ARRAY['https://murphymonitor.com/2026/01/15/townhome-plan-on-hold/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965000e5-54b5-40d4-9bae-6f70519536db', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965000e5-54b5-40d4-9bae-6f70519536db', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found with specific public safety positions. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965000e5-54b5-40d4-9bae-6f70519536db', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found with specific economic development incentive positions. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965000e5-54b5-40d4-9bae-6f70519536db', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found with specific transportation investment positions. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('965000e5-54b5-40d4-9bae-6f70519536db', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- LAURA DEEL — Council Member Place 5, City of Murphy TX
-- ID: 24d1c9c9-b496-4562-87a8-548430f26663

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24d1c9c9-b496-4562-87a8-548430f26663', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org, Ballotpedia, LegiStorm.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24d1c9c9-b496-4562-87a8-548430f26663', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24d1c9c9-b496-4562-87a8-548430f26663', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24d1c9c9-b496-4562-87a8-548430f26663', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'In January 2026, Deel made the motion to deny a 32-townhome proposal that the Planning & Zoning Commission had unanimously approved 7-0. The motion passed 6-1. Her campaign also cites "making zoning decisions that bring services closer to residents" as an accomplishment, consistent with protecting residential character and limiting density. Fits Answer 1 (protect existing neighborhood character strictly).',
  ARRAY['https://murphymonitor.com/2026/01/15/townhome-plan-on-hold/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24d1c9c9-b496-4562-87a8-548430f26663', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Deel advocates "celebrating multicultural diversity at city events" but this does not match any specific compass answer. Checked: Murphy Monitor, murphytx.org.',
  ARRAY['https://murphymonitor.com/2023/03/30/challenger-wants-more-resident-input/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24d1c9c9-b496-4562-87a8-548430f26663', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found with specific public safety funding positions. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24d1c9c9-b496-4562-87a8-548430f26663', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24d1c9c9-b496-4562-87a8-548430f26663', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24d1c9c9-b496-4562-87a8-548430f26663', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Deel identifies traffic as "Murphy''s biggest challenge" and her top accomplishment is securing funding to reconstruct McMillen Road. Her campaign focus is on road reconstruction and traffic flow rather than transit or multimodal options. Fits Answer 4 (focus on road capacity and traffic flow; transportation investment should serve the majority who drive).',
  ARRAY['https://murphymonitor.com/2026/04/16/early-voting-starts-april-20/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24d1c9c9-b496-4562-87a8-548430f26663', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- JENÉ BUTLER — Council Member Place 6, City of Murphy TX
-- ID: c0bf5333-e271-46db-a5f8-84ced3177b6b

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf5333-e271-46db-a5f8-84ced3177b6b', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: jenebutler.com (coming soon), Murphy Monitor, vote-usa.org, Facebook page.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf5333-e271-46db-a5f8-84ced3177b6b', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf5333-e271-46db-a5f8-84ced3177b6b', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no direct record of specific zoning position found beyond general community input emphasis. Checked: jenebutler.com, Murphy Monitor, vote-usa.org.',
  ARRAY['https://vote-usa.org/Intro.aspx?State=TX&Id=TXButlerJeneE'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf5333-e271-46db-a5f8-84ced3177b6b', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf5333-e271-46db-a5f8-84ced3177b6b', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found with specific public safety positions. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0bf5333-e271-46db-a5f8-84ced3177b6b', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf5333-e271-46db-a5f8-84ced3177b6b', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Butler states economic development is a "top priority" and wants to attract businesses to Murphy. She plans to "discuss tax incentives and relief programs with council members that provide tax relief to specific groups, such as senior citizens, veterans, and the disabled." This targeted, group-specific incentive approach rather than maximum corporate recruitment fits Answer 3 (targeted incentives with community benefit considerations).',
  ARRAY['https://vote-usa.org/Intro.aspx?State=TX&Id=TXButlerJeneE'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf5333-e271-46db-a5f8-84ced3177b6b', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — Butler identifies traffic congestion as a pressing issue and supports connecting sidewalks in the city, but no specific transportation investment stance matches a literal answer description. Checked: Murphy Monitor, vote-usa.org.',
  ARRAY['https://murphymonitor.com/2022/04/05/candidate-says-wastewater-plant-is-biggest-issue/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0bf5333-e271-46db-a5f8-84ced3177b6b', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ELIZABETH ABRAHAM — Council Member Place 1, City of Murphy TX
-- ID: 094da72b-3f17-4ce8-9c2a-747acd125086

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('094da72b-3f17-4ce8-9c2a-747acd125086', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org, Ballotpedia, LegiStorm.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('094da72b-3f17-4ce8-9c2a-747acd125086', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('094da72b-3f17-4ce8-9c2a-747acd125086', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — Abraham states she will ensure "the influence of special interest groups, such as developers, does not outweigh the voice of the community," but this does not precisely match a single compass answer. Checked: Murphy Monitor, murphytx.org.',
  ARRAY['https://murphymonitor.com/2025/04/03/place-1-incumbent-hopes-to-keep-focused-on-key-issues/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('094da72b-3f17-4ce8-9c2a-747acd125086', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('094da72b-3f17-4ce8-9c2a-747acd125086', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('094da72b-3f17-4ce8-9c2a-747acd125086', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Abraham stated: "Public safety, a key reason residents choose Murphy, will be a priority, adding resources to meet growing demands." Adding resources to meet growing demands aligns with Answer 4 (increase police staffing, equipment, and pay to improve response times and deter crime), reflecting a commitment to expanding public safety capacity.',
  ARRAY['https://murphymonitor.com/2025/04/03/place-1-incumbent-hopes-to-keep-focused-on-key-issues/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('094da72b-3f17-4ce8-9c2a-747acd125086', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — Abraham supports attracting businesses and providing incentives for "a variety of new businesses," but language is too general to match a specific compass answer. Checked: Murphy Monitor, murphytx.org.',
  ARRAY['https://murphymonitor.com/2022/04/06/intentional-growth-is-essential-says-candidate/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('094da72b-3f17-4ce8-9c2a-747acd125086', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — Abraham identifies traffic flow and congestion on FM-544 as a key concern, but no specific investment priority statement matches a literal answer description. Checked: Murphy Monitor, murphytx.org.',
  ARRAY['https://murphymonitor.com/2025/04/03/place-1-incumbent-hopes-to-keep-focused-on-key-issues/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('094da72b-3f17-4ce8-9c2a-747acd125086', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: Murphy Monitor, murphytx.org, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
