---
name: 260420-rh4 Context
id: 260420-rh4
slug: readrank-quote-limit-deid
status: ready_for_planning
gathered: 2026-04-20
---

# Quick Task 260420-rh4: Read-Rank quote limit + deidentification - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Task Boundary

Read-Rank surfaces candidate quotes that users evaluate blind, then reveals the speaker. Two problems with the current quote pool in `essentials.quotes`:

1. **Volume:** some politicians have many quotes on one topic. Cap at **2 per (politician, compass topic)**.
2. **Identity leaks:** some quotes explicitly reveal the speaker (office title, jurisdiction, self-naming, proper nouns). The ranking phase must be blind; the reveal happens later in the UX.

Data source: `essentials.quotes` table, served via `GET /api/essentials/quotes` (ev-accounts/backend/src/routes/essentials.ts:191). Frontend at `read-rank/` consumes via `fetchQuotesData()` (read-rank/src/data/api.ts:16).

</domain>

<decisions>
## Implementation Decisions

### Enforcement layer — Data cleanup (delete rows)
- Permanently delete excess quote rows from `essentials.quotes`. No query-level cap, no frontend cap.
- Rationale: user wants a clean pool; extras aren't used anywhere else.

### Selection — Interactive curation with user in the loop
- For every (politician_id, topic_key) group with >2 quotes, present **all** quotes in that group to the user and let them pick **1 or 2** to keep. Remaining rows are deleted.
- Must be an interactive workflow, not an automated heuristic.
- Selection UI: Claude lists each group inline with quote text + source_url, asks user which to keep (via AskUserQuestion multiSelect where `maxItems=4`, falling back to plain-text numbered prompts when a group has >4 quotes).

### Deidentification — LLM-assisted rewrite pipeline
- Detect quotes that reveal the speaker, then use Claude to rewrite them preserving meaning/tone. Human approves each rewrite before it's saved.
- Preserve the original: add a new column `essentials.quotes.deidentified_text` (nullable). Frontend reads `deidentified_text` when present, else falls back to `quote_text`. Reveal screen can still reference original if needed.
- Backend `/api/essentials/quotes` serves `deidentified_text ?? quote_text` as the `text` field to read-rank.

### Detection scope — all four patterns
Flag a quote if it contains any of:
1. **Office titles:** "As Senator", "my time as Governor", "in Congress", "on the Council", etc.
2. **Jurisdiction/location:** "in my district", "here in California", "Hoosiers", city/state names matching the politician's record.
3. **Self-naming / first-person office:** "I, [Name]", "my administration", "our caucus", "my campaign".
4. **Proper nouns matching candidate record:** politician's full_name, last name, district name, party name, or office title appearing in their own quote.

Detection is a candidate-generating scan — the LLM rewrite + human approval is the filter for false positives.

### Claude's Discretion
- Exact regex patterns for each of the four categories — planner/executor to assemble.
- Prompt wording for the LLM rewrite (will aim for: preserve stance/tone, strip reveal cues, keep under original length, neutral third-person-friendly phrasing).
- Ordering: do curation (delete) **first**, then deidentification on the surviving pool — smaller, cleaner input for the LLM step.
- Where the script runs: one-shot Node/tsx script under `ev-accounts/backend/scripts/`, similar pattern to `importBudgetHierarchy.ts`.

</decisions>

<specifics>
## Specific Ideas

- Reuse `tsx` script pattern at `ev-accounts/backend/scripts/` — runs against Supabase using existing `DATABASE_URL`.
- Claude API call via `@anthropic-ai/sdk` with prompt caching on the system prompt (rewrite rules are identical across calls).
- Both the curation step and the deidentification approval step are interactive from Claude Code — Claude drives the prompts via AskUserQuestion + plain-text follow-ups.
- Backup before destructive delete: `COPY essentials.quotes TO 'backup-quotes-260420.csv'` or a `SELECT … INTO essentials.quotes_backup_260420` snapshot table.

</specifics>

<canonical_refs>
## Canonical References

- Backend route: `ev-accounts/backend/src/routes/essentials.ts:191` — `/api/essentials/quotes`
- Frontend fetch: `read-rank/src/data/api.ts:16` — `fetchQuotesData()`
- Script pattern: `ev-accounts/backend/scripts/importBudgetHierarchy.ts`
- `essentials.quotes` columns observed in query: `id, quote_text, politician_id, source_url, source_name, topic_key` (plus implicit `created_at` presumed — planner to verify)

</canonical_refs>
