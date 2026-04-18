---
phase: 121-county-council-d1-d4-geofence-repair
verified: 2026-04-16T12:00:00Z
status: passed
score: 6/6
overrides_applied: 0
re_verification: false
---

# Phase 121: County Council D1→D4 Geofence Repair — Verification Report

**Phase Goal:** Fix the Monroe County Council (MCC) geofence bug where all 4 MCC offices (District 1/2/3/4) were linked to the shared county-wide `geo_id='18105'` district, causing address lookups to return all 4 races instead of exactly 1.
**Verified:** 2026-04-16T12:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Smoke evidence files exist for both dev and prod | VERIFIED | `evidence/smoke-kirkwood-dev.txt` and `evidence/smoke-kirkwood-prod.txt` both present and non-empty |
| 2 | `smoke-kirkwood-prod.txt` contains `[121-geo] PASS` | VERIFIED | Line 5: `[121-geo] PASS: Kirkwood returns exactly 1 MCC Council race: Monroe County Council District 4`; `exit_code=0` on final line; no `[121-geo] FAIL` present |
| 3 | `link-monroe-county-races-to-geofences.sql` contains §2e (per-district offices) and §3f (race re-linking) blocks | VERIFIED | §2e block found at line 258 with per-district office inserts for `election-mcc-d1` through `election-mcc-d4`; §3f block found at line 334 with UPDATE re-linking MCC races to per-district offices |
| 4 | `import-mcc-district-polygons.ts` exists and references geo_ids `18105-mcc-d{N}` | VERIFIED | File exists; line 176: `` const geoId = `18105-mcc-d${N}`; ``; header comment confirms schema `geo_id='18105-mcc-d{N}'` |
| 5 | GAP-REPORT.md PATTERN-004 root cause no longer contains the incorrect D1 claim | VERIFIED | Old phrase "should resolve to County Council District 1 returns District 4" is absent (grep confirmed zero matches); new root cause text present at lines 526-535 with structural description; `**Correction (Phase 121):**` bullet added; cross-references `ground-truth-attestation.md`, `gis.co.monroe.in.us`, `gisdata.in.gov`, `Jennifer Crossley` |
| 6 | `audit-112-geofence.ts` retains `[121-geo]` assertion | VERIFIED | Lines 242-263 confirm the Kirkwood exclusivity assertion is intact; PASS/FAIL branches both present |

**Score:** 6/6 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ev-accounts/backend/scripts/diagnose-121-mcc-state.ts` | Diagnostic (read-only) | VERIFIED | File exists |
| `ev-accounts/backend/scripts/fetch-mcc-district-polygons.ts` | Polygon fetcher from Monroe County GIS FeatureServer | VERIFIED | File exists |
| `ev-accounts/backend/scripts/import-mcc-district-polygons.ts` | Idempotent importer for 4 polygons + 4 districts | VERIFIED | File exists; contains `18105-mcc-d{N}` geo_id pattern; ON CONFLICT DO NOTHING guard present |
| `ev-accounts/backend/scripts/audit-112-geofence.ts` | Smoke test with [121-geo] exclusivity check | VERIFIED | File exists; `[121-geo] PASS/FAIL` assertion at lines 249-262 |
| `ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql` | Re-linking SQL with §2e and §3f | VERIFIED | §2e and §3f blocks present; §2a updated with comment redirecting MCC districts to §2e |
| `.planning/phases/121-county-council-d1-d4-geofence-repair/evidence/smoke-kirkwood-prod.txt` | Production PASS proof | VERIFIED | `[121-geo] PASS`, `exit_code=0`, no `postgres://` leak |
| `.planning/phases/121-county-council-d1-d4-geofence-repair/evidence/smoke-kirkwood-dev.txt` | Dev PASS proof | VERIFIED | Identical structure to prod file; `[121-geo] PASS`, `exit_code=0` |
| `.planning/phases/121-county-council-d1-d4-geofence-repair/evidence/ground-truth-attestation.md` | GIS source attestation for Kirkwood = D4 | VERIFIED | Two independent source responses present (Monroe County GIS + IN statewide); both confirm District 4 |
| `.planning/GAP-REPORT.md` PATTERN-004 section | Corrected root cause + Correction bullet | VERIFIED | All required strings present; old incorrect phrase absent |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `smoke-kirkwood-prod.txt` | Production DB (`kxsdzaojfaibhuzmclfq`) | `audit-112-geofence.ts` run with prod `DATABASE_URL` | VERIFIED | SUMMARY.md confirms prod DB was the target; file contents show live multi-address audit output consistent with prod data |
| `link-monroe-county-races-to-geofences.sql` §2e | `essentials.districts` (election-mcc-d{N} rows) | JOIN on `d.district_id` | VERIFIED | SQL uses `JOIN (VALUES ('Monroe County Council District 1', 'election-mcc-d1'), ...) ON d.district_id = v.did` |
| `link-monroe-county-races-to-geofences.sql` §3f | Per-district offices | UPDATE matching `d.district_id LIKE 'election-mcc-d%'` and `o.title = r.position_name` | VERIFIED | §3f UPDATE present; first nulls existing links then re-links via per-district district_id |
| GAP-REPORT.md PATTERN-004 `**Correction:**` | `evidence/ground-truth-attestation.md` | Cross-reference in text | VERIFIED | Literal string `ground-truth-attestation.md` present at line 534 |

---

### Data-Flow Trace (Level 4)

Not applicable — this phase produced scripts and SQL (no dynamic UI rendering). The smoke test output is the functional data-flow proof: Kirkwood address → PostGIS ST_Intersects against `18105-mcc-d4` boundary → 1 race returned (Monroe County Council District 4).

---

### Behavioral Spot-Checks

| Behavior | Evidence | Status |
|----------|----------|--------|
| Kirkwood address returns exactly 1 MCC Council race | `[121-geo] PASS: Kirkwood returns exactly 1 MCC Council race: Monroe County Council District 4` in prod smoke file; `exit_code=0` | PASS |
| Kirkwood returns District 4 specifically (Jennifer Crossley) | `Bloomington City Center,Monroe County Council District 4,Democratic,Jennifer Crossley` in prod smoke CSV output | PASS |
| Other Monroe County test addresses return exactly 1 MCC district each (not all 4) | Perry Township → District 2; Clear Creek Township → District 3; Richland Township → District 3; Ellettsville → District 3; IU Campus → District 4 — all 1 result each, none return multiple MCC districts | PASS |
| No `postgres://` URL leaked into committed evidence file | grep returned zero matches | PASS |
| ROADMAP.md Phase 121 wording unchanged | SUMMARY.md explicitly states "ROADMAP.md unchanged (already correct)"; task acceptance criteria specified no ROADMAP edits | PASS |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| GEO-01 | 121-04-PLAN.md | Kirkwood address resolves to exactly 1 MCC Council race | SATISFIED | `[121-geo] PASS` in prod smoke; SUMMARY.md confirms GEO-01 closed |
| GEO-02 | 121-04-PLAN.md | That 1 race is District 4 (ground-truth per Monroe County GIS) | SATISFIED | Smoke CSV shows `Monroe County Council District 4, Jennifer Crossley` for Bloomington City Center; ground-truth-attestation.md independently confirms D4 |

---

### Anti-Patterns Found

| File | Pattern | Severity | Assessment |
|------|---------|----------|------------|
| `import-mcc-district-polygons.ts` | Pool not closed on error (WR-02 from REVIEW.md) | Warning | Operational risk in error paths only; does not affect correctness of committed data — all 4 rows were already applied to both dev and prod before this phase closed. Not a blocker. |
| `import-mcc-district-polygons.ts` | Non-atomic per-district insert loop (WR-03) | Warning | Partial-import risk on failure. Mitigated by idempotency guards + confirmed successful completion on both dev and prod. Not a blocker. |
| `audit-112-geofence.ts` | Kirkwood exclusivity check only fires for Bloomington City Center address label (WR-04) | Warning | Reduces regression coverage for other addresses. IU Campus (also Bloomington) shows District 4 in the smoke output but without an automated assertion. Future improvement only. |
| `fetch-mcc-district-polygons.ts` | Redirect loop limited to 1 hop (IN-02) | Info | Minor clarity issue. Not a crash risk for the GIS endpoints used. |

No blocker anti-patterns found. REVIEW.md warnings (WR-01 through WR-04) were all identified during the review phase. WR-01 (the core missing §2e/§3f blocks) was resolved in Plan 03; the remaining warnings are non-blocking operational quality items.

---

### Human Verification Required

None. The production smoke test captures live DB output through the audit harness, providing automated proof of goal achievement. The human checkpoint in Plan 04 Task 2 was satisfied: the developer explicitly authorized production execution ("you go ahead and run these"), and the captured evidence file confirms the result. No additional human testing is required.

---

### Gaps Summary

No gaps. All 6 observable truths are verified. The phase goal — fixing MCC D1→D4 geofence binding so address lookups return exactly 1 council race instead of all 4 — is confirmed achieved in production. Dev and prod both show `[121-geo] PASS` with `exit_code=0`. GEO-01 and GEO-02 are closed.

---

_Verified: 2026-04-16T12:00:00Z_
_Verifier: Claude (gsd-verifier)_
