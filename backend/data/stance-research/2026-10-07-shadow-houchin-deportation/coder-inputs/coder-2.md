You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-houchin-deportation/labels/coder-2.json. Write JSON only, matching
codebook Part E, with "codebook_version": "0.4" and "coder_slot": 2. One row per
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

### topic_key: deportation
topic_id: 44905f3b-e105-4f6c-afc7-5d223813dbac  served_revision_id: 55c3167e-3ad8-425d-a699-b2e91552d912
Question: How far should the government go in deporting undocumented immigrants?
  1. Stop deportations entirely and protect undocumented immigrants from removal
  2. Only deport undocumented immigrants convicted of serious violent crimes
  3. Focus deportation on recent arrivals while leaving long-settled undocumented immigrants in place
  4. Deport all undocumented immigrants, starting with those who have criminal records
  5. Carry out a mass-deportation program to remove all undocumented immigrants, including long-settled families and workers

#### Annex

# deportation — served revision 55c3167e-3ad8-425d-a699-b2e91552d912 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How far should the government go in deporting undocumented immigrants?"

**Orientation:** standard. Rung 1 removes no one, rung 5 removes everyone through a dedicated
programme. The rungs order **how many undocumented immigrants the government removes**, and which
groups are left in place. Do not read the number as "more government": rung 1 is the least removal.

**Levels with a lever:** federal. Removal is a federal lever (Congress
sets who is removable and funds enforcement). State officials cannot deport anyone; at state level
most rungs can only be evidenced by own words.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: state, local (codebook V2 "No-lever level").

**Synonyms:** "removal", "deportation", "removal proceedings", "expedited removal", "enforcement
priorities", "interior enforcement", "detainer", "287(g)", "mass deportation", "self-deportation",
"long-term residents", "Dreamers", "DACA", "Temporary Protected Status" (TPS), "parole", "path to
citizenship", "legalization", "amnesty".

1. **"Stop deportations entirely and protect undocumented immigrants from removal"**
   - Means: no undocumented immigrant is removed.
   - Operative clauses: [a] stop all deportations; [b] protect undocumented immigrants from removal.
   - Establishing evidence looks like: own words that call for an end to every removal; an instrument
     that bars removal of all undocumented immigrants. "Entirely" is an absence clause: the passage
     must say that no one is removed (V4.2 "Silence is not a clause").
   - Levels that hold a lever: federal. State: own words only.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a **time-limited moratorium** on removals reads like
     "stop entirely". A pause for a fixed period does not say removals should never resume →
     `direction-only` _(proposed)_.
   - Commonly confused with BLANK because protecting **one group** (young people brought as
     children, TPS holders) is protection from removal. It says nothing about everyone else →
     `direction-only` _(proposed)_.

2. **"Only deport undocumented immigrants convicted of serious violent crimes"**
   - Means: removal is for people convicted of serious violent crimes, and for no one else.
   - Operative clauses: [a] deport those convicted of serious violent crimes; [b] "only" — no one else.
   - Establishing evidence looks like: own words or an instrument that limits removal to this group.
     [b] must be stated; a call to deport violent offenders that is silent on everyone else meets [a]
     only → `direction-only`.
   - Levels that hold a lever: federal. State: own words only.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because rung 4 also starts with criminal records. Rung 4 then
     removes everyone; rung 2 stops at serious violent convictions. "Deport criminals first" does not
     separate the two → `direction-only` _(proposed)_.
   - A bill that requires detention or removal of people **charged with** (not convicted of) a crime,
     or of lesser crimes, does not match [a] or [b]. It shows the enforcement side only →
     `direction-only` _(proposed)_.

3. **"Focus deportation on recent arrivals while leaving long-settled undocumented immigrants in
   place"**
   - Means: removal falls on people who arrived recently; people settled here a long time stay.
   - Operative clauses: [a] removal focused on recent arrivals; [b] long-settled undocumented
     immigrants left in place.
   - Establishing evidence looks like: own words or an instrument that does both — for example, a
     legalization for people present a long time, together with removal of recent arrivals.
     Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: federal. State: own words only.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with `border-security` because quick removal of people **at the border** is
     that topic's question. A passage only about people turned back at or near the border meets
     [a] at most; it says nothing about [b] _(proposed)_.

4. **"Deport all undocumented immigrants, starting with those who have criminal records"**
   - Means: every undocumented immigrant is removed in time, with criminal records first.
   - Operative clauses: [a] deport all; [b] those with criminal records first.
   - Establishing evidence looks like: own words that name both the goal (all) and the order
     (criminal records first). Compound: one side only → `compound-partial` (V4.2) _(proposed)_.
   - Levels that hold a lever: federal. State: own words only.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2: see rung 2.
   - Commonly confused with rung 5 because both remove everyone. Rung 5 names a dedicated programme
     and names long-settled families and workers. A passage that calls for a
     mass-deportation programme **and** says it starts with criminal records → rung 4, unless it
     also names long-settled families or workers (then rung 5). "Mass deportation" is a label, not a
     clause (H13) _(ruled 2026-10-01)_.

5. **"Carry out a mass-deportation program to remove all undocumented immigrants, including
   long-settled families and workers"**
   - Means: the government runs a deliberate, large-scale programme that removes every undocumented
     immigrant, with no exception for how long a person has lived here or for family or work ties.
   - Operative clauses: [a] a mass-deportation programme; [b] remove all; [c] including long-settled
     families and workers.
   - Establishing evidence looks like: own words that call for such a programme and reject exceptions
     for long-settled people. [c] must be stated; "deport all illegal immigrants" without it meets
     [b] only → `compound-partial` _(proposed)_.
   - Levels that hold a lever: federal. State: own words only.
   - Known chair-shaped instruments: _(none on file)_.
   - Speed is no longer the rung-4 / rung-5 line; the **programme** and clause [c] are. "Faster
     removals" alone does not reach rung 5 _(proposed)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Cooperation with federal enforcement.** A state law that limits state and local cooperation with
  federal immigration enforcement (detainers, information sharing, use of local resources) does not
  say who should be deported. That is the `local-immigration` question → V2 `adjacent`; BLANK
  `no-evidence` when nothing else survives — not `direction-only`.
- A law that **requires** state or local cooperation is the same question from the other side →
  `adjacent` _(proposed)_.
- **Enforcement funding.** Money for detention beds, officers or removal flights shows the
  enforcement side; it does not say who is removed → `direction-only`. Inside an appropriations or
  reconciliation bill → V4 `multi-subject`.
- **Legal-status bills** (a path to citizenship for one group, TPS designations, visa changes) protect
  a group; they do not set the removal rule for everyone → `direction-only` unless the passage also
  states that rule _(proposed)_.
- **State criminal-entry laws** that let state courts order a person to leave the state speak to
  removal of recent crossers, not to all undocumented immigrants → `direction-only` _(proposed)_.
- **Preemption (codebook V2, H12)** → `adjacent`.


## Sources

---
snapshot_id: 3c953450-c4ad-569e-8eeb-1e137bee59c8
source_kind: own-site (the person's own site or account)
url: https://houchin.house.gov/media/press-releases/houchin-fong-and-obernolte-introduce-dalilah-law-remove-illegal-truck-drivers

Houchin, Fong, and Obernolte Introduce Dalilah Law to Remove Illegal Truck Drivers from U.S. Roads | Congresswoman Erin Houchin Skip to main content 342 Cannon House Office Building, Washington, DC 20515 Email Me (202) 225-5315 About Committees and Caucuses Our District Votes and Legislation Contact Newsletter Subscribe Office Locations Media Press Releases Issues Agriculture Economy Education Energy Health Veterans Border Security Services Art Competition Congressional App Challenge Congressional Commendations Flags Grant Applicants Help with a Federal Agency Internships Service Academy Nominations Tours and Tickets America 250 Attention Seniors - Fraud Alert! Casework Success Stories Community Project Funding Help for Veterans Subscribe X How Can I Help? Home Media Press Releases Houchin, Fong, and Obernolte Introduce Dalilah Law to Remove Illegal Truck Drivers from U.S. Roads March 5, 2026 Press Release WASHINGTON, D.C. — U.S. Representative Erin Houchin (IN-09), alongside Representatives Vince Fong (CA-20) and Jay Obernolte (CA-23), recently introduced H.R. 7793 , the Dalilah Law, legislation that would prevent illegal aliens from obtaining commercial driver’s licenses (CDLs) and operating commercial trucks on American roadways. The legislation follows President Donald Trump’s call during the State of the Union for Congress to pass the Dalilah Law. Companion legislation was introduced by U.S. Senator Jim Banks (R-Ind.). The bill is inspired by Dalilah Coleman, a first grader who was severely injured in a six-car pileup caused by an illegal alien driving a semi-truck. The crash left Dalilah with life-altering injuries and required months of hospitalization and treatment. "No father should ever have to watch his little girl fight for her life the way I watched Dalilah. The months in the hospital, the surgeries, the pain she endured. No child should ever go through that. When President Trump recognized Dalilah at the State of the Union, I felt like our country was finally listening. I am so grateful to Congresswoman Houchin and Senator Banks for fighting to make sure this never happens to another family. This law will save lives, and that means everything to us. #StandWithDalilah," said Marcus Coleman, Dalilah's father. “Hoosiers are dying at the hands of illegal aliens, and Washington cannot ignore it any longer,” said Rep. Houchin. “Families should never fear who is behind the wheel of an 80,000-pound truck on our highways. The Dalilah Law ensures commercial driver’s licenses are limited to individuals who are lawfully present in the United States and able to meet the safety standards required to operate these massive vehicles.” “I’m grateful Rep. Houchin is leading the fight in the House on our legislation to get illegal truck drivers off our roads,” said Senator Banks. “Illegal aliens have killed too many Hoosiers on our highways and we must act. President Trump called on Congress to pass the Dalilah Law in his State of the Union. It’s time to get it done.” “Dalilah’s story is a heartbreaking reminder that border security and public safety are not abstract issues; they impact real families right here in our community,” said Rep. Fong. “What’s worse is that this tragedy could have been prevented if California did not grant commercial driver’s licenses to those in our country illegally. Politics should never be put ahead of public safety. Our laws must meet the safety standards required to operate big rigs on our roadways. We owe it to families like the Colemans to pursue commonsense reforms like the Dalilah Law that uphold the rule of law and protect Americans who travel our roads.” “Dalilah’s story is a heartbreaking reminder that public safety must always come first,” said Rep. Obernolte. “This legislation ensures that commercial driver’s licenses are issued only to United States citizens, lawful permanent residents, and those lawfully authorized to work here. I am proud to support this bill to strengthen highway safety, restore accountability, and honor Dalilah and her family by working to prevent tragedies like this from happening again.” The legislation would require states to limit commercial driver’s licenses to U.S. citizens, lawful permanent residents, and certain work visa holders as a condition of receiving federal Department of Transportation funding. It would also require states to revoke CDLs issued to illegal aliens and require CDL knowledge and skills tests to be administered in English. Recent crashes involving illegal alien truck drivers in Indiana have raised concerns about highway safety and the need for stronger safeguards to ensure only legally authorized drivers are operating commercial vehicles on America’s roads. Read the full bill text here . Issues : Border Security Office Locations Washington DC Office 342 Cannon House Office Building Washington, DC 20515 Phone: (202) 225-5315 Salem District Office 104 W Hackberry Street Salem, IN 47167 Phone: (812) 288-3999 Top Copyright Privacy House.gov Accessibility RSS

---
snapshot_id: df91a342-7f02-503c-89cc-a4e9ece748d6
source_kind: public-record
url: https://clerk.house.gov/Votes/202523

Office of the Clerk, U.S. House of Representatives Find Your Representative Search Office of the Clerk Toggle navigation Search Office of the Clerk Search button Legislative Information Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions 119th Congress, 2nd Session House Not In Session Next Session: October 9th, 2026 at 12:30 PM House Floor Proceedings Watch live.house.gov Additional Resources Votes Legacy View - 2024 119th Congress Nominees Statistics of the 2024 Congressional Election Final House Calendar (118th Congress) Résumé of Congressional Activity Legislative Search Congressional Record U.S. Senate House Schedule Bills This Week House Voting Days Member Information Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Republicans 218 218 Democrats 214 214 Independents 1 1 Vacancies 2 2 Republican Leadership Rep. Mike Johnson Speaker of the House Rep. Steve Scalise Majority Leader Rep. Tom Emmer Majority Whip Rep. Lisa C. McClain Republican Conference Chair Rep. Jay Obernolte Republican Policy Committee Chair Democratic Leadership Rep. Hakeem S. Jeffries Minority Leader Rep. Katherine M. Clark Minority Whip Rep. Pete Aguilar Democratic Caucus Chair Rep. Ted Lieu Democratic Caucus Vice Chair Additional Resources Find Your Representative Official List of Members by State Official Member Telephone Directory Duplicate and Similar Names of Members Terms of Service Mailing Labels [ MS Word | Text File ] Member Data [ Excel | XML | User Guide ] Biographical Directory Members on Congress.gov Committee Information COMMITTEE INFORMATION COMMITTEE PROFILES Agriculture Appropriations Armed Services Budget Education and Workforce Energy and Commerce Ethics Financial Services Foreign Affairs Homeland Security House Administration Judiciary Natural Resources Oversight and Government Reform Rules Science, Space, and Technology Small Business Transportation and Infrastructure Veterans' Affairs Ways and Means Select Intelligence Select Strategic Competition Joint Economic Joint Library Joint Printing Joint Taxation Additional Resources Official List of Members with Committee Assignments Official List of Standing Committees and Subcommittees Committee Repository Committee Reports Committees on Congress.gov Committee Data [ Excel ] Disclosures Disclosures PUBLIC DISCLOSURE Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications Additional Resources Lobbying Disclosures Public Laws Lobbying Disclosure Act About the Clerk About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office The Clerk of the House The Honorable Kevin F. McCumber Clerk of the U.S. House of Representatives Deputy Clerk Michelle H. Reinshuttle Deputy Clerk Contact Information Mailing Address U.S. Capitol Room H154 Washington, DC 20515&ndash;6601 Telephone Number (202) 225&ndash;7000 Office Hours 9:00 AM&ndash;6:00 PM, Monday&ndash;Friday Additional Resources Artificial Intelligence Use Case Inventory [ USHouse-Clerk-1: Comparative Print Suite ] 119th Congress, 2nd Session Back to Previous Page Roll Call 23 | Bill Number: S. 5 Share XML View | HTML View Jan 22, 2025, 05:01 PM | 119th Congress, 1st Session Vote Question: On Passage Laken Riley Act Vote Type: Yea-And-Nay Status: Passed VOTES yea: 263 nay: 156 present: 0 not voting: 14 Remote Voting by Proxy Votes by party votes by party Party Yeas Nays Present Not Voting Republican 217 0 0 1 Democratic 46 156 0 13 Independent 0 0 0 0 Total 263 156 0 14 All votes Keyword Name Party All Parties Republican Democratic Independent State All States Votes All Votes YEA/AYE NAY/NO PRESENT NOT VOTING All votes Representative Party State Vote Adams Adams Democratic North Carolina NC Nay Aderholt Aderholt Republican Alabama AL Yea Aguilar Aguilar Democratic California CA Nay Alford Alford Republican Missouri MO Yea Allen Allen Republican Georgia GA Yea Amo Amo Democratic Rhode Island RI Nay Amodei (NV) Amodei (NV) Republican Nevada NV Yea Ansari Ansari Democratic Arizona AZ Nay Arrington Arrington Republican Texas TX Yea Auchincloss Auchincloss Democratic Massachusetts MA Nay Babin Babin Republican Texas TX Yea Bacon Bacon Republican Nebraska NE Yea Baird Baird Republican Indiana IN Yea Balderson Balderson Republican Ohio OH Yea Balint Balint Democratic Vermont VT Nay Barr Barr Republican Kentucky KY Yea Barragán Barragan Democratic California CA Nay Barrett Barrett Republican Michigan MI Yea Baumgartner Baumgartner Republican Washington WA Yea Bean (FL) Bean (FL) Republican Florida FL Yea Beatty Beatty Democratic Ohio OH Nay Begich Begich Republican Alaska AK Yea Bell Bell Democratic Missouri MO Nay Bentz Bentz Republican Oregon OR Yea Bera Bera Democratic California CA Nay Bergman Bergman Republican Michigan MI Yea Beyer Beyer Democratic Virginia VA Nay Bice Bice Republican Oklahoma OK Yea Biggs (AZ) Biggs (AZ) Republican Arizona AZ Yea Biggs (SC) Biggs (SC) Republican South Carolina SC Yea Bilirakis Bilirakis Republican Florida FL Yea Bishop Bishop Democratic Georgia GA Yea Boebert Boebert Republican Colorado CO Yea Bonamici Bonamici Democratic Oregon OR Nay Bost Bost Republican Illinois IL Yea Boyle (PA) Boyle (PA) Democratic Pennsylvania PA Yea Brecheen Brecheen Republican Oklahoma OK Yea Bresnahan Bresnahan Republican Pennsylvania PA Yea Brown Brown Democratic Ohio OH Nay Brownley Brownley Democratic California CA Nay Buchanan Buchanan Republican Florida FL Yea Budzinski Budzinski Democratic Illinois IL Yea Burchett Burchett Republican Tennessee TN Yea Burlison Burlison Republican Missouri MO Yea Bynum Bynum Democratic Oregon OR Yea Calvert Calvert Republican California CA Yea Cammack Cammack Republican Florida FL Yea Carbajal Carbajal Democratic California CA Nay Carey Carey Republican Ohio OH Yea Carson Carson Democratic Indiana IN Nay Carter (GA) Carter (GA) Republican Georgia GA Yea Carter (LA) Carter (LA) Democratic Louisiana LA Nay Carter (TX) Carter (TX) Republican Texas TX Yea Casar Casar Democratic Texas TX Nay Case Case Democratic Hawaii HI Nay Casten Casten Democratic Illinois IL Nay Castor (FL) Castor (FL) Democratic Florida FL Nay Castro (TX) Castro (TX) Democratic Texas TX Nay Cherfilus-McCormick Cherfilus-McCormick Democratic Florida FL Nay Chu Chu Democratic California CA Nay Ciscomani Ciscomani Republican Arizona AZ Yea Cisneros Cisneros Democratic California CA Nay Clark (MA) Clark (MA) Democratic Massachusetts MA Nay Clarke (NY) Clarke (NY) Democratic New York NY Nay Cleaver Cleaver Democratic Missouri MO Nay Cline Cline Republican Virginia VA Yea Cloud Cloud Republican Texas TX Yea Clyburn Clyburn Democratic South Carolina SC Nay Clyde Clyde Republican Georgia GA Yea Cohen Cohen Democratic Tennessee TN Nay Cole Cole Republican Oklahoma OK Yea Collins Collins Republican Georgia GA Yea Comer Comer Republican Kentucky KY Yea Conaway Conaway Democratic New Jersey NJ Nay Connolly Connolly Democratic Virginia VA Nay Correa Correa Democratic California CA Not Voting Costa Costa Democratic California CA Yea Courtney Courtney Democratic Connecticut CT Yea Craig Craig Democratic Minnesota MN Yea Crane Crane Republican Arizona AZ Yea Crank Crank Republican Colorado CO Yea Crawford Crawford Republican Arkansas AR Yea Crenshaw Crenshaw Republican Texas TX Yea Crockett Crockett Democratic Texas TX Nay Crow Crow Democratic Colorado CO Nay Cuellar Cuellar Democratic Texas TX Yea Davids (KS) Davids (KS) Democratic Kansas KS Yea Davidson Davidson Republican Ohio OH Yea Davis (IL) Davis (IL) Democratic Illinois IL Nay Davis (NC) Davis (NC) Democratic North Carolina NC Yea De La Cruz De La Cruz Republican Texas TX Yea Dean (PA) Dean (PA) Democratic Pennsylvania PA Nay DeGette DeGette Democratic Colorado CO Nay DeLauro DeLauro Democratic Connecticut CT Nay DelBene DelBene Democratic Washington WA Nay Deluzio Deluzio Democratic Pennsylvania PA Nay DeSaulnier DeSaulnier Democratic California CA Nay DesJarlais DesJarlais Republican Tennessee TN Yea Dexter Dexter Democratic Oregon OR Nay Diaz-Balart Diaz-Balart Republican Florida FL Yea Dingell Dingell Democratic Michigan MI Not Voting Doggett Doggett Democratic Texas TX Nay Donalds Donalds Republican Florida FL Yea Downing Downing Republican Montana MT Yea Dunn (FL) Dunn (FL) Republican Florida FL Yea Edwards Edwards Republican North Carolina NC Yea Elfreth Elfreth Democratic Maryland MD Nay Ellzey Ellzey Republican Texas TX Yea Emmer Emmer Republican Minnesota MN Yea Escobar Escobar Democratic Texas TX Nay Espaillat Espaillat Democratic New York NY Nay Estes Estes Republican Kansas KS Yea Evans (CO) Evans (CO) Republican Colorado CO Yea Evans (PA) Evans (PA) Democratic Pennsylvania PA Nay Ezell Ezell Republican Mississippi MS Yea Fallon Fallon Republican Texas TX Yea Fedorchak Fedorchak Republican North Dakota ND Yea Feenstra Feenstra Republican Iowa IA Yea Fields Fields Democratic Louisiana LA Nay Figures Figures Democratic Alabama AL Yea Finstad Finstad Republican Minnesota MN Yea Fischbach Fischbach Republican Minnesota MN Yea Fitzgerald Fitzgerald Republican Wisconsin WI Yea Fitzpatrick Fitzpatrick Republican Pennsylvania PA Yea Fleischmann Fleischmann Republican Tennessee TN Yea Fletcher Fletcher Democratic Texas TX Nay Flood Flood Republican Nebraska NE Yea Fong Fong Republican California CA Yea Foster Foster Democratic Illinois IL Nay Foushee Foushee Democratic North Carolina NC Nay Foxx Foxx Republican North Carolina NC Yea Frankel, Lois Frankel, Lois Democratic Florida FL Nay Franklin, Scott Franklin, Scott Republican Florida FL Yea Friedman Friedman Democratic California CA Nay Frost Frost Democratic Florida FL Nay Fry Fry Republican South Carolina SC Yea Fulcher Fulcher Republican Idaho ID Yea Garamendi Garamendi Democratic California CA Not Voting Garbarino Garbarino Republican New York NY Yea Garcia (CA) Garcia (CA) Democratic California CA Nay García (IL) Garcia (IL) Democratic Illinois IL Nay Garcia (TX) Garcia (TX) Democratic Texas TX Nay Gill (TX) Gill (TX) Republican Texas TX Yea Gillen Gillen Democratic New York NY Yea Gimenez Gimenez Republican Florida FL Yea Golden (ME) Golden (ME) Democratic Maine ME Yea Goldman (NY) Goldman (NY) Democratic New York NY Nay Goldman (TX) Goldman (TX) Republican Texas TX Yea Gomez Gomez Democratic California CA Nay Gonzales, Tony Gonzales, Tony Republican Texas TX Yea Gonzalez, V. Gonzalez, V. Democratic Texas TX Yea Gooden Gooden Republican Texas TX Yea Goodlander Goodlander Democratic New Hampshire NH Yea Gosar Gosar Republican Arizona AZ Yea Gottheimer Gottheimer Democratic New Jersey NJ Yea Graves Graves Republican Missouri MO Yea Gray Gray Democratic California CA Yea Green (TN) Green (TN) Republican Tennessee TN Yea Green, Al (TX) Green, Al (TX) Democratic Texas TX Nay Greene (GA) Greene (GA) Republican Georgia GA Yea Griffith Griffith Republican Virginia VA Yea Grijalva Grijalva Democratic Arizona AZ Not Voting Grothman Grothman Republican Wisconsin WI Yea Guest Guest Republican Mississippi MS Yea Guthrie Guthrie Republican Kentucky KY Yea Hageman Hageman Republican Wyoming WY Yea Hamadeh (AZ) Hamadeh (AZ) Republican Arizona AZ Yea Harder (CA) Harder (CA) Democratic California CA Yea Haridopolos Haridopolos Republican Florida FL Yea Harrigan Harrigan Republican North Carolina NC Yea Harris (MD) Harris (MD) Republican Maryland MD Yea Harris (NC) Harris (NC) Republican North Carolina NC Yea Harshbarger Harshbarger Republican Tennessee TN Yea Hayes Hayes Democratic Connecticut CT Yea Hern (OK) Hern (OK) Republican Oklahoma OK Yea Higgins (LA) Higgins (LA) Republican Louisiana LA Yea Hill (AR) Hill (AR) Republican Arkansas AR Yea Himes Himes Democratic Connecticut CT Nay Hinson Hinson Republican Iowa IA Yea Horsford Horsford Democratic Nevada NV Yea Houchin Houchin Republican Indiana IN Yea Houlahan Houlahan Democratic Pennsylvania PA Nay Hoyer Hoyer Democratic Maryland MD Nay Hoyle (OR) Hoyle (OR) Democratic Oregon OR Nay Hudson Hudson Republican North Carolina NC Yea Huffman Huffman Democratic California CA Nay Huizenga Huizenga Republican Michigan MI Yea Hunt Hunt Republican Texas TX Yea Hurd (CO) Hurd (CO) Republican Colorado CO Yea Issa Issa Republican California CA Yea Ivey Ivey Democratic Maryland MD Nay Jack Jack Republican Georgia GA Yea Jackson (IL) Jackson (IL) Democratic Illinois IL Nay Jackson (TX) Jackson (TX) Republican Texas TX Yea Jacobs Jacobs Democratic California CA Nay James James Republican Michigan MI Yea Jayapal Jayapal Democratic Washington WA Not Voting Jeffries Jeffries Democratic New York NY Nay Johnson (GA) Johnson (GA) Democratic Georgia GA Nay Johnson (LA) Johnson (LA) Republican Louisiana LA Yea Johnson (SD) Johnson (SD) Republican South Dakota SD Yea Johnson (TX) Johnson (TX) Democratic Texas TX Nay Jordan Jordan Republican Ohio OH Yea Joyce (OH) Joyce (OH) Republican Ohio OH Yea Joyce (PA) Joyce (PA) Republican Pennsylvania PA Yea Kamlager-Dove Kamlager-Dove Democratic California CA Nay Kaptur Kaptur Democratic Ohio OH Yea Kean Kean Republican New Jersey NJ Yea Keating Keating Democratic Massachusetts MA Nay Kelly (IL) Kelly (IL) Democratic Illinois IL Nay Kelly (MS) Kelly (MS) Republican Mississippi MS Yea Kelly (PA) Kelly (PA) Republican Pennsylvania PA Yea Kennedy (NY) Kennedy (NY) Democratic New York NY Nay Kennedy (UT) Kennedy (UT) Republican Utah UT Yea Khanna Khanna Democratic California CA Nay Kiggans (VA) Kiggans (VA) Republican Virginia VA Yea Kiley (CA) Kiley (CA) Republican California CA Yea Kim Kim Republican California CA Yea Knott Knott Republican North Carolina NC Yea Krishnamoorthi Krishnamoorthi Democratic Illinois IL Nay Kustoff Kustoff Republican Tennessee TN Yea LaHood LaHood Republican Illinois IL Yea LaLota LaLota Republican New York NY Yea LaMalfa LaMalfa Republican California CA Yea Landsman Landsman Democratic Ohio OH Yea Langworthy Langworthy Republican New York NY Yea Larsen (WA) Larsen (WA) Democratic Washington WA Nay Larson (CT) Larson (CT) Democratic Connecticut CT Nay Latimer Latimer Democratic New York NY Nay Latta Latta Republican Ohio OH Yea Lawler Lawler Republican New York NY Yea Lee (FL) Lee (FL) Republican Florida FL Yea Lee (NV) Lee (NV) Democratic Nevada NV Yea Lee (PA) Lee (PA) Democratic Pennsylvania PA Nay Leger Fernandez Leger Fernandez Democratic New Mexico NM Nay Letlow Letlow Republican Louisiana LA Yea Levin Levin Democratic California CA Yea Liccardo Liccardo Democratic California CA Nay Lieu Lieu Democratic California CA Nay Lofgren Lofgren Democratic California CA Nay Loudermilk Loudermilk Republican Georgia GA Yea Lucas Lucas Republican Oklahoma OK Yea Luna Luna Republican Florida FL Yea Luttrell Luttrell Republican Texas TX Yea Lynch Lynch Democratic Massachusetts MA Yea Mace Mace Republican South Carolina SC Yea Mackenzie Mackenzie Republican Pennsylvania PA Yea Magaziner Magaziner Democratic Rhode Island RI Nay Malliotakis Malliotakis Republican New York NY Yea Maloy Maloy Republican Utah UT Yea Mann Mann Republican Kansas KS Yea Mannion Mannion Democratic New York NY Yea Massie Massie Republican Kentucky KY Yea Mast Mast Republican Florida FL Yea Matsui Matsui Democratic California CA Nay McBath McBath Democratic Georgia GA Yea McBride McBride Democratic Delaware DE Nay McCaul McCaul Republican Texas TX Yea McClain McClain Republican Michigan MI Yea McClain Delaney McClain Delaney Democratic Maryland MD Yea McClellan McClellan Democratic Virginia VA Nay McClintock McClintock Republican California CA Yea McCollum McCollum Democratic Minnesota MN Nay McCormick McCormick Republican Georgia GA Yea McDonald Rivet McDonald Rivet Democratic Michigan MI Yea McDowell McDowell Republican North Carolina NC Yea McGarvey McGarvey Democratic Kentucky KY Nay McGovern McGovern Democratic Massachusetts MA Nay McGuire McGuire Republican Virginia VA Yea McIver McIver Democratic New Jersey NJ Nay Meeks Meeks Democratic New York NY Nay Menendez Menendez Democratic New Jersey NJ Nay Meng Meng Democratic New York NY Nay Messmer Messmer Republican Indiana IN Yea Meuser Meuser Republican Pennsylvania PA Yea Mfume Mfume Democratic Maryland MD Nay Miller (IL) Miller (IL) Republican Illinois IL Yea Miller (OH) Miller (OH) Republican Ohio OH Yea Miller (WV) Miller (WV) Republican West Virginia WV Yea Miller-Meeks Miller-Meeks Republican Iowa IA Yea Mills Mills Republican Florida FL Yea Min Min Democratic California CA Yea Moolenaar Moolenaar Republican Michigan MI Yea Moore (AL) Moore (AL) Republican Alabama AL Yea Moore (NC) Moore (NC) Republican North Carolina NC Yea Moore (UT) Moore (UT) Republican Utah UT Yea Moore (WI) Moore (WI) Democratic Wisconsin WI Nay Moore (WV) Moore (WV) Republican West Virginia WV Yea Moran Moran Republican Texas TX Yea Morelle Morelle Democratic New York NY Yea Morrison Morrison Democratic Minnesota MN Nay Moskowitz Moskowitz Democratic Florida FL Yea Moulton Moulton Democratic Massachusetts MA Nay Mrvan Mrvan Democratic Indiana IN Not Voting Mullin Mullin Democratic California CA Nay Murphy Murphy Republican North Carolina NC Yea Nadler Nadler Democratic New York NY Nay Neal Neal Democratic Massachusetts MA Nay Neguse Neguse Democratic Colorado CO Nay Nehls Nehls Republican Texas TX Yea Newhouse Newhouse Republican Washington WA Yea Norcross Norcross Democratic New Jersey NJ Nay Norman Norman Republican South Carolina SC Yea Nunn (IA) Nunn (IA) Republican Iowa IA Yea Obernolte Obernolte Republican California CA Yea Ocasio-Cortez Ocasio-Cortez Democratic New York NY Nay Ogles Ogles Republican Tennessee TN Yea Olszewski Olszewski Democratic Maryland MD Nay Omar Omar Democratic Minnesota MN Nay Onder Onder Republican Missouri MO Yea Owens Owens Republican Utah UT Yea Pallone Pallone Democratic New Jersey NJ Nay Palmer Palmer Republican Alabama AL Yea Panetta Panetta Democratic California CA Nay Pappas Pappas Democratic New Hampshire NH Yea Pelosi Pelosi Democratic California CA Not Voting Perez Perez Democratic Washington WA Yea Perry Perry Republican Pennsylvania PA Yea Peters Peters Democratic California CA Nay Pettersen Pettersen Democratic Colorado CO Not Voting Pfluger Pfluger Republican Texas TX Yea Pingree Pingree Democratic Maine ME Nay Pocan Pocan Democratic Wisconsin WI Nay Pou Pou Democratic New Jersey NJ Nay Pressley Pressley Democratic Massachusetts MA Nay Quigley Quigley Democratic Illinois IL Nay Ramirez Ramirez Democratic Illinois IL Nay Randall Randall Democratic Washington WA Nay Raskin Raskin Democratic Maryland MD Nay Reschenthaler Reschenthaler Republican Pennsylvania PA Yea Riley (NY) Riley (NY) Democratic New York NY Not Voting Rivas Rivas Democratic California CA Nay Rogers (AL) Rogers (AL) Republican Alabama AL Yea Rogers (KY) Rogers (KY) Republican Kentucky KY Yea Rose Rose Republican Tennessee TN Yea Ross Ross Democratic North Carolina NC Nay Rouzer Rouzer Republican North Carolina NC Yea Roy Roy Republican Texas TX Yea Ruiz Ruiz Democratic California CA Nay Rulli Rulli Republican Ohio OH Yea Rutherford Rutherford Republican Florida FL Yea Ryan Ryan Democratic New York NY Nay Salazar Salazar Republican Florida FL Yea Salinas Salinas Democratic Oregon OR Nay Sánchez Sanchez Democratic California CA Nay Scalise Scalise Republican Louisiana LA Yea Scanlon Scanlon Democratic Pennsylvania PA Nay Schakowsky Schakowsky Democratic Illinois IL Nay Schmidt Schmidt Republican Kansas KS Yea Schneider Schneider Democratic Illinois IL Not Voting Scholten Scholten Democratic Michigan MI Yea Schrier Schrier Democratic Washington WA Yea Schweikert Schweikert Republican Arizona AZ Yea Scott (VA) Scott (VA) Democratic Virginia VA Nay Scott, Austin Scott, Austin Republican Georgia GA Yea Scott, David Scott, David Democratic Georgia GA Nay Self Self Republican Texas TX Yea Sessions Sessions Republican Texas TX Yea Sewell Sewell Democratic Alabama AL Yea Sherman Sherman Democratic California CA Nay Sherrill Sherrill Democratic New Jersey NJ Nay Shreve Shreve Republican Indiana IN Yea Simon Simon Democratic California CA Nay Simpson Simpson Republican Idaho ID Yea Smith (MO) Smith (MO) Republican Missouri MO Yea Smith (NE) Smith (NE) Republican Nebraska NE Yea Smith (NJ) Smith (NJ) Republican New Jersey NJ Yea Smith (WA) Smith (WA) Democratic Washington WA Nay Smucker Smucker Republican Pennsylvania PA Yea Sorensen Sorensen Democratic Illinois IL Yea Soto Soto Democratic Florida FL Nay Spartz Spartz Republican Indiana IN Yea Stansbury Stansbury Democratic New Mexico NM Nay Stanton Stanton Democratic Arizona AZ Yea Stauber Stauber Republican Minnesota MN Yea Stefanik Stefanik Republican New York NY Yea Steil Steil Republican Wisconsin WI Yea Steube Steube Republican Florida FL Yea Stevens Stevens Democratic Michigan MI Nay Strickland Strickland Democratic Washington WA Nay Strong Strong Republican Alabama AL Yea Stutzman Stutzman Republican Indiana IN Yea Subramanyam Subramanyam Democratic Virginia VA Yea Suozzi Suozzi Democratic New York NY Yea Swalwell Swalwell Democratic California CA Nay Sykes Sykes Democratic Ohio OH Yea Takano Takano Democratic California CA Nay Taylor Taylor Republican Ohio OH Yea Tenney Tenney Republican New York NY Yea Thanedar Thanedar Democratic Michigan MI Not Voting Thompson (CA) Thompson (CA) Democratic California CA Nay Thompson (MS) Thompson (MS) Democratic Mississippi MS Nay Thompson (PA) Thompson (PA) Republican Pennsylvania PA Yea Tiffany Tiffany Republican Wisconsin WI Yea Timmons Timmons Republican South Carolina SC Yea Titus Titus Democratic Nevada NV Yea Tlaib Tlaib Democratic Michigan MI Nay Tokuda Tokuda Democratic Hawaii HI Nay Tonko Tonko Democratic New York NY Nay Torres (CA) Torres (CA) Democratic California CA Nay Torres (NY) Torres (NY) Democratic New York NY Yea Trahan Trahan Democratic Massachusetts MA Nay Tran Tran Democratic California CA Yea Turner (OH) Turner (OH) Republican Ohio OH Yea Turner (TX) Turner (TX) Democratic Texas TX Nay Underwood Underwood Democratic Illinois IL Nay Valadao Valadao Republican California CA Yea Van Drew Van Drew Republican New Jersey NJ Yea Van Duyne Van Duyne Republican Texas TX Yea Van Orden Van Orden Republican Wisconsin WI Yea Vargas Vargas Democratic California CA Nay Vasquez Vasquez Democratic New Mexico NM Nay Veasey Veasey Democratic Texas TX Nay Velázquez Velazquez Democratic New York NY Nay Vindman Vindman Democratic Virginia VA Yea Wagner Wagner Republican Missouri MO Yea Walberg Walberg Republican Michigan MI Yea Wasserman Schultz Wasserman Schultz Democratic Florida FL Nay Waters Waters Democratic California CA Not Voting Watson Coleman Watson Coleman Democratic New Jersey NJ Nay Weber (TX) Weber (TX) Republican Texas TX Yea Webster (FL) Webster (FL) Republican Florida FL Yea Westerman Westerman Republican Arkansas AR Yea Whitesides Whitesides Democratic California CA Not Voting Wied Wied Republican Wisconsin WI Yea Williams (GA) Williams (GA) Democratic Georgia GA Nay Williams (TX) Williams (TX) Republican Texas TX Not Voting Wilson (FL) Wilson (FL) Democratic Florida FL Nay Wilson (SC) Wilson (SC) Republican South Carolina SC Yea Wittman Wittman Republican Virginia VA Yea Womack Womack Republican Arkansas AR Yea Yakym Yakym Republican Indiana IN Yea Zinke Zinke Republican Montana MT Yea No data found 119 Contact Information Room H154, The Capitol Washington, DC 20515-6601 p: (202) 225-7000 For general inquiries: info.clerkweb@mail.house.gov For general technical support: techsupport.clerkweb@mail.house.gov Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Disclosures Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office Committee Information Committee Profiles Clerk Sites Bills This Week Biographical Directory Clerk Kids Committee Repository History, Art & Archives Office of the Chaplain Help & Resources FAQs Privacy Policy Site Map

---
snapshot_id: 101dea68-4693-5107-9976-d8e9510241f2
source_kind: own-site (the person's own site or account)
url: https://www.erinhouchin.com/issues

Erin Houchin on the Issues &mdash; Erin Houchin for Congress 0 Skip to Content ABOUT ISSUES VOLUNTEER CONTACT DONATE Open Menu Close Menu ABOUT ISSUES VOLUNTEER CONTACT DONATE Open Menu Close Menu ABOUT ISSUES VOLUNTEER CONTACT DONATE ERIN ON THE ISSUES SECURE THE BORDER: Joe Biden let over 10 million individuals illegally invade our country—that we know of. These illegals outnumber the population of Indiana by three million people. Erin visited the border in Texas twice, and witnessed the chaos and destruction firsthand. She fully supports President Trump’s efforts to restore border security—by backing law enforcement, finishing the wall, and deporting criminal illegal aliens to protect American communities. STAND WITH ISRAEL: Erin stands firmly with Israel, our nation’s strongest ally in the Middle East. Even before Hamas’ barbaric terrorist attack on October 7, 2023, she has vocally supported Israel’s right to defend itself, and the right of Israelis to live. Erin believes that we as a nation have a moral obligation to unequivocally defend Israel. She is committed to standing resolute against anti-Semitism in all forms at home and abroad and advocating for the U.S. to cut all aid to any sponsors of terrorism. CUT GOVERNMENT SPENDING: Erin believes our government takes too much of your money, and spends too much. Just as families across Indiana balance their budgets, she believes the federal government should too. It's no question that our growing national debt is a national security concern. Erin is a committed fiscal conservative and has the track record to prove it, and as a champion for Indiana’s Balanced Budget Amendment, she is bringing that same fiscal discipline to Washington. PROTECT THE UNBORN: Erin is pro-life and always has been. She has been a steadfast leader in the fight for the unborn, consistently advocating for the prohibition of late-term abortions, and resources and care for mothers in need. In Congress, she continues to be a voice for the voiceless. National Right to Life and the Susan B. Anthony List have endorsed her, she has earned an A+ rating from the SBA List, and had a consistent 100% pro-life voting record as a member of the Indiana State Senate. STAND FOR CONSERVATIVE VALUES: The strong conservative values instilled in Erin growing up in Scottsburg have become a foundational part of who she is. A strong defender of the Second Amendment, the Right to Life, and the right to worship freely, Erin will always fight for our conservative freedoms and liberties. She will continue standing steadfast for an America First Agenda that allows us to live safely and freely. PROTECT PARENTAL RIGHTS: Parents should be in the driver's seat of their children's education. The pandemic opened American parents' eyes to the reality of our public school system, and millions of parents didn't like what they saw. As a mother of three, Erin knows that parents are the primary stakeholders in their children's education. That's why she voted to pass the Parents Bill of Rights and will continue to support parents in this ongoing effort for transparency and a seat at the table as we prepare the next generation for success. SUPPORT OUR VETERANS: America is blessed with the greatest fighting force in the world, and Erin deeply appreciates our servicemen and women and their families. She is committed to improving the welfare and quality of life for our veterans and their families, our active-duty military members and their spouses. Erin is committed to ensuring we keep our promises to those who fought to defend our freedoms and never let them down. UPHOLD LAW & ORDER: Hoosiers are fortunate to have some of the most dedicated and talented law enforcement and public safety officials in the country, and it’s our duty to have their backs. These brave men and women should be protected by lawmakers instead of being met with hostility and resentment. Erin will always fight to ensure our officers have the necessary resources to do their jobs effectively and safely, and they have the support and compensation they deserve. Erin will never allow radical left-wing politicians to defund the police. CREATE JOBS: Erin knows the best way to create jobs and grow the economy is to get the government out of the way and let small business owners do what they do best – innovate and create new jobs. Indiana has one of the best economies in the nation, a direct result of our conservative values. As a small business owner, Erin continues the fight to cut bureaucratic red tape and support limited government while working to cut taxes, promote free markets, and control government spending. PROTECT THE SECOND AMENDMENT: Erin is a firm believer that the Second Amendment is one of our most important freedoms, and she understands the importance of protecting our constitutional right to bear arms. The founders saw the crucial importance of giving citizens the right to protect themselves, and we must all protect that right. CONTRIBUTE PAID FOR BY HOUCHIN FOR CONGRESS ABOUT | ISSUES | CONTACT Privacy Policy

---
snapshot_id: 4413ee1b-7c53-5bdb-8a0e-b95d6202d826
source_kind: own-site (the person's own site or account)
url: https://houchin.house.gov/media/press-releases/congresswoman-houchin-prosecutor-chalfant-announce-deportation-illegal-alien

Congresswoman Houchin, Prosecutor Chalfant Announce Deportation of Illegal Alien Responsible for Fatal Crash | Congresswoman Erin Houchin Skip to main content 342 Cannon House Office Building, Washington, DC 20515 Email Me (202) 225-5315 About Committees and Caucuses Our District Votes and Legislation Contact Newsletter Subscribe Office Locations Media Press Releases Issues Agriculture Economy Education Energy Health Veterans Border Security Services Art Competition Congressional App Challenge Congressional Commendations Flags Grant Applicants Help with a Federal Agency Internships Service Academy Nominations Tours and Tickets America 250 Attention Seniors - Fraud Alert! Casework Success Stories Community Project Funding Help for Veterans Subscribe X How Can I Help? Home Media Press Releases Congresswoman Houchin, Prosecutor Chalfant Announce Deportation of Illegal Alien Responsible for Fatal Crash February 17, 2025 Press Release BROWNSTOWN, IN – Today, Congresswoman Erin Houchin (IN-09) and Jackson County Prosecutor Jeff Chalfant announced the deportation of the illegal alien responsible for the tragic death of 27-year-old Brad Castner. Thanks to the Laken Riley Act, signed into law by President Trump, dangerous illegal aliens like this one are finally being removed from American communities. In March 2024, the illegal alien, who had previously been cited for driving without a license, crossed the center line on U.S. Highway 50 and crashed into Castner’s vehicle, killing him. For years, under the Biden administration, illegal aliens like this individual remained in the country with no consequences due to weak immigration enforcement and a refusal to deport criminal offenders. “Brad Castner should still be alive today. His death was preventable,” said Congresswoman Houchin. “For four years, Biden’s open border policies allowed millions of illegal aliens to enter our country while the law was not enforced to remove criminals. That has changed under President Trump. Thanks to the Laken Riley Act, dangerous illegal aliens are finally being detained and deported before they can commit more crimes.” Houchin praised Prosecutor Chalfant and ICE for their work in securing the removal of the illegal alien from Indiana and ensuring his deportation proceedings moved forward swiftly. “There is still more work to be done to fix the damage caused by Biden’s open border policies, but this is a step in the right direction,” Houchin added. “We will continue fighting to make sure every community—from the southern border to southern Indiana—is safe from the dangers and chaos created by this border crisis.” Issues : Border Security Office Locations Washington DC Office 342 Cannon House Office Building Washington, DC 20515 Phone: (202) 225-5315 Salem District Office 104 W Hackberry Street Salem, IN 47167 Phone: (812) 288-3999 Top Copyright Privacy House.gov Accessibility RSS

---
snapshot_id: 7fba9638-5e6c-5a36-9429-bca35555d7a9
source_kind: public-record
url: https://www.congress.gov/bill/119th-congress/senate-bill/5

Laken Riley Act Policy area: Immigration Sponsor: Sen. Britt, Katie Boyd [R-AL] Latest action: Became Public Law No: 119-1. Laken Riley Act This bill requires the Department of Homeland Security (DHS) to detain certain non-U.S. nationals ( aliens under federal law) who have been arrested for burglary, theft, larceny, or shoplifting. The bill also authorizes states to sue the federal government for decisions or alleged failures related to immigration enforcement. Under this bill, DHS must detain an individual who (1) is unlawfully present in the United States or did not possess the necessary documents when applying for admission; and (2) has been charged with, arrested for, convicted of, or admits to having committed acts that constitute the essential elements of burglary, theft, larceny, or shoplifting. The bill also authorizes state governments to sue for injunctive relief over certain immigration-related decisions or alleged failures by the federal government if the decision or failure caused the state or its residents harm, including financial harm of more than $100. Specifically, the state government may sue the federal government over a decision to release a non-U.S. national from custody; failure to fulfill requirements relating to inspecting individuals seeking admission into the United States, including requirements related to asylum interviews; failure to fulfill a requirement to stop issuing visas to nationals of a country that unreasonably denies or delays acceptance of nationals of that country; violation of limitations on immigration parole, such as the requirement that parole be granted only on a case-by-case basis; or failure to detain an individual who has been ordered removed from the United States. Laken Riley Act This act requires the Department of Homeland Security (DHS) to detain certain non-U.S. nationals ( aliens under federal law) who have been arrested for burglary, theft, larceny, shoplifting, assault of a law enforcement officer, or any crime that results in death or serious bodily injury to another person. The act also authorizes states to sue the federal government for decisions or alleged failures related to immigration enforcement. Under this act, DHS must detain an individual who (1) is unlawfully present in the United States or did not possess the necessary documents when applying for admission; and (2) has been charged with, arrested for, convicted of, or admits to having committed acts that constitute the essential elements of the above crimes. The act also authorizes state governments to sue for injunctive relief over certain immigration-related decisions or alleged failures by the federal government if the decision or failure caused the state or its residents harm, including financial harm of more than $100. Specifically, the state government may sue the federal government over a decision to release a non-U.S. national from custody; failure to fulfill requirements relating to inspecting individuals seeking admission into the United States, including requirements related to asylum interviews; failure to fulfill a requirement to stop issuing visas to nationals of a country that unreasonably denies or delays acceptance of nationals of that country; violation of limitations on immigration parole, such as the requirement that parole be granted only on a case-by-case basis; or failure to detain an individual who has been ordered removed from the United States. Cosponsors: Sen. Risch, James E. [R-ID], Sen. Schmitt, Eric [R-MO], Sen. Lankford, James [R-OK], Sen. Cramer, Kevin [R-ND], Sen. Tuberville, Tommy [R-AL], Sen. Hoeven, John [R-ND], Sen. Lee, Mike [R-UT], Sen. Johnson, Ron [R-WI], Sen. Barrasso, John [R-WY], Sen. Wicker, Roger F. [R-MS], Sen. Lummis, Cynthia M. [R-WY], Sen. Thune, John [R-SD], Sen. Tillis, Thomas [R-NC], Sen. Cotton, Tom [R-AR], Sen. Crapo, Mike [R-ID], Sen. Grassley, Chuck [R-IA], Sen. McConnell, Mitch [R-KY], Sen. Moreno, Bernie [R-OH], Sen. Moran, Jerry [R-KS], Sen. Graham, Lindsey [R-SC], Sen. Budd, Ted [R-NC], Sen. Boozman, John [R-AR], Sen. Kennedy, John [R-LA], Sen. Marshall, Roger [R-KS], Sen. Collins, Susan M. [R-ME], Sen. Daines, Steve [R-MT], Sen. Cornyn, John [R-TX], Sen. Scott, Rick [R-FL], Sen. Sheehy, Tim [R-MT], Sen. Banks, Jim [R-IN], Sen. Ernst, Joni [R-IA], Sen. Mullin, Markwayne [R-OK], Sen. Hagerty, Bill [R-TN], Sen. Ricketts, Pete [R-NE], Sen. Capito, Shelley Moore [R-WV], Sen. Murkowski, Lisa [R-AK], Sen. Fischer, Deb [R-NE], Sen. Hawley, Josh [R-MO], Sen. Scott, Tim [R-SC], Sen. Young, Todd [R-IN], Sen. Blackburn, Marsha [R-TN], Sen. Sullivan, Dan [R-AK], Sen. Curtis, John R. [R-UT], Sen. Hyde-Smith, Cindy [R-MS], Sen. Rounds, Mike [R-SD], Sen. Cruz, Ted [R-TX], Sen. Cassidy, Bill [R-LA], Sen. Rubio, Marco [R-FL], Sen. McCormick, David [R-PA], Sen. Paul, Rand [R-KY], Sen. Vance, J. D. [R-OH], Sen. Fetterman, John [D-PA], Sen. Gallego, Ruben [D-AZ] Actions: Became Public Law No: 119-1. Became Public Law No: 119-1. Signed by President. Signed by President. Presented to President. Presented to President. Motion to reconsider laid on the table Agreed to without objection. On passage Passed by the Yeas and Nays: 263 - 156 (Roll no. 23). (text: CR H277-278) Passed/agreed to in House: On passage Passed by the Yeas and Nays: 263 - 156 (Roll no. 23). (text: CR H277-278) Considered as unfinished business. (consideration: CR H285-286) POSTPONED PROCEEDINGS - At the conclusion of the debate on S. 5, the Chair put the question on passage of the bill and by voice vote announced that the ayes had prevailed. Mr. Raskin demanded the yeas and nays and the Chair postponed further proceedings until a time to be announced. The previous question was ordered pursuant to the rule. DEBATE - The House proceeded with one hour of debate on S. 5. Rule provides for consideration of H.R. 471 and S. 5. The resolution provides for consideration of H.R. 471 under a structured rule with one hour of general debate and one motion to recommit. Also, the resolution provides for consideration of S. 5 under a closed rule with one hour of general debate and one motion to commit. Considered under the provisions of rule H. Res. 53. (consideration: CR H277-284) [Congressional Bills 119th Congress] [From the U.S. Government Publishing Office] [S. 5 Enrolled Bill (ENR)] S.5 One Hundred Nineteenth Congress of the United States of America AT THE FIRST SESSION Begun and held at the City of Washington on Friday, the third day of January, two thousand and twenty five An Act To require the Secretary of Homeland Security to take into custody aliens who have been charged in the United States with theft, and for other purposes. Be it enacted by the Senate and House of Representatives of the United States of America in Congress assembled, SECTION 1. SHORT TITLE. This Act may be cited as the ``Laken Riley Act''. SEC. 2. DETENTION OF CERTAIN ALIENS WHO COMMIT THEFT. Section 236(c) of the Immigration and Nationality Act (8 U.S.C. 1226(c)) is amended-- (1) in paragraph (1)-- (A) in subparagraph (C), by striking ``or''; (B) in subparagraph (D), by striking the comma at the end and inserting ``, or''; and (C) by inserting after subparagraph (D) the following: (E)(i) is inadmissible under paragraph (6)(A), (6)(C), or (7) of section 212(a); and ``(ii) is charged with, is arrested for, is convicted of, admits having committed, or admits committing acts which constitute the essential elements of any burglary, theft, larceny, shoplifting, or assault of a law enforcement officer offense, or any crime that results in death or serious bodily injury to another person,''; (2) by redesignating paragraph (2) as paragraph (4); and (3) by inserting after paragraph (1) the following: ``(2) Definition.--For purposes of paragraph (1)(E), the terms `burglary', `theft', `larceny', `shoplifting', `assault of a law enforcement officer', and `serious bodily injury' have the meanings given such terms in the jurisdiction in which the acts occurred.'' ``(3) Detainer.--The Secretary of Homeland Security shall issue a detainer for an alien described in paragraph (1)(E) and, if the alien is not otherwise detained by Federal, State, or local officials, shall effectively and expeditiously take custody of the alien.''. SEC. 3. ENFORCEMENT BY ATTORNEY GENERAL OF A STATE. (a) Inspection of Applicants for Admission.--Section 235(b) of the Immigration and Nationality Act (8 U.S.C. 1225(b)) is amended-- (1) by redesignating paragraph (3) as paragraph (4); and (2) by inserting after paragraph (2) the following: ``(3) Enforcement by attorney general of a state.--The attorney general of a State, or other authorized State officer, alleging a violation of the detention and removal requirements under paragraph (1) or (2) that harms such State or its residents shall have standing to bring an action against the Secretary of Homeland Security on behalf of such State or the residents of such State in an appropriate district court of the United States to obtain appropriate injunctive relief. The court shall advance on the docket and expedite the disposition of a civil action filed under this paragraph to the greatest extent practicable. For purposes of this paragraph, a State or its residents shall be considered to have been harmed if the State or its residents experience harm, including financial harm in excess of $100.''. (b) Apprehension and Detention of Aliens.--Section 236 of the Immigration and Nationality Act (8 U.S.C. 1226), as amended by this Act, is further amended-- (1) in subsection (e)-- (A) by striking ``or release''; and (B) by striking ``grant, revocation, or denial'' and insert ``revocation or denial''; and (2) by adding at the end the following: ``(f) Enforcement by Attorney General of a State.--The attorney general of a State, or other authorized State officer, alleging an action or decision by the Attorney General or Secretary of Homeland Security under this section to release any alien or grant bond or parole to any alien that harms such State or its residents shall have standing to bring an action against the Attorney General or Secretary of Homeland Security on behalf of such State or the residents of such State in an appropriate district court of the United States to obtain appropriate injunctive relief. The court shall advance on the docket and expedite the disposition of a civil action filed under this subsection to the greatest extent practicable. For purposes of this subsection, a State or its residents shall be considered to have been harmed if the State or its residents experience harm, including financial harm in excess of $100.''. (c) Penalties.--Section 243 of the Immigration and Nationality Act (8 U.S.C. 1253) is amended by adding at the end the following: ``(e) Enforcement by Attorney General of a State.--The attorney general of a State, or other authorized State officer, alleging a violation of the requirement to discontinue granting visas to citizens, subjects, nationals, and residents as described in subsection (d) that harms such State or its residents shall have standing to bring an action against the Secretary of State on behalf of such State or the residents of such State in an appropriate district court of the United States to obtain appropriate injunctive relief. The court shall advance on the docket and expedite the disposition of a civil action filed under this subsection to the greatest extent practicable. For purposes of this subsection, a State or its residents shall be considered to have been harmed if the State or its residents experience harm, including financial harm in excess of $100.''. (d) Certain Classes of Aliens.--Section 212(d)(5) of the Immigration and Nationality Act (8 U.S.C. 1182(d)(5)) is amended-- (1) by striking ``Attorney General'' each place such term appears and inserting ``Secretary of Homeland Security''; and (2) by adding at the end the following: ``(C) The attorney general of a State, or other authorized State officer, alleging a violation of the limitation under subparagraph (A) that parole solely be granted on a case-by-case basis and solely for urgent humanitarian reasons or a significant public benefit, that harms such State or its residents shall have standing to bring an action against the Secretary of Homeland Security on behalf of such State or the residents of such State in an appropriate district court of the United States to obtain appropriate injunctive relief. The court shall advance on the docket and expedite the disposition of a civil action filed under this subparagraph to the greatest extent practicable. For purposes of this subparagraph, a State or its residents shall be considered to have been harmed if the State or its residents experience harm, including financial harm in excess of $100.''. (e) Detention.--Section 241(a)(2) of the Immigration and Nationality Act (8 U.S.C. 1231(a)(2)) is amended-- (1) by striking ``During the removal period,'' and inserting the following: ``(A) In general.--During the removal period,''; and (2) by adding at the end the following: ``(B) Enforcement by attorney general of a state.--The attorney general of a State, or other authorized State officer, alleging a violation of the detention requirement under subparagraph (A) that harms such State or its residents shall have standing to bring an action against the Secretary of Homeland Security on behalf of such State or the residents of such State in an appropriate district court of the United States to obtain appropriate injunctive relief. The court shall advance on the docket and expedite the disposition of a civil action filed under this subparagraph to the greatest extent practicable. For purposes of this subparagraph, a State or its residents shall be considered to have been harmed if the State or its residents experience harm, including financial harm in excess of $100.''. (f) Limit on Injunctive Relief.--Section 242(f) of the Immigration and Nationality Act (8 U.S.C. 1252(f)) is amended by adding at the end following: ``(3) Certain actions.--Paragraph (1) shall not apply to an action brought pursuant to section 235(b)(3), subsections (e) or (f) of section 236, or section 241(a)(2)(B).''. Speaker of the House of Representatives. Vice President of the United States and President of the Senate.