-- =====================================================================================
-- Compass stances: Roxanne Ziegler — Vice Mayor & Council Member, Town of Marana (AZ)
-- politician_id: 4a9bf58b-fd95-4010-81fa-481e1561633d
-- Nonpartisan; long-serving councilmember, current Vice Mayor (named Vice Mayor Jan 2025).
-- Her seat is mid-term (NOT on the July 21, 2026 ballot), so 2026 candidate-forum coverage
-- does not feature her. Positions attributed only to documented council votes / on-record
-- public statements covered by citable news outlets.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Ziegler position (a recorded
--     council vote she cast — including unanimous votes she was part of — or an on-record public
--     statement in a citable article), with real cited source URLs confirmed via web research.
--   * Topics with no clear documented Ziegler position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (3 topics):
--   data-centers              = 3  (Jan 6, 2026: voted with unanimous 6-0 council — Kai recused —
--                                   to rezone ~661 acres for the Beale Infrastructure data center;
--                                   approval conditioned on noise/power/water impact studies; she
--                                   pressed for the town to have final say on noise monitoring)
--   growth-and-development    = 4  (consistent pro-growth voting record: Aug 6, 2025 Linda Vista 52
--                                   annexation for a 212-home development (4-2, Ziegler for) and the
--                                   Jan 2026 ~661-acre data-center rezoning, approved over heavy
--                                   public opposition)
--   local-immigration         = 4  (Feb 2026: declined to have the town oppose the proposed ICE
--                                   detention facility — "We will not be putting forth a resolution,
--                                   a proposition, or any other document" — an accommodating rather
--                                   than resisting posture toward federal immigration detention)
--
-- DELIBERATELY BLANK (no attributable documented Ziegler position found):
--   Local: campaign-finance, city-sanitation, economic-development, homelessness,
--          homelessness-response, housing, local-environment, public-safety-approach,
--          rent-regulation, residential-zoning, taxes, transportation-priorities.
--          (Her defense of taking small campaign contributions "because I am retired" is not a
--          campaign-finance-reform stance; the data-center vote's water/power study conditions do
--          not by themselves establish a general development-vs-environment philosophy; no evidence
--          of an incentives/subsidy position for economic-development.)
--   Non-local federal/state (a town councilmember has no record on these): abortion, ai-regulation,
--          childcare, civil-rights, climate-change, deportation, fossil-fuels, healthcare,
--          immigration, jail-capacity, medicare/aid, misinformation, redistricting,
--          religious-freedom, same-sex-marriage, school-vouchers, social-security, tariffs,
--          trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Roxanne Ziegler / data-centers (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a9bf58b-fd95-4010-81fa-481e1561633d',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a9bf58b-fd95-4010-81fa-481e1561633d',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$On Jan. 6, 2026, after an over-four-and-a-half-hour, emotion-filled public hearing, the Marana Town Council voted 6-0 (Councilmember Herb Kai recused for a conflict of interest) to rezone roughly 661 acres of agricultural land in north Marana for a large data center backed by Beale Infrastructure, the developer behind the Project Blue proposal. As Vice Mayor, Ziegler was part of that unanimous approving vote. The approval was not a no-conditions green light: developers were required to conduct noise studies with a qualified acoustic engineer, demonstrate a sufficient electricity source and assess future energy needs, and estimate annual water consumption and delineate water sourcing before proceeding. Ziegler pushed for more town control during the debate, saying she was frustrated by the noise-monitoring arrangement and that the town should have final say, or at least mutual agreement, on the monitor. Voting to allow the data center subject to noise, power and water impact assessments before approval — while pressing for town oversight rather than a moratorium or a minimal-barriers welcome — maps to allowing data center development with impact assessments and conditions before approval.$$,
        ARRAY['https://www.tucsonspotlight.org/marana-approves-rezoning-for-massive-data-center-project/',
              'https://www.azfamily.com/2026/01/09/two-southern-arizona-data-centers-move-forward-so-do-fights-over-power-water-growth/',
              'https://news.azpm.org/s/102502-marana-data-center-vote-sparks-backlash-three-residents-launch-council-runs/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roxanne Ziegler / growth-and-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a9bf58b-fd95-4010-81fa-481e1561633d',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a9bf58b-fd95-4010-81fa-481e1561633d',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Ziegler's documented voting record consistently favors approving large-scale growth and development, including over significant public opposition. On Aug. 6, 2025 she voted in favor of the Linda Vista 52 annexation — bringing roughly 52 acres north of Linda Vista Boulevard into the town for a large-scale housing development with conceptual plans for 212 single-family homes — in a 4-2 vote (Ziegler, Kai, Murphy and Officer in favor; Cavanaugh and Commerford opposed; Mayor Post recused). On Jan. 6, 2026 she was part of the unanimous 6-0 council vote (Kai recused) to rezone about 661 acres for the Beale Infrastructure data center, approved despite hours of packed opposition over water, power and growth. Repeatedly voting to expand the town's footprint and tax base through annexation and major commercial rezoning — rather than imposing growth caps or slowing approvals until infrastructure catches up — reflects an actively pro-growth, development-recruiting posture.$$,
        ARRAY['https://www.kgun9.com/news/community-inspired-journalism/marana/marana-town-council-approves-linda-vista-52-annexation',
              'https://news.azpm.org/s/102502-marana-data-center-vote-sparks-backlash-three-residents-launch-council-runs/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Roxanne Ziegler / local-immigration (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4a9bf58b-fd95-4010-81fa-481e1561633d',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4a9bf58b-fd95-4010-81fa-481e1561633d',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Amid public pressure for the town to oppose a proposed ICE detention facility (a former private prison in Marana), AZPM reported (Feb. 27, 2026) that Vice Mayor Ziegler told residents the town would not act against it, stating: "We will not be putting forth a resolution, a proposition, or any other document" regarding the detention center. She reiterated the council's decision not to formally intervene despite over an hour of public comment requesting the town's intervention, and declined a constituent meeting on the issue, reading a statement that she didn't think a meeting "would be a good use of our time." Publicly declining to have the town oppose or obstruct a federal immigration detention facility — an accommodating posture toward federal immigration enforcement rather than a resisting or sanctuary stance — best maps to cooperating with / accommodating federal immigration enforcement. (There is no evidence she directed local police to actively assist enforcement, so it is not the most extreme chair.)$$,
        ARRAY['https://news.azpm.org/p/azpmnews/2026/2/27/228667-contract-for-possible-marana-ice-facility-draws-differing-stances-from-town-county-leaders/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
