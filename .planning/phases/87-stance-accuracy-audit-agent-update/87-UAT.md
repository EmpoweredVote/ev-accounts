---
status: complete
phase: 87-stance-accuracy-audit-agent-update
source: [87-01-SUMMARY.md, 87-02-SUMMARY.md]
started: 2026-06-02T22:45:00Z
updated: 2026-06-02T23:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Audit Report — Three-Tier Structure
expected: 87-AUDIT-REPORT.md exists in the phase directory. It contains three priority tiers: Tier 1 (8 confirmed-inversion entries: Jeff Gonzalez, Roger Niello, Angie Nixon, Alex Vindman, Tim Grayson, Ashley Hinson, Derek Dooley, Adam Hinojosa), Tier 2 (borderline entries), and Tier 3 (likely-correct bulk entries). Audit SQL is embedded in a fenced code block.
result: pass

### 2. Five-Chairs Framing in SKILL.md
expected: Opening .claude/skills/research-stances/SKILL.md shows a FIVE-CHAIRS FRAMING block in the Step 1 agent prompt. The block references "five named chairs in a room", instructs value assignment by matching documented record to chair text (never by party/direction), and includes a defensibility claim. The old SCALE RULE — CRITICAL block is absent.
result: pass

### 3. Stance Texts Embedded in Agent Prompt
expected: The Topic Resolution query (STEP 0) in SKILL.md joins inform.compass_stances using json_agg to include stance text values alongside topic IDs and keys. A TOPIC SCALE REFERENCE section appears inside the agent prompt template so dispatched agents see the full 1–5 scale text for each topic at dispatch time.
result: pass

### 4. Orchestrator Note Outside Agent Fence
expected: The formatting instruction "Format each topic for the agent like this" appears as an > **Orchestrator note:** blockquote OUTSIDE and after the fenced code block that defines the agent prompt template. It is not inside the fence — researcher agents receive stance texts and framing instructions, not orchestrator meta-instructions.
result: pass

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
