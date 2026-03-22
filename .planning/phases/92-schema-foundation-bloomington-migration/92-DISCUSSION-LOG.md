# Phase 92: Schema Foundation & Bloomington Migration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-22
**Phase:** 92-schema-foundation-bloomington-migration
**Areas discussed:** Migration approach, Entity type modeling, Static fallback guard, Schema migration safety

---

## Migration Approach

### Q1: How should Bloomington data move from static JSON to Supabase?

| Option | Description | Selected |
|--------|-------------|----------|
| Go CLI subcommand | Add `import-budgets` CLI command. Reads static JSON, transforms to GORM models, upserts. Repeatable, consistent with existing patterns. | ✓ |
| One-time SQL script | Direct SQL insert. Fast but bypasses model validation, not reusable. | |
| Go script in cmd/ | Standalone Go file, uses GORM but not wired into main CLI. | |

**User's choice:** Go CLI subcommand
**Notes:** Consistent with existing import-stances and import-quotes patterns.

### Q2: Should all three dataset types migrate in Phase 92?

| Option | Description | Selected |
|--------|-------------|----------|
| All three | Migrate operating, revenue, and salary together. Requirements DATA-01 through DATA-03. | ✓ |
| Operating only | Start with operating, defer rest. Lower risk but revisit needed. | |

**User's choice:** All three
**Notes:** None

### Q3: How should the import validate data integrity?

| Option | Description | Selected |
|--------|-------------|----------|
| API round-trip check | Hit treasury API endpoints post-import, compare totals against source JSON. | ✓ |
| Database query check | SQL queries to verify row counts and totals. Faster but doesn't test API. | |
| You decide | Claude picks. | |

**User's choice:** API round-trip check
**Notes:** None

---

## Entity Type Modeling

### Q1: Should the City model/table be renamed?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep City model | Add entity_type field, keep table as treasury.cities. Least disruption. | |
| Rename to Entity | Model Entity, table treasury.entities. More accurate. | |
| Rename to Jurisdiction | Model Jurisdiction, table treasury.jurisdictions. Semantically precise. | |

**User's choice:** Other — suggested "Local" for consistency with other features
**Notes:** User initially suggested "Local" to be consistent with Essentials tier naming.

### Q2 (follow-up): Given ripple effects, how should naming be handled?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep City model | Least disruption, entity_type does semantic work. | |
| Rename to Local | Full rename to Local/locals. Consistent naming. | |
| Rename to Municipality | Model Municipality, table treasury.municipalities. Formal term. | ✓ |

**User's choice:** Rename to Municipality
**Notes:** User chose Municipality as the final naming decision.

### Q3: What entity_type values should be supported?

| Option | Description | Selected |
|--------|-------------|----------|
| city, county, township | Covers all roadmap targets plus future townships. | ✓ |
| city, county only | Skip township. | |
| Free-text string | No enum constraint. Most flexible. | |

**User's choice:** city, county, township
**Notes:** None

---

## Static Fallback Guard

### Q1: How should the static JSON fallback be guarded?

| Option | Description | Selected |
|--------|-------------|----------|
| Bloomington-only check | Only attempt static fallback if cityName === 'Bloomington'. | |
| Remove static fallback entirely | Delete static JSON files and fallback code. API-only. | ✓ |
| You decide | Claude picks. | |

**User's choice:** Remove static fallback entirely
**Notes:** Clean break — no safety net needed once data is in Supabase.

### Q2: What should the frontend show when API is down?

| Option | Description | Selected |
|--------|-------------|----------|
| Error message with retry | Clear error message with retry button. | ✓ |
| Empty dashboard | Dashboard shell with no data. | |
| You decide | Claude picks based on existing patterns. | |

**User's choice:** Error message with retry
**Notes:** None

---

## Schema Migration Safety

### Q1: How should schema changes be applied to production?

| Option | Description | Selected |
|--------|-------------|----------|
| GORM AutoMigrate | Let GORM handle on startup. Table rename needs manual SQL first. Consistent with all modules. | ✓ |
| Manual SQL migration | Explicit ALTER TABLE statements. Full control but diverges from pattern. | |
| Supabase migration file | Use Supabase migration system. More formal but new workflow. | |

**User's choice:** GORM AutoMigrate
**Notes:** Manual SQL step for table rename, then AutoMigrate for the rest.

### Q2: How to handle existing Bloomington data during table rename?

| Option | Description | Selected |
|--------|-------------|----------|
| Rename table + update FKs | ALTER TABLE RENAME, update FK column. One-time SQL before deploy. | ✓ |
| Create new table, migrate data | Create fresh, copy data, update FKs, drop old. Safer rollback. | |
| You decide | Claude picks safest approach. | |

**User's choice:** Rename table + update FKs
**Notes:** None

---

## Claude's Discretion

None — all areas had explicit user decisions.

## Deferred Ideas

None — discussion stayed within phase scope.
