You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-thomson-economic-development/labels/coder-3.json. Write JSON only, matching
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

politician_id: 1c6dbdaf-e110-48d3-9b88-27f911d9521f  office_id: b42f6de3-da88-4d50-af66-c78cdb46e628
Kerry Thomson — City Mayor, Indiana (seated, level: local)
Current term: unknown (precision: unknown) to present

## Topics (served ladder text — code against these words only)

### topic_key: economic-development
topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53  served_revision_id: af855dba-96f3-4fa0-beb7-43c5edb3f499
Question: How should government attract businesses and support economic development?
  1. Don't give companies tax breaks or subsidies. Invest in public services and infrastructure so businesses want to come on their own.
  2. Help small and local businesses grow, but don't offer subsidies to attract large outside companies.
  3. Offer incentives to attract businesses, but only if they commit to good wages and local hiring — and pay the money back if they don't deliver.
  4. Offer large tax breaks and infrastructure to attract major employers, but keep limits and pass on deals that cost too much.
  5. Offer the largest incentives to attract any large employer, with no conditions or spending limits.

#### Annex

# economic-development — served revision af855dba-96f3-4fa0-beb7-43c5edb3f499 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should government attract businesses and support economic development?"

**Orientation:** standard, on an incentive scale. Rung 1 gives companies no tax breaks or subsidies,
rung 5 gives the largest incentives with no conditions or limits. The rungs order **how much public
money and help goes to individual companies, and on what terms**. This is not a size-of-government
scale: rung 1 still spends on public services, and rung 5 spends the most on companies. Do not read
rung 1 as "most government".

**Levels with a lever:** local, state. State: tax-credit and closing-fund
programmes, the economic-development agency, megasite deals. Local: property-tax abatements, tax
increment financing, land and site infrastructure, local development corporations.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "tax abatement", "PILOT" (payment in lieu of taxes), "tax increment financing" (TIF),
"enterprise zone", "opportunity zone", "deal-closing fund", "job-creation tax credit", "megasite",
"community benefits agreement" (CBA), "clawback", "recapture", "performance agreement",
"prevailing wage", "local-hire requirement", "business retention and expansion", "small-business
grant", "revolving loan fund".

1. **"Don't give companies tax breaks or subsidies. Invest in public services and infrastructure so
   businesses want to come on their own."**
   - Means: no company-specific incentives; public money goes to services and infrastructure for
     everyone instead.
   - Operative clauses: [a] no tax breaks or subsidies to companies; [b] invest in public services
     and infrastructure instead.
   - Establishing evidence looks like: own words rejecting incentives as a tool, **plus** support for
     general public investment; a vote to repeal or end an incentive programme. [a] is an absence
     clause ("don't give"): it must be stated, and a No on one deal does not state it (V4.2 "Silence
     is not a clause"). Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both refuse subsidies to large companies. Rung 2 still
     helps small and local businesses; any support for a small-business programme excludes rung 1.

2. **"Help small and local businesses grow, but don't offer subsidies to attract large outside
   companies."**
   - Means: public help goes to small and local firms; large firms from outside get none.
   - Operative clauses: [a] help small and local businesses grow; [b] no subsidies to attract large
     outside companies.
   - Establishing evidence looks like: a small-business grant, loan or technical-assistance programme
     **plus** a passage that refuses incentives for large outside firms. Compound: one side only →
     `compound-partial` (V4.2). [b] is an absence clause and must be stated.
   - Levels that hold a lever: state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1. A small-business programme alone does not exclude
     rungs 3–5, because a person can fund small firms and also recruit large ones → `direction-only`
     _(proposed)_.

3. **"Offer incentives to attract businesses, but only if they commit to good wages and local hiring
   — and pay the money back if they don't deliver."**
   - Means: incentives are acceptable when they are tied to job quality and local jobs, and are
     recovered if the company fails.
   - Operative clauses: [a] incentives to attract businesses; [b] conditioned on good wages **and**
     local hiring; [c] clawback if the company does not deliver.
   - Establishing evidence looks like: an incentive programme or deal whose text carries wage and
     local-hire conditions and a clawback; own words requiring all three. Compound: some clauses only
     → `compound-partial` (V4.2).
   - Levels that hold a lever: state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because many large deals carry some conditions. Rung 4 "keeps
     limits" on **cost**; rung 3 sets **job-quality** conditions and recovers the money. A deal with a
     job-count target and a cost cap but no wage or local-hire term does not meet [b] _(proposed)_.
   - A general clawback or disclosure law for all incentive deals meets [c] only → `compound-partial`
     _(proposed)_.

4. **"Offer large tax breaks and infrastructure to attract major employers, but keep limits and pass
   on deals that cost too much."**
   - Means: compete for major employers with large incentives, but with a ceiling, and walk away from
     deals that are too expensive.
   - Operative clauses: [a] large tax breaks and infrastructure to attract major employers; [b] keep
     limits and pass on deals that cost too much.
   - Establishing evidence looks like: a vote for a large employer-attraction package **plus** a
     passage that sets or keeps a cap, a cost-per-job limit or a refusal of another deal on cost.
     Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because a Yes on one large deal fits both. One Yes shows [a] and
     says nothing about limits → `direction-only` (V4: chair-shaped must exclude the adjacent rungs)
     _(proposed)_.
   - **Site infrastructure built for one employer** (roads, water, power to a megasite) is an
     incentive under [a]. **General** infrastructure open to all is rung 1 [b] _(proposed)_.

5. **"Offer the largest incentives to attract any large employer, with no conditions or spending
   limits."**
   - Means: give whatever it takes to land any large employer, with no strings and no ceiling.
   - Operative clauses: [a] the largest incentives, for any large employer; [b] no conditions and no
     spending limits.
   - Establishing evidence looks like: own words rejecting caps or conditions on incentives; a vote to
     remove a cap, a clawback or a job-quality condition from an incentive programme. [b] is an
     absence clause: a deal that **happens** to carry no conditions does not show that the person
     rejects all conditions (V4.2 "Silence is not a clause").
   - Levels that hold a lever: state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **A uniform tax change for every business** (a general rate cut, a change to how all business
  property is valued, an across-the-board exemption) is tax policy, not an incentive to attract
  employers → `adjacent`; BLANK `no-evidence` when nothing else survives. Read the operative numbers
  carefully: a change to how property is valued is not a tax-rate change.
- **A No on one deal** fits rung 1, rung 2 and rung 4 ("pass on deals that cost too much") →
  `direction-only`.
- **Workforce training and education** programmes not tied to attracting a company → `adjacent`
  _(proposed)_.
- **Preemption (codebook V2, H12).** A state law that limits what localities may offer decides which
  level acts → `adjacent`.
- **Budget and omnibus votes** with an incentive line → V4 `multi-subject`. A single-subject deal
  approval (one abatement, one TIF district) is not multi-subject.
- **Ground-breakings, ribbon-cuttings and "open for business" lines** → `rhetorical`.


## Sources

---
snapshot_id: 32bcaad3-a537-580f-8da9-237e1f71db10
source_kind: own-site (the person's own site or account)
url: https://bloomington.in.gov/news/2026/07/06/6590

Thomson Administration Outlines Path Forward for Seminary Pointe and Convention Center Hotel | City of Bloomington, Indiana Skip to main content Mayor Kerry Thomson Search Search Services Services Information Info News News Meetings & Events Events City Government Govt. Breadcrumb News Releases 2026 July 06 Thomson Administration Outlines Path Forward for Seminary Pointe and Convention Center Hotel Share: Share on Facebook Share on Twitter Email this Page Page last updated on July 6, 2026 at 1:03 pm July 6, 2026 For more information, please contact Kerry Thomson, Mayor [email protected] or 812-349-3406 Desiree DeMolina, Communications Director, Office of the Mayor [email protected] or 812-349-3406 Thomson Administration Outlines Path Forward for Seminary Pointe and Convention Center Hotel In response to recent questions from members of the public, local advocates, and media regarding the future of Seminary Pointe, College Square, and the Convention Center headquarters hotel, the Thomson administration is providing additional context on the legal process governing the Bloomington Redevelopment Commission's (RDC) actions and reaffirming its commitment to both preserving deeply affordable housing and advancing the Convention Center project. The administration emphasized that the current public offering for College Square remains open, including to the Capital Improvement Board (CIB), and that the process is intended to create a lawful and transparent path for future negotiations, not prevent them. Statement from Mayor Kerry Thomson “Bloomington does not have to choose between preserving deeply affordable housing and delivering a successful Convention Center headquarters hotel. We can—and should—do both. “Recent discussion about Seminary Pointe and the Convention Center hotel selection process has combined multiple negotiations, legal requirements, and separate decision-making processes into a single narrative that does not accurately reflect how the RDC is required to operate under Indiana law. We want to clearly correct a few key points and provide context for the path forward. “The Thomson administration continues to support the preservation of the 29 deeply affordable units currently located at Seminary Pointe, and has outlined a process for ensuring that they are retained in our community. Both the RDC and the administration also support the College Square property being utilized by a Convention Center hotelier, and always have. “Staff negotiated for over a year with the CIB’s chosen hotelier in an effort to make the project financially viable. The Hunden Study states an average of approximately 33% public subsidy is required for a host hotel. When the RDC was asked to negotiate with the hotelier, a significant gap existed. With all the capital projects underway, the RDC did not have the capacity to contribute additional subsidy beyond the land itself. Staff requested assistance from the County and the CIB, but a funding gap remained. “Unfortunately, the proposed land contribution did not receive Common Council support. The Council and the public made it clear that the RDC should determine what alternatives are available for College Square before transferring the property for a nominal amount to a hotel project. The current offering, which will end in just two weeks, will provide this requested information. “Based on current market conditions, the price tag of $7 million is likely extremely difficult to achieve unless the City supports high-rise, luxury student-centric development, which is not supported by the administration or the RDC on this site. “Before the RDC can transfer ownership of property, Indiana law requires a public offering based on the average of two appraisals. If the RDC determines there are no acceptable offers, it may reject all bids and, after that 30-day period, negotiate consistent with state law. “In order to transparently evaluate the market & fulfill the statutory requirement for College Square, the RDC moved forward with the offering. This was outlined as the plan months in advance of issuing the offering. “The RDC continued to support the CIB and the Convention Center with a land donation immediately south of the Convention Center valued at $3.15M. “Just before issuing the offering on College Square, a request was made to pause the offering to negotiate with the CIB and trade parcels. “In order to do that, the RDC had to have documentation to defend that decision. No information was available at the time to justify such a decision. Continuing to issue the offering provided the needed time for documentation, allowed the RDC to meet its statutory requirements to proceed in making a defensible decision, and gave the CIB an avenue to negotiate. “Recent commentary that the CIB cannot issue an offering is inaccurate. The RDC offering on College Square lists a dozen selection criteria and Indiana Code lists another half a dozen selection criteria beyond just a purchase price. The RDC acknowledges that in this economy, there is much more than money to consider for the economic health of our community and the current offering is open to all qualified respondents, including the CIB. “The latest request to start negotiating with the CIB prior to the conclusion of our offering could subject the RDC to litigation. The RDC cannot pause its offering but would be happy to receive a proposal. “Recent statements suggesting the RDC has rejected the CIB "four times" do not reflect the official record. There has been no official offer. If there is a path forward direct communication is necessary, particularly knowing the funding gaps for host hotels, parking & other needs unlikely to be addressed using the South parcels. “Director Killion-Hanson continues to offer her assistance in identifying a collaborative path forward that preserves affordable housing while advancing the Convention Center project.” Attachments FAQ: College Square. (84.07 KB) cob-logo-horizontal City Jobs Contact the City Report an Issue Connect on Social Media City Maps Transparency Accessibility Privacy Policy City Intranet City Hall 401 North Morton Street Bloomington, Indiana 47404 812-349-3400 Facebook Twitter Instagram NextDoor YouTube

---
snapshot_id: c28c93dc-53cd-53bc-b342-3ea34f5e1673
source_kind: own-site (the person's own site or account)
url: https://bloomington.in.gov/news/2026/01/21/6431

Mayor Thomson Signals New Direction for College Square Property, Emphasizes Economic Development, Convention Center Progress, and Downtown Connectivity | City of Bloomington, Indiana Skip to main content Mayor Kerry Thomson Search Search Services Services Information Info News News Meetings & Events Events City Government Govt. Breadcrumb News Releases 2026 January 21 Mayor Thomson Signals New Direction for College Square Property, Emphasizes Economic Development, Convention Center Progress, and Downtown Connectivity Share: Share on Facebook Share on Twitter Email this Page Page last updated on January 21, 2026 at 4:54 pm January 21, 2026 For more information, please contact Desiree DeMolina, Communications Director, Office of the Mayor [email protected] or 812-349-3406 Mayor Thomson Signals New Direction for College Square Property, Emphasizes Economic Development, Convention Center Progress, and Downtown Connectivity Mayor Kerry Thomson today announced her administration’s intent to move forward with a new approach for the College Square property at 200-226 S. College Avenue, following action by the Capital Improvement Board (CIB) to discontinue negotiations with Dora Hospitality. The Mayor stated she will formally ask the Bloomington Redevelopment Commission (RDC) to place the property on the market for redevelopment focused on economic development uses and to pursue a new, narrower request for proposals that aligns with the City’s long-term downtown economic and convention center goals. “After months of good-faith efforts to make this site work for a convention center host hotel contractor, it has become clear to all parties—including our Capital Improvement Board leadership—that this property is not the right fit for that purpose,” Mayor Thomson said. “The responsible step now is to move forward, put this asset back into productive use, and focus our energy on solutions that will deliver real economic benefit to the community.” The College Square property was acquired under the previous administration based on assumptions that ultimately proved unworkable. While the City explored multiple options to make the site viable, financing realities prevented the hotel project from moving forward. Background on the Property The Bloomington Redevelopment Commission acquired the College Square property in two transactions totaling approximately $7 million in 2019 and 2023 during the Hamilton administration, with the stated purpose of facilitating a Monroe County Convention Center expansion. However, as the convention center hotel development plans evolved, significant challenges emerged regarding the site's suitability for the host hotel. Following extensive site assessments and concept designs, Mayor Thomson worked closely with the Capital Improvement Board and potential developers to evaluate the property's viability. On December 17, 2025, the CIB formally communicated to Dora Hospitality that the city would not be donating the land for hotel development at this location. Convention center host hotels serve a specific public purpose. Unlike typical hotels, host hotels are designed to support multi-day conferences by guaranteeing room blocks and stable group rates—requirements that are essential for a convention center to attract large events and generate new economic activity. Mayor Thomson outlined the actions her administration is asking the Redevelopment Commission to make to resolve the situation and advance keep priorities. 1. Convention Center Hotel Development Moves Forward at More Viable Sites The Capital Improvement Board will continue advancing a convention center host hotel at alternative locations that are better suited to meet operational and financial requirements. 2. College Square to Be Marketed for Economic Development Uses The Mayor will ask the Redevelopment Commission to immediately begin the process of marketing the College Square property for private redevelopment. The administration’s intent is clear: future use of the site should prioritize economic development. A new request for proposals will narrow the scope of acceptable uses and may include hospitality or hotel development, among other economically productive options. Student housing will not be included as part of the redevelopment vision for this site. “This is valuable real estate in the heart of our community,” Mayor Thomson said. “It needs to be contributing—supporting economic activity, strengthening downtown, and returning to the tax rolls.” “We’ve done the analysis,” the Mayor added. “It’s time to make a clear decision and move forward in Bloomington’s best interest.” 3. Supporting Downtown Economic Development Mayor Thomson emphasized that proceeds from the College Square property sale are intended to support downtown economic development priorities, particularly at a moment when Bloomington—like communities across Indiana—is navigating new fiscal constraints. Recent changes in state law, including Senate Enrolled Act 1 (SEA 1), limit the City’s ability to rely on traditional revenue growth tied to property taxes. As a result, the City must be more intentional about investments that strengthen the local economy, grow wages, and attract workforce talent. 4. Advancing a Connected Center City Vision Placing the College Square property back into productive use is part of a broader effort to catalyze investment and connectivity across Bloomington’s center city—linking the convention center, Trades District, Hopewell redevelopment, and Switchyard Park. “It's time to get moving on an ambitious vision that will transform Bloomington's center city,” Mayor Thomson said. “This is about unlocking the potential of an entire corridor and creating the kind of dynamic, connected urban environment that will serve Bloomington for generations to come.” The Redevelopment Commission is expected to consider next steps in the coming weeks, including development of a new request for proposals. cob-logo-horizontal City Jobs Contact the City Report an Issue Connect on Social Media City Maps Transparency Accessibility Privacy Policy City Intranet City Hall 401 North Morton Street Bloomington, Indiana 47404 812-349-3400 Facebook Twitter Instagram NextDoor YouTube

---
snapshot_id: 9e8e3a26-faa3-5076-97d9-df20faf3a6b1
source_kind: own-site (the person's own site or account)
url: https://bloomington.in.gov/news/2026/05/21/6551

City Issues Will-Serve Letter to Support Economic Readiness at Monroe County Airport | City of Bloomington, Indiana Skip to main content Mayor Kerry Thomson Search Search Services Services Information Info News News Meetings & Events Events City Government Govt. Breadcrumb News Releases 2026 May 21 City Issues Will-Serve Letter to Support Economic Readiness at Monroe County Airport Share: Share on Facebook Share on Twitter Email this Page Address 401 N Morton Street Suite 150 Bloomington IN 47404 Phone 812-349-3418 Email [email protected] Facebook Connect on Facebook Page last updated on May 21, 2026 at 8:15 am May 21, 2026 For more information, please contact Jane Kupersmith, Director, Economic and Sustainable Development [email protected] or 812-349-3477 Desiree DeMolina, Communications Director, Office of the Mayor [email protected] or 812-349-3406 City Issues Will-Serve Letter to Support Economic Readiness at Monroe County Airport The City of Bloomington has issued a will-serve letter for Monroe County Airport , supporting infrastructure readiness and future aviation-related economic development at one of the region’s key public assets. Monroe County Airport supports business travel, emergency response, visitor access, aviation services, and connections to regional employers and institutions. By clarifying that sanitary sewer service can be considered for airport-related uses, the City is helping make the airport more ready to attract businesses, create jobs, and bring more investment to Bloomington and Monroe County. “This is what economic development looks like before the ribbon cutting,” Mayor Kerry Thomson said. “It is infrastructure, partnership, and planning that make future jobs and investment possible. Monroe County Airport is a regional economic resource, and this step helps make sure Bloomington and Monroe County are ready to compete for opportunities that strengthen our community.” A will-serve letter is a utility service document. In this case, the City of Bloomington Utilities Department has confirmed that it can accept sanitary sewer service for airport parcels at 960 S. Kirby Road, subject to approved terms and conditions. The approval remains subject to Utilities engineering review, infrastructure requirements, capacity findings, and other applicable conditions. “We are grateful to Mayor Thomson, City Utilities, and the City of Bloomington for taking this important step in support of Monroe County Airport,” said Carlos Laverty, Airport Director. “This will-serve letter helps remove uncertainty around future airport-related development and strengthens our ability to compete for aviation, aerospace, defense, and other compatible business opportunities. Infrastructure readiness is not always visible to the public, but it is often what determines whether a community is truly prepared to attract jobs and investment.” The letter does not approve a specific development project, airport expansion, or sewer connection. Any future proposal must still complete the applicable engineering, permitting, funding, review and approval processes. The action comes as cities across Indiana are operating in a changing fiscal environment following Senate Enrolled Act 1, or SEA 1, which is expected to reduce revenue available to local governments. As traditional revenue growth becomes more constrained, infrastructure readiness and economic development become increasingly important tools for supporting future jobs, investment, and tax base growth. “SEA 1 is part of the fiscal landscape, but this decision is about doing the right thing for a regional economic asset, supporting City-County partnership, and creating clearer conditions for future jobs and investment,” Mayor Thomson said. The City will provide additional information as the review matrix is developed and as future airport-related proposals move through the appropriate review processes. Related Categories Department: Economic and Sustainable Development cob-logo-horizontal City Jobs Contact the City Report an Issue Connect on Social Media City Maps Transparency Accessibility Privacy Policy City Intranet City Hall 401 North Morton Street Bloomington, Indiana 47404 812-349-3400 Facebook Twitter Instagram NextDoor YouTube

---
snapshot_id: ac5e6d1a-0925-5797-bc9a-0c04862f9ef3
source_kind: own-site (the person's own site or account)
url: https://bloomington.in.gov/news/2024/08/27/6020

Bloomington, Monroe County Officials Sign Letter Supporting New Economic Development District in South Central Indiana | City of Bloomington, Indiana Skip to main content Mayor Kerry Thomson Search Search Services Services Information Info News News Meetings & Events Events City Government Govt. Breadcrumb News Releases 2024 August 27 Bloomington, Monroe County Officials Sign Letter Supporting New Economic Development District in South Central Indiana Share: Share on Facebook Share on Twitter Email this Page Address 401 N Morton St Suite 210 Bloomington IN 47404 Phone 812-349-3406 Fax 812-349-3455 Facebook Connect on Facebook Twitter Follow us on Twitter Page last updated on August 27, 2024 at 1:28 pm August 27, 2024 For more information, please contact Jane Kupersmith, Director of Economic and Sustainable Development [email protected] or 812-349-3418 Desiree DeMolina, Communications Director, Office of the Mayor [email protected] or 812-349-3406 Bloomington, Monroe County Officials Sign Letter Supporting New Economic Development District in South Central Indiana Officials from the City of Bloomington, Monroe County, and the Bloomington City Council have jointly signed a letter of support for the establishment of a new Economic Development District (EDD) in South Central Indiana. The proposed EDD would include Brown, Monroe, and Owen Counties—regions known for their shared economic strengths and collaborative efforts. The letter, addressed to the United States Department of Commerce's Economic Development Administration (EDA), underscores the potential benefits of formalizing regional cooperation in economic development. The signatories highlighted the area's robust life sciences, higher education, technology, and defense sectors, as well as its historical significance in the limestone industry, which has shaped the region for over two centuries. “Our counties share not only a labor shed but also a rich history, regional beauty, and the economic benefits brought by Indiana University,” Mayor Kerry Thomson stated in her letter. “Bloomington has already seen significant advantages from the EDA’s support of the Trades District Technology Center, or The Forge, which received a $3.5 million CARES Act Grant. This support has catalyzed the growth of our tech ecosystem and strengthened regional partnerships.” Mayor Thomson emphasized the importance of having a Comprehensive Economic Development Strategy (CEDS) document in place. “With a CEDS, we will be better positioned to apply for future funding opportunities and maximize the impact of these funds across the region. This will particularly benefit workforce and sector development, climate action initiatives, and the enhancement of our transportation corridor.” Mayor Thomson concluded, “I wholeheartedly support the creation of this Economic Development District and look forward to continuing our partnership with the Economic Development Administration to drive growth and prosperity for our region.” “We are grateful for the leadership of Marce King of the Owen County Chamber and EDC and for the support of our community leaders in Bloomington, Monroe County, Brown County, and Ellettsville,” says Jane Kupersmith, Director of the City’s Economic and Sustainability Department. “This regional approach represents a sea change and should be celebrated.” Related Categories Department: Office Of The Mayor cob-logo-horizontal City Jobs Contact the City Report an Issue Connect on Social Media City Maps Transparency Accessibility Privacy Policy City Intranet City Hall 401 North Morton Street Bloomington, Indiana 47404 812-349-3400 Facebook Twitter Instagram NextDoor YouTube

---
snapshot_id: 0c438c37-4a90-590b-a851-34edbe45cf59
source_kind: own-site (the person's own site or account)
url: https://bloomington.in.gov/news/2026/06/12/6570

City Names Lynn Coyne Interim Director of Planning and Transportation | City of Bloomington, Indiana Skip to main content Mayor Kerry Thomson Search Search Services Services Information Info News News Meetings & Events Events City Government Govt. Breadcrumb News Releases 2026 June 12 City Names Lynn Coyne Interim Director of Planning and Transportation Share: Share on Facebook Share on Twitter Email this Page Address 401 N Morton St Suite 130 Bloomington IN 47404 Phone 812-349-3423 Fax 812-349-3520 Email [email protected] Facebook Connect on Facebook Twitter Follow us on Twitter Page last updated on June 12, 2026 at 4:47 pm June 12, 2026 For more information, please contact Desiree DeMolina, Communications Director, Office of the Mayor [email protected] or 812-349-3406 City Names Lynn Coyne Interim Director of Planning and Transportation Mayor Kerry Thomson has appointed Lynn Coyne to serve as Interim Director of the City of Bloomington Planning and Transportation Department, pending a vote by the Bloomington Plan Commission before his official start date. Coyne succeeds David Hittle, who has accepted a position with the City of Charlotte, North Carolina. Hittle’s last day with the City of Bloomington will be July 10. A longtime Bloomington civic and economic development leader, Coyne brings decades of experience in law, real estate, economic development, higher education, and civic leadership. His career has included work at the intersection of public policy, land use, institutional planning, business development, and community partnerships. He has served as President and CEO of the Bloomington Economic Development Corporation; Assistant Vice President for Real Estate at Indiana University; Associate University Counsel at Indiana University; and Special Assistant to the Vice President for Capital Planning and Facilities at Indiana University. He also practiced law in Bloomington with a focus on real estate, business transactions, and public sector matters. “Bloomington’s Planning and Transportation Department has direct impacts on my priorities— housing people can afford, strong neighborhoods, safer streets, sustainability, inclusion, and a quality of life that makes people want to stay,” said Mayor Kerry Thomson. “The work now is making sure our systems can actually deliver on those priorities. Lynn understands Bloomington, and he understands where good projects get stuck. His experience will improve our processes, strengthen collaboration with residents, builders, employers, and community partners, and create more of the quality housing Bloomington needs.” The interim appointment comes as the City moves through several related pieces of work, including a cross-departmental review of permitting and plan review processes, proposed Unified Development Ordinance (UDO) amendments related to housing and business compliance, and continued efforts to support attainable housing and neighborhood-scale development. Results from the permitting assessment are expected this summer. The UDO amendments remain on track for Council consideration after its summer recess. “I am grateful for the opportunity to serve Bloomington in this interim role and support Mayor Thomson’s priorities at an important moment for our community,” said Coyne. “I look forward to helping advance this work and supporting decisions that serve Bloomington well.” Coyne will serve in an interim capacity while the City continues evaluating the department’s long-term leadership needs. “Our systems have to deliver for people. Lynn’s role is to help us keep moving,” said Thomson. “We have important work ahead, and this appointment reflects our commitment to implementation, partnership, and accountability.” If confirmed by the Plan Commission, Coyne will begin serving in July 2026. Related Categories Department: Planning and Transportation cob-logo-horizontal City Jobs Contact the City Report an Issue Connect on Social Media City Maps Transparency Accessibility Privacy Policy City Intranet City Hall 401 North Morton Street Bloomington, Indiana 47404 812-349-3400 Facebook Twitter Instagram NextDoor YouTube