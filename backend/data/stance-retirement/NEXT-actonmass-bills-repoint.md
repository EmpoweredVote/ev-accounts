# NEXT TASK — Act on Mass `/bills/` re-points

Self-contained spec. Everything needed is on disk. The `/legislators/` pass that preceded this is done
(migration **1532**); its review is `2026-08-02-actonmass-wayback-resourcing.md` and you should skim the
four numbered lessons in it before starting — at least two apply directly here.

## The job

**26 URLs · 196 row-citations.** Unlike `/legislators/`, these pages were **renamed, not removed**:

```
https://actonmass.org/bills/safe-communities-act/   →   https://actonmass.org/safe-communities/
```

So the remedy is a **live-site re-point**, not a Wayback one. Map each slug from the site's own
`sitemap-1.xml`. 🔴 **Do not guess the transform** — `/bills/safe-communities-act/` → `/safe-communities/`
drops both the `/bills/` prefix and the `-act` suffix, and there is no reason to expect that to hold.

The worklist is inside `2026-08-02-deep-url-findings.json` (filter `host = actonmass.org`, path prefix
`/bills/`). Rows are reachable with the same query shape as before:

```sql
SELECT pc.politician_id, pc.topic_id, pc.reasoning, pc.sources, s
  FROM inform.politician_context pc
  JOIN inform.politician_answers pa
    ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id AND pa.value <> 0
  CROSS JOIN LATERAL unnest(pc.sources) s
 WHERE s ILIKE '%actonmass.org/bills/%';
```

## 🔴 Rules that will bite on THIS task

1. **Verify the renamed page still carries the claim.** A rename is not a guarantee of continuity — the
   new page can be a stub, or a different bill for a new session. Same test as 1531/1532: does the
   destination contain what the row asserts?
2. **These bill pages carry a co-sponsor roster, and it is the same attribute-encoded evidence.** The
   archived `/bills/safe-communities-act/` page lists committee members with `/legislators/<slug>` links
   under "Who has co-sponsored" — so a claim about *who* signed on is checkable here too, and again not
   from tags-stripped text alone.
3. **Classify every non-200 before reading it as absence.** 403 = bot block, 202 = Ballotpedia-style
   mitigation, 404/410 = gone, **504 = retry**. The 08-02 sweep found 4,333 row-citations sitting in
   202/403 that are perfectly fine.
4. **Read pages with `scripts/read-site.mjs`** (greps RAW HTML, prints `raw=/body=/chrome=`). If a page
   looks empty, re-check with **`scripts/read-site-js.mjs`** — actonmass.org is **Gatsby/React**, and its
   `/legislator-search/` page has *zero* legislator links in raw HTML while rendering a full roster.
   Individual content pages are server-rendered; index/search pages are not.
5. **Any long job must checkpoint.** Launch detached with `nohup`, append results as they arrive, and
   give every `fetch` an `AbortSignal.timeout` — a CDX call with no timeout hung the 08-02 pass for ten
   minutes with an empty log.
6. **Migrations:** generate → `scripts/dry-run-migration.mjs` (always rolls back) → `npx tsx
   scripts/_apply-file.ts`. Rollback record first. Scope every assertion to **(politician_id, topic_id)**.
   ⚠ **Group per-target assertions by the TARGET, not the source URL** — if two dead URLs map to one
   destination, a per-source count double-counts and fails every one of them. That is exactly how the
   first 1532 dry run failed.

## Context

- Gate: `npm run check:stance-sources --prefix backend` — green, **643 rows, 3 checks**.
  `NON_URL_SOURCE` is **0 and zero-tolerance**.
- Last migration applied: **1532**. Next number: 1533 (confirm with `scripts/check-migration-numbers.mjs`).
  ⚠ That script currently also reports a pre-existing collision on `1527_repair_prose_in_sources.sql`
  vs `1527_repair_split_sources.sql` in the working tree — unrelated to this task, but do not let it
  mask a real collision of your own.
- Full state: `.planning/todos/2026-07-30-stance-resourcing-backlog.md` → **HANDOFF 2026-08-02 (second)**.
- Sweep results: `2026-08-02-deep-url-findings.md` (+ `.json` / `.jsonl`).

## After this, in order

1. **Act on Mass rows owed re-research — 212.** 22 legislator pages Wayback never captured (196 rows,
   **113 sole-sourced**, so they cite nothing that resolves) plus Peisch ×11 and Livingstone ×5, whose
   only captures are a prior session's board. Per-politician table in the 1532 review.
2. **The 11 contradicted + 19 mixed rows from 1532** — the archive now refutes them, in writing. Three
   name the source's own checkmark and invert it; check whether that pattern extends past this host.
3. **The dead long tail** — ~790 urls / ~1,400 rows, many hosts (ontheissues 157, newtonma.gov 102,
   wbur 66).
4. **Brooks × 2** — ⏳ operator decision, sources verify but chairs don't fit their axes.
5. **`evandone.com` × 11** — cites 2026 content that no longer exists; is it archived?
6. **32 JS-shell rows** — never actually read; use `read-site-js.mjs`.
