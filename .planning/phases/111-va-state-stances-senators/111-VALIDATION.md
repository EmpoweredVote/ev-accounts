---
phase: 111
slug: va-state-stances-senators
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-06-09
---

# Phase 111 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | SQL assertions (DO $$ blocks in migration + psql phase gate) |
| **Config file** | none — SQL-assertion-only, no test runner |
| **Quick run command** | `psql $DATABASE_URL -c "SELECT COUNT(DISTINCT pa.politician_id) FROM inform.politician_answers pa JOIN essentials.politicians p ON p.id = pa.politician_id WHERE p.external_id BETWEEN -5110040 AND -5110001"` |
| **Full suite command** | Phase gate SQL (2 queries) — see Validation Architecture in RESEARCH.md |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every plan wave:** Run phase gate SQL — senators_with_stances count must increase; unsourced must remain 0
- **Per migration:** Inline DO $$ verification block in each migration SQL file
- **Before `/gsd-verify-work`:** Full phase gate (both queries) must pass
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 111-01 pre-flight | 01 | 1 | VAST-02 | — | N/A | sql | `SELECT MAX(version) FROM supabase_migrations.schema_migrations` | ✅ existing | ⬜ pending |
| 111-01 stances | 01 | 1 | VAST-02, VAST-05 | — | N/A | sql | DO $$ block in migration | ❌ created in plan | ⬜ pending |
| 111-02 stances | 02 | 2 | VAST-02, VAST-05 | — | N/A | sql | DO $$ block in migration | ❌ created in plan | ⬜ pending |
| 111-03 stances | 03 | 3 | VAST-02, VAST-05 | — | N/A | sql | DO $$ block in migration | ❌ created in plan | ⬜ pending |
| 111-04 stances | 04 | 4 | VAST-02, VAST-05 | — | N/A | sql | DO $$ block in migration | ❌ created in plan | ⬜ pending |
| 111-05 stances + gate | 05 | 5 | VAST-02, VAST-05 | — | N/A | sql | Phase gate: senators_with_stances=40, unsourced=0 | ❌ created in plan | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test files needed — all verification is SQL-assertion-based (matching established pattern from Phases 103/106/108).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Stance values verified against Five-Chairs scale text | VAST-02 | Scale texts are domain knowledge; automated only checks numeric range | Review CSV before applying migration — each value must match the stated Chair text for that topic |
| No party-inferred stances | VAST-05 | Source quality is judgment-based | Review reasoning column in CSV — flag any entry citing only party platform without a direct politician statement or vote |

---

## Validation Sign-Off

- [ ] All tasks have SQL verify or inline DO $$ block
- [ ] Sampling continuity: each wave migration includes verification block
- [ ] Wave 0: covered — no new test infrastructure needed
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
