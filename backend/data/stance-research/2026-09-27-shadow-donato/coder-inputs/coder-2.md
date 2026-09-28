You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-27-shadow-donato/labels/coder-2.json. Write JSON only, matching
codebook Part E, with "codebook_version": "0.3.1" and "coder_slot": 2. One row per
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

politician_id: 250a7ae0-f130-449e-9625-4c2d1512bbf6  office_id: 897087f2-4301-4097-8245-5ccb22a0ab51
Stacey Donato — Senator, Indiana (seated, level: state)
Current term: 2019-01-01 (precision: year) to present

## Topics (served ladder text — code against these words only)

### topic_key: education-library-books
topic_id: 1fcff1e8-c913-4d97-91da-1145952d7c65  served_revision_id: f480f827-cb1f-4a2e-83cd-bef8763948b8
Question: How should schools handle challenges to books in libraries and classrooms?
  1. Keep every book available and let professional librarians and educators curate the collection
  2. Keep challenged books available to all, while letting parents limit what their own child can borrow
  3. Remove a challenged book only if a review committee of educators and parents finds it unsuitable
  4. Pull any book a parent challenges until it has been reviewed
  5. Remove any book a parent or community member reports as inappropriate, for all students

#### Annex

(no annex for this topic yet — apply the codebook alone)

## Sources

---
snapshot_id: 351df78a-5dd4-59ed-ba4e-e8d2c8d5c368
source_kind: public-record
url: https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1447/HB1447.04.ENRS.pdf

First Regular Session of the 123rd General Assembly (2023) PRINTING CODE. Amendments: Whenever an existing statute (or a section of the Indiana Constitution) is being amended, the text of the existing provision will appear in this style type, additions will appear in this style type , and deletions will appear in [deleted: this style type.] Additions: Whenever a new statutory provision is being enacted (or a new constitutional provision adopted), the text of the new provision will appear in this style type . Also, the word NEW will appear in that style type in the introductory clause of each SECTION that adds a new provision to the Indiana Code or the Indiana Constitution. Conflict reconciliation: Text in a statute in this style type or [deleted: this style type] reconciles conflicts between statutes enacted by the 2022 Regular Session of the General Assembly. HOUSE ENROLLED ACT No. 1447 AN ACT to amend the Indiana Code concerning education. Be it enacted by the General Assembly of the State of Indiana: SECTION 1. IC 20-23-18-3, AS AMENDED BY P.L.125-2022, SECTION 1, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2023]: Sec. 3. (a) Except as provided in subsection (c), the Muncie Community school corporation is subject to all applicable federal and state laws. (b) If a provision of this chapter conflicts with any other law, including IC 20-23-4, the provision in this chapter controls. (c) Notwithstanding subsection (a), to provide all administrative and academic flexibility to implement innovative strategies, the Muncie Community school corporation is subject only to the following IC 20 and IC 22 provisions: (1) IC 20-26-5-10 (criminal history). (2) IC 20-26-21 (personal analyses, evaluations, or surveys by third party vendors). [deleted: (2)] (3) IC 20-28-5-8 (conviction of certain felonies or misdemeanors; notice and hearing; permanent revocation of license; data base of school employees who have been reported). [deleted: (3)] (4) IC 20-28-10-17 (school counselor immunity). [deleted: (4)] (5) IC 20-29 (collective bargaining) to the extent required by HEA 1447 — CC 1 2 subsection (e). [deleted: (5)] (6) IC 20-30-3-2 and IC 20-30-3-4 (patriotic commemorative observances). [deleted: (6)] (7) The following: (A) IC 20-30-5-0.5 (display of the United States flag; Pledge of Allegiance). (B) IC 20-30-5-1, IC 20-30-5-2, and IC 20-30-5-3 (the constitutions of Indiana and the United States; writings, documents, and records of American history or heritage). (C) IC 20-30-5-4 (system of government; American history). (D) IC 20-30-5-5 (morals instruction). (E) IC 20-30-5-6 (good citizenship instruction). [deleted: (7)] (8) IC 20-32-4, concerning graduation requirements. [deleted: (8)] (9) IC 20-32-5.1, concerning the Indiana's Learning Evaluation Assessment Readiness Network (ILEARN) program. [deleted: (9)] (10) IC 20-32-8.5 (IRead3). [deleted: (10)] (11) IC 20-33-2 (compulsory school attendance). [deleted: (11)] (12) IC 20-33-8-16 (firearms, [deleted: and] deadly weapons, or destructive devices). [deleted: (12)] (13) IC 20-33-8-19, IC 20-33-8-21, and IC 20-33-8-22 (student due process and judicial review). [deleted: (13)] (14) IC 20-33-7 (parental access to education records). [deleted: (14)] (15) IC 20-33-9 (reporting of student violations of law). [deleted: (15)] (16) IC 20-34-3 (health and safety measures). [deleted: (16)] (17) IC 20-35 (concerning special education). [deleted: (17)] (18) IC 20-39 (accounting and financial reporting procedures). [deleted: (18)] (19) IC 20-40 (government funds and accounts). [deleted: (19)] (20) IC 20-41 (extracurricular funds and accounts). [deleted: (20)] (21) IC 20-42 (fiduciary funds and accounts). [deleted: (21)] (22) IC 20-42.5 (allocation of expenditures to student instruction and learning). [deleted: (22)] (23) IC 20-43 (state tuition support). [deleted: (23)] (24) IC 20-44 (property tax levies). [deleted: (24)] (25) IC 20-46 (levies other than general fund levies). [deleted: (25)] (26) IC 20-47 (related entities; holding companies; lease agreements). [deleted: (26)] (27) IC 20-48 (borrowing and bonds). [deleted: (27)] (28) IC 20-49 (state management of common school funds; state advances and loans). [deleted: (28)] (29) IC 20-50 (concerning homeless children and foster care children). HEA 1447 — CC 1 3 [deleted: (29)] (30) IC 22-2-18, before its expiration on June 30, 2021 (limitation on employment of minors). (d) The Muncie Community school corporation is subject to required audits by the state board of accounts under IC 5-11-1-9. (e) Except to the extent required under a collective bargaining agreement entered into before July 1, 2018, the Muncie Community school corporation is not subject to IC 20-29 unless the school corporation voluntarily recognizes an exclusive representative under IC 20-29-5-2. If the school corporation voluntarily recognizes an exclusive representative under IC 20-29-5-2, the school corporation may authorize a school within the corporation to opt out of bargaining allowable subjects or discussing discussion items by specifying the excluded items on the notice required under IC 20-29-5-2(b). The notice must be provided to the education employment relations board at the time the notice is posted. SECTION 2. IC 20-26-5.5 IS ADDED TO THE INDIANA CODE AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE JANUARY 1, 2024]: Chapter 5.5. School Library Sec. 1. (a) The governing body of a school corporation or charter school shall establish a: (1) procedure for each school to prepare a catalogue of materials available in the school library; (2) procedure for each school to allow a: (A) parent or guardian of a student enrolled in the school; or (B) community member: (i) within the school district; or (ii) within the school district in which the charter school is located; to submit a request to remove material from the school library that is obscene (as described in IC 35-49-2-1) or harmful to minors (as described in IC 35-49-2-2); and (3) response and appeal procedure for each school to respond to a removal request submitted by a parent, guardian, or community member described in subdivision (2). (b) The response and appeal procedure established under subsection (a)(3) must require the governing body to review the request at the next public meeting. Sec. 2. The governing body of a school corporation or charter school shall: (1) publish on the website of each school; and HEA 1447 — CC 1 4 (2) make available in hard copy for an individual upon request; the catalogue of material available in the school library and each policy established under this chapter. Sec. 3. A school corporation or charter school may not make available materials that contain: (1) obscene matter (as described in IC 35-49-2-1); or (2) matter harmful to minors (as described in IC 35-49-2-2); within the school library. SECTION 3. IC 20-26-21 IS ADDED TO THE INDIANA CODE AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2023]: Chapter 21. Personal Analyses, Evaluations, or Surveys by Third Party Vendors Sec. 1. As used in this chapter, "qualified school" means the following: (1) A school maintained by a school corporation. (2) A charter school. (3) A laboratory school established under IC 20-24.5-2. (4) The Indiana School for the Blind and Visually Impaired established by IC 20-21-2-1. (5) The Indiana School for the Deaf established by IC 20-22-2-1. Sec. 2. This chapter does not apply to the following: (1) An academic test or academic assessment, scoring keys, or other tools directly related to measuring a student's academic performance in understanding a particular curricular subject matter, as prescribed by the department. (2) A career aptitude or career interest survey. (3) An assessment or screening instrument administered by a third party employed: (A) psychologist licensed under IC 25-33; or (B) social worker, clinical social worker, marriage and family therapist, or mental health counselor licensed under IC 25-23.6; if the third party provider described in clause (A) or (B) is referred by school personnel in a crisis situation in which the school personnel and the third party provider reasonably believe that the student is in immediate danger of self harm, harming another person, or experiencing harm resulting from abuse or neglect. (4) An assessment, screening instrument, or evaluation survey HEA 1447 — CC 1 5 administered by a third party employed: (A) psychologist licensed under IC 25-33; or (B) social worker, clinical social worker, marriage and family therapist, or mental health counselor licensed under IC 25-23.6; who has received a consent for services from a student, if the student is an adult or emancipated minor, or parent of a student, if the student is an unemancipated minor. (5) A survey or evaluation administered to a student of a school by a third party vendor that gauges or attempts to gauge student satisfaction with or participation in the school's programming, technology platform, or approved curriculum. Sec. 3. If a school corporation or qualified school uses a third party vendor in providing a personal analysis, evaluation, or survey that reveals, identifies, collects, maintains, or attempts to affect a student's attitudes, habits, traits, opinions, beliefs, or feelings, the third party vendor and the school corporation or qualified school may not record, collect, or maintain the responses to or results of the analysis, evaluation, or survey in a manner that would identify the responses or results of an individual student. Sec. 4. (a) This section does not apply to a personal analysis, evaluation, or survey for which consent is required under IC 20-30-5-17(b). (b) Before a school corporation or qualified school may administer a personal analysis, evaluation, or survey described in section 3 of this chapter, the school corporation or qualified school must provide the parent of the student or the student, if the student is an adult or an emancipated minor, with a written request for consent for administration. A consent form provided to a parent of a student or a student under this subsection must accurately summarize the contents and nature of the personal analysis, evaluation, or survey that will be provided to the student and indicate that a parent of a student or an adult or emancipated minor student has the right to review and inspect all materials related to the personal analysis, evaluation, or survey. The written consent form may be sent in an electronic format. The parent of the student or the student, if the student is an adult or an emancipated minor, may return the consent form indicating that the parent of the student or the adult or emancipated student: (1) consents to the personal analysis, evaluation, or survey; or (2) declines the personal analysis, evaluation, or survey. If a student does not participate in the personal analysis, HEA 1447 — CC 1 6 evaluation, or survey, the school corporation or qualified school shall provide the student with alternative academic instruction during the same time frame that the personal analysis, evaluation, or survey is administered. (c) If the parent of the student or the student, if the student is an adult or an emancipated minor, does not respond to the written request provided by the school corporation or qualified school under subsection (b) within twenty-one (21) calendar days after receiving the request under subsection (b), the school corporation or qualified school shall provide the parent of the student or the student, if the student is an adult or an emancipated minor, a written notice requesting that the parent of the student, or the student, if the student is an adult or an emancipated minor, indicate, in a manner prescribed by the school corporation or qualified school, whether the parent of the student or the adult or emancipated student: (1) consents to the personal analysis, evaluation, or survey; or (2) declines the personal analysis, evaluation, or survey. A notice provided to a parent of a student or a student under this subsection must accurately summarize the contents and nature of the personal analysis, evaluation, or survey that will be provided to the student and indicate that a parent of a student or an adult or emancipated minor student has the right to review and inspect all materials related to the personal analysis, evaluation, or survey. The notice may be sent in an electronic format. If the school corporation or qualified school does not receive a response within ten (10) days after the notice, the student will receive the personal analysis, evaluation, or survey unless the parent or the adult or emancipated student subsequently opts out of the personal analysis, evaluation, or survey for the student. (d) Each school corporation or qualified school shall: (1) post a copy of a personal analysis, evaluation, or survey described in subsection (b) on the school corporation's or qualified school's website; and (2) send with each notice an explanation of the reasons that the school corporation or qualified school is administering the personal analysis, evaluation, or survey. (e) The department and the governing body shall give parents and students notice of the parents' and students' rights under this section. Sec. 5. A parent of a student or a student, if the student is an adult or emancipated minor, who is enrolled in a qualified school HEA 1447 — CC 1 7 may submit a complaint for a violation of this chapter under the grievance procedure maintained by the qualified school in accordance with section 6 of this chapter. Sec. 6. Each qualified school shall establish and maintain a grievance procedure for the resolution of a complaint submitted by a parent of a student or student, if the student is an adult or emancipated minor, under section 5 of this chapter. Sec. 7. The department shall: (1) develop guidance materials for school corporations and qualified schools to assist school corporations and qualified schools in implementing this chapter; and (2) post the guidance materials on the department's website. Sec. 8. Nothing in this section prohibits qualified schools from administering state or federally required assessments. Sec. 9. After June 30, 2023, if a school corporation or a qualified school contracts with a third party vendor to provide a personal analysis, survey, or evaluation described in section 3 of this chapter, the contract must include a provision stating that if the third party vendor does not comply with the requirements described in section 3 of this chapter, the third party vendor has committed a breach of contract. SECTION 4. IC 20-33-1.5 IS ADDED TO THE INDIANA CODE AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2023]: Chapter 1.5. Neutrality Regarding Certain Activities Sec. 1. As used in this chapter, "qualified school" has the meaning set forth in IC 20-26-21-1. Sec. 2. As used in this chapter, "state agency" has the meaning set forth in IC 4-13-1.4-2. Sec. 3. If a state agency, school corporation, or qualified school or an employee of a state agency, school corporation, or qualified school requires, makes part of a course, awards a grade or course credit, including extra credit, or otherwise incentivizes a student to engage in: (1) political activism; (2) lobbying; or (3) efforts to persuade members of the legislative or executive branch at the federal, state, or local level; the state agency, school corporation, or qualified school or the employee of the state agency, school corporation, or qualified school shall not require the student to adopt, affirm, affiliate, or take any action that would result in favoring any particular HEA 1447 — CC 1 8 position on the issue or issues involved without offering an alternative option for the student to complete the assignment or receive extra credit or other incentivization that allows for the favoring of an alternative position. SECTION 5. IC 35-49-3-3, AS AMENDED BY P.L.158-2013, SECTION 648, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JANUARY 1, 2024]: Sec. 3. (a) Except as provided in subsection (b) and section 4 of this chapter, a person who knowingly or intentionally: (1) disseminates matter to minors that is harmful to minors (as described in IC 35-49-2); (2) displays matter that is harmful to minors in an area to which minors have visual, auditory, or physical access, unless each minor is accompanied by the minor's parent or guardian; (3) sells, rents, or displays for sale or rent to any person matter that is harmful to minors within five hundred (500) feet of the nearest property line of a school or church; (4) engages in or conducts a performance before minors that is harmful to minors; (5) engages in or conducts a performance that is harmful to minors in an area to which minors have visual, auditory, or physical access, unless each minor is accompanied by the minor's parent or guardian; (6) misrepresents the minor's age for the purpose of obtaining admission to an area from which minors are restricted because of the display of matter or a performance that is harmful to minors; or (7) misrepresents that the person is a parent or guardian of a minor for the purpose of obtaining admission of the minor to an area where minors are being restricted because of display of matter or performance that is harmful to minors; commits a Level 6 felony. (b) This section does not apply if a person disseminates, displays, or makes available the matter described in subsection (a) through the Internet, computer electronic transfer, or a computer network unless: (1) the matter is obscene under IC 35-49-2-1; (2) the matter is child pornography under IC 35-42-4-4; or (3) the person distributes the matter to a child less than eighteen (18) years of age believing or intending that the recipient is a child less than eighteen (18) years of age. SECTION 6. IC 35-49-3-4, AS AMENDED BY P.L.266-2019, SECTION 16, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE HEA 1447 — CC 1 9 JANUARY 1, 2024]: Sec. 4. (a) It is a defense to a prosecution under section 3 of this chapter for the defendant to show: (1) that the matter was disseminated or that the performance was performed for legitimate scientific [deleted: or educational] purposes; (2) that the matter was disseminated or displayed to or that the performance was performed before the recipient by a bona fide [deleted: school,] college, university, museum, college library, or public library that qualifies for certain property tax exemptions under IC 6-1.1-10, or university library, or by an employee of such a school, college, university, museum, college library, or public library, or university library acting within the scope of the employee's employment; (3) that the defendant had reasonable cause to believe that the minor involved was eighteen (18) years of age or older and that the minor exhibited to the defendant a draft card, driver's license, birth certificate, or other official or apparently official document purporting to establish that the minor was eighteen (18) years of age or older; or (4) that the defendant was a salesclerk, motion picture projectionist, usher, or ticket taker, acting within the scope of the defendant's employment and that the defendant had no financial interest in the place where the defendant was so employed. (b) Except as provided in subsection (c), it is a defense to a prosecution under section 3 of this chapter if all the following apply: (1) A cellular telephone, another wireless or cellular communications device, or a social networking web site was used to disseminate matter to a minor that is harmful to minors. (2) The defendant is not more than four (4) years older or younger than the person who received the matter that is harmful to minors. (3) The relationship between the defendant and the person who received the matter that is harmful to minors was a dating relationship or an ongoing personal relationship. For purposes of this subdivision, the term "ongoing personal relationship" does not include a family relationship. (4) The crime was committed by a person less than twenty-two (22) years of age. (5) The person receiving the matter expressly or implicitly acquiesced in the defendant's conduct. (c) The defense to a prosecution described in subsection (b) does not apply if: (1) the image is disseminated to a person other than the person: (A) who sent the image; or HEA 1447 — CC 1 10 (B) who is depicted in the image; or (2) the dissemination of the image violates: (A) a protective order to prevent domestic or family violence or harassment issued under IC 34-26-5 (or, if the order involved a family or household member, under IC 34-26-2 or IC 34-4-5.1-5 before their repeal); (B) an ex parte protective order issued under IC 34-26-5 (or, if the order involved a family or household member, an emergency order issued under IC 34-26-2 or IC 34-4-5.1 before their repeal); (C) a workplace violence restraining order issued under IC 34-26-6; (D) a no contact order in a dispositional decree issued under IC 31-34-20-1, IC 31-37-19-1, or IC 31-37-5-6 (or IC 31-6-4-15.4 or IC 31-6-4-15.9 before their repeal) or an order issued under IC 31-32-13 (or IC 31-6-7-14 before its repeal) that orders the person to refrain from direct or indirect contact with a child in need of services or a delinquent child; (E) a no contact order issued as a condition of pretrial release, including release on bail or personal recognizance, or pretrial diversion, and including a no contact order issued under IC 35-33-8-3.6; (F) a no contact order issued as a condition of probation; (G) a protective order to prevent domestic or family violence issued under IC 31-15-5 (or IC 31-16-5 or IC 31-1-11.5-8.2 before their repeal); (H) a protective order to prevent domestic or family violence issued under IC 31-14-16-1 in a paternity action; (I) a no contact order issued under IC 31-34-25 in a child in need of services proceeding or under IC 31-37-25 in a juvenile delinquency proceeding; (J) an order issued in another state that is substantially similar to an order described in clauses (A) through (I); (K) an order that is substantially similar to an order described in clauses (A) through (I) and is issued by an Indian: (i) tribe; (ii) band; (iii) pueblo; (iv) nation; or (v) organized group or community, including an Alaska Native village or regional or village corporation as defined in or established under the Alaska Native Claims Settlement HEA 1447 — CC 1 11 Act (43 U.S.C. 1601 et seq.); that is recognized as eligible for the special programs and services provided by the United States to Indians because of their special status as Indians; (L) an order issued under IC 35-33-8-3.2; or (M) an order issued under IC 35-38-1-30. HEA 1447 — CC 1 Speaker of the House of Representatives President of the Senate President Pro Tempore Governor of the State of Indiana Date: Time: HEA 1447 — CC 1 [extracted by pdf-snapshot.ts with strike detection, 2026-09-27T07:50:05.539Z, https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1447/HB1447.04.ENRS.pdf, from saved file]

---
snapshot_id: b12590e5-2db2-535e-857b-4524fa9c9301
source_kind: public-record
url: https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1447/rollcalls/HB1447.520_S.pdf

Senate F IRST R EGULAR S ESSION 123 RD G ENERAL A SSEMBLY A PR 27, 2023 2:36:19 PM Roll Call 520: Conference Committee Report Passed HB 1447 - Donato Yea 39 Education matters. Nay 10 Conference Committee Report #1 Excused 0 Not Voting 1 Presiding: President Y EA - 39 Alexander Busch Garten Perfect Alting Byrne Gaskill Raatz Baldwin Charbonneau Glick Rogers Bassler Crane Holdman Sandlin Becker Crider Johnson Tomes Bohacek Deery Koch Walker G Bray Dernulc Leising Walker K Brown Donato Messmer Young Buchanan Doriot Mishler Zay Buck Freeman Niemeyer N AY - 10 Breaux Melton Qaddoura Yoder Ford J.D. Niezgodski Randolph Hunley Pol Taylor E XCUSED - 0 N OT V OTING - 1 Ford Jon [extracted by pdf-snapshot.ts with strike detection, 2026-09-27T07:50:06.298Z, https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1447/rollcalls/HB1447.520_S.pdf, from saved file]

---
snapshot_id: 75f0aece-f2fb-5fa3-b9d3-610e1b046485
source_kind: public-record
url: https://iga.in.gov/legislative/2023/bills/house/1447/details

IGA | House Bill 1447 (2023) Indiana General Assembly 2023 Session. House Bill 1447 Education matters. Enrolled House Bill (H) Authored by: Rep. Donna Schaibley. Co-Authored by: Rep. Julie McGuire, Rep. Becky Cash. Sponsored by: Sen. Stacey Donato, Sen. Jeff Raatz. Digest Provides that, if a school corporation or qualified school uses a third party vendor in providing certain personal analyses, evaluations, or surveys, the third party vendor and the school corporation or qualified school may not record, collect, or maintain the responses to or results of the analysis, evaluation, or survey in a manner that would identify the responses or results of an individual student. Provides that, if a school corporation or qualified school uses a third party vendor in providing the personal analysis, evaluation, or survey, the school corporation or qualified school must provide parents or students, as applicable, two ... View more [Bill details page for HB 1447 (2023), saved by browser from iga.in.gov on 2026-09-27.]