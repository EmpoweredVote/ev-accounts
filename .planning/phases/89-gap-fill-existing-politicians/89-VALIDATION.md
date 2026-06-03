---
phase: 89
slug: gap-fill-existing-politicians
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-03
---

# Phase 89 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual SQL verification via pool.query() (no automated test framework applicable — pure data ingestion phase) |
| **Config file** | backend/.env |
| **Quick run command** | `cd backend && set -a && source .env && set +a && node --import tsx -e "import { pool } from './src/lib/db.js'; const r = await pool.query('SELECT COUNT(*) FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pc.politician_id IS NULL'); console.log('orphan stances:', r.rows[0].count); await pool.end();"` |
| **Full suite command** | See Per-Task Verification Map below |
| **Estimated runtime** | ~5 seconds (SQL queries only) |

---

## Sampling Rate

- **After every Wave 1 task commit:** Run the orphan check command above
- **After every Wave 2 politician ingested:** Run the coverage check for that politician
- **Before `/gsd-verify-work`:** All SQL verification checks must return 0 for the target set
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 89-01-01 | 01 | 1 | GAPF-01 | — | N/A | manual SQL | `SELECT COUNT(*) FROM inform.politician_answers GROUP BY politician_id HAVING COUNT(*) < 10` — returns 440 or lower | ✅ (DB live) | ⬜ pending |
| 89-01-02 | 01 | 1 | GAPF-01 | — | N/A | manual SQL | Audit artifact `89-GAP-FILL-AUDIT.md` exists with tier + evidence-availability annotation for all 440 politicians | ❌ W0 | ⬜ pending |
| 89-02-01 | 02 | 2 | GAPF-02 | — | N/A | manual SQL | `SELECT COUNT(*) FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pc.politician_id IS NULL` returns 0 | ✅ (DB live) | ⬜ pending |
| 89-02-02 | 02 | 2 | GAPF-02 | — | N/A | manual SQL | `SELECT COUNT(*) FROM inform.politician_context WHERE (sources IS NULL OR array_length(sources,1) = 0) AND politician_id IN (SELECT DISTINCT politician_id FROM inform.politician_answers pa JOIN ... WHERE ... post-phase IDs)` returns 0 | ✅ (DB live) | ⬜ pending |
| 89-02-03 | 02 | 2 | GAPF-02 | — | N/A | manual SQL | All Tier 1 (high-priority) politicians now have >= 10 stances OR are documented as "no additional evidence available" | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- None required — no test framework installation needed. All verification is SQL-based against the live database.

*Existing infrastructure covers all phase requirements. SQL queries execute directly via pool.query() using the existing backend DB connection.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 89-GAP-FILL-AUDIT.md lists all 440 politicians with tier + evidence-availability annotation | GAPF-01 | Human judgment required for tier assignment | Open `.planning/phases/89-gap-fill-existing-politicians/89-GAP-FILL-AUDIT.md`; verify every row has a `Tier` column value (1/2/3) and an `Evidence` column value (`plausible` / `no_evidence` / `partial`) |
| Every Tier 1 politician either has >= 10 stances or has "no additional evidence available" documented | GAPF-02 | Requires cross-referencing audit artifact with DB state | Run: `SELECT p.full_name, COUNT(pa.topic_id) AS stance_count FROM essentials.politicians p JOIN inform.politician_answers pa ON pa.politician_id = p.id GROUP BY p.id, p.full_name HAVING COUNT(pa.topic_id) < 10 ORDER BY COUNT(pa.topic_id)` — verify remaining entries are either Tier 2/3 or have documented "no evidence" in the audit artifact |
| Orphan context rows for Niello, Schiavo, Zbur, Elhawary resolved | GAPF-02 | Side-task not captured by automated query alone | Run orphan check command; confirm count is 0 for these 4 politicians specifically |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
