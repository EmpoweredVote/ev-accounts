# Pre-tenure re-research — pipeline built, tranche 1 adjudicated

Re-researching the 36 stance rows migration 1537 retired for asserting votes cast before the member
held the office. **The pipeline is built and verified; the first adjudicated tranche says most of these
chairs cannot be restored from roll calls, and that is the correct answer rather than a failure.**

Artifacts (all under `data/stance-research/pretenure-reresearch/`):
`house-rollcall-index.json` (3,838 roll calls) · `pretenure-candidates.json` (694 candidates) ·
`rollcall-votes.json` (277 records, real votes) · `bill-adjudication.json` (277 bills, chairs blank).
Scripts: `_tmp-house-rollcall-index.mjs`, `_tmp-pretenure-triage.mjs`,
`_tmp-pretenure-fetch-votes.mjs`, `_tmp-pretenure-adjudication-sheet.mjs`.

## The pipeline

1. **Index harvest** — the Clerk's per-100 index pages for 2019–2026: **3,838 roll calls**, contiguous
   from roll 1 in every year, at ~56 requests instead of ~4,500 XML fetches.
2. **Triage against each member's REAL service window** — this filter *is* the repair. A roll call
   before a member was seated can never be their evidence, so it never enters the shortlist.
   694 candidates over 18 topics.
3. **Vote extraction, matched on `name-id` (bioguide), never surname.** The audit lost a day to the
   Clerk writing `Hoyle (OR)` when a surname is shared, which reported her absent from votes she is
   plainly in and nearly buried the pre-tenure finding as a parser artefact. Compound surnames
   (Kamlager-Dove, Van Epps) fail the same way.
4. **Bill-keyed adjudication sheet** — 694 candidates collapse to **277 bills**, judged once each and
   reused across members. 137 PASSAGE / 69 OTHER / 71 PROCEDURAL.

**Verification that the extraction is sound:** appearance counts track service length monotonically —
277 for Pressley/Reschenthaler/Neguse (2019–), 256 for Bentz (2021–), 223 for the six 2023 members, 44
for Van Epps (Dec 2025–). Chamber totals 427–435 across all 277 records, none outside 380–445.

⚠ **A wrong identifier cost a full re-fetch, and it was mine.** I supplied Cliff Bentz's bioguide as
`B001294` from memory; it is **B000668**. He appeared in 0 of 277 rolls until it was fixed — caught only
because the script prints per-member appearance counts. Same failure shape as the `clark.house.gov`
control: **identifiers must be derived from the authoritative dataset, never recalled.** All 12 are now
verified programmatically against congress-legislators.

## 🔴 Tranche 1: the adjudications, and why they mostly yield BLANK

### Same-Sex Marriage — 4 rows, DISCARD both bills, blank spoke correct

Hoyle, Salinas, Landsman, Collins. Only 2 roll calls shortlisted, and both are the **same bill**:
**H.Res.994**, a *rule* providing for consideration of the "SALT **Marriage** Penalty Elimination Act"
(a tax bill on the SALT deduction for married couples). The keyword matched a word, not a topic. Roll 47
is additionally `On Ordering the Previous Question`, where direction does not map onto support.

**Neither bill is chair-shaped for this topic → discarded.** The Respect for Marriage Act passed
2022-12-08, before all four were seated, and there has been no same-sex-marriage floor vote since.
✅ **Blank spoke is the correct outcome for all four.** ⚠ This includes Mike Collins, whose retired row
claimed he "Voted FOR the Respect for Marriage Act … breaking with most conservative Republicans" — the
highest-harm row in the whole workstream. There is no real substitute vote, so it stays blank.

### Climate Change / Fossil Fuel Policy — 5 rows, evidence is OPPOSITIONAL → SKIP

Hoyle, Salinas, Menendez (Climate); Hoyle, Salinas (Fossil Fuel). 14 passage-class bills, and the votes
are real, consistent and verified:

| bill | what it does | Hoyle / Salinas / Menendez |
|---|---|---|
| H.R. 1023 | repeal the Clean Air Act §134 greenhouse gas reduction fund | No / No / No |
| H.J.Res 35, 61, 75, 136, 131 · S.J.Res 11, 31, 80 | CRA disapproval of EPA / BLM / DOE rules | Nay throughout |
| H.R. 3015 | National Coal Council Reestablishment Act | Nay / Nay / Nay |
| H.R. 3668 | streamline pipeline permitting review | Nay / Nay / Nay |

🔴 **But this evidence cannot pin a chair, and the scale is why.** Climate chair 2 is "rapidly transition
to renewable energy and phase out fossil fuels by 2030" and chair 3 is "invest in clean energy while
gradually reducing reliance on fossil fuels". Voting to *defend existing regulation* rules out chairs 4
and 5 — it does not distinguish 2 from 3. Fossil Fuel is worse: chairs 1, 2 and 3 are all consistent with
opposing deregulation.

The standing rule in `gen-topic-scale.mjs` is explicit: *"The value you assign MUST be the chair whose
text the evidence supports … If two adjacent chairs both fit, SKIP the topic."* And the WI triage rule:
*"An oppositional No vote rules out the far end and nothing more."*

✅ **So these 5 rows stay blank pending AFFIRMATIVE evidence** — a vote for a clean-energy mandate, a
co-sponsorship, a positional statement. The retired chairs were 1.0/1.0/2.0; none is established here.

🔴 **This generalises, and it is the main finding of tranche 1.** Roll calls in a deregulatory Congress
are overwhelmingly **defensive**. A 5-point scale whose lower chairs demand affirmative commitments
("ban", "phase out by 2030", "immediately ban") cannot be reached by No votes against repeal. **Roll
calls alone will not restore most of these 36 chairs.** That is the project's blank-spoke rule working
as designed, not a shortfall of the pipeline.

## Already resolved as correctly blank, before adjudication

Three pairs produced **zero** keyword candidates inside their real service windows:
**Val Hoyle / Campaign Finance Reform**, **Val Hoyle / State Redistricting and Gerrymandering**,
**Matt Van Epps / Immigration and Treatment of Immigrants**. Hoyle's two both rested on the 2021 For the
People Act vote she could not have cast, and no equivalent vote has occurred in her term. Blank.

## What is owed

1. **Adjudicate the remaining ~261 bills**, heaviest first: Taxation and Public Spending is 5 members and
   ~53 passage votes each (Pressley, Reschenthaler, Neguse, Bentz, Hoyle, Salinas, Van Epps).
2. 🔴 **Cindy Hyde-Smith is SENATE and the House index cannot serve her.** Her one row (Taxation) needs
   `senate.gov/legislative/LIS/roll_call_lists/` — unbuilt.
3. **Expect affirmative evidence to come from outside roll calls** for most topics: co-sponsorships
   (congress.gov), committee action, and members' own issue pages. ⚠ Per 1508's rule, re-research must
   not return to the sources that failed — but for this cohort the *sources* were often fine and the
   *attribution* was wrong, so `clerk.house.gov` remains valid; it is the membership check that was
   missing.
4. **Nothing is written to production.** No migration, no stance rows. Every chair in
   `bill-adjudication.json` is still blank.
