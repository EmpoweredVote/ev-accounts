# NEXT TASK — the dead-URL long tail

Self-contained spec. Act on Mass is finished (1532 legislators, 1533 bills, 1534 a tracking-parameter
fix). Skim both reviews before starting — `2026-08-02-actonmass-wayback-resourcing.md` and
`2026-08-02-actonmass-bills-repoint.md` — the failure modes below all came out of them.

## The job

**~790 URLs / ~1,400 row-citations** still dead, across many hosts. Worklist:
`2026-08-02-deep-url-findings.json` (+ `.md` / `.jsonl`), minus everything on `actonmass.org`.

Biggest hosts: **ontheissues.org 157 · newtonma.gov 102 · wbur.org 66**, then a long tail of ones and
twos. Work host by host — a host is a shape, and the shape is what you solve once.

For each host, the Act on Mass passes suggest the same four questions, in order:

1. **Is it dead, renamed, redirected, or rebuilt?** These are four different remedies and a status
   code alone distinguishes none of them.
2. **Does the live successor still carry the claim?** A rename that drops the evidence is not a fix.
3. **Does Wayback have it, and from the right era?**
4. **Was the URL ever valid?** Some 404s are composed URLs, not removals.

## 🔴 Rules that will bite — every one of these has already cost a pass

1. **A 200 is not existence, and a 404 is not removal.** Gatsby/WordPress/React front ends serve
   soft-404s with 200, and real pages behind client-side routing. Measure status, final URL after
   redirects, and whether the body is a not-found shell — separately.
2. **Classify every non-200 before reading it as absence.** 403 = bot block (Ballotpedia: `curl -A`
   with a browser UA works where WebFetch never does), 202 = mitigation, 404/410 = gone, **504 =
   retry**. The 08-02 sweep found 4,333 row-citations in 202/403 that are perfectly fine.
3. **An empty CDX body is a query-form artifact as often as a real absence.** Try `url=<u>`, then
   `url=<u>/`, then `url=<u>*`, then the host form, and only call it absent when all of them return
   parseable, genuinely empty JSON.
4. 🔴 **Group CDX captures by the FULL URL, not the path.** Merging them lets a tracking-parameter
   capture win on recency — that is exactly how 1533 published a supporter's `emci`/`emdi`/`ceid`
   contact IDs and needed 1534 to undo it. Strip or reject query-string captures when a clean one
   exists.
5. 🔴 **Pages have generations.** Cite the version the row rests on, not the newest. **CDX `digest`
   will not detect content change** — dated chrome (a newsletter blurb, a "latest post" rail) moves the
   digest on every crawl while the substance is identical.
6. 🔴 **The evidence may live in an attribute.** Act on Mass encoded co-sponsorship purely as
   `img.green_check` vs `img.red_x`, invisible to any text grep. Before judging "the page doesn't say
   it", check whether the page says it in markup.
7. **Read pages with `scripts/read-site.mjs`** (greps RAW HTML, prints `raw=/body=/chrome=`). If it
   looks empty, re-check with **`scripts/read-site-js.mjs`** — but note Playwright now draws a
   *"Checking your browser…"* 403 on some hosts, which is a block, not an absence.
8. **Any long job must checkpoint.** `nohup`, append results as they arrive, and give every `fetch` an
   `AbortSignal.timeout` — a CDX call without one hung a pass for ten minutes with an empty log.

## Migration rules

Generate → `scripts/dry-run-migration.mjs` (always rolls back) → `npx tsx scripts/_apply-file.ts`.
Rollback record first. Scope every assertion to **(politician_id, topic_id)**.

- ⚠ **`array_replace` substitutes ONE value.** If any row cites two mapped URLs it will silently leave
  the second dead. Check first; rewrite the whole array if so.
- ⚠ **Group per-target assertions by the TARGET,** and count **distinct rows**, not summed source
  counts — two sources can share a destination.
- ⚠ **Row-citations are not rows.**
- ⚠ **Simulate the post-state read-only rather than deriving it by arithmetic.** Derivation was wrong
  twice in one migration.
- ⚠ **Assert that the rows you deliberately held are untouched.** A wildcard UPDATE would sweep them up.

## Context

- Gate: `npm run check:stance-sources --prefix backend` — green, **643 rows, 3 checks**.
  `NON_URL_SOURCE` is **0 and zero-tolerance**.
- Last applied: **1534**. Next number: 1535 (confirm with `scripts/check-migration-numbers.mjs`).
  ⚠ That script also reports a pre-existing collision on `1527_repair_prose_in_sources.sql` vs
  `1527_repair_split_sources.sql` in the working tree — not yours, but don't let it mask a real one.
- Full state: `.planning/todos/2026-07-30-stance-resourcing-backlog.md` → **HANDOFF 2026-08-02 (third)**.

## Also owed, in rough value order

1. **Act on Mass rows owed re-research — 227.** 22 legislator pages Wayback never captured (196 rows,
   **113 sole-sourced**) · Peisch ×11 and Livingstone ×5 (only a prior session's board) · 15 rows on the
   four unidentifiable bills (all have a second source). Tables in the two reviews.
2. **The 11 contradicted + 19 mixed rows from 1532** — the archive now refutes them in writing. Three
   name the source's own checkmark and invert it; check how far that pattern runs past this host.
3. **Brooks × 2** — ⏳ operator decision; sources verify but the chairs don't fit their axes.
4. **`evandone.com` × 11** — cites 2026 content that no longer exists; is it archived?
5. **32 JS-shell rows** — never actually read; `read-site-js.mjs`, and expect bot walls.
