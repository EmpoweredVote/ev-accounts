You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-27-shadow-teshka/labels/coder-2.json. Write JSON only, matching
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
- **Preemption (ruling Q10, 2026-09-26).** A law that forbids another level of government to act
  decides *which level* may set the rule, not *what* the rule is → `adjacent`, unless a rung is itself
  about which level decides.
  - **Refined 2026-09-26:** when the state law removes the very limits a rung names (a rung that says
    "cut the zoning limits that block building", and a law that voids local zoning limits statewide),
    it is `on-question` but only `direction-only`. One deregulation law cannot show that the person
    wants *nothing more* ("rely on the market", "at most") — that is an unproven magnitude → BLANK.

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

politician_id: 6ab10a36-52d6-4d7a-b039-60416eb5fd3f  office_id: 6f5b8175-824f-4677-abb3-aea3d9e8b8ae
Jake Teshka — Representative, Indiana (seated, level: state)
Current term: 2020-11-04 (precision: day) to present

## Topics (served ladder text — code against these words only)

### topic_key: gun-policy
topic_id: 56125933-b82a-46c5-847b-b2e9a146b89f  served_revision_id: 44615418-e111-4f2f-a256-92fcf74b0f2f
Question: How should the government regulate firearms?
  1. Ban civilian firearm ownership, except for tightly licensed hunting and sport use.
  2. Ban semi-automatic assault-style weapons, while allowing other firearms.
  3. Allow all types of firearms, but require universal background checks on every sale.
  4. Add no new restrictions, and at most loosen rules on carrying, such as honoring permits across state lines.
  5. Repeal major gun restrictions and let adults carry a firearm without a permit.

#### Annex

(no annex for this topic yet — apply the codebook alone)

## Sources

---
snapshot_id: c902ec0b-744f-5ae8-b06c-b52bbe4d2156
source_kind: public-record
url: https://iga.in.gov/pdf-documents/123/2024/house/bills/HB1084/HB1084.01.INTR.pdf

Introduced Version HOUSE BILL No. 1084 _____ DIGEST OF INTRODUCED BILL Citations Affected: IC 24-5-27.5. Synopsis: Privacy of firearms financial transactions. Prohibits a governmental entity or any other person from knowingly or willfully keeping any list, record, or registry of: (1) privately owned firearms; or (2) the owners of firearms; with respect to Indiana consumers. Defines a "firearms code" as a merchant category code approved by the International Organization for Standardization specifically for firearms retailers. Provides that in a payment card transaction, a merchant acquirer or a payment card network may not: (1) use; or (2) require the use of; a firearms code in a way that distinguishes a firearms retailer with at least one physical location in Indiana from general merchandise retailers or sporting goods retailers. Prohibits a financial services provider from declining or otherwise refusing to process a lawful payment card transaction based solely on the assignment or nonassignment of a firearms code to the payment card transaction. Prohibits a financial services provider from disclosing a financial record that: (1) is related to a payment card transaction; and (2) includes protected financial information, including a firearms code used, collected, or assigned in violation of the bill's provisions. Specifies that the bill's provisions apply only to a payment card transaction that is initiated after June 30, 2024: (1) at a firearms retailer's physical location in Indiana; or (2) on an online platform if the purchaser is an Indiana consumer and the seller is a firearms retailer that: (A) has at least one physical location in Indiana; or (B) does not have at least one physical location in Indiana if the firearm purchased will be shipped: (i) to another firearms retailer's physical location in Indiana and transferred to the Indiana consumer at that location; or (ii) (Continued next page) Effective: July 1, 2024. Teshka, Manning, Haggard January 8, 2024, read first time and referred to Committee on Financial Institutions. 2024 IN 1084—LS 6643/DI 101 Digest Continued directly to the Indiana consumer at the Indiana consumer's Indiana address. Requires the attorney general to investigate any alleged or suspected violation of the bill's provisions and, upon finding a violation, to provide written notice to any person, public or private, found to be in violation. Provides that upon receiving a written notice from the attorney general of a violation, a person has 30 calendar days to cease the violation. Requires the attorney general to seek injunctive relief in a court having jurisdiction for continued violations of the bill's provisions. Provides that if a person violates an injunction issued by a court, the attorney general shall petition the issuing court for a civil penalty not to exceed $10,000 per violation of the injunction. Sets forth certain factors that a court must consider in determining the amount of the civil penalty. Specifies that the remedies set forth in the bill are the exclusive remedies for a violation of the bill's provisions. 2024 IN 1084—LS 6643/DI 101 2024 IN 1084—LS 6643/DI 101 Introduced Second Regular Session of the 123rd General Assembly (2024) PRINTING CODE. Amendments: Whenever an existing statute (or a section of the Indiana Constitution) is being amended, the text of the existing provision will appear in this style type, additions will appear in this style type , and deletions will appear in this style type. Additions: Whenever a new statutory provision is being enacted (or a new constitutional provision adopted), the text of the new provision will appear in this style type . Also, the word NEW will appear in that style type in the introductory clause of each SECTION that adds a new provision to the Indiana Code or the Indiana Constitution. Conflict reconciliation: Text in a statute in this style type or this style type reconciles conflicts between statutes enacted by the 2023 Regular Session of the General Assembly. HOUSE BILL No. 1084 A BILL FOR AN ACT to amend the Indiana Code concerning trade regulation. Be it enacted by the General Assembly of the State of Indiana: 1 SECTION 1. IC 24-5-27.5 IS ADDED TO THE INDIANA CODE 2 AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE 3 JULY 1, 2024]: 4 Chapter 27.5. Privacy of Firearms Financial Transactions 5 Sec. 1. (a) This chapter applies to a payment card transaction 6 that is initiated after June 30, 2024: 7 (1) at a firearms retailer's physical location in Indiana; or 8 (2) through the Internet or an online platform if the purchaser 9 in the payment card transaction is an Indiana consumer and 10 the seller in the payment card transaction is a firearms 11 retailer that: 12 (A) has at least one (1) physical location in Indiana; or 13 (B) does not have at least one (1) physical location in 14 Indiana if the firearm purchased in the transaction will be 15 shipped: 2024 IN 1084—LS 6643/DI 101 2 1 (i) to another firearms retailer's physical location in 2 Indiana and transferred to the Indiana consumer at that 3 location; or 4 (ii) directly to the Indiana consumer at the Indiana 5 consumer's Indiana address. 6 (b) This chapter does not apply to a payment card transaction 7 that is initiated at a firearms retailer's physical location outside 8 Indiana regardless of whether the: 9 (1) purchaser in the payment card transaction is an Indiana 10 consumer; or 11 (2) firearms retailer has at least one (1) physical location in 12 Indiana. 13 Sec. 2. As used in this chapter, "affiliate" means any person who 14 directly or indirectly: 15 (1) controls; 16 (2) is controlled by; or 17 (3) is under the common control of; 18 another person. 19 Sec. 3. As used in this chapter, "credit card" means any: 20 (1) card; 21 (2) plate; or 22 (3) other single credit device; 23 that may be used from time to time to obtain credit (as defined in 24 12 CFR 1026.2(a)(14)). 25 Sec. 4. As used in this chapter, "debit card" means any: 26 (1) card; 27 (2) plate; or 28 (3) other single device; 29 that may be used from time to time to access an asset account, 30 regardless of whether authorization for the debit is based on a 31 signature, a personal identification number, or other means. 32 Sec. 5. As used in this chapter, "disclose", with respect to 33 protected financial information, means to transfer, publish, or 34 distribute the protected financial information to another person for 35 any purpose other than to: 36 (1) process or facilitate a payment card transaction; or 37 (2) take any action related to: 38 (A) dispute processing; 39 (B) fraud management; or 40 (C) protecting the integrity of the transaction with respect 41 to: 42 (i) illegal activity; 2024 IN 1084—LS 6643/DI 101 3 1 (ii) security breaches; or 2 (iii) cyber risks; 3 with respect to a payment card transaction. 4 Sec. 6. As used in this chapter, "financial institution" means any 5 bank, trust company, corporate fiduciary, savings association, 6 credit union, savings bank, bank of discount and deposit, or 7 industrial loan and investment company organized or reorganized 8 under Indiana law, the law of another state (as defined in 9 IC 28-2-17-19), or United States law. 10 Sec. 7. (a) As used in this chapter, "financial services provider" 11 means any of the following that is involved in facilitating or 12 processing a payment card transaction, as appropriate in the 13 context: 14 (1) A financial institution. 15 (2) A person engaged in money transmission in Indiana under 16 IC 28-8-4.1. 17 (3) A payment card issuer. 18 (4) A payment card network. 19 (5) A merchant acquirer. 20 (b) The term includes an: 21 (1) affiliate; 22 (2) officer; 23 (3) agent; or 24 (4) employee; 25 of a person listed in subsection (a). 26 Sec. 8. As used in this chapter, "firearm" includes the following: 27 (1) A firearm (as defined in IC 34-12-3-1). 28 (2) Ammunition for use in a firearm. 29 (3) Firearm components. 30 (4) Firearm accessories. 31 Sec. 9. As used in this chapter, "firearms code" means a 32 merchant category code approved by the International 33 Organization for Standardization specifically for firearms 34 retailers. 35 Sec. 10. As used in this chapter, "firearms retailer" means any 36 person engaged in the lawful business of selling or trading 37 firearms. 38 Sec. 11. (a) As used in this chapter, "governmental entity" 39 means any of the following: 40 (1) The state. 41 (2) A state agency (as defined in IC 1-1-15-3). 42 (3) A political subdivision (as defined in IC 36-1-2-13) or an 2024 IN 1084—LS 6643/DI 101 4 1 instrumentality of a political subdivision (as defined in 2 IC 36-1-2-13). 3 (b) The term includes an: 4 (1) official; 5 (2) agent; or 6 (3) employee; 7 of an entity listed in subsection (a). 8 Sec. 12. As used in this chapter, "Indiana consumer" means a: 9 (1) natural person whose principal residence is in Indiana; or 10 (2) person, other than a natural person, that is domiciled in 11 Indiana. 12 Sec. 13. As used in this chapter, "merchant acquirer" means a 13 person that establishes a relationship with a merchant to enable the 14 processing of payment card transactions by collecting funds from 15 the payment card issuer in the transaction and depositing them in 16 the merchant's account. 17 Sec. 14. As used in this chapter, "payment card" means: 18 (1) a credit card; 19 (2) a debit card; or 20 (3) another device that may be used to carry out debit or 21 credit transactions. 22 Sec. 15. As used in this chapter, "payment card issuer" means 23 a: 24 (1) lender, including a financial institution; or 25 (2) merchant; 26 that receives applications for and issues payment cards to 27 consumers. 28 Sec. 16. As used in this chapter, "payment card network" means 29 an entity that directly, or through licensed members, processors, 30 or agents, provides the proprietary services, infrastructure, and 31 software that: 32 (1) route information and data to conduct debit card or credit 33 card transaction authorization, clearance, and settlement; and 34 (2) a merchant or seller uses in order to accept as a form of 35 payment a brand of: 36 (A) debit card; 37 (B) credit card; or 38 (C) another device that may be used to carry out debit or 39 credit transactions. 40 Sec. 17. As used in this chapter, "payment card transaction" 41 means a transaction in which a consumer uses a payment card to 42 purchase or obtain goods, services, money, or any other thing of 2024 IN 1084—LS 6643/DI 101 5 1 value. 2 Sec. 18. As used in this chapter, "person" means: 3 (1) a natural person; or 4 (2) an organization, including a corporation, a partnership, a 5 proprietorship, an association, a cooperative, an estate, or a 6 trust. 7 Sec. 19. As used in this chapter, "protected financial 8 information" means any record of a: 9 (1) sale; 10 (2) purchase; 11 (3) return; or 12 (4) refund; 13 that is made or processed with a payment card and that is 14 retrieved, characterized, generated, labeled, sorted, or grouped 15 based on the assignment of a firearms code. 16 Sec. 20. (a) Except as provided in subsection (b), or as otherwise 17 required by law, a governmental entity or any other person, public 18 or private, shall not knowingly or willfully keep or cause to be kept 19 any: 20 (1) list, record, or registry of privately owned firearms; or 21 (2) list, record, or registry of the owners of firearms; 22 with respect to Indiana consumers. 23 (b) Subsection (a) does not apply with respect to the following: 24 (1) Records kept during the regular course of a criminal 25 investigation or prosecution. 26 (2) Records kept by the owner of privately owned firearms. 27 (3) Information submitted to a law enforcement agency in 28 connection with an application for a license to carry a 29 handgun under IC 35-47-2-3, subject to the limitations set 30 forth in IC 35-47-2-3(n) and IC 35-47-2-3(o). 31 Sec. 21. In a payment card transaction, a merchant acquirer or 32 payment card network may not: 33 (1) use; or 34 (2) require the use of; 35 a firearms code in a way that distinguishes a firearms retailer with 36 at least one (1) physical location in Indiana from general 37 merchandise retailers or sporting goods retailers. 38 Sec. 22. (a) Except as provided in subsection (b), a financial 39 services provider may not decline or otherwise refuse to process a 40 lawful payment card transaction based solely on the assignment or 41 nonassignment of a firearms code to the payment card transaction. 42 (b) A financial services provider may decline or otherwise refuse 2024 IN 1084—LS 6643/DI 101 6 1 to process a lawful payment card transaction involving a firearms 2 retailer on the basis of the assignment or nonassignment of a 3 firearms code: 4 (1) at the request of the consumer; or 5 (2) in accordance with: 6 (A) fraud controls; or 7 (B) merchant category exclusions offered by a financial 8 services provider for the purpose of expenditure control or 9 corporate card control; 10 applicable to the payment card involved in the payment card 11 transaction. 12 Sec. 23. Except as otherwise required by law, a financial services 13 provider may not disclose a financial record that: 14 (1) is related to a payment card transaction; and 15 (2) includes protected financial information, including a 16 firearms code that was used, collected, or assigned in violation 17 of this chapter. 18 Sec. 24. With respect to a payment card transaction, this 19 chapter may not be construed to: 20 (1) limit the ability of a financial services provider to 21 negotiate with responsible parties; or 22 (2) otherwise impair a financial services provider's actions; 23 related to dispute processing, fraud management, or protecting the 24 integrity of the payment card transaction with respect to illegal 25 activity, security breaches, or cyber risks. 26 Sec. 25. (a) The attorney general shall, upon: 27 (1) receiving notice of an alleged violation of this chapter 28 from: 29 (A) a firearms retailer: 30 (i) with at least one (1) physical location in Indiana; and 31 (ii) whose business is the subject of the alleged violation 32 with respect to a payment card transaction; or 33 (B) an Indiana consumer involved in a payment card 34 transaction that is the subject of the alleged violation; or 35 (2) the attorney general's own motion, if the attorney general 36 has reasonable cause to believe that any person, public or 37 private, has engaged in, is engaging in, or is about to engage 38 in a violation of this chapter; 39 investigate the alleged or suspected violation. If the attorney 40 determines that a violation has occurred, the attorney general shall 41 provide written notice to any person, public or private, found to be 42 in violation of this chapter. Upon receiving a written notice from 2024 IN 1084—LS 6643/DI 101 7 1 the attorney general under this subsection, a person has thirty (30) 2 calendar days from the date of receipt to cease the violation of this 3 chapter. 4 (b) If a person found to be in violation of this chapter fails to 5 cease the violation within the thirty (30) day period set forth in 6 subsection (a), the attorney general shall seek, in a court having 7 jurisdiction, injunctive relief against the person. If the court finds 8 that the person continues to be in violation of this chapter after the 9 thirty (30) day period set forth in subsection (a), the court shall 10 enjoin the person from continuing the activity found to be in 11 violation of this chapter. 12 (c) If an injunction is issued under subsection (b), and the 13 person subject to the injunction knowingly or willfully fails to 14 comply with the injunction within thirty (30) calendar days after 15 being served with the injunction, the attorney general shall petition 16 the issuing court for, and may recover on behalf of the state, a civil 17 penalty not to exceed ten thousand dollars ($10,000) per violation 18 of the injunction that occurs after the thirty (30) day period 19 described in this subsection. In determining the amount of a civil 20 penalty under this subsection, the court shall consider: 21 (1) the financial resources of the person found to be in 22 violation; 23 (2) the harm or risk of harm to an Indiana consumer's rights 24 or to a firearms retailer's rights, as applicable, under: 25 (A) the Second Amendment to the Constitution of the 26 United States; or 27 (B) Article 1, Section 32 of the Constitution of the State of 28 Indiana; and 29 (3) any other factor considered relevant by the court. 30 The attorney general is entitled to recover, in addition to the civil 31 penalty under this subsection, the attorney general's investigative 32 costs and reasonable attorney's fees. However, an order assessing 33 a civil penalty under this subsection shall be stayed pending an 34 appeal of the order. 35 (d) The remedies set forth in this section are the exclusive 36 remedies for a violation of this chapter. 2024 IN 1084—LS 6643/DI 101

---
snapshot_id: 2c257caa-4a86-5afc-8b71-8941bd088687
source_kind: public-record
url: https://iga.in.gov/legislative/2024/bills/house/1084/details

IGA | House Bill 1084 - Privacy of firearms financial transactions (2024) Indiana General Assembly 2024 Session. House Bill 1084 Privacy of firearms financial transactions. Enrolled House Bill (H) Authored by: Rep. Jake Teshka. Co-Authored by: Rep. Ethan Manning, Rep. Craig Haggard, Rep. Mike Speedy. Sponsored by: Sen. Scott Baldwin, Sen. Tyler Johnson, Sen. Blake Doriot, Sen. Mark Messmer, Sen. Aaron Freeman, Sen. Mike Gaskill, Sen. James Tomes, Sen. Eric Koch, Sen. Jeff Raatz, Sen. Andy Zay. Digest Amends the statute establishing the right of a member of: (1) the general assembly; (2) the professional staff of the general assembly; or (3) the Indiana lobby registration commission; to carry a handgun within the state capitol building and on the property of the state capitol complex by specifying that the right applies to any such member who is not prohibited under state or federal law from possessing a handgun. (Current law provides that the right applies to a member who: (1) possesses a valid Indiana license to carry a handgun; and (2) is otherwise permitted to possess a handgun.) Adds a new chapter to the Indiana Code article governing state officers to provide that any of the following state officers who is not prohibited from possessing a handgun under state or federal law has the right to carry a handgun within the state capitol building and on the property of the state capitol complex: (1) The attorney general. (2) The secretary of state. (3) The state comptroller. (4) The treasurer of state. Prohibits a governmental entity or any other person from knowingly or willfully keeping any list, record, or registry of: (1) privately owned firearms; or (2) the owners of firearms; with respect to Indiana consumers. Defines a "firearms code" as a merchant category code approved by the International Organization for Standardization specifically for firearms retailers. Provides that in a payment card transaction, a merchant acquirer or a payment card network may not: (1) assign; or (2) require the assignment of; a firearms code in a way that distinguishes a firearms retailer with at least one physical location in Indiana from general merchandise retailers or sporting goods retailers. Prohibits a financial services provider from declining or otherwise refusing to process a lawful payment card transaction based solely on the assignment or nonassignment of a firearms code to the payment card transaction. Prohibits a financial services provider from disclosing a financial record that: (1) is related to a payment card transaction; and (2) includes protected financial information, including a firearms code used, collected, or assigned in violation of the bill's provisions. Specifies that the bill's provisions apply only to a payment card transaction that is initiated after September 30, 2024, at a firearms retailer that is physically located in Indiana. Provides that the applicable primary financial regulator with jurisdiction over a financial services provider subject to the bill's provisions is responsible for enforcing the financial services provider's compliance with those provisions. Provides that, with respect to any person that is not a financial services provider subject to regulation by a financial regulator, the attorney general is responsible for enforcing the bill's prohibition against knowingly or willfully keeping any list, record, or registry of: (1) privately owned firearms; or (2) the owners of firearms. Provides that upon receiving notice of an alleged violation of this prohibition, the attorney general shall investigate the alleged violation in accordance with the attorney general's investigative demand procedures, subject to the statutory confidentiality provisions that apply to such procedures. View less