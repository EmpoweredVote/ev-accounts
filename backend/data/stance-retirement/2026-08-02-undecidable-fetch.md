# Fetch pass over the 187 undecidable rows — and three publications that never existed

Migration 1538 deliberately left 187 rows undecided: they still cite a composed URL, and **every** one
of their other citations had been classed `BOT_BLOCKED` or `FETCH_FAILED` by the deep sweep. A 403 says
nothing (ten such URLs returned one identical 4,215-byte block page), so those rows could be neither
retired nor cleared without a real fetch. This is that fetch.

Artifacts: `2026-08-02-undecidable-fetch.json` · `scripts/_tmp-undecidable-fetch.mjs`.
Method: browser User-Agent, **serial** with a 900 ms delay, windows-1252 tolerated, soft-404 test that
does not require a space, surname matched with diacritics folded.

## Result: the undecidable rows are almost all decidably unsupported

103 distinct citations fetched.

| fetch outcome | urls |
|---|---|
| connection failed outright | **60** |
| HTTP 403 | 24 |
| HTTP 404 | 15 |
| **readable** | **4** |

| row verdict | rows |
|---|---|
| 🔴 STILL_UNREACHABLE | **183** |
| OTHER_SOURCE_NAMES_POLITICIAN | 4 |

⚠ **The sweep's classes were wrong again, in both directions.** All 15 hard 404s had been classed
`GONE` (12) or `BOT_BLOCKED` (3) — so 3 "blocked" URLs are simply missing pages. And 3 of 103 that the
sweep called blocked/failed read perfectly well under a browser UA. Same lesson as the tail pass:
**re-probe before believing a stored class**, in both directions.

⚠ The 24 remaining 403s are concentrated on **congress.gov ×14** — a real host with a real bot wall.
Those citations are probably fine and simply cannot be verified this way; they are not evidence of a
defect.

## 🔴 THE REAL FINDING: three cited publications have no trace of ever existing

Grouping the 60 connection failures by host produced this:

| host | citations | Wayback, domain-wide |
|---|---|---|
| somervillejournal.com | 34 | **captures back to 2001** — real paper, dead domain |
| newtonobserver.com | 11 | captures from 2011 — real domain |
| **medfordmirror.com** | 5 | 🔴 **NOTHING. EVER.** |
| **newtonvillearea.com** | 2 | 🔴 **NOTHING. EVER.** |
| **walthamatch.com** | 1 | 🔴 **NOTHING. EVER.** |

Verified two independent ways for each: `archive.org/wayback/available` returns
`{"archived_snapshots":{}}` **and** a CDX wildcard query (`url=<host>*`) returns `[]`. The control
worked — `somervillejournal.com` returns real captures from 2001 through the same tooling, and its
availability call drew the documented **429** while CDX answered correctly, which is exactly why both
methods were run.

For a local news outlet to have **zero** captures across Wayback's entire history is not a crawl gap.
These are invented publications.

🔴 **`walthamatch.com` settles any doubt: it is `walthampatch.com` with the "p" missing.** Patch's real
Waltham site has Wayback captures from 2011. One is a real outlet; the other is a one-character
corruption of its name, cited as a source.

⚠ **And the invented URLs are richly specific**, which is what makes them dangerous:
`medfordmirror.com/2022/10/bears-question-1-fair-share/`,
`medfordmirror.com/2020/07/medford-council-police-reform-scarpelli-dissent/`,
`newtonvillearea.com/2025/10/laredo-wins-newton-mayoral-race.html` — correct real politicians (Zac
Bears, Lungo-Koehn, Scarpelli), correct real issues, plausible dates, house-style slugs. Nothing about
them looks wrong until you try to fetch one.

**Scope: 32 distinct URLs · 51 row-citations · 14 politicians · 0 sole-sourced.**

🔴 **This is a NEW cohort, not part of the 209 retired by 1538.** The composed set was built from URLs
the sweep had already classed `GONE`; these were classed `FETCH_FAILED`, so they never entered it. The
defect is one step worse than a composed path — **a composed outlet** — and it means the sweep's
`FETCH_FAILED` bucket (308 URLs) has never been examined for it.

## What is owed

1. ⏳ **Operator decision on the 51 rows.** All 51 carry another citation, but they sit inside the
   `STILL_UNREACHABLE` set, so those other citations do not resolve either. Same "no checkable evidence"
   shape as the 209 already retired.
2. 🔴 **Sweep the whole `FETCH_FAILED` bucket (308 URLs) for invented domains** — domain-level Wayback
   absence is the test, and it is cheap. This is the highest-value next check.
3. **The 183 STILL_UNREACHABLE rows** are now measured rather than assumed. Retire or re-research.
4. ⚠ **`somervillejournal.com` ×34 is the opposite case and must not be swept up with them**: a real
   publication whose domain has lapsed. Those citations should be re-pointed to Wayback captures, which
   exist in quantity, not retired.
