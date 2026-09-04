/* Nebo School District board-subdistrict build (P2).
 * (1) Seeds the 2 missing current members (Shannon Acor D5, John Taylor D6) mirroring the
 *     existing Nebo seat structure. (2) Dissolves Utah County precincts (LOCALSCHOOL N1..N7,
 *     verified county N#=board District# via anchors) into 7 X0002 sub-districts. (3) Repoints
 *     all 7 offices by member->district. Atomic; rolls back on any post-condition failure. */
const fs = require('fs');
const path = require('path');
const BACKEND = '/Users/chrisandrews/Documents/GitHub/ev-accounts/backend';
const { Client } = require(path.join(BACKEND, 'node_modules', 'pg'));
const env = fs.readFileSync(path.join(BACKEND, '.env'), 'utf8');
const DATABASE_URL = env.match(/^DATABASE_URL\s*=\s*"?([^"\n]+)"?\s*$/m)[1].trim();

const GEOJSON = '/private/tmp/claude-501/-Users-chrisandrews-Documents-GitHub-essentials/54a89293-4a34-4fcc-a6c7-ce6e2a08583b/scratchpad/nebo_precincts.geojson';
const CORP_GEOID = '4900630';
const CHAMBER_ID = '3a1935b1-ccfc-4d7f-81c2-3be0d117c2ce'; // "Nebo School Board"
const MTFCC = 'X0002', GB_STATE = '49', D_STATE = 'ut';
const GEO_SOURCE = 'utah_county_election_precincts_localschool_dissolve_2026';
const POL_SOURCE = 'ut-school-nebo';
// New members to seed (verified current, nebo.edu + March 2025 minutes):
const SEED = [
  { full: 'Shannon Acor', first: 'Shannon', last: 'Acor', ext: -307280, dist: 5 },
  { full: 'John Taylor',  first: 'John',    last: 'Taylor', ext: -307281, dist: 6 },
];
// name -> district N (verified county N#=board District#):
const ROSTER = { 'Brian Rowley':1, 'Kristen Betts':2, 'Shauna Warnick':3, 'Rick Ainge':4, 'Shannon Acor':5, 'John Taylor':6, 'Scott Wilson':7 };
const INV = Object.fromEntries(Object.entries(ROSTER).map(([n,d])=>[d,n]));

(async () => {
  const gj = JSON.parse(fs.readFileSync(GEOJSON, 'utf8'));
  const byDist = {};
  for (const f of gj.features) {
    const ls = f.properties && f.properties.LOCALSCHOOL;
    if (!/^N[1-7]$/.test(ls) || !f.geometry) continue;
    (byDist[ls.slice(1)] = byDist[ls.slice(1)] || []).push(JSON.stringify(f.geometry));
  }
  if (Object.keys(byDist).length !== 7) throw new Error('expected N1..N7, got '+Object.keys(byDist).sort());

  const c = new Client({ connectionString: DATABASE_URL });
  await c.connect();
  try {
    await c.query('BEGIN');
    const corp = await c.query(`SELECT id, government_id FROM essentials.districts WHERE geo_id=$1 AND district_type='SCHOOL'`, [CORP_GEOID]);
    if (corp.rowCount !== 1) throw new Error('corp Nebo district not found');
    const corpId = corp.rows[0].id, govId = corp.rows[0].government_id;

    // Preflight: seed external_ids must be free
    const clash = await c.query(`SELECT external_id FROM essentials.politicians WHERE external_id = ANY($1)`, [SEED.map(s=>s.ext)]);
    if (clash.rowCount) throw new Error('external_id already used: '+clash.rows.map(r=>r.external_id));

    // (1) Seed 2 missing members: office + politician + office_term
    for (const s of SEED) {
      const off = await c.query(
        `INSERT INTO essentials.offices (seats,title,is_vacant,chamber_id,district_id,voting_powers,representing_city,representing_state,faces_retention_vote,is_appointed_position)
         VALUES (1,'School Board Member',false,$1,$2,'full','Nebo School District','UT',false,false) RETURNING id`,
        [CHAMBER_ID, corpId]);
      const officeId = off.rows[0].id;
      const pol = await c.query(
        `INSERT INTO essentials.politicians (full_name,first_name,last_name,is_active,is_vacant,is_incumbent,party,data_source,external_id,office_id)
         VALUES ($1,$2,$3,true,false,true,NULL,$4,$5,$6) RETURNING id`,
        [s.full, s.first, s.last, POL_SOURCE, s.ext, officeId]);
      await c.query(
        `INSERT INTO essentials.office_terms (office_id,politician_id,start_precision,source)
         VALUES ($1,$2,'unknown','Nebo board roster (nebo.edu), seeded 2026-09-03')`,
        [officeId, pol.rows[0].id]);
    }

    // (2) Dissolve N1..N7 -> geofences + sub-districts
    for (const n of ['1','2','3','4','5','6','7']) {
      const geoId = `${CORP_GEOID}-board-d${n}`, districtId = `${CORP_GEOID}-board-d${n}`;
      const label = `Nebo School Board - District ${n}`;
      await c.query(
        `INSERT INTO essentials.geofence_boundaries (geo_id,name,state,mtfcc,geometry,source,imported_at)
         SELECT $1,$2,$3,$4,
           public.ST_Multi(public.ST_MakeValid(public.ST_Union(
             public.ST_MakeValid(public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON(g)),4326))))),
           $5, now()
         FROM unnest($6::text[]) AS t(g)
         ON CONFLICT (geo_id,mtfcc) DO NOTHING`,
        [geoId, label, GB_STATE, MTFCC, GEO_SOURCE, byDist[n]]);
      await c.query(
        `INSERT INTO essentials.districts (geo_id,district_type,label,state,mtfcc,district_id,government_id)
         SELECT $1,'SCHOOL',$2,$3,$4,$5,$6
         WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_id=$5)`,
        [geoId, label, D_STATE, MTFCC, districtId, govId]);
    }

    // (3) Relink all 7 offices to their sub-districts by current holder name
    let relinked = 0;
    for (const n of ['1','2','3','4','5','6','7']) {
      const sub = await c.query(`SELECT id FROM essentials.districts WHERE district_id=$1`, [`${CORP_GEOID}-board-d${n}`]);
      const up = await c.query(
        `UPDATE essentials.offices o SET district_id=$1
          WHERE o.district_id=$2
            AND o.id IN (SELECT och.office_id FROM essentials.office_current_holder och
                         JOIN essentials.politicians p ON p.id=och.politician_id WHERE p.full_name=$3)`,
        [sub.rows[0].id, corpId, INV[n]]);
      if ((up.rowCount||0)!==1) throw new Error(`relink D${n} (${INV[n]}) matched ${up.rowCount} (expected 1)`);
      relinked += up.rowCount;
    }

    // Post-conditions
    const q = async (s,p=[]) => (await c.query(s,p)).rows[0].n;
    const onSubs = await q(`SELECT count(*)::int n FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id WHERE d.geo_id LIKE $1`, [`${CORP_GEOID}-board-d%`]);
    const onCorp = await q(`SELECT count(*)::int n FROM essentials.offices WHERE district_id=$1`, [corpId]);
    const invalid = await q(`SELECT count(*)::int n FROM essentials.geofence_boundaries WHERE geo_id LIKE $1 AND mtfcc=$2 AND NOT public.ST_IsValid(geometry)`, [`${CORP_GEOID}-board-d%`, MTFCC]);
    const seeded = await q(`SELECT count(*)::int n FROM essentials.politicians WHERE external_id = ANY($1)`, [SEED.map(s=>s.ext)]);
    console.log(`relinked=${relinked}, onSubs=${onSubs}, onCorp=${onCorp}, invalid=${invalid}, seeded=${seeded}`);
    if (onSubs!==7||onCorp!==0||invalid!==0||seeded!==2) throw new Error('post-condition failed — rolling back');

    // Reachability probes (verified anchors)
    const probes = [['Santaquin',-111.786,39.976,'Brian Rowley'],['Payson',-111.732,40.043,'Scott Wilson'],['Mapleton',-111.578,40.130,'Kristen Betts'],['Salem',-111.674,40.053,'Rick Ainge']];
    for (const [lbl,lng,lat,expect] of probes) {
      const r = await c.query(
        `WITH pt AS (SELECT ST_SetSRID(ST_MakePoint($1,$2),4326) g)
         SELECT pol.full_name FROM pt
         JOIN essentials.geofence_boundaries gb ON gb.mtfcc='X0002' AND gb.geo_id LIKE '4900630-board-d%' AND ST_Covers(gb.geometry,pt.g)
         JOIN essentials.districts d ON d.geo_id=gb.geo_id
         JOIN essentials.offices o ON o.district_id=d.id
         LEFT JOIN essentials.office_current_holder och ON och.office_id=o.id
         LEFT JOIN essentials.politicians pol ON pol.id=och.politician_id`, [lng,lat]);
      const got = r.rows.map(x=>x.full_name);
      console.log(`  probe ${lbl}: ${JSON.stringify(got)} (expect ${expect})`);
      if (r.rowCount!==1 || got[0]!==expect) throw new Error(`probe ${lbl} => ${JSON.stringify(got)}, expected [${expect}] — rolling back`);
    }

    await c.query('COMMIT');
    console.log('COMMIT ok — Nebo loaded (2 members seeded + 7 subdistricts)');
  } catch (e) {
    await c.query('ROLLBACK');
    console.error('ROLLBACK (nothing committed): ' + e.message);
    process.exitCode = 1;
  } finally { await c.end(); }
})().catch(e => { console.error('FAIL: '+e.message); process.exit(1); });
