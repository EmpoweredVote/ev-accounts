# Phase 106: DC Stance Research - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-07
**Phase:** 106-dc-stance-research
**Areas discussed:** Plan split, City topic scope, SBOE depth floor, EHN stance handling

---

## Plan split

| Option | Description | Selected |
|--------|-------------|----------|
| 3 plans (1 per requirement group) | Plan 1 = Mayor+Council+AG, Plan 2 = SBOE, Plan 3 = Shadow+EHN | ✓ |
| 2 plans | Plan 1 = Mayor+Council+AG, Plan 2 = SBOE + Shadow + EHN combined | |

**User's choice:** 3 plans (1 per requirement group)
**Notes:** Maps cleanly to DCST-01/02/03.

| Option | Description | Selected |
|--------|-------------|----------|
| One migration per politician (15 migrations) | Each of the 15 Plan 1 politicians gets their own migration file | ✓ |
| Group by council type (3 migrations) | Mayor+At-Large, Ward members, AG grouped | |
| All 15 in one migration | Single large migration, risky rollback | |

**User's choice:** One migration per politician

| Option | Description | Selected |
|--------|-------------|----------|
| Research all 15, then write all migrations | Sequential agent runs first, then executor writes migrations | ✓ |
| Research one, migrate one, repeat | Tighter feedback loop, heavier context | |

**User's choice:** Research all 15 first, then write all migrations

---

## City topic scope

| Option | Description | Selected |
|--------|-------------|----------|
| Broader — all city-applicable topics | Use all 44 live topics | |
| Locked to the 8 listed | Only the 8 topics in DCST-01 | |
| 8 core + researcher discretion | 8 required + up to 3 additional | |

**User's choice:** (free text) "Do all 44 topics, please, but don't give an answer without supporting documentation."
**Notes:** Full 44 live topics; every entry requires real source URL. No inferred stances under any circumstances.

| Option | Description | Selected |
|--------|-------------|----------|
| Same scope for all 15 | All 15 politicians get the full 44-topic pass | ✓ |
| Mayor + AG broader, ward council narrower | Differentiate by seniority | |

**User's choice:** Same scope for all 15

---

## SBOE depth floor

| Option | Description | Selected |
|--------|-------------|----------|
| All 44 live topics | Consistent with other bodies | ✓ |
| 3 topics only (DCST-02 scope) | school-vouchers, childcare, civil-rights only | |

**User's choice:** All 44 live topics

| Option | Description | Selected |
|--------|-------------|----------|
| Include politician record, skip migration | No stances written if zero evidence found | ✓ |
| Flag for manual review before moving on | Pause and ask user | |
| Require at least 1 stance per politician | Force minimum coverage | |

**User's choice:** Include politician record, skip migration — honest blank profile is acceptable

---

## EHN stance handling

| Option | Description | Selected |
|--------|-------------|----------|
| Query existing rows, then gap-fill only | Research only missing/unsourced topics | ✓ |
| Full re-research from scratch | Re-run all topics regardless of existing data | |

**User's choice:** Query-then-gap-fill — do not overwrite existing sourced stances

| Option | Description | Selected |
|--------|-------------|----------|
| Full 44 topics, skip where no evidence | Consistent approach for Shadow Senators | ✓ |
| Constrained to voting rights + DC statehood proxies | Narrow scope for Shadow Senators | |

**User's choice:** Full 44 topics for Shadow Senators, skip where no evidence

---

## Claude's Discretion

None — all key decisions were made by the user.

## Deferred Ideas

None — discussion stayed within phase scope.
