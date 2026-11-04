# Post-election transition tracker — design

**Date:** 2026-11-04
**Author:** Chris Cantrell (with Claude)
**Status:** design, not yet planned

## Intent

The 2026-11-03 general election moved an unknown number of seats. Our database records
**zero** results for it: all 2,159 races carrying that date have no winner. Until each one is
worked, Empowered Vote shows voters the person who held the seat on election day, with no
indication that they are leaving.

The work is too large for one person and will run for weeks. Without a shared record of what
has been checked, seats will be missed silently — and a missed seat is indistinguishable from
a seat where the incumbent won, because both look like "no change".

This design covers the tracker that makes the work visible, and the data model that lets the
site show a handover honestly while it is pending.

## Why a tracker rather than a checklist

Progress is **computed from the database**, not typed by hand. A hand-kept checklist and the
data drift apart, and the whole purpose here is to catch what slipped. A tracker that counts
"seats with a recorded winner" by querying cannot overstate progress.

What a query cannot hold is stored alongside: who owns a batch, a swearing-in date that is not
fixed by law, and notes like "recount running" or "winner declined".

## Goals

- Every one of the 2,159 races is visible with a state, at every moment of the work.
- Progress counts are derived from production data and cannot be edited by hand.
- A teammate can claim a batch so two people do not work the same state.
- Seats whose incoming officeholder has no headshot or no stance research are flagged
  explicitly, because those are follow-on work that is easy to defer and then lose.
- A result's provenance is visible: called by AP, versus certified by the state.

## Non-goals

- The tracker is not a results-entry UI. Results are written by the importer and by
  migrations, as all our data is.
- Not a replacement for the Knight coverage trackers.
- The tracker is not a public page. This is internal. (The Essentials rendering in piece 8
  *is* voter-facing; that is a separate surface.)
- It does not track the 2026 primaries, or any election other than 2026-11-03.

## Anti-goals — things that would make this a failure even if it worked

- **A number somebody can bump to make a red go green.** Progress is computed; there is no
  writable "percent done" anywhere.
- **A tracker that says a seat is done when only the result was entered.** "Done" must mean
  the term is written, the person exists, and the follow-on gaps are either filled or
  explicitly recorded as outstanding.
- **Showing a voter that a winner holds an office before they are sworn in.** This is the
  honesty constraint the whole data model turns on. See below.

## Measured starting state (2026-11-04, production)

| Level | Races | Breakdown |
|---|---|---|
| Federal | 470 | 435 `NATIONAL_LOWER`, 35 `NATIONAL_UPPER` |
| State | 1,157 | 848 `STATE_LOWER`, 266 `STATE_UPPER`, 34 `STATE_EXEC`, 9 boards |
| Local | 526 | 202 `SCHOOL`, 179 `LOCAL`, 103 `COUNTY`, 40 `LOCAL_EXEC` |
| Other | 8 | 2 `JUDICIAL`, 6 with no office attached |
| **Total** | **2,159** | |

- **Winners recorded: 0.** `race_candidates.result` holds only `advanced` (622),
  `not_nominated` (333) and `withdrew` (8) — all carried over from the primaries.
- 🔴 **CORRECTED — 691 races hold no candidate rows at all, not 641.** The state figure is
  right (641: 480 `STATE_LOWER` + 161 `STATE_UPPER`, in MA/ME/MD/OR/NV). But there are **50
  more outside the state tier**: 38 `LOCAL` and 8 `LOCAL_EXEC` (AZ, OR) and 4 `COUNTY`
  (OR, WI). Piece 3 is scoped to the 641, so **those 50 currently fall outside every piece of
  the program** and would sit in "not looked at" for ever — which is precisely the silent miss
  this document opens by describing.
  ✅ **Resolved 2026-11-04: the 50 join piece 3**, which is therefore scoped to 691, not 641.
- There are also **6 races with no office attached at all**, which can never be seated because
  there is nothing to seat them into. ✅ **Resolved 2026-11-04: read them before deciding.**
  They may be junk rows rather than real seats, and this repo's rule is that a predicate reads
  the *shape* of a value and never what it is — so "no office attached" is a hypothesis about
  these six, not a finding. Whoever plans piece 3 opens all six first and reports what they
  are; only then is it clear whether they need an office created, a deletion, or a permanent
  blocked state in the tracker.
- **Current holders exist for 2,078 of 2,159 offices**, so nearly every seat has an outgoing
  person to label.

Gaps among candidates still standing (not yet narrowed to winners):

| Level | Live candidates | No headshot | No stance research |
|---|---|---|---|
| Federal | 1,431 | 116 | 437 |
| State | 1,090 | 457 | 699 |
| Local | 1,040 | 770 | 950 |

⚠ **`politicians.last_stances_researched_at` is not a usable coverage measure.** 4,822
politicians have rows in `inform.politician_answers` but only 431 carry that timestamp. The
tracker must measure stance coverage from `politician_answers`, not from the flag. Apply the
`@zero-scope` rule: this is an "ever researched" question, so blanks (`value = 0`) count.

## The transition display, and why it needs almost no new machinery

`essentials.current_office_holders` selects from `office_terms` where
`term_start IS NULL OR term_start <= CURRENT_DATE`, and `term_end IS NULL OR term_end >= CURRENT_DATE`.

`essentials.seat_officeholder(office, politician, term_start, source)` closes the predecessor's
term at `term_start - 1` and inserts the new one. It accepts a **future** `term_start` — this
was read from the function body, which refuses only a NULL start and a predecessor starting on
or after the successor.

Therefore: **seating a winner today with their swearing-in date as `term_start` is correct and
self-executing.** Until that date the outgoing holder still resolves as current; on that date
the view flips by itself. No calendar trigger, no January cleanup pass over 2,159 seats.

This also keeps us on the right side of the repo's own rule that *a certified result is not a
fact about who holds the seat*. A future-dated term is a scheduled handover that can be
cancelled if the winner declines, dies or is appointed elsewhere — not a claim that the
handover already happened.

🔴🔴 **THE DATED TERM IS SELF-EXECUTING. THE TWO CACHED COLUMNS ARE NOT, AND THIS REPO HAS
ALREADY PAID FOR THAT.** `CC_0201` wrote exactly this handover for one Los Angeles judge, and
`CC_0202` exists *only* because `politicians.is_incumbent` and `politicians.office_id` do not
move when the calendar does. `CC_0202` carries a hard date guard refusing to run before
2027-01-05, and its own header says: left alone, the outgoing holder stays a "current
incumbent" with no seat — the defect `CA_0188` created 1,817 times — and the incoming holder is
**hidden from address search despite holding the seat**.

🔴 **CORRECTED — there are THREE cached columns, not two, and `is_incumbent` IS written at
runtime.** An earlier draft said nothing recomputes it and that it is written only by hand.
Both are wrong, verified in the code:

| Column | Written at runtime by | Read by |
|---|---|---|
| `politicians.is_incumbent` | `stagingService.ts:456` forces `is_incumbent = true` on `ON CONFLICT … DO UPDATE`; `adminService.ts:707` defaults it to `true` | four filters in `essentialsBrowseService.ts` **plus a fifth at `essentialsService.ts:360`** |
| `politicians.office_id` | legacy snapshot | deprecated, still asserts |
| **`race_candidates.is_incumbent`** | candidate imports | `compassService.ts:629` (`rc.is_incumbent = false`, the "challengers only" read) |

🔴 **This breaks the naïve version of piece 5.** A reconciler that reads `office_terms` and
writes `politicians.is_incumbent` on a schedule will be **silently undone by the next staging
promotion**, which sets it back to `true` unconditionally. Worse, the positive control the
document asks for would still pass: it plants a row, watches the reconciler fix it, and never
exercises the writer that reverts it. ▶ **Piece 5 must fix the writers as well as reconcile,
and its control must run a staging promotion afterwards and check the value survived.**

So "seat the winner and the calendar does the rest" is true for one table and false for three
columns across two tables.

**What is genuinely new is the read path.** The site must surface the *next* term, which no
current view exposes, so that Essentials can render both people with "Outgoing" and
"Incoming on &lt;date&gt;". Those labels are **derived from the term dates**, never stored as
flags — which is why they expire on their own.

🔴 Per the repo's own rule, the claim that the current-holder view flips correctly must be
**measured against the live endpoint**, not reasoned about, before any wave relies on it.

## Called versus certified

`race_candidates.result` permits `won`, and `race_candidates_result_needs_source` already
forces a non-empty `result_source` alongside any result. There is no way to express whether a
result is called or certified.

**Decision: add a real column**, `result_certainty`, with a CHECK allowing `called` and
`certified`, NULL when `result` is NULL. Encoding the distinction inside the free-text
`result_source` would make a predicate read the shape of a string to recover a fact — the
exact failure this repo has a rule against.

Workflow (revised 2026-11-04 after AP was ruled out — both stages now come from the state):
unofficial election-night returns → `result='won'`, `result_certainty='called'`, source names
the state's returns page and the date read. Official canvass → `result_certainty='certified'`,
source names the certified canvass. A seat may be seated from a call; certification is a
later, separate update that does **not** re-seat and does not touch `office_terms`.

🔴 **The split is load-bearing, not decorative, and wave 3 proves it.** California's canvass
runs up to 30 days, so its ~173 December seats will be sworn in *before* their results are
certified. Any plan that assumes certification precedes seating fails there first.

This needs a migration in a steward-allocated `CC_` slot.

### Settled during review (builder's call, recorded here)

- **The live CHECK already allows `not_nominated`.** Migration `1574`'s file allows only
  `won | lost | advanced | runoff | withdrew`, but a later migration widened it; measured
  against production, the constraint is
  `won | lost | advanced | runoff | withdrew | not_nominated`. Write the new constraint
  against the **measured** definition, not against 1574.
- 🔴 **CORRECTED — `result_certainty` is NOT purely additive.** An earlier draft said it was,
  on the strength of the Nov-3 slice. Measured repo-wide: `race_candidates` already holds
  **1,917 rows with a non-NULL `result`, including 489 `won` and 387 `lost`** from earlier
  elections. `ALTER TABLE` validates existing rows, so a plain
  `CHECK (result <> 'won' OR result_certainty IS NOT NULL)` **cannot be added** — all 489 would
  fail it.
  ✅ **Resolved 2026-11-04: backfill all 489 to `'certified'`, then add the constraint
  fully valid.** Those are past elections and are certified by now, so this is a true
  statement rather than a convenience, and it leaves the gate covering the whole table instead
  of only future rows. Per the repo's overwrite rule the migration records the old values in
  its own header — all 489 were NULL, and that is what the header must say.
- **Losers are recorded too**, with `result='lost'` and their own `result_source`. 1574 created
  `lost` and warns against leaving defeated candidates looking live.
- 🔴 **CORRECTED — do NOT use `essentials.is_live_candidate` for the tracker.** Read from
  production, its body is
  `COALESCE(status,'active') <> 'withdrawn' AND result IS DISTINCT FROM 'not_nominated'`, so
  **`won` and `lost` both return TRUE**, deliberately (1582 says so in capitals). Using it
  would mean recording losers never moves the headshot or stance gap counts — the two bullets
  above would contradict each other.
  **The tracker gets its own predicate** (`result IS NULL OR result NOT IN ('lost',
  'not_nominated', 'withdrew')`). `is_live_candidate` is left alone: it has eleven call sites
  across seven services, and tightening it would change how **past** elections render,
  including showing a finished race with zero candidates in `ElectionsView`.
- **There is no `unseat` helper** to pair with `vacate_office` — confirmed by listing the
  schema's functions. Cancelling a scheduled handover currently means restoring the
  predecessor's `term_end` by hand, which is exactly the two-step this repo built helpers to
  prevent. Whether to build one is an open question below.

## Seat states

Each race carries one state, computed:

1. **Not looked at** — no result recorded.
2. **Called** — `result='won'`, `result_certainty='called'`.
3. **Certified** — `result_certainty='certified'`.
4. **Seated** — a future-dated `office_terms` row exists for the winner.
5. **Sworn in** — that term's `term_start <= CURRENT_DATE`.

Plus two orthogonal flags on the incoming person: **no headshot**, **no stance research**.
And one structural flag on the race: **no candidate rows** (the 691).

A seat is not "done" at state 4 unless both gap flags are clear or carry a written note.

### 🔴🔴 The re-elected incumbent breaks this ladder, and it is the majority case

`seat_officeholder`'s body contains:

```sql
IF v_prev_pol IS NOT DISTINCT FROM p_politician_id THEN
  RETURN v_prev_id;   -- same person already holding through this date
END IF;
```

So when the winner is the sitting holder, the helper **returns the existing term and does
nothing**: no new row, no date change. States 4 and 5 above are both defined as "a
future-dated `office_terms` row exists for the winner", so **every re-elected incumbent can
never leave state 3** and the tracker would report the program permanently incomplete.

Measured 2026-11-04 — races whose current holder is on their own ballot:

| Level | Races with a holder | Holder on the ballot |
|---|---|---|
| Federal | 468 | **378 (81%)** |
| State | 1,153 | 402 |
| Local | 457 | 308 |
| **Total** | **2,078** | **1,088 (52%)** |

Most of those will win. This is not an edge case; it is over half the program and four fifths
of the trial run.

🔴 **And for a holder whose term already has an end date, the no-op is actively wrong.** Two
federal seats (SC Senate, one GA US House) carry `term_end = 2027-01-03`. If either holder is
re-elected and the helper no-ops, the office resolves as **unheld from 2027-01-04** — an
address search returning a seat with no name.

✅ **RESOLVED 2026-11-04 — a re-elected incumbent gets a FRESH TERM ROW.** A term is a tenure,
and re-election starts a new one; "when did the current term begin" must stay answerable.

🔴 **This requires extending `seat_officeholder`, and that is deliberate.** Today the helper
refuses the case, so the only alternative is hand-rolling the two-step — close the old term,
insert the new — across ~1,088 seats. That is exactly the operation this repo built helpers to
stop: `office_terms.office_id` is `ON DELETE CASCADE` and the open-ended-range rule means a
missed close silently overwrites or silently unseats.

The extension must keep the existing guard intact: a predecessor whose `term_start` is on or
after the successor's start is still refused. What changes is only the
*same-politician* branch, which should close the old term at `p_term_start - 1` and insert a
new one rather than returning early. It needs its own positive control — seat the same person
twice, assert two rows with adjoining dates, and assert the current-holder view still returns
exactly one.

⚠ **Idempotency needs care.** The helper's re-run check matches on
`(office_id, politician_id, term_start)`, so a repeat call with the same date is still a no-op
and stays safe. A repeat call with a *different* date would create a third term — so the
seating script must pass the term start from the date table, never "today".

## Order of work

**Ordered by deadline, not by tier size. Agreed with the operator 2026-11-04.**

| Wave | Seats | Deadline | Why here |
|---|---|---|---|
| 1. Senate | 35 | 2027-01-03 | Trial run: small, every seat has a holder and a live field |
| 2. House | 435 | 2027-01-03 | Same statutory date, same shape as wave 1 |
| 3. December locals | ~175 | **2026-12-01 onward** | Nearest deadline in the program |
| 4. State | 1,157 | mostly Jan+ | Largest pile, latest dates, needs the seeding wave first |
| 5. Remaining locals | ~350 | Jan+ and varied | January and off-cycle starts |

🔴 **Wave 3 has the earliest deadline but runs third.** That is deliberate: waves 1 and 2 are
the trial run and prove the spine, and they are only 470 seats of largely uniform shape.
Nothing in wave 3 can be trusted until the Senate batch has been through intake,
reconciliation, measurement, the artifact and the Essentials display end to end. ▶ **If waves
1–2 are not finished by roughly 2026-11-20, wave 3 must start in parallel regardless** — a
December seat that swears in unworked shows a voter the wrong officeholder, which is the exact
failure this program exists to prevent.

🟢 **WAVE 3 IS EFFECTIVELY ONE JURISDICTION.** Measured 2026-11-04 — of the 174 local races
whose office has a December term-start precedent, **173 are California** (153 `SCHOOL`,
18 `LOCAL`, 1 `COUNTY`, 1 `LOCAL_EXEC`) and one is a Washington county seat. **Every one of
them has live candidates**; none are empty shells. So wave 3 is one state's rules, one
Secretary of State, and mostly Los Angeles County registrar — far simpler to plan than its
seat count suggests.

🔴 **But California's canvass runs up to 30 days, so certification will NOT arrive before these
seats are due to be sworn in.** That makes wave 3 the case that proves the called/certified
split is load-bearing rather than decorative: these seats must be seated from an **AP call**
with `result_certainty='called'`, and certified later, after the holder is already in office.
Any plan that assumes certification precedes seating fails here first.

▶ **Piece 4 must date wave 3 FIRST.** The December dates above are inferred from our own
historical rows, not confirmed. The real sequencing cannot be set until those ~175 seats carry
sourced dates, so that is piece 4's first job, ahead of the state tier's.

🔴🔴 **MEASURED 2026-11-04: LOCAL'S DEADLINE ARRIVES FIRST, AND THE PRIORITY ORDER ABOVE
INVERTS IT.** Reading existing `office_terms.term_start` months for the 526 local offices that
carry a 2026-11-03 race:

| Tier | Dec starts | Jan starts | Other | December range |
|---|---|---|---|---|
| `SCHOOL` | **154** | 12 | 15 | 12-01 → 12-18 |
| `LOCAL` | 18 | 10 | 7 | 12-01 → 12-10 |
| `COUNTY` | 2 | 11 | 3 | 12-01 → 12-09 |
| `LOCAL_EXEC` | 1 | 2 | 1 | 12-14 |

**175 of 236 dated local terms begin in December**, the earliest on 1 December — **27 days
from this document, against 60 for the federal tier.** School boards are the bulk of it.

⚠ This is our own historical data about these offices, so it is evidence of each body's
convention, not proof of the 2026 date. Piece 4 must confirm it per jurisdiction. But it is
strong enough to act on, and the direction is unambiguous: **working Federal → State → Local in
that order means the local tier's deadline passes while the work is still queued behind two
larger tiers.**

✅ **Agreed by the operator 2026-11-04.** Federal stays first because it is the trial run; the
December local seats move ahead of the state tier. The wave table above is the result.

The Senate batch is the trial run: it is small, every seat has a current holder and a live
field, and the swearing-in date is fixed at 2027-01-03 for both federal chambers. Kinks found
there are fixed before the House wave.

✅ Two Senate current holders looked wrong on first read and were **checked and found correct**:

- **SC — Darline Graham (R).** Lindsey Graham died in office 2026-07-11; Graham was appointed
  2026-07-13, took the oath 2026-07-14, and her term already carries
  `term_end = 2027-01-03`. Sourced to senate.gov and the Governor's release, written by `CA_0325`.
- **OK — Alan Armstrong.** `term_start = 2026-03-24`, sourced to
  `unitedstates/congress-legislators` bioguide A000383, migration 1536.

Recorded here because the wrong conclusion was reachable from a name alone, and because the
SC row carries a hazard for the Senate wave:

🔴 **An appointed senator's term may already have an end date.** `seat_officeholder` finds the
term covering the new `term_start` and sets its `term_end` to `term_start - 1`. For SC that
rewrites `2027-01-03` to `2027-01-02` — a real overwrite of an existing sourced value, so that
migration must record the old value in its own header per the repo rule. Check for a non-NULL
`term_end` on the outgoing holder before seating, across every tier.

Measured 2026-11-04 across all 2,078 races whose office has a current holder: **8 carry a
non-NULL `term_end`** — 2 federal (SC Senate, and one other) and 6 local, all 6 of which end
*before* 2027-01-03. Rare, so it will not be noticed by sampling; the seating script must test
for it rather than rely on anyone spotting it.

## Decisions taken 2026-11-04 (operator: Chris Cantrell)

These four were put to the operator after the builder check. They enlarge the project well
beyond the tracker, and the document below is scoped to them.

1. **Cached columns → a reconciliation script.** One script recomputes `is_incumbent` (and
   retires `office_id`'s claim) from `office_terms`, run on a schedule, rather than a
   `CC_0202`-style migration per cohort. It fixes the class once instead of relying on anyone
   remembering to apply a date-gated file. It needs a positive control: plant a politician
   whose cached flag disagrees with their terms, watch the script correct it, because a
   reconciler that reports "nothing to fix" is the uniform answer this repo distrusts.
2. **Results intake → build an importer.** AP for called races, state Secretary of State for
   certification. This is a first-class deliverable, not a helper.
   - 🔴 **CORRECTED:** an earlier draft said `importElectionData.ts` "is old and fetches
     nothing". It does fetch — `downloadFile` (line 133) and `fetchUrl` (line 159) over
     http/https, called at line 595 for an Indiana SoS `.xlsx` and line 744 for an LA County
     roster. It is narrow and source-specific, but **its download and redirect handling is
     reusable** and the new importer should start from it rather than from nothing.
   - 🔴 **RESOLVED 2026-11-04 — WE DO NOT HAVE AP. Piece 2 is re-specified on state Secretary
     of State feeds.** No AP client, endpoint or credential exists anywhere in the repo, and
     AP's feed is a paid contract we do not hold. The operator chose to re-spec rather than
     procure.

     **What this changes.** The called/certified split survives, but both stages now come from
     the same publisher at different moments:

     | Stage | Source | Meaning |
     |---|---|---|
     | `called` | the state's **unofficial / election-night returns** | counting is done enough to name a winner; totals may still move |
     | `certified` | the state's **official canvass** | the result is final |

     That is arguably a *better* distinction than AP-call-versus-certification, because both
     ends are the same authority and the repo's rule that the chamber's own record outranks
     every aggregator already points this way.

     🔴 **But the cost is real and it lands on piece 2: there is no single feed.** Fifty states
     publish differently, and wave 1 alone (35 Senate seats) spans 35 separate SoS sites.
     Piece 2 is therefore the **largest** item in the program, not a helper, and it should be
     built per-state and incrementally rather than as one importer:
     - Wave 1 is 35 states × 1 race. Hand entry is viable at that size and is the honest
       fallback while the importer is still thin — **35 seats must not wait on 50 scrapers.**
     - Wave 3 is ~173 races in **one** state (California). One scraper covers nearly the whole
       wave with the nearest deadline. ▶ **Build California first**, not alphabetically.
     - Expect WAF trouble: per CLAUDE.md, F5 WAFs on government hosts reject Node's `fetch` on
       its TLS fingerprint and answer **HTTP 200 with a challenge body**, so never judge a
       fetch by `r.ok`. Reuse `importElectionData.ts`'s download path and plan for Playwright
       on the hosts that need it.
3. **The 641 empty race shells are IN SCOPE.** MA, ME, MD, OR and NV need their candidate
   fields seeded before any result can be recorded against them. This roughly doubles the
   state tier and needs a per-state sourcing plan.
4. **The Essentials change is IN SCOPE — API and frontend both.** The stated problem is that
   voters see a departing officeholder with no sign they are leaving. Future-dated terms alone
   do not fix that. A tracker at 100% with no rendering leaves the problem unsolved, so the
   "Outgoing" / "Incoming on &lt;date&gt;" display ships as part of this work and must land
   before 2027-01-03.

5. **Priority is Federal → December locals → State → remaining locals.** ⚠ This superseded an
   earlier decision the same day. The operator first set Federal → State → Local, with local
   "as soon as possible, but it can be prioritized after Federal/State". Measuring the local
   tier's historical term-start months then showed that **local's deadline arrives first**
   (see "Order of work"), and the operator agreed to reorder on 2026-11-04. Local was never
   deferred into 2027 under either version; what changed is that most of it now runs *second*,
   not third.
6. **The team today is one person and Claude. Build for handoff anyway.** The operator: *"the
   teammates may just be me and claude. But if we get funds, I can get more support and want
   the ability to hand it off."* So assignment is a **real** feature, not a stub — but it is
   sized for one-to-a-few people, not for an org. Concretely: an assignment is a name against
   a batch, visible to whoever opens the page. No roles, no permissions, no invitations, no
   notification system. The test is whether a new person can open the artifact and see what is
   unclaimed, not whether the artifact can administer a team.
   - ⚠ This raises the value of displaying steward leases read-only: today, "the team" is
     mostly Claude sessions, and those already take leases. The artifact showing them is the
     only place a human sees both layers at once.

## Scope, restated

With those decisions this is a **program of eight pieces**, not a tracker:

| # | Piece | Depends on |
|---|---|---|
| 1 | `result_certainty` migration (additive, `won` only) | — |
| 2 | Results importer: AP calls, SoS certification | 1 |
| 3 | Candidate seeding for the **691** empty shells: 641 state (MA/ME/MD/OR/NV) + 50 local (AZ/OR/WI) | — |
| 4 | Swearing-in date table in production, researched per state | — |
| 5 | Incumbency reconciliation script + schedule | — |
| 6 | Status measurement script (read-only, JSON out) | 1 |
| 7 | The tracker artifact (renders 6, holds assignments and notes) | 6 |
| 8 | Essentials next-term read path + "Outgoing"/"Incoming on" rendering | — |

A ninth is likely: an `unseat` helper to pair with `vacate_office`, since cancelling a
scheduled handover is otherwise a hand-written two-step across a population where declines and
deaths before January are a certainty.

🔴 **The Senate batch is the trial run and must exercise the whole spine, not just the
tracker.** 35 seats through pieces 1, 2, 5, 6, 7 and 8 end to end proves the design before 435
House seats follow. A trial run that only proves the tracker proves the easy part.

## Shape of the build

The tracker itself is two pieces; the rest of the program is listed above.

**1. A measurement script** in `backend/scripts/`, read-only, that produces the whole status
set as JSON: every race with its level, state, office, current holder, winner if recorded,
seat state, and gap flags. This is the single place the counts are computed. It needs a
positive control — plant a known-wrong row, watch the count move — because a status script
that reports "nothing outstanding" is exactly the uniform answer this repo distrusts.

**2. A published Artifact** that renders that JSON and holds the human layer in its own
database: batch assignments and per-seat notes. It is a **living artifact** — updated in place
at its existing URL, never republished fresh.

The script's output is pushed into the artifact when it is re-run. The artifact never queries
production directly and holds no credentials.

🔴 **Swearing-in dates do NOT live in the artifact.** An earlier draft put them there. That was
wrong: the artifact is one-way (production → artifact), so a date typed into it can only reach
`seat_officeholder` by a person retyping it, which writes a term with no citation and breaks
this repo's sourcing rules. Non-statutory swearing-in dates belong in **piece 4**, a production
table with a source per row. The artifact displays them; it does not own them.

**Piece 4 keys on the OFFICE, with a per-(state, district_type) default** — builder's call,
recorded. Per-state alone is already disproved by our own data: the six Washington seats with
a dated handover are **county** offices ending 2026-12-31, which is not a Washington statewide
date. Keying on the office lets the seeding script look a date up itself in the common case
while still allowing a per-seat override, which is the difference between a scripted wave and
526 manual lookups.

🔴 **A predecessor's term may end BEFORE the successor's term starts, leaving a real gap.**
The six Washington county terms end 2026-12-31; if those winners take office later,
`seat_officeholder` finds no covering term, inserts cleanly — no overwrite — and the office
resolves as **unheld** in between. An address search then returns a seat with no name, which
is the nameless-row defect fixed on 2026-10-26 arriving by a different route.
▶ Builder's call: write the gap as an explicit vacancy span via `vacate_office` at
`term_end + 1`, so the seat reads as a declared vacancy rather than an absence, and piece 8
renders it as vacant **with** the "Incoming on &lt;date&gt;" line. Do **not** leave it
unwritten: an unwritten gap is indistinguishable from a seeding failure.

## Constraints inherited from the repo

- Migrations get numbers from `npm run steward --prefix backend -- slot CC --purpose "..."`.
  Never counted by hand.
- Migrations are idempotent and end in a `DO $$ ... $$` post-verify gate that raises on a
  wrong count. Gate on the **delta** the migration creates, in its own transaction — the
  occupancy totals move between sessions.
- A migration that overwrites a value records the old value in its own header.
- `seat_officeholder` does **not** clear `is_vacant`. Any seating of a flagged seat must clear
  the flag in the same migration and assert it.
- Set `politicians.is_incumbent` explicitly on every insert. It defaults to `false`, and a
  seated person inserted without it is hidden from address search.
- Politician-rooted reads need `DISTINCT ON (p.id)`; office-rooted reads dedupe on `o.id`.
- Any new table or view goes in an EV schema, never `public`, with explicit grants, RLS
  enabled and its policies created in the same migration.
- Work in a dedicated worktree; commit with an explicit pathspec.

## Assignments versus steward leases (builder's call, recorded)

The repo already has a claim system built for this collision: `steward claim state:xx`, with
leases, expiry warnings and containment checks. Two claim systems that can disagree is the
failure the steward exists to prevent.

They answer different questions, so both are kept, but **the artifact must not invent a second
lease**: it holds *who on the team owns a batch* (a person, over days), and it **displays
steward leases read-only** beside them (a session, over hours). A batch assigned to someone
with no matching steward lease is normal; a steward lease held by someone other than the
assignee is worth showing, because that is the collision.

✅ **Resolved 2026-11-04:** today the team is the operator plus Claude sessions. Assignment is
still built — the operator wants to hand work off if funding arrives — but sized for one to a
few people (see decision 6). The steward-lease display carries most of the weight in the
meantime, because most "workers" right now are sessions holding leases.

## Left to the builder

- The exact JSON shape the script emits, and how it is chunked for the artifact.
- The artifact's layout, and whether tiers are tabs, sections or a filter.
- Whether assignment is per state, per chamber, or free-form.
- How the "next term" read path is exposed to Essentials — a view, or a query in
  `essentialsService.ts`. The frontend change is a separate piece of work and is out of scope
  for this document beyond the data it needs.
