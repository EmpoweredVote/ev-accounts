You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-pierce-tariffs-r3/labels/coder-1.json. Write JSON only, matching
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

### topic_key: tariffs
topic_id: 683c8084-2281-4920-a07c-18439b2dd413  served_revision_id: c9b67f92-c9b9-4f7e-a10b-c312a4219346
Question: How should trade policy balance domestic industry with global commerce?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. eliminate all tariffs and pursue completely free trade with every country.
  2. reduce most tariffs, keeping only limited exceptions.
  3. use tariffs selectively to protect key American industries and jobs.
  4. increase tariffs on countries that don't trade fairly with America.
  5. impose high tariffs on all imports to bring manufacturing back to America.

#### Annex

# tariffs — served revision c9b67f92-c9b9-4f7e-a10b-c312a4219346 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. The season pin is an older revision
(`9f094155-…`); coders code the served text below.

**Question:** "How should trade policy balance domestic industry with global commerce?"

**Orientation:** **inverted.** Rung 1 is the **least** government action (no tariffs at all), rung 5
the most (high tariffs on all imports). CLAUDE.md names Tariffs as a ladder that runs the other way
from the corpus convention. The rungs order **how widely and how high tariffs apply**.

**Levels with a lever:** federal. Congress holds the tariff power and has
delegated much of it to the President; members act through trade agreements, tariff bills and votes
to end the emergencies that some tariffs rest on. State and local officials hold no lever.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "tariff", "duty", "import tax", "levy", "free trade", "free-trade agreement" (FTA),
"USMCA", "most-favoured-nation" (MFN), "normal trade relations", "Section 232" (national security),
"Section 301" (unfair practices), "IEEPA" (emergency powers), "reciprocal tariffs", "baseline tariff",
"universal tariff", "de minimis", "dumping", "countervailing duties", "trade deficit", "reshoring".

1. **"eliminate all tariffs and pursue completely free trade with every country."**
   - Means: no tariffs on any import from any country.
   - Operative clauses: [a] eliminate all tariffs; [b] completely free trade with every country.
   - Establishing evidence looks like: own words that reject every tariff, for every country. "All"
     and "every" are absence clauses (V4.2 "Silence is not a clause").
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because a **free-trade agreement** removes tariffs. It removes them
     with one partner and keeps others → not [b]; alone → `direction-only` _(proposed)_.

2. **"reduce most tariffs, keeping only limited exceptions."**
   - Means: most tariffs are cut or removed; a small number stay.
   - Operative clauses: [a] reduce most tariffs; [b] keep only limited exceptions.
   - Establishing evidence looks like: own words or an instrument that rolls back tariffs broadly and
     names the few it keeps.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - The exceptions are no longer limited to products that harm the environment. Any limited set of
     exceptions meets [b].
   - Commonly confused with rung 3 because the "limited exceptions" can be key industries. Code 2
     when the passage calls for a **general reduction** of tariffs now in force; code 3 when it
     defends or adds tariffs on named sectors without a general reduction _(proposed)_.

3. **"use tariffs selectively to protect key American industries and jobs."**
   - Means: tariffs are a tool for some strategic industries; they are not a general policy.
   - Operative clauses: [a] selective — named industries or products; [b] to protect domestic
     industries and jobs.
   - Establishing evidence looks like: support for a sector tariff (steel, semiconductors, shipbuilding)
     **plus** something that excludes rungs 4 and 5 (own words against broad or country-wide
     tariffs). One sector tariff alone shows the protective side → `direction-only` _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a sector tariff often targets one country's products. The
     **basis** decides: protecting an industry → 3; answering a country's trade practices → 4
     _(proposed)_.

4. **"increase tariffs on countries that don't trade fairly with America."**
   - Means: raise tariffs on specific countries because of how they trade.
   - Operative clauses: [a] increase tariffs; [b] on countries named as trading unfairly.
   - Establishing evidence looks like: a bill or own words that raise tariffs on a named country for
     dumping, subsidies, currency practices or barriers to U.S. goods.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because "reciprocal" schedules reach nearly every country.
     A uniform baseline tariff on all imports with higher rates for named countries meets "all
     imports"; "high" needs own words or a rate the passage calls high, otherwise `direction-only`
     between rungs 4 and 5 _(ruled 2026-10-01)_.

5. **"impose high tariffs on all imports to bring manufacturing back to America."**
   - Means: a high tariff on everything the country imports, to move manufacturing home.
   - Operative clauses: [a] high; [b] on all imports; [c] to bring manufacturing back.
   - Establishing evidence looks like: own words or an instrument that sets a tariff on all (or
     nearly all) imports and calls it high or sets a rate the passage itself calls high. Clause [c]
     states the purpose; it is not a separate test _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Who sets tariffs.** A bill that requires Congress to approve new tariffs, or that returns tariff
  authority from the President, decides which branch acts, not what the tariff is → `adjacent`, the
  same reasoning as preemption (V2, H12) _(ruled 2026-10-01)_. A vote to end the emergency that a set of tariffs
  rests on is `on-question` (it ends those tariffs) but `direction-only`: one set is not "most
  tariffs" _(ruled 2026-10-01)_.
- **Trade agreements** cut tariffs with partners and keep others → `direction-only` _(proposed)_.
- **Sanctions, export controls and investment screening** are not tariffs → `adjacent`.
- **Trade adjustment aid, tariff-relief payments to farmers, or rebates from tariff revenue** →
  `adjacent` _(proposed)_.
- **Budget, reconciliation and omnibus votes** with a tariff item → V4 `multi-subject`.


## Sources

---
snapshot_id: 8525224d-ae39-5815-87ea-dd06381b4b18
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/9d4c9fdb-cbec-4d10-b0a5-3455c6db752d

# On the Record — Matt Pierce (72dd5219-490f-48bb-986e-183a6098d602) ## forum — Bloomington Regular Session - OTR page: https://ontherecord.empowered.vote/meetings/9d4c9fdb-cbec-4d10-b0a5-3455c6db752d - Video: (no video url) - Date on On the Record: 2026-06-09 · date in the source's file name: 2026-03-23 - Kind: forum · Regular Session · Bloomington - Linked races: 0b5ae739-aa3a-4bfd-b1bf-57cc1c380fd9, 0bab4038-45bc-42b6-a1df-38b98e742952 [2:57] Thank you. I'm asking for your vote in the upcoming May primary because I want to continue being a progressive voice for our community and our community's values at the State House. And that means, you know, treating everyone with dignity and respect and not attacking and trying to marginalize communities, creating an economy that works for everyone. affordable housing which we know is a big issue accessible and affordable health care is another thing people are crying out for we need to support our public schools not private schools we shouldn't be diverting our money away from our public schools we need to defend academic freedom and free speech on the IU campus and our other institutions of higher education and the other thing we have to do is we have to protect democracy that's a sad thing to say and so that means fighting things like attempts to redistrict in the middle of the decade I've had amendments to unmask ice I opposed the governor's military police bill and the ice compliance as well [4:21] Okay. Again, as I was saying broadly, it's just this whole basket of issues surrounding preservation of democracy, and that means fighting off voter suppression and these attempts to kind of militarize the law enforcement. That's a key thing. I think one of the other key things is the economy. We cannot have a system where some people have fabulous wealth while a significant number of people are struggling just to get by, and you have the middle class shrinking in the middle. And so that's a key thing. And, you know, the housing and health care and all that kind of fits into that affordability kind of issue. And I think also. academic freedom and free speech on our campus. I mean, it's really sad what you see happening at IU, having protesters in Dunn Meadow being arrested, faculty members dismissed and punished without due process. These are all things that I think we need to push back on. [8:36] Well, the root of the problem goes all the way back to when the Daniels administration decided that having a regular agency, Department of Commerce, was not good enough for economic development because open-door laws and other transparency requirements applied to that agency. So they decided to create, spin off, this economic development corporation. And the idea was they needed to have these kind of secret negotiations and deals. And what happened is over time... That just spun out into corruption, basically. What you had is self-dealing within the IEDC, and you had these crazy things like the LEAP project. They went out and paid outrageous sums of money for land up there, and they didn't even do their due diligence to figure out whether they had enough water for the things they wanted to do there. And all that was at the expense of the taxpayers, and it was because there was not the kind of credibility or the transparency that they needed. A final one to throw in there is this foundation, which is an appendix of IEDC. And in that case, what they would do is they would get these big contributions, charitable contributions, from mostly utilities. And those then would be used for these worldwide junkets. In the name of economic development, they would go to the Formula One race over in Europe, and the governor would go there and say, I'm making deals, you know, here in the suites of the sports events. And there really was no accountability for that. So I voted for a fuller investigation of what actually happened there. I think the current governor is trying to just blame it all on the last governor and move on. And I think we need to go back and really get to the bottom and the details of what happened there. And so I'm hopeful that that will happen. [10:35] Well, I think at this point, environmental issues and energy issues are inextricable. They're just wrapped together. And so I served for a long time on the Environmental Affairs Committee, and then I had an opportunity to become the ranking member, Democratic member of the Utilities Committee. And I've been a relentless advocate for renewable energy and moving us to a clean energy economy. And one of the most frustrating and dispiriting things is just how there's no interest among the Republican Party to address the climate change problem, despite the evidence that is confronting us with these abnormal weather events, flooding, real significant economic impacts, and longer-term impacts that are going to cause people's grandchildren, future generations, to have real problems. And it's really outrageous that the current people in charge are not willing to do something to try to solve these problems. And so I'm doing everything I can to push us to promote solar, rooftop solar. I fought the net metering law that kind of destroyed the economics of people being able to afford rooftop solar and become more independent and save money on their own energy bills on top of it. I've tried to... create more competition with energy. So way back when, I had several years in a row I put in what was called a feed-in tariff bill. It was based on what Germany has, where they basically allowed anybody to plug in. If you had renewable energy, wind or solar, you had a right to sell that into the utilities grid. And that really boosted up the amount of renewables they had there. [15:36] I haven't seen any politics more cynical and hateful than the Republicans at the State House when it comes to the LBGTQ plus community. You know, this all goes back to 2004. George Bush was in trouble because of his wars going into the election. He needed something to drive his base out to the polls. And so they cynically said, let's make marriage equality the big issue. And the same thing happened at the State House. And we went through year after year. of having to fight off this effort to take the so-called Defense of Marriage Act and put it in the state constitution. And I'm proud that at the time, the Democrats were in the majority. I was the chair of the Courts and Criminal Code Committee, and that constitutional amendment passed out of the Senate was sent to my committee, and I killed it. I said, I'm not giving this bill a hearing. I'm not participating in this cynical, hateful process. Since then, they moved on because people actually, the issue turned on them, right? And they no longer had the political power to attack marriage equality, so now they're attacking trans people. And it's sad. I fought off those efforts to— To basically marginalize that community and I've authored co-authored several bills with representative Campbell from Lafayette that attempts to at least begin to claw back this attack on parents' rights to decide what kind of health care their kids could get when they need gender-affirming care. And so I'll continue to work on those issues. [17:30] Well, what I have found during my time in the legislature, that you have to demand respect from the majority party. You can't just be kind of the go-along, nice guy, junior partner. You've got to really get up in their face sometimes. But you have to balance it out, because if you get in their face too much you end up getting marginalized yourself and so what i found just you know one example is the speaker went too far one day and he ruled out we had an amendment to expand voting rights to an election bill called Various Elections Matters. And the speaker said that our amendment was not germane. It violated the rules and could not be voted upon, which was insane because this bill had like 50 different election provisions of all types in it. And so we appealed the ruling of the chair and we debated it and I basically told the other people, like, My fellow Democrats, stand back. I'm taking this one. And I really went after the Speaker full bore. And I went through every single provision in that bill. I pointed out that it said various elections matter for the title. And I said what the Speaker just did here today is an abuse of power. And I challenged them to say, why are you afraid to vote on these bills? Why are you hiding behind the rules? to prevent yourself from being held accountable to the voters. And I said, it's gotta stop. Now, the interesting thing is, For about the next week or so, there was not a single ruling by the Speaker that our amendments were out of order on stuff that I think probably was stretching it a little bit. So you've got to learn how to push hard and command respect. [22:12] The affordable housing issue is kind of one of the more complex issues that I've come across because you have so many variables and factors impacting it, everything from interest rates to housing supply. We now have hedge funds coming in and buying up homes, competing with average buyers, and they have endless funds to come in, and so we're seeing kind of the housing corporatized. And so you've got to approach it from a lot of different angles, and so we need to do a better job, and this is probably Congress's job on Section 8 vouchers. The wait lists are too long for that. We have to do more to try to get more housing. And, you know, I was excited when in this session the Republicans said that they were actually going to start addressing affordability issues. And one of the things they said they were going to address was housing. But what they ended up doing is they had a home builder spearhead the bill, and the home builder said the big problem is we have too many regulations. And so by the time this affordable housing bill actually got before us in its final form, after it had gone through both houses, it was like a joke. It essentially outlawed two safety items because the home builder said they were too expensive. They had a deal keeping your house from burning down. And it also limited what kind of flood mitigation they could do for these retention ponds and things. And then finally it just told every local community you have to have a hearing. To discuss how your zoning laws might be impacting building, which I think we've already had those debates in our community here, and we continue to have them. [24:23] come up first yeah yeah so I'm I'm pleased that when we had the Black Lives Matters protests and that issue was forefront. One of the things I did is I called up the Republican Person I'd worked with on criminal code reform and I said look this we cannot allow this moment to pass without doing something about police brutality and making clear that we have to have a different way forward and I was pleased that we were able to get a bill put together that prohibited things like chokeholds some things that were resulting in people being injured or killed and stress de-escalation and put into the training rubrics for people at the law enforcement academy processes to try to avoid getting into the situations that we've just seen happen over and over again and so we have to we have to keep after that because after a while kind of people forget and they they maybe resort back to the old ways but i think that the other thing that that bill did which i thought was really important is I believe the most police officers want to serve their community, they want to protect the community, and they're very public spirited. But we unfortunately have a few people who seem to have a different set of priorities. And what would happen is when someone would do something that violated the rules of their department, they would just resign and move to the next department, which was easy because there's a shortage of officers. This bill requires the last department to have to share all the information about their personal records with the new potential hires. [28:15] Yeah, I have to admit, there's some days where just things go so crazy up there, you just want to kind of drop your head on the desk and say, like, I surrender. I mean, what can you possibly do to talk any sense into people? Or the worst thing I hate is, like, you made really good points on that bill, but I couldn't vote with you because, you know, my leadership would get mad at me or something. But, you know. There are just enough victories to keep me going. and that's really what continues to motivate me we had a tremendous victory by defeating redistricting and that was awesome and there are lesser victories that people don't particularly hear about all the time one that i can think of we had last session was uh this crazy bill that wanted to move to uh firing squads for executions which just like the nuttiest thing ever And, you know, I really pushed back on that bill, and it couldn't get enough votes within the House to actually move on to the Senate. And I thought that was another, you know, opportunity. So I think that the worst thing we can do is think of ourselves as helpless and hopeless and not having an ability to impact the system. And so particularly right now, I feel like coming up in this election in the fall, we have an opportunity to really take back some power to change the direction of the country and the state. And I think that is the critical thing to keep people focused on is don't give up hope. It's frustrating. It's dispiriting when you see this horrible legislation continue to come through the process. But we've had some victories, and we can have more victories if we all work together and focus on, basically, gaining that political power at the ballot box. [30:09] Yeah, this is really... um tough because i've offered some amendments on that i've been kind of i think it's because i drew the short straw but it ended up being like the house democrats point person on redistricting so i had to read all those grinding legal cases and everything and I think that it is achievable. It's happened in other states, but it's going to take a long-term movement. You know, I think it's something like the women earning the right to vote. I mean, those were multi-decade kinds of efforts, civil rights movement. I think it has to be something up to that level where it's almost a movement and you have to get people engaged enough to understand the impacts of redistricting. I think it's a root of a lot of our problems because when you pack all the Democrats together to dilute their power and that then creates lopsided Republican districts, the primaries become the elections that matter. And the general elections are really just kind of a rubber stamp kind of thing, and this reduces the accountability of the members. You know, there was a time when you had like a 52-48, 51-49 split in the House. Even a 55-48. A 45 split, which was considered a huge majority in those days. You could literally see people sweating as they were thinking about how to vote. They would see stuff like, oh, how are my people going to explain this back home? And now with 70 members and these lopsided districts, there's no sweating in the General Assembly. People just vote. how they want to they pander to their most extreme bases and there's no um there's no accountability because of that so we definitely need to do something on redistricting [34:24] Yeah, I think it's going to take a lot of education, particularly because, you know, over my objections, the Republicans adopted a law which took away the right of the student ID to be used as a voter ID, even though it met every exact. And I made the author of the bill. For like 15 or 20 minutes, I led him through every single aspect of this, and he could not give a good reason why they were doing it. And so that makes it harder to vote. So you've got to educate people about what you need to do to vote. One of the saddest things that I see, and it happens every election cycle, if you go to the county election board when they meet about 10 days after the election, they go through their provisional ballots. there will be 60 or 80 students who showed up to vote and they're not registered they're not registered in the county they're not even from the state they just showed up because they decided they wanted to vote and participate but they didn't understand that you have to get registered by a certain deadline that you have to get to the right precinct and what happened is you know i don't know if they thought their um provisional ballot would just magically count or what but it didn't and to think about all those votes that are not being accounted for is really bad so education is a key thing and then secondly the other part of education is helping people to understand who is doing what to them One reason why politicians are not held accountable when they don't address the needs of the people is because with this crazy media we have, social media, you can't figure out who's doing what to whom. And so we've got to work much harder for people to understand what votes, what parties are for their interests and against their interests. [36:32] Well, I think if you get back to the Indiana Economic Development Corporation, one of the biggest problems is they just got into this mindset of we're going to get the Fortune 500 company to come build a big factory here because we're going to give them these tremendous benefits. We will outbid the corporate welfare that we'll give to the people to get them here. And they ignored the ability of the small businesses, the startups right here. And so this is one thing where I agree with Governor Braun. He seems to be trying to redirect IEDC to be more focused toward something beyond just central Indiana and kind of the big corporations and the big kind of long bomb deals like the Leap District. And so I think that we need to redirect our efforts so that small businesses, that business that is prospering and it needs to get to the next level but it needs some help to get there, how do we help them do that? And then... We have to make sure that that assistance gets out across the state. And for Bloomington, it's particularly important that we support the tech sector, right? So we have a tech park here. We have a lot of people working really hard to build off of the industries we have now and to figure out how to get this kind of startup entrepreneurial economy going. And I think that if we put more effort into that, we have an opportunity to start some small businesses, some startups that could end up being quite substantial companies that would really help our community because we need better, higher-paying jobs in our community. We don't have enough of those. [40:03] think I'm up first okay all right you know one of the things that I think is really important if you're serving as a legislator is to look around the hearing rooms and the hallways of the Capitol and ask yourself who's not here Because oftentimes you hear only from the interest groups that can afford to have paid lobbyists at the State House who are there constantly, who build the relationships, who become friendly with legislators. And their viewpoints always get across. But there are many average everyday Hoosiers. who aren't organized in a way with the resources to have somebody on the scene at the state house every day working for their interests. And so that's where the responsibility of the legislators who represents all the people within his or her district. that legislator has to be thinking about who's not here, who's getting left out of the conversation. And that's one thing that I really pride myself on. So when the payday lenders show up and say, we need less regulation because we need to give people access to capital, I say, look, guys, this is not Fortune 500 companies talking about. You're exploiting struggling people. So let's not come up with some phony excuses for why you need stuff. We know what's going on here. And so people need legislators who will call out those people who want to prey upon people who are struggling the most. And so that's why I very much would like to be returned to the legislature. I'm asking the voters to return me there for another two years so I can continue working on those issues and representing all the people of District 61. [74:45] It was a good. [78:50] We got one going.

---
snapshot_id: f34bee8e-5eeb-58b1-adc7-f38a3c469e69
source_kind: own-site (the person's own site or account)
url: https://repmattpierce.substack.com/p/rep-matt-pierces-july-newsletter

Rep. Matt Pierce's July Newsletter Rep. Matt Pierce's Newsletter Subscribe Sign in Rep. Matt Pierce's July Newsletter The IURC releases its affordability report, Gov. Braun ends the Diversity Business Enterprise program and more. Rep. Matt Pierce Jul 30, 2026 Share Welcome to my monthly newsletter, where I provide legislative updates as your state representative for House District 61. Please reach out to me at h61@iga.in.gov if you have any comments, questions, or concerns. The Cost of Tariffs A study by the Midwest Economic Policy Institute (MEPI), a nonpartisan organization, and the Project for Middle Class Renewal (PMCR) at the University of Illinois has determined the cost of President Trump’s 2025 tariffs. The average Hoosier household had its costs raised by $2,600. There were 9,148 fewer manufacturing jobs in Indiana because of the tariffs. Low-income households took the biggest hit. The bottom 10% of households in the Midwest states of Illinois, Indiana, Iowa, Michigan, Minnesota, and Wisconsin had three times their share of total income impacted by tariffs, which caused higher-priced goods, compared to the top 10% of households. Of the Midwestern states, only Michigan was hit harder by the tariffs than Indiana. The study concluded, “The data reveals that Midwest states, with their robust consumer spending and manufacturing-intensive economies, bear high costs from escalating tariffs. New tariffs imposed by the Trump administration in 2025 increased household costs by thousands of dollars per year, disproportionately burdened working families, reduced manufacturing employment by thousands of jobs, and shrank the economy by billions of dollars in Illinois, Indiana, Iowa, Michigan, Minnesota, and Wisconsin.” You can read the full study at this link . IURC Releases Affordability Report, But More Work Remains On July 15, the Indiana Utility Regulatory Commission (IURC) released its energy affordability report, which followed the series of statewide listening sessions it hosted this spring. As a result of the report, the IURC announced plans to investigate two major drivers of increases in utility bills. One investigation will examine the profits utilities are allowed to collect on capital project investments. The other will look at how trackers, fluctuating charges added to bills for fuel expenses and other costs without a rate case proceeding, will fit into Indiana’s new regulatory structure. I attended the IURC’s listening session in Columbus and urged the IURC to recommend the legislature correct the many utility-friendly laws it has passed over the past decade. The affordability report recommended a few legislative changes. Two of the three recommendations have been attempted by House Democrats during past sessions, including: Eliminating the 7% state sales tax on residential utility bills : Everyone agrees you shouldn’t be taxing necessities, and clearly electric utilities, which allow you to heat and cool your home, are necessities. This change would save ratepayers roughly $615 million a year across the state. Last session, I supported an amendment offered by my House Democratic colleague that would have eliminated the sales tax on utility bills. The Republican majority defeated the amendment. I then offered an amendment to see if House Republicans would be willing to suspend the tax for one year at least to give Hoosier households an immediate 7% cut in their utility bills. It was also defeated by the Republicans. Giving regulators oversight authority over utility ownership changes : The IURC should have the power to approve utility mergers and acquisitions to protect ratepayers. This change would allow the IURC to determine if mergers like the pending $33 billion buyout of the AES Corporation, Indianapolis’ electric utility, by BlackRock-led investors is in the public interest. For years, House Democrats have offered legislation to give the IURC this power. Requiring utilities to join a regional transmission organization (RTO): A federal regulation gives utilities an incentive to voluntarily join an RTO, which allows them to buy and sell electricity across multiple states to meet electricity demand. A state law making membership mandatory would remove .05% of the extra profit the federal regulation gives utilities. I had already requested legislation be drafted to do this before the IURC recommended it. I welcome the IURC’s renewed focus on affordability, but regulatory investigations can only go so far. At the end of the day, for real change to happen, the Indiana General Assembly will need to change its anti-consumer policies. The legislature needs to legislate in favor of ratepayers, not utility companies. Gov. Braun Ends Indiana’s Diversity Business Enterprise Program This month, Governor Braun and Attorney General Todd Rokita announced they would not enforce an Indiana law that helps women and minority businesses earn state contracts, also known as the Diversity Business Enterprise (DBE) program. They declared it unconstitutional. More troubling than Gov. Braun’s hostility to a program designed to help businesses that have been at a disadvantage in the state bidding process is his belief that he can pick and choose which laws will be enforced rather than asking the General Assembly to repeal the law or seeking a formal court decision that the law is unconstitutional. The DBE goals have been in place since 1983 to level the playing field for minority-owned and women-owned businesses competing for state contracts. The DBE was created because Indiana’s previous policies failed to give marginalized communities equal opportunities. Governor Braun left in place incentives for veteran-owned businesses. An advisory opinion doesn’t repeal a law. That’s not how our government works. If the law needs to change, that’s the responsibility of the General Assembly, not an executive announcement or order. If the law is unconstitutional, it is the judicial branch’s job to declare it so. This is another attempt to destroy the checks and balances intended to be in our government by the State Constitution and concentrate power in one person. It moves us one step closer to an authoritarian government. Indiana Hits $4 Billion in Reserves While Costs Rise June 30th was the end of the state fiscal year. The Indiana General Assembly received the 2026 fiscal year closeout report a few weeks later, which indicates how Indiana is doing with its state budget. Indiana ended the fiscal year $586.5 million above its predicted end-of-year balance, reaching a total of $3.99 billion in reserves. This amount is above the recommended surplus of around 10% to fill an unexpected budget gap during a potential economic downturn. Keeping a prudent surplus for a rainy day is important, but at a time when the legislature has cut health care, child care, and underfunded public schools, the large reserves could be helping Hoosiers right now. Public schools received a funding increase far below inflation, resulting in significant financial strain. Dollars for local public health programs that provided free vaccines, reduced the infant mortality rate and provided care for chronic conditions were cut in half. Our public colleges and universities received a 5% budget cut. The $4 billion in reserves came at the expense of Hoosiers who are struggling the most. The next budget that will be adopted during the upcoming legislative session must put this money to work addressing the challenges facing Hoosier families. You can read more about Indiana’s fiscal closeout at this link . Cuts to SNAP, Medicaid could impact free school meals at high-poverty schools Indiana not to participate in SUN Bucks in 2027 Mothers tell governor they’d be unemployed, homeless without childcare vouchers Indiana expects to receive $1B for rural health. Hospitals say it’s only a ‘Band-Aid’ Lawmakers call on Braun to investigate deaths, backlogs at Indiana ICE prison Sincerely, Matt Pierce Share Top Latest No posts Ready for more? Subscribe © 2026 Rep. Matt Pierce · Privacy ∙ Terms ∙ Collection notice Start your Substack Get the app Substack is the home for great culture This site requires JavaScript to run correctly. Please turn on JavaScript or unblock scripts