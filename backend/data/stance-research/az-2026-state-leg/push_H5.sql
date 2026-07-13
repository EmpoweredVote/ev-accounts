-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch H5 (12 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-H5.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Jeff Weninger (State House District 13) / data-centers = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'b813cb2d-f80e-4f53-83e0-fc0477ff3f3d', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'b813cb2d-f80e-4f53-83e0-fc0477ff3f3d', ct.id, $ctx$Prime sponsor of HB4009 (2026), which directs the State Land Department to map state trust land parcels identified as the best sites for computer data centers and requires the department to consult with the data-center industry when developing the map, actively facilitating industry-preferred siting on state land. This is an encouraging/facilitating posture toward data-center growth, though the bill does not address ratepayer or energy-demand transparency, aligning best with stance 4's 'encouraging development' language rather than a moratorium or incentive-package approach.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4009p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2361']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Willoughby (State House District 13) / immigration = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8edebfca-2e35-4424-85f8-f3ad498a2890', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8edebfca-2e35-4424-85f8-f3ad498a2890', ct.id, $ctx$Willoughby is a named cosponsor of HB2806 (2026), which requires county recorders and the Department of Transportation to verify voter-registration and driver's-license applicants' citizenship or lawful presence through the federal SAVE program and tightens AHCCCS eligibility verification for noncitizens. Limiting public-benefit and document access to people with verified legal status matches stance 4's 'limit public services to people with legal status' language.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2806p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2344']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Willoughby (State House District 13) / medicare/aid = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8edebfca-2e35-4424-85f8-f3ad498a2890', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8edebfca-2e35-4424-85f8-f3ad498a2890', ct.id, $ctx$As prime sponsor of HB2403 (2026), Willoughby appropriated $7.5 million per year for fiscal years 2026-27 through 2029-30 to AHCCCS for provider rate increases for home- and community-based services serving the elderly and people with physical disabilities. This is a targeted funding improvement to the existing program rather than an eligibility expansion or a benefit cut, matching stance 3's 'improve current programs while controlling costs.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2403p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2344']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julie Willoughby (State House District 13) / fossil-fuels = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8edebfca-2e35-4424-85f8-f3ad498a2890', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'fossil-fuels'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8edebfca-2e35-4424-85f8-f3ad498a2890', ct.id, $ctx$Willoughby's prime-sponsored HB2696 (2026) makes reducing gas and fuel prices the Arizona Commerce Authority's primary objective, directs the authority to collaborate with the oil and gas industry, and requires a formal study of repealing Arizona's cleaner-burning-gasoline environmental requirement along with the feasibility of new refineries, pipelines, and a strategic oil/gas reserve. This expansionary, industry-aligned posture toward fossil-fuel infrastructure matches stance 4's permit/production-expansion direction, short of an outright repeal of environmental restrictions under stance 5.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2696p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2344']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'fossil-fuels'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Khyl Powell (State House District 14) / jail-capacity = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '3769c4ad-3844-4ab6-9416-96b93c049b33', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '3769c4ad-3844-4ab6-9416-96b93c049b33', ct.id, $ctx$Powell is prime sponsor of HB2770 (2026), which creates a Home Confinement Program with electronic monitoring letting eligible non-violent inmates serve their final months of a sentence outside prison, and of HB2002 (2026), which expands parole eligibility to life-sentence prisoners convicted on or after 1994 (previously that classification applied only to pre-1994 offenses). Both measures reduce time served in physical custody through alternative-release mechanisms rather than adding capacity, matching stance 2's 'reducing the incarcerated population through...alternatives.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2770p.pdf', 'https://www.azleg.gov/legtext/57leg/2R/bills/hb2002p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2362']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'jail-capacity'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Khyl Powell (State House District 14) / residential-zoning = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '3769c4ad-3844-4ab6-9416-96b93c049b33', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'residential-zoning'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '3769c4ad-3844-4ab6-9416-96b93c049b33', ct.id, $ctx$Prime sponsor of HB4028 (2026), which mandates that municipalities over 75,000 population allow at least two accessory dwelling units per single-family lot as a by-right permitted use and bars cities from imposing parking mandates, exterior design-matching requirements, or restrictive covenants on ADUs. This broad by-right deregulation of single-family lot restrictions matches stance 4's 'streamline approvals and reduce parking requirements,' short of stance 5's full elimination of single-family zoning.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4028p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2362']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'residential-zoning'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Khyl Powell (State House District 14) / growth-and-development = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '3769c4ad-3844-4ab6-9416-96b93c049b33', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'growth-and-development'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '3769c4ad-3844-4ab6-9416-96b93c049b33', ct.id, $ctx$Prime sponsor of HB2946 (2026), which caps future municipal development-fee increases (phased 25%/50% limits, no more than once every four years) and requires a unanimous council vote plus a documented 'extraordinary circumstances' report to exceed those caps. Limiting how much cities can raise development fees on new construction matches stance 4's 'reduce fees...to grow the city's tax base.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2946p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2362']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'growth-and-development'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Laurin Hendrix (State House District 14) / voting-rights = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1f7399ee-2434-49dc-9a18-857bfa0e41f1', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1f7399ee-2434-49dc-9a18-857bfa0e41f1', ct.id, $ctx$Hendrix is a named cosponsor of HCR2001 (2026), the 'Arizona Secure Elections Act,' a proposed constitutional amendment requiring photo ID to vote (with free IDs guaranteed by law), ending early voting at 7 p.m. the Friday before Election Day, and converting mail voting from automatic to an opt-in request requiring documented proof of citizenship. The photo-ID-with-free-ID-access requirement combined with tightened mail/early-voting rules matches stance 4's photo-ID-and-roll-maintenance framing, short of stance 5's full elimination of mail voting.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2001p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2316']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Way (State House District 15) / civil-rights = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '29b130a2-1531-4b35-b79e-dc0e8e3c0b93', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '29b130a2-1531-4b35-b79e-dc0e8e3c0b93', ct.id, $ctx$As prime sponsor of HB2135 (2026), Way created a civil cause of action -- with a $100,000 minimum statutory damages floor plus compensatory damages and attorney fees -- against any entity found to violate a state or federal law prohibiting 'diversity, equity and inclusion' policies, defining DEI/critical race theory/anti-racism concepts broadly as prohibited conduct. Establishing a strong private-enforcement mechanism to penalize DEI and race-conscious programs matches stance 5's elimination of race-based government and institutional programs.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2135p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2363']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Way (State House District 15) / residential-zoning = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '29b130a2-1531-4b35-b79e-dc0e8e3c0b93', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'residential-zoning'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '29b130a2-1531-4b35-b79e-dc0e8e3c0b93', ct.id, $ctx$Prime sponsor of HB2588 (2026), which bars municipalities from requiring HOAs, gates/walls, or aesthetic design standards (building materials, colors, rooflines, facades, driveway surfacing) for single-family homes and accessory dwelling units, and prohibits denying or delaying building permits based on such standards. Stripping cities of major neighborhood-character design-control tools in favor of by-right development matches stance 4's deregulatory, streamlined-approval direction.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2588p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2363']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'residential-zoning'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael Way (State House District 15) / immigration = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '29b130a2-1531-4b35-b79e-dc0e8e3c0b93', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '29b130a2-1531-4b35-b79e-dc0e8e3c0b93', ct.id, $ctx$Way is a named cosponsor of HB2806 (2026), which tightens citizenship and lawful-presence verification for voter registration, driver's licenses, and AHCCCS eligibility using the federal SAVE program, limiting public-service and document access to people with verified legal status, matching stance 4's 'limit public services to people with legal status' language.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2806p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2363']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Neal Carter (State House District 15) / religious-freedom = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '9a81dfd3-b70b-45bf-8851-3907d6e12508', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'religious-freedom'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '9a81dfd3-b70b-45bf-8851-3907d6e12508', ct.id, $ctx$Carter is a named cosponsor of HB2110 (2026), which requires the governing boards of school districts, charter schools, community colleges, and public universities to allow any board member to pray during a public governing-body meeting on that member's request. Affirmatively guaranteeing religious expression by officials within public governmental proceedings matches stance 4's protection of religious practice within public institutions.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2110p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2297']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'religious-freedom'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
