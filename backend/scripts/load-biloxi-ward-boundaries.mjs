#!/usr/bin/env node
/**
 * load-biloxi-ward-boundaries.mjs — Knight program, wave MS-3.
 *
 * Builds Biloxi's seven City Council ward polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='biloxi-ms-ward-1' … '-7', mtfcc='X0073'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structure migration creates the districts and
 * their offices and REFUSES TO RUN if these seven boundaries are absent — an office on a district
 * with no polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * ⚠ THE MAYOR NEEDS NO POLYGON. Biloxi's mayor is elected citywide, so the structure migration
 * hangs that office on the TIGER place boundary 2806220 / G4110 already in production — the pattern
 * every other LOCAL_EXEC mayor in this database uses. Seven wards, one seat each, eight offices.
 *
 * ── X0073, AND WHY IT IS NOT COUNTED ─────────────────────────────────────────────────────────
 * `max(mtfcc)` over BOTH essentials.geofence_boundaries and essentials.districts read X0072
 * (Aberdeen, SD-3) on 2026-09-28, in the same session as this write. An X code has no allocator,
 * so it is read from production and used immediately. The pre-flight below re-reads it and aborts
 * if anything already occupies X0073 with rows that are not ours.
 *
 * ── WHERE THE GEOMETRY COMES FROM, AND WHY THIS SOURCE ───────────────────────────────────────
 * The city publishes its wards two ways: a PDF ("Ward Map", WARDS LAST REVISED: 12/12/2024) and an
 * ArcGIS feature service. The PDF is the Gary dead end and is NOT the route — but it is the source
 * of the anchors that prove the service, which is the only job a PDF can do well.
 *
 * 🔴🔴 THE SERVICE IS NAMED "Wards2022" AND THE CITY'S OWN MAP SAYS THE WARDS WERE LAST REVISED
 * 12/12/2024. A NAME CANNOT DATE A PLAN — the MS-1 finding in miniature, except that here the
 * disagreement is explicit. It is settled by measurement, not by reading the name: the ten anchors
 * in ANCHORS below all come from OUTSIDE the service (seven from the 2024-revised PDF's own polling
 * place list, two from council members' published home addresses, one from Ward 4's own ward-meeting
 * venue), and all ten land in the ward the city says they are in.
 *
 * 🔴 `Id` IS NOT THE WARD NUMBER. `Ward_2020` IS. The layer carries both and `Id` REPEATS —
 * Id=6 appears on Ward 4 AND Ward 6, Id=1 on Ward 1 AND Ward 3. A join on Id would silently merge
 * two wards. Reading one sample of the rows is what caught it; a count never would have. Control 2b
 * asserts the collision still exists, so that a future re-publish which repairs Id stops this
 * loader and makes a human re-choose the key rather than inheriting a stale choice.
 *
 * Controls, all of which must fire before any row is written:
 *   1.  a bogus layer id must fail to return features;
 *   2.  the ward numbers must be exactly {1,2,3,4,5,6,7} on Ward_2020;
 *   2b. Id must still be unusable as a key (fewer than 7 distinct values);
 *   3.  the populations must sum to 49,574;
 *   4.  every extra ring must be a hole, not a part;
 *   5.  the ten published anchors must each land in the expected ward — computed here by an
 *       INDEPENDENT point-in-polygon over the bytes about to be written, not by asking the service;
 *   6.  Biloxi City Hall must fall in EXACTLY ONE ward, and two out-of-city points in NONE;
 *   7.  each ward must contain at least one anchor of its own and no anchor of another ward.
 *
 * Usage:
 *   node scripts/load-biloxi-ward-boundaries.mjs --dry-run
 *   node scripts/load-biloxi-ward-boundaries.mjs
 *   node scripts/load-biloxi-ward-boundaries.mjs --control=<n>   # perturb one control, watch it fail
 */
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const DRY_RUN = process.argv.includes('--dry-run');
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';

const LAYER =
  'https://services1.arcgis.com/WJhHbwy2YfOSix5p/arcgis/rest/services/Wards2022/FeatureServer/8';
const MTFCC = 'X0073';
const STATE_FIPS = '28';
const SOURCE =
  'City of Biloxi GIS, feature service "Wards2022" layer 8, ' +
  'services1.arcgis.com/WJhHbwy2YfOSix5p/.../Wards2022/FeatureServer/8, ' +
  'reached from the city\'s own ArcGIS Experience gallery at biloxi.ms.us/gis-mapping; ' +
  'agrees with the City of Biloxi "Ward Map" PDF (WARDS LAST REVISED: 12/12/2024) at all ten ' +
  'published anchors; read 2026-09-28 (MS-3)';

const EXPECTED_WARDS = [1, 2, 3, 4, 5, 6, 7];
const EXPECTED_POP_TOTAL = 49574;

/**
 * Ten anchors, every one of them from outside the feature service.
 * Seven are the polling places the city's own 2024-revised Ward Map names, one per ward.
 * Two are council members' contact addresses, published on their own ward pages.
 * One is the venue at which Ward 4 holds its ward meetings, published on the Ward 4 page.
 * Coordinates from the U.S. Census geocoder, benchmark Public_AR_Current, 2026-09-28.
 */
const ANCHORS = [
  { ward: 1, lat: 30.397458539573, lon: -88.901784280852, label: 'Lopez-Quave Public Safety Complex (Ward 1 polling place)' },
  { ward: 2, lat: 30.396534215151, lon: -88.88441766183, label: 'Dr. M.L. King Jr. Municipal Building (Ward 2 polling place)' },
  { ward: 3, lat: 30.402514903215, lon: -88.958364659924, label: 'West Biloxi Branch Library (Ward 3 polling place)' },
  { ward: 4, lat: 30.437005206445, lon: -88.966198684205, label: 'Margaret Sherry Library & Fire Station (Ward 4 polling place)' },
  { ward: 5, lat: 30.401183359486, lon: -88.984149715769, label: 'Donal Snyder Sr. Community Center (Ward 5 polling place)' },
  { ward: 6, lat: 30.431903121765, lon: -88.938675788354, label: 'A.J. Holloway Sports Complex (Ward 6 polling place)' },
  { ward: 7, lat: 30.472349899272, lon: -88.994045287721, label: 'Woolmarket City Center (Ward 7 polling place)' },
  { ward: 5, lat: 30.406316074312, lon: -88.987158552231, label: 'Paul A. Tisdale home address, Ward 5 page' },
  { ward: 6, lat: 30.437529465147, lon: -88.917847464702, label: 'Kenny Glavan home address, Ward 6 page' },
  { ward: 1, lat: 30.395195772412, lon: -88.887065616037, label: 'Biloxi City Hall, 140 Lameuse Street' },
];

const PROBES = [
  { label: 'Biloxi City Hall', lat: 30.395195772412, lon: -88.887065616037, want: 1 },
  { label: 'CONTROL: Gulfport City Hall', lat: 30.378061133316, lon: -89.080121961219, want: 0 },
  { label: 'CONTROL: Mobile, Alabama', lat: 30.6954, lon: -88.0399, want: 0 },
];

const slug = (w) => `biloxi-ms-ward-${w}`;

async function fetchLayer(url) {
  const q = `${url}/query?where=1%3D1&outFields=Id,Ward_2020,Population&returnGeometry=true&outSR=4326&f=geojson`;
  const res = await fetch(q, { headers: { 'User-Agent': 'ev-accounts/ms-slice16' } });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${q}`);
  const j = await res.json();
  if (!j || j.type !== 'FeatureCollection' || !Array.isArray(j.features) || j.features.length === 0) {
    throw new Error(`no FeatureCollection returned from ${q}`);
  }
  const crs = j.crs?.properties?.name;
  if (crs && !/4326/.test(crs)) throw new Error(`expected EPSG:4326, got ${crs}`);
  return j;
}

// ── ring geometry helpers (identical maths to SD-3's loader, deliberately) ───────────────────
const signedArea = (r) => {
  let s = 0;
  for (let i = 0, n = r.length; i < n; i++) {
    const [x1, y1] = r[i];
    const [x2, y2] = r[(i + 1) % n];
    s += x1 * y2 - x2 * y1;
  }
  return s / 2;
};
const ringHas = ([x, y], r) => {
  let inside = false;
  for (let i = 0, k = r.length - 1; i < r.length; k = i++) {
    const [xi, yi] = r[i];
    const [xj, yj] = r[k];
    if (yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
};
const polyHas = (p, rings) => {
  if (!ringHas(p, rings[0])) return false;
  for (let k = 1; k < rings.length; k++) if (ringHas(p, rings[k])) return false;
  return true;
};
// A feature may be a Polygon or a MultiPolygon; both must answer the same question.
const featureHas = (p, geom) => {
  if (geom.type === 'Polygon') return polyHas(p, geom.coordinates);
  if (geom.type === 'MultiPolygon') return geom.coordinates.some((rings) => polyHas(p, rings));
  throw new Error(`unsupported geometry type ${geom.type}`);
};
const wardOf = (f) => Number(f.properties.Ward_2020);

const bboxOf = (r) =>
  r.reduce((b, [x, y]) => [Math.min(b[0], x), Math.min(b[1], y), Math.max(b[2], x), Math.max(b[3], y)],
    [Infinity, Infinity, -Infinity, -Infinity]);
const bboxInside = (a, b) => a[0] >= b[0] && a[1] >= b[1] && a[2] <= b[2] && a[3] <= b[3];

/**
 * 🔴🔴 THE HOLES ARRIVE AS SEPARATE PARTS, NOT AS INNER RINGS, AND NOTHING IN THE FILE SAYS SO.
 *
 * This service's `f=geojson` output does NOT rewind to RFC 7946. It emits the ESRI convention
 * through the GeoJSON envelope: every part carries exactly ONE ring (measured: 162 parts across the
 * seven wards, 0 of them with more than one ring), so the inner-ring channel that GeoJSON uses to
 * express a hole is never used at all. Ward 7's two holes appear instead as two additional
 * single-ring PARTS of the MultiPolygon — the only in-band signal being that they are wound
 * counter-clockwise while the other 160 parts are clockwise, and that they lie inside part 0.
 *
 * Loaded raw, PostGIS reads each part's single ring as an exterior, so ward 7 would OVERLAP itself,
 * come back invalid, and ST_MakeValid would FILL the two holes — quietly handing ~19,000 m2 of the
 * Tchoutacabouffa River to Ward 7. (The SD-3 area guard would in fact have aborted the write rather
 * than corrupt it, which is the guard earning its keep a second time — but aborting is not loading.)
 *
 * So the parts are re-assembled here, and the classification is required to agree TWO WAYS before
 * anything is written: a part counts as a hole only if it is nested inside another part AND wound
 * against it. A part that satisfies one test but not the other aborts the run, because that would
 * mean the convention this reasoning rests on has changed.
 */
function reassemble(geom, ward) {
  const parts = geom.type === 'MultiPolygon' ? geom.coordinates : [geom.coordinates];
  for (const rings of parts) {
    if (rings.length !== 1) {
      throw new Error(
        `🔴 ward ${ward}: a part carries ${rings.length} rings. This service has always emitted ` +
        `exactly one ring per part, and the hole reassembly below assumes it. Re-measure before trusting.`,
      );
    }
  }
  const outer = parts.map((rings) => rings[0]);
  const boxes = outer.map(bboxOf);
  const areas = outer.map(signedArea);

  const parentOf = outer.map(() => -1);
  for (let i = 0; i < outer.length; i++) {
    for (let k = 0; k < outer.length; k++) {
      if (i === k || !bboxInside(boxes[i], boxes[k])) continue;
      if (outer[i].every((pt) => ringHas(pt, outer[k]))) {
        if (parentOf[i] !== -1) {
          throw new Error(`🔴 ward ${ward}: part ${i} is nested inside two parts — the shape is deeper than one level`);
        }
        parentOf[i] = k;
      }
    }
  }

  const holes = [];
  for (let i = 0; i < outer.length; i++) {
    const nested = parentOf[i] !== -1;
    const opposed = nested && Math.sign(areas[i]) !== Math.sign(areas[parentOf[i]]);
    if (nested && !opposed) {
      throw new Error(
        `🔴 ward ${ward}: part ${i} is nested inside part ${parentOf[i]} but wound the SAME way. ` +
        `That is an island inside a lake, not a hole, and this loader would drop it. Re-measure.`,
      );
    }
    if (nested) holes.push(i);
  }
  // The other half of the two-way agreement: a part wound against the majority must be nested.
  const majority = Math.sign(areas.reduce((a, v) => a + Math.sign(v), 0)) || -1;
  for (let i = 0; i < outer.length; i++) {
    if (Math.sign(areas[i]) !== majority && parentOf[i] === -1) {
      throw new Error(
        `🔴 ward ${ward}: part ${i} is wound against the other ${outer.length - 1} parts but is nested ` +
        `in none of them. The winding convention has changed; re-measure before writing.`,
      );
    }
  }

  const coords = [];
  for (let i = 0; i < outer.length; i++) {
    if (parentOf[i] !== -1) continue;
    coords.push([outer[i], ...holes.filter((h) => parentOf[h] === i).map((h) => outer[h])]);
  }
  return { geometry: { type: 'MultiPolygon', coordinates: coords }, parts: coords.length, holes: holes.length };
}

async function run() {
  // ── CONTROL 1: a bogus layer must fail. ────────────────────────────────────
  let control = false;
  try {
    await fetchLayer(LAYER.replace(/\/8$/, '/999'));
  } catch {
    control = true;
    console.log('control 1 OK — bogus layer id returned no features');
  }
  if (!control) throw new Error('🔴 CONTROL 1 DID NOT FIRE — a bogus layer returned features. Nothing below proves anything.');

  const fc = await fetchLayer(LAYER);
  console.log(`fetched ${fc.features.length} features from ${LAYER}`);

  // ── Deliberate perturbations, one per gate, so each can be watched failing. ─────────────────
  // Each touches EXACTLY ONE thing, so the gate that fires names the gate that was perturbed. If a
  // perturbation makes an EARLIER gate fire, the later gate is still unproven — MS-2's finding,
  // where two controls had to be rewritten because an earlier count shadowed the target.
  if (CONTROL === '2') fc.features.pop();
  if (CONTROL === '2b') fc.features.forEach((f, i) => { f.properties.Id = i + 1; });
  if (CONTROL === '3') fc.features[0].properties.Population += 1;
  if (CONTROL === '4') {
    // reverse ONE of ward 7's two hole parts, so it is nested but no longer wound against its parent
    const w7 = fc.features.find((f) => wardOf(f) === 7);
    w7.geometry.coordinates[1][0].reverse();
  }
  if (CONTROL === '4b') {
    // drop ward 7's holes, so the recovered-hole count disagrees with the measured 2
    const w7 = fc.features.find((f) => wardOf(f) === 7);
    w7.geometry.coordinates.splice(1, 2);
  }
  if (CONTROL === '5') {
    // 🔴 The obvious perturbation — relabel ward 5 as ward 4 — is the WRONG one: control 2 fires on
    // the ward set first and control 5 is never reached, so it would still be unproven. MS-2's
    // shadowing finding. Swap two wards' GEOMETRY instead: the labels stay {1…7}, the populations
    // stay, the rings stay, and only the anchors can tell.
    const a = fc.features.find((f) => wardOf(f) === 4);
    const b = fc.features.find((f) => wardOf(f) === 5);
    [a.geometry, b.geometry] = [b.geometry, a.geometry];
  }
  if (CONTROL === '6') {
    // 🔴 Shadowing again: REPLACING ward 5's geometry moves its anchors and control 5 fires first.
    // ADD a part over Mobile, Alabama instead, wound with the majority. Every anchor still lands
    // where it did, so only the out-of-city probe can object.
    const f5 = fc.features.find((f) => wardOf(f) === 5);
    const mobile = [[-88.1, 30.6], [-88.1, 30.8], [-87.9, 30.8], [-87.9, 30.6], [-88.1, 30.6]];
    const existing = f5.geometry.type === 'MultiPolygon' ? f5.geometry.coordinates : [f5.geometry.coordinates];
    f5.geometry = { type: 'MultiPolygon', coordinates: [...existing, [mobile]] };
  }

  // ── CONTROL 2: the ward number set, read from Ward_2020. ───────────────────
  const wards = fc.features.map(wardOf).sort((a, b) => a - b);
  if (JSON.stringify(wards) !== JSON.stringify(EXPECTED_WARDS)) {
    throw new Error(`🔴 Ward_2020 values ${JSON.stringify(wards)}, expected ${JSON.stringify(EXPECTED_WARDS)}`);
  }
  console.log(`control 2 OK — Ward_2020 is exactly ${wards.join(', ')}`);

  // ── CONTROL 2b: Id must still be unusable, which is why it is not the key. ─
  const distinctIds = new Set(fc.features.map((f) => Number(f.properties.Id))).size;
  if (distinctIds >= EXPECTED_WARDS.length) {
    throw new Error(
      `🔴 the source changed: Id now has ${distinctIds} distinct values and may look like a usable key. ` +
      `This loader deliberately keys on Ward_2020 because Id repeated (Id=6 on wards 4 and 6, Id=1 on wards 1 and 3). ` +
      `Re-read the layer and re-choose the key rather than inheriting this one.`,
    );
  }
  console.log(`control 2b OK — Id still has only ${distinctIds} distinct values for 7 wards, so it is not a key`);

  // ── CONTROL 3: the population identity. ────────────────────────────────────
  const pop = fc.features.reduce((a, f) => a + Math.round(Number(f.properties.Population)), 0);
  if (pop !== EXPECTED_POP_TOTAL) {
    throw new Error(`🔴 populations sum to ${pop}, expected ${EXPECTED_POP_TOTAL} (measured 2026-09-28)`);
  }
  console.log(`control 3 OK — populations sum to ${pop.toLocaleString()}`);

  // ── CONTROL 4: re-assemble the parts, and require the hole test to agree two ways. ─
  let totalParts = 0;
  let totalHoles = 0;
  for (const f of fc.features) {
    const w = wardOf(f);
    const r = reassemble(f.geometry, w);
    f.geometry = r.geometry; // everything below, and the write itself, uses the re-assembled shape
    totalParts += r.parts;
    totalHoles += r.holes;
    if (r.holes) console.log(`   ward ${w}: ${r.parts} part(s) and ${r.holes} hole(s) recovered from separate parts`);
  }
  if (totalHoles !== 2) {
    throw new Error(
      `🔴 recovered ${totalHoles} holes, expected 2 (both in ward 7, the Tchoutacabouffa River, measured 2026-09-28). ` +
      `The source has changed shape; re-measure before writing.`,
    );
  }
  console.log(`control 4 OK — ${totalParts} parts and ${totalHoles} holes, and the nesting and winding tests agree`);

  // ── CONTROL 5: the ten published anchors, judged on the bytes we will write. ─
  for (const a of ANCHORS) {
    const hits = fc.features.filter((f) => featureHas([a.lon, a.lat], f.geometry)).map(wardOf);
    if (hits.length !== 1 || hits[0] !== a.ward) {
      throw new Error(`🔴 anchor "${a.label}": expected ward ${a.ward}, got ${JSON.stringify(hits)}`);
    }
  }
  console.log(`control 5 OK — all ${ANCHORS.length} published anchors land in the ward the city says`);

  // ── CONTROL 6: the probes. ─────────────────────────────────────────────────
  for (const p of PROBES) {
    const hits = fc.features.filter((f) => featureHas([p.lon, p.lat], f.geometry)).map(wardOf);
    if (hits.length !== p.want) {
      throw new Error(`🔴 ${p.label}: matched ${hits.length} ward(s) ${JSON.stringify(hits)}, expected ${p.want}`);
    }
    console.log(`control 6 OK — ${p.label}: ${hits.length ? `ward ${hits[0]}` : 'no ward'}`);
  }

  // ── CONTROL 7: every ward is anchored, and no ward swallows another's anchor. ─
  for (const w of EXPECTED_WARDS) {
    const mine = ANCHORS.filter((a) => a.ward === w);
    if (mine.length === 0) throw new Error(`🔴 ward ${w} has no anchor — it is untested`);
    const f = fc.features.find((x) => wardOf(x) === w);
    const foreign = ANCHORS.filter((a) => a.ward !== w && featureHas([a.lon, a.lat], f.geometry));
    if (foreign.length) {
      throw new Error(`🔴 ward ${w} contains another ward's anchor: ${foreign.map((a) => a.label).join('; ')}`);
    }
  }
  console.log('control 7 OK — every ward carries at least one anchor of its own and none of anyone else\'s');

  if (DRY_RUN) {
    console.log('\n[dry-run] all controls passed — would write:');
    for (const f of fc.features.slice().sort((a, b) => wardOf(a) - wardOf(b))) {
      console.log(`  ${MTFCC}  ${slug(wardOf(f))}  "Biloxi Ward ${wardOf(f)}"  pop ${Math.round(Number(f.properties.Population)).toLocaleString()}`);
    }
    console.log('[dry-run] no DB writes made.');
    return;
  }

  const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();
  try {
    // ── PRE-FLIGHT: X0073 must be free, or already hold exactly our rows. ─────
    const { rows: pre } = await client.query(
      `SELECT count(*)::int AS n,
              count(*) FILTER (WHERE geo_id LIKE 'biloxi-ms-ward-%')::int AS ours
         FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
      [MTFCC],
    );
    if (pre[0].n !== pre[0].ours) {
      throw new Error(
        `🔴 ${MTFCC} already holds ${pre[0].n} rows of which only ${pre[0].ours} are Biloxi's — ` +
        `somebody else took this code. Re-read max(mtfcc) and pick the next one.`,
      );
    }

    await client.query('BEGIN');
    let inserted = 0;
    let existed = 0;
    for (const f of fc.features) {
      const w = wardOf(f);
      const r = await client.query(
        // 🔴 Every parameter is cast explicitly. Postgres deduces a parameter's type from its
        // first use, and $1/$3 appear both in the SELECT list and in the NOT EXISTS comparison.
        //
        // 🔴 ST_MakeValid IS APPLIED, AND THE REPAIR IS GATED RATHER THAN TRUSTED — SD-3's rule.
        // A MakeValid that actually redrew a ward would abort here instead of passing silently.
        // The tolerance is 1 m2 against a ward of several million.
        `WITH src AS (
           SELECT public.ST_SetSRID(public.ST_GeomFromGeoJSON($4::text), 4326) AS raw),
         fixed AS (
           SELECT raw, public.ST_MakeValid(raw) AS geom FROM src)
         INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source)
         SELECT $1::text, $2::text, $6::text, $3::text, f.geom, $5::text
         FROM fixed f
         WHERE NOT EXISTS (
           SELECT 1 FROM essentials.geofence_boundaries
            WHERE geo_id = $1::text AND mtfcc = $3::text)
           AND public.ST_GeometryType(f.geom) IN ('ST_Polygon', 'ST_MultiPolygon')
           AND abs(public.ST_Area(f.raw::geography) - public.ST_Area(f.geom::geography)) < 1.0
         RETURNING id`,
        [slug(w), `Biloxi Ward ${w}`, MTFCC, JSON.stringify(f.geometry), SOURCE, STATE_FIPS],
      );
      if (r.rowCount) {
        inserted++;
        continue;
      }
      // 🔴 A ZERO ROWCOUNT HAS TWO CAUSES AND THEY ARE NOT THE SAME FACT — SD-3's rule. Either the
      // row was already there, or the MakeValid area guard rejected it. Ask which.
      const { rows: chk } = await client.query(
        `SELECT count(*)::int AS n FROM essentials.geofence_boundaries
          WHERE geo_id = $1::text AND mtfcc = $2::text`,
        [slug(w), MTFCC],
      );
      if (chk[0].n > 0) existed++;
      else {
        throw new Error(
          `🔴 ward ${w}: not inserted and not present — ST_MakeValid changed the area by more than 1 m2, ` +
          `or returned something other than a polygon. The repair is NOT a renoding here; refusing to write.`,
        );
      }
    }

    const { rows } = await client.query(
      `SELECT count(*)::int AS n,
              count(*) FILTER (WHERE public.ST_IsValid(geometry))::int AS valid,
              count(DISTINCT public.ST_SRID(geometry))::int AS srids,
              count(DISTINCT geo_id)::int AS distinct_geo_ids
         FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
      [MTFCC],
    );
    const g = rows[0];
    if (g.n !== 7 || g.valid !== 7 || g.srids !== 1 || g.distinct_geo_ids !== 7) {
      throw new Error(
        `🔴 post-write gate: ${g.n} rows, ${g.valid} valid, ${g.srids} distinct SRIDs, ` +
        `${g.distinct_geo_ids} distinct geo_ids — expected 7/7/1/7`,
      );
    }

    // 🔴 POST-WRITE ANCHOR RE-CHECK, IN THE DATABASE. Control 5 judged the bytes in memory with our
    // own point-in-polygon. This asks PostGIS the same question of the rows actually stored, so a
    // defect introduced by ST_GeomFromGeoJSON or ST_MakeValid cannot slip past.
    for (const a of ANCHORS) {
      const { rows: hit } = await client.query(
        `SELECT geo_id FROM essentials.geofence_boundaries
          WHERE mtfcc = $1
            AND public.ST_Contains(geometry, public.ST_SetSRID(public.ST_MakePoint($2, $3), 4326))`,
        [MTFCC, a.lon, a.lat],
      );
      if (hit.length !== 1 || hit[0].geo_id !== slug(a.ward)) {
        throw new Error(
          `🔴 post-write anchor "${a.label}": PostGIS returned ${JSON.stringify(hit.map((h) => h.geo_id))}, ` +
          `expected exactly ${slug(a.ward)}`,
        );
      }
    }
    console.log(`post-write OK — all ${ANCHORS.length} anchors re-checked in PostGIS`);

    await client.query('COMMIT');
    console.log(`\n✅ inserted ${inserted}, already existed ${existed}; ${MTFCC} now holds 7 valid polygons in one SRID.`);
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    await client.end();
  }
}

run().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
