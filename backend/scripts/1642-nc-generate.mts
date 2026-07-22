/**
 * 1642-nc-generate.mts — Phase 164.2-02: North Carolina enacted-2025 congressional
 * districts -> essentials.geofence_boundaries as mtfcc='G5200V26' (14 rows, 3701-3714).
 *
 * PROVENANCE: North Carolina General Assembly redistricting, enacted congressional plan
 *   SL 2025-95 (Senate Bill 249), enacted 2025-10-22, effective for the 2026 elections.
 *   https://www.ncleg.gov/redistricting
 *   resource "SL 2025-95 - Shapefile" (SL 2025-95.shp, 14 features, field `DISTRICT`
 *   as string 1..14, NAD_1983 StatePlane North Carolina).
 *   https://webservices.ncleg.gov/ViewBillDocument/2025/7667/0/SL%202025-95%20-%20Shapefile
 * REPROJECTION (EPSG:4326) via GDAL 3.12:
 *   PROJ_LIB="/c/Program Files/GDAL/projlib" ogr2ogr -f GeoJSON -t_srs EPSG:4326 \
 *     .tmp-1642-nc/nc_4326.geojson ".tmp-1642-nc/ext/SL 2025-95.shp"
 * NEW-map identity anchor: Morehead City (-76.7261,34.7226) OLD 3703 -> NEW 3701.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/1642-nc-generate.mts --dry-run
 *   npx tsx scripts/1642-nc-generate.mts
 *
 * mtfcc='G5200V26'; ON CONFLICT (geo_id,mtfcc) DO NOTHING; geo_districts NOT touched (D-04).
 */
import { runImport } from './1642-import-core.mts';

await runImport({
  state: 'NC',
  stateFips: '37',
  expected: 14,
  source: 'nc_ncga_2025',
  geojsonPath: '.tmp-1642-nc/nc_4326.geojson',
  districtCandidates: ['DISTRICT', 'District', 'district', 'DISTRICTNO', 'DIST_NUM'],
  anchor: { name: 'Morehead City', lon: -76.7261, lat: 34.7226, expectNew: '3701', expectOld: '3703' },
});
