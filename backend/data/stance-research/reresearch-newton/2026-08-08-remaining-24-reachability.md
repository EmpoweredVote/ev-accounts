# Newton — reachability of the remaining 24 rows (2026-08-08)

Read-only assessment. **Nothing written, no migration.** Follows migs 1615/1616 (block 1) and 1617
(block 2), which together closed 9 of the 48 owed rows.

The 24 are **9 politicians** with no candidate interview and no committee quote found in block 2:

| politician | rows | topics owed |
|---|---|---|
| Becky Grossman | 6 | Climate, Environment vs Development, Growth Pace, Public Safety, Residential Zoning, Transportation |
| Allison Leary | 3 | Affordable Housing, Public Safety, Residential Zoning |
| Andrea Kelley | 3 | Affordable Housing, Public Safety, Residential Zoning |
| David Micley | 2 | Affordable Housing, Residential Zoning |
| Maria S. Greenberg | 2 | Affordable Housing, Residential Zoning |
| Martha Bixby | 2 | Affordable Housing, Residential Zoning |
| Randy Block | 2 | Affordable Housing, Residential Zoning |
| Stephen Farrell | 2 | Affordable Housing, Residential Zoning |
| Tarik Lucas | 2 | Affordable Housing, Residential Zoning |

---

## ✅ THE EVIDENCE BASE DOUBLED — Newton Beacon is real and was never mined

`www.newtonbeacon.org` (the apex fails DNS; **only the `www.` form resolves**) is a second live Newton
outlet with a full WordPress category tree: `cityhall`, `housing-and-real-estate`,
`climate-and-environment`, `public-safety`, `roads-and-infrastructure`, `politics`.
**563 articles harvested.** It out-performed Fig City News for these nine — 39 candidate sentences to
24 — and for Leary it was the difference between 1 hit and 13.

Corpora used for this assessment: **493 Fig City News articles + 563 Newton Beacon articles.**

⚠ Beacon article URLs are **flat slugs** (`/some-headline-here/`), not `/YYYY/MM/slug/` like Fig City.

---

## 🔴 Two detector failures, recorded so they are not repeated

**1. Raw article counts are worthless — both sites leak sidebars into every page.**
`grep -l Leary` matches **493 of 493** Fig City articles, because the op-ed
*"Mirfendereski: The Lawn/Leary kerfuffle"* sits in the Op-Eds sidebar of every page. `Block` matches
174 Beacon articles for the same reason plus "block grant" and "Block Party". **Only sentence-level
matching, filtered to a stance verb or a quotation mark, means anything.**

**2. A "named vote" is overwhelmingly a RECUSAL, not a dissent.** The first cut ranked Micley top with
11 vote-named hits; **all 11 are "Councilor Micley not voting"**. Leary 3 of 4, Kelley 3 of 5,
Greenberg 3 of 3, Bixby 1 of 2 likewise. A recusal is not a position — the same rule that refused
Wright's police-wage recusal in 1617. Filter `not voting|did not vote|recus` before counting.

⚠ The topic-keyword filter also **under**-fires: Farrell's one real named dissent ("said he believed
the ordinance remained too restrictive") contains no zoning vocabulary and was dropped. Every
candidate sentence below was read by eye, not trusted from a count.

---

## The verdict — 3 good, 5 to check, 16 with nothing

### ✅ Good prospect (3 rows) — converging, first-person, on-topic

> 🔴 **WORKED 2026-08-08, mig 1618: 1 of these 3 survived the full read.** The verdicts below are
> superseded by the ⛔ notes. Left in place as the record of what an extract-level pass claimed.

- **Allison Leary / Residential Zoning.** ✅ **RESTORED at chair 4 (mig 1618).** She is running for
  state representative, so the Beacon covers her housing views directly.
  🔴 **ATTRIBUTION ERROR IN MY OWN TEXT — the counterweight quote below is NOT HERS.** *"I think we
  have to have some local control of where duplexes should be in a single-family zone, where some
  neighborhoods' characters could really change"* is **John LAWN**, her opponent; a sentence splitter
  glued his quote onto her next sentence. Same family as the scope doc's "Grossman interview" that was
  really an interview with Brian Golden. Her actual position is *less* hedged: multifamily by-right so
  projects "don't have to go through the Land Use Committee", "even more density" in village centres,
  statewide duplexes, and "if they're not doing it, I think the state needs to step in."
- **Randy Block / Residential Zoning.** ⛔ **NOT RESTORED (mig 1618).** The restraint-and-study
  reading does not hold: **his stated rationale is the commercial tax base**, in his own words —
  rezoning "opens up the possibility, even the likelihood, of residential development instead of
  commercial development … given our concern to protect our commercial tax base" — and his
  preservation motive is explicitly historical ("That's the historian in me talking"). Two facts cut
  the other way: he **opposed the amendment to add parking requirements**, and his 60 Brookside
  dissent carries **no stated reason at all**. ⚠ "He was with RightSize Newton" is a third party's
  description of a past affiliation and what that group stands for is not on the page — unusable.
- **Maria S. Greenberg / Residential Zoning.** ⛔ **NOT RESTORED (mig 1618).** 🔴 The *"One size
  doesn't fit all"* quote this rested on is from a **WINTER PARKING BAN** debate — she was asking for
  per-neighbourhood parking-pattern data, not talking about zoning. The caveat below was right and
  it fired: her genuine zoning remarks are reasoned entirely on commerce.

### ⚠ Worth one read each, may well fail (5 rows)

- **Greenberg / Affordable Housing** — "noted that one of the major long-term issues facing Newton is
  the lack of affordable housing." Naming a problem is not a position on government's role.
- **Kelley / Residential Zoning** — she has two named, reasoned items that point **opposite ways**:
  opposed an FAR increase over the dormer's appearance (7-1), yet warned the facade ordinance's
  special-permit override "could create an unnecessary burden for property owners". Does not converge.
- **Lucas / Affordable Housing** — on the 100%-affordable Washington Street development he called it
  "promising" and hoped current tenants can remain in Newton. One sentence about one project.
- **Leary / Affordable Housing** — her housing material is all zoning-shaped; using it here would
  repeat the Roche error that mig 1616 reversed. Check the state-rep coverage for a separate passage.
- **Grossman / Transportation** — her only on-topic remark: *"we had regular transit that was stopping
  all the time and reliable, that would be amazing for the growth of business."* Hedged, and framed as
  business growth rather than investment priority.

### ❌ Nothing found (16 rows)

Grossman ×5 (Climate, Environment vs Development, Growth Pace, Public Safety, Residential Zoning) ·
Micley ×2 · Bixby ×2 · Farrell ×2 · Lucas / Residential Zoning · Block / Affordable Housing ·
Kelley / Affordable Housing · Kelley / Public Safety · Leary / Public Safety.

🔑 **The precise finding is not "no coverage" — it is "covered, but never on the topic they owe."**
All four of the apparently-empty councilors are quoted repeatedly across the 1,056 articles:
Micley on climate and civic connection, Bixby on school budgets and turf blades, Farrell on tobacco
policy and overrides ("legislate morality"), Grossman on budgets and a future override ("For me, it's
a values statement"). They simply never speak to housing affordability or residential density.
**More searching will not help these rows.** That is a stronger and more useful conclusion than a
thin-corpus verdict would have been.

🔑 **Affordable Housing is structurally near-unreachable for this cohort — 1 of 9 has anything.**
Newton's affordability debate happened in essentially **one** meeting, the Zoning & Planning
Committee's April 2025 review of the Inclusionary Zoning Ordinance, and **block 2 already mined every
councilor who spoke there** (Malakie, Wright, Kalis, and Baker). The remaining Affordable Housing rows
are not blocked by missing sources; the distinguishing debate simply did not include these people.

---

## Planning number

**3 rows have converging evidence; 5 more have a source to CHECK.** Expect **3-5 of 24**, not 8 —
"a source exists" is not "the source answers the question", the correction that block 1 already
forced once. Blocks 1+2 ran 9 of 24 attempted (under 40%) and those were the best-sourced people in
the cluster; this cohort is the residue.

Realistic end state for Newton: **12 live rows today, plausibly 15-17 when this cohort is worked,
against 48 owed.** The remaining ~31 are not recoverable from public sources.

---

## 🔴 OUTCOME 2026-08-08 (mig 1618) — the "3 good" were 1

**Even this document over-fired.** Reading the three source articles end to end, only Leary survived.
Both failures share one shape, and it is the shape to test for next time:

🔑 **A sentence can be on-topic by VOCABULARY and off-topic by RATIONALE.** Block and Greenberg both
talk fluently about rezoning; both reason from the **commercial tax base**. Neither states a position
on housing density or neighbourhood character, which is what the topic actually asks. Sentence-level
extraction cannot see this — only the full passage shows why someone holds the position.
**Extract to build the queue; never to assign the chair.**

🔑 **Check the ARTICLE the quote lives in, not just the quote.** Greenberg's decisive line came from a
winter-parking-ban debate. The topic-keyword filter matched it; the article's subject would have
excluded it instantly.

Revised planning number for the remaining rows: of the **5 "worth one read"**, expect **0-2**. The
honest expectation for Newton is now **13 live rows, plausibly 13-15 of 48 owed.**
