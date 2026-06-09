# Design: research-stances → Read & Rank quote path

**Date:** 2026-06-07
**Status:** Approved (pending spec review)
**Author:** Chris Andrews + Claude

## Problem

Read & Rank (readrank.empowered.vote) is a blind candidate-match game. Its API
(`/api/readrank/*`, `backend/src/lib/readrankService.ts` on `master`) serves
**only** `essentials.quotes.deidentified_text`, never `quote_text`. A race becomes
playable only when **≥2 candidates** in it each have **≥1 de-identified quote** on a
**live** `inform.compass_topics` topic.

The `research-stances` skill researches politician stances and the
`politician-stance-researcher` agent already collects exact verbatim quotes — but
those quotes have **nowhere to go**:

- The researcher CSV omits a quote column, so quotes get buried in `reasoning` or dropped.
- STEP 4 pushes only to `inform.politician_answers` (value) and
  `inform.politician_context` (reasoning + source URLs).
- A separate verification pass writes auto-extracted source snippets to
  `inform.politician_context_evidence` (178 rows, all verified) and
  `inform.stance_research_review`. These snippets contain the speaker's name and
  paraphrase — the opposite of de-identified — and still never reach `essentials.quotes`.

**The only path that has ever populated `essentials.quotes` is bespoke one-shot
scripts** (e.g. `backend/scripts/push-monroe-county-research.ts`) reading hand-curated
quote CSVs. So local-lens research stances never surface in Read & Rank.

## Goal

Make the `research-stances` skill capture a verbatim quote **and** a de-identified
version per stance, and push de-identified quotes into `essentials.quotes` so Read &
Rank can serve them. Keep **all** quotes as a library; use exactly **one** per
(politician, topic) for Read & Rank, swappable when a better quote is found.

## Key decisions (from brainstorming)

1. **Capture at research time** — extend the researcher CSV + agent, not a separate
   promotion script. (Does not retro-promote the 178 stranded evidence snippets.)
2. **Researcher produces both** `quote_text` and `quote_deidentified` in one pass.
3. **One quote per stance is used by Read & Rank**, but **keep all** quotes —
   `essentials.quotes` allows multiple rows per (politician, topic); a
   `readrank_selected` flag designates the one Read & Rank serves.
4. **Single CSV, extra columns** (Approach A).
5. **Conflict handling** — never delete on a new quote. When a (politician, topic)
   already has quotes, the STEP 3 approval gate shows existing vs new and the human
   picks which is `readrank_selected`.
6. **Admin selector** lives in the **ev-accounts admin panel** as a **new top-level
   nav entry** ("Read & Rank Quotes"), NOT on the public profile/Citations page.

## Architecture / components

### 1. Schema migration — `essentials.quotes`

- Add `readrank_selected boolean NOT NULL DEFAULT false`.
- Partial unique index enforcing at most one selected per stance:
  `CREATE UNIQUE INDEX quotes_one_selected_per_stance
   ON essentials.quotes (politician_id, lower(topic_key)) WHERE readrank_selected;`
- **Backfill**: for every existing `(politician_id, lower(topic_key))` group, set
  exactly one row `readrank_selected = true`. Deterministic pick (e.g. `DISTINCT ON` /
  `row_number()` ordering): `deidentified_text IS NOT NULL DESC`, then
  `created_at ASC NULLS LAST`, then `id ASC` (since `created_at` is nullable). This keeps
  the 3 currently-live races (Ninth District, District 061, Monroe County Commissioner)
  serving identical quotes.
- No down-data-loss: migration down drops the column/index only.

### 2. Read & Rank route filter — `backend/src/lib/readrankService.ts` (on `master`)

Add `AND q.readrank_selected = true` to all three quote filters:
- `getPlayableRaces` (the `WHERE q.deidentified_text IS NOT NULL` join)
- `getRaceBlindQuotes`
- the reveal/match query (`computeRaceMatch`)

After this, Read & Rank serves only the selected, de-identified quote per stance.

> **Cross-branch dependency.** This route is on `master`, not `feat/admin-review-queue`.
> The implementation must apply this change wherever the route currently lives and
> coordinate the deploy so the column exists before the filter ships (migration first).

### 3. Researcher CSV schema (Approach A)

Append two columns to the `politician-stance-researcher` output CSV:

```
full_name,external_id,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3,quote_text,quote_deidentified
```

- `quote_text` — single best **exact verbatim** quote for the stance; blank if the
  position is only documented via voting record/paraphrase (no quotable sentence).
- `quote_deidentified` — same quote, speaker identity scrubbed (minimum change); blank
  if `quote_text` is blank, or if it can't be de-identified without destroying meaning.
- Both are free text → RFC-4180 escaped. **Parsing uses `csv-parse/sync`** (already a
  dependency), never manual string splitting.

### 4. Agent definition — `.claude/agents/politician-stance-researcher.md`

- Add the two columns to the **OUTPUT FORMAT** section.
- **Quote capture rule**: capture one verbatim quote per topic — the politician's own
  words. Blank rather than paraphrase.
- **De-identification rules** (embed, mirroring `backend/scripts/deidentifyQuotes.ts`
  system prompt):
  - SCRUB: the speaker's own name; explicit office claims ("as Senator", "since I came
    to Congress", "I'm a commissioner"); acts only one office can do ("I signed an
    executive order", "I met with President X"); party self-ID; naming the
    incumbent/opponent; district-narrowing that identifies the seat.
  - KEEP: bare state/demographic names (e.g. "Indiana", "Hoosier", "California");
    generic "we"; bill names without an authorship claim; broad policy advocacy.
  - Minimum change — only edit identity-revealing phrases. Blank if undoable.
- **Self-audit**: confirm `quote_deidentified` contains no speaker name or office claim.

### 5. Skill — `.claude/skills/research-stances/SKILL.md`

- **STEP 2 (collect)**: parse new columns via `csv-parse/sync`.
- **STEP 3 (approval summary)**:
  - Show a quote column rendering `quote_deidentified` per row.
  - Flag rows where `quote_text` is present but `quote_deidentified` is blank
    ("needs manual de-id — won't be Read-&-Rank-eligible").
  - For each `(politician, topic)` that **already has** quote(s) in `essentials.quotes`,
    show existing (verbatim + de-id) vs new and ask which should be `readrank_selected`
    (default: keep current selection).
- **STEP 4 — new sub-step 4d "Push quotes":** for each approved, name-resolved row with
  non-blank `quote_text`:
  - **Keep-all insert** into `essentials.quotes`: `politician_id`, `topic_key` (lower),
    `quote_text`, `deidentified_text` = `quote_deidentified` (nullable),
    `source_url` = first non-blank `source_url_*`, `source_name` = URL host or NULL.
    Never deletes existing rows.
  - **Idempotency**: skip if a row already exists with the same
    `(politician_id, lower(topic_key), quote_text)`.
  - **Selection**: if the stance has no `readrank_selected` row yet → mark the new one
    selected (only if it has `deidentified_text`); if it does → apply the STEP 3 choice,
    flipping the flag transactionally so exactly one stays selected.
  - **Leak-check (safety net)**: scan each candidate `deidentified_text` for the
    politician's surname; refuse to mark a leaking quote `readrank_selected` and report it.
- **STEP 4c (report)**: counts for pushed / skipped-dupe / skipped-blank-quote /
  selection-changed / leak-held, plus a reminder that a race becomes playable only at
  **≥2 candidates with a selected de-identified quote on a live topic**.
- **Rewrite mode (`--rewrite-id`)**: unchanged / out of scope.

### 6. Admin Read & Rank quote selector (ev-accounts admin panel)

**Backend (this branch), admin-guarded (`requireAuth` + `requireAdmin`):**
- `GET /api/admin/readrank-quotes?politician_id=…` → all `essentials.quotes` rows for
  that politician grouped by topic: `id`, `quote_text`, `deidentified_text`,
  `source_url`, `source_name`, `readrank_selected`.
- `PUT /api/admin/readrank-quotes/select` (body `{ quote_id }`) → in one transaction,
  set `readrank_selected = true` on `quote_id` and `false` on its siblings (same
  `politician_id` + `lower(topic_key)`). Reject (422) if the target's
  `deidentified_text IS NULL` — a non-blind quote can't be the Read & Rank pick.

**Frontend (admin app):**
- New top-level nav entry **"Read & Rank Quotes"** in `admin/src/pages/admin/AdminLayout.tsx`
  `links` array + a route + a new page component.
- Page: pick a politician → list quotes grouped by topic, each showing verbatim +
  de-identified text + source, with a radio to choose the Read & Rank pick. Mirrors the
  public Citations layout for familiarity. Lets a curator swap in a better quote anytime,
  independent of a research run.

**Public `essentials/src/pages/Citations.jsx`:** unchanged.

## Data flow

```
politician-stance-researcher
  └─ CSV (… , quote_text, quote_deidentified)
       └─ STEP 3 human approval (sees de-id text; resolves selection conflicts)
            └─ STEP 4 push
                 ├─ stances → inform.politician_answers / politician_context  (unchanged)
                 └─ quotes  → essentials.quotes (keep-all; one readrank_selected)  (NEW)
                                   │
        admin "Read & Rank Quotes" page ──(PUT select)── flips readrank_selected
                                   │
                 Read & Rank route filters readrank_selected = true + deidentified_text NOT NULL
```

## Error handling / edge cases

- **CSV escaping**: free-text quote columns may contain commas and quote marks →
  RFC-4180 + `csv-parse/sync`.
- **quote_text present, quote_deidentified blank**: insert the quote (library), but it
  is not eligible for `readrank_selected`; report as "needs manual de-id".
- **No source URL**: insert with `source_url` / `source_name` NULL (both nullable).
- **Exact duplicate** `(politician_id, lower(topic_key), quote_text)`: skip insert.
- **Selection of a non-de-identified quote**: blocked at both the skill push and the
  admin endpoint.
- **Surname leak in deidentified_text**: held by the leak-check; not auto-selected.
- **Backfill correctness**: exactly one selected per existing stance; verify the 3 live
  races serve the same quotes pre/post migration.

## Scope / non-goals

- **No retro-promotion** of the 178 `inform.politician_context_evidence` snippets.
- **No race creation / candidate linking** — the ≥2-quoted-candidate gate still governs
  playability; the skill only reports it.
- Rewrite mode of the skill is untouched.
- The public Citations page is untouched.

## Testing

- **Migration**: up adds column + index; backfill yields exactly one selected per stance;
  the playability query returns the same 3 races with the same quotes as before.
- **Read & Rank filter**: with `readrank_selected` applied, the 3 live races still serve
  their expected quotes; a stance with 2 quotes serves only the selected one.
- **Skill push (dry-run on a small batch)**: keep-all insert; selection set on first
  quote; conflict prompt flips selection; exact-dupe skip; leak-check holds a planted
  un-scrubbed quote.
- **Admin endpoints**: GET groups by topic; PUT select flips exactly one; PUT rejects a
  NULL-deid target; non-admin is forbidden.
- **Admin UI**: selecting a different quote updates Read & Rank's served quote end-to-end.

## Affected files (summary)

- `backend/migrations/NNN_*.sql` — add `readrank_selected` + index + backfill (NEW)
- `backend/src/lib/readrankService.ts` *(master)* — 3 query filters
- `backend/src/routes/admin.ts` (or a new `readrankQuotesAdmin.ts`) + wiring in `index.ts`
- `.claude/agents/politician-stance-researcher.md`
- `.claude/skills/research-stances/SKILL.md`
- `admin/src/pages/admin/AdminLayout.tsx` + new admin page + route
