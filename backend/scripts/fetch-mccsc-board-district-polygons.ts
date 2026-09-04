/**
 * fetch-mccsc-board-district-polygons.ts — Fetch the 7 Monroe County Community
 * School Corporation (MCCSC) board-district polygons and write them to disk as GeoJSON.
 *
 * WHY: MCCSC elects 7 trustees by single-member board district, but essentials only
 * held the whole-corporation TIGER outline (geo_id 1800630, G5420). An address therefore
 * matched the whole corporation and returned all 7 members. These per-district polygons
 * let the address→official lookup narrow to one seat (loaded as mtfcc X0002 — the
 * designated "school_subdistrict" layer already wired into districtQueries.ts and
 * essentialsBrowseService.ts).
 *
 * SOURCE (authoritative — Monroe County's own election-office GIS, ArcGIS Online):
 *   https://services1.arcgis.com/nYfGJ9xFTKW6VPqW/arcgis/rest/services/Monroe_County_Election_Map_Current_WFL1/FeatureServer/15
 *   Layer 15 "School Board Districts". Field `schlbrd` = '1'..'7' (MCCSC) plus 'RBBSC'
 *   (Richland-Bean Blossom — a DIFFERENT corporation, deliberately excluded here).
 *   Behind the public election map experience 47d72e9b0d60426f98ffb5ed54251a92.
 *   Registered in docs/data-sources/boundary-source-registry.md.
 *   Queried with outSR=4326 & f=geojson, so no reprojection step is needed.
 *
 * VERIFIED 2026-09-03: point-in-polygon returns exactly one district per point
 *   (-86.606,39.145→3, downtown→6, east→1, south→2; NW→RBBSC, correctly excluded).
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/fetch-mccsc-board-district-polygons.ts           # fetch + write
 *   npx tsx scripts/fetch-mccsc-board-district-polygons.ts --check   # fetch + report only
 *
 * Output: backend/data/mccsc-board-subdistricts/mccsc-board-districts.geojson
 *   (consumed by import-mccsc-board-district-polygons.ts)
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const LAYER_URL =
  'https://services1.arcgis.com/nYfGJ9xFTKW6VPqW/arcgis/rest/services/' +
  'Monroe_County_Election_Map_Current_WFL1/FeatureServer/15/query';

const OUT_PATH = path.resolve(
  __dirname,
  '..',
  'data',
  'mccsc-board-subdistricts',
  'mccsc-board-districts.geojson',
);

const EXPECTED = 7;
const CHECK_ONLY = process.argv.includes('--check');

interface Feature {
  type: string;
  geometry: { type: string; coordinates: unknown } | null;
  properties: { schlbrd?: string; [k: string]: unknown };
}
interface FeatureCollection {
  type: string;
  features: Feature[];
}

async function main(): Promise<void> {
  // MCCSC districts only (schlbrd 1..7). RBBSC is a separate corporation — excluded.
  const where = encodeURIComponent("schlbrd IN ('1','2','3','4','5','6','7')");
  const url =
    `${LAYER_URL}?where=${where}` +
    `&outFields=${encodeURIComponent('schlbrd')}` +
    `&returnGeometry=true&outSR=4326&f=geojson`;

  console.error(`[mccsc-fetch] GET ${url}`);
  const res = await fetch(url);
  if (!res.ok) throw new Error(`ArcGIS query failed: HTTP ${res.status}`);

  const geojson = (await res.json()) as FeatureCollection;
  if (geojson.type !== 'FeatureCollection' || !Array.isArray(geojson.features)) {
    throw new Error('Response is not a valid GeoJSON FeatureCollection');
  }

  const nums = geojson.features
    .map((f) => f.properties?.schlbrd)
    .filter((s): s is string => typeof s === 'string')
    .sort();
  const missingGeom = geojson.features.filter((f) => !f.geometry).length;

  console.error(`[mccsc-fetch] features: ${geojson.features.length} (schlbrd: ${nums.join(',')})`);
  if (geojson.features.length !== EXPECTED) {
    throw new Error(`Expected ${EXPECTED} MCCSC districts, got ${geojson.features.length}`);
  }
  if (new Set(nums).size !== EXPECTED) {
    throw new Error(`Expected districts 1..7 exactly once; got [${nums.join(',')}]`);
  }
  if (missingGeom > 0) {
    throw new Error(`${missingGeom} feature(s) missing geometry`);
  }

  if (CHECK_ONLY) {
    console.error('[mccsc-fetch] --check: OK, not writing.');
    return;
  }

  fs.mkdirSync(path.dirname(OUT_PATH), { recursive: true });
  fs.writeFileSync(OUT_PATH, JSON.stringify(geojson));
  console.error(`[mccsc-fetch] wrote ${OUT_PATH} (${fs.statSync(OUT_PATH).size} bytes)`);
}

main().catch((err) => {
  console.error(`[mccsc-fetch] FAIL: ${(err as Error).message}`);
  process.exit(1);
});
