/**
 * Build a single-transaction dry run of the ENTIRE MN-3 chain:
 *
 *   boundaries (what load-mn-city-council-boundaries.ts would write)
 *     -> CC_0109 structure
 *     -> CC_0110 occupancy
 *     -> ROLLBACK
 *
 * CC_0109's pre-flight refuses to run without the twelve boundaries, so the migrations cannot be
 * dry-run on their own. Loading them for real first would be a production write, and a dry run
 * that requires a production write is not a dry run. The prelude below writes exactly what the
 * loader writes -- same geo_ids, same mtfcc, same `source` string, which the pre-flight inspects
 * -- inside the same transaction that is then rolled back.
 *
 *   node build-dryrun.mjs > _dryrun-mn3.sql
 */
import fs from 'fs';
import path from 'path';

const MIG = path.join('..', '..', 'migrations');

const CITIES = [
  {
    file: '_duluth-new.geojson',
    numberField: 'CouncilDist',
    slug: (n) => `duluth-mn-council-district-${n}`,
    label: (n) => `Duluth City Council District ${n}`,
    mtfcc: 'X0052',
    source:
      'City of Duluth GIS Office, VotingDistricts/MapServer/16 "Districts and City Councilors", read 2026-09-14 (MN-3, X0052)',
  },
  {
    file: '_stpaul-wards.geojson',
    numberField: 'district',
    slug: (n) => `saint-paul-mn-ward-${n}`,
    label: (n) => `Saint Paul City Council Ward ${n}`,
    mtfcc: 'X0053',
    source:
      'City of Saint Paul, Council_Ward_/FeatureServer/0 "Council Ward", read 2026-09-14 (MN-3, X0053)',
  },
];

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const out = [];
out.push('BEGIN;');
out.push(`SET LOCAL statement_timeout = '300s';`);
out.push('');
out.push('-- ─── PRELUDE: what load-mn-city-council-boundaries.ts writes (X0052, X0053) ───');

let n = 0;
for (const c of CITIES) {
  const gj = JSON.parse(fs.readFileSync(c.file, 'utf8'));
  for (const f of gj.features) {
    const num = Number(f.properties[c.numberField]);
    out.push(
      `INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)\n` +
        `VALUES (${q(c.slug(num))}, ${q(c.label(num))}, '27', ${q(c.mtfcc)},\n` +
        `        ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(${q(JSON.stringify(f.geometry))}), 4326)),\n` +
        `        ${q(c.source)}, now())\n` +
        `ON CONFLICT (geo_id, mtfcc) DO NOTHING;`,
    );
    n++;
  }
}
out.push('');
out.push(`-- prelude wrote ${n} boundary rows`);
out.push('');

for (const f of ['CC_0109_mn_cities_structure.sql', 'CC_0110_mn_cities_officials.sql']) {
  out.push(`-- ══════ ${f} ══════`);
  const body = fs
    .readFileSync(path.join(MIG, f), 'utf8')
    .replace(/^BEGIN;$/m, '-- (BEGIN removed for dry run)')
    .replace(/^COMMIT;$/m, '-- (COMMIT removed for dry run)');
  out.push(body);
}

out.push('ROLLBACK;');
process.stdout.write(out.join('\n'));
