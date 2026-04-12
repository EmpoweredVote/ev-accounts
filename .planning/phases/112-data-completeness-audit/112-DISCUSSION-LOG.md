# Phase 112: Data Completeness Audit - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-12
**Phase:** 112-data-completeness-audit
**Areas discussed:** Audit script output format, Ballot baseline sourcing, Geofence smoke test scope, Coverage metrics granularity

---

## Audit Script Output Format

### Script Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Single composite script | One `audit-monroe-county-readiness.ts` querying all dimensions, unified markdown report | |
| Multiple focused scripts | Separate scripts per dimension (races, candidates, stances, headshots, etc.), run independently | ✓ |
| You decide | Claude picks approach that best fits codebase patterns | |

**User's choice:** Multiple focused scripts
**Notes:** Keeps each script simple and testable.

### Output Format

| Option | Description | Selected |
|--------|-------------|----------|
| Markdown file in `.planning/audit/` | Human-readable report, easy to review | |
| Markdown to stdout, redirect as needed | Flexible, script stays pure | |
| Both CSV (machine) + markdown (human) | CSV for data, markdown summary for the report | ✓ |

**User's choice:** Both formats
**Notes:** Raw data plus readable summary.

### File Writing Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Each script writes its own files | Self-contained, run any one independently | |
| CSV to stdout + assembler script | Keeps scripts pure, one script builds unified report | |
| You decide | Claude picks based on codebase patterns | ✓ |

**User's choice:** You decide
**Notes:** Claude's discretion on whether scripts self-write or use an assembler.

---

## Ballot Baseline Sourcing

### Source Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Indiana SoS + Monroe County Clerk only | Authoritative official sources | |
| Official sources + local press cross-reference | Also check Herald-Times, IDS, Ballotpedia | |
| You decide | Claude picks appropriate depth | ✓ |

**User's choice:** You decide
**Notes:** None.

### Ambiguity Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Document as-is with confidence flags | Each race gets confirmed/likely/uncertain level | |
| Only include confirmed races | Leave out anything not clearly on official source | |
| You decide | Claude picks approach | ✓ |

**User's choice:** You decide
**Notes:** None.

---

## Geofence Smoke Test Scope

### Test Breadth

| Option | Description | Selected |
|--------|-------------|----------|
| Single Bloomington address | One address (200 W Kirkwood Ave), quick, meets success criteria | |
| Multiple addresses across Monroe County | One per township or distinct district combo, catches boundary gaps | ✓ |
| Single address + one edge case | Kirkwood happy path + one boundary test | |

**User's choice:** Multiple addresses across Monroe County
**Notes:** Catches boundary gaps the single-address test would miss.

### Address Count

| Option | Description | Selected |
|--------|-------------|----------|
| One per township (11-12 addresses) | Comprehensive, covers every township boundary | |
| 5-6 strategic picks | Bloomington city center, bordering townships, rural, near IU campus | ✓ |
| You decide | Claude picks count | |

**User's choice:** 5-6 strategic picks
**Notes:** Covers the major district combos without exhaustive listing.

---

## Coverage Metrics Granularity

### Profile Completeness

| Option | Description | Selected |
|--------|-------------|----------|
| Individual field reporting | Each field reported separately (bio Y/N, contacts count, degrees count, etc.) | ✓ |
| Single completeness score | Rolled-up percentage (e.g., 65% complete) | |
| Both — fields in CSV, score in markdown | Raw detail in data, summarized score in report | |

**User's choice:** Individual field reporting
**Notes:** Full visibility into exactly what's missing per candidate.

### Stance/Quote Coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Binary | Has any stances: Y/N, has any quotes: Y/N | |
| Ratio | 3/21 topics covered, 2 quotes available — shows depth | ✓ |
| You decide | Claude picks approach | |

**User's choice:** Ratio
**Notes:** Shows actual depth, not just existence.

---

## Claude's Discretion

- Script file writing strategy (self-write vs assembler)
- Ballot baseline source verification depth
- Ballot baseline ambiguity handling approach

## Deferred Ideas

None — discussion stayed within phase scope.
