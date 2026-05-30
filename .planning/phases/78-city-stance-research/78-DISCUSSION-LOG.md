# Phase 78: City Stance Research - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 78-city-stance-research
**Areas discussed:** Sacramento scope, Sacramento headshots, Context audit timing, Migration numbering

---

## Sacramento Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Include Sacramento in Phase 78 | Add a 5th city batch — research stances for all 9 Sacramento officials alongside SJ/SD/Berkeley | ✓ |
| Leave Sacramento for a follow-on phase | Phase 78 covers SJ/SD/Berkeley only; Sacramento stance research becomes Phase 81 or a quick follow-on | |
| Sacramento headshots first, then decide | Apply sac_headshots.sql first, then reassess whether to include stances | |

**User's choice:** Include Sacramento in Phase 78
**Notes:** Sacramento government structure (migration 219) and officials (migration 220) were already applied informally on 2026-05-23. 9 officials seeded. Including stances in Phase 78 closes the gap.

---

## Sacramento Headshots

| Option | Description | Selected |
|--------|-------------|----------|
| Apply headshots first (Wave 0) | Give sac_headshots.sql a migration number and apply it as the first task in Phase 78, before any stance research | ✓ |
| Skip headshots — stances only | Researchers work from names alone; Sacramento headshots become a separate quick-fix or Phase 79 task | |

**User's choice:** Apply headshots first (Wave 0)
**Notes:** Keeps the pattern consistent with the other 4 cities — fully-wired officials (with photos) before stance ingestion. Planner assigns migration number from live DB.

---

## Context Audit Timing (CSTA-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Final wave after all cities done | One SQL pass at the end after all 4 city batches ingested — same approach as Phase 74 SSTA-02 | ✓ |
| Inline per city | Each city's plan includes a verification sub-step before moving to the next city | |

**User's choice:** Final wave after all cities done
**Notes:** Clean separation: research waves produce data, Wave 5 audits. Consistent with the senator stance phase pattern.

---

## Migration Numbering

| Option | Description | Selected |
|--------|-------------|----------|
| 221 headshots, 222–225 stances | Pre-assign sequential numbers starting at 221 | |
| Let the planner decide | Planner checks live DB migration table and assigns next available numbers at plan time | ✓ |

**User's choice:** Let the planner decide
**Notes:** Avoids pre-assignment conflicts; planner has authoritative view of applied migrations.

---

## Claude's Discretion

- Specific SQL structure within each stance migration (section organization, comment format) — follow established pattern from migrations 216/219
- Batch size within research-stances skill invocation per city

## Deferred Ideas

- Sacramento as a formal CSTA requirement with its own numbered req — not needed for execution; handled informally as Wave 4
- Sacramento headshots as a formal CITY-0X requirement — not needed; Wave 0 handles this
