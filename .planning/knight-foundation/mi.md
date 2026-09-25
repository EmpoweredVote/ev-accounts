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

## ▶ Next: MI-2 — seat the Michigan Legislature, 148 offices

Michigan currently holds **zero** state legislative offices. Expect the MN-2 / OH-2 shape:
reconcile from both chambers' member lists plus Open States, then **change-check all 148 member
pages individually** — a roster index is not a change-check, and neither chamber is reliably
fresher than the aggregator.

Carried debts:
- 🔴 **`sldu` must be re-loaded to Crane A1 after the 2026 election** (members seated 2027-01-01).
  The loader's Senate anchors will abort a re-run until they are updated, which is deliberate:
  changing them is the moment someone decides the Senate has turned over.
- ⚠ **Detroit's banner collides with `states/MI.jpg`**, which *is* Detroit's skyline. The Miami
  move — version the state banner, never overwrite — is available. Stage 5.
- Stage 4 is **Wayne County**.
