---
phase: 103
slug: state-remediation-ca-md
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-05
---

# Phase 103 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | SQL (psql / Supabase CLI) — no unit test framework; this is a data remediation phase |
| **Config file** | none — migrations applied via psql or `supabase db push` |
| **Quick run command** | `psql $DATABASE_URL -c "SELECT COUNT(*) FROM inform.politician_context WHERE sources IS NOT NULL AND array_length(sources,1)>0"` |
| **Full suite command** | Run Plan 01 triage query; check counts against RESEARCH.md findings |
| **Estimated runtime** | ~30 seconds per SQL check |

---

## Sampling Rate

- **After every task commit:** Run quick SQL count check to confirm no data loss
- **After every plan wave:** Run full triage query to verify unsourced count is trending toward zero
- **Before `/gsd-verify-work`:** Final triage query must show zero CA state legislator unsourced stances
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 103-01-01 | 01 | 1 | STAX-01 | — | Triage script runs, outputs CSV | manual | `cd backend && npx tsx scripts/run-ca-source-triage.ts --dry-run` | ✅ | ⬜ pending |
| 103-02-xx | 02 | 2 | STAX-01, QUAL-01, QUAL-02 | — | Zero unsourced CA stances remain after migration | SQL | `psql $DATABASE_URL -c "$(cat .planning/phases/103-state-remediation-ca-md/verify-ca-unsourced.sql)"` | ✅ / ❌ W0 | ⬜ pending |
| 103-03-xx | 03 | 2 | STAX-02, QUAL-01 | — | All 5 MD officials have ≥1 stance with source URL | SQL | `psql $DATABASE_URL -c "$(cat .planning/phases/103-state-remediation-ca-md/verify-md-stances.sql)"` | ✅ / ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- No test framework installation needed — this is a SQL data remediation phase.
- Executor must verify `SELECT MAX(version) FROM supabase_migrations.schema_migrations` before writing any migration number.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CA triage CSV shows full politician list (not just Phase 100's 9) | STAX-01 | Triage output is dynamic — scope depends on DB state | After Plan 01: review CSV for count, compare to Phase 100 floor of 9 |
| Every CA remediated stance value verified against Chair text | QUAL-01 | Research-stances tool selects value — human must confirm match | During Plan 02: for each stance updated, verify value matches specific Chair text, not just directional lean |
| Every MD stance value verified against Chair text (not party inference) | QUAL-01, STAX-02 | 5 officials × 44 topics = 220 stance assessments — human review needed | During Plan 03: spot-check at minimum 10% of stances per official |
| Deletion log format is correct (full_name, topic_key, former_value, reason) | QUAL-02 | Deletion log is a committed file, not a DB constraint | Before merge: confirm deletion log CSV has correct columns and no blank rows |
| Source append (not overwrite) for CA politicians with existing context rows | STAX-01 | SQL migration must use ARRAY_CAT pattern | After Plan 02 migration: verify `SELECT array_length(sources, 1)` increases, never resets to 1 for pre-existing context rows |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
