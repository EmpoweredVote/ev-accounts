# Saint Paul instruments — read, with roll calls

Source: Legistar public Web API, client `stpaul`, no key. Text from
`/matters/{id}/texts/{version}`; roll calls from `/eventitems/{MatterHistoryId}/votes`
(the event-item id **is** `MatterHistoryId`).

**Result: two instruments survive as chair evidence, two are refused by C46.**

| Matter | Adopted | Tally | C46 (≥10% against) | Verdict |
|---|---|---|---|---|
| Ord 22-37 rent stabilization | 2022-09-21 | **5–2** | 29% against ✅ | **usable** |
| Ord 25-29 rent stabilization | 2025-05-07 | **4–3** | 43% against ✅ | **usable** |
| Ord 26-31 minimum wage | 2026-08-12 | **7–0** | 0% ❌ | 🔴 **REFUSED** |
| RES 25-1980 immigration | 2025-12-10 | **5–0**, 2 absent | 0% ❌ | 🔴 **REFUSED** |

---

## 🔴 Correction: the minimum-wage ordinance is NOT usable

The scope review called **Ord 26-31** "the most promising single instrument in this slice". Reading
its roll call withdraws that. It was adopted **7–0 on 2026-08-12** — every member voting yes. C46
(spec §4.12) requires 10% or more against before a vote is a position, so a unanimous vote is not
one. This is the Charlotte data-centre moratorium exactly: it *passed 11-0 twice*, and C46 refused it.

The title's intro date, 2026-06-15, is also not the adoption date. **Adoption was 2026-08-12.**

`minimum-wage` stays **in scope** — ch. 224 exists and the council amends it — but no chair can be
seated from this instrument. A member's own words on the city wage would still qualify as statement
evidence.

## 🔴 Correction: the immigration resolution is NOT usable either

**RES 25-1980** (*City Council actions in response to SPPD conduct during federal immigration
enforcement*) was adopted **5–0 with 2 absent** on 2025-12-10. Unanimous among those voting, so C46
refuses it.

⚠ **Anika Bowie and Cheniqua Johnson were ABSENT.** An excused absence is not a position (spec
§3.2). Do not read either absence as opposition.

`local-immigration` stays in scope — Admin. Code ch. 44 is the city's own instrument — but this
resolution seats nobody.

---

## ✅ Ord 25-29 — rent stabilization, adopted 2025-05-07, 4–3

Sponsor contact on the matter record is **saura.jost@ci.stpaul.mn.us**.

**Operative section** (§ 193A.08, *Exceptions*), quoted from the matter text:

> (3) Residential rental property that is newly constructed or had a change in occupancy
> classification.
> a. The limitation on rent increases shall not apply to newly constructed residential rental
> properties that were issued their first building certificate of occupancy **less than twenty (20)
> years** from the date of notice of a rent increase after December 31, 2004.

The recitals say why, and C51 means the operative section governs — but the two agree here:

> WHEREAS, the need for affordable housing in the City of Saint Paul continues to outpace the
> construction of new housing and the City Council desires to ensure that **the RSO does not dissuade
> the construction of new housing**

This **widens** the new-construction exemption. Ord 22-37 had set it at 15 years (its own amendment
sheet is titled *"Jalali Amendment #1 - 15 Year NCE after 1.1.23"*); this moves it to 20 years and
back-dates it to 2004. The 3% cap stays on every unit that is not exempt.

**Roll call**

| Member | Vote | In our 18? |
|---|---|---|
| Rebecca Noecker | Yea | ✅ Ward 2 |
| Anika Bowie | Yea | ✅ Ward 1 |
| Saura Jost | Yea | ✅ Ward 3 |
| Matt Privratsky | Yea | — not seated in our data |
| Nelsie Yang | Nay | ✅ Ward 6 |
| HwaJeong Kim | Nay | ✅ Ward 5 |
| Cheniqua Johnson | Nay | ✅ Ward 7 |

**Molly Coleman (Ward 4) did not vote** — C44, a vote cast before the member took the seat is not
evidence. Correctly excluded, not a gap.

### Chair mapping — Yea names chair 3; Nay does not name a chair

Ladder: 1 *expand to all units* · 2 *strengthen and extend coverage* · 3 **maintain current tenant
protections while allowing market rents for new construction** · 4 *limit to subsidised units* ·
5 *oppose rent control entirely*.

🟢 **A Yea vote names chair 3 almost verbatim.** The ordinance keeps the rent stabilization ordinance
and its 3% cap in force, and exempts new construction. Chair 4 is excluded on the text: the cap is
not limited to subsidised units, it applies to every non-exempt unit.

🔴 **A Nay vote does NOT name a chair.** It establishes direction only — against widening the
exemption. Chairs 1 and 2 both sit on that side, and a vote to keep a 15-year exemption rather than a
20-year one is not a vote to extend coverage to more units. Under the evidence standard that is a
**blank**, unless the member's own words name a rung. *"The least extreme chair the reasoning
supports" is a tiebreaker, not evidence.*

**Candidate rows (record evidence, to be written one member per run):**
Noecker 3 · Bowie 3 · Jost 3.

## ✅ Ord 22-37 — rent stabilization overhaul, adopted 2022-09-21, 5–2

Its first recital corroborates the statutory reading in `scope-review.md` from the city's own text:

> WHEREAS, on **November 2, 2021, a majority of voters in the City of Saint Paul voted in favor of
> adopting the residential rent stabilization ordinance**

That is the § 471.9996 subd. 2 general-election route, stated by the ordinance itself.

The 2022 overhaul also loosened the ordinance — § 193A.05 now lets a landlord raise rent by up to
**8% plus CPI** after a just-cause vacancy.

**Only two of its seven voters are in our 18**: **Rebecca Noecker (Yea)** and **Nelsie Yang (Nay)**.
Brendmoen, Tolbert, Prince, Jalali and Balenger have all left the council. Same mapping as above:
Noecker's Yea corroborates chair 3 across two separate votes three years apart; Yang's second Nay
still establishes direction only.

---

## What this changes

- **3 candidate chairs** from one ordinance, before any news mining. Charlotte's first pass produced
  3 and Florida's 2.
- The two instruments I flagged as most promising in the scope review are both **refused**, and both
  for the same reason. ▶ **Check the tally before calling an instrument promising.** A title and a
  date say nothing about whether the body divided.
- `minimum-wage` and `local-immigration` remain live ladders; they simply have no usable *record*
  instrument yet. Statement evidence is the route for both.

---

# Duluth — the API exists, and it will not yield a single chair

## 🟢 Correction: Duluth DOES have the Legistar Web API

The scope review said Duluth has none. That was a **false negative**. The client is **`duluth-mn`**,
with a hyphen. My first probe tried `duluth` and `duluthmn`, both of which 500, and I stopped there.

▶ **Client names are not derivable from the city name — enumerate variants, hyphens included.** This
is the same error as the `"ranked choice"` / `"ranked voting"` false zero, one layer out: a confident
negative produced by trying too few spellings.

Identity confirmed before use: `/duluth-mn/bodies` returns *Duluth Economic Development Authority*,
*Duluth Citizen Review Board* and *Duluth Public Utilities Commission*, and `/persons` returns
**Arik Forsman, Janet Kennedy, Roz Randorf and Terese Tomanek**, all `active=1` — four of our 18.

## 🔴 But it carries no per-member roll calls, and the council does not divide

| Measurement | Result |
|---|---|
| Event items scanned (3 meetings) | 186 |
| Items with `EventItemRollCallFlag = 1` | **0** |
| `/eventitems/{id}/votes` on the two 2026 immigration items | **empty** |
| Meetings whose minutes were read | **14** |
| Roll-call tallies found in those minutes | **37** |
| Tallies that were **not** unanimous | **0** — 30 × (9-0), 7 × (8-0) |

The empty `/votes` response is **not** a broken detector. The same endpoint returns seven named votes
for Saint Paul, and Duluth's own action text explains why it is empty:

> Motion to approve was made by Councilor Randorf, seconded by Councilor Tomanek. **Motion carried
> unanimously by voice vote.**

**Consequence: C46 refuses every Duluth vote in the window examined.** Ten of the slice's eighteen
people have no usable record instrument at all. They must be researched from **their own words** —
statement evidence, which goes to human review.

⚠ **I did not find a single divided Duluth vote, so the format used to record one is UNKNOWN.** The
minutes write unanimous results as *"carried unanimously by roll call vote (9-0)"*, which names
nobody because it does not need to. Whether a divided tally would name the dissenter is **not
established** — do not assume either way.

## What Duluth does and does not have

- **`rent-regulation` — no instrument.** `rent stabilization` and `rent control` both return **zero**
  matters. That zero is trustworthy: the same query shape returns results for `tenant`, `housing`,
  `immigration` and `ranked`.
  ⚠ A bare `rent` search returns 20 hits and they are **false** — `substringof` has no word boundary,
  so it matches **CONCURRENT** use permits. Search the phrase, not the stem.
- **`minimum-wage` — no instrument.** Zero matters. Duluth has **Earned Sick and Safe Time**
  (Ch. 29E, Ord 18-009-O, amended 19-052-O and 20-003-O), but paid leave is not a wage floor and
  names no rung on this ladder.
- **`local-immigration` — two 2026 instruments, both refused.**

  | Matter | Adopted | How |
  |---|---|---|
  | 26-0100R — resolution clarifying the city/federal enforcement relationship | 2026-02-09 | unanimous |
  | 26-005-O — Ch. 2, new Article XXXIX, *Stewardship of City Resources* | 2026-02-23 | unanimous voice vote |

  🔴 **Mover and seconder are not chair evidence.** Randorf moved 26-005-O and Tomanek seconded it.
  Charlotte already tested motion sponsorship as individual evidence and the distribution refuted it
  — it is a procedural role. Do not seat either member from this.
- **`ranked-choice-voting` — 2015 only** (15-0516R, fixing a ballot question). Predates every current
  member, so C44 excludes it.

## ⚠ The two cities do not share a vocabulary

Saint Paul's ordinances say **"ranked voting"**. Duluth's say **"ranked choice voting"**. Same state,
same ladder, different search term. Run both spellings in every city.

---

**Next:** outlet profiling, then research one member per run. Start with Noecker, Bowie and Jost,
whose rent rows are already evidenced. **Budget Duluth as a statement-only city** — its ten members
will cost more per seated chair than Saint Paul's eight.
