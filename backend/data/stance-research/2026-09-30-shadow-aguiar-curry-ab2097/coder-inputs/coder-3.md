You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-30-shadow-aguiar-curry-ab2097/labels/coder-3.json. Write JSON only, matching
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

politician_id: 8ba12ba5-ba07-48be-ae0e-88e1d1ef5257  office_id: f4c83c0b-3c35-419b-a618-0e6c4c13fd38
Cecilia M. Aguiar-Curry — Assembly Member, California (seated, level: state)
Current term: 2016-12-05 (precision: day) to present

## Topics (served ladder text — code against these words only)

### topic_key: transportation-priorities
topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27  served_revision_id: 555f1618-fcdf-4e0b-8306-7eec8f4d0f4f
Question: Where should government focus its transportation investment?
  1. Prioritize pedestrian infrastructure, cycling networks, and public transit over new road capacity
  2. Invest equally in road capacity and in multimodal options like transit, bike lanes, and sidewalks
  3. Maintain roads while selectively adding transit connections and pedestrian improvements where density supports it
  4. Focus on road capacity and traffic flow; transportation investment should serve the majority who drive
  5. Prioritize highway access and abundant free parking as the foundation of local transportation policy

#### Annex

(no annex for this topic yet — apply the codebook alone)

## Sources

---
snapshot_id: 1a03cbce-3c6a-5f51-a7ff-7cec07571f45
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202120220AB2097

Assembly Bill No. 2097 CHAPTER 459 An act to amend Section 65585 of, and to add Section 65863.2 to, the Government Code, relating to land use. [ Approved by Governor September 22, 2022. Filed with Secretary of State September 22, 2022. ] LEGISLATIVE COUNSEL'S DIGEST AB 2097, Friedman. Residential, commercial, or other development types: parking requirements. The Planning and Zoning Law requires each county and city to adopt a comprehensive, long-term general plan for its physical development, and the development of certain lands outside its boundaries, that includes, among other mandatory elements, a land use element, and a conservation element. Existing law also authorizes the legislative body of a city or a county to adopt ordinances establishing requirements for parking, and permits variances to be granted from the parking requirements of a zoning ordinance for nonresidential development if the variance will be an incentive to the development and the variance will facilitate access to the development by patrons of public transit facilities. This bill would prohibit a public agency from imposing any minimum automobile parking requirement on any residential, commercial, or other development project, as defined, that is located within 1/2 mile of public transit, as defined. The bill, notwithstanding the above-described prohibition, would authorize a city, county, or city and county to impose or enforce minimum automobile parking requirements on a housing development project if the public agency makes written findings, within 30 days of the receipt of a completed application, that not imposing or enforcing minimum automobile parking requirements on the development would have a substantially negative impact, supported by a preponderance of the evidence in the record, on the public agency’s ability to meet its share of specified housing needs or existing residential or commercial parking within 1/2 mile of the housing development. The bill would create an exception from the above-described provision if the housing development project (1) dedicates a minimum of 20% of the total number of housing units to very low, low-, or moderate-income households, students, the elderly, or persons with disabilities, (2) contains fewer than 20 housing units, or (3) is subject to parking reductions based on any other applicable law. The bill would prohibit these provisions from reducing, eliminating, or precluding the enforcement of any requirement imposed on a housing development project that is located within 1/2 mile of public transit to provide electric vehicle supply equipment installed parking spaces or parking spaces that are accessible to persons with disabilities. By changing the duties of local planning officials, this bill would impose a state-mandated local program. Existing law also requires the Department of Housing and Community Development to notify a city, county, or city and county, and authorizes the department to notify the office of the Attorney General, that the city, county, or city and county is in violation of state law if the department finds that the housing element or an amendment to the housing element does not substantially comply with specified provisions of the Planning and Zoning Law, or that the local government has taken action or failed to act in violation of specified provisions of law. Existing law authorizes the Attorney General to bring suit for a violation of those provisions. This bill would add a violation of the minimum automobile parking requirements of residential, commercial, or other development projects, as described above, to the list of laws that, when violated, require the department to notify the jurisdiction and authorize the Attorney General to bring an action to enforce state law. The bill would include findings that changes proposed by this bill address a matter of statewide concern rather than a municipal affair and, therefore, apply to all cities, including charter cities. This bill would incorporate additional changes to Section 65585 of the Government Code proposed by AB 2011 and AB 2653 to be operative only if this bill and AB 2011 or AB 2653, or all 3 bills, are enacted and this bill is enacted last. The California Constitution requires the state to reimburse local agencies and school districts for certain costs mandated by the state. Statutory provisions establish procedures for making that reimbursement. This bill would provide that no reimbursement is required by this act for a specified reason. DIGEST KEY Vote: majority Appropriation: no Fiscal Committee: yes Local Program: yes BILL TEXT THE PEOPLE OF THE STATE OF CALIFORNIA DO ENACT AS FOLLOWS: SECTION 1. Section 65585 of the Government Code is amended to read: 65585. (a) In the preparation of its housing element, each city and county shall consider the guidelines adopted by the department pursuant to Section 50459 of the Health and Safety Code. Those guidelines shall be advisory to each city or county in the preparation of its housing element. (b) (1) At least 90 days prior to adoption of a revision of its housing element pursuant to subdivision (e) of Section 65588, or at least 60 days prior to the adoption of a subsequent amendment to this element, the planning agency shall submit a draft element revision or draft amendment to the department. The local government of the planning agency shall make the first draft revision of a housing element available for public comment for at least 30 days and, if any comments are received, the local government shall take at least 10 business days after the 30-day public comment period to consider and incorporate public comments into the draft revision prior to submitting it to the department. For any subsequent draft revision, the local government shall post the draft revision on its internet website and shall email a link to the draft revision to all individuals and organizations that have previously requested notices relating to the local government’s housing element at least seven days before submitting the draft revision to the department. (2) The planning agency staff shall collect and compile the public comments regarding the housing element received by the city, county, or city and county, and provide these comments to each member of the legislative body before it adopts the housing element. (3) The department shall review the draft and report its written findings to the planning agency within 90 days of its receipt of the first draft submittal for each housing element revision pursuant to subdivision (e) of Section 65588 or within 60 days of its receipt of a subsequent draft amendment or an adopted revision or adopted amendment to an element. The department shall not review the first draft submitted for each housing element revision pursuant to subdivision (e) of Section 65588 until the local government has made the draft available for public comment for at least 30 days and, if comments were received, has taken at least 10 business days to consider and incorporate public comments pursuant to paragraph (1). (c) In the preparation of its findings, the department may consult with any public agency, group, or person. The department shall receive and consider any written comments from any public agency, group, or person regarding the draft or adopted element or amendment under review. (d) In its written findings, the department shall determine whether the draft element or draft amendment substantially complies with this article. (e) Prior to the adoption of its draft element or draft amendment, the legislative body shall consider the findings made by the department. If the department’s findings are not available within the time limits set by this section, the legislative body may act without them. (f) If the department finds that the draft element or draft amendment does not substantially comply with this article, the legislative body shall take one of the following actions: (1) Change the draft element or draft amendment to substantially comply with this article. (2) Adopt the draft element or draft amendment without changes. The legislative body shall include in its resolution of adoption written findings which explain the reasons the legislative body believes that the draft element or draft amendment substantially complies with this article despite the findings of the department. (g) Promptly following the adoption of its element or amendment, the planning agency shall submit a copy to the department. (h) The department shall, within 90 days, review adopted housing elements or amendments and report its findings to the planning agency. (i) (1) (A) The department shall review any action or failure to act by the city, county, or city and county that it determines is inconsistent with an adopted housing element or Section 65583, including any failure to implement any program actions included in the housing element pursuant to Section 65583. The department shall issue written findings to the city, county, or city and county as to whether the action or failure to act substantially complies with this article, and provide a reasonable time no longer than 30 days for the city, county, or city and county to respond to the findings before taking any other action authorized by this section, including the action authorized by subparagraph (B). (B) If the department finds that the action or failure to act by the city, county, or city and county does not substantially comply with this article, and if it has issued findings pursuant to this section that an amendment to the housing element substantially complies with this article, the department may revoke its findings until it determines that the city, county, or city and county has come into compliance with this article. (2) The department may consult with any local government, public agency, group, or person, and shall receive and consider any written comments from any public agency, group, or person, regarding the action or failure to act by the city, county, or city and county described in paragraph (1), in determining whether the housing element substantially complies with this article. (j) The department shall notify the city, county, or city and county and may notify the office of the Attorney General that the city, county, or city and county is in violation of state law if the department finds that the housing element or an amendment to this element, or any action or failure to act described in subdivision (i), does not substantially comply with this article or that any local government has taken an action in violation of the following: (1) Housing Accountability Act (Section 65589.5). (2) Section 65863. (3) Chapter 4.3 (commencing with Section 65915.) (4) Section 65008. (5) Housing Crisis Act of 2019 (Chapter 654, Statutes of 2019, Sections 65941.1, 65943, and 66300). (6) Section 8899.50. (7) Section 65913.4. (8) Article 11 (commencing with Section 65650). (9) Article 12 (commencing with Section 65660). (10) Section 65913.11. (11) Section 65863.2. (k) Commencing July 1, 2019, prior to the Attorney General bringing any suit for a violation of the provisions identified in subdivision (j) related to housing element compliance and seeking remedies available pursuant to this subdivision, the department shall offer the jurisdiction the opportunity for two meetings in person or via telephone to discuss the violation, and shall provide the jurisdiction written findings regarding the violation. This paragraph does not affect any action filed prior to the effective date of this section. The requirements set forth in this subdivision do not apply to any suits brought for a violation or violations of paragraphs (1) and (3) to (9), inclusive, of subdivision (j). (l) In any action or special proceeding brought by the Attorney General relating to housing element compliance pursuant to a notice or referral under subdivision (j), the Attorney General may request, upon a finding of the court that the housing element does not substantially comply with the requirements of this article pursuant to this section, that the court issue an order or judgment directing the jurisdiction to bring its housing element into substantial compliance with the requirements of this article. The court shall retain jurisdiction to ensure that its order or judgment is carried out. If a court determines that the housing element of the jurisdiction substantially complies with this article, it shall have the same force and effect, for purposes of eligibility for any financial assistance that requires a housing element in substantial compliance and for purposes of any incentives provided under Section 65589.9, as a determination by the department that the housing element substantially complies with this article. (1) If the jurisdiction has not complied with the order or judgment after 12 months, the court shall conduct a status conference. Following the status conference, upon a determination that the jurisdiction failed to comply with the order or judgment compelling substantial compliance with the requirements of this article, the court shall impose fines on the jurisdiction, which shall be deposited into the Building Homes and Jobs Trust Fund. Any fine levied pursuant to this paragraph shall be in a minimum amount of ten thousand dollars ($10,000) per month, but shall not exceed one hundred thousand dollars ($100,000) per month, except as provided in paragraphs (2) and (3). In the event that the jurisdiction fails to pay fines imposed by the court in full and on time, the court may require the Controller to intercept any available state and local funds and direct such funds to the Building Homes and Jobs Trust Fund to correct the jurisdiction’s failure to pay. The intercept of the funds by the Controller for this purpose shall not violate any provision of the California Constitution. (2) If the jurisdiction has not complied with the order or judgment after three months following the imposition of fees described in paragraph (1), the court shall conduct a status conference. Following the status conference, if the court finds that the fees imposed pursuant to paragraph (1) are insufficient to bring the jurisdiction into compliance with the order or judgment, the court may multiply the fine determined pursuant to paragraph (1) by a factor of three. In the event that the jurisdiction fails to pay fines imposed by the court in full and on time, the court may require the Controller to intercept any available state and local funds and direct such funds to the Building Homes and Jobs Trust Fund to correct the jurisdiction’s failure to pay. The intercept of the funds by the Controller for this purpose shall not violate any provision of the California Constitution. (3) If the jurisdiction has not complied with the order or judgment six months following the imposition of fees described in paragraph (1), the court shall conduct a status conference. Upon a determination that the jurisdiction failed to comply with the order or judgment, the court may impose the following: (A) If the court finds that the fees imposed pursuant to paragraphs (1) and (2) are insufficient to bring the jurisdiction into compliance with the order or judgment, the court may multiply the fine determined pursuant to paragraph (1) by a factor of six. In the event that the jurisdiction fails to pay fines imposed by the court in full and on time, the court may require the Controller to intercept any available state and local funds and direct such funds to the Building Homes and Jobs Trust Fund to correct the jurisdiction’s failure to pay. The intercept of the funds by the Controller for this purpose shall not violate any provision of the California Constitution. (B) The court may order remedies available pursuant to Section 564 of the Code of Civil Procedure, under which the agent of the court may take all governmental actions necessary to bring the jurisdiction’s housing element into substantial compliance pursuant to this article in order to remedy identified deficiencies. The court shall determine whether the housing element of the jurisdiction substantially complies with this article and, once the court makes that determination, it shall have the same force and effect, for all purposes, as the department’s determination that the housing element substantially complies with this article. An agent appointed pursuant to this paragraph shall have expertise in planning in California. (4) This subdivision does not limit a court’s discretion to apply any and all remedies in an action or special proceeding for a violation of any law identified in subdivision (j). (m) In determining the application of the remedies available under subdivision (l), the court shall consider whether there are any mitigating circumstances delaying the jurisdiction from coming into compliance with state housing law. The court may consider whether a city, county, or city and county is making a good faith effort to come into substantial compliance or is facing substantial undue hardships. (n) Nothing in this section shall limit the authority of the office of the Attorney General to bring a suit to enforce state law in an independent capacity. The office of the Attorney General may seek all remedies available under law including those set forth in this section. (o) Notwithstanding Sections 11040 and 11042, if the Attorney General declines to represent the department in any action or special proceeding brought pursuant to a notice or referral under subdivision (j) the department may appoint or contract with other counsel for purposes of representing the department in the action or special proceeding. (p) Notwithstanding any other provision of law, the statute of limitations set forth in subdivision (a) of Section 338 of the Code of Civil Procedure shall apply to any action or special proceeding brought by the Office of the Attorney General or pursuant to a notice or referral under subdivision (j), or by the department pursuant to subdivision (o). SEC. 1.1. Section 65585 of the Government Code is amended to read: 65585. (a) In the preparation of its housing element, each city and county shall consider the guidelines adopted by the department pursuant to Section 50459 of the Health and Safety Code. Those guidelines shall be advisory to each city or county in the preparation of its housing element. (b) (1) At least 90 days prior to adoption of a revision of its housing element pursuant to subdivision (e) of Section 65588, or at least 60 days prior to the adoption of a subsequent amendment to this element, the planning agency shall submit a draft element revision or draft amendment to the department. The local government of the planning agency shall make the first draft revision of a housing element available for public comment for at least 30 days and, if any comments are received, the local government shall take at least 10 business days after the 30-day public comment period to consider and incorporate public comments into the draft revision prior to submitting it to the department. For any subsequent draft revision, the local government shall post the draft revision on its internet website and shall email a link to the draft revision to all individuals and organizations that have previously requested notices relating to the local government’s housing element at least seven days before submitting the draft revision to the department. (2) The planning agency staff shall collect and compile the public comments regarding the housing element received by the city, county, or city and county, and provide these comments to each member of the legislative body before it adopts the housing element. (3) The department shall review the draft and report its written findings to the planning agency within 90 days of its receipt of the first draft submittal for each housing element revision pursuant to subdivision (e) of Section 65588 or within 60 days of its receipt of a subsequent draft amendment or an adopted revision or adopted amendment to an element. The department shall not review the first draft submitted for each housing element revision pursuant to subdivision (e) of Section 65588 until the local government has made the draft available for public comment for at least 30 days and, if comments were received, has taken at least 10 business days to consider and incorporate public comments pursuant to paragraph (1). (c) In the preparation of its findings, the department may consult with any public agency, group, or person. The department shall receive and consider any written comments from any public agency, group, or person regarding the draft or adopted element or amendment under review. (d) In its written findings, the department shall determine whether the draft element or draft amendment substantially complies with this article. (e) Prior to the adoption of its draft element or draft amendment, the legislative body shall consider the findings made by the department. If the department’s findings are not available within the time limits set by this section, the legislative body may act without them. (f) If the department finds that the draft element or draft amendment does not substantially comply with this article, the legislative body shall take one of the following actions: (1) Change the draft element or draft amendment to substantially comply with this article. (2) Adopt the draft element or draft amendment without changes. The legislative body shall include in its resolution of adoption written findings which explain the reasons the legislative body believes that the draft element or draft amendment substantially complies with this article despite the findings of the department. (g) Promptly following the adoption of its element or amendment, the planning agency shall submit a copy to the department. (h) The department shall, within 90 days, review adopted housing elements or amendments and report its findings to the planning agency. (i) (1) (A) The department shall review any action or failure to act by the city, county, or city and county that it determines is inconsistent with an adopted housing element or Section 65583, including any failure to implement any program actions included in the housing element pursuant to Section 65583. The department shall issue written findings to the city, county, or city and county as to whether the action or failure to act substantially complies with this article, and provide a reasonable time no longer than 30 days for the city, county, or city and county to respond to the findings before taking any other action authorized by this section, including the action authorized by subparagraph (B). (B) If the department finds that the action or failure to act by the city, county, or city and county does not substantially comply with this article, and if it has issued findings pursuant to this section that an amendment to the housing element substantially complies with this article, the department may revoke its findings until it determines that the city, county, or city and county has come into compliance with this article. (2) The department may consult with any local government, public agency, group, or person, and shall receive and consider any written comments from any public agency, group, or person, regarding the action or failure to act by the city, county, or city and county described in paragraph (1), in determining whether the housing element substantially complies with this article. (j) The department shall notify the city, county, or city and county and may notify the office of the Attorney General that the city, county, or city and county is in violation of state law if the department finds that the housing element or an amendment to this element, or any action or failure to act described in subdivision (i), does not substantially comply with this article or that any local government has taken an action in violation of the following: (1) Housing Accountability Act (Section 65589.5). (2) Section 65863. (3) Chapter 4.3 (commencing with Section 65915). (4) Section 65008. (5) Housing Crisis Act of 2019 (Chapter 654, Statutes of 2019, Sections 65941.1, 65943, and 66300). (6) Section 8899.50. (7) Section 65913.4. (8) Article 11 (commencing with Section 65650). (9) Article 12 (commencing with Section 65660). (10) Section 65913.11. (11) Section 65863.2. (12) Chapter 4.1 (commencing with Section 65912.100). (k) Commencing July 1, 2019, prior to the Attorney General bringing any suit for a violation of the provisions identified in subdivision (j) related to housing element compliance and seeking remedies available pursuant to this subdivision, the department shall offer the jurisdiction the opportunity for two meetings in person or via telephone to discuss the violation, and shall provide the jurisdiction written findings regarding the violation. This paragraph does not affect any action filed prior to the effective date of this section. The requirements set forth in this subdivision do not apply to any suits brought for a violation or violations of paragraphs (1) and (3) to (9), inclusive, of subdivision (j). (l) In any action or special proceeding brought by the Attorney General relating to housing element compliance pursuant to a notice or referral under subdivision (j), the Attorney General may request, upon a finding of the court that the housing element does not substantially comply with the requirements of this article pursuant to this section, that the court issue an order or judgment directing the jurisdiction to bring its housing element into substantial compliance with the requirements of this article. The court shall retain jurisdiction to ensure that its order or judgment is carried out. If a court determines that the housing element of the jurisdiction substantially complies with this article, it shall have the same force and effect, for purposes of eligibility for any financial assistance that requires a housing element in substantial compliance and for purposes of any incentives provided under Section 65589.9, as a determination by the department that the housing element substantially complies with this article. (1) If the jurisdiction has not complied with the order or judgment after 12 months, the court shall conduct a status conference. Following the status conference, upon a determination that the jurisdiction failed to comply with the order or judgment compelling substantial compliance with the requirements of this article, the court shall impose fines on the jurisdiction, which shall be deposited into the Building Homes and Jobs Trust Fund. Any fine levied pursuant to this paragraph shall be in a minimum amount of ten thousand dollars ($10,000) per month, but shall not exceed one hundred thousand dollars ($100,000) per month, except as provided in paragraphs (2) and (3). In the event that the jurisdiction fails to pay fines imposed by the court in full and on time, the court may require the Controller to intercept any available state and local funds and direct such funds to the Building Homes and Jobs Trust Fund to correct the jurisdiction’s failure to pay. The intercept of the funds by the Controller for this purpose shall not violate any provision of the California Constitution. (2) If the jurisdiction has not complied with the order or judgment after three months following the imposition of fees described in paragraph (1), the court shall conduct a status conference. Following the status conference, if the court finds that the fees imposed pursuant to paragraph (1) are insufficient to bring the jurisdiction into compliance with the order or judgment, the court may multiply the fine determined pursuant to paragraph (1) by a factor of three. In the event that the jurisdiction fails to pay fines imposed by the court in full and on time, the court may require the Controller to intercept any available state and local funds and direct such funds to the Building Homes and Jobs Trust Fund to correct the jurisdiction’s failure to pay. The intercept of the funds by the Controller for this purpose shall not violate any provision of the California Constitution. (3) If the jurisdiction has not complied with the order or judgment six months following the imposition of fees described in paragraph (1), the court shall conduct a status conference. Upon a determination that the jurisdiction failed to comply with the order or judgment, the court may impose the following: (A) If the court finds that the fees imposed pursuant to paragraphs (1) and (2) are insufficient to bring the jurisdiction into compliance with the order or judgment, the court may multiply the fine determined pursuant to paragraph (1) by a factor of six. In the event that the jurisdiction fails to pay fines imposed by the court in full and on time, the court may require the Controller to intercept any available state and local funds and direct such funds to the Building Homes and Jobs Trust Fund to correct the jurisdiction’s failure to pay. The intercept of the funds by the Controller for this purpose shall not violate any provision of the California Constitution. (B) The court may order remedies available pursuant to Section 564 of the Code of Civil Procedure, under which the agent of the court may take all governmental actions necessary to bring the jurisdiction’s housing element into substantial compliance pursuant to this article in order to remedy identified deficiencies. The court shall determine whether the housing element of the jurisdiction substantially complies with this article and, once the court makes that determination, it shall have the same force and effect, for all purposes, as the department’s determination that the housing element substantially complies with this article. An agent appointed pursuant to this paragraph shall have expertise in planning in California. (4) This subdivision does not limit a court’s discretion to apply any and all remedies in an action or special proceeding for a violation of any law identified in subdivision (j). (m) In determining the application of the remedies available under subdivision (l), the court shall consider whether there are any mitigating circumstances delaying the jurisdiction from coming into compliance with state housing law. The court may consider whether a city, county, or city and county is making a good faith effort to come into substantial compliance or is facing substantial undue hardships. (n) Nothing in this section shall limit the authority of the office of the Attorney General to bring a suit to enforce state law in an independent capacity. The office of the Attorney General may seek all remedies available under law including those set forth in this section. (o) Notwithstanding Sections 11040 and 11042, if the Attorney General declines to represent the department in any action or special proceeding brought pursuant to a notice or referral under subdivision (j) the department may appoint or contract with other counsel for purposes of representing the department in the action or special proceeding. (p) Notwithstanding any other provision of law, the statute of limitations set forth in subdivision (a) of Section 338 of the Code of Civil Procedure shall apply to any action or special proceeding brought by the Office of the Attorney General or pursuant to a notice or referral under subdivision (j), or by the department pursuant to subdivision (o). SEC. 1.2. Section 65585 of the Government Code is amended to read: 65585. (a) In the preparation of its housing element, each city and county shall consider the guidelines adopted by the department pursuant to Section 50459 of the Health and Safety Code. Those guidelines shall be advisory to each city or county in the preparation of its housing element. (b) (1) At least 90 days prior to adoption of a revision of its housing element pursuant to subdivision (e) of Section 65588, or at least 60 days prior to the adoption of a subsequent amendment to this element, the planning agency shall submit a draft element revision or draft amendment to the department. The local government of the planning agency shall make the first draft revision of a housing element available for public comment for at least 30 days and, if any comments are received, the local government shall take at least 10 business days after the 30-day public comment period to consider and incorporate public comments into the draft revision prior to submitting it to the department. For any subsequent draft revision, the local government shall post the draft revision on its internet website and shall email a link to the draft revision to all individuals and organizations that have previously requested notices relating to the local government’s housing element at least seven days before submitting the draft revision to the department. (2) The planning agency staff shall collect and compile the public comments regarding the housing element received by the city, county, or city and county, and provide these comments to each member of the legislative body before it adopts the housing element. (3) The department shall review the draft and report its written findings to the planning agency within 90 days of its receipt of the first draft submittal for each housing element revision pursuant to subdivision (e) of Section 65588 or within 60 days of its receipt of a subsequent draft amendment or an adopted revision or adopted amendment to an element. The department shall not review the first draft submitted for each housing element revision pursuant to subdivision (e) of Section 65588 until the local government has made the draft available for public comment for at least 30 days and, if comments were received, has taken at least 10 business days to consider and incorporate public comments pursuant to paragraph (1). (c) In the preparation of its findings, the department may consult with any public agency, group, or person. The department shall receive and consider any written comments from any public agency, group, or person regarding the draft or adopted element or amendment under review. (d) In its written findings, the department shall determine whether the draft element or draft amendment substantially complies with this article. (e) Prior to the adoption of its draft element or draft amendment, the legislative body shall consider the findings made by the department. If the department’s findings are not available within the time limits set by this section, the legislative body may act without them. (f) If the department finds that the draft element or draft amendment does not substantially comply with this article, the legislative body shall take one of the following actions: (1) Change the draft element or draft amendment to substantially comply with this article. (2) Adopt the draft element or draft amendment without changes. The legislative body shall include in its resolution of adoption written findings which explain the reasons the legislative body believes that the draft element or draft amendment substantially complies with this article despite the findings of the department. (g) Promptly following the adoption of its element or amendment, the planning agency shall submit a copy to the department. (h) The department shall, within 90 days, review adopted housing elements or amendments and report its findings to the planning agency. (i) (1) (A) The department shall review any action or failure to act by the city, county, or city and county that it determines is inconsistent with an adopted housing element or Section 65583, including any failure to implement any program actions included in the housing element pursuant to Section 65583. The department shall issue written findings to the city, county, or city and county as to whether the action or failure to act substantially complies with this article, and provide a reasonable time no longer than 30 days for the city, county, or city and county to respond to the findings before taking any other action authorized by this section, including the action authorized by subparagraph (B). (B) If the department finds that the action or failure to act by the city, county, or city and county does not substantially comply with this article, and if it has issued findings pursuant to this section that an amendment to the housing element substantially complies with this article, the department may revoke its findings until it determines that the city, county, or city and county has come into compliance with this article. (2) The department may consult with any local government, public agency, group, or person, and shall receive and consider any written comments from any public agency, group, or person, regarding the action or failure to act by the city, county, or city and county described in paragraph (1), in determining whether the housing element substantially complies with this article. (j) The department shall notify the city, county, or city and county and may notify the office of the Attorney General that the city, county, or city and county is in violation of state law if the department finds that the housing element or an amendment to this element, or any action or failure to act described in subdivision (i), does not substantially comply with this article or that any local government has taken an action in violation of the following: (1) Housing Accountability Act (Section 65589.5). (2) Section 65863. (3) Chapter 4.3 (commencing with Section 65915). (4) Section 65008. (5) Housing Crisis Act of 2019 (Chapter 654, Statutes of 2019, Sections 65941.1, 65943, and 66300). (6) Section 8899.50. (7) Section 65913.4. (8) Article 11 (commencing with Section 65650). (9) Article 12 (commencing with Section 65660). (10) Section 65913.11. (11) Section 65400. (12) Section 65863.2. (k) Commencing July 1, 2019, prior to the Attorney General bringing any suit for a violation of the provisions identified in subdivision (j) related to housing element compliance and seeking remedies available pursuant to this subdivision, the department shall offer the jurisdiction the opportunity for two meetings in person or via telephone to discuss the violation, and shall provide the jurisdiction written findings regarding the violation. This paragraph does not affect any action filed prior to the effective date of this section. The requirements set forth in this subdivision do not apply to any suits brought for a violation or violations of paragraphs (1) and (3) to (9), inclusive, of subdivision (j). (l) In any action or special proceeding brought by the Attorney General relating to housing element compliance pursuant to a notice or referral under subdivision (j), the Attorney General may request, upon a finding of the court that the housing element does not substantially comply with the requirements of this article pursuant to this section, that the court issue an order or judgment directing the jurisdiction to bring its housing element into substantial compliance with the requirements of this article. The court shall retain jurisdiction to ensure that its order or judgment is carried out. If a court determines that the housing element of the jurisdiction substantially complies with this article, it shall have the same force and effect, for purposes of eligibility for any financial assistance that requires a housing element in substantial compliance and for purposes of any incentives provided under Section 65589.9, as a determination by the department that the housing element substantially complies with this article. (1) If the jurisdiction has not complied with the order or judgment after 12 months, the court shall conduct a status conference. Following the status conference, upon a determination that the jurisdiction failed to comply with the order or judgment compelling substantial compliance with the requirements of this article, the court shall impose fines on the jurisdiction, which shall be deposited into the Building Homes and Jobs Trust Fund. Any fine levied pursuant to this paragraph shall be in a minimum amount of ten thousand dollars ($10,000) per month, but shall not exceed one hundred thousand dollars ($100,000) per month, except as provided in paragraphs (2) and (3). In the event that the jurisdiction fails to pay fines imposed by the court in full and on time, the court may require the Controller to intercept any available state and local funds and direct such funds to the Building Homes and Jobs Trust Fund to correct the jurisdiction’s failure to pay. The intercept of the funds by the Controller for this purpose shall not violate any provision of the California Constitution. (2) If the jurisdiction has not complied with the order or judgment after three months following the imposition of fees described in paragraph (1), the court shall conduct a status conference. Following the status conference, if the court finds that the fees imposed pursuant to paragraph (1) are insufficient to bring the jurisdiction into compliance with the order or judgment, the court may multiply the fine determined pursuant to paragraph (1) by a factor of three. In the event that the jurisdiction fails to pay fines imposed by the court in full and on time, the court may require the Controller to intercept any available state and local funds and direct such funds to the Building Homes and Jobs Trust Fund to correct the jurisdiction’s failure to pay. The intercept of the funds by the Controller for this purpose shall not violate any provision of the California Constitution. (3) If the jurisdiction has not complied with the order or judgment six months following the imposition of fees described in paragraph (1), the court shall conduct a status conference. Upon a determination that the jurisdiction failed to comply with the order or judgment, the court may impose the following: (A) If the court finds that the fees imposed pursuant to paragraphs (1) and (2) are insufficient to bring the jurisdiction into compliance with the order or judgment, the court may multiply the fine determined pursuant to paragraph (1) by a factor of six. In the event that the jurisdiction fails to pay fines imposed by the court in full and on time, the court may require the Controller to intercept any available state and local funds and direct such funds to the Building Homes and Jobs Trust Fund to correct the jurisdiction’s failure to pay. The intercept of the funds by the Controller for this purpose shall not violate any provision of the California Constitution. (B) The court may order remedies available pursuant to Section 564 of the Code of Civil Procedure, under which the agent of the court may take all governmental actions necessary to bring the jurisdiction’s housing element into substantial compliance pursuant to this article in order to remedy identified deficiencies. The court shall determine whether the housing element of the jurisdiction substantially complies with this article and, once the court makes that determination, it shall have the same force and effect, for all purposes, as the department’s determination that the housing element substantially complies with this article. An agent appointed pursuant to this paragraph shall have expertise in planning in California. (4) This subdivision does not limit a court’s discretion to apply any and all remedies in an action or special proceeding for a violation of any law identified in subdivision (j). (m) In determining the application of the remedies available under subdivision (l), the court shall consider whether there are any mitigating circumstances delaying the jurisdiction from coming into compliance with state housing law. The court may consider whether a city, county, or city and county is making a good faith effort to come into substantial compliance or is facing substantial undue hardships. (n) Nothing in this section shall limit the authority of the office of the Attorney General to bring a suit to enforce state law in an independent capacity. The office of the Attorney General may seek all remedies available under law including those set forth in this section. (o) Notwithstanding Sections 11040 and 11042, if the Attorney General declines to represent the department in any action or special proceeding brought pursuant to a notice or referral under subdivision (j) the department may appoint or contract with other counsel for purposes of representing the department in the action or special proceeding. (p) Notwithstanding any other provision of law, the statute of limitations set forth in subdivision (a) of Section 338 of the Code of Civil Procedure shall apply to any action or special proceeding brought by the Office of the Attorney General or pursuant to a notice or referral under subdivision (j), or by the department pursuant to subdivision (o). SEC. 1.3. Section 65585 of the Government Code is amended to read: 65585. (a) In the preparation of its housing element, each city and county shall consider the guidelines adopted by the department pursuant to Section 50459 of the Health and Safety Code. Those guidelines shall be advisory to each city or county in the preparation of its housing element. (b) (1) At least 90 days prior to adoption of a revision of its housing element pursuant to subdivision (e) of Section 65588, or at least 60 days prior to the adoption of a subsequent amendment to this element, the planning agency shall submit a draft element revision or draft amendment to the department. The local government of the planning agency shall make the first draft revision of a housing element available for public comment for at least 30 days and, if any comments are received, the local government shall take at least 10 business days after the 30-day public comment period to consider and incorporate public comments into the draft revision prior to submitting it to the department. For any subsequent draft revision, the local government shall post the draft revision on its internet website and shall email a link to the draft revision to all individuals and organizations that have previously requested notices relating to the local government’s housing element at least seven days before submitting the draft revision to the department. (2) The planning agency staff shall collect and compile the public comments regarding the housing element received by the city, county, or city and county, and provide these comments to each member of the legislative body before it adopts the housing element. (3) The department shall review the draft and report its written findings to the planning agency within 90 days of its receipt of the first draft submittal for each housing element revision pursuant to subdivision (e) of Section 65588 or within 60 days of its receipt of a subsequent draft amendment or an adopted revision or adopted amendment to an element. The department shall not review the first draft submitted for each housing element revision pursuant to subdivision (e) of Section 65588 until the local government has made the draft available for public comment for at least 30 days and, if comments were received, has taken at least 10 business days to consider and incorporate public comments pursuant to paragraph (1). (c) In the preparation of its findings, the department may consult with any public agency, group, or person. The department shall receive and consider any written comments from any public agency, group, or person regarding the draft or adopted element or amendment under review. (d) In its written findings, the department shall determine whether the draft element or draft amendment substantially complies with this article. (e) Prior to the adoption of its draft element or draft amendment, the legislative body shall consider the findings made by the department. If the department’s findings are not available within the time limits set by this section, the legislative body may act without them. (f) If the department finds that the draft element or draft amendment does not substantially comply with this article, the legislative body shall take one of the following actions: (1) Change the draft element or draft amendment to substantially comply with this article. (2) Adopt the draft element or draft amendment without changes. The legislative body shall include in its resolution of adoption written findings which explain the reasons the legislative body believes that the draft element or draft amendment substantially complies with this article despite the findings of the department. (g) Promptly following the adoption of its element or amendment, the planning agency shall submit a copy to the department. (h) The department shall, within 90 days, review adopted housing elements or amendments and report its findings to the planning agency. (i) (1) (A) The department shall review any action or failure to act by the city, county, or city and county that it determines is inconsistent with an adopted housing element or Section 65583, including any failure to implement any program actions included in the housing element pursuant to Section 65583. The department shall issue written findings to the city, county, or city and county as to whether the action or failure to act substantially complies with this article, and provide a reasonable time no longer than 30 days for the city, county, or city and county to respond to the findings before taking any other action authorized by this section, including the action authorized by subparagraph (B). (B) If the department finds that the action or failure to act by the city, county, or city and county does not substantially comply with this article, and if it has issued findings pursuant to this section that an amendment to the housing element substantially complies with this article, the department may revoke its findings until it determines that the city, county, or city and county has come into compliance with this article. (2) The department may consult with any local government, public agency, group, or person, and shall receive and consider any written comments from any public agency, group, or person, regarding the action or failure to act by the city, county, or city and county described in paragraph (1), in determining whether the housing element substantially complies with this article. (j) The department shall notify the city, county, or city and county and may notify the office of the Attorney General that the city, county, or city and county is in violation of state law if the department finds that the housing element or an amendment to this element, or any action or failure to act described in subdivision (i), does not substantially comply with this article or that any local government has taken an action in violation of the following: (1) Housing Accountability Act (Section 65589.5). (2) Section 65863. (3) Chapter 4.3 (commencing with Section 65915). (4) Section 65008. (5) Housing Crisis Act of 2019 (Chapter 654, Statutes of 2019, Sections 65941.1, 65943, and 66300). (6) Section 8899.50. (7) Section 65913.4. (8) Article 11 (commencing with Section 65650). (9) Article 12 (commencing with Section 65660). (10) Section 65913.11. (11) Section 65400. (12) Section 65863.2. (13) Chapter 4.1 (commencing with Section 65912.100) (k) Commencing July 1, 2019, prior to the Attorney General bringing any suit for a violation of the provisions identified in subdivision (j) related to housing element compliance and seeking remedies available pursuant to this subdivision, the department shall offer the jurisdiction the opportunity for two meetings in person or via telephone to discuss the violation, and shall provide the jurisdiction written findings regarding the violation. This paragraph does not affect any action filed prior to the effective date of this section. The requirements set forth in this subdivision do not apply to any suits brought for a violation or violations of paragraphs (1) and (3) to (9), inclusive, of subdivision (j). (l) In any action or special proceeding brought by the Attorney General relating to housing element compliance pursuant to a notice or referral under subdivision (j), the Attorney General may request, upon a finding of the court that the housing element does not substantially comply with the requirements of this article pursuant to this section, that the court issue an order or judgment directing the jurisdiction to bring its housing element into substantial compliance with the requirements of this article. The court shall retain jurisdiction to ensure that its order or judgment is carried out. If a court determines that the housing element of the jurisdiction substantially complies with this article, it shall have the same force and effect, for purposes of eligibility for any financial assistance that requires a housing element in substantial compliance and for purposes of any incentives provided under Section 65589.9, as a determination by the department that the housing element substantially complies with this article. (1) If the jurisdiction has not complied with the order or judgment after 12 months, the court shall conduct a status conference. Following the status conference, upon a determination that the jurisdiction failed to comply with the order or judgment compelling substantial compliance with the requirements of this article, the court shall impose fines on the jurisdiction, which shall be deposited into the Building Homes and Jobs Trust Fund. Any fine levied pursuant to this paragraph shall be in a minimum amount of ten thousand dollars ($10,000) per month, but shall not exceed one hundred thousand dollars ($100,000) per month, except as provided in paragraphs (2) and (3). In the event that the jurisdiction fails to pay fines imposed by the court in full and on time, the court may require the Controller to intercept any available state and local funds and direct such funds to the Building Homes and Jobs Trust Fund to correct the jurisdiction’s failure to pay. The intercept of the funds by the Controller for this purpose shall not violate any provision of the California Constitution. (2) If the jurisdiction has not complied with the order or judgment after three months following the imposition of fees described in paragraph (1), the court shall conduct a status conference. Following the status conference, if the court finds that the fees imposed pursuant to paragraph (1) are insufficient to bring the jurisdiction into compliance with the order or judgment, the court may multiply the fine determined pursuant to paragraph (1) by a factor of three. In the event that the jurisdiction fails to pay fines imposed by the court in full and on time, the court may require the Controller to intercept any available state and local funds and direct such funds to the Building Homes and Jobs Trust Fund to correct the jurisdiction’s failure to pay. The intercept of the funds by the Controller for this purpose shall not violate any provision of the California Constitution. (3) If the jurisdiction has not complied with the order or judgment six months following the imposition of fees described in paragraph (1), the court shall conduct a status conference. Upon a determination that the jurisdiction failed to comply with the order or judgment, the court may impose the following: (A) If the court finds that the fees imposed pursuant to paragraphs (1) and (2) are insufficient to bring the jurisdiction into compliance with the order or judgment, the court may multiply the fine determined pursuant to paragraph (1) by a factor of six. In the event that the jurisdiction fails to pay fines imposed by the court in full and on time, the court may require the Controller to intercept any available state and local funds and direct such funds to the Building Homes and Jobs Trust Fund to correct the jurisdiction’s failure to pay. The intercept of the funds by the Controller for this purpose shall not violate any provision of the California Constitution. (B) The court may order remedies available pursuant to Section 564 of the Code of Civil Procedure, under which the agent of the court may take all governmental actions necessary to bring the jurisdiction’s housing element into substantial compliance pursuant to this article in order to remedy identified deficiencies. The court shall determine whether the housing element of the jurisdiction substantially complies with this article and, once the court makes that determination, it shall have the same force and effect, for all purposes, as the department’s determination that the housing element substantially complies with this article. An agent appointed pursuant to this paragraph shall have expertise in planning in California. (4) This subdivision does not limit a court’s discretion to apply any and all remedies in an action or special proceeding for a violation of any law identified in subdivision (j). (m) In determining the application of the remedies available under subdivision (l), the court shall consider whether there are any mitigating circumstances delaying the jurisdiction from coming into compliance with state housing law. The court may consider whether a city, county, or city and county is making a good faith effort to come into substantial compliance or is facing substantial undue hardships. (n) Nothing in this section shall limit the authority of the office of the Attorney General to bring a suit to enforce state law in an independent capacity. The office of the Attorney General may seek all remedies available under law including those set forth in this section. (o) Notwithstanding Sections 11040 and 11042, if the Attorney General declines to represent the department in any action or special proceeding brought pursuant to a notice or referral under subdivision (j) the department may appoint or contract with other counsel for purposes of representing the department in the action or special proceeding. (p) Notwithstanding any other provision of law, the statute of limitations set forth in subdivision (a) of Section 338 of the Code of Civil Procedure shall apply to any action or special proceeding brought by the Office of the Attorney General or pursuant to a notice or referral under subdivision (j), or by the department pursuant to subdivision (o). SEC. 2. Section 65863.2 is added to the Government Code, to read: 65863.2. (a) A public agency shall not impose or enforce any minimum automobile parking requirement on a residential, commercial, or other development project if the project is located within one-half mile of public transit. (b) Notwithstanding subdivision (a), a city, county, or city and county may impose or enforce minimum automobile parking requirements on a project that is located within one-half mile of public transit if the public agency makes written findings, within 30 days of the receipt of a completed application, that not imposing or enforcing minimum automobile parking requirements on the development would have a substantially negative impact, supported by a preponderance of the evidence in the record, on any of the following: (1) The city’s, county’s, or city and county’s ability to meet its share of the regional housing need in accordance with Section 65584 for low- and very low income households. (2) The city’s, county’s, or city and county’s ability to meet any special housing needs for the elderly or persons with disabilities identified in the analysis required pursuant to paragraph (7) of subdivision (a) of Section 65583. (3) Existing residential or commercial parking within one-half mile of the housing development project. (c) For a housing development project, subdivision (b) shall not apply if the housing development project satisfies any of the following: (1) The development dedicates a minimum of 20 percent of the total number of housing units to very low, low-, or moderate-income households, students, the elderly, or persons with disabilities. (2) The development contains fewer than 20 housing units. (3) The development is subject to parking reductions based on the provisions of any other applicable law. (d) Notwithstanding subdivision (a), an event center shall provide parking, as required by local ordinance, for employees and other workers. (e) For purposes of this section: (1) “Housing development project” means a housing development project as defined in paragraph (2) of subdivision (h) of Section 65589.5. (2) “Low- and very low income households” means the same as “lower income households” as defined in Section 50079.5 of the Health and Safety Code. (3) “Moderate-income households” means the same as “persons and families of moderate income,” as defined in Section 50093 of the Health and Safety Code. (4) “Public agency” means the state or any state agency, board, or commission, any city, county, city and county, including charter cities, or special district, or any agency, board, or commission of the city, county, city and county, special district, joint powers authority, or other political subdivision. (5) “Public transit” means a major transit stop as defined in Section 21155 of the Public Resources Code. (6) “Project” does not include a project where any portion is designated for use as a hotel, motel, bed and breakfast inn, or other transient lodging, except where a portion of a housing development project is designated for use as a residential hotel, as defined in Section 50519 of the Health and Safety Code. (f) This section shall not reduce, eliminate, or preclude the enforcement of any requirement imposed on a new multifamily residential or nonresidential development that is located within one-half mile of public transit to provide electric vehicle supply equipment installed parking spaces or parking spaces that are accessible to persons with disabilities that would have otherwise applied to the development if this section did not apply. (g) When a project provides parking voluntarily, a public agency may impose requirements on that voluntary parking to require spaces for car share vehicles, require spaces to be shared with the public, or require parking owners to charge for parking. A public agency may not require that voluntarily provided parking is provided to residents free of charge. (h) (1) Subdivision (a) shall not apply to commercial parking requirements if it conflicts with an existing contractual agreement of the public agency that was executed before January 1, 2023, provided that all of the required commercial parking is shared with the public. This subdivision shall apply to an existing contractual agreement that is amended after January 1, 2023, provided that the amendments do not increase commercial parking requirements. (2) A project may voluntarily build additional parking that is not shared with the public. (i) The Legislature finds and declares that the imposition of mandatory parking minimums can increase the cost of housing, limit the number of available units, lead to an oversupply of parking spaces, and increased greenhouse gas emissions. Therefore, this section shall be interpreted in favor of the prohibition of the imposition of mandatory parking minimums as outlined in this section. SEC. 3. The Legislature finds and declares that to lower the cost of housing production by reducing unnecessary parking requirements is a matter of statewide concern and is not a municipal affair as that term is used in Section 5 of Article XI of the California Constitution. Therefore, Section 2 of this act adding Section 65863.2 to the Government Code applies to all cities, including charter cities. SEC. 4. (a) Section 1.1 of this bill incorporates amendments to Section 65585 of the Government Code proposed by both this bill and Assembly Bill 2011. That section of this bill shall only become operative if (1) both bills are enacted and become effective on or before January 1, 2023, (2) each bill amends Section 65585 of the Government Code, and (3) Assembly Bill 2653 is not enacted or as enacted does not amend that section, and (4) this bill is enacted after Assembly Bill 2011, in which case Sections 1, 1.2, and 1.3 of this bill shall not become operative. (b) Section 1.2 of this bill incorporates amendments to Section 65585 of the Government Code proposed by both this bill and Assembly Bill 2653. That section of this bill shall only become operative if (1) both bills are enacted and become effective on or before January 1, 2023, (2) each bill amends Section 65585 of the Government Code, (3) Assembly Bill 2011 is not enacted or as enacted does not amend that section, and (4) this bill is enacted after Assembly Bill 2653 in which case Sections 1, 1.1, and 1.3 of this bill shall not become operative. (c) Section 1.3 of this bill incorporates amendments to Section 65585 of the Government Code proposed by this bill, Assembly Bill 2011, and Assembly Bill 2653. That section of this bill shall only become operative if (1) all three bills are enacted and become effective on or before January 1, 2023, (2) all three bills amend Section 65585 of the Government Code, and (3) this bill is enacted after Assembly Bill 2011 and Assembly Bill 2653, in which case Sections 1, 1.1, and 1.2 of this bill shall not become operative. SEC. 5. No reimbursement is required by this act pursuant to Section 6 of Article XIII B of the California Constitution because a local agency or school district has the authority to levy service charges, fees, or assessments sufficient to pay for the program or level of service mandated by this act, within the meaning of Section 17556 of the Government Code. [Chaptered text of AB 2097 (2021-2022), saved by browser from leginfo.legislature.ca.gov on 2026-09-30; the site's robots.txt disallows crawling.]

---
snapshot_id: 9e2d72ba-9f81-5280-9411-ee545091da00
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220AB2097

BILL VOTES AB-2097 Residential, commercial, or other development types: parking requirements.(2021-2022) Bill Votes Date 08/30/22 Result (PASS) Location Assembly Floor Ayes Count 52 Noes Count 17 NVR Count 11 Motion AB 2097 Friedman Concurrence in Senate Amendments Ayes Aguiar-Curry, Alvarez, Bennett, Berman, Bloom, Mia Bonta, Bryan, Calderon, Carrillo, Cervantes, Chen, Cooper, Daly, Mike Fong, Fong, Friedman, Gabriel, Gallagher, Eduardo Garcia, Gipson, Grayson, Haney, Holden, Jones-Sawyer, Kalra, Lee, Levine, Low, McCarty, McKinnor, Medina, Mullin, Patterson, Quirk, Quirk-Silva, Ramos, Reyes, Luz Rivas, Robert Rivas, Rodriguez, Blanca Rubio, Santiago, Stone, Ting, Villapudua, Waldron, Ward, Akilah Weber, Wicks, Wilson, Wood, Rendon Noes Bauer-Kahan, Bigelow, Choi, Cooley, Cunningham, Megan Dahle, Davies, Flora, Kiley, Mathis, Nguyen, O'Donnell, Salas, Seyarto, Smith, Valladares, Voepel NVR Arambula, Boerner Horvath, Cristina Garcia, Gray, Irwin, Lackey, Maienschein, Mayes, Muratsuchi, Nazarian, Petrie-Norris [Floor vote from the bill votes page for AB 2097 (2021-2022), saved by browser from leginfo.legislature.ca.gov on 2026-09-30; the site's robots.txt disallows crawling.]