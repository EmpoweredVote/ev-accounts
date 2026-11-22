# Transition Display Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a voter who is arriving in each seat — the dated successor where we have a term, the election result where we only have a winner — on every read path, so the 638 offices that already carry a future-dated term stop being invisible.

**Architecture:** Two new `essentials` views carry the facts the read paths lack: `office_pending_winner` (one row per office, the most recent general or special election it won) and `district_seat_group` (one row per district+chamber, the three counts the group rule needs). Both are joined into the existing shared `DISTRICT_SELECT_FIELDS` / `DISTRICT_JOINS` constants, so the address, coordinate, zip, jurisdiction and local-officials paths inherit them at once. A single new mapper module turns those columns into typed objects, because this field family has already drifted across seven copies once. The frontend decides which of the five display cases a row is in with a pure function, and renders the result into `PoliticianCard`'s existing `footer` slot.

**Tech Stack:** PostgreSQL views (Supabase), TypeScript + Express + `pg`, Vitest (backend); React 18 + Vite + Vitest (Essentials frontend); `@empoweredvote/ev-ui` consumed as a published package and **not modified**.

**Spec:** `docs/superpowers/specs/2026-11-21-transition-display-and-state-seating-design.md`

**Scope:** This plan implements §7 of the spec (the display) only. §8 (the state seating waves) is a separate programme of research and per-state migrations and gets its own plan, as §9 of the spec requires. The display ships first and is useful on its own.

Three parts of the spec are deliberately **not** in this plan because they belong to §8 and would have nothing to run against until a wave exists: §7.5's staleness check (a wave asserts its own convening date was honoured), §11 call 3 (whether a cited oath date may serve as a `term_start`), and §11 call 6 (which is the same check as §7.5). They are listed here so a reader can see they were placed, not missed.

**Repositories:** Tasks 1–4 are in `ev-accounts`, worktree `C:\ev-accounts-transition`, branch `feat/transition-display`. Tasks 5–6 are in the Essentials frontend, `C:\Transparent Motivations\essentials` — a **separate repository with its own branch and PR**.

## Global Constraints

- 🔴 **Never create a table or view in `public`.** Both views go in `essentials`, with `WITH (security_invoker = on)` and explicit `GRANT SELECT ... TO anon, authenticated, service_role, ev_api` in the same migration. `CC_0341_office_next_term_view.sql` is the template to match.
- 🔴 **Migration numbers are allocated, never counted:** `npm run steward --prefix backend -- slot CC --purpose "..."`. This is Cantrell's work, so the namespace is `CC_`.
- 🔴 **One migration per file.** Two `CREATE VIEW` statements inside one `BEGIN; ... COMMIT;` is one migration and is correct here; two `BEGIN`/`COMMIT` pairs in one file is the hazard `dry-run-migration.mjs` cannot see.
- 🔴 **`OFFICE_DEDUP_KEY = 'o.id'` does not change.** Grouping happens at render. Every new join must be one row per office or one row per group, or the address response duplicates seats.
- 🔴 **Count `och.politician_id`, never `count(*)`,** when counting seated people — `office_current_holder` LEFT JOINs from `offices`, so a vacancy is a row with a null `politician_id` and `count(*)` passes vacuously.
- 🔴 **`result_certainty` is on `race_candidates` (`rc`), not on `races`.**
- 🔴 **The election filter is `election_type IN ('general','special')`, never a hard-coded date.**
- 🔴 **Commit with an explicit pathspec:** `git commit -F <msgfile> -- <path>`.
- 🔴 **The production render is shown to the operator before the frontend ships** — the live baseline beside the new card, measured, not eyeballed.
- Exact copy strings are fixed by the spec and are listed verbatim in Task 5. Do not paraphrase them.

**Measured against production on 2026-11-21, with the view predicate this plan specifies** (these supersede the spec's §7.2 counts, which were taken with a draft predicate before `election_type` was settled):

| | count |
|---|---|
| offices the view returns | 1,334 |
| … from the 2026-11-03 general | 1,311 |
| … from an earlier general (2026-05-02 onwards) | 23 |
| winner rows | 1,444 |
| offices where every winner is `certified` | 23 |
| winner rows with no `politicians` record | 237 |
| single-seat groups | 1,119 |
| multi-seat groups | 149 |
| … clean, so the group arrow is allowed | 114 |
| … incomplete | 35 |

Re-measure before quoting; several of these move daily.

## Review Focus

1. **A new join fans out the address response.** `DISTINCT ON (o.id)` hides a duplicate office row but not a duplicate *result set* cost, and a group join keyed wrongly would multiply rows before the DISTINCT. Pinned in Task 3.
2. **A seat that is vacant today and has a pending winner** — `p.*` is all NULL, so there is no "current" person. The card must show the winner alone, never a blank current row. Pinned in Task 5.
3. **A winner with no `politicians` record** (237 rows). The name must render as text and never link to `/politician/null`. Pinned in Task 5.
4. **An office whose most recent general is older than November** (23 offices, back to 2026-05-02). It renders "Won the May 2 election" — true, and overdue. It must render, not be suppressed, and must not claim November. Pinned in Task 2.
5. **A group where the counts disagree, including winners > offices** (a data defect, not an expected input). No arrow, no crash, and the body-level line still renders. Pinned in Task 5.

---

### Task 1: The two views

**Files:**
- Create: `backend/migrations/CC_XXXX_office_pending_winner_views.sql` (number from the allocator in Step 1)

**Interfaces:**
- Consumes: nothing.
- Produces: `essentials.office_pending_winner(office_id uuid, race_id uuid, election_date date, seats int, certainty text, winner_count int, winners jsonb)` and `essentials.district_seat_group(district_id uuid, chamber_id uuid, group_id text, offices int, seated int, winners int)`.

- [ ] **Step 1: Reserve the slot**

Run: `npm run steward --prefix backend -- slot CC --purpose "office_pending_winner + district_seat_group views for the transition display"`
Expected: prints a slot like `CC_0458`. Name the file that number immediately.

- [ ] **Step 2: Write the migration**

One `BEGIN; ... COMMIT;`. Header comment states why, in the house style of `CC_0341_office_next_term_view.sql`, and must say: the view is consulted **only** where `office_next_term` has no row; `election_type IN ('general','special')` so a primary nominee is never shown as an officeholder-elect; `result = 'won'` only, so a Louisiana `'runoff'` row is not a winner; and that the de-duplication is office-rooted.

`essentials.office_pending_winner`, `WITH (security_invoker = on)`:

```sql
WITH latest AS (
  SELECT DISTINCT ON (o.id)
         o.id AS office_id, r.id AS race_id, e.election_date, r.seats
    FROM essentials.offices o
    JOIN essentials.races r      ON r.office_id   = o.id
    JOIN essentials.elections e  ON e.id          = r.election_id
   WHERE e.election_type IN ('general', 'special')
     AND EXISTS (SELECT 1 FROM essentials.race_candidates rc
                  WHERE rc.race_id = r.id AND rc.result = 'won')
     AND NOT EXISTS (SELECT 1 FROM essentials.office_next_term ont
                      WHERE ont.office_id = o.id)
   ORDER BY o.id, e.election_date DESC, r.id
)
SELECT l.office_id, l.race_id, l.election_date, l.seats,
       CASE WHEN bool_and(rc.result_certainty = 'certified') THEN 'certified' ELSE 'called' END AS certainty,
       count(*)::int AS winner_count,
       jsonb_agg(jsonb_build_object('id', rc.politician_id, 'name', rc.full_name)
                 ORDER BY rc.full_name) AS winners
  FROM latest l
  JOIN essentials.race_candidates rc ON rc.race_id = l.race_id AND rc.result = 'won'
 GROUP BY l.office_id, l.race_id, l.election_date, l.seats
```

`essentials.district_seat_group`, `WITH (security_invoker = on)`: group `essentials.offices` by `(district_id, chamber_id)`, LEFT JOIN `office_current_holder` and `office_pending_winner`, and emit `group_id = o.district_id::text || '|' || COALESCE(o.chamber_id::text, '')`, `offices = count(*)`, `seated = count(och.politician_id)`, `winners = COALESCE(sum(w.winner_count), 0)::int`.

- [ ] **Step 3: Grants and comments**

`GRANT SELECT ON essentials.office_pending_winner, essentials.district_seat_group TO anon, authenticated, service_role, ev_api;` and a `COMMENT ON VIEW` for each.

- [ ] **Step 4: Post-verify gate**

A `DO $$ ... $$` block that `RAISE EXCEPTION`s on any of:
- an `office_id` appearing more than once in `office_pending_winner`;
- any row whose `office_id` also appears in `essentials.office_next_term`;
- any row whose `election_date` belongs to an election whose `election_type` is not `general` or `special`;
- any `group_id` appearing more than once in `district_seat_group`;
- `district_seat_group.seated` exceeding `district_seat_group.offices`.

It ends with `RAISE NOTICE` printing the office count, the winner-row count, and the clean-group count.

- [ ] **Step 5: Prove the gate can fail**

Copy the migration to `backend/data/_tamper-CC_XXXX.sql` in the scratchpad, change `ORDER BY o.id, e.election_date DESC, r.id` to `ORDER BY o.id, e.election_date ASC, r.id` and delete the `DISTINCT ON`, then assert the tamper is present before running it:

Run: `grep -c "DISTINCT ON" <tamper file>`
Expected: `0` — a tamper that did not apply is a control that proved nothing.

- [ ] **Step 6: Run the tampered file and watch the gate go red**

Run: `node backend/scripts/dry-run-migration.mjs <tamper file>`
Expected: FAIL, with the duplicate-`office_id` exception from Step 4.

- [ ] **Step 7: Dry-run the real migration**

Run: `node backend/scripts/dry-run-migration.mjs backend/migrations/CC_XXXX_office_pending_winner_views.sql`
Expected: `DRY RUN OK`, and the `RAISE NOTICE` reporting roughly 1,334 offices / 1,444 winner rows / 114 clean groups.

- [ ] **Step 8: Apply to production**

Run: `node backend/scripts/apply-migration-file.mjs backend/migrations/CC_XXXX_office_pending_winner_views.sql`
Expected: the same `NOTICE`, committed. Delete the tamper file.

- [ ] **Step 9: Commit**

```bash
git add backend/migrations/CC_XXXX_office_pending_winner_views.sql
git commit -F <msgfile> -- backend/migrations/CC_XXXX_office_pending_winner_views.sql
```

---

### Task 2: The shared transition mapper

**Files:**
- Create: `backend/src/lib/transitionDisplay.ts`
- Create: `backend/src/lib/transitionDisplay.test.ts`
- Modify: `backend/src/lib/essentialsService.ts` (the `PoliticianFlatRecord` interface only)

**Interfaces:**
- Consumes: the view columns from Task 1, as they arrive on a `pg` row.
- Produces:
  ```ts
  export interface PendingWinnerEntry { id: string | null; name: string; }
  export interface PendingWinner {
    election_date: string;                 // 'YYYY-MM-DD'
    certainty: 'called' | 'certified';
    seats: number;
    winners: PendingWinnerEntry[];
  }
  export interface SeatGroup { group_id: string; offices: number; winners: number; seated: number; }
  export interface TransitionFields {
    incoming_holder_id: string | null;
    incoming_holder_name: string | null;
    incoming_on: string | null;            // 'YYYY-MM-DD'
    pending_winner: PendingWinner | null;
    seat_group: SeatGroup | null;
  }
  export function mapTransitionFields(row: Record<string, unknown>): TransitionFields;
  export const BLANK_TRANSITION_FIELDS: TransitionFields;
  ```
  `PoliticianFlatRecord` gains `pending_winner: PendingWinner | null` and `seat_group: SeatGroup | null`, and its three existing `incoming_*` fields stay exactly as they are.

**Why this module exists:** `essentialsService.ts:682` already records that this field family had "two further copies of this same field", and the three `incoming_*` fields are currently mapped in four places and blanked in three more. Seven call sites with no shared mapper is the drift that produced the contradictory-endpoints failure the spec cites.

- [ ] **Step 1: Write the failing tests**

In `backend/src/lib/transitionDisplay.test.ts`:

```ts
it('returns a dated successor unchanged, with the date trimmed to a day', () => {
  const t = mapTransitionFields({
    incoming_holder_id: 'p1', incoming_holder_name: 'Nithya Raman',
    incoming_on: new Date('2026-12-14T00:00:00Z'),
  });
  expect(t.incoming_on).toBe('2026-12-14');
  expect(t.pending_winner).toBeNull();
});

it('builds a pending winner from the view columns', () => {
  const t = mapTransitionFields({
    pending_election_date: '2026-11-03', pending_certainty: 'called', pending_seats: 1,
    pending_winners: [{ id: 'p2', name: 'Sam Rivera' }],
  });
  expect(t.pending_winner).toEqual({
    election_date: '2026-11-03', certainty: 'called', seats: 1,
    winners: [{ id: 'p2', name: 'Sam Rivera' }],
  });
});

// Review Focus 4: an older general must survive with its own date, not November's.
it('keeps the election date the view gave it, whatever month that is', () => {
  const t = mapTransitionFields({
    pending_election_date: '2026-05-02', pending_certainty: 'certified', pending_seats: 1,
    pending_winners: [{ id: null, name: 'Greg Wims' }],
  });
  expect(t.pending_winner?.election_date).toBe('2026-05-02');
  expect(t.pending_winner?.winners[0].id).toBeNull();
});

it('treats any certainty that is not "certified" as "called"', () => {
  expect(mapTransitionFields({
    pending_election_date: '2026-11-03', pending_certainty: null, pending_seats: 1,
    pending_winners: [{ id: 'p3', name: 'A B' }],
  }).pending_winner?.certainty).toBe('called');
});

it('returns a null pending_winner when the view produced no row', () => {
  expect(mapTransitionFields({}).pending_winner).toBeNull();
  expect(mapTransitionFields({}).seat_group).toBeNull();
});

it('builds the seat group from its four columns', () => {
  const t = mapTransitionFields({ group_id: 'd1|c1', group_offices: 3, group_winners: 3, group_seated: 3 });
  expect(t.seat_group).toEqual({ group_id: 'd1|c1', offices: 3, winners: 3, seated: 3 });
});

it('BLANK_TRANSITION_FIELDS is every field null', () => {
  expect(Object.values(BLANK_TRANSITION_FIELDS).every((v) => v === null)).toBe(true);
});
```

- [ ] **Step 2: Run the tests and watch them fail**

Run: `cd C:\ev-accounts-transition\backend && node --import ./scripts/lib/main-checkout-fallback.mjs ./node_modules/vitest/vitest.mjs run src/lib/transitionDisplay.test.ts`
Expected: FAIL — `Cannot find module './transitionDisplay.js'`.

- [ ] **Step 3: Implement `transitionDisplay.ts`**

`mapTransitionFields` reads only the column names listed in the Interfaces block. Dates are normalised with `String(v).slice(0, 10)`, matching the four existing `incoming_on` mappers. `pending_winners` arrives from `pg` already parsed from `jsonb`; accept a string as well and `JSON.parse` it, because a driver change would otherwise silently blank every card.

- [ ] **Step 4: Run the tests and watch them pass**

Run: the Step 2 command.
Expected: PASS, 7 tests.

- [ ] **Step 5: Add the two fields to `PoliticianFlatRecord`**

In `backend/src/lib/essentialsService.ts`, add `pending_winner: PendingWinner | null;` and `seat_group: SeatGroup | null;` beside the existing `incoming_*` fields, importing the types from `./transitionDisplay.js`.

- [ ] **Step 6: Run the whole backend suite**

Run: `cd C:\ev-accounts-transition\backend && node --import ./scripts/lib/main-checkout-fallback.mjs ./node_modules/vitest/vitest.mjs run`
Expected: compiles; the new required fields make every construction site of `PoliticianFlatRecord` fail to typecheck. That list is Tasks 3 and 4's work — record the failing file list in the ledger before continuing.

- [ ] **Step 7: Commit**

```bash
git commit -F <msgfile> -- backend/src/lib/transitionDisplay.ts backend/src/lib/transitionDisplay.test.ts backend/src/lib/essentialsService.ts
```

---

### Task 3: The shared district query

**Files:**
- Modify: `backend/src/lib/districtQueries.ts` (`DISTRICT_SELECT_FIELDS`, `DISTRICT_JOINS`)
- Modify: `backend/src/lib/districtQueries.test.ts`
- Modify: `backend/src/lib/essentialsService.ts` (the four `PoliticianFlatRecord` construction sites at the mappers near lines 515, 685, 2036 and 2148)

**Interfaces:**
- Consumes: Task 1's views; Task 2's `mapTransitionFields`.
- Produces: eight new columns on every row the shared constants return — `pending_election_date`, `pending_certainty`, `pending_seats`, `pending_winners`, `group_id`, `group_offices`, `group_winners`, `group_seated`.

This one change reaches the address lookup, the coordinate lookup, the ZIP path (`zipQueries.ts`), `getRepresentativesByJurisdiction` and `getLocalOfficialsByUserId`, because all of them build on these two constants.

- [ ] **Step 1: Write the failing tests**

In `backend/src/lib/districtQueries.test.ts`, following the file's existing `toContain` style:

```ts
it('selects the pending-winner columns on both builders', () => {
  for (const sql of [buildDistrictQuery(base), buildStatewideQuery()]) {
    expect(sql).toContain('opw.election_date AS pending_election_date');
    expect(sql).toContain('opw.winners AS pending_winners');
    expect(sql).toContain('dsg.group_id');
  }
});

// 🔴 An inner join here would empty every address result: almost no office has a pending winner.
it('joins both new views as LEFT JOINs', () => {
  const sql = buildDistrictQuery(base);
  expect(sql).toContain('LEFT JOIN essentials.office_pending_winner opw ON opw.office_id = o.id');
  expect(sql).toMatch(/LEFT JOIN essentials\.district_seat_group dsg/);
});

// Review Focus 1: the group join must match on a null chamber_id too, or every seat whose
// chamber is null silently loses its group and the multi-seat cases vanish.
it('matches the seat group on a null chamber_id', () => {
  expect(buildDistrictQuery(base)).toContain('dsg.chamber_id IS NOT DISTINCT FROM o.chamber_id');
});

it('still de-duplicates on the office', () => {
  expect(buildDistrictQuery(base)).toContain('DISTINCT ON (o.id)');
  expect(buildDistrictQuery(base)).toContain('ORDER BY o.id');
});
```

- [ ] **Step 2: Run the tests and watch them fail**

Run: `cd C:\ev-accounts-transition\backend && node --import ./scripts/lib/main-checkout-fallback.mjs ./node_modules/vitest/vitest.mjs run src/lib/districtQueries.test.ts`
Expected: FAIL on each new assertion.

- [ ] **Step 3: Add the joins and the columns**

In `DISTRICT_JOINS`, beside the existing `office_next_term` join and carrying a comment in the same voice: both are LEFT JOINs and must stay so; `office_pending_winner` is one row per office and `district_seat_group` is one row per group, so neither can fan the result set out. In `DISTRICT_SELECT_FIELDS`, add the eight columns beside the three `incoming_*` ones.

- [ ] **Step 4: Run the tests and watch them pass**

Run: the Step 2 command.
Expected: PASS.

- [ ] **Step 5: Wire the four mappers**

Replace the hand-written `incoming_holder_id` / `incoming_holder_name` / `incoming_on` triples at the four construction sites in `essentialsService.ts` with `...mapTransitionFields(row)`.

- [ ] **Step 6: Prove the join does not fan out, against production**

Run this against prod and read the count, not the rows:

```sql
SELECT count(*) AS offices_returning_more_than_one_group
  FROM essentials.offices o
  JOIN essentials.district_seat_group dsg
    ON dsg.district_id = o.district_id
   AND dsg.chamber_id IS NOT DISTINCT FROM o.chamber_id
 GROUP BY o.id HAVING count(*) > 1;
```
Expected: zero rows. A non-empty result means the group key is wrong and every address response would multiply.

- [ ] **Step 7: Run the whole backend suite**

Run: `cd C:\ev-accounts-transition\backend && node --import ./scripts/lib/main-checkout-fallback.mjs ./node_modules/vitest/vitest.mjs run`
Expected: the four mapper sites now compile. Compare the failing-file list against the one recorded in Task 2 Step 6; only the browse-service sites should remain.

- [ ] **Step 8: Commit**

```bash
git commit -F <msgfile> -- backend/src/lib/districtQueries.ts backend/src/lib/districtQueries.test.ts backend/src/lib/essentialsService.ts
```

---

### Task 4: `/politicians`, the browse paths, and the profile page

**Files:**
- Modify: `backend/src/lib/essentialsService.ts` (`getPoliticiansFlatList` SQL near line 420; `getPoliticianById` near line 1402; `PoliticianDetail` near line 1261)
- Modify: `backend/src/lib/essentialsBrowseService.ts` (the three blanked sites at the mappers near lines 554, 876 and 971)
- Modify: `backend/src/lib/essentialsService.test.ts`

**Interfaces:**
- Consumes: Task 1's views; Task 2's `mapTransitionFields` and `BLANK_TRANSITION_FIELDS`.
- Produces: `PoliticianDetail` gains `arriving_office_title: string | null`, `arriving_on: string | null`.

Two different facts live here and must not be confused. On a **flat list** row the question is *who is arriving in this seat*. On a **profile** the question is *what seat is this person arriving into* — the opposite join direction, which fans out, so it needs the `DISTINCT ON`/`LIMIT 1` treatment `getPoliticianById` already applies to `office_current_holder`.

- [ ] **Step 1: Write the failing tests**

In `backend/src/lib/essentialsService.test.ts`, inside the existing `describe('getPoliticiansFlatList incoming holder')` block, which already has an `async function sqlFor(includeCandidates: boolean): Promise<string>` helper that mocks `pool.query` and returns `String(query.mock.calls[0][0])`. Reuse it:

```ts
it('selects the pending-winner and seat-group columns', async () => {
  const sql = await sqlFor(false);
  expect(sql).toContain('essentials.office_pending_winner');
  expect(sql).toContain('pending_election_date');
  expect(sql).toContain('pending_winners');
});
```

Then a new `describe('getPoliticianById arriving seat')` with its own copy of that helper, calling `getPoliticianById('any-id')` instead:

```ts
// 🔴 136 people in office_next_term hold no current seat, so office_current_holder resolves
// nothing for them and their profile reads as though they are nobody.
it('resolves the seat a person is arriving into', async () => {
  const sql = await sqlForDetail();
  expect(sql).toContain('essentials.office_next_term');
  expect(sql).toContain('AS arriving_office_title');
  expect(sql).toContain('AS arriving_on');
});

// 🔴 A politician-rooted join can fan out: a person may hold two future terms.
it('takes exactly one arriving seat per person', async () => {
  expect(await sqlForDetail()).toMatch(/arriving[\s\S]*LIMIT 1/);
});
```

- [ ] **Step 2: Run the tests and watch them fail**

Run: `cd C:\ev-accounts-transition\backend && node --import ./scripts/lib/main-checkout-fallback.mjs ./node_modules/vitest/vitest.mjs run src/lib/essentialsService.test.ts`
Expected: FAIL on the three new assertions.

- [ ] **Step 3: Add the columns to `getPoliticiansFlatList`**

The `office_pending_winner` LEFT JOIN and its four `pending_*` columns, in that query's own inline SQL, and `...mapTransitionFields(row)` at its mapper. ⚠ **No `district_seat_group` join here.** This query is `DISTINCT ON (p.id)` — person-rooted, like the browse paths — and spec §7.3 gives the group block only to the office-rooted reads. `seat_group` stays null, and the frontend's group cases are reached from the address paths alone.

- [ ] **Step 4: Add the arriving seat to `getPoliticianById`**

A `LEFT JOIN LATERAL` over `essentials.office_next_term ont JOIN essentials.offices ao ON ao.id = ont.office_id` on `ont.politician_id = p.id`, `ORDER BY ont.term_start ASC LIMIT 1`, selecting `ao.title AS arriving_office_title` and `ont.term_start AS arriving_on`. Add both to `PoliticianDetail` and to its mapper.

- [ ] **Step 5: Source the three browse sites**

`getPoliticiansByArea`, `getPoliticiansByGovernmentList` and `mapBrowseRow` are **person-rooted** and inner-join `office_current_holder`, so they return only seats that have a holder. Add the `office_pending_winner` LEFT JOIN and the four `pending_*` columns to each of the three queries and replace the hard-coded nulls with `...mapTransitionFields(row)`. Per spec §7.3 these paths get the per-person fields only: **do not** join `district_seat_group` here, and let `seat_group` stay null. Replace each `🔴 NOT SOURCED ON THIS PATH YET` comment with one sentence saying the group block is deliberately absent on a person-rooted read and why.

- [ ] **Step 6: Run the tests and watch them pass**

Run: the Step 2 command, then the whole suite:
`cd C:\ev-accounts-transition\backend && node --import ./scripts/lib/main-checkout-fallback.mjs ./node_modules/vitest/vitest.mjs run`
Expected: PASS. The failing-file list must now match the pre-existing baseline recorded at Task 2 Step 6 with nothing added.

- [ ] **Step 7: Measure the live endpoint, do not reason about it**

Boot the API against production and `POST /api/essentials/coordinate-lookup` with Los Angeles City Hall. Read the response for the five seats in spec §1.

Expected: `Mayor, Los Angeles` carries `incoming_holder_name: "Nithya Raman"` and `incoming_on: "2026-12-14"`; at least one returned seat carries a non-null `pending_winner`; no seat appears twice.

- [ ] **Step 8: Commit**

```bash
git commit -F <msgfile> -- backend/src/lib/essentialsService.ts backend/src/lib/essentialsBrowseService.ts backend/src/lib/essentialsService.test.ts
```

---

### Task 5: The display model (Essentials frontend)

**Files:**
- Create: `src/lib/seatTransition.js` (repo `C:\Transparent Motivations\essentials`, new branch off `main`)
- Create: `src/lib/seatTransition.test.js`

**Interfaces:**
- Consumes: the API fields from Tasks 2–4: `incoming_holder_id`, `incoming_holder_name`, `incoming_on`, `pending_winner`, `seat_group`, plus `id` and `seat_status`.
- Produces:
  ```js
  export const CASES = {
    DATED_HANDOVER: 'dated_handover',   DATED_REELECTION: 'dated_reelection',
    RESULT_HANDOVER: 'result_handover', RESULT_REELECTION: 'result_reelection',
    RESULT_GROUP: 'result_group',       RESULT_PARTIAL: 'result_partial',
    NONE: 'none',
  };
  export function formatElectionDay(iso);   // '2026-11-03' -> 'November 3'
  export function formatTermStart(iso);     // '2026-12-14' -> 'December 14, 2026'
  export function buildSeatTransition(pol); // -> { case, lines: string[], people: [{id, name}] }
  export function buildGroupTransition(rows); // sibling rows of one group_id -> same shape
  ```

This file is **pure logic, no JSX and no DOM**, matching `src/components/SectionBanner.test.js` and `src/lib/groupHierarchy.test.js`. The component in Task 6 renders what these functions return and decides nothing.

**The copy, fixed by the spec. Use these strings exactly:**

| case | lines |
|---|---|
| `DATED_HANDOVER` | `Takes office ${formatTermStart(incoming_on)}` |
| `DATED_REELECTION` | `Re-elected — next term begins ${formatTermStart(incoming_on)}` |
| `RESULT_HANDOVER`, certified | `Won the ${formatElectionDay(d)} election:` then the winner's name |
| `RESULT_HANDOVER`, called | `Declared winner, ${formatElectionDay(d)}:`, the name, then `Count not yet certified` |
| `RESULT_REELECTION`, certified | `Re-elected ${formatElectionDay(d)} — date of the new term not yet confirmed` |
| `RESULT_REELECTION`, called | `Declared re-elected ${formatElectionDay(d)} — date of the new term not yet confirmed` |
| `RESULT_GROUP`, certified | `Won the ${formatElectionDay(d)} election` |
| `RESULT_GROUP`, called | `Declared winners, ${formatElectionDay(d)} — count not yet certified` |
| `RESULT_PARTIAL` | `${n} seats elected ${formatElectionDay(d)}:` then the names |

- [ ] **Step 1: Write the failing tests**

```js
it('an incoming person who is not the current holder is a dated handover', () => {
  const t = buildSeatTransition({ id: 'a', incoming_holder_id: 'b', incoming_holder_name: 'Nithya Raman', incoming_on: '2026-12-14' });
  expect(t.case).toBe(CASES.DATED_HANDOVER);
  expect(t.lines).toEqual(['Takes office December 14, 2026']);
});

// 🔴 An arrow from someone to themselves reads as a bug. 451 of the 638 dated seats are this.
it('an incoming person who IS the current holder is a re-election, with no second person', () => {
  const t = buildSeatTransition({ id: 'a', incoming_holder_id: 'a', incoming_holder_name: 'Jane Doe', incoming_on: '2027-01-03' });
  expect(t.case).toBe(CASES.DATED_REELECTION);
  expect(t.people).toEqual([]);
  expect(t.lines).toEqual(['Re-elected — next term begins January 3, 2027']);
});

it('a called single-seat result hedges, and a certified one does not', () => {
  const base = { id: 'a', seat_group: { group_id: 'g', offices: 1, winners: 1, seated: 1 },
                 pending_winner: { election_date: '2026-11-03', seats: 1, winners: [{ id: 'b', name: 'Sam Rivera' }] } };
  expect(buildSeatTransition({ ...base, pending_winner: { ...base.pending_winner, certainty: 'certified' } }).lines)
    .toEqual(['Won the November 3 election:', 'Sam Rivera']);
  expect(buildSeatTransition({ ...base, pending_winner: { ...base.pending_winner, certainty: 'called' } }).lines)
    .toEqual(['Declared winner, November 3:', 'Sam Rivera', 'Count not yet certified']);
});

// 914 of 1,419 result-only seats are this. It must not read "Jane Doe ... winner: Jane Doe".
it('a single-seat result won by the sitting holder is a re-election', () => {
  const t = buildSeatTransition({ id: 'a', seat_group: { group_id: 'g', offices: 1, winners: 1, seated: 1 },
    pending_winner: { election_date: '2026-11-03', certainty: 'called', seats: 1, winners: [{ id: 'a', name: 'Jane Doe' }] } });
  expect(t.case).toBe(CASES.RESULT_REELECTION);
  expect(t.people).toEqual([]);
  expect(t.lines).toEqual(['Declared re-elected November 3 — date of the new term not yet confirmed']);
});

// Review Focus 2: a vacant seat has no current person at all.
it('a vacant seat with a pending winner names the winner and claims no current holder', () => {
  const t = buildSeatTransition({ id: null, seat_status: 'vacant',
    seat_group: { group_id: 'g', offices: 1, winners: 1, seated: 0 },
    pending_winner: { election_date: '2026-11-03', certainty: 'called', seats: 1, winners: [{ id: 'b', name: 'Sam Rivera' }] } });
  expect(t.case).toBe(CASES.RESULT_HANDOVER);
  expect(t.people).toEqual([{ id: 'b', name: 'Sam Rivera' }]);
});

// Review Focus 3: 237 winner rows have no politician record.
it('keeps a winner with no record, with a null id', () => {
  const t = buildSeatTransition({ id: 'a', seat_group: { group_id: 'g', offices: 1, winners: 1, seated: 1 },
    pending_winner: { election_date: '2026-11-03', certainty: 'called', seats: 1, winners: [{ id: null, name: 'Greg Wims' }] } });
  expect(t.people).toEqual([{ id: null, name: 'Greg Wims' }]);
});

// Review Focus 4
it('names the month the election was actually held in', () => {
  expect(formatElectionDay('2026-05-02')).toBe('May 2');
});

it('draws the group arrow only when offices, winners and seated all agree', () => {
  const rows = [
    { id: 'a', seat_group: { group_id: 'g', offices: 3, winners: 3, seated: 3 },
      pending_winner: { election_date: '2026-11-03', certainty: 'certified', seats: 3,
        winners: [{ id: 'x', name: 'Moreno' }, { id: 'y', name: 'Guzzone' }, { id: 'z', name: 'Brooks' }] } },
    { id: 'b', seat_group: { group_id: 'g', offices: 3, winners: 3, seated: 3 }, pending_winner: null },
    { id: 'c', seat_group: { group_id: 'g', offices: 3, winners: 3, seated: 3 }, pending_winner: null },
  ];
  const t = buildGroupTransition(rows);
  expect(t.case).toBe(CASES.RESULT_GROUP);
  expect(t.people).toHaveLength(3);
  expect(t.lines).toEqual(['Won the November 3 election']);
});

// 🔴 A staggered body: five members, three seats up. An arrow would imply the body is shrinking.
it('falls back to the body-level line when the counts disagree', () => {
  const rows = [{ id: 'a', seat_group: { group_id: 'g', offices: 5, winners: 3, seated: 5 },
    pending_winner: { election_date: '2026-11-03', certainty: 'certified', seats: 3,
      winners: [{ id: 'x', name: 'Greg Wims' }, { id: 'y', name: 'Lesley J. Lopez' }, { id: null, name: 'A Third' }] } }];
  const t = buildGroupTransition(rows);
  expect(t.case).toBe(CASES.RESULT_PARTIAL);
  expect(t.lines[0]).toBe('3 seats elected November 3:');
});

// Review Focus 5: a data defect must degrade, not throw.
it('refuses the arrow and does not throw when winners exceed offices', () => {
  const rows = [{ id: 'a', seat_group: { group_id: 'g', offices: 2, winners: 3, seated: 2 },
    pending_winner: { election_date: '2026-11-03', certainty: 'called', seats: 2,
      winners: [{ id: 'x', name: 'A' }, { id: 'y', name: 'B' }, { id: 'z', name: 'C' }] } }];
  expect(buildGroupTransition(rows).case).toBe(CASES.RESULT_PARTIAL);
});

it('returns NONE for a seat with neither a term nor a result', () => {
  expect(buildSeatTransition({ id: 'a' }).case).toBe(CASES.NONE);
});
```

- [ ] **Step 2: Run the tests and watch them fail**

Run: `cd "C:\Transparent Motivations\essentials" && npx vitest run src/lib/seatTransition.test.js`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement `seatTransition.js`**

`buildSeatTransition` decides in this order: a dated term wins over a result; within each, the winner being the sitting holder (`winners[0].id === pol.id`) is the re-election case; a result is a single-seat case only when `seat_group.offices === 1`. `buildGroupTransition` takes rows sharing one `group_id`, unions their `pending_winner.winners`, and allows `RESULT_GROUP` only when `offices === winners && offices === seated`. The date formatters use `Intl.DateTimeFormat('en-US', { timeZone: 'UTC' })` — a local-timezone parse moves `2026-11-03` to November 2 for anyone west of UTC.

- [ ] **Step 4: Run the tests and watch them pass**

Run: the Step 2 command.
Expected: PASS, 12 tests.

- [ ] **Step 5: Commit**

```bash
git commit -F <msgfile> -- src/lib/seatTransition.js src/lib/seatTransition.test.js
```

---

### Task 6: The card (Essentials frontend)

**Files:**
- Create: `src/components/SeatTransition.jsx`
- Create: `src/components/SeatTransition.test.js`
- Modify: `src/pages/Results.jsx` (`renderPoliticianCard`, near line 1547)

**Interfaces:**
- Consumes: Task 5's `buildSeatTransition`, `buildGroupTransition`, `CASES`.
- Produces: `export default function SeatTransition({ model })`, rendered into `PoliticianCard`'s existing `footer` prop.

🔴 **`PoliticianCard` comes from the published `@empoweredvote/ev-ui` package and is not modified by this plan.** The local `src/components/PoliticianCard.jsx` is dead code that nothing imports — do not edit it. The `footer` prop already accepts any React node and is already used for `IconOverlay`, so the transition block composes beside it.

- [ ] **Step 1: Write the failing tests**

Pure-logic and source-text assertions only, matching `SectionBanner.test.js`:

```js
// 🔴 237 winners have no politician record; /politician/null is a dead page.
it('never links a person whose id is null', () => {
  const SRC = readFileSync(new URL('./SeatTransition.jsx', import.meta.url), 'utf8');
  expect(SRC).toMatch(/person\.id\s*\?/);
  expect(SRC).not.toMatch(/\/politician\/\$\{[^}]*\}`\s*}\s*>\s*\{person\.name/);
});

it('renders no arrow for either re-election case', () => {
  expect(ARROW_CASES).not.toContain(CASES.DATED_REELECTION);
  expect(ARROW_CASES).not.toContain(CASES.RESULT_REELECTION);
  expect(ARROW_CASES).not.toContain(CASES.RESULT_PARTIAL);
  expect(ARROW_CASES).toEqual(expect.arrayContaining([CASES.DATED_HANDOVER, CASES.RESULT_GROUP]));
});

it('renders nothing at all for CASES.NONE', () => {
  expect(shouldRender({ case: CASES.NONE })).toBe(false);
});
```

`ARROW_CASES` and `shouldRender` are named exports of `SeatTransition.jsx`, exported for exactly this reason.

- [ ] **Step 2: Run the tests and watch them fail**

Run: `cd "C:\Transparent Motivations\essentials" && npx vitest run src/components/SeatTransition.test.js`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement `SeatTransition.jsx`**

Renders `model.lines` as text and `model.people` as avatars with names, with a downward arrow between the current block and the incoming block only for the cases in `ARROW_CASES`. A person with a null `id` renders as plain text. At phone width the group block wraps rather than scrolling horizontally.

- [ ] **Step 4: Run the tests and watch them pass**

Run: the Step 2 command.
Expected: PASS.

- [ ] **Step 5: Wire it into `Results.jsx`**

In `renderPoliticianCard`, build the model and pass it in the existing `footer`:
`footer={<><SeatTransition model={model} /><IconOverlay ballot={ballot} hasStances={hasStances} branch={branch} /></>}`.
Group rows by `pol.seat_group?.group_id` before rendering so a multi-seat body's siblings are one card; keep the existing per-office keys. **Do not touch `OFFICE_DEDUP_KEY` or any backend de-duplication** — the grouping is a render-time concern only.

- [ ] **Step 6: Run the frontend suite**

Run: `cd "C:\Transparent Motivations\essentials" && npm test`
Expected: PASS, with no new failures against the pre-existing baseline.

- [ ] **Step 7: Show the operator the production render**

Build and serve the frontend against the production API, then screenshot, at both desktop and phone width:
- Los Angeles City Hall — case (a), the Mayor handover, dated 2026-12-14;
- a seat whose incoming person is the sitting holder — case (a) re-election, no arrow;
- a single-seat state-legislative result — case (b), called;
- a re-elected single-seat result — case (b-ii);
- a clean multi-seat body — case (c);
- an incomplete multi-seat body — case (d).

Put the current live render beside each. 🔴 Measure; do not eyeball. This is the gate before the frontend PR, not a courtesy.

- [ ] **Step 8: Commit**

```bash
git commit -F <msgfile> -- src/components/SeatTransition.jsx src/components/SeatTransition.test.js src/pages/Results.jsx
```

---

## Notes for the executor

- **The backend worktree needs its own `node_modules`.** A linked worktree has no `.env` either, so run the suite through the fallback shim exactly as the commands above do, or ~13 integration files die at load and the suite looks *cleaner* than it is. The real pre-existing count at a recent master was **33 failing tests across 13 files**, not 6. Diff the failing **file list** against your base commit, never the count.
- 🔴 **Do not plant a `node_modules` junction** in the worktree. `git worktree remove` deletes straight through one and has emptied the main checkout twice.
- The two repositories get two PRs. The backend PR can merge and deploy first: it only adds fields, and the frontend ignores fields it does not read.
