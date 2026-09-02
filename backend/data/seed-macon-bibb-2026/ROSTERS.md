# Macon-Bibb County — verified roster (GA-5)

Wave GA-5 of the Knight Foundation cities program.
Spec: [`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md) ·
Slice: [`.planning/knight-foundation/ga.md`](../../../.planning/knight-foundation/ga.md)

**15 offices, 15 people, 0 vacancies** — 10 city, 5 county. One government, three chambers.
The program's **second consolidated city-county**, after Columbus/Muscogee (GA-4).

Measured 2026-09-01. Every source in the table below is on disk in this directory, untracked.

- TIGER place `1349008` "Macon-Bibb County" = **254.906 sq mi = Bibb County `13021` exactly**,
  `FUNCSTAT 'A'` (not a balance record). Consolidation is complete; no satellite municipality.
- `essentials.districts` holds Bibb County `13021`/`G4020` and it carries **zero offices**.
  There is **no district row for the place** — GA-1 loaded the place BOUNDARY only, as at Columbus.
- Sub-range **`-1331036 .. -1331050`** (Columbus claimed through `-1331035`). Verified free.
- Private MTFCC **`X0045`** for the nine commission districts. Verified free.

---

## Sources

| # | Body | Source | Endpoint | What it is |
| --- | --- | --- | --- | --- |
| A | city | **Charter of Macon-Bibb County** | Ga. L. 2012, p. 5595/HB 1171, as amended by 2013 SB 25, 2013 HB 514, HB 610 (2021-05-03) | **the structural authority.** Sec. 5, 7, 8, 9, 10, 15 |
| B | city | Macon-Bibb County Commission roster | `maconbibb.us/commissioners/` | the government's own roster, Mayor + 9 commissioners |
| C | city | **County GIS, voter-facing** `CountyCommissioners2024` | `maconbibb.spatialitics.net/server/rest/services/Hosted/CountyCommissioners2024/FeatureServer/0` | **the layer the county's own "Find Your Commissioner" widget queries.** Fresh roster AND correct geometry — see defect 2 |
| D | city | AGOL `2022_Bibb_County_Commission_Redistricted` | `services2.arcgis.com/zPFLSOZ5HzUzzTQb/.../FeatureServer/0` | **the adopted 2022 redistricting plan as drawn**, with per-district deviations |
| E | city | AGOL `County_Commissioners_2020` (layer *named* "County Commissioners 2024") | `.../County_Commissioners_2020/FeatureServer/0` | same geometry as C and D; roster stale in D5 only |
| F | city | AGOL `ElectoralDistricts` layer 3 | `.../ElectoralDistricts/FeatureServer/3` | the **Board of Elections'** copy. No roster at all |
| G | city | AGOL `CountyDistrict` | `.../CountyDistrict/FeatureServer/0` | 🔴 **SUPERSEDED GEOMETRY** — see defect 2 |
| H | city + county | Georgia Secretary of State, certified results | `results.sos.ga.gov/results/public/api/elections/bibb-county-ga/{id}/data` | 36 elections enumerated, 2012→2026. 🔴 **Carries no Macon-Bibb Mayor or Commission contest in any year** — see defect 1 |
| I | city | Macon-Bibb County, "Mayor, Commissioners get sworn in" | `maconbibb.us/mayor-commissioners-get-sworn-in/` | states the 2025 term **"begins at 12:00 a.m. on January 1, 2025"** and lists all ten |
| J | city | Macon-Bibb County, "Thank you, Commissioners!" (2024-12-06) | `maconbibb.us/thank-you-commissioners/` | the four departing members. 🔴 Carries a district error — see defect 3 |
| K | city | Macon-Bibb County, "Stanley Stewart sworn in as District 3 Commissioner" (2024-10-25) | `maconbibb.us/stanley-stewart-sworn-in-as-district-3-commissioner/` | Stewart's oath, **Tuesday 2024-10-15** |
| L | city | Macon-Bibb County, "Brendalyn Bailey to serve as District 9 Commissioner" (2024-01-19) | `maconbibb.us/brendalyn-bailey-to-serve-as-district-9-commissioner/` | the appointment, and the charter's 20-day rule |
| M | city | 41NBC/WMGT, 2024-01-09 | `41nbc.com/macon-bibb-commissioner-al-tillman-announces-resignation/` | Tillman resigns D9 **effective immediately**, 2024-01-09 |
| N | city | 41NBC/WMGT, "List of qualifying candidates for Macon-Bibb 2020 election" | `41nbc.com/macon-bibb-election/` | **the incumbency source.** Marks which 2020 candidates were sitting commissioners, and lists every county officer on that ballot |
| O | city | WGXA, 2024-12-17 | `wgxa.tv/news/local/macon-bibb-county-inauguration-welcomes-new-and-returning-leaders` | the inauguration; names Hulett and Bryant as the only new members. 🔴 Miscounts Stewart — see defect 3 |
| P | city | WGXA, 2026-01-06 | `wgxa.tv/.../macon-bibb-commission-elects-district-1-commissioner-valerie-wynn-as-mayor-pro-tem...` | Clark's resignation (2026-01-05) and Wynn elected mayor pro tem **5–3** |
| Q | city | WPGA / Atlanta News First, 2026-04-20 | `wpganews.com/2026/04/21/andrea-cooke-sworn-macon-bibb-county-district-5-commissioner/` | Cooke sworn in **Monday 2026-04-20**; runoff 746–313 |
| R | city | The Macon Newsroom, Jan 2025 | `macon-newsroom.com/23839/news/macon-bibb-commission-elects-mayor-pro-tem-sets-committee-structure/` | the organisational meeting. **Roll call of nine commissioners, 5–4, mayor not voting** |
| S | county | Bibb County Sheriff's Office | `bibbsheriff.us/` | Sheriff David Davis; first elected November 2012 |
| T | county | Probate Court of Bibb County | `maconbibb.us/probate-court/` | Judge **Sarah S. Harris**; carries the "Bibb County Constitutional Officers" legal-organ notice |
| U | county | Clerk of Superior Court | `maconbibb.us/superior-court/clerk-of-superior-court/` | Clerk **Erica Woodford** — with the accent-free spelling her own office uses |
| V | county | Macon-Bibb County Coroner's Office | `maconbibb.us/coroners-office/` | Coroner **Leon Jones** |
| W | county | Macon Community Reporter, Dec 2025 | `mymcr.net/free/reporter-named-bibb-county-legal-organ/...` | **names four officers as "constitutional officers" acting jointly**: Davis, Harris, Woodford, McCord |
| X | county | Macon Community Reporter, Aug 2024 | `mymcr.net/news/meet-the-nice-judge-sarah-harris/...` | Harris re-elected to her **fourth** term; succeeded Judge William J. Self |
| Y | county | Macon Community Reporter, Mar 2026 | `mymcr.net/news/leon-jones-georgia-s-most-popular-coroner/...` | Jones **elected six times**, current term ends 2028, **working in March 2026** |
| Z | county | WGXA, Jul 2026 | `wgxa.tv/news/local/coroner-confirms-three-dead-bodies-found-in-apartment-...` | Coroner Jones **on the job 2026-07** — the freshest occupancy evidence in the wave |

---

## 🔴 Source defects found

### 1. 🔴🔴 The certified-results route is DEAD for the city half — worse than Columbus, and silent

GA-4 found that the Georgia SOS portal carries Columbus municipal contests **only from 2026**. Bibb is
worse: **it carries no Macon-Bibb Mayor or Commission contest in any year at all.**

All 36 elections were enumerated from `/api/jurisdictions/bibb-county-ga` (not guessed — a guessed slug
returns HTTP 204, which is indistinguishable from "no such contest"). Every ballot item in the four
plausible payloads was then listed **by hand**:

| Election | Local contests present |
| --- | --- |
| `2020AugPPP` (2020-06-09, the postponed nonpartisan general) | 42 items: federal, legislative, judicial, party questions. **No mayor, no commission, no county officer.** |
| `2020NovGen` | 19 items. **No county officer at all** — although Sheriff Davis was elected that November |
| `2024MayGenPri` | 46 items. **No mayor, no commission** |
| `2024NovGen` | 20 items. Clerk of Superior Court, Solicitor of State Court, Sheriff, Tax Commissioner — **and no Probate Judge, no Coroner** |

Source N shows what the 2020 ballot actually held: Mayor, all nine commission districts, Sheriff, Clerk
of Superior Court, Tax Commissioner, Solicitor of State Court, Judge of Probate Court, Coroner, Water
Authority and Board of Education. **The state portal carries none of it.**

⚠ So Bibb's coverage is not merely late, it is **patchy per election**: four county officers appear in
2024 and zero appear in 2020. A wave that treated the portal as authoritative would have called the
entire Macon-Bibb Commission vacant. **Every term_start below comes from the county or the press.**

### 2. 🔴🔴 FIVE layers publish Macon-Bibb commission districts. Four agree exactly; the superseded one is listed FIRST in the county's own web map.

GA-4's Columbus finding was that two layers **invert** — the one with the fresh roster had the wrong
geometry. **Macon-Bibb does not invert, and that had to be measured rather than assumed.**

Per-district symmetric difference against source C, in sq mi, computed in PostGIS after `ST_MakeValid`:

| Source | D1 | D2 | D3 | D4 | D5 | D6 | D7 | D8 | D9 | total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| D `2022_..._Redistricted` | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | **0.0000** |
| E `County_Commissioners_2020` | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | **0.0000** |
| `County_Commission` | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | **0.0000** |
| F `ElectoralDistricts/3` | 0.0069 | 0.0093 | 0.0117 | 0.0130 | 0.0044 | 0.0137 | 0.0172 | 0.0092 | 0.0058 | **0.0914** |
| **G `CountyDistrict`** | 3.8823 | 6.5437 | **31.9034** | 22.8847 | 2.8304 | 26.3060 | **33.6839** | 12.5497 | 5.1373 | **145.7215** |

- The **adopted plan** (D), the **county's voter-facing service** (C), the AGOL copy (E) and
  `County_Commission` are **the same map to 0.0000 sq mi on all nine districts**. F, the Board of
  Elections' copy, differs by 0.0914 sq mi in total — about 0.01 per district, sliver noise from a
  different digitisation, not a different map.
- 🔴 **G is a different map by 145.72 sq mi**, its union is 255.3656 (0.46 too large) and it misses the
  county outline by 1.1846 sq mi. **It is the FIRST of the two layers in the county's own
  `Macon-Bibb County Board of Commissioners` web map, which was modified 2026-02-19.** A live 2026 web
  map still ships the superseded layer alongside the current one.
- ⚠ **Do not pick by service name.** `County_Commissioners_2020` sounds superseded and is current — its
  *layer* is named "County Commissioners 2024" and its description says "based off the 2020 census",
  i.e. the post-2022 plan. `CountyDistrict` sounds generic and current, and is the old map.

**The roster fields diverge much further than the geometry**, and only one source is right:

| Source | D3 | D5 | D8 | D9 | verdict |
| --- | --- | --- | --- | --- | --- |
| **C** (voter-facing) | Stewart | **Cooke** | Bryant | Bailey | ✅ all nine match B exactly |
| E | stewart | *(null)* | bryant | Bailey | one seat blank |
| G | lucas | clark | bryant | tillman | three seats stale |
| `County_Commission` | Elaine Lucas | Seth Clark | Virgil Watkins, Jr. | Al Tillman | the 2021–2024 board |
| F | — | — | — | — | no roster at all |

**Source C is the only layer in Bibb that knows Andrea Cooke exists.** Geometry and roster point the
same way here — but they were established by two independent tests, because GA-4 proved they need not.

⚠ **The loader must still request geometry and district number only.** The roster comes from B, C and
the press, never from a boundary layer's attribute table.

### 3. 🔴 The county's own farewell post puts a sitting commissioner in the WRONG DISTRICT

Source J (2024-12-06) says the Commission "will welcome Joey Hulett as District 4 Commissioner and
**Donice Bryant as District 5 Commissioner**."

**Bryant is District 8.** Sources B, C, E, G, O and the departure of Virgil Watkins from D8 all agree.
D5 was Seth Clark's, and D5 is precisely the seat that fell vacant in January 2026 and went to Andrea
Cooke — so a wave that took the district from the county's own post would have seated Bryant in a seat
someone else holds, in the one district where a collision was live.

⚠ Source O (WGXA) carries a different error in the same event: it lists **Stanley Stewart** among
"re-elected officials … will continue their work". Stewart was not re-elected — he won Elaine Lucas'
open seat and was **appointed** to its remainder two months earlier (source K). The two errors point in
opposite directions and neither is detectable from the other source.

### 4. 🔴 Two press dates for the same oath are both wrong by construction

- **Stewart.** WGXA headlines "Stanley Stewart sworn in early as District 3 Commissioner", published
  **2024-10-01**, and its body says only that the commission *voted to appoint* him that day. The
  county's own post (K) reports the oath on **Tuesday, October 15**, with his first commission meeting
  that evening. Taking the headline's date is 14 days early. **The oath is the occupancy, not the vote.**
- **Cooke.** One outlet dates her swearing-in to **April 21, 2026**; source Q, published 2026-04-20
  23:21 EDT, says "sworn in **Monday**" and "Cooke's first commission meeting is **Tuesday**".
  April 21 2026 is a Tuesday. **The weekday arbitrates: 2026-04-20.**

### 5. 🔴 Name spellings, resolved against each officer's own office

| Wave name | Also seen as | Resolved by |
| --- | --- | --- |
| **Erica Woodford** | "Eric Woodford" (source N) | U — her own office. The 41NBC form is a typo, kept as an alias |
| **S. Wade McCord** | "Wade McCord", "Samuel Wade McCord" | the county writes "Tax Commissioner, S. Wade McCord" |
| **Sarah S. Harris** | "Sarah Stevenson Harris" (source N) | T — her own court |
| **Stanley B. Stewart** | "Stanley Stewart" | K uses both; the middle initial appears on the appointment |

### 6. 🟢 Zero name collisions among all fifteen

Exact-name match against `essentials.politicians` returns **0 rows** for all fifteen. Surname near
misses are FEC committee ALLCAPS junk plus two genuinely different people — **Christina Wynn**
(California assessor) and **Alexander Cooke**. Nothing to disambiguate.

---

## Charter rulings

### M1 — Nine single-member districts. No at-large seats.

Sec. 9(a): "The territory of the restructured government shall consist of **nine election districts**
to be designated as Commission Districts 1 through 9." Sec. 9(c): "The members shall be elected from
the nine districts specified in subsection (a) … by a majority of electors voting in such election
**from such district**."

All five GIS layers return exactly nine polygons, which is the independent confirmation. **Unlike
Columbus, there is no at-large pair**, so the citywide district carries `num_officials = 1` — the Mayor
alone — not 3.

⚠ **Sec. 5 and Sec. 9(c) contradict each other and Sec. 9(c) governs.** Sec. 5 says the commission is
"composed of a mayor and nine commissioners" and then defines *all* members as "commissioners";
Sec. 9(c) says "The commission shall consist of nine members." Sec. 9(c) is the provision that sets
membership and voting, and it is the one the body actually operates under (see M2).

### M2 — The Mayor is `voting_powers = 'non_voting'` with a REQUIRED `representation_note`

Sec. 9(c), read in the section itself and not carried from a summary:

> "All members of the commission shall be full voting members of the commission. **The mayor shall be
> the presiding officer of the commission but shall not be a voting member of the commission;
> provided, however, that the mayor may cast a vote on any matter before the commission to break a
> tie.** The mayor may propose ordinances in the same manner as a commissioner."

This is the Columbus Sec. 4-201 ruling and the Nashville Vice Mayor ruling in a third dress.

🟢 **PROVED BY TWO ROLL CALLS, not asserted.** Mayor pro tem elections are the cleanest test because
every member votes:

| Meeting | Vote | Voters | Consistent with |
| --- | --- | --- | --- |
| January 2025 (source R) | Clark elected **5–4** | **9** — Howell, Clark, Wilder, Bailey, Hulett for; Stewart, Bronson, Bryant, Wynn against | nine voting commissioners, mayor absent from the tally |
| 2026-01-06 (source P) | Wynn elected **5–3** | **8** — D5 vacant | same, one seat short |

Both totals are the commissioner count, never the commissioner count plus one. Source R also records
the government as built on the "**strong mayor**" concept — the Mayor is the chief executive who
presides, which is why he has a voice and no vote.

`representation_note` must cite **Sec. 9(c)** and must be rendered by the read path.

### M3 — Mayor Pro Tem is a parenthetical, not an office

Sec. 9(f): "The commission shall elect **from among its members in January of each year** a member to
serve as mayor pro tempore, who shall preside over meetings of the commission in the mayor's absence."

Elected annually from sitting members, and it moved from Clark to **Valerie Wynn (D1)** on 2026-01-06.
The Lawrence County / Baldwin R2 / Columbus R3 rule: a rotating role is a parenthetical on the seat
title, never its own office. **Post-verify must refuse any office titled "Mayor Pro Tem".**

### M4 — FIVE county officers, and the route in is different from Muscogee's

Charter Sec. 8 preserves **four** as county officers: "the duties of the **sheriff**, the **tax
commissioner**, the **coroner**, and the **clerk of the superior court** shall remain as such duties
are presently imposed by law for such respective officers **as county officers**."

The **Judge of the Probate Court** is not in Sec. 8 and comes in the way Muscogee's Clerk of Superior
Court did — **Ga. Const. Art. IX, Sec. I, Par. III** names it a county officer. Bibb elects it
countywide (source N, 2020 ballot; source X, fourth term 2024).

🟢 **The county's own officers confirm the set.** Source W (Dec 2025) reports "Bibb County sheriff
David Davis, probate judge Sarah Harris and clerk of court Erica Woodford, along with tax commissioner
Wade McCord, **another constitutional officer**" acting jointly to change the county's legal organ,
effective 2026-01-01 — an act only constitutional officers perform. The probate judge is inside that
group; the Solicitor of State Court is not.

| Excluded | Why |
| --- | --- |
| Solicitor of State Court (Rebecca Grist) | a prosecutor — the FL-5 rule, and Baldwin's Solicitor General |
| Judge, Civil & Magistrate Court | judicial branch, **Ga. Const. Art. VI** — Baldwin's Chief Magistrate line |
| District Attorney, **Macon Judicial Circuit** | **MULTI-COUNTY** circuit — the FL-5 ruling exactly |
| Judges, Superior Court, Macon Judicial Circuit | multi-county **and** Art. VI |
| Macon Water Authority (districts 1–3) | a separate authority, spec §11 |
| Bibb County Board of Education | spec §11 |
| Clerk of Commission | **appointed** by the commission, not elected |

⚠ **Baldwin's six-officer template does not transfer, and neither does Muscogee's five.** The *count*
matches Muscogee at five, but Bibb elects **no Marshal and no Surveyor**, and its five arrive by a
different legal route. Confirmed from the charter, inherited from nothing.

### M5 — 🟢 GA-4's municipal-court question DOES NOT ARISE in Bibb

GA-4 recorded a counter-argument to ruling R4 and predicted "**the next consolidated city-county will
raise it again**: Macon-Bibb at GA-5." **It does not.** Charter Sec. 7:

> "The court shall be known as the Municipal Court of Macon-Bibb County. … **Vacancies in the office of
> judge of the Municipal Court of Macon-Bibb County shall be filled by appointment of the mayor.**"

Bibb's municipal court judge is **appointed, not elected**, so there is no elected municipal-court
office to include or exclude. Confirmed independently by the ballot enumeration: no municipal-court
contest appears in any Bibb payload in source H. The prediction was correct to make and the answer is
that the question is moot here — it stays live for **Philadelphia and Lexington**.

### M6 — Vacancies: special election, unless within 12 months of expiry

Sec. 15(a) — any vacancy → "the commission or those remaining **shall, by resolution, order a special
election** to fill the balance of the unexpired term."
Sec. 15(b) — "**If, however, the vacancy … occurs within 12 months of the expiration of the term** …
the commission or those remaining may, **within 20 days**, appoint a successor for the remainder."
Sec. 15(c) — a mayoral vacancy makes the mayor pro tem acting mayor.

This is what makes `how_started` differ across the board, and it is load-bearing:

- **Tillman resigned 2024-01-09**, term expiring 2024-12-31 → inside 12 months → **appointment**.
  Bailey was appointed on a **5–3 commission vote** and sworn in **2024-01-17** (sources L, M).
  🔴 Two press accounts say "**Mayor** Lester Miller appointed" her. **The charter gives the power to
  the commission, and the 5–3 tally is a commission vote.** `how_started = 'appointed'` either way, but
  the prose must not repeat the error.
- **Lucas stepped down** in autumn 2024 to run for the Macon Water Authority → inside 12 months →
  **appointment**. Stewart, who had already won the seat for the next term, was appointed 2024-10-01
  and sworn in **2024-10-15**.
- **Clark resigned 2026-01-05** with the term running to 2028 → outside 12 months → **special
  election**, held 2026-03-17, runoff won by Cooke 746–313, sworn in **2026-04-20**.

⚠ `how_started = 'special election'` **is not a legal value.** `essentials.office_terms` allows only
`elected | appointed | succeeded | redistricted | unknown`. Cooke and Wynn are `'elected'`, with the
*special* fact in the `source` string — the GA-4 Task 3 correction, restated so it cannot be lost.

### M7 — 🟢 Payne City is gone, and the geometry proves it rather than assuming it

Sec. 9(a) ends: "provided, however, that such described districts **shall not include the city limits
of the City of Payne City**." Payne City was a municipality inside Bibb, excluded from the original
districting plan — so if it still existed, the nine districts would **not** tile the county.

They do. Measured union of the nine districts = **254.9060 sq mi**; Bibb County TIGER `13021` =
**254.906**; symmetric difference **0.0280 sq mi**, far below Payne City's footprint. Payne City
appears nowhere in the TIGER 2024 place file. **The charter's carve-out is spent.**

🔴 **This inverts the Columbus gate.** At GA-4 the eight districts left 74.79 sq mi (Fort Benning) in no
district and the instruction was "gate the structure, not full coverage". **In Bibb, full coverage is
correct and must be gated** — a structure-only gate would pass on a map that had lost a district.

---

## The roster

`how_started` values are the CHECK-legal ones. `precision` is `start_precision`.

### City — Macon-Bibb County (10)

| Seat | Holder | how_started | term_start | precision | Source |
| --- | --- | --- | --- | --- | --- |
| Mayor | Lester M. Miller | `elected` | **2021-01-01** | `day` ⏸ | A Sec. 10(b), N, R |
| Commission, District 1 | Valerie Wynn | `elected` (**special**) | **2018-06-01** | **`month`** | A Sec. 15(a), N |
| Commission, District 2 | Paul Bronson | `elected` | **2021-01-01** | `day` ⏸ | A Sec. 9(c), N |
| Commission, District 3 | Stanley B. Stewart | **`appointed`** | **2024-10-15** | **`day`** | K, A Sec. 15(b) |
| Commission, District 4 | Joseph "Joey" Hulett | `elected` | **2025-01-01** | **`day`** | I, O |
| Commission, District 5 | Andrea Cooke | `elected` (**special**) | **2026-04-20** | **`day`** | Q, P |
| Commission, District 6 | Raymond Wilder | `elected` | **2021-01-01** | `day` ⏸ | A Sec. 9(c), N |
| Commission, District 7 | Bill Howell | `elected` | **2021-01-01** | `day` ⏸ | A Sec. 9(c), N |
| Commission, District 8 | Donice Bryant | `elected` | **2025-01-01** | **`day`** | I, O |
| Commission, District 9 | Brendalyn Bailey | **`appointed`** | **2024-01-17** | **`day`** | L, M, A Sec. 15(b) |

**Mayor Pro Tem: Valerie Wynn (D1)** — a parenthetical on the D1 seat title, per M3. Not an office.

#### How the four 2021-01-01 starts were established, and what is still open

Source N is a contemporaneous qualifying list that marks **which 2020 candidates were sitting
commissioners**. It resolves incumbency directly:

| 2020 district | What N says | Therefore |
| --- | --- | --- |
| D1 | "**Commissioner** Valerie Wynn runs against John Adams" | incumbent — started **before** 2021 |
| D2 | "Paul Bronson and Weston Stroud run for **Schlesinger's vacant seat**" | **new** |
| D5 | "… for **Bert Bivins's vacant seat**" | **new** (Clark, since departed) |
| D6 | "Robert Abbott, Donald Druitt Sr., and Raymond Wilder are running" | **new** |
| D7 | "Bill Howell, Timothy Rivers, and Bonnie Thompson are running" | **new** |
| D8 | "… will run against **Commissioner** Virgil Watkins" | incumbent |
| D9 | "**Mayor Pro Tem Al Tillman** runs against Brendalyn Bailey" | incumbent |
| Mayor | "a different mayor for the first time since 2007" | **new** — Miller |

🟢 **The count closes on itself.** 2020 produced exactly **four** new commissioners — Bronson, Clark,
Wilder, Howell — which is what the contemporaneous coverage says, and the four members term-limited in
2024 (Lucas, Jones, Watkins, Tillman) are exactly the four who had served "since the city and county
merged in 2014". The two arithmetics are independent and both close at nine.

⏸ **THE `day` PRECISION ON THE FOUR 2021-01-01 ROWS IS A JUDGMENT CALL AND IS FLAGGED FOR CANTRELL.**
The date is not quoted by any source. It is the charter's own commencement rule — Sec. 9(c) and
Sec. 10(b), "shall take office on the **first day of January** immediately following the date of the
election" — applied to a sourced 2020 election. The county states the identical rule as fact for the
2025 cohort (source I: "begins at 12:00 a.m. on January 1, 2025"), and source R independently places
Miller in office "four years" before January 2025.

This is a **legal rule applied to a sourced election**, not the GA-4 Chapple case (a date inferred from
vague prose, which was correctly refused and written `unknown`). My read is that `day` is right and
`unknown` would discard something genuinely known. **If Cantrell disagrees, the change is one column:
`year` at 2021-01-01, or open-ended `unknown`.** The derivation goes in the `source` string either way,
never presented as a quotation.

**Wynn is `month`, deliberately.** Bechtel resigned D1 to run for the state House; the special election
was 2018-05-22, the runoff 2018-06-19, and she beat Lynn Wood 677–582. The reporting says she "could be
sworn in by Friday" and would vote on the budget in late July. **No source states the oath date**, so
the day is not written. `2018-06-01` at `month` precision.

### County — Bibb County (5)

| Seat | Holder | how_started | term_start | precision | Source |
| --- | --- | --- | --- | --- | --- |
| Sheriff | David Davis | `elected` | **2013-01-01** | **`year`** | S, N |
| Clerk of Superior Court | Erica Woodford | `elected` | — | **`unknown`** | U, N, W |
| Tax Commissioner | S. Wade McCord | `elected` | — | **`unknown`** | N, W |
| Judge of Probate Court | Sarah S. Harris | `elected` | **2013-01-01** | **`year`** | T, X, N |
| Coroner | Leon Jones | `elected` | — | **`unknown`** | V, N, Y, Z |

- **Davis** — his own office states he "was first elected Sheriff of Bibb County in November of 2012".
  Georgia county officers take office the following January, so 2013 at `year`. ⚠ The same bio still
  says "re-elected to his **third** term in November of 2020" and has not been updated for 2024 — a
  stale sentence on a maintained site. It is not used for anything but the first election.
- **Harris** — elected unopposed in 2012, succeeding retired Judge William J. Self; re-elected to her
  **fourth** term in 2024 (source X). 2013 at `year`. ⚠ "Succeeded a *retired* judge" leaves open
  whether she was appointed to a remainder first; the day is therefore not written.
- **Woodford, McCord, Jones** — all three are confirmed **in office** (below), but no source examined
  states when their occupancy began. Jones has "been elected six times" with a term ending 2028, which
  would arithmetically put him in office from 2005 — **that is arithmetic on a press phrase, not a
  source, and it is not written.** Open-ended at `unknown` is the honest record, and matches what
  Columbus wrote for nine of eleven.

---

## The change-check — "has this person LEFT?"

Run live 2026-09-01, against each officeholder's own body, in **both** directions. This is the check
GA-3 ran against its *sources* instead of its *seats*, which put a retired coroner into production.

**It paid immediately, on the one seat where it mattered.**

| Must be present | Evidence |
| --- | --- |
| All 9 commissioners + Mayor | Source B fetched today; source C edited 2026-02/03 and names all nine including Cooke |
| **Andrea Cooke (D5)** | Sworn in **2026-04-20** (Q). **Four of the five GIS layers do not know she exists** |
| Valerie Wynn as Mayor Pro Tem | Elected **2026-01-06** (P) |
| Lester Miller | Proposed the **FY27 budget** in 2026 (`maconbibb.us/proposed-fy27-budget-presented/`) |
| **Leon Jones, Coroner** | **Working 2026-07** (Z) and **2026-03** (Y). 🟢 Exactly the currency Baldwin's coroner lacked |
| Davis, Harris, Woodford, McCord | Acted **jointly** on the legal organ, Dec 2025, effective 2026-01-01 (W, T) |

| Must be ABSENT | Why |
| --- | --- |
| **Seth Clark** (D5) | **Resigned 2026-01-05** to run for Lieutenant Governor (P, Q) |
| Elaine Lucas (D3) | Stepped down autumn 2024; term-limited (J, K) |
| Al Tillman (D9) | **Resigned 2024-01-09, effective immediately** (M) |
| Mallory Jones III (D4), Virgil Watkins Jr (D8) | Term-limited; last meeting 2024-12-03 (J) |
| Gary Bechtel (D1) | Resigned 2018 to run for the state House |
| Larry Schlesinger (D2), Bert Bivins (D5) | Seats vacant at the 2020 qualifying (N) |
| Thomas W. Tedders, Jr. | Former Tax Commissioner, superseded by McCord |

🔴 **The check is not uniform, which is its own positive control.** Source G still names Lucas, Clark
and Tillman — three people who have all left — so a roster read from the first-listed GIS layer would
have seated three departed officials and missed the only 2026 arrival.

---

## What GA-5 writes

| | |
| --- | --- |
| Governments | **1** — keyed on TIGER place `1349008` (whole county, `FUNCSTAT 'A'`, no balance record) |
| Chambers | **3**, all on that one government: Commission (9), Office of the Mayor (1), Bibb County officers (5) |
| Districts created | **10** — 9 × `X0045` + the citywide `1349008`/`G4110` |
| Districts asserted, never inserted | Bibb County `13021`/`G4020`, `district_type = 'COUNTY'` |
| Offices | **15** |
| People / terms / vacancies | **15 / 15 / 0** |
| `external_id` sub-range | **`-1331036 .. -1331050`** |
| `num_officials`, citywide district | **1** — the Mayor alone. Macon-Bibb has no at-large seats |

🔴 City districts are `district_type = 'LOCAL'`; the county tier is `'COUNTY'`. **They cover identical
ground**, so GA-4's tier-crossing gate applies here in full.

🔴 Every count in the structure migration's post-verify must be **scoped to the two city chambers** —
the county chamber joins the same government row, so a government-wide assertion would pass on the day
it applies and fail forever afterwards. That is GA-4's invisible break, inherited exactly as predicted.
