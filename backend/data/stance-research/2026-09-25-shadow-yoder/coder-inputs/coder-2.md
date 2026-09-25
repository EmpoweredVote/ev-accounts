You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-25-shadow-yoder/labels/coder-2.json. Write JSON only, matching
codebook Part E, with "codebook_version": "0.2" and "coder_slot": 2. One row per
topic below. Every quoted string you write must be copied exactly from a source below.

## Codebook

# Empowered Vote — Stance & Quote Codebook

**Version:** 0.2 (DRAFT, 2026-09-25). It carries rulings Q1–Q9 (design spec §9.1). The annex
readings and examples are not yet ruled on. Every label records `codebook_version`.
**Design:** [`docs/superpowers/specs/2026-09-25-stance-quote-codebook-reliability-design.md`](../superpowers/specs/2026-09-25-stance-quote-codebook-reliability-design.md).
**Governs:** the three stance coders, the blind human reviewer, and quote tiering. Where this file
and a skill or prompt disagree, this file wins; fix the other one.
**Authorities it consolidates:** CLAUDE.md "Compass chairs are five distinct stances"; stance-program
spec (2026-09-23) §3, §4, §10; `research-stances` SKILL.md hard rules; `on-the-record`
`docs/quote-curation/PRINCIPLES.md`, `audit-quotes/CHECKS.md` §4, `CASEBOOK.md`.

> Examples marked **[real]** are taken from rows in `inform.stance_research_review` (Season 1, June
> 2026). The code shown is what this codebook *would* assign. It is not what was published. Several
> of those rows were published under older rules; Season 2 research re-codes them.

---

## Part 0 — Frame

### 0.1 Units

- **Unit of analysis:** one *row* = (politician, office, topic, season). The coders code only the
  season's **served** ladder revision.
- **Unit of coding:** one *source passage*, meaning one snapshot excerpt, identified by `snapshot_id`.
- **Quote unit:** one *candidate quote*, a verbatim span inside a snapshot.

### 0.2 What a coder sees, and what it does not see

- **It sees:** this codebook, the topic annex, the served ladder text (all five rungs), the
  politician's name, office, jurisdiction and term dates, and the snapshot passages.
- **It does not see:** the collector's opinion, any other coder's label, the chair currently
  published, the party, or anything about the "usual" position of people like this one.
- **Party is never evidence.** A coder that uses party, caucus or "voted with the majority" as a basis
  for anything is wrong on that item (§A6 bad example 2).

### 0.3 Decision order (fixed)

Code the source passages first, one at a time. Then code the row.

```
per passage:  V1 attribution → V2 relevance → V3 evidence class → V4 shape → V5 time
              (a disqualifying value at any step ends that passage: it cannot support a chair)
per row:      V6 chair, using only passages that survived V1–V5
per quote:    V7 tier → V8 quotable
```

### 0.4 Principles that override everything below

1. **A blank is a correct answer.** An honest BLANK scores the same as a correct chair. A wrong chair
   is the only failure that reaches voters.
2. **Five chairs, not a polarity scale.** Each rung is a distinct stance. Evidence of *direction*
   (for/against) does not choose between the rungs on one side.
3. **"The least extreme rung the evidence supports" is a tiebreaker, not evidence.** If you are about
   to use it, the row is not evidenced: code BLANK `direction-only`.
4. **Never assume polarity.** Read the rung text. Rung 1 is not always "most government". The annex
   marks inverted and off-axis topics.
5. **Scope is per rung.** A rung that no officeholder at this level can act on cannot be evidenced at
   this level.
6. **Convergent error is not corroboration.** Two news stories that repeat one press release are one
   source.

---

## Part A — Stance variables

### V1 Attribution — *is this passage this person's own act or own words?*

| Value | Definition |
|---|---|
| `own-words` | First person, or a direct quotation of the person, attributed in the text. |
| `own-act` | A recorded act of the person: sponsorship, a vote, a veto, a signed filing, an adopted motion. |
| `third-party-characterization` | Someone else describing the person ("a champion of…", "has long supported…"). |
| `namesake-unclear` | It cannot be established that this is the same person *in this office*. |

**Rules**
- Only `own-words` and `own-act` can support a chair.
- Voice decides, not domain. A campaign site that says "Jane will fight for…" in the third person is a
  `third-party-characterization` of a promise. Look for the first-person version.
- A news article's paraphrase is characterization. The article's quotation marks around the person's
  words are `own-words`.
- The office and jurisdiction in the passage must match the seat. If they do not, or are absent and
  the name is common → `namesake-unclear`.

**Good.** A senate press release quoting the president of the senate in his own words on the veto
override he led. → `own-words` + `own-act`.

**Hard [real].** J. Stuart Adams / `school-vouchers`. The basis says Adams "was a champion of the Utah
Fits All Scholarship Program (HB215, 2023)", and quotes him in 2024 saying "educational choice is a
right, not a privilege."
- "Champion" is a `third-party-characterization`, so it supports nothing on its own.
- The quotation is `own-words` and can go forward to V2.
- The fix is to find his own act on HB215 (floor vote, sponsorship) in the legislature's record.

**Hard.** A candidate's questionnaire answer published by a newspaper. → `own-words`: the paper is the
channel, the words are the candidate's. The same answer summarized by the paper → characterization.

**Bad [real].** Mike Kennedy / `voting-rights`. The only source is a Wikipedia article about the SAVE
Act. An encyclopedia page about a bill is not the person's act; at most it points to the roll call.
→ `third-party-characterization`, tagged `pointer` in the snapshot.

---

### V2 Relevance — *does the passage speak to this ladder's question, at this level?*

| Value | Definition |
|---|---|
| `on-question` | It addresses the thing the rungs differ on. |
| `adjacent` | Same policy area, but not the dimension the rungs separate. |
| `off` | A different question, or the right question for a different office the person also holds. |

**Rules**
- Test against the **rung text**, not the topic label. `voting-rights` Season 1 is an identification
  ladder, so a passage about mail ballots is `adjacent`.
- `adjacent` passages can never support a chair.

**Good.** `trans-athletes`: a vote to override a veto of a bill that restricts girls' school sports
teams by sex at birth. The rungs differ exactly on that. → `on-question`.

**Hard [real].** Blake Moore / `childcare`. The evidence is co-sponsorship of a $2,000 newborn tax
credit and an expanded child tax credit. Season 1 rung 4 is "reducing regulations on childcare
providers… with limited subsidies reserved for the lowest-income families."
- A general child tax credit is not a childcare-provider or childcare-subsidy measure. → `adjacent`.
- It cannot establish rung 4, whose operative clause is deregulation of providers. → Row: BLANK
  `no-evidence` unless another source exists.

**Bad [real].** Blake Moore / `data-centers`. The quote supports one local data-centre project "with
environmental safeguards". It says nothing about permitting speed, energy-demand transparency or rate
impacts, which are the clauses that separate rungs 3, 4 and 5. It is `on-question` only in the sense
of the topic label. On the rungs → `adjacent`. Coding it as rung 4 ("streamlined permitting") is an
unevidenced chair.

---

### V3 Evidence class — *what kind of evidence is it?*

| Value | Definition |
|---|---|
| `record` | An instrument **plus** the person's action on it: authored, prime-sponsored, co-sponsored, voted yes/no, vetoed, signed into law, filed (a lawsuit, an amicus brief), signed an official letter. The instrument must be named (bill number, ordinance number, docket, case, dated letter). |
| `statement-answer` | The person's own words **given in answer to this question**: a questionnaire (including one a group published with the candidate's answers), a moderated debate answer to the question, a first-person issue page on their own site, a signed pledge. |
| `statement-other` | The person's own words matched to the question afterwards: news quotes, interviews, speeches, social posts. |
| `not-evidence` | Scorecard grades, percentages and endorsements; quizzes; voter-guide summaries not in the person's words; encyclopedia or aggregator pages; advocacy-group profiles. |

**Rules**
- A record needs a named instrument. "Voted against clean energy mandates" with no instrument →
  `not-evidence` until the roll call is found. Emit `needs_source` for it.
- **Scorecards (Q9, ruled).**
  - A grade, a percentage or an endorsement is `not-evidence`, and it is not corroboration either.
    A scorecard is another organization's choice of *which* votes count, with hidden weights, and it
    often brings back the party signal.
  - The scorecard **page** is a `pointer`. Follow it to the roll calls it lists, and code each one as
    a record on its own.
- **Pledges (Q8, ruled): `statement-answer`.**
  - The text is the group's, and the person agreed to it, which is how a questionnaire works.
  - It does **not** outrank the person's later words, because it is not a record.
  - The election-cycle rule (V5) applies: a pledge signed three campaigns ago → review.
- **Lawsuits, amicus briefs, signed official letters (Q8, ruled): `record`.** The **legal claim or the
  letter's demand itself** must match the rung clause in V4. A procedural claim (standing, authority,
  a deadline) proves nothing about the policy.
- **Classifying `statement-answer` vs `statement-other`: was there a question?** If the person was
  answering *this* question (a questionnaire item, a moderator's question, their own issue page
  heading), it is an answer. If a curator later decided that the words speak to the question, it is
  `statement-other`. When unsure → `statement-other`.
- When `record` and a statement conflict, the record wins, and the row is coded
  `record-vs-statement-conflict` if the conflict decides the chair.

**Good.** "H.R. 8035, Ukraine Security Supplemental Appropriations Act, 2024 — Yea", from the Clerk's
roll call. → `record`.

**Hard [real].** Blake Moore / `taxes`: the ATR Taxpayer Protection Pledge. → `statement-answer`
(Q8). The pledge commits against *any* net tax increase. It can therefore evidence a "no tax increases" rung, but
it cannot choose between rungs that differ on *which* cuts.

**Bad [real].** Blake Moore / `climate-change`: "scored 0% from the League of Conservation Voters" +
the LCV scorecard page. → `not-evidence`. The same row's own quote ("if there needs to be some type of
tax incentive to make sure that they can be on the grid") leans *toward* subsidy, not toward S1 rung 4
("let market forces drive"). A coder that leans on the scorecard reaches the opposite reading from the
person's own words.

**Bad [real].** Blake Moore / `civil-rights`: an advocacy group's lawmaker profile and a
legislator-directory page. → both `not-evidence`.

---

### V4 Shape — *what can this passage prove?*

This variable is the core of the codebook. The stance-program pass-1 measurement is the reason:
*shape*, not type, predicted which chairs survived audit (authored bill 67%, co-authored 40%, bare vote
0%, statement alone 0%).

| Value | Definition | Can support a chair? |
|---|---|---|
| `chair-shaped` | The operative content matches **every clause** of one rung and excludes the adjacent rungs. | yes |
| `direction-only` | It shows for/against but does not separate the rungs on that side. | no |
| `multi-subject` | A vote on a bill with many unrelated parts (omnibus, budget, appropriations, reconciliation). | only via the vote ladder |
| `procedural` | Cloture, rule, table, recommit, previous question, adjournment. | no |
| `study-directive` | It orders a study, task force or report. | no |
| `near-unanimous` | Fewer than 10% of the body voted against. | no, alone |
| `rhetorical` | Real and attributed, but it names no policy clause ("hateful and divisive"). | no |
| `off-axis` | It speaks to the topic along a dimension the ladder does not order. | no |

#### V4.1 The vote ladder (ruling 2026-09-25)

A vote does not mean support for every clause of a bill.

| Vote | Can prove |
|---|---|
| Amendment / motion to strike / divided question on **the specific provision** | a chair |
| Final passage of a **single-subject** bill whose operative section matches the rung | a chair |
| Final passage of a **multi-subject** bill | direction at most. It proves a chair **only** if the person's own statement ties their vote to *that provision* (an explanation of vote, a floor speech). |
| **No** on a multi-subject bill | nothing. They may have objected to any part. |
| Procedural | nothing about the policy |

- A coder citing a vote must fill `provision_quote`: the operative text it relies on, verbatim from a
  snapshot. The gate rejects the label if the text is not in the snapshot.
- **The operative section governs, not the recital or the short title** (C38, C51).
- **Sponsorship evidences the bill as filed** (C37). If the bill was amended out of shape, code the
  version the person acted on.

#### V4.2 Clause completeness

- **Compound rungs need every clause evidenced** (stance-program §4.2). Rung 3 of `social-security`,
  "small adjustments to **both** benefits **and** taxes", needs evidence on both.
- **Broader than the instrument** (stance-program R3): an ADU-only bill cannot evidence "upzone broadly
  to allow multifamily by right". Seat the narrower rung if one exists; otherwise BLANK.

**Good (calibration A1).** A prime-sponsored bill that *is* "a moratorium on new data centres until the
utility commission reports". Rung 1 is a moratorium. → `chair-shaped`.

**Good [real].** J. Stuart Adams / `trans-athletes`. He led the 2022 Senate vote to override the
governor's veto of HB11, a single-subject bill barring transgender girls from girls' school teams.
S1 rung 4: "require transgender athletes to compete only on teams matching their biological sex
assigned at birth."
- The instrument's operative content is rung 4.
- Rung 5 (a total ban from all sport) is excluded by the bill's own text.
- → `chair-shaped`. (Check under V5: the act is in-term.)

**Hard [real].** Blake Moore / `ukraine-support`. Yea on H.R. 8035, a Ukraine-specific supplemental
appropriation, plus his statement that it is "squarely in our national interest".
- The bill is single-subject enough (Ukraine aid) → `chair-shaped` for *continuing aid*.
- The rung-2 vs rung-1 boundary is "current levels" vs "increase". The coder must check that the
  supplemental's size and the rung's magnitude line up.
- If the annex does not settle whether a supplemental is "current level", code BLANK
  `direction-only`. **This is the example to rule on for the annex.**

**Hard [real].** Burgess Owens / `redistricting`: a filed federal lawsuit arguing the Elections Clause
gives map-drawing "exclusively to state legislatures". → `record` (Q8), and the claim in the
complaint is itself the position (a substantive claim, not a procedural one). It is `chair-shaped` if rung 5 says "legislature alone draws the
maps". The coder quotes the complaint's claim as `provision_quote`.

**Bad [real] — the omnibus trap.** Mike Kennedy / `school-vouchers`, published as rung 5 (universal
vouchers). The basis is a Yea on the One Big Beautiful Bill Act (July 2025), a reconciliation bill
covering taxes, Medicaid, immigration enforcement and more, one part of which created federal
tax-credit scholarships.
- → `multi-subject`. His vote proves nothing about the scholarship clause on its own.
- A tax-credit scholarship is also not "funding follows the student to any school". → `adjacent`
  on V2 as well.
- The row needs his own words tying the vote to that clause, **and** a rung that matches the clause.
  Otherwise → BLANK.

**Bad [real].** Blake Moore / `medicare/aid` and `healthcare`: the same OBBBA vote used as the basis
for two further rungs. → `multi-subject`, both times. The statements in those rows ("sound policy",
defending work requirements) are about work requirements, a narrower clause than either rung. →
`adjacent`.

**Bad (calibration R1).** No on a rebate deal the member disliked. It rules out one end and names no
chair. → `direction-only`.

**Bad (calibration R6).** "Morally wrong… hateful and divisive." It is verbatim and attributed. →
`rhetorical`.

---

### V5 Time — *does it describe the person's position now, in this role?*

| Value | Definition |
|---|---|
| `in-term` | The act or statement dates from within a term of this office, or from the current campaign for it. |
| `pre-seating` | A vote or act from before the person held the office. A record from an earlier office is valid for that office only. |
| `superseded-by-later` | A later passage from the same person states or acts differently. |
| `undated` | No date can be established. |

**Rules**
- A **record** has no age limit if it is chair-shaped against the served rung text.
- **A statement follows the election cycle (Q4, ruled).** It counts only if it is from one of:
  - the current term;
  - the current campaign;
  - the campaign that seated the person in *this* office.

  An older statement is coded, but the row goes to review (`statement-out-of-cycle`). Code, not the
  coder, applies this from the dates; the coder records the date it sees.
- `superseded-by-later` passages are coded but cannot support the chair. The newest evidence governs.
- A person's position change is not an error. The closed season keeps the old chair.
- `undated` statements cannot support a chair. `undated` records are looked up (the instrument has a
  date).

**Hard [real].** Blake Moore / `redistricting`: co-chair of the Better Boundaries campaign in 2017,
before he was elected in 2020. Campaign work is not a vote, so this is not a pre-seating vote. But it
is 9 years old, and the source is Wikipedia (V3 `not-evidence`). Find his own recent words; the 2017
role alone → review.

**Hard [real].** Celeste Maloy / `same-sex-marriage`: in a 2023 candidate debate she said she "would
have voted yes" on the Respect for Marriage Act. → `own-words`, `statement-answer` (an answer to a moderator's question in a debate; if the only source is an article paraphrasing it, `statement-other`), pre-seating by
construction (she was a candidate). A hypothetical vote on a named instrument is a strong statement:
the instrument's content (marriage recognition with religious-organization protections) is the
position. It is `in-term` for the campaign that seated her. Note: the served ladder changed between
Seasons 1 and 2, and her Season 2 value differs. Re-code it against the served S2 rung text; do not
carry the S1 reading forward.

---

### V6 Chair — *which rung does the surviving evidence establish?* (row level)

**Values:** `1`–`5`, or `BLANK` with exactly one reason:

| BLANK reason | Use when |
|---|---|
| `no-evidence` | No passage survived V1–V5. |
| `direction-only` | The surviving passages separate the sides but not the rungs on one side. |
| `adjacent-chairs` | Surviving passages establish two different rungs (stance-program R4). |
| `compound-partial` | The best rung is compound and only some of its clauses are evidenced. |
| `record-vs-statement-conflict` | The record and the statement point to different rungs, and the record is not itself chair-shaped. |
| `scope-unavailable` | No officeholder at this level holds a lever on the rung (normally dropped before coding). |

**Rules**
- **`rests_on`** lists the snapshot IDs whose passages establish the chair. At least one is required
  for a numeric chair.
- **Reasoning:** 1–3 sentences that name the instrument or quote the words, and that cite the rung by
  its **text**, not by its number.
- **One instrument can establish chairs across a whole body** (calibration A4) — but only after a
  cohort pass shows the members are not being separated by language that separates nobody.
- **Party inference is a bad code** wherever it appears.

**Good (calibration A3).** A council appointee's vacancy-application packet, published by the city,
answers the ladder's question in his own words. It matches one rung clause for clause. → that rung.

**Hard [real].** Celeste Maloy / `social-security`. Her 2024 voter-guide answer supported "gradually
raising the retirement age"; in 2026 she said "everything's on the table", including lifting the cap.
- The first statement is benefit-side only.
- The second is `rhetorical`: "on the table" is not a position.
- S1 rung 3 ("small adjustments to **both** benefits **and** taxes") is compound.
- → BLANK `compound-partial`. Rung 4 is not established either: "raise the retirement age" is
  one clause of rung 4, and "reduce benefits for higher earners" is unevidenced.

**Hard [real].** Burgess Owens / `social-security`: co-sponsored the Social Security Fairness Act
(repealed WEP/GPO, a benefit expansion for a specific group) and said lawmakers "must be willing to
reform" the program.
- The Act increases benefits for one group and has no tax side.
- Rung 3 is compound (benefits and taxes); rung 2 is "increase benefits modestly **while** raising
  taxes on higher earners".
- → BLANK `compound-partial`.

**Bad [real] — party inference.** Celeste Maloy / `trans-athletes`. Basis: "voted with the Republican
caucus on this party-line vote. She has not expressed any dissent." Neither cited source is the roll
call.
- → Every passage fails V1 (no own act in the snapshot), and the reasoning uses the caucus as evidence.
- → BLANK `no-evidence`. The right fix: fetch the Clerk's roll call for H.R. 28 (2025), which is
  single-subject and `chair-shaped` for rung 4. It would then be a good example.

**Bad [real].** Mike Kennedy / `voting-rights`. The SAVE Act requires documentary proof of citizenship
to *register*. S1 rung 4 is "require photo ID for **voting** and regularly update voter rolls". Proof
of citizenship at registration is a different clause. → V2 `adjacent`, V6 BLANK `no-evidence` (or the
annex adds a rung that names it).

---

## Part B — Quote variables

These variables apply to every **candidate quote** the collector surfaces, for Read & Rank and for the
"Why this position?" citation.

### V7 Tier — *what does the quote commit the speaker to?*

The vocabulary is the on-the-record evidence program's.

| Value | Definition |
|---|---|
| `lever` | It names a means that passes **both** T1 and T2, below. |
| `direction` | A contestable lean whose means fails T2 ("remove regulations", "be tougher on…"). |
| `none` | A shared goal, a diagnosis, a record or accomplishment, a complaint, biography, a slogan. |

**The lever tests (Q5, ruled 2026-09-25).** Name the goal the quote serves, then apply:

- **T1, the opponent test:** could a candidate *who holds the same goal* reasonably choose a different
  means? If not, the "means" is the shared goal phrased as an action → `none`.
- **T2, the accountability test:** could a voter later check whether the person *did it*? If not, the
  means is too vague to hold anyone to → `direction`.

A quote is `lever` only if it passes both. When the lever names a specific instrument (a law, a rule,
a program, an agency action, a waiver, a budget line), also set `v7_flag = "lever-named"`. That tag
is useful for display and for chair evidence; it is not required for rankability.

This settles the disagreement between PRINCIPLES.md:139 ("build shelters" is a lever) and the
decomposition spec (broad actions are not instruments):
- "Build shelters" passes T1 (an opponent can prefer housing first) and T2 (shelter beds can be
  counted) → `lever`.
- "Build more housing", where every candidate says it, fails T1 → `none`.
- "Triple housing construction" fails T1 (a target on a shared goal) unless the passage names how →
  `none`.

T1 is relative to the question and the race, not to the words. The coder uses the other candidates'
passages when the collector supplies them; otherwise it sets `v7_flag = "lever-unclear"`.

**Graded examples [real, `essentials.quotes`, Steve Hilton unless noted]**

| # | Quote (short) | T1 | T2 | Code |
|---|---|---|---|---|
| 1 | "repeal the low-carbon fuel standard… change the refinery regulations" | yes | yes | `lever`, `lever-named` |
| 2 | "a waiver from the Medicaid IMD rule that stops any institution with more than 16 beds…" | yes | yes | `lever`, `lever-named` |
| 3 | "instructing the California Department of Geologic and Energy Management to… issue permits" | yes | yes | `lever`, `lever-named` |
| 4 | "it is illegal to live and camp on the streets. We need to enforce the law… drug treatment… cannot be a choice" | yes (vs Becerra's "Housing First approaches… paired… with treatment") | yes | `lever` |
| 5 | "If a community doesn't want a data center, there shouldn't be someone forcing that data center in there" | yes (vs state siting authority) | only if the passage says how (e.g., a local veto) | `direction` as quoted |
| 6 | "We could get that back by removing regulations" (AI) | yes | no — which regulations? | `direction` |
| 7 | "Government's role is to facilitate rather than provide…" (childcare) | yes | no | `direction` |
| 8 | "common sense on climate change, not ideology" | — | — | `none` |

⚠ **Two currently selected Read & Rank quotes code as not rankable** under this rule:
- climate-change: #8;
- economic-development: "California's policy regime should be unequivocally on the side of job- and
  wealth-creators" → `direction`.

A quote re-audit should review them. This codebook does not change them.

**Good (lever).** "We must build much more housing. That includes… deed-restricted affordable,
market-rate, social housing, and shelters." (PRINCIPLES.md). The second sentence names the means, so
keep both sentences in the quote.

**Hard [real, tier_gold_v1].** "I actually really believe in shelter and shelter is an urgent
response. We've tripled the number of shelter beds…" The labeler wrote: "a mix of record and beliefs.
I'm saying lever, but I'm not sure." Under the test: "shelter as the urgent response" is a means an
opponent (housing-first) rejects → `lever`. The "tripled beds" clause is record → it does not add to
the tier.

**Hard [real, tier_gold_v1].** "I've… created the first real performance data… on our homelessness
system." The labeler hesitated between direction and lever. Under the test: "manage by performance
data" is a means few would reject → `direction`.

**Bad → none [real, tier_gold_v1].** "We only have a third of the shelter that we need…" A diagnosis.
The labeler: "more complaining" than proposing. → `none`.

### V8 Quotable — *may this quote be shown?*

`yes`, or one or more reason codes. The codes are the `audit-quotes` check IDs, so the two systems
share one vocabulary.

| Code | Meaning (full rule in `audit-quotes/CHECKS.md` §4) |
|---|---|
| `not-forward` | Record or retrospective, not what they would do. |
| `is-attack` | Attacks a person rather than a policy or office. |
| `off-question` | Does not answer the ranking question (not the topic label). |
| `misleading-verbatim` | Word-for-word, but the cut changes the meaning in context. |
| `source-not-an-answer` | Curator-extracted from a passage that was not an answer to this question. |
| `deid-dishonest` | The blind version changes the position, or hides a load-bearing identity. |
| `non-differentiating-goal` | V7 = `none` because of a shared goal. Flag for a human; do not gate. |

**Rules**
- The quote must be verbatim in its snapshot. That is a code check, not a coder judgment.
- Trimming follows `publish-quotes/EDITORIAL.md`: marked cuts `…`, inserts `[ ]`, no reordering, no
  cut of a load-bearing qualifier.
- A quote can be quotable for the "Why this position?" citation and still not rankable in Read & Rank.
  Rankable needs V7 = `lever` (and a certified quote stratum before any auto-promotion).

---

## Part C — Per-topic annex (template + one example)

One file per open-season topic: `docs/codebook/annex/<topic_key>.md`. Written against the **served**
revision. A new revision gets a new annex version.

**Template**

```
# <topic_key> — served revision <id> (Season N)
Orientation: standard | inverted | off-axis — one sentence why.
Levels with a role: federal / state / local / school   (compass_topic_roles)
Per rung:
  <n>. "<rung text>"
     Operative clauses: [a] … [b] …
     Establishing evidence looks like: …
     Levels that hold a lever: …
     Known chair-shaped instruments: …
     Commonly confused with rung <m> because …
Hard cases: …
```

**Example:** [`annex/school-vouchers.md`](annex/school-vouchers.md).

---

## Part D — Hard-case register

Every row where the coders split, or where a person's blind answer differed from their final one,
adds an entry here: situation → code → rule → gold item ID. Items listed here are
`excluded_from_cert` (leakage).

| # | Situation | Code | Rule | Source |
|---|---|---|---|---|
| H1 | Yea on a reconciliation bill that contains the clause | V4 `multi-subject` | V4.1 | [real] Kennedy / school-vouchers |
| H2 | Party-line vote given as the only basis, and no roll call in the sources | V1 fail; BLANK `no-evidence` | 0.2, V6 | [real] Maloy / trans-athletes |
| H3 | Scorecard beside a quote that points the other way | V3 `not-evidence` | V3 | [real] Moore / climate-change |
| H4 | A hypothetical vote on a named bill, said as a candidate | `statement-answer`, the instrument is the content | V5 | [real] Maloy / same-sex-marriage |
| H5 | A compound rung with one side evidenced | BLANK `compound-partial` | V4.2 | [real] Owens, Maloy / social-security |
| H6 | A child tax credit coded on a childcare-provider rung | V2 `adjacent` | V2 | [real] Moore / childcare |
| H7 | A filed lawsuit as the position | `record`; the substantive claim must match the rung (Q8) | V3 | [real] Owens / redistricting |
| H8 | A signed pledge | `statement-answer` (Q8), limited shape | V3 | [real] Moore / taxes |
| H9 | "Shelter is the urgent response" + a record | V7 `lever` | V7 T1+T2 | [real] tier_gold_v1 |
| H10 | "Remove regulations" with none named | V7 `direction` (fails T2) | V7 T2 | [real] Hilton / ai-regulation |
| H11 | Local-control principle without a mechanism | V7 `direction` | V7 T2 | [real] Hilton / data-centers |

---

## Part E — Coder output schema (`labels/coder-N.json`)

```json
{
  "codebook_version": "0.2",
  "coder_slot": 1,
  "rows": [
    {
      "politician_id": "uuid",
      "office_id": "uuid",
      "topic_id": "uuid",
      "served_revision_id": "uuid",
      "passages": [
        {
          "snapshot_id": "uuid",
          "v1_attribution": "own-words | own-act | third-party-characterization | namesake-unclear",
          "v2_relevance": "on-question | adjacent | off",
          "v3_class": "record | statement-answer | statement-other | not-evidence",
          "date": "YYYY-MM-DD | YYYY-MM | YYYY | null",
          "v4_shape": "chair-shaped | direction-only | multi-subject | procedural | study-directive | near-unanimous | rhetorical | off-axis",
          "v5_time": "in-term | pre-seating | superseded-by-later | undated",
          "instrument": "H.R. 8035 (118th) | null",
          "provision_quote": "verbatim operative text from this snapshot | null",
          "note": "≤ 1 sentence"
        }
      ],
      "v6_value": 4,
      "v6_blank_reason": null,
      "rests_on": ["snapshot uuid"],
      "reasoning": "1–3 sentences; names the instrument or quotes the words; cites the rung by its text",
      "needs_source": ["e.g. Clerk roll call, H.R. 28 (119th), final passage"],
      "quotes": [
        {
          "snapshot_id": "uuid",
          "text": "verbatim span",
          "v7_tier": "lever | direction | none",
          "v7_flag": "lever-named | lever-unclear | null",
          "v8_quotable": true,
          "v8_codes": []
        }
      ]
    }
  ]
}
```

**Invariants (code-checked):**
- `v6_value` is null **iff** `v6_blank_reason` is set.
- A numeric `v6_value` requires `rests_on` to have at least one entry, and every entry must be a
  passage whose V1–V5 values all allow a chair.
- Every `provision_quote` and every quote `text` is verbatim in its snapshot.
- Every value is from the lists above.


## The person

politician_id: 5aa536e1-faaa-485c-b6d8-0e4d99d16361  office_id: 09c567c5-b19f-41d4-b113-5982ad0df4e1
Shelli Yoder — Senator, Indiana (seated, level: state)
Current term: unknown (precision: unknown) to present

## Topics (served ladder text — code against these words only)

### topic_key: abortion
topic_id: af2fdfd6-02c4-49df-b09c-cf8536f4773f  served_revision_id: 085feb9c-f157-4dae-bfd0-7b2736c5d87c
Question: How should the law handle abortion?
  1. keep abortion legal at every stage of pregnancy, with no time limit.
  2. keep abortion legal through the second trimester, and after that only to protect the mother's health.
  3. allow abortion during the first trimester, and after that only to protect the mother's health.
  4. ban abortion except in cases of rape, incest, or a serious risk to the mother's life.
  5. ban abortion in all cases, with no exceptions.

#### Annex

(no annex for this topic yet — apply the codebook alone)

### topic_key: data-centers
topic_id: 4559b513-0fd8-4ed1-babd-f3b554162f40  served_revision_id: c48a03d6-b972-4f27-9a8a-d41b07f4a929
Question: How should government manage the growth of large-scale data centers?
  1. Imposing a moratorium on new data center construction until energy infrastructure can support demand without raising costs for residential ratepayers
  2. Barring utilities from passing any data center energy infrastructure costs to residential customers
  3. Allowing data center development with impact assessments, energy cost-sharing agreements, and community benefit requirements before approval
  4. Encouraging data center development through streamlined permitting while requiring transparency about projected energy demand and rate impacts
  5. Welcoming data center investment with minimal regulatory barriers, trusting that economic growth and tax revenue will benefit all residents

#### Annex

(no annex for this topic yet — apply the codebook alone)

### topic_key: fossil-fuels
topic_id: a22215c3-6693-4bc2-b248-01aebba14570  served_revision_id: 58796165-cd12-44de-a9b6-84df43f6eda0
Question: What role should fossil fuels play in the nation's energy future?
  1. Phase out fossil fuel production entirely.
  2. Allow no new drilling and let production decline over time.
  3. Keep fossil fuel production steady at current levels.
  4. Expand fossil fuel production with new drilling and permits.
  5. Maximize production and open more public land and waters to drilling.

#### Annex

(no annex for this topic yet — apply the codebook alone)

### topic_key: medicare/aid
topic_id: cab61e8a-64fe-4bbd-bc08-fe9914d0091b  served_revision_id: 38bab357-9790-4cb3-a6d2-c43cbdca615b
Question: How should Medicare and Medicaid be funded and structured?
  1. expand Medicare to cover everyone regardless of age
  2. significantly expand Medicare or Medicaid eligibility, stopping short of universal coverage
  3. improve current programs while controlling costs
  4. scale back both programs, shifting more coverage to private insurance
  5. phase out both programs and use private insurance only

#### Annex

(no annex for this topic yet — apply the codebook alone)

### topic_key: school-vouchers
topic_id: 00b95a6a-75db-4521-b523-3326bba938de  served_revision_id: 88858826-90c0-41c9-a3a4-1d9f5b8c5307
Question: What role should vouchers and school choice play in the public education system?
  1. Eliminating voucher programs that divert taxpayer money from public schools to private institutions
  2. Opposing voucher programs and blocking their expansion, without moving to eliminate existing ones
  3. Allowing income-based voucher programs, open to a wider range of families under an income cap
  4. Expanding voucher eligibility to most families so parents can choose the school that best fits their child
  5. Providing universal vouchers so that education funding follows the student to any school — public, private, or religious — chosen by the family

#### Annex

# school-vouchers — annex (Season 2 served text; draft, not ruled)

**Orientation:** standard. Rung 1 is most restrictive of vouchers, rung 5 is universal.

**Levels:** state (the lever: program statutes), federal (tax-credit scholarships only), school
boards (no lever on vouchers). Verify against `compass_topic_roles` before use.

1. **"Eliminating voucher programs that divert taxpayer money from public schools to private
   institutions"**
   - Clauses: [a] eliminate existing programs.
   - Evidence: a repeal bill, or a vote on a repeal amendment; own words calling for repeal.
   - Confused with 2 when the person only opposes an *expansion*.

2. **"Opposing voucher programs and blocking their expansion, without moving to eliminate existing
   ones"**
   - Clauses: [a] oppose expansion; [b] no repeal.
   - Evidence: a No on an expansion bill **plus** evidence against repeal (a No vote alone is only
     `direction-only`: it does not separate 1 from 2).

3. **"Allowing income-based voucher programs, open to a wider range of families under an income
   cap"**
   - Clauses: [a] means-tested; [b] a wider cap.
   - Evidence: authoring or voting for a means-tested program with a cap.

4. **"Expanding voucher eligibility to most families so parents can choose the school that best fits
   their child"**
   - Clauses: [a] most families, not all.
   - Evidence: an expansion bill with a high income cap, or a phased path to universal.
   - Confused with 5 when a phase-in ends in universal eligibility: code the end state the instrument
     enacts.

5. **"Providing universal vouchers so that education funding follows the student to any school —
   public, private, or religious — chosen by the family"**
   - Clauses: [a] universal; [b] any school, including religious.
   - Evidence: a universal ESA/voucher statute (e.g., Utah HB215, 2023).
   - **A federal tax-credit scholarship is not rung 5.** It is a tax credit to donors, not funding that
     follows the student. → `adjacent` (see the V4 omnibus example).

**Hard cases:** a vote on a budget that funds an existing program (`multi-subject`); a governor's
signature (a record; `chair-shaped` when the signed bill is single-subject).


### topic_key: trans-athletes
topic_id: d1618b9c-0b9e-45af-b986-bb33d270b8e4  served_revision_id: c47c957a-5eb6-426f-b38d-89e44ba8fe73
Question: How should sports leagues determine eligibility for transgender athletes?
  1. allow all transgender athletes to compete on teams matching their gender identity without any restrictions or requirements.
  2. should allow transgender athletes to compete on teams matching their gender identity after completing basic documentation of their transition.
  3. decide transgender athletes' eligibility case by case based on individual circumstances and the requirements of each sport.
  4. require transgender athletes to compete only on teams matching their biological sex assigned at birth.
  5. completely ban all transgender athletes from competing in any organized sports competitions.

#### Annex

(no annex for this topic yet — apply the codebook alone)

### topic_key: voting-rights
topic_id: d1792200-1d3b-4955-a0b7-0e6980d7a7b2  served_revision_id: 2a18c152-67a0-4380-a381-cb8795110a7c
Question: How should the government verify a voter's identity and eligibility?
  1. Require no identification to vote, verifying voters by signature or existing records.
  2. Accept non-photo identification, such as a utility bill or bank statement.
  3. Require photo ID to vote, but let voters without one cast a ballot after signing an affidavit.
  4. Require photo ID in person and an ID number on every mail ballot.
  5. Require documentary proof of citizenship to register to vote.

#### Annex

(no annex for this topic yet — apply the codebook alone)

## Sources

---
snapshot_id: b5b3e197-0a6f-5470-b742-c57006f4e331
source_kind: public-record
url: https://iga.in.gov/legislative/2025/bills/house/1041/details

IGA | House Bill 1041 - Student eligibility in interscholastic sports (2025) Indiana General Assembly 2025 Session. House Bill 1041. Student eligibility in interscholastic sports. Enrolled House Bill (H). Authored by: Rep. Michelle Davis. Co-Authored by: Rep. Chris Jeter, Rep. Joanna King, Rep. Robert Heaton. Sponsored by: Sen. Stacey Donato, Sen. Spencer Deery, Sen. Linda Rogers, Sen. Gary Byrne. Digest Requires, for purposes of interscholastic athletic events, state educational institutions and certain private postsecondary educational institutions to expressly designate an athletic team or sport as one of the following: (1) A male, men's, or boys' team or sport. (2) A female, women's, or girls' team or sport. (3) A coeducational or mixed team or sport. Prohibits a male, based on the student's biological sex at birth in accordance with the student's genetics and reproductive biology, from participating on an athletic team or sport designated as being a female, women's, or girls' athletic team or sport. Latest Bill Actions H 04/16/2025 Public Law 83. H 04/16/2025 Signed by the Governor. Senate roll calls listed on the page: #313, #314, #315, #316, #334 (PDFs, not saved). Saved by browser (JS-rendered page) from https://iga.in.gov/legislative/2025/bills/house/1041/details on 2026-09-25.

---
snapshot_id: e36cea0e-6089-553b-a548-86bedbe14664
source_kind: news (excerpt only)
url: https://www.wvpe.org/wvpe-news/2026-04-24/senate-minority-leader-criticizes-new-laws-during-legislative-recap-in-goshen

… Real Estate Legacy Giving Corporate Support Membership Volunteer Donate Your Car Donate Your Real Estate Legacy Giving Corporate Support About Ways to Listen Coverage Map Staff Contact Careers Ways to Listen Coverage Map Staff Contact Careers Video LOCAL stories from WVPE's news team Senate minority leader criticizes new laws during legislative recap in Goshen WVPE 88.1 Elkhart/South Bend | By Michael Gallenberger Published April 24, 2026 at 12:44 AM EDT Facebook LinkedIn Email Listen &bull; 1:08 Michael Gallenberger / WVPE Indiana’s Senate minority leader criticized several laws passed this year by the Republican-led General Assembly. Senator Shelli Yoder (D-Bloomington) reviewed the legislative session during an event hosted by the Goshen City Democratic Party on Thursday. “This is the test: it’s not whether a policy sounds clever or whether it produces a press release or talking points. It really is asking the question of, ‘Does this help people’s lives?’” Yoder said. She took aim at a law requiring local cooperation with federal immigration enforcement, and said efforts to make housing and utility rates more affordable didn’t go far enough. Yoder felt a measure that Republicans said would combat fraud in the Medicaid and SNAP programs instead added new layers of confusion, delay and risk. "When a policy asks the most from people who already have the least, that is not reform," Yoder said. "That is harm." Yoder also said making school vouchers universal has been disruptive to public schools and teachers. “If we are going to be a universal school choice state, then every school must be held to the same accountability and transparency standards,” Yoder said, drawing applause from the audience. When asked whether she’d support a two-year moratorium on data center development, Yoder felt that could take attention away from the issue, rather than encouraging public discussion. “So a blanket ‘no,’ I think, gives us one more permission to step out of the importance of being engaged,” Yoder added. Still, there were some hopeful moments. Yoder, who was born in Goshen and raised in Shipshewana, encouraged local Democrats not to give up, even though they’re currently represented by Republicans at the Statehouse. "We defeated redistricting, people!" Yoder said, drawing more applause. "You stopped [an immigration] detention center from coming to this community." During Thursday’s event, Indiana Democratic Party Chair Karen Tallian said she’s encouraged to see the most people running for office since 1974, but the state still suffers …

---
snapshot_id: 6024804d-b662-5e4d-88ec-64264fa1f0fa
source_kind: public-record
url: https://iga.in.gov/pdf-documents/124/2025/house/bills/HB1041/rollcalls/HB1041.334_S.pdf

Senate FIRST REGULAR SESSION 124TH GENERAL ASSEMBLY APR 03, 2025 3:10:26 PM Roll Call 334: Bill Passed HB 1041 - Donato - 3rd Reading Yea 42 Student eligibility in interscholastic sports. Nay 6 Excused 2 Not Voting 0 Presiding: President Y EA - 42 Alting Charbonneau Goode Randolph Baldwin Clark Holdman Rogers Bassler Crider Johnson Schmitt Becker Deery Koch Taylor Bray Dernulc Leising Tomes Brown Donato Maxwell Walker G Buchanan Doriot Mishler Walker K Buck Freeman Niemeyer Young Busch Garten Niezgodski Zay Byrne Gaskill Pol Carrasco Glick Raatz N AY - 6 Ford J.D. Jackson Qaddoura Spencer Hunley Yoder E XCUSED - 2 Alexander Bohacek N OT V OTING - 0

---
snapshot_id: f8a10e80-1f14-5250-bb7b-ed5357fe9b6b
source_kind: own-site (the person's own site or account)
url: https://indianasenatedemocrats.org/open-letter-from-senator-shelli-yoder-on-the-indiana-abortion-ban/

Open Letter from Senator Shelli Yoder on the Indiana Abortion Ban - Indiana Senate Democrats Skip to content Toggle Navigation Senators What We Stand For Media Room Session Toggle Navigation Senators What We Stand For Media Room Session Open Letter from Senator Shelli Yoder on the Indiana Abortion Ban Home Caucus Shelli Yoder Previous Next Open Letter from Senator Shelli Yoder on the Indiana Abortion Ban insendems 2024-10-16T12:37:53-04:00 October 7th, 2024 | BLOOMINGTON, Ind.,– Indiana State Senator Shelli Yoder (D-Bloomington), released an open letter addressing the devastating impact of Indiana’s abortion ban. The letter focuses on the real-world consequences women across the state are facing, including life-threatening situations where they are denied critical healthcare.Yoder calls for action to restore reproductive freedom and safeguard women’s health. In her letter, Yoder reflects on the unjust nature of the abortion ban, emphasizing the loss of healthcare providers, the dire impact on families and the erosion of personal freedoms for women. The letter encourages Hoosiers to raise awareness, support local organizations and vote for candidates who prioritize reproductive rights. The full text of Yoder’s open letter is included below. Open Letter from Senator Shelli Yoder Dear Neighbors, The landscape of healthcare in Indiana, particularly for women, has drastically changed in past year. The state’s abortion ban, once a political debate, is now a lived reality for thousands of Hoosier women. We have been hearing story after story of women being denied critical care, being forced to leave our state to seek the medical attention they need or enduring unnecessary and life-threatening suffering because lawmakers have decided they know better than women and their doctors. But these are not just stories; these are real people—our neighbors, friends, daughters, and mothers—who are being deeply impacted by this unjust law. They deserve better. I understand that people across Indiana are facing a multitude of pressing issues every day, from the rising cost of living and access to affordable childcare to the looming threat of the climate crisis. It’s easy to lose sight of this battle for reproductive freedom until you or someone you love is directly affected. But we cannot forget how vital this issue is. Doctors are leaving Indiana and other states with similar bans, choosing to practice in places where they can provide comprehensive care without fear of legal repercussions. This is not just a loss of healthcare providers—it’s a loss of access to critical services that every person in our state deserves. Access to miscarriage and ectopic pregnancy care before a life-threatening infection or critical bleeding, care to sustain a high-risk pregnancy to term, care for fibrosis and reproductive system cancers, and pregnancy-saving prenatal care – all at risk as OBGYNs flee states that politicize and criminalize their profession. And we must ask ourselves: When does this stop? How many more people must suffer before we recognize that every individual has a natural right to their own body, a right that cannot and should not be stripped away by the hands of politicians? Make no mistake, state abortion bans are not about saving lives—they are coming at the cost of lives. Women are being forced into dangerous, life-threatening situations because their healthcare decisions are no longer in their control. Families are being torn apart, children are losing a parent and the well-being of countless individuals is being compromised, all because of political ideology that disregards the real-world consequences for women’s health. How many more lives must be endangered before we acknowledge that this is a fundamental human right that should never have been up for debate? Indiana has always been known for its Hoosier Hospitality, for standing up for our communities and caring for one another. Yet, this abortion ban represents a betrayal of those very values. It takes away the freedom that women have over their own bodies, treating them as objects to be governed by political decisions rather than individuals deserving of dignity, compassion, and the right to make personal healthcare choices. How many more lives will be impacted, how many more families disrupted, before we recognize that this is a fundamental human right that should never have been questioned? If you’re looking for ways to make a difference, there are several actions you can take. First, educate yourself and those around you—awareness is the first step to creating change. Talk to your family and friends about the real impact of this law, and share the stories of women who have been affected. Second, support local organizations that provide healthcare and advocacy for women’s reproductive rights. Whether through donations or volunteer work, these groups need our help to continue fighting on the front lines. Finally, make your voice heard. Contact your local representatives, attend community meetings, and vote for candidates who believe in safeguarding reproductive freedom as well as following the democratic caucus for any important updates. Together, by raising our voices and taking action, we can push back against this unjust law and work to restore the freedoms that have been stripped away. With unwavering resolve, Shelli Yoder Indiana State Senator, District 40 Menu Senators What We Stand For Media Room Legislative Session Caucus Staff Helpful Links Get INvolved Press Release Newsroom Senate E-Newsletter Indiana General Assembly Agency Finder Connect Address: 200 W. Washington Street Indianapolis, IN 46204 Call Toll-Free 800-382-9467 © Indiana Senate Democrats | All Rights Reserved Page load link Senators What We Stand For Media Room Session Contact My Senator Go to Top

---
snapshot_id: 7d3d9112-ef23-5f09-9bbe-7b8def21eaa7
source_kind: public-record
url: https://iga.in.gov/legislative/2022/bills/senate/170/details

IGA | Senate Bill 170 - Pension investments in fossil fuel companies (2022) Indiana General Assembly 2022 Session. Senate Bill 170. Pension investments in fossil fuel companies. Introduced Senate Bill (S). Authored by: Sen. Shelli Yoder. Digest Requires the board of trustees of the Indiana public retirement system (system) to divest investments and investment products in a company that is publicly traded and identified as one of the 200 largest reserve-owning fossil fuel companies based on the amount of carbon emissions in a company's oil, gas, and coal reserves. Requires the system to submit a report to the interim study committee on pension management oversight and the budget committee on or before November 1 of each year through 2029. Provides for civil immunity. Latest Bill Actions S 01/06/2022 First reading: referred to Committee on Pensions and Labor. S 01/06/2022 Authored by Senator Yoder. Saved by browser (JS-rendered page) from https://iga.in.gov/legislative/2022/bills/senate/170/details on 2026-09-25.

---
snapshot_id: ed40420e-deee-5985-bcf0-875f31908b2d
source_kind: news (excerpt only)
url: https://indianacapitalchronicle.com/2026/01/27/immigration-enforcement-bill-clears-indiana-senate-amid-national-ice-controversy/

… minute of how different things would be in Minnesota if that state would simply let the ICE officials into their jails to get the people that have broken our immigration law and that are already in custody,” said Sen. Mike Gaskill, R-Pendleton. “Think how much easier things would be in Minnesota if political leaders of that state were not inciting an army of citizens who think it’s okay to attack law enforcement.” Gaskill described incidents in which ICE agents have been targeted and criticized Democratic lawmakers for what he called a “mischaracterization” of immigration enforcement. “Our immigration laws were passed in Congress by Democrats and Republicans years ago,” he said. “It’s just a matter of, are we going to enforce them, or are we not?” Democratic senators warned the bill would strain already overcrowded county jails, divert local law enforcement resources and further undermine trust between police and immigrant communities. “County jails across the state are already full,” said Sen. Shelli Yoder, D-Bloomington. “Yet, this bill demands more holds, more time in custody and more administrative burden and not taking into account even constitutional rights.” She described the legislation as “virtue signaling with real and devastating consequences” and argued that local governments would be left to absorb costs and fallout. Sen. Fady Qaddoura, D-Indianapolis, additionally referenced opposition from Indianapolis law enforcement during similar debates last year . “The Fraternal Order of Police in Indianapolis had a press conference and they opposed that type of legislation,” Qaddoura noted. “It diverts local resources of law enforcement to enforce federal law, and that will break the trust between law enforcement and our communities.” Indiana attorney general still opposed But Brown rejected claims that the bill targets immigrants broadly. “If you are here legally, this bill doesn’t pertain to you,” Brown maintained. “If you are here legally and you continue to abide …

---
snapshot_id: 6a51c12a-8c17-5105-ae64-3d6d9e9247f3
source_kind: news (excerpt only)
url: https://www.wfyi.org/health/2025-02-18/indiana-senate-passes-medicaid-hip-overhaul-despite-concerns-about-access-coverage

… 2 , Sen. Ryan Mishler (R-Mishawaka) said the bill is about “right-sizing” the program. “Medicaid's a big issue, and this is just a start,” Mishler said. “There's a lot more work to do. Medicaid's grown by $5 billion over the last four years.” SB 2 reintroduces Indiana's previously halted work requirements and limits enrollment to 500,000 people — with some flexibility based on federal Medicaid policy. That’s nearly 200,000 people less than current enrollment. READ MORE: Indiana Senate Republicans want to make big changes to HIP, Medicaid. What do those changes mean? Mishler said the program has outgrown what it was originally intended to be. However, in 2014, when Indiana filed an application for the program, FSSA said the program would be targeting 559,000 “non-disabled adults” between the ages of 19 and 64. The program is not limited to single or childless adults, despite Mishler's repeated claims that it is. Sen. Shelli Yoder (D-Bloomington) said this legislation could “threaten” the health and economic stability of Indiana. “As it currently stands, the bill — under the guise of fiscal responsibility — could result in working Hoosiers and rural hospitals being harmed the most,” Yoder said. The fiscal note for the bill said the revenue for locally owned hospitals may be reduced and there may be an increase in bad debt or charity care. Yoder said she's concerned this could lead to hospitals closing due to economic impacts. "We have 17 counties who do not have a hospital," Yoder said. "My concern is this is going to put even more strain on our current local hospital system." Hospitals in Indiana pay a fee, similar to a tax, called a Hospital Assessment Fee. That funds 90 percent of the state’s portion of the HIP program. Cigarette taxes cover the other 1 percent. Join the conversation and sign up for our weekly …

---
snapshot_id: 817d3595-590f-5246-99dc-8dd40395e766
source_kind: own-site (the person's own site or account)
url: https://indianasenatedemocrats.org/senator-yoders-2024-legislative-agenda-hoosiers-deserve-to-thrive-in-place-and-personhood/

Senator Yoder's 2024 Legislative Agenda: Hoosiers Deserve to Thrive in Place and Personhood - Indiana Senate Democrats Skip to content Toggle Navigation Senators What We Stand For Media Room Session Toggle Navigation Senators What We Stand For Media Room Session Senator Yoder’s 2024 Legislative Agenda: Hoosiers Deserve to Thrive in Place and Personhood Home Caucus Shelli Yoder Previous Next Senator Yoder’s 2024 Legislative Agenda: Hoosiers Deserve to Thrive in Place and Personhood insendems 2024-03-19T13:57:02-04:00 January 8th, 2024 | For Senator Shelli Yoder, 2024 is the year where Indiana finally promotes a quality of life for all Hoosiers and ensures they have the resources they need to thrive in both place and personhood. From reproductive justice and ending the unjust tax on menstrual products, to fighting climate change and promoting affordable housing and addressing food deserts, Senator Yoder once again has creative proposals to the immense challenges facing Indiana residents. An Overview of Senator Yoder’s Bills: SB 174 : Creates a nutritious food program under the Indiana Housing and Community Development Authority to address food deserts and provide nutrition education. SB 175 : Requires that legally allowed low THC products have packaging that must be clearly labeled and avoid certain marketing strategies that might appeal to children. SB 176 : Establishes an income tax credit for beginning farmers to promote small-scale and sustainable agriculture. SB 177 : Creates a state task force to review agrivoltaics issues for future policy recommendations. SB 203 : Exempts menstrual discharge collection devices from state sales tax. SB 207 : Promote the community land trust affordable housing model through property tax regulations. SB 208 : Repeals most provisions of SB1 from the 2022 Special Session that banned abortion. Reestablishes licensure of abortion clinics, lessens time limits on the procedure, and removes the 8-week limitation on the use of abortion inducing drugs. Senator Yoder wants to uplift vulnerable Hoosiers—those facing hunger, those seeking autonomy and control over their choice to start a family, and women seeking full involvement in society. Everyone benefits from a healthy climate, affordable housing, and safe THC products. Together with Statehouse Democrats, Senator Yoder will be fighting for Hoosiers to have a safe and equitable state to call home. Menu Senators What We Stand For Media Room Legislative Session Caucus Staff Helpful Links Get INvolved Press Release Newsroom Senate E-Newsletter Indiana General Assembly Agency Finder Connect Address: 200 W. Washington Street Indianapolis, IN 46204 Call Toll-Free 800-382-9467 © Indiana Senate Democrats | All Rights Reserved Page load link Senators What We Stand For Media Room Session Contact My Senator Go to Top

---
snapshot_id: d9257546-cef1-5033-b8a5-e8f37e1fa389
source_kind: public-record
url: https://iga.in.gov/legislative/2024/bills/senate/208/details

IGA | Senate Bill 208 - Abortion (2024) Indiana General Assembly 2024 Session. Senate Bill 208. Abortion. Introduced Senate Bill (S). Authored by: Sen. Shelli Yoder, Sen. Vaneta Becker. Digest Reestablishes the licensure of abortion clinics. Changes statutes concerning when an abortion may be performed. Removes the eight week limitation on the use of an abortion inducing drug. Allows, rather then requires, the revocation of a physician's license for the performance of an abortion in violation of the law. Latest Bill Actions S 01/22/2024 Senator Becker added as second author. S 01/09/2024 First reading: referred to Committee on Health and Provider Services. S 01/09/2024 Authored by Senator Yoder. Saved by browser (JS-rendered page) from https://iga.in.gov/legislative/2024/bills/senate/208/details on 2026-09-25.

---
snapshot_id: 52da5a1f-8a21-524a-9a16-3b1a2af5e666
source_kind: news (excerpt only)
url: https://indianacapitalchronicle.com/2025/04/04/ban-on-transgender-female-athletes-from-womens-college-teams-passes-with-bipartisan-support/

… characterization of fairness, noting that the bill does nothing to ensure equal pay for female coaches or address disparate funding. Furthermore, Democrats argued that the bill was unnecessary since the National Collegiate Athletic Association, Trump administration and Braun administration have all enacted their own policies barring transgender female athletes from playing on college teams. “(The bill) is yet another example of unnecessary language that serves no other purpose than to remind someone that they are ‘other.’ That they are not accepted here. That their own (elected) representation looks down on them,” said Sen. J.D. Ford. “… I think we should be better than this and I think Hoosiers deserve better.” Legislation from the 2022 session barred transgender female athletes from playing in K-12 sports. Bill discussion from opponents Ford and another Democrat, Minority Senate Leader Shelli Yoder, blasted the bill for a lack of protections for accused students from harassment. The six Democrats voting against House Bill 1041 are: Sen. J.D. Ford, Indianapolis Sen. Andrea Hunley, Indianapolis Sen. La Keisha Jackson, Indianapolis Sen. Fady Qaddoura, Indianapolis Sen. Mark Spencer, Gary Sen. Shelli Yoder, Bloomington “Women who work really hard — spending their lives training tirelessly to be an elite athlete — will be accused of being trans because their work has made them too bulky or too muscular or not feminine. And all it takes is one person to point that out and (they’ll) have complete immunity,” Ford said. Such accusations have already occurred on the Olympic level, notably with Algerian boxer Imane Khelif , he said. Yoder piled on, naming several coaches around the state who had been sentenced for sexually abusing their athletes, including the infamous Larry Nassar, who abused over 100 female gymnasts . “There is no language that protects against genital inspections, forced disclosure of medical history or invasive questioning by coaches or school officials. There is nothing in (House Bill) 1041 to stop a coach, athletic trainer or administrator from asking a student to prove their gender. Nothing,” said Yoder, of Bloomington. “What is in this bill is the license to discriminate. A license to sexually harass. And we’ve seen what happens when adults in positions of authority abuse that power.” Instead, Yoder said the bill would invite more scrutiny and endanger students who don’t otherwise fit into a mold — such as intersex students, who are not mentioned in the bill’s language. Support from …

---
snapshot_id: 0fd9f104-4605-5f68-a1b1-189d71fcf056
source_kind: news (excerpt only)
url: https://indianacapitalchronicle.com/2025/04/08/senate-sends-vote-center-study-student-id-voting-ban-income-tax-cuts-to-governor/

… They noted that the Legislature usually studies desired public policy changes through interim study committees. Those bodies feature representation from both parties, both chambers and, sometimes, agencies or industry. IDs, tax measures also cross finish line The chamber additionally concurred with House edits to Senate bills. Sen. Blake Doriot, R-Goshen, reported two sets of changes to his Senate Bill 10 . The legislation would no longer allow students at Indiana’s public colleges and universities to use their institutional IDs as proof of identity at the polls. One Republican-authored amendment altered voter list maintenance and data-sharing language — requiring county voter registration offices to perform voter list maintenance within just 48 hours of receiving certain information — while a Democratic one added consular reports of births abroad to a list of documents proving U.S. citizenship. Democrats maintained strong opposition to the measure, which goes to the governor on a 39-9 vote. “We are told that this bill is about election integrity, but let’s ask ourselves the hard question: where is the fraud? … Where is the abuse of student IDs in our elections?” Senate Minority Leader Shelli Yoder, D-Bloomington, asked. Legislation paring down Indiana’s individual income tax also made the cut, on a 48-0 vote. Senate Bill 451 would drop the rate by 0.05% beginning in 2030, if state general fund revenue collections exceed 3.5% growth in each of the four preceding fiscal years. The next year’s revenue forecast also must be at least 3.5%. The House bumped the baseline requirement up. The reductions would continue in every even-numbered year through 2040. Current law is already phasing Indiana’s flat income tax rate down from 3.05% in 2024 to: 3.0% in 2025, 2.95% in 2026, and 2.9% in 2027 and years thereafter. Each 0.05 percentage point reduction of tax rate would result in a decline of income tax revenues between $150 million …