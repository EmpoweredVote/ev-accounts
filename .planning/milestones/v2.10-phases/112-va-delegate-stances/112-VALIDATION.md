---
phase: 112
slug: va-delegate-stances
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-10
---

# Phase 112 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | SQL assertions in migration DO $$ blocks + manual phase gate |
| **Config file** | None |
| **Quick run command** | `psql "$DATABASE_URL" -c "SELECT COUNT(*) FROM inform.politician_answers pa JOIN essentials.politicians p ON p.id = pa.politician_id WHERE p.external_id BETWEEN -5120100 AND -5120001"` |
| **Full suite command** | Phase gate 2-query SQL (count + unsourced=0) after Wave 10 applied |
| **Estimated runtime** | ~5 seconds (SQL only) |

---

## Sampling Rate

- **After every wave migration:** Run DO $$ ASSERT block in the migration itself
- **After every plan wave:** Run quick psql count query
- **Before `/gsd-verify-work`:** Phase gate 2-query SQL must pass (count > 0, unsourced = 0)
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Pre-flight | 01 | 1 | VAST-03 | — | N/A | SQL | `SELECT COUNT(*) FROM inform.politician_answers pa JOIN essentials.politicians p ON p.id=pa.politician_id WHERE p.external_id BETWEEN -5120100 AND -5120001` → 0 | ❌ run before Wave 1 | ⬜ pending |
| Wave 1 migration | 01 | 1 | VAST-03, VAST-05 | — | N/A | SQL assertion | DO $$ block: ASSERT unsourced_count = 0 for wave external_id range | ❌ written in migration | ⬜ pending |
| Wave 2 migration | 02 | 1 | VAST-03, VAST-05 | — | N/A | SQL assertion | DO $$ block: IN (list) — non-contiguous range | ❌ written in migration | ⬜ pending |
| Wave 3 migration | 03 | 2 | VAST-03, VAST-05 | — | N/A | SQL assertion | DO $$ block: IN (list) — non-contiguous range | ❌ written in migration | ⬜ pending |
| Wave 4 migration | 04 | 2 | VAST-03, VAST-05 | — | N/A | SQL assertion | DO $$ block: BETWEEN for wave's external_id range | ❌ written in migration | ⬜ pending |
| Wave 5 migration | 05 | 3 | VAST-03, VAST-05 | — | N/A | SQL assertion | DO $$ block: IN (list) — non-contiguous range | ❌ written in migration | ⬜ pending |
| Wave 6 migration | 06 | 3 | VAST-03, VAST-05 | — | N/A | SQL assertion | DO $$ block: BETWEEN for wave's external_id range | ❌ written in migration | ⬜ pending |
| Wave 7 migration | 07 | 4 | VAST-03, VAST-05 | — | N/A | SQL assertion | DO $$ block: BETWEEN for wave's external_id range | ❌ written in migration | ⬜ pending |
| Wave 8 migration | 08 | 4 | VAST-03, VAST-05 | — | N/A | SQL assertion | DO $$ block: BETWEEN + full_name != 'Vacant' skip (HD-20) | ❌ written in migration | ⬜ pending |
| Wave 9 migration | 09 | 5 | VAST-03, VAST-05 | — | N/A | SQL assertion | DO $$ block: BETWEEN for wave's external_id range | ❌ written in migration | ⬜ pending |
| Wave 10 migration | 10 | 5 | VAST-03, VAST-05 | — | N/A | SQL assertion | DO $$ block: BETWEEN for wave's external_id range | ❌ written in migration | ⬜ pending |
| Phase gate | 10 | 5 | VAST-03, VAST-05 | — | N/A | SQL | Count > 0 + unsourced = 0 across all external_id -5120001 to -5120100 | ❌ run after Wave 10 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — no test files needed. All verification is SQL-assertion-based, matching established pattern from Phases 103/106/108/111. Existing psql infrastructure confirmed available.

*Wave 0: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| No vacant seat (HD-20) stance rows written | VAST-03 | Must confirm Vacant record was skipped, not researched | `SELECT COUNT(*) FROM inform.politician_answers pa JOIN essentials.politicians p ON p.id=pa.politician_id WHERE p.external_id = -5120020` → must return 0 |
| Source URLs are real fetched URLs (not placeholder) | VAST-05 | Content quality cannot be asserted in SQL | Spot-check 5 random rows: `SELECT pc.sources FROM inform.politician_context pc JOIN essentials.politicians p ON p.id=pc.politician_id WHERE p.external_id BETWEEN -5120100 AND -5120001 LIMIT 5` — URLs must resolve |
| No party-inferred stances | VAST-05 | Cannot be detected by SQL | Spot-check reasoning field in politician_context for a rural Republican delegate — must show source URL, not party pattern |

---

## Critical DO $$ Pattern Note

Waves 2, 3, and 5 cover non-contiguous external_id ranges. DO $$ verification blocks for these waves MUST use `IN (list)` or OR-connected `BETWEEN` — a single `BETWEEN` would span the gap and produce wrong unsourced counts. See RESEARCH.md A5.

---

## Validation Sign-Off

- [ ] All wave migrations have DO $$ ASSERT block
- [ ] Non-contiguous waves (2, 3, 5) use IN() not BETWEEN in DO $$ block
- [ ] HD-20 Vacant skipped in Wave 8
- [ ] Phase gate confirms total count > 0 + unsourced = 0
- [ ] Spot-check confirms source URLs resolve
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
