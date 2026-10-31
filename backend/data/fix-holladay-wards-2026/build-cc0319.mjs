/**
 * Builds CC_0319 with the repaired geometry as LITERAL WKT.
 *
 *   node --import ../../scripts/lib/main-checkout-fallback.mjs build-cc0319.mjs
 *
 * 🔴 WHY LITERALS AND NOT ST_Transform. `ST_Transform` and every `::geography` cast read
 *    `public.spatial_ref_sys`, which `anon` can write — ev-cto decision 0006, an accepted risk
 *    that `check-postgis-spatial-ref-guard.mjs` refuses to let new SQL re-open. Writing the
 *    reprojected rings out as literals removes the read entirely, so the migration needs no
 *    sign-off and adds no exposure.
 *
 * The literals are read back from production, where the reprojection has already been applied
 * and verified, rather than recomputed here — so what the file writes is exactly what was
 * measured, not the output of a second implementation of the same arithmetic.
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';

const dir = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(`
  SELECT geo_id,
         ST_AsText(geometry)              AS wkt,
         ST_NPoints(geometry)             AS npoints,
         md5(ST_AsBinary(geometry)::text) AS md5_after
    FROM essentials.geofence_boundaries
   WHERE geo_id LIKE '%holladay%'
   ORDER BY geo_id`);
await pool.end();
if (rows.length !== 5) { console.error(`expected 5 rows, got ${rows.length}`); process.exit(1); }

// The pre-image MD5s, from the committed capture — the state before the repair.
const pre = JSON.parse(fs.readFileSync(path.join(dir, 'original-geometry-3857.json'), 'utf8'));
const md5Before = new Map(pre.rows.map((r) => [r.geo_id, r.wkb_md5]));
if (md5Before.size !== 5) { console.error('pre-image file does not carry 5 rows'); process.exit(1); }

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const vals = rows.map((r) =>
  `    (${q(r.geo_id)},\n     ${q(md5Before.get(r.geo_id))},\n     ${q(r.md5_after)},\n     ${q(r.wkt)})`
).join(',\n');

const header = fs.readFileSync(path.join(dir, '_cc0319_header.sql'), 'utf8');
const body = fs.readFileSync(path.join(dir, '_cc0319_body.sql'), 'utf8');
const sql = header + '\nBEGIN;\n\n'
  + '-- @generated-by data/fix-holladay-wards-2026/build-cc0319.mjs — do not hand-edit the WKT.\n'
  + 'CREATE TEMP TABLE ak_holladay_fix (geo_id text, md5_before text, md5_after text, wkt text)\n'
  + '  ON COMMIT DROP;\n'
  + 'INSERT INTO ak_holladay_fix (geo_id, md5_before, md5_after, wkt) VALUES\n'
  + vals + ';\n\n'
  + body;

const out = path.join(dir, '..', '..', 'migrations', 'CC_0319_holladay_ward_srid_repair.sql');
fs.writeFileSync(out, sql);
const bytes = fs.statSync(out).size;
console.log(`wrote CC_0319 (${(bytes / 1024).toFixed(1)} KB) with 5 literal geometries`);
for (const r of rows) console.log(`  ${r.geo_id.split('/').pop()}  npoints=${r.npoints}  after=${r.md5_after}`);
console.log('forbidden patterns in output:',
  ['ST_Transform', '::geography'].map((p) => `${p}=${(sql.match(new RegExp(p.replace('::','::'), 'g')) || []).length}`).join(' '));
