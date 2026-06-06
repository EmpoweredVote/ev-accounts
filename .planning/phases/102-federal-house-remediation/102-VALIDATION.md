---
phase: 102
slug: federal-house-remediation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-06
---

# Phase 102 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | SQL verification queries (psql) + file-existence checks |
| **Config file** | none — data-only phase, no test framework |
| **Quick run command** | `npx tsx backend/scripts/run-house-source-triage.ts --dry-run` |
| **Full suite command** | psql $DATABASE_URL -c "{V1 query}" and psql $DATABASE_URL -c "{V2 query}" |
| **Estimated runtime** | ~5 seconds (triage dry-run) |

---

## Sampling Rate

- **After every task commit:** Run triage script dry-run or file-existence check
- **After every plan wave:** Run V1 + V2 SQL verification queries
- **Before `/gsd-verify-work`:** Both V1 and V2 must return 0
- **Max feedback latency:** ~10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 102-01-T1 | 01 | 1 | FEDX-02 | — | N/A | file-check | `test -f backend/scripts/run-house-source-triage.ts && npx tsx backend/scripts/run-house-source-triage.ts --dry-run` | ❌ W0 | ⬜ pending |
| 102-01-T2 | 01 | 1 | FEDX-02 | — | N/A | file-check | `test -f .planning/phases/102-federal-house-remediation/102-TRIAGE-REPORT.md && test -f .planning/phases/102-federal-house-remediation/102-HOUSE-TARGETS.csv` | ❌ W0 | ⬜ pending |
| 102-02-T1 | 02 | 2 | QUAL-01 | — | Human spot-check | manual | Human verification at checkpoint — confirm 3 random source URLs from research CSV link to specific evidence | N/A | ⬜ pending |
| 102-02-T2 | 02 | 2 | FEDX-02 | — | N/A | SQL | `psql $DATABASE_URL -c "SELECT COUNT(*) FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id IN (SELECT DISTINCT p.id FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id=p.id AND o.is_vacant=false JOIN essentials.districts d ON d.id=o.district_id WHERE d.district_type='NATIONAL_LOWER' AND p.is_active=true) AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources,1) IS NULL)"` | N/A | ⬜ pending |
| 102-02-T3 | 02 | 2 | QUAL-02 | — | N/A | file-check | `test -f .planning/phases/102-federal-house-remediation/102-DELETION-LOG.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- No Wave 0 test stubs required — this is a data-only phase. SQL verification queries in Plan 02 Task 4 serve as the functional equivalent.

*Existing infrastructure (pool.query pattern, psql apply) covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Source URL quality spot-check | QUAL-01 | Automated tools can only confirm URL is non-empty; human must verify URL links to specific evidence of politician's position | After research CSV produced: open 3 random source URLs from Dooley/Shoffner/Alme research output and confirm each links to a bill vote, press release, floor speech, or statement that explicitly states the politician's position on the topic |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
