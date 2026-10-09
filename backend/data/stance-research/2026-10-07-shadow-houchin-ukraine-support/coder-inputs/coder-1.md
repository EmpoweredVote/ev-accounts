You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-houchin-ukraine-support/labels/coder-1.json. Write JSON only, matching
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

### topic_key: ukraine-support
topic_id: 24e9212c-b011-422a-865c-093e35050901  served_revision_id: 9ee7ecb7-fd99-429a-a37d-eff58a381983
Question: What level of military and financial support should be provided to Ukraine?
  1. significantly increase military and financial aid to Ukraine.
  2. continue providing current levels of military and economic aid to help Ukraine defend itself.
  3. provide limited humanitarian aid to Ukraine while encouraging diplomatic negotiations to end the war.
  4. reduce aid to Ukraine and focus American resources on domestic priorities instead.
  5. end all aid to Ukraine immediately and stay completely out of the conflict.

#### Annex

# ukraine-support — served revision 9ee7ecb7-fd99-429a-a37d-eff58a381983 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. The season pin is an older revision
(`107d180d-…`); coders code the served text below.

**Question:** "What level of military and financial support should be provided to Ukraine?"

**Orientation:** standard. Rung 1 is the most support (a significant increase), rung 5 ends all aid.
The rungs order **how much aid**, and from rung 3 down, **what kind** (humanitarian only) and how far
the United States stays involved.

**Levels with a lever:** federal. Congress appropriates the aid and authorizes
transfers; state and local officials hold no lever.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "supplemental appropriation", "security assistance", "Ukraine Security Assistance
Initiative" (USAI), "presidential drawdown authority" (PDA), "Foreign Military Financing" (FMF),
"direct budget support", "economic support", "lend-lease", "frozen Russian assets", "humanitarian
assistance", "ceasefire", "peace talks", "negotiated settlement".

1. **"significantly increase military and financial aid to Ukraine."**
   - Means: send substantially more military and financial aid than now.
   - Operative clauses: [a] a significant increase; [b] military and financial aid.
   - Establishing evidence looks like: own words that call for more aid, or for aid larger or faster
     than current packages; a bill or amendment that adds aid above what is in force.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - "Until complete victory" is no longer part of this rung. A war-aim statement without an amount
     → not evidence for or against rung 1 _(proposed)_.
   - "Military and financial aid" is one clause with two forms: more **military** aid alone is
     enough _(ruled 2026-10-01)_.
   - Commonly confused with rung 2: see rung 2.

2. **"continue providing current levels of military and economic aid to help Ukraine defend
   itself."**
   - Means: keep aid at about the level it has been, without a large increase or a cut.
   - Operative clauses: [a] continue aid; [b] at current levels; [c] military and economic aid.
   - Establishing evidence looks like: a Yea on a Ukraine-specific aid bill **plus** own words that
     frame it as keeping support steady, not raising it. A Yea alone excludes rungs 3–5 but not rung
     1 → `direction-only` (V4: chair-shaped must exclude the adjacent rungs) _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1 because the rungs differ on **magnitude** ("current levels" vs
     "increase"). A Yea on a supplemental (H.R. 8035, 2024, codebook V4) does not show whether its
     size is "current" or an "increase" → BLANK `direction-only` without own words about the size
     _(ruled 2026-10-01)_.

3. **"provide limited humanitarian aid to Ukraine while encouraging diplomatic negotiations to end
   the war."**
   - Means: humanitarian help only, no weapons, and a push for talks to end the war.
   - Operative clauses: [a] limited humanitarian aid (and so no military aid); [b] encourage
     negotiations to end the war.
   - Establishing evidence looks like: own words or a record that support humanitarian aid while
     opposing military aid, **and** call for negotiations. Compound: one side only →
     `compound-partial` (V4.2).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because a call for talks is common **beside** support for military
     aid. Talks plus continued weapons is not rung 3 _(proposed)_.

4. **"reduce aid to Ukraine and focus American resources on domestic priorities instead."**
   - Means: cut aid, but not end it, and spend the money at home.
   - Operative clauses: [a] reduce aid; [b] direct the resources to domestic priorities.
   - Establishing evidence looks like: own words or an amendment that cuts aid and moves the money to a
     domestic purpose. Compound: one side only → `compound-partial` (V4.2) _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because a Yea on a **cut** does not show the person wants some aid
     to stay. Sponsoring a partial cut sets the amount; voting for one does not exclude rung 5 →
     `direction-only` without own words _(proposed)_.

5. **"end all aid to Ukraine immediately and stay completely out of the conflict."**
   - Means: stop every kind of aid now, and take no part in the war at all.
   - Operative clauses: [a] end all aid; [b] immediately; [c] stay completely out of the conflict.
   - Establishing evidence looks like: own words or an amendment that strikes all Ukraine aid,
     **plus** own words against any other involvement. [c] is an absence clause (V4.2) → without
     it, `compound-partial`.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A **No** on an aid bill excludes rungs 1–2 only; it does not separate 3, 4 and 5 →
     `direction-only` (V4.1).

**Hard cases:**
- **Combined packages.** Ukraine aid inside a package with aid for other countries, border measures
  or other spending → V4 `multi-subject`; a Yea proves direction at most. The defense authorization
  bill → `multi-subject`.
- **Condemnation and solidarity resolutions** name no aid level → V4 `rhetorical` or `adjacent`.
- **Sanctions on Russia** and **use of frozen Russian assets** are not U.S. aid levels → `adjacent`
  _(proposed)_.
- **Oversight and audit measures** (an inspector general for Ukraine aid) say how aid is tracked,
  not how much → `adjacent` _(proposed)_.
- **Near-unanimous votes** (codebook V4) cannot carry the chair alone.


## Sources

---
snapshot_id: 659538c3-72c6-5b15-ba80-40067b8b4c6f
source_kind: public-record
url: https://clerk.house.gov/Votes/2024151

Office of the Clerk, U.S. House of Representatives Find Your Representative Search Office of the Clerk Toggle navigation Search Office of the Clerk Search button Legislative Information Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions 119th Congress, 2nd Session House Not In Session Next Session: October 9th, 2026 at 12:30 PM House Floor Proceedings Watch live.house.gov Additional Resources Votes Legacy View - 2024 119th Congress Nominees Statistics of the 2024 Congressional Election Final House Calendar (118th Congress) Résumé of Congressional Activity Legislative Search Congressional Record U.S. Senate House Schedule Bills This Week House Voting Days Member Information Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Republicans 218 218 Democrats 214 214 Independents 1 1 Vacancies 2 2 Republican Leadership Rep. Mike Johnson Speaker of the House Rep. Steve Scalise Majority Leader Rep. Tom Emmer Majority Whip Rep. Lisa C. McClain Republican Conference Chair Rep. Jay Obernolte Republican Policy Committee Chair Democratic Leadership Rep. Hakeem S. Jeffries Minority Leader Rep. Katherine M. Clark Minority Whip Rep. Pete Aguilar Democratic Caucus Chair Rep. Ted Lieu Democratic Caucus Vice Chair Additional Resources Find Your Representative Official List of Members by State Official Member Telephone Directory Duplicate and Similar Names of Members Terms of Service Mailing Labels [ MS Word | Text File ] Member Data [ Excel | XML | User Guide ] Biographical Directory Members on Congress.gov Committee Information COMMITTEE INFORMATION COMMITTEE PROFILES Agriculture Appropriations Armed Services Budget Education and Workforce Energy and Commerce Ethics Financial Services Foreign Affairs Homeland Security House Administration Judiciary Natural Resources Oversight and Government Reform Rules Science, Space, and Technology Small Business Transportation and Infrastructure Veterans' Affairs Ways and Means Select Intelligence Select Strategic Competition Joint Economic Joint Library Joint Printing Joint Taxation Additional Resources Official List of Members with Committee Assignments Official List of Standing Committees and Subcommittees Committee Repository Committee Reports Committees on Congress.gov Committee Data [ Excel ] Disclosures Disclosures PUBLIC DISCLOSURE Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications Additional Resources Lobbying Disclosures Public Laws Lobbying Disclosure Act About the Clerk About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office The Clerk of the House The Honorable Kevin F. McCumber Clerk of the U.S. House of Representatives Deputy Clerk Michelle H. Reinshuttle Deputy Clerk Contact Information Mailing Address U.S. Capitol Room H154 Washington, DC 20515&ndash;6601 Telephone Number (202) 225&ndash;7000 Office Hours 9:00 AM&ndash;6:00 PM, Monday&ndash;Friday Additional Resources Artificial Intelligence Use Case Inventory [ USHouse-Clerk-1: Comparative Print Suite ] 119th Congress, 2nd Session Back to Previous Page Roll Call 151 | Bill Number: H. R. 8035 Share XML View | HTML View Apr 20, 2024, 01:48 PM | 118th Congress, 2nd Session Vote Question: On Passage Ukraine Security Supplemental Appropriations Act, 2024 Vote Type: Yea-And-Nay Status: Passed VOTES yea: 311 nay: 112 present: 1 not voting: 7 Remote Voting by Proxy Votes by party votes by party Party Yeas Nays Present Not Voting Republican 101 112 1 4 Democratic 210 0 0 3 Independent 0 0 0 0 Total 311 112 1 7 All votes Keyword Name Party All Parties Republican Democratic Independent State All States Votes All Votes YEA/AYE NAY/NO PRESENT NOT VOTING All votes Representative Party State Vote Adams Adams Democratic North Carolina NC Yea Aderholt Aderholt Republican Alabama AL Yea Aguilar Aguilar Democratic California CA Yea Alford Alford Republican Missouri MO Nay Allen Allen Republican Georgia GA Nay Allred Allred Democratic Texas TX Yea Amo Amo Democratic Rhode Island RI Yea Amodei Amodei Republican Nevada NV Nay Armstrong Armstrong Republican North Dakota ND Nay Arrington Arrington Republican Texas TX Nay Auchincloss Auchincloss Democratic Massachusetts MA Yea Babin Babin Republican Texas TX Nay Bacon Bacon Republican Nebraska NE Yea Baird Baird Republican Indiana IN Nay Balderson Balderson Republican Ohio OH Nay Balint Balint Democratic Vermont VT Yea Banks Banks Republican Indiana IN Nay Barr Barr Republican Kentucky KY Yea Barragán Barragan Democratic California CA Yea Bean (FL) Bean (FL) Republican Florida FL Nay Beatty Beatty Democratic Ohio OH Yea Bentz Bentz Republican Oregon OR Yea Bera Bera Democratic California CA Yea Bergman Bergman Republican Michigan MI Nay Beyer Beyer Democratic Virginia VA Yea Bice Bice Republican Oklahoma OK Yea Biggs Biggs Republican Arizona AZ Nay Bilirakis Bilirakis Republican Florida FL Nay Bishop (GA) Bishop (GA) Democratic Georgia GA Yea Bishop (NC) Bishop (NC) Republican North Carolina NC Nay Blumenauer Blumenauer Democratic Oregon OR Yea Blunt Rochester Blunt Rochester Democratic Delaware DE Yea Boebert Boebert Republican Colorado CO Nay Bonamici Bonamici Democratic Oregon OR Yea Bost Bost Republican Illinois IL Nay Bowman Bowman Democratic New York NY Yea Boyle (PA) Boyle (PA) Democratic Pennsylvania PA Yea Brecheen Brecheen Republican Oklahoma OK Nay Brown Brown Democratic Ohio OH Yea Brownley Brownley Democratic California CA Yea Buchanan Buchanan Republican Florida FL Yea Bucshon Bucshon Republican Indiana IN Yea Budzinski Budzinski Democratic Illinois IL Yea Burchett Burchett Republican Tennessee TN Nay Burgess Burgess Republican Texas TX Yea Burlison Burlison Republican Missouri MO Nay Bush Bush Democratic Missouri MO Yea Calvert Calvert Republican California CA Yea Cammack Cammack Republican Florida FL Nay Caraveo Caraveo Democratic Colorado CO Yea Carbajal Carbajal Democratic California CA Yea Cárdenas Cardenas Democratic California CA Yea Carey Carey Republican Ohio OH Yea Carl Carl Republican Alabama AL Nay Carson Carson Democratic Indiana IN Yea Carter (GA) Carter (GA) Republican Georgia GA Yea Carter (LA) Carter (LA) Democratic Louisiana LA Yea Carter (TX) Carter (TX) Republican Texas TX Yea Cartwright Cartwright Democratic Pennsylvania PA Yea Casar Casar Democratic Texas TX Yea Case Case Democratic Hawaii HI Yea Casten Casten Democratic Illinois IL Yea Castor (FL) Castor (FL) Democratic Florida FL Yea Castro (TX) Castro (TX) Democratic Texas TX Yea Chavez-DeRemer Chavez-DeRemer Republican Oregon OR Yea Cherfilus-McCormick Cherfilus-McCormick Democratic Florida FL Yea Chu Chu Democratic California CA Yea Ciscomani Ciscomani Republican Arizona AZ Yea Clark (MA) Clark (MA) Democratic Massachusetts MA Yea Clarke (NY) Clarke (NY) Democratic New York NY Yea Cleaver Cleaver Democratic Missouri MO Yea Cline Cline Republican Virginia VA Nay Cloud Cloud Republican Texas TX Nay Clyburn Clyburn Democratic South Carolina SC Yea Clyde Clyde Republican Georgia GA Nay Cohen Cohen Democratic Tennessee TN Yea Cole Cole Republican Oklahoma OK Yea Collins Collins Republican Georgia GA Nay Comer Comer Republican Kentucky KY Nay Connolly Connolly Democratic Virginia VA Yea Correa Correa Democratic California CA Yea Costa Costa Democratic California CA Yea Courtney Courtney Democratic Connecticut CT Yea Craig Craig Democratic Minnesota MN Yea Crane Crane Republican Arizona AZ Nay Crawford Crawford Republican Arkansas AR Nay Crenshaw Crenshaw Republican Texas TX Yea Crockett Crockett Democratic Texas TX Yea Crow Crow Democratic Colorado CO Yea Cuellar Cuellar Democratic Texas TX Yea Curtis Curtis Republican Utah UT Yea D'Esposito D'Esposito Republican New York NY Yea Davids (KS) Davids (KS) Democratic Kansas KS Yea Davidson Davidson Republican Ohio OH Nay Davis (IL) Davis (IL) Democratic Illinois IL Yea Davis (NC) Davis (NC) Democratic North Carolina NC Yea De La Cruz De La Cruz Republican Texas TX Nay Dean (PA) Dean (PA) Democratic Pennsylvania PA Yea DeGette DeGette Democratic Colorado CO Yea DeLauro DeLauro Democratic Connecticut CT Yea DelBene DelBene Democratic Washington WA Yea Deluzio Deluzio Democratic Pennsylvania PA Yea DeSaulnier DeSaulnier Democratic California CA Yea DesJarlais DesJarlais Republican Tennessee TN Nay Diaz-Balart Diaz-Balart Republican Florida FL Yea Dingell Dingell Democratic Michigan MI Not Voting Doggett Doggett Democratic Texas TX Yea Donalds Donalds Republican Florida FL Nay Duarte Duarte Republican California CA Yea Duncan Duncan Republican South Carolina SC Nay Dunn (FL) Dunn (FL) Republican Florida FL Yea Edwards Edwards Republican North Carolina NC Yea Ellzey Ellzey Republican Texas TX Yea Emmer Emmer Republican Minnesota MN Yea Escobar Escobar Democratic Texas TX Yea Eshoo Eshoo Democratic California CA Yea Espaillat Espaillat Democratic New York NY Yea Estes Estes Republican Kansas KS Nay Evans Evans Democratic Pennsylvania PA Yea Ezell Ezell Republican Mississippi MS Nay Fallon Fallon Republican Texas TX Nay Feenstra Feenstra Republican Iowa IA Yea Ferguson Ferguson Republican Georgia GA Yea Finstad Finstad Republican Minnesota MN Nay Fischbach Fischbach Republican Minnesota MN Nay Fitzgerald Fitzgerald Republican Wisconsin WI Nay Fitzpatrick Fitzpatrick Republican Pennsylvania PA Yea Fleischmann Fleischmann Republican Tennessee TN Yea Fletcher Fletcher Democratic Texas TX Yea Flood Flood Republican Nebraska NE Yea Foster Foster Democratic Illinois IL Yea Foushee Foushee Democratic North Carolina NC Yea Foxx Foxx Republican North Carolina NC Yea Frankel, Lois Frankel, Lois Democratic Florida FL Yea Franklin, Scott Franklin, Scott Republican Florida FL Nay Frost Frost Democratic Florida FL Yea Fry Fry Republican South Carolina SC Nay Fulcher Fulcher Republican Idaho ID Nay Gaetz Gaetz Republican Florida FL Nay Gallagher Gallagher Republican Wisconsin WI Yea Gallego Gallego Democratic Arizona AZ Yea Garamendi Garamendi Democratic California CA Yea Garbarino Garbarino Republican New York NY Yea García (IL) Garcia (IL) Democratic Illinois IL Yea Garcia (TX) Garcia (TX) Democratic Texas TX Yea Garcia, Mike Garcia, Mike Republican California CA Yea Garcia, Robert Garcia, Robert Democratic California CA Yea Gimenez Gimenez Republican Florida FL Yea Golden (ME) Golden (ME) Democratic Maine ME Yea Goldman (NY) Goldman (NY) Democratic New York NY Yea Gomez Gomez Democratic California CA Yea Gonzales, Tony Gonzales, Tony Republican Texas TX Yea Gonzalez, Vicente Gonzalez, Vicente Democratic Texas TX Yea Good (VA) Good (VA) Republican Virginia VA Nay Gooden (TX) Gooden (TX) Republican Texas TX Nay Gosar Gosar Republican Arizona AZ Nay Gottheimer Gottheimer Democratic New Jersey NJ Yea Granger Granger Republican Texas TX Yea Graves (LA) Graves (LA) Republican Louisiana LA Nay Graves (MO) Graves (MO) Republican Missouri MO Yea Green (TN) Green (TN) Republican Tennessee TN Nay Green, Al (TX) Green, Al (TX) Democratic Texas TX Yea Greene (GA) Greene (GA) Republican Georgia GA Nay Griffith Griffith Republican Virginia VA Yea Grijalva Grijalva Democratic Arizona AZ Not Voting Grothman Grothman Republican Wisconsin WI Nay Guest Guest Republican Mississippi MS Nay Guthrie Guthrie Republican Kentucky KY Yea Hageman Hageman Republican Wyoming WY Nay Harder (CA) Harder (CA) Democratic California CA Yea Harris Harris Republican Maryland MD Nay Harshbarger Harshbarger Republican Tennessee TN Nay Hayes Hayes Democratic Connecticut CT Yea Hern Hern Republican Oklahoma OK Nay Higgins (LA) Higgins (LA) Republican Louisiana LA Nay Hill Hill Republican Arkansas AR Yea Himes Himes Democratic Connecticut CT Yea Hinson Hinson Republican Iowa IA Yea Horsford Horsford Democratic Nevada NV Yea Houchin Houchin Republican Indiana IN Yea Houlahan Houlahan Democratic Pennsylvania PA Yea Hoyer Hoyer Democratic Maryland MD Yea Hoyle (OR) Hoyle (OR) Democratic Oregon OR Yea Hudson Hudson Republican North Carolina NC Yea Huffman Huffman Democratic California CA Yea Huizenga Huizenga Republican Michigan MI Nay Hunt Hunt Republican Texas TX Not Voting Issa Issa Republican California CA Yea Ivey Ivey Democratic Maryland MD Yea Jackson (IL) Jackson (IL) Democratic Illinois IL Yea Jackson (NC) Jackson (NC) Democratic North Carolina NC Yea Jackson (TX) Jackson (TX) Republican Texas TX Nay Jackson Lee Jackson Lee Democratic Texas TX Yea Jacobs Jacobs Democratic California CA Yea James James Republican Michigan MI Yea Jayapal Jayapal Democratic Washington WA Yea Jeffries Jeffries Democratic New York NY Yea Johnson (GA) Johnson (GA) Democratic Georgia GA Yea Johnson (LA) Johnson (LA) Republican Louisiana LA Yea Johnson (SD) Johnson (SD) Republican South Dakota SD Yea Jordan Jordan Republican Ohio OH Nay Joyce (OH) Joyce (OH) Republican Ohio OH Yea Joyce (PA) Joyce (PA) Republican Pennsylvania PA Nay Kamlager-Dove Kamlager-Dove Democratic California CA Yea Kaptur Kaptur Democratic Ohio OH Yea Kean (NJ) Kean (NJ) Republican New Jersey NJ Yea Keating Keating Democratic Massachusetts MA Yea Kelly (IL) Kelly (IL) Democratic Illinois IL Yea Kelly (MS) Kelly (MS) Republican Mississippi MS Nay Kelly (PA) Kelly (PA) Republican Pennsylvania PA Yea Khanna Khanna Democratic California CA Yea Kiggans (VA) Kiggans (VA) Republican Virginia VA Yea Kildee Kildee Democratic Michigan MI Yea Kiley Kiley Republican California CA Yea Kilmer Kilmer Democratic Washington WA Yea Kim (CA) Kim (CA) Republican California CA Yea Kim (NJ) Kim (NJ) Democratic New Jersey NJ Yea Krishnamoorthi Krishnamoorthi Democratic Illinois IL Yea Kuster Kuster Democratic New Hampshire NH Yea Kustoff Kustoff Republican Tennessee TN Yea LaHood LaHood Republican Illinois IL Yea LaLota LaLota Republican New York NY Yea LaMalfa LaMalfa Republican California CA Nay Lamborn Lamborn Republican Colorado CO Yea Landsman Landsman Democratic Ohio OH Yea Langworthy Langworthy Republican New York NY Nay Larsen (WA) Larsen (WA) Democratic Washington WA Yea Larson (CT) Larson (CT) Democratic Connecticut CT Yea Latta Latta Republican Ohio OH Yea LaTurner LaTurner Republican Kansas KS Yea Lawler Lawler Republican New York NY Yea Lee (CA) Lee (CA) Democratic California CA Yea Lee (FL) Lee (FL) Republican Florida FL Nay Lee (NV) Lee (NV) Democratic Nevada NV Yea Lee (PA) Lee (PA) Democratic Pennsylvania PA Yea Leger Fernandez Leger Fernandez Democratic New Mexico NM Yea Lesko Lesko Republican Arizona AZ Nay Letlow Letlow Republican Louisiana LA Nay Levin Levin Democratic California CA Yea Lieu Lieu Democratic California CA Yea Lofgren Lofgren Democratic California CA Yea Loudermilk Loudermilk Republican Georgia GA Nay Lucas Lucas Republican Oklahoma OK Yea Luetkemeyer Luetkemeyer Republican Missouri MO Not Voting Luna Luna Republican Florida FL Nay Luttrell Luttrell Republican Texas TX Nay Lynch Lynch Democratic Massachusetts MA Yea Mace Mace Republican South Carolina SC Nay Magaziner Magaziner Democratic Rhode Island RI Yea Malliotakis Malliotakis Republican New York NY Nay Maloy Maloy Republican Utah UT Nay Mann Mann Republican Kansas KS Nay Manning Manning Democratic North Carolina NC Yea Massie Massie Republican Kentucky KY Nay Mast Mast Republican Florida FL Nay Matsui Matsui Democratic California CA Yea McBath McBath Democratic Georgia GA Yea McCaul McCaul Republican Texas TX Yea McClain McClain Republican Michigan MI Nay McClellan McClellan Democratic Virginia VA Yea McClintock McClintock Republican California CA Yea McCollum McCollum Democratic Minnesota MN Yea McCormick McCormick Republican Georgia GA Yea McGarvey McGarvey Democratic Kentucky KY Yea McGovern McGovern Democratic Massachusetts MA Yea McHenry McHenry Republican North Carolina NC Yea Meeks Meeks Democratic New York NY Yea Menendez Menendez Democratic New Jersey NJ Yea Meng Meng Democratic New York NY Yea Meuser Meuser Republican Pennsylvania PA Present Mfume Mfume Democratic Maryland MD Yea Miller (IL) Miller (IL) Republican Illinois IL Nay Miller (OH) Miller (OH) Republican Ohio OH Yea Miller (WV) Miller (WV) Republican West Virginia WV Yea Miller-Meeks Miller-Meeks Republican Iowa IA Yea Mills Mills Republican Florida FL Nay Molinaro Molinaro Republican New York NY Yea Moolenaar Moolenaar Republican Michigan MI Nay Mooney Mooney Republican West Virginia WV Not Voting Moore (AL) Moore (AL) Republican Alabama AL Nay Moore (UT) Moore (UT) Republican Utah UT Yea Moore (WI) Moore (WI) Democratic Wisconsin WI Yea Moran Moran Republican Texas TX Yea Morelle Morelle Democratic New York NY Yea Moskowitz Moskowitz Democratic Florida FL Yea Moulton Moulton Democratic Massachusetts MA Yea Mrvan Mrvan Democratic Indiana IN Yea Mullin Mullin Democratic California CA Yea Murphy Murphy Republican North Carolina NC Yea Nadler Nadler Democratic New York NY Yea Napolitano Napolitano Democratic California CA Yea Neal Neal Democratic Massachusetts MA Yea Neguse Neguse Democratic Colorado CO Yea Nehls Nehls Republican Texas TX Nay Newhouse Newhouse Republican Washington WA Yea Nickel Nickel Democratic North Carolina NC Yea Norcross Norcross Democratic New Jersey NJ Yea Norman Norman Republican South Carolina SC Nay Nunn (IA) Nunn (IA) Republican Iowa IA Yea Obernolte Obernolte Republican California CA Nay Ocasio-Cortez Ocasio-Cortez Democratic New York NY Yea Ogles Ogles Republican Tennessee TN Nay Omar Omar Democratic Minnesota MN Yea Owens Owens Republican Utah UT Nay Pallone Pallone Democratic New Jersey NJ Yea Palmer Palmer Republican Alabama AL Nay Panetta Panetta Democratic California CA Yea Pappas Pappas Democratic New Hampshire NH Yea Pascrell Pascrell Democratic New Jersey NJ Yea Payne Payne Democratic New Jersey NJ Not Voting Pelosi Pelosi Democratic California CA Yea Peltola Peltola Democratic Alaska AK Yea Pence Pence Republican Indiana IN Yea Perez Perez Democratic Washington WA Yea Perry Perry Republican Pennsylvania PA Nay Peters Peters Democratic California CA Yea Pettersen Pettersen Democratic Colorado CO Yea Pfluger Pfluger Republican Texas TX Nay Phillips Phillips Democratic Minnesota MN Yea Pingree Pingree Democratic Maine ME Yea Pocan Pocan Democratic Wisconsin WI Yea Porter Porter Democratic California CA Yea Posey Posey Republican Florida FL Nay Pressley Pressley Democratic Massachusetts MA Yea Quigley Quigley Democratic Illinois IL Yea Ramirez Ramirez Democratic Illinois IL Yea Raskin Raskin Democratic Maryland MD Yea Reschenthaler Reschenthaler Republican Pennsylvania PA Yea Rodgers (WA) Rodgers (WA) Republican Washington WA Yea Rogers (AL) Rogers (AL) Republican Alabama AL Yea Rogers (KY) Rogers (KY) Republican Kentucky KY Yea Rose Rose Republican Tennessee TN Nay Rosendale Rosendale Republican Montana MT Nay Ross Ross Democratic North Carolina NC Yea Rouzer Rouzer Republican North Carolina NC Yea Roy Roy Republican Texas TX Nay Ruiz Ruiz Democratic California CA Yea Ruppersberger Ruppersberger Democratic Maryland MD Yea Rutherford Rutherford Republican Florida FL Yea Ryan Ryan Democratic New York NY Yea Salazar Salazar Republican Florida FL Yea Salinas Salinas Democratic Oregon OR Yea Sánchez Sanchez Democratic California CA Yea Sarbanes Sarbanes Democratic Maryland MD Yea Scalise Scalise Republican Louisiana LA Yea Scanlon Scanlon Democratic Pennsylvania PA Yea Schakowsky Schakowsky Democratic Illinois IL Yea Schiff Schiff Democratic California CA Yea Schneider Schneider Democratic Illinois IL Yea Scholten Scholten Democratic Michigan MI Yea Schrier Schrier Democratic Washington WA Yea Schweikert Schweikert Republican Arizona AZ Yea Scott (VA) Scott (VA) Democratic Virginia VA Yea Scott, Austin Scott, Austin Republican Georgia GA Yea Scott, David Scott, David Democratic Georgia GA Yea Self Self Republican Texas TX Nay Sessions Sessions Republican Texas TX Yea Sewell Sewell Democratic Alabama AL Yea Sherman Sherman Democratic California CA Yea Sherrill Sherrill Democratic New Jersey NJ Yea Simpson Simpson Republican Idaho ID Yea Slotkin Slotkin Democratic Michigan MI Yea Smith (MO) Smith (MO) Republican Missouri MO Nay Smith (NE) Smith (NE) Republican Nebraska NE Yea Smith (NJ) Smith (NJ) Republican New Jersey NJ Yea Smith (WA) Smith (WA) Democratic Washington WA Yea Smucker Smucker Republican Pennsylvania PA Yea Sorensen Sorensen Democratic Illinois IL Yea Soto Soto Democratic Florida FL Yea Spanberger Spanberger Democratic Virginia VA Yea Spartz Spartz Republican Indiana IN Nay Stansbury Stansbury Democratic New Mexico NM Yea Stanton Stanton Democratic Arizona AZ Yea Stauber Stauber Republican Minnesota MN Nay Steel Steel Republican California CA Yea Stefanik Stefanik Republican New York NY Nay Steil Steil Republican Wisconsin WI Nay Steube Steube Republican Florida FL Nay Stevens Stevens Democratic Michigan MI Yea Strickland Strickland Democratic Washington WA Yea Strong Strong Republican Alabama AL Nay Suozzi Suozzi Democratic New York NY Yea Swalwell Swalwell Democratic California CA Yea Sykes Sykes Democratic Ohio OH Yea Takano Takano Democratic California CA Yea Tenney Tenney Republican New York NY Nay Thanedar Thanedar Democratic Michigan MI Yea Thompson (CA) Thompson (CA) Democratic California CA Yea Thompson (MS) Thompson (MS) Democratic Mississippi MS Yea Thompson (PA) Thompson (PA) Republican Pennsylvania PA Yea Tiffany Tiffany Republican Wisconsin WI Nay Timmons Timmons Republican South Carolina SC Nay Titus Titus Democratic Nevada NV Yea Tlaib Tlaib Democratic Michigan MI Yea Tokuda Tokuda Democratic Hawaii HI Yea Tonko Tonko Democratic New York NY Yea Torres (CA) Torres (CA) Democratic California CA Yea Torres (NY) Torres (NY) Democratic New York NY Yea Trahan Trahan Democratic Massachusetts MA Yea Trone Trone Democratic Maryland MD Yea Turner Turner Republican Ohio OH Yea Underwood Underwood Democratic Illinois IL Yea Valadao Valadao Republican California CA Yea Van Drew Van Drew Republican New Jersey NJ Nay Van Duyne Van Duyne Republican Texas TX Nay Van Orden Van Orden Republican Wisconsin WI Nay Vargas Vargas Democratic California CA Yea Vasquez Vasquez Democratic New Mexico NM Yea Veasey Veasey Democratic Texas TX Yea Velázquez Velazquez Democratic New York NY Yea Wagner Wagner Republican Missouri MO Yea Walberg Walberg Republican Michigan MI Nay Waltz Waltz Republican Florida FL Nay Wasserman Schultz Wasserman Schultz Democratic Florida FL Yea Waters Waters Democratic California CA Yea Watson Coleman Watson Coleman Democratic New Jersey NJ Yea Weber (TX) Weber (TX) Republican Texas TX Nay Webster (FL) Webster (FL) Republican Florida FL Nay Wenstrup Wenstrup Republican Ohio OH Yea Westerman Westerman Republican Arkansas AR Yea Wexton Wexton Democratic Virginia VA Yea Wild Wild Democratic Pennsylvania PA Yea Williams (GA) Williams (GA) Democratic Georgia GA Yea Williams (NY) Williams (NY) Republican New York NY Not Voting Williams (TX) Williams (TX) Republican Texas TX Nay Wilson (FL) Wilson (FL) Democratic Florida FL Yea Wilson (SC) Wilson (SC) Republican South Carolina SC Yea Wittman Wittman Republican Virginia VA Yea Womack Womack Republican Arkansas AR Yea Yakym Yakym Republican Indiana IN Yea Zinke Zinke Republican Montana MT Nay No data found 118 Contact Information Room H154, The Capitol Washington, DC 20515-6601 p: (202) 225-7000 For general inquiries: info.clerkweb@mail.house.gov For general technical support: techsupport.clerkweb@mail.house.gov Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Disclosures Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office Committee Information Committee Profiles Clerk Sites Bills This Week Biographical Directory Clerk Kids Committee Repository History, Art & Archives Office of the Chaplain Help & Resources FAQs Privacy Policy Site Map

---
snapshot_id: 31c858fa-6f99-5b9e-8ed4-dfad7b2443cb
source_kind: public-record
url: https://www.congress.gov/bill/118th-congress/house-bill/5692

Ukraine Security Assistance and Oversight Supplemental Appropriations Act, 2024 Policy area: Armed Forces and National Security Sponsor: Rep. Kean, Thomas H. [R-NJ-7] Latest action: Read the second time. Placed on Senate Legislative Calendar under General Orders. Calendar No. 216. Ukraine Security Assistance and Oversight Supplemental Appropriations Act, 2024 This bill provides FY2024 supplemental appropriations to the Department of Defense (DOD) for assistance to Ukraine and establishes the Office of the Special Inspector General for Ukraine Assistance. Specifically, the bill provides appropriations to DOD for the Ukraine Security Assistance Initiative. The funding is provided for purposes such as providing assistance and equipment to the military and national security forces of Ukraine and other forces or groups engaged in resisting Russian aggression against Ukraine, replacing weapons or defense articles provided to Ukraine from the U.S. inventory, and recovering or disposing of equipment procured using funds provided by this bill or prior acts. The bill also establishes and provides funding for the Office of the Special Inspector General for Ukraine Assistance. The duties of the office include conducting and supervising audits and investigations related to the programs and operations funded with appropriations provided to support Ukraine; coordinating and making recommendations regarding policies designed to prevent and detect waste, fraud, and abuse; and keeping the Department of State, DOD, and Congress informed about problems, deficiencies, and the need for corrective actions. Ukraine Security Assistance and Oversight Supplemental Appropriations Act, 2024 This bill provides FY2024 supplemental appropriations to the Department of Defense (DOD) for assistance to Ukraine and establishes the Office of the Special Inspector General for Ukraine Assistance. Specifically, the bill provides appropriations to DOD for the Ukraine Security Assistance Initiative. The funding is provided for purposes such as providing assistance and equipment to the military and national security forces of Ukraine and other forces or groups engaged in resisting Russian aggression against Ukraine, replacing weapons or defense articles provided to Ukraine from the U.S. inventory, and recovering or disposing of equipment procured using funds provided by this bill or prior acts. The bill also establishes and provides funding for the Office of the Special Inspector General for Ukraine Assistance. The duties of the office include conducting and supervising audits and investigations related to the programs and operations funded with appropriations provided to support Ukraine; coordinating and making recommendations regarding policies designed to prevent and detect waste, fraud, and abuse; and keeping the Department of State, DOD, and Congress informed about problems, deficiencies, and the need for corrective actions. Actions: Read the second time. Placed on Senate Legislative Calendar under General Orders. Calendar No. 216. Received in the Senate. Read the first time. Placed on Senate Legislative Calendar under Read the First Time. Motion to reconsider laid on the table Agreed to without objection. On passage Passed by the Yeas and Nays: 311 - 117 (Roll no. 503). (text: CR H4823) Passed/agreed to in House: On passage Passed by the Yeas and Nays: 311 - 117 (Roll no. 503). Considered as unfinished business. (consideration: CR H4846-4847) POSTPONED PROCEEDINGS - At the conclusion of debate on H.R. 5692, the Chair put the question on passage of the bill, and by voice vote announced that the ayes had prevailed. Mr. Calvert demanded the yeas and nays and the Chair postponed further proceedings until a time to be announced. The previous question was ordered pursuant to the rule. DEBATE - The House proceeded with 30 minutes of debate on H.R. 5692. Rule provides for consideration of H.R. 5692, H.R. 4365 and H.R. 4367. The resolution provides for consideration of H.R. 5692, under a closed rule. The resolution provides for 30 minutes of general debate on the bill H.R. 5692 and one motion to recommit. The resolution provides that further consideration of H.R. 4365, the further amendments specified in section 3 shall be considered as adopted and the resolution provides for further consideration of H.R. 4367, the further amendment specified in section 5 shall be considered as adopted. Considered under the provisions of rule H. Res. 730. (consideration: CR H4823-4826) Rules Committee Resolution H. Res. 730 Reported to House. Rule provides for consideration of H.R. 5692, H.R. 4365 and H.R. 4367. The resolution provides for consideration of H.R. 5692, under a closed rule. The resolution provides for 30 minutes of general debate on the bill H.R. 5692 and one motion to recommit. The resolution provides that further consideration of H.R. 4365, the further amendments specified in section 3 shall be considered as adopted and the resolution provides for further consideration of H.R. 4367, the further amendment specified in section 5 shall be considered as adopted. Referred to the House Committee on Appropriations. Introduced in House Introduced in House [Congressional Bills 118th Congress] [From the U.S. Government Publishing Office] [H.R. 5692 Placed on Calendar Senate (PCS)] <DOC> Calendar No. 216 118th CONGRESS 1st Session H. R. 5692 _______________________________________________________________________ IN THE SENATE OF THE UNITED STATES September 30 (legislative day, September 22), 2023 Received; read the first time October 3, 2023 Read the second time and placed on the calendar _______________________________________________________________________ AN ACT Making supplemental appropriations for the fiscal year ending September 30, 2024, and for other purposes. Be it enacted by the Senate and House of Representatives of the United States of America in Congress assembled, That the following sums are appropriated, out of any money in the Treasury not otherwise appropriated, for the fiscal year ending September 30, 2024, and for other purposes, namely: DEPARTMENT OF DEFENSE OPERATIONS AND MAINTENANCE Operations and Maintenance, Defense-Wide (including transfer of funds) For an additional amount for ``Operations and Maintenance, Defense- Wide'', for the Defense Security Cooperation Agency, $300,000,000, to remain available until September 30, 2025, which shall be for the Ukraine Security Assistance Initiative: Provided, That such funds shall be available to the Secretary of Defense, with the concurrence of the Secretary of State, to provide assistance, including training; equipment; lethal assistance; logistics support, supplies and services; salaries and stipends; sustainment; and intelligence support to the military and national security forces of Ukraine, and to other forces or groups recognized by and under the authority of the Government of Ukraine, including governmental entities within Ukraine, engaged in resisting Russian aggression against Ukraine, for replacement of any weapons or articles provided to the Government of Ukraine from the inventory of the United States, and to recover or dispose of equipment procured using funds made available in this section in this or prior Acts: Provided further, That the Secretary of Defense shall, not less than 15 days prior to obligating funds made available in this section, notify the congressional defense committees in writing of the details of any such obligation: Provided further, That the Secretary of Defense shall, not more than 60 days after such notification is made, inform such committees if such funds have not been obligated and the reasons therefor: Provided further, That the Secretary of Defense shall consult with such committees in advance of the provision of support provided to other forces or groups recognized by and under the authority of the Government of Ukraine: Provided further, That the United States may accept equipment procured using funds made available in this section in this or prior Acts transferred to the security forces of Ukraine and returned by such forces to the United States: Provided further, That equipment procured using funds made available in this section in this or prior Acts, and not yet transferred to the military or national security forces of Ukraine or to other assisted entities, or returned by such forces or other assisted entities to the United States, may be treated as stocks of the Department of Defense upon written notification to the congressional defense committees: Provided further, That any notification of funds made available in this section in this or prior Acts shall specify whether such funds support ongoing or new programs, the duration and expected cost over the life of each program, a timeline for the delivery of defense articles and defense services, and any equipment that requires enhanced end-use monitoring: Provided further, That the Secretary of Defense shall provide quarterly reports to the congressional defense committees on the use and status of funds made available in this section: Provided further, That of the amounts provided under this heading, $20,000,000 shall be transferred to the Office of Special Inspector General for Ukraine Assistance, as established in section 103 of this Act. GENERAL PROVISIONS--THIS ACT Sec. 101. Each amount appropriated or made available by this Act is in addition to amounts otherwise appropriated for the fiscal year involved. Sec. 102. Unless otherwise provided for by this Act, the additional amounts appropriated by this Act to appropriations accounts shall be available under the authorities and conditions applicable to such appropriations accounts for fiscal year 2024. Sec. 103. There is established the Office of the Special Inspector General for Ukraine Assistance for the following: (1) To provide for the independent and objective conduct and supervision of audits and investigations, including within the territory of Ukraine, relating to the programs and operations funded with amounts appropriated or otherwise made available for the military and nonmilitary support of Ukraine. (2) To provide for the independent and objective leadership and coordination of, and recommendations on, policies designed to prevent and detect waste, fraud, and abuse in such programs and operations described in paragraph (1). (3) To provide for an independent and objective means of keeping the Secretary of State, the Secretary of Defense, and Congress fully and currently informed about problems and deficiencies relating to the administration of such programs and operations and the necessity for and progress on corrective action. This Act may be cited as the ``Ukraine Security Assistance and Oversight Supplemental Appropriations Act, 2024''. Passed the House of Representatives September 28, 2023. Attest: KEVIN F. MCCUMBER, Clerk. Calendar No. 216 118th CONGRESS 1st Session H. R. 5692 _______________________________________________________________________ AN ACT Making supplemental appropriations for the fiscal year ending September 30, 2024, and for other purposes. _______________________________________________________________________ October 3, 2023 Read the second time and placed on the calendar

---
snapshot_id: c20fe92b-7bd9-5133-9689-cf3af919a856
source_kind: public-record
url: https://www.congress.gov/bill/118th-congress/house-bill/8035

Ukraine Security Supplemental Appropriations Act, 2024 Policy area: Economics and Public Finance Sponsor: Rep. Cole, Tom [R-OK-4] Latest action: Pursuant to the provisions of H. Res. 1160, H.R. 8035 is laid on the table. Ukraine Security Supplemental Appropriations Act, 2024 This bill provides FY2024 supplemental appropriations for federal departments and agencies to respond to the conflict in Ukraine. The bill designates the funding as emergency spending, which is exempt from discretionary spending limits. Specifically, the bill provides appropriations to the Department of Defense (DOD), Department of Energy science programs, the National Nuclear Security Administration, the Administration for Children and Families, the Department of State, and the U.S. Agency for International Development. The funding is provided for purposes such as supporting current U.S. military operations in the region, the Ukraine Security Assistance Initiative, replacing defense articles that were provided to Ukraine, reimbursing DOD for defense services and training provided to Ukraine, the Foreign Military Financing Program, economic support for Ukraine, refugee and entrant assistance, international narcotics control and law enforcement, and the development and production of isotopes. The bill also includes provisions that expand the authorities of the President to transfer defense articles and services from DOD to foreign countries or international organizations, require the President to transfer long-range Army Tactical Missile Systems to Ukraine, require the President to enter into an agreement with Ukraine regarding repaying the United States for the economic assistance it has provided to Ukraine, require certain funds that are provided for Ukraine to be matched by other donors, and establish various oversight and reporting requirements for assistance provided to Ukraine. Ukraine Security Supplemental Appropriations Act, 2024 This bill provides FY2024 supplemental appropriations for federal departments and agencies to respond to the conflict in Ukraine. The bill designates the funding as emergency spending, which is exempt from discretionary spending limits. Specifically, the bill provides appropriations to the Department of Defense (DOD), Department of Energy science programs, the National Nuclear Security Administration, the Administration for Children and Families, the Department of State, and the U.S. Agency for International Development. The funding is provided for purposes such as supporting current U.S. military operations in the region, the Ukraine Security Assistance Initiative, replacing defense articles that were provided to Ukraine, reimbursing DOD for defense services and training provided to Ukraine, the Foreign Military Financing Program, economic support for Ukraine, refugee and entrant assistance, international narcotics control and law enforcement, and the development and production of isotopes. The bill also includes provisions that expand the authorities of the President to transfer defense articles and services from DOD to foreign countries or international organizations, require the President to transfer long-range Army Tactical Missile Systems to Ukraine, require the President to enter into an agreement with Ukraine regarding repaying the United States for the economic assistance it has provided to Ukraine, require certain funds that are provided for Ukraine to be matched by other donors, and establish various oversight and reporting requirements for assistance provided to Ukraine. Cosponsors: Rep. Calvert, Ken [R-CA-41], Rep. Diaz-Balart, Mario [R-FL-26] Actions: Pursuant to the provisions of H. Res. 1160, H.R. 8035 is laid on the table. Motion to reconsider laid on the table Agreed to without objection. On passage Passed by the Yeas and Nays: 311 - 112, 1 Present (Roll no. 151). Passed/agreed to in House: On passage Passed by the Yeas and Nays: 311 - 112, 1 Present (Roll no. 151). On motion to recommit Failed by recorded vote: 88 - 336 (Roll no. 150). The previous question on the motion to recommit was ordered pursuant to clause 2(b) of rule XIX. Mr. Roy moved to recommit to the Committee on Appropriations. (text: CR H2620) The previous question was ordered pursuant to the rule. The House rose from the Committee of the Whole House on the state of the Union to report H.R. 8035. The House resolved into Committee of the Whole House on the state of the Union for further consideration. Considered as unfinished business. (consideration: CR H2617-2621) Committee of the Whole House on the state of the Union rises leaving H.R. 8035 as unfinished business. On motion that the committee rise Agreed to by voice vote. Mr. Diaz-Balart moved that the committee rise. POSTPONED PROCEEDINGS - At the conclusion of debate on the Cammack amendment No. 4, the Chair put the question on agreeing to the amendment and by voice vote, announced the noes had prevailed. Mrs. Cammack demanded a recorded vote, and the Chair postponed further proceedings until a time to be announced. [Congressional Bills 118th Congress] [From the U.S. Government Publishing Office] [H.R. 8035 Introduced in House (IH)] <DOC> 118th CONGRESS 2d Session H. R. 8035 Making emergency supplemental appropriations to respond to the situation in Ukraine and for related expenses for the fiscal year ending September 30, 2024, and for other purposes. _______________________________________________________________________ IN THE HOUSE OF REPRESENTATIVES April 17, 2024 Mr. Cole (for himself, Mr. Calvert, and Mr. Diaz-Balart) introduced the following bill; which was referred to the Committee on Appropriations, and in addition to the Committee on the Budget, for a period to be subsequently determined by the Speaker, in each case for consideration of such provisions as fall within the jurisdiction of the committee concerned _______________________________________________________________________ A BILL Making emergency supplemental appropriations to respond to the situation in Ukraine and for related expenses for the fiscal year ending September 30, 2024, and for other purposes. Be it enacted by the Senate and House of Representatives of the United States of America in Congress assembled, That the following sums are appropriated, out of any money in the Treasury not otherwise appropriated, for the fiscal year ending September 30, 2024, and for other purposes, namely: TITLE I DEPARTMENT OF DEFENSE MILITARY PERSONNEL Military Personnel, Army For an additional amount for ``Military Personnel, Army'', $207,158,000, to remain available until December 31, 2024, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Military Personnel, Marine Corps For an additional amount for ``Military Personnel, Marine Corps'', $3,538,000, to remain available until December 31, 2024, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Military Personnel, Air Force For an additional amount for ``Military Personnel, Air Force'', $23,302,000, to remain available until December 31, 2024, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Military Personnel, Space Force For an additional amount for ``Military Personnel, Space Force'', $4,192,000, to remain available until December 31, 2024, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. OPERATION AND MAINTENANCE Operation and Maintenance, Army For an additional amount for ``Operation and Maintenance, Army'', $4,887,581,000, to remain available until December 31, 2024, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Operation and Maintenance, Navy For an additional amount for ``Operation and Maintenance, Navy'', $976,405,000, to remain available until December 31, 2024, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Operation and Maintenance, Marine Corps For an additional amount for ``Operation and Maintenance, Marine Corps'', $69,045,000, to remain available until December 31, 2024, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Operation and Maintenance, Air Force For an additional amount for ``Operation and Maintenance, Air Force'', $371,475,000, to remain available until December 31, 2024, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Operation and Maintenance, Space Force For an additional amount for ``Operation and Maintenance, Space Force'', $8,443,000, to remain available until December 31, 2024, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Operation and Maintenance, Defense-Wide (including transfers of funds) For an additional amount for ``Operation and Maintenance, Defense- Wide'', $27,930,780,000, to remain available until December 31, 2024, to respond to the situation in Ukraine and for related expenses: Provided, That of the total amount provided under this heading in this Act, $13,772,460,000, to remain available until September 30, 2025, shall be for the Ukraine Security Assistance Initiative: Provided further, That such funds for the Ukraine Security Assistance Initiative shall be available to the Secretary of Defense under the same terms and conditions as are provided for in section 8148 of the Department of Defense Appropriations Act, 2024 (division A of Public Law 118-47): Provided further, That of the total amount provided under this heading in this Act, up to $13,414,432,000, to remain available until September 30, 2025, may be transferred to accounts under the headings ``Operation and Maintenance'', ``Procurement'', and ``Revolving and Management Funds'' for replacement, through new procurement or repair of existing unserviceable equipment, of defense articles from the stocks of the Department of Defense, and for reimbursement for defense services of the Department of Defense and military education and training, provided to the government of Ukraine or identified and notified to Congress for provision to the government of Ukraine or to foreign countries that have provided support to Ukraine at the request of the United States: Provided further, That funds transferred pursuant to the preceding proviso shall be merged with and available for the same purposes and for the same time period as the appropriations to which the funds are transferred: Provided further, That the Secretary of Defense shall notify the congressional defense committees of the details of such transfers not less than 15 days before any such transfer: Provided further, That upon a determination that all or part of the funds transferred from this appropriation are not necessary for the purposes provided herein, such amounts may be transferred back and merged with this appropriation: Provided further, That any transfer authority provided herein is in addition to any other transfer authority provided by law: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. PROCUREMENT Missile Procurement, Army For an additional amount for ``Missile Procurement, Army'', $2,742,757,000, to remain available until September 30, 2026, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Procurement of Ammunition, Army For an additional amount for ``Procurement of Ammunition, Army'', $5,612,900,000, to remain available until September 30, 2026, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Other Procurement, Army For an additional amount for ``Other Procurement, Army'', $308,991,000, to remain available until September 30, 2026, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Weapons Procurement, Navy For an additional amount for ``Weapons Procurement, Navy'', $706,976,000, to remain available until September 30, 2026, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Other Procurement, Navy For an additional amount for ``Other Procurement, Navy'', $26,000,000, to remain available until September 30, 2026, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Procurement, Marine Corps For an additional amount for ``Procurement, Marine Corps'', $212,443,000, to remain available until September 30, 2026, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Missile Procurement, Air Force For an additional amount for ``Missile Procurement, Air Force'', $366,001,000, to remain available until September 30, 2026, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Other Procurement, Air Force For an additional amount for ``Other Procurement, Air Force'', $3,284,072,000, to remain available until September 30, 2026, to respond to the situation in Ukraine and for other expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Procurement, Defense-Wide For an additional amount for ``Procurement, Defense-Wide'', $46,780,000, to remain available until September 30, 2026, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. RESEARCH, DEVELOPMENT, TEST AND EVALUATION Research, Development, Test and Evaluation, Army For an additional amount for ``Research, Development, Test and Evaluation, Army'', $18,594,000, to remain available until September 30, 2025, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Research, Development, Test and Evaluation, Navy For an additional amount for ``Research, Development, Test and Evaluation, Navy'', $13,825,000, to remain available until September 30, 2025, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Research, Development, Test and Evaluation, Air Force For an additional amount for ``Research, Development, Test and Evaluation, Air Force'', $406,834,000, to remain available until September 30, 2025, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Research, Development, Test and Evaluation, Defense-Wide For an additional amount for ``Research, Development, Test and Evaluation, Defense-Wide'', $194,125,000, to remain available until September 30, 2025, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. OTHER DEPARTMENT OF DEFENSE PROGRAMS Office of the Inspector General For an additional amount for ``Office of the Inspector General'', $8,000,000, to remain available until September 30, 2025, which shall be for operation and maintenance of the Office of the Inspector General, including the Special Inspector General for Operation Atlantic Resolve, to carry out reviews of the activities of the Department of Defense to execute funds appropriated in this Act, including assistance provided to Ukraine: Provided, That the Inspector General of the Department of Defense shall provide to the congressional defense committees a briefing not later than 90 days after the date of enactment of this Act: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. RELATED AGENCIES Intelligence Community Management Account For an additional amount for ``Intelligence Community Management Account'', $2,000,000, to remain available until September 30, 2024, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. GENERAL PROVISIONS--THIS TITLE (including transfers of funds) Sec. 101. (a) Upon the determination of the Secretary of Defense that such action is necessary in the national interest, the Secretary may, with the approval of the Director of the Office of Management and Budget, transfer up to $1,000,000,000 only between the appropriations or funds made available in this title to the Department of Defense to respond to the situation in Ukraine and for related expenses: Provided, That the Secretary shall notify the Congress promptly of each transfer made pursuant to the authority in this subsection: Provided further, That such authority is in addition to any transfer authority otherwise provided by law and is subject to the same terms and conditions as the authority provided in section 8005 of the Department of Defense Appropriations Act, 2024 (division A of Public Law 118-47), except for monetary limitations concerning the amount of authority available. (b) Upon the determination by the Director of National Intelligence that such action is necessary in the national interest, the Director may, with the approval of the Director of the Office of Management and Budget, transfer up to $250,000,000 only between the appropriations or funds made available in this title for the National Intelligence Program: Provided, That the Director of National Intelligence shall notify the Congress promptly of all transfers made pursuant to the authority in this subsection: Provided further, That such authority is in addition to any transfer authority otherwise provided by law and is subject to the same terms and conditions as the authority provided in section 8091 of the Department of Defense Appropriations Act, 2024 (division A of Public Law 118-47), except for monetary limitations concerning the amount of authority available. Sec. 102. Not later than 60 days after the date of enactment of this Act, the Secretary of Defense, in coordination with the Secretary of State, shall submit a report to the Committees on Appropriations, Armed Services, and Foreign Affairs of the House of Representatives and the Committees on Appropriations, Armed Services, and Foreign Relations of the Senate on measures being taken to account for United States defense articles designated for Ukraine since the February 24, 2022, Russian invasion of Ukraine, particularly measures with regard to such articles that require enhanced end-use monitoring; measures to ensure that such articles reach their intended recipients and are used for their intended purposes; and any other measures to promote accountability for the use of such articles: Provided, That such report shall include a description of any occurrences of articles not reaching their intended recipients or used for their intended purposes and a description of any remedies taken: Provided further, That such report shall be submitted in unclassified form, but may be accompanied by a classified annex. Sec. 103. Not later than 30 days after the date of enactment of this Act, and every 30 days thereafter through fiscal year 2025, the Secretary of Defense, in coordination with the Secretary of State, shall provide a written report to the Committees on Appropriations, Armed Services, and Foreign Affairs of the House of Representatives and the Committees on Appropriations, Armed Services, and Foreign Relations of the Senate describing United States security assistance provided to Ukraine since the February 24, 2022, Russian invasion of Ukraine, including a comprehensive list of the defense articles and services provided to Ukraine and the associated authority and funding used to provide such articles and services: Provided, That such report shall be submitted in unclassified form, but may be accompanied by a classified annex. TITLE II DEPARTMENT OF ENERGY ENERGY PROGRAMS Science For an additional amount for ``Science'', $98,000,000, to remain available until expended, for acquisition, distribution, and equipment for development and production of medical, stable, and radioactive isotopes: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. ATOMIC ENERGY DEFENSE ACTIVITIES NATIONAL NUCLEAR SECURITY ADMINISTRATION Defense Nuclear Nonproliferation For an additional amount for ``Defense Nuclear Nonproliferation'', $143,915,000, to remain available until September 30, 2025, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Federal Salaries and Expenses For an additional amount for ``Federal Salaries and Expenses'', $5,540,000, to remain available until September 30, 2025, to respond to the situation in Ukraine and for related expenses: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. TITLE III DEPARTMENT OF HEALTH AND HUMAN SERVICES Administration for Children and Families refugee and entrant assistance For an additional amount for ``Refugee and Entrant Assistance'', $481,000,000, to remain available until September 30, 2025, for refugee and entrant assistance activities authorized by section 414 of the Immigration and Nationality Act and section 501 of the Refugee Education Assistance Act of 1980: Provided, That amounts made available under this heading in this Act may be used for grants or contracts with qualified organizations, including nonprofit entities, to provide culturally and linguistically appropriate services, including wraparound services, housing assistance, medical assistance, legal assistance, and case management assistance: Provided further, That amounts made available under this heading in this Act may be used by the Director of the Office of Refugee Resettlement (Director) to issue awards or supplement awards previously made by the Director: Provided further, That the Director, in carrying out section 412(c)(1)(A) of the Immigration and Nationality Act (8 U.S.C. 1522(c)(1)(A)) with amounts made available under this heading in this Act, may allocate such amounts among the States in a manner that accounts for the most current data available: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. GENERAL PROVISION--THIS TITLE Sec. 301. Section 401(a)(1)(A) of the Additional Ukraine Supplemental Appropriations Act, 2022 (Public Law 117-128) is amended by striking ``September 30, 2023'' and inserting ``September 30, 2024'': Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. TITLE IV DEPARTMENT OF STATE AND RELATED AGENCY DEPARTMENT OF STATE Administration of Foreign Affairs diplomatic programs For an additional amount for ``Diplomatic Programs'', $60,000,000, to remain available until September 30, 2025, to respond to the situation in Ukraine and countries impacted by the situation in Ukraine: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. office of inspector general For an additional amount for ``Office of Inspector General'', $8,000,000, to remain available until September 30, 2025: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. UNITED STATES AGENCY FOR INTERNATIONAL DEVELOPMENT Funds Appropriated to the President operating expenses For an additional amount for ``Operating Expenses'', $39,000,000, to remain available until September 30, 2025, to respond to the situation in Ukraine and countries impacted by the situation in Ukraine: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. office of inspector general For an additional amount for ``Office of Inspector General'', $10,000,000, to remain available until September 30, 2025: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. BILATERAL ECONOMIC ASSISTANCE Funds Appropriated to the President transition initiatives For an additional amount for ``Transition Initiatives'', $25,000,000, to remain available until expended, for assistance for Ukraine and countries impacted by the situation in Ukraine: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. economic support fund For an additional amount for ``Economic Support Fund'', $7,899,000,000, to remain available until September 30, 2025: Provided, That of the total amount provided under this heading in this Act, $7,849,000,000 shall be for assistance for Ukraine, which may include budget support and which may be made available notwithstanding any other provision of law that restricts assistance to foreign countries: Provided further, That none of the funds made available for budget support pursuant to the preceding proviso may be made available for the reimbursement of pensions: Provided further, That of the total amount provided under this heading in this Act, $50,000,000 shall be to prevent and respond to food insecurity: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. assistance for europe, eurasia and central asia For an additional amount for ``Assistance for Europe, Eurasia and Central Asia'', $1,575,000,000, to remain available until September 30, 2025, for assistance and related programs for Ukraine and other countries identified in section 3 of the FREEDOM Support Act (22 U.S.C. 5801) and section 3(c) of the Support for East European Democracy (SEED) Act of 1989 (22 U.S.C. 5402(c)): Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. INTERNATIONAL SECURITY ASSISTANCE Department of State international narcotics control and law enforcement For an additional amount for ``International Narcotics Control and Law Enforcement'', $300,000,000, to remain available until September 30, 2025, for assistance for Ukraine and countries impacted by the situation in Ukraine: Provided, That such funds may be made available to support the State Border Guard Service of Ukraine and National Police of Ukraine, including units supporting or under the command of the Armed Forces of Ukraine: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. nonproliferation, anti-terrorism, demining and related programs For an additional amount for ``Nonproliferation, Anti-terrorism, Demining and Related Programs'', $100,000,000, to remain available until September 30, 2025, for assistance for Ukraine and countries impacted by the situation in Ukraine: Provided, That not later than 60 days after the date of enactment of this Act, the Secretary of State shall consult with the Committees on Appropriations on the prioritization of demining efforts and how such efforts will be coordinated with development activities: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Funds Appropriated to the President foreign military financing program For an additional amount for ``Foreign Military Financing Program'', $1,600,000,000, to remain available until September 30, 2025, for assistance for Ukraine and countries impacted by the situation in Ukraine and for related expenses: Provided, That amounts made available under this heading in this Act and unobligated balances of amounts made available under this heading in Acts making appropriations for the Department of State, foreign operations, and related programs for fiscal year 2024 and prior fiscal years shall be available for the cost of loans and loan guarantees as authorized by section 2606 of the Ukraine Supplemental Appropriations Act, 2022 (division N of Public Law 117-103), subject to the terms and conditions provided in such section, or as otherwise authorized by law: Provided further, That loan guarantees made using amounts described in the preceding proviso for loans financed by the Federal Financing Bank may be provided notwithstanding any provision of law limiting the percentage of loan principal that may be guaranteed: Provided further, That up to $5,000,000 of funds made available under this heading in this Act, in addition to funds otherwise available for such purposes, may be used by the Department of State for necessary expenses for the general costs of administering military assistance and sales, including management and oversight of such programs and activities: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. GENERAL PROVISIONS--THIS TITLE (including transfers of funds) Sec. 401. During fiscal year 2024, section 506(a)(1) of the Foreign Assistance Act of 1961 (22 U.S.C. 2318(a)(1)) shall be applied by substituting ``$7,800,000,000'' for ``$100,000,000''. Sec. 402. During fiscal year 2024, section 506(a)(2)(B) of the Foreign Assistance Act of 1961 (22 U.S.C. 2318(a)(2)(B)) shall be applied by substituting ``$400,000,000'' for ``$200,000,000'' in the matter preceding clause (i), and by substituting ``$150,000,000'' for ``$75,000,000'' in clause (i). Sec. 403. During fiscal year 2024, section 552(c)(2) of the Foreign Assistance Act of 1961 (22 U.S.C. 2348a(c)(2)) shall be applied by substituting ``$50,000,000'' for ``$25,000,000''. Sec. 404. (a) Funds appropriated by this Act under the headings ``Economic Support Fund'' and ``Assistance for Europe, Eurasia and Central Asia'' to respond to the situation in Ukraine and in countries impacted by the situation in Ukraine may be transferred to, and merged with, funds made available under the headings ``United States International Development Finance Corporation--Corporate Capital Account'', ``United States International Development Finance Corporation--Program Account'', ``Export-Import Bank of the United States--Program Account'', and ``Trade and Development Agency'' for such purpose. (b) The transfer authority provided by this section is in addition to any other transfer authority provided by law, and is subject to prior consultation with, and the regular notification procedures of, the Committees on Appropriations. (c) Upon a determination that all or part of the funds transferred pursuant to the authority provided by this section are not necessary for such purposes, such amounts may be transferred back to such appropriations. Sec. 405. Section 1705 of the Additional Ukraine Supplemental Appropriations Act, 2023 (division M of Public Law 117-328) shall apply to funds appropriated by this Act under the heading ``Economic Support Fund'' for assistance for Ukraine. Sec. 406. None of the funds appropriated or otherwise made available by this title in this Act may be made available for assistance for the Governments of the Russian Federation or Belarus, including entities owned or controlled by such Governments. Sec. 407. (a) Section 2606 of the Ukraine Supplemental Appropriations Act, 2022 (division N of Public Law 117-103) is amended as follows: (1) in subsection (a), by striking ``and North Atlantic Treaty Organization (NATO) allies'' and inserting ``, North Atlantic Treaty Organization (NATO) allies, major non-NATO allies, and the Indo-Pacific region''; by striking ``$4,000,000,000'' and inserting ``$8,000,000,000''; and by striking ``, except that such rate may not be less than the prevailing interest rate on marketable Treasury securities of similar maturity''; and (2) in subsection (b), by striking ``and NATO allies'' and inserting ``, NATO allies, major non-NATO allies, and the Indo-Pacific region''; by striking ``$4,000,000,000'' and inserting ``$8,000,000,000''; and by inserting at the end of the second proviso ``except for guarantees of loans by the Federal Financing Bank''. (b) Funds made available for the costs of direct loans and loan guarantees for major non-NATO allies and the Indo-Pacific region pursuant to section 2606 of division N of Public Law 117-103, as amended by subsection (a), may only be made available from funds appropriated by this Act under the heading ``Foreign Military Financing Program'' and available balances from under such heading in prior Acts making appropriations for the Department of State, foreign operations, and related programs: Provided, That such funds may only be made available if the Secretary of State certifies and reports to the appropriate congressional committees, not less than 15 days prior to the obligation of such funds, that such direct loan or loan guarantee is in the national security interest of the United States, is being provided in response to exigent circumstances, is addressing a mutually agreed upon emergency requirement of the recipient country, and the recipient country has a plan to repay such loan: Provided further, That not less than 60 days after the date of enactment of this Act, the Secretary of State shall consult with such committees on the implementation of this subsection: (c) Amounts repurposed pursuant to this section that were previously designated by the Congress as an emergency requirement pursuant to a concurrent resolution on the Budget are designated as an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Sec. 408. Funds appropriated under the headings ``Economic Support Fund'' and ``Assistance for Europe, Eurasia and Central Asia'' in this title in this Act may be made available as contributions, following consultation with the Committees on Appropriations. Sec. 409. Prior to the initial obligation of funds made available in this title in this Act, but not later than 15 days after the date of enactment of this Act, the Secretary of State and USAID Administrator, as appropriate, shall submit to the Committees on Appropriations-- (1) spend plans, as defined in section 7034(s)(4) of the Department of State, Foreign Operations, and Related Programs Appropriations Act, 2023 (division K of Public Law 117-328), at the country, account, and program level, for funds appropriated by this Act under the headings ``Economic Support Fund'', ``Transition Initiatives'', ``Assistance for Europe, Eurasia and Central Asia'', ``International Narcotics Control and Law Enforcement'', ``Nonproliferation, Anti-terrorism, Demining and Related Programs'', and ``Foreign Military Financing Program'': Provided, That plans submitted pursuant to this paragraph shall include for each program notified--(A) total funding made available for such program, by account and fiscal year; (B) funding that remains unobligated for such program from prior year base or supplemental appropriations; (C) funding that is obligated but unexpended for such program; and (D) funding committed, but not yet notified for such program; and (2) operating plans, as defined in section 7062 of the Department of State, Foreign Operations, and Related Programs Appropriations Act, 2023 (division K of Public Law 117-328), for funds appropriated by this title under the headings ``Diplomatic Programs'' and ``Operating Expenses''. TITLE V GENERAL PROVISIONS--THIS ACT Sec. 501. Each amount appropriated or made available by this Act is in addition to amounts otherwise appropriated for the fiscal year involved. Sec. 502. No part of any appropriation contained in this Act shall remain available for obligation beyond the current fiscal year unless expressly so provided herein. Sec. 503. Unless otherwise provided for by this Act, the additional amounts appropriated by this Act to appropriations accounts shall be available under the authorities and conditions applicable to such appropriations accounts for fiscal year 2024. Sec. 504. Not later than 45 days after the date of enactment of this Act, the Secretary of State and the Secretary of Defense, in consultation with the heads of other relevant Federal agencies, as appropriate, shall submit to the Committees on Appropriations, Armed Services, and Foreign Relations of the Senate and the Committees on Appropriations, Armed Services, and Foreign Affairs of the House of Representatives a strategy regarding United States support for Ukraine against aggression by the Russian Federation: Provided, That such strategy shall be multi-year, establish specific and achievable objectives, define and prioritize United States national security interests, and include the metrics to be used to measure progress in achieving such objectives: Provided further, That such strategy shall include an estimate, on a fiscal year-by-fiscal year basis, of the resources required by the United States to achieve such objectives, including to help hasten Ukrainian victory against Russia's invasion forces in a manner most favorable to United States interests and objectives, and a description of the national security implications for the United States if those objectives are not met: Provided further, That such strategy shall describe how each specific aspect of U.S. assistance, including defense articles and U.S. foreign assistance, is intended at the tactical, operational, and strategic level to help Ukraine end the conflict as a democratic, independent, and sovereign country capable of deterring and defending its territory against future aggression: Provided further, That such strategy shall include a classified independent assessment from the Commander, U.S. European Command, describing any specific defense articles and services not yet provided to Ukraine that would result in meaningful battlefield gains in alignment with the strategy: Provided further, That such strategy shall include a classified assessment from the Chairman of the Joint Chiefs of Staff that the provision of specific defense articles and services provided to Ukraine does not pose significant risk to the defense capabilities of the United States military: Provided further, That the Under Secretary of Defense for Acquisition & Sustainment in coordination with the Director, Cost Assessment and Program Evaluation provide an assessment of the executability and a production schedule for any specific defense articles recommended by the Commander, U.S. European Command that require procurement: Provided further, That such strategy shall include information on support to the Government of the Russian Federation from the Islamic Republic of Iran, the People's Republic of China, and the Democratic People's Republic of Korea, related to the Russian campaign in Ukraine, and its impact on such strategy: Provided further, That such strategy shall be updated not less than quarterly, as appropriate, until September 30, 2025, and such updates shall be submitted to such committees: Provided further, That unless otherwise specified by this section, such strategy shall be submitted in unclassified form but may include a classified annex. Sec. 505. (a) Transfer of Long-Range ATACMS Required.--As soon as practicable after the date of enactment of this Act, the President shall transfer long range Army Tactical Missile Systems to the Government of Ukraine to assist the Government of Ukraine in defending itself and achieving victory against the Russian Federation. (b) Notification.--If the President determines that executing the transfer of long-range Army Tactical Missile Systems to the Government of Ukraine pursuant to subsection (a) would be detrimental to the national security interests of the United States, the President may withhold such transfer and shall notify the congressional defense committees, the Committees on Appropriations and Foreign Relations of the Senate, and the Committees on Appropriations and Foreign Affairs of the House of Representatives of such determination. Sec. 506. (a) In-Person Monitoring.--The Secretary of State shall, to the maximum extent practicable, ensure that funds appropriated by this Act under the headings ``Economic Support Fund'', ``Assistance for Europe, Eurasia and Central Asia'', ``International Narcotics Control and Law Enforcement'', and ``Nonproliferation, Anti-terrorism, Demining and Related Programs'' and made available for project-based assistance for Ukraine are subject to in-person monitoring by United States personnel or by vetted third party monitors. (b) Certification.--Not later than 15 days prior to the initial obligation of funds appropriated by this Act and made available for assistance for Ukraine under the headings ``Economic Support Fund'', ``Assistance for Europe, Eurasia and Central Asia'', ``International Narcotics Control and Law Enforcement'', ``Nonproliferation, Anti- terrorism, Demining and Related Programs'', and ``Foreign Military Financing Program'', the Secretary of State and the USAID Administrator shall jointly certify and report to the appropriate congressional committees that mechanisms for monitoring and oversight of funds are in place and functioning to ensure accountability of such funds to prevent waste, fraud, abuse, diversion, and corruption, including mechanisms such as use of third party monitors, enhanced end-use monitoring, external and independent audits and evaluations, randomized spot checks, and regular reporting on outcomes achieved and progress made toward stated program objectives, consistent with the strategy required by section 504 of this title: Provided, That section 7015(e) of Public Law 118-47 shall apply to the certification requirement of this subsection. (c) Cost Matching.--Funds appropriated by this Act and prior Acts for fiscal year 2024 under the headings ``Economic Support Fund'' and ``Assistance for Europe, Eurasia and Central Asia'' that are made available for contributions to the Government of Ukraine may not exceed 50 percent of the total amount provided for such assistance by all donors: Provided, That the President may waive the limitation in this subsection if the President determines and reports to the appropriate congressional committees that to do so is in the national security interest of the United States, including a detailed justification for such determination and an explanation as to why other donors to the Government of Ukraine are unable to meet or exceed such level: Provided further, That following such determination, the President shall submit a report to the Speaker and Minority Leader of the House of Representatives, the Majority and Minority Leaders of the Senate, and the appropriate congressional committees every 120 days while assistance is provided in reliance on the determination under the previous proviso detailing steps taken by the Department of State to increase other donor contributions and an update on the status of such contributions: Provided further, That the requirements of this subsection shall continue in effect until such funds are expended. Sec. 507. (a) Arrangement Required.--Notwithstanding any other provision of law, not later than 60 days after the date of the enactment of this Act, the President shall enter into an arrangement with the Government of Ukraine relating to the repayment by Ukraine to the United States of economic assistance provided to Ukraine by the United States to respond to the situation in Ukraine, and for related expenses, that are made available under the headings ``Economic Support Fund'' and ``Assistance for Europe, Eurasia and Central Asia'' in title IV of this Act. (b) Terms.--Repayment required by the arrangement required by subsection (a) shall be at terms to be set by the President. (c) Limitation on Arrangement Terms.--The arrangement required pursuant to subsection (a) may not provide for the cancellation of any or all amounts of indebtedness except as provided in subsection (d). (d) Cancellation of Indebtedness.-- (1) The President may not before November 15, 2024 take any action related to the indebtedness of the Government of Ukraine that cancels any indebtedness incurred by Ukraine pursuant to this section. (2) At any time after November 15, 2024, the President may, subject to congressional review provided by section 508, cancel up to 50 percent of the total indebtedness incurred by Ukraine or anticipated to be incurred by Ukraine with respect to economic assistance and related expenses made available under the headings ``Economic Support Fund'' and ``Assistance for Europe, Eurasia, and Central Asia'' in title IV of this Act. Upon completion of the congressional review process set forth in section 508, such cancellation shall be final and irrevocable. (3) The President may, subject to congressional review provided by section 508, cancel any remaining indebtedness to the government of Ukraine under this section at any time after January 1, 2026. Upon completion of the congressional review process set forth in section 508, such cancellation shall be final and irrevocable. Sec. 508. (a) Report Required.-- (1) In General.--Notwithstanding any other provision of law, before taking any action described in paragraph (2), the President shall submit to Congress a written report that describes that action and the reason for that action. (2) Action Described.--An action described in this paragraph is an action related to the indebtedness of the Government of Ukraine authorized by section 507(d)(1). (b) Congressional Review Period.-- (1) 2024.--During calendar year 2024, if the President submits to Congress a report under subsection (a)(1), the President may not take any action with respect to the indebtedness of the Government of Ukraine until the later of-- (A) the date that is 10 calendar days after the date of such submission; or (B) the date on which Congress has considered and failed to pass a joint resolution of disapproval, as provided in this section. (2) Succeeding Years.-- (A) In general.--During calendar year 2025 or any calendar year thereafter, if the President submits to Congress a report under subsection (a)(1), the President may not take any action with respect to the indebtedness of the Government of Ukraine until the later of-- (i) the date that is 30 calendar days after the date of such submission, except as provided in subparagraph (B); or (ii) the date on which Congress has failed to pass a joint resolution of disapproval, as provided in this section. (B) Exception.--The period for congressional review of a report submitted under subsection (a)(1) shall be 60 calendar days if the report is submitted to Congress on or after July 10 and on or before September 7 in any calendar year. (3) Veto Message.--If the President vetoes a joint resolution of disapproval, he may not take any action with respect to the indebtedness of Ukraine for 5 calendar days after the veto message is received by the appropriate House of Congress. (c) Joint Resolution of Disapproval.--In this section, the term ``joint resolution'' means only a joint resolution-- (1) that is introduced not later than 3 calendar days after the date on which a report of the President referred to in subsection (a)(1) is received by Congress; (2) which does not have a preamble; (3) the title of which is as follows: ``Joint resolution relating to the disapproval of the Presidential report with respect to the indebtedness of the Government of Ukraine''; and (4) the matter after the resolving clause of which is as follows: ``That Congress disapproves the proposal relating to the indebtedness of the Government of Ukraine submitted by the President of the United States to Congress on _____'', with the blank space filled with the appropriate date of submission of the report under subsection (a)(1). (d) Fast-track Consideration in House of Representatives.-- (1) Reporting and Discharge.--Any committee of the House of Representatives to which a joint resolution is referred shall report the joint resolution to the House of Representatives not later than 5 calendar days after the date on which Congress receives the report described in subsection (a)(1). If a committee fails to report the joint resolution within that period, the committee shall be discharged from further consideration of the joint resolution and the joint resolution shall be referred to the appropriate calendar. (2) Proceeding to Consideration.--After each committee authorized to consider a joint resolution reports the joint resolution to the House of Representatives or has been discharged from its consideration, it shall be in order, not later than the 6th calendar day after the date on which Congress receives the report described in subsection (a)(1), to move to proceed to consider the joint resolution in the House of Representatives. All points of order against the motion are waived. Such a motion shall not be in order after the House of Representatives has disposed of a motion to proceed on the joint resolution. The previous question shall be considered as ordered on the motion to its adoption without intervening motion. The motion shall not be debatable. A motion to reconsider the vote by which the motion is disposed of shall not be in order. (3) Consideration.--The joint resolution shall be considered as read. All points of order against the joint resolution and against its consideration are waived. The previous question shall be considered as ordered on the joint resolution to its passage without intervening motion except two hours of debate equally divided and controlled by the proponent and an opponent. A motion to reconsider the vote on passage of the joint resolution shall not be in order. (e) Fast-track Consideration in Senate.-- (1) Placement on Calendar.--Upon introduction in the Senate, the joint resolution shall be placed immediately on the calendar. (2) Floor Consideration.-- (A) In general.--It shall not be in order to move to proceed to a joint resolution that has been placed on the calendar pursuant to paragraph (1) unless a motion signed by 16 Senators has been presented to the Senate. Thereafter, notwithstanding Rule XXII of the Standing Rules of the Senate, it is in order, during the periods described in subparagraph (B) (even though a previous motion to the same effect has been disagreed to), for any Senator to move to proceed to the consideration of the joint resolution, and all points of order against the joint resolution (and against consideration of the joint resolution) are waived. The motion to proceed is not debatable. The motion is not subject to a motion to postpone. A motion to reconsider the vote by which the motion is agreed to or disagreed to shall not be in order. If a motion to proceed to the consideration of the joint resolution is agreed to, the joint resolution shall remain the unfinished business until disposed of. (B) Periods described.--The periods described in this subparagraph are the following: (i) During calendar year 2024, the period beginning on the day after the date on which the joint resolution was placed on the calendar and ending on the 4th day after the date on which the joint resolution was placed on the calendar. (ii) During succeeding years under subsection (b)(2)(A), the period beginning on the day after the date on which the joint resolution was placed on the calendar and ending 20 calendar days later. (iii) During succeeding years under subsection (b)(2)(B), the period beginning on the day after the date on which the joint resolution was placed on the calendar and ending 50 calendar days later. (C) Debate.--Debate on the joint resolution, and on all debatable motions and appeals in connection therewith, shall be limited to not more than 10 hours, which shall be divided equally between the majority and minority leaders or their designees. A motion further to limit debate is in order and not debatable. An amendment to, or a motion to postpone, or a motion to proceed to the consideration of other business, or a motion to recommit the joint resolution is not in order. (D) Vote on passage.--The vote on passage shall occur immediately following the conclusion of the debate on a joint resolution and a single quorum call at the conclusion of the debate if requested in accordance with the rules of the Senate. (E) Rulings of the chair on procedure.--Appeals from the decisions of the Chair relating to the application of the rules of the Senate, as the case may be, to the procedure relating to a joint resolution shall be decided without debate. (F) One joint resolution of disapproval per review period.--Only one joint resolution shall be in order during each of the review periods described in subsection (b), unless the additional joint resolution is a joint resolution of the House of Representatives considered under paragraph (2) or (3) of subsection (f). (f) Rules Relating to Senate and House of Representatives.-- (1) Coordination With Action by Other House.--If, before the passage by one House of a joint resolution of that House, that House receives from the other House a joint resolution, then the following procedures shall apply: (A) The joint resolution of the other House shall not be referred to a committee. (B) With respect to a joint resolution of the House receiving the resolution-- (i) the procedure in that House shall be the same as if no joint resolution had been received from the other House; but (ii) the vote on passage shall be on the joint resolution of the other House. (2) Treatment of Joint Resolution of Other House.--If one House fails to introduce or consider a joint resolution under this section, the joint resolution of the other House shall be entitled to expedited floor procedures under this section. (3) Treatment of Companion Measures.--If, following passage of the joint resolution in the Senate, the Senate then receives the companion measure from the House of Representatives, the companion measure shall not be debatable. (4) Consideration After Passage.-- (A) In general.--If Congress passes a joint resolution, the period beginning on the date on which the President is presented with the joint resolution and ending on the date on which the President takes action with respect to the joint resolution shall be disregarded in computing the 10-, 30-, or 60-calendar-day period described in subsection (b), but the President may not take any action with respect to the indebtedness of the Government of Ukraine during any such period. (B) Vetoes.--If the President vetoes the joint resolution, debate on a veto message in the Senate under this section shall be 1 hour equally divided between the majority and minority leaders or their designees. (5) Rules of House of Representatives and Senate.--This subsection and subsections (c), (d), and (e) are enacted by Congress-- (A) as an exercise of the rulemaking power of the Senate and House of Representatives, respectively, and as such are deemed a part of the rules of each House, respectively, but applicable only with respect to the procedure to be followed in that House in the case of a joint resolution, and supersede other rules only to the extent that they are inconsistent with such rules; and (B) with full recognition of the constitutional right of either House to change the rules (so far as relating to the procedure of that House) at any time, in the same manner, and to the same extent as in the case of any other rule of that House. Sec. 509. Funds appropriated by this Act for foreign assistance (including foreign military sales), for the Department of State, for broadcasting subject to supervision of United States Agency for Global Media, and for intelligence or intelligence related activities are deemed to be specifically authorized by the Congress for the purposes of section 10 of Public Law 91-672 (22 U.S.C. 2412), section 15 of the State Department Basic Authorities Act of 1956 (22 U.S.C. 2680), section 313 of the Foreign Relations Authorization Act, Fiscal Years 1994 and 1995 (22 U.S.C. 6212), and section 504(a)(1) of the National Security Act of 1947 (50 U.S.C. 3094(a)(1)). Sec. 510. Each amount designated in this Act by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985 shall be available (or repurposed or rescinded, if applicable) only if the President subsequently so designates all such amounts and transmits such designations to the Congress. Sec. 511. Any amount appropriated by this Act, designated by the Congress as an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985, and subsequently so designated by the President, and transferred pursuant to transfer authorities provided by this Act shall retain such designation. spending reduction account Sec. 512. $0. This Act may be cited as the ``Ukraine Security Supplemental Appropriations Act, 2024''. <all>

---
snapshot_id: 507083df-f6ce-5cd1-a851-3fd02f22ff45
source_kind: public-record
url: https://clerk.house.gov/Votes/2023503

Office of the Clerk, U.S. House of Representatives Find Your Representative Search Office of the Clerk Toggle navigation Search Office of the Clerk Search button Legislative Information Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions 119th Congress, 2nd Session House Not In Session Next Session: October 9th, 2026 at 12:30 PM House Floor Proceedings Watch live.house.gov Additional Resources Votes Legacy View - 2024 119th Congress Nominees Statistics of the 2024 Congressional Election Final House Calendar (118th Congress) Résumé of Congressional Activity Legislative Search Congressional Record U.S. Senate House Schedule Bills This Week House Voting Days Member Information Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Republicans 218 218 Democrats 214 214 Independents 1 1 Vacancies 2 2 Republican Leadership Rep. Mike Johnson Speaker of the House Rep. Steve Scalise Majority Leader Rep. Tom Emmer Majority Whip Rep. Lisa C. McClain Republican Conference Chair Rep. Jay Obernolte Republican Policy Committee Chair Democratic Leadership Rep. Hakeem S. Jeffries Minority Leader Rep. Katherine M. Clark Minority Whip Rep. Pete Aguilar Democratic Caucus Chair Rep. Ted Lieu Democratic Caucus Vice Chair Additional Resources Find Your Representative Official List of Members by State Official Member Telephone Directory Duplicate and Similar Names of Members Terms of Service Mailing Labels [ MS Word | Text File ] Member Data [ Excel | XML | User Guide ] Biographical Directory Members on Congress.gov Committee Information COMMITTEE INFORMATION COMMITTEE PROFILES Agriculture Appropriations Armed Services Budget Education and Workforce Energy and Commerce Ethics Financial Services Foreign Affairs Homeland Security House Administration Judiciary Natural Resources Oversight and Government Reform Rules Science, Space, and Technology Small Business Transportation and Infrastructure Veterans' Affairs Ways and Means Select Intelligence Select Strategic Competition Joint Economic Joint Library Joint Printing Joint Taxation Additional Resources Official List of Members with Committee Assignments Official List of Standing Committees and Subcommittees Committee Repository Committee Reports Committees on Congress.gov Committee Data [ Excel ] Disclosures Disclosures PUBLIC DISCLOSURE Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications Additional Resources Lobbying Disclosures Public Laws Lobbying Disclosure Act About the Clerk About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office The Clerk of the House The Honorable Kevin F. McCumber Clerk of the U.S. House of Representatives Deputy Clerk Michelle H. Reinshuttle Deputy Clerk Contact Information Mailing Address U.S. Capitol Room H154 Washington, DC 20515&ndash;6601 Telephone Number (202) 225&ndash;7000 Office Hours 9:00 AM&ndash;6:00 PM, Monday&ndash;Friday Additional Resources Artificial Intelligence Use Case Inventory [ USHouse-Clerk-1: Comparative Print Suite ] 119th Congress, 2nd Session Back to Previous Page Roll Call 503 | Bill Number: H. R. 5692 Share XML View | HTML View Sep 28, 2023, 11:00 PM | 118th Congress, 1st Session Vote Question: On Passage Making supplemental appropriations for the fiscal year ending September 30, 2024, and for other purposes Vote Type: Yea-And-Nay Status: Passed VOTES yea: 311 nay: 117 present: 0 not voting: 5 Remote Voting by Proxy Votes by party votes by party Party Yeas Nays Present Not Voting Republican 101 117 0 3 Democratic 210 0 0 2 Independent 0 0 0 0 Total 311 117 0 5 All votes Keyword Name Party All Parties Republican Democratic Independent State All States Votes All Votes YEA/AYE NAY/NO PRESENT NOT VOTING All votes Representative Party State Vote Adams Adams Democratic North Carolina NC Yea Aderholt Aderholt Republican Alabama AL Yea Aguilar Aguilar Democratic California CA Yea Alford Alford Republican Missouri MO Yea Allen Allen Republican Georgia GA Nay Allred Allred Democratic Texas TX Yea Amodei Amodei Republican Nevada NV Yea Armstrong Armstrong Republican North Dakota ND Yea Arrington Arrington Republican Texas TX Nay Auchincloss Auchincloss Democratic Massachusetts MA Yea Babin Babin Republican Texas TX Nay Bacon Bacon Republican Nebraska NE Yea Baird Baird Republican Indiana IN Yea Balderson Balderson Republican Ohio OH Yea Balint Balint Democratic Vermont VT Yea Banks Banks Republican Indiana IN Nay Barr Barr Republican Kentucky KY Yea Barragán Barragan Democratic California CA Yea Bean (FL) Bean (FL) Republican Florida FL Nay Beatty Beatty Democratic Ohio OH Yea Bentz Bentz Republican Oregon OR Yea Bera Bera Democratic California CA Yea Bergman Bergman Republican Michigan MI Yea Beyer Beyer Democratic Virginia VA Yea Bice Bice Republican Oklahoma OK Yea Biggs Biggs Republican Arizona AZ Nay Bilirakis Bilirakis Republican Florida FL Nay Bishop (GA) Bishop (GA) Democratic Georgia GA Yea Bishop (NC) Bishop (NC) Republican North Carolina NC Nay Blumenauer Blumenauer Democratic Oregon OR Yea Blunt Rochester Blunt Rochester Democratic Delaware DE Yea Boebert Boebert Republican Colorado CO Nay Bonamici Bonamici Democratic Oregon OR Yea Bost Bost Republican Illinois IL Nay Bowman Bowman Democratic New York NY Yea Boyle (PA) Boyle (PA) Democratic Pennsylvania PA Yea Brecheen Brecheen Republican Oklahoma OK Nay Brown Brown Democratic Ohio OH Yea Brownley Brownley Democratic California CA Yea Buchanan Buchanan Republican Florida FL Nay Buck Buck Republican Colorado CO Yea Bucshon Bucshon Republican Indiana IN Yea Budzinski Budzinski Democratic Illinois IL Yea Burchett Burchett Republican Tennessee TN Nay Burgess Burgess Republican Texas TX Nay Burlison Burlison Republican Missouri MO Nay Bush Bush Democratic Missouri MO Not Voting Calvert Calvert Republican California CA Yea Cammack Cammack Republican Florida FL Nay Caraveo Caraveo Democratic Colorado CO Yea Carbajal Carbajal Democratic California CA Yea Cárdenas Cardenas Democratic California CA Yea Carey Carey Republican Ohio OH Nay Carl Carl Republican Alabama AL Nay Carson Carson Democratic Indiana IN Yea Carter (GA) Carter (GA) Republican Georgia GA Nay Carter (LA) Carter (LA) Democratic Louisiana LA Yea Carter (TX) Carter (TX) Republican Texas TX Not Voting Cartwright Cartwright Democratic Pennsylvania PA Yea Casar Casar Democratic Texas TX Yea Case Case Democratic Hawaii HI Yea Casten Casten Democratic Illinois IL Yea Castor (FL) Castor (FL) Democratic Florida FL Yea Castro (TX) Castro (TX) Democratic Texas TX Yea Chavez-DeRemer Chavez-DeRemer Republican Oregon OR Yea Cherfilus-McCormick Cherfilus-McCormick Democratic Florida FL Yea Chu Chu Democratic California CA Yea Ciscomani Ciscomani Republican Arizona AZ Yea Clark (MA) Clark (MA) Democratic Massachusetts MA Yea Clarke (NY) Clarke (NY) Democratic New York NY Yea Cleaver Cleaver Democratic Missouri MO Yea Cline Cline Republican Virginia VA Nay Cloud Cloud Republican Texas TX Nay Clyburn Clyburn Democratic South Carolina SC Yea Clyde Clyde Republican Georgia GA Nay Cohen Cohen Democratic Tennessee TN Yea Cole Cole Republican Oklahoma OK Yea Collins Collins Republican Georgia GA Nay Comer Comer Republican Kentucky KY Nay Connolly Connolly Democratic Virginia VA Yea Correa Correa Democratic California CA Yea Costa Costa Democratic California CA Yea Courtney Courtney Democratic Connecticut CT Yea Craig Craig Democratic Minnesota MN Yea Crane Crane Republican Arizona AZ Nay Crawford Crawford Republican Arkansas AR Nay Crenshaw Crenshaw Republican Texas TX Yea Crockett Crockett Democratic Texas TX Yea Crow Crow Democratic Colorado CO Yea Cuellar Cuellar Democratic Texas TX Yea Curtis Curtis Republican Utah UT Nay D'Esposito D'Esposito Republican New York NY Yea Davids (KS) Davids (KS) Democratic Kansas KS Yea Davidson Davidson Republican Ohio OH Nay Davis (IL) Davis (IL) Democratic Illinois IL Yea Davis (NC) Davis (NC) Democratic North Carolina NC Yea De La Cruz De La Cruz Republican Texas TX Nay Dean (PA) Dean (PA) Democratic Pennsylvania PA Yea DeGette DeGette Democratic Colorado CO Yea DeLauro DeLauro Democratic Connecticut CT Yea DelBene DelBene Democratic Washington WA Yea Deluzio Deluzio Democratic Pennsylvania PA Yea DeSaulnier DeSaulnier Democratic California CA Yea DesJarlais DesJarlais Republican Tennessee TN Yea Diaz-Balart Diaz-Balart Republican Florida FL Yea Dingell Dingell Democratic Michigan MI Yea Doggett Doggett Democratic Texas TX Yea Donalds Donalds Republican Florida FL Nay Duarte Duarte Republican California CA Yea Duncan Duncan Republican South Carolina SC Nay Dunn (FL) Dunn (FL) Republican Florida FL Yea Edwards Edwards Republican North Carolina NC Nay Ellzey Ellzey Republican Texas TX Yea Emmer Emmer Republican Minnesota MN Yea Escobar Escobar Democratic Texas TX Yea Eshoo Eshoo Democratic California CA Yea Espaillat Espaillat Democratic New York NY Yea Estes Estes Republican Kansas KS Nay Evans Evans Democratic Pennsylvania PA Yea Ezell Ezell Republican Mississippi MS Nay Fallon Fallon Republican Texas TX Nay Feenstra Feenstra Republican Iowa IA Nay Ferguson Ferguson Republican Georgia GA Yea Finstad Finstad Republican Minnesota MN Nay Fischbach Fischbach Republican Minnesota MN Nay Fitzgerald Fitzgerald Republican Wisconsin WI Nay Fitzpatrick Fitzpatrick Republican Pennsylvania PA Yea Fleischmann Fleischmann Republican Tennessee TN Yea Fletcher Fletcher Democratic Texas TX Yea Flood Flood Republican Nebraska NE Yea Foster Foster Democratic Illinois IL Yea Foushee Foushee Democratic North Carolina NC Yea Foxx Foxx Republican North Carolina NC Yea Frankel, Lois Frankel, Lois Democratic Florida FL Yea Franklin, C. Scott Franklin, C. Scott Republican Florida FL Nay Frost Frost Democratic Florida FL Yea Fry Fry Republican South Carolina SC Nay Fulcher Fulcher Republican Idaho ID Nay Gaetz Gaetz Republican Florida FL Nay Gallagher Gallagher Republican Wisconsin WI Yea Gallego Gallego Democratic Arizona AZ Yea Garamendi Garamendi Democratic California CA Yea Garbarino Garbarino Republican New York NY Yea García (IL) Garcia (IL) Democratic Illinois IL Yea Garcia (TX) Garcia (TX) Democratic Texas TX Yea Garcia, Mike Garcia, Mike Republican California CA Nay Garcia, Robert Garcia, Robert Democratic California CA Yea Gimenez Gimenez Republican Florida FL Yea Golden (ME) Golden (ME) Democratic Maine ME Yea Goldman (NY) Goldman (NY) Democratic New York NY Yea Gomez Gomez Democratic California CA Yea Gonzales, Tony Gonzales, Tony Republican Texas TX Not Voting Gonzalez, Vicente Gonzalez, Vicente Democratic Texas TX Yea Good (VA) Good (VA) Republican Virginia VA Nay Gooden (TX) Gooden (TX) Republican Texas TX Nay Gosar Gosar Republican Arizona AZ Nay Gottheimer Gottheimer Democratic New Jersey NJ Yea Granger Granger Republican Texas TX Yea Graves (LA) Graves (LA) Republican Louisiana LA Nay Graves (MO) Graves (MO) Republican Missouri MO Yea Green (TN) Green (TN) Republican Tennessee TN Nay Green, Al (TX) Green, Al (TX) Democratic Texas TX Yea Greene (GA) Greene (GA) Republican Georgia GA Nay Griffith Griffith Republican Virginia VA Nay Grijalva Grijalva Democratic Arizona AZ Yea Grothman Grothman Republican Wisconsin WI Yea Guest Guest Republican Mississippi MS Nay Guthrie Guthrie Republican Kentucky KY Yea Hageman Hageman Republican Wyoming WY Nay Harder (CA) Harder (CA) Democratic California CA Yea Harris Harris Republican Maryland MD Yea Harshbarger Harshbarger Republican Tennessee TN Nay Hayes Hayes Democratic Connecticut CT Yea Hern Hern Republican Oklahoma OK Nay Higgins (LA) Higgins (LA) Republican Louisiana LA Nay Higgins (NY) Higgins (NY) Democratic New York NY Yea Hill Hill Republican Arkansas AR Yea Himes Himes Democratic Connecticut CT Yea Hinson Hinson Republican Iowa IA Nay Horsford Horsford Democratic Nevada NV Yea Houchin Houchin Republican Indiana IN Nay Houlahan Houlahan Democratic Pennsylvania PA Yea Hoyer Hoyer Democratic Maryland MD Yea Hoyle (OR) Hoyle (OR) Democratic Oregon OR Yea Hudson Hudson Republican North Carolina NC Yea Huffman Huffman Democratic California CA Yea Huizenga Huizenga Republican Michigan MI Yea Hunt Hunt Republican Texas TX Nay Issa Issa Republican California CA Yea Ivey Ivey Democratic Maryland MD Yea Jackson (IL) Jackson (IL) Democratic Illinois IL Yea Jackson (NC) Jackson (NC) Democratic North Carolina NC Yea Jackson (TX) Jackson (TX) Republican Texas TX Nay Jackson Lee Jackson Lee Democratic Texas TX Yea Jacobs Jacobs Democratic California CA Yea James James Republican Michigan MI Yea Jayapal Jayapal Democratic Washington WA Yea Jeffries Jeffries Democratic New York NY Yea Johnson (GA) Johnson (GA) Democratic Georgia GA Yea Johnson (LA) Johnson (LA) Republican Louisiana LA Nay Johnson (OH) Johnson (OH) Republican Ohio OH Yea Johnson (SD) Johnson (SD) Republican South Dakota SD Yea Jordan Jordan Republican Ohio OH Nay Joyce (OH) Joyce (OH) Republican Ohio OH Yea Joyce (PA) Joyce (PA) Republican Pennsylvania PA Nay Kamlager-Dove Kamlager-Dove Democratic California CA Yea Kaptur Kaptur Democratic Ohio OH Yea Kean (NJ) Kean (NJ) Republican New Jersey NJ Yea Keating Keating Democratic Massachusetts MA Yea Kelly (IL) Kelly (IL) Democratic Illinois IL Yea Kelly (MS) Kelly (MS) Republican Mississippi MS Nay Kelly (PA) Kelly (PA) Republican Pennsylvania PA Nay Khanna Khanna Democratic California CA Yea Kiggans (VA) Kiggans (VA) Republican Virginia VA Yea Kildee Kildee Democratic Michigan MI Yea Kiley Kiley Republican California CA Yea Kilmer Kilmer Democratic Washington WA Yea Kim (CA) Kim (CA) Republican California CA Yea Kim (NJ) Kim (NJ) Democratic New Jersey NJ Yea Krishnamoorthi Krishnamoorthi Democratic Illinois IL Yea Kuster Kuster Democratic New Hampshire NH Yea Kustoff Kustoff Republican Tennessee TN Yea LaHood LaHood Republican Illinois IL Nay LaLota LaLota Republican New York NY Nay LaMalfa LaMalfa Republican California CA Yea Lamborn Lamborn Republican Colorado CO Yea Landsman Landsman Democratic Ohio OH Yea Langworthy Langworthy Republican New York NY Nay Larsen (WA) Larsen (WA) Democratic Washington WA Yea Larson (CT) Larson (CT) Democratic Connecticut CT Yea Latta Latta Republican Ohio OH Yea LaTurner LaTurner Republican Kansas KS Nay Lawler Lawler Republican New York NY Yea Lee (CA) Lee (CA) Democratic California CA Yea Lee (FL) Lee (FL) Republican Florida FL Yea Lee (NV) Lee (NV) Democratic Nevada NV Yea Lee (PA) Lee (PA) Democratic Pennsylvania PA Yea Leger Fernandez Leger Fernandez Democratic New Mexico NM Yea Lesko Lesko Republican Arizona AZ Yea Letlow Letlow Republican Louisiana LA Nay Levin Levin Democratic California CA Yea Lieu Lieu Democratic California CA Yea Lofgren Lofgren Democratic California CA Yea Loudermilk Loudermilk Republican Georgia GA Nay Lucas Lucas Republican Oklahoma OK Yea Luetkemeyer Luetkemeyer Republican Missouri MO Yea Luna Luna Republican Florida FL Not Voting Luttrell Luttrell Republican Texas TX Nay Lynch Lynch Democratic Massachusetts MA Yea Mace Mace Republican South Carolina SC Nay Magaziner Magaziner Democratic Rhode Island RI Yea Malliotakis Malliotakis Republican New York NY Yea Mann Mann Republican Kansas KS Nay Manning Manning Democratic North Carolina NC Yea Massie Massie Republican Kentucky KY Nay Mast Mast Republican Florida FL Nay Matsui Matsui Democratic California CA Yea McBath McBath Democratic Georgia GA Yea McCarthy McCarthy Republican California CA Yea McCaul McCaul Republican Texas TX Yea McClain McClain Republican Michigan MI Nay McClellan McClellan Democratic Virginia VA Yea McClintock McClintock Republican California CA Yea McCollum McCollum Democratic Minnesota MN Yea McCormick McCormick Republican Georgia GA Yea McGarvey McGarvey Democratic Kentucky KY Yea McGovern McGovern Democratic Massachusetts MA Yea McHenry McHenry Republican North Carolina NC Yea Meeks Meeks Democratic New York NY Yea Menendez Menendez Democratic New Jersey NJ Yea Meng Meng Democratic New York NY Yea Meuser Meuser Republican Pennsylvania PA Nay Mfume Mfume Democratic Maryland MD Yea Miller (IL) Miller (IL) Republican Illinois IL Nay Miller (OH) Miller (OH) Republican Ohio OH Yea Miller (WV) Miller (WV) Republican West Virginia WV Nay Miller-Meeks Miller-Meeks Republican Iowa IA Nay Mills Mills Republican Florida FL Nay Molinaro Molinaro Republican New York NY Yea Moolenaar Moolenaar Republican Michigan MI Nay Mooney Mooney Republican West Virginia WV Nay Moore (AL) Moore (AL) Republican Alabama AL Nay Moore (UT) Moore (UT) Republican Utah UT Yea Moore (WI) Moore (WI) Democratic Wisconsin WI Yea Moran Moran Republican Texas TX Nay Morelle Morelle Democratic New York NY Yea Moskowitz Moskowitz Democratic Florida FL Yea Moulton Moulton Democratic Massachusetts MA Yea Mrvan Mrvan Democratic Indiana IN Yea Mullin Mullin Democratic California CA Yea Murphy Murphy Republican North Carolina NC Nay Nadler Nadler Democratic New York NY Yea Napolitano Napolitano Democratic California CA Yea Neal Neal Democratic Massachusetts MA Yea Neguse Neguse Democratic Colorado CO Yea Nehls Nehls Republican Texas TX Nay Newhouse Newhouse Republican Washington WA Yea Nickel Nickel Democratic North Carolina NC Yea Norcross Norcross Democratic New Jersey NJ Yea Norman Norman Republican South Carolina SC Nay Nunn (IA) Nunn (IA) Republican Iowa IA Nay Obernolte Obernolte Republican California CA Yea Ocasio-Cortez Ocasio-Cortez Democratic New York NY Yea Ogles Ogles Republican Tennessee TN Nay Omar Omar Democratic Minnesota MN Yea Owens Owens Republican Utah UT Nay Pallone Pallone Democratic New Jersey NJ Yea Palmer Palmer Republican Alabama AL Nay Panetta Panetta Democratic California CA Yea Pappas Pappas Democratic New Hampshire NH Yea Pascrell Pascrell Democratic New Jersey NJ Yea Payne Payne Democratic New Jersey NJ Yea Pelosi Pelosi Democratic California CA Yea Peltola Peltola Democratic Alaska AK Not Voting Pence Pence Republican Indiana IN Nay Perez Perez Democratic Washington WA Yea Perry Perry Republican Pennsylvania PA Nay Peters Peters Democratic California CA Yea Pettersen Pettersen Democratic Colorado CO Yea Pfluger Pfluger Republican Texas TX Nay Phillips Phillips Democratic Minnesota MN Yea Pingree Pingree Democratic Maine ME Yea Pocan Pocan Democratic Wisconsin WI Yea Porter Porter Democratic California CA Yea Posey Posey Republican Florida FL Nay Pressley Pressley Democratic Massachusetts MA Yea Quigley Quigley Democratic Illinois IL Yea Ramirez Ramirez Democratic Illinois IL Yea Raskin Raskin Democratic Maryland MD Yea Reschenthaler Reschenthaler Republican Pennsylvania PA Yea Rodgers (WA) Rodgers (WA) Republican Washington WA Yea Rogers (AL) Rogers (AL) Republican Alabama AL Yea Rogers (KY) Rogers (KY) Republican Kentucky KY Yea Rose Rose Republican Tennessee TN Yea Rosendale Rosendale Republican Montana MT Nay Ross Ross Democratic North Carolina NC Yea Rouzer Rouzer Republican North Carolina NC Yea Roy Roy Republican Texas TX Nay Ruiz Ruiz Democratic California CA Yea Ruppersberger Ruppersberger Democratic Maryland MD Yea Rutherford Rutherford Republican Florida FL Yea Ryan Ryan Democratic New York NY Yea Salazar Salazar Republican Florida FL Yea Salinas Salinas Democratic Oregon OR Yea Sánchez Sanchez Democratic California CA Yea Santos Santos Republican New York NY Nay Sarbanes Sarbanes Democratic Maryland MD Yea Scalise Scalise Republican Louisiana LA Yea Scanlon Scanlon Democratic Pennsylvania PA Yea Schakowsky Schakowsky Democratic Illinois IL Yea Schiff Schiff Democratic California CA Yea Schneider Schneider Democratic Illinois IL Yea Scholten Scholten Democratic Michigan MI Yea Schrier Schrier Democratic Washington WA Yea Schweikert Schweikert Republican Arizona AZ Yea Scott (VA) Scott (VA) Democratic Virginia VA Yea Scott, Austin Scott, Austin Republican Georgia GA Yea Scott, David Scott, David Democratic Georgia GA Yea Self Self Republican Texas TX Nay Sessions Sessions Republican Texas TX Yea Sewell Sewell Democratic Alabama AL Yea Sherman Sherman Democratic California CA Yea Sherrill Sherrill Democratic New Jersey NJ Yea Simpson Simpson Republican Idaho ID Yea Slotkin Slotkin Democratic Michigan MI Yea Smith (MO) Smith (MO) Republican Missouri MO Nay Smith (NE) Smith (NE) Republican Nebraska NE Yea Smith (NJ) Smith (NJ) Republican New Jersey NJ Yea Smith (WA) Smith (WA) Democratic Washington WA Yea Smucker Smucker Republican Pennsylvania PA Yea Sorensen Sorensen Democratic Illinois IL Yea Soto Soto Democratic Florida FL Yea Spanberger Spanberger Democratic Virginia VA Yea Spartz Spartz Republican Indiana IN Yea Stansbury Stansbury Democratic New Mexico NM Yea Stanton Stanton Democratic Arizona AZ Yea Stauber Stauber Republican Minnesota MN Nay Steel Steel Republican California CA Yea Stefanik Stefanik Republican New York NY Yea Steil Steil Republican Wisconsin WI Yea Steube Steube Republican Florida FL Nay Stevens Stevens Democratic Michigan MI Yea Strickland Strickland Democratic Washington WA Yea Strong Strong Republican Alabama AL Yea Swalwell Swalwell Democratic California CA Yea Sykes Sykes Democratic Ohio OH Yea Takano Takano Democratic California CA Yea Tenney Tenney Republican New York NY Nay Thanedar Thanedar Democratic Michigan MI Yea Thompson (CA) Thompson (CA) Democratic California CA Yea Thompson (MS) Thompson (MS) Democratic Mississippi MS Yea Thompson (PA) Thompson (PA) Republican Pennsylvania PA Yea Tiffany Tiffany Republican Wisconsin WI Nay Timmons Timmons Republican South Carolina SC Nay Titus Titus Democratic Nevada NV Yea Tlaib Tlaib Democratic Michigan MI Yea Tokuda Tokuda Democratic Hawaii HI Yea Tonko Tonko Democratic New York NY Yea Torres (CA) Torres (CA) Democratic California CA Yea Torres (NY) Torres (NY) Democratic New York NY Yea Trahan Trahan Democratic Massachusetts MA Yea Trone Trone Democratic Maryland MD Yea Turner Turner Republican Ohio OH Yea Underwood Underwood Democratic Illinois IL Yea Valadao Valadao Republican California CA Yea Van Drew Van Drew Republican New Jersey NJ Nay Van Duyne Van Duyne Republican Texas TX Nay Van Orden Van Orden Republican Wisconsin WI Nay Vargas Vargas Democratic California CA Yea Vasquez Vasquez Democratic New Mexico NM Yea Veasey Veasey Democratic Texas TX Yea Velázquez Velazquez Democratic New York NY Yea Wagner Wagner Republican Missouri MO Yea Walberg Walberg Republican Michigan MI Yea Waltz Waltz Republican Florida FL Yea Wasserman Schultz Wasserman Schultz Democratic Florida FL Yea Waters Waters Democratic California CA Yea Watson Coleman Watson Coleman Democratic New Jersey NJ Yea Weber (TX) Weber (TX) Republican Texas TX Nay Webster (FL) Webster (FL) Republican Florida FL Nay Wenstrup Wenstrup Republican Ohio OH Nay Westerman Westerman Republican Arkansas AR Yea Wexton Wexton Democratic Virginia VA Yea Wild Wild Democratic Pennsylvania PA Yea Williams (GA) Williams (GA) Democratic Georgia GA Yea Williams (NY) Williams (NY) Republican New York NY Nay Williams (TX) Williams (TX) Republican Texas TX Nay Wilson (FL) Wilson (FL) Democratic Florida FL Yea Wilson (SC) Wilson (SC) Republican South Carolina SC Yea Wittman Wittman Republican Virginia VA Nay Womack Womack Republican Arkansas AR Yea Yakym Yakym Republican Indiana IN Yea Zinke Zinke Republican Montana MT Nay No data found 118 Contact Information Room H154, The Capitol Washington, DC 20515-6601 p: (202) 225-7000 For general inquiries: info.clerkweb@mail.house.gov For general technical support: techsupport.clerkweb@mail.house.gov Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Disclosures Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office Committee Information Committee Profiles Clerk Sites Bills This Week Biographical Directory Clerk Kids Committee Repository History, Art & Archives Office of the Chaplain Help & Resources FAQs Privacy Policy Site Map