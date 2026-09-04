/* Provo City School District board-subdistrict build (P2 pilot).
 * Dissolves Utah County precincts (LOCALSCHOOL P1..P7) into 7 board districts, loads them
 * as X0002 sub-districts, and repoints each office to its district via the verified roster.
 * Atomic: all-or-nothing. Geometry from provo_precincts.geojson (Utah County FeatureServer). */
const fs = require('fs');
const path = require('path');
const BACKEND = '/Users/chrisandrews/Documents/GitHub/ev-accounts/backend';
const { Client } = require(path.join(BACKEND, 'node_modules', 'pg'));
const env = fs.readFileSync(path.join(BACKEND, '.env'), 'utf8');
const DATABASE_URL = env.match(/^DATABASE_URL\s*=\s*"?([^"\n]+)"?\s*$/m)[1].trim();

const GEOJSON = '/private/tmp/claude-501/-Users-chrisandrews-Documents-GitHub-essentials/54a89293-4a34-4fcc-a6c7-ce6e2a08583b/scratchpad/provo_precincts.geojson';
const CORP_GEOID = '4900810';
const MTFCC = 'X0002';
const GB_STATE = '49';   // UT FIPS (geofence_boundaries convention)
const D_STATE = 'ut';
const SOURCE = 'utah_county_election_precincts_localschool_dissolve_2026';
// Verified 2026-09-03 vs provo.edu board pages:
const ROSTER = { 1:'Lisa Boyce', 2:'Melanie Hall', 3:'Megan Van Wagenen', 4:'Jennifer Partridge', 5:'Teri McCabe', 6:'Emily Harrison', 7:'Gina Hales' };

(async () => {
  const gj = JSON.parse(fs.readFileSync(GEOJSON, 'utf8'));
  const byDist = {}; // '1'..'7' -> [geojson geometry strings]
  for (const f of gj.features) {
    const ls = f.properties && f.properties.LOCALSCHOOL; // 'P1'..'P7'
    if (!/^P[1-7]$/.test(ls) || !f.geometry) continue;
    const n = ls.slice(1);
    (byDist[n] = byDist[n] || []).push(JSON.stringify(f.geometry));
  }
  const counts = Object.fromEntries(Object.entries(byDist).map(([k,v])=>[k,v.length]));
  console.log('precincts by district:', JSON.stringify(counts));
  if (Object.keys(byDist).length !== 7) throw new Error('expected 7 districts P1..P7, got '+Object.keys(byDist).sort());

  const c = new Client({ connectionString: DATABASE_URL });
  await c.connect();
  try {
    await c.query('BEGIN');
    const corp = await c.query(`SELECT id, government_id FROM essentials.districts WHERE geo_id=$1 AND district_type='SCHOOL'`, [CORP_GEOID]);
    if (corp.rowCount !== 1) throw new Error('corp Provo district not found (rows='+corp.rowCount+')');
    const corpId = corp.rows[0].id, govId = corp.rows[0].government_id;

    let gGeof=0, gDist=0, gLink=0;
    for (const n of ['1','2','3','4','5','6','7']) {
      const geoId = `${CORP_GEOID}-board-d${n}`;
      const label = `Provo City School Board - District ${n}`;
      // Dissolve this district's precincts: union of per-precinct valid geometry.
      const gb = await c.query(
        `INSERT INTO essentials.geofence_boundaries (geo_id,name,state,mtfcc,geometry,source,imported_at)
         SELECT $1,$2,$3,$4,
                public.ST_Multi(public.ST_MakeValid(public.ST_Union(
                  public.ST_MakeValid(public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON(g)),4326))))),
                $5, now()
         FROM unnest($6::text[]) AS t(g)
         ON CONFLICT (geo_id,mtfcc) DO NOTHING`,
        [geoId, label, GB_STATE, MTFCC, SOURCE, byDist[n]],
      );
      gGeof += gb.rowCount || 0;

      // district_id must be GLOBALLY unique — scope it to the geo_id (MCCSC already used
      // the un-scoped 'board-d{N}', which collided and rolled back the first attempt).
      const districtId = `${CORP_GEOID}-board-d${n}`;
      const d = await c.query(
        `INSERT INTO essentials.districts (geo_id,district_type,label,state,mtfcc,district_id,government_id)
         SELECT $1,'SCHOOL',$2,$3,$4,$5,$6
         WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_id=$5)`,
        [geoId, label, D_STATE, MTFCC, districtId, govId],
      );
      gDist += d.rowCount || 0;

      const sub = await c.query(`SELECT id FROM essentials.districts WHERE district_id=$1`, [districtId]);
      const subId = sub.rows[0].id;
      // Relink the office whose CURRENT HOLDER is the rostered member for district n.
      const up = await c.query(
        `UPDATE essentials.offices o SET district_id=$1
          WHERE o.district_id=$2
            AND o.id IN (SELECT och.office_id FROM essentials.office_current_holder och
                         JOIN essentials.politicians p ON p.id=och.politician_id
                         WHERE p.full_name=$3)`,
        [subId, corpId, ROSTER[n]],
      );
      if ((up.rowCount||0) !== 1) throw new Error(`roster relink for D${n} (${ROSTER[n]}) matched ${up.rowCount} offices (expected 1)`);
      gLink += up.rowCount;
    }

    // Post-conditions
    const onSubs = (await c.query(`SELECT count(*)::int n FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id WHERE d.geo_id LIKE $1`, [`${CORP_GEOID}-board-d%`])).rows[0].n;
    const onCorp = (await c.query(`SELECT count(*)::int n FROM essentials.offices WHERE district_id=$1`, [corpId])).rows[0].n;
    const invalid = (await c.query(`SELECT count(*)::int n FROM essentials.geofence_boundaries WHERE geo_id LIKE $1 AND mtfcc=$2 AND NOT public.ST_IsValid(geometry)`, [`${CORP_GEOID}-board-d%`, MTFCC])).rows[0].n;
    console.log(`geofences=${gGeof}, sub-districts=${gDist}, relinked=${gLink}, onSubs=${onSubs}, onCorp=${onCorp}, invalid=${invalid}`);
    if (onSubs!==7 || onCorp!==0 || invalid!==0) throw new Error('post-condition failed — rolling back');

    // Reachability spot-check: a downtown Provo point resolves to exactly one board member.
    const probe = await c.query(
      `WITH pt AS (SELECT ST_SetSRID(ST_MakePoint(-111.6585,40.2338),4326) g)
       SELECT d.district_id, pol.full_name
       FROM pt JOIN essentials.geofence_boundaries gb ON gb.mtfcc='X0002' AND ST_Covers(gb.geometry, pt.g)
       JOIN essentials.districts d ON d.geo_id=gb.geo_id AND d.district_type='SCHOOL' AND d.geo_id LIKE '4900810-board-d%'
       JOIN essentials.offices o ON o.district_id=d.id
       LEFT JOIN essentials.office_current_holder och ON och.office_id=o.id
       LEFT JOIN essentials.politicians pol ON pol.id=och.politician_id`);
    console.log('probe downtown Provo ->', JSON.stringify(probe.rows));
    if (probe.rowCount !== 1) throw new Error(`probe returned ${probe.rowCount} members (expected 1) — rolling back`);

    await c.query('COMMIT');
    console.log('COMMIT ok — Provo loaded');
  } catch (e) {
    await c.query('ROLLBACK');
    console.error('ROLLBACK (nothing committed): ' + e.message);
    process.exitCode = 1;
  } finally { await c.end(); }
})().catch(e => { console.error('FAIL: '+e.message); process.exit(1); });
