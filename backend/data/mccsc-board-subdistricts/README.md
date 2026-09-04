# MCCSC board-subdistrict pilot

Makes an address resolve to **one** Monroe County Community School Corporation (MCCSC)
board member instead of all seven. Pilot for the wider school-board-subdistrict rollout.

## The problem

MCCSC elects 7 trustees by single-member board district. Our data held only the
whole-corporation TIGER outline (`essentials.districts` geo_id `1800630`, mtfcc `G5420`),
with all 7 offices on that one row. An address covered the whole corporation, so the
lookup returned all 7. (Confirmed 2026-09-03: no board-subdistrict geometry existed in any
of the four geometry tables — `geofence_boundaries`, `geo_districts`,
`inform.district_boundaries`, `verification_quests`.)

## The fix (data only — no backend code change)

Load one polygon + one sub-district per board district and repoint each office at it.
`mtfcc='X0002'` is the designated "school_subdistrict" layer, already handled by
`districtQueries.ts` (address match) and `essentialsBrowseService.ts` (browse). It had
zero rows until this pilot.

After load, a point covers the whole-corp `G5420` polygon (→ corp district, now 0 offices)
**and** exactly one `X0002` sub-district (→ its 1 office) → the lookup returns one member.

## Source (authoritative)

Monroe County election-office GIS, ArcGIS Online — layer 15 "School Board Districts":
`https://services1.arcgis.com/nYfGJ9xFTKW6VPqW/arcgis/rest/services/Monroe_County_Election_Map_Current_WFL1/FeatureServer/15`
Field `schlbrd` = `1`..`7` (MCCSC) + `RBBSC` (excluded — different corporation).
Registered in `docs/data-sources/boundary-source-registry.md`.

Verified 2026-09-03 (point-in-polygon, each returns exactly one district):
`-86.606,39.145 → 3` (matches profile.empowered.vote), `downtown → 6`, `east → 1`,
`south → 2`, `northwest → RBBSC`.

## Run order

```bash
cd ev-accounts/backend
npx tsx scripts/fetch-mccsc-board-district-polygons.ts     # writes mccsc-board-districts.geojson
npx tsx scripts/import-mccsc-board-district-polygons.ts --check   # read-only preview
npx tsx scripts/import-mccsc-board-district-polygons.ts     # load (one transaction, idempotent)
psql "$DATABASE_URL" -f scripts/verify-mccsc-board-subdistricts.sql
```

`mccsc-board-districts.geojson` in this folder was already captured 2026-09-03, so the
import can run without re-fetching.

## Open items before / after apply

- **government_body_name on sub-districts.** The `government_bodies` join keys on
  `d.geo_id`, which is now the sub-district geo_id, not `1800630`. Sub-districts will show
  an empty `government_body_name` and group by `government_name` instead. Cosmetic; confirm
  the School Board tab still labels the body correctly, and add a `government_bodies` alias
  for the sub-district geo_ids if needed.
- **Corp-level browse.** With offices moved to sub-districts, confirm a browse of MCCSC
  still lists all 7 (it resolves via chamber→government, not the corp district geo_id).
- **Rollback.** `DELETE FROM essentials.geofence_boundaries WHERE geo_id LIKE '1800630-board-d%';`
  then repoint the 7 offices back to `1800630` and `DELETE` the sub-district rows.
