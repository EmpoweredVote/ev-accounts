#!/usr/bin/env node
/**
 * Build the Maryland slice of the "backed Medicaid expansion" template class.
 *
 * 🔴 THE PHRASE IS A TEMPLATE, NOT A CLAIM. It appears on 368 rows across 288 politicians in 44
 * states, 360 of them with no bill citation of any kind. Maryland expanded Medicaid in 2013, so for
 * any member seated afterwards the sentence is not merely unsourced — it is impossible.
 *
 * 🔑 THIS IS A DIFFERENT AND WIDER COHORT than the migration-1714 rows already fixed: 53 rows across
 * 53 DISTINCT politicians, none of which carries an mgaleg bill citation. The 1714 queue was a slice
 * of this, which is exactly the "the cohort itself was the defect" lesson.
 *
 * 🔴 Reads only.
 *   node scripts/md-medicaid-template-cohort.mjs --out <cohort.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-md-medicaid-template-cohort.json');

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const { rows } = await pool.query(`
  SELECT c.politician_id, c.topic_id, p.full_name AS name, t.title AS topic, a.value AS chair,
         c.reasoning, c.sources, o.title AS office, o.representing_state AS state
    FROM inform.politician_context c
    JOIN essentials.politicians p ON p.id = c.politician_id
    LEFT JOIN essentials.offices o ON o.id = p.office_id
    LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
    LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
   WHERE c.reasoning ILIKE '%Medicaid expansion%' AND o.representing_state = 'MD'
   ORDER BY t.title, p.full_name`);
await pool.end();

const noSlug = rows.filter((r) => !(r.sources || []).some((s) => /mgaleg.*Members\/Details/.test(s)));
console.log(`${rows.length} Maryland rows; ${new Set(rows.map((r) => r.name)).size} distinct politicians`);
console.log(`  without an mgaleg member slug: ${noSlug.length}`);
for (const r of noSlug) console.log(`    ⚠ ${r.name} / ${r.topic} — sources: ${(r.sources || []).join(' ')}`);
const byTopic = {};
for (const r of rows) byTopic[r.topic] = (byTopic[r.topic] || 0) + 1;
console.log(`  by topic: ${JSON.stringify(byTopic)}`);

fs.writeFileSync(OUT, JSON.stringify({
  pass: 'MD slice of the "backed Medicaid expansion" template class',
  n: rows.length, rows,
}, null, 1));
console.log(`wrote ${OUT}`);
