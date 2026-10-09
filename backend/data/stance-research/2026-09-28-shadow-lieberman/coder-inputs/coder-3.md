You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-28-shadow-lieberman/labels/coder-3.json. Write JSON only, matching
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

politician_id: a6d492a6-0d29-4d8d-8533-a3ae82284696  office_id: d13d9c57-2851-48fb-a1a6-0b181f449453
Aaron Lieberman — State Senator, Arizona (candidate, level: state)
Candidate in the election of 2026-11-03
Earlier terms in this legislature: State Representative unknown (precision: unknown) to 2021-09-20

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

## Sources

---
snapshot_id: bf071e0c-333a-557c-93a0-8d56ca7f611e
source_kind: public-record
url: https://www.azleg.gov/legtext/55leg/1R/laws/0286.htm

Chapter 0286 - 551R - C Ver of SB1457 Conference Engrossed abortion; unborn child; genetic abnormality State of Arizona Senate Fifty-fifth Legislature First Regular Session 2021 CHAPTER 286 SENATE BILL 1457 AN ACT Amending title 1, chapter 2, article 2, Arizona Revised Statutes, by adding section 1-219; Amending section 13-3603.02, Arizona Revised Statutes; repealing section 13-3604, Arizona Revised Statutes; amending title 15, chapter 1, article 1, Arizona Revised Statutes, by adding section 15-115.01; Amending sections 35-196.04, 36-449.01, 36-449.03, 36-2151, 36-2153, 36-2157 and 36-2158, Arizona Revised Statutes; amending title 36, chapter 20, article 1, Arizona Revised Statutes, by adding section 36-2160; amending section 36-2161, Arizona Revised Statutes; relating to abortion. (TEXT OF BILL BEGINS ON NEXT PAGE) Be it enacted by the Legislature of the State of Arizona: Section 1. Title 1, chapter 2, article 2, Arizona Revised Statutes, is amended by adding section 1-219, to read: START_STATUTE 1-219. Interpretation of laws; unborn child; definition A. The laws of this state shall be interpreted and construed to acknowledge, on behalf of an unborn child at every stage of development, all rights, privileges and immunities available to other persons, citizens and residents of this state, subject only to the constitution of the United States and decisional interpretations thereof by the United States supreme court. B. This section does not create a cause of action against: 1. A person who performs in vitro fertilization procedures as authorized under the laws of this state. 2. A woman for indirectly harming her unborn child by failing to properly care for herself or by failing to follow any particular program of prenatal care. C. For the purposes of this section, "unborn child" has the same meaning prescribed in section 36-2151. END_STATUTE Sec. 2. Section 13-3603.02, Arizona Revised Statutes, is amended to read: START_STATUTE 13-3603.02. Abortion; sex and race selection; genetic abnormality; injunctive and civil relief; failure to report; definitions A. Except in a medical emergency, a person who knowingly does any of the following is guilty of a class [deleted: 3] 6 felony: 1. Performs an abortion knowing that the abortion is sought based on the sex or race of the child or the race of a parent of that child. 2. Performs an abortion knowing that the abortion is sought solely because of a genetic abnormality of the child. B. A person who knowingly does either of the following is guilty of a class 3 felony: [deleted: 2.] 1. Uses force or the threat of force to intentionally injure or intimidate any person for the purpose of coercing a sex-selection or race-selection abortion or an abortion because of a genetic abnormality of the child . [deleted: 3.] 2. Solicits or accepts monies to finance a sex-selection or race-selection abortion or an abortion because of a genetic abnormality of the child . [deleted: B.] C. The attorney general or the county attorney may bring an action in superior court to enjoin the activity described in subsection A or B of this section. [deleted: C.] D. The father of the unborn child who is married to the mother at the time she receives a sex-selection or race-selection abortion or an abortion because of a genetic abnormality of the child , or, if the mother has not attained eighteen years of age at the time of the abortion, [deleted: the] a maternal [deleted: grandparents] grandparent of the unborn child, may bring a civil action on behalf of the unborn child to obtain appropriate relief with respect to a violation of subsection A or b of this section. The court may award reasonable attorney fees as part of the costs in an action brought pursuant to this subsection. For the purposes of this subsection, "appropriate relief" includes monetary damages for all injuries, whether psychological, physical or financial, including loss of companionship and support, resulting from the violation of subsection A or b of this section. [deleted: D.] E. A physician, physician's assistant, nurse, counselor or other medical or mental health professional who knowingly does not report known violations of this section to appropriate law enforcement authorities shall be subject to a civil fine of not more than [deleted: ten thousand dollars] $10,000 . [deleted: E.] F. A woman on whom a sex-selection or race-selection abortion or an abortion because of a child's genetic abnormality is performed is not subject to criminal prosecution or civil liability for any violation of this section or for a conspiracy to violate this section. [deleted: F.] G. For the purposes of this section : [deleted: ,] 1. "Abortion" has the same meaning prescribed in section 36-2151. 2. "Genetic abnormality": ( a ) Means the presence or presumed presence of an abnormal gene expression in an unborn child, including a chromosomal disorder or morphological malformation occurring as the result of abnormal gene expression. ( b ) Does not include a lethal fetal condition. For the purposes of this subdivision, "lethal fetal condition" has the same meaning prescribed in section 36-2158. 3. "Medical emergency" has the same meaning prescribed in section 36-2151. END_STATUTE Sec. 3. Repeal Section 13-3604 , Arizona Revised Statutes, is repealed. Sec. 4. Title 15, chapter 1, article 1, Arizona Revised Statutes, is amended by adding section 15-115.01, to read: START_STATUTE 15-115.01. Public educational institution facility; prohibition; definitions A. A facility that is run by or that operates on the property of a public educational institution may not Perform or provide an abortion, unless the abortion is necessary to save the life of the woman having the abortion. B. For the purposes of this section: 1. "Abortion" has the same meaning prescribed in section 36-2151. 2. "Medical emergency" has the same meaning prescribed in section 36-2151. 3. "Public educational institution" means any of the following: ( a ) A community college as defined in section 15-1401. ( b ) A university under the jurisdiction of the Arizona board of regents. ( c ) A school district, including its schools. ( d ) A charter school. ( e ) An accommodation school. ( f ) The Arizona state schools for the deaf and the blind. END_STATUTE Sec. 5. Section 35-196.04, Arizona Revised Statutes, is amended to read: START_STATUTE 35-196.04. Use of public monies prohibited; human cloning research involving fetal remains from abortion; other prohibited research; definition A. Notwithstanding any other law, tax monies of this state or any political subdivision of this state, federal monies passing through the state treasury or the treasury of any political subdivision of this state or any other public monies shall not be used by any person or entity, including any state funded institution or facility, for human somatic cell nuclear transfer, commonly known as human cloning. B. Notwithstanding any other law, public monies or tax monies of this state or any political subdivision of this state, any federal monies passing through the state treasury or the treasury of any political subdivision of this state or monies paid by students as part of tuition or fees to a state university or a community college shall not be expended or allocated for or granted to or on behalf of an existing or proposed research project that involves fetal remains from an abortion or human somatic cell nuclear transfer or any research that is prohibited by title 36, chapter 23. [deleted: B.] C. This section does not restrict areas of scientific research that are not specifically prohibited by this section, including research in the use of nuclear transfer or other cloning techniques to produce molecules, deoxyribonucleic acid, cells other than human embryos, tissues, organs, plants or animals other than humans. [deleted: C.] D. For the purposes of this section, "human somatic cell nuclear transfer" means human asexual reproduction that is accomplished by introducing the genetic material from one or more human somatic cells into a fertilized or unfertilized oocyte whose nuclear material has been removed or inactivated so as to produce an organism, at any stage of development, that is genetically virtually identical to an existing or previously existing human organism. END_STATUTE Sec. 6. Section 36-449.01, Arizona Revised Statutes, is amended to read: START_STATUTE 36-449.01 . Definitions In this article, unless the context otherwise requires: 1. "Abortion" means the use of any means with the intent to terminate a woman's pregnancy for reasons other than to increase the probability of a live birth, to preserve the life or health of the child after a live birth, to terminate an ectopic pregnancy or to remove a dead fetus. Abortion does not include birth control devices or oral contraceptives. 2. "Abortion clinic" means a facility, other than a hospital, in which five or more first trimester abortions in any month or any second or third trimester abortions are performed. 3. "Bodily remains" has the same meaning prescribed in section 36-2151. [deleted: 3.] 4. "Director" means the director of the department of health services. 5. "Final disposition" has the same meaning prescribed in section 36-301. [deleted: 4.] 6. "Medication abortion" means the use of any medication, drug or other substance that is intended to cause or induce an abortion. [deleted: 5.] 7. "Perform" includes the initial administration of any medication, drug or other substance intended to cause or induce an abortion. [deleted: 6.] 8. "Surgical abortion" has the same meaning prescribed in section 36-2151. [deleted: 7.] 9. "Viable fetus" has the same meaning prescribed in section 36-2301.01. END_STATUTE Sec. 7. Section 36-449.03, Arizona Revised Statutes, is amended to read: START_STATUTE 36-449.03 . Abortion clinics; rules; civil penalties A. The director shall adopt rules for an abortion clinic's physical facilities. At a minimum these rules shall prescribe standards for: 1. Adequate private space that is specifically designated for interviewing, counseling and medical evaluations. 2. Dressing rooms for staff and patients. 3. Appropriate lavatory areas. 4. Areas for preprocedure hand washing. 5. Private procedure rooms. 6. Adequate lighting and ventilation for abortion procedures. 7. Surgical or gynecologic examination tables and other fixed equipment. 8. Postprocedure recovery rooms that are supervised, staffed and equipped to meet the patients' needs. 9. Emergency exits to accommodate a stretcher or gurney. 10. Areas for cleaning and sterilizing instruments. 11. Adequate areas [deleted: for the secure storage of] to securely store medical records and necessary equipment and supplies. 12. The display in the abortion clinic, in a place that is conspicuous to all patients, of the clinic's current license issued by the department. B. The director shall adopt rules to prescribe abortion clinic supplies and equipment standards, including supplies and equipment that are required to be immediately available for use or in an emergency. At a minimum these rules shall: 1. Prescribe required equipment and supplies, including medications, required [deleted: for the] to conduct, in an appropriate fashion, [deleted: of] any abortion procedure that the medical staff of the clinic anticipates performing and [deleted: for monitoring] to monitor the progress of each patient throughout the procedure and recovery period. 2. Require that the number or amount of equipment and supplies at the clinic is adequate at all times to [deleted: assure] ensure sufficient quantities of clean and sterilized durable equipment and supplies to meet the needs of each patient. 3. Prescribe required equipment, supplies and medications that shall be available and ready for immediate use in an emergency and requirements for written protocols and procedures to be followed by staff in an emergency, such as the loss of electrical power. 4. Prescribe required equipment and supplies for required laboratory tests and requirements for protocols to calibrate and maintain laboratory equipment at the abortion clinic or operated by clinic staff. 5. Require ultrasound equipment. 6. Require that all equipment is safe for the patient and the staff, meets applicable federal standards and is checked annually to ensure safety and appropriate calibration. C. The director shall adopt rules relating to abortion clinic personnel. At a minimum these rules shall require that: 1. The abortion clinic designate a medical director of the abortion clinic who is licensed pursuant to title 32, chapter 13, 17 or 29. 2. Physicians performing abortions are licensed pursuant to title 32, chapter 13 or 17, demonstrate competence in the procedure involved and are acceptable to the medical director of the abortion clinic. 3. A physician is available: (a) For a surgical abortion who has admitting privileges at a health care institution that is classified by the director as a hospital pursuant to section 36-405, subsection B and that is within thirty miles of the abortion clinic. (b) For a medication abortion who has admitting privileges at a health care institution that is classified by the director as a hospital pursuant to section 36-405, subsection B. 4. If a physician is not present, a registered nurse, nurse practitioner, licensed practical nurse or physician assistant is present and remains at the clinic when abortions are performed to provide postoperative monitoring and care, or monitoring and care after inducing a medication abortion, until each patient who had an abortion that day is discharged. 5. Surgical assistants receive training in counseling, patient advocacy and the specific responsibilities of the services the surgical assistants provide. 6. Volunteers receive training in the specific responsibilities of the services the volunteers provide, including counseling and patient advocacy as provided in the rules adopted by the director for different types of volunteers based on their responsibilities. D. The director shall adopt rules relating to the medical screening and evaluation of each abortion clinic patient. At a minimum these rules shall require: 1. A medical history, including the following: (a) Reported allergies to medications, antiseptic solutions or latex. (b) Obstetric and gynecologic history. (c) Past surgeries. 2. A physical examination, including a bimanual examination estimating uterine size and palpation of the adnexa. 3. The appropriate laboratory tests, including: (a) Urine or blood tests for pregnancy performed before the abortion procedure. (b) A test for anemia. (c) Rh typing, unless reliable written documentation of blood type is available. (d) Other tests as indicated from the physical examination. 4. An ultrasound evaluation for all patients. The rules shall require that if a person who is not a physician performs an ultrasound examination, that person shall have documented evidence that the person completed a course in [deleted: the operation of] operating ultrasound equipment as prescribed in rule. The physician or other health care professional shall review, at the request of the patient, the ultrasound evaluation results with the patient before the abortion procedure is performed, including the probable gestational age of the fetus. 5. That the physician is responsible for estimating the gestational age of the fetus based on the ultrasound examination and obstetric standards in keeping with established standards of care regarding the estimation of fetal age as defined in rule and shall write the estimate in the patient's medical history. The physician shall keep original prints of each ultrasound examination of a patient in the patient's medical history file. E. The director shall adopt rules relating to the abortion procedure. At a minimum these rules shall require: 1. That medical personnel is available to all patients throughout the abortion procedure. 2. Standards for the safe conduct of abortion procedures that conform to obstetric standards in keeping with established standards of care regarding the estimation of fetal age as defined in rule. 3. Appropriate use of local anesthesia, analgesia and sedation if ordered by the physician. 4. The use of appropriate precautions, such as [deleted: the establishment of] establishing intravenous access at least for patients undergoing second or third trimester abortions. 5. The use of appropriate monitoring of the vital signs and other defined signs and markers of the patient's status throughout the abortion procedure and during the recovery period until the patient's condition is deemed to be stable in the recovery room. 6. For abortion clinics performing or inducing an abortion for a woman whose unborn child is the gestational age of twenty weeks or more, minimum equipment standards to assist the physician in complying with section 36-2301. For the purposes of this paragraph, "abortion" and "gestational age" have the same meanings prescribed in section 36-2151. F. The director shall adopt rules relating to the final disposition of bodily remains. At a minimum these rules shall require that: 1. The final disposition of bodily remains from a surgical abortion be by cremation or interment. 2. For a surgical abortion, the woman on whom the abortion is performed has the right to determine the method and location for final disposition of bodily remains. [deleted: F.] G. The director shall adopt rules that prescribe minimum recovery room standards. At a minimum these rules shall require that: 1. For a surgical abortion, immediate postprocedure care, or care provided after inducing a medication abortion, consists of observation in a supervised recovery room for as long as the patient's condition warrants. 2. The clinic arrange hospitalization if any complication beyond the management capability of the staff occurs or is suspected. 3. A licensed health professional who is trained in [deleted: the management of] managing the recovery area and who is capable of providing basic cardiopulmonary resuscitation and related emergency procedures remains on the premises of the abortion clinic until all patients are discharged. 4. For a surgical abortion, a physician with admitting privileges at a health care institution that is classified by the director as a hospital pursuant to section 36-405, subsection B and that is within thirty miles of the abortion clinic remains on the premises of the abortion clinic until all patients are stable and are ready to leave the recovery room and to facilitate the transfer of emergency cases if hospitalization of the patient or viable fetus is necessary. A physician shall sign the discharge order and be readily accessible and available until the last patient is discharged. 5. A physician discusses RhO(d) immune globulin with each patient for whom it is indicated and [deleted: assures] ensures that it is offered to the patient in the immediate postoperative period or that it will be available to her within seventy-two hours after completion of the abortion procedure. If the patient refuses, a refusal form approved by the department shall be signed by the patient and a witness and included in the medical record. 6. Written instructions with regard to postabortion coitus, signs of possible problems and general aftercare are given to each patient. Each patient shall have specific instructions regarding access to medical care for complications, including a telephone number to call for medical emergencies. 7. There is a specified minimum length of time that a patient remains in the recovery room by type of abortion procedure and duration of gestation. 8. The physician [deleted: assures] ensures that a licensed health professional from the abortion clinic makes a good faith effort to contact the patient by telephone, with the patient's consent, within twenty-four hours after a surgical abortion to assess the patient's recovery. 9. Equipment and services are located in the recovery room to provide appropriate emergency resuscitative and life support procedures pending the transfer of the patient or viable fetus to the hospital. [deleted: G.] H. The director shall adopt rules that prescribe standards for follow-up visits. At a minimum these rules shall require that: 1. For a surgical abortion, a postabortion medical visit is offered and, if requested, scheduled for three weeks after the abortion, including a medical examination and a review of the results of all laboratory tests. For a medication abortion, the rules shall require that a postabortion medical visit is scheduled between one week and three weeks after the initial dose for a medication abortion to confirm the pregnancy is completely terminated and to assess the degree of bleeding. 2. A urine pregnancy test is obtained at the time of the follow-up visit to rule out continuing pregnancy. If a continuing pregnancy is suspected, the patient shall be evaluated and a physician who performs abortions shall be consulted. [deleted: H.] I. The director shall adopt rules to prescribe minimum abortion clinic incident reporting. At a minimum these rules shall require that: 1. The abortion clinic records each incident resulting in a patient's or viable fetus' serious injury occurring at an abortion clinic and shall report them in writing to the department within ten days after the incident. For the purposes of this paragraph, "serious injury" means an injury that occurs at an abortion clinic and that creates a serious risk of substantial impairment of a major body organ and includes any injury or condition that requires ambulance transportation of the patient. 2. If a patient's death occurs, other than a fetal death properly reported pursuant to law, the abortion clinic reports it to the department not later than the next department work day. 3. Incident reports are filed with the department and appropriate professional regulatory boards. [deleted: I.] J. The director shall adopt rules relating to enforcement of this article. At a minimum, these rules shall require that: 1. For an abortion clinic that is not in substantial compliance with this article and the rules adopted pursuant to this article and section 36-2301 or that is in substantial compliance but refuses to carry out a plan of correction acceptable to the department of any deficiencies that are listed on the department's statement of deficiency, the department may do any of the following: (a) Assess a civil penalty pursuant to section 36-431.01. (b) Impose an intermediate sanction pursuant to section 36-427. (c) Suspend or revoke a license pursuant to section 36-427. (d) Deny a license. (e) Bring an action for an injunction pursuant to section 36-430. 2. In determining the appropriate enforcement action, the department consider the threat to the health, safety and welfare of the abortion clinic's patients or the general public, including: (a) Whether the abortion clinic has repeated violations of statutes or rules. (b) Whether the abortion clinic has engaged in a pattern of noncompliance. (c) The type, severity and number of violations. [deleted: J.] K. The department shall not release personally identifiable patient or physician information. [deleted: K.] L. The rules adopted by the director pursuant to this section do not limit the ability of a physician or other health professional to advise a patient on any health issue. END_STATUTE Sec. 8. Section 36-2151, Arizona Revised Statutes, is amended to read: START_STATUTE 36-2151. Definitions In this article, unless the context otherwise requires: 1. "Abortion" means the use of any means to terminate the clinically diagnosable pregnancy of a woman with knowledge that the termination by those means will cause, with reasonable likelihood, the death of the unborn child. Abortion does not include birth control devices, oral contraceptives used to inhibit or prevent ovulation, conception or the implantation of a fertilized ovum in the uterus or the use of any means to save the life or preserve the health of the unborn child, to preserve the life or health of the child after a live birth, to terminate an ectopic pregnancy or to remove a dead fetus. 2. "Auscultation" means the act of listening for sounds made by internal organs of the unborn child, specifically for a heartbeat, using an ultrasound transducer and fetal heart rate monitor. 3. "Bodily remains" means the physical remains, corpse or body parts of an unborn child who has been expelled or extracted from his or her mother through abortion. [deleted: 3.] 4. "Conception" means the fusion of a human spermatozoon with a human ovum. 5. "Final disposition" has the same meaning prescribed in section 36-301. 6. "Genetic abnormality" has the same meaning prescribed in section 13-3603.02. [deleted: 4.] 7. "Gestational age" means the age of the unborn child as calculated from the first day of the last menstrual period of the pregnant woman. [deleted: 5.] 8. "Health professional" has the same meaning prescribed in section 32-3201. [deleted: 6.] 9. "Medical emergency" means a condition that, on the basis of the physician's good faith clinical judgment, so complicates the medical condition of a pregnant woman as to necessitate the immediate abortion of her pregnancy to avert her death or for which a delay will create serious risk of substantial and irreversible impairment of a major bodily function. [deleted: 7.] 10. "Medication abortion" means the use of any medication, drug or other substance that is intended to cause or induce an abortion. [deleted: 8.] 11. "Physician" means a person who is licensed pursuant to title 32, chapter 13 or 17. [deleted: 9.] 12. "Pregnant" or "pregnancy" means a female reproductive condition of having a developing unborn child in the body and that begins with conception. [deleted: 10.] 13. "Probable gestational age" means the gestational age of the unborn child at the time the abortion is planned to be performed and as determined with reasonable probability by the attending physician. [deleted: 11.] 14. "Surgical abortion" means the use of a surgical instrument or a machine to terminate the clinically diagnosable pregnancy of a woman with knowledge that the termination by those means will cause, with reasonable likelihood, the death of the unborn child. Surgical abortion does not include the use of any means to increase the probability of a live birth, to preserve the life or health of the child after a live birth, to terminate an ectopic pregnancy or to remove a dead fetus. Surgical abortion does not include patient care incidental to the procedure. [deleted: 12.] 15. "Ultrasound" means the use of ultrasonic waves for diagnostic or therapeutic purposes to monitor a developing unborn child. [deleted: 13.] 16. "Unborn child" means the offspring of human beings from conception until birth. END_STATUTE Sec. 9. Section 36-2153, Arizona Revised Statutes, is amended to read: START_STATUTE 36-2153. Informed consent; requirements; information; website; signage; violation; civil relief; statute of limitations A. An abortion shall not be performed or induced without the voluntary and informed consent of the woman on whom the abortion is to be performed or induced. Except in the case of a medical emergency and in addition to the other requirements of this chapter, consent to an abortion is voluntary and informed only if all of the following are true: 1. At least twenty-four hours before the abortion, the physician who is to perform the abortion or the referring physician has informed the woman, orally and in person, of: (a) The name of the physician who will perform the abortion. (b) The nature of the proposed procedure or treatment. (c) The immediate and long-term medical risks associated with the procedure that a reasonable patient would consider material to the decision of whether or not to undergo the abortion. (d) Alternatives to the procedure or treatment that a reasonable patient would consider material to the decision of whether or not to undergo the abortion. (e) The probable gestational age of the unborn child at the time the abortion is to be performed. (f) The probable anatomical and physiological characteristics of the unborn child at the time the abortion is to be performed. (g) The medical risks associated with carrying the child to term. 2. At least twenty-four hours before the abortion, the physician who is to perform the abortion, the referring physician or a qualified physician, physician assistant, nurse, psychologist or licensed behavioral health professional to whom the responsibility has been delegated by either physician has informed the woman, orally and in person, that: (a) Medical assistance benefits may be available for prenatal care, childbirth and neonatal care. (b) The father of the unborn child is liable to assist in the support of the child, even if he has offered to pay for the abortion. In the case of rape or incest, this information may be omitted. (c) Public and private agencies and services are available to assist the woman during her pregnancy and after the birth of her child if she chooses not to have an abortion, whether she chooses to keep the child or place the child for adoption. (d) It is unlawful for any person to coerce a woman to undergo an abortion. (e) The woman is free to withhold or withdraw her consent to the abortion at any time without affecting her right to future care or treatment and without the loss of any state or federally funded benefits to which she might otherwise be entitled. (f) The department of health services maintains a website that describes the unborn child and lists the agencies that offer alternatives to abortion. (g) The woman has [deleted: a] the right to review the website and that a printed copy of the materials on the website will be provided to her free of charge if she chooses to review these materials. ( h ) In the case of a surgical abortion, the woman has the right to determine final disposition of bodily remains and to be informed of the available options for locations and methods for disposition of bodily remains. 3. The information in paragraphs 1 and 2 of this subsection is provided to the woman individually and in a private room to protect her privacy and to ensure that the information focuses on her individual circumstances and that she has adequate opportunity to ask questions. 4. The woman certifies in writing before the abortion that the information required to be provided pursuant to paragraphs 1 and 2 of this subsection has been provided. 5. In the case of a surgical abortion, if the woman desires to exercise her right to determine final disposition of bodily remains, the woman indicates in writing her choice for the location and method of final disposition of bodily remains. B. If a woman has taken mifepristone as part of a two-drug regimen to terminate her pregnancy, has not yet taken the second drug and consults an abortion clinic questioning her decision to terminate her pregnancy or seeking information regarding the health of her fetus or the efficacy of mifepristone alone to terminate a pregnancy, the abortion clinic staff shall inform the woman that the use of mifepristone alone to end a pregnancy is not always effective and that she should immediately consult a physician if she would like more information. C. If a medical emergency compels the performance of an abortion, the physician shall inform the woman, before the abortion if possible, of the medical indications supporting the physician's judgment that an abortion is necessary to avert the woman's death or to avert substantial and irreversible impairment of a major bodily function. D. The department of health services shall establish and shall annually update a website that includes a link to a printable version of all materials listed on the website. The materials must be written in an easily understood manner and printed in a typeface that is large enough to be clearly legible. The website must include all of the following materials: 1. Information that is organized geographically by location and that is designed to inform the woman about public and private agencies and services that are available to assist a woman through pregnancy, at childbirth and while her child is dependent, including adoption agencies. The materials shall include a comprehensive list of the agencies, a description of the services they offer and the manner in which these agencies may be contacted, including the agencies' telephone numbers and website addresses. 2. Information on the availability of medical assistance benefits for prenatal care, childbirth and neonatal care. 3. A statement that it is unlawful for any person to coerce a woman to undergo an abortion. 4. A statement that any physician who performs an abortion on a woman without obtaining the woman's voluntary and informed consent or without affording her a private medical consultation may be liable to the woman for damages in a civil action. 5. A statement that the father of a child is liable to assist in the support of that child, even if the father has offered to pay for an abortion, and that the law allows adoptive parents to pay costs of prenatal care, childbirth and neonatal care. 6. Information that is designed to inform the woman of the probable anatomical and physiological characteristics of the unborn child at two-week gestational increments from fertilization to full term, including pictures or drawings representing the development of unborn children at two-week gestational increments and any relevant information on the possibility of the unborn child's survival. The pictures or drawings must contain the dimensions of the unborn child and must be realistic and appropriate for each stage of pregnancy. The information provided pursuant to this paragraph must be objective, nonjudgmental and designed to convey only accurate scientific information about the unborn child at the various gestational ages. 7. Objective information that describes the methods of abortion procedures commonly employed, the medical risks commonly associated with each procedure, the possible detrimental psychological effects of abortion and the medical risks commonly associated with carrying a child to term. 8. Information explaining the efficacy of mifepristone taken alone, without a follow-up drug as part of a two-drug regimen, to terminate a pregnancy and advising a woman to immediately contact a physician if the woman has taken only mifepristone and questions her decision to terminate her pregnancy or seeks information regarding the health of her fetus. E. An individual who is not a physician shall not perform a surgical abortion. F. A person shall not write or communicate a prescription for a drug or drugs to induce an abortion or require or obtain payment for a service provided to a patient who has inquired about an abortion or scheduled an abortion until the [deleted: expiration of the] twenty-four-hour reflection period required by subsection A of this section expires . G. A person shall not intimidate or coerce in any way any person to obtain an abortion. A parent, a guardian or any other person shall not coerce a minor to obtain an abortion. If a minor is denied financial support by the minor's parents, guardians or custodian due to the minor's refusal to have an abortion performed, the minor is deemed emancipated for the purposes of eligibility for public assistance benefits, except that the emancipated minor may not use these benefits to obtain an abortion. H. An abortion clinic as defined in section 36-449.01 shall conspicuously post signs that are visible to all who enter the abortion clinic, that are clearly readable and that state it is unlawful for any person to force a woman to have an abortion and a woman who is being forced to have an abortion has the right to contact any local or state law enforcement or social service agency to receive protection from any actual or threatened physical, emotional or psychological abuse. The signs shall be posted in the waiting room, consultation rooms and procedure rooms. I. A person shall not require a woman to obtain an abortion as a provision in a contract or as a condition of employment. J. A physician who knowingly violates this section commits an act of unprofessional conduct and is subject to license suspension or revocation pursuant to title 32, chapter 13 or 17. K. In addition to other remedies available under the common or statutory law of this state, any of the following may file a civil action to obtain appropriate relief for a violation of this section: 1. A woman on whom an abortion has been performed without her informed consent as required by this section. 2. The father of the unborn child if the father was married to the mother at the time she received the abortion, unless the pregnancy resulted from the plaintiff's criminal conduct. 3. [deleted: The] A maternal [deleted: grandparents] grandparent of the unborn child if the mother was not at least eighteen years of age at the time of the abortion, unless the pregnancy resulted from the plaintiff's criminal conduct. L. A civil action filed pursuant to subsection K of this section shall be brought in the superior court in the county in which the woman on whom the abortion was performed resides and may be based on a claim that failure to obtain informed consent was a result of simple negligence, gross negligence, wantonness, wilfulness, intention or any other legal standard of care. Relief pursuant to subsection K of this section includes the following: 1. Money damages for all psychological, emotional and physical injuries resulting from the violation of this section. 2. Statutory damages in an amount equal to [deleted: five thousand dollars] $5,000 or three times the cost of the abortion, whichever is greater. 3. Reasonable attorney fees and costs. M. A civil action brought pursuant to this section must be initiated within six years after the violation occurred. END_STATUTE Sec. 10. Section 36-2157, Arizona Revised Statutes, is amended to read: START_STATUTE 36-2157. Affidavit A person shall not knowingly perform or induce an abortion before that person completes an affidavit that: 1. States that the person making the affidavit is not aborting the child because of the child's sex or race or because of a genetic abnormality of the child and has no knowledge that the child to be aborted is being aborted because of the child's sex or race or because of a genetic abnormality of the child . 2. Is signed by the person performing or inducing the abortion. END_STATUTE Sec. 11. Section 36-2158, Arizona Revised Statutes, is amended to read: START_STATUTE 36-2158. Informed consent; fetal condition; website; unprofessional conduct; civil relief; statute of limitations; definitions A. A person shall not perform or induce an abortion without first obtaining the voluntary and informed consent of the woman on whom the abortion is to be performed or induced. Except in the case of a medical emergency and in addition to the other requirements of this chapter, consent to an abortion is voluntary and informed only if all of the following occur: 1. In the case of a woman seeking an abortion of her unborn child diagnosed with a lethal fetal condition, at least twenty-four hours before the abortion the physician who is to perform the abortion or the referring physician has informed the woman, orally and in person, that: (a) Perinatal hospice services are available and the physician has offered this care as an alternative to abortion. (b) The department of health services maintains a website that lists perinatal hospice programs that are available both in this state and nationally and that are organized geographically by location. (c) The woman has a right to review the website and that a printed copy of the materials on the website will be provided to her free of charge if she chooses to review these materials. 2. In the case of a woman seeking an abortion of her unborn child diagnosed with a nonlethal fetal condition, at least twenty-four hours before the abortion the physician who is to perform the abortion or the referring physician has informed the woman, orally and in person: (a) Of up-to-date, evidence-based information concerning the range of outcomes for individuals living with the diagnosed condition, including physical, developmental, educational and psychosocial outcomes. (b) That the department of health services maintains a website that lists information regarding support services, hotlines, resource centers or clearinghouses, national and local peer support groups and other education and support programs available to assist the woman and her unborn child, any national or local registries of families willing to adopt newborns with the nonlethal fetal condition and contact information for adoption agencies willing to place newborns with the nonlethal fetal condition with families willing to adopt. (c) That the woman has a right to review the website and that a printed copy of the materials on the website will be provided to her free of charge if she chooses to review these materials. ( d ) That section 13-3603.02 prohibits abortion because of the unborn child's sex or race or because of a genetic abnormality. 3. The woman certifies in writing before the abortion that the information required to be provided pursuant to this subsection has been provided. B. The department of health services shall establish [deleted: a website within ninety days after the effective date of this section] and [deleted: shall] annually update [deleted: the] a website[deleted: . The website shall include] that includes the information prescribed in subsection A, paragraph 1, subdivision (b) and paragraph 2, subdivision (b) of this section. C. A physician who knowingly violates this section commits an act of unprofessional conduct and is subject to license suspension or revocation pursuant to title 32, chapter 13 or 17. D. In addition to other remedies available under the common or statutory law of this state, any of the following individuals may file a civil action to obtain appropriate relief for a violation of this section: 1. A woman on whom an abortion has been performed without her informed consent as required by this section. 2. The father of the unborn child if the father [deleted: is] was married to the mother at the time she received the abortion, unless the pregnancy resulted from the father's criminal conduct. 3. [deleted: The] A maternal [deleted: grandparents] grandparent of the unborn child if the mother was not at least eighteen years of age at the time of the abortion, unless the pregnancy resulted from [deleted: either of] the maternal grandparent's criminal conduct. E. A civil action filed pursuant to subsection D of this section shall be brought in the superior court in the county in which the woman on whom the abortion was performed resides and may be based on a claim that failure to obtain informed consent was a result of simple negligence, gross negligence, wantonness, wilfulness, intention or any other legal standard of care. Relief pursuant to this subsection includes the following: 1. Money damages for all psychological, emotional and physical injuries resulting from the violation of this section. 2. Statutory damages in an amount equal to [deleted: five thousand dollars] $5,000 or three times the cost of the abortion, whichever is greater. 3. Reasonable attorney fees and costs. F. A civil action brought pursuant to this section must be initiated within six years after the violation occurred. G. For the purposes of this section: 1. "Lethal fetal condition" means a fetal condition that is diagnosed before birth and that will result, with reasonable certainty, in the death of the unborn child within three months after birth. 2. "Nonlethal fetal condition" means a fetal condition that is diagnosed before birth and that will not result in the death of the unborn child within three months after birth but may result in physical or mental disability or abnormality. 3. "Perinatal hospice" means comprehensive support to the pregnant woman and her family that includes supportive care from the time of diagnosis through the time of birth and death of the infant and through the postpartum period. Supportive care may include counseling and medical care by maternal-fetal medical specialists, obstetricians, neonatologists, anesthesia specialists, clergy, social workers and specialty nurses who are focused on alleviating fear and ensuring that the woman and her family experience the life and death of the child in a comfortable and supportive environment. END_STATUTE Sec. 12. Title 36, chapter 20, article 1, Arizona Revised Statutes, is amended by adding section 36-2160, to read: START_STATUTE 36-2160. Abortion-inducing drugs; definition A. An abortion-inducing drug may be provided only by a qualified physician in accordance with the requirements of this chapter. B. A manufacturer, supplier or physician or any other person is prohibited from providing an abortion-inducing drug via courier, delivery or mail service. C. This section does not apply to drugs that may be known to cause an abortion but that are prescribed for other medical indications. D. For the purposes of this section, "abortion-inducing drug" means a medicine or drug or any other substance used for a medication abortion. END_STATUTE Sec. 13. Section 36-2161, Arizona Revised Statutes, is amended to read: START_STATUTE 36-2161 . Abortions; reporting requirements A. A hospital or facility in this state where abortions are performed must submit to the department of health services on a form prescribed by the department a report of each abortion performed in the hospital or facility. The report shall not identify the individual patient by name or include any other information or identifier that would make it possible to identify, in any manner or under any circumstances, a woman who has obtained or sought to obtain an abortion. The report must include the following information: 1. The name and address of the facility where the abortion was performed. 2. The type of facility where the abortion was performed. 3. The county where the abortion was performed. 4. The woman's age. 5. The woman's educational background by highest grade completed and, if applicable, level of college completed. 6. The county and state in which the woman resides. 7. The woman's race and ethnicity. 8. The woman's marital status. 9. The number of prior pregnancies and prior abortions of the woman. 10. The number of previous spontaneous terminations of pregnancy of the woman. 11. The gestational age of the unborn child at the time of the abortion. 12. The reason for the abortion, including at least one of the following: (a) The abortion is elective. (b) The abortion is due to maternal health considerations, including one of the following: (i) A premature rupture of membranes. (ii) An anatomical abnormality. (iii) Chorioamnionitis. (iv) Preeclampsia. (v) Other. (c) The abortion is due to fetal health considerations, including the fetus being diagnosed with at least one of the following: (i) A lethal anomaly. (ii) A central nervous system anomaly. [deleted: (iii) Trisomy 18. (iv) Trisomy 21. (v) Triploidy. (vi)] ( iii ) Other. (d) The pregnancy is the result of a sexual assault. (e) The pregnancy is the result of incest. (f) The woman is being coerced into obtaining an abortion. (g) The woman is a victim of sex trafficking. (h) The woman is a victim of domestic violence. (i) Other. (j) The woman declined to answer. 13. The type of procedure performed or prescribed and the date of the abortion. 14. Any preexisting medical conditions of the woman that would complicate pregnancy. 15. Any known medical complication that resulted from the abortion, including at least one of the following: (a) Shock. (b) Uterine perforation. (c) Cervical laceration requiring suture or repair. (d) Heavy bleeding or hemorrhage with estimated blood loss of at least five hundred cubic centimeters. (e) Aspiration or allergic response. (f) Postprocedure infection. (g) Sepsis. (h) Incomplete abortion retaining part of the fetus requiring reevacuation. (i) Damage to the uterus. (j) Failed termination of pregnancy. (k) Death of the patient. (l) Other. (m) None. 16. The basis for any medical judgment that a medical emergency existed that excused the physician from compliance with the requirements of this chapter. 17. The physician's statement if required pursuant to section 36-2301.01. 18. If applicable, the weight of the aborted fetus for any abortion performed pursuant to section 36-2301.01. 19. Whether a fetus or embryo was delivered alive as defined in section 36-2301 during or immediately after an attempted abortion and the efforts made to promote, preserve and maintain the life of the fetus or embryo pursuant to section 36-2301. 20. Statements by the physician and all clinical staff who observed the fetus or embryo during or immediately after the abortion certifying under penalty of perjury that, to the best of their knowledge, the aborted fetus or embryo was not delivered alive as defined in section 36-2301. 21. The medical specialty of the physician performing the abortion, including one of the following: (a) Obstetrics-gynecology. (b) General or family practice. (c) Emergency medicine. (d) Other. 22. The type of admission for the patient, including whether the abortion was performed: (a) As an outpatient procedure in an abortion clinic. (b) As an outpatient procedure at a hospital. (c) As an inpatient procedure at a hospital. (d) As an outpatient procedure at a health care institution other than an abortion clinic or hospital. 23. Whether anesthesia was administered to the mother. 24. Whether anesthesia was administered to the unborn child. 25. Whether any genetic abnormality of the unborn child was detected at or before the time of the abortion by genetic testing, such as maternal serum tests, or by ultrasound, such as nuchal translucency screening, or by other forms of testing. 26. If a surgical abortion was performed, the method of final disposition of bodily remains and whether the woman exercised her right to choose the final disposition of bodily remains. B. The hospital or facility shall request the information specified in subsection A, paragraph 12 of this section at the same time the information pursuant to section 36-2153 is provided to the woman individually and in a private room to protect the woman's privacy. The information requested pursuant to subsection A, paragraph 12 of this section may be obtained on a medical form provided to the woman to complete if the woman completes the form individually and in a private room. C. If the woman who is seeking the abortion discloses that the abortion is being sought because of a reason described in subsection A, paragraph 12, subdivision (d), (e), (f), (g) or (h) of this section, the hospital or facility shall provide the woman with information regarding the woman's right to report a crime to law enforcement and resources available for assistance and services, including a national human trafficking resource hotline. D. The report must be signed by the physician who performed the abortion or, if a health professional other than a physician is authorized by law to prescribe or administer abortion medication, the signature and title of the person who prescribed or administered the abortion medication. The form may be signed electronically and shall indicate that the person who signs the report is attesting that the information in the report is correct to the best of the person's knowledge. The hospital or facility must transmit the report to the department within fifteen days after the last day of each reporting month. E. Any report filed pursuant to this section shall be filed electronically at an internet website that is designated by the department unless the person required to file the report applies for a waiver from electronic reporting by submitting a written request to the department. END_STATUTE Sec. 14. Exemption from rulemaking For the purposes of this act, the department of health services is exempt from the rulemaking requirements of title 41, chapter 6, Arizona Revised Statutes, for one year after the effective date of this act. Sec. 15. Legislative findings and intent The Legislature finds that prohibiting persons from performing abortions knowing that the abortion is sought because of a genetic abnormality of the child advances at least three compelling state interests. First, this act protects the disability community from discriminatory abortions, including for example Down-syndrome-selective abortions. The Legislature finds that in the United States and abroad fetuses with Down syndrome are disproportionately targeted for abortions, with between 61 percent and 91 percent choosing abortion when it is discovered on a prenatal test. See Box v. Planned Parenthood of Indiana and Kentucky, Inc. , 139 S. Ct. 1780, 1790-91 (2019) (Thomas, J., concurring). The Legislature intends to send an unambiguous message that children with genetic abnormalities, whether born or unborn, are equal in dignity and value to their peers without genetic abnormalities, born or unborn. Second, this act protects against coercive health care practices that encourage selective abortions of persons with genetic abnormalities. The Sixth Circuit Court of Appeals recently found that empirical reports from parents of children with Down syndrome attest that their doctors explicitly encouraged abortion or emphasized the challenges of raising children with Down syndrome, and there is medical literature to that effect. See Preterm-Cleveland v. McCloud , No. 18-3329, __ F.3d __, 2021 WL 1377279, at *2 (6th Cir. Apr. 13, 2021) (citing David A. Savitz, How Far Can Prenatal Screening Go in Preventing Birth Defects , 152 J. of Pediatrics 3, 3 (2008) (arguing that "selective pregnancy terminations and reduced birth prevalence [of Down syndrome is] a desirable and attainable goal")). Third, this act protects the integrity and ethics of the medical profession by preventing doctors from becoming witting participants in genetic-abnormality-selective abortions. The Legislature finds that an industry that is associated with the view that some lives or potential lives are worth more than others is less likely to earn or retain the public's trust. All three of these purposes are also present for the similar prohibition in Arizona law on performing abortions knowing that the abortion is sought based on the sex or race of the child or the race of a parent of that child. The Legislature incorporates into its findings the statistics recently provided by this state and other states to the Supreme Court of the United States. See Brief of the States of Wisconsin et al. at pages 17-25, Box v. Planned Parenthood of Indiana and Kentucky Inc. , No. 18-483, 2018 WL 6042853, available at https://www.supremecourt.gov/DocketPDF/18/18-483/72184/20181115122354603_18-483%20Brief%20of%20States%20of%20Wisconsin%20et%20al%20Supporting %20Petitioners.pdf. Sec. 16. Intervention The Legislature, by concurrent resolution, may appoint one or more of its members who sponsored or cosponsored this act in the member's official capacity to intervene as a matter of right in any case in which the constitutionality of this act is challenged. Sec. 17. Construction This act does not create or recognize a right to an abortion and does not make lawful an abortion that is currently unlawful. Sec. 18. Severability If a provision of this act or its application to any person or circumstance is held invalid, the invalidity does not affect other provisions or applications of this act that can be given effect without the invalid provision or application, and to this end the provisions of this act are severable. APPROVED BY THE GOVERNOR APRIL 27, 2021. FILED IN THE OFFICE OF THE SECRETARY OF STATE APRIL 27, 2021.

---
snapshot_id: cd73a205-cc4e-51c2-b513-80cc050cda4e
source_kind: public-record
url: https://apps.azleg.gov/BillStatus/BillOverview?SessionID=123&BillNumber=SB1457#house-final

House Final Reading - SB1457 abortion; unborn child; genetic abnormality Action Date Action Vote 04/22/2021 Passed 31-29-0-0-0 ANDRADE N BARTON Y BIASIUCCI Y BLACKMAN Y BLACKWATER-NYGREN N BOLDING N BOLICK Y BURGES Y BUTLER N CANO N CARROLL Y CHAPLIK Y CHÁVEZ N COBB Y COOK Y DALESSANDRO N DEGRAZIA N DUNN Y EPSTEIN N ESPINOZA N FERNANDEZ N FILLMORE Y FINCHEM Y FRIESE N GRANTHAM Y GRIFFIN Y HERNANDEZ A N HERNANDEZ D N HERNANDEZ M N HOFFMAN Y JERMAINE N JOHN Y KAISER Y KAVANAGH Y LIEBERMAN N LONGDON N MEZA N NGUYEN Y NUTT Y OSBORNE Y PARKER Y PAWLIK N PAYNE Y PINGERELLI Y POWERS HANNLEY N PRATT Y ROBERTS Y RODRIGUEZ N SALMAN N SCHWIEBERT N SHAH N SIERRA N STAHL HAMILTON N TERÁN N TOMA Y TSOSIE N UDALL Y WENINGER Y WILMETH Y BOWERS Y [Vote detail dialog for SB1457 (2021) House Final Reading, saved by browser from apps.azleg.gov BillStatus on 2026-09-28.]