# Feature Research

**Domain:** Local government organization display — civic engagement / politician discovery app
**Researched:** 2026-03-10
**Confidence:** HIGH (existing codebase fully inspected; Indiana government structure verified via official state and county sources)

---

## Context: What Already Exists

This is a subsequent milestone. The Essentials app already has:

- Full politician discovery pipeline with PostGIS geofence matching, 3-tier Federal/State/Local classification
- `classify.js` with `LOCAL_ORDER` categories: Municipal Executives, City Council, Municipal Officials, Township Officials, County Executives, County Legislators, County Officials, School Board, Local Judiciary, Local Departments & Special Districts
- `qualifyTitle()` in `PoliticianGrid.jsx` that prepends `government_name` to generic card titles (e.g., "City Council" on a card → "Bloomington City Council")
- `government_name`, `chamber_name_formal`, `chamber_name`, `district_label`, `district_type` all in `OfficialOut` API response — no new backend fields needed for body name qualification
- `ContactOut` with `website_url` on individual politician contacts, but no body-level website field
- Section headings in the Results page currently use the raw classify category name (e.g., "County Legislators"), not the qualified body name

The gaps this milestone closes:
1. Section headings say "County Council" not "Monroe County Council"
2. Commissioners and council are grouped together as "County Legislators"
3. No official website link shown at the body/section level
4. No distinction between at-large and district council members in the display

---

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Specific body name in section heading | "County Council" is ambiguous — users expect to know which county's council this is, especially users at county boundaries | LOW | `government_name` + `chamber_name_formal` already in API response. `qualifyTitle()` already applies this logic to individual politician cards. Extend same logic to section/category headings. Zero backend changes needed. |
| Distinct sections for commissioners vs. council | Indiana: Board of Commissioners = executive/administrative. County Council = fiscal/legislative. These are separate elected bodies with different roles. Grouping them as "County Legislators" obscures both. | LOW | Pure frontend change. Update `classify.js` to route title keyword "commissioner" → "County Commissioners" group and "council member" → "County Council" group within COUNTY district type. |
| Elected county officials as their own section | Sheriff, Assessor, Clerk, Treasurer, Recorder, Coroner, Surveyor are independently elected officials with no council/commission role. Grouping them alongside legislators is misleading. | LOW | "County Officials" category already exists in `LOCAL_ORDER` and `classify.js` has this code path. Needs consistent enforcement — some fall-through paths currently land them in the wrong group. |
| Township body name specificity | "Township Officials" is generic. Users in Perry Township expect "Perry Township Trustee" not a generic bucket. | LOW | Same heading-qualification fix as county; `government_name` already contains township name for records in the DB. |
| Official website link per section | Users who want to attend a meeting or contact "the council" need the body's website, not individual member contact pages. Every comparable civic directory (Ballotpedia, BallotReady) links to the official body website. | MEDIUM | Requires one new DB field: `website_url` on the `chambers` table (or a minimal new lookup table). Manual data entry for the two covered jurisdictions (Monroe County IN + Bloomington IN). Render as a link icon or "Official website" link in the section heading row. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| At-large vs. district member badge | Indiana county councils: 4 district + 3 at-large. Bloomington city council: 6 district + 3 at-large. Surfacing "District 2" vs "At-Large" helps users understand which members are specifically accountable to their neighborhood vs. the jurisdiction at large. | LOW | `district_label` field already in `OfficialOut`. Requires only a frontend rendering change — add a badge or subtitle on council member cards. "At-Large" label when district is null or district_label contains "at-large". |
| Role description under section heading | A one-sentence explanation of the body's function (e.g., "Executive and administrative authority for the county") gives context without requiring users to already know what commissioners do. | LOW | Entirely static copy, keyed by body type. Meaningful only after section headings are specific. Ship after heading names are correct. |
| State-configurable body structure | California counties use Board of Supervisors (5 members, no separate council). Indiana uses the commissioners + council split. A config-driven structure (even a simple constant map) enables clean expansion to new states without code changes. | MEDIUM | Keep scope to Indiana in this milestone; implement as named Indiana-specific constants. Design the interface so adding a CA county config is a config change, not a code change. Defer full generalization to a future milestone. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Automated body website discovery | "Scrape or use Google to find official websites for all bodies" | Official government sites are inconsistently structured; automated discovery produces wrong URLs frequently and is hard to validate. Ongoing maintenance burden for a 2-3 person nonprofit team. | Manual data entry for covered jurisdictions (2 counties). Build an admin form or script. Verified data outperforms automated noise at this scale. |
| Full meeting calendar / agenda embed | "Show upcoming meetings" is an obvious civic utility | Requires real-time scraping or integration with a per-jurisdiction calendar source. Maintenance is enormous and varies per city. | Link to the body's official meetings page. One URL, zero maintenance after initial data entry. |
| Organizational chart / hierarchy visualization | "Show how commissioners, council, and officials relate" | High design complexity. Varies by state and county. Confusing for most users and not the right tool for discovery. | Section ordering (commissioners before council before officials) plus a brief role description implicitly communicates the hierarchy. |
| At-large member seating by fake district | "Show which at-large members represent which areas" | At-large means no district. Creating artificial districts is misleading and inaccurate. | Label "At-Large" clearly with no district badge. Do not invent districts. |
| Full elected official roster for all Indiana counties | "Show all 92 Indiana counties' bodies with specific names" | Geofence data only covers Monroe County currently. Showing specific names for bodies we have no politicians for creates an empty section problem. | Apply improvements only to covered jurisdictions. The heading qualification logic will apply automatically as new counties are added via the existing pipeline. |

---

## Feature Dependencies

```
[Specific body names in section headings]
    └──requires──> government_name populated for covered officials  [ALREADY MET]
    └──requires──> chamber_name_formal populated for covered officials  [ALREADY MET]
    └──note──> Pure frontend change to Results.jsx section header rendering

[Commissioners vs. council distinct sections]
    └──requires──> classify.js updated to split COUNTY district type by title keyword
    └──enhances──> Specific body names in section headings (each body now has its own section to label)

[County Officials as distinct section]
    └──requires──> classify.js county official fall-through paths cleaned up
    └──independent──> Can be done alongside commissioners/council split

[Official website link per section]
    └──requires──> website_url field added to chambers table in DB
    └──requires──> Manual data entry: Monroe County Commissioners, Monroe County Council, Bloomington City Council, Monroe County elected officials page
    └──requires──> Frontend: render website_url as link in CategorySection header
    └──requires──> Backend: include website_url in API response (OfficialOut.ChamberWebsiteURL or separate endpoint)

[At-large vs. district badge]
    └──requires──> district_label already in OfficialOut  [ALREADY MET]
    └──requires──> Frontend render change: show district_label as badge/subtitle on council cards
    └──depends-on──> Commissioners vs. council distinct sections (so badge appears in correct section)
```

### Dependency Notes

- **Section heading qualification and classify.js fixes are fully independent from the website link feature.** They can ship in any order or together.
- **Website links require the only new backend addition:** `website_url` on `chambers`. If chambers can have multiple URLs (e.g., main site and meeting page), a separate `chamber_links` table is cleaner — but a single `website_url` string is sufficient for MVP.
- **At-large vs. district badge requires no data changes.** `district_label` is already in the API. This is a pure rendering addition.
- **State-configurable structure** should be designed as a simple constant map (body type → body config) so Indiana rules are not hardcoded in `if (state === "IN")` branches. The map can be expanded to California later.

---

## MVP Definition

### Launch With (v2026.3.3)

Scoped to currently covered jurisdictions: Monroe County / Bloomington, Indiana. LA County improvements apply automatically from the same heading-qualification fix.

- [ ] **Specific body name in section headings** — Apply `qualifyTitle()` logic to `CategorySection` headings in `Results.jsx`. "County Council" → "Monroe County Council". Zero backend changes. HIGH value, LOW effort.
- [ ] **Distinct commissioners vs. council sections** — Update `classify.js` to route `COUNTY` district type officials with "commissioner" title to a new "County Commissioners" group (separate from "County Legislators" / "County Council"). Three-way split: commissioners, council, officials.
- [ ] **County Officials consistently distinct** — Audit and fix `classify.js` code paths so sheriff, auditor, treasurer, assessor, recorder, coroner, surveyor all reliably land in "County Officials" and not in commissioners or council groups.
- [ ] **Official website link per section** — Add `website_url` to `chambers` table. Enter URLs for Monroe County Board of Commissioners, Monroe County Council, Bloomington City Council (9 members, 6 district + 3 at-large), Monroe County elected officials page. Add `chamber_website_url` to `OfficialOut`. Render as "Official website" link in section heading. Gracefully absent when URL is null.
- [ ] **Township body names via heading qualification** — Same heading-qualification fix already covers townships; Perry Township Trustee appears instead of "Township Officials" with no extra work.

### Add After Validation (v1.x)

- [ ] **At-large vs. district badge** — Surface `district_label` as a visible badge/subtitle on council member cards. Trigger: after heading names are specific enough that users start looking at individual member distinctions.
- [ ] **Role description under section heading** — One-sentence static copy per body type explaining its function. Low effort once headings are specific. Trigger: user feedback indicating confusion about what commissioners vs. council do.
- [ ] **LA County Board of Supervisors heading** — "Board of Supervisors" already comes from `chamber_name_formal`; heading qualification will produce "Los Angeles County Board of Supervisors" automatically. Verify this renders correctly post-heading-fix.

### Future Consideration (v2+)

- [ ] **State-configurable body config** — Full pluggable config map for different state models (California Board of Supervisors vs. Indiana commissioners + council). Needed when expanding to a third state.
- [ ] **Meeting/agenda deep links** — Per-body meeting schedule URL in addition to general body website. Add after general website links are live and users ask for more depth.
- [ ] **New county/state expansion** — Each new county requires geofence import, politician data, and body website data entry. The pipeline is repeatable. Website data entry is the new manual step.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Specific body names in section headings | HIGH | LOW — frontend only, all data exists | P1 |
| Commissioners vs. council split | HIGH | LOW — classify.js keyword change | P1 |
| County Officials distinct section (cleanup) | MEDIUM | LOW — classify.js consistency fix | P1 |
| Official website link per section | HIGH | MEDIUM — new DB field + data entry + frontend | P1 |
| Township name via heading qualification | MEDIUM | LOW — covered by heading fix automatically | P1 |
| At-large vs. district badge | MEDIUM | LOW — data exists, rendering change only | P2 |
| Role description under heading | LOW | LOW — static copy | P2 |
| State-configurable body config | HIGH (future expansion) | MEDIUM | P3 |
| Meeting/agenda deep links | MEDIUM | LOW — additional URL field | P3 |

---

## Competitor Feature Analysis

| Feature | Ballotpedia | BallotReady | Google Civic Info API | Our Approach |
|---------|-------------|-------------|----------------------|--------------|
| Specific body names | Full official names on all body pages (e.g., "Monroe County Board of Commissioners") | Uses specific body names in office data | Returns `officeName` + `divisionName` separately; client must compose | Compose from `government_name` + `chamber_name_formal` in section heading — data already available |
| Official body website link | Links to official government website on body pages | Includes `websiteUrl` on office records | Returns `urls` per official, not per body | Add `website_url` to `chambers` table; one canonical URL per body |
| Commissioners vs. council distinction | Separate pages per body | Separate position entries per body type | Separate `offices` in response keyed by OCD-ID | Separate `classify.js` groups by COUNTY district type + title keyword |
| At-large vs. district distinction | Noted on member profile pages | `district_name` field populated | `district` field on office | Surface existing `district_label` as a badge in the card |
| State-specific body structure | Full wiki coverage per state | Normalized across states via position type | OCD-ID hierarchy reflects state structure | Start with Indiana-specific rules as named constants; generalize to config map for v2 |

**Key observation:** BallotReady already stores `websiteUrl` per office. Google Civic Information API returns `officeName` (e.g., "County Council Member, District 2") per division, meaning the industry standard is to present fully qualified names at the display layer — exactly what this milestone does.

---

## Indiana-Specific Structure Reference

Verified via Monroe County official sites and Indiana state resources:

**County government (same structure across all 92 Indiana counties):**
- **Board of Commissioners** — 3 members, elected countywide from geographic districts, executive/administrative authority, contract management, property maintenance. Website pattern: `co.[county].in.us/commissioners/` or `in.gov/counties/[county]/government/commissioners/`. Monroe County: `co.monroe.in.us/commissioners/`
- **County Council** — 7 members (4 district-elected + 3 at-large), fiscal/legislative authority, sets annual budget, sets salaries, authorizes spending. Staggered 4-year terms. Website: `co.monroe.in.us/council/`
- **Elected county officials** — Sheriff, Auditor, Treasurer, Recorder, Assessor, Coroner, Surveyor, Clerk of Courts. Each is independently elected; no role in commissioners or council.

**City government (Bloomington as primary):**
- **Common Council** — 9 members: 6 district-elected + 3 at-large. Official display name: "Bloomington City Council" or "Bloomington Common Council". Website: `bloomington.in.gov/council`. Indiana Code requires redistricting every decade post-Census. Most recent: 2023 elections.

**Township government (Monroe County has 11 townships):**
- **Township Trustee** — 1 elected official, executive and poor relief functions.
- **Township Advisory Board** — 3 elected members, fiscal/budget authority, approves contracts.
- Display name pattern: "[Township Name] Township Trustee", "[Township Name] Township Advisory Board".

---

## Sources

- Monroe County official site: https://www.co.monroe.in.us/
- Monroe County Council: https://www.co.monroe.in.us/council/
- Monroe County Board of Commissioners: https://www.co.monroe.in.us/commissioners/
- Indiana DLGF County Commissioners: https://www.in.gov/dlgf/local-officials/county-commissioners/
- Indiana townships (SBOA): https://www.in.gov/sboa/political-subdivisions/townships/
- Indiana township trustee (Wikipedia): https://en.wikipedia.org/wiki/Indiana_township_trustee
- Bloomington City Council: https://bloomington.in.gov/council
- Google Civic Information API reference: https://developers.google.com/civic-information/docs/v2
- Codebase: `essentials/src/lib/classify.js` — current category routing
- Codebase: `essentials/src/components/PoliticianGrid.jsx` — `qualifyTitle()` implementation
- Codebase: `EV-Backend/internal/essentials/handlers.go` — `OfficialOut` struct confirming `government_name`, `chamber_name_formal`, `district_label` already in API response

---
*Feature research for: v2026.3.3 Local Government Organization milestone*
*Researched: 2026-03-10*
