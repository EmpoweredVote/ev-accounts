# School-board subdistrict rollout

Make an address resolve to **one** school-board member instead of the whole board's
worth, everywhere our data holds a single-member-district board. MCCSC is the applied
pilot (see `backend/data/mccsc-board-subdistricts/README.md`); this is the plan to extend it.

## The mechanism (settled by the pilot)

Data-only, no backend code change:

1. Load one boundary polygon per board seat into `essentials.geofence_boundaries` under
   `mtfcc='X0002'` — the designated "school_subdistrict" layer already wired into
   `districtQueries.ts` (address match) and `essentialsBrowseService.ts` (browse).
2. Add one `SCHOOL` sub-district row per seat (`geo_id = '{corp_geoid}-board-d{N}'`).
3. Repoint each board office off the whole-corporation district onto its sub-district.

Templates: `backend/scripts/{fetch,import}-mccsc-board-district-polygons.ts` and
`verify-mccsc-board-subdistricts.sql`. Each board needs its own `fetch` (source URL differs)
and can reuse the `import`/`verify` shape.

## Scope is smaller than "137 boards"

Only **single-member-district** boards need this. **At-large** boards — every member serves
the whole area — are already correct and must be left alone. The seat title is the tell, but
it is not reliable on its own, so every board needs a human/source confirmation before load.

Suggested classification of the 136 multi-seat boards (full list:
`backend/data/school-board-subdistrict-rollout/worklist.csv`):

| Suggested class | Count | Meaning | Action |
|---|---:|---|---|
| `single_member_needs_boundaries` | 11 | Title names a geographic seat (Zone/District/Ward/Trustee Area) | **Load** — source + import |
| `single_member_generic_title_UT` | 17 | Utah — single-member by law, but titled generic "School Board Member" | **Load** — the false-negative trap; confirm per district |
| `needs_human_review` | 90 | Mostly California "Board Member" — trustee-area OR at-large, title doesn't say | **Classify first**, then load the single-member ones |
| `at_large_exclude` | 12 | TX "Place N", OR "Position N" — at-large numbered seats | **Skip** — showing all is correct |
| `at_large_or_mixed_review` | 5 | MA committees, ex-officio mayors, at-large | **Skip / partial** |
| `mixed_review` | 1 | District seats + at-large seats on one board | **Partial** — load only the district seats |

⚠ The title signal is a starting point, not a verdict:
- **False positives:** TX "Place" and OR "Position" are at-large, not districts — exclude.
- **False negatives:** Utah's generic "School Board Member" is single-member — include.
- **Mixed boards:** Indianapolis (district + 2 at-large), Richland-Bean Blossom (township +
  at-large), Clark County NV (7 elected districts + 4 appointed) — load only the geographic
  seats, leave the at-large/appointed ones on the corporation.

## Where the boundaries come from (per state)

School-board subdistricts are **not** in Census TIGER — each set is sourced separately.
Record every source in `boundary-source-registry.md` as you go.

| State | Boards | Where the seat boundaries live | Notes |
|---|---:|---|---|
| CA | ~84 | County Registrar-of-Voters / county GIS "trustee area" layers; CA statewide open-data | Biggest bucket. Many are trustee-area single-member; some elementary districts are at-large. Classify per district first. |
| UT | 17 | County / district "local school board district" precinct maps | All single-member; generic titles. Utah counties publish these with precincts. |
| OR | 3 of 12 | County election GIS (Zone layers) | Only the "Zone" boards (Portland, Beaverton, Bend-La Pine); the "Position" boards are at-large — skip. |
| IN | 2 remaining | County election GIS (as MCCSC: `services1.arcgis.com/nYfGJ9xFTKW6VPqW` layer 15 has RBBSC; Martinsville is Morgan County) | MCCSC done. Load Richland-Bean Blossom + Martinsville; Indianapolis is mixed. |
| NV | 1 | Clark County GIS trustee districts | 7 elected districts (+4 appointed — leave appointed on corp). |
| TX | 1 of 5 | Only Richardson ISD ("District N"); Allen/Frisco/McKinney/Plano are "Place" (at-large) — skip | |
| ME | 2-3 | City GIS ward/district layers | Auburn/Lewiston/South Portland — confirm ward vs at-large. |
| MA, VA, MO | 0 (likely) | — | School committees are at-large / ex-officio — skip unless a ward-based one is found. |

## Phased plan

- **P0 — done.** MCCSC (7 seats), applied + verified. Pilot proves the mechanism.
- **P1 — finish Monroe County + nearby IN.** Richland-Bean Blossom (same county layer),
  Martinsville (Morgan County). Small, same template.
- **P2 — Utah (17 boards, 105 seats).** High value (your home state), one sourcing pattern
  (county precinct → local school board district). Bundle with the compass education lens.
- **P3 — California (the ~90 review + trustee-area boards).** Largest and most nuanced.
  Start by classifying single-member vs at-large from county trustee-area layers; load the
  single-member ones. Consider a county-by-county sweep (LA County covers most).
- **P4 — OR "Zone" boards, NV Clark, TX Richardson, ME.** Long tail, one board at a time.

## P1 worked examples (Indiana)

- **MCCSC** — done (P0 pilot). 7 single-member districts from Monroe County layer 15.
- **Richland-Bean Blossom** — **done 2026-09-03**. Township-based: 2 Richland + 2 Bean Blossom +
  1 at-large. Reused the TIGER G4040 township polygons already in the DB (Richland `1810564152`,
  Bean Blossom `1810503808`; verified they cover 99.9% of the corp) as `X0002` sub-districts;
  the at-large seat stays corporation-wide. A township address now returns its 2 members + the
  at-large (5 → 3). Script: `backend/scripts/apply-rbb-township-subdistricts.sql`.
- **MSD of Martinsville** — **scoped, not built. Needs Morgan County PRECINCT polygons.** Its 5
  districts are built from voting precincts (not whole townships), so TIGER townships cannot be
  reused. District→precinct assignment (from Morgan County records, unverified — confirm against
  the county's precinct names before use):
  - D1: Washington 1, 2, 3, 5
  - D2: Washington 4, 6, 10
  - D3: Washington 7, 9; Green 1, 2
  - D4: Washington 8; Clay 1, 2, 3
  - D5: Ray 1, 2; Jefferson 1, 2; Baker
  To build: obtain Morgan County (FIPS 18109) precinct polygons (county GIS or IN statewide
  precinct layer), dissolve them into the 5 districts per this map, load as `X0002`, relink the
  5 offices. Same pattern as MCCSC once the precinct geometry is in hand.

## P2 (Utah, 17 boards / 105 seats) — sourcing reality

Investigated 2026-09-03. Utah is **harder than Indiana** for two reasons, so it is not a
quick apply:

1. **No single statewide layer of LOCAL board districts.** UGRC's "Utah School Board Districts
   2022–2032" (`services1.arcgis.com/99lidPhWCzftIe9K/.../UtahSchoolBoardDistricts2022to2032`)
   is the **15 STATE** board districts — already loaded as `X0003`. The local single-member
   districts inside Alpine, Granite, SLC, etc. are drawn per district/county and are **not**
   in one UGRC layer. Likely sources: each county's GIS, or UGRC "Vista Ballot Areas"
   precincts (`.../VistaBallotAreas/FeatureServer/0`) joined to a precinct→local-board-district
   crosswalk. Per-district / per-county sourcing.
2. **Generic seat titles.** Every Utah seat is titled "School Board Member" with no district
   number and no `district_id` — so, unlike MCCSC, we cannot map office→sub-district from our
   own data. Each district needs a roster (member name → local board district number) matched
   to our politician rows before the offices can be repointed. Do NOT guess this — a wrong
   guess puts a real member in the wrong district.

**Recommended P2 approach:** pilot ONE district end-to-end first, proving both halves (boundary
source + roster match). Then batch by county: Salt Lake County covers Granite, Canyons, Jordan,
Murray, SLC; Utah County covers Alpine, Provo, Nebo. The load/verify reuses the MCCSC template.

**SLC pilot sourcing (checked 2026-09-03) — boundaries are NOT openly published.** Unlike
Indiana (Monroe County published a clean "School Board Districts" layer), Salt Lake City School
District's 7 board precincts are not available as a queryable GIS layer:
- **UGRC** SGID: only the 15 STATE board districts (already X0003) and whole school-district
  outlines — no local board precincts.
- **SLCSD's own ArcGIS** (`services.arcgis.com/mTn3NREkFvvzmXi0/.../SLCSD_Schools_Web_Map_all_layers_WFL1`):
  86 layers, all school-attendance zones — no board precincts.
- **ArcGIS Online** search: no SLC board-precinct layer.
- **Salt Lake County Clerk** elections service (`apps.saltlakecounty.gov/slcogis/rest/services/Surveyor/SLCoElections/MapServer`):
  exists but layers are not openly enumerable (restricted/empty response).

So Utah local board boundaries need one of: (a) **manual digitization** from each district's
board-precinct PDF (the `manual_digitize_provo_wards_2026_pdf` precedent in `arcgis_sources.json`),
or (b) a **precinct→board-district crosswalk** obtained from each county clerk (records request)
applied to the county voting-precinct polygons. Both are per-district and materially more
expensive than Indiana. **Plus** the roster→office match (generic titles) is still required.
Recommend a sourcing decision before proceeding: pick the digitize-vs-crosswalk path, or defer
Utah until a county crosswalk is available. When loading, use `load-arcgis-from-config.ts` (now
ST_MakeValid-guarded) via an `arcgis_sources.json` entry per district.

**Alpine — SKIP (transition case, 2026-09-03).** Do NOT load Alpine with the county C/T/W codes.
Alpine School District is **splitting into three new districts** — **Aspen Peaks** (`C`: Alpine,
American Fork, Cedar Hills, Highland, Lehi, Draper), **Timpanogos** (`T`: Lindon, Orem, Pleasant
Grove, Vineyard), **Lake Mountain** (`W`: Eagle Mountain, Saratoga Springs, Cedar Fort, Fairfield).
That is why the county has **21** `LOCALSCHOOL` codes (3 districts × 7 board seats): they are the
NEW post-split boards. 21 new members were elected Nov 2025 and seated Dec 2025 (transition
boards); the new districts open for students 2027–2028. Our DB still holds the **current** Alpine
7-member board, which governs until 2027. Representing this correctly (current Alpine board vs the
3 new transition boards) is an editorial/data-model decision + a large seed (3 governments + 21
members) — revisit when EV decides. County boundaries for the new 21 are ready (C/T/W × 7) when
that project happens.

**Nebo — DONE 2026-09-03.** Utah County N1–N7 dissolved into 7 X0002 sub-districts; seeded the
2 members our DB was missing — Shannon Acor (D5) + John Taylor (D6) — as politician+office+term
records mirroring the existing Nebo seats (chamber "Nebo School Board", `data_source=ut-school-nebo`,
`party=NULL`, external_id −307280/−307281). All 7 verified to correct member (Santaquin→Rowley,
Payson→Wilson, Mapleton→Betts, Salem→Ainge). Script `backend/scripts/build-nebo-board-subdistricts.cjs`.

**⚠ Verified county `N#`/`P#` = board District `#` (2026-09-03).** The Nebo board PAGE's granular
precinct enumeration is stale/imprecise and appeared to disagree with the county — but anchor
checks (a school/city center known to a district, point-queried against the county precinct layer)
confirmed county number = board district number for BOTH Provo (Franklin→P5, Provost→P4,
Lakeview→P6) and Nebo (Santaquin→N1, Mapleton→N2, Salem→N4, Payson→N7). So dissolving by county
`LOCALSCHOOL` is authoritative; **Provo (loaded earlier) was verified correct, no fix.** When a
board page's precinct list conflicts with the county, trust the county (it runs the election) and
verify with anchors — do NOT assume the board page's precinct enumeration is current.

**UPDATE — Utah COUNTY publishes the crosswalk openly (2026-09-03).** Salt Lake County's
election GIS is restricted, but **Utah County's is open** and its voting-precinct layer carries a
`LOCALSCHOOL` field tagging each precinct with its local board district:
`https://maps.utahcounty.gov/arcgis/rest/services/Elections/Election_Precincts/MapServer/0`
(fields incl. `LOCALSCHOOL`, `STATESCHOOLBOARD`, `PRECINCTID`, `CITY`). So for Utah County
districts the boundaries ARE derivable: **dissolve precincts by `LOCALSCHOOL`**. Decoded by
geography: `P#` = **Provo** (7 → matches our 7 Provo seats), `N#` = **Nebo**; the `C/T/W#`
prefixes all fall in **Alpine** territory (Lehi, Pleasant Grove, Eagle Mountain) and need the
county's data dictionary to decode which prefix+number is which Alpine board district — do NOT
guess. Other Utah counties likely expose the same field; check each county's precinct layer.

**Provo P2 pilot — DONE 2026-09-03.** Applied + verified: a Provo address returns exactly one
board member (central→Van Wagenen/D3, east→Hall/D2, south→McCabe/D5). Built by dissolving the 60
Utah County precincts (P1–P7) into 7 `X0002` sub-districts and repointing offices via the roster
below. Script: `backend/scripts/build-provo-board-subdistricts.cjs`; geometry:
`backend/data/provo-board-subdistricts/`. ⚠ `district_id` must be globally unique — scope it to
the geo_id (`4900810-board-d{N}`); the first attempt used the un-scoped `board-d{N}` and collided
with MCCSC (caught by the atomic rollback). Establishes the Utah county-precinct-dissolve pattern.

**Sourcing that made Provo possible (kept for the rest of Utah County):**

- **Boundaries:** dissolve Utah County precincts `WHERE LOCALSCHOOL LIKE 'P%'` grouped by
  `LOCALSCHOOL` (P1–P7) → 7 polygons. Source layer above.
- **Roster** (verified vs provo.edu / board pages): district → our office holder:
  P1 Lisa Boyce · P2 Melanie Hall · P3 Megan Van Wagenen · P4 Jennifer Partridge ·
  P5 Teri McCabe · P6 Emily Harrison · P7 Gina Hales. (Provo corp geo_id `4900810`.)

**Build steps (next):** (1) fetch P-prefix precinct GeoJSON from the Utah County layer;
(2) `ST_Union` by `LOCALSCHOOL` into P1–P7 (ST_MakeValid); (3) insert 7 `X0002` geofences
(`geo_id='4900810-board-d{N}'`) + 7 `SCHOOL` sub-districts; (4) repoint each office to its
district per the roster above; (5) verify one member per address. NB: `load-arcgis-from-config.ts`
loads one geofence PER FEATURE and does not dissolve — Provo needs a dedicated dissolve-then-load
step (per-precinct rows would collide on geo_id under ON CONFLICT DO NOTHING). NB2: the node/pg
write path is blocked (rotated `.env` DATABASE_URL); load via the Supabase MCP or after the
credential is refreshed.

## Engineering note

- `government_body_name` on sub-districts is empty (the `government_bodies` join keys on
  `geo_id`, now the sub-district's). Cosmetic — grouping falls back to `government_name`. If
  the School Board tab label looks wrong at scale, add `government_bodies` aliases for the
  sub-district geo_ids, or relax the join to the corp geo_id for `X0002` rows.
- Idempotent, transactional loads; rollback recipe in the pilot README.
