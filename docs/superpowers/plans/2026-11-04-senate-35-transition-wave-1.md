# Senate 35 — Transition Wave 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Take all 35 US Senate seats from the 2026-11-03 election through the full transition pipeline — result recorded with provenance, winner seated on a future-dated term, incumbency reconciled, progress measurable — and publish the tracker that will run the remaining four waves.

**Architecture:** Results are recorded on `race_candidates` with a new `result_certainty` column. Winners are seated into `essentials.office_terms` with `term_start = 2027-01-03`, which `essentials.current_office_holders` keeps invisible until that date, so the handover executes itself. Three cached columns that do *not* follow the calendar get a reconciler and a fix to their runtime writers. A read-only status script computes progress; a published Artifact renders it and holds assignments.

**Tech Stack:** PostgreSQL (Supabase), Node ESM scripts in `backend/scripts/`, TypeScript services in `backend/src/lib/`, Vitest, the Artifact tool.

**Spec:** [`docs/superpowers/specs/2026-11-04-post-election-transition-tracker-design.md`](../specs/2026-11-04-post-election-transition-tracker-design.md)

## Global Constraints

- Migration numbers are **allocated, never counted**: `npm run steward --prefix backend -- slot CC --purpose "..."`. Name the file that number immediately.
- Author namespace is **`CC_`** (Chris Cantrell). Never `CA_`.
- Every migration is idempotent and ends in a `DO $$ ... $$` post-verify gate that `RAISE EXCEPTION`s on a wrong count.
- **Gate on the delta the migration creates, in its own transaction** — occupancy totals move between sessions.
- A migration that overwrites a value **records the overwritten value in its own header**.
- Dry-run against prod first: `node scripts/dry-run-migration.mjs migrations/<file>.sql --verify -`. Confirm the rollback reverted before applying.
- Apply with `node scripts/apply-migration-file.mjs migrations/<file>.sql`, never by pasting the body.
- `politicians.is_incumbent` is set **explicitly** on every insert. It defaults to `false`; a seated person inserted without it is hidden from address search.
- Politician-rooted reads need `DISTINCT ON (p.id)`; office-rooted reads dedupe on `o.id`.
- No table or view in `public`. New objects get explicit grants, `enable row level security`, and their policies in the same migration.
- Commit with an explicit pathspec: `git commit -F msg -- <path>`.
- `WebFetch` must never be the source of a name, a date or a count. Open the page.
- Never judge a fetch by `r.ok` — government WAFs answer HTTP 200 with a challenge body.

## Review Focus

Five failure modes the spec implies that no task's happy path exercises. Each has a test in the task that owns the code.

1. **The incumbent wins re-election.** 378 of 468 federal seats have the holder on their own ballot; `seat_officeholder` historically no-ops this case. Covered by Task 2.
2. **The outgoing holder's term already has an end date.** SC Senate carries `term_end = 2027-01-03`; seating a successor rewrites it. Covered by Task 2.
3. **A race with no winner yet.** On 2026-11-04 not every race is called; recounts run for weeks. The status script and the seating migration must both treat "no result" as a normal state, not an error. Covered by Task 3.
4. **A winner we have never seen before.** A new senator may have no `politicians` row, or one with `is_incumbent` defaulted to `false`. Covered by Task 5.
5. **A reconciled `is_incumbent` that a staging promotion immediately reverts.** `stagingService.ts:456` forces `is_incumbent = true` on conflict. A reconciler whose control never runs a promotion will pass while being useless. Covered by Task 6.

---

## Pre-flight

- [ ] **Create an isolated worktree.** `git worktree add -b transition/senate-2026 /c/ev-accounts-senate origin/master`. Work only there; never move HEAD in a worktree you did not create.
- [ ] **Run `npm run install:hooks --prefix backend`** in that checkout if the pre-commit pathspec hook is not already active.
- [ ] **`git fetch origin`** before trusting any migration-number check.

⚠ **The steward cannot express this wave's scope.** Claims are `place:` / `county:` / `state:`; "US Senate" spans 35 states and claiming all 35 would block unrelated work. Take **no** jurisdiction claim for this wave. The worktree marker and branch-drift report are the collision protection here. Record this in the PR body so the next wave does not read the absence as an oversight.

## File Structure

| File | Responsibility |
|---|---|
| `backend/migrations/CC_<a>_result_certainty.sql` | New column, backfill of 489 historical `won` rows, validated CHECK |
| `backend/migrations/CC_<b>_seat_officeholder_reelection.sql` | Extend the helper to handle a re-elected incumbent |
| `backend/scripts/election-transition-status.mjs` | Read-only status computation for any election date and tier |
| `backend/scripts/election-transition-status.test.ts` | Unit tests incl. the positive control |
| `backend/data/senate-2026-results/RESULTS.md` | Per-seat sources, read field by field |
| `backend/data/senate-2026-results/results.json` | Machine-readable winner set the seating migration is generated from |
| `backend/migrations/CC_<c>_senate_2026_results.sql` | Writes `result` / `result_certainty` / `result_source` |
| `backend/migrations/CC_<d>_senate_2026_seat_winners.sql` | Seats winners at `2027-01-03` |
| `backend/scripts/reconcile-incumbency.mjs` | Recomputes the three cached columns from `office_terms` |
| `backend/scripts/reconcile-incumbency.test.ts` | Tests incl. the promotion-reverts control |
| `backend/src/lib/stagingService.ts` | Stop forcing `is_incumbent = true` on conflict |
| `backend/migrations/CC_<e>_office_next_term_view.sql` | `essentials.office_next_term` view + grants + RLS |
| `backend/src/lib/essentialsService.ts` | Expose the incoming holder on office reads |

---

### Task 1: `result_certainty` column

**Files:**
- Create: `backend/migrations/CC_<a>_result_certainty.sql`

**Interfaces:**
- Produces: `essentials.race_candidates.result_certainty text`, values `'called' | 'certified'`, NULL unless `result = 'won'`.

- [ ] **Step 1: Allocate the slot**

Run: `npm run steward --prefix backend -- slot CC --purpose "race_candidates.result_certainty column and historical backfill"`
Name the file with the returned number immediately.

- [ ] **Step 2: Measure and record the pre-state**

Run against prod, and paste both numbers into the migration header:

```sql
SELECT count(*) FILTER (WHERE result = 'won')                            AS won_rows,
       count(*) FILTER (WHERE result = 'won' AND result_certainty IS NOT NULL) AS already_set
  FROM essentials.race_candidates;
```

Expected at time of writing: `489 / 0`. The header must state that **all 489 overwritten values were NULL** — that is the overwrite record the repo rule requires.

- [ ] **Step 3: Write the migration**

Three statements, idempotent:
1. `ALTER TABLE essentials.race_candidates ADD COLUMN IF NOT EXISTS result_certainty text;`
2. Guarded backfill: set `result_certainty = 'certified'` where `result = 'won' AND result_certainty IS NULL`. Past elections are certified by now; state that reasoning in a comment.
3. `ADD CONSTRAINT race_candidates_result_certainty_check CHECK (result_certainty IS NULL OR result_certainty IN ('called','certified'))` and `CHECK (result <> 'won' OR result_certainty IS NOT NULL)`, both fully valid.

End with a post-verify gate that `RAISE EXCEPTION`s unless zero rows have `result = 'won' AND result_certainty IS NULL`.

- [ ] **Step 4: Dry-run against prod and read the verify output**

Run:
```bash
node scripts/dry-run-migration.mjs migrations/CC_<a>_result_certainty.sql --verify - <<'SQL'
SELECT result_certainty, count(*) FROM essentials.race_candidates WHERE result='won' GROUP BY 1;
SQL
```
Expected: `certified | 489`, then an unconditional rollback. A clean run means the SQL executed, not that the data is right — read the verify block.

- [ ] **Step 5: Plant a tamper and watch the gate fail**

Change the backfill's `WHERE` to `AND false` in a copy of the file. **Assert the tamper is present** (`grep -c 'AND false'` returns 1 — a `sed` that silently missed would leave a file that passes every gate it does not contain). Dry-run the copy.
Expected: FAIL from the post-verify gate. Delete the copy.

- [ ] **Step 6: Apply and commit**

```bash
node scripts/apply-migration-file.mjs migrations/CC_<a>_result_certainty.sql
git commit -F msg -- backend/migrations/CC_<a>_result_certainty.sql
```

---

### Task 2: Extend `seat_officeholder` for re-election

**Files:**
- Create: `backend/migrations/CC_<b>_seat_officeholder_reelection.sql`

**Interfaces:**
- Consumes: nothing.
- Produces: `essentials.seat_officeholder(p_office_id uuid, p_politician_id uuid, p_term_start date, p_source text, p_how_started text DEFAULT 'elected', p_start_precision text DEFAULT 'day', p_how_ended_prev text DEFAULT 'term_expired')` — unchanged signature, changed behaviour in the same-politician branch.

The current body returns the existing term id and writes nothing when `v_prev_pol IS NOT DISTINCT FROM p_politician_id`. That branch becomes: close the covering term at `p_term_start - 1` and insert a new one, exactly as the different-politician branch does.

Two guards stay exactly as they are: the `(office_id, politician_id, term_start)` re-run check at the top (so a repeat call with the same date is still a no-op), and the refusal when `v_prev_start >= p_term_start`.

- [ ] **Step 1: Allocate the slot**

Run: `npm run steward --prefix backend -- slot CC --purpose "seat_officeholder: a re-elected incumbent gets a fresh term row"`

- [ ] **Step 2: Write the failing control, as SQL inside a rolled-back transaction**

Create `backend/scripts/_seat-reelection-control.sql` (scratch, not committed): inside `BEGIN; ... ROLLBACK;`, pick one Senate office, call `seat_officeholder` with the **sitting holder's** id and `2027-01-03`, then assert:

```sql
-- expect 2 rows for this office/politician: one closed 2027-01-02, one starting 2027-01-03
SELECT count(*) FROM essentials.office_terms
 WHERE office_id = :office AND politician_id = :holder;
-- expect exactly 1 row from the current-holder view
SELECT count(*) FROM essentials.office_current_holder WHERE office_id = :office;
```

- [ ] **Step 3: Run it against the CURRENT helper and watch it fail**

Run: `node scripts/dry-run-migration.mjs scripts/_seat-reelection-control.sql`
Expected: the term count is **1**, not 2 — the helper no-opped. This is the defect being fixed; see it before fixing it.

- [ ] **Step 4: Write the migration**

`CREATE OR REPLACE FUNCTION essentials.seat_officeholder(...)` with the same-politician branch replaced as described in Interfaces. Keep `SET search_path TO ''` and every existing guard.

- [ ] **Step 5: Dry-run the migration with the control appended, and watch it pass**

Expected: term count **2**, adjoining dates, current-holder view returns exactly **1** row.

- [ ] **Step 6: Add the already-ends case**

Extend the control to a second office — SC Senate, whose holder's term already carries `term_end = 2027-01-03` — seating a *different* politician at `2027-01-03`. Assert the predecessor's `term_end` is now `2027-01-02` and that the migration header records the overwritten value `2027-01-03`.

- [ ] **Step 7: Apply and commit**

---

### Task 3: Status measurement script

**Files:**
- Create: `backend/scripts/election-transition-status.mjs`
- Test: `backend/scripts/election-transition-status.test.ts`

**Interfaces:**
- Consumes: `result_certainty` from Task 1.
- Produces:
  - `buildStatus(client, { electionDate, levels }) -> { generatedAt, electionDate, seats, totals }`
  - `seatState(row) -> 1|2|3|4|5` — pure, exported, unit-testable with no database.
  - `Seat = { raceId, officeId, level, state, title, positionName, currentHolder, winner, resultCertainty, seatState, flags }`
  - `flags = { noCandidateRows, noHeadshot, noStances, holderTermEndsEarly }`
  - `level ∈ 'federal' | 'state' | 'local' | 'unknown'`, derived from `districts.district_type` exactly as the spec's table does.

Three measurement rules the spec pins:
- Stance coverage comes from `inform.politician_answers`, **not** `politicians.last_stances_researched_at` (431 vs 4,827 — the flag is unusable). Blanks (`value = 0`) count: this asks whether research happened.
- Headshot presence is `politicians.photo_custom_url` OR `race_candidates.photo_url`.
- "Still in contention" is **this script's own predicate**, `result IS NULL OR result NOT IN ('lost','not_nominated','withdrew')`. Do **not** use `essentials.is_live_candidate` — it returns TRUE for `won` and `lost` alike, by design.

- [ ] **Step 1: Write the failing unit tests for `seatState`**

```ts
it('returns 1 when no result is recorded', () => { expect(seatState({ result: null })).toBe(1) })
it('returns 2 for a called win', () => { expect(seatState({ result: 'won', resultCertainty: 'called' })).toBe(2) })
it('returns 3 for a certified win', () => { expect(seatState({ result: 'won', resultCertainty: 'certified' })).toBe(3) })
it('returns 4 when a future-dated term exists', () => { expect(seatState({ result: 'won', resultCertainty: 'certified', winnerTermStart: '2027-01-03', today: '2026-11-04' })).toBe(4) })
it('returns 5 once that term has started', () => { expect(seatState({ result: 'won', resultCertainty: 'certified', winnerTermStart: '2027-01-03', today: '2027-01-03' })).toBe(5) })
it('stays at 1 for an undecided race rather than throwing', () => { expect(seatState({ result: null, liveCandidates: 4 })).toBe(1) })
```

- [ ] **Step 2: Run to verify they fail**

Run: `npx vitest run scripts/election-transition-status.test.ts -t seatState`
Expected: FAIL, `seatState is not a function`.

- [ ] **Step 3: Implement `seatState` and `buildStatus` in `backend/scripts/election-transition-status.mjs`**

`buildStatus` issues one query joining `elections → races → offices → districts → office_current_holder → race_candidates`, plus the two coverage sub-selects. Office-rooted, so dedupe on `o.id`. CLI entry point writes JSON to stdout, and takes `--election-date` (default `2026-11-03`) and `--levels` (default all).

- [ ] **Step 4: Run to verify they pass**

Run: `npx vitest run scripts/election-transition-status.test.ts`
Expected: PASS.

- [ ] **Step 5: Run against prod and check the Senate totals against the spec**

Run: `node scripts/election-transition-status.mjs --levels federal | node -e "..."` and assert 35 `NATIONAL_UPPER` seats, all at state 1, 35 with a current holder.
🔴 A uniform answer is a broken detector until a control passes — all 35 reading "state 1" is exactly what a query returning nothing useful also looks like. Proceed to Step 6 before trusting it.

- [ ] **Step 6: Positive control — plant a result, watch the state move, roll back**

In a `BEGIN; ... ROLLBACK;` transaction, set one Senate candidate to `result='won', result_certainty='called'`, re-run `buildStatus` **inside that transaction**, and assert that seat reads state 2 while the other 34 read state 1.
🔴 This is the step that proves the script reads the rows it claims to. Assert the **count it examined** (35), not only that it did not crash.

- [ ] **Step 7: Commit**

---

### Task 4: Research and record the 35 results

**Files:**
- Create: `backend/data/senate-2026-results/RESULTS.md`
- Create: `backend/data/senate-2026-results/results.json`
- Create: `backend/migrations/CC_<c>_senate_2026_results.sql`

**Interfaces:**
- Consumes: `result_certainty` (Task 1).
- Produces: `results.json` as `[{ state, raceId, winnerPoliticianId, winnerName, result: 'won', resultCertainty, resultSource, sourceUrl, readOn }]`, and `result='lost'` rows for every defeated candidate in a decided race.

**Sourcing rules, each of which this repo paid for:**
- 🔴 The state's own returns page outranks every aggregator. A search summary is a lead; open the page.
- 🔴 `WebFetch` fabricates names and dates and formats them as quotations. Use it to locate a document only. Never source a name, a date or a count from it.
- 🔴 A clean HTTP 200 can be a WAF challenge body. If Node `fetch` returns something that does not parse as returns, retry with `curl`, then Playwright.
- A race that is not yet called gets **no row**. An undecided seat stays at state 1; that is correct, not a gap.

- [ ] **Step 1: Write `RESULTS.md` with one section per state**

Each section records: the returns URL, the date and time read, the winner as the page names them, whether the page is unofficial or certified, and the margin. Where a race is uncalled, say so and why.

- [ ] **Step 2: Resolve each winner to a `politicians.id`**

Match against `race_candidates.politician_id` for that race first. A winner with no candidate row is a finding, not a lookup failure — record it in `RESULTS.md` and handle it in Task 5.

- [ ] **Step 3: Write `results.json` from `RESULTS.md`, not from memory**

- [ ] **Step 4: Generate `CC_<c>_senate_2026_results.sql` from `results.json`**

Guarded `UPDATE`s on `race_candidates`, setting `result`, `result_certainty`, `result_source` (which the existing `race_candidates_result_needs_source` CHECK requires non-empty). Post-verify gate: the number of `won` rows for this election equals the number of decided races in `results.json`, **and** no race has two `won` rows.

- [ ] **Step 5: Dry-run, verify, apply, commit**

---

### Task 5: Seat the 35 winners

**Files:**
- Create: `backend/migrations/CC_<d>_senate_2026_seat_winners.sql`

**Interfaces:**
- Consumes: the extended `seat_officeholder` (Task 2), `results.json` (Task 4).

Every call is `SELECT essentials.seat_officeholder(<office>, <winner>, DATE '2027-01-03', '<source>');`

- [ ] **Step 1: Assert every winner has a `politicians` row with `is_incumbent` set explicitly**

For a winner new to us, `INSERT ... is_incumbent = false` — they are not an incumbent until sworn in, and the column defaults to `false` anyway, so the value is written explicitly to say it was decided. Post-verify: zero winners with a NULL `politicians` row.

- [ ] **Step 2: Record every `term_end` this migration will overwrite**

Query the outgoing holders' current `term_end` values and paste them into the header. Expected: SC Senate `2027-01-03`, one other federal seat. **The values exist nowhere else once this commits.**

- [ ] **Step 3: Write the migration**

One helper call per decided seat. Then, for any office flagged `is_vacant`, clear it in the same file — `seat_officeholder` does **not** touch `essentials.offices`, and leaving the flag gives a held-and-vacant row.

- [ ] **Step 4: Post-verify gate — on the delta, in this transaction**

Assert: the count of `office_terms` rows with `term_start = '2027-01-03'` for `NATIONAL_UPPER` offices rose by exactly the number of decided seats; `essentials.office_current_holder` still returns exactly one row per Senate office; and **no Senate office resolves as unheld today**.

- [ ] **Step 5: Verify the view has NOT changed today**

Run before and after, expecting identical output:
```sql
SELECT o.representing_state, p.full_name FROM essentials.offices o
JOIN essentials.districts d ON d.id=o.district_id AND d.district_type='NATIONAL_UPPER'
LEFT JOIN essentials.office_current_holder och ON och.office_id=o.id
LEFT JOIN essentials.politicians p ON p.id=och.politician_id ORDER BY 1;
```
🔴 This is the measurement the spec demands: the transition must be invisible today. Reasoning about the read path is not measuring it.

- [ ] **Step 6: Dry-run, apply, commit**

---

### Task 6: Incumbency reconciler and its runtime writers

**Files:**
- Create: `backend/scripts/reconcile-incumbency.mjs`
- Test: `backend/scripts/reconcile-incumbency.test.ts`
- Modify: `backend/src/lib/stagingService.ts:456`

**Interfaces:**
- Produces: `computeIncumbencyDrift(client) -> { politicianId, column, current, expected }[]` and `applyIncumbencyFixes(client, rows) -> number`.
- Covers all three cached columns: `politicians.is_incumbent`, `politicians.office_id`, `race_candidates.is_incumbent`.

Truth is `essentials.office_current_holder`: a politician is an incumbent iff they resolve as the current holder of at least one office today. Politician-rooted, so `DISTINCT ON (p.id)`.

- [ ] **Step 1: Write the failing test for `computeIncumbencyDrift`**

```ts
it('flags a politician marked incumbent who holds no current seat', ...)
it('flags a current holder marked is_incumbent = false', ...)
it('reports race_candidates.is_incumbent separately from politicians.is_incumbent', ...)
it('returns nothing when every cached value agrees', ...)
```

- [ ] **Step 2: Run to verify they fail**

- [ ] **Step 3: Implement both functions**

- [ ] **Step 4: Run to verify they pass**

- [ ] **Step 5: Stop `stagingService` forcing the flag**

At `backend/src/lib/stagingService.ts:456` the `ON CONFLICT (external_id) DO UPDATE` sets `is_incumbent = true` unconditionally. Remove `is_incumbent` from the `DO UPDATE` set-list so a promotion no longer overwrites a reconciled value; leave the INSERT's explicit `true` alone. Update the doc comment at line 425, which currently says "Always sets: is_active = true, is_incumbent = true".
Check `adminService.ts:707` (`data.is_incumbent ?? true`) and record whether it is in scope — it is an admin-initiated write, not a sweep, so defaulting is defensible; say so rather than leaving it unexamined.

- [ ] **Step 6: The control that matters — prove a promotion no longer reverts a fix**

🔴 A control that only plants drift and watches the reconciler fix it **proves nothing here**: it never exercises the writer that reverted it. In one rolled-back transaction: plant drift → run `applyIncumbencyFixes` → run the staging promotion path for that same `external_id` → assert `is_incumbent` still holds the reconciled value.
Run this control against the **unmodified** `stagingService` first and watch it FAIL. That failure is the proof the control is live.

- [ ] **Step 7: Commit**

---

### Task 7: Next-term read path

**Files:**
- Create: `backend/migrations/CC_<e>_office_next_term_view.sql`
- Modify: `backend/src/lib/essentialsService.ts`
- Test: `backend/src/lib/essentialsService.test.ts`

**Interfaces:**
- Produces: `essentials.office_next_term(office_id, politician_id, term_start, start_precision)` — the earliest term per office with `term_start > CURRENT_DATE`, one row per office.
- Produces on the politician flat record: `incoming_holder_id: string | null`, `incoming_holder_name: string | null`, `incoming_on: string | null` (ISO date).

Labels are **derived from dates, never stored**. "Outgoing" means this office has a next term; "Incoming on \<date\>" is that term's `term_start`. Nothing needs undoing in January.

The view goes in `essentials`, not `public`, with `security_invoker = on`, explicit grants to `anon`, `authenticated`, `service_role`, `ev_api`, and RLS enabled with its policies in the same migration.

- [ ] **Step 1: Allocate the slot and write the failing service test**

```ts
it('returns incoming_holder_name and incoming_on for an office with a future term', ...)
it('returns nulls for an office with no future term', ...)
it('does not change who the current holder is', ...)
it('returns one row per office when a politician holds two seats', ...)
```

- [ ] **Step 2: Run to verify they fail**

Run: `npx vitest run src/lib/essentialsService.test.ts -t incoming`

- [ ] **Step 3: Write the view migration; dry-run; apply**

- [ ] **Step 4: Add the LEFT JOIN and the three fields to `essentialsService.ts`**

LEFT JOIN, so an office with no successor still returns. ⚠ The existing filter at line 360 is `AND och.office_id IS NOT NULL AND p.is_incumbent = true` — do not let the new join widen or narrow that match. Per the `is_vacant` trap, any new condition must constrain the match, not a downstream join.

- [ ] **Step 5: Run to verify they pass**

- [ ] **Step 6: Measure the live endpoint, not the query**

Boot the server and request a South Carolina address. Assert the response still names the sitting senator as current **and** carries `incoming_on: "2027-01-03"`.
🔴 The spec requires this be measured against the live endpoint. Reasoning about a read path is not measuring it.

- [ ] **Step 7: Commit**

---

### Task 8: Publish the tracker artifact

**Files:**
- No new repo files. The artifact is published via the Artifact tool and consumes Task 3's output.

**Interfaces:**
- Consumes: `buildStatus` JSON (Task 3).

The artifact renders computed status and holds **only** the human layer in its own database: batch assignments and per-seat notes. Swearing-in dates are **not** stored here — they belong in production (spec piece 4); the artifact displays them.

- [ ] **Step 1: Generate the full status set**

Run `node scripts/election-transition-status.mjs > status.json` for all tiers, not just the Senate — the artifact covers the whole program from the start, so wave 2 needs no rebuild.

- [ ] **Step 2: Publish the artifact with the `db` capability**

Load the `artifact-capabilities` skill before writing the page. Tiers as the spec's five waves, each seat showing its state, provenance badge (`called` / `certified`), and the two gap flags. Assignment is a name against a batch — no roles, no permissions, no invitations.

- [ ] **Step 3: Show steward leases read-only beside the assignments**

A batch assigned to someone with no matching steward lease is normal. A steward lease held by someone other than the assignee is the collision worth surfacing.

- [ ] **Step 4: Verify the counts against the database**

Assert the artifact's Senate totals equal `buildStatus`'s. A tracker that disagrees with the data on day one will not be trusted on day thirty.

- [ ] **Step 5: Record the artifact URL in the design doc and in `MEMORY.md`**

🔴 It is a **living artifact**: updated in place at that URL, never republished fresh.

---

## What this plan deliberately does not cover

Checked against the spec's eight pieces, so a reader can tell a scoping decision from an
oversight:

| Spec piece | Status in wave 1 | Why |
|---|---|---|
| 2 — SoS results importer | **Deferred.** Task 4 is hand entry. | 35 seats across 35 states. The spec's own rule: *35 seats must not wait on 50 scrapers.* Build the importer for wave 3, where ~173 races sit in one state. |
| 3 — seeding the 691 empty shells | **Not applicable.** | No Senate race lacks candidate rows; all 35 have live fields. |
| 4 — swearing-in date table | **Not needed yet.** | Federal is statutory at 2027-01-03. The table becomes load-bearing at wave 3, where dates vary and are mostly December. |
| 8 — Essentials voter-facing render | **API half only** (Task 7). | The Essentials frontend is a **separate repository**, not `app/` or `admin/` here. It gets its own plan once `incoming_on` is live. |

🔴 **Wave 1 is not finished when this plan is.** Until the Essentials render ships, voters still
see a departing senator with no sign they are leaving — the problem the spec opens with. Task 7
makes that render possible; it does not deliver it.

## Done when

- All 35 Senate races carry a result, or a recorded reason they do not.
- Every decided seat has a `2027-01-03` term, and the current-holder view still returns the sitting senator today.
- `reconcile-incumbency` reports zero drift, and a staging promotion does not reintroduce it.
- The live endpoint serves `incoming_on` for a seat that changes hands.
- The tracker is published and its Senate counts match the database.
