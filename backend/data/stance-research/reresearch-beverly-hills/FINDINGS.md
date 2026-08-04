# Beverly Hills re-research — findings, session 1 (2026-08-04)

First cluster worked from `data/stance-retirement/2026-08-03-reresearch-worklist.json` (303 rows / 109
politicians). Beverly Hills was chosen first because all 42 of its owed rows sit on **5 people in one
city**, every one of them emptied to **zero** answers by migration 1538, which is what switched the
city's purple "compass stances seeded" chip off (essentials commit `ca993e74`).

**Nothing has been written to production. No migration. Next free number is 1546.**

## 🔴 FINDING 1 — the roster is stale: Mirisch left the council, Pynoos is not seeded

John Mirisch **completed his fourth and final term on 2026-07-07** and is no longer a Beverly Hills
councilmember. **Rebecca Pynoos** won the seat and is not in our database at all.

- Official city page lists exactly five: Mayor **Craig A. Corman**, Vice Mayor **Mary N. Wells**,
  Councilmembers **Lester Friedman**, **Sharona R. Nazarian PsyD**, **Rebecca Pynoos** —
  <https://www.beverlyhills.org/223/City-Council> (Mirisch absent; Pynoos photo "Coming Soon").
- Installation 2026-07-07 at the Samuel Goldwyn Theater; Friedman reelected to a third and final term,
  Nazarian to a second, Pynoos new, Mirisch out as "the longest-serving councilman in the city's
  history" — <https://beverlypress.com/2026/07/beverly-hills-installs-new-city-council/>.

**Consequence for this worklist:** Mirisch's 11 owed rows (10 in tier-scope) are **dropped from the
research queue**. Re-researching them would publish new stances for someone who left office five
months into our own retirement pass. They are not blanks and not defects — they are OUT_OF_OFFICE.

⚠ **This was found by reading, not by any check we own.** `essentials.office_terms.term_end` is NULL
for **all 98** politicians on the worklist, so the database asserts every one of them is still seated
and cannot distinguish a sitting member from a departed one. Newton (57 rows) and Medford (36 rows)
both held municipal elections since their seeding and must be roster-checked the same way **before**
any stance work, not after.

✅ **RESOLVED by migration 1546** (applied 2026-08-04 on operator instruction, dry-run first). Mirisch's
term closed `2026-07-06 / term_expired` and `is_incumbent` cleared — both gates, because
`current_office_holders` filters on `term_end` while `getPoliticiansFlatList`'s incumbents-only view
filters `p.is_incumbent` with no occupancy join at all, so fixing one alone is a half-repair. Pynoos
seated `term_start 2026-07-07`, `how_started 'elected'`. Verified after: the council reads exactly
*Corman, Friedman, Wells, Pynoos, Nazarian*; Mirisch has 0 current-holder rows; stance counts unmoved at
33,171 / 33,717.

🔴 **The handoff had to be dated 07-06 → 07-07, not 07-07 → 07-07.** `office_terms_no_overlap` is
`EXCLUDE USING gist (office_id =, daterange(term_start, term_end, '[]') &&)` — **inclusive both ends** —
so ending the predecessor on the successor's start date is rejected outright. Pynoos's 07-07 is the
verified fact; Mirisch's 07-06 is the modelling consequence, and it is recorded as such in the migration.

🔴 **TWELFTH first-cut detector over-fire, and a warning for every future roster migration.** The guard
"no existing Pynoos row" fired on **3 rows** — all of them **campaign-finance committees**:
`PYNOOS FOR BH CITY COUNCIL 2026; REBECCA` (twice) and `PYNOOS FOR LA CITY COUNCIL 2022; KATE`, with
empty `first_name`, `is_active` false, and `office_terms` rows pointing at offices that have no title,
chamber or government. **Most of `essentials.politicians` is not people** — roughly 77,000 of 85,139 rows
are committees — so any name-matching guard must use the exact person form, or it blocks correct work
while looking like it caught a duplicate.

## ⚠ FINDING 2 — `beverlyhillscourier.com` is paywalled, and it fails open

`https://beverlyhillscourier.com/2025/06/19/city-council-approves-budget/` returns **HTTP 200 with a
teaser and "This content is for Recurring Membership!"** — no article body. This is the thin-body trap
in a new costume: a reachability sweep scores it OK, an extractor reports a short body, and a reader
concludes the page does not carry the claim when in fact the page was never shown to us.

The retired citations used `www.bhcourier.com/article/<slug>` — the **composed** host+path shape. The
real outlet is `beverlyhillscourier.com/<yyyy>/<mm>/<dd>/<slug>/`. Both facts matter: the old URLs were
never real, and the real ones are mostly unreadable, so **the Courier cannot be this cluster's evidence
base.** `beverlypress.com` (Beverly Press & Park Labrea News) is free, dated, and names individual
councilmembers — it is the workable source here.

## ⚠ FINDING 3 — "unanimously approved" is not per-member evidence

The strongest available document, the SB 79 transit-plan vote, is reported as *"The Beverly Hills City
Council on June 9 unanimously approved…"* with no roll. A unanimous vote does not establish that any
particular member was present and voting, and the city publishes **agenda briefs, not minutes**:
`/1774/Council-Meetings-Summary` links `Formal-Meeting-06-09-2026`, whose own header says
**"Summaries are not Official Minutes"** and which carries no roll call (it confirms the item —
F-2, urgency ordinance amending the TOD Alternative Plan for SB 79, the plan itself first adopted
2026-01-21 — and nothing about votes).

So the vote is used **only** for the member the article quotes by name. Wells, Friedman and Nazarian
are left PENDING rather than assigned by inference from the word "unanimously". Getting them will take
either official minutes (City Clerk, 310-285-1000) or their own quoted words.

## Row-level results

Scope: 42 owed rows. **5 out of tier-scope** (Taxation and Public Spending is `federal+state` in
`compass_topic_roles`, so it cannot display for a city officeholder — close permanently as
BLANK_OUT_OF_SCOPE, do not research). **10 dropped** as Mirisch/OUT_OF_OFFICE. **27 in play**, of which:

| verdict | rows | meaning |
|---|---|---|
| ✅ CHAIR ASSIGNED | 1 | evidence read verbatim, one chair distinctly fits |
| ⏭ SKIP_ADJACENT | 2 | evidence read; two adjacent chairs both fit, so no answer is correct |
| ⏳ PENDING | 24 | not yet decidable from sources read — **not** blanks |

### ✅ Craig A. Corman — Residential Zoning = **3**

Chair 3 is *"Allow multifamily and mixed-use near commercial corridors while protecting most
residential zones."* The TOD Alternative Plan does exactly that, and Corman is quoted describing it
in his own words.

- <https://beverlypress.com/2026/06/beverly-hills-approves-transit-plan-for-sb-79/> — verified verbatim
  in raw HTML: *"We essentially have taken as much density as we can out of our single-family
  neighborhoods, trying to protect our single-family neighborhoods, and we've been able to concentrate
  it on a very small area east of La Cienega where there are no single-family neighborhoods, next to
  the new Metro subway stop. It concentrates the additional density in an area where it belongs."*
  The plan moves 50% of SB 79 density into the mixed-use overlay on Wilshire Boulevard east of La Cienega.
- <https://beverlypress.com/2026/07/corman-charts-course-for-the-future-of-beverly-hills/> — verified
  verbatim: TODAP *"seeks to concentrate future housing around the Wilshire/La Cienega Metro station
  while reducing development pressure on single-family neighborhoods"*; Corman says the strategy creates
  *"a vibrant mixed-use district where new housing and businesses support one another."*

Adjacent chairs tested and excluded: **2** is modest duplex/ADU density with design review — this is
concentrated multifamily, not modest infill; **4** is broad by-right upzoning with streamlined
approvals — the plan deliberately narrows where density lands and was adopted to keep it out of
single-family areas.

⚠ **Do not take the bill number from the mayor-profile article.** It says "Senate Bill 29"; the
transit-plan article, the city's own agenda brief and the SCAG map all say **SB 79**. Same trap as the
Bentz roll-call row (right vote, wrong bill number). The row names SB 79 and cites the transit-plan
article, which carries that number verbatim — the number must travel with the source that has it.

### ⏭ Skips — evidence read, chair not separable

- **Corman / Homelessness Response.** His only statements are *"Our goal cannot be to eliminate
  homelessness because that's beyond our power. What we can do is make sure that Beverly Hills
  residents are safe and don't have to worry about encounters with homeless people who may have mental
  illnesses or other issues"* and that the city will continue addressing it *"as humanely as possible."*
  Both verified verbatim. **No strategy is named** — nothing about enforcement, shelter capacity or
  service investment — so chairs 3 (services plus reasonable public-space rules) and 4 (anti-camping
  enforcement primary) both fit. SKIP. Note the retired chair here was 4; that is not a prior.
- **Corman / Transportation Priorities.** Verified verbatim: Metro *"presents opportunities as well as
  challenges"*, *"I think we have not seen any significant negative impacts from the station"*, plus a
  "Metro with the Mayor" ridership-familiarisation program. Promoting transit *use* is not a statement
  about where transportation *investment* should go, and chairs 1 and 3 are indistinguishable on this
  evidence. SKIP.

### ⏳ Pending — what each still needs

- **Wells, Friedman, Nazarian / Residential Zoning** — the June 9 roll call, or their own words.
- **Corman, Wells, Nazarian, Friedman / Public Safety Approach** — the FY 2025-26 and 2026-27 budget
  deliberations. The Courier's budget coverage is paywalled; try Beverly Press budget articles and the
  study-session item on the BHPD military-equipment policy (June 9, Study Session A-4).
- **All / Local Immigration Enforcement** — no dedicated source searched yet. Do **not** record these
  as blanks; nothing has been read.
- **All / Affordable Housing** — TODAP and the Builder's Remedy remarks are land-use, not affordability
  mechanisms. Needs the affordable-housing guidelines item or inclusionary-policy coverage.
- **Mirisch-only topics** (Campaign Finance, Climate Change, Local Environment, Growth) — moot, dropped.
- **Nazarian / Civil Rights and Social Justice** — not yet searched.

## Method notes for the next session

- `scripts/read-site.mjs --site <url> --find "a|b|c"` is the right first move on every candidate page:
  it prints `raw=`/`body=` hit counts so a miss in `body` alone is a report about the extractor, not
  about the page. Every quote above was confirmed as a `raw` HIT before being written down.
- City-council PDFs fetched by URL can be read directly — the agenda brief above was parsed straight
  from the saved PDF rather than guessed at from a summariser.
- The generator for these worksheets is `scripts/reresearch-worksheet.mjs "<government>" <outdir>`;
  it marks out-of-tier topics so no one re-creates the out-of-tier backlog that 1543-1545 shrank.
