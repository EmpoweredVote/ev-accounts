# Standing rulebook — season topic prep

Rulings that apply across topics. Read this file before every stage. A ruling here is applied, not re-argued.
The codebook (`docs/codebook/stance-and-quote-codebook.md`) still governs: where this file and the codebook
disagree, the codebook wins and this file is fixed.

Each entry gives the ruling, its date, its source and its scope. Sources under `.planning/` are in the workspace
root (`~/Documents/GitHub/.planning/`, local to Chris Andrews' machine); the ruling text here is enough to apply
them without opening the source.

## Coding rulings

### Furthest act
- **Ruling:** a record that states the acts of two neighbouring rungs sits on the rung of its furthest act. Each
  lower act must still be stated; nothing is inferred from silence. Acts from both sides of the middle in one
  record → BLANK `adjacent-chairs`.
- **Date and source:** 2026-10-15, Chris Andrews, library books Q2
  (`.planning/research/s3-pilot-library-stage3/results.md`); confirmed for equity programs Q5, 2026-10-19
  (`.planning/research/s3-pilot-equity-programs/stage2/drafts.md` §7).
- **Scope:** every topic. Write it as an annex line for each new ladder.

### Small-body rule
- **Ruling:** on a body of 10 or fewer voting members the tally does not decide `near-unanimous`. Such a vote can
  carry a chair only if it was its own action item (not a consent agenda or an en bloc vote) and the provision the
  chair rests on is the body's own choice (not a duty a higher law imposes). Bodies of 11 or more keep the 10%-No
  rule.
- **Date and source:** 2026-10-15, codebook 0.6, V4.1 "Small bodies" (direction agreed by Chris Andrews; wording
  not yet ruled).
- **Scope:** every topic. 0.6 rows go to review until a small gold round on board votes covers them.

### Single-subject test
- **Ruling:** a bill is `multi-subject` when any operative part would be evidence for a different compass topic of
  the season being coded. Judge it against the season's served topic list, and record that list's season and the
  codebook version with the verdict.
- **Date and source:** 2026-10-14, codebook 0.5, V4.1 "The single-subject test".
- **Scope:** every topic. Topic-scoped readings of this test are listed below; they are **not general**.

### Higher-law duty vs own choice
- **Ruling:** a vote that carries out a duty a higher law imposes shows compliance, so the provision it rests on is
  `direction-only` (gate `higher-law-duty`). A body's choice made within a higher law is its own choice and can
  seat: a menu duty where the body picks the option (police U1), a duty that applies only once the body has chosen
  (police S1, Virginia SRO memorandum), a resolution citing an executive order or guidance letter that is not a
  statute (equity G4), and a city-chosen provision inside a state condition (homelessness, Oregon
  time-place-manner: the chair counts only where it rests on the city's own hours or places).
- **Date and source:** library books 2026-10-15 (`.planning/research/s3-pilot-library-stage3/results.md`); police
  U1 2026-10-16 and S1 2026-10-19 (`.planning/research/s3-pilot-school-police-stage3-supp/results.md`); equity G4
  2026-10-19 (`.planning/research/s3-census-education-equity-programs-supplement/stage0-supplement.md`);
  homelessness Stage 0a call 1, 2026-10-20 (`.planning/todos/2026-10-20-s3-pilot-homelessness-plan.md`).
  All Chris Andrews.
- **Scope:** every topic. Each topic's annex lists, per state, the standing duties boards carry out.

### Gating
- **Ruling:** a consent-agenda or en bloc vote and a near-unanimous vote never seat. Pooled T1 is judged on
  **ungated rows**: rows no ladder can ever seat (consent agenda, near-unanimous chamber, off-version sponsor) leave
  the denominator, as No votes did on 2026-10-08. All-rows figures are still reported.
- **Date and source:** Q6, 2026-10-19, Chris Andrews (`.planning/research/s3-pilot-school-police-stage3-supp/results.md`,
  "Rulings, 2026-10-19"); T1 over affirmative records, 2026-10-08
  (`docs/superpowers/specs/2026-10-07-season3-ladder-evaluation.md`).
- **Scope:** every Season 3 topic.

### A blank spoke is correct; pause and keep votes
- **Ruling:** a blank spoke is a correct result, not a failure to fix. A vote to pause, keep or restore something,
  when no rung states keeping or restoring, shows a side only: BLANK `direction-only`. Ruling out another rung is
  not evidence for this one (codebook V4.2).
- **Date and source:** CLAUDE.md "Compass chairs are five distinct stances"; equity programs Stage 3, 2026-10-19
  (`.planning/research/s3-pilot-equity-programs/stage3/results.md`, Virginia Beach pause motions).
- **Scope:** every topic.

## Census and test-set rulings

### Census
- **Ruling:** companion bills (one bill per chamber, each with its own roll calls) count as two records. The
  identity check is mandatory and comes before any gate result: confirm each person on the official session list or
  minutes for the vote date, never by surname alone.
- **Date and source:** equity programs census supplement, 2026-10-19
  (`.planning/research/s3-census-education-equity-programs-supplement/stage0-supplement.md`, "State identity check").
- **Scope:** every census.

### Stage 1 sampling
- **Ruling:** one coder row per board member. Absent = no row; an abstention = a row. For state laws: the prime
  sponsors plus a seeded draw of 2 Yea and 2 Nay per chamber per law, from identity-checked rows on each chamber's
  final-passage roll call; the seed and the draw script are hashed before the draw runs. Records only (own words go
  in a separate set). Overlap with another topic's test set is allowed and flagged, checked by politician id.
- **Date and source:** equity programs Stage 1, D1–D7, 2026-10-19, Chris Andrews
  (`.planning/research/s3-pilot-equity-programs/stage1/FROZEN.md`).
- **Scope:** every Stage 1.

## Process rulings

### Revisions are applied without expert review
- **Ruling:** T4 (blind operator labels) is replaced by the adversarial check. Revisions are applied once every
  dispute is ruled; every seated row that rests on a bill or ordinance is queued for future expert review in
  `stage3/expert-queue.json`, and the revision's rationale says so. Old T4 items on the Blind Gold Desk (`t4lib`,
  `t4pol`, `t4eq`) are retired from the gate and stay available as optional expert-queue items.
- **Date and source:** 2026-10-20, Chris Andrews (`docs/superpowers/specs/2026-10-20-season-topic-prep-skill-design.md`
  §5.6, §10); library books (CA_0310) and equity programs (CA_0314) were applied with T4 open.
- **Scope:** every topic from Season 3 on.

## Topic-scoped readings

These change how a general rule reads for **one topic only**. They are not general. Do not apply them to another
topic; if a topic seems to need the same reading, ask for a ruling and point to the entry here.

### education-equity-programs — R1 (single-subject scope)
- **Reading:** a separate operative part makes a bill multi-subject only when it acts **outside K-12 schools**
  (colleges' or state agencies' own operations, other employers). K-12 harassment, hiring and Title VI parts of a
  school equity instrument, and preparation standards for K-12 staff, stay inside the topic.
- **Date and source:** R1, 2026-10-19, Chris Andrews
  (`.planning/research/s3-pilot-equity-programs/stage3/results.md`); written into codebook 0.6, V4.1 "The
  single-subject test" (the "Clarified 2026-10-19" header line, `docs/codebook/stance-and-quote-codebook.md`).
- **Scope:** the Season 3 revision 2 of `education-equity-programs` only (CA_0314).
- **Contrast:** homelessness kept the strict test (2026-10-20): a camping law that also funds shelters is
  multi-subject while `homelessness-response` is served. Bundled laws are counted on their own line so the cost of
  the strict test is visible.

## How to add a ruling

1. A ruling enters this file only when the runner made it, it is dated, and it applies beyond one topic. A reading
   for one topic goes in that topic's Season annex (`docs/codebook/annex/season3/<topic>.md`); if it narrows a
   general rule, also list it under "Topic-scoped readings" above.
2. Propose the line in the same PR as the revision or stage that produced it. Say in the PR which section it joins.
3. Write it as the entries above: **Ruling** (plain words, one rule), **Date and source** (date, who ruled, the file
   that records it), **Scope** (every topic, every census, or one topic).
4. If a new ruling changes or replaces an older one, edit the older entry and say what replaced it and when. Do
   not leave two entries that disagree.
5. If it changes coding results, the codebook needs a line too (and maybe a version bump). Ask; the codebook wins.
