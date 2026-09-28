You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-28-shadow-kolodin/labels/coder-2.json. Write JSON only, matching
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

politician_id: 178470c3-94ea-442a-a558-7b3c841ce858  office_id: f04e0b05-9d07-4f0d-b4a9-c9dd784545fe
Alexander Kolodin — State Representative, Arizona (seated, level: state)
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
snapshot_id: e7ae1801-618d-53bc-accb-5b50af1db3e3
source_kind: public-record
url: https://www.azleg.gov/legtext/56leg/2R/laws/0001.htm

Chapter 0001 - 562R - H Ver of HB2785 House Engrossed primary; identification; canvass; recounts; ballots State of Arizona House of Representatives Fifty-sixth Legislature Second Regular Session 2024 CHAPTER 1 HOUSE BILL 2785 An Act amending sections 16-411, 16-461, 16-510, 16-542, 16-547 and 16-550, Arizona Revised Statutes; amending title 16, chapter 4, article 8, Arizona Revised Statutes, by adding section 16-550.01; amending sections 16-551, 16-552, 16-579, 16-584, 16-622, 16-642, 16-645, 16-646, 16-648, 16-662, 16-663 and 16-664, Arizona Revised Statutes; relating to conduct of elections. (TEXT OF BILL BEGINS ON NEXT PAGE) Be it enacted by the Legislature of the State of Arizona: Section 1. Section 16-411, Arizona Revised Statutes, is amended to read: START_STATUTE 16-411. Designation of election precincts and polling places; voting centers; electioneering; wait times A. The board of supervisors of each county, on or before October 1 of each year preceding the year of a general election, by an order, shall establish a convenient number of election precincts in the county and define the boundaries of the precincts as follows: 1. The election precinct boundaries shall be established so as to be included within election districts prescribed by law for elected officers of the state and its political subdivisions, including community college district precincts, except those elected officers provided for in titles 30 and 48. 2. If after October 1 of the year preceding the year of a general election the board of supervisors must further adjust precinct boundaries due to the redistricting of election districts as prescribed by law and to comply with this subsection, the board of supervisors shall adjust these precinct boundaries as soon as is practicable. B. At least twenty days before a general or primary election, and at least ten days before a special election, the board shall designate one polling place within each precinct where the election shall be held, except that: 1. On a specific finding of the board, included in the order or resolution designating polling places pursuant to this subsection, that no suitable polling place is available within a precinct, a polling place for that precinct may be designated within an adjacent precinct. 2. Adjacent precincts may be combined if boundaries so established are included in election districts prescribed by law for state elected officials and political subdivisions including community college districts but not including elected officials prescribed by titles 30 and 48. The officer in charge of elections may also split a precinct for administrative purposes. The polling places shall be listed in separate sections of the order or resolution. 3. On a specific finding of the board that the number of persons who are listed as early voters pursuant to section 16-544 and who are not expected to have their ballots tabulated at the polling place as prescribed in section 16-579.02 is likely to substantially reduce the number of voters appearing at one or more specific polling places at that election, adjacent precincts may be consolidated by combining polling places and precinct boards for that election. The board of supervisors shall ensure that a reasonable and adequate number of polling places will be designated for that election. Any consolidated polling places shall be listed in separate sections of the order or resolution of the board. 4. On a specific resolution of the board, the board may authorize the use of voting centers in place of or in addition to specifically designated polling places. A voting center shall allow any voter in that county to receive the appropriate ballot for that voter on election day after presenting identification as prescribed in section 16-579 and to lawfully cast the ballot. Voting centers may be established in coordination and consultation with the county recorder, at other county offices or at other locations in the county deemed appropriate. 5. On a specific resolution of the board of supervisors that is limited to a specific election date and that is voted on by a recorded vote, the board may authorize the county recorder or other officer in charge of elections to use emergency voting centers as follows: (a) The board shall specify in the resolution the location and the hours of operation of the emergency voting centers. (b) A qualified elector voting at an emergency voting center shall provide identification as prescribed in section 16-579, except that notwithstanding section 16-579, subsection A, paragraph 2, for any voting at an emergency voting center, the county recorder or other officer in charge of elections may allow a qualified elector to update the elector's voter registration information as provided for in the secretary of state's instructions and procedures manual adopted pursuant to section 16-452. (c) If an emergency voting center established pursuant to this section becomes unavailable and there is not sufficient time for the board of supervisors to convene to approve an alternate location for that emergency voting center, the county recorder or other officer in charge of elections may make changes to the approved emergency voting center location and shall notify the public and the board of supervisors regarding that change as soon as practicable. The alternate emergency voting center shall be as close in proximity to the approved emergency voting center location as possible. C. If the board fails to designate the place for holding the election, or if it cannot be held at or about the place designated, the justice of the peace in the precinct, two days before the election, by an order, copies of which the justice of the peace shall immediately post in three public places in the precinct, shall designate the place within the precinct for holding the election. If there is no justice of the peace in the precinct, or if the justice of the peace fails to do so, the election board of the precinct shall designate and give notice of the place within the precinct of holding the election. For any election in which there are no candidates for elected office appearing on the ballot, the board may consolidate polling places and precinct boards and may consolidate the tabulation of results for that election if all of the following apply: 1. All affected voters are notified by mail of the change at least thirty-three days before the election. 2. Notice of the change in polling places includes notice of the new voting location, notice of the hours for voting on election day and notice of the telephone number to call for voter assistance. 3. All affected voters receive information on early voting that includes the application used to request an early voting ballot. D. The board is not required to designate a polling place for special district mail ballot elections held pursuant to article 8.1 of this chapter, but the board may designate one or more sites for voters to deposit marked ballots until 7:00 p.m. on the day of the election. E. Except as provided in subsection F of this section, a public school shall provide sufficient space for use as a polling place for any city, county or state election when requested by the officer in charge of elections. F. The principal of the school may deny a request to provide space for use as a polling place for any city, county or state election if, within two weeks after a request has been made, the principal provides a written statement indicating a reason the election cannot be held in the school, including any of the following: 1. Space is not available at the school. 2. The safety or welfare of the children would be jeopardized. G. Beginning in 2026, the department of administration shall coordinate with state agencies and counties to provide available and appropriate state-owned facilities for use as a voting location for any city, county or state election when requested by the officer in charge of elections. [deleted: G.] H. The board shall make available to the public as a public record a list of the polling places for all precincts in which the election is to be held. [deleted: H.] I. Except in the case of an emergency, any facility that is used as a polling place on election day or that is used as an early voting site during the period of early voting shall allow persons to electioneer and engage in other political activity outside of the seventy-five foot limit prescribed by section 16-515 in public areas and parking lots used by voters. This subsection does not allow the temporary or permanent construction of structures in public areas and parking lots or the blocking or other impairment of access to parking spaces for voters. The county recorder or other officer in charge of elections shall post on its website at least two weeks before election day a list of those polling places in which emergency conditions prevent electioneering and shall specify the reason the emergency designation was granted and the number of attempts that were made to find a polling place before granting an emergency designation. If the polling place is not on the website list of polling places with emergency designations, electioneering and other political activity shall be allowed outside of the seventy-five foot limit. If an emergency arises after the county recorder or other officer in charge of elections' initial website posting, the county recorder or other officer in charge of elections shall update the website as soon as is practicable to include any new polling places, shall highlight the polling place location on the website and shall specify the reason the emergency designation was granted and the number of attempts that were made to find a polling place before granting an emergency designation. [deleted: I.] J. For the purposes of this section, a county recorder or other officer in charge of elections shall designate a polling place as an emergency polling place and thus prohibit persons from electioneering and engaging in other political activity outside of the seventy-five foot limit prescribed by section 16-515 but inside the property of the facility that is hosting the polling place if any of the following occurs: 1. An act of God renders a previously set polling place as unusable. 2. A county recorder or other officer in charge of elections has exhausted all options and there are no suitable facilities in a precinct that are willing to be a polling place unless a facility can be given an emergency designation. [deleted: J.] K. The secretary of state shall provide through the instructions and procedures manual adopted pursuant to section 16-452 the maximum allowable wait time for any election that is subject to section 16-204 and provide for a method to reduce voter wait time at the polls in the primary and general elections. The method shall consider at least all of the following for primary and general elections in each precinct: 1. The number of ballots voted in the prior primary and general elections. 2. The number of registered voters who voted early in the prior primary and general elections. 3. The number of registered voters and the number of registered voters who cast an early ballot for the current primary or general election. 4. The number of registered voters whose early ballots were tabulated on-site as prescribed in section 16-579.02 in the prior primary and general elections. 5. The number of election board members and clerks and the number of rosters that will reduce voter wait time at the polls. END_STATUTE Sec. 2. Section 16-461, Arizona Revised Statutes, is amended to read: START_STATUTE 16-461. Sample primary election ballots; submission to party chairmen for examination; preparation, printing and distribution of ballot A. At least forty-five days before a primary election, the officer in charge of that election shall: 1. Prepare a proof of a sample ballot. 2. Submit the sample ballot proof of each party to the county chairman or in city or town primaries to the city or town chairman. 3. Mail a sample ballot proof to each candidate for whom a nomination paper and petitions have been filed. B. Within [deleted: five] two calendar days after receipt of the sample ballot, the county chairman of each political party and any candidate in that election who has submitted and confirmed an email address shall suggest to the election officer any change the chairman or candidate considers should be made in the chairman's or candidate's party ballot, and if on examination the election officer finds an error or omission [deleted: in] on the ballot , the officer shall correct it. The election officer shall [deleted: cause] print and distribute the sample ballots [deleted: to be printed and distributed] as required by law, shall maintain a copy of each sample ballot and shall post a notice indicating that sample ballots are available on request. The official sample ballot shall be printed on colored paper or white paper with a different colored stripe for each party that is represented on that ballot. For voters who are not registered with a party that is entitled to continued representation on the ballot pursuant to section 16-804, the election officer may print and distribute the required sample ballots in an alternative format, including a reduced size format. C. Not later than forty days before a primary election, the county chairman of a political party may request one sample primary election ballot of the chairman's party for each election precinct. D. The board of supervisors shall have printed mailer-type sample ballots for a primary election and shall mail at least eleven days before the election one sample ballot of a political party to each household containing a registered voter of that political party unless that registered voter is on the active early voting list established pursuant to section 16-544. Each sample ballot shall contain the following statement: "This is a sample ballot and cannot be used as an official ballot under any circumstances". A certified claim shall be presented to the secretary of state by the board of supervisors for the actual cost of printing, labeling and postage of each sample ballot actually mailed, and the secretary of state shall direct payment of the authenticated claim from funds of the secretary of state's office. E. For city and town elections, the governing body of a city or town may have printed mailer-type sample ballots for a primary election. If the city or town has printed such sample ballots, the city or town shall provide for the distribution of such ballots and shall bear the expense of printing and distributing [deleted: of] such sample ballots. F. The return address on the mailer-type sample ballots shall not contain the name of an appointed or elected public officer nor may the name of an appointed or elected public officer be used to indicate who produced the sample ballot. G. The great seal of the state of Arizona shall be imprinted along with the words "official voting materials" on the mailing face of each sample ballot. In county, city or town elections the seal of such jurisdiction shall be substituted for the state seal. END_STATUTE Sec. 3. Section 16-510, Arizona Revised Statutes, is amended to read: START_STATUTE 16-510. Sample ballots; preparation and distribution A. Before printing the sample ballots for the general election the board of supervisors shall send to each candidate whose name did not appear on the preceding primary election ballot and to the county chairperson of each political party a ballot proof of the sample ballot for the candidate's and chairperson's review. Within two calendar days after receipt of the sample ballot, Those candidates and the county chairperson of each political party shall suggest to the election officer any change the candidate or chairperson considers should be made to the ballot, and if on examination the election officer finds an error or omission on the ballot, the officer shall correct the error or Omission. B. The board of supervisors shall print and distribute, for the information of voters at each polling place, a number of sample ballots as it deems necessary. C. The board of supervisors shall have printed mailer-type sample ballots for a general election and shall mail at least eleven days before the election one such sample ballot to each household in the county containing a registered voter unless that registered voter is on the active early voting list established pursuant to section 16-544. Each sample ballot shall contain the following statement: "This is a sample ballot and cannot be used as an official ballot under any circumstances". A certified claim shall be presented to the secretary of state by the board of supervisors for the actual cost of printing, labeling and postage of each sample ballot actually mailed, and the secretary of state shall direct payment of the authenticated claim from funds of the secretary of state's office. D. For city and town elections, the governing body of a city or town may have printed mailer-type sample ballots for a general election. If the city or town has printed such sample ballots, the city or town shall provide for the distribution of such ballots and shall bear the expense of printing and distributing such sample ballots. E. For special district elections, the governing body of a special district may have printed mailer-type sample ballots. If the special district has printed such sample ballots, the special district shall provide for the distribution of such ballots and shall bear the expense of printing and distributing such sample ballots. END_STATUTE Sec. 4. Section 16-542, Arizona Revised Statutes, is amended to read: START_STATUTE 16-542. Request for ballot; civil penalties; violation; classification A. Within ninety-three days before any election called pursuant to the laws of this state, an elector may make a verbal or signed request to the county recorder, or other officer in charge of elections for the applicable political subdivision of this state in whose jurisdiction the elector is registered to vote, for an official early ballot. In addition to name and address, the requesting elector shall provide the date of birth and state or country of birth or other information that if compared to the voter registration information on file would confirm the identity of the elector. If the request indicates that the elector needs a primary election ballot and a general election ballot, the county recorder or other officer in charge of elections shall honor the request. For any partisan primary election, if the elector is not registered as a member of a political party that is entitled to continued representation on the ballot pursuant to section 16-804, the elector shall designate the ballot of only one of the political parties that is entitled to continued representation on the ballot and the elector may receive and vote the ballot of only that one political party, which also shall include any nonpartisan offices and ballot questions, or the elector shall designate the ballot for nonpartisan offices and ballot questions only and the elector may receive and vote the ballot that contains only nonpartisan offices and ballot questions. The county recorder or other officer in charge of elections shall process any request for an early ballot for a municipal election pursuant to this subsection. The county recorder may establish on-site early voting locations at the recorder's office, which shall be open and available for use beginning the same day that a county begins to send out the early ballots. The county recorder may also establish any other early voting locations in the county the recorder deems necessary. Any on-site early voting location or other early voting location shall require each elector to present identification as prescribed in section 16-579 before receiving a ballot. Notwithstanding section 16-579, subsection A, paragraph 2, at any on-site early voting location or other early voting location the county recorder or other officer in charge of elections may provide for a qualified elector to update the elector's voter registration information as provided for in the secretary of state's instructions and procedures manual adopted pursuant to section 16-452. B. Notwithstanding subsection A of this section, a request for an official early ballot from an absent uniformed services voter or overseas voter as defined in the uniformed and overseas citizens absentee voting act [deleted: of 1986] (P.L. 99-410; 52 United States Code section 20310) or a voter whose information is protected pursuant to section 16-153 that is received by the county recorder or other officer in charge of elections more than ninety-three days before the election is valid. If requested by the absent uniformed services or overseas voter, or a voter whose information is protected pursuant to section 16-153, the county recorder or other officer in charge of elections shall provide to the requesting voter early ballot materials through the next regularly scheduled general election for federal office immediately following receipt of the request unless a different period of time, which does not exceed the next two regularly scheduled general elections for federal office, is designated by the voter. C. The county recorder or other officer in charge of elections shall mail the early ballot and the envelope for its return postage prepaid to the address provided by the requesting elector within five days after receipt of the official early ballots from the officer charged by law with the duty of preparing ballots pursuant to section 16-545, except that early ballot distribution shall not begin more than twenty-seven days before the election. If an early ballot request is received on or before the thirty-first day before the election, the early ballot shall be distributed not earlier than the twenty-seventh day before the election and not later than the twenty-fourth day before the election. D. Only the elector may be in possession of that elector's unvoted early ballot. If a complete and correct request is made by the elector within twenty-seven days before the election, the mailing must be made within forty-eight hours after receipt of the request. Saturdays, Sundays and other legal holidays are excluded from the computation of the [deleted: forty-eight hour] forty-eight-hour period prescribed by this subsection. If a complete and correct request is made by an absent uniformed services voter or an overseas voter before the election, the regular early ballot shall be transmitted by mail, by fax or by other electronic format approved by the secretary of state within twenty-four hours after the early ballots are delivered pursuant to section 16-545, subsection B, excluding Sundays. E. In order to be complete and correct and to receive an early ballot by mail, an elector's request that an early ballot be mailed to the elector's residence or temporary address must include all of the information prescribed by subsection A of this section and must be received by the county recorder or other officer in charge of elections [deleted: no] not later than 5:00 p.m. on the eleventh day preceding the election. An elector who appears personally [deleted: no] not later than [deleted: 5:00] 7:00 p.m. on the Friday preceding the election at an on-site early voting location that is established by the county recorder or other officer in charge of elections shall be given a ballot after presenting identification as prescribed in section 16-579 and shall be [deleted: permitted] allowed to vote at the on-site location. Notwithstanding section 16-579, subsection A, paragraph 2, at any on-site early voting location the county recorder or other officer in charge of elections may provide for a qualified elector to update the elector's voter registration information as provided for in the secretary of state's instructions and procedures manual adopted pursuant to section 16-452. If an elector's request to receive an early ballot is not complete and correct but complies with all other requirements of this section, the county recorder or other officer in charge of elections shall attempt to notify the elector of the deficiency of the request. F. Unless an elector specifies that the address to which an early ballot is to be sent is a temporary address, the recorder may use the information from an early ballot request form to update voter registration records. G. The county recorder or other officer in charge of early balloting shall provide an alphabetized list of all voters in the precinct who have requested and have been sent an early ballot to the election board of the precinct in which the voter is registered not later than the day before the election. H. As a result of experiencing an emergency between [deleted: 5:00] 7:00 p.m. on the Friday preceding the election and 5:00 p.m. on the Monday preceding the election, qualified electors may request to vote in the manner prescribed by the board of supervisors of their respective county. Before voting pursuant to this subsection, an elector who experiences an emergency shall provide identification as prescribed in section 16-579 and shall sign a statement under penalty of perjury that states that the person is experiencing or experienced an emergency after [deleted: 5:00] 7:00 p.m. on the Friday immediately preceding the election and before 5:00 p.m. on the Monday immediately preceding the election that would prevent the person from voting at the polls. Signed statements received pursuant to this subsection are not subject to inspection pursuant to title 39, chapter 1, article 2. For the purposes of this subsection, "emergency" means any unforeseen circumstances that would prevent the elector from voting at the polls. I. Notwithstanding section 16-579, subsection A, paragraph 2, for any voting pursuant to subsection H of this section, the county recorder or other officer in charge of elections may allow a qualified elector to update the elector's voter registration information as provided for in the secretary of state's instructions and procedures manual adopted pursuant to section 16-452. J. A candidate, political committee or other organization may distribute early ballot request forms to voters. If the early ballot request forms include a printed address for return, the addressee shall be the political subdivision that will conduct the election. Failure to use the political subdivision as the return addressee is punishable by a civil penalty of up to three times the cost of the production and distribution of the request. K. All original and completed early ballot request forms that are received by a candidate, political committee or other organization shall be submitted within six business days after receipt by a candidate, political committee or other organization or eleven days before the election day, whichever is earlier, to the political subdivision that will conduct the election. Any person, political committee or other organization that fails to submit a completed early ballot request form within the prescribed time is subject to a civil penalty of up to $25 per day for each completed form withheld from submittal. Any person who knowingly fails to submit a completed early ballot request form before the submission deadline for the election immediately following the completion of the form is guilty of a class 6 felony. L. Except for a voter who is on the active early voting list prescribed by section 16-544, a voter who requests a onetime early ballot pursuant to this section [deleted: 16-542] or for an election conducted pursuant to section 16-409 or article 8.1 of this chapter, a county recorder, city or town clerk or other election officer may not deliver or mail an early ballot to a person who has not requested an early ballot for that election. An election officer who knowingly violates this subsection is guilty of a class 5 felony. END_STATUTE Sec. 5. Section 16-547, Arizona Revised Statutes, is amended to read: START_STATUTE 16-547. Ballot affidavit; form A. The early ballot shall be accompanied by an envelope bearing on the front the name, official title and post office address of the recorder or other officer in charge of elections and on the other side a printed affidavit in substantially the following form: I declare the following under penalty of perjury: I am a registered voter in ___________ county Arizona, I have not voted and will not vote in this election in any other county or state, I understand that knowingly voting more than once in any election is a class 5 felony and I voted the enclosed ballot and signed this affidavit personally unless noted below. If the voter was assisted by another person in marking the ballot, complete the following: I declare the following under penalty of perjury: At the registered voter's request I assisted the voter identified in this affidavit with marking the voter's ballot, I marked the ballot as directly instructed by the voter, I provided the assistance because the voter was physically unable to mark the ballot solely due to illness, injury or physical limitation and I understand that there is no power of attorney for voting and that the voter must be able to make the voter's selection even if the voter cannot physically mark the ballot. Name of voter assistant: _____________________________ Address of voter assistant: __________________________ B. The face of each envelope in which a ballot is sent to a federal postcard applicant or in which a ballot is returned by the applicant to the recorder or other officer in charge of elections shall be in the form prescribed in accordance with the uniformed and overseas citizens absentee voting act (P.L. 99-410; 52 United States Code section 20301). Otherwise, the envelopes shall be the same as those used to send ballots to, or receive ballots from, other early voters. C. The officer charged by law with the duty of preparing ballots at any election shall ensure that the early ballot is sent in an envelope that states substantially the following: If the addressee does not reside at this address, mark the unopened envelope "return to sender" and deposit it in the United States mail. D. The county recorder or other officer in charge of elections shall supply printed instructions to early voters that direct them to sign the affidavit, mark the ballot and return both in the enclosed self-addressed envelope that complies with section 16-545 , [deleted: .] and: 1. Through 2025, the instructions shall include the following statement: In order to be valid and counted, the ballot and mail affidavit must be delivered to the office of the county recorder or other officer in charge of elections or may be deposited at any polling place in the county not later than 7:00 p.m. on election day. The ballot will not be counted without the voter's signature on the envelope. (WARNING — It is a felony to offer or receive any compensation for a ballot.) 2. Beginning in 2026, the instructions shall include the following statement: In order to be valid and COUNTED, the mail affidavit that contains the mail ballot MUST have the voter's signature on the envelope and must be returned to the OFFICE of the county recorder by any one of the following methods: ( a ) Delivering it to the office of the COUNTY RECORDER or other officer in CHARGE of elections not later than 7:00 p.m. on election day. ( b ) Depositing it at any polling place in the county not later than 7:00 P.m. on election day. ( c ) Bringing the ballot to any polling place in the county not later than 7:00 p.m. on election day and choosing to present valid identification that complies with section 16-579, subsection A, paragraph 1, Arizona Revised Statutes. (WARNING — It is a felony to offer or receive any compensation for a ballot.) E. The printed instructions prescribed by subsection D of this section shall also include the following information regarding section 16-1005, subsections H and I in substantially the following form: A person may only handle or return their own ballot or the ballot of family members, household members or persons for whom they are a caregiver. It is unlawful under section 16-1005 to handle or return the ballot of any other person. END_STATUTE Sec. 6. Section 16-550, Arizona Revised Statutes, is amended to read: START_STATUTE 16-550. Receipt of voter's ballot; cure period; tracking system A. Except for early ballots tabulated as prescribed in section 16-579.02 or, beginning in 2026, received at a voting location after a voter's identification is CONFIRMED as prescribed by section 16-579, subsection A, paragraph 4 , on receipt of the envelope containing the early ballot and the mail ballot affidavit, the county recorder or other officer in charge of elections shall compare the [deleted: signatures thereon] signature on the envelope with the signature of the elector on the elector's registration record as prescribed by section 16-550.01 . If the signature is inconsistent with the elector's signature on the elector's registration record, the county recorder or other officer in charge of elections shall make reasonable efforts to contact the voter, advise the voter of the inconsistent signature and allow the voter to correct or the county to confirm the inconsistent signature. The county recorder or other officer in charge of elections shall allow signatures to be corrected not later than the fifth business day after a primary, general or special election that includes a federal office or the third business day after any other election. If the election is a primary, general or special election that includes a federal office, in addition to the office's regular business hours, the county recorder's and city or town CLERKS' offices shall be open during regular business hours to allow for curing signatures during the friday and weekend before and the friday and weekend after the election. If the signature is missing, the county recorder or other officer in charge of elections shall make reasonable efforts to contact the elector, advise the elector of the missing signature and allow the elector to add the elector's signature not later than 7:00 p.m. on election day. If satisfied that the signatures correspond, the recorder or other officer in charge of elections shall hold the envelope containing the early ballot and the completed mail affidavit unopened in accordance with the rules of the secretary of state. signatures that cannot be verified pursuant to section 16-550.01 or cured pursuant to this section shall be rejected. Beginning with the first missing or mismatched signature that is identified after the period of early voting begins through the Monday immediately preceding the election, the county recorder or other officer in charge of elections shall submit daily to the political parties that are qualified for continued REPRESENTATION on the state ballot an updated list of all voters whose signatures are missing or inconsistent with the voter's signature on the voter's registration record. Beginning on the Wednesday immediately following the election through the end of the signature cure period after a primary, general or special election that includes a federal office, or the third business day after the election for any other election, the county recorder or other officer in charge of elections shall submit daily to the political parties that are qualified for continued representation on the state ballot an updated list of all voters whose signatures are inconsistent with the voter's signature on the voter's registration record and all voters who voted with a conditional provisional ballot. This list of voters whose signatures require curing shall include for those voters all voter information that is provided to the political parties that are qualified for continued REPRESENTATION on the state ballot as prescribed by section 16-168. B. The recorder or other officer in charge of elections shall thereafter safely keep the mail ballot affidavits and early ballots in the recorder's or other officer's office and may deliver them for tallying pursuant to section 16-551. [deleted: Tallying] C. Processing and tabulation of individual ballots may begin immediately after the envelope and completed mail ballot affidavit are processed pursuant to this section and delivered to the early election board and shall continue without delay until completed . Until election day, the early election board and the county recorder or other officer in charge of elections shall: 1. Not access an aggregated complete results file of early voting and vote by mail ballots that were processed and tabulated by the end of the early voting period. 2. Not produce for internal or external use an aggregated results report or associated files of complete results. 3. Only produce a partial results report or associated files if it is part of the internal preparation for the hand count pursuant to section 16-602 or for the logic and accuracy testing required pursuant to section 16-449. 4. Not PUBLICLY release complete or partial results, whether for internal or external use, until all precincts have reported or one hour after the closing of the polls on election day, whichever is earlier. D. The county recorder or other officer in charge of elections shall post on its website within forty-eight hours AFTER all ballot tabulation is complete all system log files and other SIMILAR files from the election management system that verify compliance with subsection C of this section. [deleted: C.] E. The county recorder shall send a list of all voters who were issued early ballots to the election board of the precinct in which the voter is registered. [deleted: D.] F. For a county that uses early ballots, the county recorder or other officer in charge of elections shall provide an early ballot tracking system that indicates whether the voter's early ballot has been received and whether the early ballot has been verified and sent to be tabulated or rejected. The county recorder or other officer in charge of elections shall provide voters with access to the early ballot tracking system on the county's website. [deleted: E.] G. This section does not apply to: 1. A special taxing district that is authorized pursuant to section 16-191 to conduct its own elections. 2. A special district mail ballot election that is conducted pursuant to article 8.1 of this chapter. END_STATUTE Sec. 7. Title 16, chapter 4, article 8, Arizona Revised Statutes, is amended by adding section 16-550.01, to read: START_STATUTE 16-550.01. Signature verification; procedures; exemption; intent; definitions A. Except for early ballots tabulated as prescribed in section 16-579.02, on receipt of the envelope containing the early ballot and the ballot affidavit, the county recorder or other officer in charge of elections shall conduct signature verification as prescribed by this section. B. The evaluator shall examine all the broad characteristics of the signature. If the broad characteristics of the signature on the ballot affidavit are clearly consistent with the broad characteristics of the voter's signature in the voter's registration record, the evaluator may accept the signature as valid. C. If the evaluator finds discrepancies between the signature on the ballot affidavit and the voter's signature in the voter's registration record, the evaluator shall examine the local characteristics of the signature. If the local characteristics of the signature on the ballot affidavit are clearly consistent with the local characteristics of the voter's signature in the voter's registration record, the evaluator may accept the signature as valid. D. If the evaluator finds a combination of broad and local characteristic differences between the signature on the ballot affidavit and the voter's signature in the voter's registration record, the evaluator shall denote the signature for a second review that shall be conducted by an evaluator using the same standards prescribed by this section. E. Electronic signatures shall be evaluated as prescribed by this section, except that electronic signatures that use a typed font shall be rejected. F. The legislature intends that the illustrations of broad and local characteristics in the 2020 secretary of state's signature verification guide be used as reference. G. For the purposes of this section: 1. "Broad characteristics" means all of the following: ( a ) The type of writing. ( b ) The speed of writing. ( c ) Overall spacing. ( d ) Overall size and proportions. ( e ) Position of the signature. ( f ) Spelling and punctuation. 2. "Evaluator" means the individual who is designated by the county recorder or officer in charge of elections and who conducts signature verification. 3. "Local characteristics" means all of the following: ( a ) Internal spacing. ( b ) The size or proportions of a letter or letter combination. ( c ) Curves, loops and cross points. ( d ) The presence or absence of pen lifts. ( e ) Beginning and ending strokes. 4. "Signature verification" means the process of manually comparing the signature on a voter's affidavit envelope or ballot affidavit with the voter's signature in the voter's registration record. H. The legislature intends by this section to codify procedures based on the 2020 secretary of state signature verification guide, provided that in the event of any conflict between the guide and this section, this section controls. This section is not intended to modify the grounds on which a party-appointed challenger may challenge an early ballot. This section does not require signature evaluators to examine broad or local characteristics one at a time. This section is not intended to require an exact match. END_STATUTE Sec. 8. Section 16-551, Arizona Revised Statutes, is amended to read: START_STATUTE 16-551. Early election board; violation; classification A. The board of supervisors or the governing body of the political subdivision shall appoint one or more early election boards to serve at places to be designated by the board of supervisors or the governing body to canvass and tally early election ballots. Members of early election boards shall be selected in accordance with the provisions for selecting members of regular election boards as provided in section 16-531. B. If an electronic voting system is in use for early voting, the early election board shall consist of at least one inspector and two judges who shall perform the processing requirements in accordance with the rules issued by the secretary of state. The inspector and judges shall be appointed in the same manner by party as provided in section 16-531. C. All early ballots received by the county recorder or other officer in charge of elections before 7:00 p.m. on election day and the original mail ballot affidavit of the voter shall be delivered to the early election boards for processing as provided in the rules of the secretary of state. Beginning in 2026, all early ballots that are delivered by a voter to a voting location without presenting identification that complies with section 16-579, subsection A, paragraph 1 must be signature verified. The office of the county recorder or other officer in charge of elections shall remain open until 7:00 p.m. on election day for the purpose of receiving early ballots. Partial or complete tallies of the early election board shall not be released or divulged before all precincts have reported or one hour after the closing of the polls on election day, whichever occurs first. Any person who unlawfully releases information regarding vote tallies or who possesses a tally sheet or summary without authorization from the recorder or officer in charge of elections is guilty of a class 6 felony. D. [deleted: If practicable,] The county recorder or other officer in charge of elections shall count the number of early ballots that are returned at voting locations on election day and shall post on its website those totals with the last unofficial results that are released on election night pursuant to section 16-622. Beginning with the day following the election, the county recorder or other officer in charge of elections shall enter into the county's ballot tracking system, if established, early ballots that were returned at the voting location on election day. E. The necessary printed blanks for poll lists, tally lists, lists of voters, ballots, oaths and returns, together with envelopes in which to enclose the returns, shall be furnished by the board of supervisors or the governing body of the political subdivision to the early election board for each election precinct at the expense of the county or the political subdivision. END_STATUTE Sec. 9. Section 16-552, Arizona Revised Statutes, is amended to read: START_STATUTE 16-552. Early ballots; processing; challenges A. In a jurisdiction that uses optical scan ballots, the officer in charge of elections may use the procedure prescribed by this section or may request approval from the secretary of state for a different method for processing early ballots. The request shall be made in writing at least ninety days before the election for which the procedure is intended to be used. After the election official has confirmed with the secretary of state that all election equipment passes the logic and accuracy test, the election official may begin to count early ballots. No early ballot results may be released except as prescribed by section 16-551. B. The early election board shall check the voter's mail ballot affidavit on the envelope containing the early ballot. If it is found to be sufficient, the vote shall be allowed. If the mail ballot affidavit is insufficient, the vote shall not be allowed. Beginning in 2026, for an early ballot that is received and verified as prescribed by section 16-579, subsection A, paragraph 4, additional signature verification is not required. C. The county chairman of each political party represented on the ballot, by written appointment addressed to the early election board, may designate party representatives and alternates to act as early ballot challengers for the party. No party may have more than the number of such representatives or alternates that were mutually agreed on by each political party to be present at one time. If such agreement cannot be reached, the number of representatives shall be limited to one for each political party. D. An early ballot may be challenged on any grounds set forth in section 16-591. All challenges shall be made in writing with a brief statement of the grounds before the early ballot is placed in the ballot box. A record of all challenges and resulting proceedings shall be kept in substantially the same manner as provided in section 16-594. If an early ballot is challenged, it shall be set aside and retained in the possession of the early election board or other officer in charge of early ballot processing until a time that the early election board sets for determination of the challenge, subject to the procedure in subsection E of this section, at which time the early election board shall hear the grounds for the challenge and shall decide what disposition shall be made of the early ballot by majority vote. If the early ballot is not allowed, it shall be handled pursuant to subsection G of this section. E. Within twenty-four hours of receipt of a challenge, the early election board or other officer in charge of early ballot processing shall mail, by first class mail, a notice of the challenge including a copy of the written challenge, and also including the time and place at which the voter may appear to defend the challenge, to the voter at the mailing address shown on the request for an early ballot or, if none was provided, to the mailing address shown on the registration rolls. Notice shall also be mailed to the challenger at the address listed on the written challenge and provided to the county chairman of each political party represented on the ballot. The board shall meet to determine the challenge at the time specified by the notice but, in any event, not earlier than ninety-six hours after the notice is mailed, or forty-eight hours if the notifying party chooses to deliver the notice by overnight or hand delivery, and not later than 5:00 p.m. on the Monday following the election. The board shall provide the voter with an informal opportunity to make, or to submit, brief statements regarding the challenge. The board may decline to permit comments, either in person or in writing, by anyone other than the voter, the challenger and the party representatives. The burden of proof is on the challenger to show why the voter should not be permitted to vote. The fact that the voter fails to appear shall not be deemed to be an admission of the validity of the challenge. The early election board or other officer in charge of early ballot processing is not required to provide the notices described in this subsection if the written challenge fails to set forth at least one of the grounds listed in section 16-591 as a basis for the challenge. In that event, the challenge will be summarily rejected at the meeting of the board. Except for election contests pursuant to section 16-672, the board's decision is final and may not be appealed. F. If the vote is allowed, the board shall open the envelope containing the ballot in such a manner that the mail ballot affidavit thereon is not destroyed, take out the ballot without unfolding it or permitting it to be opened or examined and show by the records of the election that the elector has voted. G. If the vote is not allowed, the mail ballot affidavit envelope containing the early ballot shall not be opened and the board shall mark across the face of such envelope the grounds for rejection. The mail ballot affidavit envelope and its contents shall then be deposited with the opened mail ballot affidavit envelopes and shall be preserved with official returns. If the voter does not enter an appearance, the board shall send the voter a notice stating whether the early ballot was disallowed and, if disallowed, providing the grounds for the determination. The notice shall be mailed by first class mail to the voter's mailing address as shown on the registration rolls within three days after the board's determination. H. Party representatives and alternates may be appointed as provided in subsection C of this section to be present and to challenge the verification of questioned ballots pursuant to section 16-584 on any grounds [deleted: permitted] allowed by this section. Questioned ballots that are challenged shall be presented to the early election board for decision under the provisions of this section. END_STATUTE Sec. 10. Section 16-579, Arizona Revised Statutes, is amended to read: START_STATUTE 16-579. Procedure for obtaining ballot by elector A. Every qualified elector, before receiving a ballot, shall announce the elector's name and place of residence in a clear, audible tone of voice to the election official in charge of the signature roster or present the elector's name and residence in writing. The election official in charge of the signature roster shall comply with the following and the qualified elector shall be allowed within the voting area : 1. The elector shall present any of the following: (a) A valid form of identification that bears the photograph, name and address of the elector that reasonably appear to be the same as the name and address in the precinct register, including an Arizona driver license, an Arizona nonoperating identification license, a tribal enrollment card or other form of tribal identification or a United States federal, state or local government issued identification. Identification is deemed valid unless it can be determined on its face that it has expired. (b) Two different items that contain the name and address of the elector that reasonably appear to be the same as the name and address in the precinct register, including a utility bill, a bank or credit union statement that is dated within ninety days of the date of the election, a valid Arizona vehicle registration, an Arizona vehicle insurance card, an Indian census card, tribal enrollment card or other form of tribal identification, a property tax statement, a recorder's certificate, a voter registration card, a valid United States federal, state or local government issued identification or any mailing that is labeled as "official election material". Identification is deemed valid unless it can be determined on its face that it has expired. (c) A valid form of identification that bears the photograph, name and address of the elector except that if the address on the identification does not reasonably appear to be the same as the address in the precinct register or the identification is a valid United States military identification card or a valid United States passport and does not bear an address, the identification must be accompanied by one of the items listed in subdivision (b) of this paragraph. 2. If the elector does not present identification that complies with paragraph 1 of this subsection, the elector is only eligible to vote a provisional ballot as prescribed by section 16-584 or a conditional provisional ballot as provided for in the secretary of state's instruction and procedures manual adopted pursuant to section 16-452. 3. Through 2025, if the voter surrenders the early ballot to the precinct inspector and the voter is not otherwise required to be issued a provisional ballot, the voter shall be issued a standard ballot after presenting identification pursuant to this subsection. The precinct inspector shall retain the surrendered early ballot, unopened in its affidavit envelope. 4. Beginning in 2026, aT ANY VOTING LOCATION THE VOTER MAY CHOOSE TO PROVIDE IDENTIFICATION WHEN PRESENTING THE VOTER'S MAILED EARLY BALLOT, AND IF SO THE ELECTION OFFICIAL SHALL: ( a ) REQUIRE THE VOTER TO PRESENT IDENTIFICATION THAT COMPLIES WITH PARAGRAPH 1 OF THIS SUBSECTION. ( b ) CONFIRM THAT THE NAME AND ADDRESS ON THE IDENTIFICATION REASONABLY APPEAR TO BE THE SAME NAME AND ADDRESS SHOWN ON THE VOTER'S REGISTRATION RECORD. ( c ) Stamp the signed affidavit with a stamp that reads "ID verified" and place the stamped affidavit that contains the early ballot in a secured ballot box that is labeled for early ballots. THE stamped AFFIDAVIT ENVELOPE IS NOT REQUIRED TO BE REVIEWED AT THE VOTING LOCATION, THE VOTER'S EARLY BALLOT IS DEEMED READY FOR TABULATING AND ADDITIONAL SIGNATURE VERIFICATION OF THE COMPLETED AFFIDAVIT ENVELOPE AS PRESCRIBED BY SECTION 16-550 IS NOT REQUIRED. ( d ) MAINTAIN A TALLY OF THE NUMBER OF BALLOTS THAT HAVE BEEN DEPOSITED IN THE SECURED BALLOT BOX AND SIGN AN AFFIDAVIT THAT INCLUDES THE ELECTION OFFICIAL'S NAME, THE POLLING LOCATION, THE TIME AND DATE, THE NUMBER OF EARLY BALLOTS DEPOSITED ACCORDING TO THE TALLY MAINTAINED BY THE ELECTION OFFICIAL AND A STATEMENT SUFFICIENT TO RECORD AND MAINTAIN THE CHAIN OF CUSTODY FOR THOSE BALLOTS. B. Any qualified elector who is listed as having applied for an early ballot but who states that the elector has not voted and will not vote an early ballot for this election or surrenders the early ballot to the precinct inspector on election day shall be allowed to vote pursuant to the procedure set forth in section 16-584, except that for elections conducted using an electronic pollbook or similar system with continuous voter usage updates, the following apply: 1. If the electronic pollbook or other system indicates that the voter's early ballot has not been returned or accepted by the county recorder and the voter is not otherwise required to be issued a provisional ballot, the voter may be issued a standard ballot after presenting identification pursuant to subsection A of this section. 2. If the electronic pollbook or other system indicates that the voter's early ballot has been received or accepted by the county recorder, the voter may not be issued a standard ballot and may only be issued a provisional ballot as prescribed in section 16-584. C. Each qualified elector's name shall be numbered consecutively by the clerks and in the order of applications for ballots. The judge shall give the qualified elector only one ballot and a ballot privacy folder, and the elector's name shall be immediately checked on the precinct register. Notwithstanding any provision of this subsection, an elector shall not be required to accept or use a ballot privacy folder. D. For precincts in which a paper signature roster is used, each qualified elector shall sign the elector's name in the signature roster before receiving a ballot, but an inspector or judge may sign the roster for an elector who is unable to sign because of physical disability, and in that event the name of the elector shall be written with red ink, and no attestation or other proof shall be necessary. The provisions of this subsection relating to signing the signature roster [deleted: shall] do not apply to electors casting a ballot using early voting procedures. E. For precincts in which an electronic poll book system is used, each qualified elector shall sign the elector's name as prescribed in the instructions and procedures manual adopted by the secretary of state pursuant to section 16-452 before receiving a ballot, but an inspector or judge may sign the roster for an elector who is unable to sign because of physical disability, and in that event the name of the elector shall be written with the inspector's or judge's attestation on the same signature line. F. A person offering to vote at a special district election for which no special district register has been supplied shall sign an affidavit stating the person's address and that the person resides within the district boundaries or proposed district boundaries and swearing that the person is a qualified elector and has not already voted at the election being held. END_STATUTE Sec. 11. Section 16-584, Arizona Revised Statutes, is amended to read: START_STATUTE 16-584. Qualified elector not on precinct register; recorder's certificate; verified ballot; procedure A. A qualified elector whose name is not on the precinct register and who presents a certificate from the county recorder showing that the elector is entitled by law to vote in the precinct shall be entered on the signature roster on the blank following the last printed name and shall be given the next consecutive register number, and the qualified elector shall sign in the space provided. B. A qualified elector whose name is not on the precinct register, on presentation of identification verifying the identity of the elector that includes the voter's given name and surname and the complete residence address that is verified by the election board to be in the precinct or on signing an affirmation that states that the elector is a registered voter in that jurisdiction and is eligible to vote in that jurisdiction, shall be allowed to vote a provisional ballot. C. If a voter has moved to a new address within the county and has not notified the county recorder of the change of address before the date of an election, the voter shall be [deleted: permitted] allowed to correct the voting records for purposes of voting in future elections at the appropriate polling place for the voter's new address. The voter shall be [deleted: permitted] allowed to vote a provisional ballot. The voter shall present a form of identification that includes the voter's given name and surname and the voter's complete residence address. The residence address must be within the precinct in which the voter is attempting to vote, and the voter shall affirm in writing that the voter is registered in that jurisdiction and is eligible to vote in that jurisdiction. D. On completion of the ballot, the election official shall place the ballot in a provisional ballot envelope and shall deposit the envelope in the ballot box. Within [deleted: ten] five calendar days after a primary, general or special election that includes an election for a federal office and within [deleted: five] three business days after any other election or [deleted: no] not later than the time at which challenged early voting ballots are resolved, the signature shall be compared to the precinct signature roster of the former precinct where the voter was registered. If the voter's name is not signed on the roster and if there is no indication that the voter voted an early ballot, the provisional ballot envelope shall be opened and the ballot shall be counted. If there is information showing the person did vote, the provisional ballot shall remain unopened and shall not be counted. When provisional ballots are confirmed for counting, the county recorder shall use the information supplied on the provisional ballot envelope to correct the address record of the voter. E. When a voter is allowed to vote a provisional ballot, the elector's name shall be entered on a separate signature roster page at the end of the signature roster. Voters' names shall be numbered consecutively beginning with the number V-1. The elector shall sign in the space provided. The ballot shall be placed in a separate envelope, the outside of which shall contain the precinct name or number, a sworn or attested statement of the elector that the elector resides in the precinct, is eligible to vote in the election and has not previously voted in the election, the signature of the elector and the voter registration number of the elector, if available. The ballot shall be verified for proper registration of the elector by the county recorder before being counted. The verification shall be made by the county recorder within ten calendar days after a general election that includes an election for a federal office and within five business days following any other election. Verified ballots shall be counted by depositing the ballot in the ballot box and showing on the records of the election that the elector has voted. If registration is not verified the ballot shall remain unopened and shall be retained in the same manner as voted ballots. F. For any person who votes a provisional ballot, the county recorder or other officer in charge of elections shall provide for a method of notifying the provisional ballot voter at no cost to the voter whether the voter's ballot was verified and counted and, if not counted, the reason for not counting the ballot. The notification may be in the form of notice by mail to the voter, establishment of a [deleted: toll free] toll-free telephone number, internet access or other similar method to allow the voter to have access to this information. The method of notification shall provide reasonable restrictions that are designed to limit transmittal of the information only to the voter. END_STATUTE Sec. 12. Section 16-622, Arizona Revised Statutes, is amended to read: START_STATUTE 16-622. Official canvass; unofficial results A. At any time following the close of the polls, except as provided in section 16-550 and section 16-551, subsection C, unofficial returns may be released during the counting of the ballots by vote tabulating equipment, and [deleted: upon] on completion of the count the unofficial results shall be open to the public. The result printed by the vote tabulating equipment, to which have been added write-in and early votes, [deleted: shall,] when certified by the board of supervisors or other officer in charge, shall constitute the official canvass of each precinct or election district. B. In any election for a federal office, a statewide office or a member of the legislature or in any election for a statewide ballot measure, all unofficial returns that are released during the counting of the ballots and all unofficial results that are open to the public shall when released to the public be transmitted by telephone, by [deleted: telefacsimile] fax or by other electronic means to the secretary of state. END_STATUTE Sec. 13. Section 16-642, Arizona Revised Statutes, is amended to read: START_STATUTE 16-642. Canvass of election; postponements A. The governing body holding an election shall meet and canvass the election [deleted: not less than six days nor more than twenty days following the election] as follows: 1. The governing board of a county shall meet and canvass as follows: ( a ) For the primary election, not later than the second Monday after the election. ( b ) For the general election, not later than the third Thursday after the election. 2. The secretary of state shall canvass as follows: ( a ) For the primary election, not later than the third Thursday after the election. ( b ) For the general election, not later than the third Monday after the election . 3. The governing body of a city, town or special district shall meet and canvass the election not less than six days and not more than twenty days FOLLOWING the election. B. The governing body of a special district as defined in title 48 shall present to the board of supervisors a certified copy of the official canvass of the election at the next regularly scheduled meeting of the board of supervisors. For purposes of contesting a special district election as described in section 16-673, the canvass is not complete until the presentation to the board of supervisors is made. C. If, at the time of the meeting of the governing body, the returns from any polling place in the election district where the polls were opened and an election held are found to be missing, the canvass shall be postponed from day to day until all the returns are received or until six postponements have been had. The subsection does not apply to the county board of supervisors' canvass of the primary and general election. END_STATUTE Sec. 14. Section 16-645, Arizona Revised Statutes, is amended to read: START_STATUTE 16-645. Canvass and return of precinct vote; declaring nominee of party; certificate of nomination; write-in candidates A. When the board of supervisors, or the governing body of a city or town, has completed its canvass of precinct returns, the person having the largest number of votes, or if more than one candidate is necessary, those candidates to the required number who have received the largest number of votes for the nomination for an office in the political party of which the person was set forth on the ballot as a candidate for the nomination, shall be declared the nominee of the party for that office and shall be given a certificate of nomination for that office by the board or governing body, which shall entitle the person to have the person's name placed on the official ballot at the ensuing election as the nominee of the party for the office. When canvassing write-in votes the apparent intent of the voter shall be taken into consideration to the extent possible and the standard prescribed for federal write-in candidates in section 16-543.02, subsection C applies. B. The board of supervisors shall deliver the official canvass by electronic means to the secretary of state within [deleted: fourteen] thirteen calendar days after the primary election, and the secretary of state shall on or before the third [deleted: Monday] Thursday following the primary election canvass the return and issue a letter declaring nomination as provided in this section to the nominees who filed nominating petitions and papers with the secretary of state pursuant to section 16-311, subsection D. For any partisan primary election, the governing body or officer in charge of elections shall prepare and transmit to the secretary of state along with the official canvass the total by party of partisan ballots selected in that primary election by voters who registered as no party preference, as independents or as members of a political party that is not qualified for representation on the ballot. C. A certificate of election shall not be issued to a write-in candidate for precinct committeeman or a write-in candidate for a nonpartisan office unless the candidate receives a number of votes equivalent to at least the same number of signatures required by section 16-322 for nominating petitions for the same office. D. Except as provided in subsection C of this section, a letter declaring nomination shall not be issued to a write-in candidate of a party that has not qualified for continued representation on the official ballot pursuant to section 16-804 unless the candidate receives a plurality of the votes of the party for the office for which the candidate is a candidate. E. Except as provided by subsection C of this section, a letter declaring nomination shall not be issued to a write-in candidate of a party qualified for continued representation on the official ballot unless the candidate receives a number of votes equivalent to at least the same number of signatures required by section 16-322 for nominating petitions for the same office. F. A certificate of election shall not be issued to presidential electors who are pledged to a write-in candidate for president unless that candidate received the highest number of votes cast for the office of president. END_STATUTE Sec. 15. Section 16-646, Arizona Revised Statutes, is amended to read: START_STATUTE 16-646. Statement, contents and mailing of official canvass A. When the result of the canvass is determined, a statement, known and designated as the official canvass, shall be entered on the official record of the election district that shall show: 1. The number of ballots cast in each precinct and in the county. 2. The number of ballots rejected in each precinct and in the county. 3. The titles of the offices voted for and the names of the persons, together with the party designation, if any, of each person voted for to fill the offices. 4. The number of votes by precincts and county received by each candidate. 5. For each candidate race in each political subdivision prescribed by section 16-204.01, the number of ballots cast and the number of active registered voters in each political subdivision and portion of a political subdivision for which a candidate may be elected. 6. The numbers and a brief title of each proposed constitutional amendment and each initiated or referred measure voted on. 7. The number of votes by precincts and county for and against such proposed amendment or measure. B. The certified permanent copy of the official canvass for all offices and ballot measures, except offices and ballot measures in a city or town election and nonpartisan election returns, shall be mailed immediately to the secretary of state who shall maintain and preserve it as a permanent public record. C. The board of supervisors shall first mail with a postmark or other similar date and time indicator, then deliver electronically a copy of the official canvass for all offices and ballot measures in the primary and general elections to the secretary of state in a uniform electronic computer media format that shall be agreed on between the secretary of state and all county election officials. The uniform format shall be designed to facilitate the computer analysis of election results for offices and ballot measures that are statewide or are common to more than one county. The electronic copy of the official canvass from the board of supervisors is sufficient for the secretary of state to conduct and issue the statewide canvass if the electronic copy includes a scan or other similar evidence that the paper official canvass was mailed before the electronic version was sent. D. The certified permanent copy of the official canvass for all offices and ballot measures in a city or town election shall be filed with the appropriate city or town clerk, or in a special district election with the clerk of the board of supervisors, who shall maintain and preserve it as a permanent public record. END_STATUTE Sec. 16. Section 16-648, Arizona Revised Statutes, is amended to read: START_STATUTE 16-648. Canvass for state offices, amendments and measures A. On the [deleted: fourth] third Monday following a general election, the secretary of state, in the presence of the governor and the attorney general, shall canvass all offices for which the nominees filed nominating petitions and papers with the secretary of state pursuant to section 16-311, subsection E. B. The secretary of state, in the presence of the governor and the chief justice of the supreme court, shall canvass all proposed constitutional amendments and initiated or referred measures, as shown by the electronic or certified copies of the official canvass received from the several counties, and forthwith certify the result to the governor. [deleted: C. If the official canvass of any county has not been received on the fourth Monday following the general election, the canvass shall be postponed from day to day, not to exceed thirty days from the date of the election, until canvasses from all counties are received.] END_STATUTE Sec. 17. Section 16-662, Arizona Revised Statutes, is amended to read: START_STATUTE 16-662. Certification to superior court of facts requiring recount When the canvass shows that a recount is required, the secretary of state , within twenty-four hours after the last county canvass or the last day for county canvasses prescribed by section 16-642, whichever is earlier, shall, in the case of an office to be filled by electors of the entire state, a congressional district, a legislative district or a subdivision of the state greater than a county, initiated or referred measures or proposals to amend the constitution, certify the facts requiring the recount to the superior court in Maricopa county. In the case of an office to be filled by the electors of a county or subdivision of a county or precinct, the board of supervisors of such county or in the case of an office to be filled by the electors of a city or town, the city or town council of that city or town shall certify the facts requiring a recount to the superior court in the county in which the canvass was conducted. END_STATUTE Sec. 18. Section 16-663, Arizona Revised Statutes, is amended to read: START_STATUTE 16-663. Recount of votes; method A. The superior court to which the facts requiring a recount are certified shall [deleted: forthwith] promptly make and enter an order requiring a recount of the votes cast for such office, measure or proposal. The recount shall be conducted in accordance with the laws pertaining to contests of elections. B. [deleted: When the court orders] A court-ordered recount of votes [deleted: which] that were cast and tabulated on electronic voting equipment[deleted: , such recount] shall be pursuant to section 16-664. [deleted: On completion of] while the recount is being conducted , and for legislative, statewide and federal candidate races only, the county [deleted: chairmen] chairpersons of the political parties entitled to continued representation on the ballot or the [deleted: chairman's] chairperson's designee shall select at random without the use of a computer five [deleted: per cent] percent of the precincts for the recounted race for a hand count, and if the results of that hand count when compared to the electronic tabulation of that same race are less than the designated margins calculated pursuant to section 16-602, the recount is complete and the electronic tabulation is the official result. If the hand count results in a difference that is equal to or greater than the designated margin for that race, the [deleted: procedure] procedures established in section 16-602, subsections C, D, E and F [deleted: applies] APPLY . The hand count conducted pursuant to this section May begin before the machine tabulation of ballots for the court-ordered recount is complete. END_STATUTE Sec. 19. Section 16-664, Arizona Revised Statutes, is amended to read: START_STATUTE 16-664. Recount of votes by automatic tabulating system A. In the event of a court-ordered recount of votes that were cast and tabulated on electronic voting equipment for a state primary, state general or state special election, the secretary of state shall order the ballots recounted on an automatic tabulating system to be furnished and programmed under the supervision of the secretary of state. In the event of a court-ordered recount for elections other than for the office of supervisor, the secretary of state may designate the county board of supervisors to perform the duties assigned to the secretary of state. B. If the office of secretary of state is contested, the governor shall order the ballots recounted on an automatic tabulating system to be furnished and programmed under the supervision of the governor. C. The programs to be used in the recount of votes pursuant to this section shall differ from the programs prescribed by section 16-445 and used in the initial tabulation of the votes. D. The secretary of state shall conduct logic and accuracy testing on the automated tabulating system to be used in the recount of votes not more than two calendar days after the court orders a recount. Each team that is conducting a logic and accuracy test shall be supervised by a certified election officer. A person is not eligible to serve as contract staff for logic and accuracy testing on the automated tabulating system to be used in a recount of votes if that person has been affiliated with or received any income in the preceding three years from a voting system vendor for a voting system that is used in that county. END_STATUTE Sec. 20. Primary election date 2024 Notwithstanding section 16-204, Arizona Revised Statutes, as amended by this act, and any other law, the 2024 primary election shall be held on July 30, 2024. Sec. 21. 2024 primary election; nomination petition forms; local initiative petition forms; previous primary election date A. A person who desires to become a candidate at the 2024 primary election, who collects signatures on a nomination petition form before the effective date of this act and who has used a petition form that includes the former primary election date of August 6, 2024 may lawfully submit those signatures for the 2024 primary election to be held on July 30, 2024. Signatures that are collected with the August 6, 2024 primary election date, that are submitted as prescribed in this subsection and that otherwise comply with the requirements provided by law are deemed to be as valid as signatures collected on a nomination petition form that complies with the newly designated primary election date of July 30, 2024 and shall not be ruled invalid due solely to the changed date of the primary election. B. Any city, town or county initiative petition that is circulated before the effective date of this act and that is on a petition form that includes the former 2024 primary election date of August 6, 2024 may lawfully submit those petitions and signatures for the primary election to be held on July 30, 2024. Signatures that are collected with the August 6, 2024 primary election date, that are submitted as prescribed in this subsection and that otherwise comply with the requirements provided by law are deemed to be as valid as signatures collected on an initiative petition form that complies with the newly designated primary election date of July 30, 2024 and shall not be ruled invalid due solely to the changed date of the primary election. Sec. 22. 2024, 2025 and 2026 elections; signature cure period Notwithstanding section 16-550, subsection A, Arizona Revised Statutes, as amended by this act, and any other law, the following apply: 1. For a primary, general or special election in 2024, 2025 and 2026 that includes a federal office, the county recorder or other officer in charge of elections shall allow signatures to be corrected not later than the fifth calendar day after the election. 2. For all other elections in 2024, 2025 and 2026, the county recorder or other officer in charge of elections shall allow signatures to be corrected not later than the third business day after the election. Sec. 23. Emergency This act is an emergency measure that is necessary to preserve the public peace, health or safety and is operative immediately as provided by law. APPROVED BY THE GOVERNOR FEBRUARY 9, 2024. FILED IN THE OFFICE OF THE SECRETARY OF STATE FEBRUARY 9, 2024.

---
snapshot_id: b319bfa0-eeab-5418-b995-9c0443422a92
source_kind: public-record
url: https://apps.azleg.gov/BillStatus/BillOverview?SessionID=128&BillNumber=HB2785#house-third

House Third Reading - HB2785 primary; identification; canvass; recounts; ballots Action Date Action Vote 02/08/2024 Passed 56-2-0-0-2 Amended Emergency AGUILAR Y AUSTIN Y BIASIUCCI Y BLATTMAN Y BLISS Y CARBONE Y CARTER Y CHAPLIK Y CONTRERAS L Y CONTRERAS P Y COOK Y CREWS Y DE LOS SANTOS Y DIAZ Y DUNN Y GILLETTE Y GRANTHAM Y GRESS Y GRIFFIN Y GUTIERREZ Y HEAP Y HENDRIX Y HERNANDEZ A Y HERNANDEZ C Y HERNANDEZ L Y HERNANDEZ M Y HODGE Y JONES Y KOLODIN Y LIGUORI Y LIVINGSTON Y MARSHALL Y MARTINEZ Y MATHIS Y MCGARR Y MONTENEGRO Y NGUYEN Y ORTIZ Y PARKER B N PARKER J N PAWLIK Y PAYNE Y PEÑA Y PESHLAKAI Y PINGERELLI Y QUIÑONEZ Y SANDOVAL Y SCHWIEBERT Y SEAMAN Y SHAH V SMITH Y STAHL HAMILTON Y SUN V TERECH Y TRAVERS Y TSOSIE Y VILLEGAS Y WILLOUGHBY Y WILMETH Y TOMA Y [Vote detail dialog for HB2785 (2024) House Third Reading, saved by browser from apps.azleg.gov BillStatus on 2026-09-28.]

---
snapshot_id: 09b7ba91-cd3c-5e43-9543-38edf20f89e6
source_kind: public-record
url: https://apps.azleg.gov/BillStatus/BillOverview?SessionID=128&BillNumber=HB2785

Bill Status Inquiry. Bill History for HB2785. Short Title: primary; identification; canvass; recounts; ballots. Sponsors: Kolodin (Prime) Substitute Bill: HB2785 for SB1733 Governor Action 02/09/2024 Signed Chapter: 1 Emergency Chapter Version: House Engrossed [Bill overview for HB2785 (2024), saved by browser from apps.azleg.gov BillStatus on 2026-09-28.]