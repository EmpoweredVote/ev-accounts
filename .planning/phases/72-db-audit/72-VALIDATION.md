---
phase: 72
slug: db-audit
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-10
---

# Phase 72 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — Phase 72 is SQL-only investigation |
| **Config file** | none |
| **Quick run command** | `psql $DATABASE_URL -c "<query>"` or Supabase SQL editor |
| **Full suite command** | Execute all 5 queries in order |
| **Estimated runtime** | ~30 seconds (manual SQL execution) |

---

## Sampling Rate

- **After every task commit:** Not applicable — Phase 72 produces documentation, not code
- **After every plan wave:** Execute all 5 queries, verify outputs match FINDINGS.md
- **Before `/gsd:verify-work`:** All 4 DATA-01 sub-questions answered in FINDINGS.md
- **Max feedback latency:** N/A (manual SQL execution)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 72-01-01 | 01 | 1 | DATA-01 | manual-only | Execute Query 1 in Supabase SQL editor | N/A | ⬜ pending |
| 72-01-02 | 01 | 1 | DATA-01 | manual-only | Execute Query 2, inspect simulated_group | N/A | ⬜ pending |
| 72-01-03 | 01 | 1 | DATA-01 | manual-only | Execute Query 3, check row count > 0 | N/A | ⬜ pending |
| 72-01-04 | 01 | 1 | DATA-01 | manual-only | Execute Query 5, annotate expected groups | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework or stubs needed — Phase 72 is a pure SQL audit producing documentation.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Distinct chamber_name/chamber_name_formal values documented | DATA-01 | Output is DB query results, not testable code | Run Query 1 in Supabase SQL editor, paste output into FINDINGS.md |
| classify.js group collision confirmed or denied | DATA-01 | Requires human interpretation of simulated_group column | Run Query 2, check if Commissioners and Council share "County Legislators" group |
| TIGER GeoID 18105 verified present | DATA-01 | Single query result, pass/fail | Run Query 3, confirm row exists |
| Regression mapping table created | DATA-01 | Requires manual annotation of expected groups | Run Query 5, add Expected Group column based on classify.js trace |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < N/A
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
