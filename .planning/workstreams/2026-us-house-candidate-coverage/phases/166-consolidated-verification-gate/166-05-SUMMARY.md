---
phase: 166-consolidated-verification-gate
plan: 05
subsystem: infra
tags: [verification, runbook, roadmap, state, ci-guards, closeout]

requires:
  - phase: 166-02
    provides: the coordinate smoke and its MO flip region
  - phase: 166-03
    provides: the structural gate
  - phase: 166-04
    provides: the invariants gate and its MO flip region
provides:
  - "166-mo-flip-runbook.md — the branch-by-branch post-2026-08-04 MO edit list"
  - "The combined three-artifact green run: the evidence USHC3-06 is closed"
  - "ROADMAP/STATE/REQUIREMENTS closure with the 164.1-07 forward pointer"
affects: [164.1-07, 167, 159-06]

tech-stack:
  added: []
  patterns:
    - "Date-gated future work gets a named runbook reachable by three independent routes"

key-files:
  created:
    - .planning/workstreams/2026-us-house-candidate-coverage/phases/166-consolidated-verification-gate/166-mo-flip-runbook.md
  modified:
    - .planning/workstreams/2026-us-house-candidate-coverage/ROADMAP.md
    - .planning/workstreams/2026-us-house-candidate-coverage/STATE.md
    - .planning/workstreams/2026-us-house-candidate-coverage/REQUIREMENTS.md

key-decisions:
  - "The four pre-existing scripts referencing the dropped occupancy column were recorded, not fixed — out of Phase 166's scope."
  - "No migration authored and no Render deploy performed: everything in Phase 166 is read-only."

patterns-established:
  - "A branch that requires no action still gets an explicit do-not-defensively-edit instruction"

requirements-completed: [USHC3-06]
---

# 166-05: phase closeout

## Combined three-artifact green run — one session, one prod snapshot

Run `2026-07-27T01:00:30Z` (UTC), all three from `/c/EV-Accounts/backend` with `.env` loaded:

```
########## EXITS: verify=0 invariants=0 smoke=0 ##########
```

### 1/3 `psql -v ON_ERROR_STOP=1 -f scripts/166-verify.sql` — EXIT 0, 12 PASS

```
PASS SCOPE: 178 NATIONAL_LOWER districts across 38 states (WA10 AZ9 TN9 MA9 IN9 MD8 MN8 MO8 WI8 CO8
  AL7 SC7 LA6 KY6 OR6 CT5 OK5 AR4 IA4 KS4 MS4 NV4 UT4 NM3 NE3 WV2 ID2 HI2 ME2 NH2 RI2 MT2 AK1 DE1
  ND1 SD1 VT1 WY1), carried by 194 races over 43 elections
PASS ACTIVE: all 178 districts have >=1 active candidate; 2 with <2 (uncontested-seat allowance,
  not a failure)
NOTE ACTIVE: 5 in-scope race(s) hold 0 active candidates (geo_ids 5501, 5502, 5505, 5507, 5508) —
  expected: WI's field moved to WI 2026 Partisan Primary on 2026-07-25, leaving its general races
  empty. Every district is still covered.
PASS NULLOFFICE: 0 of 194 in-scope races have NULL office_id — including the 5 withheld severe MO
  races (2902-2906), whose office_id IS populated; only their election_id is withheld
PASS NULLPID: 0 active candidates with NULL politician_id across all 178 districts
PASS DUPNAME: 0 duplicate full_name within any state among active candidates
PASS DUPINCUMBENT: 0 politicians active in more than one in-scope race
PASS RC-UNIQUE: exactly 1 race_candidates row per (race_id, politician_id) across all 178 districts
PASS PARTY: race_candidates has no party/party_affiliation column
PASS PROVISIONAL: 81 marked + 80 unmarked asserted across 32 states (WI split 8m/16u, AL split
  4m/3u); 33 races EXCLUDED across MA/MD/OR/ME/NV/UT because their PROVISIONAL wording is inherited
  from reused pre-existing elections, not authored here; 81 + 80 + 33 = 194 in-scope races over 178
  districts
PASS HEADSHOT: every active banded new candidate across all 178 districts has a politician_images
  row or one of the 51 live-derived honest-skip pins
PASS UNSOURCED: 0 unsourced stance rows across the in-scope 178-district candidate set (challengers
  AND incumbents)
PASS COVERAGE: every active banded new candidate has >=1 sourced stance, or is one of 123 RESEARCHED
  whole-record honest-skips (documented search trail, carried verbatim from gates 161-165), or one
  of 2 candidates QUEUED TO PHASE 167 (0-stance as of 2026-07-26, no research performed — not a
  judgment)
ALL ASSERTIONS PASSED (USHC3-06 structural half, 178 Wave-3 districts across 38 states: SCOPE,
  ACTIVE, NULLOFFICE, NULLPID, DUPNAME, DUPINCUMBENT, RC-UNIQUE, PARTY, PROVISIONAL, HEADSHOT,
  UNSOURCED, COVERAGE)
NATIONAL TOTAL: 178 Wave-3 (v2.22) districts asserted by this gate together with
  backend/scripts/166-verify-invariants.sql and backend/scripts/166-coordinate-smoke.ts; 144 v2.20
  Wave-1 districts owned by backend/scripts/152-verify.sql; 89 v2.21 decided-state districts owned
  by backend/scripts/158-verify.sql; 24 v2.21 MI and VA districts SEEDED BUT GATE-PENDING under plan
  159-06, date-gated on or after 2026-08-05 (158-verify.sql's own header states it must not
  reference MI or VA, so no currently passing gate covers them). 411 gate-proven + 24 gate-pending
  = 435 US House districts nationally.
```

### 2/3 `psql -v ON_ERROR_STOP=1 -f scripts/166-verify-invariants.sql` — EXIT 0, 15 PASS

`PASS TN-SURFACING`, `PASS AL-SURFACING`, `PASS LA-SURFACING`, `PASS MO-SEVERE`, `PASS IN9-FLAG`,
`PASS AZ-RECONCILE`, `PASS MA-INCUMBENT-DEDUP`, `PASS CO1-DEGETTE`, `PASS OPEN-SEAT`,
`PASS OR-REUSE`, `PASS NV-RECONCILE`, `PASS ME-RECONCILE`, `PASS UT-REKEY`, `PASS AK-FIELD`,
`PASS COLLISION-BAND`, then:

```
ALL INHERITED INVARIANTS PASSED (15 blocks): TN-SURFACING (161+164.1-04), AL-SURFACING
  (163+164.1-05), LA-SURFACING (163+164.1-05), MO-SEVERE (162), IN9-FLAG (162), AZ-RECONCILE (161),
  MA-INCUMBENT-DEDUP (161), CO1-DEGETTE (163), OPEN-SEAT (164), OR-REUSE (164), NV-RECONCILE (165),
  ME-RECONCILE (165), UT-REKEY (165 via 1641 D04-NOTOUCH), AK-FIELD (165), COLLISION-BAND (164+165).
  The structural half is backend/scripts/166-verify.sql and the coordinate half is
  backend/scripts/166-coordinate-smoke.ts.
```

Full per-block text is in `166-04-SUMMARY.md`.

### 3/3 `node --import tsx scripts/166-coordinate-smoke.ts` — EXIT 0, 38 PASS + the MO negative

```
PASS AZ 0401: 8 active,  8 challengers   PASS WA 5304: 11 active, 11 challengers
PASS TN 4706: 11 active, 11 challengers  PASS MA 2506: 7 active,  7 challengers
PASS IN 1802: 3 active,  2 challengers   PASS MD 2405: 4 active,  4 challengers
PASS MN 2705: 10 active, 9 challengers   PASS MO 2901: 8 active,  7 challengers
PASS WI 5503: 2 active,  2 challengers   PASS CO 0801: 2 active,  2 challengers
PASS AL 0102: 7 active,  6 challengers   PASS SC 4501: 4 active,  4 challengers
PASS LA 2205: 12 active, 12 challengers  PASS KY 2104: 4 active,  4 challengers
PASS OR 4104: 3 active,  2 challengers   PASS CT 0904: 6 active,  5 challengers
PASS OK 4005: 4 active,  3 challengers   PASS AR 0501: 3 active,  2 challengers
PASS IA 1902: 4 active,  4 challengers   PASS KS 2004: 11 active, 10 challengers
PASS MS 2801: 3 active,  2 challengers   PASS NV 3202: 3 active,  3 challengers
PASS UT 4903: 6 active,  5 challengers   PASS NM 3501: 2 active,  1 challenger
PASS NE 3102: 3 active,  3 challengers   PASS WV 5402: 4 active,  3 challengers
PASS ID 1602: 6 active,  5 challengers   PASS HI 1501: 8 active,  7 challengers
PASS ME 2302: 2 active,  2 challengers   PASS NH 3301: 14 active, 14 challengers
PASS RI 4401: 3 active,  2 challengers   PASS MT 3001: 3 active,  3 challengers
PASS AK 0200: 15 active, 14 challengers  PASS DE 1000: 2 active,  1 challenger
PASS ND 3800: 2 active,  1 challenger    PASS SD 4600: 2 active,  2 challengers
PASS VT 5000: 4 active,  3 challengers   PASS WY 5600: 14 active, 14 challengers

PASS MO 2905 (severe negative sample): coordinate (39.0841,-94.4623) surfaced ZERO House races
  on MO 2026 Statewide General — withholding confirmed end-to-end

166 COORDINATE SMOKE GREEN: 38/38 states surface their US House race with full challenger-inclusive
  field
```

Every PASS line reports ≥1 challenger and 0 null politician_id. Followed by the NATIONAL COVERAGE
footer (411 gate-proven + 24 gate-pending = 435).

## Repo CI guards

| Guard | Result |
|---|---|
| `npm run check:occupancy --prefix backend` | `Office occupancy OK — 5 changed file(s) scanned, no writes to offices.politician_id.` |
| `npm run check:migrations --prefix backend` | `Migration numbering OK — 0 added vs origin/master (1322 existing prefixes).` |

**No migration authored** by Phase 166 — `git status backend/migrations/` is empty. **No Render
deploy performed or needed**: every Phase-166 artifact is read-only and touches no runtime code.

## Discovered pre-existing defect — recorded, deliberately NOT fixed

Four scripts reference `essentials.offices.politician_id`, the occupancy column dropped by
**ADR 0002 phase 5 / migration 1463**. They are **broken at runtime today**:

| File | Line |
|---|---|
| `backend/scripts/154-verify.sql` | 134 — `HAVING COUNT(o.politician_id) <> 1` |
| `backend/scripts/160-verify.sql` | 178 — `HAVING COUNT(o.politician_id) <> 1` |
| `backend/scripts/1641-coordinate-smoke.ts` | 241 — `count(o.id) FILTER (WHERE o.politician_id IS NOT NULL) AS reps` |
| `backend/scripts/1642-coordinate-smoke.ts` | 232 — `count(o.id) FILTER (WHERE o.politician_id IS NOT NULL) AS reps` |

All four are out of Phase 166's scope and were left unmodified — confirmed by `git diff --name-only`
against both `origin/master...HEAD` and the index. The `check:occupancy` guard only scans files
touched on the branch, so they do not fail it.

**Consequence that matters:** `1641-coordinate-smoke.ts` and `1642-coordinate-smoke.ts` are the
**D-02 reps-feed halves of the 164.1 and 164.2 dual-map proofs**. Those proofs therefore **cannot
currently be re-run as evidence**. Recommend a follow-up quick task to port all four to
`essentials.office_current_holder` per CLAUDE.md. If plan 164.1-07 takes Branch A and needs the 1641
differential as part of its D-10 bar, that repair becomes a prerequisite — noted in the runbook.

## `166-mo-flip-runbook.md`

Three required headings present verbatim: `## Branch A — map holds`,
`## Branch B — referendum qualifies`, `## Verification after either branch`. Branch A enumerates
five ordered changes by exact file path; Branch B states no artifact needs editing and carries an
explicit **Do not defensively edit** note.

**Three independent routes lead to it:** the delimited flip region in
`backend/scripts/166-verify-invariants.sql`, the matching region in
`backend/scripts/166-coordinate-smoke.ts`, and the STATE.md operator entry below.

## STATE.md Operator Next Steps — the amended `≥ 2026-08-04` entry, verbatim

> - **≥ 2026-08-04:** `/gsd-execute-phase 164.1 --wave 4` — Plan 164.1-07, MO date-gated (SOS
>   Hoskins certification decision). **READ
>   `phases/166-consolidated-verification-gate/166-mo-flip-runbook.md` FIRST — it is the
>   branch-by-branch edit list.** Map-holds branch = MO G5200V26 import + un-withhold 2902-2906,
>   then flip **BOTH** the Phase-162 gate (`162-verify.sql` + `162-coordinate-smoke.ts`) **AND the
>   Phase-166 gate pair** (`166-verify-invariants.sql` MO-SEVERE block inside its delimited flip
>   region, `166-coordinate-smoke.ts` severe negative sample, plus `166-derive-pins.ts`, whose
>   CENSUS MISMATCH guard will fire by design on the first post-flip run). Flipping 162 without 166
>   leaves two gates in the repo asserting opposite things about the same five districts.
>   Referendum-qualifies branch = zero polygon work, MO stays withheld, divert to Phase 167's MO
>   cluster — **neither gate needs any edit**, and the runbook says so explicitly so nobody
>   defensively edits a correct gate.

## Other tracking edits

Scoped `Edit` only. **ROADMAP grew 11 lines (1300 → 1311)**, well inside the 30-line bound;
STATE +5; REQUIREMENTS +0. No wholesale rewrite.

- ROADMAP: Phase 166 `5/5 plans complete`, all five ticked, progress row `5/5 | Complete |
  2026-07-26`; a short note recording the 43-election scope correction. Goal and Success Criteria
  left as written — they were accurate.
- STATE: frontmatter `status: complete`, progress 8/10 phases and 85/86 plans; Current Position
  records the combined green run; the stale `NEXT / anytime: /gsd-plan-phase 166` line is gone,
  replaced with the honest statement that **no unblocked v2.22 forward step remains**.
- STATE Phase-167 handoff: the `_stance_queue_167` set is **non-empty — 2 WI candidates**
  (`-550304` Kent WI-3, `-550708`), with a pointer to `166-01-SUMMARY.md` where they are enumerated.
- REQUIREMENTS: USHC3-06 ticked, coverage row `Complete (2026-07-26)`.

## Self-Check: PASSED
