# NEXT TASK — ⏳ OPERATOR DECISION: 1,166 rows cite pages that never existed

**This is not a task to execute. It is a decision to take, and then a large amount of work either
way.** Read `2026-08-02-dead-url-tail.md` first.

## What was established

Of 623 cited URLs the deep sweep called `GONE` (excluding actonmass.org), **497 URLs / 1,166
row-citations point at pages there is no evidence ever existed**:

- they return a hard 404 today;
- Wayback has **never** captured them, in any query form;
- yet Wayback holds **3,000+ distinct URLs in the same directory** on the same hosts —
  `wbur.org/news/`, `mass.gov/info-details/`, `newtonma.gov/government/`,
  `somervillema.gov/departments/`, `bhcourier.com/article/`, `pressley.house.gov/issues/`,
  `ontheissues.org/House/`.

The mechanism is not in doubt: on OnTheIssues the *real* pages were found, and the cited URLs turned
out to use a single invented path shape for a site that files members under four different ones. Those
136 rows were fixed (1535). The rest have no findable real page.

🔴 **Re-pointing cannot fix these.** A citation to a page that never existed is not a dead link; it is
a row whose stated evidence cannot be checked by anyone.

## The decision

1. **Re-research** — send the 1,166 rows back through stance research with a live-URL requirement.
   Expensive, preserves coverage, and only worth it if the underlying chairs are sound.
2. **Retire** — remove the rows. Cheap, honest, and visibly reduces coverage on ~190 hosts' worth of
   local officials.
3. **Split by stakes** — retire where the row is sole-sourced (**61 rows**), re-research the rest
   (1,105 have at least one other source, so they are not currently unsupported).

⚠ **Only 61 of the 1,166 are sole-sourced.** The other 1,105 carry a second citation, so the immediate
voter-facing harm is much smaller than the row count suggests — but the second source has not been
checked for the same defect, and that check is the obvious precondition for option 3.

## ⚠ Do not over-apply the finding

Four hosts are a genuine Wayback coverage gap, not composed URLs — Wayback holds almost nothing of them
at all: `lynnma.gov/city-council/` (0 siblings), `alhambraca.gov/government/` (7),
`carsonca.gov/government/` (67), `medfordma.org/city-council/` (78). **30 URLs / 115 rows.** These
deserve a hand pass, not a bulk verdict.

Two `sgvtribune.com` URLs have a malformed date path (`/2021/08/slug`, missing the day segment the site
requires) and are plausibly composed too — but the host returns 403 to everything, so it cannot be
settled remotely.

## The obvious next question, and it is bigger than this queue

The sweep only classified URLs by reachability. **A composed URL that happens to resolve would have
passed as `OK`** — and 15,405 URLs / 51,168 row-citations passed as OK. Nothing has tested whether a
resolving cited page actually supports its row, except where this workstream has looked by hand and
found 11 contradicted rows on Act on Mass alone.

Before spending on re-research, consider sampling the `OK` set: pick 100 rows at random, fetch, and
check the page names the politician and carries any quoted span (`_tmp-tail-verify.mjs` already does
exactly this and is the tool for it). The result decides whether this is a tail problem or a corpus
problem.

## Method notes for whoever picks this up

- 🔴 **A throttled `archive.org/wayback/available` response is indistinguishable from a real absence** —
  it returns `{"archived_snapshots":{}}` either way. Run it **serially**; treat any non-200 as a retry.
- 🔴 **CDX is too slow for per-URL lookups at scale**: 4s / 36s / 60s-504 for three forms of one page.
  Use availability for yes/no and spend CDX on per-host sibling coverage — that query is what turned
  "not archived" into "never existed".
- 🔴 **Re-probe before believing any stored class.** This pass found 64 of 623 misclassified: 43 now
  resolve, 11 `THIN` are HTTP 200 with correct titles (SPA shells and PDFs — no extractable body text
  is not a dead page), 10 `BOT_BLOCKED` return an identical block page so the 403 means nothing.
- ⚠ **Encoding matters.** OnTheIssues serves windows-1252; decoding as UTF-8 faked five failed
  verifications. Accented names fail naive title tests (`García` vs `Garcia`).
- ⚠ **A quoted compass chair label is not a quotation from the source.** Detect it structurally: a
  quoted span reused across 3+ different politicians is our vocabulary, not the page's.

## Context

- Gate: `npm run check:stance-sources --prefix backend` — green, **643 rows, 3 checks**.
  `NON_URL_SOURCE` is **0 and zero-tolerance**.
- Last applied: **1535**. Next number: 1536. ⚠ `check-migration-numbers.mjs` also reports a
  pre-existing collision on `1527_repair_prose_in_sources.sql` vs `1527_repair_split_sources.sql` in
  the working tree — not yours, but don't let it mask a real one.
- Migration rules that cost four dry runs last time: `array_replace` substitutes ONE value per
  statement · group per-target assertions by the TARGET and count DISTINCT ROWS · targets may already
  carry healthy citations, so expected counts are the post-state UNION · simulate the post-state
  read-only rather than deriving it · assert that deliberately-held rows are untouched.

## Also still owed

1. **Act on Mass — 227 rows.** 22 legislator pages Wayback never captured (196 rows, 113 sole-sourced)
   · Peisch ×11 and Livingstone ×5 (prior-session captures only) · 15 on four bills Act on Mass never
   tracked.
2. **The 11 contradicted + 19 mixed rows from 1532** — the archive now refutes them in writing. Three
   name the source's own checkmark and invert it.
3. **22 rows held in 1535** on archived URLs the capture does not support, plus Ghazala Hashmi ×22.
4. **Brooks × 2** — ⏳ operator decision; sources verify but the chairs don't fit their axes.
5. **`evandone.com` × 11** — cites 2026 content that no longer exists; is it archived?
6. **32 JS-shell rows** — never actually read; expect bot walls (Playwright now draws a
   *"Checking your browser…"* 403 on some hosts).
