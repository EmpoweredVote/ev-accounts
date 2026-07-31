# MO post-2026-08-04 flip runbook

**Read this before executing plan 164.1-07.**

On or after **2026-08-04** the Missouri Secretary of State's Hoskins certification decision
determines whether Missouri's 2026 congressional map holds or the referendum qualifies for the
ballot. Plan 164.1-07 executes exactly one of the two branches below.

Five districts are affected — geo_ids **2902, 2903, 2904, 2905, 2906** (the severity-routed set,
including the dismantled Cleaver seat MO-5). Two elections are involved:

- `MO 2026 Congressional Redistricting - Polygon Pending` — the **withheld** marker election.
  `electionService.ts`'s `ELECTION_VISIBILITY_WINDOW` never returns it, so a resident of a severe
  MO district correctly sees no House race.
- `MO 2026 Statewide General` — the **surfacing** election. The three non-severe districts
  **2901, 2907, 2908** are already on it.

As of 2026-07-26 these five are the **only** districts withheld anywhere in the 178-district Wave-3
scope. The live withheld census in `backend/scripts/166-pins.generated.sql` reads
`TN 0 / AL 0 / LA 0 / MO 5`.

This runbook is referenced by name from the delimited flip regions in
`backend/scripts/166-verify-invariants.sql` and `backend/scripts/166-coordinate-smoke.ts`, and from
the `≥ 2026-08-04` entry in `STATE.md` Operator Next Steps.

---

## Branch A — map holds

The 2026 map survives certification. MO's `G5200V26` polygons are imported, the D-10 three-layer bar
is run, and a guarded migration re-points the five severe races to `MO 2026 Statewide General`.

**Worked precedent — follow it, do not re-derive.** TN went through this on 2026-07-07 via
migration **1247** (164.1-04-SUMMARY.md); AL-2 and LA-2/LA-6 via migrations **1248** and **1249**
(164.1-05-SUMMARY.md). 164.1-05 also records the in-migration count assertion pattern. Per CLAUDE.md
the migration takes the next free number **from `origin/master`**, is idempotent, ends in a `DO $$`
post-verify gate that `RAISE EXCEPTION`s on a wrong count, and is dry-run first wrapped in
`BEGIN; … ROLLBACK;` with the rollback confirmed to have actually reverted.

Change these artifacts, in this order:

### 1. `backend/scripts/166-verify-invariants.sql`

Inside the region delimited by:

```
  -- === MO POST-2026-08-04 FLIP REGION — see 166-mo-flip-runbook.md ===
  -- === END MO POST-2026-08-04 FLIP REGION ===
```

The **MO-SEVERE** block inverts:

- The withheld geo_id array `('2902','2903','2904','2905','2906')` becomes **empty**, and the
  assertion becomes "**0** MO races remain on `MO 2026 Congressional Redistricting - Polygon
  Pending`".
- The surfacing set becomes **all 8** MO geo_ids **2901 through 2908** on `MO 2026 Statewide
  General`.
- The pass notice is rewritten to the **AL-SURFACING wording** already in the same file, naming the
  un-withholding migration number and its date — exactly as the TN, AL and LA notices name 1247,
  1248 and 1249.
- Rename the block from `MO-SEVERE` to `MO-SURFACING` so it reads like its three siblings, and
  update the block name in the terminal `ALL INHERITED INVARIANTS PASSED` notice.

### 2. `backend/scripts/166-coordinate-smoke.ts`

Inside its matching `-- === MO POST-2026-08-04 FLIP REGION` region:

- Delete the `SEVERE_MO_GEO_ID` negative-sample block and the constant itself.
- Empty `SEVERE_MO_GEO_IDS`, which also drops the `--select` exclusion so MO's previously withheld
  districts become selectable samples.
- Add positive samples for the previously withheld districts. Pick them from a fresh
  `--select` run, not from memory.
- `MIN_DISTRICTS` stays **38** if MO keeps contributing exactly one positive sample. If you add all
  five as separate samples, raise it to **43** — the flip region in the file states this.
- The terminal summary must **stop claiming a severe negative**.

Note: 164.1-04 found that the **1641 smoke auto-proved the post-flip differential when re-run
unedited**, so `backend/scripts/1641-coordinate-smoke.ts` itself needs no edit for the flip. (It is
separately broken today — see the caveat at the end of this runbook.)

### 3. `backend/scripts/162-verify.sql` and `backend/scripts/162-coordinate-smoke.ts`

The per-phase gate flip that **162-11 already flagged as a carry-forward**. Flip these too.

> Flipping 166 without also flipping 162 leaves a stale contradiction on disk: two gates in the same
> repo asserting opposite things about the same five districts.

### 4. `backend/scripts/166-derive-pins.ts`

The withheld census expectation changes from **`MO 5`** to **`MO 0`**, and the expected MO geo_id
list becomes empty.

> Its `CENSUS MISMATCH` guard **will fire on the first post-flip run**. That is the intended
> behaviour — the guard exists precisely so the world cannot change underneath the fragment. The fix
> is to **update the expectation**, never to remove the guard.

After updating, re-run it to regenerate `backend/scripts/166-pins.generated.sql`, then re-paste the
regenerated `_img_skip` / `_stance_skip` / `_stance_queue_167` blocks into
`backend/scripts/166-verify.sql`. The five newly surfacing MO races bring their candidates into the
in-scope universe, so the pin lists will legitimately change.

### 5. Re-run everything

All three Phase-166 artifacts **plus** 162's pair, and confirm green. See
*Verification after either branch* below.

---

## Branch B — referendum qualifies

The referendum makes the ballot. **MO does zero polygon work.** The five districts stay withheld for
this cycle, and the revert diverts to Phase 167's MO cluster.

**No Phase-166 artifact requires any edit.** As written, all three already assert exactly this
steady state:

- `166-verify-invariants.sql` MO-SEVERE asserts 5 withheld / 0 leaked / 3 surfacing — correct.
- `166-coordinate-smoke.ts` asserts the MO-5 coordinate surfaces zero races — correct.
- `166-derive-pins.ts` expects the withheld census `TN 0 / AL 0 / LA 0 / MO 5` — correct.

> **Do not defensively edit.** There is a real temptation, on reaching a decision point, to "update"
> a gate that is already right. Every one of these three is already asserting the branch-B world.
> Touching them can only introduce error. In this branch the correct action on all Phase-166
> artifacts is **nothing**. Re-run them to confirm they are still green, and record that.

---

## Verification after either branch

Run all of these from `/c/EV-Accounts/backend`, in one session, with the environment loaded:

```bash
cd /c/EV-Accounts/backend && set -a && source .env && set +a
```

| # | Command | Must emit |
|---|---|---|
| 1 | `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/166-verify.sql` | twelve `PASS ` lines, then `ALL ASSERTIONS PASSED` and `NATIONAL TOTAL` |
| 2 | `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/166-verify-invariants.sql` | fifteen `PASS ` lines, then `ALL INHERITED INVARIANTS PASSED` |
| 3 | `node --import tsx scripts/166-coordinate-smoke.ts` | Branch A: 38 (or 43) `PASS ` lines and **no** severe-negative line. Branch B: 38 `PASS ` lines **plus** `PASS MO 2905 (severe negative sample):`. Both: `166 COORDINATE SMOKE GREEN` |
| 4 | `npm run check:occupancy --prefix backend` | `Office occupancy OK` |
| 5 | `npm run check:migrations --prefix backend` | exit 0, no number collision |

Branch A additionally requires 162's pair to be green:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/162-verify.sql
node --import tsx scripts/162-coordinate-smoke.ts
```

All commands must exit 0 **in the same session**, so the evidence describes one consistent snapshot
of prod rather than several moments hours apart.

If a gate goes red at this point, **fix the gate, not the expectation**. A red gate here means either
a real regression or a wrong assertion, and both need diagnosis rather than relaxation.

---

## Caveat carried forward from 166-05 — ⚠️ SUPERSEDED, re-tested 2026-07-30

**The caveat below is no longer accurate. Do not act on it.** It said four scripts were broken at
runtime because they reference `essentials.offices.politician_id`, dropped by ADR 0002 phase 5 /
migration 1463, and that **1641 must be repaired before Branch A**. All four were in fact ported on
2026-07-26 (each now carries an `OCCUPANCY PORT (2026-07-26)` note); none still reads the column.
Re-run against prod on 2026-07-30:

| script | result |
|---|---|
| `1641-coordinate-smoke.ts` | ✅ **GREEN** — `1641 COORDINATE SMOKE GREEN: 4 state(s) asserted, 1 skipped (no G5200V26 rows yet)` |
| `1642-coordinate-smoke.ts` | ✅ **GREEN** — 5 states, 0 skipped |
| `154-verify.sql` | ❌ fails `A2a: expected 0 race_candidates on 2026-11-03 Wave-2 House races (none seeded yet), got 326` |
| `160-verify.sql` | ❌ fails `A2b: expected 0 pre-seeded 2026-11-03 races for the other 33 Wave-3 states, got 144` |

🟢 **Branch A is NOT blocked.** Both D-02 reps-feed halves of the 164.1 / 164.2 dual-map proofs are
runnable as evidence right now. The 1641 skip is MO itself — no `G5200V26` rows yet — which is
exactly what Branch A step 1 imports, so that skip should turn into a pass once polygons land.

🔴 **The two SQL gates fail for an unrelated reason: stale PRECONDITIONS, not the dropped column.**
Both are historical per-phase gates asserting "nothing seeded yet" for waves that have since shipped.
That is expected obsolescence. **Do not 'fix' them by relaxing the assertion** — they are pinned to
the world as it stood at their phase, and neither is on the Branch A or Branch B verification list.

Lesson worth keeping: this caveat named a blocker that had already been cleared, and would have cost
a repair cycle on the day of the flip. **Re-test a carried-forward caveat before planning around it.**
