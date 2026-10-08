You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-education-curriculum/labels/coder-3.json. Write JSON only, matching
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

politician_id: 9a60d603-194d-410f-ae01-85bd6293f1a7  office_id: 08454462-a1f0-4d11-9f61-aba7a173a3de
Steve Hilton — Governor, California (candidate, level: state)
Candidate in the election of 2026-11-03

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


## Sources

---
snapshot_id: 6bb2d4aa-7dff-5ddd-b3d6-941ec16bedca
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/califordable-schools-ban-school-supply-charges

Saved from https://stevehiltonforgovernor.com/policies/califordable-schools-ban-school-supply-charges (rendered page text, built-in browser, 2026-10-07) POLICY CALIFORDABLE SCHOOLS ← POLICY ARCHIVE CALIFORDABLE SCHOOLS BAN SCHOOL SUPPLY CHARGES If a public school requires it, the public school should provide it. California spends nearly $28,000 per public-school student. Yet every year, parents are sent shopping lists for pencils, notebooks, paper, folders, glue sticks and other basic classroom supplies. Parents may not receive a formal bill from the school. Instead, they are told to go to the store and buy the supplies themselves. The effect is the same. Steve Hilton will ban public schools from charging parents for basic supplies, including getting around the ban by sending home “suggested” or “voluntary” shopping lists. If a student needs something for class, the school will provide it. THE PROBLEM California law already says that public schools must provide the supplies, materials and equipment students need to participate in educational activities free of charge. Schools cannot require students to purchase supplies. But schools continue to send parents shopping lists because the request is supposedly voluntary. Putting the word “suggested” at the top does not make the pressure disappear. A Los Angeles Unified fifth-grade supply list tells families to purchase pencils, crayons, paper, folders, copier paper, wipes, glue sticks and other supplies. A Tustin elementary school list asks first-grade families for 24 pencils, 12 glue sticks, notebooks, headphones, wipes and more. Teachers are left to cover the same gap. A 2025 California Teachers Association survey found that 93 percent of educators surveyed routinely spend their own money to support their students. A separate national survey found that teachers spent an average of $895 out of pocket during the 2024-25 school year. Public schools should provide the basics. That responsibility should not be pushed onto parents and teachers. THE MONEY IS ALREADY THERE The overall state budget has more than doubled in the past decade. California spent about $171 billion in 2016-17. The 2026-27 budget spends about $352 billion. General Fund spending alone grew from about $122 billion to more than $251 billion. Schools and community colleges receive a constitutionally guaranteed, formula-driven share of General Fund revenue through Proposition 98. The exact percentage changes with the formula, but under the test currently in effect, approximately 40 cents of every relevant General Fund revenue dollar goes toward the guarantee. As the state budget grew, education funding grew with it. The Proposition 98 guarantee increased from $71.9 billion in 2016-17 to an estimated $128.1 billion in 2026-27. The Legislature’s nonpartisan fiscal analyst estimates that California will provide roughly $149 billion for K-12 education from state, local and federal sources in 2026-27. That works out to $27,418 per student. Over the same period, the total number of enrolled students has actually fallen by nearly half a million, from 6,228,235 in 2016–17 to a projected 5,736,456 in 2026–27. On the latest nationally comparable measure, California’s current spending per student is well above the national average. California is spending much more money on half a million fewer public-school students than it did a decade ago. A state spending nearly $28,000 per student has no excuse for sending parents out to buy pencils. STEVE HILTON’S CALIFORDABLE SCHOOLS PLAN 1. BAN SCHOOL SUPPLY CHARGES AND SHOPPING LISTS As governor, Steve will send to the Legislature the Califordable Schools Act. The current law bans required school-supply purchases. The Califordable Schools Act will also ban the workaround of sending parents lists for basic supplies and claiming that buying the items is voluntary. Under the Act: Public schools may not require or ask individual families to purchase supplies needed or routinely used in class. A school-published list for basic classroom supplies will be treated as a school-supply charge, even if it is labeled “suggested” or “voluntary.” Schools and districts must provide pencils, paper, notebooks, folders, crayons, glue, basic calculators, classroom books and other necessary instructional materials at no cost to students or parents. Parents will be able to use the existing pupil-fee complaint process. Schools that violate the law will have to provide the supplies and reimburse affected families. The Act will still allow PTA fundraisers, community donations and voluntary support for enrichment or special projects. But schools may not send individual families a shopping list for the materials needed to operate a classroom. 2. GIVE EVERY TEACHER A $1,000 CLASSROOM BASICS ACCOUNT Every classroom teacher will receive a $1,000 Classroom Basics Account before the first day of school. Teachers will be able to buy the supplies their students need without using their own money, submitting reimbursement forms or waiting for approval from a central district office. California has approximately 287,000 K-12 teachers. Providing each teacher with a $1,000 account would cost about $287 million. That is less than two-tenths of one percent of the roughly $149 billion California already provides for K-12 education. The accounts will supplement, not replace, existing school and district supply budgets. Districts will not be allowed to cut their current classroom-supply funding and substitute the new accounts. The money will remain under the control of teachers. It may not be redirected to central administration, consultants, salaries or travel. HOW IT WILL BE PAID FOR The Califordable Schools Plan does not raise taxes. California can fund the Classroom Basics Accounts from the Lottery. In 2024-25, the California Lottery recorded nearly $8.93 billion in ticket sales. Only 20.6 percent of those sales was allocated to education. Prizes received 67.1 percent, while 12.3 percent went to retailer costs, game costs and Lottery operations. Steve will move the Lottery to a 25/65/10 formula: 25 percent for education, 65 percent for prizes and 10 percent for Lottery costs. At 2024-25 sales levels, this would provide approximately $389 million more for education. If K-12 schools continued to receive the same share of Lottery education distributions, they would receive roughly $306 million more. That is enough to cover the approximately $287 million cost of the Classroom Basics Accounts. The 65 percent prize share falls within the range identified by an independent Lottery analysis as most likely to maximize contributions to education. Steve can begin this reform without waiting for new legislation. The governor appoints the five Lottery commissioners and the Lottery director, subject to Senate confirmation, and may remove them. The Commission approves the annual Lottery budget and determines the percentages going to education and prizes. Lottery spending reductions will begin with advertising, public relations, management overhead and unnecessary outside contracts. Ordinary compensation for the small businesses that sell Lottery tickets will not be affected. Lottery funding will remain supplemental. It will not replace Proposition 98 funding or the classroom-supply money districts already provide. The Classroom Basics Accounts will remain guaranteed if annual Lottery sales fluctuate. A BETTER WAY FORWARD Steve will ask legislators of both parties to pass the Califordable Schools Act. They all say they care about affordability. They should be able to agree that a public school receiving nearly $28,000 per student should provide the supplies needed in its classrooms. A vote against the Califordable Schools Act is a vote to keep sending parents shopping lists and expecting teachers to spend their own money. Enough is enough. Free public school should mean really free. If the school requires it, the school provides it. SOURCES AND METHODOLOGY California 2016-17 Enacted Budget. Reports total state spending of approximately $170.9 billion and General Fund spending of approximately $122.5 billion. California 2026-27 Enacted Budget. Reports total state spending of approximately $351.7 billion and General Fund spending of approximately $251.5 billion. Legislative Analyst’s Office, Proposition 98 Key Inputs and Outcomes Under the 2026-27 Budget Package. Reports a 2026-27 Proposition 98 guarantee of approximately $128.1 billion and identifies Test 1 as the operative formula. Legislative Analyst’s Office, 2016-17 EdBudget Tables. Reports a 2016-17 Proposition 98 guarantee of approximately $71.9 billion. Legislative Analyst’s Office, K-12 Funding by Source. Estimates $149.3 billion in total K-12 funding and $27,418 in total funding per student for 2026-27. Public Policy Institute of California, Financing California’s Public Schools. Reports that California ranks 16th on the latest nationally comparable current-spending measure. California Education Code sections 49010 through 49014. Requires necessary supplies to be provided free of charge and establishes the pupil-fee complaint and reimbursement process. California Department of Education, Fiscal Management Advisory 23-02. Explains California’s pupil-fee laws and the requirement that districts furnish necessary school supplies. Sunny Brae Avenue Magnet School, Fifth Grade Supply List, 2026-27. LAUSD school list identifying supplies for families to purchase. Arroyo Elementary School, Suggested Supply Lists, 2025-26. California public-school supply lists including pencils, glue sticks, notebooks, headphones and wipes. California Teachers Association, State of California’s Public Schools survey release. Reports that 93 percent of educators surveyed routinely spend their own money to support students. AdoptAClassroom.org, 2025 Teacher Spending Survey. Reports average national teacher out-of-pocket spending of $895 during the 2024-25 school year. California State Lottery, 2024-25 Annual Comprehensive Financial Report. Provides audited Lottery sales, prize, expense, education and distribution figures. California Department of Education, 2025-26 DataQuest Highlights. Reports 287,358 K-12 teachers. California Government Code sections 8880.16 and 8880.23. Establish the governor’s appointment and removal authority over the Lottery Commission and director. ← Back to all policies

---
snapshot_id: 3356e490-4c50-5693-a163-fb4a7fb74719
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/an-elite-business-school-in-east-la

Saved from https://stevehiltonforgovernor.com/policies/an-elite-business-school-in-east-la (rendered page text, built-in browser, 2026-10-07) POLICY WORKING CLASS TO FOUNDER CLASS: AN ELITE BUSINESS SCHOOL IN EAST LA ← POLICY ARCHIVE WORKING CLASS TO FOUNDER CLASS: AN ELITE BUSINESS SCHOOL IN EAST LA A world-class pathway to technology entrepreneurship and business leadership THE PROBLEM California has some of the best universities in the world. But for millions of working Californians, the opportunity they represent is increasingly out of reach. We have among the highest poverty and unemployment rates in America. Social mobility in many parts of our state, and for millions of young Californians, seems to have ground to a halt. California used to offer young people opportunity better than anywhere else in the world. Far too many young Californians today feel as if the only option is to be stuck here with no prospect of ever owning a home, or starting a business – or moving to another state. That failure is especially stark in East LA. A teenager in Palo Alto grows up surrounded by founders, engineers, investors, and people who expect them to aim high. A teenager in East LA may have just as much talent and drive, but far less exposure to those industries, those networks, and those expectations. In East Los Angeles, only 11.4 percent of adults over 25 have a bachelor’s degree, and more than 17 percent live in poverty. Too many talented young people are never shown a credible route from where they are to a career in technology or finance, or to starting a high-growth company of their own. There is nothing wrong with building a restaurant, working in music, or joining a family business. Those are part of the strength of East LA. But they should not be the only visible paths. Young people in East LA should see the same horizon as young people growing up around Silicon Valley: technology, venture capital, finance, product development, and high-growth, high reward entrepreneurship. California’s answer has usually been another workforce program. That is not enough. East LA does not need a second-tier program with lower expectations. It needs an elite institution built to recognize talent, raise aspiration, and open doors. HOW WE GOT HERE California has built a two-tier education system. Students from affluent communities get access to elite universities, powerful alumni networks, prestigious internships, and the confidence that comes from being told they can lead. Working-class students are too often steered toward basic job training and told to be “realistic.” Business success depends on more than classroom instruction. It depends on exposure, mentors, relationships, confidence, and access to capital. Young people absorb what is possible from the people and institutions around them. If they never meet a founder, investor, engineer, or executive, those careers can feel as if they belong to someone else. California’s leading universities regularly promise to expand access and serve the communities around them. Some have begun. UCLA Extension has partnered with the SoLa Foundation to offer tuition-free UCLA courses in South Los Angeles. That is a good start. But a collection of short courses is not the same as an elite, aspirational business school with a rigorous curriculum, a respected credential, a powerful network, and a direct path to building and leading a company. STEVE’S PLAN Steve Hilton will launch an elite, locally rooted business school in East Los Angeles through a competitive partnership with one of California’s leading universities. It will be elite in quality, not restricted by wealth. Students will be admitted for their talent, drive, creativity, and potential, and the program will be tuition-free for income-qualified California residents. BRING AN ELITE UNIVERSITY TO EAST LA UCLA, USC, Claremont McKenna and other leading public and private universities will be invited to compete to become the school’s founding academic partner. The selected university will put its name and academic standing behind the school, design the curriculum, provide faculty and visiting instructors, and open its alumni, employer, and industry networks to students. This will not be a satellite office with a famous logo on the wall. Students will earn a respected university credential and transferable academic credit, with a clear path to further study at the partner university, or another equivalently high-status institution. SET ELITE STANDARDS AND FIND OVERLOOKED TALENT The school will recruit aggressively from East LA high schools, community colleges, churches, and community organizations. Admissions will look beyond family connections and narrow measures of academic success to identify initiative, resilience, creativity, leadership, and the determination to build something. The standards will be demanding. Students who need additional preparation will receive it through a summer bridge program, tutoring, and academic support. The answer to unequal opportunity is not a watered-down curriculum. It is giving talented students the support they need to meet an elite standard. TEACH STUDENTS HOW COMPANIES ARE BUILT Students will study entrepreneurship, finance, accounting, marketing, sales, product development, operations, artificial intelligence, data, leadership, and communication. The goal is not to train students for one narrow job. It is to teach them how a company is created, financed, managed, and scaled. Every student will work on a real company, product, or business plan. They will test ideas with customers, build a budget, make a pitch, and learn from success and failure. Students who want to grow an existing family business will be able to use the same tools to take it further. OPEN THE NETWORK California founders, executives, investors, engineers, accountants, and attorneys will serve as mentors and instructors, and every student will receive paid work experience with a technology company, startup, investment firm, or growing California business. The school will also host founders and investors in residence and regular pitch sessions. Students will leave with relationships, references, experience, and people prepared to open doors for them. GIVE STUDENTS THE CHANCE TO BUILD The school will include a business incubator where students and graduates can develop companies with access to workspace, legal and accounting support, market research, and experienced advisers. A privately backed seed fund will give promising student ventures the chance to compete for early investment. Public dollars will support education. Private investors will decide which businesses to back. REMOVE THE PRICE BARRIERS For income-qualified students, support will cover tuition, books, technology, transportation, and childcare. The school will offer a full-time program, flexible options for working students, and a summer academy that introduces local high school students to technology, entrepreneurship, and business leadership before they choose a college or career path. START IN EAST LA AND PROVE IT WORKS Steve will fund the East LA pilot in his first budget by bringing together existing higher education and workforce resources with matching support from the university partner, employers, and philanthropy. There will be no new state bureaucracy, and no new tax. The first class will begin during Steve’s first term. The state will publish results including completion, transfer, paid internships, job placement, starting pay, companies launched, and outside capital raised. If the model works in East LA, California will take it to other working-class communities across the state. A BETTER WAY FORWARD The point is not to train young people in East LA for the jobs others have decided are “realistic” for them. The point is to give them access to the same knowledge, networks, and expectations that have helped create generations of California business leaders. A young person in East LA should grow up believing they can found the next great California company, finance it, build it, and lead it. Talent is already there. This school will match that talent with elite opportunity: from working class to founder class. ← Back to all policies

---
snapshot_id: 350a5134-adbe-50e5-86e4-90e47ae2d049
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/making-californias-schools-work-again

Saved from https://stevehiltonforgovernor.com/policies/making-californias-schools-work-again (rendered page text, built-in browser, 2026-10-07) POLICY MAKING CALIFORNIA’S SCHOOLS WORK AGAIN: FIX PUBLIC EDUCATION BY 3RD GRADE ← POLICY ARCHIVE MAKING CALIFORNIA’S SCHOOLS WORK AGAIN: FIX PUBLIC EDUCATION BY 3RD GRADE THE PROBLEM California’s public schools are failing millions of students. Only 47% of students meet English language standards, and just 35% meet math standards, compared to the roughly 60% of students nationwide that meet their state’s English standards and 65% that meet state math standards. For Black and Latino students, the numbers are even worse. Nearly 70% of Black students and 64% of Latino students do not meet basic standards in reading. These failures are concentrated in the early grades, where students are falling behind and never catching up. Research shows that if a child cannot read proficiently by the end of 3rd grade, they are four times more likely to drop out of high school. That is why fixing early education and ensuring literacy by 3rd grade must be the cornerstone of any serious education reform. HOW WE GOT HERE California spends more than $22,000 per student each year, among the highest in the nation, yet outcomes continue to decline. This is not a funding problem. It is a leadership and accountability problem. Politicians backed by teachers unions have removed phonics-based reading instruction, abandoned Algebra in middle school, stripped away consequences for failure, and added ideological curricula that crowd out basic skills. At the same time, the state has made it nearly impossible to reward good teachers or remove ineffective ones. Schools are no longer judged by whether students learn, but by whether bureaucratic boxes are checked. In too many places, especially low-income communities, the system seems designed to protect itself rather than serve children. STEVE HILTON’S SOLUTION: 3RD GRADE FIRST As governor, Steve Hilton will make 3rd grade literacy and numeracy a top education priority. His plan includes structural change, immediate classroom reforms, and full accountability to parents. This approach does not require more spending. It requires a new focus on results. 1. RESTORE PHONICS-BASED READING INSTRUCTION IN ALL K–3 CLASSROOMS. Phonics is the most proven method to teach children to read, but California does not require it. Steve Hilton will use executive action and pro-reform appointments to the state Board of Education to mandate phonics instruction statewide. 2. HOLD SCHOOLS ACCOUNTABLE FOR 3RD GRADE READING RESULTS. Every school will receive a clear, public letter grade each year based on student proficiency, starting in 3rd grade. Schools that fail to show improvement will be placed in state-directed “special measures” with new leadership, strategies and greater accountability. 3. REFORM TENURE, TEACHER EVALUATIONS, AND DISMISSAL POLICIES. With Steve Hilton as governor, California will require at least five years of classroom experience before granting tenure. Low-performing teachers must be removed quickly and excellent teachers rewarded. 4. BRING BACK AND EXPAND THE PARENT TRIGGER LAW. Parents will once again be empowered to force reforms at failing schools. If a school receives a D grade two years in a row, parents will have the right to trigger administrative changes, curriculum overhauls, or conversion to a charter model. 5. LAUNCH EDUCATION SAVINGS ACCOUNTS AND CROSS-DISTRICT OPEN ENROLLMENT. To give parents immediate options while traditional schools improve, Hilton will expand choice through ESAs, starting with low-income and special needs students. Parents will be free to move their children to any public school that performs better, regardless of zip code. Steve Hilton believes California can lead the nation in education again. But it starts with getting every child reading properly by 3rd grade. ← Back to all policies

---
snapshot_id: 273ad670-1320-579b-b8d6-e17c912fe8e4
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/get-big-tech-out-of-the-classroom

Saved from https://stevehiltonforgovernor.com/policies/get-big-tech-out-of-the-classroom (rendered page text, built-in browser, 2026-10-07) POLICY GET BIG TECH OUT OF THE CLASSROOM ← POLICY ARCHIVE GET BIG TECH OUT OF THE CLASSROOM A company that sells technology to schools should not also be setting academic standards, writing curricula or training teachers to use its products. Recent investigations have documented how companies including Google, Microsoft and Apple have funded teacher training, supported courses and front organizations that advance their interests, and built influence throughout the education system. The same pattern is now being used to rush artificial intelligence into classrooms before anyone knows what it will do to learning, critical thinking or child development. As governor Steve Hilton will draw a clear line between the companies selling classroom technology and the people deciding what - and how - children learn. STEVE’S PLAN WILL: Bar technology companies and the organizations they fund from setting academic standards, writing curricula, designing teacher training or shaping state education policy. Require organizations advising California education officials to disclose their corporate funding and financial relationships. Big Tech-backed groups should not be presented to parents and policymakers as independent experts. Stop companies from using branded courses and teacher training as marketing. Vendors would be able to explain how to operate a product after a school has purchased it, but they could not use training programs to shape teaching methods or create demand for their products. Require independent evidence and testing before major new technology is introduced into California classrooms. Schools and parents should be told what evidence shows that the product improves learning, what student information it collects and how much it will cost. Pause the adoption of AI in California schools until a full independent review, to report by the summer of 2027, recommends clear guidelines, including the appropriate grade level for AI to be introduced into the classroom. The review will include public hearings in every county and take evidence from experts and interested parties from around the world, to make sure that California sets the global standard for the use of AI in education. Technology that is genuinely useful, and which supports human flourishing, will still have a place in California schools. But dehumanizing technology that impedes learning and development will be banned, and Big Tech will no longer be able to sell products to schools as well as writing the rules. ← Back to all policies

---
snapshot_id: 31e388b8-06af-5aba-932d-18de637db7eb
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/cut-californias-electricity-bills

Saved from https://stevehiltonforgovernor.com/policies/cut-californias-electricity-bills (rendered page text, built-in browser, 2026-10-07) POLICY CUT CALIFORNIA’S ELECTRICITY BILLS BY ENDING WIND AND SOLAR FARM MANDATES AND SUBSIDIES ← POLICY ARCHIVE CUT CALIFORNIA’S ELECTRICITY BILLS BY ENDING WIND AND SOLAR FARM MANDATES AND SUBSIDIES THE PROBLEM California families and small businesses pay the highest electricity bills in the continental United States. The average bill is now $253 per month, with Californians paying 35 cents per kilowatt-hour compared to a national average of 17 cents. That is more than double what most Americans pay, even though California is rich in energy resources. Over the last decade, the average monthly bill has more than doubled. These costs are not the result of shortages, but of deliberate political choices. Two policies in particular have driven rates sky high: the system of Renewable Energy Credits (RECs) and the Renewable Portfolio Standard (RPS), which forces utilities to buy ever-greater shares of renewable electricity regardless of price. Both were sold as tools to promote clean energy. In practice, they have become hidden taxes on ratepayers, funneling billions to special interests while households struggle to keep the lights on. The harm does not stop with higher bills. Subsidized solar farms are also spreading across some of California’s most productive farmland, putting long-term food production at risk. Families are being squeezed at the grocery store as well as on their utility bills. HOW WE GOT HERE California politicians have spent decades layering mandates and subsidies that distort the true cost of power. The result is at least $5 billion a year — and possibly as much as $10 billion — in extra costs that show up directly on utility bills. RENEWABLE ENERGY CREDITS (RECS) These credits can be sold into programs like California’s Low Carbon Fuel Standard for about $15 per REC. In 2023, utility-scale solar generated over 40,000 gigawatt-hours of power. That translates into 40 million RECs worth roughly $600 million a year, costs that businesses and households ultimately bear through higher rates and prices. RENEWABLE PORTFOLIO STANDARD (RPS) California law requires utilities to source 60 percent of their electricity from renewables by 2030 and 100 percent carbon-free by 2045. This mandate forces utilities to buy renewable power or credits at inflated prices. The real costs go far beyond the electricity itself: billions for new transmission lines to remote solar farms, battery storage, inflated costs for gas plants that are forced to run only part-time, and endless litigation and permitting delays that drive up the price of nuclear and other reliable sources. Families pay twice — once through taxes that bankroll subsidies, and again in soaring monthly bills. FARMLAND AT RISK Solar farms are spreading onto some of California’s best farmland, raising local temperatures and cutting into the “chill hours” that crops like almonds and pistachios need to grow. Even small changes reduce yields and hurt long-term food production. Italy confronted the same problem in 2024 and banned new solar installations on productive farmland to protect its food supply. California should do the same and keep its farmland focused on feeding families and supporting our great farmers and world-leading agriculture industry. STEVE HILTON’S PLAN Steve Hilton will repeal California’s costly wind and solar mandates and subsidies, replacing them with an energy policy focused on affordability, reliability, and consumer choice. His plan includes: End Renewable Energy Credits and Portfolio Mandates. Stop forcing utilities and businesses to buy credits and overpriced renewable power that drive up household bills. Audit the full system costs of renewables. Demand honest accounting of transmission, storage, backup, and permitting costs that are often hidden. Californians deserve transparency, not accounting tricks. Prioritize affordable, reliable energy. Allow natural gas, nuclear, and consumer-driven rooftop solar to compete on a level playing field, free from government mandates that tilt the market. Protect farmland. As governor, Steve Hilton will ensure California’s farmland is preserved for food production by banning new solar farms on fertile and productive fields, while allowing projects that do not disrupt agriculture. And by ensuring that farmers get the water they need, Steve will end the cruel and cynical trick currently being played by Democrat climate extremists: denying farmers water, rendering potentially fertile farmland unusable for agriculture, then claiming that solar farms are the only realistic option for generating income from the land. We have the most fertile farmland in the world and we should be using it to grow the food that will help make America healthy again — fruit, nuts, produce — instead of dumping solar panels made in China. With these reforms, Californians will finally see their electricity bills fall, the grid strengthened, farmland saved, and families protected from politically imposed energy inflation. Energy policy should serve working people and small businesses, not lobbyists or ideological crusades. ← Back to all policies

---
snapshot_id: 0a65c8ba-845a-5292-8d4a-c1f2d7f74a7c
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## California Governor Debate - CNN (General Election) - OTR page: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7 - Video: (no video url) - Date on On the Record: 2026-09-30 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, bec5ef3b-095b-4d7d-9117-db81e407cb5e [1:23] I love the way that Javier says the wealthiest are people who are earning less than $150 ,000 a year struggling. But first of all I just want to say thank you to CNN for bringing Javier out of hiding. He's barely been seen in public since the primary four months ago. It's very important we have this debate and the simple point is that the quickest way to get more money in people's pockets is for the government to take less out. That's what I'm going to be doing and it's not coming from the budgets that he describes you know what it's coming from canceling high -speed rail which he's promised to [2:27] So just to be clear you want the people working so hard and barely able to survive I've been in every one of our 58 counties the struggle that people face with the highest cost of living in the country and the highest taxes you want to ask them to continue to pay taxes at same rates? See, again, the misrepresentation. [3:15] happy to talk about that. Javier is right about that. As well as helping working people, [3:23] as well as helping working people, we need to bring jobs back to California. Right now, because of your policies, we have the highest poverty rate and the highest unemployment rate in America. That's because high taxes have driven business out. So we need to incentivize jobs to be created in California instead of sending them to Texas. What I didn't hear was a single thing from Javier about how he would actually help people with the cost of living. And in fact, if we continue with his policies, that's another $11 ,074 a year extra that you would pay [4:52] much more straightforward than I think people realize. There's a couple of simple things that we can do to restore that California dream of home ownership. Number one, the quickest way to reduce the cost of housing is for the government to stop making it more expensive. A recent survey found that the average new home in California is subject to $200 ,000 in government fees and regulations. I'm announcing tonight that I will cap that at $50 ,000. That is $150 ,000 off the price of a new home. Secondly, we need to stop forcing apartment buildings into suburban areas and having all those battles between NIMBYs and YIMBYs when we've got so much space that we could building in in California and then the final part is to build as we used to do in this state the magnificent California dream 10 new cities that's my plan with counties bidding to host the construction of the new communities that will help young people follow their dreams here in California instead of having to move to another state. [6:07] problems Jake is that we've had these kind of top -down targets rather than and they never get met and they make all these promises and exactly as Javier said is the definition of insanity is is doing the same thing and expecting a different result I've got a completely new approach instead of the set of Sacramento forcing this onto communities I want communities to build the housing that meets their needs. [7:09] He hasn't explained how he would actually reduce the cost of housing. We have the highest... No, you didn't. You said that... I would cut red tape. Red tape needs to move fast. What's the track record that you've shown in standing up to the legislature in Sacramento when you were there as attorney general, you did nothing to push back against the and the craziness of that legislature. You can make up the facts. I could get into [7:37] Tell us one thing you did when you were in the, when you were state attorney general to push back against the growth of red tape on housing and everything else. Just one thing. Sure. I [7:47] city [8:18] huntington beach we've got communities up and down the state that want to build but they're being stopped from building by the legislation the regulations and the red tape that his party has put in place. And I said, I would cut the red tape. [8:31] Why should it? It's like your question. The definition of insanity is believing that the people who put the red tape in place are now somehow going to cut it. Gentlemen, [9:10] Well, I think this AI question is actually a different one for California than the rest of the country because these companies are based here and because of the fact that so many businesses have been driven out of the state, our finances are really dependent on these companies. And the problem is that the jobs associated with AI, the high -end manufacturing and infrastructure, that's all going to other states like Texas and Arizona. And the first priority with this industry is to make sure we get all those jobs here in California. The second thing that's very important I think we can all agree on is that this is the least complicated part. At least let's protect children. I think we can all agree on that. And that's why I've said that we should have an immediate pause on AI in the classroom, because right now we're seeing real concerns about something called cognitive stunting, where children's ability to learn is being impeded by AI. In terms of the regulations, I want to make sure that the priority for these companies is safety, making their products safer. Whether that's done by them or we need regulation, we'll see how quickly they act on the promises they've made. [10:28] Well, we'll have to see. They made a number of commitments yesterday. This is very urgent, and I will hold them to that. And as they said in that announcement that they made yesterday, it may require regulation and legislation. I think that should be led in California because this industry is here. You've got a lot of people putting out their opinions on this who really don't know what they're talking about. Here in this state, we lead this industry and I think we need to lead the regulation of this industry as well. [11:48] I just want to ask you a very simple question. How can we possibly trust you on this when you are funded by Big Tech and AI? How much money have you taken from OpenAI and Anthropic? [12:04] much money have you taken from OpenAI and Anthropic? [12:27] you've never done it. [12:28] What I've never done is what you've done in your 36 years as a career politician, where you've never created a job. You've never actually had to make any money of your own. All you've ever done is spend other people's money in every government job you've had. According to your Democrat colleagues, the ones who worked with you, like Susan Rice, who worked with you side by side when you were in the Biden cabinet, she described you as an idiot. She called you bitch ass. Why did Susan Rice, a respected political leader, call you an idiot? [14:42] If you're Javier Becerra and you're the candidate who is supported by the machine in Sacramento, the unions, big business, all these people that for 16 years have given us the highest cost of living in the country, made it impossible to build anything, given us the highest unemployment rate, the highest poverty rate, then we're not going to get the jobs in this state that we so desperately need. And that's why we've got to try something different this time instead of voting for more of the same and expecting a different result. [15:49] is all you can do is point to the same people the same organizations the same policies that have given this state the worst homelessness which you gave Gavin Newsom an A grade for Unbelievably, the highest cost of living, the highest cost of doing anything, the highest unemployment rate, the highest poverty rate. It's impossible for regular working people to live in this state anymore. That's why two million people have left just in the last few years. And all you're offering is more of the same, backed by the same corrupt machine in Sacramento. We've got to change the - I'll let [17:03] Well, as you said, Jake, there is a scope within the law, SB 54, our Sanctuary State Law, as it's known, for there to be cooperation on a long list of categories, specific crimes and specific circumstances. And so I would follow the law. And in fact, my goal here would be to lower the temperature on this whole question. I'm an immigrant. My parents were immigrants from Hungary to England. And so, I want to make sure that we protect our legal immigrant communities and we enforce the law. Everybody agrees that we need secure borders and that we've got to make sure that people who are in this country illegally, who've committed dangerous crimes, should be removed. But that's not happening in California every week, pretty much. We hear horrific stories of crimes that have been committed because of this partisan posturing by the politicians in California that just refuse to follow the law as it's written, even California sanctuary law, which allows for those kinds of criminals to be removed from the country. [18:15] It's about enforcing the law. I mean, the federal law is, immigration law is obviously a federal matter. And my whole aim here would be to lower the temperature. We've got to get this whole debate back to where most people want it to be, which is to prioritize the removal of dangerous criminals. That's not happening in California today and that's because they're playing politics with the issue instead of protecting public safety and that will be my priority. [19:31] You're not enforcing and your party isn't enforcing California law as it is now. And what a disgraceful remark that was. I don't think people want to hear that kind remark in a debate like this and why would you deport every [19:49] said people want to hear it's solutions to their problems not these unpleasant political attacks that don't help anyone immigrant or not with the problems that they're facing the cost of living all of the problems that you have no solutions to whatsoever so all you've got is the talk about your federal politics your All you ever say is Trump, Trump, Trump, and that's nothing but an insult to every Californian who is desperate for something to change in this state and all you're offering is more of the same. Your words, [20:27] Trump, [20:31] That's all you can say on every question because [20:55] Again, because he's got no arguments. Don't try to escape your own words. Because he's got no arguments and no solutions and nothing to say about how he would change anything about how California is run. [22:35] Mr. [22:36] I cannot believe that you're standing there trying to make these arguments. When you were HHS secretary, you were responsible for 479 ,000 unaccompanied migrant children and for their welfare in camps that you ran. You sent them because you dismantled the vetting that should have made sure that they were with a safe, protective family or sponsor, you sent thousands of young children directly into the clutches of child sex and labor traffickers. Hundreds of thousands of children that you were responsible for are still missing today. A hundred thousand of them are under 10 years old. So I cannot believe that you haven't apologized, That you you have any kind of sense of shame or responsibility for what you did to those children and you stand here Lecturing people about immigration when you treated these most vulnerable children unaccompanied children in this way those [24:46] The original investigation that he's now trying to deny was by the New York Times, and it won a Pulitzer Prize. These arguments were made in the primary by other Democrats, including Antonio Villaraigosa, the former mayor of Los Angeles. And you tried the same trick then, to deny responsibility. I cannot believe I've seen the testimony of the victims who were sexually assaulted, and you're proud of putting them into the hands 200 children were sent to one address that turned out to be a contain a lot because you dismantle [26:36] Yes, sensible things that will actually help reduce carbon emissions without hurting every California family and business. For example, it makes absolutely no sense right now to do what we're doing, importing oil halfway around the world from the Middle East and from South America when we have abundant oil reserves here. That actually increases carbon emissions as well as raising gas prices. As long as we're using those energy products in California, let's use what we produce here, which is produced cleaner than anywhere else in the world. Secondly, wildfires. When you have these mega wildfires that burn out of control, they release much more carbon dioxide than is saved by these ineffective and costly climate policies. So we'll have proper forest management to reduce the risk of mega wildfires. That will reduce carbon emissions. And so right through all of these policies, we need to be practical and sensible about these goals rather than just following ideological objectives that increase the cost of living for every California family and business. [28:30] I'm gonna cut the bureaucrats that they've increased in massive numbers that are making everyone's life more expensive and difficult and cancel high speed rail and cancel the payments to nonprofits that are ripping us off when it comes to homelessness. That's how we reduce taxes for every worker. But I just wanna ask you a question about why you're not gonna change. Just look into that camera and tell everyone the national average gas price in America today. [29:01] the [29:40] in Sacramento so that we can give firefighters a tax cut so they're not struggling. Okay, gentlemen, we're gonna [31:25] So Javier gave, when we were asked to give Gavin Newsom a grade on homelessness, he gave him an A. And he's standing there after 16 years where this absolute scandal shames our state saying that suddenly he's gonna go in new direction. This is what's so insulting, actually, about this attitude we get from the Democrats, that just you're going to keep voting for the same thing and you're going to just suck it up because that's what happens in California. We need a plan to change policy for homelessness, not more of the same failed policy. [32:50] I was there in Altadena this week [32:53] and the money that's being withheld is actually the money that Gavin Newsom promised and they said that when you went there, you didn't even, you didn't even bother, you didn't bother to listen, you didn't bother to listen to the stories of local people who feel so terribly let down by the California government. And as usual, all he wants to talk about is federal politics. [35:20] Mr. Helton? I agree that we can't drive more tax revenue out of our state because we need that money here and this initiative would do that. But the priority has to be working people, not just making sure we don't drive the jobs out, but actually we create jobs and that we reduce taxes for people who are struggling. If you earn around $70 ,000 in California just above the typical individual earning, you're paying 9 .3 % tax. That's higher than the top rate in most states. He's got no plans to do anything about that. He's got to help working people. [36:29] votes? As I've said, I've got confidence in what we saw in the primary and in this process, but the thing that I can't believe is the attitude you get from the Democrats who've been running this state about our elections. We just had Karen Bass, the mayor of LA saying, we don't need an election for governor because the Democrat is going to win. And that is the attitude we get from these people who've been in charge of our state for 16 years, and they think that they can just do whatever they want, get whatever bad results, the highest taxes in the country for the worst results, taking everybody for granted, taking their votes for granted. That's why he's not trying to earn anybody's vote. That's why he hasn't been campaigning in this election. They take you for granted. And I just wanna ask every Californian, aren't you tired of that? It's time to try something different Instead of the same thing over and over again. He wasn't even supposed to be the candidate He was the sixth or seventh choice, but they said it doesn't matter as long as it's a D That'll do secretary won't do we need change in, California. Thank you. Just want to try something different. [38:33] Helm There's a majority in this state who agree that it's reasonable to show ID when you vote But the thing that we have to understand is that if we vote just as Javier said earlier if we vote the same way this state as we've been doing we're gonna get the same results and this attitude of just constantly talking about national politics because he's got nothing to offer to change the direction of this state when people are suffering so much and he takes no responsibility for the policies that he supported for the last 16 years of one -party rule is an insult to every California. [44:43] No, I'm pro -vaccine, but I think the data shows, when you look at different ways that this very, very emotional issue for a lot of parents has been handled, particularly since the pandemic, when Javier forced children to be vaccinated, when there was no public health or scientific justification for that whatsoever, forcing little babies and toddlers to wear masks, when there was no justification for that whatsoever, and it's become very contentious. And the evidence shows, as the current head of NIH has made clear, when you look at the data around the world, the places where the requirements, the mandates are lower, are the places where you actually have higher compliance, where parents don't feel that they're being bullied into doing something that they don't want to do. And that's what I wanna see here. [45:40] the law in California, in any case. Well, [45:45] the law much as Javier would like to, I'm sure, in many areas. I would follow the law, and I think that the evidence is that if we can move away from this over -prescriptive attitude where you're telling parents to use so many different vaccines that they're concerned about and actually do it without those kinds of mandates, The evidence from other places is you get higher compliance with the vaccines that are really important for public health. [47:16] guidance to the states? We gave guidance. That's not mandatory. Why did you [47:21] suggest forcefully that children should be given the COVID vaccine? [47:51] When he was HHS secretary, he suggested that children, young children, should wear masks, two and three -year -olds. That's right. mask, there was no public health justification for any of that. He went along with the groupthink. This is why you can't trust him because he's been a bureaucrat and a career politician all his life and he goes along with the groupthink instead of actually standing up for facts and in this case the science. He went against the science and along with the politics and the groupthink. That's why he can't be trusted. [49:16] Yes, and in fact, I will increase affordable, reliable healthcare for Californians. Right now, so many families and individuals have healthcare in name only, where they actually have such a high deductible and such a high premium that it doesn't really mean anything. That's why I've announced my plan for a working class healthcare guarantee that will have a low premium and a low deductible by cutting out the waste and the fraud in the system. The fraud, by the way, that Javier unleashed when he was HHS secretary, he dismantled the fraud unit at HHS. He changed the policy, so that hundreds of billions of dollars were lost in fraud. And when it comes to what he describes as cuts, it shows that first of all, he can't even do math because the amount of money is going up. But secondly, what he's really talking about are work requirements for Medicaid. And the same exact work requirements for Medicaid that have been put in place by the federal government have been matched by Gavin Newsom for the California part of the system. Thank you. So the question for him is, is he going to do that? [51:00] Mr. Helton? If you're against the work requirements, will you then remove them for the California part of the system in the way that Gavin Newsom has imposed them? Will you remove that? [51:45] So you're going to keep the Gavin Newsom [53:19] Mr. Allen, who's been in charge when all those jobs have gone? Donald Trump. When this industry has collapsed. The Democrats, the Democrats in California have run this state for 16 years. He asked me earlier not to interrupt. I see he's not following his own advice. That's okay. [53:36] The Democrats have been in charge for 16 years as the jobs have gone, the industries have gone, and this city, this iconic industry, is on the brink of collapse. And it's the same with so many other industries. Agriculture, which he helped destroy in this state by suing to stop our farmers getting the water that they need. My plan to bring Hollywood home would make us competitive with the best in the world and reduce the bureaucracy and the red tape, which also has been piled on by Javier and his friends. Let me clarify. [56:16] Mr. Hill. Well, none of that is true. What is true is that yet again he's talking as if someone else other than the Democrats, his party and his friends and his legislature in Sacramento that he did nothing to push back against when he was attorney general haven't actually been in charge of California's education system that spends nearly the highest amount in the entire country for some of the worst results. We need reform and change. We need to make sure that every student reads by third grade. We need to use phonics in our school system to teach kids to read. We need accountability for teachers and for individual schools. None of that will happen because he is sponsored by the teacher unions that have been such a big part of the problem in California. [57:27] about him. [57:28] We have some of the worst results in the country after 16 years of Javier and his policies being implemented in California. As you said, Jake, less than half the students read a grade level with math. It's 37%. It's a catastrophe for our young people. We cannot go on like this just as we can't go on with the highest cost of living, with the highest unemployment rate, with the worst homelessness. All of these things are the result of the policies that he wants to see more of. It can't happen in California. We've got to try something different. [58:26] This is the most amazing state in the most amazing country on earth. And it's because we've got this rebel spirit that we do things differently. people build, we can grow anything, build anything, make anything, invent anything. That spirit is being crushed by this bloated nanny state bureaucratic government that Javier has been a part of for 36 years and would continue. It's time to try something different, not least to reduce the cost of living. And so if we have his policies for another four years, the average, the Typical California household will pay $11 ,047 more. If I'm elected governor, the starting point will be to reduce that cost of living. $11 ,000 is what you'd save. And you can check out individually how much you'd save if you go to savewithsteve .vote. It's a practical plan to reduce your costs. And when we do that, we'll make California once again the best place to start and raise a family, to start and grow a business, the best place anywhere in the world.

---
snapshot_id: 475df7cf-be14-5439-a177-07eb4945a189
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/keep-california-the-ai-capital-of-the-world

Saved from https://stevehiltonforgovernor.com/policies/keep-california-the-ai-capital-of-the-world (rendered page text, built-in browser, 2026-10-07) POLICY KEEP CALIFORNIA THE AI CAPITAL OF THE WORLD ← POLICY ARCHIVE KEEP CALIFORNIA THE AI CAPITAL OF THE WORLD THE PROBLEM California leads the world in artificial intelligence today. But decisions being made in Sacramento risk driving this critical industry out of our state. After 16 years of one-party rule, the pattern is clear: more regulation, higher taxes, and greater political control. That approach has already pushed other industries out of California—and now it is being applied to one of the most important technologies of the future. This is not just about jobs or investment. Artificial intelligence is a foundational technology with major national security implications. The global race is happening now, largely between the United States and China. If California weakens its position, America’s leadership is weakened with it. At the same time, California is failing to prepare its own people for the changes AI will bring. Educational outcomes are declining despite increased spending: Only 47% of students meet basic English standards Only 35% meet basic math standards These failures leave millions unprepared for a more technical, fast-changing workforce. California risks pushing out the industries of the future while failing to prepare its workforce to participate in them. WHY THIS IS HAPPENING This problem stems from a governing approach that prioritizes regulation, restriction, and taxation over growth. California policymakers approach new technologies with excessive caution rather than confidence. Instead of supporting innovation, they impose sweeping rules before technologies are fully developed. At the same time, the state has neglected foundational systems: Schools focus on bureaucracy over outcomes Workforce training and vocational pathways are limited There are fewer clear routes into skilled, well-paying jobs AI also depends on physical infrastructure and reliable energy—areas where California has struggled due to high costs, supply constraints, and regulatory delays. THE THREAT California is already seeing the consequences of this approach. Proposed legislation would: Restrict how AI can be developed and used Increase liability under vague standards Add new layers of bureaucracy Examples include: AB 1979: restricting AI use in healthcare SB 420: imposing liability for “algorithmic discrimination” SB 813: creating a new AI regulatory commission These proposals risk slowing innovation, pushing investment elsewhere, and increasing government control over technology. Combined with proposals like taxing unrealized gains, these policies threaten the foundation of California’s startup ecosystem. Unless direction changes, it will become easier for innovators to build the future somewhere else. THE PLAN 1. EXTEND CALIFORNIA’S GLOBAL LEADERSHIP IN AI California must be the best place in the world to build, invest, and grow AI companies. That requires: A strong business climate Affordable infrastructure A well-educated workforce Government should enforce basic accountability—but avoid sweeping, preemptive regulation on evolving technologies. 2. SET CLEAR, COMMON-SENSE GUARDRAILS There are real risks, but solutions should be targeted and practical. Focus areas include: Protecting children Preventing fraud and impersonation Safeguarding intellectual property and identity The approach should: Enforce existing laws Close clear gaps Avoid vague, open-ended rules 3. COMPETE FOR THE FULL STACK OF AI JOBS California must capture the entire AI ecosystem, including: Energy Manufacturing Infrastructure Computing Software and applications Right now, many of these jobs are going elsewhere due to cost and regulatory barriers. Fixing this means: Faster approvals Lower barriers to building A clear commitment to growth 4. DELIVER ABUNDANT ENERGY AND INFRASTRUCTURE AI depends on reliable, affordable energy. California must shift from scarcity to abundance by: Expanding in-state energy production Modernizing the grid Removing barriers to infrastructure development This includes: Utilizing existing natural gas capacity Expanding nuclear power over time Meeting rising electricity demand must be treated as an urgent priority. 5. PREPARE CALIFORNIANS TO WIN IN THE AI ECONOMY The most important role of government is preparing people—not controlling technology. Current education outcomes are failing students and the workforce. Key priorities include: Ensuring literacy and math proficiency Using phonics-based instruction Holding schools accountable for performance Students should not advance without mastering fundamentals. In addition: Expand vocational and technical education Support retraining for displaced workers Change is coming. The goal is to ensure Californians can move forward—not fall behind. CONCLUSION California has all the advantages needed to lead the world in artificial intelligence—but those advantages are being undermined by bad policy decisions. The state faces a choice: Continue down a path of overregulation, high costs, and declining outcomes or Prioritize growth, innovation, and opportunity If California gets this right, it will lead the AI revolution for decades to come . ← Back to all policies

---
snapshot_id: f2b4d934-3450-57f5-80e5-5231208bbd33
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## debate — California Governor Debate (CBS and SF Examiner) - OTR page: https://ontherecord.empowered.vote/meetings/deb719ec-159d-41f7-bcd1-99f7e90d370f - Video: https://www.youtube.com/watch?v=-_LHkpd7PcM - Date on On the Record: 2026-05-15 - Kind: debate · Governor Debate (CBS and SF Examiner) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [7:19] the change we need is away from the policies that have brought us to the situation that all the people on this stage described there's a difference though only two of us here actually represent real change away from that like millions of people before me I came to this state in search of a dream like my parents who left communist Hungary to England in search of freedom I was brought up in a working -class immigrant family I made it to Oxford University started a business worked in 10 Downing Street came here in 2012 my wife and my two sons taught at Stanford started a business and now leading the race for governor I want every single one of you to know that I see you I believe in you I won't accept that the California dream is something we talk about in the past tense wherever you want to go I want to clear the barriers away more money in your pocket your first hundred grand tax -free enough with the bureaucracy and the nonsense we will restore the California dream [15:51] I love the way Matt talks about how he's gonna lower costs when his city was recently rated the most expensive the least affordable for housing in the world [16:06] he's not fixing it because he's not fixing it because we're building housing are as high this year as they ever were all the plans he talks about have not actually reduced the cost of housing because fundamentally he supports the policies that have made housing and gas the most expensive in the country we need a change from those policies not more of the same I [22:13] well I don't think it's fair that California taxpayers who can barely afford their own health coverage should be paying for the health care of citizens of other countries and if you look at the record of Javier it's exactly what was just saying that you cannot believe that any change will come from these people he as health secretary dismantled the unit and HHS that was supposed to crack down on fraud billions of dollars of fraud as a result of his rule as HHS secretary and there's another point I think we have to acknowledge we learned today that Javier implicated in this corruption scandal today we learned that he knew about illegal and improper payments from his campaign account to his former chief of staff honestly it pains me to say because I like you personally Javier but you shouldn't be on thanks a lot you shouldn't be in this race you should be preparing your criminal defense [24:32] it Javier [24:34] talk about your chief of staff who said that you knew about these payments let's talk about [27:23] in the polls I think I get [34:30] no instead of forcing housing into places that don't want it we need to build housing in the places that do want it and I'm afraid all this conversation around housing we're not thinking big enough it's all just fiddling around the edges it's a crisis here in California so many young people I see they've given up on the idea that they could ever own their own home we need to build outwards not just upwards with apartment building shoved into suburban neighbors you know that only 6 % of our land is developed in California we could increase that to 7 % and there would be room for 10 million households and single -family homes so that young families could see their kids play outside in California we need to think big again back to the days when we used to build amazing things in California the suburbs of Southern California the state water project we should be thinking about how we store the ambition the abundance of California [41:20] believe a word he's saying his party increased those regulations mr. [47:06] yeah and we need to have common sense on climate change not ideology that ends up being counterproductive and exactly as Chad said hurting every small business and family and everyone in California I'm an environmentalist we love our beautiful natural landscapes our climate here in California we've got to protect that clean air clean water of course that's right but look at some of the things that we're doing in the name of climate change the wildfires that occurred in the Sierras in 2020 because the forests weren't managed properly the co2 emissions from that one year of mega wildfires wiped out all the savings from climate policy in the previous 20 years look at what's going on with our gas prices the highest in the country because instead of getting oil and gas from our own oil production here in California we are shipping it 7 ,500 miles in giant super tankers spewing out carbon emissions in the name of climate we are increasing carbon emissions we need some common sense here [48:55] a [49:54] look I don't know if you know how many EVs are on the roads in California the proportion the idea that that's gonna actually half of the [50:10] number man statewide yeah [50:13] do you know [50:14] it's another percentage of our vehicles on the roads [50:19] 7 % and he wants and it's power our power grid with that it's a lot of batteries this is what you get tell me the math on the batteries thank you you get from ideologues who are not actually it's actually called innovation [50:33] very much how we fix things how to make things work [58:01] Yes. We have to lower gas prices. [58:15] No. [69:28] We need to make it easier for working -class Californians to get into the UC system. As we used to, the costs are so high, the structure of the courses, all of this needs to change. I don't believe in artificial caps and regulation. That's the kind of policy that has got us into this mess. And I have to say, listening to my Democrat friends here, talking about education, it's as if they haven't been in charge for the last 16 years. They are the policies that they support that have got us to a position where less than half the kids in our schools can read at grade level. For math it's 35%. We need new management in this state if we're going to turn things around. We can't have more of the same. We need to make sure we use phonics to teach kids to read. Make sure that they can read by third grade. And like Mississippi does, not go to fourth grade if that doesn't happen. We need to hold teachers accountable also to make sure that we reform the pensions because right now 10 and a quarter percent of every teacher's salary is going towards their pension. We need that to change as well. [73:37] This is not about abortion rights. This is about one state trying to undermine another state's laws. We have a federal system. Yes or no, Mr. Hilton? Sorry? [73:47] Yes, I would follow the law, and that's because we have a constitution in this country that we need to [73:56] abortion rights. Mr. Steyer? It is about abortion. No, it isn't. [73:59] Undermine democracy in another state. Thank you, Mr. Hilton. The people in that state chose differently to California. [74:07] interfere in another state's laws in that way? Mr. [74:12] don't want Louisiana dictating our laws. We shouldn't be dictating Louisiana. Maybe you ought to run for governor. Mr. [74:22] Hell no. [74:56] I'm afraid it's not as simple as that. It really isn't. No, I'm serious. This is exactly the reason we get in. This [75:04] it's not the right way to discuss a very important and serious issue. Do you think there should be more safeguards on AI bots that interact with children? No, I'm sorry. This is why we get into a problem in this country, because we go for these simplistic solutions. Thank you, Mr. Hilton. Mr. Steyer, do you have an answer for me? And it causes problems that are unintended. And we need to have a serious conversation about a very serious issue. We have to protect children, but do it in a sensible way that works. Look at these policies that are being implemented around the world. Okay, Mr. Hilton, I have to move forward. Like in Australia, they don't work. [75:37] It's really not. [75:51] Yes or no questions. They're a little bit longer. Sometimes. [77:08] This state is desperate for change. We cannot have another four years of one -party rule. We need some balance. The only choice for change, apart from myself, is Chad. [80:31] I think we get it, Tom. You're a billionaire. Congratulations. Look, I get on with Tom. I get on with everyone on this stage, and we're all here for the same reason. We love this state, and we want it to be the state that once again offers young people the opportunity to make your life here better than anywhere else in our country. The truth is that we've gone off track. We've got one party rule now for 16 years. The results have been such a disappointment. It is time for some balance. We need some balance in our system. No more one party rule. And the reason that I can make the change happen is precisely because I get on with people from all different backgrounds. I'm not an ideologue. I'm pragmatic. I'm a problem solver. Most of my career has been in business, but I have experience working inside of a government. Above all, I know how to work with people to make change happen. That's what we need in California. Common sense, practical ideas to turn things around and restore the California dream.