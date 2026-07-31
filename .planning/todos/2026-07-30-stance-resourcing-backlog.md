# Stance re-sourcing backlog — opened 2026-07-30

## A1 OREGON — CITATION AUDIT DONE 2026-07-30, awaiting a retire/keep decision

Operator picked **A1 first** (harm-first ordering confirmed). All 94 cited Ballotpedia pages were
fetched and tested. Full per-politician results:
[`backend/data/stance-retirement/2026-07-30-a1-oregon-citation-audit.json`](../../backend/data/stance-retirement/2026-07-30-a1-oregon-citation-audit.json)

**Test applied** — the strictest and most mechanical half of "definition of done": do the bills named
in the row's own `reasoning` appear ANYWHERE in the page cited as its source? This judges the
citation, not the claim. A row can fail here and still be true — it just isn't sourced.

| verdict | politicians | rows | meaning |
|---|---|---|---|
| **ALL_CITED_BILLS_ABSENT** | 48 | **136** | named specific bills; **none appear on the cited page** |
| **DEAD_URL_404** | 2 | **3** | cited page does not exist (Sarah Finger McDonald, Jeff Helfrich) |
| PARTIAL_PRESENT | 4 | 27 | ≥1 cited measure appears — still needs the "does it support the chair" test |
| NO_BILL_CITED | 40 | 64 | general claims, no bill to test — **needs a different test, not yet done** |

**139 of 230 rows (60%) fail outright.** Worked example: Dan Rayfield, 13 rows citing HB 2002,
SB 1547, HB 3115, HB 2929 — the page (44,835 rendered chars) contains **none** of them, no "Medicaid",
no "voucher", no "transgender", and states he did not complete Ballotpedia's candidate survey.

Even PARTIAL_PRESENT is weak: Dexter cited 7 bills and only Measure 110 appears; Kotek cited 7 and
only Measure 118. A ballot-measure name on a Ballotpedia bio is usually an elections-section artifact,
not a position statement — these 4 need reading in context before any of their 27 rows are kept.

🔴 **METHOD WARNING — Ballotpedia rate-limits and it is SILENT.** Parallel fetches return **HTTP 202
with an empty body**. `r.ok` is TRUE for 202, so a naive probe records "no bill found" for a page it
never actually read, and the false-negative looks exactly like evidence. The first sweep here was
wrong for this reason. **Fetch serially with ~1.3s delay, and treat `status!==200 || chars<3000` as
UNKNOWN, never as a miss.**

### ✅ RETIRED — migration 1507, applied and pushed 2026-07-30

**86 rows across 53 politicians deleted** (83 bill-absent + 3 dead-URL). Answers held by those 53
went 265 → 179; context rows 179, no orphans. `last_stances_researched_at` untouched — all 53 were
already NULL, verified against the CSV rather than inferred from the post-state.

🔴 **It was 86, not the 139 first reported.** That earlier figure applied a POLITICIAN-level verdict
to every one of that politician's rows. At row level only 83 actually name an absent bill. **A
politician-level verdict is not a row-level verdict — most of these people have a mix.**

### Still open in A1 — 144 rows. ATTEMPTED 2026-07-30, NOT RESOLVED. Nothing deleted.

| rows | class |
|---|---|
| 140 | name no bill at all |
| 4 | cited measure IS on the page (Dexter, Kotek, Gelser Blouin, Thatcher/Prozanski, Osborne) |

🔴 **THE BILL TEST DOES NOT GENERALISE — do not retry it as-is.** It worked for the 83 because a bill
number is a RARE token: absent from the page ⇒ real evidence of absence. General claims have no such
token, and **Ballotpedia's site-wide nav names every policy area on every page** ("Education policy",
"Immigration policy", "Redistricting"…). A keyword probe over full page text therefore matched
**50–180 of 345 terms on every single page**, including pages with no substantive content. It is
not a weak signal, it is *no* signal. Verified: all 37 pages in batch A fetched cleanly at 200 and
still matched most terms.

### ✅ ARTICLE-BODY TEST VALIDATED 2026-07-30 — use this

Read `#mw-content-text` and take **`innerText` on a navigated page, or `textContent` on a
DOMParser-parsed fetch after removing `script`/`style`.** Both were checked against each other and
agree exactly. **Chrome falls to 9–11% of the text**, versus dominating it. My earlier failure came
from stripping RAW HTML, which drags in the whole mega-menu — the pages and terms were fine, the
extraction was not.

Both pilot rows resolve cleanly:
- **Harbick / Taxation** — `Corporate Activity Tax`, `Lane County`, `anti-tax` all ABSENT. Seated
  2025-01-13 (predecessor Charlie Conrad); the CAT passed 2019, so no voting record on it is possible.
- **Drazan / Climate** — `walkout` ABSENT (`cap-and-trade` present, but a compound claim needs every
  clause). Senate seat began **2025-10-24**; she held no seat in May 2023. *Healthcare*: `Medicaid`,
  `market-based` absent. *Immigration*: `sanctuary`, `immigration enforcement`, `border security` absent.

**Rule: test only multi-word capitalised phrases and rare tokens. Never bare common words.**

### 🔴 THE TENURE TEST DOES NOT WORK — do not build on it

Tempting idea: flag any row whose claimed event predates the person's tenure. **Ballotpedia's infobox
gives only the CURRENT office's tenure**, and prior service could not be extracted (a `Political
career`/`Previous offices` scrape came back empty on every page tried). Measured floors: Drazan 2025,
**Steiner 2025, Starr 2025** — yet Steiner served in the Senate for years before becoming Treasurer
and Starr was a senator in the 2000s. The screen would mark every **returning legislator** as making
an impossible claim. 19 politicians were fetched before this surfaced; nothing was deleted.

It also would not catch **gap** cases even if the floor were right: Drazan's earliest service (2019)
precedes the May-2023 claim, so only reading her full history reveals she was out of office then.

**Temporal impossibility remains the dominant failure mode** (memory: 7 of 8 bill-citing rows cited
pre-seating votes) — it just cannot be screened from the infobox. It needs the full office history.

**What IS established without any fetch:**
- **0 of 144 match migration 1494's party-prior predicate.** A broader variant I wrote catches 22, but
  that is **not an approved standard** and nothing was deleted on it.
- **22 rows (15%) share a reasoning SKELETON with another row** — normalise away proper nouns and
  numbers and they collapse. Seven different people carry a byte-identical *"Supported civil rights
  and anti-discrimination measures; consistent progressive voting record from Portland district."*
  Also x3 the same for Portland/Multnomah, x2 Healthcare Access, x2 Transgender Athletes.
  🔴 **Template clustering is a strong, FETCH-FREE fabrication detector — run it FIRST on A2-A6.**
  It is evidence about how a row was produced, not proof its citation fails, so it justifies
  scrutiny, not deletion on its own.

Then A2 (VA, 50) → A3 (TX, 34) → A4 (CA, 20) → A5 (7) → A6 (442, unseated, last).

## ⏸️ Cohort ordering — remaining decisions

Retirement is **done and pushed** (migration 1494, commit `16f0a1e5`). Nothing here is date-gated, so
this is picked up on demand — the operator asked to return to it after an unrelated task.

**What's waiting on a decision, not on research:**
1. **Confirm or re-rank the cohort order** in workstreams A and B below. The listed order is my
   recommendation only.
2. **One open disagreement to settle:** cohort **A6** is the largest single block by row count (442
   answers, 138 politicians) but none of those politicians hold a current office, so Essentials never
   displays them. I ranked it **last** despite the size, on the grounds that verifying claims nobody
   can see is the weakest use of an hour. If the goal is clearing volume, A6 is the cohort to promote —
   I'd argue against it. Operator's call.
3. Decide whether workstream B splits **UT local** and **UT state-leg** into separate waves (they use
   different research methods).

No verification work has started. 783 rows remain live and unverified.

---

**Purpose:** a sortable worklist for putting real evidence behind the compass rows that never had it.
Review this together and re-rank; the proposed order below is a recommendation, not a decision.

**Data:** [`backend/data/stance-retirement/2026-07-29-suspect-stance-backlog.csv`](../../backend/data/stance-retirement/2026-07-29-suspect-stance-backlog.csv)
— 1,752 rows, one per suspect answer, with `politician_id`, `topic_id`, `value`, `reasoning`,
`sources`, office, state, `seated`, and `whole_compass_affected`. Sort/filter it directly. It is also
the **rollback record** for what was deleted.

---

## Done — retirement applied (migration 1494)

**969 answers across 184 politicians deleted from prod**, because they failed the bar by construction
rather than by judgement:

| Bucket | Answers | Why it could not stand |
|---|---|---|
| `no-context` | 921 | no reasoning and no sources at all |
| `empty-sources` | 42 | context row present, `sources` array empty |
| `bio-only:party-prior-language` | 6 | reasoning argues from party membership |

Prod now holds **33,632 answers / 3,831 politicians**, with **0 unsourced**. 159 politicians dropped to
zero answers; the 28 of them carrying a research timestamp had it cleared so they resurface in the
re-research queue (old value preserved per row in the CSV). Three politicians who *already* had a
timestamp with zero answers — Deidre Tyler, MacKenzie Miller, Thaddeus A. Evans — were left alone:
that combination is how an **honest zero** is recorded and erasing it would destroy the fact that we
looked.

---

## Workstream A — VERIFY (783 answers still LIVE, 287 politicians)

Rows cited **only** to a Ballotpedia bio URL. They were not retired because they carry a source and
may well be true. **This is the higher-priority workstream**: a retired row is now merely absent,
which is honest, whereas these are still published and may still be false statements about real
people.

| # | Cohort | Answers | Politicians | Whole-compass | Visible? |
|---|---|---|---|---|---|
| A1 | **OR — seated** | 230 | 94 | 19 | **yes** |
| A2 | **VA — seated** | 50 | 18 | 13 | **yes** |
| A3 | TX — seated | 34 | 20 | 3 | yes |
| A4 | CA — seated | 20 | 11 | 0 | yes |
| A5 | ME / MD / AZ / MA — seated | 7 | 6 | 0 | yes |
| A6 | **not seated (no current office)** | 442 | 138 | 109 | **no** |

**Proposed order: A1 → A2 → A3 → A4 → A5 → A6.** A1 is the documented Oregon contamination cohort and
is visible to voters. A6 is the single largest block but its politicians hold no current office, so
Essentials does not display them — verifying claims nobody can see is the weakest use of the next hour,
even though the row count is tempting.

**Definition of done per row:** fetch the cited Ballotpedia page and establish that (a) the quote or
bill actually appears there, (b) it actually supports the specific chair recorded, and (c) it is
temporally possible for that person. Then either replace `sources` with the primary source the page
draws on, or retire the row.

## Workstream B — RE-RESEARCH (969 answers retired, 184 politicians)

These are now absent, so there is no live falsehood — this is a **coverage gap**, not a correctness
problem. Order by wave efficiency and election proximity rather than by harm.

| # | Cohort | Answers | Politicians | Whole-compass | Texture |
|---|---|---|---|---|---|
| B1 | **UT — seated** | 877 | 153 | 143 | mix of UT local (Mayor 54, City Council 46, at-large/district 30+) and UT state leg (~14 per district) |
| B2 | MA — seated | 45 | 18 | 15 | |
| B3 | blank-state — seated | 23 | 2 | 0 | state field empty — worth a look on its own |
| B4 | OR — seated | 11 | 5 | 3 | |
| B5 | CA / TX / unseated | 13 | 6 | 1 | |

B1 splits naturally into **UT local** and **UT state leg**, which are different research methods and
should probably be separate waves.

---

## Sort dimensions (for re-ranking together)

- **Live vs absent** — is a wrong claim still published? (A outranks B on this alone.)
- **Visible in Essentials** — does the politician hold a current office? 138 of the VERIFY politicians
  do not.
- **Whole compass affected** — 303 politicians have/had *every* answer in this set. A partial gap reads
  as incomplete; a total one reads as never-researched.
- **Election proximity** — nothing here is date-gated today, but an upcoming primary should jump a cohort.
- **Cohort efficiency** — same-state, same-chamber cohorts share sources and research method.

## Method notes — read before starting

- **🔴 Do not triage by reasoning text.** Grouping the 783 by what the reasoning *contains* gives
  quote 407 / characterisation 283 / specific bill 93 / explicit party-prior language only 6. That
  reads as "mostly lazy citations" and it is misleading: this project already established that **7 of
  8 bill-citing rows cited votes cast before the member was seated**. Specific-looking content is what
  fabrication looks like here. Only fetching the cited page settles a row.
- **`[PRE-SEATING]` check** in `backend/scripts/validate-stance-quotes.py` is deterministic and needs
  no fetch — but it requires `term_start`, which is NULL for most UT county officials, so it cannot
  carry cohort B1.
- **Ballotpedia is curl-walled; Playwright renders it.** Several county and state sites 403 WebFetch.
- **A URL existing is not a source check.** That is how this cohort passed the Phase 149 gate.
- For UT officeholder identity questions, the state's official contest API settles who actually holds a
  seat: `electionresults.utah.gov/results/public/api/elections/<county>-county-ut/general11052024/data`.

## Separate data debt found while measuring

**547 orphaned `inform.politician_context` rows** — reasoning and sources whose answer no longer
exists. Invisible to voters (no answer is published), so this is untidiness rather than harm, but it
means some earlier deletion did not clean up after itself. Not addressed by migration 1494, which
scoped its orphan check to the keys it retired precisely so it would not fail on this pre-existing
state.
