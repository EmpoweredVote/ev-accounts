---
id: 260420-rh4
slug: readrank-quote-limit-deid
status: complete
date: 2026-04-20
---

# Quick Task 260420-rh4: Read-Rank quote limit + deidentification

## Outcome

Read-Rank quote pool went from **114 quotes (over-quota in 8 groups)** to **92 curated quotes (max 2 per politician/topic) with 13 deidentified for blind ranking**.

## Tasks completed

### Task 1 — Migration + backend `COALESCE`  *(commit `be4719a`)*
- Added `essentials.quotes.deidentified_text TEXT NULL` column.
- Snapshot backup: `essentials.quotes_backup_260420` preserves the original 114-row state.
- Backend `/api/essentials/quotes` now serves `COALESCE(deidentified_text, quote_text) AS text` so read-rank gets the deidentified version when present, original otherwise.
- TypeScript typecheck clean.

### Task 2 — Interactive curation  *(commit `31e7d6c`)*
- 8 over-quota groups walked through with user one-by-one.
- 3 user-approved text edits (clarifications, not deidentification): bracket "[the jail]", trim dated tail with ellipsis, add Fourth Amendment context.
- 22 quotes deleted (cascade to `inform.compass_verdicts` = 0 rows).
- Decision log: [`CURATION.md`](CURATION.md).
- Result: 0 over-quota groups remain, 92 live rows.

### Task 3 — LLM-assisted deidentification  *(this commit)*
- Scanned all 92 surviving quotes against 4 reveal patterns.
- 53 initial flags; reduced to 17 candidates after applying the user's "lighter touch" principle (broad state names like "California"/"Indiana" don't identify; only narrow reveals do).
- Drafted side-by-side review at [`DEID-REVIEW.md`](DEID-REVIEW.md).
- 13 rewrites approved (with brackets `[]` marking substitutions per user convention).
- 4 explicitly reviewed and kept original.
- Stored in `deidentified_text`; `quote_text` originals preserved.

## Reveals scrubbed

| Pattern | Examples |
|---|---|
| Explicit office claims | "As Lieutenant Governor of California", "as Lieutenant Governor", "As long as I'm a commissioner", "since I came to the Senate" |
| Acts only one office can do | "I'm directing the state", "I signed an executive order", "We are signing 17 bills", "I am declaring a state of emergency" |
| Party self-ID | "our own Democratic Party", "Indiana Republicans drew maps" |
| Specific district | "Santa Clarita Valley and the Antelope Valley" (CA-27) |
| Vote claim + state | "I voted yes on the USMCA. It is a better deal for Indiana..." |
| State-leg → Congress transition | "I fought for expanded coverage in the state legislature, and I will bring that same commitment to Congress..." |

## Reveals deliberately not scrubbed

State names alone ("California", "Indiana", "Hoosier"), generic "we" as state/community, bill numbers without authorship claims, broad policy advocacy without office claim. Too broad to identify.

## Deliverables

- **Code:** `ev-accounts/backend/migrations/070_quotes_deidentified_text.sql`, updated `ev-accounts/backend/src/routes/essentials.ts`
- **DB state (production `kxsdzaojfaibhuzmclfq`):**
  - `essentials.quotes`: 92 live rows (was 114), 13 with `deidentified_text` populated
  - `essentials.quotes_backup_260420`: 114-row snapshot, untouched
- **Decision logs:** [`CURATION.md`](CURATION.md), [`DEID-REVIEW.md`](DEID-REVIEW.md)

## Followups (out of scope, captured for later)

- One quote (`5e316990`) was mis-categorized as `jail-capacity` but is about tax legislation. Deleted as part of Task 2 curation; if more mis-categorizations exist in the broader 92-row pool, a topic-correctness audit is its own task.
- The plan called for a reusable `ev-accounts/backend/scripts/deidentifyQuotes.ts` script with Claude API + prompt caching. Skipped because the user wanted a one-shot interactive review instead. If new quotes are ingested in the future, this becomes worth building.
- Backend route change is committed but only takes effect when ev-accounts deploys to Render (api.empowered.vote).

## Verification

```sql
-- 0 over-quota groups
SELECT politician_id, topic_key, COUNT(*) FROM essentials.quotes GROUP BY 1,2 HAVING COUNT(*) > 2;
-- (0 rows)

-- 13 deidentified
SELECT COUNT(*) FROM essentials.quotes WHERE deidentified_text IS NOT NULL;
-- 13

-- backup intact
SELECT COUNT(*) FROM essentials.quotes_backup_260420;
-- 114
```
