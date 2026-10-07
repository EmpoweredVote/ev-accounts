You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-pierce-deportation/labels/coder-1.json. Write JSON only, matching
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

### topic_key: deportation
topic_id: 44905f3b-e105-4f6c-afc7-5d223813dbac  served_revision_id: 55c3167e-3ad8-425d-a699-b2e91552d912
Question: How far should the government go in deporting undocumented immigrants?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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
snapshot_id: 5f5ea07a-ba29-551d-add5-58fa5c06473a
source_kind: own-site (the person's own site or account)
url: https://www.indianahousedemocrats.org/news/house-republicans-reject-amendment-to-unmask-ice

House Republicans reject amendment to unmask ICE &mdash; Indiana House Democratic Caucus 0 Skip to Content Members Members Leadership IHDC Staff Need Help? News Newsroom Press Inquiries IBLC Indiana Black Legislative Caucus History of the IBLC IBLC Events 2026 Agenda Student Opportunities Internships Page Program Policy Briefs The Big Beautiful Bill's Impact on Indiana Open Menu Close Menu Open Menu Close Menu Members Members Leadership IHDC Staff Need Help? News Newsroom Press Inquiries IBLC Indiana Black Legislative Caucus History of the IBLC IBLC Events 2026 Agenda Student Opportunities Internships Page Program Policy Briefs The Big Beautiful Bill's Impact on Indiana Folder: Members Back Members Leadership IHDC Staff Need Help? Folder: News Back Newsroom Press Inquiries Folder: IBLC Back Indiana Black Legislative Caucus History of the IBLC IBLC Events 2026 Agenda Folder: Student Opportunities Back Internships Page Program Folder: Policy Briefs Back The Big Beautiful Bill's Impact on Indiana House Republicans reject amendment to unmask ICE Rep. Matt Pierce Feb 17 Written By Anna Groover Yesterday, Feb. 16, State Rep. Matt Pierce (D-Bloomington) offered an amendment to Senate Bill 160. The amendment would have required the Law Enforcement Training Board to adopt a statewide policy prohibiting officers from wearing a mask during official duties, with exceptions for situations such as tactical operations and undercover work. It also would have made it a class A misdemeanor for a law enforcement officer to wear a mask with the intent to commit or conceal the commission of a criminal act. It would have applied to federal law enforcement agencies, including Immigration and Customs Enforcement (ICE). House Republicans voted down the amendment 33-59 . Pierce released the following statement: “I asked Republicans what kind of country and state they want to live in today. Do we want to live in a nation or state where masked agents with no identification can stop and demand proof of citizenship, and then arrest and send us off to a distant detention center? “I don’t want to live in that kind of state or country. I don’t want to live in a place where masked agents demand to see your papers on the street. That is a big step towards authoritarian government. “Republicans love to talk about the dangers of big government. We hear complaints about interference with property rights or too much regulation of businesses. Yet masked agents on the streets of America violating the constitutional rights of its residents, including unjustifiable killings, are met with deafening silence. “This amendment was a chance for the General Assembly to stand up and demand the federal government respect our freedoms and liberties. Instead, Republicans said ‘no’ to preserving what so many of us took for granted.” Anna Groover Previous Previous Porter bill increasing awareness for Alzheimer’s disease and dementia heads to governor’s desk Next Next IBLC mourns passing of Rev. Jesse Jackson Indiana House Democratic Caucus 200 W. Washington St., Indianapolis, IN 46204 Toll-free: 1-800-382-9842 Site Map Members Members Leadership IHDC Staff Need Help? News Newsroom Press Inquiries IBLC Indiana Black Legislative Caucus History of the IBLC IBLC Events 2026 Agenda Student Opportunities Internships Page Program Policy Briefs The Big Beautiful Bill's Impact on Indiana

---
snapshot_id: 79c56604-2c43-59c4-ac07-0b604371d804
source_kind: public-record
url: https://iga.in.gov/pdf-documents/124/2026/senate/bills/SB0076/rollcalls/SB0076.240_H.pdf

Indiana House of Representatives S ECOND R EGULAR S ESSION 124 TH G ENERAL A SSEMBLY F EB 12, 2026 3:19:20 PM Roll Call 240: Bill Passed SB 76 - Prescott - 3rd Reading Yea 61 Immigration matters Nay 28 Excused 11 Not Voting 0 Presiding: Speaker Y EA - 61 Abbott Greene Lindauer Smaltz Aylesworth Haggard Lucas Smith, H Baird Hall May Snow Barrett Heaton McGuire Soliday Bartels Heine McNamara Steuerwald Bascom Hostettler Meltzer Sweet Behning Ireland Miller, D Teshka Borders Isa Morris Thompson Carbaugh Jeter O'Brien VanNatter Cash Jordan Olthoff Wesco Commons Judy Payne Yocum Criswell Karickhoff Pierce, K Zimmerman Culp King Prescott Mr. Speaker Davis Lauer Pressel DeVon Lawson Shonkwiler Goss-Reaves Lehman Slager N AY - 28 Andrade DeLaney Johnson, B Pfaff Bartlett Dvorak Klinker Pierce, M Bauer Garcia Wilburn Lopez Porter Burton Genda Moed Pryor Campbell Gore Moseley Shackleford Clere Hamilton Novak Smith, V Dant Chesser Harris Pack Summers E XCUSED - 11 Engleman Hatcher Manning Patterson Errington Jackson, C Mayfield Rowray GiaQuinta Ledbetter Miller, K N OT V OTING - 0 v. 1.1 [extracted by pdf-snapshot.ts with strike detection, 2026-10-07T17:02:55.584Z, https://iga.in.gov/pdf-documents/124/2026/senate/bills/SB0076/rollcalls/SB0076.240_H.pdf, from saved file]

---
snapshot_id: b4226e81-1cf9-5237-b3b8-34b70433b2f5
source_kind: own-site (the person's own site or account)
url: https://www.indianahousedemocrats.org/news/pierce-rejects-bill-forcing-all-levels-of-state-government-schools-and-universities-to-assist-ice

Pierce rejects bill forcing all levels of state government, schools, and universities to assist ICE &mdash; Indiana House Democratic Caucus 0 Skip to Content Members Members Leadership IHDC Staff Need Help? News Newsroom Press Inquiries IBLC Indiana Black Legislative Caucus History of the IBLC IBLC Events 2026 Agenda Student Opportunities Internships Page Program Policy Briefs The Big Beautiful Bill's Impact on Indiana Open Menu Close Menu Open Menu Close Menu Members Members Leadership IHDC Staff Need Help? News Newsroom Press Inquiries IBLC Indiana Black Legislative Caucus History of the IBLC IBLC Events 2026 Agenda Student Opportunities Internships Page Program Policy Briefs The Big Beautiful Bill's Impact on Indiana Folder: Members Back Members Leadership IHDC Staff Need Help? Folder: News Back Newsroom Press Inquiries Folder: IBLC Back Indiana Black Legislative Caucus History of the IBLC IBLC Events 2026 Agenda Folder: Student Opportunities Back Internships Page Program Folder: Policy Briefs Back The Big Beautiful Bill's Impact on Indiana Pierce rejects bill forcing all levels of state government, schools, and universities to assist ICE Rep. Matt Pierce Feb 13 Written By Anna Groover Yesterday, Feb. 12, Senate Bill 76 passed the House of Representatives by a vote of 61 to 28. Because the bill was amended in the House, it returns to the Senate to approve the House changes or to request a conference committee to reconcile differences in the bill. SB 76 requires local governments, law enforcement, schools and universities to assist U.S. Immigration and Customs Enforcement (ICE), including complying with detainer requests. The state attorney general is given broad powers to investigate any of these entities he feels is not sufficiently compliant with ICE and to seek penalties against them. State Rep. Matt Pierce (D-Bloomington) released the following statement: "Why do we want to give our full, complete compliance to an organization that has proven itself to be poorly trained, incompetent, not able to follow our laws or constitution, and has caused the deaths of innocent U.S. citizens? We don't have to have this bill. We don't have to completely entangle our entire state with this deadly force that's spreading chaos and violence wherever it goes. "It doesn't help that the bill gives our ethically challenged attorney general immense power to investigate and seek penalties against anyone he deems not sufficiently compliant with ICE. We should know better than to hand the attorney general this power." Anna Groover Previous Previous Pryor concerned about civil rights violations under new immigration bill Next Next Miller opposes Senate immigration bill Indiana House Democratic Caucus 200 W. Washington St., Indianapolis, IN 46204 Toll-free: 1-800-382-9842 Site Map Members Members Leadership IHDC Staff Need Help? News Newsroom Press Inquiries IBLC Indiana Black Legislative Caucus History of the IBLC IBLC Events 2026 Agenda Student Opportunities Internships Page Program Policy Briefs The Big Beautiful Bill's Impact on Indiana

---
snapshot_id: 297c3d77-e35c-52ff-8bf0-36e1996fabaf
source_kind: public-record
url: https://iga.in.gov/legislative/2026/bills/senate/76/details

IGA | Senate Bill 76 - Immigration matters (2026) Indiana General Assembly 2026 Session. Senate Bill 76 Immigration matters. Enrolled Senate Bill (S) Authored by: Sen. Liz Brown, Sen. Chris Garten, Sen. Tyler Johnson. Co-Authored by: Sen. Scott Alexander, Sen. Mike Bohacek, Sen. Ed Charbonneau, Sen. Stacey Donato, Sen. Jeff Raatz, Sen. Michael Young, Sen. Eric Koch, Sen. Gary Byrne. Sponsored by: Rep. J.D. Prescott, Rep. Chris Jeter, Rep. Garrett Bascom, Rep. Michelle Davis. [Excerpt: the bill details page header and author block only, saved by browser from iga.in.gov/legislative/2026/bills/senate/76/details on 2026-09-26. The digest that follows on the page is not included; the bill text is saved separately.]

---
snapshot_id: 361d58f8-cc6b-53b1-9c37-1c0dbfba907c
source_kind: public-record
url: https://iga.in.gov/pdf-documents/124/2026/senate/bills/SB0076/SB0076.01.INTR.pdf

Introduced Version SENATE BILL No. 76 _____ DIGEST OF INTRODUCED BILL Citations Affected: IC 4-6-2-1.5; IC 5-2-18.2; IC 12-8-1.5-21; IC 22-5-9; IC 32-30-7-7; IC 36-2-13-9. Synopsis: Immigration matters. Provides that if a law enforcement officer, governmental body, or a postsecondary educational institution is made a party to a civil suit and the attorney general determines that the suit has arisen out of certain acts, the attorney general shall defend the law enforcement officer, the governmental body, or the postsecondary educational institution throughout the action. Clarifies that the enforcement of federal immigration laws may be carried out by federal, state, or local law enforcement. Removes the mens rea standard in the statute concerning governmental entities or postsecondary institutions violating the citizenship and immigration status information and enforcement of federal laws chapter. Provides that a governmental body that has the custody of an individual who is the subject of an immigration detainer request shall: (1) provide the judge authorized to grant or deny the individual's release on bail notice that the individual is subject to an immigration detainer request; (2) record in the individual's case file that the individual is subject to an immigration detainer request; (3) comply with the immigration detainer request; and (4) inform the individual that the individual is being held pursuant to an immigration detainer request. Requires a judge who receives notice that an individual is subject to an immigration detainer request to ensure that the notice of the immigration detainer request is recorded in the court's record. Prohibits an employer from recklessly or intentionally hiring or employing an unauthorized alien. Requires the office of the secretary to submit a report to the legislative council concerning certain information. Provides that if the attorney general, an agency, or a law enforcement agency determines that probable cause (Continued next page) Effective: Upon passage; July 1, 2026. Brown L December 8, 2025, read first time and referred to Committee on Judiciary. 2026 IN 76—LS 6446/DI 151 Digest Continued exists that an employer has hired or employed an unauthorized alien the agency, attorney general, or law enforcement agency shall provide notice to the United States Department of Homeland Security. Provides that a governmental entity that employs a prosecuting official is entitled to investigative costs and costs in an indecent nuisance action. Requires the department of correction to provide training to all sheriffs-elect concerning cooperation with the United States Immigration and Customs Enforcement. 2026 IN 76—LS 6446/DI 151 Introduced Second Regular Session of the 124th General Assembly (2026) PRINTING CODE. Amendments: Whenever an existing statute (or a section of the Indiana Constitution) is being amended, the text of the existing provision will appear in this style type, additions will appear in this style type, and deletions will appear in this style type. Additions: Whenever a new statutory provision is being enacted (or a new constitutional provision adopted), the text of the new provision will appear in this style type. Also, the word NEW will appear in that style type in the introductory clause of each SECTION that adds a new provision to the Indiana Code or the Indiana Constitution. Conflict reconciliation: Text in a statute in this style type or this style type reconciles conflicts between statutes enacted by the 2025 Regular Session of the General Assembly. SENATE BILL No. 76 A BILL FOR AN ACT to amend the Indiana Code concerning state and local administration. Be it enacted by the General Assembly of the State of Indiana: 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 SECTION 1. IC 4-6-2-1.5, AS AMENDED BY P.L.55-2025, SECTION 1, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2026]: Sec. 1.5. (a) Whenever any state governmental official or employee, whether elected or appointed, is made a party to a suit, and the attorney general determines that said suit has arisen out of an act which such official or employee in good faith believed to be within the scope of the official's or employee's duties as prescribed by statute or duly adopted regulation, the attorney general shall defend such person throughout such action. (b) Whenever a teacher (as defined in IC 20-18-2-22) is made a party to a civil suit, and the attorney general determines that the suit has arisen out of an act that the teacher in good faith believed was within the scope of the teacher's duties in enforcing discipline policies developed under IC 20-33-8-12, the attorney general shall defend the teacher throughout the action. 2026 IN 76—LS 6446/DI 151 2 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 (c) Not later than July 30 of each year, the attorney general, in consultation with the Indiana education employment relations board established in IC 20-29-3-1, shall draft and disseminate a letter by electronic mail to the listed electronic mail address of teachers providing a summary of the teacher's rights and protections under state and federal law, including a teacher's rights and protections relating to the teacher's performance evaluation under IC 20-28-11.5. (d) The department of education, in consultation with the Indiana education employment relations board, shall develop a method to provide the attorney general with the names and electronic mail addresses of active teachers in Indiana in order for the attorney general to disseminate the letter described in subsection (c). Names and electronic mail addresses collected and provided to the attorney general under this subsection are confidential and excepted from public disclosure as provided in IC 5-14-3-4. (e) Whenever a school corporation (as defined in IC 20-26-2-4) is made a party to a civil suit and the attorney general determines that the suit has arisen out of an act authorized under IC 20-30-5-0.5 or IC 20-30-5-4.5, the attorney general shall defend the school corporation throughout the action. (f) Whenever a law enforcement officer (as defined in IC 5-2-18.2-2), governmental body (as defined in IC 5-2-18.2-1), or postsecondary educational institution (as defined in IC 5-2-18.2-2.2) is made a party to a civil suit and the attorney general determines that the suit has arisen out of an act authorized or required by IC 5-2-18.2, the attorney general shall defend the law enforcement officer, the governmental body, or the postsecondary educational institution throughout the action. (f) (g) As used in this subsection, "bridge authority" refers to the New Harmony and Wabash River bridge authority established by IC 8-16-15.5-2. Whenever: (1) the bridge authority; (2) a member of the bridge authority; (3) an officer of the bridge authority; or (4) an employee of the bridge authority; is made a party to a civil suit and the attorney general determines that the suit has arisen out of an act or omission of any person described in subdivision (1), (2), (3), or (4), that is authorized or required under IC 8-16-15.5 or any other law, the attorney general shall defend that person throughout the action. (g) (h) A determination by the attorney general under subsection (a), (b), (e), or (f), or (g) shall not be admitted as evidence in the trial of 2026 IN 76—LS 6446/DI 151 3 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 any such civil action for damages. (h) (i) Nothing in this chapter shall be construed to deprive any such person of the person's right to select counsel of the person's own choice at the person's own expense. SECTION 2. IC 5-2-18.2-1.7 IS ADDED TO THE INDIANA CODE AS A NEW SECTION TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2026]: Sec. 1.7. As used in this chapter, "immigration detainer request" means a request issued by an authorized immigration officer to a law enforcement agency to detain an individual pursuant to 8 CFR 287.7. SECTION 3. IC 5-2-18.2-4, AS AMENDED BY P.L.265-2017, SECTION 3, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE UPON PASSAGE]: Sec. 4. A governmental body or a postsecondary educational institution may not limit or restrict the enforcement of federal immigration laws, regardless of whether the enforcement is carried out by a federal, state, or local law enforcement agency, to less than the full extent permitted by federal law. SECTION 4. IC 5-2-18.2-5, AS AMENDED BY P.L.76-2024, SECTION 1, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2026]: Sec. 5. (a) If the attorney general determines that probable cause exists that a governmental body or a postsecondary educational institution has violated this chapter, the attorney general shall bring an action to compel the governmental body or postsecondary educational institution to comply with this chapter. (b) If the attorney general determines that probable cause exists that a governmental body has not complied with section 9 of this chapter, the attorney general may bring an action to: (1) enjoin an act or a practice constituting a violation; and (2) impose a civil penalty of ten thousand dollars ($10,000) for each violation. (c) The attorney general shall transfer all penalties collected under this chapter to the treasurer of state for deposit in the state general fund. (d) If in an action taken under subsection (b), a governmental body is found to have violated section 9 of this chapter, the governor may, upon the advice of the attorney general, withhold any grants or state funding to the governmental body for a period not to exceed one (1) year. SECTION 5. IC 5-2-18.2-6, AS AMENDED BY P.L.76-2024, SECTION 2, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE UPON PASSAGE]: Sec. 6. (a) If a court finds by a preponderance of the evidence that a governmental body or postsecondary educational 2026 IN 76—LS 6446/DI 151 4 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 institution knowingly or intentionally violated this chapter, the court shall enjoin the violation. (b) This section expires June 30, 2026. SECTION 6. IC 5-2-18.2-6.1 IS ADDED TO THE INDIANA CODE AS A NEW SECTION TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2026]: Sec. 6.1. (a) If a court finds by a preponderance of the evidence that a governmental body or postsecondary educational institution violated section 3 or 4 of this chapter, the court shall enjoin the violation. (b) If a court finds by a preponderance of the evidence that a governmental body or a postsecondary educational institution violated section 9 of this chapter, the court shall: (1) enjoin the violation; and (2) grant the relief for a violation provided by section 5(b) of this chapter. SECTION 7. IC 5-2-18.2-9 IS ADDED TO THE INDIANA CODE AS A NEW SECTION TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2026]: Sec. 9. (a) Except as provided in subsection (b), a governmental body that has custody of an individual who is the subject of an immigration detainer request shall: (1) provide to the judge authorized to grant or deny the individual's release on bail under IC 35-33-8-3.2 notice that the individual is subject to an immigration detainer request; (2) record in the individual's case file that the individual is subject to an immigration detainer request; (3) comply with all requests made in the immigration detainer request; and (4) inform the individual that the individual is being held pursuant to an immigration detainer request issued by an authorized immigration officer. (b) If an individual who is the subject of an immigration detainer request presents to the governmental body a United States passport or a birth certificate issued in the United States, the governmental body shall contact the authorized immigration officer to determine whether the individual is a citizen of the United States. SECTION 8. IC 5-2-18.2-10 IS ADDED TO THE INDIANA CODE AS A NEW SECTION TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2026]: Sec. 10. A judge who receives notice under section 9 of this chapter that an individual is subject to an immigration detainer request shall ensure that the notice of the immigration detainer request is recorded in the court's record, regardless of 2026 IN 76—LS 6446/DI 151 5 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 whether the notice was received before or after a judgment in a case. SECTION 9. IC 12-8-1.5-21 IS ADDED TO THE INDIANA CODE AS A NEW SECTION TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2026]: Sec. 21. (a) The office of the secretary shall submit a report to the legislative council, in an electronic format under IC 5-14-6, that provides: (1) except as provided in subsection (b), data regarding the number of individuals in Indiana who: (A) are not citizens of the United States; and (B) are enrolled in or receiving benefits under: (i) IC 12-10-6; (ii) IC 12-13; (iii) IC 12-14; (iv) IC 12-15; and (v) IC 12-19; and (2) the immigration status of each individual described in subdivision (1). (b) The data described in subsection (a) does not include individually identifiable health information as defined in 42 U.S.C. 1320d(6). SECTION 10. IC 22-5-9 IS ADDED TO THE INDIANA CODE AS A NEW CHAPTER TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2026]: Chapter 9. Employment of Unauthorized Aliens Sec. 1. As used in this chapter, "agency" means any state or local administration, agency, authority, board, bureau, commission, committee, council, department, division, institution, office, service, or other similar body of government created or established by law that issues any form of operating authorization that is used to engage in commerce in Indiana or in a county, city, town, or township located in Indiana. Sec. 2. As used in this chapter, "employ" means to engage the services or labor of an individual for wages or other remuneration, including to suffer or permit to work. Sec. 3. As used in this chapter, "employee" means an individual who is employed by an employer, including an individual who is suffered or permitted to work. Sec. 4. As used in this chapter, "employer" means a person, including an agent, that employs at least ten (10) employees in Indiana. Sec. 5. As used in this chapter, "law enforcement agency" has 2026 IN 76—LS 6446/DI 151 6 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 the meaning set forth in IC 5-2-17-2. Sec. 6. As used in this chapter, "unauthorized alien" has the meaning set forth in 8 U.S.C. 1324a(h)(3). Sec. 7. (a) This subsection does not apply to the hiring or employment of an unauthorized alien that occurred before July 1, 2026. Except as provided in subsection (c), it is unlawful for an employer to recklessly or intentionally hire or employ an unauthorized alien in Indiana. (b) For purposes of this chapter, "reasonable diligence to confirm the work eligibility of an individual" includes utilizing an electronic verification of work authorization program operated by the United States Department of Homeland Security to verify the work eligibility of an employee, except where the circumstances under which the verification was made would have put a reasonable person on notice that the verification was unreliable or of limited reliability. (c) An employer is not in violation of subsection (a) if the employer engaged in reasonable diligence to confirm the work eligibility of an individual before hiring or employing the individual. Sec. 8. If: (1) an agency; (2) the attorney general; or (3) a law enforcement agency; determines that probable cause exists that an employer has violated section 7 of this chapter, the agency, attorney general, or law enforcement agency shall provide notice to the United States Department of Homeland Security. Sec. 9. (a) An employer may not discharge an employee or in any way discriminate against any employee because the employee communicated or cooperated with the United States Department of Homeland Security concerning the employer's or another employer's compliance with section 7 of this chapter. (b) Any employee who believes that the employee has been discharged or otherwise discriminated against by any person in violation of this section may, within thirty (30) calendar days after the violation occurs, file a complaint with the commissioner of labor alleging the discrimination. The complaint shall be received and acted upon as provided in IC 22-8-1.1-38.1. Sec. 10. This chapter shall be enforced without regard to race, color, or national origin. SECTION 11. IC 32-30-7-7 IS AMENDED TO READ AS 2026 IN 76—LS 6446/DI 151 7 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 FOLLOWS [EFFECTIVE JULY 1, 2026]: Sec. 7. (a) If an indecent nuisance exists, a prosecuting official or any resident of the county in which the indecent nuisance exists may bring an action to abate the indecent nuisance and to perpetually enjoin the maintenance of the indecent nuisance. (b) If a person other than a prosecuting official institutes an action under this chapter, the complainant shall execute a bond to the person against whom complaint is made, with good and sufficient surety to be approved by the court or clerk in a sum of at least one thousand dollars ($1,000) to secure to the party enjoined the damages the party may sustain if: (1) the action is wrongfully brought; (2) the action is not prosecuted to final judgment; (3) the action is dismissed; (4) the action is not maintained; or (5) it is finally decided that the injunction ought not to have been granted. The party aggrieved by the issuance of the injunction has recourse against the bond for all damages suffered, including damages to the aggrieved party's property, person, or character and including reasonable attorney's fees incurred in defending the action. (c) A person who institutes an action and executes a bond may recover the bond and reasonable attorney's fees incurred in trying the action if the existence of an indecent nuisance is admitted or established in an action as provided in this chapter. (d) If a prosecuting official institutes an action under this chapter (or IC 34-1-52.5 or IC 34-19-2 before their repeal) and the existence of an indecent nuisance is admitted or established in the action, the governmental entity that employs the prosecuting official is entitled to all investigative costs, court costs, and reasonable attorney's fees incurred by the entity in instituting the action. The fees shall be deposited in: (1) the state general fund, if the action is instituted by the attorney general; (2) the operating budget of the office of the prosecuting attorney, if the action is instituted by a prosecuting attorney; (3) the operating budget of the office of the corporation counsel or city attorney, if the action is instituted by a corporation counsel or city attorney; or (4) the county general fund, if the action is instituted by an attorney representing the county. SECTION 12. IC 36-2-13-9, AS AMENDED BY P.L.127-2017, 2026 IN 76—LS 6446/DI 151 8 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 SECTION 91, IS AMENDED TO READ AS FOLLOWS [EFFECTIVE JULY 1, 2026]: Sec. 9. (a) After election and before assuming the duties of office, the sheriff-elect may attend the sessions of a training school that: (1) offers courses of instruction for sheriffs; (2) is established by Indiana University, Purdue University, Indiana University and Purdue University, the state police department, or the Indiana sheriffs' association; and (3) teaches methods of crime detection and offers courses from the state board of accounts on office routine and accounting. (b) On presentation of proper charges or receipts and with the approval of the county executive, the county auditor may issue the auditor's warrant for the following expenses of the sheriff-elect in attending a school under this section: (1) Any tuition charged by the school. (2) A sum for mileage, lodging, and meals, equal to the sum allowed county officers under IC 5-11-14-1. (c) The department of correction shall provide training to all sheriffs-elect concerning cooperation with the United States Immigration and Customs Enforcement. SECTION 13. An emergency is declared for this act. 2026 IN 76—LS 6446/DI 151