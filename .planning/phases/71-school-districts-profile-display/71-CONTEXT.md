# Phase 71: School Districts + Profile Display - Context

**Gathered:** 2026-05-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Import CA school district TIGER data (unified, elementary, secondary layers) into `essentials.geo_districts`, extend `cache_user_districts` to include school layers, display school district on the existing Location tab of the profile page for both tiers, and wire school districts into the Path 0 politicians-representing-me join (returns empty until school board members are added to `essentials.politicians`). School board politician ingestion is a separate future phase.

</domain>

<decisions>
## Implementation Decisions

### Display logic (unified vs. elementary+secondary overlap)

- A user in a unified district gets a single "School District" entry with the full TIGER name verbatim (e.g., "Los Angeles Unified School District")
- A user in an elementary + secondary district (no unified) gets **two labeled sub-entries**: "Elementary School District: [Name]" and "Secondary School District: [Name]" — they are genuinely distinct districts
- Zero-match (user outside CA, or location not yet set): hide the school district section entirely — no placeholder, no "not available" message
- District name is a **Google search link** (e.g., `https://www.google.com/search?q=Los+Angeles+Unified+School+District`). TIGER does not include website URLs and NCES CCD doesn't reliably provide them either. Upgrade to direct URL in a future pass when a URL source exists.

### Profile placement

- School district appears in the **existing Location tab** on `admin/src/pages/ProfilePage.tsx` — not a new tab
- The Location tab is where district info, address/coordinates, and location recalibration already live
- **Both tiers** see school district (Connected and Inform) — show it for any user who has a location on file (cached user_districts for Connected; location-hint lat/lng for Inform)
- At Phase 71 launch, the school district display is: district name + Google search link. No board member section. No "coming soon" placeholder.

### Politicians-me scope

- **Wire the join now** — extend `essentials.cache_user_districts` default `p_layers` array to include `school_unified`, `school_elementary`, `school_secondary`. The Path 0 `representatives/me` join naturally picks up all `user_districts` rows per user; school district rows will return zero politicians until board members are added to `essentials.politicians` and `essentials.districts` tiger_geoids are populated for them.
- School board members (when they exist) go in the **main "All" feed** alongside assembly/senate/congress representatives — no separate endpoint
- Future filter tabs (Federal / State / Local / School) will use `district_type` on `essentials.districts` — no additional tagging needed in the response payload
- **`GET /api/account/districts` stays legislative only** — school layers are NOT added to that endpoint's response. School district is surfaced on the profile, not the districts endpoint.

### Claude's Discretion

- Exact layout position of school district within the Location tab (above or below legislative districts, before or after recalibration controls)
- Whether `cache_user_districts` is updated via a migration to its default `p_layers` array or via a Node.js call with explicit layer override

</decisions>

<specifics>
## Specific Ideas

- "If it's just name and link, let's put it on the profile page under the 'Location' tab. This is where we list all of your locations, and where you can re-calibrate your location."
- "For now, we will have the one (unnamed) 'All' tab [for representatives], that includes everyone — eventually, we may parse the different categories (All, Federal, State, Local, School)"
- Google search link preferred over NCES lookup for URLs — NCES doesn't reliably have district website URLs, and a Google search delivers the same result in one extra click with zero ETL work

</specifics>

<deferred>
## Deferred Ideas

- **Dedicated "School" filter tab** on representatives/me feed — future phase when school board members are populated in `essentials.politicians`
- **Direct district website links** — add a `website_url` column to `essentials.geo_districts` (or a separate enrichment table) when a reliable URL source is identified; replace Google search links with direct links then
- **School board politician ingestion** — separate future phase; Phase 71 only imports the geographic boundary data and wires the query join (which returns empty until this exists)

</deferred>

---

*Phase: 71-school-districts-profile-display*
*Context gathered: 2026-05-09*
