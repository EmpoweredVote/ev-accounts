---
phase: 87
slug: stance-accuracy-audit-agent-update
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-02
---

# Phase 87 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — this phase produces a planning artifact (AUDIT-REPORT.md) and a SKILL.md edit; no automated test suite |
| **Config file** | none |
| **Quick run command** | `node -e "require('./backend/src/lib/db.js')" 2>&1 | head -5` (verify DB connection) |
| **Full suite command** | manual review of 87-AUDIT-REPORT.md and SKILL.md diff |
| **Estimated runtime** | ~5 seconds (DB connection check) |

---

## Sampling Rate

- **After every task commit:** Verify output file exists and has expected structure
- **After every plan wave:** Manual review of artifact completeness
- **Before `/gsd-verify-work`:** AUDIT-REPORT.md complete + SKILL.md diff reviewed
- **Max feedback latency:** N/A (manual artifact)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 87-01-01 | 01 | 1 | SACC-01 | — | N/A | manual | `ls .planning/phases/87-stance-accuracy-audit-agent-update/87-AUDIT-REPORT.md` | ❌ W0 | ⬜ pending |
| 87-02-01 | 02 | 2 | SACC-04 | — | N/A | manual | `grep -c "five chairs\|five-chairs" .claude/skills/research-stances/SKILL.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test stubs needed — this phase produces a Markdown artifact and edits SKILL.md. Verification is by inspection.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| AUDIT-REPORT.md contains all required columns (name, party, office, stance_count, flagged_count, priority_tier, flagged_topics) | SACC-01 | Markdown table — no automated schema validation | Open report, verify header row matches spec in CONTEXT.md D-06 |
| 8 confirmed inversions appear in confirmed-inversion tier | SACC-01 | Pre-seeded data check | Grep for "Jeff Gonzalez", "Roger Niello", "Angie Nixon", "Alex Vindman", "Tim Grayson", "Ashley Hinson", "Derek Dooley", "Adam Hinojosa" in AUDIT-REPORT.md |
| Known-correct cases (Collins, Murkowski, etc.) are documented as reviewed-and-confirmed | SACC-01 | Narrative section check | Grep for "Collins" or "VanDeaver" in AUDIT-REPORT.md |
| Audit SQL block is present in AUDIT-REPORT.md | SACC-01 | Markdown code block — visual check | Grep for ```sql in AUDIT-REPORT.md |
| SCALE RULE — CRITICAL block removed from SKILL.md | SACC-04 | Text content check | `grep "SCALE RULE" .claude/skills/research-stances/SKILL.md` should return no matches |
| Five-chairs framing block present in SKILL.md | SACC-04 | Text content check | `grep -c "five chairs\|five-chairs\|named chairs" .claude/skills/research-stances/SKILL.md` should return ≥ 1 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
