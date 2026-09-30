You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-30-shadow-gonzalez/labels/coder-3.json. Write JSON only, matching
codebook Part E, with "codebook_version": "0.4" and "coder_slot": 3. One row per
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
  - **Candidates too (ruling 2026-09-27).** A candidate for a seat in a legislature is coded on their
    record from either chamber of that legislature, exactly as a seated member is — a former
    representative running for the senate, say. Earlier service comes from
    `essentials.legislative_service` (CA_0296); CONFIRM checks it the same way.
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

politician_id: 1cede4d2-3075-4860-b133-1ab34cdacff5  office_id: a77cd5e4-d43d-4af1-b8e0-46ed80b979c6
Lena Gonzalez — Senator, California (seated, level: state)
Current term: 2019-01-01 (precision: year) to present

## Topics (served ladder text — code against these words only)

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

## Sources

---
snapshot_id: b9379b8b-cb68-500a-a099-8922f2af98a7
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202120220SB1137

Senate Bill No. 1137 CHAPTER 365 An act to add Article 4.6 (commencing with Section 3280) to Chapter 1 of Division 3 of the Public Resources Code, relating to oil and gas. [ Approved by Governor September 16, 2022. Filed with Secretary of State September 16, 2022. ] LEGISLATIVE COUNSEL'S DIGEST SB 1137, Gonzalez. Oil and gas: operations: location restrictions: notice of intention: health protection zone: sensitive receptors. Existing law establishes the Geologic Energy Management Division in the Department of Conservation, under the direction of the State Oil and Gas Supervisor, who is required to supervise the drilling, operation, maintenance, and abandonment of oil and gas wells in the state and the operation, maintenance, and removal or abandonment of tanks and facilities related to oil and gas production within an oil and gas field, so as to prevent damage to life, health, property, and natural resources. Existing law requires the operator of a well to file a written notice of intention to commence drilling with, and prohibits any drilling until approval is given by, the supervisor or district deputy. Existing law authorizes the supervisor to require other pertinent information to supplement the notice. Existing law requires the owner of any well to file with the supervisor a monthly statement that provides certain information relating to the well, as provided. Existing law requires an operator proposing to perform a well stimulation treatment to apply to the supervisor or district deputy for a permit to perform the well stimulation treatment and imposes other requirements and conditions on the use of well stimulation treatments. Under existing law, a person who fails to comply with this and other requirements relating to the regulation of oil or gas operations is guilty of a misdemeanor. This bill would prohibit, commencing January 1, 2023, the division from approving any notice of intention within a health protection zone, as defined, except for reasons related to preventing or responding to a threat to public health, safety, or the environment, complying with a court order, or to plug and abandon or reabandon a well, as provided. The bill would also explicitly authorize the division to approve notices of intention to public and private entities who own, purchase, or lease land containing idle-deserted or previously plugged and abandoned wells for the purposes of those public and private entities plugging and abandoning, or replugging and abandoning, those oil and gas wells so development of nonfossil fuel production and injection and related uses can proceed, as provided. The bill would require an operator who submits a notice of intention, except for certain notices of intention, to also submit either a sensitive receptor inventory and map of the area within the 3,200 feet radius of the wellhead or proposed wellhead location to the division, or a statement certifying that the operator has confirmed that there are no sensitive receptors, as defined, located within 3,200-foot of the wellhead location, as provided. If a notice of intention is approved pursuant to compliance with a court order, the bill would require the operator of the oil or gas well to provide an individual indemnity bond sufficient to pay the full cost of properly plugging and abandoning the operator’s well or wells, and decommissioning any attendant production facilities in the health protection zone, as provided. Commencing January 1, 2025, the bill would require all oil or gas production facilities or wells with a wellhead within a health protection zone to comply with specified health, safety, and environmental requirements, as provided. These health, safety, and environmental requirements would, among other things, require compliance with requirements related to applicable permits, public notice, sound levels, light generation, migration of dust and particulates beyond property boundaries, emissions and vapor venting, and chemical analyses of produced waters. The bill would also require all operators with a production facility or well with a wellhead in a health protection zone to submit a leak detection and response plan, as provided, to the division by January 1, 2025, require division approval or notice of deficiency by January 1, 2026, and require implementation of the plan by January 1, 2027. The bill would require the division to hold public workshops related to the leak detection and response plans, as provided, operators to review and update their plans at least once every 5 years, subject to division approval, and the supervisor to notify the applicable legislative budget and policy committees about these leak detection and response plans, as provided. The bill would require operators to contact property owners and tenants before commencing work that requires a notice of intention, and would also require operators to comply with water sampling requirements, as provided. The bill would require every operator to submit a sensitive receptor inventory and map to the division by July 1, 2023, and provide updates to the inventory and map annually thereafter, as provided, and require the division to make all current sensitive receptor inventories and maps publicly available on its internet website. The bill would, commencing January 1, 2027, and annually thereafter, require operators with a wellhead or other production facility in a health protection zone to provide information to the division, as provided, and require the division to make this information publicly available on its internet website. Because a violation of these requirements would be a crime, the bill would impose a state-mandated local program. The bill would exempt from its provisions underground gas storage wells and attendant production facilities. The bill would require the division, on or before July 1, 2027, and annually thereafter, to provide a legislative report to the applicable budget and policy committees regarding the implementation of health protection zones, as provided. The bill would authorize the division, the State Air Resources Board, and the State Water Resources Control Board to prescribe, adopt, and enforce any emergency regulations as necessary to implement, administer, and enforce these duties, as provided. The bill would require the State Air Resources Board, relevant local air districts, the State Water Resources Control Board, and relevant local water quality control boards, by June 1, 2023, to enter into memoranda of understanding with the division to clearly delineate respective responsibilities for the implementation and enforcement of health protection zones. By imposing requirements on local entities, the bill would impose a state-mandated local program. This bill would state that its provisions are severable. The California Constitution requires the state to reimburse local agencies and school districts for certain costs mandated by the state. Statutory provisions establish procedures for making that reimbursement. This bill would provide that with regard to certain mandates no reimbursement is required by this act for a specified reason. With regard to any other mandates, this bill would provide that, if the Commission on State Mandates determines that the bill contains costs so mandated by the state, reimbursement for those costs shall be made pursuant to the statutory provisions noted above. DIGEST KEY Vote: majority Appropriation: no Fiscal Committee: yes Local Program: yes BILL TEXT THE PEOPLE OF THE STATE OF CALIFORNIA DO ENACT AS FOLLOWS: SECTION 1. The Legislature finds and declares all of the following: (a) In addition to increasing impacts of climate change, a growing body of research shows direct health impacts from proximity to oil extraction. (b) These impacts are disproportionately impacting Black, indigenous, and people of color in California, who are most likely to live in close proximity to oil extraction activities and who are the most vulnerable to the negative impacts of climate change. (c) Proximity to oil and gas extraction sites pose significant health risks, especially due to increased air pollution. (d) Studies have shown evidence of harm at distances less than one kilometer, which is approximately 3,200 feet. (e) Further assistance must be provided to frontline communities that have been most polluted by the fossil fuel industry by cleaning up pollution, remediating negative health impacts, and building resilient infrastructure to prepare for the unavoidable impacts of climate change. SEC. 2. Article 4.6 (commencing with Section 3280) is added to Chapter 1 of Division 3 of the Public Resources Code, to read: Article 4.6. Health Protection Zones 3280. For purposes of this article, the following definitions apply: (a) “Area” means surface area, and all measurement of distances is on the surface of the land. (b) “Health protection zone” means the area within 3,200 feet of a sensitive receptor. The measurement shall be made from the property line of the receptor unless the receptor building is more than 50 feet set back from the property line, in which case the measurement shall be made from the outline of the building footprint to 3,200 feet in all directions. (c) “Sensitive receptor” means any of the following: (1) A residence, including a private home, condominium, apartment, and living quarter. (2) An education resource, including a preschool, school maintaining transitional kindergarten, kindergarten, or any of grades 1 to 12, inclusive, daycare center, park, playground, university, and college. Where a university or college is the only sensitive receptor within 3,200 feet of the operator’s wellheads or production facilities, the university or college is not a sensitive receptor if the operator demonstrates to the division’s satisfaction that no building with nominal daily occupancy on the university or college campus is located within 3,200 feet of the operator’s wellheads or production facilities. (3) A community resource center, including a youth center. (4) A health care facility, including a hospital, retirement home, and nursing home. (5) Live-in housing, including a long-term care hospital, hospice, prison, detention center, and dormitory. (6) Any building housing a business that is open to the public. 3281. (a) Notwithstanding any other law, commencing January 1, 2023, the division shall not approve any notice of intention under Section 3203 within a health protection zone, except for approvals of notices of intention necessary for any of the following purposes: (1) To prevent or respond to a threat to public health, safety, or the environment. (2) To comply with a court order finding that denying approval would amount to a taking of property, or a court order otherwise requiring approval of a notice of intention. (3) To plug and abandon or reabandon a well, including an intercept well necessary to plug and abandon or reabandon a well. (b) An operator who submits a notice of intention under Section 3203, except for notices of intention described in paragraph (3) of subdivision (a), shall submit a sensitive receptor inventory and map pursuant to Section 3285 of the area within the 3,200-foot radius of the wellhead or proposed wellhead location to the division with the notice of intention or a statement certifying that the operator has confirmed, and the division has verified, that there are no sensitive receptors located within 3,200 feet of the wellhead location. The operator shall submit the sensitive receptor inventory and map in a format that complies with all requirements of the federal Americans with Disabilities Act of 1990 (Public Law 101–336) and its implementing regulations for online viewing. If the inventory or map includes any personally identifiable information, the operator shall submit a second version with the personally identifiable information redacted. Inventories and maps with no personally identifiable information shall be made available to the public in compliance with Section 3234. No new production facilities shall be constructed or operated in a health protection zone unless associated with a notice of intention approved pursuant to subdivision (a) or as determined by the division to be necessary to protect public health and safety. (c) If a notice of intention is approved pursuant to paragraph (2) of subdivision (a), the approval shall require the operator of the oil or gas well to provide an individual indemnity bond sufficient to pay the full cost of properly plugging and abandoning the operator’s well or wells, and decommissioning any attendant production facilities in the health protection zone. The division shall determine the amount of the individual indemnity bond in accordance with subdivision (b) of Section 3205.3. The bond shall be executed by the operator, as principal, and by an authorized surety company, as surety, and shall be in substantially the same language and upon the same conditions as provided in Section 3204, except as to the difference in the amount. The operator’s blanket indemnity bond authorized pursuant to Section 3205 shall not be used to satisfy this subdivision. (d) Underground gas storage wells and attendant production facilities are not subject to this article. 3281.5. (a) The Legislature finds and declares that development of oil and gas fields into nonfossil fuel production and injection and related uses, including, but not limited to, housing, recreation, and commercial development, may have plugged and abandoned wells or may require existing oil and gas wells to be plugged and abandoned, or replugged and abandoned, to current statutory and regulatory standards, and that the creation of health protection zones, and the related restrictions and requirements of this article, do not apply in the context of development for nonfossil fuel production and injection and related uses. (b) Notwithstanding any contrary provisions of subdivision (a) of Section 3281, the division may approve notices of intention pursuant to Section 3203 to public and private entities who own, purchase, or lease land containing idle-deserted or previously plugged and abandoned wells for the purposes of those public and private entities plugging and abandoning, or replugging and abandoning, those oil and gas wells so development of nonfossil fuel production and injection and related uses can proceed. This may include, without limitation, a notice of intention to drill or rework an intercept well, if needed to plug and abandon or replug and abandon another well on the condition that the intercept well is itself plugged and abandoned. The public and private entities, as well as any lessees, tenants, or other occupants, shall not engage in oil or gas development or production or injection or related uses for which they have submitted a notice of intention pursuant to this subdivision. 3282. Commencing January 1, 2025, all oil or gas production facilities or wells with a wellhead within a health protection zone shall be in compliance with all of the following requirements: (a) The operator is required to comply with the terms and conditions of all applicable federal, state, and local permits required to operate the well and facility. (b) If not otherwise required by law or regulation, clearly post contact information for where to address complaints about noise, odor, and other concerns on the perimeter of the site. This information shall include responsible persons employed by the operator, as well as enforcement officials in the city, county, or city and county, and air district, in which the facility is located. The size and format of the posted information shall be consistent with existing requirements. (c) Unless more stringent local requirements apply, between 8 p.m. and 7 a.m., sound levels from oil and gas production operations shall not exceed ambient noise levels, as measured at the property line. (d) Unless more stringent local requirements apply, minimize light generated at an oil or gas well or production facility to reduce light traveling beyond property boundaries. Except as needed in emergency circumstances, operators shall use only such lighting as is necessary to provide the minimum intensity and coverage for safety and basic security between the hours of 8 p.m. and 7 a.m. Lighting shall be hooded or otherwise directed so that it shines onto only the operator’s property and not onto adjacent properties or into the sky. (e) Unless more stringent local requirements apply, employ operational measures to prevent dust and particulates from migrating beyond property boundaries. Dust control measures to be employed within property boundaries shall include, but are not limited to, the following: (1) Limiting vehicle speeds on unpaved roads to 15 miles per hour or less. (2) Containing or covering stored sands, drilling muds, and excavated soil. (f) Immediately suspending the use of a production facility if the production facility, including all permanent and temporary equipment within the health protection zone that emits vapors, such as tanks, vessels, separation facilities, gas processing units, and other equipment holding petroleum liquids or produced water, is not in compliance with all applicable air district requirements relating to preventing vapor venting to the atmosphere. (g) (1) The operator is required to provide the division with representative chemical analyses for all produced water transported away from the oilfield where it was produced. (2) Chemical analysis required under this subdivision shall be in accordance with the analytical specifications for liquid analysis detailed in Section 1724.7.2 of Title 14 of the California Code of Regulations, and shall be filed with the division within three months of produced water being transported from the oilfield and whenever the source of produced water is changed. (3) For the purposes of this subdivision, the source of produced water is changed if the treatment process or additives are changed, if a contributing source is added or removed, or if there is a significant change to the relative contribution of individual sources such that the last chemical analysis is not representative of the produced water being transported from the oilfield. 3283. (a) All operators with a production facility or well with a wellhead in a health protection zone shall develop a leak detection and response plan that shall be submitted to the division no later than January 1, 2025, and fully implemented by operators by January 1, 2027. For any leak detection and response plan submitted by January 1, 2025, the division shall either approve the plan or provide notice of deficiencies by January 1, 2026. Commencing January 1, 2027, the operator shall suspend all production and injection operations within a health protection zone unless an approved leak detection and response plan is fully implemented in that area. A leak detection and response plan is subject to review and approval by the division, in consultation with and with the concurrence of the State Air Resources Board, and shall include all of the following: (1) The leak detection and response plan shall identify the chemical constituents, such as methane and hydrogen sulfide, as well as potential toxics of highest concern in the region as identified by the State Air Resources Board or local air district that will be detection targets for the emissions detection system to ensure early detection of leaks that otherwise may result in emissions impacting the surrounding communities. Not all chemical species that may be found in the oilfield are required to be detection targets and methane may serve as a surrogate for chemical constituents that cannot be continuously monitored but are identified in the leak detection and response plan. The State Air Resources Board and the State Water Resources Control Board shall adopt regulations as necessary to implement and set performance standards by regulation for the emissions detection system. The division, the State Air Resources Board, and the State Water Resources Control Board may adopt such regulations under an emergency rulemaking process as provided in Section 3288. (2) (A) The leak detection and response plan shall include a continuously operating emissions detection system designed to provide for rapid detection of target chemical constituents to identify leaks before emissions impact the surrounding communities. Sampling locations and sample inlets shall be sited consistent with local meteorology and best practices. (B) The emissions detection system shall include an alarm system that effectively, immediately, and reliably alerts the operator when triggered. (C) The emissions detection system shall include a new, or use an existing, meteorological system that is appropriately sited with the ability to continuously record measurements. (b) The leak detection and response plan shall include an alarm response protocol that provides for immediate action to rapidly identify and fix the leak that is the source of the emissions. In the event that the source of the emissions is not identified and the leak stopped within 48 hours of the leak being identified, the alarm response protocol shall include a communication plan for notification of local emergency responders and public health authorities, the division, and people in the community, including notification in languages that are easily understood by the affected community. The alarm response protocol shall provide for compliance with all local, state, and federal requirements for reporting leaks of hazardous emissions. The operator shall consult with local emergency response entities when preparing the alarm response protocol and shall engage in drills as deemed necessary by the local emergency response entity. The alarm response protocol shall provide for collection and determination of the chemical composition of a representative sample near the leak when a continuous alarm event indicates that emissions from the leak may have impacted the surrounding community, and the subsequent collection and determination of the chemical composition of samples when there is reason to believe that the composition of the emissions may be changing. If the source of the emissions is a leak from a well or production facility, the operator shall suspend use of the well or production facility until the leak has been corrected and the division has approved the resumption of its use. Where the operator can demonstrate to the division that the source of the emissions is not related to the oil and gas operations, the division may waive any additional actions required under the alarm response protocol. (c) The division and the State Air Resources Board shall collaborate to develop methods for providing public access to data generated by operators from emissions detection systems. (d) The division shall hold no less than three public workshops following the enactment of the emergency regulations pursuant to Section 3288 to provide information and guidance to operators and the public on the development of leak detection and response plans pursuant to this section. (e) An operator’s leak detection and response plan shall be reviewed and updated by the operator, subject to division approval, at least once every five years from the date of its initial approval by the division. The division shall hold at least one public technical workshop at least biennially to provide information and guidance to operators on best practices for the development, review, and update of leak detection and response plans. (f) The operator shall record and maintain records of emissions and meteorological monitoring, including the composition of any samples collected during leak events, for 10 years. (g) Notwithstanding Section 10231.5 of the Government Code, commencing July 1, 2023, and at six-month intervals thereafter, the supervisor shall notify the applicable legislative budget and policy committees on progress, including milestones, towards achieving the deadlines in subdivision (a) for the development, approval, and implementation of the leak detection and response plans. 3284. (a) Before commencing any work that requires a notice of intention under Section 3203 in the health protection zone, the operator shall contact property owners and tenants within a 3,200-foot radius of the wellhead in writing with a record of delivery and offer to sample and test water wells or surface water on their property before and after drilling. (b) The operator shall contact property owners and tenants as specified in subdivision (a) at least 30 days before commencing drilling. If a property owner or tenant requests sampling and testing of a water well or surface water, drilling may not commence until a baseline water sample has been collected, provided that the owner’s or tenant’s request is delivered in writing with a record of delivery to the operator within 20 days from the date notice is provided and the surface property owner makes necessary accommodations to enable the collection of a water sample within 10 days from the date notice is provided. The operator shall collect a followup water sample no sooner than 30 days, and no later than 60 days, after drilling is complete. The costs of sampling and testing required under this section shall be borne by the operator. (c) Before commencing drilling in the health protection zone, the operator shall provide to the division documentation of the effort to identify and notify property owners and tenants as required. (d) The operator shall conduct water sampling and testing, both baseline and followup, pursuant to this section, in accordance with all of the following requirements: (1) Water quality sampling shall be conducted by appropriately qualified personnel in a manner consistent with standard environmental industry practice and chain of custody protocols. Documentation of the sampling process shall accurately describe the location that the sample was taken from and the process for collecting the sample. (2) Water quality analytical testing shall be performed by a laboratory that has been accredited under the State Water Resources Control Board’s Environmental Laboratory Accreditation Program to perform the tests necessary to complete the required analysis under this subdivision, except for those tests labeled as field tests, that may be conducted by any person qualified to sample and interpret the results of the required test. (3) (A) Water quality testing shall include baseline measurements before the commencement of the drilling, and followup measurements after drilling is completed. (B) Liquid analysis required under this subdivision shall include testing for all of the following: total dissolved solids; total petroleum hydrocarbon as crude oil; major cations (Ca, Mg, Na, K, Fe, Mn, Sr, B); major anions (CI, SO4, HCO3, CO3, Br, I, NO3); any constituents listed in subparagraphs (A) and (B) of paragraph (2) of subdivision (a) of Section 66261.24 of Title 22 of the California Code of Regulations; radionuclides; appropriate indicator chemicals for drilling mud and fluids used for well cleanout; total alkalinity and hydroxide; electrical conductance; pH; and temperature. (C) The division or the regional water quality control board may require testing for additional constituents on a case-by-case basis. (4) Within 120 days after drilling in the health protection zone is complete, the results of any baseline and followup water quality testing shall be provided by the operator to the division, the appropriate regional water quality control board, the State Water Resources Control Board, the surface property owner, and the requesting tenant. (5) The appropriate regional water quality control board shall be notified at least five working days before collecting a sample under this section so that regional water quality control board staff may witness the sampling. (6) Water quality data collected under this section shall be submitted to the State Water Resources Control Board and the appropriate regional water quality control board in an electronic format that follows the guidelines detailed in Chapter 30 (commencing with Section 3890) of Division 3 of Title 23 of the California Code of Regulations within 120 days after drilling is complete. (7) If the property owner or tenant is unable to provide the necessary access to perform baseline or followup testing under this section, then failure to do the testing is not a violation of this section. The division may waive the requirements of this section if the operator demonstrates that the delay in well work associated with the requirements of this section is likely to result in significant damage to life, health, or natural resources. The operator is not required to sample or test water under this section if the relevant authorities have determined that the water is not an underground source of drinking water, as defined in the federal Safe Drinking Water Act (42 U.S.C. Sec. 300f et. seq.), and the water has no beneficial uses, in accordance with subdivision (f) of Section 13050 of the Water Code. 3285. (a) Every operator shall submit to the division by July 1, 2023, a sensitive receptor inventory and map that includes the following: (1) A list of all sensitive receptors within 3,200 feet of an operator’s wellheads and production facilities by field. For each sensitive receptor listed, the operator shall provide all of the following: (A) The distance from the sensitive receptor to each wellhead or production facility that is located within 3,200 feet of that specific receptor. The well shall be identified by API number, and the production facility shall also be explicitly identified. Latitude and longitude shall also be provided for the wellhead and production facility. (B) The type of sensitive receptor. (C) A map showing each sensitive receptor’s location in relation to the operator’s wellheads and production facilities. (2) A statement from each operator based on their sensitive receptor inventory that provides the operator’s determination as to whether their wellheads and production facilities are located within 3,200 feet of a sensitive receptor. An operator who has identified sufficient sensitive receptors such that their entire operation is located within a health protection zone may cease adding new sensitive receptors to their inventory and make a determination that all of their wellheads and production facilities are located within a health protection zone. (b) By July 1 of each year, all operators shall submit to the division a sensitive receptor inventory and map pursuant to subdivision (a) that is up to date, with information no more than 90 days old, and shall make a new determination regarding the location of each of their wellheads and production facilities within a health protection zone. If there have been no changes to the location of sensitive receptors in the 3,200 feet surrounding the operator’s wellheads and production facilities, the operator shall submit a statement that no changes to the determination are needed. (c) The division shall review for completeness and accuracy no less than 30 percent of the inventories and associated maps submitted annually pursuant to this section. The division shall notify operators of any discrepancies in the submitted inventories and maps as determined by the division. (d) The division shall make available to the public on its internet website all current sensitive receptor inventories and maps. 3286. (a) Commencing January 1, 2027, and no less than annually on a date to be determined by the division, an operator with a wellhead or other production facility or facilities in a health protection zone shall provide at least the following information to the division by location in a format that complies with all requirements of the federal Americans with Disabilities Act of 1990 (Public Law 101–336) and its implementing regulations for online viewing: (1) The number of and amounts of time the emissions detection system was not operating. (2) The number of validated alarms, and the reasons for the alarms. (3) The number of leaks that occurred, the time needed to repair the leak, and a brief description of the leak, including the impact on air quality and community exposure. (4) The number of times the surrounding community was notified after a leak persisted for 48 hours. (5) The number of times and length of time production and injection operations and other use of the facility were suspended due to leaks. (6) Any baseline and postdrilling groundwater testing performed by location. (b) The division shall make the information submitted by the operators available to the public on its internet website. 3287. Notwithstanding Section 10231.5 of the Government Code, on or before July 1, 2027, and annually thereafter, the division shall provide a legislative report to the applicable budget and policy committees regarding the implementation of health protection zones by the division. The reports shall include at least the following: (a) The number and types of wells and attendant facilities in health protection zones by operator and field. (b) The estimated population protected by the health protection zone. (c) The status of leak detection and response plans by operation and location. (d) The number and type of notices of intention approved in health protection zones and the reason the notices of intention received approval by operator and field. (e) The number of sensitive receptor inventories and maps received by the division by operator and field. (f) Aggregated information by operator and location of leaks detected and alarms associated with the leaks. (g) The number of notices of violation issued by the division for dust control, excess noise and light, and other requirements pursuant to this article by operator and field. (h) The number of orders issued by the supervisor pursuant to this article by operator and field. (i) The number of times by operator and location that baseline and postdrilling groundwater testing was performed. 3288. The division, the State Air Resources Board, and the State Water Resources Control Board may prescribe, adopt, and enforce any emergency regulations as necessary to implement, administer, and enforce its duties under this article. Any emergency regulation prescribed, adopted, or enforced pursuant to this article shall be adopted in accordance with Chapter 3.5 (commencing with Section 11340) of Part 1 of Division 3 of Title 2 of the Government Code, and, for purposes of that chapter, including Section 11349.6 of the Government Code, the adoption of the regulation is an emergency and shall be considered by the Office of Administrative Law as necessary for the immediate preservation of the public peace, health and safety, and general welfare. Notwithstanding any other law, the emergency regulations adopted by the division, the State Air Resources Board, and the State Water Resources Control Board may remain in effect for two years from adoption. 3289. (a) No provision of this article is a limitation on the authority or jurisdiction of the State Water Resources Control Board, the regional water quality control boards, the State Air Resources Board, or local air quality districts. (b) This article does not prohibit a city, county, or city and county from imposing more stringent regulations, limits, or prohibitions on oil and gas development. 3290. The State Air Resources Board, relevant local air districts, the State Water Resources Control Board, and relevant local water quality control boards shall enter into memoranda of understanding with the division to clearly delineate respective responsibilities for implementing and enforcing health protection zones. These memoranda of understanding shall be executed by June 1, 2023. The division may pursue additional memoranda of understanding with other state and local entities as needed. 3291. This article does not diminish or alter the authority of the supervisor to deny, revoke, or suspend permits to meet the division’s purpose to protect public health and safety and environmental quality, including the reduction and mitigation of greenhouse gas emissions, or the supervisor’s repeated obligation pursuant to this division to supervise certain oil and gas related operations to prevent, as far as possible, damage to life, health, property, natural resources, or underground and surface waters suitable for irrigation or domestic purposes, among other reasons. SEC. 3. The provisions of this act are severable. If any provision of this act or its application is held invalid, that invalidity shall not affect other provisions or applications that can be given effect without the invalid provision or application. SEC. 4. No reimbursement is required by this act pursuant to Section 6 of Article XIII B of the California Constitution for certain costs that may be incurred by a local agency or school district because, in that regard, this act creates a new crime or infraction, eliminates a crime or infraction, or changes the penalty for a crime or infraction, within the meaning of Section 17556 of the Government Code, or changes the definition of a crime within the meaning of Section 6 of Article XIII B of the California Constitution. However, if the Commission on State Mandates determines that this act contains other costs mandated by the state, reimbursement to local agencies and school districts for those costs shall be made pursuant to Part 7 (commencing with Section 17500) of Division 4 of Title 2 of the Government Code. [Chaptered text of SB 1137 (2021-2022), saved by browser from leginfo.legislature.ca.gov on 2026-09-30; the site's robots.txt disallows crawling.]