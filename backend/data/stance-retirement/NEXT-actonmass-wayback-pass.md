# NEXT TASK — Act on Mass legislator pages → Wayback

Self-contained spec. Everything needed is on disk; nothing depends on the 2026-08-02 conversation.

## The job

**147 dead URLs · 1,318 row-citations** — worklist already extracted, sorted by rows affected:
`data/stance-retirement/2026-08-02-actonmass-legislators-dead.json`

`actonmass.org/legislators/<name>/` pages were **removed** (verified: not in `sitemap-1.xml`, not in
site nav, no equivalent path — this is NOT a rename, unlike `/bills/`). They were almost certainly
per-legislator voting-record/scorecard pages, so they are high-value evidence for Massachusetts rows.
Act on Mass is a prominent org → Wayback coverage is plausible but **unconfirmed**.

Remedy shape if captures exist: **migration 1532, the 1519 pattern** — re-point the citation at
`web.archive.org/web/<ts>/<url>`, retire nothing.

⚠ **9 of the 147 are trailing-slash duplicates of another URL** (`/mindy-domb` vs `/mindy-domb/`).
Resolve both, and check they land on the same capture.

## 🔴 Rules that WILL bite on this task — all learned the hard way

1. **Query CDX unfiltered, and try BOTH forms.** `collapse=urlkey` once reported 2 snapshots where
   there were 46 (neighbors4faye, 1519). And on 2026-08-02 the `url=host*` form returned an EMPTY body
   for `erinforutah.com` while `url=host` found the capture — **an empty CDX response is a query-form
   artifact as often as a real absence.** Try `url=<u>`, then `url=<u>/*`, then the host form.
2. **A capture existing is NOT a usable source.** Verify the snapshot CONTAINS what the row asserts.
   Jemison's only capture is a 2,026c landing page that supports none of her claims — she was correctly
   NOT re-sourced. Malik's carries every specific — she was (1531). Same rule decided both.
3. **Classify every non-200 before reading it as absence.** 403 = bot block, 202 = Ballotpedia-style
   mitigation, 404/410 = gone. This sweep found 4,333 row-citations in 202/403 that are perfectly fine.
4. **Read pages with `scripts/read-site.mjs`** (greps RAW HTML, prints `raw=/body=/chrome=` counts).
   If a page looks empty, re-check with **`scripts/read-site-js.mjs`** (Playwright, prints plain vs
   rendered) — every other tool here is blind to JS shells.
5. **Any long job must checkpoint.** The deep sweep was killed twice as a harness-tracked background
   task and lost an hour the first time. Launch detached with `nohup` and append results as they arrive.
6. Migrations: generate → `scripts/dry-run-migration.mjs` (always rolls back) → `_apply-file.ts`.
   Rollback record first. Scope every assertion to **(politician_id, topic_id)**, never politician
   alone — that mistake in 1524 and 1530 each surfaced a real extra defect, so narrow the check *and*
   fix what it found.

## Context

- Gate: green, 649 rows, 3 checks. `NON_URL_SOURCE` is **0 and zero-tolerance**.
- Last migration applied: **1531**. Next number: 1532 (confirm with `scripts/check-migration-numbers.mjs`).
- Full state: `.planning/todos/2026-07-30-stance-resourcing-backlog.md` → **HANDOFF 2026-08-02**.
- Sweep results: `2026-08-02-deep-url-findings.md` (+ `.json` / `.jsonl`).

## After this, in order

1. **actonmass `/bills/` re-points** — 26 urls / 196 rows, genuinely renamed
   (`/bills/safe-communities-act/` → `/safe-communities/`). Map each slug from `sitemap-1.xml`; don't
   guess the transform.
2. **The 1,594-row dead long tail** — ~790 urls, many hosts (ontheissues 157, newtonma.gov 102, wbur 66).
3. **Brooks × 2** — ⏳ operator decision, sources verify but chairs don't fit their axes.
4. **`evandone.com` × 11** — cites 2026 content that no longer exists; is it archived?
5. **32 JS-shell rows** — never actually read; use `read-site-js.mjs`.
