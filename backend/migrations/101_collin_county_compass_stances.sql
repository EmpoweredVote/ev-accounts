-- Migration 101: Collin County TX — compass stance ingestion (MEDIUM+ confidence)
-- Phase 18 execution. Sources: LWV Collin County voter guides, Community Impact Q&As,
-- candidate campaign websites. Research date: 2026-05-03.
-- Only MEDIUM or HIGH confidence assignments included.
--
-- Topics used:
--   Housing = a9f53bc4-db4e-48e1-8663-c87f2c18b63d  (Affordable Housing and Homelessness)
--   Taxes   = 45ca4740-a861-4c8c-b3b5-0a49cf953501  (Taxation and Government Spending)

BEGIN;

DO $$
DECLARE
  v_housing UUID := 'a9f53bc4-db4e-48e1-8663-c87f2c18b63d';
  v_taxes   UUID := '45ca4740-a861-4c8c-b3b5-0a49cf953501';
BEGIN

  -- -------------------------------------------------------------------------
  -- PLANO
  -- -------------------------------------------------------------------------

  -- Shun Thomas — Place 7 — Housing = 3 (MEDIUM)
  -- Evidence: LWV Jan 2026 voter guide — "Zoning Reform, Strategic Partnerships,
  --   Incentives for Affordability, and Anti-Displacement Measures"
  PERFORM public.admin_update_politician_answers(
    '4272e5cb-40cf-42d9-a493-ae5ca04301bb'::uuid,
    jsonb_build_array(jsonb_build_object('topic_id', v_housing, 'value', 3))
  );
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    '4272e5cb-40cf-42d9-a493-ae5ca04301bb',
    v_housing,
    'Thomas supports a multi-pronged approach to housing affordability including zoning reform, strategic public-private partnerships, incentives for affordability, and anti-displacement measures. Does not call for government-built units (stance 2) nor pure market deregulation (stance 4).',
    ARRAY['https://www.lwvcollin.org/voters-guides']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Steve Lavine — Place 5 — Housing = 3 (MEDIUM)
  -- Evidence: Community Impact Q&A Apr 2025 — public-private partnerships for
  --   redevelopment, senior housing, "without overburdening taxpayers"
  PERFORM public.admin_update_politician_answers(
    'ecef0481-27c7-4955-b822-83d64c7ef63f'::uuid,
    jsonb_build_array(jsonb_build_object('topic_id', v_housing, 'value', 3))
  );
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    'ecef0481-27c7-4955-b822-83d64c7ef63f',
    v_housing,
    'Lavine proposes public-private partnership redevelopment (Collin Creek, Willow Bend) to create mixed-use community hubs. Focuses on senior housing and keeping growing families in Plano. Frames solutions as providing amenities "without overburdening taxpayers." Aligns with stance 3 (incentives/market-assist).',
    ARRAY['https://communityimpact.com/dallas-fort-worth/plano-north/election/2025/04/03/qa-meet-the-candidates-for-plano-city-council-place-5/']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- John B. Muns — Mayor — Housing = 3 (MEDIUM)
  -- Evidence: Plano Magazine interview — supports housing diversity including
  --   multifamily via adaptive zoning, not government-funded programs
  PERFORM public.admin_update_politician_answers(
    '5584e869-4a54-4a68-a3c8-c14db45a71c5'::uuid,
    jsonb_build_array(jsonb_build_object('topic_id', v_housing, 'value', 3))
  );
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    '5584e869-4a54-4a68-a3c8-c14db45a71c5',
    v_housing,
    'Muns supports housing diversity including multifamily, stating "If you dig deep, I think some people have a prejudice against that type of housing." Advocates adaptive zoning and market-driven housing diversity for corporate relocation needs. Does not support government housing programs; fits stance 3 (zoning flexibility and market-assist).',
    ARRAY['https://planomagazine.com/plano-mayor-john-muns/']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- -------------------------------------------------------------------------
  -- McKINNEY
  -- -------------------------------------------------------------------------

  -- Bill Cox — Mayor — Housing = 3 (MEDIUM)
  -- Evidence: Community Impact May 2025 — "attainable housing opportunities",
  --   opened McKinney first Affordable Housing Summit (Apr 2026)
  PERFORM public.admin_update_politician_answers(
    '1c31b159-d4c1-4756-ba81-a247dbf0af8f'::uuid,
    jsonb_build_array(jsonb_build_object('topic_id', v_housing, 'value', 3))
  );
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    '1c31b159-d4c1-4756-ba81-a247dbf0af8f',
    v_housing,
    'Cox stated the city needs to "prepare now for new roads, infrastructure and attainable housing opportunities." As mayor, he opened McKinney''s first Affordable Housing Summit (April 2026) with remarks on workforce housing needs. "Attainable housing" framing and hosting an affordable housing summit indicates stance 3 (incentives/assistance) rather than pure market or government-built units.',
    ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/03/26/mckinneys-next-mayor-residents-to-decide-between-4-candidates-in-may-election/']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Geré Feltus — District 3 — Housing = 3 (MEDIUM)
  -- Evidence: Community Impact Mar 2025 — "expanding Community Land Trust for
  --   homeownership and workforce development partnerships"
  PERFORM public.admin_update_politician_answers(
    '23ba75d2-6eed-4b71-9669-78ab3bb82e98'::uuid,
    jsonb_build_array(jsonb_build_object('topic_id', v_housing, 'value', 3))
  );
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    '23ba75d2-6eed-4b71-9669-78ab3bb82e98',
    v_housing,
    'Feltus explicitly proposes "expanding the Community Land Trust for homeownership and workforce development partnerships with schools and colleges." A Community Land Trust is a below-market homeownership tool — the clearest specific housing policy mechanism found in this research batch. Maps well to stance 3 (helping first-time buyers and workforce housing). He has also noted achievements: "lowered property tax rates, increased senior homestead exemptions."',
    ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/election/2025/03/05/qa-meet-the-candidates-in-the-mckinney-city-council-district-3-race/']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- -------------------------------------------------------------------------
  -- ALLEN
  -- -------------------------------------------------------------------------

  -- Michael Schaeffer — Place 1 — Housing = 4 (MEDIUM) + Taxes = 4 (MEDIUM)
  -- Evidence: mike4allen.com — "I have never incentivized, zoned or approved
  --   a single apartment in Allen"; pledges to continue lowering tax rate
  PERFORM public.admin_update_politician_answers(
    'c7a0ecf6-b416-474b-9647-a25e404f4bc4'::uuid,
    jsonb_build_array(
      jsonb_build_object('topic_id', v_housing, 'value', 4),
      jsonb_build_object('topic_id', v_taxes,   'value', 4)
    )
  );
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    'c7a0ecf6-b416-474b-9647-a25e404f4bc4',
    v_housing,
    'Schaeffer states on his campaign website: "I have never incentivized, zoned or approved a single apartment in Allen." His approach to housing is to build a stronger commercial tax base rather than housing programs. Explicit opposition to apartment approvals and government housing incentives aligns with stance 4 (let private developers solve housing shortages).',
    ARRAY['https://www.mike4allen.com/']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    'c7a0ecf6-b416-474b-9647-a25e404f4bc4',
    v_taxes,
    'Schaeffer pledges on his campaign website: "I pledge to continue Allen''s long history of lowering the tax rate while maintaining the city services that All of Allen deserves." Explicit commitment to lowering tax rates fits stance 4.',
    ARRAY['https://www.mike4allen.com/']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- -------------------------------------------------------------------------
  -- FRISCO
  -- -------------------------------------------------------------------------

  -- Ann Anderson — Place 1 — Housing = 3 (MEDIUM)
  -- Evidence: LWV Frisco Special Election voter guide Jan 2026
  PERFORM public.admin_update_politician_answers(
    'da010ea4-257d-4582-98cb-ee90063aa31d'::uuid,
    jsonb_build_array(jsonb_build_object('topic_id', v_housing, 'value', 3))
  );
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    'da010ea4-257d-4582-98cb-ee90063aa31d',
    v_housing,
    'Anderson states in the LWV voter guide: "My vision for housing includes balanced, thoughtful development that preserves Frisco''s character while preparing for future growth. I support reinvestment in established areas and careful zoning decisions that ensure infrastructure and schools can support new development." Centrist zoning stewardship language with no government housing programs mentioned and no deregulation call — fits stance 3.',
    ARRAY['https://www.lwvcollin.org/voters-guides']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Angelia Pelham — Place 3 — Taxes = 4 (MEDIUM)
  -- Evidence: Community Impact Place 3 Q&A Apr 2024 — "property tax relief through
  --   lowered rates and increased homestead exemptions up to 20%"
  PERFORM public.admin_update_politician_answers(
    '5b346b19-d6ee-47e2-acbf-5780ca423264'::uuid,
    jsonb_build_array(jsonb_build_object('topic_id', v_taxes, 'value', 4))
  );
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    '5b346b19-d6ee-47e2-acbf-5780ca423264',
    v_taxes,
    'Pelham explicitly calls for "property tax relief through lowered rates and increased homestead exemptions up to 20%" as a top priority. As an incumbent, she has continued voting for lower tax rates. Explicit lower-rates commitment fits stance 4.',
    ARRAY['https://communityimpact.com/dallas-fort-worth/frisco/election/2024/04/15/qa-meet-the-candidates-running-for-frisco-city-council-place-3/']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Burt Thakur — Place 2 — Taxes = 4 (MEDIUM)
  -- Evidence: Community Impact Place 2 Q&A Mar 2025 — "Lowering property taxes
  --   by opposing wasteful projects" listed as first priority
  PERFORM public.admin_update_politician_answers(
    'c11bf372-8190-4b45-b80a-cbd0fb2ba401'::uuid,
    jsonb_build_array(jsonb_build_object('topic_id', v_taxes, 'value', 4))
  );
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    'c11bf372-8190-4b45-b80a-cbd0fb2ba401',
    v_taxes,
    'Thakur makes "Lowering property taxes by opposing wasteful projects" his first stated priority, citing opposition to the $300M Performing Arts Center as an example. Explicit tax reduction priority fits stance 4.',
    ARRAY['https://communityimpact.com/dallas-fort-worth/frisco/election/2025/03/11/qa-meet-the-candidates-in-the-race-for-frisco-city-council-place-2/']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Laura Rummel — Place 5 — Housing = 4 (MEDIUM) + Taxes = 4 (HIGH)
  -- Evidence: LWV Frisco voter guide May 2026 — "I believe in free market
  --   principles"; documented 4-year record of annual tax rate reductions
  PERFORM public.admin_update_politician_answers(
    '76c3fa35-a286-4fa1-b6da-40300d91f33e'::uuid,
    jsonb_build_array(
      jsonb_build_object('topic_id', v_housing, 'value', 4),
      jsonb_build_object('topic_id', v_taxes,   'value', 4)
    )
  );
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    '76c3fa35-a286-4fa1-b6da-40300d91f33e',
    v_housing,
    'Rummel states in the LWV voter guide: "I believe in free market principles, but Frisco would benefit by diversifying our housing inventory." She has advocated for shifting developer rights from traditional apartments to owner-occupied townhomes/condos, framing this as a market-based zoning mechanism to increase housing options "without compromising the suburban character of our community." Explicit free market principles statement with private-developer-model solution fits stance 4.',
    ARRAY['https://www.lwvcollin.org/voters-guides']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    '76c3fa35-a286-4fa1-b6da-40300d91f33e',
    v_taxes,
    'Rummel states in the LWV voter guide: "during my 4 years on Council, we''ve increased the Homestead Exemption from 10% to the 20% legal maximum, implemented the Senior Tax Freeze, and reduced the tax rate nearly every year. I approach my role as a steward of our tax dollars with a firm commitment to conservative, results-driven leadership." Documented 4-year voting record of tax rate reductions and expanded exemptions — HIGH confidence for stance 4.',
    ARRAY['https://www.lwvcollin.org/voters-guides']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- Jeff Cheney — Mayor — Taxes = 4 (MEDIUM)
  -- Evidence: Texas Scorecard — opposes state-imposed caps on local tax-setting;
  --   Frisco has cut property tax rates under his tenure
  PERFORM public.admin_update_politician_answers(
    'ac1ed3c9-db6c-4931-bc55-4d53c6c81b35'::uuid,
    jsonb_build_array(jsonb_build_object('topic_id', v_taxes, 'value', 4))
  );
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (
    'ac1ed3c9-db6c-4931-bc55-4d53c6c81b35',
    v_taxes,
    'Cheney opposes SB2/HB2 state property tax reform that would cap local rate increases, arguing it would "shift the tax burden from corporations to residents." Note: this is a LOCAL CONTROL position, not a pro-tax stance — Cheney''s stated priority is keeping resident burden low via commercial growth, and Frisco has reduced property tax rates multiple times under his tenure. Fits stance 4 (reduce rates) at local level.',
    ARRAY['https://texasscorecard.com/local/frisco-mayor-doubles-down-against-property-tax-reform/']
  )
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

END $$;

COMMIT;
