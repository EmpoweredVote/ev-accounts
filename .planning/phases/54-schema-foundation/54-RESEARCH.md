# Phase 54: Schema Foundation - Research

**Researched:** 2026-03-01
**Domain:** Go/GORM schema extension — adding 7 legislative GORM models, a politician ID bridge table, and a `leg_data_fetched_at` column to an existing PostgreSQL database; data inventory confirming available data per jurisdiction before schema commits
**Confidence:** HIGH

---

## Summary

Phase 54 is a pure schema phase: no API calls, no frontend changes, no data import. Its job is to lay the exact database foundation that every subsequent legislative data phase (55–58) depends on. Three things must be true at the end: (1) 7 new GORM models exist in `essentials/models.go` and AutoMigrate creates the tables; (2) a `legislative_politician_id_map` bridge table exists and is pre-populated so imports have a place to anchor; and (3) the `politicians` table has a `leg_data_fetched_at` column for lazy-fetch staleness gating.

The single biggest research finding is a **bioguide_id coverage gap**: live database query shows only 6 of 53 federal politicians have `bioguide_id` populated. The 47 missing are primarily cabinet secretaries and NATIONAL_EXEC officials — who legitimately have no bioguide_id because that identifier is Congressional-only. The NATIONAL_UPPER (senators) and NATIONAL_LOWER (House members) in the database are Indiana-only: 4 senators (including some from states represented in the geofence coverage) and 4 Indiana House members. The success criterion in the roadmap says "returns the same count as federal politicians in essentials.politicians" — this must be scoped to NATIONAL_UPPER + NATIONAL_LOWER only, not NATIONAL_EXEC, because cabinet secretaries do not have bioguide_ids. The 6 existing bioguide_ids all appear to be Indiana reps. The backfill for NATIONAL_UPPER/NATIONAL_LOWER politicians missing bioguide_ids (approximately 17 members) comes from the congress-legislators YAML cross-reference.

The second finding is the **schema placement decision**: prior milestone research (STACK.md) proposed a new `legislative` schema and `internal/legislative/` package, but the STATE.md architectural decision explicitly overrides this — all legislative data stays in `internal/essentials/` with `legislative_` prefix tables in the `essentials` schema. This is locked. The RESEARCH.md must not explore alternatives. The 7 GORM models go into `essentials/models.go`, their `TableName()` methods return `essentials.legislative_*`, and AutoMigrate for them goes into `essentials/setup.go`.

The third finding is the **data inventory deliverable**: SCHEMA-09 requires implementing entities from a `data-model.md` document that does not yet exist in the repository. This document must be created as part of Phase 54. It should confirm what data is actually available for each jurisdiction (federal, Indiana, California, Bloomington, LA County) at this milestone, so the schema matches confirmed-available data rather than aspirational coverage. The data inventory is an output, not an input — Phase 54 creates it.

**Primary recommendation:** Add 7 `Legislative*` GORM models to `essentials/models.go`, wire into `setup.go` AutoMigrate, add `LegDataFetchedAt *time.Time` to `Politician`, create a CLI backfill subcommand that downloads congress-legislators YAML and populates `legislative_politician_id_map` for NATIONAL_UPPER and NATIONAL_LOWER politicians only, and write a data inventory matrix document confirming per-jurisdiction data availability.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SCHEMA-01 | Database schema includes legislative sessions table with jurisdiction, name, date range, and is_current flag | LegislativeSession GORM model; `essentials.legislative_sessions` table; AutoMigrate adds it |
| SCHEMA-02 | Database schema includes legislative committees table with external_id, name, type, chamber, parent committee support, and source tracking | LegislativeCommittee GORM model; self-referential ParentID pointer; `essentials.legislative_committees` table |
| SCHEMA-03 | Database schema includes committee memberships join table linking politicians to committees with role and session | LegislativeCommitteeMembership GORM model; composite unique index on `(politician_id, committee_id, congress_number)` |
| SCHEMA-04 | Database schema includes leadership roles table with politician, title, chamber, and date range | LegislativeLeadershipRole GORM model; nullable StartDate/EndDate; `essentials.legislative_leadership_roles` table |
| SCHEMA-05 | Database schema includes legislative bills table with external_id, number, title, plain-language summary, status, sponsor, introduced date, subject tags, and source | LegislativeBill GORM model; `pq.StringArray` for TopicTags; raw_status + status_label dual fields |
| SCHEMA-06 | Database schema includes bill cosponsors join table linking politicians to bills | LegislativeBillCosponsor GORM model; composite unique on `(bill_id, politician_id)` |
| SCHEMA-07 | Database schema includes legislative votes table with politician, bill (nullable), vote question, position, date, result, and source | LegislativeVote GORM model; nullable BillID; Position enum-like string (yea/nay/abstain/absent/not_voting) |
| SCHEMA-08 | Politician table extended with `leg_data_fetched_at` timestamp column for lazy-fetch staleness gating | Add `LegDataFetchedAt *time.Time` field to existing Politician struct; GORM AutoMigrate adds column without data loss |
| SCHEMA-09 | Full data model entities from data-model.md implemented: jurisdictions, governing bodies, seats, seat tenures, and data sources tables | Create `data-model.md` confirming per-jurisdiction availability; implement LegislativePoliticianIDMap bridge table as the identity anchor; session + governing body entities covered by LegislativeSession model |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GORM | 1.30.0 | AutoMigrate adds new columns/tables without data loss | Already used for all essentials models; pattern established across 20+ tables |
| `gorm.io/driver/postgres` | 1.6.0 | PostgreSQL backend | Existing driver |
| `github.com/google/uuid` | 1.6.0 | UUID primary keys on all new models | Existing pattern: `type:uuid;default:uuid_generate_v4();primaryKey` |
| `github.com/lib/pq` | 1.10.9 | `pq.StringArray` for TopicTags text[] column | Existing pattern used in Politician.Notes, LegislativeBill.TopicTags |
| `github.com/goccy/go-yaml` | v1.18.0 | Parse congress-legislators YAML for ID bridge population | **Must add to go.mod.** `gopkg.in/yaml.v3` is archived — do not use it |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `golang.org/x/time` | latest (already in go.sum transitively) | Rate limiting for bridge population script if calling Congress.gov | Only needed for Plan 54-02 if hitting Congress.gov API; congress-legislators YAML download needs no rate limiting |
| `net/http` stdlib | Go 1.24 | Download congress-legislators YAML files | Already used throughout codebase; no wrapper needed |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `goccy/go-yaml` | `gopkg.in/yaml.v3` | `gopkg.in/yaml.v3` is **archived/unmaintained** as of 2025. Must not use. |
| `goccy/go-yaml` | `sigs.k8s.io/yaml` | Wraps the archived `gopkg.in/yaml.v3` — same maintenance issue |
| `essentials` schema prefix | New `legislative` schema | **Locked decision in STATE.md**: stay in `essentials` schema with `legislative_` prefix. No separate schema. |

**Installation (only new dependency):**
```bash
cd EV-Backend
go get github.com/goccy/go-yaml@v1.18.0
```

---

## Architecture Patterns

### Recommended Project Structure

No new directories. All changes go into existing files:

```
EV-Backend/
├── internal/essentials/
│   ├── models.go           ← Add 7 Legislative* structs + LegislativePoliticianIDMap
│   └── setup.go            ← Add new models to AutoMigrate call
├── main.go                 ← Add 'backfill-legislative-ids' subcommand case
└── go.mod                  ← Add github.com/goccy/go-yaml
```

Plus one new planning document:
```
.planning/phases/54-schema-foundation/
└── data-model.md           ← Data inventory matrix (jurisdiction × data type)
```

### Pattern 1: GORM Model with TableName in essentials Schema

All existing essentials models follow this exact pattern. New legislative models must match it exactly — no deviation.

```go
// Source: EV-Backend/internal/essentials/models.go (existing pattern)

type LegislativeSession struct {
    ID           uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    Jurisdiction string     `json:"jurisdiction"` // "federal", "indiana", "california", "bloomington-in", "la-county-ca"
    Name         string     `json:"name"`         // "119th Congress", "2025 Indiana Regular Session"
    StartDate    *time.Time `json:"start_date"`
    EndDate      *time.Time `json:"end_date"`
    IsCurrent    bool       `json:"is_current"`
    ExternalID   string     `json:"external_id"` // congress number, LegiScan session ID, etc.
    Source       string     `json:"source"`       // "congress-legislators", "legiscan", "manual"
}

func (LegislativeSession) TableName() string {
    return "essentials.legislative_sessions"
}
```

Every new model must have a `TableName()` returning `"essentials.legislative_<name>"`.

### Pattern 2: Adding a Nullable Column to Existing Model

GORM AutoMigrate adds missing columns without data loss. Adding `LegDataFetchedAt` to `Politician` is safe: it's nullable (pointer type), so existing rows get NULL and no data is touched.

```go
// Source: GORM docs (gorm.io/docs/migration) + existing Politician struct pattern
// In the Politician struct, add:
LegDataFetchedAt *time.Time `json:"leg_data_fetched_at,omitempty"`

// GORM AutoMigrate will:
// - Detect the new column by comparing struct fields to DB schema
// - ALTER TABLE essentials.politicians ADD COLUMN leg_data_fetched_at TIMESTAMPTZ
// - Existing rows get NULL (pointer type = nullable)
// - No data loss
```

**Critical:** Use `*time.Time` (pointer), not `time.Time` (value). A non-pointer time.Time would get `0001-01-01` as the default, which is misleading. A pointer gives true NULL.

### Pattern 3: Composite Unique Index on Join Tables

The existing `PoliticianCommittee` and `Identifier` models show the GORM composite unique index pattern:

```go
// Source: EV-Backend/internal/essentials/models.go (existing Identifier pattern)
type LegislativeCommitteeMembership struct {
    ID             uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    CommitteeID    uuid.UUID  `json:"committee_id" gorm:"type:uuid;uniqueIndex:idx_committee_member"`
    PoliticianID   uuid.UUID  `json:"politician_id" gorm:"type:uuid;uniqueIndex:idx_committee_member"`
    CongressNumber int        `json:"congress_number" gorm:"uniqueIndex:idx_committee_member"` // 119 for 119th Congress
    Role           string     `json:"role"`    // "member", "chair", "vice_chair", "ranking_member", "ex_officio"
    IsCurrent      bool       `json:"is_current"`
    SessionID      *uuid.UUID `json:"session_id,omitempty" gorm:"type:uuid"`
}
```

### Pattern 4: ID Bridge Table Design

The bridge table is the identity anchor for all legislative imports. It maps external IDs from any source to `essentials.politicians.id`.

```go
// New model — not in any existing file yet
type LegislativePoliticianIDMap struct {
    ID           uuid.UUID `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PoliticianID uuid.UUID `json:"politician_id" gorm:"type:uuid;not null;uniqueIndex:idx_leg_id_map"`
    IDType       string    `json:"id_type" gorm:"uniqueIndex:idx_leg_id_map"` // "bioguide", "ocd_person", "legiscan", "legistar", "openstates"
    IDValue      string    `json:"id_value" gorm:"uniqueIndex:idx_leg_id_map"`
    VerifiedAt   time.Time `json:"verified_at" gorm:"default:now()"`
    Source       string    `json:"source"` // "congress-legislators-yaml", "manual", "legiscan-lookup"
}

func (LegislativePoliticianIDMap) TableName() string {
    return "essentials.legislative_politician_id_map"
}
```

Note: The roadmap calls this table `legislative_politician_id_map` (with the `legislative_` prefix), not `politician_id_map`. Use the prefix.

### Pattern 5: CLI Backfill Subcommand

The existing `import-stances` and `import-quotes` subcommands in `main.go` provide the template. A new `backfill-legislative-ids` subcommand follows the same switch-case pattern:

```go
// Source: EV-Backend/main.go (existing switch pattern)
case "backfill-legislative-ids":
    result, err := legislativeimport.BackfillIDs(legislativeimport.BackfillConfig{
        DryRun: hasFlag(os.Args[2:], "--dry-run"),
    })
    if err != nil {
        log.Fatal("backfill-legislative-ids failed: ", err)
    }
    fmt.Printf("Backfill complete: %d matched, %d inserted, %d skipped\n",
        result.Matched, result.Inserted, result.Skipped)
    os.Exit(0)
```

The backfill logic:
1. Downloads `https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml`
2. Parses YAML into struct with `bioguide`, `first_name`, `last_name`, `full_name` fields
3. Queries `essentials.politicians` for rows where `district_type IN ('NATIONAL_UPPER', 'NATIONAL_LOWER')` (not NATIONAL_EXEC)
4. Matches by `bioguide_id` field first (fast path), then by name+state (fallback)
5. Updates `politicians.bioguide_id` where NULL and match is HIGH confidence
6. Inserts into `legislative_politician_id_map` with `id_type='bioguide'`

### Anti-Patterns to Avoid

- **Do not use `gopkg.in/yaml.v3`:** It is archived. Use `github.com/goccy/go-yaml`.
- **Do not add models to a new package:** All legislative models go in `internal/essentials/models.go`. No `internal/legislative/` package.
- **Do not create a new schema:** Tables go in `essentials` schema with `legislative_` prefix — not a new `legislative` schema.
- **Do not use non-pointer time.Time for optional timestamps:** `*time.Time` for nullable; `time.Time` for required.
- **Do not bridge NATIONAL_EXEC politicians to bioguide_id:** Cabinet secretaries, VP, President have no bioguide_id. The bridge table for these uses other ID types (none at this phase; handled in future phases if needed).
- **Do not skip the data inventory document:** SCHEMA-09 requires it. The planner must schedule its creation in Plan 54-02.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML parsing of congress-legislators | Custom byte parsing, regex | `github.com/goccy/go-yaml` | YAML has edge cases (multi-line strings, anchors, null handling) that trip custom parsers |
| Schema migrations beyond AutoMigrate | Raw `ALTER TABLE` SQL statements | GORM AutoMigrate | AutoMigrate handles column additions, missing indexes, and type changes safely; manual SQL migrations can conflict with future AutoMigrate |
| UUID generation | `fmt.Sprintf` or random bytes | `gorm:"default:uuid_generate_v4()"` tag | Existing pattern; database-generated UUIDs avoid Go-side allocation race conditions |

**Key insight:** GORM AutoMigrate is the established migration mechanism for this project. Adding columns to existing tables and creating new tables is safe and non-destructive. The `uuid-ossp` extension is already enabled in `setup.go`. Do not add parallel migration scripts — AutoMigrate is the single source of truth for DDL.

---

## Common Pitfalls

### Pitfall 1: Scoping bioguide_id Backfill to Wrong Politician Set

**What goes wrong:** The roadmap success criterion says "returns the same count as federal politicians in essentials.politicians." A literal reading suggests counting all 53 federal politicians (NATIONAL_UPPER + NATIONAL_LOWER + NATIONAL_EXEC). But cabinet secretaries (NATIONAL_EXEC) legitimately have no bioguide_id — it is a Congressional identifier only.

**Live data confirms:** 53 total federal politicians (active). 6 have bioguide_id (all Indiana congressional delegation). 47 are missing. The 47 missing are primarily NATIONAL_EXEC (cabinet, VP, President) plus some NATIONAL_UPPER/NATIONAL_LOWER politicians whose bioguide_id was never populated from BallotReady.

**How to avoid:** Scope the bridge population and the success criterion SQL to `district_type IN ('NATIONAL_UPPER', 'NATIONAL_LOWER')` only. The correct query for the success check is:
```sql
-- Check: bridge rows for legislators (not cabinet)
SELECT COUNT(*) FROM essentials.legislative_politician_id_map
WHERE id_type = 'bioguide'

-- Compare against:
SELECT COUNT(*) FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_LOWER')
  AND p.is_active = true
```

**Warning signs:** If the backfill script attempts to set bioguide_id on NATIONAL_EXEC politicians, it will fail with no match (cabinet officials are not in congress-legislators) and create misleading "failed" log entries.

---

### Pitfall 2: GORM AutoMigrate Does Not Add Foreign Keys Across Schemas

**What goes wrong:** If any new legislative model uses a GORM `foreignKey` association pointing to `essentials.politicians`, GORM AutoMigrate may fail to create the cross-table foreign key constraint (depending on GORM version and PostgreSQL configuration).

**How to avoid:** Do NOT declare GORM `foreignKey` associations from legislative models to `essentials.politicians`. Use bare UUID fields (`PoliticianID uuid.UUID`) with no association tag. Enforce referential integrity at the application layer (check politician exists before inserting) and document the app-level FK. This matches the existing pattern — `ElectionRecord.PoliticianID` uses bare UUID with no GORM association.

**Why it happens:** GORM's cross-schema FK support is inconsistent on Supabase/PostgreSQL with RLS enabled. The existing codebase already avoids cross-table GORM associations for this reason.

---

### Pitfall 3: Adding the Same Model to AutoMigrate Twice

**What goes wrong:** The `setup.go` AutoMigrate call already has 20+ models. If `LegislativePoliticianIDMap` is added but also appears as a nested association on another model, GORM may attempt to migrate it twice — which either silently deduplicates or causes a conflict error.

**How to avoid:** Each new model appears exactly once in the `db.DB.AutoMigrate(...)` call. Do not add GORM association tags that would cause implicit migration of related models.

---

### Pitfall 4: congress-legislators YAML Name Matching Breaks for Common Names and Name Variants

**What goes wrong:** The congress-legislators YAML has `first_name`, `last_name`, and `official_full_name` fields. The `essentials.politicians` table has `first_name`, `last_name`, `full_name`. Name matching as a fallback (when `bioguide_id` is not already set) will break for:
- "Jim" vs "James" (Jim Banks is "James Banks" in official records)
- Hyphenated names split differently across sources
- Suffixes ("Jr.", "III") present in one source but not the other

**How to avoid:** Implement tiered matching in the backfill:
1. Exact `bioguide_id` match (existing field) → HIGH confidence → insert directly
2. `last_name` + `state` match → MEDIUM confidence → insert + log for review
3. No match → log as unmatched → do not insert

Log all MEDIUM confidence matches for manual review. Do not silently insert ambiguous matches.

---

### Pitfall 5: The data-model.md Inventory Is Missing — SCHEMA-09 Will Fail Without It

**What goes wrong:** SCHEMA-09 references `data-model.md` as the authoritative data model spec to implement from. This file does not currently exist in the repository. Without it, the planner will have no spec to verify against.

**How to avoid:** Plan 54-02 must create `data-model.md` (or a similarly named inventory document) as an explicit task — not as documentation afterthought. The document's content is the jurisdiction × data type matrix from PITFALLS.md (Pitfall 1 table) plus confirmed counts of available records per source.

The document should answer for each jurisdiction (federal, Indiana, California, Bloomington, LA County):
- Are sessions machine-readable? (Yes/No/Partial)
- Are committee assignments available? (Yes/No/Partial + source)
- Are individual votes available? (Yes/No/Partial + source)
- Is bill sponsorship available? (Yes/No/Partial + source)

---

## Code Examples

Verified patterns from the codebase:

### Adding `leg_data_fetched_at` to Politician

```go
// Source: EV-Backend/internal/essentials/models.go — existing Politician struct
// Add this field to the existing Politician struct (after the existing Provenance block):

// Legislative data fetching
LegDataFetchedAt *time.Time `json:"leg_data_fetched_at,omitempty" gorm:"index"` // nullable; null = never fetched
```

No migration script needed. GORM AutoMigrate detects the new field and adds the column:
```sql
-- What AutoMigrate will run (equivalent):
ALTER TABLE essentials.politicians ADD COLUMN IF NOT EXISTS leg_data_fetched_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_politicians_leg_data_fetched_at ON essentials.politicians (leg_data_fetched_at);
```

### All 7 New GORM Models (with TableName)

```go
// LegislativeSession — a congressional/legislative session
type LegislativeSession struct {
    ID           uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    Jurisdiction string     `json:"jurisdiction"` // "federal", "indiana", "california", "bloomington-in", "la-county-ca"
    Name         string     `json:"name"`         // "119th Congress", "2025 IN Regular Session"
    StartDate    *time.Time `json:"start_date"`
    EndDate      *time.Time `json:"end_date"`
    IsCurrent    bool       `json:"is_current"`
    ExternalID   string     `json:"external_id"` // congress number (int as string), LegiScan session ID, etc.
    Source       string     `json:"source"`       // "congress-legislators", "legiscan", "manual"
}
func (LegislativeSession) TableName() string { return "essentials.legislative_sessions" }

// LegislativeCommittee — a committee or subcommittee
type LegislativeCommittee struct {
    ID              uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    SessionID       *uuid.UUID `json:"session_id,omitempty" gorm:"type:uuid"` // nullable: some committees span sessions
    ParentID        *uuid.UUID `json:"parent_id,omitempty" gorm:"type:uuid"`  // self-referential for subcommittees
    ExternalID      string     `json:"external_id" gorm:"uniqueIndex:idx_committee_ext"` // thomas_id, OCD committee ID
    Jurisdiction    string     `json:"jurisdiction" gorm:"uniqueIndex:idx_committee_ext"`
    Name            string     `json:"name"`
    Type            string     `json:"type"`    // "committee", "subcommittee", "joint"
    Chamber         string     `json:"chamber"` // "house", "senate", "joint", "local"
    IsCurrent       bool       `json:"is_current"`
    Source          string     `json:"source"`  // "congress-legislators", "legiscan", "manual"
}
func (LegislativeCommittee) TableName() string { return "essentials.legislative_committees" }

// LegislativeCommitteeMembership — politician on committee with role
type LegislativeCommitteeMembership struct {
    ID             uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    CommitteeID    uuid.UUID  `json:"committee_id" gorm:"type:uuid;uniqueIndex:idx_cmember"`
    PoliticianID   uuid.UUID  `json:"politician_id" gorm:"type:uuid;uniqueIndex:idx_cmember"` // app-level FK to essentials.politicians
    CongressNumber int        `json:"congress_number" gorm:"uniqueIndex:idx_cmember"` // 119 for 119th Congress; 0 for non-federal
    Role           string     `json:"role"`      // "member", "chair", "vice_chair", "ranking_member", "ex_officio"
    IsCurrent      bool       `json:"is_current"`
    SessionID      *uuid.UUID `json:"session_id,omitempty" gorm:"type:uuid"`
}
func (LegislativeCommitteeMembership) TableName() string { return "essentials.legislative_committee_memberships" }

// LegislativeLeadershipRole — speaker, majority leader, whip, etc.
type LegislativeLeadershipRole struct {
    ID           uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PoliticianID uuid.UUID  `json:"politician_id" gorm:"type:uuid;uniqueIndex:idx_leadership"` // app-level FK
    SessionID    *uuid.UUID `json:"session_id,omitempty" gorm:"type:uuid;uniqueIndex:idx_leadership"`
    Chamber      string     `json:"chamber" gorm:"uniqueIndex:idx_leadership"` // "house", "senate", "local"
    Title        string     `json:"title"`  // "Speaker", "Majority Leader", "President Pro Tempore"
    StartDate    *time.Time `json:"start_date"`
    EndDate      *time.Time `json:"end_date"`
    IsCurrent    bool       `json:"is_current"`
    Source       string     `json:"source"`
}
func (LegislativeLeadershipRole) TableName() string { return "essentials.legislative_leadership_roles" }

// LegislativeBill — a bill, resolution, ordinance, or motion
type LegislativeBill struct {
    ID           uuid.UUID      `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    SessionID    uuid.UUID      `json:"session_id" gorm:"type:uuid"`
    ExternalID   string         `json:"external_id" gorm:"uniqueIndex:idx_bill_ext"` // "hb1044-118", LegiScan bill_id, etc.
    Jurisdiction string         `json:"jurisdiction" gorm:"uniqueIndex:idx_bill_ext"`
    Number       string         `json:"number"`     // "HB 1044", "SB 123", "Ordinance 2026-15"
    Title        string         `json:"title"`      // Official title
    Summary      string         `json:"summary" gorm:"type:text"` // CRS plain-language summary (federal) or empty
    RawStatus    string         `json:"raw_status"` // Source-specific status string, preserved as-is
    StatusLabel  string         `json:"status_label"` // Normalized display label: "In Committee", "Passed", "Signed", etc.
    SponsorID    *uuid.UUID     `json:"sponsor_id,omitempty" gorm:"type:uuid"` // primary sponsor (app-level FK)
    IntroducedAt *time.Time     `json:"introduced_at"`
    PassedAt     *time.Time     `json:"passed_at"`
    SignedAt      *time.Time    `json:"signed_at"`
    TopicTags    pq.StringArray `json:"topic_tags" gorm:"type:text[]"` // Congress.gov subjects for federal
    URL          string         `json:"url"`   // Link to full text on Congress.gov / state legislature site
    Source       string         `json:"source"` // "congress", "legiscan", "manual"
}
func (LegislativeBill) TableName() string { return "essentials.legislative_bills" }

// LegislativeBillCosponsor — politician co-sponsors a bill
type LegislativeBillCosponsor struct {
    ID           uuid.UUID `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    BillID       uuid.UUID `json:"bill_id" gorm:"type:uuid;uniqueIndex:idx_cosponsor"`
    PoliticianID uuid.UUID `json:"politician_id" gorm:"type:uuid;uniqueIndex:idx_cosponsor"` // app-level FK
}
func (LegislativeBillCosponsor) TableName() string { return "essentials.legislative_bill_cosponsors" }

// LegislativeVote — individual member vote on a roll call
type LegislativeVote struct {
    ID             uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PoliticianID   uuid.UUID  `json:"politician_id" gorm:"type:uuid;uniqueIndex:idx_leg_vote;index"` // app-level FK
    BillID         *uuid.UUID `json:"bill_id,omitempty" gorm:"type:uuid;uniqueIndex:idx_leg_vote"`   // nullable: procedural votes have no bill
    SessionID      uuid.UUID  `json:"session_id" gorm:"type:uuid;uniqueIndex:idx_leg_vote"`
    ExternalVoteID string     `json:"external_vote_id" gorm:"uniqueIndex:idx_leg_vote"` // roll call number, Legistar vote ID
    VoteQuestion   string     `json:"vote_question"` // "Passage", "Amendment #3", "Cloture"
    Position       string     `json:"position"`      // "yea", "nay", "abstain", "absent", "not_voting", "present"
    VoteDate       time.Time  `json:"vote_date"`
    Result         string     `json:"result"`  // "passed", "failed", "tabled"
    YeaCount       int        `json:"yea_count"`
    NayCount       int        `json:"nay_count"`
    Source         string     `json:"source"`  // "congress", "legiscan", "manual"
}
func (LegislativeVote) TableName() string { return "essentials.legislative_votes" }

// LegislativePoliticianIDMap — cross-source identity bridge
type LegislativePoliticianIDMap struct {
    ID           uuid.UUID `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PoliticianID uuid.UUID `json:"politician_id" gorm:"type:uuid;not null;uniqueIndex:idx_leg_id_map"`
    IDType       string    `json:"id_type" gorm:"uniqueIndex:idx_leg_id_map"` // "bioguide", "ocd_person", "legiscan", "legistar", "openstates"
    IDValue      string    `json:"id_value" gorm:"uniqueIndex:idx_leg_id_map"`
    VerifiedAt   time.Time `json:"verified_at"`
    Source       string    `json:"source"` // "congress-legislators-yaml", "manual", "legiscan-lookup"
}
func (LegislativePoliticianIDMap) TableName() string { return "essentials.legislative_politician_id_map" }
```

### AutoMigrate Addition in setup.go

```go
// Source: EV-Backend/internal/essentials/setup.go (existing pattern)
// Add to the AutoMigrate call, after existing models:

if err := db.DB.AutoMigrate(
    // ... existing models ...
    &Quote{},
    &PositionDescription{},
    &BuildingPhoto{},
    // Phase 54: Legislative data foundation
    &LegislativeSession{},
    &LegislativeCommittee{},
    &LegislativeCommitteeMembership{},
    &LegislativeLeadershipRole{},
    &LegislativeBill{},
    &LegislativeBillCosponsor{},
    &LegislativeVote{},
    &LegislativePoliticianIDMap{},
); err != nil {
    log.Fatal("Failed to auto-migrate tables", err)
}
```

### congress-legislators YAML Download (for backfill)

```go
// Source: STACK.md research (verified against unitedstates/congress-legislators README)
const legislatorsCurrentURL = "https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml"

// Minimal struct for matching — only fields needed for ID bridge population
type LegislatorYAML struct {
    ID struct {
        Bioguide string `yaml:"bioguide"`
        Thomas   string `yaml:"thomas"`
        GovTrack int    `yaml:"govtrack"`
    } `yaml:"id"`
    Name struct {
        First    string `yaml:"first"`
        Last     string `yaml:"last"`
        Official string `yaml:"official_full"`
    } `yaml:"name"`
    Terms []struct {
        Type  string `yaml:"type"` // "rep" or "sen"
        State string `yaml:"state"`
        Start string `yaml:"start"`
        End   string `yaml:"end"`
    } `yaml:"terms"`
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `gopkg.in/yaml.v3` | `github.com/goccy/go-yaml` v1.18.0 | 2025 (archived) | Must use goccy; do not use go-yaml or sigs.k8s.io/yaml |
| ProPublica Congress API | Congress.gov API v3 | ProPublica shutdown | No longer available; Congress.gov is the official source |
| GovTrack bulk data/API | Congress.gov API v3 | GovTrack deprecated | Not applicable to Phase 54 but noted for Phase 56 |
| Senate votes via Congress.gov | LegiScan (Senate votes) | Congress.gov API v3 never had Senate votes | Senate vote data comes from LegiScan, not Congress.gov |

**Deprecated/outdated:**
- `gopkg.in/yaml.v3`: archived 2025, must not be used
- BallotReady provider: decommissioned (v1.5), still referenced in `ballotready/` package preserved for historical reference only

---

## Open Questions

1. **The data-model.md document location and format**
   - What we know: SCHEMA-09 requires it to exist; it is a data inventory matrix
   - What's unclear: Should it live in `.planning/phases/54-schema-foundation/` or in `EV-Backend/` as a project doc? The roadmap says "a data inventory matrix document exists" — no path specified
   - Recommendation: Create it in `.planning/phases/54-schema-foundation/data-model.md` during Plan 54-02. It is a planning artifact, not a code artifact. The success criterion says "document exists" — location in `.planning/` is appropriate.

2. **bioguide_id backfill scope: do ALL NATIONAL_UPPER/NATIONAL_LOWER politicians need bioguide_id before bridge population?**
   - What we know: 6 of ~27 NATIONAL_UPPER + NATIONAL_LOWER politicians currently have bioguide_id. The other ~21 are likely from states covered by geofence data (CA congressional delegation, Monroe County IN) whose bioguide_id was never populated.
   - What's unclear: Are the missing ~21 NATIONAL_LOWER/UPPER records actual current federal legislators, or are they stale records from BallotReady's decommissioned data?
   - Recommendation: The backfill script should match by full_name + state to congress-legislators YAML and update bioguide_id where missing AND where the match is HIGH confidence. Log all LOW confidence matches for manual review. Do not block Phase 54 completion on resolving every mismatch — the success criterion is that the bridge count matches the NATIONAL_UPPER/NATIONAL_LOWER count after backfill, not before.

3. **Should LegislativeVote model combine the roll call header with the member position, or separate them?**
   - What we know: Many legislative databases separate "roll call event" (date, question, bill, overall result, yea/nay totals) from "member vote position" (politician, position). The prior STACK.md research proposed two models: `RollCallVote` and `VoteCast`.
   - What's unclear: The REQUIREMENTS.md (SCHEMA-07) describes one table: "legislative votes table with politician, bill (nullable), vote question, position (yea/nay/abstain/absent/not voting), date, result, and source." This is a denormalized design (header + position combined).
   - Recommendation: Follow SCHEMA-07 literally — one `LegislativeVote` model combining the roll call header fields (question, date, result, yea/nay totals) with the member position. This is simpler and matches the stated requirement. The tradeoff is duplication of the header fields per vote-caster, but for the initial milestone scope (last 2 sessions, bounded number of legislators) this is acceptable and avoids a two-table FK join on every profile page query.

---

## Critical Live Database Facts

These are verified from the actual Supabase database (project: `zlbutxtrjcixpdgfzrgv`) as of 2026-03-01:

| Fact | Value | Implication for Phase 54 |
|------|-------|--------------------------|
| Total active federal politicians | 53 | The population to bridge |
| NATIONAL_EXEC (cabinet, VP, President) | 26 | No bioguide_id; exclude from bridge population |
| NATIONAL_UPPER (senators) | 4 | Should have bioguide_id; backfill from congress-legislators |
| NATIONAL_LOWER (House members) | 23 | Should have bioguide_id; backfill from congress-legislators |
| Already have bioguide_id | 6 | Indiana delegation (confirmed: Jim Banks, Todd Young, 4 IN House members) |
| Missing bioguide_id in NATIONAL_UPPER/LOWER | ~21 | Need backfill from congress-legislators YAML |
| `leg_data_fetched_at` column exists | NO | AutoMigrate will add it |
| Any `legislative_*` tables exist | NO | All 7 models are net-new |
| `essentials` schema exists | YES | No schema creation needed |
| `uuid-ossp` extension enabled | YES (in setup.go) | `uuid_generate_v4()` default works |

**Success criterion restatement (informed by live data):**
```sql
-- This query should return equal counts after Plan 54-02 completes:
SELECT COUNT(*) FROM essentials.legislative_politician_id_map WHERE id_type = 'bioguide';
-- vs:
SELECT COUNT(*) FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_LOWER')
  AND p.is_active = true;
-- Expected: 27 (4 NATIONAL_UPPER + 23 NATIONAL_LOWER)
```

---

## Sources

### Primary (HIGH confidence)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/models.go` — existing GORM model patterns (struct tags, TableName, composite uniqueIndex)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/setup.go` — AutoMigrate call structure
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/main.go` — CLI subcommand switch-case pattern
- `/Users/chrisandrews/Documents/GitHub/.planning/STATE.md` — locked architectural decision: `essentials` schema, `legislative_` prefix, no new Go package
- `/Users/chrisandrews/Documents/GitHub/.planning/REQUIREMENTS.md` — SCHEMA-01 through SCHEMA-09 specifications
- `/Users/chrisandrews/Documents/GitHub/.planning/ROADMAP.md` — Phase 54 success criteria, plan breakdown
- Live Supabase query (project zlbutxtrjcixpdgfzrgv) — federal politician counts, bioguide_id coverage, existing table list
- GORM AutoMigrate docs (gorm.io/docs/migration) — AutoMigrate adds columns/tables without data loss; does not delete columns

### Secondary (MEDIUM confidence)
- `/Users/chrisandrews/Documents/GitHub/.planning/research/STACK.md` — `goccy/go-yaml` v1.18.0 recommendation; `gopkg.in/yaml.v3` archived status
- `/Users/chrisandrews/Documents/GitHub/.planning/research/PITFALLS.md` — Pitfall 1 (schema over-engineering), Pitfall 3 (ID bridge), Pitfall 13 (FK ordering)
- `/Users/chrisandrews/Documents/GitHub/.planning/research/SUMMARY.md` — 7 new GORM models listed; bridge table design; data inventory as Phase 54 output
- [unitedstates/congress-legislators GitHub](https://github.com/unitedstates/congress-legislators) — YAML structure, bioguide field location, daily update cadence

### Tertiary (LOW confidence — verify before implementation)
- `/Users/chrisandrews/Documents/GitHub/.planning/research/ARCHITECTURE.md` — proposed model designs (note: uses `legislative` schema name, which conflicts with STATE.md decision; use `essentials` schema instead)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in codebase or verified against official docs; go-yaml deprecation confirmed
- Architecture: HIGH — based on direct codebase inspection; 20+ existing models provide clear precedent
- Pitfalls: HIGH — bioguide gap confirmed with live database query; AutoMigrate behavior confirmed from GORM docs; FK cross-schema issue confirmed from existing codebase pattern
- Live data facts: HIGH — queried directly from Supabase production DB

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (GORM is stable; congress-legislators YAML structure changes infrequently; live DB counts may shift as data is imported)
