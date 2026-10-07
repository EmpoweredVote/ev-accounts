You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-pierce-medicare-aid-r3/labels/coder-2.json. Write JSON only, matching
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

politician_id: 72dd5219-490f-48bb-986e-183a6098d602  office_id: 7b3f68ef-bd9b-4316-9e39-89091b6e9aa1
Matt Pierce — Representative, Indiana (seated, level: state)
Current term: 2002-01-01 (precision: year) to present

## Topics (served ladder text — code against these words only)

### topic_key: medicare/aid
topic_id: cab61e8a-64fe-4bbd-bc08-fe9914d0091b  served_revision_id: 38bab357-9790-4cb3-a6d2-c43cbdca615b
Question: How should Medicare and Medicaid be funded and structured?
  1. expand Medicare to cover everyone regardless of age
  2. significantly expand Medicare or Medicaid eligibility, stopping short of universal coverage
  3. improve current programs while controlling costs
  4. scale back both programs, shifting more coverage to private insurance
  5. phase out both programs and use private insurance only

#### Annex

# medicare/aid — served revision 38bab357-9790-4cb3-a6d2-c43cbdca615b (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should Medicare and Medicaid be funded and structured?"

**Orientation:** standard. Rung 1 makes Medicare cover everyone, rung 5 ends both programmes. The
rungs order **how large the two public programmes are**: universal, larger, the same, smaller, none.

**Levels with a lever:** federal, state. Medicare is federal only. Medicaid is
joint: Congress sets the frame and the federal share; each state sets eligibility, benefits and
waivers inside it. So a state officeholder holds a lever on Medicaid and none on Medicare.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "Medicare Part A / B / C / D", "Medicare Advantage", "traditional Medicare", "premium
support", "voucher", "Medicare buy-in", "Medicare at 60" (or 55, 50), "Medicare for All",
"Medicaid expansion", "FMAP" (federal share), "block grant", "per-capita cap", "section 1115
waiver", "work requirements" or "community engagement", "CHIP", "dual eligibles", "drug price
negotiation", state Medicaid names ("Medi-Cal", "AHCCCS", "BadgerCare", "MassHealth", "TennCare",
"Healthy Indiana Plan").

1. **"expand Medicare to cover everyone regardless of age"**
   - Means: Medicare becomes the coverage for every person, of any age.
   - Operative clauses: [a] Medicare (the federal programme, or a programme that replaces it for
     all); [b] everyone, regardless of age.
   - Establishing evidence looks like: authoring or co-sponsoring a Medicare for All bill that enrolls
     every resident; own words calling for Medicare for everyone.
   - Levels that hold a lever: federal. A state cannot expand Medicare; a state single-payer plan is
     not Medicare → code it on `healthcare`; here a state officeholder's rung 1 is `scope-unavailable`
     (codebook 0.4 principle 5) _(proposed)_.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because a buy-in or a lower Medicare age is an expansion that
     stops short of everyone → rung 2.

2. **"significantly expand Medicare or Medicaid eligibility, stopping short of universal coverage"**
   - Means: many more people qualify for one of the two programmes, but not everyone.
   - Operative clauses: [a] **eligibility** for Medicare **or** Medicaid (one programme is enough);
     [b] significant; [c] short of universal.
   - Establishing evidence looks like: a single-subject bill or vote that lowers the Medicare age, or
     adopts the adult Medicaid expansion in a state; own words calling for such a change. Code the
     end state the instrument enacts: an instrument that stops short of everyone meets [c]; it does
     not need a second passage that rejects rung 1 _(proposed; adjudicated gold on another topic
     seated an instrument that met every clause of one rung, but not the extra clause of the
     stronger rung beside it, on the rung it met)_. If a surviving rung-1 passage also exists → V6
     `adjacent-chairs` rules apply.
   - Levels that hold a lever: federal (Medicare age, federal Medicaid rules); state (Medicaid
     eligibility).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a **narrow** eligibility change (one group, such as
     12-month postpartum coverage) is an expansion but not "significant" → `direction-only`
     _(proposed)_.
   - Benefits are not eligibility. Adding dental, vision or hearing to Medicare improves the programme
     → rung 3 clause [a], not rung 2 _(proposed)_.
   - S1 rung 2 named "lower Medicare age to 55 **and** expand Medicaid"; the served rung needs one of
     the two, not both.

3. **"improve current programs while controlling costs"**
   - Means: keep the two programmes' present shape, make them work better, and hold down what they
     cost.
   - Operative clauses: [a] improve current programmes (benefits, access, quality, administration);
     [b] control costs (drug price negotiation, payment reform, fraud and waste). Compound: one side
     only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a single-subject Medicare or Medicaid bill that does both, or
     two passages that each match one clause, inside current eligibility.
   - Levels that hold a lever: federal; state (Medicaid administration and payment rates).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because "controlling costs" can mean cutting coverage. A cut in who
     is covered is rung-4 territory, not [b].
   - "Protect Medicare", "no cuts to Medicare" names no clause → `direction-only` (it excludes rungs
     4 and 5 only).

4. **"scale back both programs, shifting more coverage to private insurance"**
   - Means: both Medicare and Medicaid cover less, and private insurance covers more.
   - Operative clauses: [a] scale back Medicare; [b] scale back Medicaid; [c] shift coverage to
     private insurance. Compound: one programme only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a premium-support or voucher plan for Medicare **and** a
     Medicaid cut or cap (block grant, per-capita cap, eligibility rollback); own words calling for
     both.
   - Levels that hold a lever: federal for [a] and [b]; state for [b] only.
   - At state level, a Medicaid-only scale-back → `compound-partial`: the rung says "both" _(ruled 2026-10-01)_.
   - Known chair-shaped instruments: _(none on file)_.
   - Medicare Advantage growth alone moves enrollees to private plans **inside** Medicare; it does not
     scale back the programme → `direction-only` _(proposed)_.
   - S1 rung 4 named "partially privatize Medicare **and** reduce Medicaid"; the served rung is about
     size ("scale back"), and needs both programmes.

5. **"phase out both programs and use private insurance only"**
   - Means: Medicare and Medicaid end, and private insurance is the only coverage.
   - Operative clauses: [a] phase out Medicare; [b] phase out Medicaid; [c] private insurance only (an
     absence clause: the passage must say it, V4.2).
   - Establishing evidence looks like: own words that call for ending both programmes.
   - Levels that hold a lever: federal. A state can leave Medicaid but cannot end Medicare → same
     scope question as rung 4.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a deep cut is not a phase-out. A plan that keeps either
     programme → not rung 5.

**Hard cases:**
- **The omnibus trap (codebook V4, [real]).** A Yea on the One Big Beautiful Bill Act (2025), a
  reconciliation bill covering taxes, Medicaid, immigration and more → `multi-subject`. Statements
  that defend its **work requirements** ("sound policy") speak to a narrower clause than any rung →
  `adjacent`.
- **Medicaid work requirements** on their own → `adjacent` (same codebook example) _(proposed for the
  stand-alone case)_.
- **Budget resolutions and appropriations** that assume Medicare or Medicaid savings → V4
  `multi-subject`; a budget resolution's assumptions are not law _(proposed)_.
- **A multi-subject bill that includes drug price negotiation** (climate, tax and health together) →
  `multi-subject`. Only an amendment or a separate vote on the negotiation provision can carry rung 3
  [b] _(proposed)_.
- **Medicaid enrollment procedure** (renewals after the pandemic, paperwork, enrollment drives) does
  not change who is eligible → `adjacent` _(proposed)_.
- **A Medicare for All bill** can also be evidence on `healthcare`. Code each topic on its own rung
  text.
- **Preemption (codebook V2, H12)** → `adjacent`.


## Sources

---
snapshot_id: 2e5ad88c-ec99-5efa-9e1a-f727a2abe8e9
source_kind: own-site (the person's own site or account)
url: https://repmattpierce.substack.com/p/2026-session-wrap-up-the-wins-the

2026 Session Wrap-Up: The Wins, The Draws and The Losses Rep. Matt Pierce's Newsletter Subscribe Sign in 2026 Session Wrap-Up: The Wins, The Draws and The Losses Rep. Matt Pierce Mar 11, 2026 Share Neighbors, This year’s official session lasted from the beginning of January to the end of February, with two weeks of session in December for Gov. Braun’s failed redistricting attempt. We had a short schedule this year, so the state legislature passed hundreds of bills all within the past two months. Now that the legislature has finished its work, here’s a breakdown of some of the wins, draws and losses from the 2026 legislative session. My takeaway? We hit a few singles when we could have hit some home runs. Defeating Statehouse Republicans’ Push to Redistrict At the start of this session, Hoosiers spoke up and stopped a national movement to redraw Indiana’s congressional maps. Gov. Braun and Indiana House Republicans attempted to give themselves an unfair advantage in our elections at Washington, D.C.’s request. But they couldn’t gerrymander our determination to fight this power grab. People reached out to their elected officials in record numbers, letting Indiana Republicans know that they believe in fairness and accountability. Hoosier values prevailed. Equal competition prevailed. Because of you, this rushed and unnecessary redistricting plan didn’t move forward. Fighting for Children and Families House Enrolled Act 1036: Children in Need of Services HEA 1036 closes a dangerous gap in child safety oversight by requiring the Department of Child Services (DCS) to perform an in-person, face-to-face assessment before closing an investigation or terminating a Child in Need of Services (CHINS) case. This bill was written in honor of 5-year-old Kinsleigh Welty, who tragically died after DCS prematurely closed her case. House Enrolled Act 1307: Department of Child Services (DCS) Ombudsman HEA 1307 increases accountability and oversight of DCS to strengthen protections for Indiana’s children. The DCS ombudsman must actively investigate complaints, review cases where children may have been put at risk and make recommendations where problems are found. House Enrolled Act 1325: Special Education HEA 1325 improves special education reporting and recommendations by requiring the Indiana Department of Health (IDOH), DCS, and the Office of the Secretary of Family and Social Services (FSSA) to report and make data-driven recommendations regarding residential placement, developmental preschool and special education. House Enrolled Act 1408: Education Matters HEA 1408 requires parental consent for minors under the age of 16 to access social media sites that use addictive algorithms, autoplay, or continuous scrolling. Apps must limit direct messages from people a minor doesn’t follow and which accounts show up in searches. Companies will also be prohibited from showing content or advertisements based on a minor’s previous interactions with an app. The bill goes into effect on January 1, 2027. Congress is considering similar legislation that may preempt this state legislation before it goes into effect. Expanding Patient Protections and Lowering Health Care Costs House Enrolled Act 1114: Coverage for Certain Cancer Prescriptions HEA 1114 provides patients with advanced cancer faster access to prescription medications by prohibiting step therapy. Step therapy requires patients to use drugs preferred by their insurance company and fail to respond to the treatment before they receive coverage for the prescription recommended by their doctor. House Enrolled Act 1029: Alzheimer’s Disease and Dementia Education HEA 1029 increases public awareness and education about Alzheimer’s disease and dementia. The bill requires the Indiana Department of Health (IDOH) to collaborate with national Alzheimer’s disease and dementia organizations to educate the public, identify partners for education and publish educational materials on its website. The goal is to inform Hoosiers about the risk factors, symptoms and treatment options available for the two diseases. This bill was authored in honor of S. Carmen Porter, State Rep. Gregory W. Porter’s (D-Indianapolis) late mother. Senate Enrolled Act 90: Consent for Pelvic, Prostate and Rectal Exams SEA 90 prohibits health practitioners from performing pelvic, prostate, or rectal examinations on an anesthetized or unconscious patient without informed consent. Senate Enrolled Act 189: Nonparticipating Providers SEA 189 prohibits insurance companies from imposing financial penalties on hospitals and facilities for care from an out-of-network provider. Strengthening Public Safety and Supporting First Responders House Enrolled Act 1048: VFD Clothing and Automobile Allowances HEA 1048 increases the clothing and automobile allowance for active members of volunteer fire departments from $100 to $250. The change will help offset the increases in costs of essential protective gear and vehicle-related expenses. Volunteer firefighters are critical for community safety and emergency response, and this bill is expected to improve recruitment and retention in volunteer fire departments. House Enrolled Act 1248: Advanced DNA Testing for Cold Cases HEA 1248 gives families a stronger voice in reopening unsolved violent crimes by allowing them to request advanced DNA testing in cold cases through approved nonprofits. Fundraising can be used to help cover the cost. Indiana currently has over 7,000 unsolved cold-case homicides and more than 1,100 missing person cold cases. Many of these cases contain DNA evidence that, with modern technology, could be reanalyzed to deliver justice for victims and their families. House Enrolled Act 1250: Public Safety Procedures HEA 1250 strengthens protections for victims of violent crimes by ensuring they’re notified before the release of a violent felon. The Indiana Department of Correction (IDOC) must notify law enforcement and the prosecuting attorney at least seven days before their release. The court and prosecuting attorney would then notify any victims of the felon’s release. Something for Utility Costs But Not Enough House Enrolled Act 1002: Electric Utility Affordability HEA 1002 is a step towards lowering Hoosiers’ energy costs, but the legislature could have done more. The bill begins switching our state to “performance-based ratemaking” (PBR), tying a utility company’s rates to multiple “performance incentive mechanisms” (PIM) like the quality of service provided, reliability, etc. Utility rate cases will shift to multi-year plans. Utility companies will be required to implement levelized billing plans for customers enrolled in an energy assistance program. This is a payment plan where monthly bills are based on average usage with occasional adjustments to account for the actual amount of energy used. Customers will be able to opt out of levelized billing. Companies will also be prohibited from disconnecting service to customers enrolled in a low-income assistance program during periods of extreme summer heat. I supported 12 amendments to improve the bill and lower energy costs immediately for Hoosiers. House Democrats’ proposals included my amendment eliminating the 7% sales tax on residential utility bills and offsetting that lost revenue by ending state tax breaks for data centers. Other amendments would have prevented private equity firms from acquiring utility companies and stopped utility companies from passing on to customers the costs of lobbying and political activity. All these amendments were voted down or blocked by House Republicans. Small Step Towards Affordable Child Care House Enrolled Act 1177: Child Care Assistance HEA 1177 expands the state’s Employer Child Care Expenditure Tax Credit. This credit encourages businesses to help cover the cost of child care for their employees by giving them money back on their taxes. This is one way to help provide child care, but the credit is limited to a maximum of $2.5 million. It also limits eligibility to businesses with up to 500 employees. With a low maximum and a 500-employee cap, the number of businesses that will be able to use this credit is limited. Senate Enrolled Act 4: Fiscal Matters SEA 4 is a wide-ranging bill that addresses several state financial and administrative policies. One of the provisions aims to address the child care crisis by allowing — not requiring — the State Budget Agency (SBA) to use up to $300 million from the 2025 state budget for the Child Care and Development Fund (CCDF) voucher program. Last year, Gov. Braun cut reimbursement rates for CCDF, which caused child care providers across Indiana to close due to funding losses. Republicans voted down a proposal offered by House Democrats that would have required the release of funds to alleviate the child care crisis. It remains to be seen whether the Governor’s Budget Agency will release the money. Republicans Block Attempts to Lower the Cost of Living The 2026 legislative session was a missed opportunity to provide Hoosiers relief from the rising cost of living. The Indiana House Democratic Caucus offered proposals to lower costs for your utilities, health care premiums, and child care. We fought for a first-time homebuyer savings program and for families to get the same tax breaks on utility bills as data centers. House Republicans blocked all of these proposals. Attacks on Public Education Senate Enrolled Act 199: Various Education Matters SEA 199 builds on Statehouse Republican attempts to exert more control over Indiana’s colleges and universities by allowing the state to restrict or eliminate degree programs that are considered “low-earning.” Degrees at-risk include theater, dance and certain associate degrees. This bill continues to walk Indiana down a dangerous path where the state can dictate what students can study in college. There’s a difference between informing students about the financial outcomes of a certain degree and outright eliminating it. I continue fighting these efforts to micromanage state universities and undermine the arts and humanities. House Enrolled Act 1004: Various Education Matters HEA 1004 is described by its supporters as a public education “deregulation” bill. But it makes sweeping changes to Indiana education law, including changing the powers of school corporations’ governing bodies and private-public agreements to construct and renovate charter schools. The nearly 200-page bill raises serious concerns by repealing union protections for teachers in joint programs, interlocal agreements, and special education cooperatives. HEA 1004 also makes it easier for schools to use money designated for teacher pay to cover other losses, potentially risking the livelihood of our public school teachers. Immigration Bill Puts Schools, Universities and Hospitals at Risk Senate Enrolled Act 76: Immigration matters SEA 76 mandates that state and government entities, including local law enforcement, K-12 schools, universities and hospitals, cooperate with U.S. Immigration and Customs Enforcement (ICE). Local governments are given civil and criminal immunity when cooperating with ICE requests. Indiana’s Attorney General will have the power to pursue lawsuits against a government entity that’s deemed non-compliant with ICE and sue employers who knowingly hire undocumented workers. Some other parts of the bill include a ban on sanctuary city policies and requiring hospitals to provide quarterly reports on the forms of ID used by Medicaid patients to identify possible undocumented immigrants. Republicans blocked Democratic proposals to prevent ICE enforcement in schools and hospitals, to protect victims of mistaken identity and to prevent Hoosiers from paying the cost of enforcing what is ultimately the responsibility of the federal government. I opposed this bill. After seeing how ICE operates — racial profiling, mistaken identification of detainees, and Americans killed in the streets. I can’t understand why the legislature would want to align every institution of state government with ICE. Rolling Back Environmental Protections Senate Enrolled Act 277: Indiana Department of Environmental Management SEA 277 weakens Indiana environmental protections by undermining the Indiana Department of Environmental Management (IDEM). It prohibits IDEM from adopting environmental rules that are more “burdensome” than federal standards and makes environmental oversight rules optional, such as setting standards for cleaning up hazardous waste. The act creates a narrow definition of PFAS, excluding thousands of variations of these synthetic forever chemicals from water quality protections. Giving the Governor a Military Police Force House Enrolled Act 1343: Public Safety Matters HEA 1343 establishes a military police force within the Indiana National Guard with the power to enforce laws against civilians when deemed necessary by the Governor. This military police force will have the authority to make arrests and conduct searches and seizures. The governor now has the authority to deploy this force into communities without the consent of local officials. I offered an amendment to remove this dangerous language from the bill. I supported other Democratic amendments to add additional guardrails, including required collaboration with local authorities and civilian law enforcement training. Every amendment was voted down by House Republicans. Criminalizing Homelessness Senate Enrolled Act 285: Housing Matters SEA 285 criminalizes homelessness in Indiana, making it a Class C misdemeanor to camp, sleep, or take long-term shelter on land owned by the state or units of government. Individuals could face a penalty of up to 60 days in jail and fines up to $500. Those who don’t qualify for an involuntary mental health hold and are first-time violators will receive a warning and be given information on shelters and services. If they’re still within a 300-foot radius more than 48 hours after their warning, they could be charged. I offered an amendment to this bill that would have prevented it from becoming effective until residential treatment facilities are operating that have the capacity to provide substance use disorder and mental health treatment to all of Indiana’s unhoused who need it. Criminalizing street camping and sleeping does nothing to solve the root causes of homelessness. In fact, a criminal record will add additional barriers to recovery and fines will continue the cycle of poverty. Instead of spending money on imprisonment and enforcement, we could use it to expand much-needed access to shelters, rehab centers and mental health services. More Restrictions for Medicaid and SNAP Senate Enrolled Act 1: Human Services Matters SEA 1 creates stricter eligibility criteria for Indiana Medicaid and SNAP. Applicants for Medicaid will be subject to higher co-pays, more frequent and stricter eligibility checks, new work requirements and fewer exemptions for the medically frail. Hoosiers enrolled in the Healthy Indiana Plan (HIP) must meet various work requirements three months before applying for Medicaid. SNAP will also have stricter eligibility checks and lower asset limits. Republicans claim SEA 1 is necessary to eliminate waste, fraud, and abuse in Medicaid and SNAP, yet they have presented no evidence that waste and fraud are prevalent in these programs. The additional bureaucratic red tape enacted in the name of combating fraud will actually result in eligible Hoosiers losing health and nutrition benefits because they won’t be able to keep up with the constant demands for more paperwork. Any applicant who cannot verify their legal immigration status will be referred to the U.S. Department of Homeland Security (DHS) for investigation. If you have any questions about this year’s legislation, you can visit iga.in.gov . Please reach out to me at h61@iga.in.gov with any comments, thoughts or concerns. Sincerely, Matt Pierce Share Top Latest No posts Ready for more? Subscribe © 2026 Rep. Matt Pierce · Privacy ∙ Terms ∙ Collection notice Start your Substack Get the app Substack is the home for great culture This site requires JavaScript to run correctly. Please turn on JavaScript or unblock scripts

---
snapshot_id: 349f2ada-5c23-5e51-8f89-44c36608dc89
source_kind: own-site (the person's own site or account)
url: https://repmattpierce.substack.com/p/rep-matt-pierces-august-newsletter

Rep. Matt Pierce’s August Newsletter Rep. Matt Pierce's Newsletter Subscribe Sign in Rep. Matt Pierce’s August Newsletter Indiana’s literacy scores increased, the gas tax quagmire and more. Rep. Matt Pierce Aug 31, 2026 Share Medicaid Disruption? I Can Help Across all of Indiana’s Medicaid programs – the Healthy Indiana Plan (HIP), Hoosier Healthwise, Traditional Medicaid and more – people are losing their coverage at an astonishing rate. Over the past year, 343,000 Hoosiers lost their coverage, one of the steepest enrollment drops in the nation . Roughly 40% of Medicaid cases up for renewal late last year were terminated for procedural reasons. This means eligible Hoosiers lost their Medicaid coverage from increased paperwork and red tape. As you can see from the chart below, ineligibility is not the major driver of Indiana’s enrollment drop. Credit: Indiana Capital Chronicle People are doing the best they can to keep up with constantly shifting requirements, but the system is clearly over capacity. Hundreds of thousands of eligible Hoosiers shouldn’t lose their health care coverage because of confusion or miscommunication. Republicans say the new bureaucratic trap doors are necessary to prevent fraud. Are these Medicaid changes really about preventing fraud or are they intended to reduce the number of people getting Medicaid to reduce costs ? The statistics and the stories from those affected point toward the latter. If you’ve been disenrolled and haven’t gotten answers from the Family and Social Services Administration ( FSSA ) about your case, I am here to help. Here’s What I Can Do: As a state representative, I can request FSSA review your case. This doesn’t mean I can jump an applicant to the front of a waitlist or that I have the power to get a preferred outcome, but it does mean someone at FSSA will look at your case. This is especially important given the stories I’ve heard recently about FSSA losing paperwork or letting cases slip through the cracks. Tips for Reaching Out: In your email requesting help , please share a brief explanation of your situation and be prepared to provide your address, date of birth, and contact information. If you are the caregiver for someone else, be prepared to share the same identifying information on behalf of whomever you are caring for. You can request help by emailing me at h61@iga.in.gov . I’m happy to help people overcome all of the new bureaucratic requirements to obtain the health care benefits for which they qualify. Indiana’s Literacy Scores Increase For the first time since the COVID-19 pandemic, Indiana’s third-grade reading scores have surpassed their pre-pandemic mark. Reading proficiency among third-graders reached 88.7% on the 2025-2026 IREAD exam. This is the fifth straight annual increase, and overall proficiency is higher than the pre-pandemic level of 87.3% in 2019. The gains were not limited to one group of students. Scores rose across the board for nearly every racial and ethnic group, students with disabilities, English learners, and students with free or reduced lunch. State officials may announce these literacy gains, but our teachers, school administrators, and parents made them possible . This important work is done in the classroom and at the kitchen table. Countless hours have been invested in our children’s futures to help them meet these benchmarks and create lifelong learners. Thank you to our educators and administrators, and thank you to our parents for your devotion to our students. To build on these gains and ensure the best for our students, the legislature must properly fund our public schools when the legislature adopts a new budget during the upcoming legislative session . The record number of school corporations sponsoring referendums to obtain more property tax revenue shows the legislature has not been adequately funding our schools. It can and should do better. Statewide Disaster Recovery Resources This month, Indiana has been devastated by severe storms and historic floods. Northwest Indiana was without electricity for almost two weeks, and at least 1,000 Hoosiers have been displaced or evacuated from flash floods in central and eastern Indiana. My thoughts are with those who’ve been affected, especially the families of the seven people who lost their lives. Thank you to our first responders, the Indiana National Guard, volunteers, linemen, and public works crews who’ve been working around the clock across the state to restore power and clean up debris. While o ur area did not experience significant damage from these storms , I want to share s ome information that might be helpful to any friends or family members located in the counties declared disaster areas. Statewide Disaster and FEMA Emergency Disaster Declaration Gov. Mike Braun has declared a statewide disaster emergency, and the Federal Emergency Management Agency (FEMA) has approved a major disaster declaration for Indiana. Federal FEMA assistance is now available in Carroll, Dearborn, Decatur, Delaware, Fayette, Franklin, Hamilton, Hancock, Henry, Lake, LaPorte, Madison, Marion, Morgan, Porter, Pulaski, Randolph, Rush, Tipton, Union, and Wayne counties. Resources for Impacted Hoosiers: Call 211: Individuals impacted can call 211 (866-211-9966) or visit the 211 website for more information on housing, financial relief, and reporting storm damage. Apply for the State Disaster Relief Fund: The state’s disaster relief fund is active and providing grants of up to $5,000 for emergency needs, including food and clothing. Individuals can find application information on the Indiana Department of Homeland Security’s website. Insurance: The Indiana Department of Insurance announced a 60-day moratorium on canceling any insurance policy in effect for any policyholder affected by the severe weather. This moratorium is not a waiver; it extends the period to pay the premium. After the 60 days, the policyholder will resume making premium payments. Document Everything: Those affected should take photos and videos of damage, track serial numbers on damaged items and keep receipts for any repairs or expenses related to the storm. This evidence will be necessary for filing an insurance claim or applying for state or federal assistance. Avoiding Scams Scammers often arrive shortly after disasters and take advantage of the uncertainty. The Office of the Attorney General has warned Hoosiers about individuals who are posing as FEMA agents. The most common scam is fraudsters pressuring homeowners to sign contracts on the spot to “reserve their spot in line” for repairs. Some offer to “manage” the insurance claim on behalf of the homeowner, or promise to waive deductibles, give referral discounts, or perform work for “whatever insurance pays.” If approached, individuals should ask for the person’s credentials and verify the identity of anyone claiming to offer flood relief services. They should a lso avoid risky payments like wire transfers and insist on a written agreement; FEMA never charges application fees. Anyone who suspects that they have encountered a scam is encouraged to report it immediately to the Indiana Attorney General’s Consumer Protection Division at indianaconsumer.com or by calling 1-800-382-5516. Indiana’s Gas Tax Quagmire On Aug. 5, Gov. Mike Braun declared a new emergency to allow the suspension of the two gas taxes for another 30 days. The Governor’s previous emergency declaration responding to the war in Iran could no longer be extended without approval of the General Assembly. The new emergency was blamed on the war in Ukraine and Canadian wildfires. Braun did not mention global oil disruptions caused by the war in Iran. I welcome cheaper gas prices from this suspension. Undoubtedly, people need these savings as gas prices climb. It’s better to be proactive than to wring our hands. But the Governor used a sleight of hand to extend the suspension without legislative approval or acknowledging the ongoing impact of President Trump’s war in Iran. More and more of our paycheck s go to gas, g roceries and utility bills. According to the chief economist at Moody’s Analytics, the Iran war has cost the average household more than $1,100 . There is no denying reality: as long as this war continues, Hoosiers will keep paying for it. Major cuts in Indiana ’s current budget created a large surplus that could be used to absorb the gas tax suspension, which is costing over $130 million per month . However, I am concerned that if the Iran war and gas tax suspension continue with no end in sight, the need to replace lost revenue for road repairs could crowd out funding desperately needed for priorities like schools, health care , child care, and affordable housing . Indiana damages from flooding, high winds could exceed $5B, Braun tells feds ‘Powerless’: Indiana families describe the toll of losing Medicaid access Indiana shifts $130M to replace road funding lost during gas tax holiday 38 Indiana school districts to seek property tax referendums this fall State paying $625K to settle lawsuit over Braun firing utility commission member Sincerely, Matt Pierce Share Top Latest No posts Ready for more? Subscribe © 2026 Rep. Matt Pierce · Privacy ∙ Terms ∙ Collection notice Start your Substack Get the app Substack is the home for great culture This site requires JavaScript to run correctly. Please turn on JavaScript or unblock scripts

---
snapshot_id: 9867b6c8-cfa8-5eb8-8b0a-1957fda23e1e
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/9d4c9fdb-cbec-4d10-b0a5-3455c6db752d

# On the Record — Matt Pierce (72dd5219-490f-48bb-986e-183a6098d602) ## forum — Bloomington Regular Session - OTR page: https://ontherecord.empowered.vote/meetings/9d4c9fdb-cbec-4d10-b0a5-3455c6db752d - Video: (no video url) - Date on On the Record: 2026-06-09 · date in the source's file name: 2026-03-23 - Kind: forum · Regular Session · Bloomington - Linked races: 0b5ae739-aa3a-4bfd-b1bf-57cc1c380fd9, 0bab4038-45bc-42b6-a1df-38b98e742952 [2:57] Thank you. I'm asking for your vote in the upcoming May primary because I want to continue being a progressive voice for our community and our community's values at the State House. And that means, you know, treating everyone with dignity and respect and not attacking and trying to marginalize communities, creating an economy that works for everyone. affordable housing which we know is a big issue accessible and affordable health care is another thing people are crying out for we need to support our public schools not private schools we shouldn't be diverting our money away from our public schools we need to defend academic freedom and free speech on the IU campus and our other institutions of higher education and the other thing we have to do is we have to protect democracy that's a sad thing to say and so that means fighting things like attempts to redistrict in the middle of the decade I've had amendments to unmask ice I opposed the governor's military police bill and the ice compliance as well [4:21] Okay. Again, as I was saying broadly, it's just this whole basket of issues surrounding preservation of democracy, and that means fighting off voter suppression and these attempts to kind of militarize the law enforcement. That's a key thing. I think one of the other key things is the economy. We cannot have a system where some people have fabulous wealth while a significant number of people are struggling just to get by, and you have the middle class shrinking in the middle. And so that's a key thing. And, you know, the housing and health care and all that kind of fits into that affordability kind of issue. And I think also. academic freedom and free speech on our campus. I mean, it's really sad what you see happening at IU, having protesters in Dunn Meadow being arrested, faculty members dismissed and punished without due process. These are all things that I think we need to push back on. [8:36] Well, the root of the problem goes all the way back to when the Daniels administration decided that having a regular agency, Department of Commerce, was not good enough for economic development because open-door laws and other transparency requirements applied to that agency. So they decided to create, spin off, this economic development corporation. And the idea was they needed to have these kind of secret negotiations and deals. And what happened is over time... That just spun out into corruption, basically. What you had is self-dealing within the IEDC, and you had these crazy things like the LEAP project. They went out and paid outrageous sums of money for land up there, and they didn't even do their due diligence to figure out whether they had enough water for the things they wanted to do there. And all that was at the expense of the taxpayers, and it was because there was not the kind of credibility or the transparency that they needed. A final one to throw in there is this foundation, which is an appendix of IEDC. And in that case, what they would do is they would get these big contributions, charitable contributions, from mostly utilities. And those then would be used for these worldwide junkets. In the name of economic development, they would go to the Formula One race over in Europe, and the governor would go there and say, I'm making deals, you know, here in the suites of the sports events. And there really was no accountability for that. So I voted for a fuller investigation of what actually happened there. I think the current governor is trying to just blame it all on the last governor and move on. And I think we need to go back and really get to the bottom and the details of what happened there. And so I'm hopeful that that will happen. [10:35] Well, I think at this point, environmental issues and energy issues are inextricable. They're just wrapped together. And so I served for a long time on the Environmental Affairs Committee, and then I had an opportunity to become the ranking member, Democratic member of the Utilities Committee. And I've been a relentless advocate for renewable energy and moving us to a clean energy economy. And one of the most frustrating and dispiriting things is just how there's no interest among the Republican Party to address the climate change problem, despite the evidence that is confronting us with these abnormal weather events, flooding, real significant economic impacts, and longer-term impacts that are going to cause people's grandchildren, future generations, to have real problems. And it's really outrageous that the current people in charge are not willing to do something to try to solve these problems. And so I'm doing everything I can to push us to promote solar, rooftop solar. I fought the net metering law that kind of destroyed the economics of people being able to afford rooftop solar and become more independent and save money on their own energy bills on top of it. I've tried to... create more competition with energy. So way back when, I had several years in a row I put in what was called a feed-in tariff bill. It was based on what Germany has, where they basically allowed anybody to plug in. If you had renewable energy, wind or solar, you had a right to sell that into the utilities grid. And that really boosted up the amount of renewables they had there. [15:36] I haven't seen any politics more cynical and hateful than the Republicans at the State House when it comes to the LBGTQ plus community. You know, this all goes back to 2004. George Bush was in trouble because of his wars going into the election. He needed something to drive his base out to the polls. And so they cynically said, let's make marriage equality the big issue. And the same thing happened at the State House. And we went through year after year. of having to fight off this effort to take the so-called Defense of Marriage Act and put it in the state constitution. And I'm proud that at the time, the Democrats were in the majority. I was the chair of the Courts and Criminal Code Committee, and that constitutional amendment passed out of the Senate was sent to my committee, and I killed it. I said, I'm not giving this bill a hearing. I'm not participating in this cynical, hateful process. Since then, they moved on because people actually, the issue turned on them, right? And they no longer had the political power to attack marriage equality, so now they're attacking trans people. And it's sad. I fought off those efforts to— To basically marginalize that community and I've authored co-authored several bills with representative Campbell from Lafayette that attempts to at least begin to claw back this attack on parents' rights to decide what kind of health care their kids could get when they need gender-affirming care. And so I'll continue to work on those issues. [17:30] Well, what I have found during my time in the legislature, that you have to demand respect from the majority party. You can't just be kind of the go-along, nice guy, junior partner. You've got to really get up in their face sometimes. But you have to balance it out, because if you get in their face too much you end up getting marginalized yourself and so what i found just you know one example is the speaker went too far one day and he ruled out we had an amendment to expand voting rights to an election bill called Various Elections Matters. And the speaker said that our amendment was not germane. It violated the rules and could not be voted upon, which was insane because this bill had like 50 different election provisions of all types in it. And so we appealed the ruling of the chair and we debated it and I basically told the other people, like, My fellow Democrats, stand back. I'm taking this one. And I really went after the Speaker full bore. And I went through every single provision in that bill. I pointed out that it said various elections matter for the title. And I said what the Speaker just did here today is an abuse of power. And I challenged them to say, why are you afraid to vote on these bills? Why are you hiding behind the rules? to prevent yourself from being held accountable to the voters. And I said, it's gotta stop. Now, the interesting thing is, For about the next week or so, there was not a single ruling by the Speaker that our amendments were out of order on stuff that I think probably was stretching it a little bit. So you've got to learn how to push hard and command respect. [22:12] The affordable housing issue is kind of one of the more complex issues that I've come across because you have so many variables and factors impacting it, everything from interest rates to housing supply. We now have hedge funds coming in and buying up homes, competing with average buyers, and they have endless funds to come in, and so we're seeing kind of the housing corporatized. And so you've got to approach it from a lot of different angles, and so we need to do a better job, and this is probably Congress's job on Section 8 vouchers. The wait lists are too long for that. We have to do more to try to get more housing. And, you know, I was excited when in this session the Republicans said that they were actually going to start addressing affordability issues. And one of the things they said they were going to address was housing. But what they ended up doing is they had a home builder spearhead the bill, and the home builder said the big problem is we have too many regulations. And so by the time this affordable housing bill actually got before us in its final form, after it had gone through both houses, it was like a joke. It essentially outlawed two safety items because the home builder said they were too expensive. They had a deal keeping your house from burning down. And it also limited what kind of flood mitigation they could do for these retention ponds and things. And then finally it just told every local community you have to have a hearing. To discuss how your zoning laws might be impacting building, which I think we've already had those debates in our community here, and we continue to have them. [24:23] come up first yeah yeah so I'm I'm pleased that when we had the Black Lives Matters protests and that issue was forefront. One of the things I did is I called up the Republican Person I'd worked with on criminal code reform and I said look this we cannot allow this moment to pass without doing something about police brutality and making clear that we have to have a different way forward and I was pleased that we were able to get a bill put together that prohibited things like chokeholds some things that were resulting in people being injured or killed and stress de-escalation and put into the training rubrics for people at the law enforcement academy processes to try to avoid getting into the situations that we've just seen happen over and over again and so we have to we have to keep after that because after a while kind of people forget and they they maybe resort back to the old ways but i think that the other thing that that bill did which i thought was really important is I believe the most police officers want to serve their community, they want to protect the community, and they're very public spirited. But we unfortunately have a few people who seem to have a different set of priorities. And what would happen is when someone would do something that violated the rules of their department, they would just resign and move to the next department, which was easy because there's a shortage of officers. This bill requires the last department to have to share all the information about their personal records with the new potential hires. [28:15] Yeah, I have to admit, there's some days where just things go so crazy up there, you just want to kind of drop your head on the desk and say, like, I surrender. I mean, what can you possibly do to talk any sense into people? Or the worst thing I hate is, like, you made really good points on that bill, but I couldn't vote with you because, you know, my leadership would get mad at me or something. But, you know. There are just enough victories to keep me going. and that's really what continues to motivate me we had a tremendous victory by defeating redistricting and that was awesome and there are lesser victories that people don't particularly hear about all the time one that i can think of we had last session was uh this crazy bill that wanted to move to uh firing squads for executions which just like the nuttiest thing ever And, you know, I really pushed back on that bill, and it couldn't get enough votes within the House to actually move on to the Senate. And I thought that was another, you know, opportunity. So I think that the worst thing we can do is think of ourselves as helpless and hopeless and not having an ability to impact the system. And so particularly right now, I feel like coming up in this election in the fall, we have an opportunity to really take back some power to change the direction of the country and the state. And I think that is the critical thing to keep people focused on is don't give up hope. It's frustrating. It's dispiriting when you see this horrible legislation continue to come through the process. But we've had some victories, and we can have more victories if we all work together and focus on, basically, gaining that political power at the ballot box. [30:09] Yeah, this is really... um tough because i've offered some amendments on that i've been kind of i think it's because i drew the short straw but it ended up being like the house democrats point person on redistricting so i had to read all those grinding legal cases and everything and I think that it is achievable. It's happened in other states, but it's going to take a long-term movement. You know, I think it's something like the women earning the right to vote. I mean, those were multi-decade kinds of efforts, civil rights movement. I think it has to be something up to that level where it's almost a movement and you have to get people engaged enough to understand the impacts of redistricting. I think it's a root of a lot of our problems because when you pack all the Democrats together to dilute their power and that then creates lopsided Republican districts, the primaries become the elections that matter. And the general elections are really just kind of a rubber stamp kind of thing, and this reduces the accountability of the members. You know, there was a time when you had like a 52-48, 51-49 split in the House. Even a 55-48. A 45 split, which was considered a huge majority in those days. You could literally see people sweating as they were thinking about how to vote. They would see stuff like, oh, how are my people going to explain this back home? And now with 70 members and these lopsided districts, there's no sweating in the General Assembly. People just vote. how they want to they pander to their most extreme bases and there's no um there's no accountability because of that so we definitely need to do something on redistricting [34:24] Yeah, I think it's going to take a lot of education, particularly because, you know, over my objections, the Republicans adopted a law which took away the right of the student ID to be used as a voter ID, even though it met every exact. And I made the author of the bill. For like 15 or 20 minutes, I led him through every single aspect of this, and he could not give a good reason why they were doing it. And so that makes it harder to vote. So you've got to educate people about what you need to do to vote. One of the saddest things that I see, and it happens every election cycle, if you go to the county election board when they meet about 10 days after the election, they go through their provisional ballots. there will be 60 or 80 students who showed up to vote and they're not registered they're not registered in the county they're not even from the state they just showed up because they decided they wanted to vote and participate but they didn't understand that you have to get registered by a certain deadline that you have to get to the right precinct and what happened is you know i don't know if they thought their um provisional ballot would just magically count or what but it didn't and to think about all those votes that are not being accounted for is really bad so education is a key thing and then secondly the other part of education is helping people to understand who is doing what to them One reason why politicians are not held accountable when they don't address the needs of the people is because with this crazy media we have, social media, you can't figure out who's doing what to whom. And so we've got to work much harder for people to understand what votes, what parties are for their interests and against their interests. [36:32] Well, I think if you get back to the Indiana Economic Development Corporation, one of the biggest problems is they just got into this mindset of we're going to get the Fortune 500 company to come build a big factory here because we're going to give them these tremendous benefits. We will outbid the corporate welfare that we'll give to the people to get them here. And they ignored the ability of the small businesses, the startups right here. And so this is one thing where I agree with Governor Braun. He seems to be trying to redirect IEDC to be more focused toward something beyond just central Indiana and kind of the big corporations and the big kind of long bomb deals like the Leap District. And so I think that we need to redirect our efforts so that small businesses, that business that is prospering and it needs to get to the next level but it needs some help to get there, how do we help them do that? And then... We have to make sure that that assistance gets out across the state. And for Bloomington, it's particularly important that we support the tech sector, right? So we have a tech park here. We have a lot of people working really hard to build off of the industries we have now and to figure out how to get this kind of startup entrepreneurial economy going. And I think that if we put more effort into that, we have an opportunity to start some small businesses, some startups that could end up being quite substantial companies that would really help our community because we need better, higher-paying jobs in our community. We don't have enough of those. [40:03] think I'm up first okay all right you know one of the things that I think is really important if you're serving as a legislator is to look around the hearing rooms and the hallways of the Capitol and ask yourself who's not here Because oftentimes you hear only from the interest groups that can afford to have paid lobbyists at the State House who are there constantly, who build the relationships, who become friendly with legislators. And their viewpoints always get across. But there are many average everyday Hoosiers. who aren't organized in a way with the resources to have somebody on the scene at the state house every day working for their interests. And so that's where the responsibility of the legislators who represents all the people within his or her district. that legislator has to be thinking about who's not here, who's getting left out of the conversation. And that's one thing that I really pride myself on. So when the payday lenders show up and say, we need less regulation because we need to give people access to capital, I say, look, guys, this is not Fortune 500 companies talking about. You're exploiting struggling people. So let's not come up with some phony excuses for why you need stuff. We know what's going on here. And so people need legislators who will call out those people who want to prey upon people who are struggling the most. And so that's why I very much would like to be returned to the legislature. I'm asking the voters to return me there for another two years so I can continue working on those issues and representing all the people of District 61. [74:45] It was a good. [78:50] We got one going.

---
snapshot_id: 96cd33c0-2f03-5a1f-9cd5-11291c3ca704
source_kind: own-site (the person's own site or account)
url: https://repmattpierce.substack.com/p/rep-matt-pierces-september-newsletter

Rep. Matt Pierce’s September Newsletter Rep. Matt Pierce's Newsletter Subscribe Sign in Rep. Matt Pierce’s September Newsletter Check your voter registration, holding utilities accoutable and more. Rep. Matt Pierce Sep 30, 2026 Share Town Hall: Healthy Indiana Plan (HIP) Work Requirements On Monday, Oct. 12, the Family and Social Services Administration (FSSA) will host a town hall with Covering Kids and Families for HIP members, providers, and community partners to learn more about upcoming work requirements. The town hall will be at Ivy Tech Bloomington in Shreve Hall (200 Daniels Way, Bloomington, IN) from 6 to 7:30 p.m. I encourage anyone enrolled in HIP to attend. This is a good way to learn about upcoming changes, discuss your options and chat with FSSA representatives face-to-face. Upcoming HIP Work Requirements Starting Jan. 1, 2027, Medicaid enrollees on the Healthy Indiana Plan (HIP) must meet new work requirements to keep their healthcare coverage. If you are on a Traditional Medicaid plan (including Hoosier Healthwise, Hoosier Care Connect, or Indiana PathWays for Aging), these changes do not apply to you. Existing and new HIP recipients aged 19-64 must complete 80 hours of work per month in qualifying activities, including employment, job training, part-time education and community service. Enrollees can combine these activities to meet the 80-hour monthly requirement. Recipients must meet these work requirements three months before they apply for or renew their HIP coverage. Individuals planning to enroll or renew in January 2027 must meet the required 80 hours in October 2026. In addition to these new work requirements, recipients must renew HIP every six months. The state will verify required hours every t hree months. Many HIP recipients will likely be exempt from work requirements, including pregnant women, veterans with a 100% disability rating, caregivers and the medically frail. For a full list of exemptions, visit the FSSA’s HIP work requirements page. Without an exemption, recipients must meet these requirements. If hours are not reported, coverage will be terminated, preventing recipients from getting Marketplace financial help. Recipients can check if these changes apply to them on the FSSA’s Benefit Portal . HIP enrollees have three months before work requirements take effect. Those currently on HIP or likely to enroll in the coming months can find more information in English and Spanish on the FSSA’s website. Republicans claim these new requirements will reduce fraud. I oppose them because claims of fraud are overblown. A majority of HIP recipients are working and just need help affording astronomical healthcare premiums. What will really happen is that eligible recipients will be kicked off the program because of a blizzard of never-ending paperwork that will be difficult to keep up with. This new scheme will also cost the state a lot of money to administer. Please contact me if you need assistance with the new requirements by emailing me at h61@iga.in.gov . Holding Utility Companies Accountable After severe weather in Northwest Indiana on Aug. 11, the Northern Indiana Public Service Company (NIPSCO) experienced its largest outage in the utility’s history. Hundreds of thousands were without electricity, with over 374,000 outages reported. In some cases, households had no power for two weeks. Northwest Indiana residents incurred massive, unexpected costs from food and medication loss, long hotel stays and extended usage of gas-powered generators. This came despite NIPSCO customers paying the highest average utility bills in the state, and the company raising its electric bills by roughly $23 per month to improve “reliability.” That’s why I called for a legislative investigation. I authored a letter with my fellow Northwest Indiana House Democrats, calling on legislative leaders to assign the Interim Study Committee on Energy, Utilities and Telecommunications the task of reviewing NIPSCO’s storm response. We urged legislative leaders to have the committee hold public hearings in Northwest Indiana so we could hear directly from NIPSCO customers. Instead, Statehouse Republicans scheduled a single meeting in Indianapolis, held on Sept. 29. The committee meeting was a missed opportunity to better understand the harms suffered by residents of the area. Residents wishing to testify had to take off work and drive to Indianapolis. I envisioned a multiple hearing effort to understand what happened and why it took so long to restore power. NIPSCO did send a representative to speak, but the chair of the committee discouraged specific questions about its storm response. Instead, the committee was redirected to a broader discussion of energy utility reliability and resilience while waiting for the Indiana Utility Regulatory Commission (IURC) to complete its own investigation of the outages. If the legislature is serious about understanding what happened to ensure something like this never happens again, the committee should spend more than one day on the issue. A two-week outage deserves more than one day of proceedings. We should have met three times, as allowed under Indiana law, and held a meeting in Northwest Indiana to hear from those affected. Republicans have justified pro-utility legislation that has resulted in skyrocketing utility rates as necessary to ensure reliable service. Despite major NIPSCO rate increases over the past decade, its response to the storm was slow and poorly executed. The committee voted on a committee report with a few general recommendations. More than that will have to be done if we want better responses to natural and manmade disasters in the future. I look forward to hearing the results of the IURC’s investigation into NIPSCO’s storm response. I hope the findings are something of substance that will move the legislature to pass comprehensive legislation that will hold utilities accountable when they fail to adequately respond to emergencies. If you would like to watch the meeting, you can watch the archived video on the IGA website. Get Out the Vote and Check Your Registration Voting is one of our most sacred rights as Americans. The next election is Tuesday, Nov. 3, 2026. To vote in this election, you must be registered by Monday, Oct. 5. To check your voter registration status, click here . In the “Check Your Voting Status” box, enter your legal first and last name, date of birth, and county of residence. If you are registered to vote, the portal will show you local polling locations, candidates on the ballot and information on requesting an absentee ballot. You can also vote early in-person. If you’ve moved since the last election, you’ll need to update your registration to be able to vote. If you aren’t currently registered to vote, you can register on the same webpage under the “Register To Vote” box. You’ll need a valid driver’s license or state-issued ID card number and your current address. Remember, in Indiana, you have the right to vote if: You are both a U.S. citizen and a resident of Indiana. You will be at least 18 years of age on or before the next general or municipal election. You are not currently incarcerated following a conviction. You have lived in the precinct where you vote for at least 30 days before the election. You are registered to vote. Once you register, you should receive a confirmation of your registration in the mail. You can also track your application status and/or registration through the online portal. Indiana sees surge of cities, counties ending Flock camera contracts As work requirements loom for Medicaid, state officials worry about readiness Indiana school voucher use has flipped from low-income families to more high-income families using them Want a say in Indiana’s next budget? Here’s how to tell your state lawmaker Sincerely, Matt Pierce Share Top Latest No posts Ready for more? Subscribe © 2026 Rep. Matt Pierce · Privacy ∙ Terms ∙ Collection notice Start your Substack Get the app Substack is the home for great culture This site requires JavaScript to run correctly. Please turn on JavaScript or unblock scripts