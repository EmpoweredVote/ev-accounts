# Pitfalls Research

**Domain:** Adding state-specific local government organization to an existing civic engagement app (Essentials v2026.3.3)
**Researched:** 2026-03-10
**Confidence:** HIGH — based on direct codebase inspection of classify.js, Results.jsx, models.go, and handlers.go; patterns are specific to this codebase, not derived from third-party sources

---

## Critical Pitfalls

---

### Pitfall 1: String-Matching Classification Breaks Silently When Body Names Change

**What goes wrong:**
The current `classify.js` determines which section a politician appears in by pattern-matching `chamber_name`, `chamber_name_formal`, and `office_title` strings. Adding state-specific body names means these strings will be more specific — "Monroe County Council" instead of "County Council" — which can silently break the keyword matching that currently routes politicians into sections.

Specifically, the current code matches `hasAny(chamber, ["county council"])`. If the chamber name is updated in the database to "Monroe County Council", that check still passes — but if code is changed to match "Monroe County Council" exactly for the new specific-section logic, and a different county's data comes in as "Monroe County Board of Commissioners" (historically used interchangeably), the politician falls through to `"Local (Other)"` instead of `"County Legislators"`.

The failure is invisible: no console error, no 500 response, the politician simply appears in the wrong section or the catch-all bucket.

**Why it happens:**
The classify function is designed to be forgiving — it uses `includes()` matching with many keyword variants so any reasonable string routes correctly. Adding specific body name requirements makes it stricter without adding any feedback mechanism for misses. Additionally, Indiana county government uses distinct terminology that doesn't appear in the current keyword lists: "County Auditor", "County Assessor", "County Recorder" are statutory offices that would currently fall under the generic `"County Officials"` bucket — not wrong, but not specific enough for the new milestone goal.

**How to avoid:**
- Add a logging/audit step at the end of `classifyCategory`: track all politicians that land in `"Local (Other)"` or `"County Officials"` and inspect them before shipping. Any politician who should have a specific section but landed in a catch-all is a classification miss.
- When adding new body-specific matching rules, add them before the existing generic rules (order matters in the if/else chain), not after.
- Write a classification regression test: for each known politician in the DB (Monroe County Council members, MCHD officials, etc.), assert the expected `group` output. Run this after any change to classify.js.

**Warning signs:**
- Any politician appearing in `"Local (Other)"` for a jurisdiction where you have complete data
- Section counts that don't match what you know exists (e.g., Monroe County has 4 county commissioners — if only 3 appear in "County Executives", one is misclassified)
- Body name changes in the DB not matched by a corresponding classify.js update

**Phase to address:**
The first phase that modifies classify.js — before any UI changes. Create the regression test list first, then modify the classifier, then verify all known politicians still route correctly.

---

### Pitfall 2: `government_name` Field Is Not Reliable Enough to Drive Section Headers

**What goes wrong:**
The natural implementation for "Monroe County Council instead of County Council" is to use the `government_name` field (already available in the API response, already used in `qualifyLocalTitle()`) to prefix section titles. The code already does this for individual card titles: `qualifyLocalTitle("County Council", pol)` → "Monroe County Council". Extending this to section headers seems straightforward.

The problem: `government_name` in the current data is sourced from the `essentials.governments` table, joined via `chambers.government_id`. For some local officials, especially those imported via bulk gap-fill scripts, `government_name` is the name of the government entity (e.g., "Monroe County, IN") — not the chamber name. This means a section titled from `government_name` would read "Monroe County, IN Council" instead of "Monroe County Council."

More critically: politicians within the same `group` (e.g., `"County Legislators"`) may come from different governments when the search returns results across jurisdictions. A search near a county boundary could return politicians from two different county councils — both classified as `"County Legislators"`. Using the first politician's `government_name` to label the entire section would mislabel the second county's representatives.

**Why it happens:**
The classified result is grouped by `group` key (e.g., `"County Legislators"`), not by `(group, government_id)`. Within a group, there can be multiple governments. The existing `qualifyLocalTitle` function handles this correctly at the card level (each card gets its own prefix) but the section title cannot use this approach without knowing whether the group spans multiple governments.

**How to avoid:**
- Use `chamber_name_formal` (e.g., "Monroe County Council") as the section title source, not `government_name`.
- `chamber_name_formal` comes from `essentials.chambers.name_formal` and should be the official body name. Verify that Indiana chamber records have `name_formal` populated — if they don't, this is a data gap to fix at import time, not classify time.
- When a group contains politicians from multiple distinct chambers (cross-jurisdiction results), fall back to the generic `getDisplayName(category)` label for the section header. Detect this case by checking if `pol.chamber_name_formal` differs across politicians in the same group.

**Warning signs:**
- Section headers containing ", IN" or ", CA" county name suffixes that look like DB identifiers
- Section headers that don't match what the official body calls itself (e.g., "Monroe County IN Council" vs. "Monroe County Council")
- A single section containing politicians from two different counties with one county's name in the header

**Phase to address:**
Schema/data audit phase before implementing the section header logic. Check that `chambers.name_formal` is populated for all Indiana local bodies before writing the frontend to depend on it.

---

### Pitfall 3: Splitting Generic Categories Into Specific Bodies Breaks the Sidebar Filter and Sort Options

**What goes wrong:**
The `Results.jsx` renders sections using `LOCAL_ORDER` as the sort key for section ordering. The `CATEGORY_DISPLAY_NAMES` map provides sidebar filter labels. The `GROUP_SORT_OPTIONS` in `sorters.js` defines sort options per group key.

Adding new specific body sections (e.g., splitting `"County Legislators"` into `"Monroe County Council"` and `"Monroe County Commissioners"`) requires adding these new keys to all three of these structures simultaneously. Missing any one causes:
- **Missing from `LOCAL_ORDER`**: The new section renders at the bottom after "Local (Other)" instead of in the correct position
- **Missing from `CATEGORY_DISPLAY_NAMES`**: The raw internal key is displayed as the section header (e.g., `"Monroe County Council"` the JS key, not a formatted label)
- **Missing from `GROUP_SORT_OPTIONS`**: The sort dropdown shows no options for the new section, or throws an error when trying to access sort options

The current code already has this coupling — `LOCAL_ORDER` has 11 entries, `CATEGORY_DISPLAY_NAMES` has mapped entries for each, and `GROUP_SORT_OPTIONS` has sort options per group. The issue is that these are in three different files with no compile-time check that they're in sync.

**Why it happens:**
JavaScript has no exhaustive switch enforcement. Adding a new `group` value returned by `classifyCategory` requires manual updates in three places (classify.js, sorters.js, Results.jsx) with no tooling to catch misses.

**How to avoid:**
- Before adding any new specific group keys, audit all places that consume group keys: `LOCAL_ORDER`, `CATEGORY_DISPLAY_NAMES`, `GROUP_SORT_OPTIONS`, and any component that pattern-matches on group name strings.
- Add new group keys to all consumers in the same commit. Never add a new group key to `classifyCategory` without updating all three consumers in the same PR.
- Consider a shared constants file (`classify-constants.js`) that exports the canonical list of valid group keys, and have `LOCAL_ORDER` import from it — making it visible when the list diverges from classify.js output.

**Warning signs:**
- A section appearing at the bottom of the results list when it should appear in a specific position (missing from `LOCAL_ORDER`)
- Raw key strings visible in the UI where formatted labels should appear
- Sort controls disappearing for a section

**Phase to address:**
First phase that adds new `group` values to `classifyCategory`. Create a checklist for all consumers of group keys and verify each is updated before merging.

---

### Pitfall 4: Website Links Per Section Require a New Data Layer With No Existing Infrastructure

**What goes wrong:**
The milestone requires each government body section to link to its official website. This data does not currently exist in any table. The `essentials.governments` table has `Name`, `Type`, `State`, `City` but no `website_url`. The `essentials.chambers` table has no URL field. The `PoliticianContact` table stores contact info per-politician (not per-body), and the contact types include `"city_website"` but this is attached to a politician, not to a chamber/section.

The natural implementation is to add a `website_url` column to `essentials.chambers` — this is the right approach — but it requires:
1. A schema migration (GORM AutoMigrate will add the column, but the data must be populated)
2. A data population step (manual research + entry for each body, or import from a source)
3. An API change to include `chamber_website_url` in the politician list response
4. A frontend change to read and display the URL per section

The pitfall is underestimating the data population effort. Monroe County alone has ~10 distinct chambers (County Council, County Commissioners, City Council, Township Trustees × multiple townships, MCHD board, Monroe County Circuit Court, etc.). LA County has hundreds. Each URL must be found, verified, and entered. If this is treated as a "quick database update," it blocks the milestone.

**Why it happens:**
Website links seem like a metadata field — "just add a column." The schema change is indeed small. But civic government websites are not in any centralized database: they must be researched body-by-body, are often buried in county websites, and change when counties redesign their sites.

**How to avoid:**
- Scope explicitly: define which bodies get website links in v2026.3.3 vs. which are deferred. Indiana local bodies (Monroe County + Bloomington) have manageable scope; LA County's 791 officials span dozens of bodies and cannot all be linked in one milestone.
- Do the data population work before implementing the frontend: collect the URLs first, verify they resolve, then implement the API and UI.
- Treat the URL column as nullable with graceful fallback: sections without a URL simply have no link, rather than showing a broken or empty link target. Never show an empty `href=""` or `href="#"` as a placeholder.
- Store URLs with the chamber record (`essentials.chambers.website_url`) not with individual politicians — the URL belongs to the body, not the person.

**Warning signs:**
- URLs stored on politicians instead of chambers (correct entity is the body)
- Dead links (county government sites frequently change URL structure)
- Scope creep into "all LA County bodies" when only Indiana bodies were originally scoped

**Phase to address:**
Data population phase before any frontend work. The schema migration and data entry are prerequisites; the frontend is last.

---

### Pitfall 5: Indiana County Government Structure Is Incompatible With the Current Generic Category Taxonomy

**What goes wrong:**
Indiana counties have a constitutionally distinct dual-body structure: the **County Commissioners** (executive body, 3 members) and the **County Council** (fiscal/legislative body, 7 members: 4 district + 3 at-large). This is not generic "county legislators" — they are distinct bodies with different roles, different election cycles, and different authority.

The current `classify.js` maps both Commissioners and Council to `"County Legislators"` (if title contains "commissioner" or chamber contains "county council"). This was acceptable for the generic display but is wrong for specific-body display — it merges two distinct governmental bodies into one section.

Additionally, Indiana townships have **Township Trustees** (single elected official) and **Township Advisory Boards** (3 members) — also distinct bodies currently collapsed into `"Township Officials"`.

The pitfall: naively splitting by title keyword creates fragile logic. If a Monroe County Commissioner is titled "County Commissioner" and a Monroe County Council member is titled "County Council Member", keyword splitting works. But if either title deviates (historical imports, data entry variations), the split fails and you get one body's members appearing in the other's section.

**Why it happens:**
The current classify.js was designed for California (LA County) where the county board is a single body — the Board of Supervisors. Indiana's dual-body model is not reflected in the code because the system wasn't originally designed for Indiana's specific structure.

**How to avoid:**
- Use `chamber_name_formal` as the primary split signal, not title keywords. "Monroe County Board of Commissioners" and "Monroe County Council" are distinct chamber names — matching on `chamber_name_formal` is reliable. Title keywords are a fallback only when `chamber_name_formal` is absent.
- Verify that Indiana commissioner and council members have distinct `chamber_name_formal` values in the database before writing the classifier to depend on this distinction.
- Do not add Indiana-specific body detection logic without first confirming what data is actually in the DB for these politicians (run `SELECT DISTINCT chamber_name, chamber_name_formal FROM essentials.chambers WHERE state = 'IN'`).

**Warning signs:**
- Monroe County Commissioners and Monroe County Council members appearing in the same section
- Any "at-large" members appearing in a district-specific section, or vice versa
- Township Trustees and Township Advisory Board members in the same section when they should be distinct

**Phase to address:**
DB audit phase — inspect the actual chamber data for Indiana politicians before writing any classification code. The classifier must match what's in the DB, not an idealized data model.

---

### Pitfall 6: "At-Large vs. District" Distinction Requires Subtitle Logic That Conflicts With Existing Card Subtitle Rules

**What goes wrong:**
The milestone requires distinguishing at-large from district County Council members within the same section. The existing card subtitle logic already handles this for individual cards (the `dashIdx` pattern in `Results.jsx` parses " - At Large" from `office_title`). But for section-level grouping, "at-large vs. district" requires either:

a) Two sub-sections within the same "Monroe County Council" section (At-Large members in one sub-group, District members in another), OR
b) A single section with card-level subtitles showing "At Large" / "District 1" — which already works via existing logic

Option (a) requires a new sub-section concept not in the current `CategorySection` component. Option (b) already works via the existing subtitle system.

The pitfall is implementing (a) when (b) is sufficient. Option (a) requires changes to the ev-ui `CategorySection` component (a published library), which triggers a version bump and publish cycle. Option (b) requires no ev-ui changes.

**Why it happens:**
The milestone description says "County council at-large vs district members distinguished in display" — this sounds like two separate sections but can be satisfied with card subtitles. Developers default to "if we need to distinguish, we need separate sections."

**How to avoid:**
- Default to card-level subtitle distinction (option b) unless UX review explicitly requires separate sub-sections.
- The existing subtitle logic already correctly renders "At Large" and "District 1" on individual cards via the `dashIdx` split pattern. Verify this works for Monroe County Council members before building anything new.
- Only pursue sub-section grouping if a user test or design review confirms that card subtitles are insufficient.

**Warning signs:**
- Proposals to modify `CategorySection` in ev-ui for this milestone
- New sub-group data structures being added to the `byTier` map that don't fit the existing flat group model

**Phase to address:**
Design review phase — confirm whether card subtitles are sufficient before writing any code for sub-sections.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcode Indiana body names as string constants in classify.js | Works immediately without DB changes | Every new county or state requires code deployment, not just data updates | Never — body names belong in the DB |
| Use `government_name` + generic category as section title | No schema changes needed | Section titles vary unpredictably; cross-jurisdiction searches mislabel sections | Never for section headers |
| Store body website URLs on individual politicians instead of chambers | Avoids schema migration | URL must be duplicated for every politician in the body; updates require mass updates | Never |
| Skip regression testing of classify.js when modifying it | Faster implementation | Silent misclassification of politicians into wrong sections | Only if the change is trivially isolated (adding a single catch-all keyword that cannot possibly affect existing classifications) |
| Defer website links to "a later PR" after section names are done | Ships section names faster | The section name UI looks incomplete without links; two separate PRs for one feature is more expensive than one | Acceptable only if data population is the blocker, not implementation |

---

## Integration Gotchas

Common mistakes when connecting existing system components.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| classify.js → Results.jsx | Adding a new group key in classify.js without updating `LOCAL_ORDER` in Results.jsx | Update `LOCAL_ORDER`, `CATEGORY_DISPLAY_NAMES`, and `GROUP_SORT_OPTIONS` in the same commit as the new group key |
| chambers table → API response | Adding `website_url` to the DB without adding it to the SQL query in `handlers.go` | Check every raw SQL query that joins chambers — they all use explicit column lists, not `SELECT *` |
| chamber.name_formal → section titles | Assuming `name_formal` is always populated | Verify population in DB first; add null-safe fallback to `name` if `name_formal` is empty |
| qualifyLocalTitle() | Calling it for section headers (it's designed for card titles) | This function adds a government prefix to a title string — it works for cards but produces wrong output for section headers that already contain the government name (e.g., "Monroe County Monroe County Council") |
| ev-ui CategorySection | Assuming it can be extended for sub-sections without a library publish | Any change to ev-ui requires npm publish + version bump in essentials package.json; plan for this overhead |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Deriving section titles from politician data at render time | Extra logic in the React render loop per politician | Pre-compute section metadata (title, URL) before the render loop | Not a real performance issue at current scale (~100 politicians per result set); acceptable |
| Fetching website URL per section via a separate API call | Network waterfall: results load → section renders → URL fetch happens | Include `chamber_website_url` in the main politician list response (already joins chambers) | First page load with slow connection; always avoid separate calls for data available in the main join |
| Running `classifyCategory` on every render instead of memoizing | CPU spike on filter/sort changes | The existing code correctly memoizes classified results in `useMemo` — maintain this pattern for any new classification logic | Non-issue at current scale if memoization is preserved |

---

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing body website links that open in the same tab | User loses their results page; back navigation restores from sessionStorage but feels disruptive | Open body website links in a new tab (`target="_blank" rel="noopener"`) |
| Showing a section header link when the URL is unknown | Broken link or unhelpful "#" href; undermines trust in the platform | Only render the link element when `chamber_website_url` is non-empty; section header renders as plain text otherwise |
| Displaying Indiana-specific body names for Indiana officials but California-specific names for CA officials with no explanation | Users who see "Monroe County Council" for Indiana might expect "Los Angeles County Board of Supervisors" for CA, but currently see "County Board" | If state-specific names are only implemented for Indiana in this milestone, that is fine — do not add a half-baked CA implementation; make the Indiana improvement cleanly, and note that CA specificity is a future item |
| Splitting "County Legislators" into specific bodies without updating the sidebar filter labels | Sidebar shows "County Board" but results show "Monroe County Council" and "Monroe County Commissioners" — labels don't match | The sidebar filter operates at tier level (Local/State/Federal), not group level, so this is not an issue for the sidebar; but ensure `CATEGORY_DISPLAY_NAMES` is updated for any new group key |
| Showing empty sections with only a header and website link, no politicians | If classification misroutes politicians, a section renders with just its header and link but zero cards — looks broken | Render sections only when `polList.length > 0` (current code already does this for groups via `hasGroups` check) |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Specific section names:** Verify that the new names appear for Indiana addresses but generic fallbacks still appear for unsupported regions (not every address in the US should show "Monroe County Council")
- [ ] **Website links:** Verify links open correctly, point to the right body's page (not just the county homepage), and open in a new tab — not just that the anchor element is present
- [ ] **At-large vs. district distinction:** Verify that card subtitles correctly show "At Large" vs. "District 1" for Monroe County Council members — inspect actual DB data to confirm the `office_title` contains " - At Large" / " - District N" format that the existing `dashIdx` logic depends on
- [ ] **Missing politician classification audit:** After any classify.js change, run a spot check: search an Indiana address, count politicians per section, compare against known counts for Monroe County bodies (4 commissioners, 7 council members, etc.)
- [ ] **Cross-jurisdiction results:** Test with an address near a county boundary — verify that when two counties' politicians appear, section headers correctly reflect both bodies (or fall back gracefully), not just the first politician's government
- [ ] **Empty `chamber_name_formal` handling:** Verify that the section title logic has a null-safe fallback before using `chamber_name_formal` as the section title; check which Indiana chambers have empty `name_formal` in the DB

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Politicians in wrong section due to classify.js regression | LOW | Fix the keyword match in classify.js; no DB changes needed; deploy frontend only |
| Section title shows raw key string instead of display name | LOW | Add missing entry to `CATEGORY_DISPLAY_NAMES`; deploy frontend only |
| Website links pointing to wrong body | LOW-MEDIUM | Update `chamber_website_url` in DB for affected chambers; no code changes; verify via direct DB update |
| Indiana Commissioners and Council members merged into one section | MEDIUM | Add specific chamber matching logic to classify.js + verify DB has distinct `chamber_name_formal` values; may require DB data correction if chamber names are identical |
| ev-ui CategorySection modified prematurely for sub-sections | HIGH | Revert ev-ui change; republish previous version; update package.json in essentials; redesign approach using card subtitles instead |
| Website URL column added to chambers but not to API query | LOW | Add column to SQL SELECT list in `handlers.go`; no migration needed (column exists, just not fetched) |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| String-matching classification regression | DB audit + regression test creation (Phase 1) | Run classification spot check after any classify.js change; count politicians per section |
| government_name unreliable for section headers | DB audit phase — inspect `chamber_name_formal` for Indiana chambers | Query: `SELECT name, name_formal FROM essentials.chambers WHERE state = 'IN'` and verify `name_formal` is populated |
| New group keys missing from LOCAL_ORDER, CATEGORY_DISPLAY_NAMES, GROUP_SORT_OPTIONS | classify.js change phase — use checklist before merging | Search codebase for all usages of group key strings before adding a new one |
| Website links require new data layer underestimated | Data collection phase before schema/frontend work | Complete the URL research spreadsheet for in-scope bodies before writing any code |
| Indiana dual-body structure not matching DB data | DB audit phase | Run `SELECT DISTINCT chamber_name, chamber_name_formal FROM essentials.chambers JOIN essentials.districts ON ... WHERE districts.state = 'IN'` |
| At-large vs. district distinction triggers ev-ui changes | Design review before implementation | Confirm card subtitle approach works by testing with a Monroe County address; only escalate to sub-sections if review demands it |

---

## Sources

- Direct codebase inspection: `/essentials/src/lib/classify.js` — current classification logic, LOCAL_ORDER, CATEGORY_DISPLAY_NAMES
- Direct codebase inspection: `/essentials/src/pages/Results.jsx` — rendering pipeline, qualifyLocalTitle(), subtitle logic, section rendering
- Direct codebase inspection: `/EV-Backend/internal/essentials/models.go` — Government struct (no website_url), Chamber struct fields
- Direct codebase inspection: `/EV-Backend/internal/essentials/handlers.go` — API response shape, government_name JOIN pattern, chamber_name_formal availability
- Indiana Code Title 36 — Counties and Local Government: Indiana's constitutional dual-body county structure (County Commissioners = executive body, County Council = fiscal body) is codified in state law; this is not a local convention but a statewide statutory requirement
- Project context: `.planning/PROJECT.md` milestone definition and existing system constraints

---

*Pitfalls research for: v2026.3.3 Local Government Organization — state-specific body names, website links, Indiana county structure*
*Researched: 2026-03-10*
