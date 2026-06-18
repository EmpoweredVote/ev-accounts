-- Migration 575: Cambridge City Council + School Committee stances
-- Phase 117 Wave 1 — 16 Cambridge officials, 81 stances
-- government_id: 6f7d55bc-d50c-47ff-b521-5767d1f763fb

BEGIN;

-- ============================================================
-- Yasmin Al-Zubi (City Councillor)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', '669cac97-66a6-4087-b036-936fbe62efb3', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', '669cac97-66a6-4087-b036-936fbe62efb3',
$text$Al-Zubi's stated central policy priority is Cambridge's first Social Housing pilot — municipally owned affordable housing funded by a proposed $50 million bond order. She explicitly supports "maintaining our municipal housing program, or maybe expanding it," and frames housing as a matter of keeping people housed through direct public ownership, not just subsidies or market incentives. This aligns with value 1 (directly build and operate public housing).$text$,
ARRAY['https://www.cambridgeday.com/2026/01/03/can-socialists-on-city-council-make-cambridge-more-affordable/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$text$Al-Zubi voted NO on the Cambridge Street heights zoning ordinance and voted Present on the amendment, citing concern that the compromise gave away leverage before a June 2026 Nexus Study that could reduce affordability requirements. She said "we're giving away our leverage for free," indicating she supports density increases only when tied to robust affordability guarantees — consistent with value 2 (allow modest density increases with design review and community input), prioritizing affordability protections over broad upzoning.$text$,
ARRAY['https://www.cambridgeday.com/2026/01/27/cambridge-street-compromise/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$text$Al-Zubi was endorsed by Cambridge Bicycle Safety as a 'bike champion'; she sponsored the Garden Street policy order that resulted in keeping the street one-way with divided bike lanes on both sides (a 5-4 vote on April 28, 2026); and she expressed safety concerns about making JFK Street two-way because of heavy pedestrian traffic. These actions consistently prioritize pedestrian infrastructure, cycling networks, and street safety over road capacity, matching value 1.$text$,
ARRAY['https://www.cambridgeday.com/2026/04/29/garden-street-tight-vote/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$text$Al-Zubi proposed an amendment to Cambridge's ICE hiring ban to expand it beyond agents who joined after January 20, 2025, to exclude all former ICE/DHS/CBP agents, arguing that "many agents who served under previous administrations remain actively involved in these murderous, illegal operations that are currently unfolding in our communities." This expansive anti-ICE-cooperation stance aligns with value 1 (refuse all ICE detainers, prohibit sharing immigration status information with federal agencies).$text$,
ARRAY['https://www.cambridgeday.com/2026/02/11/city-council-ice-response/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$text$As chair of the Public Safety Committee, Al-Zubi introduced a policy order calling for Cambridge Police to cease using ShotSpotter within 90 days, raising concerns about data sharing and surveillance privacy: "the question becomes not who does ShotSpotter share data with, but who can ShotSpotter share data with." Her focus is on limiting surveillance technology rather than expanding police resources, suggesting she maintains current staffing levels while shifting the approach — matching value 2.$text$,
ARRAY['https://www.cambridgeday.com/2026/05/13/shotspotter-vote-strong-feelings/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$text$Al-Zubi co-sponsored Cambridge's gender-neutral bathrooms policy order (March 2026) alongside the mayor, explicitly framed as protecting transgender and gender-nonconforming residents. She also co-chairs the Human Services and Veterans Committee and self-identifies as a Democratic Socialist who ran on a platform of dignity and equity for renters and lower-income residents. Her record reflects strengthening protections and addressing systemic inequity, matching value 2.$text$,
ARRAY['https://www.cambridgeday.com/2026/03/24/future-bathrooms-gender-neutral/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('236fb3c1-b473-407f-b8a0-d76039b28087', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
$text$Al-Zubi co-sponsored Cambridge City Council's March 2026 policy order requiring gender-neutral bathrooms in new public spaces, explicitly framed as a pro-transgender rights measure to make residents feel safe. Her broader democratic socialist and human rights advocacy stance, combined with co-sponsoring this trans-affirming measure without any restrictions, aligns with value 1 (allow all transgender athletes and individuals on facilities matching their gender identity without restrictions).$text$,
ARRAY['https://www.cambridgeday.com/2026/03/24/future-bathrooms-gender-neutral/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Burhan Azeem (City Councillor)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2358e54-6860-4382-8c8d-95a3dabea874', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2358e54-6860-4382-8c8d-95a3dabea874', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$text$Azeem was a co-sponsor of the original petition to allow six-story buildings citywide (the most aggressive upzoning proposal), voted YES in February 2025 on the final four-story multifamily ordinance that eliminated single- and two-family zoning restrictions citywide, and his official city page credits him with having 'legalized multifamily housing up to six stories throughout the city' in his second term. At the Ordinance Committee stage he stated 'I'm on Team Pass Whatever We Can at this point,' signaling he wanted even broader upzoning. This aligns with stance 4: upzone broadly to allow multifamily by right and streamline approvals.$text$,
ARRAY['https://www.cambridgeday.com/2025/01/20/cambridge-moves-forward-with-four-plus-two-multifamily-plan-final-vote-in-less-than-a-month/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2358e54-6860-4382-8c8d-95a3dabea874', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2358e54-6860-4382-8c8d-95a3dabea874', '669cac97-66a6-4087-b036-936fbe62efb3',
$text$Azeem's official city page documents three housing tools: expanded zoning for 100% affordable housing projects (AHO expansion), removed parking minimums that limited housing development, and legalized multifamily citywide. His approach combines regulatory easing for private development with targeted affordability mandates (inclusionary affordable unit bonuses tied to height), which matches stance 3: offer targeted help like subsidies for affordable projects and easier building permits — not pure market deregulation nor publicly built housing.$text$,
ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/burhanazeem']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2358e54-6860-4382-8c8d-95a3dabea874', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2358e54-6860-4382-8c8d-95a3dabea874', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$text$Azeem voted NO in April 2025 against restoring two-way car traffic on Garden Street (the Transportation Director had recommended keeping the bike-lane-friendly one-way configuration as 'safest for all modes'), and then voted YES in April 2026 to lock in the one-way/bike-lane configuration. His official city page lists 'street safety' as a primary policy focus alongside housing. He also championed removal of parking minimums citywide. Together these actions align with stance 1: prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking requirements citywide.$text$,
ARRAY['https://www.cambridgeday.com/2026/04/29/garden-street-tight-vote/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2358e54-6860-4382-8c8d-95a3dabea874', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2358e54-6860-4382-8c8d-95a3dabea874', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$text$Azeem's official Cambridge City Council page explicitly states he 'played a key role in establishing universal pre-K for all Cambridge residents' and lists universal pre-K as one of his 'primary focuses.' Universal pre-K provided to all residents regardless of income is publicly funded universal childcare, matching stance 1: establishing publicly funded universal childcare so that all families have access regardless of income.$text$,
ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/burhanazeem']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2358e54-6860-4382-8c8d-95a3dabea874', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2358e54-6860-4382-8c8d-95a3dabea874', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$text$In February 2026 the Cambridge City Council voted unanimously — including Azeem — to ban ICE from operating on municipal property, prohibit city employees (including Cambridge Police) from cooperating with ICE agents, and bar CPD from hiring former ICE or DHS enforcement officers. The measures codified existing sanctuary protections into the city's Welcoming Cities Ordinance. This unanimous vote aligns with stance 1: refuse all ICE detainers; prohibit city employees from sharing immigration status information with federal agencies.$text$,
ARRAY['https://cambridgeday.com/2026/02/11/city-council-ice-response/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2358e54-6860-4382-8c8d-95a3dabea874', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2358e54-6860-4382-8c8d-95a3dabea874', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$text$Azeem co-sponsored the original petition for six-story multifamily citywide (the maximum upzoning option on the table), voted YES on the final February 2025 ordinance eliminating single- and two-family zoning restrictions, and in committee stated 'I'm on Team Pass Whatever We Can at this point' to prioritize swift passage of housing reform over waiting for a more comprehensive proposal. His consistent push for streamlined, fast-tracked zoning reform aligns with stance 4: streamline permitting, reduce fees, and actively recruit development to grow the city's tax base.$text$,
ARRAY['https://www.cambridgeday.com/2025/02/10/in-landmark-zoning-reform-cambridge-votes-to-legalize-four-story-multifamily-homes-citywide/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Paul Flaherty (City Councillor)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('34da113e-e5dc-4637-9be1-9d42a6feea93', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('34da113e-e5dc-4637-9be1-9d42a6feea93', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$text$Flaherty co-authored (with Councillor Zusy) a June 2026 policy order asking the Community Development Department to draft language requiring wider setbacks, ground-level open space, and parking requirements above a certain unit threshold for new multifamily buildings — aiming to amend, not abolish, the Feb 2025 Multifamily Housing Ordinance. His 2025 campaign website stated the upzoning 'fails to fully appreciate the economics of new construction' and 'fails to include the voices of abutters and neighbors.' He supports multifamily development near transit stations and ADUs, but with design review and neighborhood input requirements. This aligns with value 2: modest density increases with strong design review and neighborhood input.$text$,
ARRAY['https://www.cambridgeday.com/2026/06/12/will-new-cambridge-buildings-get-cut-down-to-size/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('34da113e-e5dc-4637-9be1-9d42a6feea93', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('34da113e-e5dc-4637-9be1-9d42a6feea93', '669cac97-66a6-4087-b036-936fbe62efb3',
$text$Flaherty supports affordable housing through targeted mechanisms — multifamily near transit stations, ADUs, repurposing vacant office buildings — while opposing blanket citywide upzoning and warning that the MFH Ordinance would let developers convert existing homes into units designed to evade affordability requirements. His policy order with Zusy sought to strengthen affordability protections within the existing zoning framework. He does not advocate for full public housing or market deregulation. This aligns with value 2: requiring new developments to include affordable units and using public policy to fund new housing.$text$,
ARRAY['https://www.cambridgeday.com/2026/06/12/will-new-cambridge-buildings-get-cut-down-to-size/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('34da113e-e5dc-4637-9be1-9d42a6feea93', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('34da113e-e5dc-4637-9be1-9d42a6feea93', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$text$In a 5-2 Cambridge City Council vote in May 2026, Flaherty voted against removing ShotSpotter acoustic surveillance technology, one of only two councillors to do so. He stated: 'I think it's a false narrative to think that federal agents are monitoring conversations that are overheard by ShotSpotter.' The progressive majority voted to remove the technology citing civil liberties and immigration enforcement concerns. Flaherty's defense of police surveillance technology aligns with value 4: increasing police equipment and tools to improve public safety response.$text$,
ARRAY['https://www.cambridgeday.com/2026/05/19/council-drops-shotspotter-in-close-vote/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Marc McGovern (City Councillor)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', '669cac97-66a6-4087-b036-936fbe62efb3',
$text$McGovern authored the Affordable Housing Overlay (passed 2020), which grants height, density, and permitting advantages to 100% affordable housing developers and has generated 600+ affordable units. He raised inclusionary zoning to 20% (highest in the state) and incentive zoning contributions from $4.50 to $33 per square foot. This matches value 2: use rent caps, require new developments to include affordable units, and publicly fund new housing.$text$,
ARRAY['https://www.marcmcgovern.com/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$text$Cambridge Day's 2025 election guide confirms McGovern was one of eight councillors voting for the city's recent upzoning. In June 2026 he explicitly opposed restrictions limiting tall affordable buildings to thoroughfares, saying 'You are pushing those inclusionary units, those low-income folks out to the thoroughfares, the corridors, and not within neighborhoods. I thought one of the points that we all agreed on was that we wanted to do away with exclusionary zoning, which did exactly that.' He is endorsed by A Better Cambridge, a pro-density advocacy group. This matches value 4: upzone broadly to allow multifamily by right and streamline approvals.$text$,
ARRAY['https://www.cambridgeday.com/2026/06/will-new-cambridge-buildings-get-cut-down-to-size/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$text$McGovern was the lead sponsor of the Cycling Safety Ordinance, requiring implementation of a citywide Bike Safety Network by 2027. He was named a 'Bike Champion' by Cambridge Bicycle Safety and his policy page also emphasizes public transit investment and converting the city fleet to electric vehicles. This matches value 1: prioritize pedestrian infrastructure, cycling networks, and public transit.$text$,
ARRAY['https://www.marcmcgovern.com/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$text$McGovern's background as a social worker with at-risk children and families shapes his public safety approach; his policy page emphasizes substance use treatment, inpatient beds, and overdose prevention centers as complements to policing. He voted YES on the ShotSpotter ban in a 7-2 Cambridge City Council vote (May 2026) and supports unarmed crisis response teams. This matches value 2: maintain current police staffing but shift non-violent calls to unarmed mental health co-responders.$text$,
ARRAY['https://www.marcmcgovern.com/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$text$McGovern supported and spoke in favor of Cambridge's July 2025 amendment to the welcoming community ordinance barring city police from cooperating with immigration enforcement. He stated 'This is a horrible and scary time' and argued that asking ICE agents for identification would 'actually put our community at risk.' His 2017 immigrant advocacy included recommitting Cambridge to sanctuary status. This matches value 1: refuse all ICE detainers; prohibit city employees from sharing immigration status information with federal agencies.$text$,
ARRAY['https://www.cambridgeday.com/2025/07/welcoming-community-law-is-changed-slightly-for-council-vote-reflecting-few-options-on-arrests/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$text$McGovern's career as a social worker with children and families, his Cambridge RISE program (direct cash payments to low-income families), his anti-exclusionary-zoning advocacy, and his GBLC endorsement all demonstrate sustained attention to systemic economic and social disparities. His stated goal is practical solutions for 'the most vulnerable' including immigrants, unhoused people, and low-income residents. This matches value 2: strengthen civil rights enforcement and address systemic discrimination.$text$,
ARRAY['https://www.marcmcgovern.com/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', '4938766b-b45a-46e3-93bd-b8b30651271a',
$text$McGovern opened Cambridge's first warming center for the homeless serving 500+ individuals, launched the Winter Warmth Drive raising ~$100k annually, created a documentation assistance program, and founded the Metro Boston Homeless Summit for regional coordination. His policy page states 'the best way to resolve homelessness is to build more homes' and calls for inpatient treatment beds and overdose prevention centers — a service-investment rather than enforcement approach. This matches value 2: decriminalizing public sleeping while investing in shelter capacity, outreach workers, and voluntary service connections.$text$,
ARRAY['https://www.marcmcgovern.com/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$text$McGovern's homelessness strategy centers on shelter expansion (first warming center in Cambridge), outreach through the Winter Warmth Drive, documentation assistance, and Metro Boston Homeless Summit coordination. He emphasizes building more homes as the long-term solution and supports harm reduction (overdose prevention centers). There is no evidence of enforcement-first approaches in his record. This matches value 2: expand shelter capacity and services as the primary strategy; use enforcement only after services are offered.$text$,
ARRAY['https://www.marcmcgovern.com/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$text$McGovern's policy page states he has worked toward moving Cambridge toward '100% renewable energy,' banning single-use plastics, identifying gas leaks, creating solar incentive programs, expanding EV charging infrastructure, and requiring new buildings to be more sustainable — framing climate action as urgent ('As a father, I am terrified at the world my children will inherit'). He endorses public transit investment and building retrofit requirements. This matches value 2: rapidly transition to renewable energy and phase out fossil fuels.$text$,
ARRAY['https://www.marcmcgovern.com/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$text$McGovern served on the Mayor's Early Education Task Force, which created a plan for 'free, universal pre-kindergarten to every 4-year-old in Cambridge' — a $24 million publicly funded program launched September 2024. He has committed to expanding it to earlier ages and directed DHS to develop a plan to expand after-school opportunities to every child who wants them. This matches value 1: establishing publicly funded universal childcare so that all families have access regardless of income.$text$,
ARRAY['https://www.marcmcgovern.com/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$text$McGovern's policy page calls for banning single-use plastics, gas leak identification, 100% renewable energy, and requires new buildings to be more sustainable, but he simultaneously supports the Affordable Housing Overlay and upzoning that increases development density across the city. His record shows consistent environmental standards applied across development rather than strict preservation blocking growth. This matches value 3: apply consistent environmental standards while giving developers reasonable flexibility on implementation.$text$,
ARRAY['https://www.marcmcgovern.com/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', '44905f3b-e105-4f6c-afc7-5d223813dbac',
$text$McGovern supported the Cambridge welcoming community ordinance barring police cooperation with ICE, reaffirmed sanctuary city status since 2017, and his September 2025 letter cited 'active lawsuits against the Trump administration' on immigration. His consistent stance of protecting all residents from immigration enforcement unless they pose a serious criminal threat aligns with value 2: only deport people convicted of serious violent crimes.$text$,
ARRAY['https://www.cambridgeday.com/2025/07/welcoming-community-law-is-changed-slightly-for-council-vote-reflecting-few-options-on-arrests/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$text$McGovern's economic policy page focuses entirely on direct assistance to low-income residents (Cambridge RISE, $500/month cash transfers) and poverty reduction rather than business attraction. He co-created Cambridge RISE targeting families '250% below the federal poverty line' and uses incentive zoning as a tool to require developer contributions to affordable housing rather than to attract employers. This matches value 2: small business support and local entrepreneur programs only; avoid large corporate subsidies.$text$,
ARRAY['https://www.marcmcgovern.com/policy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a8f48816-2ebc-4ae4-9667-a12d4c18f5ec', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$text$McGovern sponsored the Affordable Housing Overlay to enable more development of affordable units, voted yes on the 2025 Cambridge upzoning (8-1 majority), but also acknowledged resident concerns about the pace of change and proposed increasing the signature threshold for resident-initiated zoning petitions. His record shows proactive investment in infrastructure ahead of growth — particularly affordable housing — while managing community input. This matches value 3: plan proactively — invest in infrastructure ahead of growth to support responsible expansion.$text$,
ARRAY['https://www.cambridgeday.com/2026/06/will-new-cambridge-buildings-get-cut-down-to-size/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Patricia Nolan (City Councillor)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$text$Nolan co-sponsored the May 2026 policy order to remove ShotSpotter and voted yes (5-2-2 vote). The removal was framed by co-sponsors around concerns that surveillance data could be shared with federal authorities and that safety should not rely solely on surveillance or policing — consistent with value 2: maintain current police staffing but shift non-violent calls to less surveillance-heavy approaches.$text$,
ARRAY['https://www.cambridgeday.com/2026/05/19/council-drops-shotspotter-in-close-vote/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$text$The Cambridge City Council voted unanimously in February 2026 to codify an ICE ban on municipal property and prohibit city employees from cooperating with ICE enforcement — a measure Nolan supported. In January 2026 she stated 'We will not interfere with the federal immigration work. However, when our own laws are broken, I think we need to proactively think about how do we ensure that our law enforcement can enforce law and order when the laws are being broken by federal officials' — indicating support for refusing ICE cooperation while holding federal agents accountable to local law. This aligns with value 1: refuse all ICE detainers; prohibit city employees from sharing immigration status information with federal agencies.$text$,
ARRAY['https://www.cambridgeday.com/2026/01/28/city-prepares-for-ice/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$text$In August 2021 Nolan co-sponsored both the restitution order (funding programs for drug war victims from cannabis revenue) and the reparations order (directing cannabis revenue to Black-owned businesses) alongside Councillor E. Denise Simmons. She stated she hoped Cambridge would 'get to the work of actually figuring out how it is that we will do both restitution and reparations.' This reflects value 2: strengthen civil rights enforcement and address systemic discrimination.$text$,
ARRAY['https://www.cambridgeday.com/2021/08/04/cambridge-now-has-restitution-and-reparations-on-the-table-awaiting-input-from-the-community/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$text$Nolan voted against maintaining Garden Street as one-way with dedicated bike lanes on both sides, preferring the 2025 decision to revert it to two-way traffic with adjacent bike lanes — stating 'I still maintain my belief that it's safer and better for the whole city, for us to have reverted Garden Street to two-way.' She supports transit via the Zero Emissions plan but her Garden Street vote shows preference for road balance over pure cyclist/pedestrian prioritization. This aligns with value 3: maintain roads while selectively adding transit connections and pedestrian improvements where density supports it.$text$,
ARRAY['https://www.cambridgeday.com/2026/04/29/garden-street-tight-vote/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', '669cac97-66a6-4087-b036-936fbe62efb3',
$text$Nolan voted for the Cambridge Street Corridor height compromise (January 2026), which included affordability requirements (20% affordable floor space for taller buildings) and supports the city's Affordable Housing Overlay. She expressed support for social housing noting its benefits for economic mobility. Her official priorities include 'affordable housing including middle class families.' These actions align with value 2: use rent caps, require new developments to include affordable units, and publicly fund new housing.$text$,
ARRAY['https://www.cambridgeday.com/2026/01/27/cambridge-street-compromise/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$text$Nolan co-proposed the Siddiqui-Nolan amendment (passed 6-3) that reduced the Cambridge Street Corridor height allowances from 8-15 stories down to 6-12 stories with affordability requirements for taller buildings. She stated the amendments were 'very much in line with the Our Cambridge Street work that a huge range of people in the city were involved in,' emphasizing community process. This reflects value 2: allow modest density increases with strong design review and neighborhood input.$text$,
ARRAY['https://www.cambridgeday.com/2026/01/27/cambridge-street-compromise/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$text$Cambridge Day describes Nolan as 'probably the council's staunchest environmental advocate this term.' She championed the Zero Emissions Transportation Plan (targeting fossil-fuel-free transportation by 2050), limited data centers citing grid strain and drought, and halted artificial turf citing PFAS and microplastics. These actions align with value 2: rapidly transition to renewable energy and phase out fossil fuels.$text$,
ARRAY['https://www.cambridgeday.com/2026/04/14/ahern-turf-on-hold/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$text$Nolan brought the policy order to halt Ahern Field's artificial turf installation citing storm drainage reduction, PFAS chemicals, and microplastics, stating 'I really think this is a time when we need to make sure construction doesn't move forward until we have those issues addressed fully.' She also championed data center limits citing Cambridge's Level 3 Critical drought status. These positions align with value 2: protect existing parks and tree canopy strictly; require developers to fully offset any environmental impact.$text$,
ARRAY['https://www.cambridgeday.com/2026/04/14/ahern-turf-on-hold/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeaaf186-3dc4-4ae3-b28f-6a0a0d54c585', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$text$Nolan co-proposed height reductions on the Cambridge Street Corridor petition, reducing from 8-15 stories to 6-12 stories while emphasizing community input gathered over 'several years.' Her Ahern Field intervention also halted development until environmental concerns were fully addressed. This pattern reflects value 2: allow growth only where existing infrastructure can support it; slow approvals until capacity catches up.$text$,
ARRAY['https://www.cambridgeday.com/2026/01/27/cambridge-street-compromise/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- E. Denise Simmons (City Councillor)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', '669cac97-66a6-4087-b036-936fbe62efb3',
$text$As Chair of the Housing Committee, Simmons led the successful push to triple the developer fees toward affordable housing, double the mandatory affordable units in new developments, and pass the Citywide Affordable Housing Overlay zoning ordinance. Her official profile states expanding the supply of affordable housing 'remains central to everything she does on the Council.' This matches value 2: use public requirements on new developments and publicly-directed fees to fund affordable housing.$text$,
ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/denisesimmons']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$text$The Multifamily Housing Ordinance passed 8-1 in February 2025, allowing 4-story buildings as-of-right in all residential zones citywide and eliminating minimum lot size requirements for multifamily construction. Simmons was among the eight yes votes. This matches value 4: upzone broadly to allow multifamily by right.$text$,
ARRAY['https://www.cambridgeday.com/2025/01/31/rejection-of-three-story-zoning-plan-paves-way-for-passage-of-four-story-residential-in-february/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$text$Simmons explicitly stated she would vote yes on a $570,000 police firearm purchase (March 2025), citing the Cambridge Police Department's 'extraordinary jobs around deescalation.' In May 2026, she opposed a policy order to ban ShotSpotter surveillance technology, arguing the process 'infantilizes' Black residents and noting 'I have had my son shot down in the street.' This reflects value 4: supporting police equipment and staffing over redirection of funds to social services.$text$,
ARRAY['https://www.cambridgeday.com/2025/03/30/answers-expected-on-police-request-for-new-guns-are-delayed-again-until-mondays-council-meeting/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$text$In February 2026, the Cambridge City Council unanimously passed an ICE response ordinance codifying a ban on ICE agents operating on municipal property, prohibiting city employees from sharing immigration status information with federal agencies, and barring CPD from hiring former ICE, DHS, or CBP agents. Simmons was part of the unanimous vote. This matches value 1: refuse all ICE detainers and prohibit city employees from sharing immigration status information.$text$,
ARRAY['https://www.cambridgeday.com/2026/02/11/city-council-ice-response/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$text$Simmons' official profile states she advanced legislation establishing an American Freedmen Commission — a body investigating historical harms to descendants of enslaved people and identifying pathways toward reparations. She opened cannabis licensing pathways for women and minority entrepreneurs, chairs the Civic Unity Committee, and in 2021 authored a reparations order linking cannabis revenue to Black business empowerment. This matches value 1: mandate racial equity requirements in all institutions and provide reparations.$text$,
ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/denisesimmons']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$text$Simmons voted with the council to accept the city manager's recommendation to close the 58-bed Transition Wellness Center while 'bulking up services' in the Cambridge budget. She insisted 'a renovated building without accountability is just a nicer place to be ignored' when addressing shelter renovation at 240 Albany St — indicating services expansion combined with institutional accountability standards. This aligns with value 3: invest in outreach, shelter, and mental health services while enforcing reasonable public space rules.$text$,
ARRAY['https://www.cambridgeday.com/2025/04/29/council-concedes-to-closing-a-homeless-shelter-while-bulking-up-services-in-cambridge-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00565708-5520-418d-afec-58a295d0d8ec', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
$text$Simmons was on the Cambridge City Council when Cambridge City Hall became the first US municipality to issue same-sex marriage licenses in 2004. She later married her same-sex partner Mattie Hayes in 2009 and is documented as the first openly lesbian African-American mayor in the United States, elected unanimously in 2008. Her personal life and council record directly confirm support for requiring all states to recognize same-sex marriages and federal protections — value 1.$text$,
ARRAY['https://en.wikipedia.org/wiki/E._Denise_Simmons']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jivan Sobrinho-Wheeler (City Councillor)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad060f52-145c-41e3-8bd1-c454ac1ed46c', '669cac97-66a6-4087-b036-936fbe62efb3', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad060f52-145c-41e3-8bd1-c454ac1ed46c', '669cac97-66a6-4087-b036-936fbe62efb3',
$text$Sobrinho-Wheeler is the lead sponsor of Cambridge's social housing initiative, which he described in October 2025 as 'part of this paradigm shift around thinking of housing as a human right, rather than as a commodity to be speculated on.' The proposed model uses public ownership for permanent affordability. This aligns with value 1: directly build and operate public housing so anyone who needs a home can get one.$text$,
ARRAY['https://www.cambridgeday.com/2025/10/02/exploration-of-social-housing-given-a-step-forward-by-cambridge-councillors-amid-affordability-crisis/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad060f52-145c-41e3-8bd1-c454ac1ed46c', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad060f52-145c-41e3-8bd1-c454ac1ed46c', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$text$As co-chair of the housing committee, Sobrinho-Wheeler spoke against proposed setback and height restrictions on the 2025 Multifamily Housing Ordinance in June 2026, arguing: 'If someone doesn't want live in a house like mine that has less than a ten-foot setback, no one is forcing them to. What is wrong with the house I live in?' He opposed amendments that would restrict dense multifamily development. This aligns with value 4: upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements.$text$,
ARRAY['https://www.cambridgeday.com/2026/06/12/will-new-cambridge-buildings-get-cut-down-to-size/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad060f52-145c-41e3-8bd1-c454ac1ed46c', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad060f52-145c-41e3-8bd1-c454ac1ed46c', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$text$Sobrinho-Wheeler co-sponsored and voted yes (5-2 majority) in May 2026 to drop ShotSpotter technology, stating 'Let's actually use proven technologies … rather than some security theater.' His position — skeptical of surveillance tech, supportive of crisis response integration — aligns with value 2: maintain current police staffing but shift non-violent calls to unarmed mental health co-responders.$text$,
ARRAY['https://www.cambridgeday.com/2026/05/19/council-drops-shotspotter-in-close-vote/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad060f52-145c-41e3-8bd1-c454ac1ed46c', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad060f52-145c-41e3-8bd1-c454ac1ed46c', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$text$Cambridge's entire City Council voted unanimously in February 2026 to ban ICE from city property and prohibit city employees from cooperating with ICE enforcement — codified into the Welcoming Cities Ordinance. Sobrinho-Wheeler was part of this unanimous vote. This aligns with value 1: refuse all ICE detainers; prohibit city employees from sharing immigration status information with federal agencies.$text$,
ARRAY['https://cambridgeday.com/2026/02/11/city-council-ice-response/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad060f52-145c-41e3-8bd1-c454ac1ed46c', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad060f52-145c-41e3-8bd1-c454ac1ed46c', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$text$Sobrinho-Wheeler's lead sponsorship of the social housing initiative frames housing as 'a human right, rather than as a commodity to be speculated on,' with the goal of permanent affordability through public ownership rather than criminalization. He committed to maintaining funding for housing, mental and behavioral health, and education. This aligns with value 1: housing-first — provide permanent supportive housing with no preconditions; avoid criminalization entirely.$text$,
ARRAY['https://www.cambridgeday.com/2025/10/02/exploration-of-social-housing-given-a-step-forward-by-cambridge-councillors-amid-affordability-crisis/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad060f52-145c-41e3-8bd1-c454ac1ed46c', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad060f52-145c-41e3-8bd1-c454ac1ed46c', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$text$Sobrinho-Wheeler worked as New England Progressive Governance Director for the Working Families Party on social equity legislation, identifies as a democratic socialist, and frames Cambridge's economic and political systems in terms of democratic accountability. The January 2026 article describes him as committed to 'fighting for democracy not just in our political system...but in our economy,' emphasizing democratic control over economic institutions. This is consistent with value 2: strengthen civil rights enforcement and address systemic discrimination.$text$,
ARRAY['https://www.cambridgeday.com/2026/01/03/can-socialists-on-city-council-make-cambridge-more-affordable/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Olivia Zusy (City Councillor)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$text$Zusy was the sole NO vote on the February 10, 2025 Multifamily Housing Ordinance (8-1), which eliminated single- and two-family zoning citywide by legalizing four-story multifamily buildings. She also voted against the Cambridge Street corridor upzoning in January 2026. In June 2026 she co-sponsored Councillor Flaherty's policy order proposing MHO modifications — wider setbacks, ground-level open space, and parking requirements — stating 'I'm not proposing that we rescind [the MHO]. I just feel like, you have a rough draft of [a] good policy, it makes sense to improve upon what you've got.' This matches stance 2: allow modest density increases with strong design review and neighborhood input.$text$,
ARRAY['https://www.cambridgeday.com/2025/02/10/in-landmark-zoning-reform-cambridge-votes-to-legalize-four-story-multifamily-homes-citywide/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', '669cac97-66a6-4087-b036-936fbe62efb3',
$text$Zusy accepts the need for more housing in principle but focuses on design standards, process, and wraparound services rather than broad expansion of supply or public financing. She said the MHO is 'a rough draft of a good policy' that needs improvement, not rescission, and pushed for setback and parking requirements in new multifamily buildings. This aligns with stance 3: targeted help like easier building permits paired with quality standards, not mandate-driven affordability or public construction.$text$,
ARRAY['https://www.cambridgeday.com/2026/06/12/will-new-cambridge-buildings-get-cut-down-to-size/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$text$Zusy sponsored the policy order to update Cambridge's Tree Protection Ordinance, stating: 'Trees cool us, they absorb water and prevent flooding … they absorb carbon.' She was the sole councillor to vote against Marc McGovern's amendment that would have subordinated tree protections to housing development needs — meaning she prioritized tree protection over development flexibility. This matches stance 2: protect existing parks and tree canopy strictly; require developers to fully offset any environmental impact.$text$,
ARRAY['https://www.cambridgeday.com/2026/06/05/the-lorax-comes-to-cambridge-city-council/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$text$The Cambridge City Council voted unanimously in February 2026 to codify an executive order banning ICE agents from municipal property, prevent city employees from collaborating with ICE, and bar Cambridge Police from hiring former ICE or Homeland Security agents. Zusy voted in favor of this unanimous measure. This matches stance 1: refuse all ICE detainers and prohibit city employees from sharing immigration status information with federal agencies.$text$,
ARRAY['https://www.cambridgeday.com/2026/02/11/city-council-ice-response/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$text$On the solar zoning debate, Zusy stated: 'Balance is key. We have to have a balanced view. We do want to build housing, but we also have sustainability goals.' She frames her Tree Protection Ordinance work around climate benefits (carbon absorption, flood prevention) but emphasizes balance between housing production and net-zero climate objectives. This matches stance 3: invest in clean energy while gradually reducing reliance on fossil fuels.$text$,
ARRAY['https://www.cambridgeday.com/2025/10/08/higher-cambridge-construction-fees-get-a-study-and-council-deals-with-park-safety-solar-zoning/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$text$Zusy voted unanimously with the council to direct the city manager to expand the 240 Albany Street homeless shelter, and separately advocated for preserving wraparound services at the Transitional Wellness Center, stating 'I want us to learn from the Transitional Wellness Center, because I think those wraparound services really provide support.' She engages with shelter quality and services without advocating for criminalization or strict enforcement. This matches stance 3: invest in outreach, shelter, and mental health services while enforcing reasonable public space rules.$text$,
ARRAY['https://www.cambridgeday.com/2025/04/29/council-concedes-to-closing-a-homeless-shelter-while-bulking-up-services-in-cambridge-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e44fdba7-5fd0-43c2-a125-c999b0a0bb97', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$text$Zusy was the sole NO vote on the February 2025 Multifamily Housing Ordinance, and voted against the January 2026 Cambridge Street corridor zoning ordinance (voting yes only on the height-lowering amendment). She advocates for improving housing policy with more community process rather than streamlining approvals. This matches stance 2: allow growth only where existing infrastructure can support it; slow approvals until capacity catches up.$text$,
ARRAY['https://www.cambridgeday.com/2026/01/27/cambridge-street-compromise/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Yi-An Huang (City Manager)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('af870d90-718a-4d0c-a267-8436e84720ba', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('af870d90-718a-4d0c-a267-8436e84720ba', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$text$Huang issued a public statement in May 2025 explicitly rejecting federal immigration enforcement in Cambridge: 'as a welcoming community, we do not support this federal administration's approach to immigration enforcement, which is detaining community members without due process.' He committed to 'prioritize public safety decisions that are in the best interests of our residents, while protecting their dignity, safety, and rights, regardless of immigration status.' This matches value 1: refuse ICE detainers and prohibit sharing immigration status information with federal agencies.$text$,
ARRAY['https://www.cambridgeday.com/2025/05/30/cambridge-and-somerville-are-named-on-list-identifying-sanctuary-jurisdictions-by-feds/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('af870d90-718a-4d0c-a267-8436e84720ba', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('af870d90-718a-4d0c-a267-8436e84720ba', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$text$In April 2025, Huang recommended closing a temporary shelter and redirecting funds to permanent supportive housing: 'We have spent over $10 million on 58 beds of temporary shelter while with a one-time $10 million investment at 116 Norfolk St., we leveraged additional public and private funding to create 62 beds of permanent shelter that will continue to serve people for decades.' His FY27 budget allocated $16 million for homelessness and housing stability, emphasizing permanent housing. This matches value 1: housing-first, provide permanent supportive housing with no preconditions.$text$,
ARRAY['https://www.cambridgeday.com/2025/04/29/council-concedes-to-closing-a-homeless-shelter-while-bulking-up-services-in-cambridge-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('af870d90-718a-4d0c-a267-8436e84720ba', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('af870d90-718a-4d0c-a267-8436e84720ba', '669cac97-66a6-4087-b036-936fbe62efb3',
$text$Huang's FY27 budget proposal allocates over $51 million for affordable housing including 'social housing development plans,' with the city directly funding creation of permanent affordable units. Prior budget documents show $18.5 million committed to creating 96 units of permanent supportive housing. This matches value 2: publicly fund new housing and require affordable unit creation.$text$,
ARRAY['https://www.cambridgeday.com/2026/04/29/cambridge-billion-dollar-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('af870d90-718a-4d0c-a267-8436e84720ba', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('af870d90-718a-4d0c-a267-8436e84720ba', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$text$Huang's FY27 budget proposes $5 million to explore publicly funded early childcare for children too young for Cambridge's existing Universal Pre-K program, expanding the public childcare investment pipeline. The city already operates Universal Pre-K; this proposal extends public investment to younger age groups. This matches value 2: significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families.$text$,
ARRAY['https://www.cambridgeday.com/2026/04/29/cambridge-billion-dollar-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Sumbul Siddiqui (Mayor / City Councillor)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', '669cac97-66a6-4087-b036-936fbe62efb3',
$text$Siddiqui sponsored the City of Cambridge Tenants Rights and Resources Ordinance (2020) for housing stability; cast the deciding vote for more affordable housing in the East Cambridge Courthouse development (2019); preserved 500+ affordable units at Fresh Pond Apartments (2021) and expanded the Homebridge eligibility to 120% AMI; and authored a housing voucher policy order passed 8-0 (2024). Her record reflects consistent public subsidy, inclusionary requirements, and tenant protections — matching use of rent caps, requiring affordable units in developments, and publicly funding housing.$text$,
ARRAY['https://en.wikipedia.org/wiki/Sumbul_Siddiqui']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$text$Siddiqui established a Climate Crisis Working Group (2022) and supported a tree protection ordinance (2021). Cambridge under her administration runs greenhouse gas reduction programs, EV charging infrastructure, and energy efficiency initiatives earning a 5-STAR sustainability certification. Her approach — clean energy investment and gradual emissions reduction without a declared emergency or carbon ban — aligns with investing in clean energy while gradually reducing reliance on fossil fuels.$text$,
ARRAY['https://en.wikipedia.org/wiki/Sumbul_Siddiqui']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', '4938766b-b45a-46e3-93bd-b8b30651271a',
$text$In May 2021 Siddiqui appointed an ad-hoc homelessness working group and specifically advocated for non-congregate shelter options rather than criminalization. This services-first approach — expanding shelter access and outreach — aligns with decriminalizing public sleeping while investing in shelter capacity and voluntary service connections.$text$,
ARRAY['https://en.wikipedia.org/wiki/Sumbul_Siddiqui']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$text$Siddiqui's 2021 ad-hoc homelessness working group advocated for non-congregate shelters and a services-led approach. Cambridge under her leadership prioritizes services expansion and shelter capacity as the primary homelessness response rather than anti-camping enforcement — consistent with expanding shelter capacity and services as the primary strategy.$text$,
ARRAY['https://en.wikipedia.org/wiki/Sumbul_Siddiqui']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$text$Siddiqui eliminated library fines that 'disproportionately affect low-income residents and families of color' (2020); launched Cambridge RISE and Rise Up Cambridge guaranteed income pilots targeting families below 250% FPL (2021-2023); and advocated for inclusive school meals for Muslim students. These actions reflect a consistent focus on addressing systemic barriers for marginalized groups — aligning with strengthening civil rights enforcement and addressing systemic discrimination.$text$,
ARRAY['https://en.wikipedia.org/wiki/Sumbul_Siddiqui']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$text$Siddiqui launched Cambridge RISE (2021) providing $500/month for 18 months to 130 single caretakers and Rise Up Cambridge (2023) giving $500/month to nearly 2,000 families earning under 250% of the Federal Poverty Line. These publicly funded direct-subsidy programs directly reduce childcare and living cost burdens for low- and middle-income families — aligning with significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families.$text$,
ARRAY['https://en.wikipedia.org/wiki/Sumbul_Siddiqui']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$text$Cambridge under Siddiqui implemented Vision Zero (20 mph on most streets), a 2020 Bike Plan, and bus priority lanes while the city states it emphasizes 'sustainable modes of transportation such as walking, biking and using transit.' Siddiqui's own senior residents page notes she is 'mindful' of bike infrastructure's impact on seniors who drive, indicating balanced multimodal investment — consistent with investing equally in roads and multimodal options and requiring bike lanes and sidewalks on new road projects.$text$,
ARRAY['https://www.cambridgema.gov/cdd/transportation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cc61015f-dba2-4f52-9f1f-832ef23f6595', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$text$The Cambridge City Council voted 8-1 in January 2025 to advance a four-story residential upzoning ordinance, with Siddiqui as Mayor/Councilor in the 8-vote majority. Cambridge also adopted the Affordable Housing Overlay allowing dense 100% affordable projects by right citywide. This direction — broadly allowing multifamily housing with streamlined approvals — aligns with upzoning broadly to allow multifamily by right and streamlining approvals and reducing parking requirements.$text$,
ARRAY['https://cambridgeday.com/2025/01/31/rejection-of-three-story-zoning-plan-paves-way-for-passage-of-four-story-residential-in-february/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Luisa de Paula Santos (School Committee)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca2ff1d9-8ebe-4cf2-a804-27d73c58340b', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca2ff1d9-8ebe-4cf2-a804-27d73c58340b', '00b95a6a-75db-4521-b523-3326bba938de',
$text$De Paula Santos ran as the only MTA (teachers union) member working inside a public school classroom. Her campaign explicitly called for fully funded schools and reallocation of resources to student-facing supports. Endorsed by the Cambridge Education Association and Our Revolution Cambridge — both of which oppose school vouchers. Her platform statement calls for making every neighborhood school a thriving well-resourced community hub with no mention of voucher or charter options. This aligns with value 1: fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions.$text$,
ARRAY['https://www.cambridgeresidentsalliance.org/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca2ff1d9-8ebe-4cf2-a804-27d73c58340b', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca2ff1d9-8ebe-4cf2-a804-27d73c58340b', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$text$De Paula Santos made implementing restorative justice frameworks her key platform priority to address inequities in student discipline across lines of race and wealth. She specifically stated that tying administrator evaluations to equity goals would be key. Her Our Revolution Cambridge endorsement page describes her as committed to advancing Cambridge Public Schools' anti-racist mission and closing resource and opportunity gaps. This consistent focus on addressing systemic racial and economic disparities in school discipline and resource allocation aligns with value 2: strengthen civil rights enforcement and address systemic discrimination.$text$,
ARRAY['https://www.cambridgeday.com/2025/10/30/cambridge-school-committee-election-guide-2025/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Caitlin Dube (School Committee)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c2a5bfd4-a756-4da5-8902-11ee3846cb3a', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c2a5bfd4-a756-4da5-8902-11ee3846cb3a', '00b95a6a-75db-4521-b523-3326bba938de',
$text$Dube's campaign platform centers entirely on strengthening public schools: equity-weighted lottery within the public system, 100% after-school access for every family, universal pre-K, community school hubs, and micro-grants for educator-led innovation. No mention of vouchers or charter alternatives. She is endorsed by the Cambridge Education Association (teachers union) and Our Revolution Cambridge, both of which oppose school voucher programs. Aligns with value 1: fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions.$text$,
ARRAY['https://www.caitlinforcambridge.com/priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c2a5bfd4-a756-4da5-8902-11ee3846cb3a', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c2a5bfd4-a756-4da5-8902-11ee3846cb3a', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$text$Dube's priorities page calls for universal pre-K strengthening with publicly provided literacy-rich classrooms and '100% after-school access for every family' — a universal public provision model for early childhood and out-of-school care. This aligns with value 1: establishing publicly funded universal childcare so all families have access regardless of income.$text$,
ARRAY['https://www.caitlinforcambridge.com/priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c2a5bfd4-a756-4da5-8902-11ee3846cb3a', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c2a5bfd4-a756-4da5-8902-11ee3846cb3a', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$text$Our Revolution Cambridge's endorsement of Dube highlights her commitment to advancing Cambridge Public Schools' 'anti-racist mission' and 'closing resource gaps.' Her own website describes her goal as 'closing achievement gaps in Cambridge and beyond by identifying and dismantling barriers to learning, belonging, and democratic participation.' This systemic-equity framing aligns with value 2: strengthening civil rights enforcement and addressing systemic discrimination.$text$,
ARRAY['https://ourrevolutioncambridge.org/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Richard Harding, Jr. (School Committee)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03e962a0-559e-4ec3-9e41-9a8a933467b2', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03e962a0-559e-4ec3-9e41-9a8a933467b2', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$text$Harding is Vice-President of the Cambridge NAACP and received the NAACP Education Excellence Award and Cambridge Peace and Justice Award. His cpsd.us biography documents organizing community forums on policing and criminal justice and serving on the Cambridge Police Commissioner's Advisory Committee. He co-founded Port Action Group to connect formerly incarcerated individuals with resources — a direct violence-prevention and reentry equity initiative. This sustained institutional engagement with racial equity, policing reform, and incarceration justice aligns with value 2: strengthen civil rights enforcement and address systemic discrimination.$text$,
ARRAY['https://www.cpsd.us/school_committee/school-committee-members-subcommittees/richard-harding']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Arjun Jaikumar (School Committee)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0342bc7c-a470-4013-897e-237d77265c06', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0342bc7c-a470-4013-897e-237d77265c06', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$text$Jaikumar explicitly stated 'The primary drivers of achievement gaps are economic inequality and systemic racism' and supports addressing racial disparities in student discipline and providing wraparound support services for families. His entire platform centers on reducing these systemic inequities within the public school system. This aligns with value 2: strengthen civil rights enforcement and address systemic discrimination.$text$,
ARRAY['https://www.cambridgeday.com/2025/11/02/after-taking-on-trump-jaikumar-was-called-to-run-by-a-lack-of-transparency-from-school-committee/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0342bc7c-a470-4013-897e-237d77265c06', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0342bc7c-a470-4013-897e-237d77265c06', '00b95a6a-75db-4521-b523-3326bba938de',
$text$Jaikumar's CPSD biography states 'strong public schools are essential to a thriving, inclusive community' and his entire platform centers on expanding public school instructional models (e.g., extending Tobin Montessori co-teaching to other public schools) with no mention of vouchers or charter alternatives. He is endorsed by Our Revolution Cambridge, which opposes voucher programs. This aligns with value 1: fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions.$text$,
ARRAY['https://www.cpsd.us/school_committee/school-committee-members-subcommittees/arjun-jaikumar']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- David Weinstein (School Committee)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7dafe688-b8ef-4b49-b6ab-fce66e443fa0', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7dafe688-b8ef-4b49-b6ab-fce66e443fa0', '00b95a6a-75db-4521-b523-3326bba938de',
$text$Weinstein is a former public school teacher and 4-term incumbent who co-sponsored algebra-for-all in Cambridge public schools and advocates for a 'success planning' system with wraparound services — entirely within the public school system. He is endorsed by Our Revolution Cambridge, whose 2025 platform explicitly commits to 'defending public education against federal threats' and opposing privatization. No evidence of any support for vouchers or charter diversion. Aligns with value 1: fully funding public schools and eliminating voucher programs.$text$,
ARRAY['https://www.cambridgeday.com/2025/10/30/cambridge-school-committee-election-guide-2025']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7dafe688-b8ef-4b49-b6ab-fce66e443fa0', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7dafe688-b8ef-4b49-b6ab-fce66e443fa0', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$text$Our Revolution Cambridge's 2025 endorsement of Weinstein cites his commitment to 'advancing Cambridge Public Schools' anti-racist mission' and 'closing resource and opportunity gaps' — framing aligned with value 2 (strengthen civil rights enforcement and address systemic discrimination). His advocacy for success planning with individualized supports and mental health services targets equity gaps by design. The endorsement platform also supports replacing MCAS with culturally responsive assessments.$text$,
ARRAY['https://www.ourrevolutioncambridge.org']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
