import { pool } from '../src/lib/db.js';

const politician_id = 'cc61015f-dba2-4f52-9f1f-832ef23f6595';

const stances = [
  {
    topic_key: 'housing',
    topic_id: '669cac97-66a6-4087-b036-936fbe62efb3',
    value: 2,
    reasoning: 'As mayor, Siddiqui preserved over 500 affordable units at Fresh Pond Apartments and voted for increased affordable housing requirements in the 2019 East Cambridge Courthouse development deal. She launched Cambridge RISE and Rise Up Cambridge, providing $500/month payments to nearly 2,000 low-income families, demonstrating a government-led approach to economic stability. These actions place her at stance 2: using subsidies, rent protection (tougher condo conversion law), and public affordable housing expansion.',
    sources: [
      'https://en.wikipedia.org/wiki/Sumbul_Siddiqui',
      'https://www.cambridgeday.com/2021/06/27/attend-meetings-on-a-condo-conversion-law-after-school-programs-harvard-dining-more/',
      'https://www.cambridgeday.com/2025/04/28/cambridge-leaders-weigh-reviving-cash-program-for-lower-income-families-in-the-next-fiscal-year/',
    ],
  },
  {
    topic_key: 'rent-regulation',
    topic_id: 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
    value: 2,
    reasoning: 'Siddiqui led the effort to enact a tougher condominium conversion law as mayor in 2021 — a direct anti-displacement/tenant-protection measure. She also championed housing preservation (Fresh Pond Apartments, 500+ units) and supported rent assistance exploration. Her record aligns with strengthening existing tenant protections and extending coverage, not full rent control of all units but going beyond merely maintaining the status quo.',
    sources: [
      'https://www.cambridgeday.com/2021/06/27/attend-meetings-on-a-condo-conversion-law-after-school-programs-harvard-dining-more/',
      'https://en.wikipedia.org/wiki/Sumbul_Siddiqui',
    ],
  },
  {
    topic_key: 'residential-zoning',
    topic_id: 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
    value: 3,
    reasoning: 'Siddiqui received endorsements from both A Better Cambridge (pro-density YIMBY group) and the Cambridge Residents Alliance (neighborhood-character-focused group), suggesting a middle-of-the-road position on density. She supported the East Cambridge Courthouse development with affordable housing conditions, and Cambridge eliminated parking minimums under her tenure. Her record supports multifamily and affordable housing near commercial corridors while maintaining neighborhood input rather than blanket upzoning.',
    sources: [
      'https://www.cambridgeday.com/2023/09/29/group-endorsements-for-cambridge-city-council-have-few-points-of-overlap-as-housing-stays-key/',
      'https://en.wikipedia.org/wiki/Sumbul_Siddiqui',
    ],
  },
  {
    topic_key: 'growth-and-development',
    topic_id: 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
    value: 3,
    reasoning: 'Siddiqui backed major development projects that included affordable housing conditions (the East Cambridge Courthouse project, Foundry community building) while insisting on community benefit requirements. Cambridge continued to grow substantially during her mayoral tenure. She did not oppose development but consistently demanded affordable housing set-asides and community benefits, aligning with proactive infrastructure investment over either growth limits or pure market-led development.',
    sources: [
      'https://en.wikipedia.org/wiki/Sumbul_Siddiqui',
      'https://www.cambridgeday.com/2023/09/29/group-endorsements-for-cambridge-city-council-have-few-points-of-overlap-as-housing-stays-key/',
    ],
  },
  {
    topic_key: 'local-environment',
    topic_id: '1935979c-b290-42e4-baa5-8cb0138b4ffa',
    value: 2,
    reasoning: 'Siddiqui co-submitted a July 2021 policy order with Councillors Nolan and Zondervan to redefine trees as essential infrastructure and require city reporting on any project affecting tree canopy. She also appointed a Climate Crisis Working Group in 2022 that issued formal recommendations. These actions reflect a stance of strictly protecting existing parks and tree canopy and requiring environmental offsets, aligning with stance 2.',
    sources: [
      'https://www.cambridgeday.com/2021/07/30/rally-for-cambridge-trees-takes-place-monday-before-an-order-to-strengthen-the-citys-canopy/',
      'https://en.wikipedia.org/wiki/Sumbul_Siddiqui',
    ],
  },
  {
    topic_key: 'transportation-priorities',
    topic_id: 'ba59337e-30e2-4aba-a39a-426b3366eb27',
    value: 2,
    reasoning: 'Siddiqui organized annual Bike Bonanza events encouraging use of protected bike lanes. Cambridge eliminated parking minimums during her mayoral term. She co-sponsored the MBTA bench-bar order criticizing hostile architecture targeting unhoused people at T stops, showing concern for pedestrian/transit-user welfare. These actions reflect equal investment in roads and multimodal options with explicit bike and pedestrian infrastructure support.',
    sources: [
      'https://en.wikipedia.org/wiki/Sumbul_Siddiqui',
      'https://www.cambridgeday.com/2021/01/12/bench-bars-at-cambridge-t-stops-draw-criticism-as-hostile-architecture-aimed-at-the-homeless/',
    ],
  },
  {
    topic_key: 'homelessness-response',
    topic_id: '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
    value: 2,
    reasoning: 'Siddiqui appointed an ad hoc working group in May 2021 specifically to advocate for non-congregate shelter models over traditional mass shelters, reflecting a preference for individualized services and housing-focused approaches. She also co-launched the Unhoused Neighbors Project connecting residents with services. This aligns with stance 2: expanding shelter capacity and services as the primary strategy, with enforcement only after services are offered.',
    sources: [
      'https://en.wikipedia.org/wiki/Sumbul_Siddiqui',
      'https://www.cambridgeday.com/2022/11/29/in-handling-homelessness-and-substance-abuse-foundation-exists-for-easing-the-crisis-staff-says/',
    ],
  },
  {
    topic_key: 'public-safety-approach',
    topic_id: 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
    value: 2,
    reasoning: 'In February 2025, Siddiqui voted against a 6-3 council vote approving police license plate readers and phone hacker surveillance technology, siding with civil liberties concerns. She also questioned excessive police budget expenditures (the $570,000 gun purchase). Her approach favors maintaining core police staffing while shifting some resources to non-violent/social approaches, aligning with stance 2.',
    sources: [
      'https://www.cambridgeday.com/2025/02/04/fears-of-increasingly-totalitarian-government-cited-when-cambridge-police-ask-for-more-tech/',
      'https://www.cambridgeday.com/2025/03/30/answers-expected-on-police-request-for-new-guns-are-delayed-again-until-mondays-council-meeting/',
      'https://www.cambridgeday.com/2021/01/12/bench-bars-at-cambridge-t-stops-draw-criticism-as-hostile-architecture-aimed-at-the-homeless/',
    ],
  },
  {
    topic_key: 'economic-development',
    topic_id: 'eb3d1247-0de1-4b7f-baec-7259861efd53',
    value: 2,
    reasoning: 'Siddiqui launched Cambridge RISE (2021, 130 families, $500/month) and Rise Up Cambridge (2023, ~2,000 families) as direct guaranteed-income programs rather than corporate tax incentives. Her prior career was providing free legal services to small businesses and entrepreneurs. She co-authored an op-ed supporting a Black-owned cannabis dispensary in Harvard Square, reflecting support for local and minority-owned small businesses rather than large corporate subsidies.',
    sources: [
      'https://en.wikipedia.org/wiki/Sumbul_Siddiqui',
      'https://commonwealthbeacon.org/opinion/support-black-owned-cannabis-shop-in-harvard-square/',
      'https://www.cambridgeday.com/2025/04/28/cambridge-leaders-weigh-reviving-cash-program-for-lower-income-families-in-the-next-fiscal-year/',
    ],
  },
  {
    topic_key: 'local-immigration',
    topic_id: 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
    value: 1,
    reasoning: "Cambridge is a declared sanctuary city with a Commission on Immigrant Rights & Citizenship. Siddiqui served as mayor from January 2021 through January 2024, during which she presided over and supported Cambridge's full sanctuary policy — refusing ICE detainers and prohibiting city employees from sharing immigration status. In January 2025, when Cambridge was named a sanctuary jurisdiction by the Trump administration, city officials reaffirmed this policy, consistent with Siddiqui's prior leadership position.",
    sources: [
      'https://www.cambridgeday.com/2025/05/30/cambridge-and-somerville-are-named-on-list-identifying-sanctuary-jurisdictions-by-feds/',
      'https://www.cambridgeday.com/2025/02/03/know-your-rights-trainings-draw-hundreds-worried-over-trump-attacks-on-immigrants/',
      'https://en.wikipedia.org/wiki/Sumbul_Siddiqui',
    ],
  },
  {
    topic_key: 'civil-rights',
    topic_id: '0bc588c6-39e1-4084-b5de-cac909b8b762',
    value: 2,
    reasoning: 'Siddiqui launched Cambridge RISE and Rise Up Cambridge as targeted economic equity programs disproportionately benefiting families of color. She co-sponsored the cease-fire resolution in January 2024, voted against adding divisive language and called for inclusive peace-building language. These align with stance 2: strengthening civil rights enforcement and addressing systemic discrimination.',
    sources: [
      'https://www.cambridgeday.com/2024/01/30/cease-fire-resolution-is-approved-in-cambridge-protesters-police-are-biggest-city-hall-presences/',
      'https://en.wikipedia.org/wiki/Sumbul_Siddiqui',
      'https://www.cambridgeday.com/2024/05/31/more-details-emerge-on-gunfire-at-donnelly-field-and-themes-for-debate-less-police-more-cameras/',
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

console.log(`\nDone: ${stances.length} stances upserted for Sumbul Siddiqui`);
await pool.end();
