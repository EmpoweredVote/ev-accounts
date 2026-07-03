---
phase: 149
slug: ca-candidate-seeding-race-candidates-only-turnkey
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-28
---

# Phase 149 — Validation Strategy

> Per-phase validation contract. Phase 149 is a **data-seeding** phase (race_candidates + new politician records + headshots + stances on production). It writes to production via reviewed migrations/scripts, but all *validation* is via read-only SQL/node assertions — there is no unit-test framework in scope. The gate is a standalone `149-verify.sql` (+ a small coordinate-surfacing node smoke), following the `148-verify.sql` / `verify-phase-141-144.sql` precedent.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Read-only SQL gate (`psql -f`) + node-tsx coordinate smoke (pattern: `148-verify.sql`, `verify-phase-141-144.sql`) |
| **Config file** | none — gate is a standalone `.sql` in `backend/scripts/` |
| **Quick run command** | `cd /c/EV-Accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/149-verify.sql` (expect all assertions PASS, exit 0) |
| **Full suite command** | same gate + the coordinate surfacing node smoke (≥3 CA House centroids) |
| **Estimated runtime** | ~10–30 seconds |

---

## Sampling Rate

- **After every task commit:** run the targeted SQL count for that task's slice (e.g. per-district race_candidate count, per-candidate stance count).
- **After every plan wave:** run the full `149-verify.sql` gate.
- **Before `/gsd:verify-work`:** full gate green + coordinate smoke surfaces ≥3 sample CA House districts.
- **Max feedback latency:** ~30 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Verification | Status |
|---------|------|------|-------------|-----------------|-----------|--------------|--------|
| 149-* (records+wiring) | 01 | 1 | USHC-02, USHC-03 | reviewed prod write; no untrusted input | SQL data-assertion | 52 House races each ≥2 active candidates, all `politician_id` non-null; no duplicate `full_name` in CA; Ruiz CA-25 dedup applied; renominated incumbents reuse 148 `incumbent_pid` | ⬜ pending |
| 149-* (headshots) | — | 2 | USHC-04 | Storage write via service role | SQL data-assertion | every newly-seeded CA candidate has a `politician_images` row + `photo_origin_url` (honest-skips pinned) | ⬜ pending |
| 149-* (stances) | — | 3 | USHC-05 | reviewed prod write; primary-source-verified | SQL data-assertion | 0 unsourced rows for the 36+38 in-scope candidates; federal-24 coverage OR documented honest-skip pinned by UUID | ⬜ pending |
| 149-* (gate) | — | final | USHC-02/03/04/05, D-04 | read-only (write-free gate) | SQL/node | `149-verify.sql` all assertions PASS exit 0; both same-party advancers present in the 9 same-party districts; coordinate smoke surfaces sample races | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red. Per-task rows finalized by the planner.*

---

## Gate Scoping Rules (CRITICAL — from live research findings)

- **Scope ALL assertions to the 52 CA House races** (`d.district_type='NATIONAL_LOWER'` within the "CA 2026 Statewide General" election `728d0074-…`). The 53rd race in that election is **Governor**, which already carries ~76 pre-existing candidates (quick-016/023 leftovers) — any election-wide count will false-fail. This is the single biggest gate trap.
- The **honest-skip set** (including any whole-record stance skip) MUST be pinned by exact UUID/external_id with the query's exact `ORDER BY` (the Phase 143 lesson — an ordering mismatch false-fails).
- The gate must be **write-free** (a `CREATE TEMP TABLE … ON COMMIT DROP` for diffing is acceptable — the `148-verify.sql` precedent). SELECT-only against production; never `--commit`.

---

## Wave 0 Requirements

- [ ] `backend/scripts/149-verify.sql` — all USHC-02/03/04/05 + D-04 assertions, House-scoped, honest-skip-pinned (authored as part of the gate plan).
- [ ] Coordinate surfacing node smoke (≥3 CA House district centroids) — or fold into the gate as `ST_Covers` assertions.
- [ ] Sample in-district lat/lng per smoke district (centroid query from `geofence_boundaries`).

*No test-framework install needed — `psql` + `node --import tsx` + the `pg` pool is the established read-only harness (v2.17/v2.18 methodology).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Stance values are chairs-not-polarity & sources back the value | USHC-05 | The value↔evidence match is a judgment against an external primary source, not machine-assertable | Primary-source verification pass before push (Playwright/fetch the cited URL; confirm the value the evidence supports; agents over-read even when citing URLs) |
| Headshot is the correct person / not a placeholder | USHC-04 | Image identity is not machine-assertable | Spot-check a sample of newly-seeded headshots against the source page |
| Nov-3 candidate field per district is correct | USHC-02/03 | External ground truth — established by Phase 148's cited field table | Cross-check a sample of seeded districts against `148-FIELD-TABLE.md` source_url citations |

---

## Validation Sign-Off

- [ ] `149-verify.sql` covers USHC-02/03/04/05 + D-04, House-scoped to the 52 races, honest-skips pinned by UUID
- [ ] Every CA House race has ≥2 active candidates with non-null `politician_id`; 0 duplicate `full_name` in CA
- [ ] 0 unsourced stance rows for the 36+38 in-scope candidates; primary-source-verified before push
- [ ] Coordinate smoke surfaces sample CA House races on the elections feed
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
