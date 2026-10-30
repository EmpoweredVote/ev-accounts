# Standing rulebook — season topic prep

Rulings that apply across topics. Read this file before every stage. A ruling here is applied, not re-argued.
The codebook (`docs/codebook/stance-and-quote-codebook.md`) still governs: where this file and the codebook
disagree, the codebook wins and this file is fixed.

Each entry gives the ruling, its date, its source and its scope. Sources under `.planning/` are in the workspace
root (`~/Documents/GitHub/.planning/`, local to Chris Andrews' machine); the ruling text here is enough to apply
them without opening the source.

## The ladder rulebook, as ruled (L1–L10)

The ruled table is in `docs/superpowers/specs/2026-10-07-season3-ladder-evaluation.md`, "Rulebook rulings" (Chris
Andrews, 2026-10-08). Quote it, not the design spec's proposal (`2026-10-07-season3-design.md` §2), where they differ.
Two differences that have misled runners: **L10 is five rungs always in Season 3, with no fewer-rung exception**
(a topic that cannot reach five kinds of act on one axis is re-axed or retired), and **E1 needs no second source**:
a co-sponsorship seats a chair by itself (design spec §3.1 proposed a second source; not adopted).

## Coding rulings

### Furthest act
- **Ruling:** a record that states the acts of two neighbouring rungs sits on the rung of its furthest act. Each
  lower act must still be stated; nothing is inferred from silence. Acts from both sides of the middle in one
  record → BLANK `adjacent-chairs`.
- **Date and source:** 2026-10-15, Chris Andrews, library books Q2
  (`.planning/research/s3-pilot-library-stage3/results.md`); confirmed for equity programs Q5, 2026-10-19
  (`.planning/research/s3-pilot-equity-programs/stage2/drafts.md` §7).
- **Scope:** every topic. Write it as an annex line for each new ladder.

### Furthest act — an escape open to everyone
- **Ruling:** the furthest-act rule applies only among acts that bind. When a record also states an escape that
  lets **any** person avoid the requirement (for any reason, or for a reasonable impediment), the record sits on the
  escape's rung, even when it also states a stricter act such as a cure. An escape limited to named exemptions does
  not count as an escape: the stricter act decides. Worked example: `voting-rights` D3 (a sworn-statement path open
  to any voter keeps a photo-ID law at rung 3, even with a cure).
- **Date and source:** 2026-10-22, Chris Andrews, season-topic-prep fixes (finding #50,
  `.planning/research/s3-prep-voting-rights/skill-test-notes.md`); generalises D3 (2026-10-21).
- **Scope:** every topic. Written into the codebook (header line "Clarified 2026-10-22" and V4.2 "An escape open
  to everyone", still 0.6).

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
- **Ruling:** on a body of **10 or fewer voting members**, a vote that carries out a duty a higher law imposes shows
  compliance, so the provision it rests on is `direction-only` (gate `higher-law-duty`; codebook V4.1 "Small bodies",
  item 2). Bodies of 11 or more keep only the 10%-No rule; this gate does not apply to them. A body's choice made within a higher law is its own choice and can
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
- **Ruling:** on a body of **10 or fewer voting members**, a vote taken on a consent agenda or en bloc, or not on
  the body's own motion, never seats (gate `consent`), and neither does a provision that carries out a higher-law
  duty (gate `higher-law-duty`). On a body of **11 or more**, only the 10%-No rule applies: a vote with under 10%
  No never seats (gate `near-unanimous`); consent, en bloc and higher-law duty are not gates there (codebook V4.1,
  which wins over this file). Pooled T1 is judged on **ungated rows**: rows no ladder can ever seat (consent
  agenda on a small body, near-unanimous large chamber, off-version sponsor) leave the denominator, as No votes did
  on 2026-10-08. All-rows figures are still reported.
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

### A fallback does not erase a stated requirement
- **Ruling:** a fallback printed beside a stated requirement (a records match, an attestation route, an affidavit)
  does not move the record off the requirement's rung, unless the rung itself turns on that fallback (as
  `voting-rights` rungs 3 and 4 do, reading D3).
- **Date and source:** D6, 2026-10-21, Chris Andrews (`.planning/research/s3-prep-voting-rights/stage3/disputes-C.md`; `.planning/research/s3-prep-voting-rights/stage4/README.md`);
  ruled for every topic, against the recommendation to keep it topic-scoped.
- **Scope:** every topic.

### Off-question records
- **Ruling:** `record_kind` describes the person's record **on this ladder's question**. A Yea vote (or any record)
  on a question the ladder no longer asks is `record_kind` = `none`: it stays out of the affirmative-record (T1)
  denominator, and its blank is classed `off-question`.
- **Date and source:** 2026-10-22, Chris Andrews, season-topic-prep fixes (finding #7,
  `.planning/research/s3-prep-voting-rights/skill-test-notes.md`).
- **Scope:** every topic.

### Own words that back your own jurisdiction's current law
- **Ruling:** own words that back the person's own jurisdiction's current law on the topic place them on the rung of
  the furthest act that law states, read from the law in force at the statement's date. Describing the law, or citing
  it only to oppose a new bill, does not count. Where the law in force states no rung act, or states acts from both
  sides of the middle, the record stays `direction-only` / `adjacent-chairs`.
- **Date and source:** Stage 2 Q2, 2026-10-29, Chris Andrews (`.planning/research/s3-prep-gun-policy/stage2/drafts.md`
  §7); the same reading as voting-rights W3-R8 (Stage 5).
- **Scope:** every topic.

### Exposure
- **Ruling:** an instrument the live ladder or its annex names is exposed. Its items stay in the test set and are
  scored apart from T1 and T3.
- **Date and source:** J1, 2026-10-20, Chris Andrews (`.planning/research/s3-prep-voting-rights/stage1/rulings.md`).
- **Scope:** every topic.

## Census and test-set rulings

### Census
- **Ruling:** companion bills (one bill per chamber, each with its own roll calls) count as two records. The
  identity check is mandatory and comes before any gate result: confirm each person on the official session list or
  minutes for the vote date, never by surname alone.
- **Date and source:** equity programs census supplement, 2026-10-19
  (`.planning/research/s3-census-education-equity-programs-supplement/stage0-supplement.md`, "State identity check").
- **Scope:** every census.

### Census — what one record is
- **Ruling:** one record per instrument per chamber: its final vote (final passage, concurrence or conference
  report; where a veto was overridden, the override vote; where a veto override failed, the chamber's last passage or
  concurrence vote). A recorded floor-amendment vote that is itself a provision
  of the topic is its own record. Procedural votes and earlier readings do not count.
- **Date and source:** 2026-10-22, Chris Andrews, season-topic-prep fixes (finding #26, a law with nine roll calls;
  `.planning/research/s3-prep-voting-rights/skill-test-notes.md`).
  Failed override: J6, 2026-10-29, Chris Andrews (`.planning/research/s3-prep-gun-policy/stage1/rulings.md`; VA SB 2
  2024 Senate).
- **Scope:** every census.

### Census — private funding of election offices
- **Ruling:** a ban on private funding of election offices is not campaign-finance evidence. It does not make a
  bill multi-subject while `campaign-finance` is served.
- **Date and source:** census Q1, 2026-10-20, Chris Andrews (`.planning/research/s3-prep-voting-rights/stage0/census.md`).
- **Scope:** every census.

### Census — a record needs its operative text
- **Ruling:** a record counts toward the census gate only once its operative text (or amendment text) has been
  read. A title or summary is a lead, not a record.
- **Date and source:** 2026-10-21, Chris Andrews, from the KY HB 574 HFA 3 correction
  (`.planning/research/s3-prep-voting-rights/stage0/census.md`; `.planning/research/s3-prep-voting-rights/stage4/README.md`).
- **Scope:** every census.

### Census — a law's own penalty is not a second subject
- **Ruling:** a penalty for breaking the bill's own rule is part of that rule and is not a second subject. A separate
  sentence change for another crime makes the bill multi-subject while `judicial-criminal-justice` is served.
- **Date and source:** census Q1, 2026-10-29, Chris Andrews (`.planning/research/s3-prep-gun-policy/stage0/census.md`).
- **Scope:** every census.

### Stage 1 sampling
- **Ruling:** one coder row per board member. Absent = no row; an abstention = a row. For state laws: the prime
  sponsors plus a seeded draw of 2 Yea and 2 Nay per chamber per law, from identity-checked rows on each chamber's
  final-passage roll call; the seed and the draw script are hashed before the draw runs. Records only (own words go
  in a separate set). Overlap with another topic's test set is allowed and flagged, checked by politician id.
- **Date and source:** equity programs Stage 1, D1–D7, 2026-10-19, Chris Andrews
  (`.planning/research/s3-pilot-equity-programs/stage1/FROZEN.md`).
- **Scope:** every Stage 1.

### Stage 1 sampling — extensions
- **Ruling:** federal acts are sampled like state laws. A recorded floor-amendment vote that is itself a provision
  of the topic is its own record (2 Yea + 2 Nay). Where a veto was overridden, the override vote is the enacting
  roll call. Existing Season rows the census reaches with a counted Yea form a whole second stratum (Nay-only rows
  are left out). Where no single prime sponsor is printed, the first-named author is the sponsor item, and there is
  none when the page is ambiguous (co-authors stay in the store). A sponsor now at a different level gets no item
  for that record. Roll calls on bills that died after one chamber or were vetoed stay in.
- **Date and source:** voting-rights Stage 1, J2–J5, J7, J9, J10, 2026-10-20/21, Chris Andrews
  (`.planning/research/s3-prep-voting-rights/stage1/rulings.md`).
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

### Validators get the default readings
- **Ruling:** blind validators at Stage 3 code from the codebook, the ladder, its annex lines, the frozen texts **and
  the pre-registered default readings**. The readings were fixed before any label, so giving them is not leakage.
- **Date and source:** 2026-10-22, Chris Andrews, season-topic-prep fixes (finding #44: all four voting-rights
  validation misses came from leaving one reading out; `.planning/research/s3-prep-voting-rights/skill-test-notes.md`).
- **Scope:** every topic.

### A third draft after Stage 3
- **Ruling:** a third draft may be written after Stage 3 from the Stage 3 lesson by kind, and tested on the same
  frozen set. It is flagged as not fully blind.
- **Date and source:** C1, 2026-10-21, Chris Andrews (`.planning/research/s3-prep-voting-rights/stage2/c-lesson.md`, `.planning/research/s3-prep-voting-rights/stage2/drafts-c.md`).
- **Scope:** every topic.

### Stage 3: the voter-placement test (T7)
- **Ruling:** Stage 3 adds a voter-placement test for every topic. Separate agents play ordinary voters: each reads only
  one ladder's question, guidance and rungs, plus a list of first-person views in a seeded order, and picks the rung
  that view would choose, or none. The views and their target rungs (or "none fits") are pre-registered with the other
  Stage 3 rules. The score is the share of placements on target, reported beside T1–T6 for the control and every
  draft. It measures what the record tests cannot: whether a voter can find their own view.
- **Date and source:** 2026-10-26, Chris Andrews (`voting-rights`, `.planning/research/s3-prep-voting-rights/stage3-fg/`:
  three voters per ladder, ten views; revision 4 placed 19/30, Draft F 25/30).
- **Scope:** every topic, from 2026-10-26.

### Stage 4: a draft that replaces an approved, unpublished revision
- **Ruling:** when the winning draft replaces a revision that was approved but never published (for example, pinned in
  a draft season that has not opened), the new revision is measured from the current published revision (its change
  class, version and rung map), and the approved one is rejected in the same migration. Draft-season rows that cite
  the approved revision are carried to the new one in that migration when Stage 3 shows none moves, or withdrawn,
  by the runner's ruling.
- **Date and source:** 2026-10-26, Chris Andrews (`voting-rights` revision 5, CA_0334, replacing revision 4).
- **Scope:** every topic.

## Stage 5 rulings

### Local records support own words, never seat alone
- **Ruling:** a local ordinance or resolution that shows which way a local official leans may serve as supporting
  evidence beside that person's own words on the topic. It never seats anyone alone. A local law that only decides
  which level may set a rule stays `adjacent` (codebook V2).
- **Date and source:** 2026-10-22, Chris Andrews, Stage 5 ruling 1
  (`docs/superpowers/specs/2026-10-22-season-topic-prep-stage5-code-everyone-design.md` §5).
- **Scope:** every topic with local officials in scope.

### Shown quotes need no human hold
- **Ruling:** a person's own words shown to voters as "own words, not on the scale" go live without human review,
  once the AI quote check confirms the passage is on its source page word for word, is the person's own words
  (codebook V1), and is on the topic. A failed check keeps it off the page.
- **Date and source:** 2026-10-22, Chris Andrews, Stage 5 ruling 2a (design §9).
- **Scope:** every topic.

### Own-words seats: the hold ends after a blind check
- **Ruling:** a seat placed on own words alone keeps the `statement-evidence` human hold until a blind gold sample
  of own-words seats on that topic agrees with the coder at the Stage 3 validation bar (≥ 95%). When it passes, the
  hold is retired for that topic, and CLAUDE.md's "separate reliability stratum" rule is updated in the same PR.
- **Date and source:** 2026-10-22, Chris Andrews, Stage 5 ruling 2b (design §9).
- **Scope:** every topic, decided per topic.

### A vote on the record carries a joint seat
- **Ruling:** a seat that rests on the person's own words together with a legislative record (a vote, sponsorship
  or other act on an instrument, not a local record) is record evidence. It goes through the record gate and does
  not take the `statement-evidence` hold. Only a seat on own words alone, or own words with a local record, keeps
  the hold until the topic's blind check passes.
- **Date and source:** 2026-10-23, Chris Andrews, Stage 5 Phase B review (`backend/scripts/lib/stage5Write.ts`
  `planBatch`: `evidence_type = record` when any cited finding is a non-local record).
- **Scope:** every topic.

### The Stage 5 early-check bar
- **Ruling:** the early check stops the run and asks whether to fix the rungs when "doesn't fit" is more than 1 in 5
  of the people with any on-topic evidence, **or** any single theme from the theme pass holds more than 1 in 10 of
  them. Doesn't-fit cases whose only record is a No vote (`nay-only`) or a gated vote (`gate`) are counted and
  reported apart, and left out of both sides of both bars: no rung change can seat them.
- **Date and source:** 2026-10-22, Chris Andrews, Stage 5 ruling 3 (design §6); the No-vote and gated cases ruled
  apart the same day, after the `voting-rights` pilot (`.planning/research/s3-prep-voting-rights/stage5/`).
- **Scope:** every topic.

### The early check may run on a seeded sample
- **Ruling:** when a unit is large, the early check may run on a seeded random sample of it (the seed and the draw
  recorded before the draw). The rest of the unit is researched after the check passes; nothing found is wasted.
- **Date and source:** 2026-10-22, Chris Andrews, `voting-rights` run: 300 of 1,452 federal people, plus every
  state legislator in IN, NC and MA.
- **Scope:** every topic.

### A Candidate Connection survey answer is the candidate's own words
- **Ruling:** a candidate's own answer to Ballotpedia's Candidate Connection survey counts as their own words and
  may seat them, even when it is their only source. Every other Ballotpedia page (editorial bio, measure page)
  still cannot seat anyone alone. The source must link the survey section (`#Campaign_themes`) and the quoted
  words must sit inside that section (`backend/scripts/lib/candidate-connection.mjs`). The verifier cannot open
  Ballotpedia, so such a seat always goes to a person for review; the batch keeps a saved copy of the section
  (`survey-sections.json`) for the gate.
- **Date and source:** 2026-10-07, Chris Andrews (Season 2 pilot); confirmed 2026-10-29, Chris Andrews, voting-rights
  federal-held batch (Christy Peterson).
- **Scope:** every topic.

### Party labels never reach a reader; shown quotes bracket them out
- **Ruling:** Empowered Vote is anti-partisan: no reader should get a party as a shortcut for whom to agree with. A
  party label is a party's name or colour used for people or places ("Republicans", "the GOP", "Democratic
  lawmakers", "R-Idaho", "(D-GA)", "red states"); "democratic process" is not one.
  1. A quote shown to voters or to Stage 3 test voters (own-words passages, blinded quotes) replaces each party label
     with a bracketed neutral word ("[some lawmakers]", "Sen. Jim Risch […] wrote"), so the edit is visible and the
     person's point is kept.
  2. An evidence snippet (the verifier's verbatim page text) is never edited: the builder picks a stretch with no
     party label, and drops the snippet when the page has none near the person.
  3. The quote check fails a passage for a party only when the party is its point (a call to back or oppose a
     party); a passage that only mentions one passes once the label is bracketed out.
  The bracket words are a fixed list, so no slanted word can be slipped in; it grows only by ruling: "[…]", "[some
  lawmakers]", "[some officials]", "[some voters]", "[some states]", "[others]". No note explains the brackets: the
  source link under every shown quote is where a reader sees the full words.
- **Built (CA_0337, applied 2026-10-29; PR #1219):** `own_words_passages.shown_text` holds the bracketed text and the
  public profile serves it; `passage` keeps the exact words. The quote checker writes `shown_text`; the writer
  stores it only when `bracketEditProblem` (`backend/src/lib/partyLabels.ts`) finds nothing changed but labels into
  listed words, and the check's `shown_sha256` covers it. `accumulateEvidence` skips a snippet with a label. One
  detector (`namesParty`) serves quotes, notes and snippets, and adds party-state tags ("R-Idaho", "(D-GA)",
  "D-N.Y.") and "Smith (R)"; the stance gate reads those tags and colours too. Stage 3 blinded quotes have no code
  path: whoever builds them brackets labels by hand with the same list.
- **Date and source:** 2026-10-29, Chris Andrews, voting-rights federal-held batch
  (`.planning/research/s3-prep-voting-rights/stage5/write/federal-held/PREVIEW.md`). Replaces "Quotes that name a
  party are never shown" (2026-10-22), which failed every mention and never edited a quote. The same day, 7 draft-season
  snippets that tagged people with a party were deleted (backup in that folder, `party-snippets-backup.json`).
- **Scope:** every topic.

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

### voting-rights — D3, C-Q4, DC1 (rung 3/4 line)
- **Note (2026-10-22):** D3 is now a general rule ("Furthest act — an escape open to everyone", above). C-Q4 and DC1
  stay topic-scoped.
- **Reading:** D3 — a sworn-statement path open to any voter with a reasonable impediment keeps a law at rung 3 even
  when it also states a cure; sworn statements only for named exemptions leave it at rung 4. C-Q4 — on the mail
  branch, a statement limited to people never issued any listed ID number is a named exemption. DC1 — a mail-ballot
  request-ID rule whose failure still lets the ballot be sent and counted on documents that are not the requested
  ID does not meet rung 4.
- **Date and source:** D3, C-Q4, DC1, 2026-10-21, Chris Andrews (`.planning/research/s3-prep-voting-rights/stage3/disputes.md`,
  `.planning/research/s3-prep-voting-rights/stage3/disputes-C.md`); written into the codebook "Clarified 2026-10-21" header line and the Season 3 annex
  (`docs/codebook/annex/season3/voting-rights.md`, EmpoweredVote/ev-accounts#1096).
- **Scope:** the Season 3 revisions 4 and 5 of `voting-rights` only (CA_0318; CA_0334, which keeps every act of
  revision 4).
- **Contrast:** the standing furthest-act rule (above). A record that states both a rung 3 and a rung 4 act sits at
  rung 4.

### voting-rights — F-Q2 (citizenship documents beside a ballot rule)
- **Reading:** a record that requires a document proving citizenship to register sits on rung 5 whatever ballot rule
  it also states, an exception to the `adjacent-chairs` line ("acts from both sides of the middle") for this topic.
  So a voter's "proved it once, at registration" view and the coder's reading of such a law land on the same rung.
- **Date and source:** F-Q2, 2026-10-26, Chris Andrews (`.planning/research/s3-prep-voting-rights/stage2/drafts-fg.md`
  §7); written into the Season 3 annex (`docs/codebook/annex/season3/voting-rights.md`, CA_0334).
- **Scope:** the Season 3 revision 5 of `voting-rights` only (CA_0334).
- **Contrast:** the standing furthest-act rule, under which acts from both sides of the middle in one record are BLANK
  `adjacent-chairs`.

### voting-rights — H-P1, H-Q3, H-Q4 (fallback not stated → rung 4)
- **Reading:** a photo-ID requirement whose own text states no sworn-statement path open to any voter sits at rung 4,
  with or without a stated cure. Exceptions left to later law with none named ("which may include exceptions") are no
  escape (H-Q3). A bill that sets the accepted-ID list is read on its own printed text; a sworn statement in a section
  it neither prints nor restates is not read in (H-Q4; a cross-reference to another law's challenged-voter procedure
  is not read in either, DH2). A person with a stated-escape record (3) and a silent photo-ID record (4) sits at 3
  whatever the dates (H-P1, reading B); a stated polls escape beside a mail-ballot ID record sits at 4 (DH3). Own
  words rejecting voting without photo ID state the rung 4 act (DH1).
- **Date and source:** H-P1, H-Q3, H-Q4, DH1–DH3, 2026-10-27, Chris Andrews
  (`.planning/research/s3-prep-voting-rights/stage2/drafts-h.md` §7, `.planning/research/s3-prep-voting-rights/stage3-h/results.md`,
  `.planning/research/s3-prep-voting-rights/stage3-h/disputes-H.md`); written into the Season 3 annex
  (`docs/codebook/annex/season3/voting-rights.md`, "Draft H lines").
- **Scope:** the Season 3 revision 5 of `voting-rights` only (CA_0334; the text is unchanged, so no new revision).
- **Contrast:** the codebook rule that the newest evidence governs ("superseded-by-later") still applies where a later
  record states a different rule; H-P1 reads a silent record as not contradicting a stated escape.

### gun-policy — Q5 (a federal bar on state carry permits)
- **Reading:** a federal bill that bars states from requiring a carry permit is on-question and sits on rung 5: it
  states the carry rule, not only which level decides.
- **Date and source:** Q5, 2026-10-29, Chris Andrews (`.planning/research/s3-prep-gun-policy/stage2/drafts.md` §7);
  written into the codebook "Clarified 2026-10-30" header line and the Season 3 annex
  (`docs/codebook/annex/season3/gun-policy.md`).
- **Scope:** the Season 3 revision 4 of `gun-policy` only (CA_0338).
- **Contrast:** codebook V2 / H12: a law that only decides which level may act is `adjacent`.

### gun-policy — J7, D4 (single-subject scope)
- **Reading:** a self-defense part (no duty to retreat, a justifiable-homicide line) is not `judicial-criminal-justice`
  evidence; a background-check notice to immigration enforcement is not `deportation` evidence. Neither makes a gun
  law multi-subject.
- **Date and source:** J7, 2026-10-29 (`.planning/research/s3-prep-gun-policy/stage1/rulings.md`); D4, 2026-10-30
  (`.planning/research/s3-prep-gun-policy/stage3/disputes.md`); Chris Andrews. Written into the codebook "Clarified
  2026-10-30" header line and the Season 3 annex.
- **Scope:** the Season 3 revision 4 of `gun-policy` only (CA_0338).
- **Contrast:** the strict single-subject test (codebook V4.1).

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
