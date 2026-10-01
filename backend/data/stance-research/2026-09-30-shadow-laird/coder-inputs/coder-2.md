You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-30-shadow-laird/labels/coder-2.json. Write JSON only, matching
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
**Clarified 2026-09-30 (still 0.4 — no new variable or value; two existing rules spelled out):** V4.2
"Silence is not a clause" and "Ruling out the other rungs is not evidence", with register rows H13 and
H14. Both restate V4 `direction-only` and the CLAUDE.md tiebreaker rule; the version stays 0.4 so
existing gold keeps counting. The two gold items that prompted them are not named here, so they stay
certifiable: their coder labels were written before these lines existed.
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
- **Silence is not a clause** (gold round 5, 2026-09-30). When a rung's clause is a limit or its
  absence ("at every stage, with no time limit", "without exceptions"), the instrument must *say* it.
  A text that declares a right and names no limit has not said "no limit"; it has said nothing about
  limits, and other law may still set them. → `direction-only`.
- **Ruling out the other rungs is not evidence for the one left** (gold round 5, 2026-09-30). "Not
  rung 1 (nothing is required), not rung 3 (the law changes), so rung 2" establishes only a side. The
  remaining rung still needs its own clauses matched — a repeal that *permits* a programme does not
  "strengthen enforcement". This is the same fault as reaching for "the least extreme option the
  reasoning supports" (CLAUDE.md): a tiebreaker, not evidence. → `direction-only`, or
  `compound-partial` when the rung is compound and one clause is met.

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
| H13 | A declared right with no stated limit coded as the "no limit" rung | V4 `direction-only` | V4.2 "Silence is not a clause" | gold round 5 (item withheld; coded before this entry) |
| H14 | A chair reached by excluding every other rung, with the remaining rung's clause unmatched | BLANK `direction-only` / `compound-partial` | V4.2 "Ruling out the other rungs" | gold round 5 (item withheld; coded before this entry) |

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

politician_id: 178a41d4-42b5-4ffd-be06-d1059d54eacb  office_id: eaf4cad0-012a-48a6-8765-ca9020432782
John Laird — Senator, California (seated, level: state)
Current term: 2020-12-07 (precision: day) to present

## Topics (served ladder text — code against these words only)

### topic_key: climate-change
topic_id: f1e44d66-5d27-4b51-b54f-b7ace86f6a3c  served_revision_id: 5f1403f3-90b6-491f-ba54-3c8e46a5ae26
Question: How much should government do to expand clean energy?
  1. Require a shift to clean energy through mandates and firm deadlines.
  2. Fund clean energy with major subsidies, tax credits, and public investment.
  3. Speed up clean energy by cutting permitting red tape and upgrading the grid.
  4. Stay neutral on energy and let the market choose among all sources.
  5. End government subsidies and mandates for clean energy.

#### Annex

(no annex for this topic yet — apply the codebook alone)

## Sources

---
snapshot_id: 48806783-3894-5855-8a66-ed263f20f170
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202120220SB1020

Senate Bill No. 1020 CHAPTER 361 An act to amend Section 7921.505 of the Government Code, to amend Section 38561 of the Health and Safety Code, to amend Sections 454.53 and 583 of, and to add Sections 454.59 and 739.13 to, the Public Utilities Code, and to add Division 27.5 (commencing with Section 80400) to the Water Code, relating to public resources. [ Approved by Governor September 16, 2022. Filed with Secretary of State September 16, 2022. ] LEGISLATIVE COUNSEL'S DIGEST SB 1020, Laird. Clean Energy, Jobs, and Affordability Act of 2022. The California Global Warming Solutions Act of 2006 designates the State Air Resources Board as the state agency responsible for monitoring and regulating sources emitting greenhouse gases. The act requires the state board to prepare and approve a scoping plan for achieving the maximum technologically feasible and cost-effective reductions in greenhouse gas emissions and to update the scoping plan at least once every 5 years. The act requires the state board to conduct a series of public workshops to give interested parties an opportunity to comment on the plan and requires a portion of those workshops to be conducted in regions of the state that have the most significant exposure to pollutants. The act specifically includes as regions for these workshops communities with minority populations, communities with low-income populations, or both. This bill would instead include as regions for these workshops federal extreme nonattainment areas that have communities with minority populations, communities with low-income populations, or both. Under existing law, it is the policy of the state that eligible renewable energy resources and zero-carbon resources supply 100% of all retail sales of electricity to California end-use customers and 100% of electricity procured to serve all state agencies by December 31, 2045. This bill would revise that state policy to instead provide that eligible renewable energy resources and zero-carbon resources supply 90% of all retail sales of electricity to California end-use customers by December 31, 2035, 95% of all retail sales of electricity to California end-use customers by December 31, 2040, 100% of all retail sales of electricity to California end-use customers by December 31, 2045, and 100% of electricity procured to serve all state agencies by December 31, 2035, as specified. Existing law vests the Public Utilities Commission (PUC) with regulatory authority over public utilities, including electrical corporations, while local publicly owned electric utilities are under the direction of their governing boards. Existing law requires the PUC to ensure that facilities needed to maintain the reliability of the electrical supply remain available and operational. Existing law establishes an Independent System Operator (ISO) as a nonprofit public benefit corporation and requires the ISO to ensure efficient use and reliable operation of the electrical transmission grid consistent with achieving planning and operating reserve criteria no less stringent than those established by the Western Electricity Coordinating Council and the North American Electric Reliability Council. Existing law requires the State Energy Resources Conservation and Development Commission (Energy Commission), in consultation with the PUC, ISO, transmission owners, users, and consumers, to adopt a strategic plan for the state’s electrical transmission grid using existing resources in order to identify and recommend actions required to implement investments needed to ensure reliability, relieve congestion, and meet future growth in load and generation. This bill would authorize the PUC and Energy Commission, upon request of the ISO, to disclose to the ISO confidential information relating to power purchase agreements with electric generation and energy storage projects for purposes of transmission planning. This bill would require the PUC, Energy Commission, and state board, on or before December 1, 2023, and annually thereafter, to issue a joint reliability progress report that reviews system and local reliability within the context of that state policy described above, with a particular focus on summer reliability, identifies challenges and gaps, if any, to achieving system and local reliability, and identifies the amount and cause of any delays to achieving compliance with all energy and capacity procurement requirements set by the PUC. This bill would require the PUC to develop a definition of energy affordability, as specified, and to use energy affordability metrics to guide the development of any protections, incentives, discounts, or new programs to assist residential customers facing hardships or disconnections due to electricity or gas bills and to assess the impact of proposed rate increases on different types of residential customers. The California Public Records Act requires a public agency, defined to mean a state or local agency, to make its public records available for public inspection and to make copies available upon request and payment of a fee, unless the public records are exempt from disclosure. The act makes specified records exempt from disclosure and provides that disclosure by a state or local agency of a public record that is otherwise exempt constitutes a waiver of the exemptions. This bill would specify that a disclosure made through the sharing of information between the ISO and a state agency does not constitute a waiver of the exemptions. Existing law prohibits information furnished to the PUC by a public utility, a business that is a subsidiary or affiliate of a public utility, or a corporation that holds a controlling interest in a public utility from being open to public inspection or made public, except as specified. This bill would authorize a present officer or employee of the PUC to share information with the ISO pursuant to an agreement to treat the shared information as confidential. Existing constitutional provisions require that a statute that limits the right of access to the meetings of public bodies or the writings of public officials and agencies be adopted with findings demonstrating the interest protected by the limitation and the need for protecting that interest. This bill would make legislative findings to that effect. Under existing law, a violation of the Public Utilities Act or any order, decision, rule, direction, demand, or requirement of the PUC is a crime. Because certain of the above provisions would be part of the act and a violation of a PUC action implementing this bill’s requirements would be a crime, the bill would impose a state-mandated local program. The California Constitution requires the state to reimburse local agencies and school districts for certain costs mandated by the state. Statutory provisions establish procedures for making that reimbursement. This bill would provide that no reimbursement is required by this act for a specified reason. DIGEST KEY Vote: majority Appropriation: no Fiscal Committee: yes Local Program: yes BILL TEXT THE PEOPLE OF THE STATE OF CALIFORNIA DO ENACT AS FOLLOWS: SECTION 1. This act shall be known, and may be cited, as the Clean Energy, Jobs, and Affordability Act of 2022. SEC. 2. Section 7921.505 of the Government Code is amended to read: 7921.505. (a) As used in this section, “agency” includes a member, agent, officer, or employee of the agency acting within the scope of that membership, agency, office, or employment. (b) Notwithstanding any other law, if a state or local agency discloses to a member of the public a public record that is otherwise exempt from this division, this disclosure constitutes a waiver of the exemptions specified in: (1) The provisions listed in Section 7920.505. (2) Sections 7924.510 and 7924.700. (3) Other similar provisions of law. (c) This section, however, does not apply to any of the following disclosures: (1) A disclosure made pursuant to the Information Practices Act of 1977 (Chapter 1 (commencing with Section 1798) of Title 1.8 of Part 4 of Division 3 of the Civil Code) or a discovery proceeding. (2) A disclosure made through other legal proceedings or as otherwise required by law. (3) A disclosure within the scope of disclosure of a statute that limits disclosure of specified writings to certain purposes. (4) A disclosure not required by law, and prohibited by formal action of an elected legislative body of the local agency that retains the writing. (5) A disclosure made to a governmental agency that agrees to treat the disclosed material as confidential. Only persons authorized in writing by the person in charge of the agency shall be permitted to obtain the information. Any information obtained by the agency shall only be used for purposes that are consistent with existing law. (6) A disclosure of records relating to a financial institution or an affiliate thereof, if the disclosure is made to the financial institution or affiliate by a state agency responsible for regulation or supervision of the financial institution or affiliate. (7) A disclosure of records relating to a person who is subject to the jurisdiction of the Department of Business Oversight, if the disclosure is made to the person who is the subject of the records for the purpose of corrective action by that person, or, if a corporation, to an officer, director, or other key personnel of the corporation for the purpose of corrective action, or to any other person to the extent necessary to obtain information from that person for the purpose of an investigation by the Department of Business Oversight. (8) A disclosure made by the Commissioner of Business Oversight under Section 450, 452, 8009, or 18396 of the Financial Code. (9) A disclosure of records relating to a person who is subject to the jurisdiction of the Department of Managed Health Care, if the disclosure is made to the person who is the subject of the records for the purpose of corrective action by that person, or, if a corporation, to an officer, director, or other key personnel of the corporation for the purpose of corrective action, or to any other person to the extent necessary to obtain information from that person for the purpose of an investigation by the Department of Managed Health Care. (10) A disclosure made through the sharing of information between the Independent System Operator and a state agency. SEC. 3. Section 38561 of the Health and Safety Code is amended to read: 38561. (a) On or before January 1, 2009, the state board shall prepare and approve a scoping plan, as that term is understood by the state board, for achieving the maximum technologically feasible and cost-effective reductions in greenhouse gas emissions from sources or categories of sources of greenhouse gases by 2020 under this division. The state board shall consult with all state agencies with jurisdiction over sources of greenhouse gases, including the Public Utilities Commission and the State Energy Resources Conservation and Development Commission, on all elements of its plan that pertain to energy-related matters including, but not limited to, electrical generation, load based-standards or requirements, the provision of reliable and affordable electrical service, petroleum refining, and statewide fuel supplies to ensure the greenhouse gas emissions reduction activities to be adopted and implemented by the state board are complementary, nonduplicative, and can be implemented in an efficient and cost-effective manner. (b) The plan shall identify and make recommendations on direct emissions reduction measures, alternative compliance mechanisms, market-based compliance mechanisms, and potential monetary and nonmonetary incentives for sources and categories of sources that the state board finds are necessary or desirable to facilitate the achievement of the maximum feasible and cost-effective reductions of greenhouse gas emissions by 2020. (c) In making the determinations required by subdivision (b), the state board shall consider all relevant information pertaining to greenhouse gas emissions reduction programs in other states, localities, and nations, including the northeastern states of the United States, Canada, and the European Union. (d) The state board shall evaluate the total potential costs and total potential economic and noneconomic benefits of the plan for reducing greenhouse gases to California’s economy, environment, and public health, using the best available economic models, emission estimation techniques, and other scientific methods. (e) In developing its plan, the state board shall take into account the relative contribution of each source or source category to statewide greenhouse gas emissions, and the potential for adverse effects on small businesses, and shall recommend a de minimis threshold of greenhouse gas emissions below which emissions reduction requirements will not apply. (f) In developing its plan, the state board shall identify opportunities for emissions reduction measures from all verifiable and enforceable voluntary actions, including, but not limited to, carbon sequestration projects and best management practices. (g) The state board shall conduct a series of public workshops to give interested parties an opportunity to comment on the plan. The state board shall conduct a portion of these workshops in regions of the state that have the most significant exposure to air pollutants, including, but not limited to, areas designated as federal extreme nonattainment that have communities with minority populations, communities with low-income populations, or both. (h) The state board shall update its plan for achieving the maximum technologically feasible and cost-effective reductions of greenhouse gas emissions at least once every five years. SEC. 4. Section 454.53 of the Public Utilities Code is amended to read: 454.53. (a) It is the policy of the state that eligible renewable energy resources and zero-carbon resources supply 90 percent of all retail sales of electricity to California end-use customers by December 31, 2035, 95 percent of all retail sales of electricity to California end-use customers by December 31, 2040, 100 percent of all retail sales of electricity to California end-use customers by December 31, 2045, and 100 percent of electricity procured to serve all state agencies by December 31, 2035. The achievement of this policy for California shall not increase carbon emissions elsewhere in the western grid and shall not allow resource shuffling. The commission and Energy Commission, in consultation with the State Air Resources Board, shall take steps to ensure that a transition to a zero-carbon electric system for the State of California does not cause or contribute to greenhouse gas emissions increases elsewhere in the western grid, and is undertaken in a manner consistent with clause 3 of Section 8 of Article I of the United States Constitution. The commission, the Energy Commission, the State Air Resources Board, and all other state agencies shall incorporate this policy into all relevant planning. (b) The commission, Energy Commission, State Air Resources Board, and all other state agencies shall ensure that actions taken in furtherance of subdivision (a) do all of the following: (1) Maintain and protect the safety, reliable operation, and balancing of the electric system. (2) Prevent unreasonable impacts to electricity, gas, and water customer rates and bills resulting from implementation of this section, taking into full consideration the economic and environmental costs and benefits of renewable energy and zero-carbon resources. (3) To the extent feasible and authorized under law, lead to the adoption of policies and taking of actions in other sectors to obtain greenhouse gas emission reductions that ensure equity between other sectors and the electricity sector. (4) Not affect in any manner the rules and requirements for the oversight of, and enforcement against, retail sellers and local publicly owned utilities pursuant to the California Renewables Portfolio Standard Program (Article 16 (commencing with Section 399.11) of Chapter 2.3) and Sections 454.51, 454.52, 9621, and 9622. (c) Nothing in this section shall affect a retail seller’s obligation to comply with the federal Public Utility Regulatory Policies Act of 1978 (16 U.S.C. Sec. 2601 et seq.). (d) The commission, Energy Commission, and State Air Resources Board shall do all of the following: (1) Use programs authorized under existing statutes to achieve the policy described in subdivision (a). (2) In consultation with all California balancing authorities, as defined in subdivision (d) of Section 399.12, as part of a public process, issue a joint report to the Legislature by January 1, 2021, and at least every four years thereafter. The joint report shall include all of the following: (A) A review of the policy described in subdivision (a) focused on technologies, forecasts, then-existing transmission, and maintaining safety, environmental and public safety protection, affordability, and system and local reliability. (B) An evaluation identifying the potential benefits and impacts on system and local reliability associated with achieving the policy described in subdivision (a). (C) An evaluation identifying the nature of any anticipated financial costs and benefits to electric, gas, and water utilities, including customer rate impacts and benefits. (D) The barriers to, and benefits of, achieving the policy described in subdivision (a). (E) Alternative scenarios in which the policy described in subdivision (a) can be achieved and the estimated costs and benefits of each scenario. (3) On or before December 1, 2023, and annually thereafter, in consultation with California balancing authorities, as defined in subdivision (d) of Section 399.12, and as part of, or an interim addendum to, the quadrennial joint report required by paragraph (2), as applicable, issue a joint reliability progress report that reviews system and local reliability within the context of the policy described in subdivision (a), with a particular focus on summer reliability. The joint reliability progress report shall identify challenges and gaps, if any, to achieving system and local reliability and identify the amount and cause of any delays to achieving compliance with all energy and capacity procurement requirements set by the commission. (e) Nothing in this section authorizes the commission to establish any requirements on a nonmobile self-cogeneration or cogeneration facility that served onsite load, or that served load pursuant to an over-the-fence arrangement if that arrangement existed on or before December 20, 1995. (f) This section does not limit any entity, including local governments, from accelerating their achievement of the state’s electric sector decarbonization targets. SEC. 5. Section 454.59 is added to the Public Utilities Code, to read: 454.59. (a) This section applies to the obligations on a state agency, except the State Water Resources Development System commonly known as the State Water Project, imposed pursuant to subdivision (a) of Section 454.53. (b) Each state agency shall ensure that zero-carbon resources and eligible renewable energy resources supply 100 percent of electricity procured on its behalf by December 31, 2035. (c) A state agency may satisfy the requirement in subdivision (b) by doing one or more of the following: (1) Installing zero-carbon resources or eligible renewable energy resources behind the customer meter on state-owned or state-leased buildings to serve the state agency’s onsite load. (2) Procuring zero-carbon resources or eligible renewable energy resources through the local publicly owned electric utility or load-serving entity, as defined in Section 380, providing retail service to the state agency, subject to any credit or collateral requirements or other applicable requirements imposed by the local publicly owned electric utility or load-serving entity, as defined in Section 380, as a condition for procurement on behalf of a customer. (3) Participating in a voluntary shared renewable or green pricing program offered by a local publicly owned electric utility or load-serving entity, as defined in Section 380, if the resources serving the state agency satisfy the requirements of subdivision (d). (d) New procurement commitments made on behalf of a state agency by its retail seller or local publicly owned electric utility after June 1, 2022, for zero-carbon resources or eligible renewable energy resources to serve the state agency pursuant to subdivision (c) shall satisfy all of the following criteria: (1) The zero-carbon resource or eligible renewable energy resource shall be newly developed as a result of contracting and reach initial commercial operations on or after January 1, 2023. (2) An eligible renewable energy resource or storage product shall be required to satisfy either of the criteria specified in paragraph (1) of subdivision (b) of Section 399.16. (3) The zero-carbon resource or eligible renewable energy resource shall be located within California. (4) The retail seller or local publicly owned electric utility shall require its contractors to use a multicraft project labor agreement, as defined in paragraph (1) of subdivision (b) of Section 2500 of the Public Contract Code, for construction of the zero-carbon resource or eligible renewable energy resource. The project labor agreement shall conform to the industry standard agreements recently used for other similar private projects, including side letters for high-voltage transmission and related work. (5) The retail seller or local publicly owned electric utility shall exclude the retail sales to a state agency customer from any compliance obligations relating to zero-carbon resources or eligible renewable resources, including, but not limited to, obligations pursuant to Section 399.25 or 399.30. (6) Any renewable energy credits or environmental attributes associated with incremental procurement pursuant to this section shall be retired on behalf of the state agency customer and shall not be further sold, transferred, or otherwise monetized for any purpose. (e) Zero-carbon resource or eligible renewable energy resource procurement commitments made on behalf of a state agency shall give preference to resource options expected to yield maximum long-term employment, stimulate new economic activity, generate local and state tax revenues, and assist with the development of new industries. SEC. 6. Section 583 of the Public Utilities Code is amended to read: 583. (a) No information furnished to the commission by a public utility, a business that is a subsidiary or affiliate of a public utility, or a corporation that holds a controlling interest in a public utility, except those matters specifically required to be open to public inspection by this part, shall be open to public inspection or made public, except on order of the commission or by the commission or a commissioner in the course of a hearing or proceeding. A present or former officer or employee of the commission who divulges that information is guilty of a misdemeanor. (b) Notwithstanding subdivision (a) or any other law, a present officer or employee of the commission may share information with the Independent System Operator pursuant to an agreement to treat the shared information as confidential. SEC. 7. Section 739.13 is added to the Public Utilities Code, to read: 739.13. (a) The commission shall develop a definition of energy affordability. (b) The definition of energy affordability shall establish energy affordability metrics based on household income and include the combined impact of electricity and gas bills. (c) The commission shall use energy affordability metrics for both of the following purposes: (1) To guide the development of any protections, incentives, discounts, or new programs to assist residential customers facing hardships or disconnections due to electricity or gas bills. (2) To assess the impact of proposed rate increases on different types of residential customers. SEC. 8. Division 27.5 (commencing with Section 80400) is added to the Water Code, to read: DIVISION 27.5. State Water Project Energy Procurement 80400. (a) (1) The department shall procure eligible renewable energy resources and zero-carbon resources to satisfy the state agency obligations imposed on the State Water Resources Development System, commonly known as the State Water Project, pursuant to subdivision (a) of Section 454.53 of the Public Utilities Code. (2) If the department determines that the full achievement of the state agency obligations imposed on the State Water Resources Development System would require the early termination of an existing contract to procure fossil generation entered before January 1, 2010, and that early termination would result in significant uneconomic costs, the department may defer procuring zero-carbon electricity resource quantities equal to the amount of electricity provided under the existing contract until no later than December 31, 2040. (3) In the event that extraordinary circumstances, catastrophic events, considerable supply chain disruptions and equipment shortages, or threats of significant economic harm render full achievement of the obligations imposed on the State Water Resources Development System pursuant to subdivision (a) of Section 454.53 of the Public Utilities Code infeasible, the Governor may adjust the applicable deadline for the department’s compliance to the earliest feasible date, but that date shall be no later than December 31, 2040. (b) The department may satisfy all or a portion of the obligation on the State Water Resources Development System pursuant to subdivision (a) of Section 454.53 of the Public Utilities Code by installing zero-carbon resources or eligible renewable energy resources behind the meter on the State Water Resources Development System property or properties to service its load. (c) All resources procured pursuant to subdivision (a) after February 1, 2022, shall satisfy both of the following criteria: (1) The eligible renewable energy resources and zero-carbon resources shall either be newly developed as a result of contracting by the department or constitute incremental production from existing resources and reach initial commercial operations on or after January 1, 2023. This requirement may be satisfied if the resource is newly developed by a local publicly owned electric utility with the expectation that the output would be sold to the department in support of the State Water Resources Development System. (2) The eligible renewable energy resources and zero-carbon resources shall be located within California or have a first point of interconnection to a California balancing authority. (d) In conducting procurement pursuant to subdivision (a), the department shall consider all of the following: (1) Procurement commitments that may yield maximum long-term employment, stimulate new economic activity, generate local and state tax revenues, and assist with the development of new industries. (2) Attributes, including resource adequacy, flexibility, and integration value, the ability to provide firm clean electricity, and local air quality benefits. (3) The results of integrated resource planning modeling conducted by the Public Utilities Commission pursuant to Section 454.52 of the Public Utilities Code. (e) The department shall consider doing all of the following to reduce the costs of any procurement made pursuant to this section: (1) Coordinate with the California Infrastructure and Economic Development Bank to make low-cost financing assistance available to new projects included in any procurement commitments. (2) Coordinate with other state agencies to identify incentives from existing programs for new projects included in any procurement commitments. (3) If reasonably expected to provide incremental benefits, secure an ownership stake or royalties for any project or economic activity resulting from a contractual commitment. (f) All resources procured pursuant to this section shall be used first to meet the department’s own electricity needs. A renewable energy credit, as defined in Section 399.12 of the Public Utilities Code, associated with the electricity used to satisfy the obligations of the department and the State Water Resources Development System under this section shall be retired and shall not be transferred or resold. (g) The department shall enter into an agreement to procure energy from a new energy generation facility only if the seller requires its contractors to use a multicraft project labor agreement, as defined in paragraph (1) of subdivision (b) of Section 2500 of the Public Contract Code, for construction of the facility. Those project labor agreements shall conform to the industry standard agreements recently used for other similar private projects, including side letters for high-voltage transmission and related work. SEC. 9. The Legislature finds and declares that Section 2 of this act, which amends Section 7921.505 of the Government Code, imposes a limitation on the public’s right of access to the meetings of public bodies or the writings of public officials and agencies within the meaning of Section 3 of Article I of the California Constitution. Pursuant to that constitutional provision, the Legislature makes the following findings to demonstrate the interest protected by this limitation and the need for protecting that interest: This act protects market-sensitive procurement information from public disclosure to protect fair competition and prevent market manipulation, while enabling the Independent System Operator and a state agency to share with each other otherwise confidential information for purposes of ensuring electrical system reliability. Further, the Legislature endorses the Public Utilities Commission’s findings and governing rules adopted after the 2000–01 energy crisis for protecting and accessing confidential market-sensitive information, as specified in Public Utilities Commission Decisions 06-06-66, 06-12-030, 07-05-032, 08-04-023, 09-12-020, 11-07-028, and 20-07-005. SEC. 10. No reimbursement is required by this act pursuant to Section 6 of Article XIII B of the California Constitution because the only costs that may be incurred by a local agency or school district will be incurred because this act creates a new crime or infraction, eliminates a crime or infraction, or changes the penalty for a crime or infraction, within the meaning of Section 17556 of the Government Code, or changes the definition of a crime within the meaning of Section 6 of Article XIII B of the California Constitution. [Chaptered text of SB 1020 (2021-2022), saved by browser from leginfo.legislature.ca.gov on 2026-09-30; the site's robots.txt disallows crawling.]