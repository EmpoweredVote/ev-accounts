-- Full coverage sprint for Jay Obernolte (politician_id: 18db5d61-6bce-4f55-ad45-bed01f329548)
-- Republican U.S. Representative, CA-23 (Inland Empire / High Desert)
-- Group A: add context to 2 existing answers with no context
--          (housing, ukraine-support)
-- Group B: insert 8 new answer+context rows
--          (childcare, data-centers, economic-development, homelessness, homelessness-response,
--           public-safety-approach, school-vouchers, transportation-priorities)

-- ── GROUP A: Add context to existing no-context rows ─────────────────────────

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','a9f53bc4-db4e-48e1-8663-c87f2c18b63d',
  'Obernolte is a consistent anti-regulatory conservative who voted against the American Rescue Plan (Mar 2021), which included housing assistance and rental relief, and has campaigned on limiting government intervention in markets. He explicitly opposes high-speed-rail and large government infrastructure programs, reflecting a broader preference for market-led solutions over public investment in housing. His overall record aligns with reducing housing regulations and letting private developers drive supply.',
  ARRAY['https://www.ontheissues.org/CA/Jay_Obernolte_Budget_+_Economy.htm','https://en.wikipedia.org/wiki/Jay_Obernolte','https://ballotpedia.org/Jay_Obernolte'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','669cac97-66a6-4087-b036-936fbe62efb3',
  'Obernolte is a consistent anti-regulatory conservative who voted against the American Rescue Plan (Mar 2021), which included housing assistance and rental relief, and has campaigned on limiting government intervention in markets. He explicitly opposes high-speed-rail and large government infrastructure programs, reflecting a broader preference for market-led solutions over public investment in housing. His overall record aligns with reducing housing regulations and letting private developers drive supply.',
  ARRAY['https://www.ontheissues.org/CA/Jay_Obernolte_Budget_+_Economy.htm','https://en.wikipedia.org/wiki/Jay_Obernolte','https://ballotpedia.org/Jay_Obernolte'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','24e9212c-b011-422a-865c-093e35050901',
  'Obernolte was NOT among the 10 House Republicans who voted against the Ukraine Democracy Defense Lend-Lease Act (April 2022, passed 417–10), confirming he voted yes. His stated commitment to ''a strong national defense'' and his 2021 vote to repeal the 2002 Iraq AUMF (favoring strategic multilateralism) align with continued Ukraine support at current aid levels. His conservative fiscal instincts temper any push to dramatically escalate aid.',
  ARRAY['https://en.wikipedia.org/wiki/Ukraine_Democracy_Defense_Lend-Lease_Act_of_2022','https://www.ontheissues.org/CA/Jay_Obernolte_Homeland_Security.htm','https://en.wikipedia.org/wiki/Jay_Obernolte'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','c1ac1330-47f7-44ec-baf3-c913d926b97c', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'Obernolte voted against the American Rescue Plan (Mar 2021), which included the expanded Child Tax Credit and $39 billion in childcare provider funding. He has consistently opposed large federal spending programs and favors limited government intervention in social services. His record suggests he would support only narrowly targeted childcare subsidies for the lowest-income families, not broad federal programs.',
  ARRAY['https://www.ontheissues.org/CA/Jay_Obernolte_Budget_+_Economy.htm','https://www.ontheissues.org/CA/Jay_Obernolte_Welfare_+_Poverty.htm','https://en.wikipedia.org/wiki/Jay_Obernolte'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','4559b513-0fd8-4ed1-babd-f3b554162f40', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','4559b513-0fd8-4ed1-babd-f3b554162f40',
  'Obernolte, a former video game developer and member of the House Science, Space & Technology Committee, supports minimal federal barriers to tech investment. He championed a 10-year moratorium on state AI regulations in the May 2025 reconciliation bill, arguing ''we have a limited amount of legislative runway to be able to get that problem solved before the states get too far ahead.'' This anti-regulatory, pro-tech-growth philosophy extends to data center development: he favors competitive incentives and streamlined permitting over environmental or cost-sharing requirements.',
  ARRAY['https://statescoop.com/state-lawmakers-push-back-federal-proposal-limit-ai-regulation/','https://en.wikipedia.org/wiki/Jay_Obernolte','https://www.ontheissues.org/CA/Jay_Obernolte_Technology.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Obernolte consistently campaigns on limited government, low taxes, and pro-business policies, with a stated record of ''fighting for lower taxes'' and opposing what he terms ''big government.'' He voted against the PRO Act (Mar 2021), preserving right-to-work laws, and opposed the American Rescue Plan stimulus. His philosophy aligns with actively competing for large employers through significant tax abatements and infrastructure investment rather than relying solely on organic growth.',
  ARRAY['https://www.ontheissues.org/CA/Jay_Obernolte_Jobs.htm','https://www.ontheissues.org/CA/Jay_Obernolte_Budget_+_Economy.htm','https://en.wikipedia.org/wiki/Jay_Obernolte'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','4938766b-b45a-46e3-93bd-b8b30651271a', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','4938766b-b45a-46e3-93bd-b8b30651271a',
  'Obernolte voted against AB 1869 (Aug 2020), which eliminated 23 administrative fees imposed on people in the criminal justice system — indicating he favors maintaining accountability mechanisms over decriminalizing systemic poverty-related conduct. He voted against the George Floyd Justice in Policing Act (Mar 2021), opposing reduced law enforcement tools. His fiscal conservatism and opposition to broad social-spending programs support an enforcement-first approach to public camping.',
  ARRAY['https://www.ontheissues.org/CA/Jay_Obernolte_Crime.htm','https://www.ontheissues.org/CA/Jay_Obernolte_Budget_+_Economy.htm','https://ballotpedia.org/Jay_Obernolte'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'Obernolte''s voting record shows consistent support for law enforcement tools and opposition to reduced policing measures: he voted against the George Floyd Justice in Policing Act, opposed fee waivers in the criminal justice system (AB 1869), and has campaigned on limited government. He represents a largely rural/suburban High Desert district (CA-23) where enforcement of anti-camping ordinances on public property is broadly supported. No evidence found of support for housing-first or decriminalization approaches.',
  ARRAY['https://www.ontheissues.org/CA/Jay_Obernolte_Crime.htm','https://www.ontheissues.org/CA/Jay_Obernolte_Principles_+_Values.htm','https://ballotpedia.org/Jay_Obernolte'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Obernolte voted against the George Floyd Justice in Policing Act (H.R. 1280, Mar 2021), which would have lowered the criminal intent standard for law enforcement misconduct and expanded DOJ investigative authority. He also voted to keep administrative fees in the criminal justice system (Aug 2020) and has consistently opposed measures that would reduce police authority or redirect police budgets. His stated values include ''a strong national defense'' and individual liberty, consistent with a pro-law-enforcement stance.',
  ARRAY['https://www.ontheissues.org/CA/Jay_Obernolte_Crime.htm','https://www.ontheissues.org/CA/Jay_Obernolte_Homeland_Security.htm','https://en.wikipedia.org/wiki/Jay_Obernolte'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','00b95a6a-75db-4521-b523-3326bba938de', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','00b95a6a-75db-4521-b523-3326bba938de',
  'No direct federal school voucher votes were confirmed in available records; however, Obernolte has consistently opposed government programs that restrict parental and market choice, voted against broad federal education spending (opposed ARPA), and is aligned with the Republican Party''s school choice agenda. He campaigned on ''individual liberty'' and ''limited government,'' principles that align with expanding voucher eligibility so parents can direct education funding.',
  ARRAY['https://www.ontheissues.org/CA/Jay_Obernolte_Education.htm','https://www.ontheissues.org/CA/Jay_Obernolte_Principles_+_Values.htm','https://en.wikipedia.org/wiki/Jay_Obernolte'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('18db5d61-6bce-4f55-ad45-bed01f329548','ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Obernolte explicitly stated (Jul 2020) ''No to wasteful government spending like high speed rail'' and supported efforts to ''end the bullet train to nowhere'' during his time in the California Assembly. He consistently opposes large government infrastructure projects. His focus on road capacity and driver-centric transportation over transit investment is reflected in his broader opposition to large public spending programs and his district''s largely car-dependent High Desert geography.',
  ARRAY['https://www.ontheissues.org/CA/Jay_Obernolte_Technology.htm','https://www.ontheissues.org/CA/Jay_Obernolte_Budget_+_Economy.htm','https://ballotpedia.org/Jay_Obernolte'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
