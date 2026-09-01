# Milledgeville + Baldwin County — verified roster (GA-3)

**Program tracker:** [`.planning/knight-foundation/PROGRAM.md`](../../../.planning/knight-foundation/PROGRAM.md) ·
**State notes:** [`.planning/knight-foundation/ga.md`](../../../.planning/knight-foundation/ga.md)

Measured 2026-09-01. **18 offices, 18 people, 0 vacancies** — 7 city, 11 county.

---

## Sources

| # | Body | Source | Endpoint | What it is |
| --- | --- | --- | --- | --- |
| A | city | City of Milledgeville | `milledgevillega.us/index.php/city-council/`, `/mayor/` | the city's own roster, 6 members with districts |
| B | city | Georgia Municipal Association | `gacities.com/Directories/Cities/MILLEDGEVILLE/51492` | self-updated member directory, **9 names, no districts** |
| C | city + county | Baldwin County ArcGIS `ElectionGeography` | `services7.arcgis.com/Da8HZMsU25Hzzob3/.../FeatureServer/2` | one row per district carrying `repname1` and a per-row `EditDate` |
| D | city + county | **Georgia Secretary of State, certified results** | `results.sos.ga.gov/results/public/api/elections/baldwin-county-ga/{id}/data` | **the arbiter.** Nov 2025 municipal general and Nov 2024 general, both certified |
| E | county | Baldwin County staff directory | `baldwincountyga.com/Directory.aspx` | names the Clerk, Probate Judge, Sheriff and Tax Commissioner |
| F | county | Baldwin County Board of Commissioners | `baldwincountyga.com/1194/Board-of-Commissioners` | the county's own roster, 5 districts |
| G | county | Baldwin County Sheriff's Office | `baldwinsheriff.com` | the Sheriff's own office |
| H | both | Ballotpedia 2024 candidate list | `ballotpedia.org/Baldwin_County,_Georgia,_elections,_2024` | who was on the ballot; **not** a results source, and says so |
| I | city | The Union-Recorder, 2025-11-04 | `unionrecorder.com/2025/11/04/mary-parham-copelan-wins-3rd-term/` | contemporaneous press on election night |

Payloads are on disk in this directory, untracked.

🔴 **Source D is the only certified source, and it is the only one that settled every seat.**
The SOS results portal carries the **November 4, 2025 Municipal General** as well as the November 2024
general, so even a small city's council is resolvable from the state's own certified record. Nothing
in Florida used this route. **Look for it first in Columbus and Macon.**

---

## 🔴 Source defects found

### 1. The county's ArcGIS layer is stale on half the city council, and its own `EditDate` is the tell

Source C carries one row per elected office with the sitting officer's name. Its **`EditDate` is
per row**, and it splits cleanly:

| Rows | Last edited | Accurate? |
| --- | --- | --- |
| County Commissioner x 5 | **2026-04-21** | ✅ all five correct |
| City District 1, 3, 5 | 2021–2023 | ✅ correct by luck — those three members did not change |
| City District 2, 4, 6 | 2021–2022 | ❌ **all three name the predecessor** |
| President of the United States | 2021-02-04 | ❌ "Joe Biden" |
| Governor | 2023-01-17 | ❌ "Brain Kemp" — misspelt |
| Lt. Governor, Commissioner of Labor, Commissioner of Agriculture | 2021–2023 | ❌ all three left office in January 2023 |
| US House District 8 | — | ❌ **two contradictory rows**, Austin Scott and Jody Hice |

A row's freshness in this layer is **not** a property of the layer. Read `EditDate` per row, or do
not read the layer at all.

### 2. The GMA directory ACCUMULATES — nine members for a six-seat council

Source B lists Chambers, Lee, Mapp, Pendergast, Reynolds, Shinholster, Simmons, Walden and Wells.
Six sit; three left. It carries **no district and no `dateVacated`**, so unlike GA-2's member LIST
there is no field that separates them. Its only safe use is as a **superset check**: every sitting
member appears in it, and its three extras are exactly the three predecessors.

### 3. 🔴🔴 A layer titled "(2025)" can still carry a roster from before the 2025 election

The city's own `City Council Districts (2025)` layer has a `CouncilMem` attribute. It reads:

```
D1 Lee   D2 Walden   D3 Shinholster   D4 Reynolds   D5 Mapp   D6 Chambers
```

The **geometry** is the current plan. The **attribute** predates the November 2025 election.
Geometry vintage and attribute vintage are different questions about the same row — and the layer's
own title answers only the first. This field is not a fourth roster; it is a fourth confirmation of
who the three predecessors were.

### 4. Milledgeville's published charter is codified through **January 2014** and describes a body that no longer exists

`library.municode.com/ga/milledgeville` is "Codified through Ordinance No. O-1311-013, enacted
January 14, 2014 (Supp. No. 1)". Its Part I Charter is titled **"ARTICLE II. — MAYOR AND ALDERMEN"**
and holds no section describing six single-member districts. It cannot settle the mayor's voting
powers, the council's composition, or the majority rule.
⚠ Municode's own API returns **HTTP 401 to curl AND to an in-page `fetch()`**. The way through is to
let the SPA render and read the DOM — the legis.ga.gov pattern by a different mechanism.

### 5. The D2 arithmetic does not close, and the published charter cannot explain it

Certified D2: Simmons **108**, Snider 56, Solomon 52, total **216** — exactly **50.0%**, not a
majority. The Union-Recorder reported five write-ins pending a panel review on November 5. The
certified sheet published 2025-11-21 carries **no write-in ballot option** and sums to 216.
**Baldwin held no runoff** — it is absent from the December 2, 2025 runoff results, which return
HTTP 204 for this county.

The likeliest explanation is that Milledgeville elects by **plurality**, not majority, which would
make 50.0% a win and no runoff correct. **That is not confirmed**, because the only published charter
is the 2014 one (defect 4). Recorded as an open question. It does not affect the seating: Simmons
holds D2 by the certified count, by the city's own roster, and by the absence of any successor contest.

---

## Charter rulings

**R1 — The Mayor is `voting_powers 'full'` in an `Office of the Mayor` chamber of one.**
Follows **Bradenton's ruling R2** (`CC_0008`): `voting_powers` describes the powers of the OFFICE, not
a council procedure. Milledgeville's Mayor is elected citywide on a separate certified ballot line
("Mayor - Milledgeville", source D) for a four-year term, and is not a seat that exists only to
preside — which is what made Nashville's Vice Mayor `non_voting`.
⚠ **The mayor's vote on the council is NOT established**, because the only published charter is the
2014 one (defect 4). Milledgeville is council-**manager**, so unlike Bradenton the Mayor is not the
chief executive. Re-check when a current charter is obtainable. `'full'` requires no
`representation_note`, so this ruling writes no unsourced prose into a voter-facing field.

**R2 — The county Chair and Vice Chair are parentheticals, not offices.**
Source F: "one commissioner for each of the County's five districts **with the Chair elected by the
Board**". Kendrick B. Butts chairs from District 2; Scott Little vice-chairs from District 5. Follows
the Lawrence County ruling: a rotating role is a parenthetical on the seat title, never its own office.
The same applies to Denese Shinholster as **Mayor Pro-Tem** (source B).

**R3 — Eleven county offices, per the ruling of 2026-09-01 (Cantrell).**
Baldwin elects thirteen countywide offices besides the commission. Seated: Sheriff, Clerk of Superior
Court, Probate Judge, Tax Commissioner, Coroner, Surveyor. **Excluded**: Solicitor General (a
prosecutor — the FL-5 rule against Palm Beach's State Attorney); Chief Magistrate (judicial branch,
Ga. Const. Art. VI, as Florida excluded its county judges); the Ocmulgee Judicial Circuit District
Attorney and five Superior Court judges (**multi-county circuit** — FL-5); the school board and the
Piedmont Soil and Water District supervisor (spec §11). The four seated non-commission officers named
in Ga. Const. Art. IX, Sec. I, Par. III are the constitutional set; Coroner and Surveyor are statutory
county officers, and Baldwin genuinely elected both countywide in 2024.

**R4 — All 18 terms are open-ended at `start_precision 'unknown'`.**
As GA-2. The certified election dates are known and go in the migration headers, but `term_start` is
the start of **continuous occupancy**, which re-election does not end, and neither the city nor the
county publishes a service-start or a swearing-in date. Four of the seven city members are incumbents
whose occupancy predates 2025. **No date is invented.**

---

## Roster — city (7 offices, 7 people)

Certified November 4, 2025 municipal general, `asOf 2025-11-21`, 6 of 6 units reporting.
🔴 **All six districts and the mayoralty were on the same ballot — the council is NOT staggered.**

| Office | Person | Certified | Sources |
| --- | --- | --- | --- |
| Mayor | **Mary Parham-Copelan** | 1,235 / 2,330 (53.0%) def. Walter Reynolds 1,095 | A B C D I |
| Council Member, District 1 | **Collinda J. Lee** | 377, unopposed | A B C D |
| Council Member, District 2 | **Arlene Simmons** | 108 / 216 (50.0%) — see defect 5 | A B D I |
| Council Member, District 3 | **Denese Ray Shinholster** | 248, unopposed | A B C D |
| Council Member, District 4 | **Morgan Pendergast** | 79, unopposed | A B D |
| Council Member, District 5 | **Shonya A. Mapp** | 498, unopposed | A B C D |
| Council Member, District 6 | **Jeffery C. Wells** | 456 / 730 (62.5%) def. Kayla Brownlow 274 | A B D |

🔴 **Walter Reynolds vacated District 4 to run for Mayor, and lost** — one person's move explains the
D4 change, exactly as Higgins' move explained Miami's HD-113 vacancy. Walden (D2) and Chambers (D6)
do not appear on the 2025 ballot at all.

**Name forms settled by source D:** `Jeffery` C. Wells, not GMA's "Jeffrey". `Denese Ray Shinholster`
— source A gives the middle initial only. Sources A and C prefix "Dr." to Collinda Lee and Jeffery
Wells; a courtesy title is not part of the name.

## Roster — county (11 offices, 11 people)

Certified November 5, 2024 general, `asOf 2025-01-02`. **All ten on the ballot ran unopposed at 100%.**
The Probate Judge appears on no 2024 ballot returned by source D — Georgia omits unopposed nonpartisan
candidates — and rests on sources E, C and H, which agree on the person.

| Office | Person | Votes (2024) | Sources |
| --- | --- | --- | --- |
| Commissioner, District 1 | **Emily C. Davis** | 2,650 unopposed | C D F H |
| Commissioner, District 2 *(Chairman)* | **Kendrick B. Butts** | 2,128 unopposed | C D F H |
| Commissioner, District 3 | **Sammy Hall** | 2,239 unopposed | C D F H |
| Commissioner, District 4 | **Andrew Strickland** | 4,084 unopposed | C D F H |
| Commissioner, District 5 *(Vice Chairman)* | **Scott Little** | 4,312 unopposed | C D F H |
| Sheriff | **W.C. "Bill" Massee, Jr.** | 16,400 unopposed | C D E G H |
| Clerk of Superior Court | **Wanda T. Paul** | 14,815 unopposed | C D E H |
| Probate Judge | **Todd A. Blackwell** | not on ballot — unopposed | C E H |
| Tax Commissioner | **Cathy Freeman Settle** | 16,026 unopposed | C D E H |
| Coroner | **John Gonzalez** | 15,444 unopposed | D H |
| Surveyor | **James E. Smith, Jr.** | 14,121 unopposed | D H |

**Name forms settled by source D:** `W.C. "Bill" Massee, Jr.` — source C misspells it "Bill Masse"
with one `e`; his own office (G) and the county directory (E) both give **Massee**. `Cathy Freeman
Settle` — the county directory (E) shortens it to "Cathy Settle". `James E. Smith, Jr.` — Ballotpedia
gives "James Smith Jr.".
⚠ **Two suffixed names and one embedded nickname**, so `splitName()` is not used: first and last are
taken from the source, as GA-2 did.

## Change-check

Sources were last edited between 2021 and 2026-04-21; the certified results are from 2025-11-21 and
2025-01-02. Checked for a change after those dates:

- **No Baldwin county office is on a 2026 ballot.** The commissioners' term "expires December 31,
  2028" (source F) and the constitutional officers were elected in 2024 to four-year terms. Confirmed
  against source D's May 19, 2026 general primary, which carries no Baldwin county office.
- **No Milledgeville city office is on a 2026 ballot.** Milledgeville elects in odd years; the next
  municipal general is November 2027.
- The county's own commissioner rows were edited **2026-04-21**, after certification, and agree 5 of 5.
- No resignation, death or appointment was found for any of the 18, in press or in source E.

⚠ This is the SD-12 discipline from GA-2: a roster that reports no change is exactly what a stale
roster also looks like. Here the change-check carries a **positive control** — the same method found
three real city changes — so it is not returning a uniform answer.

## Collision check against production

All 18 tested on `normalize(lower(first_name), NFD)` + `normalize(lower(last_name), NFD)`.
**Zero matches. All 18 are new politician rows; there is no reuse in this wave.**

⚠ The first run returned zero for all 18, which is the shape of a broken detector. A **positive
control** was added — `Floyd Griffin`, seated by GA-2 — and it returns exactly 1, so the zero is real.
A surname sweep found `Smith` 57 times in production and 4 times in Georgia, `Davis` 49/1 and
`Strickland` 7/1; all six Georgia rows are GA-2 legislators, and none is one of ours.
