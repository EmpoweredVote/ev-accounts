You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-29-shadow-aguiar-curry/labels/coder-3.json. Write JSON only, matching
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

## Sources

---
snapshot_id: b2056197-763a-566a-abad-fe59bef3eb40
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201720180SB54

Senate Bill No. 54 CHAPTER 495 An act to amend Sections 7282 and 7282.5 of, and to add Chapter 17.25 (commencing with Section 7284) to Division 7 of Title 1 of, the Government Code, and to repeal Section 11369 of the Health and Safety Code, relating to law enforcement. [ Approved by Governor October 05, 2017. Filed with Secretary of State October 05, 2017. ] LEGISLATIVE COUNSEL'S DIGEST SB 54, De León. Law enforcement: sharing data. Existing law provides that when there is reason to believe that a person arrested for a violation of specified controlled substance provisions may not be a citizen of the United States, the arresting agency shall notify the appropriate agency of the United States having charge of deportation matters. This bill would repeal those provisions. Existing law provides that whenever an individual who is a victim of or witness to a hate crime, or who otherwise can give evidence in a hate crime investigation, is not charged with or convicted of committing any crime under state law, a peace officer may not detain the individual exclusively for any actual or suspected immigration violation or report or turn the individual over to federal immigration authorities. This bill would, among other things and subject to exceptions, prohibit state and local law enforcement agencies, including school police and security departments, from using money or personnel to investigate, interrogate, detain, detect, or arrest persons for immigration enforcement purposes, as specified, and would, subject to exceptions, proscribe other activities or conduct in connection with immigration enforcement by law enforcement agencies. The bill would apply those provisions to the circumstances in which a law enforcement official has discretion to cooperate with immigration authorities. The bill would require, by October 1, 2018, the Attorney General, in consultation with the appropriate stakeholders, to publish model policies limiting assistance with immigration enforcement to the fullest extent possible for use by public schools, public libraries, health facilities operated by the state or a political subdivision of the state, and courthouses, among others. The bill would require, among others, all public schools, health facilities operated by the state or a political subdivision of the state, and courthouses to implement the model policy, or an equivalent policy. The bill would state that, among others, all other organizations and entities that provide services related to physical or mental health and wellness, education, or access to justice, including the University of California, are encouraged to adopt the model policy. The bill would require that a law enforcement agency that chooses to participate in a joint law enforcement task force, as defined, submit a report annually pertaining to task force operations to the Department of Justice, as specified. The bill would require the Attorney General, by March 1, 2019, and annually thereafter, to report on the types and frequency of joint law enforcement task forces, and other information, as specified, and to post those reports on the Attorney General’s Internet Web site. The bill would require law enforcement agencies to report to the department annually regarding transfers of persons to immigration authorities. The bill would require the Attorney General to publish guidance, audit criteria, and training recommendations regarding state and local law enforcement databases, for purposes of limiting the availability of information for immigration enforcement, as specified. The bill would require the Department of Corrections and Rehabilitation to provide a specified written consent form in advance of any interview between a person in department custody and the United States Immigration and Customs Enforcement regarding civil immigration violations. This bill would state findings and declarations of the Legislature relating to these provisions. By imposing additional duties on public schools and local law enforcement agencies, this bill would impose a state-mandated local program. The California Constitution requires the state to reimburse local agencies and school districts for certain costs mandated by the state. Statutory provisions establish procedures for making that reimbursement. This bill would provide that, if the Commission on State Mandates determines that the bill contains costs mandated by the state, reimbursement for those costs shall be made pursuant to the statutory provisions noted above. DIGEST KEY Vote: majority Appropriation: no Fiscal Committee: yes Local Program: yes BILL TEXT THE PEOPLE OF THE STATE OF CALIFORNIA DO ENACT AS FOLLOWS: SECTION 1. Section 7282 of the Government Code is amended to read: 7282. For purposes of this chapter, the following terms have the following meanings: (a) “Conviction” shall have the same meaning as subdivision (d) of Section 667 of the Penal Code. (b) “Eligible for release from custody” means that the individual may be released from custody because one of the following conditions has occurred: (1) All criminal charges against the individual have been dropped or dismissed. (2) The individual has been acquitted of all criminal charges filed against him or her. (3) The individual has served all the time required for his or her sentence. (4) The individual has posted a bond. (5) The individual is otherwise eligible for release under state or local law, or local policy. (c) “Hold request,” “notification request,” and “transfer request” have the same meanings as provided in Section 7283. Hold, notification, and transfer requests include requests issued by the United States Immigration and Customs Enforcement or the United States Customs and Border Protection as well as any other immigration authorities. (d) “Law enforcement official” means any local agency or officer of a local agency authorized to enforce criminal statutes, regulations, or local ordinances or to operate jails or to maintain custody of individuals in jails, and any person or local agency authorized to operate juvenile detention facilities or to maintain custody of individuals in juvenile detention facilities. (e) “Local agency” means any city, county, city and county, special district, or other political subdivision of the state. (f) “Serious felony” means any of the offenses listed in subdivision (c) of Section 1192.7 of the Penal Code and any offense committed in another state which, if committed in California, would be punishable as a serious felony as defined by subdivision (c) of Section 1192.7 of the Penal Code. (g) “Violent felony” means any of the offenses listed in subdivision (c) of Section 667.5 of the Penal Code and any offense committed in another state which, if committed in California, would be punishable as a violent felony as defined by subdivision (c) of Section 667.5 of the Penal Code. SEC. 2. Section 7282.5 of the Government Code is amended to read: 7282.5. (a) A law enforcement official shall have discretion to cooperate with immigration authorities only if doing so would not violate any federal, state, or local law, or local policy, and where permitted by the California Values Act (Chapter 17.25 (commencing with Section 7284)). Additionally, the specific activities described in subparagraph (C) of paragraph (1) of subdivision (a) of, and in paragraph (4) of subdivision (a) of, Section 7284.6 shall only occur under the following circumstances: (1) The individual has been convicted of a serious or violent felony identified in subdivision (c) of Section 1192.7 of, or subdivision (c) of Section 667.5 of, the Penal Code. (2) The individual has been convicted of a felony punishable by imprisonment in the state prison. (3) The individual has been convicted within the past five years of a misdemeanor for a crime that is punishable as either a misdemeanor or a felony for, or has been convicted within the last 15 years of a felony for, any of the following offenses: (A) Assault, as specified in, but not limited to, Sections 217.1, 220, 240, 241.1, 241.4, 241.7, 244, 244.5, 245, 245.2, 245.3, 245.5, 4500, and 4501 of the Penal Code. (B) Battery, as specified in, but not limited to, Sections 242, 243.1, 243.3, 243.4, 243.6, 243.7, 243.9, 273.5, 347, 4501.1, and 4501.5 of the Penal Code. (C) Use of threats, as specified in, but not limited to, Sections 71, 76, 139, 140, 422, 601, and 11418.5 of the Penal Code. (D) Sexual abuse, sexual exploitation, or crimes endangering children, as specified in, but not limited to, Sections 266, 266a, 266b, 266c, 266d, 266f, 266g, 266h, 266i, 266j, 267, 269, 288, 288.5, 311.1, 311.3, 311.4, 311.10, 311.11, and 647.6 of the Penal Code. (E) Child abuse or endangerment, as specified in, but not limited to, Sections 270, 271, 271a, 273a, 273ab, 273d, 273.4, and 278 of the Penal Code. (F) Burglary, robbery, theft, fraud, forgery, or embezzlement, as specified in, but not limited to, Sections 211, 215, 459, 463, 470, 476, 487, 496, 503, 518, 530.5, 532, and 550 of the Penal Code. (G) Driving under the influence of alcohol or drugs, but only for a conviction that is a felony. (H) Obstruction of justice, as specified in, but not limited to, Sections 69, 95, 95.1, 136.1, and 148.10 of the Penal Code. (I) Bribery, as specified in, but not limited to, Sections 67, 67.5, 68, 74, 85, 86, 92, 93, 137, 138, and 165 of the Penal Code. (J) Escape, as specified in, but not limited to, Sections 107, 109, 110, 4530, 4530.5, 4532, 4533, 4534, 4535, and 4536 of the Penal Code. (K) Unlawful possession or use of a weapon, firearm, explosive device, or weapon of mass destruction, as specified in, but not limited to, Sections 171b, 171c, 171d, 246, 246.3, 247, 417, 417.3, 417.6, 417.8, 4574, 11418, 11418.1, 12021.5, 12022, 12022.2, 12022.3, 12022.4, 12022.5, 12022.53, 12022.55, 18745, 18750, and 18755 of, and subdivisions (c) and (d) of Section 26100 of, the Penal Code. (L) Possession of an unlawful deadly weapon, under the Deadly Weapons Recodification Act of 2010 (Part 6 (commencing with Section 16000) of the Penal Code). (M) An offense involving the felony possession, sale, distribution, manufacture, or trafficking of controlled substances. (N) Vandalism with prior convictions, as specified in, but not limited to, Section 594.7 of the Penal Code. (O) Gang-related offenses, as specified in, but not limited to, Sections 186.22, 186.26, and 186.28 of the Penal Code. (P) An attempt, as defined in Section 664 of, or a conspiracy, as defined in Section 182 of, the Penal Code, to commit an offense specified in this section. (Q) A crime resulting in death, or involving the personal infliction of great bodily injury, as specified in, but not limited to, subdivision (d) of Section 245.6 of, and Sections 187, 191.5, 192, 192.5, 12022.7, 12022.8, and 12022.9 of, the Penal Code. (R) Possession or use of a firearm in the commission of an offense. (S) An offense that would require the individual to register as a sex offender pursuant to Section 290, 290.002, or 290.006 of the Penal Code. (T) False imprisonment, slavery, and human trafficking, as specified in, but not limited to, Sections 181, 210.5, 236, 236.1, and 4503 of the Penal Code. (U) Criminal profiteering and money laundering, as specified in, but not limited to, Sections 186.2, 186.9, and 186.10 of the Penal Code. (V) Torture and mayhem, as specified in, but not limited to, Section 203 of the Penal Code. (W) A crime threatening the public safety, as specified in, but not limited to, Sections 219, 219.1, 219.2, 247.5, 404, 404.6, 405a, 451, and 11413 of the Penal Code. (X) Elder and dependent adult abuse, as specified in, but not limited to, Section 368 of the Penal Code. (Y) A hate crime, as specified in, but not limited to, Section 422.55 of the Penal Code. (Z) Stalking, as specified in, but not limited to, Section 646.9 of the Penal Code. (AA) Soliciting the commission of a crime, as specified in, but not limited to, subdivision (c) of Section 286 of, and Sections 653j and 653.23 of, the Penal Code. (AB) An offense committed while on bail or released on his or her own recognizance, as specified in, but not limited to, Section 12022.1 of the Penal Code. (AC) Rape, sodomy, oral copulation, or sexual penetration, as specified in, but not limited to, paragraphs (2) and (6) of subdivision (a) of Section 261 of, paragraphs (1) and (4) of subdivision (a) of Section 262 of, Section 264.1 of, subdivisions (c) and (d) of Section 286 of, subdivisions (c) and (d) of Section 288a of, and subdivisions (a) and (j) of Section 289 of, the Penal Code. (AD) Kidnapping, as specified in, but not limited to, Sections 207, 209, and 209.5 of the Penal Code. (AE) A violation of subdivision (c) of Section 20001 of the Vehicle Code. (4) The individual is a current registrant on the California Sex and Arson Registry. (5) The individual has been convicted of a federal crime that meets the definition of an aggravated felony as set forth in subparagraphs (A) to (P), inclusive, of paragraph (43) of subsection (a) of Section 101 of the federal Immigration and Nationality Act (8 U.S.C. Sec. 1101), or is identified by the United States Department of Homeland Security’s Immigration and Customs Enforcement as the subject of an outstanding federal felony arrest warrant. (6) In no case shall cooperation occur pursuant to this section for individuals arrested, detained, or convicted of misdemeanors that were previously felonies, or were previously crimes punishable as either misdemeanors or felonies, prior to passage of the Safe Neighborhoods and Schools Act of 2014 as it amended the Penal Code. (b) In cases in which the individual is arrested and taken before a magistrate on a charge involving a serious or violent felony, as identified in subdivision (c) of Section 1192.7 or subdivision (c) of Section 667.5 of the Penal Code, respectively, or a felony that is punishable by imprisonment in state prison, and the magistrate makes a finding of probable cause as to that charge pursuant to Section 872 of the Penal Code, a law enforcement official shall additionally have discretion to cooperate with immigration officials pursuant to subparagraph (C) of paragraph (1) of subdivision (a) of Section 7284.6. SEC. 3. Chapter 17.25 (commencing with Section 7284) is added to Division 7 of Title 1 of the Government Code, to read: CHAPTER 17.25. Cooperation with Immigration Authorities 7284. This chapter shall be known, and may be cited, as the California Values Act. 7284.2. The Legislature finds and declares the following: (a) Immigrants are valuable and essential members of the California community. Almost one in three Californians is foreign born and one in two children in California has at least one immigrant parent. (b) A relationship of trust between California’s immigrant community and state and local agencies is central to the public safety of the people of California. (c) This trust is threatened when state and local agencies are entangled with federal immigration enforcement, with the result that immigrant community members fear approaching police when they are victims of, and witnesses to, crimes, seeking basic health services, or attending school, to the detriment of public safety and the well-being of all Californians. (d) Entangling state and local agencies with federal immigration enforcement programs diverts already limited resources and blurs the lines of accountability between local, state, and federal governments. (e) State and local participation in federal immigration enforcement programs also raises constitutional concerns, including the prospect that California residents could be detained in violation of the Fourth Amendment to the United States Constitution, targeted on the basis of race or ethnicity in violation of the Equal Protection Clause, or denied access to education based on immigration status. See Sanchez Ochoa v. Campbell, et al. (E.D. Wash. 2017) 2017 WL 3476777; Trujillo Santoya v. United States, et al. (W.D. Tex. 2017) 2017 WL 2896021; Moreno v. Napolitano (N.D. Ill. 2016) 213 F. Supp. 3d 999; Morales v. Chadbourne (1st Cir. 2015) 793 F.3d 208; Miranda-Olivares v. Clackamas County (D. Or. 2014) 2014 WL 1414305; Galarza v. Szalczyk (3d Cir. 2014) 745 F.3d 634. (f) This chapter seeks to ensure effective policing, to protect the safety, well-being, and constitutional rights of the people of California, and to direct the state’s limited resources to matters of greatest concern to state and local governments. (g) It is the intent of the Legislature that this chapter shall not be construed as providing, expanding, or ratifying any legal authority for any state or local law enforcement agency to participate in immigration enforcement. 7284.4. For purposes of this chapter, the following terms have the following meanings: (a) “California law enforcement agency” means a state or local law enforcement agency, including school police or security departments. “California law enforcement agency” does not include the Department of Corrections and Rehabilitation. (b) “Civil immigration warrant” means any warrant for a violation of federal civil immigration law, and includes civil immigration warrants entered in the National Crime Information Center database. (c) “Immigration authority” means any federal, state, or local officer, employee, or person performing immigration enforcement functions. (d) “Health facility” includes health facilities as defined in Section 1250 of the Health and Safety Code, clinics as defined in Sections 1200 and 1200.1 of the Health and Safety Code, and substance abuse treatment facilities. (e) “Hold request,” “notification request,” “transfer request,” and “local law enforcement agency” have the same meaning as provided in Section 7283. Hold, notification, and transfer requests include requests issued by United States Immigration and Customs Enforcement or United States Customs and Border Protection as well as any other immigration authorities. (f) “Immigration enforcement” includes any and all efforts to investigate, enforce, or assist in the investigation or enforcement of any federal civil immigration law, and also includes any and all efforts to investigate, enforce, or assist in the investigation or enforcement of any federal criminal immigration law that penalizes a person’s presence in, entry, or reentry to, or employment in, the United States. (g) “Joint law enforcement task force” means at least one California law enforcement agency collaborating, engaging, or partnering with at least one federal law enforcement agency in investigating federal or state crimes. (h) “Judicial probable cause determination” means a determination made by a federal judge or federal magistrate judge that probable cause exists that an individual has violated federal criminal immigration law and that authorizes a law enforcement officer to arrest and take into custody the individual. (i) “Judicial warrant” means a warrant based on probable cause for a violation of federal criminal immigration law and issued by a federal judge or a federal magistrate judge that authorizes a law enforcement officer to arrest and take into custody the person who is the subject of the warrant. (j) “Public schools” means all public elementary and secondary schools under the jurisdiction of local governing boards or a charter school board, the California State University, and the California Community Colleges. (k) “School police and security departments” includes police and security departments of the California State University, the California Community Colleges, charter schools, county offices of education, schools, and school districts. 7284.6. (a) California law enforcement agencies shall not: (1) Use agency or department moneys or personnel to investigate, interrogate, detain, detect, or arrest persons for immigration enforcement purposes, including any of the following: (A) Inquiring into an individual’s immigration status. (B) Detaining an individual on the basis of a hold request. (C) Providing information regarding a person’s release date or responding to requests for notification by providing release dates or other information unless that information is available to the public, or is in response to a notification request from immigration authorities in accordance with Section 7282.5. Responses are never required, but are permitted under this subdivision, provided that they do not violate any local law or policy. (D) Providing personal information, as defined in Section 1798.3 of the Civil Code, about an individual, including, but not limited to, the individual’s home address or work address unless that information is available to the public. (E) Making or intentionally participating in arrests based on civil immigration warrants. (F) Assisting immigration authorities in the activities described in Section 1357(a)(3) of Title 8 of the United States Code. (G) Performing the functions of an immigration officer, whether pursuant to Section 1357(g) of Title 8 of the United States Code or any other law, regulation, or policy, whether formal or informal. (2) Place peace officers under the supervision of federal agencies or employ peace officers deputized as special federal officers or special federal deputies for purposes of immigration enforcement. All peace officers remain subject to California law governing conduct of peace officers and the policies of the employing agency. (3) Use immigration authorities as interpreters for law enforcement matters relating to individuals in agency or department custody. (4) Transfer an individual to immigration authorities unless authorized by a judicial warrant or judicial probable cause determination, or in accordance with Section 7282.5. (5) Provide office space exclusively dedicated for immigration authorities for use within a city or county law enforcement facility. (6) Contract with the federal government for use of California law enforcement agency facilities to house individuals as federal detainees, except pursuant to Chapter 17.8 (commencing with Section 7310). (b) Notwithstanding the limitations in subdivision (a), this section does not prevent any California law enforcement agency from doing any of the following that does not violate any policy of the law enforcement agency or any local law or policy of the jurisdiction in which the agency is operating: (1) Investigating, enforcing, or detaining upon reasonable suspicion of, or arresting for a violation of, Section 1326(a) of Title 8 of the United States Code that may be subject to the enhancement specified in Section 1326(b)(2) of Title 8 of the United States Code and that is detected during an unrelated law enforcement activity. Transfers to immigration authorities are permitted under this subsection only in accordance with paragraph (4) of subdivision (a). (2) Responding to a request from immigration authorities for information about a specific person’s criminal history, including previous criminal arrests, convictions, or similar criminal history information accessed through the California Law Enforcement Telecommunications System (CLETS), where otherwise permitted by state law. (3) Conducting enforcement or investigative duties associated with a joint law enforcement task force, including the sharing of confidential information with other law enforcement agencies for purposes of task force investigations, so long as the following conditions are met: (A) The primary purpose of the joint law enforcement task force is not immigration enforcement, as defined in subdivision (f) of Section 7284.4. (B) The enforcement or investigative duties are primarily related to a violation of state or federal law unrelated to immigration enforcement. (C) Participation in the task force by a California law enforcement agency does not violate any local law or policy to which it is otherwise subject. (4) Making inquiries into information necessary to certify an individual who has been identified as a potential crime or trafficking victim for a T or U Visa pursuant to Section 1101(a)(15)(T) or 1101(a)(15)(U) of Title 8 of the United States Code or to comply with Section 922(d)(5) of Title 18 of the United States Code. (5) Giving immigration authorities access to interview an individual in agency or department custody. All interview access shall comply with requirements of the TRUTH Act (Chapter 17.2 (commencing with Section 7283)). (c) (1) If a California law enforcement agency chooses to participate in a joint law enforcement task force, for which a California law enforcement agency has agreed to dedicate personnel or resources on an ongoing basis, it shall submit a report annually to the Department of Justice, as specified by the Attorney General. The law enforcement agency shall report the following information, if known, for each task force of which it is a member: (A) The purpose of the task force. (B) The federal, state, and local law enforcement agencies involved. (C) The total number of arrests made during the reporting period. (D) The number of people arrested for immigration enforcement purposes. (2) All law enforcement agencies shall report annually to the Department of Justice, in a manner specified by the Attorney General, the number of transfers pursuant to paragraph (4) of subdivision (a), and the offense that allowed for the transfer, pursuant to paragraph (4) of subdivision (a). (3) All records described in this subdivision shall be public records for purposes of the California Public Records Act (Chapter 3.5 (commencing with Section 6250)), including the exemptions provided by that act and, as permitted under that act, personal identifying information may be redacted prior to public disclosure. To the extent that disclosure of a particular item of information would endanger the safety of a person involved in an investigation, or would endanger the successful completion of the investigation or a related investigation, that information shall not be disclosed. (4) If more than one California law enforcement agency is participating in a joint task force that meets the reporting requirement pursuant to this section, the joint task force shall designate a local or state agency responsible for completing the reporting requirement. (d) The Attorney General, by March 1, 2019, and annually thereafter, shall report on the total number of arrests made by joint law enforcement task forces, and the total number of arrests made for the purpose of immigration enforcement by all task force participants, including federal law enforcement agencies. To the extent that disclosure of a particular item of information would endanger the safety of a person involved in an investigation, or would endanger the successful completion of the investigation or a related investigation, that information shall not be included in the Attorney General’s report. The Attorney General shall post the reports required by this subdivision on the Attorney General’s Internet Web site. (e) This section does not prohibit or restrict any government entity or official from sending to, or receiving from, federal immigration authorities, information regarding the citizenship or immigration status, lawful or unlawful, of an individual, or from requesting from federal immigration authorities immigration status information, lawful or unlawful, of any individual, or maintaining or exchanging that information with any other federal, state, or local government entity, pursuant to Sections 1373 and 1644 of Title 8 of the United States Code. (f) Nothing in this section shall prohibit a California law enforcement agency from asserting its own jurisdiction over criminal law enforcement matters. 7284.8. (a) The Attorney General, by October 1, 2018, in consultation with the appropriate stakeholders, shall publish model policies limiting assistance with immigration enforcement to the fullest extent possible consistent with federal and state law at public schools, public libraries, health facilities operated by the state or a political subdivision of the state, courthouses, Division of Labor Standards Enforcement facilities, the Agricultural Labor Relations Board, the Division of Workers Compensation, and shelters, and ensuring that they remain safe and accessible to all California residents, regardless of immigration status. All public schools, health facilities operated by the state or a political subdivision of the state, and courthouses shall implement the model policy, or an equivalent policy. The Agricultural Labor Relations Board, the Division of Workers’ Compensation, the Division of Labor Standards Enforcement, shelters, libraries, and all other organizations and entities that provide services related to physical or mental health and wellness, education, or access to justice, including the University of California, are encouraged to adopt the model policy. (b) For any databases operated by state and local law enforcement agencies, including databases maintained for the agency by private vendors, the Attorney General shall, by October 1, 2018, in consultation with appropriate stakeholders, publish guidance, audit criteria, and training recommendations aimed at ensuring that those databases are governed in a manner that limits the availability of information therein to the fullest extent practicable and consistent with federal and state law, to anyone or any entity for the purpose of immigration enforcement. All state and local law enforcement agencies are encouraged to adopt necessary changes to database governance policies consistent with that guidance. (c) Notwithstanding the rulemaking provisions of the Administrative Procedure Act (Chapter 3.5 (commencing with Section 11340) of Part 1 of Division 3 of Title 2), the Department of Justice may implement, interpret, or make specific this chapter without taking any regulatory action. 7284.10. (a) The Department of Corrections and Rehabilitation shall: (1) In advance of any interview between the United States Immigration and Customs Enforcement (ICE) and an individual in department custody regarding civil immigration violations, provide the individual with a written consent form that explains the purpose of the interview, that the interview is voluntary, and that he or she may decline to be interviewed or may choose to be interviewed only with his or her attorney present. The written consent form shall be available in English, Spanish, Chinese, Tagalog, Vietnamese, and Korean. (2) Upon receiving any ICE hold, notification, or transfer request, provide a copy of the request to the individual and inform him or her whether the department intends to comply with the request. (b) The Department of Corrections and Rehabilitation shall not: (1) Restrict access to any in-prison educational or rehabilitative programming, or credit-earning opportunity on the sole basis of citizenship or immigration status, including, but not limited to, whether the person is in removal proceedings, or immigration authorities have issued a hold request, transfer request, notification request, or civil immigration warrant against the individual. (2) Consider citizenship and immigration status as a factor in determining a person’s custodial classification level, including, but not limited to, whether the person is in removal proceedings, or whether immigration authorities have issued a hold request, transfer request, notification request, or civil immigration warrant against the individual. 7284.12. The provisions of this act are severable. If any provision of this act or its application is held invalid, that invalidity shall not affect other provisions or applications that can be given effect without the invalid provision or application. SEC. 4. Section 11369 of the Health and Safety Code is repealed. SEC. 5. If the Commission on State Mandates determines that this act contains costs mandated by the state, reimbursement to local agencies and school districts for those costs shall be made pursuant to Part 7 (commencing with Section 17500) of Division 4 of Title 2 of the Government Code. [Chaptered text of SB 54 (2017-2018), saved by browser from leginfo.legislature.ca.gov on 2026-09-29; the site's robots.txt disallows crawling.]

---
snapshot_id: e45850e5-c900-5eb6-a053-26d4882babdc
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=201720180SB54

BILL VOTES SB-54 Law enforcement: sharing data.(2017-2018) Bill Votes Date 09/15/17 Result (PASS) Location Assembly Floor Ayes Count 51 Noes Count 26 NVR Count 2 Motion SB 54 De León Senate Third Reading By GONZALEZ FLETCHER Ayes Aguiar-Curry, Arambula, Berman, Bloom, Bocanegra, Bonta, Burke, Caballero, Calderon, Cervantes, Chau, Chiu, Chu, Cooley, Cooper, Dababneh, Daly, Eggman, Friedman, Cristina Garcia, Eduardo Garcia, Gipson, Gloria, Gonzalez Fletcher, Grayson, Holden, Irwin, Jones-Sawyer, Kalra, Levine, Limón, Low, McCarty, Medina, Mullin, Nazarian, O'Donnell, Quirk, Quirk-Silva, Reyes, Ridley-Thomas, Rodriguez, Rubio, Salas, Santiago, Mark Stone, Thurmond, Ting, Weber, Wood, Rendon Noes Acosta, Travis Allen, Baker, Bigelow, Brough, Chen, Choi, Cunningham, Dahle, Flora, Fong, Frazier, Gallagher, Gray, Harper, Kiley, Lackey, Maienschein, Mathis, Mayes, Melendez, Obernolte, Patterson, Steinorth, Voepel, Waldron NVR Chávez, Muratsuchi [Final floor vote from the bill votes page for SB 54 (2017-2018), saved by browser from leginfo.legislature.ca.gov on 2026-09-29; the site's robots.txt disallows crawling.]