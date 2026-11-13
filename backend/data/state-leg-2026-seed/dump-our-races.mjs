#!/usr/bin/env node
// Dump every 2026-11-03 state-legislative RACE we hold in the named states, whether or not it
// carries candidates, so the matcher and the report are reproducible from committed files.
//
// 🔴 THE RESULTS PASS (CC_0381) INNER-JOINED race_candidates, so a race with no candidates was
//   invisible to it by construction. This wave is exactly those races, so the join is a LEFT one
//   and `candidates` is a counted column rather than an assumption.
//
// It also carries essentials.office_current_holder per office — an INDEPENDENT fact, needed to
// link an incumbent candidacy to a politician without reading a name (CC_0381's `holder` basis).
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
const require = createRequire(process.env.RESOLVE_FROM || import.meta.url);
const pg = require('pg');

const out = process.argv[2];
const states = (process.argv[3] || '').split(',').map((s) => s.trim().toLowerCase()).filter(Boolean);
if (!out || !states.length) { console.error('usage: dump-our-races.mjs <output.json> <st,st,...>'); process.exit(2); }

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
const { rows } = await client.query(
  `SELECT lower(d.state) AS state, d.district_type, d.ocd_id, d.label AS district_label,
          d.id AS district_id,
          o.id AS office_id, o.title AS office_title, o.is_vacant,
          r.id AS race_id, r.position_name, r.seats, r.primary_party,
          (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id) AS candidates,
          och.politician_id AS current_holder_id,
          hp.full_name AS current_holder_name,
          hp.first_name AS current_holder_first,
          hp.last_name AS current_holder_last,
          hp.is_active AS current_holder_active
     FROM essentials.races r
     JOIN essentials.elections e ON e.id = r.election_id
     JOIN essentials.offices o ON o.id = r.office_id
     JOIN essentials.districts d ON d.id = o.district_id
     LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     LEFT JOIN essentials.politicians hp ON hp.id = och.politician_id
    WHERE e.election_date = DATE '2026-11-03'
      AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
      AND lower(d.state) = ANY($1::text[])
    ORDER BY d.state, d.district_type, o.title`,
  [states],
);
await client.end();

// One row per race is the contract here; office_current_holder is one row per office, so a
// politician-rooted fan-out cannot happen. Assert it rather than trust it.
const ids = new Set(rows.map((r) => r.race_id));
if (ids.size !== rows.length) throw new Error(`fan-out: ${rows.length} rows for ${ids.size} races`);

fs.mkdirSync(path.dirname(path.resolve(out)), { recursive: true });
fs.writeFileSync(out, JSON.stringify(rows, null, 1));

const tally = {};
for (const r of rows) {
  const k = `${r.state} ${r.district_type}`;
  tally[k] ??= { races: 0, empty: 0, seated: 0 };
  tally[k].races++;
  if (Number(r.candidates) === 0) tally[k].empty++;
  if (r.current_holder_id) tally[k].seated++;
}
console.log(`wrote ${out}: ${rows.length} races`);
for (const [k, v] of Object.entries(tally)) {
  console.log(`  ${k.padEnd(16)} races ${String(v.races).padStart(3)}  no candidates ${String(v.empty).padStart(3)}  office seated ${String(v.seated).padStart(3)}`);
}
