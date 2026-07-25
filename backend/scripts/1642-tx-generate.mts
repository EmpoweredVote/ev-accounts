/**
 * 1642-tx-generate.mts — Phase 164.2-02: Texas enacted-2026 congressional districts
 * (PlanC2333) -> essentials.geofence_boundaries as mtfcc='G5200V26' (38 rows, 4801-4838).
 *
 * PROVENANCE: Texas Legislative Council Capitol Data Portal, dataset PLANC2333
 *   https://data.capitol.texas.gov/dataset/planc2333
 *   resource PLANC2333.zip (PLANC2333.shp, 38 features, field `District` 1..38,
 *   NAD_1983 Lambert Conformal Conic). PlanC2333 is the congressional plan enacted by
 *   the 89th Legislature, 2nd C.S. (2025), in effect for the 2026 primaries.
 * REPROJECTION (EPSG:4326) via GDAL 3.12:
 *   PROJ_LIB="/c/Program Files/GDAL/projlib" ogr2ogr -f GeoJSON -t_srs EPSG:4326 \
 *     .tmp-1642-tx/planc2333_4326.geojson .tmp-1642-tx/ext/PLANC2333/PLANC2333.shp
 * NEW-map identity anchor: Liberty (-94.7955,30.0577) OLD 4836 -> NEW 4809.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/1642-tx-generate.mts --dry-run
 *   npx tsx scripts/1642-tx-generate.mts
 *
 * mtfcc='G5200V26'; ON CONFLICT (geo_id,mtfcc) DO NOTHING; geo_districts NOT touched (D-04).
 */
import { runImport } from './1642-import-core.mts';

await runImport({
  state: 'TX',
  stateFips: '48',
  expected: 38,
  source: 'tx_tlc_planc2333_2026',
  geojsonPath: '.tmp-1642-tx/planc2333_4326.geojson',
  districtCandidates: ['District', 'DISTRICT', 'district', 'DISTRICTNO', 'DIST_NUM'],
  anchor: { name: 'Liberty', lon: -94.7955, lat: 30.0577, expectNew: '4809', expectOld: '4836' },
});
