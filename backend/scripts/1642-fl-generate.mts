/**
 * 1642-fl-generate.mts — Phase 164.2-02: Florida enacted-2026 congressional districts
 * -> essentials.geofence_boundaries as mtfcc='G5200V26' (28 rows, 1201-1228).
 *
 * PROVENANCE: The Florida Senate redistricting portal, enacted congressional plan
 *   EOGPCRP2026 (Executive Office of the Governor Plan for Congressional Redistricting,
 *   signed 2026-05-04).
 *   https://www.flsenate.gov/Session/Redistricting/Congressional
 *   resource EOGPCRP2026.zip (EOGPCRP2026.shp, 28 features, field `DISTRICT` 1..28,
 *   already GCS_WGS_1984).
 * REPROJECTION (EPSG:4326 passthrough / normalize) via GDAL 3.12:
 *   PROJ_LIB="/c/Program Files/GDAL/projlib" ogr2ogr -f GeoJSON -t_srs EPSG:4326 \
 *     .tmp-1642-fl/fl_4326.geojson .tmp-1642-fl/ext/EOGPCRP2026.shp
 * NEW-map identity anchor: Frankel FL-23 zone (-80.0772,26.6097) OLD 1222 -> NEW 1223
 *   (derived at execution as a South-FL point-on-surface differential).
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/1642-fl-generate.mts --dry-run
 *   npx tsx scripts/1642-fl-generate.mts
 *
 * mtfcc='G5200V26'; ON CONFLICT (geo_id,mtfcc) DO NOTHING; geo_districts NOT touched (D-04).
 */
import { runImport } from './1642-import-core.mts';

await runImport({
  state: 'FL',
  stateFips: '12',
  expected: 28,
  source: 'fl_legislature_2026',
  geojsonPath: '.tmp-1642-fl/fl_4326.geojson',
  districtCandidates: ['DISTRICT', 'District', 'district', 'DISTRICTNO', 'DIST_NUM'],
  anchor: { name: 'Frankel FL-23 zone', lon: -80.0772, lat: 26.6097, expectNew: '1223', expectOld: '1222' },
});
