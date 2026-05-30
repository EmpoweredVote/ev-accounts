BEGIN;

-- ============================================================
-- Migration 124: Local Lens compass stances for Matt Flaherty
-- Bloomington City Common Council, At Large
-- politician_id: 7dc7e4a1-9e52-4287-a100-6e1d715b5085
-- Researched: 2026-05-11
-- ============================================================

-- 1. AFFORDABLE HOUSING (topic_id: 669cac97-66a6-4087-b036-936fbe62efb3)
-- Value 2: Use rent caps, require new developments to include affordable units, and publicly fund new housing
-- Evidence: Flaherty co-signed council letter demanding the Hopewell South PUD set 25-50% of units as
-- permanently affordable (vs. the developer's proposed 15%). His campaign platform supports housing vouchers,
-- development incentive requirements, and community land trusts. He has pushed to fund the city's affordable
-- housing pilot fund via PILOT revenues. His approach centers on mandatory requirements on private
-- developments and targeted public subsidy — not direct government construction (value 1) nor market-only
-- solutions (values 4-5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7dc7e4a1-9e52-4287-a100-6e1d715b5085', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7dc7e4a1-9e52-4287-a100-6e1d715b5085',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from council votes, public statements, and campaign platform. Flaherty co-signed a March 2026 letter by six council members calling on Mayor Thomson to revise the Hopewell South PUD so that 25–50% of units would be permanently affordable (the developer proposed 15%). His published platform supports affordable housing through housing choice vouchers, development code incentive requirements, and community land trusts. He also supported Resolution 2025-13 establishing an Affordable Housing Pilot Fund financed by PILOT revenues. His approach centers on mandatory affordability requirements for private developments and public subsidy tools, matching value 2 — not direct government construction of housing (value 1), and not market-only deregulation (values 4–5).',
  ARRAY[
    'https://www.ipm.org/news/2026-03-31/city-council-members-ask-mayor-to-change-hopewell-proposal',
    'https://www.idsnews.com/article/2026/03/majority-of-bloomington-033126',
    'https://www.ballotready.org/people/matt-flaherty',
    'https://bloomington.in.gov/council/legislation/Resolution/2025/2025-13'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 2. CRIMINALIZATION OF HOMELESSNESS (topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a)
-- Value 1: Protecting the right to sleep in public spaces and redirecting enforcement budgets toward
-- permanent supportive housing and mental health services.
-- Evidence: Flaherty (a) voted against the 2023 anti-camping ordinance that would have banned sleeping
-- on sidewalks/streets; (b) co-sponsored an earlier ordinance requiring 15-day notice before camp
-- displacement AND requiring sufficient permanent or transitional housing availability before any
-- displacement can occur; (c) established that "the current answer is: Nowhere" (no legal sleeping
-- location exists); (d) stated government has "an obligation to secure the basic rights, dignity and
-- security of all residents, including our unhoused residents"; (e) framed the anti-camping measure
-- as violating "our unhoused neighbors' basic rights."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7dc7e4a1-9e52-4287-a100-6e1d715b5085', '4938766b-b45a-46e3-93bd-b8b30651271a', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7dc7e4a1-9e52-4287-a100-6e1d715b5085',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Inferred from council votes and direct quotes. In September 2023 Flaherty voted against an ordinance that would have prohibited camping on city sidewalks and streets. Earlier (2021) he co-sponsored an encampment protection ordinance that required (a) 15-day notice before camp displacement and (b) sufficient permanent or transitional housing availability as a precondition for any displacement. He stated: "I would say violations of our unhoused neighbors'' basic rights, for a start. For instance, being evicted from public space without notice." He established that the city has no legal sleeping location for unhoused people ("We clarified that the current answer is: Nowhere") and asserted that "government does have an obligation to secure the basic rights, dignity and security of all residents, including our unhoused residents." He criticized the anti-camping ordinance as "very disingenuous" in framing enforcement as an accessibility issue. This record — rights framing, housing-first precondition, opposition to enforcement without shelter availability — aligns with value 1.',
  ARRAY[
    'https://bsquarebulletin.com/bloomingtons-proposed-law-protecting-encampments-puts-housing-first-we-cant-shelter-our-way-out-of-this-problem/',
    'https://www.ipm.org/2023-09-14/city-council-rejects-effort-to-prevent-camping-on-sidewalks-streets',
    'https://bsquarebulletin.com/proposed-law-on-protections-for-bloomingtons-houseless-population-prompts-question-what-are-a-citys-core-services/',
    'https://bsquarebulletin.com/2021/02/22/proposed-ordinance-giving-protections-to-houseless-encampments-gets-a-look-from-bloomington-human-rights-group/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 3. RESIDENTIAL ZONING (topic_id: d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Value 4: Upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements
-- Evidence: Flaherty has been described as Bloomington's "most outspoken pro-upzoning advocate." He
-- sponsored a March 2025 resolution directing the plan commission to eliminate minimum parking requirements
-- in ALL zones. He voted to introduce (4-4 tie failed) resolutions that would allow duplexes, triplexes,
-- and fourplexes by right in single-family residential zones. He explicitly supports "missing middle housing"
-- for its racial and income diversity benefits. The anti-upzoning group called his Comprehensive Plan
-- reading disingenuous: "Depending on how you want to read the Comprehensive Plan, you can kind of read
-- into it what you want." His legislative agenda (eliminate parking minimums, allow any multiplexes by right,
-- streamline UDO approvals) maps squarely to value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7dc7e4a1-9e52-4287-a100-6e1d715b5085', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7dc7e4a1-9e52-4287-a100-6e1d715b5085',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from voting record and public statements. Flaherty has been called Bloomington''s "most outspoken pro-upzoning advocate." In March 2025 he sponsored a resolution directing the city plan commission to eliminate minimum parking requirements in ALL residential and commercial zones — the broadest possible parking reform. He also voted to introduce a companion resolution (the 4-4 tie blocked introduction) that would have allowed duplexes, triplexes, and fourplexes by right in single-family zones citywide. He is publicly documented advocating for "missing middle housing," arguing that such forms support racially and economically diverse populations. His stated quote — "Depending on how you want to read the Comprehensive Plan, you can kind of read into it what you want" — reflects a willingness to advance density reform aggressively rather than defer to neighborhood input. His specific legislative agenda (eliminate parking minimums, allow multiplexes by right citywide, streamline UDO approvals) is consistent with value 4 (upzone broadly, streamline approvals, reduce parking requirements). There is no evidence of support for eliminating all single-family zoning on every lot citywide (value 5).',
  ARRAY[
    'https://stopbtownupzoning.org/2021/06/06/matt-flaherty-says-the-quiet-part-out-loud/',
    'https://bsquarebulletin.com/start-of-process-for-possible-zoning-changes-halted-with-4-4-votes-by-bloomington-city-council/',
    'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning',
    'https://www.idsnews.com/article/2025/04/city-council-mayor-upzoning-disagreement-udo-housing-density'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 4. CIVIL RIGHTS AND SOCIAL JUSTICE (topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Value 2: Strengthen civil rights enforcement and address systemic discrimination
-- Evidence: Flaherty stated in the 2026 budget debate: "For me, that is the defining value of what it
-- means to be liberal, what it means to me to be a Democrat. Virtually all decisions in other policy
-- areas flow from this [equity], and in my view, we simply aren't integrating equity as a value in
-- government in a consistent or meaningful way most of the time." His campaign platform explicitly
-- calls for a racial equity framework in budgeting/legislation and for addressing disparities in
-- housing ownership, transit ridership, and arrest/incarceration rates. He voted against the 2026
-- budget partly on equity grounds. No evidence of reparations mandates (value 1) or limiting
-- enforcement (values 3-5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7dc7e4a1-9e52-4287-a100-6e1d715b5085', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7dc7e4a1-9e52-4287-a100-6e1d715b5085',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from direct quotes and platform statements. During the 2026 budget debate Flaherty stated: "For me, that is the defining value of what it means to be liberal, what it means to me to be a Democrat. Virtually all decisions in other policy areas flow from this [equity], and in my view, we simply aren''t integrating equity as a value in government in a consistent or meaningful way most of the time." He voted against the 2026 budget in part on equity grounds. His published campaign platform calls for integrating a racial equity framework into budgeting and legislative decisions, and specifically addresses disparities in housing ownership, transit ridership, and arrest and incarceration rates. This reflects a systemic approach to civil rights — matching value 2 (strengthen civil rights enforcement, address systemic discrimination). No evidence of support for reparations mandates (value 1) or limiting civil rights enforcement (values 3–5).',
  ARRAY[
    'https://bsquarebulletin.com/163m-budget-for-2026-okd-by-bloomington-councilmembers-2-dissent-citing-lack-of-trust/',
    'https://www.ballotready.org/people/matt-flaherty',
    'https://www.idsnews.com/article/2025/10/bloomington-city-council-adopts-2026-budget'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 5. PUBLIC SAFETY APPROACH (topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Value 3: Keep current public safety funding while adding crisis response teams for mental health and addiction calls
-- Evidence: Flaherty voted FOR the 2024 police salary ordinance (approving pay raises). He raised
-- accountability/transparency concerns about the $30M police/fire headquarters appropriation without
-- advocating for cutting police budgets. He dissented on the 2026 budget over trust and equity concerns,
-- not over police spending specifically. No record of calling to defund or redirect police dollars to social
-- services. No documented position on co-responder programs. His equity framing and progressive stance
-- suggest he would likely support crisis response additions, but no direct evidence found.
-- Placed at value 3 (keep current funding + add crisis response) as the most evidence-consistent position.
-- Note: this is an inference; no direct quote on co-responder programs or police budget philosophy was found.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7dc7e4a1-9e52-4287-a100-6e1d715b5085', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7dc7e4a1-9e52-4287-a100-6e1d715b5085',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from voting record; no direct statement on police budget philosophy found. Flaherty voted in favor of the 2024 police salary ordinance that approved pay raises for officers. He raised accountability and transparency concerns about the $30 million police/fire headquarters appropriation (arguing funds were not used as the appropriating ordinances specified) but did not call for reducing police budgets. He voted against the 2026 budget on equity and trust grounds, not on police spending. He noted that reducing overtime would require hiring additional officers — suggesting he understood staffing-level tradeoffs rather than advocating for cuts. No statements or votes on co-responder programs, mental health diversion units, or defunding police were found. His equity-focused progressive record and support for social services (Jack Hopkins grants) are consistent with value 3 (keep current public safety funding while adding crisis response), but this is an inference. Checked: B Square Bulletin, Indiana Public Media, Indiana Daily Student, city budget coverage 2023–2026.',
  ARRAY[
    'https://bsquarebulletin.com/2023/10/12/unchanged-2024-budget-okd-by-bloomington-council-after-debate-on-police-pay-econ-development-money/',
    'https://bsquarebulletin.com/163m-budget-for-2026-okd-by-bloomington-councilmembers-2-dissent-citing-lack-of-trust/',
    'https://www.idsnews.com/article/2025/10/bloomington-city-council-adopts-2026-budget'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 6. LOCAL IMMIGRATION ENFORCEMENT (topic_id: b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Value 2: Comply only with court-ordered detainers; protect undocumented crime victims and witnesses from referral
-- Evidence: The full Bloomington City Council (including Flaherty) voted unanimously (9-0) in March 2026
-- for a resolution restricting Flock license plate reader data from being used for immigration investigations.
-- The council unanimously supported ending the Flock contract in April 2026. Monroe County was listed by
-- DHS as Indiana's only "sanctuary jurisdiction" in 2025. Bloomington's overall posture is welcoming/
-- non-cooperative with ICE, but no specific Flaherty quote on ICE detainers was found. Placed at value 2
-- (court-ordered detainers only; protect undocumented victims) as the position most consistent with
-- his unanimous votes limiting immigration data use and the city's documented non-cooperation posture.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7dc7e4a1-9e52-4287-a100-6e1d715b5085', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7dc7e4a1-9e52-4287-a100-6e1d715b5085',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from council-wide votes; no Flaherty-specific quote on ICE detainers found. The full Bloomington City Council — including Flaherty — voted unanimously (9-0) in March 2026 for a resolution restricting city Flock license plate reader data from being used for immigration enforcement investigations. The council subsequently voted unanimously in April 2026 to allow the Flock contract to expire. Monroe County was listed by DHS as Indiana''s only "sanctuary jurisdiction" in mid-2025 (later removed). Bloomington''s documented city posture is one of limited cooperation with federal immigration enforcement within state law constraints. No Flaherty-specific statements on ICE detainers, undocumented victims, or a formal welcoming-city ordinance were found in available sources. Placed at value 2 (comply only with court-ordered detainers; protect undocumented crime victims) as the position most consistent with the unanimous votes he participated in limiting immigration data use, and the broader city posture he has not contradicted. Checked: B Square Bulletin, Indiana Daily Student, Indiana Public Media, Indiana Capital Chronicle, The Bloomingtonian.',
  ARRAY[
    'https://www.idsnews.com/article/2026/03/bloomington-city-council-flock-cameras-resolution-hopewell-affordable-housing',
    'https://www.idsnews.com/article/2026/04/city-of-bloomington-ends-flock-contract-data-sharing-with-indiana-law-enforcement',
    'https://bloomingtonian.com/2025/05/30/monroe-county-named-indianas-only-sanctuary-jurisdiction-on-homeland-security-watchlist/',
    'https://www.idsnews.com/article/2026/04/bloomington-police-department-bans-flock-data-immigration-reproductive-investigations'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 7. ECONOMIC DEVELOPMENT INCENTIVES (topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Value 2: Small business support and local entrepreneur programs only; avoid large corporate subsidies
-- Evidence: Flaherty cast the SOLE NO vote against the Catalent tax abatement in 2022, the only
-- council member to vote against it. He cited the statutory definition: the area had not been shown to
-- be "undesirable for, or impossible of, normal development." He also expressed discomfort with another
-- tax abatement: "My hope would be that Bloomington is attractive enough on its own that we wouldn't
-- have to abate taxes to attract growth." His BallotReady profile notes support for "green jobs" and
-- "vibrant local economy" not corporate tax breaks. This is consistent with value 2 (avoid large
-- corporate subsidies) rather than value 1 (no incentives at all — he did support some incentive
-- mechanisms for affordable housing) or value 3+ (active competition with tax abatements).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7dc7e4a1-9e52-4287-a100-6e1d715b5085', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7dc7e4a1-9e52-4287-a100-6e1d715b5085',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from voting record and direct quotes. In 2022 Flaherty cast the sole no vote (1 of 9) against the Catalent pharmaceutical company tax abatement, citing the letter of Indiana law: the area had not been shown to meet the statutory definition of "undesirable for, or impossible of, normal development." On a separate tax abatement he stated: "My hope would be that Bloomington… is attractive enough on its own that we wouldn''t have to abate taxes to attract growth." He noted Indiana''s already-low corporate income tax rate (5.5%) compared to other states, suggesting he did not view additional tax breaks as necessary. His platform emphasizes green jobs and a vibrant local economy rather than corporate tax incentives. He did support incentive mechanisms for affordable housing specifically (community land trusts, PILOT programs). This pattern — opposing corporate tax abatements while supporting community-benefit economic tools — is consistent with value 2 (small business support and local programs; avoid large corporate subsidies). No evidence of opposing all economic development tools (value 1) or supporting competitive large-employer incentives (values 4–5).',
  ARRAY[
    'https://bsquarebulletin.com/catalent-tax-break-gets-just-a-6-vote-majority-from-9-member-bloomington-city-council-but-its-enough/',
    'https://bsquarebulletin.com/2023/10/12/unchanged-2024-budget-okd-by-bloomington-council-after-debate-on-police-pay-econ-development-money/',
    'https://www.ballotready.org/people/matt-flaherty'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 8. TRANSPORTATION PRIORITIES (topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Value 1: Prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking requirements citywide
-- Evidence: Flaherty personally mostly walks for transportation. He sponsored the resolution to eliminate
-- parking minimums in ALL zones (part of the March 2025 UDO resolutions). He spearheaded the creation
-- of the new Transportation Commission in 2025, replacing three prior commissions, with a mandate
-- prioritizing "nonautomotive modes and sustainability." He was appointed to serve on that commission.
-- His campaign platform advocates Vision Zero (eliminate all traffic fatalities via safe walking routes,
-- public transit, and bicycle networks that "welcome all ages and abilities"). His climate-linked
-- transportation goals include "decarbonized transportation system by 2050." All of these positions
-- are consistent with value 1, the strongest multimodal/active transportation option.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7dc7e4a1-9e52-4287-a100-6e1d715b5085', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7dc7e4a1-9e52-4287-a100-6e1d715b5085',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from legislative record, personal statements, and platform. Flaherty currently gets around primarily by walking. He sponsored the March 2025 UDO resolution directing the plan commission to eliminate minimum parking requirements in ALL zoning districts citywide — the broadest possible parking reform. He spearheaded the creation of Bloomington''s new Transportation Commission (approved February 2025), which replaced three prior commissions and was explicitly chartered to prioritize "nonautomotive modes and sustainability." He was subsequently appointed to serve on that commission (March 2025, 5-4 council vote). His published platform advocates Vision Zero — eliminating all traffic fatalities through safe walking routes to school, convenient public transit, and bicycle networks that welcome all ages and abilities — and calls for "a decarbonized transportation system by 2050." This consistent legislative and personal record aligns with value 1 (prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking requirements citywide).',
  ARRAY[
    'https://bsquarebulletin.com/amid-shift-in-bloomington-street-oversight-flaherty-gets-city-council-nod-for-new-transportation-group-2/',
    'https://bsquarebulletin.com/start-of-process-for-possible-zoning-changes-halted-with-4-4-votes-by-bloomington-city-council/',
    'https://www.ballotready.org/people/matt-flaherty',
    'https://www.idsnews.com/article/2025/04/city-council-mayor-upzoning-disagreement-udo-housing-density'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
