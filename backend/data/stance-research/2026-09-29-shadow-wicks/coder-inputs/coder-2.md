You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-29-shadow-wicks/labels/coder-2.json. Write JSON only, matching
codebook Part E, with "codebook_version": "0.4" and "coder_slot": 2. One row per
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

politician_id: 5821d0a9-672e-44c0-bac7-1a802a2e8368  office_id: 7b3dcdad-b119-4b25-8240-460f70244f9d
Buffy Wicks — Assembly Member, California (seated, level: state)
Current term: 2022-12-05 (precision: day) to present
Earlier terms in this legislature: State Representative 2018-12-03 (precision: day) to 2022-12-05

## Topics (served ladder text — code against these words only)

### topic_key: rent-regulation
topic_id: c308e8e8-caac-44f5-ab04-dbfecf40bbe2  served_revision_id: 6fa44a68-8006-48e9-b562-6b5e61d58693
Question: What role should government play in regulating rents and protecting tenants?
  1. Expand rent control to cover all rental units communitywide
  2. Strengthen existing rent stabilization and extend coverage to more units
  3. Maintain current tenant protections while allowing market rents for new construction
  4. Limit rent regulations to subsidized units; allow market rents broadly
  5. Oppose rent control entirely; rents should be set by the market without government intervention

#### Annex

(no annex for this topic yet — apply the codebook alone)

## Sources

---
snapshot_id: 843f5f64-d525-5361-8821-91f18379a595
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=201920200AB1482

BILL VOTES AB-1482 Tenant Protection Act of 2019: tenancy: rent caps.(2019-2020) Bill Votes Date 09/11/19 Result (PASS) Location Assembly Floor Ayes Count 48 Noes Count 26 NVR Count 5 Motion AB 1482 Chiu Concurrence in Senate Amendments Ayes Aguiar-Curry, Bauer-Kahan, Berman, Bloom, Boerner Horvath, Bonta, Burke, Calderon, Carrillo, Cervantes, Chau, Chiu, Chu, Cooley, Eggman, Friedman, Gabriel, Cristina Garcia, Eduardo Garcia, Gipson, Gloria, Gonzalez, Grayson, Holden, Jones-Sawyer, Kalra, Kamlager-Dove, Levine, Limón, Low, McCarty, Medina, Mullin, Muratsuchi, Nazarian, Quirk, Quirk-Silva, Reyes, Luz Rivas, Robert Rivas, Rodriguez, Santiago, Mark Stone, Ting, Weber, Wicks, Wood, Rendon Noes Bigelow, Brough, Chen, Choi, Cunningham, Daly, Diep, Flora, Frazier, Gallagher, Gray, Irwin, Kiley, Lackey, Mathis, Mayes, Melendez, Obernolte, Patterson, Petrie-Norris, Ramos, Blanca Rubio, Salas, Smith, Voepel, Waldron NVR Arambula, Cooper, Fong, Maienschein, O'Donnell [Final floor vote from the bill votes page for AB 1482 (2019-2020), saved by browser from leginfo.legislature.ca.gov on 2026-09-29; the site's robots.txt disallows crawling.]

---
snapshot_id: 7346d636-0059-5547-b6d6-5113cf6b4140
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB1482

Assembly Bill No. 1482 CHAPTER 597 An act to add and repeal Sections 1946.2, 1947.12, and 1947.13 of the Civil Code, relating to tenancy. [ Approved by Governor October 08, 2019. Filed with Secretary of State October 08, 2019. ] LEGISLATIVE COUNSEL'S DIGEST AB 1482, Chiu. Tenant Protection Act of 2019: tenancy: rent caps. Existing law specifies that a hiring of residential real property, for a term not specified by the parties, is deemed to be renewed at the end of the term implied by law unless one of the parties gives written notice to the other of that party’s intention to terminate. Existing law requires an owner of a residential dwelling to give notice at least 60 days prior to the proposed date of termination, or at least 30 days prior to the proposed date of termination if any tenant or resident has resided in the dwelling for less than one year, as specified. Existing law requires any notice given by an owner to be given in a prescribed manner, to contain certain information, and to be formatted, as specified. This bill would, with certain exceptions, prohibit an owner, as defined, of residential real property from terminating a tenancy without just cause, as defined, which the bill would require to be stated in the written notice to terminate tenancy when the tenant has continuously and lawfully occupied the residential real property for 12 months, except as provided. The bill would require, for certain just cause terminations that are curable, that the owner give a notice of violation and an opportunity to cure the violation prior to issuing the notice of termination. The bill, if the violation is not cured within the time period set forth in the notice, would authorize a 3-day notice to quit without an opportunity to cure to be served to terminate the tenancy. The bill would require, for no-fault just cause terminations, as specified, that the owner, at the owner’s option, either assist certain tenants to relocate, regardless of the tenant’s income, by providing a direct payment of one month’s rent to the tenant, as specified, or waive in writing the payment of rent for the final month of the tenancy, prior to the rent becoming due. The bill would require the actual amount of relocation assistance or rent waiver provided to a tenant that fails to vacate after the expiration of the notice to terminate the tenancy to be recoverable as damages in an action to recover possession. The bill would provide that if the owner does not provide relocation assistance, the notice of termination is void. The bill would except certain properties and circumstances from the application of its provisions. The bill would require an owner of residential property to provide prescribed notice to a tenant of the tenant’s rights under these provisions. The bill would not apply to residential real property subject to a local ordinance requiring just cause for termination adopted on or before September 1, 2019, or to residential real property subject to a local ordinance requiring just cause for termination adopted or amended after September 1, 2019, that is more protective than these provisions, as defined. The bill would void any waiver of the rights under these provisions. The bill would repeal these provisions as of January 1, 2030. Existing law governs the hiring of residential dwelling units and requires a landlord to provide specified notice to tenants prior to an increase in rent. Existing law, the Costa-Hawkins Rental Housing Act, prescribes statewide limits on the application of local rent control with regard to certain properties. That act, among other things, authorizes an owner of residential real property to establish the initial and all subsequent rental rates for a dwelling or unit that meets specified criteria, subject to certain limitations. This bill would, until January 1, 2030, prohibit an owner of residential real property from, over the course of any 12-month period, increasing the gross rental rate for a dwelling or unit more than 5% plus the percentage change in the cost of living, as defined, or 10%, whichever is lower, of the lowest gross rental rate charged for the immediately preceding 12 months, subject to specified conditions. The bill would prohibit an owner of a unit of residential real property from increasing the gross rental rate for the unit in more than 2 increments over a 12-month period, after the tenant remains in occupancy of the unit over a 12-month period. The bill would exempt certain properties from these provisions. The bill would require the Legislative Analyst’s Office to submit a report, on or before January 1, 2030, to the Legislature regarding the effectiveness of these provisions. The bill would provide that these provisions apply to all rent increases occurring on or after March 15, 2019. The bill would provide that in the event that an owner increased the rent by more than the amount specified above between March 15, 2019, and January 1, 2020, the applicable rent on January 1, 2020, shall be the rent as of March 15, 2019, plus the maximum permissible increase, and the owner shall not be liable to the tenant for any corresponding rent overpayment. The bill would authorize an owner who increased the rent by less than the amount specified above between March 15, 2019, and January 1, 2020, to increase the rent twice within 12 months of March 15, 2019, but not by more than the amount specified above. The bill would void any waiver of the rights under these provisions. The Planning and Zoning Law requires the owner of an assisted housing development in which there will be an expiration of rental restrictions to, among other things, provide notice of the proposed change to each affected tenant household residing in the assisted housing development subject to specified procedures and requirements, and to also provide specified entities notice and an opportunity to submit an offer to purchase the development prior to the expiration of the rental restrictions. This bill would authorize an owner of an assisted housing development, who demonstrates, under penalty of perjury, compliance with the provisions described above with regard to the expiration of rental restrictions, to establish the initial unassisted rental rate for units without regard to the cap on rent increases discussed above, but would require the owner to comply with the above cap on rent increases for subsequent rent increases in the development. The bill would authorize an owner of a deed-restricted affordable housing unit or an affordable housing unit subject to a regulatory restriction contained in an agreement with a government agency limiting rental rates that is not within an assisted housing development to establish the initial rental rate for the unit upon the expiration of the restriction, but would require the owner to comply with the above cap on rent increases for subsequent rent increases for the unit. The bill would repeal these provisions on January 1, 2030. The bill would void any waiver of the rights under these provisions. By requiring an owner of an assisted housing development to demonstrate compliance with specified provisions under penalty of perjury, this bill would expand the existing crime of perjury and thus would impose a state-mandated local program. The California Constitution requires the state to reimburse local agencies and school districts for certain costs mandated by the state. Statutory provisions establish procedures for making that reimbursement. This bill would provide that no reimbursement is required by this act for a specified reason. DIGEST KEY Vote: majority Appropriation: no Fiscal Committee: yes Local Program: yes BILL TEXT THE PEOPLE OF THE STATE OF CALIFORNIA DO ENACT AS FOLLOWS: SECTION 1. This act shall be known, and may be cited, as the Tenant Protection Act of 2019. SEC. 2. Section 1946.2 is added to the Civil Code, to read: 1946.2. (a) Notwithstanding any other law, after a tenant has continuously and lawfully occupied a residential real property for 12 months, the owner of the residential real property shall not terminate the tenancy without just cause, which shall be stated in the written notice to terminate tenancy. If any additional adult tenants are added to the lease before an existing tenant has continuously and lawfully occupied the residential real property for 24 months, then this subdivision shall only apply if either of the following are satisfied: (1) All of the tenants have continuously and lawfully occupied the residential real property for 12 months or more. (2) One or more tenants have continuously and lawfully occupied the residential real property for 24 months or more. (b) For purposes of this section, “just cause” includes either of the following: (1) At-fault just cause, which is any of the following: (A) Default in the payment of rent. (B) A breach of a material term of the lease, as described in paragraph (3) of Section 1161 of the Code of Civil Procedure, including, but not limited to, violation of a provision of the lease after being issued a written notice to correct the violation. (C) Maintaining, committing, or permitting the maintenance or commission of a nuisance as described in paragraph (4) of Section 1161 of the Code of Civil Procedure. (D) Committing waste as described in paragraph (4) of Section 1161 of the Code of Civil Procedure. (E) The tenant had a written lease that terminated on or after January 1, 2020, and after a written request or demand from the owner, the tenant has refused to execute a written extension or renewal of the lease for an additional term of similar duration with similar provisions, provided that those terms do not violate this section or any other provision of law. (F) Criminal activity by the tenant on the residential real property, including any common areas, or any criminal activity or criminal threat, as defined in subdivision (a) of Section 422 of the Penal Code, on or off the residential real property, that is directed at any owner or agent of the owner of the residential real property. (G) Assigning or subletting the premises in violation of the tenant’s lease, as described in paragraph (4) of Section 1161 of the Code of Civil Procedure. (H) The tenant’s refusal to allow the owner to enter the residential real property as authorized by Sections 1101.5 and 1954 of this code, and Sections 13113.7 and 17926.1 of the Health and Safety Code. (I) Using the premises for an unlawful purpose as described in paragraph (4) of Section 1161 of the Code of Civil Procedure. (J) The employee, agent, or licensee’s failure to vacate after their termination as an employee, agent, or a licensee as described in paragraph (1) of Section 1161 of the Code of Civil Procedure. (K) When the tenant fails to deliver possession of the residential real property after providing the owner written notice as provided in Section 1946 of the tenant’s intention to terminate the hiring of the real property, or makes a written offer to surrender that is accepted in writing by the landlord, but fails to deliver possession at the time specified in that written notice as described in paragraph (5) of Section 1161 of the Code of Civil Procedure. (2) No-fault just cause, which includes any of the following: (A) (i) Intent to occupy the residential real property by the owner or their spouse, domestic partner, children, grandchildren, parents, or grandparents. (ii) For leases entered into on or after July 1, 2020, clause (i) shall apply only if the tenant agrees, in writing, to the termination, or if a provision of the lease allows the owner to terminate the lease if the owner, or their spouse, domestic partner, children, grandchildren, parents, or grandparents, unilaterally decides to occupy the residential real property. Addition of a provision allowing the owner to terminate the lease as described in this clause to a new or renewed rental agreement or fixed-term lease constitutes a similar provision for the purposes of subparagraph (E) of paragraph (1). (B) Withdrawal of the residential real property from the rental market. (C) (i) The owner complying with any of the following: (I) An order issued by a government agency or court relating to habitability that necessitates vacating the residential real property. (II) An order issued by a government agency or court to vacate the residential real property. (III) A local ordinance that necessitates vacating the residential real property. (ii) If it is determined by any government agency or court that the tenant is at fault for the condition or conditions triggering the order or need to vacate under clause (i), the tenant shall not be entitled to relocation assistance as outlined in paragraph (3) of subdivision (d). (D) (i) Intent to demolish or to substantially remodel the residential real property. (ii) For purposes of this subparagraph, “substantially remodel” means the replacement or substantial modification of any structural, electrical, plumbing, or mechanical system that requires a permit from a governmental agency, or the abatement of hazardous materials, including lead-based paint, mold, or asbestos, in accordance with applicable federal, state, and local laws, that cannot be reasonably accomplished in a safe manner with the tenant in place and that requires the tenant to vacate the residential real property for at least 30 days. Cosmetic improvements alone, including painting, decorating, and minor repairs, or other work that can be performed safely without having the residential real property vacated, do not qualify as substantial rehabilitation. (c) Before an owner of residential real property issues a notice to terminate a tenancy for just cause that is a curable lease violation, the owner shall first give notice of the violation to the tenant with an opportunity to cure the violation pursuant to paragraph (3) of Section 1161 of the Code of Civil Procedure. If the violation is not cured within the time period set forth in the notice, a three-day notice to quit without an opportunity to cure may thereafter be served to terminate the tenancy. (d) (1) For a tenancy for which just cause is required to terminate the tenancy under subdivision (a), if an owner of residential real property issues a termination notice based on a no-fault just cause described in paragraph (2) of subdivision (b), the owner shall, regardless of the tenant’s income, at the owner’s option, do one of the following: (A) Assist the tenant to relocate by providing a direct payment to the tenant as described in paragraph (3). (B) Waive in writing the payment of rent for the final month of the tenancy, prior to the rent becoming due. (2) If an owner issues a notice to terminate a tenancy for no-fault just cause, the owner shall notify the tenant of the tenant’s right to relocation assistance or rent waiver pursuant to this section. If the owner elects to waive the rent for the final month of the tenancy as provided in subparagraph (B) of paragraph (1), the notice shall state the amount of rent waived and that no rent is due for the final month of the tenancy. (3) (A) The amount of relocation assistance or rent waiver shall be equal to one month of the tenant’s rent that was in effect when the owner issued the notice to terminate the tenancy. Any relocation assistance shall be provided within 15 calendar days of service of the notice. (B) If a tenant fails to vacate after the expiration of the notice to terminate the tenancy, the actual amount of any relocation assistance or rent waiver provided pursuant to this subdivision shall be recoverable as damages in an action to recover possession. (C) The relocation assistance or rent waiver required by this subdivision shall be credited against any other relocation assistance required by any other law. (4) An owner’s failure to strictly comply with this subdivision shall render the notice of termination void. (e) This section shall not apply to the following types of residential real properties or residential circumstances: (1) Transient and tourist hotel occupancy as defined in subdivision (b) of Section 1940. (2) Housing accommodations in a nonprofit hospital, religious facility, extended care facility, licensed residential care facility for the elderly, as defined in Section 1569.2 of the Health and Safety Code, or an adult residential facility, as defined in Chapter 6 of Division 6 of Title 22 of the Manual of Policies and Procedures published by the State Department of Social Services. (3) Dormitories owned and operated by an institution of higher education or a kindergarten and grades 1 to 12, inclusive, school. (4) Housing accommodations in which the tenant shares bathroom or kitchen facilities with the owner who maintains their principal residence at the residential real property. (5) Single-family owner-occupied residences, including a residence in which the owner-occupant rents or leases no more than two units or bedrooms, including, but not limited to, an accessory dwelling unit or a junior accessory dwelling unit. (6) A duplex in which the owner occupied one of the units as the owner’s principal place of residence at the beginning of the tenancy, so long as the owner continues in occupancy. (7) Housing that has been issued a certificate of occupancy within the previous 15 years. (8) Residential real property that is alienable separate from the title to any other dwelling unit, provided that both of the following apply: (A) The owner is not any of the following: (i) A real estate investment trust, as defined in Section 856 of the Internal Revenue Code. (ii) A corporation. (iii) A limited liability company in which at least one member is a corporation. (B) (i) The tenants have been provided written notice that the residential property is exempt from this section using the following statement: “This property is not subject to the rent limits imposed by Section 1947.12 of the Civil Code and is not subject to the just cause requirements of Section 1946.2 of the Civil Code. This property meets the requirements of Sections 1947.12 (d)(5) and 1946.2 (e)(8) of the Civil Code and the owner is not any of the following: (1) a real estate investment trust, as defined by Section 856 of the Internal Revenue Code; (2) a corporation; or (3) a limited liability company in which at least one member is a corporation.” (ii) For a tenancy existing before July 1, 2020, the notice required under clause (i) may, but is not required to, be provided in the rental agreement. (iii) For any tenancy commenced or renewed on or after July 1, 2020, the notice required under clause (i) must be provided in the rental agreement. (iv) Addition of a provision containing the notice required under clause (i) to any new or renewed rental agreement or fixed-term lease constitutes a similar provision for the purposes of subparagraph (E) of paragraph (1) of subdivision (b). (9) Housing restricted by deed, regulatory restriction contained in an agreement with a government agency, or other recorded document as affordable housing for persons and families of very low, low, or moderate income, as defined in Section 50093 of the Health and Safety Code, or subject to an agreement that provides housing subsidies for affordable housing for persons and families of very low, low, or moderate income, as defined in Section 50093 of the Health and Safety Code or comparable federal statutes. (f) An owner of residential real property subject to this section shall provide notice to the tenant as follows: (1) For any tenancy commenced or renewed on or after July 1, 2020, as an addendum to the lease or rental agreement, or as a written notice signed by the tenant, with a copy provided to the tenant. (2) For a tenancy existing prior to July 1, 2020, by written notice to the tenant no later than August 1, 2020, or as an addendum to the lease or rental agreement. (3) The notification or lease provision shall be in no less than 12-point type, and shall include the following: “California law limits the amount your rent can be increased. See Section 1947.12 of the Civil Code for more information. California law also provides that after all of the tenants have continuously and lawfully occupied the property for 12 months or more or at least one of the tenants has continuously and lawfully occupied the property for 24 months or more, a landlord must provide a statement of cause in any notice to terminate a tenancy. See Section 1946.2 of the Civil Code for more information.” The provision of the notice shall be subject to Section 1632. (g) (1) This section does not apply to the following residential real property: (A) Residential real property subject to a local ordinance requiring just cause for termination of a residential tenancy adopted on or before September 1, 2019, in which case the local ordinance shall apply. (B) Residential real property subject to a local ordinance requiring just cause for termination of a residential tenancy adopted or amended after September 1, 2019, that is more protective than this section, in which case the local ordinance shall apply. For purposes of this subparagraph, an ordinance is “more protective” if it meets all of the following criteria: (i) The just cause for termination of a residential tenancy under the local ordinance is consistent with this section. (ii) The ordinance further limits the reasons for termination of a residential tenancy, provides for higher relocation assistance amounts, or provides additional tenant protections that are not prohibited by any other provision of law. (iii) The local government has made a binding finding within their local ordinance that the ordinance is more protective than the provisions of this section. (2) A residential real property shall not be subject to both a local ordinance requiring just cause for termination of a residential tenancy and this section. (3) A local ordinance adopted after September 1, 2019, that is less protective than this section shall not be enforced unless this section is repealed. (h) Any waiver of the rights under this section shall be void as contrary to public policy. (i) For the purposes of this section, the following definitions shall apply: (1) “Owner” and “residential real property” have the same meaning as those terms are defined in Section 1954.51. (2) “Tenancy” means the lawful occupation of residential real property and includes a lease or sublease. (j) This section shall remain in effect only until January 1, 2030, and as of that date is repealed. SEC. 3. Section 1947.12 is added to the Civil Code, to read: 1947.12. (a) (1) Subject to subdivision (b), an owner of residential real property shall not, over the course of any 12-month period, increase the gross rental rate for a dwelling or a unit more than 5 percent plus the percentage change in the cost of living, or 10 percent, whichever is lower, of the lowest gross rental rate charged for that dwelling or unit at any time during the 12 months prior to the effective date of the increase. In determining the lowest gross rental amount pursuant to this section, any rent discounts, incentives, concessions, or credits offered by the owner of such unit of residential real property and accepted by the tenant shall be excluded. The gross per-month rental rate and any owner-offered discounts, incentives, concessions, or credits shall be separately listed and identified in the lease or rental agreement or any amendments to an existing lease or rental agreement. (2) If the same tenant remains in occupancy of a unit of residential real property over any 12-month period, the gross rental rate for the unit of residential real property shall not be increased in more than two increments over that 12-month period, subject to the other restrictions of this subdivision governing gross rental rate increase. (b) For a new tenancy in which no tenant from the prior tenancy remains in lawful possession of the residential real property, the owner may establish the initial rental rate not subject to subdivision (a). Subdivision (a) is only applicable to subsequent increases after that initial rental rate has been established. (c) A tenant of residential real property subject to this section shall not enter into a sublease that results in a total rent for the premises that exceeds the allowable rental rate authorized by subdivision (a). Nothing in this subdivision authorizes a tenant to sublet or assign the tenant’s interest where otherwise prohibited. (d) This section shall not apply to the following residential real properties: (1) Housing restricted by deed, regulatory restriction contained in an agreement with a government agency, or other recorded document as affordable housing for persons and families of very low, low, or moderate income, as defined in Section 50093 of the Health and Safety Code, or subject to an agreement that provides housing subsidies for affordable housing for persons and families of very low, low, or moderate income, as defined in Section 50093 of the Health and Safety Code or comparable federal statutes. (2) Dormitories constructed and maintained in connection with any higher education institution within the state for use and occupancy by students in attendance at the institution. (3) Housing subject to rent or price control through a public entity’s valid exercise of its police power consistent with Chapter 2.7 (commencing with Section 1954.50) that restricts annual increases in the rental rate to an amount less than that provided in subdivision (a). (4) Housing that has been issued a certificate of occupancy within the previous 15 years. (5) Residential real property that is alienable separate from the title to any other dwelling unit, provided that both of the following apply: (A) The owner is not any of the following: (i) A real estate investment trust, as defined in Section 856 of the Internal Revenue Code. (ii) A corporation. (iii) A limited liability company in which at least one member is a corporation. (B) (i) The tenants have been provided written notice that the residential real property is exempt from this section using the following statement: “This property is not subject to the rent limits imposed by Section 1947.12 of the Civil Code and is not subject to the just cause requirements of Section 1946.2 of the Civil Code. This property meets the requirements of Sections 1947.12 (c)(5) and 1946.2 (e)(7) of the Civil Code and the owner is not any of the following: (1) a real estate investment trust, as defined by Section 856 of the Internal Revenue Code; (2) a corporation; or (3) a limited liability company in which at least one member is a corporation.” (ii) For a tenancy existing before July 1, 2020, the notice required under clause (i) may, but is not required to, be provided in the rental agreement. (iii) For a tenancy commenced or renewed on or after July 1, 2020, the notice required under clause (i) must be provided in the rental agreement. (iv) Addition of a provision containing the notice required under clause (i) to any new or renewed rental agreement or fixed-term lease constitutes a similar provision for the purposes of subparagraph (E) of paragraph (1) of subdivision (b) of Section 1946.2. (6) A duplex in which the owner occupied one of the units as the owner’s principal place of residence at the beginning of the tenancy, so long as the owner continues in occupancy. (e) An owner shall provide notice of any increase in the rental rate, pursuant to subdivision (a), to each tenant in accordance with Section 827. (f) (1) On or before January 1, 2030, the Legislative Analyst’s Office shall report to the Legislature regarding the effectiveness of this section and Section 1947.13. The report shall include, but not be limited to, the impact of the rental rate cap pursuant to subdivision (a) on the housing market within the state. (2) The report required by paragraph (1) shall be submitted in compliance with Section 9795 of the Government Code. (g) For the purposes of this section, the following definitions shall apply: (1) “Owner” and “residential real property” shall have the same meaning as those terms are defined in Section 1954.51. (2) “Percentage change in the cost of living” means the percentage change from April 1 of the prior year to April 1 of the current year in the regional Consumer Price Index for the region where the residential real property is located, as published by the United States Bureau of Labor Statistics. If a regional index is not available, the California Consumer Price Index for All Urban Consumers for all items, as determined by the Department of Industrial Relations, shall apply. (3) “Tenancy” means the lawful occupation of residential real property and includes a lease or sublease. (h) (1) This section shall apply to all rent increases subject to subdivision (a) occurring on or after March 15, 2019. This section shall become operative January 1, 2020. (2) In the event that an owner has increased the rent by more than the amount permissible under subdivision (a) between March 15, 2019, and January 1, 2020, both of the following shall apply: (A) The applicable rent on January 1, 2020, shall be the rent as of March 15, 2019, plus the maximum permissible increase under subdivision (a). (B) An owner shall not be liable to the tenant for any corresponding rent overpayment. (3) An owner of residential real property subject to subdivision (a) who increased the rental rate on that residential real property on or after March 15, 2019, but prior to January 1, 2020, by an amount less than the rental rate increase permitted by subdivision (a) shall be allowed to increase the rental rate twice, as provided in paragraph (2) of subdivision (a), within 12 months of March 15, 2019, but in no event shall that rental rate increase exceed the maximum rental rate increase permitted by subdivision (a). (i) Any waiver of the rights under this section shall be void as contrary to public policy. (j) This section shall remain in effect until January 1, 2030, and as of that date is repealed. (k) (1) The Legislature finds and declares that the unique circumstances of the current housing crisis require a statewide response to address rent gouging by establishing statewide limitations on gross rental rate increases. (2) It is the intent of the Legislature that this section should apply only for the limited time needed to address the current statewide housing crisis, as described in paragraph (1). This section is not intended to expand or limit the authority of local governments to establish local policies regulating rents consistent with Chapter 2.7 (commencing with Section 1954.50), nor is it a statement regarding the appropriate, allowable rental rate increase when a local government adopts a policy regulating rent that is otherwise consistent with Chapter 2.7 (commencing with Section 1954.50). (3) Nothing in this section authorizes a local government to establish limitations on any rental rate increases not otherwise permissible under Chapter 2.7 (commencing with Section 1954.50), or affects the existing authority of a local government to adopt or maintain rent controls or price controls consistent with that chapter. SEC. 4. Section 1947.13 is added to the Civil Code, to read: 1947.13. (a) Notwithstanding Section 1947.12, upon the expiration of rental restrictions, the following shall apply: (1) The owner of an assisted housing development who demonstrates, under penalty of perjury, compliance with all applicable provisions of Sections 65863.10, 65863.11, and 65863.13 of the Government Code and any other applicable law or regulation intended to promote the preservation of assisted housing, may establish the initial unassisted rental rate for units in the applicable housing development. Any subsequent rent increase in the development shall be subject to Section 1947.12. (2) The owner of a deed-restricted affordable housing unit or an affordable housing unit subject to a regulatory restriction contained in an agreement with a government agency limiting rental rates that is not within an assisted housing development may establish the initial rental rate for the unit upon the expiration of the restriction. Any subsequent rent increase for the unit shall be subject to Section 1947.12. (b) For purposes of this section: (1) “Assisted housing development” has the same meaning as defined in paragraph (3) of subdivision (a) of Section 65863.10 of the Government Code. (2) “Expiration of rental restrictions” has the same meaning as defined in paragraph (5) of subdivision (a) of Section 65863.10 of the Government Code. (c) This section shall remain in effect until January 1, 2030, and as of that date is repealed. (d) Any waiver of the rights under this section shall be void as contrary to public policy. SEC. 5. No reimbursement is required by this act pursuant to Section 6 of Article XIII B of the California Constitution because the only costs that may be incurred by a local agency or school district will be incurred because this act creates a new crime or infraction, eliminates a crime or infraction, or changes the penalty for a crime or infraction, within the meaning of Section 17556 of the Government Code, or changes the definition of a crime within the meaning of Section 6 of Article XIII B of the California Constitution. [Chaptered text of AB 1482 (2019-2020), saved by browser from leginfo.legislature.ca.gov on 2026-09-29; the site's robots.txt disallows crawling.]