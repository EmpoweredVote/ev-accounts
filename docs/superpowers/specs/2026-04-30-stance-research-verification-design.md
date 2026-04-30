# Stance Research Verification — Design Spec

**Date:** 2026-04-30
**Status:** Approved, ready for implementation planning
**Owners:** chrisandrewsedu

## Problem

The current `/research-stances` pipeline produces hallucinated data. Two failure modes have been observed:

1. **Fake quotes.** The `politician-stance-researcher` agent invents quotes that do not appear in the cited article.
2. **Real-but-irrelevant articles.** The agent cites a real URL where the politician is mentioned, but the article does not actually discuss the stance being claimed.

The existing `/verify-sources` skill catches these problems only after data is in the production database, requires LLM-based page judgment, and runs as a manual batch job. By the time it surfaces a problem, the bad data has already been visible to users.

## Goal

Add an automated verification gate between research and database push so that data reaching the production tables has been mechanically verified to be grounded in real source pages, with no LLM in the verification loop.

## Non-goals

- Domain reputation enforcement (deferred — handled by existing `/verify-sources` post-hoc audit)
- LLM-based snippet→reasoning relevance check (deferred; reserved as follow-up if review-queue patterns show snippets passing verification but not actually supporting the stated reasoning)
- Replacing the existing `/verify-sources` skill (it stays; it gets a small upgrade)
- Quote verification for read-rank (separate system; out of scope)

## Architecture

A three-stage pipeline replaces the current two-stage one.

### Stage 1: Research with evidence capture

The `politician-stance-researcher` agent is updated to require verbatim snippets for every source it cites. The CSV format splits in two:

**`stances.csv`** — one row per (politician, topic):
```
full_name,external_id,topic_key,value,reasoning
```

**`evidence.csv`** — one row per snippet:
```
full_name,topic_key,source_url,snippet,snippet_index
```

Multiple snippets per source URL are allowed and encouraged when the politician is cited in multiple places in the same article. `snippet_index` preserves order. A source URL with zero snippets does not appear in `evidence.csv` and therefore is not a source.

The agent prompt enforces a "no snippet = no source" rule prominently. If the agent cannot capture an exact passage from the page that mentions the politician's position, it does not have that source.

### Stage 2: Automated verification

A new deterministic Node module verifies each evidence row before any DB write. Per-snippet verdicts:

- `verified` — snippet appears verbatim on the page (after normalization) and politician name is in proximity
- `snippet_not_found` — snippet does not appear on the page
- `name_not_present` — snippet is on the page but the politician's name does not appear within 500 characters of the snippet (and is not in the snippet itself)
- `snippet_too_short` — snippet is fewer than 25 words; rejected as too coincidence-prone
- `url_broken` — fetch failed (DNS, 4xx/5xx, timeout, paywall)

A source is `verified` if at least one of its snippets is verified. Failed sources are dropped from the row.

### Stage 2.5: Bounded re-research

A row falls below the **minimum-source threshold** (default 2) when verified sources are insufficient. Such rows trigger a single re-dispatch of `politician-stance-researcher` for that one (politician, topic) pair, with the original failed sources/URLs included in the prompt as context ("these did not verify; find different sources").

The re-research output goes through verification again. **Only one re-research attempt per row per batch** — if the row still falls short, it goes to the review queue.

### Stage 3: Gated DB push + review queue

- Rows clearing the threshold push to `inform.politician_answers` + `inform.politician_context` (existing flow, unchanged).
- Verified evidence is also persisted to a new `inform.politician_context_evidence` table.
- Rows below threshold (after re-research) write to a new `inform.stance_research_review` table with full audit trail of failed verifications.

## Data Shapes

### CSV format

Two files per batch, joined on `(full_name, topic_key)`:

`stances.csv`:
```
full_name,external_id,topic_key,value,reasoning
```

`evidence.csv`:
```
full_name,topic_key,source_url,snippet,snippet_index
```

### New tables

**`inform.politician_context_evidence`** — persisted snippets for verified rows:

```sql
CREATE TABLE inform.politician_context_evidence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  politician_id uuid NOT NULL REFERENCES essentials.politicians(id) ON DELETE CASCADE,
  topic_id uuid NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  source_url text NOT NULL,
  snippet text NOT NULL,
  snippet_index int NOT NULL,
  verified_at timestamptz NOT NULL DEFAULT now(),
  batch_id text,
  FOREIGN KEY (politician_id, topic_id)
    REFERENCES inform.politician_context(politician_id, topic_id) ON DELETE CASCADE
);
CREATE INDEX ON inform.politician_context_evidence (politician_id, topic_id);
CREATE INDEX ON inform.politician_context_evidence (source_url);
```

On re-research/upsert, evidence for `(politician_id, topic_id)` is replaced (delete + insert) — old snippets describe stale reasoning.

**`inform.stance_research_review`** — review queue for rows that fail verification:

```sql
CREATE TABLE inform.stance_research_review (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id text NOT NULL,
  politician_id uuid REFERENCES essentials.politicians(id),
  full_name_raw text NOT NULL,
  topic_id uuid REFERENCES inform.compass_topics(id),
  topic_key text NOT NULL,
  proposed_value smallint,
  proposed_reasoning text,
  evidence jsonb NOT NULL,
  verified_source_count int NOT NULL,
  threshold int NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  re_research_attempted boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  resolved_by uuid,
  notes text
);
CREATE INDEX ON inform.stance_research_review (status, batch_id);
CREATE INDEX ON inform.stance_research_review (politician_id, topic_id);
```

Status values: `pending | resolved | rejected | superseded | unresolved_politician`.

The `evidence` jsonb keeps the full audit trail — every snippet the verifier saw, its verdict, and the failure reason — so an admin opening the row sees the failure mode inline without re-running anything.

## Components

### 1. `politician-stance-researcher` agent (modified)

- New requirement: emit `evidence.csv` alongside `stances.csv`.
- "No snippet = no source" rule prominent in the prompt.
- Snippet length guidance: 25–300 words, capture surrounding context.
- Multiple snippets per source allowed and encouraged.
- Re-research mode: prompt accepts an `--exclude-urls` list and prior-failure context so re-dispatched runs avoid known-bad sources.
- Files: `.claude/agents/politician-stance-researcher.md` and the `ev-accounts/.claude/` mirror.

### 2. New verifier module (new code)

`ev-accounts/backend/src/lib/researchVerifier.ts` — pure-function-style:

- Input: parsed `stances.csv` + `evidence.csv` + politician name lookup
- Output: `{ pushable: [...], needsReResearch: [...], reviewQueue: [...] }`
- For each evidence row: fetch URL (cached per batch), normalize whitespace/quotes/dashes/case, run `pageText.includes(normalize(snippet))`, run name-proximity check (last name within 500 chars, or full name; common last names require title qualifier).
- No LLM involvement. Deterministic and testable.
- Caches fetched pages per batch — same URL across multiple snippets = one fetch.

### 3. `/research-stances` skill (modified orchestrator)

New flow:

- **STEP 2.5** (between current STEP 2 and STEP 3): run verifier; dispatch single re-research per row below threshold; re-run verifier; partition into `pushable` / `reviewQueue`.
- **STEP 3** (approval summary): three counts shown — auto-verified, verified after re-research, sent to review queue.
- **STEP 4** (DB push): atomic per-row — upsert `politician_answers`, upsert `politician_context`, replace `politician_context_evidence`. On any failure, mark row for review.
- **STEP 5** (new): write review-queue rows to `inform.stance_research_review`.

Rewrite mode (`--rewrite-id`) gets the same verification flow. Failed proposals auto-reject through the existing rewrite mechanism instead of going to a review queue (the rewrite workflow has its own gating).

### 4. `/verify-sources` skill (light upgrade)

Updated to prefer `politician_context_evidence.snippet` as the verification target when present. Falls back to current LLM page-judgment behavior only when no stored snippet exists. Cheaper and more accurate over time as evidence accumulates.

## File Layout

- **New:** `ev-accounts/backend/src/lib/researchVerifier.ts` + tests + `__fixtures__/`
- **New:** Migration in `ev-accounts/backend/migrations/` for both new tables
- **New:** `.claude/skills/research-stances/README.md` — durable architecture/decisions doc (this spec is point-in-time; the README is the living doc that travels with the code)
- **Modified:** `.claude/agents/politician-stance-researcher.md` (+ `ev-accounts/.claude/` mirror)
- **Modified:** `.claude/skills/research-stances/SKILL.md`
- **Modified:** `.claude/skills/verify-sources/SKILL.md`

## Edge Cases

(Documented in detail in `.claude/skills/research-stances/README.md`.)

- **Whitespace/quote/dash normalization** before string match. Lowercase both sides.
- **Snippet length bounds:** min 25 words, persistence cap 300 words (full snippet still verified).
- **Common last names:** require title qualifier (Sen./Rep./Mayor) within proximity if last name alone is ambiguous.
- **Paywalled pages:** treated as `url_broken` with reason `gated`. Conservative — we cannot verify.
- **WebFetch timeout:** retry once, then `url_broken`.
- **Re-research returning no new sources:** row goes to review queue with note. Signal that topic should probably be skipped for that politician.
- **`value=null` rows:** skip verification, drop in normal mode (was always a "skip" signal); auto-reject in rewrite mode.
- **Politician name doesn't resolve:** review-queue row with `politician_id=null`, `full_name_raw` preserved, status `unresolved_politician`.
- **Batch ID:** stable per batch (e.g. `2026-04-30-bloomington-council-1`); used in CSV filenames and as a column on review/evidence rows for traceability.
- **Idempotency:** upserts on answers/context already idempotent. Evidence replaced by `(politician_id, topic_id)`. Review queue upserted by `(batch_id, politician_id, topic_id)`.

## Testing Strategy

- **Unit tests for `researchVerifier.ts`** (Vitest): snippet matching variants, normalization, name proximity, common-last-name handling, WebFetch error mapping, multi-snippet source logic, threshold logic, page caching. Use `__fixtures__/` of frozen HTML snapshots; mock WebFetch.
- **Integration smoke test:** one real end-to-end run against a known small-footprint politician on 2–3 topics. Verify all three tables get rows; eyeball snippets against cited pages.
- **Migration test:** runs cleanly on fresh dev DB. Run `/research-stances` once with the *old* agent prompt (no snippets) — confirm graceful fallback (everything to review queue with reason `no_snippets_provided`).
- **No tests for agent prompt itself** — the review queue is the regression detector.

## Decisions Log

The key decisions made during brainstorming, with rationale:

1. **Inline + post-research verification (option C in initial brainstorm).** Inline gives cheap fabrication-resistance via snippet capture; post-research is where the deterministic match runs.
2. **Snippet-as-evidence over LLM page judgment.** Cheap, parallel, deterministic. The snippet itself becomes the audit trail. LLM judgment deferred.
3. **A+C for verification rules (verbatim string match + name proximity).** B (LLM relevance check on snippet→reasoning) deferred until review-queue patterns show it's needed. Rationale: the snippet→reasoning visual check is fast for a human reviewer when both are visible in one row.
4. **B+C for failure handling.** Drop individual failed sources (keeps good rows moving); zero-source rows to review queue. Stricter "any failure = review" rejected as too disruptive.
5. **Dedicated `inform.stance_research_review` table** (not CSV, not reusing `public.source_verifications`). Persistent, queryable, lets patterns of agent failure become visible across batches.
6. **Persist verified snippets to `inform.politician_context_evidence`.** Enables `/verify-sources` to get cheaper/more accurate over time and supports a future admin UI showing exactly what justified each stance.
7. **Two CSVs (stances + evidence) over one fat CSV or JSON column.** Mirrors eventual table structure; each file readable on its own; verifier walks `evidence.csv` row-by-row.
8. **Multiple snippets per source allowed.** Politicians often cited in multiple paragraphs of one article.
9. **Minimum source threshold = 2, default.** Below threshold triggers re-research.
10. **Single re-research attempt per row per batch.** Prevents runaway loops while giving the agent a real second chance.
11. **Verifier as deterministic TypeScript code (not a sub-skill).** Testable, deterministic, not subject to LLM drift.
12. **Domain reputation deferred.** The two observed failure modes (fake quotes, irrelevant articles) are both caught by snippet+name-proximity. Domain reputation is a different problem.

## Out of Scope / Follow-ups

- LLM-based snippet→reasoning relevance check (option B from initial brainstorm). Add if review-queue patterns show snippets verifying but reasoning not actually supported by them.
- Domain reputation gate. Available via existing `/verify-sources`; promote into pre-push pipeline if needed.
- Admin UI for the review queue. Schema is built for it; UI is a separate effort.
- Read-rank quote verification using the same machinery (different table shape; future work).
