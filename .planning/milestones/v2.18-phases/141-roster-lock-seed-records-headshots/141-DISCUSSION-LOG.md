# Phase 141: Roster Lock + Seed (Records + Headshots) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-20
**Phase:** 141-roster-lock-seed-records-headshots
**Areas discussed:** Treasurer-equivalent mapping, external_id scheme, Existing-record handling, Roster source + as-of date

---

## Treasurer-equivalent mapping

| Option | Description | Selected |
|--------|-------------|----------|
| Functional mapping | NY/TX elected Comptroller + FL elected CFO → role_canonical='treasurer' (keep real title); MD-style separate elected Comptroller (with appointed Treasurer) stays out of scope. | ✓ |
| Strict literal | Only offices literally titled 'Treasurer' count; NY/TX/FL recorded as no in-scope elected Treasurer. | |

**User's choice:** Functional mapping
**Notes:** Captures the state's actual elected fiscal officer for residents. MD distinction preserved (elected Comptroller ≠ Big-5 Treasurer because a separate Treasurer office exists, just legislature-chosen).

---

## external_id scheme

| Option | Description | Selected |
|--------|-------------|----------|
| fips×100000 + seq | -(state_fips*100000 + seq), seq 1-9; mandatory preflight (id < -56000 AND not present); no retrofit of existing ids. | ✓ |
| Discuss further | Walk through alternatives before locking. | |

**User's choice:** fips×100000 + seq
**Notes:** Resolved by live prod query (2026-06-20) — existing schemes are inconsistent (fips×10000 for MD/ME/VA, ad-hoc for CA/MA/TX, positive for IN, NULL for UT). fips×100 / fips×1000 both collide with the federal House band -1001..-56000; fips×100000 is the only universally-clear scheme and matches OR's existing convention.

---

## Existing-record handling

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal-touch + fix UT | Backfill role_canonical on present Big-5; leave display titles as-is; fix UT's NULL external_ids; hard no-reseed (dry-run 0 new INSERTs); non-Big-5 officers untouched. | ✓ |
| Also normalize titles | Same, plus rewrite display titles to bare office names for cross-state consistency. | |

**User's choice:** Minimal-touch + fix UT
**Notes:** Avoid cosmetic title churn (no user value, breakage risk). UT NULL external_ids surfaced during the live query — must be fixed for idempotent ON CONFLICT keys.

---

## Roster source + as-of date

| Option | Description | Selected |
|--------|-------------|----------|
| Wikipedia + .gov cross-check | Wikipedia 'List of current...' tables structured primary, state .gov cross-check, Ballotpedia individual pages tertiary; per-office source URL; as-of 2026-06; individually verify contested cases (WA Treasurer, 2025 turnover). | ✓ |
| Discuss source priority | Reconsider which source leads / recency handling. | |

**User's choice:** Wikipedia + .gov cross-check
**Notes:** Ballotpedia list/category pages are JS-rendered (empty via WebFetch) per research; individual pages still usable. Per-office source URL feeds both SEXR-01 and the later SEXS-02 context rows.

---

## Claude's Discretion

- Seed migration batching (single migration vs regional waves) — bounded 41-state set; reuse seed-national-house-reps.ts pattern.
- Headshot fallback when none found — default honest-skip (McDowell precedent) after find-headshots attempts.

## Deferred Ideas

- Non-Big-5 statewide officers (Auditor, distinct Comptroller, Superintendent, Commissioners, Land/Boards) — future milestone.
- AZ Lieutenant Governor — not seated until Jan 2027; documented exclusion.
- State-exec campaign finance — FINA stream.
- Display-title normalization across existing records — not pursued.
