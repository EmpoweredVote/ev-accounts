# Position summaries, and placing local officials — design

Written 2026-11-22. Decisions by Chris Andrews (the runner) in conversation the same day, unless marked
**(builder's call)** or **(proposed, not yet ruled)**.

## 1. Why

Stage 5 places people on a topic's five rungs from their record: votes, sponsorships, bills. Local officials
(council members, mayors, county commissioners, sheriffs) rarely have one, and in most states they cannot make gun
law at all, because state law pre-empts it. Yet a voter still wants to know where their mayor stands on guns
(ruling 2026-10-06, "positions without a lever").

Most local officials will never have enough evidence for a specific rung. Many have enough to say which way they
lean and what they have said or done. Today a voter sees one of three things: a rung, a list of quotes under "In
their own words — not a position on the scale", or "We researched … and found no public stance". Nothing in our
own words says what the person thinks.

So this design adds **a short summary, in our own words, of where a person stands on a topic**, with numbered
citations to the evidence. It is shown on the person's profile, for **every politician with any evidence on the
topic**, at every level, not only local officials. Local officials are the reason for it, and the first new
people it reaches.

## 2. Goals, non-goals, anti-goals

**Goals**
- Every person with saved evidence on a topic gets a checked summary of where they stand, on their profile.
- Every sentence carries citations, `[1]`, `[1, 4, 5]`, that point to a numbered reference list shown with the
  summary. A reference may be a vote, a sponsorship, a statement, a questionnaire answer, a local ordinance or
  resolution: any saved finding. Cite several where they exist; one is often enough.
- Local officials get searched for evidence, starting with a 100-person pilot that measures what the search finds
  and what it costs, before anyone decides on the full run of about 3,800.

**Non-goals**
- **No direction marker.** No "leans more limits / fewer limits" label, badge or half-filled spoke. The summary's
  words carry the direction. The runner: "We haven't built a way to show a direction and I don't think we want to
  right now."
- **The compass is unchanged.** A person with no rung keeps an empty spoke, and a summary never counts in a
  voter's match.
- No change to the Stage 5 coder or its rules. The coder passed a blind check; this design must not reopen it.
- Other topics are later work. Gun-policy goes first (§9).

**Anti-goals** (would make this a failure even if it worked)
- A summary sentence that its citations do not support. That is a composed citation, the defect class the whole
  evidence standard exists to prevent.
- A summary that contradicts the person's rung (says they oppose limits while seated at rung 2).
- A summary that infers a view from silence or from party, or names a party.
- A summary that names or implies a rung ("sits at rung 3"). The compass shows rungs; the summary describes views.
- Voters seeing draft-season summaries before the season opens.

## 3. Constraints from the existing system

- **Evidence lives in the source store**: `backend/data/source-store/findings/<politician_id>.json`, one file per
  person, each finding with a 64-hex `id`, `kind` (`record`, own words, local record …), `url`, `date`,
  `date_precision`, `topic_keys`, and for records `instrument_id`, `act`, `motion`; `instruments/` holds the bills.
  The summary step reads only this store, like the coder ("searching and coding are separate passes").
- **Stage 5 tables (CA_0322, CA_0337):** `inform.topic_research_outcomes` (`seated | doesnt-fit | no-stance` per
  person, topic, season) and `inform.own_words_passages` (quote-checked passages, `shown_text` with party labels
  bracketed out). Both carry `season_id` and a closed-season immutability trigger.
- **Read path:** `getResearchStates` in `backend/src/lib/compassService.ts` serves `doesnt-fit` / `no-stance` with
  passages, newest **published** season only (`SEASON_IS_PUBLISHED`), and hides any topic the compass seats. The
  profile shows it through `ev-ui` `StanceAccordion.jsx` and `essentials` `src/lib/compass.js`.
- **New tables go in `inform`**, with grants, RLS enabled and policies in the same migration (root `CLAUDE.md`).
  Every reader must exclude draft seasons, or declare `@draft-reads: ADMIN-ONLY`; `draftSeasonWrites.test.ts`
  scans for an unguarded new reader.
- **Party labels never reach a reader** (RULINGS.md); `backend/src/lib/partyLabels.ts` has the checker.
- **Quote-check precedent** (ruling 2026-10-22, 2a): text shown to voters goes live without human review once a
  separate AI check passes it; a failed check keeps it off the page. The summary check follows this (§6).
- **Local records support own words, never seat alone** (ruling 2026-10-22). This design does not change it. A
  local record **may** be cited in a summary: a summary describes, it does not seat.
- **Conflict to fix:** `inform.compass_topic_roles` has `gun-policy / local / evidence_basis = 'record'`, which
  contradicts the local-records ruling. **(proposed, not yet ruled):** a `CA_` migration sets it to `own-words`,
  recording the old value in its header. The runner did not object when this was raised; confirm before applying.
  🔴 **It must be applied before the local pilot codes anyone**: the Stage 5 coder reads this field
  (`stage5/coder-inputs.ts`, `lib/stage5Code.ts`, `codingReport.ts`), so a pilot coded on `record` would let a
  local record seat a local official and mismeasure the outcome split.
- **A "local record" is not its own finding kind.** The store holds only `record` and `own-words` findings. A local
  record is a `record` whose instrument belongs to a county or a place; the reference line and the checker derive
  that from the instrument, as `own_words_passages.kind = 'local-record'` already does.

## 4. Approaches considered

1. **A separate summary step after coding** — chosen by the runner. A new step reads each person's saved findings
   for the topic, writes the summary, and a separate agent checks it. It can backfill everyone already coded
   (about 4,450 people on gun-policy) without touching the coder.
   Cost: the evidence is read twice, once to code and once to summarise.
2. **The coder writes the summary while coding.** One read, and summary and rung come from one reasoning. Rejected:
   it changes the certified coder (a new blind check), and does nothing for the 4,450 already coded.
3. **Generate the summary when a profile is opened.** Rejected: nothing checks it before a voter sees it, and the
   wording would change from visit to visit.

## 5. The summary

**Who gets one:** everyone with evidence on the topic, as part of the placement process (runner, 2026-11-22:
"everyone should get a summary as part of our placement process"). **First:** every (person, topic, season) Stage 5
coded `seated` or `doesnt-fit` with at least one saved finding. **Later:** people seated by the older research
flow, whose evidence sits in `inform.politician_context_evidence` rather than the source store; that needs a
second evidence reader and is a follow-on, not part of the first build. `no-stance` people get none and keep
today's line. **(builder's call):** a person whose
only findings are gated votes (near-unanimous) still gets a summary if the vote says something; the gate stops
seating, not describing. The checker decides whether a gated vote supports a sentence.

**Shape:**
- Two to five sentences of plain prose **(builder's call on the cap)**, followed by a numbered reference list.
- Every sentence ends with one or more citations: `[1]`, `[2, 3]`. The runner's example: *"Senator Smith has often
  voted to restrict gun sales for X, Y, Z [1, 4, 5]."*
- Naming the evidence in the sentence ("voted for SB 243") is allowed and often useful, never required. The
  citation is what ties a sentence to evidence.
- Citation numbers are assigned in order of first use; the list holds only cited findings.

**References are built by code, not written by the model.** The writer cites finding ids; the tool numbers them
in order of first use and writes the reference list from the findings' own URLs, so a reference cannot misstate
where the evidence is. The profile already shows a REFERENCES list beneath the reasoning (§7); the summary's `[n]`
is the position of the URL in that list. Two cited findings on one page share one number.

**Writing rules** (given to the writer, enforced by the checker):
1. Every sentence carries at least one citation, and each cited finding supports what the sentence says.
2. Describe views and acts; never name a rung, a rung number or the ladder's wording.
3. Agree with the seat. For a seated person, nothing in the summary may point to the other side of the ladder
   (`topic-profile.json` `sides`, `1,2,3/4,5` for gun-policy). A two-sided record may be described as two-sided
   only if the person is not seated.
4. No inference from silence, party or office. No party names or colours.
5. Quantity words need support **(builder's call on the thresholds)**: "often", "consistently", "repeatedly" need
   at least three cited acts; "more than once" needs two.
6. Dates and offices as the evidence gives them; a statement made in another office or as a candidate says so.
7. Neutral tone: the words a news wire would use, no adjectives of judgement.

## 6. The check

A separate agent (never the writer) reads each summary next to the full text of every finding it cites, plus the
person's outcome and rung. It returns, per sentence, `pass` or `fail` with a reason. **One failed sentence keeps
the whole summary off the page** **(builder's call)**. The tool then re-runs the party-label check and the
quantity-word count mechanically.

- A failed summary may be rewritten once and checked again; a second failure leaves the person with today's
  display.
- **No blind check and no human review** (runner, 2026-11-22: "No time to do a blind check"). Instead, **a second
  opinion from other model families**, run through OpenCode (`opencode`, installed, v2.2.6), **until the runner is
  confident in the quality**: every summary the Claude check passes is also checked by two outside models, one
  GPT and one Gemini **(builder's call on which, from `opencode models`)**, with the same inputs and the same
  per-sentence pass/fail format.
  - All three pass → the summary is written.
  - Any outside model fails a sentence → the summary is held, and the disagreement goes into a short report for the
    runner (sentence, citations, each model's reason). Held summaries are not shown.
  - The tool keeps a running agreement rate per topic (summaries where all three agreed / summaries checked) and
    prints it with every batch, so the runner can decide when to retire the second opinion. Retiring it is the
    runner's ruling, recorded in RULINGS.md.
  - The outside models see only the summary, the cited findings and the person's outcome; no database access, no
    `.env`, no other files.
- The check records its sha256 of the exact shown text, like the quote check, so text edited later has no check.

## 7. Storage and display

**The display already exists, so reuse it.** Essentials shows a seated topic as the rung, then a prose paragraph,
then a REFERENCES list, then QUOTES (`ev-ui` `StanceAccordion.jsx`, fetched lazily per topic). The paragraph is
`inform.politician_context.reasoning`; the references are its `sources`, an ordered array of URLs; the quotes come
from the quotes endpoint. Example on file: Bonta, environment, three press-release references.

So **the summary is the `reasoning`, and the reference list is `sources`**, in the order the `[n]` markers use.
No new table.

- **Seated people:** the summary step writes `reasoning` (with `[n]` markers) and `sources` (the cited URLs, in
  citation order) on the person's `politician_context` row for that topic and season. It replaces the coder's
  reasoning text **(builder's call:** keep the coder's text in the batch folder as history; the migration or write
  tool records the old value, root `CLAUDE.md`). `politician_context_evidence` snippets stay as they are.
- **`doesnt-fit` people:** they have no answer, so a `politician_context` row for them today is an
  `ORPHAN_CONTEXT` in `check-stance-sources.mjs`. Teach that gate one exception: a context row whose
  (person, topic, season) has a `topic_research_outcomes` row with outcome `doesnt-fit` is a summary, not an
  orphan. Its reasoning must state no position on the scale (rule 2 in §5 already forbids naming a rung).
  **(builder's call)** whether the exception keys on the outcome row alone or also on a marker in the row.
- **Read path:** the context endpoint already serves `reasoning` + `sources` per topic; make sure it serves them
  for a `doesnt-fit` topic too, and that every reader still excludes draft seasons (`SEASON_IS_PUBLISHED`).
- **Display:** `StanceAccordion` shows the reasoning and references for a `doesnt-fit` topic the same way it does
  for a seated one, above the "In their own words" quotes. Turning `[n]` into links to the reference list is a
  small `ev-ui` change **(builder's call)**.
- **Season:** everything is written to the draft Season 3, like the rest of gun-policy Stage 5, and voters see it
  when Season 3 opens (runner, 2026-11-22). The display changes ship before then but have nothing to show until
  the season opens.
- **The check's record:** the check result, checker names, agreement and the text's sha256 are kept in the batch
  folder (`stage5/summaries/<unit>-NN/`), as the quote check keeps its record; the write tool refuses a summary
  without a passing record for its exact text.

## 8. Local officials: the pilot

**Pool:** 3,812 local people on the gun-policy roster (3,157 sitting, 364 candidates, 291 both). About 1,700
council members, 311 mayors, 195 commissioners, 76 sheriffs, and clerks, assessors, coroners and others; 1,118
in California.

**Sample:** 100, drawn with a seed recorded in `stage5/local-pilot/seed.txt` before the draw, stratified
**(builder's call on strata)** by office group (council and mayor / county commission and supervisor / sheriff /
other elected) and spread across states, with California capped at its share.

**Search:** the existing Stage 5 own-words searcher, with the search subjects widened for local acts:
Second-Amendment-sanctuary resolutions, bans on guns in city or county buildings, local ordinances (home-made
guns, magazines, storage), letters or resolutions urging state or federal action, and sheriffs' statements on
enforcing gun laws. Then the usual coder, then the summary step.

**Measure and report** (`stage5/local-pilot/REPORT.md`):
- share with any on-topic finding; split of `seated` / `doesnt-fit` / `no-stance`
- share whose summary passed the check
- tokens and wall time per person, and the projected cost of all 3,812
- by office group and by state pre-emption, so the full run can skip groups that come back empty

🛑 **Stop and ask the runner** with that report: run all, run some groups, or stop. No database write before the
runner's yes, as in Stage 5.

## 9. Order

1. Summary step built and tested on gun-policy people already coded (backfill dry run, research folder only).
2. Show the runner a sample of 20 summaries with references before any write. 🛑
3. The `ORPHAN_CONTEXT` exception, the read path and the display, in one PR per repo (backend, `ev-ui`,
   `essentials`); the `evidence_basis` fix migration (dry run, then apply, each on the runner's yes).
4. Write the gun-policy backfill, one batch per state, as Stage 5 writes.
5. Local pilot (§8). 🛑
6. Other topics, by the same step.

## 10. Left to the builder

The prompt wording for writer and checker; batch sizes; model choice (judgement work: Opus for both, as the
coder); the reference-line wording; how the tool handles a person whose findings run to dozens (pick the most
recent and the most direct, cite the rest only if needed); file layout under `backend/scripts/stage5/`; tests.
