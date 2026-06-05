import { pool } from '../src/lib/db.js';

const politician_id = 'd2358e54-6860-4382-8c8d-95a3dabea874';

const stances = [
  {
    topic_key: 'residential-zoning',
    topic_id: 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
    value: 4,
    reasoning: 'As Housing Committee chair Azeem pushed for six-story zoning citywide and authored legislation eliminating all parking minimums — making Cambridge the first Massachusetts city to do so. The final February 2025 ordinance passed 8-1 with a four-story base and six-story allowance on larger parcels; Azeem co-authored an op-ed arguing design review slows housing and that most of the buildings cherished in Cambridge were built before design review was added in the 1970s. This reflects a strong pro-density upzoning position with streamlined approvals.',
    sources: [
      'https://www.cambridgeday.com/2025/09/30/we-compromised-on-zoning-reform-because-it-was-better-for-cambridge/',
      'https://www.cambridgeday.com/2025/10/30/cambridge-city-council-election-guide-2025/',
    ],
  },
  {
    topic_key: 'growth-and-development',
    topic_id: 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
    value: 4,
    reasoning: 'Azeem co-chairs the Housing and Finance committees leading efforts on residential development enhancements including tax incentives, public equity financing and reduced fees and requirements. He authored the elimination of parking minimums citywide and pushed for six-story base zoning (accepting four-story as a compromise). His stated goal is to build more greener housing and he frames streamlined permitting and reduced requirements as core tools.',
    sources: [
      'https://www.cambridgeday.com/2025/11/27/attend-cambridge-meetings-from-nov-27-dec-4-on-development-incentives-and-brattle-bike-lanes/',
      'https://www.cambridgeday.com/2025/09/30/we-compromised-on-zoning-reform-because-it-was-better-for-cambridge/',
      'https://www.cambridgeday.com/2025/10/30/cambridge-city-council-election-guide-2025/',
    ],
  },
  {
    topic_key: 'rent-regulation',
    topic_id: 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
    value: 3,
    reasoning: 'Azeem explicitly pairs his pro-development stance with tenant protections to prevent displacement from new development but his primary tool is supply expansion rather than rent control. The 2025 election guide notes he advocates for housing security through transit-oriented housing paired with tenant protections — suggesting maintenance of existing protections for current tenants while allowing market rents on new construction.',
    sources: [
      'https://www.cambridgeday.com/2025/10/30/cambridge-city-council-election-guide-2025/',
      'https://www.cambridgeday.com/2025/09/30/we-compromised-on-zoning-reform-because-it-was-better-for-cambridge/',
    ],
  },
  {
    topic_key: 'local-environment',
    topic_id: '1935979c-b290-42e4-baa5-8cb0138b4ffa',
    value: 3,
    reasoning: 'Azeem advocates for net-zero housing construction and transit-oriented development reflecting consistent environmental standards applied to new housing. He supports broad upzoning without requiring developers to fully offset environmental impact — his zoning reform op-ed focuses on urgency of housing production and design flexibility not environmental preservation requirements. This aligns with applying consistent standards while giving developers reasonable implementation flexibility.',
    sources: [
      'https://www.cambridgeday.com/2025/09/30/we-compromised-on-zoning-reform-because-it-was-better-for-cambridge/',
      'https://www.cambridgeday.com/2025/10/30/cambridge-city-council-election-guide-2025/',
    ],
  },
  {
    topic_key: 'transportation-priorities',
    topic_id: 'ba59337e-30e2-4aba-a39a-426b3366eb27',
    value: 1,
    reasoning: 'Azeem earned bike champion status from Cambridge Bicycle Safety and pledged to complete the Cycling Safety Ordinance. He voted Nay in 2025 against eliminating bike lanes on Garden Street for two-way car traffic then voted in the 5-4 majority in 2026 to restore the one-way/bike-lane configuration. He authored legislation eliminating all parking minimums citywide and advocates for MBTA board representation to improve public transit.',
    sources: [
      'https://www.cambridgeday.com/2026/04/29/garden-street-tight-vote/',
      'https://www.cambridgeday.com/2026/04/16/garden-street-development/',
      'https://www.cambridgeday.com/2025/10/30/cambridge-city-council-election-guide-2025/',
    ],
  },
  {
    topic_key: 'homelessness-response',
    topic_id: '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
    value: 2,
    reasoning: "Cambridge's overall shelter and services approach aligns with expanding outreach as the primary strategy. No direct votes or statements from Azeem specifically on criminalization vs. housing-first approaches were found but his housing-security framing and consistent alignment with Cambridge progressive majority (which prioritizes services before enforcement) place him at stance 2. His 2019 campaign positions also emphasized services and legal support for vulnerable residents.",
    sources: [
      'https://www.cambridgeday.com/2025/10/30/cambridge-city-council-election-guide-2025/',
    ],
  },
  {
    topic_key: 'public-safety-approach',
    topic_id: 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
    value: 3,
    reasoning: 'In February 2025 Azeem voted with the 6-3 majority to approve police license plate readers and a phone hacker while the progressive bloc (Nolan, Sobrinho-Wheeler, Siddiqui) voted no. He acknowledged the technology feels chilling to Cambridge undocumented and protest communities but voted yes. He used his vice-mayoral charter right to delay (not kill) the ShotSpotter vote. He does not advocate for redirecting police budgets and his approach reflects maintaining current public safety funding with limited tech tools — not defunding or major expansion.',
    sources: [
      'https://www.cambridgeday.com/2025/02/04/fears-of-increasingly-totalitarian-government-cited-when-cambridge-police-ask-for-more-tech/',
      'https://www.cambridgeday.com/2026/05/13/shotspotter-vote-strong-feelings/',
    ],
  },
  {
    topic_key: 'economic-development',
    topic_id: 'eb3d1247-0de1-4b7f-baec-7259861efd53',
    value: 3,
    reasoning: 'Azeem co-chairs the Housing and Finance committees pursuing residential development enhancements including tax incentives and public equity financing specifically tied to housing production goals. His economic development focus is on targeted incentives tied to housing production with inclusionary zoning requirements — not broad corporate subsidies or maximum incentives for any employer. This aligns with stance 3: targeted incentives for specific purposes with community benefit requirements.',
    sources: [
      'https://www.cambridgeday.com/2025/11/27/attend-cambridge-meetings-from-nov-27-dec-4-on-development-incentives-and-brattle-bike-lanes/',
      'https://www.cambridgeday.com/2025/10/30/cambridge-city-council-election-guide-2025/',
    ],
  },
  {
    topic_key: 'local-immigration',
    topic_id: 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
    value: 1,
    reasoning: 'In his 2019 campaign Azeem stated he would have voted to provide legal counsel to undocumented immigrants in Cambridge. Cambridge is a declared sanctuary city that refuses ICE detainers and Azeem has been a consistent supporter. He raised concerns about how police surveillance tech affects Cambridge undocumented residents stating he can understand why that feels chilling to people given the undocumented population.',
    sources: [
      'https://www.cambridgeday.com/2025/02/04/fears-of-increasingly-totalitarian-government-cited-when-cambridge-police-ask-for-more-tech/',
      'https://www.cambridgeday.com/2025/05/30/cambridge-and-somerville-are-named-on-list-identifying-sanctuary-jurisdictions-by-feds/',
    ],
  },
  {
    topic_key: 'housing',
    topic_id: '669cac97-66a6-4087-b036-936fbe62efb3',
    value: 3,
    reasoning: 'Azeem advocates for supply-side solutions to the housing crisis: upzoning, eliminating parking minimums, streamlined permitting, and housing-linked tax incentives. He calls for transit-oriented housing with tenant protections to prevent displacement and inclusionary affordable unit requirements for larger developments. His approach centers on regulatory reform to enable private development with affordability conditions — targeted help and easier permitting rather than direct public housing or pure market laissez-faire.',
    sources: [
      'https://www.cambridgeday.com/2025/10/30/cambridge-city-council-election-guide-2025/',
      'https://www.cambridgeday.com/2025/09/30/we-compromised-on-zoning-reform-because-it-was-better-for-cambridge/',
      'https://www.cambridgeday.com/2025/11/27/attend-cambridge-meetings-from-nov-27-dec-4-on-development-incentives-and-brattle-bike-lanes/',
    ],
  },
  {
    topic_key: 'civil-rights',
    topic_id: '0bc588c6-39e1-4084-b5de-cac909b8b762',
    value: 2,
    reasoning: 'Azeem voted unanimously with the full council to pass the cease-fire resolution in January 2024 and supported language calling military action disproportionate, framing it as accurate and factual. His 2019 campaign included support for undocumented immigrant legal services and his housing work explicitly addresses displacement of lower-income communities. No race-based reparations or specific racial equity mandates are documented, placing him at stance 2: strengthening civil rights enforcement and addressing systemic discrimination.',
    sources: [
      'https://www.cambridgeday.com/2024/01/30/cease-fire-resolution-is-approved-in-cambridge-protesters-police-are-biggest-city-hall-presences/',
      'https://www.cambridgeday.com/2025/10/30/cambridge-city-council-election-guide-2025/',
    ],
  },
];

for (const s of stances) {
  await pool.query(
    `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
     VALUES ($1, $2, $3)
     ON CONFLICT (politician_id, topic_id)
     DO UPDATE SET value = EXCLUDED.value`,
    [politician_id, s.topic_id, s.value]
  );

  await pool.query(
    `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (politician_id, topic_id)
     DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
    [politician_id, s.topic_id, s.reasoning, s.sources]
  );

  console.log(`OK: ${s.topic_key} = ${s.value}`);
}

console.log(`\nDone: ${stances.length} stances upserted for Burhan Azeem`);
await pool.end();
