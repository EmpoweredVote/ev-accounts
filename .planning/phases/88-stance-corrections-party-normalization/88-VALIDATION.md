---
phase: 88
slug: stance-corrections-party-normalization
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-02
---

# Phase 88 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | SQL verification queries (no unit test framework — data migration phase) |
| **Config file** | none — direct DB queries via mcp__supabase-local__execute_sql |
| **Quick run command** | `SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '<uuid>'` |
| **Full suite command** | Run verification SQL in 88-VERIFICATION.md after all corrections applied |
| **Estimated runtime** | ~5 seconds per query |

---

## Sampling Rate

- **After every task commit:** Run spot-check SQL for the corrected politician (row count + value distribution)
- **After every plan wave:** Run context-rows check (zero orphan stances, all corrections have source URLs)
- **Before `/gsd-verify-work`:** All 5 success criteria SQL queries must pass

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 88-01-01 | 01 | 1 | SACC-02 | T-88-01-01 | Tier 1 batch A (Gonzalez, Niello, Nixon, Vindman) corrected with source URLs | sql | `SELECT value, COUNT(*) FROM inform.politician_answers WHERE politician_id IN ('5ad32852-789e-4013-995b-6f0aa6a5a5d4','22152e41-31b9-4700-9226-4e274c616f37','0ac89151-2b8d-4430-b9bd-3a80bef3413b','a2fee754-f90c-47ff-a3b7-377d55992273') GROUP BY value` | ✅ | ⬜ pending |
| 88-02-01 | 02 | 2 | SACC-02 | T-88-02-01 | Tier 1 batch B (Grayson, Hinson, Dooley, Hinojosa) corrected with source URLs; Hinojosa party verified | sql | `SELECT COUNT(*) FROM inform.politician_context WHERE politician_id IN ('29389f8b-de23-4312-af73-264289dc7774','bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1','b841a475-41b4-4f19-9ad1-13769b1f4eef','0c6c482a-feba-45bc-821b-02769a810063') AND (sources IS NULL OR array_length(sources, 1) = 0)` (expect 0) | ✅ | ⬜ pending |
| 88-03-01 | 03 | 3 | SACC-02 | T-88-03-02 | Tier 2 borderline determinations documented; MA cluster investigation labeled; corrections applied where needed | sql | `SELECT COUNT(*) FROM inform.politician_context pc JOIN essentials.politicians p ON p.id = pc.politician_id WHERE pc.updated_at > '2026-06-03' AND (pc.sources IS NULL OR array_length(pc.sources, 1) = 0)` (expect 0) | ✅ | ⬜ pending |
| 88-04-01 | 04 | 4 | SACC-02 | T-88-04-01 | Ukraine-support Republicans verified — each has determination + source URL | sql | `SELECT COUNT(*) FROM inform.politician_context WHERE topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support') AND politician_id IN (SELECT id FROM essentials.politicians WHERE party ILIKE 'Republican') AND (sources IS NULL OR array_length(sources, 1) = 0)` (expect 0) | ✅ | ⬜ pending |
| 88-05-01 | 05 | 5 | SACC-03 | T-88-05-01 | Party string normalized — no "Democrat" rows remain; total preserved | sql | `SELECT COUNT(*) FROM essentials.politicians WHERE party = 'Democrat'` (expect 0); `SELECT DISTINCT party FROM essentials.politicians WHERE party ILIKE 'democra%' ORDER BY party` (expect single row 'Democratic') | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- None. No test infrastructure setup needed — all verification is via SQL queries against live DB.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Research stances for each Tier 1 politician | SACC-02 | Requires human review of fetched web sources to confirm stance accuracy | Use research-stances skill; review output CSV before ingesting |
| Confirm MA value=3 cluster root cause | SACC-02 | Requires reading politician_context reasoning text for templated patterns | Run investigation SQL, inspect returned reasoning strings |
| Ukraine-support position determination per R | SACC-02 | Requires reading vote records / news sources per politician | Use research-stances skill; confirm value matches current position |
| Hinojosa party-tag verification | SACC-02 | Requires reading ballotpedia / official Texas legislative sources to confirm true party | Inspect Task 3 resume-signal value in 88-02 |

---

## Validation Sign-Off

- [ ] All corrections have source URLs in inform.politician_context
- [ ] Zero orphaned stance rows (every corrected stance has a paired context row)
- [ ] SELECT DISTINCT party returns exactly one "Democratic" variant (or agreed-upon standard)
- [ ] All 8 Tier 1 politicians either corrected or documented as "original value confirmed correct"
- [ ] All 21 Tier 2 borderline politicians have a documented disposition
- [ ] `nyquist_compliant: true` set in frontmatter when all above pass

**Approval:** pending
