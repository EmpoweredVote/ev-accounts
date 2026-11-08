#!/usr/bin/env node
// Dump the rows this wave writes against, so the analyser and the report are reproducible
// from committed files. One row per candidacy in the 19 races whose seats hand over on
// 2026-12-04. Run with DOTENV_CONFIG_PATH pointing at a checkout that has backend/.env.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
// ESM ignores NODE_PATH, and a linked worktree has no node_modules of its own. RESOLVE_FROM
// lets this run against the main checkout's modules without planting a junction.
const require = createRequire(process.env.RESOLVE_FROM || import.meta.url);
const pg = require('pg');

const out = process.argv[2];
if (!out) { console.error('usage: dump-our-rows.mjs <output.json>'); process.exit(2); }
const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
const { rows } = await client.query(`
  SELECT d.label AS district_label, o.title AS office_title, r.seats,
         r.id AS race_id, o.id AS office_id, o.is_vacant, o.vacant_since,
         rc.id AS rc_id, rc.full_name, rc.first_name, rc.last_name, rc.politician_id,
         rc.is_incumbent, rc.candidate_status, rc.result, rc.result_certainty, rc.result_source,
         s.swearing_in_date, s.basis, s.rule_id
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE e.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-04'
   ORDER BY d.label, o.title, rc.last_name, rc.first_name`);
await client.end();

const races = new Set(rows.map((r) => r.race_id));
if (races.size !== 19) throw new Error(`expected 19 races on 2026-12-04, found ${races.size}`);
if (rows.length !== 59) throw new Error(`expected 59 candidacies, found ${rows.length}`);
fs.mkdirSync(path.dirname(path.resolve(out)), { recursive: true });
fs.writeFileSync(out, JSON.stringify(rows, null, 1));
console.log(`wrote ${out}: ${rows.length} candidacies across ${races.size} races`);
