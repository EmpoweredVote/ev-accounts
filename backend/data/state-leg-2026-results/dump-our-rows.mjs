#!/usr/bin/env node
// Dump every candidacy in our 2026-11-03 state-legislative races, so the analyser and the
// report are reproducible from committed files. One row per candidacy.
//
// It also carries essentials.office_current_holder for each office — an INDEPENDENT fact the
// migration's incumbent cross-check needs, because a file that checks is_incumbent against its
// own table agrees with itself (CC_0358).
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
const require = createRequire(process.env.RESOLVE_FROM || import.meta.url);
const pg = require('pg');

const out = process.argv[2];
const expectRaces = process.argv[3] ? Number(process.argv[3]) : null;
if (!out) { console.error('usage: dump-our-rows.mjs <output.json> [expected races]'); process.exit(2); }

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
const { rows } = await client.query(`
  SELECT lower(d.state) AS state, d.district_type, d.ocd_id, d.label AS district_label,
         o.id AS office_id, o.title AS office_title,
         r.id AS race_id, r.position_name, r.seats,
         rc.id AS rc_id, rc.full_name, rc.first_name, rc.last_name, rc.politician_id,
         rc.is_incumbent, rc.candidate_status, rc.is_write_in,
         rc.result, rc.result_certainty, rc.result_source,
         och.politician_id AS current_holder_id,
         hp.full_name AS current_holder_name
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians hp ON hp.id = och.politician_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
   ORDER BY d.state, d.district_type, d.ocd_id, o.title, rc.last_name, rc.first_name`);
await client.end();

const races = new Set(rows.map((r) => r.race_id));
if (expectRaces !== null && races.size !== expectRaces) {
  throw new Error(`expected ${expectRaces} races carrying candidates, found ${races.size}`);
}
fs.mkdirSync(path.dirname(path.resolve(out)), { recursive: true });
fs.writeFileSync(out, JSON.stringify(rows, null, 1));
const byState = {};
for (const r of rows) byState[r.state] = (byState[r.state] || 0) + 1;
console.log(`wrote ${out}: ${rows.length} candidacies across ${races.size} races`);
console.log(Object.entries(byState).map(([k, v]) => `${k} ${v}`).join(' · '));
