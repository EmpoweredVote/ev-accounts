You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/clever-leakey-bd9943/backend/data/stance-research/2026-10-01-shadow-soliday-hb1007/labels/coder-2.json. Write JSON only, matching
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

politician_id: 79bb9e5a-a74a-44ef-a1c4-5b956ad36e5e  office_id: 5f584301-def4-4b05-bba8-e017dc2273e0
Edmond Soliday — Representative, Indiana (seated, level: state)
Current term: 2006-11-08 (precision: day) to present

## Topics (served ladder text — code against these words only)

### topic_key: data-centers
topic_id: 4559b513-0fd8-4ed1-babd-f3b554162f40  served_revision_id: c48a03d6-b972-4f27-9a8a-d41b07f4a929
Question: How should government manage the growth of large-scale data centers?
  1. Imposing a moratorium on new data center construction until energy infrastructure can support demand without raising costs for residential ratepayers
  2. Barring utilities from passing any data center energy infrastructure costs to residential customers
  3. Allowing data center development with impact assessments, energy cost-sharing agreements, and community benefit requirements before approval
  4. Encouraging data center development through streamlined permitting while requiring transparency about projected energy demand and rate impacts
  5. Welcoming data center investment with minimal regulatory barriers, trusting that economic growth and tax revenue will benefit all residents

#### Annex

(no annex for this topic yet — apply the codebook alone)

## Sources

---
snapshot_id: 206911f6-16c7-55c4-b0a9-47b94c4c0cf1
source_kind: public-record
url: https://iga.in.gov/legislative/2025/bills/house/1007/details

IGA | House Bill 1007 (2025) Indiana General Assembly 2025 Session. House Bill 1007 Energy generation resources. Enrolled House Bill (H) Authored by: Rep. Edmond Soliday. Co-Authored by: Rep. Alaina Shonkwiler, Rep. Jim Pressel, Rep. Steve Bartels, Rep. Ryan Lauer, Rep. Robert Heaton, Rep. Chris May, Rep. Jim Lucas, Rep. Hunter Smith, Rep. Dale DeVon, Rep. Michael Karickhoff, Rep. Dave Heine, Rep. Ben Smaltz, Rep. Jake Teshka, Rep. Craig Snow, Rep. Jack Jordan, Rep. Jeffrey Thompson, Rep. Gregory Steuerwald, Rep. Julie Olthoff, Rep. Alex Zimmerman, Rep. Craig Haggard, Rep. Mike Aylesworth, Rep. Doug Miller, Rep. Matt Commons, Rep. Chris Judy, Rep. Dave Hall, Rep. Matt Lehman, Rep. J.D. Prescott, Rep. Kendell Culp, Rep. Bruce Borders, Rep. Beau Baird, Rep. Timothy Wesco, Rep. Danny Lopez, Rep. Martin Carbaugh, Rep. Wendy McNamara, Rep. Chris Jeter, Rep. David Abbott. Sponsored by: Sen. Eric Koch, Sen. Linda Rogers, Sen. Daryl Schmitt, Sen. David Niezgodski. Digest Provides a credit against state tax liability for expenses incurred in the manufacture of a small modular nuclear reactor (SMR) in Indiana. Establishes procedures under which certain energy utilities may request approval for one or more of the following from the Indiana utility regulatory commission (IURC): (1) An expedited generation resource plan (EGR plan) to meet customer load growth that exceeds a specified threshold. (2) A generation resource submittal for the acquisition of a specific generation resource in accordance with an approved EGR plan. (3) A project to serve one or more large load customers. Latest Bill Actions: H 05/06/2025 Public Law 217. H 05/06/2025 Signed by the Governor. [Bill details for HB 1007 (2025), saved by browser from iga.in.gov on 2026-10-01.]

---
snapshot_id: fb024c22-ae9a-5f57-b04e-bbe4fc13fc69
source_kind: public-record
url: https://iga.in.gov/pdf-documents/124/2025/house/bills/HB1007/HB1007.08.ENRS.pdf

First Regular Session of the 124th General Assembly (2025) PRINTING CODE. Amendments: Whenever an existing statute (or a section of the Indiana Constitution) is being amended, the text of the existing provision will appear in this style type, additions will appear in this style type , and deletions will appear in [deleted: this style type.] Additions: Whenever a new statutory provision is being enacted (or a new constitutional provision adopted), the text of the new provision will appear in this style type . Also, the word NEW will appear in that style type in the introductory clause of each SECTION that adds a new provision to the Indiana Code or the Indiana Constitution. Conflict reconciliation: Text in a statute in this style type or [deleted: this style type] reconciles conflicts between statutes enacted by the 2024 Regular Session of the General Assembly. HOUSE ENROLLED ACT No. 1007 AN ACT to amend the Indiana Code concerning utilities. Be it enacted by the General Assembly of the State of Indiana: SECTION 1. IC 6-3.1-45 IS ADDED TO THE INDIANA CODE AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE JANUARY 1, 2025 (RETROACTIVE)]: Chapter 45. Small Modular Nuclear Reactor Manufacturing Expense Tax Credit Sec. 1. This chapter applies to a taxable year beginning after December 31, 2024. Sec. 2. As used in this chapter, "department" refers to the department of state revenue. Sec. 3. As used in this chapter, "qualified investment" means a taxpayer's expenditures incurred in the manufacture of a small modular nuclear reactor in Indiana. Sec. 4. As used in this chapter, "small modular nuclear reactor" means a nuclear reactor that: (1) has a rated electric generating capacity of not more than four hundred seventy (470) megawatts; (2) is capable of being constructed and operated, either: (A) alone; or (B) in combination with one (1) or more similar reactors if additional reactors are, or become, necessary; at a single site; and HEA 1007 — Concur 2 (3) is required to be licensed by the United States Nuclear Regulatory Commission. The term includes a nuclear reactor that is described in this section and that uses a process to produce hydrogen that can be used for energy storage, as a fuel, or for other uses. Sec. 5. As used in this chapter, "state tax liability" means a taxpayer's total tax liability that is incurred under: (1) IC 6-3-1 through IC 6-3-7 (the adjusted gross income tax); (2) IC 6-5.5 (the financial institutions tax); and (3) IC 27-1-18-2 (the insurance premiums tax); as computed after the application of the credits that under IC 6-3.1-1-2 are to be applied before the credit provided by this chapter. Sec. 6. As used in this chapter, "taxpayer" means a person, corporation, partnership, or other entity that makes a qualified investment. Sec. 7. A taxpayer is entitled to a credit against the taxpayer's state tax liability in the taxable year in which the taxpayer makes a qualified investment. The amount of the credit provided by this section is equal to twenty percent (20%) of the amount of the taxpayer's qualified investment. Sec. 8. (a) If the amount determined under section 7 of this chapter for a taxpayer in a taxable year exceeds the taxpayer's state tax liability for that taxable year, the taxpayer may carry the excess over to the following taxable years. The amount of the credit carryover from a taxable year shall be reduced to the extent that the carryover is used by the taxpayer to obtain a credit under this chapter for any subsequent taxable year. (b) A taxpayer is not entitled to a carryback or refund of any unused credit. Sec. 9. (a) If a pass through entity is entitled to a credit under section 7 of this chapter but does not have state tax liability against which the tax credit may be applied, an individual who is a shareholder, partner, or member of the pass through entity is entitled to a tax credit equal to: (1) the tax credit determined for the pass through entity for the taxable year; multiplied by (2) the percentage of the pass through entity's distributive income to which the shareholder, partner, or member is entitled. (b) The credit provided under subsection (a) is in addition to a tax credit to which a shareholder, partner, or member of a pass HEA 1007 — Concur 3 through entity is otherwise entitled under this chapter. However, a pass through entity and an individual who is a shareholder, partner, or member of the pass through entity may not claim more than one (1) credit for the same qualified investment. Sec. 10. To receive the credit provided by this chapter, a taxpayer must claim the credit on the taxpayer's annual state tax return or returns in the manner prescribed by the department. The taxpayer shall submit to the department: (1) information verifying that the taxpayer's qualified investment was made with respect to a small modular nuclear reactor that will be manufactured in Indiana; and (2) all information that the department determines is necessary for the calculation of the credit provided by this chapter. SECTION 2. IC 8-1-7.9 IS ADDED TO THE INDIANA CODE AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE UPON PASSAGE]: Chapter 7.9. Expedited Generation Resource Plans and Large Load Customers Sec. 1. (a) As used in this chapter, "acquisition" means a project or an arrangement that is undertaken: (1) by an energy utility to construct, purchase, lease, or otherwise acquire a generation resource; and (2) in accordance with an approved EGR plan. (b) The term includes the purchase of energy or capacity through a power purchase agreement. Sec. 2. As used in this chapter, "acquisition costs" means the total costs of an acquisition made under an EGR plan, including: (1) planning; (2) construction; and (3) operating; costs related to the acquisition. Sec. 3. As used in this chapter, "appropriate regional transmission organization" has the meaning set forth in IC 8-1-8.5-13(b). Sec. 4. As used in this chapter, "commission" refers to the Indiana utility regulatory commission created by IC 8-1-1-2. Sec. 5. (a) As used in this chapter, "construction and operating costs" means costs: (1) incurred or to be incurred by an energy utility under this chapter after the issuance of an order by the commission under this chapter; and HEA 1007 — Concur 4 (2) related to an approved or commission modified acquisition or project. (b) The term includes procurement, contractual, construction, operating, maintenance, financing, legal, regulatory, and project evaluation, analysis, and development costs incurred after the issuance of an order by the commission under this chapter. Sec. 6. As used in this chapter, "corporation" refers to the Indiana economic development corporation established by IC 5-28-3-1 or its successor. Sec. 7. As used in this chapter, "energy utility" means: (1) an electric utility listed in 170 IAC 4-7-2(a) and any successor in interest to that utility; or (2) a corporation organized under IC 8-1-13. Sec. 8. As used in this chapter, "expedited generation resource plan", or "EGR plan", means a plan developed by an energy utility for acquiring generation resources to meet load growth that exceeds the lesser of: (1) five percent (5%) of the energy utility's average peak demand over the most recent three (3) calendar years; or (2) one hundred fifty (150) megawatts. Sec. 9. As used in this chapter, "generation resource submittal" means a compliance filing made to the commission for approval of the acquisition of a specific generation resource in accordance with the criteria set forth in an approved EGR plan. Sec. 10. As used in this chapter, "large load customer" means a new or existing customer of an energy utility, or not more than four (4) multiple new or existing customers of an energy utility, that: (1) requests new or additional electricity demand that in the aggregate exceeds the lesser of: (A) five percent (5%) of the energy utility's average peak demand over the most recent three (3) calendar years; or (B) one hundred fifty (150) megawatts; (2) plans to make a capital investment that exceeds five hundred million dollars ($500,000,000) in a new or expanded facility in Indiana; and (3) plans to employ at the new or expanded facility in Indiana at least fifty (50) full-time employees with wages that on average meet or exceed the most recently published annual national average according to the Bureau of Labor Statistics of the United States Department of Labor. Sec. 11. As used in this chapter, "office" refers to the Indiana HEA 1007 — Concur 5 office of energy development established by IC 4-3-23-3. Sec. 12. (a) As used in this chapter, "planning costs" means costs: (1) incurred or to be incurred by an energy utility before the issuance of an order by the commission under this chapter; and (2) related to an acquisition or project. (b) The term includes study, analysis, pre-engineering, engineering, legal, financing, and regulatory costs. Sec. 13. As used in this chapter, "pre-filing meeting" means a meeting to review and discuss a filing or submittal by an energy utility in accordance with: (1) section 18 of this chapter; (2) section 20 of this chapter; or (3) section 22 of this chapter; as applicable. Sec. 14. As used in this chapter, "project" refers to a project relating to energy infrastructure and generation resources that: (1) are required primarily to serve a large load customer of an energy utility; and (2) may be designed to serve more than one (1) large load customer of the energy utility or to meet other customer demand or energy needs. Sec. 15. As used in this chapter, "project costs" means the total costs of a project, including: (1) planning costs; and (2) construction and operating costs; related to the project. Sec. 16. As used in this chapter, "reasonable risk premium" means compensation: (1) negotiated between an energy utility and a large load customer; and (2) paid by the large load customer. Sec. 17. (a) The commission may expedite, in accordance with this chapter, the review of filings and submittals made by an energy utility to meet the energy infrastructure and generation resource needs of customers. An energy utility may request an expedited review by the commission under either or both of the following: (1) Sections 18 through 21 of this chapter (concerning EGR plans). (2) Sections 22 through 24 of this chapter (concerning large HEA 1007 — Concur 6 load customer projects). (b) This chapter does not preclude an energy utility from petitioning the commission under other applicable statutes for approval of a generation resource acquisition to meet the needs of its customers. (c) This chapter does not preclude an energy utility from petitioning the commission under, or in conjunction with, other applicable statutes, including: (1) IC 8-1-2-24; (2) IC 8-1-2-42; (3) IC 8-1-2.5; (4) IC 8-1-8.5; (5) IC 8-1-8.8; or (6) IC 8-1-39; for approval of a project to meet the needs of large load customers. Sec. 18. (a) This section applies to an energy utility that petitions the commission for approval of an EGR plan. (b) An energy utility may file a petition with the commission for approval of an EGR plan to acquire generation resources to meet the extraordinary needs for electricity by the energy utility's customers. (c) In a petition under this section, an energy utility must do the following: (1) Describe the energy utility's EGR plan for acquiring generation resources to meet the anticipated extraordinary growth in the load of its customers. (2) Demonstrate a need for generation capacity that exceeds the lesser of: (A) five percent (5%) of the energy utility's average peak demand over the most recent three (3) calendar years; or (B) one hundred fifty (150) megawatts. (3) Provide a load growth forecast for a minimum of five (5) years from the date of the petition. (4) Describe the status of customer contracts and commitments that support the load growth forecast described in subdivision (3). (5) Explain how the EGR plan is consistent with or differs from the energy utility's most recent integrated resource plan. (6) Propose the accounting authority needed from the commission to support the EGR plan. (7) Propose the manner in which the capital costs and operating and maintenance expenses related to the EGR plan HEA 1007 — Concur 7 will be included in the energy utility's revenue requirement. (8) Identify the type and amount of capacity and energy: (A) that is included in the EGR plan; (B) that does not exceed seventy-five percent (75%) of the energy utility's peak capacity over the forecast period described in subdivision (3); and (C) with respect to which the energy utility may request expedited approval in a subsequent generation resource submittal. (9) Identify the criteria to be included in a generation resource submittal that must be met for the acquisition to be approved by the commission. (10) Certify that at least thirty (30) days before the filing of the petition the energy utility held a pre-filing meeting with the commission and the office of utility consumer counselor to review the EGR plan. (11) Describe how the energy utility considered implementing grid enhancing technologies to defer or minimize the need for additional investment in generation. (12) Describe how the EGR plan will support the provision of electric utility service with the attributes set forth in IC 8-1-2-0.6, including: (A) reliability; (B) affordability; (C) resiliency; (D) stability; and (E) environmental sustainability. (13) Describe how the EGR plan reasonably protects existing and future customers and is consistent with: (A) the provision of safe, reliable, and affordable electric utility service; and (B) economical rates. (14) Include: (A) verified testimony; and (B) exhibits; supporting the petition and constituting the energy utility's case in chief. (15) Include a proposed order for the petition. Sec. 19. (a) This section applies to an energy utility that petitions the commission for approval of an EGR plan. (b) Notwithstanding IC 8-1-8.5 or any other statute, the commission may approve an energy utility's EGR plan to HEA 1007 — Concur 8 construct, purchase, lease, or otherwise acquire generation resources under this chapter for purposes of meeting the needs of the energy utility's customers. The commission shall make its decision based on whether the relief requested is just, reasonable, and in the public interest. (c) The commission may: (1) approve the energy utility's petition in its entirety; (2) deny the energy utility's petition in its entirety; or (3) modify the petition, subject to the energy utility's acceptance of the modification. (d) The commission shall issue a final order on the petition not later than ninety (90) days after receiving the energy utility's complete petition. A petition is considered: (1) complete unless the commission provides a notice of deficiency to the energy utility not later than five (5) business days after the filing of the petition; and (2) approved if the commission does not issue a final order on the petition within the ninety (90) day period set forth in this subsection. Sec. 20. (a) This section applies to an energy utility that submits to the commission for approval a generation resource submittal in accordance with an approved EGR plan. (b) An energy utility may submit a generation resource submittal to the commission for approval of an acquisition that the energy utility intends to make in accordance with an approved EGR plan. (c) In a generation resource submittal under this section, an energy utility must do the following: (1) Describe: (A) the type of technology used in the generation resource to be acquired; (B) the amount of capacity and energy to be acquired; (C) key contractual terms for the acquisition; and (D) the estimated acquisition costs. (2) Demonstrate that the acquisition meets the criteria set forth in the energy utility's approved EGR plan. (3) Explain how the acquisition is consistent with or differs from the energy utility's most recent integrated resource plan. (4) Detail the status of customer contracts and commitments that support the acquisition. (5) Certify that at least thirty (30) days before the filing of the generation resource submittal the energy utility held a HEA 1007 — Concur 9 pre-filing meeting with the commission and the office of utility consumer counselor to review the acquisition. (6) Describe how the energy utility considered implementing grid enhancing technologies to defer or minimize the need for additional investment in generation. (7) Describe how the acquisition will support the provision of electric utility service with the attributes set forth in IC 8-1-2-0.6, including: (A) reliability; (B) affordability; (C) resiliency; (D) stability; and (E) environmental sustainability. (8) Describe how the acquisition reasonably protects existing and future customers and is consistent with: (A) the provision of safe, reliable, and affordable electric utility service; and (B) economical rates. (9) Include supporting affidavits and exhibits. (10) Include a proposed order for the submittal. Sec. 21. (a) This section applies to an energy utility that submits to the commission for approval a generation resource submittal in accordance with an approved EGR plan. (b) Notwithstanding IC 8-1-8.5 or any other statute, the commission may approve an energy utility's generation resource submittal to construct, purchase, lease, or otherwise acquire generation resources under this chapter for purposes of meeting the needs of the energy utility's customers. The commission shall make its decision based solely on whether the submittal meets the criteria and requirements set forth in the energy utility's approved EGR plan. (c) The commission may: (1) approve the energy utility's generation resource submittal in its entirety; (2) deny the energy utility's generation resource submittal in its entirety; or (3) modify the energy utility's generation resource submittal, subject to the energy utility's acceptance of the modification. (d) The commission shall issue a final order on the energy utility's generation resource submittal not later than: (1) sixty (60) days after receiving the energy utility's complete generation resource submittal, if the acquisition is a clean HEA 1007 — Concur 10 energy project (as defined in IC 8-1-8.8-2); or (2) one hundred twenty (120) days after receiving the energy utility's complete generation resource submittal, if the acquisition would otherwise require a certificate under IC 8-1-8.5-2. A generation resource submittal is considered complete unless the commission provides a notice of deficiency to the energy utility not later than five (5) business days after the filing of the generation resource submittal. A generation resource submittal is considered approved if the commission does not issue a final order on the generation resource submittal within the period set forth in subdivision (1) or (2), as applicable. Sec. 22. (a) This section applies to an energy utility that petitions the commission for approval of a project to serve a large load customer. (b) An energy utility may submit to the commission a petition for approval of a project to serve a large load customer only if the following are satisfied: (1) The petition concerns serving the energy needs of a large load customer. (2) The large load customer commits to significant and meaningful financial assurances that must: (A) include reimbursement by the large load customer of at least eighty percent (80%) of the project costs reasonably allocable to the large load customer; and (B) afford protections for the energy utility's existing and future customers from project costs reasonably allocable to the large load customer regardless of whether the large load customer ultimately takes service in the anticipated amount and within the anticipated time frame. (3) At least thirty (30) days before the energy utility's submission of the petition to the commission, the energy utility held at least one (1) pre-filing meeting with: (A) the corporation; (B) the office; (C) the office of utility consumer counselor; (D) the appropriate regional transmission organization; and (E) the large load customer; to review the project. (c) An energy utility may petition the commission for approval of a project to serve: HEA 1007 — Concur 11 (1) one (1) or more large load customers at one (1) or more locations; or (2) not more than four (4) customers whose aggregate demand satisfies the amount set forth in section 10(1) of this chapter. In any case in which more than one (1) large load customer is to be served by a project, a reference in this chapter to one (1) large load customer is a reference to all large load customers to be served by the project, in accordance with IC 1-1-4-1(3). (d) In submitting a petition to the commission under this section, an energy utility must demonstrate that the large load customer and the associated projects meet the requirements of this chapter. Sec. 23. (a) This section applies to an energy utility that petitions the commission for approval of a project to serve a large load customer. (b) In a petition under this section, an energy utility must include, at a minimum, the following: (1) The energy utility's complete case in chief, which must include, at a minimum, the following: (A) An agreement from the large load customer that describes the financial assurances: (i) that afford protections for the energy utility's existing and future customers; and (ii) to which the large load customer has committed regardless of whether the large load customer ultimately takes service in the anticipated amount and within the anticipated time frame. (B) A description of: (i) the demand side management and self-generation options reviewed with the large load customer; and (ii) the investments the large load customer will undertake to reasonably minimize the amount of incremental and other costs incurred by the energy utility. (C) A description of how the energy utility considered implementing grid enhancing technologies to defer or minimize the need for additional investment in generation. (D) A description of how the energy utility may provide for the requisite amount of electricity needed by the large load customer, including the estimated project costs. (E) A description of how the expected project solution will support the provision of electric utility service with the attributes set forth in IC 8-1-2-0.6, including: HEA 1007 — Concur 12 (i) reliability; (ii) affordability; (iii) resiliency; (iv) stability; and (v) environmental sustainability. (F) A description of how the expected project solution and its implementation, if approved by the commission, reasonably protects existing and future customers and is consistent with: (i) the provision of safe, reliable, and affordable electric utility service; and (ii) economical rates. (G) A description of the changes that the energy utility will make to the energy utility's: (i) submissions under IC 8-1-8.5; or (ii) filings under IC 8-1-39; or both, that are necessary to update the energy utility's plans under those statutes to incorporate the project. (H) Information concerning each: (i) large load customer; and (ii) economic development project; included in the petition. (I) A letter to the energy utility from the corporation supporting the petition's request. (J) A letter to the energy utility from the office certifying that a pre-filing meeting took place and that at the meeting: (i) the large load customer's proposed project; and (ii) the expected project solution proposed by the energy utility; were adequately discussed. (K) A description of the communications and information sharing that: (i) took place with the appropriate regional transmission organization before the pre-filing meeting described in clause (J); and (ii) concerned the capacity and energy needs of each large load customer included in the petition. (L) A proposed order for the petition. (2) A copy of a notice of filing with: (A) the corporation; (B) the office; HEA 1007 — Concur 13 (C) the office of utility consumer counselor; and (D) the appropriate regional transmission organization. A notice that is delivered electronically to the parties set forth in this subdivision satisfies the notice requirement under this subdivision. Sec. 24. (a) This section applies to an energy utility that petitions the commission for approval of a project to serve a large load customer. (b) The commission may approve a petition in whole or in part. The commission shall make its decision based on whether the relief requested is just, reasonable, and in the public interest. The commission shall issue its final order on the petition not later than one hundred fifty (150) days after receiving the energy utility's complete petition and case in chief. A petition is considered: (1) complete unless the commission provides a notice of deficiency to the energy utility not later than seven (7) business days after the filing of the petition; and (2) approved if the commission does not issue a final order on the petition within the one hundred fifty (150) day period set forth in this subsection. (c) If an energy utility files a petition that includes one (1) or more large load customers and one (1) or more proposed projects, the commission may: (1) approve the energy utility's petition in its entirety; (2) deny the energy utility's petition in its entirety; or (3) modify the petition, subject to the energy utility's acceptance of the modification. (d) The commission may approve a reasonable risk premium for a project if requested in an energy utility's petition and if the commission finds that the reasonable risk premium is appropriate. If the commission approves a reasonable risk premium: (1) the large load customer is responsible for the amount of the reasonable risk premium; and (2) the reasonable risk premium may not be: (A) included in the energy utility's: (i) revenue requirement; (ii) authorized net operating income; or (iii) calculations under IC 8-1-2-42(d)(3) or IC 8-1-2-42(g)(3)(C); or (B) otherwise considered for purposes of setting the authorized return in any future general rate case or other regulatory proceeding involving the energy utility. HEA 1007 — Concur 14 (e) The commission may approve an energy utility's request to construct, purchase, lease, or otherwise acquire an energy generation resource under this chapter (notwithstanding and instead of under IC 8-1-2.5, IC 8-1-8.5, or IC 8-1-8.8) for the purpose of serving one (1) or more large load customers. In approving an energy utility's request under this chapter to acquire an energy generation resource to serve one (1) or more large load customers, the commission must find that: (1) the information provided by the energy utility under section 23 of this chapter is complete; (2) reasonable and demonstrable consideration was given to nongeneration alternatives by the parties involved; (3) existing and future customers of the energy utility will be adequately protected if the request is granted; and (4) the energy utility has considered the impact of the request on the energy utility's preferred resource portfolio in the energy utility's most recent integrated resource plan. (f) An energy utility shall promptly notify the commission if, after the commission has approved a petition under subsection (e), one (1) or more of the large load customers with respect to whom the petition was approved: (1) no longer requires service from the energy utility or materially alters or terminates the large load customer's service requirements; and (2) the project is incomplete. (g) The commission may, not later than sixty (60) days after receiving a notice under subsection (f), conduct an investigation under IC 8-1-2-58 through IC 8-1-2-60 to determine whether the public interest would still be served by completion of the project. An investigation under this subsection does not preclude the energy utility from continuing construction of the project to serve the large load customer or from continuing to serve the large load customer. If the commission finds that completion of the project is no longer in the public interest, the commission may modify or revoke the order approving the petition. Sec. 25. (a) The commission shall review an energy utility's: (1) estimated acquisition costs submitted under section 20(c)(1)(D) of this chapter; or (2) estimated project costs filed under section 23(b)(1)(D) of this chapter; as applicable. (b) If the commission approves, with or without modification, an HEA 1007 — Concur 15 energy utility's generation resource submittal or petition for approval of a project, the energy utility may recover: (1) acquisition costs; or (2) project costs; as applicable, that have been reviewed and found reasonable by the commission, with a return at the energy utility's weighted average cost of capital. (c) If the commission denies an energy utility's generation resource submittal or petition for approval of a project, the energy utility may recover planning costs that have been reviewed and found reasonable by the commission, without a return. (d) Absent fraud, concealment, or gross mismanagement, an energy utility may recover: (1) acquisition costs; or (2) project costs; as applicable, with a return at the energy utility's weighted average cost of capital, that the energy utility has incurred or contractually will incur in reliance on a commission order issued under this chapter. Sec. 26. (a) Upon request by an energy utility, the commission shall determine whether the information and related materials filed or submitted, or to be filed or submitted, by an energy utility under this chapter: (1) are confidential under IC 5-14-3-4 or are trade secrets under IC 24-2-3; (2) are exempt from public access and disclosure by Indiana law; and (3) must be treated as confidential and protected from public access and disclosure by the commission. (b) The parties to a pre-filing meeting under this chapter shall execute a nondisclosure agreement to review or discuss information or materials considered confidential under IC 5-14-3-4 or to be trade secrets under IC 24-2-3. (c) If the corporation is in negotiations with an industrial, research, or commercial prospect about a potential economic development project and, based on communications related to those negotiations, determines that the potential economic development project for a new or expanded facility in Indiana may result in the economic development project requiring new or increased energy demand of at least twenty (20) megawatts, the corporation shall notify the affected energy utility not later than fifteen (15) days after making the determination. All HEA 1007 — Concur 16 communications of the corporation, including notice under this section to an affected energy utility, regarding a potential economic development project are considered confidential and exempt from disclosure under IC 5-14-3-4(b)(5). Upon the corporation's provision of the notice required by this subsection, any subsequent: (1) meeting; (2) pre-filing meeting; (3) communications; or (4) information sharing; involving the corporation, the affected energy utility, or the industrial, research, or commercial prospect about a potential economic development project may be subject to a nondisclosure agreement with respect to information or materials considered confidential under IC 5-14-3-4 or to be trade secrets under IC 24-2-3. (d) An energy utility may request, and the commission may approve, financial incentives under IC 8-1-8.8-11(a) for: (1) an acquisition; or (2) a project; that qualifies as a clean energy project (as defined in IC 8-1-8.8-2). (e) An energy utility may request that review of an arrangement under IC 8-1-2-24 and any related rates and charges under IC 8-1-2-25 that are: (1) submitted with a generation resource submittal; or (2) filed with a petition for a project; under this chapter be reviewed and approved or denied by the commission not later than ninety (90) days after the date of submittal or filing, as applicable. (f) Notwithstanding IC 8-1-8.5 or any other applicable statute, an energy utility may begin construction of an acquisition or a project before filing a petition or submittal under this chapter. (g) The commission may require an energy utility to file with the commission progress reports and updates with respect to an acquisition or project under this chapter. Any required progress reports or updates under this subsection shall be made in a form and at a frequency that the commission determines to be reasonable. SECTION 3. IC 8-1-8.5-2.1, AS AMENDED BY THE TECHNICAL CORRECTIONS BILL OF THE 2025 GENERAL ASSEMBLY, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2025]: Sec. 2.1 . (a) This section does not apply to the retirement, sale, or transfer of: HEA 1007 — Concur 17 (1) a public utility's electric generation facility if the retirement, sale, or transfer is necessary in order for the public utility to comply with a federal consent decree; or (2) an electric generation facility that generates electricity for sale exclusively to the wholesale market. (b) A public utility shall notify the commission if: (1) the public utility intends or decides to retire, sell, or transfer an electric generation facility with a capacity of at least eighty (80) megawatts; and (2) the retirement, sale, or transfer: (A) was not set forth in; or (B) is to take place on a date earlier than the date specified in; the public utility's short term action plan in the public utility's most recently filed integrated resource plan. (c) Upon receiving notice from a public utility under subsection (b), the commission shall consider and may investigate, under IC 8-1-2-58 through IC 8-1-2-60, the public utility's intention or decision to retire, sell, or transfer the electric generation facility. In considering the public utility's intention or decision under this subsection, the commission shall examine the impact the retirement, sale, or transfer would have on the public utility's ability to meet: (1) the public utility's planning reserve margin requirements or other federal reliability requirements that the public utility is obligated to meet, as described in section [deleted: 13(i)(4)] 13(n)(6) of this chapter; and (2) the reliability adequacy metrics set forth in section [deleted: 13(e)] 13(h) of this chapter. (d) Before July 1, 2026, if: (1) a public utility intends or decides to retire, sell, or transfer an electric generation facility with a capacity of at least eighty (80) megawatts; and (2) the retirement, sale, or transfer: (A) was not set forth in; or (B) is to take place on a date earlier than the date specified in; the public utility's short term action plan in the public utility's most recently filed integrated resource plan; the commission shall not permit the public utility's depreciation rates, as established under IC 8-1-2-19, to be amended to reflect the accelerated date for the retirement, sale, or transfer of the electric generation asset unless the commission finds that such an adjustment is necessary to ensure the ability of the public utility to provide reliable service to its customers, and that the unamended depreciation rates HEA 1007 — Concur 18 would cause an unjust and unreasonable impact on the public utility and its ratepayers. (e) The commission may issue a general administrative order to implement this section. (f) This section expires July 1, 2026. SECTION 4. IC 8-1-8.5-13, AS AMENDED BY P.L.93-2024, SECTION 68, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2025]: Sec. 13. (a) The general assembly finds that it is in the public interest to support the reliability, availability, and diversity of electric generating capacity in Indiana for the purpose of providing reliable and stable electric service to customers of public utilities. (b) As used in this section, "appropriate regional transmission organization", with respect to a public utility, refers to the regional transmission organization approved by the Federal Energy Regulatory Commission for the control area that includes the public utility's assigned service area (as defined in IC 8-1-2.3-2). (c) As used in this section, "capacity market" means an auction conducted by an appropriate regional transmission organization to determine a market clearing price for capacity based on the planning reserve margin requirements established by the appropriate regional transmission organization for a planning year with respect to which an auction has not yet been conducted. (d) As used in this section, "fall unforced capacity", or "fall UCAP", with respect to an electric generating facility, means: (1) the capacity value of the electric generating facility's installed capacity rate adjusted for the electric generating facility's average forced outage rate for the fall period, calculated as required by the appropriate regional transmission organization or by the Federal Energy Regulatory Commission; (2) a metric that is similar to the metric described in subdivision (1) and that is required by the appropriate regional transmission organization; or (3) if the appropriate regional transmission organization does not require a metric described in subdivision (1) or (2), a metric that: (A) can be used to demonstrate that a public utility has sufficient capacity to: (i) provide reliable electric service to Indiana customers for the fall period; and (ii) meet its planning reserve margin requirement and other federal reliability requirements described in subsection [deleted: (l)(4);] (n)(6); and (B) is acceptable to the commission. HEA 1007 — Concur 19 (e) As used in this section, "MISO" refers to the regional transmission organization known as the Midcontinent Independent System Operator that operates the bulk power transmission system serving most of the geographic territory in Indiana. (f) As used in this section, "planning reserve margin requirement", with respect to a public utility for a particular resource planning year, means the planning reserve margin requirement for that planning year that the public utility is obligated to meet in accordance with the public utility's membership in the appropriate regional transmission organization. (g) As used in this section, "refuel" or "refueling" means a planned fuel conversion from one fuel source to another fuel source with respect to an electric generation resource with a nameplate capacity of at least one hundred twenty-five (125) megawatts by a public utility. [deleted: (g)] (h) As used in this section, "reliability adequacy metrics", with respect to a public utility, means calculations used to demonstrate all of the following: (1) Subject to subsection [deleted: (q)(2)(B),] (u)(2), that the public utility: (A) has in place sufficient summer UCAP; or (B) can reasonably acquire not more than: (i) thirty percent (30%) of its total summer UCAP from capacity markets, with respect to a report filed with the commission under subsection [deleted: (l)] (n) before July 1, 2023; or (ii) fifteen percent (15%) of its total summer UCAP from capacity markets, with respect to a report filed with the commission under subsection [deleted: (l)] (n) after June 30, 2023; such that it will have sufficient summer UCAP; to provide reliable electric service to Indiana customers, and to meet its planning reserve margin requirement and other federal reliability requirements described in subsection [deleted: (l)(4).] (n)(6). (2) Subject to subsection [deleted: (q)(2)(B),] (u)(2), that the public utility: (A) has in place sufficient winter UCAP; or (B) can reasonably acquire not more than: (i) thirty percent (30%) of its total winter UCAP from capacity markets, with respect to a report filed with the commission under subsection [deleted: (l)] (n) before July 1, 2023; or (ii) fifteen percent (15%) of its total winter UCAP from capacity markets, with respect to a report filed with the commission under subsection [deleted: (l)] (n) after June 30, 2023; such that it will have sufficient winter UCAP; to provide reliable electric service to Indiana customers, and to HEA 1007 — Concur 20 meet its planning reserve margin requirement and other federal reliability requirements described in subsection [deleted: (l)(4).] (n)(6). (3) Subject to subsection [deleted: (q)(2)(B),] (u)(2), with respect to a report filed with the commission under subsection [deleted: (l)] (n) after June 30, 2026, that the public utility: (A) has in place sufficient spring UCAP; or (B) can reasonably acquire not more than fifteen percent (15%) of its total spring UCAP from capacity markets, such that it will have sufficient spring UCAP; to provide reliable electric service to Indiana customers, and to meet its planning reserve margin requirement and other federal reliability requirements described in subsection [deleted: (l)(4).] (n)(6). (4) Subject to subsection [deleted: (q)(2)(B),] (u)(2), with respect to a report filed with the commission under subsection [deleted: (l)] (n) after June 30, 2026, that the public utility: (A) has in place sufficient fall UCAP; or (B) can reasonably acquire not more than fifteen percent (15%) of its total fall UCAP from capacity markets, such that it will have sufficient fall UCAP; to provide reliable electric service to Indiana customers, and to meet its planning reserve margin requirement and other federal reliability requirements described in subsection [deleted: (l)(4).] (n)(6). (i) As used in this section, "retire" or retirement" means a planned permanent ceasing of electric generation operations with respect to an electric generation resource with a nameplate capacity of at least one hundred twenty-five (125) megawatts by a public utility. [deleted: (h)] (j) As used in this section, "spring unforced capacity", or "spring UCAP", with respect to an electric generating facility, means: (1) the capacity value of the electric generating facility's installed capacity rate adjusted for the electric generating facility's average forced outage rate for the spring period, calculated as required by the appropriate regional transmission organization or by the Federal Energy Regulatory Commission; (2) a metric that is similar to the metric described in subdivision (1) and that is required by the appropriate regional transmission organization; or (3) if the appropriate regional transmission organization does not require a metric described in subdivision (1) or (2), a metric that: (A) can be used to demonstrate that a public utility has sufficient capacity to: (i) provide reliable electric service to Indiana customers for HEA 1007 — Concur 21 the spring period; and (ii) meet its planning reserve margin requirement and other federal reliability requirements described in subsection [deleted: (l)(4);] (n)(6); and (B) is acceptable to the commission. [deleted: (i)] (k) As used in this section, "summer unforced capacity", or "summer UCAP", with respect to an electric generating facility, means: (1) the capacity value of the electric generating facility's installed capacity rate adjusted for the electric generating facility's average forced outage rate for the summer period, calculated as required by the appropriate regional transmission organization or by the Federal Energy Regulatory Commission; or (2) a metric that is similar to the metric described in subdivision (1) and that is required by the appropriate regional transmission organization. [deleted: (j)] (l) As used in this section, "winter unforced capacity", or "winter UCAP", with respect to an electric generating facility, means: (1) the capacity value of the electric generating facility's installed capacity rate adjusted for the electric generating facility's average forced outage rate for the winter period, calculated as required by the appropriate regional transmission organization or by the Federal Energy Regulatory Commission; (2) a metric that is similar to the metric described in subdivision (1) and that is required by the appropriate regional transmission organization; or (3) if the appropriate regional transmission organization does not require a metric described in subdivision (1) or (2), a metric that: (A) can be used to demonstrate that a public utility has sufficient capacity to: (i) provide reliable electric service to Indiana customers for the winter period; and (ii) meet its planning reserve margin requirement and other federal reliability requirements described in subsection [deleted: (l)(4);] (n)(6); and (B) is acceptable to the commission. [deleted: (k)] (m) A public utility that owns and operates an electric generating facility serving customers in Indiana shall operate and maintain the facility using good utility practices and in a manner: (1) reasonably intended to support the provision of reliable and economic electric service to customers of the public utility; [deleted: and] (2) reasonably consistent with the resource reliability requirements of MISO or any other appropriate regional HEA 1007 — Concur 22 transmission organization; and (3) reasonably maximizes the economic value of the electric generating facility. [deleted: (l)] (n) Not later than thirty (30) days after the deadline for submitting an annual planning reserve margin report to MISO, each public utility providing electric service to Indiana customers shall, regardless of whether the public utility is required to submit an annual planning reserve margin report to MISO, file with the commission a report, in a form specified by the commission, that provides the following information for each of the next three (3) resource planning years, beginning with the planning year covered by the planning reserve margin report to MISO described in this subsection: (1) The: (A) capacity; (B) location; and (C) fuel source; for each electric generating facility that is owned and operated by the electric utility and that will be used to provide electric service to Indiana customers. (2) With respect to a report submitted to the commission after December 31, 2025, the amount of generating resource capacity or energy, or both, that the public utility plans to retire and that is owned and operated by the public utility and used to provide retail electric service in Indiana, including the: (A) capacity; (B) location; (C) fuel source; and (D) planned retirement date; for each electric generating facility. The public utility must include information as to whether the planned retirement is required in order to comply with environmental laws, regulations, or court orders, including consent decrees, that are or will be in effect at the time of the planned retirement. In addition, the public utility must provide its economic rationale for the planned retirement, including anticipated ratepayer impacts, and information concerning the public utility's plan or plans with respect to the amount of replacement capacity identified to provide approximately the same accredited capacity within the appropriate regional transmission organization as the amount of capacity of the facility to be retired. HEA 1007 — Concur 23 (3) With respect to a report submitted to the commission after December 31, 2025, the amount of generating resource capacity or energy, or both, that the public utility plans to refuel, including the: (A) capacity; (B) location; (C) existing fuel source; (D) proposed fuel source; and (E) planned completion date of the refueling; with respect to each electric generating facility that the public utility plans to refuel. The public utility must provide its economic rationale for the planned refueling, including anticipated ratepayer impacts, and information concerning the public utility's plan or plans with respect to the extent to which the refueling will maintain or increase the current generating resource accredited capacity or energy, or both, that the electric generating facility provides, so as to provide approximately the same accredited capacity within the appropriate regional transmission organization. [deleted: (2)] (4) The amount of generating resource capacity or energy, or both, that the public utility has procured under contract and that will be used to provide electric service to Indiana customers, including the: (A) capacity; (B) location; and (C) fuel source; for each electric generating facility that will supply capacity or energy under the contract, to the extent known by the public utility. [deleted: (3)] (5) The amount of demand response resources available to the public utility under contracts and tariffs. [deleted: (4)] (6) The following: (A) The planning reserve margin requirements established by MISO for the planning years covered by the report, to the extent known by the public utility with respect to any particular planning year covered by the report. (B) If applicable, any other planning reserve margin requirement that: (i) applies to the planning years covered by the report; and (ii) the public utility is obligated to meet in accordance with the public utility's membership in an appropriate regional transmission organization; HEA 1007 — Concur 24 to the extent known by the public utility with respect to any particular planning year covered by the report. (C) Other federal reliability requirements that the public utility is obligated to meet in accordance with its membership in an appropriate regional transmission organization with respect to the planning years covered by the report, to the extent known by the public utility with respect to any particular planning year covered by the report. For each planning reserve margin requirement reported under clause (A) or (B), the public utility shall include a comparison of that planning reserve margin requirement to the planning reserve margin requirement established by the same regional transmission organization for the 2021-2022 planning year. [deleted: (5)] (7) The reliability adequacy metrics of the public utility, as forecasted for the three (3) planning years covered by the report. [deleted: (m)] (o) Upon request by a public utility, the commission shall determine whether information provided in a report filed by the public utility under subsection [deleted: (l):] (n): (1) is confidential under IC 5-14-3-4 or is a trade secret under IC 24-2-3; (2) is exempt from public access and disclosure by Indiana law; and (3) shall be treated as confidential and protected from public access and disclosure by the commission. [deleted: (n)] (p) A joint agency created under IC 8-1-2.2 may file the report required under subsection [deleted: (l)] (n) as a consolidated report on behalf of any or all of the municipally owned utilities that make up its membership. [deleted: (o)] (q) A: (1) corporation organized under IC 23-17 that is an electric cooperative and that has at least one (1) member that is a corporation organized under IC 8-1-13; or (2) general district corporation within the meaning of IC 8-1-13-23; may file the report required under subsection [deleted: (l)] (n) as a consolidated report on behalf of any or all of the cooperatively owned electric utilities that it serves. [deleted: (p)] (r) In reviewing a report filed by a public utility under subsection [deleted: (l),] (n), the commission may request technical assistance from MISO or any other appropriate regional transmission organization in determining: (1) the planning reserve margin requirements or other federal HEA 1007 — Concur 25 reliability requirements that the public utility is obligated to meet, as described in subsection [deleted: (l)(4);] (n)(6); and (2) whether the resources available to the public utility under subsections [deleted: (l)(1)] (n)(1) through [deleted: (l)(3)] (n)(5) will be adequate to support the provision of reliable electric service to the public utility's Indiana customers. (s) With respect to a report submitted under subsection (n) after December 31, 2025, commission staff shall review the reports submitted by public utilities and shall, not later than ninety (90) days after the date of submission of the reports, submit to the commission a staff report concerning any planned retirements included in the reports under subsection (n)(2). The report must make recommendations to the commission based on whether each planned retirement: (1) is consistent with the standards set forth in subsection (m); (2) will be replaced with an amount of replacement capacity that will provide approximately the same accredited capacity within the appropriate regional transmission organization as the amount of capacity of the facility to be retired; (3) will not adversely and unreasonably impact a public utility's ability to provide safe, reliable, and economical electric utility service to the public utility's customers; (4) will result in the provision to Indiana customers of electric utility service with the attributes of: (A) reliability; (B) affordability; (C) resiliency; (D) stability; and (E) environmental sustainability; as set forth in IC 8-1-2-0.6; and (5) is required in order to comply with environmental laws, regulations, or court orders, including consent decrees, that are or will be in effect at the time of the planned retirement. (t) The commission shall make the staff reports prepared under subsection (s) publicly available by posting the staff reports on the commission's website. Upon the posting of a staff report on the commission's website, the commission shall accept public comments on the report for a period not to exceed thirty (30) days after the date of posting. [deleted: (q)] (u) If, after reviewing a report filed by a public utility under subsection [deleted: (l),] (n) and any staff report prepared with respect to the public utility under subsection (s), the commission is not satisfied HEA 1007 — Concur 26 that the public utility can either: [deleted: (1) provide reliable electric service to the public utility's Indiana customers; or (2) either: (A)] (1) satisfy both: [deleted: (i)] (A) its planning reserve margin requirement or other federal reliability requirements that the public utility is obligated to meet, as described in subsection [deleted: (l)(4);] (n)(6); and [deleted: (ii)] (B) the reliability adequacy metrics set forth in subsection [deleted: (g);] (h); or [deleted: (B)] (2) provide sufficient reason as to why the public utility is unable to satisfy both: [deleted: (i)] (A) its planning reserve margin requirement or other federal reliability requirements that the public utility is obligated to meet, as described in subsection [deleted: (l)(4);] (n)(6); and [deleted: (ii)] (B) the reliability adequacy metrics set forth in subsection [deleted: (g);] (h); during one (1) more of the planning years covered by the report, the commission [deleted: may] shall conduct an investigation under IC 8-1-2-58 through IC 8-1-2-60 as to the reasons for the public utility's potential inability to meet the requirements described in subdivision (1) or [deleted: (2), or both.] provide sufficient reason as to that inability, as described in subdivision (2). In addition, if the public utility has indicated in its report under subsection (n)(2) that it plans to retire an electric generating facility within one (1) year of the date of the report, the commission must conduct an investigation under IC 8-1-2-58 through IC 8-1-2-60 as to the reasons for the public utility's potential inability to meet the requirements described in subdivision (1) or provide sufficient reason as to that inability, as described in subdivision (2). However, a public utility may request, not earlier than three (3) years before the planned retirement date of an electric generation facility, that the commission conduct an investigation under IC 8-1-2-58 through IC 8-1-2-60, for the purposes described in this subsection, with respect to the planned retirement. If the commission conducts an investigation at the request of a public utility within the three (3) year period before the planned retirement date of an electric generation facility, the commission may not conduct a subsequent investigation that would otherwise be required under this subsection with respect to the retirement of that same electric generation facility unless the commission is not satisfied, as of the time that an investigation would otherwise be required under this subsection, that the public HEA 1007 — Concur 27 utility can meet the requirements described in subdivision (1) or provide sufficient reason as to that inability, as described in subdivision (2). If a certificate is granted by the commission under this chapter for a facility intended to repower or replace a generation unit that is planned for retirement, and the certificate includes findings that the project will result in at least equivalent accredited capacity and will provide economic benefit to ratepayers as compared to the continued operation of the generating unit to be retired, the certificate under this chapter constitutes approval by the commission for purposes of an investigation required by this subsection. However, if the commission finds that facts and circumstances regarding the planned retirement have changed significantly since the certificate was granted and that those changes concern the public utility's ability to meet the requirements described in subdivision (1), the commission may conduct an investigation into the planned retirement of the unit. [deleted: (r)] (v) If, upon investigation under IC 8-1-2-58 through IC 8-1-2-60, and after notice and hearing, as required by IC 8-1-2-59, the commission determines that the capacity resources available to the public utility under subsections [deleted: (l)(1)] (n)(1) through [deleted: (l)(3)] (n)(5) will not be adequate [deleted: to support the provision of reliable electric service to the public utility's Indiana customers, or] to allow the public utility to satisfy both its planning reserve margin requirements or other federal reliability requirements that the public utility is obligated to meet (as described in subsection [deleted: (l)(4))] (n)(6)) and the reliability adequacy metrics set forth in subsection [deleted: (g),] (h), the commission shall issue an order: (1) directing the public utility to acquire or construct; or (2) prohibiting the retirement or refueling of; such capacity resources that are reasonable and necessary to enable the public utility to provide reliable electric service to its Indiana customers, and to satisfy both its planning reserve margin requirements or other federal reliability requirements described in subsection [deleted: (l)(4)] (n)(6) and the reliability adequacy metrics set forth in subsection [deleted: (g).] (h). The commission shall issue an order under this subsection not later than one hundred twenty (120) days after the initiation of the investigation under subsection (u). If the commission does not issue an order within the one hundred twenty (120) day period prescribed by this subsection, the public utility is considered to be able to meet the requirements described in subsection (u)(1) with respect to the retirement of the electric generation facility under HEA 1007 — Concur 28 investigation. Not later than ninety (90) days after the date of [deleted: the commission's] an order by the commission under this subsection, the public utility shall file for approval with the commission a plan to comply with the commission's order. Notwithstanding IC 8-1-3 or any other law, any appeal of an order by the commission under this subsection is entitled to priority review and shall be given expedited consideration in accordance with Rule 21 of the Indiana Rules of Appellate Procedure. (w) With respect to a report submitted under subsection (n) after December 31, 2025, if the commission issues an order under subsection (v) to prohibit the retirement or refueling of an electric generation resource, the commission shall create a sub-docket to authorize the public utility to recover in rates the costs of the continued operation of the electric generation resource that was proposed to be retired or refueled. The commission must find that the continued costs of operation are just and reasonable before authorizing their recovery in the public utility's rates. The creation of a sub-docket under this subsection is not subject to the one hundred twenty (120) day time frame for the commission to issue an order under subsection (v). [deleted: The] (x) A public utility's plan under subsection (v) may include: (1) a request for a certificate of public convenience and necessity under this chapter; or (2) an application under IC 8-1-8.8; or both. [deleted: (s)] (y) Beginning in 2022, the commission shall include in its annual report under IC 8-1-1-14 the following information: (1) The commission's analysis regarding the ability of public utilities to: (A) provide reliable electric service to Indiana customers; and (B) satisfy both: (i) their planning reserve margin requirements or other federal reliability requirements; and (ii) the reliability adequacy metrics set forth in subsection [deleted: (g);] (h); for the next three (3) utility resource planning years, based on the most recent reports filed by public utilities under subsection [deleted: (l).] (n). (2) A summary of: (A) the projected demand for retail electricity in Indiana over the next calendar year; [deleted: and] (B) the amount and type of capacity resources committed to HEA 1007 — Concur 29 meeting the projected demand; (C) beginning with the commission's annual report due before October 1, 2026, and in each subsequent annual report, the planned retirements or refuelings of electric generation resources and the plans to replace or retain the capacity or energy, or both, of the electric generation resources planned to be retired or refueled; and (D) beginning with the commission's annual report due before October 1, 2026, and in each subsequent annual report, the reports of commission staff under subsection (s). In preparing the summary required under this subdivision, the commission may consult with the forecasting group established under section 3.5 of this chapter. (3) Beginning with the commission's annual report filed under IC 8-1-1-14 in 2025, the commission's analysis regarding the appropriate percentage or portion of: (A) total spring UCAP that public utilities should be authorized to acquire from capacity markets under subsection [deleted: (g)(3)(B);] (h)(3)(B); and (B) total fall UCAP that public utilities should be authorized to acquire from capacity markets under subsection [deleted: (g)(4)(B).] (h)(4)(B). [deleted: (t)] (z) The commission may adopt rules under IC 4-22-2 to implement this section. SECTION 5. An emergency is declared for this act. HEA 1007 — Concur Speaker of the House of Representatives President of the Senate President Pro Tempore Governor of the State of Indiana Date: Time: HEA 1007 — Concur [extracted by pdf-snapshot.ts with strike detection, 2026-10-01T18:41:36.182Z, https://iga.in.gov/pdf-documents/124/2025/house/bills/HB1007/HB1007.08.ENRS.pdf, from saved file]