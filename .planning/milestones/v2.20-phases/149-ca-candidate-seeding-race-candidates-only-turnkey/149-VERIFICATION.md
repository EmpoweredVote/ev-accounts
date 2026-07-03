---
phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
verified: 2026-06-29T11:05:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
---

# Phase 149: CA Candidate Seeding (race_candidates only — turnkey) Verification Report

**Phase Goal:** Every CA US House race surfaces its full Nov-3 candidate field on `/elections` for an in-district address — incumbent + challengers as `race_candidates` rows on the pre-seeded races, each new candidate with a record, headshot, and federal-24 evidence-only stances. Lowest-friction state; validates the seed + headshot + stance pattern before the create-races states.
**Verified:** 2026-06-29T11:05:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria, USHC-02/03/04/05)

| #   | Truth (roadmap SC)                                                                                                              | Status     | Evidence |
| --- | ----------------------------------------------------------------------------------------------------------------------------- | ---------- | -------- |
| 1   | Every CA US House race (all 52) surfaces on `/elections` via `race_candidates`; each row non-null `politician_id`, `active`, incumbent flagged | ✓ VERIFIED | Independent query: 52 distinct CA House races, 104 active race_candidates, 0 NULL pid. Gate USHC-03a/03b PASS (re-run, exit 0). Coordinate smoke 5/5 districts surface 1 race, ≥2 active incl. ≥1 challenger, 0 null pid (exit 0). |
| 2   | Every CA incumbent-nominee reuses EXISTING `politician_id` (0 dup `full_name`); only genuinely-new get new records; party normalized | ✓ VERIFIED | Gate USHC-02a (0 dup full_name), USHC-02c (46 reused incumbent pids all present, no v2.4 dup record), USHC-02b (Ruiz dedup) all PASS. Independent: 36 new active `-601xxxx` candidates; Ruiz dup `05349fa0` `is_active=false`. mig 1091 + 1092 present. |
| 3   | Every newly-seeded CA candidate has a headshot (600×750 + `politician_images` + `photo_origin_url`) or documented skip; no card shows party | ✓ VERIFIED | Gate USHC-04 PASS. Independent: 9 new candidates carry `politician_images`; the 27 honest-skip external_ids genuinely have 0 images (no free-license portrait exists — documented terminal state). Party not stored on `race_candidates` (reads from `races.primary_party`). |
| 4   | Every CA candidate lacking them has sourced federal-24 chairs-not-polarity stances, 0 unsourced, honest-skip where thin; already-stanced incumbents skipped | ✓ VERIFIED | Gate USHC-05a/05b PASS. Independent: in-scope = 68 (36 new + 32 zero-incumbents); 51 stanced (626 sourced answers); 0 unsourced; 17 whole-record skips all have 0 answers AND are active CA House candidates (honest, non-vacuous). Per operator USHC-05b standard (≥1 sourced OR pinned skip). |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact                                                       | Expected                                  | Status     | Details |
| -------------------------------------------------------------- | ----------------------------------------- | ---------- | ------- |
| `backend/migrations/1091_seed_ca_2026_house_candidates.sql`    | Idempotent seed: 38 new + 104 rc + Ruiz dedup | ✓ VERIFIED | Applied to prod; 104 active rc + 36 active new records live (2 dups retired by 1092). |
| `backend/migrations/1092_phase149_dedup_redistricted_incumbents.sql` | Retire 2 redistricting dup incumbents | ✓ VERIFIED | Present; Sánchez/Solis dedup. Explains 38-seeded → 36-active band. |
| `backend/data/seed-ca-2026-house/149-01-reconciliation.csv`    | 104-row reuse-vs-new decision             | ✓ VERIFIED | Created (per SUMMARY self-check). |
| `backend/scripts/149-verify.sql`                               | Read-only House-scoped gate               | ✓ VERIFIED | 441 lines; re-run exit 0, all 10 assertions PASS, write-free, NATIONAL_LOWER-scoped. |
| `backend/scripts/seed-ca-house-headshots.py`                   | Band-targeted headshot pipeline           | ✓ VERIFIED | Present; hardened wrong-person guard. |
| `backend/data/seed-ca-2026-house/149-03-headshots.manual.txt`  | Manual second-source list                 | ✓ VERIFIED | Present. |
| `backend/data/stance-research/ca-2026-house-b1..b7/`           | Per-batch federal-24 stance CSVs          | ✓ VERIFIED | Data pushed to DB (DB is source of truth); 626 in-scope sourced answers live. |
| `backend/scripts/149-coordinate-smoke.ts`                      | Read-only ST_Covers surfacing smoke       | ✓ VERIFIED | Re-run exit 0; 5/5 districts surface full field with challenger. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `race_candidates.race_id` | 52 existing CA House race UUIDs | INSERT onto pre-existing races | ✓ WIRED | 52 races each ≥2 active candidates; Governor (53rd) untouched. |
| `race_candidates.politician_id` | incumbent_pid or new id | reconciliation | ✓ WIRED | 0 NULL pid; 46 reused incumbents present; 36 new records. |
| `inform.politician_answers` | `inform.politician_context` with non-empty sources[] | push scripts | ✓ WIRED | 626 in-scope answers, 0 unsourced (each has matching context row with sources). |
| new candidate ext_id | `politician_images` + `politician_photos/{uuid}-headshot.jpg` | headshot pipeline | ✓ WIRED | 9 imaged; 27 documented honest-skips (0 images, no free-license portrait). |
| gate + smoke | 52 CA House races + geofence surfacing | psql gate + node ST_Covers | ✓ WIRED | Both re-run independently, exit 0. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Read-only gate all-PASS | `psql -f scripts/149-verify.sql` | 10/10 assertions PASS, exit 0 | ✓ PASS |
| Coordinate surfacing | `node scripts/149-coordinate-smoke.ts` | 5/5 districts, ≥2 active + ≥1 challenger, exit 0 | ✓ PASS |
| 52 races / 104 active rc | independent SQL | distinct_races=52, active_rc=104 | ✓ PASS |
| In-scope stance set | independent SQL | in_scope=68, with_answers=51, answers=626, unsourced=0 | ✓ PASS |
| Skip-pin honesty | independent SQL | 17 skip pids: 0 answers, all active CA House cands | ✓ PASS |
| Headshot-skip honesty | independent SQL | 27 skip ext_ids: 0 images present | ✓ PASS |
| Ruiz dedup | independent SQL | dup `05349fa0` is_active=true count = 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
| ----------- | ----------- | ------ | -------- |
| USHC-02 (records/dedup) | 149-01 | ✓ SATISFIED (CA slice) | 66 reuse + 36 new active, 0 dup full_name, Ruiz dedup. Cross-cutting req continued in 150/151 (REQUIREMENTS.md checkbox `[x]` for 02/03). |
| USHC-03 (race wiring) | 149-01 | ✓ SATISFIED (CA slice) | 104 active rc, 0 NULL pid, surfacing smoke green. |
| USHC-04 (headshots) | 149-03 | ✓ SATISFIED (CA slice) | 9 imaged + 27 documented honest-skips. REQUIREMENTS.md checkbox `[ ]` is the cross-cutting roll-up across 149/150/151, not a CA gap. |
| USHC-05 (stances) | 149-04..10 | ✓ SATISFIED (CA slice) | 51 stanced (626 sourced), 0 unsourced, 17 pinned skips per operator USHC-05b standard. |

No orphaned requirements. USHC-02/03/04/05 are state-partitioned cross-cutting requirements anchored here; the CA slice is complete. Full-144 completion is asserted by Phase 152.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (none) | — | No unreferenced TBD/FIXME/XXX in any phase-149 key file | — | — |

### Notable Deviations (documented, not gaps)

- **Quotes withheld from stance push** (all 7 batches; `essentials.quotes` push = 0): re-fetch spot-checks showed aggregator (OnTheIssues) quote strings only ~60% verbatim-locatable on the cited URL, so ~1,000+ quotes could not be verified at scale. Per T-149-12 (fabricated/stale-quote risk), the push carries values + reasoning + sources only. The roadmap SC #4 requires each answer paired to a `politician_context` row with a real source URL — that is satisfied (0 unsourced). Quotes are not in the SC; Read & Rank quote population is a documented follow-up. NOT a goal gap.
- **8 per-value verification deletions** during the wave (trans-athletes/immigration/redistricting/misinformation over-reads) — these are the chairs-not-polarity verification pass working as intended (party-inference rows removed), not gaps.
- **Gate USHC-05b reconciled from `fed_count >= 24` to `>= 1`** per operator decision 2026-06-29 — aligns the coded assertion with the gate's documented intent and D-05 (chairs-not-polarity forbids inflating to 24 via inference). Verified this is a documented standard, not a green-forcing weakening: USHC-05a (0 unsourced) remains the hard floor and held independently.
- **Gate comment says "38" new candidates; live active band = 36** (2 redistricting dups Sánchez/Solis retired by mig 1092 with `is_active=true` filter). The gate's `_new_cands` correctly resolves to the 36 active rows; comment is stale but assertion logic is correct.

### Human Verification Required

None. All goal-critical behaviors are programmatically verifiable via the read-only gate + coordinate smoke (both re-run independently with exit 0) and cross-checked with independent SQL against live prod. No visual/real-time/external-service behavior gates the phase goal (headshot visual correctness is guarded by the hardened wrong-person guard + documented manual sourcing; surfacing is proven by ST_Covers geofence smoke).

### Gaps Summary

No gaps. The phase goal is achieved in the live database and proven end-to-end:
- 52 CA House races each carry their full Nov-3 field (104 active candidates, 0 NULL pid, surfacing green).
- Records deduped (0 dup full_name; Ruiz + 2 redistricting dups retired; 46 incumbents reused — no v2.4 trap).
- Headshots best-effort complete (9 imaged + 27 honest-documented skips, all genuinely image-less).
- Federal-24 evidence-only stances: 68 in-scope, 51 stanced (626 sourced answers, 0 unsourced), 17 honest-skips pinned by UUID — all verified honest and non-vacuous.

The authoritative gate (`149-verify.sql`, exit 0, 10/10 PASS) and coordinate smoke (`149-coordinate-smoke.ts`, exit 0, 5/5) were both re-executed in this verification, and every headline count was independently re-derived with SQL that does not rely on the gate's pinned literals.

---

_Verified: 2026-06-29T11:05:00Z_
_Verifier: Claude (gsd-verifier)_
