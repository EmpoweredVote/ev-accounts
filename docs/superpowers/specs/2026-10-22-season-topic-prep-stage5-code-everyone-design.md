# Season topic prep — Stage 5: code everyone (design)

**Date:** 2026-10-22. **Owner:** Chris Andrews (operator, `CA_` namespace).
**Extends:** `docs/superpowers/specs/2026-10-20-season-topic-prep-skill-design.md` and
`.claude/skills/season-topic-prep/` (Stages 0a–4).
**Prompted by:** the first full round on `voting-rights` (CA_0318, EmpoweredVote/ev-accounts#1096, #1118).

## 1. Why

Stages 0a–4 fix a topic's question and five rungs, and test them on a small frozen set of records. On
`voting-rights` that set held 66 people, all chosen because they had a vote on a voter-ID bill. The Season 3 run
seated 57 of them (86%). That number is real for the people chosen. It says nothing about the roughly 2,000
sitting federal and state officials in scope, most of whom were never looked at.

Two things follow:

1. **The rungs are only proven on people who were picked because they fit the test.** Coding everyone is the real
   test. A large share of people who have a stance that no rung holds means the rungs need work, or the topic
   needs splitting, and that has to be found **before the season opens**, because an open season's question and
   rungs never change.
2. **Voters see nothing when a person has no seat.** Today the API drops every blank answer
   (`compassService.ts` `getPoliticianAnswers`, `WHERE value <> 0`), so a topic simply vanishes from the
   profile. A voter cannot tell "we never looked" from "we looked and found nothing" from "they spoke on it, but
   not on one of these five positions".

Stage 5 runs after Stage 4 applies a revision to the draft season. It researches everyone the topic applies to,
saves what it finds so no one is searched twice in a season, reports how the rungs held up, and gives voters a
true sentence or the person's own words for every blank.

## 2. Goals

- **G1 — Everyone in scope is researched once per season.** Scope is in §4.
- **G2 — Findings are saved by person and by subject, apart from the coding.** A rung change, a reworded
  question or a topic split next season is handled by re-coding saved findings, with new searching only for real
  gaps.
- **G3 — An early check stops the run if the rungs look wrong,** and a full report at the end shows, for
  everyone, how many have no stance found, how many fit a rung, and how many have a stance that does not fit,
  with the reasons drawn from the cases themselves (open coding).
- **G4 — Every person has something true for voters on every topic that applies to them:** a seat with its
  reasoning; or their own words on the topic with sources, even when they show only a direction; or the plain
  sentence that we researched and found no public stance.
- **G5 — Every quote shown to voters is checked by a second AI agent** against its source page before it goes
  live.

## 3. Non-goals and anti-goals

**Non-goals (not in this design):**
- Validation Quests as the review path. Rows go live after the automated checks; Validation Quests will affirm
  them later, designed separately (Chris Andrews, 2026-10-22). This design only leaves room for it (§9).
- The human admin review queue as a gate. It is the bottleneck this replaces (§9).
- People who are neither sitting officials nor active candidates: past candidates, people who lost or withdrew,
  former officials.
- Changing how Stages 0a–4 pick or test the question.

**Anti-goals (a failure even if everything runs):**
- **Anything made up.** A quote that is not on its source page, a stance inferred from silence, a party used as
  evidence. Antipartisan rule: no party names or party colours anywhere, including in the voter text.
- **Searching the same person twice in a season** for the same subjects, except in the early stages of a topic.
- **Forcing a case into a fixed list of reasons.** The "doesn't fit" reasons come from the cases (§6).
- **Fixing the rungs after the season opens.** Stage 5's job is to find rung problems while they can still be
  fixed.

## 4. Who is researched, and when

**Scope (Chris Andrews, 2026-10-22):**
1. **Sitting officials at every level the topic applies to** (`inform.compass_topic_roles`: federal, state,
   local, judicial, school, as listed for that topic).
2. **Candidates in active races** (`essentials.race_candidates.candidate_status = 'active'`), in races at the levels
   the topic applies to (my call). No one else. Answers and findings are keyed by `politician_id`; the builder
   first counts active candidates with no politician record and reports the gap before any essentials write.

**Election timing (2026).** The general election is 2026-11-03. Season 3 will mostly serve the winners. Stage 5
does not wait for the results:
- **Before the results:** research sitting officials who stay past January (seat not up this year, or running
  again), and every candidate in an active race, challengers and incumbents alike, so every winner is already
  done. Officials who are leaving get only the cheap pass (their votes already in the source store count toward
  the rung check, §5 step 2); no open research.
- **After the results:** drop the losers. As close races are called (days to a week), finish only those. Georgia
  and Louisiana can hold December runoffs; their candidates stay active until then.
- **Builder's first job here:** find out whether essentials can tell who is leaving. `race_candidates.is_incumbent`
  shows incumbents on a ballot; an official whose seat is up and who is on no ballot is leaving. Report the gaps
  before relying on it.

**Order:**
1. **Federal, as one batch.** One Congress, one set of bills, one source profile: the cheapest first read of the
   rungs.
2. **States, one at a time.** Bills, vote records and websites differ by state, and patterns show up per state.
   **The first two or three states are the early check** (§6). Pick them to differ on the topic (for
   `voting-rights`: a strict-ID state, a state that changed its law, a state with no ID rule).
3. **Within each state:** people already in the source store's roll calls first (sources on file), then open
   research for the rest.
4. **Local, then candidates' remaining gaps.** Local officials where the topic applies (often on own words only,
   §5).

## 5. The stage, step by step

**Step 1 — Build the roster.** Everyone in scope (§4) with their office, level, state and why they are in scope
(sitting / candidate / both). Sitting officials come from `essentials.office_current_holder` (CLAUDE.md
"Officeholder occupancy": a politician-rooted join needs `DISTINCT ON (p.id)` or a chosen office;
`politicians.office_id` is a legacy snapshot, not the source). Level comes from `levelForDistrict`
(`backend/src/lib/topicApplicability.ts`), as `topic:seat-rate` does. Write `stage5/roster.tsv` in the research folder. Show the counts per level and per
state before anything runs.

**Step 2 — Pre-fill from the source store.** For every instrument in `backend/data/source-store/` that the topic's
census accepted, every member vote matched to a person on the roster becomes a saved finding (step 3 format)
without any new search. Unmatched names on those roll calls are matched to the roster with the identity check the
skill already requires (official member lists, never surname alone; RULINGS.md "Census"). On `voting-rights`
this alone reaches about 330 sitting officials (530 matched people with a Yes vote; 1,020 Yes votes not yet
matched).

**Step 3 — Find (search), once per person per topic.** **Everyone on the roster gets an own-words search**, even
people Step 2 already placed from a vote (Chris Andrews, 2026-10-22). A vote on file saves the record search, not
the own-words search; skipping it would hide the "doesn't fit" cases this stage exists to find. Research **broadly
on the topic's subject**, not only on the five rungs: records (votes, sponsorships, vetoes, signatures, lawsuits,
official letters, amendments, local ordinances and resolutions) and own words (questionnaires, debate and forum
answers including On the Record transcripts, issue pages, pledges, speeches, interviews, posts). The codebook V3
classes apply unchanged. Use the existing `research-stances` discovery (STEP 0.5 and STEP 1).
- **Save every finding** (§7): the passage or the vote, the source, the date, a saved copy, a short plain note of
  what it says, and subject tags in plain words. Save the searches that found nothing too.
- Searching and coding are separate passes. The searcher does not decide the rung.

**Step 4 — Code (judge) from saved findings only.** The coder reads the person's saved findings and gives one of:
- **Seated** on a rung, with reasoning, as today.
- **No stance found:** nothing on the topic after a full search. The note says what was searched.
- **Doesn't fit:** there is on-topic evidence, but no rung holds it. The coder writes an **open note** in its own
  words: what the person said or did, and why no rung holds it. It may add any of the starter tags (§6), several,
  or none.
- Existing blank classes (`source-gap`, `gate`, `wording`, `no-lever`, `off-question`, `nay-only`) map onto
  these three; keep them as the detail.

**Local records (Chris Andrews, 2026-10-22).** A local ordinance or resolution that shows which way a local
official leans (for example a clinic buffer-zone ordinance, or a city fund for abortion travel) is saved and
shown. It **never seats anyone alone**; with the person's own words it may help place them. A local law that only
decides *which level* may set a rule stays `adjacent` (codebook V2, ruling Q10). 🛑 **Needs a ruling before
build:** today `compass_topic_roles.evidence_basis = 'own-words'` for local on `voting-rights`, so a local record
counts for nothing. The ruling asked for: may a local record serve as supporting evidence beside own words?

**Step 5 — Early check** (§6). **Step 6 — Full report** (§6). **Step 7 — Write and show** (§8).

## 6. The early check and the report

**Early check.** After federal and the first two or three states, the run pauses and shows the split for
everyone so far: no stance found / seated / doesn't fit, with the open notes. If **"doesn't fit" is more than
1 in 5 of the people who have any on-topic evidence** (a placeholder: Chris Andrews sets the real bar), it stops
and asks whether to fix the rungs first (back to Stage 2, or a split) or carry on. Otherwise it continues.

**Open coding of "doesn't fit."** No fixed list decides a case.
- **Starter tags** the coder may use, any number, or none: *between two rungs*; *a related but different
  question* (a possible other topic); *a position no rung names*; *direction only* (shows a side, not a rung —
  Chris's example: a person who says only "pro-life" on a reproductive-rights topic); *a different level's
  lever*.
- **The open note is required for every case**, tagged or not. It is what the theme pass reads.
- **Theme pass.** At the early check and at the end, a separate agent reads all the open notes together and groups
  them into themes the notes suggest, naming each theme in plain words. It gives each theme a count, the cases
  behind it, and whether it points at a rung change, a new topic, or nothing. Because the notes are saved, the
  theme pass can be re-run any time without new searching.

**Full report** (`stage5/report.md`, per topic): counts per level, per state and overall for the three outcomes;
the themes with cases; the rungs held (per-rung counts); and a plain recommendation: ship the rungs as they are,
fix them (with the cases that show why), or split the topic. Post the summary to the topic's Monday Story (the
skill's existing Monday step).

**Seat rate, measured honestly.** Today `topic:seat-rate --season draft` counts written answers only, so blanks
never written make it read 100% (#1118). Stage 5 reports the rate over the whole roster: seated ÷ everyone
researched, and seated ÷ everyone with on-topic evidence.

## 7. Saved findings: search once, reuse across seasons

The source store (`backend/data/source-store/`) already holds instruments with per-member votes, jurisdictions,
and dead ends. Its `people/<politician-id>.json` file holds only URLs with a kind and topic keys. Stage 5 needs a
richer per-person record. Each finding holds:

- the person, the source URL, the kind (`record` / `own-words`), the date of the act or words;
- for own words, the **exact passage**; for a record, the instrument id and the person's act on it;
- a saved copy reference with its SHA-256 (large copies stay in the research folder, as today);
- a short plain note of what it says;
- **subject tags in plain words** (for example "voter ID at the polls", "mail-ballot ID", "proof of
  citizenship"), not rung numbers, so a reworded or split topic can be re-coded from them;
- who found it, when, how (the existing provenance fields).

Searches that found nothing are saved with the person, the subjects searched, the places searched, and the date.

**Reuse rules.**
- Within a season: never search a person again for subjects already searched, unless the saved finding is broken.
- Next season, or after a reword or split: re-code from saved findings first; search only for subjects the saved
  findings do not cover, or for acts and words newer than the last search.
- A full re-search is for a changed question, not changed rungs.

## 8. What voters see when there is no seat

Today the API drops value-0 rows, and the profile shows nothing. Stage 5 changes that.

**Only for people Stage 5 researched (my call).** The new voter text needs a stored marker that this person was
researched on this topic in this season, separate from `value = 0`. Older blanks (a ladder moved under a seat) and
people never researched (officials who are leaving, local officials not yet reached) show nothing, as today.
Voters are never told "we researched" when we did not.

**Three cases, for every topic that applies to the person:**
1. **Seated:** as today (spoke, reasoning, citations).
2. **Doesn't fit, with own words:** the person's **exact on-topic words**, with source link and date, labelled
   plainly as their own words and not a position on the scale. This includes words that show only a direction
   (Chris Andrews, 2026-10-22: shown right away, no human review). A local record that shows direction is shown
   with them, described in plain words.
3. **No stance found:** "We researched [name] and found no public stance on [topic]." with the date of the
   research.

**Safeguard: the quote check (G5).** Before any quote or record summary goes live, a second AI agent confirms:
the passage is on the source page word for word; it is the person's own words (codebook V1); it is about this
topic. A failed check keeps it off the page and logs why. This runs on every quote, every time.

**Wording rules for the voter text:** plain words; no party names or colours; no adjectives about the person;
dates on everything; "no public stance found" never phrased as a judgement.

**Build pieces (left to the builder, named here so the plan covers them):** the API must return the blank state
and its voter text instead of dropping value-0 rows (`getPoliticianAnswers`, `getCandidateAnswers`); the
essentials accordion (`StanceAccordion`, ev-ui) and the compass need a row for "own words, not on the scale" and
for "no public stance found"; the existing own-words quote display (Read & Rank quotes in `StanceAccordion`) is the
starting point. Where the stored own-words passages live (a new table, or `politician_context` plus evidence
rows) is the builder's call; it must be per person, per topic, per season.

## 9. Review: automated now, Validation Quests later

- **Today:** the stance process sends every own-words row to a human queue (`statement-evidence` in
  `research-stances`), and CLAUDE.md says an own-words chair is a separate reliability stratum that goes to
  review "until that stratum has its own blind gold". That queue is the bottleneck. 🛑 **Needs a ruling before build, in two parts**, because
  they are different kinds of row:
  - **(a) Shown quotes** ("own words, not on the scale", §8 case 2). Display only; no voter answer is compared
    with them. Chris Andrews has said these go live without human review (2026-10-22); the ruling confirms it in
    writing.
  - **(b) Seats placed on own words alone.** Voters' answers are compared with these. Retiring the hold for them
    overturns the CLAUDE.md "separate reliability stratum" rule, so CLAUDE.md must be updated in the same PR if
    the ruling says yes.
  Rows that pass the automated checks (the pre-write evidence gate, the quote check, the existing mechanical QA)
  then go live with the draft season without a person.
- **Later:** Validation Quests (`empowered-validation-quests`) will let users affirm or dispute live rows. Stage 5
  marks each row with what checked it, so Validation Quests can pick them up. Its design is separate.

## 10. Constraints

- **An open season never changes** (`closed_season_is_immutable` trigger, season pins). Stage 5 writes only to the
  draft season. Draft rows are hidden from voters until the season opens (CLAUDE.md "Pre-staging research into a
  DRAFT season"), so "live right away" in §8–§9 means live **when the season opens**, with no human hold before.
- **A blank is `value = 0`** (CLAUDE.md). Any new read that shows blanks to voters must say so with a
  `-- @zero-scope:` marker, and keep the filter outside the newest-season collapse.
- **Budget rule (Chris Andrews, 2026-10-22):** search each person **once per topic per season** for now. No other
  cost cap. Each topic's Stage 5 run stands alone, but files its findings by subject so later topics reuse them
  (§7). **Later:** switch to one search per person covering every topic, once the saved findings are a good body of
  evidence. Not in this build; the findings format must not block it.
- **No database writes before the early check passes** (my call). Findings and codes stay in the research folder
  and the source store until then, so a rung fix or a split leaves no draft-season rows to undo. After it passes,
  each batch is written on Chris Andrews' yes.
- **Rules carry over:** the codebook, RULINGS.md, the identity check, the pre-write `audit-chair-evidence.mjs`
  gate, `--season draft` on every step, the source store's validate and merge rules, explicit pathspecs on commit,
  never print `DATABASE_URL`, never commit in `~/Documents/GitHub` itself.
- **Every database write waits for Chris Andrews' yes,** per batch.

## 11. Decided, and left to the builder

**Decided (Chris Andrews, 2026-10-22):** everything attributed above — scope (sitting officials, then active
candidates only); research before the results, winners after; open coding with optional starter tags; own words
shown right away, including direction-only words; the AI quote check; Validation Quests later, not the admin
queue; local records as supporting direction evidence (pending the §5 ruling); search once per season and reuse
across seasons.

**Also decided (2026-10-22, after review):** search once per person per topic for now, one search across all
topics later; everyone gets an own-words search, including people placed from a vote.

**My calls (to check):** no database writes before the early check passes; the new voter text only for people
Stage 5 researched; the review ruling split into (a) shown quotes and (b) own-words seats; candidates only in races
at the topic's levels; federal first, then states one at a time; the early check after federal plus two or three
contrasting states; the 1-in-5 placeholder bar; keeping the existing blank classes as detail under the three
outcomes; the per-finding fields in §7; the voter sentence wording in §8.

**Left to the builder:** where the richer findings and passages are stored; how the theme pass is prompted; batch
sizes and parallelism; how the run resumes after a stop; the exact API and UI shape for the two blank states; how
Stage 5 is split into skill text, scripts and tests.

**Open rulings (🛑 before build):** (1) local records as supporting evidence (§5); (2) retiring the
`statement-evidence` human hold, (a) for shown quotes and (b) for own-words seats (§9); (3) the real "doesn't fit"
bar (§6).
