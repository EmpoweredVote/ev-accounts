You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-27-shadow-mishler-v04/labels/coder-1.json. Write JSON only, matching
codebook Part E, with "codebook_version": "0.4" and "coder_slot": 1. One row per
topic below. Every quoted string you write must be copied exactly from a source below.

## Codebook

# Empowered Vote — Stance & Quote Codebook

**Version:** 0.4 (DRAFT, 2026-09-25). It carries rulings Q1–Q9 (design spec §9.1) and the record
fields (confirm-basis spec). The annex
readings and examples are not yet ruled on. Every label records `codebook_version`.
**Clarified 2026-09-26 (still 0.3 — no new variable, the validator got more permissive):** the
record fields are required per instrument group, not per passage (V3 "Record fields", Part E), and V3
carries a worked two-passage vote example.
**Updated 2026-09-27 (0.3 → 0.3.1 — a new rule coders must apply, amendment-markup spec §5):** text
inside a `[deleted: …]` fence is removed from the law; it is never the provision, and a coder never
quotes it as `provision_quote` (V3 "Record fields").
**Updated 2026-09-27 (0.3.1 → 0.4 — V5 ruling, option B, Chris Andrews):** a record from **either
chamber of the same legislature** counts for the current seat (a senator's votes and bills from their
House years). A record from another level of government (a city council, a county, Congress) is still
valid for that office only. See V5.
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
| `in-term` | The act or statement dates from within a term of this office, or from the current campaign for it. **A record** (vote, sponsorship, authorship, a signed act) also counts as `in-term` when it dates from a term in **either chamber of the same legislature** (V5 ruling 2026-09-27, option B). |
| `pre-seating` | A vote or act from before the person held a seat in this body. A record from **another level of government** (a city council, a county, Congress) is valid for that office only. |
| `superseded-by-later` | A later passage from the same person states or acts differently. |
| `undated` | No date can be established. |

**Rules**
- A **record** has no age limit if it is chair-shaped against the served rung text.
- **Earlier chamber, same legislature (ruling 2026-09-27, option B).** A person moves between the two
  chambers of one legislature as the same person, and what they sponsored there is often what elected
  them to the other. So their earlier-chamber records are coded exactly like in-term records: the vote
  ladder (V4.1), the near-unanimous rule and `superseded-by-later` all apply unchanged. Code, not the
  coder, then checks that the earlier term is on file and that the page shows that term's chamber
  (CONFIRM `prior-service-unverified`, `chamber-not-evidenced`). A statement is not a record: the
  election-cycle rule below still decides it.
  - **[real]** John Kavanagh / `school-vouchers`: co-sponsored and voted for AZ HB 2853 (2022) in the
    House; a State Senator since 2023. → `in-term`; code the act on its content.
  - A record from a **different level** (city council → legislature, legislature → Congress) is
    `pre-seating`: the levers differ, so the ladder may not apply at the new level (scope is a per-rung
    question).
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

politician_id: 25becdfe-46ec-4a8a-88ec-8c85eed418b5  office_id: 109811e6-4a7d-4293-88d9-6dd9b90edd98
Ryan Mishler — Senator, Indiana (seated, level: state)
Current term: 2004-11-03 (precision: day) to present

## Topics (served ladder text — code against these words only)

### topic_key: taxes
topic_id: f7e5678d-dadd-4556-a2fc-446e24642ceb  served_revision_id: 44ac21e4-76ad-4318-a5c4-d0d744a8313e
Question: How should government balance what it collects in taxes against what it spends on public services?
  1. Significantly raise taxes on wealthy people and large companies to fund more public services
  2. Moderately raise taxes on wealthy people and large companies to fund existing services
  3. Keep the current tax system mostly as-is, with targeted adjustments — closing loopholes or granting narrow relief
  4. Cut taxes broadly, including the main rates most people pay
  5. Cut taxes as far as possible and shrink what government does

#### Annex

(no annex for this topic yet — apply the codebook alone)

## Sources

---
snapshot_id: c81f9d6a-5163-5e81-8afc-bf71e435f87d
source_kind: public-record
url: https://iga.in.gov/legislative/2022/bills/house/1002/details

IGA | House Bill 1002 (2022) Indiana General Assembly 2022 Session. House Bill 1002 Various tax matters. Enrolled House Bill (H) Authored by: Rep. Timothy Brown. Co-Authored by: Rep. Daniel Leonard, Rep. Timothy O'Brien, Rep. Chris Judy, Rep. Karen Engleman, Rep. Cindy Ledbetter, Rep. Martin Carbaugh, Rep. Dale DeVon, Rep. Julie Olthoff, Rep. Ann Vermilion, Rep. Randall Frye, Rep. Peggy Mayfield, Rep. J.D. Prescott, Rep. Bruce Borders, Rep. Jeff Ellington, Rep. Ryan Lauer, Rep. Ethan Manning, Rep. Mike Aylesworth, Rep. Robert Heaton, Rep. Sharon Negele, Rep. Jeffrey Thompson, Rep. Robert Cherry, Rep. Jim Lucas, Rep. John Young, Rep. Jerry Torr, Rep. Robert Behning, Rep. Harold Slager, Rep. Chris May, Rep. Jake Teshka, Rep. Matt Hostettler, Rep. Edmond Soliday, Rep. Edward Clere, Rep. Matt Lehman, Rep. Don Lehe, Rep. Donna Schaibley, Rep. Alan Morrison, Rep. Doug Miller, Rep. Jim Pressel, Rep. Craig Snow, Rep. David Abbott, Rep. Doug Gutwein, Rep. Dave Heine, Rep. Curt Nisly, Rep. Michelle Davis, Rep. Chuck Goodrich, Rep. Gregory Steuerwald, Rep. Jack Jordan, Rep. Elizabeth Rowray, Rep. Ben Smaltz. Sponsored by: Sen. Ryan Mishler, Sen. Travis Holdman, Sen. Lonnie Randolph. Digest Specifies that the amount of excess combined reserves that may be transferred to the pre-1996 account in 2022 may not exceed $2,500,000,000. Reduces the individual adjusted gross income tax rate from 3.23% in 2022 to 3.15% in 2023 and 2024. Phases down the individual adjusted gross income tax rate after 2024 depending on certain conditions being met. Allows a taxpayer to elect a special property tax valuation method for mini-mill equipment. (Current law allows the method to be used only for certain integrated steel mill and oil refinery/petrochemical equipment.) Repeals the utility receipts and utility services use taxes. Requires a ... View more [Bill details page for HB 1002 (2022), saved by browser from iga.in.gov on 2026-09-27.]

---
snapshot_id: 3fb9bf85-7b82-5c95-8b18-f9683c42c170
source_kind: public-record
url: https://iga.in.gov/pdf-documents/122/2022/house/bills/HB1002/rollcalls/HB1002.374_S.pdf

Senate S ECOND R EGULAR S ESSION 122 ND G ENERAL A SSEMBLY M AR 09, 2022 12:08:32 AM Roll Call 374: Conference Committee Report Passed HB 1002 - Mishler Yea 50 Various tax matters. Nay 0 Conference Committee Report #1 Excused 0 Not Voting 0 Presiding: President Y EA - 50 Alting Byrne Holdman Raatz Baldwin Charbonneau Koch Randolph Bassler Crane Kruse Rogers Becker Crider Lanane Sandlin Boehnlein Donato Leising Taylor Bohacek Doriot Melton Tomes Boots Ford J.D. Messmer Walker G Bray Ford Jon Mishler Walker K Breaux Freeman Niemeyer Yoder Brown Garten Niezgodski Young Buchanan Gaskill Perfect Zay Buck Glick Pol Busch Griffin Qaddoura N AY - 0 E XCUSED - 0 N OT V OTING - 0 [extracted by pdf-snapshot.ts with strike detection, 2026-09-27T07:50:03.016Z, https://iga.in.gov/pdf-documents/122/2022/house/bills/HB1002/rollcalls/HB1002.374_S.pdf, from saved file]

---
snapshot_id: 909c3da5-0b10-5bcb-8764-7ae863bde3be
source_kind: public-record
url: https://iga.in.gov/pdf-documents/122/2022/house/bills/HB1002/HB1002.04.ENRS.pdf

Second Regular Session of the 122nd General Assembly (2022) PRINTING CODE. Amendments: Whenever an existing statute (or a section of the Indiana Constitution) is being amended, the text of the existing provision will appear in this style type, additions will appear in this style type , and deletions will appear in [deleted: this style type.] Additions: Whenever a new statutory provision is being enacted (or a new constitutional provision adopted), the text of the new provision will appear in this style type . Also, the word NEW will appear in that style type in the introductory clause of each SECTION that adds a new provision to the Indiana Code or the Indiana Constitution. Conflict reconciliation: Text in a statute in this style type or [deleted: this style type] reconciles conflicts between statutes enacted by the 2021 Regular Session of the General Assembly. HOUSE ENROLLED ACT No. 1002 AN ACT to amend the Indiana Code concerning taxation. Be it enacted by the General Assembly of the State of Indiana: SECTION 1. IC 4-10-22-1.5, AS ADDED BY P.L.165-2021, SECTION 39, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE UPON PASSAGE]: Sec. 1.5. This section applies only in calendar year 2022. Notwithstanding any other law, if, after the calculation required by section 1(d) of this chapter, the budget agency certifies that the state's combined reserve balance as calculated in section 1(d) of this chapter exceeds two billion five hundred million dollars ($2,500,000,000), the budget agency, after budget committee review, shall transfer the amount of combined state reserves that exceed two billion five hundred million dollars ($2,500,000,000) to the pre-1996 account (as defined in IC 5-10.2-1-5.5) for the purposes of the pre-1996 account. However, the amount transferred under this section may not exceed two billion five hundred million dollars ($2,500,000,000). SECTION 2. IC 6-1.1-3-23.5 IS ADDED TO THE INDIANA CODE AS A NEW SECTION TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 23.5. (a) For purposes of this section: (1) "adjusted cost" has the meaning set forth in section 23(b)(1) of this chapter; (2) "depreciable personal property" has the meaning set forth in section 23(b)(2) of this chapter; HEA 1002 — CC 1 2 (3) "mini-mill" means a person, including a subsidiary of a corporation, that produces steel using an electric arc furnace in Indiana; (4) "permanently retired depreciable personal property" has the meaning set forth in section 23(b)(5) of this chapter; (5) "pool" has the meaning set forth in section 23(b)(6) of this chapter; (6) "mini-mill equipment" means depreciable personal property, other than special tools and permanently retired depreciable personal property, that is owned, leased, or used by a mini-mill or an entity that is at least fifty percent (50%) owned by an affiliate of a mini-mill in the production of steel; (7) "special tools" has the meaning set forth in section 23(b)(8) of this chapter; and (8) "year of acquisition" for purposes of applying the table in section 23(c) of this chapter, has the meaning set forth in section 23(b)(9) of this chapter. (b) Notwithstanding 50 IAC 4.2-4-4, 50 IAC 4.2-4-6, and 50 IAC 4.2-4-7, but subject to subsection (c), beginning with the January 1, 2023, assessment date, a taxpayer may elect to calculate the true tax value of the taxpayer's mini-mill equipment by multiplying the adjusted cost of that equipment by the applicable percentage set forth in the table designated as "Pool No. 5" under section 23(c) and 23(d) of this chapter. (c) A taxpayer may not make an election to calculate the true tax value of the taxpayer's mini-mill equipment under subsection (b) if there are any outstanding bond obligations that would be impaired as a result of the election, as certified by the department of local government finance. (d) The percentage factors in the table under section 23(c) of this chapter automatically reflect all adjustments for depreciation and obsolescence, including abnormal obsolescence, for mini-mill equipment. The equipment is entitled to all exemptions, credits, and deductions for which it qualifies. (e) The minimum valuation limitations under 50 IAC 4.2-4-9 do not apply to mini-mill equipment valued under this section. The value of the equipment is not included in the calculation of that minimum valuation limitation for the taxpayer's other assessable depreciable personal property in the taxing district. (f) An election to value mini-mill equipment under this section: (1) must be made by reporting the equipment under this section on a business personal property tax return; HEA 1002 — CC 1 3 (2) applies to all of the taxpayer's mini-mill equipment located in the state (whether owned or leased, or used as an integrated part of the equipment); and (3) is binding on the taxpayer for the assessment date for which the election is made. The department of local government finance shall prescribe the forms to make the election beginning with the January 1, 2023, assessment date. Any mini-mill equipment acquired by a taxpayer that has made an election under this section is valued under this section. (g) If fifty percent (50%) or more of the adjusted cost of a taxpayer's property that would, notwithstanding this section, be reported in a pool other than "Pool No. 5" (as designated under section 23 of this chapter) is attributable to mini-mill equipment, the taxpayer may elect to calculate the true tax value of all of that property as mini-mill equipment. The true tax value of property for which an election is made under this subsection is calculated under subsections (b) through (f). SECTION 3. IC 6-2.3 IS REPEALED [EFFECTIVE JULY 1, 2022]. (Utility Receipts Tax). SECTION 4. IC 6-3-2-1, AS AMENDED BY P.L.212-2018(ss), SECTION 20, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 1. (a) As used in this section, "pre-1996 account" has the meaning set forth in IC 5-10.2-1-5.5. (b) Each taxable year, a tax at the following rate of adjusted gross income is imposed upon the adjusted gross income of every resident person, and on that part of the adjusted gross income derived from sources within Indiana of every nonresident person: (1) For taxable years beginning before January 1, 2015, three and four-tenths percent (3.4%). (2) For taxable years beginning after December 31, 2014, and before January 1, 2017, three and three-tenths percent (3.3%). (3) For taxable years beginning after December 31, 2016, and before January 1, 2023, three and twenty-three hundredths percent (3.23%). (4) For taxable years beginning after December 31, 2022, and before January 1, 2025, three and fifteen hundredths percent (3.15%). (5) For taxable years beginning after December 31, 2024, and before January 1, 2027, the tax rate is determined as follows: (A) If the state general fund revenue collections for the state fiscal year ending June 30, 2024, exceed by at least HEA 1002 — CC 1 4 two percent (2%) the state general fund revenue collections for the state fiscal year ending June 30, 2023, as determined by the budget agency under subsection (e), the tax rate is three and one-tenth percent (3.1%). (B) If the state general fund revenue collections for the state fiscal year ending June 30, 2024, do not exceed by at least two percent (2%) the state general fund revenue collections for the state fiscal year ending June 30, 2023, as determined by the budget agency under subsection (e), the tax rate is three and fifteen hundredths percent (3.15%). (6) For taxable years beginning after December 31, 2026, and before January 1, 2029, the tax rate is determined as follows: (A) Three percent (3.0%) if the: (i) state general fund revenue collections for the state fiscal year ending June 30, 2026, exceed by at least two percent (2%) the state general fund revenue collections for the state fiscal year ending June 30, 2025, as determined by the budget agency under subsection (e); (ii) Indiana public retirement system determines under subsection (f) in 2026 that the balance of the pension stabilization fund (established by IC 5-10.4-2-5) is sufficient to pay the liabilities of the pre-1996 account without the need for an appropriation by the general assembly; and (iii) tax rate was decreased under subdivision (5)(A). (B) Three and ten hundredths percent (3.1%) if the: (i) state general fund revenue collections for the state fiscal year ending June 30, 2026, exceed by at least two percent (2%) the state general fund revenue collections for the state fiscal year ending June 30, 2025, as determined by the budget agency under subsection (e); (ii) Indiana public retirement system determines under subsection (f) in 2026 that the balance of the pension stabilization fund (established by IC 5-10.4-2-5) is sufficient to pay the liabilities of the pre-1996 account without the need for an appropriation by the general assembly; and (iii) tax rate was not decreased under subdivision (5)(A). (C) If clauses (A) and (B) do not apply, the tax rate in effect in the taxable year beginning after December 31, 2025, and before January 1, 2027, remains in effect. (7) For taxable years beginning after December 31, 2028, the HEA 1002 — CC 1 5 tax rate is determined as follows: (A) Two and nine tenths percent (2.9%) if the: (i) state general fund revenue collections for the state fiscal year ending June 30, 2028, exceed by at least two percent (2%) the state general fund revenue collections for the state fiscal year ending June 30, 2027, as determined by the budget agency under subsection (e); (ii) Indiana public retirement system determines under subsection (f) in 2028 that the balance of the pension stabilization fund (established by IC 5-10.4-2-5) is sufficient to pay the liabilities of the pre-1996 account without the need for an appropriation by the general assembly; and (iii) tax rate was decreased under subdivisions (5) and (6). (B) Three percent (3.0%) if the: (i) state general fund revenue collections for the state fiscal year ending June 30, 2028, exceed by at least two percent (2%) the state general fund revenue collections for the state fiscal year ending June 30, 2027, as determined by the budget agency under subsection (e); (ii) Indiana public retirement system determines under subsection (f) in 2028 that the balance of the pension stabilization fund (established by IC 5-10.4-2-5) is sufficient to pay the liabilities of the pre-1996 account without the need for an appropriation by the general assembly; and (iii) tax rate was decreased under subdivision (5) or (6), but not both. (C) Three and ten hundredths percent (3.1%) if the: (i) state general fund revenue collections for the state fiscal year ending June 30, 2028, exceed by at least two percent (2%) the state general fund revenue collections for the state fiscal year ending June 30, 2027, as determined by the budget agency under subsection (e); (ii) Indiana public retirement system determines under subsection (f) in 2028 that the balance of the pension stabilization fund (established by IC 5-10.4-2-5) is sufficient to pay the liabilities of the pre-1996 account without the need for an appropriation by the general assembly; and (iii) tax rate was not decreased under either subdivision HEA 1002 — CC 1 6 (5) or (6). (D) If clauses (A), (B), and (C) do not apply, the tax rate in effect in the taxable year beginning after December 31, 2027, and before January 1, 2029, remains in effect. [deleted: (b)] (c) Except as provided in section 1.5 of this chapter (before its expiration), each taxable year, a tax at the following rate of adjusted gross income is imposed on that part of the adjusted gross income derived from sources within Indiana of every corporation: (1) Before July 1, 2012, eight and five-tenths percent (8.5%). (2) After June 30, 2012, and before July 1, 2013, eight percent (8.0%). (3) After June 30, 2013, and before July 1, 2014, seven and five-tenths percent (7.5%). (4) After June 30, 2014, and before July 1, 2015, seven percent (7.0%). (5) After June 30, 2015, and before July 1, 2016, six and five-tenths percent (6.5%). (6) After June 30, 2016, and before July 1, 2017, six and twenty-five hundredths percent (6.25%). (7) After June 30, 2017, and before July 1, 2018, six percent (6.0%). (8) After June 30, 2018, and before July 1, 2019, five and seventy-five hundredths percent (5.75%). (9) After June 30, 2019, and before July 1, 2020, five and five-tenths percent (5.5%). (10) After June 30, 2020, and before July 1, 2021, five and twenty-five hundredths percent (5.25%). (11) After June 30, 2021, four and nine-tenths percent (4.9%). [deleted: (c)] (d) If for any taxable year a taxpayer is subject to different tax rates under subsection (b), the taxpayer's tax rate for that taxable year is the rate determined in the last STEP of the following STEPS: STEP ONE: Multiply the number of days in the taxpayer's taxable year that precede the day the rate changed by the rate in effect before the rate change. STEP TWO: Multiply the number of days in the taxpayer's taxable year that follow the day before the rate changed by the rate in effect after the rate change. STEP THREE: Divide the sum of the amounts determined under STEPS ONE and TWO by the number of days in the taxpayer's tax period. However, the rate determined under this subsection shall be rounded to the nearest one-hundredth of one percent (0.01%). HEA 1002 — CC 1 7 (e) After the end of each even-numbered state fiscal year that ends before January 1, 2029, the budget agency shall calculate and determine the percentage of revenue growth in state general fund revenue collections between each applicable state fiscal year under subsection (b)(5) through (b)(7) for purposes of determining whether the tax rate will decrease for a taxable year under subsection (b)(5) through (b)(7). The budget agency shall make the calculation not later than thirty (30) days after the end of each even-numbered state fiscal year. (f) Beginning after the end of the state fiscal year ending June 30, 2026, and after the end of each even-numbered state fiscal year that ends before January 1, 2029, for purposes of determining whether the tax rate will decrease for a taxable year under subsection (b)(6) through (b)(7), the Indiana public retirement system shall determine whether the balance of the pension stabilization fund (established by IC 5-10.4-2-5) is sufficient to pay the liabilities of the pre-1996 account without the need for an appropriation by the general assembly. The Indiana public retirement system shall make the calculation not later than thirty (30) days after the end of each even-numbered state fiscal year. (g) This subsection applies in calendar year 2024. Not later than September 1, the budget agency shall report the percentage of revenue growth determined under subsection (e) to the budget committee, and certify the results to the department. (h) This subsection applies in each even-numbered calendar year beginning after December 31, 2025, and ending before January 1, 2029. Not later than September 1 of each year, the budget agency, in collaboration with the Indiana public retirement system, shall report the: (1) applicable percentage of revenue growth determined under subsection (e); and (2) determination made for the applicable year under subsection (f); to the budget committee, and certify the results to the department. (i) Not later than November 1 of each year, if the results certified under subsection (g) or (h), as applicable, satisfy the conditions for a tax rate decrease as set forth in subsection (b)(5) through (b)(7), as applicable, the department shall provide notice of the determination and the applicable tax rate under subsection (b)(5) through (b)(7) on the department's Internet web site in a departmental notice. SECTION 5. IC 6-3-2-1.5, AS AMENDED BY P.L.212-2018(ss), HEA 1002 — CC 1 8 SECTION 21, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 1.5. (a) As used in this section, "qualified area" means: (1) a military base (as defined in IC 36-7-30-1(c)); (2) a military base reuse area established under IC 36-7-30; (3) the part of an economic development area established under IC 36-7-14.5-12.5 that is or formerly was a military base (as defined in IC 36-7-30-1(c)); or (4) a qualified military base enhancement area established under IC 36-7-34. (b) Except as provided in subsections (e) and (h), a tax at the lesser of: (1) the rate of five percent (5%) of adjusted gross income; or (2) the rate imposed under [deleted: section 1(b)] section 1(c) of this chapter; is imposed on that part of the adjusted gross income of a corporation that is derived from sources within a qualified area if the corporation locates all or part of its operations in a qualified area during the taxable year, as determined under subsection (g). The tax rate under this section applies to the taxable year in which the corporation locates its operations in the qualified area and to the next succeeding four (4) taxable years, and the tax rate shall be determined as provided in this subsection in each of those taxable years. (c) In the case of a corporation that locates all or part of its operations in a qualified military base enhancement area established under IC 36-7-34-4(1), the tax rate imposed under this section applies to the corporation only if the corporation meets at least one (1) of the following criteria: (1) The corporation is a participant in the technology transfer program conducted by the qualified military base (as defined in IC 36-7-34-3). (2) The corporation is a United States Department of Defense contractor. (3) The corporation and the qualified military base have a mutually beneficial relationship evidenced by a memorandum of understanding between the corporation and the United States Department of Defense. (d) In the case of a business that uses the services or commodities in a qualified military base enhancement area established under IC 36-7-34-4(2), the business must satisfy at least one (1) of the following criteria: (1) The business is a participant in the technology transfer HEA 1002 — CC 1 9 program conducted by the qualified military base (as defined in IC 36-7-34-3). (2) The business and the qualified military base have a mutually beneficial relationship evidenced by a memorandum of understanding between the business and the qualified military base (as defined in IC 36-7-34-3). (e) A taxpayer is not entitled to the tax rate described in subsection (b) to the extent that the taxpayer substantially reduces or ceases its operations at another location in Indiana in order to relocate its operations within the qualified area, unless: (1) the taxpayer had existing operations in the qualified area; and (2) the operations relocated to the qualified area are an expansion of the taxpayer's operations in the qualified area. (f) A determination under subsection (e) that a taxpayer is not entitled to the tax rate provided by this section as a result of a substantial reduction or cessation of operations applies to the taxable year in which the substantial reduction or cessation occurs and in all subsequent years. Determinations under this section shall be made by the department of state revenue. (g) The department of state revenue: (1) shall adopt rules under IC 4-22-2 to establish a procedure for determining the part of a corporation's adjusted gross income that was derived from sources within a qualified area; and (2) may adopt other rules that the department considers necessary for the implementation of this chapter. (h) The tax rate under this section applies only to a corporation that locates all or part of its operations in a qualified area before January 1, 2019. However, this subsection may not be construed to prevent the tax rate from applying to succeeding taxable years of a corporation after December 31, 2018, if the corporation locates all or part of its operations in a qualified area before January 1, 2019. (i) This section expires January 1, 2025. SECTION 6. IC 6-3-4.5-1, AS ADDED BY P.L.159-2021, SECTION 18, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 1. The following definitions apply throughout this chapter: (1) "Adjustment year" means the partnership taxable year described in Section 6225(d)(2) of the Internal Revenue Code. (2) "Administrative adjustment request" means an administrative adjustment request filed by a partnership under Section 6227 of the Internal Revenue Code. (3) "Affected year" means any taxable year for a taxpayer that is HEA 1002 — CC 1 10 affected by an adjustment under this chapter, regardless of whether the partnership has received an adjustment for that taxable year. (4) "Audited partnership" means a partnership subject to a partnership level audit resulting in a federal adjustment. (5) "Corporate partner" means a partner that is subject to the state adjusted gross income tax under [deleted: IC 6-3-2-1(b)] IC 6-3-2-1(c) or the financial institutions tax under IC 6-5.5-2-1. In the case of a partner that is a corporation described in IC 6-3-2-2.8(2) that also is subject to tax under [deleted: IC 6-3-2-1(b),] IC 6-3-2-1(c), the corporation is a corporate partner only to the extent that its income is subject to tax under [deleted: IC 6-3-2-1(b).] IC 6-3-2-1(c). (6) "Direct partner" means a partner that holds an interest directly in a partnership or pass through entity. (7) "Exempt partner" means a partner that is exempt from the adjusted gross income tax under IC 6-3-2-2.8(1) or the financial institutions tax under IC 6-5.5-2-7(4), except to the extent of unrelated business taxable income. (8) "Federal adjustment" means a change to an item or amount determined under the Internal Revenue Code or a change to any other tax attribute that is used by a taxpayer to compute state adjusted gross income taxes or financial institutions tax owed, whether that change results from action by the Internal Revenue Service, including a partnership level audit, or the filing of an amended federal return, a federal refund claim, or an administrative adjustment request by the taxpayer. A federal adjustment is positive to the extent that it increases state adjusted gross income as determined under IC 6-3 or IC 6-5.5 and is negative to the extent that it decreases state adjusted gross income as determined under IC 6-3 or IC 6-5.5. (9) "Federal adjustment reports" includes methods or forms required by the department for use by a taxpayer to report final federal adjustments for purposes of this chapter, including an amended Indiana tax return, information return, or uniform multistate report. (10) "Federal partnership representative" means a person the partnership designates for the taxable year as the partnership's representative, or the person the Internal Revenue Service has appointed to act as the federal partnership representative, pursuant to Section 6223(a) of the Internal Revenue Code. (11) "Final determination date" means the following: (A) Except as provided in clause (B) or (C), if the federal HEA 1002 — CC 1 11 adjustment arises from an Internal Revenue Service audit or other action by the Internal Revenue Service, the final determination date is the date on which the federal adjustment is a final determination under IC 6-3-4-6(d). (B) For federal adjustments arising from an Internal Revenue Service audit or other action by the Internal Revenue Service, if the taxpayer filed as a member of a consolidated tax return filed under IC 6-3-4-14, a combined return filed under IC 6-3-2-2 or IC 6-5.5-5-1, or a return combined by the department under IC 6-3-2-2(p), the final determination date means the first date on which no related federal adjustments arising from that audit remain to be finally determined, as described in clause (A), for the entire group. (C) If the federal adjustment results from filing an amended federal return, a federal refund claim, or an administrative adjustment request, the final determination date means the day on which the amended return, refund claim, administrative adjustment request, or other similar report was filed. (12) "Final federal adjustment" means a federal adjustment after the final determination date for that federal adjustment has passed. (13) "Indirect partner" means a partner in a partnership or pass through entity that itself holds an interest directly, or through another indirect partner, in a partnership or pass through entity. (14) "Internal Revenue Code" has the meaning set forth in IC 6-3-1-11. (15) "Nonresident partner" has the meaning provided in IC 6-3-4-12(n). (16) "Partner" means a person or entity that holds an interest directly or indirectly in a partnership or other pass through entity. (17) "Partner level adjustments report" means a report provided by a partnership to its partners as a result of a department action with regard to the partnership. A partner level adjustments report does not include an amended statement provided by a partnership or other entity as a result of an adjustment reported by the partnership. (18) "Partnership" has the meaning set forth in IC 6-3-1-19. (19) "Partnership level audit" means an examination by the Internal Revenue Service at the partnership level under Sections 6221 through 6241 of the Internal Revenue Code, as enacted by the Bipartisan Budget Act of 2015, Public Law 114-74, which results in federal adjustments. HEA 1002 — CC 1 12 (20) "Partnership return" means a return required to be filed by a partnership pursuant to IC 6-3-4-10. In the case of a partnership that is required to withhold tax or file a composite return pursuant to IC 6-3-4-12 or IC 6-5.5-2-8, the term also includes the returns or schedules required for tax withholding or composite filing. (21) "Pass through entity" means an entity defined in IC 6-3-1-35, other than a partnership, that is not subject to tax under IC 6-3. (22) "Reallocation adjustment" means a federal adjustment resulting from a partnership level audit or an administrative adjustment request that changes the shares of one (1) or more items of partnership income, gain, loss, expense, or credit allocated to direct partners. A positive reallocation adjustment means the portion of a reallocation adjustment that would increase federal adjusted gross income or federal taxable income for one (1) or more direct partners, and a negative reallocation adjustment means the portion of a reallocation adjustment that would decrease federal adjusted gross income or federal taxable income for one (1) or more direct partners, according to Section 6225 of the Internal Revenue Code and the regulations under that section. (23) "Resident partner" means a partner that is not a nonresident partner. (24) "Review year" means the taxable year of a partnership that is subject to a partnership level audit that results in federal adjustments. (25) "Statement" means a form or schedule prescribed by the department through which a pass through entity reports tax attributes to its owners or beneficiaries. (26) "Tax attribute" means any item of income, deduction, credit, receipts for apportionment, or other amount or status that determines a partner's liability under IC 6-3, IC 6-3.6, or IC 6-5.5. (27) "Taxable year" means, in the case of a partnership, the year or partial year for which a partnership files a return for state and federal purposes and, in the case of a partner, the taxable year in which the partner reports tax attributes from the partnership. (28) "Taxpayer" has the meaning set forth in IC 6-3-1-15 (in the case of the adjusted gross income tax) and IC 6-5.5-1-17 (in the case of the financial institutions tax) and, unless the context clearly indicates otherwise, includes a partnership subject to a partnership level audit or a partnership that has made an administrative adjustment request, as well as a tiered partner of that partnership. HEA 1002 — CC 1 13 (29) "Tiered partner" means any partner that is a partnership or pass through entity. (30) "Unrelated business taxable income" has the meaning set forth in Section 512 of the Internal Revenue Code. SECTION 7. IC 6-3-4.5-9, AS ADDED BY P.L.159-2021, SECTION 18, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 9. (a) Partnerships and partners shall report final federal adjustments arising from a partnership level audit or an administrative adjustment request and make payments as required under this section. (b) Final federal adjustments subject to the requirements of this section, except those subject to a properly made election under subsection (c), shall be reported as follows: (1) Not later than the applicable deadline, the partnership shall: (A) file an amended partnership return for the review year and any other taxable year affected by the final federal adjustments with the department as provided in section 8 of this chapter and provide any other information required by the department; (B) notify each of its direct partners of their distributive share of the final federal adjustments as provided in section 8 of this chapter for all affected taxable years for which the partnership filed an amended partnership return by an amended statement or a report in the form and manner prescribed by the department; and (C) file an amended composite return for direct partners and an amended withholding return for direct partners for the review year and any affected taxable years as otherwise required by IC 6-3-4-12 or IC 6-5.5-2-8 and pay any tax due for the taxable years. (2) Each direct partner that is subject to tax under IC 6-3, IC 6-3.6, or IC 6-5.5 shall, on or before the applicable deadline: (A) file an amended return as provided in section 8 of this chapter reporting their distributive share of the adjustments reported to them under subdivision (1)(B) for the taxable year in which affected taxable year attributes would be reported by the direct partner as provided in section 8 of this chapter; and (B) pay any additional amount of tax due as if final federal partnership adjustments had been properly reported, less any credit for related amounts paid or withheld and remitted on behalf of the direct partner. (3) Each tiered partner shall treat any final federal partnership adjustments under this section in a manner consistent with the HEA 1002 — CC 1 14 treatment of tiered partners under section 8 of this chapter. (c) Except as provided in subsection (d), an audited partnership making an election under this subsection shall: (1) not later than the applicable deadline, file an amended partnership return for the review year and for any other affected taxable year elected by the audited partnership, including information as required by the department, and notify the department that it is making the election under this subsection; and (2) not later than ninety (90) days after the applicable deadline, pay an amount, determined as follows, in lieu of taxes owed by its direct or indirect partners: (A) Exclude from final federal adjustments the distributive share of these adjustments reported to a direct exempt partner that is not unrelated business income. (B) For the total distributive shares of the remaining final federal adjustments reported to direct corporate partners and to direct exempt partners, apportion and allocate such adjustments as provided under IC 6-3-2-2 or IC 6-3-2-2.2 (in the case of the adjusted gross income tax) or IC 6-5.5-4 (in the case of the financial institutions tax), and multiply the resulting amount by the tax rate for the taxable year under [deleted: IC 6-3-2-1(b),] IC 6-3-2-1(c), IC 6-3-2-1.5, or IC 6-5.5-2-1, as applicable. (C) For the total distributive shares of the remaining final federal adjustments reported to nonresident direct partners other than corporate partners, determine the amount of such adjustments which is Indiana source income under IC 6-3-2-2 or IC 6-3-2-2.2, and multiply the resulting amount by the tax rate under [deleted: IC 6-3-2-1(a),] IC 6-3-2-1(b), and if applicable IC 6-3.6. If a partnership is unable to determine whether a nonresident is subject to tax under IC 6-3.6, or to determine in what county the nonresident is subject to tax under IC 6-3.6, tax shall also be imposed at the highest rate for which a county imposes a tax under IC 6-3.6 for the taxable year. (D) For the total distributive shares of the remaining final federal adjustments reported to tiered partners: (i) determine the amount of any adjustment that is of a type that it would be subject to sourcing in Indiana under IC 6-3-2-2, IC 6-3-2-2.2, or IC 6-5.5-4, as applicable, and determine the portion of this amount that would be sourced to Indiana; HEA 1002 — CC 1 15 (ii) determine the amount of any adjustment that is of a type that it would not be subject to sourcing to Indiana by a nonresident partner under IC 6-3-2-2, IC 6-3-2-2.2, or IC 6-5.5-4, as applicable; (iii) determine the portion of the amount determined under item (ii) that can be established, as prescribed by the department by rule under IC 4-22-2, to be properly allocable to nonresident indirect partners or other partners not subject to tax on the adjustments; and (iv) multiply the sum of the amounts determined in items (i) and (ii) reduced by the amount determined in item (iii) by the highest combined rate for the review year under [deleted: IC 6-3-2-1(a)] IC 6-3-2-1(b) and IC 6-3.6 for any county, the rate under [deleted: IC 6-3-2-1(b),] IC 6-3-2-1(c), or the rate under 6-5.5-2-1 for the taxable year, whichever is highest. (E) For the total distributive shares of the remaining final federal adjustments reported to resident individual, estate, or trust direct partners, multiply that amount by the tax rate under [deleted: IC 6-3-2-1(a)] IC 6-3-2-1(b) and IC 6-3.6. If a partnership does not reasonably ascertain the county of residence for an individual direct partner, the rate under IC 6-3.6 for that partner shall be treated as the highest rate imposed in any county under IC 6-3.6 for the taxable year. (F) Add the amounts determined in clauses (B), (C), (D)(iv), and (E). For purposes of determining interest and penalties, the due date of payment shall be the due date of the partnership's return under IC 6-3-4-10 for the taxable year, determined without regard to any extensions. If a partnership has made an election under this chapter to report and remit all tax otherwise due at the partnership level for a taxable year, the partnership shall be considered to have made a timely election under this subsection with regard to any changes arising from an amended return under this section for that taxable year. (d) Final federal adjustments subject to an election under subsection (c) shall not include: (1) the distributive share of final federal adjustments that would constitute income derived from a partnership to any direct or indirect partner that is a corporation taxable under [deleted: IC 6-3-2-1(b),] IC 6-3-2-1(c), IC 6-3-2-1.5, or IC 6-5.5-2-1 and is considered unitary to the partnership; (2) any final federal adjustments resulting from an administrative adjustment request; or HEA 1002 — CC 1 16 (3) any other circumstances that the department determines would result in avoidance or evasion of any tax otherwise due from one (1) or more partners under IC 6-3 or IC 6-5.5. (e) Notwithstanding IC 6-3-4-11, an audited partnership not otherwise subject to any reporting or payment obligations to Indiana that makes an election under subsection (c) consents to be subject to Indiana law related to reporting, assessment, payment, and collection of Indiana tax calculated under the election. SECTION 8. IC 6-3-4.5-18, AS ADDED BY P.L.159-2021, SECTION 18, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 18. (a) If a partnership or tiered partner is required to issue a report, issue an amended statement, or issue other information to a partner, owner, or beneficiary under this chapter, and does not issue such report, statement, or information within the period such issuance is required under this chapter, the partnership or tiered partner shall be liable for any tax that otherwise may be due from the partner, owner, or beneficiary, notwithstanding any other provision in IC 6-3 or IC 6-5.5. The tax rate under this section shall be computed at the highest rate for the taxable year under: (1) [deleted: IC 6-3-2-1(a),] IC 6-3-2-1(b), plus the highest rate imposed in any county under IC 6-3.6; (2) [deleted: IC 6-3-2-1(b);] IC 6-3-2-1(c); or (3) IC 6-5.5-2-1; unless the partnership or tiered partner can establish that a lower rate should apply, the partnership or tiered partner has made an election to be subject to tax under sections 6, 8, or 9 of this chapter, or to the extent the partnership, tiered partner, or the department can determine that the tax was otherwise properly reported and remitted. Such tax shall be considered to be due on the due date of the partnership's or tiered partner's return for the taxable year, determined without regard to extensions. (b) If a partnership or tiered partner issues the report, amended statement, or other information: (1) to an address that the partnership or tiered partner knows or reasonably should know is incorrect; or (2) if the report, amended statement, or other information not described in subdivision (1) is returned and the partnership or tiered partner: (A) fails to take reasonable steps to determine a proper address for reissuance within thirty (30) days after the report, amended statement, or other information is returned; or (B) takes such steps and fails to reissue the report to a proper HEA 1002 — CC 1 17 address within thirty (30) days after the report, amended statement, or other information is returned; such report, amended statement, or other information shall be considered to have not been issued for purposes of this section. (c) The department may issue a proposed assessment under this section not later than three (3) years after the department receives a return or amended return from the partnership or tiered partner for which the partnership or tiered partner fails to issue reports, amended statements, or other information. (d) If: (1) a direct or indirect partner files and remits the tax otherwise due under this section, the assessment to the partnership under this section shall be reduced by the portion of the tax attributable to the direct or indirect partner; and (2) a partnership or tiered partner files and remits the tax under this section, such tax shall be treated as payment of tax to the direct or indirect partners. However, in no event shall the direct or indirect partners be permitted a refund of tax paid by a partnership or tiered partner under this section unless otherwise permitted under this chapter or IC 6-8.1-9-1. (e) Nothing in this section shall be construed to relieve a partnership or tiered partner from any duty to issue a report, amended statement, or other information otherwise required under this chapter or under any other provision of IC 6-3 or IC 6-5.5. If a partnership or tiered partner issues a report, amended statement, or other information provided under this chapter after the date otherwise required for issuance, the department may grant relief to any tiered partner, direct partner, or indirect partner affected by the late issuance, including extension of applicable deadlines. SECTION 9. IC 6-3.1-29-11, AS ADDED BY P.L.191-2005, SECTION 15, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 11. As used in this chapter, "state tax liability" means a taxpayer's total tax liability that is incurred under: (1) IC 6-3-1 through IC 6-3-7 (the adjusted gross income tax); (2) IC 6-5.5 (the financial institutions tax); (3) IC 27-1-18-2 (the insurance premiums tax); and (4) IC 6-2.3 (the utility receipts tax) (before its repeal); as computed after the application of the credits that under IC 6-3.1-1-2 are to be applied before the credit provided by this chapter. SECTION 10. IC 6-3.1-29-14, AS AMENDED BY P.L.122-2006, SECTION 12, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 14. (a) A taxpayer that: HEA 1002 — CC 1 18 (1) is awarded a tax credit under this chapter by the corporation; and (2) complies with the conditions set forth in this chapter and the agreement entered into by the corporation and the taxpayer under this chapter; is entitled to a credit against the taxpayer's state tax liability for a taxable year in which the taxpayer places into service an integrated coal gasification powerplant or a fluidized bed combustion technology and for the taxable years provided in section 16 of this chapter. (b) A tax credit awarded under this chapter must be applied against the taxpayer's state tax liability in the following order: (1) Against the taxpayer's liability incurred under IC 6-3-1 through IC 6-3-7 (the adjusted gross income tax). (2) Against the taxpayer's liability incurred under IC 6-5.5 (the financial institutions tax). (3) Against the taxpayer's liability incurred under IC 27-1-18-2 (the insurance premiums tax). (4) Against the taxpayer's liability incurred under IC 6-2.3 (the utility receipts tax) (before its repeal). SECTION 11. IC 6-3.1-29-16, AS AMENDED BY P.L.122-2006, SECTION 14, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 16. (a) A credit awarded under section 15 of this chapter must be taken in ten (10) annual installments, beginning with the year in which the taxpayer places into service an integrated coal gasification powerplant or a fluidized bed combustion technology. (b) Subject to section 20 of this chapter, the amount of an annual installment of the credit awarded under section 15 of this chapter is equal to the amount determined in the last of the following STEPS: STEP ONE: Determine the lesser of: (A) the credit amount determined under section 15 of this chapter, divided by ten (10); or (B) the greater of: (i) the taxpayer's total state tax liability for the taxable year, multiplied by twenty-five percent (25%); or (ii) the taxpayer's liability for the utility receipts tax imposed under IC 6-2.3 (before its repeal) for the taxable year. STEP TWO: Multiply the STEP ONE amount by the percentage of Indiana coal used in the taxpayer's integrated coal gasification powerplant or fluidized bed combustion technology in the taxable year for which the annual installment of the credit is allowed. (c) If the credit allowed by this chapter is available to a member of an affiliated group of corporations filing a consolidated return under HEA 1002 — CC 1 19 IC 6-2.3-6-5 (before its repeal) or IC 6-3-4-14, the credit shall be applied against the state tax liability of the affiliated group. SECTION 12. IC 6-8.1-1-1, AS AMENDED BY P.L.165-2021, SECTION 120, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 1. "Listed taxes" or "taxes" includes only the pari-mutuel taxes (IC 4-31-9-3 through IC 4-31-9-5); the supplemental wagering tax (IC 4-33-12); the riverboat wagering tax (IC 4-33-13); the slot machine wagering tax (IC 4-35-8); the type II gambling game excise tax (IC 4-36-9); the gross income tax (IC 6-2.1) (repealed); the utility receipts and utility services use taxes (IC 6-2.3) (repealed); the state gross retail and use taxes (IC 6-2.5); the adjusted gross income tax (IC 6-3); the supplemental net income tax (IC 6-3-8) (repealed); the county adjusted gross income tax (IC 6-3.5-1.1) (repealed); the county option income tax (IC 6-3.5-6) (repealed); the county economic development income tax (IC 6-3.5-7) (repealed); the local income tax (IC 6-3.6); the auto rental excise tax (IC 6-6-9); the financial institutions tax (IC 6-5.5); the gasoline tax (IC 6-6-1.1); the special fuel tax (IC 6-6-2.5); the motor carrier fuel tax (IC 6-6-4.1); a motor fuel tax collected under a reciprocal agreement under IC 6-8.1-3; the vehicle excise tax (IC 6-6-5); the aviation fuel excise tax (IC 6-6-13); the commercial vehicle excise tax (IC 6-6-5.5); the excise tax imposed on recreational vehicles and truck campers (IC 6-6-5.1); the hazardous waste disposal tax (IC 6-6-6.6) (repealed); the heavy equipment rental excise tax (IC 6-6-15); the vehicle sharing excise tax (IC 6-6-16); the cigarette tax (IC 6-7-1); the closed system cartridge tax (IC 6-7-2-7.5); the electronic cigarette tax (IC 6-7-4); the beer excise tax (IC 7.1-4-2); the liquor excise tax (IC 7.1-4-3); the wine excise tax (IC 7.1-4-4); the hard cider excise tax (IC 7.1-4-4.5); the petroleum severance tax (IC 6-8-1); the various innkeeper's taxes (IC 6-9); the various food and beverage taxes (IC 6-9); the county admissions tax (IC 6-9-13 and IC 6-9-28); the oil inspection fee (IC 16-44-2); the penalties assessed for oversize vehicles (IC 9-20-3 and IC 9-20-18); the fees and penalties assessed for overweight vehicles (IC 9-20-4 and IC 9-20-18); and any other tax or fee that the department is required to collect or administer. SECTION 13. IC 6-8.1-5-2, AS AMENDED BY P.L.159-2021, SECTION 33, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 2. (a) Except as otherwise provided in this section and section 2.5 of this chapter, the department may not issue a proposed assessment under section 1 of this chapter more than three (3) years after the latest of the date the return is filed, or the following: (1) The due date of the return. HEA 1002 — CC 1 20 (2) In the case of a return filed for the state gross retail or use tax, the gasoline use tax, the gasoline tax (including the inventory tax), the special fuel tax (including the inventory tax), the motor carrier fuel tax (including the inventory tax), the oil inspection fee, the cigarette tax, the tobacco products tax, any county innkeeper's taxes imposed under IC 6-9, any food and beverage taxes imposed under IC 6-9, any county or local admissions taxes imposed under IC 6-9, or the petroleum severance tax, the end of the calendar year which contains the taxable period for which the return is filed. (3) In the case of the use tax, three (3) years from the end of the calendar year in which the first taxable use, other than an incidental nonexempt use, of the property occurred. (b) If a person files a return for the utility receipts tax (IC 6-2.3) (repealed), adjusted gross income tax (IC 6-3), supplemental net income tax (IC 6-3-8) (repealed), county adjusted gross income tax (IC 6-3.5-1.1) (repealed), county option income tax (IC 6-3.5-6) (repealed), local income tax (IC 6-3.6), or financial institutions tax (IC 6-5.5) that understates the person's income, as that term is defined in the particular income tax law, by at least twenty-five percent (25%), the proposed assessment limitation is six (6) years instead of the three (3) years provided in subsection (a). (c) In the case of the vehicle excise tax (IC 6-6-5), the tax shall be assessed as provided in IC 6-6-5 and shall include the penalties and interest due on all listed taxes not paid by the due date. A person that fails to properly register a vehicle as required by IC 9-18 (before its expiration) or IC 9-18.1 and pay the tax due under IC 6-6-5 is considered to have failed to file a return for purposes of this article. (d) In the case of the commercial vehicle excise tax imposed under IC 6-6-5.5, the tax shall be assessed as provided in IC 6-6-5.5 and shall include the penalties and interest due on all listed taxes not paid by the due date. A person that fails to properly register a commercial vehicle as required by IC 9-18 (before its expiration) or IC 9-18.1 and pay the tax due under IC 6-6-5.5 is considered to have failed to file a return for purposes of this article. (e) In the case of the excise tax imposed on recreational vehicles and truck campers under IC 6-6-5.1, the tax shall be assessed as provided in IC 6-6-5.1 and must include the penalties and interest due on all listed taxes not paid by the due date. A person that fails to properly register a recreational vehicle as required by IC 9-18 (before its expiration) or IC 9-18.1 and pay the tax due under IC 6-6-5.1 is considered to have failed to file a return for purposes of this article. A HEA 1002 — CC 1 21 person that fails to pay the tax due under IC 6-6-5.1 on a truck camper is considered to have failed to file a return for purposes of this article. (f) In the case of a credit against a listed tax based on payments of taxes to a state or local jurisdiction outside Indiana or payments of amounts that are subsequently refunded or returned, a proposed assessment for the refunded or returned credit must be issued by the later of: (1) the date by which a proposed assessment must be issued under this section; or (2) one hundred eighty (180) days from the date the taxpayer notifies the department of the refund or return of payment. For purposes of this subsection, if a taxpayer receives a refund of an amount paid by or on behalf of the taxpayer for a listed tax, that refund shall not be considered the payment of an amount that is subsequently refunded or returned. (g) If a person files a fraudulent, unsigned, or substantially blank return, or if a person does not file a return, there is no time limit within which the department must issue its proposed assessment. (h) If any part of a listed tax has been erroneously refunded by the department, the erroneous refund may be recovered through the assessment procedures established in this chapter. An assessment issued for an erroneous refund must be issued within the later of: (1) the period for which an assessment could otherwise be issued under this section; or (2) whichever is applicable: (A) within two (2) years after making the refund; or (B) within five (5) years after making the refund if the refund was induced by fraud or misrepresentation. (i) If, before the end of the time within which the department may make an assessment, the department and the person agree to extend that assessment period, the period may be extended according to the terms of a written agreement signed by both the department and the person. The agreement must contain: (1) the date to which the extension is made; and (2) a statement that the person agrees to preserve the person's records until the extension terminates. The department and a person may agree to more than one (1) extension under this subsection. (j) Except as otherwise provided in subsection (k), if a taxpayer's federal taxable income, federal adjusted gross income, or federal income tax liability for a taxable year is modified due to a modification as provided under IC 6-3-4-6(c) and IC 6-3-4-6(d) (for the adjusted HEA 1002 — CC 1 22 gross income tax), or a modification or alteration as provided under IC 6-5.5-6-6(c) and IC 6-5.5-6-6(e) (for the financial institutions tax), then the date by which the department must issue a proposed assessment under section 1 of this chapter for tax imposed under IC 6-3 is extended to six (6) months after the date on which the notice of modification is filed with the department by the taxpayer. (k) The following apply: (1) This subsection applies to partnerships whose taxable year: (A) begins after December 31, 2017; (B) ends after August 12, 2018; or (C) begins after November 2, 2015, and before January 1, 2018, and for which a valid election under United States Treasury Regulation 301.9100-22 is in effect; and to the partners of such partnerships, including any partners, shareholders, or beneficiaries of a pass through entity that is a partner in such partnership. (2) Notwithstanding any other provision of this article, if a partnership is subject to federal income tax liability or a federal tax adjustment at the partnership level as the result of a modification under Sections 6221 through 6241 of the Internal Revenue Code, the date on which the department must issue a proposed assessment to either the partners or the partnership shall be the later of: (A) the date on which a proposed assessment must otherwise be issued to the partner or the partnership under this section or IC 6-3-4.5 with regard to the taxable year of the partnership to which the modification is taxed at the partnership level; or (B) December 31, 2021. (3) For purposes of this section and IC 6-8.1-9-1, a modification under this subsection shall be considered a modification to the federal taxable income, federal adjusted gross income, or federal income tax liability of both the partners and the partnership within the meaning of IC 6-3-4-6 and IC 6-5.5-6-6, and shall be considered to be included in the federal taxable income or federal adjusted gross income of both the partners and partnerships for purposes of this article and IC 6-5.5. (4) If a modification made to a partnership for federal income tax purposes is reported to the partners to determine the partners' respective federal taxable income, federal adjusted gross income, or federal income tax liability, including reporting to partners as the result of an election made under Section 6226 of the Internal Revenue Code, subdivision (2) shall not apply, and those HEA 1002 — CC 1 23 modifications shall be treated as modifications to the partners' federal taxable income, federal adjusted gross income, or federal income tax liability for purposes of the following: (A) This section. (B) IC 6-3-4-6. (C) IC 6-5.5-6-6. (D) IC 6-8.1-9-1. SECTION 14. IC 6-8.1-17-1, AS ADDED BY P.L.212-2018(ss), SECTION 29, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 1. As used in this chapter, "income tax return" means any of the following: (1) An individual income tax return under IC 6-3. (2) A corporate income tax return under IC 6-3. (3) A financial institutions tax return under IC 6-5.5. (4) A utility receipts tax return under IC 6-2.3 (before its repeal). (5) A claim for refund of any tax described in subdivisions (1) through (4). SECTION 15. IC 8-1-2-4.2 IS ADDED TO THE INDIANA CODE AS A NEW SECTION TO READ AS FOLLOWS [EFFECTIVE UPON PASSAGE]: Sec. 4.2. (a) This section applies to a utility that is subject to the: (1) utility receipts tax under IC 6-2.3; and (2) jurisdiction of the commission for the approval of rates and charges; on January 1, 2022. (b) Not later than May 1, 2022, a utility shall file with the commission a rate adjustment that adjusts the utility's rates and charges to reflect the repeal of the utility receipts tax (IC 6-2.3, before its repeal) in HEA 1002-2022 by the general assembly, independent of any other matters related to the utility's revenue requirement. A rate adjustment approved under this section shall operate on a prospective basis. (c) A rate adjustment under this section: (1) applies to each rate or charge in effect at the time of the filing that includes recovery of the utility receipts tax; and (2) shall be calculated to remove the amount of the utility receipts tax that each existing rate or charge was designed to recover based on the utility receipts tax rate in effect at the time the rate or charge was approved. (d) The commission shall approve a rate adjustment under this section if the commission finds that the rate adjustment has been calculated correctly under subsection (c)(2). If the rate adjustment HEA 1002 — CC 1 24 under this section has not been calculated correctly under subsection (c)(2), the commission shall notify the utility of the defect and require the utility to correct the calculation. (e) A rate adjustment under this section takes effect upon the effective date of the repeal of the utility receipts tax (IC 6-2.3, before its repeal) in HEA 1002-2022, pending approval of a utility's filing under this section. (f) Upon a rate adjustment taking effect under subsection (e), the utility shall provide notice to all affected customers in each of the next two (2) regular billing cycles that the adjustment in rates or charges reflects the repeal of the utility receipts tax (IC 6-2.3, before its repeal) in HEA 1002-2022 by the general assembly. Notice provided under this subsection must include the amount of the adjustment reflected in the bill. (g) This section shall not be construed to limit the commission's authority to: (1) initiate proceedings; or (2) take actions; to ensure just and reasonable rates in connection with the repeal of the utility receipts tax (IC 6-2.3, before its repeal) in HEA 1002-2022 by the general assembly. SECTION 16. IC 8-1-2-4.3 IS ADDED TO THE INDIANA CODE AS A NEW SECTION TO READ AS FOLLOWS [EFFECTIVE UPON PASSAGE]: Sec. 4.3. (a) This section applies to a utility that is: (1) subject to the utility receipts tax under IC 6-2.3; and (2) not under the jurisdiction of the commission for the approval of rates and charges; on January 1, 2022. (b) A utility shall adjust the utility's rates and charges to reflect the repeal of the utility receipts tax (IC 6-2.3, before its repeal) in HEA 1002-2022 by the general assembly. A rate or charge adjustment under this section shall operate on a prospective basis. (c) A rate or charge adjustment under this section: (1) applies to each rate or charge in effect at the time of the adjustment that includes recovery of the utility receipts tax; and (2) shall be calculated to remove the amount of the utility receipts tax that each existing rate or charge was designed to recover based on the utility receipts tax rate in effect at the time the rate or charge was established. (d) The utility shall provide notice to all affected customers in HEA 1002 — CC 1 25 each of the next two (2) regular billing cycles that the adjustment in rates or charges reflects the repeal of the utility receipts tax (IC 6-2.3, before its repeal) in HEA 1002-2022 by the general assembly. Notice provided under this subsection must include the amount of the adjustment reflected in the bill. SECTION 17. IC 8-1-34-23, AS AMENDED BY P.L.149-2016, SECTION 36, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2022]: Sec. 23. (a) Except as provided in subsection (b), the holder of a certificate under this chapter shall, at the end of each calendar quarter, determine under subsections (c) and (d) the gross revenue received during that quarter from the holder's provision of video service in each unit included in the holder's service area under the certificate. (b) This subsection applies to a holder or other provider providing video service in a unit in which a provider of video service is required on June 30, 2006, to pay a franchise fee based on a percentage of gross revenues. The holder's or provider's gross revenue shall be determined as follows: (1) If only one (1) local franchise is in effect on June 30, 2006, the holder or provider shall determine gross revenue as the term is defined in the local franchise in effect on June 30, 2006. (2) If: (A) more than one (1) local franchise is in effect on June 30, 2006; and (B) the holder or provider is subject to a local franchise in the unit on June 30, 2006; the holder or provider shall determine gross revenue as the term is defined in the local franchise to which the holder or provider is subject on June 30, 2006. (3) If: (A) more than one (1) local franchise is in effect on June 30, 2006; and (B) the holder is not subject to a local franchise in the unit on June 30, 2006; the holder shall determine gross revenue as the term is defined in the local franchise in effect on June 30, 2006, that is most favorable to the unit. (c) This subsection does not apply to a holder that is required to determine gross revenue under subsection (b). The holder shall include the following in determining the gross revenue received during the quarter with respect to a particular unit: (1) Fees and charges charged to subscribers for video service HEA 1002 — CC 1 26 provided by the holder. Fees and charges under this subdivision include the following: (A) Recurring monthly charges for video service. (B) Event based charges for video service, including pay per view and video on demand charges. (C) Charges for the rental of set top boxes and other equipment. (D) Service charges related to the provision of video service, including activation, installation, repair, and maintenance charges. (E) Administrative charges related to the provision of video service, including service order and service termination charges. (2) Revenue received by an affiliate of the holder from the affiliate's provision of video service, to the extent that treating the revenue as revenue of the affiliate, instead of revenue of the holder, would have the effect of evading the payment of fees that would otherwise be paid to the unit. However, revenue of an affiliate may not be considered revenue of the holder if the revenue is otherwise subject to fees to be paid to the unit. (d) This subsection does not apply to a holder that is required to determine gross revenue under subsection (b). The holder shall not include the following in determining the gross revenue received during the quarter with respect to a particular unit: (1) Revenue not actually received, regardless of whether it is billed. Revenue described in this subdivision includes bad debt. (2) Revenue received by an affiliate or any other person in exchange for supplying goods and services used by the holder to provide video service under the holder's certificate. (3) Refunds, rebates, or discounts made to subscribers, advertisers, the unit, or other providers leasing access to the holder's facilities. (4) Revenue from providing service other than video service, including revenue from providing: (A) telecommunications service (as defined in 47 U.S.C. 153); (B) information service (as defined in 47 U.S.C. 153), other than video service; or (C) any other service not classified as cable service or video programming by the Federal Communications Commission. (5) Any fee imposed on the holder under this chapter that is passed through to and paid by subscribers, including the franchise fee: HEA 1002 — CC 1 27 (A) imposed under section 24 of this chapter for the quarter immediately preceding the quarter for which gross revenue is being computed; and (B) passed through to and paid by subscribers during the quarter for which gross revenue is being computed. (6) Revenue from the sale of video service for resale in which the purchaser collects a franchise fee under: (A) this chapter; or (B) a local franchise agreement in effect on July 1, 2006; from the purchaser's customers. This subdivision does not limit the authority of a unit, or the commission on behalf of a unit, to impose a tax, fee, or other assessment upon the purchaser under 47 U.S.C. 542(h). (7) Any tax of general applicability: (A) imposed on the holder or on subscribers by a federal, state, or local governmental entity; and (B) required to be collected by the holder and remitted to the taxing entity; including the state gross retail and use taxes (IC 6-2.5) and the utility receipts tax (IC 6-2.3) (before its repeal). (8) Any forgone revenue from providing free or reduced cost cable video service to any person, including: (A) employees of the holder; (B) the unit; or (C) public institutions, public schools, or other governmental entities, as required or permitted by this chapter or by federal law. However, any revenue that the holder chooses to forgo in exchange for goods or services through a trade or barter arrangement shall be included in gross revenue. (9) Revenue from the sale of: (A) capital assets; or (B) surplus equipment that is not used by the purchaser to receive video service from the holder. (10) Reimbursements that: (A) are made by programmers to the holder for marketing costs incurred by the holder for the introduction of new programming; and (B) exceed the actual costs incurred by the holder. (11) Late payment fees collected from customers. (12) Charges, other than those described in subsection (c)(1), that are aggregated or bundled with charges described in subsection HEA 1002 — CC 1 28 (c)(1) on a customer's bill, if the holder can reasonably identify the charges on the books and records by the holder in the regular course of business. (e) If, under the terms of the holder's certificate, the holder provides video service to any unincorporated area in Indiana, the holder shall calculate the holder's gross income received from each unincorporated area served in accordance with: (1) subsection (b); or (2) subsections (c) and (d); whichever is applicable. (f) If a unit served by the holder under a certificate annexes any territory after the certificate is issued or renewed under this chapter, the holder shall: (1) include in the calculation of gross revenue for the annexing unit any revenue generated by the holder from providing video service to the annexed territory; and (2) subtract from the calculation of gross revenue for any unit or unincorporated area: (A) of which the annexed territory was formerly a part; and (B) served by the holder before the effective date of the annexation; the amount of gross revenue determined under subdivision (1); beginning with the calculation of gross revenue for the calendar quarter in which the annexation becomes effective. The holder shall notify the commission of the new boundaries of the affected service areas as required under section 20(a)(7) of this chapter. (g) This subsection applies to a unit that: (1) annexes territory after December 31, 2015; and (2) is served on the date of the annexation by the holder of a certificate that is issued or renewed under this chapter before the date of the annexation. The unit shall provide the holder a list of all addresses located within the annexed territory not more than thirty (30) days after the date of the annexation. If the holder is required to pay the franchise fee imposed and calculated under this section, the holder is not required to pay the franchise fee with respect to addresses provided under this subsection until ninety (90) days after the unit provides the holder with the addresses under this subsection. SECTION 18. IC 12-15-5-17.5, AS ADDED BY P.L.165-2021, SECTION 138, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE UPON PASSAGE]: Sec. 17.5. (a) The office shall report on its progress on the development of a risk based managed care HEA 1002 — CC 1 29 program or capitated managed care program for Medicaid recipients who are eligible to participate in the Medicare program (42 U.S.C. 1395 et seq.) and receive nursing facility services to the interim study committee on public health, behavioral health, and human services before November 1, 2021. (b) Not later than February 1, 2022, the office shall report the following information and analysis to the legislative council and budget committee (in an electronic format under IC 5-14-6) regarding the implementation of a risk based managed care program or capitated managed care program for Medicaid recipients who are eligible to participate in the Medicare program (42 U.S.C. 1395 et seq.) and receive nursing facility services, as follows: (1) The projected utilization of home and community based services and institutional services for the four (4) years following implementation, and including, but not limited to, information on: (A) provider network adequacy; (B) family caregiver programming; and (C) costs and funding sources associated with creating and maintaining adequate provider networks and family caregiving programming. (2) How administrative processes, including service approval and billing processes, between managed care entities and providers of services will be addressed or streamlined in a risk based managed care program or capitated managed care program, with specific discussion of uniform provider credentialing, the potential of a single claims processing portal, and prior authorization processes. (3) Projected total spending for a risk based managed care program or capitated managed care program for the four (4) years following implementation. Such information shall include the identification of and impact on each source of state matching funds and overall impact on the state general fund. (4) The expected financial impacts of a risk based managed care program or capitated managed care program on the available amounts and use of the nursing facility quality assessment fee and supplemental payments to nursing facilities that are owned and operated by a governmental entity. Such information shall include an analysis on whether either of these funding streams will be diverted for uses other than the uses prior to implementation of a risk based managed care program or capitated managed care program and the effects on access to acute and post-acute care services due to the expected financial impacts. (c) A request for proposal for the procurement of a Medicaid HEA 1002 — CC 1 30 program to enroll a Medicaid recipient who is eligible to participate in the Medicare program (42 U.S.C. 1395 et seq.) and receives nursing facility services in a risk based managed care program or capitated managed care program may not be issued until the request for proposal has been reviewed by the budget committee. (d) After the review of a request for proposal by the budget committee under subsection (c), the office may not enter into a final contract that would implement a program described in subsection (c) before January 31, 2023. SECTION 19. IC 35-52-6-8 IS REPEALED [EFFECTIVE JULY 1, 2022]. [deleted: Sec. 8. IC 6-2.3-5.5-12 defines a crime concerning utility taxes.] SECTION 20. IC 35-52-6-9 IS REPEALED [EFFECTIVE JULY 1, 2022]. [deleted: Sec. 9. IC 6-2.3-7-1 defines a crime concerning taxes.] SECTION 21. IC 35-52-6-10 IS REPEALED [EFFECTIVE JULY 1, 2022]. [deleted: Sec. 10. IC 6-2.3-7-2 defines a crime concerning taxes.] SECTION 22. IC 35-52-6-11 IS REPEALED [EFFECTIVE JULY 1, 2022]. [deleted: Sec. 11. IC 6-2.3-7-3 defines a crime concerning taxes.] SECTION 23. IC 35-52-6-12 IS REPEALED [EFFECTIVE JULY 1, 2022]. [deleted: Sec. 12. IC 6-2.3-7-4 defines a crime concerning taxes.] SECTION 24. [EFFECTIVE UPON PASSAGE] (a) This SECTION applies for purposes of computation of the utility receipts and utility services use taxes (IC 6-2.3, before its repeal by this act). For taxable years that include June 30, 2022, the tax imposed under IC 6-2.3 must be computed based on the taxable receipts of the taxpayer received before July 1, 2022. For purposes of calculating the deduction under IC 6-2.3-5-1 for the taxable year that includes June 30, 2022, the deduction allowed must be prorated based on: (1) the number of days in the taxpayer's taxable year before July 1, 2022; divided by (2) the total number of days in the taxpayer's taxable year. (b) This SECTION expires July 1, 2025. SECTION 25. An emergency is declared for this act. HEA 1002 — CC 1 Speaker of the House of Representatives President of the Senate President Pro Tempore Governor of the State of Indiana Date: Time: HEA 1002 — CC 1 [extracted by pdf-snapshot.ts with strike detection, 2026-09-27T07:50:02.159Z, https://iga.in.gov/pdf-documents/122/2022/house/bills/HB1002/HB1002.04.ENRS.pdf, from saved file]