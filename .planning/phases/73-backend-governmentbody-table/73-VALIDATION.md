---
phase: 73
slug: backend-governmentbody-table
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-11
---

# Phase 73 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | go build (compilation check) + manual SQL/curl |
| **Config file** | none |
| **Quick run command** | `cd EV-Backend && go build -o server . && echo "build OK"` |
| **Full suite command** | Manual: psql queries to verify migration + curl against running server |
| **Estimated runtime** | ~5 seconds (build) |

---

## Sampling Rate

- **After every task commit:** Run `cd EV-Backend && go build -o server .`
- **After every plan wave:** Manual curl test against running server
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 73-01-01 | 01 | 1 | LINK-02 | manual-smoke | `psql $DATABASE_URL -c "\d essentials.government_bodies"` | N/A | ⬜ pending |
| 73-01-02 | 01 | 1 | LINK-02 | manual-smoke | `cd EV-Backend && go build -o server .` | ✅ | ⬜ pending |
| 73-01-03 | 01 | 1 | LINK-02 | manual-smoke | `curl -s -X POST .../essentials/address -d '...' \| jq '.[0].government_body_name'` | N/A | ⬜ pending |
| 73-01-04 | 01 | 1 | DATA-02 | manual-code-review | `grep -n "commission" essentials/src/lib/classify.js` | ❌ W0 | ⬜ pending |
| 73-01-05 | 01 | 1 | DATA-03 | manual-code-review | `grep -n "County Legislators" essentials/src/lib/classify.js essentials/src/utils/sorters.js` | ❌ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* No test framework install needed — all validation is manual SQL queries, curl, and go build compilation checks.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| government_bodies table has correct columns | LINK-02 | Schema DDL check | `psql $DATABASE_URL -c "\d essentials.government_bodies"` — verify state, geo_id, body_key, display_name, website_url columns |
| SearchPoliticians returns body fields | LINK-02 | Requires running server + DB | POST to /essentials/address with Monroe County IN address, check response has government_body_name |
| NULL-safe: officials without body row | LINK-02 | Edge case requires specific data | Check Sheriff/Assessor in response — field should be empty string not null |
| Commissioners land in County Legislators | DATA-02 | Requires classify.js trace | Run classify with title "Monroe County Commission - District 1" |
| All three consumer structures consistent | DATA-03 | Code review | grep "County Legislators" across classify.js and sorters.js |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
