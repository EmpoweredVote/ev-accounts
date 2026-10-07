# Season 3 — design spec (ladders that records can seat, pre-staged research, a switch to open)

**Date:** 2026-10-07 · **Owner:** Chris Andrews (operator) · **Status:** DRAFT — every § marked *Ruling* needs his
decision before build. Seasons design and ADR 0005/0006 are Chris Cantrell's; §6 touches them and needs his review.
**Evidence for this spec:** `~/Documents/GitHub/.planning/todos/2026-10-07-why-season2-seats-fewer-chairs.md`
(measurements) and `2026-10-07-season3-pilot-direction-only-ladders.md` (per-topic items).

## 1. Why

Season 2 research seats 2–3% of production rows (Monroe 5/145; local batches 51/2,502). Where evidence exists, the
blocker is ladder shape: 82 coder rows showed a side and no rung, because adjacent rungs differ by a degree
("high", "significantly"), an absence ("at most", "without moving to eliminate"), a second clause joined by "and",
or a mechanism no rung names. Ladders whose rungs are **kinds of act a government passes** (a ban, a definition, a
required document) seated 5 of 6 rows; degree ladders seated 0 of 5.

Season 3 keeps the evidence standard (codebook 0.4, V4.2, certification eb2f791a) and changes the ladders so that
the standard can be met.

**Goal:** every Season 3 ladder passes the seatability test in §4 before it is pinned, and research for Season 3 is
done in the draft season before it opens (§6).

**Non-goals:** ladders per location or per level (later); the compass questionnaire to candidates and the "confirm
your rung" follow-up (need Empowered accounts, about a year out); On the Record evidence work (its own spec, §7).

## 2. The ladder rulebook (*Ruling* — L1–L10)

| # | Rule | Why (measured) |
|---|---|---|
| **L1** | **Name the spectrum.** Every ladder states one axis with two named poles, e.g. *"Government directs the energy shift ↔ Government stays out of energy choices."* The poles are shown to voters with the question. | Rung order must mean something to the voter and to the coder; today the axis lives only in the annex ("inverted", "off-axis"). |
| **L2** | **Rungs are ordered along that axis**, 1 at one pole, 5 at the other. Each rung is one step along the named axis, not a mix of two axes. | 3 of the measured blockers mix axes (housing zoning vs subsidies; redistricting who-draws vs rules; healthcare coverage vs cost). |
| **L3** | **Each rung names a kind of act** — require by law, pay for, make easier, treat neutrally, undo — **general in the kind, never in the amount.** Name a class of mechanism ("public money or guaranteed prices"), not one instrument. | 22 rows stopped on a mechanism no rung named; class-level wording would cover ~14 of them, specific rewrites 10 (estimate). |
| **L4** | **No degree words** on any rung: high, low, major, significant(ly), moderate(ly), modest, strict, aggressive, as far as possible, broadly, small. | A record never states a degree; 4 measured rows. |
| **L5** | **No absence clauses on middle rungs** (at most, without, no new, only [as a limit on what the person wants], leaving … in place). A pole rung may state an absence ("no penalties", "no subsidies") because it is the end of the axis. A **condition a law itself states** ("enforce only when shelter is offered") is a clause, not an absence, and is allowed. | Silence is not a clause (V4.2); 9 measured rows. |
| **L6** | **No "and" between two clauses a record must both show.** If both are needed, they are two rungs, or one clause goes. | 9 rows met one clause of a compound rung. |
| **L7** | **"Or" is allowed only when both alternatives sit at the same point on the axis** — two ways of doing the same kind of act ("public money **or** guaranteed prices"). "Ban camping **or** fund shelters" fails: two positions. | Keeps "or" from merging two stances into one chair. |
| **L8** | **Level-neutral verbs.** "Your government requires …", not "Congress" / "national". One ladder serves every level that is asked the topic. | minimum-wage rung 3 says "national" and cannot be met by a state record. |
| **L9** | **The rung's object is what records act on.** Name the object laws actually regulate (emissions **or** energy sources; developers **or** deployers). | H17: emissions limits matched no climate rung; AI liability bills bind deployers. |
| **L10** | **Five rungs, each a distinct stance.** No rung defined as "more of" its neighbour. If a topic cannot reach five kinds of act along one axis, propose fewer rungs for that topic as an exception (needs a separate ruling: voter compass shape). | Nested rungs cannot be separated by records. |

### 2.1 Worked examples (drafts for illustration — not proposals yet; each goes through §4)

**climate-change** — axis: *Government directs the energy shift ↔ Government stays out of energy choices.*

| | Season 2 | Season 3 draft | Rules |
|---|---|---|---|
| 1 | Require a shift to clean energy through mandates and firm deadlines. | Require emissions cuts **or** a shift to clean energy by law, with deadlines. | L7, L9 |
| 2 | Fund clean energy with **major** subsidies, tax credits, and public investment. | Pay for clean energy with public money, tax credits **or** guaranteed purchase prices. | L3, L4, L7 |
| 3 | Speed up clean energy by cutting permitting red tape and upgrading the grid. | Make clean energy easier to build: faster permits **or** grid upgrades. | L6→L7 |
| 4 | Stay neutral on energy and let the market choose among all sources. | Treat all energy sources the same in law. | L5 (stated positively) |
| 5 | End government subsidies and mandates for clean energy. | Remove existing clean-energy subsidies **or** mandates. | pole |

Measured rows it would seat: Muratsuchi, Gipson, Lee (emissions laws → 1), Pierce (feed-in tariff → 2). The
operator's blind gold seated Gipson and Lee at 1 — the draft matches his first reading.

**homelessness** — axis: *Protect public sleeping ↔ Penalize public sleeping.*

| | Season 2 | Season 3 draft |
|---|---|---|
| 1 | Protecting the right to sleep … **with no penalties of any kind** | Protect a right to sleep in public places. |
| 2 | Decriminalizing public sleeping and camping | Allow public sleeping and camping without penalty. |
| 3 | Allowing enforcement **only when** adequate shelter beds are available, **with** citations diverting people to services | Enforce camping rules only when shelter is offered. (a condition the law states — L5) |
| 4 | Prohibiting encampments … graduated warnings **and** civil penalties | Clear encampments after notice, by removal **or** civil fines. |
| 5 | Banning public camping and sleeping with criminal penalties … | Make public camping a crime. |

Measured rows it would seat: Montenegro, Thomson (→ 4), Pierce, Taylor (→ 2 or 1 — re-code needed).

## 3. Evidence rules for Season 3 (codebook proposals — *Ruling*)

### 3.1 E1 — Sponsorship
- **Prime author** of a **single-subject** bill whose **operative text** (as filed, or the version they acted on)
  meets every clause of one rung → seats the chair, tier **single-source**.
- **Co-sponsor / co-author** → seats only with a second source: their vote on the final text, or their own words.
- **Every member who voted Yea** on that bill's final passage → seated by the same instrument (whole-body pass,
  calibration A4, after the cohort check). A Nay seats nothing (V4.1).
- Guards that stay: vehicle bills and amended-out-of-shape bills (C37; HEA 1296 2022), near-unanimous votes,
  name-collision, chamber evidence (CONFIRM).
- Basis: the stance-program audit kept 67% of authored-bill chairs, 40% co-authored, 0% bare votes; the
  unanimous gold chairs came from authored single-subject bills (SB 3, SB 100).

### 3.2 E2 — Joint evidence
Two or more instruments may together seat a rung when all hold:
1. each is the person's own act or own words and passes V1–V5;
2. each clause of the rung is met **positively** by at least one instrument, with a verbatim `provision_quote` per
   clause (ruling out another rung meets no clause);
3. no instrument meets a clause of a different rung on the same side (else BLANK `adjacent-chairs`);
4. no instrument contradicts another (else `superseded-by-later` / `record-vs-statement-conflict`);
5. `rests_on` lists every instrument; the reasoning maps instrument → clause;
6. tier **single-source** (no instrument alone supports it). Worked example: Shope / abortion (gold round 19).

Under L6/L7 few rungs remain compound, so E2 matters mostly for Season 2 rows and for "or" rungs it does not need.

### 3.3 Vote explanations (no rule change)
V4.1 already lets a multi-subject vote seat a chair when the person's own explanation ties the vote to the
provision. Season 3 needs **collection** (§7): journals, floor/committee video, the Congressional Record, author
testimony, press releases and newsletters about a named bill.

### 3.4 Candidate Connection
Ruled 2026-10-07: a Ballotpedia Candidate Connection survey answer is the candidate's own words. Gate change in
flight (task chip "Let Candidate Connection surveys pass the source gate").

## 4. The seatability test (#16) — a ladder passes before it is pinned (*Ruling* on thresholds)

**Input**
- *Test set per topic:* every existing coder row on that topic (262 slot-1 rows today; see
  `backend/data/stance-research/2026-10-07-s2-seating-analysis/`) + every blind gold row on it + a fresh sample of
  20 real records/statements per topic, spread over the levels that are asked the topic, drawn **before** the draft
  ladder is written (so the ladder is not fitted to its own test).
- *Ladder:* the draft revision (a `compass_topic_revisions` row in `draft`; coder labels accept any revision id).

**Procedure:** code the test set with the Opus coder (slot 1, codebook current) against the draft revision; repeat
against the served Season 2 revision as the control.

**Pass criteria (proposed)**

| # | Measure | Proposed bar |
|---|---|---|
| T1 | Seat rate among rows whose evidence shows at least a side (chair, direction-only or compound-partial) | ≥ 60% (Season 2 today: 50 / 132 = 38% overall; 0% on degree ladders) |
| T2 | Gold agreement: no draft chair contradicts a gold **final** chair mapped to the new ladder; no gold final blank becomes a chair unless the new rung's clause is visibly met | 0 contradictions |
| T3 | Order check: on 10 paired records where one person clearly acts further toward a pole, the draft chairs keep that order | 10 / 10 |
| T4 | Blind human check: the operator labels 10 new draft chairs blind (Gold Desk) | ≥ 9 / 10 agree |
| T5 | Re-audit cost reported: visible chairs on the topic today (e.g. climate 1,848) and how many the material rewrite reopens | reported, no bar |
| T6 | Rulebook lint: L4 degree-word list, L5/L6 patterns ("and" between clauses, "at most", "without") | 0 hits, or a written exception |

**Leakage:** gold items used to write a ladder cannot count toward a later certification on it (same rule as the
annex exposure cut-off of 2026-10-02).

**Output:** a one-page report per topic (T1–T6) attached to the revision's `review_ref`.

## 5. Rollout order

1. Rulebook (§2) ruled.
2. Seatability harness built (§4).
3. Pilot topics: **climate-change, abortion, homelessness, education-library-books** — 12 of the 31 measured
   rewrite rows and 10 of the 18 gold rows where the operator's blind chair became a blank.
4. Then the rest of the 100%-side topics: housing (watch the zoning-reform trap; consider moving zoning to
   `residential-zoning`), redistricting, deportation, transportation-priorities, judicial-criminal-justice,
   civil-rights, healthcare, ai-regulation, minimum-wage, school-vouchers, taxes, tariffs, ukraine-support.
5. Clarifying-only changes where a ladder already passes T1 (gun-policy, same-sex-marriage, trans-athletes,
   voting-rights): keep seats, no re-audit (ruling 2026-08-28).

## 6. Pre-staging: research Season 3 in the draft season, then open it (*Ruling* on 6.3; Cantrell review)

### 6.1 What exists
- Draft Season 3 (`7b3a066c-…`, 61 questions). A draft may pin an **approved** revision; `admin_open_season`
  publishes approved pins at open, closes the open season, opens the draft (no answer copy).
- Answers and context written with `season_id` = Season 3 are hidden from voters (`SEASON_IS_PUBLISHED`,
  `draftSeasonReads.test.ts`). 17 such rows exist (surveillance-technology).
- Season 2 re-pointing (CC_0058) and the guard that accepts re-pointed revisions (CC_0060).

### 6.2 Gaps (task chips created 2026-10-07)
| Gap | Chip |
|---|---|
| Research scripts hard-code the open season | "Add --season option to stance research scripts" |
| After open, a person with no Season 3 row shows an older chair on rewritten rung text | "Never show a chair on a ladder version it wasn't written for" |
| Moved/merged rungs at publish; one open revision per topic blocks Season 2 fixes on that topic | "Check that moved/merged rungs can publish in Season 3" |
| Reviewer preview of a draft-season profile | not yet a chip (after the --season work) |
| Axis and pole labels have no column (L1) | needs a migration (CA_) after the rulebook ruling |

### 6.3 Open decisions
1. **What voters see when a ladder they answered changes materially** — re-answer prompt for that topic only, or
   hide that spoke until they re-answer?
2. **Clarifying vs material** per topic is decided at proposal time (ruling 2026-08-28); material topics need
   pre-staged research before open, or show an empty spoke (version-aware reads).
3. **The switch:** open Season 3 when every material topic has passed §4 and has pre-staged research for an
   agreed share of seated people (proposal: the people who hold a visible chair on that topic today).

## 7. Evidence base (On the Record) — separate spec, outline only

Today `inform.evidence_items` holds 131 rows for ~3 people and keeps only forward-looking own words; records are
out of scope ("a later votes/actions evidence type"); coder snapshots and evidence items do not read each other.
The spec should cover, in order: one evidence store for both pipelines; a **record** evidence type (vote,
sponsorship, authorship, amendment vote, with provision and tally); a **vote-explanation** type the forward gate
keeps; state floor and committee video ingest (Indiana first); own-site press/newsletter snapshots via discovery;
Candidate Connection as a source; and a person × topic coverage count that sends discovery to empty cells first.

## 8. Decisions needed (summary)

1. Rulebook L1–L10 — adopt / modify.
2. E1 sponsorship and E2 joint evidence — adopt into the codebook (version bump) / modify.
3. Seatability bars T1–T6 — adopt / change the numbers.
4. Pilot topics — the four in §5.3 / others.
5. §6.3 voter-side decisions (1–3).
6. Fewer-than-five-rung exceptions (L10) — allowed at all?
