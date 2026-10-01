You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-09-30-shadow-wicks-ab1228/labels/coder-2.json. Write JSON only, matching
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

politician_id: 5821d0a9-672e-44c0-bac7-1a802a2e8368  office_id: 7b3dcdad-b119-4b25-8240-460f70244f9d
Buffy Wicks — Assembly Member, California (seated, level: state)
Current term: 2022-12-05 (precision: day) to present
Earlier terms in this legislature: State Representative 2018-12-03 (precision: day) to 2022-12-05

## Topics (served ladder text — code against these words only)

### topic_key: minimum-wage
topic_id: 43d9e981-f25e-471f-ae92-b8e2a700900c  served_revision_id: bc949d3b-43f4-4612-ba4c-2de39f8757c8
Question: What approach should government take to the minimum wage?
  1. Raise the wage floor and tie it to the cost of living, so it rises automatically each year without new legislation.
  2. Raise the wage floor to a set higher level, then adjust it only when lawmakers vote to.
  3. Keep a modest national wage floor as a baseline and let states and cities set higher rates.
  4. Hold the wage floor at its current level and let the market set pay above it.
  5. Remove the wage floor entirely and let employers and workers set pay by agreement.

#### Annex

(no annex for this topic yet — apply the codebook alone)

## Sources

---
snapshot_id: d406e55d-80fd-5708-be95-8b2bd4399548
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1228

BILL VOTES AB-1228 Fast food restaurant industry: Fast Food Council: health, safety, employment, and minimum wage.(2023-2024) Bill Votes Date 09/14/23 Result (PASS) Location Assembly Floor Ayes Count 53 Noes Count 17 NVR Count 10 Motion AB 1228 Holden Concurrence in Senate Amendments Ayes Addis, Aguiar-Curry, Arambula, Bains, Bauer-Kahan, Bennett, Berman, Boerner, Bonta, Bryan, Calderon, Wendy Carrillo, Cervantes, Connolly, Mike Fong, Friedman, Gabriel, Garcia, Gipson, Grayson, Haney, Hart, Holden, Jackson, Jones-Sawyer, Kalra, Lee, Low, Lowenthal, Maienschein, McCarty, McKinnor, Muratsuchi, Stephanie Nguyen, Ortega, Papan, Pellerin, Quirk-Silva, Reyes, Luz Rivas, Rodriguez, Santiago, Schiavo, Soria, Ting, Valencia, Ward, Weber, Wicks, Wilson, Wood, Zbur, Robert Rivas Noes Alanis, Megan Dahle, Davies, Dixon, Essayli, Flora, Vince Fong, Gallagher, Hoover, Lackey, Mathis, Jim Patterson, Joe Patterson, Sanchez, Ta, Waldron, Wallis NVR Alvarez, Juan Carrillo, Chen, Irwin, Pacheco, Petrie-Norris, Ramos, Rendon, Blanca Rubio, Villapudua [Final floor vote from the bill votes page for AB 1228 (2023-2024), saved by browser from leginfo.legislature.ca.gov on 2026-09-30; the site's robots.txt disallows crawling.]

---
snapshot_id: 2b00b586-74a0-5073-9887-3b6484ae1ae5
source_kind: public-record
url: https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202320240AB1228

Assembly Bill No. 1228 CHAPTER 262 An act to add Part 4.5.5 (commencing with Section 1474) to, and to repeal Part 4.5.5 (commencing with Section 1470) of, Division 2 of the Labor Code, relating to employment. [ Approved by Governor September 28, 2023. Filed with Secretary of State September 28, 2023. ] LEGISLATIVE COUNSEL'S DIGEST AB 1228, Holden. Fast food restaurant industry: Fast Food Council: health, safety, employment, and minimum wage. Existing law, which is suspended pursuant to a referendum petition, establishes, until January 1, 2029, the Fast Food Council (council) within the Department of Industrial Relations and prescribes its powers. Existing law, among other things, prescribes the purposes, duties, and limitations of the council, including a requirement that the council promulgate minimum fast food restaurant employment standards. Existing law sets standards for any minimum wage the council establishes. This bill would repeal those existing provisions on January 1, 2024, if a specified referendum is withdrawn by its proponents by that date. If the referendum is withdrawn, in addition to that repeal, this bill would, until January 1, 2029, or as otherwise provided, establish the Fast Food Council and prescribe the council’s purposes, duties, and limitations, as described, establish an hourly minimum wage for fast food restaurant employees, as described, authorize the council to increase the hourly minimum wage pursuant to specified parameters, and set forth requirements, limitations, and procedures for adopting and reviewing fast food restaurant health, safety, and employment standards. The bill would require all standards, rules, and regulations developed by the council to be issued, amended, or repealed, as applicable, in the manner prescribed in the Administrative Procedure Act, but as modified, and would require the council to petition the Occupational Safety and Health Standards Board and the Civil Rights Council if any minimum standards fall within their jurisdiction. Existing law prohibits, among other things, an employer or any person acting on behalf of the employer from making, adopting, or enforcing any rule, regulation, or policy preventing an employee from disclosing information to a government or law enforcement agency, among other individuals and entities, if the employee has reasonable cause to believe that the information discloses specified violations of law, regardless of whether disclosing the information is part of the employee’s job duties. Existing law imposes, in addition to other penalties, a civil penalty on certain employers for each violation of this provision, except as specified. This bill would also deem the council a governmental agency for purposes of the above-described prohibition. The bill would additionally prohibit a fast food restaurant operator from discharging or in any manner discriminating or retaliating against any employee due to the employee’s participation in or testimony to any proceeding convened by the council. This bill would prohibit any city, county, or city and county from enacting or enforcing any ordinance or regulation applicable to fast food restaurant employees that sets the amount of wages or salaries for fast food restaurant employees, except as provided. By imposing additional requirements on local agencies, the bill would impose a state-mandated local program. Existing law establishes in the Department of Industrial Relations the Division of Labor Standards Enforcement under the direction of the Labor Commissioner. Existing law authorizes the Labor Commissioner to investigate employee complaints and to provide for a hearing in any action to recover wages, penalties, and other demands for compensation. This bill would require the Labor Commissioner to enforce compliance with the minimum fast food restaurant employment standards and any other standards promulgated pursuant to the bill’s provisions and would set forth procedures for enforcing the standards. By expanding the application of crimes associated with those enforcement procedures, the bill would impose a state-mandated local program. This bill would make legislative findings and declarations as to the necessity of a special statute for fast food restaurant workers. The bill would include findings that changes proposed by this bill address a matter of statewide concern rather than a municipal affair and, therefore, apply to all cities, including charter cities. The California Constitution requires the state to reimburse local agencies and school districts for certain costs mandated by the state. Statutory provisions establish procedures for making that reimbursement. This bill would provide that with regard to certain mandates no reimbursement is required by this act for a specified reason. With regard to any other mandates, this bill would provide that, if the Commission on State Mandates determines that the bill contains costs so mandated by the state, reimbursement for those costs shall be made pursuant to the statutory provisions noted above. DIGEST KEY Vote: majority Appropriation: no Fiscal Committee: yes Local Program: yes BILL TEXT THE PEOPLE OF THE STATE OF CALIFORNIA DO ENACT AS FOLLOWS: SECTION 1. It is the intent of the Legislature to repeal Sections 1470, 1471, 1472, and 1473 of the Labor Code and enact new Sections 1474, 1475, and 1476 of the Labor Code. SEC. 2. Part 4.5.5 (commencing with Section 1470) of Division 2 of the Labor Code is repealed. SEC. 3. Part 4.5.5 (commencing with Section 1474) is added to Division 2 of the Labor Code, to read: PART 4.5.5. Fast Food 1474. For purposes of this part: (a) “National fast food chain” means a set of limited-service restaurants consisting of more than 60 establishments nationally that share a common brand, or that are characterized by standardized options for decor, marketing, packaging, products, and services, and which are primarily engaged in providing food and beverages for immediate consumption on or off premises where patrons generally order or select items and pay before consuming, with limited or no table service. For purposes of the definitions in this part, “limited-service restaurant” includes, but is not limited to, an establishment with the North American Industry Classification System Code 722513. (b) “Council” means the Fast Food Council. (c) (1) Except as provided in paragraph (2), “fast food restaurant” means a limited-service restaurant in the state that is part of a national fast food chain. (2) “Fast food restaurant” shall not include an establishment that on September 15, 2023, operates a bakery that produces for sale on the establishment’s premises bread, as defined under Part 136 of Subchapter B of Chapter I of Title 21 of the Code of Federal Regulations, so long as it continues to operate such a bakery. This exemption applies only where the establishment produces for sale bread as a stand-alone menu item, and does not apply if the bread is available for sale solely as part of another menu item. (d) “Fast food restaurant franchisee” means a person to whom a fast food restaurant franchise is granted. (e) “Fast food restaurant franchisor” means a person who grants or has granted a fast food restaurant franchise. (f) “Fast food restaurant operator” means a person who operates a fast food restaurant. (g) “Franchise,” “franchisee,” and “franchisor” have the definitions set forth in Article 1 (commencing with Section 20000) of Chapter 5.5 of Division 8 of the Business and Professions Code. (h) “Working conditions” include, but are not limited to, wages, conditions affecting fast food restaurant employees’ health and safety, security in the workplace, the right to take time off work for protected purposes, and the right to be free from discrimination and harassment in the workplace. (i) When a restaurant is located and operates within a “grocery establishment,” as defined in subdivision (d) of Section 2502, and the grocery establishment employer employs the individuals working in the restaurant, the restaurant shall not be considered a fast food restaurant. 1475. (a) (1) The Fast Food Council is hereby established within the Department of Industrial Relations and shall consist of the following nine voting members: (A) Two representatives of the fast food restaurant industry. (B) Two representatives of fast food restaurant franchisees or restaurant owners. (C) Two representatives of fast food restaurant employees. (D) Two representatives of advocates for fast food restaurant employees. (E) One unaffiliated member of the public who is not an owner, franchisee, officer, or employee in the fast food industry; who is not an employee or officer of a labor organization or a member of a labor organization representing fast food restaurant employees; and who has not received income from the fast food industry or any labor organization for a period of two years prior to appointment. (2) In addition to the voting members, the council shall include the following nonvoting members: (A) One representative from the Department of Industrial Relations. (B) One representative from the Governor’s Office of Business and Economic Development. (3) The Governor shall appoint the representatives of fast food restaurant employees, fast food restaurant franchisees or restaurant owners, the fast food restaurant industry, and the member of the public. The Speaker of the Assembly and the Senate Committee on Rules shall each appoint one representative of an advocate for fast food restaurant employees. (4) The appointments shall be at the will of each appointing power and each member of the council shall serve for a term of four years, except that all terms shall end on the date this section becomes inoperative. All terms that end prior to the date that this section becomes inoperative shall end on January 1. Vacancies occurring prior to the expiration of the term shall be filled by appointment for the unexpired term. A council member shall not serve more than two consecutive terms. (5) The unaffiliated member of the public shall be the chairperson of the council. The chairperson shall be responsible for convening the council. The chairperson shall designate a member of the council to act as chairperson in their absence. (6) Each member of the council shall receive one hundred dollars ($100) for each day of their actual attendance at meetings of the council and other official business of the council, in addition to their actual necessary traveling expenses incurred in the performance of their duties as a member. (7) The council may employ necessary assistants, officers, experts, and other employees as it deems necessary, subject to appropriation. All personnel of the council shall be under the supervision of the chairperson or an executive officer to whom the chairperson delegates such responsibility. All such personnel shall be appointed pursuant to the State Civil Service Act (Part 2 (commencing with Section 18500) of Division 5 of Title 2 of the Government Code), except for the one exempt deputy or employee allowed by subdivision (e) of Section 4 of Article VII of the California Constitution. (8) All meetings of the council shall be subject to the Bagley-Keene Open Meeting Act (Article 9 (commencing with Section 11120) of Chapter 1 of Part 1 of Division 3 of Title 2 of the Government Code). (b) The council’s purposes are to establish fast food restaurant minimum standards on wages, and develop fast food restaurant minimum standards on working hours, and other working conditions adequate to ensure and maintain the health, safety, and welfare of, and to supply the necessary cost of proper living to, fast food restaurant workers and to ensure and effect interagency coordination and prompt agency responses regarding issues affecting the health, safety, and employment of fast food restaurant workers. (c) (1) The council shall provide direction to, and coordinate with, state agencies regarding the health, safety, and employment of fast food restaurant workers. (2) The council shall convene its first meeting by no later than March 15, 2024. (d) (1) (A) The council is charged with developing minimum fast food restaurant employment standards, including, as appropriate, standards on wages, working conditions, and training, as are reasonably necessary or appropriate to protect and ensure the welfare, including the physical well-being and security, of fast food workers or to otherwise meet the purposes of this section, subject to the limitations of subdivisions (e) and (f). In developing these standards, the council may take account of regional differences. Any change developed by the council to existing standards, rules, or regulations shall not be less protective of or less beneficial to health, safety, or fast food restaurant worker employment terms, conditions, or privileges, including wages, than the immediately preceding standard, rule, or regulation. To the extent there is a conflict between standards, rules, or regulations issued pursuant to this subdivision and those previously issued by another state agency, the standards, rules, or regulations issued pursuant to this subdivision shall apply to fast food restaurant employees, and the conflicting standards, rules, or regulations of the other state agency shall not have force or effect with respect to fast food restaurant employees. (B) Decisions by the council regarding standards, rules, or regulations shall be made by an affirmative vote of at least five of the council members. (C) All standards, rules, and regulations developed by the council shall be issued, amended, or repealed, as applicable, in the manner prescribed in Chapter 3.5 (commencing with Section 11340) of Part 1 of Division 3 of Title 2 of the Government Code, subject to the provisions of clause (i) to (iii), inclusive, of this subparagraph, and with the exception of standards issued pursuant to the procedures identified in subparagraph (D) of paragraph (2) of this subdivision. (i) With the exception of standards subject to subdivision (e) or (f), the Labor Commissioner shall be responsible for issuing, amending, or repealing, as applicable, standards developed by the council pursuant to the requirements of this subparagraph. (ii) The council shall send proposed written standards to the Labor Commissioner and request that the commissioner prepare a notice of proposed rulemaking action regarding the proposed regulatory text. (iii) Upon receiving a request to prepare a notice of proposed rulemaking action, the Labor Commissioner shall determine whether the proposed written standards are consistent with the council’s authority and consistent with the criteria identified in subdivision (a) of Section 11349.1 of the Government Code, and, if it so determines, the commissioner shall prepare and submit to the Office of Administrative Law a notice of proposed rulemaking action and the required materials identified in Section 11346.2 of the Government Code. If the commissioner determines either that the proposed standards are not consistent with the council’s authority, or not consistent with the criteria identified in subdivision (a) of Section 11349.1 of the Government Code, the commissioner shall, within 60 days of receiving the council’s request to issue a notice of proposed rulemaking, provide the council with a written explanation of the reasons for that determination so the council may modify its proposed standards as appropriate. The commissioner shall also have responsibility and authority to carry out the requirements of Sections 11346.8 and 11346.9 of the Government Code. (D) The council may develop written emergency standards and send the proposed written emergency standards to the Labor Commissioner and request that the commissioner promulgate such standards pursuant to Sections 11346.1 and 11349.6 of the Government Code. (2) (A) The hourly minimum wage for fast food restaurant employees shall be twenty dollars ($20) per hour, effective April 1, 2024. Thereafter, the council may establish, pursuant to this subdivision, minimum wages for fast food restaurant employees that take effect on an annual basis, beginning on January 1, 2025. (B) The hourly minimum wage established by the council may increase on an annual basis by no more than the lesser of the following, rounded to the nearest ten cents ($0.10): (i) 3.5 percent. (ii) The rate of change in the averages of the most recent July 1 to June 30, inclusive, period over the preceding July 1 to June 30, inclusive, period for the United States Bureau of Labor Statistics nonseasonally adjusted United States Consumer Price Index for Urban Wage Earners and Clerical Workers (U.S. CPI-W). (C) In establishing minimum wage increases subject to paragraph (B), the council may elect to set minimum wage standards that vary by region or to set a statewide minimum wage increase. (D) The hourly minimum wage established pursuant to subparagraph (A), and all future hourly minimum wages established pursuant to subparagraph (B), shall constitute the state minimum wage for fast food restaurant employees for all purposes under this code and the wage orders of the Industrial Welfare Commission. It shall be enforceable by the Labor Commissioner through the procedures set forth in Sections 98, 98.1, 98.2, 98.3, 98.7, 98.74, or 1197.1, or by a covered worker through a civil action, through the same means and with the same relief available for violation of any other state minimum wage requirement. The Department of Industrial Relations shall update Wage Order No. 5-2001 and the Minimum Wage Order to be consistent with any minimum hourly wage adopted by the council and any other standards or requirements developed by the council and adopted by the commissioner pursuant to this chapter, except that any existing provision in Wage Order 5-2001 or the Minimum Wage Order providing greater protections or benefits to fast food restaurant employees shall continue in full force and effect, notwithstanding any provision of this part. Hourly minimum wages established by the council pursuant to subparagraphs (A) and (B) shall be treated as wage orders and shall be exempt from Article 5 (commencing with Section 11346) of Chapter 3.5 of Part 1 of Division 3 of Title 2 of the Government Code. (E) Any minimum wage established by the council must be equal to or greater than any otherwise generally applicable state hourly minimum wage. (F) The council shall not establish any minimum wage increase that takes effect commencing on a date after the 2029 calendar year. However, the council may provide advice to any appropriate state agencies regarding minimum wage increases that would take effect commencing on a date on or after January 1, 2030. (3) Minimum wage standards established by the council shall be subject to any suspension of increases in the statewide minimum wage made pursuant to subdivision (d) of Section 1182.12. (4) Standards developed pursuant to paragraphs (1) and (2) shall not alter or amend the requirements in the California Retail Food Code (Part 7 (commencing with Section 113700) of Division 104 of the Health and Safety Code). (5) The council shall provide information as requested by the appropriate committees of the Legislature on labor to facilitate a review of the council’s performance and standards under this section, which review may be conducted in a joint hearing held every three years or as otherwise designated by the appropriate committees of the Legislature on labor. (6) Nothing in this section shall be construed to give the council the authority to create or amend statutes. (7) Nothing in this section shall be construed to permit the council to develop or promulgate regulations creating new paid time off benefits, such as paid sick leave or paid vacation. For purposes of this paragraph, paid time off benefits do not include paid rest periods. (8) Nothing in this section shall be construed to permit the council to develop or promulgate regulations regarding predictable scheduling. Predictable scheduling does not include reporting time pay. (e) To the extent that any minimum standards that the council finds are reasonably necessary to protect fast food restaurant employee health and safety fall within the jurisdiction of the Occupational Safety and Health Standards Board, the council shall petition the Occupational Safety and Health Standards Board for the adoption, amendment, or repeal of any occupational safety and health standard. The Occupational Safety and Health Standards Board shall consider and respond to the petition no later than six months following receipt of the petition in accordance with Section 142.2, or no later than three months if the petition relates to an emergency, as defined in Section 11342.545 of the Government Code. The Occupational Safety and Health Standards Board shall not adopt a standard recommended by the council if it reduces occupational safety and health protections for employees. (f) To the extent that any minimum standards that the Fast Food Council finds are reasonably necessary fall within the jurisdiction of the Civil Rights Council under Section 12935 of the Government Code, the Fast Food Council shall petition the Civil Rights Council for the adoption, amendment, or repeal of any regulation under the jurisdiction of the Civil Rights Council. The Civil Rights Council shall consider and respond to the petition no later than six months following receipt of the petition, or within no more than three months if the petition relates to an emergency, as defined in Section 11342.545 of the Government Code. The Civil Rights Council shall not adopt a recommended standard that would reduce protections provided under the California Fair Employment and Housing Act (Part 2.8 (commencing with Section 12900) of Division 3 of Title 2 of the Government Code) or other law within the Civil Rights Council’s jurisdiction. (g) The council shall conduct a full review of the adequacy of the minimum fast food restaurant health, safety, and employment standards at least once every three years. Upon that review, the council shall develop and seek the issuance of any fast food employment, health, or safety standard applicable to fast food restaurants, or a portion of any such standard, as appropriate to meet the purposes of this section, pursuant to the procedures set forth in subdivision (d) and subject to subdivisions (e) and (f). (h) The council shall hold meetings or hearings no less than every six months that are open to the public, at which the public, including fast food restaurant employees, shall have the opportunity to be heard on issues of fast food restaurant health, safety, and employment conditions. The council shall provide advance public notice of these meetings or hearings that is reasonably calculated to advise fast food restaurant workers, fast food restaurant operators and owners, franchisors, franchisees, community members, and other stakeholders of the opportunity to participate in the meetings or hearings. The location of the meetings or hearings shall rotate among major metropolitan areas throughout the state to provide fast food restaurant workers, fast food restaurant operators and owners, franchisors, franchisees, community members, and other stakeholders throughout the state a reasonable opportunity to participate in a meeting or hearing at least once per each three-year review. (i) The council may coordinate with local agencies and request that they hold meetings or hearings that are open to the public, at which the public, including fast food restaurant employees, shall have the opportunity to be heard on issues of fast food restaurant health, safety, and employment conditions. After these meetings or hearings, the council may request information from the local agencies, including any recommendations for action by the council. (j) (1) The minimum wage, maximum hours of work, and other working conditions developed by the council in standards promulgated pursuant to subdivision (d) shall be the minimum wage, maximum hours of work, and the standard conditions of labor for fast food restaurant employees or a relevant subgroup of fast food restaurant employees for purposes of state law. Except as provided in subdivision (m), nothing in this section shall restrict local jurisdictions’ exercise of police powers to establish more protective local standards. The employment of a fast food restaurant employee for lower wages or for longer hours than those fixed by the minimum standards promulgated pursuant to subdivision (d), or under any other working conditions prohibited by the minimum standards promulgated pursuant to subdivision (d), is unlawful. Compliance with the minimum fast food restaurant employment standards promulgated pursuant to subdivision (d) shall be enforced by the Labor Commissioner pursuant to the procedures and provisions set forth in Chapter 4 (commencing with Section 79) of Division 1, Division 2 (commencing with Section 200), Division 3 (commencing with Section 2700), and Division 5 (commencing with Section 6300), and standards, orders, or regulations promulgated pursuant to subdivision (d). (2) Other than occupational safety and health violations, which shall be enforced by the Division of Occupational Safety and Health under Division 5 (commencing with Section 6300), and other than protections against discrimination, harassment, and other violations of Part 2.8 (commencing with Section 12900) of Division 3 of Title 2 of the Government Code, which shall be enforced by the Civil Rights Department, the Labor Commissioner shall enforce this part, including any standards promulgated by the appropriate agency pursuant to subdivision (d), including by investigating an alleged violation, and ordering appropriate temporary relief to mitigate the violation or to maintain the status quo pending the completion of a full investigation or hearing, through the procedures set forth in Chapter 4 (commencing with Section 79) of Division 1 and Section 1197.1, including by issuance of a citation against an employer, a fast food restaurant operator, or any other liable person under this part, and by filing a civil action. If a citation is issued, the procedures for issuing, contesting, and enforcing judgments for citations and civil penalties issued by the Labor Commissioner shall be the same as those set out in Section 98.74 or 1197.1, as appropriate. In any successful civil action to enforce this section by the Labor Commissioner or an employee, the court may grant injunctive relief in order to obtain compliance with this part, and shall award costs and reasonable attorney’s fees. (3) A standard promulgated pursuant to subdivision (d) shall not supersede a standard covered by a valid collective bargaining agreement if the agreement expressly provides for the wages, hours of work, and working conditions of the employees, and a regular hourly rate of pay not less than 30 percent more than the state minimum wage for those employees, if the agreement provides equivalent or greater protection than the standards established by the council and if state law on the same issue authorizes an exception for employees covered by a collective bargaining agreement. Nothing in this section shall be construed to allow a collective bargaining agreement to waive any occupational health and safety protections. (4) Nothing in this section shall be construed to require local health departments to enforce standards issued by the council. (k) The Labor Commissioner is authorized to issue any other rules, regulations, and guidance necessary for the enforcement of this part consistent with its authority under Section 98.8. (l) (1) No ordinance or regulation applicable to fast food restaurant employees that sets the amount of wages or salaries for fast food restaurant employees shall be enacted or enforced by any city, county, or city and county, including charter cities, charter counties, and charter cities and counties. (2) This subdivision does not preclude a city, county, or city and county, including charter cities, charter counties, and charter cities and counties, from establishing a minimum wage that is generally applicable to all industries. (3) This subdivision does not preclude any employer that employs fast food restaurant employees from establishing higher wage or compensation rates for its employees or contracted employees. (4) (A) Subject to subdivision (m), this subdivision shall become inoperative if the hourly minimum wage established pursuant to subparagraph (A) of paragraph (2) of subdivision (d) does not take effect on April 1, 2024, or by a later date arising from a delay or other temporary pause in the implementation of that hourly minimum wage that is forced by an injunction or other proper judicial or administrative action, whichever is later. (B) Subject to subparagraph (A) of this paragraph and subdivision (m), this subdivision shall remain in effect only so long as the council maintains authority to establish minimum wage increases pursuant to subparagraphs (A) and (B) of paragraph (2) of subdivision (d). (m) Subject to Section 1477, subdivisions (a) to (i), inclusive, and (l) of this section shall become inoperative as of January 1, 2029, and the council shall cease operations. Any standards adopted by the appropriate agencies pursuant to this section shall not be impacted by the cessation of the council. 1476. (a) A fast food restaurant operator shall not discharge or in any manner discriminate or retaliate against any employee due to the employee’s participation in or testimony to any proceeding convened by the council. (b) The council shall be deemed a governmental agency for purposes of subdivision (a) of Section 1102.5. 1477. Sections 1474 to 1476, inclusive, shall become operative and shall take effect commencing January 1, 2024, only if Referendum No. 1939 (Attorney General No. 22-0005) has been withdrawn by its proponents by January 1, 2024. If that referendum has not been withdrawn by its proponents by January 1, 2024, Sections 1474 to 1476, inclusive, and this section shall become inoperative on January 1, 2024, and as of that date, are repealed. SEC. 4. Section 2 shall become operative and take effect commencing January 1, 2024, only if Referendum No. 1939 (Attorney General No. 22-0005) has been withdrawn by its proponents by January 1, 2024. SEC. 5. The Legislature finds and declares that a special statute is necessary and that a general statute cannot be made applicable within the meaning of Section 16 of Article IV of the California Constitution because of the urgent and immediate need to provide fast food restaurant workers a living wage commensurate with rising costs of living, the large percentage of fast food restaurant workers living at or below the federal poverty line, and the significant number of fast food restaurant workers enrolled in the state’s safety net programs. SEC. 6. The Legislature finds and declares that establishing uniform statewide regulation of certain aspects of minimum wage for fast food restaurant workers, to the extent set forth in Section 3, is a matter of statewide concern. Therefore, Section 3 of this act adding Part 4.5.5 (commencing with Section 1474) to Division 2 of the Labor Code applies to all cities, including charter cities. SEC. 7. No reimbursement is required by this act pursuant to Section 6 of Article XIII B of the California Constitution for certain costs that may be incurred by a local agency or school district because, in that regard, this act creates a new crime or infraction, eliminates a crime or infraction, or changes the penalty for a crime or infraction, within the meaning of Section 17556 of the Government Code, or changes the definition of a crime within the meaning of Section 6 of Article XIII B of the California Constitution. However, if the Commission on State Mandates determines that this act contains other costs mandated by the state, reimbursement to local agencies and school districts for those costs shall be made pursuant to Part 7 (commencing with Section 17500) of Division 4 of Title 2 of the Government Code. [Chaptered text of AB 1228 (2023-2024), saved by browser from leginfo.legislature.ca.gov on 2026-09-30; the site's robots.txt disallows crawling.]