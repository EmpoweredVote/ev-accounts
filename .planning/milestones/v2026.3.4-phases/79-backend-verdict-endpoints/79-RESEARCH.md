# Phase 79: Backend Verdict Endpoints - Research

**Researched:** 2026-03-12
**Domain:** Go / Chi / GORM / PostgreSQL — new table + authenticated REST endpoints within existing EV-Backend
**Confidence:** HIGH

## Summary

Phase 79 adds server-side verdict storage to the EV-Backend. The work is entirely within the `EV-Backend` Go project and divides cleanly into two tasks:

1. **Verdicts CRUD in the `compass` package** — new `QuoteVerdict` model in `compass.quote_verdicts`, plus GET and POST handlers under `/compass/verdicts`. The model mirrors the established `Answer` pattern: `user_id` string FK, `quote_id` UUID FK, unique constraint on `(user_id, quote_id)`, `created_at` timestamp.

2. **Politician filter on the existing `/essentials/quotes` endpoint** — a single query-param guard in `GetQuotes`. The existing raw SQL query already has a `politician_id` column; adding `WHERE q.politician_id = ?` when the param is present is the full change.

No new Go package is needed. No new schema is needed — the decision in STATE.md locks verdicts into the existing `compass` schema. Both handlers attach to existing route groups protected by `SessionMiddleware`.

**Primary recommendation:** Model `QuoteVerdict` after `Answer` (string user_id, UUID quote_id, gorm unique constraint). Use `clause.OnConflict` for bulk upsert — this pattern is already established in `staging/handlers.go` and `compassimport/run.go`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| VERD-01 | `compass.quote_verdicts` table with `(user_id, quote_id)` unique constraint | GORM AutoMigrate + `uniqueIndex` tag; mirrors Answer model pattern in compass/models.go |
| VERD-02 | POST /compass/verdicts — authenticated bulk upsert, returns updated set | `clause.OnConflict` bulk pattern from staging/handlers.go; attach to existing SessionMiddleware group |
| VERD-03 | GET /compass/verdicts — returns current user's verdicts | Simple WHERE user_id filter; mirrors UserAnswersHandler GET branch |
| VERD-04 | GET /essentials/quotes?politician_id=X — filters by politician | Add query-param guard to existing GetQuotes raw SQL; no new endpoint needed |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| gorm.io/gorm | v1.30.0 | ORM, AutoMigrate, Clauses | Already in use for all models |
| gorm.io/gorm/clause | (bundled with gorm) | OnConflict upsert | Established pattern in staging and compassimport |
| github.com/go-chi/chi/v5 | v5.2.1 | Route registration | All packages use Chi |
| github.com/google/uuid | v1.6.0 | UUID types and generation | All models use this |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| github.com/EmpoweredVote/EV-Backend/internal/middleware | (local) | SessionMiddleware | Wraps authenticated route group |
| github.com/EmpoweredVote/EV-Backend/internal/utils | (local) | GetUserIDFromContext | Extract user_id from session context after middleware |
| github.com/EmpoweredVote/EV-Backend/internal/db | (local) | db.DB | Global GORM instance |

No new dependencies are required.

## Architecture Patterns

### Recommended Model: QuoteVerdict

Mirrors `Answer` in `compass/models.go`. Key differences: quote_id is the FK instead of topic_id; no float value field needed — verdict is a string enum ("agreed"/"disagreed").

```go
// Source: internal/compass/models.go (Answer pattern)
type QuoteVerdict struct {
    ID        string    `gorm:"primaryKey" json:"id"`
    UserID    string    `json:"user_id" gorm:"uniqueIndex:idx_user_quote"`
    QuoteID   uuid.UUID `json:"quote_id" gorm:"type:uuid;uniqueIndex:idx_user_quote"`
    Verdict   string    `json:"verdict"` // "agreed" | "disagreed"
    CreatedAt time.Time `json:"created_at"`
}

func (QuoteVerdict) TableName() string {
    return "compass.quote_verdicts"
}
```

The composite `uniqueIndex:"idx_user_quote"` on both `UserID` and `QuoteID` is the GORM tag pattern for composite unique constraints — the same tag name on multiple fields creates one composite index.

### Pattern 1: Bulk Upsert with clause.OnConflict

**What:** Accept an array of `{quote_id, verdict}` objects, upsert each one in a transaction, return the caller's full verdict set.
**When to use:** POST /compass/verdicts
**Example:**

```go
// Source: internal/staging/handlers.go:599
import "gorm.io/gorm/clause"

tx := db.DB.Begin()
for _, input := range body {
    v := QuoteVerdict{
        ID:      uuid.NewString(),
        UserID:  userID,
        QuoteID: input.QuoteID,
        Verdict: input.Verdict,
    }
    if err := tx.Clauses(clause.OnConflict{
        Columns:   []clause.Column{{Name: "user_id"}, {Name: "quote_id"}},
        DoUpdates: clause.AssignmentColumns([]string{"verdict"}),
    }).Create(&v).Error; err != nil {
        tx.Rollback()
        http.Error(w, "upsert failed", http.StatusInternalServerError)
        return
    }
}
if err := tx.Commit().Error; err != nil { ... }
// Then re-query all verdicts for this user and return them
```

Note: `clause.OnConflict.Columns` must reference the actual DB column names, not Go field names. The composite unique constraint columns are `user_id` and `quote_id`.

### Pattern 2: Session-Authenticated Handler (GetUserIDFromContext)

**What:** Retrieve `user_id` from request context set by `SessionMiddleware`.
**When to use:** Both GET and POST /compass/verdicts handlers.

```go
// Source: internal/compass/handlers.go:1003 (DeleteMyAnswersHandler)
userID, ok := utils.GetUserIDFromContext(r.Context())
if !ok {
    http.Error(w, "Unauthorized", http.StatusUnauthorized)
    return
}
```

This is the modern pattern. Older handlers in the same file manually re-read the `session_id` cookie and call `auth.SessionInfo{}.FindSessionByID` — avoid that approach; use `GetUserIDFromContext` for any handler behind `SessionMiddleware`.

### Pattern 3: Adding politician_id Filter to GetQuotes

**What:** Extend existing `GetQuotes` in `essentials/handlers.go` with an optional query param.
**When to use:** VERD-04 — GET /essentials/quotes?politician_id=X
**Example:**

```go
// Extend the WHERE clause in GetQuotes raw SQL:
politicianIDStr := r.URL.Query().Get("politician_id")
var rows []quoteRow
query := `SELECT q.id::text, ... FROM essentials.quotes q JOIN essentials.politicians p ON p.id = q.politician_id ...`
var args []interface{}
if politicianIDStr != "" {
    pid, err := uuid.Parse(politicianIDStr)
    if err != nil {
        http.Error(w, "invalid politician_id", http.StatusBadRequest)
        return
    }
    query += " WHERE q.politician_id = ?"
    args = append(args, pid)
} else {
    query += " ORDER BY p.full_name, q.topic_key"
}
db.DB.Raw(query, args...).Scan(&rows)
```

Alternatively the filter can be added as an additional WHERE or AND to the existing ORDER BY query; the important constraint is preserving the response shape (`quotes`, `candidates`, `issues`) even when filtered.

### Recommended Project Structure Change

Only two files are modified, one file added to compass package:

```
internal/compass/
├── models.go        # Add QuoteVerdict struct + TableName()
├── setup.go         # Add &QuoteVerdict{} to AutoMigrate call
├── handlers.go      # Add VerdictHandler (GET+POST) or two separate funcs
└── routes.go        # Add r.Get/r.Post("/verdicts", ...) in SessionMiddleware group

internal/essentials/
└── handlers.go      # Extend GetQuotes with politician_id filter
```

### Anti-Patterns to Avoid

- **Re-reading session cookie manually in handlers:** Use `utils.GetUserIDFromContext` — handlers behind `SessionMiddleware` already have `user_id` in context. The pattern of calling `r.Cookie("session_id")` and `auth.SessionInfo{}.FindSessionByID` is legacy and duplicates middleware work.
- **Manual find-then-update upsert loop:** The existing `UpsertPoliticianAnswers` handler does this (loop, First, then Create/Update). For `QuoteVerdict` use `clause.OnConflict` instead — it is atomic per row and cleaner.
- **Separate endpoint for filtered quotes:** VERD-04 is a filter on the existing GET /essentials/quotes, not a new route. Adding a parallel route creates route sprawl.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Upsert on conflict | Manual First + Create/Update | `clause.OnConflict` | Already proven in staging and compassimport; atomic, no TOCTOU race |
| Schema creation | Raw SQL CREATE SCHEMA | `db.EnsureSchema` + AutoMigrate | Established pattern in all setup.go files |
| User identity | Cookie parsing in handler | `utils.GetUserIDFromContext` | Middleware already validated and injected it |
| UUID generation | Custom ID logic | `uuid.NewString()` | All models use this |

**Key insight:** The codebase already has every building block. Phase 79 is assembly, not invention.

## Common Pitfalls

### Pitfall 1: Wrong Column Names in clause.OnConflict.Columns
**What goes wrong:** GORM panics or the upsert silently inserts duplicates if `clause.Column{Name: "..."}` references Go field name instead of DB column name.
**Why it happens:** Go field is `QuoteID` but DB column is `quote_id`. GORM does not auto-convert here.
**How to avoid:** Use snake_case DB column names: `"user_id"` and `"quote_id"`.
**Warning signs:** `ERROR: there is no unique or exclusion constraint matching the ON CONFLICT specification` at runtime.

### Pitfall 2: AutoMigrate Does Not Create Unique Constraints on Existing Tables
**What goes wrong:** If `compass.quote_verdicts` table already exists (from a previous partial run) with no unique constraint, AutoMigrate will not add the missing constraint.
**Why it happens:** GORM AutoMigrate only adds missing columns and indexes; it does not repair existing ones.
**How to avoid:** This is a greenfield table so it is not a concern for initial creation. Document that the unique constraint is part of the model from the start.

### Pitfall 3: GetQuotes Response Shape Must Be Preserved for Filtered Requests
**What goes wrong:** If `politician_id` filter returns only 1 candidate's data, the `candidates` and `issues` arrays may be smaller than clients expect, but the shape must still be `{quotes:[], candidates:[], issues:[]}`.
**Why it happens:** Frontend Read & Rank relies on the fixed shape.
**How to avoid:** Keep the same response struct; just let the arrays be smaller when filtered.

### Pitfall 4: compass schema prefix required in AutoMigrate target
**What goes wrong:** GORM creates `public.quote_verdicts` instead of `compass.quote_verdicts` if the model's `TableName()` is wrong.
**Why it happens:** PostgreSQL defaults to `public` schema.
**How to avoid:** `TableName()` must return `"compass.quote_verdicts"` — consistent with all other compass models.

## Code Examples

Verified patterns from codebase sources:

### QuoteVerdict AutoMigrate Registration
```go
// Source: internal/compass/setup.go (existing pattern)
func Init() {
    if err := db.EnsureSchema(db.DB, "compass"); err != nil {
        log.Fatal("Failed to create compass schema: ", err)
    }
    if err := db.DB.AutoMigrate(
        &Topic{}, &Answer{}, &Stance{}, &Category{}, &Context{}, &UserCompass{},
        &QuoteVerdict{},  // ADD THIS
    ); err != nil {
        log.Fatal("Failed to auto-migrate tables", err)
    }
}
```

### GET /compass/verdicts Handler
```go
// Source: pattern from internal/compass/handlers.go DeleteMyAnswersHandler
func GetVerdicts(w http.ResponseWriter, r *http.Request) {
    userID, ok := utils.GetUserIDFromContext(r.Context())
    if !ok {
        http.Error(w, "Unauthorized", http.StatusUnauthorized)
        return
    }
    var verdicts []QuoteVerdict
    if err := db.DB.Where("user_id = ?", userID).Find(&verdicts).Error; err != nil {
        http.Error(w, "DB error", http.StatusInternalServerError)
        return
    }
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(verdicts)
}
```

### Route Registration
```go
// Source: internal/compass/routes.go (existing authenticated group)
r.Group(func(r chi.Router) {
    r.Use(middleware.SessionMiddleware(sessionFetcher))
    // ... existing routes ...
    r.Get("/verdicts", GetVerdicts)
    r.Post("/verdicts", BulkUpsertVerdicts)
})
```

### clause.OnConflict Bulk Upsert (established in staging)
```go
// Source: internal/staging/handlers.go:599
if err := tx.Clauses(clause.OnConflict{
    Columns:   []clause.Column{{Name: "user_id"}, {Name: "quote_id"}},
    DoUpdates: clause.AssignmentColumns([]string{"verdict"}),
}).Create(&v).Error; err != nil {
    tx.Rollback()
    http.Error(w, "Failed to upsert verdict", http.StatusInternalServerError)
    return
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual find-then-update upsert | `clause.OnConflict` atomic upsert | Used in staging/compassimport | No TOCTOU race, fewer DB round-trips |
| Reading session cookie in each handler | `utils.GetUserIDFromContext` | Introduced with utils/context.go | Handlers behind SessionMiddleware don't re-parse cookies |

## Open Questions

1. **Verdict enum validation**
   - What we know: verdict values "agreed"/"disagreed" are established in STATE.md (Phase 78 amber/cyan badge pair)
   - What's unclear: whether the model should enforce this at the DB level (CHECK constraint) or Go level
   - Recommendation: Validate in handler (simple string check before upsert); CHECK constraint can be added via raw migration if desired but is not required for the phase

2. **Return shape of POST /compass/verdicts**
   - What we know: Success criteria says "returns the updated set"
   - What's unclear: Whether this means the full user verdict set or just the upserted rows
   - Recommendation: Return the full user set (re-query after commit) — consistent with how `SelectedTopicsHandler` returns the full topic array after a PUT; makes frontend state sync trivial

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — EV-Backend has no test files |
| Config file | None |
| Quick run command | `go build ./...` (compilation check) |
| Full suite command | `go vet ./...` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VERD-01 | Table created with unique constraint | manual-only (inspect DB after run) | `go build ./...` | N/A |
| VERD-02 | POST bulk upsert returns updated verdicts | manual-only (curl/Postman) | `go build ./...` | N/A |
| VERD-03 | GET returns current user verdicts | manual-only (curl/Postman) | `go build ./...` | N/A |
| VERD-04 | GET /quotes?politician_id=X filters correctly | manual-only (curl/Postman) | `go build ./...` | N/A |

### Wave 0 Gaps
- No test infrastructure exists in EV-Backend; all validation is manual via curl/Postman against a running server pointing at the isolated Supabase instance.
- Minimum verification: `go build ./...` passes; `go vet ./...` clean; manual curl tests hit all four requirements.

## Sources

### Primary (HIGH confidence)
- `internal/compass/models.go` — Answer/UserCompass model patterns for QuoteVerdict design
- `internal/compass/setup.go` — AutoMigrate registration pattern
- `internal/compass/routes.go` — Authenticated route group pattern
- `internal/compass/handlers.go` — GetUserIDFromContext usage, handler structure
- `internal/staging/handlers.go:599` — `clause.OnConflict` upsert pattern
- `internal/essentials/handlers.go:3081` — Existing GetQuotes implementation to extend
- `internal/essentials/routes.go` — Route placement for quotes endpoint
- `internal/middleware/middleware.go` — SessionMiddleware sets ContextUserIDKey

### Secondary (MEDIUM confidence)
- `internal/compassimport/run.go:51` — Second example of clause.OnConflict usage confirming pattern is idiomatic here
- `.planning/STATE.md` Decisions section — confirms `compass.` schema, QuoteVerdict mirrors CompassAnswer

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in use; go.mod verified
- Architecture: HIGH — every pattern is already implemented in the codebase; no novel work
- Pitfalls: HIGH — identified from direct code inspection of existing handlers
- Validation: HIGH — no test framework exists; go build is the gate

**Research date:** 2026-03-12
**Valid until:** 90 days (stable Go codebase, no external API dependencies)
