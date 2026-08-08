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

- **Allison Leary / Residential Zoning.** The richest of the nine. She is running for state
  representative, so the Beacon covers her housing views directly: she "wants to build on" the
  Healey housing law that "undid certain zoning regulations in communities statewide", "supports both
  pieces of legislation and said the state should actually intervene more to advance housing
  development", with the counterweight *"I think we have to have some local control of where duplexes
  should be in a single-family zone, where some neighborhoods' characters could really change."* Plus
  her MU4 quote in Fig City: the development *"fits the bill for MU4"* because it is not displacing
  residents and MU4 "would always need to come before the City Council for a vote."
  ⚠ Chair 3 vs 4 is a real decision — she wants MORE state intervention but local control over
  duplex placement. Read the full state-rep profile before choosing.
- **Randy Block / Residential Zoning.** Consistent restraint-and-study posture: opposed the 148
  California rezoning "warning it could open the door to additional residential development"; *"a
  zoning change to business use needs a much more thorough analysis by the Planning Department"*;
  wanted "more data and comprehensive studies done before the city starts rezoning manufacturing
  parcels"; opposed 60 Brookside Avenue (four attached dwellings); "would be happy to see demolition
  delays of up to two years"; wants the city "more aggressive in landmarking". He was with
  **RightSize Newton** before election. Chair 1 or 2 — note chair 1 needs community votes before any
  rezoning, which he never proposes, so probably 2.
- **Maria S. Greenberg / Residential Zoning.** *"One size doesn't fit all if you have unique
  neighborhoods with different needs"*; supported the Mula zoning changes and the MU4 rezoning.
  ⚠ Her stated reasons are consistently **commercial** (tax base, foot traffic, attracting
  industries). Chairing her on residential density from a commercial rationale risks the
  Malakie/Newton-Crossing error refused in block 2. Usable only if the reasoning stays on the
  "one size doesn't fit all" passage.

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
