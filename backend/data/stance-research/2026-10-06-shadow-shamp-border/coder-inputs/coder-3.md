You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-gold19/backend/data/stance-research/2026-10-06-shadow-shamp-border/labels/coder-3.json. Write JSON only, matching
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
**Clarified 2026-10-01 (still 0.4 — no new variable or value; rulings by Chris Andrews):** V5 says
how a judge's lower-court record is coded (`pre-seating`, with one lever-match exception), and the
Maloy / `same-sex-marriage` example now reads the RFMA on its operative section (recognition → rung 2;
its religious section is a savings clause). The version stays 0.4 so existing labels and gold keep
counting; no gold item turns on either line.
**Clarified 2026-10-02 (still 0.4 — no new variable or value):** V3 "A record reported only by news is
not a record", with register row H15. It restates the V3 rule that a record needs the instrument and
the person's action on it, for the case where the only source of that action is a reporter's sentence.
The items that prompted it are not named here, for the same reason as H13 and H14.
**Clarified 2026-10-02 (still 0.4 — no new variable or value; ruling by Chris Andrews):** V4 "A study
directive that states its goal", with register row H16. It decides which existing blank reason a
`study-directive` row takes; it changes no chair. The item that prompted it is not named here.
**Clarified 2026-10-02 (still 0.4 — no new variable or value; ruling by Chris Andrews):** V4.2 "The rung's
object is a clause", with register row H17 and its `climate-change` example. The items that prompted it
are not named here.
**Clarified 2026-10-06 (still 0.4 — no new coded variable; ruling by Chris Andrews):** V6 "Evidence
tier". A chair may still rest on one source, but every published chair carries a tier — `single-source`
or `corroborated` — that code computes from `rests_on`. Coders code exactly as before.
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
- **A record reported only by news is not a record (H15).** "She authored Senate Bill 285" or "he
  voted against it", written by a reporter, is the reporter's account of a record, not the record. Code
  that passage by what it is: the person's own quoted words in it are `statement-other`; the
  reporter's account of the act is context for those words, not a `record` passage, and it cannot
  carry `record_kind`. Find the record itself (the bill page, the roll call) and code that instead;
  emit `needs_source` for it. CONFIRM cannot check a record on a news page, because no source profile
  reads records from one.
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
- **A study directive that states its goal (H16, ruling 2026-10-02).** A vote for a study does not say
  what the person hopes it finds, so a study directive is never a chair. Which blank it gives depends
  on the bill's own text:
  - The text states no outcome ("study X and report") → the row is BLANK `no-evidence`.
  - The text states the outcome it seeks — findings that endorse a side ("the Legislature endorses a
    health care system with unified financing, such as a single-payer health care system"), or a
    study ordered "with the objective of creating" a named policy → BLANK `direction-only`, on that
    side. It applies to anyone who acted on the bill, because the stated goal is in the text they
    voted for; it is clearest for the author.
  - This does not let a recital carry a chair: the operative section still governs what the bill
    does, and the stated goal shows only a side.
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
- **The rung's object is a clause (H17, ruling 2026-10-02).** A rung says *what* the government acts on,
  not only *how*. A mandate with a firm deadline matches the mechanism of `climate-change` rung 1,
  "Require a shift to **clean energy** through mandates and firm deadlines", only when the thing it
  mandates is clean energy.
  - A renewable-procurement standard with dated targets ("44 percent by December 31, 2024 … 60 percent
    by December 31, 2030" of retail sales from eligible renewable resources) → rung 1, `chair-shaped`.
  - A greenhouse-gas emissions limit ("reduced to at least 40 percent below … no later than December
    31, 2030"), or a declared net-zero policy that names carbon capture and removal as paths, names no
    energy source; it can be met in other ways → BLANK `direction-only` (the pro-action side).
  - The same test applies on every ladder: match the rung's object, not only its verb.

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
  - **A judge's record on a lower court** (ruling 2026-10-01) is `pre-seating` too: a trial court and
    an appellate court are different offices with different levers. It counts for the current seat
    only when the rung's lever is the same at both courts — an opinion that shows the judge's method
    of interpretation, or the judge's own sealing or access practice — and the coder names that lever
    in the note.
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
the instrument's **operative** content is the position. The RFMA's operative section is marriage
recognition; its religious section saves protections that already exist, so it does not show that she
insists on a carve-out (V4.1: the operative section governs). → Season 2 rung 2, "the same benefits
and protections as any other marriage", unless her own words stress the religious exemption (ruling
2026-10-01). It is `in-term` for the campaign that seated her. Note: the served ladder changed between
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
- **Evidence tier (ruling 2026-10-06, Chris Andrews; option C).** One chair-shaped source is enough to
  seat a chair, but the voter sees how much evidence stands behind it. The tier is **computed by code
  from the row's `rests_on`, never coded**:
  - `corroborated` — at least two **independent** sources in `rests_on`, each of which on its own
    supports the chair (its passage is `chair-shaped` for that rung, or, for a vote, passes the V4.1
    vote ladder for it).
  - `single-source` — anything else that seats a chair.
  - **Independent** means a different instrument (record passages on one instrument are one source —
    the instrument group of V3), or a different occasion of the person's own words. Two reports of one
    statement, or news repeating one press release, are one source (principle 6).
  - _owed:_ whether the person's own explanation of a vote counts as a second source for that same
    vote, or as the same act. Until ruled, it is the same act (one source).
  - A tier never upgrades a blank: two `direction-only` sources are still BLANK `direction-only`.

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
| H15 | A news sentence that reports the person's vote or authorship, coded as a `record` | the quoted words → `statement-other`; the reported act → context only, `needs_source` | V3 "A record reported only by news" | gold round 14 (items withheld; coded before this entry) |
| H16 | A study directive whose findings or stated objective endorse a side, coded `no-evidence` | BLANK `direction-only` (a study with no stated outcome stays `no-evidence`) | V4.1 "A study directive that states its goal" | gold round 15 (item withheld; coded before this entry) |
| H17 | An emissions limit coded as `climate-change` rung 1 ("a shift to clean energy") | BLANK `direction-only`; a renewable-procurement standard with dates stays rung 1 | V4.2 "The rung's object is a clause" | gold round 17 (items withheld; coded before this entry) |

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

politician_id: 687e6f07-f71a-41b4-8525-b509b2cebb42  office_id: 2aed98f5-ab9e-49d3-b6be-e8fd257518cd
Janae Shamp — State Senator, Arizona (seated, level: state)
Current term: 2023-01-02 (precision: day) to present

## Topics (served ladder text — code against these words only)

### topic_key: border-security
topic_id: 407614a8-ba2c-4145-8224-233655e6ac3f  served_revision_id: 76d9941b-3085-42cf-b229-ac41f4f85b8d
Question: How should the government handle people who cross the border?
  1. Give everyone who crosses the border a fair asylum hearing.
  2. Expand orderly, legal ways to seek asylum at the border.
  3. Combine strong enforcement with a faster asylum process.
  4. Sharply restrict who can claim asylum at the border.
  5. End asylum and quickly turn back anyone who crosses illegally.

#### Annex

# border-security — served revision 76d9941b-3085-42cf-b229-ac41f4f85b8d (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should the government handle people who cross the border?"

**Orientation:** standard. Rung 1 gives every person who crosses an asylum hearing, rung 5 ends
asylum and turns people back. The rungs order **how much access to asylum a person at the border
has**. Do not read the number as "more government": enforcement rises as the number rises.

**Levels with a role:** federal (`compass_topic_roles`). Asylum law, border enforcement and the
immigration courts are federal. State border measures (state troops, barriers, state crossing
crimes) are actions of an office with no role on this topic.

**Synonyms:** "asylum", "credible fear", "expedited removal", "ports of entry", "between ports",
"parole", "CBP One" or "appointments", "Remain in Mexico" / "Migrant Protection Protocols", "safe
third country", "transit ban", "Title 42", "expulsion", "border emergency authority",
"asylum officers", "immigration judges", "backlog", "wall" / "barrier".

1. **"Give everyone who crosses the border a fair asylum hearing."**
   - Means: every person who crosses, wherever and however they cross, can ask for asylum and gets a
     full, fair hearing.
   - Operative clauses: [a] everyone who crosses, including between ports of entry; [b] a fair
     asylum hearing.
   - Establishing evidence looks like: own words that every person who crosses must get a hearing; an
     instrument that ends expedited removal or bars turning people back without a hearing.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because opposing a **restriction** reads like "a hearing for
     everyone". A No on a restriction shows the side only → `direction-only` (V4.1).

2. **"Expand orderly, legal ways to seek asylum at the border."**
   - Means: the government opens more lawful routes to ask for asylum at the border, such as more
     processing at ports of entry or appointments.
   - Operative clauses: [a] expand; [b] orderly, legal ways to seek asylum at the border.
   - Establishing evidence looks like: an instrument that adds processing capacity or lawful entry
     routes for asylum seekers, **plus** something that excludes rung 1 (own words that people who
     cross between ports should use the lawful routes) _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: a new route does not say that everyone who crosses elsewhere
     still gets a hearing.
   - Commonly confused with rung 3 because more asylum officers also make the process faster. Rung 3
     needs the enforcement clause as well; capacity alone → `direction-only` _(proposed)_.

3. **"Combine strong enforcement with a faster asylum process."**
   - Means: more enforcement at the border, and quicker asylum decisions, together.
   - Operative clauses: [a] strong enforcement (agents, barriers, detention, removal of those who do
     not qualify); [b] a faster asylum process (more officers or judges, shorter time to decision).
   - Establishing evidence looks like: a single-subject border bill that does both. Compound: one side
     only → `compound-partial` (V4.2).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a faster process often comes with a **higher screening
     standard**. Code the eligibility rule: if the bill narrows who may claim, it reaches rung 4's
     clause; if it only speeds decisions, it is rung 3 _(proposed)_.
   - Border bills are often attached to foreign-aid supplementals → V4 `multi-subject`.

4. **"Sharply restrict who can claim asylum at the border."**
   - Means: many fewer people are allowed to ask for asylum at the border.
   - Operative clauses: [a] restrict eligibility to claim asylum at the border; [b] "sharply".
   - Establishing evidence looks like: an instrument that bars claims by large groups (people who
     crossed between ports, people who passed through another country) or that suspends claims when
     crossings exceed a number.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A narrow change (one category, one procedural bar) is not "sharply" → `direction-only`
     _(proposed)_.
   - Commonly confused with rung 5 because a **suspension** of asylum claims reads like "end
     asylum". A suspension that applies only while crossings stay above a set number restricts asylum
     → rung 4, not rung 5 _(ruled 2026-10-01)_.

5. **"End asylum and quickly turn back anyone who crosses illegally."**
   - Means: no asylum claim is available, and anyone who crosses unlawfully is sent back at once.
   - Operative clauses: [a] end asylum; [b] quickly turn back anyone who crosses illegally.
   - Establishing evidence looks like: own words or an instrument that does both. An expulsion
     authority that removes crossers without asylum screening meets [b]; [a] still needs the passage
     to say asylum is ended, not paused. Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Barriers and personnel.** Money for a wall, agents or technology is enforcement only → rung 3
  clause [a] at most; it does not say what happens to asylum claims → `direction-only` _(proposed)_.
- **Where claimants wait** (a rule that makes claimants wait outside the country) restricts the
  process, not who may claim → `direction-only` _(proposed)_.
- **People already inside the country** are the `deportation` question. A passage about removal of
  long-settled people → `adjacent` here _(proposed)_.
- **Legal immigration levels** (visas, refugee caps) are not on this ladder → `adjacent`.
- **Budget, appropriations and supplemental votes** with a border item → V4 `multi-subject`.
- **Resolutions** that condemn a border policy, or that praise agents, name no clause → V4
  `rhetorical`.


## Sources

---
snapshot_id: c5f21c37-b7a1-5a7f-bd5f-0d5039fcd863
source_kind: public-record
url: https://www.azleg.gov/legtext/56leg/2R/bills/HCR2060S.htm

HCR2060 - 562R - S Ver Senate Engrossed House Bill [deleted: lawful presence; e-verify program; penalties] (now: border; benefits; fentanyl; illegal entry) State of Arizona House of Representatives Fifty-sixth Legislature Second Regular Session 2024 HOUSE CONCURRENT RESOLUTION 2060 A Concurrent Resolution enacting and ordering the submission to the people of a measure relating to responses to harms related to an unsecured border. (TEXT OF BILL BEGINS ON NEXT PAGE) Be it resolved by the House of Representatives of the State of Arizona, the Senate concurring: 1. Under the power of the referendum, as vested in the Legislature, the following measure, relating to responses to harms related to an unsecured border, is enacted to become valid as a law if approved by the voters and on proclamation of the Governor: AN ACT amending title 1, chapter 5, article 1, arizona revised statutes, by adding sections 1-503 and 1-504; amending title 13, chapter 34, arizona revised statutes, by adding section 13-3424; amending title 13, chapter 38, Arizona Revised Statutes, by adding article 35; amending title 23, chapter 2, article 2, arizona revised statutes, by adding section 23-215; relating to responses to harms related to an unsecured border. Be it enacted by the Legislature of the State of Arizona: Section 1. Short title This act may be cited as the "Secure the Border Act". Sec. 2. Findings and declaration of purpose A. The people of the State of Arizona find and declare as follows: 1. Due to weaknesses in immigration enforcement, a public safety crisis is occurring in Arizona, caused by transnational cartels engaging in rampant human trafficking and drug smuggling across this state's southern border. 2. From 2021 to 2023, United States Customs and Border Protection encountered nearly seven million immigrants illegally entering the United States through the southwest border. This number does not include an estimated two million "gotaways" who evaded encounters with border officials entirely. 3. From 2021 to 2023, United States Customs and Border Protection encountered two hundred eighty-two individuals on the terrorist watchlist illegally entering the southwest border between ports of entry. This is a 3033% increase over the prior three years when only nine such individuals were encountered. 4. From 2021 to 2023, the number of unaccompanied minors illegally crossing the southwest border skyrocketed to over four hundred thousand. Studies have shown that a majority of these children are victims of human trafficking. 5. From 2021 to 2023, the amount of fentanyl seized at the southwest border almost tripled, amounting to billions of doses of fentanyl. Illicit fentanyl, which is primarily produced in foreign nations and smuggled across the southwest border, is a synthetic opioid fifty times stronger than heroin. Even a single dose can be lethal. Synthetic opioids like fentanyl have now become the leading cause of overdose deaths in the United States. Transnational cartels fund their operations by trafficking this deadly drug across the southwest border. 6. In 2022, the Arizona Department of Health Services reported that illicit fentanyl is primarily responsible for an increasing number of overdose deaths in Arizona and that opioid overdose data demonstrates the continued urgency to address the drug overdose crisis in Arizona through comprehensive and collaborative approaches. 7. Many individuals who enter the United States unlawfully are enticed by smugglers with promises of economic incentives, including employment and taxpayer-funded benefits. Human smuggling is a gateway crime for additional offenses, including identity theft, document fraud and benefit fraud, harming Arizona taxpayers. Unchecked and unauthorized employment causes economic hardship to Arizona workers who may face unfair labor competition, wage suppression and reduced working conditions or opportunities. 8. A holistic approach is required to deter human trafficking and drug smuggling into Arizona by: (a) Empowering law enforcement to protect the public. (b) Reducing the incentives for illegal immigration. (c) Punishing criminals who fuel the crisis at Arizona's southern border. B. Based on the facts outlined in subsection A of this section, the state of Arizona is being "actually invaded" as defined in article I, section 10 of the United States Constitution. The determination of invasion made in this subsection may only be revoked by referendum or by legislation that is duly enacted by the legislature and signed by the governor. C. Based on these findings, the people of Arizona's purpose in adopting the Secure the Border Act includes protecting the public and responding to the harms related to an unsecured border by: 1. Empowering law enforcement to protect the public by arresting aliens who fail to enter Arizona's southern border through official ports of entry. 2. Reducing the incentive for illegal immigration by creating criminal offenses for a person to knowingly present false documents to obtain public benefits or to evade workplace eligibility detection through the e-verify program. 3. Strengthening Arizona's laws that require documentation of a person's lawful presence in the United States in order to receive public benefits by requiring agencies and political subdivisions of this state to use the systematic alien verification for entitlements program to verify benefit eligibility and validity of documents for people who are not citizens or nationals of the United States. 4. Increasing punishments for criminals who fuel the crisis at the southern border by selling fentanyl that causes the death of another person. Sec. 3. Title 1, chapter 5, article 1, Arizona Revised Statutes, is amended by adding sections 1-503 and 1-504, to read: START_STATUTE 1-503. Federal, state and local public benefits; false documents; violation; classification; definitions A. Notwithstanding any other state law and to the extent allowed by federal law, any natural person who is not lawfully present in the United States shall not knowingly apply for a federal public benefit or a state or local public benefit by submitting a false document to any entity that administers the federal public benefit or the state or local public benefit. B. Any natural person who violates subsection A of this section is guilty of a class 6 felony. C. For the purposes of this section: 1. "Federal public benefit" has the same meaning prescribed in section 1-501. 2. "State or local public benefit" has the same meaning prescribed in section 1-502. END_STATUTE START_STATUTE 1-504. Document verification; applicants for public benefits; definitions A. if a natural person who applies for any federal public benefit pursuant to section 1-501 or any state or local public benefit pursuant to section 1-502 is not a citizen or national of the United States, the agency or political subdivision of this state that administers the public benefit shall use the systematic alien verification for entitlements program that is maintained by the United States Citizenship and immigration services, or any successor program that is designated by the United States department of homeland security, in order to verify the validity of the documents provided by the applicant and to verify the applicant's eligibility for benefits. B. This section does not relieve a natural person of any requirement to submit documentation that is required for any federal public benefit pursuant to section 1-501 or any state or local public benefit pursuant to section 1-502. C. For the purposes of this section: 1. "Federal public benefit" has the same meaning prescribed in section 1-501. 2. "State or local public benefit" has the same meaning as prescribed in section 1-502. END_STATUTE Sec. 4. Title 13, chapter 34, Arizona Revised Statutes, is amended by adding section 13-3424, to read: START_STATUTE 13-3424. Sale of lethal fentanyl; affirmative defense; classification A. A person who is at least eighteen years of age commits sale of lethal fentanyl if the person knowingly sells fentanyl in violation of section 13-3408, subsection A, paragraph 7 and both of the following apply: 1. The person knows that the drug being sold contains fentanyl. 2. The fentanyl causes the death of another person. B. It is an affirmative defense to a charge brought under this section that the fentanyl and its precursor chemicals were either manufactured in the United States or were lawfully imported into the United States. C. Sale of lethal fentanyl is a class 2 felony, except that the presumptive, minimum and maximum sentences shall be increased by five years. END_STATUTE Sec. 5. Title 13, chapter 38, Arizona Revised Statutes, is amended by adding article 35, to read: ARTICLE 35. ILLEGAL ENTRY INTO THIS STATE START_STATUTE 13-4295. Definitions In this article, unless the context otherwise requires: 1. "Alien" means a person who is not a citizen or national of the United States as described in 8 United States code section 1101. 2. "Port of entry" means a port of entry in the United States as described in 19 code of federal regulations section 101.1. END_STATUTE START_STATUTE 13-4295.01. Illegal entry from foreign nation; affirmative defense; probable cause to arrest; prospective applicability; classification A. It is unlawful for a person who is an alien to enter or attempt to enter this state directly from a foreign nation at any location other than a lawful port of entry. B. It is an affirmative defense to a violation of subsection A of this section if either of the following applies: 1. The federal government has granted the defendant lawful presence in the United States or asylum under 8 United States Code section 1158. 2. The defendant's conduct does not constitute a violation of 8 United States Code section 1325( a ). C. A person may not be arrested for a violation of this section without probable CAUSE, which SHALL be established by any of the following: 1. A law enforcement officer who witnesses the violation. 2. A TECHNOLOGICAL recording of the violation. 3. Any other constitutionally sufficient indicia of probable cause. D. This section may only be enforced prospectively. This section does not apply retroactively and shall not be construed to apply to the conduct of any person who entered this state unlawfully from a foreign nation at any time before this section becomes enforceable. e. An alien lacks lawful presence under this section if the alien was either: 1. Paroled pursuant to a programmatic grant of parole, including under any parole program not created under notice-and-comment rulemaking that establishes specific characteristics under which an alien would be entitled to parole and that has been applied to more than one hundred aliens during one calendar year. 2. Required to be detained under the immigration and nationality act but was not detained and instead was paroled into the United States. f. A violation of this section is a class 1 misdemeanor, except that it is a class 6 felony if the person has been previously convicted of a violation of this section. The person is not eligible for probation, pardon, commutation or suspension of sentence or release on any other basis until the person has served a term of incarceration as determined by the court. END_STATUTE START_STATUTE 13-4295.02. Refusal to comply with order to return to a foreign nation; classification A. A person who is an alien commits refusal to comply with an order to return to a foreign nation if all of the following occur: 1. The person is charged with or convicted of an offense under this article. 2. A court, as applicable, issues an order pursuant to section 13-4295.03 for the person to return to the foreign nation from which the person entered or attempted to enter the United States or the person's nation of origin. 3. The person refuses to comply with the order. B. A violation of this section is a class 4 felony. END_STATUTE START_STATUTE 13-4295.03. Order to return to foreign nation A. At any time before a person is convicted of or adjudicated for a violation of section 13-4295.01, a court may dismiss the charge pending against the person and issue a written order in accordance with subsection b of this section. B. A written order authorized by subsection A of this section shall discharge the person and require the person to return to the foreign nation from which the person entered or attempted to enter the United States or the person's nation of origin and may be issued if all of the following apply: 1. The person agrees to the order. 2. The person has not previously been convicted of an offense under this article or previously obtained a discharge under an order issued pursuant to this section. 3. The person is not charged with another class 1 misdemeanor or any felony offense. 4. Before the issuance of the order, the arresting law enforcement agency does both of the following: ( a ) Collects all identifying information of the person, which must include taking fingerprints from the person and using other applicable photographic and biometric measures to identify the person. ( b ) Cross-references the collected information with all relevant local, state and federal criminal databases and federal lists or classifications that are used to identify a person as a threat or potential threat to national security. C. On conviction of an offense under this article, the judge shall enter an order that requires the person to return to the foreign nation from which the person entered or attempted to enter the United States or the person's nation of origin. An order issued under this subsection takes effect on completion of any term of incarceration or imprisonment. D. An order that is issued under this section must include an authorization that allows a state or local law enforcement agency to transport the person to a port of entry or to any other point of transfer into federal custody. END_STATUTE START_STATUTE 13-4295.04. Enforcement of article Notwithstanding any other law, this article may not be enforced in any manner until any part of section 2 of S.B. 4, 88th Leg., 4th Called Sess. (2023) that was enacted in the state of Texas, or any other law of any other state similar thereto, has been in effect for a period of sixty consecutive days at any time on or after the effective date of this article. END_STATUTE START_STATUTE 13-4295.05. Civil immunity for state and local public entities, officials, employees and contractors; other laws not affected A. A state or local government entity, official, employee or contractor is immune from liability for damages arising from a cause of action under the laws of this state resulting from an action taken by the state or local government entity, official, employee or contractor to enforce this article or an order issued pursuant to this article during the course and scope of the state or local government entity's official's, employee's or contractor's office, employment or performance for or on behalf of this state or the local government. B. This section shall not affect a defense, immunity or jurisdictional bar available to this state or a local government or an official, employee or contractor of this state or a local government. END_STATUTE START_STATUTE 13-4295.06. Incarceration authorization and agreements Notwithstanding any other law, If a county or local law enforcement agency does not have the capacity to hold a person who is arrested for or convicted of an offense included in this article, the director of the state department of corrections shall accept arrested or convicted persons who are charged with or convicted of an offense included in this article at any facility in this state that has available capacity. END_STATUTE Sec. 6. Title 23, chapter 2, article 2, Arizona Revised Statutes, is amended by adding section 23-215, to read: START_STATUTE 23-215. Employment eligibility; e-verify program; false documents; violation; classification A. Any natural person who is not lawfully present in the United States shall not knowingly submit false information or documents to an employer to evade detection of employment eligibility under the e-verify program. B. Any natural person who violates subsection a of this section is guilty of a class 1 misdemeanor, except that it is a class 6 felony if the person has been previously convicted of a violation of this section. The person is not eligible for probation, pardon, commutation or suspension of sentence or release on any other basis until the person has served a term of incarceration as determined by the court. END_STATUTE Sec. 7. Right to intervene; lawsuit A. The president of the senate, the speaker of the house of representatives, the minority leader of the senate or the minority leader of the house of representatives shall be allowed to file a lawsuit or intervene in any action concerning this act if the individual seeks to defend the constitutionality, validity or enforceability of this act. B. Any settlement of a lawsuit challenging this act cannot be entered before service of a twenty-one-day notice to the president of the senate, speaker of the house of representatives, minority leader of the senate and minority leader of the house of representatives. The failure to comply with this subsection shall invalidate the settlement and constitutes a violation of section 38-443, Arizona Revised Statutes. Sec. 8. Severability If a provision of this act or its application to any person or circumstance is held invalid, the invalidity does not affect other provisions or applications of the act that can be given effect without the invalid provision or application, and to this end the provisions of this act are severable. 2. The Secretary of State shall submit this proposition to the voters at the next general election as provided by article IV, part 1, section 1, Constitution of Arizona.

---
snapshot_id: 71d87495-204b-51b8-96d1-6ff81b693ecf
source_kind: public-record
url: https://www.azleg.gov/legtext/56leg/2R/bills/SB1231S.htm

SB1231 - 562R - S Ver Senate Engrossed state crime; illegal border crossings State of Arizona Senate Fifty-sixth Legislature Second Regular Session 2024 SENATE BILL 1231 An Act amending title 12, chapter 7, article 2, Arizona Revised Statutes, by adding sections 12-827, 12-828, 12-829 and 12-830; amending section 13-603, Arizona Revised Statutes; amending title 13, chapter 38, Arizona Revised Statutes, by adding article 35; amending sections 31-402, 31-403 and 41-1750, Arizona Revised Statutes; relating to illegal border crossings. (TEXT OF BILL BEGINS ON NEXT PAGE) Be it enacted by the Legislature of the State of Arizona: Section 1. Title 12, chapter 7, article 2, Arizona Revised Statutes, is amended by adding sections 12-827, 12-828, 12-829 and 12-830 to read: START_STATUTE 12-827. Civil immunity for and indemnification of local government officials, employees and contractors; exception A. a local government official, employee or contractor is immune from civil liability for damages arising from a cause of action under the laws of this state resulting from an action taken by the local government official, employee or contractor to enforce Title 13, chapter 38, article 35 or an order issued under section 13-4295.05 during the course and scope of the local government official's, employee's or contractor's office, employment or contractual performance for or service on behalf of the local government. b. a local government shall indemnify a local government official, employee or contractor for damages arising from a cause of action under federal law resulting from an action taken by the local government official, employee or contractor to enforce Title 13, chapter 38, article 35 during the course and scope of the local government official's, employee's or contractor's office, employment or contractual performance for or service on behalf of the local government in an amount not to exceed: 1. $100,000 to any one person or $300,000 for any single occurrence in the case of personal injury or death. 2. $10,000 FOR A SINGLE OCCURRENCE OF PROPERTY DAMAGE. c. SUBSECTIONS A AND B of this section DO NOT APPLY IF THE COURT OR a JURY DETERMINES THAT THE LOCAL GOVERNMENT official, employee or contractor ACTED IN BAD FAITH, WITH CONSCIOUS INDIFFERENCE OR WITH RECKLESSNESS. d. A LOCAL GOVERNMENT SHALL INDEMNIFY A local government official, employee or contractor FOR REASONABLE ATTORNEY FEES INCURRED IN DEFENSE OF A CRIMINAL PROSECUTION AGAINST THE local government official, employee or contractor FOR AN ACTION TAKEN BY THE local government official, employee or contractor TO ENFORCE Title 13, chapter 38, article 35 DURING THE COURSE AND SCOPE OF THE local government OFFICIAL'S, EMPLOYEE'S OR CONTRACTOR'S OFFICE, EMPLOYMENT OR CONTRACTUAL PERFORMANCE FOR OR SERVICE ON BEHALF OF THE LOCAL GOVERNMENT. e. THIS SECTION does NOT WAIVE ANY STATUTORY LIMITS ON DAMAGES UNDER STATE LAW. END_STATUTE START_STATUTE 12-828. Civil immunity for and indemnification of state officials, employees and contractors; exception A. an elected or appointed state official or a state employee or contractor is immune from liability for damages arising from a cause of action under the laws of this state resulting from an action taken by the state official, employee or contractor to enforce Title 13, chapter 38, article 35 or an order issued under section 13-4295.05 during the course and scope of the state official's, employee's or contractor's office, employment or contractual performance for or service on behalf of this state. b. this state shall indemnify an elected or appointed state official or a state employee or contractor for damages arising from a cause of action under federal law resulting from an action taken by the state official, employee or contractor to enforce Title 13, chapter 38, article 35 during the course and scope of the state official's, employee's or contractor's office, employment or contractual performance for or service on behalf of this state. notwithstanding any other law, an indemnification payment made under this subsection is not subject to an indemnification limit under the laws of this state. c. SUBSECTIONS A AND B of this section DO NOT APPLY IF THE COURT OR a JURY DETERMINES THAT THE state official, employee or contractor ACTED IN BAD FAITH, WITH CONSCIOUS INDIFFERENCE OR WITH RECKLESSNESS. d. this state SHALL INDEMNIFY A state official, employee or contractor FOR REASONABLE ATTORNEY FEES INCURRED IN DEFENSE OF A CRIMINAL PROSECUTION AGAINST THE state official, employee or contractor FOR AN ACTION TAKEN BY THE official, employee or contractor TO ENFORCE Title 13, chapter 38, article 35 DURING THE COURSE AND SCOPE OF THE state OFFICIAL'S, EMPLOYEE'S OR CONTRACTOR'S OFFICE, EMPLOYMENT OR CONTRACTUAL PERFORMANCE FOR OR SERVICE ON BEHALF OF THis state. e. the attorney general shall represent a state official, employee or contractor in any action in which the state official, employee or contractor may be entitled to indemnification under subsection b of this section. f. THIS SECTION does NOT WAIVE ANY STATUTORY LIMITS ON DAMAGES UNDER STATE LAW. END_STATUTE START_STATUTE 12-829. Appeal to supreme court for a civil action that is brought against a person who may be entitled to immunity or indemnification under section 12-827 or 12-828, an appeal must be taken directly to the supreme court. END_STATUTE START_STATUTE 12-830. Other laws not affected sections 12-827, 12-828 and 12-829 do not affect a defense, immunity or jurisdictional bar available to this state or a local government or an official, employee or contractor of this state or a local government. END_STATUTE Sec. 2. Section 13-603, Arizona Revised Statutes, is amended to read: START_STATUTE 13-603. Authorized disposition of offenders A. Every person convicted of any offense defined in this title or defined outside this title shall be sentenced in accordance with this chapter and chapters 7, 8 and 9 of this title unless otherwise provided by law. B. If a person is convicted of an offense, the court, if authorized by chapter 9 of this title, may suspend the imposition or execution of sentence and grant such person a period of probation except as otherwise provided by law. The sentence is tentative to the extent that it may be altered or revoked in accordance with chapter 9 of this title, but for all other purposes it is a final judgment of conviction. C. If a person is convicted of an offense, the court shall require the convicted person to make restitution to the person who is the victim of the crime or to the immediate family of the victim if the victim has died, in the full amount of the economic loss as determined by the court and in the manner as determined by the court or the court's designee pursuant to chapter 8 of this title. Restitution ordered pursuant to this subsection shall be paid to the clerk of the court for disbursement to the victim and is a criminal penalty for the purposes of a federal bankruptcy involving the person convicted of an offense. D. If the court imposes probation it may also impose a fine as authorized by chapter 8 of this title. E. If a person is convicted of an offense and not granted a period of probation, or when probation is revoked, any of the following sentences may be imposed: 1. A term of imprisonment authorized by this chapter or chapter 7 of this title. 2. A fine authorized by chapter 8 of this title. The sentence is tentative to the extent it may be modified or revoked in accordance with chapter 8 of this title, but for all other purposes it is a final judgment of conviction. If the conviction is of a class 2, 3 or 4 felony, the sentence cannot consist solely of a fine. 3. Both imprisonment and a fine. 4. Intensive probation, subject to the provisions of chapter 9 of this title. 5. Intensive probation, subject to the provisions of chapter 9 of this title, and a fine. 6. A new term of probation or intensive probation. 7. If the conviction is for a misdemeanor, in addition to any sentence authorized by law, a term of: (a) Community restitution pursuant to section 13-717, subsection A. (b) Education or treatment pursuant to section 13-717, subsection B. F. If an enterprise is convicted of any offense, a fine may be imposed as authorized by chapter 8 of this title. G. If a person or an enterprise is convicted of any felony, the court, in addition to any other sentence authorized by law, may order the forfeiture, suspension or revocation of any charter, license, permit or prior approval granted to the person or enterprise by any department or agency of the state or of any political subdivision. H. A court authorized to pass sentence on a person convicted of any offense defined within or without this title shall have a duty to determine and impose the punishment prescribed for such offense. I. If a person is convicted of a felony offense and the court sentences the person to a term of imprisonment, the court at the time of sentencing shall impose on the convicted person a term of community supervision. The term of community supervision shall be served consecutively to the actual period of imprisonment if the person signs and agrees to abide by conditions of supervision established by the state department of corrections. Except pursuant to subsection J of this section, the term of community supervision imposed by the court shall be for a period equal to one day for every seven days of the sentence or sentences imposed. J. In calculating the term of community supervision, all fractions shall be decreased to the nearest month, except for a class 5 or 6 felony which shall not be less than one month. K. Notwithstanding subsection I of this section, if the court sentences a person to serve a consecutive term of probation immediately after the person serves a term of imprisonment, the court may waive community supervision and order that the person begin serving the term of probation on the person's release from confinement. The court may retroactively waive the term of community supervision or that part remaining to be served if the community supervision was imposed before July 21, 1997. If the court waives community supervision, the term of probation imposed shall be equal to or greater than the term of community supervision that would have been imposed. If the court does not waive community supervision, the person shall begin serving the term of probation after the person serves the term of community supervision. The state department of corrections shall provide reasonable notice to the probation department of the scheduled release of the inmate from confinement by the department. l. notwithstanding subsections i, j and k of this section, a defendant who is convicted of an offense under chapter 38, article 35 of this title is not eligible for community supervision. [deleted: L.] M. If at the time of sentencing the court is of the opinion that a sentence that the law requires the court to impose is clearly excessive, the court may enter a special order allowing the person sentenced to petition the board of executive clemency for a commutation of sentence within ninety days after the person is committed to the custody of the state department of corrections. If the court enters a special order regarding commutation, the court shall set forth in writing its specific reasons for concluding that the sentence is clearly excessive. The court shall allow both the state and the victim to submit a written statement on the matter. The court's order, and reasons for its order, and the statements of the state and the victim shall be sent to the board of executive clemency. END_STATUTE Sec. 3. Title 13, chapter 38, Arizona Revised Statutes, is amended by adding article 35, to read: ARTICLE 35. ILLEGAL ENTRY INTO THIS STATE START_STATUTE 13-4295. Definitions in this article, unless the context otherwise requires: 1. "alien" means a person who is not a citizen or national of the united states as described in 8 united states code section 1101. 2. "port of entry" means a port of entry in the united states as described in 19 Code of federal regulations part 101.1. END_STATUTE START_STATUTE 13-4295.01. Illegal entry from foreign nation; affirmative defense; classification A. it is unlawful for a person who is an alien to enter or attempt to enter this state directly from a foreign nation at any location other than a lawful port of entry. B. It is an affirmative defense to A VIOLATION OF SUBSECTION A OF THIS SECTION if any of THE FOLLOWING applies: 1. THE FEDERAL GOVERNMENT HAS GRANTED THE DEFENDANT LAWFUL PRESENCE IN THE uNITED STATES OR ASYLUM UNDER 8 United states code SECTION 1158. 2. THE DEFENDANT'S CONDUCT does not CONSTITUTE A VIOLATION OF 8 United states code SECTION 1325( a) . 3. the defendant was approved for benefits under the deferred action for childhood arrivals program between june 15, 2012 and july 16, 2021. C. Notwithstanding subsection B of this section, the following federal programs do not provide an affirmative defense for the purposes of subsection B, paragraph 1 of this section: 1. the deferred action for parents of americans and lawful permanent residents program. 2. any program not enacted by the united states congress that is a successor to or materially similar to the program described in subsection B, paragraph 3 of this section or paragraph 1 of this subsection. D. a violation of this section is a class 1 misdemeanor, except that a violation of this section is a class 6 felony if the DEFENDANT has been previously convicted of a violation of this section. END_STATUTE START_STATUTE 13-4295.02. Illegal reentry by certain aliens; classification; definition A. it is unlawful for a person who is an alien to enter, to attempt to enter or to be found at any time in this state if either of the following applies: 1. The person has been denied admission to or excluded, deported or removed from the united states. 2. The person has departed from the united states while an order of exclusion, deportation or removal is outstanding. b. a violation of this section is a class 1 misdemeanor, except that a violation of this section is a class 3 felony if any of the following applies: 1. the defendant's removal was subsequent to a conviction for commission of two or more misdemeanors involving drugs or crimes against a person, or both. 2. the defendant was excluded pursuant to 8 United States Code section 1225( c) because the defendant was excludable under 8 united states code section 1182( a )(3)(b). 3. the defendant was removed pursuant to 8 united states code chapter 12, subchapter v. 4. the DEFENDANT was removed pursuant to 8 united states code section 1231( a )(4)(b). c. Notwithstanding subsection B of this section, a violation of this section is a class 2 felony if the defendant was removed subsequent to a conviction for the commission of a felony. d. for purposes of this section, "removal" includes an order issued pursuant to section 13-4295.05 or any other agreement in which an alien stipulates to removal pursuant to a criminal proceeding pursuant to either federal or state law. END_STATUTE START_STATUTE 13-4295.03. Refusal to comply with order to return to a foreign nation; classification A. a person who is an alien commits refusal to comply with an order to return to a foreign nation if all of the following occur: 1. the person is charged with or convicted of an offense under this article. 2. a magistrate or judge, as applicable, issues an order pursuant to section 13-4295.05 for the person to return to the foreign nation from which the person entered or attempted to enter. 3. the person refuses to comply with the order. b. a violation of this section is a class 2 felony. END_STATUTE START_STATUTE 13-4295.04. Enforcement prohibited in certain locations a peace officer may not arrest or detain a person to enforce this article if the person is on the premises or grounds of any of the following: 1. a public or private primary or postsecondary educational institution. 2. a church, synagogue or other established place of religious worship. 3. a health care facility as defined in section 36-437, including a facility that a state agency maintains or operates to provide health care, or the office of a health care provider as defined in section 12-2291, if the person is on the premises or grounds of the health care facility or office of a health care provider to receive medical treatment. END_STATUTE START_STATUTE 13-4295.05. Order to return to foreign nation A. during a person's appearance before a magistrate pursuant to section 13-3897 or 13-3898 and after determining that probable cause exists for arrest for an offense under section 13-4295.01 or 13-4295.02, the magistrate may order the person to be released from custody and issue a written order in accordance with subsection c of this section. b. At any time after a person's appearance before a magistrate pursuant to section 13-3897 or 13-3898, the judge, instead of continuing the prosecution of or entering an adjudication regarding an offense under section 13-4295.01 or 13-4295.02, may dismiss the charge pending against the person and issue a written order in accordance with subsection c of this section. c. a written order authorized by subsection a or b of this section shall discharge the person and require the person to return to the foreign nation from which the person entered or attempted to enter and may be issued if all of the following apply: 1. the person agrees to the order. 2. the person has not previously been convicted of an offense under this article or previously obtained a discharge under an order issued pursuant to this section. 3. the person is not charged with another class 1 misdemeanor or any felony offense. 4. Before the issuance of the order, the arresting law enforcement agency does all of the following: ( a ) Collects all identifying information of the person, which must include taking fingerprints from the person and using other applicable photographic and biometric measures to identify the person. ( b ) Cross-reference the collected information with all relevant local, state and federal criminal databases and federal lists or classifications that are used to identify a person as a threat or potential threat to national security. D. On conviction of an offense under this article, the judge shall enter an order that requires the person to return to the foreign nation from which the person entered or attempted to enter. An order issued under this subsection takes effect on completion of the person's term imprisonment. E. An order that is issued under this section must include both of the following: 1. The manner of transportation of the person to a port of entry. 2. The law enforcement officer or state agency that is responsible for monitoring compliance with the order. F. An order that is issued under this section must be filed with either of the following: 1. For orders entered under subsection A of this section, the county clerk of the county in which the person was arrested. 2. For orders entered under subsection B or D of this section, the clerk of the court exercising jurisdiction in the case. G. Not later than the seventh day after the date an order is issued under this section, the law enforcement officer or state agency that is required to monitor compliance with the order shall report the issuance of the order to the department of public safety for inclusion in the central state repository under section 41-1750. END_STATUTE START_STATUTE 13-4295.06. Abatement of prosecution on basis of immigration status determination prohibited the court may not abate the prosecution of an offense under this article on the basis that a federal determination regarding the immigration status of the defendant is pending or will be initiated. END_STATUTE Sec. 4. Section 31-402, Arizona Revised Statutes, is amended to read: START_STATUTE 31-402. Powers of board; powers and duties of governor; powers and duties of executive director A. For all persons who committed felony offenses before January 1, 1994, the board of executive clemency shall have exclusive power to pass on and recommend reprieves, commutations, paroles and pardons. A reprieve, commutation or pardon may not be granted by the governor unless it has first been recommended by the board. B. For all persons who committed felony offenses before January 1, 1994, all applications for reprieves, commutations and pardons made to the governor shall be at once transmitted to the chairperson of the board, and the board shall return the applications with its recommendation to the governor. All applications for reprieves, commutations and pardons made to the governor shall include documentation that the victim or the victim's family was notified pursuant to section 31-411, subsection H. C. For all persons who committed felony offenses on or after January 1, 1994, in addition to the powers and duties prescribed in subsection A of this section, the board of executive clemency: 1. Is vested with the powers and duties of the board of pardons and paroles as they existed before January 1, 1994 to carry out articles 3, 4.1, 5, 6 and 7 of this chapter. 2. After a hearing for which the victim, county attorney and presiding judge are given notice and an opportunity to be heard, may make recommendations to the governor for commutation of sentence after finding by clear and convincing evidence that the sentence imposed is clearly excessive given the nature of the offense and the record of the offender and that there is a substantial probability that when released the offender will conform the offender's conduct to the requirements of the law. 3. Shall receive petitions from individuals for whom the court has entered a special order allowing the person to petition the board pursuant to section 13-603, subsection [deleted: L] M and may make recommendations to the governor. 4. Shall receive petitions from individuals, organizations or the department for review and commutation of sentences and pardoning of offenders in extraordinary cases and may make recommendations to the governor. 5. Shall receive petitions from the state department of corrections alleging that an offender has violated the offender's terms and conditions of community supervision and has lapsed or is probably about to lapse into criminal ways or company. If the board determines that an offender on community supervision has violated the terms and conditions of community supervision the board may do any of the following: (a) If the offender has not committed an additional offense, place the offender on electronic monitoring. (b) Revoke community supervision and return the offender to prison for the remainder of the offender's community supervision. (c) Impose additional terms and conditions on the offender while keeping the offender on community supervision. If there is reasonable cause to believe that an offender who has been kept on community supervision has violated any term or condition of community supervision, any member of the board may petition the board to revoke community supervision. After a petition to revoke has been submitted, the chairperson may issue a summons directing the offender to appear on a specified date for a revocation hearing or may issue a warrant for the offender's arrest. This subsection does not limit the state department of corrections' authority with respect to submitting revocation petitions or issuing revocation warrants. D. Any recommendation for commutation that is made unanimously by the members present and voting and that is not acted on by the governor within ninety days after the board submits its recommendation to the governor automatically becomes effective. E. The executive director shall perform all administrative, operational and financial functions for the board. F. The executive director may employ case analysts as deemed necessary within the limits of legislative appropriation and subject to title 41, chapter 4, article 4. The analysts shall aid the board in making investigations, in securing information and in performing necessary administrative functions to assist the board in passing on applications for parole and commutation. G. The executive director may employ hearing officers as deemed necessary within the limits of legislative appropriation and subject to title 41, chapter 4, article 4. The hearing officers shall conduct probable cause hearings on parole, work furlough, community supervision and home arrest revocations or rescissions. Hearing officers shall assist the board in making investigations, securing information and performing necessary administrative functions. END_STATUTE Sec. 5. Section 31-403, Arizona Revised Statutes, is amended to read: START_STATUTE 31-403. Commutation; restrictions on consideration A. A person who is otherwise eligible for commutation and who is denied a commutation of sentence recommendation shall not petition or be considered by the board for commutation of that sentence for a period of five years following the date of the board's denial of the commutation recommendation if the offense for which the commutation recommendation was denied involved any of the following: 1. Death in violation of section 13-1104 or 13-1105. 2. Serious physical injury if the person was sentenced pursuant to section 13-704. 3. A dangerous crime against children as defined in section 13-705. 4. A felony offense in violation of title 13, chapter 14 or 35.1. B. Notwithstanding subsection A, paragraph 2 of this section, if, in its sole discretion, the board determines that the person committed an offense that involved serious physical injury as defined in section 13-105 and that the person was not sentenced pursuant to section 13-704, the board may order that the person shall not petition or be considered by the board for commutation of that sentence for a period of five years following the date of the board's denial of the commutation recommendation. C. Notwithstanding subsection A or B of this section, the board, at the time of denial, may lengthen the five year period of time prescribed in subsection A or B of this section to a period of up to ten years, except that if the offense for which commutation was denied involved a violation of an offense listed in subsection A, paragraph 1 of this section, the board may lengthen the period of time to a period of time that is greater than ten years and that is specified by the board by one of the following votes: 1. A majority affirmative vote if four or more members consider the action. 2. A unanimous affirmative vote if three members consider the action. 3. A unanimous affirmative vote if two members consider the action pursuant to section 31-401, subsection I and the chairman concurs after reviewing the information considered by the two members. If the chairman is one of the two members constituting a two member quorum under section 31-401, subsection I, and both the chairman and the other member vote to lengthen the five year period to a period of time greater than ten years, no further action shall be taken and the decision on whether to lengthen the five year period shall be considered by the board at a meeting at which at least three members are present and voting. D. The board may waive the provisions of subsections A, B and C of this section if any of the following applies: 1. The person is in imminent danger of death due to a medical condition, as determined by the board. 2. The person is the subject of a warrant of execution. 3. The sentence for which commutation is sought is the subject of a special order issued by the court pursuant to section 13-603, subsection [deleted: L] M . E. This section applies only to offenses that are committed on or after January 1, 2006. END_STATUTE Sec. 6. Section 41-1750, Arizona Revised Statutes, is amended to read: START_STATUTE 41-1750. Central state repository; department of public safety; duties; funds; accounts; definitions A. The department is responsible for the effective operation of the central state repository in order to collect, store and disseminate complete and accurate Arizona criminal history records and related criminal justice information. The department may procure criminal history records and related criminal justice information for violations that are not listed in this section. The department shall: 1. Procure from all criminal justice agencies in this state accurate and complete personal identification data, fingerprints, charges, process control numbers and dispositions and such other information as may be pertinent to all persons who have been charged with, arrested for, convicted of or summoned to court as a criminal defendant for any of the following: (a) A felony offense or an offense involving domestic violence as defined in section 13-3601. (b) A violation of title 13, chapter 14 or title 28, chapter 4. (c) An offense listed in: (i) Section 32-2422, subsection A, paragraph 4. (ii) Section 32-2441, paragraph 4. (iii) Section 32-2612, subsection A, paragraph 4. (iv) Section 32-2622, subsection A, paragraph 4. (v) Section 41-1758.03, subsections B and C. (vi) Section 41-1758.07, subsections B and C. ( d ) a violation of section 13-4295.01 or 13-4295.02 and for whom an order to return was issued pursuant to section 13-4295.05. 2. Collect information concerning the number and nature of offenses known to have been committed in this state and of the legal steps taken in connection with these offenses, such other information that is useful in the study of crime and in the administration of criminal justice and all other information deemed necessary to operate the statewide uniform crime reporting program and to cooperate with the federal government uniform crime reporting program. 3. Collect information concerning criminal offenses that manifest evidence of prejudice based on race, color, religion, national origin, sexual orientation, gender, antisemitism or disability. 4. Cooperate with the central state repositories in other states and with the appropriate agency of the federal government in the exchange of information pertinent to violators of the law. 5. Ensure the rapid exchange of information concerning the commission of crime and the detection of violators of the law among the criminal justice agencies of other states and of the federal government. 6. Furnish assistance to peace officers throughout this state in crime scene investigation for the detection of latent fingerprints and in the comparison of latent fingerprints. 7. Conduct periodic operational audits of the central state repository and of a representative sample of other agencies that contribute records to or receive criminal justice information from the central state repository or through the Arizona criminal justice information system. 8. Establish and enforce the necessary physical and system safeguards to ensure that the criminal justice information maintained and disseminated by the central state repository or through the Arizona criminal justice information system is appropriately protected from unauthorized inquiry, modification, destruction or dissemination as required by this section. 9. Aid and encourage coordination and cooperation among criminal justice agencies through the statewide and interstate exchange of criminal justice information. 10. Provide training and proficiency testing on the use of criminal justice information to agencies receiving information from the central state repository or through the Arizona criminal justice information system. 11. Operate and maintain the Arizona automated fingerprint identification system established by section 41-2411. 12. Provide criminal history record information to the fingerprinting division for the purpose of screening applicants for fingerprint clearance cards. B. The director may establish guidelines for the submission and retention of criminal justice information as deemed useful for the study or prevention of crime and for the administration of criminal justice. C. Criminal justice agencies may provide criminal history records and related criminal justice information for violations that are not listed in this section. The chief officers of criminal justice agencies of this state or its political subdivisions shall provide to the central state repository fingerprints and information concerning personal identification data, descriptions, crimes for which persons are arrested, process control numbers and dispositions and such other information as may be pertinent to all persons who have been charged with, arrested for, convicted of or summoned to court as criminal defendants for any of the following: 1. Felony offenses or offenses involving domestic violence as defined in section 13-3601. 2. Violations of title 13, chapter 14 or title 28, chapter 4 that have occurred in this state. 3. An offense listed in: (a) Section 32-2422, subsection A, paragraph 4. (b) Section 32-2441, paragraph 4. (c) Section 32-2612, subsection A, paragraph 4. (d) Section 32-2622, subsection A, paragraph 4. (e) Section 41-1758.03, subsections B and C. (f) Section 41-1758.07, subsections B and C. D. The chief officers of law enforcement agencies of this state or its political subdivisions shall provide to the department such information as necessary to operate the statewide uniform crime reporting program and to cooperate with the federal government uniform crime reporting program. E. The chief officers of criminal justice agencies of this state or its political subdivisions shall comply with the training and proficiency testing guidelines as required by the department to comply with the federal national crime information center mandates. F. The chief officers of criminal justice agencies of this state or its political subdivisions also shall provide to the department information concerning crimes that manifest evidence of prejudice based on race, color, religion, national origin, sexual orientation, gender, antisemitism or disability. G. The director shall authorize the exchange of criminal justice information between the central state repository, or through the Arizona criminal justice information system, whether directly or through any intermediary, only as follows: 1. With criminal justice agencies of the federal government, Indian tribes, this state or its political subdivisions and other states, on request by the chief officers of such agencies or their designated representatives, specifically for the purposes of the administration of criminal justice and for evaluating the fitness of current and prospective criminal justice employees. The department may conduct periodic state and federal criminal history records checks for the purpose of updating the status of current criminal justice employees or volunteers and may notify the criminal justice agency of the results of the records check. The department is authorized to submit fingerprints to the federal bureau of investigation to be retained for the purpose of being searched by future submissions to the federal bureau of investigation including latent fingerprint searches. 2. With any noncriminal justice agency pursuant to a statute, ordinance or executive order that specifically authorizes the noncriminal justice agency to receive criminal history record information for the purpose of evaluating the fitness of current or prospective licensees, employees, contract employees or volunteers, on submission of the subject's fingerprints and the prescribed fee. Each statute, ordinance, or executive order that authorizes noncriminal justice agencies to receive criminal history record information for these purposes shall identify the specific categories of licensees, employees, contract employees or volunteers, and shall require that fingerprints of the specified individuals be submitted in conjunction with such requests for criminal history record information. The department may conduct periodic state and federal criminal history records checks for the purpose of updating the status of current licensees, employees, contract employees or volunteers and may notify the noncriminal justice agency of the results of the records check. The department is authorized to submit fingerprints to the federal bureau of investigation to be retained for the purpose of being searched by future submissions to the federal bureau of investigation including latent fingerprint searches. 3. With the board of fingerprinting for the purpose of conducting good cause exceptions pursuant to section 41-619.55 and central registry exceptions pursuant to section 41-619.57. 4. With any individual for any lawful purpose on submission of the subject of record's fingerprints and the prescribed fee. 5. With the governor, if the governor elects to become actively involved in the investigation of criminal activity or the administration of criminal justice in accordance with the governor's constitutional duty to ensure that the laws are faithfully executed or as needed to carry out the other responsibilities of the governor's office. 6. With regional computer centers that maintain authorized computer-to-computer interfaces with the department, that are criminal justice agencies or under the management control of a criminal justice agency and that are established by a statute, ordinance or executive order to provide automated data processing services to criminal justice agencies specifically for the purposes of the administration of criminal justice or evaluating the fitness of regional computer center employees who have access to the Arizona criminal justice information system and the national crime information center system. 7. With an individual who asserts a belief that criminal history record information relating to the individual is maintained by an agency or in an information system in this state that is subject to this section. On submission of fingerprints, the individual may review this information for the purpose of determining its accuracy and completeness by making application to the agency operating the system. Rules adopted under this section shall include provisions for administrative review and necessary correction of any inaccurate or incomplete information. The review and challenge process authorized by this paragraph is limited to criminal history record information. 8. With individuals and agencies pursuant to a specific agreement with a criminal justice agency to provide services required for the administration of criminal justice pursuant to that agreement if the agreement specifically authorizes access to data, limits the use of data to purposes for which given and ensures the security and confidentiality of the data consistent with this section. 9. With individuals and agencies for the express purpose of research, evaluative or statistical activities pursuant to an agreement with a criminal justice agency if the agreement specifically authorizes access to data, limits the use of data to research, evaluative or statistical purposes and ensures the confidentiality and security of the data consistent with this section. 10. With the auditor general for audit purposes. 11. With central state repositories of other states for noncriminal justice purposes for dissemination in accordance with the laws of those states. 12. On submission of the fingerprint card, with the department of child safety and a tribal social services agency to provide criminal history record information on prospective adoptive parents for the purpose of conducting the preadoption certification investigation under title 8, chapter 1, article 1 if the department of economic security is conducting the investigation, or with an agency or a person appointed by the court, if the agency or person is conducting the investigation. Information received under this paragraph shall only be used for the purposes of the preadoption certification investigation. 13. With the department of child safety, a tribal social services agency and the superior court for the purpose of evaluating the fitness of custodians or prospective custodians of juveniles, including parents, relatives and prospective guardians. Information received under this paragraph shall only be used for the purposes of that evaluation. The information shall be provided on submission of either: (a) The fingerprint card. (b) The name, date of birth and social security number of the person. 14. On submission of a fingerprint card, provide criminal history record information to the superior court for the purpose of evaluating the fitness of investigators appointed under section 14-5303 or 14-5407, guardians appointed under section 14-5206 or 14-5304 or conservators appointed under section 14-5401. 15. With the supreme court to provide criminal history record information on prospective fiduciaries pursuant to section 14-5651. 16. With the department of juvenile corrections to provide criminal history record information pursuant to section 41-2814. 17. On submission of the fingerprint card, provide criminal history record information to the Arizona peace officer standards and training board or a board certified law enforcement academy to evaluate the fitness of prospective cadets. 18. With the internet sex offender website database established pursuant to section 13-3827. 19. With licensees of the United States nuclear regulatory commission for the purpose of determining whether an individual should be granted unescorted access to the protected area of a commercial nuclear generating station on submission of the subject of record's fingerprints and the prescribed fee. 20. With the state board of education for the purpose of evaluating the fitness of a certificated educator, an applicant for a teaching or administrative certificate or a noncertificated person as defined in section 15-505 if the state board of education or its employees or agents have reasonable suspicion that the educator or person engaged in conduct that would be a criminal violation of the laws of this state or was involved in immoral or unprofessional conduct or that the applicant engaged in conduct that would warrant disciplinary action if the applicant were certificated at the time of the alleged conduct. The information shall be provided on the submission of either: (a) The fingerprint card. (b) The name, date of birth and social security number of the person. 21. With each school district and charter school in this state. The department of education and the state board for charter schools shall provide the department of public safety with a current list of email addresses for each school district and charter school in this state and shall periodically provide the department of public safety with updated email addresses. If the department of public safety is notified that a person who is required to have a fingerprint clearance card to be employed by or to engage in volunteer activities at a school district or charter school has been arrested for or convicted of an offense listed in section 41-1758.03, subsection B or has been arrested for or convicted of an offense that amounts to unprofessional conduct under section 15-550, the department of public safety shall notify each school district and charter school in this state that the person's fingerprint clearance card has been suspended or revoked. 22. With a tribal social services agency and the department of child safety as provided by law, which currently is the Adam Walsh child protection and safety act of 2006 (42 United States Code section 16961), for the purposes of investigating or responding to reports of child abuse, neglect or exploitation. Information received pursuant to this paragraph from the national crime information center, the interstate identification index and the Arizona criminal justice information system network shall only be used for the purposes of investigating or responding as prescribed in this paragraph. The information shall be provided on submission to the department of public safety of either: (a) The fingerprints of the person being investigated. (b) The name, date of birth and social security number of the person. 23. With a nonprofit organization that interacts with children or vulnerable adults for the lawful purpose of evaluating the fitness of all current and prospective employees, contractors and volunteers of the organization. The criminal history record information shall be provided on submission of the applicant fingerprint card and the prescribed fee. 24. With the superior court for the purpose of determining an individual's eligibility for substance abuse and treatment courts in a family or juvenile case. 25. With the governor to provide criminal history record information on prospective gubernatorial nominees, appointees and employees as provided by law. H. The director shall adopt rules necessary to execute this section. I. The director, in the manner prescribed by law, shall remove and destroy records that the director determines are no longer of value in the detection or prevention of crime. J. The director shall establish a fee in an amount necessary to cover the cost of federal noncriminal justice fingerprint processing for criminal history record information checks that are authorized by law for noncriminal justice employment, licensing or other lawful purposes. An additional fee may be charged by the department for state noncriminal justice fingerprint processing. Fees submitted to the department for state noncriminal justice fingerprint processing are not refundable. K. The director shall establish a fee in an amount necessary to cover the cost of processing copies of department reports, eight by ten inch black and white photographs or eight by ten inch color photographs of traffic accident scenes. L. Except as provided in subsection O of this section, each agency authorized by this section may charge a fee, in addition to any other fees prescribed by law, in an amount necessary to cover the cost of state and federal noncriminal justice fingerprint processing for criminal history record information checks that are authorized by law for noncriminal justice employment, licensing or other lawful purposes. M. A fingerprint account within the records processing fund is established for the purpose of separately accounting for the collection and payment of fees for noncriminal justice fingerprint processing by the department. Monies collected for this purpose shall be credited to the account, and payments by the department to the United States for federal noncriminal justice fingerprint processing shall be charged against the account. Monies in the account not required for payment to the United States shall be used by the department in support of the department's noncriminal justice fingerprint processing duties. At the end of each fiscal year, any balance in the account not required for payment to the United States or to support the department's noncriminal justice fingerprint processing duties reverts to the state general fund. N. A records processing fund is established for the purpose of separately accounting for the collection and payment of fees for department reports and photographs of traffic accident scenes processed by the department. Monies collected for this purpose shall be credited to the fund and shall be used by the department in support of functions related to providing copies of department reports and photographs. At the end of each fiscal year, any balance in the fund not required for support of the functions related to providing copies of department reports and photographs reverts to the state general fund. O. The department of child safety may pay from appropriated monies the cost of federal fingerprint processing or federal criminal history record information checks that are authorized by law for employees and volunteers of the department, guardians pursuant to section 8-453, subsection A, paragraph 6, the licensing of foster parents or the certification of adoptive parents. P. The director shall adopt rules that provide for: 1. The collection and disposition of fees pursuant to this section. 2. The refusal of service to those agencies that are delinquent in paying these fees. Q. The director shall ensure that the following limitations are observed regarding dissemination of criminal justice information obtained from the central state repository or through the Arizona criminal justice information system: 1. Any criminal justice agency that obtains criminal justice information from the central state repository or through the Arizona criminal justice information system assumes responsibility for the security of the information and shall not secondarily disseminate this information to any individual or agency not authorized to receive this information directly from the central state repository or originating agency. 2. Dissemination to an authorized agency or individual may be accomplished by a criminal justice agency only if the dissemination is for criminal justice purposes in connection with the prescribed duties of the agency and not in violation of this section. 3. Criminal history record information disseminated to noncriminal justice agencies or to individuals shall be used only for the purposes for which it was given. Secondary dissemination is prohibited unless otherwise authorized by law. 4. The existence or nonexistence of criminal history record information shall not be confirmed to any individual or agency not authorized to receive the information itself. 5. Criminal history record information to be released for noncriminal justice purposes to agencies of other states shall only be released to the central state repositories of those states for dissemination in accordance with the laws of those states. 6. Criminal history record information shall be released to noncriminal justice agencies of the federal government pursuant to the terms of the federal security clearance information act (P.L. 99-169). R. This section and the rules adopted under this section apply to all agencies and individuals collecting, storing or disseminating criminal justice information processed by manual or automated operations if the collection, storage or dissemination is funded in whole or in part with monies made available by the law enforcement assistance administration after July 1, 1973, pursuant to title I of the crime control act of 1973, and to all agencies that interact with or receive criminal justice information from or through the central state repository and through the Arizona criminal justice information system. S. This section does not apply to criminal history record information contained in: 1. Posters, arrest warrants, announcements or lists for identifying or apprehending fugitives or wanted persons. 2. Original records of entry such as police blotters maintained by criminal justice agencies, compiled chronologically and required by law or long-standing custom to be made public if these records are organized on a chronological basis. 3. Transcripts or records of judicial proceedings if released by a court or legislative or administrative proceedings. 4. Announcements of executive clemency or pardon. 5. Computer databases, other than the Arizona criminal justice information system, that are specifically designed for community notification of an offender's presence in the community pursuant to section 13-3825 or for public informational purposes authorized by section 13-3827. T. Nothing in this section prevents a criminal justice agency from disclosing to the public criminal history record information that is reasonably contemporaneous to the event for which an individual is currently within the criminal justice system, including information noted on traffic accident reports concerning citations, blood alcohol tests or arrests made in connection with the traffic accident being investigated. U. In order to ensure that complete and accurate criminal history record information is maintained and disseminated by the central state repository: 1. The booking agency shall take legible ten-print fingerprints of all persons who are arrested for offenses listed in subsection C of this section. The booking agency shall obtain a process control number and provide to the person fingerprinted a document that indicates proof of the fingerprinting and that informs the person that the document must be presented to the court. 2. Except as provided in paragraph 3 of this subsection, if a person is summoned to court as a result of an indictment or complaint for an offense listed in subsection C of this section, the court shall order the person to appear before the county sheriff and provide legible ten-print fingerprints. The county sheriff shall obtain a process control number and provide a document to the person fingerprinted that indicates proof of the fingerprinting and that informs the person that the document must be presented to the court. For the purposes of this paragraph, "summoned" includes a written promise to appear by the defendant on a uniform traffic ticket and complaint. 3. If a person is arrested for a misdemeanor offense listed in subsection C of this section by a city or town law enforcement agency, the person shall appear before the law enforcement agency that arrested the defendant and provide legible ten-print fingerprints. The law enforcement agency shall obtain a process control number and provide a document to the person fingerprinted that indicates proof of the fingerprinting and that informs the person that the document must be presented to the court. 4. The mandatory fingerprint compliance form shall contain the following information: (a) Whether ten-print fingerprints have been obtained from the person. (b) Whether a process control number was obtained. (c) The offense or offenses for which the process control number was obtained. (d) Any report number of the arresting authority. (e) Instructions on reporting for ten-print fingerprinting, including available times and locations for reporting for ten-print fingerprinting. (f) Instructions that direct the person to provide the form to the court at the person's next court appearance. 5. Within ten days after a person is fingerprinted, the arresting authority or agency that took the fingerprints shall forward the fingerprints to the department in the manner or form required by the department. 6. On the issuance of a summons for a defendant who is charged with an offense listed in subsection C of this section, the summons shall direct the defendant to provide ten-print fingerprints to the appropriate law enforcement agency. 7. At the initial appearance or on the arraignment of a summoned defendant who is charged with an offense listed in subsection C of this section, if the person does not present a completed mandatory fingerprint compliance form to the court or if the court has not received the process control number, the court shall order that within twenty calendar days the defendant be ten-print fingerprinted at a designated time and place by the appropriate law enforcement agency. 8. If the defendant fails to present a completed mandatory fingerprint compliance form or if the court has not received the process control number, the court, on its own motion, may remand the defendant into custody for ten-print fingerprinting. If otherwise eligible for release, the defendant shall be released from custody after being ten-print fingerprinted. 9. In every criminal case in which the defendant is incarcerated or fingerprinted as a result of the charge, an originating law enforcement agency or prosecutor, within forty days of the disposition, shall advise the central state repository of all dispositions concerning the termination of criminal proceedings against an individual arrested for an offense specified in subsection C of this section. This information shall be submitted on a form or in a manner required by the department. 10. Dispositions resulting from formal proceedings in a court having jurisdiction in a criminal action against an individual who is arrested for an offense specified in subsection C of this section or section 8-341, subsection Q, paragraph 3 shall be reported to the central state repository within forty days of the date of the disposition. This information shall be submitted on a form or in a manner specified by rules approved by the supreme court. 11. The state department of corrections or the department of juvenile corrections, within forty days, shall advise the central state repository that it has assumed supervision of a person convicted of an offense specified in subsection C of this section or section 8-341, subsection Q, paragraph 3. The state department of corrections or the department of juvenile corrections shall also report dispositions that occur thereafter to the central state repository within forty days of the date of the dispositions. This information shall be submitted on a form or in a manner required by the department of public safety. 12. Each criminal justice agency shall query the central state repository before dissemination of any criminal history record information to ensure the completeness of the information. Inquiries shall be made before any dissemination except in those cases in which time is of the essence and the repository is technically incapable of responding within the necessary time period. If time is of the essence, the inquiry shall still be made and the response shall be provided as soon as possible. V. The director shall adopt rules specifying that any agency that collects, stores or disseminates criminal justice information that is subject to this section shall establish effective security measures to protect the information from unauthorized access, disclosure, modification or dissemination. The rules shall include reasonable safeguards to protect the affected information systems from fire, flood, wind, theft, sabotage or other natural or man-made hazards or disasters. W. The department shall make available to agencies that contribute to, or receive criminal justice information from, the central state repository or through the Arizona criminal justice information system a continuing training program in the proper methods for collecting, storing and disseminating information in compliance with this section. X. Nothing in this section creates a cause of action or a right to bring an action including an action based on discrimination due to sexual orientation. Y. The definition prescribed in subsection Z, paragraph 3 of this section does not diminish or infringe on any rights protected under the first amendment to the United States constitution or the Arizona constitution. Z. For the purposes of this section: 1. "Administration of criminal justice" means performance of the detection, apprehension, detention, pretrial release, posttrial release, prosecution, adjudication, correctional supervision or rehabilitation of criminal offenders. Administration of criminal justice includes enforcement of criminal traffic offenses and civil traffic violations, including parking violations, when performed by a criminal justice agency. Administration of criminal justice also includes criminal identification activities and the collection, storage and dissemination of criminal history record information. 2. "Administrative records" means records that contain adequate and proper documentation of the organization, functions, policies, decisions, procedures and essential transactions of the agency and that are designed to furnish information to protect the rights of this state and of persons directly affected by the agency's activities. 3. "Antisemitism" includes the definition of antisemitism that was adopted by the international holocaust remembrance alliance on May 26, 2016 and that has been adopted by the United States department of state, including the contemporary examples of antisemitism identified in the adopted definition. 4. "Arizona criminal justice information system" or "system" means the statewide information system managed by the director for the collection, processing, preservation, dissemination and exchange of criminal justice information and includes the electronic equipment, facilities, procedures and agreements necessary to exchange this information. 5. "Booking agency" means the county sheriff or, if a person is booked into a municipal jail, the municipal law enforcement agency. 6. "Central state repository" means the central location within the department for the collection, storage and dissemination of Arizona criminal history records and related criminal justice information. 7. "Criminal history record information" and "criminal history record" means information that is collected by criminal justice agencies on individuals and that consists of identifiable descriptions and notations of arrests, detentions, indictments and other formal criminal charges, and any disposition arising from those actions, sentencing, formal correctional supervisory action and release. Criminal history record information and criminal history record do not include identification information to the extent that the information does not indicate involvement of the individual in the criminal justice system or information relating to juveniles unless they have been adjudicated as adults. 8. "Criminal justice agency" means either: (a) A court at any governmental level with criminal or equivalent jurisdiction, including courts of any foreign sovereignty duly recognized by the federal government. (b) A government agency or subunit of a government agency that is specifically authorized to perform as its principal function the administration of criminal justice pursuant to a statute, ordinance or executive order and that allocates more than fifty percent of its annual budget to the administration of criminal justice. This subdivision includes agencies of any foreign sovereignty duly recognized by the federal government. 9. "Criminal justice information" means information that is collected by criminal justice agencies and that is needed for the performance of their legally authorized and required functions, such as criminal history record information, citation information, stolen property information, traffic accident reports, wanted persons information and system network log searches. Criminal justice information does not include the administrative records of a criminal justice agency. 10. "Disposition" means information disclosing that a decision has been made not to bring criminal charges or that criminal proceedings have been concluded or information relating to sentencing, correctional supervision, release from correctional supervision, the outcome of an appellate review of criminal proceedings or executive clemency. 11. "Dissemination" means the written, oral or electronic communication or transfer of criminal justice information to individuals and agencies other than the criminal justice agency that maintains the information. Dissemination includes the act of confirming the existence or nonexistence of criminal justice information. 12. "Management control": (a) Means the authority to set and enforce: (i) Priorities regarding development and operation of criminal justice information systems and programs. (ii) Standards for the selection, supervision and termination of personnel involved in the development of criminal justice information systems and programs and in the collection, maintenance, analysis and dissemination of criminal justice information. (iii) Policies governing the operation of computers, circuits and telecommunications terminals used to process criminal justice information to the extent that the equipment is used to process, store or transmit criminal justice information. (b) Includes the supervision of equipment, systems design, programming and operating procedures necessary for the development and implementation of automated criminal justice information systems. 13. "Process control number" means the Arizona automated fingerprint identification system number that attaches to each arrest event at the time of fingerprinting and that is assigned to the arrest fingerprint card, disposition form and other pertinent documents. 14. "Secondary dissemination" means the dissemination of criminal justice information from an individual or agency that originally obtained the information from the central state repository or through the Arizona criminal justice information system to another individual or agency. 15. "Sexual orientation" means consensual homosexuality or heterosexuality. 16. "Subject of record" means the person who is the primary subject of a criminal justice record. END_STATUTE (ENACTED WITHOUT THE EMERGENCY) Sec. 7. Emergency This act is an emergency measure that is necessary to preserve the public peace, health or safety and is operative immediately as provided by law.

---
snapshot_id: 125fe8a9-eb1b-515f-9261-332a868709f6
source_kind: public-record
url: https://apps.azleg.gov/BillStatus/BillOverview?SessionID=128&BillNumber=SB1231

Bill Status Inquiry. Bill History for SB1231. Short Title: state crime; illegal border crossings. Sponsors: Shamp (Prime) Bennett (Co-Sponsor) Bolick (Co-Sponsor) Carroll (Co-Sponsor) Farnsworth (Co-Sponsor) Gowan (Co-Sponsor) Hoffman (Co-Sponsor) Kavanagh (Co-Sponsor) Kern (Co-Sponsor) Kerr (Co-Sponsor) Petersen (Co-Sponsor) Rogers (Co-Sponsor) Shope (Co-Sponsor) Wadsack (Co-Sponsor) Senate THIRD 02/21/2024 16-13-1-0-0 PASSED (Amended, Without Emergency). House THIRD 02/28/2024 31-28-0-0-1 PASSED. Governor Action 03/04/2024 Vetoed [Bill overview for SB1231 (2024), saved by browser from apps.azleg.gov BillStatus on 2026-10-06.]

---
snapshot_id: 1486069c-8039-5984-aac6-3e2f54f0e1db
source_kind: public-record
url: https://apps.azleg.gov/BillStatus/BillOverview?SessionID=128&BillNumber=SB1231#senate-third

Senate Third Reading - SB1231 state crime; illegal border crossings Action Date Action Vote 02/21/2024 Passed 16-13-1-0-0 Amended Without Emergency ALSTON N BENNETT Y BOLICK Y BORRELLI Y BRAVO N BURCH N CARROLL Y DIAZ NV EPSTEIN N FARNSWORTH Y FERNANDEZ N GABALDÓN N GONZALES N GOWAN Y HATATHLIE N HERNANDEZ N HOFFMAN Y KAVANAGH Y KERN Y KERR Y MARSH N MENDEZ N MESNARD Y MIRANDA N ROGERS Y SHAMP Y SHOPE Y SUNDARESHAN N WADSACK Y PETERSEN Y [Vote detail dialog for SB1231 (2024) Senate Third Reading, saved by browser from apps.azleg.gov BillStatus on 2026-10-06.]

---
snapshot_id: d8b53c96-0bbb-5e9d-87e2-d67475de3328
source_kind: news (excerpt only)
url: https://www.kjzz.org/2024-02-21/content-1871968-arizona-republicans-move-controversial-immigration-bills-despite-hobbs-veto-threat

… Login E-Member Login Member Portal Access KJZZ Plus E-Member Login Member Portal Access KJZZ Plus News Arizona Republicans move controversial immigration bills despite Hobbs veto threat KJZZ | By Wayne Schutsky Published February 21, 2024 at 7:47 PM MST Facebook Threads LinkedIn Bluesky Email Listen Republican lawmakers at the Arizona Legislature advanced multiple immigration bills Wednesday that drew comparisons to the controversial SB 1070 immigration law that passed over a decade ago. Sen. Janae Shamp’s (R-Surprise) Senate Bill 1231, also called the Arizona Border Invasion Act, would make it a state crime to cross Arizona’s southern border illegally. It would essentially duplicate federal law by prohibiting a person from entering Arizona from Mexico outside a port of entry, or reentering the state if they had already been deported. Democrats opposed the bill, saying it is the federal government, not the state, that is responsible for immigration law and border security. But Shamp said the bill will empower state and local law enforcement to arrest individuals at the border, arguing that the federal government has failed to fulfill its duty to secure the border. “Every single day Joe Biden allows this invasion at our southern border to continue, the lives of Arizonans remain in grave danger,” Shamp said in a statement. Howard Fischer/Capitol Media Services State Sen. Janae Shamp at the Arizona Capitol on Thursday, Feb. 1, 2024. The Arizona Senate passed the bill on a part-line vote on Wednesday. Similar bills sponsored by Reps. Joseph Chaplik (R-Scottsdale) and Steve Montenegro (R-Goodyear) survived procedural votes with only Republican support in the Arizona House of Representatives. Democrats compared the bills to SB 1070, the immigration law passed by Arizona lawmakers in 2010 that was partially overturned by the U.S. Supreme Court after a majority of justices found sections empowering state and local police to enforce immigration laws conflicted with federal law. They said SB 1070 disproportionately affected specific groups and that they believed the new legislation would have a similar impact. “Within 12 months, I was pulled over more than 10 times by …

---
snapshot_id: b9b4e91d-3b34-52e1-89d7-db46344d6d08
source_kind: news (excerpt only)
url: https://www.fox10phoenix.com/news/sb1231-gov-katie-hobbs-vetoes-bill-on-border-crossing-saying-the-bill-does-not-secure-our-border

… to the United States by a willfully false or misleading representation or the willful concealment of a material fact." AZ Gov. vetoes Arizona Border Invasion Act bill Arizona Governor Katie Hobbs announced on March 4 that she had vetoed a State Senate bill that would have made it a crime for an unlawful immigrant to cross the border at any location other than a lawful port of entry. In her letter to State Senate President Warren Petersen, Gov. Hobbs said the bill "does not secure our border, will be harmful for communities and businesses in our state, and burdensome for law enforcement personnel and the state judicial system." Gov. Hobbs also stated in her letter that the bill "presents significant constitutional concerns," and will become the subject of long and costly litigation involving the state. In response, Republicans in the Arizona State Senate released a statement condemning Gov. Hobbs' veto. "The Legislature did its job to protect our citizens, but Governor Hobbs failed to do hers. Vetoing the Arizona Border Invasion Act is a prime example of the chaos Hobbs is unleashing in our state while perpetuating this open border crisis as Biden's accomplice," State Sen. Janae Shamp ( District 29 ) wrote, in the statement. Arizona Politics U.S. Border Security Katie Hobbs News Phoenix Breaking News Breaking news delivered fast By clicking Sign Up, I confirm that I have read and agree to the Privacy Policy and Terms of Service . Just In... View More 'Saved by the Bell' star Dennis Haskins cause of death revealed: Report Bus driver hailed hero after fatal Polk County bus crash that killed 2, including high school student University of Arizona suspends all fraternity activities amid misconduct investigation 2026 AZ voter guide: What to know about the races Nature’s Own recalls Hawaiian Bread sold in 5 states Trending Homeowners, subcontractors speak out …

---
snapshot_id: 4fd78a7a-f8e3-5b48-b6c2-e36e56d47f36
source_kind: public-record
url: https://apps.azleg.gov/BillStatus/BillOverview?SessionID=128&BillNumber=HCR2060#senate-third

Senate Third Reading - HCR2060 lawful presence; e-verify program; penalties (NOW: border; benefits; fentanyl; illegal entry) Action Date Action Vote 05/22/2024 Passed 16-13-1-0-0 Amended ALSTON NV BENNETT Y BOLICK Y BORRELLI Y BRAVO N BURCH N CARROLL Y DIAZ N EPSTEIN N FARNSWORTH Y FERNANDEZ N GABALDÓN N GONZALES N GOWAN Y HATATHLIE N HERNANDEZ N HOFFMAN Y KAVANAGH Y KERN Y KERR Y MARSH N MENDEZ N MESNARD Y MIRANDA N ROGERS Y SHAMP Y SHOPE Y SUNDARESHAN N WADSACK Y PETERSEN Y [Vote detail dialog for HCR2060 (2024) Senate Third Reading, saved by browser from apps.azleg.gov BillStatus on 2026-10-06.]