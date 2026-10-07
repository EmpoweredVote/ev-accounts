You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-pierce-nosource-r3/labels/coder-1.json. Write JSON only, matching
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

### topic_key: growth-and-development
topic_id: fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4  served_revision_id: 65e8ffd5-5aac-4d40-8862-a321949eafa4
Question: How should government manage population growth and new development?
  1. Hold the pace of growth down — cap major new development, and let residents vote directly on the largest projects.
  2. Allow growth only as fast as current infrastructure can handle — make new development wait for capacity.
  3. Welcome steady growth — invest in roads, water and schools ahead of demand so expansion isn't held back.
  4. Actively push for faster growth — cut red tape and recruit new development, while keeping basic guardrails.
  5. Step back and let the market set the pace — remove development constraints beyond basic health and safety.

#### Annex

# growth-and-development — served revision 65e8ffd5-5aac-4d40-8862-a321949eafa4 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should government manage population growth and new development?"

**Orientation:** off-axis (CLAUDE.md lists it). Read it as one scale of **how fast government lets
growth happen**: rung 1 holds growth down, rung 5 lets the market set the pace. It is **not** a
size-of-government scale. Rung 1 restrains growth by regulation, rung 3 spends the most (it builds
infrastructure ahead of demand), and rung 5 removes rules. A "more government" reading and a "less
regulation" reading point in different directions here, so place a person by the **pace** their act
or words support, never by who usually holds a view.

**Levels with a lever:** local, state. Local: approvals, caps, moratoria,
capital plans, impact fees, annexation. State: growth-management acts, infrastructure funding, and
laws that limit or override local development rules. State officials rarely approve one project.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "growth cap", "building-permit allocation", "urban growth boundary", "adequate public
facilities ordinance" (APFO), "concurrency", "development moratorium", "capital improvement plan",
"impact fee", "annexation", "growth-management act", "entitlement", "streamlining", "by-right
approval", "shot clock", "ballot-box zoning", "voter approval of development".

1. **"Hold the pace of growth down — cap major new development, and let residents vote directly on
   the largest projects."**
   - Means: limit how much new development can happen, and give residents a direct vote on the
     largest projects.
   - Operative clauses: [a] cap major new development; [b] residents vote directly on the largest
     projects.
   - Establishing evidence looks like: a cap or permit allocation on new development **and** a
     requirement that the largest projects go to a public vote. Compound: one side only →
     `compound-partial` (V4.2).
   - Levels that hold a lever: local (caps, charter amendments); state (authorizing or forbidding
     local caps or development referendums).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both slow growth. A cap or moratorium **tied to
     infrastructure capacity** ("until the sewer plant is expanded") is rung 2; a cap that holds
     growth down **whatever the capacity** is rung 1 [a] _(proposed)_.
   - A required vote on **annexation** is not a vote on "the largest projects" unless the passage
     ties it to a development _(proposed)_.

2. **"Allow growth only as fast as current infrastructure can handle — make new development wait for
   capacity."**
   - Means: new development proceeds only when roads, water, sewer and schools already have room for
     it.
   - Operative clauses: [a] growth limited to what current infrastructure can handle; [b] development
     waits for capacity.
   - Establishing evidence looks like: an adequate-facilities or concurrency rule that holds approvals
     until capacity exists; a capacity-based moratorium; own words that development must wait for
     infrastructure.
   - Levels that hold a lever: local; state (growth-management acts that require concurrency).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - Commonly confused with rung 3 because both talk about infrastructure. Rung 2 makes development
     **wait** for capacity; rung 3 **builds** capacity ahead so it does not wait.

3. **"Welcome steady growth — invest in roads, water and schools ahead of demand so expansion isn't
   held back."**
   - Means: plan for growth by building infrastructure before it is needed.
   - Operative clauses: [a] welcome steady growth; [b] invest in infrastructure **ahead of demand**.
   - Establishing evidence looks like: a capital plan, bond or budget that funds infrastructure for
     projected growth, with the passage stating it is built ahead of demand.
   - Levels that hold a lever: local; state (infrastructure funding).
   - Known chair-shaped instruments: _(none on file)_.
   - An infrastructure bond or road project alone does not show "ahead of demand": it may repair or
     catch up → `direction-only` _(proposed)_.
   - Commonly confused with rung 2: see rung 2.

4. **"Actively push for faster growth — cut red tape and recruit new development, while keeping basic
   guardrails."**
   - Means: government works to speed up growth by easing approvals and courting developers, but
     keeps core development rules.
   - Operative clauses: [a] cut red tape; [b] recruit new development; [c] keep basic guardrails.
   - Establishing evidence looks like: a streamlining measure (faster approvals, fewer reviews)
     **and** active recruitment of development, **plus** a passage that keeps standards in place.
     Compound: some clauses only → `compound-partial` (V4.2).
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because both cut rules. [c] separates them: rung 4 keeps
     guardrails, rung 5 keeps nothing beyond health and safety. A streamlining measure alone excludes
     neither → `direction-only` (V4).
   - Fee cuts (impact fees, permit fees) lower the cost of building; they are not "red tape" as such.
     Alone → `direction-only` _(proposed)_.

5. **"Step back and let the market set the pace — remove development constraints beyond basic health
   and safety."**
   - Means: government stops managing the pace of growth and keeps only health and safety rules.
   - Operative clauses: [a] the market sets the pace; [b] remove development constraints beyond basic
     health and safety.
   - Establishing evidence looks like: own words that only health and safety rules should remain; a
     record that removes the jurisdiction's development constraints **and** states that no other
     constraint should remain. [b] is a limit clause ("beyond basic health and safety"): the passage
     must say it (V4.2 "Silence is not a clause").
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **A state law that removes local development limits** (it voids local caps, review steps or
  approval rules statewide). This is **not** plain preemption: it removes the very limits rungs 4 and
  5 name, so it is `on-question`. But it is `direction-only`: one deregulation law cannot show that
  the person keeps guardrails (rung 4) or wants nothing beyond health and safety (rung 5) (codebook V2,
  "Refined 2026-09-26"). Do not code it `adjacent` as preemption, and do not code it rung 5 because
  it cuts rules.
- **Preemption that only moves the decision** (which level approves, with no limit removed) → V2
  `adjacent` (H12).
- **Density and housing-type rules** (what may be built on one lot) belong to `residential-zoning`
  and `housing`. Here they show pace only when the passage speaks to the pace of growth →
  otherwise `adjacent` _(proposed)_.
- **One project approval or denial** is routine and project-specific → `direction-only` at most.
- **Comprehensive plans and budget votes** → V4 `multi-subject`.


### topic_key: jail-capacity
topic_id: c267e137-0ff9-4e7d-9d13-e3cea1756cd0  served_revision_id: 7992fadf-a24c-4f73-bd34-76b5bca4764b
Question: How should government respond to jail overcrowding and criminal justice demand?
  1. Redirecting incarceration funding into community-based mental health, addiction, housing, and restorative justice programs to shrink the jail system
  2. Reducing the incarcerated population through alternatives to incarceration rather than building new capacity
  3. Upgrading jail facilities only as needed to meet constitutional standards, without expanding overall capacity
  4. Building additional jail capacity to address overcrowding and facility deficiencies
  5. Expanding jail capacity as the primary response to crime, prioritizing detention over alternatives

#### Annex

# jail-capacity — served revision 7992fadf-a24c-4f73-bd34-76b5bca4764b (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. The season pin is an older revision
(`f63a4e70-…`); coders code the served text below.

**Question:** "How should government respond to jail overcrowding and criminal justice demand?"

**Orientation:** standard. Rung 1 moves money out of incarceration to shrink the jail system, rung 5
expands jails as the main response to crime. The rungs order **the size of the jail system**: shrink
it, reduce its population, hold capacity, add capacity, make detention the primary tool.

**Levels with a lever:** local, state. Counties fund, build and run jails
(boards of supervisors or commissioners, sheriffs); states fund jail construction, set bail and
sentencing law, and run prisons. No federal officeholder holds a lever.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "jail", "detention center", "correctional facility", "beds" / "rated capacity",
"overcrowding", "consent decree", "conditions of confinement", "jail bond", "certificates of
participation", "pretrial services", "diversion", "bail reform", "electronic monitoring",
"mental-health court", "drug court", "restorative justice", "justice reinvestment", "care first".

1. **"Redirecting incarceration funding into community-based mental health, addiction, housing, and
   restorative justice programs to shrink the jail system"**
   - Means: take money away from jails and spend it on community programmes, so the jail system gets
     smaller.
   - Operative clauses: [a] redirect incarceration funding (money leaves jails or prisons);
     [b] into community-based programmes (mental health, addiction, housing, restorative justice);
     [c] to shrink the jail system.
   - Establishing evidence looks like: a budget amendment or motion that cuts jail or sheriff
     detention funding and moves it to such programmes; a jail closure plan that reinvests the money.
     New programme money with no cut to incarceration has no [a] → rung 2 territory _(proposed)_.
   - Levels that hold a lever: local (county budgets); state (prison and jail funding).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both reduce the jail population. Rung 1 needs money moved
     **out of** incarceration.
   - The four programme types name forms of [b]; one form is enough _(proposed)_.

2. **"Reducing the incarcerated population through alternatives to incarceration rather than building
   new capacity"**
   - Means: lower the number of people held by using alternatives, instead of building more space.
   - Operative clauses: [a] reduce the incarcerated population through alternatives; [b] rather than
     building new capacity.
   - Establishing evidence looks like: a diversion, pretrial-release, treatment-court or bail-reform
     measure **plus** evidence against new capacity (a No on a jail expansion, or own words). An
     alternatives programme alone does not exclude rungs 3 and 4 → `compound-partial` _(proposed)_.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - Bail reform, pretrial diversion and treatment alternatives are now all inside "alternatives to
     incarceration"; any one of them meets [a].

3. **"Upgrading jail facilities only as needed to meet constitutional standards, without expanding
   overall capacity"**
   - Means: fix jails so they meet constitutional standards, but do not add beds.
   - Operative clauses: [a] upgrade facilities only as needed for constitutional standards;
     [b] without expanding overall capacity.
   - Establishing evidence looks like: a renovation or replacement project tied to conditions
     (a consent decree, a court order, an inspection finding) whose bed count does not grow. Read
     the capacity numbers; [b] must be stated, not assumed (V4.2 "Silence is not a clause").
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a "replacement jail" can be larger than the old one. If
     the rated capacity grows → rung 4.

4. **"Building additional jail capacity to address overcrowding and facility deficiencies"**
   - Means: build more jail space to deal with overcrowding and poor facilities.
   - Operative clauses: [a] build additional capacity; [b] to address overcrowding and facility
     deficiencies.
   - Establishing evidence looks like: a vote for a jail expansion or a new, larger facility, justified
     by crowding or conditions. A capacity vote alone does not exclude rung 5 → `direction-only`,
     unless the same record or the person's words keep alternatives in place _(proposed)_.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3: see rung 3.
   - Commonly confused with rung 5 because both add beds. Rung 5 adds the claim that detention is the
     **primary** response to crime and comes **before** alternatives.

5. **"Expanding jail capacity as the primary response to crime, prioritizing detention over
   alternatives"**
   - Means: add jail space as the main answer to crime, and prefer detention to alternatives.
   - Operative clauses: [a] expand capacity; [b] as the primary response to crime; [c] detention
     over alternatives.
   - Establishing evidence looks like: a capacity expansion **plus** own words or records that rank
     detention ahead of alternatives (for example opposing diversion or pretrial release while
     funding beds).
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Enforcement is no longer part of this rung. More police or tougher sentences with no capacity
     clause do not reach rung 5 → `adjacent` _(proposed)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Prisons.** State prison capacity is on-question: the question names "criminal justice demand",
  rung 1 names incarceration funding, and prisons are the state's lever _(ruled 2026-10-01)_.
- **Bail and sentencing law** with no capacity or population clause → `adjacent`; the judicial
  topics order those rules _(proposed)_.
- **Jail health care, staffing and wages** improve operations without changing capacity → `adjacent`
  _(proposed)_.
- **Bonds and capital plans** are a record when the person votes on the specific project; a county
  budget that funds the whole sheriff's office → V4 `multi-subject`.
- **Feasibility studies and needs assessments** → V4 `study-directive`.


### topic_key: misinformation
topic_id: ddd65d64-9dc7-4208-a30f-59f4b9c0653d  served_revision_id: bd313c07-02a5-4344-8cc3-0e4b4c3b78a1
Question: What responsibility do platforms and government have in combating online misinformation?
  1. legally require platforms to remove false information
  2. require platforms to label false content, rather than remove it
  3. encourage voluntary standards for combating misinformation online
  4. protect free speech online and prevent government censorship
  5. ban any government involvement in content moderation decisions

#### Annex

# misinformation — served revision bd313c07-02a5-4344-8cc3-0e4b4c3b78a1 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris
Andrews). Lines marked _(proposed)_ are a drafter's reading, not yet ruled.

**Question:** "What responsibility do platforms and government have in combating online
misinformation?"

**Orientation:** standard. Rung 1 is the most legal compulsion on platforms (removal), rung 5 forbids
any government role. The rungs order **mechanisms** — require removal, require labels, encourage
voluntary standards, protect speech from government, ban government involvement.

**Levels with a lever:** federal, state.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "materially deceptive content", "deepfake", "synthetic media", "digital impersonation",
"digital replica", "large online platform", "content moderation", "terms of service", "trust and
safety", "provenance" or "watermark", "jawboning", "Section 230".

1. **"legally require platforms to remove false information"**
   - Means: the law makes platforms take false content down.
   - Operative clauses: [a] a legal duty; [b] on a platform; [c] to remove or block content because it
     is false or deceptive.
   - Establishing evidence looks like: operative text that requires a platform to remove or block a
     class of false or deceptive content; own words calling for such a duty.
   - Levels that hold a lever: federal, state.
   - Known chair-shaped instruments: a single-subject law that requires large platforms to remove
     deceptive election content.
   - Commonly confused with rung 2 because many bills mix the two duties: removal for one class of
     content, labels for the rest. The removal duty decides — rung 2 says "rather than remove it".
     A **narrow scope** (one category of content, an election window) does not change the mechanism
     the rungs order; the rung does not say "all" false information.
   - Content removed for a reason other than falsity (child abuse material, harassment,
     non-consensual intimate images) is not "false information" → `adjacent` _(proposed)_.

2. **"require platforms to label false content, rather than remove it"**
   - Means: the law makes platforms mark false content as false or synthetic, and stops short of
     removal.
   - Operative clauses: [a] a legal duty on a platform to label, flag or mark content as false or
     synthetic; [b] not removal.
   - Establishing evidence looks like: a labeling or provenance mandate on platforms **plus**
     something that excludes removal — the text says removal is not required, the person voted
     against a removal duty, or their own words prefer labels. A label-only law that is silent on
     removal does not exclude rung 1 → `direction-only` (V4.2 "Silence is not a clause") _(proposed)_.
   - Levels that hold a lever: federal, state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - Commonly confused with BLANK because a **transparency** mandate looks like a label. A law that
     makes platforms publish their moderation policies or report how they enforce them puts no label
     on any content and sets no moderation duty → `direction-only` at most. Algorithm transparency
     is not in this ladder → `adjacent` _(proposed)_.

3. **"encourage voluntary standards for combating misinformation online"**
   - Means: government promotes industry standards but does not require them.
   - Operative clauses: [a] government encourages — it convenes, recommends, endorses or funds; [b]
     the standards are voluntary, with no legal duty.
   - Establishing evidence looks like: a resolution or bill that adopts or endorses a voluntary code;
     own words preferring voluntary standards to mandates.
   - Levels that hold a lever: federal, state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with `study-directive` because a task force or report is not a standard. A bill
     that only orders a study → V4 `study-directive`.
   - Commonly confused with rung 2 because a disclosure **requirement** is not voluntary. See rung 2.

4. **"protect free speech online and prevent government censorship"**
   - Means: the law stops government from suppressing lawful online speech.
   - Operative clauses: [a] protect online speech; [b] against **government** action.
   - Establishing evidence looks like: a bill that bars officials from pressing platforms to remove
     lawful speech; a No on a removal mandate together with own words that name government
     censorship.
   - Levels that hold a lever: federal, state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because rung 5 bans **any** involvement — requests, partnerships,
     funding — not only coercion. A bar on coercion with exceptions (illegal content, security) is
     rung 4, not rung 5 _(proposed)_.

5. **"ban any government involvement in content moderation decisions"**
   - Means: government may play no part at all in what platforms allow or remove.
   - Operative clauses: [a] a prohibition; [b] on **any** government involvement; [c] in content
     moderation decisions.
   - Establishing evidence looks like: a bill or own words that forbid all government contact with
     platforms on moderation. "Any" is an absence of exceptions: the instrument must say it (V4.2
     "Silence is not a clause") _(proposed)_.
   - Levels that hold a lever: federal, state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **A duty on the speaker, not the platform.** A law that makes the creator or publisher of a deepfake
  disclose that it is fake, or makes them liable for it, puts no duty on platforms. One liability line
  for publishers in a law aimed at the creator does not make it a platform duty → `adjacent`, BLANK
  `no-evidence` when nothing else survives.
- **Political-ad disclaimers** for synthetic media, placed on the campaign or advertiser → `adjacent`.
- **Must-carry laws** that forbid platforms to remove users or viewpoints. Government regulates
  moderation, so it is not rung 5; rung 4 names government censorship, not platform moderation. The
  rungs order what is done about **false** content; a must-carry law is about a platform's power over
  lawful speech → V2 `adjacent`. Do not use such a vote "against rung 5" to seat rung 4: ruling out a
  rung is not evidence for another (V4.2) _(ruled 2026-10-01)_.
- **Section 230 changes** alter liability, not a duty to remove or label → `direction-only` at most,
  unless the change conditions immunity on removing false content _(proposed)_.
- **Government's own speech** (public information campaigns, media-literacy curricula) → `adjacent`.
- **Preemption (codebook V2, H12)** → `adjacent`.


### topic_key: rent-regulation
topic_id: c308e8e8-caac-44f5-ab04-dbfecf40bbe2  served_revision_id: 6fa44a68-8006-48e9-b562-6b5e61d58693
Question: What role should government play in regulating rents and protecting tenants?
  1. Expand rent control to cover all rental units communitywide
  2. Strengthen existing rent stabilization and extend coverage to more units
  3. Maintain current tenant protections while allowing market rents for new construction
  4. Limit rent regulations to subsidized units; allow market rents broadly
  5. Oppose rent control entirely; rents should be set by the market without government intervention

#### Annex

# rent-regulation — served revision 6fa44a68-8006-48e9-b562-6b5e61d58693 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "What role should government play in regulating rents and protecting tenants?"

**Orientation:** standard. Rung 1 puts every rental unit under rent control, rung 5 has no rent
control at all. The rungs order **how many units** a rent rule covers: all, more than now, the
current set, subsidized units only, none.

**Levels with a lever:** local, state. Cities and counties adopt rent rules
where state law permits; the state sets statewide caps and decides whether local rent control is
allowed at all.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "rent control", "rent stabilization", "rent cap", "anti-gouging cap", "annual
allowable increase", "vacancy control" / "vacancy decontrol", "just-cause eviction", "Costa-Hawkins"
(California's limits on local rent control), "rent board", "covered unit", "exempt unit".

1. **"Expand rent control to cover all rental units communitywide"**
   - Means: every rental unit in the community comes under rent control.
   - Operative clauses: [a] expand rent control; [b] to all rental units, communitywide.
   - Establishing evidence looks like: an ordinance or bill that brings every rental unit under a rent
     rule, or own words calling for universal coverage. [b] is an "all" clause, so the instrument
     must not exempt a class of units (V4.2).
   - Levels that hold a lever: local (where state law permits); state (statewide coverage).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because a **statewide** cap reads as "all units". A cap that
     exempts any class of units does not cover all units: it extends coverage → rung 2, not rung 1 (gold).
   - Strong tenant protections and just-cause eviction are no longer part of this rung. A
     just-cause law does not move a person to rung 1.

2. **"Strengthen existing rent stabilization and extend coverage to more units"**
   - Means: make the current rent rules stronger and bring more units under them, short of all units.
   - Operative clauses: [a] strengthen existing rent stabilization; [b] extend coverage to more units.
   - Establishing evidence looks like: a bill or ordinance that adds a cap where there was none, or
     brings new classes of units under an existing cap, with exemptions that keep it short of all
     units. A single-subject statewide cap with exemptions → rung 2 (gold).
   - Levels that hold a lever: state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - Commonly confused with rung 3 because a cap that **exempts new construction** matches rung 3's
     "market rents for new construction". Rung 3 **maintains** current protections; a cap that
     covers units that were not covered before **extends** them → rung 2 (gold).
   - [a] and [b] read as one direction: more stabilization, short of all units. A measure that
     extends coverage meets the rung without a separate "strengthen" clause (gold). A measure that
     only tightens the cap on units already covered → rung 2 too _(proposed)_.

3. **"Maintain current tenant protections while allowing market rents for new construction"**
   - Means: keep the rent rules and tenant protections that exist now, and let new buildings rent at
     market rates.
   - Operative clauses: [a] maintain current protections (no expansion, no repeal); [b] market rents
     for new construction.
   - Establishing evidence looks like: a No on an expansion **plus** a No on a repeal, or own words
     for both. A vote for a new-construction exemption alone → `compound-partial` _(proposed)_.
   - Levels that hold a lever: state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2: see rung 2.

4. **"Limit rent regulations to subsidized units; allow market rents broadly"**
   - Means: only units that receive public subsidy have rent limits; all other units rent at market
     rates.
   - Operative clauses: [a] rent rules only on subsidized units; [b] market rents for everything else.
   - Establishing evidence looks like: a repeal or phase-out of rent rules on private, unsubsidized
     units that keeps the affordability terms of subsidized units, or own words saying so.
   - Levels that hold a lever: state (statewide repeal or preemption); local (repeal of a local
     ordinance).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because both allow market rents broadly. Rung 4 keeps rules on
     subsidized units; rung 5 keeps none.

5. **"Oppose rent control entirely; rents should be set by the market without government
   intervention"**
   - Means: no rent control of any kind; the market sets every rent.
   - Operative clauses: [a] oppose rent control entirely; [b] no government intervention in rents.
   - Establishing evidence looks like: own words against all rent control, or a repeal of every rent
     rule. A No on one rent bill is `direction-only`: it does not separate 3, 4 and 5 (gold).
   - Levels that hold a lever: state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **A No vote** on a rent bill rules out the stronger rungs but names no chair → BLANK
  `direction-only` (gold). The same is true of a No on a repeal.
- **Preemption (codebook V2, H12).** A state law that forbids local rent control, or its repeal,
  decides which level may act, not how many units are covered → `adjacent`. Repealing a state ban
  on local rent control lets cities act but extends no rule to any unit → `adjacent` _(ruled 2026-10-01)_.
- **Tenant protections with no rent rule** (just-cause eviction, relocation payments, habitability,
  right to counsel) are on the question's wording but do not order coverage → `direction-only`
  _(proposed)_.
- **Temporary emergency caps** (an emergency order, an eviction moratorium) → `direction-only`.
  Read the dates: a cap with a far sunset is a standing rule; code it on coverage _(proposed)_.
- **Studies and rent-board reports** → V4 `study-directive`.
- **Budget and omnibus votes** with a rent item → V4 `multi-subject`.


### topic_key: social-security
topic_id: 87d20824-a6e9-407b-983c-65440084a0ab  served_revision_id: 8defc029-0b7e-426f-b838-a2e170f566c9
Question: How should Social Security be funded and structured for the future?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. expand Social Security benefits significantly and remove the income cap on payroll taxes to fund it.
  2. increase Social Security benefits modestly while raising taxes on higher earners to strengthen the program.
  3. make small adjustments to both benefits and taxes to keep Social Security stable for future generations.
  4. gradually reduce future benefits rather than raise taxes to keep Social Security solvent.
  5. transition Social Security to private investment accounts that individuals control themselves.

#### Annex

# social-security — served revision 8defc029-0b7e-426f-b838-a2e170f566c9 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should Social Security be funded and structured for the future?"

**Orientation:** standard. Rung 1 is the largest public programme (bigger benefits, more tax), rung 5
replaces it with private accounts. The rungs order **benefit level and how it is paid for**. Rungs
1–4 each pair a benefit side with a tax side, so most of them are compound.

**Levels with a lever:** federal. Only Congress sets benefits and the payroll
tax. State and local officeholders hold no lever on any rung.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "OASDI", "trust fund", "solvency", "payroll tax", "FICA", "taxable maximum" or "wage
base cap", "donut hole", "full retirement age", "COLA", "CPI-E", "chained CPI", "progressive price
indexing", "minimum benefit", "WEP" and "GPO" (Windfall Elimination Provision, Government Pension
Offset), "personal accounts", "carve-out accounts", "fiscal commission".

1. **"expand Social Security benefits significantly and remove the income cap on payroll taxes to
   fund it."**
   - Means: benefits rise a lot for beneficiaries in general, paid for by taxing all earnings.
   - Operative clauses: [a] a significant benefit increase; [b] remove the payroll-tax cap; [c] the
     tax pays for the increase. Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: authoring or co-sponsoring a single-subject bill that raises
     benefits broadly (an across-the-board increase, a higher COLA formula) **and** applies the
     payroll tax to earnings above the present cap.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A "donut hole" design (tax again above a threshold, with a gap below it) meets [b] "remove the
     income cap": no upper limit remains. The **size of the benefit increase** then separates rung 1
     from rung 2 _(ruled 2026-10-01)_.
   - Commonly confused with rung 2 because both raise taxes on higher earners. When the tax side does
     not separate them, the **size** of the benefit increase does: across-the-board → rung 1
     territory; one group or a small amount → rung 2 territory _(proposed)_.

2. **"increase Social Security benefits modestly while raising taxes on higher earners to strengthen
   the program."**
   - Means: a small benefit increase, paid for by more tax on high earners.
   - Operative clauses: [a] a modest benefit increase; [b] raise taxes on higher earners. Compound:
     one side only → `compound-partial`.
   - Establishing evidence looks like: a bill or own words with both a limited increase (a minimum
     benefit, a targeted increase) and a tax rise aimed at high earners.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - **[real] (codebook V6, H5).** Co-sponsoring the Social Security Fairness Act (WEP/GPO repeal, a
     benefit increase for one group, no tax side) plus "must be willing to reform" → BLANK
     `compound-partial`.

3. **"make small adjustments to both benefits and taxes to keep Social Security stable for future
   generations."**
   - Means: small changes on both sides, without a large cut or a large tax rise.
   - Operative clauses: [a] a small benefit adjustment; [b] a small tax adjustment. Compound (V4.2
     names this rung): one side only → `compound-partial`.
   - Establishing evidence looks like: a solvency bill or own words that name a change on each side
     (a small retirement-age or COLA change **and** a small payroll-tax or wage-base change).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a benefit-side change (raise the retirement age) is in
     both. Rung 3 needs a tax side; rung 4 needs the tax side **rejected**. A benefit change plus
     openness to a tax change → rung 3 territory; a benefit change alone → `compound-partial` for
     both _(proposed)_.

4. **"gradually reduce future benefits rather than raise taxes to keep Social Security solvent."**
   - Means: future benefits grow less or are cut over time, and taxes are not raised.
   - Operative clauses: [a] gradually reduce future benefits (a higher retirement age, chained CPI,
     price indexing, means-testing all count); [b] **rather than** raise taxes — the person rejects a
     tax rise for solvency. [b] must be stated (V4.2 "Silence is not a clause"). Compound: [a] only →
     `compound-partial`.
   - Establishing evidence looks like: a benefit-side solvency plan **plus** the person's own words or
     record against a tax rise.
   - A signed no-new-taxes pledge is `statement-answer` (codebook V3, H8) and can meet [b], in cycle
     (V5) _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - S1 rung 4 was "raise the retirement age **and** reduce benefits for higher earners". The served
     rung adds [b] and drops the named mechanisms. S1 evidence on the retirement age alone now meets
     [a] only.
   - **[real] (codebook V6, H5).** A voter-guide answer for "gradually raising the retirement age" and
     a later "everything's on the table" (`rhetorical`) → [a] only, [b] unmet → BLANK
     `compound-partial`.

5. **"transition Social Security to private investment accounts that individuals control
   themselves."**
   - Means: the programme moves to accounts that each person owns and invests.
   - Operative clauses: [a] a transition of the programme to private accounts; [b] individual control.
   - Establishing evidence looks like: a bill or own words that move payroll-tax contributions into
     individually owned investment accounts in place of the benefit.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A voluntary carve-out of a small part of the payroll tax is a step, not a transition →
     `direction-only` _(proposed)_. Accounts **added** on top of Social Security (funded outside the
     payroll tax) → `adjacent` _(proposed)_.

**Hard cases:**
- **"Protect Social Security", "no cuts", "keep our promise"** exclude rungs 4 and 5 only →
  `direction-only`.
- **A fiscal or trust-fund commission bill** orders a report → V4 `study-directive`.
- **Income tax on benefits** (exempt benefits from income tax, a senior deduction) is not the payroll
  tax and not a benefit level → `adjacent` _(proposed)_.
- **Budget resolutions** that assume Social Security changes → V4 `multi-subject` _(proposed)_.
- **SSA administration** (field offices, staffing, phone wait times) → `adjacent`.
- **Ratings from seniors' groups** → V3 `not-evidence`; follow them to the roll calls.


### topic_key: ukraine-support
topic_id: 24e9212c-b011-422a-865c-093e35050901  served_revision_id: 9ee7ecb7-fd99-429a-a37d-eff58a381983
Question: What level of military and financial support should be provided to Ukraine?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


### topic_key: 2020-election
topic_id: b5260e5a-5576-4071-8b2a-088af8d1f9eb  served_revision_id: 81920cf6-9a30-4c5c-82b1-5f2c16cda95c
Question: What is your view of the outcome of the 2020 presidential election?
  1. The election was fair and Joe Biden won legitimately.
  2. Joe Biden won, but the election had real problems worth fixing.
  3. There was some fraud, but not enough to change the result.
  4. Fraud or irregularities may have been enough to change the result.
  5. The election was stolen from Donald Trump through widespread fraud.

#### Annex

# 2020-election — served revision 81920cf6-9a30-4c5c-82b1-5f2c16cda95c (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. No gold item exists on this topic
yet; every reading below is a drafter's.

**Question:** "What is your view of the outcome of the 2020 presidential election?"

**Orientation:** off-axis — a **belief** ladder, not a government-action ladder. Rung 1 accepts the
certified result without reservation, rung 5 says it was stolen. The rungs order **how far the
person doubts the certified result**. No rung asks what government should do.

**Levels with a lever:** federal, local, state, in the sense that records count at each level. No
officeholder can change a past event; the evidence is mostly own words. Records exist too: objections to electoral votes
(Congress), audit, decertification or elector resolutions (state), certification votes (local
election boards).

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "certification", "certify" or "decertify", "electoral count", "objection",
"Electoral Count Act", "alternate electors", "forensic audit", "irregularities", "rigged",
"stolen", "election integrity", "legitimate", "the will of the voters".

1. **"The election was fair and Joe Biden won legitimately."**
   - Means: the 2020 election was fair, and its winner won legitimately.
   - Operative clauses: [a] the election was fair; [b] Biden won legitimately.
   - Establishing evidence looks like: own words that say both. A vote to certify, or against an
     objection, shows acceptance of the result but does not separate rungs 1, 2 and 3 →
     `direction-only` _(proposed)_.
   - Levels that hold a lever: none; own words at every level.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 when the person also backs election-security changes. A call to
     improve future elections is not a statement that 2020 "had real problems" → it does not move
     the person to rung 2 _(proposed)_.

2. **"Joe Biden won, but the election had real problems worth fixing."**
   - Means: the result stands, but the 2020 election had real faults that need correcting.
   - Operative clauses: [a] Biden won; [b] the 2020 election had real problems worth fixing.
   - Establishing evidence looks like: own words that accept the result **and** name problems in the
     2020 election. Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: none; own words at every level.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because "problems" can mean fraud. Rung 2's problems are faults
     (administration, rule changes, delays); a person who says fraud occurred is rung 3 or above.

3. **"There was some fraud, but not enough to change the result."**
   - Means: some fraud happened in 2020, but the result would have been the same.
   - Operative clauses: [a] some fraud occurred; [b] not enough to change the result.
   - Establishing evidence looks like: own words that say both. Compound: one side only →
     `compound-partial` (V4.2).
   - Levels that hold a lever: none; own words at every level.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 when the person says fraud occurred and does not say whether it
     changed the result. That is [a] only → `compound-partial`, not rung 4.

4. **"Fraud or irregularities may have been enough to change the result."**
   - Means: the person is unsure whether the result was right, because fraud or irregularities may
     have changed it.
   - Operative clauses: [a] fraud or irregularities; [b] possibly enough to change the result.
   - Establishing evidence looks like: own words that the outcome is in doubt because of fraud or
     irregularities.
   - Levels that hold a lever: none; own words. Records: see hard cases.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because "may have" and "was" are close. Rung 5 is certainty; doubt
     is rung 4.

5. **"The election was stolen from Donald Trump through widespread fraud."**
   - Means: the person says the election was taken from its rightful winner by widespread fraud.
   - Operative clauses: [a] the election was stolen (the result is wrong); [b] through widespread
     fraud.
   - Establishing evidence looks like: own words that say the election was stolen, or that Trump
     won, by fraud.
   - Levels that hold a lever: none; own words. Records: see hard cases.
   - Known chair-shaped instruments: _(none on file)_.
   - "Stolen" or "rigged" with no mechanism named → `compound-partial`: it meets [a] but not [b]
     "through widespread fraud" (H14) _(ruled 2026-10-01)_.
   - A claim that it was stolen by something other than fraud (rule changes, media, courts) meets [a]
     but not [b] → `compound-partial` _(proposed)_.

**Hard cases:**
- **Objections and electoral-count votes.** A vote to object to a state's electoral votes shows doubt
  about that count. It does not separate rung 4 from rung 5, and an objection can rest on rule
  changes rather than fraud → `direction-only`, unless the person's own explanation of the vote places it
  _(proposed)_.
- **Lawsuits and amicus briefs** (Q8 `record`): the legal claim must match the rung. A claim that
  states changed election rules unlawfully is not a claim of fraud → `direction-only` at most
  _(proposed)_.
- **Audit and certification votes.** A vote for an audit, or against certifying, shows doubt but names
  no conclusion → `direction-only` _(proposed)_.
- **Dodges.** "I'm focused on the future", "Biden is the president", "that's been litigated" do not
  state a view of the outcome → V4 `rhetorical`; BLANK `no-evidence` if nothing else survives. A
  blank here is correct.
- **Time (V5).** A person's view may have changed since 2020. The newest evidence governs; older
  passages are `superseded-by-later`. A statement outside the election cycle goes to review.


### topic_key: border-security
topic_id: 407614a8-ba2c-4145-8224-233655e6ac3f  served_revision_id: 76d9941b-3085-42cf-b229-ac41f4f85b8d
Question: How should the government handle people who cross the border?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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

**Levels with a lever:** federal. Asylum law, border enforcement and the
immigration courts are federal. State border measures (state troops, barriers, state crossing
crimes) do not decide who may claim asylum or how claims are heard; a state or local officeholder's
position on these rungs can be shown only by their own words.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

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


### topic_key: cannabis-policy
topic_id: 2d893b95-9365-48f3-b7d6-1d0db8216518  served_revision_id: 0d9ff53d-0eb1-43a4-80f6-daaaf9851524
Question: How should the government regulate cannabis?
  1. Keep cannabis fully illegal and enforce criminal penalties for possessing or selling it.
  2. Allow cannabis only for medical use, available to patients with a physician's authorization.
  3. Remove criminal penalties for personal possession, replacing them with civil fines, but keep commercial sales illegal.
  4. Legalize recreational cannabis and regulate it through a licensed, taxed commercial market.
  5. Legalize cannabis and treat it like an ordinary legal product, with minimal restrictions on growing and using it.

#### Annex

# cannabis-policy — served revision 0d9ff53d-0eb1-43a4-80f6-daaaf9851524 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should the government regulate cannabis?"

**Orientation:** standard. Rung 1 is the most restriction (fully illegal, criminal penalties), rung 5
the least (an ordinary legal product). The rungs order **what is legal**: nothing, medical use,
possession without a crime, a licensed adult market, an open market.

**Levels with a lever:** federal, local, state. The lever is state law (and
ballot measures), with federal scheduling above it. Local governments decide where licensed
businesses may operate and how police treat possession.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "marijuana", "marihuana", "THC", "CBD", "hemp", "Schedule I" / "Schedule III",
"rescheduling", "descheduling", "decriminalization", "civil infraction", "adult use", "recreational",
"medical marijuana", "qualifying condition", "dispensary", "home grow", "excise tax", "expungement",
"opt-out".

1. **"Keep cannabis fully illegal and enforce criminal penalties for possessing or selling it."**
   - Means: no legal use, medical included, and possession and sale stay crimes.
   - Operative clauses: [a] fully illegal, medical use included; [b] criminal penalties for possession
     and sale, enforced.
   - Establishing evidence looks like: a No on a medical-cannabis law **plus** a vote or own words
     that keep criminal penalties for possession. A No on adult-use legalization alone excludes rungs
     4–5 only → `direction-only`.
   - Levels that hold a lever: federal; state; local (enforcement priorities).
   - Known chair-shaped instruments: _(none on file)_.

2. **"Allow cannabis only for medical use, available to patients with a physician's authorization."**
   - Means: patients with a physician's authorization may use cannabis; no one else may.
   - Operative clauses: [a] medical use allowed with a physician's authorization; [b] "only" — no
     adult use.
   - Establishing evidence looks like: authoring or a final-passage vote on a medical-cannabis law
     **plus** something that excludes rungs 3–5 (a No on decriminalization or adult use, own words).
     A medical law alone → `direction-only` (V4: chair-shaped must exclude the adjacent rungs).
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A **CBD-only or low-THC** law is narrower than medical cannabis → `direction-only` _(proposed)_.

3. **"Remove criminal penalties for personal possession, replacing them with civil fines, but keep
   commercial sales illegal."**
   - Means: possession for personal use is a civil fine, not a crime; selling stays illegal.
   - Operative clauses: [a] no criminal penalty for personal possession; [b] a civil fine instead;
     [c] commercial sales stay illegal.
   - Establishing evidence looks like: a decriminalization law with civil fines **plus** evidence
     that the person opposes legal sales. [c] separates this rung from rung 4, and silence on sales
     does not meet it (V4.2). Compound: some clauses only → `compound-partial`.
   - Levels that hold a lever: state; local (lowest-priority policing, local fines where allowed).
   - Known chair-shaped instruments: _(none on file)_.
   - A decriminalization law whose own text keeps sale a crime meets [c] for the instrument; it
     still shows only what the person voted for, not that they oppose a legal market _(proposed)_.

4. **"Legalize recreational cannabis and regulate it through a licensed, taxed commercial market."**
   - Means: adults may buy cannabis legally from licensed businesses that are taxed and regulated.
   - Operative clauses: [a] legalize adult use; [b] a licensed commercial market; [c] taxed.
   - Establishing evidence looks like: authoring or a final-passage vote on an adult-use law that
     sets up licensing and a tax; own words for the same.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because many adult-use laws allow **home grow** of a few plants.
     A licensed, taxed market with home grow is still rung 4 _(proposed)_.

5. **"Legalize cannabis and treat it like an ordinary legal product, with minimal restrictions on
   growing and using it."**
   - Means: cannabis is legal, like any ordinary product, with few limits on growing or using it.
   - Operative clauses: [a] legalize; [b] treat it as an ordinary product; [c] minimal restrictions on
     growing and use.
   - Establishing evidence looks like: own words or an instrument that removes cannabis-specific
     licensing and limits. "Minimal restrictions" must be stated, not inferred from a legalization
     vote (V4.2).
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Federal descheduling or "states decide" bills** that remove the federal ban and leave the rule to
  the states decide which level acts → `adjacent` (V2, H12), unless the bill also sets a federal
  market rule _(proposed)_.
- **Rescheduling** (Schedule I to Schedule III) changes medical research and tax rules; it keeps
  adult use illegal → `direction-only` _(proposed)_.
- **Banking access** for state-legal businesses does not say what should be legal → `adjacent`
  _(proposed)_.
- **Local opt-outs and dispensary zoning** decide where licensed businesses operate, not whether
  cannabis is legal → `adjacent` _(proposed)_.
- **Expungement** of past convictions is consistent with rungs 3–5 → `direction-only` _(proposed)_.
- **Hemp-derived THC products** (delta-8 and similar) → `adjacent` unless the passage speaks to
  cannabis itself _(proposed)_.
- **Budget votes** with a cannabis rider → V4 `multi-subject`.


### topic_key: defense-spending
topic_id: 3fd1aa81-e032-4335-8785-452ed10ce9ce  served_revision_id: 5b75a7a2-1a72-436f-be9a-e60cf9ffada5
Question: How much should the government spend on the military?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Increase military spending substantially, launching a major buildup to expand the armed forces and their capabilities.
  2. Increase military spending moderately, growing the budget above inflation to keep pace with rising threats.
  3. Hold military spending roughly flat, allowing it to rise only with inflation.
  4. Reduce military spending modestly below current levels.
  5. Cut military spending dramatically, roughly halving the budget or more.

#### Annex

# defense-spending — served revision 5b75a7a2-1a72-436f-be9a-e60cf9ffada5 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How much should the government spend on the military?"

**Orientation:** standard. Rung 1 is the largest budget (a major buildup), rung 5 the deepest cut
(about half or more). The rungs order **the size of the military budget measured against
inflation**. How the money is spent, and where forces are based, are not on this ladder.

**Levels with a lever:** federal. Congress sets the budget through the annual
defense authorization and defense appropriations bills, budget resolutions and spending caps.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "national defense" (budget function 050), "topline", "base budget", "NDAA" (National
Defense Authorization Act), "defense appropriations", "budget request", "real growth",
"inflation-adjusted", "constant dollars", "percent of GDP", "spending caps", "sequestration",
"continuing resolution", "readiness", "procurement", "end strength", "force structure".

1. **"Increase military spending substantially, launching a major buildup to expand the armed forces
   and their capabilities."**
   - Means: a large real increase that grows the size and capability of the forces.
   - Operative clauses: [a] a substantial increase; [b] a major buildup that expands the forces and
     their capabilities.
   - Establishing evidence looks like: own words that call for a large increase (for example a much
     larger share of GDP) **and** for more forces or capabilities; an amendment that adds a large sum
     above the request for that purpose.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both increase. "Substantial" and "major buildup" separate
     them; an increase the passage does not size → `direction-only` _(proposed)_.

2. **"Increase military spending moderately, growing the budget above inflation to keep pace with
   rising threats."**
   - Means: steady real growth, above inflation but short of a buildup.
   - Operative clauses: [a] a moderate increase; [b] above inflation.
   - Establishing evidence looks like: own words that call for real growth (for example "3 to 5
     percent above inflation"), or an instrument whose topline the passage itself compares with
     inflation. Clause [b] needs that comparison in the snapshot; the coder does not supply an
     inflation figure _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a **nominal** increase can be flat or a cut in real terms.
     Without the comparison → `direction-only` _(proposed)_.

3. **"Hold military spending roughly flat, allowing it to rise only with inflation."**
   - Means: keep the budget the same in real terms.
   - Operative clauses: [a] roughly flat; [b] rising only with inflation.
   - Establishing evidence looks like: own words for a freeze in real terms; a single-subject cap that
     limits defense growth to inflation.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A spending cap inside a debt-limit or budget deal that also caps other spending → V4
     `multi-subject`.

4. **"Reduce military spending modestly below current levels."**
   - Means: a small cut from what is spent now.
   - Operative clauses: [a] reduce; [b] modestly (a small share, for example around a tenth
     _(proposed)_).
   - Establishing evidence looks like: sponsorship of an amendment that cuts the topline by a modest
     share — sponsorship sets the amount (V4.1) _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because a **Yea** on a modest cut does not show the voter wants no
     deeper cut. Voting for it without own words → `direction-only` _(proposed)_.

5. **"Cut military spending dramatically, roughly halving the budget or more."**
   - Means: cut the budget by about half or more.
   - Operative clauses: [a] a dramatic cut; [b] about half or more.
   - Establishing evidence looks like: own words or an instrument that names a cut of about half or
     more. "Slash the Pentagon budget" with no size → `direction-only` _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **The annual defense authorization and defense appropriations bills.** Final passage →
  `multi-subject` _(ruled 2026-10-01)_. A **No** proves nothing (V4.1), and a Yea that the passage does not compare
  with inflation cannot separate rungs 2 and 3.
- **Topline amendments** (add or cut a stated sum or share) are the amendment row of the vote ladder
  (V4.1) and can carry a chair, but only when the size of the change maps to a rung's size
  ("substantially", "moderately above inflation", "roughly flat", "modestly below", "roughly
  halving") _(ruled 2026-10-01)_.
- **Composition is not size.** Moving money inside the budget (cancel one programme, fund another),
  pay raises, base closures, or an audit of the department → `adjacent` _(proposed)_.
- **Force posture** (where troops are based, whether to intervene) is the `military-intervention`
  question → `adjacent`. Aid to another country is `ukraine-support` or `israel-military-aid`.
- **Veterans' benefits** are not military spending on this ladder → `adjacent` _(proposed)_.
- **Reconciliation, omnibus and continuing-resolution votes** with a defense item → V4
  `multi-subject`. A continuing resolution that holds spending at last year's level is not own
  evidence for rung 3 _(proposed)_.


### topic_key: military-intervention
topic_id: 710396dc-e618-4011-8118-43c62a786111  served_revision_id: c42b12b6-d7c3-4b88-a932-06b87d5043c9
Question: How should the United States use military force abroad?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Use US military power to actively lead and police conflicts around the world.
  2. Intervene militarily when clear US interests or allied nations are directly threatened.
  3. Prefer diplomacy and economic sanctions, using military force only as a last resort.
  4. Avoid overseas military action except to defend US territory from direct attack.
  5. Withdraw from overseas military commitments and end foreign military intervention.

#### Annex

# military-intervention — served revision c42b12b6-d7c3-4b88-a932-06b87d5043c9 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should the United States use military force abroad?"

**Orientation:** standard. Rung 1 is the most use of force (lead and police conflicts worldwide),
rung 5 the least (withdraw from overseas commitments). The rungs order **the conditions under which
force is used abroad**, and at rung 5, whether the overseas footprint stays.

**Levels with a lever:** federal. Congress declares war, authorizes force,
funds deployments and can direct the removal of forces; state and local officials hold no lever.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "War Powers Resolution", "authorization for use of military force" (AUMF),
"declaration of war", "hostilities", "deployment", "troop withdrawal", "forward presence",
"overseas bases", "collective defense", "NATO Article 5", "treaty commitments", "deterrence",
"strike", "regime change", "sanctions", "restraint", "global leadership".

1. **"Use US military power to actively lead and police conflicts around the world."**
   - Means: the United States uses force to shape and settle conflicts worldwide, not only where its
     own interests are threatened.
   - Operative clauses: [a] actively lead and police conflicts; [b] around the world.
   - Establishing evidence looks like: own words that the United States should act militarily in
     conflicts generally, as a world role.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because support for **one** strike or deployment reads like a world
     role. One use of force does not state a general rule → `direction-only` _(proposed)_.

2. **"Intervene militarily when clear US interests or allied nations are directly threatened."**
   - Means: force is used when U.S. interests or allies face a direct threat, and not otherwise.
   - Operative clauses: [a] intervene militarily; [b] when clear U.S. interests or allies are directly
     threatened.
   - Establishing evidence looks like: own words that state that condition as the test; a Yea on an
     authorization of force against a named direct threat **plus** words that tie it to the threat
     _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because rung 3 also allows force. Rung 3 tries diplomacy and
     sanctions first; rung 2 acts when the threat is direct. A passage that does not say which comes
     first → `direction-only` _(proposed)_.

3. **"Prefer diplomacy and economic sanctions, using military force only as a last resort."**
   - Means: diplomacy and sanctions come first; force only when they have failed.
   - Operative clauses: [a] prefer diplomacy and sanctions; [b] force only as a last resort.
   - Establishing evidence looks like: own words that state both. Compound: one side only →
     `compound-partial` (V4.2).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A **sanctions bill** shows [a] at most; it is silent on force → `compound-partial` _(proposed)_.

4. **"Avoid overseas military action except to defend US territory from direct attack."**
   - Means: no military action abroad unless U.S. territory is attacked directly; defending allies is
     not an exception.
   - Operative clauses: [a] avoid overseas military action; [b] except to defend U.S. territory from
     direct attack.
   - Establishing evidence looks like: own words that limit force to defense of U.S. territory.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because both oppose intervention. Rung 4 keeps the overseas
     footprint and does not use it; rung 5 pulls it back. A passage against one intervention that is
     silent on bases and commitments → `direction-only` _(proposed)_.

5. **"Withdraw from overseas military commitments and end foreign military intervention."**
   - Means: bring forces home, leave military commitments abroad, and stop intervening.
   - Operative clauses: [a] withdraw from overseas commitments (bases, deployments, alliances); [b]
     end foreign military intervention.
   - Establishing evidence looks like: own words or an instrument that withdraws from commitments
     generally. A bill to withdraw troops from **one** country meets [a] for that country only →
     `direction-only` _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **War Powers votes.** A resolution that directs the removal of forces from named hostilities is
  against **that** use of force; it does not state the general rule the rungs differ on →
  `direction-only` at most. A War Powers or authorization vote framed only as **who decides**
  (Congress or the President) → `adjacent` _(ruled 2026-10-01)_.
- **Authorizations of force** (AUMF) for one conflict → `direction-only`; a repeal of an old
  authorization that is no longer used → `adjacent` _(proposed)_.
- **Military aid and arms sales** are the `ukraine-support` and `israel-military-aid` questions;
  **the size of the budget** is `defense-spending` → `adjacent`.
- **The defense authorization bill** and other omnibus votes → V4 `multi-subject`.
- **Statements about one strike** ("the strike was right", "the strike was wrong") → `direction-only`
  unless the passage states the rule behind it _(proposed)_.


### topic_key: israel-military-aid
topic_id: 6783e65c-0722-45d9-8579-65327af7c15c  served_revision_id: a9e300f1-8d13-4e34-89f0-e321031676b2
Question: What level of military aid should the U.S. provide to Israel?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Continue full military aid to Israel with no new conditions.
  2. Continue aid to Israel, but require it to comply with humanitarian and human-rights law.
  3. Block offensive weapons sales while continuing defensive support such as missile defense.
  4. Sharply cut military aid to Israel as a step toward ending it.
  5. End all military aid to Israel.

#### Annex

# israel-military-aid — served revision a9e300f1-8d13-4e34-89f0-e321031676b2 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "What level of military aid should the U.S. provide to Israel?"

**Orientation:** standard. Rung 1 is the most support (full aid, no new conditions), rung 5 ends all
military aid. It reads in the same direction as `ukraine-support`. The rungs order **how much
military aid continues and on what terms**: unconditioned, conditioned, defensive only, cut, ended.

**Levels with a lever:** federal. Congress appropriates the aid and can block
arms sales by joint resolution; state and local officials hold no lever. State divestment and
boycott laws are a different question (see hard cases).

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "Foreign Military Financing" (FMF), "memorandum of understanding" (MOU), "security
assistance", "arms sales", "joint resolution of disapproval" (JRD), "Arms Export Control Act",
"Leahy law", "conditions", "end-use monitoring", "offensive weapons", "Iron Dome", "David's Sling",
"missile defense", "cooperative programs", "supplemental".

1. **"Continue full military aid to Israel with no new conditions."**
   - Means: keep all military aid at its full level, and add no conditions to it.
   - Operative clauses: [a] continue full military aid; [b] no new conditions.
   - Establishing evidence looks like: a Yea on military aid **plus** a No on a conditioning amendment,
     or own words that reject conditions. [b] is an absence clause: a Yea on aid alone does not show
     the person rejects conditions → `direction-only` (V4.2) _(proposed)_.
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A No on a resolution that blocks one arms sale excludes rung 3 and below; it does not exclude
     rung 2 _(proposed)_.

2. **"Continue aid to Israel, but require it to comply with humanitarian and human-rights law."**
   - Means: aid continues, with a legal condition on how it is used.
   - Operative clauses: [a] continue aid; [b] require compliance with humanitarian and human-rights
     law.
   - Establishing evidence looks like: sponsorship of, or a Yea on, an amendment that conditions aid
     on compliance, **plus** something that shows the person continues aid (a Yea on the aid, own
     words). Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - A **reporting** requirement (a report on how aid is used) is not a compliance condition →
     `study-directive` _(proposed)_.

3. **"Block offensive weapons sales while continuing defensive support such as missile defense."**
   - Means: stop sales of offensive weapons; keep defensive support.
   - Operative clauses: [a] block offensive weapons sales; [b] continue defensive support.
   - Establishing evidence looks like: a Yea on resolutions that block sales of offensive weapons
     (bombs, munitions for attack) **plus** support for defensive aid (a Yea on missile-defense money,
     or a carve-out for air defense in the same instrument). Compound: one side only →
     `compound-partial` (V4.2).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because blocking one sale can be a way to enforce conditions. The
     instrument decides: a block on a weapon type → [a]; a condition on use → rung 2 _(proposed)_.

4. **"Sharply cut military aid to Israel as a step toward ending it."**
   - Means: cut aid by a large amount now, with ending it as the goal.
   - Operative clauses: [a] a sharp cut; [b] as a step toward ending aid.
   - Establishing evidence looks like: own words that call for a large cut on the way to zero; an
     amendment that strips a large share of the aid, plus own words for [b].
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because a Yea on stripping one aid account (for example a year's
     FMF) does not show whether the person would keep missile defense or end everything →
     `direction-only` without own words _(proposed)_.

5. **"End all military aid to Israel."**
   - Means: no military aid of any kind, missile defense included.
   - Operative clauses: [a] end all military aid.
   - Establishing evidence looks like: own words or an instrument that ends all military aid. "All"
     is an absence clause: a cut that leaves defensive programmes is not rung 5 (V4.2).
   - Levels that hold a lever: federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Supplementals.** A Yea on an Israel aid supplemental shows continued aid; it does not separate
  rungs 1 and 2 → `direction-only`. If the supplemental also funds aid elsewhere → V4
  `multi-subject`.
- **Humanitarian aid for civilians** in the region is not military aid → `adjacent`.
- **State divestment and anti-boycott laws** are a state lever on a different question → `adjacent`.
- **Resolutions** that state support for Israel or condemn an attack name no aid level → V4
  `rhetorical`.
- **Appropriations bills and the defense authorization bill** that carry Israel aid → V4
  `multi-subject`; an amendment on the Israel item is the amendment row of the vote ladder (V4.1).


### topic_key: minimum-wage
topic_id: 43d9e981-f25e-471f-ae92-b8e2a700900c  served_revision_id: bc949d3b-43f4-4612-ba4c-2de39f8757c8
Question: What approach should government take to the minimum wage?
  1. Raise the wage floor and tie it to the cost of living, so it rises automatically each year without new legislation.
  2. Raise the wage floor to a set higher level, then adjust it only when lawmakers vote to.
  3. Keep a modest national wage floor as a baseline and let states and cities set higher rates.
  4. Hold the wage floor at its current level and let the market set pay above it.
  5. Remove the wage floor entirely and let employers and workers set pay by agreement.

#### Annex

# minimum-wage — served revision bc949d3b-43f4-4612-ba4c-2de39f8757c8 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(ruled 2026-08-31)_ carry an operator ruling (Chris
Andrews, recorded when the topic was built). Lines marked _(proposed)_ are a drafter's reading, not
yet ruled. Lines marked _(ruled 2026-10-01)_ carry a later ruling. No `_owed:_` line is open.

**Question:** "What approach should government take to the minimum wage?"

**Orientation:** standard. Rung 1 is the strongest wage floor (raised and indexed), rung 5 removes
the floor. Rungs 1 and 2 differ by **mechanism** (automatic indexing against a lawmakers' vote), not
by the size of the raise.

**Levels with a lever:** federal, local, state. Each level can set its own
floor where higher law permits; only Congress sets the national floor that rung 3 names.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "minimum wage", "wage floor", "living wage", "indexing", "cost-of-living adjustment"
(COLA), "CPI" / "CPI-W", "escalator", "step increases", "tipped minimum wage", "training wage",
"youth wage", "sector minimum wage", "wage board", "Fair Labor Standards Act" (FLSA).

1. **"Raise the wage floor and tie it to the cost of living, so it rises automatically each year
   without new legislation."**
   - Means: raise the floor and index it, so it rises every year with no new vote.
   - Operative clauses: [a] raise the floor; [b] index it to the cost of living, automatically each
     year. The two clauses are bundled on purpose _(ruled 2026-08-31)_.
   - Establishing evidence looks like: a general minimum-wage law that raises the floor and adds an
     automatic annual adjustment by a price index.
   - Levels that hold a lever: federal; state; local (where state law permits).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because many laws raise the floor in steps. Steps alone, with no
     index after them, are rung 2.
   - An index with **no** raise (indexing the current floor) → `compound-partial` _(proposed)_.

2. **"Raise the wage floor to a set higher level, then adjust it only when lawmakers vote to."**
   - Means: raise the floor to a fixed amount; later changes need a new vote.
   - Operative clauses: [a] raise to a set higher level; [b] adjust only by a vote of lawmakers.
   - Establishing evidence looks like: a general minimum-wage law that raises the floor to a stated
     amount (or a stated schedule) with no automatic adjustment. A fixed amount with no index meets
     [b] by its own design, and that design excludes rung 1's automatic rise _(ruled 2026-10-01)_.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.

3. **"Keep a modest national wage floor as a baseline and let states and cities set higher rates."**
   - Means: a low national floor stays in place, and states and cities may set higher floors.
   - Operative clauses: [a] a modest national floor; [b] states and cities may set higher rates.
   - Establishing evidence looks like: own words for a national baseline plus local choice; a vote
     against a large federal raise together with words for state and local rates.
   - Levels that hold a lever: federal for [a]. A state law that allows cities to set higher rates
     meets [b] only. A state or local officeholder evidences [a] only by own words; otherwise
     `compound-partial` _(ruled 2026-10-01)_.
   - Known chair-shaped instruments: _(none on file)_.
   - **Preemption is on-question here.** This rung is itself about which level decides (codebook V2
     exception), so a state law that forbids local minimum wages is evidence against [b], and a
     repeal of such a ban is evidence for [b] _(proposed)_.
   - Commonly confused with rung 4 because both keep the national floor low. Rung 3 needs [b].

4. **"Hold the wage floor at its current level and let the market set pay above it."**
   - Means: keep the floor where it is now; no raise, no removal.
   - Operative clauses: [a] hold the floor at its current level; [b] the market sets pay above it.
   - Establishing evidence looks like: own words against any raise and against removal. A No on a
     raise rules out rungs 1 and 2 but not 3 or 5 → `direction-only`.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3: see rung 3.

5. **"Remove the wage floor entirely and let employers and workers set pay by agreement."**
   - Means: no minimum wage at all; pay is whatever employer and worker agree.
   - Operative clauses: [a] remove the floor entirely; [b] pay set by agreement.
   - Establishing evidence looks like: a bill to repeal the minimum wage, or own words calling for
     repeal. [a] is an "entirely" clause: a carve-out is not removal (V4.2).
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 when a person supports **exemptions** (youth, training, tipped,
     small employers). An exemption narrows the floor; it does not remove it → `direction-only`
     _(proposed)_.

**Hard cases:**
- **Sector or employer-group floors** (one industry, public contractors) set a floor for some workers only. They are on the wage-floor question but do not show
  the person's general rule → `direction-only` (gold).
- **Tipped-wage changes** (raise or abolish the tipped subminimum) → `direction-only` unless the same
  passage states the general rule _(proposed)_.
- **Ballot measures** are not an officeholder's act. A person's own endorsement of one in their own
  words is `statement-other`.
- **Studies and wage-board reports** → V4 `study-directive`.
- **Budget and omnibus votes** with a wage item → V4 `multi-subject`.


### topic_key: ranked-choice-voting
topic_id: 81ff12e2-0e4f-44b3-a936-2f154f7d9ab5  served_revision_id: 100cdf38-0794-4267-b711-934438f05853
Question: How should votes be cast and counted in elections?
  1. Replace winner-take-all elections with proportional ranked-choice voting — ranked ballots fill several seats at once, so seats reflect how everyone voted.
  2. Adopt ranked-choice voting for single-winner offices: voters rank candidates, and if a top choice can't win, the vote shifts to the next choice until someone has a majority.
  3. Allow ranked-choice voting where communities choose it, while keeping single-choice voting as the standard.
  4. Keep single-choice voting and oppose adopting ranked-choice voting, but stop short of banning it.
  5. Ban ranked-choice voting by law.

#### Annex

# ranked-choice-voting — served revision 100cdf38-0794-4267-b711-934438f05853 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should votes be cast and counted in elections?"

**Orientation:** standard. Rung 1 is the largest change to the voting method (proportional ranked
voting), rung 5 forbids ranked-choice voting by law; rung 3 is the neutral local-option centre. The
rungs order **openness to changing how votes are cast and counted**.

**Levels with a lever:** federal, local, state. Each level sets the method for
its own elections; states also decide whether their cities may choose.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "ranked-choice voting" (RCV), "instant-runoff voting" (IRV), "single transferable
vote" (STV), "proportional RCV", "multi-winner" or "multi-member districts", "plurality",
"first-past-the-post", "winner-take-all", "majority winner", "local option", "final-five" or
"final-four voting" (a top-N primary with an RCV general election).

1. **"Replace winner-take-all elections with proportional ranked-choice voting — ranked ballots fill
   several seats at once, so seats reflect how everyone voted."**
   - Means: elect several members per district by ranked ballots, so seats track the vote share.
   - Operative clauses: [a] replace winner-take-all; [b] ranked ballots; [c] several seats filled at
     once (proportional).
   - Establishing evidence looks like: a bill that creates multi-member districts elected by ranked
     ballots; own words for it. The federal Fair Representation Act is this shape (ladder grounding,
     2026-09-01) — check the version the person acted on.
   - Levels that hold a lever: federal (House elections); state (legislature); local (councils).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because **proportional systems without ranked ballots** (list
     systems, cumulative voting) fail [b] → `direction-only` _(proposed)_.

2. **"Adopt ranked-choice voting for single-winner offices: voters rank candidates, and if a top
   choice can't win, the vote shifts to the next choice until someone has a majority."**
   - Means: use ranked ballots with a majority count for offices that have one winner.
   - Operative clauses: [a] adopt RCV; [b] for single-winner offices.
   - Establishing evidence looks like: a statute, charter amendment or ordinance that adopts RCV for
     single-winner offices; own words for it. Adoption for some offices only (primaries, one city's
     offices) still meets [a] and [b] for those offices _(proposed)_.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a **local-option** bill permits RCV without adopting it.
     Permission is rung 3; adoption is rung 2.
   - A vote to **put RCV on the ballot** lets voters decide; it does not adopt it → `direction-only`
     _(proposed)_.

3. **"Allow ranked-choice voting where communities choose it, while keeping single-choice voting as
   the standard."**
   - Means: communities may opt into RCV; single-choice voting stays the default.
   - Operative clauses: [a] RCV permitted where a community chooses it; [b] single-choice voting stays
     the standard.
   - Establishing evidence looks like: a local-option statute that lets cities or counties adopt RCV
     and keeps plurality as the default. Its own text excludes rung 2 (it keeps the default) and
     rung 5 (it permits RCV) _(proposed)_.
   - Levels that hold a lever: state (the enabling law); local (the officials who choose).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2: see rung 2.

4. **"Keep single-choice voting and oppose adopting ranked-choice voting, but stop short of banning
   it."**
   - Means: oppose RCV for one's own elections, without making it illegal.
   - Operative clauses: [a] keep single-choice voting; [b] oppose adoption; [c] no ban.
   - Establishing evidence looks like: own words that oppose RCV and also oppose a ban. [c] is an
     absence clause and must be stated (V4.2): a No on an RCV adoption bill, or a veto, does not
     separate rung 4 from rung 5 → `direction-only`.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5: see rung 5.
   - A **repeal** of an existing RCV system restores single-choice voting but does not by itself
     forbid RCV later → `direction-only` unless the text also bans it _(proposed)_.

5. **"Ban ranked-choice voting by law."**
   - Means: the law forbids RCV in the jurisdiction's elections.
   - Operative clauses: [a] a legal ban on RCV.
   - Establishing evidence looks like: a statute or constitutional text that prohibits RCV in the
     state's elections, including its local elections. Sponsorship or a final-passage vote on a
     single-subject ban is `chair-shaped`. A ban reaches only the jurisdiction's own elections; it
     does not need to reach other states _(ruled 2026-09-01, ladder wording)_.
   - Levels that hold a lever: state; local (its own elections); federal (federal elections).
   - Known chair-shaped instruments: _(none on file)_. The statewide bans of 2022 and 2024 are the
     ladder's grounding; code each from its bill text and roll call.
   - Commonly confused with BLANK because a state ban that also covers cities looks like
     **preemption**. It is not `adjacent`: rung 3 is itself about whether communities may choose,
     so the Q10 exception applies (codebook V2), and a direct ban is rung 5.

**Hard cases:**
- **Other reform systems** (approval voting, top-two primaries, runoffs, score voting) are on a
  different axis (ladder ruling 2026-09-01) → `adjacent`. A bill that bans RCV **and** another
  method is still rung 5 for RCV.
- **"Final-five" style packages** combine an off-axis primary with an RCV general election. Code the
  RCV clause; the primary clause is `adjacent` _(proposed)_.
- **Ballot-counting and audit rules** for an existing RCV system (tabulation, reporting rounds) →
  `adjacent` _(proposed)_.
- **Omnibus election bills** with an RCV clause → V4 `multi-subject`.


## Sources

---
snapshot_id: d90f7287-4d0d-59fd-9cab-d18a49629d43
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/9d4c9fdb-cbec-4d10-b0a5-3455c6db752d

# On the Record — Matt Pierce (72dd5219-490f-48bb-986e-183a6098d602) ## forum — Bloomington Regular Session - OTR page: https://ontherecord.empowered.vote/meetings/9d4c9fdb-cbec-4d10-b0a5-3455c6db752d - Video: (no video url) - Date on On the Record: 2026-06-09 · date in the source's file name: 2026-03-23 - Kind: forum · Regular Session · Bloomington - Linked races: 0b5ae739-aa3a-4bfd-b1bf-57cc1c380fd9, 0bab4038-45bc-42b6-a1df-38b98e742952 [2:57] Thank you. I'm asking for your vote in the upcoming May primary because I want to continue being a progressive voice for our community and our community's values at the State House. And that means, you know, treating everyone with dignity and respect and not attacking and trying to marginalize communities, creating an economy that works for everyone. affordable housing which we know is a big issue accessible and affordable health care is another thing people are crying out for we need to support our public schools not private schools we shouldn't be diverting our money away from our public schools we need to defend academic freedom and free speech on the IU campus and our other institutions of higher education and the other thing we have to do is we have to protect democracy that's a sad thing to say and so that means fighting things like attempts to redistrict in the middle of the decade I've had amendments to unmask ice I opposed the governor's military police bill and the ice compliance as well [4:21] Okay. Again, as I was saying broadly, it's just this whole basket of issues surrounding preservation of democracy, and that means fighting off voter suppression and these attempts to kind of militarize the law enforcement. That's a key thing. I think one of the other key things is the economy. We cannot have a system where some people have fabulous wealth while a significant number of people are struggling just to get by, and you have the middle class shrinking in the middle. And so that's a key thing. And, you know, the housing and health care and all that kind of fits into that affordability kind of issue. And I think also. academic freedom and free speech on our campus. I mean, it's really sad what you see happening at IU, having protesters in Dunn Meadow being arrested, faculty members dismissed and punished without due process. These are all things that I think we need to push back on. [8:36] Well, the root of the problem goes all the way back to when the Daniels administration decided that having a regular agency, Department of Commerce, was not good enough for economic development because open-door laws and other transparency requirements applied to that agency. So they decided to create, spin off, this economic development corporation. And the idea was they needed to have these kind of secret negotiations and deals. And what happened is over time... That just spun out into corruption, basically. What you had is self-dealing within the IEDC, and you had these crazy things like the LEAP project. They went out and paid outrageous sums of money for land up there, and they didn't even do their due diligence to figure out whether they had enough water for the things they wanted to do there. And all that was at the expense of the taxpayers, and it was because there was not the kind of credibility or the transparency that they needed. A final one to throw in there is this foundation, which is an appendix of IEDC. And in that case, what they would do is they would get these big contributions, charitable contributions, from mostly utilities. And those then would be used for these worldwide junkets. In the name of economic development, they would go to the Formula One race over in Europe, and the governor would go there and say, I'm making deals, you know, here in the suites of the sports events. And there really was no accountability for that. So I voted for a fuller investigation of what actually happened there. I think the current governor is trying to just blame it all on the last governor and move on. And I think we need to go back and really get to the bottom and the details of what happened there. And so I'm hopeful that that will happen. [10:35] Well, I think at this point, environmental issues and energy issues are inextricable. They're just wrapped together. And so I served for a long time on the Environmental Affairs Committee, and then I had an opportunity to become the ranking member, Democratic member of the Utilities Committee. And I've been a relentless advocate for renewable energy and moving us to a clean energy economy. And one of the most frustrating and dispiriting things is just how there's no interest among the Republican Party to address the climate change problem, despite the evidence that is confronting us with these abnormal weather events, flooding, real significant economic impacts, and longer-term impacts that are going to cause people's grandchildren, future generations, to have real problems. And it's really outrageous that the current people in charge are not willing to do something to try to solve these problems. And so I'm doing everything I can to push us to promote solar, rooftop solar. I fought the net metering law that kind of destroyed the economics of people being able to afford rooftop solar and become more independent and save money on their own energy bills on top of it. I've tried to... create more competition with energy. So way back when, I had several years in a row I put in what was called a feed-in tariff bill. It was based on what Germany has, where they basically allowed anybody to plug in. If you had renewable energy, wind or solar, you had a right to sell that into the utilities grid. And that really boosted up the amount of renewables they had there. [15:36] I haven't seen any politics more cynical and hateful than the Republicans at the State House when it comes to the LBGTQ plus community. You know, this all goes back to 2004. George Bush was in trouble because of his wars going into the election. He needed something to drive his base out to the polls. And so they cynically said, let's make marriage equality the big issue. And the same thing happened at the State House. And we went through year after year. of having to fight off this effort to take the so-called Defense of Marriage Act and put it in the state constitution. And I'm proud that at the time, the Democrats were in the majority. I was the chair of the Courts and Criminal Code Committee, and that constitutional amendment passed out of the Senate was sent to my committee, and I killed it. I said, I'm not giving this bill a hearing. I'm not participating in this cynical, hateful process. Since then, they moved on because people actually, the issue turned on them, right? And they no longer had the political power to attack marriage equality, so now they're attacking trans people. And it's sad. I fought off those efforts to— To basically marginalize that community and I've authored co-authored several bills with representative Campbell from Lafayette that attempts to at least begin to claw back this attack on parents' rights to decide what kind of health care their kids could get when they need gender-affirming care. And so I'll continue to work on those issues. [17:30] Well, what I have found during my time in the legislature, that you have to demand respect from the majority party. You can't just be kind of the go-along, nice guy, junior partner. You've got to really get up in their face sometimes. But you have to balance it out, because if you get in their face too much you end up getting marginalized yourself and so what i found just you know one example is the speaker went too far one day and he ruled out we had an amendment to expand voting rights to an election bill called Various Elections Matters. And the speaker said that our amendment was not germane. It violated the rules and could not be voted upon, which was insane because this bill had like 50 different election provisions of all types in it. And so we appealed the ruling of the chair and we debated it and I basically told the other people, like, My fellow Democrats, stand back. I'm taking this one. And I really went after the Speaker full bore. And I went through every single provision in that bill. I pointed out that it said various elections matter for the title. And I said what the Speaker just did here today is an abuse of power. And I challenged them to say, why are you afraid to vote on these bills? Why are you hiding behind the rules? to prevent yourself from being held accountable to the voters. And I said, it's gotta stop. Now, the interesting thing is, For about the next week or so, there was not a single ruling by the Speaker that our amendments were out of order on stuff that I think probably was stretching it a little bit. So you've got to learn how to push hard and command respect. [22:12] The affordable housing issue is kind of one of the more complex issues that I've come across because you have so many variables and factors impacting it, everything from interest rates to housing supply. We now have hedge funds coming in and buying up homes, competing with average buyers, and they have endless funds to come in, and so we're seeing kind of the housing corporatized. And so you've got to approach it from a lot of different angles, and so we need to do a better job, and this is probably Congress's job on Section 8 vouchers. The wait lists are too long for that. We have to do more to try to get more housing. And, you know, I was excited when in this session the Republicans said that they were actually going to start addressing affordability issues. And one of the things they said they were going to address was housing. But what they ended up doing is they had a home builder spearhead the bill, and the home builder said the big problem is we have too many regulations. And so by the time this affordable housing bill actually got before us in its final form, after it had gone through both houses, it was like a joke. It essentially outlawed two safety items because the home builder said they were too expensive. They had a deal keeping your house from burning down. And it also limited what kind of flood mitigation they could do for these retention ponds and things. And then finally it just told every local community you have to have a hearing. To discuss how your zoning laws might be impacting building, which I think we've already had those debates in our community here, and we continue to have them. [24:23] come up first yeah yeah so I'm I'm pleased that when we had the Black Lives Matters protests and that issue was forefront. One of the things I did is I called up the Republican Person I'd worked with on criminal code reform and I said look this we cannot allow this moment to pass without doing something about police brutality and making clear that we have to have a different way forward and I was pleased that we were able to get a bill put together that prohibited things like chokeholds some things that were resulting in people being injured or killed and stress de-escalation and put into the training rubrics for people at the law enforcement academy processes to try to avoid getting into the situations that we've just seen happen over and over again and so we have to we have to keep after that because after a while kind of people forget and they they maybe resort back to the old ways but i think that the other thing that that bill did which i thought was really important is I believe the most police officers want to serve their community, they want to protect the community, and they're very public spirited. But we unfortunately have a few people who seem to have a different set of priorities. And what would happen is when someone would do something that violated the rules of their department, they would just resign and move to the next department, which was easy because there's a shortage of officers. This bill requires the last department to have to share all the information about their personal records with the new potential hires. [28:15] Yeah, I have to admit, there's some days where just things go so crazy up there, you just want to kind of drop your head on the desk and say, like, I surrender. I mean, what can you possibly do to talk any sense into people? Or the worst thing I hate is, like, you made really good points on that bill, but I couldn't vote with you because, you know, my leadership would get mad at me or something. But, you know. There are just enough victories to keep me going. and that's really what continues to motivate me we had a tremendous victory by defeating redistricting and that was awesome and there are lesser victories that people don't particularly hear about all the time one that i can think of we had last session was uh this crazy bill that wanted to move to uh firing squads for executions which just like the nuttiest thing ever And, you know, I really pushed back on that bill, and it couldn't get enough votes within the House to actually move on to the Senate. And I thought that was another, you know, opportunity. So I think that the worst thing we can do is think of ourselves as helpless and hopeless and not having an ability to impact the system. And so particularly right now, I feel like coming up in this election in the fall, we have an opportunity to really take back some power to change the direction of the country and the state. And I think that is the critical thing to keep people focused on is don't give up hope. It's frustrating. It's dispiriting when you see this horrible legislation continue to come through the process. But we've had some victories, and we can have more victories if we all work together and focus on, basically, gaining that political power at the ballot box. [30:09] Yeah, this is really... um tough because i've offered some amendments on that i've been kind of i think it's because i drew the short straw but it ended up being like the house democrats point person on redistricting so i had to read all those grinding legal cases and everything and I think that it is achievable. It's happened in other states, but it's going to take a long-term movement. You know, I think it's something like the women earning the right to vote. I mean, those were multi-decade kinds of efforts, civil rights movement. I think it has to be something up to that level where it's almost a movement and you have to get people engaged enough to understand the impacts of redistricting. I think it's a root of a lot of our problems because when you pack all the Democrats together to dilute their power and that then creates lopsided Republican districts, the primaries become the elections that matter. And the general elections are really just kind of a rubber stamp kind of thing, and this reduces the accountability of the members. You know, there was a time when you had like a 52-48, 51-49 split in the House. Even a 55-48. A 45 split, which was considered a huge majority in those days. You could literally see people sweating as they were thinking about how to vote. They would see stuff like, oh, how are my people going to explain this back home? And now with 70 members and these lopsided districts, there's no sweating in the General Assembly. People just vote. how they want to they pander to their most extreme bases and there's no um there's no accountability because of that so we definitely need to do something on redistricting [34:24] Yeah, I think it's going to take a lot of education, particularly because, you know, over my objections, the Republicans adopted a law which took away the right of the student ID to be used as a voter ID, even though it met every exact. And I made the author of the bill. For like 15 or 20 minutes, I led him through every single aspect of this, and he could not give a good reason why they were doing it. And so that makes it harder to vote. So you've got to educate people about what you need to do to vote. One of the saddest things that I see, and it happens every election cycle, if you go to the county election board when they meet about 10 days after the election, they go through their provisional ballots. there will be 60 or 80 students who showed up to vote and they're not registered they're not registered in the county they're not even from the state they just showed up because they decided they wanted to vote and participate but they didn't understand that you have to get registered by a certain deadline that you have to get to the right precinct and what happened is you know i don't know if they thought their um provisional ballot would just magically count or what but it didn't and to think about all those votes that are not being accounted for is really bad so education is a key thing and then secondly the other part of education is helping people to understand who is doing what to them One reason why politicians are not held accountable when they don't address the needs of the people is because with this crazy media we have, social media, you can't figure out who's doing what to whom. And so we've got to work much harder for people to understand what votes, what parties are for their interests and against their interests. [36:32] Well, I think if you get back to the Indiana Economic Development Corporation, one of the biggest problems is they just got into this mindset of we're going to get the Fortune 500 company to come build a big factory here because we're going to give them these tremendous benefits. We will outbid the corporate welfare that we'll give to the people to get them here. And they ignored the ability of the small businesses, the startups right here. And so this is one thing where I agree with Governor Braun. He seems to be trying to redirect IEDC to be more focused toward something beyond just central Indiana and kind of the big corporations and the big kind of long bomb deals like the Leap District. And so I think that we need to redirect our efforts so that small businesses, that business that is prospering and it needs to get to the next level but it needs some help to get there, how do we help them do that? And then... We have to make sure that that assistance gets out across the state. And for Bloomington, it's particularly important that we support the tech sector, right? So we have a tech park here. We have a lot of people working really hard to build off of the industries we have now and to figure out how to get this kind of startup entrepreneurial economy going. And I think that if we put more effort into that, we have an opportunity to start some small businesses, some startups that could end up being quite substantial companies that would really help our community because we need better, higher-paying jobs in our community. We don't have enough of those. [40:03] think I'm up first okay all right you know one of the things that I think is really important if you're serving as a legislator is to look around the hearing rooms and the hallways of the Capitol and ask yourself who's not here Because oftentimes you hear only from the interest groups that can afford to have paid lobbyists at the State House who are there constantly, who build the relationships, who become friendly with legislators. And their viewpoints always get across. But there are many average everyday Hoosiers. who aren't organized in a way with the resources to have somebody on the scene at the state house every day working for their interests. And so that's where the responsibility of the legislators who represents all the people within his or her district. that legislator has to be thinking about who's not here, who's getting left out of the conversation. And that's one thing that I really pride myself on. So when the payday lenders show up and say, we need less regulation because we need to give people access to capital, I say, look, guys, this is not Fortune 500 companies talking about. You're exploiting struggling people. So let's not come up with some phony excuses for why you need stuff. We know what's going on here. And so people need legislators who will call out those people who want to prey upon people who are struggling the most. And so that's why I very much would like to be returned to the legislature. I'm asking the voters to return me there for another two years so I can continue working on those issues and representing all the people of District 61. [74:45] It was a good. [78:50] We got one going.