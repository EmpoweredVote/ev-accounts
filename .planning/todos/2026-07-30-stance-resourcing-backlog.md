# Stance re-sourcing backlog — opened 2026-07-30, current as of 2026-07-31 (end of day)

## ⚠️ READ THIS FIRST — the ranking below is superseded

All 560 rows were swept with `npm run audit:stance-citations` after the sections below were written.
Two findings change the plan:

1. **🔴 TX came back CLEAN — 0 failures in 181 rows. Oregon's ~82% is NOT a base rate.** Across all 560,
   **436 are positively verified** (quote verbatim on the cited page, or every distinctive term present).
   The ranking below orders cohorts by ROW COUNT on the assumption that volume tracks risk. **It does
   not.** Re-rank by measured failure rate. Most remaining rows need **RE-POINTING at the primary source
   behind Ballotpedia, not retiring** — they quote campaign sites and candidate surveys as reproduced
   there. Only 35 rows are candidate failures, and 6 of 6 hand-checked "failures" were artifacts of the
   tool, not the data. → agent memory `project_stance_citation_audit_tool`
2. **🔴 A BIGGER DEFECT CLASS EXISTS AND IT IS CHEAPER TO FIND: 602 answers / 223 politicians whose
   ENTIRE source is a bare domain** (`https://ballotpedia.org`, no path). Plus 55 citing the
   `r.jina.ai` scraping proxy and ~41 citing an election page instead of a person. **Invisible for
   months because it PASSES the Ballotpedia-only predicate.** All now gated. Total gated debt is
   **1,214 rows, not 560.** → agent memory `project_stance_source_ci_gate`

**Standing lesson: exhaust cheap SQL predicates over `sources` BEFORE spending hours reading pages.**
602 rows cost one query; 224 Oregon retirements cost four sessions.

**Next: decide the 602 bare-domain class → hand-sample the 22 failing tail rows → bulk re-source the 436
verified.**

---

**560 answers cite nothing but a Ballotpedia bio** (557 after reclassification). Everything below is how
they were ranked, what has been tried, and what does not work.

Measured against prod 2026-07-31, not carried forward. Regenerate any number here with:

```bash
npm run check:stance-sources:verbose --prefix backend    # the 560, per state
node scripts/cluster-stance-reasoning.mjs                # the cheap pre-filter (from backend/)
```

## ▶️ START HERE — the ranking changed, and the reason matters

🔴 **VISIBILITY IS NOT OCCUPANCY. The old ranking got this wrong and it inverted the queue.**

This doc used to rank cohort A6 (politicians holding no current office) **last**, on the grounds that
"Essentials never displays them." That is false. `compassService.ts:406-438` surfaces compass answers
for **any non-incumbent active candidate in an upcoming race** — no office required. Measured: **422 of
the 443 not-seated rows are on a live candidate card right now.** Only 21 rows across 9 politicians are
genuinely invisible.

So the largest block is not the invisible one — it is **71% of everything still live, and it is
published**. Two things follow, and the second is the stronger argument:

1. These people are on the **2026-11-03 general ballot** (one WI exception, 2026-08-11), so the doc's
   own "election proximity" dimension promotes them rather than demoting them.
2. A challenger has **no voting record to contradict a fabrication**. An incumbent's false stance can be
   checked against a roll call by anyone; a challenger's cannot. And a voter comparing the two on a
   candidate card is exactly who the compass is for.

### The queue, re-ranked

| # | cohort | rows | politicians | seated | on ballot | why here |
|---|---|---|---|---|---|---|
| **1** | **A1 residue — OR** | **6** | ~6 | 6 | — | genuine claim-term matches; needs reading in context, not a mechanical pass |
| **2** | **TX** | **181** | 55 | 34 | 147 | largest single block; both halves visible |
| **3** | **TN** | **76** | 27 | 0 | 76 | all challengers, all on the general |
| **4** | **WA** | **68** | 23 | 0 | 68 | all challengers |
| **5** | **VA** | **54** | 20 | 50 | 4 | was A2; 13 whole-compass |
| **6** | **NY** | **48** | 10 | 0 | 48 | 4.8 rows/person — whole compasses |
| **7** | CA | 20 | 11 | 20 | 0 | was A4 |
| **8** | MA | 20 | 5 | 1 | 19 | |
| **9** | the tail — UT 10, MS 7, NE 7, HI 6, AZ 5, MN 4, OH 4, OK 3, ME 3, MD 2, KY 2, WY 2, NH 2, CT 2, AR 2, MI 1, WI 1, OR-cand 2 | 65 | ~35 | 7 | 58 | one sweep, shared method by chamber |
| **last** | **genuinely invisible** | **21** | 9 | 0 | 0 | no office, no upcoming race — the only rows nobody can see |

TX leads on volume and carries both a seated and a challenger half, so its sources overlap.
**The old A2→A6 lettering is retired** — it encoded the visibility error in its ordering.

### Definition of done per row (unchanged, still the bar)

Fetch the cited page and establish that (a) the quote or bill actually appears there, (b) it actually
supports the specific chair recorded, and (c) it is temporally possible for that person. Then either
replace `sources` with the primary source the page draws on, or retire the row.

## 🔴 The 602 "bare domain" rows are NOT a retirement class — 601 of them are a MISSING PATH

Measured against prod 2026-07-31, after the class was first written up as "the entire source is
`https://ballotpedia.org` … indefensible on their face, retire as a class". **That description is true
of exactly one row.**

| what the bare domain actually is | rows | politicians |
|---|---|---|
| the candidate's **own campaign site** (`silviacatten.com`, `bakerforcongress2026.com`…) | **596** | 218 |
| an officeholder's **own .gov office site** (`treasurer.ks.gov`, `ltgov.ri.gov`…) | 5 | 4 |
| a **multi-subject reference root** (`ballotpedia.org`) | **1** | 1 |

Not one row has empty reasoning; the mean is 282 chars and most carry a verbatim quote. Six cited
homepages were fetched and grepped for the exact claim credited to them — **6 of 6 contained it**
(kshamasawant.org "military aid", lorenabrunerforcongress.com "Medicare for All", cheryl4maryland.com
"sealed borders", wileyfor21.com "ZIP code", fairlyfortexas.com "gender", charlie4va.com "property
tax"). These sites put their issues content on the front page, so the citation is *imprecise, not
absent*. **367 of the 602 are live on candidate cards.** Retiring the class would have deleted ~596
true, sourced rows — the failure this doc already warns about under "deleting those destroys true,
sourced work".

**Remedy is to add the path, never to swap the source and never to retire.** Now gated separately as
`PRIMARY_SITE_NO_PATH` vs `BARE_AGGREGATOR_DOMAIN` (1).

### ✅ Repair pass applied — migration 1512, 601 → 558

`node scripts/repair-primary-site-paths.mjs` crawled all 223 sites and re-tested every row's quote
page by page. **Only 43 rows had a better page to point at.** That is the headline: this class is
mostly not repairable, because it is mostly *not broken*.

| verdict | rows | what it means |
|---|---|---|
| `HOMEPAGE_ONLY` | **265** | claim IS on the homepage, site has nothing more specific. **Already as precise as the source permits** — not debt |
| `NOT_FOUND` | 130 | verbatim quote not on the site as fetched — **human read, never a retirement** |
| `UNREADABLE` | 112 | client-rendered shell (1,027k html → 7k text). An unread page is not an absent claim |
| `DEEP_PAGE` | 23 | ✅ applied — `/issues`, `/platform`, `/priorities` |
| `HOMEPAGE_ANCHOR` | 20 | ✅ applied — single-page site, topical section id |
| `UNTESTABLE` | 23 | no quote and no distinctive term survived extraction |
| `DEAD_SITE` | 16 | campaign site 404s. **Wayback is the likely remedy, not deletion** |
| `DEEP_PAGE_WEAK` | 9 | one term, no quote. Probably right; not the bar for a prod write |
| held | 3 | `jessicaandersonforva.com` 301s to `jess4va.com` — a **host change needs a human**, not a script |

Rollback: `data/stance-retirement/2026-07-31-primary-site-paths-rollback.json` carries the exact prior
`sources` array for all 43. Dry-run via `node scripts/dry-run-migration.mjs <file>` — that script
cannot commit, and its failure path is verified, so the "dry-run before applying" habit is mechanical
now instead of remembered.

🔴 **`NOT_FOUND` IS NOT A RETIREMENT LIST — hand-checked, it is at least two different things.**
Rendered with Playwright: voteforpedrori.com says *"Dissolve AIPAC. No Foreign-Interest Lobby Money …
I will not take money from AIPAC"* while the row quotes *"No AIPAC Money. No Foreign-Interest Lobby
Money"* — substance plainly present, wording compressed, **fix the quote and keep the row**. But
shannontaylorva.com contains no occurrence of *tariff* at all across 4 pages read. Same verdict,
opposite remedy.

🔴 **THREE ROUNDS OF BLOCK-LISTING ANCHOR IDS FAILED BEFORE ALLOW-LISTING WORKED.** `#comp-jtv6vr22`
→ blocked; then `#page`/`#PAGES_CONTAINER` → blocked; then `#zi245S`, `#ui-id-6`, `#container02`,
`#accordion-1-content-1`. Every round the filter grew and the next site builder invented a new shape —
the same losing pattern as the keyword probe and the template clusterer. The property that matters is
not "was this hand-written" but **"does the name say what it points at"**, so the id must now contain
a topical word and enclose <40% of the page. Anything else falls back to `HOMEPAGE_ONLY`, which is a
correct citation rather than a failure.

🔴 **A PREDICATE READS THE SHAPE OF A VALUE, NEVER WHAT THE VALUE IS.** `BARE_DOMAIN_ONLY` was a true
statement about 602 rows and a false description of 601 of them, because it never asked *whose* domain
it was. One `GROUP BY` on the domain settled it — the same five minutes the class itself cost to find.
This is the Phase 149 error one level up: first we checked a URL existed, then we checked the shape of
the citation, and neither step looked at what was there. **Before adding a check, group what it catches
and read a sample.**

## ✅ The gate — this is what stops the backlog regenerating

`npm run check:stance-sources` — **Ballotpedia cannot be the only source** (operator's predicate,
2026-07-31). Baselined per state; fires on growth in a state or on any new state.

⚠️ **Candidate Connection carve-out (2026-07-31).** A Ballotpedia URL deep-linked to `#Campaign_themes`
(or a `Candidate_Connection` path) **counts as a valid sole citation**. Those are the candidate's own
survey answers, published nowhere else — Ballotpedia is the primary source, not a conduit, and there is
nothing upstream to re-point to. **231 of the 557 rows in this bucket rest on exactly that.** Without
the carve-out the gate pressures whoever works the backlog into deleting a well-sourced row or bolting
on a second citation that is not really the source. The anchor is REQUIRED — a bare `/Name` page is
still just a bio. Verified against live pages: the anchor is `#Campaign_themes`, there is no
`#Candidate_Connection` section id. Applying it took BALLOTPEDIA_ONLY 557 → **552** (5 UT rows already
had the anchor).
`ANSWER_WITHOUT_CONTEXT` and `EMPTY_SOURCES` are zero-tolerance (prod verified at 0 before being
written as such). Runs on master pushes and the daily cron, not PRs — sourcing debt changes with data,
not with commits. Verified to FAIL, not just to pass.

🔴 **A green run means "no row cites Ballotpedia and nothing else". It does NOT mean stances are
sourced.** It reads the shape of `sources`, never the cited page. A row citing the legislature for a
vote the member never cast passes it and is still false.

**The 560 baseline should only ever go down.** Lowering it is how progress on this backlog gets
recorded; raising it needs a reason in the commit message. Already done twice: `or` 44 → 17 → 8 recorded the
1509/1510/1511 retirements, total 596 → 560.

## ⚠️ Oregon REPLACEMENT wave — built, deliberately NOT started

A1 retirement is complete: **224 of 230 rows gone** (**1507** 86 absent-bill · **1508** 102
absent-claim-term · **1509/1510** 27 untestable · **1511** 9 disambiguation-cited). 84 officeholders
have gaps and a nulled `last_stances_researched_at`. Extractor is
built and verified: `node scripts/olis-fetch-votes.mjs --session 2025R1 --votes <out.json>`. Scope
decided: OLIS session `2025R1` only. Source notes and the session-vs-current trap: agent memory
`project_olis_oregon_vote_source`.

**Held because it adds coverage while 422 published unsourced rows sit on candidate cards.** That is a
sequencing call, not a problem with the wave — resume it whenever the correctness queue above is judged
short enough.

| n | office | OLIS 2025R1 |
|---|---|---|
| 52 | STATE_LOWER | ✅ covered |
| 24 | STATE_UPPER | ✅ covered |
| 5 | STATE_EXEC — Kotek, Rayfield, Steiner, Stephenson, Read | ❌ no roll calls in current office |
| 3 | NATIONAL_LOWER — Salinas, Bynum, Dexter | ❌ US House; needs a congressional source |

**76 of 84 covered.** Most were seated in 2025, so 2025R1 is their entire record. Add `2023R1` later
**only** for identified long-serving members (Prozanski, Frederick, Nathanson). 🔴 **Do NOT push the 8
non-legislators through OLIS** — that is how a Governor ends up credited with legislative votes.

### Recipe

1. `--votes` pulls 2025R1 (72,752 rows, ~73 paged requests, retry built in). Output is large —
   **decide storage before writing it into the repo**; do not commit a 10 MB raw dump.
2. 🔴 **Resolve the 3 changed seats by `ActionDate` before attributing anything.** OLIS has Drazan in
   H51 and Bonham in S26; we have Bunch in H51 and Drazan in S26 (appointed 2025-10-24). H48 likewise
   (OLIS Hoa Nguyen, ours Lamar Wise). A vote belongs to whoever held the seat when it was cast.
3. **State scale is 26 topics** — `inform.compass_topic_roles` where `role_scope='state'` (confirmed
   against prod 2026-07-31). **Re-verify topic UUIDs before reuse.**
4. 🔴 **A `No Vote`/absent value is NOT a position.** Never read it as opposition.
5. 🔴 **Where no roll call supports a chair, the answer is NO STANCE** — not a weaker one.
6. **Write the expected yield down before starting.** A single roll call rarely evidences one chair on a
   1-5 scale (same source → two plausible chairs ⇒ pin none), so expect a handful of the 26 topics per
   member, not 26. Partial coverage is the honest outcome; recording the expectation up front is what
   keeps a low yield from being read as failure and "fixed" by inflation.
7. **Validate every produced row.** Standing failure rate for agent stance rows is 25-38%.
8. Push via office/district join, never bare `full_name`; OR state districts are `state` LOWERCASE.

## ✅ A1 IS CLOSED — 224 of 230 retired. 6 rows left.

| rows | class | status |
|---|---|---|
| ~~27~~ | no testable term in the reasoning | ✅ **RETIRED — 1509 (20 sitting legislators) + 1510 (7 non-legislators)** |
| ~~9~~ | "cited page unreadable" | ✅ **RETIRED — 1511. The pages were DISAMBIGUATION STUBS, not failed extractions** |
| 6 | a cited claim-term IS on the page | **all that remains** — read in context; keep, re-source or retire individually. Not another mechanical pass. |

🔴 **A SHORT PAGE IS NOT A FAILED FETCH.** 1508 held those 9 back because the cited page returned under
400 chars, and scoring an unread page as a miss is the same false negative as the silent HTTP-202. The
caution was right and the diagnosis was wrong: all five pages are `may refer to` stubs listing unrelated
people. `/Rob_Wagner` redirects to `/Robert_Wagner` and lists five other Robert Wagners. **Test for
"may refer to" before concluding extraction broke**, or rows get re-held indefinitely.

🔴 **RE-POINTING A DEAD CITATION USUALLY DOESN'T SAVE THE ROW — check before assuming it will.** All five
correctly-titled pages exist and were read in full (20k-33k chars); the claim terms are absent from every
one, and all five state the member never completed Ballotpedia's survey. **Travis Nelson is the
instructive case**: his correct page *does* contain `Medicaid`, so a term-presence test would score his
row supported. In context both hits are **sponsored-legislation** entries for HB4127 (2026, *Medicaid
payments to reproductive health providers*) while the row claims a **vote for Medicaid expansion**.
Presence is not support.

**Why the 27 went as two acts.** 1509's 20 rows belong to sitting OR legislators whose record is already
reachable via `olis-fetch-votes.mjs` — so retiring is delete-and-re-derive, not delete-and-lose. 1510's 7
belong to Steiner, Stephenson, Read and Bynum, and every one describes service in a **previous** office
while citing the **current** office's bio page. 🔴 **Those four must not be pushed through OLIS 2025R1** —
they hold no seat in it, and that is how a statewide executive gets credited with legislative votes. They
need earlier sessions matched to the years served (Steiner/Stephenson/Read) or a congressional source
(Bynum). Separate, unscheduled work.

**Occupancy was checked and the doubt was misplaced.** McLane (SD-30) and Skarlatos (HD-4) both carry
`term_start NULL` / `start_precision 'unknown'` from the migration-1459 backfill, so their seats looked
unverified — but the **authoritative OLIS 2025R1 roster confirms both**. Tawna Sanchez is stored as
`Tawna Sanchez`, not `Tawna D. Sanchez`: a name form, not a missing person. 🔴 **An unknown-precision
backfilled term is not evidence the occupancy is WRONG — check the authoritative roster before acting on
that suspicion.**

Per-row detail: [`backend/data/stance-retirement/2026-07-31-a1-oregon-articlebody-audit.json`](../../backend/data/stance-retirement/2026-07-31-a1-oregon-articlebody-audit.json)

## Method — what works, and what looks like it works

### ✅ The article-body test — USE THIS

Read `#mw-content-text` and take **`innerText` on a navigated page, or `textContent` on a
DOMParser-parsed fetch after removing `script`/`style`.** Both were checked against each other and
agree exactly. **Chrome falls to 9-11% of the text** instead of dominating it. The earlier failure came
from stripping RAW HTML, which drags in the whole mega-menu — the pages and terms were fine, the
extraction was not.

**Test only multi-word capitalised phrases and rare tokens. Never bare common words.** Drop IDENTITY
terms (county, town, title) — they are load-bearing on a bio page and took a 13-term probe down to 6.

### ✅ Bill-number absence — works, but only for rows that name a bill

A bill number is a RARE token: absent from the page ⇒ real evidence of absence. This retired 83 rows.
It does **not** generalise to general claims, which have no such token.

### 🔴 Ballotpedia rate-limits SILENTLY — this produced a wrong sweep once

Parallel fetches return **HTTP 202 with an empty body**, and `r.ok` is TRUE for 202, so a naive probe
records "no bill found" for a page it never read — and the false negative looks exactly like evidence.
**Fetch serially at ~1.3s, and treat `status !== 200 || chars < 3000` as UNKNOWN, never as a miss.**

### 🔴 Full-page keyword probing — NO signal, do not retry

Ballotpedia's site-wide nav names every policy area on every page ("Education policy", "Immigration
policy", "Redistricting"…), so a keyword probe over full page text matched **50-180 of 345 terms on
every single page**, including pages with no substantive content. Verified: all 37 pages in that batch
fetched cleanly at 200 and still matched most terms. Not a weak signal — no signal.

### 🔴 The TENURE screen — rejected, do not build on it

Flagging rows whose claimed event predates the person's tenure sounds deterministic. **Ballotpedia's
infobox gives only the CURRENT office's tenure**, and prior service could not be extracted (a
`Political career`/`Previous offices` scrape came back empty on every page tried). Measured floors:
Drazan 2025, **Steiner 2025, Starr 2025** — yet Steiner served in the Senate for years before becoming
Treasurer and Starr was a senator in the 2000s. The screen would mark every **returning legislator** as
making an impossible claim. It also misses **gap** cases: Drazan's earliest service (2019) predates the
May-2023 claim, so only her full history reveals she was out of office then.

**Temporal impossibility remains the dominant failure mode** (7 of 8 bill-citing rows cited pre-seating
votes) — it just cannot be screened from the infobox. It needs the full office history.

### 🔴 TEMPLATE CLUSTERING — much weaker than this doc used to claim

Committed as `backend/scripts/cluster-stance-reasoning.mjs` and run globally 2026-07-31. **The previous
claim — "a strong, FETCH-FREE fabrication detector, run it FIRST on every cohort" — did not survive the
full corpus.**

Corpus-wide (33,528 live answers) 1,976 rows cluster, and **the largest clusters are the best-sourced
rows in the database**: 54 WI Assembly members voting Yes on AJR-102 produce one identical sentence, as
do 78 ME representatives sharing an MRTL scorecard outcome and 20 OR members who voted YES on HB 2002.
**Repetition is what honest shared-vote sourcing looks like**, so raw cluster size says nothing about
fabrication.

What discriminates is whether the repeated text names an **instrument** — bill, resolution, ballot
measure, named Act, scorecard. The Portland finding was suspicious because it repeated while citing
nothing lookup-able, not because it repeated. With that split, corpus-wide actionable rows fall from
1,976 to **204 (0.6%)** — and even 204 is an overestimate: three passes widening the instrument
vocabulary (`RES-142` WI municipal, `HJ 9` VA, "Act on Mass tracker" MA, hyphenated `SB-7`) moved
350 → 234 → 204, with the remaining top entries still naming instruments the regex has not learned.
**Each refinement reclassifies rows from suspicious to explained — the same shape as the rejected
keyword probe.**

Where it **does** earn its keep is the narrow cohort it was calibrated on: **596 rows → 29 clustered →
6 actionable** (measured before 1509/1510), in seconds, with no fetch. Those 6 are the genuine article (Thatcher/McLane,
Sosa/Nelson, Prozanski/Gelser Blouin). **Use it as a cheap pre-filter on the Ballotpedia-only cohort,
not as a corpus sweep, and not as a reason to reorder the queue.**

A cluster is evidence about how a row was **produced**, never proof its citation fails. Nothing is
deleted on this signal alone.

### Other standing notes

- **🔴 Do not triage by reasoning text.** Grouping by what the reasoning *contains* gives quote 407 /
  characterisation 283 / specific bill 93. That reads as "mostly lazy citations" and misleads:
  **specific-looking content is what fabrication looks like here.** Only fetching the cited page settles
  a row.
- **🔴 A politician-level verdict is NOT a row-level verdict.** The first A1 sweep reported 139 rows by
  applying a per-politician verdict to all of that person's rows; at row level it was 83. Most of these
  people have a mix.
- **`[PRE-SEATING]` check** in `backend/scripts/validate-stance-quotes.py` is deterministic and
  fetch-free — but needs `term_start`, NULL for most UT county officials.
- **Ballotpedia is curl-walled; Playwright renders it.** Several county and state sites 403 WebFetch.
- **A URL existing is not a source check.** That is how this cohort passed the Phase 149 gate.
- **0 of the A1 144 matched migration 1494's party-prior predicate.** A broader variant caught 22, but
  that is **not an approved standard** and nothing was deleted on it.
- For UT officeholder identity, the state's contest API settles who holds a seat:
  `electionresults.utah.gov/results/public/api/elections/<county>-county-ut/general11052024/data`.

## Workstream B — RE-RESEARCH (coverage gap, not a live falsehood)

969 answers retired by migration 1494 across 184 politicians. These are **absent**, so nothing false is
published — order by wave efficiency, below Workstream A.

| # | cohort | answers | politicians | whole-compass | texture |
|---|---|---|---|---|---|
| B1 | **UT — seated** | 877 | 153 | 143 | UT local (Mayor 54, City Council 46, at-large/district 30+) **and** UT state leg (~14 per district) — **different methods, split into separate waves** |
| B2 | MA — seated | 45 | 18 | 15 | |
| B3 | blank-state — seated | 23 | 2 | 0 | `state` empty — worth a look on its own |
| B4 | OR — seated | 11 | 5 | 3 | folded into the OLIS wave above |
| B5 | CA / TX / unseated | 13 | 6 | 1 | |

## Separate data debt

**546 orphaned `inform.politician_context` rows** — reasoning and sources whose answer no longer
exists. Invisible to voters, so untidiness rather than harm, and it means some earlier deletion did not
clean up after itself (1494 deliberately scoped its orphan check to the keys it retired so it would not
fail on this pre-existing state; 1507/1508 added none). ⚠️ **These rows are the only surviving reasoning
and sources for deleted answers** — confirm the backlog CSV is the rollback record you want before
clearing them.

## Rollback record

[`backend/data/stance-retirement/2026-07-29-suspect-stance-backlog.csv`](../../backend/data/stance-retirement/2026-07-29-suspect-stance-backlog.csv)
— 1,752 rows, one per suspect answer, with `politician_id`, `topic_id`, `value`, `reasoning`,
`sources`, office, state, `seated`, `whole_compass_affected`. Also the rollback record for what was
deleted.

Cluster reports: `2026-07-31-template-clusters-cohort.json` (full) and
`-all-generic.json` (corpus, ANCHORED clusters trimmed; regenerate with `--all`).

---

## Archive — superseded, kept for the reasoning only

Numbers in this section are **historical**. Do not plan against them; the live figures are at the top.

- **Retirement applied, migration 1494** — 969 answers / 184 politicians deleted: `no-context` 921 (no
  reasoning and no sources), `empty-sources` 42, `bio-only:party-prior-language` 6. Prod went to
  33,632 answers / 3,831 politicians with 0 unsourced. 159 politicians dropped to zero answers; the 28
  carrying a research timestamp had it cleared so they resurface in the queue. Three politicians who
  *already* had a timestamp with zero answers — Deidre Tyler, MacKenzie Miller, Thaddeus A. Evans —
  were left alone: **that combination is how an honest zero is recorded**, and erasing it would destroy
  the fact that we looked.
- **Migration 1507** — 86 rows / 53 politicians (83 bill-absent + 3 dead-URL). Answers held by those 53
  went 265 → 179. `last_stances_researched_at` untouched; all 53 were already NULL, **verified against
  the CSV rather than inferred from the post-state**.
- **Migration 1508** — 102 rows whose cited page lacks the claim term, found by the article-body test.
- **Migrations 1509 + 1510** — the 27 untestable rows, split by replacement path: 20 held by sitting OR
  legislators (OLIS-derivable) and 7 by statewide/congressional officeholders (not). Dry-run against prod
  with the rollback confirmed, then applied; answers 33,534 → 33,507, no new orphaned context.
- **The old A1-A6 cohort table and its A1→A6 ordering** are retired: A6 was ranked last for being
  invisible, and 422 of its 443 rows are published on candidate cards. The lettering is not reused.
- **Migration 1511** — the last 9 A1 rows. Held back by 1508 as "unreadable"; the pages are
  disambiguation stubs, and all five correctly-titled pages were then read in full to prove re-pointing
  the citation would not rescue them.
- **The 783-live, 144-open, 596-live, 569-live, 42-residue and 15-residue figures** that appeared here
  are superseded by **560 live and 6 A1 residue** (migrations 1509, 1510, 1511).
