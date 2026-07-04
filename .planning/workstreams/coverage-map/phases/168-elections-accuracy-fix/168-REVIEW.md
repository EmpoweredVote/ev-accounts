---
phase: 168-elections-accuracy-fix
reviewed: 2026-07-04T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - backend/src/lib/electionsMap.ts
  - backend/src/lib/electionsMap.test.ts
  - backend/src/lib/electionsMapService.ts
  - backend/src/routes/admin.test.ts
  - admin/src/pages/admin/coverageTypes.ts
  - admin/src/pages/admin/StatewideRacesPanel.tsx
  - admin/src/pages/admin/CoveragePage.tsx
  - admin/src/pages/admin/CoverageMap.tsx
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 168: Code Review Report

**Reviewed:** 2026-07-04
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the elections-accuracy-fix ("Michigan bug") partition work across backend
(`classifyRaces` helper, `getElectionsStateScores` rewrite, route test) and frontend
(`StatewideRacesPanel`, `CoverageMap`/`CoveragePage`/`coverageTypes` changes).

The core partition logic is sound and well-tested: `classifyRaces` reuses the single
`resolveRaceCountyFips` classifier so the state split and county drill-down cannot drift,
and the county-side N/A-vs-0% distinction (`countyCoverage.status`) is correctly plumbed
end to end. The backend/frontend `StateElection` contracts match field-for-field. SQL is
fully parameterized; no injection, secrets, or unsafe patterns found.

Two Warnings: (1) the N/A-vs-0% distinction — the entire premise of this phase — is
**only** applied on the county color axis, not on the state fill, so a state with a real
statewide 0% still paints identical to a state with no election data (the same class of
bug this phase set out to fix, on the state axis); (2) a stale-selection window where the
new panel silently renders empty. The Info items cover a duplicated numerator computation,
a tautological consistency test, and minor display/semantics nits.

Note: the two documented deferred items (depth-aware indicator; missing seeded statewide
offices) are out of scope per the review brief and are not flagged.

## Warnings

### WR-01: State choropleth does not distinguish a real 0% statewide coverage from "no data"

**File:** `admin/src/pages/admin/CoverageMap.tsx:37` (and `31-36`)
**Issue:** The county color path was explicitly hardened for this phase's N/A-vs-0%
distinction — `electionCountyColor` (lines 38-42) maps a real 0% (`status === 'scored'`,
`coverage === 0`) to `scoreColor(0.01)` so it does not collapse into `NOT_STARTED`, and
maps `status === 'unknown'` to a separate `NO_RACE_DATA` gray. The **state** fill did not
receive the same treatment:

```ts
function electionStateColor(s: StateElection | undefined): string { return s ? scoreColor(s.coverage) : NOT_STARTED; }
```

`scoreColor` returns `NOT_STARTED` for any `score <= 0` (line 32). A state that *has*
upcoming statewide/legislative races but none with a candidate yet produces
`coverage: 0` (a genuine, scored 0% — `raceCoverage(statewide)` returns `0` when
`statewide.length > 0` but zero races are covered). That state is painted the exact same
`NOT_STARTED` gray as a state with no election at all (`es === undefined`). This is the
same "0% looks like nothing" ambiguity the phase fixed on the county axis, left unfixed on
the state axis. The hover readout distinguishes them ("0%" vs "no upcoming election"), but
the choropleth fill — the primary at-a-glance signal — does not.
**Fix:** Mirror the county treatment on the state axis — nudge a genuine scored-0% off the
`NOT_STARTED` sentinel, and keep true "no election" as the sentinel:
```ts
function electionStateColor(s: StateElection | undefined): string {
  if (!s) return NOT_STARTED;                     // no upcoming election → truly absent
  return scoreColor(s.coverage <= 0 ? 0.01 : s.coverage); // scored 0% stays visible, distinct from absent
}
```
(If distinguishing "scored but 0" from "no races at that date" also matters on the state
axis, consider surfacing a statewide `status` on `StateElection` mirroring `countyCoverage`,
since a state whose nearest election has zero statewide/legislative races currently also
reports `coverage: 0`.)

### WR-02: StatewideRacesPanel renders empty during the elections lazy-fetch window after a completeness-mode selection

**File:** `admin/src/pages/admin/CoveragePage.tsx:173-175` (with `42-49`)
**Issue:** The panel reads `elecStatesByFips.get(selected.fips) ?? null`. `elecStates` is
lazily fetched only the first time elections mode is toggled on (lines 42-49). If a user
selects a state while in completeness mode and then flips to elections, the panel mounts
(`metric === 'elections' && selected` is true) before the elections state fetch resolves,
so `elecStatesByFips` is empty, `get()` returns `undefined`, and `StatewideRacesPanel`
receives `null` → returns `null` (renders nothing). The map area shows its own loading
spinner, but the panel region silently shows no content and no loading affordance for that
transient window. Once the fetch resolves the panel does not re-mount to reflect the newly
available data unless a re-render is triggered by other state (it will re-render because
`elecStates` set triggers it — so it self-heals — but during the in-flight window the user
sees an unexplained blank).
**Fix:** Gate the panel on data readiness, or pass a loading state so the panel can show a
placeholder consistent with the map spinner:
```tsx
{metric === 'elections' && selected && (
  statesLoading
    ? <div className="rounded-lg bg-white p-4 text-sm text-gray-400 shadow dark:bg-gray-900">Loading races…</div>
    : <StatewideRacesPanel stateElection={elecStatesByFips.get(selected.fips) ?? null} />
)}
```

## Info

### IN-01: "covered" numerator computed twice by parallel code paths that must stay in sync

**File:** `backend/src/lib/electionsMapService.ts:140-149`
**Issue:** `stateCovered`/`countyCovered` re-implement the exact `candidate_count > 0`
filter that `raceCoverage` already computes internally (`electionsMap.ts:33`). The service
then calls `raceCoverage(statewide)` for the percentage and separately reports
`races_covered: stateCovered`. The numerator is derived twice by two independent passes; if
the "covered" definition ever changes in one place, the percentage and the count can silently
diverge.
**Fix:** Expose the covered count once (e.g. return `{ coverage, covered, total }` from a
single helper, or compute `stateCovered` and derive coverage from it) so a single definition
of "covered" feeds both the percentage and the count.

### IN-02: ELEC-03 consistency test is tautological (asserts hardcoded 2 === 2)

**File:** `backend/src/routes/admin.test.ts:105-126`
**Issue:** The assertion `mi.countyCoverage.races_total === countyDrilldownTotal` compares
`stateElection.countyCoverage.races_total` (hardcoded `2`, line 64) against the sum of
`countyPayload.counties[*].races.length` (also `2` by fixture construction, lines 73-76).
Both sides are fixed constants the author wrote; the test cannot fail on a real partition
regression because the route forwards mocks verbatim and the partition logic is mocked out
entirely. The summary acknowledges this ("by construction"), but as written the test proves
route forwarding, not denominator consistency. The value is real (catches route glue that
drops/duplicates data) but the ELEC-03 *contract* it claims to encode is not exercised.
**Fix:** Consider driving the fixture through the real `classifyRaces`/`raceCoverage`
helpers (which are already unit-tested and pure) so the state and county totals are *derived*
from one race set rather than both hand-authored, or rename the test to reflect that it
asserts route forwarding rather than partition consistency.

### IN-03: Candidate cell shows `candidate_count/seats` which can read as a fraction >100%

**File:** `admin/src/pages/admin/StatewideRacesPanel.tsx:54`
**Issue:** `{r.candidate_count}/{r.seats} candidates` renders e.g. "5/1 candidates" for a
5-candidate single-seat race. Read as "covered/total" (the convention used everywhere else
in this map for coverage), this looks like an over-100% ratio; it is actually
candidates-per-seat. Ambiguous next to the surrounding coverage percentages.
**Fix:** Label it unambiguously, e.g. `{r.candidate_count} candidates · {r.seats} seat(s)`,
or drop the seats denominator if seats is not the intended comparison.

### IN-04: `pathRef`/`projRef` typed as `any`

**File:** `admin/src/pages/admin/CoverageMap.tsx:65-68`
**Issue:** Two refs are `any` (with eslint-disable). Pre-existing pattern in this file
(unchanged by this phase), noted only for completeness — the react-simple-maps `path`
(a d3 geo path) and `projection` have real types that would catch a misuse of
`path.bounds`/`proj.invert` (used at lines 105-110). Not introduced by this phase; low
priority.
**Fix:** Type as `d3.GeoPath` / `d3.GeoProjection` from `d3-geo` if convenient; otherwise
leave as-is (out of phase scope).

---

_Reviewed: 2026-07-04_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
