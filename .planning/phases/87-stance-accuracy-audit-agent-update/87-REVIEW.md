---
phase: 87-stance-accuracy-audit-agent-update
reviewed: 2026-06-02T22:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - .claude/skills/research-stances/SKILL.md
findings:
  critical: 2
  warning: 2
  info: 1
  total: 5
status: issues_found
---

# Phase 87: Code Review Report

**Reviewed:** 2026-06-02T22:00:00Z
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

This review covers the single file changed in phase 87-02: `.claude/skills/research-stances/SKILL.md`. The change replaced a 6-line `SCALE RULE — CRITICAL` block with a 20-line `FIVE-CHAIRS FRAMING` block, extended the Topic Resolution query to fetch stance texts via `json_agg`, and added a `TOPIC SCALE REFERENCE` section inside the agent prompt template.

The five-chairs framing itself is correct and well-written. Two bugs were introduced (or exposed) that affect correctness of the dispatched agent prompt and the jurisdiction resolution query. Two pre-existing quality issues are also documented.

## Critical Issues

### CR-01: "Format each topic for the agent like this:" orchestrator instruction is inside the agent prompt fenced block

**File:** `.claude/skills/research-stances/SKILL.md:129`

**Issue:** Lines 129–136 contain an orchestrator meta-instruction that tells the orchestrating agent how to format topic data before passing it to the researcher. This block reads:

```
Format each topic for the agent like this:
  [topic_key] (id: [uuid])
  Question: "[question_text]"
    1 = "[stance text for value 1]"
    ...
```

This instruction is inside the fenced code block that spans lines 92–158. Everything inside that block is literal agent-prompt text — it gets pasted verbatim into the researcher agent's prompt. The researcher agent will receive "Format each topic for the agent like this:" as an instruction directed at itself, which is meaningless (the researcher is not formatting anything for itself) and will produce confusing context.

The intent is for the orchestrator to see this formatting guide and use it when composing the prompt. But because it sits inside the backtick fence, it will be passed through to the researcher agent unchanged.

**Fix:** Move lines 129–136 outside the fenced code block, placing them as a callout between the `[PASTE THE FULL JSON OUTPUT...]` placeholder line and the closing fence — or, preferably, as a note in the orchestrator-facing prose before the fence opens. One correct structure:

```markdown
TOPIC SCALE REFERENCE — assign values by matching to exact stance text:
[PASTE THE FULL JSON OUTPUT FROM THE TOPIC RESOLUTION QUERY HERE — including id, topic_key, question_text, and the stances array with value+text for each of the 5 levels]

The topic_key in your CSV output MUST exactly match one of the topic_key values above.
...
```

And outside the fence, add:

```markdown
> **Orchestrator note:** When pasting the JSON output, format each topic entry as:
>   [topic_key] (id: [uuid])
>   Question: "[question_text]"
>     1 = "[stance text for value 1]"
>     ...
```

This ensures the researcher only receives stance text, not orchestrator formatting instructions.

---

### CR-02: `o.is_current = true` in Jurisdiction Resolution query references a non-existent column

**File:** `.claude/skills/research-stances/SKILL.md:35`

**Issue:** The Jurisdiction Resolution query (STEP 0) joins `essentials.offices` and filters on `o.is_current = true`. Per PATTERNS.md (phase 87 patterns map, line 141): "The `essentials.offices` table has NO `is_current` column. Use `LIMIT 1` subquery, not a join on `is_current = true`." This query will fail at runtime with a column-does-not-exist error whenever a user invokes the skill with a legislative body name (e.g., "California State Senate").

This bug predates phase 87 but is present in the reviewed file.

**Fix:**

```javascript
const { rows } = await pool.query(`
  SELECT p.id, p.full_name,
         (SELECT o2.title FROM essentials.offices o2
          WHERE o2.politician_id = p.id LIMIT 1) AS title,
         c.name as chamber_name
  FROM essentials.politicians p
  JOIN essentials.chambers c ON c.name ILIKE '%' || $1 || '%'
  WHERE EXISTS (
    SELECT 1 FROM essentials.offices o3
    WHERE o3.politician_id = p.id
  )
  ORDER BY p.full_name
`, [process.argv[2]]);
```

Or at minimum remove the `o.is_current = true` filter and replace with a `LIMIT 1` subquery on `o.title`, matching the established pattern used in lines 395–397 (the rewrite mode proposals query).

---

## Warnings

### WR-01: Stale topic count comment (43 → 44 live topics)

**File:** `.claude/skills/research-stances/SKILL.md:72`

**Issue:** Line 72 reads: "As of 2026-05-16 there are 43 live topics; this number will grow." The RESEARCH.md for this same phase (line 307) records: "44 live topics (as of 2026-06-02; previously documented as 43 — one was added)." The comment was not updated when the new topic was added. This is a minor discrepancy, but when an orchestrator reads this line to estimate scope for the user confirmation message (line 77: "3 politicians x 43 topics = up to 129 stance assessments"), it will show the wrong number.

**Fix:** Update line 72 to read: `As of 2026-06-02 there are 44 live topics; this number will grow.`

---

### WR-02: Normal mode Step 4b DB push script: sequential upserts without a transaction — partial write on failure

**File:** `.claude/skills/research-stances/SKILL.md:248–274`

**Issue:** The Step 4b DB push script (lines 248–274) issues individual `pool.query()` calls for `politician_answers` and `politician_context` inside a `for` loop with no wrapping transaction. If the process crashes or the DB connection drops mid-loop (e.g., at row 30 of 50), the `politician_answers` row for a politician may be upserted while the corresponding `politician_context` row is not, leaving orphaned answer records with no reasoning or sources. The script has no BEGIN/COMMIT and no rollback path.

The rewrite mode step 4a (lines 467–484) has the same pattern: each `admin_upsert_stance_proposal` RPC call is fired individually in a loop with no outer transaction.

**Fix:** Wrap the loop in a transaction using `pool.query('BEGIN')` and `pool.query('COMMIT')`, with a `try/catch` for `pool.query('ROLLBACK')`:

```javascript
await pool.query('BEGIN');
try {
  for (const s of stances) {
    await pool.query(`INSERT INTO inform.politician_answers ...`, [...]);
    await pool.query(`INSERT INTO inform.politician_context ...`, [...]);
  }
  await pool.query('COMMIT');
  console.log('Done: ' + stances.length + ' stances upserted');
} catch (err) {
  await pool.query('ROLLBACK');
  console.error('Rolled back due to error:', err.message);
  process.exit(1);
}
```

---

## Info

### IN-01: Topic Resolution query drops `short_title` column that the previous query included

**File:** `.claude/skills/research-stances/SKILL.md:56–64`

**Issue:** The pre-phase-87 Topic Resolution query selected `id, topic_key, title, short_title, question_text`. The updated query (phase 87) selects `t.id, t.topic_key, t.title, t.question_text` — `short_title` is omitted. This is not wrong if `short_title` was not being used by agents, but the omission is silent and unexplained. If any downstream agent prompt template or UI component expected `short_title` in the JSON blob, it will silently receive `undefined`. The CONTEXT.md and PATTERNS.md for this phase do not mention this column removal, making it an undocumented behavioral change.

**Fix:** If `short_title` is unused by researcher agents, add a comment in SKILL.md noting the deliberate omission: `-- short_title intentionally excluded: not needed by researcher agent`. If it is needed, restore it to the SELECT clause.

---

_Reviewed: 2026-06-02T22:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
