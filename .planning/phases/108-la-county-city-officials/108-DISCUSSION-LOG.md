# Phase 108: LA County City Officials — Discussion Log

**Date:** 2026-06-08
**Participants:** Chris (product), Claude (builder)

## Context

Phase 108 was defined following a live DB audit of LA County politician coverage conducted in the same session. The audit queried `essentials.politicians`, `essentials.offices`, `essentials.districts`, and `essentials.governments` to establish ground truth before scoping the work.

## DB Audit Findings (pre-discussion)

**What we have:**
- LA City: Mayor Bass + all 15 council members (CD1–CD15) via OCD IDs. City Attorney/Controller/Clerk offices exist but have zero politicians linked.
- LA County BOS: All 5 supervisors (Solis, Mitchell, Horvath, Hahn, Barger).
- 14 other LA County cities with partial council data: Long Beach (8/9 council, no Mayor), Glendale (4 council, no Mayor), Burbank (3 council, no Mayor), plus Downey, El Monte, Inglewood, Lancaster, Norwalk, Palmdale, Pasadena, Pomona, Santa Clarita, Torrance, West Covina — all with partial councils and no mayors.
- Beverly Hills + Santa Monica: office/district structure exists, zero politicians.
- Finance data: NULL for every single LA politician.

**What's missing entirely:**
- ~70+ LA County cities with government stub records but zero politician data.

## Questions and Decisions

### Area 1: City Coverage Scope

**Question:** Which cities should Phase 108 cover?

**Options presented:**
- Fill gaps only (~50 politicians)
- Fill gaps + top 10 new cities (~100–130 politicians)
- Fill gaps + top 15 new cities (~160–200 politicians)

**Decision:** Fill gaps + top 10 new cities

**10 new cities selected:** South Gate, Compton, Carson, Hawthorne, Whittier, Alhambra, Gardena, Culver City, West Hollywood, El Segundo

---

### Area 2: Completeness Standard

**Question:** For partial cities (e.g. Downey has Mayor + 2 of 5 council members), go full council or mayor-only?

**Options presented:**
- Full council + mayor (complete governing body)
- Mayor gap-fill only (faster, leaves data inconsistent)

**Decision:** Full council + mayor. Every covered city gets its complete elected governing body.

---

### Area 3: Census FIPS Geo_ids

**Question:** Populate geo_ids on district records for future geofencing, or politician records only?

**Options presented:**
- Politicians only, geo_ids deferred
- Populate geo_ids for all cities covered (FIPS place codes, no TIGER polygons)

**Decision:** Populate geo_ids. The 7-digit Census FIPS place code (format 06XXXXX) goes on `essentials.districts.geo_id` for every covered city. This enables future TIGER polygon import without another DB pass. Does NOT include polygon import — that's a separate effort.

---

## Deferred Ideas

- Stance research for LA officials — future phase (needs Phase 108 records as FK targets)
- TIGER polygon import for LA city boundaries — separate effort
- School boards / special districts — out of scope for v2.9
- Cities beyond top 10 new — future v2.10 milestone

## Next Steps

`/gsd-plan-phase 108`
