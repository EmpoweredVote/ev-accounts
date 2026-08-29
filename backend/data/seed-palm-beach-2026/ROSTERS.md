# Palm Beach County — reconciled roster, 2026-08-28

Wave **FL-5** of the Knight Foundation cities program.
Plan: [`2026-08-28-knight-fl-wave-5-palm-beach-county.md`](../../../docs/superpowers/plans/2026-08-28-knight-fl-wave-5-palm-beach-county.md)
Slice notes: [`fl.md`](../../../.planning/knight-foundation/fl.md)

**12 offices, 12 people, 0 vacancies.** County only — Palm Beach County has no city half in this
program, so there is no municipal table here and the acceptance probe has three required answers
rather than four.

🔴 **Palm Beach publishes NO combined elected-officials page.** Manatee's and Leon's Supervisors of
Elections each gave one document covering both bodies. Palm Beach's gives none — `votepalmbeach.gov`
offers only Candidates / Elections / Records. Every row below is sourced from the officeholder's own
publisher, and three of the seven commission dates had to come from outside the county's own site.

---

### Palm Beach County

| Seat | Slug | Name | external_id | term_start | precision | how_started | source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Commissioner, District 1 | commissioner-1 | Maria G. Marino | -1240061 | 2020-11-01 | month | elected | pbcgov-d1-bio |
| Commissioner, District 2 | commissioner-2 | Gregg K. Weiss | -1240062 | 2018-11-01 | month | elected | pbcgov-d2-bio |
| Commissioner, District 3 | commissioner-3 | Joel G. Flores | -1240063 | 2024-11-01 | month | elected | pbc-soe-candidates-2024 |
| Commissioner, District 4 | commissioner-4 | Marci Woodward | -1240064 | 2022-11-01 | month | elected | pbcgov-d4-bio |
| Commissioner, District 5 | commissioner-5 | Maria Sachs | -1240065 | 2020-11-01 | month | elected | pbc-soe-candidates-2024 |
| Commissioner, District 6 | commissioner-6 | Sara Baxter | -1240066 | 2022-11-01 | month | elected | pbc-soe-candidates-2022 |
| Commissioner, District 7 | commissioner-7 | Bobby Powell Jr. | -1240067 | 2024-11-01 | month | elected | pbcgov-d7-bio |
| Clerk of the Circuit Court & Comptroller | clerk-of-circuit-court | Shannon Ramsey-Chessman | -1240071 | 2026-08-18 | day | appointed | pbcclerk-about-clerk-ad-interim |
| Property Appraiser | property-appraiser | Dorothy Jacks | -1240072 | 2017-01-01 | month | elected | pbcpao-dorothy-bio |
| Sheriff | sheriff | Ric L. Bradshaw | -1240073 | 2005-01-04 | day | elected | pbso-sheriff-bio |
| Supervisor of Elections | supervisor-of-elections | Wendy Sartory Link | -1240074 | 2019-01-01 | year | appointed | votepalmbeach-meet-your-supervisor |
| Tax Collector | tax-collector | Anne M. Gannon | -1240075 | 2007-01-01 | month | elected | pbctax-about-us |

<!-- COUNTS: county_offices=12 county_people=12 vacancies=0 -->

## Counts

- Board of County Commissioners: 7 offices, 7 people, 0 vacant
- Elected Officials: 5 offices, 5 people, 0 vacant
- Total: 12 offices, 12 people, 0 vacant
- external_id range used: -1240075 .. -1240061 (68..70 deliberately unused)
- Date precision: **day 2, month 9, year 1, unknown 0**

🔴 **Zero `unknown` precisions — the first Florida wave with none.** FL-3 had 3 of 17, FL-4 had 9 of
18. That is not because Palm Beach publishes more; it is because the Supervisor of Elections' candidate
filing report (see sources) dates every contested seat by cycle, which neither Manatee nor Leon
offered.

## alternate_names

The form the publisher uses is `full_name`, because that is what a voter sees. The alternate carries
the form a later dedupe pass or headshot search is likely to hit. Same rule as the Ben/Benjamin
Nadolski failure.

| Slug | full_name | alternate_names | why they differ |
| --- | --- | --- | --- |
| commissioner-1 | Maria G. Marino | Maria Marino | middle initial on both the county page and the ballot |
| commissioner-2 | Gregg K. Weiss | Gregg Weiss | middle initial in the county's own index |
| commissioner-3 | Joel G. Flores | Joel Flores | the county INDEX and his contact block say "Joel G. Flores"; his BIO says "Joel Flores" |
| commissioner-6 | Sara Baxter | Sara Marie Baxter | the county publishes "Sara Baxter"; her ballot name is "Sara Marie Baxter" |
| commissioner-7 | Bobby Powell Jr. | Bobby Powell | the suffix is on the county page |
| sheriff | Ric L. Bradshaw | Ric Bradshaw | his ballot name carries the middle initial; his own site's header does not |
| supervisor-of-elections | Wendy Sartory Link | Wendy Link | the SOE site uses both forms on the same page |
| tax-collector | Anne M. Gannon | Anne Gannon | ballot name has the initial; her own site's header does not |

⚠ **No alternate invented for Ramsey-Chessman, Jacks or Sachs.** Their publishers and their ballot
names agree, and a guessed variant is a claim about a real person.

---

## 🔴 The Clerk's seat — three holders in fourteen months

The chain, all from public record:

| When | What |
| --- | --- |
| 2021-01-05 | **Joseph Abruzzo** takes office as elected Clerk. |
| 2024-11 | Abruzzo re-elected (SOE filing report, 2024 cycle: `Clerk & Comptroller — Joseph Abruzzo (DEM), Inactive-Elected`). |
| 2025-06 | Abruzzo **resigns**, selected as Palm Beach County Administrator — an appointed post. |
| 2025-08-19 | **Michael A. "Mike" Caruso** appointed Clerk by the Governor and sworn in. He resigned his Florida House seat to take it. |
| 2026-08-18 | The Governor **suspends** Caruso. **Suspended, not removed** — under Fla. Const. art. IV §7 the Senate ultimately removes or reinstates. |
| 2026-08-18 | **Chief Judge Glenn Kelley of the 15th Judicial Circuit** appoints the office's Chief Deputy Clerk as **Clerk Ad Interim** by administrative order, effective the same day. |

The Clerk's own site, read 2026-08-28: *"Shannon Ramsey-Chessman is the Clerk Ad Interim for Palm
Beach County. She was appointed to the position by Chief Judge Glenn Kelley effective August 18,
2026…"* She had served the office since January 2021 as Chief of Staff, Chief Deputy Clerk and Chief
Information Officer.

**Decision: seat Ramsey-Chessman.** `term_start = 2026-08-18`, `day`, `appointed`.

- The voter-facing question the record answers is *"who is my Clerk?"*. Someone is holding the office,
  by court order, and her own office publishes her as its holder. Displaying a suspended officer who
  cannot act would be a false statement about a real person.
- **`is_vacant` is wrong here.** A vacancy means nobody holds the seat. This seat is held.
- **Caruso's own closed term is deliberately NOT written**, though every date for it is known. FL-2
  wrote no predecessor terms for its five legislative vacancies and FL-3 wrote none for Carol Ann
  Felts; writing one here would leave Florida internally inconsistent. It also has no honest enum
  value — `office_terms.how_ended` offers `removed`, and he was not removed.
  ▶ **Adds to the standing open item:** write predecessor terms for all Florida vacancies and
  interruptions together. Abruzzo and Caruso both belong on that list, with the dates above.
- `offices.description` on this one office carries the chain in plain words. It states the suspension
  and the interim appointment as facts and dates. It does **not** restate the criminal allegations;
  the record needs to explain why the elected officer is not seated, and nothing more.

⚠ **The rejected alternative, recorded so it is not re-litigated:** flag the office
`is_vacant = true, vacant_since = 2026-08-18` and write no term. That matches FL-3's Felts handling,
and one same-day news account framed the office as vacant. Rejected because Felts had died and nobody
was performing the office, whereas here a named person is — and `is_vacant` would tell a Palm Beach
voter there is no Clerk.

🔴 **Re-check this seat immediately before `CC_0014` is applied.** The Senate can act, the Governor can
appoint over the administrative order, or Caruso can be reinstated. Switching to the vacancy treatment
is one row in this file and no generator change.

---

## 🔴 Bobby Powell Jr. and Mack Bernard traded seats

- **Mack Bernard** was the District 7 commissioner, elected November 2016. He is now **State Senator,
  SD-24** — seated by FL-2 as `external_id = -1230024`, and he is **already in
  `essentials.politicians`**.
- **Bobby Powell Jr.** was the SD-24 state senator — "eight years in the Florida Senate and four years
  in the Florida House", per his own bio. He is now the **District 7 commissioner**, and he is **not**
  in prod.

🔴 **The stale `County_Commission_Districts` GIS layer still names `MACK BERNARD` for District 7.** A
"reuse the existing person if the name matches" step reading that layer would seat a sitting state
senator on the county commission. Nothing would error; `office_terms` would accept it and Bernard would
appear holding two offices. **Never read a roster out of a boundary layer.**

**Name-collision check, run 2026-08-28 against all twelve names:** exactly one hit — Mack Bernard, who
is not on this roster. **All twelve people here are fresh inserts.** The only other matches were FEC
ALLCAPS committee junk (`MC CAMMACK FOR SAN BERNARDINO…`), which the dedupe rules already exclude.

---

## 🔴 Three of seven commissioner bio pages carry the PREDECESSOR'S biography, unlabelled

`discover.pbc.gov/countycommissioners/<district>/Pages/Biography.aspx` appends the previous
commissioner's biography to the sitting one, with no heading, no separator and no name change to warn
you.

| Page | Incumbent text | Stale text that follows |
| --- | --- | --- |
| District 6 | Sara Baxter — **no election date anywhere** | *"Palm Beach County Commissioner Melissa McKinlay was first elected in 2014."* McKinlay left in 2022. |
| District 7 | *"In November 2024, Bobby Powell Jr. was elected…"* | *"Mack Bernard was elected in November 2016 to the Palm Beach County Commissi…"* |

🔴 **A regex for `elected in (\d{4})` returns 2016 for District 7 and 2014 for District 6.** Right
shape, right page, right district heading, wrong by eight and eight years. Both were read by eye
instead.

Which pages date their own incumbent:

| District | Date in the bio? |
| --- | --- |
| 1 Marino | ✅ "Elected to the Palm Beach County Commission in 2020 and again in 2024" |
| 2 Weiss | ✅ "elected to the District 2 seat … in November 2018 and was reelected in 2022" |
| 3 Flores | ❌ only "He served as the Mayor of the City of Greenacres from 2017 to 2024" |
| 4 Woodward | ✅ "elected in November 2022 … and currently serves as Vice Mayor" |
| 5 Sachs | ❌ prior offices only — FL House 86th 2006–2010, FL Senate 30th 2010–2012, FL Senate 34th |
| 6 Baxter | ❌ none; McKinlay's stale bio follows |
| 7 Powell | ✅ "In November 2024, Bobby Powell Jr. was elected…" |

⚠ Two smaller traps on the same site: the district URL casing is inconsistent (`district1` …
**`District5`** with a capital D … `district7`), and every page's extracted text opens with the full
site navigation, which contains the literal strings "District 1" through "District 7" and matches a
naive district-scoping regex.

⚠ **District 5's page is stamped `*Revised 11/2020`** — which is the signal that led to the Sachs
correction below. A page's own revision date can be worth more than its prose.

---

## 🔴 THE PLAN HAD MARIA SACHS' START YEAR WRONG, AND THE SEAT STAGGER IS WHY

The plan expected `2022-11-01` for District 5. **It is `2020-11-01`.** Sachs was elected in **2020**,
succeeding the term-limited Mary Lou Berger, and **re-elected in 2024**.

The mechanism, which the plan did not know:

🔴 **Palm Beach's seven commission seats are staggered ODD / EVEN, not arbitrarily.**

| Districts | Elected in | Next |
| --- | --- | --- |
| **1, 3, 5, 7** | presidential years — 2020, **2024** | 2028 |
| **2, 4, 6** | gubernatorial years — 2018, 2022, **2026** | 2030 |

Confirmed against the Supervisor of Elections' own candidate filing report across three cycles:

| Cycle | County offices with filings |
| --- | --- |
| 2022 (gubernatorial) | BCC Districts 2, 4, 6 — **no constitutional officers** |
| 2024 (presidential) | BCC Districts 1, 3, 5, 7 **and all five constitutional officers** |
| 2026 (gubernatorial) | BCC Districts 2, 4, 6 — **no constitutional officers** |

So District 5 is an odd seat, elected 2020 and 2024. The 2024 filing report corroborates it from the
other direction: `County Commissioner, Dist. 5 — John Fischer (REP), Inactive-Defeated`, i.e. the
challenger lost to a sitting incumbent, which Sachs could only be if she started in 2020.

**Consequence for the plan's churn note: THREE seats are on the November 2026 ballot, not four.**
Districts **2, 4 and 6**. District 5 is not up until 2028.

---

## 🔴 ALL FIVE CONSTITUTIONAL OFFICERS ARE ON THE PRESIDENTIAL CYCLE — AND THE GANNON "CONTRADICTION" WAS THE PLAN'S OWN ARITHMETIC

`fl.md` records, from Manatee, that Florida county officers run on the presidential cycle. **Palm Beach
matches**: all five were on the **2024** ballot and are next up in **2028**. From the 2024 filing
report:

| Office | Candidate as filed | Status |
| --- | --- | --- |
| Clerk & Comptroller | Joseph Abruzzo (DEM) | Inactive-Elected |
| Property Appraiser | Dorothy Jacks (DEM) | Inactive-Unopposed |
| Sheriff | Ric L. Bradshaw (DEM) | Inactive-Elected |
| Supervisor of Elections | Jeff Buongiorno (REP) | Inactive-Defeated *(Wendy Sartory Link won)* |
| Tax Collector | Anne M. Gannon (DEM) | Inactive-Unopposed |

The plan flagged Anne Gannon's page as self-contradictory: *"Elected in 2006"* and *"currently serving
her sixth term"* cannot both be true on a four-year step from 2006, which gives five terms by 2026.

🔴 **They are both true, and the faulty step was the plan's.** On the presidential cycle her elections
are 2006, then **2008, 2012, 2016, 2020, 2024** — six. Her current, sixth term began January 2025.

⚠ **And the plan's supporting inference was unsound for a second reason.** It argued "no
constitutional-officer contest in the 2026 primary ⇒ presidential cycle". That does not follow:
Florida removes **unopposed** races from the ballot entirely, so an unopposed officer appears in no
primary feed regardless of cycle. Jacks and Gannon were both unopposed in 2024 and appear in the
filing report but would not appear in a results feed. **The filing report is the right instrument; a
results feed is not.**

What is **not** established: whether the November 2006 election was a special election for an
unexpired term or the tail of an older cycle. It does not matter for `term_start` — her continuous
occupancy begins **January 2007** either way, at `month` precision — and no date here is inferred from
the unresolved part.

---

## The two appointments — a first for the Florida slice

FL-2, FL-3 and FL-4 wrote `how_started = 'elected'` for all 190 people between them. Two of the five
officers here were appointed:

- **Wendy Sartory Link**, Supervisor of Elections. Her own page: *"First appointed in 2019, elected in
  2020, and re-elected in 2024."* Her continuous occupancy of the office begins with the **2019
  appointment**, so `term_start = 2019-01-01` at **`year`** precision and `how_started = 'appointed'`.
  ⚠ No month is published. `year` is the honest precision; do not derive one from the news cycle.
- **Shannon Ramsey-Chessman**, Clerk Ad Interim. `2026-08-18`, `day`, `appointed`. See above.

⚠ **A gubernatorial appointment is the normal mechanism for a Palm Beach county vacancy** (Fla. Const.
art. IV §1(f)), and District 3 is a worked example the county's own record supplies: **Mike Barnett was
appointed to District 3 in 2023** after Dave Kerner resigned to lead the Florida Department of Highway
Safety and Motor Vehicles, then **lost the 2024 election to Joel Flores**. This is the same mechanism
`fl.md` documents for Manatee's District 1 — except that there the Governor left the seat empty and
here he filled it. **The mechanism is the same; the Governor's choice is not.**

---

## Take-office rules

| Body | Rule | Source |
| --- | --- | --- |
| Board of County Commissioners | *"sworn into office two weeks after being elected in the November general election"* | the county's Overview of County Government |
| The five constitutional officers | 1st Tuesday after the 1st Monday in January | Fla. Const. art. VIII §1(d); ch. 100, F.S. |

**The commission rule makes a day derivable, and this roster deliberately does not use it.** Two weeks
after each general gives 2018-11-20, 2020-11-17, 2022-11-22 and 2024-11-19. Those are written here as
corroboration only. `term_start` is stored at **`month`** precision (`YYYY-11-01`), matching Leon,
because the county publishes no per-person swearing-in date and a mis-stated rule would produce a
confidently wrong day.
▶ Follow-up, shared with FL-4: the Board's organisational-meeting minutes would date all seven exactly.

⚠ **Term limits differ by body**: commissioners may not serve more than two consecutive four-year
terms; the constitutional officers have no limit. **Gregg K. Weiss (District 2) is term-limited** —
2018 plus 2022 — and does not appear among the 2026 filings.

---

## Live churn — re-check before applying

| Seat | Situation |
| --- | --- |
| **Clerk** | 🔴 Held by a Clerk Ad Interim since 2026-08-18. Re-check on the day of apply. |
| **District 2** | **Weiss is term-limited and is not running.** Two qualified Democrats, no qualified Republican, so the August primary was a Universal Primary Contest and decided the seat. **This seat changes hands in November 2026.** |
| **District 4** | Marci Woodward (REP) is qualified for re-election, against one qualified Democrat. |
| **District 6** | Sara Baxter (REP) is qualified for re-election, against four qualified opponents. ⚠ Press reporting in this cycle also described her entering a congressional race and dropping her commission bid; **the SOE filing record shows her Active-Qualified for District 6**, and the filing record is the instrument that governs. Do not restate the congressional claim as fact. |

Every other seat runs to January 2029 (officers) or November 2028 (Districts 1, 3, 5, 7).

▶ **Palm Beach needs a roster re-check after the November 2026 general, before FL-7 assets.**

---

## Out of scope, considered

- 🔴 **State Attorney and Public Defender of the 15th Judicial Circuit.** The county's own *Overview of
  County Government* lists them among its seven "constitutional officers", but they are officers of
  the circuit under Fla. Const. art. V §§17–18. They look countywide only because **the 15th Judicial
  Circuit is coterminous with Palm Beach County** — Leon's 2nd Circuit spans six counties, which is why
  FL-4 never met the question. Seating them on the `12099`/`G4020` district would assert that the
  circuit equals the county: true today, a fact about *circuit* boundaries, and it would make Florida
  internally inconsistent because Leon's voters elect a State Attorney too and FL-4 seated neither.
  ▶ Program-level open work; a `JUDICIAL` compass scale already exists.
- **Palm Beach County School Board** — 7 elected by district. Out of scope, as Manatee's and Leon's
  were. **There is no elected Superintendent of Schools**; Palm Beach's superintendent is appointed by
  the School Board, unlike Leon's.
- **Soil and Water Conservation District**; **Greater Boca Raton Beach and Park District**, **Jupiter
  Inlet District** and **Indian Trail Improvement District** — all elected, all on the county's own
  2026 ballot, none a county commission or constitutional officer.
- **Mayor and Vice Mayor are not offices.** The Board elects them annually from among its own members:
  *"The BCC elects a mayor to preside over commission meetings and serve as the ceremonial head… A vice
  mayor is also selected."* Marino's bio confirms the rotation — she *"served as Mayor of Palm Beach
  County from November 2024 to November 2025"*. **Sara Baxter (D6) is Mayor and Marci Woodward (D4) is
  Vice Mayor** as of 2026-08-28. Same ruling as Bradenton's and Asheville's Vice Mayor, opposite of
  Nashville's.
- Every municipality in the county, **West Palm Beach included** — the county Governmental Center
  anchor sits inside TIGER place `1276600`, which this program deliberately does not seat.

---

## Sources

Working copies of every page are in this directory as `_*.html`, **untracked on purpose** — they are
inputs, not artefacts. `git grep` a filename before deleting one.

| Key | Page | Fetched with |
| --- | --- | --- |
| `pbcgov-bcc-index` | `discover.pbc.gov/countycommissioners/Pages/default.aspx` | curl |
| `pbcgov-d1-bio` … `pbcgov-d7-bio` | `…/countycommissioners/<district>/Pages/Biography.aspx` | curl |
| `pbcgov-overview` | `discover.pbc.gov/pages/pbc-gov-overview.aspx` | curl |
| `pbcpao-dorothy-bio` | `pbcpao.gov/dorothy-bio.htm` | curl |
| `pbso-sheriff-bio` | `pbso.org/sheriff-ric-bradshaw` | curl |
| `pbctax-about-us` | `pbctax.gov/about-us/` | curl |
| `votepalmbeach-meet-your-supervisor` | `votepalmbeach.gov/275/Meet-Your-Supervisor` | curl |
| `pbcclerk-about-clerk-ad-interim` | `mypalmbeachclerk.com/about-us/about-clerk-ad-interim-shannon-ramsey-chessman` | 🔴 **Playwright** |
| `pbc-soe-candidates-2022` / `-2024` / `-2026` | `voterfocus.com/CampaignFinance/candidate_pr.php?c=palmbeach&el=<9\|11\|12>` | 🔴 **Playwright** |

🔴 **Only ONE host 403s `curl` here** — `mypalmbeachclerk.com`, and a full browser header set does not
help. Leon needed Playwright for six hosts. Everything else on Palm Beach answers `curl` normally.

🔴 **The Supervisor of Elections' candidate filing report is the instrument that settled the stagger,
the officer cycle and three of the seven commission dates — and it is NOT on `votepalmbeach.gov`.** It
is an iframe pointing at `voterfocus.com`, reachable only after reading the page's DOM: the
`Announced-Candidates` page renders no candidate data itself, and the iframe URL 302s if fetched
directly with `curl`. The cycle is selected by the `el` query parameter (`9` = 2022, `11` = 2024,
`12` = 2026, `13` = 2028). **Find this first in any later Florida county wave.**
