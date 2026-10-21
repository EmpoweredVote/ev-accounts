# Blind drafter prompt — Stage 2

**Orchestrator notes (do not send this part).**
- Fill every `{{…}}` with absolute paths, then send everything below the line as the prompt of a fresh subagent
  (general-purpose, the strongest model available). Note its agent id.
- Fill `{{FORBIDDEN_PATHS}}` with an explicit list of absolute paths. Do not rely on a glob: search the research
  root for every `s3-census-*`, `s3-pilot-*` and `s3-prep-*` folder for this topic (by topic key and short name) and
  list each one, plus this trail's `stage0a/rows.tsv`, `stage0/`, `stage1/`, `stage3/`, the source store, the
  side-session notes folders, the shadow-run folders and the named memory notes.
- Every path in `{{FORBIDDEN_PATHS}}` is also a `--forbid` for the blindness check. After the drafter finishes, run:

  ```bash
  npm run topic:blindness-check --prefix backend -- \
    --transcript ~/.claude/projects/<project-key>/<session-id>/subagents/agent-<agentId>.jsonl \
    --forbid <abs path> [--forbid <abs path> …] \
    --out <abs research folder>/stage2/blindness-check.txt --cwd <abs repo root>
  ```

  Use absolute paths everywhere (npm runs the CLI from `backend/`). Exit 0 = PASS: record it. Exit 1 = a forbidden
  read: the draft is **void**; delete `stage2/drafts.md` and start a fresh drafter. Exit 3 = no tool calls found:
  wrong transcript; find the right one. Exit 2 = bad flags or unreadable file; fix and re-run. A draft without a
  PASS in `blindness-check.txt` is never used.

---

You are the **blind drafter** for the compass topic `{{TOPIC_KEY}}` (Season {{SEASON}} prep). You write draft ladders
(five rungs each) that records can seat, following the rulebook. You must not see the test set, so that the
drafts are not fitted to it.

## Why this matters

Every compass topic must seat as many politicians as the evidence honestly allows, and follow the rulebook so that
a chair means the same everywhere. This topic's audit found: {{DIAGNOSIS_HEADLINE}}. You are fixing the wording.
You are not lowering the evidence standard.

## You may read

- The rulebook: `docs/superpowers/specs/2026-10-07-season3-design.md` §2 (L1–L10) and §4 (T1–T6), and the rulings in
  `docs/superpowers/specs/2026-10-07-season3-ladder-evaluation.md` ("Rulebook rulings"; "Evidence rules,
  seatability test", including the T6 stated-act rule and the L3 "a bar is an act" clarification).
- The codebook: `docs/codebook/stance-and-quote-codebook.md` (version {{CODEBOOK_VERSION}}).
- The standing rulebook: `.claude/skills/season-topic-prep/RULINGS.md`.
- The topic's current annex: {{ANNEX_PATH}}.
- The Stage 0a diagnosis: {{DIAGNOSIS_PATH}} (kinds of loss, no names).
- Earlier pilots' Stage 2 drafts, for format only: {{FORMAT_PRECEDENT_PATHS}}.
- One read-only query of the live revision tables for this topic (`inform.compass_topic_revisions`,
  `inform.compass_stance_revisions`, `inform.compass_topic_roles`, `inform.season_questions`).

## 🔴 You must not open, list or search

{{FORBIDDEN_PATHS}}

This always includes: the Stage 0a row list (`stage0a/rows.tsv`), every census folder for this topic (listed
above by name), the Stage 1 test set (`stage1/`), Stage 3 (`stage3/`), the source store
(`backend/data/source-store/`), the side-session notes folders, shadow runs
(`backend/data/stance-research/*-shadow-*-{{TOPIC_KEY}}/`), the topic's Stage 1 plan, and these memory notes:
{{FORBIDDEN_MEMORY_NOTES}}. Do not look up bill numbers, board names or people. Describe example acts **by kind**
only. Your transcript is checked for reads of these paths afterwards; one read voids the draft.

## What to write: `{{OUT_PATH}}` (stage2/drafts.md)

Header: date, operator, "DRAFT for ruling", a **Blindness** paragraph naming what you did not open (by kind, never
by path: a forbidden path written into your file counts as a read) and what you did read, an **Exposure**
paragraph (any gold row or named item that informed you), **Seat cost (T5)** from the query, and the design of the
comparison.

- **§0 Control** — the live revision copied verbatim (id, revision, version, class, pins, title, question,
  guidance, levels asked), each rung with its rulebook defects, the T6 lint result, and why it fails.
- **§1 Shared design** — the proposed question and guidance, the L1 poles, the scope line for the topic's object,
  and the rungs both drafts share with their map from the control.
- **§2 Draft A** and **§3 Draft B** — two drafts that **differ in one place only** (one rung), so a Stage 3
  difference has one cause. For each: the reading, the five rungs, a rationale per rung against L1–L10, the annex
  lines the draft needs (furthest act, per-rung evidence, higher-law duty), and an evidence-by-rung-and-level table
  (which act would evidence each rung at each level that holds a lever; own words only where there is no lever).
- **§4 Rulebook check** — a table of L1–L10 and T6 for control, A and B; the T6 lint (degree words, "and",
  "at most", "without", "only", "while", every/any/all — the list in `backend/scripts/lib/ladderLint.ts`) with a
  written reason for any hit you accept; and the stated-act table: each neighbouring pair differs by a stated act,
  never by silence ("every time", "even with", "no exception").
- **§5 Risks for Stage 3** — named before the test (single-subject overlaps with other served topics, gates,
  rungs likely to stay empty).
- **§6 Open questions** — one plain question each, with your recommendation and its cost.
- **§7 Rulings** — leave empty; the orchestrator fills it.

Do not code any person or test item. Do not write to the database. Return a five-line summary.
