---
phase: 123
slug: ward-geofencing-all-7-cities
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-16
---

# Phase 123 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | SQL assertions via Supabase execute_sql (PostGIS) |
| **Config file** | none — direct DB queries |
| **Quick run command** | `SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE city ILIKE '%<city>%'` |
| **Full suite command** | `backend/scripts/verify-phase-123.sql` (written in Plan 04) |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run per-city row count check (see Per-Task map)
- **After every plan wave:** Run full verify-phase-123.sql assertions
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 123-01-01 | 01 | 1 | MAGE-16..22 | — | N/A | sql | `SELECT COUNT(*) FROM essentials.geofence_boundaries WHERE city IN ('NEWTON','SOMERVILLE','LYNN','FALL RIVER','WALTHAM','MEDFORD','NEW BEDFORD') GROUP BY city` | ❌ W0 | ⬜ pending |
| 123-02-01 | 02 | 2 | MAGE-16,17,18,19 | T-123-D2 | Fall River has NO office re-links | sql | `SELECT COUNT(*) FROM essentials.districts WHERE state='ma' AND geo_id LIKE 'newton-ma-council-ward-%' AND tiger_geoid IS NOT NULL` | ❌ W0 | ⬜ pending |
| 123-02-02 | 02 | 2 | MAGE-18,19 | T-123-D2 | Fall River migration 709 has no UPDATE essentials.offices | sql | `SELECT COUNT(*) FROM essentials.districts WHERE state='ma' AND geo_id LIKE 'fall-river-ma-council-ward-%' AND tiger_geoid IS NOT NULL` | ❌ W0 | ⬜ pending |
| 123-03-01 | 03 | 2 | MAGE-20,21 | T-123-E1 | Medford uses geo_id '2539835' not '2540115' | sql | `SELECT COUNT(*) FROM essentials.districts WHERE state='ma' AND geo_id LIKE 'waltham-ma-council-ward-%' AND tiger_geoid IS NOT NULL` | ❌ W0 | ⬜ pending |
| 123-03-02 | 03 | 2 | MAGE-22 | — | N/A | sql | `SELECT COUNT(*) FROM essentials.districts WHERE state='ma' AND geo_id LIKE 'new-bedford-ma-council-ward-%' AND tiger_geoid IS NOT NULL` | ❌ W0 | ⬜ pending |
| 123-04-01 | 04 | 3 | MAGE-16..22 | — | All 7 MAGE assertions pass | sql | `\i backend/scripts/verify-phase-123.sql` | ❌ W0 | ⬜ pending |
| 123-04-02 | 04 | 3 | MAGE-16..22 | — | Path 0 returns correct ward councillor for each city | manual | Path 0 spot-check per city (see Plan 04 Task 2) | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test stubs or framework installation needed — all verification is via direct SQL against the live Supabase database using execute_sql.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Path 0 returns correct ward councillor for a Newton address | MAGE-16 | PostGIS ST_Contains spatial join requires a real address geocode to verify | Run `SELECT resolve_user_jurisdiction(lat, lng)` for a known Newton ward address; confirm ward councillor returned |
| Path 0 returns correct ward councillor for Somerville | MAGE-17 | Same — spatial join requires real coordinates | Same pattern for a known Somerville ward address |
| Path 0 returns correct ward councillor for Lynn | MAGE-18 | Same | Same |
| Path 0 returns ward boundary (not councillor) for Fall River | MAGE-19 | At-large city — verify boundary polygon exists but no ward councillor re-link | Confirm citywide at-large councillors returned, not per-ward |
| Path 0 returns correct ward councillor for Waltham | MAGE-20 | Same spatial check | Same pattern |
| Path 0 returns ward boundary for Medford | MAGE-21 | At-large city — same as Fall River | Same |
| Path 0 returns correct ward councillor for New Bedford | MAGE-22 | Same spatial check | Same pattern |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify elements (SQL assertions) or are flagged manual-only
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0: no test stubs needed — direct DB SQL
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
