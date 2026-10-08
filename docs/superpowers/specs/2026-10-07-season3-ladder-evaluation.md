# Season 3 ladder evaluation worksheet

Date: 2026-10-07 (rulebook rulings added 2026-10-08). Operator: Chris Andrews. Read-only on prod: no migration, no proposed or approved
revision, no write. Data read from prod (session pooler, `default_transaction_read_only = on`) on
2026-10-07. Companion to
[`2026-10-07-season3-repointing-findings.md`](2026-10-07-season3-repointing-findings.md).

This worksheet does **not** draft ladder wording and does **not** decide any rung_map. It puts each
of the 61 Season 3 ladders, its pins, its populated rungs and its known defects on one page, with
an empty ruling row.

## How to read it

- One section per topic, grouped by **cost of a moving map** (Groups 1–6, below). The index lists
  every topic with its group.
- **Rungs** are the published text of the `is_current` revision (`inform.compass_stance_revisions`).
  The Season 3 pin equals `is_current` on all 61 topics.
- **Polarity is not assumed.** An "Orientation" line appears only where a source states it. Where
  there is no line, read the rungs. Known: AI Oversight and Tariffs run **inverted**; Residential
  Zoning, Growth and Development Pace and Government Deference are **off-axis**
  (`.planning/todos/2026-08-12-ladder-orientation-and-consumers.md`).
- **S2 rows** = Season 2 `politician_answers` per rung. Value 0 is a blank. On a ⛓ chained topic
  these rows sit on the older Season 2-pinned ladder (shown under the table).
- **S2 would map** = what `inform.repoint_season_answers` (CA_0305) maps if the topic moves:
  non-blank Season 2 rows on the current revision that have a reasoning row. On every non-chained
  topic this equals all seated Season 2 rows. On every chained topic it is 0.
- **S1-only** = people with a Season 1 answer and no Season 2 row, counted against the **Season 1**
  ladder. Under the default rule they all become blank if the topic moves.
- **Voter rows** = `compass_responses` on the topic, all seasons (the findings-doc definition);
  "live" excludes soft-deleted rows.
- Counts were refreshed on 2026-10-07. They equal the findings-doc appendix on every topic (no
  drift yet).

### The three rulings

| ruling | meaning | what it costs |
|---|---|---|
| **identity** | The ladder stays. No new revision. Season 3 keeps the current pin. | Nothing. Season 2 and Season 1 positions keep showing through the newest-season fallback. |
| **clarifying** | Same positions, clearer words. New revision with an identity rung_map. | Seats are kept (ruling 2026-08-28). No re-pointing. The open revision blocks any Season 2 fix on the topic until the Season 3 open. |
| **substantive** | A rung moves, merges or is invalidated. New revision with a moving rung_map. | `repoint_season_answers` writes Season 3 rows (mapped or blank). A material rewrite needs a re-audit, with the seated count stated in the rationale (ruling 2026-08-28). |

### Default rule (accepted 2026-10-07, CA_0305)

1. A Season 2 row on the current revision with reasoning carries to Season 3 at `rung_map[value]`.
2. Everyone else on a moving topic gets a blank (value 0) in Season 3; Season 1 keeps its originals.

CA_0305 and CA_0306 are **applied on prod** (checked 2026-10-07: `inform.repoint_season_answers`
exists, and the publish guard raises `REPOINTING_NO_REASONING`).

## Rulings Chris still owes (rule these first)

1. ~~**Order of work.**~~ **Settled 2026-10-08 (call with Chris Cantrell):** Season 2 is being retired,
   so no Season 2 wording fixes are planned. A pending Season 3 revision blocking a Season 2 fix on
   the same topic is accepted.
2. ~~**The draft Season 3 ladder rulebook (L1–L10).**~~ **Ruled 2026-10-08** — see "Rulebook rulings"
   below. Every topic section in this worksheet now has to be read against those rules.
3. ~~**The 13 chained topics.**~~ **Settled 2026-10-08** by the carry-forward rule (group B carries).
   Original note: Under the default rule, a moving map blanks **every** Season 2 row on
   these topics (0 rows map), including 117 seated `transportation-priorities` rows and 97 seated
   `gun-policy` rows. Accept that, or extend CA_0305 to map through the clarifying revisions in
   between. The findings doc (Rule detail) lists that extension as a possible later change.
4. ~~**Season 1-only people on expensive topics.**~~ **Settled 2026-10-08** by the carry-forward rule
   (same-version carries flagged; older-version blanks). Original note: More than 1,000 people per topic in Group 5 (and
   4 chained topics) show a Season 1 position today. A moving map blanks them all. Confirm this is
   intended per topic, or prefer identity/clarifying where the defect allows it.
5. **CA_0302 (own-words / no-lever, ruling 2026-10-06).** Does it change any ladder's scope? Rungs
   that name a level now conflict with the role rows: `civil-rights` rung 4 ("federal"),
   `minimum-wage` rung 3 ("national"), `surveillance-technology` ("the city", with a `state` role),
   `medicare/aid` (Medicare rungs, with a `state` role), and the eight `education-*` topics (a
   `local` role no city council can answer). The lever review owed in
   `~/Documents/GitHub/.planning/todos/2026-10-06-positions-without-a-lever.md` §10 (taxes/local,
   healthcare/local, transportation/federal, economic-development/federal, education/federal) is
   also still open.
6. **The 2026-08-28 rewording rule** applies to every row: clarifying keeps seats; a material
   rewrite needs a re-audit with the seated-row count stated. Use the "S2 rows" column for that
   count. Note one existing case to decide: `public-safety-approach` rev 4 was published as
   clarifying with an identity map while its own rationale says chairs 2 and 3 "shifted meaning"
   (~462 seats owed a re-audit).
7. **Re-audits owed from Season 2.** Decide whether these finish under Season 2 before any Season 3
   revision: public-safety-approach (~462), housing (reshuffle re-audit never ran),
   same-sex-marriage (57 RFMA rows), gun-policy (49+3), city-sanitation (13 orphans),
   judicial-transparency (34), local-environment (CA_0062).
8. **Unruled proposals** a1–a3, b2, c1–c13, c-lib
   (`~/Documents/GitHub/.planning/todos/2026-10-07-season3-pilot-direction-only-ladders.md`,
   `~/Documents/GitHub/.planning/todos/2026-10-07-why-season2-seats-fewer-chairs.md`), and the
   program questions P3 (preemption marker), P4 (orientation column), P7 (ballot-access ladder),
   L10 (fewer than five rungs) in `docs/superpowers/specs/2026-09-23-stance-program-design.md`
   §12.2–12.3.
9. **`surveillance-technology` has 17 Season 3 rows already** (seated 2026-09-12 to 09-15). Any
   ruling other than identity requires deleting or rewriting them first.
10. **Foreign-policy pruning.** Five foreign-policy topics converge (defense-spending note). Pruning
    is a decision for Chris, and it would change which ladders exist at all.

## Rulebook rulings (Chris Andrews, 2026-10-08)

The draft rulebook is §2 of `docs/superpowers/specs/2026-10-07-season3-design.md` (PR #925, branch
`claude/s2-seating-analysis`). Ruled rule by rule, against a word scan of the 61 current ladders
(the scan over-counts "and" and "only"; it is a size estimate, not a defect list):

| scan | rungs | topics |
|---|---:|---:|
| L4 degree words | 42 | 28 |
| L5 absence words, any rung | 46 | 41 |
| L6 "and", upper bound | 159 | 58 |
| L8 level words | 19 | 12 |

| rule | ruling | detail |
|---|---|---|
| **L1** name the spectrum | **adopted, poles stored internally** | Every ladder gets two named poles in a column (needs a `CA_` migration). Coders, lexicon checks and orientation read them. **Not shown to voters yet**, so no compass UI change before the open. Replaces the open P4 orientation question. Off-axis ladders must get an honest pole pair or a re-axis. |
| **L2** one axis | **adopted** | A rung that mixes two axes is a defect. Known candidates: housing, redistricting, healthcare, civil-rights r5, voting-rights r5, rent-regulation r3, city-sanitation r2, misinformation r5. |
| **L3** kinds of act | **adopted, with record anchors** | A rung names a kind of act, general in the kind. It may carry an **anchor a record can show** — relative to current law (raise / keep / cut) or a stated threshold (e.g. index to inflation) — instead of an amount. Magnitude ladders keep five rungs this way. |
| L3 clarification (2026-10-08) | **a bar is an act** | A law that forbids the other side's policy (e.g. CA AB 1955, which forbids forced-notification policies) is a kind of act, and a rung may name it. Applies to every ladder. Ruled while preparing the education-gender-identity pilot. |
| **L4** no degree words | **adopted, with record anchors** | No vague degree word (high, significant, moderate, broadly, as far as possible, …) on any rung. Use an anchor (L3) instead. |
| **L5** no absence on middle rungs | **adopted as written** | Poles may state an absence. A condition the law itself states is a clause, not an absence. |
| **L6** no "and"-compounds | **adopted as written** | Split the rung or drop a clause. |
| **L7** "or" at one point only | **adopted as written** | "Or" joins two ways of doing the same kind of act, never two positions. |
| **L8** level-neutral verbs | **adopted, level relations excepted** | Verbs are level-neutral. A rung may name another level only when the relation between levels is the subject (cooperation with federal agents, preemption, state-drawn maps). True defects: minimum-wage r3, civil-rights r4, transportation-priorities r5, economic-development r2–3. |
| **L9** object = what records act on | **adopted** | Checked by the seatability test, not by a lint. Known cases: climate-change, ai-regulation, healthcare, medicare/aid. |
| **L10** five distinct rungs | **five always in Season 3** | No fewer-rung exception. A topic that cannot reach five kinds of act on one axis is re-axed or retired. Fewer-rung ladders are a separate compass-shape decision later. |

**Widening rule (2026-10-08), refines the 2026-08-28 rewording rule.** A change that widens a rung
(for example "A and B" becomes "A or B") is **clarifying** when no seat moves: every seated row
still fits its rung, and no seated row now also fits a neighbour rung. The proposal must state that
check with the seated-row count. Otherwise it is material.

**What this does to the worksheet.** A topic can stay **identity** only if its ladder passes these
rules, or Chris rules a written exception. Most L6 fixes can be clarifying under the widening rule.
L2, L3/L4 (degree to anchor), L8 (true defects) and L9 changes usually move a seat, so they are
substantive and blank every Season 1-only person on that topic under the default rule.

### Evidence rules, seatability test, pilots and the open (same spec §3–§6, ruled 2026-10-08)

| item | ruling |
|---|---|
| **E1** sponsorship | **No tightening.** A co-sponsorship on a bill can seat a chair by itself, as today. Research should still look for more sources, especially the person's own words: a second independent source gives the `corroborated` tier. The rest of E1 (prime author, as-filed, Yea cohort pass, guards) is already in codebook 0.4. |
| **E2** joint evidence | **Adopted as written.** Several instruments may together seat a compound rung: each clause met positively with a verbatim quote, no clause of another rung met, no contradiction, all in `rests_on`, tier always `single-source`. |
| codebook version | **Bump to 0.5** (E2 changes coding results), with a small gold round on E2 cases. 0.5 rows go to review until that round covers them under certification eb2f791a. |
| test scope (§4) | **Changed ladders take T1–T6. An identity topic takes T6 only** (rulebook check, or a written exception); T1/T2 are run on it as a measurement, with no bar. |
| T1 | ~~**≥ 60%** seat rate among rows that show at least a side.~~ **Changed 2026-10-08 (applies to every topic from now on): T1 ≥ 60% over affirmative records only** — Yes votes, sponsorship, authorship. **No votes are excluded** (V4.1: they can never seat on any ladder). **Own words are reported separately, with a no-regression bar:** the draft must seat at least as many own-words rows as the control on the same set. Prompted by the education-gender-identity A1 v2 result (overall 27% vs control 15%; Yes-side records 5/7 = 71%; own words 2/16) — recorded here because the bar changed after a result was seen. Reason: the old denominator measured the evidence mix (a side that votes No and argues against can never seat) rather than the ladder; Season 3's goal is ladders that records can seat, and own words mostly corroborate (hearing-transcript study). |
| T3 | **Kept**: 10 ordered pairs per changed topic, 10/10. **Fixed 2026-10-08:** pairs are pre-registered **before labels**, and only among items that could seat (affirmative records and own words) — a No voter can never seat, so a pair with one is unscorable. The education-gender-identity A1 v2 result (5/5 pairs built after labels) is a provisional pass only. |
| T4 | **5 blind operator labels per changed topic** (5/5, or a review of each miss); **10 for pilots** (≥ 9/10). **Ruled 2026-10-08:** when a draft seats fewer chairs than the bar needs, **wait** — collect a fresh, frozen extension of the test set until enough chairs exist, then run T4 as written; the extension's T1 is reported separately. |
| pilots (§5) | **climate-change, abortion, homelessness, education-library-books, plus minimum-wage** (tests record anchors L3/L4 and L8 at almost no cost: 2 visible chairs). |
| sixth pilot | **education-gender-identity** (added 2026-10-08, proposed by the hearing-transcript study). Tests L6 directly; 0 seats, so no carry-forward cost; a state-level test set already exists (3 opposing instruments in AZ and CA, 35 statements, 2 gold rows — `~/Documents/GitHub/.planning/research/2026-10-hearing-transcripts-as-sources.md` §12). Needs about 10 school-board policies or votes before the test runs. Started in the session "Explore hearing transcripts as own-words sources". Ruled 2026-10-08: **one topic, no split.** Two single-topic ladders are drafted and tested against the frozen set — A1 (who controls telling parents) and A2b (name and pronoun use); the one that seats more people (T1) and passes T2–T4 becomes the topic (T4: 10 blind labels each). Drop "written" from the parental-permission rung. Drafts: `docs/superpowers/specs/2026-10-08-egi-pilot-draft-ladders.md` (PR #945). |
| no-lever resolutions (2026-10-08) | **Resolves the codebook `_owed:_` in V2 "No-lever level"** (`docs/codebook/stance-and-quote-codebook.md`, "whether a member's vote for a resolution that states every clause of a rung counts as their own words"). At a level that holds no lever on the rung: (1) a resolution or failed measure the person **wrote or sponsored**, whose text states every clause of one rung, counts as their **own words** and can seat the chair (own-words stratum; `single-source` unless corroborated). (2) A **bare Yes vote** on someone else's such text counts as own words **only if contested** — at least 10% of the body voted No (the existing near-unanimous guard); a near-unanimous or ceremonial vote shows direction only. (3) Text that only urges another level without stating the rung stays `rhetorical` / direction-only. Reason (Chris Andrews): such a measure shows where the person stands even when the body cannot enact it; a "political stunt" is still a public, attributed position, and the voter sees the source. **Changes coding results → goes into codebook 0.5.** |
| sixth pilot result (2026-10-08) | **Failed.** T1: control 9%, A1 8%, A2b 0% (no annex on any ladder; 108 offline labels, no DB write). Half the 34 items could never seat (records at levels without a lever, multi-subject packages, sources not showing the person's act), and the drafts had boundaries that only silence separates. Report: `~/Documents/GitHub/.planning/research/2026-10-egi-pilot-seatability-results.md` (names test items — exposes the frozen set). **Round 2 (2026-10-08): A1 v2 passes T1 under the new rule (records 5/7 = 71% vs control 43%), own words (2 vs 1 of 17) and T2 (2/2); T3 provisional (5/5 post-hoc); T4 waits for 10 chairs (7 so far). A2b v2 approved for its own set v3 (26 items).** Earlier: redraft A1 and re-test on a fresh set drawn first (v2, 32 items); A1 v2 approved 2026-10-08 (PR #945). Revised the same day: A2b also gets a second chance — redraft after its own fresh test set (v3) is frozen. Still one topic: if both pass, the one that seats more people wins; if neither passes, the topic stays identity for Season 3** (0 visible chairs, nothing lost). |
| T6 addition (2026-10-08) | **No silence-only boundary.** Two neighbouring rungs must differ by a stated act. A difference of "every time", "even with …" or "no exception" alone fails T6, because a record never states what it leaves out. Learned from the sixth pilot (A1 rungs 3/4, A2b rungs 4/5). Applies to every ladder. |
| test-set rule (ruled 2026-10-08) | **Adopted.** Own words count at **any** level the topic is asked (CA_0302); **records** count only from a level that holds a lever and only from single-subject instruments showing the person's own act. Chris Andrews raised that no-lever opinions still matter; this wording keeps them and drops only items that can never seat. Applies to every seatability test set. |
| test-set leakage | Transcript passages whose clause matches are discussed in that report (§3, §4, §10) are marked **exposed**: they may inform a ladder draft but do not count toward its seatability test or a later certification (same rule as gold rows used to write a ladder). |
| voter re-ask (§6.3.1) | **Keep as built** (CC_0061/CC_0062): a moved or invalidated voter answer is hidden and re-asked; a reworded one is kept and prompted. No build. |
| the open (§6.3.2–3) | **No research threshold (Chris Cantrell call, 2026-10-08; replaces the pilot-scoped rule ruled earlier the same day).** Seasons switch to fix question problems, not when research reaches a set point. Research is still pre-staged in the draft season as far as it goes, and Chris Andrews decides when to open. A threshold may fit a much later season (Cantrell: "season eight, nine"). Substantive topics show an empty spoke until researched, so substantive rulings stay rare. |

For scale, the nationwide count the first version of this rule would have required — "seated now with a visible chair" (prod, 2026-10-08; visible = latest Season 1/2 answer non-blank):
taxes 1,455 · abortion 1,545 · climate-change 1,519 · homelessness 574 · minimum-wage 2 ·
education-library-books 0.

### Seasons ADR review with Chris Cantrell (call, 2026-10-08)

ADR 0005/0006 are Chris Cantrell's. Reviewed with him using a plain-language summary
(https://claude.ai/artifact/9o3bndcAgf9gWBmL4bsoc6):

- **Agreed:** research into the draft season; an answer and the ladder it answered are one unit,
  locked to their season, never compared across ladders (version-aware reads); carrying research
  forward between seasons where it still applies; widening "A and B" to "A or B".
- **Changed:** no research threshold for the open (row above).
- **Empty spoke:** no per-spoke reason for voters (noise); at most a note on the season itself.
- **Later, not Season 3:** a season selector showing a person's stance per season (like Treasury
  Tracker's year switch).
- **Carry-forward:** see "Carry-forward rule" below (ruled the same day; settles rulings owed 3 and 4).
- Still owed: who edits the ADR text, and marking ADR 0006 accepted. §7 (On the Record evidence base) is a separate spec.

### Carry-forward rule (Chris Andrews, 2026-10-08) — replaces the CA_0305 default rule, not built yet

Applies only to a topic whose Season 3 change is **substantive** (a moving rung_map). Identity and
clarifying topics carry every seat already. Seat counts are non-blank answers on the 61 Season 3
topics, prod 2026-10-08.

| group | who | seats | ruling |
|---|---|---:|---|
| A | Season 2 answer on the current revision, with reasoning | all non-chained Season 2 seats | **carry** to `rung_map[value]` (as CA_0305) |
| B | Season 2 answer on an older revision **of the current version** (the 13 chained topics; only clarifying steps between) | 394 | **carry** through the clarifying steps, then the rung_map |
| C | Season 1-only answer **on the current version** (only clarifying changes since) | 13,429 | **carry, flagged** "carried from Season 1" so research re-checks it over time, pilot cities first |
| D | Season 1-only answer on an **older version** (Season 2 changed the ladder substantively) | 14,007 | **blank** — already hidden by version-aware reads (PR #929), so nothing visible is lost |

- **Why:** the 2026-08-28 rule says a clarifying change keeps seats; blanking B and C contradicted it
  and would remove about 13,800 chairs voters see today. Chris Cantrell asked that research be
  carried forward where it still applies (call, 2026-10-08).
- **Exception:** `public-safety-approach` rev 4 is labelled clarifying, but its rationale says chairs 2
  and 3 "shifted meaning". Seats on those two rungs that pass through rev 4 are **not** carried: they
  blank or go to re-audit.
- **Caution on C:** Season 1 evidence is often weaker (bare yes votes). All 27,436 Season 1-only seats
  have a reasoning row, so reasoning does not separate strong from weak rows; the flag is what
  lets research find them.
- **Build owed:** a `CA_` migration extending `inform.repoint_season_answers` (same-version source
  rows from Season 1 and Season 2, the public-safety exception, the Season 1 flag), with the same
  rolled-back dry run CA_0305 used. Where the flag lives is a design choice for that migration.
- **Effect on this worksheet:** the "S2 would map" column and the chained group (Group 6) were
  computed under CA_0305. Under this rule the chained topics are no longer a special cost, and the
  cost of a substantive change is the group D count per topic (Appendix C).

## Cost groups

The findings doc named three buckets: free, cheap and expensive, plus the chained topics. They do
not cover all 61 topics, so two groups were added (3 and 4). Each topic is in exactly one group.
A chained topic is in Group 6 whatever its size.

| group | rule | topics |
|---|---|---:|
| 1 Free | no Season 1 or Season 2 answer | 11 |
| 2 Cheap | ≤ 12 Season 1-only and ≤ 12 Season 2 rows, Season 2 pin = current (+ surveillance-technology) | 5 |
| 3 Season 2-populated (added) | ≤ 12 Season 1-only, > 12 Season 2 rows, Season 2 pin = current | 5 |
| 4 Middle (added) | 13–1,000 Season 1-only, Season 2 pin = current | 21 |
| 5 Expensive | > 1,000 Season 1-only, Season 2 pin = current | 6 |
| 6 Chained | Season 2 pin ≠ current revision | 13 |

## Sources searched

Short names used in the evidence lines:

| short | file |
|---|---|
| S3N | `.planning/todos/2026-10-01-season-3-ladder-notes.md` (the Season 3 staging list) |
| LLD | `.planning/todos/2026-10-03-local-ladder-defects-season-3.md` |
| ORI | `.planning/todos/2026-08-12-ladder-orientation-and-consumers.md` |
| ANX/x | `docs/codebook/annex/x.md` |
| SPD | `docs/superpowers/specs/2026-09-23-stance-program-design.md` |
| S3D | `docs/superpowers/specs/2026-10-07-season3-design.md` on branch `claude/s2-seating-analysis` (draft) |
| BND | `backend/data/stance-research/2026-10-07-s2-seating-analysis/boundaries.csv` on the same branch |
| PIL | `~/Documents/GitHub/.planning/todos/2026-10-07-season3-pilot-direction-only-ladders.md` (workspace root, not in git) |
| WHY | `~/Documents/GitHub/.planning/todos/2026-10-07-why-season2-seats-fewer-chairs.md` (workspace root) |
| LEV | `~/Documents/GitHub/.planning/todos/2026-10-06-positions-without-a-lever.md` (workspace root) |
| MEM/x | Chris Andrews' local memory notes (`memory/x.md` at the workspace root; not in git) |
| RT | `.planning/todos/` file named in the line |
| CA_NNNN | migration header in `backend/migrations/` |

Also read: `compass_topic_revisions` (every revision, its status and rung_map) and
`compass_topic_roles` on prod. Line numbers are from the files as of 2026-10-07.

## Index

Group numbers match the sections below. "S2 seated" excludes blanks. ⛓ = chained. ⚠ = evidence of a problem.

| grp | topic | S2 seated | S2 blank | S1-only | voters | ⛓ | ⚠ | ruling |
|---|---|---:|---:|---:|---:|---|---|---|
| 1 | [`2020-election`](#2020-election--2020-presidential-election---evidence-of-a-problem) | 0 | 0 | 0 | 1 |  | ⚠ | |
| 1 | [`defense-spending`](#defense-spending--defense-spending---evidence-of-a-problem) | 0 | 0 | 0 | 1 |  | ⚠ | |
| 1 | [`education-ai`](#education-ai--artificial-intelligence-in-schools---evidence-of-a-problem) | 0 | 0 | 0 | 1 |  | ⚠ | |
| 1 | [`education-charter-authorization`](#education-charter-authorization--charter-schools---evidence-of-a-problem) | 0 | 0 | 0 | 1 |  | ⚠ | |
| 1 | [`education-curriculum`](#education-curriculum--curriculum-and-contested-topics---evidence-of-a-problem) | 0 | 0 | 0 | 1 |  | ⚠ | |
| 1 | [`education-equity-programs`](#education-equity-programs--equity-and-inclusion-programs-in-schools---evidence-of-a-problem) | 0 | 0 | 0 | 2 |  | ⚠ | |
| 1 | [`education-gender-identity`](#education-gender-identity--parental-notification-and-transgender-students---evidence-of-a-problem) | 0 | 0 | 0 | 1 |  | ⚠ | |
| 1 | [`education-library-books`](#education-library-books--school-library-books-and-instructional-materials---evidence-of-a-problem) | 0 | 0 | 0 | 1 |  | ⚠ | |
| 1 | [`education-school-budget`](#education-school-budget--school-budget-and-spending-priorities---evidence-of-a-problem) | 0 | 0 | 0 | 1 |  | ⚠ | |
| 1 | [`education-school-police`](#education-school-police--police-in-schools---evidence-of-a-problem) | 0 | 0 | 0 | 1 |  | ⚠ | |
| 1 | [`military-intervention`](#military-intervention--foreign-military-intervention---evidence-of-a-problem) | 0 | 0 | 0 | 1 |  | ⚠ | |
| 2 | [`border-security`](#border-security--border-security---evidence-of-a-problem) | 12 | 0 | 0 | 3 |  | ⚠ | |
| 2 | [`judicial-police-accountability`](#judicial-police-accountability--police-accountability---evidence-of-a-problem) | 0 | 0 | 12 | 3 |  | ⚠ | |
| 2 | [`judicial-bail-pretrial`](#judicial-bail-pretrial--bail-and-pretrial-decisions---evidence-of-a-problem) | 0 | 0 | 6 | 3 |  | ⚠ | |
| 2 | [`minimum-wage`](#minimum-wage--minimum-wage---evidence-of-a-problem) | 2 | 0 | 0 | 1 |  | ⚠ | |
| 2 | [`surveillance-technology`](#surveillance-technology--surveillance-technology-and-police-data-collection---evidence-of-a-problem) | 0 | 0 | 0 | 0 |  | ⚠ | |
| 3 | [`housing`](#housing--affordable-housing---evidence-of-a-problem) | 1782 | 39 | 0 | 6 |  | ⚠ | |
| 3 | [`same-sex-marriage`](#same-sex-marriage--same-sex-marriage---evidence-of-a-problem) | 866 | 35 | 0 | 8 |  | ⚠ | |
| 3 | [`cannabis-policy`](#cannabis-policy--cannabis-policy) | 116 | 0 | 0 | 1 |  |  | |
| 3 | [`ranked-choice-voting`](#ranked-choice-voting--ranked-choice-voting-and-electoral-method---evidence-of-a-problem) | 75 | 0 | 0 | 1 |  | ⚠ | |
| 3 | [`israel-military-aid`](#israel-military-aid--us-military-aid-to-israel---evidence-of-a-problem) | 47 | 0 | 0 | 1 |  | ⚠ | |
| 4 | [`campaign-finance`](#campaign-finance--campaign-finance-reform---evidence-of-a-problem) | 2 | 5 | 834 | 4 |  | ⚠ | |
| 4 | [`childcare`](#childcare--childcare-affordability--access---evidence-of-a-problem) | 21 | 15 | 761 | 6 |  | ⚠ | |
| 4 | [`economic-development`](#economic-development--economic-development-incentives---evidence-of-a-problem) | 24 | 27 | 668 | 4 |  | ⚠ | |
| 4 | [`religious-freedom`](#religious-freedom--religious-freedom---evidence-of-a-problem) | 2 | 3 | 683 | 8 |  | ⚠ | |
| 4 | [`redistricting`](#redistricting--state-redistricting-and-gerrymandering---evidence-of-a-problem) | 2 | 10 | 674 | 4 |  | ⚠ | |
| 4 | [`homelessness`](#homelessness--criminalization-of-homelessness---evidence-of-a-problem) | 4 | 1 | 637 | 7 |  | ⚠ | |
| 4 | [`ai-regulation`](#ai-regulation--artificial-intelligence-oversight---evidence-of-a-problem) | 0 | 7 | 597 | 3 |  | ⚠ | |
| 4 | [`social-security`](#social-security--social-security---evidence-of-a-problem) | 2 | 7 | 589 | 8 |  | ⚠ | |
| 4 | [`homelessness-response`](#homelessness-response--homelessness-response---evidence-of-a-problem) | 3 | 0 | 440 | 4 |  | ⚠ | |
| 4 | [`growth-and-development`](#growth-and-development--growth-and-development-pace---evidence-of-a-problem) | 9 | 1 | 428 | 4 |  | ⚠ | |
| 4 | [`misinformation`](#misinformation--misinformation-and-the-role-of-algorithms-in-democracy---evidence-of-a-problem) | 0 | 5 | 364 | 4 |  | ⚠ | |
| 4 | [`local-environment`](#local-environment--environmental-protection-vs-development) | 2 | 12 | 345 | 3 |  |  | |
| 4 | [`judicial-criminal-justice`](#judicial-criminal-justice--criminal-justice-approach---evidence-of-a-problem) | 3 | 4 | 283 | 3 |  | ⚠ | |
| 4 | [`data-centers`](#data-centers--data-center-development--energy-costs---evidence-of-a-problem) | 2 | 2 | 280 | 6 |  | ⚠ | |
| 4 | [`rent-regulation`](#rent-regulation--rent-regulation---evidence-of-a-problem) | 17 | 1 | 228 | 4 |  | ⚠ | |
| 4 | [`city-sanitation`](#city-sanitation--city-sanitation-and-cleanliness---evidence-of-a-problem) | 1 | 0 | 113 | 3 |  | ⚠ | |
| 4 | [`judicial-interpretation`](#judicial-interpretation--judicial-interpretation---evidence-of-a-problem) | 0 | 0 | 71 | 3 |  | ⚠ | |
| 4 | [`judicial-access-to-justice`](#judicial-access-to-justice--access-to-justice---evidence-of-a-problem) | 0 | 0 | 48 | 3 |  | ⚠ | |
| 4 | [`judicial-transparency`](#judicial-transparency--transparency-in-legal-proceedings) | 0 | 0 | 34 | 3 |  |  | |
| 4 | [`judicial-government-deference`](#judicial-government-deference--judicial--prosecutorial-discretion---evidence-of-a-problem) | 0 | 0 | 22 | 3 |  | ⚠ | |
| 4 | [`judicial-prosecution-priorities`](#judicial-prosecution-priorities--prosecution-priorities---evidence-of-a-problem) | 0 | 0 | 20 | 2 |  | ⚠ | |
| 5 | [`climate-change`](#climate-change--climate-change-and-environmental-protection---evidence-of-a-problem) | 6 | 54 | 1,842 | 8 |  | ⚠ | |
| 5 | [`civil-rights`](#civil-rights--civil-rights-and-social-justice---evidence-of-a-problem) | 9 | 32 | 1,536 | 8 |  | ⚠ | |
| 5 | [`voting-rights`](#voting-rights--voting-rights-and-electoral-integrity---evidence-of-a-problem) | 0 | 46 | 1,475 | 6 |  | ⚠ | |
| 5 | [`deportation`](#deportation--deportation-priorities---evidence-of-a-problem) | 17 | 22 | 1,319 | 6 |  | ⚠ | |
| 5 | [`school-vouchers`](#school-vouchers--school-vouchers--public-education-funding---evidence-of-a-problem) | 1 | 14 | 1,216 | 4 |  | ⚠ | |
| 5 | [`medicare/aid`](#medicareaid--medicare--medicaid---evidence-of-a-problem) | 6 | 7 | 1,131 | 6 |  | ⚠ | |
| 6 | [`taxes`](#taxes--taxation-and-public-spending---chained---evidence-of-a-problem) | 42 | 39 | 1,940 | 4 | ⛓ | ⚠ | |
| 6 | [`abortion`](#abortion--reproductive-rights-and-abortion-access---chained---evidence-of-a-problem) | 34 | 27 | 1,850 | 8 | ⛓ | ⚠ | |
| 6 | [`healthcare`](#healthcare--healthcare-access---chained---evidence-of-a-problem) | 20 | 34 | 1,741 | 3 | ⛓ | ⚠ | |
| 6 | [`fossil-fuels`](#fossil-fuels--fossil-fuel-policy---chained---evidence-of-a-problem) | 8 | 16 | 1,319 | 6 | ⛓ | ⚠ | |
| 6 | [`public-safety-approach`](#public-safety-approach--public-safety-approach---chained---evidence-of-a-problem) | 43 | 23 | 801 | 3 | ⛓ | ⚠ | |
| 6 | [`trans-athletes`](#trans-athletes--transgender-athletes---chained---evidence-of-a-problem) | 2 | 5 | 854 | 7 | ⛓ | ⚠ | |
| 6 | [`tariffs`](#tariffs--united-states-tariff-policy---chained---evidence-of-a-problem) | 2 | 4 | 657 | 8 | ⛓ | ⚠ | |
| 6 | [`local-immigration`](#local-immigration--local-immigration-enforcement---chained---evidence-of-a-problem) | 11 | 4 | 555 | 5 | ⛓ | ⚠ | |
| 6 | [`transportation-priorities`](#transportation-priorities--transportation-priorities---chained---evidence-of-a-problem) | 117 | 16 | 428 | 3 | ⛓ | ⚠ | |
| 6 | [`ukraine-support`](#ukraine-support--ukraine---russia-conflict---chained---evidence-of-a-problem) | 1 | 6 | 460 | 7 | ⛓ | ⚠ | |
| 6 | [`residential-zoning`](#residential-zoning--residential-zoning---chained---evidence-of-a-problem) | 8 | 84 | 355 | 5 | ⛓ | ⚠ | |
| 6 | [`jail-capacity`](#jail-capacity--jail-capacity-and-incarceration-alternatives---chained---evidence-of-a-problem) | 9 | 7 | 291 | 3 | ⛓ | ⚠ | |
| 6 | [`gun-policy`](#gun-policy--gun-policy---chained---evidence-of-a-problem) | 97 | 0 | 0 | 1 | ⛓ | ⚠ | |

## Group 1. Free: no politician answers (11 topics)

No Season 1 or Season 2 politician answer exists. Any ruling costs nothing on the politician side. Voter rows only.

### `2020-election` — 2020 Presidential Election · ⚠ evidence of a problem

Question: What is your view of the outcome of the 2020 presidential election?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-08-29.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.
- **Orientation:** Off-axis (belief, not policy). Source: ANX/2020-election:10-12.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | The election was fair and Joe Biden won legitimately. | 0 | 0 | 0 |
| 2 | Joe Biden won, but the election had real problems worth fixing. | 0 | 0 | 0 |
| 3 | There was some fraud, but not enough to change the result. | 0 | 0 | 0 |
| 4 | Fraud or irregularities may have been enough to change the result. | 0 | 0 | 0 |
| 5 | The election was stolen from Donald Trump through widespread fraud. | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - A belief ladder with no lever at any level (own words only). ANX/2020-election:31.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `defense-spending` — Defense Spending · ⚠ evidence of a problem

Question: How much should the government spend on the military?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-09-01.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `own-words`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Increase military spending substantially, launching a major buildup to expand the armed forces and their capabilities. | 0 | 0 | 0 |
| 2 | Increase military spending moderately, growing the budget above inflation to keep pace with rising threats. | 0 | 0 | 0 |
| 3 | Hold military spending roughly flat, allowing it to rise only with inflation. | 0 | 0 | 0 |
| 4 | Reduce military spending modestly below current levels. | 0 | 0 | 0 |
| 5 | Cut military spending dramatically, roughly halving the budget or more. | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - A force-posture second axis was excluded on purpose; five foreign-policy topics converge, and pruning is owed to Chris. MEM/defense-spending-new-topic-ca0091:27-31, 50-54.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `education-ai` — Artificial Intelligence in Schools · ⚠ evidence of a problem

Question: What role should artificial intelligence play in classrooms and student work?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-08-31.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `own-words`, local `own-words`, school `record`, state `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Prohibit artificial intelligence tools in student work and classroom instruction | 0 | 0 | 0 |
| 2 | Restrict artificial intelligence to teacher planning and administrative use, keeping it out of student work | 0 | 0 | 0 |
| 3 | Permit students to use artificial intelligence on designated assignments, with disclosure required | 0 | 0 | 0 |
| 4 | Encourage broad classroom use of artificial intelligence with light guidelines and teacher discretion | 0 | 0 | 0 |
| 5 | Let teachers and students use artificial intelligence freely, without restrictions | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Rung 4 "light guidelines" vs "teacher discretion" are hard to evidence separately. S3N:106-107.
  - No city lever (re-labelled own-words). CA_0302 header.
  - All eight education topics carry a `local` role that no city council can answer. LLD:144-154.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `education-charter-authorization` — Charter Schools · ⚠ evidence of a problem

Question: How should the board handle charter schools that want to open in the district?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-08-31.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** local `record`, school `record`, state `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Stop authorizing new charter schools and move to close existing ones | 0 | 0 | 0 |
| 2 | Approve new charters rarely, only when a school is clearly failing students | 0 | 0 | 0 |
| 3 | Judge each charter application on its own merits | 0 | 0 | 0 |
| 4 | Welcome charters and approve strong applications to expand family options | 0 | 0 | 0 |
| 5 | Convert failing district schools into charters run by independent operators | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Rung 2 referent. S3N:101-102.
  - Not asked at federal ("the board"). LEV §10.
  - All eight education topics carry a `local` role that no city council can answer. LLD:144-154.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `education-curriculum` — Curriculum and Contested Topics · ⚠ evidence of a problem

Question: How should schools handle contested topics like race, gender, and history in what they teach?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-08-31.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `own-words`, local `record`, school `record`, state `record`.
- **Orientation:** Off-axis (both ends are mandates). Source: ANX/education-curriculum:10-13.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Require lessons that center race, gender, and social justice as themes across the curriculum | 0 | 0 | 0 |
| 2 | Teach an honest account of racism, injustice, and diverse identities as part of the core curriculum | 0 | 0 | 0 |
| 3 | Present contested social and historical topics as open questions, giving competing viewpoints equal weight | 0 | 0 | 0 |
| 4 | Keep the curriculum focused on core academics and leave contested social topics to families | 0 | 0 | 0 |
| 5 | Prohibit lessons on race, gender, or sexuality that the community considers divisive or age-inappropriate | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Rung 5 "community considers" is vague; rung 1 is a triple compound. S3N:91-93.
  - All eight education topics carry a `local` role that no city council can answer. LLD:144-154.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `education-equity-programs` — Equity and Inclusion Programs in Schools · ⚠ evidence of a problem

Question: How should schools address gaps in achievement and opportunity between groups of students?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-08-31.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 2 (live 2: S2 2).
- **Asked of (compass_topic_roles):** federal `own-words`, local `record`, school `record`, state `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Fund dedicated equity offices and staff to close gaps between student groups | 0 | 0 | 0 |
| 2 | Require equity training for staff and set measurable goals to close gaps between groups | 0 | 0 | 0 |
| 3 | Measure results for each student group and steer extra support to those falling behind | 0 | 0 | 0 |
| 4 | Offer the same supports to every struggling student, without grouping them by race or identity | 0 | 0 | 0 |
| 5 | Eliminate equity programs, training, and staff from the district | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Rung 5 "from the district" fits school boards only; triple compound. S3N:103-104.
  - All eight education topics carry a `local` role that no city council can answer. LLD:144-154.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `education-gender-identity` — Parental Notification and Transgender Students · ⚠ evidence of a problem

Question: What should schools do when a student uses a different name or gender identity at school than at home?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-08-31.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `own-words`, local `own-words`, school `record`, state `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Use the student's chosen name and pronouns, and keep their gender identity from parents unless the student agrees to share it | 0 | 0 | 0 |
| 2 | Use the student's chosen name and pronouns, and tell parents only if they directly ask | 0 | 0 | 0 |
| 3 | Tell parents when a student changes their name or gender at school, unless staff believe it would put the student in danger | 0 | 0 | 0 |
| 4 | Require staff to notify parents whenever a student asks to be treated as a different gender at school | 0 | 0 | 0 |
| 5 | Require written parental permission before staff use a student's chosen name or pronouns | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - No rung for a flat ban on chosen names or pronouns (gap). S3N:105; ANX/education-gender-identity:85-86.
  - All eight education topics carry a `local` role that no city council can answer. LLD:144-154.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `education-library-books` — School Library Books and Instructional Materials · ⚠ evidence of a problem

Question: How should schools handle challenges to books in libraries and classrooms?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-08-31.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `own-words`, local `record`, school `record`, state `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Keep every book available and let professional librarians and educators curate the collection | 0 | 0 | 0 |
| 2 | Keep challenged books available to all, while letting parents limit what their own child can borrow | 0 | 0 | 0 |
| 3 | Remove a challenged book only if a review committee of educators and parents finds it unsuitable | 0 | 0 | 0 |
| 4 | Pull any book a parent challenges until it has been reviewed | 0 | 0 | 0 |
| 5 | Remove any book a parent or community member reports as inappropriate, for all students | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Rung 3 is double-barrelled (review finding + educators-and-parents committee). Rung 1 "every book" conflicts with routine weeding. S3N:87-90.
  - Proposal c-lib re-seats 2 gold rows; pilot topic for the draft rulebook. PIL:79; S3D.
  - All eight education topics carry a `local` role that no city council can answer. LLD:144-154.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `education-school-budget` — School Budget and Spending Priorities · ⚠ evidence of a problem

Question: How should schools set spending levels and decide whether to raise more revenue?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-08-31.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `own-words`, local `record`, school `record`, state `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Raise taxes to significantly increase school funding | 0 | 0 | 0 |
| 2 | Increase funding modestly to keep pace with costs, without raising taxes | 0 | 0 | 0 |
| 3 | Hold funding flat at current levels | 0 | 0 | 0 |
| 4 | Cut administrative overhead to lower costs while protecting classroom funding | 0 | 0 | 0 |
| 5 | Cut school funding significantly to reduce the taxes residents pay | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Gaps: no rung for a modest increase paid by a tax, none for a large increase with no tax. Rung 4 is about composition, not level. S3N:94-97.
  - All eight education topics carry a `local` role that no city council can answer. LLD:144-154.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `education-school-police` — Police in Schools · ⚠ evidence of a problem

Question: What role should police officers play in schools?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-08-31.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `own-words`, local `record`, school `record`, state `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Remove police officers from schools and rely on counselors and mental health staff | 0 | 0 | 0 |
| 2 | Keep officers out of schools and call them only when a serious crime occurs | 0 | 0 | 0 |
| 3 | Bring in a shared or part-time officer with a limited, clearly defined role | 0 | 0 | 0 |
| 4 | Place a dedicated officer in every school for safety, but bar them from routine discipline | 0 | 0 | 0 |
| 5 | Place an officer in every school with authority to handle discipline and make arrests on campus | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Rung 5 "make arrests" adds nothing; rungs 1/2 are compounds. S3N:98-100.
  - All eight education topics carry a `local` role that no city council can answer. LLD:144-154.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `military-intervention` — Foreign Military Intervention · ⚠ evidence of a problem

Question: How should the United States use military force abroad?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-09-01.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `own-words`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Use US military power to actively lead and police conflicts around the world. | 0 | 0 | 0 |
| 2 | Intervene militarily when clear US interests or allied nations are directly threatened. | 0 | 0 | 0 |
| 3 | Prefer diplomacy and economic sanctions, using military force only as a last resort. | 0 | 0 | 0 |
| 4 | Avoid overseas military action except to defend US territory from direct attack. | 0 | 0 | 0 |
| 5 | Withdraw from overseas military commitments and end foreign military intervention. | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Vote ladder where a No vote proves nothing (one row). BND.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

## Group 2. Cheap: 12 or fewer people in each season, Season 2 pin = current (5 topics)

A moving map touches 12 or fewer Season 2 rows and 12 or fewer Season 1-only people. `surveillance-technology` is here too: it has no Season 1 or Season 2 answer, but it already has 17 seated Season 3 rows on rev 1. Any new revision must first delete or rewrite those 17 rows, because the pin foreign keys have no cascade.

### `border-security` — Border Security · ⚠ evidence of a problem

Question: How should the government handle people who cross the border?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-08-29.
- **Counts:** Season 2 rows 12 (0 blank, 12 seated) · would map under the default rule 12 · Season 1-only 0 · voter rows 3 (live 3: S2 3).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `own-words`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Give everyone who crosses the border a fair asylum hearing. | 0 | 0 | 0 |
| 2 | Expand orderly, legal ways to seek asylum at the border. | 3 | 3 | 0 |
| 3 | Combine strong enforcement with a faster asylum process. | 9 | 9 | 0 |
| 4 | Sharply restrict who can claim asylum at the border. | 0 | 0 | 0 |
| 5 | End asylum and quickly turn back anyone who crosses illegally. | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Rung 5 "End asylum": at the border, or the whole system? S3N:204-205.
  - Federal-only record role, inconsistent with deportation. LEV:27-34.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `judicial-police-accountability` — Police Accountability · ⚠ evidence of a problem

Question: When a government employee is accused of misconduct, should the office defend them or hold them accountable?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 12 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** judicial `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Single-revision review 2026-09-01 (Chris Andrews). Core defect: judicial_role = city_attorney_da bundles two offices with different accountability levers, but v1 chairs 2-5 were written as one office's instrument — ci...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Actively hold government employees accountable when they do wrong, even when they are on the office's own side. | 0 | 0 | 4 |
| 2 | Take misconduct complaints seriously, and act on the ones that hold up. | 0 | 0 | 2 |
| 3 | Defend government employees when a complaint is weak, and hold them accountable when it has merit. | 0 | 0 | 4 |
| 4 | Give government employees the benefit of the doubt, and act only when the wrongdoing is clear. | 0 | 0 | 2 |
| 5 | Stand behind government employees and defend their conduct rather than hold them accountable. | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Investigate independently. The office works for the public — not the officials it's supposed to keep accountable. **(differs)**
2. Settle valid claims quickly and pursue real accountability. Defending misconduct wastes money and public trust. **(differs)**
3. Represent the government fairly while acknowledging when claims have merit. **(differs)**
4. Defend government employees vigorously. That's the job. Settlements invite more lawsuits. **(differs)**
5. The client is the government. Defending its employees and decisions — aggressively when needed — is the core function. **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Evidence of a problem:**
  - Rungs 2/3 overlap. S3N:78-80.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `judicial-bail-pretrial` — Bail and Pretrial Decisions · ⚠ evidence of a problem

Question: Should a judge trust what prosecutors say, or watch them closely?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 3 (v2, published) · S3 rev 3 (v2, published). Current = rev 3 v2, `substantive`, published 2026-08-28.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 6 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** judicial `record`.
- **Orientation:** Off-axis. Source: ANX/judicial-bail-pretrial:9-12.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): ORIGIN: written by an automated content audit on 2026-08-24 while building this review workflow (ADR 0004). No human authored it, and proposed_by is deliberately NULL. An earlier attempt was attributed to chrisandrews...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Watch closely. Prosecutors have enormous power and real incentives to win. A judge's job is to make sure that power is used fairly. | 0 | 0 | 0 |
| 2 | Be skeptical. Hold prosecution to strict standards — especially on evidence handling and plea deals. | 0 | 0 | 4 |
| 3 | Treat both sides equally and let the process work. | 0 | 0 | 2 |
| 4 | Give prosecutors reasonable deference. They're trained professionals representing the public. | 0 | 0 | 0 |
| 5 | Trust prosecutors. They represent the community and have already screened the case — judges shouldn't second-guess that judgment. | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map null.
- **Evidence of a problem:**
  - Key and title do not match the rungs (no rung mentions bail). Rungs 1/2 are not clearly ordered. S3N:66-69.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `minimum-wage` — Minimum Wage · ⚠ evidence of a problem

Question: What approach should government take to the minimum wage?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-09-01.
- **Counts:** Season 2 rows 2 (0 blank, 2 seated) · would map under the default rule 2 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Raise the wage floor and tie it to the cost of living, so it rises automatically each year without new legislation. | 2 | 2 | 0 |
| 2 | Raise the wage floor to a set higher level, then adjust it only when lawmakers vote to. | 0 | 0 | 0 |
| 3 | Keep a modest national wage floor as a baseline and let states and cities set higher rates. | 0 | 0 | 0 |
| 4 | Hold the wage floor at its current level and let the market set pay above it. | 0 | 0 | 0 |
| 5 | Remove the wage floor entirely and let employers and workers set pay by agreement. | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Rung 3 says "national" (no lever at state). `~/Documents/GitHub/.planning/todos/2026-10-02-season3-minimum-wage-rung3-national.md`:1-18; S3N:144-145.
  - Tipped and youth carve-outs fit no rung. Proposal c11. PIL:77.
  - Rung 1 bundles "raise + index" on purpose. MEM/minimum-wage-new-topic-ca0092:21-24.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `surveillance-technology` — Surveillance Technology and Police Data Collection · ⚠ evidence of a problem

Question: How should your community use surveillance technology like license plate readers and facial recognition?

- **Pins:** S3 rev 1 (v1, published) · S1: not pinned · S2: not pinned. Current = rev 1 v1, `substantive`, published 2026-09-12.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 0 (live 0: none).
- **Season 3 rows already written:** 17 (all seated, on the current pin). A new revision cannot be pinned until they are deleted or rewritten.
- **Asked of (compass_topic_roles):** local `record`, state `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Prohibit the city from acquiring or operating face recognition, predictive policing, and similar surveillance systems. | 0 | 0 | 0 |
| 2 | Allow specific tools only with council approval and a published use policy, strict retention limits, and no outside data sharing. | 0 | 0 | 0 |
| 3 | Let the police department decide deployments under its own written policy, with regular public reporting after the fact. | 0 | 0 | 0 |
| 4 | Use surveillance technology routinely as a standard investigative tool and share data with other law enforcement agencies. | 0 | 0 | 0 |
| 5 | Build out citywide camera and license plate reader networks with real-time monitoring, integrated with state and federal databases. | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Rungs say "the city" and "citywide", but the topic has a `state` role. Rung 2 has four clauses (P1). SPD §12.2.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

## Group 3. Season 2-populated: few Season 1-only people, many Season 2 rows, Season 2 pin = current (5 topics)

Not one of the three buckets in the findings doc. These carry many Season 2 rows. Under the default rule each non-blank Season 2 row maps to its new rung, so a moving map re-seats real research. A material rewrite needs a re-audit of those rows (ruling 2026-08-28).

### `housing` — Affordable Housing · ⚠ evidence of a problem

Question: What role should government play in making sure people can afford housing?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 3 (v2, published) · S3 rev 3 (v2, published). Current = rev 3 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 1,821 (39 blank, 1,782 seated) · would map under the default rule 1,782 · Season 1-only 0 · voter rows 6 (live 6: S1 4, S2 2).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.
- **Orientation:** Mid-ladder divergence: rung 4 is right for YIMBY rows and wrong for tenant-protection rows. Source: ORI:24-25.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Five-chair v2 reshuffle for Season 2 (CA_0043). Supersedes the parked rev 2 (chair-2-only fix). Mutually-exclusive chairs by how far government should go: (1) main provider / universal public housing; (2) NEW public o...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Make government the main provider — build and operate public housing so everyone is guaranteed a home. | 106 | 106 | 0 |
| 2 | Build a large public housing sector that competes with the private market to hold prices down, while private housing stays the norm. | 7 | 7 | 0 |
| 3 | Build no public housing, but set binding rules on the private market like rent caps or required affordable units. | 757 | 757 | 0 |
| 4 | Set no binding rules, but offer subsidies and tax breaks so more affordable housing gets built. | 676 | 676 | 0 |
| 5 | Rely on the market to set prices and supply — at most, cut the regulations and zoning limits that block private building. | 236 | 236 | 0 |
| 0 | *(blank)* | 39 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Directly build and operate public housing so anyone who needs a home can get one **(differs)**
2. Use rent caps, require new developments to include affordable units, and publicly fund new housing **(differs)**
3. Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits **(differs)**
4. Cut regulations and zoning rules so private developers can build more housing **(differs)**
5. Stay out of housing entirely and let the market decide prices and supply **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Candidate map (not a decision):** Prior map, already published S1→S2 (not an S3 candidate): `{"1":1,"2":3,"3":4,"4":5,"5":5}`, `CA_0043_housing_v2_five_chair_reshuffle.sql`:74, 80.
- **Evidence of a problem:**
  - No home for demand-side aid such as vouchers (gap). S3N:152-153; PIL:50.
  - The "at most" ceiling blocks records. Proposal c1 carries a YIMBY trap; zoning may belong in residential-zoning. PIL:15, 67; WHY:120.
  - Rung 4 "no binding rules" is the legal default in NC and FL. LLD:69-82.
  - The S1→S2 rung_map reshuffle re-audit never ran. MEM/compass-topic-notes-index:40.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `same-sex-marriage` — Same-Sex Marriage · ⚠ evidence of a problem

Question: What legal recognition should same-sex marriages receive?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 901 (35 blank, 866 seated) · would map under the default rule 866 · Season 1-only 0 · voter rows 8 (live 6: S1 5, S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Single-revision review 2026-08-31 (Chris Andrews). Two structural fixes plus a styling sweep. (1) ONE SPECTRUM: old chair 3 ("let each state decide … without federal interference") measured WHO decides, not how much r...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Guarantee same-sex couples full legal equality — equal marriage plus protection from discrimination (such as in jobs and housing). | 0 | 0 | 0 |
| 2 | Guarantee same-sex marriage the same benefits and protections as any other marriage. | 488 | 488 | 0 |
| 3 | Allow same-sex marriage, but protect religious organizations' right to decline to perform or host these marriages. | 145 | 145 | 0 |
| 4 | Recognize civil unions for same-sex couples, but reserve marriage for opposite-sex couples. | 60 | 60 | 0 |
| 5 | Make same-sex marriage illegal and define marriage as only between one man and one woman. | 173 | 173 | 0 |
| 0 | *(blank)* | 35 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. require all states to recognize same-sex marriages and provide full federal benefits and protections. **(differs)**
2. allow same-sex marriage nationwide while protecting some organizations' right to decline participation. **(differs)**
3. let each state decide its own same-sex marriage laws without federal interference. **(differs)**
4. recognize civil unions for same-sex couples but reserve marriage for opposite-sex couples. **(differs)**
5. make same-sex marriage illegal and define marriage as only between one man and one woman. **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Candidate map (not a decision):** Prior map, already published S1→S2 (not an S3 candidate): `{"1":2,"2":3,"3":"invalidated","4":4,"5":5}`, `CA_0074`:69-70, 117.
- **Evidence of a problem:**
  - Rung 5 "illegal" invites a criminal reading; a clarifying reword is listed. `~/Documents/GitHub/.planning/todos/2026-10-03-season3-same-sex-marriage-rung5-illegal.md`:1-14.
  - Rungs 2/3 overlap for laws with a religious carve-out. S3N:172-173.
  - Rung 1 is a new double-barrel (marriage + non-discrimination), P6. SPD §12.2; MEM/same-sex-marriage-v2-split-ca0074:43.
  - No lever at local; 61–122 legacy local chairs. LEV:84-89.
  - Re-audit owed: 57 rows citing the RFMA. RT `.planning/todos/2026-10-01-annex-rulings-reaudit.md`.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `cannabis-policy` — Cannabis Policy

Question: How should the government regulate cannabis?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-09-01.
- **Counts:** Season 2 rows 116 (0 blank, 116 seated) · would map under the default rule 116 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Keep cannabis fully illegal and enforce criminal penalties for possessing or selling it. | 0 | 0 | 0 |
| 2 | Allow cannabis only for medical use, available to patients with a physician's authorization. | 0 | 0 | 0 |
| 3 | Remove criminal penalties for personal possession, replacing them with civil fines, but keep commercial sales illegal. | 0 | 0 | 0 |
| 4 | Legalize recreational cannabis and regulate it through a licensed, taxed commercial market. | 116 | 116 | 0 |
| 5 | Legalize cannabis and treat it like an ordinary legal product, with minimal restrictions on growing and using it. | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:** none found in the sources listed under "Sources searched".

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `ranked-choice-voting` — Ranked-Choice Voting and Electoral Method · ⚠ evidence of a problem

Question: How should votes be cast and counted in elections?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-09-02.
- **Counts:** Season 2 rows 75 (0 blank, 75 seated) · would map under the default rule 75 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Replace winner-take-all elections with proportional ranked-choice voting — ranked ballots fill several seats at once, so seats reflect how everyone voted. | 0 | 0 | 0 |
| 2 | Adopt ranked-choice voting for single-winner offices: voters rank candidates, and if a top choice can't win, the vote shifts to the next choice until someone has a majority. | 1 | 1 | 0 |
| 3 | Allow ranked-choice voting where communities choose it, while keeping single-choice voting as the standard. | 0 | 0 | 0 |
| 4 | Keep single-choice voting and oppose adopting ranked-choice voting, but stop short of banning it. | 0 | 0 | 0 |
| 5 | Ban ranked-choice voting by law. | 74 | 74 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Rung 5 "ban by law" equals state preemption (FL 101.019). LLD:56.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `israel-military-aid` — U.S. Military Aid to Israel · ⚠ evidence of a problem

Question: What level of military aid should the U.S. provide to Israel?

- **Pins:** S2 rev 1 (v1, published) · S3 rev 1 (v1, published) · S1: not pinned. Current = rev 1 v1, `substantive`, published 2026-09-01.
- **Counts:** Season 2 rows 47 (0 blank, 47 seated) · would map under the default rule 47 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `own-words`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Continue full military aid to Israel with no new conditions. | 43 | 43 | 0 |
| 2 | Continue aid to Israel, but require it to comply with humanitarian and human-rights law. | 0 | 0 | 0 |
| 3 | Block offensive weapons sales while continuing defensive support such as missile defense. | 4 | 4 | 0 |
| 4 | Sharply cut military aid to Israel as a step toward ending it. | 0 | 0 | 0 |
| 5 | End all military aid to Israel. | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - "No new conditions" vs "comply with humanitarian law": one bill was read both ways. PIL:22.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

## Group 4. Middle: 13 to 1,000 Season 1-only people, Season 2 pin = current (21 topics)

Not one of the three buckets in the findings doc. A moving map blanks every Season 1-only person (default rule) and maps the Season 2 rows.

### `campaign-finance` — Campaign Finance Reform · ⚠ evidence of a problem

Question: What rules should govern money in political campaigns and elections?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 3 (v2, published) · S3 rev 3 (v2, published). Current = rev 3 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 7 (5 blank, 2 seated) · would map under the default rule 2 · Season 1-only 834 · voter rows 4 (live 4: S1 4).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Single-axis rebuild of the campaign-finance ladder. All five rungs now measure one lever — how much government limits private money in campaigns (1 = replace it, 5 = no limits). The prior option 3 ("require full discl...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Ban all private money in political campaigns | 0 | 0 | 101 |
| 2 | Strictly limit corporate and dark-money spending | 2 | 2 | 504 |
| 3 | Keep contribution limits at current levels | 0 | 0 | 98 |
| 4 | Reduce restrictions on political donations and spending | 0 | 0 | 122 |
| 5 | Eliminate all campaign finance laws and limits | 0 | 0 | 9 |
| 0 | *(blank)* | 5 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. ban all private money in politics and publicly fund campaigns **(differs)**
2. strictly limit corporate donations and dark money groups **(differs)**
3. require full disclosure of all political donations **(differs)**
4. reduce restrictions on political donations and spending **(differs)**
5. eliminate all campaign finance laws and limits **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rung 5 still covers disclosure laws after the disclosure split. S3N:179-181.
  - Rung 1 "ban all private money" is an unreachable absolute (P5). SPD §12.2.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `childcare` — Childcare Affordability & Access · ⚠ evidence of a problem

Question: How should government address the cost and availability of childcare?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 36 (15 blank, 21 seated) · would map under the default rule 21 · Season 1-only 761 · voter rows 6 (live 6: S1 5, S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Double-barrel split batch (full conjunction-screen triage, decision 2026-08-28 "file them all"). Chair 4 (85 seated): Deregulation (licensing, ratios) and a means-tested subsidy floor are qualitatively different lever...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Establishing publicly funded universal childcare so that all families have access regardless of income | 1 | 1 | 103 |
| 2 | Significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families | 20 | 20 | 474 |
| 3 | Offering targeted tax credits and subsidies for families below a set income threshold while supporting providers through training and facility grants | 0 | 0 | 92 |
| 4 | Limiting government support to childcare subsidies for the lowest-income families, relying on the private market for everyone else | 0 | 0 | 72 |
| 5 | Leaving childcare to the private market and families, with no government subsidies or mandates that increase costs for providers and taxpayers | 0 | 0 | 20 |
| 0 | *(blank)* | 15 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Establishing publicly funded universal childcare so that all families have access regardless of income
2. Significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families
3. Offering targeted tax credits and subsidies for families below a set income threshold while supporting providers through training and facility grants
4. Reducing regulations on childcare providers to increase supply and lower costs, with limited subsidies reserved for the lowest-income families **(differs)**
5. Leaving childcare to the private market and families, with no government subsidies or mandates that increase costs for providers and taxpayers

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Candidate map (not a decision):** identity — candidate from `CA_0036_childcare_chair4_v2_park.sql`:21. The same header (lines 57-61) says identity is false for 12 orphan rows.
- **Evidence of a problem:**
  - Rungs 2/3 overlap. S3N:141-143.
  - At local it is a funding ladder; the city lever is zoning (gap). LLD:248-270.
  - The parked v2 of rung 4 dropped the deregulation clause. CA_0036 header.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `economic-development` — Economic Development Incentives · ⚠ evidence of a problem

Question: How should government attract businesses and support economic development?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 51 (27 blank, 24 seated) · would map under the default rule 24 · Season 1-only 668 · voter rows 4 (live 4: S1 4).
- **Asked of (compass_topic_roles):** federal `own-words`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Single-revision review 2026-08-31 (Chris Andrews). The ladder is one sound axis — how far government goes to hand companies public money/help to attract them (none -> largest, no strings) — so no re-axis. Chairs 1-3 r...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Don't give companies tax breaks or subsidies. Invest in public services and infrastructure so businesses want to come on their own. | 2 | 2 | 39 |
| 2 | Help small and local businesses grow, but don't offer subsidies to attract large outside companies. | 5 | 5 | 270 |
| 3 | Offer incentives to attract businesses, but only if they commit to good wages and local hiring — and pay the money back if they don't deliver. | 10 | 10 | 227 |
| 4 | Offer large tax breaks and infrastructure to attract major employers, but keep limits and pass on deals that cost too much. | 7 | 7 | 116 |
| 5 | Offer the largest incentives to attract any large employer, with no conditions or spending limits. | 0 | 0 | 16 |
| 0 | *(blank)* | 27 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. No corporate tax incentives; invest in public services and infrastructure to attract business organically **(differs)**
2. Small business support and local entrepreneur programs only; avoid large corporate subsidies **(differs)**
3. Targeted incentives for specific industries with community benefit agreements and job quality requirements **(differs)**
4. Compete actively for major employers with significant tax abatements and infrastructure investment **(differs)**
5. Offer maximum incentives to attract any large employer; economic growth is the top priority **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Evidence of a problem:**
  - Rung 3 is a triple clause (wages, local hiring, clawback). S3N:128-130.
  - Conditions on incentives vs "pass on deals that cost too much" separate no records. PIL:17.
  - Permitting statements are claimed by three ladders (no ownership rule). LLD:86-103. Possible federal lever. LEV §10.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `religious-freedom` — Religious Freedom · ⚠ evidence of a problem

Question: How should the law balance religious freedom with protection from discrimination?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 3 (v2, published) · S3 rev 3 (v2, published). Current = rev 3 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 5 (3 blank, 2 seated) · would map under the default rule 2 · Season 1-only 683 · voter rows 8 (live 6: S1 6).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Substantive v2. Axis-B reframe: the question moves from "role of religion in government/public institutions/policymaking" (Axis A) to "how should the law balance religious freedom with protection from discrimination" ...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | prohibit religious exemptions from civil rights and anti-discrimination laws. | 0 | 0 | 11 |
| 2 | protect religious freedom while ensuring it doesn't override anti-discrimination protections in employment and housing. | 1 | 1 | 192 |
| 3 | balance protecting religious practices with maintaining equal treatment under the law for all citizens. | 0 | 0 | 78 |
| 4 | protect religious freedom and allow faith-based exemptions from laws that conflict with sincere religious beliefs. | 1 | 1 | 227 |
| 5 | strongly protect religious freedom and allow religious organizations complete autonomy in their operations and hiring practices. | 0 | 0 | 175 |
| 0 | *(blank)* | 3 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. strictly separate religion from all public institutions and prohibit religious exemptions from civil rights laws. **(differs)**
2. protect religious freedom while ensuring it doesn't override anti-discrimination protections in employment and housing.
3. balance protecting religious practices with maintaining equal treatment under the law for all citizens.
4. protect religious freedom and allow faith-based exemptions from laws that conflict with sincere religious beliefs.
5. strongly protect religious freedom and allow religious organizations complete autonomy in their operations and hiring practices.

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rungs 2/3 overlap. S3N:169-171.
  - Vote ladder where a No vote proves nothing. PIL:25.
  - Axis-B reframe was parked in v2 (rung 1 split), later published as rev 3. CA_0030:4-60.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `redistricting` — State Redistricting and Gerrymandering · ⚠ evidence of a problem

Question: Who should draw electoral district boundaries and how should they be determined?

- **Pins:** S1 rev 1 (v1, published) · S2 rev 1 (v1, published) · S3 rev 1 (v1, published). Current = rev 1 v1, `substantive`, published 2026-03-15.
- **Counts:** Season 2 rows 12 (10 blank, 2 seated) · would map under the default rule 2 · Season 1-only 674 · voter rows 4 (live 4: S1 4).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | independent citizens' commissions with no elected officials involved at any level. | 0 | 0 | 233 |
| 2 | independent redistricting commissions with equal representation from both major parties. | 1 | 1 | 241 |
| 3 | bipartisan legislative committees with strict rules requiring supermajority approval. | 0 | 0 | 20 |
| 4 | state legislatures with court oversight to prevent extreme partisan bias. | 1 | 1 | 91 |
| 5 | the party that controls the state legislature without outside interference. | 0 | 0 | 89 |
| 0 | *(blank)* | 10 | - | 0 |

- **Evidence of a problem:**
  - Rung 2 commission wording (clarifying). S3N:185-187.
  - Rungs order who draws; records state rules (no partisan data, court review). Mixed axes. Proposal c8. PIL:26, 75; WHY:122.
  - An earlier review found no change needed. MEM/redistricting-review-none:23.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `homelessness` — Criminalization of Homelessness · ⚠ evidence of a problem

Question: How should government address people sleeping or camping in public spaces?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 5 (1 blank, 4 seated) · would map under the default rule 4 · Season 1-only 637 · voter rows 7 (live 7: S1 6, S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Double-barrel split batch (full conjunction-screen triage, decision 2026-08-28 "file them all"). Chair 1 (34 seated): A legal right to sleep in public and a budget reallocation to housing/mental-health are two separab...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Protecting the right to sleep and shelter in public spaces, with no penalties of any kind | 0 | 0 | 34 |
| 2 | Decriminalizing public sleeping and camping in public spaces | 0 | 0 | 289 |
| 3 | Allowing enforcement only when adequate shelter beds are available, with citations diverting people to services rather than the criminal justice system | 3 | 3 | 164 |
| 4 | Prohibiting encampments on public property, enforced through graduated warnings and civil penalties | 0 | 0 | 109 |
| 5 | Banning public camping and sleeping with criminal penalties to maintain public safety and order | 1 | 1 | 41 |
| 0 | *(blank)* | 1 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Protecting the right to sleep in public spaces and redirecting enforcement budgets toward permanent supportive housing and mental health services **(differs)**
2. Decriminalizing public sleeping while investing in shelter capacity, outreach workers, and voluntary service connections **(differs)**
3. Allowing enforcement only when adequate shelter beds are available, with citations diverting people to services rather than the criminal justice system
4. Prohibiting encampments on public property with graduated warnings and penalties, while requiring jurisdictions to maintain basic shelter options **(differs)**
5. Banning public camping and sleeping with criminal penalties to maintain public safety and order, relying on existing social services for those who seek help **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Evidence of a problem:**
  - Rungs 2/4 overlap: a civil-only prohibition fits both (ruled to rung 4). S3N:138-140.
  - Proposal c5 (merge "no penalties of any kind" with "decriminalize"; drop the civil-penalty clause). PIL:18, 72; WHY:121.
  - S3D:55-65 holds a redraft (branch `claude/s2-seating-analysis`).

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `ai-regulation` — Artificial Intelligence Oversight · ⚠ evidence of a problem

Question: How much should government oversee artificial intelligence development and deployment?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 7 (7 blank, 0 seated) · would map under the default rule 0 · Season 1-only 597 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `record`.
- **Orientation:** INVERTED. Rung 1 is the minimum-intervention end. Source: ORI:11-15. Also ANX/ai-regulation:10.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Double-barrel split batch (full conjunction-screen triage, decision 2026-08-28 "file them all"). Chair 3 (269 seated): Mandatory risk disclosure and legal liability for harm are two distinct policies; one can back lia...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Allow AI companies to develop and deploy technology freely without government interference | 0 | 0 | 18 |
| 2 | Suggest AI safety guidelines but let companies choose whether to follow them | 0 | 0 | 122 |
| 3 | Hold AI developers legally responsible when their systems cause harm | 0 | 0 | 264 |
| 4 | Require safety testing before AI can be used in high-stakes areas like hiring, healthcare, and policing | 0 | 0 | 186 |
| 5 | Impose strict government approval requirements before any AI system can be deployed | 0 | 0 | 7 |
| 0 | *(blank)* | 7 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Allow AI companies to develop and deploy technology freely without government interference
2. Suggest AI safety guidelines but let companies choose whether to follow them
3. Require AI developers to disclose risks and be held responsible when their systems cause harm **(differs)**
4. Require safety testing and ban high-risk AI uses in areas like hiring, healthcare, and policing **(differs)**
5. Impose strict approval requirements and ban AI systems that could cause serious harm **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Evidence of a problem:**
  - Targeted bans fit no rung (ruled 2026-09-01). ANX/ai-regulation:95-97.
  - Disclosure/labelling duties are on no rung; the liability rung names developers, not deployers. Proposal c4. PIL:71; WHY:128.
  - An optional frontier-model testing rung 4 is listed as material. S3N:190-191.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `social-security` — Social Security · ⚠ evidence of a problem

Question: How should Social Security be funded and structured for the future?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 9 (7 blank, 2 seated) · would map under the default rule 2 · Season 1-only 589 · voter rows 8 (live 6: S1 6).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `own-words`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Double-barrel split batch (full conjunction-screen triage, decision 2026-08-28 "file them all"). Chair 4 (98 seated): Raising the retirement age and means-reducing benefits are two distinct cuts with distinct constitu...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | expand Social Security benefits significantly and remove the income cap on payroll taxes to fund it. | 1 | 1 | 105 |
| 2 | increase Social Security benefits modestly while raising taxes on higher earners to strengthen the program. | 1 | 1 | 201 |
| 3 | make small adjustments to both benefits and taxes to keep Social Security stable for future generations. | 0 | 0 | 180 |
| 4 | gradually reduce future benefits rather than raise taxes to keep Social Security solvent. | 0 | 0 | 26 |
| 5 | transition Social Security to private investment accounts that individuals control themselves. | 0 | 0 | 77 |
| 0 | *(blank)* | 7 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. expand Social Security benefits significantly and remove the income cap on payroll taxes to fund it.
2. increase Social Security benefits modestly while raising taxes on higher earners to strengthen the program.
3. make small adjustments to both benefits and taxes to keep Social Security stable for future generations.
4. gradually raise the retirement age and reduce benefits for higher earners to save Social Security. **(differs)**
5. transition Social Security to private investment accounts that individuals control themselves.

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Evidence of a problem:**
  - Federal-only lever. ANX/social-security:13.
  - Compound tax clause left unevidenced (one row). BND.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `homelessness-response` — Homelessness Response · ⚠ evidence of a problem

Question: How much should your community spend on housing and services to reduce homelessness?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 3 (0 blank, 3 seated) · would map under the default rule 3 · Season 1-only 440 · voter rows 4 (live 4: S1 3, S2 1).
- **Asked of (compass_topic_roles):** local `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Single-revision review 2026-08-31 (Chris Andrews). RE-AXIS. As written this topic duplicated the sibling topic 'homelessness' (Criminalization of Homelessness, S2 q14): both ran one services<->enforcement axis. 271 po...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Guarantee housing and support services through dedicated, permanent public funding | 1 | 1 | 29 |
| 2 | Expand housing and support services by increasing public funding | 2 | 2 | 176 |
| 3 | Maintain current housing and service programs at today's funding level, with no major new spending | 0 | 0 | 164 |
| 4 | Provide limited public funding to nonprofits and charities to lead the response, rather than running public programs | 0 | 0 | 65 |
| 5 | Withdraw government funding for housing and support services, treating homelessness as a matter for private charity and the market | 0 | 0 | 6 |
| 0 | *(blank)* | 0 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Housing-first: provide permanent supportive housing with no preconditions; avoid criminalization entirely **(differs)**
2. Expand shelter capacity and services as the primary strategy; use enforcement only after services are offered **(differs)**
3. Invest in outreach, shelter, and mental health services while enforcing reasonable public space rules **(differs)**
4. Enforce anti-camping ordinances as the primary tool while maintaining basic outreach programs **(differs)**
5. Prioritize strict enforcement of trespassing and camping bans; minimize public spending on homeless services **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Candidate map (not a decision):** `{1:1, 2:3, 3:4, 4:5, 5:5}` was used only in the rolled-back dry run (findings doc §4, line 66) on a throwaway ladder. It is a test map, not a ladder proposal.
- **Evidence of a problem:**
  - Rung 4 does not separate from rungs 2–3. S3N:131-134.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `growth-and-development` — Growth and Development Pace · ⚠ evidence of a problem

Question: How should government manage population growth and new development?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 10 (1 blank, 9 seated) · would map under the default rule 9 · Season 1-only 428 · voter rows 4 (live 4: S1 4).
- **Asked of (compass_topic_roles):** federal `own-words`, local `record`, state `record`.
- **Orientation:** OFF-AXIS. Source: ORI:21; ANX/growth-and-development:9-14.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Single-revision review 2026-08-31 (Chris Andrews). The ladder is ONE coherent axis — how permissive government is of the PACE of growth, from actively restrain (chair 1) to step back / market-led (chair 5). It is a pa...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Hold the pace of growth down — cap major new development, and let residents vote directly on the largest projects. | 0 | 0 | 18 |
| 2 | Allow growth only as fast as current infrastructure can handle — make new development wait for capacity. | 4 | 4 | 112 |
| 3 | Welcome steady growth — invest in roads, water and schools ahead of demand so expansion isn't held back. | 3 | 3 | 196 |
| 4 | Actively push for faster growth — cut red tape and recruit new development, while keeping basic guardrails. | 2 | 2 | 96 |
| 5 | Step back and let the market set the pace — remove development constraints beyond basic health and safety. | 0 | 0 | 6 |
| 0 | *(blank)* | 1 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Impose growth limits; require voter approval for major annexations or large-scale developments **(differs)**
2. Allow growth only where existing infrastructure can support it; slow approvals until capacity catches up **(differs)**
3. Plan proactively — invest in infrastructure ahead of growth to support responsible expansion **(differs)**
4. Streamline permitting, reduce fees, and actively recruit development to grow the tax base **(differs)**
5. Remove regulatory barriers to development entirely; let market demand determine growth pace **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Evidence of a problem:**
  - Rung 1 is still double-barrelled although CA_0077 claimed to de-barrel it; rung 4 has three clauses. S3N:111-113 (served text not re-checked by the sweep; compare the table).
  - Permitting overlap with housing and economic-development. LLD:86-103.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `misinformation` — Misinformation and the Role of Algorithms in Democracy · ⚠ evidence of a problem

Question: What responsibility do platforms and government have in combating online misinformation?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 3 (v2, published) · S3 rev 3 (v2, published). Current = rev 3 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 5 (5 blank, 0 seated) · would map under the default rule 0 · Season 1-only 364 · voter rows 4 (live 4: S1 4).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `record`.
- **Orientation:** Conventional on intervention, but rung 5 ("no government involvement in moderation") is a free-speech position held across the spectrum. Source: ORI:26-27.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Axis fix (review 2026-08-31, Path B). The rev2 double-barrel split kept the WRONG barrel in chair 2: it retained algorithmic transparency (off-axis — regulates the algorithm) and dropped fact-checking (on-axis — acts ...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | legally require platforms to remove false information | 0 | 0 | 1 |
| 2 | require platforms to label false content, rather than remove it | 0 | 0 | 142 |
| 3 | encourage voluntary standards for combating misinformation online | 0 | 0 | 58 |
| 4 | protect free speech online and prevent government censorship | 0 | 0 | 129 |
| 5 | ban any government involvement in content moderation decisions | 0 | 0 | 34 |
| 0 | *(blank)* | 5 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. require platforms to remove all false information and regulate algorithms **(differs)**
2. mandate fact-checking and transparency in how algorithms promote content **(differs)**
3. encourage voluntary standards for combating misinformation online
4. protect free speech online and prevent government censorship
5. ban any government involvement in content moderation decisions

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - No rung covers platform transparency or disclosure duties (part of c4). PIL:71; BND.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `local-environment` — Environmental Protection vs. Development

Question: How should your community balance new development with environmental preservation?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 3 (v2, published) · S3 rev 3 (v2, published). Current = rev 3 v2, `substantive`, published 2026-08-31.
- **Counts:** Season 2 rows 14 (12 blank, 2 seated) · would map under the default rule 2 · Season 1-only 345 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** local `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Re-axis, not a de-barrel. Rewrites every rung as one point on the protection-vs-development stringency spine so the specific good/mechanism (green space, canopy, offsets, review, fees) becomes evidence that PLACES a p...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Make environmental protection the overriding priority — block or sharply limit development that would harm the local environment | 0 | 0 | 57 |
| 2 | Lean strongly toward protection — put the burden on development to prove it will not damage the environment before it can proceed | 1 | 1 | 182 |
| 3 | Apply consistent environmental standards while giving developers reasonable flexibility on implementation | 1 | 1 | 95 |
| 4 | Lean toward development — treat environmental cost as a manageable trade-off and approve projects with clear economic benefit | 0 | 0 | 8 |
| 5 | Remove local environmental restrictions beyond what state and federal law requires | 0 | 0 | 3 |
| 0 | *(blank)* | 12 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Require significant green space, tree preservation, and environmental review before approving any development **(differs)**
2. Protect existing parks and tree canopy strictly; require developers to fully offset any environmental impact **(differs)**
3. Apply consistent environmental standards while giving developers reasonable flexibility on implementation
4. Allow developers to pay fees in lieu of on-site preservation; prioritize economic activity over green space **(differs)**
5. Remove local environmental restrictions beyond what state and federal law requires

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Note:** Re-axis CA_0062; its re-audit is not applied. MEM/local-environment-reaxis-ca0062:45-54.
- **Evidence of a problem:** none found in the sources listed under "Sources searched".

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `judicial-criminal-justice` — Criminal Justice Approach · ⚠ evidence of a problem

Question: When someone breaks the law, how should the system respond?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 3 (v2, published) · S3 rev 3 (v2, published). Current = rev 3 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 7 (4 blank, 3 seated) · would map under the default rule 3 · Season 1-only 283 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** federal `record`, judicial `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Single-axis reauthor (2026-08-31, Chris Andrews). The prior mechanism draft (rev 2) broke single-select exclusivity: chairs 4-5 described mechanisms while chairs 1-3 described purposes, so a voter could sit in a goal-...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Focus on support and treatment, not punishment. | 2 | 2 | 63 |
| 2 | Give the person a chance to make things right through service or restitution, rarely punishment. | 1 | 1 | 110 |
| 3 | Each situation is different — some people need support, some need consequences. | 0 | 0 | 34 |
| 4 | Breaking the law needs to have real consequences — accountability is the priority. | 0 | 0 | 44 |
| 5 | Impose the toughest penalties the law allows. | 0 | 0 | 32 |
| 0 | *(blank)* | 4 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Helping the person change their life and stay out of trouble in the future. **(differs)**
2. Giving the person a fair chance to make things right — through treatment, community service, or restitution. **(differs)**
3. A mix: some accountability, some support, depending on what happened. **(differs)**
4. Making sure others think twice before doing the same thing. **(differs)**
5. Punishing the behavior. Society needs to know that breaking the law has real consequences. **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rung 5 "toughest penalties" cannot be performed by legislators (no lever; own words only). S3N:82-83.
  - "Not punishment" is an absence clause; treatment bills fit no rung. PIL:53; WHY:124.
  - A judicial-named topic that still reaches legislators. LEV §10.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `data-centers` — Data Center Development & Energy Costs · ⚠ evidence of a problem

Question: How should government manage the growth of large-scale data centers?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 3 (v1, published) · S3 rev 3 (v1, published). Current = rev 3 v1, `clarifying`, published 2026-09-04.
- **Counts:** Season 2 rows 4 (2 blank, 2 seated) · would map under the default rule 2 · Season 1-only 280 · voter rows 6 (live 6: S1 6).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Double-barrel split batch (full conjunction-screen triage, decision 2026-08-28 "file them all"). Chair 2 (100 seated): A cost pass-through ban and a dedicated-generation mandate are separable — the pass-through ban al...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Imposing a moratorium on new data center construction until energy infrastructure can support demand without raising costs for residential ratepayers | 1 | 1 | 50 |
| 2 | Barring utilities from passing any data center energy infrastructure costs to residential customers | 0 | 0 | 91 |
| 3 | Allowing data center development with impact assessments, energy cost-sharing agreements, and community benefit requirements before approval | 1 | 1 | 89 |
| 4 | Encouraging data center development through streamlined permitting while requiring transparency about projected energy demand and rate impacts | 0 | 0 | 40 |
| 5 | Welcoming data center investment with minimal regulatory barriers, trusting that economic growth and tax revenue will benefit all residents | 0 | 0 | 10 |
| 0 | *(blank)* | 2 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Imposing a moratorium on new data center construction until energy infrastructure can support demand without raising costs for residential ratepayers
2. Requiring data centers to fund their own dedicated power generation and barring utilities from passing data center infrastructure costs to residential customers **(differs)**
3. Allowing data center development with impact assessments, energy cost-sharing agreements, and community benefit requirements before approval
4. Encouraging data center development through streamlined permitting while requiring transparency about projected energy demand and rate impacts
5. Welcoming data center investment with competitive incentives and minimal regulatory barriers, trusting that economic growth and tax revenue will benefit all residents **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rung 3 is a triple compound (material fix listed). S3N:182-184.
  - Opposing tax exemptions fits no rung. BND. A rung-3 seat rests on a study bill. RT `.planning/todos/2026-10-01-annex-rulings-reaudit.md`:40-44.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `rent-regulation` — Rent Regulation · ⚠ evidence of a problem

Question: What role should government play in regulating rents and protecting tenants?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 3 (v1, published) · S3 rev 3 (v1, published). Current = rev 3 v1, `clarifying`, published 2026-09-04.
- **Counts:** Season 2 rows 18 (1 blank, 17 seated) · would map under the default rule 17 · Season 1-only 228 · voter rows 4 (live 4: S1 4).
- **Asked of (compass_topic_roles):** federal `own-words`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Double-barrel split batch (full conjunction-screen triage, decision 2026-08-28 "file them all"). Chair 1 (36 seated): Just-cause eviction rules are a separate statute from rent caps; one can back eviction protections ...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Expand rent control to cover all rental units communitywide | 0 | 0 | 7 |
| 2 | Strengthen existing rent stabilization and extend coverage to more units | 9 | 9 | 158 |
| 3 | Maintain current tenant protections while allowing market rents for new construction | 8 | 8 | 24 |
| 4 | Limit rent regulations to subsidized units; allow market rents broadly | 0 | 0 | 29 |
| 5 | Oppose rent control entirely; rents should be set by the market without government intervention | 0 | 0 | 10 |
| 0 | *(blank)* | 1 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Expand rent control to all rental units with strong tenant protections and just-cause eviction requirements **(differs)**
2. Strengthen existing rent stabilization and extend coverage to more units
3. Maintain current tenant protections while allowing market rents for new construction
4. Limit rent regulations to subsidized units; allow market rents broadly
5. Oppose rent control entirely; rents should be set by the market without government intervention

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rung 3 brings "tenant protections" into a coverage ladder. S3N:154-155.
  - No tenant-protection ladder (gap): Duluth votes read backwards on the price ladder. LLD:158-211; ANX/rent-regulation:91-93.
  - Rung 5 describes state preemption in FL and NC, not a position. LLD:46-65; SPD:482-500, §12.2 P3.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `city-sanitation` — City Sanitation and Cleanliness · ⚠ evidence of a problem

Question: How should your community approach street cleanliness and sanitation?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 4 (v1, published) · S3 rev 4 (v1, published). Current = rev 4 v1, `clarifying`, published 2026-09-04.
- **Counts:** Season 2 rows 1 (0 blank, 1 seated) · would map under the default rule 1 · Season 1-only 113 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** local `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 4): De-barrel chairs 1-3 on the public->private provision spine (decision 2026-08-30, Chris Andrews). Chair 1 keeps the draft-v2 split (four clauses -> one: max public provision, city responsibility). Chair 2 drops the st...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Significantly expand public sanitation services, treating cleanliness as the city's responsibility | 1 | 1 | 6 |
| 2 | Concentrate sanitation resources on the most neglected, worst-served neighborhoods to close long-standing service gaps | 0 | 0 | 30 |
| 3 | Maintain current public sanitation services and target enforcement at the businesses and large property owners who create the most waste | 0 | 0 | 50 |
| 4 | Rely primarily on enforcement of anti-littering and property maintenance laws; hold residents and businesses responsible | 0 | 0 | 24 |
| 5 | Privatize sanitation services and require residents and businesses to contract for cleanup directly | 0 | 0 | 3 |
| 0 | *(blank)* | 0 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Significantly expand sanitation staffing, cleaning frequency, and free community disposal access; treat poor conditions as a services failure **(differs)**
2. Increase sanitation crews and prioritize historically underserved neighborhoods to equalize cleanliness communitywide **(differs)**
3. Maintain current sanitation services while enforcing anti-dumping laws for businesses and large property owners **(differs)**
4. Rely primarily on enforcement of anti-littering and property maintenance laws; hold residents and businesses responsible
5. Privatize sanitation services and require residents and businesses to contract for cleanup directly

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}; rev 3 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rung 2 measures allocation while the others measure amount; rung 3 is compound. S3N:125-127.
  - 13 axis-orphans on rung 2 are owed a re-source. MEM/compass-topic-notes-index:38.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `judicial-interpretation` — Judicial Interpretation · ⚠ evidence of a problem

Question: Does the law change with the times, or does it mean what it said when it was written?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 71 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** judicial `record`.
- **Orientation:** Off-axis (interpretive method, not intervention). Source: ANX/judicial-interpretation:9-12.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Single-revision review 2026-08-31 (Chris Andrews). Re-cut the five chairs onto one clean evolve<->fixed interpretive axis. Chair 1 was OFF-AXIS: its text measured willingness to overturn precedent (stare decisis), not...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Judges should read the law in light of how society has changed, not only what it meant long ago. | 0 | 0 | 10 |
| 2 | Judges should follow what the law was meant to achieve, even when the exact words don't fit a new situation. | 0 | 0 | 19 |
| 3 | Start with what the law says; when the words are unclear, weigh what lawmakers were trying to do. | 0 | 0 | 4 |
| 4 | Stick to what the words meant when they were written; don't update them to fit new times. | 0 | 0 | 8 |
| 5 | Judges should apply the law as written. If it needs to change, that is for elected lawmakers. | 0 | 0 | 30 |
| 0 | *(blank)* | 0 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Courts should reconsider old rulings when we know more or society has changed. Keeping bad precedent alive is its own injustice. **(differs)**
2. Laws were written for a purpose. When the exact words don't fit a new situation, look at what the law was trying to accomplish. **(differs)**
3. Follow the text closely, but use some common sense about what lawmakers were trying to do. **(differs)**
4. The law means what it says. Use original intent to fill gaps, but don't stretch the meaning. **(differs)**
5. A judge's job is to apply the law as written — not rewrite it. If society has changed, pass a new law. That's what elections are for. **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Evidence of a problem:**
  - Rungs 4/5 overlap: rung 5 names no method that rung 4 lacks. S3N:75-77.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `judicial-access-to-justice` — Access to Justice · ⚠ evidence of a problem

Question: How easy should it be to use the courts?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 48 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** judicial `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Single-revision review 2026-08-31 (Chris Andrews). The "judicial" lens is the people who run the legal system (judges, court clerks, city/county attorneys, attorneys general), not sitting judges alone. The old rungs w...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Make it easy to bring a case, and clear away the costs and hurdles that shut people out. | 0 | 0 | 10 |
| 2 | Apply the normal requirements, but don't let small mistakes or technicalities keep a real case out. | 0 | 0 | 32 |
| 3 | Apply the same rules to everyone, and let a case stand or fall on its own merits. | 0 | 0 | 4 |
| 4 | Require people to show a strong case up front, and dismiss those that fall short. | 0 | 0 | 2 |
| 5 | Keep the courts for serious cases only, and steer other disputes elsewhere. | 0 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Easy. Courts exist for everyone — not just people with expensive lawyers. Low barriers mean more access to justice. **(differs)**
2. Accessible. Some basic requirements are fine, but courts shouldn't be a maze that only the wealthy can navigate. **(differs)**
3. Reasonable standards that keep out frivolous cases without blocking legitimate ones. **(differs)**
4. Higher bars are fine. Too much litigation clogs the system and costs everyone money. **(differs)**
5. Hard. Most disputes should be settled privately. Courts should be a last resort, not a first option. **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Evidence of a problem:**
  - Rungs 2/3 are close. Clerks can reach only rung 1. S3N:70-72.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `judicial-transparency` — Transparency in Legal Proceedings

Question: How much should the public know about what happens in court?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 34 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** judicial `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Single-revision review 2026-08-31 (Chris Andrews). The v1 ladder was one coherent axis (public access, open->closed) with genuinely judicial levers, but its middle rungs were cut by WHICH reasons justify sealing rathe...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Everything in court should be public. Courts should never seal records or close hearings. | 0 | 0 | 4 |
| 2 | Courts should be open except where the law requires privacy, like juvenile records. Judges shouldn't seal anything beyond that. | 0 | 0 | 20 |
| 3 | Courts should be open by default. A judge can seal records or close a hearing only when there's a strong, specific reason that outweighs the public's interest. | 0 | 0 | 6 |
| 4 | Openness matters, but so do privacy and fair trials. Judges should seal or close proceedings whenever sensitive information is at stake. | 0 | 0 | 3 |
| 5 | Court proceedings should be closed to the public by default. A judge decides what, if anything, becomes public. | 0 | 0 | 1 |
| 0 | *(blank)* | 0 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Everything possible should be public — hearings, evidence, rulings, and the reasoning behind them. Secrecy breeds injustice. **(differs)**
2. Default to open proceedings. Sealing records or closing hearings requires a compelling, documented reason. **(differs)**
3. Balance openness with legitimate needs for privacy — protect victims, seal juvenile records, but keep the courtroom open as a rule. **(differs)**
4. Courts should protect sensitive information broadly — personal details, ongoing investigations, and anything that could prejudice a fair trial. **(differs)**
5. The law is complicated. Public access to proceedings can distort outcomes. Broad judicial discretion to limit access protects the integrity of the process. **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Note:** Only a 34-row re-audit is owed. MEM/compass-topic-notes-index:30.
- **Evidence of a problem:** none found in the sources listed under "Sources searched".

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `judicial-government-deference` — Judicial & Prosecutorial Discretion · ⚠ evidence of a problem

Question: When elected officials or a government agency make a decision, how closely should courts review it?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 22 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** judicial `record`.
- **Orientation:** OFF-AXIS (burden of proof; rung 1 sides with the citizen against government). Source: ORI:22-23; ANX/judicial-government-deference:10-14.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Single-revision review 2026-08-31 (Chris Andrews). RE-AXIS. The old ladder failed the one-spectrum and evidence-able checks: "who gets the benefit of the doubt when government and a citizen clash" welded three indepen...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | When the law is unclear, courts should side with the individual and require the government to prove its decision was clearly within its legal authority. | 0 | 0 | 7 |
| 2 | When the law is unclear, courts should lean toward the individual and overturn decisions whose legal basis is doubtful. | 0 | 0 | 9 |
| 3 | Courts should not favor either side. When the law is unclear, neither the government nor the individual gets the benefit of the doubt. | 0 | 0 | 4 |
| 4 | When the law is unclear, courts should lean toward the government and uphold its decision unless it clearly broke the law. | 0 | 0 | 1 |
| 5 | Courts should defer to elected officials and agencies almost entirely, overturning a decision only for a plain and serious violation of the law. | 0 | 0 | 1 |
| 0 | *(blank)* | 0 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. The citizen, almost always. Government has lawyers, money, and power. Regular people need courts to level the playing field. **(differs)**
2. The citizen usually — unless the government has clear legal authority on its side. **(differs)**
3. Neither side automatically. Look at the facts and apply the law evenly. **(differs)**
4. The government usually — it represents everyone, and its decisions deserve respect unless clearly wrong. **(differs)**
5. The government, unless it has obviously overreached. Officials make decisions for good reasons — courts shouldn't second-guess them constantly. **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Evidence of a problem:**
  - Rung 5 referent differs from rungs 1–4. Rungs 1/2 and 4/5 differ only in strength. S3N:73-74.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `judicial-prosecution-priorities` — Prosecution Priorities · ⚠ evidence of a problem

Question: Does the office try to put people away, or find better solutions?

- **Pins:** S1 rev 1 (v1, published) · S2 rev 1 (v1, published) · S3 rev 1 (v1, published). Current = rev 1 v1, `substantive`, published 2026-05-07.
- **Counts:** Season 2 rows 0 (0 blank, 0 seated) · would map under the default rule 0 · Season 1-only 20 · voter rows 2 (live 2: S1 2).
- **Asked of (compass_topic_roles):** judicial `record`.

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Prosecution should be a last resort. Connecting people to treatment, housing, or job programs does more good than a criminal record. | 0 | 0 | 1 |
| 2 | Use diversion when it's available and makes sense. Reserve prosecution for when community safety actually requires it. | 0 | 0 | 10 |
| 3 | Strong cases get prosecuted. Diversion is used when there's a clear benefit — it's a judgment call every time. | 0 | 0 | 5 |
| 4 | Prosecute all solid cases. Declination is the exception and needs a strong reason. | 0 | 0 | 3 |
| 5 | The office enforces the law — not social policy. If a case is prosecutable, prosecute it. Courts figure out the rest. | 0 | 0 | 1 |
| 0 | *(blank)* | 0 | - | 0 |

- **Evidence of a problem:**
  - Rung 5 carries editorial phrases. S3N:81.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

## Group 5. Expensive: more than 1,000 Season 1-only people, Season 2 pin = current (6 topics)

A moving map blanks more than 1,000 people who show a Season 1 position today through the newest-season fallback.

### `climate-change` — Climate Change and Environmental Protection · ⚠ evidence of a problem

Question: How much should government do to expand clean energy?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 3 (v2, published) · S3 rev 3 (v2, published). Current = rev 3 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 60 (54 blank, 6 seated) · would map under the default rule 6 · Season 1-only 1,842 · voter rows 8 (live 6: S1 5, S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Reframes and renames the former Climate Change topic to Clean Energy. Splits the old climate/fossil overlap: this topic now covers the CLEAN supply side (how actively government promotes clean energy) while Fossil Fue...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Require a shift to clean energy through mandates and firm deadlines. | 2 | 2 | 144 |
| 2 | Fund clean energy with major subsidies, tax credits, and public investment. | 0 | 0 | 572 |
| 3 | Speed up clean energy by cutting permitting red tape and upgrading the grid. | 0 | 0 | 505 |
| 4 | Stay neutral on energy and let the market choose among all sources. | 4 | 4 | 276 |
| 5 | End government subsidies and mandates for clean energy. | 0 | 0 | 345 |
| 0 | *(blank)* | 54 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. declare a climate emergency and ban all activities that increase carbon emissions **(differs)**
2. rapidly transition to renewable energy and phase out fossil fuels by 2030 **(differs)**
3. invest in clean energy while gradually reducing reliance on fossil fuels **(differs)**
4. let market forces drive any transition to cleaner energy sources **(differs)**
5. reject climate change policies and focus on economic growth instead **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rungs 2/3 overlap on grid money (public investment vs "upgrading the grid"). S3N:18-29; ANX/climate-change:56.
  - Mechanism gaps: emissions targets fit no rung (case H17); a feed-in tariff is not "public money". Proposals c2, c2b. PIL:16, 47, 68-69; WHY:130.
  - A national energy ladder asked of cities, whose levers are heat, canopy and stormwater. LLD:123-140.
  - Pilot topic for the draft Season 3 rulebook; S3D:42-53 holds a worked redraft (branch `claude/s2-seating-analysis`).

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `civil-rights` — Civil Rights and Social Justice · ⚠ evidence of a problem

Question: What role should government play in addressing racial and social inequality?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 41 (32 blank, 9 seated) · would map under the default rule 9 · Season 1-only 1,536 · voter rows 8 (live 8: S1 6, S2 2).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Double-barrel split batch (full conjunction-screen triage, decision 2026-08-28 "file them all"). Chair 1 (210 seated): Equity mandates and reparations are two plainly separable policies — many back one and not the oth...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | mandate racial equity requirements in all institutions | 4 | 4 | 187 |
| 2 | strengthen civil rights enforcement and address systemic discrimination | 4 | 4 | 828 |
| 3 | maintain current civil rights laws while promoting equal opportunity | 0 | 0 | 47 |
| 4 | limit federal civil rights enforcement to clear cases of discrimination | 0 | 0 | 136 |
| 5 | eliminate affirmative action and all race-based government programs | 1 | 1 | 338 |
| 0 | *(blank)* | 32 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. mandate racial equity requirements in all institutions and provide reparations **(differs)**
2. strengthen civil rights enforcement and address systemic discrimination
3. maintain current civil rights laws while promoting equal opportunity
4. limit federal civil rights enforcement to clear cases of discrimination
5. eliminate affirmative action and all race-based government programs

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Evidence of a problem:**
  - Rung 4 names "federal" enforcement (no lever below federal). Rung 1 "in all institutions" is almost never evidenceable. Rung 5 is on a different axis. S3N:166-168.
  - Repealing permits is not "strengthen enforcement". WHY:126. DEI-office closures code direction-only. ANX/civil-rights:98.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `voting-rights` — Voting Rights and Electoral Integrity · ⚠ evidence of a problem

Question: How should the government verify a voter's identity and eligibility?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 3 (v2, published) · S3 rev 3 (v2, published). Current = rev 3 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 46 (46 blank, 0 seated) · would map under the default rule 0 · Season 1-only 1,475 · voter rows 6 (live 4: S1 4).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Season 2 redesign (2026-08-29). Rebuilt voting-rights as a single verification-spine axis: how much identity/eligibility proof the state requires to vote, value 1 = no ID / widest access, value 5 = documentary proof o...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Require no identification to vote, verifying voters by signature or existing records. | 0 | 0 | 283 |
| 2 | Accept non-photo identification, such as a utility bill or bank statement. | 0 | 0 | 560 |
| 3 | Require photo ID to vote, but let voters without one cast a ballot after signing an affidavit. | 0 | 0 | 52 |
| 4 | Require photo ID in person and an ID number on every mail ballot. | 0 | 0 | 516 |
| 5 | Require documentary proof of citizenship to register to vote. | 0 | 0 | 64 |
| 0 | *(blank)* | 46 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. automatically register all eligible citizens to vote and allow online voting **(differs)**
2. expand early voting periods and make mail-in voting available to all voters without requiring an excuse **(differs)**
3. standardize voter ID requirements while ensuring free IDs are available to all eligible citizens **(differs)**
4. require photo ID for voting and regularly update voter rolls to remove inactive registrations **(differs)**
5. mandate in-person voting with strict photo ID and eliminate mail-in voting except for military overseas **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rung 5 switches from ID-to-vote to registration (off-axis; material). S3N:188-189; ANX/voting-rights:9-11.
  - Registration rules that are not documentary proof fit no rung. ANX/voting-rights:80-81. REAL-ID widening fits no rung. PIL:48.
  - Fails 4 of 5 rungs at local. SPD:1077-1078. Ballot access has no ladder (P7). SPD §12.2.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `deportation` — Deportation Priorities · ⚠ evidence of a problem

Question: How far should the government go in deporting undocumented immigrants?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 2 (v2, published) · S3 rev 2 (v2, published). Current = rev 2 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 39 (22 blank, 17 seated) · would map under the default rule 17 · Season 1-only 1,319 · voter rows 6 (live 5: S1 5).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `own-words`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 2): Single-revision review 2026-08-31 (Chris Andrews). Three fixes: (1) the question named a second axis ("how aggressively") the chairs never measured, so it is restated onto the real axis — breadth of removal — neutrall...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Stop deportations entirely and protect undocumented immigrants from removal | 3 | 3 | 164 |
| 2 | Only deport undocumented immigrants convicted of serious violent crimes | 2 | 2 | 529 |
| 3 | Focus deportation on recent arrivals while leaving long-settled undocumented immigrants in place | 0 | 0 | 118 |
| 4 | Deport all undocumented immigrants, starting with those who have criminal records | 11 | 11 | 400 |
| 5 | Carry out a mass-deportation program to remove all undocumented immigrants, including long-settled families and workers | 1 | 1 | 108 |
| 0 | *(blank)* | 22 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Stop deportations entirely and protect undocumented residents from removal **(differs)**
2. Only deport people convicted of serious violent crimes **(differs)**
3. Focus deportation on recent arrivals while leaving long-term residents in place **(differs)**
4. Deport everyone without legal status, starting with those who have criminal records **(differs)**
5. Move quickly to deport all undocumented people regardless of how long they've lived here or family ties **(differs)**

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null.
- **Evidence of a problem:**
  - Rungs 4/5 overlap ("mass deportation" is a label). S3N:195-197; ANX/deportation:79.
  - Rung 3 absence clause ("leaving long-settled in place") blocks records. Proposal c6. PIL:73; WHY:123.
  - No state lever; deportation/state is own-words, and its scope is inconsistent with border-security. LEV:27-34.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `school-vouchers` — School Vouchers & Public Education Funding · ⚠ evidence of a problem

Question: What role should vouchers and school choice play in the public education system?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 3 (v2, published) · S3 rev 3 (v2, published). Current = rev 3 v2, `substantive`, published 2026-09-04.
- **Counts:** Season 2 rows 15 (14 blank, 1 seated) · would map under the default rule 1 · Season 1-only 1,216 · voter rows 4 (live 4: S1 4).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Axis re-author (review 2026-08-31, Chris Andrews). Rev1 welded a public-school-funding clause onto the voucher position in chairs 1-4 (two independent votes). Rev2 dropped those clauses but left chair 2 as a double-co...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Eliminating voucher programs that divert taxpayer money from public schools to private institutions | 1 | 1 | 572 |
| 2 | Opposing voucher programs and blocking their expansion, without moving to eliminate existing ones | 0 | 0 | 82 |
| 3 | Allowing income-based voucher programs, open to a wider range of families under an income cap | 0 | 0 | 35 |
| 4 | Expanding voucher eligibility to most families so parents can choose the school that best fits their child | 0 | 0 | 294 |
| 5 | Providing universal vouchers so that education funding follows the student to any school — public, private, or religious — chosen by the family | 0 | 0 | 233 |
| 0 | *(blank)* | 14 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. Fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions **(differs)**
2. Prioritizing public school funding while restricting vouchers to low-income families who lack adequate local options **(differs)**
3. Funding public schools at current levels while allowing means-tested voucher programs with accountability requirements for participating private schools **(differs)**
4. Expanding voucher eligibility to most families so parents can choose the school that best fits their child, while maintaining baseline public school funding **(differs)**
5. Providing universal vouchers so that education funding follows the student to any school — public, private, or religious — chosen by the family

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rung 3 "wider range" is a comparison, not a test (clarifying fix listed). S3N:31-41. Rung 5 should say "school or schooling". S3N:43-55.
  - Rung 2 absence clause ("without moving to eliminate"). Proposal c7. PIL:23, 74; WHY:132.
  - Fails all five rungs at school-board level, so excluded there. CA_0256 header.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `medicare/aid` — Medicare / Medicaid · ⚠ evidence of a problem

Question: How should Medicare and Medicaid be funded and structured?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 4 (v1, published) · S3 rev 4 (v1, published). Current = rev 4 v1, `clarifying`, published 2026-09-04.
- **Counts:** Season 2 rows 13 (7 blank, 6 seated) · would map under the default rule 6 · Season 1-only 1,131 · voter rows 6 (live 4: S1 4).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 4): Combined proposal: carries the earlier queued rewrite unchanged (its draft 70d5face-a1d5-447f-9af0-6bfcb0dcd515 was rejected as superseded, its rationale preserved there) and adds the full-triage double-barrel split(s...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | expand Medicare to cover everyone regardless of age | 2 | 2 | 252 |
| 2 | significantly expand Medicare or Medicaid eligibility, stopping short of universal coverage | 1 | 1 | 331 |
| 3 | improve current programs while controlling costs | 0 | 0 | 286 |
| 4 | scale back both programs, shifting more coverage to private insurance | 3 | 3 | 243 |
| 5 | phase out both programs and use private insurance only | 0 | 0 | 19 |
| 0 | *(blank)* | 7 | - | 0 |

S1-only counts are against the **Season 1** ladder.

<details><summary>Season 1 ladder (rev 1)</summary>

1. expand Medicare to cover everyone regardless of age
2. lower Medicare age to 55 and expand Medicaid significantly **(differs)**
3. improve current programs while controlling costs
4. partially privatize Medicare and reduce Medicaid coverage **(differs)**
5. phase out both programs and use private insurance only

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}; rev 3 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rungs 1, 4, 5 need Medicare, but the topic has a `state` role. A Medicaid-only state rung 4 is listed. S3N:163-165; ANX/medicare/aid:12, 82.
  - Omnibus votes vs eligibility statements: rungs order size, statements address eligibility. PIL:27.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

## Group 6. Chained: Season 2 pin is not the current revision (13 topics)

Season 2 rows sit on an older revision than the Season 3 pin. The default rule maps only Season 2 rows on the current revision, and there are none here. So a moving map blanks EVERY Season 2 row as well as every Season 1-only person. An identity ruling avoids all of it.

### `taxes` — Taxation and Public Spending · ⛓ chained · ⚠ evidence of a problem

Question: How should government balance what it collects in taxes against what it spends on public services?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 1 (v1, superseded) · S3 rev 3 (v1, published). Current = rev 3 v1, `clarifying`, published 2026-08-31.
- **Counts:** Season 2 rows 81 (39 blank, 42 seated) · would map under the default rule 0 · Season 1-only 1,940 · voter rows 4 (live 4: S1 4).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): WA sweep, defect 4: chair 4 demanded a service consequence no bill states (4 blanks across both parties, e.g. identical half-point sales-tax cuts from Orcutt (R) and Krishnadasan (D)), and chair 3 excluded every targe...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Significantly raise taxes on wealthy people and large companies to fund more public services | 10 | 0 | 294 |
| 2 | Moderately raise taxes on wealthy people and large companies to fund existing services | 11 | 0 | 595 |
| 3 | Keep the current tax system mostly as-is, with targeted adjustments — closing loopholes or granting narrow relief | 11 | 0 | 135 |
| 4 | Cut taxes broadly, including the main rates most people pay | 9 | 0 | 703 |
| 5 | Cut taxes as far as possible and shrink what government does | 1 | 0 | 213 |
| 0 | *(blank)* | 39 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 1)</summary>

1. Significantly raise taxes on wealthy people and large companies to fund more public services
2. Moderately raise taxes on wealthy people and large companies to fund existing services
3. Keep the current tax system mostly as-is with small adjustments to close unfair loopholes **(differs)**
4. Cut taxes for everyone and scale back public services to match **(differs)**
5. Drastically cut taxes and shrink government so people and businesses keep more of their money **(differs)**

</details>

Season 1 pins the same ladder as Season 2, so the S1-only counts use the ladder above.

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rungs 1/2 are a magnitude dial; a 2026-10-01 ruling says a purpose clause separates them. S3N:146-148.
  - Rungs 4/5 rest on degree words ("broadly" vs "as far as possible"). Proposal c10. PIL:14, 76; WHY §5(c).
  - Possible local lever (property and sales tax), but CA_0302 codes taxes/local as own-words. LEV §10.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `abortion` — Reproductive Rights and Abortion Access · ⛓ chained · ⚠ evidence of a problem

Question: How should the law handle abortion?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 1 (v1, superseded) · S3 rev 5 (v1, published). Current = rev 5 v1, `clarifying`, published 2026-08-29.
- **Counts:** Season 2 rows 61 (27 blank, 34 seated) · would map under the default rule 0 · Season 1-only 1,850 · voter rows 8 (live 6: S1 6).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 5): Minor (clarifying) rewrite, decision 2026-08-29 after the seated-answer scope analysis: positions preserved (identity rung_map), so publish into the current season rather than staging a major. Only chair 3 shifted (dr...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | keep abortion legal at every stage of pregnancy, with no time limit. | 19 | 0 | 497 |
| 2 | keep abortion legal through the second trimester, and after that only to protect the mother's health. | 4 | 0 | 614 |
| 3 | allow abortion during the first trimester, and after that only to protect the mother's health. | 2 | 0 | 51 |
| 4 | ban abortion except in cases of rape, incest, or a serious risk to the mother's life. | 9 | 0 | 492 |
| 5 | ban abortion in all cases, with no exceptions. | 0 | 0 | 196 |
| 0 | *(blank)* | 27 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 1)</summary>

1. ensure abortion is legal, accessible, and publicly funded at all stages of pregnancy. **(differs)**
2. keep abortion legal and accessible through the second trimester with rare exceptions afterward. **(differs)**
3. allow abortion in the first trimester and in cases of rape, incest, or maternal health risks. **(differs)**
4. restrict abortion to only cases involving rape, incest, or serious threats to the mother's life. **(differs)**
5. ban abortion completely with no exceptions and impose criminal penalties for providers and patients. **(differs)**

</details>

Season 1 pins the same ladder as Season 2, so the S1-only counts use the ladder above.

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}; rev 3 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}; rev 4 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rungs state trimesters; laws state weeks. A life-only-exception ban fits neither rung 4 nor 5. S3N:57-62.
  - A 16–21 week limit fits no rung (ruled). ANX/abortion:48-49. A life-only exception codes compound-partial (ruled). ANX/abortion:73-74.
  - Proposal c3: write the restrictive rungs by ban point. PIL:70; WHY:129.
  - No lever at local; abortion/local is own-words (CA_0302). LEV:38-41.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `healthcare` — Healthcare Access · ⛓ chained · ⚠ evidence of a problem

Question: What role should government play in healthcare access?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 1 (v1, superseded) · S3 rev 3 (v1, published). Current = rev 3 v1, `clarifying`, published 2026-08-31.
- **Counts:** Season 2 rows 54 (34 blank, 20 seated) · would map under the default rule 0 · Season 1-only 1,741 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Reclassified the pending healthcare rework from MAJOR (substantive, version 2) to MINOR (clarifying, version 1) and published into the open season. The reword splits chair 1's double barrel — "paid for and run by the ...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Make healthcare free and available to everyone, fully paid for by the public sector | 10 | 0 | 335 |
| 2 | Make sure everyone has affordable coverage through a mix of public programs and regulated private insurance | 7 | 0 | 824 |
| 3 | Help people who can't afford care and expand programs for seniors and low-income residents, while keeping private insurance for everyone else | 2 | 0 | 141 |
| 4 | Only help the poorest people afford healthcare and leave everyone else to employers and private insurance | 1 | 0 | 319 |
| 5 | Stay out of healthcare entirely and let private markets handle all coverage decisions | 0 | 0 | 122 |
| 0 | *(blank)* | 34 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 1)</summary>

1. Make healthcare free and available to everyone, paid for and run by the public sector **(differs)**
2. Make sure everyone has affordable coverage through a mix of public programs and regulated private insurance
3. Help people who can't afford care and expand programs for seniors and low-income residents, while keeping private insurance for everyone else
4. Only help the poorest people afford healthcare and leave everyone else to employers and private insurance
5. Stay out of healthcare entirely and let private markets handle all coverage decisions

</details>

Season 1 pins the same ladder as Season 2, so the S1-only counts use the ladder above.

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rung 4 "only help the poorest" conflicts with Medicare; rungs 2/3 turn on the single word "everyone". S3N:159-162.
  - Rungs order whom government covers; bills address cost control (all-payer rates). Off-axis for those records. PIL:27, 49; WHY:127.
  - Possible local lever (county health) against own-words coding. LEV §10.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `fossil-fuels` — Fossil Fuel Policy · ⛓ chained · ⚠ evidence of a problem

Question: What role should fossil fuels play in the nation's energy future?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 1 (v1, superseded) · S3 rev 3 (v1, published). Current = rev 3 v1, `clarifying`, published 2026-08-29.
- **Counts:** Season 2 rows 24 (16 blank, 8 seated) · would map under the default rule 0 · Season 1-only 1,319 · voter rows 6 (live 4: S1 4).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Minor (clarifying) rewrite, decision 2026-08-29: positions fully preserved (identity rung_map) — the trajectory rewording kept the meaning of every chair and only removed off-axis environmental-regulation limbs. Zero ...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Phase out fossil fuel production entirely. | 1 | 0 | 46 |
| 2 | Allow no new drilling and let production decline over time. | 3 | 0 | 483 |
| 3 | Keep fossil fuel production steady at current levels. | 2 | 0 | 223 |
| 4 | Expand fossil fuel production with new drilling and permits. | 2 | 0 | 370 |
| 5 | Maximize production and open more public land and waters to drilling. | 0 | 0 | 197 |
| 0 | *(blank)* | 16 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 1)</summary>

1. immediately ban all new fossil fuel drilling and extraction **(differs)**
2. stop issuing new permits for fossil fuel drilling **(differs)**
3. maintain current levels of fossil fuel production with existing environmental regulations **(differs)**
4. expand fossil fuel drilling permits **(differs)**
5. remove environmental restrictions and maximize fossil fuel extraction **(differs)**

</details>

Season 1 pins the same ladder as Season 2, so the S1-only counts use the ladder above.

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - A siting setback is not "no new drilling" (mechanism gap, one row). BND.
  - Season 2 pins rev 1 but serves rev 3. MEM/season2-prestage-blockers:25-26.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `public-safety-approach` — Public Safety Approach · ⛓ chained · ⚠ evidence of a problem

Question: What approach should your community take to public safety?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 1 (v1, superseded) · S3 rev 4 (v1, published). Current = rev 4 v1, `clarifying`, published 2026-08-29.
- **Counts:** Season 2 rows 66 (23 blank, 43 seated) · would map under the default rule 0 · Season 1-only 801 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** local `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 4): Minor (clarifying) rewrite published into the current season per author decision 2026-08-29. Chairs 1/4/5 carry; chairs 2 and 3 shifted meaning (funding-dial → role-model) and their ~462 seatings are owed a re-audit a...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Shift public safety away from policing and toward mental health, housing, and social services. | 0 | 0 | 31 |
| 2 | Send unarmed responders, instead of police, to mental-health and non-violent calls. | 14 | 0 | 203 |
| 3 | Keep police as the main responders and add crisis teams to work alongside them. | 8 | 0 | 231 |
| 4 | Add more officers and expand police presence to deter and respond to crime. | 21 | 0 | 303 |
| 5 | Make policing the community's top public-safety priority, ahead of social and community programs. | 0 | 0 | 33 |
| 0 | *(blank)* | 23 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 1)</summary>

1. Redirect a significant portion of the police budget to social services, mental health, and community programs **(differs)**
2. Maintain current police staffing but shift non-violent calls to unarmed mental health co-responders **(differs)**
3. Keep current public safety funding while adding crisis response teams for mental health and addiction calls **(differs)**
4. Increase police staffing, equipment, and pay to improve response times and deter crime **(differs)**
5. Make expanding the police budget the top spending priority over other services **(differs)**

</details>

Season 1 pins the same ladder as Season 2, so the S1-only counts use the ladder above.

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}; rev 3 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rungs 1 and 3 do not separate ("funds both" fits neither); 7 of 12 Charlotte members could not be seated. LLD:18-43.
  - Rungs 4/5: a vote to add officers fits both. S3N:122-124.
  - The current revision (rev 4, clarifying, identity map) says chairs 2 and 3 "shifted meaning"; ~462 seatings owed a re-audit, deferred. Revision rationale; MEM/compass-topic-reworks-2026-08-29:18.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `trans-athletes` — Transgender Athletes · ⛓ chained · ⚠ evidence of a problem

Question: How should sports leagues determine eligibility for transgender athletes?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 1 (v1, superseded) · S3 rev 3 (v1, published). Current = rev 3 v1, `clarifying`, published 2026-08-30.
- **Counts:** Season 2 rows 7 (5 blank, 2 seated) · would map under the default rule 0 · Season 1-only 854 · voter rows 7 (live 5: S1 5).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Minor (clarifying) rewrite. Splits the chair-3 double-barrel so the chair states one position: it drops the "create separate transgender divisions" branch and keeps "decide eligibility case by case based on individual...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | allow all transgender athletes to compete on teams matching their gender identity without any restrictions or requirements. | 0 | 0 | 198 |
| 2 | should allow transgender athletes to compete on teams matching their gender identity after completing basic documentation of their transition. | 0 | 0 | 158 |
| 3 | decide transgender athletes' eligibility case by case based on individual circumstances and the requirements of each sport. | 0 | 0 | 14 |
| 4 | require transgender athletes to compete only on teams matching their biological sex assigned at birth. | 2 | 0 | 410 |
| 5 | completely ban all transgender athletes from competing in any organized sports competitions. | 0 | 0 | 74 |
| 0 | *(blank)* | 5 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 1)</summary>

1. allow all transgender athletes to compete on teams matching their gender identity without any restrictions or requirements.
2. should allow transgender athletes to compete on teams matching their gender identity after completing basic documentation of their transition.
3. create separate transgender divisions or allow case-by-case decisions based on individual circumstances and sport requirements. **(differs)**
4. require transgender athletes to compete only on teams matching their biological sex assigned at birth.
5. completely ban all transgender athletes from competing in any organized sports competitions.

</details>

Season 1 pins the same ladder as Season 2, so the S1-only counts use the ladder above.

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rung 2 grammar ("should allow…"). S3N:174-175.
  - Vote ladder where a No vote proves nothing. PIL:25.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `tariffs` — United States Tariff Policy · ⛓ chained · ⚠ evidence of a problem

Question: How should trade policy balance domestic industry with global commerce?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 1 (v1, superseded) · S3 rev 3 (v1, published). Current = rev 3 v1, `clarifying`, published 2026-08-29.
- **Counts:** Season 2 rows 6 (4 blank, 2 seated) · would map under the default rule 0 · Season 1-only 657 · voter rows 8 (live 6: S1 5, S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `own-words`.
- **Orientation:** INVERTED. Rung 1 is the minimum-intervention end. Source: ORI:11-15. Also ANX/tariffs:10-12.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Reclassified from substantive (v2) to clarifying (stays v1) on 2026-08-29 review (minor-bump decision). The sole change is chair 2: the off-axis environmental-tariff carve-out is removed and generalized to 'limited ex...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | eliminate all tariffs and pursue completely free trade with every country. | 0 | 0 | 72 |
| 2 | reduce most tariffs, keeping only limited exceptions. | 1 | 0 | 141 |
| 3 | use tariffs selectively to protect key American industries and jobs. | 1 | 0 | 329 |
| 4 | increase tariffs on countries that don't trade fairly with America. | 0 | 0 | 107 |
| 5 | impose high tariffs on all imports to bring manufacturing back to America. | 0 | 0 | 8 |
| 0 | *(blank)* | 4 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 1)</summary>

1. eliminate all tariffs and pursue completely free trade with every country.
2. reduce most tariffs while keeping some on products that harm the environment. **(differs)**
3. use tariffs selectively to protect key American industries and jobs.
4. increase tariffs on countries that don't trade fairly with America.
5. impose high tariffs on all imports to bring manufacturing back to America.

</details>

Season 1 pins the same ladder as Season 2, so the S1-only counts use the ladder above.

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rungs 2/3 overlap ("limited exceptions"). S3N:201-203.
  - A baseline tariff on all imports codes direction-only (ruled 2026-10-01); proposal a2 would reverse that. ANX/tariffs:69-71; PIL:13; WHY:177.
  - Nothing in the schema stores orientation (P4). SPD §12.2.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `local-immigration` — Local Immigration Enforcement · ⛓ chained · ⚠ evidence of a problem

Question: How should your community's law enforcement relate to federal immigration enforcement?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 1 (v1, superseded) · S3 rev 3 (v1, published). Current = rev 3 v1, `clarifying`, published 2026-08-31.
- **Counts:** Season 2 rows 15 (4 blank, 11 seated) · would map under the default rule 0 · Season 1-only 555 · voter rows 5 (live 5: S1 4, S2 1).
- **Asked of (compass_topic_roles):** local `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Reclassified the pending local-immigration (Local Immigration Enforcement) rework from MAJOR (substantive, version 2) to MINOR (clarifying, version 1) and published into the open season. The reword splits chair 2's do...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Refuse all ICE detainers; prohibit local employees from sharing immigration status information with federal agencies | 4 | 0 | 221 |
| 2 | Comply with ICE detainers only when they are ordered by a court | 0 | 0 | 146 |
| 3 | Follow federal law as required but do not use local resources for proactive immigration enforcement | 7 | 0 | 78 |
| 4 | Honor ICE detainers and share information proactively when federal agencies request it | 0 | 0 | 98 |
| 5 | Direct local police to actively assist with immigration enforcement and support federal detention operations | 0 | 0 | 12 |
| 0 | *(blank)* | 4 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 1)</summary>

1. Refuse all ICE detainers; prohibit local employees from sharing immigration status information with federal agencies
2. Comply only with court-ordered detainers; protect undocumented crime victims and witnesses from referral **(differs)**
3. Follow federal law as required but do not use local resources for proactive immigration enforcement
4. Honor ICE detainers and share information proactively when federal agencies request it
5. Direct local police to actively assist with immigration enforcement and support federal detention operations

</details>

Season 1 pins the same ladder as Season 2, so the S1-only counts use the ladder above.

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rung 3 states no detainer rule (overlaps 2 and 4); rung 4 "proactively when … request" contradicts itself. S3N:114-117.
  - Rungs span two offices: detainers belong to the county sheriff, police policy to the city. LLD:107-119.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `transportation-priorities` — Transportation Priorities · ⛓ chained · ⚠ evidence of a problem

Question: Where should government focus its transportation investment?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 1 (v1, superseded) · S3 rev 3 (v1, published). Current = rev 3 v1, `clarifying`, published 2026-08-30.
- **Counts:** Season 2 rows 133 (16 blank, 117 seated) · would map under the default rule 0 · Season 1-only 428 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** federal `own-words`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Minor (clarifying) rewrite. Rewrites chairs 1 and 2 to each state one position, carrying chairs 3-5 verbatim. Chair 1 drops "reduce parking requirements communitywide" and adds "over new road capacity"; chair 2 drops ...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Prioritize pedestrian infrastructure, cycling networks, and public transit over new road capacity | 75 | 0 | 111 |
| 2 | Invest equally in road capacity and in multimodal options like transit, bike lanes, and sidewalks | 3 | 0 | 151 |
| 3 | Maintain roads while selectively adding transit connections and pedestrian improvements where density supports it | 8 | 0 | 106 |
| 4 | Focus on road capacity and traffic flow; transportation investment should serve the majority who drive | 31 | 0 | 57 |
| 5 | Prioritize highway access and abundant free parking as the foundation of local transportation policy | 0 | 0 | 3 |
| 0 | *(blank)* | 16 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 1)</summary>

1. Prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking requirements communitywide **(differs)**
2. Invest equally in roads and multimodal options; require bike lanes and sidewalks on all new road projects **(differs)**
3. Maintain roads while selectively adding transit connections and pedestrian improvements where density supports it
4. Focus on road capacity and traffic flow; transportation investment should serve the majority who drive
5. Prioritize highway access and abundant free parking as the foundation of local transportation policy

</details>

Season 1 pins the same ladder as Season 2, so the S1-only counts use the ladder above.

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rung 5 is double-barrelled (highways + free parking) and says "local". S3N:149-151.
  - Rung 1 "over new road capacity" is a priority comparison no bill states. Proposal c13. PIL:52, 78; WHY:125.
  - Season 3 carries newer wording than the Season 2 pin. CA_0113:51-56.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `ukraine-support` — Ukraine - Russia Conflict · ⛓ chained · ⚠ evidence of a problem

Question: What level of military and financial support should be provided to Ukraine?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 1 (v1, superseded) · S3 rev 3 (v1, published). Current = rev 3 v1, `clarifying`, published 2026-08-30.
- **Counts:** Season 2 rows 7 (6 blank, 1 seated) · would map under the default rule 0 · Season 1-only 460 · voter rows 7 (live 5: S1 5).
- **Asked of (compass_topic_roles):** federal `record`, local `own-words`, state `own-words`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Minor (clarifying) rewrite. Rewrites chair 1 to state one position: it drops the "and commit to supporting them until complete victory over Russia" limb (an off-axis war-aim commitment) and adds "financial" alongside ...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | significantly increase military and financial aid to Ukraine. | 0 | 0 | 22 |
| 2 | continue providing current levels of military and economic aid to help Ukraine defend itself. | 1 | 0 | 261 |
| 3 | provide limited humanitarian aid to Ukraine while encouraging diplomatic negotiations to end the war. | 0 | 0 | 50 |
| 4 | reduce aid to Ukraine and focus American resources on domestic priorities instead. | 0 | 0 | 82 |
| 5 | end all aid to Ukraine immediately and stay completely out of the conflict. | 0 | 0 | 45 |
| 0 | *(blank)* | 6 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 1)</summary>

1. significantly increase military aid to Ukraine and commit to supporting them until complete victory over Russia **(differs)**
2. continue providing current levels of military and economic aid to help Ukraine defend itself.
3. provide limited humanitarian aid to Ukraine while encouraging diplomatic negotiations to end the war.
4. reduce aid to Ukraine and focus American resources on domestic priorities instead.
5. end all aid to Ukraine immediately and stay completely out of the conflict.

</details>

Season 1 pins the same ladder as Season 2, so the S1-only counts use the ladder above.

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rungs 1, 2, 4: "military and financial" reads as two tests (ruled one clause). Rung 4 "domestic priorities" is a reason, not a level. S3N:206-208.
  - "Significantly" vs "current levels" is a degree boundary. Proposal a3. PIL:24; WHY:178.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `residential-zoning` — Residential Zoning · ⛓ chained · ⚠ evidence of a problem

Question: What should guide decisions about housing density and neighborhood character in your community?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 1 (v1, superseded) · S3 rev 4 (v1, published). Current = rev 4 v1, `clarifying`, published 2026-08-29.
- **Counts:** Season 2 rows 92 (84 blank, 8 seated) · would map under the default rule 0 · Season 1-only 355 · voter rows 5 (live 5: S1 4, S2 1).
- **Asked of (compass_topic_roles):** local `record`.
- **Orientation:** OFF-AXIS, with inversions both ways. Source: ORI:18-20, 44-53; ANX/residential-zoning:11-16.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 4): Minor (clarifying) rewrite. Splits three double-barrels so each chair states one position: chair 1 drops the "require community votes before any rezoning" mechanism (keeps the protection stance); chair 2 drops "with s...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Protect existing single-family neighborhoods; oppose density increases. | 0 | 0 | 31 |
| 2 | Allow modest density increases, like duplexes and accessory units, in single-family neighborhoods | 2 | 0 | 89 |
| 3 | Allow multifamily and mixed-use near commercial corridors while protecting most residential zones | 4 | 0 | 119 |
| 4 | Upzone broadly to allow multifamily housing by right in most neighborhoods | 2 | 0 | 108 |
| 5 | Eliminate single-family-only zoning; allow any housing type on any lot communitywide | 0 | 0 | 8 |
| 0 | *(blank)* | 84 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 1)</summary>

1. Protect existing neighborhood character strictly; require community votes before any rezoning **(differs)**
2. Allow modest density increases (duplexes, accessory units) with strong design review and neighborhood input **(differs)**
3. Allow multifamily and mixed-use near commercial corridors while protecting most residential zones
4. Upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements **(differs)**
5. Eliminate single-family-only zoning; allow any housing type on any lot communitywide

</details>

Season 1 pins the same ladder as Season 2, so the S1-only counts use the ladder above.

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}; rev 3 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rung 5 "eliminate SF-only" is met by a duplex-only law; "any type on any lot" is unreachable. Rung 2 vs 4 undefined for 3–4 units. S3N:118-121; SPD §12.2 P2.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `jail-capacity` — Jail Capacity and Incarceration Alternatives · ⛓ chained · ⚠ evidence of a problem

Question: How should government respond to jail overcrowding and criminal justice demand?

- **Pins:** S1 rev 1 (v1, superseded) · S2 rev 1 (v1, superseded) · S3 rev 3 (v1, published). Current = rev 3 v1, `clarifying`, published 2026-08-31.
- **Counts:** Season 2 rows 16 (7 blank, 9 seated) · would map under the default rule 0 · Season 1-only 291 · voter rows 3 (live 3: S1 3).
- **Asked of (compass_topic_roles):** federal `own-words`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Reclassified the pending jail-capacity rework from MAJOR (substantive, version 2) to MINOR (clarifying, version 1) and published into the open season. The reword broadens two chairs by removing welded limbs: chair 2 "...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Redirecting incarceration funding into community-based mental health, addiction, housing, and restorative justice programs to shrink the jail system | 4 | 0 | 49 |
| 2 | Reducing the incarcerated population through alternatives to incarceration rather than building new capacity | 1 | 0 | 104 |
| 3 | Upgrading jail facilities only as needed to meet constitutional standards, without expanding overall capacity | 3 | 0 | 71 |
| 4 | Building additional jail capacity to address overcrowding and facility deficiencies | 1 | 0 | 57 |
| 5 | Expanding jail capacity as the primary response to crime, prioritizing detention over alternatives | 0 | 0 | 10 |
| 0 | *(blank)* | 7 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 1)</summary>

1. Redirecting incarceration funding into community-based mental health, addiction, housing, and restorative justice programs to shrink the jail system
2. Reducing the incarcerated population through pretrial diversion, bail reform, and treatment alternatives rather than building new capacity **(differs)**
3. Upgrading jail facilities only as needed to meet constitutional standards, without expanding overall capacity
4. Building additional jail capacity to address overcrowding and facility deficiencies
5. Expanding jail capacity and enforcement as the primary response to crime, prioritizing detention over alternatives **(differs)**

</details>

Season 1 pins the same ladder as Season 2, so the S1-only counts use the ladder above.

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 rejected substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - No `federal` role (a House seat has no lever). MEM/barr-moulton-season2-reresearch-ca0211:30-31. Note: CA_0302 later set jail-capacity/federal to own-words (see roles line).

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

### `gun-policy` — Gun Policy · ⛓ chained · ⚠ evidence of a problem

Question: How should the government regulate firearms?

- **Pins:** S2 rev 2 (v2, superseded) · S3 rev 3 (v2, published) · S1: not pinned. Current = rev 3 v2, `clarifying`, published 2026-09-08.
- **Counts:** Season 2 rows 97 (0 blank, 97 seated) · would map under the default rule 0 · Season 1-only 0 · voter rows 1 (live 1: S2 1).
- **Asked of (compass_topic_roles):** federal `record`, local `record`, state `record`.
- **Why the current revision exists** (`compass_topic_revisions.rationale`, rev 3): Ruling 2026-09-08 (Chris Andrews) on the Senate research memo "Fifty-Three Empty Chairs" (Chris Cantrell, 2026-09-05). Rung 4 "Keep current gun laws, adding no new restrictions" was a status-quo position no bill can e...

| rung | current text (Season 3 pin) | S2 rows | S2 would map | S1-only |
|---:|---|---:|---:|---:|
| 1 | Ban civilian firearm ownership, except for tightly licensed hunting and sport use. | 0 | 0 | 0 |
| 2 | Ban semi-automatic assault-style weapons, while allowing other firearms. | 44 | 0 | 0 |
| 3 | Allow all types of firearms, but require universal background checks on every sale. | 3 | 0 | 0 |
| 4 | Add no new restrictions, and at most loosen rules on carrying, such as honoring permits across state lines. | 49 | 0 | 0 |
| 5 | Repeal major gun restrictions and let adults carry a firearm without a permit. | 1 | 0 | 0 |
| 0 | *(blank)* | 0 | - | 0 |

S2 rows count against the **Season 2-pinned** ladder, not the text in this table. The differing rungs are marked below.

<details><summary>Season 2-pinned ladder (rev 2)</summary>

1. Ban civilian firearm ownership, except for tightly licensed hunting and sport use.
2. Ban semi-automatic assault-style weapons, while allowing other firearms.
3. Allow all types of firearms, but require universal background checks on every sale.
4. Keep current gun laws, adding no new restrictions. **(differs)**
5. Repeal major gun restrictions and let adults carry a firearm without a permit.

</details>

- **Other revisions:** rev 1 superseded substantive, rung_map null; rev 2 superseded substantive, rung_map {"1":1,"2":2,"3":3,"4":4,"5":5}.
- **Evidence of a problem:**
  - Rungs 4/5 overlap on carry (permitless carry fits both). S3N:198-200.
  - Rung 3 "allow all types" is met only by silence (compound). BND; annex re-audit list.
  - Re-audit owed: 49+3 rows. RT `.planning/todos/2026-10-01-annex-rulings-reaudit.md`.

| ruling | rung_map (substantive only) | note |
|---|---|---|
| ☐ identity · ☐ clarifying · ☐ substantive | | |

## Appendix A. Prior rung_maps (cited, not proposed)

No `CA_` migration header states a Season 3 rung_map. Every **rejected** revision in
`compass_topic_revisions` carries an identity map, except `judicial-bail-pretrial` rev 2 (null).
So the database holds no parked moving map that could serve as a Season 3 candidate.

Identity maps used in earlier parks or splits (candidate from the source named, only if a ruling
is clarifying): religious-freedom `CA_0030_religious_freedom_axis_b_reframe.sql`:172-173; childcare
`CA_0036_childcare_chair4_v2_park.sql`:21 (its own header, lines 57-61, says identity is false for
12 orphan rows); city-sanitation `CA_0040`:121; campaign-finance `CA_0041`:143; civil-rights
`CA_0064`:13; judicial-government-deference `CA_0081`:109; misinformation `CA_0058`:150;
residential-zoning `CA_0028`:133; trans-athletes `CA_0031`:144; local-environment `CA_0062`:172.

Moving maps already **published** (Season 1 → Season 2; not Season 3 candidates):
housing `{"1":1,"2":3,"3":4,"4":5,"5":5}` (`CA_0043`); same-sex-marriage
`{"1":2,"2":3,"3":"invalidated","4":4,"5":5}` (`CA_0074`). The homelessness-response map in the
findings doc §4 was a rolled-back test on a throwaway ladder.

## Appendix B. What the sibling Season 3 tasks need from this worksheet (pointers only)

Nothing below is built here.

- **Research into the draft season (`--season`).** The option exists (PR #927, merged; see the
  repo CLAUDE.md, "Pre-staging research into a DRAFT season"). 🔴 Research writes Season 3 rows
  that carry the **current** pin, and the pin foreign keys have no cascade. So run `--season draft`
  only on topics ruled **identity** here. On a clarifying or substantive topic, research must wait
  until the new revision is pinned, or it blocks the re-pin (as `surveillance-technology`'s 17 rows
  already do).
- **Version-aware voter reads.** Open as PR #929 ("a chair shows only on the ladder version it was
  written for"). It needs the per-topic ruling to know which topics change version at the open.
- **Candidate Connection gate.** Open as PR #926 (`claude/candidate-connection-gate`). It is a
  source rule, not a ladder rule; this worksheet changes nothing for it. Its re-research of
  Season 2 rows should finish before any Season 3 re-point on the same topic, because
  `repoint_season_answers` copies the Season 2 value it finds.
- **The Season 3 design spec and seating analysis.** Open as PR #925 (branch
  `claude/s2-seating-analysis`). Ruling item 2 above depends on it.
- **Re-point runs.** `inform.repoint_season_answers(season, topic)` runs once per substantive topic,
  as the last step before the open (findings doc, "Re-running").

## Appendix C. Season 1-only seats by ladder version (carry-forward groups C and D)

Non-blank Season 1 answers with no Season 2 row, on Season 3 topics (prod, 2026-10-08). Group C
carries (flagged) on a substantive change; group D blanks and is already hidden by version-aware
reads. Every one of these rows has a reasoning row.

| topic | Season 1-only seats | C: same version (carry, flagged) | D: older version (blank) |
|---|---:|---:|---:|
| `taxes` | 1,901 | 1,901 | 0 |
| `climate-change` | 1,816 | 0 | 1,816 |
| `abortion` | 1,809 | 1,809 | 0 |
| `healthcare` | 1,692 | 1,692 | 0 |
| `civil-rights` | 1,493 | 0 | 1,493 |
| `voting-rights` | 1,441 | 0 | 1,441 |
| `deportation` | 1,293 | 0 | 1,293 |
| `fossil-fuels` | 1,291 | 1,291 | 0 |
| `school-vouchers` | 1,202 | 0 | 1,202 |
| `medicare/aid` | 1,121 | 1,121 | 0 |
| `trans-athletes` | 834 | 834 | 0 |
| `campaign-finance` | 827 | 0 | 827 |
| `public-safety-approach` | 795 | 795 | 0 |
| `childcare` | 755 | 0 | 755 |
| `religious-freedom` | 669 | 0 | 669 |
| `economic-development` | 665 | 0 | 665 |
| `tariffs` | 654 | 654 | 0 |
| `homelessness` | 627 | 0 | 627 |
| `redistricting` | 627 | 627 | 0 |
| `ai-regulation` | 596 | 0 | 596 |
| `social-security` | 586 | 0 | 586 |
| `local-immigration` | 551 | 551 | 0 |
| `ukraine-support` | 456 | 456 | 0 |
| `homelessness-response` | 438 | 0 | 438 |
| `growth-and-development` | 426 | 0 | 426 |
| `transportation-priorities` | 425 | 425 | 0 |
| `misinformation` | 357 | 0 | 357 |
| `residential-zoning` | 351 | 351 | 0 |
| `local-environment` | 342 | 0 | 342 |
| `jail-capacity` | 287 | 287 | 0 |
| `judicial-criminal-justice` | 281 | 0 | 281 |
| `data-centers` | 279 | 279 | 0 |
| `rent-regulation` | 226 | 226 | 0 |
| `city-sanitation` | 110 | 110 | 0 |
| `judicial-interpretation` | 71 | 0 | 71 |
| `judicial-access-to-justice` | 48 | 0 | 48 |
| `judicial-transparency` | 34 | 0 | 34 |
| `judicial-government-deference` | 22 | 0 | 22 |
| `judicial-prosecution-priorities` | 20 | 20 | 0 |
| `judicial-police-accountability` | 12 | 0 | 12 |
| `judicial-bail-pretrial` | 6 | 0 | 6 |
| **total** | 27,436 | 13,429 | 14,007 |

## Reproduction

Read-only SQL on prod through the session pooler, each session started with
`SET default_transaction_read_only = on;` and checked with `SHOW transaction_read_only` (`on`).
The pooler ignores `PGOPTIONS`. Per topic pinned in Season 3 it reads: the current revision and its
`compass_stance_revisions`; the Season 1 and Season 2 pinned revisions and their stances; every
revision with status and rung_map; Season 2 answers per value; Season 2 answers on the current
revision with a non-empty `politician_context.reasoning` for the same season and revision; Season 1
answers with no Season 2 row, per value; `compass_responses` per season; `compass_topic_roles`.
Season 3 id: `7b3a066c-815d-43b2-a6a0-6a3029778075`.
