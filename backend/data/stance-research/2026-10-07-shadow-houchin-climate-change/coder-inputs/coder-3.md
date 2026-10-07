You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-houchin-climate-change/labels/coder-3.json. Write JSON only, matching
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

politician_id: 68568faf-1e0f-4ca2-89d9-bda625665712  office_id: b343becb-af7d-4a19-a6a1-2e5df210f344
Erin Houchin — U.S. House of Representatives - Indiana 9th Congressional District, Indiana (seated, level: federal)
Current term: 2023-01-03 (precision: day) to present

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
snapshot_id: 56875b74-a61a-5bf8-85ef-409ea73908c5
source_kind: own-site (the person's own site or account)
url: https://houchin.house.gov/media/press-releases/congresswoman-erin-houchin-introduces-resolution-stop-fdic-climate-rule

Congresswoman Erin Houchin Introduces Resolution to Stop FDIC Climate Rule | Congresswoman Erin Houchin Skip to main content 342 Cannon House Office Building, Washington, DC 20515 Email Me (202) 225-5315 About Committees and Caucuses Our District Votes and Legislation Contact Newsletter Subscribe Office Locations Media Press Releases Issues Agriculture Economy Education Energy Health Veterans Border Security Services Art Competition Congressional App Challenge Congressional Commendations Flags Grant Applicants Help with a Federal Agency Internships Service Academy Nominations Tours and Tickets America 250 Attention Seniors - Fraud Alert! Casework Success Stories Community Project Funding Help for Veterans Subscribe X How Can I Help? Home Media Press Releases Congresswoman Erin Houchin Introduces Resolution to Stop FDIC Climate Rule April 10, 2024 Press Release Washington, D.C. (April 10, 2024) - Congresswoman Erin Houchin (R-IN) introduced a resolution aimed at halting the implementation of the Federal Deposit Insurance Corporation’s (FDIC) recent climate rule. The resolution, under a Congressional Review Act, pushes back against the Biden Administration’s climate-obsessed agenda that undermines proper risk management within the banking sector. This climate rule, which was issued concurrently by the Federal Reserve System, the Office of the Comptroller of the Currency (OCC), and the FDIC, comes on the heels of the collapse of Silicon Valley Bank and Signature Bank. Under the Biden Administration’s direction, this rule requires banks to account for customers’ climate risks and other Environmental, Social, and Governance (ESG) factors when determining who to bank, offer loans to, and ultimately do business with. It has drawn criticism for diverting attention away from sound banking practices. Instead of safeguarding the banking system, the rule would increase burdens and compliance costs for banks, ultimately passing on these costs to consumers. Issued on October 24, 2023, the rule’s guidance applies to banks with $100 billion or more in total consolidated assets and emphasizes a risk-based approach tailored to each covered bank's business model and operations. "In this environment of high inflation and energy costs, the last thing we need from this Administration is more red tape and more attacks on American energy producers," said Congresswoman Houchin. "The FDIC is not a climate regulator. This resolution aims to refocus its attention on the safety and soundness of our banking sector, rather than pursuing an ideologically driven climate agenda." Congresswoman Houchin's resolution seeks to nullify this burdensome rule, redirecting regulatory attention to the fundamental concerns of risk management and financial stability within the banking industry. Office Locations Washington DC Office 342 Cannon House Office Building Washington, DC 20515 Phone: (202) 225-5315 Salem District Office 104 W Hackberry Street Salem, IN 47167 Phone: (812) 288-3999 Top Copyright Privacy House.gov Accessibility RSS

---
snapshot_id: d307e2db-78ae-55a7-b904-26197d0528bc
source_kind: own-site (the person's own site or account)
url: https://houchin.house.gov/media/press-releases/rep-houchin-applauds-announcement-nuclear-microreactor-nws-crane-develop

Rep. Houchin Applauds Announcement of Nuclear Microreactor at NWS Crane to Develop Energy Resilience | Congresswoman Erin Houchin Skip to main content 342 Cannon House Office Building, Washington, DC 20515 Email Me (202) 225-5315 About Committees and Caucuses Our District Votes and Legislation Contact Newsletter Subscribe Office Locations Media Press Releases Issues Agriculture Economy Education Energy Health Veterans Border Security Services Art Competition Congressional App Challenge Congressional Commendations Flags Grant Applicants Help with a Federal Agency Internships Service Academy Nominations Tours and Tickets America 250 Attention Seniors - Fraud Alert! Casework Success Stories Community Project Funding Help for Veterans Subscribe X How Can I Help? Home Media Press Releases Rep. Houchin Applauds Announcement of Nuclear Microreactor at NWS Crane to Develop Energy Resilience September 9, 2026 Press Release Today, Congresswoman Erin Houchin (IN-09) celebrated the Department of War’s announcement that Naval Weapons Station (NWS) Crane will host Indiana's first advanced nuclear Micro Modular Reactor (MMR), with installation planned no later than September 2028. The project, executed jointly by the Army's Janus Program, the Office of the Assistant Secretary of the Navy for Energy, Installations and Environment, the Office of the Under Secretary of War for Research and Engineering, and the State of Indiana, will deliver reliable, around-the-clock power to one of the nation's premier warfighting innovation hubs. "Crane is a unique and valuable asset to our National Defense Portfolio and this investment demonstrates that Indiana is at the forefront of unleashing American energy.” said Rep. Houchin. "With proven success in powering submarines, microreactors at our military installations is a natural next step in U.S. energy deployment and rebuilding our nuclear supply chain. The project will also have a positive impact at West Gate due to increased power supply to the base. Thank you to the Department of War, the Navy, our state and federal partners and to everyone whose efforts made this day possible. I am proud to have been part of a chorus of voices advocating for this project and I am proud to be among NWS Crane’s advocates in Washington.” As the first power-producing nuclear reactor sited in Indiana, the Crane MMR will expand the state's power generation capacity and support the region's long-standing role as a hub for national defense research and manufacturing. The project implements President Trump's Executive Orders on deploying advanced nuclear reactor technologies for national security and reinvigorating the nuclear industrial base. ### Office Locations Washington DC Office 342 Cannon House Office Building Washington, DC 20515 Phone: (202) 225-5315 Salem District Office 104 W Hackberry Street Salem, IN 47167 Phone: (812) 288-3999 Top Copyright Privacy House.gov Accessibility RSS

---
snapshot_id: be4156c6-63f3-5dbc-b5dd-f8c03329843d
source_kind: public-record
url: https://clerk.house.gov/Votes/2023391

Office of the Clerk, U.S. House of Representatives Find Your Representative Search Office of the Clerk Toggle navigation Search Office of the Clerk Search button Legislative Information Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions 119th Congress, 2nd Session House Not In Session Next Session: October 9th, 2026 at 12:30 PM House Floor Proceedings Watch live.house.gov Additional Resources Votes Legacy View - 2024 119th Congress Nominees Statistics of the 2024 Congressional Election Final House Calendar (118th Congress) Résumé of Congressional Activity Legislative Search Congressional Record U.S. Senate House Schedule Bills This Week House Voting Days Member Information Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Republicans 218 218 Democrats 214 214 Independents 1 1 Vacancies 2 2 Republican Leadership Rep. Mike Johnson Speaker of the House Rep. Steve Scalise Majority Leader Rep. Tom Emmer Majority Whip Rep. Lisa C. McClain Republican Conference Chair Rep. Jay Obernolte Republican Policy Committee Chair Democratic Leadership Rep. Hakeem S. Jeffries Minority Leader Rep. Katherine M. Clark Minority Whip Rep. Pete Aguilar Democratic Caucus Chair Rep. Ted Lieu Democratic Caucus Vice Chair Additional Resources Find Your Representative Official List of Members by State Official Member Telephone Directory Duplicate and Similar Names of Members Terms of Service Mailing Labels [ MS Word | Text File ] Member Data [ Excel | XML | User Guide ] Biographical Directory Members on Congress.gov Committee Information COMMITTEE INFORMATION COMMITTEE PROFILES Agriculture Appropriations Armed Services Budget Education and Workforce Energy and Commerce Ethics Financial Services Foreign Affairs Homeland Security House Administration Judiciary Natural Resources Oversight and Government Reform Rules Science, Space, and Technology Small Business Transportation and Infrastructure Veterans' Affairs Ways and Means Select Intelligence Select Strategic Competition Joint Economic Joint Library Joint Printing Joint Taxation Additional Resources Official List of Members with Committee Assignments Official List of Standing Committees and Subcommittees Committee Repository Committee Reports Committees on Congress.gov Committee Data [ Excel ] Disclosures Disclosures PUBLIC DISCLOSURE Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications Additional Resources Lobbying Disclosures Public Laws Lobbying Disclosure Act About the Clerk About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office The Clerk of the House The Honorable Kevin F. McCumber Clerk of the U.S. House of Representatives Deputy Clerk Michelle H. Reinshuttle Deputy Clerk Contact Information Mailing Address U.S. Capitol Room H154 Washington, DC 20515&ndash;6601 Telephone Number (202) 225&ndash;7000 Office Hours 9:00 AM&ndash;6:00 PM, Monday&ndash;Friday Additional Resources Artificial Intelligence Use Case Inventory [ USHouse-Clerk-1: Comparative Print Suite ] 119th Congress, 2nd Session Back to Previous Page Roll Call 391 | Bill Number: H. R. 1435 Share XML View | HTML View Sep 14, 2023, 03:56 PM | 118th Congress, 1st Session Vote Question: On Passage Preserving Choice in Vehicle Purchases Act Vote Type: Yea-And-Nay Status: Passed VOTES yea: 222 nay: 190 present: 0 not voting: 22 Remote Voting by Proxy Votes by party votes by party Party Yeas Nays Present Not Voting Republican 214 0 0 8 Democratic 8 190 0 14 Independent 0 0 0 0 Total 222 190 0 22 All votes Keyword Name Party All Parties Republican Democratic Independent State All States Votes All Votes YEA/AYE NAY/NO PRESENT NOT VOTING All votes Representative Party State Vote Adams Adams Democratic North Carolina NC Nay Aderholt Aderholt Republican Alabama AL Yea Aguilar Aguilar Democratic California CA Nay Alford Alford Republican Missouri MO Yea Allen Allen Republican Georgia GA Yea Allred Allred Democratic Texas TX Not Voting Amodei Amodei Republican Nevada NV Yea Armstrong Armstrong Republican North Dakota ND Yea Arrington Arrington Republican Texas TX Yea Auchincloss Auchincloss Democratic Massachusetts MA Nay Babin Babin Republican Texas TX Yea Bacon Bacon Republican Nebraska NE Yea Baird Baird Republican Indiana IN Yea Balderson Balderson Republican Ohio OH Yea Balint Balint Democratic Vermont VT Nay Banks Banks Republican Indiana IN Yea Barr Barr Republican Kentucky KY Yea Barragán Barragan Democratic California CA Nay Bean (FL) Bean (FL) Republican Florida FL Yea Beatty Beatty Democratic Ohio OH Nay Bentz Bentz Republican Oregon OR Yea Bera Bera Democratic California CA Nay Bergman Bergman Republican Michigan MI Yea Beyer Beyer Democratic Virginia VA Nay Bice Bice Republican Oklahoma OK Yea Biggs Biggs Republican Arizona AZ Yea Bilirakis Bilirakis Republican Florida FL Yea Bishop (GA) Bishop (GA) Democratic Georgia GA Nay Bishop (NC) Bishop (NC) Republican North Carolina NC Yea Blumenauer Blumenauer Democratic Oregon OR Nay Blunt Rochester Blunt Rochester Democratic Delaware DE Nay Boebert Boebert Republican Colorado CO Yea Bonamici Bonamici Democratic Oregon OR Nay Bost Bost Republican Illinois IL Yea Bowman Bowman Democratic New York NY Nay Boyle (PA) Boyle (PA) Democratic Pennsylvania PA Nay Brecheen Brecheen Republican Oklahoma OK Yea Brown Brown Democratic Ohio OH Nay Brownley Brownley Democratic California CA Nay Buchanan Buchanan Republican Florida FL Yea Buck Buck Republican Colorado CO Yea Bucshon Bucshon Republican Indiana IN Yea Budzinski Budzinski Democratic Illinois IL Nay Burchett Burchett Republican Tennessee TN Yea Burgess Burgess Republican Texas TX Yea Burlison Burlison Republican Missouri MO Yea Bush Bush Democratic Missouri MO Nay Calvert Calvert Republican California CA Yea Cammack Cammack Republican Florida FL Yea Caraveo Caraveo Democratic Colorado CO Yea Carbajal Carbajal Democratic California CA Nay Cárdenas Cardenas Democratic California CA Nay Carey Carey Republican Ohio OH Yea Carl Carl Republican Alabama AL Yea Carson Carson Democratic Indiana IN Nay Carter (GA) Carter (GA) Republican Georgia GA Yea Carter (LA) Carter (LA) Democratic Louisiana LA Nay Carter (TX) Carter (TX) Republican Texas TX Yea Cartwright Cartwright Democratic Pennsylvania PA Nay Casar Casar Democratic Texas TX Nay Case Case Democratic Hawaii HI Nay Casten Casten Democratic Illinois IL Nay Castor (FL) Castor (FL) Democratic Florida FL Nay Castro (TX) Castro (TX) Democratic Texas TX Not Voting Chavez-DeRemer Chavez-DeRemer Republican Oregon OR Yea Cherfilus-McCormick Cherfilus-McCormick Democratic Florida FL Nay Chu Chu Democratic California CA Nay Ciscomani Ciscomani Republican Arizona AZ Yea Clark (MA) Clark (MA) Democratic Massachusetts MA Nay Clarke (NY) Clarke (NY) Democratic New York NY Nay Cleaver Cleaver Democratic Missouri MO Nay Cline Cline Republican Virginia VA Yea Cloud Cloud Republican Texas TX Yea Clyburn Clyburn Democratic South Carolina SC Nay Clyde Clyde Republican Georgia GA Yea Cohen Cohen Democratic Tennessee TN Not Voting Cole Cole Republican Oklahoma OK Yea Collins Collins Republican Georgia GA Yea Comer Comer Republican Kentucky KY Yea Connolly Connolly Democratic Virginia VA Nay Correa Correa Democratic California CA Nay Costa Costa Democratic California CA Yea Courtney Courtney Democratic Connecticut CT Nay Craig Craig Democratic Minnesota MN Nay Crane Crane Republican Arizona AZ Yea Crawford Crawford Republican Arkansas AR Yea Crenshaw Crenshaw Republican Texas TX Not Voting Crockett Crockett Democratic Texas TX Nay Crow Crow Democratic Colorado CO Nay Cuellar Cuellar Democratic Texas TX Yea Curtis Curtis Republican Utah UT Yea D'Esposito D'Esposito Republican New York NY Not Voting Davids (KS) Davids (KS) Democratic Kansas KS Nay Davidson Davidson Republican Ohio OH Yea Davis (IL) Davis (IL) Democratic Illinois IL Nay Davis (NC) Davis (NC) Democratic North Carolina NC Yea De La Cruz De La Cruz Republican Texas TX Yea Dean (PA) Dean (PA) Democratic Pennsylvania PA Nay DeGette DeGette Democratic Colorado CO Nay DeLauro DeLauro Democratic Connecticut CT Nay DelBene DelBene Democratic Washington WA Nay Deluzio Deluzio Democratic Pennsylvania PA Nay DeSaulnier DeSaulnier Democratic California CA Nay DesJarlais DesJarlais Republican Tennessee TN Yea Diaz-Balart Diaz-Balart Republican Florida FL Not Voting Dingell Dingell Democratic Michigan MI Nay Doggett Doggett Democratic Texas TX Nay Donalds Donalds Republican Florida FL Yea Duarte Duarte Republican California CA Yea Duncan Duncan Republican South Carolina SC Yea Dunn (FL) Dunn (FL) Republican Florida FL Yea Edwards Edwards Republican North Carolina NC Yea Ellzey Ellzey Republican Texas TX Yea Emmer Emmer Republican Minnesota MN Yea Escobar Escobar Democratic Texas TX Nay Eshoo Eshoo Democratic California CA Nay Espaillat Espaillat Democratic New York NY Nay Estes Estes Republican Kansas KS Yea Evans Evans Democratic Pennsylvania PA Nay Ezell Ezell Republican Mississippi MS Yea Fallon Fallon Republican Texas TX Yea Feenstra Feenstra Republican Iowa IA Yea Ferguson Ferguson Republican Georgia GA Yea Finstad Finstad Republican Minnesota MN Yea Fischbach Fischbach Republican Minnesota MN Yea Fitzgerald Fitzgerald Republican Wisconsin WI Yea Fitzpatrick Fitzpatrick Republican Pennsylvania PA Yea Fleischmann Fleischmann Republican Tennessee TN Yea Fletcher Fletcher Democratic Texas TX Nay Flood Flood Republican Nebraska NE Yea Foster Foster Democratic Illinois IL Nay Foushee Foushee Democratic North Carolina NC Nay Foxx Foxx Republican North Carolina NC Yea Frankel, Lois Frankel, Lois Democratic Florida FL Nay Franklin, C. Scott Franklin, C. Scott Republican Florida FL Yea Frost Frost Democratic Florida FL Nay Fry Fry Republican South Carolina SC Yea Fulcher Fulcher Republican Idaho ID Yea Gaetz Gaetz Republican Florida FL Yea Gallagher Gallagher Republican Wisconsin WI Yea Gallego Gallego Democratic Arizona AZ Nay Garamendi Garamendi Democratic California CA Nay Garbarino Garbarino Republican New York NY Yea García (IL) Garcia (IL) Democratic Illinois IL Nay Garcia (TX) Garcia (TX) Democratic Texas TX Nay Garcia, Mike Garcia, Mike Republican California CA Yea Garcia, Robert Garcia, Robert Democratic California CA Nay Gimenez Gimenez Republican Florida FL Yea Golden (ME) Golden (ME) Democratic Maine ME Yea Goldman (NY) Goldman (NY) Democratic New York NY Nay Gomez Gomez Democratic California CA Nay Gonzales, Tony Gonzales, Tony Republican Texas TX Yea Gonzalez, Vicente Gonzalez, Vicente Democratic Texas TX Nay Good (VA) Good (VA) Republican Virginia VA Yea Gooden (TX) Gooden (TX) Republican Texas TX Yea Gosar Gosar Republican Arizona AZ Yea Gottheimer Gottheimer Democratic New Jersey NJ Nay Granger Granger Republican Texas TX Yea Graves (LA) Graves (LA) Republican Louisiana LA Yea Graves (MO) Graves (MO) Republican Missouri MO Yea Green (TN) Green (TN) Republican Tennessee TN Yea Green, Al (TX) Green, Al (TX) Democratic Texas TX Nay Greene (GA) Greene (GA) Republican Georgia GA Yea Griffith Griffith Republican Virginia VA Yea Grijalva Grijalva Democratic Arizona AZ Nay Grothman Grothman Republican Wisconsin WI Yea Guest Guest Republican Mississippi MS Yea Guthrie Guthrie Republican Kentucky KY Yea Hageman Hageman Republican Wyoming WY Yea Harder (CA) Harder (CA) Democratic California CA Nay Harris Harris Republican Maryland MD Yea Harshbarger Harshbarger Republican Tennessee TN Yea Hayes Hayes Democratic Connecticut CT Nay Hern Hern Republican Oklahoma OK Yea Higgins (LA) Higgins (LA) Republican Louisiana LA Yea Higgins (NY) Higgins (NY) Democratic New York NY Yea Hill Hill Republican Arkansas AR Yea Himes Himes Democratic Connecticut CT Nay Hinson Hinson Republican Iowa IA Yea Horsford Horsford Democratic Nevada NV Nay Houchin Houchin Republican Indiana IN Yea Houlahan Houlahan Democratic Pennsylvania PA Nay Hoyer Hoyer Democratic Maryland MD Not Voting Hoyle (OR) Hoyle (OR) Democratic Oregon OR Nay Hudson Hudson Republican North Carolina NC Yea Huffman Huffman Democratic California CA Nay Huizenga Huizenga Republican Michigan MI Yea Hunt Hunt Republican Texas TX Yea Issa Issa Republican California CA Yea Ivey Ivey Democratic Maryland MD Not Voting Jackson (IL) Jackson (IL) Democratic Illinois IL Nay Jackson (NC) Jackson (NC) Democratic North Carolina NC Nay Jackson (TX) Jackson (TX) Republican Texas TX Yea Jackson Lee Jackson Lee Democratic Texas TX Not Voting Jacobs Jacobs Democratic California CA Nay James James Republican Michigan MI Yea Jayapal Jayapal Democratic Washington WA Nay Jeffries Jeffries Democratic New York NY Nay Johnson (GA) Johnson (GA) Democratic Georgia GA Nay Johnson (LA) Johnson (LA) Republican Louisiana LA Yea Johnson (OH) Johnson (OH) Republican Ohio OH Yea Johnson (SD) Johnson (SD) Republican South Dakota SD Yea Jordan Jordan Republican Ohio OH Yea Joyce (OH) Joyce (OH) Republican Ohio OH Yea Joyce (PA) Joyce (PA) Republican Pennsylvania PA Yea Kamlager-Dove Kamlager-Dove Democratic California CA Nay Kaptur Kaptur Democratic Ohio OH Nay Kean (NJ) Kean (NJ) Republican New Jersey NJ Yea Keating Keating Democratic Massachusetts MA Nay Kelly (IL) Kelly (IL) Democratic Illinois IL Nay Kelly (MS) Kelly (MS) Republican Mississippi MS Yea Kelly (PA) Kelly (PA) Republican Pennsylvania PA Yea Khanna Khanna Democratic California CA Nay Kiggans (VA) Kiggans (VA) Republican Virginia VA Yea Kildee Kildee Democratic Michigan MI Nay Kiley Kiley Republican California CA Yea Kilmer Kilmer Democratic Washington WA Nay Kim (CA) Kim (CA) Republican California CA Yea Kim (NJ) Kim (NJ) Democratic New Jersey NJ Nay Krishnamoorthi Krishnamoorthi Democratic Illinois IL Nay Kuster Kuster Democratic New Hampshire NH Nay Kustoff Kustoff Republican Tennessee TN Yea LaHood LaHood Republican Illinois IL Yea LaLota LaLota Republican New York NY Yea LaMalfa LaMalfa Republican California CA Yea Lamborn Lamborn Republican Colorado CO Yea Landsman Landsman Democratic Ohio OH Nay Langworthy Langworthy Republican New York NY Yea Larsen (WA) Larsen (WA) Democratic Washington WA Nay Larson (CT) Larson (CT) Democratic Connecticut CT Nay Latta Latta Republican Ohio OH Yea LaTurner LaTurner Republican Kansas KS Yea Lawler Lawler Republican New York NY Yea Lee (CA) Lee (CA) Democratic California CA Nay Lee (FL) Lee (FL) Republican Florida FL Yea Lee (NV) Lee (NV) Democratic Nevada NV Nay Lee (PA) Lee (PA) Democratic Pennsylvania PA Nay Leger Fernandez Leger Fernandez Democratic New Mexico NM Nay Lesko Lesko Republican Arizona AZ Yea Letlow Letlow Republican Louisiana LA Yea Levin Levin Democratic California CA Nay Lieu Lieu Democratic California CA Nay Lofgren Lofgren Democratic California CA Nay Loudermilk Loudermilk Republican Georgia GA Yea Lucas Lucas Republican Oklahoma OK Not Voting Luetkemeyer Luetkemeyer Republican Missouri MO Yea Luna Luna Republican Florida FL Not Voting Luttrell Luttrell Republican Texas TX Yea Lynch Lynch Democratic Massachusetts MA Nay Mace Mace Republican South Carolina SC Yea Magaziner Magaziner Democratic Rhode Island RI Nay Malliotakis Malliotakis Republican New York NY Yea Mann Mann Republican Kansas KS Yea Manning Manning Democratic North Carolina NC Nay Massie Massie Republican Kentucky KY Yea Mast Mast Republican Florida FL Yea Matsui Matsui Democratic California CA Nay McBath McBath Democratic Georgia GA Not Voting McCarthy McCarthy Republican California CA Yea McCaul McCaul Republican Texas TX Not Voting McClain McClain Republican Michigan MI Yea McClellan McClellan Democratic Virginia VA Nay McClintock McClintock Republican California CA Yea McCollum McCollum Democratic Minnesota MN Nay McCormick McCormick Republican Georgia GA Yea McGarvey McGarvey Democratic Kentucky KY Nay McGovern McGovern Democratic Massachusetts MA Nay McHenry McHenry Republican North Carolina NC Yea Meeks Meeks Democratic New York NY Not Voting Menendez Menendez Democratic New Jersey NJ Nay Meng Meng Democratic New York NY Nay Meuser Meuser Republican Pennsylvania PA Yea Mfume Mfume Democratic Maryland MD Nay Miller (IL) Miller (IL) Republican Illinois IL Yea Miller (OH) Miller (OH) Republican Ohio OH Yea Miller (WV) Miller (WV) Republican West Virginia WV Yea Miller-Meeks Miller-Meeks Republican Iowa IA Yea Mills Mills Republican Florida FL Yea Molinaro Molinaro Republican New York NY Yea Moolenaar Moolenaar Republican Michigan MI Yea Mooney Mooney Republican West Virginia WV Yea Moore (AL) Moore (AL) Republican Alabama AL Yea Moore (UT) Moore (UT) Republican Utah UT Yea Moore (WI) Moore (WI) Democratic Wisconsin WI Nay Moran Moran Republican Texas TX Yea Morelle Morelle Democratic New York NY Nay Moskowitz Moskowitz Democratic Florida FL Nay Moulton Moulton Democratic Massachusetts MA Nay Mrvan Mrvan Democratic Indiana IN Nay Mullin Mullin Democratic California CA Nay Murphy Murphy Republican North Carolina NC Yea Nadler Nadler Democratic New York NY Nay Napolitano Napolitano Democratic California CA Nay Neal Neal Democratic Massachusetts MA Nay Neguse Neguse Democratic Colorado CO Nay Nehls Nehls Republican Texas TX Not Voting Newhouse Newhouse Republican Washington WA Yea Nickel Nickel Democratic North Carolina NC Nay Norcross Norcross Democratic New Jersey NJ Nay Norman Norman Republican South Carolina SC Yea Nunn (IA) Nunn (IA) Republican Iowa IA Yea Obernolte Obernolte Republican California CA Yea Ocasio-Cortez Ocasio-Cortez Democratic New York NY Nay Ogles Ogles Republican Tennessee TN Yea Omar Omar Democratic Minnesota MN Nay Owens Owens Republican Utah UT Yea Pallone Pallone Democratic New Jersey NJ Nay Palmer Palmer Republican Alabama AL Yea Panetta Panetta Democratic California CA Nay Pappas Pappas Democratic New Hampshire NH Nay Pascrell Pascrell Democratic New Jersey NJ Nay Payne Payne Democratic New Jersey NJ Nay Pelosi Pelosi Democratic California CA Nay Peltola Peltola Democratic Alaska AK Not Voting Pence Pence Republican Indiana IN Yea Perez Perez Democratic Washington WA Yea Perry Perry Republican Pennsylvania PA Yea Peters Peters Democratic California CA Nay Pettersen Pettersen Democratic Colorado CO Nay Pfluger Pfluger Republican Texas TX Yea Phillips Phillips Democratic Minnesota MN Nay Pingree Pingree Democratic Maine ME Not Voting Pocan Pocan Democratic Wisconsin WI Nay Porter Porter Democratic California CA Nay Posey Posey Republican Florida FL Yea Pressley Pressley Democratic Massachusetts MA Nay Quigley Quigley Democratic Illinois IL Nay Ramirez Ramirez Democratic Illinois IL Nay Raskin Raskin Democratic Maryland MD Nay Reschenthaler Reschenthaler Republican Pennsylvania PA Yea Rodgers (WA) Rodgers (WA) Republican Washington WA Yea Rogers (AL) Rogers (AL) Republican Alabama AL Yea Rogers (KY) Rogers (KY) Republican Kentucky KY Yea Rose Rose Republican Tennessee TN Yea Rosendale Rosendale Republican Montana MT Yea Ross Ross Democratic North Carolina NC Nay Rouzer Rouzer Republican North Carolina NC Yea Roy Roy Republican Texas TX Yea Ruiz Ruiz Democratic California CA Nay Ruppersberger Ruppersberger Democratic Maryland MD Nay Rutherford Rutherford Republican Florida FL Yea Ryan Ryan Democratic New York NY Nay Salazar Salazar Republican Florida FL Yea Salinas Salinas Democratic Oregon OR Nay Sánchez Sanchez Democratic California CA Nay Santos Santos Republican New York NY Yea Sarbanes Sarbanes Democratic Maryland MD Nay Scalise Scalise Republican Louisiana LA Yea Scanlon Scanlon Democratic Pennsylvania PA Nay Schakowsky Schakowsky Democratic Illinois IL Nay Schiff Schiff Democratic California CA Nay Schneider Schneider Democratic Illinois IL Nay Scholten Scholten Democratic Michigan MI Nay Schrier Schrier Democratic Washington WA Nay Schweikert Schweikert Republican Arizona AZ Yea Scott (VA) Scott (VA) Democratic Virginia VA Nay Scott, Austin Scott, Austin Republican Georgia GA Yea Scott, David Scott, David Democratic Georgia GA Nay Self Self Republican Texas TX Yea Sessions Sessions Republican Texas TX Yea Sewell Sewell Democratic Alabama AL Not Voting Sherman Sherman Democratic California CA Nay Sherrill Sherrill Democratic New Jersey NJ Nay Simpson Simpson Republican Idaho ID Yea Slotkin Slotkin Democratic Michigan MI Nay Smith (MO) Smith (MO) Republican Missouri MO Yea Smith (NE) Smith (NE) Republican Nebraska NE Yea Smith (NJ) Smith (NJ) Republican New Jersey NJ Yea Smith (WA) Smith (WA) Democratic Washington WA Nay Smucker Smucker Republican Pennsylvania PA Yea Sorensen Sorensen Democratic Illinois IL Nay Soto Soto Democratic Florida FL Nay Spanberger Spanberger Democratic Virginia VA Nay Spartz Spartz Republican Indiana IN Yea Stansbury Stansbury Democratic New Mexico NM Nay Stanton Stanton Democratic Arizona AZ Nay Stauber Stauber Republican Minnesota MN Yea Steel Steel Republican California CA Yea Stefanik Stefanik Republican New York NY Yea Steil Steil Republican Wisconsin WI Yea Steube Steube Republican Florida FL Yea Stevens Stevens Democratic Michigan MI Nay Stewart Stewart Republican Utah UT Not Voting Strickland Strickland Democratic Washington WA Nay Strong Strong Republican Alabama AL Yea Swalwell Swalwell Democratic California CA Nay Sykes Sykes Democratic Ohio OH Nay Takano Takano Democratic California CA Nay Tenney Tenney Republican New York NY Yea Thanedar Thanedar Democratic Michigan MI Nay Thompson (CA) Thompson (CA) Democratic California CA Nay Thompson (MS) Thompson (MS) Democratic Mississippi MS Nay Thompson (PA) Thompson (PA) Republican Pennsylvania PA Yea Tiffany Tiffany Republican Wisconsin WI Yea Timmons Timmons Republican South Carolina SC Yea Titus Titus Democratic Nevada NV Nay Tlaib Tlaib Democratic Michigan MI Nay Tokuda Tokuda Democratic Hawaii HI Nay Tonko Tonko Democratic New York NY Nay Torres (CA) Torres (CA) Democratic California CA Nay Torres (NY) Torres (NY) Democratic New York NY Not Voting Trahan Trahan Democratic Massachusetts MA Nay Trone Trone Democratic Maryland MD Not Voting Turner Turner Republican Ohio OH Yea Underwood Underwood Democratic Illinois IL Nay Valadao Valadao Republican California CA Yea Van Drew Van Drew Republican New Jersey NJ Yea Van Duyne Van Duyne Republican Texas TX Yea Van Orden Van Orden Republican Wisconsin WI Yea Vargas Vargas Democratic California CA Nay Vasquez Vasquez Democratic New Mexico NM Yea Veasey Veasey Democratic Texas TX Nay Velázquez Velazquez Democratic New York NY Not Voting Wagner Wagner Republican Missouri MO Yea Walberg Walberg Republican Michigan MI Yea Waltz Waltz Republican Florida FL Yea Wasserman Schultz Wasserman Schultz Democratic Florida FL Nay Waters Waters Democratic California CA Nay Watson Coleman Watson Coleman Democratic New Jersey NJ Nay Weber (TX) Weber (TX) Republican Texas TX Yea Webster (FL) Webster (FL) Republican Florida FL Yea Wenstrup Wenstrup Republican Ohio OH Yea Westerman Westerman Republican Arkansas AR Yea Wexton Wexton Democratic Virginia VA Nay Wild Wild Democratic Pennsylvania PA Nay Williams (GA) Williams (GA) Democratic Georgia GA Nay Williams (NY) Williams (NY) Republican New York NY Yea Williams (TX) Williams (TX) Republican Texas TX Yea Wilson (FL) Wilson (FL) Democratic Florida FL Nay Wilson (SC) Wilson (SC) Republican South Carolina SC Yea Wittman Wittman Republican Virginia VA Yea Womack Womack Republican Arkansas AR Yea Yakym Yakym Republican Indiana IN Yea Zinke Zinke Republican Montana MT Yea No data found 118 Contact Information Room H154, The Capitol Washington, DC 20515-6601 p: (202) 225-7000 For general inquiries: info.clerkweb@mail.house.gov For general technical support: techsupport.clerkweb@mail.house.gov Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Disclosures Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office Committee Information Committee Profiles Clerk Sites Bills This Week Biographical Directory Clerk Kids Committee Repository History, Art & Archives Office of the Chaplain Help & Resources FAQs Privacy Policy Site Map

---
snapshot_id: cf3beccf-77b9-59ad-ae8f-02142d7f531e
source_kind: public-record
url: https://www.congress.gov/bill/118th-congress/house-joint-resolution/126

Providing for congressional disapproval under chapter 8 of title 5, United States Code, of the rule submitted by the Federal Deposit Insurance Corporation relating to "Principles for Climate-Related Financial Risk Management for Large Financial Institutions". Policy area: Finance and Financial Sector Sponsor: Rep. Houchin, Erin [R-IN-9] Latest action: Placed on the Union Calendar, Calendar No. 517. Cosponsors: Rep. Hill, J. French [R-AR-2], Rep. Donalds, Byron [R-FL-19], Rep. Meuser, Daniel [R-PA-9], Rep. Sessions, Pete [R-TX-17], Rep. Huizenga, Bill [R-MI-4], Rep. Barr, Andy [R-KY-6] Actions: Placed on the Union Calendar, Calendar No. 517. Reported by the Committee on Financial Services. H. Rept. 118-619. Reported by the Committee on Financial Services. H. Rept. 118-619. Ordered to be Reported by the Yeas and Nays: 28 - 22. Committee Consideration and Mark-up Session Held Referred to the House Committee on Financial Services. Introduced in House Introduced in House [Congressional Bills 118th Congress] [From the U.S. Government Publishing Office] [H.J. Res. 126 Reported in House (RH)] <DOC> Union Calendar No. 517 118th CONGRESS 2d Session H. J. RES. 126 [Report No. 118-619] Providing for congressional disapproval under chapter 8 of title 5, United States Code, of the rule submitted by the Federal Deposit Insurance Corporation relating to ``Principles for Climate-Related Financial Risk Management for Large Financial Institutions''. _______________________________________________________________________ IN THE HOUSE OF REPRESENTATIVES April 5, 2024 Mrs. Houchin (for herself, Mr. Hill, and Mr. Donalds) submitted the following joint resolution; which was referred to the Committee on Financial Services July 30, 2024 Additional sponsors: Mr. Meuser, Mr. Sessions, Mr. Huizenga, and Mr. Barr July 30, 2024 Committed to the Committee of the Whole House on the State of the Union and ordered to be printed _______________________________________________________________________ JOINT RESOLUTION Providing for congressional disapproval under chapter 8 of title 5, United States Code, of the rule submitted by the Federal Deposit Insurance Corporation relating to ``Principles for Climate-Related Financial Risk Management for Large Financial Institutions''. Resolved by the Senate and House of Representatives of the United States of America in Congress assembled, That Congress disapproves the rule submitted by the Federal Deposit Insurance Corporation relating to ``Principles for Climate-Related Financial Risk Management for Large Financial Institutions'' (88 Fed. Reg. 74183; published October 30, 2023), and such rule shall have no force or effect. Union Calendar No. 517 118th CONGRESS 2d Session H. J. RES. 126 [Report No. 118-619] _______________________________________________________________________ JOINT RESOLUTION Providing for congressional disapproval under chapter 8 of title 5, United States Code, of the rule submitted by the Federal Deposit Insurance Corporation relating to ``Principles for Climate-Related Financial Risk Management for Large Financial Institutions''. _______________________________________________________________________ July 30, 2024 Committed to the Committee of the Whole House on the State of the Union and ordered to be printed

---
snapshot_id: 859240a2-8b38-57c8-ae5f-710413fe1776
source_kind: public-record
url: https://www.congress.gov/bill/118th-congress/house-bill/1435

Preserving Choice in Vehicle Purchases Act Policy area: Environmental Protection Sponsor: Rep. Joyce, John [R-PA-13] Latest action: Received in the Senate and Read twice and referred to the Committee on Environment and Public Works. Preserving Choice in Vehicle Purchases Act This bill modifies the waiver process under the Clean Air Act related to state emission control standards for new motor vehicles (or new motor vehicle engines). Under current law, states are preempted from adopting or enforcing emission control standards for new motor vehicles (or new motor vehicle engines) unless the Environmental Protection Agency (EPA) provides a waiver authorizing a state to adopt such standards if certain requirements are met. The bill provides that state standards that directly or indirectly limit the sale or use of new motor vehicles with internal combustion engines are not eligible for waivers. The bill also prohibits the EPA from determining that any state standards amended after the bill's enactment are within the scope of an existing waiver. Additionally, the bill requires the EPA to revoke waivers granted between January 1, 2022, and the date of enactment of this bill if the standards directly or indirectly limit the sale or use of new motor vehicles with internal combustion engines. Preserving Choice in Vehicle Purchases Act This bill modifies the waiver process under the Clean Air Act related to state emission control standards for new motor vehicles (or new motor vehicle engines). Under current law, states are preempted from adopting or enforcing emission control standards for new motor vehicles (or new motor vehicle engines) unless the Environmental Protection Agency (EPA) provides a waiver authorizing a state to adopt such standards if certain requirements are met. The bill provides that state standards that directly or indirectly limit the sale or use of new motor vehicles with internal combustion engines are not eligible for waivers. The bill also prohibits the EPA from determining that any state standards amended after the bill's enactment are within the scope of an existing waiver. Additionally, the bill requires the EPA to revoke waivers granted between January 1, 2022, and the date of enactment of this bill if the standards directly or indirectly limit the sale or use of new motor vehicles with internal combustion engines. Preserving Choice in Vehicle Purchases Act This bill modifies the waiver process under the Clean Air Act related to state emission control standards for new motor vehicles (or new motor vehicle engines). Under current law, states are preempted from adopting or enforcing emission control standards for new motor vehicles (or new motor vehicle engines) unless the Environmental Protection Agency (EPA) provides a waiver authorizing a state to adopt such standards if certain requirements are met. The bill provides that state standards that directly or indirectly limit the sale or use of new motor vehicles with internal combustion engines are not eligible for waivers. The bill also prohibits the EPA from determining that any state standards amended after the bill's enactment are within the scope of an existing waiver. Additionally, the bill requires the EPA to revoke waivers granted between January 1, 2022, and the date of enactment of this bill if the standards directly or indirectly limit the sale or use of new motor vehicles with internal combustion engines. Cosponsors: Rep. Latta, Robert E. [R-OH-5], Rep. Bilirakis, Gus M. [R-FL-12], Rep. Obernolte, Jay [R-CA-23], Rep. Emmer, Tom [R-MN-6], Rep. Stefanik, Elise M. [R-NY-21], Rep. Curtis, John R. [R-UT-3], Rep. Posey, Bill [R-FL-8], Rep. Balderson, Troy [R-OH-12], Rep. Reschenthaler, Guy [R-PA-14], Rep. Pfluger, August [R-TX-11], Rep. Roy, Chip [R-TX-21], Rep. Miller, Max L. [R-OH-7], Rep. Van Duyne, Beth [R-TX-24], Rep. Finstad, Brad [R-MN-1], Rep. Nehls, Troy E. [R-TX-22], Rep. Mast, Brian J. [R-FL-21], Rep. Pence, Greg [R-IN-6], Rep. Gooden, Lance [R-TX-5], Rep. Armstrong, Kelly [R-ND-At Large], Rep. Johnson, Bill [R-OH-6], Rep. Jackson, Ronny [R-TX-13], Rep. Issa, Darrell E. [R-CA-48], Rep. Boebert, Lauren [R-CO-3], Rep. Guest, Michael [R-MS-3], Rep. Ellzey, Jake [R-TX-6], Rep. Weber, Randy K., Sr. [R-TX-14], Rep. Smith, Christopher H. [R-NJ-4], Rep. Hudson, Richard [R-NC-9], Rep. Crenshaw, Dan [R-TX-2], Rep. Carter, Earl L. "Buddy" [R-GA-1], Rep. Smith, Jason [R-MO-8], Rep. Bost, Mike [R-IL-12], Rep. Harshbarger, Diana [R-TN-1], Rep. Feenstra, Randy [R-IA-4], Rep. Williams, Roger [R-TX-25], Rep. Donalds, Byron [R-FL-19], Rep. Owens, Burgess [R-UT-4], Rep. Walberg, Tim [R-MI-5], Rep. Miller-Meeks, Mariannette [R-IA-1], Rep. Scott, Austin [R-GA-8], Rep. Griffith, H. Morgan [R-VA-9], Rep. McCormick, Richard [R-GA-6], Rep. Bice, Stephanie I. [R-OK-5], Rep. Stauber, Pete [R-MN-8], Rep. Allen, Rick W. [R-GA-12], Rep. LaMalfa, Doug [R-CA-1], Rep. Hern, Kevin [R-OK-1], Rep. Kelly, Mike [R-PA-16], Rep. LaTurner, Jake [R-KS-2], Rep. Duncan, Jeff [R-SC-3], Rep. Turner, Michael R. [R-OH-10], Rep. Burgess, Michael C. [R-TX-26], Rep. Wenstrup, Brad R. [R-OH-2], Rep. Mann, Tracey [R-KS-1], Rep. Smucker, Lloyd [R-PA-11], Rep. Perry, Scott [R-PA-10], Rep. Carey, Mike [R-OH-15], Rep. Wittman, Robert J. [R-VA-1], Rep. Tenney, Claudia [R-NY-24], Rep. Steel, Michelle [R-CA-45], Rep. Hunt, Wesley [R-TX-38], Rep. Edwards, Chuck [R-NC-11], Rep. Fulcher, Russ [R-ID-1], Rep. Bucshon, Larry [R-IN-8], Rep. Fischbach, Michelle [R-MN-7], Rep. Comer, James [R-KY-1], Rep. McHenry, Patrick T. [R-NC-10], Rep. De La Cruz, Monica [R-TX-15], Rep. Lesko, Debbie [R-AZ-8], Rep. Johnson, Dusty [R-SD-At Large], Rep. Estes, Ron [R-KS-4], Rep. Yakym, Rudy [R-IN-2], Rep. Carl, Jerry L. [R-AL-1], Rep. Grothman, Glenn [R-WI-6], Rep. Van Orden, Derrick [R-WI-3], Rep. Rouzer, David [R-NC-7], Rep. Meuser, Daniel [R-PA-9], Rep. Kelly, Trent [R-MS-1], Rep. Ezell, Mike [R-MS-4], Rep. Calvert, Ken [R-CA-41], Rep. Simpson, Michael K. [R-ID-2], Rep. McCaul, Michael T. [R-TX-10], Rep. Johnson, Mike [R-LA-4] Actions: Received in the Senate and Read twice and referred to the Committee on Environment and Public Works. Motion to reconsider laid on the table Agreed to without objection. On passage Passed by the Yeas and Nays: 222 - 190 (Roll no. 391). (text: CR H4318) Passed/agreed to in House: On passage Passed by the Yeas and Nays: 222 - 190 (Roll no. 391). (text: CR H4318) On motion to recommit Failed by the Yeas and Nays: 193 - 212 (Roll no. 390). The previous question on the motion to recommit was ordered pursuant to clause 2(b) of rule XIX. Mr. Levin moved to recommit to the Committee on Energy and Commerce. (text: CR H4326) The previous question was ordered pursuant to the rule. DEBATE - The House proceeded with one hour of debate on H.R. 1435. Rule provides for consideration of H.R. 1435 with 1 hour of general debate. Motion to recommit allowed. Bill is closed to amendments. Considered under the provisions of rule H. Res. 681. (consideration: CR H4318-4328) Rule H. Res. 681 passed House. Rules Committee Resolution H. Res. 681 Reported to House. Rule provides for consideration of H.R. 1435 with 1 hour of general debate. Motion to recommit allowed. Bill is closed to amendments. Rules Committee Resolution H. Res. 680 Reported to House. Rule provides for consideration of H.R. 1435 and H.R. 4365. The resolution provides for consideration of H.R. 1435 under a closed rule and H.R. 4365 under a structured rule. The rule provides for one hour of general debate on each measure with one motion to recommit allowed. Placed on the Union Calendar, Calendar No. 133. [Congressional Bills 118th Congress] [From the U.S. Government Publishing Office] [H.R. 1435 Referred in Senate (RFS)] <DOC> 118th CONGRESS 1st Session H. R. 1435 _______________________________________________________________________ IN THE SENATE OF THE UNITED STATES September 18, 2023 Received; read twice and referred to the Committee on Environment and Public Works _______________________________________________________________________ AN ACT To amend the Clean Air Act to prevent the elimination of the sale of internal combustion engines. Be it enacted by the Senate and House of Representatives of the United States of America in Congress assembled, SECTION 1. SHORT TITLE. This Act may be cited as the ``Preserving Choice in Vehicle Purchases Act''. SEC. 2. STATE STANDARDS. (a) Amendments.--Section 209(b) of the Clean Air Act (42 U.S.C. 7543(b)) is amended-- (1) in paragraph (1)-- (A) in subparagraph (B), by striking the ``or'' at the end; (B) in subparagraph (C), by striking ``part.'' and inserting ``part, or''; and (C) by adding at the end the following: ``(D) such State standards directly or indirectly limit the sale or use of new motor vehicles with internal combustion engines, as such term is defined in section 63.9375 of title 40, Code of Federal Regulations, as in effect January 1, 2023.''; and (2) by adding at the end the following: ``(4) The Administrator may not determine that any State standards amended after the date of enactment of this paragraph are within the scope of a waiver granted under paragraph (1) before the date of enactment of this paragraph.''. (b) Effect on Certain Existing Waivers.--The Administrator of the Environmental Protection Agency shall revoke a waiver granted under section 209(b) of the Clean Air Act (42 U.S.C. 7543(b)) during the period that begins on January 1, 2022, and ends on the date of enactment of this Act if the Administrator finds that such waiver does not comply with subparagraph (D) of section 209(b)(1) of the Clean Air Act (42 U.S.C. 7543(b)(1)), as added by this Act. Passed the House of Representatives September 14, 2023. Attest: KEVIN F. MCCUMBER, Clerk.