# Phase 105: DC Infrastructure + Official Records - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-07
**Phase:** 105-dc-infrastructure-official-records
**Areas discussed:** TIGER ward import, At-large FK structure, EHN migration scope, Plan split

---

## TIGER Ward Import

| Option | Description | Selected |
|--------|-------------|----------|
| Extend load-state-tiger-boundaries.ts | Add DC/sldl to STATE_LAYER_ALLOWLIST; add STATE_LAYER_TYPE_MAP override; wire sldl processLayer dispatch | ✓ |
| New one-off script | Write import-dc-ward-boundaries.ts specific to DC | |
| You decide | Claude picks the approach that best fits the codebase pattern | |

**User's choice:** Extend load-state-tiger-boundaries.ts

---

## TIGER Type Override

| Option | Description | Selected |
|--------|-------------|----------|
| Add per-state type override map | STATE_LAYER_TYPE_MAP: { DC: { sldl: 'CITY_COUNCIL' } } alongside the existing allowlist | ✓ |
| Hard-code DC case inside processLayer dispatch | if state === 'DC' set CITY_COUNCIL inline in the sldl branch | |
| You decide | Claude picks the cleanest implementation | |

**User's choice:** Add per-state type override map (separate from allowlist)

---

## At-Large FK Structure — Shadow Senators

| Option | Description | Selected |
|--------|-------------|----------|
| NATIONAL_LOWER at-large | Shadow Senators share EHN's NATIONAL_LOWER district record | ✓ |
| New DC_SHADOW district record | New district_type for Shadow Senators | |
| NULL district_id | Link to DC government only, no district FK | |

**User's choice:** NATIONAL_LOWER at-large

---

## At-Large FK Structure — SBOE At-Large

| Option | Description | Selected |
|--------|-------------|----------|
| NULL tiger_geoid | SBOE at-large seat is a SCHOOL_BOARD district record with tiger_geoid = NULL | ✓ |
| Synthetic at-large geoid | Assign placeholder geoid + full DC city boundary polygon as geometry | |
| You decide | Claude picks what makes sense for the schema | |

**User's choice:** NULL tiger_geoid

---

## EHN Migration Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Full update | Verify/create NATIONAL_LOWER office FK to new DC district + update photo_origin_url | ✓ |
| Photo only | Only update photo_origin_url if null, leave office FK as-is | |

**User's choice:** Full update

---

## Plan Split

| Option | Description | Selected |
|--------|-------------|----------|
| 2 plans: 105-01 infra + 105-02 records | Mirrors v2.5 Phase 77 pattern; infra gates records via FK | ✓ |
| 3 plans: infra / council records / other records | Split DCOF into Mayor+Council vs. AG+Shadow+SBOE | |
| 1 plan: everything together | Single large migration | |

**User's choice:** 2 plans

---

## Claude's Discretion

- DC government geo_id format: Claude recommended `'11'` (FIPS state-equivalent) consistent with TX migration 087 using `'48'`
- External_id range: Claude recommended -600001 onward (next unoccupied range after city officials at -500001+); researcher to verify at pre-flight

## Deferred Ideas

- Phase 130 full sldl generalization — wiring sldl for other states beyond DC is Phase 130 scope
- DC school board geofencing — ward-based SBOE member lookup via user_districts is a future enhancement
