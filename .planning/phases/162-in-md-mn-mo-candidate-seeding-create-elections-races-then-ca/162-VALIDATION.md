---
phase: 162
slug: in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-04
---

# Phase 162 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is a pure-data seeding phase — verification is read-only SQL assertion scripts +
> a TS coordinate-smoke script, per the 149→161 precedent. No unit-test framework applies.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None (no unit-test framework). Data-seeding phases verify via read-only SQL assertion scripts (`psql -v ON_ERROR_STOP=1 -f <phase>-verify.sql`) + standalone TS coordinate-smoke scripts. No Jest/pytest/vitest applicable. |
| **Config file** | none — see Wave 0 Requirements |
| **Quick run command** | `cd /c/EV-Accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/162-verify.sql` |
| **Full suite command** | Same command — the gate script IS the full suite (single consolidated assertion set, per 156/158/161 precedent) + `162-coordinate-smoke.ts` |
| **Estimated runtime** | ~10 seconds (SQL gate) + ~15 seconds (coordinate smoke) |

---

## Sampling Rate

- **After every task commit:** targeted `psql` SELECT for the specific state/district just written (idempotency + row-count spot check)
- **After every plan wave / state-slice merge:** run the state-scoped subset of `162-verify.sql` (or the whole file — cheap)
- **Before `/gsd:verify-work`:** Full `162-verify.sql` green + `162-coordinate-smoke.ts` (4-state positive + MO-severe negative sample) must pass
- **Max feedback latency:** ~25 seconds

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| USHC3-02 | 0 duplicate politician rows per state; new/reuse split correct | SQL assertion | `psql -f scripts/162-verify.sql` (dup-full_name + reuse-pid checks, cloned from 156/161) | ❌ W0 | ⬜ pending |
| USHC3-02 | IN-9 flags corrected (Houchin `true`, 4 opponents `false`) | SQL assertion | `162-verify.sql` IN9-FLAG block (novel — no 161 precedent) | ❌ W0 | ⬜ pending |
| USHC3-03 | 33 races exist, 0 NULL office_id, 0 NULL politician_id (active) | SQL assertion | `162-verify.sql` scope-count + NULLPID checks | ❌ W0 | ⬜ pending |
| USHC3-03 | Severe MO races exist but do NOT surface via `/elections` | SQL assertion + coord smoke | `162-verify.sql` MO-SEVERE block (clone TN-SEVERE) + `162-coordinate-smoke.ts` (0 races at severe test point) | ❌ W0 | ⬜ pending |
| USHC3-04 | Every new candidate has a `politician_images` row or pinned honest-skip | SQL assertion | `162-verify.sql` `_img_skip` pattern | ❌ W0 | ⬜ pending |
| USHC3-05 | 0 unsourced stance rows; every in-scope candidate has ≥1 sourced federal stance or pinned whole-record skip | SQL assertion | `162-verify.sql` `_stance_skip`/`_in_scope`/`_fed24` pattern | ❌ W0 | ⬜ pending |
| MD reuse | All 8 MD incumbents + 13 new challengers wired without duplication on the 8 existing races | SQL assertion | `162-verify.sql` exactly-1-row-per-pid-per-race check | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `backend/scripts/162-verify.sql` — clone `161-verify.sql` structurally; add a NEW MO-SEVERE assertion block (TN-SEVERE is the structural template) and a NEW IN9-FLAG assertion block (genuinely novel — no prior-phase equivalent)
- [ ] `backend/scripts/162-coordinate-smoke.ts` — clone `161-coordinate-smoke.ts`, extend to IN/MD/MN/MO, with a negative-result sample for ≥1 severe MO district
- [ ] `162-mo-correspondence-audit.md` — D-01a deliverable (no code); produces the MO severity table (clone `161-tn-correspondence-audit.md` structure + rubric)
- [ ] Per-state `.mts` generators (`162-{mo,mn,in,md}-generate.mts`) — clone `161-{tn,az,az,ma}-generate.mts`; free-text fields escaped via `sqlStr()` helper (V5 input-validation carry-forward)
- [ ] Per-state headshot scripts (or single parameterized script with per-state `BANDS`) — clone `seed-{tn,mi,mi,ma}-house-headshots.py`; MO uses band-scoped-only variant

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Stance chairs-not-polarity calibration + primary-source verification | USHC3-05 | Judgment on evidence sufficiency cannot be automated | Mandatory primary-source verification pass before every per-state push (per stance-pipeline standard) |
| MO severity classification (which districts are severe) | USHC3-03 | Requires human/agent map-comparison judgment (D-01a audit) | The correspondence audit produces the severity table; `162-verify.sql` then asserts the resulting withheld set |

---

## Validation Sign-Off

- [ ] All requirements have an automated SQL/coordinate verify or a documented manual verification
- [ ] Sampling continuity: gate script re-runnable per state-slice, no 3 consecutive tasks without a spot-check
- [ ] Wave 0 covers all MISSING references (verify.sql, coordinate-smoke.ts, generators, headshot scripts, MO audit)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
