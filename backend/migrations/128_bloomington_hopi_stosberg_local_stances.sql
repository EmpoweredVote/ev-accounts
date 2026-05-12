BEGIN;

-- ============================================================
-- Migration 128: Local Lens compass stances for Hopi H Stosberg
-- Bloomington City Common Council, District 3
-- politician_id: 73457c02-d058-44cb-ac56-c5120284553b
-- Researched: 2026-05-11
-- ============================================================


-- 1. AFFORDABLE HOUSING (topic_id: 669cac97-66a6-4087-b036-936fbe62efb3)
-- Value 2: Use rent caps, require new developments to include affordable units, and publicly fund new housing
-- Evidence: Stosberg's campaign platform lists "affordable family housing" as a priority. She co-sponsored
-- the March 2025 UDO amendment resolutions adding inclusionary requirements for new developments. She
-- sponsored Resolution 2024-23 initiating stronger affordable housing incentive changes. On the Hopewell
-- South PUD she advocated that at least half the units be permanently affordable (not temporary). She
-- ultimately voted against the final Hopewell affordability condition because the 35% floor / 50% goal
-- compromise fell short of her "permanently affordable" standard, showing a more demanding stance than
-- mere subsidy or permit streamlining. No evidence of advocating directly government-built public
-- housing (value 1) or market deregulation (values 4-5). Value 2 is the closest match.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73457c02-d058-44cb-ac56-c5120284553b', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '73457c02-d058-44cb-ac56-c5120284553b',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign platform, council sponsorships, and voting record. Stosberg listed "affordable family housing" as a campaign priority and has been consistent in demanding strong affordability requirements. She co-sponsored the March 2025 UDO amendment resolutions that would have directed the plan commission to add inclusionary housing requirements for new developments. She sponsored Resolution 2024-23 (November 2024) to initiate strengthened affordable housing incentive changes to the UDO. On the Hopewell South PUD, she and Rosenbarger advocated that at least 50% of units be permanently affordable; when council adopted a 35% floor / 50% goal compromise instead, Stosberg voted against the final affordability condition on grounds that the complex affordability instruments needed more clearly mapped staff capacity and long-term subsidy commitments — a higher standard than the compromise offered. Her volunteer co-chairing of a group assisting refugee families with housing illustrates her direct engagement with the difficulty of finding affordable housing in Bloomington. No evidence of advocating for directly government-operated public housing (value 1), nor for a deregulatory market approach (values 4-5). Value 2 (require new developments to include affordable units and publicly fund housing) best matches her record.',
  ARRAY[
    'https://www.ipm.org/2023-02-06/hopi-stosberg-joins-race-for-third-district-bloomington-city-council-seat',
    'https://bsquarebulletin.com/start-of-process-for-possible-zoning-changes-halted-with-4-4-votes-by-bloomington-city-council/',
    'https://bsquarebulletin.com/hopewell-south-pud-wins-unanimous-ok-from-bloomington-city-council/',
    'https://www.idsnews.com/article/2026/04/bloomington-city-council-delays-vote-hopewell-pud-for-third-meeting',
    'https://bloomdocs.org/wp-content/uploads/simple-file-list/2025-09-30-city-council-initiated-Res_2025-17.pdf'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 2. CRIMINALIZATION OF HOMELESSNESS (topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a)
-- Value 2: Decriminalizing public sleeping while investing in shelter capacity, outreach workers,
--          and voluntary service connections
-- Evidence: Stosberg took office in January 2024 (elected November 2023), so was not present for the
-- September 2023 camping-on-sidewalks ordinance vote. No specific encampment vote by Stosberg was
-- found. She has consistently framed public safety as broader than policing: "lots of pieces of
-- public safety, lots of pieces that keep our community safe because it's not just about police and
-- crime." She advocated that the city spent $20 million of ARPA funds on homelessness and workforce
-- housing, consistent with housing-first service investment. The city opened the Beacon Center
-- (funded in part during her tenure) to provide emergency shelter and permanent housing services.
-- Evidence supports investing in services over enforcement, but no direct statement on encampment
-- criminalization found. Value 2 is the closest match based on her housing-first investment advocacy.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73457c02-d058-44cb-ac56-c5120284553b', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '73457c02-d058-44cb-ac56-c5120284553b',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Inferred from public safety framing and housing investment advocacy; no direct encampment vote found. Stosberg took office in January 2024, so she was not present for the September 2023 vote that rejected a camping-on-sidewalks prohibition ordinance. No council vote on encampment policy has arisen during her term. She has consistently framed public safety broadly: "lots of pieces of public safety, lots of pieces that keep our community safe because it''s not just about police and crime." She advocated that the city directed approximately $20 million of ARPA funds toward homelessness and workforce housing needs, consistent with a housing-first and services-investment approach rather than enforcement. The city funded the Beacon Center (opening 2027) to provide emergency shelter, permanent housing, and rehousing services, which Stosberg supported as part of the city''s homelessness response. No statement from Stosberg affirmatively protecting the right to camp in public spaces was found (value 1). No statement supporting criminal penalties for public sleeping was found (values 4-5). Her emphasis on services and housing investment over enforcement is most consistent with value 2 (decriminalize public sleeping while investing in shelter and voluntary service connections). Checked: B Square Bulletin, Indiana Daily Student, Indiana Public Media, Bloomingtonian, WFHB, bloomington.in.gov.',
  ARRAY[
    'https://www.idsnews.com/article/2025/11/bloomington-housing-homelessness-report-affordability-development',
    'https://bsquarebulletin.com/2024/01/11/bloomington-city-councils-first-meeting-puts-familiar-faces-in-leadership-gives-public-safety-some-airtime/',
    'https://bloomington.in.gov/council/district-3'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 3. RESIDENTIAL ZONING (topic_id: d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Value 4: Upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements
-- Evidence: Stosberg co-sponsored (with Rosenbarger) the March 2025 UDO amendment resolutions directing
-- the plan commission to allow duplexes, triplexes, and fourplexes by right in single-family zones,
-- remove owner-occupancy requirements for ADUs, allow two ADUs per lot, eliminate ADU square footage
-- caps, and redefine single-family attached dwellings. A companion resolution she supported eliminated
-- minimum parking requirements citywide. Both resolutions failed 4-4. She voted YES on their introduction.
-- She has continued pursuing UDO housing density changes since, framing this as essential to address
-- Bloomington's housing shortage. She also voted YES on the 140-acre southwest Bloomington rezone (7-2).
-- NOTE: The task brief stated she voted NO on the March 2025 upzoning resolutions — this is incorrect
-- per B Square Bulletin coverage; she voted YES (for introduction) along with Flaherty, Piedmont-Smith,
-- and Rosenbarger. Value 4 is a direct match.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73457c02-d058-44cb-ac56-c5120284553b', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '73457c02-d058-44cb-ac56-c5120284553b',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from co-sponsorship, voting record, and public statements. In March 2025, Stosberg co-sponsored (with Rosenbarger) UDO amendment resolutions that would direct the Bloomington Plan Commission to prepare ordinances allowing duplexes, triplexes, and fourplexes as permitted uses in single-family residential zones; removing owner-occupancy requirements for ADUs; allowing two ADUs per lot; eliminating ADU square footage caps in favor of footprint-based standards; and redefining single-family attached dwellings to include townhouses and rowhouses. A companion resolution she supported would have eliminated minimum parking requirements citywide. Both resolutions failed on 4-4 tie votes that blocked even introduction. Stosberg voted YES (in favor of introduction) along with Flaherty, Piedmont-Smith, and Rosenbarger; the four NO votes were Rollo, Ruff, Daily, and Asare. As council president, Stosberg stated the next step is continued UDO policy changes to address the housing situation, with official proposals expected in early 2026. She also sponsored Resolution 2025-17 (passed 7-0, September 2025) initiating further UDO amendments to the PUD affordability incentive structure. She voted with the majority on the 7-2 vote approving a 140-acre rezone in southwest Bloomington. Her stated and voted position is for broad density increases and reduced parking requirements — directly matching value 4 (upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements).',
  ARRAY[
    'https://bsquarebulletin.com/start-of-process-for-possible-zoning-changes-halted-with-4-4-votes-by-bloomington-city-council/',
    'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning',
    'https://www.idsnews.com/article/2025/04/city-council-mayor-upzoning-disagreement-udo-housing-density',
    'https://bloomdocs.org/wp-content/uploads/simple-file-list/2025-09-30-city-council-initiated-Res_2025-17.pdf',
    'https://bsquarebulletin.com/140-acre-rezone-in-southwest-part-of-town-okd-by-bloomington-city-council-on-7-2-vote/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 4. CIVIL RIGHTS AND SOCIAL JUSTICE (topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Value 2: Strengthen civil rights enforcement and address systemic discrimination
-- Evidence: Stosberg's campaign platform explicitly lists "improving systems to reflect values of
-- justice, equity, and inclusion" as a priority. In 2025 she chose to open council meetings with
-- historical facts about cultural diversity, equity, and shared progress toward a more just and
-- equitable future. She has volunteered co-chairing a group assisting refugee families. She
-- attended Earlham College (known for its Quaker equity focus). No evidence of reparations advocacy
-- (value 1) or of limiting civil rights enforcement (values 3-5). Value 2 is the best match.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73457c02-d058-44cb-ac56-c5120284553b', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '73457c02-d058-44cb-ac56-c5120284553b',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from campaign platform and public council conduct. Stosberg lists "improving systems to reflect values of justice, equity, and inclusion" as a core campaign priority, alongside "supporting youth and educational systems" and "mindfulness of climate change." In 2025, as council president, she instituted a practice of opening council meetings with historical facts and information related to cultural diversity, equity, and related concepts — explicitly to ground residents in shared histories and progress toward a more just and equitable future. Her volunteer work co-chairing a group assisting refugee families with housing, employment, and education reflects a direct commitment to equity for marginalized communities. Her background includes a master''s degree in teaching from Earlham College, an institution with a strong tradition of social justice education. No evidence of advocating for reparations or mandated racial equity requirements across all institutions (value 1). No evidence of limiting civil rights enforcement (values 3-5). Value 2 (strengthen civil rights enforcement and address systemic discrimination) matches her stated platform and council conduct.',
  ARRAY[
    'https://www.ipm.org/2023-02-06/hopi-stosberg-joins-race-for-third-district-bloomington-city-council-seat',
    'https://bloomington.in.gov/council/district-3',
    'https://www.chamberbloomington.org/2023-city-council-candidates.html'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 5. PUBLIC SAFETY APPROACH (topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Value 2: Maintain current police staffing but shift non-violent calls to unarmed mental health co-responders
-- Evidence: At 2024 budget hearings Stosberg questioned whether salary increases alone would solve
-- staffing issues, asking to reassess "our culture of policing" and noting "it's not just about
-- police and crime." She said public safety has "lots of pieces." She established the Community
-- Advisory on Public Safety (CAPS) Commission as a council body, which researches evidence-based
-- alternatives to traditional policing. No evidence of advocating police defunding (value 1) or
-- significantly expanding police budget as top priority (values 4-5). Value 2 matches.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73457c02-d058-44cb-ac56-c5120284553b', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '73457c02-d058-44cb-ac56-c5120284553b',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from budget hearing statements and council institutional support for public safety alternatives. At 2024 Bloomington city budget hearings, Stosberg questioned whether a $2 million increase to the police budget focused on salary would solve staffing issues, noting that "our culture of policing, in terms of our culture of Bloomington, and how Bloomington responds to police and considers public safety as a whole" needs reassessment. She stated: "There''s lots of pieces of public safety, lots of pieces that keep our community safe because it''s not just about police and crime." The Bloomington City Council established the Community Advisory on Public Safety (CAPS) Commission, which is a council-created body charged with researching evidence-based alternatives to traditional policing and making policy recommendations — Stosberg as council president supports this body''s mandate. No evidence of advocating for significantly redirecting police budgets to social services (value 1) or for making police budget expansion the top city spending priority (values 4-5). Her framing — neither defund nor expand, but broaden the definition of public safety to include non-police services — is most consistent with value 2 (maintain current police staffing but shift non-violent calls to unarmed mental health co-responders). Note: no specific Stosberg vote on a formal co-responder program was found; assessment is based on budget statements and institutional support.',
  ARRAY[
    'https://bsquarebulletin.com/2024/01/11/bloomington-city-councils-first-meeting-puts-familiar-faces-in-leadership-gives-public-safety-some-airtime/',
    'https://www.ipm.org/2024-09-10/city-fire-and-police-hiring-struggles-go-deeper-than-just-money',
    'https://bloomington.in.gov/council/public-safety-advisory'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 6. LOCAL IMMIGRATION ENFORCEMENT (topic_id: b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Value 2: Comply only with court-ordered detainers; protect undocumented crime victims and witnesses
-- Evidence: Stosberg voted unanimously with the council on the March 5, 2026 Flock camera oversight
-- resolution, stating her stance shifted from seeing the benefits of surveillance to seeing the
-- consequences — specifically citing SB 76 requiring law enforcement to cooperate with federal
-- immigration officers as a concern. Bloomington is designated as Indiana's only DHS-listed sanctuary
-- jurisdiction. BPD policy: no communication with ICE except for criminal arrest warrants. City
-- statement: residents of any status should feel safe calling 911. The council ended the Flock contract
-- rather than risk immigration data sharing. Value 2 is the best match for Stosberg and Bloomington's posture.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73457c02-d058-44cb-ac56-c5120284553b', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '73457c02-d058-44cb-ac56-c5120284553b',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from council vote, public statement, and city policy context. On March 5, 2026, Stosberg voted unanimously with the Bloomington City Council to pass a resolution imposing an immediate pause on ALPR (Flock camera) program expansion and requiring the mayor to brief the council on data-sharing practices. In explaining her position, Stosberg stated her stance had "shifted from seeing the benefits to now seeing the consequences" of the Flock program, specifically citing Indiana SB 76 requiring law enforcement to cooperate with federal immigration officers as a concern. The city ultimately ended its Flock contract in April 2026 and BPD banned use of Flock data for immigration enforcement. Bloomington is the only municipality in Indiana designated as a sanctuary jurisdiction on the DHS watchlist. The city''s standing policy is: "we do not inquire about anyone''s immigration status and any person regardless of status should feel safe in calling 911." BPD has stated it has "no communication with ICE unless they''re assisting with an arrest warrant related to a criminal matter." No council resolution explicitly refusing all ICE detainers was passed (value 1 would require affirmatively refusing all detainers and prohibiting all information sharing). The city''s posture — limit contact with ICE to criminal arrest warrants, protect undocumented persons from status inquiries, stop data-sharing that could be used for immigration enforcement — maps directly to value 2.',
  ARRAY[
    'https://www.idsnews.com/article/2026/02/bloomington-flock-contract-what-to-know',
    'https://www.idsnews.com/article/2026/03/bloomington-city-council-flock-cameras-resolution-hopewell-affordable-housing',
    'https://www.idsnews.com/article/2026/04/bloomington-police-department-bans-flock-data-immigration-reproductive-investigations',
    'https://www.idsnews.com/article/2026/04/city-of-bloomington-ends-flock-contract-data-sharing-with-indiana-law-enforcement',
    'https://www.ipm.org/news/2026-03-05/with-residents-opposing-surveillance-tools-bloomington-city-council-seeks-details-from-mayor-police'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 7. ECONOMIC DEVELOPMENT INCENTIVES (topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Not found — no specific Stosberg statements on corporate tax incentives or economic development
-- strategy found. She acknowledged the Monroe Convention Center project was "too far along to change
-- direction" but expressed concerns about its focus — this is not a clear statement on incentive policy.
-- No vote on a tax abatement or corporate subsidy by Stosberg was found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '73457c02-d058-44cb-ac56-c5120284553b',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record of Stosberg''s stance on economic development incentives found. On the Monroe Convention Center interlocal agreement (approved February 2024), Stosberg was noted as agreeing the project was too far along to change direction despite concerns — this is not a meaningful statement on tax incentive philosophy. No vote on corporate tax abatements or subsidy packages by Stosberg was found during her term. Checked: B Square Bulletin, Indiana Daily Student, Indiana Public Media, Bloomingtonian, WFHB, chamberbloomington.org, bloomingtonedc.com, bloomington.in.gov.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 8. TRANSPORTATION PRIORITIES (topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Value 2: Invest equally in roads and multimodal options; require bike lanes and sidewalks on all
--          new road projects
-- Evidence: Before taking office, Stosberg spoke from the public mic against reinstalling stop signs
-- on the 7-Line separated bike path (pro-cycling). She raised pedestrian safety concerns about INDOT's
-- SR 45/10th Street road design. She voted for the Flaherty transportation commission appointment whose
-- mandate explicitly "prioritizes nonautomotive modes and sustainability." She supported the March 2025
-- UDO resolution eliminating minimum parking requirements. Her campaign priority includes "expansion
-- of public transportation." The pattern supports multimodal investment. However, her documented
-- positions are less aggressive than full citywide deprioritization of cars (value 1). Value 2 is
-- the best supported match.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73457c02-d058-44cb-ac56-c5120284553b', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '73457c02-d058-44cb-ac56-c5120284553b',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from public comments, council votes, and campaign platform. Before taking office, Stosberg spoke at a public meeting against reinstalling stop signs at Lincoln and Washington on the 7-Line separated bike path, arguing stop signs on a hill make the route "less bike friendly" by forcing cyclists to lose momentum. She raised pedestrian safety concerns about INDOT''s planned SR 45/10th Street curb designs, noting the curve facilitates fast driving and endangers crossing pedestrians. After taking office, she voted in March 2025 to support Flaherty''s appointment to a new transportation commission whose mandate is to guide "the city''s transportation endeavors through a comprehensive framework which seeks to provide adequate and safe access to all right-of-way users while prioritizing nonautomotive modes and sustainability." She supported the March 2025 UDO amendment resolution that included eliminating minimum parking requirements citywide. Her campaign platform explicitly lists "expansion of public transportation" as a priority. No evidence she advocated for road capacity expansion or car-centric transportation spending as a city priority (values 4-5). No evidence she called for eliminating parking requirements across all city transportation investment (which would be closer to value 1). Value 2 (invest equally in roads and multimodal options; require bike lanes and sidewalks on all new road projects) is the best supported match given the evidence available.',
  ARRAY[
    'https://www.ipm.org/2023-10-20/bloomington-residents-share-mixed-opinions-on-s-r-45-project',
    'https://bsquarebulletin.com/amid-shift-in-bloomington-street-oversight-flaherty-gets-city-council-nod-for-new-transportation-group-2/',
    'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning',
    'https://www.ipm.org/2023-02-06/hopi-stosberg-joins-race-for-third-district-bloomington-city-council-seat'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
