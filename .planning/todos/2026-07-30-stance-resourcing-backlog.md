# Stance re-sourcing backlog — opened 2026-07-30

## ⏸️ NEXT ACTION — sort the cohorts with the operator (paused 2026-07-30)

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
