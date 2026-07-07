---
phase: 165
slug: small-delegation-states-candidate-seeding-17-states-create-e
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-07
---

# Phase 165 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is a pure-data seeding phase — verification is read-only SQL assertion scripts +
> a TS coordinate-smoke script, per the 149→164 precedent. No unit-test framework applies.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None (no unit-test framework). Data-seeding phases verify via read-only SQL assertion scripts (`psql -v ON_ERROR_STOP=1 -f <phase>-verify.sql`) + standalone TS coordinate-smoke scripts. No Jest/pytest/vitest applicable. |
| **Config file** | none — see Wave 0 Requirements |
| **Quick run command** | `cd /c/EV-Accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/165-verify.sql` |
| **Full suite command** | Same command — the gate script IS the full suite (single consolidated assertion set, per 156/158/161–164 precedent) + `165-coordinate-smoke.ts` |
| **Estimated runtime** | ~10 seconds (SQL gate) + ~20 seconds (coordinate smoke, 17 states) |

---

## Sampling Rate

- **After every per-state seed migration:** Re-run the relevant per-state assertion block of `165-verify.sql` (or targeted `execute_sql` count checks) before moving to the next state.
- **After every plan wave:** Run the full `165-verify.sql` gate + `165-coordinate-smoke.ts`.
- **Before `/gsd:verify-work`:** Full gate must be green (all criteria PASS, 0 unsourced stances, pinned skip sets documented).
- **Max feedback latency:** ~30 seconds.

---

## Per-Task Verification Map

*Filled by the planner per task. Every seeding task maps to a `165-verify.sql` criterion (row counts, NON-NULL politician_id/office_id, 0 duplicate full_name per state, 0 unsourced stances) and/or a `165-coordinate-smoke.ts` anchor (in-district coordinate → race with full field, including the challenger-present Pitfall-5 two-path guard). UT tasks additionally assert the 164.1-ut-wiring-contract invariants: races on existing offices 4901–4904, `essentials.offices` untouched (NOTOUCH md5 unchanged).*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (per-plan) | — | — | USHC3-02..05 | — | idempotent NOT EXISTS migrations; read-only gates | sql-gate | `psql ... -f scripts/165-verify.sql` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `backend/scripts/165-verify.sql` — consolidated re-runnable assertion gate (authored by the gate plan; pinned skip sets with dated comments)
- [ ] `backend/scripts/165-coordinate-smoke.ts` — per-state in-district coordinate anchors (UT anchors use G5200V26 boundaries; race-level asserts in `1641-coordinate-smoke.ts` auto-activate once `UT 2026 Statewide General` exists)

*No test-framework install needed — existing psql/tsx infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Headshot wrong-person guard spot-check | USHC3-04 | Visual identity confirmation is human judgment | Spot-check a sample of new `politician_images` rows against source pages (first-name mismatch + pre-1940 homonym guard already automated) |
| Stance chairs-not-polarity calibration | USHC3-05 | Scale-position judgment vs evidence | Review a sample CSV batch per state cluster before push |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (165-verify.sql + 165-coordinate-smoke.ts authored by plan 165-17)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-07 (plan-checker VERIFICATION PASSED, 17/17 plans, Nyquist Dim-8 PASS)
