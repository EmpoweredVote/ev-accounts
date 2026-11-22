# State Seating (2026-11-03) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Write the future-dated `essentials.office_terms` row that schedules each 2026 state-tier winner into their seat, so the display shipped by PR #1574 stops saying "declared winner" for every body whose start date we can cite.

**Architecture:** A wave is one body — one `(state, district_type)` pair — and ships as at most two migrations: the cited date rows into `essentials.office_swearing_in`, then the seating, built on `CC_0453`'s template (selection derived by query and pinned by digest, term start read from the table rather than written into the file). Shared machinery comes first: one script that derives a wave's pin block and names its blockers, so none of the 73 waves counts by hand. Then the bodies whose dates we already hold and cite ship as real waves, proving the machinery at 2 offices, at 3 and at 121. The remaining 70 bodies run the same recipe from a register this plan produces.

**Tech Stack:** PostgreSQL (Supabase, `essentials` schema), Node ESM scripts under `backend/scripts/`, vitest.

**Spec:** `docs/superpowers/specs/2026-11-21-transition-display-and-state-seating-design.md` §8 — on branch `feat/transition-display` (PR #1574) until that merges.

**Precedents to read before Task 2.** These are the files this plan instructs you to copy, not to improve on:

- `backend/migrations/CC_0453_house_2026_seat_winners_2027_01_03.sql` — the seating template. Read all 329 lines.
- `backend/migrations/CC_0445_wi_2026_swearing_in_dates.sql` — the date-row template.
- `backend/migrations/CC_0344_office_swearing_in.sql` — the register table and its CHECK constraints.
- `backend/scripts/lib/seating-invariants.mjs` with `check-seating-invariants.mjs` and `control-seating-invariants.mjs` — the house shape for a pure verdict module, a thin CLI, and a control that watches the check go red.

## What is actually there

Measured against production 2026-11-21, after `CC_0458`/`CC_0459`/`CC_0460` applied. These numbers supersede the spec's §8.1 where they differ, and the differences are noted.

| | |
|---|---|
| state-tier offices with a winner and no scheduled term | **1,286** (825 `STATE_LOWER`, 245 `STATE_UPPER`, 174 `STATE_EXEC`, 27 `STATE_BOARD_EDUCATION`, 15 `STATE_BOARD`) |
| research units — `(state, district_type)` pairs | **73**, across **42** states and **204** chambers |
| offices whose date is already in `office_swearing_in` | **121 — every one of them Wisconsin**, covering **3 of the 73 pairs** |
| chambers carrying `inauguration_rules` prose | **15 of 204** |
| winner rows with no `politicians` record | **211** (MD 85, ME 77, MA 21, OR 15, NV 13) |
| offices carrying more than one winner | **71**, holding **169** winners (MD House 38, AZ House 29, MI/AZ/HI executives 4) |
| offices currently held | **1,282 held, 4 unheld — all 4 flagged `is_vacant`, 0 unheld-and-unflagged** |
| earliest start date anyone has cited for this population | **2027-01-01** (IN executives, LA PSC, NM PEC) |

🔴 **The spec's §8.2 called the 121 existing `office_swearing_in` rows "the single largest unknown in how much research §8 is", and they are not.** It read them as spread across the pass; they are **one state**, covering 3 of 73 pairs. However the oath-versus-term-start question is answered, 70 pairs still need a date sourced from nothing. §8.2 shrinks to a per-body line in each wave's header, which is where it belongs — and the research estimate does not move.

🟢 **Nothing here is overdue.** The earliest start date anyone has cited for this population is 2027-01-01, six weeks out. The December dates in the transition programme (Idaho re-seat 12-01, CA school boards 12-11) belong to the municipal waves, not to this one. §8.3's ordering rule still stands; it has slack in it.

⚠ **Two seats in this population are federal, not state.** Alaska's Senate seat and NC-03 — the stragglers `CC_0453` named and could not seat. They are Task 2 because they are the smallest possible test of the template, not because they belong to §8.

## Scope of this plan

**In:** the derivation machinery, and every body whose start date is already cited in our own database — **126 of the 1,286 offices**: the two federal seats, Indiana's three House seats, and all 121 of Wisconsin. Plus the register that orders the other 70 bodies, and the recipe each one runs.

**Out:** the 70 bodies whose dates nobody has sourced yet. Each is a wave of its own against the Task 5 recipe, claimed with `steward claim state:<usps>` and shipped per §8.3 by date. That is the bulk of §8 and it is research, not engineering — a task list cannot specify a citation that does not exist yet.

## Global Constraints

Exact values, from the spec's §5 and from `CLAUDE.md`. Every task's requirements include this section.

- 🔴 **A term start is not a swearing-in.** Different events, different sources. A date enters `office_swearing_in` only with the authority saying it is the **term start** for that body, or with an explicit per-body line saying that body's law starts the term **on qualification** — which makes the oath date the term start.
- 🔴 **`WebFetch` may locate a document and may never be the source of a name, a date or a count.** Open the page and read it.
- 🔴 **`chambers.inauguration_rules` is a lead, not a source.** 15 chambers carry it and the quality is uneven: Alabama's cites `Code of Alabama § 16-3-1` and computes 2027-01-18; three California executives say only *"1st Monday in the new year following election"* and name no authority at all. A rule row earns its way into `office_swearing_in` by its own citation or not at all.
- 🔴 **`basis = 'estimated'` may not seat anybody.** The table's CHECK permits the value; this plan does not accept it. Every seating migration asserts `basis IN ('statute','published')` for its own rows.
- 🔴 **Migration numbers are allocated, never counted** — `npm run steward --prefix backend -- slot CC --purpose "..."`. This is Cantrell's work, so the namespace is `CC_`. Name the file that number immediately.
- 🔴 **One migration per file. Never concatenate** — `dry-run-migration.mjs` strips only the first `BEGIN`/`COMMIT` pair and has committed a second migration to production while printing "ROLLED BACK".
- 🔴 **A migration that overwrites a value records the value it overwrote, in its own header.**
- 🔴 **Never create a table or view in `public`.** Nothing here creates either; if that changes it goes in `essentials`, with RLS and explicit grants in the same file.
- 🔴 **`districts.state` is mixed case.** Always `lower(d.state)`.
- 🔴 **Seat through `essentials.seat_officeholder`.** It does the two-step — closes the predecessor at `term_start - 1`, opens the successor. Hand-rolling that leaves the predecessor's infinite range overlapping the new term.
- 🔴 **`seat_officeholder` does not clear `is_vacant`**, and for a **future-dated** seating it must not be cleared: the seat really is empty until that morning. Only a seating whose `term_start` has already passed clears the flag, in the same migration, with an assertion.
- 🔴 **`p_allow_reelection` is computed per row, never passed `true` everywhere.** It is the guard against a wrong winner or a wrong date; switching it off wholesale disarms it for every genuine handover in the wave.
- 🔴 **Gate on the delta the migration creates, captured in its own transaction** — never on a repository-wide total another session moves while you write.
- 🔴 **The 238-unflagged `offices_missing_terms` baseline must not move, and must never be raised.** Measured: 0 of these 1,286 offices are unheld-and-unflagged, so no wave in this plan can move it. Assert it anyway.
- ⚠ **Every wave refreshes the live transition tracker artifact as its last step**, in place, never republished fresh. That is how the next session learns which bodies are done.
- ⚠ **Commit with an explicit pathspec**: `git commit -F msg -- <path>`.

## Review Focus

The five input classes the spec implies that no task's tests exercise, most likely to bite first.

1. **A Maryland delegate subdistrict is not an interchangeable seat.** Task 5's Ruling A rests on sibling offices within a district being indistinguishable. Maryland splits delegate districts into lettered subdistricts (19A, 19B) that elect separately; if those arrive as distinct office rows under one district, assigning a winner to "a remaining sibling" claims a subdistrict nobody sourced. **Pinned in Task 5 step 5:** the interchangeability assertion refuses a district whose sibling offices differ in `title`, `seats`, `voting_powers`, `representation_note` or `description`.
2. **A body where we hold fewer office rows than the race has winners.** Three winners and two seats leaves one person with nowhere to go, and a careless assignment overwrites a seat. **Pinned in Task 5 step 5:** refuse the district when the winner count exceeds the count of sibling offices, and name it.
3. **Applying a wave twice stacks a second future term.** Migrations here run once by hand, with no runner and nothing that replays them, so the file's own pre-check is the only protection. **Pinned in Task 2 step 5:** `P2` refuses when any selected office already carries an `office_next_term` row, watched failing against a planted row.
4. **A winner declines, dies or is disqualified between the wave and the term start.** We will have written a term for somebody who never takes office, and the rows have to be findable to undo. **Pinned in Task 2 step 3:** every written term's `source` carries its own migration slot, asserted in the post-verify, so `source LIKE '%CC_XXXX%'` recovers the exact set.
5. **The display does not change when a wave lands.** The point of the pass is that a seated body moves from the result card to the dated-handover card. A wave can pass every database gate and leave the page unchanged if the office leaves `office_pending_winner` without entering `office_next_term`. **Pinned in Task 3 step 7:** both views queried for all 121 Wisconsin offices, plus one live API read.

---

### Task 1: The wave derivation script

Every wave needs the same six numbers and the same seven blocker lists. Counting them by hand 73 times is where the mistakes will live, and `CC_0453`'s own header says why a file must derive rather than transcribe: *"a literal date here would agree with itself however wrong it was."*

**Files:**

- Create: `backend/scripts/lib/seating-wave.mjs`
- Create: `backend/scripts/derive-seating-wave.mjs`
- Test: `backend/scripts/lib/seating-wave.test.ts`

**Interfaces:**

- Consumes: nothing from earlier tasks.
- Produces:
  - `WAVE_SELECTION_SQL: string` — the parameterised selection. `$1` = lower-case state or `NULL` for every state, `$2` = `text[]` of district types, `$3` = election date.
  - `selectionDigest(rows: { office_id: string, politician_id: string | null, is_reelection: boolean }[]) => string`
  - `classifyWave(rows) => { rows: number, reelections: number, newHolders: number, termStart: string | null, called: number, certified: number, blockers: Blocker[] }`
  - `Blocker = { kind: 'multi_winner' | 'winner_no_record' | 'no_date' | 'date_estimated' | 'date_disagrees' | 'already_scheduled' | 'flagged_vacant', office_id: string, detail: string }`
  - `pinBlockSql(slot: string, summary) => string`

- [ ] **Step 1: Write the failing tests for the digest**

```ts
// backend/scripts/lib/seating-wave.test.ts
import { createHash } from 'node:crypto';
import { selectionDigest } from './seating-wave.mjs';

// 🔴 The digest must reproduce CC_0453's SQL expression EXACTLY:
//   md5(string_agg(office_id::text || ':' || politician_id::text || ':' || is_reelection::text,
//                  '|' ORDER BY office_id::text))
// Three things go wrong here and each gets its own test: the ORDER BY is on the id as TEXT and
// not as a uuid (they sort differently), the boolean renders the way Postgres renders it and not
// as 1/0, and the separator is '|' between rows with ':' inside one.
it('orders by office id as text, not as a uuid', () => { /* two ids that sort opposite ways */ });

it('renders the re-election flag the way Postgres does', () => {
  const rows = [{ office_id: 'a', politician_id: 'p', is_reelection: true }];
  expect(selectionDigest(rows)).toBe(createHash('md5').update('a:p:true').digest('hex'));
});

it('separates rows with a pipe and fields with a colon', () => { /* two rows */ });

it('changes when one row\'s re-election flag changes', () => { /* the tamper */ });
```

- [ ] **Step 2: Run them and watch them fail**

Run: `npx vitest run scripts/lib/seating-wave.test.ts` from `backend/`
Expected: FAIL — cannot resolve `./seating-wave.mjs`.

- [ ] **Step 3: Write the failing tests for `classifyWave`**

One test per blocker kind, each from a row fixture: a `winner_count` above 1 yields `multi_winner`; a null `politician_id` yields `winner_no_record`; a null `swearing_in_date` yields `no_date`; `basis = 'estimated'` yields `date_estimated`; two different dates in one wave yield `date_disagrees` **and** a null `termStart`; a non-null `next_term_start` yields `already_scheduled`; `is_vacant` yields `flagged_vacant`. Plus two that pin the arithmetic: `reelections + newHolders === rows`, and **a wave with blockers still returns its counts** — this script reports, it never refuses.

- [ ] **Step 4: Run them and watch them fail**

Run: `npx vitest run scripts/lib/seating-wave.test.ts` from `backend/`
Expected: FAIL — `classifyWave is not a function`.

- [ ] **Step 5: Implement `backend/scripts/lib/seating-wave.mjs`**

Pure: no database handle, no `process.exit`, no I/O. `WAVE_SELECTION_SQL` selects from `essentials.office_pending_winner` joined to `offices`, `districts`, `office_swearing_in` (on `office_id` **and** `election_date`), `office_current_holder` and `office_next_term`, filtered on `lower(d.state)` and `d.district_type = ANY($2)`. It returns **one row per winner, not per office**, so `multi_winner` is visible rather than collapsed; `is_reelection` is `och.politician_id IS NOT DISTINCT FROM <winner id>`.

- [ ] **Step 6: Run the tests and watch them pass**

Run: `npx vitest run scripts/lib/seating-wave.test.ts` from `backend/`
Expected: PASS, every test.

- [ ] **Step 7: Implement the CLI `backend/scripts/derive-seating-wave.mjs`**

`node scripts/derive-seating-wave.mjs --state wi --type STATE_LOWER --type STATE_UPPER --type STATE_EXEC [--election 2026-11-03] [--json]`. `--state` omitted means every state, for a nationwide type. It prints the counts, each blocker list with office labels, and the `pinBlockSql` output ready to paste. It exits 0 whatever it finds — a report, not a gate. Follow `check-seating-invariants.mjs` for the no-`DATABASE_URL` path: skip, exit 0, and say why.

- [ ] **Step 8: Control — the JS digest and the SQL digest agree on real rows**

Run the CLI for `--state wi --type STATE_LOWER` and capture its digest. Then run, against production, the exact `md5(string_agg(...))` expression copied from `CC_0453` over the same selection. Two independent computations of the same thing, one in JS and one in Postgres.
Expected: identical strings, over 99 rows.

- [ ] **Step 9: Control — watch that comparison fail**

Re-run the SQL with `ORDER BY office_id` (the uuid) in place of `ORDER BY office_id::text`.
Expected: a **different** digest, proving step 8 compared something real.
🔴 If the two still agree, step 8 proved nothing — this sample happens to sort the same both ways. Find a selection where the two orderings differ before trusting it.

- [ ] **Step 10: Commit**

```bash
git commit -F msg -- backend/scripts/lib/seating-wave.mjs backend/scripts/derive-seating-wave.mjs backend/scripts/lib/seating-wave.test.ts
```

---

### Task 2: Wave 0 — the two federal seats `CC_0453` left behind

`CC_0453` seated 427 of 435 House seats and named the eight it could not. Two of those now have a recorded winner and still no term: **Alaska's Senate seat** (Mary Peltola, ranked choice) and **NC-03** (Raymond Smith Jr.), both results written by `CC_0454` after `CC_0453` ran. Both offices already carry a cited `office_swearing_in` row at **2027-01-03**, `basis = 'statute'`, authority `U.S. Const. amend. XX, § 1`. Nothing needs sourcing, and two rows is the smallest honest test of the whole template.

**Files:**

- Create: `backend/migrations/CC_XXXX_ak_senate_nc03_seat_winners_2027_01_03.sql` (slot from the allocator)

**Interfaces:**

- Consumes: Task 1's CLI, for the pin block.
- Produces: the migration shape every later wave copies — pin table, selection table, pre-image table, `P1`–`P5`, the `seat_officeholder` loop, post-verify 1–10.

- [ ] **Step 1: Reserve the slot**

Run: `npm run steward --prefix backend -- slot CC --purpose "seat the AK Senate and NC-03 winners at 2027-01-03, the two seats CC_0453 named and could not"`
Name the file that number straight away.

- [ ] **Step 2: Derive the pin**

Run: `node scripts/derive-seating-wave.mjs --type NATIONAL_UPPER --type NATIONAL_LOWER --json` from `backend/`
Expected: 2 rows, term start `2027-01-03`, and the only blockers are the 427 offices reported `already_scheduled` — which is exactly why they are not in the selection.
🔴 **Record the digest, the three counts and the capture date in the file's header.** They are what `P1` refuses to proceed without.

- [ ] **Step 3: Write the migration**

Copy `CC_0453`'s structure. Keep all five pre-checks, adapted:

- `P1` — row count, digest, re-election count.
- `P2` — no selected office already carries an `office_next_term` row.
- `P3` — one winner per office.
- `P4` — every row's `swearing_in_date` equals the pinned date **and** `basis IN ('statute','published')`.
- `P5` — every winner has a `politicians` row.

Keep all ten post-verify assertions, with assertion 3 scoped to `district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')` and expecting 427 + 2, and assertion 10 pinning this slot in every new term's `source`. The header states, in its own words: what the file does and what it deliberately does not; that it seats nobody today; that a losing incumbent still holds the seat until the term ends; and an `@incumbency-decision: no-effect` block with the two numbers that make that claim checkable.

- [ ] **Step 4: Dry run against production**

Run: `node scripts/dry-run-migration.mjs migrations/CC_XXXX_*.sql` from `backend/`
Expected: `DRY RUN OK`, and the `RAISE NOTICE` reporting 2 offices seated.
⚠ If it fails with `permission denied for schema essentials`, that is the `ev_api` role and not the file — apply through the Supabase MCP, which connects privileged. Either way, **confirm the rollback actually reverted** before trusting the run.

- [ ] **Step 5: Control — plant a tamper and watch `P2` go red**

Inside a rolled-back transaction, insert a future-dated `office_terms` row for the Alaska office, then run the file's pre-check block.
Expected: `P2: 1 of these offices already carry a future term.`
🔴 **Assert the tamper is present in the transaction before running the check.** A tamper that did not apply is a control that proved nothing, and it looks exactly like a pass.

- [ ] **Step 6: Apply, and read the gate's output**

Expected: post-verify passes; the closing `RAISE NOTICE` names 2 seats scheduled for 2027-01-03 with the current-holder map untouched.

- [ ] **Step 7: Verify through the view a page actually reads**

Query `essentials.office_next_term` and `essentials.office_pending_winner` for both offices.
Expected: 2 rows in the first at 2027-01-03, **0** in the second.

- [ ] **Step 8: Commit, and refresh the tracker**

```bash
git commit -F msg -- backend/migrations/CC_XXXX_ak_senate_nc03_seat_winners_2027_01_03.sql
```

Then update the live transition tracker artifact in place.

---

### Task 3: Wave 1 — Wisconsin, 121 offices at 2027-01-04

The whole state in one migration: 99 Assembly, 17 Senate, 5 executives. Every date is already written and cited by `CC_0445` — `Wis. Const. art. XIII § 1` with `Wis. Stat. § 13.02(1)` — and the body measures clean: **0 offices with more than one winner, 0 winners without a record, 0 flagged vacant, 0 already scheduled, 0 estimated dates.** 90 re-elections, 31 new or unheld. The first wave at real size, and it needs no research at all.

**§8.2 for Wisconsin, decided here:** `Wis. Stat. § 13.02(1)` convenes the legislature on the first Monday of January *"to take the oath of office"*, and `art. XIII § 1` starts the political year on that same day. Oath and term start fall on one date, so the existing rows serve as `term_start` unchanged. **State this in the migration header, with both citations.** Wisconsin settles the question for Wisconsin and for nowhere else.

**Files:**

- Create: `backend/migrations/CC_XXXX_wi_2026_seat_winners_2027_01_04.sql`

**Interfaces:**

- Consumes: Task 1's CLI; Task 2's migration shape.
- Produces: the first wave covering several `district_type`s under one date — the shape most of the remaining 70 will take.

- [ ] **Step 1: Reserve the slot**

Run: `npm run steward --prefix backend -- slot CC --purpose "seat Wisconsin's 121 2026 winners at 2027-01-04 per Wis. Const. art. XIII §1 and Wis. Stat. §13.02(1)"`

- [ ] **Step 2: Derive the pin**

Run: `node scripts/derive-seating-wave.mjs --state wi --type STATE_LOWER --type STATE_UPPER --type STATE_EXEC --json`
Expected: 121 rows, 90 re-elections, 31 new, term start `2027-01-04`, **every blocker list empty**.
🔴 A non-empty blocker means the body has changed since 2026-11-21. Read it before writing the file; do not route around it.

- [ ] **Step 3: Write the migration**

Task 2's shape. Assertion 3 scoped to `lower(d.state) = 'wi'` and the three state-tier types, expecting 121 — so a Wisconsin seat with no recorded winner cannot have been swept in.

- [ ] **Step 4: Dry run against production**

Run: `node scripts/dry-run-migration.mjs migrations/CC_XXXX_wi_*.sql`
Expected: `DRY RUN OK`, 121 offices seated, rollback confirmed.

- [ ] **Step 5: Control — watch assertion 4 go red**

Inside a rolled-back transaction, close one unrelated current term so the nationwide current-holder map changes, then run the post-verify block.
Expected: `4: the current-holder map changed (... -> ...)`.
This is the assertion that makes a wave safe to apply six weeks early, so it is the one worth watching fail.

- [ ] **Step 6: Apply, and read the gate's output**

Expected: post-verify passes; the notice names 121 seats scheduled for 2027-01-04.

- [ ] **Step 7: Verify the crossover — both views, the baseline, and the live page**

Expected: `office_pending_winner` returns **0** Wisconsin state-tier rows; `office_next_term` returns **121** at 2027-01-04; the `offices_missing_terms` unflagged count is still **238**.
Then read one live API response for a Wisconsin address and confirm the card now reads as a dated handover rather than a declared result. 🔴 **Reasoning about a read path is not measuring it** — ask the endpoint.

- [ ] **Step 8: Commit, and refresh the tracker**

---

### Task 4: Wave 2 — Indiana's three House seats, and the past-dated branch

Districts 46, 60 and 61 — Bob Heaton, Peggy Mayfield and Matt Pierce. All three winners are the sitting member, which is why `CA_0374` left them behind: `seat_officeholder` refuses a re-election unless told otherwise, and that pass wrote only the four handovers. Their body's date is **2026-11-04**, already past, so this is the one wave in the plan that seats people **today** rather than scheduling them — and almost every assertion in Task 2's template points the other way.

**What changes, and why each one matters:**

- The date is in the past, so `office_current_holder` is recomputed from the new rows the moment the file commits. Assertion 4 cannot pin the nationwide map unchanged. Replace it with: the map changes for **exactly these three offices and no others**, and for each of the three the holder is **the same person before and after** — which is true here, because all three are re-elections.
- 🔴 **Each predecessor's term closes at 2026-11-03, election day itself.** `term_end` is inclusive, so each predecessor still covers the day they were elected on and `race_candidates.is_incumbent` stays true. This is exactly the delta `backend/migrations/_templates/office_terms_incumbency_guard.sql` exists for: **paste the guard and state an `@incumbency-decision:` line**, then prove it with `reconcile-incumbency.mjs --check` after the apply.
- `p_allow_reelection` is `true` for all three — still computed per row as everywhere else, and `P1`'s digest covers the flag, so the file and the data cannot disagree about it.
- None of the three is flagged `is_vacant`, so nothing is cleared. Assert that count is 0 rather than assuming it.

**The date needs writing and citing first.** None of the three carries an `office_swearing_in` row today. Read the full `source` string on one of `CA_0374`'s four Indiana terms and take the constitutional citation from it — the visible prefix cites Wikipedia for the *result*, which is not a source for a *date*. 🔴 **Open `Ind. Const. art. 4 § 3` and read what its date is a date of** before writing the row.

**Files:**

- Create: `backend/migrations/CC_XXXX_in_house_2026_swearing_in_dates.sql`
- Create: `backend/migrations/CC_XXXX_in_house_2026_seat_three_reelected.sql`

🔴 **Two files, never one.** `dry-run-migration.mjs` strips only the first `BEGIN`/`COMMIT` pair.

- [ ] **Step 1: Reserve both slots**

- [ ] **Step 2: Read `CA_0374`'s term source in full, and the constitutional provision it names**

Expected: the provision establishes a date that is a **term start** for an Indiana representative, not a ceremony.
🔴 If it turns out to name the oath rather than the term, say so and write the row with the `basis` and authority that reflect what you read. Do not reshape the finding to fit the plan.

- [ ] **Step 3: Write the date migration, following `CC_0445`**

Three rows into `office_swearing_in`: `election_date = 2026-11-03`, `swearing_in_date = 2026-11-04`, `basis = 'statute'`, `authority` = the provision quoted, `source` = where it was read. Post-verify: exactly 3 rows added, all three offices covered, and the nationwide `office_swearing_in` count moved by exactly 3.

- [ ] **Step 4: Dry run the date migration, then apply it**

Expected: `DRY RUN OK`, 3 rows, rollback confirmed; then applied.

- [ ] **Step 5: Derive the pin for the seating**

Run: `node scripts/derive-seating-wave.mjs --state in --type STATE_LOWER --json`
Expected: 3 rows, **3 re-elections, 0 new**, term start `2026-11-04`, blockers empty.

- [ ] **Step 6: Write the seating migration**

Task 2's shape with the four changes above, plus the incumbency guard template.

- [ ] **Step 7: Control — watch the scoped holder assertion go red**

Inside a rolled-back transaction, seat a *different* person into one of the three, then run the post-verify.
Expected: the assertion names the office whose holder changed identity.

- [ ] **Step 8: Dry run, apply, and read the gate's output**

- [ ] **Step 9: Verify the incumbency delta against the real outcome**

Run: `node scripts/reconcile-incumbency.mjs --check`
Expected: **0 drift rows**. 🔴 Measured after the apply, not reasoned before it.

- [ ] **Step 10: Commit each migration with its own pathspec, and refresh the tracker**

---

### Task 5: The register, the recipe, and the two rulings the remaining 70 bodies need

What makes the other 1,160 offices shippable is not more code — it is a worked order and two decisions that would otherwise be taken 70 times, differently. This task writes them down and re-cuts the programme's wave list per §8.5.

**Files:**

- Create: `backend/scripts/lib/state-seating-register.mjs`
- Create: `backend/scripts/build-state-seating-register.mjs`
- Create: `backend/data/state-seating-2026/REGISTER.md`
- Test: `backend/scripts/lib/state-seating-register.test.ts`
- Modify: `backend/data/transition-tracker/waves.csv`

**Interfaces:**

- Consumes: Task 1's `classifyWave`.
- Produces: the register every later wave is claimed and reported against.

- [ ] **Step 1: Write the failing tests for the register builder**

```ts
// One row per (state, district_type). The queue sorts by known start date ascending, then by
// office count descending — so an undated body sinks BELOW a dated one rather than sorting as
// the epoch and jumping the queue it has no deadline for.
it('puts a dated pair before an undated one however large the undated one is', () => { ... });
it('marks a pair done when every office in it already carries a next term', () => { ... });
it('counts a partly-seated pair as queued, with its remainder', () => { ... });
```

- [ ] **Step 2: Run them and watch them fail**

Run: `npx vitest run scripts/lib/state-seating-register.test.ts` from `backend/`
Expected: FAIL.

- [ ] **Step 3: Implement the builder and generate the register**

One row per pair: state, district_type, offices, winners, re-elections, winners without a record, multi-winner offices, flagged-vacant offices, the cited start date or `—`, and the status.
Expected at the time of writing: **73 pairs, 4 done (Wisconsin's three plus Indiana House), 69 queued, 1,160 offices outstanding.**

- [ ] **Step 4: Write the per-wave recipe into `REGISTER.md`**

Nine steps, every one of them something this plan already did once: claim `state:<usps>`; source and cite the date, answering §8.2 for that body in writing; write the date rows following `CC_0445`; create any missing `politicians` rows following `CC_0352` — 🔴 **against the body's own roster, never a name search, because a full-name match is not an identity and this repository has shipped the wrong Mark Harris**; derive the pin; write the seating following Task 2's file; watch one control fail; apply and read the gate; verify both views and one live address; refresh the tracker.

- [ ] **Step 5: Record Ruling A — a multi-member seat is assigned by incumbent anchor, under an interchangeability gate**

🔴 **This is a claim about real people's seats, and it is the one call in this plan a reader should check first.**

71 offices carry more than one winner, because a multi-seat race attaches all its winners to one office row. The display could decline to claim a mapping; a seating cannot — a term row names one person and one office. Measured on Arizona House District 1: the district's two office rows are **both titled `State Representative`, both held, and identical in every column** — nothing distinguishes one from the other except who sits in it. Where that holds, assigning a winner to a sibling office makes no claim a voter could see as wrong, because the seats carry no separate public identity.

So: **a winner who already holds one of the district's sibling offices is seated into that office.** Remaining winners fill remaining sibling offices in name order. And the whole district is **refused**, asserted per district before any write, unless:

- every sibling office in the district shares `chamber_id`, `title`, `seats`, `voting_powers` and `representation_note`; and
- no sibling office carries a `description` that distinguishes it from its siblings; and
- the count of sibling offices is **at least** the number of winners.

**What it costs if wrong:** a Maryland subdistrict delegate shown against the wrong half of their district — a wrong-seat claim about a named person. The gate is what stops that being silent, so the gate is not optional and it runs **per district**, never per wave.

- [ ] **Step 6: Record Ruling B — a wave seats from a `called` result, and records which it was**

1,943 of the 1,945 November winners are `called`, not `certified`, so waiting for certification ships nothing. `CC_0453` already seated 427 House seats from called results and that precedent stands. Each wave therefore records, in its pin block and its header, **how many of its rows were `called` on the day it ran**, and every term's `source` carries the slot — so when a canvass reverses one, the rows are findable by slot and the recorded count says how exposed the wave was.

**What it costs if wrong:** a term written for somebody a recount unseats. Recoverable, because the rows are findable by slot; invisible if the certainty is not recorded, which is why it is.

- [ ] **Step 7: Re-cut `waves.csv` per §8.5**

Replace the single `Wave 4 — State` row (1,326 seats / 1,286 called) with one slice per queued pair, each carrying its office count and its date where one is cited. The bodies this plan shipped are marked done with their slots.
Expected: the file's state-tier seat total still sums to **1,286** — a re-cut that loses seats has lost them from the programme, not from the work.

- [ ] **Step 8: Run the whole backend suite**

Run: `npm test --prefix backend`
Expected: the failing-file list is **identical** to the baseline at this branch's merge-base.
⚠ A worktree has no `.env`, so ~13 integration files skip and the suite looks cleaner than it is — **diff the failing file list, never the count.**

- [ ] **Step 9: Commit, and refresh the tracker artifact to the new wave list**

---

## Self-review

**Spec coverage.** §8.1 shape — the register, Task 5. §8.2 standard for a date — Global Constraints, with a decided per-body line in Tasks 3 and 4 and a required one in the recipe. §8.3 order — the register's sort, and the recipe's claim step. §8.4 gating — every wave gates on its own delta in its own transaction, and the 238 baseline is asserted in Task 3 step 7. §8.5 programme integration — Task 5 steps 7 and 9, plus a tracker refresh closing every wave.

**Gaps left open, deliberately:** the 70 undated bodies, and the 211 missing `politicians` rows, which arrive per wave with the body that needs them. Both are named in Scope, and neither can be specified before its citation exists.

**One task planned and removed.** A `check:swearing-in-sources` CI guard, to refuse an uncited date row — unnecessary: `CC_0344` already carries `office_swearing_in_cited`, a CHECK requiring non-empty `authority` **and** `source`, plus `office_swearing_in_basis_check` closing `basis` to three values and `office_swearing_in_after_election` ordering the dates. The only thing the schema does not enforce is that an `estimated` date must not seat, and that is one line in each wave's `P4`, not a script.

**Proportion.** Five tasks, three of them migrations that copy one existing file. The code blocks here are test assertions and signatures; no migration body is transcribed, because `CC_0453` is the body and it is already written.
