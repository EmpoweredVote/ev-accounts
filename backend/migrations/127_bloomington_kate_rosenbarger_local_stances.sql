BEGIN;

-- ============================================================
-- Migration 127: Local Lens compass stances for Kate Rosenbarger
-- Bloomington City Common Council, District 2
-- politician_id: 4aa0dadf-a3c0-41e9-a5de-66582a393622
-- Researched: 2026-05-11
-- ============================================================

-- 1. AFFORDABLE HOUSING (topic_id: 669cac97-66a6-4087-b036-936fbe62efb3)
-- Value 2: Use rent caps, require new developments to include affordable units, and publicly fund new housing
-- Evidence: Rosenbarger voted NO on the February 2026 affordable housing incentives ordinance (passed 6-2)
-- explicitly to pressure the administration for bigger changes than what was offered. She co-authored
-- the Hopewell South PUD condition requiring at least 50% of units to be permanently affordable (a hard
-- floor, not a target); when the council adopted a 35% floor / 50% goal instead she voted against the
-- final condition because it fell short of her required threshold. She co-sponsored the 2021 ordinance
-- protecting houseless encampments (failed 4-4) as a companion measure to housing-first services. She
-- also sponsored the March 2025 UDO resolutions adding sustainability incentives and inclusionary
-- requirements for developers. Career background: NeighborWorks America (community development and
-- affordable housing) and Patronicity (community development crowdfunding). No evidence of advocating
-- for directly government-built public housing (value 1), nor for a deregulatory market approach
-- (values 4-5). Value 2 (require new developments to include affordable units, publicly fund housing)
-- matches her documented record.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa0dadf-a3c0-41e9-a5de-66582a393622', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4aa0dadf-a3c0-41e9-a5de-66582a393622',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from voting record and public advocacy. Rosenbarger voted NO on the February 2026 affordable housing incentives ordinance (passed 6-2), doing so explicitly to pressure administration for bigger changes. She co-authored the Hopewell South PUD condition requiring at least 50% of units be permanently affordable as a hard requirement, not a target; when council adopted a 35% floor / 50% goal compromise instead, she voted against the final condition because it did not meet her threshold. She co-sponsored the March 2025 UDO amendment resolutions adding sustainability incentive requirements and inclusionary standards for new developments. Her professional background is in community development and affordable housing — she spent most of her career at NeighborWorks America, a national nonprofit focused on affordable housing and community development, and later at Patronicity, which works with local governments and nonprofits to enhance neighborhood quality of life. No evidence of supporting direct government-operated public housing (value 1), nor of a market deregulation approach (values 4-5). Value 2 (require new developments to include affordable units and publicly fund housing) best matches her documented record.',
  ARRAY[
    'https://www.ipm.org/news/2026-02-11/council-passes-affordable-housing-incentives-asks-for-more',
    'https://bsquarebulletin.com/hopewell-south-pud-wins-unanimous-ok-from-bloomington-city-council/',
    'https://www.idsnews.com/article/2025/04/city-council-mayor-upzoning-disagreement-udo-housing-density',
    'https://bloomington.in.gov/council/district-2',
    'https://bsquarebulletin.com/bloomington-city-council-district-2-democratic-party-primary-kate-rosenbarger-sue-sgambelluri/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 2. CRIMINALIZATION OF HOMELESSNESS (topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a)
-- Value 1: Protecting the right to sleep in public spaces and redirecting enforcement budgets toward
--          permanent supportive housing and mental health services
-- Evidence: In February 2021 Rosenbarger co-sponsored (with Flaherty and Piedmont-Smith) the Bloomington
-- ordinance that would have affirmatively protected houseless encampments — the city could not displace
-- a camp unless it could provide permanent or transitional housing as defined by HUD. The ordinance
-- failed 4-4. In September 2023 she was among five council members who voted down an ordinance
-- prohibiting camping on sidewalks and streets. The encampment-protection ordinance she co-sponsored
-- represents a position beyond decriminalization (value 2) — it affirmatively protected the right to
-- camp, consistent with value 1.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa0dadf-a3c0-41e9-a5de-66582a393622', '4938766b-b45a-46e3-93bd-b8b30651271a', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4aa0dadf-a3c0-41e9-a5de-66582a393622',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Inferred from co-sponsorship and voting record. In February 2021, Rosenbarger co-sponsored (with Flaherty and Piedmont-Smith) a Bloomington ordinance that would have affirmatively protected houseless encampments: the city could not displace a camp unless it could provide "permanent housing" or "transitional housing" as defined by HUD. The ordinance failed 4-4. In September 2023, she was among five council members who voted down an ordinance that would have prohibited camping on sidewalks, streets, and roads, preventing the city from forcibly removing items blocking the public right-of-way. Her co-sponsorship of encampment protections goes beyond decriminalizing public sleeping (value 2) to affirmatively protecting the right to camp in city parks. The D Square Bulletin noted that her co-sponsored ordinance was explicitly framed as a "housing first" measure, with the title "We can''t shelter our way out of this problem," indicating her position is to redirect resources toward permanent supportive housing rather than enforcement or shelter expansion alone. Value 1 (protecting the right to sleep in public and redirecting enforcement budgets toward permanent supportive housing and mental health services) best matches her documented record.',
  ARRAY[
    'https://www.ipm.org/2023-09-14/city-council-rejects-effort-to-prevent-camping-on-sidewalks-streets',
    'https://bsquarebulletin.com/bloomington-city-council-district-2-democratic-party-primary-kate-rosenbarger-sue-sgambelluri/',
    'https://kateforbloomington.org/issues/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 3. RESIDENTIAL ZONING (topic_id: d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Value 4: Upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements
-- Evidence: Rosenbarger authored and sponsored the March 2025 UDO amendment resolutions directing the
-- plan commission to allow duplexes, triplexes, and fourplexes as permitted uses in single-family
-- residential zones; eliminate design restrictions on those housing types; remove the owner-occupancy
-- requirement for ADUs; allow two ADUs per lot; eliminate ADU square footage caps; redefine
-- single-family attached dwellings to include townhouses and rowhouses; and ease cottage development
-- restrictions. A companion resolution she co-sponsored called for removing minimum parking requirements.
-- The pair of resolutions failed 4-4 (tied votes blocked even introduction). She described the timeline
-- as feasible because "We've done it already," indicating this is a familiar process for her. Value 4
-- (upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements)
-- is a direct match.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa0dadf-a3c0-41e9-a5de-66582a393622', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4aa0dadf-a3c0-41e9-a5de-66582a393622',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from direct authorship and sponsorship of UDO amendment resolutions. In March 2025, Rosenbarger authored and sponsored UDO amendment resolutions that directed the Bloomington Plan Commission to prepare ordinances allowing: duplexes, triplexes, and fourplexes as permitted uses in single-family residential zones; elimination of design restrictions on these housing types; removal of owner-occupancy requirements for ADUs; permission for two ADUs per lot; elimination of ADU square footage caps in favor of footprint-based standards; redefinition of "single-family attached dwellings" to include townhouses and rowhouses (provided units are not stacked); and easing of cottage development restrictions through removing size limits and increasing density allowances. A companion resolution co-sponsored by Rosenbarger called for removing minimum parking requirements citywide. Both resolutions failed on 4-4 tie votes that blocked even introduction to the plan commission. Rosenbarger stated "We''ve done it already" when challenged on the timeline, indicating familiarity with the process. She and co-sponsor Hopi Stosberg framed the changes as essential for addressing Bloomington''s housing shortage. No evidence of supporting neighborhood-character protection (value 1), limiting changes to modest density with design review (value 2), or limiting multifamily to commercial corridors (value 3). Her proposals match value 4 (upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements) precisely.',
  ARRAY[
    'https://bsquarebulletin.com/start-of-process-for-possible-zoning-changes-halted-with-4-4-votes-by-bloomington-city-council/',
    'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning',
    'https://www.idsnews.com/article/2025/04/city-council-mayor-upzoning-disagreement-udo-housing-density'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 4. CIVIL RIGHTS AND SOCIAL JUSTICE (topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Value 2: Strengthen civil rights enforcement and address systemic discrimination
-- Evidence: Rosenbarger's campaign platform explicitly lists "racial and social equity" as a key issue.
-- She stated: "we really have to look at our racial and social disparities in housing, in transit, in
-- business ownership and speak to those root causes and make decisions that bring everyone up." She
-- describes inclusive government as requiring centering underrepresented voices in decision making.
-- No evidence of reparations advocacy (value 1) or limiting civil rights enforcement (values 3-5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa0dadf-a3c0-41e9-a5de-66582a393622', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4aa0dadf-a3c0-41e9-a5de-66582a393622',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from campaign platform and public statements. Rosenbarger lists "racial and social equity" as a key campaign issue. She stated in a 2023 primary interview: "we really have to look at our racial and social disparities in housing, in transit, in business ownership and speak to those root causes and make decisions that bring everyone up." She describes inclusive government as specifically requiring that "underrepresented voices are centered in decision making" and that communities "historically excluded from local government decisions" must be supported. Her stated approach frames equity in terms of addressing root causes of disparity — consistent with value 2 (strengthen civil rights enforcement and address systemic discrimination). No evidence of advocating for reparations or mandated racial equity requirements across all institutions (value 1), nor of limiting civil rights enforcement (values 3-5). Value 2 matches her documented platform and statements.',
  ARRAY[
    'https://kateforbloomington.org/issues/',
    'https://bsquarebulletin.com/bloomington-city-council-district-2-democratic-party-primary-kate-rosenbarger-sue-sgambelluri/',
    'https://bloomington.in.gov/council/district-2'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 5. PUBLIC SAFETY APPROACH (topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Value 2: Maintain current police staffing but shift non-violent calls to unarmed mental health co-responders
-- Evidence: Rosenbarger stated in a 2023 primary interview that "continuing to allocate funds for
-- non-police alternatives is very important here" and that "jail is not a place for recovery,"
-- emphasizing mental health treatment and nonprofits providing recovery services. She framed public
-- safety as requiring both police and mental health alternatives. No evidence she called for
-- significant police budget reductions (value 1) or for expanded police staffing (values 4-5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa0dadf-a3c0-41e9-a5de-66582a393622', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4aa0dadf-a3c0-41e9-a5de-66582a393622',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from 2023 primary interview statements. Rosenbarger stated that "continuing to allocate funds for non-police alternatives is very important here" and noted "mental health is public health," saying "we need to look at it in a very holistic way." She said "jail is not a place for recovery" and emphasized the need to "continue to support the nonprofits doing recovery work and doing treatment work in our community." Her framing is explicitly additive — maintaining public safety while allocating funds to non-police mental health alternatives — not a call to significantly redirect or defund police. No evidence she advocated for large police budget cuts (value 1) or for increased police staffing and equipment as a city priority (values 4-5). Value 2 (maintain current police staffing but shift non-violent calls to unarmed mental health co-responders) matches her stated public safety philosophy. Note: no specific council vote on a co-responder or alternative-responder program was found for Rosenbarger specifically; this assessment is based on her 2023 candidate statements.',
  ARRAY[
    'https://bsquarebulletin.com/bloomington-city-council-district-2-democratic-party-primary-kate-rosenbarger-sue-sgambelluri/',
    'https://kateforbloomington.org/issues/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 6. LOCAL IMMIGRATION ENFORCEMENT (topic_id: b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Value 2: Comply only with court-ordered detainers; protect undocumented crime victims and witnesses
-- Evidence: No specific statement from Rosenbarger on ICE detainer policy found. However, Bloomington
-- is the only DHS-designated "sanctuary jurisdiction" in Indiana. The BPD updated policies in March
-- 2026 to prohibit use of Flock data for immigration enforcement; the city council unanimously passed
-- a resolution on March 5, 2026 calling for Flock camera oversight and limiting data sharing.
-- BPD stated it has no communication with ICE unless assisting with a criminal arrest warrant.
-- The city's stated policy is "we do not inquire about anyone's immigration status and any person
-- regardless of status should feel safe in calling 911." Rosenbarger voted with this unanimous council.
-- The overall city posture — protect status inquiries, no proactive enforcement — maps to value 2.
-- Not value 1 (no evidence of actively refusing all ICE detainers by resolution); not value 3+
-- (city explicitly declines proactive enforcement).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa0dadf-a3c0-41e9-a5de-66582a393622', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4aa0dadf-a3c0-41e9-a5de-66582a393622',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from council context and city policy; no specific Rosenbarger statement on ICE detainer policy found. Bloomington is the only DHS-designated "sanctuary jurisdiction" in Indiana per a 2025 Homeland Security watchlist. The city''s stated position is "we do not inquire about anyone''s immigration status and any person regardless of status should feel safe in calling 911 or contacting police, fire and emergency services." BPD updated its policies in March 2026 to officially prohibit use of Flock license plate reader data for immigration enforcement. On March 5, 2026, the Bloomington City Council voted unanimously to pass a resolution calling for greater oversight of Flock cameras — Rosenbarger voted with this unanimous council. BPD has stated it has "no communication with ICE unless they''re assisting with an arrest warrant related to a criminal matter." Mayor Thomson''s May 2025 statement affirmed that federal immigration enforcement "falls outside the city''s legal authority" and directed residents to community legal resources. The overall city posture — declining to inquire about immigration status, limiting law enforcement contact with ICE to criminal arrest warrants, prohibiting surveillance data from being used for immigration enforcement — maps to value 2 (comply only with court-ordered detainers; protect undocumented crime victims and witnesses from referral). No council resolution specifically refusing all ICE detainers (value 1) was documented. Checked: Indiana Daily Student, B Square Bulletin, Indiana Public Media, Bloomington.in.gov news, The Bloomingtonian.',
  ARRAY[
    'https://www.idsnews.com/article/2026/03/bloomington-city-council-flock-cameras-resolution-hopewell-affordable-housing',
    'https://www.idsnews.com/article/2026/04/bloomington-police-department-bans-flock-data-immigration-reproductive-investigations',
    'https://bloomingtonian.com/2025/05/30/monroe-county-named-indianas-only-sanctuary-jurisdiction-on-homeland-security-watchlist/',
    'https://bloomington.in.gov/news/2025/05/02/6246'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 7. ECONOMIC DEVELOPMENT INCENTIVES (topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Value 2: Small business support and local entrepreneur programs only; avoid large corporate subsidies
-- Evidence: Rosenbarger abstained on the March 2022 Catalent pharmaceutical tax abatement vote,
-- explicitly stating "it's very hard for me to get behind something that is a system that I don't
-- agree with" and "I don't support the tax abatement process." She proposed grant programs and
-- incentives for small businesses to adopt solar and become environmentally sustainable — a small
-- business support focus rather than large corporate tax abatements. This matches value 2 directly.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa0dadf-a3c0-41e9-a5de-66582a393622', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4aa0dadf-a3c0-41e9-a5de-66582a393622',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from abstention statement and proposed alternative programs. Rosenbarger abstained from voting on the March 2022 Catalent pharmaceutical tax abatement (a $350 million capital investment bringing approximately 1,000 jobs). In explaining her abstention she stated: "it''s very hard for me to get behind something that is a system that I don''t agree with," making clear she does not support the tax abatement mechanism as an economic development tool. She acknowledged that the financial incentive makes pragmatic sense for the company, characterizing it as "silly" for Catalent not to pursue the break — hence abstaining rather than voting no — but her stated philosophy opposes using large corporate tax incentives as a city economic development strategy. As an alternative approach, she proposed partnering with the chamber to create grant programs or incentives for small businesses to install solar and become environmentally sustainable, indicating preference for targeted small business support over large corporate subsidies. Value 2 (small business support and local entrepreneur programs only; avoid large corporate subsidies) matches her documented statements and proposed alternatives directly.',
  ARRAY[
    'https://bsquarebulletin.com/2022/03/03/catalent-tax-break-gets-just-a-6-vote-majority-from-9-member-bloomington-city-council-but-its-enough/',
    'https://bsquarebulletin.com/bloomington-city-council-district-2-democratic-party-primary-kate-rosenbarger-sue-sgambelluri/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 8. TRANSPORTATION PRIORITIES (topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Value 1: Prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking
--          requirements citywide
-- Evidence: Rosenbarger explicitly questioned spending $382,000 on road repaving, noting that amount
-- "already exceeds the entire annual budget for the city council sidewalk committee," and asked whether
-- the city should "dump money into helping drivers get around at expense of other forms of
-- transportation." She advocated for protected bicycle lanes on College Mall Road citing the city's
-- transportation plan. She cited Vision Zero strategies to eliminate traffic fatalities. She opposed
-- car-centric transportation investment and supported the March 2025 UDO resolution eliminating
-- minimum parking requirements citywide. Her campaign issue is "safe and accessible streets"
-- prioritizing equity, pedestrian safety, and multimodal access. Value 1 is a direct match.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4aa0dadf-a3c0-41e9-a5de-66582a393622', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4aa0dadf-a3c0-41e9-a5de-66582a393622',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from council committee statements, voting record, and campaign platform. Rosenbarger questioned whether $382,000 should be spent repaving College Mall Road, noting that amount "already exceeds the entire annual budget for the city council sidewalk committee" and asked whether the city should "dump money into helping drivers get around at expense of other forms of transportation." She advocated specifically for protected bicycle lanes on College Mall Road, citing the city''s transportation plan which includes such lanes in its recommended "full build bicycle network." She referenced Vision Zero strategies to eliminate traffic fatalities "while increasing access to safe, healthy, and equitable mobility for all." She noted that Bloomington''s goal is Platinum Ranked Bicycling Community status and that the city "isn''t moving there fast enough." She supported the March 2025 UDO amendment resolution that included eliminating minimum parking requirements citywide — a key policy tool for reducing car-centric development. Her campaign lists "safe and accessible streets" as a core issue emphasizing equitable mobility for all, not just drivers. No evidence of prioritizing road capacity, traffic flow, or highway access as city transportation priorities (values 3-5). Value 1 (prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking requirements citywide) matches her documented statements and positions.',
  ARRAY[
    'https://bsquarebulletin.com/2020/05/14/bloomington-council-committee-digs-into-road-funding-to-weigh-repaving-of-college-mall-road-against-other-transportation-goals/',
    'https://kateforbloomington.org/issues/',
    'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning',
    'https://bsquarebulletin.com/2023/10/05/5-4-bloomington-council-vote-3-more-stops-not-just-dunn-okd-for-reinstallation-on-7-line-bicycle-route/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
