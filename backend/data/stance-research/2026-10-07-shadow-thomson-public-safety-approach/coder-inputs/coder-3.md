You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-thomson-public-safety-approach/labels/coder-3.json. Write JSON only, matching
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

### topic_key: public-safety-approach
topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85  served_revision_id: cfc3824f-522e-4671-bd2d-dd628e6578e1
Question: What approach should your community take to public safety?
  1. Shift public safety away from policing and toward mental health, housing, and social services.
  2. Send unarmed responders, instead of police, to mental-health and non-violent calls.
  3. Keep police as the main responders and add crisis teams to work alongside them.
  4. Add more officers and expand police presence to deter and respond to crime.
  5. Make policing the community's top public-safety priority, ahead of social and community programs.

#### Annex

# public-safety-approach — served revision cfc3824f-522e-4671-bd2d-dd628e6578e1 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. The season pin is an older revision
(`b9c1c07f-…`); coders code the served text below.

**Question:** "What approach should your community take to public safety?"

**Orientation:** standard. Rung 1 moves public safety away from policing, rung 5 makes policing the
top priority. The rungs order **how central police are** in the community's public-safety response:
replaced in part, replaced on some calls, kept as main responders with help, expanded, put first.

**Levels with a lever:** local. The lever is the city or county budget, police
and sheriff staffing, the 911 dispatch system, and civilian response programmes. State and federal
officeholders hold no lever here → `scope-unavailable`.

**Asked at:** local (`compass_topic_roles`, CA_0302).

**Synonyms:** "alternative response", "civilian crisis response", "unarmed responders",
"co-responder", "crisis intervention team" (CIT), "mobile crisis team", "988", "behavioural-health
response", "community violence intervention", "reallocate", "redirect police funding", "sworn
officers", "authorized strength", "staffing levels", "police presence", "hot-spot policing".

1. **"Shift public safety away from policing and toward mental health, housing, and social
   services."**
   - Means: move the community's public-safety effort and money from police to services.
   - Operative clauses: [a] away from policing (a smaller police role or budget); [b] toward mental
     health, housing and social services.
   - Establishing evidence looks like: a single-subject vote or budget amendment that moves money or
     duties from police to services; own words calling for that shift. Compound: one side only →
     `compound-partial` (V4.2).
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - More money for services with **no** change to policing does not meet [a] → `direction-only`
     _(proposed)_.
   - Commonly confused with rung 2 because an unarmed-responder programme moves some duties away
     from police. One programme for certain calls is rung 2; a broader shift of the public-safety
     effort is rung 1 _(proposed)_.

2. **"Send unarmed responders, instead of police, to mental-health and non-violent calls."**
   - Means: trained civilians, not officers, answer mental-health and non-violent calls.
   - Operative clauses: [a] unarmed responders **instead of** police; [b] for mental-health and
     non-violent calls.
   - Establishing evidence looks like: creating or funding a civilian response team that is
     dispatched **without** police to those calls; own words calling for it.
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - Commonly confused with rung 3 because both add crisis workers. A **co-responder** model
     (a clinician rides with or meets an officer) keeps police on the call → rung 3. Rung 2 needs
     the civilians to go **instead of** police. A programme whose text does not say who goes →
     `direction-only` _(proposed)_.

3. **"Keep police as the main responders and add crisis teams to work alongside them."**
   - Means: police still answer calls, with crisis specialists working with them.
   - Operative clauses: [a] police stay the main responders; [b] add crisis teams alongside them.
   - Establishing evidence looks like: funding a co-responder or crisis-intervention programme
     attached to the police department, with police staffing kept as it is.
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2: see rung 2.
   - Crisis-intervention **training** for officers is not a crisis team → `direction-only`
     _(proposed)_.

4. **"Add more officers and expand police presence to deter and respond to crime."**
   - Means: hire more police and put more of them on the street.
   - Operative clauses: [a] add more officers; [b] expand police presence.
   - Establishing evidence looks like: a single-subject vote or budget amendment that funds new sworn
     positions or raises authorized strength; own words calling for more officers.
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - Pay raises and hiring bonuses keep or fill current positions; they add officers only when the
     passage ties them to a larger force → otherwise `direction-only` _(proposed)_.
   - Commonly confused with rung 5 because adding officers is also consistent with putting policing
     first. A vote to add officers does not show that police come **ahead of** social programmes;
     it does not exclude rung 5 on its own → `direction-only` unless another passage keeps services
     level with or ahead of policing (V4) _(proposed)_.

5. **"Make policing the community's top public-safety priority, ahead of social and community
   programs."**
   - Means: policing comes first, and social and community programmes come after it.
   - Operative clauses: [a] policing as the top public-safety priority; [b] ahead of social and
     community programmes.
   - Establishing evidence looks like: own words that rank policing above social programmes; a
     single-subject vote that cuts or caps social programmes to fund police.
   - Levels that hold a lever: local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4. "Public safety is my top priority" is not [a]: public
     safety is not policing → `rhetorical` _(proposed)_.

**Hard cases:**
- **Budget and omnibus votes** that fund the police department among other departments → V4
  `multi-subject`. A No on such a budget proves nothing.
- **Police oversight and accountability** (review boards, body cameras, use-of-force rules) do not
  speak to how central police are → `adjacent` _(proposed)_.
- **Sentencing, bail and criminal law** are state or court matters → `adjacent` (other topics).
- **Community violence-intervention grants** fund a service; alone they do not reduce policing →
  `direction-only` toward rungs 1–2 _(proposed)_.
- **Slogans for or against police** with no measure named → `rhetorical`.
- **Near-unanimous** votes (a crisis-line agreement, a grant acceptance) → `near-unanimous`.


## Sources

---
snapshot_id: 7ca23e6f-d83a-5eeb-b9e7-ec31052c548e
source_kind: own-site (the person's own site or account)
url: https://bloomington.in.gov/news/2026/04/15/6521

City of Bloomington Transitions Away from Flock Use After Months-Long Evaluation | City of Bloomington, Indiana Skip to main content Mayor Kerry Thomson Search Search Services Services Information Info News News Meetings & Events Events City Government Govt. Breadcrumb News Releases 2026 April 15 City of Bloomington Transitions Away from Flock Use After Months-Long Evaluation Share: Share on Facebook Share on Twitter Email this Page Address 401 N Morton St Suite 210 Bloomington IN 47404 Phone 812-349-3406 Fax 812-349-3455 Facebook Connect on Facebook Twitter Follow us on Twitter Page last updated on April 15, 2026 at 7:01 pm April 15, 2026 For more information, please contact Desiree DeMolina, Communications Director, Office of the Mayor [email protected] or 812-349-3406 City of Bloomington Transitions Away from Flock Use After Months-Long Evaluation Mayor Kerry Thomson announced today that the City’s contract for Flock LPR services expired on March 5, 2026, and that, following a months-long evaluation, the City decided not to renew it. On April 15, 2026, Bloomington Police Chief Michael Diekhoff submitted a report on Bloomington’s use of Flock, followed by a memo from Mayor Thomson to the Bloomington Common Council. Both will be presented at the Council’s April 22 meeting. The evaluation was already underway before the Bloomington Common Council’s March 5, 2026, resolution calling for additional oversight of the City’s Flock cameras and requesting a report from BPD regarding access to Flock data. The review included consultation with Bloomington Police Department (BPD) leadership and investigative teams, the City’s legal team, Flock representatives, and community partners, and included an assessment of operational use, legal considerations, and documented case applications. As the City transitions away from Flock, it will evaluate other technologies and providers that better balance public safety needs with privacy protections, transparency, accountability, and public trust. As part of the review, Mayor Thomson directed immediate steps to narrow and govern the system’s use during the transition period. Access to Flock data will be limited to Bloomington Police Department personnel only. There will be no outside data sharing. The City’s Flock-related equipment includes 11 permanently mounted license plate reader cameras, four permanently mounted video cameras, and four mobile trailer systems equipped for license plate reading, video recording, and gunshot detection. Other local jurisdictions, including Indiana University and Monroe County, operate similar systems under their own authority and policies. Bloomington is not alone in reassessing how automated license plate reader technology should be governed. In March 2026, the City of Boulder, Colorado announced it would continue using license plate reader technology while launching a bid process and renegotiating terms with its current provider, Flock. License plate reader cameras capture an image of the rear of a vehicle and its license plate as the vehicle travels on a public roadway. Per BPD policy and reporting, the system does not use facial recognition; does not contain, collect or reveal vehicle registration information such as a driver’s name or address; and does not create profiles based on personal traits or demographic information. Search results show a still image and timestamp tied to a vehicle observation, not a personal identity profile. Within BPD, access is limited to sworn officers and data analysts. Users are required to complete training, use individually assigned log-ins, connect searches to an active event number, and identify a valid reason for each search. Search activity is logged and those logs are subject to audit every 60 days. The Police Department also maintains a 30-day retention period for Flock data unless material was entered as evidence in a criminal case. BPD is not participating in Flock’s national network, and the data collected by Bloomington cameras was shared only with other Indiana law enforcement agencies as authorized by department policy. Under the Mayor’s direction, that sharing will discontinue. Bloomington cameras will no longer be visible to other agencies on the network, and outside agencies will not be able to query Bloomington camera data. The City’s review considered documented examples of how BPD had used the system in support of investigations and resolution of cases, including the safe recovery of a kidnapping victim, identification of a suspect in a homicide investigation near the county line, and identification of a suspect who later confessed in a roadside sexual assault case. The department also cited cases in which vehicle data helped support homicide investigations within Bloomington and aided another Indiana agency in locating evidence connected to a murder investigation. “We take civil liberties seriously. We take public safety seriously. Those are shared obligations of good government,” said Mayor Kerry Thomson. “This review made clear that if this tool is used, it must be used under narrow parameters, strong accountability, and clear public safeguards. We are continuing to evaluate whether other options may better serve the community.” “Due diligence takes time. We do not make decisions like this to satisfy a moment. We review the full picture, weigh the impacts meticulously, and respond for the good of the whole community,” said Thomson. “Everyone in Bloomington deserves to be safe and to feel safe,” said Chief Michael Diekhoff. “The goal is to support good police work with tools that are effective, carefully governed, and understood by the public. As Bloomington moves away from Flock, it is important that we do so responsibly and without creating avoidable gaps in public safety.” Additional information regarding Flock system use will be presented to the Bloomington Common Council by Bloomington Police Chief Michael Diekhoff at its April 22 meeting . Related Categories Department: Office Of The Mayor cob-logo-horizontal City Jobs Contact the City Report an Issue Connect on Social Media City Maps Transparency Accessibility Privacy Policy City Intranet City Hall 401 North Morton Street Bloomington, Indiana 47404 812-349-3400 Facebook Twitter Instagram NextDoor YouTube

---
snapshot_id: 0ba3d80e-b0a4-5da5-81ca-62de02422b0d
source_kind: own-site (the person's own site or account)
url: https://bloomington.in.gov/news/2025/05/16/6259

City of Bloomington Reflects on 2024 Successes in Public Safety Through Latest Annual Report | City of Bloomington, Indiana Skip to main content Mayor Kerry Thomson Search Search Services Services Information Info News News Meetings & Events Events City Government Govt. Breadcrumb News Releases 2025 May 16 City of Bloomington Reflects on 2024 Successes in Public Safety Through Latest Annual Report Share: Share on Facebook Share on Twitter Email this Page Page last updated on May 16, 2025 at 4:02 pm May 16, 2025 For more information, please contact Desiree DeMolina, Communications Director, Office of the Mayor comms@ [email protected] or 812-349-3406 City of Bloomington Reflects on 2024 Successes in Public Safety Through Latest Annual Report Bloomington, Ind. — The City of Bloomington has released its latest State of Public Safety Report, a comprehensive document that provides a snapshot of our community’s safety, health and well-being from last year. The report focuses on the City’s three principal public safety agencies: the Bloomington Police Department (BPD), the Bloomington Fire Department (BFD), and the Community and Family Resources Department (CFRD). “As we reflected on 2024, one thing was clear: our community’s needs were growing and so was the demand on our public safety teams,” said Mayor Kerry Thomson. “When I came into office, I saw firsthand how many of our frontline workers were asked to do more with less. My team and I prioritized listening, problem-solving, and making sure our public servants had what they needed to serve our residents with care, efficiency, and dignity. This report reflects the progress we’ve made and the momentum we’re committed to continuing.” Major highlights from 2024 include the following, per the report: Bloomington Police Department Violent crime in Bloomington declined by 24.3% The city’s overall crime rate declined by 0.8% BPD responded to 31% fewer calls involving weapons BPD responded to 2.4% more calls overall BPD responded to 24% more traffic stops The City began exploring using the building at 714 S. Rogers St. as BPD’s new headquarters and continues to do so, with support from police administration and union members. Bloomington Fire Department BFD responded to 8.3% more calls BFD completed 23% more inspections The Department’s Mobile Integrated Healthcare program saw a sustained surge in patient interaction, underscoring its increasingly vital role in delivering essential services to our residents. The City reopened Fire Station 1 with new renovations that improve firefighters’ quality of life and equip them with resources to offer the best protection possible for the community. Community and Family Resources Department CFRD administered $117,800 in Violence Reduction Grants, aimed at empowering local neighborhoods and organizations to tackle violence through community-based initiatives. CFRD administered $250,000 in Downtown Outreach Grants, which aimed to improve conditions for Bloomington residents who were unhoused or at risk of homelessness. A total of 7,695 searches were done through Helping Bloomington Monroe , a free community resource to help residents find the services they need. In July 2024, Mayor Thomson appointed Shatoyia Moss as CFRD Director . In November 2024, Andrew Shannon joined the City as Safe and Civil City Director To read the full report, visit bloomington.in.gov/public-safety/annual-reports and click on the hyperlink next to “2025 Public Safety Report.” cob-logo-horizontal City Jobs Contact the City Report an Issue Connect on Social Media City Maps Transparency Accessibility Privacy Policy City Intranet City Hall 401 North Morton Street Bloomington, Indiana 47404 812-349-3400 Facebook Twitter Instagram NextDoor YouTube

---
snapshot_id: 44943727-1970-589b-82f4-784ca26d9344
source_kind: own-site (the person's own site or account)
url: https://bloomington.in.gov/news/2024/04/25/5916

Bloomington Police Initiatives to Improve Recruiting and Safety | City of Bloomington, Indiana Skip to main content Mayor Kerry Thomson Search Search Services Services Information Info News News Meetings & Events Events City Government Govt. Breadcrumb News Releases 2024 April 25 Bloomington Police Initiatives to Improve Recruiting and Safety Share: Share on Facebook Share on Twitter Email this Page Page last updated on April 25, 2024 at 11:52 am April 25, 2024 For more information, please contact Captain Ryan Pedigo Bloomington Police Department [email protected] or (812)349-3324 Justin Crossley, Digital Brand Manager, Office of the Mayor [email protected] or 812-349-3406 Bloomington Police Initiatives to Improve Recruiting and Safety Today the Office of the Mayor and Bloomington Police Department (BPD) announced several new initiatives aimed at increasing recruitment, providing modern policing tools, and supporting safer, faster response to incidents. First, in an effort to recruit quality applicants and retain current personnel, Mayor Kerry Thomson recently announced an individually issued patrol vehicle program for officers of the Bloomington Police Department. Under this new program, officers are able to take their patrol vehicles home. The policy mirrors programs already in place at surrounding agencies, thereby eliminating a difficult recruiting hurdle. Take-home cars also allow for a quicker, safer response to large-scale incidents, as officers have their equipment with them and can respond directly to the scene of an event even while off-duty. Since the new policy was announced, officers have responded to multiple calls for service while off-duty, including a recent event in which off-duty officers arrived within moments of shots fired in a busy shopping center parking lot. Second, beginning in May, BPD officers will receive training and be issued the latest in less-lethal technology, the Taser 10. The Taser 10 allows officers to use a less-lethal response in critical situations and works seamlessly with the body cameras that officers already wear. As soon as the taser is drawn from the holster, cameras in the vicinity will be immediately activated, ensuring that any use is recorded. This is the only remaining actionable item in President Obama’s Final Report of the President’s Task Force on 21 st Century Policing that the Bloomington Police Department has yet to complete. BPD is the last law enforcement agency in Monroe County to equip their officers with these tools. Also starting in May, Flock Safety Falcon cameras will be activated at various locations around Bloomington. These cameras monitor vehicular traffic and provide investigators with immediate information, based upon vehicle descriptors and/or license plate numbers, that can assist in locating suspect vehicles and vehicles associated with missing persons, Silver Alerts, and Amber Alerts. Flock cameras capture license plates and vehicle characteristics, not people or faces. Each search by a user requires a justification, and Flock does not share or sell data to third parties. The cameras will be used to solve property and violent crimes and are not intended to be used for minor traffic violations. BPD’s cameras will work with other Flock cameras already currently in use by other area agencies, thereby expanding the effectiveness of the technology. Currently over 4,000 communities and over 3,000 police departments utilize Flock cameras to help solve and deter crime. Communities using Flock technology have reported significant crime reductions. The Bloomington Police Department is confident that the deployment of the cameras will assist in a reduction of crime in this City as well. “These progressive policing tools facilitate collaboration, reduce crime, and allow officers to safely, efficiently protect our community,” said Mayor Thomson. “We are pleased to join other area agencies in adopting these leading technologies.” cob-logo-horizontal City Jobs Contact the City Report an Issue Connect on Social Media City Maps Transparency Accessibility Privacy Policy City Intranet City Hall 401 North Morton Street Bloomington, Indiana 47404 812-349-3400 Facebook Twitter Instagram NextDoor YouTube

---
snapshot_id: a7450aea-d225-5942-b8a7-1884b899e4e0
source_kind: own-site (the person's own site or account)
url: https://bloomington.in.gov/news/2024/05/02/5923

PUBLIC SAFETY HOUSING PILOT CANCELED | City of Bloomington, Indiana Skip to main content Mayor Kerry Thomson Search Search Services Services Information Info News News Meetings & Events Events City Government Govt. Breadcrumb News Releases 2024 May 02 PUBLIC SAFETY HOUSING PILOT CANCELED Share: Share on Facebook Share on Twitter Email this Page Page last updated on May 3, 2024 at 5:26 pm May 2, 2024 For more information, please contact Sharr Pechac, Director of Human Resources, [email protected] or 812-349-3404 Justin Crossley, Digital Brand Manager, Office of the Mayor [email protected] or 812-349-3406 PUBLIC SAFETY HOUSING PILOT CANCELED Today the Office of the Mayor announced that a pilot program to spend $3 million on mortgage assistance for 20 public safety officers has been canceled. The City will instead direct interested parties to an existing program that offers public safety officers $18,000 toward home purchase. Former Mayor John Hamilton announced the pilot program in February 2023, with the intent of boosting public safety recruitment and retention by offering $100,000 toward a down payment on a home in Bloomington. The City Council then committed an initial $500,000 to fund it. On December 15, 2023, after an unsuccessful search for a local partner, a contract was signed with Fahe to facilitate the mortgage assistance program. “We’ve spent several months working with the great people at Fahe to understand how this complicated program would be administered,” said Mayor Thomson. “After investigating the costs for the City and for participants, and consulting with police, fire, and union leaderships, we have come to the conclusion that this pilot would not be an equitable or cost-effective use of City funds. Instead, we’ll seek scaleable, sustainable solutions to attract and retain public safety officers.” Several factors led to the cancellation of the pilot, according to the Office of the Mayor. These include the high cost for a limited number of beneficiaries; the lack of criteria for when and how to evaluate the success of the 10-year program; and the financial impossibility of extending the benefit to all public safety officers or the City’s hundreds of other employees. The program would have cost $3 million over 10 years to provide mortgage assistance to 10 firefighters and 10 police officers. Each year, the City Council would have had to appropriate $200,000 ($10,000 per participant) to cover mortgage costs. In addition, the City would have had to put an additional $1 million into a nonrefundable reserve at Fahe. The $1 million fund would have covered the interest on all 20 mortgages in the pilot. It would have also served as Fahe’s insurance policy if and when the Council did not make the required annual appropriation of $10,000 per participant at any time during the 10-year pilot. Participating employees would have had to pay back the loan interest as well as pay additional payroll tax each year on their $10,000 annual appropriation. Eligibility for the program was to have been determined in two phases. New recruits would have had to finish probation and complete 1 year of service at the City, then apply to Fahe to pass their requirements. If a participant received a loan and later was terminated or otherwise became ineligible (for example, if the employee rented the house out instead of living in it, moved away, lost the house in a divorce, etc.), the City would have stopped paying and the employee would have become responsible for the remainder of the mortgage. City Council approved an initial $500,000 in American Rescue Plan Act (ARPA) funds for the program in February 2023, but it was later determined that those funds could not be used. The $500,000 would have come from the general fund instead to get the program started, and an additional $500,000 would have been due once Fahe had accepted 8 loans. At the time of the cancellation, no payments had been made yet. Since the program was announced in February 2023, 7 people have expressed interest. No one relocated or transferred based on the offer, and no one reached the stage of applying for Fahe eligibility. Fire Union Local 586 supports the decision to cancel the program. Paul Post, President of Don Owens Memorial Lodge 88, Fraternal Order of Police, commented, "We appreciate Mayor Thomson notifying us about this decision, and support her review of the previous administration's financial actions. The FOP looks forward to working with her administration to find further recruiting and retention efforts to get BPD back up to fully staffed and recognize the hard work of the existing officers." “We are very proud of our dedicated firefighters and police officers, and we are collaborating with Chiefs Kerr and Diekhoff, Human Resources, and union leadership to understand and meet their recruitment and retention needs in sustainable ways,” added Mayor Thomson. ### About Fahe Fahe is a network of 50+ community nonprofits serving Appalachia and other regions. Fahe provides people, especially those living in persistently poor rural counties, with the opportunity to fulfill their potential through access to housing, community services, and inclusive local economies. JustChoice Lending is the mortgage lending division of Fahe, with more than 15 years of experience connecting families with financial resources to secure homeownership. During the 2023 fiscal year, Fahe made total direct investments of $144.8 million. Total capital under management exceeded $300 million. Since 1980 Fahe has invested almost $2 billion and served more than 940,000 people. Learn more at fahe.org . cob-logo-horizontal City Jobs Contact the City Report an Issue Connect on Social Media City Maps Transparency Accessibility Privacy Policy City Intranet City Hall 401 North Morton Street Bloomington, Indiana 47404 812-349-3400 Facebook Twitter Instagram NextDoor YouTube