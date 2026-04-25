# Ground Truth Attestation — Kirkwood = Monroe County Council District 4

**Coordinate:** lng=-86.534947, lat=39.166646
**Address:** 200 W Kirkwood Ave, Bloomington IN 47404

---

## Source 1: Monroe County GIS FeatureServer

**URL:**
```
https://gis.co.monroe.in.us/server/rest/services/MoCo_Council_Districts/FeatureServer/0/query?geometry={"x":-86.534947,"y":39.166646,"spatialReference":{"wkid":4326}}&geometryType=esriGeometryPoint&spatialRel=esriSpatialRelIntersects&outFields=*&f=json&returnGeometry=false
```

**Raw response (attributes of matching feature):**

```json
{
  "objectIdFieldName": "OBJECTID",
  "globalIdFieldName": "GlobalID",
  "geometryType": "esriGeometryPolygon",
  "spatialReference": {"wkid": 2245, "latestWkid": 2966},
  "fields": [
    {"name": "OBJECTID", "alias": "OBJECTID", "type": "esriFieldTypeOID"},
    {"name": "CountyCouncil", "alias": "County Council", "type": "esriFieldTypeString", "length": 255},
    {"name": "Council", "alias": "Council", "type": "esriFieldTypeString", "length": 255},
    {"name": "GlobalID", "alias": "GlobalID", "type": "esriFieldTypeGlobalID", "length": 38},
    {"name": "Rep", "alias": "Rep", "type": "esriFieldTypeString", "length": 255},
    {"name": "Shape__Area", "alias": "Shape.STArea()", "type": "esriFieldTypeDouble"},
    {"name": "Shape__Length", "alias": "Shape.STLength()", "type": "esriFieldTypeDouble"}
  ],
  "features": [
    {
      "attributes": {
        "OBJECTID": 3,
        "CountyCouncil": "4",
        "Council": "Council 4",
        "GlobalID": "{C0C4EC15-5BC6-43B0-8C0C-1731CFE15808}",
        "Rep": "Jennifer Crossley",
        "Shape__Area": 0.006033001694,
        "Shape__Length": 0.5526312149
      }
    }
  ]
}
```

**Result:** `CountyCouncil="4"`, `Council="Council 4"`, `Rep="Jennifer Crossley"` — **District 4 confirmed.**

---

## Source 2: Indiana Statewide Administrative Boundaries FeatureServer

**URL:**
```
https://gisdata.in.gov/server/rest/services/Hosted/Administrative_Boundaries_of_Indiana_2024/FeatureServer/4
```

**Point-in-polygon query executed:**
```
https://gisdata.in.gov/server/rest/services/Hosted/Administrative_Boundaries_of_Indiana_2024/FeatureServer/4/query?geometry={"x":-86.534947,"y":39.166646,"spatialReference":{"wkid":4326}}&geometryType=esriGeometryPoint&spatialRel=esriSpatialRelIntersects&outFields=*&f=json&returnGeometry=false&inSR=4326
```

**Raw response (attributes of matching feature):**

```json
{
  "features": [
    {
      "attributes": {
        "source_featureid": "2",
        "source_originator": "Monroe County",
        "local_id": "2",
        "nguid": "urn:emergency:uid:gis:CCOUN:0000003:co.monroe.in.us",
        "dsplayname": "Council 4",
        "loaddate": 1722556800000,
        "SHAPE__Length": 0.5526312117654706,
        "objectid": 128,
        "SHAPE__Area": 0.0060330016984425075
      }
    }
  ],
  "exceededTransferLimit": false
}
```

**Result:** `dsplayname="Council 4"`, `source_originator="Monroe County"` — **District 4 confirmed independently.**

---

## Attestation

ATTESTATION: Kirkwood (200 W Kirkwood Ave, Bloomington IN 47404) resolves to Monroe County Council District 4 per two independent authoritative GIS sources retrieved on 2026-04-16T00:00:00Z.

Both sources agree: the correct MCC district for the Kirkwood coordinate (lng=-86.534947, lat=39.166646) is **Council 4** (Jennifer Crossley).

---

## Documentation Discrepancy

- **ROADMAP.md Phase 121 success criteria #1 wording** ("D4, not D1") is **CORRECT.** The phase title "D1→D4 binding bug" means the system was incorrectly returning all four districts (including D1 as the first) instead of D4 only.

- **GAP-REPORT.md PATTERN-004 text** ("should resolve to D1") is **INCORRECT** and will be rewritten in Plan 04. The error arose because GAP-REPORT compared the EV result against Ballotpedia's superset display, which listed D1 first — but Ballotpedia shows all 4 council districts for any Monroe County address (it is not a district-assignment tool). The authoritative district for Kirkwood is D4, not D1.

---

## Current DB State (Wave 0 Findings)

The Phase 121 diagnostic (run 2026-04-16) reveals the MCC sub-district fix was already applied to the dev DB before this phase executed:

- `essentials.geofence_boundaries` contains `geo_id='1810500004'` (D4 polygon, `mtfcc=X0001`)
- Kirkwood coordinate already resolves to exactly 1 MCC Council race: **Monroe County Council District 4**
- The `audit-112-geofence.ts` extended assertion shows `[121-geo] PASS`

Wave 1 (polygon import) and Wave 2 (office re-linking) may already be complete in the dev DB. Planner should verify scope before proceeding.
