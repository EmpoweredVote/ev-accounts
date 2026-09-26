You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-25-shadow-durazo/labels/coder-2.json. Write JSON only, matching
codebook Part E, with "codebook_version": "0.3" and "coder_slot": 2. One row per
topic below. Every quoted string you write must be copied exactly from a source below.

## Codebook

# Empowered Vote — Stance & Quote Codebook

**Version:** 0.3 (DRAFT, 2026-09-25). It carries rulings Q1–Q9 (design spec §9.1) and the record
fields (confirm-basis spec). The annex
readings and examples are not yet ruled on. Every label records `codebook_version`.
**Clarified 2026-09-26 (still 0.3 — no new variable, the validator got more permissive):** the
record fields are required per instrument group, not per passage (V3 "Record fields", Part E), and V3
carries a worked two-passage vote example.
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

**Hard [real].** Maria Elena Durazo / `voting-rights` / SB 1174 (2023-2024). She voted Aye on a bill
whose operative section reads "A local government shall not enact or enforce any charter provision,
ordinance, or regulation requiring a person to present identification for the purpose of voting".
The ladder asks *what* identification the government should require (rung 1: "Require no
identification to vote …").
- The bill decides *which level of government* may set an ID rule. It leaves the state's own rule
  as it is, and it says nothing about what that rule should be. A legislator can oppose a local
  patchwork and still favour a state photo-ID law. → `adjacent`.
- A preemption bill is `on-question` only when a rung is itself about which level decides.
- 2026-09-25/26: three coders read it as rung 1, twice. Each time, the page mechanics (vote page,
  bill text, a divided 30–8 tally) were correct, so CONFIRM cannot catch this reading. Only V2 can.

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
- **Record fields (0.3).**
  - `record_kind` is one of `vote` / `sponsor` / `author` / `other-act`. Every `record` passage
    carries it — the bill-text page of a vote is `vote` too.
  - `actor_quote` is the words, verbatim, showing this person acted: the Aye/No list segment that
    contains the surname, or the author/sponsor line. If two members on the page share the surname,
    or the surname is a common one (Adams, Walker, Smith …), include the initial or first name (for
    example `Walker G`, or `Watson, R.`).
  - `tally_quote` is the vote count text, verbatim (for example `Ayes Count 29 Noes Count 8`).
  - **They are required per record, not per page (ruling 2026-09-26).** All `record` passages on one
    `instrument` are one record. At least one of them carries `actor_quote`; for a vote, at least one
    carries `tally_quote`. Put each fact on the page that prints it: `actor_quote` and `tally_quote`
    on the vote page, `provision_quote` on the page that prints the provision (usually the bill
    text). A page that does not print a fact carries `null` for it — never copy a fact onto a page
    that does not show it.
- `instrument` names the bill and the session (for example `SB 1174 (2023-2024)`); every page of
  one record must name the same instrument.

**Worked example — a vote is two passages.** The vote page names the voter and the count but not
the provision; the bill text prints the provision but names no voter. Both are in `rests_on`.

| field | vote page (`billVotesClient`, SB 1174) | bill text (`billNavClient`, SB 1174) |
|---|---|---|
| `v3_class` / `record_kind` | `record` / `vote` | `record` / `vote` |
| `instrument` | `SB 1174 (2023-2024)` | `SB 1174 (2023-2024)` |
| `actor_quote` | `Ayes Archuleta, Ashby, … Dodd, Durazo` | `null` |
| `tally_quote` | `Ayes Count 30 Noes Count 8` | `null` |
| `provision_quote` | `null` | `A local government shall not enact or enforce any charter provision, …` |

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
- A vote whose `tally_quote` shows fewer than 10% No is `near-unanimous` and cannot carry the chair
  alone; a claimed vote with no vote page (for example a bill that died in committee) is not a vote.

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
Synonyms: statute or program names the state uses for this topic (e.g. "Medical Assistance Program" for Medicaid in Maryland)
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
| H12 | A bill that forbids another level of government to act (preemption) coded as the rule itself | V2 `adjacent` | V2 | [real] Durazo / voting-rights (SB 1174) |

---

## Part E — Coder output schema (`labels/coder-N.json`)

```json
{
  "codebook_version": "0.3",
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
          "note": "≤ 1 sentence",
          "record_kind": "vote | sponsor | author | other-act | null",
          "actor_quote": "verbatim span showing this person acted | null",
          "tally_quote": "verbatim vote count text | null"
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
- A `record` passage (`v3_class = "record"`) requires `record_kind`. Per instrument group (all
  `record` passages of the row on one `instrument`), at least one passage carries a non-empty
  `actor_quote`, and a group that is a `vote` has at least one non-empty `tally_quote` (ruling
  2026-09-26). `actor_quote` and `tally_quote`, when present, are verbatim in their snapshot.


## The person

politician_id: c7dc9c50-84c6-4bde-af06-e7f9d5167e93  office_id: 493a571f-b01b-4253-afbc-ffe3979f52bb
Maria Elena Durazo — Senator, California (seated, level: state)
Current term: 2022-12-05 (precision: day) to present

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

### topic_key: childcare
topic_id: c1ac1330-47f7-44ec-baf3-c913d926b97c  served_revision_id: 0e9fe0f2-cfab-4553-99cd-c3195d08e236
Question: How should government address the cost and availability of childcare?
  1. Establishing publicly funded universal childcare so that all families have access regardless of income
  2. Significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families
  3. Offering targeted tax credits and subsidies for families below a set income threshold while supporting providers through training and facility grants
  4. Limiting government support to childcare subsidies for the lowest-income families, relying on the private market for everyone else
  5. Leaving childcare to the private market and families, with no government subsidies or mandates that increase costs for providers and taxpayers

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

### topic_key: deportation
topic_id: 44905f3b-e105-4f6c-afc7-5d223813dbac  served_revision_id: 55c3167e-3ad8-425d-a699-b2e91552d912
Question: How far should the government go in deporting undocumented immigrants?
  1. Stop deportations entirely and protect undocumented immigrants from removal
  2. Only deport undocumented immigrants convicted of serious violent crimes
  3. Focus deportation on recent arrivals while leaving long-settled undocumented immigrants in place
  4. Deport all undocumented immigrants, starting with those who have criminal records
  5. Carry out a mass-deportation program to remove all undocumented immigrants, including long-settled families and workers

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

**Synonyms:** "education savings account" (ESA), "scholarship", "tax-credit scholarship",
"Choice Scholarship" (Indiana), "Utah Fits All".

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

# voting-rights — annex (Season 2 served text; draft, not ruled)

**Question:** "How should the government verify a voter's identity and eligibility?"

**Orientation:** standard. Rung 1 requires the least identification, rung 5 the most.

**Levels:** state (the lever: election codes set ID and registration rules), federal (registration
and mail-ballot rules for federal elections). Local governments run elections but, in most states,
cannot set their own ID rules. Verify against `compass_topic_roles` before use.

**Synonyms:** "voter identification", "voter ID", "photo identification", "proof of citizenship",
"documentary proof", "SAVE Act", "signature verification", "HAVA identification".

1. **"Require no identification to vote, verifying voters by signature or existing records."**
   - Clauses: [a] no ID at the polls; [b] signature or record matching instead.
   - Evidence: a bill that removes an existing state ID requirement; own words against any ID.
   - Confused with 2 when the person only opposes *photo* ID.
2. **"Accept non-photo identification, such as a utility bill or bank statement."**
   - Clauses: [a] ID required; [b] non-photo documents accepted.
   - Evidence: a bill that widens the accepted list to non-photo documents.
3. **"Require photo ID to vote, but let voters without one cast a ballot after signing an affidavit."**
   - Clauses: [a] photo ID; [b] an affidavit fallback.
4. **"Require photo ID in person and an ID number on every mail ballot."**
   - Clauses: [a] photo ID in person; [b] an ID number on mail ballots.
5. **"Require documentary proof of citizenship to register to vote."**
   - Clauses: [a] documentary proof of citizenship at registration.
   - Evidence: a proof-of-citizenship bill (for example the federal SAVE Act).

**Hard cases:**
- **Preemption is not the rule (codebook V2, H12).** A bill that forbids local governments to require
  ID (California SB 1174, 2024) decides *which level* may set the rule, not *what* the rule is. →
  `adjacent`.
- A mail-ballot rule with no identity clause (drop boxes, deadlines) → `adjacent` (codebook V2).
- An omnibus election bill that includes an ID clause → V4 `multi-subject`.


## Sources

---
snapshot_id: f3a91fb1-d408-5e30-ac76-3fd187a53bf5
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57

Bill Votes - SB-57 Electrical corporations: data centers: report. (2025-2026) California Legislative Information || Date 09/13/25 Result (PASS) Location Senate Floor Ayes Count 29 Noes Count 8 NVR Count 3 Motion Unfinished Business SB57 Padilla et al. Concurrence Ayes Allen, Archuleta, Arreguín, Ashby, Becker, Blakespear, Cabaldon, Caballero, Cervantes, Cortese, Durazo, Grayson, Hurtado, Laird, Limón, McGuire, McNerney, Menjivar, Padilla, Pérez, Reyes, Richardson, Rubio, Smallwood-Cuevas, Stern, Umberg, Wahab, Weber Pierson, Wiener Noes Alvarado-Gil, Dahle, Grove, Jones, Niello, Ochoa Bogh, Seyarto, Strickland NVR Choi, Gonzalez, Valladares || Date 05/28/25 Result (PASS) Location Senate Floor Ayes Count 25 Noes Count 9 NVR Count 6 Motion Senate 3rd Reading SB57 Padilla et al. Ayes Allen, Archuleta, Arreguín, Ashby, Becker, Blakespear, Cabaldon, Cervantes, Durazo, Gonzalez, Hurtado, Laird, McGuire, McNerney, Menjivar, Padilla, Pérez, Richardson, Rubio, Smallwood-Cuevas, Stern, Umberg, Wahab, Weber Pierson, Wiener Noes Alvarado-Gil, Choi, Grove, Jones, Niello, Ochoa Bogh, Seyarto, Strickland, Valladares NVR Caballero, Cortese, Dahle, Grayson, Limón, Reyes Senate Floor vote blocks only. Saved by browser (robots-disallowed page) from leginfo.legislature.ca.gov billVotesClient on 2026-09-25.

---
snapshot_id: a0875722-e1b5-56fd-8f6b-0d92898f8cbe
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB729

Bill Text - SB-729 Health care coverage: treatment for infertility and fertility services. skip to content home accessibility FAQ feedback sitemap login x Quick Search: Bill Number Bill Keyword Home Bill Information California Law Publications Other Resources My Subscriptions My Favorites Bill Information >> Bill Search >> Text Bill Text Bill Information PDF2 Bill PDF | Add To My Favorites | Version: 09/29/24 - Chaptered 09/03/24 - Enrolled 08/22/24 - Amended Assembly 08/14/23 - Amended Assembly 05/18/23 - Amended Senate 05/01/23 - Amended Senate 02/17/23 - Introduced SB-729 Health care coverage: treatment for infertility and fertility services. (2023-2024) Text >> Votes >> History >> Bill Analysis >> Today's Law As Amended >> Compare Versions >> Status >> Comments To Author >> Add To My Favorites >> SHARE THIS: Date Published: 09/30/2024 02:00 PM SB729:v93#DOCUMENT Bill Start Senate Bill No. 729 CHAPTER 930 An act to repeal and add Section 1374.55 of the Health and Safety Code, and to repeal and add Section 10119.6 of the Insurance Code, relating to health care coverage. [ Approved by Governor September 29, 2024. Filed with Secretary of State September 29, 2024. ] LEGISLATIVE COUNSEL'S DIGEST SB 729, Menjivar. Health care coverage: treatment for infertility and fertility services. Existing law, the Knox-Keene Health Care Service Plan Act of 1975, provides for the licensure and regulation of health care service plans by the Department of Managed Health Care and makes a willful violation of the act a crime. Existing law provides for the regulation of disability insurers by the Department of Insurance. Existing law imposes various requirements and restrictions on health care service plans and disability insurers, including, among other things, a requirement that every group health care service plan contract or disability insurance policy that is issued, amended, or renewed on or after January 1, 1990, offer coverage for the treatment of infertility, except in vitro fertilization. This bill would require large and small group health care service plan contracts and disability insurance policies issued, amended, or renewed on or after July 1, 2025, to provide coverage for the diagnosis and treatment of infertility and fertility services. With respect to large group health care service plan contracts and disability insurance policies, the bill would require coverage for a maximum of 3 completed oocyte retrievals, as specified. The bill would revise the definition of infertility, and would remove the exclusion of in vitro fertilization from coverage. The bill would also delete a requirement that a health care service plan contract and disability insurance policy provide infertility treatment under agreed-upon terms that are communicated to all group contractholders and policyholders. The bill would prohibit a health care service plan or disability insurer from placing different conditions or coverage limitations on fertility medications or services, or the diagnosis and treatment of infertility and fertility services, than would apply to other conditions, as specified. The bill would make these requirements inapplicable to a religious employer, as defined, and specified contracts and policies. Because the violation of these provisions by a health care service plan would be a crime, the bill would impose a state-mandated local program. The California Constitution requires the state to reimburse local agencies and school districts for certain costs mandated by the state. Statutory provisions establish procedures for making that reimbursement. This bill would provide that no reimbursement is required by this act for a specified reason. Digest Key Vote: MAJORITY Appropriation: NO Fiscal Committee: YES Local Program: YES Bill Text The people of the State of California do enact as follows: SECTION 1. Section 1374.55 of the Health and Safety Code is repealed. SEC. 2. Section 1374.55 is added to the Health and Safety Code, to read: 1374.55. (a) (1) A large group health care service plan contract, except a specialized health care service plan contract, that is issued, amended, or renewed on or after July 1, 2025, shall provide coverage for the diagnosis and treatment of infertility and fertility services, including a maximum of three completed oocyte retrievals with unlimited embryo transfers in accordance with the guidelines of the American Society for Reproductive Medicine (ASRM), using single embryo transfer when recommended and medically appropriate. (2) A small group health care service plan contract, except a specialized health care service plan contract, that is issued, amended, or renewed on or after July 1, 2025, shall offer coverage for the diagnosis and treatment of infertility and fertility services. This paragraph shall not be construed to require a small group health care service plan contract to provide coverage for infertility services. (3) A health care service plan shall include notice of the coverage specified in this section in the plan’s evidence of coverage. (b) For purposes of this section, “infertility” means a condition or status characterized by any of the following: (1) A licensed physician’s findings, based on a patient’s medical, sexual, and reproductive history, age, physical findings, diagnostic testing, or any combination of those factors. This definition shall not prevent testing and diagnosis of infertility before the 12-month or 6-month period to establish infertility in paragraph (3). (2) A person’s inability to reproduce either as an individual or with their partner without medical intervention. (3) The failure to establish a pregnancy or to carry a pregnancy to live birth after regular, unprotected sexual intercourse. For purposes of this section, “regular, unprotected sexual intercourse” means no more than 12 months of unprotected sexual intercourse for a person under 35 years of age or no more than 6 months of unprotected sexual intercourse for a person 35 years of age or older. Pregnancy resulting in miscarriage does not restart the 12-month or 6-month time period to qualify as having infertility. (c) The contract may not include any of the following: (1) Any exclusion, limitation, or other restriction on coverage of fertility medications that are different from those imposed on other prescription medications. (2) Any exclusion or denial of coverage of any fertility services based on a covered individual’s participation in fertility services provided by or to a third party. For purposes of this section, “third party” includes an oocyte, sperm, or embryo donor, gestational carrier, or surrogate that enables an intended recipient to become a parent. (3) Any deductible, copayment, coinsurance, benefit maximum, waiting period, or any other limitation on coverage for the diagnosis and treatment of infertility, except as provided in subdivision (a) that are different from those imposed upon benefits for services not related to infertility. (d) This section does not in any way deny or restrict any existing right or benefit to coverage and treatment of infertility or fertility services under an existing law, plan, or policy. (e) Consistent with Section 1365.5, coverage for the treatment of infertility and fertility services shall be provided without discrimination on the basis of age, ancestry, color, disability, domestic partner status, gender, gender expression, gender identity, genetic information, marital status, national origin, race, religion, sex, or sexual orientation. This subdivision shall not be construed to interfere with the clinical judgment of a physician and surgeon. (f) This section does not apply to Medi-Cal managed care health care service plan contracts or any entity that enters into a contract with the State Department of Health Care Services for the delivery of health care services pursuant to Chapter 7 (commencing with Section 14000), Chapter 8 (commencing with Section 14200), Chapter 8.75 (commencing with Section 14591), or Chapter 8.9 (commencing with Section 14700) of Part 3 of Division 9 of the Welfare and Institutions Code. (g) This section shall not apply to a religious employer, as defined in Section 1367.25. (h) This section shall not apply to a health care benefit plan or contract entered into with the Board of Administration of the Public Employees’ Retirement System pursuant to the Public Employees’ Medical and Hospital Care Act (Part 5 (commencing with Section 22750) of Division 5 of Title 2 of the Government Code) until July 1, 2027. SEC. 3. Section 10119.6 of the Insurance Code is repealed. SEC. 4. Section 10119.6 is added to the Insurance Code, to read: 10119.6. (a) (1) A large group disability insurance policy, except a specialized disability insurance policy, that is issued, amended, or renewed on or after July 1, 2025, shall provide coverage for the diagnosis and treatment of infertility and fertility services, including a maximum of three completed oocyte retrievals with unlimited embryo transfers in accordance with the guidelines of the American Society for Reproductive Medicine (ASRM), using single embryo transfer when recommended and medically appropriate. (2) A small group disability insurance policy, except a disability insurance policy described in paragraph (4), that is issued, amended, or renewed on or after July 1, 2025, shall offer coverage for the diagnosis and treatment of infertility and fertility services. This paragraph shall not be construed to require a small group disability insurance policy to provide coverage for infertility services. (3) A disability insurer shall include notice of the coverage specified in this section in the insurer’s evidence of coverage. (4) This section shall not apply to accident-only, specified disease, hospital indemnity, Medicare supplement, or specialized disability insurance policies. (b) For purposes of this section, “infertility” means a condition or status characterized by any of the following: (1) A licensed physician’s findings, based on a patient’s medical, sexual, and reproductive history, age, physical findings, diagnostic testing, or any combination of those factors. This definition shall not prevent testing and diagnosis before the 12-month or 6-month period to establish infertility in paragraph (3). (2) A person’s inability to reproduce either as an individual or with their partner without medical intervention. (3) The failure to establish a pregnancy or to carry a pregnancy to live birth after regular, unprotected sexual intercourse. For purposes of this section “regular, unprotected sexual intercourse” means no more than 12 months of unprotected sexual intercourse for a person under 35 years of age or no more than 6 months of unprotected sexual intercourse for a person 35 years of age or older. Pregnancy resulting in miscarriage does not restart the 12-month or 6-month time period to qualify as having infertility. (c) The policy may not include any of the following: (1) Any exclusion, limitation, or other restriction on coverage of fertility medications that are different from those imposed on other prescription medications. (2) Any exclusion or denial of coverage of any fertility services based on a covered individual’s participation in fertility services provided by or to a third party. For purposes of this section, “third party” includes an oocyte, sperm, or embryo donor, gestational carrier, or surrogate that enables an intended recipient to become a parent. (3) Any deductible, copayment, coinsurance, benefit maximum, waiting period, or any other limitation on coverage for the diagnosis and treatment of infertility, except as provided in subdivision (a) that are different from those imposed upon benefits for services not related to infertility. (d) This section does not in any way deny or restrict any existing right or benefit to coverage and treatment of infertility or fertility services under an existing law, plan, or policy. (e) This section applies to every disability insurance policy that is issued, amended, or renewed to residents of this state regardless of the situs of the contract. (f) Consistent with Section 10140, coverage for the treatment of infertility and fertility services shall be provided without discrimination on the basis of age, ancestry, color, disability, domestic partner status, gender, gender expression, gender identity, genetic information, marital status, national origin, race, religion, sex, or sexual orientation. This subdivision shall not be construed to interfere with the clinical judgment of a physician and surgeon. (g) This section shall not apply to a religious employer, as defined in Section 10123.196. (h) This section shall not apply to a health care benefit plan or policy entered into with the Board of Administration of the Public Employees’ Retirement System pursuant to the Public Employees’ Medical and Hospital Care Act (Part 5 (commencing with Section 22750) of Division 5 of Title 2 of the Government Code) until July 1, 2027. SEC. 5. No reimbursement is required by this act pursuant to Section 6 of Article XIII B of the California Constitution because the only costs that may be incurred by a local agency or school district will be incurred because this act creates a new crime or infraction, eliminates a crime or infraction, or changes the penalty for a crime or infraction, within the meaning of Section 17556 of the Government Code, or changes the definition of a crime within the meaning of Section 6 of Article XIII B of the California Constitution.

---
snapshot_id: aa219c5b-dbee-5027-b3cb-bbba415b5977
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174

Bill Votes - SB-1174 Elections: voter identification. (2023-2024) California Legislative Information || Date 05/21/24 Result (PASS) Location Senate Floor Ayes Count 30 Noes Count 8 NVR Count 2 Motion Senate 3rd Reading SB1174 Min et al. Ayes Archuleta, Ashby, Atkins, Becker, Blakespear, Bradford, Caballero, Cortese, Dodd, Durazo, Eggman, Glazer, Gonzalez, Hurtado, Laird, Limón, McGuire, Menjivar, Min, Newman, Padilla, Portantino, Roth, Rubio, Skinner, Smallwood-Cuevas, Stern, Umberg, Wahab, Wiener Noes Dahle, Grove, Jones, Nguyen, Niello, Ochoa Bogh, Seyarto, Wilk NVR Allen, Alvarado-Gil Senate Floor vote blocks only. Saved by browser (robots-disallowed page) from leginfo.legislature.ca.gov billVotesClient on 2026-09-25.

---
snapshot_id: 8666d0a3-1cdd-5281-acc3-596657c85fd4
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955

Bill Votes - AB-1955 Support Academic Futures and Educators for Today’s Youth Act. (2023-2024) California Legislative Information || Date 06/13/24 Result (PASS) Location Senate Floor Ayes Count 29 Noes Count 8 NVR Count 3 Motion Assembly 3rd Reading AB1955 Ward et al. By Eggman Ayes Allen, Archuleta, Ashby, Atkins, Becker, Blakespear, Bradford, Caballero, Cortese, Dodd, Durazo, Eggman, Glazer, Gonzalez, Hurtado, Laird, McGuire, Menjivar, Min, Newman, Padilla, Portantino, Roth, Rubio, Skinner, Smallwood-Cuevas, Umberg, Wahab, Wiener Noes Dahle, Grove, Jones, Nguyen, Niello, Ochoa Bogh, Seyarto, Wilk NVR Alvarado-Gil, Limón, Stern Senate Floor vote blocks only. Saved by browser (robots-disallowed page) from leginfo.legislature.ca.gov billVotesClient on 2026-09-25.

---
snapshot_id: 79c1076f-b9be-59bb-889a-f8dd7daac037
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112

Bill Votes - SB-1112 Childcare: alternative payment programs. (2023-2024) California Legislative Information || Date 08/30/24 Result (PASS) Location Senate Floor Ayes Count 40 Noes Count 0 NVR Count 0 Motion Unfinished Business SB1112 Menjivar et al. Concurrence Ayes Allen, Alvarado-Gil, Archuleta, Ashby, Atkins, Becker, Blakespear, Bradford, Caballero, Cortese, Dahle, Dodd, Durazo, Eggman, Glazer, Gonzalez, Grove, Hurtado, Jones, Laird, Limón, McGuire, Menjivar, Min, Newman, Nguyen, Niello, Ochoa Bogh, Padilla, Portantino, Roth, Rubio, Seyarto, Skinner, Smallwood-Cuevas, Stern, Umberg, Wahab, Wiener, Wilk Noes NVR || Date 05/24/24 Result (PASS) Location Senate Floor Ayes Count 38 Noes Count 0 NVR Count 2 Motion Special Consent SB1112 Menjivar et al. Ayes Alvarado-Gil, Ashby, Atkins, Becker, Blakespear, Bradford, Caballero, Cortese, Dahle, Dodd, Durazo, Eggman, Glazer, Gonzalez, Grove, Hurtado, Jones, Laird, Limón, McGuire, Menjivar, Min, Newman, Nguyen, Niello, Ochoa Bogh, Padilla, Portantino, Roth, Rubio, Seyarto, Skinner, Smallwood-Cuevas, Stern, Umberg, Wahab, Wiener, Wilk Noes NVR Allen, Archuleta Senate Floor vote blocks only. Saved by browser (robots-disallowed page) from leginfo.legislature.ca.gov billVotesClient on 2026-09-25.

---
snapshot_id: d7255bbb-f88a-53a1-b47b-ca619c0ad279
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1174

Bill Text - SB-1174 Elections: voter identification. skip to content home accessibility FAQ feedback sitemap login x Quick Search: Bill Number Bill Keyword Home Bill Information California Law Publications Other Resources My Subscriptions My Favorites Bill Information >> Bill Search >> Text Bill Text Bill Information PDF2 Bill PDF | Add To My Favorites | Version: 09/29/24 - Chaptered 08/29/24 - Enrolled 05/02/24 - Amended Senate 03/18/24 - Amended Senate 02/14/24 - Introduced SB-1174 Elections: voter identification. (2023-2024) Text >> Votes >> History >> Bill Analysis >> Today's Law As Amended >> Compare Versions >> Status >> Comments To Author >> Add To My Favorites >> SHARE THIS: Date Published: 09/30/2024 09:00 PM SB1174:v95#DOCUMENT Bill Start Senate Bill No. 1174 CHAPTER 990 An act to add Section 10005 to the Elections Code, relating to elections. [ Approved by Governor September 29, 2024. Filed with Secretary of State September 29, 2024. ] LEGISLATIVE COUNSEL'S DIGEST SB 1174, Min. Elections: voter identification. Existing law permits the governing body of a city or district to request that the county render specified services to the city or district regarding the conduct of an election. This bill would prohibit a local government from enacting or enforcing any charter provision, ordinance, or regulation requiring a person to present identification for the purpose of voting or submitting a ballot at any polling place, vote center, or other location where ballots are cast or submitted, as specified. The bill would include findings that changes proposed by this bill address a matter of statewide concern rather than a municipal affair and, therefore, apply to all cities, including charter cities. Digest Key Vote: MAJORITY Appropriation: NO Fiscal Committee: NO Local Program: NO Bill Text The people of the State of California do enact as follows: SECTION 1. (a) The Legislature finds and declares all of the following: (1) Under existing law, a person is entitled to vote in a local, special, or consolidated election who is registered in any one of the precincts which compose the local, special, or consolidated election precinct. (2) California ensures the integrity of its elections by requiring a person to provide a driver’s license number, a California identification number, or the last four digits of their social security number to register to vote. (3) The state has taken further steps to ensure election integrity, including signature verification checks, mandatory partial recounts, and ballot tracking. (4) Voter identification laws have historically been used to disenfranchise low-income voters, voters of color, voters with disabilities, and senior voters. (5) Existing law gives the Secretary of State jurisdiction over voter-eligibility functions. (6) Under existing law, local elections officials are responsible for supervising voting at the polls. (7) Voter identification laws place the onus on the voter to prove their identity and right to vote, even after voters have taken the necessary steps to prove their identity and right to vote through the voter registration process. (8) The implementation of voter identification laws in municipal elections conflicts with California’s established, well-balanced methods of ensuring election integrity across the state. (b) The Legislature finds and declares that Section 2 of this act adding Section 10005 of the Elections Code addresses a matter of statewide concern rather than a municipal affair as that term is used in Section 5 of Article XI of the California Constitution. Therefore, Section 2 of this act applies to all cities, including charter cities. SEC. 2. Section 10005 is added to the Elections Code, to read: 10005. A local government shall not enact or enforce any charter provision, ordinance, or regulation requiring a person to present identification for the purpose of voting or submitting a ballot at any polling place, vote center, or other location where ballots are cast or submitted, unless required by state or federal law. For the purpose of this section, “local government” means any charter or general law city, charter or general law county, or any city and county.

---
snapshot_id: 4993243e-1f51-580d-95b3-19cd9f7279e2
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729

Bill Votes - SB-729 Health care coverage: treatment for infertility and fertility services. (2023-2024) California Legislative Information || Date 08/29/24 Result (PASS) Location Senate Floor Ayes Count 31 Noes Count 8 NVR Count 1 Motion Unfinished Business SB729 Menjivar et al. Concurrence Ayes Allen, Archuleta, Ashby, Atkins, Becker, Blakespear, Bradford, Caballero, Cortese, Dodd, Durazo, Eggman, Glazer, Gonzalez, Hurtado, Laird, Limón, McGuire, Menjivar, Min, Newman, Padilla, Portantino, Roth, Rubio, Skinner, Smallwood-Cuevas, Stern, Umberg, Wahab, Wiener Noes Alvarado-Gil, Dahle, Grove, Jones, Nguyen, Niello, Seyarto, Wilk NVR Ochoa Bogh || Date 05/24/23 Result (PASS) Location Senate Floor Ayes Count 31 Noes Count 3 NVR Count 6 Motion Senate 3rd Reading SB729 Menjivar et al. Ayes Allen, Archuleta, Ashby, Atkins, Becker, Blakespear, Bradford, Caballero, Cortese, Dodd, Durazo, Eggman, Glazer, Gonzalez, Hurtado, Laird, Limón, McGuire, Menjivar, Min, Newman, Padilla, Portantino, Roth, Rubio, Skinner, Smallwood-Cuevas, Stern, Umberg, Wahab, Wiener Noes Jones, Niello, Seyarto NVR Alvarado-Gil, Dahle, Grove, Nguyen, Ochoa Bogh, Wilk Senate Floor vote blocks only. Saved by browser (robots-disallowed page) from leginfo.legislature.ca.gov billVotesClient on 2026-09-25.

---
snapshot_id: 8b8b97cb-a441-5903-a984-346577517aeb
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB57

Bill Text - SB-57 Electrical corporations: data centers: report. skip to content home accessibility FAQ feedback sitemap login x Quick Search: Bill Number Bill Keyword Home Bill Information California Law Publications Other Resources My Subscriptions My Favorites Bill Information >> Bill Search >> Text Bill Text Bill Information PDF2 Bill PDF | Add To My Favorites | Track Bill | Version: 10/11/25 - Chaptered 09/18/25 - Enrolled 09/02/25 - Amended Assembly 07/14/25 - Amended Assembly 06/30/25 - Amended Assembly 04/10/25 - Amended Senate 03/26/25 - Amended Senate 03/05/25 - Amended Senate 01/08/25 - Introduced SB-57 Electrical corporations: data centers: report. (2025-2026) Text >> Votes >> History >> Bill Analysis >> Today's Law As Amended >> Compare Versions >> Status >> Comments To Author >> Track Bill >> Add To My Favorites >> SHARE THIS: Date Published: 10/13/2025 02:00 PM SB57:v91#DOCUMENT Bill Start Senate Bill No. 57 CHAPTER 647 An act to add and repeal Section 913.22 of the Public Utilities Code, relating to electricity. [ Approved by Governor October 11, 2025. Filed with Secretary of State October 11, 2025. ] LEGISLATIVE COUNSEL'S DIGEST SB 57, Padilla. Electrical corporations: data centers: report. Existing law vests the Public Utilities Commission with regulatory authority over public utilities, including electrical corporations. Existing law authorizes the commission to fix the rates and charges for every public utility and requires that those rates and charges be just and reasonable. This bill would authorize the commission to assess the extent to which electrical corporation costs associated with new loads from data centers result in cost shifts to other electrical corporation customers, as provided. The bill would require the commission to submit an assessment completed pursuant to that authorization to the relevant policy committees of the Legislature and to publicly post a copy of the assessment on the commission’s internet website on or before January 1, 2027. Digest Key Vote: MAJORITY Appropriation: NO Fiscal Committee: YES Local Program: NO Bill Text The people of the State of California do enact as follows: SECTION 1. This act shall be known, and may be cited, as the Ratepayer and Technological Innovation Protection Act. SEC. 2. The Legislature finds and declares all of the following: (a) California drives worldwide technological innovation, and that innovation is an important component of the state’s economy, which is the fifth largest economy in the world. (b) California supports technological innovation with a world-class university system that provides a highly skilled workforce, and research and development tax incentives and other tools to facilitate the development and expansion of the state’s technology economy. (c) The quickly evolving development of artificial intelligence requires large-format data centers that currently require extremely large loads of electricity and water. While that expanded energy demand can help support the larger electrical grid and ordinary ratepayers, if managed incorrectly, it could pose a serious threat to California’s climate goals and, more importantly, leave existing ratepayers saddled with the enormous costs of stranded assets built to support that industry. Furthermore, with the appropriate guardrails, the increased consumption from these large-load customers could help drive down electricity rates for existing utility customers. (d) More efficient use of existing electrical and grid assets and the sharing of fixed energy costs across a larger overall demand can lower the cost to individual customers as a result of a new data center development. (e) It is the goal of the state that the development of new large load customers support clean energy and the state’s climate goals while encouraging more efficient use of existing assets and the potential to lower costs to all customers. SEC. 3. Section 913.22 is added to the Public Utilities Code, to read: 913.22. (a) The commission may assess the extent to which electrical corporation costs associated with new loads from data centers result in cost shifts to other electrical corporation customers. This assessment may include, but not be limited to, the following: (1) An analysis of potential electrical corporation costs associated with utility procurement to meet growing load demands from data centers’ increased energy consumption. (2) An analysis of potential electrical corporation costs associated with the installation of new transmission and distribution assets to serve new data centers or expansions of existing data centers, including the costs of stranded assets and assets installed for an entity that ceases operation. (3) Identification of opportunities to prevent or mitigate any substantial cost shifts, if the cost shifts are identified. (b) The commission shall submit an assessment completed pursuant to this section to the relevant policy committees of the Legislature and publicly post a copy of the assessment on the commission’s internet website on or before January 1, 2027. (c) Pursuant to Section 10231.5 of the Government Code, this section is repealed on January 1, 2031.

---
snapshot_id: 178b73c0-a303-5afb-971b-9947d852292e
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1112

Bill Text - SB-1112 Childcare: alternative payment programs. skip to content home accessibility FAQ feedback sitemap login x Quick Search: Bill Number Bill Keyword Home Bill Information California Law Publications Other Resources My Subscriptions My Favorites Bill Information >> Bill Search >> Text Bill Text Bill Information PDF2 Bill PDF | Add To My Favorites | Version: 09/30/24 - Chaptered 09/04/24 - Enrolled 08/19/24 - Amended Assembly 05/16/24 - Amended Senate 03/21/24 - Amended Senate 02/13/24 - Introduced SB-1112 Childcare: alternative payment programs. (2023-2024) Text >> Votes >> History >> Bill Analysis >> Today's Law As Amended >> Compare Versions >> Status >> Comments To Author >> Add To My Favorites >> SHARE THIS: Date Published: 09/30/2024 09:00 PM SB1112:v94#DOCUMENT Bill Start Senate Bill No. 1112 CHAPTER 1016 An act to amend Section 10229 of the Welfare and Institutions Code, relating to childcare. [ Approved by Governor September 30, 2024. Filed with Secretary of State September 30, 2024. ] LEGISLATIVE COUNSEL'S DIGEST SB 1112, Menjivar. Childcare: alternative payment programs. Existing law establishes a system of childcare and development services, administered by the State Department of Social Services, for children from infancy to 13 years of age. Existing federal law establishes the Child Care and Development Fund authorized under the Child Care and Development Block Grant Act of 2014 and administered by states to provide assistance to low-income families who need childcare due to specified reasons. Existing federal law requires a portion of those funds to be used to disseminate information on existing resources for developmental screenings and descriptions of how a family may utilize those resources to obtain developmental screenings. Existing law authorizes, upon departmental approval, the use of appropriated funds for alternative payment programs to allow for maximum parental choice. Existing law authorizes the reimbursement to those programs for the cost of child care paid to child care providers and the administrative and support services costs of the alternative program. This bill would state that the costs allowable for administration shall include, but not be limited to, costs associated with disseminating the above-described information. Digest Key Vote: MAJORITY Appropriation: NO Fiscal Committee: YES Local Program: NO Bill Text The people of the State of California do enact as follows: SECTION 1. Section 10229 of the Welfare and Institutions Code is amended to read: 10229. The reimbursement for alternative payment programs shall include the cost of child care paid to child care providers plus the administrative and support services costs of the alternative payment program. The total cost for administration and support services shall not exceed an amount equal to 17.5 percent of the total contract amount. The administrative costs shall not exceed the costs allowable for administration under federal requirements, and shall include, but not be limited to, costs associated with the dissemination of information on developmental screenings, including information on existing resources and a description of how a family or eligible child care provider may utilize those resources to obtain developmental screenings, as described in Section 9858c of the Title 42 of the United States Code.

---
snapshot_id: 4ba84a78-7403-5a1d-adf0-765e30c8402f
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB494

Bill Text - SB-494 School district governing boards: meetings: school district superintendents and assistant superintendents: termination. skip to content home accessibility FAQ feedback sitemap login x Quick Search: Bill Number Bill Keyword Home Bill Information California Law Publications Other Resources My Subscriptions My Favorites Bill Information >> Bill Search >> Text Bill Text Bill Information PDF2 Bill PDF | Add To My Favorites | Version: 10/13/23 - Chaptered 09/15/23 - Enrolled 09/07/23 - Amended Assembly 06/30/23 - Amended Assembly 06/08/23 - Amended Assembly 03/20/23 - Amended Senate 02/14/23 - Introduced SB-494 School district governing boards: meetings: school district superintendents and assistant superintendents: termination. (2023-2024) Text >> Votes >> History >> Bill Analysis >> Today's Law As Amended >> Compare Versions >> Status >> Comments To Author >> Add To My Favorites >> SHARE THIS: Date Published: 10/16/2023 09:00 PM SB494:v93#DOCUMENT Bill Start Senate Bill No. 494 CHAPTER 875 An act to add Section 35150 to the Education Code, relating to school districts. [ Approved by Governor October 13, 2023. Filed with Secretary of State October 13, 2023. ] LEGISLATIVE COUNSEL'S DIGEST SB 494, Newman. School district governing boards: meetings: school district superintendents and assistant superintendents: termination. Existing law requires the governing board of any school district to fix the time and place for its regular meetings with proper notice to all members of the governing board of the regular meetings. Existing law authorizes the presiding officer of the governing board of a school district, or a majority of the members of the governing board of a school district, to call a special meeting of the governing board of the school district at any time if specified notice requirements are met. This bill would prohibit the governing board of a school district from taking action to terminate a superintendent or assistant superintendent of the school district, or both, without cause, at a special or emergency meeting of the governing board or within 30 days after the first convening of the governing board after an election at which one or more members of the governing board are elected or recalled, as provided. For the purpose of terminating a superintendent or assistant superintendent, or both, without cause, the bill would authorize the governing board of a school district to hold a regular meeting, as specified, during any month in which a regular meeting of the governing board is not scheduled. Digest Key Vote: MAJORITY Appropriation: NO Fiscal Committee: NO Local Program: NO Bill Text The people of the State of California do enact as follows: SECTION 1. Section 35150 is added to the Education Code, immediately following Section 35149, to read: 35150. (a) (1) The governing board of a school district shall not take action to terminate a superintendent or assistant superintendent of the school district, or both, without cause, at a special or emergency meeting of the governing board. (2) The governing board of a school district may hold a regular meeting pursuant to Section 54954 of the Government Code for the purpose of terminating a superintendent or assistant superintendent of the school district, or both, without cause, during any month in which a regular meeting of the governing board is not scheduled. (b) The governing board of a school district shall not terminate a superintendent or assistant superintendent of the school district, or both, without cause, within 30 days after the first convening of the governing board after an election at which one or more members of the governing board are elected or recalled.

---
snapshot_id: fb096408-6d38-5f00-8e18-dd8112f26518
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB580

Bill Text - SB-580 Attorney General: immigration enforcement policies. skip to content home accessibility FAQ feedback sitemap login x Quick Search: Bill Number Bill Keyword Home Bill Information California Law Publications Other Resources My Subscriptions My Favorites Bill Information >> Bill Search >> Text Bill Text Bill Information PDF2 Bill PDF | Add To My Favorites | Track Bill | Version: 10/12/25 - Chaptered 09/13/25 - Enrolled 09/04/25 - Amended Assembly 09/02/25 - Amended Assembly 06/16/25 - Amended Assembly 05/23/25 - Amended Senate 03/26/25 - Amended Senate 02/20/25 - Introduced SB-580 Attorney General: immigration enforcement policies. (2025-2026) Text >> Votes >> History >> Bill Analysis >> Today's Law As Amended >> Compare Versions >> Status >> Comments To Author >> Track Bill >> Add To My Favorites >> SHARE THIS: Date Published: 10/13/2025 02:00 PM SB580:v92#DOCUMENT Bill Start Senate Bill No. 580 CHAPTER 670 An act to add Section 12532.5 to the Government Code, relating to state government. [ Approved by Governor October 12, 2025. Filed with Secretary of State October 12, 2025. ] LEGISLATIVE COUNSEL'S DIGEST SB 580, Durazo. Attorney General: immigration enforcement policies. Existing law requires the Attorney General to develop model policies limiting assistance with immigration enforcement to the fullest extent possible consistent with federal and state law at public schools, public libraries, courthouses, specified health facilities, shelters, and other specified state agencies. This bill would similarly require the Attorney General, on or before July 1, 2026, and in consultation with appropriate stakeholders, to publish model policies relating to interaction with immigration enforcement, consistent with federal and state law, and to publish guidance and recommendations for databases operated by state and local agencies to limit the availability of information in those databases for the purposes of immigration enforcement, consistent with federal and state law. The bill would require state and local agencies to implement the model policies on or before January 1, 2027, as specified. By imposing new duties on local agencies, this bill would impose a state-mandated local program. The bill would include findings that changes proposed by this bill address a matter of statewide concern rather than a municipal affair and, therefore, apply to all cities, including charter cities. The California Constitution requires the state to reimburse local agencies and school districts for certain costs mandated by the state. Statutory provisions establish procedures for making that reimbursement. This bill would provide that, if the Commission on State Mandates determines that the bill contains costs mandated by the state, reimbursement for those costs shall be made pursuant to the statutory provisions noted above. Digest Key Vote: MAJORITY Appropriation: NO Fiscal Committee: YES Local Program: YES Bill Text The people of the State of California do enact as follows: SECTION 1. Section 12532.5 is added to the Government Code, to read: 12532.5. (a) (1) On or before July 1, 2026, in consultation with appropriate stakeholders, the Attorney General shall publish model policies for state and local agencies relating to interaction with immigration authorities consistent with federal and state law. (2) On or before January 1, 2027, a state or local agency shall implement the model policy or an equivalent policy. (b) On or before July 1, 2026, in consultation with appropriate stakeholders, the Attorney General shall publish guidance, audit criteria, and training recommendations for databases operated by a state or local agency, including databases maintained for the agency by private vendors, aimed at ensuring that the databases are governed in a manner that makes the availability of information therein to anyone or any entity for the purposes of immigration enforcement limited to the fullest extent practicable, consistent with federal and state law. (c) A rule, policy, or standard of general application issued by the Attorney General pursuant to this section shall not be subject to the requirements of Chapter 3.5 (commencing with Section 11340) of Part 1. SEC. 2. The Legislature finds and declares all of the following: (a) Immigrants are valuable and essential members of the California community and indiscriminate immigration enforcement against persons who do not pose a public safety risk to Californians has a significant negative impact on state and local functions. Increased immigration enforcement activity in California, including in the workplace and schools, has been detrimental to the health and welfare of California’s residents. (b) The California Constitution confers an inalienable right to privacy for all Californians. This right to privacy protects the personal, private information of individuals. (c) A relationship of trust between California’s immigrant community and state and local agencies is central to the functioning of the state’s government and the public safety, health, welfare, and constitutional rights of the people of California. (d) Protecting the state’s limited public resources from being used for federal immigration enforcement actions is a matter of statewide concern and is not a municipal affair as that term is used in Section 5 of Article XI of the California Constitution. Therefore, Section 1 of this act adding Section 12532.5 to the Government Code applies to all cities, including charter cities. SEC. 3. The provisions of this act are severable. If any provision of this act or its application is held invalid, that invalidity shall not affect other provisions or applications that can be given effect without the invalid provision or application. SEC. 4. If the Commission on State Mandates determines that this act contains costs mandated by the state, reimbursement to local agencies and school districts for those costs shall be made pursuant to Part 7 (commencing with Section 17500) of Division 4 of Title 2 of the Government Code.

---
snapshot_id: 30fe75c6-6bbf-5a1a-af89-e68e532dde5c
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1955

Bill Text - AB-1955 Support Academic Futures and Educators for Today’s Youth Act. skip to content home accessibility FAQ feedback sitemap login x Quick Search: Bill Number Bill Keyword Home Bill Information California Law Publications Other Resources My Subscriptions My Favorites Bill Information >> Bill Search >> Text Bill Text Bill Information PDF2 Bill PDF | Add To My Favorites | Version: 07/15/24 - Chaptered 07/01/24 - Enrolled 05/22/24 - Amended Senate 01/29/24 - Introduced AB-1955 Support Academic Futures and Educators for Today’s Youth Act. (2023-2024) Text >> Votes >> History >> Bill Analysis >> Today's Law As Amended >> Compare Versions >> Status >> Comments To Author >> Add To My Favorites >> SHARE THIS: Date Published: 07/15/2024 09:00 PM AB1955:v96#DOCUMENT Bill Start Assembly Bill No. 1955 CHAPTER 95 An act to add Sections 220.1, 220.3, and 220.5 to, and to add Article 2.6 (commencing with Section 217) to Chapter 2 of Part 1 of Division 1 of Title 1 of, the Education Code, relating to pupil rights. [ Approved by Governor July 15, 2024. Filed with Secretary of State July 15, 2024. ] LEGISLATIVE COUNSEL'S DIGEST AB 1955, Ward. Support Academic Futures and Educators for Today’s Youth Act. (1) Existing law requires the State Department of Education to develop resources or, as appropriate, update existing resources for in-service training on schoolsite and community resources for the support of lesbian, gay, bisexual, transgender, queer, and questioning (LGBTQ) pupils, and strategies to increase support for LGBTQ pupils, as specified. This bill would require the State Department of Education to develop resources or, as appropriate, update existing resources, for supports and community resources for the support of parents, guardians, and families of LGBTQ pupils and strategies to increase support for LGBTQ pupils, as specified. (2) Existing law prohibits discrimination on the basis of, among other characteristics, gender, gender identity, gender expression, and sexual orientation in any program or activity conducted by an educational institution that receives, or benefits from, state financial assistance, or enrolls pupils who receive state student financial aid. Existing law requires the State Board of Education to adopt regulations to implement these provisions. This bill would prohibit school districts, county offices of education, charter schools, and the state special schools, and a member of the governing board or body of those educational entities, from enacting or enforcing any policy, rule, or administrative regulation that requires an employee or a contractor to disclose any information related to a pupil’s sexual orientation, gender identity, or gender expression to any other person without the pupil’s consent unless otherwise required by law, as provided. The bill would prohibit employees or contractors of those educational entities from being required to make such a disclosure unless otherwise required by law, as provided. The bill would prohibit employees or contractors of school districts, county offices of education, charter schools, or the state special schools, or members of the governing boards or bodies of those educational entities, from retaliating or taking adverse action against an employee on the basis that the employee supported a pupil in the exercise of specified rights, work activities, or providing certain instruction, as provided. Digest Key Vote: MAJORITY Appropriation: NO Fiscal Committee: YES Local Program: NO Bill Text The people of the State of California do enact as follows: SECTION 1. This act shall be known, and may be cited, as the Support Academic Futures and Educators for Today’s Youth Act or SAFETY Act. SEC. 2. The Legislature finds and declares all of the following: (a) All pupils deserve to feel safe, supported, and affirmed for who they are at school. (b) Choosing when to “come out” by disclosing an LGBTQ+ identity, and to whom, are deeply personal decisions, impacting health and safety as well as critical relationships, that every LGBTQ+ person has the right to make for themselves. (c) Parents and families across California understand that coming out as LGBTQ+ is an extremely personal decision and want to support their children in coming out to them on their own terms. (d) Parents and families have an important role to play in the lives of young people. Studies confirm that LGBTQ+ youth thrive when they have parental support and feel safe sharing their full identities with them, but it can be harmful to force young people to share their full identities before they are ready. (e) Policies that forcibly “out” pupils without their consent remove opportunities for LGBTQ+ young people and their families to build trust and have these conversations when they are ready. (f) LGBTQ+ pupils have the right to express themselves freely at school without fear, punishment, or retaliation, including that teachers or administrators might “out” them without their permission. Policies that require outing pupils without their consent violate pupils’ rights to privacy and self-determination. (g) Pupils have a constitutional right to privacy when it comes to sensitive information about them, and courts have affirmed that young people have a right to keep personal information private. (h) Laws and policies that target or invite targeting of pupils on the basis of gender or sexual orientation are prohibited under state and federal law. (i) Attacks on the rights, safety, and dignity of transgender, gender-expansive, and other LGBTQ+ youth continue to grow across the country, including here in California. These efforts are having a measurable impact on the health and well-being of LGBTQ+ pupils, and have led to a rise in bullying, harassment, and discrimination. (j) School policies that support LGBTQ+ pupils and their parents and families in working towards family acceptance on their own terms, without interference from teachers and school staff, build safety and trust within school communities. (k) (1) Teachers and school staff can provide crucial support to LGBTQ+ young people and can play an important role in encouraging them to seek out appropriate resources and support. (2) Affirming school environments significantly reduce the odds of transgender youth attempting suicide, according to The Trevor Project Research Brief: LGBTQ & Gender-Affirming Spaces (2020). (3) LGBTQ+ students with supportive staff at their school experienced a number of positive outcomes, including being less likely to feel unsafe at school because of their gender expression or sexual orientation, or both, and reporting lower levels of depression, according to Joseph G. Kosciw, Ph.D., et al., The 2019 National School Climate Survey: The Experiences of Lesbian, Gay, Bisexual, Transgender, and Queer Youth in Our Nation’s Schools (2019). (4) Transgender and gender-nonconforming youth with supportive educators had better education outcomes, according to Michelle Marie Johns et al., Protective Factors Among Transgender and Gender Variant Youth: A Systematic Review by Socioecological Level (2018). (l) School personnel have faced increasing harassment and adverse employment actions because of their lawful efforts to protect pupil privacy, to protect pupils from discrimination, to provide instruction consistent with state standards, and to create a safe and supportive learning environment for all pupils, including LGBTQ+ pupils. (m) This harassment and adverse treatment of school personnel prevents all pupils from accessing safe and supportive learning environments. (n) No school employee should suffer an adverse employment action because the employee supported a pupil or pupils in exercising their legal rights to privacy, nondiscrimination, state-aligned instructional materials, and equal educational opportunity. SEC. 3. Article 2.6 (commencing with Section 217) is added to Chapter 2 of Part 1 of Division 1 of Title 1 of the Education Code, to read: Article 2.6. Supports and Resources for Parents, Guardians, and Families of Lesbian, Gay, Bisexual, Transgender, Queer, and Questioning Pupils 217. (a) (1) The department shall develop resources, or, as appropriate, update existing resources, for supports and community resources for the support of parents, guardians, and families of lesbian, gay, bisexual, transgender, queer, and questioning (LGBTQ) pupils and strategies to increase support for LGBTQ pupils and thereby improve overall school and community climate. The resources shall be designed for use in schools operated by a school district or county office of education and charter schools serving pupils in grades 7 to 12, inclusive. (2) The department shall develop the supports and community resources for parents, guardians, and families of LGBTQ pupils in collaboration with parents, guardians, and families of, including, but not limited to, LGBTQ pupils. (b) The department shall periodically update the supports and community resources for the support of parents, guardians, and families of LGBTQ pupils to reflect changes in law. (c) (1) As used in this section, school-based supports and community resources for the support of parents, guardians, and families of LGBTQ pupils include, but are not limited to, all of the following: (A) Parents, guardians, and families of LGBTQ pupils support groups or affinity clubs and organizations. (B) Safe spaces for parents, guardians, and families of LGBTQ pupils. (C) Antibullying and harassment policies and related complaint procedures for parents, guardians, and families to access. (D) Counseling services. (E) School staff who have received antibias or other training aimed at supporting LGBTQ youth and their parents, guardians, and families. (F) Suicide prevention policies and related procedures for parents, guardians, and families to access. (2) As used in this section, community resources for the support of parents, guardians, and families of LGBTQ pupils include, but are not limited to, both of the following: (A) Local community-based organizations that provide support to parents, guardians, and families of LGBTQ youth. (B) Local physical and mental health providers with experience in treating and supporting parents, families, and guardians of LGBTQ youth. SEC. 4. Section 220.1 is added to the Education Code, to read: 220.1. An employee or a contractor of a school district, county office of education, charter school, or state special school for the blind or the deaf, or a member of the governing board of a school district or county office of education or a member of the governing body of a charter school, shall not in any manner retaliate or take adverse action against any employee, including by placing the employee on administrative leave, on the basis that the employee (a) supported a pupil in the exercise of rights set forth in Article 1 (commencing with Section 200) of, Article 2.7 (commencing with Section 218) of, Article 3 (commencing with Section 220) of, or Article 4 (commencing with Section 221.5) of, this chapter, (b) performed the employee’s work activities in a manner consistent with the recommendations or employer obligations set forth in this chapter, or (c) provided instruction to pupils consistent with the current content standards, curriculum frameworks, and instructional materials adopted by the state board, and any other requirements of this code, including, but not limited to, Section 51204.5 and the California Healthy Youth Act (Chapter 5.6 (commencing with Section 51930) of Part 28 of Division 4 of Title 2). SEC. 5. Section 220.3 is added to the Education Code, to read: 220.3. (a) An employee or a contractor of a school district, county office of education, charter school, or state special school for the blind or the deaf shall not be required to disclose any information related to a pupil’s sexual orientation, gender identity, or gender expression to any other person without the pupil’s consent unless otherwise required by state or federal law. (b) Subdivision (a) does not constitute a change in, but is declaratory of, existing law. SEC. 6. Section 220.5 is added to the Education Code, to read: 220.5. (a) A school district, county office of education, charter school, state special school for the blind or the deaf, or a member of the governing board of a school district or county office of education or a member of the governing body of a charter school, shall not enact or enforce any policy, rule, or administrative regulation that would require an employee or a contractor to disclose any information related to a pupil’s sexual orientation, gender identity, or gender expression to any other person without the pupil’s consent, unless otherwise required by state or federal law. (b) Subdivision (a) does not constitute a change in, but is declaratory of, existing law. (c) Any policy, regulation, guidance, directive, or other action of a school district, county office of education, charter school, or state special school for the blind or the deaf, or a member of the governing board of a school district or county office of education or a member of the governing body of a charter school, that is inconsistent with subdivision (a) is invalid and shall not have any force or effect.

---
snapshot_id: 6c0d4012-fa54-5a1e-8a0c-213fd3bb8636
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB494

Bill Votes - SB-494 School district governing boards: meetings: school district superintendents and assistant superintendents: termination. (2023-2024) California Legislative Information || Date 09/13/23 Result (PASS) Location Senate Floor Ayes Count 32 Noes Count 7 NVR Count 1 Motion Unfinished Business SB494 Newman Concurrence Ayes Allen, Alvarado-Gil, Archuleta, Ashby, Atkins, Becker, Blakespear, Bradford, Cortese, Dodd, Durazo, Eggman, Glazer, Gonzalez, Hurtado, Laird, Limón, McGuire, Menjivar, Min, Newman, Ochoa Bogh, Padilla, Portantino, Roth, Rubio, Skinner, Smallwood-Cuevas, Stern, Umberg, Wahab, Wiener Noes Dahle, Grove, Jones, Nguyen, Niello, Seyarto, Wilk NVR Caballero || Date 05/15/23 Result (PASS) Location Senate Floor Ayes Count 32 Noes Count 6 NVR Count 2 Motion Senate 3rd Reading SB494 Newman Ayes Allen, Alvarado-Gil, Archuleta, Ashby, Atkins, Becker, Blakespear, Bradford, Caballero, Cortese, Dodd, Durazo, Eggman, Glazer, Gonzalez, Grove, Hurtado, Laird, Limón, McGuire, Menjivar, Min, Newman, Ochoa Bogh, Padilla, Portantino, Roth, Skinner, Stern, Umberg, Wahab, Wiener Noes Dahle, Jones, Nguyen, Niello, Seyarto, Wilk NVR Rubio, Smallwood-Cuevas Senate Floor vote blocks only. Saved by browser (robots-disallowed page) from leginfo.legislature.ca.gov billVotesClient on 2026-09-25.