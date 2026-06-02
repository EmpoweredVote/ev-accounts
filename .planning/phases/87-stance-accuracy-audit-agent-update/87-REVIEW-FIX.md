---
phase: 87-stance-accuracy-audit-agent-update
fixed_at: 2026-06-02T22:30:00Z
review_path: .planning/phases/87-stance-accuracy-audit-agent-update/87-REVIEW.md
iteration: 1
fix_scope: critical_warning
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 87: Code Review Fix Report

**Fixed at:** 2026-06-02T22:30:00Z
**Source review:** .planning/phases/87-stance-accuracy-audit-agent-update/87-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (CR-01, CR-02, WR-01, WR-02)
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: Orchestrator formatting instruction moved outside agent prompt fence

**Files modified:** `.claude/skills/research-stances/SKILL.md`
**Commit:** 9b72a24
**Applied fix:** Removed the "Format each topic for the agent like this:" block (7 lines) from inside the backtick-fenced agent prompt template (which spans lines 92–149). Added it as an `> **Orchestrator note:**` blockquote immediately after the closing fence, before the `Use \`subagent_type\`` line. The researcher agent now only receives stance texts, not orchestrator formatting instructions.

---

### CR-02: `o.is_current = true` removed from Jurisdiction Resolution query

**Files modified:** `.claude/skills/research-stances/SKILL.md`
**Commit:** 08f2d43
**Applied fix:** Replaced the STEP 0 Jurisdiction Resolution query's broken `JOIN essentials.offices o ON o.politician_id = p.id ... AND o.is_current = true` pattern with a correlated subquery `(SELECT o2.title FROM essentials.offices o2 WHERE o2.politician_id = p.id LIMIT 1) AS title` for the title column, and an `EXISTS (SELECT 1 FROM essentials.offices o3 WHERE o3.politician_id = p.id)` clause to ensure only politicians with offices are returned. The `essentials.offices` table has no `is_current` column; this query previously would have failed at runtime with a column-does-not-exist error.

---

### WR-01: Stale topic count updated from 43 to 44

**Files modified:** `.claude/skills/research-stances/SKILL.md`
**Commit:** 1358529
**Applied fix:** Updated the comment on line 76 from "As of 2026-05-16 there are 43 live topics" to "As of 2026-06-02 there are 44 live topics". Also updated the example scope estimate in the confirmation message from "3 politicians x 43 topics = up to 129 stance assessments" to "3 politicians x 44 topics = up to 132 stance assessments".

---

### WR-02: Step 4b upsert loop wrapped in BEGIN/COMMIT transaction

**Files modified:** `.claude/skills/research-stances/SKILL.md`
**Commit:** a39ba8b
**Applied fix:** Wrapped the `for (const s of stances)` loop in the Step 4b DB push script with `await pool.query('BEGIN')` before the loop, `await pool.query('COMMIT')` after the loop inside a `try` block, and a `catch` handler that calls `await pool.query('ROLLBACK')`, logs the error, and calls `process.exit(1)`. This ensures all upserts for a batch are atomic — a mid-loop failure no longer leaves orphaned `politician_answers` rows without corresponding `politician_context` rows.

---

_Fixed: 2026-06-02T22:30:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
