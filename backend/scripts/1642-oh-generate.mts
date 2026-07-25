/**
 * 1642-oh-generate.mts — Phase 164.2-02: Ohio enacted-2025 congressional districts
 * -> essentials.geofence_boundaries as mtfcc='G5200V26' (15 rows, 3901-3915).
 *
 * PROVENANCE: Ohio congressional plan adopted unanimously by the Ohio Redistricting
 *   Commission 2025-10-31, effective 2026-2032. Operator-provided authoritative shapefile
 *   (C:\Transparent Motivations\essentials\docs\uscongressionaldistricts-2026-2032-adopted-
 *   2025-10-31-shapefiles.zip -> Districts_2025_11_03_SHP.shp), 15 features, field
 *   `DISTRICT`, GCS_North_American_1983.
 * REPROJECTION (EPSG:4326) via GDAL 3.12:
 *   PROJ_LIB="/c/Program Files/GDAL/projlib" ogr2ogr -f GeoJSON -t_srs EPSG:4326 \
 *     .tmp-1642-oh/oh_enacted_4326.geojson ".tmp-1642-oh/ext2/Districts_2025_11_03_SHP.shp"
 * NEW-map identity anchor: Wilmington/Clinton (-83.8286,39.4453) OLD 3902 -> NEW 3901.
 *   (NOTE: the state maps.ohio.gov "Ohio_Congressional_Districts_2022_2027" service is the
 *   OLD map — it FAILS this anchor; this operator-provided adopted-2025 shapefile passes it.)
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/1642-oh-generate.mts --dry-run
 *   npx tsx scripts/1642-oh-generate.mts
 *
 * mtfcc='G5200V26'; ON CONFLICT (geo_id,mtfcc) DO NOTHING; geo_districts NOT touched (D-04).
 */
import { runImport } from './1642-import-core.mts';

await runImport({
  state: 'OH',
  stateFips: '39',
  expected: 15,
  source: 'oh_orc_2025',
  geojsonPath: '.tmp-1642-oh/oh_enacted_4326.geojson',
  districtCandidates: ['DISTRICT', 'District', 'district', 'DISTRICTNO', 'DIST_NUM'],
  anchor: { name: 'Wilmington/Clinton', lon: -83.8286, lat: 39.4453, expectNew: '3901', expectOld: '3902' },
});
