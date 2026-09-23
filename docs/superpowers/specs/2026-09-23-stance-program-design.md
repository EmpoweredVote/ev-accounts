# The Compass Stance Program — method, standard, and what it cost to learn

**Status:** proposed, 2026-09-23. Written for Essentials sign-off, then for Chris Andrews and his
Claude to adopt.
**Author:** Chris Cantrell's session, from the accumulated record of every stance wave to date.
**Scope:** how we find, judge, source, verify and publish a compass stance; how we build a ladder
when none fits; and what we propose Season 3 should change.
**Out of scope:** the quote curation rulebook, which lives in the `on-the-record` corpus and is
referenced in §9, not restated.

> **Every number in this document is dated, and the ones marked "measured 2026-09-23" were read from
> production while writing it.** Four defects this document was originally going to report had
> already been fixed in the Season 2/3 pins; they are in §12.1 as *closed*, not as open work. That is
> not tidiness. A stale caveat does not merely age — **it misattributes the failure, so it sends the
> next reader at the wrong fix.** Re-test before you plan around anything here.

---

## 0. Who this is for, and what it will and will not do

This document transfers the **standard** and the **reasoning behind it**. It will not, by itself,
make a new researcher produce rows at our bar. We have the number that proves it.

On the North Carolina pilot (2026-08-24) three `politician-stance-researcher` agents returned **38
rows**. Fourteen looked evidenced. **Eight survived someone reading the bills.** The agents were not
sloppy — they cited real bills and quoted real operative text. The defect is that the bar is a
judgment made invisibly, and it surfaces only in review.

So the transfer has three parts, and this document is one of them:

| | What it is | Where it lives |
|---|---|---|
| 1 | The standard and its rationale | **this document** |
| 2 | Ten worked judgments, accept and refuse | **§10 of this document** |
| 3 | The runnable tooling and the two skills | the repo — see §14, and the warning in §13.1 |

A reviewer should expect the first wave from a new researcher to be **read before it is pushed**,
not after. §11 specifies that protocol. It is not a probation ritual; it is how we caught our own
failures, every time.

### 0.1 Handover prerequisites — three repo fixes this document depends on

These are not proposals. Each is a place where our shipped materials contradict this standard, so a
reader who follows them faithfully will reproduce a failure we have already paid for. They are ours to make, not the reader's.

**Status 2026-09-23: all three are done — H1 (#662), H3 (#664), H2 (#666).**

| # | Fix | Why |
|---|---|---|
| **H1** | ✅ **Done.** `research-stances/SKILL.md` STEP 1 said to dispatch one research **agent** per politician; it now executes inline, one politician per run. (The rewrite mode it also affected has since been deleted — §8.6.) | Withdrawn by ruling 2026-08-24, reaffirmed 2026-09-23. Following it as written turned 38 rows into 8 — §13.1 |
| **H2** | ✅ **Done.** `verify-quotes.mjs` is now `backend/scripts/verify-quotes.mjs`, wave-agnostic, and runnable as `npm run verify:quotes -- <wave-dir>`. | It is the only defence against WebFetch fabricating quotes, and it is currently findable only by accident — §4.11 |
| **H3** | ✅ **Done.** `research-stances/SKILL.md` STEP 0's topic-resolution query joined `inform.compass_stances` (the **frozen** table) and filtered `WHERE t.is_live = true`. It now resolves the open season's pin by status. | 41 of 61 Season 3 topics disagree with the frozen text, and 18 of them carry `is_live = false` while being perfectly live in the season. The first fails silently and plausibly. The second returns the 44 `is_live` topics — **dropping 18 of Season 3's 61, while including `immigration`, which Season 2 retired and which the write gate no longer accepts** — §2.2, §8.5 |

---

## 1. What a compass row claims

A compass row is a **public statement about a named living person, published under their name.**
The voter-facing surface is not just the dot on the radar: `inform.politician_context.reasoning`
renders on the candidate's Essentials profile and on the Compass under **"Why this position?"**
(`src/pages/Citations.jsx` in the **essentials** frontend repo — a sibling checkout, not this one).
Prose we write is prose a voter reads.

Three consequences follow, and they are the whole ethos.

**1.1 The bar is two independent things.** A stance needs **a chair the evidence names** *and*
**a source that supports it**. Either alone is a failure. A row can cite a real, live, correctly
attributed page and still be false, because nothing checked whether the page supports the claim.

**1.2 An empty compass is honest; a confabulated one is a false statement about a real person.**
This is the standing rule, and it has never once been wrong to apply. When in doubt, refuse the row.
A blank spoke is a correct answer. Expect — and accept — that a large fraction of a cohort seats
nothing: on the NC Assembly wave, **42 of 120 House members seated nothing at all**, and that was the
bar working, not a search failure.

**1.3 Party is never evidence.** Empowered Vote is antipartisan by design. Inferring a chair from a
party label is the single failure that has cost us the most rows, and it does not look like laziness
when it happens — see §5.4.

**1.4 One evidence bar for everyone.** Independents and minor-party candidates qualify for the ballot
later than party nominees, through signature verification rather than a primary. If we passively
accept that asymmetry, the electoral system's structural disadvantage becomes *our editorial bias*.
The rule (ruled 2026-07-10): one bar — verified ballot qualification — and when an independent is
unverified the default action is a **verification pass**, never a hold. Ballotpedia listing alone is
not qualification, and an FEC statement of candidacy is not ballot access.

**1.5 Research the whole field, before the primary.** Do not treat a pre-primary field as work that
gets culled. In the operator's words (2026-07-10): *"You see it as discarded after Aug/Sep, and I see
it as us being able to help people in KS MN NH and AK make a discerning decision between their
options in Aug/Sep. We serve the citizens."* Primary voters are voters, and our value is highest
exactly where the field is large and confusing. In **ranked-choice jurisdictions this compounds** —
a ranking voter compares many candidates at once, so depth is worth disproportionately more there.
Over-indulge thoroughness in RCV races; never trim minor candidates as low priority.

**1.6 A challenger's unsourced stance is higher-harm than an incumbent's.** A challenger has no
voting record to contradict a fabrication. And they are just as visible: a politician holding **no
office at all is still published** if they are an active candidate in a race whose election date has
not passed (§2.6).

---

## 2. The model — where a row actually lives

Getting this wrong produces silent failures, which is why it comes before the method.

🔴🔴 **The MCP server named `supabase-local` is production.** There is no local
database in this program. Every measurement in this document, and every query you run to check
one, hits the live database that serves voters. Reads are free; anything that writes goes
through a numbered migration under the guards in §7.

### 2.1 A seat holds no occupant

`essentials.offices` is a **seat** — district, chamber, title. `offices.politician_id` was dropped
(ADR 0002, migration 1463). Occupancy is a dated row in `essentials.office_terms`, resolved at read
time through `essentials.office_current_holder`. Joining that view **from a politician can fan out**,
because a person can hold two seats; joining it from an office cannot. Full rules are in `CLAUDE.md`
— read that section before seeding anyone.

For stance work the operative consequence is narrower: **resolve a politician's identity through the
seat, not by name.** `push-nc-stances.mjs` joins on id *and* name so that a wrong id drops the row
rather than seating the wrong person.

### 2.2 Topics are versioned; the content is not in the table you think

A topic's identity is `inform.compass_topics`. Its **content** — title, question, and the five rung
texts — lives in `inform.compass_topic_revisions` and `inform.compass_stance_revisions` (ADR 0004).

🔴🔴 **The legacy `inform.compass_stances` table is frozen at v1** and has not been maintained since
`CA_0012`. **Measured 2026-09-23: 41 of the 61 Season 3 topics have pinned rung text that differs
from the frozen table.** It was 29 of 60 on 2026-09-08. The divergence is growing.

This fails silently and it is the single most dangerous read in the program: the frozen table returns
a **complete, plausible ladder on the right subject with the wrong rungs**. It has already caused a
researcher to believe five correctly-seated `housing` rows were mis-seated. Voter read paths are
fine; this bites *research* queries.

**Always read a ladder through the season pin:**

```sql
season_questions  →  compass_stance_revisions  ON topic_revision_id
```

and read each existing context row's ladder from **its own** `topic_revision_id` — a row must be
judged against the ladder it was actually written against. `scripts/check-ladder-text-reads.mjs`
enforces this for committed code.

### 2.3 Seasons

A season is the set of questions asked, of whom, right now (ADR 0005). At most one season is open.
`inform.politician_answers` carries a `season_id` and a `topic_revision_id`, both `NOT NULL`, and a
foreign key requires the pair to match the open season's question set.

**Measured 2026-09-23:**

| Season | Status | Topics | Answers | Blanks (`value = 0`) |
|---|---|---|---|---|
| 1 | closed 2026-09-04 | 44 | 33,022 | 0 |
| 2 | **open** | 60 | 3,381 | 127 |
| 3 | **draft** | 61 | 17 | 0 |

Season 2 **added 17** topics over Season 1 — `2020-election`, `border-security`, `cannabis-policy`,
`defense-spending`, `gun-policy`, `israel-military-aid`, `military-intervention`, `minimum-wage`,
`ranked-choice-voting`, and an eight-way `education-*` split — and **retired exactly one**:
`immigration`. Season 3 adds one more: `surveillance-technology`.

Reads follow the person, not the calendar. A politician researched in Season 1 and not since still
shows their Season 1 stances.

🔴 **Do not hand-roll the write.** Import `UPSERT_ANSWER_SQL`, `UPSERT_CONTEXT_SQL` and
`assertWritten` from `backend/src/lib/seasonService.ts`. They resolve the open season and its pinned
revision **in the same statement**, so the season cannot close between the read and the write.
`assertWritten` is not optional: the upsert sources its `INSERT` from a join on the open season, so
if no season is open the select yields no rows, **nothing is written, and nothing raises.** A push
without the row-count check reports success having saved nothing.

⚠ The **149** `backend/scripts/apply-*-stances.ts` files (counted on `master`, 2026-09-23) are **not templates**. They carry a bare
`INSERT (politician_id, topic_id, value)` that predates the season model. They already ran, so they
are harmless where they sit; copying one gives you a form that fails, or worse, resolves against
scaffolding that is being removed.

### 2.4 A blank is `value = 0`, and every read must decide what that means

When a ladder moves so that no rung states what a person holds, the answer is **blanked**, not
guessed and not deleted. The row stays, carrying `value = 0`. (Ruling 2026-09-02: *"If there is
nowhere for them to go, they can be blanked. We will remember the difference between seasons 1 and
2."*)

The two right answers point opposite ways:

- **Anything that displays or averages a position must exclude it.** A 0 is not rung 0. Left in, it
  scores as maximum disagreement in `compareWithPoliticians` and opens a bar no ladder text can label.
- **Anything asking whether research happened must keep it.** Blanking says the ladder moved, not
  that the reading was undone.

A query that keeps blanks says so, in the same shape as `-- @season-scope:`:

```sql
-- @zero-scope: counts-blanks — coverage is "ever researched", and the research happened.
```

⚠ **Unlike `@season-scope`, this marker is not enforced by a gate.** `grep -rn "@zero-scope"
backend/src` finds every site that has been judged. A read with no marker has not necessarily been
thought about.

**Guard placement is the part that goes wrong.** Put the filter *outside* the newest-season collapse,
never inside it. Inside, a blank in the newest season is skipped and the query silently falls back to
an older season's rung — serving a position the person no longer holds, against a ladder it was never
an answer to. `compassService.test.ts` pins this.

### 2.5 Deleting an answer obliges a decision about its context

Removing an answer removes the chair. The reasoning that argued for that chair survives, still
asserting a position, attached to nothing. It is not published while the pair has no answer — but
write an answer for that pair later and `Citations.jsx` renders the old prose verbatim.

There are **two dispositions and they are opposites**:

| Situation | Disposition | What the counts do |
|---|---|---|
| Topic applies, the record was read, no rung fits | rewrite the context as a **documented blank** | answers fall, context holds |
| The claim is withdrawn, or the topic does not apply to this person | **delete the context too** | both fall, by the same amount |

Paste the guard from `backend/migrations/_templates/answer_delete_context_guard.sql` and state a
`-- @context-decision:` line. `npm run check:answer-delete-guards` enforces it.
⚠ A guard asserting the context *survived* is not this guard — migration 1735 had one, passed green,
and created 117 violations.

### 2.6 Visibility is not occupancy

`compassService.ts` publishes answers for **any non-incumbent `race_candidates` row with
`candidate_status = 'active'` in a race whose `election_date >= CURRENT_DATE`** — no office, no
occupancy required.

Measured 2026-07-31: of 443 backlog rows held by politicians with no current office, **422 were on a
live candidate card.** Only 21 were genuinely invisible. A written premise that "none hold office, so
Essentials never displays them" had ranked the largest cohort *last*; it was actually 71% of all live
unsourced rows, and published.

**Resolve visibility from the read path, never from occupancy.** And never bucket a CI baseline by
visibility — it churns on the calendar. Bucket by state, which is stable.

---

## 3. Finding a chair — the method

### 3.1 Five chairs, not a polarity rating

The operator's phrasing (2026-06-27) is **"chairs, not polarity."**

The five options are five **distinct, substantive positions** a real person could hold, defend, and
point at a policy for. They are not degree-of-agreement markers. When a voter matches a politician,
the system must be able to say *"you both support rapidly transitioning to renewable energy and
phasing out fossil fuels by 2030"* — not *"you both scored a 2 on Climate."*

- Evidence that establishes only the **direction** (pro/anti) under-determines *which* of the two or
  three chairs on that side applies. Seating anyway is an unevidenced claim expressed as a number.
- A bill citation proves direction. It does **not** automatically prove magnitude: "supports
  progressive taxation to fund public services" cannot distinguish *significantly raise taxes on the
  wealthy* (1) from *moderately raise* (2).
- ⚠ **"The least extreme option the reasoning supports" is a tiebreaker, not evidence.** Reaching for
  it is the signal that the row is not yet evidenced.

**Never assume polarity.** The corpus convention is chair 1 = maximum government action — but
`ai-regulation` and `tariffs` run the other way (re-confirmed against the Season 3 pin, 2026-09-23),
and `residential-zoning`, `growth-and-development` and `judicial-government-deference` are off-axis
entirely, where the deregulatory and the progressive position sit at the same end.

**Always embed the actual rung texts in whatever prompt or worksheet does the judging.** Given only a
`topic_key`, a model defaults to 1 = oppose / 5 = support and systematically inverts. That was fixed
three times by hand before it was fixed structurally.

### 3.2 Evidence **shape** predicts survival, not evidence **type**

This is the most useful single finding in the program. Measured on the WI Madison delegation wave
(2026-07-27), two passes, 41 rows produced, 15 dropped and 2 corrected on review.

Pass-1 survival by what pinned the chair:

| What pinned the chair | Survived |
|---|---|
| Authored bill | **67%** |
| Co-authored bill | 40% |
| Bare roll-call vote | **0%** |
| Statement or quote alone | **0%** |

That ordering suggests "votes are weak evidence" — **which is the wrong lesson**, and it is the
wrong lesson twice over, because a **0%** in a table is what a reader remembers. Recorded floor
votes were the single best evidence in the Texas SB 17 / HB 17 audit: they are dated, attributed,
and the journals parse. What the 0% measures is *bare* votes — a vote with no chair-shaped bill
under it. Pass 2 targeted votes deliberately and they came back at 50%, split perfectly:

- *Yes on SB23* — a specific Medicaid benefit extension. The bill **is** chair-shaped. Kept.
- *No on SS AB1* — a rebate deal the member disliked. Oppositional only. Dropped.

🔑 **A vote pins a chair only when the bill is itself chair-shaped** — when the bill *is* "impose a
moratorium until X", or *is* "ban this AI use in healthcare". A No vote on something objectionable
rules out the far end of the scale and nothing more.

Votes are simultaneously the **strongest** evidence on attribution (their name, their vote) and the
**weakest** on resolution.

Three traps sit on the attribution side, all of them from the Texas cohort:

- 🔴 **An excused absence is not a position.** A member who was not there did not decline to
  vote. This was nearly cited as evidence of opposition.
- 🔴 **Check tenure before you read a non-vote.** A blank in the tally for a member who had not
  yet been seated says nothing about them (§4.10).
- 🔑 **Verify your parse against the journal's own totals.** Journals are pypdf-parseable, and an
  18/10 tally scraped off one page turned out to belong to a different bill printed on the same
  page. The journal prints its own totals; if yours disagree, yours are wrong.

🔑 **Three properties, testable from the lead list, before you spend a fetch.** An instrument
can seat a chair only if it is *single-subject* (one topic, so the position it evidences is
unambiguous), *outcome-shaped* (it states an outcome, not a study, a report-back or a procedural
step — §4.13), and *divided* (a recorded split with at least 10% against — §4.12). Fail any one
and no amount of sourcing rescues the row, so find that out from the title and the tally rather
than from the PDF. This is the cheapest filter in the program, and it is why a body that
legislates by directive-and-report yields so little (§3.5).

The three failure modes are distinct and are caught differently:

- **Authored bills fail by over-reach.** Bill real, authorship real, claimed chair broader than the
  bill. An ADU-only bill scored as "upzone broadly to allow multifamily"; judicial public financing
  scored as "ban all private money". *Caught by reading the chair text against the bill's
  relating-clause.*
- **Bare votes fail by indeterminacy.** Not fixable by better sourcing — it is a property of the
  instrument.
- **Quotes fail by being rhetorical.** A verbatim, correctly attributed quote can pin nothing.
  *"Morally wrong… hateful and divisive"* is a sentiment, not a policy clause.

**Every clean keep had a bill establishing the chair. Votes and quotes are for corroboration.**

### 3.3 Work bill-first, not person-first

Pull an instrument's full sponsor list **once**, then read it across the whole roster. Measured on NC:
**batch 01 produced 8 rows from 25 source reads; batch 04 produced 26 rows from 4.** Same bar, same
people, six times the yield.

Keep a verified-instrument file — NC's is `chair-shaped-bills.json` — holding every verified bill with
its full sponsor list, the chair it establishes, and the conflicts that force a blank.

### 3.4 A cohort pass is mandatory

Per-person research is blind to peers. Twice on the Colorado Springs wave, and repeatedly on NC,
comparing rows side by side **changed an answer**:

- `growth-and-development` seated 2/3/3 plus three skips off near-identical language. The
  discriminator was that chair 3 is *investing ahead of growth* and chair 2 is *conditioning growth on
  existing capacity.* "Plan carefully and consider infrastructure" is what every Colorado Springs
  politician says, and separates nobody.
- `local-immigration`: a county Board Chair was seated a chair **above** the Sheriff on weaker
  evidence for the same lawsuit. Chair 5's verb is "**direct** local police" — a commissioner cannot
  direct an independently elected Sheriff.

**Adjudicate any ladder touched by several members of one body comparatively, before pushing.**

⚠ And watch the opposite failure: on Miami-Dade one commissioner holds 3 of the 12 seated rows and
has the densest record on nearly every ladder. She was refused on `city-sanitation` on exactly the
evidence shape that refused two colleagues. **Check that a marginal seat is not just familiarity.**

### 3.5 Yield — what to expect, so a thin result is not read as failure

| Wave | Result |
|---|---|
| NC Assembly | 187 rows / 120 House members = **1.6 per member**; 2.4 per member who seated anything; **42 of 120 seated nothing** |
| NC locals | 43 rows / 32 people = 1.3 per person; 2.0 per person who seated anything |
| Colorado Springs | 77 answers across 28 of 35 people; **7 documented honest zeros** |
| Miami-Dade | **eleven whole-Board passes have produced 3 rows** |

Councils are thinner per head than legislatures because **one instrument seats a whole body at once** —
three instruments carried Asheville's seven members, two carried Durham's seven, one carried
Buncombe's seven. The binding constraint is how many chair-shaped instruments the body voted on
inside the readable window, not evidence per person.

🔴 **Price the yield by the shape of the leads, not their count.** Of Miami-Dade's 1,785 matters,
**363 (20%) begin "DIRECTING THE COUNTY MAYOR…"**, 119 terminate in "PROVIDE A REPORT", and 68 urge
the Legislature or Congress. That Board legislates by directive-and-report, and **a study directive
is not a chair** — in either direction. Most of what a commissioner personally initiates cannot seat
one, however on-topic it looks.

---

## 4. The refusal rules

Each of these cost real rows. They are ordered roughly by how often they fire.

### 4.1 Direction-only evidence

The default failure. The source establishes pro or anti and nothing narrower. **Refuse.** If two
adjacent chairs both fit, the row pins neither.

### 4.2 Compound chairs need *every* clause evidenced

Before writing a 1 or a 5, **list the chair's clauses and point to evidence for each**. Examples that
have bitten: `campaign-finance` chair 1 requires "ban **all** private money"; `same-sex-marriage`
chair 1 (Season 3 pin) requires marriage equality **and** protection from discrimination in jobs and
housing — someone can hold one and not the other.

A clause can also be **unreachable at the office's level**, which retires the whole chair for that
cohort rather than the individual row.

### 4.3 Check every member against *every* instrument on the topic

An NC member is primary sponsor of both the data-centre moratorium (chair 1) **and** the bill making
data centres buy their own power (chair 2) — two adjacent chairs, both his own bills. **The spoke is
blank.** Finding one bill is not finding the answer.

### 4.4 Sponsorship evidences the bill **as filed**

🔴🔴 A bill's *current* title can belong to the **other chamber's committee substitute**. All four NC
bills parked in that campaign were Senate gut-and-replace: the text was swapped wholesale in
committee and **the sponsor list never changes**. H565 went from organ-donation tax checkoff to **AI
in healthcare billing**; it would have been the campaign's only `ai-regulation` row, for four members
who never filed it. Refused.

Read the **PDF editions on the bill-lookup page**, which show each version as filed. The session HTML
omits editions entirely, so it cannot show you the swap happened.

⚠ A re-sourcing pass citing sponsorship must also **refuse any row at the anti pole** — the new
citation would contradict the displayed position.

### 4.5 A short title is not evidence

**Five of the bills read in one ten-member NC batch contradicted their own titles.** *Beyond The
Choice Act* is veterans' tuition. *Expedited Removal of Unauthorized Persons* amends the **trespass**
statutes. *Energy Security Act* is substation physical security. *Save the American Dream Act* is a
development-deregulation omnibus.

Cross-check by **sponsor list**: if the text page's sponsors match the lookup page's, the text is the
right bill and the title is branding. If unresolvable, blank it.

### 4.6 The instrument can be about a different topic entirely

🔴🔴 This class was formalised on 2026-09-20 and is the newest one. Migration 1882 re-filed **82 Maine
rows** that had been graded on the Transportation ladder and written into Residential Zoning — found
by accident. Then the Texas immigration cohort turned out to seat `deportation` chairs 4 and 5 on
**SB 17** (foreign nationals buying real *property*) and **SB 16** (proof of citizenship to *register
to vote*). Neither is a removal instrument. **Nothing in the repo asked that question.**

`backend/scripts/instrument-topic-affinity.mjs` now does, from both directions: the corpus is its own
dictionary, scoring each cited bill's pooled descriptions against every topic's rung text, and
separately flagging bills whose descriptions **disagree with each other**. That is how one bill was
caught being described as "property restrictions" 29 times and "ICE enforcement" 12 times.
⚠ It is a **reading queue, not a verdict**. Adjacent topics legitimately share vocabulary.

Related and equally seductive: **mapping an enforcement-cooperation instrument onto a ladder that
asks something else.** Dropped twice in Colorado Springs — a "not a sanctuary city" resolution (about
municipal *spending*) onto `local-immigration` (about *ICE detainers*), and a police-reporting-to-ICE
bill onto `deportation` (which asks *who should be deported*).

### 4.7 Test the axis before starting a topic

🔴🔴 **Three of four Miami-Dade passes found the lead pattern asking a different question from the
ladder.** `local-environment`'s pattern asked about the health of Biscayne Bay; the ladder asks how to
regulate development. 32 of 43 leads were bay water quality, resilience and board appointments — and
the pattern was simultaneously blind to the ordinances that are the real instruments.
**Direction is rarely the problem. The axis is.**

Method: read the five rungs, write down **the one question they all answer**, then read twenty lead
titles before spending anything.

🔴 **The same instrument can be procedural for one ladder and on-axis for another** — tag both, judge
separately. A Rapid Transit Zone subzone ordinance is parcel-level zoning (on-axis for
`residential-zoning`), not transport investment; it was the largest false-positive class on
transportation and removed three commissioners who looked seatable from lead counts alone.

### 4.8 A lead count is not evidence until the pattern is measured

"jail-capacity: 13 hits, thin" turned out to be **44 hits / 20 usable** once the search was fixed.
**A low count is as often a broken query as a real absence.**

🔴 **Substring and proper-noun traps, measured:** `bail` matches **BAIL**EY; `vice` matches
ser**VICE**s; `carbon` matches **CARBON**ATE. **A word boundary does not save you from a proper
noun** — `\bbail\b` still hits a person called Bailey. Read a sample of hits before trusting a count
in either direction. Maryland had the same class: *"App-**rent**-iceships in Licensed Occupations
Act"* ranked as a member's best housing evidence.

🔴 **A leads file cannot tell you what a pattern missed** — it stores only what matched. To ask "does
an on-axis instrument exist at all?", re-fetch the **unfiltered** corpus and grep raw titles, with a
positive control in the scan.

### 4.9 A ladder can be legally unavailable at a level

🔴🔴 **The failure mode is a confident wrong row, not a blank spoke.**

**Fla. Stat. 125.0103(2)** forbids any Florida county from imposing rent control. So on
`rent-regulation`, rungs 1–2 are unlawful, rungs 3–4 describe the preempted baseline, and **rung 5 —
"oppose rent control entirely" — is an accurate description of state law and of nobody's position.**
Work backwards from the outcome and you seat all thirteen commissioners at 5, recording a preemption
as thirteen personal beliefs. North Carolina preempts it too.

⚠ The ladder is valid elsewhere. The defect is **jurisdictional**, and `compass_topic_roles` has no
per-state dimension, so it can only be written down. **Before starting a topic, ask whether the rungs
are things this officeholder may lawfully do.**

🔴 **A scope blank is closed research — never re-queue it.** This is a register, not a Florida
curiosity: `rent-regulation`, `taxes`, `gun-policy` and the eight-way `education-*` split all have
rungs no officeholder at some level holds a lever on. Record the jurisdictional finding once, with
the level it applies to, and treat those people as researched. A later pass that reads them as
"unsourced" and re-queues them spends a whole wave re-deriving a refusal we already made.

### 4.10 Pre-seating — a genuine URL is not a genuine vote

7 of 8 bill-cited rows in one Oregon cohort attributed votes cast **before the member was seated**.
One member's 2021 "term start" was in fact their **city council** term, not the legislature. A row
citing a real bill page looks well-sourced while being fabricated.

🔴 **`essentials.office_terms.term_start` cannot adjudicate this below the federal level.** It is
nullable *by policy* under ADR 0002, with a `start_precision` column so imprecision is recorded
rather than invented — a NULL there is a deliberate absence of authority, not a gap to fill. No
term-start authority exists for state or local officeholders in our data or in any single public
dataset. So resolve seating from the member's own record page, never from our `term_start`, and
report the row **owed** when the page cannot answer.

⚠ **A candidate seat is not a tenure.** `office_terms` holds `Candidate for U.S. Senate — Alabama`
rows beside real seats, and a sitting senator seeking re-election has **both**. Reading the wrong
one gives a term that starts in the future.

`validate-stance-quotes.py` carries a deterministic `[PRE-SEATING]` check that parses session codes
out of `sources` **and** `reasoning`. Note the trap in the trap: a member with prior service in the
*other chamber* will false-positive unless the check is keyed to the earliest chamber. And
🔴 **a member's own roster page can hide prior-chamber service** — one senator's page read "Senate
since June 13, 2024" while the corpus had her sponsoring as a Delegate from 2019, so her entire
relevant service fell outside "tenure" and the test silently never ran.

🔴 **A member record is chamber-scoped.** Ask a current senator's record for a session when they sat
in the House, and the system returns a **valid page with zero bills**. Treating that as absence
manufactures a false negative for every chamber-switcher. Record it as UNAVAILABLE and report the row
**owed**, never absent.

### 4.11 WebFetch fabricates quotes

🔴🔴 **WebFetch runs a summarising model over every page and will return paraphrased talking points
formatted as quotations.** Three independent confirmations in the Colorado Springs wave alone: one
re-fetch asking for "only text inside quotation marks" reversed to "no direct quotes exist"; another
returned two *different* "exact quotes" for the same passage across two calls; a third produced two
sentences attributed to a county commissioner that **did not exist in the article at all.**

**Verify every `quote_text` against raw page bytes with no model in the loop** — a plain fetch, strip
tags, normalise quotes and whitespace, substring test.

✅ **The checker is `backend/scripts/verify-quotes.mjs`**, promoted out of the Colorado Springs
wave directory on 2026-09-23 (it was findable only by accident there). Run it on every wave
before pushing quotes:

```bash
cd backend && npm run verify:quotes -- data/stance-research/<wave>
```

It scans the directory for `out-*.csv` (override with `--pattern`), loads the wave's `sources/`
as local text so a quote taken from a harvested file matches without a refetch (override with
`--sources`), and **exits 1 if any quote could not be found**, so it can gate a push. It refuses
to guess a wave directory — name the one you are pushing.
⚠ Four bugs in that checker had to be fixed before it was trustworthy, each of which falsely accused a
genuine quote. Most subtly, it **stripped punctuation before splitting on the ellipsis** (destroying
the truncation marker) and **stripped punctuation before decoding numeric entities**, so
`you&#8217;re` became `you 8217 re` — the digits survive. A false positive here invites deleting a
real quote, so run every flag to ground.

### 4.12 Near-unanimity is not a position; and pick the bill the *claim* names

A vote that passed 43–1 then 45–0 evidences nothing about the member. Record it, do not cite it;
every vote we cite has ≥10% against.

And choose the instrument by **what the claim says**, not by what scores best. Ranking by margin
picked a "Revisions" bill for every childcare row, when the childcare claim lived in a different act
— 159 mentions of "prekindergarten" in the enacted text, **none of it in the synopsis.**

### 4.13 A study directive is not a chair — in either direction

Directing staff to report back is not a position on what the report should say. This is what makes
directive-and-report bodies (§3.5) expensive.

### 4.14 Inference from silence

One agent correctly skipped `trans-athletes` for three senators as indeterminate, then scored a
fourth off the same kind of vote, justified by *"no support expressed for a documentation-based
alternative."* That is inference from silence. Refuse.

---

## 5. Sourcing

### 5.1 What counts

A source must be a real URL that was actually fetched and returned content supporting the claim.
Preferably more than one.

**Primary sources, in rough order of strength:**

1. **On the Record transcripts** — speaker-attributed, timestamped, verbatim. Check these *first* for
   any race; a prior CA-Governor run used web research only and missed **18 of 21** available OTR
   sources.
2. **The instrument itself** — the bill text, the ordinance, the roll call.
3. **The body's own record** — agendas and minutes (§5.3).
4. **The candidate's own site**, deep-linked to the issues page.
5. **A Ballotpedia Candidate Connection survey** — the candidate wrote it, and it is published
   nowhere else, so Ballotpedia is the primary here, not a conduit.

**Corroboration, not primary:** news coverage. The NC pilot's local agent worked from a campaign
platform page plus one news article, produced 7 rows, and **all 7 failed** — a platform is a promise,
not an instrument.

### 5.2 Read the operative section, not the recital

🔴 Miami-Dade Ordinance 26-51 reads pro-cycling in its title **and in its own recitals**, while its
operative section authorises municipalities to **restrict** e-bikes. **The recital and the operative
section can point opposite ways; the operative section governs.**

### 5.3 Local bodies are a different job, and the rule is *test per body*

The legislature method — bill-first off sponsor lists — does not transfer. Councils have no sponsor
lists; the equivalent primary source is the body's own agenda and minutes system.

**The Legistar Web API is the biggest source find and it generalises.** The WebForms UI needs an
interactive postback, but the public JSON API needs no browser: `https://webapi.legistar.com/v1/<client>/`
gives `events`, `eventitems`, `matters` with `$filter`, `histories`, `attachments`, and
**`eventitems/{MatterHistoryId}/votes` = the per-member roll call by name.** Most mid and large US
cities run Legistar. Try it before concluding a council has no reachable record. It produced two
things nothing else could: a council appointee's **vacancy-application packet** (a first-person
policy questionnaire that took him from a documented 0 to 2 rows) and a camping ordinance with roll
call and narrative minutes.

🔴🔴 **"City minutes are narrative, county minutes are action-only" was wrong.** It held in Colorado
Springs and failed in North Carolina, where both Buncombe's and Durham County's minutes carry
per-member statements. What varies is **which system a body publishes in.** Test per body; never
infer from city-versus-county. Action-only minutes can confirm a vote but **cannot seat a chair.**

🔴🔴 **An absent document in one system is not an absent document.** Durham County's Legistar has no
minutes and no roll calls at all; the county's own site has verbatim statements and named Ayes and
Nays — but that archive stops after Jan 2025, so the current board is readable across **four
meetings**. Both facts matter and neither is visible from the other system.

🔴 **The seating rule is per body.** In Asheville the mover chose the item, so mover/seconder is
evidence. In Durham the Mayor Pro Tempore moves nearly everything and one pair moved and seconded
thirty consent items at one timestamp — there **only the named tally counts.**

Other measured traps: a Legistar **HTTP 500 means "no such client"**, not "server down"; CivicClerk
OData **caps a page at 15 rows whatever `$top` says** (paging took one body from 21 documents to 51);
one city publishes **each minutes document twice** (briefing and formal meeting, same underlying
file) — dedupe by content hash; and **a published minutes PDF can be an unfilled template**
(`Councilwoman ____ moved`).

🔴🔴 **Skip school boards and school committees entirely — this is a standing product
decision, not a coverage judgement.** No compass stance research runs for a `School Committee` or
`School Board` chamber until a dedicated school-board badge ships, because those members must be
visually distinguished before their stances go live. When a local body list includes them, route
the city council and leave the school board; say in the wave notes that you did.

⚠ Some seats set almost no policy the ladders ask about. **6 of 32** NC locals were Sheriff, Register
of Deeds or Clerk of Superior Court. Expect documented zeros. Do not force.

### 5.4 What went wrong at scale, and why it did not look like laziness

This is the part a new researcher most needs to read, because the failure is *convincing*.

A bulk seed published stances inferred from **party plus district geography**. The tell was one
member's `civil-rights` reasoning citing a *"consistent progressive voting record from Lake Oswego
district"* — she represents a district 130 miles away. Four of her six rows described a different
representative.

Scope, re-measured 2026-07-29: **1,749 suspect answers across 466 politicians**, in three shapes —
921 with **no `politician_context` row at all**, 786 sourced **only to a Ballotpedia biography**, and
42 with an empty `sources` array. **326 of the 466 were seated and visible**, and **303 politicians
had an *entirely* suspect compass** — a voter seeing a complete profile resting on nothing.

Migration 1494 retired 969 answers across 184 politicians.

🔴 **Do not triage this bucket by reasoning text.** Grouping the 786 by what the reasoning *contains*
gives quote 407 / characterisation 283 / specific bill 93 / explicit party-prior language **6**. That
reads as "mostly lazy citations," and it is not: **7 of 8 bill-citing rows cited votes cast before the
member was seated.** Specific-looking content is what fabrication looks like here — a party prior
dressed in bills and quotes. Rare party-prior phrasing exonerates nothing.

🔴 **A single-party cohort is where party-prior fabrication is invisible.** On the WI wave all 12
subjects were Democrats, and **all 10 pass-1 drops over-reached toward the most extreme chair, none
toward the middle** — even though the brief opened with that exact warning. **The warning is necessary
and not sufficient. Mechanical chair-text comparison is what actually caught them.**

**Convergent error is not corroboration.** Two agents independently scored `healthcare` = 2 off
*companion* fertility-coverage bills. A single benefit mandate is not a position on coverage
architecture. Agreement between two readers of the same text means nothing.

Related class, national and **not yet worked**: the phrase *"backed Medicaid expansion"* appears in
**368 rows across 288 politicians in 44 states, 360 of them with no bill citation of any kind.**
Maryland expanded Medicaid in 2013, before most of those members were seated — so the claim was not
merely unsourced, it was impossible.

### 5.5 The chair-inversion batch — when a run writes intensity instead of a chair

A separate defect, found 2026-08-12. Rows whose stored chair says the *opposite* of their own
reasoning: a senator who "prioritizes racial justice" at the chair reading *eliminate affirmative
action*; an openly gay mayor at *make same-sex marriage illegal*; two senators described as the
chamber's strongest Ukraine supporters at *end all aid immediately*.

🔴🔴 **It was one bad batch, not scattered noise.** 15 politicians held 79 inverted rows, and for 14
of them **100% of their pro-worded rows sat at the anti pole.** 14 of the 15 were Maryland.
Best reading: **one research run wrote the chair as an intensity rating** — 5 meaning "strongly holds
this view" — instead of picking one of five discrete policy options.

⚠ **But a mechanical 5→1 flip was not safe.** The same batch got other topics right, because there
the reasoning was phrased as opposition and the writer picked a low number. The batch is
*inconsistent*, so the correction had to be judged per row. Migration 1714 corrected 89 chairs.

The detector itself is worth copying, because **polarity must not be hand-asserted**: it lets the
*corpus* define each topic's direction by measuring how pro/anti-worded reasoning distributes across
the five chairs, and marks topics with a weak or non-monotonic pattern **UNCALIBRATED**, contributing
no flags. `fossil-fuels` scores 0.00 and is correctly excluded — its restrictive chair is the
pro-climate one.

⚠ Four topics scored UNCALIBRATED and were therefore **never tested at all**, so the national total
is unknown and may exceed the 194 flags found.

### 5.6 The gate

`npm run check:stance-sources --prefix backend`. The operator's predicate: **Ballotpedia cannot be
the only source.** It runs on master pushes and the daily cron, **not on PRs** — sourcing debt changes
with data, not with commits.

**Measured 2026-09-23 — 900 offending rows, every class at baseline:**

| Class | Observed | Baseline |
|---|---|---|
| `PRIMARY_SITE_NO_PATH` | 670 | 670 |
| `BALLOTPEDIA_ONLY` | 179 | 179 |
| `ORPHAN_CONTEXT` | 50 | 50 |
| `BARE_AGGREGATOR_DOMAIN` | 1 | 1 |
| `ANSWER_WITHOUT_CONTEXT`, `EMPTY_SOURCES`, `FABRICATED_SOURCE`, `NON_URL_SOURCE` | 0 | must be 0 |

⚠ **Two baselines have risen since 2026-08-21** — `BALLOTPEDIA_ONLY` 158 → 179 and
`PRIMARY_SITE_NO_PATH` 536 → 670. The rule in the original design was that these numbers should only
ever go *down*, because lowering them is how backlog progress is recorded. **Whether those raises
were earned is a question for the reviewer, and §12.3 asks it.**

🔴🔴 **Do not retire the `PRIMARY_SITE_NO_PATH` rows as a class.** That recommendation was made once
and was **wrong**. Those 670 rows cite a domain with no path, and the overwhelming majority are the
**candidate's own campaign homepage** — which is the primary source that re-sourcing is *trying to
reach*. 6 of 6 sampled contained the claim credited to them, because those sites put their issues
content on the front page. **The defect is a missing path, not an absent source. Add the path.**

🔴 **A green run means "no row cites Ballotpedia and nothing else". It does not mean stances are
sourced.** The gate reads the *shape* of `sources` and never the cited page. A row citing the
legislature for a vote the member never cast passes, and is still false.

---

## 6. Verification, and the controls that make it mean something

### 6.1 Run a positive control on any detector that reports "nothing found"

This is the load-bearing habit of the whole program, and it has caught silent breakage repeatedly.

- `check:deletable`'s untracked-file scan came back **blind** on its first run, because
  `git status --ignored` overflowed a 1 MB buffer and the error handler swallowed it into an empty
  result. Without the control it would have reported "0 untracked, SAFE TO DELETE" for a worktree
  full of files.
- A file-mtime scan whose threshold predated the checkout, and a `curl` sweep where the host had
  begun 403-ing every request — turning "this file does not exist" into "you are being blocked".
- The Census ACS API answers **HTTP 200 with HTML saying "Missing Key"**. A clean 200 can be an error
  page.
- A Miami-Dade matter PDF **404s as HTTP 200 with 2,625 bytes of "Web Error" HTML.** Fetch a
  known-good one in the same run as a control before recording an absence.

🔴 **And a control that passes can pass for the wrong reason.** Watch it fail before you trust that it
can. `check:stance-sources` was proven with a deliberately doctored baseline, then the baseline was
restored.

### 6.2 Classify every non-200 before reading it as evidence

`403` = bot block (it renders in a browser). `202`/`429`/`503` = throttled, re-check.
`404`/`0` = actually gone.

This has bitten three times; once **214 silent HTTP-202s nearly recorded 168 correctly-sourced rows
as unsupported.** Ballotpedia rate-limits silently with a 202 and an empty body. A whole cohort once
returned an **empty 200** from Ballotpedia, 0 for 13.

⚠ The inverse exists too: a WAF can 403 a *half*-impersonation and accept a bare request. A browser
user-agent is not a key.

### 6.3 Check what your extractor **kept**, not what you fetched

**Print the length of the text you actually searched.** Three of five bugs in the citation auditor
would have been caught in seconds by that one line.

The worst of them: unbounded `[...]` stripping in a normaliser, meant for `advocate[s]`, paired a `[`
at offset 5,517 with a `]` at 52,511 and **deleted 47,177 of 56,732 characters** — turning two
verbatim quotes into "fabrications". A human hand-check then confirmed the wrong answer, because it
searched the gutted text.

Also measured: scoping extraction to `<main>` drops the whole issues section on single-page campaign
sites; stripping the footer as boilerplate removes the "Paid for by…" line that is the actual
evidence for campaign-finance rows; and a **short page (<400 chars) is usually a disambiguation stub**,
not a failed fetch.

### 6.4 Nine detector corrections, and not once was the detector right that a row should be deleted

🔴🔴 **Treat any "unsourced" or "unverifiable" tally from these tools as a READING QUEUE, never as a
delete list.**

🔑🔑 **A failed basis is not a failed chair.** The rule above is about the detector; this one is
about the row. Evidence that does not survive reading makes the row *unevidenced*, which is not the
same as making the chair wrong — the next step is re-research, not a blank. The Texas SB 17 / HB 17
cohort flagged 16 rows and resolved to **11 re-seated, 4 blanked, 1 held**. Two corollaries. A blank
whose note says the row is re-researchable is an invitation, not a closed case. And 🔴 **sweep every
session a member served** — a sweep restricted to the current session missed SB 4, the actual
operative statute, and left two of those blanks wrong.

When the citation auditor was calibrated, Texas retire-candidates went **32 → 11 → 3 → 0** and
Tennessee/Washington **18 → 8 → 5**, as each false-failure class was fixed. **The data never changed.**
Six distinct classes, including compass **chair labels** being extracted as claim terms (no page
contains `gradual-transition-while-investing-in-clean-energy`, so 15 failures were manufactured) and
the tool **testing pages for our own compass answer text**.

⚠ **Two of those "fixes" reproduced the bug they were written to fix.** Always re-test a fix against
the original failing case, never a synthetic one.

**When a detector's findings shrink every time you fix the detector, it was measuring the detector.**

### 6.5 Oregon is not a base rate

Oregon's cohort failed ~82%. **Texas failed 0 of 181.** Across 560 cohort rows, **436 are positively
verified.** Contamination is the signature of one bad research wave, not of a source.

**Rank cohorts by measured failure rate, never by row count.** The volume-based ranking was wrong.
And the consequence for the backlog is that most remaining rows need **re-pointing, not retiring** —
they quote a campaign site *as reproduced on* Ballotpedia, and the real source is the campaign site.

### 6.6 Verify a retirement against **raw HTML**

Retirement is the one step that cannot be walked back, so it must not depend on the component that
keeps being wrong. Every failure in this workstream has been a **silent text loss**, and a silent loss
looks exactly like an absent claim.

Migration 1520 did it correctly: fetched all 11 pages and grepped the **raw HTML** for the topic
vocabulary — zero hits anywhere — after noticing the original reads had used a broken extractor.

🔴 **Grep counts are not evidence until you look at the matches.** In that same pass, one member's
only "trade" hits were *another politician trading stocks*, and her only "import" hits were the word
*"important"*.

### 6.7 Run the citation control in **both** directions

A control asserting that *every cited id maps to the instrument named, with the right sponsor* runs
**sources → reality**. It cannot see the other direction: **an instrument the voter-facing prose
names that appears in no source URL.**

Measured on Miami-Dade: one member's two seated rows passed the one-way control on 5 citations and 4
unique ids — while `residential-zoning` asserted an ordinance with **no URL for it**. Then the whole
`housing` topic was swept: **3 of 5 rows were short, 13 instruments in all.** ⚠ The one-way control
passed 13 of 13 on those same rows.

**Read the prose, list every instrument it names, then check that list against `sources`.**

⚠ **Cite the claim, not the theme.** One adjacent instrument was deliberately *not* cited and the
post-verify gate asserts its absence. A source list padded with adjacent instruments stops meaning
anything.

### 6.8 A wrong sentence in `reasoning` is a defect even when the number is right

A keyword moved a transportation surtax into the housing corpus, and the published housing reasoning
then called it the housing surtax. Value unchanged, prose wrong, **voter-facing**. Corrected.

Likewise: quotation marks around words a candidate never said are a **fabricated quote on a live
profile**, independent of whether the stance value is right. Migration 1518 fixed 16 of those, and
the CI gate number did not move and never would have — the gate reads the shape of `sources` and
never the reasoning text.

### 6.9 The evidence gate

`node scripts/audit-chair-evidence.mjs --check <written.json>` fails if any row it lists carries
reasoning that names no instrument, act or vote. **Run it before committing any migration that sets a
chair.**

⚠ **`--check` alone before the write is a vacuous pass** — it reads stored reasoning, and with no rows
it reports "OK: all 0". Run `--csv` before the write and `--check` after.

⚠ **Structural validation is not sufficient.** Every row dropped on the WI wave passed
`validate-stance-quotes.py`. The script cannot compare a claimed chair to the ladder's literal text.
And a validator with no roster and no topic scope makes every row trivially "pass" — its guards are
the whole point.

---

## 7. Writing it down

### 7.1 The value-change guard

**Before pushing any value, diff it against what is already there.** Changing a curated value is a
bigger deal than filling a blank.

🔴 **Diff against the OPEN season, not against every season.** The upsert replaces the open season's
row, so "what am I about to overwrite?" is a question about the open season alone. Without the
`status = 'open'` join the guard returns one row per season per topic and becomes ambiguous exactly
when it matters. A row with a blank current value and a filled *prior* value is a **NEW** answer for
this season, not a change.

Three buckets: **NEW** → push with normal approval. **unchanged** → skip. **CHANGE** → do not push
automatically; list each with its reasoning and get explicit per-row sign-off.

**The public summary moves with the value.** Never change a value and leave a reasoning that argues
the old position. After any change, re-read the stored reasoning and confirm it describes the new
position and does not still argue the old one. A value/summary mismatch is a trust defect, not a
cosmetic one.

### 7.2 Migrations

- Live in `backend/migrations/`, numbered `NNNN_snake_case.sql`.
- 🟢 **Ask the allocator for the number. Do not count.**
  `npm run steward --prefix backend -- slot CA --purpose "..."`
- 🔴 **Counting by hand is not a fallback — it is the bug.** A number another session has *decided* to
  use is invisible until it pushes, so no scan can ever see it.
- 🔴 **Decide the author before the number** — the namespace is an argument to the allocator.
  **Chris Andrews → `CA_`.** Chris Cantrell → `CC_`. Everyone else → `shared`.
- CI fails a migration whose slot nobody reserved (`npm run check:reservations`).
- Write them idempotent and end with a `DO $$ … $$` post-verify gate that `RAISE EXCEPTION`s on a
  wrong count. **Dry-run against prod** by wrapping the body `BEGIN; … ROLLBACK;` — and confirm the
  rollback actually reverted before trusting it.

Full rules, including the grandfathering ceilings, are in `CLAUDE.md`.

### 7.3 The gates, and which ones actually run when

| Gate | Command | Runs on |
|---|---|---|
| Stance sourcing | `check:stance-sources` | master push + daily cron — **not PRs** |
| Instrument/topic affinity self-test | `check:instrument-topics` | CI |
| Season corpus floor | `check:season-floor` | CI |
| Answer/season consumers | `check:answer-seasons` | CI |
| Season scaffold | `check:season-scaffold` | CI |
| Ladder text reads | `check-ladder-text-reads.mjs` | CI |
| Answer-delete context guards | `check:answer-delete-guards` | CI |
| Chair evidence | `audit-chair-evidence.mjs` | **manual, before every chair migration** |
| Citation pages | `audit:stance-citations` | manual, chunked — a full pass exceeds the 10-minute cap |

🔴 **Several of the most important jobs skip on PRs and only run on the master push.** A green PR is
not evidence the data is sound. On the NC campaign the master push was the first real run against that
data.

🔴🔴 **A falling count is not proof of destruction, and equal deltas are the cheap half of the test.**
`check:season-floor` once went red with 12 missing from both answers and context, and its own
signature table read that as *"rows are being destroyed. STOP."* It was correct work — twelve
seatings evidenced against a *different person*, deleted under the second disposition of §2.5. The
branch is only earned once **named pairs account for the shortfall exactly**, each verified to hold
zero answers and zero context. And **rule out a re-pin first**: a migration moving rows to another
season makes a season's count fall with nothing destroyed.
**Never lower a floor to make it pass.**

### 7.4 Timestamps will not tell you what you want to know

`politician_answers` and `politician_context` carry `created_at` and `updated_at`.

- **`updated_at` is real and per-row** — it is the diagnostic that works.
- 🔴🔴 **`created_at` is a single backfilled constant.** All 33,022 Season 1 answer rows read
  `2026-08-26 03:46:19`, the moment the column was added. "How many answers were created since the
  baseline?" returns **0 for every window** — which reads like "no insertions" and actually means the
  column cannot answer.
- And **no timestamp says what *value* a row was given**, and a **deleted row leaves no timestamp at
  all.**

**Therefore: keep a ledger.** NC's `LEDGER.md` plus one `written-<batch>.json` per batch is the only
record of what a batch wrote. Research CSVs are gitignored; the written-JSON is what survives.

---

## 8. Building a new ladder

Use this when the evidence is real and **no rung states what the person holds**. That is a topic-
registry question, not a reason to stretch a chair.

### 8.1 Revise, split, or new — decide before authoring

- **Revise** when it is the same issue reworded or reframed. Keeps `topic_key`, quotes, and seated
  answers via an identity `rung_map`. **A rename is always a revision.**
- **Split** when one topic secretly measures two independent axes. Keep one as a revision of the
  original (preserving its quotes); the other becomes a new topic. Season 2's eight-way `education-*`
  split is the worked example.
- **New topic** only for a genuinely new issue with no existing home.

🔴 **`topic_key` is load-bearing and frozen.** `essentials.quotes` joins on it. Change it and you
orphan every quote on that topic.

### 8.2 The seven design rules

1. **One axis only.** If chair 1 measures funding and chair 2 measures who-responds, they are not two
   points on a line — they are two lines.
2. **No effort-dials.** "significantly / moderately / a little" is one position said five ways, and a
   citizen cannot feel the difference. Anchor each rung in a distinct **policy model or posture**.
   *Exception:* a genuine magnitude axis is fine **if** each rung is a concrete, recognisable
   threshold — `abortion`'s gestational limits are the good example.
3. **No double-barrels**, in three kinds: two independent positions joined by "and"; an **off-axis
   limb** (a broadly-agreeable extra that discriminates nothing, like police "better pay and
   equipment" on a centrality axis); and **belief-versus-policy mixing** (a topic named for a belief
   but scored on policy).
4. **Label poles by real held positions, not strawmen.** "Open borders" and literal "abolish the
   police" are attack labels almost nobody holds. **A chair no one sits in is dead weight.**
5. **Ground every rung in reality.** If you cannot name who sits in a chair, it is invented. A
   research pass earns this.
6. **Check cross-topic overlap** before adding.
7. **Neutral, open question** that names the axis. "What approach should…", not "The government
   should…" and not a question that is itself a double-barrel.

**Level-agnostic language is a hard gate.** No "federal", "state", "city", "county"; no "Congress",
"state legislature", "city council". ⚠ **The Season 3 addition breaks this** — see §12.2.

### 8.3 Scope is a per-rung question, not a per-topic one

**Ruling, 2026-08-28, Chris Andrews.** A ladder is only valid at a level where its rungs are things an
officeholder there can actually do. Scopes were originally assigned per topic and never re-checked
rung by rung — `voting-rights` fails 4 of 5 rungs at `local`.

**Before adding a `compass_topic_roles` row for a level, read every rung and ask: does an officeholder
at this level hold a lever on this?** A chair that can only be evidenced by opinion at that level is
exactly the shape the evidence standard refuses.

This arrives from the other direction too. Seven `ORPHAN_CONTEXT` rows sit on topics with **no
`local` row** while the person holds or seeks local office — *"has not raised taxes and lowered the
tax rate"*, *"proposed on day one as mayor to cancel Special Order 40"*. **Every one describes a lever
the office actually holds.** The topic simply is not offered at local, so there is no ladder to seat
them on. **That is a question for the topic registry, not a row to delete.**

### 8.4 Rewording a chair that already holds seated politicians

**Ruling, 2026-08-28, Chris Andrews.**

- A **clarifying** rewording — same position, clearer words — keeps existing seats. Nothing re-audits.
- A **material** rewrite — a double-barrel split, a narrowed or widened claim — means the seats'
  evidence was gathered against a sentence that no longer exists. Those rows need a **re-audit against
  the new wording**, not a silent text update.
- **State the seated-row count in the proposal's rationale**, so the reviewer prices the re-audit
  before approving.

Seasons carry the mechanics: a season's pin never moves once open, so Season 1 rows keep asserting
exactly the wording they were evidenced against. The re-audit question is about what carries forward
into the **next** season's research, not about rewriting history.

### 8.5 The mechanics

Create a topic through the **full revision model**, from a numbered migration, calling
`inform.admin_create_topic_with_revision`. It bootstraps all five layers atomically: identity row,
legacy ladder, the founding published/current v1 revision, its five stance revisions, and the role
scopes. **Do not use the legacy `admin_create_topic_with_stances`** — it creates no revision, so the
topic is invisible to the season read path and cannot be pinned.

⚠ The founding revision's `rationale` and `public_note` are **auto-generated**; the RPC has no
argument for the real design rationale. **Put it in the migration's SQL comments** — the axis, the
polarity choice, the rung thresholds, who seats each rung, and why it departs from convention.
`CA_0027` is the model.

To edit an existing topic: `admin_propose_topic_revision` → approve. For a **major** change, **do not
publish** — stage into the next draft season with `admin_season_pin_revision`, and let
`admin_open_season` publish it at the season boundary. Only one open revision per topic; to change a
draft you must reject it and propose a fresh one.

`is_live` does **not** gate the season read path. A topic goes live by being pinned into a season and
that season opening. **Measured 2026-09-23: 18 of the 61 Season 3 topics carry `is_live = false`** and
are perfectly live in the season — which is precisely why a nightly job that read `is_live` had to be
corrected (`CA_0170`).

### 8.6 The Plan D rewrite workflow is retired

✅ **Deleted 2026-09-23.** `research-stances/SKILL.md` carried a `--rewrite-id` REWRITE
RE-EVALUATION MODE — roughly 250 lines feeding `inform.topic_rewrites` and
`inform.topic_rewrite_stance_proposals`. It is gone, and the skill now points at §8.3–8.5 instead.

It was flagged during the H3 repair for still reading the frozen `inform.compass_stances` table for
both its old and its new ladder, and the first instinct was to port it onto the revision model.
**Measuring first killed that plan**, which is the reusable part of this:

| Table | Rows |
|---|---|
| `inform.topic_rewrites` | **0** |
| `inform.topic_rewrite_stance_proposals` | **0** |
| `inform.compass_topic_revisions` | **140**, 2026-03-15 → 2026-09-12 |

Both rewrite tables have always been empty. The mode was a second, never-used path to a job the
revision model already does, and the revision model already carries the two things the rewrite
workflow was hand-rolling: `change_class` (17 `clarifying`, 123 `substantive`) is the §8.4 ruling
about which rewordings cost a re-audit, and `rung_map` (on all 17 clarifying revisions and 57 of
the substantive ones) is the old→new identity mapping.

🔑 **A port would have rebuilt a frozen-table read that had no user.** Before repointing a code
path at a better model, count its rows — dead code is cheaper to delete than to modernise, and
every line kept is a place the frozen table can leak back in.

⚠ The two tables themselves are left in place. Dropping them is a migration and a separate
decision; empty tables cost nothing, and it was the skill that made them reachable.

---

## 9. Quotes and Read & Rank — the coupling, in brief

The full rulebook is `docs/quote-curation/PRINCIPLES.md` in the `on-the-record` corpus, with the
working checks in `audit-quotes/CHECKS.md`. **Read it from there; do not restate it from memory.**

Three things a stance researcher must know:

1. **`topic_key` is the shared unit.** `essentials.quotes` joins on it. A topic rename or a careless
   new topic orphans quotes silently.
2. **Quotes ship as drafts and are promoted after the audit** — never live in the same step that
   inserts them. The flow is research → pre-push QA → insert with `readrank_selected = false` →
   audit → promote.
3. **A quote is coupled to its value.** If the audit finds the quote and the chair in tension, that
   is a finding about the *stance*, not only the quote.

⚠ The admin layer made the **question** the first-class unit of comparison (`readrank_questions`,
`quotes.question_id`), while the game still treats the **topic** as the unit. One topic can host
several questions. Know which layer you are in.

---

## 10. Calibration set — ten worked judgments

These transfer faster than rules. Each is real.

### Accept

**A1 — Authored bill, chair-shaped, clause-complete.**
A state senator is prime sponsor of a bill that *is* "impose a moratorium on new data centres until
the utility commission reports". The ladder's chair 1 is a moratorium. The bill's relating-clause
matches the chair's clause. **Seat chair 1.**

**A2 — A vote, where the bill is the position.**
*Yes* on a bill that is specifically a Medicaid benefit extension. The instrument itself is
chair-shaped, so the Yes adopts its content. **Seat.** (Contrast R1.)

**A3 — A first-person policy questionnaire from the body's own record.**
A council appointee's vacancy-application packet answers policy questions in his own words, published
by the city. Took him from a documented zero to two rows. **Seat**, citing the packet.

**A4 — One instrument, a whole body.**
An ordinance adopted by a named tally, where the minutes carry each member's statement. Read once,
seats seven members. **Seat all seven** — after a cohort pass confirms the members are not being
separated by language that separates nobody.

**A5 — A clean single-instrument policy seat.**
A commissioner's own adopted, sole-prime **policy** item squarely on the ladder's axis. **Seat** —
and note the precedent it sets, because the next marginal case will be compared to it.

### Refuse

**R1 — A vote against something objectionable.**
*No* on a rebate deal the member disliked. It rules out one end of the scale and identifies no chair.
**Refuse.** This is the single most common near-miss.

**R2 — Direction without magnitude.**
"Supports progressive taxation to fund public services." Real, sourced, and it cannot distinguish
*significantly raise* from *moderately raise*. **Refuse**, and do not reach for the least extreme
option — reaching for it is the signal the row is not evidenced.

**R3 — The chair is broader than the bill.**
Member authored an **ADU-only** bill. The chair says "upzone broadly to allow multifamily by right in
most neighborhoods". **Refuse** — or seat the narrower chair if one fits. Caught by reading the chair
text against the relating-clause, not by reading the bill alone.

**R4 — Two of his own bills, two adjacent chairs.**
Prime sponsor of both the data-centre moratorium (chair 1) and the bill making data centres buy their
own power (chair 2). **Blank the spoke.** Finding one bill is not finding the answer.

**R5 — The chair describes state law, not a person.**
A Florida county commissioner on `rent-regulation`. Rungs 1–2 are unlawful; rung 5 is an accurate
description of the statute and of nobody's belief. **Refuse the whole topic for the cohort** and write
the jurisdictional finding down — `compass_topic_roles` cannot express it.

**Bonus — R6, the one that looks like a keep.**
A verbatim, correctly attributed quote: *"Morally wrong… hateful and divisive."* It is real, it is
theirs, and it pins no policy clause. **Refuse.** Rhetoric is corroboration, never the chair.

---

## 11. First-wave protocol

For the first wave by any new researcher — human or model — on any new body.

1. **Scope from `compass_topic_roles`, live.** Query the role scopes for the level; do not inherit a
   topic list from a file. **Measured 2026-09-23 across the 61 Season 3 topics: 36 carry `local`, 41
   `state`, 34 `federal`.** These move; re-verify every run. **Drop any school board or school
   committee from the cohort before you start** (§5.3).
2. **Read the ladders from the season pin** (§2.2), and **diff them against the frozen table** so you
   know which ones would have misled you.
3. **Test the axis before spending** (§4.7): write down the one question the five rungs all answer,
   then read twenty lead titles.
4. **Run a positive control** on whatever search you are about to trust (§6.1).
5. **Work bill-first** (§3.3), keeping a verified-instrument file.
6. **Do the work inline, one politician per run.** Not in research sub-agents, and not several people
   batched into one pass — see §13.1. Finish a person, review them, then start the next. Budget for it
   being slower and say so up front.
7. **Cohort pass** before any push (§3.4).
8. **Pre-push checks:** `audit-chair-evidence.mjs --csv`, `npm run verify:quotes -- <wave-dir>`
   (quote verification against raw bytes), the value-change guard against the **open** season.
9. **Human review of the whole batch, against the ladder text, before the push.** This is the step the
   NC pilot proves is not optional.
10. **Push dry-run first**, confirm the rollback reverted, then commit. Write the ledger and the
    `written-<batch>.json`.
11. **Post-push:** `audit-chair-evidence.mjs --check <written.json>`, then re-run
    `check:stance-sources` and confirm every class is at or below baseline.
12. **Record every refusal and what would close it.** A refusal is a result. Miami-Dade keeps
    `2026-09-07-miamidade-refusals.md` for exactly this, and it is read before anyone is re-researched.

**Exit criterion for "supervised":** two consecutive batches where the reviewer's read changes no
chair. Not a row count.

---

## 12. Season 3 — proposals

Season 3 exists as a **draft** with **61 topics** and **17 answers already written into it**
(Nashville Metro Council, `surveillance-technology`, 2026-09-12 to 09-15). It adds exactly one topic
over Season 2.

🔴🔴 **Opening Season 3 is decided, not pending, and it is not yours to propose.** Everything
below is about what Season 3 should *contain*; none of it is a step toward opening it. Do not list
opening the season as a next step, and never call `inform.admin_open_season`. Season 2's topic set
is likewise frozen — no additions, removals, re-pins or rewordings — though its stances and
display order are still open, so a ladder fix lands in the Season 3 draft and nowhere else.

### 12.1 Closed — four defects our own notes still list as open

**Re-tested against the Season 3 pin, 2026-09-23. Do not plan work against these.**

| Ladder | What our notes say | Actual state in the Season 3 pin |
|---|---|---|
| `medicare/aid` ch.2 | "lower Medicare age to 55 **and** expand Medicaid" — the Medicare half is unreachable below federal, so all state-leg rows belong at chair 3 | ✅ **Fixed.** Now *"significantly expand Medicare **or** Medicaid eligibility, stopping short of universal coverage."* The double-barrel is gone |
| `abortion` ch.1 | requires "publicly funded", a second clause | ✅ **Fixed.** Now a clean gestational-limit axis, 1–5, each rung a concrete threshold — the good example of rule 8.2(2) |
| `same-sex-marriage` ch.1–2 | written at federal scope ("require all states", "full federal benefits"); no state bill can evidence either | ✅ **Scope fixed** |
| `voting-rights` | asymmetric — chair 2 names *expanding* early voting, no chair names *reducing* it | ✅ **Rewritten** as a single, symmetric voter-ID axis |

### 12.2 Open — what we propose Season 3 should change

**P1 — `surveillance-technology` breaks the level-agnostic gate, and it already has 17 seated rows.**
Chair 1 reads *"Prohibit **the city** from acquiring or operating…"* and chair 5 *"Build out
**citywide** camera and license plate reader networks…"* — while the topic carries a **`state`** role.
A state legislator cannot be seated against a rung written about a city.
Chair 2 also bundles **four** clauses (council approval, published use policy, strict retention
limits, no outside data sharing); under §4.2 every clause needs evidence, which makes it very hard to
seat honestly. All 17 existing answers sit at 1 or 2.
▶ **Proposed:** revise the rung text to be level-agnostic, split chair 2's clauses onto the axis or
reduce it to its discriminating clause, and re-audit the 17 seated rows against the new wording
(§8.4). **This is a material rewrite, so the 17 rows are the re-audit cost.**

**P2 — `residential-zoning` chair 5 is unreachable in practice.** It bundles "eliminate
single-family-only zoning" with "allow **any housing type on any lot** communitywide". Every real
jurisdiction has ended SF-only zoning the other way — Buncombe County adopted what its own board
called "ending single family zoning in the County" by allowing **two units per lot**. So chair 5's
headline is met and its operative clause is not, while two-units-per-lot is chair 2's duplex clause
whose qualifier the same amendment contradicts.
▶ **Proposed:** drop the "any housing type on any lot" clause, or move it to a distinct rung.

**P3 — `rent-regulation` is state-preempted in at least Florida and North Carolina.** Rungs 1–2 are
unlawful there and rung 5 describes the statute. `compass_topic_roles` has no per-state dimension.
▶ **Proposed:** a ruling on whether a topic can carry a per-jurisdiction availability note, and — if
not — a documented exclusion list that researchers must check. **This is the one structural gap the
schema cannot currently express.**

**P4 — `ai-regulation` and `tariffs` run opposite to the corpus convention, and nothing stores that.**
Confirmed against the Season 3 pin: `ai-regulation` chair 1 is *"Allow AI companies to develop and
deploy technology freely"*; `tariffs` chair 1 is *"eliminate all tariffs"*. **Measured 2026-09-23:
`inform.compass_topics` has no orientation column**, and the radar's `invertedSpokes` is a
**per-viewer UI toggle** initialised to `{}`. So by default both spokes plot backwards for every
viewer, and two politicians with identical radar shapes can hold opposite positions.
▶ **Proposed:** store orientation on the topic and derive a canonical `invertedSpokes` default from
it, keeping the user toggle as an override. The 2026-08-12 audit table is the seed data. **This is a
product decision, hence a proposal rather than a fix.**

**P5 — `campaign-finance` chair 1 is an absolute clause.** "Ban **all** private money in political
campaigns." Under §4.2, seating it requires evidence for the absolute. In practice it is unreachable
and the ladder loses a rung.
▶ **Proposed:** soften to a real held position, or accept that chair 1 is a pole nobody sits in
(rule 8.2(4)).

**P6 — `same-sex-marriage` chair 1 is a new double-barrel.** The scope fix introduced it:
*"equal marriage **plus** protection from discrimination (such as in jobs and housing)"* — two
independent positions.
▶ **Proposed:** split, or reduce chair 1 to its discriminating clause.

**P7 — `voting-rights` is now voter-ID only, and carries no `local` role.** The rewrite made it clean
and narrowed it: early voting, mail access and registration are no longer anywhere on it.
`ranked-choice-voting` (new in Season 2) does carry `local`, which partly closes the long-standing
"the local scale has no elections topic" gap that left county Clerks and Treasurers with real
election-security records and nowhere to sit.
▶ **Proposed:** a ruling on whether ballot **access** deserves its own ladder, now that
`voting-rights` is an identification ladder.

### 12.3 Rulings requested from Chris Andrews

1. **P3** — can a topic express per-jurisdiction legal availability, or is a documented exclusion list
   the answer?
2. **P4** — store topic orientation, yes or no? It changes what every voter sees on two spokes.
3. **P7** — does ballot access get its own ladder?
4. **§8.3** — the seven local-office `ORPHAN_CONTEXT` rows describe levers the office genuinely
   holds, on topics not offered at `local`. Add the roles, or leave the rows unseatable?
5. **§5.6** — `BALLOTPEDIA_ONLY` rose 158 → 179 and `PRIMARY_SITE_NO_PATH` 536 → 670 since
   2026-08-21. The design rule was that these only go down. **Were those raises earned?**
6. **§12.2 P1** — `surveillance-technology` has 17 seated rows against rung text that breaks our own
   level-agnostic gate. Revise and re-audit, or accept as-is?

---

## 13. What we would do differently

### 13.1 🔴 Our own `research-stances` skill is stale, and it will reproduce a known failure

`.claude/skills/research-stances/SKILL.md` STEP 1 instructs the reader to **dispatch one
`politician-stance-researcher` agent per politician.** The operator withdrew that on 2026-08-24:

> *"I almost always get into trouble with multiple agents and prefer doing it inline unless there's a
> very compelling reason. Speed is less important than getting it right, with sources and assigned to
> a chair — not polarity."*

The reasoning is not preference. **A stance row is a public claim about a real person, so the work
that must be visible is exactly the work an agent hides.** The agent makes the bar judgment invisibly,
at roughly 143k tokens and 9 minutes per person, and it surfaces only in review — which is how 38
rows became 8.

**The unit of work is one politician** (reaffirmed 2026-09-23). Research one person, finish them,
review them, then start the next. Do not batch several people into one pass, and do not run two
people concurrently.

That rule used to be a **concurrency cap on agents** — at most three `politician-stance-researcher`
agents at once, because more hit the rate limit and returned empty CSVs. **That framing is obsolete.**
With inline execution there is no concurrency to cap; the reason for one-at-a-time is now different
and better. Two reasons:

- **A cohort pass needs a finished person to compare against.** Judging a ladder comparatively (§3.4)
  only works once the earlier members' rows exist and have been read.
- **A batch hides which judgment went wrong.** When 38 rows arrive together, the review cost is the
  whole batch. When one person arrives, the reviewer can point at the row and the instrument.

🔴🔴 **And a subagent cannot do this work at all.** No MCP server is bound inside a subagent, so
a research agent has no route to the season pin, the ladder text, or the database — it can
web-search and report, and nothing more. Subagents here have also repeatedly reported verification
they never ran. Inline execution is not a preference about agent count; it is the only mode in
which the checks in §6 can actually run.

▶ **Required before handover: update STEP 1 to inline execution, one politician per run.** If
Andrews' Claude runs the skill as written, it will do the thing this document spends §4 warning
against.

### 13.2 Exhaust cheap SQL predicates before reading pages

**We did this in the wrong order and it cost weeks.** A single query over the shape of `sources`
found a 602-row class nobody had looked for. The judgement-heavy page-reading produced 224
retirements over four sessions. Do the query first.

### 13.3 A predicate reads the shape of a value, never what the value is

🔴🔴 In this corpus **the shape of a blank and the shape of a claim are the same words.** A regex for
position-asserting language (`supports|opposes|voted`) flagged 15 rows as suspect; **all 15 were model
blanks** — the regex fired on the evidence the row *reports*, not on a claim it makes:
*"supports growing businesses, **but** no specific stance … found"*.
`GROUP BY` the discriminating field and read a sample before trusting any predicate. **Deletion raises
the bar further.**

### 13.4 Split a retirement by replacement path, not by size

One batch of 20 rows belonged to sitting legislators whose record is re-derivable from roll calls
(delete and re-derive). Another 7 described a **previous office** while citing the current one's bio
page, and **must never** be re-derived from the current chamber's record — that is how a statewide
executive gets credited with legislative votes. Mixing them would have lost that instruction.

### 13.5 An honest zero is a real result, and a research timestamp with zero answers is legitimate

That is how "we looked and found nothing" is recorded. Nulling it destroys the fact that we looked.

### 13.6 Verify a name collision is the same person

Two of four roster hits in one pass were a Colorado senator and a Utah treasurer. A naive
"one legislator with this surname" rule matched a Utah representative to an Oregon legislator.
Scope by state and title, require the first initial to agree, strip bare middle initials but **keep
suffixes**, and normalise diacritics by NFKD-then-delete-combining-marks (otherwise `Nguyễn` becomes
`nguye n`).

---

## 14. Tooling index

| Purpose | Path |
|---|---|
| Push a researched CSV | `backend/scripts/push-stance-csv.mjs`, `push-nc-stances.mjs` |
| Season-aware write shapes | `backend/src/lib/seasonService.ts` |
| Chair evidence gate | `backend/scripts/audit-chair-evidence.mjs` |
| Sourcing gate | `backend/scripts/check-stance-sources.mjs` |
| Page-level citation audit | `backend/scripts/audit-stance-citations.mjs` |
| Instrument ↔ topic affinity | `backend/scripts/instrument-topic-affinity.mjs` |
| Borrowed-ladder probe | `backend/scripts/ladder-language-probe.mjs` |
| Chair-inversion scan | `backend/scripts/chair-inversion-scan.mjs` |
| Ladder-text read enforcement | `backend/scripts/check-ladder-text-reads.mjs` |
| Quote verification vs raw bytes | `npm run verify:quotes -- <wave-dir>` (`backend/scripts/verify-quotes.mjs`) — exits 1 on any unverified quote, see §4.11 |
| Payload validator | `backend/scripts/validate-stance-quotes.py` |
| Topic authoring | `.claude/skills/compass-topic-builder/SKILL.md` |
| Stance research | `.claude/skills/research-stances/SKILL.md` — ⚠ **see §13.1** |

**Prior art worth reading before a wave:** `.planning/todos/2026-09-07-miamidade-compass-stances.md`
(the toolchain and its run order), `.planning/workstreams/nc-stance-campaign/LEDGER.md`,
`backend/data/stance-research/nc-campaign/local-source-map.md`,
`.planning/todos/2026-08-12-ladder-orientation-and-consumers.md`, and ADRs 0004, 0005, 0006.

---

## 15. The standard, in one paragraph

A compass row is a public claim about a named person. It needs a **chair the evidence names** and a
**source that supports it**, independently verified. Party is never evidence. Direction is not
magnitude. A vote pins a chair only when the bill is chair-shaped. Every clause of a compound chair
needs its own evidence. Read the ladder from the season pin, not the frozen table. Test the axis
before you spend. Run a positive control on anything that reports nothing. Treat every detector's
output as a reading queue, never a delete list. Verify a retirement against raw HTML. And when the
evidence does not reach a chair, **leave the spoke blank** — an empty compass is honest, and a
confabulated one is a false statement about a real person.
