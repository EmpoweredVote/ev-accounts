# Knight Foundation Cities — Civic Seed Program

**Status:** approved design, 2026-08-28
**Scope:** 26 Knight Foundation jurisdictions in 16 states. City and county elected offices, their
state legislatures, headshots for every person, and a city banner for each city.
**Out of scope:** compass stances. Stances are a separate program that follows this one, together
with the deferred Nashville stances.

---

## 1. Why this is a program of state slices

The request names 26 cities. The work does not decompose that way. Four of the five stages in §3 are
**state**-scoped, and each is reused by every jurisdiction inside its state:

1. The TIGER polygon load.
2. The legislature roster builder and migration generator.
3. The county officer template, which state law defines.
4. The banner adjacency test — Georgia's three cities must not repeat each other, or Georgia's state
   banner.

So the unit of work is a **state slice**, not a city. There are 16 slices.

## 2. Measured starting position

All figures measured against production on 2026-08-28.

### 2.1 State legislatures — 13 of 16 states need work

| Status | States | Seats owed |
| --- | --- | --- |
| Complete | CA (80+40), CO (65+35), NC (120+50) | 0 |
| Partial | IN — 12 of 100 House, 6 of 50 Senate | 132 |
| Empty | FL, GA, KS, KY, MI, MN, MS, ND, OH, PA, SC, SD | 2,023 |

**2,155 legislative seats owed.**

### 2.2 Geography is the hidden prerequisite

County polygons (`G4020`) exist for all 16 states. `place` (`G4110`), `sldu` (`G5210`) and `sldl`
(`G5220`) polygons exist for **only CA, CO, IN and NC** — the states already seeded. The other 12
states hold **zero**. Without them, no legislator and no citywide office is reachable by address.

`backend/scripts/load-state-tiger-boundaries.ts` is already general. It supports `cd`, `cd119`,
`sldu`, `sldl`, `place`, `county`, `cousub`, `unsd`, `elsd` and `scsd`. Adding a state means an entry
in `STATE_LAYER_ALLOWLIST` plus a pre-flight block asserting counts verified against the raw TIGER
file. That is proven work, not new work.

### 2.3 Local and county — effectively greenfield

24 of the 26 jurisdictions have **no** local or county seats. Two look partial and both are missing
their entire council:

| Jurisdiction | Exists | Absent |
| --- | --- | --- |
| Long Beach, CA | Mayor, City Attorney, City Auditor, City Prosecutor. 4 of 4 have headshots. | all 9 council districts |
| San José, CA | Mayor only | all 10 council districts |

Los Angeles County and Santa Clara County hold partial rows from the CA county wave. Santa Clara has
0 headshots.

**Long Beach and San José are the program's cautionary case.** Both read as "covered" while no
address in either city returns a council member. This is why the acceptance test in §5 is an
end-to-end address probe and nothing cheaper.

### 2.4 Banners — 24 of 26 missing

Only `long beach` and `san jose` exist in the essentials repo's `src/lib/buildingImages.js`.
(`boulder city` is Boulder City, Nevada — a different place, not Boulder, Colorado.)

### 2.5 Program total

| Tier | Seats |
| --- | --- |
| State legislatures | 2,155 measured as owed |
| Local and county | 500–700 estimated |
| **Total** | **~2,700** |

Nashville's 42 seats took one wave. This program is 40 to 60 waves. It is expected to run across many
sessions.

## 3. The state slice — five stages

| Stage | Output | Skipped for |
| --- | --- | --- |
| 1. Geography | TIGER `place` + `sldu` + `sldl` loaded and verified | CA, CO, IN, NC |
| 2. Legislature | Roster JSON → structure migration + occupancy migration | CA, CO, NC |
| 3. City waves | One per jurisdiction: council-district layer + structure + occupancy | Palm Beach County |
| 4. County waves | Commission layer + county officers — offices **and** people in ONE migration | never skipped; see §3.2 |
| 5. Assets | Headshots for every person seated in the slice, plus one banner per city | — |

**Stage 2 precedes stage 3.** The acceptance test is a four-answer address probe, and two of those
answers are the state representative and the state senator. A city wave run before the legislature
can only ever score 2 of 4.

**Stage 4 keeps the Nashville correction.** An office with no `office_terms` row is invisible: no
holder, so the official never appears anywhere, and nothing errors. Shipping county offices in one
wave and county people in the next would push `essentials.offices_missing_terms` above its
699-unflagged baseline for the days between the two applies. Offices and people ship together.

### 3.1 Slice order

Grouped by state, largest group first:

| Group | States | Jurisdictions |
| --- | --- | --- |
| 1 | FL | Bradenton, Miami, Palm Beach County, Tallahassee |
| 2 | GA | Columbus, Macon, Milledgeville |
| 3 | CA, IN, MN, PA, SC | 2 each |
| 4 | OH, CO, NC, MI, ND, KY, KS, SD, MS | 1 each |

CA, CO and NC are the cheapest slices, because they skip stages 1 and 2 entirely. Indiana skips only
stage 1: its polygons are loaded, but its legislature still owes 132 seats, so stage 2 there is roster
work with no geography work. FL and GA are the most expensive — full geography plus a full legislature
plus four and three jurisdictions. This ordering therefore front-loads the hardest work deliberately,
so the pipeline is proven under load early rather than late.

### 3.2 A consolidated city-county still has a stage 4

Consolidation merges the **legislative body**. It does not merge the separately elected county
officers. Philadelphia still elects its row officers; Lexington–Fayette still elects a Sheriff, a
County Clerk and a Property Valuation Administrator; Macon–Bibb and Columbus–Muscogee still elect a
Sheriff, a Clerk of Superior Court and a Tax Commissioner.

So for the four consolidated jurisdictions, stage 4 drops the **county commission** — because the city
council already is it — and keeps the county officers. Stage 4 is never skipped entirely. Which
officers are separately elected is confirmed from the charter in that wave, never assumed.

## 4. Wave anatomy

Every wave follows the Nashville shape. Nothing downstream can be more correct than the roster file
it is generated from.

1. **Pull sources to disk.** Two or more independent sources per body, kept untracked under
   `backend/data/seed-<jurisdiction>-2026/` for the length of the wave. They are the evidence.
2. **Diff the sources and list every disagreement.** A human settles each one from the officeholder's
   own page.
3. **Check every seat for a change since the sources were last edited.** A source cannot report a
   change that postdates it, and a resignation is exactly what silently seats the wrong person.
4. **Write `ROSTERS.md`** with a `## Sources` table, a `## 🔴 Source defects found` section, a
   `## Charter rulings` section, and one roster table whose columns the generator parses.
5. **Generate the migrations** from that file with a script. Structure first, occupancy second, so a
   re-seat never re-runs office creation. County waves emit **one** migration, per §3.
6. **Dry-run against production** by wrapping the body in a transaction that ends in `ROLLBACK`,
   through `psql "$DATABASE_URL"`, and confirm the rollback reverted.
7. **Take the migration number last.** Write files as `CC_wip_*.sql`, then rename, apply and commit in
   one go.

### 4.1 Standing constraints

- **Migration namespace is `CC_`** (Chris Cantrell). Next free slot is `CC_0006`, measured
  2026-08-28. Re-verify with `git fetch origin` and `npm run check:migrations --prefix backend` at
  the start of every wave.
- Every migration is idempotent and ends with an anonymous `DO` block post-verify gate that raises an
  exception on a wrong count.
- `ev_api` cannot create objects in `essentials`. These migrations are DML only, so `psql` works. Do
  not use the Supabase MCP for the apply — it wraps each call in its own transaction, which destroys
  the dry-run rollback semantics of step 6.
- `outSR=4326` is load-bearing on every ArcGIS fetch.
- Always pair `geo_id` with `district_type` in a join. Never match a district on `label`.
- No party affiliation on a person or an office. Party lives on `races.primary_party`.
- No `term_end` is written. A future `term_end` makes a seat silently self-vacate.
- `politicians.alternate_names` is `NOT NULL DEFAULT '{}'`. Emit an empty array, never NULL.
- `office_current_holder` LEFT JOINs from `offices`, so a vacancy is a NULL `politician_id`, not an
  absent row. Seated counts use `count(och.politician_id)`, never `count(*)`.
- `term_start` is the start of continuous occupancy by that person, not the start of the current term.
  Re-election does not end an occupancy.
- Do not invent a date. `start_precision` is `day` / `month` / `year` / `unknown`, per source, per
  person.
- Always `lower(d.state)` — `essentials.districts.state` is mixed case.
- `cwd` resets between Bash calls. Prefix every command with `cd /c/EV-Accounts/backend &&`.

## 5. Gates and the definition of done

Per wave:

- `npm run check:migrations --prefix backend`, after `git fetch origin`.
- `npm run check:occupancy --prefix backend`.
- A read-only `verify-<jurisdiction>-import.sql`, matching the existing `verify-*-tiger-import.sql`
  siblings.
- `npm run check:reachability`.

**Definition of done for one jurisdiction:** an address at city hall returns its council member, its
county commissioner, its state representative and its state senator. Four answers, one probe.

`check:reachability` is the **only** acceptance test. Every cheaper check passes vacuously when a term
row is missing.

🔴 **CORRECTED 2026-09-01 (GA-3). This paragraph used to end "a new probe scoped `place:<slug>` is
added to the reachability gate for each jurisdiction". THAT IS NOT HOW THE GATE WORKS, and it had been
carried unchallenged through eight waves.** `scripts/check-address-reachability.mjs` takes **no
per-jurisdiction probe list**: it sweeps every district of an addressable `district_type` and reads its
MTFCC mapping out of `src/lib/geoIdGuard.ts` at runtime, deliberately, so the mapping has exactly one
definition. There is nothing to add.

⚠ **The consequence matters, because it is a vacuous-pass risk.** A green
`check:reachability` after a wave means "no district regressed"; it does **not** prove the wave's own
districts were examined. So the acceptance evidence for a jurisdiction is two things, not one:

1. the wave's own **probe file** (`scripts/verify-<jurisdiction>-probes.sql`), asserting the four
   required answers at city hall — and a **second anchor** wherever two tiers number the same ground,
   which is what catches a wave that crossed them; plus
2. a **per-district positive control** — every new district tested at its own interior point,
   asserting exactly one holder — which is what distinguishes *swept and clean* from *not swept*.

GA-3 ran both: 4 of 4 at City Hall, a second anchor returning different numbers on both tiers, and
11 of 11 districts resolving individually.

## 6. The ledger

This program spans dozens of sessions. `MEMORY.md` has a hard 19 KB ceiling and silently drops its
tail past 24.4 KB, so the tracker lives on disk.

| File | Purpose |
| --- | --- |
| `docs/superpowers/specs/2026-08-28-knight-cities-program-design.md` | this spec |
| `.planning/knight-foundation/PROGRAM.md` | live tracker: 16 slices × 5 stages, status and measured counts, updated at the end of every session |
| `.planning/knight-foundation/<state>.md` | per-state notes: verified TIGER counts, county officer template, source URLs, defects found |
| `backend/data/seed-<jurisdiction>-2026/ROSTERS.md` | the verified roster per jurisdiction |

`MEMORY.md` gets exactly one line, pointing at `PROGRAM.md`.

## 7. Headshots

Two tiers, two methods, because the sources differ.

| Tier | Method | Expected yield |
| --- | --- | --- |
| Legislature (~2,155) | The chamber's own roster carries official portraits for the whole body at one URL. One script per chamber, cloned from `scripts/seed-wi-legislature-headshots.py`. | High |
| Local and county (~550) | A per-person hunt down a source ladder: official city or county page → `<county>dems.org/elected-officials` → local press → Ballotpedia original, dropping `thumbs/200/300/` from the api4 path. | Historically well under 100% |

The 46 `scripts/seed-*-house-headshots.py` files target **US House candidates** through Wikipedia, not
legislatures. Their pipeline still transfers: license check → download → 4:5 crop → 600×750 LANCZOS
q90 → upload → guarded insert.

### 7.1 Standing rules — not re-asked per cohort

- Press, official and public-domain sources only. **Never Facebook or any social network.** Campaign
  photos and official rosters are acceptable. A photographer's copyright is a refusal.
- Approval is always a batch contact sheet, never one dialog per person.
- Crop about one ear above the hair.
- The upscale gate measures the **face** crop, not the frame.
- Skip monochrome, judicial portraits included.
- The import guard joins `external_id` **and** `full_name`, so a wrong id drops the row rather than
  seating a stranger.
- Ballotpedia homonyms hide behind a bare title. Test for state and county.
- Report **measured yield in usable headshots**, never a count of files touched.

### 7.2 Review unit

One contact sheet per **body**, capped at 40 faces and paged. The Florida House is 3 sheets; the Miami
city commission is 1.

## 8. Banners

24 cities need one. Palm Beach County is a county and has no city key — see §8.3.

### 8.1 The adjacency rule

A city banner must not repeat the **composition** of its state banner, or of a sibling city in the
same state group. Compare compositions, not subject nouns.

Four cities have a hard conflict, because their own skyline is already the **state** banner:

| City | Conflicting state banner |
| --- | --- |
| Miami, FL | FL — Miami Late Afternoon Skyline |
| Wichita, KS | KS — Wichita, Kansas skyline |
| Detroit, MI | MI — Detroit Skyline from Windsor |
| Charlotte, NC | NC — Charlotte uptown skyline (daytime) |

These four need a **different frame**, not a different skyline photograph.

Georgia's three cities must also differ from each other, and Florida's four likewise. This is testable
only when the group is seen together, which is why banners are a stage-5, per-slice review.

### 8.2 Certification

In the 6:1 desktop band, at real CSS, at real aspect. Rejected options and the live baseline are shown
alongside. Measured, not eyeballed. For banners with people in them, test **scale**.

Banners live in the essentials repo (`C:\Transparent Motivations\essentials`) at
`src/lib/buildingImages.js`, plus the Supabase storage bucket. `treasury.municipalities` is dead.
Overwriting a file does **not** purge the CDN.

### 8.3 Open decision, deferred not hidden

`buildingImages.js` is keyed by city. Palm Beach County has no city. The options — a county key, or
the Florida state banner as a fallback — are brought to the user at wave FL-5 rather than guessed now.

## 9. Approval artifacts

Headshot contact sheets and banner comparisons are **published as Artifacts** and the link is handed
to the user. Not terminal text, not a static image file, not one dialog per person.

Constraints that follow from the Artifact sandbox:

- A strict CSP blocks external hosts. The Supabase storage CDN will **not** load. Images must be
  embedded as `data:` URIs, or uploaded as artifact assets where that capability is available.
- The rendered page must stay at or under 16 MB, and base64 inflates a payload by about a third.
  Contact-sheet thumbnails are therefore emitted at 300×375, not at full 600×750 — roughly 30 KB each,
  so a 40-face page lands near 1.2 MB.
- Banner review pages show the real 6:1 band at real CSS. Give the page an explicit neutral ground in
  both themes, so the viewer's theme cannot tint the judgement.
- Load the `artifact-design` skill before writing any approval page, and `artifact-capabilities`
  before declaring any capability such as asset upload.
- Re-publishing the same file path redeploys to the same URL. Keep one stable path per slice so the
  link the user holds stays current.

## 10. Named risks

- **North Dakota and South Dakota elect multi-member House districts.** ND elects 2 representatives
  from each of 47 districts, so TIGER `sldl` gives 47 polygons for 94 seats. SD elects 70
  representatives from 35 districts, with districts 26 and 28 split into A and B subdistricts. The
  loader's pre-flight must assert polygon count against **seat** count separately. AZ and WA already
  set this precedent in the file.
- **Four jurisdictions are consolidated city-counties** — Columbus–Muscogee GA, Lexington–Fayette KY,
  Macon–Bibb GA and Philadelphia PA. There is no separate county commission. The parent geography is
  the county FIPS, never the TIGER place. Each must be checked for the Nashville trap: a satellite city
  inside the county whose residents still elect the consolidated council.
- **Miami-Dade County and the City of Miami are separate governments.** Miami-Dade is not a
  consolidated city-county. Do not conflate them.
- **Certified election results change column count by year.** Nashville's 2019 and 2015 results added
  `FS / PV` and `Percent` columns; a fixed-column parser read 0 for every total, ranking degraded to
  "first row listed", and nine seats were wrong with no error raised. Any results parser asserts its
  column count per file.
- **`geo_id` collisions.** 1,159 collisions exist across 13 states. `src/lib/geoIdGuard.ts` guards
  production; ad-hoc SQL does not.
- **A uniform answer is a broken detector until a positive control passes.** The coverage query behind
  §2 returned almost nothing for all 26 jurisdictions. It became trustworthy only after Nashville
  returned 42, Asheville 17 and Durham 15.

## 11. What this program does not do

- No compass stances. That is the next program, and it includes the deferred Nashville stances.
- No school boards. City and county elected offices only, per the approved scope.
- No special districts.
- No candidates. Incumbent officeholders only. Offices titled `Candidate for%` are excluded from every
  count in this spec.

## 12. First slice — Florida

Roughly 238 seats across 7 waves.

| Wave | Content | Seats | Artifacts |
| --- | --- | --- | --- |
| FL-1 | TIGER `place` + `sldu` + `sldl`, FIPS 12. Counties already loaded (67). | 0 | allowlist entry, pre-flight block, `verify-fl-tiger-import.sql` |
| FL-2 | Florida Legislature — House 120, Senate 40 | 160 | roster JSON + 2 migrations |
| FL-3 | Bradenton + Manatee County | ~18 | ward layer, 2 + 1 migrations |
| FL-4 | Tallahassee + Leon County | ~22 | 2 + 1 migrations |
| FL-5 | Palm Beach County (county only) | ~12 | commission layer, 1 migration |
| FL-6 | Miami + Miami-Dade County | ~26 | 2 + 1 migrations |
| FL-7 | Florida assets | — | headshots for all 238, 3 banners |

FL-2 is 160 seats. That is the **lowest-risk** large wave available: North Carolina seated 170 in one
wave through `scripts/build-nc-legislature-roster.mjs` and
`scripts/gen-nc-legislature-migrations.mjs`, and Florida clones both. FL-3 is deliberately the
smallest jurisdiction in the group, so the city and county vertical is proven at 18 seats before Miami
costs anything.

### 12.1 Florida facts to verify, not assume

- Florida's constitutional county officers are Sheriff, Tax Collector, Property Appraiser, Supervisor
  of Elections and Clerk of the Circuit Court. **Charter counties vary**, so the template is confirmed
  per county, never inherited from the state.
- Miami-Dade's elected Sheriff was restored by constitutional amendment and filled recently. Confirm
  the office is elected before seeding it.
- Tallahassee's city commission may be entirely at-large. If it is, no ward layer is needed and the
  citywide `place` polygon carries every seat.
- Florida runs frequent legislative special elections. Every one of the 160 seats gets the
  change-since-source check of §4 step 3.
- Florida's `place` layer is roughly 410 municipalities. The pre-flight asserts the real count against
  the raw TIGER file before any write.

### 12.2 Next step

Each wave gets its own implementation plan under `docs/superpowers/plans/`, written through the
`writing-plans` skill. FL-1 and FL-2 are planned together, because FL-1 produces nothing observable on
its own.
