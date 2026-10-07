You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-pierce-redistricting/labels/coder-3.json. Write JSON only, matching
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

politician_id: 72dd5219-490f-48bb-986e-183a6098d602  office_id: 7b3f68ef-bd9b-4316-9e39-89091b6e9aa1
Matt Pierce — Representative, Indiana (seated, level: state)
Current term: 2002-01-01 (precision: year) to present

## Topics (served ladder text — code against these words only)

### topic_key: redistricting
topic_id: 48cc9585-ec22-4f53-8d42-6839828dd36f  served_revision_id: c7f973fc-33f5-4570-bfe2-bff4ac6141cc
Question: Who should draw electoral district boundaries and how should they be determined?
  1. independent citizens' commissions with no elected officials involved at any level.
  2. independent redistricting commissions with equal representation from both major parties.
  3. bipartisan legislative committees with strict rules requiring supermajority approval.
  4. state legislatures with court oversight to prevent extreme partisan bias.
  5. the party that controls the state legislature without outside interference.

#### Annex

# redistricting — served revision c7f973fc-33f5-4570-bfe2-bff4ac6141cc (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "Who should draw electoral district boundaries and how should they be determined?"

**Orientation:** standard. Rung 1 puts the map-drawer furthest from elected officials, rung 5 gives
the maps to the legislative majority with no check. The rungs order **how insulated the map-drawer is
from the people elected under the maps**. Each rung names an institution and the constraint that
separates it from its neighbour.

**Levels with a lever:** federal, state. The lever is state: constitutions and
statutes say who draws the maps. The federal lever is national redistricting-standards legislation;
for rungs 2 and 3 a federal official's evidence is usually own words (review 2026-08-31, scope kept).

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "independent redistricting commission" (IRC), "citizens redistricting commission",
"advisory commission", "backup commission", "apportionment", "gerrymandering", "partisan fairness",
"communities of interest", "Fair Districts", "mid-decade redistricting", "Elections Clause",
"independent state legislature", "supermajority".

1. **"independent citizens' commissions with no elected officials involved at any level."**
   - Means: ordinary citizens draw the maps, and elected officials take no part at any step.
   - Operative clauses: [a] an independent citizens' commission draws the maps; [b] no elected official
     is involved at any step (choosing members, drawing, approving).
   - Establishing evidence looks like: a measure that creates such a commission and gives elected
     officials no role; own words for it. [b] is an absence clause and must be stated (V4.2).
   - Levels that hold a lever: state; federal (national standards that require such commissions).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because many citizens' commissions also seat equal numbers from the
     two largest parties. A citizens' commission with equal party seats, where legislative leaders take
     part in choosing members, is rung 2: elected officials are involved, so rung 1's absence clause
     fails _(ruled 2026-10-01)_.

2. **"independent redistricting commissions with equal representation from both major parties."**
   - Means: a commission outside the legislature draws the maps, with equal seats for the two largest
     parties.
   - Operative clauses: [a] an independent commission draws the maps; [b] equal representation of the
     two major parties.
   - Establishing evidence looks like: a measure that creates a commission with equal party seats.
   - Levels that hold a lever: state; federal (own words, mostly).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - An **advisory** commission whose maps the legislature may change or reject is not independent →
     not rung 1 or 2; `direction-only` _(proposed)_.

3. **"bipartisan legislative committees with strict rules requiring supermajority approval."**
   - Means: legislators draw the maps in a committee of both parties, and the maps need a supermajority.
   - Operative clauses: [a] a bipartisan legislative committee; [b] supermajority approval.
   - Establishing evidence looks like: a rule or constitutional text that gives the maps to a
     bipartisan legislative committee **and** requires a supermajority. Compound: one side only →
     `compound-partial` (V4.2).
   - Levels that hold a lever: state; federal (own words, mostly).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because both keep the maps in the legislature. Rung 3's check is
     internal (bipartisanship and a supermajority); rung 4's is a court.

4. **"state legislatures with court oversight to prevent extreme partisan bias."**
   - Means: the legislature draws the maps, and courts can strike maps with extreme partisan bias.
   - Operative clauses: [a] the legislature draws; [b] courts can review for partisan bias.
   - Establishing evidence looks like: a measure that leaves the maps with the legislature and sets
     partisan-fairness standards that courts enforce; own words for that arrangement _(proposed)_.
   - Levels that hold a lever: state; federal (national standards enforceable in court).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a **lawsuit asking a court to strike a map** for partisan
     bias shows [b] but not [a]: the plaintiff may want a commission → `direction-only` _(proposed)_.

5. **"the party that controls the state legislature without outside interference."**
   - Means: the legislative majority draws the maps, and no commission or court may change them.
   - Operative clauses: [a] the legislative majority draws; [b] no outside check (no commission, no
     court review).
   - Establishing evidence looks like: a filed lawsuit claiming the Elections Clause gives map-drawing
     "exclusively to state legislatures" is a `record` whose claim is the position (codebook H7,
     Owens / redistricting). Quote the claim as `provision_quote`. If the claim attacks a commission
     but accepts court review, it does not exclude rung 4 → `direction-only` _(proposed)_.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **A change of map-drawer that is not permanent** fits no single rung → BLANK `direction-only`. The measure's own findings or declarations are part of the same
  record, not a separate statement, so there is no `record-vs-statement-conflict`.
- **A vote for a particular map** is about the map's lines, not about who should draw → `adjacent`
  _(proposed)_.
- **Campaign work for a commission initiative** is not a vote. Code the person's own words; an old role
  sourced only to an encyclopedia → V3 `not-evidence`, and the row goes to review (codebook V5, Moore /
  redistricting).
- **Omnibus election bills** that include a commission mandate → V4 `multi-subject`.
- **Preemption.** This ladder is itself about which body decides, so a measure that moves map-drawing
  between bodies is `on-question` (codebook V2, Q10 exception).


## Sources

---
snapshot_id: a837cee9-158c-5243-bd19-e4e6692f4e7b
source_kind: own-site (the person's own site or account)
url: https://www.indianahousedemocrats.org/news/pierce-reacts-to-the-house-passage-of-republicans-gerrymandered-congressional-map

Pierce reacts to the House passage of Republicans gerrymandered congressional map &mdash; Indiana House Democratic Caucus 0 Skip to Content Members Members Leadership IHDC Staff Need Help? News Newsroom Press Inquiries IBLC Indiana Black Legislative Caucus History of the IBLC IBLC Events 2026 Agenda Student Opportunities Internships Page Program Policy Briefs The Big Beautiful Bill's Impact on Indiana Open Menu Close Menu Open Menu Close Menu Members Members Leadership IHDC Staff Need Help? News Newsroom Press Inquiries IBLC Indiana Black Legislative Caucus History of the IBLC IBLC Events 2026 Agenda Student Opportunities Internships Page Program Policy Briefs The Big Beautiful Bill's Impact on Indiana Folder: Members Back Members Leadership IHDC Staff Need Help? Folder: News Back Newsroom Press Inquiries Folder: IBLC Back Indiana Black Legislative Caucus History of the IBLC IBLC Events 2026 Agenda Folder: Student Opportunities Back Internships Page Program Folder: Policy Briefs Back The Big Beautiful Bill's Impact on Indiana Pierce reacts to the House passage of Republicans gerrymandered congressional map Rep. Matt Pierce Dec 5 Written By Anna Groover Today, Dec. 5, Indiana House Republicans passed House Bill 1032 , their gerrymandered congressional map, after months of pressure from Washington, D.C. The map carves up like-minded communities to give Republicans control of every congressional district in Indiana. HB 1032 now must be approved by the Senate to become law. State Rep. Matt Pierce (D-Bloomington) released the following statement: “This is a sad day. It’s a sad day for the House, and it’s a sad day for democracy. We have a president who wants to cheat in the midterms to preserve his party's control of the U.S. House of Representatives. We have a governor who agrees and is pressuring members of his own party. We have an Indiana House that is rolling over and giving in. “This is a failure of our President, a failure of our Governor, and a failure of the House majority. There aren't enough Republicans standing up and saying, ‘This isn’t right, this is not our values.’ All because Washington demands they rig congressional elections in the Republicans' favor. “I cannot state too strongly that this is not normal. What has the Republican Party become? It’s hard to imagine Lincoln, Roosevelt, Eisenhower, or Reagan demanding an unfair advantage or Governors Bowen, Orr, or Daniels eagerly going along with the scheme. This erasure of Democratic members of Congress and the voices of their constituents will delegitimize Congress. People are already frustrated with the state and federal governments' failure to address the real problems they face. Today's action will make them feel more cynical about their government and undermine their confidence in our democracy. “This is the saddest day I have ever experienced in the Indiana House of Representatives.” Anna Groover Previous Previous IBLC comments on Martin University pausing its operations Next Next Klinker comments on House passage of Republicans’ new congressional map Indiana House Democratic Caucus 200 W. Washington St., Indianapolis, IN 46204 Toll-free: 1-800-382-9842 Site Map Members Members Leadership IHDC Staff Need Help? News Newsroom Press Inquiries IBLC Indiana Black Legislative Caucus History of the IBLC IBLC Events 2026 Agenda Student Opportunities Internships Page Program Policy Briefs The Big Beautiful Bill's Impact on Indiana

---
snapshot_id: 0b82d0fc-79d9-56ac-a5b8-f3319d2e29eb
source_kind: public-record
url: https://iga.in.gov/pdf-documents/124/2026/house/bills/HB1032/rollcalls/HB1032.28_H.pdf

Indiana House of Representatives S ECOND R EGULAR S ESSION 124 TH G ENERAL A SSEMBLY D EC 05, 2025 1:26:06 PM Roll Call 28: Bill Passed HB 1032 - Smaltz - 3rd Reading Yea 57 Nay 41 Excused 2 Not Voting 0 Presiding: Speaker Y EA - 57 Abbott Greene Manning Slager Aylesworth Haggard May Smaltz Baird Heaton McGuire Smith, H Barrett Heine McNamara Snow Bascom Hostettler Miller, D Soliday Behning Ireland Morris Sweet Borders Isa O'Brien Teshka Carbaugh Jordan Olthoff Thompson Commons Judy Patterson VanNatter Criswell King Payne Wesco Culp Lauer Pierce, K Zimmerman Davis Lawson Prescott Mr. Speaker DeVon Ledbetter Pressel Engleman Lindauer Rowray Goss-Reaves Lucas Shonkwiler N AY - 41 Andrade Errington Karickhoff Pfaff Bartels Garcia Wilburn Klinker Pierce, M Bartlett Genda Lehman Porter Bauer GiaQuinta Lopez Shackleford Burton Gore Mayfield Smith, V Campbell Hall Meltzer Steuerwald Cash Hamilton Miller, K Summers Clere Harris Moed Yocum Dant Chesser Hatcher Moseley DeLaney Jackson, C Novak Dvorak Johnson, B Pack E XCUSED - 2 Jeter Pryor N OT V OTING - 0 Redistricting [Roll call 28 (House, 3rd reading) for HB 1032 (2026), downloaded by browser from iga.in.gov on 2026-10-01; text extracted with pdf.js.]

---
snapshot_id: 850e9e86-3efa-5bd3-a1ef-3ce3ee5b11ba
source_kind: public-record
url: https://iga.in.gov/pdf-documents/124/2026/house/bills/HB1032/HB1032.02.COMH.pdf

*HB1032.1* December 2, 2025 HOUSE BILL No. 1032 _____ DIGEST OF HB 1032 (Updated December 2, 2025 3:36 pm - DI 144) Citations Affected: IC 3-3; IC 3-11; noncode. Synopsis: Redistricting. Allows the general assembly to amend congressional districts at a time other than the first regular session of the general assembly convening immediately following the United States decennial census. Specifies requirements that apply to any action challenging the apportionment of congressional districts or general assembly districts. Establishes new Indiana congressional districts. Provides for expiration of the current congressional districts on the date of the 2026 general election. Specifies that for purposes of the 2026 primary and general election, a precinct may cross the boundary of a congressional district. Requires the election division to assist each county voter registration office with the implementation of this act. Makes technical and necessary changes in related statutes. Effective: Upon passage. Smaltz December 1, 2025, read first time and referred to Committee on Elections and Apportionment. December 2, 2025, reported — Do Pass. HB 1032—LS 6390/DI 144 December 2, 2025 Second Regular Session of the 124th General Assembly (2026) PRINTING CODE. Amendments: Whenever an existing statute (or a section of the Indiana Constitution) is being amended, the text of the existing provision will appear in this style type, additions will appear in this style type , and deletions will appear in [deleted: this style type.] Additions: Whenever a new statutory provision is being enacted (or a new constitutional provision adopted), the text of the new provision will appear in this style type . Also, the word NEW will appear in that style type in the introductory clause of each SECTION that adds a new provision to the Indiana Code or the Indiana Constitution. Conflict reconciliation: Text in a statute in this style type or [deleted: this style type] reconciles conflicts between statutes enacted by the 2025 Regular Session of the General Assembly. HOUSE BILL No. 1032 A BILL FOR AN ACT to amend the Indiana Code concerning elections. Be it enacted by the General Assembly of the State of Indiana: 1 SECTION 1. IC 3-3-2-1 IS AMENDED TO READ AS FOLLOWS 2 [EFFECTIVE UPON PASSAGE]: Sec. 1. (a) Except as provided in 3 subsection (b), congressional districts shall be established by law at 4 the first regular session of the general assembly convening immediately 5 following the United States decennial census. 6 (b) The general assembly may amend the congressional districts 7 established under subsection (a) at a time other than the first 8 regular session of the general assembly convening immediately 9 following the United States decennial census. 10 SECTION 2. IC 3-3-2-2, AS AMENDED BY P.L.133-2021, 11 SECTION 9, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE 12 UPON PASSAGE]: Sec. 2. [deleted: (a) This subsection applies only to the first] 13 [deleted: regular session of the one hundred twenty-second general assembly. If] 14 [deleted: the general assembly adjourns sine die before November 15, 2021,] 15 [deleted: without having complied with the requirements of section 1 of this] 16 [deleted: chapter, a redistricting commission is established. The redistricting] 17 [deleted: commission consists of the speaker of the house, the president pro tem] HB 1032—LS 6390/DI 144 2 1 [deleted: of the senate, the chairpersons of the senate and house committees] 2 [deleted: responsible for legislative apportionment, and a fifth member] 3 [deleted: appointed by the governor from the membership of the general] 4 [deleted: assembly.] 5 [deleted: (b)] (a) [deleted: This subsection applies to a session of the general assembly] 6 [deleted: beginning after November 15, 2021.] If a session of the general 7 assembly adjourns without having complied with the requirements of 8 section [deleted: 1] 1(a) of this chapter or if for any other reason at any time the 9 state finds itself without a valid congressional district law, a 10 redistricting commission shall be established which shall consist of the 11 speaker of the house, the president pro tem of the senate, the chairman 12 of the senate and house committees responsible for legislative 13 apportionment and a fifth member who shall be appointed by the 14 governor from the membership of the general assembly. 15 [deleted: (c)] (b) The redistricting commission shall meet within thirty (30) 16 days after adjournment of the general assembly at a time and place 17 designated by the president pro tem of the senate and shall adopt a 18 congressional redistricting plan in accordance with this chapter. 19 [deleted: (d)] (c) Any plan so adopted shall be signed by a majority of the 20 redistricting committee and submitted to the governor who forthwith 21 shall issue and publish the governor's executive order establishing 22 congressional districts in accordance with the plan so adopted and 23 directing the commission to place such congressional districts in effect 24 for the primary and general elections next succeeding such general 25 assembly. Congressional districts so established shall continue in effect 26 until changed by statute. 27 SECTION 3. IC 3-3-2-3 IS ADDED TO THE INDIANA CODE AS 28 A NEW SECTION TO READ AS FOLLOWS [EFFECTIVE UPON 29 PASSAGE]: Sec. 3. (a) This section applies to any action 30 challenging the apportionment of congressional districts or general 31 assembly districts. 32 (b) The general assembly makes the following findings with 33 respect to actions to which this section applies: 34 (1) The state has a compelling interest in preserving the 35 integrity of its elections and ensuring elections are fair, 36 orderly, and free from chaos and confusion. 37 (2) Actions challenging the apportionment of congressional or 38 general assembly districts can have statewide impacts on the 39 electoral process and disrupt the orderly conduct of elections. 40 (3) Judicial alterations to election laws can interfere with the 41 orderly administration of an election, cause unanticipated 42 consequences, and undermine voter confidence in the electoral HB 1032—LS 6390/DI 144 3 1 process. 2 (4) A prompt, orderly determination of apportionment issues 3 by a court of last resort is critical for preserving election 4 integrity, protecting voter confidence, and preventing chaotic 5 disruption of the electoral process. 6 (c) The following apply in any action to which this section 7 applies: 8 (1) A temporary restraining order may not be sought or 9 issued. 10 (2) The supreme court has mandatory and exclusive 11 jurisdiction over any appeal from an order granting, 12 extending, modifying, or refusing to dissolve an injunction. 13 However, this subdivision does not apply to an appeal from an 14 order refusing to grant or dissolving an injunction. 15 (3) The supreme court has mandatory and exclusive 16 jurisdiction over any appeal from a final judgment or any 17 other appealable order holding the apportionment 18 unconstitutional or otherwise invalid, either in whole or in 19 part. 20 (4) If an appeal is taken from an order, injunction, or 21 judgment concerning the apportionment of congressional 22 districts or general assembly districts, the order, injunction, 23 or judgment is automatically stayed by operation of law 24 pending disposition of the appeal by the supreme court. Any 25 party may seek relief from the stay in the supreme court, and 26 relief from the stay may be sought only in the supreme court. 27 (5) Any action or appeal of an action to which this section 28 applies must be given priority over ordinary matters. 29 SECTION 4. IC 3-3-4-2, AS AMENDED BY P.L.221-2021, 30 SECTION 19, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE 31 UPON PASSAGE]: Sec. 2. As used in this chapter, "district" refers to 32 a district described in: 33 [deleted: (1) IC 3-3-5, before November 8, 2022; and] 34 [deleted: (2)] (1) IC 3-3-6, [deleted: after November 7, 2022.] before November 3, 35 2026; and 36 (2) IC 3-3-7, after November 2, 2026. 37 SECTION 5. IC 3-3-4-5, AS AMENDED BY P.L.221-2021, 38 SECTION 21, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE 39 UPON PASSAGE]: Sec. 5. (a) Any part of Indiana that has not been 40 described as included in a district is included within the district that: 41 (1) is contiguous to the part; and 42 (2) contains the least population of districts contiguous to that HB 1032—LS 6390/DI 144 4 1 part according to the 2020 decennial census of Indiana. 2 (b) If any part of Indiana is described as being in more than one (1) 3 district, the part is included within the district that: 4 (1) is one (1) of the districts in which the part is listed in: 5 [deleted: (A) IC 3-3-5, before November 8, 2022; and] 6 [deleted: (B)] (A) IC 3-3-6, [deleted: after November 7, 2022;] before November 7 3, 2026; and 8 (B) IC 3-3-7, after November 2, 2026; 9 whichever is applicable; 10 (2) is contiguous to the part; and 11 (3) contains the least population according to the 2020 decennial 12 census of Indiana. 13 (c) If any part of Indiana: 14 (1) is described in: 15 [deleted: (A) IC 3-3-5, before November 8, 2022; and] 16 [deleted: (B)] (A) IC 3-3-6, [deleted: after November 7, 2022;] before November 17 3, 2026; and 18 (B) IC 3-3-7, after November 2, 2026; 19 as being in one (1) district; and 20 (2) is entirely surrounded by another district; 21 the part shall be incorporated into the district that surrounds the part. 22 (d) If any part of Indiana: 23 (1) is described as being in one (1) district; and 24 (2) is not contiguous to another part of the district that contains 25 the majority of the population in the district; 26 the part is included with the contiguous district that contains the least 27 population according to the 2020 decennial census of Indiana. 28 SECTION 6. IC 3-3-6-10 IS ADDED TO THE INDIANA CODE 29 AS A NEW SECTION TO READ AS FOLLOWS [EFFECTIVE 30 UPON PASSAGE]: Sec. 10. This chapter expires November 3, 2026. 31 SECTION 7. IC 3-3-7 IS ADDED TO THE INDIANA CODE AS 32 A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE UPON 33 PASSAGE]: 34 Chapter 7. Congressional Districts; 2026 Plan 35 Sec. 1. The First Congressional District consists of the following: 36 COUNTIES: 37 Cass County, Fulton County, Lake County, Marshall County, 38 Miami County, Pulaski County, Starke County, Wabash 39 County 40 LaPorte County TOWNSHIPS: 41 Cass Township, Dewey Township, Hanna Township, Prairie 42 Township HB 1032—LS 6390/DI 144 5 1 Porter County TOWNSHIPS: 2 Boone Township, Morgan Township, Pleasant Township, 3 Porter Township, Union Township 4 Porter County PRECINCTS: 5 CENTER 18, CENTER 23, CENTER 24, CENTER 31, 6 CENTER 32 7 Porter County CENSUS BLOCKS: 8 181270506053001, 181270506053002, 181270506053003, 9 181270506053004, 181270506062000, 181270506062001, 10 181270506062002, 181270506062003, 181270506062004, 11 181270506062005, 181270506063000, 181270506063001, 12 181270506063002, 181270506063003, 181270506063004, 13 181270506063005, 181270506063006, 181270506063007, 14 181270506063008, 181270506063009, 181270506063010, 15 181270506063011, 181270506063012, 181270506063013, 16 181270506063014, 181270506063015, 181270506063017, 17 181270506063020, 181270506063022, 181270506063023, 18 181270506063024, 181270506063025, 181270506063026, 19 181270506063027, 181270506063028, 181270506063029, 20 181270506063030, 181270506063031, 181270506063032, 21 181270506063033, 181270509011013, 181270509011014, 22 181270509011015, 181270509011016, 181270509011017, 23 181270509011018, 181270509011019, 181270509011020, 24 181270509011021, 181270509011022, 181270509011023, 25 181270509011024, 181270509011025, 181270509011026, 26 181270509011027, 181270509011032, 181270509011033, 27 181270509011034, 181270509011035, 181270509012010, 28 181270509012011, 181270509012012, 181270509012013, 29 181270509012014, 181270509012015, 181270509012016 30 Sec. 2. The Second Congressional District consists of the 31 following: 32 COUNTIES: 33 Kosciusko County, Noble County, St. Joseph County, Whitley 34 County 35 Elkhart County TOWNSHIPS: 36 Baugo Township, Benton Township, Cleveland Township, 37 Harrison Township, Jackson Township, Locke Township, 38 Olive Township, Osolo Township, Union Township 39 Elkhart County PRECINCTS: 40 WASHINGTON 02 41 Elkhart County CENSUS BLOCKS: 42 180390007011000, 180390007011001, 180390007011002, HB 1032—LS 6390/DI 144 6 1 180390007012000, 180390007012001, 180390007012002, 2 180390007012003, 180390007012004, 180390007012005, 3 180390007012006, 180390007012007, 180390007012008, 4 180390007012009, 180390007012010, 180390007012011, 5 180390007012015, 180390007012016, 180390007012017, 6 180390007012018, 180390007012019, 180390007012020, 7 180390007012021, 180390007012022, 180390007012023, 8 180390007012024, 180390007012025, 180390007012026, 9 180390007012027, 180390007012028, 180390007013000, 10 180390007013001, 180390007013002, 180390007013003, 11 180390007013004, 180390007013005, 180390007013006, 12 180390007013007, 180390007013008, 180390007013009, 13 180390007013010, 180390007013011, 180390007013012, 14 180390007013013, 180390007013014, 180390007013015, 15 180390007013016, 180390007013017, 180390007013018, 16 180390007022007, 180390007022024, 180390007022025, 17 180390007022026, 180390007022027, 180390007022028, 18 180390007022029, 180390007022030, 180390007022031, 19 180390007022032, 180390007022033, 180390007022034, 20 180390007022037, 180390007022038, 180390007022039, 21 180390007022040, 180390007022041, 180390007022042, 22 180390007022043, 180390007022044, 180390007022045, 23 180390007022046, 180390007022047, 180390007022054, 24 180390007022055, 180390007022059, 180390007023009, 25 180390007023010, 180390007023013, 180390007023014, 26 180390007023023 27 LaPorte County TOWNSHIPS: 28 Center Township, Clinton Township, Coolspring Township, 29 Galena Township, Hudson Township, Johnson Township, 30 Kankakee Township, Lincoln Township, Michigan Township, 31 New Durham Township, Noble Township, Pleasant Township, 32 Scipio Township, Springfield Township, Union Township, 33 Washington Township, Wills Township 34 Porter County TOWNSHIPS: 35 Jackson Township, Liberty Township, Pine Township, 36 Portage Township, Washington Township, Westchester 37 Township 38 Porter County PRECINCTS: 39 CENTER 01, CENTER 02, CENTER 03, CENTER 05, 40 CENTER 06, CENTER 07, CENTER 09, CENTER 11, 41 CENTER 13, CENTER 14, CENTER 15, CENTER 17, 42 CENTER 20, CENTER 21, CENTER 22, CENTER 25, HB 1032—LS 6390/DI 144 7 1 CENTER 26, CENTER 27, CENTER 28, CENTER 29, 2 CENTER 30, CENTER 33, CENTER 34, CENTER 35, LAKE 3 MICHIGAN NV 4 Porter County CENSUS BLOCKS: 5 181270506051008, 181270506051011, 181270506051012, 6 181270506051013, 181270506051020, 181270506051021, 7 181270506051022, 181270506051023, 181270506051024, 8 181270506051025, 181270506051026, 181270506051027, 9 181270506051045, 181270506051048, 181270506063018, 10 181270506063021, 181270507041037, 181270507041038, 11 181270507041039, 181270507041040, 181270507041041, 12 181270507041042, 181270507041043, 181270507041044, 13 181270507041045, 181270507041047, 181270507041048, 14 181270508011049, 181270509012017, 181270509012021 15 Sec. 3. The Third Congressional District consists of the 16 following: 17 COUNTIES: 18 Adams County, Allen County, DeKalb County, Jay County, 19 LaGrange County, Steuben County 20 Delaware County TOWNSHIPS: 21 Delaware Township, Liberty Township, Niles Township 22 Delaware County PRECINCTS: 23 PRECINCT 01, PRECINCT 02, PRECINCT 03, PRECINCT 24 04, PRECINCT 06, PRECINCT 07, PRECINCT 08, 25 PRECINCT 10, PRECINCT 11, PRECINCT 12, PRECINCT 26 13, PRECINCT 14, PRECINCT 15, PRECINCT 18, 27 PRECINCT 19, PRECINCT 20, PRECINCT 22, PRECINCT 28 23, PRECINCT 25, PRECINCT 26, PRECINCT 27, 29 PRECINCT 33, PRECINCT 34, PRECINCT 35, PRECINCT 30 36, PRECINCT 38, PRECINCT 39, PRECINCT 40, 31 PRECINCT 42, PRECINCT 43, PRECINCT 45, PRECINCT 32 46, PRECINCT 47, PRECINCT 48, PRECINCT 49, 33 PRECINCT 50 34 Delaware County CENSUS BLOCKS: 35 180350013001025, 180350013001027, 180350013001028, 36 180350013001029, 180350013001030, 180350013001031, 37 180350013001032, 180350013001034, 180350013002001, 38 180350013002002, 180350013002003, 180350013002004, 39 180350013002005, 180350013002006, 180350013002007, 40 180350013002011, 180350013002012, 180350013002013, 41 180350013002014, 180350013002015, 180350013002016, 42 180350013002017, 180350013003019, 180350013003020, HB 1032—LS 6390/DI 144 8 1 180350013003021, 180350013003022, 180350013003023, 2 180350013003024, 180350013003025, 180350013003026, 3 180350013003027, 180350013003028, 180350013003029, 4 180350014001000, 180350014001007, 180350015003008, 5 180350015003009, 180350015003010, 180350015004012, 6 180350015004013, 180350015004014, 180350015004015, 7 180350015004016, 180350015004017, 180350015004018, 8 180350015004019, 180350015004020, 180350015004021, 9 180350015004022, 180350015004023, 180350016001026, 10 180350016001027, 180350016001028, 180350016001029, 11 180350016001030, 180350016001031, 180350016001032, 12 180350021001000, 180350021001001, 180350021001002, 13 180350021001003, 180350021001004, 180350021001005, 14 180350021001006, 180350021001007, 180350021001008, 15 180350021001009 16 Elkhart County TOWNSHIPS: 17 Clinton Township, Concord Township, Elkhart Township, 18 Jefferson Township, Middlebury Township, York Township 19 Elkhart County CENSUS BLOCKS: 20 180390007021000, 180390007021001, 180390007021002, 21 180390007021003, 180390007021004, 180390007021005, 22 180390007021006, 180390007021007, 180390007021008, 23 180390007021009, 180390007021010, 180390007021011, 24 180390007021012, 180390007021013, 180390007021014, 25 180390007021015, 180390007021016, 180390007021017, 26 180390007021018, 180390007021019, 180390007021020, 27 180390007021021, 180390007021022, 180390007021023, 28 180390007021024, 180390007021025, 180390007021026, 29 180390007021027, 180390007021028, 180390007021029, 30 180390007021030, 180390007021031, 180390007021032, 31 180390007021033, 180390007021034, 180390007021035, 32 180390007022000, 180390007022001, 180390007022002, 33 180390007022003, 180390007022004, 180390007022005, 34 180390007022006, 180390007022008, 180390007022009, 35 180390007022010, 180390007022011, 180390007022012, 36 180390007022013, 180390007022014, 180390007022015, 37 180390007022016, 180390007022017, 180390007022018, 38 180390007022019, 180390007022020, 180390007022021, 39 180390007022022, 180390007022023, 180390007022048, 40 180390007022049, 180390007022050, 180390007022051, 41 180390007022052, 180390007022053, 180390007022056, 42 180390007022057, 180390007022058, 180390007023000, HB 1032—LS 6390/DI 144 9 1 180390007023001, 180390007023002, 180390007023003, 2 180390007023004, 180390007023005, 180390007023006, 3 180390007023007, 180390007023008, 180390007023015, 4 180390007023016, 180390007023017, 180390007023018, 5 180390007023019, 180390007023020, 180390007023021, 6 180390007023022, 180390007023024, 180390007023025, 7 180390007023026, 180390007023027, 180390007023028 8 Sec. 4. The Fourth Congressional District consists of the 9 following: 10 COUNTIES: 11 Benton County, Boone County, Clay County, Fountain 12 County, Hendricks County, Jasper County, Montgomery 13 County, Newton County, Owen County, Parke County, 14 Putnam County, Vermillion County, Warren County, White 15 County 16 Greene County TOWNSHIPS: 17 Fairplay Township, Grant Township, Highland Township, 18 Jefferson Township, Smith Township, Stafford Township, 19 Stockton Township, Washington Township, Wright Township 20 Greene County PRECINCTS: 21 RICHLAND 1, RICHLAND 2 22 Greene County CENSUS BLOCKS: 23 180559554004002, 180559554004003, 180559554004004, 24 180559554004005, 180559554004006, 180559554004007, 25 180559554004008, 180559554004009, 180559554004010, 26 180559554004011, 180559554004012, 180559554004013, 27 180559554004015, 180559554004016, 180559554004017, 28 180559554004018, 180559554004019, 180559554004020, 29 180559554004025, 180559554004026, 180559554004031, 30 180559554004032, 180559554004036, 180559554004039, 31 180559554004040 32 Marion County TOWNSHIPS: 33 Pike Township 34 Marion County PRECINCTS: 35 WS-01, WS-02, WS-03, WS-04, WS-05, WS-06, WS-07, 36 WS-08, WS-09, WS-10, WS-11, WS-12, WS-13, WS-14, 37 WS-15, WS-16, WS-17, WS-18, WS-19, WS-20, WS-21, 38 WS-22, WS-23, WS-24, WS-25, WS-26, WS-27, WS-28, 39 WS-29, WS-31, WS-32, WS-33, WS-34, WS-35, WS-36, 40 WS-37, WS-38, WS-40, WS-41, WS-43, WY-01, WY-11, 41 WY-12, WY-13, WY-22 42 Marion County CENSUS BLOCKS: HB 1032—LS 6390/DI 144 10 1 180973202021007, 180973202021008, 180973202021009, 2 180973202021013, 180973202021014, 180973202021015, 3 180973202021019, 180973202021020, 180973202021021, 4 180973202021022, 180973202021023, 180973202021024, 5 180973202021025, 180973202021026, 180973202021027, 6 180973202021028, 180973202021029, 180973205001010, 7 180973205002017, 180973206001014, 180973206001018, 8 180973206001019, 180973206001020, 180973206001021, 9 180973206001022, 180973206001023, 180973206001024, 10 180973206001025, 180973206001026, 180973206001027, 11 180973206002002, 180973206002003, 180973206002004, 12 180973206002005, 180973206002006, 180973206002007, 13 180973206002017, 180973206002018, 180973206002019, 14 180973206002041, 180973206002044, 180973206002045, 15 180973206002047, 180973207001005, 180973207001007, 16 180973207001025, 180973208002022, 180973209022003, 17 180973209022004, 180973209022005, 180973209022006, 18 180973209023000, 180973209023001, 180973209023002, 19 180973209023003, 180973209023004, 180973209023005, 20 180973401112008, 180973401112009, 180973401112011, 21 180973401112012, 180973401112013, 180973401121000, 22 180973401121001, 180973401121002, 180973401121003, 23 180973401121009, 180973401121010, 180973401121011, 24 180973401121012, 180973401124005, 180973401124012, 25 180973401131004, 180973401131006, 180973401131007, 26 180973401131008, 180973401131010, 180973401131012, 27 180973401131013, 180973401131014, 180973401133000, 28 180973401133001, 180973401133002, 180973401133003, 29 180973401133004, 180973401143013, 180973401152015, 30 180973401152016, 180973401152018 31 Tippecanoe County TOWNSHIPS: 32 Jackson Township, Lauramie Township, Randolph Township, 33 Sheffield Township, Shelby Township, Union Township, 34 Wayne Township, Wea Township 35 Tippecanoe County PRECINCTS: 36 WABASH 01, WABASH 02, WABASH 03, WABASH 04, 37 WABASH 05, WABASH 08, WABASH 09, WABASH 10, 38 WABASH 11, WABASH 12, WABASH 13, WABASH 18, 39 WABASH 19, WABASH 20, WABASH 31 40 Tippecanoe County CENSUS BLOCKS: 41 181570051012000, 181570051021008, 181570051021014, 42 181570051021015, 181570051022003, 181570051022004, HB 1032—LS 6390/DI 144 11 1 181570051022005, 181570051022010, 181570055001025, 2 181570102071042, 181570102071043, 181570102071053, 3 181570102071054, 181570105001008, 181570105001009, 4 181570105001010, 181570105001011, 181570106001006, 5 181570106001007, 181570106001008, 181570106001009, 6 181570106001010, 181570106001011, 181570106001012, 7 181570106001013, 181570106001014, 181570106001015, 8 181570106001016, 181570106001017, 181570106001018, 9 181570106001019, 181570106001020, 181570106001021, 10 181570106001022, 181570106001023, 181570106001024, 11 181570106001025, 181570106001026, 181570106001027, 12 181570106001028, 181570106001029, 181570106001030, 13 181570106001031, 181570106001032, 181570106001033, 14 181570106001034, 181570106001035, 181570106001036, 15 181570106001037, 181570106001038, 181570106001039, 16 181570106001040, 181570106001041, 181570106001042, 17 181570106001043, 181570106001044, 181570106001045, 18 181570106001046, 181570106001048, 181570106001049, 19 181570106001050, 181570106001051, 181570106001052, 20 181570106001053 21 Sec. 5. The Fifth Congressional District consists of the following: 22 COUNTIES: 23 Blackford County, Carroll County, Clinton County, Grant 24 County, Hamilton County, Howard County, Huntington 25 County, Tipton County, Wells County 26 Tippecanoe County TOWNSHIPS: 27 Fairfield Township, Perry Township, Tippecanoe Township, 28 Washington Township 29 Tippecanoe County PRECINCTS: 30 WABASH 06, WABASH 14, WABASH 17, WABASH 21, 31 WABASH 22, WABASH 23, WABASH 24, WABASH 25, 32 WABASH 26, WABASH 27 33 Tippecanoe County CENSUS BLOCKS: 34 181570051012013, 181570051012014, 181570051012018, 35 181570051021000, 181570051021016, 181570051021017, 36 181570051021018, 181570051022000, 181570051022001, 37 181570051022002, 181570051022006, 181570051022007, 38 181570051022008, 181570051022009, 181570051022011, 39 181570051022012, 181570051022013, 181570051022014, 40 181570051022015, 181570051022016, 181570051022017, 41 181570051022018, 181570051022019, 181570051022021, 42 181570051022026, 181570051022031, 181570051023004, HB 1032—LS 6390/DI 144 12 1 181570051023005, 181570052001008, 181570052001009, 2 181570052001010, 181570052002000, 181570052002001, 3 181570052002003, 181570052002004, 181570052003000, 4 181570052003001, 181570052003002, 181570052003003, 5 181570052003004, 181570052003005, 181570052003006, 6 181570054012003, 181570054012006, 181570054012023, 7 181570054012024, 181570054012025, 181570054022012, 8 181570054022013, 181570054022014, 181570054022017, 9 181570054022019, 181570055001000, 181570055001001, 10 181570055001002, 181570055001003, 181570055001004, 11 181570055001005, 181570055001006, 181570055001007, 12 181570055001008, 181570055001009, 181570055001010, 13 181570055001011, 181570055001012, 181570055001013, 14 181570055001014, 181570055001015, 181570055001016, 15 181570055001017, 181570055001018, 181570055001019, 16 181570055001020, 181570055001021, 181570055001022, 17 181570055001023, 181570055001024, 181570055002000, 18 181570055002001, 181570055002002, 181570055002003, 19 181570055003000, 181570055003001, 181570055003002, 20 181570055004000, 181570055004001, 181570055004002, 21 181570055004003, 181570055004004, 181570055004005, 22 181570102071058, 181570105001000, 181570105001001, 23 181570105001002, 181570105001003, 181570105001004, 24 181570105001005, 181570105001006, 181570105001007, 25 181570105002000, 181570106001000, 181570106001001, 26 181570106001002, 181570106001003, 181570106001004, 27 181570106001005, 181570106001047 28 Sec. 6. The Sixth Congressional District consists of the 29 following: 30 COUNTIES: 31 Bartholomew County, Decatur County, Fayette County, 32 Jennings County, Johnson County, Rush County, Shelby 33 County 34 Marion County TOWNSHIPS: 35 Franklin Township, Perry Township, Warren Township 36 Marion County PRECINCTS: 37 02-02, 02-03, 02-04, 09-01, 09-02, 09-03, 09-04, 09-05, 09-06, 38 09-07, 10-03, 10-04, 10-05, 13-01, 13-02, 13-03, 13-04, 13-05, 39 15-01, 15-02, 16-01, 16-02, 16-03, 16-04, 16-05, 17-01, 17-02, 40 17-03, 17-04, 17-05, 25-01, 25-02, 25-03, 25-04, 25-05, 30-01, 41 30-02, 30-03, 30-04, 30-05, 30-06, 30-07, WR-34, CO-01, 42 CO-02 HB 1032—LS 6390/DI 144 13 1 Marion County CENSUS BLOCKS: 2 180973521002019, 180973521002020, 180973521002025, 3 180973521002026, 180973521003017, 180973526002000, 4 180973526002001, 180973526002002, 180973526002003, 5 180973526002004, 180973526002005, 180973526002006, 6 180973527001000, 180973527001001, 180973527001002, 7 180973527001003, 180973527001004, 180973527001007, 8 180973527001008, 180973527001009, 180973527001010, 9 180973527001011, 180973527001016, 180973527001017, 10 180973527001018, 180973527001019, 180973527001024, 11 180973527001025, 180973527001026, 180973527001027, 12 180973527001046, 180973527003000, 180973527003001, 13 180973527003002, 180973527003013, 180973527003014, 14 180973527003015, 180973527003016, 180973527003019, 15 180973528001040, 180973528001041, 180973528001067, 16 180973528001068, 180973545001002, 180973545001003, 17 180973545001006, 180973545001007, 180973545001008, 18 180973545001009, 180973545002002, 180973545002003, 19 180973545002005, 180973545002006, 180973545003003, 20 180973545003004, 180973545003009, 180973545003010, 21 180973545003011, 180973545003012, 180973545003013, 22 180973545003014 23 Sec. 7. The Seventh Congressional District consists of the 24 following: 25 COUNTIES: 26 Dearborn County, Franklin County, Hancock County, Henry 27 County, Jefferson County, Madison County, Ohio County, 28 Randolph County, Ripley County, Switzerland County, Union 29 County, Wayne County 30 Delaware County TOWNSHIPS: 31 Hamilton Township, Harrison Township, Monroe Township, 32 Perry Township, Salem Township, Union Township, 33 Washington Township 34 Delaware County PRECINCTS: 35 PRECINCT 05, PRECINCT 29, PRECINCT 44, PRECINCT 36 53, PRECINCT 54, PRECINCT 55, PRECINCT 71, 37 PRECINCT 74, PRECINCT 81, PRECINCT 87, PRECINCT 38 88, PRECINCT 95, PRECINCT 98 39 Delaware County CENSUS BLOCKS: 40 180350013002000, 180350013002008, 180350013002009, 41 180350013002010, 180350013002018, 180350015004024, 42 180350015004025, 180350015004026, 180350015004027, HB 1032—LS 6390/DI 144 14 1 180350015004028, 180350015004029, 180350015004030, 2 180350016001025, 180350016001033, 180350016001034, 3 180350016001035, 180350016001036, 180350016001037, 4 180350016001038, 180350017001020, 180350017001021, 5 180350017001022, 180350021001010, 180350021001011, 6 180350021001013, 180350021001014, 180350021001015, 7 180350021001016, 180350021001017, 180350021001018, 8 180350021001024, 180350021001025, 180350021001029, 9 180350021001030, 180350021001031, 180350021001032, 10 180350021001033, 180350021001034, 180350021001035, 11 180350021001036, 180350021001037, 180350021001038, 12 180350021001039, 180350021001040, 180350021001041, 13 180350021001042, 180350021001043, 180350021001046, 14 180350021001048, 180350021001049, 180350021001050, 15 180350021001051, 180350021001053, 180350021001054, 16 180350021001055, 180350021001056, 180350021001057, 17 180350021001058, 180350021001059, 180350021001061, 18 180350021001062, 180350021001063, 180350021001064, 19 180350021001065, 180350021001066, 180350021001067, 20 180350021002002, 180350021002013, 180350021002015, 21 180350021002016, 180350021002017, 180350021002018 22 Marion County PRECINCTS: 23 20-01, 20-02, 20-03, 20-04, 20-05, 20-06, 20-07, 20-08, 20-09, 24 20-10, 20-11, 20-12, 21-03, 21-04, 21-05, 21-07, 21-08, 21-09, 25 21-10, 21-11, 21-12, 21-13, 22-01, 22-02, 22-03, 22-04, 22-05, 26 22-06, 22-07, 22-08, 27-01, 27-02, 27-03, 27-04, 27-05, 27-06, 27 27-07, 27-08, 27-09, 27-10, 27-11, 27-12, 27-13, 27-14, 31-01, 28 31-02, 31-03, 31-04, LA-01, LA-02, LA-03, LA-04, LA-05, 29 LA-06, LA-07, LA-08, LA-09, LA-10, LA-11, LA-12, LA-13, 30 LA-14, LA-15, LA-16, LA-17, LA-18, LA-19, LA-20, LA-21, 31 LA-22, LA-23, LA-24, LA-25, LA-26, LA-27, LA-28, LA-29, 32 LA-30, LA-31, LA-32, LA-33, LA-34, LA-35, LA-36, LA-37, 33 LA-38, LA-39, LA-40, LA-41, LA-42, LA-43, LA-44, LA-45, 34 LA-46, LA-47, LA-48, LA-49, LA-50, LA-51, LA-52, LA-53, 35 LA-54, LA-55, LA-56, LA-57, LA-58, LA-59, LA-60, LA-61, 36 LA-62, LA-63, LA-64, LA-65, LA-66, LA-67, WS-39, WS-45, 37 WS-46, WS-47, WS-48, WS-49, WS-50, WS-51, WS-52, 38 WS-53, WS-54, WS-55, WS-56, WS-57, WS-58, WS-59, 39 WS-60, WS-61, WS-62, WS-63, WS-64, WS-65, WS-66, 40 WS-67, WS-68, WS-69 41 Marion County CENSUS BLOCKS: 42 180973205001009, 180973205001011, 180973205001012, HB 1032—LS 6390/DI 144 15 1 180973205001013, 180973205001014, 180973205001015, 2 180973205001016, 180973205001017, 180973205001018, 3 180973205001019, 180973205001020, 180973205002005, 4 180973205002006, 180973205002007, 180973205002009, 5 180973205002010, 180973205002011, 180973205002014, 6 180973207001000, 180973207001001, 180973207001002, 7 180973207001003, 180973207001004, 180973207001006, 8 180973207001008, 180973207001009, 180973207001010, 9 180973207001011, 180973207001012, 180973207001013, 10 180973207001014, 180973207001015, 180973207001016, 11 180973207001017, 180973207001018, 180973207001019, 12 180973207001020, 180973207001021, 180973207001022, 13 180973207001023, 180973207001024, 180973207001026, 14 180973207001027, 180973207001028, 180973207001029, 15 180973207001030, 180973207001031, 180973207001032, 16 180973207001033, 180973207001034, 180973207001035, 17 180973207001036, 180973207001037, 180973207001038, 18 180973207001039, 180973207001040, 180973207001041, 19 180973207001042, 180973207001043, 180973207001044, 20 180973207001045, 180973207001046, 180973207001047, 21 180973207001048, 180973207001049, 180973207001050, 22 180973207001051, 180973207001052, 180973207001053, 23 180973207001054, 180973207001055, 180973207001056, 24 180973207001057, 180973207001058, 180973207001059, 25 180973207001060, 180973207001061, 180973207001062, 26 180973207001063, 180973207001064, 180973207001065, 27 180973207001066, 180973207001067, 180973207001068, 28 180973207001069, 180973207001070, 180973207001071, 29 180973207001072, 180973207001073, 180973209034000, 30 180973211001000, 180973211001001, 180973212001000, 31 180973212001001, 180973212001002, 180973212001003, 32 180973212001004, 180973212001005, 180973212001006, 33 180973212001007, 180973212001011, 180973212001019, 34 180973212001020, 180973212001021, 180973212001022, 35 180973212001023, 180973212001024, 180973212001025, 36 180973212001026, 180973212001027, 180973212001028, 37 180973212001029, 180973212001037, 180973213002000, 38 180973213002001, 180973213002002, 180973213002003, 39 180973213002004, 180973213002005, 180973213002006, 40 180973213002007, 180973213002008, 180973213002009, 41 180973213002010, 180973213002011, 180973213002012, 42 180973213002013, 180973213002014, 180973213002015, HB 1032—LS 6390/DI 144 16 1 180973213002016, 180973213002017, 180973213002018, 2 180973213002019, 180973213002020, 180973213002021, 3 180973214004016, 180973214004017, 180973214004018 4 Sec. 8. The Eighth Congressional District consists of the 5 following: 6 COUNTIES: 7 Daviess County, Dubois County, Gibson County, Knox 8 County, Martin County, Monroe County, Perry County, Pike 9 County, Posey County, Spencer County, Sullivan County, 10 Vanderburgh County, Vigo County, Warrick County 11 Greene County TOWNSHIPS: 12 Beech Creek Township, Cass Township, Center Township, 13 Jackson Township, Taylor Township 14 Greene County PRECINCTS: 15 RICHLAND 4 16 Greene County CENSUS BLOCKS: 17 180559553001016, 180559553001017, 180559553001018, 18 180559553001019, 180559553001020, 180559553001021, 19 180559554001040, 180559554001041, 180559554001042, 20 180559554001043, 180559554001046, 180559554001047, 21 180559554001048, 180559554001049, 180559554001051, 22 180559554001052, 180559554001053, 180559554001054, 23 180559554001055, 180559554003018, 180559554003019, 24 180559554003021, 180559554003022, 180559554003023, 25 180559554003024, 180559554004000, 180559554004001, 26 180559554004014, 180559554004021, 180559554004022, 27 180559554004023, 180559554004024, 180559554004027, 28 180559554004028, 180559554004029, 180559554004030, 29 180559554004033, 180559554004034, 180559554004035, 30 180559554004037, 180559554004038, 180559554004041, 31 180559554004042, 180559554004043 32 Sec. 9. The Ninth Congressional District consists of the 33 following: 34 COUNTIES: 35 Brown County, Clark County, Crawford County, Floyd 36 County, Harrison County, Jackson County, Lawrence 37 County, Morgan County, Orange County, Scott County, 38 Washington County 39 Marion County TOWNSHIPS: 40 Decatur Township 41 Marion County PRECINCTS: 42 01-01, 01-02, 01-03, 01-04, 01-05, 01-06, 01-07, 01-08, 01-10, HB 1032—LS 6390/DI 144 17 1 03-01, 03-02, 03-03, 03-04, 03-05, 04-01, 04-02, 04-03, 04-04, 2 04-05, 05-01, 05-02, 05-03, 05-04, 05-05, 05-06, 06-01, 06-02, 3 06-03, 06-04, 06-05, 06-06, 07-01, 07-02, 07-03, 08-01, 08-02, 4 08-03, 11-01, 11-02, 11-03, 11-04, 11-05, 12-01, 12-02, 12-03, 5 14-01, 14-02, 19-01, 19-02, 19-03, 19-04, 19-05, 19-06, 23-01, 6 23-02, 23-03, 23-04, 23-05, 23-06, 23-08, 24-01, 24-02, 24-03, 7 24-04, 24-05, 29-01, 29-02, 29-03, 29-04, 29-05, 29-06, 29-07, 8 29-08, 29-09, 29-10, 29-11, 29-12, 29-13, 29-14, 29-15, 29-16, 9 29-17, 29-18, WY-03, WY-04, WY-05, WY-06, WY-07, 10 WY-08, WY-09, WY-10, WY-14, WY-15, WY-17, WY-18, 11 WY-19, WY-20, WY-21, WY-23, WY-24, WY-25, WY-26, 12 WY-27, WY-28, WY-29, WY-30, WY-31, WY-32, WY-33, 13 WY-34, WY-35, WY-36, WY-37, WY-38, WY-39, WY-40, 14 WY-41, WY-42, WY-43, WY-44, WY-45, WY-46, WY-47, 15 WY-48, WY-49, WY-50, WY-51, WY-52, WY-53, WY-54, 16 WY-55, WY-56, WY-57, WY-58, WY-59, WY-60 17 Marion County CENSUS BLOCKS: 18 180973401111004, 180973401124001, 180973401131000, 19 180973401131001, 180973401131002, 180973401131003, 20 180973401131005, 180973401131009, 180973401131011, 21 180973519002009, 180973519002010, 180973519002011, 22 180973519002015, 180973519002016, 180973519002017, 23 180973519003010, 180973519003011, 180973519003012, 24 180973519003013, 180973519003014, 180973519003015, 25 180973519003016, 180973519003017, 180973519003018, 26 180973519003019, 180973521001001, 180973521001002, 27 180973521001003, 180973521001004, 180973521001005, 28 180973521001010, 180973521001011, 180973521001012, 29 180973521001013, 180973521002001, 180973521002002, 30 180973521002003, 180973521002007, 180973521002008, 31 180973521002009, 180973521002010, 180973521002011, 32 180973521002012, 180973521002013, 180973521002014, 33 180973521002015, 180973521002017, 180973521002018, 34 180973521002021, 180973521002022, 180973521002023, 35 180973521002024, 180973521003016, 180973527001020, 36 180973527001021, 180973527001022, 180973527001023, 37 180973527001043, 180973527001044, 180973527001048, 38 180973527001049, 180973527001050, 180973527003003, 39 180973527003004, 180973527003005, 180973527003006, 40 180973527003007, 180973527003008, 180973527003009, 41 180973527003010, 180973527003011, 180973527003012, 42 180973527003017, 180973527003018, 180973527003020, HB 1032—LS 6390/DI 144 18 1 180973527003021, 180973527003022, 180973528001000, 2 180973528001001, 180973528001002, 180973528001003, 3 180973528001004, 180973528001005, 180973528001006, 4 180973528001007, 180973528001008, 180973528001009, 5 180973528001010, 180973528001011, 180973528001014, 6 180973528001015, 180973528001016, 180973528001019, 7 180973528001020, 180973528001021, 180973528001022, 8 180973528001023, 180973528001024, 180973528001029, 9 180973528001030, 180973528001031, 180973528001032, 10 180973528001033, 180973528001034, 180973528001035, 11 180973528001036, 180973528001037, 180973528001038, 12 180973528001039, 180973528001042, 180973528001043, 13 180973528001044, 180973528001045, 180973528001046, 14 180973528001047, 180973528001048, 180973528001062, 15 180973528001063, 180973528001064, 180973528001065, 16 180973528001066, 180973528001069, 180973528001070, 17 180973528001071, 180973528001072, 180973528001081, 18 180973544001000, 180973544001001, 180973544001002, 19 180973544001003, 180973544001004, 180973544001005, 20 180973544001006, 180973544001007, 180973544001008, 21 180973544001009, 180973544001010, 180973544001011, 22 180973544001012, 180973544001015, 180973544001016, 23 180973544001017, 180973544001018, 180973544001019, 24 180973544001020, 180973544001021, 180973544001022, 25 180973544001023, 180973544001024, 180973544001025, 26 180973544001026, 180973544001027, 180973544001028, 27 180973544001029, 180973544001030, 180973544001031, 28 180973544001032, 180973544001033, 180973544001034, 29 180973544001035, 180973544001040, 180973544002000, 30 180973544002001, 180973544002002, 180973544002009, 31 180973544002010, 180973544002011, 180973544002012, 32 180973544002013, 180973544002014, 180973544002015, 33 180973544002016, 180973544002020, 180973544002021, 34 180973544002022, 180973544002023, 180973545001004, 35 180973545001005, 180973545001010, 180973545001011, 36 180973545002004, 180973545003005, 180973545003006, 37 180973545003007, 180973545003008, 180973545003015, 38 180973545003016, 180973545003017, 180973545003018, 39 180973545003019, 180973545003020, 180973545003021, 40 180973545003022, 180973545003023 41 SECTION 8. IC 3-11-1.5-4 IS AMENDED TO READ AS 42 FOLLOWS [EFFECTIVE UPON PASSAGE]: Sec. 4. (a) A county HB 1032—LS 6390/DI 144 19 1 executive shall establish precincts so that each boundary of each 2 precinct does not cross the boundary of: 3 (1) the state; 4 (2) a county; 5 (3) a township; 6 (4) a district of the House of Representatives of the Congress of 7 the United States; 8 (5) a district of the senate of the general assembly; or 9 (6) a district of the house of representatives of the general 10 assembly. 11 (b) Notwithstanding subsection (a), for purposes of the 2026 12 primary and general election, a precinct may cross the boundary 13 of a district of the House of Representatives of the Congress of the 14 United States. This subsection expires November 4, 2026. 15 SECTION 9. IC 3-11-1.5-20.5 IS AMENDED TO READ AS 16 FOLLOWS [EFFECTIVE UPON PASSAGE]: Sec. 20.5. (a) This 17 section applies when: 18 (1) a county executive is advised that a proposed precinct 19 establishment order does not comply with this chapter; and 20 (2) the county executive determines that the noncompliance 21 cannot be corrected by the establishment of a precinct that 22 complies with both: 23 (A) the maximum voter requirement of section 3 of this 24 chapter; and 25 (B) the precinct boundary requirements of section 5 of this 26 chapter. 27 (b) The county executive may request the commission to grant an 28 exemption from the precinct boundary requirements of section 5 of this 29 chapter to establish a precinct boundary described by this section. 30 (c) The commission shall conduct a hearing on the exemption 31 request. If the commission determines that the noncompliance cannot 32 be corrected by the establishment of a precinct that complies with both: 33 (1) the maximum voter requirement of section 3 of this chapter; 34 and 35 (2) the precinct boundary requirements of section 5 of this 36 chapter; 37 the commission shall grant the exemption. However, the commission 38 may not grant an exemption that violates section [deleted: 4(1),] 4(a)(1), 4(a)(4), 39 [deleted: 4(5),] 4(a)(5), [deleted: 4(6),] or (4)(a)(6) [deleted: 4(7)] of this chapter. 40 (d) If the commission grants the exemption, the county executive 41 shall amend the proposed precinct establishment order described by 42 section 19 of this chapter to establish precinct boundaries: HB 1032—LS 6390/DI 144 20 1 (1) in accordance with the exemption granted by the commission; 2 and 3 (2) that comply with all other requirements established by this 4 chapter. 5 (e) The proposed precinct establishment order described in 6 subsection (d) must include a description in metes and bounds of the 7 boundaries authorized by the exemption granted under this section. 8 SECTION 10. IC 3-11-1.5-35, AS AMENDED BY P.L.2-2005, 9 SECTION 3, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE 10 UPON PASSAGE]: Sec. 35. (a) This section applies to a county that 11 has a precinct that crosses a boundary in violation of section [deleted: 4(4),] 12 4(a)(4), [deleted: 4(5),] 4(a)(5), or [deleted: 4(6)] 4(a)(6) of this chapter. 13 (b) Notwithstanding section 25 of this chapter, if the county does 14 not issue a precinct establishment order that establishes precincts in 15 compliance with section [deleted: 4(4),] 4(a)(4), [deleted: 4(5),] 4(a)(5), and [deleted: 4(6)] 4(a)(6) 16 of this chapter by the January 31 following the last effective date 17 described in section 25(2) of this chapter, the commission may issue an 18 order establishing precincts as provided under subsection (c). 19 (c) An order issued by the commission under this section must 20 comply with section [deleted: 4(4),] 4(a)(4), [deleted: 4(5),] 4(a)(5), and [deleted: 4(6)] 4(a)(6) of this 21 chapter. 22 (d) The co-directors shall send a copy of the commission's order to 23 the office. 24 SECTION 11. [EFFECTIVE UPON PASSAGE] (a) The definitions 25 in IC 3-5-2.1 apply throughout this SECTION. 26 (b) The election division shall assist each county voter 27 registration office with the implementation of this act. 28 (c) This SECTION expires July 1, 2027. 29 SECTION 12. [EFFECTIVE UPON PASSAGE] (a) The districts 30 described by IC 3-3-7, as added by this act, apply to an election to 31 the office of United States Representative beginning with the 32 primary and general elections in 2026 for members of the 120th 33 Congress. This act does not affect the membership or the 34 congressional districts of the 119th Congress. 35 (b) This SECTION expires July 1, 2027. 36 SECTION 13. An emergency is declared for this act. HB 1032—LS 6390/DI 144 21 COMMITTEE REPORT Mr. Speaker: Your Committee on Elections and Apportionment, to which was referred House Bill 1032, has had the same under consideration and begs leave to report the same back to the House with the recommendation that said bill do pass. (Reference is to HB 1032 as introduced.) WESCO Committee Vote: Yeas 8, Nays 5 HB 1032—LS 6390/DI 144 [extracted by pdf-snapshot.ts with strike detection, 2026-10-01T18:41:34.220Z, https://iga.in.gov/pdf-documents/124/2026/house/bills/HB1032/HB1032.02.COMH.pdf, from saved file]

---
snapshot_id: 573edad6-a2b9-5813-8484-e917c31c0c9c
source_kind: public-record
url: https://iga.in.gov/legislative/2026/bills/house/1032/details

IGA | House Bill 1032 (2026) Indiana General Assembly 2026 Session. House Bill 1032 Redistricting. House Bill (S) Authored by: Rep. Ben Smaltz. Co-Authored by: Rep. Alex Zimmerman. Sponsored by: Sen. Mike Gaskill, Sen. Chris Garten, Sen. Liz Brown, Sen. Tyler Johnson, Sen. Gary Byrne, Sen. Michael Young. Digest Allows the general assembly to amend congressional districts at a time other than the first regular session of the general assembly convening immediately following the United States decennial census. Specifies requirements that apply to any action challenging the apportionment of congressional districts or general assembly districts. Establishes new Indiana congressional districts. Provides for expiration of the current congressional districts on the date of the 2026 general election. Specifies that for purposes of the 2026 primary and general election, a precinct may cross the boundary of a congressional district. Latest Bill Actions: S 12/11/2025 Third reading: defeated; Roll Call 8: yeas 19, nays 31. [Bill details for HB 1032 (2026), saved by browser from iga.in.gov on 2026-10-01.]

---
snapshot_id: caec4816-01dc-5b50-a525-dc2d2b388e65
source_kind: own-site (the person's own site or account)
url: https://repmattpierce.substack.com/p/house-republicans-pass-their-gerrymandered

House Republicans Pass Their Gerrymandered Map Rep. Matt Pierce's Newsletter Subscribe Sign in House Republicans Pass Their Gerrymandered Map House Bill 1032 heads to the Senate for consideration on Monday, Dec. 8. Rep. Matt Pierce Dec 05, 2025 Share Neighbors, This is a sad day for Indiana. It’s a sad day for democracy. House Republicans passed HB 1032 , their gerrymandered congressional map, to give themselves an unfair advantage in Indiana’s elections. But the battle is not yet over! Make no mistake: this isn’t about good governance. It’s about rigging the system at Washington, D.C.’s behest. Hoosiers across our state – Democrats, Republicans, and independents – have been clear: they want fair maps and healthy competition. Instead, House Republicans caved to put Washington’s wants above Hoosiers’ needs. I fought hard against the maps. I offered an amendment to not redraw the maps now and instead establish a non-partisan system of redistricting, in which no political data could be used when maps are next redrawn in 2031. If the proposed maps become law, thousands of Hoosiers could have their voices silenced, especially voters of color. But they can’t gerrymander our determination to continue fighting for our democracy. The bill will now have a hearing in the Senate on Monday. Urge your friends and neighbors who live in Republican districts to contact their state senators. Let them know they should listen to their constituents, not Washington, D.C. Let them know, instead of focusing on preserving political power, they should do something about working families who are struggling, health care insurance that is too expensive, the lack of affordable childcare, and skyrocketing utility costs. They’re counting on you to give up. Don’t. Below is a video of the speech I gave today on the House floor: Sincerely, Matt Pierce Share Top Latest No posts Ready for more? Subscribe © 2026 Rep. Matt Pierce · Privacy ∙ Terms ∙ Collection notice Start your Substack Get the app Substack is the home for great culture This site requires JavaScript to run correctly. Please turn on JavaScript or unblock scripts