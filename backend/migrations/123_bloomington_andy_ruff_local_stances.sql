BEGIN;

-- ============================================================
-- Migration 123: Local Lens compass stances for Andy Ruff
-- Bloomington City Common Council At Large
-- politician_id: ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6
-- Researched: 2026-05-11
-- ============================================================

-- 1. AFFORDABLE HOUSING (topic_id: 669cac97-66a6-4087-b036-936fbe62efb3)
-- Value 2: Use rent caps, require new developments to include affordable units, and publicly fund new housing
-- Evidence: Ruff signed a letter demanding the Hopewell South PUD include 25-50% permanently affordable units
-- (vs. the proposed 15%). At the final vote he opposed lowering the floor below 50%, stating
-- "One thing that I feel like can be set clear is a high bar on the amount of affordability we're going to have
-- in the project." He voted against the 35% compromise condition (with Rollo) because it didn't reach 50%.
-- This is a direct requirement on private development, not public housing construction (value 1).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from council votes and direct quotes. Ruff co-signed a letter demanding the Hopewell South PUD set 25–50% of units as permanently affordable (vs. the proposed 15%). At the May 2026 vote he opposed lowering the bar below 50%, stating: "One thing that I feel like can be set clear is a high bar on the amount of affordability we are going to have in the project." He voted against the 35% compromise condition because it fell short. He also serves on the Jack Hopkins Social Services Committee which funds housing and eviction-prevention services. His approach centers on mandatory affordability requirements in private developments and public subsidy for affordable projects — matching value 2.',
  ARRAY[
    'https://bsquarebulletin.com/hopewell-south-pud-wins-unanimous-ok-from-bloomington-city-council/',
    'https://www.ipm.org/news/2026-03-31/city-council-members-ask-mayor-to-change-hopewell-proposal',
    'https://www.ipm.org/news/2026-05-08/hopewell-south-passes-city-council-unanimously',
    'https://bloomington.in.gov/council/jack-hopkins'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 2. CRIMINALIZATION OF HOMELESSNESS (topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a)
-- NOT FOUND: Ruff rejoined the council in January 2024. The September 2023 council vote that rejected
-- an ordinance prohibiting camping on sidewalks (voted down 5-2) occurred before he was seated.
-- No public statements or votes from Ruff on criminalization of homelessness were found.
-- Checked: B Square, Indiana Public Media, IDS News, his council bio, campaign site.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. The September 2023 Bloomington council vote rejecting a sidewalk/camping ordinance occurred before Ruff rejoined the council (January 2024). No subsequent votes, committee statements, or candidate questionnaire responses on criminalization of homelessness were located. Checked: B Square Bulletin, Indiana Public Media, Indiana Daily Student, Ballotpedia, his official council bio, campaign website (andyruffforcouncil.com), and his 2020 congressional campaign page.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 3. RESIDENTIAL ZONING (topic_id: d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Value 2: Allow modest density increases (duplexes, accessory units) with strong design review and neighborhood input
-- Evidence: Ruff was "outspoken opponent" of voiding single-family zoning in 2019. In March 2025 he was one
-- of four votes blocking introduction of resolutions that would allow duplexes/triplexes/fourplexes by right
-- in single-family zones (4-4 tie). In May 2024 he dissented (7-2) on the 140-acre Summit District rezone,
-- citing "qualitative growth" — "You can't grow indefinitely in a finite environment." His process objection
-- in 2025 ("needs a long, lengthy, well-deliberated process") indicates he supports community input before any
-- changes, not outright prohibition of all density. His 2019 endorsement by a neighborhood-character group
-- further confirms a cautious, community-deliberation approach consistent with value 2.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from voting record and public statements. Ruff was described as an "outspoken opponent" of the Hamilton administration''s push to void single-family zoning in 2019. In March 2025 he was one of four votes blocking introduction of resolutions to allow duplexes, triplexes, and fourplexes by right in residential zones (4-4 tie). He explained: "They have huge implications for the whole community, and it needs a long, lengthy, well-deliberated, well understood process, and this wasn''t the start of it in my opinion." He also dissented on the 140-acre Summit District rezone (7-2, May 2024), citing the city''s comprehensive plan language distinguishing qualitative growth from mere physical expansion ("You can''t grow indefinitely in a finite environment"). This record reflects a neighborhood-character and community-input-first approach rather than support for broad upzoning — consistent with value 2 (modest density with design review and neighborhood input).',
  ARRAY[
    'https://stopbtownupzoning.org/2023/03/13/we-endorse-andy-ruff-city-council-at-large/',
    'https://bsquarebulletin.com/start-of-process-for-possible-zoning-changes-halted-with-4-4-votes-by-bloomington-city-council/',
    'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning',
    'https://bsquarebulletin.com/2024/05/16/140-acre-rezone-in-southwest-part-of-town-okd-by-bloomington-city-council-on-7-2-vote/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 4. CIVIL RIGHTS AND SOCIAL JUSTICE (topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Value 2: Strengthen civil rights enforcement and address systemic discrimination
-- Evidence: Ruff sponsored the 2003 resolution opposing the Iraq War and another opposing the PATRIOT Act
-- (civil liberties). He was the driving force behind Indiana's first Living Wage Ordinance (2005) — a systemic
-- economic justice measure. He voted unanimously (9-0) for the April 2024 Gaza ceasefire resolution and
-- helped override the mayor's veto; he argued the council has authority to address "issues we care about
-- as a community — local, state, federal or global." His 20+ year record is consistently framed as
-- advocacy for "the most vulnerable" and working families. No evidence of reparations mandates (value 1)
-- or limiting enforcement (value 3+).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from legislative record and public statements. Ruff sponsored the 2003 council resolution opposing the invasion of Iraq and a resolution opposing the PATRIOT Act — both civil liberties positions. He was the primary sponsor of Indiana''s first Living Wage Ordinance (2005), a systemic economic equity measure. He voted unanimously with the council (9-0) in April 2024 to pass a Gaza ceasefire resolution and helped override the mayor''s veto, arguing the council chambers are "a place where we can come together, debate and deliberate the issues we care about as a community — local, state, federal or global." His two-decade public record is consistently framed around support for vulnerable populations, workers, and civil liberties. This aligns with value 2 (strengthen civil rights enforcement, address systemic discrimination) rather than value 1 (reparations mandates) or values 3-5.',
  ARRAY[
    'https://bsquarebulletin.com/council-candidate-at-large-andy-ruff/',
    'https://stopbtownupzoning.org/2023/03/13/we-endorse-andy-ruff-city-council-at-large/',
    'https://bsquarebulletin.com/2024/04/03/gaza-ceasefire-resolution-gets-9-0-vote-from-bloomington-council-mayoral-veto-uncertain/amp/',
    'https://www.idsnews.com/article/2024/05/bloomington-indiana-city-council-overrides-mayors-veto-of-gaza-ceasefire-resolution'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 5. PUBLIC SAFETY APPROACH (topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- NOT FOUND: No direct vote or statement from Ruff on police budget size, defunding, or co-responder
-- programs was found. The city piloted Community Service Specialists (civilian 911 responders) in the
-- 2024 budget but no individual council member vote on that specific line item was located for Ruff.
-- He serves on the Public Safety Local Income Tax Committee but no committee positions were found.
-- Checked: B Square, IPM, IDS News, Ballotpedia, his council bio, 2024 budget coverage.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. Ruff serves on the Public Safety Local Income Tax Committee but no statements or votes on police budget size, defunding, or co-responder program design were found. The city piloted Community Service Specialists (civilian 911 responders) in the 2024 budget cycle, but no individual position from Ruff on that initiative was located. Checked: B Square Bulletin, Indiana Public Media, Indiana Daily Student, Bloomington city council page, his campaign website, and Ballotpedia.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 6. LOCAL IMMIGRATION ENFORCEMENT (topic_id: b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- NOT FOUND: No direct statement or vote from Ruff on ICE detainers, immigration enforcement policy,
-- or sanctuary/welcoming ordinance was found. The council voted unanimously on the March 2026 Flock
-- resolution (limiting surveillance data use for immigration investigations), but Ruff's individual
-- role in that debate was not documented. Bloomington ended the Flock contract in April 2026 but
-- no specific quote from Ruff on immigration was found. Checked: B Square, IPM, IDS News,
-- Indiana Capital Chronicle, his council page.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found for Ruff specifically. The Bloomington City Council voted unanimously (March 2026) for a resolution restricting Flock camera data use for immigration investigations, and the city ended its Flock contract entirely in April 2026. However, no statements or quotes specifically from Ruff on ICE detainers, immigration enforcement, or sanctuary/welcoming ordinances were found. Bloomington''s welcoming-city ordinance discussions have not reached a final council vote. Checked: B Square Bulletin, Indiana Public Media, Indiana Daily Student, Indiana Capital Chronicle, his official council bio, and Ballotpedia.',
  ARRAY[
    'https://www.idsnews.com/article/2026/03/bloomington-city-council-flock-cameras-resolution-hopewell-affordable-housing',
    'https://www.idsnews.com/article/2026/04/city-of-bloomington-ends-flock-contract-data-sharing-with-indiana-law-enforcement'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 7. ECONOMIC DEVELOPMENT INCENTIVES (topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Value 3: Targeted incentives for specific industries with community benefit agreements and job quality requirements
-- Evidence: Ruff sponsored Indiana's first Living Wage Ordinance (2005), requiring city contractors and
-- grant recipients to pay living wages — a direct community benefit requirement attached to city economic
-- relationships. He voted in favor of extending a residential tax abatement for a low-income housing complex,
-- contextualizing it with a critique of how industrial abatements receive similar treatment: "With tax
-- abatements that aren't related to residential, we constantly find things like free market forces."
-- He also voted for the residential TIF while questioning unlimited growth. His "qualitative growth"
-- philosophy and labor advocacy suggest he supports targeted economic tools with conditions attached,
-- not maximum incentives or opposition to all incentives.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from legislative record. Ruff sponsored Indiana''s first Living Wage Ordinance (2005), requiring city contractors and grant recipients to pay living wages — directly attaching a labor-standards condition to city economic relationships. He supported extending a tax abatement for a low-income housing complex, citing consistency with how other abatements are evaluated ("With tax abatements that aren''t related to residential, we constantly find things like free market forces"). He voted for a residential TIF while expressing skepticism about unlimited quantitative growth. His overall economic philosophy of "qualitative growth — a better city, not just a bigger city" suggests support for targeted economic tools tied to community benefit (job quality, affordability), consistent with value 3. No evidence of opposing all incentives (value 1-2) or of supporting maximum incentives regardless of conditions (value 4-5).',
  ARRAY[
    'https://stopbtownupzoning.org/2023/03/13/we-endorse-andy-ruff-city-council-at-large/',
    'https://bsquarebulletin.com/bloomington-extends-tax-break-for-troubled-low-income-housing-complex-citing-factors-beyond-the-control-of-the-property-owner/',
    'https://bsquarebulletin.com/bloomington-council-oks-residential-tif-for-summit-now-back-to-rdc-for-final-step/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 8. TRANSPORTATION PRIORITIES (topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Value 1: Prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking requirements citywide
-- Evidence: Ruff has been "a commuting cyclist in Bloomington for 50 years" and raised children "using walking
-- and bicycling for transportation." He sought a seat on the new Transportation Commission specifically to
-- advocate for greenways and traffic calming programs. He attempted to amend the transportation commission
-- ordinance to give the council final authority over permanent roadway changes (greenways/traffic calming).
-- He voted against the commission merger only due to procedural/legal concerns about council authority over
-- greenway decisions — not opposition to cycling or pedestrian infrastructure. His personal identity as a
-- lifelong cyclist and his specific advocacy for the greenways program distinguish him as a multimodal
-- transportation champion, consistent with value 1.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec5eefcb-8f41-4bdd-8782-8751f1ed3fb6',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from personal background and legislative advocacy. Ruff has commuted by bicycle in Bloomington for 50 years and raised two children using walking and cycling as primary transportation. He sought appointment to the new Transportation Commission specifically to advocate for greenways and traffic calming programs. He attempted to amend the commission ordinance to give the council final oversight authority over permanent roadway changes like greenways — showing active investment in non-automotive infrastructure governance. His vote against the commission merger was procedural (concern about unclear statutory authority), not opposition to multimodal transportation. This record is consistent with value 1 (prioritize pedestrian infrastructure, cycling networks, and public transit).',
  ARRAY[
    'https://bsquarebulletin.com/amid-shift-in-bloomington-street-oversight-flaherty-gets-city-council-nod-for-new-transportation-group-2/',
    'https://www.iustv.com/article/2025/02/city-council-approves-merging-commissions-into-new-transportation-commission'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
