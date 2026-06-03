-- Correction migration for Jeff Gonzalez (politician_id: 5ad32852-789e-4013-995b-6f0aa6a5a5d4)
-- CA Assembly Member, Assembly District 36 (Riverside/Imperial County)
-- Source date: 2026-06-02 (research from batch-A CSV)
-- Corrections: 10 topics updated from original values (many at 1-2) to researched values (2-4)
-- Topics corrected: climate-change, fossil-fuels, campaign-finance, ai-regulation,
--   data-centers, taxes, healthcare, housing, immigration, voting-rights

BEGIN;

-- climate-change: value corrected to 4 (12% CEV score, voted NO on multiple pro-environment bills)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '5ad32852-789e-4013-995b-6f0aa6a5a5d4'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5ad32852-789e-4013-995b-6f0aa6a5a5d4',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Gonzalez earned a 12% lifetime environmental score from California Environmental Voters (CEV) in 2025 and abstained or voted NO on nearly every pro-environment bill scored by CEV: NO on AB-1319 (California Endangered Species Act), NO on AB-263 (Scott and Shasta River Instream Flows), abstained (scored anti-environment) on AB-39 (Local Electrification Planning Act), NO on SB-682 (banning PFAS/forever chemicals), NO on SB-541 (clean energy load shifting). He also accepted oil industry money. His site lists ''lower the cost of living'' as a key mission rather than climate action. This pattern fits value 4 (let market forces drive any transition) rather than value 5 because he did author AB-2163 to leverage Lithium Valley for energy, indicating he does not fully reject clean energy — but his overall record is market-driven on climate.',
  ARRAY['https://action.ecovote.org/scorecard/representative/jeff-gonzalez/', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB1319', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB682']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- fossil-fuels: value corrected to 4 (voted NO on AB-1448 coastal sanctuary bill, accepted oil money)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '5ad32852-789e-4013-995b-6f0aa6a5a5d4'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5ad32852-789e-4013-995b-6f0aa6a5a5d4',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Gonzalez voted NO on AB-1448 (2025), which would have protected the California Coastal Sanctuary from expanded oil and gas development on tidelands and submerged lands. The bill''s digest states it amends the California Coastal Sanctuary to restrict expanded tidelands oil and gas development. Gonzalez also accepted oil industry money per CEV''s 2025 scorecard. A NO vote on protecting against expanded offshore oil drilling aligns with value 4 (expand fossil fuel drilling permits).',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB1448', 'https://action.ecovote.org/scorecard/representative/jeff-gonzalez/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- campaign-finance: value corrected to 4 (voted NO on SB-42 public campaign financing)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '5ad32852-789e-4013-995b-6f0aa6a5a5d4'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5ad32852-789e-4013-995b-6f0aa6a5a5d4',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Gonzalez voted NO on SB-42 (2025), the California Fair Elections Act of 2026, authored by Umberg. The bill would have established public campaign financing for state elections under the Political Reform Act. A NO vote on public campaign financing aligns with value 4 (reduce restrictions on political donations and spending) rather than value 5 because Gonzalez has not publicly advocated eliminating all campaign finance laws.',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB42', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB42']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- ai-regulation: value corrected to 2 (voted NO on SB-7 mandatory employer AI disclosure)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '5ad32852-789e-4013-995b-6f0aa6a5a5d4'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ai-regulation');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5ad32852-789e-4013-995b-6f0aa6a5a5d4',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'ai-regulation'),
  'Gonzalez voted NO on SB-7 (2025), authored by McNerney, which would have required employers to inventory and disclose all high-risk automated decision systems to the California Labor and Workforce Development Agency and established protections for workers affected by automated decision systems in employment. This is a vote against mandatory disclosure and regulation of AI in employment settings. However, Gonzalez''s own press release from May 28 2026 states he voted FOR transparency legislation around AI and data centers, stating he wants communities to be ''fully informed'' about impacts. This combination — opposing mandatory employer AI disclosure while supporting community transparency rules — fits value 2 (suggest AI safety guidelines but let companies choose whether to follow them).',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB7', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB7', 'https://ad36.asmrc.org/2026/05/28/el-asambleista-jeff-gonzalez-apoya-medidas-de-transparencia-y-rendicion-de-cuentas-para-los-centros-de-datos/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- data-centers: value corrected to 3 (authored data center transparency legislation)
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '5ad32852-789e-4013-995b-6f0aa6a5a5d4'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'data-centers');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5ad32852-789e-4013-995b-6f0aa6a5a5d4',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'data-centers'),
  'Gonzalez''s May 28 2026 press release states he voted for legislation ''increasing transparency and oversight around the rapid expansion of artificial intelligence and data center development across California.'' He cited community concerns about public health, infrastructure, energy consumption, water use, and local taxpayer impacts. He stated: ''I support responsible economic development, but we also have a duty to ensure our communities are protected and fully informed.'' This is a balance between allowing development with accountability requirements, fitting value 3 (allowing data center development with impact assessments, energy cost-sharing agreements, and community benefit requirements before approval).',
  ARRAY['https://ad36.asmrc.org/2026/05/28/el-asambleista-jeff-gonzalez-apoya-medidas-de-transparencia-y-rendicion-de-cuentas-para-los-centros-de-datos/', 'https://ad36.asmrc.org/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- taxes: value corrected to 4 (voted NO on Budget Act of 2025, fiscal conservative)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '5ad32852-789e-4013-995b-6f0aa6a5a5d4'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5ad32852-789e-4013-995b-6f0aa6a5a5d4',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Gonzalez voted NO on AB-218, the Budget Act of 2025, as introduced. He is a fiscal conservative Republican whose stated mission is to ''lower the cost of living'' in California. His campaign platform emphasizes reducing red tape and government costs for small businesses. Voting against the state budget — which includes tax-and-spend programs — aligns with value 4 (cut taxes for everyone and scale back public services to match). He did vote YES on AB-108 for hospital grants funded by existing state programs, but his overall fiscal pattern is conservative.',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB218', 'https://ad36.asmrc.org/biography/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- healthcare: value corrected to 3 (voted YES on AB-108 distressed hospital grants, supports rural access)
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '5ad32852-789e-4013-995b-6f0aa6a5a5d4'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5ad32852-789e-4013-995b-6f0aa6a5a5d4',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Gonzalez voted YES on AB-108, the Distressed Hospital Small Grant Program, which provides one-time emergency grants to rural and underserved hospitals. In his May 29 2026 press release announcing hospital grants for Palo Verde Hospital ($3M) and El Centro Regional Medical Center ($11M), Gonzalez stated: ''Healthcare access is not optional, especially in rural communities like ours.'' His biography states his mission includes ''increase access to healthcare.'' He supports targeted government assistance for hospitals serving the poorest communities while his opposition to the Budget Act and support for market-based solutions indicates he does not favor universal government-run healthcare. This fits value 3 (help people who can''t afford care and expand programs for seniors and low-income residents, while keeping private insurance for everyone else).',
  ARRAY['https://ad36.asmrc.org/2026/05/29/assemblyman-jeff-gonzalez-applauds-distressed-hospital-grant-awards-for-palo-verde-hospital-and-el-centro-regional-medical-center/', 'https://ad36.asmrc.org/biography/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- housing: value corrected to 4 (NVR on SB-79 transit-oriented development, supports deregulation)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '5ad32852-789e-4013-995b-6f0aa6a5a5d4'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5ad32852-789e-4013-995b-6f0aa6a5a5d4',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Gonzalez voted NVR (not voting/absent) on SB-79 (2025), the Transit-Oriented Development bill by Wiener that would allow higher-density housing near transit stops and override local zoning — a top progressive housing bill. He voted YES on AB-1308, the Housing Accountability Act streamlining inspection requirements for private residential developers. As a small business owner representing a district with significant rural communities, his pattern of supporting deregulation while abstaining on government-mandated upzoning fits value 4 (cut regulations and zoning rules so private developers can build more housing).',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB79', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB1308']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- immigration: value corrected to 3 (voted YES on AB-450 immigrant services, pragmatic district rep)
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '5ad32852-789e-4013-995b-6f0aa6a5a5d4'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5ad32852-789e-4013-995b-6f0aa6a5a5d4',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Gonzalez represents Assembly District 36, which covers eastern Riverside County and Imperial County and includes a large Latino population and proximity to the US-Mexico border. He voted YES on AB-450 (2025), providing public social services support for older and aging immigrants — a bill expanding public services to immigrants. His district''s demographic composition and his biography''s emphasis on serving underserved communities suggest a more pragmatic position on immigration than the most restrictive stance, but no evidence of supporting expanded legal immigration channels was found. His vote pattern (YES on immigrant services, no direct anti-immigration votes documented) fits value 3 (keep immigration levels and rules about where they are now).',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB450', 'https://ad36.asmrc.org/biography/', 'https://en.wikipedia.org/wiki/Jeff_Gonzalez']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- voting-rights: value corrected to 3 (voted YES on AB-16 bipartisan vote-by-mail efficiency bill)
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '5ad32852-789e-4013-995b-6f0aa6a5a5d4'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '5ad32852-789e-4013-995b-6f0aa6a5a5d4',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Gonzalez voted YES on AB-16 (2025), authored by Republican Assemblymember Alanis. AB-16 authorizes elections officials to begin processing vote by mail ballot return envelopes and ballots on the date ballots are mailed — earlier than the current 29-day-before-election threshold. This is a technical election administration bill that passed with bipartisan support to improve election efficiency. A YES vote indicates Gonzalez supports maintaining vote by mail as a system (not eliminating it), which fits value 3 (standardize voter ID requirements while ensuring free IDs are available to all eligible citizens) as the middle position — he does not support eliminating vote by mail, but there is no evidence he supports automatic universal voter registration (value 1) or mandatory photo ID with elimination of mail voting (value 5).',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB16', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB16']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

COMMIT;
