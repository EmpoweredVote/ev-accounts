---
phase: quick-5
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - EV-Backend/internal/essentials/handlers.go
  - EV-Backend/internal/essentials/routes.go
  - EV-Backend/scripts/seed_faizah.sql
  - essentials/src/lib/api.jsx
  - essentials/src/pages/Results.jsx
  - essentials/src/pages/CandidateProfile.jsx
  - essentials/src/App.jsx
autonomous: false
requirements: [CANDIDATE-PROFILE, CANDIDATE-CARDS, COMPASS-STANCES, CANDIDATE-FILTER]

must_haves:
  truths:
    - "Faizah Malik appears in candidate results when searching a District 11 address"
    - "Candidate cards have a subtle accent color border distinguishing them from incumbent cards"
    - "Clicking a candidate card navigates to a compact candidate profile page"
    - "Candidate profile page shows photo, bio, platform, compass radar chart, endorsements, and campaign website link"
    - "Compass badge appears on Faizah's candidate card when she has stances"
    - "Show Candidates toggle works for both ZIP and address queries"
  artifacts:
    - path: "essentials/src/pages/CandidateProfile.jsx"
      provides: "Compact candidate profile page"
      min_lines: 80
    - path: "EV-Backend/internal/essentials/handlers.go"
      provides: "Enhanced CandidateOut with UUID + images + SearchCandidates endpoint"
      contains: "SearchCandidates"
  key_links:
    - from: "essentials/src/pages/Results.jsx"
      to: "/candidate/:id route"
      via: "handlePoliticianClick for candidates with real UUID"
      pattern: "navigate.*candidate"
    - from: "essentials/src/lib/api.jsx"
      to: "/essentials/candidates/search"
      via: "fetchCandidates POST for address queries"
      pattern: "candidates/search"
    - from: "essentials/src/pages/CandidateProfile.jsx"
      to: "/essentials/politician/:id"
      via: "fetchPolitician for candidate data"
      pattern: "fetchPolitician"
---

<objective>
Create a candidate profile system with Faizah Malik (LA City Council District 11) as test case. Includes: enhanced backend CandidateOut with UUID/images, address-based candidate search endpoint, accent-colored candidate cards (no badge text), compact candidate profile page with compass radar chart, and Faizah's compass stances inserted via SQL.

Purpose: Enable users to discover and learn about political candidates alongside incumbents, with compass stance comparison.
Output: Working candidate flow — search address, see accent-colored candidate cards, click to view compact candidate profile with radar chart.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/quick/5-create-candidate-profile-system-with-com/5-CONTEXT.md

<interfaces>
<!-- Key types and contracts the executor needs -->

From EV-Backend/internal/essentials/models.go — existing candidate models:
```go
type ElectionRecord struct {
  ID                  uuid.UUID `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
  PoliticianID        uuid.UUID `json:"politician_id" gorm:"type:uuid;index"`
  CandidacyExternalID string    `json:"candidacy_external_id" gorm:"uniqueIndex"`
  ElectionName        string    `json:"election_name"`
  ElectionDate        string    `json:"election_date"`
  PositionName        string    `json:"position_name"`
  Result              string    `json:"result"`
  Withdrawn           bool      `json:"withdrawn"`
  PartyName           string    `json:"party_name"`
  IsPrimary           bool      `json:"is_primary"`
  IsRunoff            bool      `json:"is_runoff"`
  IsUnexpiredTerm     bool      `json:"is_unexpired_term"`
  IsActive            bool      `json:"is_active" gorm:"default:false"`
}

type Politician struct { /* full struct in models.go — has ID (uuid), Images, Degrees, Experiences, BioText, etc. */ }
type PoliticianImage struct { ID, PoliticianID uuid.UUID; URL, Type, PhotoLicense string }
type Endorsement struct { ID, PoliticianID uuid.UUID; EndorserString, Status, ElectionDate string; Organization *EndorserOrganization }
```

From EV-Backend/internal/essentials/handlers.go — current CandidateOut (needs enhancement):
```go
type CandidateOut struct {
  ExternalID        int    `json:"external_id"`       // NO UUID — frontend uses `candidate-${external_id}` fake ID
  FirstName         string `json:"first_name"`
  LastName          string `json:"last_name"`
  FullName          string `json:"full_name"`
  PhotoOriginURL    string `json:"photo_origin_url,omitempty"`  // NO images array
  OfficeTitle       string `json:"office_title"`
  DistrictType      string `json:"district_type"`
  Party             string `json:"party,omitempty"`
  PartyShortName    string `json:"party_short_name,omitempty"`
  IsCandidate       bool   `json:"is_candidate"`
  ElectionDate      string `json:"election_date"`
  ElectionName      string `json:"election_name"`
  IsPrimary         bool   `json:"is_primary"`
  IsRunoff          bool   `json:"is_runoff"`
  RepresentingState string `json:"representing_state,omitempty"`
  ChamberName       string `json:"chamber_name,omitempty"`
}
```

From EV-Backend/internal/compass/models.go — compass answer model:
```go
type Answer struct {
  ID           string    `gorm:"primaryKey" json:"id"`
  PoliticianID uuid.UUID `json:"politician_id" gorm:"index:idx_pol_topic"`
  TopicID      uuid.UUID `json:"topic_id" gorm:"index:idx_pol_topic"`
  Value        float64   `gorm:"default: 0" json:"value"`
}
```

From essentials/src/lib/api.jsx — current fetchCandidates (returns [] for non-ZIP):
```js
export async function fetchCandidates(zipOrQuery) {
  const zip = /^\d{5}$/.test(zipOrQuery) ? zipOrQuery : null;
  if (!zip) { return []; }  // BUG: address queries silently return empty
  // ...
}
```

From essentials/src/pages/Results.jsx — candidate rendering (line 455):
```js
// Currently: onClick={isCandidate ? undefined : () => handlePoliticianClick(pol.id)}
// Currently: badge={isCandidate ? 'Candidate' : undefined}
// Currently: pol.id for candidates = `candidate-${c.external_id}` (fake, not UUID)
```

From ev-ui/src/PoliticianCard.jsx — card accepts style prop for overrides:
```jsx
export default function PoliticianCard({ id, imageSrc, name, title, subtitle, onClick, onCompassClick, variant, style, badge })
// style prop merges into card container styles — can add borderLeft, backgroundColor, etc.
```

From ev-ui/src/tokens.js — design system colors:
```js
evCoral: '#ff5740',
evYellow: '#fed12e',
evYellowLight: '#fef3c7',
evTeal: '#00657c',
```

From essentials/src/App.jsx — current routes:
```jsx
<Route path="/" element={<Landing />} />
<Route path="/results" element={<Results />} />
<Route path="/politician/:id" element={<Profile />} />
<Route path="/politician/:id/record" element={<LegislativeRecord />} />
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Backend — Enhance CandidateOut, add address-based candidate search, insert Faizah Malik data</name>
  <files>
    EV-Backend/internal/essentials/handlers.go
    EV-Backend/internal/essentials/routes.go
    EV-Backend/scripts/seed_faizah.sql
  </files>
  <action>
**1a. Enhance CandidateOut struct** (in handlers.go near line 2661):

Add UUID ID and images array to `CandidateOut`:
```go
type CandidateOut struct {
  ID                string            `json:"id"`                          // NEW: politician UUID as string
  ExternalID        int               `json:"external_id"`
  FirstName         string            `json:"first_name"`
  LastName          string            `json:"last_name"`
  FullName          string            `json:"full_name"`
  PhotoOriginURL    string            `json:"photo_origin_url,omitempty"`
  Images            []PoliticianImage `json:"images,omitempty"`            // NEW: full images array
  OfficeTitle       string            `json:"office_title"`
  DistrictType      string            `json:"district_type"`
  Party             string            `json:"party,omitempty"`
  PartyShortName    string            `json:"party_short_name,omitempty"`
  IsCandidate       bool              `json:"is_candidate"`
  ElectionDate      string            `json:"election_date"`
  ElectionName      string            `json:"election_name"`
  IsPrimary         bool              `json:"is_primary"`
  IsRunoff          bool              `json:"is_runoff"`
  RepresentingState string            `json:"representing_state,omitempty"`
  ChamberName       string            `json:"chamber_name,omitempty"`
  DistrictID        string            `json:"district_id,omitempty"`       // NEW: for subtitle (e.g. "District 11")
}
```

**1b. Update GetCandidatesByZip** to return the new fields:
- Add `p.id` (UUID) to the SQL SELECT as `politician_id`
- Add `COALESCE(d.district_id, '') AS district_id_text` to SELECT
- Add `politician_id` to the candidateRow struct as `uuid.UUID`
- After building the candidates slice, fetch images for all candidate politician IDs in a single query:
  ```go
  polIDs := make([]uuid.UUID, 0, len(rows))
  for _, row := range rows { polIDs = append(polIDs, row.PoliticianID) }
  var images []PoliticianImage
  db.DB.Where("politician_id IN ?", polIDs).Find(&images)
  ```
- Group images by politician_id into a map and attach to each CandidateOut
- Set `ID: row.PoliticianID.String()` and `DistrictID: row.DistrictIDText` for each candidate

**1c. Create SearchCandidates endpoint** (POST /candidates/search):
- Accept same `{"query": "..."}` body as SearchPoliticians
- Require GeoClient (same check as SearchPoliticians)
- Geocode the query, then use existing geofence helpers:
  - For area queries: call `ResolveAreaBoundary` + `FindGeoIDsByAreaIntersection`, fallback to `FindGeoIDsByPoint`
  - For point queries: call `FindGeoIDsByPoint`
- With the matched geo_ids, query candidates:
  ```sql
  SELECT p.id AS politician_id, p.external_id, p.first_name, p.last_name, p.full_name,
    COALESCE(p.photo_custom_url, NULLIF(p.photo_origin_url, '')) AS photo_origin_url,
    o.title AS office_title, d.district_type,
    COALESCE(p.party, '') AS party, COALESCE(p.party_short_name, '') AS party_short_name,
    er.election_date, er.election_name, er.is_primary, er.is_runoff,
    COALESCE(o.representing_state, '') AS representing_state,
    COALESCE(c.name, '') AS chamber_name,
    COALESCE(d.district_id, '') AS district_id_text
  FROM essentials.election_records er
  JOIN essentials.politicians p ON p.id = er.politician_id
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE er.is_active = true AND er.withdrawn = false
    AND d.geo_id IN (geo_ids_from_matches)
  ```
  Extract district geo_ids from the `[]GeoMatch` returned by the geofence helpers (each has a GeoID field).
- Also supplement with state/federal active candidates by representing_state (same pattern as SearchPoliticians).
- Fetch images for all returned candidates (same batch pattern as 1b).
- Return `[]CandidateOut` with UUID, images, district_id.
- Register route in routes.go: `r.Post("/candidates/search", SearchCandidates)`

**1d. Create seed SQL script** at `EV-Backend/scripts/seed_faizah.sql`:

The script should be idempotent (use DO $$ blocks with existence checks or ON CONFLICT). Include:

1. **Politician record** — essentials.politicians:
   - first_name: "Faizah", last_name: "Malik", full_name: "Faizah Malik"
   - party: "Democratic", party_short_name: "D"
   - bio_text: "Public interest attorney with 15+ years advocating for renters, immigrants, and working families in Los Angeles."
   - data_source: "manual", is_active: true

2. **Office record** — Look up existing LA City Council chamber_id and LOCAL district for district_id "11" in LA:
   ```sql
   SELECT id FROM essentials.chambers WHERE name LIKE '%Los Angeles City Council%' LIMIT 1;
   SELECT id FROM essentials.districts WHERE district_type = 'LOCAL' AND district_id = '11' AND city = 'Los Angeles' LIMIT 1;
   ```
   - title: "Los Angeles City Council", representing_city: "Los Angeles", representing_state: "CA"

3. **Election record** — essentials.election_records:
   - election_name: "2026 Los Angeles City Council District 11"
   - election_date: "2026-06-02", is_active: true, withdrawn: false
   - candidacy_external_id: "manual-faizah-malik-2026" (unique key)

4. **zip_politicians** — ZIP codes for District 11:
   90049, 90066, 90291, 90293, 90094, 90045, 90056, 90064, 90272

5. **Compass stances** — compass.answers with politician_id:
   Query `SELECT id, short_title FROM compass.topics WHERE is_active = true;` first to find matching topic IDs. Map her 6 platform areas to the closest existing topics. Use strong support values (1.5-2.0).

6. **Endorsements** — essentials.endorsements:
   SEIU Local 721, DSA-LA, Unite Here! Local 11, CA Working Families Party, LA County Federation of Labor
   - endorser_string: org name, status: "endorsed", recommendation: "PRO"
   - candidacy_external_id: "manual-faizah-malik-2026"

7. **Campaign website** — Set urls array on the politician record to include "https://www.faizahforla.com"
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go build -o /dev/null . 2>&1</automated>
  </verify>
  <done>
    - CandidateOut includes `id` (UUID string), `images` array, and `district_id` fields
    - GetCandidatesByZip returns candidates with real UUIDs and images
    - SearchCandidates endpoint accepts POST with address query and returns candidates
    - Route registered in routes.go
    - Faizah Malik seed SQL ready in EV-Backend/scripts/seed_faizah.sql
    - Backend compiles successfully
  </done>
</task>

<task type="auto">
  <name>Task 2: Frontend — Accent-colored candidate cards, address-based candidate fetch, candidate profile page</name>
  <files>
    essentials/src/lib/api.jsx
    essentials/src/pages/Results.jsx
    essentials/src/pages/CandidateProfile.jsx
    essentials/src/App.jsx
  </files>
  <action>
**2a. Update fetchCandidates in api.jsx** to support address queries:

Replace the early-return for non-ZIP queries with a POST to the new search endpoint:
```js
export async function fetchCandidates(zipOrQuery) {
  try {
    const isZip = /^\d{5}$/.test(zipOrQuery);

    if (isZip) {
      // ZIP: use existing GET endpoint
      const res = await fetch(`${API}/essentials/candidates/${zipOrQuery}`, {
        credentials: "include",
        cache: "no-store",
      });
      if (!res.ok) return [];
      return res.json();
    }

    // Address: use new POST search endpoint
    const res = await fetch(`${API}/essentials/candidates/search`, {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query: zipOrQuery }),
    });
    if (!res.ok) return [];
    return res.json();
  } catch (error) {
    console.error("Error fetching candidates:", error);
    return [];
  }
}
```

Also add a new `fetchEndorsements` function:
```js
export async function fetchEndorsements(id) {
  try {
    const res = await fetch(`${API}/essentials/politician/${id}/endorsements`, { credentials: "include" });
    if (!res.ok) return [];
    return res.json();
  } catch { return []; }
}
```

**2b. Update Results.jsx candidate rendering:**

Per user decision: use accent color differentiation, NOT badge text.

In `renderPoliticianCard`, make these changes:
- REMOVE: `badge={isCandidate ? 'Candidate' : undefined}` — no badge text at all for candidates
- ADD accent color style via the `style` prop on PoliticianCard for candidate cards:
  ```jsx
  style={isCandidate ? { borderLeft: '4px solid #fed12e', backgroundColor: '#fffef5' } : {}}
  ```
  This gives candidates a subtle gold left-border + very slight warm background tint.

- Enable clicking for candidates. Change `onClick`:
  ```jsx
  onClick={() => {
    if (isCandidate) {
      // Save scroll position before navigating
      const scrollTop = isDesktop ? mainRef.current?.scrollTop ?? 0 : window.scrollY;
      sessionStorage.setItem('ev:scrollTop', String(scrollTop));
      navigate(`/candidate/${pol.id}`);
    } else {
      handlePoliticianClick(pol.id);
    }
  }}
  ```

- Update `classifiedCandidates` useMemo (near line 332): Since CandidateOut now returns a real UUID in the `id` field, stop generating fake IDs. Change from:
  ```jsx
  pol: { ...c, id: `candidate-${c.external_id}` },
  ```
  to:
  ```jsx
  pol: { ...c },
  ```
  The `id` and `is_candidate` fields now come directly from the API response.

**2c. Create CandidateProfile.jsx** — compact candidate-specific profile page:

New file at `essentials/src/pages/CandidateProfile.jsx`. This is a COMPACT page — NOT the full incumbent PoliticianProfile from ev-ui. No legislative sections (candidates don't have voting records).

Imports:
```jsx
import { useParams, useNavigate } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { fetchPolitician, fetchEndorsements } from '../lib/api';
import { SiteHeader, RadarChartCore } from '@chrisandrewsedu/ev-ui';
import { useCompass } from '../contexts/CompassContext';
```

Data fetching in useEffect:
- `fetchPolitician(id)` — returns full politician data (bio_text, urls, images, office info)
- `fetchEndorsements(id)` — returns endorsement records
- Fetch compass answers: `fetch(\`${API}/compass/politicians/${id}/answers\`)` — returns array of {topic_id, value}

Layout (single column, max-w-2xl mx-auto, px-4 py-6):

1. **SiteHeader** — same as other pages: `<SiteHeader logoSrc="/EVLogo.svg" />`

2. **Back button** — styled text button: "Back to results". Use sessionStorage pattern from Profile.jsx:
   ```jsx
   onClick={() => {
     try {
       const cached = sessionStorage.getItem('ev:results');
       if (cached) { const { query } = JSON.parse(cached); navigate(`/results?q=${encodeURIComponent(query)}`); return; }
     } catch {}
     navigate('/');
   }}
   ```

3. **Header section** — flex row (stack on mobile):
   - Photo: 120px rounded-full, use `getImageUrl(pol)` pattern from Results.jsx. Show initials placeholder if no image.
   - Name: text-2xl font-bold text-[#00657c]
   - Party badge: small pill (e.g. "Democratic" in gray-100 rounded-full)
   - Office title + district subtitle below name

4. **Election banner** — div with left gold border (border-l-4 border-[#fed12e]) and light gold bg (bg-[#fffef5]):
   - "Running for [position_name]"
   - Election date formatted nicely
   - Election name

5. **Bio section** — heading "About" + bio_text paragraph

6. **Compass section** — if politician has compass answers:
   - Heading "Political Compass"
   - RadarChartCore at 250px showing candidate stances
   - If user also has compass answers (from CompassContext), show dual overlay (pink user + blue candidate) — same pattern as CompassPreview
   - If no user answers, show candidate-only (single blue dataset)
   - Map topic_ids from answers to topic short_titles using allTopics from CompassContext

7. **Endorsements section** — if endorsements exist:
   - Heading "Endorsements"
   - Display as flex-wrap pills/badges: each endorsement's endorser_string or organization.name
   - Styled: bg-gray-100 rounded-full px-3 py-1 text-sm

8. **Campaign website** — if pol.urls array has entries:
   - "Visit Campaign Website" button, styled with ev-coral bg, white text, rounded-lg, opens in new tab
   - Use first URL from the array (or the one matching faizahforla.com)

Loading state: spinner (same pattern as Profile.jsx)

**2d. Add route in App.jsx:**
```jsx
import CandidateProfile from "./pages/CandidateProfile";
```
Add inside Routes:
```jsx
<Route path="/candidate/:id" element={<CandidateProfile />} />
```
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build 2>&1</automated>
  </verify>
  <done>
    - fetchCandidates works for both ZIP and address queries
    - fetchEndorsements function added to api.jsx
    - Candidate cards display with gold left-border accent (no "Candidate" badge text per user decision)
    - Clicking a candidate card navigates to /candidate/:id
    - CandidateProfile page renders with photo, bio, election banner, compass radar chart, endorsements, campaign link
    - Route /candidate/:id registered in App.jsx
    - essentials builds successfully
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 3: Verify candidate profile system end-to-end</name>
  <files>n/a</files>
  <action>Human verification of the complete candidate flow.</action>
  <verify>Manual testing per steps below.</verify>
  <done>User confirms candidate cards and profile page work correctly.</done>
  <what-built>
    Complete candidate profile system with Faizah Malik as test case:
    1. Enhanced backend CandidateOut with UUID and images
    2. Address-based candidate search endpoint (POST /candidates/search)
    3. Accent-colored candidate cards (gold border, no badge text)
    4. Compact candidate profile page with compass radar chart
    5. Faizah Malik data seed SQL
  </what-built>
  <how-to-verify>
    1. Start backend: `cd EV-Backend && go run .`
    2. Run the seed SQL in `EV-Backend/scripts/seed_faizah.sql` against the database
    3. Start frontend: `cd essentials && npm run dev`
    4. Search for a District 11 address (e.g., "1200 Getty Center Drive, Los Angeles, CA 90049")
    5. Toggle "Show Candidates" — verify Faizah Malik appears with a gold left-border accent (no "Candidate" text badge)
    6. Verify compass badge appears on her card (hexagon icon)
    7. Click her card — verify it navigates to /candidate/{uuid}
    8. On the candidate profile page, verify:
       - Photo, name, party, office title visible
       - Election banner with gold accent and date shown
       - Bio text displays
       - Compass radar chart renders with her stances
       - Endorsements listed (SEIU Local 721, DSA-LA, etc.)
       - Campaign website link present and opens faizahforla.com
    9. Test mobile layout — verify responsive stacking
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues to fix</resume-signal>
</task>

</tasks>

<verification>
- `cd EV-Backend && go build -o /dev/null .` compiles without errors
- `cd essentials && npm run build` succeeds
- CandidateOut JSON includes `id` (UUID), `images`, `district_id` fields
- POST /essentials/candidates/search returns candidates for LA addresses
- Candidate cards render with gold accent border, no badge text
- /candidate/:id route loads CandidateProfile component
- Compass radar chart renders on candidate profile when stances exist
</verification>

<success_criteria>
- Faizah Malik appears in search results for District 11 addresses with accent-colored card
- Clicking her card opens a compact candidate profile page (not the full incumbent profile)
- Profile shows compass radar chart with her mapped stances
- Endorsements and campaign website link visible on profile
- Show Candidates toggle works for both ZIP and address-based searches
</success_criteria>

<output>
After completion, create `.planning/quick/5-create-candidate-profile-system-with-com/5-SUMMARY.md`
</output>
