# Composed citations — the second-source check that option 3 depends on

`NEXT-composed-citations.md` offers three ways to dispose of the 1,166 row-citations pointing at pages
that never existed, and recommends **option 3: retire the sole-sourced (61 rows), re-research the rest
(1,105)** — while noting the precondition plainly: *"the second source has not been checked for the
same defect, and that check is the obvious precondition for option 3."*

**This is that check. Option 3's split is wrong by 3.4×.**

Artifacts: `2026-08-02-composed-secondsource.json` · `scripts/_tmp-composed-secondsource.mjs`.
Method: live `sources` arrays joined against the deep sweep's per-URL classes and the rebuilt composed
set. **No re-probe** — so link rot since 2026-08-02 is not reflected (see the perishability warning in
handoff (sixth)).

## The composed set, rebuilt rather than taken from prose

The write-up's own figures could not all be right (518 never-archived, 497 composed, 30 on thin hosts),
so it was recomputed:

| | URLs |
|---|---|
| never captured by Wayback, dead on re-probe | 518 |
| …**composed** (host well covered, our URL never served) | **494** |
| …held out as a genuine Wayback gap on four thin hosts | 24 |

⚠ **Hold the thin hosts out by HOST, not by path.** The write-up names them as directory prefixes
(`lynnma.gov/city-council/`), and matching those prefixes caught only **6 of the 24** — the rest sit
under `/news/`, `/departments/` and `/government/mayor`. The finding is about how thinly Wayback covers
the whole host, so a path-scoped holdout silently under-protects the exception.

## The result

**903 rows cite at least one composed URL.**

| bucket | rows | |
|---|---|---|
| HAS_A_RESOLVING_OTHER_SOURCE | **506** | another citation resolves; re-research is optional, not urgent |
| OTHERS_UNJUDGEABLE | **188** | every other citation is bot-walled or unreachable — **undecidable from the artifacts** |
| ALL_SOURCES_COMPOSED | **138** | two or more citations, **all** composed |
| SOLE_SOURCED_COMPOSED | **61** | exactly one citation, composed |
| ALL_OTHERS_ALSO_BAD | **10** | other citations are hard 404s |

🔴 **209 rows have no resolving citation at all** — not 61. The 61 is exactly reproducible (it validates
the method: `n_sole` in `tail-rows.json` is 62 across the never-archived set), but it counts only rows
whose *single* source is composed. It misses the **138 rows that cite two or three composed URLs and
nothing else**. Those rows have more citations and the same amount of evidence: none.

⚠ **A further 188 rows cannot be classified without fetching.** Their other sources are all
`BOT_BLOCKED`/`FETCH_FAILED`, and the tail pass established that a 403 says nothing — 10 such URLs
returned one identical 4,215-byte block page. These are neither safe to retire nor demonstrably fine.

**So the honest shape of the decision is:**

- **209 rows** — no evidence a reader can check. Retire or re-research.
- **188 rows** — undecidable; need a real fetch pass (Playwright/UA rotation) before any verdict.
- **506 rows** — hold; a working citation exists, and re-research is a coverage improvement rather
  than a correction.

Concentration among the 209: **82 politicians**, led by John A. Mirisch ×11, Carlos A. Gimenez ×11,
Wendy Davis ×11, Erin Jemison ×10, Lester Friedman ×9. Retiring wholesale would visibly hollow out a
handful of local profiles rather than thinning the corpus evenly.

## What is owed

1. ⏳ **Operator decision on the 209**, not the 61.
2. **A fetch pass over the 188 undecidable rows** before they are counted either way.
3. The 506 held rows still carry a citation to a page that never existed. Even when a second source
   covers the claim, **the composed URL should come out of the array** — it is an unverifiable
   citation shown to users either way.
