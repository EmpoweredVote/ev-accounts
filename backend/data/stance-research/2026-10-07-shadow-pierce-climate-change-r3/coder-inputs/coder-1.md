You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-pierce-climate-change-r3/labels/coder-1.json. Write JSON only, matching
codebook Part E, with "codebook_version": "0.4" and "coder_slot": 1. One row per
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
**Updated 2026-10-06 (still 0.4 — ruling by Chris Andrews, option B "positions without a lever"):**
scope now decides **which evidence counts**, not whether a chair can exist. Every level is asked every
topic unless an exclusion is named; at a level with no lever, only the person's own words can seat a
chair (V2 "No-lever level"). `scope-unavailable` narrows to the named exclusions (V6). Code computes
the row's evidence basis, never the coder. The version stays 0.4: no recorded gold turns on the change
(the two `scope-unavailable` gold rows are `excluded_from_cert`), and own-words rows form their own
stratum with no gold yet. Memo: `.planning/todos/2026-10-06-positions-without-a-lever.md` (workspace
root).
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
5. **Scope decides the evidence, per rung (ruling 2026-10-06, option B).** A record needs a lever: a
   rung that no officeholder at this level can act on cannot be evidenced at this level by a record.
   It can still be evidenced by the person's own words (V2 "No-lever level"). A voter may want to
   know a mayor's view on abortion even though she cannot change the law.
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

- **No-lever level (ruling 2026-10-06, Chris Andrews, option B).** Read the annex line "Levels that
  hold a lever" for the rung. If the seat's level is not listed there, the level holds no lever on
  that rung, and **only the person's own words** (V3 `statement-answer` or `statement-other`) can
  support it. The prompt also says so per topic ("Evidence basis at this seat's level: OWN WORDS
  ONLY") when no rung of the topic has a lever at that level.
  - An act of this office on such a rung cannot enact it. A vote or bill at this level is coded on
    what its text does, against the rung's clauses; a law on a neighbouring matter is `adjacent`, as
    anywhere else (no example is given here: the item that prompted this rule is to be re-labelled
    blind). A resolution that only urges another level to act is V4 `rhetorical`, unless its text
    states every clause of one rung.
    _owed:_ whether a member's vote for a resolution that states every clause of a rung counts as
    their own words (statement class) or stays a record that cannot seat a chair at a no-lever level.
    Until ruled: code it `statement-other` and let the row go to review.
  - A record from another level stays `pre-seating` (V5); it is not this person's act in this office.
  - The election-cycle rule (V5, Q4) applies unchanged.
  - **Not** this rule: a level the topic is not asked at all (no `compass_topic_roles` row, or a
    named exclusion). That row is not coded; V6 `scope-unavailable`.

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
    question). Their **own words** from that time are statements, decided by the election-cycle rule
    below.
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
| `scope-unavailable` | This level is **not asked** this topic or rung: a named exclusion (no `compass_topic_roles` row for the level, or the annex rules the office out). Normally dropped before coding. Since 2026-10-06 the lack of a lever alone is **not** this reason: own words can still seat the chair (V2 "No-lever level"). |

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
  - **Two statements on one day (ruling 2026-10-06, Chris Andrews).** A date is not an occasion: a
    debate answer and a questionnaire on the same day are two occasions. Two same-day statements count
    as two sources only if (1) both are the person's own words on a first-party page, not news or a
    pointer; (2) they are on different snapshots; and (3) their texts do not overlap — one page does
    not reprint the other's words. News on that day adds no source.
  - _owed:_ whether the person's own explanation of a vote counts as a second source for that same
    vote, or as the same act. Until ruled, it is the same act (one source).
  - A tier never upgrades a blank: two `direction-only` sources are still BLANK `direction-only`.
- **Evidence basis (ruling 2026-10-06, Chris Andrews; option B).** Computed by code, never coded, from
  `compass_topic_roles.evidence_basis` for the topic at the seat's level (CA_0302): `record` (the
  level holds a lever) or `own-words` (it holds none). It is not shown to voters: they see the sources
  (the evidence chain). It splits the reliability strata — a certification measured on `record` rows
  never covers `own-words` rows — and an own-words chair goes to review until its own stratum is
  certified. A chair from own words is compared with the voter's view like any other chair.

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
Levels with a lever: federal / state / local / school — records and own words count here
Asked at: every level unless excluded (compass_topic_roles); a level asked but not listed above is own words only
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

politician_id: 72dd5219-490f-48bb-986e-183a6098d602  office_id: 7b3f68ef-bd9b-4316-9e39-89091b6e9aa1
Matt Pierce — Representative, Indiana (seated, level: state)
Current term: 2002-01-01 (precision: year) to present

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

# climate-change — served revision 5f1403f3-90b6-491f-ba54-3c8e46a5ae26 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris
Andrews). Lines marked _(proposed)_ are a drafter's reading, not yet ruled.

**Question:** "How much should government do to expand clean energy?"

**Orientation:** standard. Rung 1 is the most government action (a legal requirement), rung 5 ends
government support. The rungs order **mechanisms** — require, fund, ease, stay neutral, end support —
not the size of an emissions goal.

**Levels with a lever:** federal, state, local.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "renewable portfolio standard" (RPS), "clean energy standard", "zero-carbon" or "100%
clean" electricity, "net zero", "renewable energy credit", "investment tax credit", "production tax
credit", "green bank", "interconnection", "transmission siting", "permitting reform",
"technology-neutral", "all of the above".

1. **"Require a shift to clean energy through mandates and firm deadlines."**
   - Means: the law makes the move to clean energy compulsory, by dates that bind.
   - Operative clauses: [a] a legal requirement to supply, buy or use clean energy; [b] a firm
     deadline.
   - Establishing evidence looks like: operative text with a binding verb ("shall ensure", "shall
     procure", "each retail seller shall") attached to a clean-energy share and a date; own words
     calling for such a requirement.
   - Levels that hold a lever: state (standards on utilities and retail sellers); federal (a national
     clean-electricity standard); local (municipal-utility procurement, building codes).
   - Known chair-shaped instruments: a single-subject renewable or clean-electricity standard whose
     dated percentages sit in binding text.
   - Commonly confused with BLANK because a dated **goal** reads like a deadline. A "policy of the
     state", a "goal", an "intent" or an "aim" is not a mandate, even with a year attached. If the
     instrument only states the goal and orders the agency to recommend measures or study
     feasibility → `direction-only` (and the study part is `study-directive`). One binding clause
     with a date in the same bill is enough for [a] and [b]; the goal clauses beside it do not cancel
     it.
   - Commonly confused with BLANK because an **emissions** target is not a clean-energy requirement.
     A net-zero or percent-reduction target that the state may meet by any means (including carbon
     capture) does not require clean energy → `direction-only`.

2. **"Fund clean energy with major subsidies, tax credits, and public investment."**
   - Means: government pays, at scale, to grow clean energy, and does not require it.
   - Operative clauses: [a] public money for clean energy — a subsidy, a tax credit or public
     investment; [b] "major" — at scale.
   - Establishing evidence looks like: authoring or a final-passage vote on a single-subject clean-energy
     credit, rebate or investment programme of significant size, **plus** something that excludes
     rung 1 (a vote or own words against a mandate). A funding record alone does not exclude rung 1,
     so it is `direction-only` (V4: chair-shaped must exclude the adjacent rungs) _(proposed)_.
   - Levels that hold a lever: federal (tax credits), state (incentive programmes, green banks), local
     (municipal investment, rebates).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1 because many bills both fund and require; code the requirement
     when its clause is binding and dated.
   - Commonly confused with rung 3 because public money for the **grid** matches "public investment"
     and "upgrading the grid". One passage that matches two rungs excludes neither, so a grid
     **appropriation** alone → `direction-only`. Grid **rules** that are not spending
     (interconnection reform, transmission-planning orders) are rung 3 clause [b] _(ruled
     2026-10-01)_.
   - The list "subsidies, tax credits, and public investment" names forms of one clause, so one form
     is enough _(proposed)_. A small pilot grant is not "major" → `direction-only` _(proposed)_.

3. **"Speed up clean energy by cutting permitting red tape and upgrading the grid."**
   - Means: government removes obstacles to building clean energy, without paying for or requiring it.
   - Operative clauses: [a] cut permitting delay for clean-energy projects; [b] upgrade the grid
     (transmission, interconnection).
   - Establishing evidence looks like: a permitting or siting reform aimed at clean-energy projects
     **and** a grid measure. Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: federal (transmission siting, federal permits), state (siting boards,
     interconnection rules), local (local permits and zoning for solar, wind, storage).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a permitting bill that speeds **all** energy projects
     equally is technology-neutral. It speeds up clean projects too, so it meets rung 3 clause [a]
     (and alone gives `compound-partial` until [b] is evidenced). It does **not** support rung 4:
     rung 4 needs evidence that the person rejects any preference among sources, and a neutral bill
     is silent on that (V4.2 "Silence is not a clause") _(ruled 2026-10-01)_.
   - Commonly confused with rung 2: see rung 2.

4. **"Stay neutral on energy and let the market choose among all sources."**
   - Means: government favours no energy source; prices and private choices decide. (This is the one
     rung where the S1 draft text still applies.)
   - Operative clauses: [a] no government preference for any source; [b] the market chooses.
   - Establishing evidence looks like: own words that reject preferences for every source; a record
     that removes support for clean **and** other sources alike.
   - Levels that hold a lever: federal, state, local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because ending clean-energy support while keeping support for other
     sources is not neutral. It can be rung 5; it is not rung 4.
   - "All of the above" usually means support for every source, not neutrality → not rung 4 unless
     the passage says government should not pick _(proposed)_.

5. **"End government subsidies and mandates for clean energy."**
   - Means: government stops both paying for and requiring clean energy.
   - Operative clauses: [a] end clean-energy subsidies; [b] end clean-energy mandates.
   - Establishing evidence looks like: repeal of a clean-energy standard **and** of clean-energy
     credits or subsidies, or own words calling for both. Compound: one side only →
     `compound-partial` (V4.2) _(proposed)_.
   - Levels that hold a lever: federal, state, local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Preemption (codebook V2, H12).** A state law that forbids local clean-energy rules, or local bans
  on gas hookups, decides which level may act → `adjacent`.
- **The government's own operations.** A clause that sets clean-energy or net-zero requirements only
  for the government's own buildings, fleet or electricity purchases, is **on-question**: government
  buying clean energy expands clean energy. The **verb** decides the rung, not whose energy it is. A
  binding, dated duty ("each state agency shall ensure … by [date]") is rung 1; an "aim", "intent" or
  "goal" → `direction-only`. A narrow scope does not change the mechanism _(ruled 2026-10-01)_.
- **Carbon pricing** (cap-and-trade, a carbon tax) prices emissions; it does not require, fund or ease
  clean energy as such → `direction-only` unless the passage names a clean-energy clause
  _(proposed)_.
- **Vehicle rules** (zero-emission sales requirements, EV credits) are transport, not energy supply.
  The rungs speak of permitting, the grid and choice among energy sources → `adjacent` _(ruled
  2026-10-01)_.
- **Budget and omnibus votes** that contain a clean-energy item → V4 `multi-subject`.


## Sources

---
snapshot_id: 19ed8373-d5ad-5b74-a5dc-2528b8a82e26
source_kind: public-record
url: https://iga.in.gov/pdf-documents/118/2014/house/bills/HB1374/HB1374.01.INTR.pdf

Introduced Version HOUSE BILL No. 1374 _____ DIGEST OF INTRODUCED BILL Citations Affected: IC 8-1-2.5-9; IC 8-1-37.1. Synopsis: Feed-in tariff for renewable energy facilities. Requires the utility regulatory commission (IURC) to adopt rules to establish an electric utility feed-in tariff (FIT) program. Provides that the rules adopted must do the following: (1) Require all jurisdictional electric utilities (utilities) to offer a FIT to eligible customers (including persons that are not existing customers of the electric utility) not later than July 1, 2015. (2) Require utilities, upon the request of an eligible customer, to enter into a contract, for a term of at least 20 years, for the purchase of electricity generated by a renewable energy facility (facility) located in Indiana at a site at which the utility provides, or will provide, retail electric service to the eligible customer. (3) Prohibit a utility from requiring a minimum size or capacity for participating facilities, subject to any: (A) program participation cap; or (B) maximum size or capacity limit (which must allow facilities with less than 20 megawatt capacities to participate) for any one participating facility; that the IURC may approve. (4) Establish appropriate standards for interconnections between facilities and utilities' electric systems. (5) Establish appropriate FITs for participating facilities, with separate rates for electricity generated from each type of qualifying renewable energy resource under the program. (6) Require that any renewable energy credit or clean energy credit earned by a utility under the program be retired. (7) Prohibit an electric utility from requiring that a person that otherwise qualifies to participate in the electric utility's FIT program to be a customer of the electric utility for any period of time before enrolling in the electric utility's FIT program. Requires the IURC to ensure that the program complies with certain (Continued next page) Effective: Upon passage; July 1, 2014. Pierce January 15, 2014, read first time and referred to Committee on Utilities and Energy. 2014 IN 1374—LS 7087/DI 101 Digest Continued federal laws, regulations, and orders. Requires the IURC to develop and make available a standard contract for use by utilities in entering into contracts with eligible customers under the program. Provides that a nonjurisdictional electric utility may offer a FIT program to eligible customers at any time under terms and conditions that: (1) are just and reasonable to the utility's customers and in the public interest; and (2) comply with certain federal laws, regulations, and orders, to the extent applicable. Requires the IURC to include certain information concerning the program in its annual report to the regulatory flexibility committee. 2014 2014 IN 1374—LS 7087/DI 101 IN 1374—LS 7087/DI 101 Introduced Second Regular Session 118th General Assembly (2014) PRINTING CODE. Amendments: Whenever an existing statute (or a section of the Indiana Constitution) is being amended, the text of the existing provision will appear in this style type, additions will appear in this style type , and deletions will appear in [deleted: this style type.] Additions: Whenever a new statutory provision is being enacted (or a new constitutional provision adopted), the text of the new provision will appear in this style type . Also, the word NEW will appear in that style type in the introductory clause of each SECTION that adds a new provision to the Indiana Code or the Indiana Constitution. Conflict reconciliation: Text in a statute in this style type or [deleted: this style type] reconciles conflicts between statutes enacted by the 2013 Regular Session and 2013 First Regular Technical Session of the General Assembly. HOUSE BILL No. 1374 A BILL FOR AN ACT to amend the Indiana Code concerning utilities. Be it enacted by the General Assembly of the State of Indiana: 1 SECTION 1. IC 8-1-2.5-9, AS AMENDED BY P.L.256-2013, 2 SECTION 1, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE 3 JULY 1, 2014]: Sec. 9. (a) The regulatory flexibility committee 4 established under IC 8-1-2.6-4 shall also monitor changes and 5 competition in the energy utility industry. 6 (b) The commission shall before August 15 of each year prepare for 7 presentation to the regulatory flexibility committee an analysis of the 8 effects of competition or changes in the energy utility industry on 9 service and on the pricing of all energy utility services under the 10 jurisdiction of the commission. Beginning in 2015, the commission 11 shall include in its report under this subsection the following 12 information concerning the electric utility feed-in tariff program 13 established under IC 8-1-37.1: 14 (1) For the report prepared by the commission in 2015, 15 information concerning the commission's implementation of 2014 IN 1374—LS 7087/DI 101 2 1 the program, including any costs incurred by the commission 2 in implementing the program. 3 (2) The following information for each electric utility that is 4 required to offer a feed-in tariff (as defined in IC 8-1-37.1-6) 5 under the program: 6 (A) The total number of renewable energy facilities (as 7 defined in IC 8-1-37.1-8) participating in the electric 8 utility's feed-in tariff program under all contracts 9 described in IC 8-1-37.1-11(a)(2) that are in effect on the 10 last day of the state fiscal year that ends in the same year 11 as the commission's report under this subsection. The 12 commission shall break down the total number of 13 participating renewable energy facilities reported under 14 this clause by: 15 (i) the type of renewable energy resource (as defined in 16 IC 8-1-37.1-9) used by the participating renewable 17 energy facilities to generate electricity; and 18 (ii) the size or capacity of the participating renewable 19 energy facilities. 20 From the total number of participating renewable energy 21 facilities reported under this clause, the commission shall 22 identify those participating renewable energy facilities (by 23 size or capacity and by type of renewable energy resource 24 used) that were added to the electric utility's feed-in tariff 25 program under contracts entered into during the state 26 fiscal year that ends in the same year as the commission's 27 report under this subsection. 28 (B) Information concerning any program participation 29 caps established by the electric utility and approved by the 30 commission under IC 8-1-37.1-11(a)(3)(A). 31 (C) Information concerning any maximum size or capacity 32 limits for participating renewable energy facilities 33 established by the electric utility and approved by the 34 commission under IC 8-1-37.1-11(a)(3)(B). 35 (D) Information on the rates established by the commission 36 under IC 8-1-37.1-11(a)(5) that are in effect under the 37 electric utility's program as of the last day of the state 38 fiscal year that ends in the same year as the commission's 39 report under this subsection. 40 (3) Any other information that: 41 (A) pertains to the program or an electric utility required 42 to offer a feed-in tariff under the program; and 2014 IN 1374—LS 7087/DI 101 3 1 (B) the commission considers relevant or useful to the 2 regulatory flexibility committee, or that the committee 3 requests from the commission. 4 (c) In addition to reviewing the commission report prepared under 5 subsection (b), the regulatory flexibility committee shall also issue a 6 report and recommendations to the legislative council before 7 November 1 of each year that are based on a review of the following 8 issues: 9 (1) The effects of competition or changes in the energy utility 10 industry and the impact of the competition or changes on the 11 residential rates. 12 (2) The status of modernization of the energy utility facilities in 13 Indiana and the incentives required to further enhance this 14 infrastructure. 15 (3) The effects on economic development of this modernization. 16 (4) The traditional method of regulating energy utilities and the 17 method's effectiveness. 18 (5) The economic and social effectiveness of traditional energy 19 utility service pricing. 20 (6) The effects of legislation enacted by the United States 21 Congress. 22 (7) All other energy utility issues the committee considers 23 appropriate; however, it is not the intent of this section to provide 24 for the review of the statutes cited in section 11 of this chapter. 25 The report and recommendations issued under this subsection to the 26 legislative council must be in an electronic format under IC 5-14-6. 27 (d) This section: 28 (1) does not give a party to a collective bargaining agreement any 29 greater rights under the agreement than the party had before 30 January 1, 1995; 31 (2) does not give the committee the authority to order a party to 32 a collective bargaining agreement to cancel, terminate, amend or 33 otherwise modify the collective bargaining agreement; and 34 (3) may not be implemented by the committee in a way that would 35 give a party to a collective bargaining agreement any greater 36 rights under the agreement than the party had before January 1, 37 1995. 38 (e) The regulatory flexibility committee shall meet on the call of the 39 co-chairs to study energy utility issues described in subsection (c). The 40 committee shall, with the approval of the commission, retain 41 independent consultants the committee considers appropriate to assist 42 the committee in the review and study. The expenses for the 2014 IN 1374—LS 7087/DI 101 4 1 consultants shall be paid with funds from the public utility fees 2 assessed under IC 8-1-6. 3 (f) The legislative services agency shall provide staff support to the 4 committee. 5 (g) Each member of the committee is entitled to receive the same 6 per diem, mileage, and travel allowances paid to individuals who serve 7 as legislative members of interim study committees established by the 8 legislative council. 9 SECTION 2. IC 8-1-37.1 IS ADDED TO THE INDIANA CODE 10 AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE 11 UPON PASSAGE]: 12 Chapter 37.1. Feed-in Tariff Program for Renewable Energy 13 Facilities 14 Sec. 1. (a) The general assembly makes the following findings: 15 (1) The development of a robust and diverse portfolio of 16 electric generating capacity, including the use of renewable 17 energy resources, is necessary if Indiana is to continue to be 18 successful in attracting new businesses and jobs. 19 (2) The payment by electric utilities for electricity generated 20 from renewable energy resources: 21 (A) ensures a sound long term investment for individuals, 22 businesses, nonprofit organizations, cooperatives, local 23 units, and school corporations investing in renewable 24 energy technologies; and 25 (B) creates strong economic incentives for those 26 individuals, businesses, nonprofit organizations, 27 cooperatives, local units, and school corporations to make 28 the necessary capital and job creating investments in 29 renewable energy technologies in states that provide such 30 incentives. 31 (3) Indiana has considerable renewable energy resources that 32 could support the development of new electricity generation. 33 (4) It is in the public interest for the state to encourage the 34 rapid and sustainable development of renewable energy 35 resources for the generation of electricity in Indiana. 36 (5) The rapid and sustainable development of renewable 37 energy resources for the generation of electricity will benefit 38 the health, safety, and welfare of Indiana and its citizens by 39 doing the following: 40 (A) Stimulating the development of new technologies and 41 industries in Indiana and creating new jobs to serve those 42 emerging industries. 2014 IN 1374—LS 7087/DI 101 5 1 (B) Placing Indiana at the forefront of the nation's 2 renewable energy revolution. 3 (C) Creating an Indiana marketplace for the development 4 of and investments in renewable energy resources and 5 technologies. 6 (D) Opening renewable electricity generation, and the 7 economic opportunities that accompany such generation, 8 to individuals, businesses, nonprofit organizations, 9 cooperatives, local units, and school corporations in 10 Indiana. 11 (E) Providing equitable opportunities for individuals, 12 businesses, nonprofit organizations, cooperatives, local 13 units, and school corporations to help grow Indiana's 14 renewable energy industry. 15 (F) Reducing the price volatility and long term costs of 16 electricity. 17 (G) Reducing air and water pollution and related health 18 problems and health care expenditures. 19 (H) Protecting Indiana's natural resources. 20 (I) Reducing greenhouse gas emissions into the 21 atmosphere. 22 (b) The purpose of this chapter is to: 23 (1) strengthen Indiana's economy by attracting new 24 businesses and jobs in the growing renewable energy 25 industry; and 26 (2) enable the rapid and sustainable development of 27 renewable energy resources for the generation of electricity 28 in Indiana by establishing a feed-in tariff program to allow 29 eligible customers of electric utilities to sell electricity 30 produced by renewable energy facilities to electric utilities at 31 rates that stimulate the development of renewable energy 32 facilities in Indiana and encourage the continuation of existing 33 capacity from those facilities. 34 Sec. 2. As used in this chapter, "capacity", with respect to a 35 renewable energy facility, means the maximum output of 36 electricity, expressed in kilowatts or megawatts, that the renewable 37 energy facility can supply to an electric system's load, adjusted for 38 ambient conditions. 39 Sec. 3. (a) As used in this chapter, "customer" means any of the 40 following that agrees, orally or otherwise, to pay an electric utility 41 for retail electric service provided to a location in Indiana: 42 (1) An individual. 2014 IN 1374—LS 7087/DI 101 6 1 (2) A business, however organized. 2 (3) A nonprofit organization. 3 (4) A cooperative association. 4 (5) A unit (as defined in IC 36-1-2-23). 5 (6) A school corporation (as defined in IC 36-1-2-17). 6 (b) The term includes: 7 (1) an existing customer of an electric utility; and 8 (2) a potential customer of an electric utility. 9 Sec. 4. As used in this chapter, "electric utility" means: 10 (1) a public utility (as defined in IC 8-1-2-1(a)); 11 (2) a municipally owned utility (as defined in IC 8-1-2-1(h)); 12 or 13 (3) a local district corporation (as defined in IC 8-1-13-23(b)); 14 that furnishes retail electric service to customers in Indiana. 15 Sec. 5. (a) As used in this chapter, "eligible customer" means a 16 customer that agrees, orally or otherwise, to pay an electric utility 17 for retail electric service provided, or to be provided, at an Indiana 18 location that is the site of a renewable energy facility, regardless of 19 whether: 20 (1) the customer; or 21 (2) a person other than the customer; 22 owns, operates, manages, controls, or invests in the renewable 23 energy facility. 24 (b) The term includes: 25 (1) an existing customer of an electric utility; and 26 (2) a person that is not an existing customer of an electric 27 utility but agrees to become a customer of the electric utility 28 upon enrolling in the electric utility's feed-in tariff program. 29 Sec. 6. As used in this chapter, "feed-in tariff" or "FIT" means 30 a rate that: 31 (1) an electric utility pays to an eligible customer, under a 32 contract described in section 11(a)(2) of this chapter, for 33 electricity that is: 34 (A) generated by a renewable energy facility located at a 35 site in Indiana at which the electric utility provides retail 36 electric service to the eligible customer; and 37 (B) supplied back to the electric utility's system; and 38 (2) is determined by the commission under rules adopted 39 under section 11(a)(5) of this chapter. 40 Sec. 7. As used in this chapter, "program" refers to the electric 41 utility feed-in tariff program established by the commission under 42 section 11 of this chapter. 2014 IN 1374—LS 7087/DI 101 7 1 Sec. 8. (a) As used in this chapter, "renewable energy facility" 2 means a facility that: 3 (1) is located in Indiana; 4 (2) generates electricity solely from a renewable energy 5 resource; and 6 (3) is capable of providing electricity directly to an electric 7 grid. 8 (b) The term includes the following: 9 (1) An alternate energy production facility (as defined in 10 IC 8-1-2.4-2(b)), to the extent the alternate energy production 11 facility generates electricity from a renewable energy 12 resource set forth in section 9 of this chapter. 13 (2) A small hydro facility (as defined in IC 8-1-2.4-2(e)) at an 14 existing dam. 15 (c) The term does not include a cogeneration facility (as defined 16 in IC 8-1-2.4-2(c)). 17 Sec. 9. (a) As used in this chapter, "renewable energy resource" 18 means any of the following sources for the generation of electricity: 19 (1) Wind energy. 20 (2) Solar energy. 21 (3) Hydropower from existing dams. 22 (4) Geothermal energy. 23 (5) Energy from organic waste biogas, including any of the 24 following: 25 (A) Methane produced by the biodigestion of farm or 26 animal wastes. 27 (B) Landfill gas. 28 (C) Sewage treatment gas. 29 (b) The term does not include coal bed methane. 30 Sec. 10. As used in this chapter, "retail electric service" has the 31 meaning set forth in IC 8-1-2.3-2(c). 32 Sec. 11. (a) Not later than June 1, 2015, the commission shall 33 adopt rules under IC 4-22-2 to establish the electric utility feed-in 34 tariff program. The rules adopted by the commission under this 35 chapter must do the following: 36 (1) Require all electric utilities subject to the jurisdiction of 37 the commission for the approval of rates and charges to offer 38 a FIT to eligible customers not later than July 1, 2015. 39 (2) Provide that after July 1, 2015, an electric utility shall, 40 upon the request of an eligible customer, enter into a contract 41 for the purchase of electricity generated by a renewable 42 energy facility located in Indiana at a site at which the electric 2014 IN 1374—LS 7087/DI 101 8 1 utility provides or will provide retail electric service to the 2 eligible customer. A contract under this subdivision must 3 satisfy the following requirements: 4 (A) Be for a term of at least twenty (20) years. 5 (B) Require the electric utility to purchase electricity from 6 the eligible customer at a rate that is not less than the FIT 7 that is established by the commission under subdivision (5) 8 and that applies at the time the contract is entered into 9 with respect to: 10 (i) the renewable resource used by; and 11 (ii) the size or capacity of; 12 the renewable energy facility that is the subject of the 13 contract. Subject to subdivision (5)(D), a contract required 14 under this subdivision must specify that the rate that 15 applies at the time the contract is entered into applies 16 throughout the term of the contract. 17 (C) Require: 18 (i) the eligible customer to sell to the electric utility all 19 the electricity generated by the renewable energy facility 20 that is the subject of the contract; and 21 (ii) the electric utility to sell to the eligible customer all 22 the electricity that is required at the site of the renewable 23 energy facility that is the subject of the contract. 24 (3) Prohibit an electric utility from requiring a minimum size 25 or capacity for renewable energy facilities participating in the 26 program. However, in the rules adopted under this chapter, 27 the commission may allow an electric utility to do the 28 following: 29 (A) Subject to approval by the commission, establish 30 program participation caps including: 31 (i) establishing a maximum aggregate capacity for all 32 participating renewable energy facilities under the 33 electric utility's FIT program; 34 (ii) limiting participation in the electric utility's FIT 35 program based on a percentage of the amount of the 36 electric utility's annual gross retail electric sales; or 37 (iii) establishing other restrictions approved by the 38 commission. 39 If an electric utility seeks to establish a program cap under 40 this clause, the commission may require as a condition for 41 approving the cap that a certain percentage of the 42 proposed maximum aggregate capacity, a certain 2014 IN 1374—LS 7087/DI 101 9 1 percentage of the electric utility's annual gross retail 2 electric sales, or another part of the proposed program 3 cap, as applicable, be reserved for electricity generated 4 from one (1) or more types of renewable energy resources 5 set forth in section 9 of this chapter, to ensure that the 6 electric utility's program is not discriminatory with respect 7 to particular types of renewable energy facilities or 8 technologies. 9 (B) Subject to approval by the commission, establish a 10 maximum size or capacity limit for a participating 11 renewable energy facility. However, in establishing a 12 maximum size or capacity limit under this clause, an 13 electric utility: 14 (i) must allow renewable energy facilities with capacities 15 of less than twenty (20) megawatts to participate in the 16 program; and 17 (ii) may not base the maximum size or capacity limit on 18 the amount of electricity purchased or required by an 19 eligible customer from the electric utility at the site of 20 the eligible customer's renewable energy facility. 21 (4) Establish appropriate standards for interconnections 22 between renewable energy facilities and electric utilities' 23 systems, based on the size, capacity, and technical 24 requirements of the interconnecting facilities. In adopting 25 standards under this subdivision, the commission may specify 26 how the costs of the interconnection and any required 27 upgrades to an electric utility's system are to be allocated 28 among the parties. 29 (5) Establish appropriate FITs for renewable energy facilities 30 that are the subject of a contract described in subdivision (2), 31 subject to the following: 32 (A) The rates established must: 33 (i) be just and reasonable to the customers of the electric 34 utility and in the public interest; 35 (ii) not be discriminatory with respect to particular 36 eligible customers or particular types of renewable 37 energy facilities or technologies; 38 (iii) be at levels sufficient to stimulate the development of 39 renewable energy facilities in Indiana and to encourage 40 the continuation of existing capacity from those facilities; 41 (iv) be based on an eligible customer's costs to generate 42 the electricity sold under the program, plus a reasonable 2014 IN 1374—LS 7087/DI 101 10 1 rate of return; and 2 (v) be fair to both the electric utility's ratepayers and 3 investors. 4 (B) The commission shall establish separate rates for 5 electricity generated from each of the renewable energy 6 resources set forth in section 9 of this chapter, subject to 7 the following: 8 (i) Subject to item (ii) and except as provided in item (iii), 9 for electricity generated from each renewable energy 10 resource set forth in section 9 of this chapter, the 11 commission shall establish at least four (4) rates based on 12 the size or capacity (up to and including a nameplate 13 capacity of at least twenty (20) megawatts) of the 14 renewable energy facility that generates electricity from 15 the particular renewable energy resource. 16 (ii) For electricity generated from solar energy, the 17 commission shall establish separate rate classes for 18 rooftop facilities and ground-mounted facilities. For each 19 of these two (2) rate classes, the commission shall 20 establish four (4) rates based on the size or capacity (up 21 to and including a nameplate capacity of at least twenty 22 (20) megawatts) of the facility, as required by item (i). 23 (iii) For electricity generated from wind energy, the 24 commission shall establish at least four (4) rate classes 25 that reflect the wind resource intensity of the location in 26 Indiana at which the renewable energy facility that 27 generates the electricity is located. For each of these four 28 (4) rate classes, the commission shall establish a number 29 (to be determined by the commission) of rates, each of 30 which reflects the capacity of the facility or the rotor 31 swept area of the facility, as the commission determines 32 appropriate. 33 (C) In establishing rates under this subdivision for a 34 particular electric utility, the commission shall consider 35 the following: 36 (i) The electric utility's costs under the program, 37 including capital costs and operation and maintenance 38 costs, and taking into account the incremental cost of 39 electric energy that, but for the electric utility's purchase 40 of electricity from eligible customers under the program, 41 the electric utility would generate or purchase from 42 another source. 2014 IN 1374—LS 7087/DI 101 11 1 (ii) The term of the contract between the electric utility 2 and an eligible customer. 3 (iii) Any federal tax credit or deduction, or any other 4 federal incentive or subsidy, including any accelerated 5 depreciation available for tax purposes, received by an 6 eligible customer or another person that owns, operates, 7 manages, controls, or invests in a renewable energy 8 facility. 9 (iv) Any shifting of costs of the program to the electric 10 utility's nonparticipating customers. 11 (D) Notwithstanding subdivision (2)(B), the commission 12 may, in establishing rates under this subdivision, provide 13 that the rate set forth in a contract under subdivision 14 (2)(B) shall be adjusted periodically during the term of the 15 contract to reflect the effects of inflation or deflation. 16 (E) The commission shall review the rates established 17 under this subdivision on a periodic basis determined by 18 the commission, but not less frequently than every two (2) 19 years, to determine whether the rates in effect at the time 20 of the review, as most recently adjusted under this clause, 21 satisfy the requirements set forth in clause (A). If, after a 22 review required under this clause, the commission 23 determines that the rates in effect at the time of the review 24 do not satisfy the requirements set forth in clause (A), the 25 commission may amend the rules adopted under this 26 subdivision to adjust the rates to ensure compliance with 27 the requirements set forth in clause (A). However, any rate 28 adjustments made by the commission under this clause 29 apply only to contracts under subdivision (2) that are 30 entered into after the effective date of the amended rules. 31 (6) Require that any renewable energy credit or clean energy 32 credit (as defined in IC 8-1-37-3) earned by an electric utility 33 in connection with the program be retired. 34 (7) Prohibit an electric utility from requiring that a person 35 that: 36 (A) owns, operates, manages, controls, or invests in a 37 renewable energy facility located in Indiana; and 38 (B) otherwise qualifies to participate in the electric utility's 39 feed-in tariff program; 40 to be a customer of the electric utility for any period of time 41 before enrolling in the electric utility's feed-in tariff program. 42 (b) In adopting rules under this chapter, the commission shall 2014 IN 1374—LS 7087/DI 101 12 1 ensure that the program complies with: 2 (1) the federal Public Utility Regulatory Policies Act of 1978 3 (16 U.S.C. 2601 et seq.) and rules and regulations adopted 4 under that act; 5 (2) the Federal Power Act (16 U.S.C. 791a et seq.) and rules 6 and regulations adopted under that act; and 7 (3) any applicable order or ruling of the Federal Energy 8 Regulatory Commission. 9 (c) An electric utility that is not subject to the jurisdiction of the 10 commission for the approval of rates and charges may offer a 11 feed-in tariff program to eligible customers at any time under 12 terms and conditions that: 13 (1) are just and reasonable to the customers of the electric 14 utility and in the public interest; and 15 (2) comply with: 16 (A) the federal Public Utility Regulatory Policies Act of 17 1978 (16 U.S.C. 2601 et seq.) and rules and regulations 18 adopted under that act; 19 (B) the Federal Power Act (16 U.S.C. 791a et seq.) and 20 rules and regulations adopted under that act; and 21 (C) any applicable order or ruling of the Federal Energy 22 Regulatory Commission; 23 to the extent applicable. 24 An electric utility described in this subsection may use the rules 25 adopted by the commission under this chapter as a guide or model 26 for a feed-in tariff program offered by the electric utility under this 27 subsection. 28 Sec. 12. Not later than June 1, 2015, the commission shall 29 develop and make available a standard contract form for use by 30 electric utilities in entering into contracts with eligible customers 31 under rules adopted under section 11(a)(2) of this chapter. The 32 form prescribed by the commission must require the parties to set 33 forth the following information: 34 (1) The rate to be paid for each kilowatt hour of electricity 35 purchased under the contract. 36 (2) Any adjustments to be made to the rate to account for 37 inflation or deflation, as may be prescribed by the commission 38 under section 11(a)(5)(D) of this chapter. 39 (3) The duration of the contract. 40 (4) The following information for the renewable energy 41 facility that is the subject of the contract: 42 (A) The type of renewable energy resource used by the 2014 IN 1374—LS 7087/DI 101 13 1 renewable energy facility to generate electricity. 2 (B) The capacity or size of the renewable energy facility. 3 (C) The location of the renewable energy facility. 4 (D) Any technical specifications concerning the renewable 5 energy facility that the commission may require. 6 (E) The owner or operator of the energy facility if the 7 owner or operator is a person other than the eligible 8 customer. 9 (F) Any federal tax credit or deduction, or any other 10 federal incentive or subsidy, including any accelerated 11 depreciation available for tax purposes, received by the 12 eligible customer or another person that owns, operates, 13 manages, controls, or invests in the renewable energy 14 facility, with respect to the renewable energy facility. 15 (5) Any other pertinent information that the commission may 16 require. 17 Sec. 13. The commission may adopt emergency rules in the 18 manner provided under IC 4-22-2-37.1 to adopt the rules required 19 by this chapter, including any amendments to the rules described 20 in section 11(a)(5)(E) of this chapter. An emergency rule adopted 21 by the commission in the manner provided under IC 4-22-2-37.1 22 expires on the date a rule that supersedes the emergency rule is 23 adopted by the commission under IC 4-22-2-24 through 24 IC 4-22-2-36. 25 SECTION 3. An emergency is declared for this act. 2014 IN 1374—LS 7087/DI 101 [extracted by pdf-snapshot.ts with strike detection, 2026-10-07T19:13:11.971Z, https://iga.in.gov/pdf-documents/118/2014/house/bills/HB1374/HB1374.01.INTR.pdf, from saved file]

---
snapshot_id: ac560d97-70dd-5fc3-a4a8-514ab560cd33
source_kind: own-site (the person's own site or account)
url: https://repmattpierce.substack.com/p/rep-matt-pierces-november-newsletter

Rep. Matt Pierce's November Newsletter Rep. Matt Pierce's Newsletter Subscribe Sign in Rep. Matt Pierce's November Newsletter SNAP resumes, high electricity costs and more. Rep. Matt Pierce Nov 29, 2025 Share Welcome to my monthly newsletter, where I provide legislative updates as your state representative for House District 61. Please reach out to me at h61@iga.in.gov if you have any comments, questions, or concerns SNAP Resumes: Indiana Failed to Help Since the federal government has reopened, families will receive their full benefits from the Supplemental Nutrition Assistance Program (SNAP). The Indiana Family and Social Services Administration (FSSA) started loading Electronic Benefits Transfer (EBT) cards on Nov. 16. I’m grateful that SNAP has resumed. Access to food should never be a bargaining chip in national politics. I’m frustrated that politics prevented action in Indiana. Our leaders played the blame game instead of helping Hoosiers in need. The State Budget Committee (SBC) met right before the SNAP pause. More time was spent discussing new casinos than the impending hunger crisis. Democrats supported a SBC resolution offered by Rep. Greg Porter (D-Indianapolis) that called on the Governor and State Board of Finance to use their authority to bridge the gap in federal funding by using surplus budget funds to support food banks and SNAP recipients during the shutdown. The resolution failed. Their inaction resulted in families losing food assistance for two weeks. Food banks are still facing record demand as we enter the holiday season. If you are financially able, I encourage you to join me in donating to the Hoosier Hills Food Bank at this link . If you receive SNAP benefits and have any questions about the program, please reach out to the local Division of Family Resources (DFR) Office. You can contact the office at: 1531 South Curry Pike, Ste. 300 Bloomington, IN 47403 Office hours are 8 a.m. – 4:30 p.m. local time. Telephone: 800-403-0864 Fax: 888-436-9199 Map courtesy of The Associated Press (AP). Hoosiers’ Electric Bills Grew More Than Any Other State Recently, Democrats on the Congressional Joint Economic Committee (JEC) released a national report on electric bills. The analysis reveals what we already know: Electric bills are skyrocketing. The report estimated full-year 2025 electricity costs per state based on the monthly electricity bill data released by the federal Energy Information Administration (EIA) for January – August of 2025 and compared the estimate to 2024 bills. Indiana had the highest increase out of all 50 states at 16.3%. The average Hoosier is paying $260 more for electricity this year than last year. By comparison, the Committee projected that American households will pay, on average, approximately $100 more per household in electricity costs this year. You can read a copy of the report here: State-by-State Data Electricity Bills Up $100 Per Family in 2025 I am not surprised by this report because I fought against many pieces of legislation that contributed to increased rates. Here are just a few examples of the bills I opposed: HEA 1421 (2023) and SEA 271 (2022) allow electric utilities to charge customers for natural gas plants and small modular reactors while they are under construction. This shifts any risk of cost overruns from utility company shareholders to utility customers. SEA 423 and SEA 424 (2025) allow electric utilities to charge customers for preconstruction costs of small modular reactors even if a reactor is never built. Again, the risk is shifted from utility shareholders to utility customers. SEA 560 (2013) allows utilities to add a charge to bills for 80% of costs to upgrade transmission, distribution, and storage improvements without filing a rate case, where cost savings to the utilities could be used to offset the new charges. When the State Supreme Court ruled the Indiana Utility Regulatory Commission (IURC) had illegally allowed the utilities to charge customers for things that did not benefit them, the Republican majority quickly passed HEA 1470 (2019) to reverse the court decision and allow customers to be charged for the costs the Court had disallowed. HEA 1417 and SEA 9 (2023) also overruled court cases that ruled utilities could not charge customers for the cleanup of coal ash ponds near their power plants. HEA 1417 lets utilities add extra costs to their books for cleanup costs without IURC approval and then later charge customers for them. These bills make it easy to see the legislature’s supermajorities are not on the side of utility customers. I fought these bills and have advocated for more competition in the utility industry by promoting renewable energy like wind and solar, along with energy storage. These are both the lowest cost and quickest to deploy forms of electric generation. Indiana House Dems: Redistricting on Hold; Lawmakers Must Tackle High Costs What education issues will Indiana lawmakers consider in 2026? ‘It’s a disaster.’ How cuts undermine high-quality child care in Indiana Obamacare Premiums Are About to Soar. How’d We Get Here? Social Security change in 2026 may impact retirement age. Here’s what to know. Analysis: Property tax changes to put more pressure on businesses, owners of low-value homes Sincerely, Matt Pierce Share Top Latest No posts Ready for more? Subscribe © 2026 Rep. Matt Pierce · Privacy ∙ Terms ∙ Collection notice Start your Substack Get the app Substack is the home for great culture This site requires JavaScript to run correctly. Please turn on JavaScript or unblock scripts

---
snapshot_id: 2a12e507-70a0-5243-90b6-91ec1aed93d3
source_kind: public-record
url: https://iga.in.gov/legislative/2014/bills/house/1374/details

House Bill 1374 Feed-in tariff for renewable energy facilities. Introduced House Bill (H) Authored by: Rep. Matt Pierce. Digest Requires the utility regulatory commission (IURC) to adopt rules to establish an electric utility feed-in tariff (FIT) program. Provides that the rules adopted must do the following: (1) Require all jurisdictional electric utilities (utilities) to offer a FIT to eligible customers (including persons that are not existing customers of the electric utility) not later than July 1, 2015. (2) Require utilities, upon the request of an eligible customer, to enter into a contract, for a term of at least 20 years, for the purchase of electricity generated by a renewable energy facility (facility) located in Indiana at a site at ... View more Authors Latest Bill Actions View All Actions Chamber Date Bill Action H 01/15/2014 First Reading: Referred to Utilities and Energy H 01/14/2014 Authored by Representative Pierce.

---
snapshot_id: 0df4413e-5776-5592-9649-3cbdf004caeb
source_kind: news (excerpt only)
url: https://www.idsnews.com/article/2026/03/democratic-candidates-bloomington-state-house-election-public-forum

… Music Opinion Columns Editorial Letters Oped Perspectives Black Voices Features Community Hub IDS Shop IDS Games IDS Events IDS Health IDS Religious Press Releases Print Archive Campus News Academics & Research Administration Student Government Student Life Regional City News Bloomington Business & Economy Crime & Courts Investigations Politics Indiana National News Sports Football Men's Basketball Women's Basketball Baseball Volleyball Wrestling Men's Soccer Women's Soccer Swimming & Diving Little 500 Arts Community Events Film IU Auditorium Jacobs School of Music Local Music Opinion Columns Editorial Letters Oped Perspectives Black Voices Features Community Hub IDS Shop IDS Games IDS Events IDS Health IDS Religious Press Releases Print Archive Donate city politics bloomington Democratic candidates for Bloomington's State House seat participate in public forum Democratic candidates for Indiana's House District 61 seat Lilliana Young (left) and Matt Pierce (right) participate in a candidate forum March 5, 2026, at First United Church in Bloomington. Young and Pierce answered questions about school choice, environmental protections, pro-Palestine protests and more at the forum. Photo by Adelyn Rabbitt / The Indiana Daily Student By Adelyn Rabbitt Mar 6, 2026 2:40 pm &middot; Updated Mar 6, 2026 2:40 pm Two Democratic candidates for Indiana’s House of Representatives District 61, Matt Pierce and Lilliana Young, discussed pro-Palestine protests, school choice, environmental protections and more during a candidate forum Thursday. The Bloomington Democratic Socialists of America hosted the forum, which took place at First United Church. Pierce, the incumbent, is facing a Democratic primary challenger , Lilliana Young, in the statehouse District 61 election for the first time in over two decades. Pierce has held his seat in the statehouse since 2002 and has focused on affordability within healthcare, housing, college and childcare in his current campaign. Lilliana Young serves on the Bloomington/Monroe County Human Rights Commission and is an advocate for gender-affirming healthcare. She is also the founded The Sisterhood, a community for political activism and …

---
snapshot_id: c1c9d8e0-2945-5db3-b622-bf30ae8beb26
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/9d4c9fdb-cbec-4d10-b0a5-3455c6db752d

# On the Record — Matt Pierce (72dd5219-490f-48bb-986e-183a6098d602) ## forum — Bloomington Regular Session - OTR page: https://ontherecord.empowered.vote/meetings/9d4c9fdb-cbec-4d10-b0a5-3455c6db752d - Video: (no video url) - Date on On the Record: 2026-06-09 · date in the source's file name: 2026-03-23 - Kind: forum · Regular Session · Bloomington - Linked races: 0b5ae739-aa3a-4bfd-b1bf-57cc1c380fd9, 0bab4038-45bc-42b6-a1df-38b98e742952 [2:57] Thank you. I'm asking for your vote in the upcoming May primary because I want to continue being a progressive voice for our community and our community's values at the State House. And that means, you know, treating everyone with dignity and respect and not attacking and trying to marginalize communities, creating an economy that works for everyone. affordable housing which we know is a big issue accessible and affordable health care is another thing people are crying out for we need to support our public schools not private schools we shouldn't be diverting our money away from our public schools we need to defend academic freedom and free speech on the IU campus and our other institutions of higher education and the other thing we have to do is we have to protect democracy that's a sad thing to say and so that means fighting things like attempts to redistrict in the middle of the decade I've had amendments to unmask ice I opposed the governor's military police bill and the ice compliance as well [4:21] Okay. Again, as I was saying broadly, it's just this whole basket of issues surrounding preservation of democracy, and that means fighting off voter suppression and these attempts to kind of militarize the law enforcement. That's a key thing. I think one of the other key things is the economy. We cannot have a system where some people have fabulous wealth while a significant number of people are struggling just to get by, and you have the middle class shrinking in the middle. And so that's a key thing. And, you know, the housing and health care and all that kind of fits into that affordability kind of issue. And I think also. academic freedom and free speech on our campus. I mean, it's really sad what you see happening at IU, having protesters in Dunn Meadow being arrested, faculty members dismissed and punished without due process. These are all things that I think we need to push back on. [8:36] Well, the root of the problem goes all the way back to when the Daniels administration decided that having a regular agency, Department of Commerce, was not good enough for economic development because open-door laws and other transparency requirements applied to that agency. So they decided to create, spin off, this economic development corporation. And the idea was they needed to have these kind of secret negotiations and deals. And what happened is over time... That just spun out into corruption, basically. What you had is self-dealing within the IEDC, and you had these crazy things like the LEAP project. They went out and paid outrageous sums of money for land up there, and they didn't even do their due diligence to figure out whether they had enough water for the things they wanted to do there. And all that was at the expense of the taxpayers, and it was because there was not the kind of credibility or the transparency that they needed. A final one to throw in there is this foundation, which is an appendix of IEDC. And in that case, what they would do is they would get these big contributions, charitable contributions, from mostly utilities. And those then would be used for these worldwide junkets. In the name of economic development, they would go to the Formula One race over in Europe, and the governor would go there and say, I'm making deals, you know, here in the suites of the sports events. And there really was no accountability for that. So I voted for a fuller investigation of what actually happened there. I think the current governor is trying to just blame it all on the last governor and move on. And I think we need to go back and really get to the bottom and the details of what happened there. And so I'm hopeful that that will happen. [10:35] Well, I think at this point, environmental issues and energy issues are inextricable. They're just wrapped together. And so I served for a long time on the Environmental Affairs Committee, and then I had an opportunity to become the ranking member, Democratic member of the Utilities Committee. And I've been a relentless advocate for renewable energy and moving us to a clean energy economy. And one of the most frustrating and dispiriting things is just how there's no interest among the Republican Party to address the climate change problem, despite the evidence that is confronting us with these abnormal weather events, flooding, real significant economic impacts, and longer-term impacts that are going to cause people's grandchildren, future generations, to have real problems. And it's really outrageous that the current people in charge are not willing to do something to try to solve these problems. And so I'm doing everything I can to push us to promote solar, rooftop solar. I fought the net metering law that kind of destroyed the economics of people being able to afford rooftop solar and become more independent and save money on their own energy bills on top of it. I've tried to... create more competition with energy. So way back when, I had several years in a row I put in what was called a feed-in tariff bill. It was based on what Germany has, where they basically allowed anybody to plug in. If you had renewable energy, wind or solar, you had a right to sell that into the utilities grid. And that really boosted up the amount of renewables they had there. [15:36] I haven't seen any politics more cynical and hateful than the Republicans at the State House when it comes to the LBGTQ plus community. You know, this all goes back to 2004. George Bush was in trouble because of his wars going into the election. He needed something to drive his base out to the polls. And so they cynically said, let's make marriage equality the big issue. And the same thing happened at the State House. And we went through year after year. of having to fight off this effort to take the so-called Defense of Marriage Act and put it in the state constitution. And I'm proud that at the time, the Democrats were in the majority. I was the chair of the Courts and Criminal Code Committee, and that constitutional amendment passed out of the Senate was sent to my committee, and I killed it. I said, I'm not giving this bill a hearing. I'm not participating in this cynical, hateful process. Since then, they moved on because people actually, the issue turned on them, right? And they no longer had the political power to attack marriage equality, so now they're attacking trans people. And it's sad. I fought off those efforts to— To basically marginalize that community and I've authored co-authored several bills with representative Campbell from Lafayette that attempts to at least begin to claw back this attack on parents' rights to decide what kind of health care their kids could get when they need gender-affirming care. And so I'll continue to work on those issues. [17:30] Well, what I have found during my time in the legislature, that you have to demand respect from the majority party. You can't just be kind of the go-along, nice guy, junior partner. You've got to really get up in their face sometimes. But you have to balance it out, because if you get in their face too much you end up getting marginalized yourself and so what i found just you know one example is the speaker went too far one day and he ruled out we had an amendment to expand voting rights to an election bill called Various Elections Matters. And the speaker said that our amendment was not germane. It violated the rules and could not be voted upon, which was insane because this bill had like 50 different election provisions of all types in it. And so we appealed the ruling of the chair and we debated it and I basically told the other people, like, My fellow Democrats, stand back. I'm taking this one. And I really went after the Speaker full bore. And I went through every single provision in that bill. I pointed out that it said various elections matter for the title. And I said what the Speaker just did here today is an abuse of power. And I challenged them to say, why are you afraid to vote on these bills? Why are you hiding behind the rules? to prevent yourself from being held accountable to the voters. And I said, it's gotta stop. Now, the interesting thing is, For about the next week or so, there was not a single ruling by the Speaker that our amendments were out of order on stuff that I think probably was stretching it a little bit. So you've got to learn how to push hard and command respect. [22:12] The affordable housing issue is kind of one of the more complex issues that I've come across because you have so many variables and factors impacting it, everything from interest rates to housing supply. We now have hedge funds coming in and buying up homes, competing with average buyers, and they have endless funds to come in, and so we're seeing kind of the housing corporatized. And so you've got to approach it from a lot of different angles, and so we need to do a better job, and this is probably Congress's job on Section 8 vouchers. The wait lists are too long for that. We have to do more to try to get more housing. And, you know, I was excited when in this session the Republicans said that they were actually going to start addressing affordability issues. And one of the things they said they were going to address was housing. But what they ended up doing is they had a home builder spearhead the bill, and the home builder said the big problem is we have too many regulations. And so by the time this affordable housing bill actually got before us in its final form, after it had gone through both houses, it was like a joke. It essentially outlawed two safety items because the home builder said they were too expensive. They had a deal keeping your house from burning down. And it also limited what kind of flood mitigation they could do for these retention ponds and things. And then finally it just told every local community you have to have a hearing. To discuss how your zoning laws might be impacting building, which I think we've already had those debates in our community here, and we continue to have them. [24:23] come up first yeah yeah so I'm I'm pleased that when we had the Black Lives Matters protests and that issue was forefront. One of the things I did is I called up the Republican Person I'd worked with on criminal code reform and I said look this we cannot allow this moment to pass without doing something about police brutality and making clear that we have to have a different way forward and I was pleased that we were able to get a bill put together that prohibited things like chokeholds some things that were resulting in people being injured or killed and stress de-escalation and put into the training rubrics for people at the law enforcement academy processes to try to avoid getting into the situations that we've just seen happen over and over again and so we have to we have to keep after that because after a while kind of people forget and they they maybe resort back to the old ways but i think that the other thing that that bill did which i thought was really important is I believe the most police officers want to serve their community, they want to protect the community, and they're very public spirited. But we unfortunately have a few people who seem to have a different set of priorities. And what would happen is when someone would do something that violated the rules of their department, they would just resign and move to the next department, which was easy because there's a shortage of officers. This bill requires the last department to have to share all the information about their personal records with the new potential hires. [28:15] Yeah, I have to admit, there's some days where just things go so crazy up there, you just want to kind of drop your head on the desk and say, like, I surrender. I mean, what can you possibly do to talk any sense into people? Or the worst thing I hate is, like, you made really good points on that bill, but I couldn't vote with you because, you know, my leadership would get mad at me or something. But, you know. There are just enough victories to keep me going. and that's really what continues to motivate me we had a tremendous victory by defeating redistricting and that was awesome and there are lesser victories that people don't particularly hear about all the time one that i can think of we had last session was uh this crazy bill that wanted to move to uh firing squads for executions which just like the nuttiest thing ever And, you know, I really pushed back on that bill, and it couldn't get enough votes within the House to actually move on to the Senate. And I thought that was another, you know, opportunity. So I think that the worst thing we can do is think of ourselves as helpless and hopeless and not having an ability to impact the system. And so particularly right now, I feel like coming up in this election in the fall, we have an opportunity to really take back some power to change the direction of the country and the state. And I think that is the critical thing to keep people focused on is don't give up hope. It's frustrating. It's dispiriting when you see this horrible legislation continue to come through the process. But we've had some victories, and we can have more victories if we all work together and focus on, basically, gaining that political power at the ballot box. [30:09] Yeah, this is really... um tough because i've offered some amendments on that i've been kind of i think it's because i drew the short straw but it ended up being like the house democrats point person on redistricting so i had to read all those grinding legal cases and everything and I think that it is achievable. It's happened in other states, but it's going to take a long-term movement. You know, I think it's something like the women earning the right to vote. I mean, those were multi-decade kinds of efforts, civil rights movement. I think it has to be something up to that level where it's almost a movement and you have to get people engaged enough to understand the impacts of redistricting. I think it's a root of a lot of our problems because when you pack all the Democrats together to dilute their power and that then creates lopsided Republican districts, the primaries become the elections that matter. And the general elections are really just kind of a rubber stamp kind of thing, and this reduces the accountability of the members. You know, there was a time when you had like a 52-48, 51-49 split in the House. Even a 55-48. A 45 split, which was considered a huge majority in those days. You could literally see people sweating as they were thinking about how to vote. They would see stuff like, oh, how are my people going to explain this back home? And now with 70 members and these lopsided districts, there's no sweating in the General Assembly. People just vote. how they want to they pander to their most extreme bases and there's no um there's no accountability because of that so we definitely need to do something on redistricting [34:24] Yeah, I think it's going to take a lot of education, particularly because, you know, over my objections, the Republicans adopted a law which took away the right of the student ID to be used as a voter ID, even though it met every exact. And I made the author of the bill. For like 15 or 20 minutes, I led him through every single aspect of this, and he could not give a good reason why they were doing it. And so that makes it harder to vote. So you've got to educate people about what you need to do to vote. One of the saddest things that I see, and it happens every election cycle, if you go to the county election board when they meet about 10 days after the election, they go through their provisional ballots. there will be 60 or 80 students who showed up to vote and they're not registered they're not registered in the county they're not even from the state they just showed up because they decided they wanted to vote and participate but they didn't understand that you have to get registered by a certain deadline that you have to get to the right precinct and what happened is you know i don't know if they thought their um provisional ballot would just magically count or what but it didn't and to think about all those votes that are not being accounted for is really bad so education is a key thing and then secondly the other part of education is helping people to understand who is doing what to them One reason why politicians are not held accountable when they don't address the needs of the people is because with this crazy media we have, social media, you can't figure out who's doing what to whom. And so we've got to work much harder for people to understand what votes, what parties are for their interests and against their interests. [36:32] Well, I think if you get back to the Indiana Economic Development Corporation, one of the biggest problems is they just got into this mindset of we're going to get the Fortune 500 company to come build a big factory here because we're going to give them these tremendous benefits. We will outbid the corporate welfare that we'll give to the people to get them here. And they ignored the ability of the small businesses, the startups right here. And so this is one thing where I agree with Governor Braun. He seems to be trying to redirect IEDC to be more focused toward something beyond just central Indiana and kind of the big corporations and the big kind of long bomb deals like the Leap District. And so I think that we need to redirect our efforts so that small businesses, that business that is prospering and it needs to get to the next level but it needs some help to get there, how do we help them do that? And then... We have to make sure that that assistance gets out across the state. And for Bloomington, it's particularly important that we support the tech sector, right? So we have a tech park here. We have a lot of people working really hard to build off of the industries we have now and to figure out how to get this kind of startup entrepreneurial economy going. And I think that if we put more effort into that, we have an opportunity to start some small businesses, some startups that could end up being quite substantial companies that would really help our community because we need better, higher-paying jobs in our community. We don't have enough of those. [40:03] think I'm up first okay all right you know one of the things that I think is really important if you're serving as a legislator is to look around the hearing rooms and the hallways of the Capitol and ask yourself who's not here Because oftentimes you hear only from the interest groups that can afford to have paid lobbyists at the State House who are there constantly, who build the relationships, who become friendly with legislators. And their viewpoints always get across. But there are many average everyday Hoosiers. who aren't organized in a way with the resources to have somebody on the scene at the state house every day working for their interests. And so that's where the responsibility of the legislators who represents all the people within his or her district. that legislator has to be thinking about who's not here, who's getting left out of the conversation. And that's one thing that I really pride myself on. So when the payday lenders show up and say, we need less regulation because we need to give people access to capital, I say, look, guys, this is not Fortune 500 companies talking about. You're exploiting struggling people. So let's not come up with some phony excuses for why you need stuff. We know what's going on here. And so people need legislators who will call out those people who want to prey upon people who are struggling the most. And so that's why I very much would like to be returned to the legislature. I'm asking the voters to return me there for another two years so I can continue working on those issues and representing all the people of District 61. [74:45] It was a good. [78:50] We got one going.