---
phase: 141
slug: roster-lock-seed-records-headshots
status: wired
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-20
---

# Phase 141 — Validation Strategy

> Per-phase validation contract. This is a **data-seeding** phase — validation is read-only SQL assertions against production (the project's `verify-phase-*.sql` gate pattern), NOT a unit-test framework.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | PostgreSQL read-only labeled SQL assertions (psql `-v ON_ERROR_STOP=1`) + `node --import tsx` + `pool` diagnostics |
| **Config file** | none — ad hoc scripts in `backend/scripts/` (run from inside `backend/` to resolve node_modules; `import 'dotenv/config'`) |
| **Quick run command** | `cd backend && node --import tsx scripts/verify-state-exec-baseline.ts` (per-state STATE_EXEC counts) |
| **Full suite command** | `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-141.sql` |
| **Estimated runtime** | ~5–15 seconds (network round-trips to prod `kxsdzaojfaibhuzmclfq`) |

*Note: prod migrations apply directly (execute_sql / psql / apply_migration). A seed migration is only "real" once applied AND the rows are visible — every plan must include an explicit apply-to-prod + row-count verify step so build/type checks don't produce a false-positive pass.*

---

## Sampling Rate

- **After each seed migration commit:** Run the quick per-state count (`SELECT state, COUNT(*) FROM essentials.districts WHERE district_type='STATE_EXEC' GROUP BY state ORDER BY state`).
- **After each wave merge:** Run `verify-state-exec-baseline.ts` full diagnostic (gap vs the 208-office matrix).
- **Before phase close (Phase 144 gate is separate):** `verify-phase-141.sql` — all labeled assertions PASS.
- **Max feedback latency:** ~15 seconds.

---

## Per-Task Verification Map

| Requirement | Behavior | Test Type | Automated Command / Assertion | File Exists | Status |
|-------------|----------|-----------|-------------------------------|-------------|--------|
| SEXR-01 | The 50-state roster names elected vs appointed/legislature/nonexistent per Big-5 office, with a source URL per exception + officeholder per in-scope office; in-scope count = 208 | manual (matrix in RESEARCH.md) + SQL | matrix reviewed; `verify-phase-141.sql` asserts labeled STATE_EXEC Big-5 districts ≈ 208 (minus documented exclusions: AZ LtGov) | ❌ W0 | ⬜ pending |
| SEXR-02 | Every in-scope (state, role_canonical) Big-5 office has a seeded politician + office; 0 phantom offices; 0 duplicates | SQL assertion | `verify-phase-141.sql`: for each of 208 matrix pairs `EXISTS` politician+office; AND `NOT EXISTS` non-elected/phantom office | ❌ W0 | ⬜ pending |
| SEXR-03 | Every in-scope Big-5 office has non-null `role_canonical` (incl. alias mapping: FL CFO / NY+TX Comptroller → treasurer; MA Secretary of the Commonwealth → secretary_of_state) | SQL assertion | `COUNT(*) FROM essentials.offices o JOIN ... WHERE in-scope AND role_canonical IS NULL` = 0 | ❌ W0 | ⬜ pending |
| SEXR-04 | Every newly-seeded exec has a headshot (verify actual mechanism: `photo_origin_url` column + storage mirror per v2.15/find-headshots, NOT assumed `politician_images`) | SQL assertion | `COUNT` of newly-seeded execs (external_id in new range) with NULL/empty headshot = 0 | ❌ W0 | ⬜ pending |
| D-10 | Every STATE_EXEC district has uppercase `state` AND non-empty `geo_id` (the 223a lowercase-`or` defect guard) | SQL assertion | `COUNT(*) WHERE district_type='STATE_EXEC' AND (state != upper(state) OR geo_id IS NULL OR geo_id='')` = 0 | ❌ W0 | ⬜ pending |
| D-09 | No reseed: existing Big-5 records (9 states) untouched; dry-run gap query → 0 new INSERTs for present (state, role_canonical) | SQL assertion (pre-flight in seed migration) | dry-run gap query returns 0 for present offices; existing external_ids unchanged | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `backend/scripts/verify-phase-141.sql` — labeled read-only SQL assertions covering SEXR-01..04 + D-09/D-10, `-v ON_ERROR_STOP=1`, mirroring `backend/scripts/verify-phase-132-140.sql`. (The existing `verify-state-exec-baseline.ts` is a research diagnostic, NOT the gate.)
- [ ] external_id collision preflight assertion (id < -56000 AND not already present) embedded in each seed migration.

*The Phase 144 consolidated gate (SEXS-03) is separate; this `verify-phase-141.sql` is the phase-local proof that seeding + role_canonical + headshots are complete.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Roster elected-vs-appointed correctness | SEXR-01 | Truth lives in external sources (Wikipedia + state .gov), not derivable from DB | Review the 50-state matrix in RESEARCH.md; spot-check ≥1 exception per category (appointed AG, no-LtGov state, abolished Treasurer) against its cited source URL |
| Officeholder identity is current (as-of 2026-06) | SEXR-01/02 | Recency (Jan-2026 inaugurations, 2025 turnover) can't be asserted by count alone | Spot-check ≥3 newly-seeded officeholders against the cited .gov/Wikipedia source |

---

## Validation Sign-Off

- [ ] All requirements have a SQL assertion in `verify-phase-141.sql` or a documented manual check
- [ ] Sampling continuity: per-migration quick count + per-wave diagnostic defined
- [ ] Wave 0 covers the missing gate script + collision preflight
- [ ] No watch-mode flags (N/A — SQL)
- [ ] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter (assertions wired: gate authored in plan 141-01 Task 1; applied + asserted in 141-12 Task 2)

**Approval:** pending
