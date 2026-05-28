# Utah Data Completeness & Accuracy Audit

**Generated:** 2026-05-28 (Phase 1 of the Utah Data Completeness & Accuracy Pass)
**Scope:** the jurisdictions already live in production — 10 counties, 10 cities, 17 school
districts (374 UT politicians total). **Not adding new counties.**
**Production DB:** `kxsdzaojfaibhuzmclfq` (E.V Backend).

---

## Headline finding: there is NO roster↔production drift

The initial hypothesis (Salt Lake County missing 6 council seats) was an **artifact of the
`district_type` split**, not real drift. Salt Lake County's 6 district council members
(Jiro Johnson, Carlos A. Moreno, Aimee Winder Newton, Ross Romero, Sheldon Stewart, Dea
Theodore) **are loaded** — they're classified `district_type=LOCAL` (labeled generically
"Council District 1–6"), so a COUNTY-typed query missed them.

Verified reconciliation:
- **Counties:** roster 81 = production (75 COUNTY + 6 LOCAL council-district) = 81. ✅
- **Cities:** roster 67 (45 TSV council + 12 ArcGIS SLC/Provo council + 10 mayors) =
  production (57 city council LOCAL + 10 LOCAL_EXEC) = 67. ✅
- **Schools:** roster 105 = production 105 across 17 districts. ✅

**Dry-run** of all three loaders (`--dry-run`) shows 0 pending inserts for covered
jurisdictions; only un-researched counties/schools are skipped as `PENDING_RESEARCH`
(194 county stubs across the 19 un-covered counties + 24 school stubs).

## Address surfacing works

Sub-district geofences exist in `essentials.geofence_boundaries`: **12 ward boundaries**
(SLC 7 + Provo 5) + **6 council-district boundaries** (SL County). Confirmed end-to-end
against production `GET /api/essentials/address-search` for a Salt Lake City address —
returns the correct **Ross Romero** (SL County Council Dist 4) + **Dan Dugan** (SLC Council
Ward 6) alongside mayor, at-large council, county officers, SLC school board, state
legislators, and federal officials. **No geofence/surfacing gap.**

---

## Real gaps (this is the actual work)

### A. Completeness — contacts (email/phone): ~0 for local officials

| Tier | With email |
|---|---|
| State legislature | 104/104 |
| SBOE | 0/15 (contacts present, no email) |
| County | **0/75** |
| City council (LOCAL) | **5** (Provo only; SLC wards have none despite ArcGIS) |
| City mayors (LOCAL_EXEC) | **0/10** |
| School boards | **0/105** |

### B. Completeness — headshots: 0 for local officials

| Tier | With headshot |
|---|---|
| SBOE | 15/15 |
| State legislature | ~100/104 |
| County / City / School | **0/245** |

### C. Completeness — missing elected county officers

Per-county officer matrix (`✓`=present, `✗`=missing). Note: small Utah counties legally
**combine** offices (e.g. Clerk/Auditor, Recorder/Surveyor) — research must model each
county as it actually presents itself (playbook "citizen experience first").

| County | Sheriff | Attorney | Clerk | Auditor | Recorder | Assessor | Treasurer | Surveyor | Action |
|---|---|---|---|---|---|---|---|---|---|
| Box Elder | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | verify surveyor (likely combined) |
| Cache | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | verify surveyor |
| **Davis** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | **research full officer slate** |
| **Iron** | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | ✗ | ✗ | **research Auditor/Treasurer/Surveyor** |
| Salt Lake | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | complete |
| **Summit** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | **research full officer slate** |
| **Tooele** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | **research full officer slate** |
| Utah | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | complete |
| **Washington** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | **research full officer slate** |
| **Weber** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | **research full officer slate** |

Counties needing officer research: **Davis, Iron (partial), Summit, Tooele, Washington,
Weber** (~40 officer seats).

### D. Completeness — Layton city council incomplete

`layton_city.tsv` has **2 of ~7** council members (Bettina Smith Edmondson, Mike
Kolendrianos). Research remaining seats.

---

## Accuracy items (lower severity)

### E. Salt Lake County council member labels are generic
The 6 SL County council members sit on districts labeled "Council District 1–6"
(`district_type=LOCAL`) rather than "Salt Lake County Council District N". Functionally
correct (geofenced + surfacing), but the display label is ambiguous. **Optional relabel.**

### F. West Jordan / West Valley City council members lumped
All 7 WJ members attach to one district "West Jordan Council District 1" (city PLACE geoid
4982950); all 6 WVC members to "West Valley City Council District 1" (4983470). They
surface correctly for city addresses (whole-city attachment) but the single shared label
is misleading. **Optional: split labels / attach to per-district ArcGIS boundaries if
available.**

### G. Mayor modeling — verify council-manager vs strong-mayor
All 10 mayors are `LOCAL_EXEC`, `is_appointed_position=false`. Playbook says
council-manager cities (mayor not a separately-elected executive) should be `LOCAL`. SLC =
strong-mayor (keep `LOCAL_EXEC`). The other 9 (Provo, Ogden, Sandy, Orem, Layton, Lehi, St.
George, West Jordan, West Valley City) need per-city charter verification.

### H. Box Elder / Cache "missing" surveyor
Likely a combined/appointed office, not a true gap. Verify against county site; document if
intentional.

---

## Utah County is CORRECT — no change
Verified via web: Utah County remains a 3-commissioner county (2026 commissioners Skyler
Beltran (Chair), Amelia Powers Gardner, Brandon Gordon). No structural change needed.

---

## Recommended execution order

1. **Phase 2 (accuracy + small completeness):** research missing county officers (Davis,
   Iron, Summit, Tooele, Washington, Weber) + Layton council; verify mayor modeling +
   Box Elder/Cache surveyor; optional SL County / WJ / WVC relabel. Fill TSVs → re-run
   loaders per `--county` / `--city`.
2. **Phase 3 (bulk completeness, population waves):** research email/phone/photo_url for
   covered local officials; fill TSV columns → re-run loaders (`replaceContacts` +
   `rehostPhoto` auto-fire). Wave 1 = SL County, SLC, Utah County, big school districts,
   West Valley City, West Jordan, Sandy, Provo. Wave 2 = the rest.

**Out of scope this pass:** bios, compass stances, 2026 elections, new counties.

---

## Phase 2 results (executed 2026-05-28)

**County officers added (30 seats, all from official county sources):**
- **Davis (+8):** Sheriff Kelly V. Sparks, Attorney Troy Rawlings, Clerk Brian McKenzie,
  Controller Scott Parke, Recorder Kelly Silvester, Surveyor Max B. Elliott, Assessor Andy
  Hansen, Treasurer Matt Brady. (Davis renamed Auditor→Controller Dec 2024; Parke & Brady
  are appointees currently filling elected vacancies.)
- **Weber (+6):** Sheriff Ryan Arbon, Attorney Christopher F. Allred, Clerk/Auditor Ricky
  Hatch, Recorder/Surveyor Bahy Rahimzadegan, Assessor Jared Preisler, Treasurer Lynelle
  Jensen. (Weber combines Clerk/Auditor and Recorder/Surveyor.)
- **Iron (+2):** Auditor Lucas Little, Treasurer Nicole Rosenberg. (Surveyor combined into
  the existing Recorder office — Carri Jeffries.)
- **Summit (+7):** Sheriff Kacey Bates, Attorney Margaret Olson, Clerk Malena Stevens,
  Auditor Cindy Keyes, Recorder/Surveyor Gregory R. Wolbach, Assessor Stephanie Paice,
  Treasurer Corrie Forsling.
- **Tooele (+7):** Sheriff Paul J. Wimmer, Attorney Scott Broadhead, Clerk Tracy Shaw,
  Auditor Alison H. McCoy, Recorder/Surveyor Jerry Houghton, Assessor Joy Peters, Treasurer
  Michael J. Jensen.

Loaded via `load-ut-county-rosters.ts` (ins=30, upd=81, err=0). Officers attach to the
G4020 whole-county geofence and surface for county addresses.

**Layton city council completed:** added Zach Bloxham, Clint Morris, Dave Thomas (now 5
at-large council + Mayor Joy Petro). Layton is a 6-member-council form (5 council + mayor),
all at-large.

**DEFERRED — Washington County officers:** official 2024 election results conflict with
department-page data on nearly every office (and show a "Clerk/Auditor Special 2-Year
Seat" implying a mid-term vacancy). Per "accuracy over completeness — NULL acceptable,"
NOT written. Needs a dedicated verification pass against electionresults.utah.gov +
current department contact pages. Confirmed-only so far: Assessor Tom Durrant; Sheriff Nate
Brooksby and Attorney Jerry Jaeger (high-confidence, unverified on rendered pages).

**Mayor modeling — decision: no changes.** All 10 city mayors are *directly elected* by
voters. The playbook's `LOCAL` recommendation targets *council-selected* mayors (e.g.
Cambridge); none of these are. By citizen-experience-first, all 10 remain `LOCAL_EXEC`
(residents elect and experience them as "the Mayor"), `is_appointed_position=false`.
Forms: strong-mayor (SLC, Provo, Ogden, Sandy, West Jordan); six-member-council form,
mayor = statutory CEO (Layton, Lehi); council-manager, mayor = council chair (Orem, West
Valley City) — kept LOCAL_EXEC anyway since directly elected. **St. George flagged**:
statutory CEO-mayor vs manager-run practice conflict; left as `LOCAL_EXEC`.

**Deferred (cosmetic, documented):** SL County council members keep generic
"Council District 1–6" labels; WJ/WVC council members keep lumped city-place labels. Both
surface correctly by address — relabel is display-only and out of scope this pass.

**Box Elder / Cache "missing surveyor":** confirmed acceptable — these counties combine or
appoint the surveyor; no separate elected office. No change.

---

## Phase 3 Wave 1 results (executed 2026-05-28) — contacts + headshots

All from official sources; emails left blank where only a contact form is published (no
pattern-guessing). Headshots downloaded + re-hosted to Supabase Storage `politician_photos/ut/`.

| Jurisdiction | Members | Emails | Phones | Headshots |
|---|---|---|---|---|
| Salt Lake County (incl. 6 council districts) | 18 | 16 | 17 | 18 |
| Utah County | 11 | 10 | 11 | 11 |
| Granite School District | 7 | 7 | 7 | 7 |
| Jordan School District | 6 | 6 | 6 | 6 |
| Davis School District | 5 | 5 | 5 | 5 |
| Alpine School District | 7 | 7 | 7 | 7 |
| Canyons School District | 5 | 5 | 1 | 4 |
| West Valley City (+ mayor) | 7 | 0 (contact-form only) | 7 | 7 |
| West Jordan (+ mayor) | 8 | 0 (council line only) | 1 | 7 |

**Loader bug found + fixed:** the city loader's `ingest()` does NOT wrap `rehostPhoto` in a
try/catch (unlike county/school loaders), so a throwing photo URL rolls back the whole row.
Separately, a tab-count error in hand-written WVC/WJ TSVs (11 cols vs 10) silently dropped
phone/photo into wrong columns — fixed by regenerating those files programmatically.
WVC's extensionless ArcGIS `ImageRepository/Document?documentId=N` URLs re-host fine
(`detectExt` defaults to jpg; content-type is image/jpeg).

### ACCURACY corrections APPLIED (2026-05-28, verified in production)

All four verified and committed:
- **SLC Ward 5:** Darin Mano → **Erika Carlsen** (seat repurposed in place + phone 801-535-7786).
- **SLC Ward 4:** **vacated** (Eva Lopez Chavez removed per residency ruling; office `is_vacant=true`, no occupant pending the ~June 11 appointment).
- **Sandy City council:** removed 4 stale (Applegarth, Bennett, Jones, Saville), added 4 current
  (Alison Stroud, Aaron Dekeyzer, Cyndi Sharkey, Brooke D'Sousa) → correct 7-member council
  (5 emails + shared council phone). Kept Christensen/Nicholl/Houseman + Mayor Zoltanski.
- **Provo Mayor:** Michelle Kaufusi (lost Nov 2025) → **Marsha Judkins** (re-hosted photo + phone).

> **CAUTION — SLC FeatureServer is stale.** SLC council loads from the ArcGIS FeatureServer,
> which still returns Mano (Ward 5) and Eva Lopez (Ward 4). **Do NOT re-run
> `load-ut-city-rosters.ts` for SLC until that FeatureServer is updated**, or it will
> reintroduce the corrected records. The Ward 5/4 fixes above were applied via direct SQL.

### Original findings (now resolved above)

- **Salt Lake City Ward 5 — Darin Mano is NO LONGER in office.** Replaced by **Erika
  Carlsen** (since Jan 2026). Our DB still has Mano. SLC council is loaded from the **ArcGIS
  FeatureServer**, not a TSV — so this needs a direct DB update/migration, not a roster edit.
- **Salt Lake City Ward 4 — Eva Lopez Chavez's seat declared VACANT (May 12, 2026)** on a
  residency ruling; appointment expected ~June 11, 2026. DB still shows Eva Lopez.
- **Sandy City council roster appears STALE** — Mike Applegarth, Jim Bennett, Ronald T.
  Jones, Linda Saville may have been replaced (by Alison Stroud, Aaron Dekeyzer, Cyndi
  Sharkey, Brooke D'Sousa). The researching agent hit tooling issues on sandy.utah.gov, so
  this needs a dedicated verification pass before any destructive roster change. **Sandy
  enrichment deferred.**

### Wave 1 continuation (executed 2026-05-28) — SLC + Provo councils

| Jurisdiction | Members | Emails | Phones | Headshots |
|---|---|---|---|---|
| Salt Lake City council (W1-W3, W5-W7) | 6 | 6 | 6 | 6 |
| Provo council (W1-W5) | 5 | 5 | 4 (Whitlock phone=null) | 5 |

Sources: slc.gov/district{N}/ (emails Cloudflare-decoded), provo.gov/government/city-council + ImageRepository.
Script: `scripts/enrich-ut-slc-provo-councils.ts --commit`
Note: orphan contact for Erika Carlsen (source=slc.gov/district5, from Phase 3 direct SQL) cleaned up via DELETE.

---

## Phase 2 Wave 2 results (executed 2026-05-28) — Washington County officers

**Washington County officers added (6 seats):**

| Office | Officeholder | Confidence | Source |
|---|---|---|---|
| Sheriff | Barry Golding | HIGH | news.washeriff.net (official WCSO site) |
| County Attorney | Jerry Jaeger | HIGH | washco.utah.gov/departments/attorney |
| Clerk/Auditor | Ryan Sullivan | HIGH | washco.utah.gov/departments/clerk-auditor |
| Recorder/Surveyor | Gary Christensen | HIGH | washco.utah.gov/departments/recorder |
| Assessor | Tom Durrant | HIGH | washco.utah.gov/departments/assessor |
| Treasurer | David Whitehead | HIGH | washco.utah.gov/departments/treasurer |

**Office structure decisions:**
- **Clerk/Auditor is a combined office** — washco.utah.gov presents a single "Clerk/Auditor"
  department; Ryan Sullivan self-identifies as "Washington County Clerk/Auditor" in election
  notices. Modeled as one row (matches Weber County pattern).
- **Recorder/Surveyor is a combined office** — county navigation lists "Recorder/Surveyor" as a
  single department. Modeled as one row (matches Weber, Tooele, Summit pattern).

**Sheriff vacancy note:** Nate Brooksby (2024 election winner) resigned March 27, 2026.
Undersheriff Barry Golding was formally chosen by the Washington County Republican Party
Central Committee on May 6, 2026 (~75% of vote) to fill the vacancy through end of term
(January 2027, when Johnny Heppler takes office). Golding is the current officeholder per
the midterm vacancy procedure (Utah Code); modeled as "Sheriff" consistent with the Davis
County appointee precedent (Parke & Brady).

**Earlier conflict resolved:** The 2024 election "Clerk/Auditor Special 2-Year Seat" was a
genuine mid-term vacancy fill for the combined Clerk/Auditor office. Ryan Sullivan is the
current holder per the live department page — no separate Clerk and Auditor offices exist.

Loaded via `load-ut-county-rosters.ts --county washington` (ins=6, upd=3, err=0).
All 9 Washington County officials (3 commissioners + 6 officers) verified in production DB
(district COUNTY / geo_id=49053 / ocd-division/country:us/state:ut/county:washington).

~~Wave 1 still pending (SLC/Provo) — resolved above.~~

---

## Wave 2 results (executed 2026-05-28) — cities + county enrichment + schools (partial)

### Cities enriched

| Jurisdiction | Members | Emails | Phones | Headshots | Notes |
|---|---|---|---|---|---|
| St. George (5 council + mayor) | 6 | 6 | 6 | 6 | All from sgcityutah.gov |
| Orem (6 council + mayor) | 7 | 7 | 1 (mayor only) | 7 | Council: no individual phones published. Dave Young STALE → Jenn Gale added; Dave Young remains in DB unenriched (**needs manual DELETE**) |
| Ogden (7 council + mayor) | 8 | 8 | 8 | 8 | All from ogdencity.gov |
| Lehi (5 council + mayor) | 6 | 6 | 6 | 6 | All from lehi-ut.gov |
| Layton (5 council + mayor) | 6 | 1 (mayor only) | 1 (mayor only) | 6 | Council: no individual emails/phones published on laytoncityutah.gov |

### Counties enriched (contacts + headshots added to existing officials)

| County | Officials | With contact | With photo | Notes |
|---|---|---|---|---|
| Washington | 3 | 3 (phone only) | 0 | No public emails; photos hotlink-protected |
| Box Elder | 10 | 10 | 0 | 3 commissioners with .gov emails; officers with dept phones only |
| Cache | 15 | 5 | 4 | 4 serving council + Exec Daines email; 3 STALE (Worthen, Ward, Tidwell → Garrity, Bennett, Beus; **needs cleanup**) |
| Davis | 11 | 10 | 0 | Dept phones only (JS-rendered site, no public emails) |
| Iron | 10 | 3 | 0 | Site under migration; general phone only |
| Summit | 12 | 11 | 0 | 5 council + 5 officers with individual emails+phones; Margaret Olson (Attorney) no directory entry |
| Tooele | 12 | 12 | 5 | 5 council photos; 5 officers with individual emails+phones |

### School districts enriched

| District | Members | Emails | Phones | Headshots | Status |
|---|---|---|---|---|---|
| Weber School District | 7 | 7 | 0 | 7 | **DONE** — wsd.net |
| Provo School District | 7 | 0 | 0 | 7 | **DONE** — contact-forms only, no direct emails |

### School districts still pending (10 of 12)

Salt Lake City, Nebo, Washington, Box Elder, Cache, Tooele, Iron, Murray, Park City, Logan

### OPEN ACCURACY FLAGS

- **Orem:** Dave Young (stale, left office) still in DB as `ut-city-orem` with no contacts. Jenn Gale added as replacement. Manual DELETE of Dave Young's office row needed before next city loader run.
- **Cache County:** Gina Worthen, Karl Ward, Barbara Tidwell are stale (Kathryn Beus, Keegan Garrity, JoAnn Bennett are current). Their DB records have no contacts (safe but inaccurate). Needs cleanup.
- **DISPLAY ISSUE (new):** Utah city councils loaded at-large have label "Orem City Council" etc. but city name not prominent in front-end display for address searches. At-large Utah councils also lack seat/position labels (unlike Bloomington, IN wards). See handoff prompt for fix scope.

### LOADER FLAG NOTE
Both `load-ut-city-rosters.ts` and `load-ut-school-rosters.ts` now support `--city <slug>` and `--district <slug>` flags respectively (added Wave 2 to prevent re-running stale SLC FeatureServer data).
