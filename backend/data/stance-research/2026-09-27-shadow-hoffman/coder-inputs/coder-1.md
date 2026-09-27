You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-27-shadow-hoffman/labels/coder-1.json. Write JSON only, matching
codebook Part E, with "codebook_version": "0.3.1" and "coder_slot": 1. One row per
topic below. Every quoted string you write must be copied exactly from a source below.

## Codebook

# Empowered Vote — Stance & Quote Codebook

**Version:** 0.3.1 (DRAFT, 2026-09-25). It carries rulings Q1–Q9 (design spec §9.1) and the record
fields (confirm-basis spec). The annex
readings and examples are not yet ruled on. Every label records `codebook_version`.
**Clarified 2026-09-26 (still 0.3 — no new variable, the validator got more permissive):** the
record fields are required per instrument group, not per passage (V3 "Record fields", Part E), and V3
carries a worked two-passage vote example.
**Updated 2026-09-27 (0.3 → 0.3.1 — a new rule coders must apply, amendment-markup spec §5):** text
inside a `[deleted: …]` fence is removed from the law; it is never the provision, and a coder never
quotes it as `provision_quote` (V3 "Record fields").
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
  - **An amending bill's page keeps deleted text fenced as `[deleted: …]` (amendment-markup spec
    2026-09-27 §2).** That text is removed from the law — it is never the provision, and never
    quoted as `provision_quote`. A bill's effect is the added text plus the unchanged text.
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

politician_id: 66ca210e-deab-4d07-8a18-48f7079f6f9b  office_id: cd9644aa-ae19-4f20-bde2-6099f5ac57cc
Jake Hoffman — State Senator, Arizona (seated, level: state)
Current term: 2023-01-02 (precision: day) to present

## Topics (served ladder text — code against these words only)

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
snapshot_id: 24f32815-b607-5ce4-a12d-ee748d219f48
source_kind: public-record
url: https://www.azleg.gov/legtext/55leg/2R/laws/0099.htm

Chapter 0099 - 552R - H Ver of HB2492 House Engrossed voter registration; verification; citizenship State of Arizona House of Representatives Fifty-fifth Legislature Second Regular Session 2022 CHAPTER 99 HOUSE BILL 2492 An Act amending sections 16-101, 16-112, 16-121 and 16-121.01, Arizona Revised Statutes; amending title 16, chapter 1, article 2, Arizona Revised Statutes, by adding sections 16-123 and 16-127; amending section 16-134, Arizona Revised Statutes; amending title 16, chapter 1, article 3, Arizona Revised Statutes, by adding section 16-143; amending section 16-165, Arizona Revised Statutes; relating to qualification and registration of electors. (TEXT OF BILL BEGINS ON NEXT PAGE) Be it enacted by the Legislature of the State of Arizona: Section 1. Section 16-101, Arizona Revised Statutes, is amended to read: START_STATUTE 16-101 . Qualifications of registrant; definition A. Every resident of [deleted: the] this state is qualified to register to vote if [deleted: he] the resident : 1. Is a citizen of the United States and has provided SATISFACTORY evidence of CITIZENSHIP as PRESCRIBED in section 16-166 . 2. Will be eighteen years of age or more on or before the date of the regular general election next following his registration. 3. [deleted: Will have been] Is a resident of [deleted: the] this state twenty-nine days next preceding the election, except as provided in section 16-126. 4. Is able to write [deleted: his] the resident's name or make [deleted: his] the resident's mark, unless prevented from so doing by physical disability. 5. Has not been convicted of treason or a felony, unless restored to civil rights. 6. Has not been adjudicated an incapacitated person as defined in section 14-5101. B. For the purposes of this title, "resident" means an individual who has actual physical presence in this state, or for purposes of a political subdivision actual physical presence in the political subdivision, combined with an intent to remain. A temporary absence does not result in a loss of residence if the individual has an intent to return following his absence. An individual has only one residence for purposes of this title. END_STATUTE Sec. 2. Section 16-112, Arizona Revised Statutes, is amended to read: START_STATUTE 16-112 . Driver license voter registration A. Every person who is applying for a driver license or renewal and who is otherwise qualified to register to vote [deleted: shall], at the same time and place, shall be [deleted: permitted] allowed to register to vote by providing the information prescribed by section 16-152.� The method used to register voters shall require only the minimum information necessary to prevent duplicate registrations, to enable elections officials to determine voter eligibility and to administer voter registration and election laws.� A registration form shall be included for a person who is applying for a driver license renewal by mail.� On [deleted: completion of] completing a form that contains at least the information prescribed by section 16-121.01[deleted: , subsection A] and that may contain the information prescribed by section 16-152 and on receipt of that form by the county recorder from the department of transportation as prescribed by subsection D of this section, the applicant is presumed to be properly registered to vote.� That presumption may be rebutted as provided in section 16-121.01[deleted: , subsection B]. B. The director of the department of transportation and the secretary of state shall consult at least every two years regarding voter registration at driver license offices.� The director of the department of transportation and the secretary of state [deleted: shall], after consultation with all county recorders, shall adopt rules to implement a system [deleted: permitting] allowing driver license applicants to register to vote at the same time and place as they apply for driver licenses.� [deleted: Such] The rules shall: 1. Bring the license application and voter registration application forms into substantial conformity. 2. [deleted: Permit] Allow the transfer of driver license applications, including renewal and change of address, and voter registration information from the department of transportation to the voter registration rolls. 3. Respect all rules and statutes of this state concerning the confidentiality of driver license application information. 4. Provide for the manual or electronic generation and transmittal of voter registrations and provide for electronic generation of changes in voter registration information, including address, in conformity with the confidentiality requirements of the national voter registration act of 1993 (P.L. 103-31; 107 Stat. 77; [deleted: 42] 52 United States Code [deleted: section 394] sections 20501 through 20511 ). C. The department of transportation shall provide to applicants a statement that provides each eligibility requirement for voting, including citizenship, an attestation that the applicant meets each requirement, for the signature of the applicant under penalty of perjury and, in print that is identical to that used in the attestation, the following: 1. A description of the penalties provided by law for the submission of a false voter registration application. 2. A statement that if an applicant declines to register to vote the fact that the applicant has declined to register will remain confidential and will be used only for voter registration purposes. 3. A statement that if an applicant does register to vote the office at which the applicant submits a voter registration application will remain confidential and will be used only for voter registration purposes. D. The department of transportation shall return or mail completed registrations to the county recorder of the county in which the applicant resides within five days after receipt of a completed registration. END_STATUTE Sec. 3. Section 16-121, Arizona Revised Statutes, is amended to read: START_STATUTE 16-121 . Qualified elector; definition A. A person who is qualified to register to vote pursuant to section 16-101 and who is properly registered to vote [deleted: shall], if [deleted: he] the person is at least eighteen years of age on or before the date of the election and has provided SATISFACTORY EVIDENCE of citizenship as prescribed in SECTION 16-166 , shall be deemed a qualified elector for any purpose for which such qualification is required by law, except as provided in section 16-126. A person continues to be a qualified elector until that person's registration is canceled pursuant to section 16-165 or until that person does not qualify as a resident as [deleted: prescribed by] defined in section 16-101, subsection B. B. For purposes of subsection A of this section, a person who does not reside at a fixed, permanent or private structure shall be properly registered to vote if that person is qualified pursuant to section 16-101 and if that person's registration address is any of the following places located in this state: 1. A homeless shelter to which the registrant regularly returns. 2. The place at which the registrant is a resident. 3. The county courthouse in the county in which the registrant resides. 4. A general delivery address for a post office covering the location where the registrant is a resident. C. A person who is otherwise qualified to register to vote shall not be refused registration or declared not qualified to vote because the person does not live in a permanent, private or fixed structure. D. [deleted: As used in] For the purposes of this section, "homeless shelter" means a supervised publicly or privately operated shelter designed to provide temporary living accommodations to individuals who lack a fixed, regular and adequate nighttime residence. END_STATUTE Sec. 4. Section 16-121.01, Arizona Revised Statutes, is amended to read: START_STATUTE 16-121.01 . Requirements for proper registration; violation; classification A. A person is presumed to be properly registered to vote on completion of a registration form as prescribed by section 16-152 that contains at least the name, the residence address or the location, proof of location of residence as prescribed by section 16-123, the date and place of birth and the signature or other statement of the registrant as prescribed by section 16-152, subsection A, paragraph 20 and a checkmark or other appropriate [deleted: indicator that the person answered] mark in the "yes" box next to the question regarding citizenship. Any application for registration, including an application on a form PRESCRIBED by the United States election assistance commission, must contain a checkmark or other appropriate mark in the "yes" box next to the question regarding citizenship as a condition of being properly registered to vote as either a voter who is eligible to vote a full ballot or a voter who is eligible to vote only with a ballot for federal offices. The completed registration form must also contain the person's Arizona driver license number, the nonoperating identification license number issued pursuant to section 28-3165, the last four digits of the person's social security number or the person's affirmation that if an Arizona driver license number, A nonoperating identification license number or the last four digits of the person's social security number is not provided, the person does not possess a valid Arizona driver or nonoperating identification license or a social security number and the person is hereby requesting that a unique identifying number be assigned by the secretary of state pursuant to section 16-152, subsection A, paragraph 12, subdivision (c).� Any application that does not include all of the information required to be on the REGISTRATION form pursuant to section 16-152 and any application that is not signed is incomplete and the county recorder shall notify the applicant pursuant to section 16-134, subsection b, and shall not register the voter until all of the information is returned. B. The presumption in subsection A of this section may be rebutted only by clear and convincing evidence of any of the following: 1. That the registrant is not the person whose name appears on the register. 2. That the registrant has not resided in this state for twenty-nine days next preceding the election or other event for which the registrant's status as properly registered is in question. 3. That the registrant is not properly registered at an address permitted by section 16-121. 4. That the registrant is not a qualified registrant under section 16-101. C. Except for a form produced by the United States election assistance commission, any application for registration shall be accompanied by satisfactory evidence of citizenship as prescribed in section 16-166, subsection F, and the county recorder or other officer in charge of elections shall reject any application for registration that is not accompanied by satisfactory evidence of citizenship. A county recorder or other officer in charge of elections who knowingly fails to reject an application for registration as prescribed by this subsection is guilty of a class 6 felony. THE COUNTY RECORDER OR OTHER OFFICER IN CHARGE OF ELECTIONS SHALL SEND A NOTICE TO THE APPLICANT AS PRESCRIBED IN SECTION 16-134, SUBSECTION B. D. Within ten days after RECEIVING an application for registration on a form produced by the United States election assistance commission that is not accompanied by satisfactory evidence of citizenship, the county recorder or other officer in charge of elections shall use all available resources to verify the citizenship status of the applicant and at a minimum shall compare the information available on the application for registration with the following, provided the county has access: 1. The department of transportation databases of ARIZONA DRIVER licenses or nonoperating identification licenses. 2. The social security administration databases. 3. The United States citizenship and immigration services systematic alien verification for entitlements program, if practicable. 4. A national association for public health statistics and information systems electronic verification of vital events system. 5. Any other state, city, town, county or federal database and any other database relating to voter REGISTRATION to which the county recorder or officer in charge of elections has access, including an electronic registration information center database. E. After complying with subsection D of this section, if the county recorder or other officer in charge of elections matches the applicant with INFORMATION that verifies the applicant is a United States citizen, is otherwise qualified as prescribed by section 16-101 and has met the other requirements of this section, the applicant shall be properly registered. If the county recorder or other officer in charge of elections matches the applicant with information that the applicant is not a United States citizen, the county recorder or other officer in charge of elections shall reject the application, notify the applicant that the application was rejected because the applicant is not a United States citizen and forward the application to the county attorney and attorney general for investigation.� If the county recorder or other officer in charge of elections is unable to match the applicant with appropriate citizenship information, the county recorder or other officer in charge of elections shall notify the applicant that the county recorder or other officer in charge of elections could not verify that the applicant is a United States citizen and that the applicant will not be QUALIFIED to vote in a PRESIDENTIAL election or by mail with an early ballot in any election until satisfactory evidence of citizenship is provided. F. The county recorder or other officer in charge of elections shall record the efforts made to verify an applicant's citizenship status as prescribed in subsections D and E of this section.� If the county recorder or other officer in charge of elections fails to attempt to verify the citizenship status of an applicant pursuant to subsections D and E of this section and the county recorder or other officer in charge of elections knowingly causes the applicant to be registered and it is later determined that the applicant was not a United States citizen at the time of registration, the county recorder or other officer in charge of elections is guilty of a class 6 felony. END_STATUTE Sec. 5. Title 16, chapter 1, article 2, Arizona Revised Statutes, is amended by adding sections 16-123 and 16-127, to read: START_STATUTE 16-123. Proof of location of residence Except for persons who register pursuant to section 16-103, a person who registers to vote shall provide an identifying document that establishes proof of location of residence. Any of the identifying documents prescribed in section 16-579, SUBSECTION A, paragraph 1 CONSTITUTEs satisfactory proof of location of residence.� Compliance with this section does not SATISFY the residency requirements in section 16-101 or 16-593 and only constitutes confirmation of the address on the applicant's application at the time of registration. a valid and unexpired Arizona driver license or nonoperating identification number that is properly verified by the county recorder satisfies the requirements of this section. END_STATUTE START_STATUTE 16-127. Federal only voters; early ballot; eligibility; exemption A. NOTWITHSTANDING ANY OTHER LAW: 1. A person who has REGISTERED TO VOTE and WHO HAS NOT PROVIDED SATISFACTORY EVIDENCE OF CITIZENSHIP as prescribed by section 16-166, subsection F is not eligible TO VOTE IN PRESIDENTIAL ELECTIONS. 2. A person WHO HAS NOT PROVIDED SATISFACTORY EVIDENCE OF CITIZENSHIP PURSUANT TO section 16-166, subsection F AND who IS eligible to VOTE ONLY for FEDERAL offices is NOT ELIGIBLE TO RECEIVE AN EARLY BALLOT BY MAIL. B. THIS SECTION DOES NOT APPLY TO AN ABSENT UNIFORMED SERVICES VOTER OR OVERSEAS VOTER AS DEFINED IN THE UNIFORMED AND OVERSEAS CITIZENS ABSENTEE VOTING ACT (P.L. 99-410; 100 Stat. 924; 52 UNITED STATES CODE SECTION 20310), AS AMENDED BY THE RONALD W. REAGAN NATIONAL DEFENSE AUTHORIZATION ACT FOR FISCAL YEAR 2005 (P.L. 108-375). END_STATUTE Sec. 6. Section 16-134, Arizona Revised Statutes, is amended to read: START_STATUTE 16-134 . Return of registrations made outside office of county recorder; incomplete or illegible forms A. A county recorder shall authorize persons to accept registration forms, shall designate places for receipt of registration forms and shall designate additional locations for distribution of voter registration forms. Public assistance agencies and disabilities agencies as defined in section 16-140 shall return or mail completed voter registrations to the county recorder of the county in which the applicant resides within five days after receipt of those registrations. B. If the information on the registration form is incomplete or illegible and the county recorder is not able to process the registration form, the county recorder shall notify the applicant within ten business days of receipt of the registration form, shall specify the missing or illegible information and, if the missing or illegible information includes any of the information prescribed by section 16-121.01, subsection A or C , shall state that the registration cannot be completed until the information is supplied. If the missing or illegible information is supplied before 7:00 p.m. on election day, that person is deemed to have been registered on the date the registration was first received. C. In the case of registration by mail, a voter registration is valid for an election if it complies with either of the following: 1. The form is postmarked twenty-nine days or more before an election and is received by the county recorder by 7:00 p.m. on the day of that election. 2. The registration is dated twenty-nine days or more before an election and is received by the county recorder by first class mail within five days after the last day to register to vote in that election. D. The date of registration entered for registration forms that are received by the county recorder from persons, groups or agencies that are not authorized to accept registrations pursuant to subsection A of this section and that do not bear a legible postmark date or an otherwise reliable date shall be the date that those forms are received by the county recorder. END_STATUTE Sec. 7. Title 16, chapter 1, article 3, Arizona Revised Statutes, is amended by adding section 16-143, to read: START_STATUTE 16-143. Federal only voters; attorney general; investigation; report A. THE SECRETARY OF STATE AND EACH COUNTY RECORDER SHALL MAKE AVAILABLE TO THE ATTORNEY GENERAL A LIST OF ALL INDIVIDUALS who are REGISTERED TO VOTE and WHO HAVE NOT PROVIDED SATISFACTORY EVIDENCE OF CITIZENSHIP PURSUANT TO SECTION 16-166 AND SHALL PROVIDE, on or before OCTOBER 31, 2022, THE APPLICATIONS OF INDIVIDUALS WHO ARE REGISTERED TO VOTE and WHO HAVE NOT PROVIDED SATISFACTORY EVIDENCE OF CITIZENSHIP PURSUANT TO SECTION 16-166. B. THE ATTORNEY GENERAL SHALL USE ALL AVAILABLE RESOURCES TO VERIFY THE CITIZENSHIP STATUS OF THE APPLICANT AND AT A MINIMUM SHALL COMPARE THE INFORMATION AVAILABLE ON THE APPLICATION FOR REGISTRATION WITH THE FOLLOWING: 1. THE DEPARTMENT OF TRANSPORTATION DATABASES OF ARIZONA DRIVER LICENSES OR NONOPERATING IDENTIFICATION LICENSES. 2. THE SOCIAL SECURITY ADMINISTRATION DATABASES. 3. THE UNITED STATES CITIZENSHIP AND IMMIGRATION SERVICES SYSTEMATIC ALIEN VERIFICATION FOR ENTITLEMENTS PROGRAM, IF PRACTICABLE. 4. A NATIONAL ASSOCIATION FOR PUBLIC HEALTH STATISTICS AND INFORMATION SYSTEMS ELECTRONIC VERIFICATION OF VITAL EVENTS SYSTEM. 5. ANY OTHER STATE, CITY, TOWN, COUNTY OR FEDERAL DATABASE AND ANY OTHER DATABASE RELATING TO VOTER REGISTRATION TO WHICH THE COUNTY RECORDER OR OFFICER IN CHARGE OF ELECTIONS HAS ACCESS, INCLUDING AN ELECTRONIC REGISTRATION INFORMATION CENTER DATABASE. C. THE SECRETARY OF STATE SHALL PROVIDE THE ATTORNEY GENERAL ACCESS TO THE UNITED STATES CITIZENSHIP AND IMMIGRATION SERVICES SYSTEMATIC ALIEN VERIFICATION FOR ENTITLEMENTS PROGRAM FOR THE PURPOSES OF THIS SECTION. D. THE ATTORNEY GENERAL SHALL PROSECUTE INDIVIDUALS who are FOUND TO NOT BE UNITED STATES CITIZENS pursuant to section 16-182. E. THE ATTORNEY GENERAL SHALL SUBMIT A REPORT TO THE SECRETARY OF STATE, the PRESIDENT OF THE SENATE, AND the SPEAKER OF THE HOUSE of representatives on or before MARCH 31, 2023 DETAILING ALL FINDINGS RELATING TO THE CITIZENSHIP STATUS OF INDIVIDUALS who are REGISTERED TO VOTE and WHO HAVE NOT PROVIDED SATISFACTORY EVIDENCE OF CITIZENSHIP PURSUANT TO SECTION 16-166. END_STATUTE Sec. 8. Section 16-165, Arizona Revised Statutes, is amended to read: START_STATUTE 16-165 . Causes for cancellation A. The county recorder shall cancel a registration: 1. At the request of the person registered. 2. When the county recorder knows of the death of the person registered. 3. If the person has been adjudicated an incapacitated person as defined in section 14-5101. 4. When the person registered has been convicted of a felony, and the judgment of conviction has not been reversed or set aside.� The county recorder shall cancel the registration on receipt of notice of a felony conviction from the court or from the secretary of state or when reported by the elector on a signed juror questionnaire that is completed pursuant to section 21-314. 5. On production of a certified copy of a judgment directing a cancellation to be made. 6. Promptly after the election if the person registered has applied for a ballot pursuant to section 16-126. 7. When a person has been on the inactive voter list and has not voted during the time periods prescribed in section 16-166, subsection C. 8. When the county recorder receives written information from the person registered that the person has a change of residence within the county and the person does not complete and return a new registration form within twenty-nine days after the county recorder mails notification of the need to complete and return a new registration form with current information. 9. When the county recorder receives written information from the person registered that the person has a change of address outside the county. 10. When the county recorder receives and confirms information that the person registered is not a United States citizen. B. If the county recorder cancels a registration pursuant to subsection A, paragraph 8 of this section, the county recorder shall send the person notice that the registration has been cancelled and a registration form with the information described in section 16-131, subsection C attached to the form. C. When proceedings in the superior court or the United States district court result in a person being declared incapable of taking care of himself and managing his property, and for whom a guardian of the person and estate is appointed, result in such person being committed as an insane person or result in a person being convicted of a felony, the clerk of the superior court in the county in which those proceedings occurred shall file with the secretary of state an official notice of that fact.� The secretary of state shall notify the appropriate county recorder and the recorder shall cancel the name of the person on the register.� Such notice shall name the person covered, shall give the person's date and place of birth if available, the person's social security number, if available, the person's usual place of residence, the person's address and the date of the notice, and shall be filed with the recorder of the county where the person last resided. D. Each month the department of health services shall transmit to the secretary of state without charge a record of the death of every resident of the state reported to the department within the preceding month. This record shall include only the name of the decedent, the decedent's date of birth, the decedent's date of death, the decedent's social security number, if available, the decedent's usual legal residence at the time of death and, if available, the decedent's father's name or mother's maiden name. The secretary of state shall use the record for the sole purpose of canceling the names of deceased persons from the statewide voter registration database. In addition, the department of health services shall annually provide to the secretary of state from the statewide electronic death registration system without charge a record of all deaths of residents of this state that are reported to the department of health services. The records transmitted by the department of health services shall include only the name of the decedent, the decedent's date of birth, the decedent's social security number, if available, the decedent's usual legal residence at the time of death and, if available, the decedent's father's name or mother's maiden name. The secretary of state shall compare the records of deaths with the statewide voter registration database. Public access to the records is prohibited. Use of information from the records for purposes other than those required by this section is prohibited. The name of each deceased person shall promptly be canceled from the statewide voter registration database and the secretary of state shall notify the appropriate county recorder and the recorder shall cancel the name of the person from the register. END_STATUTE Sec. 9. Severability If a provision of this act or its application to any person or circumstance is held invalid, the invalidity does not affect other provisions or applications of the act that can be given effect without the invalid provision or application, and to this end the provisions of this act are severable. APPROVED BY THE GOVERNOR MARCH 30, 2022. FILED IN THE OFFICE OF THE SECRETARY OF STATE MARCH 30, 2022.

---
snapshot_id: 356ac84c-3d82-56a3-96a9-f1c184c2bd87
source_kind: public-record
url: https://apps.azleg.gov/BillStatus/BillOverview?SessionID=125&BillNumber=HB2492

Bill Status Inquiry. Bill History for HB2492. Short Title: voter registration; verification; citizenship. Sponsors: Hoffman (Prime) Blackman (Co-Sponsor) Carter (Co-Sponsor) Chaplik (Co-Sponsor) Fillmore (Co-Sponsor) Kaiser (Co-Sponsor) Martinez (Co-Sponsor) Nguyen (Co-Sponsor) Parker (Co-Sponsor) Toma (Co-Sponsor) Wilmeth (Co-Sponsor) Governor Action 03/30/2022 Signed Chapter: 99 Chapter Version: House Engrossed [Bill overview for HB2492 (2022), saved by browser from apps.azleg.gov BillStatus on 2026-09-27.]

---
snapshot_id: e7828829-3acb-5732-a4c8-dfbe8f0db679
source_kind: public-record
url: https://apps.azleg.gov/BillStatus/BillOverview?SessionID=125&BillNumber=HB2492#house-third

House Third Reading - HB2492 voter registration; verification; citizenship Action Date Action Vote 02/28/2022 Passed 31-26-3-0-0 Amended ABRAHAM N ANDRADE N BARTON Y BIASIUCCI Y BLACKMAN Y BLACKWATER-NYGREN NV BOLDING NV BOLICK Y BURGES Y BUTLER N CANO N CARROLL Y CARTER Y CHAPLIK Y CHÁVEZ N COBB Y COOK Y DALESSANDRO N DEGRAZIA N DIAZ Y DUNN Y EPSTEIN N ESPINOZA N FERNANDEZ B N FILLMORE Y FINCHEM Y GRANTHAM Y GRIFFIN Y HERNANDEZ A N HERNANDEZ D N HERNANDEZ M N HOFFMAN Y JERMAINE N JOHN Y KAISER Y KAVANAGH Y LIGUORI N LONGDON N MARTINEZ Y MATHIS N MEZA N NGUYEN Y OSBORNE Y PARKER Y PAWLIK N PAYNE Y PINGERELLI Y POWERS HANNLEY N QUIÑONEZ N SALMAN NV SCHWIEBERT N SHAH N SIERRA N SOLORIO N TOMA Y TSOSIE N UDALL Y WENINGER Y WILMETH Y BOWERS Y [Vote detail dialog for HB2492 (2022) House Third Reading, saved by browser from apps.azleg.gov BillStatus on 2026-09-27.]