---
phase: 156-oh-ga-nc-candidate-seeding
verified: 2026-07-01T06:25:40Z
status: passed
score: 3/3 success criteria verified (11/11 gate assertions PASS, 9/9 coordinate smoke)
overrides_applied: 0
re_verification:
  # Initial verification — no previous VERIFICATION.md existed
carry_forward_flags: # Documented in SUMMARY, confirmed as reasonable deferrals (NOT gaps)
  - flag: "NC minor-line NCSBE certified-list reconciliation"
    detail: "Official NCSBE 2026 filing CSV lists only Robert Luffman (NC-5) as an NC-US-House Libertarian; the other 8 154-listed NC Libertarians + Green (Aguilar) + Independent (Rogers) may not have certified. Records kept per locked-154-source discipline (not deleted mid-phase). Recommend a Phase-153-style post-hoc certified-list prune."
    reasonable: true
  - flag: "OH-1 Libertarian John Hancock vs Jason Stoops"
    detail: "LP of Ohio lists Jason Stoops (not John Hancock) for OH-1; possible 154 mis-ID. Record kept per locked-154-source; stance honest-skipped. Post-hoc 154 re-check recommended."
    reasonable: true
  - flag: "McDowell + Jerrad Christian iSideWith reliance"
    detail: "Coverage leans on iSideWith candidate-stated positions; candidate for a later Playwright/vote-based corroboration pass. 0-unsourced + chairs-not-polarity satisfied for this pass."
    reasonable: true
---

# Phase 156: OH + GA + NC Candidate Seeding Verification Report

**Phase Goal:** Every OH, GA, and NC US House race surfaces its full Nov-3 candidate field on `/elections` — all three states need `elections`/`races` rows authored first, then candidate records, race_candidates wiring, headshots, and federal-24 stances. OH (15) + GA (14) + NC (14) = 43 districts.
**Verified:** 2026-07-01T06:25:40Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC1 | `elections` row per state + one `races` row per district (15 OH + 14 GA + 14 NC), `office_id`→existing U.S. House office, every district surfaces its full field via `race_candidates` (non-null pid) | ✓ VERIFIED | 3 elections (mig 1127); scoped race count = 15 OH / 14 GA / 14 NC, **0 null office_id**; 101 active race_candidates (34/28/39), 0 null pid (gate USHC2-03a/b PASS); coordinate smoke GREEN 9/9 districts surface field via ST_Covers geofence |
| SC2 | Every new candidate has a headshot OR documented skip; incumbents reuse records (0 dup full_name/state); no party on cards; GA-13 handled (no ghost incumbent) | ✓ VERIFIED | 5 imaged + 57 pinned honest-skips = 62 (gate USHC2-04 PASS); 0 duplicate full_name in any state (independent query empty; USHC2-02a PASS); `races.primary_party=NULL`; **GA-13 office is_vacant=t, politician_id=NULL**, Clark+Chavez both `is_incumbent=f` (D-04-GA13 PASS) |
| SC3 | Every candidate lacking federal-24 stances has sourced chairs-not-polarity stances, 0 unsourced, honest-skip where thin; already-stanced incumbents skipped | ✓ VERIFIED | 17 covered (9 OH / 5 GA / 2 NC new + NC-6 McDowell 0→22), 130 rows, **0 unsourced** (independent scoped query = 0; USHC2-05a/b PASS); 46 whole-record honest-skips each confirmed 0 stance rows; partial incumbents untouched (in-scope excludes them) |

**Score:** 3/3 success criteria verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `migrations/1127_seed_oh_ga_nc_2026_house_elections_races.sql` | 3 elections + 43 races + GA-13 vacancy office | ✓ VERIFIED | Exists; GA-13 office `0d031c4f…` created is_vacant=t |
| `migrations/1128_seed_oh_2026_house_candidates.sql` | 15 OH races, 34 active rc | ✓ VERIFIED | Exists; 34 active rc / 19 new confirmed live |
| `migrations/1129_seed_ga_2026_house_candidates.sql` | 14 GA races, 28 active rc | ✓ VERIFIED | Exists; 28 active rc / 18 new confirmed live |
| `migrations/1130_seed_nc_2026_house_candidates.sql` | 14 NC races, 39 active rc | ✓ VERIFIED | Exists; 39 active rc / 25 new confirmed live |
| `scripts/156-verify.sql` | Write-free 11-assertion gate | ✓ VERIFIED | Runs green, psql exit 0, write-free (grep: no DELETE/UPDATE/INSERT INTO essentials\|inform) |
| `scripts/156-coordinate-smoke.ts` | 9-district geofence smoke | ✓ VERIFIED | Prints COORDINATE SMOKE GREEN, exit 0 |
| Stance research CSVs (OH 8 / GA 6 / NC 9) | Per-candidate sourced data | ✓ VERIFIED | All batch dirs present under `data/stance-research/{oh,ga,nc}-2026-house/` |
| Reconciliation CSVs (OH/GA/NC) | Audit trail | ✓ VERIFIED | 156-03/04/05 reconciliation CSVs all present |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| race_candidates | politician | non-null politician_id | ✓ WIRED | 0 null pid across 101 active rows (USHC2-03b) |
| races | office | non-null office_id (never NULL on House race) | ✓ WIRED | 0 null office_id across all 43 races |
| new candidate | politician_images | headshot or pinned skip | ✓ WIRED | 5 imaged confirmed live; 57 skips pinned; USHC2-04 PASS |
| stance answer | politician_context | real http source (0 unsourced) | ✓ WIRED | Independent scoped query: 0 unsourced of 130 rows |
| geofence coordinate | race → active field | ST_Covers | ✓ WIRED | Smoke: 9/9 districts surface field |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
|----------|------|--------|--------------------|--------|
| McDowell (-37006) stances | 22 answers | iSideWith questionnaire URLs, paired context rows | ✓ Values vary (Abortion=4, CivilRights=5, Climate=5, SocSec=3, AI=3 — not monotone party-line); SSM=5 carries verbatim quote | ✓ FLOWING |
| in-scope stance set | 130 rows / 17 pids | 8/6/9 research CSVs → `_push_relaxed.ts` (0-unsourced filter) | ✓ Every row has ≥1 fetched http source | ✓ FLOWING |
| GA-13 race field | Clark + Chavez active | mig 1129 on created vacancy office | ✓ Both active, neither incumbent | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Consolidated gate | `psql -f scripts/156-verify.sql` | 11 PASS, exit 0 | ✓ PASS |
| Coordinate smoke | `node --import tsx scripts/156-coordinate-smoke.ts` | COORDINATE SMOKE GREEN (9), exit 0 | ✓ PASS |
| GA-13 vacancy no ghost | live SQL | office is_vacant=t, pid=NULL; Clark/Chavez is_incumbent=f | ✓ PASS |
| Lost incumbents absent | live SQL (Carter/Collins/Loudermilk) | 0 present in 2026 active field | ✓ PASS |
| Honest-skips genuine | live SQL (sample 9 pins) | all 0 stance rows; total skipped = 46 | ✓ PASS |
| Dedup / collisions | live SQL | 0 dup full_name/state; 0 external_id collisions | ✓ PASS |

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| USHC2-02 | Records + dedup, collision-free external_id | ✓ SATISFIED | 62 new (19/18/25); 0 dup full_name; 0 collisions; incumbents reused |
| USHC2-03 | Elections/races scaffold + wiring, non-null pid+office | ✓ SATISFIED | 3 elections/43 races/101 rc; 0 null pid; 0 null office_id; smoke green |
| USHC2-04 | Headshots (or documented skips) | ✓ SATISFIED | 5 imaged + 57 pinned skips; gate PASS; 2 wrong-person attaches caught+reverted |
| USHC2-05 | Stances, 0 unsourced, chairs-not-polarity, honest-skip | ✓ SATISFIED | 130 rows / 0 unsourced; 46 honest-skips (0 rows each); McDowell 0→22 evidence-driven |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| scripts/156-verify.sql | 369, 381 | word "placeholder" in skip-reason strings | ℹ️ Info | Legitimate audit annotation ("candidate's site was a launching-soon placeholder") documenting WHY a whole-record honest-skip — not a code stub. No action. |

No TBD/FIXME/XXX debt markers in any phase-156 file.

### Human Verification Required

None. Phase deliverables are DB-state seeding fully verifiable via the consolidated gate + coordinate smoke + independent live-DB cross-checks, all of which passed.

### Gaps Summary

No gaps. All three ROADMAP success criteria are observably true in the live database, independently verified beyond the gate's own labels:

- **SC1 (scaffold + wiring):** 3 elections, 43 races (15/14/14) all with non-null office_id, 101 active race_candidates all with non-null politician_id, and the coordinate smoke confirms each sampled district surfaces its field via geofence.
- **SC2 (headshots + records + GA-13):** 62 new records with 0 duplicate full_name per state, 0 external_id collisions, no party on cards, and GA-13 is a true vacancy (office is_vacant=true, politician_id NULL, Clark+Chavez both non-incumbent). GA-1/10/11 lost/retired incumbents confirmed absent from the 2026 active field.
- **SC3 (stances):** 17 candidates covered / 130 rows with an independently-confirmed 0 unsourced, 46 whole-record honest-skips each verified to hold 0 stance rows (genuine skips, not hidden coverage). NC-6 McDowell went 0→22 with real iSideWith sources and evidence-driven values (SSM=5 backed by a verbatim quote), satisfying the zero-stance-gets-full-set rule.

The three documented carry-forward flags (NCSBE minor-line reconciliation, OH-1 Stoops-vs-Hancock, iSideWith corroboration) are reasonable, well-documented deferrals consistent with the locked-154-source discipline and Phase-153-style post-primary reconciliation pattern — NOT defects. Records were correctly kept rather than deleted mid-phase.

---

_Verified: 2026-07-01T06:25:40Z_
_Verifier: Claude (gsd-verifier)_
