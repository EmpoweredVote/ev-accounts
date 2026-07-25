/**
 * 1642-ca-generate.mts — Phase 164.2-02: California enacted-2026 congressional districts
 * (Prop 50 / AB 604) -> essentials.geofence_boundaries as mtfcc='G5200V26' (52 rows, 0601-0652).
 *
 * PROVENANCE: "AB 604 - California Congressional Districts 2027-2032 as enacted by
 *   Proposition 50" — the Prop-50 (AB 604) map approved by voters 2025-11-04, effective
 *   for 2026 congressional elections. Operator-provided authoritative shapefile
 *   (C:\Transparent Motivations\essentials\docs\AB_604_-_California_Congressional_Districts_
 *   2027-2032_as_enacted_by_Proposition_50_view_*.zip), 52 features, field `DISTRICT`
 *   ("01".."52"), WGS_1984_Web_Mercator.
 * REPROJECTION (EPSG:4326) via GDAL 3.12:
 *   PROJ_LIB="/c/Program Files/GDAL/projlib" ogr2ogr -f GeoJSON -t_srs EPSG:4326 \
 *     .tmp-1642-ca/ca_enacted_4326.geojson ".tmp-1642-ca/ext2/AB_604_-_..._Proposition_50.shp"
 * NEW-map identity anchor: Redding (-122.3775,40.5922) OLD 0601 -> NEW 0602.
 *   (NOTE: the open data.ca.gov "Congressional Districts CA" service is the OLD 2021 CRC
 *   map — it FAILS this anchor; this operator-provided AB604 shapefile passes it.)
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/1642-ca-generate.mts --dry-run
 *   npx tsx scripts/1642-ca-generate.mts
 *
 * mtfcc='G5200V26'; ON CONFLICT (geo_id,mtfcc) DO NOTHING; geo_districts NOT touched (D-04).
 */
import { runImport } from './1642-import-core.mts';

await runImport({
  state: 'CA',
  stateFips: '06',
  expected: 52,
  source: 'ca_swdb_prop50_2026',
  geojsonPath: '.tmp-1642-ca/ca_enacted_4326.geojson',
  districtCandidates: ['DISTRICT', 'District', 'district', 'CongDist_1', 'CongDistri'],
  anchor: { name: 'Redding', lon: -122.3775, lat: 40.5922, expectNew: '0602', expectOld: '0601' },
});
