You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-houchin-education/labels/coder-1.json. Write JSON only, matching
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

politician_id: 68568faf-1e0f-4ca2-89d9-bda625665712  office_id: b343becb-af7d-4a19-a6a1-2e5df210f344
Erin Houchin — U.S. House of Representatives - Indiana 9th Congressional District, Indiana (seated, level: federal)
Current term: 2023-01-03 (precision: day) to present

## Topics (served ladder text — code against these words only)

### topic_key: education-curriculum
topic_id: 6c43fdec-d084-415d-a15d-d78f48d4fb34  served_revision_id: 2146e080-bd5e-4e1e-8a51-fcc1b44af916
Question: How should schools handle contested topics like race, gender, and history in what they teach?
Evidence basis at this seat's level (federal): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Require lessons that center race, gender, and social justice as themes across the curriculum
  2. Teach an honest account of racism, injustice, and diverse identities as part of the core curriculum
  3. Present contested social and historical topics as open questions, giving competing viewpoints equal weight
  4. Keep the curriculum focused on core academics and leave contested social topics to families
  5. Prohibit lessons on race, gender, or sexuality that the community considers divisive or age-inappropriate

#### Annex

# education-curriculum — served revision 2146e080-bd5e-4e1e-8a51-fcc1b44af916 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should schools handle contested topics like race, gender, and history in what they
teach?"

**Orientation:** off-axis. Both ends are mandates: rung 1 **requires** lessons on these themes and
rung 5 **prohibits** some of them; rung 4 is the least prescriptive. The rungs order **how much room
the curriculum gives these topics**, from centring them everywhere to forbidding them — not the
amount of government action.

**Levels with a lever:** local, school, state. The lever is state standards
and statute, and the school board's curriculum adoption and instruction policy. A city or county
council holds no curriculum lever unless it runs the school system _(proposed)_.

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "academic standards", "social studies standards", "ethnic studies", "culturally
responsive", "divisive concepts", "critical race theory" (CRT), "prohibited concepts", "parental
rights in education", "age-appropriate", "instructional materials", "curriculum transparency",
"opt-out", "diverse and contending perspectives".

1. **"Require lessons that center race, gender, and social justice as themes across the curriculum"**
   - Means: every subject must build its lessons around race, gender and social justice.
   - Operative clauses: [a] a requirement; [b] race, gender **and** social justice as central themes;
     [c] across the curriculum, not in one course or unit.
   - Establishing evidence looks like: a statute, standard or board policy that requires these themes
     to be integrated in all or most subjects; own words calling for that.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because a required **course** (for example an ethnic-studies
     graduation course) adds the content in one place. It does not meet [c] → rung 2 territory, and
     it needs rung 2's evidence _(proposed)_.

2. **"Teach an honest account of racism, injustice, and diverse identities as part of the core
   curriculum"**
   - Means: the required curriculum teaches the history of racism and injustice, and diverse
     identities, as fact, not as an optional extra.
   - Operative clauses: [a] content on racism, injustice and diverse identities; [b] in the core
     (required) curriculum; [c] taught as an honest account, not as an open question.
   - Establishing evidence looks like: a standard, statute or adopted course that requires this
     content in core subjects. To exclude rung 1, the passage must not require the themes across the
     whole curriculum; to exclude rung 3, it must not order equal weight for competing views.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a mandate to teach **one historical subject** (for example
     a required unit on a named historical injustice) points toward this rung but is narrower than "racism, injustice, and diverse
     identities" → `direction-only` (V4.2 "Broader than the instrument").

3. **"Present contested social and historical topics as open questions, giving competing viewpoints
   equal weight"**
   - Means: teachers present these topics as unsettled and give each side the same weight.
   - Operative clauses: [a] contested topics presented as open questions; [b] competing viewpoints
     given equal weight.
   - Establishing evidence looks like: a "balanced perspectives" provision — teachers who discuss a
     contested topic must present it from competing perspectives without favouring one.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because one act often carries a balance clause **and** a list of
     prohibited concepts. Code the provision the passage relies on. An act that prohibits named
     lessons is rung 5 territory when rung 5's clauses are met; a balance clause beside the
     prohibition does not move it to rung 3. Rung 3 needs an instrument or own words that ask for
     balance **instead of** a ban _(proposed)_.

4. **"Keep the curriculum focused on core academics and leave contested social topics to families"**
   - Means: schools teach core academic subjects and do not teach contested social topics; families
     deal with them at home.
   - Operative clauses: [a] focus on core academics; [b] contested social topics left to families.
   - Establishing evidence looks like: own words that state both clauses; a policy that removes
     contested social topics from instruction **without** a prohibition list (a prohibition is
     rung 5).
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because both keep topics out. Rung 5 forbids named lessons; rung 4
     does not ask for a ban. A ban → rung 5, not rung 4.
   - "Back to basics" or "focus on reading and math" alone meets [a] only → `compound-partial`.

5. **"Prohibit lessons on race, gender, or sexuality that the community considers divisive or
   age-inappropriate"**
   - Means: some lessons on race, gender or sexuality are forbidden because they are judged divisive
     or not suitable for the students' age.
   - Operative clauses: [a] a prohibition on lessons; [b] on race, gender **or** sexuality (one is
     enough); [c] because they are divisive or age-inappropriate.
   - Establishing evidence looks like: operative text that forbids instruction on named concepts, or
     on gender identity or sexual orientation in named grades.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - "The community" is the public acting through its elected body: a state statute's own list of
     prohibited concepts meets it, as does a board policy. The text must still prohibit the lessons
     and give a divisiveness or age reason _(ruled 2026-10-01)_.

**Hard cases:**
- **State law and school boards.** A state law that itself forbids or requires instruction in every
  public school states the rule → `on-question`. A law that only moves the decision (for example
  "only the state board may adopt …", or "a district shall not require a teacher to …" with no rule
  on what is taught) decides which level decides → `adjacent` (V2, H12) _(ruled 2026-10-01)_ A state law is the legislator's act, not a school-board member's..
- **Curriculum transparency** (posting materials online, parent review of materials) and
  **opt-out** rights → `adjacent`. They let parents see or decline a lesson; they do not set what
  is taught _(proposed)_.
- **Sex-education rules** (abstinence, consent, opt-in) → `adjacent` unless the operative text
  forbids or requires lessons on gender or sexuality as such _(proposed)_.
- **Book and library challenges** → `adjacent` (they have their own topic).
- **Budget or omnibus votes** with a curriculum item → V4 `multi-subject`.
- **A study, task force or standards review** → `study-directive`.


### topic_key: education-library-books
topic_id: 1fcff1e8-c913-4d97-91da-1145952d7c65  served_revision_id: f480f827-cb1f-4a2e-83cd-bef8763948b8
Question: How should schools handle challenges to books in libraries and classrooms?
Evidence basis at this seat's level (federal): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Keep every book available and let professional librarians and educators curate the collection
  2. Keep challenged books available to all, while letting parents limit what their own child can borrow
  3. Remove a challenged book only if a review committee of educators and parents finds it unsuitable
  4. Pull any book a parent challenges until it has been reviewed
  5. Remove any book a parent or community member reports as inappropriate, for all students

#### Annex

# education-library-books — served revision f480f827-cb1f-4a2e-83cd-bef8763948b8 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should schools handle challenges to books in libraries and classrooms?"

**Orientation:** standard. Rung 1 keeps every book and leaves selection to professionals; rung 5
removes a book on any report. The rungs order **what a challenge does to access**: nothing, a limit
for one child, removal after a review finding, removal during review, removal on report.

**Levels with a lever:** local, school, state. The lever is the school board's
reconsideration policy and the state statute that sets the challenge process. A city or county
council governs public libraries, not school libraries → `adjacent` unless the act covers school
collections _(proposed)_.

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "reconsideration policy", "request for reconsideration", "challenged material",
"review committee", "media specialist", "collection development", "weeding", "harmful to minors",
"obscene", "sexual conduct", "freedom to read", "Library Bill of Rights", "parental opt-out",
"restricted list", "classroom library".

1. **"Keep every book available and let professional librarians and educators curate the
   collection"**
   - Means: a challenge does not remove a book; trained librarians and educators decide what the
     collection holds.
   - Operative clauses: [a] challenged books stay available; [b] selection and removal stay with
     professional librarians and educators.
   - Establishing evidence looks like: own words that reject removal on challenge and leave
     selection to professionals; an act that forbids removing books because of their ideas or
     content **and** places selection with professional staff. Routine weeding by professionals
     (worn, outdated) does not contradict [a] _(proposed)_.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a "freedom to read" act often forbids removal for
     viewpoint but keeps a review process that can remove on other grounds. If a review can still
     remove a challenged book → not [a]; code the review process (rung 3 or 4) _(proposed)_.
   - [a] is an "every" clause: an act that names no removal rule has not said books stay (V4.2
     "Silence is not a clause").

2. **"Keep challenged books available to all, while letting parents limit what their own child can
   borrow"**
   - Means: challenged books stay on the shelf for everyone, and a parent may restrict only their
     own child's borrowing.
   - Operative clauses: [a] challenged books stay available to all; [b] a parent may limit their
     own child's borrowing. Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a policy with a parent-restriction (opt-out) list **and** a
     rule that a challenge does not remove the book for others.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1 because both keep books. A parent-restriction list meets [b];
     rung 1 has no parent limit.
   - A parent-restriction list beside a review that can remove books for everyone → not [a]; code
     the review process _(proposed)_.

3. **"Remove a challenged book only if a review committee of educators and parents finds it
   unsuitable"**
   - Means: a challenged book stays until a committee of educators and parents reviews it and finds
     it unsuitable; only that finding removes it.
   - Operative clauses: [a] removal only after a review finds the book unsuitable; [b] the reviewer
     is a committee of educators **and** parents. Compound: one side only → `compound-partial`
     (V4.2).
   - Establishing evidence looks like: a reconsideration policy or statute that requires a review
     finding before removal **and** names a committee whose members include educators and parents.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - A process that removes a book after a review finding, but names a different reviewer (the
     board alone, an administrator, a librarian, a state agency) or does not say who reviews → [a]
     only → BLANK `compound-partial`.
   - A committee that recommends while the board decides meets [b] when **the board may remove a book
     only on the committee's finding** (it may keep a book against the committee). If the board can
     remove against the committee's recommendation, [b] fails → `compound-partial` _(ruled 2026-10-01)_.
   - Commonly confused with rung 4 because both review. If the book is pulled **during** the review,
     it is rung 4, not rung 3.

4. **"Pull any book a parent challenges until it has been reviewed"**
   - Means: a parent's challenge removes the book at once, for the time the review takes.
   - Operative clauses: [a] any parent challenge triggers removal; [b] the removal lasts until the
     review ends.
   - Establishing evidence looks like: operative text that removes or restricts a challenged book
     from the filing of the challenge until the review decides.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - [a] is an "any" clause. Removal pending review only for some challenges (for example only for a
     named content category) does not meet [a] → `direction-only` _(proposed)_.
   - A policy silent on access during review does not reach rung 4 (V4.2).

5. **"Remove any book a parent or community member reports as inappropriate, for all students"**
   - Means: a report alone removes the book for every student; no review finding is needed.
   - Operative clauses: [a] a report removes the book, with no review finding; [b] a parent or a
     community member may report; [c] the removal applies to all students.
   - Establishing evidence looks like: operative text that removes a reported book without a review
     finding.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because both remove on challenge. Rung 4's removal ends when a
     review decides; rung 5's does not depend on a review.

**Hard cases:**
- **Content standards.** An act that orders removal of every book meeting a statutory content test
  ("harmful to minors", described sexual conduct) sets **what** may be removed, not what a challenge
  does. Code the process it uses to decide (rung 3, 4 or 5); a content test with no process named →
  `direction-only` _(proposed)_.
- **State law and school boards.** A state law that sets the challenge process for every district
  states the rule → `on-question`. A law that only decides which body hears challenges (state board
  or district) → `adjacent` (V2, H12) _(ruled 2026-10-01)_ A state law is the legislator's act, not a school-board member's..
- **Removing a legal defence** for librarians or teachers (criminal liability for distributing
  material) → `direction-only` _(proposed)_.
- **Ratings, labels, vendor rules and checkout-record access** for parents → `adjacent` _(proposed)_.
- **Assigned texts in a course** are in scope ("classrooms"). A curriculum standard that names no
  challenge process → `adjacent` (curriculum has its own topic).
- **A vote on one book.** A board vote to keep or remove one title shows the person's act on that
  title, not the process → `direction-only`, unless the vote adopts or applies a stated process
  _(proposed)_.
- **Budget or omnibus votes** → V4 `multi-subject`.


### topic_key: education-gender-identity
topic_id: d96f987e-3404-4667-909d-5889116ba6e5  served_revision_id: 89f9d4a5-362e-4470-9529-46d4826fdeb9
Question: What should schools do when a student uses a different name or gender identity at school than at home?
Evidence basis at this seat's level (federal): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Use the student's chosen name and pronouns, and keep their gender identity from parents unless the student agrees to share it
  2. Use the student's chosen name and pronouns, and tell parents only if they directly ask
  3. Tell parents when a student changes their name or gender at school, unless staff believe it would put the student in danger
  4. Require staff to notify parents whenever a student asks to be treated as a different gender at school
  5. Require written parental permission before staff use a student's chosen name or pronouns

#### Annex

# education-gender-identity — served revision 89f9d4a5-362e-4470-9529-46d4826fdeb9 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "What should schools do when a student uses a different name or gender identity at
school than at home?"

**Orientation:** standard. Rung 1 gives the student's wish the most weight against disclosure to
parents; rung 5 gives parents a veto before staff act. The rungs order **who controls disclosure and
consent**: the student, the parent on request, the school with a safety exception, the school with
no exception, the parent in advance.

**Levels with a lever:** school, state. The lever is the school board's
policy and the state statute or state-board rule. A city or county council holds none →
own words only there _(proposed)_.

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal, local (codebook V2 "No-lever level").

**Synonyms:** "chosen name", "preferred name", "pronouns", "social transition", "gender support
plan", "parental notification", "parental rights", "forced outing", "parental consent", "safety
exception", "education records", "student privacy".

1. **"Use the student's chosen name and pronouns, and keep their gender identity from parents unless
   the student agrees to share it"**
   - Means: staff use the student's name and pronouns, and do not tell parents unless the student
     consents — even when a parent asks.
   - Operative clauses: [a] staff use the chosen name and pronouns; [b] no disclosure to parents
     without the student's consent. Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a policy or statute that requires staff to use the chosen
     name **and** forbids disclosure without the student's consent.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both use the name. Rung 1 keeps the identity from a parent
     who asks; rung 2 answers a parent who asks. A policy that does not say what happens when a
     parent asks cannot separate them → `direction-only`.

2. **"Use the student's chosen name and pronouns, and tell parents only if they directly ask"**
   - Means: staff use the student's name and pronouns, do not notify parents on their own, but answer
     truthfully when a parent asks.
   - Operative clauses: [a] staff use the chosen name and pronouns; [b] no notice unless a parent
     asks; [c] disclosure when a parent asks. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a policy with no notification duty that releases the
     information on a parent's request.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - A general parent right to see education records does not by itself meet [b] or [c]; it does not
     say what staff do about name or gender → `adjacent` _(proposed)_.

3. **"Tell parents when a student changes their name or gender at school, unless staff believe it
   would put the student in danger"**
   - Means: the school tells parents by default, but staff may hold back when they believe telling
     would endanger the student.
   - Operative clauses: [a] a notification duty; [b] a safety exception that staff apply.
   - Establishing evidence looks like: a notification statute or policy with an exception for a
     belief that disclosure would cause abuse, neglect or harm.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

4. **"Require staff to notify parents whenever a student asks to be treated as a different gender at
   school"**
   - Means: staff must notify parents every time, with no safety exception.
   - Operative clauses: [a] a notification duty; [b] it applies whenever a student asks.
   - Establishing evidence looks like: operative text that makes notification a duty on every such
     request and carries no safety exception. A duty stated for every request is a stated rule, not
     silence.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 when the safety exception is in another section of the same act or
     in a cross-referenced law. Read the whole act: an exception anywhere in it → rung 3.
   - Commonly confused with rung 5 when the act also requires consent. Notice only → rung 4; consent
     before use → rung 5.

5. **"Require written parental permission before staff use a student's chosen name or pronouns"**
   - Means: staff may not use the chosen name or pronouns until a parent gives written permission.
   - Operative clauses: [a] parental permission; [b] in writing; [c] before staff use the name or
     pronouns.
   - Establishing evidence looks like: operative text that requires written parental consent for
     the use of a different name or pronouns.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Permission that need not be written meets [a] and [c] only → `compound-partial` _(proposed)_.
   - A rule that forbids staff to use a name or pronouns that do not match sex **even with** parental
     permission is past this rung, and no rung states it → `direction-only` _(proposed)_.

**Hard cases:**
- **A law that forbids school boards to adopt a notification policy** (or a law that forbids them to
  adopt a confidentiality policy) removes one side's rule statewide, but it does not itself require
  the other side's practice → `on-question` but `direction-only` (V2 "Refined 2026-09-26") _(proposed)_.
- **Teacher speech protections** (a teacher may not be required to use a pronoun) → `adjacent`
  _(proposed)_.
- **Sports, restrooms and locker rooms** → `adjacent` (sports has its own topic).
- **Curriculum on gender identity** → `adjacent` (curriculum has its own topic).
- **Federal law** (education-records rights, Title IX rules) is not a role here; a state or school
  passage that only cites it → `adjacent` unless it states the school's own rule _(proposed)_.
- **Budget or omnibus votes** → V4 `multi-subject`.


### topic_key: education-equity-programs
topic_id: 66b389c7-86fc-45e9-bf34-964bb747f27b  served_revision_id: 23d87824-d25c-4b9a-8b13-fb2799d75661
Question: How should schools address gaps in achievement and opportunity between groups of students?
Evidence basis at this seat's level (federal): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Fund dedicated equity offices and staff to close gaps between student groups
  2. Require equity training for staff and set measurable goals to close gaps between groups
  3. Measure results for each student group and steer extra support to those falling behind
  4. Offer the same supports to every struggling student, without grouping them by race or identity
  5. Eliminate equity programs, training, and staff from the district

#### Annex

# education-equity-programs — served revision 23d87824-d25c-4b9a-8b13-fb2799d75661 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should schools address gaps in achievement and opportunity between groups of
students?"

**Orientation:** standard. Rung 1 is the most dedicated institutional effort (funded offices and
staff), rung 5 removes equity programmes. The rungs order **the mechanism used for gaps between
groups**: offices, training and goals, measurement and targeted support, the same support for every
struggling student, nothing.

**Levels with a lever:** local, school, state. The lever is the school board's
budget, staffing and policy, and state statute (mandates, bans, accountability rules). A city or
county council holds a lever only where it funds or runs the schools _(proposed)_.

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "equity office", "chief equity officer", "diversity, equity and inclusion" (DEI),
"achievement gap", "opportunity gap", "subgroup", "disaggregated data", "equity plan", "implicit-bias
training", "culturally responsive training", "targeted support", "multi-tiered system of supports"
(MTSS), "Title I".

1. **"Fund dedicated equity offices and staff to close gaps between student groups"**
   - Means: the district pays for an office and staff whose job is to close gaps between groups.
   - Operative clauses: [a] a dedicated equity office or staff; [b] funded; [c] with the purpose of
     closing gaps between groups.
   - Establishing evidence looks like: a single-item vote or resolution that creates or funds an
     equity office or position; own words calling for one.
   - Levels that hold a lever: school; state (a mandate on districts).
   - Known chair-shaped instruments: _(none on file)_.
   - A line item inside the annual budget → V4 `multi-subject`.

2. **"Require equity training for staff and set measurable goals to close gaps between groups"**
   - Means: staff must take equity training, and the district sets measurable targets for closing
     gaps.
   - Operative clauses: [a] required equity training for staff; [b] measurable gap-closing goals.
     Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a policy or statute that requires both.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1 because an equity plan often has both. Funding a dedicated office
     → rung 1; training and goals with no dedicated office → rung 2 _(proposed)_.
   - Commonly confused with rung 3 because goals and measurement look alike. A goal is a target;
     rung 3 is measurement plus support, with no training clause.

3. **"Measure results for each student group and steer extra support to those falling behind"**
   - Means: the district reports results by group and sends extra help to the groups whose results
     lag.
   - Operative clauses: [a] results measured for each student group; [b] extra support steered to
     groups that fall behind. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: an accountability rule that both reports by subgroup and
     directs support or intervention to the lagging groups.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Subgroup **reporting** alone (a common state or federal requirement) meets [a] only →
     `compound-partial`.
   - A funding weight for low-income or English-learner students steers money by category, not by
     measured results → `direction-only`, unless the act ties the support to the group's measured
     results. It is not rung 4 either: a weight treats groups differently _(ruled 2026-10-01)_.

4. **"Offer the same supports to every struggling student, without grouping them by race or
   identity"**
   - Means: help goes to each student who struggles, by individual need, and not by group.
   - Operative clauses: [a] supports for every struggling student by need; [b] no grouping by race
     or identity.
   - Establishing evidence looks like: own words or a policy that states both. [b] is an absence
     clause: the instrument must say it, for example by forbidding race- or identity-based
     eligibility for support (V4.2 "Silence is not a clause").
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because a ban on group-based programmes often comes with a
     closure of equity offices. Rung 4 keeps support for struggling students; a ban that ends
     programmes and names no support for struggling students → rung 5 territory _(proposed)_.

5. **"Eliminate equity programs, training, and staff from the district"**
   - Means: the district ends its equity programmes, its equity training and its equity staff.
   - Operative clauses: [a] programmes ended; [b] training ended; [c] staff ended. Compound: some
     only → `compound-partial` _(proposed)_.
   - Establishing evidence looks like: a board resolution or statute that ends all three; own words
     calling for that.
   - Levels that hold a lever: school; state (a statewide ban that binds every district).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **State law and school boards.** A state law that bans (or requires) equity offices, training or
  programmes in every district states the rule → `on-question`. A law that only moves the decision
  to another body → `adjacent` (V2, H12) _(ruled 2026-10-01)_ A state law is the legislator's act, not a school-board member's..
- **Admissions to selective schools or programmes** (test-based, lottery, geographic) → `adjacent`
  _(proposed)_.
- **Curriculum content on race or identity** → `adjacent` (curriculum has its own topic).
- **Discipline-disparity rules** (limits on suspensions) → `adjacent` _(proposed)_.
- **Study, audit or task force** on gaps → `study-directive`.
- **Annual budget votes** → V4 `multi-subject`.


### topic_key: education-school-police
topic_id: 15d7e730-119b-43a2-a351-1efb7352b86b  served_revision_id: d81d7662-3c68-425c-a5c6-ca0717384a9e
Question: What role should police officers play in schools?
Evidence basis at this seat's level (federal): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Remove police officers from schools and rely on counselors and mental health staff
  2. Keep officers out of schools and call them only when a serious crime occurs
  3. Bring in a shared or part-time officer with a limited, clearly defined role
  4. Place a dedicated officer in every school for safety, but bar them from routine discipline
  5. Place an officer in every school with authority to handle discipline and make arrests on campus

#### Annex

# education-school-police — served revision d81d7662-3c68-425c-a5c6-ca0717384a9e (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "What role should police officers play in schools?"

**Orientation:** standard. Rung 1 removes officers from schools; rung 5 puts an officer in every
school with discipline and arrest authority. The rungs order **how much police presence and authority
schools have**.

**Levels with a lever:** local, school, state. The lever is the school board's
contract with a police agency (or its own district police), the city or county council that funds
and staffs the officers, and state statute (mandates, grants, limits on officers' role).

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "school resource officer" (SRO), "school safety officer", "school police department",
"memorandum of understanding" (MOU), "school-based law enforcement", "police-free schools",
"counselors not cops", "school-to-prison pipeline", "armed guard", "guardian programme".

1. **"Remove police officers from schools and rely on counselors and mental health staff"**
   - Means: schools have no police officers; counselors and mental health staff do the work instead.
   - Operative clauses: [a] officers removed; [b] reliance on counselors and mental health staff.
     Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a motion that ends the officer contract **and** moves the money
     or the duties to counselors or mental health staff; own words that state both.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both remove officers. A vote that only ends the contract
     separates neither rung → `direction-only`.

2. **"Keep officers out of schools and call them only when a serious crime occurs"**
   - Means: no officer is stationed in schools; police come only when a serious crime happens.
   - Operative clauses: [a] no officers stationed in schools; [b] police called only for serious
     crime. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a policy that ends stationed officers **and** sets a protocol
     that limits police calls to serious crimes.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.

3. **"Bring in a shared or part-time officer with a limited, clearly defined role"**
   - Means: an officer serves several schools or part of the time, under a written, limited role.
   - Operative clauses: [a] a shared or part-time officer; [b] a limited role that is written down.
   - Establishing evidence looks like: an MOU or contract for officers who cover more than one school
     or work part-time, with a defined scope of duties.
   - Levels that hold a lever: school; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a defined role also appears in dedicated-officer MOUs. The
     separator is coverage: one officer per school → rung 4.

4. **"Place a dedicated officer in every school for safety, but bar them from routine discipline"**
   - Means: each school has its own officer for safety, who does not handle ordinary student
     discipline.
   - Operative clauses: [a] a dedicated officer in every school; [b] the officer is barred from
     routine discipline. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a mandate or contract for an officer in every school **plus**
     operative text that excludes officers from routine school discipline.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A mandate for an officer in every school that is silent on discipline cannot separate rung 4
     from rung 5 → `direction-only` (V4.2 "Silence is not a clause").
   - A mandate with waivers (shared officers for small districts, or another person in place of an
     officer) does not meet "every school" → `direction-only` _(proposed)_.

5. **"Place an officer in every school with authority to handle discipline and make arrests on
   campus"**
   - Means: each school has an officer who may enforce school discipline as well as make arrests.
   - Operative clauses: [a] an officer in every school; [b] authority to handle discipline; [c]
     authority to make arrests on campus.
   - Establishing evidence looks like: a mandate or contract for an officer in every school whose
     duties include school discipline. Arrest power comes with a sworn officer; [b] must be stated
     _(proposed)_.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Armed staff or guards** who are not police (guardian programmes, armed teachers, private
  security) → `adjacent` _(proposed)_.
- **Grant programmes** that fund officers without a per-school rule → `direction-only` _(proposed)_.
- **Physical security** (cameras, metal detectors, locked entrances) → `adjacent`.
- **A city police budget** with an SRO line → V4 `multi-subject`; a single-item vote on the SRO
  contract → on-question.
- **State law and school boards.** A state law that itself requires or forbids officers in every
  school states the rule → `on-question`. A law that only decides which body may contract for
  officers → `adjacent` (V2, H12) _(ruled 2026-10-01)_ A state law is the legislator's act, not a school-board member's..
- **Study, safety audit or task force** → `study-directive`.


### topic_key: education-school-budget
topic_id: 49f0b171-2ddf-4e68-887f-0ba78a2562f1  served_revision_id: 0c82eb1c-4bb8-4c0e-9fc1-3646925a8bfc
Question: How should schools set spending levels and decide whether to raise more revenue?
Evidence basis at this seat's level (federal): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Raise taxes to significantly increase school funding
  2. Increase funding modestly to keep pace with costs, without raising taxes
  3. Hold funding flat at current levels
  4. Cut administrative overhead to lower costs while protecting classroom funding
  5. Cut school funding significantly to reduce the taxes residents pay

#### Annex

# education-school-budget — served revision 0c82eb1c-4bb8-4c0e-9fc1-3646925a8bfc (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should schools set spending levels and decide whether to raise more revenue?"

**Orientation:** standard. Rung 1 raises taxes to raise funding a lot; rung 5 cuts funding a lot to
cut taxes. The rungs order **the funding level and its tax source**. Rung 4 is about the **mix** of
spending (administration against classroom), not the level.

**Levels with a lever:** local, school, state. The lever is the school board's
budget and levy, the city or county council where it funds or approves the school budget, and the
state's school-aid formula and tax law.

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "levy", "mill rate", "millage", "operating referendum", "override", "bond", "per-pupil
funding", "foundation amount", "school-aid formula", "adequacy", "truth in taxation", "levy limit",
"tax cap", "property-tax relief", "maintenance of effort", "central office", "administrative
overhead", "classroom spending".

1. **"Raise taxes to significantly increase school funding"**
   - Means: a tax increase that pays for a large rise in school funding.
   - Operative clauses: [a] a tax increase; [b] a significant funding increase. Compound: one side
     only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a vote to raise the levy or rate, or to put an operating
     referendum or override on the ballot, where the passage shows the increase is large.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - "Significantly" means an increase **above cost growth** (inflation and enrollment) as the
     passage shows; rung 2 defines "modestly" as keeping pace. A tax-funded increase that only keeps
     pace → `direction-only` (not rung 1: not significant; not rung 2: it raises taxes) _(ruled 2026-10-01)_.

2. **"Increase funding modestly to keep pace with costs, without raising taxes"**
   - Means: funding rises about as fast as costs, paid from existing revenue.
   - Operative clauses: [a] a modest increase that tracks costs (inflation, enrollment); [b] no tax
     increase. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a budget whose increase tracks costs **and** a levy or rate
     held at its current level. [b] is an absence clause: the passage must show no tax increase
     (V4.2 "Silence is not a clause").
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 when the nominal budget is flat but costs rise. Code the change
     the passage states; do not convert to real terms _(proposed)_.

3. **"Hold funding flat at current levels"**
   - Means: no increase and no cut.
   - Operative clauses: [a] the total stays at its current level.
   - Establishing evidence looks like: a budget or own words that keep the total the same as last
     year.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.

4. **"Cut administrative overhead to lower costs while protecting classroom funding"**
   - Means: spend less on administration and keep classroom spending whole.
   - Operative clauses: [a] a cut to administrative overhead; [b] classroom funding protected.
     Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a budget amendment or own words that cut central-office or
     administrative spending **and** keep classroom spending at or above its level.
   - Levels that hold a lever: school; local; state (classroom-spending floors).
   - Known chair-shaped instruments: _(none on file)_.
   - A classroom-spending floor (a share that must go to instruction) meets [b] only →
     `compound-partial` _(proposed)_.

5. **"Cut school funding significantly to reduce the taxes residents pay"**
   - Means: a large funding cut that is made to lower taxes.
   - Operative clauses: [a] a significant funding cut; [b] made to reduce taxes. Compound: one side
     only → `compound-partial`.
   - Establishing evidence looks like: a vote to lower the levy or rate together with a large
     budget cut; own words that tie the two.
   - Levels that hold a lever: school; local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - **Property-tax relief that the state replaces with state aid** lowers taxes without cutting
     funding → not [a] → `direction-only` _(proposed)_.

**Hard cases:**
- **A Yes on the district's annual budget** is `on-question`, not `multi-subject`: the total is this
  ladder's subject. It is chair-shaped only when the passage shows the year-over-year change and the
  levy or rate change; otherwise `direction-only` _(ruled 2026-10-01)_.
- **A No on a budget** proves nothing (V4.1).
- **What counts as raising taxes.** A higher rate, a higher levy amount, a new tax, or approval of a
  referendum, override or bond raises taxes. A rate held flat while values rise is not a tax
  increase unless the instrument says it raises the levy _(proposed)_.
- **Capital bonds** fund buildings, not operating spending → [a] at most; code [b] only when the
  passage ties the bond to the funding level _(proposed)_.
- **State levy limits and tax caps** on districts limit what a district may raise; they do not by
  their own text cut funding or lower a tax → `adjacent` (V2, H12), unless the act itself lowers
  rates _(proposed)_.
- **A state budget** with a school-aid line → V4 `multi-subject`; a single-subject school-aid bill →
  on-question.
- **Teacher pay and specific programmes** → `adjacent` unless the passage states the total level.


### topic_key: education-ai
topic_id: 61269f44-9c7f-4b27-818a-3508009f6ae2  served_revision_id: c6a2c643-aaa3-4d91-958e-e17f421b7dc9
Question: What role should artificial intelligence play in classrooms and student work?
Evidence basis at this seat's level (federal): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Prohibit artificial intelligence tools in student work and classroom instruction
  2. Restrict artificial intelligence to teacher planning and administrative use, keeping it out of student work
  3. Permit students to use artificial intelligence on designated assignments, with disclosure required
  4. Encourage broad classroom use of artificial intelligence with light guidelines and teacher discretion
  5. Let teachers and students use artificial intelligence freely, without restrictions

#### Annex

# education-ai — served revision c6a2c643-aaa3-4d91-958e-e17f421b7dc9 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "What role should artificial intelligence play in classrooms and student work?"

**Orientation:** standard. Rung 1 prohibits AI in schools, rung 5 allows it with no restriction. The
rungs order **how much classroom and student use is allowed**: none, staff only, designated
assignments with disclosure, broad use with light rules, free use.

**Levels with a lever:** school, state. The lever is the school board's
policy (acceptable use, academic integrity, device and network rules) and state statute or
state-board rules. A city or county council holds none → own words only there _(proposed)_.

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal, local (codebook V2 "No-lever level").

**Synonyms:** "generative AI", "large language model", "chatbot", "AI tutor", "acceptable use
policy", "academic integrity", "AI disclosure", "AI literacy", "AI guidance", "responsible use".

1. **"Prohibit artificial intelligence tools in student work and classroom instruction"**
   - Means: AI is banned both from what students produce and from teaching in class.
   - Operative clauses: [a] banned in student work; [b] banned in classroom instruction. Compound:
     one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a policy or statute that bans AI tools for students **and** for
     classroom instruction.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A ban on student use that is silent on teachers cannot separate rung 1 from rung 2 →
     `direction-only`.
   - **Blocking AI sites on district networks and devices** is a ban in practice for students; it
     says nothing about instruction → [a] only _(proposed)_.

2. **"Restrict artificial intelligence to teacher planning and administrative use, keeping it out of
   student work"**
   - Means: teachers and staff may use AI for planning and administration; students may not use it
     for their work.
   - Operative clauses: [a] staff use allowed for planning and administration; [b] no student use.
     Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a policy that permits staff use **and** bars student use.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.

3. **"Permit students to use artificial intelligence on designated assignments, with disclosure
   required"**
   - Means: students may use AI only where the assignment allows it, and must say when they did.
   - Operative clauses: [a] student use only on designated assignments; [b] disclosure required.
     Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: an academic-integrity or acceptable-use policy with both
     clauses.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A disclosure or citation rule with no limit to designated assignments meets [b] only →
     `compound-partial`.

4. **"Encourage broad classroom use of artificial intelligence with light guidelines and teacher
   discretion"**
   - Means: schools promote wide use of AI in class, with a few rules and room for each teacher to
     decide.
   - Operative clauses: [a] broad use encouraged; [b] light guidelines; [c] teacher discretion.
   - Establishing evidence looks like: a policy or own words that promote classroom use and leave
     the limits to teachers under general guidance.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because teacher discretion can include "designated" assignments.
     If the policy requires disclosure and limits use to assignments the teacher designates → rung 3.

5. **"Let teachers and students use artificial intelligence freely, without restrictions"**
   - Means: no limits on AI use by teachers or students.
   - Operative clauses: [a] free use by teachers and students; [b] no restrictions.
   - Establishing evidence looks like: own words or a policy that rejects any restriction. [b] is an
     absence clause: a district with no AI policy has not said "no restrictions" (V4.2 "Silence is
     not a clause").
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because broad use with few rules reads like free use. Any
     guideline at all → not rung 5.

**Hard cases:**
- **A state law that requires each district to adopt an AI policy**, without saying what it must
  contain, decides that districts decide → `adjacent` (V2, H12) _(ruled 2026-10-01)_.
- **State guidance, task forces and pilot programmes** → `study-directive`.
- **Teaching about AI** (AI literacy, computer science standards) is not use in student work →
  `adjacent` _(proposed)_.
- **Student data privacy** rules for AI vendors, and **AI-generated images** of students (deepfakes)
  → `adjacent`.
- **Buying an AI tutoring product** → `direction-only` toward rungs 3–5 _(proposed)_.
- **Phone or device bans** that do not name AI → `adjacent`.
- **Budget or omnibus votes** → V4 `multi-subject`.


## Sources

---
snapshot_id: 9da6bb5f-c7d4-5c0e-bbf1-9574063e570a
source_kind: own-site (the person's own site or account)
url: https://houchin.house.gov/media/press-releases/congresswoman-houchin-supports-house-passage-parents-bill-rights

Congresswoman Houchin Supports House Passage of the Parents Bill of Rights | Congresswoman Erin Houchin Skip to main content 342 Cannon House Office Building, Washington, DC 20515 Email Me (202) 225-5315 About Committees and Caucuses Our District Votes and Legislation Contact Newsletter Subscribe Office Locations Media Press Releases Issues Agriculture Economy Education Energy Health Veterans Border Security Services Art Competition Congressional App Challenge Congressional Commendations Flags Grant Applicants Help with a Federal Agency Internships Service Academy Nominations Tours and Tickets America 250 Attention Seniors - Fraud Alert! Casework Success Stories Community Project Funding Help for Veterans Subscribe X How Can I Help? Home Media Press Releases Congresswoman Houchin Supports House Passage of the Parents Bill of Rights March 24, 2023 Press Release Passed bill includes Rep. Houchin’s amendment to improve child literacy in the third grade WASHINGTON – Today, Congresswoman Erin Houchin (R-Ind.-09), a member of the House Education and Workforce Committee, voted to pass the Parents Bill of Rights Act to improve transparency inside the classroom. The bill included her amendment to require parents to be notified when their student is not reading at a grade-level proficiency by the end of the third grade. The vote follows Congresswoman Houchin’s management of the rule debate on the Parents Bill of Rights for the first time, including opening remarks on the need to pass the bill yesterday . “Today, House Republicans responded to the pleas of parents across America by passing the Parents Bill of Rights . We fought for and delivered a bill to put parents, not bureaucrats, in charge of their children’s education by ensuring access to information. I will always support our parents and students fundamental rights inside of the classroom, and will continue to help improve child literacy every opportunity I can,” said Congresswoman Houchin. The Parents Bill of Rights Act , which Congresswoman Houchin is an original cosponsor of, focuses on five principles, including that parents have the right to know what their children are being taught; that parents have the right to be heard; that parents have the right to see the school budget; that parents have the right to protect their children’s privacy; and that parents have a right to keep their children safe. Yesterday, Congresswoman Houchin delivered remarks on the House floor in support of the Parents Bill of Rights . Video here and transcript here . Issues : Education Office Locations Washington DC Office 342 Cannon House Office Building Washington, DC 20515 Phone: (202) 225-5315 Salem District Office 104 W Hackberry Street Salem, IN 47167 Phone: (812) 288-3999 Top Copyright Privacy House.gov Accessibility RSS

---
snapshot_id: dec8279c-e087-56ec-ab71-790a65c049b8
source_kind: own-site (the person's own site or account)
url: https://houchin.house.gov/media/press-releases/congresswoman-houchin-manages-debate-house-floor-first-time-parents-bill

Congresswoman Houchin Manages Debate on House Floor for First Time on Parents Bill of Rights | Congresswoman Erin Houchin Skip to main content 342 Cannon House Office Building, Washington, DC 20515 Email Me (202) 225-5315 About Committees and Caucuses Our District Votes and Legislation Contact Newsletter Subscribe Office Locations Media Press Releases Issues Agriculture Economy Education Energy Health Veterans Border Security Services Art Competition Congressional App Challenge Congressional Commendations Flags Grant Applicants Help with a Federal Agency Internships Service Academy Nominations Tours and Tickets America 250 Attention Seniors - Fraud Alert! Casework Success Stories Community Project Funding Help for Veterans Subscribe X How Can I Help? Home Media Press Releases Congresswoman Houchin Manages Debate on House Floor for First Time on Parents Bill of Rights March 24, 2023 Press Release WASHINGTON – Today, Congresswoman Erin Houchin (R-Ind.-09) managed rule debate on the House Floor for the first time on the Parents Bill of Rights Act. She delivered opening remarks on the legislation to restore transparency inside the classroom, including her amendment to improve the declining rates of child literacy in the third grade. “The Parents Bill of Rights would secure a fundamental right that parents should always be guaranteed, their right to make informed decisions for their children. Our families in Indiana, and across the country, deserve debate on H.R. 5 and we plan to deliver. As a mother of three children in school, I know how important it is for parents to know what is happening inside the classroom. Unfortunately, this bill is necessary,” said Congresswoman Houchin. “Yet, parents are left pleading. They are left to plead for information, to plead for safety of their kids in public restrooms, to plead for a quality education, and to plead for anyone who would listen to help restore their parental rights,” Congresswoman Houchin continued. Congresswoman Houchin’s amendment would require parents to be notified when their student is not reading at a grade-level proficiency by the end of the third grade. Two weeks ago, the amendment passed markup in the House Education and Workforce Committee and was included in the final bill text. “Our child literacy rates are falling behind, and the more parents can help, the better,” said Congresswoman Houchin. Now that the rule providing for H.R. 5 has been adopted, the House will consider the bill with a vote tomorrow. To watch the floor speech, click here . Issues : Education Office Locations Washington DC Office 342 Cannon House Office Building Washington, DC 20515 Phone: (202) 225-5315 Salem District Office 104 W Hackberry Street Salem, IN 47167 Phone: (812) 288-3999 Top Copyright Privacy House.gov Accessibility RSS

---
snapshot_id: a7eee045-339d-5009-851f-707ff6380e92
source_kind: own-site (the person's own site or account)
url: https://houchin.house.gov/media/press-releases/published-op-ed-im-mom-3-school-aged-children-and-we-need-protect-parents

Published Op-Ed: “I’m a mom of 3 school-aged children and we need to protect parents’ rights inside the classroom” | Congresswoman Erin Houchin Skip to main content 342 Cannon House Office Building, Washington, DC 20515 Email Me (202) 225-5315 About Committees and Caucuses Our District Votes and Legislation Contact Newsletter Subscribe Office Locations Media Press Releases Issues Agriculture Economy Education Energy Health Veterans Border Security Services Art Competition Congressional App Challenge Congressional Commendations Flags Grant Applicants Help with a Federal Agency Internships Service Academy Nominations Tours and Tickets America 250 Attention Seniors - Fraud Alert! Casework Success Stories Community Project Funding Help for Veterans Subscribe X How Can I Help? Home Media Press Releases Published Op-Ed: “I’m a mom of 3 school-aged children and we need to protect parents’ rights inside the classroom” September 14, 2023 Press Release WASHINGTON – Today, Congresswoman Erin Houchin (R-Ind.-09) had an op-ed published in Fox News on the urgent need to protect Hoosier parents’ rights inside the classroom. “Now more than ever we need to protect parents’ voices inside the classroom. I know I join parents across southern Indiana, and across our country, in feeling increasingly worried as soon as we send our children off to school,” Congresswoman Houchin writes. Read Congresswoman Houchin’s full op-ed here and below. I’m a mom of 3 school-aged children and we need to protect parents’ rights inside the classroom Let me cut to the chase: Now more than ever we need to protect parents’ voices inside the classroom. I know I join parents across southern Indiana, and across our country, in feeling increasingly worried as soon as we send our children off to school. It wasn’t always like this. However, as a mother to three school-aged children, I have experienced it myself throughout the years. Conversations surrounding education have evolved, especially conversations about a parent’s voice when they are advocating for their children. Recently, it feels like the communication lines have been strained, or even severed, between home and school – where our children spend most of their day. Some changes became painfully obvious to parents during the pandemic, as our living rooms became classrooms. Quickly, parents came to realize exactly what their children’s days looked like. Many parents have told me that they were surprised and disappointed by what they learned about their children’s educational experience. And when parents vocalized these concerns in school board meetings, they were often met with silence or dismissed. As I said on the floor of the House of Representatives, sending a child to a public school does not terminate the parents’ rights at the door. When I worked in child services, I assisted with the care of children in foster care. I saw how the process worked firsthand. When foster parents are caring for children in custody of the state, they can’t give those kids a haircut without permission from the child’s biological parents. Why shouldn’t the same rules apply to our students’ well-being in the classroom? Here in southern Indiana, we’re lucky. Most of our school districts go above and beyond to communicate with parents and inform them about, and empower them in, their children’s education. Tragically, this is not a universal experience across our country. In fact, one father in Virginia had to learn his daughter was assaulted in a high school bathroom from his child, not the school. Just last month, a New Jersey judge ruled to block multiple school districts from notifying parents of a child’s gender identity change. Stories like these shouldn’t become the new normal. That is exactly why House Republicans made commitments to address this problem and pushed for legislation that culminated in H.R. 5, the "Parent’s Bill of Rights." We heard the pleas of parents across America and knew we couldn’t stand by as parental rights are being eroded in our public schools. I was proud to be an original champion of H.R. 5 and support its swift passage in the House. This bill reaffirmed the fundamental relationship that had long existed between parents and teachers in America – that parents have the right to make informed decisions about their children’s education. As we highlighted extensively during the House Education and Workforce Committee’s consideration of the bill, The "Parents Bill of Rights" contains five basic principles to ensure: that parents have the right to know what their children are being taught; that parents have the right to be heard; that parents have the right to see the school budget; that parents have the right to protect their children’s privacy; and that parents have a right to keep their children safe. Furthermore, I was happy to add to this legislation during the committee process with an amendment to require notification of parents when their student isn’t reading at a grade-level proficiency by the end of third grade – an important time when kids start to transition from learning to read to reading to learn. Our child literacy rates are falling behind, and the more parents can help the better. But to help they must be informed. Years ago, we had no need for this kind of legislative action. But unfortunately, in today’s world this bill is necessary because school districts across the country have failed to deliver on these basic principles. The American education system is failing us. This debate has inspired my colleagues and me to continue to take steps to strengthen our schools and empower parents. For me, this includes actions to expand choices for parents. This is why I will always be a strong supporter of school choice and education savings accounts, which keep parents squarely in the driver’s seat. Parents know what is best for their student. As members of the House Committee on Education and the Workforce say, it’s time to apply our most fundamental principle, freedom, to our most fundamental system, education. This bill reaffirmed the fundamental relationship that had long existed between parents and teachers in America – that parents have the right to make informed decisions about their children’s education. Now, as a member of the committee, I have a seat at the table for parents inside the committee room. It’s important that we protect and restore parents’ original role in their children's education, because in the vast majority of cases, no one will be a better advocate for their children than parents. And I, along with my House Republican colleagues, won’t stop until we achieve this mission. Thankfully, we fought for and delivered a bill to put parents, not bureaucrats, in charge of their children’s education by ensuring access to information, but the fight doesn’t stop there. We will continue to look for partners in our Senate colleagues and other opportunities to restore educational excellence in every school in America. I won’t stop contending on behalf of my fellow parents because the rights of parents don’t stop at the classroom door. Office Locations Washington DC Office 342 Cannon House Office Building Washington, DC 20515 Phone: (202) 225-5315 Salem District Office 104 W Hackberry Street Salem, IN 47167 Phone: (812) 288-3999 Top Copyright Privacy House.gov Accessibility RSS

---
snapshot_id: 69a6e8f0-cf48-566f-bc0d-9b73253476ec
source_kind: public-record
url: https://clerk.house.gov/Votes/2023161

Office of the Clerk, U.S. House of Representatives Find Your Representative Search Office of the Clerk Toggle navigation Search Office of the Clerk Search button Legislative Information Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions 119th Congress, 2nd Session House Not In Session Next Session: October 9th, 2026 at 12:30 PM House Floor Proceedings Watch live.house.gov Additional Resources Votes Legacy View - 2024 119th Congress Nominees Statistics of the 2024 Congressional Election Final House Calendar (118th Congress) Résumé of Congressional Activity Legislative Search Congressional Record U.S. Senate House Schedule Bills This Week House Voting Days Member Information Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Republicans 218 218 Democrats 214 214 Independents 1 1 Vacancies 2 2 Republican Leadership Rep. Mike Johnson Speaker of the House Rep. Steve Scalise Majority Leader Rep. Tom Emmer Majority Whip Rep. Lisa C. McClain Republican Conference Chair Rep. Jay Obernolte Republican Policy Committee Chair Democratic Leadership Rep. Hakeem S. Jeffries Minority Leader Rep. Katherine M. Clark Minority Whip Rep. Pete Aguilar Democratic Caucus Chair Rep. Ted Lieu Democratic Caucus Vice Chair Additional Resources Find Your Representative Official List of Members by State Official Member Telephone Directory Duplicate and Similar Names of Members Terms of Service Mailing Labels [ MS Word | Text File ] Member Data [ Excel | XML | User Guide ] Biographical Directory Members on Congress.gov Committee Information COMMITTEE INFORMATION COMMITTEE PROFILES Agriculture Appropriations Armed Services Budget Education and Workforce Energy and Commerce Ethics Financial Services Foreign Affairs Homeland Security House Administration Judiciary Natural Resources Oversight and Government Reform Rules Science, Space, and Technology Small Business Transportation and Infrastructure Veterans' Affairs Ways and Means Select Intelligence Select Strategic Competition Joint Economic Joint Library Joint Printing Joint Taxation Additional Resources Official List of Members with Committee Assignments Official List of Standing Committees and Subcommittees Committee Repository Committee Reports Committees on Congress.gov Committee Data [ Excel ] Disclosures Disclosures PUBLIC DISCLOSURE Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications Additional Resources Lobbying Disclosures Public Laws Lobbying Disclosure Act About the Clerk About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office The Clerk of the House The Honorable Kevin F. McCumber Clerk of the U.S. House of Representatives Deputy Clerk Michelle H. Reinshuttle Deputy Clerk Contact Information Mailing Address U.S. Capitol Room H154 Washington, DC 20515&ndash;6601 Telephone Number (202) 225&ndash;7000 Office Hours 9:00 AM&ndash;6:00 PM, Monday&ndash;Friday Additional Resources Artificial Intelligence Use Case Inventory [ USHouse-Clerk-1: Comparative Print Suite ] 119th Congress, 2nd Session Back to Previous Page Roll Call 161 | Bill Number: H. R. 5 Share XML View | HTML View Mar 24, 2023, 11:02 AM | 118th Congress, 1st Session Vote Question: On Passage Parents Bill of Rights Act Vote Type: Recorded Vote Status: Passed VOTES Aye: 213 No: 208 present: 0 not voting: 14 Remote Voting by Proxy Votes by party votes by party Party Ayes Noes Present Not Voting Republican 213 5 0 4 Democratic 0 203 0 10 Independent 0 0 0 0 Total 213 208 0 14 All votes Keyword Name Party All Parties Republican Democratic Independent State All States Votes All Votes YEA/AYE NAY/NO PRESENT NOT VOTING All votes Representative Party State Vote Adams Adams Democratic North Carolina NC No Aderholt Aderholt Republican Alabama AL Aye Aguilar Aguilar Democratic California CA No Alford Alford Republican Missouri MO Aye Allen Allen Republican Georgia GA Aye Allred Allred Democratic Texas TX No Amodei Amodei Republican Nevada NV Aye Armstrong Armstrong Republican North Dakota ND Aye Arrington Arrington Republican Texas TX Aye Auchincloss Auchincloss Democratic Massachusetts MA No Babin Babin Republican Texas TX Aye Bacon Bacon Republican Nebraska NE Aye Baird Baird Republican Indiana IN Aye Balderson Balderson Republican Ohio OH Aye Balint Balint Democratic Vermont VT No Banks Banks Republican Indiana IN Aye Barr Barr Republican Kentucky KY Aye Barragán Barragan Democratic California CA No Bean (FL) Bean (FL) Republican Florida FL Aye Beatty Beatty Democratic Ohio OH No Bentz Bentz Republican Oregon OR Aye Bera Bera Democratic California CA No Bergman Bergman Republican Michigan MI Aye Beyer Beyer Democratic Virginia VA No Bice Bice Republican Oklahoma OK Aye Biggs Biggs Republican Arizona AZ No Bilirakis Bilirakis Republican Florida FL Aye Bishop (GA) Bishop (GA) Democratic Georgia GA No Bishop (NC) Bishop (NC) Republican North Carolina NC Aye Blumenauer Blumenauer Democratic Oregon OR Not Voting Blunt Rochester Blunt Rochester Democratic Delaware DE No Boebert Boebert Republican Colorado CO Aye Bonamici Bonamici Democratic Oregon OR No Bost Bost Republican Illinois IL Aye Bowman Bowman Democratic New York NY No Boyle (PA) Boyle (PA) Democratic Pennsylvania PA No Brecheen Brecheen Republican Oklahoma OK Aye Brown Brown Democratic Ohio OH No Brownley Brownley Democratic California CA No Buchanan Buchanan Republican Florida FL Aye Buck Buck Republican Colorado CO No Bucshon Bucshon Republican Indiana IN Not Voting Budzinski Budzinski Democratic Illinois IL No Burchett Burchett Republican Tennessee TN Aye Burgess Burgess Republican Texas TX Aye Burlison Burlison Republican Missouri MO Aye Bush Bush Democratic Missouri MO No Calvert Calvert Republican California CA Aye Cammack Cammack Republican Florida FL Aye Caraveo Caraveo Democratic Colorado CO No Carbajal Carbajal Democratic California CA No Cárdenas Cardenas Democratic California CA No Carey Carey Republican Ohio OH Aye Carl Carl Republican Alabama AL Aye Carson Carson Democratic Indiana IN No Carter (GA) Carter (GA) Republican Georgia GA Aye Carter (LA) Carter (LA) Democratic Louisiana LA No Carter (TX) Carter (TX) Republican Texas TX Aye Cartwright Cartwright Democratic Pennsylvania PA No Casar Casar Democratic Texas TX No Case Case Democratic Hawaii HI No Casten Casten Democratic Illinois IL No Castor (FL) Castor (FL) Democratic Florida FL No Castro (TX) Castro (TX) Democratic Texas TX Not Voting Chavez-DeRemer Chavez-DeRemer Republican Oregon OR Aye Cherfilus-McCormick Cherfilus-McCormick Democratic Florida FL No Chu Chu Democratic California CA No Cicilline Cicilline Democratic Rhode Island RI No Ciscomani Ciscomani Republican Arizona AZ Aye Clark (MA) Clark (MA) Democratic Massachusetts MA No Clarke (NY) Clarke (NY) Democratic New York NY No Cleaver Cleaver Democratic Missouri MO Not Voting Cline Cline Republican Virginia VA Aye Cloud Cloud Republican Texas TX Aye Clyburn Clyburn Democratic South Carolina SC No Clyde Clyde Republican Georgia GA Aye Cohen Cohen Democratic Tennessee TN No Cole Cole Republican Oklahoma OK Aye Collins Collins Republican Georgia GA Aye Comer Comer Republican Kentucky KY Aye Connolly Connolly Democratic Virginia VA No Correa Correa Democratic California CA No Costa Costa Democratic California CA Not Voting Courtney Courtney Democratic Connecticut CT No Craig Craig Democratic Minnesota MN No Crane Crane Republican Arizona AZ Aye Crawford Crawford Republican Arkansas AR Aye Crenshaw Crenshaw Republican Texas TX Aye Crockett Crockett Democratic Texas TX No Crow Crow Democratic Colorado CO No Cuellar Cuellar Democratic Texas TX Not Voting Curtis Curtis Republican Utah UT Aye D'Esposito D'Esposito Republican New York NY Aye Davids (KS) Davids (KS) Democratic Kansas KS No Davidson Davidson Republican Ohio OH Aye Davis (IL) Davis (IL) Democratic Illinois IL No Davis (NC) Davis (NC) Democratic North Carolina NC No De La Cruz De La Cruz Republican Texas TX Aye Dean (PA) Dean (PA) Democratic Pennsylvania PA No DeGette DeGette Democratic Colorado CO No DeLauro DeLauro Democratic Connecticut CT No DelBene DelBene Democratic Washington WA No Deluzio Deluzio Democratic Pennsylvania PA No DeSaulnier DeSaulnier Democratic California CA No DesJarlais DesJarlais Republican Tennessee TN Aye Diaz-Balart Diaz-Balart Republican Florida FL Aye Dingell Dingell Democratic Michigan MI No Doggett Doggett Democratic Texas TX No Donalds Donalds Republican Florida FL Aye Duarte Duarte Republican California CA Aye Duncan Duncan Republican South Carolina SC Aye Dunn (FL) Dunn (FL) Republican Florida FL Aye Edwards Edwards Republican North Carolina NC Aye Ellzey Ellzey Republican Texas TX Aye Emmer Emmer Republican Minnesota MN Aye Escobar Escobar Democratic Texas TX No Eshoo Eshoo Democratic California CA No Espaillat Espaillat Democratic New York NY No Estes Estes Republican Kansas KS Aye Evans Evans Democratic Pennsylvania PA No Ezell Ezell Republican Mississippi MS Aye Fallon Fallon Republican Texas TX Aye Feenstra Feenstra Republican Iowa IA Aye Ferguson Ferguson Republican Georgia GA Aye Finstad Finstad Republican Minnesota MN Aye Fischbach Fischbach Republican Minnesota MN Aye Fitzgerald Fitzgerald Republican Wisconsin WI Aye Fitzpatrick Fitzpatrick Republican Pennsylvania PA Aye Fleischmann Fleischmann Republican Tennessee TN Aye Fletcher Fletcher Democratic Texas TX No Flood Flood Republican Nebraska NE Aye Foster Foster Democratic Illinois IL No Foushee Foushee Democratic North Carolina NC No Foxx Foxx Republican North Carolina NC Aye Frankel, Lois Frankel, Lois Democratic Florida FL No Franklin, C. Scott Franklin, C. Scott Republican Florida FL Aye Frost Frost Democratic Florida FL No Fry Fry Republican South Carolina SC Aye Fulcher Fulcher Republican Idaho ID Aye Gaetz Gaetz Republican Florida FL No Gallagher Gallagher Republican Wisconsin WI Aye Gallego Gallego Democratic Arizona AZ Not Voting Garamendi Garamendi Democratic California CA No Garbarino Garbarino Republican New York NY Aye García (IL) Garcia (IL) Democratic Illinois IL No Garcia (TX) Garcia (TX) Democratic Texas TX No Garcia, Mike Garcia, Mike Republican California CA Aye Garcia, Robert Garcia, Robert Democratic California CA No Gimenez Gimenez Republican Florida FL Aye Golden (ME) Golden (ME) Democratic Maine ME No Goldman (NY) Goldman (NY) Democratic New York NY No Gomez Gomez Democratic California CA No Gonzales, Tony Gonzales, Tony Republican Texas TX Aye Gonzalez, Vicente Gonzalez, Vicente Democratic Texas TX No Good (VA) Good (VA) Republican Virginia VA Aye Gooden (TX) Gooden (TX) Republican Texas TX Aye Gosar Gosar Republican Arizona AZ Aye Gottheimer Gottheimer Democratic New Jersey NJ No Granger Granger Republican Texas TX Aye Graves (LA) Graves (LA) Republican Louisiana LA Aye Graves (MO) Graves (MO) Republican Missouri MO Aye Green (TN) Green (TN) Republican Tennessee TN Aye Green, Al (TX) Green, Al (TX) Democratic Texas TX No Greene (GA) Greene (GA) Republican Georgia GA Aye Griffith Griffith Republican Virginia VA Aye Grijalva Grijalva Democratic Arizona AZ No Grothman Grothman Republican Wisconsin WI Aye Guest Guest Republican Mississippi MS Aye Guthrie Guthrie Republican Kentucky KY Aye Hageman Hageman Republican Wyoming WY Aye Harder (CA) Harder (CA) Democratic California CA No Harris Harris Republican Maryland MD Aye Harshbarger Harshbarger Republican Tennessee TN Aye Hayes Hayes Democratic Connecticut CT No Hern Hern Republican Oklahoma OK Aye Higgins (LA) Higgins (LA) Republican Louisiana LA Aye Higgins (NY) Higgins (NY) Democratic New York NY No Hill Hill Republican Arkansas AR Aye Himes Himes Democratic Connecticut CT No Hinson Hinson Republican Iowa IA Aye Horsford Horsford Democratic Nevada NV No Houchin Houchin Republican Indiana IN Aye Houlahan Houlahan Democratic Pennsylvania PA No Hoyer Hoyer Democratic Maryland MD No Hoyle (OR) Hoyle (OR) Democratic Oregon OR No Hudson Hudson Republican North Carolina NC Aye Huffman Huffman Democratic California CA No Huizenga Huizenga Republican Michigan MI Aye Hunt Hunt Republican Texas TX Aye Issa Issa Republican California CA Aye Ivey Ivey Democratic Maryland MD No Jackson (IL) Jackson (IL) Democratic Illinois IL No Jackson (NC) Jackson (NC) Democratic North Carolina NC No Jackson (TX) Jackson (TX) Republican Texas TX Aye Jackson Lee Jackson Lee Democratic Texas TX No Jacobs Jacobs Democratic California CA No James James Republican Michigan MI Aye Jayapal Jayapal Democratic Washington WA No Jeffries Jeffries Democratic New York NY No Johnson (GA) Johnson (GA) Democratic Georgia GA No Johnson (LA) Johnson (LA) Republican Louisiana LA Not Voting Johnson (OH) Johnson (OH) Republican Ohio OH Aye Johnson (SD) Johnson (SD) Republican South Dakota SD Aye Jordan Jordan Republican Ohio OH Aye Joyce (OH) Joyce (OH) Republican Ohio OH Aye Joyce (PA) Joyce (PA) Republican Pennsylvania PA Aye Kamlager-Dove Kamlager-Dove Democratic California CA No Kaptur Kaptur Democratic Ohio OH No Kean (NJ) Kean (NJ) Republican New Jersey NJ Aye Keating Keating Democratic Massachusetts MA No Kelly (IL) Kelly (IL) Democratic Illinois IL Not Voting Kelly (MS) Kelly (MS) Republican Mississippi MS Aye Kelly (PA) Kelly (PA) Republican Pennsylvania PA Aye Khanna Khanna Democratic California CA No Kiggans (VA) Kiggans (VA) Republican Virginia VA Aye Kildee Kildee Democratic Michigan MI No Kiley Kiley Republican California CA Aye Kilmer Kilmer Democratic Washington WA No Kim (CA) Kim (CA) Republican California CA Aye Kim (NJ) Kim (NJ) Democratic New Jersey NJ No Krishnamoorthi Krishnamoorthi Democratic Illinois IL No Kuster Kuster Democratic New Hampshire NH No Kustoff Kustoff Republican Tennessee TN Aye LaHood LaHood Republican Illinois IL Aye LaLota LaLota Republican New York NY Aye LaMalfa LaMalfa Republican California CA Aye Lamborn Lamborn Republican Colorado CO Aye Landsman Landsman Democratic Ohio OH No Langworthy Langworthy Republican New York NY Aye Larsen (WA) Larsen (WA) Democratic Washington WA No Larson (CT) Larson (CT) Democratic Connecticut CT No Latta Latta Republican Ohio OH Aye LaTurner LaTurner Republican Kansas KS Aye Lawler Lawler Republican New York NY No Lee (CA) Lee (CA) Democratic California CA No Lee (FL) Lee (FL) Republican Florida FL Aye Lee (NV) Lee (NV) Democratic Nevada NV No Lee (PA) Lee (PA) Democratic Pennsylvania PA No Leger Fernandez Leger Fernandez Democratic New Mexico NM Not Voting Lesko Lesko Republican Arizona AZ Aye Letlow Letlow Republican Louisiana LA Aye Levin Levin Democratic California CA No Lieu Lieu Democratic California CA No Lofgren Lofgren Democratic California CA No Loudermilk Loudermilk Republican Georgia GA Aye Lucas Lucas Republican Oklahoma OK Aye Luetkemeyer Luetkemeyer Republican Missouri MO Aye Luna Luna Republican Florida FL Aye Luttrell Luttrell Republican Texas TX Aye Lynch Lynch Democratic Massachusetts MA No Mace Mace Republican South Carolina SC Aye Magaziner Magaziner Democratic Rhode Island RI No Malliotakis Malliotakis Republican New York NY Aye Mann Mann Republican Kansas KS Aye Manning Manning Democratic North Carolina NC No Massie Massie Republican Kentucky KY Aye Mast Mast Republican Florida FL Aye Matsui Matsui Democratic California CA No McBath McBath Democratic Georgia GA No McCarthy McCarthy Republican California CA Aye McCaul McCaul Republican Texas TX Aye McClain McClain Republican Michigan MI Aye McClellan McClellan Democratic Virginia VA No McClintock McClintock Republican California CA Aye McCollum McCollum Democratic Minnesota MN No McCormick McCormick Republican Georgia GA Aye McGarvey McGarvey Democratic Kentucky KY No McGovern McGovern Democratic Massachusetts MA No McHenry McHenry Republican North Carolina NC Aye Meeks Meeks Democratic New York NY No Menendez Menendez Democratic New Jersey NJ No Meng Meng Democratic New York NY No Meuser Meuser Republican Pennsylvania PA Aye Mfume Mfume Democratic Maryland MD No Miller (IL) Miller (IL) Republican Illinois IL Aye Miller (OH) Miller (OH) Republican Ohio OH Aye Miller (WV) Miller (WV) Republican West Virginia WV Aye Miller-Meeks Miller-Meeks Republican Iowa IA Aye Mills Mills Republican Florida FL Aye Molinaro Molinaro Republican New York NY Aye Moolenaar Moolenaar Republican Michigan MI Aye Mooney Mooney Republican West Virginia WV Aye Moore (AL) Moore (AL) Republican Alabama AL Aye Moore (UT) Moore (UT) Republican Utah UT Aye Moore (WI) Moore (WI) Democratic Wisconsin WI No Moran Moran Republican Texas TX Aye Morelle Morelle Democratic New York NY No Moskowitz Moskowitz Democratic Florida FL Not Voting Moulton Moulton Democratic Massachusetts MA No Mrvan Mrvan Democratic Indiana IN No Mullin Mullin Democratic California CA Not Voting Murphy Murphy Republican North Carolina NC Aye Nadler Nadler Democratic New York NY No Napolitano Napolitano Democratic California CA No Neal Neal Democratic Massachusetts MA No Neguse Neguse Democratic Colorado CO No Nehls Nehls Republican Texas TX Aye Newhouse Newhouse Republican Washington WA Aye Nickel Nickel Democratic North Carolina NC No Norcross Norcross Democratic New Jersey NJ No Norman Norman Republican South Carolina SC Aye Nunn (IA) Nunn (IA) Republican Iowa IA Not Voting Obernolte Obernolte Republican California CA Aye Ocasio-Cortez Ocasio-Cortez Democratic New York NY No Ogles Ogles Republican Tennessee TN Aye Omar Omar Democratic Minnesota MN No Owens Owens Republican Utah UT Aye Pallone Pallone Democratic New Jersey NJ No Palmer Palmer Republican Alabama AL Not Voting Panetta Panetta Democratic California CA No Pappas Pappas Democratic New Hampshire NH No Pascrell Pascrell Democratic New Jersey NJ No Payne Payne Democratic New Jersey NJ No Pelosi Pelosi Democratic California CA No Peltola Peltola Democratic Alaska AK No Pence Pence Republican Indiana IN Aye Perez Perez Democratic Washington WA No Perry Perry Republican Pennsylvania PA Aye Peters Peters Democratic California CA No Pettersen Pettersen Democratic Colorado CO No Pfluger Pfluger Republican Texas TX Aye Phillips Phillips Democratic Minnesota MN No Pingree Pingree Democratic Maine ME No Pocan Pocan Democratic Wisconsin WI No Porter Porter Democratic California CA No Posey Posey Republican Florida FL Aye Pressley Pressley Democratic Massachusetts MA No Quigley Quigley Democratic Illinois IL No Ramirez Ramirez Democratic Illinois IL No Raskin Raskin Democratic Maryland MD No Reschenthaler Reschenthaler Republican Pennsylvania PA Aye Rodgers (WA) Rodgers (WA) Republican Washington WA Aye Rogers (AL) Rogers (AL) Republican Alabama AL Aye Rogers (KY) Rogers (KY) Republican Kentucky KY Aye Rose Rose Republican Tennessee TN Aye Rosendale Rosendale Republican Montana MT No Ross Ross Democratic North Carolina NC No Rouzer Rouzer Republican North Carolina NC Aye Roy Roy Republican Texas TX Aye Ruiz Ruiz Democratic California CA No Ruppersberger Ruppersberger Democratic Maryland MD No Rutherford Rutherford Republican Florida FL Aye Ryan Ryan Democratic New York NY No Salazar Salazar Republican Florida FL Aye Salinas Salinas Democratic Oregon OR No Sánchez Sanchez Democratic California CA No Santos Santos Republican New York NY Aye Sarbanes Sarbanes Democratic Maryland MD No Scalise Scalise Republican Louisiana LA Aye Scanlon Scanlon Democratic Pennsylvania PA No Schakowsky Schakowsky Democratic Illinois IL No Schiff Schiff Democratic California CA No Schneider Schneider Democratic Illinois IL No Scholten Scholten Democratic Michigan MI No Schrier Schrier Democratic Washington WA No Schweikert Schweikert Republican Arizona AZ Aye Scott (VA) Scott (VA) Democratic Virginia VA No Scott, Austin Scott, Austin Republican Georgia GA Aye Scott, David Scott, David Democratic Georgia GA No Self Self Republican Texas TX Aye Sessions Sessions Republican Texas TX Aye Sewell Sewell Democratic Alabama AL No Sherman Sherman Democratic California CA No Sherrill Sherrill Democratic New Jersey NJ No Simpson Simpson Republican Idaho ID Aye Slotkin Slotkin Democratic Michigan MI No Smith (MO) Smith (MO) Republican Missouri MO Aye Smith (NE) Smith (NE) Republican Nebraska NE Aye Smith (NJ) Smith (NJ) Republican New Jersey NJ Aye Smith (WA) Smith (WA) Democratic Washington WA No Smucker Smucker Republican Pennsylvania PA Aye Sorensen Sorensen Democratic Illinois IL No Soto Soto Democratic Florida FL No Spanberger Spanberger Democratic Virginia VA No Spartz Spartz Republican Indiana IN Aye Stansbury Stansbury Democratic New Mexico NM No Stanton Stanton Democratic Arizona AZ No Stauber Stauber Republican Minnesota MN Aye Steel Steel Republican California CA Aye Stefanik Stefanik Republican New York NY Aye Steil Steil Republican Wisconsin WI Aye Steube Steube Republican Florida FL Aye Stevens Stevens Democratic Michigan MI No Stewart Stewart Republican Utah UT Aye Strickland Strickland Democratic Washington WA No Strong Strong Republican Alabama AL Aye Swalwell Swalwell Democratic California CA No Sykes Sykes Democratic Ohio OH No Takano Takano Democratic California CA No Tenney Tenney Republican New York NY Aye Thanedar Thanedar Democratic Michigan MI No Thompson (CA) Thompson (CA) Democratic California CA No Thompson (MS) Thompson (MS) Democratic Mississippi MS No Thompson (PA) Thompson (PA) Republican Pennsylvania PA Aye Tiffany Tiffany Republican Wisconsin WI Aye Timmons Timmons Republican South Carolina SC Aye Titus Titus Democratic Nevada NV No Tlaib Tlaib Democratic Michigan MI No Tokuda Tokuda Democratic Hawaii HI No Tonko Tonko Democratic New York NY No Torres (CA) Torres (CA) Democratic California CA No Torres (NY) Torres (NY) Democratic New York NY No Trahan Trahan Democratic Massachusetts MA No Trone Trone Democratic Maryland MD No Turner Turner Republican Ohio OH Aye Underwood Underwood Democratic Illinois IL No Valadao Valadao Republican California CA Aye Van Drew Van Drew Republican New Jersey NJ Aye Van Duyne Van Duyne Republican Texas TX Aye Van Orden Van Orden Republican Wisconsin WI Aye Vargas Vargas Democratic California CA No Vasquez Vasquez Democratic New Mexico NM No Veasey Veasey Democratic Texas TX No Velázquez Velazquez Democratic New York NY No Wagner Wagner Republican Missouri MO Aye Walberg Walberg Republican Michigan MI Aye Waltz Waltz Republican Florida FL Aye Wasserman Schultz Wasserman Schultz Democratic Florida FL No Waters Waters Democratic California CA No Watson Coleman Watson Coleman Democratic New Jersey NJ No Weber (TX) Weber (TX) Republican Texas TX Aye Webster (FL) Webster (FL) Republican Florida FL Aye Wenstrup Wenstrup Republican Ohio OH Aye Westerman Westerman Republican Arkansas AR Aye Wexton Wexton Democratic Virginia VA No Wild Wild Democratic Pennsylvania PA No Williams (GA) Williams (GA) Democratic Georgia GA No Williams (NY) Williams (NY) Republican New York NY Aye Williams (TX) Williams (TX) Republican Texas TX Aye Wilson (FL) Wilson (FL) Democratic Florida FL No Wilson (SC) Wilson (SC) Republican South Carolina SC Aye Wittman Wittman Republican Virginia VA Aye Womack Womack Republican Arkansas AR Aye Yakym Yakym Republican Indiana IN Aye Zinke Zinke Republican Montana MT Aye No data found 118 Contact Information Room H154, The Capitol Washington, DC 20515-6601 p: (202) 225-7000 For general inquiries: info.clerkweb@mail.house.gov For general technical support: techsupport.clerkweb@mail.house.gov Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Disclosures Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office Committee Information Committee Profiles Clerk Sites Bills This Week Biographical Directory Clerk Kids Committee Repository History, Art & Archives Office of the Chaplain Help & Resources FAQs Privacy Policy Site Map

---
snapshot_id: 035b809c-3a9b-500b-8771-7bcbc2ce0b37
source_kind: public-record
url: https://www.congress.gov/bill/118th-congress/house-bill/5

Parents Bill of Rights Act Policy area: Education Sponsor: Rep. Letlow, Julia [R-LA-5] Latest action: Received in the Senate and Read twice and referred to the Committee on Health, Education, Labor, and Pensions. Parents Bill of Rights Act This bill establishes various rights of parents and guardians regarding the elementary or secondary school education of their children. Local educational agencies (LEAs) and schools must comply with the requirements of the bill in order to receive federal education funds. Specifically, the bill requires schools to notify parents and guardians of their rights regarding the education of their children. These rights include the right to review the curriculum of their child's school; know if the state alters its challenging academic standards; meet with each teacher of their child at least twice each school year; review the budget, including all revenues and expenditures, of their child's school; review a list of the books and other reading materials in the library of their child's school; address the school board of the LEA; receive information about violent activity in their child's school; and receive information about any plans to eliminate gifted and talented programs in the child's school. Additionally, the bill directs each LEA to post on a publicly accessible website (or otherwise widely disseminate to the public) the curriculum for each elementary and secondary school grade level. The LEA must also include in its annual report card the overall budget of the LEA and the budget for each elementary and secondary school. The bill also provides for additional family educational and privacy rights, including by prohibiting schools from selling student information for commercial or financial gain. Parents Bill of Rights Act This bill establishes various rights of parents and guardians regarding the elementary or secondary school education of their children. Local educational agencies (LEAs) and schools must comply with the requirements of the bill in order to receive federal education funds. Specifically, the bill requires schools to notify parents and guardians of their rights regarding the education of their children. These rights include the right to review the curriculum of their child's school; meet with each teacher of their child at least twice each school year; review the budget, including all revenues and expenditures, of their child's school; inspect the books and other reading materials in the library of their child's school; address the school board of the LEA; receive information about violent activity in their child's school; and know if their child is not grade-level proficient in reading or language arts at the end of 3rd grade. Each LEA must (1) post on a publicly accessible website (or otherwise widely disseminate to the public) the curriculum for each grade level, and (2) include detailed budget information in its annual report card. The bill provides for additional family educational and privacy rights, including by prohibiting schools from selling student information for commercial or financial gain. An elementary school or a school consisting of only grades 5-8 must obtain parental consent before (1) changing a minor child's gender markers, pronouns, or preferred name on school forms; or (2) allowing a child to change the child's sex-based accommodations. Parents Bill of Rights Act This bill establishes various rights of parents and guardians regarding the public elementary or secondary school education (including secondary career and technical education) of their children. Local educational agencies (LEAs) and schools must comply with the requirements of the bill in order to receive federal education funds. Specifically, the bill requires schools to notify parents and guardians of their rights regarding the education of their children. These rights include the right to review (and make copies of at no cost) the curriculum of their child's school; know if the state alters its challenging academic standards; meet with each teacher of their child at least twice each school year; review the budget, including all revenues and expenditures, of their child's school; inspect the books and other reading materials in the library of their child's school; address the school board of the LEA; receive information about violent activity in their child's school; and know if their child is not grade-level proficient in reading or language arts at the end of 3rd grade. Additional rights include the right to receive information about any plans to eliminate gifted and talented programs or college credit programs in their child's school; know the total number of school counselors in their child's school; know if their child's school operates, sponsors, or facilitates athletic programs or activities that permit an individual whose biological sex is male to participate in an athletic program or activity that is designed for individuals whose biological sex is female; know if their child's school allows an individual whose biological sex is male to use restrooms or changing rooms designated for individuals whose biological sex is female; and receive timely information about any major cyberattack against their child's school. Each LEA must (1) post on a publicly accessible website (or otherwise widely disseminate to the public) the curriculum for each grade level, and (2) include detailed budget information in its annual report card. The bill provides for additional family educational and privacy rights, including by (1) prohibiting schools from acting as an agent of a parent for purposes of providing verifiable parental consent for a vaccination, (2) prohibiting schools from selling student information for commercial or financial gain, and (3) requiring schools to engage meaningfully with parents in developing privacy policies or procedures. An elementary school or a school consisting of only grades 5-8 must obtain parental consent before (1) changing a minor child's gender markers, pronouns, or preferred name on school forms; or (2) allowing a child to change the child's sex-based accommodations. The bill requires the Government Accountability Office to evaluate and analyze the impact of the bill on protecting parents' rights in the education of their children and the costs to educational agencies and schools. Cosponsors: Rep. Scalise, Steve [R-LA-1], Rep. Emmer, Tom [R-MN-6], Rep. Stefanik, Elise M. [R-NY-21], Rep. Johnson, Mike [R-LA-4], Rep. Hudson, Richard [R-NC-9], Rep. Foxx, Virginia [R-NC-5], Rep. Miller, Mary E. [R-IL-15], Rep. Fitzgerald, Scott [R-WI-5], Rep. Wilson, Joe [R-SC-2], Rep. Thompson, Glenn [R-PA-15], Rep. Grothman, Glenn [R-WI-6], Rep. Allen, Rick W. [R-GA-12], Rep. Banks, Jim [R-IN-3], Rep. Smucker, Lloyd [R-PA-11], Rep. Owens, Burgess [R-UT-4], Rep. Steel, Michelle [R-CA-45], Rep. Bean, Aaron [R-FL-4], Rep. Williams, Brandon [R-NY-22], Rep. Houchin, Erin [R-IN-9], Rep. Reschenthaler, Guy [R-PA-14], Rep. Moolenaar, John R. [R-MI-2], Rep. Newhouse, Dan [R-WA-4], Rep. Miller-Meeks, Mariannette [R-IA-1], Rep. Buchanan, Vern [R-FL-16], Rep. Higgins, Clay [R-LA-3], Rep. Finstad, Brad [R-MN-1], Rep. Tenney, Claudia [R-NY-24], Rep. DesJarlais, Scott [R-TN-4], Rep. Fallon, Pat [R-TX-4], Rep. Kelly, Mike [R-PA-16], Rep. Edwards, Chuck [R-NC-11], Rep. Tiffany, Thomas P. [R-WI-7], Rep. Carl, Jerry L. [R-AL-1], Rep. Calvert, Ken [R-CA-41], Rep. Valadao, David G. [R-CA-22], Rep. Hinson, Ashley [R-IA-2], Rep. Norman, Ralph [R-SC-5], Rep. Bost, Mike [R-IL-12], Rep. Meuser, Daniel [R-PA-9], Rep. Waltz, Michael [R-FL-6], Rep. Kustoff, David [R-TN-8], Rep. Garcia, Mike [R-CA-27], Rep. Guthrie, Brett [R-KY-2], Rep. Mace, Nancy [R-SC-1], Rep. Steil, Bryan [R-WI-1], Rep. Wenstrup, Brad R. [R-OH-2], Rep. Rutherford, John H. [R-FL-5], Rep. Graves, Garret [R-LA-6], Rep. McMorris Rodgers, Cathy [R-WA-5], Rep. Duncan, Jeff [R-SC-3], Rep. Miller, Max L. [R-OH-7], Rep. McClintock, Tom [R-CA-5], Rep. Crenshaw, Dan [R-TX-2], Rep. Mooney, Alexander X. [R-WV-2], Rep. Gooden, Lance [R-TX-5], Rep. Gimenez, Carlos A. [R-FL-28], Rep. Harshbarger, Diana [R-TN-1], Rep. Guest, Michael [R-MS-3], Rep. Gonzales, Tony [R-TX-23], Rep. Huizenga, Bill [R-MI-4], Rep. Luna, Anna Paulina [R-FL-13], Rep. Balderson, Troy [R-OH-12], Rep. Wittman, Robert J. [R-VA-1], Rep. Rouzer, David [R-NC-7], Rep. Crawford, Eric A. "Rick" [R-AR-1], Rep. Ezell, Mike [R-MS-4], Rep. Carey, Mike [R-OH-15], Rep. Cammack, Kat [R-FL-3], Rep. Zinke, Ryan K. [R-MT-1], Rep. McCaul, Michael T. [R-TX-10], Rep. Joyce, John [R-PA-13], Rep. Hern, Kevin [R-OK-1], Rep. Ellzey, Jake [R-TX-6], Rep. Hageman, Harriet M. [R-WY-At Large], Rep. Lawler, Michael [R-NY-17], Rep. Lamborn, Doug [R-CO-5], Rep. Estes, Ron [R-KS-4], Rep. Lee, Laurel M. [R-FL-15], Rep. Steube, W. Gregory [R-FL-17], Rep. Van Drew, Jefferson [R-NJ-2], Rep. Feenstra, Randy [R-IA-4], Rep. Diaz-Balart, Mario [R-FL-26], Rep. Williams, Roger [R-TX-25], Rep. D'Esposito, Anthony [R-NY-4], Rep. Mann, Tracey [R-KS-1], Rep. LaHood, Darin [R-IL-16], Rep. Greene, Marjorie Taylor [R-GA-14], Rep. Smith, Christopher H. [R-NJ-4], Rep. Chavez-DeRemer, Lori [R-OR-5], Rep. Malliotakis, Nicole [R-NY-11], Rep. Langworthy, Nicholas A. [R-NY-23], Rep. Bucshon, Larry [R-IN-8], Rep. LaTurner, Jake [R-KS-2], Rep. Aderholt, Robert B. [R-AL-4], Rep. Ferguson, A. Drew, IV [R-GA-3], Rep. Posey, Bill [R-FL-8], Rep. Nehls, Troy E. [R-TX-22], Rep. Amodei, Mark E. [R-NV-2], Rep. Fischbach, Michelle [R-MN-7], Rep. Bice, Stephanie I. [R-OK-5], Rep. LaMalfa, Doug [R-CA-1], Rep. Carter, Earl L. "Buddy" [R-GA-1], Rep. Baird, James R. [R-IN-4], Rep. Moran, Nathaniel [R-TX-1], Rep. Ogles, Andrew [R-TN-5], Rep. Franklin, C. Scott [R-FL-18], Rep. Molinaro, Marcus J. [R-NY-19], Rep. Babin, Brian [R-TX-36], Rep. Santos, George [R-NY-3], Rep. Walberg, Tim [R-MI-5], Rep. Kelly, Trent [R-MS-1], Rep. Green, Mark E. [R-TN-7], Rep. Cline, Ben [R-VA-6], Rep. Boebert, Lauren [R-CO-3], Rep. Nunn, Zachary [R-IA-3], Rep. Stauber, Pete [R-MN-8], Rep. Burgess, Michael C. [R-TX-26], Rep. Van Orden, Derrick [R-WI-3], Rep. Johnson, Dusty [R-SD-At Large], Rep. Lesko, Debbie [R-AZ-8], Rep. Hunt, Wesley [R-TX-38], Rep. Jackson, Ronny [R-TX-13] Actions: Received in the Senate and Read twice and referred to the Committee on Health, Education, Labor, and Pensions. Motion to reconsider laid on the table Agreed to without objection. On passage Passed by recorded vote: 213 - 208 (Roll no. 161). Passed/agreed to in House: On passage Passed by recorded vote: 213 - 208 (Roll no. 161). On motion to recommit Failed by the Yeas and Nays: 203 - 218 (Roll no. 160). The previous question on the motion to recommit was ordered pursuant to clause 2(b) of rule XIX. Mrs. Hayes moved to recommit to the Committee on Education and the Workforce. (text: CR H1424) The House adopted the amendment in the nature of a substitute as agreed to by the Committee of the Whole House on the state of the Union. The previous question was ordered pursuant to the rule. The House rose from the Committee of the Whole House on the state of the Union to report H.R. 5. DEBATE - Pursuant to the provisions of H. Res. 241, the Committee of the Whole proceeded with 10 minutes of debate on the Tenney amendment No. 22. DEBATE - Pursuant to the provisions of H. Res. 241, the Committee of the Whole proceeded with 10 minutes of debate on the Smith (NJ) amendment No. 21. POSTPONED PROCEEDINGS - At the conclusion of debate on the Roy amendment No. 20, the Chair put the question on adoption of the amendment and by voice vote, announced that the noes had prevailed. Mr. Roy demanded a recorded vote and the Chair postponed further proceedings until a time to be announced. DEBATE - Pursuant to the provisions of H. Res. 241, the Committee of the Whole proceeded with 10 minutes of debate on the Roy amendment No. 20. POSTPONED PROCEEDINGS - At the conclusion of debate on the Roy amendment No. 19, the Chair put the question on adoption of the amendment and by voice vote, announced that the noes had prevailed. Mr. Roy demanded a recorded vote and the Chair postponed further proceedings until a time to be announced. [Congressional Bills 118th Congress] [From the U.S. Government Publishing Office] [H.R. 5 Referred in Senate (RFS)] <DOC> 118th CONGRESS 1st Session H. R. 5 _______________________________________________________________________ IN THE SENATE OF THE UNITED STATES March 27, 2023 Received; read twice and referred to the Committee on Health, Education, Labor, and Pensions _______________________________________________________________________ AN ACT To ensure the rights of parents are honored and protected in the Nation's public schools. Be it enacted by the Senate and House of Representatives of the United States of America in Congress assembled, SECTION 1. SHORT TITLE. This Act may be cited as the ``Parents Bill of Rights Act''. TITLE I--AMENDMENTS TO THE ELEMENTARY AND SECONDARY EDUCATION ACT OF 1965 SEC. 101. STATE PLAN ASSURANCES. Section 1111(g)(2) of the Elementary and Secondary Education Act of 1965 (20 U.S.C. 6311(g)(2)) is amended-- (1) in subparagraph (M), by striking ``and'' at the end; (2) in subparagraph (N), by striking the period at the end and inserting a semicolon; and (3) by adding at the end the following: ``(O) the State will ensure that each local educational agency in the State-- ``(i) in a case in which the curriculum for an elementary or secondary school (including secondary career and technical education schools) grade level is freely and publicly available on the internet-- ``(I) posts on a publicly accessible website of the agency, such curriculum; or ``(II) if such agency does not operate a website, widely disseminates to the public such curriculum; or ``(ii) in a case in which the curriculum for an elementary or secondary school (including secondary career and technical education schools) grade level is not freely and publicly available on the internet-- ``(I) posts on a publicly accessible website of the agency-- ``(aa) a description of such curriculum; and ``(bb) information on how parents can review such curriculum as described in section 1112(e)(1)(A); or ``(II) if such agency does not operate a website, widely disseminates to the public the description and information described in items (aa) and (bb) of subclause (I); and ``(P) in the case of any revisions to the State's challenging State academic standards (including any revisions to the levels of achievement within the State's academic achievement standards), the State educational agency will post to the homepage of its website, and widely disseminate to the public, notice of such revisions and a copy of such revisions, except that the State educational agency shall not be required to submit such notice or such revisions to the Secretary.''. SEC. 102. ANNUAL LOCAL EDUCATIONAL AGENCY REPORT CARDS. Section 1111(h)(2) of the Elementary and Secondary Education Act of 1965 (20 U.S.C. 6311(h)(2)) is amended by inserting at the end the following new subparagraph: ``(E) Budget.--Each local educational agency report card shall include the budget for the school year for which such report card is being prepared (including all revenues and expenditures (including expenditures made to private entities)) for the local educational agency as a whole, and for each elementary school and secondary school (including secondary career and technical education schools) served by the local educational agency. In addition to the detailed budget information required under the preceding sentence, the agency shall include a separate fact sheet that summarizes such information in a clear and easily understandable format.''. SEC. 103. LOCAL EDUCATIONAL AGENCY PLAN ASSURANCES. Section 1112(c) of the Elementary and Secondary Education Act of 1965 (20 U.S.C. 6312(c)) is amended-- (1) in paragraph (6), by striking ``and'' at the end; (2) in paragraph (7), by striking the period at the end and inserting a semicolon; and (3) by adding at the end the following: ``(8) meet the requirements described in section 1111(g)(2)(O); ``(9) post on a publicly accessible website of the local educational agency or, if the local educational agency does not operate a website, widely disseminate to the public, the plan for carrying out the parent and family engagement described in section 1116 and all policies and procedures that result from such engagement; ``(10) ensure that each elementary school served by the local educational agency notifies the parents of any student enrolled at such school when the student does not score as grade-level proficient in reading or language arts at the end of the third grade based on the reading or language arts assessments administered under section 1111(b)(2)(B)(v)(I)(aa) or another assessment administered to all third grade students by such school; and ``(11) ensure that each elementary school and secondary school (including secondary career and technical education schools) served by the local educational agency provides to the parents of students enrolled at such school, before a person speaks (in-person or virtually) to such students in a class, school assembly, or any other school-sponsored event, notice that includes the name of the speaker and the name of the organization or other entity being represented by the speaker.''. SEC. 104. PARENTS RIGHT-TO-KNOW. Section 1112(e) of the Elementary and Secondary Education Act of 1965 (20 U.S.C. 6312(e)) is amended-- (1) by redesignating paragraphs (1), (2), (3), and (4) as paragraphs (2), (3), (4), and (6), respectively; (2) by inserting before paragraph (2) (as so redesignated), the following: ``(1) Notice of rights.--A local educational agency receiving funds under this part shall ensure that each elementary school and secondary school (including secondary career and technical education schools) served by such agency posts on a publicly accessible website of the school or, if the school does not operate a website, widely disseminates to the public, a summary notice of the right of parents to information about their children's education as required under this Act, which shall be in an understandable format for parents and include, at minimum-- ``(A) the right (provided in accordance with the requirements of section 445(a)(2) of the General Education Provisions Act (20 U.S.C. 1232h(a)(2)) with respect to such local educational agency) to review, and make copies of, at no cost, the curriculum of their child's school; ``(B) the right to know if the State alters the State's challenging State academic standards; ``(C) the right to meet with each teacher of their child not less than twice during each school year in accordance with paragraph (5)(A); ``(D) the right to review the budget, including all revenues and expenditures, of their child's school; ``(E) the right to-- ``(i) a list of the books and other reading materials available in the library of their child's school; and ``(ii) inspect such books or other reading materials; ``(F) the right to information about all schools in which their child can enroll, including options for enrolling in or transferring to-- ``(i) other schools served by the local educational agency; ``(ii) charter schools; and ``(iii) schools served by a different local educational agency in the State; ``(G) the right to address the school board of the local educational agency; ``(H) the right to information about violent activity in their child's school; ``(I) the right to information about any plans to eliminate gifted and talented or college credit programs in the child's school, including Advanced Placement and dual-enrollment classes; ``(J) the right to review any professional development materials; ``(K) the right to know if their child is not grade-level proficient in reading or language arts at the end of the third grade as described in subsection (c)(10); ``(L) the right to know if a school employee or contractor acts to-- ``(i) change a minor child's gender markers, pronouns, or preferred name; or ``(ii) allow a child to change the child's sex-based accommodations, including locker rooms or bathrooms; ``(M) the right to know if-- ``(i) a school employee or contractor acts to-- ``(I) treat, advise, or address the cyberbullying of a student; ``(II) treat, advise, or address the bullying or hazing of a student; ``(III) treat, advise, or address a student's mental health, suicidal ideation, or instances of self-harm; ``(IV) treat, advise, or address a specific threat to the safety of a student; ``(V) treat, advise, or address the possession or use of drugs and other controlled substances; or ``(VI) treat, advise, or address an eating disorder; or ``(ii) a child brings a weapon to school; ``(N) the right to the notice described in subsection (c)(11) before a person speaks (in-person or virtually) to their child in a class, school assembly, or any other school-sponsored event; ``(O) the right to be informed of the total number of school counselors in their child's school; ``(P) the right to know if their child's school operates, sponsors, or facilitates athletic programs or activities that permit an individual whose biological sex is male to participate in an athletic program or activity that is designated for individuals whose biological sex is female; ``(Q) the right to know if their child's school allows an individual whose biological sex is male to use restrooms or changing rooms designated for individuals whose biological sex is female; and ``(R) the right to timely notice of any major cyberattack against their child's school that may have compromised student or parent information.''; (3) in paragraph (2)(B) (as redesignated by paragraph (1))-- (A) by redesignating clause (i) and clause (ii) as subclause (I) and subclause (II), respectively; (B) by striking ``(B) Additional information.--'' and inserting: ``(B) Additional information.-- ``(i) In general.--''; and (C) by adding at the end the following: ``(ii) School library.--A local educational agency receiving funds under this part shall ensure that each elementary school and secondary school (including secondary career and technical education schools) served by such agency provides the parents of each child who is a student in such school-- ``(I) at the beginning of each school year, a list of books and other reading materials available in the library of such school; and ``(II) the opportunity to inspect such books and other reading materials. ``(iii) Violent activity.--A local educational agency receiving funds under this part shall ensure that each elementary school and secondary school (including secondary career and technical education schools) served by such agency provides the parents of each child who is a student in such school timely notification of any violent activity occurring on school grounds or at school-sponsored activities in which one or more individuals suffer injuries (including whether such agency is aware of videos or recordings of such violent activity), except that such notification shall not contain names or the grade level of any students involved in the activity. ``(iv) Gifted and talented programs.--A local educational agency receiving funds under this part shall ensure that each elementary school and secondary school (including secondary career and technical education schools) served by such agency provides the parents of each child who is a student in such school timely notification of any plan to eliminate gifted and talented or college credit programs in such school, including Advanced Placement and dual-enrollment classes. ``(v) School counselors.--A local educational agency receiving funds under this part shall ensure that each elementary school and secondary school (including secondary career and technical education schools) served by such agency provides the parents of each child who is a student in such school the information described in paragraph (1)(O). ``(vi) Enrollment options.--A local educational agency receiving funds under this part shall ensure that each elementary school and secondary school (including secondary career and technical education schools) served by such agency provides the parents of each child who is a student in such school the information described in paragraph (1)(F), including the enrollment and transfer options described in such paragraph. ``(vii) School employee or contractor actions.--A local educational agency receiving funds under this part shall ensure that each elementary school and secondary school (including secondary career and technical education schools) served by such agency notifies the parents of any child who is a student in such school if a school employee or contractor takes, with respect to such child, any action described in clause (i) or (ii) of paragraph (1)(L). ``(viii) School and student safety.--A local educational agency receiving funds under this part shall ensure that each elementary school and secondary school (including secondary career and technical education schools) served by such agency notifies-- ``(I) the parents of any child who is a student in such school if a school employee or contractor takes, with respect to such child, any action described in clause (i) of paragraph (1)(M); and ``(II) the parents of each child who is a student in such school if any child takes the action described in clause (ii) of paragraph (1)(M). ``(ix) Professional development materials.--A local educational agency receiving funds under this part shall ensure that each elementary school and secondary school (including secondary career and technical education schools) served by such agency provides the parents of each child who is a student in such school the opportunity to review professional development materials to ensure the parental right described in paragraph (1)(J). ``(x) Athletic programs or activities.--A local educational agency receiving funds under this part shall ensure that each elementary school and secondary school (including secondary career and technical education schools) served by such agency provides the parents of each child who is a student in such school the information described in paragraph (1)(O). ``(xi) Accommodations.--A local educational agency receiving funds under this part shall ensure that each elementary school and secondary school (including secondary career and technical education schools) served by such agency provides the parents of each child who is a student in such school the information described in paragraph (1)(O). ``(xii) Cyberattacks.--A local educational agency receiving funds under this part shall ensure that each elementary school and secondary school (including secondary career and technical education schools) served by such agency provides the parents of each child who is a student in such school notifications described in paragraph (1)(O).''; and (4) by inserting after paragraph (4) (as redesignated by paragraph (1)) the following: ``(5) Transparency.--A local educational agency receiving funds under this part shall provide the parents of each child who is a student in an elementary school or secondary school (including secondary career and technical education schools) served by such agency-- ``(A)(i) the opportunity to meet in-person or virtually via videoconference with each teacher of such child not less than twice during each school year; and ``(ii) a notification, at the beginning of each school year, of the opportunity for such meetings, including the option to attend such meetings virtually via videoconference; and ``(B) the opportunity to address the school board of such local educational agency on issues impacting the education of children in such agency and on any violations of the rights specified in paragraph (1).''. SEC. 105. SENSE OF CONGRESS ON FIRST AMENDMENT RIGHTS. (a) In General.--Title VIII of the Elementary and Secondary Education Act of 1965 (20 U.S.C. 7801 et seq.) is amended-- (1) by redesignating section 8549C as section 8549D; and (2) by inserting after section 8549B the following new section: ``SEC. 8549C. SENSE OF CONGRESS ON FIRST AMENDMENT RIGHTS. ``(a) Findings.--Congress finds the following: ``(1) The right of parents to educate their children is a pre-political natural right that the U.S. Supreme Court has recognized as `beyond debate' and rooted in the `history and culture of Western civilization'. ``(2) Parents have a First Amendment right to express their opinions on decisions made by State and local education leaders. ``(3) States and local educational agencies should empower parents to communicate regularly with Federal, State, and local policymakers and educators regarding the education and well- being of their children. ``(4) Transparent and cooperative relationships between parents and schools have significant and long-lasting positive effects on the development of children. ``(5) Parents' concerns over content and pedagogy deserve to be heard and fully considered by school professionals. ``(6) Parent and other community input about schools that is presented in a lawful and appropriate manner should always be encouraged. ``(7) Educators, policymakers, elected officials, Executive Branch officials and employees, and other stakeholders should never seek to use law enforcement to criminalize the lawfully expressed concerns of parents about their children's education, but should never hesitate to contact public safety officials if there is a credible threat to the safety and security of students, parents, educators, policymakers, elected officials, executive branch officials or employees, or other stakeholders, school faculty, or staff. ``(b) Sense of Congress.--It is the sense of Congress that-- ``(1) the First Amendment guarantees parents and other stakeholders the right to assemble and express their opinions on decisions affecting their children and communities, and that educators and policymakers should welcome and encourage that engagement and consider that feedback when making decisions; and ``(2) parents have a fundamental right, protected by the U.S. Constitution, to direct the education of their children, and the strict scrutiny test used by courts to evaluate cases concerning fundamental rights is the correct standard of review for government actions that interfere with the right of parents to educate their children.''. (b) Table of Contents.--The table of contents in section 2 of the Elementary and Secondary Education Act of 1965 is amended-- (1) by striking the item relating to section 8549C; and (2) by inserting after the item relating to section 8549B the following: Sec. 8549C. Sense of Congress on First Amendment Rights. Sec. 8549D. Technical assistance. SEC. 106. DEFINITION OF SECONDARY CAREER AND TECHNICAL EDUCATION SCHOOL. Section 8101 the Elementary and Secondary Education Act of 1965 (20 U.S.C. 7801) is amended-- (1) by redesignating paragraphs (45) through (52) as paragraphs (46) through (53), respectively; and (2) by inserting after paragraph (44) the following new paragraph: ``(45) Secondary career and technical education school.-- The term `secondary career and technical education school' means a secondary school (including secondary career and technical education schools) that is an area career and technical education school described in subparagraph (A) or (B) of paragraph (3) of section 3 of the Carl D. Perkins Career and Technical Education Act of 2006 (20 U.S.C. 2032(3)(A); (B)).''. TITLE II--AMENDMENTS TO FERPA AND PPRA SEC. 201. AMENDMENTS TO THE FAMILY EDUCATIONAL RIGHTS AND PRIVACY ACT OF 1974. (a) Enforcement.--Section 444(f) of the General Education Provisions Act (20 U.S.C. 1232g) (also known as the ``Family Educational Rights and Privacy Act of 1974'') (20 U.S.C. 1232g(f)) is amended by adding at the end the following: ``The Secretary shall comply with the reporting requirement under section 445(e)(2)(C)(ii) with respect to the enforcement actions taken under this subsection to ensure compliance with this section.''. (b) Prohibition on Educational Agencies or Institutions Acting as an Agent of a Parent.--Section 444 of the General Education Provisions Act (20 U.S.C. 1232g) (also known as the ``Family Educational Rights and Privacy Act of 1974'') is amended by adding at the end the following: ``(k) Prohibition on Educational Agencies or Institutions Acting as Agent of a Parent for Use of Technology.--An educational agency or institution may not act as the agent of a parent of a student in attendance at a school of such agency or at such institution for purposes of providing verifiable parental consent for the use of technology in the classroom for purposes of educating the student without providing notice and an opportunity for the parent to object to the use of such technology. ``(l) Prohibition on Educational Agencies or Institutions Acting as Agent of a Parent for Vaccines.--An educational agency or institution may not act as the agent of a parent of a student in attendance at a school of such agency or at such institution for purposes of providing verifiable parental consent for a vaccination.''. (c) Prohibition on Sale of Information for Commercial Purposes.-- Section 444 of the General Education Provisions Act (20 U.S.C. 1232g) (also known as the ``Family Educational Rights and Privacy Act of 1974''), as amended by this section, is further amended by adding at the end the following: ``(m) Prohibition on Sale of Information for Commercial Purposes.-- ``(1) In general.--Except as provided in paragraph (2), no educational agency or institution or authorized representative of such agency or institution may sell student information for commercial or financial gain. ``(2) Exceptions.--The prohibition described in paragraph (1) shall not apply to products sold to students by or on behalf of the educational agency or institution, such as yearbooks, prom tickets, and school pictures.''. (d) Parental Consultation.--Section 444 of the General Education Provisions Act (20 U.S.C. 1232g) (also known as the ``Family Educational Rights and Privacy Act of 1974''), as amended by this section, is further amended by adding at the end the following: ``(n) Parental Consultation.--In developing a privacy policy or procedure, an educational agency or institution shall engage meaningfully with parents of students in attendance at the schools served by such agency or institution.''. (e) Disclosure of Information.--Section 444 of the General Education Provisions Act (20 U.S.C. 1232g) (also known as the ``Family Educational Rights and Privacy Act of 1974''), as amended by this section, is further amended by adding at the end the following: ``(o) Disclosure of Information.--An educational agency or institution or authorized representative of such agency or institution shall, upon request from a parent of a student, disclose to such parent the identity of any individual or entity with whom information is shared from the education record of the student or any response of the student to a survey.''. SEC. 202. PROTECTION OF PUPIL RIGHTS. (a) Availability for Inspection by Parents or Guardians.--Section 445(a) of the General Education Provisions Act (20 U.S.C. 1232h(a)) is amended to read as follows: ``(a) Availability for Inspection by Parents or Guardians.--A local educational agency (as such term is defined in subsection (c)(6)(C)) that receives funds under any applicable program shall ensure the following: ``(1) Information available.--Each of the following shall be available for inspection by the parents or guardians of the children in attendance at the schools served by such agency, and the availability of each of the following for inspection shall not be conditioned on any requirement that such parents or guardians sign a nondisclosure agreement: ``(A) All instructional materials, including teacher's manuals, films, tapes, or other supplementary material which will be used in such school or in connection with any survey, analysis, or evaluation. ``(B) Any books or other reading materials made available to students in such school or through the school library of such school. ``(C) Any professional development materials. ``(2) Comment periods for parents.-- ``(A) In general.--The agency shall provide comment periods during which parents or guardians of the children in attendance at the schools served by the agency may inspect and provide feedback on any of the materials referred to in paragraph (1) that-- ``(i) are expected to be used to teach such children during the three weeks following the comment period; or ``(ii) were used to teach such children during preceding portions of the school year. ``(B) Frequency and duration.--The comment periods described in subparagraph (A) shall be held not less frequently than once every three weeks during the school year and each comment period shall be not less than three school days in duration.''. (b) Single Issue Notification.--Section 445(b) of the General Education Provisions Act (20 U.S.C. 1232h) is amended-- (1) by striking ``prior consent of the student'' and inserting ``prior written consent of the student''; and (2) by inserting ``, which is provided specifically for such survey, analysis, or evaluation'' before the period at the end. (c) Development and Adoption of Local Policies.--Section 445(c) of the General Education Provisions Act (20 U.S.C. 1232h(c)) is amended-- (1) in the subsection heading, by striking ``Physical'' and inserting ``Medical''; (2) in paragraph (1)-- (A) in the matter preceding subparagraph (A), by striking ``in consultation with parents'' and inserting ``in consultation with parents in accordance with paragraph (2)(A)''; (B) in subparagraph (C), by amending clause (i) to read as follows: ``(i) The right of a parent of a student to inspect, upon the request of the parent, any instructional material used as part of the educational curriculum for the student, and any books or other reading materials made available to the student in a school served by the agency or through the school library; and''; (C) by amending subparagraph (D) to read as follows: ``(D) The administration of medical examinations or screenings that the school or agency may administer to a student, including-- ``(i) prior notice to parents of such a medical examination or screening, and receipt of consent from parents before administering such an examination or screening; and ``(ii) in the event of an emergency that requires a medical examination or screening without time for parental notification and consent, the procedure for promptly notifying parents of such examination or screening subsequent to such examination or screening.''; and (D) by amending subparagraph (E) to read as follows: ``(E) The prohibition on the collection, disclosure, or use of personal information collected from students for the purpose of marketing or for selling that information (or otherwise providing that information to others for that purpose), other than for a legitimate educational purpose to improve the education of students as described in paragraph (4), and the arrangements to protect student privacy that are provided by the agency in the event of such collection, disclosure, or use for such a legitimate educational purpose.''. (d) Parental Notification.--Paragraph (2) of section 445(c) of the General Education Provisions Act (20 U.S.C. 1232h(c)) is amended-- (1) in the paragraph heading, by inserting ``consultation and'' before ``notification''; (2) by redesignating subparagraphs (A) through (C) as subparagraphs (B) through (D), respectively; (3) in subparagraph (B) (as so redesignated)-- (A) in clause (i), by striking ``and'' at the end; (B) by amending clause (ii) to read as follows: ``(ii) in the case of an activity described in clause (i) or (iii) of subparagraph (D), offer an opportunity and clear instructions for the parent (or in the case of a student who is an adult or emancipated minor, the student) to opt the student out of participation in such activity;''; and (C) by adding at the end the following: ``(iii) in the case of an activity described in subparagraph (D)(i), a description of how such activity is for a legitimate educational purpose to improve the education of students as described in paragraph (4); and ``(iv) not require a student to submit to a survey described in subparagraph (D)(ii) without the prior written consent of the student (if the student is an adult or emancipated minor), or in the case of an unemancipated minor, without the prior written consent of the parent, which is provided specifically for such survey.''; (4) by inserting before subparagraph (B) (as so amended and redesignated), the following: ``(A) Parental consultation.--The parental consultation required for the purpose of developing and adopting policies under paragraphs (1) and (3) by a local educational agency shall ensure that such policy is developed with meaningful engagement by parents of students enrolled in schools served by that agency.''; and (5) in subparagraph (D) (as redesignated by paragraph (2))-- (A) by amending clause (i) to read as follows: ``(i) Activities involving the collection, disclosure, or use of personal information collected from students for a legitimate educational purpose to improve the education of students as described in paragraph (4).''; and (B) in clause (iii), by striking ``invasive physical'' and inserting ``medical''. (e) Updates to Existing Policies.--Paragraph (3) of section 445(c) of the General Education Provisions Act (20 U.S.C. 1232h(c)) is amended to read as follows: ``(3) Updates to existing policies.-- ``(A) In general.--Not later than 180 days after the date of enactment of the Parents Bill of Rights Act, a local educational agency that receives funds under any applicable program shall-- ``(i) review policies covering the requirements of paragraph (1) as in effect on the day before such date of enactment; and ``(ii) develop and update such policies to reflect the changes made to paragraph (1) by the amendments made by the Parents Bill of Rights Act. ``(B) Consultation and notification.--In developing and updating the policies under subparagraph (A), the agency shall comply with the consultation and notification requirements under paragraph (2).''. (f) Exceptions.--Paragraph (4)(A) of section 445(c) of the General Education Provisions Act (20 U.S.C. 1232h(c)) is amended by amending the matter preceding clause (i) to read as follows: ``(A) Educational products or services.--For purposes of paragraph (1)(E), the collection, disclosure, or use of personal information collected from students for a legitimate educational purpose to improve the education of students means the exclusive purpose of developing, evaluating, or providing educational products or services for, or to, students or schools, such as the following:''. (g) Definitions.--Paragraph (6) of section 445(c) of the General Education Provisions Act (20 U.S.C. 1232h(c)) is amended-- (1) by amending subparagraph (B) to read as follows: ``(B) Medical examination or screening.--The term `medical examination or screening' means any medical examination or screening that involves the exposure of private body parts, or any act during such examination or screening that includes incision, insertion, or injection into the body, or a mental health or substance use disorder screening, except that such term does not include a hearing, vision, or scoliosis screening, or an observational screening carried out to comply with child find obligations under the Individuals with Disabilities Education Act (20 U.S.C. 1400 et seq.).''; and (2) in subparagraph (E)-- (A) in clause (iii), by striking ``or''; (B) in clause (iv), by striking the period at the end and inserting ``; or''; and (C) by adding at the end the following: ``(v) an email address.''. (h) Enforcement and Reporting.--Subsection (e) of section 445 of the General Education Provisions Act (20 U.S.C. 1232h) is amended to read as follows: ``(e) Enforcement and Reporting.-- ``(1) Enforcement.--The Secretary shall take such action as the Secretary determines appropriate to enforce this section, except that action to terminate assistance provided under an applicable program shall be taken only if the Secretary determines that-- ``(A) there has been a failure to comply with such section; and ``(B) compliance with such section cannot be secured by voluntary means. ``(2) Reporting.-- ``(A) Local educational agencies.--On an annual basis, each local educational agency (as such term is defined in subsection (c)(6)(C)) that receives funds under any applicable program shall-- ``(i) without identifying any personal information of a student or students, report to the State educational agency any enforcement actions or investigations carried out for the preceding school year to ensure compliance with this section; and ``(ii) publish such information on its website or through other public means used for parental notification if the agency does not have a website. ``(B) States.--On an annual basis, each State educational agency shall provide to the Secretary a report, with respect to the preceding school year, that includes all actions local educational agencies have reported under subparagraph (A), and a description of the enforcement actions the State educational agency took to ensure parents' rights were protected. ``(C) Secretary.--Not later than 1 year after the date of enactment of the Parents Bill of Rights Act, and annually thereafter, the Secretary shall submit to the Committee on Education and the Workforce of the House of Representatives and the Committee on Health, Education, Labor, and Pensions of the Senate-- ``(i) the reports received under subparagraph (B); and ``(ii) a description of the enforcement actions taken by the Secretary under this subsection and section 444(f) to ensure full compliance with this section and section 444, respectively.''. TITLE III--PROHIBITION ON FEDERAL INVOLVEMENT IN CURRICULUM SEC. 301. RULE OF CONSTRUCTION. Nothing in this Act may be construed to authorize any department, agency, officer, or employee of the United States to exercise any direction, supervision, or control over the curriculum, program of instruction, administration, or personnel of any educational institution, school, or school system. TITLE IV--GENDER MARKERS, PRONOUNS, AND PREFERRED NAMES ON SCHOOL FORMS SEC. 401. REQUIREMENT RELATED TO GENDER MARKERS, PRONOUNS, AND PREFERRED NAMES ON SCHOOL FORMS. As a condition of receiving Federal funds from the Department of Education, any elementary school (as such term is defined in section 8101 of the Elementary and Secondary Education Act of 1965 (20 U.S.C. 7801)) or school that consists of only middle grades (as such term is defined in such section), that receives such Federal funds shall be required to obtain parental consent before-- (1) changing a minor child's gender markers, pronouns, or preferred name on any school form; or (2) allowing a child to change the child's sex-based accommodations, including locker rooms or bathrooms. TITLE V--ACCESS TO SCHOOL BROADBAND SEC. 501. SENSE OF CONGRESS. It is the sense of Congress that all public elementary and public secondary school (including public secondary career and technical education school) students should have access to broadband. TITLE VI--SENSE OF CONGRESS SEC. 601. SENSE OF CONGRESS. It is the sense of Congress that all public elementary school and secondary school (including public secondary career and technical education school) students should have opportunities to learn the history of the Holocaust and anti-Semitism. TITLE VII--GAO REPORT SEC. 701. GAO REPORT. Not later than one year after the date of enactment of this Act, the Comptroller General of the United States shall submit to the Committee on Education and the Workforce and the Committee on Appropriations of the House of Representatives and the Committee on Health, Education, Labor, and Pensions and the Committee on Appropriations of the Senate a report that evaluates and analyzes the impact of this Act, and the amendments made by this Act, on-- (1) protecting parents' rights in the education of their children; and (2) costs to State educational agencies, local educational agencies, elementary schools, and secondary schools (as such terms are defined in section 8101 of the Elementary and Secondary Education Act of 1965 (20 U.S.C. 7801)). TITLE VIII--RULE OF CONSTRUCTION ON STUDENT ACCESS TO BOOKS AND OTHER READING MATERIALS SEC. 801. RULE OF CONSTRUCTION ON STUDENT ACCESS TO BOOKS AND OTHER READING MATERIALS. Nothing in this Act, or the amendments made by this Act, shall be construed as authorizing or granting parents the right or ability to deny any student who is not their child from accessing any books or other reading materials that are otherwise available in the library of their child's school. TITLE IX--INAPPLICABILITY TO NON-PUBLIC SCHOOLS SEC. 901. RULE OF CONSTRUCTION. Nothing in this Act may be construed to impose any requirements on non-public elementary or secondary schools. SEC. 902. SENSE OF CONGRESS. It is the sense of Congress that local educational agencies do not have the authority to exercise any direction, supervision, or control over the curriculum or program of instruction of non-public elementary or secondary schools. Passed the House of Representatives March 24, 2023. Attest: CHERYL L. JOHNSON, Clerk.

---
snapshot_id: 3613dc61-25c5-5c44-ab7e-d48d1068b992
source_kind: own-site (the person's own site or account)
url: https://www.erinhouchin.com/issues

Erin Houchin on the Issues &mdash; Erin Houchin for Congress 0 Skip to Content ABOUT ISSUES VOLUNTEER CONTACT DONATE Open Menu Close Menu ABOUT ISSUES VOLUNTEER CONTACT DONATE Open Menu Close Menu ABOUT ISSUES VOLUNTEER CONTACT DONATE ERIN ON THE ISSUES SECURE THE BORDER: Joe Biden let over 10 million individuals illegally invade our country—that we know of. These illegals outnumber the population of Indiana by three million people. Erin visited the border in Texas twice, and witnessed the chaos and destruction firsthand. She fully supports President Trump’s efforts to restore border security—by backing law enforcement, finishing the wall, and deporting criminal illegal aliens to protect American communities. STAND WITH ISRAEL: Erin stands firmly with Israel, our nation’s strongest ally in the Middle East. Even before Hamas’ barbaric terrorist attack on October 7, 2023, she has vocally supported Israel’s right to defend itself, and the right of Israelis to live. Erin believes that we as a nation have a moral obligation to unequivocally defend Israel. She is committed to standing resolute against anti-Semitism in all forms at home and abroad and advocating for the U.S. to cut all aid to any sponsors of terrorism. CUT GOVERNMENT SPENDING: Erin believes our government takes too much of your money, and spends too much. Just as families across Indiana balance their budgets, she believes the federal government should too. It's no question that our growing national debt is a national security concern. Erin is a committed fiscal conservative and has the track record to prove it, and as a champion for Indiana’s Balanced Budget Amendment, she is bringing that same fiscal discipline to Washington. PROTECT THE UNBORN: Erin is pro-life and always has been. She has been a steadfast leader in the fight for the unborn, consistently advocating for the prohibition of late-term abortions, and resources and care for mothers in need. In Congress, she continues to be a voice for the voiceless. National Right to Life and the Susan B. Anthony List have endorsed her, she has earned an A+ rating from the SBA List, and had a consistent 100% pro-life voting record as a member of the Indiana State Senate. STAND FOR CONSERVATIVE VALUES: The strong conservative values instilled in Erin growing up in Scottsburg have become a foundational part of who she is. A strong defender of the Second Amendment, the Right to Life, and the right to worship freely, Erin will always fight for our conservative freedoms and liberties. She will continue standing steadfast for an America First Agenda that allows us to live safely and freely. PROTECT PARENTAL RIGHTS: Parents should be in the driver's seat of their children's education. The pandemic opened American parents' eyes to the reality of our public school system, and millions of parents didn't like what they saw. As a mother of three, Erin knows that parents are the primary stakeholders in their children's education. That's why she voted to pass the Parents Bill of Rights and will continue to support parents in this ongoing effort for transparency and a seat at the table as we prepare the next generation for success. SUPPORT OUR VETERANS: America is blessed with the greatest fighting force in the world, and Erin deeply appreciates our servicemen and women and their families. She is committed to improving the welfare and quality of life for our veterans and their families, our active-duty military members and their spouses. Erin is committed to ensuring we keep our promises to those who fought to defend our freedoms and never let them down. UPHOLD LAW & ORDER: Hoosiers are fortunate to have some of the most dedicated and talented law enforcement and public safety officials in the country, and it’s our duty to have their backs. These brave men and women should be protected by lawmakers instead of being met with hostility and resentment. Erin will always fight to ensure our officers have the necessary resources to do their jobs effectively and safely, and they have the support and compensation they deserve. Erin will never allow radical left-wing politicians to defund the police. CREATE JOBS: Erin knows the best way to create jobs and grow the economy is to get the government out of the way and let small business owners do what they do best – innovate and create new jobs. Indiana has one of the best economies in the nation, a direct result of our conservative values. As a small business owner, Erin continues the fight to cut bureaucratic red tape and support limited government while working to cut taxes, promote free markets, and control government spending. PROTECT THE SECOND AMENDMENT: Erin is a firm believer that the Second Amendment is one of our most important freedoms, and she understands the importance of protecting our constitutional right to bear arms. The founders saw the crucial importance of giving citizens the right to protect themselves, and we must all protect that right. CONTRIBUTE PAID FOR BY HOUCHIN FOR CONGRESS ABOUT | ISSUES | CONTACT Privacy Policy