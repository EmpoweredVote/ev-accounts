# Phase 118: MA TIGER Geofencing — Discussion Log

**Date:** 2026-06-14
**Phase:** 118-ma-tiger-geofencing

## Areas Discussed

### 1. Scope

**Question:** What's in scope for Phase 118?
**Options presented:**
- State leg only (sldu+sldl TIGER + tiger_geoid backfill only)
- State leg + new cities (sldu+sldl + geofencing for 6 new MA cities)

**Decision:** State leg + new cities

**Notes:** The 6 new MA cities (Somerville, Lynn, Medford, Fall River, Waltham, New Bedford) added in migrations 581–596 also need district records + tiger_geoid linkage so Path 0 can resolve their officials.

---

### 2. New Cities Geofencing Approach

**Question:** For the 6 new MA cities — what geofencing work do they need?
**Options presented:**
- Place boundaries only (just verify geo_id linkage)
- Full district records + tiger_geoid
- Just confirm they work (smoke test only)

**Decision:** Full district records + tiger_geoid

**Notes:** Need to add any missing essentials.districts rows AND backfill tiger_geoid on them. Researcher verifies DB state first.

---

### 3. DB Preflight

**Question:** Are the MA sldu/sldl boundaries already in geofence_boundaries, or does Phase 118 need to run the TIGER loader?
**Options presented:**
- Run loader + backfill (not sure of current state)
- Already loaded — just backfill tiger_geoid

**Decision:** Run loader + backfill (not sure)

**Notes:** Since the loader is idempotent (ON CONFLICT DO NOTHING), safe to run regardless. Phase 118 runs the loader as part of its work.

---

### 4. New City District Rows

**Question:** Do the 6 new MA cities' essentials.districts rows already exist?
**Options presented:**
- Already exist — just add tiger_geoid
- Need to check — researcher should verify

**Decision:** Researcher should verify

**Notes:** Researcher queries DB to confirm district row existence before writing the plan. Phase covers both paths.

---

### 5. Verification

**Question:** What should the Phase 118 verification gate look like?
**Options presented:**
- SQL gate + Path 0 smoke tests
- SQL gate only

**Decision:** SQL gate + Path 0 smoke tests

**Notes:** Use existing verify-ma-tiger-import.sql + tiger_geoid IS NULL = 0 assertions + live point-in-polygon test for a MA address resolving to correct state rep + senator.

---

## Deferred Ideas

- MA campaign finance for new cities — separate phase
- MA school committee geofencing — separate phase
- Additional MA cities beyond the 6 in scope
