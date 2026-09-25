# MI — slice 11 (Detroit)

Parent county **Wayne**. Stage 1 is `sldu` + `sldl` only: Michigan's 533 `G4110` places, 1,540
`G4040` county subdivisions, 212 `G4210` CDPs, 13 `G5200` congressional districts and 83 counties
were all already present, so this is the Ohio shape — a slice that owes no `place` load.

Tracker: [`PROGRAM.md`](./PROGRAM.md). Tools this wave added:
`backend/scripts/verify-mi-tiger-vintage.mjs` and the `MI` block in
`backend/scripts/load-state-tiger-boundaries.ts`.

---

## MI-1 — geography (APPLIED 2026-09-24)

**148 boundaries and 148 districts, 38 Senate + 110 House, 0 errors.** No migration; this is a
loader, as OH-1 was. `districts` 9,850 → 9,998 and `geofence_boundaries` 72,035 → 72,183, both
**exactly +148** against a baseline measured minutes earlier in the same session through the same
connection the loader writes with. All 148 valid, SRID 4326, 0 null geometries, 38 and 110
**distinct `ocd_id`s** (no `08A`/`1A` collapse), `state` lowercase `mi`. Re-run: **0 inserted, 148
already existed** — idempotent. `offices_missing_terms` **unmoved at 423/185/238**.

### 🔴🔴 The two chambers are on different maps, and that is the whole slice

Four real plans are in play and **every one of them is 110 House / 38 Senate**, so a count dates
nothing. Michigan has had those seat totals since 1964.

In **Agee v. Benson** (W.D. Mich., 2023-12-21) a three-judge panel held that the MICRC drew 13
Detroit-area districts predominantly on the basis of race and enjoined them. The two chambers were
then remedied **on different timetables**:

| Chamber | Plan loaded | Why | The plan we refused |
| --- | --- | --- | --- |
| House (`sldl`) | **Motown Sound FC E1** — panel-approved 2024-03-27, used from the 2024 election onward | the sitting House was elected under it in November 2024 | **Hickory** (2021 MICRC) |
| Senate (`sldu`) | **Linden** (2021 MICRC, adopted 2021-12-28) | senators serve **four-year** terms and were last elected in **November 2022**, so the sitting Senate represents Linden | **Crane A1** — MICRC 2024-06-26, panel 2024-07-26, authorised **for the 2026 elections** |

▶ **THE CORRECT MAP IS NOT THE NEWEST ONE FOR BOTH CHAMBERS.** It is the map each sitting member
was elected under, and here that is a different plan per chamber. Loading Crane A1 now because it
is newer would name the wrong senator for a Detroit address for the next three months.

### 🔴 This load has a dated expiry on the Senate half

Senators elected **2026-11-03** take office **2027-01-01** under **Crane A1**. `sldu` must be
re-loaded then and the sitting senators re-seated against it. Same shape as the FL 2026 polygon
gap, and it is **six weeks away** as of this wave. The House needs nothing: Motown Sound FC E1
governs the 2026 election too.

### 🔴 `LSY` is a label, not a vintage

TIGER 2024 **and** 2025 both stamp the Senate layer `LSY=2024`, and **both carry Linden**. Measured
across TIGER 2022/2023/2024/2025, the Michigan Senate layer never moves — so **no TIGER vintage
through 2025 carries Crane A1 at all**. Reading `LSY` would have asserted the opposite. The House
layer does move, at 2023 → 2024, on 18 of 110 districts by up to 35.6% of area.

That asymmetry is exactly the trap the handoff warned about: a vintage that is right for the House
can still be carrying the pre-remedial Senate map. Here it does — and that turns out to be the
answer we want, but only because the Senate has not turned over yet. It is a coincidence with an
expiry date, not a property of TIGER.

### The authority, and why the controls are the real competing plans

The **State of Michigan's own ArcGIS organisation** (`dxRQUfTDNtfqZ301`) — which the MICRC's own
mapping-data page names as the publisher of the 2024 maps, linking out to searches for them rather
than hosting them. Four layers: the two 2021 plans and the two 2024 remedial plans.

Every one of the **3,017 Michigan 2020 census tract internal points** was located in both the TIGER
layer and the authority plan:

| TIGER 2025 | vs the plan loaded | vs the plan refused |
| --- | --- | --- |
| `sldl` | **Motown Sound FC E1 — 2,969/2,969 tracts, 109/109 locatable seats** | Hickory — 284 tracts and 6 seats disagree |
| `sldu` | **Linden — 2,968/2,968 tracts, 38/38 seats** | Crane A1 — 483 tracts and 6 seats disagree |

🟢 **The control is not a stale vintage — it is the other real plan**, and it fails in both
directions: the House's competitor is older, the Senate's is newer. `--self-test` swaps claim and
control and was **watched failing** (4 failures from 2 chambers, exit 1) before any green run was
believed.

### 🔴 The area test measured the Great Lakes, and both sides "failed" identically

The geometry half was a per-district area comparison first. It does not separate. TIGER's
legislative polygons **carry Great Lakes water**; the state's layers are clipped to the shoreline.
So House 88 differs by **931%** and Senate 31 by **450%** between two digitisations of the *same*
plan — swamping the 1.2%–35% a real redraw produces. The tell was that the claim and its control
failed on the *same districts by the same amounts*. **A metric that does not separate is a ranking,
not a gate.** Tract internal points are on land and carry no such term.

⚠ Same cause: **HD-109's own published internal point (46.720711, −87.411743) is in Lake Superior**,
about 20 km north of Marquette, and lies in no state polygon. It is declared in `KNOWN_OFFMAP` with
its reason and scored by its tract points; the verifier fails if the off-map set is anything other
than exactly the declared one, so a new one cannot hide behind it.

### ⚠ An unscoped search for these plan names is a jurisdiction collision

ArcGIS Hub's global search answers **"motown sound"** with a Detroit-history story map and
**"crane a1"** with **sandhill crane hunting zones in Texas, North Dakota and Montana**. Scope to
the org. ⚠ And the layers' `Layout` field is **not** the plan name — it reads `Landscape`.

### ⚠ michigan.gov is the inverse of the ohiosos.gov WAF

`michigan.gov` returns **403 to a bare request** and **HTTP 200 to a UA-only request**. Ohio's SOS
refused bare, UA-only *and* a full Chrome header set. A browser UA is not a key, and its absence is
not a lock — probe all three shapes. The verifier never needs michigan.gov: the MICRC page is where
the service URLs were **read**, not fetched from.

### The pre-flight, and what replaces Ohio's structural proof

⚠ **Ohio's nesting proof does not transfer.** It worked because Ohio Const. Art. XI § 4 makes every
Senate district three whole House districts. Michigan Senate districts do **not** nest in House
districts, so there is no internal cross-check at all.

What replaces it is **anchors**: four points per chamber whose district differs between the plan we
load and the plan we refuse, each a published 2020 tract internal point in the redrawn Detroit-area
corridor. The loader aborts before any DB write and **names the wrong plan** when they fail.

🔴 **The Senate anchors guard a future TIGER, not today's.** No vintage through 2025 carries
Crane A1, but 2026 is expected to, and `sldu` must not switch silently under a re-run while the
sitting senators still represent Linden.

Three controls, all watched failing:

```bash
MI_PREFLIGHT_CONTROL=count  npx tsx scripts/load-state-tiger-boundaries.ts --state MI --fips 26 --layers sldu --vintage 2025 --dry-run
MI_PREFLIGHT_CONTROL=anchor npx tsx scripts/load-state-tiger-boundaries.ts --state MI --fips 26 --layers sldu --vintage 2025 --dry-run
#   and the realistic one, which needs no flag — TIGER 2023 carries Hickory for the House:
npx tsx scripts/load-state-tiger-boundaries.ts --state MI --fips 26 --layers sldl --vintage 2023 --dry-run
```

The third reports: *"anchor 42.5061325,-82.8859088 must be district 13 under Motown Sound FC E1, and
it returned 11, which is this point's district under Hickory — THIS FILE CARRIES THE WRONG PLAN."*

### ✅ The probe, and why it had to be Detroit

| Address | House loaded | House under Hickory | Senate loaded | Senate under Crane A1 |
| --- | --- | --- | --- | --- |
| **Detroit City Hall**, 2 Woodward Ave | **9** | 10 🔴 | 1 | 1 |
| Detroit — Grandmont/Rosedale | **16** | 4 🔴 | 6 | 6 |
| Detroit — Jefferson Chalmers | **9** | 10 🔴 | **10** | 3 🔴 |
| Grand Rapids City Hall | 84 | 84 | 30 | 30 |
| Marquette | 109 | 109 | 38 | 38 |

🔴🔴 **The wrong House vintage would have named a different representative at Detroit's own city
hall** — and at Jefferson Chalmers the *Senate* answer moves too, so the Senate choice is
consequential at a real address rather than academic. **Grand Rapids and Marquette are unchanged**,
which is precisely why a spot check outside Detroit would have passed the wrong map. OH-1's lesson,
on this slice's own city.

Every Michigan point returns **exactly one** House and one Senate district; **Toledo, Ohio returns
zero**.

### ✅ Per-district control, with a positive control on the control

All **148** districts resolve at their own interior point to **exactly one** polygon of their own
type, and in every case to themselves: G5210 38/38, G5220 110/110, 0 bad, 0 resolved-to-wrong.

🔴 **148/148 is a uniform answer, so the detector was proved able to fail** before it was believed.
Fed three points it must reject, it reported: a Toledo point contained by **no** House district
(`bad`), a relabelled interior point and a Lake Michigan point both `resolved_to_wrong_district`.
⚠ The Lake Michigan point at (−87.0, 43.2) **is** inside Senate 32's TIGER polygon — the Great
Lakes finding again, from a third direction.

### 🔴 The `geo_id` collision is with counties, as in PA, SC and OH

`sldl` runs 26001..26110 and `sldu` 26001..26038, while Michigan's 83 counties are 26001..26165
odd. **Wayne County — Detroit's parent and this wave's own jurisdiction — is 26163**, outside the
legislative range, but all 38 Senate ids and most House ids collide with a county. Every join must
pair `geo_id` with `mtfcc`/`district_type`.

### 🟢 The child→county matview needed no refresh, checked not assumed

The loader always offers one. `check:child-county` reports children 13,737 · stale **0** — and
because a pass straight after a load is the shape of a vacuous pass, the reason was established:
the mapping holds **11,960 rows, all `G4110`, and zero for `G5210`/`G5220`**. MI-1 added nothing to
it. OH-1's rule re-confirmed: a legislative-only load needs no refresh; a `place` load still does.

### Gates

`check:occupancy`, `check:migrations`, `check:reservations`, `check:child-county`,
`check:ocd-suffixes`, `check:spatial-ref` all green. `check:reachability` **nothing regressed** —
BAD_GEOMETRY 4 (baseline 4), DEAD_GEOGRAPHY 17 (17), UNREACHABLE 7 (7).

### Reproducing this

The 67 MB of inputs are gitignored and regenerate deterministically:

```bash
node scripts/verify-mi-tiger-vintage.mjs --fetch              # provisions and proves
node scripts/verify-mi-tiger-vintage.mjs --self-test          # must exit 1
```

`--fetch` refuses to keep a truncated authority layer: ArcGIS pages silently, so a 200 that set
`exceededTransferLimit` is deleted rather than trusted.

---

## MI-2 — the legislature (APPLIED 2026-09-24)

**`CC_0138` (structure) + `CC_0139` (occupancy): 148 offices — 110 House + 38 Senate — 148 seated,
0 vacant, 144 people created, 4 reused.** Both slots reserved from the allocator before either file
was named. `politicians` 88,672 → 88,816 (**exactly +144**), `offices` 9,208 → 9,356 (+148),
`office_terms` 9,143 → 9,291 (+148), Michigan chambers 4 → 6. `offices_missing_terms` **unmoved at
423/238** — every office gets its term in the same transaction. Both migrations re-run: every
insert 0. Michigan is the program's ninth legislature.

### 🔴🔴 An absence on a chamber's own roster is not a vacancy

`house.mi.gov/AllRepresentatives` lists **109 of 110** districts. District 4 is missing, and
58 R + 51 D = 109 reads exactly like a one-seat vacancy.

**It is not.** That page is the **union of the two caucus websites** — every row links to
`gophouse.org` or `housedems.com`. **Karen Whitsett (HD-4, Detroit)** announced in March 2026 that
she was leaving the Democratic Party and would not seek re-election; she holds the seat until the
term ends **2026-12-31**. Belonging to neither caucus, she has no row to render. The
**Legislature's own** combined list carries her, and so does Open States.

▶ **Seating HD-4 as vacant would have deleted a sitting representative from every address in her
district.** Ask what a roster is ASSEMBLED FROM, not just how many rows it has. The builder now
asserts that every caucus-union gap is a seat the Legislature's list fills with a named member; a
gap **both** sources cannot fill is reported as `REAL_VACANCY_CANDIDATE`.

⚠ And her link proves status codes are not the test: `housedems.com/whitsett` **redirects to the
caucus home page and answers HTTP 200** with an `<h1>` of "Michigan House Democrats" — a dead member
link wearing a success code. ⚠ HD-101's link (`house.mi.gov/repdetail/repJosephFox`) **404s**; the
caucus page titled "Joseph Fox Posts" names him and District 101. A stale link is a fact about a link.

### 🔴 A connection failure is not an absence — an incomplete certificate chain

`legislature.mi.gov` and `house.mi.gov` serve **only their leaf certificate**. Node and curl both
fail with `UNABLE_TO_VERIFY_LEAF_SIGNATURE` while a browser succeeds, because a browser fetches the
missing intermediate from the certificate's own **AIA** extension. The builder does the same thing
honestly: it downloads the two DigiCert intermediates named in each leaf and adds them to the system
roots. **It does not disable verification.** `--tls-control` proves the fix is necessary and
sufficient and masks nothing — both hosts FAIL on default roots and succeed with the intermediates,
while `senate.michigan.gov` is fine either way.

### The four sources, and which one was wrong

| | Source | Role |
| --- | --- | --- |
| A | `legislature.mi.gov/Legislature/Legislators` | **PRIMARY** — all 148 seats in one document, and not a caucus list |
| B | `senate.michigan.gov/senators/all-senators/` | the Senate's own 38, as a JSON array in a `senatorInfo` attribute |
| C | `house.mi.gov/AllRepresentatives` | the caucus union — a detector of caucus membership, never the seat count |
| D | `data.openstates.org/people/current/mi.csv` | a detector, not an oracle |

🔴 **THE PRIMARY SOURCE WAS WRONG ABOUT A NAME AND THE DETECTOR CAUGHT IT.** Source A renders HD-7
as "Tonya Phillips"; source C says "Myers Phillips". Settled where it should be — on her own page,
whose `<h1>` reads **"State Representative Tonya Myers Phillips"**. Recorded as a `NAME_OVERRIDES`
entry naming the district, both readings and the page that decided it, and it **re-verifies its own
premise**: if source A ever stops saying "Tonya Phillips", the override fails loudly rather than
applying silently.

⚠ Open States disagrees on **17** names, all short forms (Gregory/Greg, Joseph/Joe). A detector that
fires 17 times on nicknames hides the one that matters, so the class is **split**: same surname plus
a prefix or initial short form is `OPENSTATES_NICKNAME` and does not block; a different surname or an
unrelated first name is `OPENSTATES_DISAGREES` and does.

### 🔴🔴 Four people are REUSED, and that is the guard's own "normal case"

The name sweep ran on the **guard's own key** — `lower(btrim(first_name))`, `lower(btrim(last_name))`
against **ACTIVE** rows, exactly what `essentials.politician_name_duplicate_guard` compares — and was
**controlled at 68 active `Smith` rows**, so a zero would have shown as blindness rather than read as
agreement. It returned **exactly six**, splitting four / two.

**Reused, because production already holds them as 2026 federal candidates** (a second row would
split their quotes and race edges away from the person a voter sees):

| Seat | Existing row | Verified |
| --- | --- | --- |
| HD-11 | `-261302` Donavan McKinney | won the MI-13 Democratic primary 2026-08-05, defeating Rep. Shri Thanedar |
| SD-7 | `-261103` Jeremy Moss | won the MI-11 Democratic primary 2026-08-04 |
| SD-8 | `-400123` Mallory McMorrow | holds the office literally titled "Candidate for U.S. Senate — Michigan" |
| SD-19 | `-260402` Sean McCann | term-limited in the Senate; won the MI-04 Democratic primary 2026-08-04 |

**Genuinely different people, guard lifted for that one statement:**

- **HD-68 David Martin** collides with `-2745026` "David Martin", who **sits today as a SOUTH
  CAROLINA state Representative** (SC HD-26, seated by SC-2).
- **HD-83 John Fitzgerald** collides with `-2507000008` "John Fitz**G**erald", a **BOSTON,
  MASSACHUSETTS city councillor**. ⚠ The capitalisation differs — the guard lowercases, so it sees
  what an exact match would not.

A person cannot hold two of these at once. The GA trap (a Colorado senator and a Utah treasurer) and
OH-2's Tom Young, for a third time. The other 142 rows were inserted with the guard **live**.

### 🔴🔴 The defect only the reachability gate could see

Every count was right — 148 offices, 148 terms, 148 seated — and **four districts showed nobody**.

All four reused rows were created as **candidates** and so carry `is_incumbent = false`. The reps
feed address search serves requires
`(is_active OR is_vacant) AND coalesce(is_incumbent, true) AND title NOT ILIKE 'Candidate for%'`,
so HD-11, SD-7, SD-8 and SD-19 had a correctly seated member **no resident could ever surface**.
`check:reachability` failed `REPS_FILTER_HIDDEN` 1 + 3, zero-tolerance, and named them.

▶ **REUSING A ROW MEANS INHERITING EVERY FLAG IT WAS CREATED WITH.** A candidate row is not a blank
person; it carries a claim about what that person IS, and seating them changes it.
⚠ `coalesce(is_incumbent, true)` means a NULL passes and only an explicit FALSE hides — which is why
only the reused four were affected, a difference invisible in any count of offices, terms or holders.
`CC_0139` now sets `is_incumbent = true` on those four with a guarded UPDATE, and **gate 8 asserts the
reps-feed predicate itself**: 148 of 148 pass.

### 🔴 The change-check, and two of my own detectors that failed first

All **147** member pages were read (HD-4 publishes none) and each names its own member **in its own
`<title>`/`<h1>`**. A list page is not a change-check.

Two detector failures, both caught by their own uniformity:

1. **48 "unreachable"** — an ESM module calling `require('http')`. Every one was an `http://`
   Republican member site while the Democratic sites are `https`, so the failure even looked like a
   plausible partisan pattern. ▶ **A finding that correlates with something structural about the
   SOURCE is a reason to suspect the DETECTOR.** ⚠ The first fix was also wrong, the same 48 rows
   again: an `https.Agent` handed to `http.get` is refused. **The count not moving is what said the
   second fix had not landed either.**
2. **100 of 100 pages "never name their own member"** — the test was a `RegExp` built from a template
   literal, where **`\b` is the BACKSPACE character**, not a word boundary. It searched for an
   unprintable byte. 100 of 100 is the tell. Replaced with a padded substring test, and the
   change-check now runs a **matcher control every time**, on the four surname shapes that actually
   occur here — it must be able to say yes and to say no before a single page is fetched.

⚠ A third, milder one: a proximity regex demanding the literal words "State Senator" flagged **88 of
147**, because most member sites write "Senator Albert". 88 is not uniform, so it did not look broken
— it was measuring house style. Replaced by the title/`<h1>` test, which is what the check actually
means, and which is also what caught Whitsett's redirect.

⚠ Two `departureLanguage` hits survive and are both about **other people** — a condolence for a police
officer in HD-69's embedded Facebook feed, and HD-104 quoting the governor on a department director
stepping down. The feed is now stripped before reading, and every hit carries ±110 characters of
context so a human can settle it in one look.

### ✅ Verified from outside

- 110 House / 38 Senate, **148 seated counting `och.politician_id`** (not `count(*)` — the view LEFT
  JOINs and a vacancy is a NULL holder), 0 vacant, 148 distinct districts, 148 distinct people.
- **Probe**: Detroit City Hall returns **HD-9 Joseph Tate** and **SD-1 Erika Geiss**; Jefferson
  Chalmers returns HD-9 and **SD-10 Paul Wojno**; Grand Rapids HD-84 / SD-30; Marquette HD-109 /
  SD-38. **Toledo, Ohio returns nothing.**
- **A third authority, and it is not a roster**: the State of Michigan's own GIS layers carry a
  `Legislator` attribute per district. **109/110 House and 37/38 Senate agree** with what we seated.
  Both disagreements are explained — HD-7 is the "Tonya Phillips" short form, and 🔴 **SD-35 is the
  GIS layer being STALE BY OVER A YEAR**: it still names Kristen McDonald Rivet, who **resigned
  2025-01-03** on election to Congress. **Chedrick Greene won the special election 2026-05-05**, and
  all three roster sources have him. ▶ The same layer that was the right authority for MI-1's
  GEOMETRY is a lagging authority for OCCUPANCY. Freshness is a property of a FIELD, not of a source.
- Six post-verify gates **watched failing**, each for its own reason. ⚠ The gate-3 control had to be
  rewritten: deleting a term row tripped **gate 1** first, so gate 3 was never exercised — *a control
  that aborts for the wrong reason proves nothing*. Nulling the holder leaves 148 rows standing so
  only gate 3 can catch it, which also exercises why it counts `och.politician_id`.
- Dry run of both migrations as **ONE transaction ending in ROLLBACK**, and the revert was
  **re-measured** and exact on every counter.
- `check:occupancy`, `check:migrations`, `check:reservations`, `check:child-county`,
  `check:ocd-suffixes`, `check:duplicate-people` green; `check:reachability` back to **nothing
  regressed** (4/17/7 against 4/17/7).

### Debts carried out of MI-2

- 🔴 **148 undated arrivals.** No Michigan member page publishes a service-start date. Mich. Const.
  art. IV, § 5 fixes commencement for members who arrive at a general election and says nothing about
  anyone appointed or elected mid-term — writing 2025-01-01 for all 148 would be the San José D8/D10
  error at scale. All terms are open-ended at `unknown`.
  ⚠ **SD-35 is the one seat with a documented recent arrival and it is still not datable**: Greene won
  on **2026-05-05**, but no source publishes his oath date, and the election is a **lower bound** on
  arrival, not the arrival.
- 🔴 The **Crane A1 `sldu` re-load for 2027-01-01** (MI-1), which will also re-seat the Senate.

---

## MI-3 — Detroit (APPLIED 2026-09-24)

`X0065` (7 council-district polygons), `CC_0140` structure, `CC_0141` occupancy: **18 offices, 18
seated, 0 vacant** — 1 government, 4 chambers, 17 people created, 1 reused. `politicians` 88,816 →
88,833 (**exactly +17**), `offices` +18, `terms` +18, `districts` +8. `offices_missing_terms`
**unmoved at 423/238**. All three writes re-run clean: 0 inserted, 7 boundaries already existed.

### The office inventory is the charter's own sentence

> "The elective officers of the city are the Mayor, the nine (9) members comprising the City
> Council, the City Clerk and seven (7) elected Board of Police Commissioners."

1 + 9 + 1 + 7 = **18**. The council splits 7 district + 2 at-large because the charter creates
"seven (7) non at-large districts and one (1) at-large district", electing two from the latter.

🔴🔴 **DETROIT ELECTS ITS POLICE OVERSIGHT BOARD, AND MOST CITIES DO NOT.** The Board of Police
Commissioners has **eleven** members: **7 elected by district** and 4 appointed by the Mayor. Only
the 7 elected are seated; one appointed seat is currently vacant and neither fact belongs in the
table. ⚠ The **elected** members serve **four**-year terms — the board's own page leads with a
five-year figure, which describes the **appointed** members.

🔴 **THREE OF THE SEVEN WON AS WRITE-INS.** Districts 1, 2 and 3 had **no candidate on the 2025
ballot** and were won on write-in votes (Ivey, Williams, Morris). They are elected officeholders and
are seated like the rest. Recorded because "no candidate filed" is normally the shape of a vacancy,
and here it is not.

### 🔴🔴 One geography, two elected bodies

Police-commission districts have **identical boundaries** to council districts, so each of the 7
`X0065` polygons carries **two** offices and a Detroit address correctly returns **both** a council
member and a police commissioner.

⚠ That is the Long Beach fan-out shape, and here it is **correct** — the same inversion IN-5 found
with Allen County's three commissioners. No coverage or fan-out check can separate the two cases;
only the charter can. `CC_0140` gate 9 asserts exactly 2 offices per council district, so a later
wave cannot quietly add a third.

### The vintage question, and the answer is the opposite of MI-1's

Detroit publishes **three** layers — `city_council_districts_2013`, `city_council_districts_2026`
and one titled **"Current Detroit City Council Districts"** — plus a *2026 to 2013 crosswalk*, which
is the city itself saying these are two different maps.

🟢 **THE 2026 LAYER DATES ITSELF.** Its own description: selected by City Council **8-1 on
2024-02-06** under charter Sec. 3-108, "used to determine resident districts when voting in 2025
municipal elections, and will officially take effect **January 1, 2026**". The sitting members took
office that same day.

⚠ **NOTE THIS IS THE OPPOSITE ANSWER TO MI-1's SENATE.** There the newer map was authorised for a
*future* election, so the sitting members still represented the old one. Here the new map took
effect on the day the new members did. **"Which map is newer" is never the question; "which map do
the sitting members represent" is.**

🟢 **"Current" turned out to be byte-identical to the 2026 layer** — same vertex counts, zero area
difference on all seven, measured rather than assumed — so the city serves the operative map under
two names, and the loader uses that as two-publisher agreement. ⚠ Reading "Current" as the live map
would have been right *by luck*: Horry County's `CurrentCouncilDistricts` was the superseded map
under exactly that name. The 2013 map differs from the loaded one on **all seven** districts, by
1.65%–18.18%.

⚠ **The layer says it is not the legal boundary** — "for illustrative purposes only... refer to the
geographical boundaries formally approved by the Detroit City Council on February 6, 2024". The
legal boundary is a street-by-street description, and the layer carries it per district in a
`legal_description` field; gate 3 asserts all seven are present.

### 🔴 The closure gate had to be measured, not copied

Akron's ten wards tile its place polygon at 99.971% and OH-3 gated at 99.5%. Detroit's seven cover
**97.421%** of TIGER place `2622000` — **139.22 sq mi against the place's 142.90** — because the
TIGER polygon includes the Detroit River out to the international boundary while the districts tile
the **land** (~138.75 sq mi). 3.850 sq mi uncovered, 0.165 sq mi outside the city.
**Akron's threshold would have failed on correct Detroit data.** The Great Lakes term from MI-1, for
a third time, and Fort Wayne's rule: gate the structure and set a coverage bound from a measurement.

### 🔴🔴 The X-code allocator gap, and why filling it naively is worse

OH-3 recorded that `X` boundary codes are picked by reading `max(mtfcc)` in prod — "the exact
procedure CLAUDE.md calls the bug for migration numbers" — and asked for X in the steward.

**The steward's allocator turns out to be generic: `steward slot X` works.** It returned **`X_0001`**
— and production's `X0001` already holds **207 rows**. 🔴 **AN UNSEEDED NAMESPACE IS WORSE THAN NO
ALLOCATOR, BECAUSE IT HANDS OUT NUMBERS THAT ARE ALREADY TAKEN.** The seed is the hard part:
`sync --seed` can bootstrap migrations because it reads git, and nothing reads
`geofence_boundaries.mtfcc`. `X_0001` was marked **abandoned** with that reason on the row.

MI-3 therefore used **`X0065`**, read from prod's max **in the same session as the write**, and the
loader refuses if anything already occupies it or if the max has moved past it. ▶ Seeding the X
namespace from prod remains the real fix.

### Roster and the change-check

Mayor **Mary Sheffield** (sworn 2026-01-01, Detroit's 76th mayor and first woman elected to the
office), Clerk **Janice M. Winfrey** (re-elected 2025-11-04), nine council members, seven elected
police commissioners.

⚠ **`detroitmi.gov` sits behind a Cloudflare interstitial** that answers a plain fetch with HTTP 403
"Just a moment...". The sweep ran inside a real browser session and issued its 18 requests
**same-origin**, which is what made the challenge cookie apply. All 18 pages name their own
officeholder.

⚠ **A "does the page's own `<title>`/`<h1>` name them" test reported 17 of 17 and is NOT a finding.**
Detroit titles its pages by **office** ("City Council District 2"), not by person. 17 of 17 is a
uniform answer, and here the uniform answer was the test not matching this site's convention — the
same test that correctly caught a dead member link in MI-2.

### 🔴 One person reused, and MI-2's defect fixed before the gate had to catch it

The name sweep ran on the **guard's own key** across all 18 and returned exactly one hit:
**`-261303` Mary Waters**, the sitting at-large council member, already in production as a 2024
MI-13 congressional candidate. Reused, not duplicated.

Candidate rows carry `is_incumbent = false`, and the reps feed hides those — the defect that left
four Michigan legislative seats invisible in MI-2. `CC_0141` sets the flag **in the same migration
that seats her**, and **gate 7 asserts the reps-feed predicate itself** rather than trusting the fix.

### 🔴 Only one term is dated, and the reason is not "Detroit publishes nothing"

All 18 offices were on the 2025-11-04 ballot and the winners' current **term** began 2026-01-01 —
but `office_terms` records **occupancy**, not the current term. **Seven of the nine council members
were re-elected** and have held their seats for years; James Tate since 2010. Writing 2026-01-01 for
them would assert they arrived this year.

⚠ And their own pages give the other trap: Tate's says **"since November 2009"** and **"since
2010"** — a *first* election, not an occupancy start, and the two do not even agree with each other.

So the Mayor is dated **2026-01-01 `day`** (a newly open office with a reported swearing-in) and the
other 17 are open-ended at `unknown`. Akron exactly.

### 🔴 Community Advisory Councils are excluded (ruling 2026-09-24, Cantrell)

Detroit also elects **5-member Community Advisory Councils**, on the city ballot, in the **3 of 7
districts** that created one by petition (D4, D5, D7) — 15 more elected people. They are **not** in
the charter's enumeration of "the elective officers of the city", hold no governing power, and the
set changes as districts opt in or out. Excluded as SC-4 excluded Horry's 15 watershed
commissioners. **A recorded debt, not an oversight** — the inclusion ruling does reach them, and a
later wave may take them.

### ✅ Verified from outside

- 18 offices, **18 seated counting `och.politician_id`**, 0 vacant, 4 chambers, 1 government.
- **Probe**: Detroit City Hall returns **6** answers — Mayor Sheffield, Clerk Winfrey, both at-large
  members, **Council D6 Santiago-Romero and Police Commissioner D6 Lisa Carter**; Grandmont/Rosedale
  returns D1 Tate and Commissioner D1 Ivey. **Grand Rapids returns 0 Detroit offices.**
- **Per-district control 7/7**: every council district resolves at its own interior point to exactly
  2 offices, both seated, from 2 different bodies — with a Grand Rapids positive control returning 0.
- Five loader gates and five migration gates **watched failing**.
  🔴 **THREE OF THE FIRST FIVE MIGRATION CONTROLS WERE SHADOWED BY GATE 3** ("the charter names 18
  elective officers"), which runs first and trips on any plant that adds or removes an office — so
  gates 5, 6 and 9 were never exercised and all three "passed" vacuously. ▶ **A control for a
  structural gate must hold every earlier gate's quantity constant** and break only the shape its
  target measures; each plant now moves or retitles an office instead of creating or deleting one.
  This is MI-2's gate-3 lesson for the third time in the programme.
- Dry run of both migrations as **ONE transaction ending in ROLLBACK**, revert re-measured and exact.
- `check:reachability` nothing regressed; `check:occupancy`, `check:migrations`,
  `check:reservations`, `check:child-county`, `check:duplicate-people` green.

### Debts carried out of MI-3

- 🔴 **17 undated arrivals** (the Mayor is dated). Detroit publishes no per-member service dates,
  and a blanket 2026-01-01 would be false for the seven re-elected incumbents.
- 🔴 **The 15 Community Advisory Council seats**, excluded by ruling and reversible.
- 🔴 **Seed the `X` namespace in the steward from `geofence_boundaries.mtfcc`**, or leave it out —
  `X_0001` is abandoned and the namespace must not be used until it is seeded.
- 🔴 The **Crane A1 `sldu` re-load for 2027-01-01** (MI-1), which also re-seats the Senate.

---

## ▶ Next: MI-4 — Wayne County

Stage 4. Wayne County's polygon (`26163`) is already present at 672.3911 sq mi and the county holds
**no** government row yet. Read the county charter for the elected inventory — Wayne is a **charter**
county, so an all-Michigan statutory template will not describe it (Summit County's lesson at OH-4).
The 15-member County Commission is elected by district, so that layer and its vintage come first.

Carried debts:
- 🔴 **`sldu` must be re-loaded to Crane A1 after the 2026 election** (members seated 2027-01-01).
  The loader's Senate anchors will abort a re-run until they are updated, which is deliberate:
  changing them is the moment someone decides the Senate has turned over.
- ⚠ **Detroit's banner collides with `states/MI.jpg`**, which *is* Detroit's skyline. The Miami
  move — version the state banner, never overwrite — is available. Stage 5.
- Stage 4 is **Wayne County**.
