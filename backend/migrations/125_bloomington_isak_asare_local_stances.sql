BEGIN;

-- ============================================================
-- Migration 125: Local Lens compass stances for Isak Nti Asare
-- Bloomington City Common Council, At Large
-- politician_id: 2b280bdf-bf17-48ad-853d-a4f0a854c548
-- Researched: 2026-05-11
-- ============================================================

-- 1. AFFORDABLE HOUSING (topic_id: 669cac97-66a6-4087-b036-936fbe62efb3)
-- Value 3: Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits
-- Evidence: As Jack Hopkins Fund Committee Chair, Asare advocated for increasing the $350K fund (which
-- distributes grants to affordable housing and social service nonprofits). He voted unanimously with the
-- full council for Resolution 2025-13, creating the city's Affordable Housing PILOT Fund — a targeted
-- tax-incentive subsidy tool for affordable housing developers, not direct government construction.
-- On the Relato workforce housing dispute, he said the $1M payment "provides some immediate benefits,
-- but the ordinance is also a call to action for the council to make changes to the UDO relating to
-- workforce housing going forward" — signaling support for incentive-based UDO affordability requirements
-- rather than public housing (value 1) or rent caps (value 2). His 2023 campaign cited affordable housing
-- as a priority with an approach through public subsidy and incentive tools. No evidence of supporting
-- rent caps, government-built housing, or market-only solutions.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b280bdf-bf17-48ad-853d-a4f0a854c548', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2b280bdf-bf17-48ad-853d-a4f0a854c548',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from council votes, committee role, and public statements. As Jack Hopkins Social Services Fund Committee Chair, Asare advocated for increasing the fund (which grants money to affordable housing and social service nonprofits), and noted the committee expanded funding by nearly $150,000. He voted with the full council (7-0 quorum) for Resolution 2025-13 establishing the Affordable Housing PILOT Fund — a targeted tax-incentive tool that gives developers a property tax exemption on low-income housing tax credit properties in exchange for PILOT payments. On the Relato workforce housing dispute, Asare said the $1 million payment "provides some immediate benefits, but the ordinance is also a call to action for the council to make changes to the UDO relating to workforce housing going forward," signaling support for incentive-based affordability requirements rather than direct government construction (value 1) or rent caps (value 2). His 2023 campaign cited affordable housing as a key priority with an approach centered on subsidies and regulatory incentives. No evidence of supporting rent caps, mandatory affordable unit requirements on all new developments, or a market-only deregulatory approach. Value 3 (targeted subsidies, first-time buyer assistance, easier permits) best matches his documented record.',
  ARRAY[
    'https://www.idsnews.com/article/2024/06/city-council-meeting-work-session-may',
    'https://www.idsnews.com/article/2025/09/cacitycouncil090325',
    'https://www.ipm.org/news/2025-09-04/city-develops-affordable-housing-fund-to-comply-with-state-code',
    'https://www.idsnews.com/article/2025/02/relato-says-it-can-t-fill-workforce-housing-will-pay-over-1-million-to-city',
    'https://bloomington.in.gov/council/jack-hopkins'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 2. CRIMINALIZATION OF HOMELESSNESS (topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a)
-- Not found: No direct statements or votes from Asare specifically on homelessness enforcement policy.
-- The city uses a 30-day notice encampment clearing process under Mayor Thomson; Asare as Council President
-- described the council-mayor relationship as "collaborative" but made no specific statement on the
-- criminalization vs. services debate. The 2026 Indiana camping ban (SB 285) drew criticism from city
-- officials but no recorded Asare comment was found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2b280bdf-bf17-48ad-853d-a4f0a854c548',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. No direct statements or votes from Asare specifically on homelessness enforcement, public camping, or shelter policy were found. The city operates a 30-day notice encampment clearing process under Mayor Thomson; Asare as Council President described the council-mayor relationship as "collaborative" without elaborating on encampment policy specifically. Indiana''s 2026 camping ban (SB 285) drew criticism from Bloomington city officials but no recorded Asare comment on the legislation was found. Checked: B Square Bulletin, Indiana Daily Student, Indiana Public Media, WTHR, Fox 59, WFHB, Herald-Times references, Bloomington.in.gov council pages.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 3. RESIDENTIAL ZONING (topic_id: d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Value 2: Allow modest density increases (duplexes, accessory units) with strong design review and neighborhood input
-- Evidence: In 2023 the anti-upzoning group "Stop Bloomington Upzoning" (The Dissident Democrat)
-- endorsed Asare, quoting him: "no neighborhood should undergo rapid, drastic, or sudden changes…
-- people who live in neighborhoods should be able to co-create their spaces and have significant input
-- on changes that take place." He specifically said he did not support "the way the UDO was changed to
-- allow duplexes" as inconsistent with "bottom up governance and decision making." In March 2025 he
-- voted against introducing resolutions (4-4 tie) that would have directed the plan commission to allow
-- duplexes, triplexes, and fourplexes by right in single-family zones and eliminate parking minimums.
-- He has signaled openness to some incremental density changes but insists on a community-led,
-- bottom-up process with strong input. This closely matches value 2 (allow modest density with strong
-- design review and neighborhood input), not values 4-5 (broad upzoning) or value 1 (strict protection).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b280bdf-bf17-48ad-853d-a4f0a854c548', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2b280bdf-bf17-48ad-853d-a4f0a854c548',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from endorsement record, direct quotes, and voting record. In 2023, the anti-upzoning group "Stop Bloomington Upzoning" (The Dissident Democrat) endorsed Asare over pro-density candidates, quoting him: "no neighborhood should undergo rapid, drastic, or sudden changes… people who live in neighborhoods should be able to co-create their spaces and have significant input on changes that take place." He explicitly stated he did not support "the way the UDO was changed to allow duplexes," saying it was inconsistent with his "political approach of bottom up governance and decision making." In March 2025 he voted against introducing UDO amendment resolutions (resulting in a 4-4 tie that killed introduction) that would have allowed duplexes, triplexes, and fourplexes by right in single-family zones and eliminated parking minimums citywide. His stated reasoning at the time centered on procedural concerns (inadequate public notice), but he had already established his substantive preference for incremental, community-led density changes. This pattern — supporting modest, process-respecting density adjustments while opposing rapid broad upzoning — matches value 2 (allow modest density increases with strong design review and neighborhood input). Not value 1 (he did not oppose all density) and not values 4-5 (he actively blocked the upzoning effort).',
  ARRAY[
    'https://stopbtownupzoning.org/2023/04/04/we-endorse-lois-sabo-skelton-and-isak-nti-asare-city-council-at-large/',
    'https://bsquarebulletin.com/start-of-process-for-possible-zoning-changes-halted-with-4-4-votes-by-bloomington-city-council/',
    'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning',
    'https://thebloomingtonchronicle.org/index.php/Isak_Asare'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 4. CIVIL RIGHTS AND SOCIAL JUSTICE (topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Value 2: Strengthen civil rights enforcement and address systemic discrimination
-- Evidence: Asare voted unanimously (9-0) for the Gaza ceasefire resolution in April 2024 and the
-- 9-0 veto override in May 2024 — demonstrating support for council resolutions addressing global
-- human rights and discrimination. His Flock camera statement — "The strongest protection for civil
-- liberties is not better settings or better assurances—it is restraint. You cannot misuse data that
-- does not exist. You cannot be compelled to share what you never collected. And you cannot normalize
-- a form of power you have chosen not to build." — frames civil liberties as a structural protection
-- issue rather than individual case management. He introduced the resolution restricting Flock data
-- from immigration and reproductive health investigations. He is described in endorsement materials as
-- "a deeply committed progressive." No evidence of reparations mandates (value 1) or limiting civil
-- rights enforcement (values 3-5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b280bdf-bf17-48ad-853d-a4f0a854c548', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2b280bdf-bf17-48ad-853d-a4f0a854c548',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from voting record, direct quotes, and endorsement materials. Asare voted with all 9 council members for the Gaza ceasefire resolution (April 2024) and the veto override (May 2024), which called for an end to civilian casualties and humanitarian aid. On civil liberties broadly, he introduced the Flock camera oversight resolution (Feb 2026) and stated: "My preference is to eliminate our relationship with this technology entirely. The strongest protection for civil liberties is not better settings or better assurances — it is restraint. You cannot misuse data that does not exist. You cannot be compelled to share what you never collected. And you cannot normalize a form of power you have chosen not to build." He also worked with councilmember Piedmont-Smith on a surveillance ordinance imposing hard retention caps, mandatory auditing, and a sunset clause — a systemic rather than case-by-case approach to civil liberties. He is described in 2023 endorsement materials as "a deeply committed progressive." He did not sign the letter condemning IU''s response to pro-Palestinian protests — but solely because of his status as an IU employee, having already expressed agreement with its substance. No evidence of mandating racial equity requirements in all institutions or reparations (value 1), or of limiting civil rights enforcement (values 3-5). Value 2 (strengthen civil rights enforcement and address systemic discrimination) best fits.',
  ARRAY[
    'https://bsquarebulletin.com/bloomington-council-overrides-mayors-veto-of-resolution-on-gaza-by-same-9-0-vote-as-before/',
    'https://www.ipm.org/news/2026-03-05/with-residents-opposing-surveillance-tools-bloomington-city-council-seeks-details-from-mayor-police',
    'https://www.idsnews.com/article/2026/03/bloomington-city-council-flock-cameras-resolution-hopewell-affordable-housing',
    'https://stopbtownupzoning.org/2023/04/04/we-endorse-lois-sabo-skelton-and-isak-nti-asare-city-council-at-large/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 5. PUBLIC SAFETY APPROACH (topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Value 3: Keep current public safety funding while adding crisis response teams for mental health and addiction calls
-- Evidence: No statements from Asare calling for reducing or redirecting police budgets. He voted for
-- the 2024 and 2025 city budgets that maintained police staffing and approved officer pay. His primary
-- public safety legislative work has been the Flock surveillance oversight resolution — a transparency/
-- accountability measure, not a budget reallocation. His progressive orientation and work on the Jack
-- Hopkins social services fund (which funds mental health nonprofits) is consistent with adding crisis
-- response infrastructure alongside police, not replacing it. No evidence of defund positions (value 1-2)
-- or expanded police spending priority (values 4-5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b280bdf-bf17-48ad-853d-a4f0a854c548', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2b280bdf-bf17-48ad-853d-a4f0a854c548',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from voting record and issue priorities; no direct statement on police budget philosophy found. Asare has not made public statements calling for reducing or reallocating the police budget. He supported the 2024 and 2025 city budgets maintaining current police staffing and approving officer pay raises. His most prominent public safety legislative action was introducing the Flock license plate reader oversight resolution (Feb 2026) — a civil liberties and transparency measure, not a budget reallocation proposal. As Jack Hopkins Fund Chair he directed grants to mental health and social service nonprofits, consistent with an interest in building community support infrastructure alongside (not instead of) police. His progressive record and social services focus are consistent with value 3 (keep current public safety funding while adding crisis response teams). No evidence of calling to redirect a significant portion of the police budget to social services (values 1-2), nor of advocating for expanded police staffing or equipment as a top spending priority (values 4-5). This is an inference; no direct quote on police budget philosophy or co-responder programs was found. Checked: B Square Bulletin, Indiana Daily Student, Indiana Public Media, city budget coverage 2024-2026.',
  ARRAY[
    'https://bsquarebulletin.com/2024/01/11/bloomington-city-councils-first-meeting-puts-familiar-faces-in-leadership-gives-public-safety-some-airtime/',
    'https://www.idsnews.com/article/2026/03/bloomington-city-council-flock-cameras-resolution-hopewell-affordable-housing',
    'https://bloomington.in.gov/council/jack-hopkins',
    'https://bloomington.in.gov/news/2024/10/11/6074'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 6. LOCAL IMMIGRATION ENFORCEMENT (topic_id: b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Value 2: Comply only with court-ordered detainers; protect undocumented crime victims and witnesses from referral
-- Evidence: Asare personally introduced the February 2026 resolution requesting a full BPD report on
-- Flock camera data access by officers and external agencies, specifically concerned about immigration
-- enforcement use. He stated: "My preference is to eliminate our relationship with this technology
-- entirely." The council unanimously passed his oversight resolution in March 2026 restricting Flock
-- data from immigration investigations. BPD subsequently updated its policy to explicitly prohibit
-- Flock data use for immigration enforcement. The full council then voted to end the Flock contract
-- in April 2026. Monroe County was listed as Indiana's only DHS "sanctuary jurisdiction" in 2025.
-- Asare's leadership on preventing city technology from being used in immigration enforcement is
-- strong evidence for value 2 (limit cooperation, protect undocumented residents).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b280bdf-bf17-48ad-853d-a4f0a854c548', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2b280bdf-bf17-48ad-853d-a4f0a854c548',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from direct legislation and public statements. Asare personally introduced the February 2026 resolution requesting a full Bloomington Police Department report on which officers and agencies have access to Flock license plate reader camera data, specifically motivated by concern that Flock data could be shared with ICE through its national camera network. He stated publicly: "My preference is to eliminate our relationship with this technology entirely. The strongest protection for civil liberties is not better settings or better assurances — it is restraint." The full council unanimously passed his oversight resolution in March 2026, restricting Flock data from immigration enforcement uses. BPD updated its policies March 26, 2026 to explicitly prohibit Flock data use for immigration enforcement and reproductive healthcare investigations. The council subsequently voted to allow the Flock contract to expire in April 2026, and the city ended data sharing with Indiana law enforcement. Monroe County was listed by DHS as Indiana''s only "sanctuary jurisdiction" in May 2025 (later removed without explanation). No Asare-specific statement on ICE detainers was found, but his legislative leadership preventing city technology from facilitating immigration enforcement, and the city''s posture of not cooperating with ICE beyond legal requirements, is consistent with value 2 (comply only with court-ordered detainers; protect undocumented crime victims and witnesses from referral). No evidence of more aggressive non-cooperation (value 1, refusing all ICE detainers) or cooperation (values 3-5).',
  ARRAY[
    'https://www.ipm.org/news/2026-03-05/with-residents-opposing-surveillance-tools-bloomington-city-council-seeks-details-from-mayor-police',
    'https://www.idsnews.com/article/2026/03/bloomington-city-council-flock-cameras-resolution-hopewell-affordable-housing',
    'https://www.idsnews.com/article/2026/04/bloomington-police-department-bans-flock-data-immigration-reproductive-investigations',
    'https://www.idsnews.com/article/2026/04/city-of-bloomington-ends-flock-contract-data-sharing-with-indiana-law-enforcement',
    'https://bloomingtonian.com/2025/05/30/monroe-county-named-indianas-only-sanctuary-jurisdiction-on-homeland-security-watchlist/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 7. ECONOMIC DEVELOPMENT INCENTIVES (topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Not found: Asare was not on the council for the 2022 Catalent tax abatement vote (Flaherty's solo no).
-- His 2023 campaign cited "promoting Bloomington's economic health" as a priority but gave no specifics
-- on tax abatements or corporate incentives. No council votes or statements by Asare on tax abatements
-- or economic development incentive packages were found after he took office in January 2024.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2b280bdf-bf17-48ad-853d-a4f0a854c548',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Asare was not on the council for the 2022 Catalent pharmaceutical tax abatement vote. His 2023 campaign cited "promoting Bloomington''s economic health" as a priority but provided no specifics on corporate tax incentives, abatements, or development subsidy philosophy. No council votes or statements from Asare on economic development incentive packages, tax abatements, or competing for major employers were found after he took office in January 2024. Checked: B Square Bulletin, Indiana Daily Student, Indiana Economic Digest, Indiana Public Media, city council meeting records, Bloomington.in.gov.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 8. TRANSPORTATION PRIORITIES (topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Not found: Asare raised questions about the makeup of the new Transportation Commission during
-- November 2024 discussions, and voted for the commission's creation (7-2, Feb 2025), which was
-- chartered to "prioritize nonautomotive modes and sustainability." However, this is a vote on
-- governance structure rather than a statement of his own transportation priorities. No specific
-- statements from Asare on road vs. transit vs. cycling investment priorities were found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2b280bdf-bf17-48ad-853d-a4f0a854c548',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. Asare raised questions about the makeup of the proposed merged Transportation Commission during council discussions in November 2024. He voted in favor of creating the new Transportation Commission in February 2025 (7-2 vote, with Rollo and Ruff dissenting), which replaced three prior commissions and was chartered to prioritize "nonautomotive modes and sustainability." However, this governance vote is not a direct statement of his personal transportation investment priorities. No specific statements from Asare on road capacity vs. transit vs. cycling/pedestrian investment priorities were found. Checked: B Square Bulletin, Indiana Daily Student, Indiana Public Media, IUSTV, city council meeting records, Bloomington.in.gov transportation pages.',
  ARRAY[
    'https://www.iustv.com/article/2025/02/city-council-approves-merging-commissions-into-new-transportation-commission',
    'https://www.idsnews.com/article/2024/11/bloomington-city-council-traffic-parking-bike-commission-merger'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
