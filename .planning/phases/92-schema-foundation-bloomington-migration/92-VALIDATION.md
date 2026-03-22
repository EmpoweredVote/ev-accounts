---
phase: 92
slug: schema-foundation-bloomington-migration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-22
---

# Phase 92 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (no automated test suite in EV-Backend or treasury-tracker) |
| **Config file** | None |
| **Quick run command** | `cd EV-Backend && go build -o server .` |
| **Full suite command** | API round-trip: `curl "http://localhost:5050/treasury/budgets?city=Bloomington&year=2025&dataset=operating"` |
| **Estimated runtime** | ~15 seconds (build + curl) |

---

## Sampling Rate

- **After every task commit:** Run `cd EV-Backend && go build -o server .`
- **After every plan wave:** Run import and verify record counts in DB
- **Before `/gsd:verify-work`:** All 7 curl checks return populated data
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 92-01-01 | 01 | 1 | SCHM-01 | manual | `./server run-sql "SELECT count(*) FROM treasury.budgets"` | ❌ W0 | ⬜ pending |
| 92-01-02 | 01 | 1 | SCHM-02 | manual | `curl .../treasury/municipalities` | ❌ W0 | ⬜ pending |
| 92-01-03 | 01 | 1 | SCHM-03 | manual | `./server run-sql "SELECT fiscal_year_start_month FROM treasury.budgets LIMIT 5"` | ❌ W0 | ⬜ pending |
| 92-02-01 | 02 | 2 | DATA-01 | manual | `curl ".../treasury/budgets?city=Bloomington&year=2025&dataset=operating"` | ❌ W0 | ⬜ pending |
| 92-02-02 | 02 | 2 | DATA-02 | manual | `curl ".../treasury/budgets?city=Bloomington&year=2025&dataset=revenue"` | ❌ W0 | ⬜ pending |
| 92-02-03 | 02 | 2 | DATA-03 | manual | `curl ".../treasury/budgets?city=Bloomington&year=2025&dataset=salaries"` | ❌ W0 | ⬜ pending |
| 92-03-01 | 03 | 3 | DATA-04 | manual | Stop server, load frontend — verify error+retry UI | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] No automated test infrastructure exists — all verification is manual curl + SQL queries
- [ ] Go build verification: `cd EV-Backend && go build -o server .` must succeed
- [ ] API round-trip validation: compare `totalBudget` from source JSON against API response for each of 15 datasets

*Existing infrastructure covers build verification only. All behavioral verification is manual.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Duplicate import conflict | SCHM-01 | Requires DB state setup | Import once, import again, verify conflict error |
| entity_type storage | SCHM-02 | Requires API call + DB check | POST municipality with entity_type, GET and verify |
| fiscal_year_start_month | SCHM-03 | Requires DB query | Import budget, query DB for field value |
| Static fallback guard | DATA-04 | Requires server down + browser | Stop server, load frontend, verify error UI |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
