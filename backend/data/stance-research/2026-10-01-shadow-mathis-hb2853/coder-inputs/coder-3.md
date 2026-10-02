You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-10-01-shadow-mathis-hb2853/labels/coder-3.json. Write JSON only, matching
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

politician_id: a7675f41-2e50-413c-9864-8a64969f47f9  office_id: 60ec357f-3c1b-4b58-82e7-447dd47bc111
Christopher Mathis — State Representative, Arizona (seated, level: state)
Current term: 2023-01-02 (precision: day) to present
Earlier terms in this legislature: State Representative 2021-12-09 (precision: day) to 2023-01-09

## Topics (served ladder text — code against these words only)

### topic_key: school-vouchers
topic_id: 00b95a6a-75db-4521-b523-3326bba938de  served_revision_id: 88858826-90c0-41c9-a3a4-1d9f5b8c5307
Question: What role should vouchers and school choice play in the public education system?
  1. Eliminating voucher programs that divert taxpayer money from public schools to private institutions
  2. Opposing voucher programs and blocking their expansion, without moving to eliminate existing ones
  3. Allowing income-based voucher programs, open to a wider range of families under an income cap
  4. Expanding voucher eligibility to most families so parents can choose the school that best fits their child
  5. Providing universal vouchers so that education funding follows the student to any school — public, private, or religious — chosen by the family

#### Annex

# school-vouchers — annex (Season 2 served text; draft, not ruled)

**Orientation:** standard. Rung 1 is most restrictive of vouchers, rung 5 is universal.

**Levels:** state (the lever: program statutes), federal (tax-credit scholarships only), school
boards (no lever on vouchers). Verify against `compass_topic_roles` before use.

**Synonyms:** "education savings account" (ESA), "scholarship", "tax-credit scholarship",
"Choice Scholarship" (Indiana), "Utah Fits All".

1. **"Eliminating voucher programs that divert taxpayer money from public schools to private
   institutions"**
   - Clauses: [a] eliminate existing programs.
   - Evidence: a repeal bill, or a vote on a repeal amendment; own words calling for repeal.
   - Confused with 2 when the person only opposes an *expansion*.

2. **"Opposing voucher programs and blocking their expansion, without moving to eliminate existing
   ones"**
   - Clauses: [a] oppose expansion; [b] no repeal.
   - Evidence: a No on an expansion bill **plus** evidence against repeal (a No vote alone is only
     `direction-only`: it does not separate 1 from 2).

3. **"Allowing income-based voucher programs, open to a wider range of families under an income
   cap"**
   - Clauses: [a] means-tested; [b] a wider cap.
   - Evidence: authoring or voting for a means-tested program with a cap.

4. **"Expanding voucher eligibility to most families so parents can choose the school that best fits
   their child"**
   - Clauses: [a] most families, not all.
   - Evidence: an expansion bill with a high income cap, or a phased path to universal.
   - Confused with 5 when a phase-in ends in universal eligibility: code the end state the instrument
     enacts.

5. **"Providing universal vouchers so that education funding follows the student to any school —
   public, private, or religious — chosen by the family"**
   - Clauses: [a] universal; [b] any school, including religious.
   - Evidence: a universal ESA/voucher statute (e.g., Utah HB215, 2023).
   - **A federal tax-credit scholarship is not rung 5.** It is a tax credit to donors, not funding that
     follows the student. → `adjacent` (see the V4 omnibus example).

**Hard cases:** a vote on a budget that funds an existing program (`multi-subject`); a governor's
signature (a record; `chair-shaped` when the signed bill is single-subject).


## Sources

---
snapshot_id: de4a25eb-7ddc-596e-a3f4-9878a074a6b9
source_kind: public-record
url: https://apps.azleg.gov/BillStatus/BillOverview?SessionID=125&BillNumber=HB2853

Bill Status Inquiry. Bill History for HB2853. Short Title: Arizona empowerment scholarship accounts; appropriation. Sponsors: Toma (Prime with permission of Rules) Barton (Co-Sponsor) Biasiucci (Co-Sponsor) Blackman (Co-Sponsor) Bolick (Co-Sponsor) Bowers (Co-Sponsor) Burges (Co-Sponsor) Carroll (Co-Sponsor) Carter (Co-Sponsor) Chaplik (Co-Sponsor) Cobb (Co-Sponsor) Cook (Co-Sponsor) Diaz (Co-Sponsor) Dunn (Co-Sponsor) Fillmore (Co-Sponsor) Finchem (Co-Sponsor) Grantham (Co-Sponsor) Griffin (Co-Sponsor) Kaiser (Co-Sponsor) Kavanagh (Co-Sponsor) Martinez (Co-Sponsor) Nguyen (Co-Sponsor) Osborne (Co-Sponsor) Payne (Co-Sponsor) Pingerelli (Co-Sponsor) Weninger (Co-Sponsor) Wilmeth (Co-Sponsor) Governor Action 07/07/2022 Signed Chapter: 388 Chapter Version: House Engrossed [Bill overview for HB2853 (2022), saved by browser from apps.azleg.gov BillStatus on 2026-09-27.]

---
snapshot_id: e9e56d07-1b1d-5bd8-b284-2ea2381fed8f
source_kind: public-record
url: https://apps.azleg.gov/BillStatus/BillOverview?SessionID=125&BillNumber=HB2853#house-third

House Third Reading - HB2853 Arizona empowerment scholarship accounts; appropriation Action Date Action Vote 06/22/2022 Passed 31-26-3-0-0 Amended ABRAHAM N ANDRADE N BARTON Y BIASIUCCI Y BLACKMAN Y BLACKWATER-NYGREN N BOLDING N BOLICK Y BURGES Y BUTLER N CANO N CARROLL Y CARTER Y CHAPLIK Y CHÁVEZ N COBB Y COOK Y DALESSANDRO NV DEGRAZIA N DIAZ Y DUNN Y EPSTEIN N ESPINOZA N FERNANDEZ B N FILLMORE Y FINCHEM Y GRANTHAM Y GRIFFIN Y HERNANDEZ A N HERNANDEZ D NV HERNANDEZ M N HOFFMAN Y JERMAINE N JOHN Y KAISER Y KAVANAGH Y LIGUORI N LONGDON N MARTINEZ Y MATHIS N MEZA N NGUYEN Y OSBORNE Y PARKER Y PAWLIK N PAYNE Y PINGERELLI Y POWERS HANNLEY N QUIÑONEZ N SALMAN NV SCHWIEBERT N SHAH N SIERRA N SOLORIO N TOMA Y TSOSIE N UDALL Y WENINGER Y WILMETH Y BOWERS Y [Vote detail dialog for HB2853 (2022) House Third Reading, saved by browser from apps.azleg.gov BillStatus on 2026-09-27.]

---
snapshot_id: c4059cca-3b4f-51ae-bae8-673e487d5925
source_kind: public-record
url: https://www.azleg.gov/legtext/55leg/2R/laws/0388.htm

Chapter 0388 - 552R - H Ver of HB2853 House Engrossed Arizona empowerment scholarship accounts; appropriation State of Arizona House of Representatives Fifty-fifth Legislature Second Regular Session 2022 CHAPTER 388 HOUSE BILL 2853 An Act amending section 15-2401, Arizona Revised Statutes; amending title 15, chapter 19, article 1, Arizona Revised Statutes, by adding section 15-2401.01; amending sections 15-2402 and 15-2403, Arizona Revised Statutes; appropriating monies; relating to Arizona empowerment scholarship accounts. (TEXT OF BILL BEGINS ON NEXT PAGE) Be it enacted by the Legislature of the State of Arizona: Section 1. Section 15-2401, Arizona Revised Statutes, is amended to read: START_STATUTE 15-2401. Definitions In this chapter, unless the context otherwise requires: 1. "Annual education plan" means an initial individualized evaluation and subsequent annual reviews that are developed for a qualified student who meets the criteria specified in paragraph 7, subdivision (a), item (i), (ii) or (iii) of this section to determine ongoing annual eligibility through the school year in which the qualified student reaches twenty-two years of age and whether the student may be eligible pursuant to section 36-2981 and should be referred for eligibility determination. 2. "Curriculum" means a course of study for content areas or grade levels, including any supplemental materials required or recommended by the curriculum, approved by the department. 3. "Department" means the department of education. 4. "Eligible postsecondary institution" means a community college as defined in section 15-1401, a university under the jurisdiction of the Arizona board of regents or an accredited private postsecondary institution. 5. "Parent" means a resident of this state who is the parent, stepparent or legal guardian of a qualified student. 6. "Qualified school" means a nongovernmental primary or secondary school or a preschool for pupils with disabilities that is located in this state or, for qualified students who reside within the boundaries of an Indian reservation in this state, that is located in an adjacent state and that is within two miles of the border of the state in which the qualified student resides, and that does not discriminate on the basis of race, color or national origin. 7. "Qualified student" means a resident of this state who: (a) Is any of the following: (i) Identified as having a disability under section 504 of the rehabilitation act of 1973 (29 United States Code section 794). (ii) Identified by a school district or by an independent third party pursuant to section 15-2403, subsection [deleted: I] J as a child with a disability as defined in section 15-731 or 15-761. (iii) A child with a disability who is eligible to receive services from a school district under section 15-763. (iv) Attending a school or school district that was assigned a letter grade of D or F pursuant to section 15-241 for the most recent year in which letter grades were assigned or is currently eligible to attend kindergarten and resides within the attendance boundary of a school that was assigned a letter grade of D or F pursuant to section 15-241 for the most recent year in which letter grades were assigned. A child who meets the requirements of this item and who meets the income eligibility requirements for free and reduced-price lunches under the national school lunch and child nutrition acts (42 United States Code sections 1751 through 1793) is not subject to subdivision (b) of this paragraph. (v) A previous recipient of a scholarship issued pursuant to section 15-891 or this section, unless the qualified student's parent has been removed from eligibility in the program for failure to comply pursuant to section 15-2403, subsection C. (vi) A child of a parent who is a member of the armed forces of the United States and who is on active duty or was killed in the line of duty. A child who meets the requirements of this item is not subject to subdivision (b) of this paragraph. (vii) A child who is a ward of the juvenile court and who is residing with a prospective permanent placement pursuant to section 8-862 and the case plan is adoption or permanent guardianship. (viii) A child who was a ward of the juvenile court and who achieved permanency through adoption or permanent guardianship. (ix) A child who is the sibling of a current or previous Arizona empowerment scholarship account recipient or of an eligible qualified student who accepts the terms of and enrolls in an Arizona empowerment scholarship account. (x) A child who resides within the boundaries of an Indian reservation in this state as determined by the department of education or a tribal government. (xi) A child of a parent who is legally blind or deaf or hard of hearing as defined in section 36-1941. (b) And, except as provided in subdivision (a), items (iv) and (vi) of this paragraph, who meets any of the following requirements: (i) Attended a governmental primary or secondary school as a full-time student as defined in section 15-901 for at least forty-five days of the current or prior fiscal year and who transferred from a governmental primary or secondary school under a contract to participate in an Arizona empowerment scholarship account. Kindergarten students who are enrolled in Arizona online instruction must receive [deleted: two] one hundred hours of logged instruction to be eligible pursuant to this item. First, second and third grade students who are enrolled in Arizona online instruction must receive [deleted: four] two hundred hours of logged instruction to be eligible pursuant to this item. Fourth, fifth and sixth grade students who are enrolled in Arizona online instruction must receive [deleted: five] two hundred fifty hours of logged instruction to be eligible pursuant to this item. Seventh and eighth grade students who are enrolled in Arizona online instruction must receive [deleted: five] two hundred [deleted: fifty] seventy-five hours of logged instruction to be eligible pursuant to this item. High school students who are enrolled in Arizona online instruction must receive [deleted: five] two hundred fifty hours of logged instruction to be eligible pursuant to this item. (ii) Previously participated in an Arizona empowerment scholarship account. (iii) Received a scholarship under section 43-1505 and who continues to attend a qualified school if the student attended a governmental primary or secondary school as a full-time student as defined in section 15-901 for at least ninety days of the prior fiscal year or one full semester before attending a qualified school. (iv) Was eligible for an Arizona scholarship for pupils with disabilities and received monies from a school tuition organization pursuant to section 43-1505 or received an Arizona scholarship for pupils with disabilities but did not receive monies from a school tuition organization pursuant to section 43-1505 and who continues to attend a qualified school if the student attended a governmental primary or secondary school as a full-time student as defined in section 15-901 for at least ninety days of the prior fiscal year or one full semester before attending a qualified school. ( v ) Attended a nonpublic school for pupils with disabilities in the prior year if placement at the school was approved by the department of education and contracted for by a public school district. [deleted: (v)] ( vi ) Has not previously attended a governmental primary or secondary school but is currently eligible to enroll in a kindergarten program in a school district or charter school in this state or attended a program for preschool children with disabilities. For the purposes of this item, a child is eligible to enroll in a kindergarten program if the child is at least five years of age on January 1 of the current school year, is under seven years of age, has not already completed a kindergarten program and is not enrolled in grade one of a private or governmental school in the current year. [deleted: (vi)] ( vii ) Has not previously attended a governmental primary or secondary school but is currently eligible to enroll in a program for preschool children with disabilities in this state. 8. "Treasurer" means the office of the state treasurer. END_STATUTE Sec. 2. Title 15, chapter 19, article 1, Arizona Revised Statutes, is amended by adding section 15-2401.01, to read: START_STATUTE 15-2401.01. Definition of qualified student for Arizona empowerment scholarship accounts; expansion Notwithstanding section 15-2401, beginning in the 2022-2023 school year, in this chapter, unless the context otherwise requires, "qualified student" includes a resident of this state who both: 1. Is eligible to enroll in a public school in this state in any of the following: ( a ) A preschool program for children with disabilities. ( b ) A kindergarten program. ( c ) Any of grades one through twelve. 2. Does not otherwise qualify for an Arizona empowerment scholarship account pursuant to this chapter. END_STATUTE Sec. 3. Section 15-2402, Arizona Revised Statutes, is amended to read: START_STATUTE 15-2402 . Arizona empowerment scholarship accounts; funds A. Arizona empowerment scholarship accounts are established to provide options for the education of students in this state. B. To enroll a qualified student for an Arizona empowerment scholarship account, the parent of the qualified student must sign an agreement to do all of the following: 1. Use a portion of the Arizona empowerment scholarship account monies allocated annually to provide an education for the qualified student in at least the subjects of reading, grammar, mathematics, social studies and science, unless the Arizona empowerment scholarship account is allocated monies according to a transfer schedule other than quarterly transfers pursuant to section 15-2403, subsection [deleted: F] G . 2. Not enroll the qualified student in a school district or charter school and release the school district from all obligations to educate the qualified student. This paragraph does not : ( a ) Relieve the school district or charter school that the qualified student previously attended from the obligation to conduct an evaluation pursuant to section 15-766. ( b ) Require a qualified student to withdraw from a school district or charter school before enrolling for an Arizona empowerment scholarship account if the qualified student withdraws from the school district or charter school before receiving any monies in the qualified student's Arizona empowerment scholarship account. ( c ) Prevent a qualified student from applying in advance for an Arizona empowerment scholarship account to be funded beginning the following school year. 3. Not accept a scholarship from a school tuition organization pursuant to title 43 concurrently with an Arizona empowerment scholarship account for the qualified student in the same year a parent signs the agreement pursuant to this section. 4. Use monies deposited in the qualified student's Arizona empowerment scholarship account only for the following expenses of the qualified student: (a) Tuition or fees at a qualified school. (b) Textbooks required by a qualified school. (c) If the qualified student meets any of the criteria specified in section 15-2401, paragraph 7, subdivision (a), item (i), (ii) or (iii) as determined by a school district or by an independent third party pursuant to section 15-2403, subsection [deleted: I] J , the qualified student may use the following additional services: (i) Educational therapies from a licensed or accredited practitioner or provider, including and up to any amount not covered by insurance if the expense is partially paid by a health insurance policy for the qualified student. (ii) A licensed or accredited paraprofessional or educational aide. (iii) Tuition for vocational and life skills education approved by the department. (iv) Associated goods and services that include educational and psychological evaluations, assistive technology rentals and braille translation goods and services approved by the department. (d) Tutoring or teaching services provided by an individual or facility accredited by a state, regional or national accrediting organization. (e) Curricula and supplementary materials. (f) Tuition or fees for a nonpublic online learning program. (g) Fees for a nationally standardized norm-referenced achievement test, an advanced placement examination or any exams related to college or university admission. (h) Tuition or fees at an eligible postsecondary institution. (i) Textbooks required by an eligible postsecondary institution. (j) Fees to manage the Arizona empowerment scholarship account. (k) Services provided by a public school, including individual classes and extracurricular programs. (l) Insurance or surety bond payments. (m) Uniforms purchased from or through a qualified school. (n) If the qualified student meets the criteria specified in section 15-2401, paragraph 7, subdivision (a), item (i), (ii) or (iii) and if the qualified student is in the second year prior to the final year of a contract executed pursuant to this article, costs associated with an annual education plan conducted by an independent evaluation team. The department shall prescribe minimum qualifications for independent evaluation teams pursuant to this subdivision and factors that teams must use to determine whether the qualified student shall be eligible to continue to receive monies pursuant to this article through the school year in which the qualified student reaches twenty-two years of age. An independent evaluation team that provides an annual education plan pursuant to this subdivision shall submit a written report that summarizes the results of the evaluation to the parent of the qualified student and to the department on or before July 31. The written report submitted by the independent evaluation team is valid for one year. If the department determines that the qualified student meets the eligibility criteria prescribed in the annual education plan, the qualified student is eligible to continue to receive monies pursuant to this article until the qualified student reaches twenty-two years of age, subject to annual review. A parent may appeal the department's decision pursuant to title 41, chapter 6, article 10. As an addendum to a qualified student's final-year contract, the department shall provide the following written information to the parent of the qualified student: (i) That the qualified student will not be eligible to continue to receive monies pursuant to this article unless the results of an annual education plan conducted pursuant to this subdivision demonstrate that the qualified student meets the eligibility criteria prescribed in the annual education plan. (ii) That the parent is entitled to obtain an annual education plan pursuant to this subdivision to determine whether the qualified student meets the eligibility criteria prescribed in the annual education plan. (iii) A list of independent evaluation teams that meet the minimum qualifications prescribed by the department pursuant to this subdivision. ( o ) Public transportation services in this state, including a commuter pass for the qualified student, or transportation network services as defined in section 28-9551 between the qualified student's residence and a qualified school in which the qualified student is enrolled. ( p ) Computer hardware and technological devices primarily used for an educational purpose. For the purposes of this subdivision, "computer hardware and technological devices": ( i ) Includes calculators, personal computers, laptops, tablet devices, microscopes, telescopes and printers. ( ii ) Does not include entertainment and other primarily noneducational devices, including televisions, telephones, video game consoles and accessories, and home theatre and audio equipment. 5. Not file an affidavit of intent to homeschool pursuant to section 15-802, subsection B, paragraph 2 or 3. 6. Not use monies deposited in the qualified student's account for any of the following: (a) Computer hardware or other technological devices, except as otherwise allowed under paragraph 4, subdivision (c) or ( p ) of this subsection. (b) Transportation of the pupil , except for transportation services described in paragraph 4, subdivision ( o ) of this subsection . [deleted: (c) Consumable educational supplies, including paper, pens or markers.] C. In exchange for the parent's agreement pursuant to subsection B of this section, the department shall transfer from the monies that would otherwise be allocated to a recipient's prior school district, or if the child is currently eligible to attend a preschool program for children with DISABILITIES, a kindergarten program or any of grades one through twelve , the monies that the department determines would otherwise be allocated to a recipient's expected school district of attendance, to the treasurer for deposit into an Arizona empowerment scholarship account an amount that is equivalent to ninety percent of the sum of the base support level and additional assistance prescribed in sections 15-185 and 15-943 for that particular student if that student were attending a charter school. D. The department of education empowerment scholarship account fund is established consisting of monies appropriated by the legislature. The department shall administer the fund. Monies in the fund are subject to legislative appropriation. Monies in the fund shall be used for the department's costs in administering Arizona empowerment scholarship accounts under this chapter. Monies in the fund are exempt from the provisions of section 35-190 relating to lapsing of appropriations. If the number of Arizona empowerment scholarship accounts significantly increases after fiscal year 2020-2021, the department may request an increase in the amount appropriated to the fund in any subsequent fiscal year in the budget estimate submitted pursuant to section 35-113. The department shall list monies in the fund as a separate line item in its budget estimate. E. The state treasurer empowerment scholarship account fund is established consisting of monies appropriated by the legislature. The state treasurer shall administer the fund. Monies in the fund shall be used for the state treasurer's costs in administering the Arizona empowerment scholarship accounts under this chapter. If the number of Arizona empowerment scholarship accounts significantly increases after fiscal year 2020-2021, the state treasurer may request an increase in the amount appropriated to the fund in any subsequent fiscal year in the budget estimate submitted pursuant to section 35-113. Monies in the fund are subject to legislative appropriation. Monies in the fund are exempt from the provisions of section 35-190 relating to lapsing of appropriations. The state treasurer shall list monies in the fund as a separate line item in its budget estimate. F. A parent must renew the qualified student's Arizona empowerment scholarship account on an annual basis. G. Notwithstanding any changes to the student's multidisciplinary evaluation team plan, a student who has previously qualified for an Arizona empowerment scholarship account remains eligible to apply for renewal until the student finishes high school. H. If a parent does not renew the qualified student's Arizona empowerment scholarship account for a period of three academic years, the department shall notify the parent that the qualified student's account will be closed in sixty calendar days. The notification must be sent through certified mail, email and telephone, if applicable. The parent has sixty calendar days to renew the qualified student's Arizona empowerment scholarship account. If the parent chooses not to renew or does not respond in sixty calendar days, the department shall close the account and any remaining monies shall be returned to the state. I. A signed agreement under this section constitutes school attendance required by section 15-802. J. A qualified school or a provider of services purchased pursuant to subsection B, paragraph 4 of this section may not share, refund or rebate any Arizona empowerment scholarship account monies with the parent or qualified student in any manner. K. Notwithstanding subsection H of this section, on the qualified student's graduation from a postsecondary institution or after any period of four consecutive years after high school graduation in which the student is not enrolled in an eligible postsecondary institution, but not before this time as long as the account holder continues using a portion of account monies for eligible expenses each year and is in good standing, the qualified student's Arizona empowerment scholarship account shall be closed and any remaining monies shall be returned to the state. L. Monies received pursuant to this article do not constitute taxable income to the parent of the qualified student. END_STATUTE Sec. 4. Section 15-2403, Arizona Revised Statutes, is amended to read: START_STATUTE 15-2403 . Arizona empowerment scholarship accounts; administration; appeals; audit; rules; policy handbook A. The treasurer may contract with private financial management firms to manage Arizona empowerment scholarship accounts. B. The department shall conduct or contract for annual audits of Arizona empowerment scholarship accounts to ensure compliance with section 15-2402, subsection B, paragraph 4. The department shall also conduct or contract for random, quarterly and annual audits of Arizona empowerment scholarship accounts as needed to ensure compliance with section 15-2402, subsection B, paragraph 4. C. The department may remove any parent or qualified student from eligibility for an Arizona empowerment scholarship account if the parent or qualified student fails to comply with the terms of the contract or applicable laws, rules or orders or knowingly misuses monies or knowingly fails to comply with the terms of the contract with intent to defraud and shall notify the treasurer. The department shall notify the treasurer to suspend the account of a parent or qualified student and shall notify the parent or qualified student in writing that the account has been suspended and that no further transactions will be allowed or disbursements made. The notification shall specify the reason for the suspension and state that the parent or qualified student has [deleted: ten] fifteen days, not including weekends, to respond and take corrective action. If the parent or qualified student refuses or fails to contact the department, furnish any information or make any report that may be required for reinstatement within the [deleted: ten-day] fifteen-day period, the department may remove the parent or qualified student pursuant to this subsection. D. A parent may appeal to the state board of education any administrative decision the department makes pursuant to this article, including determinations of allowable expenses, removal from the program or enrollment eligibility. The department shall notify the parent in writing that the parent may appeal any administrative decision under this article and the process by which the parent may appeal at the same time the department notifies the parent of an administrative decision under this article. The state board of education shall establish an appeals process, and the department shall post this information on the department's website in the same location as the policy handbook developed pursuant to subsection [deleted: J] K of this section. E. A parent may represent himself or herself or designate a representative, not necessarily an attorney, before any appeals hearing held pursuant to this section. Any such designated representative who is not an attorney admitted to practice may not charge for any services rendered in connection with such a hearing. The fact that a representative participated in the hearing or assisted the account holder is not grounds for reversing any administrative decision or order if the evidence supporting the decision or order is substantial, reliable and probative. [deleted: E.] F. The state board of education may refer cases of substantial misuse of monies to the attorney general for the purpose of collection or for the purpose of a criminal investigation if the state board of education obtains evidence of fraudulent use of an account. [deleted: F.] G. The department shall make quarterly transfers of the amount calculated pursuant to section 15-2402, subsection C to the treasurer for deposit in the Arizona empowerment scholarship account of each qualified student, except the department may make transfers according to another transfer schedule if the department determines a transfer schedule other than quarterly transfers is necessary to operate the Arizona empowerment scholarship account. [deleted: G.] H. The department shall accept applications between July 1 and June 30 of each year. The department shall enroll and issue an award letter to eligible applicants within thirty days after receipt of a completed application and all required documentation. On or before May 30 of each year, the department shall furnish to the joint legislative budget committee an estimate of the amount required to fund Arizona empowerment scholarship accounts for the following fiscal year. The department shall include in its budget request for the following fiscal year the amount estimated pursuant to section 15-2402, subsection C for each qualified student. [deleted: H.] I. The state board of education may adopt rules and policies necessary to administer Arizona empowerment scholarship accounts, including rules and policies: 1. For establishing an appeals process pursuant to subsection D of this section. 2. For conducting or contracting for examinations of the use of account monies. 3. For conducting or contracting for random, quarterly and annual reviews of accounts. 4. For establishing or contracting for the establishment of an online anonymous fraud reporting service. 5. For establishing an anonymous telephone hotline for fraud reporting. 6. That require a surety bond or insurance for account holders. [deleted: I.] J. The department shall contract with an independent third party for the purposes of determining whether a qualified student is eligible to receive educational therapies or services pursuant to section 15-2402, subsection B, paragraph 4, subdivision (c). If during any period on or after January 1, 2023 the department fails to ensure that a contract with an independent third party is in effect, during that period: 1. The county school superintendent of each county may approve a list of independent third parties within the county whose evaluation may be used to determine whether a student who resides within the county is eligible to receive educational therapies or services pursuant to section 15-2402, subsection B, paragraph 4, subdivision ( c ). 2. If the county school superintendent of a county does not provide a list of approved independent third parties within ninety days after the beginning of any period during which the department does not have a contract with an independent third party in effect as described in this subsection, the parent of a student who resides within the county has the right to obtain an independent educational evaluation from a qualified examiner to determine whether the student is eligible to receive educational therapies or services pursuant to section 15-2402, subsection B, paragraph 4, subdivision ( c ). The expense for an educational evaluation undertaken pursuant to this paragraph shall be provided by the school district within which the student resides and that serves the grade level of the student. For the purposes of this paragraph, "qualified examiner" means a licensed physician, psychiatrist or psychologist. [deleted: J.] K. On or before July 1 of each year, the department shall develop an applicant and participant handbook that includes information relating to policies and processes of Arizona empowerment scholarship accounts. The policy handbook shall comply with the rules adopted by the state board of education pursuant to this section. The department shall post the handbook on its website. [deleted: K.] L. Except for cases in which the attorney general determines that a parent or account holder has committed fraud, any expenditure from an Arizona empowerment scholarship account for a purchase that is deemed ineligible pursuant to section 15-2402 and that is subsequently repaid by the parent or account holder shall be credited back to the Arizona empowerment scholarship account balance within thirty days after the receipt of payment. [deleted: L.] M. If, in response to an appeal of an administrative decision made by the department, the state board of education issues a stay of an Arizona empowerment scholarship account suspension pursuant to rules adopted by the board, the department may not withhold funding or contract renewal for the account holder on account of the appealed administrative decision during the stay unless directed by the board to do so. END_STATUTE Sec. 5. Appropriation; department of education; Arizona empowerment scholarship accounts In addition to any other appropriations made in fiscal year 2022-2023 to the department of education, the sum of $2,200,000 and twenty-six FTE positions are appropriated from the state general fund in fiscal year 2022-2023 to the department of education for the purposes of administering Arizona empowerment scholarship accounts under title 15, chapter 19, Arizona Revised Statutes. Sec. 6. Retroactivity This act applies retroactively to from and after June 30, 2022. APPROVED BY THE GOVERNOR JULY 7, 2022. FILED IN THE OFFICE OF THE SECRETARY OF STATE JULY 7, 2022.