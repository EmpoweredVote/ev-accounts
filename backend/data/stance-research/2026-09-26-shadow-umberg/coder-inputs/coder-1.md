You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-26-shadow-umberg/labels/coder-1.json. Write JSON only, matching
codebook Part E, with "codebook_version": "0.3" and "coder_slot": 1. One row per
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
- **Preemption (ruling Q10, 2026-09-26).** A law that forbids another level of government to act
  decides *which level* may set the rule, not *what* the rule is → `adjacent`, unless a rung is itself
  about which level decides.

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

politician_id: 712be98b-a05d-4605-9603-cd5d86abfad1  office_id: 9d4dce25-ba2b-4835-9490-4ef4bc69d4a5
Thomas Umberg — Senator, California (seated, level: state)
Current term: 2018-12-03 (precision: day) to present

## Topics (served ladder text — code against these words only)

### topic_key: housing
topic_id: 669cac97-66a6-4087-b036-936fbe62efb3  served_revision_id: 598c879d-f387-461c-9120-fbbbf6314bbc
Question: What role should government play in making sure people can afford housing?
  1. Make government the main provider — build and operate public housing so everyone is guaranteed a home.
  2. Build a large public housing sector that competes with the private market to hold prices down, while private housing stays the norm.
  3. Build no public housing, but set binding rules on the private market like rent caps or required affordable units.
  4. Set no binding rules, but offer subsidies and tax breaks so more affordable housing gets built.
  5. Rely on the market to set prices and supply — at most, cut the regulations and zoning limits that block private building.

#### Annex

(no annex for this topic yet — apply the codebook alone)

## Sources

---
snapshot_id: e45f22f9-8520-58a2-906f-039398c9ab04
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202120220SB9

Bill Text - SB-9 Housing development: approvals. skip to content home accessibility FAQ feedback sitemap login x Quick Search: Bill Number Bill Keyword Home Bill Information California Law Publications Other Resources My Subscriptions My Favorites Bill Information >> Bill Search >> Text Bill Text PDF2 Bill PDF | Add To My Favorites | Version: 09/16/21 - Chaptered 09/01/21 - Enrolled 08/16/21 - Amended Assembly 04/27/21 - Amended Senate 04/05/21 - Amended Senate 12/07/20 - Introduced SB-9 Housing development: approvals. (2021-2022) Text >> Votes >> History >> Bill Analysis >> Today's Law As Amended >> Compare Versions >> Status >> Comments To Author >> Add To My Favorites >> SHARE THIS: Date Published: 09/17/2021 09:00 PM SB9:v94#DOCUMENT Bill Start Senate Bill No. 9 CHAPTER 162 An act to amend Section 66452.6 of, and to add Sections 65852.21 and 66411.7 to, the Government Code, relating to land use. [ Approved by Governor September 16, 2021. Filed with Secretary of State September 16, 2021. ] LEGISLATIVE COUNSEL'S DIGEST SB 9, Atkins. Housing development: approvals. The Planning and Zoning Law provides for the creation of accessory dwelling units by local ordinance, or, if a local agency has not adopted an ordinance, by ministerial approval, in accordance with specified standards and conditions. This bill, among other things, would require a proposed housing development containing no more than 2 residential units within a single-family residential zone to be considered ministerially, without discretionary review or hearing, if the proposed housing development meets certain requirements, including, but not limited to, that the proposed housing development would not require demolition or alteration of housing that is subject to a recorded covenant, ordinance, or law that restricts rents to levels affordable to persons and families of moderate, low, or very low income, that the proposed housing development does not allow for the demolition of more than 25% of the existing exterior structural walls, except as provided, and that the development is not located within a historic district, is not included on the State Historic Resources Inventory, or is not within a site that is legally designated or listed as a city or county landmark or historic property or district. The bill would set forth what a local agency can and cannot require in approving the construction of 2 residential units, including, but not limited to, authorizing a local agency to impose objective zoning standards, objective subdivision standards, and objective design standards, as defined, unless those standards would have the effect of physically precluding the construction of up to 2 units or physically precluding either of the 2 units from being at least 800 square feet in floor area, prohibiting the imposition of setback requirements under certain circumstances, and setting maximum setback requirements under all other circumstances. The Subdivision Map Act vests the authority to regulate and control the design and improvement of subdivisions in the legislative body of a local agency and sets forth procedures governing the local agency’s processing, approval, conditional approval or disapproval, and filing of tentative, final, and parcel maps, and the modification of those maps. Under the Subdivision Map Act, an approved or conditionally approved tentative map expires 24 months after its approval or conditional approval or after any additional period of time as prescribed by local ordinance, not to exceed an additional 12 months, except as provided. This bill, among other things, would require a local agency to ministerially approve a parcel map for an urban lot split that meets certain requirements, including, but not limited to, that the urban lot split would not require the demolition or alteration of housing that is subject to a recorded covenant, ordinance, or law that restricts rents to levels affordable to persons and families of moderate, low, or very low income, that the parcel is located within a single-family residential zone, and that the parcel is not located within a historic district, is not included on the State Historic Resources Inventory, or is not within a site that is legally designated or listed as a city or county landmark or historic property or district. The bill would set forth what a local agency can and cannot require in approving an urban lot split, including, but not limited to, authorizing a local agency to impose objective zoning standards, objective subdivision standards, and objective design standards, as defined, unless those standards would have the effect of physically precluding the construction of 2 units, as defined, on either of the resulting parcels or physically precluding either of the 2 units from being at least 800 square feet in floor area, prohibiting the imposition of setback requirements under certain circumstances, and setting maximum setback requirements under all other circumstances. The bill would require an applicant to sign an affidavit stating that they intend to occupy one of the housing units as their principal residence for a minimum of 3 years from the date of the approval of the urban lot split, unless the applicant is a community land trust or a qualified nonprofit corporation, as specified. The bill would prohibit a local agency from imposing any additional owner occupancy standards on applicants. By requiring applicants to sign affidavits, thereby expanding the crime of perjury, the bill would impose a state-mandated local program. The bill would also extend the limit on the additional period that may be provided by ordinance, as described above, from 12 months to 24 months and would make other conforming or nonsubstantive changes. The California Environmental Quality Act (CEQA) requires a lead agency, as defined, to prepare, or cause to be prepared, and certify the completion of, an environmental impact report on a project that it proposes to carry out or approve that may have a significant effect on the environment. CEQA does not apply to the approval of ministerial projects. This bill, by establishing the ministerial review processes described above, would thereby exempt the approval of projects subject to those processes from CEQA. The California Coastal Act of 1976 provides for the planning and regulation of development, under a coastal development permit process, within the coastal zone, as defined, that shall be based on various coastal resources planning and management policies set forth in the act. This bill would exempt a local agency from being required to hold public hearings for coastal development permit applications for housing developments and urban lot splits pursuant to the above provisions. By increasing the duties of local agencies with respect to land use regulations, the bill would impose a state-mandated local program. The bill would include findings that changes proposed by this bill address a matter of statewide concern rather than a municipal affair and, therefore, apply to all cities, including charter cities. The California Constitution requires the state to reimburse local agencies and school districts for certain costs mandated by the state. Statutory provisions establish procedures for making that reimbursement. This bill would provide that no reimbursement is required by this act for specified reasons. Digest Key Vote: MAJORITY Appropriation: NO Fiscal Committee: YES Local Program: YES Bill Text The people of the State of California do enact as follows: SECTION 1. Section 65852.21 is added to the Government Code, to read: 65852.21. (a) A proposed housing development containing no more than two residential units within a single-family residential zone shall be considered ministerially, without discretionary review or a hearing, if the proposed housing development meets all of the following requirements: (1) The parcel subject to the proposed housing development is located within a city, the boundaries of which include some portion of either an urbanized area or urban cluster, as designated by the United States Census Bureau, or, for unincorporated areas, a legal parcel wholly within the boundaries of an urbanized area or urban cluster, as designated by the United States Census Bureau. (2) The parcel satisfies the requirements specified in subparagraphs (B) to (K), inclusive, of paragraph (6) of subdivision (a) of Section 65913.4. (3) Notwithstanding any provision of this section or any local law, the proposed housing development would not require demolition or alteration of any of the following types of housing: (A) Housing that is subject to a recorded covenant, ordinance, or law that restricts rents to levels affordable to persons and families of moderate, low, or very low income. (B) Housing that is subject to any form of rent or price control through a public entity’s valid exercise of its police power. (C) Housing that has been occupied by a tenant in the last three years. (4) The parcel subject to the proposed housing development is not a parcel on which an owner of residential real property has exercised the owner’s rights under Chapter 12.75 (commencing with Section 7060) of Division 7 of Title 1 to withdraw accommodations from rent or lease within 15 years before the date that the development proponent submits an application. (5) The proposed housing development does not allow the demolition of more than 25 percent of the existing exterior structural walls, unless the housing development meets at least one of the following conditions: (A) If a local ordinance so allows. (B) The site has not been occupied by a tenant in the last three years. (6) The development is not located within a historic district or property included on the State Historic Resources Inventory, as defined in Section 5020.1 of the Public Resources Code, or within a site that is designated or listed as a city or county landmark or historic property or district pursuant to a city or county ordinance. (b) (1) Notwithstanding any local law and except as provided in paragraph (2), a local agency may impose objective zoning standards, objective subdivision standards, and objective design review standards that do not conflict with this section. (2) (A) The local agency shall not impose objective zoning standards, objective subdivision standards, and objective design standards that would have the effect of physically precluding the construction of up to two units or that would physically preclude either of the two units from being at least 800 square feet in floor area. (B) (i) Notwithstanding subparagraph (A), no setback shall be required for an existing structure or a structure constructed in the same location and to the same dimensions as an existing structure. (ii) Notwithstanding subparagraph (A), in all other circumstances not described in clause (i), a local agency may require a setback of up to four feet from the side and rear lot lines. (c) In addition to any conditions established in accordance with subdivision (b), a local agency may require any of the following conditions when considering an application for two residential units as provided for in this section: (1) Off-street parking of up to one space per unit, except that a local agency shall not impose parking requirements in either of the following instances: (A) The parcel is located within one-half mile walking distance of either a high-quality transit corridor, as defined in subdivision (b) of Section 21155 of the Public Resources Code, or a major transit stop, as defined in Section 21064.3 of the Public Resources Code. (B) There is a car share vehicle located within one block of the parcel. (2) For residential units connected to an onsite wastewater treatment system, a percolation test completed within the last 5 years, or, if the percolation test has been recertified, within the last 10 years. (d) Notwithstanding subdivision (a), a local agency may deny a proposed housing development project if the building official makes a written finding, based upon a preponderance of the evidence, that the proposed housing development project would have a specific, adverse impact, as defined and determined in paragraph (2) of subdivision (d) of Section 65589.5, upon public health and safety or the physical environment and for which there is no feasible method to satisfactorily mitigate or avoid the specific, adverse impact. (e) A local agency shall require that a rental of any unit created pursuant to this section be for a term longer than 30 days. (f) Notwithstanding Section 65852.2 or 65852.22, a local agency shall not be required to permit an accessory dwelling unit or a junior accessory dwelling unit on parcels that use both the authority contained within this section and the authority contained in Section 66411.7. (g) Notwithstanding subparagraph (B) of paragraph (2) of subdivision (b), an application shall not be rejected solely because it proposes adjacent or connected structures provided that the structures meet building code safety standards and are sufficient to allow separate conveyance. (h) Local agencies shall include units constructed pursuant to this section in the annual housing element report as required by subparagraph (I) of paragraph (2) of subdivision (a) of Section 65400. (i) For purposes of this section, all of the following apply: (1) A housing development contains two residential units if the development proposes no more than two new units or if it proposes to add one new unit to one existing unit. (2) The terms “objective zoning standards,” “objective subdivision standards,” and “objective design review standards” mean standards that involve no personal or subjective judgment by a public official and are uniformly verifiable by reference to an external and uniform benchmark or criterion available and knowable by both the development applicant or proponent and the public official prior to submittal. These standards may be embodied in alternative objective land use specifications adopted by a local agency, and may include, but are not limited to, housing overlay zones, specific plans, inclusionary zoning ordinances, and density bonus ordinances. (3) “Local agency” means a city, county, or city and county, whether general law or chartered. (j) A local agency may adopt an ordinance to implement the provisions of this section. An ordinance adopted to implement this section shall not be considered a project under Division 13 (commencing with Section 21000) of the Public Resources Code. (k) Nothing in this section shall be construed to supersede or in any way alter or lessen the effect or application of the California Coastal Act of 1976 (Division 20 (commencing with Section 30000) of the Public Resources Code), except that the local agency shall not be required to hold public hearings for coastal development permit applications for a housing development pursuant to this section. SEC. 2. Section 66411.7 is added to the Government Code, to read: 66411.7. (a) Notwithstanding any other provision of this division and any local law, a local agency shall ministerially approve, as set forth in this section, a parcel map for an urban lot split only if the local agency determines that the parcel map for the urban lot split meets all the following requirements: (1) The parcel map subdivides an existing parcel to create no more than two new parcels of approximately equal lot area provided that one parcel shall not be smaller than 40 percent of the lot area of the original parcel proposed for subdivision. (2) (A) Except as provided in subparagraph (B), both newly created parcels are no smaller than 1,200 square feet. (B) A local agency may by ordinance adopt a smaller minimum lot size subject to ministerial approval under this subdivision. (3) The parcel being subdivided meets all the following requirements: (A) The parcel is located within a single-family residential zone. (B) The parcel subject to the proposed urban lot split is located within a city, the boundaries of which include some portion of either an urbanized area or urban cluster, as designated by the United States Census Bureau, or, for unincorporated areas, a legal parcel wholly within the boundaries of an urbanized area or urban cluster, as designated by the United States Census Bureau. (C) The parcel satisfies the requirements specified in subparagraphs (B) to (K), inclusive, of paragraph (6) of subdivision (a) of Section 65913.4. (D) The proposed urban lot split would not require demolition or alteration of any of the following types of housing: (i) Housing that is subject to a recorded covenant, ordinance, or law that restricts rents to levels affordable to persons and families of moderate, low, or very low income. (ii) Housing that is subject to any form of rent or price control through a public entity’s valid exercise of its police power. (iii) A parcel or parcels on which an owner of residential real property has exercised the owner’s rights under Chapter 12.75 (commencing with Section 7060) of Division 7 of Title 1 to withdraw accommodations from rent or lease within 15 years before the date that the development proponent submits an application. (iv) Housing that has been occupied by a tenant in the last three years. (E) The parcel is not located within a historic district or property included on the State Historic Resources Inventory, as defined in Section 5020.1 of the Public Resources Code, or within a site that is designated or listed as a city or county landmark or historic property or district pursuant to a city or county ordinance. (F) The parcel has not been established through prior exercise of an urban lot split as provided for in this section. (G) Neither the owner of the parcel being subdivided nor any person acting in concert with the owner has previously subdivided an adjacent parcel using an urban lot split as provided for in this section. (b) An application for a parcel map for an urban lot split shall be approved in accordance with the following requirements: (1) A local agency shall approve or deny an application for a parcel map for an urban lot split ministerially without discretionary review. (2) A local agency shall approve an urban lot split only if it conforms to all applicable objective requirements of the Subdivision Map Act (Division 2 (commencing with Section 66410)), except as otherwise expressly provided in this section. (3) Notwithstanding Section 66411.1, a local agency shall not impose regulations that require dedications of rights-of-way or the construction of offsite improvements for the parcels being created as a condition of issuing a parcel map for an urban lot split pursuant to this section. (c) (1) Except as provided in paragraph (2), notwithstanding any local law, a local agency may impose objective zoning standards, objective subdivision standards, and objective design review standards applicable to a parcel created by an urban lot split that do not conflict with this section. (2) A local agency shall not impose objective zoning standards, objective subdivision standards, and objective design review standards that would have the effect of physically precluding the construction of two units on either of the resulting parcels or that would result in a unit size of less than 800 square feet. (3) (A) Notwithstanding paragraph (2), no setback shall be required for an existing structure or a structure constructed in the same location and to the same dimensions as an existing structure. (B) Notwithstanding paragraph (2), in all other circumstances not described in subparagraph (A), a local agency may require a setback of up to four feet from the side and rear lot lines. (d) Notwithstanding subdivision (a), a local agency may deny an urban lot split if the building official makes a written finding, based upon a preponderance of the evidence, that the proposed housing development project would have a specific, adverse impact, as defined and determined in paragraph (2) of subdivision (d) of Section 65589.5, upon public health and safety or the physical environment and for which there is no feasible method to satisfactorily mitigate or avoid the specific, adverse impact. (e) In addition to any conditions established in accordance with this section, a local agency may require any of the following conditions when considering an application for a parcel map for an urban lot split: (1) Easements required for the provision of public services and facilities. (2) A requirement that the parcels have access to, provide access to, or adjoin the public right-of-way. (3) Off-street parking of up to one space per unit, except that a local agency shall not impose parking requirements in either of the following instances: (A) The parcel is located within one-half mile walking distance of either a high-quality transit corridor as defined in subdivision (b) of Section 21155 of the Public Resources Code, or a major transit stop as defined in Section 21064.3 of the Public Resources Code. (B) There is a car share vehicle located within one block of the parcel. (f) A local agency shall require that the uses allowed on a lot created by this section be limited to residential uses. (g) (1) A local agency shall require an applicant for an urban lot split to sign an affidavit stating that the applicant intends to occupy one of the housing units as their principal residence for a minimum of three years from the date of the approval of the urban lot split. (2) This subdivision shall not apply to an applicant that is a “community land trust,” as defined in clause (ii) of subparagraph (C) of paragraph (11) of subdivision (a) of Section 402.1 of the Revenue and Taxation Code, or is a “qualified nonprofit corporation” as described in Section 214.15 of the Revenue and Taxation Code. (3) A local agency shall not impose additional owner occupancy standards, other than provided for in this subdivision, on an urban lot split pursuant to this section. (h) A local agency shall require that a rental of any unit created pursuant to this section be for a term longer than 30 days. (i) A local agency shall not require, as a condition for ministerial approval of a parcel map application for the creation of an urban lot split, the correction of nonconforming zoning conditions. (j) (1) Notwithstanding any provision of Section 65852.2, 65852.21, 65852.22, 65915, or this section, a local agency shall not be required to permit more than two units on a parcel created through the exercise of the authority contained within this section. (2) For the purposes of this section, “unit” means any dwelling unit, including, but not limited to, a unit or units created pursuant to Section 65852.21, a primary dwelling, an accessory dwelling unit as defined in Section 65852.2, or a junior accessory dwelling unit as defined in Section 65852.22. (k) Notwithstanding paragraph (3) of subdivision (c), an application shall not be rejected solely because it proposes adjacent or connected structures provided that the structures meet building code safety standards and are sufficient to allow separate conveyance. (l) Local agencies shall include the number of applications for parcel maps for urban lot splits pursuant to this section in the annual housing element report as required by subparagraph (I) of paragraph (2) of subdivision (a) of Section 65400. (m) For purposes of this section, both of the following shall apply: (1) “Objective zoning standards,” “objective subdivision standards,” and “objective design review standards” mean standards that involve no personal or subjective judgment by a public official and are uniformly verifiable by reference to an external and uniform benchmark or criterion available and knowable by both the development applicant or proponent and the public official prior to submittal. These standards may be embodied in alternative objective land use specifications adopted by a local agency, and may include, but are not limited to, housing overlay zones, specific plans, inclusionary zoning ordinances, and density bonus ordinances. (2) “Local agency” means a city, county, or city and county, whether general law or chartered. (n) A local agency may adopt an ordinance to implement the provisions of this section. An ordinance adopted to implement this section shall not be considered a project under Division 13 (commencing with Section 21000) of the Public Resources Code. (o) Nothing in this section shall be construed to supersede or in any way alter or lessen the effect or application of the California Coastal Act of 1976 (Division 20 (commencing with Section 30000) of the Public Resources Code), except that the local agency shall not be required to hold public hearings for coastal development permit applications for urban lot splits pursuant to this section. SEC. 3. Section 66452.6 of the Government Code is amended to read: 66452.6. (a) (1) An approved or conditionally approved tentative map shall expire 24 months after its approval or conditional approval, or after any additional period of time as may be prescribed by local ordinance, not to exceed an additional 24 months. However, if the subdivider is required to expend two hundred thirty-six thousand seven hundred ninety dollars ($236,790) or more to construct, improve, or finance the construction or improvement of public improvements outside the property boundaries of the tentative map, excluding improvements of public rights-of-way that abut the boundary of the property to be subdivided and that are reasonably related to the development of that property, each filing of a final map authorized by Section 66456.1 shall extend the expiration of the approved or conditionally approved tentative map by 48 months from the date of its expiration, as provided in this section, or the date of the previously filed final map, whichever is later. The extensions shall not extend the tentative map more than 10 years from its approval or conditional approval. However, a tentative map on property subject to a development agreement authorized by Article 2.5 (commencing with Section 65864) of Chapter 4 of Division 1 may be extended for the period of time provided for in the agreement, but not beyond the duration of the agreement. The number of phased final maps that may be filed shall be determined by the advisory agency at the time of the approval or conditional approval of the tentative map. (2) Commencing January 1, 2012, and each calendar year thereafter, the amount of two hundred thirty-six thousand seven hundred ninety dollars ($236,790) shall be annually increased by operation of law according to the adjustment for inflation set forth in the statewide cost index for class B construction, as determined by the State Allocation Board at its January meeting. The effective date of each annual adjustment shall be March 1. The adjusted amount shall apply to tentative and vesting tentative maps whose applications were received after the effective date of the adjustment. (3) “Public improvements,” as used in this subdivision, include traffic controls, streets, roads, highways, freeways, bridges, overcrossings, street interchanges, flood control or storm drain facilities, sewer facilities, water facilities, and lighting facilities. (b) (1) The period of time specified in subdivision (a), including any extension thereof granted pursuant to subdivision (e), shall not include any period of time during which a development moratorium, imposed after approval of the tentative map, is in existence. However, the length of the moratorium shall not exceed five years. (2) The length of time specified in paragraph (1) shall be extended for up to three years, but in no event beyond January 1, 1992, during the pendency of any lawsuit in which the subdivider asserts, and the local agency that approved or conditionally approved the tentative map denies, the existence or application of a development moratorium to the tentative map. (3) Once a development moratorium is terminated, the map shall be valid for the same period of time as was left to run on the map at the time that the moratorium was imposed. However, if the remaining time is less than 120 days, the map shall be valid for 120 days following the termination of the moratorium. (c) The period of time specified in subdivision (a), including any extension thereof granted pursuant to subdivision (e), shall not include the period of time during which a lawsuit involving the approval or conditional approval of the tentative map is or was pending in a court of competent jurisdiction, if the stay of the time period is approved by the local agency pursuant to this section. After service of the initial petition or complaint in the lawsuit upon the local agency, the subdivider may apply to the local agency for a stay pursuant to the local agency’s adopted procedures. Within 40 days after receiving the application, the local agency shall either stay the time period for up to five years or deny the requested stay. The local agency may, by ordinance, establish procedures for reviewing the requests, including, but not limited to, notice and hearing requirements, appeal procedures, and other administrative requirements. (d) The expiration of the approved or conditionally approved tentative map shall terminate all proceedings and no final map or parcel map of all or any portion of the real property included within the tentative map shall be filed with the legislative body without first processing a new tentative map. Once a timely filing is made, subsequent actions of the local agency, including, but not limited to, processing, approving, and recording, may lawfully occur after the date of expiration of the tentative map. Delivery to the county surveyor or city engineer shall be deemed a timely filing for purposes of this section. (e) Upon application of the subdivider filed before the expiration of the approved or conditionally approved tentative map, the time at which the map expires pursuant to subdivision (a) may be extended by the legislative body or by an advisory agency authorized to approve or conditionally approve tentative maps for a period or periods not exceeding a total of six years. The period of extension specified in this subdivision shall be in addition to the period of time provided by subdivision (a). Before the expiration of an approved or conditionally approved tentative map, upon an application by the subdivider to extend that map, the map shall automatically be extended for 60 days or until the application for the extension is approved, conditionally approved, or denied, whichever occurs first. If the advisory agency denies a subdivider’s application for an extension, the subdivider may appeal to the legislative body within 15 days after the advisory agency has denied the extension. (f) For purposes of this section, a development moratorium includes a water or sewer moratorium, or a water and sewer moratorium, as well as other actions of public agencies that regulate land use, development, or the provision of services to the land, including the public agency with the authority to approve or conditionally approve the tentative map, which thereafter prevents, prohibits, or delays the approval of a final or parcel map. A development moratorium shall also be deemed to exist for purposes of this section for any period of time during which a condition imposed by the city or county could not be satisfied because of either of the following: (1) The condition was one that, by its nature, necessitated action by the city or county, and the city or county either did not take the necessary action or by its own action or inaction was prevented or delayed in taking the necessary action before expiration of the tentative map. (2) The condition necessitates acquisition of real property or any interest in real property from a public agency, other than the city or county that approved or conditionally approved the tentative map, and that other public agency fails or refuses to convey the property interest necessary to satisfy the condition. However, nothing in this subdivision shall be construed to require any public agency to convey any interest in real property owned by it. A development moratorium specified in this paragraph shall be deemed to have been imposed either on the date of approval or conditional approval of the tentative map, if evidence was included in the public record that the public agency that owns or controls the real property or any interest therein may refuse to convey that property or interest, or on the date that the public agency that owns or controls the real property or any interest therein receives an offer by the subdivider to purchase that property or interest for fair market value, whichever is later. A development moratorium specified in this paragraph shall extend the tentative map up to the maximum period as set forth in subdivision (b), but not later than January 1, 1992, so long as the public agency that owns or controls the real property or any interest therein fails or refuses to convey the necessary property interest, regardless of the reason for the failure or refusal, except that the development moratorium shall be deemed to terminate 60 days after the public agency has officially made, and communicated to the subdivider, a written offer or commitment binding on the agency to convey the necessary property interest for a fair market value, paid in a reasonable time and manner. SEC. 4. The Legislature finds and declares that ensuring access to affordable housing is a matter of statewide concern and not a municipal affair as that term is used in Section 5 of Article XI of the California Constitution. Therefore, Sections 1 and 2 of this act adding Sections 65852.21 and 66411.7 to the Government Code and Section 3 of this act amending Section 66452.6 of the Government Code apply to all cities, including charter cities. SEC. 5. No reimbursement is required by this act pursuant to Section 6 of Article XIII B of the California Constitution because a local agency or school district has the authority to levy service charges, fees, or assessments sufficient to pay for the program or level of service mandated by this act or because costs that may be incurred by a local agency or school district will be incurred because this act creates a new crime or infraction, eliminates a crime or infraction, or changes the penalty for a crime or infraction, within the meaning of Section 17556 of the Government Code, or changes the definition of a crime within the meaning of Section 6 of Article XIII B of the California Constitution.

---
snapshot_id: 7202f411-4253-5329-9387-677d15265e79
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB9

Bill Votes - SB-9 Housing development: approvals. California Legislative Information || Date 08/30/21 Result (PASS) Location Senate Floor Ayes Count 28 Noes Count 7 NVR Count 5 Motion Unfinished Business SB9 Atkins et al. Concurrence Ayes Archuleta, Atkins, Becker, Bradford, Caballero, Cortese, Dahle, Dodd, Durazo, Eggman, Gonzalez, Grove, Hertzberg, Hueso, Hurtado, Laird, Leyva, McGuire, Min, Nielsen, Pan, Portantino, Roth, Rubio, Skinner, Umberg, Wieckowski, Wiener Noes Bates, Borgeas, Glazer, Jones, Melendez, Ochoa Bogh, Wilk NVR Allen, Kamlager, Limón, Newman, Stern Bill Votes || Date 05/26/21 Result (PASS) Location Senate Floor Ayes Count 28 Noes Count 6 NVR Count 6 Motion Senate 3rd Reading SB9 Atkins et al. Ayes Archuleta, Atkins, Becker, Bradford, Caballero, Cortese, Dahle, Dodd, Durazo, Eggman, Gonzalez, Grove, Hertzberg, Hueso, Hurtado, Laird, Leyva, McGuire, Min, Nielsen, Pan, Portantino, Roth, Rubio, Skinner, Umberg, Wieckowski, Wiener Noes Bates, Borgeas, Jones, Melendez, Ochoa Bogh, Wilk NVR Allen, Glazer, Kamlager, Limón, Newman, Stern Bill Votes Senate Floor vote blocks only. Saved by browser (robots-disallowed page) from leginfo.legislature.ca.gov billVotesClient on 2026-09-26.