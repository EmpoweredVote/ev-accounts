You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/strange-hawking-b66441/backend/data/stance-research/2026-10-08-egi-a1v2/bob-wirch/labels/coder-3.json. Write JSON only, matching
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

politician_id: 6e3e9f2e-c393-45ef-b702-8bba4c209220  office_id: e47bd286-26f9-4158-b7d6-e41b6362a497
Bob Wirch — State Senator, Wisconsin (seated, level: state)
Current term: unknown (precision: unknown) to present

## Topics (served ladder text — code against these words only)

### topic_key: egi-draft-a1v2
topic_id: 00000000-0000-0000-0000-0000000a1002  served_revision_id: draft-a1v2-pr945
Question: When a student wants to use a different name or gender identity at school, who decides whether parents are told?
  1. Require staff to keep a student's gender identity from parents unless the student consents.
  2. Forbid rules that require schools to tell parents.
  3. Require schools to tell parents when parents ask.
  4. Require schools to notify parents.
  5. Require parental permission before staff use a different name or pronouns.

#### Annex

(no annex for this topic yet — apply the codebook alone)

## Sources

---
snapshot_id: 3c2b511e-20e8-5905-9f11-5c3e770369b9
source_kind: public-record
url: https://docs.legis.wisconsin.gov/document/votes/2021/sv0326

2021 Senate Vote 326 Skip navigation Home Documents Senate Assembly Committees Service Agencies Docs Options Help 2025 Biennium Statutes Admin. Rules Indices Miscellaneous Archives Home Bill, Rule, and Appointment Histories Senators Representatives Committees Text of Introduced Proposals Amendment Text Acts Veto Messages Enrolled Bills Votes Assembly and Senate Floor Calendars Schedule of Committee Activities Assembly and Senate Journals Committee Records (ROCPs) Legislative Rules All Session-Related Documents Subject Index to Acts Subject Index to Legislation Subject Index to Journals Author Index to Legislation Subject Index to Clearinghouse Rules Miscellaneous Budget Documents Executive Orders Rulings of the Chair Wisconsin Supreme Court Rules Opinions of the Attorney General Town Law Forms Law Districts Session Drafting Files Feeds Preferences Show tree Hide tree Feedback Help Home Senate Home Senators Committees Session Chief Clerk Sergeant at Arms Civics Education Human Resources Assembly Home Representatives Committees Session Chief Clerk Sergeant at Arms Human Resources Schedule Joint Senate Assembly Study Legislative Audit Bureau Legislative Council Legislative Fiscal Bureau Legislative Human Resources Office Legislative Reference Bureau Legislative Technology Services Bureau Menu » 2021 » Related Documents » Votes » Senate » 2021 Senate Vote 326 Wisconsin Senate Roll Call 2021 Regular Session AB 963 BY GUNDRUM PARENT'S BILL OF RIGHTS CONCURRENCE AYES - 19 BERNIER KAPENGA STAFSHOLT BRADLEY KOOYENGA STROEBEL DARLING LEMAHIEU TESTIN FELZKOWSKI MARKLEIN WANGGAARD FEYEN NASS WIMBERGER JACQUE PETROWSKI JAGLER ROTH NAYS - 12 AGARD JOHNSON ROYS BEWLEY LARSON SMITH CARPENTER PFAFF TAYLOR COWLES RINGHAND WIRCH NOT VOTING - 2 BALLWEG ERPENBACH NO VACANT DISTRICTS PRESIDING: SENATOR KAPENGA SEQUENCE NO. 326 Tuesday, March 8, 2022 4:49 PM /2021/related/votes/senate/sv0326 votes

---
snapshot_id: 9f1f02d0-c7eb-5b1a-863d-a01164173c68
source_kind: public-record
url: https://docs.legis.wisconsin.gov/document/proposaltext/2023/REG/AB510

Wisconsin Legislature: AB510: Bill Text " href="/doc/feed?path=%2F2023%2Frelated%2Fproposals%2Fab510" /> Skip navigation Home Documents Senate Assembly Committees Service Agencies Docs Options Help 2025 Biennium Statutes Admin. Rules Indices Miscellaneous Archives Home Bill, Rule, and Appointment Histories Senators Representatives Committees Text of Introduced Proposals Amendment Text Acts Veto Messages Enrolled Bills Votes Assembly and Senate Floor Calendars Schedule of Committee Activities Assembly and Senate Journals Committee Records (ROCPs) Legislative Rules All Session-Related Documents Subject Index to Acts Subject Index to Legislation Subject Index to Journals Author Index to Legislation Subject Index to Clearinghouse Rules Miscellaneous Budget Documents Executive Orders Rulings of the Chair Wisconsin Supreme Court Rules Opinions of the Attorney General Town Law Forms Law Districts Session Drafting Files Feeds Preferences Show tree Hide tree Feedback Help Home Senate Home Senators Committees Session Chief Clerk Sergeant at Arms Civics Education Human Resources Assembly Home Representatives Committees Session Chief Clerk Sergeant at Arms Human Resources Schedule Joint Senate Assembly Study Legislative Audit Bureau Legislative Council Legislative Fiscal Bureau Legislative Human Resources Office Legislative Reference Bureau Legislative Technology Services Bureau Menu » 2023 » Related Documents » Proposal Text » AB510: Bill Text Up Up LRB-0541/1 EHS : amn&cjs 2023 - 2024 LEGISLATURE 2023 Assembly BILL 510 October 18, 2023 - Introduced by Representatives Wittke , Gundrum , Maxey , Nedweski , Schmidt , Binsfeld , Rettinger , Allen , Magnafici , Steffen , Brooks , Armstrong , Callahan , O'Connor , Goeben , Bodden , Sapik , Tittl , Michalski , Schutt , Penterman , Dittrich , Murphy , Green , Behnke , Mursau , Brandtjen , Wichgers , Gustafson , VanderMeer and Edming , cosponsored by Senators Wanggaard , Quinn , Marklein and Nass . Referred to Committee on Family Law. AB510,1,2 1 An Act to create 48.9865 of the statutes; relating to: rights reserved to a parent 2 or guardian of a child. Analysis by the Legislative Reference Bureau This bill establishes a legal standard for state infringement on fundamental rights of parents and guardians, explicitly establishes a number of parental and guardian rights relating to a child's religion, medical care and records, and education, and creates a cause of action for the violation of these rights. The bill prohibits the state from infringing on the fundamental right of parents to direct the upbringing, education, health care, and mental health of their children without demonstrating that the infringement is required by a compelling governmental interest of the highest order as applied to the child, is narrowly tailored, and is not otherwise served by a less restrictive means. The bill reserves all of the following rights to the parent of a child without interference from the state or other government entity: 1. The right to determine the religion of the child. 2. The right to determine the type of school or educational setting the child attends. 3. The right to be notified of each health care service, including vaccinations or immunizations, offered at the child's school and the right to withhold consent or decline any specific service, unless otherwise specified by law or court order. 4. The right to review all medical records related to the child, unless otherwise specified by law or court order. 5. The right to determine the names and pronouns used for the child while at school. 6. The right to review instructional materials and outlines used by the child's school, to the extent required by federal law. 7. The right to access records regarding the education of the child that are generated, maintained, or used by the child's school, to the extent required by federal law. 8. The right to timely notice by the child's school of any surveys or evaluations conducted in the child's classroom that would reveal information concerning any of the following about the child or his or her parent or family members: political affiliations or beliefs; mental or psychological problems; sexual behavior or attitudes; illegal, antisocial, self-incriminating, or demeaning behavior; critical appraisals of individuals with whom the child or parent has a close family relationship; relationships that are legally recognized as privileged, such as those with lawyers, physicians, and ministers; religious practices, affiliations, or beliefs; or income, unless otherwise specified by law. 9. The right to timely notice by the child's school, through a process consistent with school policy, of when a controversial subject will be taught or discussed in the child's classroom. The bill defines “controversial subject” as a subject of substantial public debate, disagreement, or disapproval and specifies that the term includes instruction about gender identity, sexual orientation, racial identity, structural, systemic, or institutional racism, or content that is not age-appropriate. 10. The right to opt out of a class or instructional materials at the child's school for reasons based on either religion or personal conviction. 11. The right to visit the child at school during school hours, consistent with school policy, unless otherwise specified by law or court order. 12. The right to engage with locally elected school board members of the school district in which the child is a student in accordance with school district policy, including by participating at regularly scheduled school board meetings. 13. The right to be notified of the creation of or updates to a security or surveillance system at the child's school, not including routine maintenance. 14. The right to be informed by the child's school, in accordance with school policy, of any disciplinary action taken against the child. This includes suspension, expulsion, seclusion, physical restraint, or removal from class. 15. The right to be timely informed of any acts of violence or crimes occurring on grounds of the child's school. 16. The right to receive accurate and individual information from the child's school at least two times per year regarding the academic proficiency and classroom behavior of the child. The bill also provides that a guardian has all of the rights listed in the bill, unless they are limited by law or court order. The bill provides that this list does not comprehensively prescribe all inalienable parental rights, and that a child's guardian may have rights that are more comprehensive than those listed. The bill requires a school board to adopt a policy setting forth a process by which a parent or guardian of a pupil enrolled in the school district may file a written complaint alleging that a right identified in the bill was violated. Under the bill, this policy must require the school board to hold a public hearing to address any such written complaints at least once every three months. The bill also requires that the process be timely, that it grant the school board the final decision, and that it allow a clear process to appeal that decision. The bill also allows a parent or guardian who is denied one of the rights identified in the bill to bring a civil action against a governmental body or official. The bill allows a parent or guardian to raise a violation of these rights in court or before an administrative tribunal of appropriate jurisdiction as a claim or defense. Under the bill, a parent or guardian that successfully asserts such a claim may recover declaratory relief, injunctive relief, reasonable attorney's fees and costs, and up to $10,000 for any other appropriate relief. The bill provides that nothing in the bill authorizes a parent or guardian to abuse or neglect a child in violation of state law and that it may not be construed to apply to a parent's or guardian's action or decision that would end life. The bill also provides that nothing in the bill prohibits a court from issuing an order that is otherwise permitted by law and that it may not be construed to supersede a court order. The people of the state of Wisconsin, represented in senate and assembly, do enact as follows: AB510,1 1 Section 1 . 48.9865 of the statutes is created to read: AB510,3,2 2 48.9865 Rights reserved to parents. (1) In this section: AB510,3,6 3 (a) “Controversial subject” means a subject of substantial public debate, 4 disagreement, or disapproval and includes instruction about gender identity, sexual 5 orientation, racial identity, structural, systemic, or institutional racism, or content 6 that is not age-appropriate, as defined in s. 118.019 (1m) (a). AB510,3,7 7 (b) “School board” has the meaning given in s. 115.001 (7). AB510,3,10 8 (c) “Timely notice” means written notice provided to a parent or guardian 9 through a process consistent with school policy such that the parent or guardian may 10 effectively exercise the rights set forth under this section. AB510,4,4 11 (2) This state may not infringe on the fundamental right of parents to direct 12 the upbringing, education, health care, and mental health of their children without 13 demonstrating that the infringement is required by a compelling governmental 1 interest of the highest order as applied to the child, is narrowly tailored, and is not 2 otherwise served by a less restrictive means. The rights enumerated in this section 3 are in addition to rights granted to parents under the constitutions of this state and 4 of the United States. AB510,4,6 5 (3) All of the following rights are reserved to the parent of a child without 6 interference from the state or other government entity: AB510,4,7 7 (a) The right to determine the religion of the child. AB510,4,9 8 (b) The right to determine the type of school or educational setting the child 9 attends. AB510,4,12 10 (c) The right to be notified of each health care service, including vaccinations 11 or immunizations, offered at the child's school and the right to withhold consent or 12 decline any specific service, unless otherwise specified by law or court order. AB510,4,14 13 (d) The right to review all medical records related to the child, unless otherwise 14 specified by law or court order. AB510,4,16 15 (e) The right to determine the names and pronouns used for the child while at 16 school. AB510,4,18 17 (f) The right to review instructional materials and outlines used by the child's 18 school, to the extent required by federal law. AB510,4,21 19 (g) The right to access records regarding the education of the child that are 20 generated, maintained, or used by the child's school, to the extent required by federal 21 law. AB510,4,24 22 (h) The right to timely notice by the child's school of any surveys or evaluations 23 conducted in the child's classroom that would reveal information concerning any of 24 the following about the child or his or her parent or family members: AB510,4,25 25 1. Political affiliations or beliefs. AB510,5,1 1 2. Mental or psychological problems. Down Down /2023/related/proposals/ab510 true proposaltext /2023/related/proposals/ab510 proposaltext/2023/REG/AB510 proposaltext/2023/REG/AB510 section true Menu » 2023 » Related Documents » Proposal Text » AB510: Bill Text &times; Details for PDF view Link (Permanent link) Bookmark this location View toggle Go to top of document Search in this chapter Search in this section Search in this agency Search in this chapter group Search in this chapter Search in this section Cross references for section Acts affecting this section References to this 1970 Statutes Annotations Appellate Court Citations Administrative Code Index Reference lines Clear highlighting

---
snapshot_id: 56a527a5-260b-579e-897b-bb4f81f55c14
source_kind: public-record
url: https://docs.legis.wisconsin.gov/document/proposaltext/2025/REG/AB103

Wisconsin Legislature: AB103: Bill Text " href="/doc/feed?path=%2F2025%2Frelated%2Fproposals%2Fab103" /> Skip navigation Home Documents Senate Assembly Committees Service Agencies Docs Options Help 2025 Biennium Statutes Admin. Rules Indices Miscellaneous Archives Home Bill, Rule, and Appointment Histories Senators Representatives Committees Text of Introduced Proposals Amendment Text Acts Veto Messages Enrolled Bills Votes Assembly and Senate Floor Calendars Schedule of Committee Activities Assembly and Senate Journals Committee Records (ROCPs) Legislative Rules All Session-Related Documents Subject Index to Acts Subject Index to Legislation Subject Index to Journals Author Index to Legislation Subject Index to Clearinghouse Rules Miscellaneous Budget Documents Executive Orders Rulings of the Chair Wisconsin Supreme Court Rules Opinions of the Attorney General Town Law Forms Law Districts Session Drafting Files Feeds Preferences Show tree Hide tree Feedback Help Home Senate Home Senators Committees Session Chief Clerk Sergeant at Arms Civics Education Human Resources Assembly Home Representatives Committees Session Chief Clerk Sergeant at Arms Human Resources Schedule Joint Senate Assembly Study Legislative Audit Bureau Legislative Council Legislative Fiscal Bureau Legislative Human Resources Office Legislative Reference Bureau Legislative Technology Services Bureau Menu » 2025 » Related Documents » Proposal Text » AB103: Bill Text Up Up 2025 - 2026 LEGISLATURE LRB-1245/1 FFK:cdc 2025 ASSEMBLY BILL 103 March 4, 2025 - Introduced by Representatives Dittrich , Behnke , B. Jacobson , Kreibich , Maxey , O'Connor , Tusler and Mursau , cosponsored by Senator Jacque . Referred to Committee on Education. AB103,1,2 1 An Act to create 118.1255 of the statutes; relating to: school board policies 2 related to changing a pupil’s legal name and pronouns. Analysis by the Legislative Reference Bureau By July 1, 2026, this bill requires school boards to adopt 1) a policy related to the conditions under which a school board will change a pupil’s legal name or legal name and pronouns in official school records (legal name and pronoun records policy) and 2) a policy related to the conditions under which a school board will allow school staff to regularly use or refer to a minor pupil by a name other the pupil’s legal name or by pronouns other than the pronouns provided at the time the pupil first enrolled in the school district (name and pronoun usage policy). The bill requires that a school board include certain provisions in its legal name and pronoun records policy. Under the bill, a school board’s legal name and pronoun record policy must include 1) that the initial determination is made by the principal of the school the pupil attends, 2) that the principal may only approve the change if the documentation of a legal name change is provided or, if such documentation is not provided, an affidavit is provided stating, among other things, that the pupil legally changed the pupil’s name and that it was not for a fraudulent purpose or to interfere with the rights of others, 3) for a minor pupil, a requirement that the school board make a reasonable attempt to provide each of the minor pupil’s parents and legal guardians with an opportunity to provide information in favor of or against approving the requested change; and 4) a process to appeal a principal’s decision to deny a request to the school board. The bill also specifies provisions that a school board must include in its name and pronoun usage policy. Under the bill, a school board’s name and pronoun usage policy must 1) state that a minor pupil’s parent or legal guardian determines the names and pronouns school staff are allowed use to refer to the minor pupil during school hours and 2) prohibit school staff from referring to a minor pupil by a name or pronoun that does not align with the pupil’s biological sex without written authorization from the pupil’s parent or guardian. A name and pronoun usage policy does not need to require written authorization for school staff to use a shortened version of a minor pupil’s legal first or middle name to refer to the pupil. Finally, the bill explicitly states that nothing in the bill may be construed to limit the rights of pupils, parents, or guardians under the Family Educational Rights and Privacy Act, the federal law the protects pupil records. The people of the state of Wisconsin, represented in senate and assembly, do enact as follows: AB103,1 1 Section 1 . 118.1255 of the statutes is created to read: AB103,2,4 2 118.1255 Pupil name change and pronoun usage; policies. (1) In this 3 section, “official school records” has the meaning given for “pupil records” in s. 4 118.125 (1) (d). AB103,2,6 5 (2) By July 1, 2026, each school board shall adopt a policy related to the 6 conditions under which the school board will do each of the following: AB103,2,8 7 (a) Change a pupil’s legal name or a pupil’s legal name and pronouns in 8 official school records. AB103,2,11 9 (b) Allow school board employees to regularly use or refer to a pupil who is a 10 minor by a name other than the pupil’s legal name or by pronouns other than the 11 pronouns provided at the time the pupil first enrolls in the school district. AB103,2,13 12 (3) A school board shall include at least all of the following in a policy adopted 13 under sub. (2) (a): AB103,3,2 1 (a) An initial request to change a pupil’s legal name or pronouns on official 2 school records shall be made to the principal of the school the pupil attends. AB103,3,5 3 (b) A pupil’s official school records shall be maintained under a pupil’s legal 4 name and the pronouns provided at the time the pupil first enrolls in the school 5 district, unless any of the following apply: AB103,3,8 6 1. A pupil’s parent or guardian submits a request to change the pupil’s name 7 in official school records due to a change in the pupil’s legal name in writing and 8 provides documentation of the pupil’s legal name change. AB103,3,12 9 2. If a pupil or the pupil’s parent or guardian does not provide documentation 10 of the pupil’s legal name change and the pupil is 18 years of age or older, the pupil 11 provides an affidavit that includes the pupil’s former legal name and the pupil’s 12 new legal name and affirms all of the following: AB103,3,13 13 a. The pupil has changed the pupil’s legal name. AB103,3,14 14 b. The pupil consistently uses the new legal name for all official purposes. AB103,3,15 15 c. The pupil is not a registered sex offender. AB103,3,17 16 d. The pupil has not changed the pupil’s legal name for a fraudulent purpose 17 or in order to interfere with the rights of others. AB103,3,21 18 3. If a pupil or the pupil’s parent or guardian does not provide documentation 19 of the pupil’s legal name change and the pupil is younger than 18 years of age, each 20 parent or legal guardian of the pupil provides an affidavit that includes the pupil’s 21 former legal name and the pupil’s new legal name and affirms all of the following: AB103,3,22 22 a. The pupil has changed the pupil’s legal name. AB103,3,23 23 b. The pupil consistently uses the new legal name for all official purposes. AB103,4,2 1 c. Neither the pupil, nor the parent, nor the guardian is prohibited by law 2 from changing the pupil’s name. AB103,4,4 3 d. The pupil has not changed the pupil’s legal name for a fraudulent purpose 4 or in order to interfere with the rights of others. AB103,4,11 5 (c) For a pupil who is under 18 years of age, before approving a request to 6 change the pupil’s legal name or the pupil’s legal name and pronouns in official 7 school records, the school board shall make a reasonable attempt to notify each of 8 the pupil’s parents and legal guardians who have a right to access the pupil’s 9 official school records under s. 118.125 (2) and provide an opportunity for each 10 parent or legal guardian to present any additional records or documentation to the 11 school board before the school board approves or denies the request. AB103,4,16 12 (d) If a request for a pupil name change does not include documentation of a 13 legal name change and the pupil’s parents or guardians do not all support the 14 request to change the pupil’s legal name or the pupil’s legal name and pronouns in 15 the pupil’s official school records, a principal or school administrator shall deny the 16 request. AB103,4,19 17 (e) A principal or school administrator may not change a pupil’s legal name or 18 pronouns in official school records unless the policy adopted under sub. (2) (a) and 19 any procedures developed to implement the policy have been followed. AB103,5,2 20 (f) A procedure under which a parent, legal guardian, or pupil may appeal the 21 denial of a request to change the pupil’s legal name or the pupil’s legal name and 22 pronouns in official school records to the school board. A school board shall treat an 23 appeal under this paragraph in the same manner as a request to correct or delete 1 information in official school records that is inaccurate, misleading, or otherwise in 2 violation of the privacy rights of students under 20 USC 1232 g. AB103,5,4 3 (4) A school board shall include at least all of the following in a policy adopted 4 under sub. (2) (b): AB103,5,6 5 (a) A pupil’s parent or legal guardian determines the names and pronouns 6 school staff may use to refer to the pupil who is a minor during school hours. AB103,5,9 7 (b) During school hours, school staff may not refer to a pupil who is a minor by 8 using a name or pronouns that do not align with the pupil’s biological sex without 9 written authorization from the pupil’s parent or legal guardian. AB103,5,12 10 (c) Written authorization from a parent or legal guardian is not required 11 under par. (b) to refer to a pupil using a shortened version of the pupil’s legal first or 12 middle name. AB103,5,14 13 (5) This section may not be construed to impair the rights of pupils, parents, 14 or guardians under 20 USC 1232g . AB103,5,15 15 (end) Down Down /2025/related/proposals/ab103 true proposaltext /2025/related/proposals/ab103 proposaltext/2025/REG/AB103 proposaltext/2025/REG/AB103 section true Menu » 2025 » Related Documents » Proposal Text » AB103: Bill Text &times; Details for PDF view Link (Permanent link) Bookmark this location View toggle Go to top of document Search in this chapter Search in this section Search in this agency Search in this chapter group Search in this chapter Search in this section Cross references for section Acts affecting this section References to this 1970 Statutes Annotations Appellate Court Citations Administrative Code Index Reference lines Clear highlighting

---
snapshot_id: 08e43924-b6e1-548d-9c25-d2dab9f61788
source_kind: public-record
url: https://docs.legis.wisconsin.gov/document/votes/2025/sv0170

2025 Senate Vote 170 Skip navigation Home Documents Senate Assembly Committees Service Agencies Docs Options Help 2025 Biennium Statutes Admin. Rules Indices Miscellaneous Archives Home Bill, Rule, and Appointment Histories Senators Representatives Committees Text of Introduced Proposals Amendment Text Acts Veto Messages Enrolled Bills Votes Assembly and Senate Floor Calendars Schedule of Committee Activities Assembly and Senate Journals Committee Records (ROCPs) Legislative Rules All Session-Related Documents Subject Index to Acts Subject Index to Legislation Subject Index to Journals Author Index to Legislation Subject Index to Clearinghouse Rules Miscellaneous Budget Documents Executive Orders Rulings of the Chair Wisconsin Supreme Court Rules Opinions of the Attorney General Town Law Forms Law Districts Session Drafting Files Feeds Preferences Show tree Hide tree Feedback Help Home Senate Home Senators Committees Session Chief Clerk Sergeant at Arms Civics Education Human Resources Assembly Home Representatives Committees Session Chief Clerk Sergeant at Arms Human Resources Schedule Joint Senate Assembly Study Legislative Audit Bureau Legislative Council Legislative Fiscal Bureau Legislative Human Resources Office Legislative Reference Bureau Legislative Technology Services Bureau Menu » 2025 » Related Documents » Votes » Senate » 2025 Senate Vote 170 Wisconsin Senate Roll Call 2025 Regular Session AB 103 BY DITTRICH SCHOOL DISTRICT POLICY - NAME CHANGE AND PRONOUN U CONCURRENCE AYES - 18 BRADLEY JAGLER QUINN CABRAL-GUEVARA JAMES STAFSHOLT FELZKOWSKI KAPENGA TESTIN FEYEN LEMAHIEU TOMCZYK HUTTON MARKLEIN WANGGAARD JACQUE NASS WIMBERGER NAYS - 15 CARPENTER JOHNSON ROYS DASSLER-ALFHEI KEYESKI SMITH DRAKE LARSON SPREITZER HABUSH SINYKIN PFAFF WALL HESSELBEIN RATCLIFF WIRCH NOT VOTING - 0 NO VACANT DISTRICTS PRESIDING: SENATOR FELZKOWSKI SEQUENCE NO. 170 Wednesday, February 11, 2026 2:47 PM /2025/related/votes/senate/sv0170 votes

---
snapshot_id: 8e0c4b05-37aa-50c3-a12f-bec23a4e6e5b
source_kind: public-record
url: https://docs.legis.wisconsin.gov/document/proposaltext/2021/REG/AB963

Wisconsin Legislature: AB963: Bill Text " href="/doc/feed?path=%2F2021%2Frelated%2Fproposals%2Fab963" /> Skip navigation Home Documents Senate Assembly Committees Service Agencies Docs Options Help 2025 Biennium Statutes Admin. Rules Indices Miscellaneous Archives Home Bill, Rule, and Appointment Histories Senators Representatives Committees Text of Introduced Proposals Amendment Text Acts Veto Messages Enrolled Bills Votes Assembly and Senate Floor Calendars Schedule of Committee Activities Assembly and Senate Journals Committee Records (ROCPs) Legislative Rules All Session-Related Documents Subject Index to Acts Subject Index to Legislation Subject Index to Journals Author Index to Legislation Subject Index to Clearinghouse Rules Miscellaneous Budget Documents Executive Orders Rulings of the Chair Wisconsin Supreme Court Rules Opinions of the Attorney General Town Law Forms Law Districts Session Drafting Files Feeds Preferences Show tree Hide tree Feedback Help Home Senate Home Senators Committees Session Chief Clerk Sergeant at Arms Civics Education Human Resources Assembly Home Representatives Committees Session Chief Clerk Sergeant at Arms Human Resources Schedule Joint Senate Assembly Study Legislative Audit Bureau Legislative Council Legislative Fiscal Bureau Legislative Human Resources Office Legislative Reference Bureau Legislative Technology Services Bureau Menu » 2021 » Related Documents » Proposal Text » AB963: Bill Text Up Up LRB-5468/1 EHS : cjs&cdc 2021 - 2022 LEGISLATURE 2021 Assembly BILL 963 February 8, 2022 - Introduced by Representatives Gundrum , Thiesfeldt , Wittke , Murphy , Penterman , Moses , Steffen , Vorpagel , Brandtjen , Rozar , Knodl and Macco , cosponsored by Senators Darling , Roth , Wanggaard and Nass . Referred to Committee on Education. AB963,1,2 1 An Act to create 48.9865 of the statutes; relating to: rights reserved to a parent 2 or guardian of a child. Analysis by the Legislative Reference Bureau This bill establishes a legal standard for state infringement on fundamental rights of parents and guardians, explicitly establishes a number of parental and guardian rights relating to a child's religion, medical care and records, and education, and creates a cause of action for the violation of these rights. The bill prohibits the state from infringing on the fundamental right of parents to direct the upbringing, education, health care, and mental health of their children without demonstrating that the infringement is required by a compelling governmental interest of the highest order as applied to the child, is narrowly tailored, and is not otherwise served by a less restrictive means. The bill reserves all of the following rights to the parent of a child without interference from the state or other government entity: 1. The right to determine the religion of the child. 2. The right to determine the type of school or educational setting the child attends. 3. The right to determine medical care for the child, unless specified otherwise in law or court order. 4. The right to review all medical records related to the child, unless specified otherwise in law or court order. 5. The right to determine the names and pronouns used for the child while at school. 6. The right to review instructional materials and outlines used by the child's school. 7. The right to access any education-related information regarding the child. 8. The right to advanced notice of any polls or surveys instituted by the child's classroom. 9. The right to request notice of when certain subjects will be taught or discussed in the child's classroom. 10. The right to opt out of a class or instructional materials for reasons based on either religion or personal conviction. 11. The right to visit the child at school during school hours, consistent with school policy, unless otherwise specified in law or court order. 12. The right to engage with locally elected school board members of the school district in which the child is a student, including participating at regularly scheduled school board meetings. 13. The right to be notified of the creation of or updates to a security or surveillance system at the child's school. 14. The right to be informed of any disciplinary action taken against or threatened against the child. 15. The right to be timely informed of any acts of violence or crimes occurring on grounds of the child's school. The bill also provides that a guardian has all of the rights listed in the bill, unless they are limited by law or court order. The bill provides that this list does not comprehensively prescribe all inalienable parental rights, and that a child's guardian may have rights that are more comprehensive than those listed. The bill allows a parent or guardian to bring a suit against a governmental body or official based on any violation of these rights or any other action that interferes with or usurps the fundamental right of a parent or guardian to direct the upbringing, education, health care, and mental health of a child. The bill allows a parent or guardian to raise a violation of these rights in court or before an administrative tribunal of appropriate jurisdiction as a claim or defense. Under the bill, a parent or guardian that successfully asserts such a claim may recover declaratory relief, injunctive relief, reasonable attorney's fees and costs, and any other appropriate relief. The bill also authorizes the attorney general to enforce these rights. The bill provides that nothing in the bill authorizes a parent or guardian to abuse or neglect a child in violation of state law, and it may not be construed to apply to a parent's or guardian's action or decision that would end life. The bill also provides that nothing in the bill prohibits a court from issuing an order that is otherwise permitted by law. The people of the state of Wisconsin, represented in senate and assembly, do enact as follows: AB963,1 1 Section 1 . 48.9865 of the statutes is created to read: AB963,3,8 2 48.9865 Rights reserved to parents. (1) This state may not infringe on the 3 fundamental right of parents to direct the upbringing, education, health care, and 4 mental health of their children without demonstrating that the infringement is 5 required by a compelling governmental interest of the highest order as applied to the 6 child, is narrowly tailored, and is not otherwise served by a less restrictive means. 7 The rights enumerated in this section are in addition to rights granted to parents 8 under the constitutions of this state and of the United States. AB963,3,10 9 (2) All of the following rights are reserved to the parent of a child without 10 interference from the state or other government entity: AB963,3,11 11 (a) The right to determine the religion of the child. AB963,3,13 12 (b) The right to determine the type of school or educational setting the child 13 attends. AB963,3,15 14 (c) The right to determine medical care for the child, unless specified otherwise 15 in law or court order. AB963,3,17 16 (d) The right to review all medical records related to the child, unless specified 17 otherwise in law or court order. AB963,3,19 18 (e) The right to determine the names and pronouns used for the child while at 19 school. AB963,3,21 20 (f) The right to review instructional materials and outlines used by the child's 21 school. AB963,3,22 22 (g) The right to access any education-related information regarding the child. AB963,3,24 23 (h) The right to advanced notice of any polls or surveys instituted by the child's 24 classroom. AB963,4,2 1 (i) The right to request notice of when certain subjects will be taught or 2 discussed in the child's classroom. AB963,4,4 3 (j) The right to opt out of a class or instructional materials for reasons based 4 on either religion or personal conviction. AB963,4,6 5 (k) The right to visit the child at school during school hours, consistent with 6 school policy, unless otherwise specified in law or court order. AB963,4,9 7 (L) The right to engage with locally elected school board members of the school 8 district in which the child is a student, including participating at regularly scheduled 9 school board meetings. AB963,4,11 10 (m) The right to be notified of the creation of or updates to a security or 11 surveillance system at the child's school. AB963,4,13 12 (n) The right to be informed of any disciplinary action taken against or 13 threatened against the child. AB963,4,15 14 (o) The right to be timely informed of any acts of violence or crimes occurring 15 on grounds of the child's school. AB963,4,17 16 (3) Except as limited by other law or court order, a guardian of a child has the 17 same rights specified under subs. (1) and (2). Down Down /2021/related/proposals/ab963 true proposaltext /2021/related/proposals/ab963 proposaltext/2021/REG/AB963 proposaltext/2021/REG/AB963 section true Menu » 2021 » Related Documents » Proposal Text » AB963: Bill Text &times; Details for PDF view Link (Permanent link) Bookmark this location View toggle Go to top of document Search in this chapter Search in this section Search in this agency Search in this chapter group Search in this chapter Search in this section Cross references for section Acts affecting this section References to this 1970 Statutes Annotations Appellate Court Citations Administrative Code Index Reference lines Clear highlighting

---
snapshot_id: 8c8b1a2b-4204-5ae9-8661-ce809af3227e
source_kind: public-record
url: https://docs.legis.wisconsin.gov/document/votes/2023/sv0263

2023 Senate Vote 263 Skip navigation Home Documents Senate Assembly Committees Service Agencies Docs Options Help 2025 Biennium Statutes Admin. Rules Indices Miscellaneous Archives Home Bill, Rule, and Appointment Histories Senators Representatives Committees Text of Introduced Proposals Amendment Text Acts Veto Messages Enrolled Bills Votes Assembly and Senate Floor Calendars Schedule of Committee Activities Assembly and Senate Journals Committee Records (ROCPs) Legislative Rules All Session-Related Documents Subject Index to Acts Subject Index to Legislation Subject Index to Journals Author Index to Legislation Subject Index to Clearinghouse Rules Miscellaneous Budget Documents Executive Orders Rulings of the Chair Wisconsin Supreme Court Rules Opinions of the Attorney General Town Law Forms Law Districts Session Drafting Files Feeds Preferences Show tree Hide tree Feedback Help Home Senate Home Senators Committees Session Chief Clerk Sergeant at Arms Civics Education Human Resources Assembly Home Representatives Committees Session Chief Clerk Sergeant at Arms Human Resources Schedule Joint Senate Assembly Study Legislative Audit Bureau Legislative Council Legislative Fiscal Bureau Legislative Human Resources Office Legislative Reference Bureau Legislative Technology Services Bureau Menu » 2023 » Related Documents » Votes » Senate » 2023 Senate Vote 263 Wisconsin Senate Roll Call 2023 Regular Session AB 510 BY WITTKE PARENT'S BILL OF RIGHTS CONCURRENCE AYES - 22 BALLWEG JAGLER STAFSHOLT BRADLEY JAMES STROEBEL CABRAL-GUEVARA KAPENGA TESTIN COWLES KNODL TOMCZYK FELZKOWSKI LEMAHIEU WANGGAARD FEYEN MARKLEIN WIMBERGER HUTTON NASS JACQUE QUINN NAYS - 10 AGARD LARSON SPREITZER CARPENTER PFAFF WIRCH HESSELBEIN ROYS JOHNSON SMITH NOT VOTING - 0 VACANT DISTRICTS: 4 PRESIDING: SENATOR KAPENGA SEQUENCE NO. 263 Tuesday, February 13, 2024 2:26 PM /2023/related/votes/senate/sv0263 votes