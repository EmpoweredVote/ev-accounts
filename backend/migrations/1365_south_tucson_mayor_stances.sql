-- =====================================================================================
-- Compass stances: Roxanna Valenzuela — Mayor, City of South Tucson (AZ)
-- politician_id: 94fd53ed-f05a-4e65-a600-0fb5076f2109   (external_id -4015001)
-- Nonpartisan (antipartisan display). Elected to the City Council (term thru 2026);
-- chosen Mayor by the council (Mayor is a council-selected TITLE in South Tucson, not a
-- directly elected office). Running in the July 21, 2026 primary to retain her at-large
-- seat. Positions attributed ONLY to her own on-record statements/actions; no other
-- member's views. Recall-era / historical South Tucson politics are treated as
-- BACKGROUND, never as current-roster fact.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Valenzuela position
--     (verbatim candidate-Q&A statements in the AZ Luminaria voter guide and the
--     Tucson Spotlight council profile — both non-WAF sources actually fetched
--     2026-07-17).
--   * Topics with no clear documented Valenzuela position emit NO row (honest blank). No
--     party inference, no neutral defaults.
--   * Discrete 1-5 "chairs" (feedback_compass_chairs_not_polarity), never a polarity scale.
--   * AUDIT-ONLY / unregistered (no migration-ledger entry). Touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- Reference: topic UUIDs used below (36 non-judicial live compass topics are in scope;
--   the 8 judicial-* topics are NEVER seeded for a city council official):
--     public-safety-approach = e9ebefcd-c496-45e8-b816-a79f8442ba85
--     economic-development   = eb3d1247-0de1-4b7f-baec-7259861efd53
--     housing                = 669cac97-66a6-4087-b036-936fbe62efb3
--     taxes                  = f7e5678d-dadd-4556-a2fc-446e24642ceb
--
-- SEEDED (4 topics):
--   public-safety-approach = 4  (voter guide: "invested millions in our public safety
--                                department and built some of the fastest response times";
--                                emergency services "fully equipped" + officer training;
--                                additive youth crime-prevention framing)
--   economic-development   = 2  (voter guide: "driving local economic development" and
--                                fostering "a thriving local business environment that
--                                generates new revenue" — local/small-business, not
--                                major-employer recruitment)
--   housing                = 2  (Tucson Spotlight: "keep the houses for everybody - not
--                                just for low income"; involved with Barrios Unidos Land
--                                Trust; volunteers with Casa Maria)
--   taxes                  = 3  (voter guide: "Eliminating the grocery tax was a necessary
--                                step to alleviate burdens on struggling families" +
--                                "streamlining municipal operations and cutting unnecessary
--                                operational costs" — a targeted regressive-tax cut +
--                                efficiency, structure otherwise intact, no service rollback)
--
-- DELIBERATELY BLANK (no clean, attributable documented Valenzuela position found):
--   civil-rights / surveillance: the city ended its Flock surveillance-camera contract
--     under her tenure (AZPM/The Press Room, Feb 2026) — but that is a council decision and
--     the AZPM item is a video with NO transcript available this session, so her specific
--     reasoning cannot be quoted or mapped to a chair. BLANK (honest — no unfetched cite).
--   homelessness / homelessness-response: she names "addressing the widespread challenges
--     of homelessness and substance addiction" as a priority, but with no specific
--     housing-first-vs-enforcement approach that maps to a chair. BLANK.
--   growth-and-development, residential-zoning, rent-regulation, local-immigration,
--     local-environment, city-sanitation, transportation-priorities, data-centers,
--     public-safety adjacent specifics: no citable Valenzuela position mapping to a chair.
--   Non-local federal/state topics (a city mayor has no governing record on these):
--     abortion, ai-regulation, campaign-finance, childcare, climate-change, deportation,
--     economic (covered), fossil-fuels, healthcare, immigration, jail-capacity,
--     medicare/aid, misinformation, redistricting, religious-freedom, same-sex-marriage,
--     school-vouchers, social-security, tariffs, trans-athletes, ukraine-support,
--     voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Roxanna Valenzuela / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94fd53ed-f05a-4e65-a600-0fb5076f2109',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94fd53ed-f05a-4e65-a600-0fb5076f2109',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Valenzuela's documented public-safety record is one of active investment in staffing and equipment. In the AZ Luminaria 2026 voter guide she describes "ensuring our emergency services are fully equipped, and our officers have the necessary training," and says the city has "invested millions in our public safety department and built some of the fastest response times." She pairs that with expanding youth crime-prevention programs "to break generational cycles." Her Tucson Spotlight comments temper it against reflexive spending ("I don't want us to act irrationally just because we have the money"), so this is not making police the single top budget priority over all else (chair 5). Materially funding and equipping the police/fire departments to improve staffing and response times — rather than redirecting police funds to social services (chair 1), shifting calls to unarmed responders (chair 2), or merely maintaining current funding (chair 3) — matches increasing police staffing, equipment, and pay to improve response times (chair 4).$$,
        ARRAY['https://azluminaria.org/2026/06/22/your-voter-guide-where-south-tucson-city-council-candidates-stand-on-key-issues/',
              'https://www.tucsonspotlight.org/inside-south-tucson/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roxanna Valenzuela / economic-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94fd53ed-f05a-4e65-a600-0fb5076f2109',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94fd53ed-f05a-4e65-a600-0fb5076f2109',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Valenzuela frames economic development around the city's own small businesses and cultural identity rather than recruiting outside major employers. In the AZ Luminaria voter guide she advocates "driving local economic development" and fostering "a thriving local business environment that generates new revenue," and elsewhere emphasizes strengthening small businesses and protecting South Tucson's unique (largely Mexican-food/South-4th-Avenue) small-business culture. For a one-square-mile city with no capacity to abate taxes for large corporate employers, that local-business-and-entrepreneur focus — rather than offering no incentives at all (chair 1), targeted industry incentives with community-benefit agreements (chair 3), or competing for major employers with significant abatements (chair 4) — matches small business support and local entrepreneur programs (chair 2).$$,
        ARRAY['https://azluminaria.org/2026/06/22/your-voter-guide-where-south-tucson-city-council-candidates-stand-on-key-issues/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roxanna Valenzuela / housing (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94fd53ed-f05a-4e65-a600-0fb5076f2109',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94fd53ed-f05a-4e65-a600-0fb5076f2109',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Valenzuela backs actively preserving and expanding affordable housing so lower-income residents are not displaced. In the Tucson Spotlight council profile she says "It's very important to us that we keep the houses for everybody - not just for low income," and she is documented as involved with the Barrios Unidos Land Trust (a community land trust that keeps housing permanently affordable) and as a volunteer with Casa Maria, the neighborhood's Catholic Worker aid house. That posture — publicly/community-funded affordable housing and anti-displacement tools — goes beyond targeted subsidies and easier permits (chair 3) but stops short of the city directly building and operating public housing for all comers (chair 1), matching using publicly funded new housing and affordability requirements to keep housing attainable (chair 2).$$,
        ARRAY['https://www.tucsonspotlight.org/inside-south-tucson/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roxanna Valenzuela / taxes (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94fd53ed-f05a-4e65-a600-0fb5076f2109',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94fd53ed-f05a-4e65-a600-0fb5076f2109',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Valenzuela's documented fiscal posture is a targeted adjustment to an otherwise-intact revenue structure, not a broad tax cut with service rollbacks or a broad tax increase. In the AZ Luminaria voter guide she calls "Eliminating the grocery tax ... a necessary step to alleviate burdens on struggling families," paired with "streamlining municipal operations and cutting unnecessary operational costs." Critically, she made that regressive-consumption-tax cut while continuing to invest millions in public-safety services (see public-safety-approach), so she is not cutting taxes and scaling back public services to match (chair 4) or shrinking government (chair 5), nor raising taxes on the wealthy/companies (chairs 1-2). Removing one regressive tax and finding efficiencies while preserving services matches keeping the current tax system mostly as-is with small, targeted adjustments (chair 3).$$,
        ARRAY['https://azluminaria.org/2026/06/22/your-voter-guide-where-south-tucson-city-council-candidates-stand-on-key-issues/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
