-- Migration 129: Local Lens compass stances for David R Rollo
-- Bloomington City Common Council, District 4
-- politician_id: 85741f19-1c12-43ad-8504-d615522725d7
-- Researched: 2026-05-11

BEGIN;

-- 1. Affordable Housing (topic_id: 669cac97-66a6-4087-b036-936fbe62efb3)
-- Value 3: Targeted subsidies, first-time buyer assistance, easier permits
-- Rollo championed affordable housing incentives in the UDO, supported Habitat for Humanity projects,
-- and backed cohousing initiatives. He proposed incremental lot-coverage incentives for affordable
-- housing in Feb 2026. His record shows targeted/incentive-based support, not rent control or public housing.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85741f19-1c12-43ad-8504-d615522725d7', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '85741f19-1c12-43ad-8504-d615522725d7',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign platform and council votes. Rollo developed affordable housing incentives in the UDO, voted to approve a 70-unit Habitat for Humanity PUD (2020), championed cohousing projects that reduce costs through shared living, and consistently supported increases in social service funding. In February 2026 he introduced an amendment to affordable housing incentive ordinance (Ordinance 2026-01) with incrementally increasing lot coverage percentages by zone district to balance housing incentives with environmental protection. His approach is squarely targeted assistance and incentive-based — no record of supporting rent caps or direct public housing construction.',
  ARRAY[
    'https://daverollo.com/platform/',
    'https://daverollo.com/issues/',
    'https://bsquarebulletin.com/2020/08/13/bloomington-city-council-oks-habitat-for-humanity-project-to-build-70-houses-in-southwest-part-of-town/',
    'https://www.ipm.org/news/2026-02-11/council-passes-affordable-housing-incentives-asks-for-more'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 2. Criminalization of Homelessness (topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a)
-- Value 2: Decriminalize public sleeping while investing in shelter/outreach
-- Rollo abstained on the September 2023 anti-camping ordinance (5 NO, 2 YES, 1 abstain).
-- He said he was inclined to table it — meaning he did not support criminalization.
-- His abstention on criminalization aligns with decriminalization coupled with services investment.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85741f19-1c12-43ad-8504-d615522725d7', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '85741f19-1c12-43ad-8504-d615522725d7',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Inferred from council vote record. In September 2023, Rollo abstained on an ordinance that would have banned camping and storing property in the public right-of-way. The vote was 5 NO / 2 YES / 1 abstain (Rollo), with the ordinance failing. Rollo stated he was inclined to table the ordinance but did not make that motion when it was clear there was no majority support for tabling. His abstention — rather than a YES vote — indicates he does not support criminalization of homelessness. His consistent support for social service funding and the decriminalization-leaning outcome of his abstention most closely matches a position of decriminalizing public sleeping while investing in shelter capacity and outreach.',
  ARRAY[
    'https://www.ipm.org/2023-09-14/city-council-rejects-effort-to-prevent-camping-on-sidewalks-streets',
    'https://bsquarebulletin.com/bloomington-council-votes-down-proposed-law-against-camping-storing-property-in-public-right-of-way/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 3. Residential Zoning (topic_id: d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Value 1: Protect existing neighborhood character; require community process before rezoning
-- Rollo voted NO on March 2025 UDO resolutions (duplexes/triplexes by right, parking minimum elimination).
-- He authored anti-upzoning amendments in 2019 and 2025. He was endorsed by Stop Btown Upzoning.
-- He dissented on 140-acre rezone in 2024. He advocates "bottom up" deliberation before zoning changes.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85741f19-1c12-43ad-8504-d615522725d7', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '85741f19-1c12-43ad-8504-d615522725d7',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Direct vote record. In March 2025, Rollo voted NO (with Ruff, Daily, Asare) on two resolutions that would have directed the plan commission to draft UDO amendments allowing duplexes, triplexes, and fourplexes by right in single-family zones, and eliminating parking minimums — the votes failed 4-4. Rollo said the approach "landed like a grenade" and opposed increasing density in older neighborhoods without building "from the bottom up" through deliberation. He co-sponsored a 2019 amendment prohibiting duplexes/triplexes in central city neighborhoods, authored amendments to put "guardrails on dense housing proliferation in formerly single-family-zoned neighborhoods," and was one of two dissenters on a 7-2 vote approving a 140-acre rezone in southwest Bloomington (May 2024). Endorsed by Stop Btown Upzoning in 2023 as their "most eloquent, fervent and consistent ally in the opposition to Bloomington''s upzoning." His record is consistently and strongly in favor of protecting existing neighborhood character and requiring extensive community process before any rezoning.',
  ARRAY[
    'https://bsquarebulletin.com/start-of-process-for-possible-zoning-changes-halted-with-4-4-votes-by-bloomington-city-council/',
    'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning',
    'https://bsquarebulletin.com/140-acre-rezone-in-southwest-part-of-town-okd-by-bloomington-city-council-on-7-2-vote/',
    'https://stopbtownupzoning.org/2023/03/06/we-endorse-dave-rollo-city-council-district-4/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 4. Civil Rights and Social Justice (topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Value 2: Strengthen civil rights enforcement and address systemic discrimination
-- Rollo supported trans protections in city code, co-sponsored RFRA repeal resolution, signed hate crimes
-- letter. His platform explicitly states he "support[s] and promote[s] race, gender and LGBT equality."
-- He abstained on the BLM mural vote (government funds / political org concern), not opposition to BLM sentiment.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85741f19-1c12-43ad-8504-d615522725d7', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '85741f19-1c12-43ad-8504-d615522725d7',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from platform and council votes. Rollo explicitly states he "support[s] and promote[s] race, gender and LGBT equality." He supported a 2006 ordinance adding gender identity as a protected class, co-sponsored a resolution demanding repeal of Indiana''s Religious Freedom Restoration Act, and as Council President signed a letter urging strong hate crimes legislation. He abstained on the September 2020 Black Lives Matter street mural vote, not out of opposition to civil rights but because he said he was "not in favor of using government funds to promote a political organization" — he stated he "overwhelmingly supports the Black Lives Matter sentiment." His record aligns with strengthening civil rights enforcement and addressing systemic discrimination.',
  ARRAY[
    'https://daverollo.com/platform/',
    'https://bsquarebulletin.com/2020/09/24/split-votes-on-race-related-topics-by-city-county-electeds/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 5. Public Safety Approach (topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Value 3: Keep current public safety funding while adding crisis response teams
-- Rollo explicitly supported adequate police staffing and higher compensation, wanted retention fund
-- increased beyond $250K, floated reopening CBA for higher police pay. NOT in defund camp.
-- Also supported adding civilian social workers and non-sworn positions to public safety.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85741f19-1c12-43ad-8504-d615522725d7', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '85741f19-1c12-43ad-8504-d615522725d7',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from budget hearing record. During 2022 budget hearings, Rollo expressed concern that the $250,000 retention and recruitment fund for police was insufficient and floated reopening the collective bargaining agreement to provide higher officer compensation. He supported police take-home vehicles and adequate sworn officer counts. His platform includes funding "fire and police protection" as a core city responsibility and promises "more hires in public safety." He did not support defunding or significant reallocation away from police. At the same time, the 2022 budget included non-sworn social worker positions in the police department, which Rollo did not oppose. His position — maintain or modestly grow police capacity while supporting civilian/social service additions — aligns most closely with keeping current funding while adding crisis response capability.',
  ARRAY[
    'https://bsquarebulletin.com/2021/08/24/bloomington-city-council-critical-on-first-night-of-2022-budget-hearings-police-parking-sidewalks/',
    'https://daverollo.com/issues/',
    'https://bsquarebulletin.com/2022/05/19/police-contract-with-13-initial-raise-okd-by-bloomington-city-council-but-its-enough/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 6. Local Immigration Enforcement (topic_id: b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Value 1: Refuse ICE cooperation; prohibit sharing immigration status information
-- Rollo said of Flock cameras: "I think that the case has been made tonight that we don't need this.
-- We don't need Flock cameras, and we should think of defunding it." — explicitly citing ICE data-sharing
-- as part of resident concerns about the program. He voted 9-0 for the resolution to pause/investigate.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85741f19-1c12-43ad-8504-d615522725d7', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '85741f19-1c12-43ad-8504-d615522725d7',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from Flock camera debate, March 2026. Rollo voted unanimously (9-0) on March 4, 2026 for a resolution pausing Flock license-plate reader expansion and requiring a briefing on data-sharing, access controls, and costs. During the meeting, Rollo stated: "I think that the case has been made tonight that we don''t need this. We don''t need Flock cameras, and we should think of defunding it." Resident concerns driving the debate explicitly included ICE data-sharing via Flock systems (residents protested on January 30 connecting Flock to immigration enforcement). The city subsequently ended its Flock contract (April 2026). While Indiana passed Senate Bill 76 (signed March 5, 2026) requiring local governments to cooperate with federal immigration enforcement, Rollo''s demonstrated position is to refuse surveillance tools that could enable ICE and to oppose city resources being directed toward immigration enforcement.',
  ARRAY[
    'https://bsquarebulletin.com/bloomington-city-council-adopts-resolution-on-flock-license-plate-reader-cameras-as-first-step/',
    'https://www.ipm.org/news/2026-03-05/with-residents-opposing-surveillance-tools-bloomington-city-council-seeks-details-from-mayor-police',
    'https://www.idsnews.com/article/2026/04/city-of-bloomington-ends-flock-contract-data-sharing-with-indiana-law-enforcement',
    'https://www.idsnews.com/article/2026/01/bloomington-protest-ice-immigration-flock-cameras'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 7. Economic Development Incentives (topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Value 3: Targeted incentives for specific industries with community benefit/job quality requirements
-- Voted YES on Catalent tax abatement (2022) despite stated reservations about corporate tax breaks,
-- citing wage-growth needs ("we're job rich, but wage poor"). Co-sponsored 2003 Living Wage Ordinance.
-- Supports life sciences, IT, biotech, arts. Questions corporate subsidies without wage standards.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85741f19-1c12-43ad-8504-d615522725d7', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '85741f19-1c12-43ad-8504-d615522725d7',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from voting record and platform. Rollo co-sponsored Bloomington''s 2003 Living Wage Ordinance and consistently links economic development to fair wages and worker benefit, stating the city is "job rich, but wage poor." He voted YES on the Catalent pharmaceutical tax abatement in 2022 (which passed 6-3) despite calling critical comments about corporate tax breaks "very appropriate," concluding the abatement was justified by wage-growth benefit. His platform supports targeted economic sectors (life sciences, IT, pharmaceutical, biotech, health services, green technology, arts/cultural development) that "added hundreds of living wage jobs." He questioned whether Bloomington should pursue a municipally-owned fiber utility rather than a private-ownership model for the 2022 Meridiam internet deal. The overall pattern is targeted incentives for specific industries with wage/community benefit emphasis — not blanket opposition to incentives nor aggressive competition for any large employer.',
  ARRAY[
    'https://bsquarebulletin.com/2022/03/03/catalent-tax-break-gets-just-a-6-vote-majority-from-9-member-bloomington-city-council-but-its-enough/',
    'https://bsquarebulletin.com/2022/06/16/3-oks-in-3-days-bloomington-gets-needed-nods-for-high-speed-internet-fiber-deal-with-meridiam/',
    'https://daverollo.com/platform/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 8. Transportation Priorities (topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Value 2: Invest equally in roads and multimodal; require bike lanes and sidewalks on all new projects
-- Rollo chaired Bloomington Platinum Biking Task Force; implemented sidewalks, trails, traffic calming;
-- secured $2.1M for Sare Road side path. He also pushed stop signs on bike path for pedestrian safety
-- and sought council oversight of greenway projects — reflecting balanced/multimodal rather than
-- aggressive de-prioritization of cars, but also not a pure car-first position.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('85741f19-1c12-43ad-8504-d615522725d7', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '85741f19-1c12-43ad-8504-d615522725d7',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from platform and council actions. Rollo served as chair of the Bloomington Platinum Biking Task Force and worked toward achieving platinum bike-city status. His platform records implementing "sidewalks, trails, traffic calming, and pedestrian crossings" and securing $2.1 million for a side path on Sare Road. He states that "good plan should be beneficial to everyone, whether it be pedestrians or users of public transportation, automobiles or bikes." His multimodal advocacy is substantive — but not at the extreme end of reducing parking or deprioritizing roads. He proposed reinstalling stop signs at 7-Line bike path intersections for safety, and introduced an ordinance (which failed 4-5) for council oversight of traffic calming and greenway projects — showing a cautious, community-input-oriented approach to infrastructure changes. The overall record aligns with equal investment in roads and multimodal options, requiring bike and pedestrian infrastructure on new projects.',
  ARRAY[
    'https://daverollo.com/issues/',
    'https://daverollo.com/platform/',
    'https://news.yahoo.com/bitterly-split-bloomington-council-votes-091114969.html',
    'https://bsquarebulletin.com/2023/05/11/on-4-5-vote-city-council-rejects-direct-oversight-of-bloomington-traffic-calming-greenways-program/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
