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

## 🔴🔴 CORRECTION 2026-10-05 — IT DOES CARRY PER-MEMBER ROLL CALLS, AND THE COUNCIL DOES DIVIDE

**Everything in the section below this one is WRONG, and it is kept only to show how.** Scanning
**40 meetings** instead of three with `divided_votes.mjs duluth-mn 2025-01-01 138` found **905 event
items, 12 with a recorded roll call, and 10 DIVIDED votes**, every one naming its dissenters. Full
output and per-member tallies: [`duluth-divided-votes.txt`](./duluth-divided-votes.txt).

🔴 **The defect was the SAMPLE, not the detector.** Three meetings and two hand-picked matters is not
a measurement of a city's vote record. Both of those probes returned a *true* empty — those items did
pass unanimously by voice — and the generalisation from them to "no per-member roll calls at all" is
what was false. ▶ **Run the whole-year script before characterising a city's record.** One command
answered in four minutes what a hand sample got backwards.

⚠ Duluth records a roll call for **12 of 905 items (1.3%)**. Saint Paul records one for 918 of 1,059
(87%). So the *rate* finding was real and the *absence* finding was not: **Duluth records a roll call
more or less exactly when the council divides.** A 1.3% rate is what "no roll calls" looked like.

### 🔴🔴 THE API'S ROLL CALLS ARE A FLOOR, NOT A CENSUS — the newspaper carries a tally it does not

`26-0105R` was **tabled 5-4 on 2026-02-09** (the API has that vote) and then **failed 7-2 on the
merits on 2026-02-23** — and for that second vote `/eventitems/{id}/votes` returns **zero**. The
action text records only *"A motion was made to approve 26-0105R by Councilor Durrwachter, seconded by
Councilor Clanaugh"*. The Duluth News Tribune reports the tally and names who was on which side:

> Yet Clanaugh's and Durrwachter's resolution failed on a 7-2 vote, with support only from its authors.

▶ **So `divided_votes.mjs` under-reports, and a city's record evidence is not bounded by its API.**
A vote on the MERITS can be missing while the PROCEDURAL vote on the same matter is present — which is
the worst direction for this error to run, because the procedural one is the one C46 should refuse.
▶ **Read the local paper's meeting coverage as a second census of the vote record**, not only as
statement evidence.

⚠ The same meeting adopted **26-005-O** (Stewardship of City Resources) *"unanimously by voice vote"*,
moved by Randorf — so the zero-votes response is genuinely empty for some items and genuinely
incomplete for others. **The API cannot tell you which.**

### The ten divided votes, and what each one is worth

| Matter | Date | Tally | Verdict |
|---|---|---|---|
| 25-015-O Tenant Right to Repair (petition ordinance) | 2025-07-01 | **2-6 FAILED** | 🟢 single-subject, citizen-initiated — the best record evidence in the city |
| 25-016-O Ch. 29A landlord training, notice, timely repairs | 2025-07-01 | 6-2 | 🟢 the council's own alternative — **read as a PAIR with 25-015-O** |
| 26-0105R Call on the Governor for residential financial protection (Operation Metro Surge) | 2026-02-09 | 5-4 **to TABLE** | ⚠ procedural; a table vote is not a vote on the merits |
| 25-0784R Axon drone-as-first-responder + Draft One, $1.92M | 2025-10-14 | 8-1 | ⚠ procurement, and the lone nay (Awal) is not ours |
| 26-0092R Housing Trust Fund Committee appointments | 2026-02-09 | 6-2-1 | ❌ appointments |
| 25-035-O / 25-036-O 2026 levy and budget | 2025-12-15 | 8-1 / 7-2 | ❌ omnibus |
| 25-0995R Council standing rules, public comment | 2025-12-15 | 7-2 | ❌ procedural, no ladder |
| 25-032-O Lester Park conveyance to DEDA | 2025-12-08 | 8-1 | ❌ single land transaction |
| 25-0891R Shopper's Ramp demolition change order | 2025-11-24 | 7-2 | ❌ single project |

🔴🔴 **THE DIRECTION OF A NAY DEPENDS ON WHAT THE ALTERNATIVE WAS, AND HERE IT INVERTS.**
Durrwachter voted **against** the council's tenant-protection ordinance (25-016-O) and **for** the
tenants' union's stronger one (25-015-O), on the same night. Read alone, her nay on 25-016-O scores as
anti-tenant; it is the opposite. **A divided vote is only legible against the measure it was competing
with.** This is "read the agenda item text before trusting a vote title" one layer deeper — read the
*other item on the same agenda*.

🔴 **Neither pair is `rent-regulation` evidence, and the campaign says so in its own words.** Every
rung of that ladder is about rent *price* — control, stabilisation, market rents. Right-to-repair is
habitability. Asked directly whether it was a precursor to rent control, organiser DyAnna Grondahl
answered **"This is not rent control"** (Duluth News Tribune, 2025-09-16). Seating a rent chair from
these votes would be a confident wrong row.

▶ **No current local ladder states what these ten members divided over.** `rent-regulation` is price,
`housing` is public housing vs subsidies, `residential-zoning` is density. **Tenant protection and
habitability have no ladder.** This is a Season 3 ladder defect and belongs with the other seven.

⚠ Mayor Reinert did **not sign** 25-016-O — it "passes without Mayoral signature". That is a fact
about a signature, not a stated position, and it has two readings. **Do not seat the mayor from it.**

---

## ❌ SUPERSEDED — the original finding, wrong, kept for the lesson

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

❌ **FALSE — see the correction above.** The window was three meetings. Over 40 meetings there are ten
divided votes, and two of them are single-subject housing measures voted on the same night.

⚠ ❌ **FALSE — ten divided votes were found, and the API names every dissenter by full name.**
Original text: **I did not find a single divided Duluth vote, so the format used to record one is UNKNOWN.** The
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

---

# ⚠ UNEXPLAINED: Yang's A1 amendment to Ord 25-29

The attachment `A1 Amendment - Yang` on matter 49196 is a .docx. Read through its Word revision
marks rather than as plain text, because the plain text shows both numbers side by side and says
nothing about which is which:

```
[ less than][STRUCK: twenty (20)][NEW: thirty (30)][ years ]
[ ... ][STRUCK: after December 31, 2004]
```

**The amendment Yang moved would have lengthened the new-construction exemption from twenty years
to thirty, and removed the 2004 cutoff** — both of which make the exemption broader and rent
stabilization weaker.

That does not sit with the rest of the record. Yang voted **against** the ordinance; the minutes show
Johnson and Kim, the other two Nay votes, speaking **for** A1, and Jost, Bowie and Privratsky — the
Yea side — speaking **against** it. A1 failed 3-4.

🔴 **No chair has been seated from this, in either direction.** A protest or poison-pill amendment
would explain it, and so would several other things; none is evidenced. It is written down as
unexplained because the alternative is to guess at a motive and publish the guess.

▶ **This is also why the plain-text read of a .docx is not enough.** The first extraction of this
file produced `twenty (20) thirty (30)` with no way to tell the struck text from the inserted text,
and reading it either way would have been a coin flip presented as a finding.

## ⚠ Correction to an earlier claim in this file

An earlier version said Ord 22-37 set the exemption at **15 years**, inferred from an attachment
*titled* "Jalali Amendment #1 - 15 Year NCE after 1.1.23". That was wrong, and it was wrong because
it read a title instead of the text. A1's own recitals state that the September 2022 amendment
"include[d] a **twenty (20) year** exemption ... and those changes to the law took effect on
January 1, 2023". A proposed amendment's title is not what the council adopted.

---

# 🔴🔴 WHAT ORD 25-29 ACTUALLY DID — read from the RTF revision marks

`MatterTextPlain` renders an ordinance **with the strikethrough invisible**, so it reads as the text
*before* the amendment. Reading `MatterTextRtf` and tracking `\strike` / `\ul` gives the real change:

```
STRUCK   less than twenty (20) years from the date of notice of a rent increase
STRUCK   for twenty (20) years from the date of the first building certificate of occupancy issued after the change.
ADDED    after December 31, 2004
ADDED    that were issued their first building certificate of occupancy after December 31, 2004
```

**Ord 25-29 removed the twenty-year limit altogether and replaced it with a date.** The 3% cap no
longer applies to any rental property first issued a certificate of occupancy after 31 December
2004 — permanently, with no expiry. That is a far larger change than "a longer exemption".

⚠ **Three seated reasonings described the old rule and have been corrected.** The chair does not
move: the cap still binds every unit first occupied on or before that date, while new construction
sets market rents, which is chair 3. But the mechanism was wrong, and `reasoning` is voter-facing.

▶ **Never describe what an ordinance changed from its plain text.** Use the RTF revision marks, or
the Word revision marks for a .docx attachment. This is the second time in this slice that a
formatting-stripped read produced a confident wrong answer; the first was Yang's A1.

# Kim's A2 amendment — real evidence that CANNOT BE CITED

Kim moved A2 to Ord 25-29. Its filed text keeps the twenty-year limit and makes the exemption
conditional on paying the prevailing wage rate, with recitals that prevailing wage helps workers
afford rent and improves the durability of the housing stock. It failed 3-4.

That is an affirmative position pointing at chair 2, not a direction. **It is still written as a
blank**, because the amendment exists only as a Word and PDF attachment and **no fetchable page names
both Kim and that amendment** — the meeting page carries the agenda grid and the designation, not the
amendment or her name.

🔴 **Saint Paul's amendment-level record is therefore effectively uncitable** under the evidence
contract: `verificationFetch` throws `not_html`, and nothing below a final ordinance vote reaches a
reportable page. Expect this to recur wherever a member's clearest position is an amendment rather
than a final vote.

---

# 🟢 The divided-vote scan — do this FIRST for the next city

Rather than hunt instruments topic by topic, scan the whole year's roll calls and keep only the ones
C46 can accept. For Saint Paul in 2026 (`divided-votes.mjs`):

| | |
|---|---|
| Council items scanned | **1,059** |
| Items carrying a recorded roll call | **918** |
| Divided by 10% or more (C46) | **8** |

**Eight.** Fewer than one per cent of recorded votes are positions under the programme's own rule.
That single number prices a city's record evidence better than any amount of topic searching, and it
explains why four of the slice's six seated-or-searched members have no record chair.

The eight, and what they are worth:

| Date | File | Tally | On a ladder? |
|---|---|---|---|
| 2026-08-05 | RES 26-1253 | 2-5 | tenant repair-and-deduct **ballot question** — a referral decision, names no rung |
| 2026-04-22 | RES 26-619 | 5-2 | urging European banks to divest from DHS contractors — no rung |
| 2026-05-13 / 05-27 | RES 26-791 | 4-3 / 6-1 | a mayoral **appointment** — personnel, not policy |
| 2026-08-26 | RES PH 26-175 | 0-7 | residential permit parking boundary |
| 2026-08-12 | RLH SAO 26-62 | 6-1 | a **single-property** abatement appeal |
| 2026-09-09 | RES 26-1502 / 26-1543 | 6-1 | honorary street **co-naming** |

▶ **None of the eight seats a chair.** They are appointments, single properties, street names, a
parking boundary and two referral decisions — the municipal equivalent of Charlotte's finding that
every divided policy vote failed as chair evidence, reached here by measurement rather than by
reading them one at a time.

⚠ **RES 26-1253 is recorded in Johnson's reasoning as a counter-fact.** She is seated at chair 2 on
rent regulation, and she voted against referring a tenant repair-and-deduct question to the ballot.
The two are not contradictory — a referral decision is not a position on the policy — but the
reviewer should see the whole record, not only the part that supports the chair.

---

# ✅ CORRECTED 2026-10-05 (LATER) — DULUTH'S ORDINANCE TEXT **IS** CITABLE, AND THE SECTION BELOW SAYS OTHERWISE

The finding below is **wrong in its conclusion and right in every measurement it took**. Keep both.

`duluth-mn.legistar.com/LegislationDetail.aspx?ID=…&GUID=…` serves **116,377 bytes** of readable
text — sponsor list, full title and the complete operative body — to `curl` **and to node's
`fetch`**, which is what the verifier uses. A snippet cut from it verifies. Measured on 26-0100R:

| Route | Result |
|---|---|
| `?ID=7864734` alone | 200, **19 bytes** |
| `?ID=7864734&GUID=B105F04C-45ED-4AC9-B451-9E69CD2774D2` | 200, **116,377 bytes**, full body |
| `?ID=7864734&GUID=<the API's MatterGuid>` | 200, **19 bytes** |
| `?GUID=…` alone, or a mismatched pair | 200, **19 bytes** |

🔴 **THE WEB GUID IS NOT THE API'S `MatterGuid`. THEY ARE DIFFERENT IDENTIFIERS.** For 26-0100R
the API returns `8AAC66AD-3744-4503-8EDB-B05D98622FCE` and the page wants
`B105F04C-45ED-4AC9-B451-9E69CD2774D2`. That is why the probe below got 19 bytes **with "the
correct GUID taken from `MatterGuid`"** and concluded no page could be cited. The page exists; the
URL simply cannot be constructed from the Web API.

## 🟢 THE SCRIPTED ROUTE EXISTS — ONE KNOWN PAIR BOOTSTRAPS ALL THE OTHERS

`Calendar.aspx` does not expose the pairs, which is what made this look impossible. **Any single
matter page does.** A `LegislationDetail` page lists, under History, a `MeetingDetail` link for every
meeting the matter reached, carrying its own ID+GUID; a `MeetingDetail` page then lists every matter
on that agenda as a `LegislationDetail` link carrying ITS ID+GUID. So:

```
26-0100R  (pair taken from a MinnPost hyperlink)
  └─ MeetingDetail 1381311 / 75A5A26D-6D66-405A-B879-2F25492EF387   (council, 2026-02-23)
       └─ 26-005-O = ID 7869631 / GUID B9A84056-7F2A-4E7A-ADD4-B55A575AF296
```

▶ **Seed from any news story that links a Legistar matter, then walk meetings → agendas.** Every
Duluth instrument that reached a meeting is reachable this way, and the same shape should hold for
Saint Paul and every other Legistar client.

✅ **`26-005-O` IS SETTLED.** Stewardship of City Resources, sole author Councilor Randorf, adopted
2026-02-23, pair above. Randorf holds `local-immigration` **3** on it. Its codified text excludes
chair 1 more sharply than the resolution does: § 2-196(d) bars employees from sharing private or
nonpublic data with federal immigration authorities **and then exempts data subject to 8 U.S.C.
§§ 1373 and 1644** — the provisions governing citizenship and immigration status information. The
ordinance restricts data sharing in general and carves out exactly the category chair 1 names.

🔴 **CUT LEGISTAR SNIPPETS WITH THEIR ORIGINAL CASE.** The first batch of them was sliced out of
`normalizeText(page)`, which lowercases. Two costs: the published citation reads as lowercase
ordinance text, and `stanceGate`'s instrument patterns are **case-sensitive** — `/Chapter\s?\d+/`
has no `i` flag — so a reasoning naming "Chapter 2" fails `instrument-not-cited` against a snippet
that says "chapter 2". `scripts/stance-news/_legistar_text.mjs` returns a case-preserving twin of the
normalized page and asserts the two align before any slice is taken.

⚠ **`checkNameProximity` can miss by a single character.** On 26-005-O the file number sits at offset
246 and "Randorf" spans 740–746, so the window `slice(0, 746)` cuts the final letter and the header
snippet reads `name_not_present`; starting at 247 verifies and would begin mid-number. That row
therefore carries two snippets off the one page — the header for the file number, the body for the
operative text and the verification. Both are cut from the page; neither is composed.

⚠ The "do not quote the ordinance text in reasoning" rule below is **withdrawn for any matter whose
web GUID you have**, and still stands for any matter where you have only the API.

---

# ❌ SUPERSEDED — DULUTH'S ENACTED ORDINANCE TEXT IS READABLE BUT NOT CITABLE (2026-10-05)

The Legistar **Web API** serves the full text — `/matters/{id}/versions` gives a version key, and
`/matters/{id}/texts/{key}` returns `MatterTextPlain` and `MatterTextRtf`. That is how the camping
ordinance's enforcement conditions were read. But **no HTML page carrying that text can be cited**:

| Route | Result |
|---|---|
| `duluth-mn.legistar.com/LegislationDetail.aspx?ID=…&GUID=…` | **HTTP 200, 19 bytes** — with the correct GUID taken from `MatterGuid` |
| `library.municode.com/mn/duluth/codes/code_of_ordinances` | HTTP 200, **6 KB shell**, rendered client-side |
| `/matters/{id}/texts/{key}` | JSON, not an HTML page |
| `duluthmn.gov/…/city-code/` | 302 |

🔴 **A 200 carrying 19 bytes is the soft-404 trap, and it survived the obvious fix.** The first probe
used a placeholder GUID and the 19-byte body looked like the explanation; supplying the real GUID
returned the same 19 bytes. ▶ **Judge a fetch by its SIZE as well as its status** — the memory rule
about a clean 200 lying in five ways, met in the wild.

**Consequence for the rows.** An ordinance's operative conditions can be *read* and used to decide
which chair fits, but the citation must be the reporting. For the camping ordinance the News Tribune
carries the two facts that matter: the mayor proposed a misdemeanor *"unless other housing is
available for them"*, and councilors *"balked at the prospect of charging homeless people with
misdemeanors for the crime of potentially having no other suitable place to go, amending the
ordinance to recommend no more than a $200 fine."*

⚠ **Do not quote the ordinance text in `reasoning`.** A quoted sentence must appear in a cited
snippet, and no citable page carries it. Describe the instrument and cite what was reported.

---

# THE MAYOR LEAVES ALMOST NO RECORD IN LEGISTAR (2026-10-05)

A mayor casts no votes, so `member_votes.mjs` finds nothing for one and the divided-vote census is
silent about the executive. The mayor's recorded act is the **signature** — signing, vetoing, or
letting an ordinance pass unsigned — and that appears only in an event item's action text.

`mayor_actions.mjs duluth-mn 2024-01-04 138` over **1,914 items in 76 meetings** returns exactly
**one** match:

> 2025-07-01 · `25-016-O` · *"The Ordinance passed 6-2 **This Ordinance passes without Mayoral
> signature.**"* — the council's own tenant ordinance (landlord training, tenant notification,
> repairs within 14 days).

🟢 **The near-zero is a real finding, not a broken detector**, because the pattern fired once: Reinert
has **vetoed nothing** in the window and has let exactly one ordinance pass unsigned.

⚠ **Not signing has two readings** — disapproval, or simply letting a measure take effect — and no
reporting in the corpus says which. It is a lead, never a chair. Do not seat the mayor from it, and
note that `rent-regulation` would be the wrong ladder for it in any case, because that ordinance is
about habitability rather than rent.

▶ **So a mayor is researched almost entirely from proposals and statements.** Reinert's are abundant:
he proposed the 2024 public safety package, proposes the budget and levy each year, and speaks to both
papers regularly.
