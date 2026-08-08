# Portland cluster — the 15 published survivors, verified 2026-08-07

Scope: the 15 rows QUEUE.md flagged as "suspect survivors" (Ryan 6, Wilson 5, Smith 2, Novick 2).
All 15 are **still published** (each has a row in both `inform.politician_context` and
`inform.politician_answers`). Portland's `hasContext` chip was already flipped to `false` on
2026-08-04, but the rows themselves were never resolved — that is what this pass covers.

**All 15 are SOLE-sourced, and every one embeds its URL verbatim in the voter-facing reasoning
prose** (the Stephenson shape — the invented URL is not just metadata, voters read it).

---

## Verdicts by citation group

| # rows | politician | cited authority | verdict |
|---|---|---|---|
| 6 | Dan Ryan | `portland.gov/council/agenda` | 🔴 **LIVE landing page, verified absent** |
| 2 | Keith Wilson | `portland.gov/mayor` | 🔴 **LIVE per-person page, verified absent** |
| 3 | Keith Wilson | `oregonlive.com/portland/2024/10/portland-mayoral-candidates-weigh-in-…html` | 🔴 **COMPOSED — article never existed** |
| 2 | Loretta Smith | `oregonlive.com/portland/loretta-smith` | 🔴 **COMPOSED — URL shape never existed** |
| 2 | Steve Novick | `oregonlive.com/portland/steve-novick` | 🔴 **COMPOSED — URL shape never existed** |

### 1. `portland.gov/council/agenda` — Ryan ×6 — verified absent

Live, HTTP 200, fetchable. Isolated `<main>` (4,539 chars of 6,588) and counted claim terms:

```
Ryan 0 · climate action 0 · green infrastructure 0 · shelter 0 · Housing Bond 0
community policing 0 · accountability 0 · relocation assistance 0 · tenant 0
infill 0 · Vision Zero 0 · TriMet 0 · zoning 1 · minutes 4
```

**The page never names Ryan at all.** The two non-zero terms were read in context and are noise:
all 4 "minutes" are time allocations ("Time requested 15 minutes"); the single "zoning" is an
unrelated agenda-item title. The page is a **rolling agenda for the next meeting** (it currently
shows August 12, 2026) — it has never held the 2020-2024 minutes all six rows cite.

This clears the strict bar: the page is live and readable, so this is *verified absent*, not the
weaker *unverifiable* of a lapsed domain (mig 1601).

### 2. `portland.gov/mayor` — Wilson ×2 — verified absent

Redirects to `/mayor/keith-wilson`, a real per-person official page. Body prose is a two-sentence
bio plus contact details and a list of headline links. Main-region term counts:

```
incentive 0 · economic development 0 · downtown 0 · climate 0 · environment 0
carbon 0 · green infrastructure 0 · business 2 · homeless 2
```

Wilson's two rows here are **Economic Development Incentives** and **Environmental Protection vs.
Development** — both score **zero on every distinctive term**. The "business" 2 is the bio phrase
"longtime business owner"; "homeless" 2 is the bio plus a headline. Neither touches either topic.

⚠ Counted on `<main>` only, deliberately — the McCarty ruling (mig 1561) is that .gov word counts
are nav-inflated. Nav-inclusive counts were identical here, so nav inflation did not decide it.

### 3. The three oregonlive URLs — composed

`oregonlive.com` **403s every request** (bot block). A 403 is never absence, so nothing below rests
on it — the verdicts rest on Wayback, with a control that returned data in the same run.

**Control validity first.** An earlier run returned zero for target *and* control, which is
inconclusive (the 08-04 trap). Re-run alone, `oregonlive.com/portland/2024/10*` returned real
captures, so CDX was healthy and the zeros are real measurements.

- **Wilson's article** — `…/2024/10/portland-mayoral-candidates-weigh-in-on-homelessness-housing-and-public-safety.html`:
  **zero captures**, both bare and `www.` forms. The containing directory is densely archived
  (dozens of 200-status `.html` articles). Narrowing to the slug's own neighbourhood,
  `…/2024/10/portland-m*` **does** return a real archived article —
  `portland-mayoral-candidate-bit-by-dog-while-campaigning.html`. So the archive reaches this exact
  prefix and the cited article is not there.

- **Smith's and Novick's index URLs** — the `/portland/<hyphenated-name>` **shape does not exist on
  oregonlive at all**. Zero captures for Smith and Novick, and zero for three well-known Portland
  controls (`carmen-rubio`, `ted-wheeler`, `rene-gonzalez`).

  🔑 **The real shape is `oregonlive.com/topic/<Name>/`** (space-separated, URL-encoded) — and both
  people have genuine archived 200 pages there (`/topic/Steve%20Novick/index.html`,
  `/topic/loretta%20smith/`). So these are composed URLs: a real pattern re-shaped into one that
  never existed. Same family as `clark.house.gov` and `willametteweek.com`.

  🔴 **Do not "repair" these by re-pointing to the real `/topic/` pages.** Those are index pages,
  and a landing page is not coverage ([[landing_pages_not_coverage]]). Swapping a composed index
  for a real index is not a repair.

---

## 🔑 THE UNLOCK: portland.gov publishes per-member roll-call records

QUEUE.md listed "council minutes" as the untried next move. There is something better and it is
free, official, live, and searchable:

```
https://www.portland.gov/council/districts/<n>/<name>/votes
https://www.portland.gov/mayor/keith-wilson/votes
```

Every councilor has one. Each row is a **named individual vote** — council document number, date,
full title, and that member's **Yea / Nay / Absent / Abstain**. Ryan's holds **2,679 votes**.
Query params: `?council_document=<keywords>&voted=<Yea|Nay|Absent|Abstain>`.

This is exactly the per-member evidence Beverly Hills lacked, and it dissolves the 1548 problem that
"unanimously approved" establishes neither presence nor position. **It re-sources this whole
cluster — the 57 retired rows as well as these 15.**

⚠ **It does not work for the mayor.** Under Portland's new charter the mayor votes only to break
ties: Wilson's page holds **exactly 1 vote** (vs Ryan's 2,679). Every topic keyword returns 0.
Wilson must be sourced from his official agenda instead — see below.

🔴 **Vote counts are NOT stance evidence.** The keyword search matches full document text, so
Ryan's "police 186" and "transportation 276" are mostly routine items — lawsuit settlements from
vehicle collisions, pension bonds, fee schedules. A Yea on *"Pay settlement of a bodily injury
lawsuit resulting from a collision"* says nothing about policing policy. Read the item, not the
tally — this is the same trap as the nav-page shape heuristic.

⚠ **Near-unanimous votes are weak evidence** ([[newton_survivors_resolved]]). Smith and Novick vote
identically on most items. They are still good evidence of *a person's own position* when the item
is squarely on-topic (e.g. enacting sanctuary-city protections) — they are just useless for
distinguishing one councilor from another.

### Wilson's replacement basis: Portland's Promise

`portland.gov/promise` is itself a hub, but one level down are four substantive, first-person,
official policy documents ("Here are my goals"):

| page | covers |
|---|---|
| `/promise/about-portlands-promise/activation` | TIF districts, Prosper Portland, downtown — **Economic Development Incentives** |
| `/promise/about-portlands-promise/green-leadership` | green jobs, clean energy, carbon goals — **Environmental Protection vs. Development** |
| `/promise/about-portlands-promise/housing` | affordable housing, home share — **Homelessness Response / Zoning** |
| `/promise/about-portlands-promise/public-health-and-safety` | Vision Zero, investigators, 1,500 shelter beds — **Public Safety** |

---

## Ryan's record vs. his published stances — one real conflict, one I got wrong

🔴 **CORRECTION, recorded deliberately.** On the first pass I reported that Ryan's votes *contradicted
two* of his stances. That was right about Rent Regulation and **wrong about Homelessness Response**,
and the error is instructive: I searched `Homelessness Response System`, found two **Nay** votes, and
read them as opposition to homelessness response. Reading his *whole* record refutes that — he voted
Yea on emergency shelter expansion (four times in 2023), on zoning changes to allow more shelter
options, on Safe Rest Villages, and on years of Joint Office funding. **Both Nays are on Multnomah
County Joint Office GOVERNANCE items** (the three-year IGA and the Action Plan/KPIs), which is a
known Portland fight about county accountability — not a vote against shelter.

🔑 **The lesson is the same one this workstream keeps relearning**: a keyword match is not a topic
match. "Nay on a document whose title contains *Homelessness Response*" looked exactly like the
finding I expected. Only the full record distinguished them.

| published row | what the record actually shows |
|---|---|
| **Rent Regulation, chair 2** — "supported renter protections including relocation assistance and tenant rights ordinances" | **Genuine conflict.** He funds tenant *assistance* heavily (eviction legal defense ×3, tenant stabilisation ×3, security-deposit rules) but voted **Nay** on 2025-045 (Nov 19 2025), *prohibition of anti-competitive rental practices including algorithmic devices* — the one actual rent regulation in the record. Smith: Yea. Novick: Absent. No "relocation assistance" vote exists anywhere in his record. → chair **2 → 3**. |
| **Homelessness Response, chair 2** — "voted for shelter expansion" | **Not contradicted — supported.** Chair still moves **2 → 3**, but for a different reason: he *also* voted for the 2023 and 2024 public camping restrictions, which is services-plus-enforcement, not shelter-first. |

Attribution for both was confirmed against the site's **own** `voted=Nay` filter, not my parser, with
the same query for Smith returning **empty** as a control — so the filter discriminates and this is
not a parsing misalignment.

⚠ Two substring traps worth remembering: `rent` matches "cur**rent**"/"B**rent**wood" (34 hits, mostly
noise) and `tree` matches "s**tree**t" (107 hits, nearly all street LIDs). **Keyword totals from this
search are meaningless; only read titles count.**

⚠ Ryan's higher totals across the board are legitimate: he served on the **old** council 2020-2024,
so his page spans both tenures (2021-22 and 2023-24 budget documents appear). His prior tenure is
real; only the citation for it was not.

---

## Outcome — migration 1608 applied 2026-08-07 (operator chose re-research over retirement)

**12 repaired · 3 retired · 6 chairs corrected.** Rollback:
`data/stance-retirement/2026-08-07-portland-survivors-rollback.json` (verified field-by-field against
the DB before the change; canonical md5 `9835bcc6030512f035ab50d1abb0b7b0`).

| politician | topic | chair | basis |
|---|---|---|---|
| Ryan | Environmental Protection vs. Development | 2 → **3** | continued *existing* private-tree rules (Nov 2024); streamlined environmental zoning for infrastructure (Mar 2026) |
| Ryan | Homelessness Response | 2 → **3** | shelter expansion + shelter zoning **and** the 2023/2024 camping restrictions |
| Ryan | Public Safety Approach | **3** | Nay on Portland Street Response as co-equal branch; Yea on its committee; Yea on police recruitment report |
| Ryan | Rent Regulation | 2 → **3** | funds eviction legal defense; Nay on the algorithmic rent-pricing prohibition |
| Ryan | Residential Zoning | 2 → **4** | Housing Regulatory Relief; vehicle parking reforms |
| Ryan | Transportation Priorities | **2** | Vision Zero reaffirmation; Nay on the Transportation Utility Fee |
| Wilson | Economic Development Incentives | 2 → **3** | six new TIF districts with Prosper Portland |
| Wilson | Homelessness Response | **3** | 1,500 overnight shelter beds **and** resumed camping-ordinance enforcement |
| Wilson | Public Safety Approach | **4** | 24 new investigators by end of 2027; Vision Zero |
| Smith | Local Immigration Enforcement | **1** | voted to codify Code Ch. 23.20 — bars detention agreements and status collection/disclosure |
| Novick | Public Safety Approach | **2** | Yea on Portland Street Response as a co-equal branch |
| Novick | Transportation Priorities | 1 → **2** | Vision Zero + Transportation Utility Fee; **no** evidence of citywide parking reduction, which chair 1 requires |

**Retired (3)** — citation verified absent and no free source found that evidences a chair:
Wilson/Environmental Protection (the Green Leadership agenda is about the green *economy*, not the
development-vs-preservation tradeoff), Wilson/Residential Zoning (housing *production* targets, no
zoning policy), Smith/Homelessness Response (two procedural votes that don't locate her on the
service-vs-enforcement scale).

🔑 **Wilson/Homelessness is the case for re-researching rather than retiring**: the citation was
fabricated but the claim was *true*, and is now provable from the City's own page. Retiring it would
have deleted a correct, verifiable stance — the Lungo-Koehn rule in action.

⚠ **All 21 proposed citations were fetched and asserted to carry their claim terms in raw HTML before
the migration was written.** One initially failed — `Resumed enforcement of the camping ordinance` is
split by markup (`<a><strong>`), so the term was wrong, not the page. That failure surfaced a better
citation: the dedicated `portland.gov/sscc/camping-ordinance`.

**Verified on row counts, not on absence of error**: ctx 33,287→33,284, answers 32,746→32,743,
citations 58,154→**58,160** (predicted +6 exactly), 0 rows citing any of the five bad authorities,
`answer_without_context` 0, orphan context unchanged at 541, and no row introduced that is
bare-domain-only or scheme-less. Gate buckets cannot have grown.

**Nobody was emptied to zero answers** (Ryan 6, Wilson 5→3, Smith 2→1, Novick 2), so no
`last_stances_researched_at` nulling applies and no coverage chip changes.

▶ **Next**: the 57 rows migration 1558 retired are now re-sourceable by the same method — 8 of the 12
councilors still sit at zero answers. Operator deferred scoping that until this pass landed.
