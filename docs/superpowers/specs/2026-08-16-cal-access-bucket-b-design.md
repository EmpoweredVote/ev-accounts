# Cal-Access bucket B — remediation design

**Date:** 2026-08-16
**Status:** approved (operator, 2026-08-16). Not yet implemented.
**Prerequisites shipped:** predicate tripwire (commit `50d1cdfd`, CI job `cal-access predicate tripwire`); bucket A purge (migration `1789`).

---

## 1. Why this exists

`backend/scripts/confirm-cal-access.ts` links Cal-Access committees to politicians when
`extractLastName(full_name)` — **the last space-delimited token** — appears as a whole word in the
committee name, and the name contains any of `FOR / COMMITTEE / CAMPAIGN / ELECT / OFFICEHOLDER /
EXPLORATORY`. Both halves are broken: the last token is frequently not the surname, and every
candidate committee name contains one of those words, so the "signal word" test admits rather than
filters. The script generates and confirms in one pass, so nothing independent ever checked it —
**7,836 of 7,853 links came back `confirmed`.**

Surfaced by migration 1788 (Assemblymember Robert Garcia was carrying Antonio Vazquez's identity,
including 21 `VAZQUEZ` committees belonging to a dozen unrelated people).

The audit split cal_access by comparing the last token of `full_name` against the stored `last_name`:

| bucket | politicians | links | status |
|---|---|---|---|
| A — last token ≠ stored surname | 6 | 532 | ✅ done, migration 1789 |
| **B — last token = stored surname** | **572** | **7,321** | **this document** |

Bucket B matched the *correct* surname. That is still not an identity: Traci Park's `park` matched
Buena Park and Menlo Park; Ashley Johnson's `johnson` matched Ray, Ben, Jimmie, Stephanie, Nancy and
Michael V. Johnson.

## 2. Measured facts

All measured against the live DB on 2026-08-16, **after** migration 1789. Re-measure before acting;
these are inputs to a decision, not constants.

- Bucket B: **7,321 links across 572 active politicians**.
- cal_access displayed money on active politicians: **$41,474,744.97**.
- **Only 359 bucket-B links carry any money at all.** The rest display nothing.
- Money is extremely concentrated: top 10 links = $25.6M (62%), top 25 = $35.1M (85%),
  **top 50 = $39.1M (94.4%)**, top 100 = $40.8M (98%).
- Name-evidence split across all 7,321: names them 916 ($13.7M) · a *different* trailing given name
  2,843 ($9.0M) · no given name in the string 3,757 ($18.6M).
- **22 links have no committee name recorded at all.** 8 of those carry money, totalling **$11.2M**;
  3 of the 8 fall in the top 50 and account for $11.1M of it. A name-based rule cannot judge any of
  them.
- `transparent_motivations.committees` is **empty for cal_access** (0 of 8,061) — not a rescue.

### Two confirmed live defects
- 🔴 **"BONTA FOR ASSEMBLY 2024; MIA" — $2,388,048.52 — displays on Rob Bonta.** That is Mia Bonta,
  his spouse and a different sitting Assemblymember.
- ✅ **Newsom's $10,676,008.32 is CORRECT.** Its link has no committee name in our DB, but Cal-Access
  filer `1414018` is officially "NEWSOM FOR CALIFORNIA GOVERNOR 2022". Verified 2026-08-16.
  This is why a name-only classifier must not rule on the no-name rows.

## 3. Posture (operator decision, 2026-08-16)

**Prove-it-right.** Keep only links we can affirmatively tie to the politician; anything unprovable
comes down. Rationale: false attribution is the harm this product exists to prevent, and missing data
is merely incomplete. Consistent with the Socrata bucket-C ruling, where "committee has no given
name" was purged.

Rejected alternatives, recorded so they are not silently revisited:
- *Prove-it-wrong* (unprovable stays up) — knowingly leaves wrong money displayed.
- *Ingest Cal-Access filer registration in bulk, then classify* — highest fidelity and the only option
  that fixes the source properly, but a much larger project. **Deferred, not dismissed**: it is the
  right move whenever someone wants to re-enable cal_access ingestion at scale, which the tripwire now
  forces as an explicit decision.
- *Demote the whole source* — would remove ~$41.5M including money since proven correct.

## 4. Design

Two independent tracks, matched to two genuinely different risk profiles. **Track A can ship before
Track B is written.**

### Track A — the money (~25 links needing evidence, $26.2M)

Of the top 50 money links: 25 ($12.9M) already name the politician and auto-keep; **22 ($15.1M) are
surname-only or carry a different given name; 3 ($11.1M) have no committee name at all.** The latter
25 need evidence.

**Evidence source — the primary record, and the field the script should have used.** Navigate to
`https://cal-access.sos.ca.gov/` once to clear the Incapsula challenge, then fetch
`https://cal-access.sos.ca.gov/Campaign/Committees/Detail.aspx?id=<filer_id>` per link and read the
official registered committee name.
⚠ **curl gets an Incapsula stub; Playwright works, but only after the home-page visit.** A cold hit on
the detail URL returns an empty body. Verified end-to-end on filer 1414018.

**Decision rule per link:**
| fetched official name | action |
|---|---|
| names this politician | keep, `confirmed` |
| names someone else | purge: delete contributions + `contribution_summary_agg` rows, demote link |
| genuinely ambiguous | purge under the prove-it-right posture, with the reason recorded |

**Coverage:** top 50 first (94.4% of dollars). Extend to top 100 (98%) only if the first pass shows a
high wrong-rate. The remaining ~259 money links share ~$0.7M and fall to Track B's rule.

**Output:** one migration + a rollback JSON capturing every purged link's filer id, official committee
name, and dollar figure.

### Track B — the ~7,270 zero-dollar links

**Rule:** keep if the committee name contains **both** the politician's `last_name` and `first_name`
as whole words. Otherwise demote to `not_applicable` with a WRONG PERSON note. No contributions exist
to delete.

**Two precision guards, both load-bearing:**
1. **Nicknames.** Match `first_name` OR a known diminutive (Bob/Robert, Jim/James, Liz/Elizabeth).
   Without this the rule falsely demotes correct links at scale.
2. **Leading-position surname.** Cal-Access puts the surname first. Require it there, so "Buena Park"
   and "Menlo Park" do not count as naming Traci Park.

**Accepted cost, stated plainly:** this demotes correct-but-unprovable links such as "SOLACHE FOR
ASSEMBLY 2026" — surname, office, year, no given name. That is the chosen posture working as
intended. Because no money rides on these, the cost is a missing source listing, not a wrong figure.

**Output:** a second migration, plus per-branch counts of what moved.

## 5. Mechanics that must not regress

- **Demote, never delete, a wrong link.** `research_status = 'not_applicable'` plus a WRONG PERSON
  note appended to `notes`. The notes are the only provenance of how the tangle arose
  (person-merge recipe, migration 1661).
- **`contribution_summary_agg` is a real TABLE, not a view.** Delete from it explicitly or the UI keeps
  displaying money whose contributions are gone.
- 🔴 **`count(*)` on `transparent_motivations.contributions` blows the statement timeout.** It killed
  the first attempt at migration 1789 before it reached any work. Never take a global before/after
  snapshot of that table; scope every assertion to the affected ids — which is the better assertion
  anyway, since a global delta is also satisfied by deleting unrelated rows.
- 🔴 **`IN (SELECT ... FROM <temp table>)` seq-scans `contributions`.** A fresh temp table has no
  statistics, so the planner ignores
  `idx_transparent_motivations_contributions_politician_source_id`. **Write the ids INLINE**, keep the
  temp table too, and assert in a pre-check that the two agree so the duplication cannot drift.
- 💰 **Use `contribution_summary_agg` for all money questions.** Every aggregate over `contributions`
  timed out, even scoped to a single politician.
- **Guards must assert content, not that an UPDATE ran**: the per-branch counts, a phrase from the
  note, and — critically — that the KEEP set survived untouched with its dollar total unchanged. A bug
  that widens the purge satisfies every count-only guard.
- **Verify on row counts after applying**, never on the apply script's "OK".
- **Re-check the migration number immediately before commit** (`check-migration-numbers.mjs`).
- Migrations here are pure DML; apply via `npx tsx scripts/_apply-file.ts` from `backend/`.

## 6. Out of scope

- Rewriting `confirm-cal-access.ts`'s predicate. The tripwire blocks re-enabling it; replacing it is a
  separate task, and doing it properly means Section 3's deferred bulk-registration ingest.
- The `needs_research` cal_access rows (~64k). Untouched, and inert while the script cannot run.
- Politicians who are `is_active = false`, including the committee-name-as-politician rows.
- The 46 Socrata bucket-C links and the 8 remaining dedup collision groups — unrelated queues.

## 7. Risks

- **Cal-Access availability.** Track A depends on a WAF-protected government site. If it blocks
  sustained access, Track A stalls; fall back to per-link judgment on the committee name plus the
  politician's office and era, and record the weaker basis in the migration.
- **The keep-rate may be high enough to question the posture.** If Track A's 25 lookups come back
  mostly correct, that is evidence the unprovable middle is largely fine, and the operator may want to
  revisit prove-it-right for Track B before it demotes ~3,700 links. **Report Track A's wrong-rate
  before starting Track B.**
- **Re-measure first.** Every count here is from 2026-08-16 and three migrations have landed since the
  audit began.
