// compare-limits.mjs <slug> — how far a council map's union sits from (a) TIGER's place polygon and
// (b) the State of Indiana's own city-limits layer (WAYEO City, layer 10). Read-only.
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';
const slug = process.argv[2];
const cfg = JSON.parse(fs.readFileSync(new URL('./council-maps.json', import.meta.url))).find((c) => c.slug === slug);
const WAYEO = 'https://services6.arcgis.com/3BIBAkkTYicFwv1e/arcgis/rest/services/WAYEO_WebMap_WFL1/FeatureServer/10';
const name = cfg.name.replace(/'/g, "''");
const w = await (await fetch(`${WAYEO}/query?where=${encodeURIComponent(`namelsad_1='${name} city'`)}&outFields=*&outSR=4326&f=geojson`)).json();
const d = await (await fetch(`${cfg.url}/query?where=${encodeURIComponent(cfg.where ?? '1=1')}&outFields=*&outSR=4326&f=geojson`)).json();
console.log(`${slug}: WAYEO features ${w.features?.length}, council features ${d.features?.length}`);
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const S = 2589988.110336;
const mk = (fs_) => `ST_SetSRID(ST_MakeValid(ST_Union(ARRAY[${fs_.map((f) => `ST_SetSRID(ST_GeomFromGeoJSON('${JSON.stringify(f.geometry).replace(/'/g, "''")}'),4326)`).join(",")}])),4326)`;
const r = (await pool.query(`WITH t AS (SELECT ST_SetSRID(geometry,4326) g FROM essentials.geofence_boundaries WHERE geo_id=$1 AND mtfcc='G4110'),
  w AS (SELECT ${mk(w.features)} g), u AS (SELECT ${mk(d.features)} g)
  SELECT ST_Area(t.g::geography)/${S} tiger, ST_Area(w.g::geography)/${S} state, ST_Area(u.g::geography)/${S} uni,
         ST_Area(ST_Difference(u.g,t.g)::geography)/${S} out_tiger, ST_Area(ST_Difference(t.g,u.g)::geography)/${S} unc_tiger,
         ST_Area(ST_Difference(u.g,w.g)::geography)/${S} out_state, ST_Area(ST_Difference(w.g,u.g)::geography)/${S} unc_state
  FROM t,w,u`, [cfg.geoid])).rows[0];
for (const [k, v] of Object.entries(r)) console.log(`  ${k.padEnd(10)} ${Number(v).toFixed(4)} sq mi`);
await pool.end();
