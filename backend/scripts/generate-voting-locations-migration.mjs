#!/usr/bin/env node
/**
 * generate-voting-locations-migration — turn one hand-checked county file in
 * backend/data/voting-locations/ into the SQL that loads it.
 *
 *   node backend/scripts/generate-voting-locations-migration.mjs <file.json> > out.sql
 *
 * Fetches the precinct polygons from the layer the file names, checks that every
 * precinct maps to exactly one Election Day site (and that every site's precincts
 * exist), and prints INSERTs for essentials.voting_location_sets / voting_precincts /
 * voting_sites. Re-running for the same county and election replaces that set.
 *
 * The SQL ends with assertions that re-check the same invariants inside the
 * database, so a hand edit to the output cannot slip a bad row through.
 */
import { readFileSync } from 'node:fs';

const file = process.argv[2];
if (!file) {
  console.error('usage: generate-voting-locations-migration.mjs <county-file.json>');
  process.exit(2);
}
const cfg = JSON.parse(readFileSync(file, 'utf8'));

const q = (v) => (v === null || v === undefined ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`);
const num = (v) => (typeof v === 'number' ? String(v) : 'NULL');
const fail = (msg) => {
  console.error(`✗ ${msg}`);
  process.exit(1);
};

// ---- precinct polygons ------------------------------------------------------
const url = new URL(`${cfg.precincts.layer_url}/query`);
url.searchParams.set('where', '1=1');
url.searchParams.set('outFields', cfg.precincts.code_field);
url.searchParams.set('outSR', '4326');
url.searchParams.set('f', 'geojson');
const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0', 'Accept-Encoding': 'gzip' } });
if (!res.ok) fail(`precinct layer returned ${res.status}`);
const geo = await res.json();

// 6 decimals ≈ 0.1 m — far finer than the boundary guard, and half the bytes.
const round = (c) => (typeof c[0] === 'number' ? [+c[0].toFixed(6), +c[1].toFixed(6)] : c.map(round));
const precincts = geo.features.map((f) => ({
  code: String(f.properties[cfg.precincts.code_field]).trim(),
  geometry: { type: f.geometry.type, coordinates: round(f.geometry.coordinates) },
}));

if (precincts.length !== cfg.precincts.expected_count) {
  fail(`expected ${cfg.precincts.expected_count} precincts, layer returned ${precincts.length}`);
}

// ---- the one invariant that matters ----------------------------------------
const codes = new Set(precincts.map((p) => p.code));
if (codes.size !== precincts.length) fail('precinct layer has duplicate codes');
const assigned = new Map();
for (const s of cfg.election_day_sites) {
  for (const c of s.precincts) {
    if (!codes.has(c)) fail(`site "${s.name}" lists precinct "${c}", which is not in the layer`);
    if (assigned.has(c)) fail(`precinct "${c}" is listed at both "${assigned.get(c)}" and "${s.name}"`);
    assigned.set(c, s.name);
  }
}
const unassigned = [...codes].filter((c) => !assigned.has(c));
if (unassigned.length) fail(`precincts with no Election Day site: ${unassigned.join(', ')}`);

// ---- SQL --------------------------------------------------------------------
const setWhere = `county_fips = ${q(cfg.county_fips)} AND election_date = ${q(cfg.election_date)}`;
const setId = `(SELECT id FROM essentials.voting_location_sets WHERE ${setWhere})`;
const out = [];

out.push(`-- ${cfg.county_name}, ${cfg.state} — ${cfg.election_name} (${cfg.election_date})`);
out.push(`-- Generated from ${file.replace(/^.*backend\//, 'backend/')} by scripts/generate-voting-locations-migration.mjs.`);
out.push(`-- ${precincts.length} precincts, ${cfg.election_day_sites.length} Election Day sites, ${cfg.early_vote_sites.length} early-vote site(s).`);
out.push('');
out.push(`DELETE FROM essentials.voting_location_sets WHERE ${setWhere};  -- cascades to precincts and sites`);
out.push('');
out.push(
  `INSERT INTO essentials.voting_location_sets
  (county_fips, county_name, state, election_name, election_date, source_label, source_url, last_checked, lookup_url)
VALUES (${[cfg.county_fips, cfg.county_name, cfg.state, cfg.election_name, cfg.election_date, cfg.source_label, cfg.source_url, cfg.last_checked, cfg.lookup_url].map(q).join(', ')});`,
);
out.push('');

for (const s of cfg.election_day_sites) {
  out.push(
    `INSERT INTO essentials.voting_sites (set_id, kind, name, address, lat, lng, hours, precinct_codes) VALUES (${setId}, 'election_day', ${q(s.name)}, ${q(s.address)}, ${num(s.lat)}, ${num(s.lng)}, ${q(s.hours ?? cfg.election_day_hours)}, ARRAY[${s.precincts.map(q).join(', ')}]::text[]);`,
  );
}
for (const s of cfg.early_vote_sites) {
  out.push(
    `INSERT INTO essentials.voting_sites (set_id, kind, name, address, lat, lng, hours, start_date, end_date) VALUES (${setId}, 'early_vote', ${q(s.name)}, ${q(s.address)}, ${num(s.lat)}, ${num(s.lng)}, ${q(s.hours)}, ${q(s.start_date)}, ${q(s.end_date)});`,
  );
}
out.push('');

for (const p of precincts.sort((a, b) => a.code.localeCompare(b.code))) {
  out.push(
    `INSERT INTO essentials.voting_precincts (set_id, code, geometry) VALUES (${setId}, ${q(p.code)}, ST_Multi(ST_SetSRID(ST_GeomFromGeoJSON(${q(JSON.stringify(p.geometry))}), 4326)));`,
  );
}
out.push('');

// The same invariants, checked against what actually landed.
out.push(`DO $$
DECLARE
  sid int := ${setId};
  n_precincts int;
  bad text;
BEGIN
  SELECT count(*) INTO n_precincts FROM essentials.voting_precincts WHERE set_id = sid;
  IF n_precincts <> ${precincts.length} THEN
    RAISE EXCEPTION 'expected ${precincts.length} precincts, found %', n_precincts;
  END IF;

  SELECT string_agg(p.code, ', ') INTO bad
    FROM essentials.voting_precincts p
   WHERE p.set_id = sid
     AND (SELECT count(*) FROM essentials.voting_sites s
           WHERE s.set_id = sid AND s.kind = 'election_day' AND p.code = ANY (s.precinct_codes)) <> 1;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'precincts without exactly one Election Day site: %', bad;
  END IF;

  SELECT string_agg(c, ', ') INTO bad
    FROM essentials.voting_sites s, unnest(s.precinct_codes) c
   WHERE s.set_id = sid
     AND NOT EXISTS (SELECT 1 FROM essentials.voting_precincts p WHERE p.set_id = sid AND p.code = c);
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'sites list precincts that do not exist: %', bad;
  END IF;

  SELECT string_agg(code, ', ') INTO bad
    FROM essentials.voting_precincts WHERE set_id = sid AND NOT ST_IsValid(geometry);
  IF bad IS NOT NULL THEN
    RAISE NOTICE 'precincts with invalid geometry (ST_Covers still works; check if lookups look wrong): %', bad;
  END IF;
END $$;`);

process.stdout.write(out.join('\n') + '\n');
console.error(`✓ ${precincts.length} precincts, all mapped to exactly one of ${cfg.election_day_sites.length} sites`);
