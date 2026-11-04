#!/usr/bin/env node
/**
 * load-jackson-ward-boundaries.mjs — Jackson, MS deep seed.
 *
 * Builds Jackson's seven City Council ward polygons and inserts them into
 *
 *   essentials.geofence_boundaries  geo_id='jackson-ms-ward-1' … '-7', mtfcc='X0085'
 *
 * Writes ONLY to essentials.geofence_boundaries. The structure migration (CC_0320) creates the
 * districts and their offices and REFUSES TO RUN if these seven boundaries are absent — an office
 * on a district with no polygon is unreachable by any address, and NOTHING ERRORS.
 *
 * ⚠ THE MAYOR NEEDS NO POLYGON. Jackson's mayor is elected citywide, so the structure migration
 * hangs that office on the TIGER place boundary 2836000 / G4110 already in production. Seven wards,
 * one seat each, eight offices.
 *
 * ── X0085, AND WHY IT IS NOT COUNTED ─────────────────────────────────────────────────────────
 * `max(mtfcc)` over BOTH essentials.geofence_boundaries and essentials.districts read X0084 on
 * 2026-10-31, in the same session as this write. An X code has no allocator, so it is read from
 * production and used immediately. The pre-flight re-reads it and aborts if anything already
 * occupies X0085 with rows that are not ours.
 *
 * ── 🔴🔴 THE CITY PUBLISHES TWO WARD LAYERS AND ITS OWN ORG HOSTS BOTH ────────────────────────
 * This is the Boise defect (two council-district maps, the dead one still reachable) in a new city:
 *
 *     operative   Jackson_Adopted_Wards_2024/FeatureServer/0    edited 2025-02-25
 *     superseded  Jackson_Ward_Boundary_WFL1/FeatureServer/2    edited 2023-06-15
 *
 * 🟢 UNLIKE BOISE, A CHEAP CHECK SEPARATES THEM, AND IT IS AN ARITHMETIC IDENTITY. The 2024 layer's
 * seven ward populations sum to 153,701, which is Jackson city's 2020 POP100. The superseded layer
 * sums to 173,514, the 2010 count, and carries its own IDEAL_VALU of 24,788 (×7 = 173,516), so it
 * corroborates its own vintage. Control 4 re-fetches the census number from TIGERweb rather than
 * trusting the constant below — a hard-coded identity proves only that somebody typed it once.
 *
 * ── 🔴 THE NUMBERING IS PROVED, NOT READ OFF THE ATTRIBUTE ────────────────────────────────────
 * Mississippi has handed this programme a bad district-number field twice: Biloxi's `Id` REPEATED
 * (MS-3) and Harrison County's `DIST_ID` was a clean PERMUTATION of exactly the right five values
 * (MS-4), which would have sent voters in four of five districts to the wrong supervisor. Neither a
 * count, a distinctness test nor a null check sees either defect.
 *
 * Control 6 overlaps each NEW ward against every OLD ward in PostGIS. A ward redraw moves
 * boundaries; it does not renumber wards, so new Ward N must occupy substantially the same ground
 * as old Ward N. Measured: the diagonal is strongest for 7 of 7 (99.9, 97.3, 86.2, 97.8, 88.0,
 * 84.3, 94.4 per cent) and every off-diagonal is small. The same comparison with the labels rotated
 * goes 0 of 7. `scripts/verify-jackson-ward-numbering.mjs` is the standalone form.
 *
 * ⚠ A STREET-LABEL TEST WAS TRIED FIRST AND IS NOT IN THE REPO. The idea was that a street printed
 * on Ward N's published map lies in Ward N. It scored 66 per cent and appeared to indict wards 3, 5
 * and 7. The mechanism was the fault: measured, only 198 of 1,998 TIGER road names appear on exactly
 * one ward map and most appear on two to four, because each map draws its neighbours for context.
 * A METRIC THAT DOES NOT SEPARATE IS A RANKING, NOT A GATE. It was discarded rather than tuned.
 *
 * ── 🔴 THE CRS TRAP ───────────────────────────────────────────────────────────────────────────
 * The service stores Web Mercator (wkid 102100 / 3857). It is fetched with outSR=4326 and control 5
 * asserts the coordinate range, because a polygon can be valid, correctly shaped and in the wrong
 * CRS while every geometric check passes — Holladay's five wards were metres tagged SRID 4326 and
 * matched no address at all.
 *
 * Controls, all of which must fire before any row is written:
 *   1. a bogus layer id must fail to return features;
 *   2. the ward numbers must be exactly {1..7} on `Ward`;
 *   3. `District` and `Name` must agree with `Ward` on EVERY row, read row by row;
 *   4. the population identity, against a figure fetched live from TIGERweb;
 *   5. the coordinate range, after reprojection;
 *   6. the cross-plan numbering overlap against the superseded layer;
 *   7. out-of-city probes return no ward, and each ward's interior point returns only itself.
 *
 *   node scripts/load-jackson-ward-boundaries.mjs --dry-run
 *   node scripts/load-jackson-ward-boundaries.mjs --control=<n>   # perturb one control, watch it fail
 */
import pg from 'pg';

const DRY_RUN = process.argv.includes('--dry-run');
const CONTROL = (process.argv.find((a) => a.startsWith('--control=')) || '').split('=')[1] || '';

const MTFCC = 'X0085';
const STATE_FIPS = '28';
const SOURCE = 'City of Jackson GIS, Jackson_Adopted_Wards_2024 (AGOL org n0wqzAPJddc1vROD), fetched 2026-10-31';
const LAYER = 'https://services2.arcgis.com/n0wqzAPJddc1vROD/arcgis/rest/services/Jackson_Adopted_Wards_2024/FeatureServer/0';
const OLD_LAYER = 'https://services2.arcgis.com/n0wqzAPJddc1vROD/arcgis/rest/services/Jackson_Ward_Boundary_WFL1/FeatureServer/2';
const PLACE_GEOID = '2836000';
const TIGERWEB_PLACES =
  'https://tigerweb.geo.census.gov/arcgis/rest/services/Census2020/Places_CouSub_ConCity_SubMCD/MapServer/4';

const slug = (w) => `jackson-ms-ward-${w}`;

/**
 * A FIXED point just north of Jackson's city limits. No ward may contain it.
 *
 * 🔴 IT IS A CONSTANT ON PURPOSE, AND THE FIRST VERSION WAS NOT. That version computed the halo
 * from the ward set's own bounding box, so when the control translated every ward northwards the
 * halo translated with them and the gate could never fire — A CONTROL DERIVED FROM THE DATA UNDER
 * TEST MOVES WITH THE TAMPER. The clean run measures Jackson's northern edge at lat 32.41249, so
 * this point lies outside every ward and stays there whatever the fetched geometry does.
 */
const HALO = { label: 'CONTROL: fixed point north of the city limits', lon: -90.19, lat: 32.43, want: 0 };

/** Out-of-city probes. `want: 0` means no ward may contain the point. */
const PROBES = [
  { label: 'CONTROL: Gulfport City Hall', lat: 30.378061, lon: -89.080122, want: 0 },
  { label: 'CONTROL: Mobile, Alabama', lat: 30.6954, lon: -88.0399, want: 0 },
  { label: 'CONTROL: Biloxi City Hall', lat: 30.3960, lon: -88.8853, want: 0 },
];

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0.0.0 Safari/537.36';

async function getJson(url) {
  const r = await fetch(url, { headers: { 'User-Agent': UA } });
  const t = await r.text();
  try {
    return JSON.parse(t);
  } catch {
    // 🔴 A CLEAN HTTP 200 LIES. api.census.gov now answers 200 with an HTML "Missing Key" page,
    // which JSON.parse turns into a thrown error rather than a clear refusal. Say which it was.
    throw new Error(`not JSON from ${url} (HTTP ${r.status}, ${t.length} bytes): ${t.slice(0, 120)}`);
  }
}

const ringsOf = (geom) => {
  if (geom.type === 'Polygon') return geom.coordinates;
  if (geom.type === 'MultiPolygon') return geom.coordinates.flat();
  throw new Error(`unexpected geometry ${geom.type}`);
};

function pointInRings(x, y, rings) {
  let inside = false;
  for (const ring of rings) {
    for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      const xi = ring[i][0];
      const yi = ring[i][1];
      const xj = ring[j][0];
      const yj = ring[j][1];
      if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
    }
  }
  return inside;
}

const wardOf = (f) => Number(f.properties.Ward);

async function run() {
  // ── CONTROL 1: a bogus layer must fail. ──────────────────────────────────────
  let control1Fired = false;
  try {
    const bogus = await getJson(
      `${LAYER.replace('/FeatureServer/0', '/FeatureServer/97')}/query?where=1%3D1&outFields=*&f=geojson`,
    );
    if (!bogus.features || !bogus.features.length) control1Fired = true;
  } catch {
    control1Fired = true;
  }
  if (!control1Fired) {
    throw new Error('🔴 CONTROL 1 DID NOT FIRE — a bogus layer returned features. Nothing below proves anything.');
  }
  console.log('CONTROL 1 ✅ a bogus layer returns nothing, so the fetch can report absence');

  const fc = await getJson(`${LAYER}/query?where=1%3D1&outFields=*&outSR=4326&f=geojson`);
  if (!fc.features || fc.features.length !== 7) {
    throw new Error(`🔴 expected 7 ward features, got ${fc.features ? fc.features.length : 'none'}`);
  }

  // ── tampers, one per control ─────────────────────────────────────────────────
  if (CONTROL === '2') fc.features[0].properties.Ward = 9;
  if (CONTROL === '3') fc.features[2].properties.District = 'WARD6';
  if (CONTROL === '4') fc.features[0].properties.Population += 1;
  if (CONTROL === '5') {
    // metres tagged as degrees — the Holladay defect
    for (const f of fc.features) {
      const walk = (c) => (typeof c[0] === 'number' ? ((c[0] *= 100000), (c[1] *= 100000)) : c.forEach(walk));
      walk(f.geometry.coordinates);
    }
  }
  if (CONTROL === '6') {
    // 🔴 THE TAMPER MUST ROTATE ALL THREE FIELDS TOGETHER, OR CONTROL 3 SHADOWS THIS ONE.
    // A first version rotated `Ward` alone; control 3 caught the inconsistency and control 6 was
    // never reached, so it looked tested and was not. That is also the REALISTIC defect: Harrison
    // County's DIST_ID permutation was perfectly consistent WITHIN each row, which is exactly why
    // no single-row check could see it and only a comparison against another plan can.
    const nums = fc.features.map((f) => f.properties.Ward);
    const snapshot = fc.features.map((f) => ({ ...f.properties }));
    fc.features.forEach((f, i) => {
      const src = snapshot[(i + 1) % snapshot.length];
      f.properties.Ward = nums[(i + 1) % nums.length];
      f.properties.District = src.District;
      f.properties.Name = src.Name;
      f.properties.Population = src.Population;
    });
  }
  if (CONTROL === '7') {
    // 🔴 A SMALL TRANSLATION, NOT A BIG ONE. A first version moved the wards onto the Gulf coast;
    // control 5's "degrees, but not Mississippi" box caught it first and shadowed this gate. The
    // shift below stays inside that box and inside the state, and is caught only by the halo probe.
    for (const f of fc.features) {
      const walk = (c) => (typeof c[0] === 'number' ? (c[1] += 0.05) : c.forEach(walk));
      walk(f.geometry.coordinates);
    }
  }

  // ── CONTROL 2: the ward number set, read from `Ward`. ────────────────────────
  const wards = fc.features.map(wardOf).sort((a, b) => a - b);
  if (JSON.stringify(wards) !== JSON.stringify([1, 2, 3, 4, 5, 6, 7])) {
    throw new Error(`🔴 CONTROL 2: ward numbers are ${JSON.stringify(wards)}, expected 1..7`);
  }
  console.log('CONTROL 2 ✅ ward numbers are exactly {1..7}');

  // ── CONTROL 3: three fields must agree, ROW BY ROW. ──────────────────────────
  // 🔴 Harrison County's DIST_ID was a clean permutation that passed every aggregate test. Only
  // reading the rows catches that class, so the rows are read.
  for (const f of fc.features) {
    const w = wardOf(f);
    const d = String(f.properties.District || '').toUpperCase().replace(/\s+/g, '');
    const n = String(f.properties.Name || '').toUpperCase().replace(/\s+/g, '');
    if (d !== `WARD${w}` || n !== `WARD${w}`) {
      throw new Error(`🔴 CONTROL 3: Ward=${w} but District="${f.properties.District}" Name="${f.properties.Name}"`);
    }
  }
  console.log('CONTROL 3 ✅ Ward, District and Name agree on all 7 rows');

  // ── CONTROL 4: the population identity, measured not assumed. ────────────────
  const pop = fc.features.reduce((s, f) => s + Number(f.properties.Population || 0), 0);
  const tw = await getJson(
    `${TIGERWEB_PLACES}/query?where=GEOID%3D%27${PLACE_GEOID}%27&outFields=NAME,GEOID,POP100&returnGeometry=false&f=json`,
  );
  const census = Number(tw.features && tw.features[0] && tw.features[0].attributes.POP100);
  if (!Number.isFinite(census) || census <= 0) {
    throw new Error('🔴 CONTROL 4: TIGERweb did not return a population — a connection failure is not an absence');
  }
  if (pop !== census) {
    throw new Error(
      `🔴 CONTROL 4: ward populations sum to ${pop.toLocaleString()} but Jackson city's 2020 POP100 is ` +
      `${census.toLocaleString()}. The superseded 2013 plan sums to 173,514; check WHICH LAYER this is.`,
    );
  }
  console.log(`CONTROL 4 ✅ wards sum to ${pop.toLocaleString()} = TIGERweb 2020 POP100 for place ${PLACE_GEOID}`);

  // ── CONTROL 5: the coordinate range, after reprojection. ─────────────────────
  const coords = [];
  for (const f of fc.features) {
    const walk = (c) => (typeof c[0] === 'number' ? coords.push(c) : c.forEach(walk));
    walk(f.geometry.coordinates);
  }
  const lons = coords.map((c) => c[0]);
  const lats = coords.map((c) => c[1]);
  const lo = Math.min(...lons);
  const hi = Math.max(...lons);
  const la = Math.min(...lats);
  const lb = Math.max(...lats);
  if (lo < -180 || hi > 180 || la < -90 || lb > 90) {
    throw new Error(
      `🔴 CONTROL 5: coordinates out of degree range (lon ${lo}..${hi}, lat ${la}..${lb}) — ` +
      'this is projected, not WGS84. Holladay shipped exactly this and matched no address.',
    );
  }
  if (lo < -91 || hi > -89 || la < 31.5 || lb > 33) {
    throw new Error(`🔴 CONTROL 5: degrees, but not Mississippi (lon ${lo}..${hi}, lat ${la}..${lb})`);
  }
  console.log(`CONTROL 5 ✅ lon ${lo.toFixed(5)}..${hi.toFixed(5)}, lat ${la.toFixed(5)}..${lb.toFixed(5)} — real degrees over Jackson`);

  // ── CONTROL 7 (in memory): probes and per-ward identity. ─────────────────────
  const polys = fc.features.map((f) => ({ w: wardOf(f), rings: ringsOf(f.geometry) }));
  const whichWard = (lon, lat) => polys.filter((p) => pointInRings(lon, lat, p.rings)).map((p) => p.w);

  // HALO first: it catches a SMALL displacement of the whole set, which the named out-of-city
  // probes cannot — a translation big enough to reach Gulfport trips the coordinate box first.
  for (const p of [HALO, ...PROBES]) {
    const got = whichWard(p.lon, p.lat);
    if (got.length !== p.want) {
      throw new Error(`🔴 CONTROL 7: ${p.label} returned wards ${JSON.stringify(got)}, expected ${p.want}`);
    }
  }
  for (const p of polys) {
    const ring = p.rings.reduce((a, b) => (b.length > a.length ? b : a));
    const cx = ring.reduce((s, c) => s + c[0], 0) / ring.length;
    const cy = ring.reduce((s, c) => s + c[1], 0) / ring.length;
    const got = whichWard(cx, cy);
    if (got.length !== 1 || got[0] !== p.w) {
      throw new Error(`🔴 CONTROL 7: ward ${p.w}'s own interior point resolved to ${JSON.stringify(got)}`);
    }
  }
  console.log(`CONTROL 7 ✅ halo + ${PROBES.length} out-of-city probes return no ward; all 7 interior points return only their own`);

  const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();
  try {
    // ── CONTROL 6: cross-plan numbering, in PostGIS, before anything is written. ─
    const oldFc = await getJson(`${OLD_LAYER}/query?where=1%3D1&outFields=*&outSR=4326&f=geojson`);
    if (!oldFc.features || oldFc.features.length !== 7) {
      throw new Error('🔴 CONTROL 6: the superseded layer did not return 7 wards — cannot check the numbering');
    }
    let diag = 0;
    const matrix = [];
    for (const f of fc.features.slice().sort((a, b) => wardOf(a) - wardOf(b))) {
      const w = wardOf(f);
      const self = await client.query('SELECT public.ST_Area(public.ST_GeomFromGeoJSON($1)::geography) AS a', [
        JSON.stringify(f.geometry),
      ]);
      let best = { n: null, v: -1 };
      const row = [];
      for (const o of oldFc.features.slice().sort((a, b) => Number(a.properties.Ward_) - Number(b.properties.Ward_))) {
        const r = await client.query(
          `SELECT public.ST_Area(public.ST_Intersection(
             public.ST_MakeValid(public.ST_GeomFromGeoJSON($1)),
             public.ST_MakeValid(public.ST_GeomFromGeoJSON($2)))::geography) AS a`,
          [JSON.stringify(f.geometry), JSON.stringify(o.geometry)],
        );
        const pct = (Number(r.rows[0].a) / Number(self.rows[0].a)) * 100;
        row.push(pct.toFixed(1).padStart(6));
        if (pct > best.v) best = { n: Number(o.properties.Ward_), v: pct };
      }
      matrix.push(`  Ward ${w} ${row.join('')}  -> strongest old ward ${best.n}${best.n === w ? ' ✅' : ' 🔴'}`);
      if (best.n === w) diag++;
    }
    console.log(matrix.join('\n'));
    if (diag !== 7) {
      throw new Error(
        `🔴 CONTROL 6: the numbering carries across the two plans for only ${diag}/7 wards. ` +
        'Harrison County shipped a clean permutation; read the rows before writing.',
      );
    }
    console.log('CONTROL 6 ✅ new Ward N overlaps old Ward N most, 7/7 — the numbering carries across plans');

    if (DRY_RUN) {
      console.log('\n[dry-run] all controls passed — would write:');
      for (const f of fc.features.slice().sort((a, b) => wardOf(a) - wardOf(b))) {
        console.log(
          `  ${MTFCC}  ${slug(wardOf(f))}  "Jackson Ward ${wardOf(f)}"  ` +
          `pop ${Number(f.properties.Population).toLocaleString()}`,
        );
      }
      console.log('[dry-run] no DB writes made.');
      return;
    }

    // ── PRE-FLIGHT: X0085 must be free, or already hold exactly our rows. ───────
    const { rows: pre } = await client.query(
      `SELECT count(*)::int AS n,
              count(*) FILTER (WHERE geo_id LIKE 'jackson-ms-ward-%')::int AS ours
         FROM essentials.geofence_boundaries WHERE mtfcc = $1`,
      [MTFCC],
    );
    if (pre[0].n !== pre[0].ours) {
      throw new Error(
        `🔴 ${MTFCC} already holds ${pre[0].n} rows of which only ${pre[0].ours} are Jackson's — ` +
        'somebody else took this code. Re-read max(mtfcc) and pick the next one.',
      );
    }

    await client.query('BEGIN');
    let inserted = 0;
    let existed = 0;
    for (const f of fc.features) {
      const w = wardOf(f);
      const r = await client.query(
        // 🔴 ST_MakeValid is applied and the repair is GATED rather than trusted — SD-3's rule.
        // A MakeValid that actually redrew a ward aborts here instead of passing silently.
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
        [slug(w), `Jackson Ward ${w}`, MTFCC, JSON.stringify(f.geometry), SOURCE, STATE_FIPS],
      );
      if (r.rowCount) {
        inserted++;
        continue;
      }
      // 🔴 A ZERO ROWCOUNT HAS TWO CAUSES AND THEY ARE NOT THE SAME FACT. Ask which.
      const { rows: chk } = await client.query(
        `SELECT count(*)::int AS n FROM essentials.geofence_boundaries
          WHERE geo_id = $1::text AND mtfcc = $2::text`,
        [slug(w), MTFCC],
      );
      if (chk[0].n > 0) existed++;
      else {
        throw new Error(
          `🔴 ward ${w}: not inserted and not present — ST_MakeValid changed the area by more than 1 m², ` +
          'or returned something other than a polygon. Refusing to write.',
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

    // 🔴 POST-WRITE RE-CHECK IN THE DATABASE. The controls above judged bytes in memory with our own
    // point-in-polygon. This asks PostGIS the same questions of the rows actually stored, so a defect
    // introduced by ST_GeomFromGeoJSON or ST_MakeValid cannot slip past.
    for (const p of polys) {
      const ring = p.rings.reduce((a, b) => (b.length > a.length ? b : a));
      const cx = ring.reduce((s, c) => s + c[0], 0) / ring.length;
      const cy = ring.reduce((s, c) => s + c[1], 0) / ring.length;
      const { rows: hit } = await client.query(
        `SELECT geo_id FROM essentials.geofence_boundaries
          WHERE mtfcc = $1
            AND public.ST_Contains(geometry, public.ST_SetSRID(public.ST_MakePoint($2, $3), 4326))`,
        [MTFCC, cx, cy],
      );
      if (hit.length !== 1 || hit[0].geo_id !== slug(p.w)) {
        throw new Error(
          `🔴 post-write: ward ${p.w}'s interior point returned ${JSON.stringify(hit.map((h) => h.geo_id))}`,
        );
      }
    }
    for (const p of [HALO, ...PROBES]) {
      const { rows: hit } = await client.query(
        `SELECT geo_id FROM essentials.geofence_boundaries
          WHERE mtfcc = $1
            AND public.ST_Contains(geometry, public.ST_SetSRID(public.ST_MakePoint($2, $3), 4326))`,
        [MTFCC, p.lon, p.lat],
      );
      if (hit.length !== p.want) {
        throw new Error(`🔴 post-write probe "${p.label}" returned ${JSON.stringify(hit.map((h) => h.geo_id))}`);
      }
    }
    console.log('post-write OK — 7 interior points and 3 out-of-city probes re-checked in PostGIS');

    await client.query('COMMIT');
    console.log(`\n✅ inserted ${inserted}, already existed ${existed}; ${MTFCC} now holds 7 valid polygons in one SRID.`);
  } catch (e) {
    await client.query('ROLLBACK').catch(() => {});
    throw e;
  } finally {
    await client.end();
  }
}

run().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
