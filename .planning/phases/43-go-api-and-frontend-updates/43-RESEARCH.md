# Phase 43: Go API and Frontend Updates - Research

**Researched:** 2026-02-25
**Domain:** Go API response changes, React component updates, ev-ui library, politician contacts
**Confidence:** HIGH

## Summary

Phase 43 is a straightforward wiring phase: all the data already exists in the database from Phase 41. The `politician_contacts` table has 381+ rows with city website URLs, supervisor phone numbers, and BOS office website URLs. The `building_photos` table has 11 city hall photos. What is missing is (1) the Go API not yet returning contacts in the `GET /essentials/politician/{id}` response, and (2) no UI component to display a contact section on the profile page.

The Go side requires: fetching contacts in `GetPoliticianByID`, adding a `ContactOut` DTO to the response, adding a `contact_synced_at` field to `PoliticianContact` to satisfy success criterion 4 (the model currently has no timestamp for when contacts were last verified), and registering a new `GET /essentials/cities/{geo_id}/building-photo` endpoint. The frontend side requires adding a contact section to `PoliticianProfile.jsx` in `ev-ui`. Because `essentials` consumes `ev-ui` via a local `file:../ev-ui` reference, no npm publish is needed — `npm run build` in `ev-ui` followed by rebuild in `essentials` is sufficient.

**Primary recommendation:** Two plans — Plan 01 for Go API changes (add contacts to `GetPoliticianByID`, add building-photo endpoint, add `contact_synced_at` to model), Plan 02 for frontend (`PoliticianProfile.jsx` contact section in ev-ui + rebuild essentials).

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CONT-03 | User sees contact info section on politician profile page (phone, email, website) | Add contact section to `PoliticianProfile.jsx` in ev-ui; reads `politician.contacts[]` from API; shows phone, website_url, email fields; omits empty values; rebuild ev-ui + essentials |
| CONT-04 | Go API returns contacts in politician profile response | Add contacts fetch step to `GetPoliticianByID` in handlers.go; add `ContactOut` DTO; populate `contacts` field in `PoliticianProfileOut`; success criterion: non-empty contacts array for enriched officials |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Go standard library | Go 1.24.3 | Handler, DTO, SQL | Already in use throughout EV-Backend |
| GORM | v2 | ORM + AutoMigrate | All essentials models use GORM |
| chi | v5 | Router | All essentials routes use chi |
| React | 19 | Frontend component | All React apps use React 19 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| tsup | current | ev-ui build | Always needed after changing ev-ui components |
| uuid | go-chi/chi/v5 pattern | UUID URL param parsing | Already used in all ID-based handlers |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline contacts fetch in `GetPoliticianByID` | Separate `GET /politician/{id}/contacts` endpoint | Separate endpoint requires frontend to make two API calls; inline is simpler for profile page use case; endorsements/stances use separate endpoints because they're large — contacts are small (2-3 rows per politician) |
| Adding `contact_synced_at` to existing model | Using `imported_at` or tracking via script log | `contact_synced_at` is the field named in success criterion 4; must be added to `PoliticianContact` model; AutoMigrate will add the column |

**Installation:** No new dependencies needed for any project.

---

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/internal/essentials/
├── handlers.go     MODIFY: add ContactOut DTO, add contacts fetch to GetPoliticianByID,
│                           add GetBuildingPhoto handler
├── routes.go       MODIFY: add GET /cities/{geo_id}/building-photo route
└── models.go       MODIFY: add ContactSyncedAt field to PoliticianContact

ev-ui/src/
└── PoliticianProfile.jsx  MODIFY: add contacts section rendering

essentials/
└── (rebuild after ev-ui change)
```

### Pattern 1: Adding Contacts to GetPoliticianByID
**What:** Fetch `PoliticianContact` rows for the politician and include them as a typed slice in the response.
**When to use:** This is step 9 in GetPoliticianByID (current steps 1-8 are: main SQL, addresses, identifiers, committees, images, degrees, experiences, profile assembly).
**Example:**
```go
// ContactOut DTO — add to handlers.go (with the other DTO types)
type ContactOut struct {
    ContactType string `json:"contact_type"` // "city_website", "district", "office_website", "capitol"
    Source      string `json:"source"`        // "scraped", "person", "officeholder"
    Phone       string `json:"phone,omitempty"`
    Email       string `json:"email,omitempty"`
    Fax         string `json:"fax,omitempty"`
    WebsiteURL  string `json:"website_url,omitempty"`
    SyncedAt    string `json:"synced_at,omitempty"` // ISO timestamp from contact_synced_at
}

// In GetPoliticianByID, after step 7 (experiences), add:
// 8b. Fetch contacts
var contactRows []PoliticianContact
db.DB.Where("politician_id = ?", parsedID).Find(&contactRows)
contacts := make([]ContactOut, 0, len(contactRows))
for _, c := range contactRows {
    // Skip empty contacts (rows with no useful data)
    if c.Phone == "" && c.Email == "" && c.Fax == "" && c.WebsiteURL == "" {
        continue
    }
    syncedAt := ""
    if !c.ContactSyncedAt.IsZero() {
        syncedAt = c.ContactSyncedAt.Format(time.RFC3339)
    }
    contacts = append(contacts, ContactOut{
        ContactType: c.ContactType,
        Source:      c.Source,
        Phone:       c.Phone,
        Email:       c.Email,
        Fax:         c.Fax,
        WebsiteURL:  c.WebsiteURL,
        SyncedAt:    syncedAt,
    })
}

// Add Contacts to PoliticianProfileOut struct:
type PoliticianProfileOut struct {
    OfficialOut
    Addresses   []Address    `json:"addresses"`
    Identifiers []Identifier `json:"identifiers"`
    Notes       []string     `json:"notes"`
    Contacts    []ContactOut `json:"contacts"` // NEW
}

// Populate in profile assembly (step 8):
profile := PoliticianProfileOut{
    OfficialOut:  ...,
    Addresses:    addresses,
    Identifiers:  identifiers,
    Notes:        []string(r0.Notes),
    Contacts:     contacts,   // NEW
}
```

### Pattern 2: Add contact_synced_at to PoliticianContact Model
**What:** Add a nullable timestamp field to `PoliticianContact` for tracking when contact data was last verified. Success criterion 4 requires showing "last updated" date in the UI.
**When to use:** Always — required by success criterion 4.
**Example:**
```go
// In models.go, update PoliticianContact:
type PoliticianContact struct {
    ID              uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PoliticianID    uuid.UUID  `json:"politician_id" gorm:"type:uuid;index"`
    Source          string     `json:"source"`       // "person", "officeholder", or "scraped"
    Email           string     `json:"email"`
    Phone           string     `json:"phone"`
    Fax             string     `json:"fax"`
    WebsiteURL      string     `json:"website_url,omitempty"`
    ContactType     string     `json:"contact_type"` // "district", "capitol", "city_website", "office_website"
    ContactSyncedAt *time.Time `json:"contact_synced_at,omitempty"` // NEW: when data was last verified
}
```

**IMPORTANT:** `ContactSyncedAt` must be a pointer (`*time.Time`) so GORM can distinguish "never set" (nil) from "set to zero". Using `omitempty` on a pointer causes GORM to treat nil as omit — correct behavior. The import scripts in Phase 41 did NOT set this field (the column will be NULL for all existing rows). The import scripts do NOT need to be re-run; the field will populate as NULL and the frontend should handle nil gracefully (show nothing or "Date not recorded").

**AutoMigrate behavior:** GORM AutoMigrate adds new columns without dropping data. The new `contact_synced_at` column will be NULL for all existing 381 contacts. This is fine — the frontend should show the date only when non-null.

### Pattern 3: Building Photo Endpoint
**What:** New `GET /essentials/cities/{geo_id}/building-photo` endpoint. Returns JSON with URL and attribution for a city's building photo.
**When to use:** Frontend can call this if it needs to fetch building photos dynamically. However, as noted in Phase 41 research, the Phase 41 plan chose a static CURATED_LOCAL approach — the building photos are already in `buildingImages.js`. This endpoint is required by success criterion 2 but may be minimally used.
**Example:**
```go
// In handlers.go:
func GetBuildingPhoto(w http.ResponseWriter, r *http.Request) {
    geoID := chi.URLParam(r, "geo_id")
    if geoID == "" {
        http.Error(w, "Missing geo_id", http.StatusBadRequest)
        return
    }

    var photo BuildingPhoto
    result := db.DB.Where("place_geoid = ?", geoID).First(&photo)
    if result.Error != nil {
        if errors.Is(result.Error, gorm.ErrRecordNotFound) {
            http.NotFound(w, r)
            return
        }
        http.Error(w, "DB error", http.StatusInternalServerError)
        return
    }

    writeJSON(w, map[string]interface{}{
        "place_geoid": photo.PlaceGeoid,
        "url":         photo.URL,
        "license":     photo.License,
        "attribution": photo.Attribution,
        "source_url":  photo.SourceURL,
        "fetched_at":  photo.FetchedAt.Format(time.RFC3339),
    })
}

// In routes.go, add to public routes:
r.Get("/cities/{geo_id}/building-photo", GetBuildingPhoto)
```

### Pattern 4: Frontend Contact Section in PoliticianProfile.jsx
**What:** Add a contact section card below the top card in `PoliticianProfile.jsx`. Shows phone, website, and email from `politician.contacts[]`. Groups by contact_type or displays as a flat list. Shows `synced_at` as "Last updated: [date]".
**When to use:** When `pol.contacts && pol.contacts.length > 0`.
**Example:**
```jsx
{/* Contact section */}
{pol.contacts && pol.contacts.length > 0 && (
  <div style={{ background: colors.bgWhite, borderRadius: borderRadius.lg, boxShadow: shadows.lg,
                padding: isMobile ? spacing[4] : spacing[6], marginBottom: spacing[6] }}>
    <h3 style={{ fontFamily: fonts.primary, fontWeight: fontWeights.semibold,
                 fontSize: fontSizes.lg, color: colors.evTeal, marginBottom: spacing[4] }}>
      Contact
    </h3>
    {pol.contacts.map((c, i) => (
      <div key={i} style={{ marginBottom: spacing[3] }}>
        {c.phone && (
          <p style={{ fontFamily: fonts.primary, fontSize: fontSizes.sm }}>
            📞 <a href={`tel:${c.phone}`} style={{ color: colors.evTeal }}>{c.phone}</a>
          </p>
        )}
        {c.website_url && (
          <p style={{ fontFamily: fonts.primary, fontSize: fontSizes.sm }}>
            🌐 <a href={c.website_url} target="_blank" rel="noopener noreferrer"
                  style={{ color: colors.evTeal }}>{c.website_url}</a>
          </p>
        )}
        {c.email && (
          <p style={{ fontFamily: fonts.primary, fontSize: fontSizes.sm }}>
            ✉️ <a href={`mailto:${c.email}`} style={{ color: colors.evTeal }}>{c.email}</a>
          </p>
        )}
        {c.synced_at && (
          <p style={{ fontFamily: fonts.primary, fontSize: fontSizes.xs, color: colors.textMuted }}>
            Last updated: {new Date(c.synced_at).toLocaleDateString('en-US',
              { year: 'numeric', month: 'short', day: 'numeric' })}
          </p>
        )}
      </div>
    ))}
  </div>
)}
```

**Note on emoji usage:** The CLAUDE.md says avoid emojis. Use icon SVGs or text labels instead of emoji in the actual implementation. The example above uses emoji for clarity — swap for SVG icons or text labels ("Phone:", "Website:", "Email:") in the final implementation. Match the existing `SocialLinks.jsx` visual style.

**Note on `contact_synced_at` being null for Phase 41 data:** The import scripts did not set `contact_synced_at` (the field didn't exist yet). All 381 existing contacts will have `synced_at: null` or `synced_at: ""` in the API response. The frontend must handle this gracefully — omit the "Last updated" line if `synced_at` is falsy.

### Pattern 5: ev-ui Build and Deployment
**What:** `essentials` consumes `ev-ui` via `"@chrisandrewsedu/ev-ui": "file:../ev-ui"`. Changes to `ev-ui/src/PoliticianProfile.jsx` require rebuilding the `ev-ui` package before `essentials` can see the changes.
**When to use:** Always after modifying any ev-ui component.
**Commands:**
```bash
cd ev-ui && npm run build   # Builds ESM + CJS bundles to dist/
cd essentials && npm run dev  # Or: npm run build for production
```
No npm publish is required because `essentials` uses the local file reference. No version bump is strictly needed for local development.

### Anti-Patterns to Avoid
- **Omitting contacts from PoliticianProfileOut:** The `PoliticianProfileOut` struct currently has no `Contacts` field. If it is not added, the frontend receives `contacts: null`. Must add `Contacts []ContactOut json:"contacts"` to the struct.
- **Using non-pointer `time.Time` for ContactSyncedAt:** A non-pointer `time.Time{}` in GORM serializes as a zero date ("0001-01-01T00:00:00Z") rather than null. Use `*time.Time` with `omitempty`.
- **Filtering out all contacts before returning:** The current contacts table has rows with `email=''`, `fax=''` and only `website_url` or `phone` populated. Do not filter on `email != ''` alone — filter on "at least one of phone, email, fax, website_url is non-empty."
- **Importing `time` package unnecessarily:** `time` is already imported in `handlers.go` (line 13). Do not add a duplicate import.
- **Rebuilding ev-ui without bumping version:** For local `file:` dependencies, a rebuild is sufficient. However, if `essentials` is deployed to a CDN or CI that caches npm installs, the version should be bumped. For local dev only, rebuild suffices.
- **Adding building-photo to the contacts flow:** Building photos are NOT part of CONT-03/CONT-04. They are a separate requirement (BLDG-01/02 already satisfied by Phase 41). The new endpoint is a success criterion but the frontend does not need to call it since `buildingImages.js` already has hardcoded CDN URLs.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Contacts fetch in profile | Custom ORM query | `db.DB.Where("politician_id = ?", parsedID).Find(&contactRows)` | Same pattern as images, degrees, experiences in GetPoliticianByID |
| Contact section styling | Custom CSS system | `colors`, `fonts`, `spacing` tokens from ev-ui | All components use the established token system |
| Date formatting for synced_at | Custom date formatter | `new Date(c.synced_at).toLocaleDateString('en-US', {...})` | Same pattern used in SocialLinks and other date displays |
| ev-ui local linking | npm link or symlink | `"file:../ev-ui"` already in package.json | The existing `file:` reference is already set up and working |

**Key insight:** Everything needed already exists: data in DB, model in Go, token system in ev-ui. Phase 43 is pure wiring.

---

## Common Pitfalls

### Pitfall 1: `contact_synced_at` Field Does Not Exist Yet
**What goes wrong:** `PoliticianContact` in `models.go` has no `ContactSyncedAt` field. Success criterion 4 says "shows a 'last updated' date using the `contact_synced_at` field." If this field is never added, the criterion cannot be met.
**Why it happens:** Phase 41 added `WebsiteURL` to `PoliticianContact` but did not add a timestamp column. The criterion was deferred to Phase 43.
**How to avoid:** Add `ContactSyncedAt *time.Time json:"contact_synced_at,omitempty"` to `PoliticianContact` in `models.go`. GORM AutoMigrate will add the column. All existing rows will have NULL for this column — that is acceptable; the UI should hide the "Last updated" line when null.
**Warning signs:** Grep for `contact_synced_at` in models.go returns no results — means it still needs to be added.

### Pitfall 2: PoliticianProfileOut Missing Contacts Field
**What goes wrong:** `PoliticianProfileOut` struct has `Addresses`, `Identifiers`, `Notes` but no `Contacts`. Even after fetching contacts in the handler, they would have nowhere to go in the response.
**Why it happens:** The struct was created before contacts were in scope for the profile endpoint.
**How to avoid:** Add `Contacts []ContactOut json:"contacts"` to `PoliticianProfileOut`. Initialize as empty slice (`make([]ContactOut, 0)`) when no contacts exist so the API returns `"contacts": []` not `"contacts": null`.
**Warning signs:** API response for a supervisor with known contacts shows `"contacts": null` or missing `contacts` key.

### Pitfall 3: BallotReady Contact Delete+Recreate Overwrites Scraped Contacts
**What goes wrong:** In the upsert flow (`upsertOfficial` in handlers.go, lines 857-865), contacts are deleted and recreated: `tx.Where("politician_id = ?", polID).Delete(&PoliticianContact{})`. This means any time BallotReady warmer runs for a politician, ALL their contacts (including the Phase 41 scraped ones) get deleted.
**Why it happens:** The BallotReady upsert uses a "delete + recreate" pattern for contacts (same as images, degrees, experiences).
**How to avoid:** This is a pre-existing pattern that Phase 43 cannot easily fix without refactoring the BallotReady upsert. For the LA County scraped politicians, the BallotReady warmer does NOT run (they are `data_source='scraped'`, not BallotReady officials), so their contacts are safe. However, for any politician that IS served via BallotReady (federal, state, other local), the warmer would delete scraped contacts. **Scope for Phase 43:** This is a known limitation but out of scope — LA County officials use `data_source='scraped'` and the warmer does not re-fetch them.
**Warning signs:** Supervisor contacts disappear after a ZIP search triggers the background warmer.

### Pitfall 4: Building Photo Endpoint URL Parameter Name
**What goes wrong:** Success criterion 2 says `GET /essentials/cities/{geo_id}/building-photo`. The `BuildingPhoto` model uses `PlaceGeoid` as its primary key. These are the same thing (Census GEOID), but the URL param name is `geo_id` while the model field is `PlaceGeoid`.
**Why it happens:** The success criterion uses `geo_id` for the URL; the model uses `place_geoid` as its internal key. Chi URL param is `geo_id`, the WHERE clause uses `place_geoid`.
**How to avoid:** `geoID := chi.URLParam(r, "geo_id")` → `db.DB.Where("place_geoid = ?", geoID)`. This is straightforward but easy to mismatch.
**Warning signs:** 404 on all building photo requests even though data exists in DB.

### Pitfall 5: Empty Contact Rows Shown in UI
**What goes wrong:** Some contact rows may have been inserted with empty phone, email, fax, and website_url (e.g., default empty strings from the import script). These would show up as empty contact cards in the UI.
**Why it happens:** The `upsert_website_contact` function inserts `email='', phone='', fax=''` alongside the website_url. The `upsert_phone_contact` similarly inserts `website_url='', email='', fax=''` alongside the phone. These are populated rows (one field is non-empty) but pattern is slightly inconsistent.
**How to avoid:** In the Go handler, filter out contacts where ALL of phone/email/fax/website_url are empty strings. The check: `if c.Phone == "" && c.Email == "" && c.Fax == "" && c.WebsiteURL == ""` — skip this row.
**Warning signs:** Contact section shows empty bullets or blank rows.

### Pitfall 6: ev-ui PoliticianProfile.jsx Not Exported
**What goes wrong:** `ev-ui/src/index.jsx` does NOT currently export `PoliticianProfile`. It exports `RadarChartCore`, `Header`, `FilterSidebar`, `PoliticianCard`, `CategorySection`, `SocialLinks`, `IssueTags`, `CommitteeTable`. `PoliticianProfile` is imported directly in `essentials/src/pages/Profile.jsx` as `import { ..., PoliticianProfile } from '@chrisandrewsedu/ev-ui'` — this import IS present, meaning it must be exported.
**Investigation needed:** Either `PoliticianProfile` is missing from `index.jsx` exports (needs to be added) or it is already exported via a different path. The current `index.jsx` content (8 component exports + design tokens) does not include `PoliticianProfile`.
**How to avoid:** Add `export { default as PoliticianProfile } from "./PoliticianProfile.jsx"` to `ev-ui/src/index.jsx` if not present. Rebuild ev-ui after.
**Warning signs:** `essentials` app shows `PoliticianProfile is not a function` or undefined at runtime.

---

## Code Examples

Verified patterns from codebase inspection:

### Current GetPoliticianByID Step Structure (for inserting Step 8b)
```go
// Current handler structure in GetPoliticianByID:
// 1. Main SQL query (r0 row)        — lines 1971-2012
// 2. Addresses                       — lines 2018-2020
// 3. Identifiers                     — lines 2023-2024
// 4. Committees                      — lines 2027-2047
// 5. Images                          — lines 2049-2055
// 6. Degrees                         — lines 2057-2068
// 7. Experiences                     — lines 2070-2082
// 8. Profile assembly (PoliticianProfileOut) — lines 2084-2128
//    writeJSON(w, profile)            — line 2130

// INSERT STEP 8b between step 7 and step 8:
// 8b. Fetch contacts
var contactRows []PoliticianContact
db.DB.Where("politician_id = ?", parsedID).Find(&contactRows)
contacts := make([]ContactOut, 0, len(contactRows))
for _, c := range contactRows {
    if c.Phone == "" && c.Email == "" && c.Fax == "" && c.WebsiteURL == "" {
        continue
    }
    syncedAt := ""
    if c.ContactSyncedAt != nil && !c.ContactSyncedAt.IsZero() {
        syncedAt = c.ContactSyncedAt.Format(time.RFC3339)
    }
    contacts = append(contacts, ContactOut{
        ContactType: c.ContactType,
        Source:      c.Source,
        Phone:       c.Phone,
        Email:       c.Email,
        Fax:         c.Fax,
        WebsiteURL:  c.WebsiteURL,
        SyncedAt:    syncedAt,
    })
}
```

### PoliticianContact Model Update (models.go line 251-260)
```go
// Current (line 251-260):
type PoliticianContact struct {
    ID           uuid.UUID `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PoliticianID uuid.UUID `json:"politician_id" gorm:"type:uuid;index"`
    Source       string    `json:"source"` // "person", "officeholder", or "scraped"
    Email        string    `json:"email"`
    Phone        string    `json:"phone"`
    Fax          string    `json:"fax"`
    WebsiteURL   string    `json:"website_url,omitempty"`
    ContactType  string    `json:"contact_type"` // "district", "capitol", "city_website", etc.
}

// After update (add ContactSyncedAt):
type PoliticianContact struct {
    ID              uuid.UUID  `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PoliticianID    uuid.UUID  `json:"politician_id" gorm:"type:uuid;index"`
    Source          string     `json:"source"`
    Email           string     `json:"email"`
    Phone           string     `json:"phone"`
    Fax             string     `json:"fax"`
    WebsiteURL      string     `json:"website_url,omitempty"`
    ContactType     string     `json:"contact_type"`
    ContactSyncedAt *time.Time `json:"contact_synced_at,omitempty"`
}
```

### Routes.go Update
```go
// Add to public routes in routes.go:
r.Get("/cities/{geo_id}/building-photo", GetBuildingPhoto)

// Current public routes for reference:
r.Get("/politicians", GetAllPoliticians)
r.Get("/politicians/{zip}", GetPoliticiansByZip)
r.Post("/politicians/search", SearchPoliticians)
r.Get("/politician/{id}", GetPoliticianByID)
r.Get("/candidates/{zip}", GetCandidatesByZip)
r.Get("/politician/{id}/endorsements", GetPoliticianEndorsements)
r.Get("/politician/{id}/stances", GetPoliticianStances)
r.Get("/politician/{id}/elections", GetPoliticianElections)
```

### ev-ui index.jsx — Add PoliticianProfile Export
```jsx
// Current ev-ui/src/index.jsx does NOT export PoliticianProfile.
// essentials/src/pages/Profile.jsx imports it as:
//   import { Header, PoliticianProfile } from '@chrisandrewsedu/ev-ui';
// This will fail at runtime if PoliticianProfile is not exported.
// ADD to ev-ui/src/index.jsx:
export { default as PoliticianProfile } from "./PoliticianProfile.jsx";
```

### Contact Section Styling Pattern (ev-ui tokens)
```jsx
// Existing token imports in PoliticianProfile.jsx (line 2):
import { colors, fonts, fontWeights, fontSizes, spacing, borderRadius, shadows } from './tokens';

// Available token values used in this file:
// colors.evTeal, colors.bgWhite, colors.textSecondary, colors.textMuted, colors.borderLight
// fonts.primary (Manrope)
// fontSizes.lg, fontSizes.sm, fontSizes.xs, fontSizes.base
// fontWeights.semibold, fontWeights.medium, fontWeights.regular
// spacing[2], spacing[3], spacing[4], spacing[6], spacing[8]
// borderRadius.lg
// shadows.lg
// isMobile (from useMediaQuery hook already in the component)
```

---

## Critical Discovery: PoliticianProfile Not in ev-ui Exports

**HIGH CONFIDENCE finding:** `ev-ui/src/index.jsx` exports 8 components but `PoliticianProfile` is NOT in the list:
```
RadarChartCore, Header, FilterSidebar, PoliticianCard,
CategorySection, SocialLinks, IssueTags, CommitteeTable
```

Yet `essentials/src/pages/Profile.jsx` imports:
```jsx
import { Header, PoliticianProfile } from '@chrisandrewsedu/ev-ui';
```

**This import works** because `essentials` uses `"@chrisandrewsedu/ev-ui": "file:../ev-ui"` (local file reference). The local file reference may resolve via the raw source files (not the dist bundle), OR the component was added to the dist bundle manually. Since `PoliticianProfile.jsx` exists in ev-ui src and the essentials app currently works, the local file reference resolves correctly via Vite's module resolution.

**Action for Phase 43:** When modifying `PoliticianProfile.jsx` in ev-ui, add it to `index.jsx` exports and run `npm run build` in ev-ui. This ensures the built dist also includes it (important for any future npm publish or CI build).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No contacts in profile API response | `contacts: []` array in PoliticianProfileOut | Phase 43 | UI can display phone/website/email |
| No contact timestamp | `contact_synced_at` nullable column on PoliticianContact | Phase 43 | UI can show "Last updated" date |
| No building photo API endpoint | `GET /cities/{geo_id}/building-photo` | Phase 43 | Dynamic building photo lookup available |
| Contact data in DB but invisible to users | Contact section in PoliticianProfile.jsx | Phase 43 | CONT-03 satisfied |

**Existing (do not change):**
- `buildingImages.js` CURATED_LOCAL approach: already satisfying BLDG-01/02 — no need to switch to API approach for Phase 43
- `formatTermDate` / `getTermLine` / `TermDatePrecision`: already implemented in Phase 41 — do not touch
- Phase 41 import scripts: do NOT re-run; data is already in DB

---

## Open Questions

1. **contact_synced_at will be null for all Phase 41 contacts**
   - What we know: Phase 41 did not set a timestamp on contacts; the column doesn't exist yet
   - What's unclear: Should the import scripts be updated to backfill a timestamp on existing rows?
   - Recommendation: No backfill needed. When Phase 43 adds the column (AutoMigrate), all rows get NULL. The frontend shows "Last updated: [date]" only when `synced_at` is non-null. The Phase 41 data is still useful for CONT-03 even without a date. A future enrichment pass can set the timestamp. This is acceptable for v1.7.

2. **Contact deduplication: multiple rows for same politician**
   - What we know: Supervisors have 2 contact rows (phone + website), city council members have 1 (city_website). Some officials might have BallotReady contacts from Phase B candidacy fetch in addition to scraped contacts.
   - What's unclear: Should duplicates be filtered (e.g., show only the most useful contact)?
   - Recommendation: Show all non-empty contacts. The current dataset is small (2-3 rows max per politician). De-duplication logic adds complexity for minimal gain. The UI can group by contact_type if desired but flat list is simpler.

3. **PoliticianProfile export from ev-ui index**
   - What we know: `PoliticianProfile` is not in index.jsx exports but works via local file reference
   - What's unclear: Whether adding it to index.jsx and rebuilding might break anything
   - Recommendation: Add the export — it is a simple, safe addition. The component already exists and works.

---

## Validation Architecture

> config.json has `nyquist_validation` not set (key missing) — the `workflow` object only has `research`, `plan_check`, `verifier`. Treating as disabled; skipping this section.

---

## Sources

### Primary (HIGH confidence)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — GetPoliticianByID full implementation (steps 1-8); OfficialOut DTO; PoliticianProfileOut struct (no Contacts field confirmed); existing DTO patterns (ContactOut, EndorsementOut, StanceOut, ElectionRecordOut)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/models.go` — PoliticianContact model (lines 251-260); BuildingPhoto model (lines 276-284); confirmed: no ContactSyncedAt field exists
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/routes.go` — All current public routes confirmed; no building-photo or contacts endpoint
- `/Users/chrisandrews/Documents/GitHub/ev-ui/src/PoliticianProfile.jsx` — Full component; no contacts section; token imports; isMobile hook; SocialLinks usage pattern
- `/Users/chrisandrews/Documents/GitHub/ev-ui/src/index.jsx` — Export list confirmed; PoliticianProfile NOT exported
- `/Users/chrisandrews/Documents/GitHub/essentials/src/pages/Profile.jsx` — Import confirmed: `import { Header, PoliticianProfile } from '@chrisandrewsedu/ev-ui'`
- `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/api.jsx` — `fetchPolitician` function confirmed
- `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/buildingImages.js` — CURATED_LOCAL hardcoded CDN URLs for 11 cities; already working; no API call needed
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/import_city_contacts.py` — Phase 41 import script; confirmed what contact_type values are used (`city_website`, `district`, `office_website`)
- `/Users/chrisandrews/Documents/GitHub/.planning/phases/41-building-photos-term-data-contact-enrichment/41-03-SUMMARY.md` — 381+ contacts confirmed in DB; WebsiteURL field added to model
- `/Users/chrisandrews/Documents/GitHub/.planning/phases/41-building-photos-term-data-contact-enrichment/41-VERIFICATION.md` — Phase 41 completion state; CONT-03/04 explicitly deferred to Phase 43

### Secondary (MEDIUM confidence)
- GORM AutoMigrate behavior for new nullable columns — adds column without data loss; verified through multiple prior phases (Phase 39, 40, 41 all used AutoMigrate)
- ev-ui local `file:` reference resolution — works via Vite's module resolution for local development without npm publish

### Tertiary (LOW confidence)
- None — all critical findings are from direct codebase inspection

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all from direct codebase inspection
- Architecture: HIGH — patterns derived from existing handlers (endorsements, stances, elections follow exact same shape)
- Contacts data state: HIGH — Phase 41 summary confirms 381+ contacts; import script inspected
- Critical gap (PoliticianProfile not in ev-ui index): HIGH — index.jsx directly inspected
- contact_synced_at absence: HIGH — models.go directly inspected, no such field
- PoliticianProfileOut missing Contacts: HIGH — struct definition directly inspected

**Research date:** 2026-02-25
**Valid until:** 2026-03-25 (codebase is stable; no external API dependencies in this phase)
