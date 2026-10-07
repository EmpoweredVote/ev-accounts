You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-pierce-education/labels/coder-1.json. Write JSON only, matching
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

### topic_key: education-curriculum
topic_id: 6c43fdec-d084-415d-a15d-d78f48d4fb34  served_revision_id: 2146e080-bd5e-4e1e-8a51-fcc1b44af916
Question: How should schools handle contested topics like race, gender, and history in what they teach?
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


### topic_key: education-charter-authorization
topic_id: c8807d3d-4264-47ce-b8c4-08c6c9c33ce3  served_revision_id: 3901e1b0-12b0-4f7e-9e14-061ae2247c26
Question: How should the board handle charter schools that want to open in the district?
  1. Stop authorizing new charter schools and move to close existing ones
  2. Approve new charters rarely, only when a school is clearly failing students
  3. Judge each charter application on its own merits
  4. Welcome charters and approve strong applications to expand family options
  5. Convert failing district schools into charters run by independent operators

#### Annex

# education-charter-authorization — served revision 3901e1b0-12b0-4f7e-9e14-061ae2247c26 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should the board handle charter schools that want to open in the district?"

**Orientation:** standard. Rung 1 stops new charters and closes existing ones; rung 5 converts
district schools into charters. The rungs order **how readily charters are authorized**: none,
rarely, case by case, readily, by conversion.

**Levels with a lever:** local, school, state. The question is about the
board as authorizer. A school board holds the lever only where state law lets districts authorize;
state legislators set who may authorize, caps and conversion rules; a city holds a lever only where
the mayor or council is an authorizer _(proposed)_.

**Asked at:** state, local, school (`compass_topic_roles`, CA_0302).

**Synonyms:** "charter authorizer", "charter application", "charter petition", "charter renewal",
"charter cap", "moratorium", "state charter commission", "conversion charter", "restart",
"turnaround", "charter management organization" (CMO), "education management organization" (EMO),
"innovation school", "parent trigger".

1. **"Stop authorizing new charter schools and move to close existing ones"**
   - Means: no new charters, and the existing ones are wound down.
   - Operative clauses: [a] no new charters; [b] action to close existing charters. Compound: one
     side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a moratorium **plus** a non-renewal or closure plan for
     existing charters; own words that state both.
   - Levels that hold a lever: school (where it authorizes); state.
   - Known chair-shaped instruments: _(none on file)_.
   - Closing or not renewing **one** charter for its own performance is not [b] → `adjacent`
     _(proposed)_.

2. **"Approve new charters rarely, only when a school is clearly failing students"**
   - Means: new charters are the exception, approved only where students are clearly being failed.
   - Operative clauses: [a] approval is rare; [b] approval only where a school is clearly failing
     students.
   - Establishing evidence looks like: a policy or statute that limits new charters to areas or
     schools with documented failure.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - "A school is clearly failing" means the **district school the students would leave**, not the
     applicant _(ruled 2026-10-01)_.
   - Commonly confused with rung 1 because a moratorium with a failing-school exception blocks most
     charters. It allows some → rung 2 territory, not rung 1 _(proposed)_.

3. **"Judge each charter application on its own merits"**
   - Means: no presumption for or against charters; each application is judged on its quality.
   - Operative clauses: [a] case-by-case review; [b] no general presumption either way.
   - Establishing evidence looks like: own words that state merit review with no presumption; a
     policy of published quality criteria with no cap, moratorium or preference.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A vote on one application shows the person's act on that application, not a rule →
     `direction-only`. Approving some and denying others does not establish [b]: it rules out the
     ends, which is not evidence (V4.2 "Ruling out the other rungs").

4. **"Welcome charters and approve strong applications to expand family options"**
   - Means: the board favours charters and approves the strong ones to give families more choice.
   - Operative clauses: [a] a welcoming posture with the aim of more family options; [b] strong
     applications approved.
   - Establishing evidence looks like: own words that state both; a policy that sets expansion of
     charter options as a goal.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because both favour charters. Lifting a cap or adding an
     authorizer does not say whether district schools should be converted → `direction-only`
     _(proposed)_.

5. **"Convert failing district schools into charters run by independent operators"**
   - Means: failing district schools are handed to independent charter operators.
   - Operative clauses: [a] conversion of failing district schools; [b] run by independent
     operators.
   - Establishing evidence looks like: a board vote to convert a named failing school to an
     independent operator; a statute that requires conversion as the consequence of failure.
   - Levels that hold a lever: school; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A turnaround law that lists conversion as **one option** among several → `direction-only`
     _(proposed)_.

**Hard cases:**
- **Who authorizes.** A state law that moves authorization from districts to a state commission (or
  back) decides which body decides, and no rung is about that → `adjacent` (V2, H12).
- **Charter funding formulas and facilities access** → `adjacent` _(proposed)_.
- **Vouchers and ESAs** → `adjacent` (they have their own topic).
- **Charter accountability rules** (audits, renewal standards) → `adjacent` _(proposed)_.
- **Budget or omnibus votes** → V4 `multi-subject`.


### topic_key: education-school-budget
topic_id: 49f0b171-2ddf-4e68-887f-0ba78a2562f1  served_revision_id: 0c82eb1c-4bb8-4c0e-9fc1-3646925a8bfc
Question: How should schools set spending levels and decide whether to raise more revenue?
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
snapshot_id: 2b87eea5-e3e9-5d75-91ff-e1a83e629eaf
source_kind: public-record
url: https://iga.in.gov/legislative/2023/bills/house/1608/details

IGA | House Bill 1608 (2023) Indiana General Assembly 2023 Session. House Bill 1608 Education matters. Enrolled House Bill (H) Authored by: Rep. Michelle Davis. Co-Authored by: Rep. Jake Teshka, Rep. Chris Jeter, Rep. Robert Heaton. Sponsored by: Sen. Stacey Donato, Sen. Jeff Raatz, Sen. Gary Byrne. Digest Provides that a school, an employee or staff member of a school, or a third party vendor used by a school to provide instruction may not provide any instruction to a student in prekindergarten through grade 3 on human sexuality. Provides that a school employee or a school staff member is not prohibited from responding to a question from a student regarding certain topics. Requires a school to notify in writing at least one parent of a student, if the student is an unemancipated minor, of a request made by the student to change the student's name or pronoun, title, ... View more [Bill details page for HB 1608 (2023), saved by browser from iga.in.gov on 2026-09-27.]

---
snapshot_id: 9b63482e-23ef-5fbd-b484-b9f965876198
source_kind: public-record
url: https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1447/HB1447.04.ENRS.pdf

First Regular Session of the 123rd General Assembly (2023) PRINTING CODE. Amendments: Whenever an existing statute (or a section of the Indiana Constitution) is being amended, the text of the existing provision will appear in this style type, additions will appear in this style type , and deletions will appear in [deleted: this style type.] Additions: Whenever a new statutory provision is being enacted (or a new constitutional provision adopted), the text of the new provision will appear in this style type . Also, the word NEW will appear in that style type in the introductory clause of each SECTION that adds a new provision to the Indiana Code or the Indiana Constitution. Conflict reconciliation: Text in a statute in this style type or [deleted: this style type] reconciles conflicts between statutes enacted by the 2022 Regular Session of the General Assembly. HOUSE ENROLLED ACT No. 1447 AN ACT to amend the Indiana Code concerning education. Be it enacted by the General Assembly of the State of Indiana: SECTION 1. IC 20-23-18-3, AS AMENDED BY P.L.125-2022, SECTION 1, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2023]: Sec. 3. (a) Except as provided in subsection (c), the Muncie Community school corporation is subject to all applicable federal and state laws. (b) If a provision of this chapter conflicts with any other law, including IC 20-23-4, the provision in this chapter controls. (c) Notwithstanding subsection (a), to provide all administrative and academic flexibility to implement innovative strategies, the Muncie Community school corporation is subject only to the following IC 20 and IC 22 provisions: (1) IC 20-26-5-10 (criminal history). (2) IC 20-26-21 (personal analyses, evaluations, or surveys by third party vendors). [deleted: (2)] (3) IC 20-28-5-8 (conviction of certain felonies or misdemeanors; notice and hearing; permanent revocation of license; data base of school employees who have been reported). [deleted: (3)] (4) IC 20-28-10-17 (school counselor immunity). [deleted: (4)] (5) IC 20-29 (collective bargaining) to the extent required by HEA 1447 — CC 1 2 subsection (e). [deleted: (5)] (6) IC 20-30-3-2 and IC 20-30-3-4 (patriotic commemorative observances). [deleted: (6)] (7) The following: (A) IC 20-30-5-0.5 (display of the United States flag; Pledge of Allegiance). (B) IC 20-30-5-1, IC 20-30-5-2, and IC 20-30-5-3 (the constitutions of Indiana and the United States; writings, documents, and records of American history or heritage). (C) IC 20-30-5-4 (system of government; American history). (D) IC 20-30-5-5 (morals instruction). (E) IC 20-30-5-6 (good citizenship instruction). [deleted: (7)] (8) IC 20-32-4, concerning graduation requirements. [deleted: (8)] (9) IC 20-32-5.1, concerning the Indiana's Learning Evaluation Assessment Readiness Network (ILEARN) program. [deleted: (9)] (10) IC 20-32-8.5 (IRead3). [deleted: (10)] (11) IC 20-33-2 (compulsory school attendance). [deleted: (11)] (12) IC 20-33-8-16 (firearms, [deleted: and] deadly weapons, or destructive devices). [deleted: (12)] (13) IC 20-33-8-19, IC 20-33-8-21, and IC 20-33-8-22 (student due process and judicial review). [deleted: (13)] (14) IC 20-33-7 (parental access to education records). [deleted: (14)] (15) IC 20-33-9 (reporting of student violations of law). [deleted: (15)] (16) IC 20-34-3 (health and safety measures). [deleted: (16)] (17) IC 20-35 (concerning special education). [deleted: (17)] (18) IC 20-39 (accounting and financial reporting procedures). [deleted: (18)] (19) IC 20-40 (government funds and accounts). [deleted: (19)] (20) IC 20-41 (extracurricular funds and accounts). [deleted: (20)] (21) IC 20-42 (fiduciary funds and accounts). [deleted: (21)] (22) IC 20-42.5 (allocation of expenditures to student instruction and learning). [deleted: (22)] (23) IC 20-43 (state tuition support). [deleted: (23)] (24) IC 20-44 (property tax levies). [deleted: (24)] (25) IC 20-46 (levies other than general fund levies). [deleted: (25)] (26) IC 20-47 (related entities; holding companies; lease agreements). [deleted: (26)] (27) IC 20-48 (borrowing and bonds). [deleted: (27)] (28) IC 20-49 (state management of common school funds; state advances and loans). [deleted: (28)] (29) IC 20-50 (concerning homeless children and foster care children). HEA 1447 — CC 1 3 [deleted: (29)] (30) IC 22-2-18, before its expiration on June 30, 2021 (limitation on employment of minors). (d) The Muncie Community school corporation is subject to required audits by the state board of accounts under IC 5-11-1-9. (e) Except to the extent required under a collective bargaining agreement entered into before July 1, 2018, the Muncie Community school corporation is not subject to IC 20-29 unless the school corporation voluntarily recognizes an exclusive representative under IC 20-29-5-2. If the school corporation voluntarily recognizes an exclusive representative under IC 20-29-5-2, the school corporation may authorize a school within the corporation to opt out of bargaining allowable subjects or discussing discussion items by specifying the excluded items on the notice required under IC 20-29-5-2(b). The notice must be provided to the education employment relations board at the time the notice is posted. SECTION 2. IC 20-26-5.5 IS ADDED TO THE INDIANA CODE AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE JANUARY 1, 2024]: Chapter 5.5. School Library Sec. 1. (a) The governing body of a school corporation or charter school shall establish a: (1) procedure for each school to prepare a catalogue of materials available in the school library; (2) procedure for each school to allow a: (A) parent or guardian of a student enrolled in the school; or (B) community member: (i) within the school district; or (ii) within the school district in which the charter school is located; to submit a request to remove material from the school library that is obscene (as described in IC 35-49-2-1) or harmful to minors (as described in IC 35-49-2-2); and (3) response and appeal procedure for each school to respond to a removal request submitted by a parent, guardian, or community member described in subdivision (2). (b) The response and appeal procedure established under subsection (a)(3) must require the governing body to review the request at the next public meeting. Sec. 2. The governing body of a school corporation or charter school shall: (1) publish on the website of each school; and HEA 1447 — CC 1 4 (2) make available in hard copy for an individual upon request; the catalogue of material available in the school library and each policy established under this chapter. Sec. 3. A school corporation or charter school may not make available materials that contain: (1) obscene matter (as described in IC 35-49-2-1); or (2) matter harmful to minors (as described in IC 35-49-2-2); within the school library. SECTION 3. IC 20-26-21 IS ADDED TO THE INDIANA CODE AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2023]: Chapter 21. Personal Analyses, Evaluations, or Surveys by Third Party Vendors Sec. 1. As used in this chapter, "qualified school" means the following: (1) A school maintained by a school corporation. (2) A charter school. (3) A laboratory school established under IC 20-24.5-2. (4) The Indiana School for the Blind and Visually Impaired established by IC 20-21-2-1. (5) The Indiana School for the Deaf established by IC 20-22-2-1. Sec. 2. This chapter does not apply to the following: (1) An academic test or academic assessment, scoring keys, or other tools directly related to measuring a student's academic performance in understanding a particular curricular subject matter, as prescribed by the department. (2) A career aptitude or career interest survey. (3) An assessment or screening instrument administered by a third party employed: (A) psychologist licensed under IC 25-33; or (B) social worker, clinical social worker, marriage and family therapist, or mental health counselor licensed under IC 25-23.6; if the third party provider described in clause (A) or (B) is referred by school personnel in a crisis situation in which the school personnel and the third party provider reasonably believe that the student is in immediate danger of self harm, harming another person, or experiencing harm resulting from abuse or neglect. (4) An assessment, screening instrument, or evaluation survey HEA 1447 — CC 1 5 administered by a third party employed: (A) psychologist licensed under IC 25-33; or (B) social worker, clinical social worker, marriage and family therapist, or mental health counselor licensed under IC 25-23.6; who has received a consent for services from a student, if the student is an adult or emancipated minor, or parent of a student, if the student is an unemancipated minor. (5) A survey or evaluation administered to a student of a school by a third party vendor that gauges or attempts to gauge student satisfaction with or participation in the school's programming, technology platform, or approved curriculum. Sec. 3. If a school corporation or qualified school uses a third party vendor in providing a personal analysis, evaluation, or survey that reveals, identifies, collects, maintains, or attempts to affect a student's attitudes, habits, traits, opinions, beliefs, or feelings, the third party vendor and the school corporation or qualified school may not record, collect, or maintain the responses to or results of the analysis, evaluation, or survey in a manner that would identify the responses or results of an individual student. Sec. 4. (a) This section does not apply to a personal analysis, evaluation, or survey for which consent is required under IC 20-30-5-17(b). (b) Before a school corporation or qualified school may administer a personal analysis, evaluation, or survey described in section 3 of this chapter, the school corporation or qualified school must provide the parent of the student or the student, if the student is an adult or an emancipated minor, with a written request for consent for administration. A consent form provided to a parent of a student or a student under this subsection must accurately summarize the contents and nature of the personal analysis, evaluation, or survey that will be provided to the student and indicate that a parent of a student or an adult or emancipated minor student has the right to review and inspect all materials related to the personal analysis, evaluation, or survey. The written consent form may be sent in an electronic format. The parent of the student or the student, if the student is an adult or an emancipated minor, may return the consent form indicating that the parent of the student or the adult or emancipated student: (1) consents to the personal analysis, evaluation, or survey; or (2) declines the personal analysis, evaluation, or survey. If a student does not participate in the personal analysis, HEA 1447 — CC 1 6 evaluation, or survey, the school corporation or qualified school shall provide the student with alternative academic instruction during the same time frame that the personal analysis, evaluation, or survey is administered. (c) If the parent of the student or the student, if the student is an adult or an emancipated minor, does not respond to the written request provided by the school corporation or qualified school under subsection (b) within twenty-one (21) calendar days after receiving the request under subsection (b), the school corporation or qualified school shall provide the parent of the student or the student, if the student is an adult or an emancipated minor, a written notice requesting that the parent of the student, or the student, if the student is an adult or an emancipated minor, indicate, in a manner prescribed by the school corporation or qualified school, whether the parent of the student or the adult or emancipated student: (1) consents to the personal analysis, evaluation, or survey; or (2) declines the personal analysis, evaluation, or survey. A notice provided to a parent of a student or a student under this subsection must accurately summarize the contents and nature of the personal analysis, evaluation, or survey that will be provided to the student and indicate that a parent of a student or an adult or emancipated minor student has the right to review and inspect all materials related to the personal analysis, evaluation, or survey. The notice may be sent in an electronic format. If the school corporation or qualified school does not receive a response within ten (10) days after the notice, the student will receive the personal analysis, evaluation, or survey unless the parent or the adult or emancipated student subsequently opts out of the personal analysis, evaluation, or survey for the student. (d) Each school corporation or qualified school shall: (1) post a copy of a personal analysis, evaluation, or survey described in subsection (b) on the school corporation's or qualified school's website; and (2) send with each notice an explanation of the reasons that the school corporation or qualified school is administering the personal analysis, evaluation, or survey. (e) The department and the governing body shall give parents and students notice of the parents' and students' rights under this section. Sec. 5. A parent of a student or a student, if the student is an adult or emancipated minor, who is enrolled in a qualified school HEA 1447 — CC 1 7 may submit a complaint for a violation of this chapter under the grievance procedure maintained by the qualified school in accordance with section 6 of this chapter. Sec. 6. Each qualified school shall establish and maintain a grievance procedure for the resolution of a complaint submitted by a parent of a student or student, if the student is an adult or emancipated minor, under section 5 of this chapter. Sec. 7. The department shall: (1) develop guidance materials for school corporations and qualified schools to assist school corporations and qualified schools in implementing this chapter; and (2) post the guidance materials on the department's website. Sec. 8. Nothing in this section prohibits qualified schools from administering state or federally required assessments. Sec. 9. After June 30, 2023, if a school corporation or a qualified school contracts with a third party vendor to provide a personal analysis, survey, or evaluation described in section 3 of this chapter, the contract must include a provision stating that if the third party vendor does not comply with the requirements described in section 3 of this chapter, the third party vendor has committed a breach of contract. SECTION 4. IC 20-33-1.5 IS ADDED TO THE INDIANA CODE AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2023]: Chapter 1.5. Neutrality Regarding Certain Activities Sec. 1. As used in this chapter, "qualified school" has the meaning set forth in IC 20-26-21-1. Sec. 2. As used in this chapter, "state agency" has the meaning set forth in IC 4-13-1.4-2. Sec. 3. If a state agency, school corporation, or qualified school or an employee of a state agency, school corporation, or qualified school requires, makes part of a course, awards a grade or course credit, including extra credit, or otherwise incentivizes a student to engage in: (1) political activism; (2) lobbying; or (3) efforts to persuade members of the legislative or executive branch at the federal, state, or local level; the state agency, school corporation, or qualified school or the employee of the state agency, school corporation, or qualified school shall not require the student to adopt, affirm, affiliate, or take any action that would result in favoring any particular HEA 1447 — CC 1 8 position on the issue or issues involved without offering an alternative option for the student to complete the assignment or receive extra credit or other incentivization that allows for the favoring of an alternative position. SECTION 5. IC 35-49-3-3, AS AMENDED BY P.L.158-2013, SECTION 648, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JANUARY 1, 2024]: Sec. 3. (a) Except as provided in subsection (b) and section 4 of this chapter, a person who knowingly or intentionally: (1) disseminates matter to minors that is harmful to minors (as described in IC 35-49-2); (2) displays matter that is harmful to minors in an area to which minors have visual, auditory, or physical access, unless each minor is accompanied by the minor's parent or guardian; (3) sells, rents, or displays for sale or rent to any person matter that is harmful to minors within five hundred (500) feet of the nearest property line of a school or church; (4) engages in or conducts a performance before minors that is harmful to minors; (5) engages in or conducts a performance that is harmful to minors in an area to which minors have visual, auditory, or physical access, unless each minor is accompanied by the minor's parent or guardian; (6) misrepresents the minor's age for the purpose of obtaining admission to an area from which minors are restricted because of the display of matter or a performance that is harmful to minors; or (7) misrepresents that the person is a parent or guardian of a minor for the purpose of obtaining admission of the minor to an area where minors are being restricted because of display of matter or performance that is harmful to minors; commits a Level 6 felony. (b) This section does not apply if a person disseminates, displays, or makes available the matter described in subsection (a) through the Internet, computer electronic transfer, or a computer network unless: (1) the matter is obscene under IC 35-49-2-1; (2) the matter is child pornography under IC 35-42-4-4; or (3) the person distributes the matter to a child less than eighteen (18) years of age believing or intending that the recipient is a child less than eighteen (18) years of age. SECTION 6. IC 35-49-3-4, AS AMENDED BY P.L.266-2019, SECTION 16, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE HEA 1447 — CC 1 9 JANUARY 1, 2024]: Sec. 4. (a) It is a defense to a prosecution under section 3 of this chapter for the defendant to show: (1) that the matter was disseminated or that the performance was performed for legitimate scientific [deleted: or educational] purposes; (2) that the matter was disseminated or displayed to or that the performance was performed before the recipient by a bona fide [deleted: school,] college, university, museum, college library, or public library that qualifies for certain property tax exemptions under IC 6-1.1-10, or university library, or by an employee of such a school, college, university, museum, college library, or public library, or university library acting within the scope of the employee's employment; (3) that the defendant had reasonable cause to believe that the minor involved was eighteen (18) years of age or older and that the minor exhibited to the defendant a draft card, driver's license, birth certificate, or other official or apparently official document purporting to establish that the minor was eighteen (18) years of age or older; or (4) that the defendant was a salesclerk, motion picture projectionist, usher, or ticket taker, acting within the scope of the defendant's employment and that the defendant had no financial interest in the place where the defendant was so employed. (b) Except as provided in subsection (c), it is a defense to a prosecution under section 3 of this chapter if all the following apply: (1) A cellular telephone, another wireless or cellular communications device, or a social networking web site was used to disseminate matter to a minor that is harmful to minors. (2) The defendant is not more than four (4) years older or younger than the person who received the matter that is harmful to minors. (3) The relationship between the defendant and the person who received the matter that is harmful to minors was a dating relationship or an ongoing personal relationship. For purposes of this subdivision, the term "ongoing personal relationship" does not include a family relationship. (4) The crime was committed by a person less than twenty-two (22) years of age. (5) The person receiving the matter expressly or implicitly acquiesced in the defendant's conduct. (c) The defense to a prosecution described in subsection (b) does not apply if: (1) the image is disseminated to a person other than the person: (A) who sent the image; or HEA 1447 — CC 1 10 (B) who is depicted in the image; or (2) the dissemination of the image violates: (A) a protective order to prevent domestic or family violence or harassment issued under IC 34-26-5 (or, if the order involved a family or household member, under IC 34-26-2 or IC 34-4-5.1-5 before their repeal); (B) an ex parte protective order issued under IC 34-26-5 (or, if the order involved a family or household member, an emergency order issued under IC 34-26-2 or IC 34-4-5.1 before their repeal); (C) a workplace violence restraining order issued under IC 34-26-6; (D) a no contact order in a dispositional decree issued under IC 31-34-20-1, IC 31-37-19-1, or IC 31-37-5-6 (or IC 31-6-4-15.4 or IC 31-6-4-15.9 before their repeal) or an order issued under IC 31-32-13 (or IC 31-6-7-14 before its repeal) that orders the person to refrain from direct or indirect contact with a child in need of services or a delinquent child; (E) a no contact order issued as a condition of pretrial release, including release on bail or personal recognizance, or pretrial diversion, and including a no contact order issued under IC 35-33-8-3.6; (F) a no contact order issued as a condition of probation; (G) a protective order to prevent domestic or family violence issued under IC 31-15-5 (or IC 31-16-5 or IC 31-1-11.5-8.2 before their repeal); (H) a protective order to prevent domestic or family violence issued under IC 31-14-16-1 in a paternity action; (I) a no contact order issued under IC 31-34-25 in a child in need of services proceeding or under IC 31-37-25 in a juvenile delinquency proceeding; (J) an order issued in another state that is substantially similar to an order described in clauses (A) through (I); (K) an order that is substantially similar to an order described in clauses (A) through (I) and is issued by an Indian: (i) tribe; (ii) band; (iii) pueblo; (iv) nation; or (v) organized group or community, including an Alaska Native village or regional or village corporation as defined in or established under the Alaska Native Claims Settlement HEA 1447 — CC 1 11 Act (43 U.S.C. 1601 et seq.); that is recognized as eligible for the special programs and services provided by the United States to Indians because of their special status as Indians; (L) an order issued under IC 35-33-8-3.2; or (M) an order issued under IC 35-38-1-30. HEA 1447 — CC 1 Speaker of the House of Representatives President of the Senate President Pro Tempore Governor of the State of Indiana Date: Time: HEA 1447 — CC 1 [extracted by pdf-snapshot.ts with strike detection, 2026-09-27T07:50:05.539Z, https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1447/HB1447.04.ENRS.pdf, from saved file]

---
snapshot_id: f65d7bd5-af08-5541-a8eb-790f48c5bc62
source_kind: own-site (the person's own site or account)
url: https://repmattpierce.substack.com/p/rep-matt-pierces-may-newsletter

Rep. Matt Pierce's May Newsletter Rep. Matt Pierce's Newsletter Subscribe Sign in Rep. Matt Pierce's May Newsletter The weakening of the Voting Rights Act, a study of property tax assessments and more. Rep. Matt Pierce May 26, 2026 Share Welcome to my monthly newsletter, where I provide legislative updates as your state representative for House District 61. Please reach out to me at h61@iga.in.gov if you have any comments, questions, or concerns. Support the Bloomington Community Farmers Market The Bloomington Farmers Market is open for the season. Every Saturday from now until September, the market will be open from 8:00 a.m. to 12:30 p.m. at Showers Commons (401 N Morton St.). The market will also be open on Saturdays in October from 9:00 a.m. to 12:30 p.m. Local vendors will sell baked goods, crafts and fresh produce from our area. Each week, there are several pop-up performances by buskers and musicians. No pets are allowed at the market. The Bloomington Community Farmers Market accepts SNAP benefits. You can learn more about the market at this link . State Legislature Will Study Property Tax Assessments I am hearing from homeowners concerned about rising assessed values of their homes leading to higher property taxes. Homeowners wonder if the assessments reflect the true market value of their homes. Because the state constitution caps homeowner’s property taxes at 1% of a home’s assessed value, when assessments rise, property tax caps also rise. That’s why I’m glad the General Assembly will study property tax assessments this summer and fall. The legislature has struggled with limiting property tax increases while at the same time ensuring local units of government have the revenue necessary to provide the services residents expect. Public libraries, police and fire departments and our schools all rely on property taxes. In 2025, Republicans said they would provide “historic relief” with Senate Enrolled Act 1 (SEA 1), but fell short. The Bloomington Herald-Times reported SEA 1 only provided modest savings for Monroe County homeowners. The median savings on tax bills was about $159. Three-quarters of residential property owners experienced a decrease of less than $300. Twenty percent of property owners saw their taxes increase. Meanwhile, SEA 1 is making it difficult for schools and local governments to balance their budgets. Indiana’s public schools are projected to lose $744.4 million over the next three years. A survey of school administrators is evidence of the impact: 99.3% of school districts expect SEA 1 to harm their funding. Districts are already passing referendums or postponing bus purchases, scaling back technological upgrades or pausing building repairs. The legislature’s study of the assessment system is important to ensure homes are valued fairly. However, the General Assembly must also continue analyzing the entire property tax system and the impacts of SEA 1. This is particularly important for people on fixed incomes who face higher property taxes because the value of their homes have skyrocketed in value. Rep. Pierce debating legisaltion on the House floor. Other Interim Study Committee Topics Other topics that committees will study before the next legislative session in January include: Potential changes in policies or statutes to improve child safety. Name, Image, and Likeness (NIL) rights for student-athletes at the high school level The feasibility of an increase in workers’ compensation benefits and the decreasing rate of workers’ compensation claims. Sources of funding for child care expansion. Indiana’s sexual assault response workforce, availability of services to survivors, and sexual assault response plans. Mobile digital driving credentials (licenses). Current and future challenges and opportunities in the agricultural industry and potential changes to the Indiana State Department of Agriculture. Committee agendas, minutes, and exhibits will be available at https://iga.in.gov/2026/committees/interim . Committee meetings are streamed live and archived for later viewing at https://iga.in.gov/ . The Weakening of the Voting Rights Act Last month, the U.S. Supreme Court issued one of the most devastating blows to voting rights in a generation. In a 6-3 decision along ideological lines, the Court’s conservative majority struck down Louisiana’s congressional map in Louisiana v. Callais . This map was drawn under a court order to give Black voters, who make up roughly a third of Louisiana’s population, meaningful representation. The Republican-backed lawsuit argued Louisiana’s new map violated the 14th Amendment by considering race. The Supreme Court agreed, weakening Section 2 of the Voting Rights Act of 1965 (VRA). For communities of color across America, and for everyone who believes the essence of democracy is elected officials who understand the interests of their constituents, this ruling is an alarm bell we cannot ignore. The VRA is the living legacy of the Civil Rights Movement, signed in the aftermath of Dr. Martin Luther King Jr.’s march from Selma to Montgomery. The VRA was intended to ensure that minorities would not be marginalized in elections. The consequences of this ruling are already unfolding. In the weeks following the Callais decision, several Southern states have started to redraw their maps. Tennessee Republicans quickly drew and passed a new map that eliminated the state’s sole majority-minority House district. The green light has been given, and Republicans are racing to carve up majority-minority districts for partisan gain before a single vote is cast. This decision also hits close to home. Indiana recently had its own months-long battle over redistricting. The Trump administration tried to pressure the Republican supermajority into drawing two more Republican congressional seats. The voting power of Indiana’s most diverse regions, Gary and Indianapolis, would have been diluted. Thankfully, Hoosiers loudly rejected the supermajority’s map. Indiana took a stand for the principle that voters should choose their representatives, not the other way around. A democracy where some voices are heard and others are silenced isn’t a democracy. Each community deserves representation that reflects its interests, regardless of party or ethnicity. Rigging maps corrodes the belief that America depends on: the belief that our system is fair and that participation leads to change. I will continue to fight for fair maps, for full and equal representation, and for the principle that every Hoosier’s vote carries equal weight. Indiana high school athletes may now profit off their name, image and likeness Public school group expects record number of school referendums The redistricting frenzy is scrambling the midterm elections. Here’s where things stand now. Indiana unveils Medicaid overhaul aimed at pressuring hospitals to lower prices Indiana lawmakers to study childcare funding options Sincerely, Matt Pierce Share Top Latest No posts Ready for more? Subscribe © 2026 Rep. Matt Pierce · Privacy ∙ Terms ∙ Collection notice Start your Substack Get the app Substack is the home for great culture This site requires JavaScript to run correctly. Please turn on JavaScript or unblock scripts

---
snapshot_id: ad53d5ab-01ba-5c47-9670-c5e343a0738e
source_kind: public-record
url: https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1608/rollcalls/HB1608.220_H.pdf

Indiana House of Representatives F IRST R EGULAR S ESSION 123 RD G ENERAL A SSEMBLY F EB 23, 2023 2:14:18 PM Roll Call 220: Bill Passed HB 1608 - Davis M - 3rd Reading Yea 65 Human sexuality instruction Nay 29 Excused 5 Not Voting 1 Presiding: Speaker Y EA - 65 Aylesworth Haggard Mayfield Slager Baird Hall McGuire Smaltz Barrett Heaton McNamara Snow Bartels Heine Meltzer Soliday Behning Hostettler Miller, D Speedy Borders Jeter Morrison Steuerwald Carbaugh Jordan Morris Sweet Cash Judy Negele Teshka Criswell Karickhoff O'Brien Thompson Culp Lauer Olthoff Torr Davis Ledbetter Patterson VanNatter DeVon Lehman Payne Vermilion Engleman Lindauer Pierce, K Wesco Frye Lucas Prescott Zent Genda Lyness Pressel Goodrich Manning Rowray Greene May Schaibley N AY - 29 Andrade Fleming Johnson Porter Bauer, M Garcia Wilburn Klinker Pryor Boy GiaQuinta Miller, K Shackleford Campbell Gore Moed Smith, V Clere Hamilton Moseley Summers DeLaney Harris Pack Dvorak Hatfield Pfaff Errington Jackson Pierce, M E XCUSED - 5 Abbott Cherry Hatcher King Bartlett N OT V OTING - 1 Mr. Speaker [extracted by pdf-snapshot.ts with strike detection, 2026-10-07T17:02:51.673Z, https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1608/rollcalls/HB1608.220_H.pdf, from saved file]

---
snapshot_id: 31369651-dad5-57e2-833c-f3a7662fbe45
source_kind: public-record
url: https://iga.in.gov/legislative/2023/bills/house/1447/details

IGA | House Bill 1447 (2023) Indiana General Assembly 2023 Session. House Bill 1447 Education matters. Enrolled House Bill (H) Authored by: Rep. Donna Schaibley. Co-Authored by: Rep. Julie McGuire, Rep. Becky Cash. Sponsored by: Sen. Stacey Donato, Sen. Jeff Raatz. Digest Provides that, if a school corporation or qualified school uses a third party vendor in providing certain personal analyses, evaluations, or surveys, the third party vendor and the school corporation or qualified school may not record, collect, or maintain the responses to or results of the analysis, evaluation, or survey in a manner that would identify the responses or results of an individual student. Provides that, if a school corporation or qualified school uses a third party vendor in providing the personal analysis, evaluation, or survey, the school corporation or qualified school must provide parents or students, as applicable, two ... View more [Bill details page for HB 1447 (2023), saved by browser from iga.in.gov on 2026-09-27.]

---
snapshot_id: 8953d7c0-8b43-579c-98da-794ae0f01608
source_kind: public-record
url: https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1608/rollcalls/HB1608.489_H.pdf

Indiana House of Representatives F IRST R EGULAR S ESSION 123 RD G ENERAL A SSEMBLY A PR 24, 2023 4:52:00 PM Roll Call 489: Motion Prevailed HB 1608 - Davis M Yea 63 Education matters Nay 29 Motion to Concur Excused 7 Not Voting 1 Presiding: Speaker Y EA - 63 Abbott Goodrich Lyness Pressel Aylesworth Greene Manning Schaibley Baird Haggard May Slager Barrett Hall Mayfield Smaltz Behning Heaton McGuire Snow Borders Hostettler McNamara Soliday Carbaugh Jeter Meltzer Speedy Cash Jordan Miller, D Steuerwald Cherry Judy Morrison Sweet Criswell Karickhoff Morris Thompson Culp King Negele Torr Davis Lauer O'Brien VanNatter DeVon Ledbetter Olthoff Vermilion Engleman Lehman Patterson Wesco Frye Lindauer Pierce, K Zent Genda Lucas Prescott N AY - 29 Andrade Fleming Johnson Porter Bauer, M GiaQuinta Klinker Pryor Boy Gore Miller, K Shackleford Campbell Hamilton Moed Smith, V Clere Harris Moseley Summers DeLaney Hatcher Pack Dvorak Hatfield Pfaff Errington Jackson Pierce, M E XCUSED - 7 Bartels Garcia Wilburn Payne Teshka Bartlett Heine Rowray N OT V OTING - 1 Mr. Speaker v. 1.1 [extracted by pdf-snapshot.ts with strike detection, 2026-10-07T17:02:52.634Z, https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1608/rollcalls/HB1608.489_H.pdf, from saved file]

---
snapshot_id: 502a0117-c635-5a60-a779-864c9afde4c8
source_kind: public-record
url: https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1447/rollcalls/HB1447.535_H.pdf

Indiana House of Representatives F IRST R EGULAR S ESSION 123 RD G ENERAL A SSEMBLY A PR 27, 2023 1:21:41 PM Roll Call 535: Conference Committee Report Adopted HB 1447 - Schaibley Yea 69 Education matters Nay 28 Conference Committee Report #1 Excused 1 Not Voting 2 Presiding: Speaker Y EA - 69 Abbott Goodrich Lyness Rowray Aylesworth Gore Manning Schaibley Baird Greene May Slager Barrett Haggard Mayfield Smaltz Bartels Hall McGuire Snow Behning Heaton McNamara Soliday Borders Heine Meltzer Speedy Carbaugh Hostettler Miller, D Steuerwald Cash Jeter Moed Sweet Cherry Jordan Morrison Teshka Criswell Judy Morris Thompson Culp Karickhoff Negele Torr Davis King O'Brien VanNatter DeVon Lauer Olthoff Wesco Engleman Ledbetter Patterson Zent Fleming Lehman Pierce, K Frye Lindauer Prescott Genda Lucas Pressel N AY - 28 Andrade Dvorak Jackson Pierce, M Bartlett Errington Johnson Porter Bauer, M Garcia Wilburn Klinker Pryor Boy GiaQuinta Miller, K Shackleford Campbell Hamilton Moseley Smith, V Clere Harris Pack Summers DeLaney Hatcher Pfaff Vermilion E XCUSED - 1 Payne N OT V OTING - 2 Hatfield Mr. Speaker v. 1.1 [extracted by pdf-snapshot.ts with strike detection, 2026-10-07T17:02:54.578Z, https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1447/rollcalls/HB1447.535_H.pdf, from saved file]

---
snapshot_id: 0776b409-4af5-5603-b773-6447a8a2209c
source_kind: own-site (the person's own site or account)
url: https://repmattpierce.substack.com/p/rep-matt-pierces-december-newsletter

Rep. Matt Pierce's December Newsletter Rep. Matt Pierce's Newsletter Subscribe Sign in Rep. Matt Pierce's December Newsletter Take my legislative survey, a troubling requirement for new college degrees, and more. Rep. Matt Pierce Dec 22, 2025 Share Welcome to my monthly newsletter, where I provide legislative updates as your state representative for House District 61. Please reach out to me at h61@iga.in.gov if you have any comments, questions, or concerns. Congratulations to Fernando Mendoza and the IU Football Team Congratulations to IU’s quarterback, Fernando Mendoza, for winning the Heisman Memorial Trophy. His performance this season is a major part of the team’s success. The IU football team continues to reach new heights with an undefeated season and Big Ten Championship. It has been fun watching the team’s success under Coach Curt Cignetti. Good luck to IU as they play in the Rose Bowl on New Year’s Day. I will be cheering them on as they march to a National Championship! Take My 2026 Legislative Survey Make your voice heard! Hearing your views is essential to representing you at the Statehouse, and my legislative survey is an important way for me to understand your opinions on specific issues. There are three ways you can complete my survey: If you’re a registered voter in my district, you should receive a postcard in the mail with a QR code. Scanning the QR code with your smartphone will take you to my survey. Visit my website at IN.gov/H61 and click the survey button at the top. You can also call my office at (317) 232-9656 from 8 a.m. to 4:30 p.m. Monday through Friday. Please do not complete my survey if you do not reside in House District 61. To find your state legislator, you can visit https://iga.in.gov/information/find-legislators . Please know that a question on my survey does not indicate my support for or opposition to an issue. I hope you’ll be a part of helping me learn what you think by completing my survey. You can contact me at h61@iga.in.gov if you have any questions, thoughts or concerns. State Requires Universities to Promote “American Values” New degree programs at Indiana colleges and universities must be approved by the Indiana Commission for Higher Education (CHE). The application mostly focuses on the programs’ logistics — potential enrollment, costs, curriculum and career outcomes. But the CHE added a new question to the application: “How does the proposed program cultivate civic responsibility and commitment to the core values of American society? For example, how does the curriculum include components that emphasize civic engagement and the duties of citizenship in a free society?” Now, our public colleges and universities must prove that new degrees promote core American values. I am concerned this new requirement will be used to impose political viewpoints on university classrooms in the name of “American values.” Even more troubling, this is a continuation of the legislature and Braun administration’s conversion of the CHE from a coordinating body to a regulatory agency. The Commission is now an appellate review board for complaints about the “intellectual diversity” of faculty members and can eliminate degree programs based on criteria created by the legislature. The CHE was not created to micromanage university operations. It was intended to coordinate degree offerings among universities to avoid unnecessary duplication of programs. The door is now open for the CHE to politically interfere with academic decisions and erode the independence of our universities. I will continue opposing legislation that undermines shared faculty governance, erodes diversity on campus, and enables arbitrary top-down decisions. You can read more about this topic here . Holiday Support and Essential Resources As we celebrate the holidays, people in need of support can contact Indiana 211 for help. Whether families are seeking holiday meals, toy assistance, winter shelter, or support with basic needs, Indiana 211 is available to connect residents with local, trustworthy resources across all 92 counties. Hoosiers can contact 2-1-1 or search online at in211.org for statewide assistance programs including: Holiday Meals & Food Programs Christmas meal sites Emergency food pantries Holiday food box programs Community meals with extended winter hours Winter Shelter & Warmth Resources Warming centers and overnight emergency shelters Severe Weather Contingency shelters Utility assistance agencies for heating support Holiday Giving Programs Toy distribution Holiday clothing drives Mental Health & Crisis Support Immediate emotional support Connections to local counseling, warm lines and crisis teams Referrals for grief support resources If you or someone you know is currently experiencing thoughts of suicide, or a mental health or substance use crisis, please call 988 to reach the Suicide & Crisis Lifeline and speak with a trained crisis specialist 24/7. ‘We cannot survive’ | Indiana school leaders fear looming budget crisis after property tax reform ‘Protecting Hoosiers’ | New bill aims to protect Indiana’s water from data center development Hoosiers on ACA health plans feel the pain of spiking premiums ‘It’s a disaster.’ How cuts undermine high-quality child care in Indiana Education bill tracker: What did lawmakers file by the 2026 legislative session’s first week? Indiana elected officials turn their attention to lowering utility bills in 2026 Sincerely, Matt Pierce Share Top Latest No posts Ready for more? Subscribe © 2026 Rep. Matt Pierce · Privacy ∙ Terms ∙ Collection notice Start your Substack Get the app Substack is the home for great culture This site requires JavaScript to run correctly. Please turn on JavaScript or unblock scripts

---
snapshot_id: 30f74405-4bca-53d2-80ca-512b13a4b443
source_kind: public-record
url: https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1608/HB1608.05.ENRS.pdf

First Regular Session of the 123rd General Assembly (2023) PRINTING CODE. Amendments: Whenever an existing statute (or a section of the Indiana Constitution) is being amended, the text of the existing provision will appear in this style type, additions will appear in this style type , and deletions will appear in [deleted: this style type.] Additions: Whenever a new statutory provision is being enacted (or a new constitutional provision adopted), the text of the new provision will appear in this style type . Also, the word NEW will appear in that style type in the introductory clause of each SECTION that adds a new provision to the Indiana Code or the Indiana Constitution. Conflict reconciliation: Text in a statute in this style type or [deleted: this style type] reconciles conflicts between statutes enacted by the 2022 Regular Session of the General Assembly. HOUSE ENROLLED ACT No. 1608 AN ACT to amend the Indiana Code concerning education. Be it enacted by the General Assembly of the State of Indiana: SECTION 1. IC 20-28-10-17, AS ADDED BY P.L.1-2005, SECTION 12, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2023]: Sec. 17. (a) Except as provided in IC 20-33-7.5 and IC 31-32-11-1, a school counselor is immune from disclosing privileged or confidential communication made to the counselor as a counselor by a student. (b) Except as provided in IC 20-33-7.5 and IC 31-32-11-1, the matters communicated are privileged and protected against disclosure. SECTION 2. IC 20-28-12-5, AS ADDED BY P.L.1-2005, SECTION 12, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2023]: Sec. 5. A school psychologist who is endorsed under this chapter may not disclose any information acquired from persons with whom the school psychologist has dealt in a professional capacity, except under the following circumstances: (1) Trials for homicide when the disclosure relates directly to the fact or immediate circumstances of the homicide. (2) Proceedings: (A) to determine mental competency; or (B) in which a defense of mental incompetency is raised. (3) Civil or criminal actions against a school psychologist for malpractice. (4) Upon an issue as to the validity of a document. HEA 1608 — Concur 2 (5) If the school psychologist has the express consent of the client or, in the case of a client's death or disability, the express consent of the client's legal representative. (6) Circumstances under which privileged communication is lawfully invalidated. (7) Disclosures required by IC 20-33-7.5. SECTION 3. IC 20-30-17 IS ADDED TO THE INDIANA CODE AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2023]: Chapter 17. Prohibited Instruction Sec. 1. As used in this chapter, "school" means any of the following: (1) A public school, including a charter school. (2) A laboratory school established under IC 20-24.5-2. (3) The Indiana School for the Blind and Visually Impaired established by IC 20-21-2-1. (4) The Indiana School for the Deaf established by IC 20-22-2-1. Sec. 2. A school, an employee or staff member of a school, or a third party vendor used by a school to provide instruction may not provide any instruction to a student in prekindergarten through grade 3 on human sexuality. Sec. 3. Nothing in this chapter may be construed to prohibit a teacher from providing instruction on academic standards developed by the department under IC 20-31-3-2 or instruction required under IC 20-30-5-5.7. Sec. 4. Nothing in this chapter may be construed to prevent a school employee or a school staff member from responding to a question from a student regarding the topic described in section 2 of this chapter. SECTION 4. IC 20-33-7.5 IS ADDED TO THE INDIANA CODE AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2023]: Chapter 7.5. Parental Notification Regarding Identification Sec. 1. As used in this chapter, "school" has the meaning set forth in IC 20-30-17-1. Sec. 2. (a) A school shall notify in writing at least one (1) parent of a student, if the student is an unemancipated minor, of a request made by the student to change the student's: (1) name; or (2) pronoun, title, or word to identify the student. (b) Not later than five (5) business days after the date on which HEA 1608 — Concur 3 a school receives a request described in subsection (a), the school shall provide notification to a parent as required by subsection (a). Sec. 3. This chapter does not: (1) change an individual's duty to report child abuse or neglect, as required under IC 31-33-5; or (2) permit a school to establish a policy described in IC 20-26-5-35.5. Sec. 4. Nothing in this chapter may be construed to require a school psychologist, a school nurse, a school social worker, or a school counselor to violate a federal law or regulation. HEA 1608 — Concur Speaker of the House of Representatives President of the Senate President Pro Tempore Governor of the State of Indiana Date: Time: HEA 1608 — Concur [extracted by pdf-snapshot.ts with strike detection, 2026-09-27T07:50:07.169Z, https://iga.in.gov/pdf-documents/123/2023/house/bills/HB1608/HB1608.05.ENRS.pdf, from saved file]