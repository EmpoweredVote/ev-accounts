import { pool } from '../src/lib/db.js';

const stances = [
  {
    politician_id: '22152e41-31b9-4700-9226-4e274c616f37',
    topic_id: 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
    topic_key: 'abortion',
    reasoning: "Niello voted NO on SB-345 (Health care services: legally protected health care activities — abortion protection bill that expanded legal shields for providers from out-of-state prosecution). As a moderate CA Republican who has not authored abortion restriction legislation, his NO vote reflects opposition to California expanding provider immunity rather than opposition to abortion being legal through the second trimester. This pattern — opposing expanded state protections while not seeking outright bans — is consistent with value 2 (keep abortion legal and accessible through the second trimester with rare exceptions afterward).",
    sources: [
      'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB345',
      'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB345'
    ]
  },
  {
    politician_id: '22152e41-31b9-4700-9226-4e274c616f37',
    topic_id: '44905f3b-e105-4f6c-afc7-5d223813dbac',
    topic_key: 'deportation',
    reasoning: "Niello voted NO on AB-1306 (State government: immigration enforcement — prohibited the CA Department of Corrections from cooperating with ICE deportation holds for inmates eligible for parole). His NO vote indicates he supports ICE cooperation and enforcement for undocumented individuals with criminal records. This aligns with value 4 (deport everyone without legal status starting with those who have criminal records) — specifically supporting law enforcement coordination to enable deportations.",
    sources: [
      'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1306',
      'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1306'
    ]
  },
  {
    politician_id: '22152e41-31b9-4700-9226-4e274c616f37',
    topic_id: 'a22215c3-6693-4bc2-b248-01aebba14570',
    topic_key: 'fossil-fuels',
    reasoning: "Niello voted YES on SB-438 (Carbon Capture program: allowing residual oil production as byproduct of carbon sequestration) and voted NO on AB-1167 (Oil and gas: acquisition: bonding requirements — increased regulatory burden on oil/gas operations). His YES on a bill facilitating continued oil production and NO on oil/gas regulations indicates support for expanding or maintaining fossil fuel operations over restricting them. This aligns with value 4 (expand fossil fuel drilling permits).",
    sources: [
      'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB438',
      'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1167'
    ]
  },
  {
    politician_id: '22152e41-31b9-4700-9226-4e274c616f37',
    topic_id: 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
    topic_key: 'misinformation',
    reasoning: "Niello voted YES on SB-942 (California AI Transparency Act — required AI companies to disclose when content is AI-generated) and NO on AB-2839 (Elections: deceptive media in advertisements — stronger anti-deepfake penalties). His YES on mandatory AI disclosure combined with NO on the more expansive censorship bill reflects support for transparency requirements while opposing government censorship. This matches value 2 (mandate fact-checking and transparency in how algorithms promote content) rather than the more restrictive value 1 or the more permissive value 3-4.",
    sources: [
      'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB942',
      'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2839'
    ]
  },
  {
    politician_id: '22152e41-31b9-4700-9226-4e274c616f37',
    topic_id: 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
    topic_key: 'voting-rights',
    reasoning: "Niello voted YES on AB-16 (Vote by mail ballots: processing — streamlined processing of mail-in ballots submitted with errors or deficiencies). His YES vote on a bill expanding the usability of mail-in ballots indicates support for accessible mail-in voting. This aligns with value 2 (expand early voting periods and make mail-in voting available to all voters without requiring an excuse).",
    sources: [
      'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB16',
      'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB16'
    ]
  },
  {
    politician_id: 'd64c969e-f458-4387-98b5-1e7af8cb42f0',
    topic_id: '666bf03d-81fc-4138-ab15-69ae734c9023',
    topic_key: 'ai-regulation',
    reasoning: "Schiavo voted YES on SB-7 (Employment: automated decision systems — required employers to disclose and regulate AI use in employment decisions with worker protections) and YES on SB-1047 (Safe and Secure Innovation for Frontier AI Models Act — required safety testing and risk disclosure for large AI models). Her YES votes on both bills requiring AI risk disclosure and employer accountability reflect support for holding AI developers responsible when systems cause harm. This aligns with value 3 (require AI developers to disclose risks and be held responsible when their systems cause harm).",
    sources: [
      'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB7',
      'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047'
    ]
  },
  {
    politician_id: 'ff77225c-51f9-4628-acc3-020d40382d05',
    topic_id: '666bf03d-81fc-4138-ab15-69ae734c9023',
    topic_key: 'ai-regulation',
    reasoning: "Zbur voted YES on SB-7 (Employment: automated decision systems — required employers to disclose and regulate AI use in employment decisions with worker protections) and YES on SB-1047 (Safe and Secure Innovation for Frontier AI Models Act — required safety testing and risk disclosure for large AI models). His YES votes on both bills requiring AI risk disclosure and AI safety requirements reflect support for mandatory accountability. This aligns with value 3 (require AI developers to disclose risks and be held responsible when their systems cause harm).",
    sources: [
      'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB7',
      'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047'
    ]
  },
  {
    politician_id: '3c2bfe51-9a53-4992-801b-138a1a8ce9ed',
    topic_id: '666bf03d-81fc-4138-ab15-69ae734c9023',
    topic_key: 'ai-regulation',
    reasoning: "Elhawary voted YES on SB-7 (Employment: automated decision systems — required employers to disclose and regulate AI use in employment decisions and establish worker protections against automated decision systems). As a Democrat representing an Assembly district in Los Angeles, her YES vote on a bill requiring AI accountability in employment contexts reflects support for holding AI systems accountable when they affect workers. This aligns with value 3 (require AI developers to disclose risks and be held responsible when their systems cause harm).",
    sources: [
      'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB7',
      'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB7'
    ]
  }
];

await pool.query('BEGIN');
try {
  for (const s of stances) {
    await pool.query(`
      INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (politician_id, topic_id)
      DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources
    `, [s.politician_id, s.topic_id, s.reasoning, s.sources]);
    console.log('Upserted:', s.politician_id, s.topic_key);
  }
  await pool.query('COMMIT');
  console.log('Done: ' + stances.length + ' context rows upserted');
} catch (err) {
  await pool.query('ROLLBACK');
  console.error('Rolled back:', err.message);
  process.exit(1);
}
await pool.end();
