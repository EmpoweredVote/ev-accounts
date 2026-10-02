You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-28-shadow-pellerin/labels/coder-3.json. Write JSON only, matching
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

politician_id: 190c3584-0826-4a5f-a2ad-104ff70ff259  office_id: 4164cda9-e149-46c7-9b5a-7f1f75088ac0
Gail Pellerin — Assembly Member, California (seated, level: state)
Current term: 2022-12-05 (precision: day) to present

## Topics (served ladder text — code against these words only)

### topic_key: misinformation
topic_id: ddd65d64-9dc7-4208-a30f-59f4b9c0653d  served_revision_id: bd313c07-02a5-4344-8cc3-0e4b4c3b78a1
Question: What responsibility do platforms and government have in combating online misinformation?
  1. legally require platforms to remove false information
  2. require platforms to label false content, rather than remove it
  3. encourage voluntary standards for combating misinformation online
  4. protect free speech online and prevent government censorship
  5. ban any government involvement in content moderation decisions

#### Annex

(no annex for this topic yet — apply the codebook alone)

## Sources

---
snapshot_id: 8dca6231-481c-5393-ad92-d19f85d328ae
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202320240AB2839

Assembly Bill No. 2839 CHAPTER 262 An act to amend Section 35 of the Code of Civil Procedure, and to add Section 20012 to the Elections Code, relating to elections, and declaring the urgency thereof, to take effect immediately. [ Approved by Governor September 17, 2024. Filed with Secretary of State September 17, 2024. ] LEGISLATIVE COUNSEL'S DIGEST AB 2839, Pellerin. Elections: deceptive media in advertisements. Existing law prohibits certain distribution of materially deceptive audio or visual media of a candidate within 60 days of an election at which the candidate will appear on the ballot, unless the media includes a disclosure stating that the media has been manipulated, subject to specified exemptions. Existing law authorizes a candidate whose voice or likeness appears in audio or visual media distributed in violation of these provisions to file specified actions, and it requires a court to place such proceedings on the calendar in the order of their date of filing and give the proceedings precedence. This bill would prohibit a person, committee, or other entity from knowingly distributing an advertisement or other election communication, as defined, that contains certain materially deceptive content, as defined, with malice, as defined, subject to specified exemptions. The bill would apply this prohibition within 120 days of an election in California and, in specified cases, 60 days after an election. The bill would authorize a recipient of materially deceptive content distributed in violation of this section, candidate or committee participating in the election, or elections official, as defined, to file a civil action to enjoin the distribution of the media and to seek damages against the person, committee, or other entity that distributed it, except as specified. The bill would require a court to place such proceedings on the calendar in the order of their date of filing and give the proceedings precedence. This bill would incorporate additional changes to Section 35 of the Code of Civil Procedure proposed by AB 2655 to be operative only if this bill and AB 2655 are enacted and this bill is enacted last. This bill would declare that it is to take effect immediately as an urgency statute. DIGEST KEY Vote: 2/3 Appropriation: no Fiscal Committee: no Local Program: no BILL TEXT THE PEOPLE OF THE STATE OF CALIFORNIA DO ENACT AS FOLLOWS: SECTION 1. Section 35 of the Code of Civil Procedure, as amended by Section 1 of Chapter 343 of the Statutes of 2023, is amended to read: 35. (a) Proceedings in cases involving the registration or denial of registration of voters, the certification or denial of certification of candidates, the certification or denial of certification of ballot measures, election contests, actions under Section 20010 or 20012 of the Elections Code, and actions under Chapter 2 (commencing with Section 21100) of Division 21 of the Elections Code shall be placed on the calendar in the order of their date of filing and shall be given precedence. (b) This section shall remain in effect only until January 1, 2027, and as of that date is repealed, unless a later enacted statute, that is enacted before January 1, 2027, deletes or extends that date. SEC. 1.5. Section 35 of the Code of Civil Procedure, as amended by Section 1 of Chapter 343 of the Statutes of 2023, is amended to read: 35. (a) Proceedings in cases involving the registration or denial of registration of voters, the certification or denial of certification of candidates, the certification or denial of certification of ballot measures, election contests, actions under Section 20010 or 20012 of the Elections Code, actions under Chapter 7 (commencing with Section 20510) of Division 20 of the Elections Code, and actions under Chapter 2 (commencing with Section 21100) of Division 21 of the Elections Code shall be placed on the calendar in the order of their date of filing and shall be given precedence. (b) This section shall remain in effect only until January 1, 2027, and as of that date is repealed, unless a later enacted statute, that is enacted before January 1, 2027, deletes or extends that date. SEC. 2. Section 35 of the Code of Civil Procedure, as amended by Section 2 of Chapter 343 of the Statutes of 2023, is amended to read: 35. (a) Proceedings in cases involving the registration or denial of registration of voters, the certification or denial of certification of candidates, the certification or denial of certification of ballot measures, election contests, actions under Section 20012 of the Elections Code, and actions under Chapter 2 (commencing with Section 21100) of Division 21 of the Elections Code shall be placed on the calendar in the order of their date of filing and shall be given precedence. (b) This section shall become operative January 1, 2027. SEC. 2.5. Section 35 of the Code of Civil Procedure, as amended by Section 2 of Chapter 343 of the Statutes of 2023, is amended to read: 35. (a) Proceedings in cases involving the registration or denial of registration of voters, the certification or denial of certification of candidates, the certification or denial of certification of ballot measures, election contests, actions under Section 20012 of the Elections Code, actions under Chapter 7 (commencing with Section 20510) of Division 20 of the Elections Code, and actions under Chapter 2 (commencing with Section 21100) of Division 21 of the Elections Code shall be placed on the calendar in the order of their date of filing and shall be given precedence. (b) This section shall become operative January 1, 2027. SEC. 3. Section 20012 is added to the Elections Code, to read: 20012. (a) The Legislature finds and declares as follows: (1) California is entering its first-ever artificial intelligence (AI) election, in which disinformation powered by generative AI will pollute our information ecosystems like never before. Voters will not know what images, audio, or video they can trust. (2) In a few clicks, using current technology, bad actors now have the power to create a false image of a candidate accepting a bribe, or a fake video of an elections official “caught on tape” saying that voting machines are not secure, or generate an artificial robocall in the Governor’s voice telling millions of Californians their voting site has changed. (3) In the lead-up to the 2024 presidential elections, candidates and parties are already creating and distributing deepfake images and audio and video content. These fake images or files can skew election results, even if they use older methods of distribution, such as mail, television, telephone, and text, and undermine trust in the ballot counting process. (4) In order to ensure California elections are free and fair, California must, for a limited time before and after elections, prevent the use of deepfakes and disinformation meant to prevent voters from voting and deceive voters based on fraudulent content. The provisions of this bill are narrowly tailored to advance California’s compelling interest in protecting free and fair elections. (5) The labeling information required by this bill is narrowly tailored to provide consumers with factual information about the inauthenticity of particular images, audio, video, or text content in order to prevent consumer deception. (b) (1) A person, committee, or other entity shall not, during the time period set forth in subdivision (c), with malice, knowingly distribute an advertisement or other election communication containing materially deceptive content of any of the following: (A) A candidate for any federal, state, or local elected office in California portrayed as doing or saying something that the candidate did not do or say if the content is reasonably likely to harm the reputation or electoral prospects of a candidate. (i) For purposes of subparagraph (A), “candidate for any federal, state, or local elected office” includes any person running for the office of President of the United States or Vice President of the United States who seeks to or will appear on a ballot issued in California. (B) An elections official portrayed as doing or saying something in connection with an election in California that the elections official did not do or say if the content is reasonably likely to falsely undermine confidence in the outcome of one or more election contests. (C) An elected official portrayed as doing or saying something in connection with an election in California that the elected official did not do or say if the content is reasonably likely to harm the reputation or electoral prospects of a candidate or is reasonably likely to falsely undermine confidence in the outcome of one or more election contests. (D) A voting machine, ballot, voting site, or other property or equipment related to an election in California portrayed in a materially false way if the content is reasonably likely to falsely undermine confidence in the outcome of one or more election contests. (2) Notwithstanding subparagraph (A) of paragraph (1), this section does not apply to a candidate portraying themself as doing or saying something that the candidate did not do or say if the content includes a disclosure stating “This ____ has been manipulated.” and complies with the following requirements: (A) The blank in the disclosure required by paragraph (2) shall be filled with whichever of the following terms most accurately describes the media: (i) Image. (ii) Audio. (iii) Video. (B) (i) For visual media, the text of the disclosure shall appear in a size that is easily readable by the average viewer and no smaller than the largest font size of other text appearing in the visual media. If the visual media does not include any other text, the disclosure shall appear in a size that is easily readable by the average viewer. For visual media that is video, the disclosure shall appear for the duration of the video. (ii) If the media consists of audio only, the disclosure shall be read in a clearly spoken manner and in a pitch that can be easily heard by the average listener, at the beginning of the audio, at the end of the audio, and, if the audio is greater than two minutes in length, interspersed within the audio at intervals of not greater than two minutes each. (3) Notwithstanding paragraph (1), this section does not apply to an advertisement or other election communication containing materially deceptive content that constitutes satire or parody if the communication includes a disclosure stating “This ____ has been manipulated for purposes of satire or parody.” The disclosure shall comply with the requirements set forth in subparagraphs (A) and (B) of paragraph (2). (4) (A) A person, committee, or other entity shall not, during the time period set forth in subdivision (c), do either of the following: (i) Remove any disclosure required by paragraph (2) or (3). (ii) Knowingly republish any content subject to paragraph (2) or (3) without the required disclosure. (B) A violation of subparagraph (A) is evidence of intent to knowingly distribute an advertisement or other election communication containing materially deceptive content, as prohibited by paragraph (1). (c) The prohibition in subdivision (b) applies only during the following time periods: (1) One hundred twenty days before any election in California. (2) For people and items set forth in subparagraphs (B) and (D) of paragraph (1) of subdivision (b), 120 days before any election in California through 60 days after the election, inclusive. (d) (1) A recipient of materially deceptive content distributed in violation of this section, candidate or committee participating in the election, or elections official may seek injunctive or other equitable relief prohibiting the distribution of the materially deceptive content in violation of this section. The court shall also award a prevailing plaintiff reasonable attorney’s fees and costs. An action under this paragraph shall be entitled to precedence in accordance with Section 35 of the Code of Civil Procedure. (2) (A) A recipient of materially deceptive content distributed in violation of this section, candidate or committee participating in the election, or elections official may bring an action for general or special damages against the person, committee, or other entity that distributed or republished the materially deceptive content in violation of this section. The court shall also award a prevailing party reasonable attorney’s fees and costs. This subdivision shall not be construed to limit or preclude a plaintiff from securing or recovering any other available remedy at law or equity. (B) This paragraph does not apply to a broadcasting station or internet website that distributed the materially deceptive content if the broadcasting station or internet website did not create the content. (3) In any civil action alleging a violation of this section, the plaintiff shall bear the burden of establishing the violation through clear and convincing evidence. (e) (1) This section does not apply to a broadcasting station that broadcasts any materially deceptive content prohibited by this section as part of a bona fide newscast, news interview, news documentary, commentary of general interest, or on-the-spot coverage of bona fide news events, if the broadcast clearly acknowledges through content or a disclosure, in a manner that can be easily heard or read by the average listener or viewer, that the materially deceptive content does not accurately represent any actual event, occurrence, appearance, speech, or expressive conduct. (2) This section does not apply to a broadcasting station when it is paid to broadcast materially deceptive content and either of the following circumstances exist: (A) The broadcasting station can show that it has prohibition and disclaimer requirements that are consistent with the requirements in this section and that it has provided those prohibition and disclaimer requirements to each person or entity that purchased the advertisement. (B) Federal law requires the broadcasting station to air advertisements from legally qualified candidates or prohibits the broadcasting station from censoring or altering the message. (3) This section does not apply to a regularly published newspaper, magazine, or other periodical of general circulation, including an internet or electronic publication, that routinely carries news and commentary of general interest, and that publishes any materially deceptive content prohibited by this section, if the publication clearly states that the materially deceptive content does not accurately represent any actual event, occurrence, appearance, speech, or expressive conduct. (4) This section does not impose liability on an interactive computer service, as defined in Section 230(f)(2) of Title 47 of the United States Code. (f) For purposes of this section, the following definitions apply: (1) “Advertisement” means any general or public communication that is authorized or paid for the purpose of supporting or opposing a candidate for elective office in California or a ballot measure that appears on a ballot issued in California and that is broadcast by or through television, radio, telephone, or text, distributed through the internet, or disseminated by print media, including billboards, video billboards or screens, and other similar types of advertising. (2) “Broadcasting station” means a radio or television broadcasting station, including any of the following: (i) Cable operator, programmer, or producer. (ii) Streaming service operator, programmer, or producer. (iii) Direct-to-home satellite television operator, programmer, or producer. (3) “Committee” means a committee as defined in Section 82013 of the Government Code. (4) “Deepfake” means audio or visual media that is digitally created or modified such that it would falsely appear to a reasonable person to be an authentic record of the actual speech or conduct of the individual depicted in the media. (5) “Election communication” means any general or public communication not covered under “advertisement” that is broadcast by or through television, radio, telephone, or text, distributed through the internet, or disseminated by print media, including billboards, video billboards or screens, and other similar types of communications, that concerns any of the following: (A) A candidate for office or ballot measure. (B) Voting or refraining from voting in an election. (C) The canvass of the vote. (6) “Elections official” means any of the following persons, but only in their capacity as a person charged with holding or conducting an election, conducting a canvass, assisting with the holding or conducting of an election or a canvass, or performing another duty related to administering the provisions of the Elections Code: (i) An elections official as defined in Section 320. (ii) The Secretary of State and their staff. (iii) A temporary worker, poll worker, or member of a precinct board. (iv) Any other person charged with holding or conducting an election, conducting a canvass, assisting with the holding or conducting of an election or a canvass, or performing another duty related to administering the provisions of the Elections Code. (7) “Malice” means the person, committee, or other entity distributed the audio or visual media knowing the materially deceptive content was false or with a reckless disregard for the truth. (8) (A) “Materially deceptive content” means audio or visual media that is intentionally digitally created or modified, which includes, but is not limited to, deepfakes, such that the content would falsely appear to a reasonable person to be an authentic record of the content depicted in the media. (B) “Materially deceptive content” does not include any audio or visual media that contains only minor modifications that do not significantly change the perceived contents or meaning of the content. Minor changes include changes to brightness or contrast of images, removal of background noise in audio, and other minor changes that do not impact the content of the audio or visual media. (9) “Recipient” includes a person who views, hears, or otherwise perceives an image or audio or video file that was initially distributed in violation of this section. (g) The provisions of this section apply regardless of the language used in the advertisement or solicitation. If the language used is not English, the disclosure required by paragraph (2) of subdivision (b) shall appear in the language used in the advertisement or solicitation. (h) The provisions of this section are severable. If any provision of this section or its application is held invalid, that invalidity shall not affect other provisions or applications that can be given effect without the invalid provision or application. SEC. 4. Section 1.5 of this bill incorporates amendments to Section 35 of the Code of Civil Procedure proposed by both this bill and Assembly Bill 2655. That section of this bill shall only become operative if (1) both bills are enacted and become effective on or before January 1, 2025, but this bill becomes operative first, (2) each bill amends Section 35 of the Code of Civil Procedure, as amended by Section 1 of Chapter 343 of the Statutes of 2023, and (3) this bill is enacted after Assembly Bill 2655, in which case Section 35 of the Code of Civil Procedure, as amended by Section 1 of this bill, shall remain operative only until the operative date of Assembly Bill 2655, at which time Section 1.5 of this bill shall become operative. SEC. 5. Section 2.5 of this bill incorporates amendments to Section 35 of the Code of Civil Procedure proposed by both this bill and Assembly Bill 2655. That section of this bill shall only become operative if (1) both bills are enacted and become effective on or before January 1, 2025, but this bill becomes operative first, (2) each bill amends Section 35 of the Code of Civil Procedure, as amended by Section 2 of Chapter 343 of the Statutes of 2023, and (3) this bill is enacted after Assembly Bill 2655, in which case Section 35 of the Code of Civil Procedure, as amended by Section 2 of this bill, shall remain operative only until the operative date of Assembly Bill 2655, at which time Section 2.5 of this bill shall become operative. SEC. 6. This act is an urgency statute necessary for the immediate preservation of the public peace, health, or safety within the meaning of Article IV of the California Constitution and shall go into immediate effect. The facts constituting the necessity are: California is approaching its first election influenced by artificial intelligence (“AI”), where disinformation generated by AI can distort voter awareness and perception of candidates, elections officials, elected officials, and voting apparatuses. In the lead-up to the 2024 presidential election, candidates and bad actors are already creating and distributing deepfake images and audio and video content. In order to implement the provisions of this act and safeguard the upcoming November 5, 2024, general election against disinformation propagated by AI and deepfake media, it is necessary for this act to take effect immediately. [Chaptered text of AB 2839 (2023-2024), saved by browser from leginfo.legislature.ca.gov on 2026-09-28; the site's robots.txt disallows crawling.]