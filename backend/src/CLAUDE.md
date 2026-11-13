# backend/src — repo facts for the API and its queries

Moved here from the root `CLAUDE.md` (2026-11-12). The officeholder occupancy rules (how to read
`office_current_holder`, the `is_vacant` trap) live in `backend/migrations/CLAUDE.md` and are imported here:

@../migrations/CLAUDE.md

## Repo facts worth knowing

- Party affiliation is **antipartisan** by design: party lives on `races.primary_party` (which ballot
  a voter requests), never on `race_candidates`.
- `geofence_boundaries.state` holds **2-digit FIPS**, not USPS codes — ⚠ **EXCEPT ON THE `G4000`
  STATE-OUTLINE LAYER, WHERE IT HOLDS USPS.** Measured 2026-11-08: of its 53 rows, 52 carry
  `'NH'`, `'CA'`, … , one carries `'72'` and one is NULL. So a state-outline lookup written the
  way this line used to read — `mtfcc = 'G4000' AND state = '33'` — returns **nothing**, and an
  empty result reads as "we hold no outline for this state", which silently SKIPS a coverage gate
  rather than failing it. 🔴 **Key the state outline on `geo_id`** (`geo_id = '33'`), as the
  tier-3 loaders do.
- 🔴 **`geo_id` IS NOT UNIQUE — THE KEY IS THE PAIR `(mtfcc, geo_id)`.** Measured: **1,159
  collisions across 13 states**, because a place and a county subdivision can share a number.
  `geoIdGuard.ts` enforces the pair on the production write path; **ad-hoc SQL does not**, so a
  hand-written join on `geo_id` alone silently matches the wrong geography. ⚠ **`ocd_id` ROLLS UP,
  `geo_id` LOOKS UP** — they answer different questions and are not interchangeable.
- 🔴🔴 **A CITY CAN BE FULLY SEEDED, ANSWER EVERY ADDRESS, AND STILL BE INVISIBLE ON THE MAIN
  PAGE.** The landing chip keys on **`governments.geo_id`**, which address search never touches, so
  the two surfaces fail independently and neither one's success implies the other's. 🔴 **THE ONLY
  RELIABLE DETECTOR IS END-TO-END: does a city-hall point return a council member?**
  `check:reachability` runs on master-push and cron — **not on PRs** — and takes no probe list, so
  **green does not mean your districts were swept.**
- 🔴🔴 **SUPABASE STORAGE NEEDS BOTH `apikey` AND `Authorization` HEADERS** (key `sb_secret_…`). A
  lone Bearer is refused as **HTTP 400 with a body saying 403 "Invalid Compact JWS"**, which reads
  like a missing object and sends you looking in the wrong place.
  - 🔴🔴 **STORAGE ANSWERS ON TWO HOSTNAMES** — `<ref>.storage.supabase.co` *and* `<ref>.supabase.co`.
    **Match on the PATH `%supabase.co/storage/v1/object/public/%`, never on the host:** a host-based
    `LIKE` once classified **1,279 of our own mirrored headshots as "hotlinked"**.
- 🔴🔴 **PROD AUTHENTICATES AS `ev_api`, AND A SUPABASE PASSWORD RESET ROTATES `postgres` ONLY.** So
  the break you will see is a **mismatched username**, not an expired secret. **Test a credential
  against a DATA endpoint** — `/api/health` touches no data and passes with a dead database.
- 🔴 **`districts.geo_id` IS A LOOKUP KEY, SO AN EMPTY ONE IS A KEY NOTHING CAN EVER MATCH.** A
  district with `geo_id = ''` is invisible to every `geo_id`-keyed read — today that is the
  `government_bodies` join in `DISTRICT_SELECT_FIELDS`, which simply never fires for it. The seats
  still answer an address, because the statewide branch admits by `district_type` + `state`, so
  nothing looks broken. `gen-state-exec-seed.mjs` already RAISEs on an empty `STATE_EXEC` geo_id
  for the states it covers; `CC_0297` fixed the last multi-office one outside that list (Indiana's,
  10 offices). ⚠ One single-office case is left on purpose — California's Board of Equalization
  seat, which needs a BOE-district geo_id, not the state FIPS.
  - ⚠ **A SHARED DISTRICT HOLDING SEVERAL OFFICES IS A LEGITIMATE VARIANT, NOT A DEFECT.** Measured
    across all 51 jurisdictions: 48 give each statewide executive its own district; CA (17 offices),
    OR (5) and IN (10) share one. Do not "normalise" one of those into per-office districts — check
    whether its key is wrong before deciding its shape is.
- 🔴 **`districts.district_type` IS A ROUTING KEY TOO, NOT A TAXONOMY LABEL — PICK IT BY WHAT READS
  IT.** `buildStatewideQuery` admits a seat **by type**, and the list is closed:
  `NATIONAL_UPPER`, `NATIONAL_EXEC`, `STATE_EXEC`, `NATIONAL_JUDICIAL`, `JUDICIAL` (plus DC's two
  at-large `geo_id`s). **`STATE_BOARD` and `STATE_BOARD_EDUCATION` are not in it.** Those reach a
  voter only through the geofence join, keyed on a particular `mtfcc` — `X0003` (Utah SBOE),
  `X-CA-SBOE` (California BOE), `G5220` (DC) — because every board filed under them is
  **districted**. ▶ **A board elected STATEWIDE AT LARGE belongs on `STATE_EXEC` with the state
  FIPS**, which is what Arizona's Corporation Commission already is.
  ⚠ `CC_0364` nearly filed Michigan's elected State Board of Education under
  `STATE_BOARD_EDUCATION` because that is the name that fits. It has no sub-state polygon, so all
  eight members would have been **unreachable from every Michigan address and nothing would have
  errored** — the same failure as an empty `geo_id`, reached from the other direction.
  - 🔴 **A DISTRICT IN A SEAT'S TITLE IS A CLAIM ABOUT THE CANDIDATE, NOT NECESSARILY ABOUT THE
    ELECTORATE. READ WHO VOTES.** Georgia's Public Service Commissioners each *reside* in a
    numbered district and are **chosen statewide**; Hawaii's OHA "Maui Resident Trustee" is elected
    by the whole state; Alabama's PSC "Place 1" and "Place 2" are ballot positions on an at-large
    commission. All three read as districted and none of them is, and all three were in the
    inventory of seats "blocked on real geometry" until somebody read the enabling text
    (`CC_0364`, `CC_0366`).
  - 🟢 **BEFORE IMPORTING A POLYGON, ASK WHETHER THE BODY REUSES ONE WE HOLD.** Colorado's State
    Board of Education and CU Regents are elected by **congressional district**, so `CC_0366`
    copied the eight `G5200` polygons inside the database — no download, no reprojection, and the
    CRS hazard cannot arise. A gate asserts each copy `ST_Equals` the district it claims to be;
    a point-in-polygon check is **not** enough, because a consistent permutation passes it.
  - ⚠ **A NEW `X…` LAYER NEEDS AN EXPLICIT LINE IN BOTH `districtQueries.ts` AND `geoIdGuard.ts`**
    unless its district type is `LOCAL`, `COUNTY` or `JUDICIAL`, which is all the `X%` catch-all
    admits. `X0003` → `STATE_BOARD_EDUCATION` is **not state-scoped**, so any state's K-12 board
    can use it as-is. ⚠ **`geofence_boundaries.mtfcc` is `varchar(10)`** — a longer layer name
    fails only at INSERT time, after every other gate has passed.
  - 🔴🔴 **TWO BODIES CAN SHARE ONE CUSTOM LAYER INSIDE ONE STATE, SO SCOPE EVERY QUERY BY THE
    `geo_id` PREFIX AS WELL.** Nebraska's Public Service Commission and its Board of Regents are
    **both** `(X-ST-BOARD, STATE_BOARD)` in state `31`. Louisiana's commission and Colorado's
    regents sit on that layer too, but in **different states** — so `(mtfcc, state)` was a unique
    key by accident, everywhere, until Nebraska. A row count, a coverage test, or a "does this
    body already exist" pre-gate keyed on `(mtfcc, state)` alone silently reads the two bodies as
    one: without the prefix the `CC_0373`-`CC_0375` loader reports **13 rows where 8 are
    expected**, and `CC_0375` refuses to run once `CC_0373` has been applied. ▶ The prefix is the
    body — `ocd-division/country:us/state:ne/regents:%` — and controls on both the loader and the
    migration prove the scoping is load-bearing.
- 🔴 **A MULTI-MEMBER STATEWIDE BODY IS ONE CHAMBER, ONE SHARED DISTRICT, N UNNUMBERED OFFICES, AND
  ONE RACE CARRYING `seats = N`.** Arizona's Corporation Commission is the pattern (5 offices all
  titled `Commissioner`); `CC_0364` built seven more on it — HI's Office of Hawaiian Affairs (9),
  Michigan's State Board of Education (8) and MSU's trustees (8), and the ND, OK, SD and TX
  commissions (3 each). **Create the whole body, not the seats that were up**: `chambers.official_count`
  states the size, so a chamber short of it reads as a vacancy that is not there — and every office
  you create must be seated, or the 238 drift baseline rises. ▶ **Attach the race to the office of
  the member who is actually leaving**, sourced from the body's own term table; that office is what
  a seating pass replaces.
- The `essentials` frontend never queries `essentials.*` tables directly — it goes through this API.
- **Not every seat is residency-based or full-voting.** Maine seats three non-voting *tribal*
  representatives; the territories and DC send non-voting delegates.
  [`docs/adr/0003-non-residency-representation.md`](docs/adr/0003-non-residency-representation.md)
  splits those into `districts.representation_basis` (`residency` | `membership`) and
  `offices.voting_powers` (`full` | `committee_only` | `non_voting`). Live since migration 1718
  (Maine's three tribal seats) and 1719 (**all six territory/DC non-voting House seats** — PR, VI, GU,
  AS, MP, DC — plus DC's two shadow senators, who hold no seat in Congress at all).
  - **A `membership` district must never carry a `geo_id`.** Enrollment is not inferable from an
    address, so these seats are *additional and explained*, never assigned. `check:reachability`
    fails on a membership district with geometry, and excludes them from address expectations.
  - `offices.representation_note` is **required** whenever `voting_powers <> 'full'` (a CHECK) or
    `representation_basis <> 'residency'` (post-verify + read path — a CHECK can't cross tables).
    **The read path must not render such a seat without the note.**
