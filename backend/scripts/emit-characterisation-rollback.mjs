#!/usr/bin/env node
/**
 * Write the rollback record for the characterisation-row remedies (migrations 1522-1524).
 *
 * 🔴 THIS FILE IS THE ONLY SURVIVING COPY of the retired rows' value, reasoning and sources once
 * 1522 runs. Generated from the database rather than transcribed by hand, for the same reason the
 * quote-correction tools re-fetch instead of trusting a note: a hand-copied rollback that is subtly
 * wrong is worse than none, because it looks restorable.
 *
 * Usage (from backend/):  node scripts/emit-characterisation-rollback.mjs --out <path>
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { Pool } from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-01-characterisation-remedies-rollback.json');

// Second set: the 8 rows resolved by working the calibrated reading queue (1525/1526).
// Kept in the SAME tool rather than a copy, so the "refuse to write a short record" guard and the
// answers-before/after impact report cannot drift between the two passes.
const QUEUE_ROWS = [
  // ---- RETIRE (6)
  ['09d9691d-0352-45c0-9efd-31c38b69c302', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 'retire'], // Anderson / Public Safety
  ['09d9691d-0352-45c0-9efd-31c38b69c302', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 'retire'], // Anderson / Transportation
  ['09d9691d-0352-45c0-9efd-31c38b69c302', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 'retire'], // Anderson / Sanitation
  ['63d60b50-2395-4cde-8999-97a9166d3563', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 'retire'], // Catten / Taxes
  ['fee24b69-dd56-4b07-a890-a08e898dc031', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'retire'], // Wiley / Healthcare
  ['f1f3e6ca-5532-4f33-8ec2-64791b08f59b', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 'retire'], // Solis / Residential Zoning
  // ---- REASONING (2)
  ['13eea214-867a-4a66-ae1a-c0f9916ac833', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 'reasoning'], // Calanche / Transportation
  ['372a7e8f-5f5f-4ac0-939d-3d2ca9fee97a', 'a22215c3-6693-4bc2-b248-01aebba14570', 'reasoning'], // Kopp / Fossil Fuels
];

// (politician_id, topic_id, remedy) — the 25 rows the review resolved as non-keep.
const CHARACTERISATION_ROWS = [
  // ---- RETIRE (12): the topic itself is absent from the cited site, verified against raw HTML
  ['d2ff9bbf-4434-4b81-a869-e3241e954e3c', 'a22215c3-6693-4bc2-b248-01aebba14570', 'retire'], // Kirkland / Fossil Fuels
  ['d2ff9bbf-4434-4b81-a869-e3241e954e3c', '669cac97-66a6-4087-b036-936fbe62efb3', 'retire'], // Kirkland / Housing
  ['d2ff9bbf-4434-4b81-a869-e3241e954e3c', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'retire'], // Kirkland / Healthcare
  ['d2ff9bbf-4434-4b81-a869-e3241e954e3c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 'retire'], // Kirkland / Taxes
  ['0dc7e2da-505d-42b6-af05-a2105ce81379', '44905f3b-e105-4f6c-afc7-5d223813dbac', 'retire'], // Fairly / Deportation
  ['0dc7e2da-505d-42b6-af05-a2105ce81379', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 'retire'], // Fairly / Trans Athletes
  ['b266c38d-9763-48d4-bcba-7b44adf79ab9', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 'retire'], // Hopper / Trans Athletes
  ['44d86767-7041-4ce9-9d03-ce23dd663c95', '44905f3b-e105-4f6c-afc7-5d223813dbac', 'retire'], // Craddick / Deportation
  ['c63201eb-c3e1-4bcd-b24a-995e9d367fc3', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 'retire'], // Lancia / Immigration
  ['786ac925-59d3-40e3-a9ce-b63a54f4caf4', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 'retire'], // LaHood / Religious Freedom
  ['e9cd8a4e-9e2b-4962-be21-7a2f68a650ba', '669cac97-66a6-4087-b036-936fbe62efb3', 'retire'], // Hernandez / Housing
  ['9a171371-be83-456e-acd5-ece936ee84ae', '669cac97-66a6-4087-b036-936fbe62efb3', 'retire'], // Benson / Housing
  ['786ac925-59d3-40e3-a9ce-b63a54f4caf4', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 'retire'], // LaHood / Immigration
  // ---- CHAIR (3): topic is on the page, but the page supports a different chair
  ['4782f3f1-c940-47ad-a3ab-a753b8cd719a', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'chair'],  // Welford / Healthcare 1->2
  ['90d94c32-12a1-433a-8ab4-418cd2f05c01', 'a22215c3-6693-4bc2-b248-01aebba14570', 'chair'],  // Landgraf / Fossil Fuels 5->4
  ['31e72d49-a541-4855-9262-4f5c4abf7b18', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'chair'],  // Tandon / Childcare 4->3
  // ---- REASONING (10): row and chair stand; an unsourced specific comes out
  ['2f570d90-c1e2-45bd-811c-243e92884235', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 'reasoning'], // Nagel / Taxes
  ['0dc7e2da-505d-42b6-af05-a2105ce81379', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 'reasoning'], // Fairly / Religious Freedom
  ['b266c38d-9763-48d4-bcba-7b44adf79ab9', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 'reasoning'], // Hopper / Religious Freedom
  ['e9cd8a4e-9e2b-4962-be21-7a2f68a650ba', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'reasoning'], // Hernandez / Childcare
  ['5604c5ae-d10d-4ca3-920d-dd3592278777', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 'reasoning'], // Negrete / Public Safety
  ['90d94c32-12a1-433a-8ab4-418cd2f05c01', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'reasoning'], // Landgraf / Climate Change
  ['d0977350-df68-4cfe-822e-816ba13f9213', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 'reasoning'], // Park / Immigration
  ['ca2ff1d9-8ebe-4cf2-a804-27d73c58340b', '00b95a6a-75db-4521-b523-3326bba938de', 'reasoning'], // Santos / School Vouchers
  ['372a7e8f-5f5f-4ac0-939d-3d2ca9fee97a', '00b95a6a-75db-4521-b523-3326bba938de', 'reasoning'], // Kopp / School Vouchers
];

const SET = flag('--set', 'characterisation');
const ROWS = SET === 'queue' ? QUEUE_ROWS : CHARACTERISATION_ROWS;

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

(async () => {
  if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }
  const { rows } = await pool.query(
    `SELECT p.id::text AS politician_id, p.full_name, p.last_stances_researched_at,
            t.id::text AS topic_id, t.short_title AS topic,
            a.value, c.reasoning, c.sources
       FROM inform.politician_answers a
       JOIN essentials.politicians p ON p.id = a.politician_id
       JOIN inform.compass_topics t ON t.id = a.topic_id
       LEFT JOIN inform.politician_context c
              ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
      WHERE (a.politician_id::text, a.topic_id::text) IN (
              SELECT * FROM unnest($1::text[], $2::text[]))`,
    [ROWS.map((r) => r[0]), ROWS.map((r) => r[1])],
  );

  const remedy = new Map(ROWS.map(([p, t, r]) => [`${p}|${t}`, r]));
  const out = rows.map((r) => ({ ...r, remedy: remedy.get(`${r.politician_id}|${r.topic_id}`) }));

  // 🔴 A SHORT ROLLBACK IS A SILENT DATA LOSS. If a row did not come back, the record cannot restore
  // it, so refuse to write rather than emit a file that looks complete.
  if (out.length !== ROWS.length) {
    console.error(`FAIL: expected ${ROWS.length} rows, matched ${out.length} — refusing to write`);
    const got = new Set(out.map((r) => `${r.politician_id}|${r.topic_id}`));
    for (const [p, t, r] of ROWS) if (!got.has(`${p}|${t}`)) console.error(`  missing (${r}): ${p} / ${t}`);
    await pool.end();
    process.exit(2);
  }

  // Answer counts before/after, so the 1494 rule can be checked rather than assumed.
  const pids = [...new Set(ROWS.filter((r) => r[2] === 'retire').map((r) => r[0]))];
  const { rows: counts } = await pool.query(
    `SELECT p.id::text AS politician_id, p.full_name,
            p.last_stances_researched_at IS NOT NULL AS research_ts_set,
            count(a.*)::int AS answers_now
       FROM essentials.politicians p JOIN inform.politician_answers a ON a.politician_id = p.id
      WHERE p.id = ANY($1::uuid[]) GROUP BY p.id, p.full_name`, [pids],
  );
  const retiring = new Map();
  for (const [p, , r] of ROWS) if (r === 'retire') retiring.set(p, (retiring.get(p) ?? 0) + 1);
  const impact = counts.map((c) => ({
    ...c, retiring: retiring.get(c.politician_id), answers_after: c.answers_now - retiring.get(c.politician_id),
  })).sort((a, b) => a.answers_after - b.answers_after);

  await pool.end();
  writeFileSync(OUT, `${JSON.stringify({ generated_for: '1522/1523/1524', rows: out, impact }, null, 2)}\n`);
  console.log(`wrote ${out.length} rows to ${OUT}`);
  for (const i of impact) {
    console.log(`  ${i.full_name}: ${i.answers_now} -> ${i.answers_after}`
      + `${i.answers_after === 0 ? `  ⚠ EMPTIED (research_ts_set=${i.research_ts_set})` : ''}`);
  }
})().catch(async (e) => { console.error('FAIL:', e); try { await pool.end(); } catch {} process.exit(2); });
