# Phase 31: Essentials Profile and District Data Fixes - Research

**Researched:** 2026-02-22
**Domain:** React frontend UI (essentials app + ev-ui library), Go backend (essentials handlers), PostgreSQL/PostGIS geofence data
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Profile page context:**
- Office title stays as the main heading (H2)
- Add subtitle below title showing **chamber name + district** (e.g., "Bloomington Common Council, District 3" or "Indiana Senate, District 40")
- Office description (what their position does) stays near the title as italicized text — immediate context, not a separate section
- Show **only office_description** — remove bio_text from profile display entirely (no long biographies)
- Term dates labeled inline: "First elected: Jan 2020 — Term ends: Jan 2026"
- Years in office displayed right below the term dates
- If years-in-office data is missing for federal/state officials, research should investigate whether it's a DB gap or display gap and fix accordingly

**Card display in results:**
- Cards should be 3 lines: (1) Name, (2) Office/position title, (3) Chamber + district
- Chamber + district subtitle appears on ALL cards (federal, state, local) — consistent design
- If chamber/district data is empty, card falls back to 2 lines (no empty 3rd line)
- **No party affiliation displayed anywhere** — no party badges on cards, no party info on profiles. Empowered Vote is antipartisan; listing party affiliation undermines the tool's purpose.
- Research should verify whether party badges are currently showing and flag for removal

**Empty/missing data handling:**
- Missing profile image: show **initials avatar** (circle with first/last initials in EV color palette)
- Empty office_description: **hide the section** entirely (don't show placeholder text)
- Both term dates null: **hide entire term section** including years in office
- Empty card 3rd line (no chamber/district): card is just 2 lines, no fallback text

**District-level city council visibility:**
- District-level city council members are not appearing in search results at all
- Backend uses address-based search via Google Maps geocoding → geofence polygon matching against stored data
- Research must verify: (1) Do we have polygon data for Bloomington, IN city council districts? (2) Do we have polygon data for major LA County city districts? (3) Is the geofence matching query including LOCAL district types?
- This phase includes both **code fixes AND data fixes** — if polygon data is missing, import it
- BallotReady is no longer used; all data comes from our own database

**Remove Issues and Prioritization card:**
- Remove the "Issues and Prioritization" card from the profile page (frontend only)
- Keep backend endpoints (endorsements, stances) intact for future use
- Only this card is removed — all other profile sections remain

### Claude's Discretion
- Exact initials avatar styling (colors, font weight, sizing)
- How to abbreviate long chamber names on cards if needed
- Geofence query optimization approach
- Which specific LA County cities to verify polygon data for

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

## Summary

This phase is a frontend UI polish pass combined with a geofence data import task. The UI work touches two layers: the `ev-ui` shared library (`PoliticianProfile` and `PoliticianCard` components) and the `essentials` app itself (`Profile.jsx`, `Results.jsx`). The data work requires importing Census TIGER shapefile data for city council sub-district boundaries that are currently missing from the `geofence_boundaries` table.

Database investigation confirms the root cause of missing district-level city council members: Bloomington, IN city council Districts 1–6 have geo_ids like `180586000001` through `180586000006`, but no matching rows exist in `essentials.geofence_boundaries`. At-Large council members (geo_id `1805860`, the whole city boundary) do appear correctly because that geo_id has a G4110 geofence. The six district council members are simply invisible because their sub-city boundaries were never imported. The same pattern applies to all LA County city council sub-districts — zero CA city-level (G4110) or ward-level geofences exist in the table.

The `total_years_in_office` gap for federal officials (NATIONAL_EXEC, and several NATIONAL_UPPER/NATIONAL_LOWER) is a **data gap, not a display gap** — these records came from the Cicero provider which did not populate that field. The display logic already handles `total_years_in_office = 0` by hiding the section (via the `> 0` guard in `PoliticianProfile.jsx`). No backend change is needed for this field; it will surface naturally when data is present.

**Primary recommendation:** Split work into (a) frontend-only changes in essentials app and ev-ui library, (b) geofence data import for Bloomington city council districts, (c) evaluate LA County feasibility separately given scale.

---

## Standard Stack

### Core (already in use, no new dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 19.1.1 | UI rendering | Already in essentials app |
| Tailwind CSS 4 | ^4.1.12 | Utility styling | Already in essentials app |
| `@chrisandrewsedu/ev-ui` | ^0.1.19 (installed), 0.1.26 (published) | Shared components | PoliticianProfile + PoliticianCard live here |
| Go 1.24.3 | — | Backend (no changes needed) | Backend data is already correct |
| PostGIS | — | Geofence polygon storage + point-in-polygon queries | Already in use |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Census TIGER shapefiles | 2024 | City council district boundaries | Data import for geofence fix |
| `psql` / Supabase SQL console | — | SQL migration to import boundaries | One-time data import |

**No new npm packages required.** All UI changes use existing Tailwind + inline styles. The geofence import uses raw SQL (existing PostGIS infrastructure).

---

## Architecture Patterns

### Component Ownership

The codebase has two distinct edit sites for politician display:

**1. `ev-ui` library** (`/Users/chrisandrews/Documents/GitHub/ev-ui/src/`):
- `PoliticianProfile.jsx` — profile page layout (photo, name, title, term, bio, committees)
- `PoliticianCard.jsx` — card in results list (image, name, title)

**2. `essentials` app** (`/Users/chrisandrews/Documents/GitHub/essentials/src/`):
- `pages/Profile.jsx` — wraps `PoliticianProfile`, owns the "Issues and Prioritization" section that must be removed
- `pages/Results.jsx` — renders `PoliticianCard` via `renderPoliticianCard()` helper

**Critical publishing requirement:** Changes to `ev-ui` require a version bump + `npm run build` + `npm publish`, then `npm update @chrisandrewsedu/ev-ui` in the `essentials` app. This is a multi-step deploy cycle. However, several decisions (subtitle on cards, initials avatar) require changes in `ev-ui`. Plan must account for this publish step.

**Alternative for card changes:** The `essentials` app's `Results.jsx` calls the ev-ui `PoliticianCard` with `title={pol.office_title}`. The 3-line card (name/title/chamber+district) requires adding a `subtitle` prop to `PoliticianCard` in ev-ui. This cannot be done locally only — ev-ui must be updated.

### Data Flow: What the API Returns

The `OfficialOut` DTO (handlers.go:103–152) already includes all needed fields:
```
chamber_name        → "Bloomington Common Council"
district_label      → "Bloomington City Common Council - District 1"
district_id         → "1"  (or "At Large" or "")
office_title        → "Bloomington City Common Council - District 1"
total_years_in_office → int (0 for Cicero-sourced officials)
term_start          → "2025-01-01" (mapped from valid_from)
term_end            → "2028-12-31" (mapped from valid_to)
office_description  → from offices.description
bio_text            → from politicians.bio_text
```

For the profile subtitle "chamber name + district", the best source is `chamber_name` + `district_id`. However, for BallotReady data the chamber_name is often set to the full position label (e.g., "Bloomington City Common Council - District 1") rather than just "Bloomington Common Council". This means chamber_name is not clean for subtitle display — it may need truncation/parsing.

**Better subtitle construction approach:** Use `district_label` (which is clean from BallotReady) combined with `district_id`. Or compute it in the frontend from available fields. Research shows the chamber_name for Bloomington district council members is set identically to the office title (e.g., "Bloomington City Common Council - District 1"), not a shared chamber name. For Indiana Senate members, `chamber_name` = "Indiana Senate" and `district_id` = "40", which is ideal for "Indiana Senate, District 40".

### Pattern: Profile Subtitle Construction

The frontend needs to build a subtitle string. Given the inconsistency of `chamber_name` for BallotReady LOCAL officials, the safest approach is:

```javascript
// In PoliticianProfile.jsx
function buildSubtitle(pol) {
  const chamber = pol.chamber_name || pol.chamber_name_formal || '';
  const distId = pol.district_id || '';  // "1", "40", "At Large", ""

  if (!chamber) return null;

  // If chamber_name equals office_title (BallotReady redundancy), use district_label instead
  if (chamber === pol.office_title && pol.district_label) {
    return pol.district_label; // "Bloomington City Common Council - District 1"
  }

  // Standard: "Indiana Senate, District 40"
  if (distId && distId !== '') {
    return `${chamber}, District ${distId}`;
  }

  return chamber; // fallback: just chamber name
}
```

However, `district_id` is NOT currently in the `OfficialOut` DTO or the `GetPoliticianByID` query. It must be added to both the fetchOfficialsFromDB query and the GetPoliticianByID query, and to the OfficialOut struct.

**Wait** — checking the data again: for the card display in Results, we have `chamber_name` and `district_label` available in the list response. The `district_label` is already the full human-readable string (e.g., "Bloomington City Common Council - District 1"). For cards, using `district_label` directly as the 3rd line may be simpler than constructing it. For profile, the subtitle construction needs to be clean.

### Pattern: Term Date Display

Current `PoliticianProfile.jsx` (line 14–19) already has:
```javascript
function getTermLine(pol) {
  const start = formatTermDate(pol.term_start);
  if (!start) return null;
  const end = formatTermDate(pol.term_end);
  return end ? `${start} – ${end}` : `Since ${start}`;
}
```

This produces "Jan 2025 – Jan 2029", not "First elected: Jan 2025 — Term ends: Jan 2029". The label text must change. The field is `valid_from` in the DB but `term_start`/`term_end` in the API response — already renamed correctly.

The decision says: "First elected: Jan 2020 — Term ends: Jan 2026". Note that `valid_from` is the start of the **current term** (from BallotReady), not necessarily when they were first elected. Calling it "First elected" is technically inaccurate for multi-term officials. The safer label is "Term start:" and "Term ends:" — but the user decided "First elected". This should be flagged in the plan as a naming caveat.

### Pattern: Initials Avatar

Current `PoliticianProfile.jsx` already has an initials placeholder:
```javascript
const initials = [pol.first_name, pol.last_name]
  .filter(Boolean)
  .map((n) => n[0])
  .join('');
// ...
<div style={styles.placeholder}>{initials || '?'}</div>
```

The current placeholder style is a rectangular 3:4 aspect ratio box (matching photo dimensions) with `borderRadius: borderRadius.lg`. The decision asks for a **circle** with EV color palette. This requires changing the placeholder from a rectangle to a circle (`borderRadius: '50%'` with equal width/height, or use `aspect-ratio: 1`), and applying an EV brand color as background.

For `PoliticianCard.jsx`, the image placeholder currently shows "No photo" text in a small `imagePlaceholder` div. This also needs to become an initials circle.

### Pattern: Geofence Data Import

The root cause of missing district council members is confirmed: city council sub-district boundaries (geo_ids like `180586000001`) have no entries in `essentials.geofence_boundaries`.

**TIGER shapefile source for city council districts:**

From BallotReady's own documentation ([Interpreting mtfcc and geo_id](https://support.ballotready.org/interpreting-mtfcc-and-geoid)), city council sub-districts use MTFCC `X0001` — a custom code, not a standard Census MTFCC. The geo_id format is: 7-digit place FIPS + zero-padded district number (e.g., Bloomington FIPS = `1805860`, District 1 = `180586000001`).

Census TIGER does NOT have a shapefile layer for municipal ward/council districts as a standard product. The sub-city district boundaries must come from a local/municipal source:
- Bloomington, IN provides its own GIS data (Monroe County GIS portal)
- LA County cities would each need their own data

**Bloomington city council district boundaries:**

The 6 Bloomington city council districts (geo_ids `180586000001` through `180586000006`) need polygon data. Bloomington/Monroe County publishes this on their open data portal. The import approach:
1. Obtain GeoJSON/Shapefile from Monroe County GIS or Bloomington Open Data
2. Transform to WGS84 if needed
3. Insert into `essentials.geofence_boundaries` with `mtfcc = 'X0001'` and `state = '18'`
4. Update `mtfccToDistrictTypes` map in `geofence_lookup.go` to handle `X0001` → `["LOCAL"]`

**Current mtfccToDistrictTypes gap:** The map in `geofence_lookup.go` does not include `X0001`. Without adding it, even if boundary polygons are imported, the query will fall through to the "unknown MTFCC" branch which matches any district type — this would actually work but without type-safety filtering. Adding `X0001` → `["LOCAL"]` explicitly is cleaner.

**LA County city council districts:**

LA county has zero G4110 (incorporated place) boundaries in the geofence table, and zero city-council ward boundaries. For this phase, verifying LA County feasibility means: obtaining polygon data for Long Beach, Pasadena, LA City, and other major cities. Each city publishes its own GIS data. This is a larger data import effort than Bloomington. The decision says "this phase includes data fixes" but LA County at full scale may warrant scoping to just Bloomington for the initial fix.

**Geofence query type-filtering:**

In `FindPoliticiansByGeoMatches` (geofence_lookup.go:66), the current `mtfccToDistrictTypes` includes:
```go
"G4110": {"LOCAL", "LOCAL_EXEC"},  // Incorporated Place (city/town)
```

This means a point inside Bloomington's G4110 polygon returns LOCAL and LOCAL_EXEC politicians — which is why At-Large members, the Mayor, and the Clerk appear. District council members do NOT appear because their geo_ids have no polygon. The fix is purely a data import, not a code logic change (except adding X0001 to the map).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Polygon boundary import | Custom parser | PostGIS `ST_GeomFromGeoJSON()` or `ST_GeomFromText()` | PostGIS handles all projection/validity issues |
| Initials avatar | Custom SVG generator | Inline div with `border-radius: 50%` + initials text | Already done in ev-ui; just change shape + color |
| Term date formatting | Custom date library | Native `Date.toLocaleDateString` | Already in ev-ui `formatTermDate()` |
| Chamber name truncation | Long string parsing | CSS `text-overflow: ellipsis` on card 3rd line | Frontend CSS handles overflow cleanly |

---

## Common Pitfalls

### Pitfall 1: ev-ui Publish Cycle Timing
**What goes wrong:** Developer edits `PoliticianCard.jsx` in ev-ui, forgets to publish, tests in essentials app against the old installed version, sees no change.
**Why it happens:** essentials uses the npm-published version (`^0.1.19`), not a local symlink.
**How to avoid:** Version bump ev-ui, `npm run build`, `npm publish`, then `npm update @chrisandrewsedu/ev-ui` in essentials before testing.
**Warning signs:** Card still shows old layout despite code change in ev-ui.

### Pitfall 2: district_id Not in API Response
**What goes wrong:** Frontend tries to access `pol.district_id` to build "District 3" subtitle but field is undefined — it is not currently included in `OfficialOut` or either SQL query.
**Why it happens:** The `district_id` column (text like "1", "40", "At Large") exists in the `districts` table but was never selected into the DTO.
**How to avoid:** Add `d.district_id` to both `fetchOfficialsFromDB` queries and `GetPoliticianByID` query, and add `DistrictID string` to `OfficialOut` struct.
**Note:** This is a backend change required to support the subtitle feature.

### Pitfall 3: Chamber Name = Office Title for BallotReady LOCAL Officials
**What goes wrong:** Subtitle shows "Bloomington City Common Council - District 1, District 1" — double redundancy.
**Why it happens:** BallotReady stores a unique chamber per position for LOCAL officials; the chamber name equals the full position label, not a shared body name.
**How to avoid:** Detect when `chamber_name === office_title` and fall back to `district_label` alone, or parse out just the "Bloomington Common Council" portion.
**Warning signs:** Subtitle looks like a repeat of the title.

### Pitfall 4: Geofence MTFCC = '' for BallotReady Districts
**What goes wrong:** Imported city council polygons have `mtfcc = ''` because the districts table stores empty MTFCC for BallotReady data — but `FindGeoIDsByPoint` returns the MTFCC from `geofence_boundaries`, not from `districts`. So as long as the inserted boundary row has `mtfcc = 'X0001'`, the lookup will work correctly regardless of what's in `districts.mtfcc`.
**Why it happens:** The geofence query reads MTFCC from `geofence_boundaries.mtfcc`, not from `districts.mtfcc`. These are two separate tables.
**How to avoid:** Set `mtfcc = 'X0001'` explicitly on all imported city council boundary rows.

### Pitfall 5: party Field Still in API Response
**What goes wrong:** `party` and `party_short_name` fields are in `OfficialOut` and returned by the API. If any frontend code reads them to render UI, party data leaks into the display.
**Current status:** Confirmed no party badges currently render — `PoliticianCard.jsx` in ev-ui does not read party. The old local `PoliticianCard` (essentials/src/components/PoliticianCard.jsx, now unused) has a comment "Eventually add party logo here" but does not render party data. The sorters.js has a `partyKey` sort function but sorting by party is not currently active in the UI. **Party data is not currently displayed anywhere.** No code removal needed, but the backend can leave the field available for future use; frontend simply must not render it.

### Pitfall 6: total_years_in_office = 0 vs null for State/Federal Officials
**What goes wrong:** State EXEC officials from Cicero have `total_years_in_office = 0` (integer zero from COALESCE), not null. The profile display check `pol.total_years_in_office > 0` correctly hides the section for these. NATIONAL_EXEC officials are all 0. STATE_EXEC has a mix (some Cicero = 0, some BallotReady = populated). This is a **data gap**, not a display bug — the display logic already handles it correctly.
**Resolution:** No change needed. Document that years-in-office will not display for Cicero-sourced officials; this is expected behavior.

---

## Code Examples

### Adding district_id to OfficialOut (Go backend)

```go
// In handlers.go OfficialOut struct, add:
DistrictID string `json:"district_id,omitempty"`

// In fetchOfficialsFromDB queries, add to SELECT:
d.district_id,

// In Scan() call, add:
&off.DistrictID,

// In GetPoliticianByID row struct, add:
DistrictID string

// In GetPoliticianByID SELECT query, add:
d.district_id,
```

### Subtitle construction in PoliticianProfile.jsx (ev-ui)

```javascript
function buildSubtitle(pol) {
  const chamber = pol.chamber_name || '';
  const distId  = pol.district_id  || '';

  if (!chamber) return null;

  // BallotReady LOCAL: chamber_name equals office_title — use district_label
  if (chamber === pol.office_title) {
    return pol.district_label || null;
  }

  // Standard: "Indiana Senate, District 40"
  if (distId) {
    return `${chamber}, District ${distId}`;
  }

  return chamber;
}
```

### Term date label change in PoliticianProfile.jsx (ev-ui)

```javascript
// Replace current getTermLine() with labeled version:
function getTermLine(pol) {
  const start = formatTermDate(pol.term_start);
  if (!start) return null;
  const end = formatTermDate(pol.term_end);
  if (!end) return `Since ${start}`;
  return `First elected: ${start} \u2014 Term ends: ${end}`;
}
```

Note: "First elected" label technically refers to the start of the current term (from BallotReady's `valid_from`), not the original election. This is acceptable as a display label but may show a more recent date for multi-term incumbents.

### Initials avatar as circle in PoliticianProfile.jsx (ev-ui)

```javascript
// Change placeholder style from rectangle to circle:
placeholder: {
  width: isMobile ? '120px' : '192px',
  height: isMobile ? '120px' : '192px',   // equal height for circle
  borderRadius: '50%',
  background: colors.evTeal,               // EV brand color
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  color: '#ffffff',
  fontSize: isMobile ? fontSizes.xl : fontSizes['3xl'],
  fontWeight: fontWeights.bold,
},
```

### Adding subtitle prop to PoliticianCard.jsx (ev-ui)

```javascript
// New prop: subtitle (string, optional)
export default function PoliticianCard({ id, imageSrc, name, title, subtitle, onClick, ... }) {
  // In content section, after title:
  {subtitle && (
    <p style={styles.subtitle}>{subtitle}</p>
  )}
}

// New style:
subtitle: {
  fontFamily: fonts.primary,
  fontWeight: fontWeights.regular,
  fontSize: fontSizes.xs,
  color: colors.textMuted,
  margin: 0,
  marginTop: spacing[1],
  overflow: 'hidden',
  textOverflow: 'ellipsis',
  whiteSpace: 'nowrap',
},
```

### Passing subtitle to PoliticianCard in Results.jsx (essentials)

```javascript
function renderPoliticianCard(pol, handlePoliticianClick) {
  // Build subtitle: prefer chamber_name, fallback to district_label
  const subtitle = pol.chamber_name && pol.chamber_name !== pol.office_title
    ? (pol.district_id ? `${pol.chamber_name}, District ${pol.district_id}` : pol.chamber_name)
    : pol.district_label || null;

  return (
    <PoliticianCard
      id={pol.id}
      imageSrc={getImageUrl(pol)}
      name={`${pol.first_name} ${pol.last_name}`}
      title={pol.office_title}
      subtitle={subtitle || undefined}   // omit if empty to get 2-line fallback
      ...
    />
  );
}
```

### Removing Issues and Prioritization card from Profile.jsx (essentials)

```javascript
// In Profile.jsx, remove the entire JSX block:
<div className="bg-white rounded-lg shadow-lg p-4 sm:p-8">
  <h3 className="text-2xl font-bold text-[var(--ev-teal)] mb-6">
    Issues and Prioritization
  </h3>
  ... (entire section)
</div>

// Keep all state declarations and useEffect hooks intact
// (they have no side effects beyond setting local state).
// Optionally clean up unused state/hooks: topics, answersByShort,
// loadingCompass, invertedSpokes, showUserComparison, userAnswers.
// Removing them reduces bundle size but is optional for this phase.
```

### Geofence import for Bloomington city council districts

```sql
-- After obtaining GeoJSON boundaries for Districts 1–6:
-- Insert with mtfcc = 'X0001' and correct geo_id format
INSERT INTO essentials.geofence_boundaries (id, geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
VALUES (
  uuid_generate_v4(),
  '180586000001',       -- Bloomington District 1
  '',
  'Bloomington City Common Council District 1',
  '18',
  'X0001',
  ST_GeomFromGeoJSON('{ "type": "Polygon", "coordinates": [...] }'),
  'bloomington_open_data_2024',
  NOW()::text
);
-- Repeat for districts 2–6
```

```go
// In geofence_lookup.go, add X0001 to the MTFCC map:
var mtfccToDistrictTypes = map[string][]string{
  "G5210": {"STATE_UPPER"},
  "G5220": {"STATE_LOWER"},
  "G5200": {"NATIONAL_LOWER"},
  "G4020": {"COUNTY", "JUDICIAL"},
  "G4040": {"LOCAL", "LOCAL_EXEC"},
  "G4110": {"LOCAL", "LOCAL_EXEC"},
  "G5420": {"SCHOOL"},
  "X0001": {"LOCAL"},               // City council sub-districts (BallotReady/custom)
}
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| BallotReady API live fetch | Geofence-only from our DB | Means missing boundaries = missing officials permanently |
| Chamber name = body name (Cicero) | Chamber name = position label (BallotReady LOCAL) | Makes subtitle construction context-dependent |
| Rectangular photo placeholder | Initials placeholder (rectangular) | Phase 31 changes to circle |

---

## Open Questions

1. **LA County city council boundary data**
   - What we know: Zero G4110 or X0001 geofences exist for CA incorporated places
   - What's unclear: Which cities to prioritize; each city has its own data portal
   - Recommendation: Scope to Bloomington only for phase 31; create a follow-up phase for LA County with a proper data import pipeline

2. **"First elected" vs "Term start" label accuracy**
   - What we know: `valid_from` = start of current term, not original election date
   - What's unclear: User context decision about whether this matters for UX
   - Recommendation: Use "Term start:" and "Term ends:" labels instead — technically accurate, clearly labeled. Or keep "First elected" as the user decided with a note that it reflects current term start.

3. **Chamber name cleanup for BallotReady LOCAL officials**
   - What we know: `chamber_name` for Bloomington district council = same as `office_title` (e.g., "Bloomington City Common Council - District 1")
   - What's unclear: Is there a shared chamber name available elsewhere in the data model?
   - Recommendation: Use the fallback strategy in code: when `chamber_name === office_title`, display `district_label` directly as the subtitle. This is already the full human-readable label.

4. **Unused state cleanup in Profile.jsx**
   - What we know: Removing the Issues card leaves state hooks (topics, answersByShort, etc.) with no UI surface
   - What's unclear: User preference on cleanup scope
   - Recommendation: Remove the dead state and useEffect hooks in the same PR — they add bundle overhead and are confusing.

---

## Sources

### Primary (HIGH confidence)
- Direct DB query, Supabase project `zlbutxtrjcixpdgfzrgv` — confirmed zero geofences for Bloomington city council districts
- Source code read: `ev-ui/src/PoliticianProfile.jsx`, `ev-ui/src/PoliticianCard.jsx`, `essentials/src/pages/Profile.jsx`, `essentials/src/pages/Results.jsx`, `EV-Backend/internal/essentials/handlers.go`, `EV-Backend/internal/essentials/geofence_lookup.go`, `EV-Backend/internal/essentials/models.go`

### Secondary (MEDIUM confidence)
- [BallotReady support: Interpreting mtfcc and geo_id](https://support.ballotready.org/interpreting-mtfcc-and-geoid) — X0001 MTFCC for city council sub-districts
- [Census TIGER MAF/TIGER Feature Class Codes](https://www.census.gov/library/reference/code-lists/mt-feature-class-codes.html) — standard MTFCC codes (G4110, etc.)

---

## Metadata

**Confidence breakdown:**
- UI changes (Profile + Card): HIGH — code fully read, fields confirmed in API
- district_id gap: HIGH — confirmed absent from OfficialOut struct and SQL queries
- Geofence root cause: HIGH — confirmed via DB query, 6 Bloomington districts have no geofence rows
- X0001 MTFCC for city council: MEDIUM — from BallotReady support docs, cross-referenced with DB geo_id format
- LA County feasibility: LOW — no CA incorporated-place geofences exist; city-specific data collection effort unscoped
- total_years_in_office gap: HIGH — data gap for Cicero-sourced officials; display logic correct as-is

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (stable domain — no fast-moving dependencies)
