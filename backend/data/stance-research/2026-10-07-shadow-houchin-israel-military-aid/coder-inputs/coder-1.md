You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-houchin-israel-military-aid/labels/coder-1.json. Write JSON only, matching
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

politician_id: 68568faf-1e0f-4ca2-89d9-bda625665712  office_id: b343becb-af7d-4a19-a6a1-2e5df210f344
Erin Houchin — U.S. House of Representatives - Indiana 9th Congressional District, Indiana (seated, level: federal)
Current term: 2023-01-03 (precision: day) to present

## Topics (served ladder text — code against these words only)

### topic_key: israel-military-aid
topic_id: 6783e65c-0722-45d9-8579-65327af7c15c  served_revision_id: a9e300f1-8d13-4e34-89f0-e321031676b2
Question: What level of military aid should the U.S. provide to Israel?
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


## Sources

---
snapshot_id: 15c5a6dd-1130-5475-8bb7-83d5b57e9638
source_kind: public-record
url: https://clerk.house.gov/Votes/2024152

Office of the Clerk, U.S. House of Representatives Find Your Representative Search Office of the Clerk Toggle navigation Search Office of the Clerk Search button Legislative Information Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions 119th Congress, 2nd Session House Not In Session Next Session: October 9th, 2026 at 12:30 PM House Floor Proceedings Watch live.house.gov Additional Resources Votes Legacy View - 2024 119th Congress Nominees Statistics of the 2024 Congressional Election Final House Calendar (118th Congress) Résumé of Congressional Activity Legislative Search Congressional Record U.S. Senate House Schedule Bills This Week House Voting Days Member Information Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Republicans 218 218 Democrats 214 214 Independents 1 1 Vacancies 2 2 Republican Leadership Rep. Mike Johnson Speaker of the House Rep. Steve Scalise Majority Leader Rep. Tom Emmer Majority Whip Rep. Lisa C. McClain Republican Conference Chair Rep. Jay Obernolte Republican Policy Committee Chair Democratic Leadership Rep. Hakeem S. Jeffries Minority Leader Rep. Katherine M. Clark Minority Whip Rep. Pete Aguilar Democratic Caucus Chair Rep. Ted Lieu Democratic Caucus Vice Chair Additional Resources Find Your Representative Official List of Members by State Official Member Telephone Directory Duplicate and Similar Names of Members Terms of Service Mailing Labels [ MS Word | Text File ] Member Data [ Excel | XML | User Guide ] Biographical Directory Members on Congress.gov Committee Information COMMITTEE INFORMATION COMMITTEE PROFILES Agriculture Appropriations Armed Services Budget Education and Workforce Energy and Commerce Ethics Financial Services Foreign Affairs Homeland Security House Administration Judiciary Natural Resources Oversight and Government Reform Rules Science, Space, and Technology Small Business Transportation and Infrastructure Veterans' Affairs Ways and Means Select Intelligence Select Strategic Competition Joint Economic Joint Library Joint Printing Joint Taxation Additional Resources Official List of Members with Committee Assignments Official List of Standing Committees and Subcommittees Committee Repository Committee Reports Committees on Congress.gov Committee Data [ Excel ] Disclosures Disclosures PUBLIC DISCLOSURE Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications Additional Resources Lobbying Disclosures Public Laws Lobbying Disclosure Act About the Clerk About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office The Clerk of the House The Honorable Kevin F. McCumber Clerk of the U.S. House of Representatives Deputy Clerk Michelle H. Reinshuttle Deputy Clerk Contact Information Mailing Address U.S. Capitol Room H154 Washington, DC 20515&ndash;6601 Telephone Number (202) 225&ndash;7000 Office Hours 9:00 AM&ndash;6:00 PM, Monday&ndash;Friday Additional Resources Artificial Intelligence Use Case Inventory [ USHouse-Clerk-1: Comparative Print Suite ] 119th Congress, 2nd Session Back to Previous Page Roll Call 152 | Bill Number: H. R. 8034 Share XML View | HTML View Apr 20, 2024, 01:57 PM | 118th Congress, 2nd Session Vote Question: On Passage Israel Security Supplemental Appropriations Act, 2024 Vote Type: Yea-And-Nay Status: Passed VOTES yea: 366 nay: 58 present: 0 not voting: 7 Remote Voting by Proxy Votes by party votes by party Party Yeas Nays Present Not Voting Republican 193 21 0 4 Democratic 173 37 0 3 Independent 0 0 0 0 Total 366 58 0 7 All votes Keyword Name Party All Parties Republican Democratic Independent State All States Votes All Votes YEA/AYE NAY/NO PRESENT NOT VOTING All votes Representative Party State Vote Adams Adams Democratic North Carolina NC Yea Aderholt Aderholt Republican Alabama AL Yea Aguilar Aguilar Democratic California CA Yea Alford Alford Republican Missouri MO Yea Allen Allen Republican Georgia GA Yea Allred Allred Democratic Texas TX Yea Amo Amo Democratic Rhode Island RI Yea Amodei Amodei Republican Nevada NV Yea Armstrong Armstrong Republican North Dakota ND Yea Arrington Arrington Republican Texas TX Yea Auchincloss Auchincloss Democratic Massachusetts MA Yea Babin Babin Republican Texas TX Yea Bacon Bacon Republican Nebraska NE Yea Baird Baird Republican Indiana IN Yea Balderson Balderson Republican Ohio OH Yea Balint Balint Democratic Vermont VT Nay Banks Banks Republican Indiana IN Yea Barr Barr Republican Kentucky KY Yea Barragán Barragan Democratic California CA Yea Bean (FL) Bean (FL) Republican Florida FL Yea Beatty Beatty Democratic Ohio OH Yea Bentz Bentz Republican Oregon OR Yea Bera Bera Democratic California CA Yea Bergman Bergman Republican Michigan MI Yea Beyer Beyer Democratic Virginia VA Nay Bice Bice Republican Oklahoma OK Yea Biggs Biggs Republican Arizona AZ Nay Bilirakis Bilirakis Republican Florida FL Yea Bishop (GA) Bishop (GA) Democratic Georgia GA Yea Bishop (NC) Bishop (NC) Republican North Carolina NC Yea Blumenauer Blumenauer Democratic Oregon OR Nay Blunt Rochester Blunt Rochester Democratic Delaware DE Yea Boebert Boebert Republican Colorado CO Nay Bonamici Bonamici Democratic Oregon OR Yea Bost Bost Republican Illinois IL Yea Bowman Bowman Democratic New York NY Nay Boyle (PA) Boyle (PA) Democratic Pennsylvania PA Yea Brecheen Brecheen Republican Oklahoma OK Yea Brown Brown Democratic Ohio OH Yea Brownley Brownley Democratic California CA Yea Buchanan Buchanan Republican Florida FL Yea Bucshon Bucshon Republican Indiana IN Yea Budzinski Budzinski Democratic Illinois IL Yea Burchett Burchett Republican Tennessee TN Nay Burgess Burgess Republican Texas TX Yea Burlison Burlison Republican Missouri MO Yea Bush Bush Democratic Missouri MO Nay Calvert Calvert Republican California CA Yea Cammack Cammack Republican Florida FL Yea Caraveo Caraveo Democratic Colorado CO Yea Carbajal Carbajal Democratic California CA Yea Cárdenas Cardenas Democratic California CA Yea Carey Carey Republican Ohio OH Yea Carl Carl Republican Alabama AL Yea Carson Carson Democratic Indiana IN Nay Carter (GA) Carter (GA) Republican Georgia GA Yea Carter (LA) Carter (LA) Democratic Louisiana LA Yea Carter (TX) Carter (TX) Republican Texas TX Yea Cartwright Cartwright Democratic Pennsylvania PA Yea Casar Casar Democratic Texas TX Nay Case Case Democratic Hawaii HI Yea Casten Casten Democratic Illinois IL Yea Castor (FL) Castor (FL) Democratic Florida FL Yea Castro (TX) Castro (TX) Democratic Texas TX Nay Chavez-DeRemer Chavez-DeRemer Republican Oregon OR Yea Cherfilus-McCormick Cherfilus-McCormick Democratic Florida FL Yea Chu Chu Democratic California CA Nay Ciscomani Ciscomani Republican Arizona AZ Yea Clark (MA) Clark (MA) Democratic Massachusetts MA Yea Clarke (NY) Clarke (NY) Democratic New York NY Yea Cleaver Cleaver Democratic Missouri MO Yea Cline Cline Republican Virginia VA Yea Cloud Cloud Republican Texas TX Yea Clyburn Clyburn Democratic South Carolina SC Yea Clyde Clyde Republican Georgia GA Nay Cohen Cohen Democratic Tennessee TN Yea Cole Cole Republican Oklahoma OK Yea Collins Collins Republican Georgia GA Yea Comer Comer Republican Kentucky KY Yea Connolly Connolly Democratic Virginia VA Yea Correa Correa Democratic California CA Yea Costa Costa Democratic California CA Yea Courtney Courtney Democratic Connecticut CT Yea Craig Craig Democratic Minnesota MN Yea Crane Crane Republican Arizona AZ Nay Crawford Crawford Republican Arkansas AR Yea Crenshaw Crenshaw Republican Texas TX Yea Crockett Crockett Democratic Texas TX Yea Crow Crow Democratic Colorado CO Yea Cuellar Cuellar Democratic Texas TX Yea Curtis Curtis Republican Utah UT Yea D'Esposito D'Esposito Republican New York NY Yea Davids (KS) Davids (KS) Democratic Kansas KS Yea Davidson Davidson Republican Ohio OH Nay Davis (IL) Davis (IL) Democratic Illinois IL Yea Davis (NC) Davis (NC) Democratic North Carolina NC Yea De La Cruz De La Cruz Republican Texas TX Yea Dean (PA) Dean (PA) Democratic Pennsylvania PA Yea DeGette DeGette Democratic Colorado CO Yea DeLauro DeLauro Democratic Connecticut CT Yea DelBene DelBene Democratic Washington WA Yea Deluzio Deluzio Democratic Pennsylvania PA Yea DeSaulnier DeSaulnier Democratic California CA Nay DesJarlais DesJarlais Republican Tennessee TN Nay Diaz-Balart Diaz-Balart Republican Florida FL Yea Dingell Dingell Democratic Michigan MI Not Voting Doggett Doggett Democratic Texas TX Nay Donalds Donalds Republican Florida FL Yea Duarte Duarte Republican California CA Yea Duncan Duncan Republican South Carolina SC Yea Dunn (FL) Dunn (FL) Republican Florida FL Yea Edwards Edwards Republican North Carolina NC Yea Ellzey Ellzey Republican Texas TX Yea Emmer Emmer Republican Minnesota MN Yea Escobar Escobar Democratic Texas TX Yea Eshoo Eshoo Democratic California CA Yea Espaillat Espaillat Democratic New York NY Yea Estes Estes Republican Kansas KS Yea Evans Evans Democratic Pennsylvania PA Yea Ezell Ezell Republican Mississippi MS Yea Fallon Fallon Republican Texas TX Yea Feenstra Feenstra Republican Iowa IA Yea Ferguson Ferguson Republican Georgia GA Yea Finstad Finstad Republican Minnesota MN Yea Fischbach Fischbach Republican Minnesota MN Yea Fitzgerald Fitzgerald Republican Wisconsin WI Yea Fitzpatrick Fitzpatrick Republican Pennsylvania PA Yea Fleischmann Fleischmann Republican Tennessee TN Yea Fletcher Fletcher Democratic Texas TX Yea Flood Flood Republican Nebraska NE Yea Foster Foster Democratic Illinois IL Yea Foushee Foushee Democratic North Carolina NC Yea Foxx Foxx Republican North Carolina NC Yea Frankel, Lois Frankel, Lois Democratic Florida FL Yea Franklin, Scott Franklin, Scott Republican Florida FL Yea Frost Frost Democratic Florida FL Nay Fry Fry Republican South Carolina SC Yea Fulcher Fulcher Republican Idaho ID Yea Gaetz Gaetz Republican Florida FL Nay Gallagher Gallagher Republican Wisconsin WI Yea Gallego Gallego Democratic Arizona AZ Yea Garamendi Garamendi Democratic California CA Nay Garbarino Garbarino Republican New York NY Yea García (IL) Garcia (IL) Democratic Illinois IL Nay Garcia (TX) Garcia (TX) Democratic Texas TX Yea Garcia, Mike Garcia, Mike Republican California CA Yea Garcia, Robert Garcia, Robert Democratic California CA Yea Gimenez Gimenez Republican Florida FL Yea Golden (ME) Golden (ME) Democratic Maine ME Yea Goldman (NY) Goldman (NY) Democratic New York NY Yea Gomez Gomez Democratic California CA Yea Gonzales, Tony Gonzales, Tony Republican Texas TX Yea Gonzalez, Vicente Gonzalez, Vicente Democratic Texas TX Yea Good (VA) Good (VA) Republican Virginia VA Nay Gooden (TX) Gooden (TX) Republican Texas TX Yea Gosar Gosar Republican Arizona AZ Nay Gottheimer Gottheimer Democratic New Jersey NJ Yea Granger Granger Republican Texas TX Yea Graves (LA) Graves (LA) Republican Louisiana LA Yea Graves (MO) Graves (MO) Republican Missouri MO Yea Green (TN) Green (TN) Republican Tennessee TN Yea Green, Al (TX) Green, Al (TX) Democratic Texas TX Nay Greene (GA) Greene (GA) Republican Georgia GA Nay Griffith Griffith Republican Virginia VA Yea Grijalva Grijalva Democratic Arizona AZ Not Voting Grothman Grothman Republican Wisconsin WI Yea Guest Guest Republican Mississippi MS Yea Guthrie Guthrie Republican Kentucky KY Yea Hageman Hageman Republican Wyoming WY Yea Harder (CA) Harder (CA) Democratic California CA Yea Harris Harris Republican Maryland MD Nay Harshbarger Harshbarger Republican Tennessee TN Yea Hayes Hayes Democratic Connecticut CT Yea Hern Hern Republican Oklahoma OK Yea Higgins (LA) Higgins (LA) Republican Louisiana LA Yea Hill Hill Republican Arkansas AR Yea Himes Himes Democratic Connecticut CT Yea Hinson Hinson Republican Iowa IA Yea Horsford Horsford Democratic Nevada NV Yea Houchin Houchin Republican Indiana IN Yea Houlahan Houlahan Democratic Pennsylvania PA Yea Hoyer Hoyer Democratic Maryland MD Yea Hoyle (OR) Hoyle (OR) Democratic Oregon OR Yea Hudson Hudson Republican North Carolina NC Yea Huffman Huffman Democratic California CA Yea Huizenga Huizenga Republican Michigan MI Yea Hunt Hunt Republican Texas TX Not Voting Issa Issa Republican California CA Yea Ivey Ivey Democratic Maryland MD Yea Jackson (IL) Jackson (IL) Democratic Illinois IL Nay Jackson (NC) Jackson (NC) Democratic North Carolina NC Yea Jackson (TX) Jackson (TX) Republican Texas TX Yea Jackson Lee Jackson Lee Democratic Texas TX Yea Jacobs Jacobs Democratic California CA Yea James James Republican Michigan MI Yea Jayapal Jayapal Democratic Washington WA Nay Jeffries Jeffries Democratic New York NY Yea Johnson (GA) Johnson (GA) Democratic Georgia GA Nay Johnson (LA) Johnson (LA) Republican Louisiana LA Yea Johnson (SD) Johnson (SD) Republican South Dakota SD Yea Jordan Jordan Republican Ohio OH Yea Joyce (OH) Joyce (OH) Republican Ohio OH Yea Joyce (PA) Joyce (PA) Republican Pennsylvania PA Yea Kamlager-Dove Kamlager-Dove Democratic California CA Yea Kaptur Kaptur Democratic Ohio OH Yea Kean (NJ) Kean (NJ) Republican New Jersey NJ Yea Keating Keating Democratic Massachusetts MA Yea Kelly (IL) Kelly (IL) Democratic Illinois IL Yea Kelly (MS) Kelly (MS) Republican Mississippi MS Yea Kelly (PA) Kelly (PA) Republican Pennsylvania PA Yea Khanna Khanna Democratic California CA Nay Kiggans (VA) Kiggans (VA) Republican Virginia VA Yea Kildee Kildee Democratic Michigan MI Nay Kiley Kiley Republican California CA Yea Kilmer Kilmer Democratic Washington WA Yea Kim (CA) Kim (CA) Republican California CA Yea Kim (NJ) Kim (NJ) Democratic New Jersey NJ Yea Krishnamoorthi Krishnamoorthi Democratic Illinois IL Yea Kuster Kuster Democratic New Hampshire NH Yea Kustoff Kustoff Republican Tennessee TN Yea LaHood LaHood Republican Illinois IL Yea LaLota LaLota Republican New York NY Yea LaMalfa LaMalfa Republican California CA Yea Lamborn Lamborn Republican Colorado CO Yea Landsman Landsman Democratic Ohio OH Yea Langworthy Langworthy Republican New York NY Yea Larsen (WA) Larsen (WA) Democratic Washington WA Yea Larson (CT) Larson (CT) Democratic Connecticut CT Yea Latta Latta Republican Ohio OH Yea LaTurner LaTurner Republican Kansas KS Yea Lawler Lawler Republican New York NY Yea Lee (CA) Lee (CA) Democratic California CA Nay Lee (FL) Lee (FL) Republican Florida FL Yea Lee (NV) Lee (NV) Democratic Nevada NV Yea Lee (PA) Lee (PA) Democratic Pennsylvania PA Nay Leger Fernandez Leger Fernandez Democratic New Mexico NM Yea Lesko Lesko Republican Arizona AZ Yea Letlow Letlow Republican Louisiana LA Yea Levin Levin Democratic California CA Yea Lieu Lieu Democratic California CA Yea Lofgren Lofgren Democratic California CA Yea Loudermilk Loudermilk Republican Georgia GA Yea Lucas Lucas Republican Oklahoma OK Yea Luetkemeyer Luetkemeyer Republican Missouri MO Not Voting Luna Luna Republican Florida FL Yea Luttrell Luttrell Republican Texas TX Yea Lynch Lynch Democratic Massachusetts MA Yea Mace Mace Republican South Carolina SC Yea Magaziner Magaziner Democratic Rhode Island RI Yea Malliotakis Malliotakis Republican New York NY Yea Maloy Maloy Republican Utah UT Yea Mann Mann Republican Kansas KS Yea Manning Manning Democratic North Carolina NC Yea Massie Massie Republican Kentucky KY Nay Mast Mast Republican Florida FL Yea Matsui Matsui Democratic California CA Yea McBath McBath Democratic Georgia GA Yea McCaul McCaul Republican Texas TX Yea McClain McClain Republican Michigan MI Yea McClellan McClellan Democratic Virginia VA Yea McClintock McClintock Republican California CA Yea McCollum McCollum Democratic Minnesota MN Yea McCormick McCormick Republican Georgia GA Yea McGarvey McGarvey Democratic Kentucky KY Yea McGovern McGovern Democratic Massachusetts MA Nay McHenry McHenry Republican North Carolina NC Yea Meeks Meeks Democratic New York NY Yea Menendez Menendez Democratic New Jersey NJ Yea Meng Meng Democratic New York NY Yea Meuser Meuser Republican Pennsylvania PA Yea Mfume Mfume Democratic Maryland MD Yea Miller (IL) Miller (IL) Republican Illinois IL Yea Miller (OH) Miller (OH) Republican Ohio OH Yea Miller (WV) Miller (WV) Republican West Virginia WV Yea Miller-Meeks Miller-Meeks Republican Iowa IA Yea Mills Mills Republican Florida FL Nay Molinaro Molinaro Republican New York NY Yea Moolenaar Moolenaar Republican Michigan MI Yea Mooney Mooney Republican West Virginia WV Not Voting Moore (AL) Moore (AL) Republican Alabama AL Yea Moore (UT) Moore (UT) Republican Utah UT Yea Moore (WI) Moore (WI) Democratic Wisconsin WI Yea Moran Moran Republican Texas TX Yea Morelle Morelle Democratic New York NY Yea Moskowitz Moskowitz Democratic Florida FL Yea Moulton Moulton Democratic Massachusetts MA Yea Mrvan Mrvan Democratic Indiana IN Yea Mullin Mullin Democratic California CA Yea Murphy Murphy Republican North Carolina NC Yea Nadler Nadler Democratic New York NY Yea Napolitano Napolitano Democratic California CA Yea Neal Neal Democratic Massachusetts MA Yea Neguse Neguse Democratic Colorado CO Yea Nehls Nehls Republican Texas TX Nay Newhouse Newhouse Republican Washington WA Yea Nickel Nickel Democratic North Carolina NC Yea Norcross Norcross Democratic New Jersey NJ Yea Norman Norman Republican South Carolina SC Nay Nunn (IA) Nunn (IA) Republican Iowa IA Yea Obernolte Obernolte Republican California CA Yea Ocasio-Cortez Ocasio-Cortez Democratic New York NY Nay Ogles Ogles Republican Tennessee TN Yea Omar Omar Democratic Minnesota MN Nay Owens Owens Republican Utah UT Yea Pallone Pallone Democratic New Jersey NJ Yea Palmer Palmer Republican Alabama AL Yea Panetta Panetta Democratic California CA Yea Pappas Pappas Democratic New Hampshire NH Yea Pascrell Pascrell Democratic New Jersey NJ Yea Payne Payne Democratic New Jersey NJ Not Voting Pelosi Pelosi Democratic California CA Yea Peltola Peltola Democratic Alaska AK Yea Pence Pence Republican Indiana IN Yea Perez Perez Democratic Washington WA Yea Perry Perry Republican Pennsylvania PA Nay Peters Peters Democratic California CA Yea Pettersen Pettersen Democratic Colorado CO Yea Pfluger Pfluger Republican Texas TX Yea Phillips Phillips Democratic Minnesota MN Yea Pingree Pingree Democratic Maine ME Nay Pocan Pocan Democratic Wisconsin WI Nay Porter Porter Democratic California CA Yea Posey Posey Republican Florida FL Yea Pressley Pressley Democratic Massachusetts MA Nay Quigley Quigley Democratic Illinois IL Yea Ramirez Ramirez Democratic Illinois IL Nay Raskin Raskin Democratic Maryland MD Nay Reschenthaler Reschenthaler Republican Pennsylvania PA Yea Rodgers (WA) Rodgers (WA) Republican Washington WA Yea Rogers (AL) Rogers (AL) Republican Alabama AL Yea Rogers (KY) Rogers (KY) Republican Kentucky KY Yea Rose Rose Republican Tennessee TN Yea Rosendale Rosendale Republican Montana MT Nay Ross Ross Democratic North Carolina NC Yea Rouzer Rouzer Republican North Carolina NC Yea Roy Roy Republican Texas TX Nay Ruiz Ruiz Democratic California CA Yea Ruppersberger Ruppersberger Democratic Maryland MD Yea Rutherford Rutherford Republican Florida FL Yea Ryan Ryan Democratic New York NY Yea Salazar Salazar Republican Florida FL Yea Salinas Salinas Democratic Oregon OR Yea Sánchez Sanchez Democratic California CA Yea Sarbanes Sarbanes Democratic Maryland MD Yea Scalise Scalise Republican Louisiana LA Yea Scanlon Scanlon Democratic Pennsylvania PA Yea Schakowsky Schakowsky Democratic Illinois IL Yea Schiff Schiff Democratic California CA Yea Schneider Schneider Democratic Illinois IL Yea Scholten Scholten Democratic Michigan MI Yea Schrier Schrier Democratic Washington WA Yea Schweikert Schweikert Republican Arizona AZ Yea Scott (VA) Scott (VA) Democratic Virginia VA Yea Scott, Austin Scott, Austin Republican Georgia GA Yea Scott, David Scott, David Democratic Georgia GA Yea Self Self Republican Texas TX Yea Sessions Sessions Republican Texas TX Yea Sewell Sewell Democratic Alabama AL Yea Sherman Sherman Democratic California CA Yea Sherrill Sherrill Democratic New Jersey NJ Yea Simpson Simpson Republican Idaho ID Yea Slotkin Slotkin Democratic Michigan MI Yea Smith (MO) Smith (MO) Republican Missouri MO Yea Smith (NE) Smith (NE) Republican Nebraska NE Yea Smith (NJ) Smith (NJ) Republican New Jersey NJ Yea Smith (WA) Smith (WA) Democratic Washington WA Yea Smucker Smucker Republican Pennsylvania PA Yea Sorensen Sorensen Democratic Illinois IL Yea Soto Soto Democratic Florida FL Yea Spanberger Spanberger Democratic Virginia VA Yea Spartz Spartz Republican Indiana IN Yea Stansbury Stansbury Democratic New Mexico NM Yea Stanton Stanton Democratic Arizona AZ Yea Stauber Stauber Republican Minnesota MN Yea Steel Steel Republican California CA Yea Stefanik Stefanik Republican New York NY Yea Steil Steil Republican Wisconsin WI Yea Steube Steube Republican Florida FL Yea Stevens Stevens Democratic Michigan MI Yea Strickland Strickland Democratic Washington WA Yea Strong Strong Republican Alabama AL Yea Suozzi Suozzi Democratic New York NY Yea Swalwell Swalwell Democratic California CA Yea Sykes Sykes Democratic Ohio OH Yea Takano Takano Democratic California CA Nay Tenney Tenney Republican New York NY Yea Thanedar Thanedar Democratic Michigan MI Yea Thompson (CA) Thompson (CA) Democratic California CA Yea Thompson (MS) Thompson (MS) Democratic Mississippi MS Nay Thompson (PA) Thompson (PA) Republican Pennsylvania PA Yea Tiffany Tiffany Republican Wisconsin WI Nay Timmons Timmons Republican South Carolina SC Yea Titus Titus Democratic Nevada NV Yea Tlaib Tlaib Democratic Michigan MI Nay Tokuda Tokuda Democratic Hawaii HI Nay Tonko Tonko Democratic New York NY Yea Torres (CA) Torres (CA) Democratic California CA Yea Torres (NY) Torres (NY) Democratic New York NY Yea Trahan Trahan Democratic Massachusetts MA Yea Trone Trone Democratic Maryland MD Yea Turner Turner Republican Ohio OH Yea Underwood Underwood Democratic Illinois IL Yea Valadao Valadao Republican California CA Yea Van Drew Van Drew Republican New Jersey NJ Yea Van Duyne Van Duyne Republican Texas TX Yea Van Orden Van Orden Republican Wisconsin WI Yea Vargas Vargas Democratic California CA Yea Vasquez Vasquez Democratic New Mexico NM Yea Veasey Veasey Democratic Texas TX Yea Velázquez Velazquez Democratic New York NY Nay Wagner Wagner Republican Missouri MO Yea Walberg Walberg Republican Michigan MI Yea Waltz Waltz Republican Florida FL Yea Wasserman Schultz Wasserman Schultz Democratic Florida FL Yea Waters Waters Democratic California CA Nay Watson Coleman Watson Coleman Democratic New Jersey NJ Nay Weber (TX) Weber (TX) Republican Texas TX Yea Webster (FL) Webster (FL) Republican Florida FL Yea Wenstrup Wenstrup Republican Ohio OH Yea Westerman Westerman Republican Arkansas AR Yea Wexton Wexton Democratic Virginia VA Yea Wild Wild Democratic Pennsylvania PA Yea Williams (GA) Williams (GA) Democratic Georgia GA Yea Williams (NY) Williams (NY) Republican New York NY Not Voting Williams (TX) Williams (TX) Republican Texas TX Yea Wilson (FL) Wilson (FL) Democratic Florida FL Yea Wilson (SC) Wilson (SC) Republican South Carolina SC Yea Wittman Wittman Republican Virginia VA Yea Womack Womack Republican Arkansas AR Yea Yakym Yakym Republican Indiana IN Yea Zinke Zinke Republican Montana MT Nay No data found 118 Contact Information Room H154, The Capitol Washington, DC 20515-6601 p: (202) 225-7000 For general inquiries: info.clerkweb@mail.house.gov For general technical support: techsupport.clerkweb@mail.house.gov Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Disclosures Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office Committee Information Committee Profiles Clerk Sites Bills This Week Biographical Directory Clerk Kids Committee Repository History, Art & Archives Office of the Chaplain Help & Resources FAQs Privacy Policy Site Map

---
snapshot_id: 22238768-2817-5798-8d0c-42b37c2c2770
source_kind: public-record
url: https://clerk.house.gov/Votes/2024217

Office of the Clerk, U.S. House of Representatives Find Your Representative Search Office of the Clerk Toggle navigation Search Office of the Clerk Search button Legislative Information Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions 119th Congress, 2nd Session House Not In Session Next Session: October 9th, 2026 at 12:30 PM House Floor Proceedings Watch live.house.gov Additional Resources Votes Legacy View - 2024 119th Congress Nominees Statistics of the 2024 Congressional Election Final House Calendar (118th Congress) Résumé of Congressional Activity Legislative Search Congressional Record U.S. Senate House Schedule Bills This Week House Voting Days Member Information Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Republicans 218 218 Democrats 214 214 Independents 1 1 Vacancies 2 2 Republican Leadership Rep. Mike Johnson Speaker of the House Rep. Steve Scalise Majority Leader Rep. Tom Emmer Majority Whip Rep. Lisa C. McClain Republican Conference Chair Rep. Jay Obernolte Republican Policy Committee Chair Democratic Leadership Rep. Hakeem S. Jeffries Minority Leader Rep. Katherine M. Clark Minority Whip Rep. Pete Aguilar Democratic Caucus Chair Rep. Ted Lieu Democratic Caucus Vice Chair Additional Resources Find Your Representative Official List of Members by State Official Member Telephone Directory Duplicate and Similar Names of Members Terms of Service Mailing Labels [ MS Word | Text File ] Member Data [ Excel | XML | User Guide ] Biographical Directory Members on Congress.gov Committee Information COMMITTEE INFORMATION COMMITTEE PROFILES Agriculture Appropriations Armed Services Budget Education and Workforce Energy and Commerce Ethics Financial Services Foreign Affairs Homeland Security House Administration Judiciary Natural Resources Oversight and Government Reform Rules Science, Space, and Technology Small Business Transportation and Infrastructure Veterans' Affairs Ways and Means Select Intelligence Select Strategic Competition Joint Economic Joint Library Joint Printing Joint Taxation Additional Resources Official List of Members with Committee Assignments Official List of Standing Committees and Subcommittees Committee Repository Committee Reports Committees on Congress.gov Committee Data [ Excel ] Disclosures Disclosures PUBLIC DISCLOSURE Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications Additional Resources Lobbying Disclosures Public Laws Lobbying Disclosure Act About the Clerk About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office The Clerk of the House The Honorable Kevin F. McCumber Clerk of the U.S. House of Representatives Deputy Clerk Michelle H. Reinshuttle Deputy Clerk Contact Information Mailing Address U.S. Capitol Room H154 Washington, DC 20515&ndash;6601 Telephone Number (202) 225&ndash;7000 Office Hours 9:00 AM&ndash;6:00 PM, Monday&ndash;Friday Additional Resources Artificial Intelligence Use Case Inventory [ USHouse-Clerk-1: Comparative Print Suite ] 119th Congress, 2nd Session Back to Previous Page Roll Call 217 | Bill Number: H. R. 8369 Share XML View | HTML View May 16, 2024, 05:00 PM | 118th Congress, 2nd Session Vote Question: On Passage Israel Security Assistance Support Act Vote Type: Yea-And-Nay Status: Passed VOTES yea: 224 nay: 187 present: 0 not voting: 19 Remote Voting by Proxy Votes by party votes by party Party Yeas Nays Present Not Voting Republican 208 3 0 6 Democratic 16 184 0 13 Independent 0 0 0 0 Total 224 187 0 19 All votes Keyword Name Party All Parties Republican Democratic Independent State All States Votes All Votes YEA/AYE NAY/NO PRESENT NOT VOTING All votes Representative Party State Vote Adams Adams Democratic North Carolina NC Nay Aderholt Aderholt Republican Alabama AL Yea Aguilar Aguilar Democratic California CA Nay Alford Alford Republican Missouri MO Yea Allen Allen Republican Georgia GA Yea Allred Allred Democratic Texas TX Nay Amo Amo Democratic Rhode Island RI Nay Amodei Amodei Republican Nevada NV Yea Armstrong Armstrong Republican North Dakota ND Yea Arrington Arrington Republican Texas TX Yea Auchincloss Auchincloss Democratic Massachusetts MA Nay Babin Babin Republican Texas TX Yea Bacon Bacon Republican Nebraska NE Yea Baird Baird Republican Indiana IN Yea Balderson Balderson Republican Ohio OH Yea Balint Balint Democratic Vermont VT Nay Banks Banks Republican Indiana IN Yea Barr Barr Republican Kentucky KY Yea Barragán Barragan Democratic California CA Nay Bean (FL) Bean (FL) Republican Florida FL Yea Beatty Beatty Democratic Ohio OH Nay Bentz Bentz Republican Oregon OR Yea Bera Bera Democratic California CA Nay Bergman Bergman Republican Michigan MI Yea Beyer Beyer Democratic Virginia VA Nay Bice Bice Republican Oklahoma OK Yea Biggs Biggs Republican Arizona AZ Yea Bilirakis Bilirakis Republican Florida FL Yea Bishop (GA) Bishop (GA) Democratic Georgia GA Nay Bishop (NC) Bishop (NC) Republican North Carolina NC Yea Blumenauer Blumenauer Democratic Oregon OR Nay Blunt Rochester Blunt Rochester Democratic Delaware DE Nay Boebert Boebert Republican Colorado CO Not Voting Bonamici Bonamici Democratic Oregon OR Nay Bost Bost Republican Illinois IL Yea Bowman Bowman Democratic New York NY Nay Boyle (PA) Boyle (PA) Democratic Pennsylvania PA Nay Brecheen Brecheen Republican Oklahoma OK Yea Brown Brown Democratic Ohio OH Nay Brownley Brownley Democratic California CA Nay Buchanan Buchanan Republican Florida FL Yea Bucshon Bucshon Republican Indiana IN Yea Budzinski Budzinski Democratic Illinois IL Nay Burchett Burchett Republican Tennessee TN Yea Burgess Burgess Republican Texas TX Yea Burlison Burlison Republican Missouri MO Yea Bush Bush Democratic Missouri MO Nay Calvert Calvert Republican California CA Yea Cammack Cammack Republican Florida FL Yea Caraveo Caraveo Democratic Colorado CO Nay Carbajal Carbajal Democratic California CA Nay Cárdenas Cardenas Democratic California CA Nay Carey Carey Republican Ohio OH Yea Carl Carl Republican Alabama AL Yea Carson Carson Democratic Indiana IN Not Voting Carter (GA) Carter (GA) Republican Georgia GA Yea Carter (LA) Carter (LA) Democratic Louisiana LA Nay Carter (TX) Carter (TX) Republican Texas TX Yea Cartwright Cartwright Democratic Pennsylvania PA Yea Casar Casar Democratic Texas TX Nay Case Case Democratic Hawaii HI Nay Casten Casten Democratic Illinois IL Nay Castor (FL) Castor (FL) Democratic Florida FL Nay Castro (TX) Castro (TX) Democratic Texas TX Nay Chavez-DeRemer Chavez-DeRemer Republican Oregon OR Yea Cherfilus-McCormick Cherfilus-McCormick Democratic Florida FL Nay Chu Chu Democratic California CA Nay Ciscomani Ciscomani Republican Arizona AZ Yea Clark (MA) Clark (MA) Democratic Massachusetts MA Nay Clarke (NY) Clarke (NY) Democratic New York NY Nay Cleaver Cleaver Democratic Missouri MO Not Voting Cline Cline Republican Virginia VA Yea Cloud Cloud Republican Texas TX Yea Clyburn Clyburn Democratic South Carolina SC Nay Clyde Clyde Republican Georgia GA Yea Cohen Cohen Democratic Tennessee TN Nay Cole Cole Republican Oklahoma OK Yea Collins Collins Republican Georgia GA Yea Comer Comer Republican Kentucky KY Yea Connolly Connolly Democratic Virginia VA Nay Correa Correa Democratic California CA Nay Costa Costa Democratic California CA Nay Courtney Courtney Democratic Connecticut CT Nay Craig Craig Democratic Minnesota MN Yea Crane Crane Republican Arizona AZ Yea Crawford Crawford Republican Arkansas AR Yea Crenshaw Crenshaw Republican Texas TX Yea Crockett Crockett Democratic Texas TX Nay Crow Crow Democratic Colorado CO Nay Cuellar Cuellar Democratic Texas TX Yea Curtis Curtis Republican Utah UT Yea D'Esposito D'Esposito Republican New York NY Yea Davids (KS) Davids (KS) Democratic Kansas KS Nay Davidson Davidson Republican Ohio OH Nay Davis (IL) Davis (IL) Democratic Illinois IL Not Voting Davis (NC) Davis (NC) Democratic North Carolina NC Yea De La Cruz De La Cruz Republican Texas TX Yea Dean (PA) Dean (PA) Democratic Pennsylvania PA Nay DeGette DeGette Democratic Colorado CO Nay DeLauro DeLauro Democratic Connecticut CT Nay DelBene DelBene Democratic Washington WA Nay Deluzio Deluzio Democratic Pennsylvania PA Nay DeSaulnier DeSaulnier Democratic California CA Nay DesJarlais DesJarlais Republican Tennessee TN Yea Diaz-Balart Diaz-Balart Republican Florida FL Yea Dingell Dingell Democratic Michigan MI Nay Doggett Doggett Democratic Texas TX Nay Donalds Donalds Republican Florida FL Yea Duarte Duarte Republican California CA Yea Duncan Duncan Republican South Carolina SC Yea Dunn (FL) Dunn (FL) Republican Florida FL Yea Edwards Edwards Republican North Carolina NC Yea Ellzey Ellzey Republican Texas TX Yea Emmer Emmer Republican Minnesota MN Yea Escobar Escobar Democratic Texas TX Nay Eshoo Eshoo Democratic California CA Nay Espaillat Espaillat Democratic New York NY Nay Estes Estes Republican Kansas KS Yea Evans Evans Democratic Pennsylvania PA Not Voting Ezell Ezell Republican Mississippi MS Yea Fallon Fallon Republican Texas TX Yea Feenstra Feenstra Republican Iowa IA Yea Ferguson Ferguson Republican Georgia GA Not Voting Finstad Finstad Republican Minnesota MN Yea Fischbach Fischbach Republican Minnesota MN Yea Fitzgerald Fitzgerald Republican Wisconsin WI Yea Fitzpatrick Fitzpatrick Republican Pennsylvania PA Yea Fleischmann Fleischmann Republican Tennessee TN Yea Fletcher Fletcher Democratic Texas TX Nay Flood Flood Republican Nebraska NE Yea Foster Foster Democratic Illinois IL Nay Foushee Foushee Democratic North Carolina NC Nay Foxx Foxx Republican North Carolina NC Yea Frankel, Lois Frankel, Lois Democratic Florida FL Yea Franklin, Scott Franklin, Scott Republican Florida FL Yea Frost Frost Democratic Florida FL Nay Fry Fry Republican South Carolina SC Yea Fulcher Fulcher Republican Idaho ID Yea Gaetz Gaetz Republican Florida FL Not Voting Gallego Gallego Democratic Arizona AZ Nay Garamendi Garamendi Democratic California CA Nay Garbarino Garbarino Republican New York NY Yea García (IL) Garcia (IL) Democratic Illinois IL Nay Garcia (TX) Garcia (TX) Democratic Texas TX Nay Garcia, Mike Garcia, Mike Republican California CA Yea Garcia, Robert Garcia, Robert Democratic California CA Nay Gimenez Gimenez Republican Florida FL Not Voting Golden (ME) Golden (ME) Democratic Maine ME Yea Goldman (NY) Goldman (NY) Democratic New York NY Nay Gomez Gomez Democratic California CA Nay Gonzales, Tony Gonzales, Tony Republican Texas TX Yea Gonzalez, Vicente Gonzalez, Vicente Democratic Texas TX Not Voting Good (VA) Good (VA) Republican Virginia VA Yea Gooden (TX) Gooden (TX) Republican Texas TX Yea Gosar Gosar Republican Arizona AZ Yea Gottheimer Gottheimer Democratic New Jersey NJ Yea Granger Granger Republican Texas TX Yea Graves (LA) Graves (LA) Republican Louisiana LA Yea Graves (MO) Graves (MO) Republican Missouri MO Yea Green (TN) Green (TN) Republican Tennessee TN Yea Green, Al (TX) Green, Al (TX) Democratic Texas TX Nay Greene (GA) Greene (GA) Republican Georgia GA Nay Griffith Griffith Republican Virginia VA Yea Grijalva Grijalva Democratic Arizona AZ Not Voting Grothman Grothman Republican Wisconsin WI Yea Guest Guest Republican Mississippi MS Yea Guthrie Guthrie Republican Kentucky KY Yea Hageman Hageman Republican Wyoming WY Yea Harder (CA) Harder (CA) Democratic California CA Nay Harris Harris Republican Maryland MD Yea Harshbarger Harshbarger Republican Tennessee TN Yea Hayes Hayes Democratic Connecticut CT Nay Hern Hern Republican Oklahoma OK Yea Higgins (LA) Higgins (LA) Republican Louisiana LA Yea Hill Hill Republican Arkansas AR Yea Himes Himes Democratic Connecticut CT Nay Hinson Hinson Republican Iowa IA Yea Horsford Horsford Democratic Nevada NV Nay Houchin Houchin Republican Indiana IN Yea Houlahan Houlahan Democratic Pennsylvania PA Nay Hoyer Hoyer Democratic Maryland MD Nay Hoyle (OR) Hoyle (OR) Democratic Oregon OR Nay Hudson Hudson Republican North Carolina NC Yea Huffman Huffman Democratic California CA Nay Huizenga Huizenga Republican Michigan MI Yea Hunt Hunt Republican Texas TX Yea Issa Issa Republican California CA Yea Ivey Ivey Democratic Maryland MD Nay Jackson (IL) Jackson (IL) Democratic Illinois IL Nay Jackson (NC) Jackson (NC) Democratic North Carolina NC Nay Jackson (TX) Jackson (TX) Republican Texas TX Yea Jackson Lee Jackson Lee Democratic Texas TX Not Voting Jacobs Jacobs Democratic California CA Nay James James Republican Michigan MI Yea Jayapal Jayapal Democratic Washington WA Nay Jeffries Jeffries Democratic New York NY Nay Johnson (GA) Johnson (GA) Democratic Georgia GA Nay Johnson (LA) Johnson (LA) Republican Louisiana LA Yea Johnson (SD) Johnson (SD) Republican South Dakota SD Yea Jordan Jordan Republican Ohio OH Yea Joyce (OH) Joyce (OH) Republican Ohio OH Yea Joyce (PA) Joyce (PA) Republican Pennsylvania PA Yea Kamlager-Dove Kamlager-Dove Democratic California CA Nay Kaptur Kaptur Democratic Ohio OH Nay Kean (NJ) Kean (NJ) Republican New Jersey NJ Yea Keating Keating Democratic Massachusetts MA Nay Kelly (IL) Kelly (IL) Democratic Illinois IL Nay Kelly (MS) Kelly (MS) Republican Mississippi MS Yea Kelly (PA) Kelly (PA) Republican Pennsylvania PA Yea Kennedy Kennedy Democratic New York NY Nay Khanna Khanna Democratic California CA Not Voting Kiggans (VA) Kiggans (VA) Republican Virginia VA Yea Kildee Kildee Democratic Michigan MI Nay Kiley Kiley Republican California CA Yea Kilmer Kilmer Democratic Washington WA Nay Kim (CA) Kim (CA) Republican California CA Yea Kim (NJ) Kim (NJ) Democratic New Jersey NJ Nay Krishnamoorthi Krishnamoorthi Democratic Illinois IL Nay Kuster Kuster Democratic New Hampshire NH Nay Kustoff Kustoff Republican Tennessee TN Yea LaHood LaHood Republican Illinois IL Yea LaLota LaLota Republican New York NY Yea LaMalfa LaMalfa Republican California CA Yea Lamborn Lamborn Republican Colorado CO Yea Landsman Landsman Democratic Ohio OH Yea Langworthy Langworthy Republican New York NY Yea Larsen (WA) Larsen (WA) Democratic Washington WA Nay Larson (CT) Larson (CT) Democratic Connecticut CT Nay Latta Latta Republican Ohio OH Yea LaTurner LaTurner Republican Kansas KS Yea Lawler Lawler Republican New York NY Yea Lee (CA) Lee (CA) Democratic California CA Nay Lee (FL) Lee (FL) Republican Florida FL Yea Lee (NV) Lee (NV) Democratic Nevada NV Nay Lee (PA) Lee (PA) Democratic Pennsylvania PA Nay Leger Fernandez Leger Fernandez Democratic New Mexico NM Nay Lesko Lesko Republican Arizona AZ Yea Letlow Letlow Republican Louisiana LA Yea Levin Levin Democratic California CA Nay Lieu Lieu Democratic California CA Nay Lofgren Lofgren Democratic California CA Nay Loudermilk Loudermilk Republican Georgia GA Yea Lucas Lucas Republican Oklahoma OK Yea Luetkemeyer Luetkemeyer Republican Missouri MO Yea Luna Luna Republican Florida FL Not Voting Luttrell Luttrell Republican Texas TX Yea Lynch Lynch Democratic Massachusetts MA Nay Mace Mace Republican South Carolina SC Yea Magaziner Magaziner Democratic Rhode Island RI Not Voting Malliotakis Malliotakis Republican New York NY Yea Maloy Maloy Republican Utah UT Yea Mann Mann Republican Kansas KS Yea Manning Manning Democratic North Carolina NC Nay Massie Massie Republican Kentucky KY Nay Mast Mast Republican Florida FL Yea Matsui Matsui Democratic California CA Nay McBath McBath Democratic Georgia GA Nay McCaul McCaul Republican Texas TX Yea McClain McClain Republican Michigan MI Not Voting McClellan McClellan Democratic Virginia VA Nay McClintock McClintock Republican California CA Yea McCollum McCollum Democratic Minnesota MN Nay McCormick McCormick Republican Georgia GA Yea McGarvey McGarvey Democratic Kentucky KY Nay McGovern McGovern Democratic Massachusetts MA Nay McHenry McHenry Republican North Carolina NC Yea Meeks Meeks Democratic New York NY Nay Menendez Menendez Democratic New Jersey NJ Nay Meng Meng Democratic New York NY Nay Meuser Meuser Republican Pennsylvania PA Yea Mfume Mfume Democratic Maryland MD Nay Miller (IL) Miller (IL) Republican Illinois IL Yea Miller (OH) Miller (OH) Republican Ohio OH Yea Miller (WV) Miller (WV) Republican West Virginia WV Yea Miller-Meeks Miller-Meeks Republican Iowa IA Yea Mills Mills Republican Florida FL Yea Molinaro Molinaro Republican New York NY Yea Moolenaar Moolenaar Republican Michigan MI Yea Mooney Mooney Republican West Virginia WV Yea Moore (AL) Moore (AL) Republican Alabama AL Yea Moore (UT) Moore (UT) Republican Utah UT Yea Moore (WI) Moore (WI) Democratic Wisconsin WI Nay Moran Moran Republican Texas TX Yea Morelle Morelle Democratic New York NY Nay Moskowitz Moskowitz Democratic Florida FL Yea Moulton Moulton Democratic Massachusetts MA Nay Mrvan Mrvan Democratic Indiana IN Nay Mullin Mullin Democratic California CA Nay Murphy Murphy Republican North Carolina NC Yea Nadler Nadler Democratic New York NY Nay Napolitano Napolitano Democratic California CA Nay Neal Neal Democratic Massachusetts MA Nay Neguse Neguse Democratic Colorado CO Nay Nehls Nehls Republican Texas TX Yea Newhouse Newhouse Republican Washington WA Yea Nickel Nickel Democratic North Carolina NC Nay Norcross Norcross Democratic New Jersey NJ Not Voting Norman Norman Republican South Carolina SC Yea Nunn (IA) Nunn (IA) Republican Iowa IA Yea Obernolte Obernolte Republican California CA Yea Ocasio-Cortez Ocasio-Cortez Democratic New York NY Nay Ogles Ogles Republican Tennessee TN Yea Omar Omar Democratic Minnesota MN Nay Owens Owens Republican Utah UT Yea Pallone Pallone Democratic New Jersey NJ Yea Palmer Palmer Republican Alabama AL Yea Panetta Panetta Democratic California CA Nay Pappas Pappas Democratic New Hampshire NH Nay Pascrell Pascrell Democratic New Jersey NJ Nay Pelosi Pelosi Democratic California CA Nay Peltola Peltola Democratic Alaska AK Yea Pence Pence Republican Indiana IN Yea Perez Perez Democratic Washington WA Yea Perry Perry Republican Pennsylvania PA Yea Peters Peters Democratic California CA Nay Pettersen Pettersen Democratic Colorado CO Nay Pfluger Pfluger Republican Texas TX Yea Phillips Phillips Democratic Minnesota MN Nay Pingree Pingree Democratic Maine ME Nay Pocan Pocan Democratic Wisconsin WI Nay Porter Porter Democratic California CA Nay Posey Posey Republican Florida FL Yea Pressley Pressley Democratic Massachusetts MA Nay Quigley Quigley Democratic Illinois IL Nay Ramirez Ramirez Democratic Illinois IL Nay Raskin Raskin Democratic Maryland MD Nay Reschenthaler Reschenthaler Republican Pennsylvania PA Yea Rodgers (WA) Rodgers (WA) Republican Washington WA Yea Rogers (AL) Rogers (AL) Republican Alabama AL Yea Rogers (KY) Rogers (KY) Republican Kentucky KY Yea Rose Rose Republican Tennessee TN Yea Rosendale Rosendale Republican Montana MT Yea Ross Ross Democratic North Carolina NC Nay Rouzer Rouzer Republican North Carolina NC Yea Roy Roy Republican Texas TX Yea Ruiz Ruiz Democratic California CA Nay Ruppersberger Ruppersberger Democratic Maryland MD Nay Rutherford Rutherford Republican Florida FL Yea Ryan Ryan Democratic New York NY Nay Salazar Salazar Republican Florida FL Yea Salinas Salinas Democratic Oregon OR Nay Sánchez Sanchez Democratic California CA Nay Sarbanes Sarbanes Democratic Maryland MD Nay Scalise Scalise Republican Louisiana LA Yea Scanlon Scanlon Democratic Pennsylvania PA Nay Schakowsky Schakowsky Democratic Illinois IL Nay Schiff Schiff Democratic California CA Nay Schneider Schneider Democratic Illinois IL Nay Scholten Scholten Democratic Michigan MI Nay Schrier Schrier Democratic Washington WA Nay Schweikert Schweikert Republican Arizona AZ Yea Scott (VA) Scott (VA) Democratic Virginia VA Nay Scott, Austin Scott, Austin Republican Georgia GA Yea Scott, David Scott, David Democratic Georgia GA Yea Self Self Republican Texas TX Yea Sessions Sessions Republican Texas TX Yea Sewell Sewell Democratic Alabama AL Nay Sherman Sherman Democratic California CA Nay Sherrill Sherrill Democratic New Jersey NJ Nay Simpson Simpson Republican Idaho ID Yea Slotkin Slotkin Democratic Michigan MI Nay Smith (MO) Smith (MO) Republican Missouri MO Yea Smith (NE) Smith (NE) Republican Nebraska NE Yea Smith (NJ) Smith (NJ) Republican New Jersey NJ Yea Smith (WA) Smith (WA) Democratic Washington WA Nay Smucker Smucker Republican Pennsylvania PA Yea Sorensen Sorensen Democratic Illinois IL Nay Soto Soto Democratic Florida FL Yea Spanberger Spanberger Democratic Virginia VA Nay Spartz Spartz Republican Indiana IN Yea Stansbury Stansbury Democratic New Mexico NM Nay Stanton Stanton Democratic Arizona AZ Nay Stauber Stauber Republican Minnesota MN Yea Steel Steel Republican California CA Yea Stefanik Stefanik Republican New York NY Yea Steil Steil Republican Wisconsin WI Yea Steube Steube Republican Florida FL Yea Stevens Stevens Democratic Michigan MI Nay Strickland Strickland Democratic Washington WA Nay Strong Strong Republican Alabama AL Yea Suozzi Suozzi Democratic New York NY Yea Swalwell Swalwell Democratic California CA Nay Sykes Sykes Democratic Ohio OH Nay Takano Takano Democratic California CA Nay Tenney Tenney Republican New York NY Yea Thanedar Thanedar Democratic Michigan MI Nay Thompson (CA) Thompson (CA) Democratic California CA Nay Thompson (MS) Thompson (MS) Democratic Mississippi MS Nay Thompson (PA) Thompson (PA) Republican Pennsylvania PA Yea Tiffany Tiffany Republican Wisconsin WI Yea Timmons Timmons Republican South Carolina SC Yea Titus Titus Democratic Nevada NV Nay Tlaib Tlaib Democratic Michigan MI Nay Tokuda Tokuda Democratic Hawaii HI Nay Tonko Tonko Democratic New York NY Nay Torres (CA) Torres (CA) Democratic California CA Nay Torres (NY) Torres (NY) Democratic New York NY Yea Trahan Trahan Democratic Massachusetts MA Nay Trone Trone Democratic Maryland MD Not Voting Turner Turner Republican Ohio OH Yea Underwood Underwood Democratic Illinois IL Nay Valadao Valadao Republican California CA Yea Van Drew Van Drew Republican New Jersey NJ Yea Van Duyne Van Duyne Republican Texas TX Yea Van Orden Van Orden Republican Wisconsin WI Yea Vargas Vargas Democratic California CA Nay Vasquez Vasquez Democratic New Mexico NM Nay Veasey Veasey Democratic Texas TX Nay Velázquez Velazquez Democratic New York NY Nay Wagner Wagner Republican Missouri MO Yea Walberg Walberg Republican Michigan MI Yea Waltz Waltz Republican Florida FL Yea Wasserman Schultz Wasserman Schultz Democratic Florida FL Nay Waters Waters Democratic California CA Nay Watson Coleman Watson Coleman Democratic New Jersey NJ Nay Weber (TX) Weber (TX) Republican Texas TX Yea Webster (FL) Webster (FL) Republican Florida FL Yea Wenstrup Wenstrup Republican Ohio OH Yea Westerman Westerman Republican Arkansas AR Yea Wexton Wexton Democratic Virginia VA Not Voting Wild Wild Democratic Pennsylvania PA Nay Williams (GA) Williams (GA) Democratic Georgia GA Nay Williams (NY) Williams (NY) Republican New York NY Yea Williams (TX) Williams (TX) Republican Texas TX Yea Wilson (FL) Wilson (FL) Democratic Florida FL Not Voting Wilson (SC) Wilson (SC) Republican South Carolina SC Yea Wittman Wittman Republican Virginia VA Yea Womack Womack Republican Arkansas AR Yea Yakym Yakym Republican Indiana IN Yea Zinke Zinke Republican Montana MT Yea No data found 118 Contact Information Room H154, The Capitol Washington, DC 20515-6601 p: (202) 225-7000 For general inquiries: info.clerkweb@mail.house.gov For general technical support: techsupport.clerkweb@mail.house.gov Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Disclosures Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office Committee Information Committee Profiles Clerk Sites Bills This Week Biographical Directory Clerk Kids Committee Repository History, Art & Archives Office of the Chaplain Help & Resources FAQs Privacy Policy Site Map

---
snapshot_id: 07a3692a-e6c4-5f6f-b4b2-a176e901b9b1
source_kind: public-record
url: https://www.congress.gov/bill/118th-congress/house-bill/8369

Israel Security Assistance Support Act Policy area: International Affairs Sponsor: Rep. Calvert, Ken [R-CA-41] Latest action: Read the second time. Placed on Senate Legislative Calendar under General Orders. Calendar No. 398. Israel Security Assistance Support Act This bill specifies that no federal funds may be used to withhold, halt, reverse, or cancel the delivery of defense articles or defense services to Israel. Also, no funds may be used to pay the salary of any Department of Defense (DOD) or Department of State employee who acts to limit defense deliveries to Israel. Additionally, DOD and the State Department shall ensure prompt delivery of all defense articles and services expected to be delivered to Israel in FY2024 and FY2025. Unobligated funds for operation and maintenance for the Office of the Secretary of Defense, diplomatic programs for the Office of the Secretary of State, and the National Security Council may not be spent until each office certifies to Congress that any withheld defense articles or services are delivered to Israel. DOD and the State Department must obligate any remaining funds for assistance to Israel. DOD and the State Department must periodically report to Congress on defense articles and services provided to Israel. Cosponsors: Rep. Cole, Tom [R-OK-4], Rep. Diaz-Balart, Mario [R-FL-26], Rep. Joyce, David P. [R-OH-14], Rep. McCaul, Michael T. [R-TX-10], Rep. Houchin, Erin [R-IN-9], Rep. Yakym, Rudy [R-IN-2], Rep. McClintock, Tom [R-CA-5], Rep. Tenney, Claudia [R-NY-24], Rep. Weber, Randy K. [R-TX-14], Rep. Aderholt, Robert B. [R-AL-4], Rep. Lawler, Michael [R-NY-17], Rep. Moolenaar, John R. [R-MI-2], Rep. Ellzey, Jake [R-TX-6], Rep. Fleischmann, Charles J. "Chuck" [R-TN-3], Rep. Reschenthaler, Guy [R-PA-14], Rep. Miller, Carol D. [R-WV-1], Rep. Miller-Meeks, Mariannette [R-IA-1], Rep. Kiggans, Jennifer A. [R-VA-2], Rep. Wittman, Robert J. [R-VA-1], Rep. Zinke, Ryan K. [R-MT-1], Rep. Valadao, David G. [R-CA-22], Rep. Carter, John R. [R-TX-31], Rep. Womack, Steve [R-AR-3], Rep. Pfluger, August [R-TX-11], Rep. Lamborn, Doug [R-CO-5], Rep. Armstrong, Kelly [R-ND-At Large], Rep. Fitzpatrick, Brian K. [R-PA-1], Rep. Owens, Burgess [R-UT-4], Rep. Gonzales, Tony [R-TX-23], Rep. Van Drew, Jefferson [R-NJ-2], Rep. Wagner, Ann [R-MO-2], Rep. Burchett, Tim [R-TN-2], Rep. Hinson, Ashley [R-IA-2], Rep. Langworthy, Nicholas A. [R-NY-23], Rep. Buchanan, Vern [R-FL-16], Rep. Fulcher, Russ [R-ID-1], Rep. Stefanik, Elise M. [R-NY-21], Rep. Hageman, Harriet M. [R-WY-At Large], Rep. Barr, Andy [R-KY-6], Rep. Guest, Michael [R-MS-3], Rep. Graves, Sam [R-MO-6], Rep. Garcia, Mike [R-CA-27], Rep. Kean, Thomas H. [R-NJ-7], Rep. Foxx, Virginia [R-NC-5], Rep. Bilirakis, Gus M. [R-FL-12], Rep. Garbarino, Andrew R. [R-NY-2], Rep. Moran, Nathaniel [R-TX-1], Rep. Gimenez, Carlos A. [R-FL-28], Rep. Rose, John W. [R-TN-6], Rep. LaLota, Nick [R-NY-1], Rep. Kelly, Trent [R-MS-1], Rep. Sessions, Pete [R-TX-17], Rep. Mann, Tracey [R-KS-1], Rep. Simpson, Michael K. [R-ID-2], Rep. Newhouse, Dan [R-WA-4], Rep. Smith, Christopher H. [R-NJ-4], Rep. Bergman, Jack [R-MI-1], Rep. LaMalfa, Doug [R-CA-1], Rep. Carter, Earl L. "Buddy" [R-GA-1], Rep. Dunn, Neal P. [R-FL-2], Rep. Granger, Kay [R-TX-12], Rep. Bice, Stephanie I. [R-OK-5], Rep. Stauber, Pete [R-MN-8], Rep. Mast, Brian J. [R-FL-21], Rep. Hunt, Wesley [R-TX-38], Rep. Lucas, Frank D. [R-OK-3], Rep. Meuser, Daniel [R-PA-9], Rep. Bost, Mike [R-IL-12], Rep. Williams, Brandon [R-NY-22], Rep. Guthrie, Brett [R-KY-2], Rep. McHenry, Patrick T. [R-NC-10], Rep. Letlow, Julia [R-LA-5], Rep. Scott, Austin [R-GA-8], Rep. Bacon, Don [R-NE-2], Rep. Graves, Garret [R-LA-6], Rep. Kustoff, David [R-TN-8], Rep. Fry, Russell [R-SC-7], Rep. James, John [R-MI-10], Rep. Smith, Adrian [R-NE-3], Rep. Gooden, Lance [R-TX-5], Rep. LaTurner, Jake [R-KS-2], Rep. Grothman, Glenn [R-WI-6], Rep. Burgess, Michael C. [R-TX-26], Rep. Jackson, Ronny [R-TX-13], Rep. Hill, J. French [R-AR-2], Rep. Waltz, Michael [R-FL-6], Rep. Johnson, Dusty [R-SD-At Large], Rep. Amodei, Mark E. [R-NV-2], Rep. Ciscomani, Juan [R-AZ-6], Rep. Williams, Roger [R-TX-25], Rep. Van Duyne, Beth [R-TX-24], Rep. Rogers, Harold [R-KY-5], Rep. Edwards, Chuck [R-NC-11], Rep. Kelly, Mike [R-PA-16], Rep. Allen, Rick W. [R-GA-12], Rep. Joyce, John [R-PA-13], Rep. Rouzer, David [R-NC-7], Rep. Balderson, Troy [R-OH-12], Rep. Babin, Brian [R-TX-36], Rep. Nunn, Zachary [R-IA-3], Rep. Green, Mark E. [R-TN-7], Rep. Scalise, Steve [R-LA-1], Rep. Mills, Cory [R-FL-7], Rep. Duarte, John S. [R-CA-13], Rep. Finstad, Brad [R-MN-1], Rep. Walberg, Tim [R-MI-5], Rep. Kiley, Kevin [R-CA-3], Rep. Smith, Jason [R-MO-8], Rep. Chavez-DeRemer, Lori [R-OR-5], Rep. Feenstra, Randy [R-IA-4], Rep. Latta, Robert E. [R-OH-5], Rep. Steube, W. Gregory [R-FL-17], Rep. Rutherford, John H. [R-FL-5], Rep. D'Esposito, Anthony [R-NY-4], Rep. Franklin, Scott [R-FL-18], Rep. Banks, Jim [R-IN-3], Rep. Malliotakis, Nicole [R-NY-11], Rep. Loudermilk, Barry [R-GA-11], Rescom. González-Colón, Jenniffer [R-PR-At Large] Actions: Read the second time. Placed on Senate Legislative Calendar under General Orders. Calendar No. 398. Received in the Senate. Read the first time. Placed on Senate Legislative Calendar under Read the First Time. Motion to reconsider laid on the table Agreed to without objection. On passage Passed by the Yeas and Nays: 224 - 187 (Roll no. 217). (text: CR H3287-3288) Passed/agreed to in House: On passage Passed by the Yeas and Nays: 224 - 187 (Roll no. 217). (text: CR H3287-3288) On motion to recommit Failed by the Yeas and Nays: 202 - 210 (Roll no. 216). Considered as unfinished business. (consideration: CR H3310-3311) POSTPONED PROCEEDINGS - At the conclusion of debate on H.R. 8369, the Chair put the question on the motion to recommit and by voice vote announced that the noes had prevailed. Mr. Meeks demanded the yeas and nays and the Chair postponed further proceedings until a time to be announced. The previous question on the motion to recommit was ordered pursuant to clause 2(b) of rule XIX. Mr. Meeks moved to recommit to the Committee on Foreign Affairs. (text: CR H3294) The previous question was ordered pursuant to the rule. DEBATE - The House proceeded with one hour of debate on H.R. 8369. Rule provides for consideration of H.R. 8369, H.R. 7530, H.R. 7343, H.R. 8146, H.R. 7581, H.R. 354, H. Res. 1213 and H. Res. 1210. Rule provides for consideration of H.R. 8369, H.R. 7530, H.R. 7581, H.R. 354, H. Res. 1213, and H. Res. 1210 under a closed rule with one hour of general debate each. Rule provides for consideration of H.R. 7343 and H.R. 8146 under a structured rule with one hour of general debate each. Rule provides for one motion to recommit each on H.R. 8369, H.R. 7530, H.R. 7343, H.R. 7581, H.R. 354, and H.R. 8146. Considered under the provisions of rule H. Res. 1227. (consideration: CR H3287-3294) Rules Committee Resolution H. Res. 1227 Reported to House. Rule provides for consideration of H.R. 8369, H.R. 7530, H.R. 7343, H.R. 8146, H.R. 7581, H.R. 354, H. Res. 1213 and H. Res. 1210. Rule provides for consideration of H.R. 8369, H.R. 7530, H.R. 7581, H.R. 354, H. Res. 1213, and H. Res. 1210 under a closed rule with one hour of general debate each. Rule provides for consideration of H.R. 7343 and H.R. 8146 under a structured rule with one hour of general debate each. Rule provides for one motion to recommit each on H.R. 8369, H.R. 7530, H.R. 7343, H.R. 7581, H.R. 354, and H.R. 8146. [Congressional Bills 118th Congress] [From the U.S. Government Publishing Office] [H.R. 8369 Placed on Calendar Senate (PCS)] <DOC> Calendar No. 398 118th CONGRESS 2d Session H. R. 8369 _______________________________________________________________________ IN THE SENATE OF THE UNITED STATES May 20, 2024 Received; read the first time May 21, 2024 Read the second time and placed on the calendar _______________________________________________________________________ AN ACT To provide for the expeditious delivery of defense articles and defense services for Israel and other matters. Be it enacted by the Senate and House of Representatives of the United States of America in Congress assembled, SECTION 1. SHORT TITLE. This Act may be cited as the ``Israel Security Assistance Support Act''. SEC. 2. FINDINGS. Congress finds the following: (1) On October 7, 2023, Hamas terrorists launched a massive, unprovoked war on Israel, killing over 1,200 innocent people and taking over 240 hostages, including American citizens. (2) Since October 7, Israel has faced attacks by Iran and its proxies including Hezbollah, Hamas, and the Houthis, which have required significant military responses. (3) Under the terms of a 2016 Memorandum of Understanding, the United States provides Israel with $3.8 billion per year in security assistance and missile defense funding from fiscal years 2019 through 2028, which is subject to the approval of Congress. (4) Thus far in fiscal year 2024, Congress has enacted regular and supplemental legislation appropriating $12.5 billion in security assistance and missile defense for Israel without any additional conditions. (5) Congress plays a vital role in oversight and approval of direct commercial sales and foreign military sales to security partners around the world, including Israel. (6) In May 2024, it was reported that President Biden ordered a pause on certain defense articles ready for imminent delivery to Israel, without having consulted with Congress. (7) On May 8, 2024, President Biden stated regarding Israel, ``We're not going to supply the weapons and artillery shells''. SEC. 3. SENSE OF CONGRESS. Congress-- (1) condemns the Biden Administration's decision to pause certain arms transfers to Israel as Israel faces unprecedented threats from Iran and its proxies, including Hezbollah, Hamas, and the Houthis; (2) calls on the Biden Administration to allow all previously approved arms transfers to Israel to proceed quickly to ensure that Israel can defend itself and defeat threats from Iran and its proxies, including Hezbollah, Hamas, and the Houthis; (3) calls on the Biden Administration to utilize all congressionally appropriated funds for security assistance for Israel as Congress intended; (4) stands with Israel as it defends itself against the barbaric war launched by Hamas and other terrorists; and (5) reaffirms Israel's right to self-defense. SEC. 4. PROHIBITION. None of the funds appropriated or otherwise made available under any Act appropriating funds for the Department of Defense or the Department of State for fiscal year 2024 or any prior years may be made available-- (1) to withhold, halt, reverse, or cancel the delivery of defense articles or defense services from the United States to Israel; or (2) to pay the salary or expenses of any officer or employee of the Department of Defense or the Department of State who takes any action to support or further the withholding, halting, reversal, or cancellation of the delivery of such defense articles or services. SEC. 5. PROMPT DELIVERY. (a) Prompt Delivery of Defense Articles and Services.--The Secretary of Defense, in coordination with the Secretary of State, shall ensure prompt delivery of all defense articles and services for Israel which are expected to be delivered in fiscal years 2024 and 2025, including-- (1) those contracted through the Foreign Military Sales system; (2) those supported by prior Acts making appropriations for the Department of Defense; and (3) those provided pursuant to a declaration in section 506(a) of the Foreign Assistance Act of 1961. (b) Prompt Delivery of Direct Commercial Sales.--The Secretary of State shall ensure prompt approval and delivery of all direct commercial sales of defense articles and services for Israel which are expected to be delivered in fiscal years 2024 and 2025, including those for the Ministry of Public Security. (c) Prompt Delivery of Withheld Items.--Any defense article and defense service described in subsection (a) or (b) of this section that were withheld from delivery as of the date of the enactment of this Act shall be delivered to Israel not later than 15 days after the date of the enactment of this Act. SEC. 6. WITHHOLDING OF FUNDS. (a) Withholding of Department of Defense Funds.--None of the unobligated balances of funds made available by prior Acts making appropriations for the Department of Defense under the heading ``Operation and Maintenance, Defense-Wide'' for the immediate Office of the Secretary of Defense that are available as of the date of the enactment of this Act may be obligated or expended until the Secretary of Defense certifies and reports to the Committee on Appropriations of the House of Representatives and the Senate that the requirements of section 5(c) have been met. (b) Withholding of Department of State Funds.--None of the unobligated balances of funds made available by prior Acts making appropriations for the Department of State, Foreign Operations, and Related Programs under the heading ``Diplomatic Programs'' for the Office of the Secretary that are available as of the date of the enactment of this Act may be obligated or expended until the Secretary of State certifies and reports to the Committee on Appropriations of the House of Representatives and the Senate that the requirements of section 5(c) have been met. (c) Withholding of Financial Services and General Government Funds.--None of the unobligated balances of funds made available by prior Acts making appropriations for Financial Services and General Government under the heading ``Executive Office of the President and Funds Appropriated To the President--National Security Council and Homeland Security Council'' that are available as of the date of the enactment of this Act may be obligated or expended until the President certifies and reports to the Committee on Appropriations of the House of Representatives and the Senate that the requirements of section 5(c) have been met. SEC. 7. OBLIGATION REQUIREMENT. Notwithstanding any other provision of law, the Secretary of Defense and the Secretary of State shall obligate any remaining unobligated balances of funds appropriated or otherwise made available for assistance for Israel not later than 30 days after the date of the enactment of this Act. SEC. 8. REPORTS. (a) Inspector General Report.--Not later than 90 days after the date of the enactment of this Act, the Inspectors General of the Department of Defense and the Department of State shall jointly submit to Congress a report on any actions taken by executive branch officials before the date of the enactment of this Act to withhold, halt, reverse, or cancel the delivery of defense articles and defense services to Israel. (b) Monthly Security Assistance Report.--Not later than 30 days after the date of enactment of this Act, and every 30 days thereafter through fiscal year 2025, the Secretary of Defense, in coordination with the Secretary of State, shall provide a written report to the Committees on Appropriations, Armed Services, and Foreign Affairs of the House of Representatives and the Committees on Appropriations, Armed Services, and Foreign Relations of the Senate describing United States security assistance provided to Israel since October 7, 2023, including a comprehensive list of the defense articles and services provided to Israel and the associated authority and funding used to provide such articles and services: Provided, That such report shall be submitted in unclassified form, but may be accompanied by a classified annex. (c) Report on Priority Defense Articles and Services.--Not later than 30 days after the date of enactment of this Act, the Secretary of Defense, in coordination with the Secretary of State, shall provide a written report to the Committees on Appropriations, Armed Services, and Foreign Affairs of the House of Representatives and the Committees on Appropriations, Armed Services, and Foreign Relations of the Senate describing urgent and high priority defense articles and defense services for Israel and steps taken or planned to expedite the delivery of such articles and services. Passed the House of Representatives May 16, 2024. Attest: KEVIN F. MCCUMBER, Clerk. Calendar No. 398 118th CONGRESS 2d Session H. R. 8369 _______________________________________________________________________ AN ACT To provide for the expeditious delivery of defense articles and defense services for Israel and other matters. _______________________________________________________________________ May 21, 2024 Read the second time and placed on the calendar

---
snapshot_id: 505e986a-1cce-5388-8443-28cd7fdc4ade
source_kind: own-site (the person's own site or account)
url: https://www.erinhouchin.com/issues

Erin Houchin on the Issues &mdash; Erin Houchin for Congress 0 Skip to Content ABOUT ISSUES VOLUNTEER CONTACT DONATE Open Menu Close Menu ABOUT ISSUES VOLUNTEER CONTACT DONATE Open Menu Close Menu ABOUT ISSUES VOLUNTEER CONTACT DONATE ERIN ON THE ISSUES SECURE THE BORDER: Joe Biden let over 10 million individuals illegally invade our country—that we know of. These illegals outnumber the population of Indiana by three million people. Erin visited the border in Texas twice, and witnessed the chaos and destruction firsthand. She fully supports President Trump’s efforts to restore border security—by backing law enforcement, finishing the wall, and deporting criminal illegal aliens to protect American communities. STAND WITH ISRAEL: Erin stands firmly with Israel, our nation’s strongest ally in the Middle East. Even before Hamas’ barbaric terrorist attack on October 7, 2023, she has vocally supported Israel’s right to defend itself, and the right of Israelis to live. Erin believes that we as a nation have a moral obligation to unequivocally defend Israel. She is committed to standing resolute against anti-Semitism in all forms at home and abroad and advocating for the U.S. to cut all aid to any sponsors of terrorism. CUT GOVERNMENT SPENDING: Erin believes our government takes too much of your money, and spends too much. Just as families across Indiana balance their budgets, she believes the federal government should too. It's no question that our growing national debt is a national security concern. Erin is a committed fiscal conservative and has the track record to prove it, and as a champion for Indiana’s Balanced Budget Amendment, she is bringing that same fiscal discipline to Washington. PROTECT THE UNBORN: Erin is pro-life and always has been. She has been a steadfast leader in the fight for the unborn, consistently advocating for the prohibition of late-term abortions, and resources and care for mothers in need. In Congress, she continues to be a voice for the voiceless. National Right to Life and the Susan B. Anthony List have endorsed her, she has earned an A+ rating from the SBA List, and had a consistent 100% pro-life voting record as a member of the Indiana State Senate. STAND FOR CONSERVATIVE VALUES: The strong conservative values instilled in Erin growing up in Scottsburg have become a foundational part of who she is. A strong defender of the Second Amendment, the Right to Life, and the right to worship freely, Erin will always fight for our conservative freedoms and liberties. She will continue standing steadfast for an America First Agenda that allows us to live safely and freely. PROTECT PARENTAL RIGHTS: Parents should be in the driver's seat of their children's education. The pandemic opened American parents' eyes to the reality of our public school system, and millions of parents didn't like what they saw. As a mother of three, Erin knows that parents are the primary stakeholders in their children's education. That's why she voted to pass the Parents Bill of Rights and will continue to support parents in this ongoing effort for transparency and a seat at the table as we prepare the next generation for success. SUPPORT OUR VETERANS: America is blessed with the greatest fighting force in the world, and Erin deeply appreciates our servicemen and women and their families. She is committed to improving the welfare and quality of life for our veterans and their families, our active-duty military members and their spouses. Erin is committed to ensuring we keep our promises to those who fought to defend our freedoms and never let them down. UPHOLD LAW & ORDER: Hoosiers are fortunate to have some of the most dedicated and talented law enforcement and public safety officials in the country, and it’s our duty to have their backs. These brave men and women should be protected by lawmakers instead of being met with hostility and resentment. Erin will always fight to ensure our officers have the necessary resources to do their jobs effectively and safely, and they have the support and compensation they deserve. Erin will never allow radical left-wing politicians to defund the police. CREATE JOBS: Erin knows the best way to create jobs and grow the economy is to get the government out of the way and let small business owners do what they do best – innovate and create new jobs. Indiana has one of the best economies in the nation, a direct result of our conservative values. As a small business owner, Erin continues the fight to cut bureaucratic red tape and support limited government while working to cut taxes, promote free markets, and control government spending. PROTECT THE SECOND AMENDMENT: Erin is a firm believer that the Second Amendment is one of our most important freedoms, and she understands the importance of protecting our constitutional right to bear arms. The founders saw the crucial importance of giving citizens the right to protect themselves, and we must all protect that right. CONTRIBUTE PAID FOR BY HOUCHIN FOR CONGRESS ABOUT | ISSUES | CONTACT Privacy Policy

---
snapshot_id: 8827fe78-aa0c-538f-8033-5638fa3ad14e
source_kind: public-record
url: https://www.congress.gov/bill/118th-congress/house-bill/8034

Israel Security Supplemental Appropriations Act, 2024 Policy area: Economics and Public Finance Sponsor: Rep. Cole, Tom [R-OK-4] Latest action: Pursuant to the provisions of H. Res. 1160, H.R. 8034 is laid on the table. Israel Security Supplemental Appropriations Act, 2024 This bill provides FY2024 supplemental appropriations for federal departments and agencies to respond to the conflict in Israel. The bill designates the funding as emergency spending, which is exempt from discretionary spending limits. Specifically, the bill provides appropriations to the Department of Defense (DOD), the Federal Emergency Management Agency (FEMA), the Department of State, and the U.S Agency for International Development. The funding is provided for purposes such as supporting current U.S. military operations in the region; replacing defense articles that were provided to Israel; reimbursing DOD for defense services and training provided to Israel; Defense Production Act purchases; procuring Israel's Iron Dome, David's Sling, and Iron Beam defense systems to counter short-range rocket threats; procuring advanced weapons systems, defense articles, and defense services for Israel through the Foreign Military Financing Program; the FEMA Nonprofit Security Grant Program; migration and refugee assistance; international narcotics control and law enforcement; peacekeeping operations; security at U.S. diplomatic facilities; and humanitarian assistance. The bill also includes provisions that (1) expand the authorities of the President to transfer defense articles and services from DOD to foreign countries or international organizations, and (2) prohibit funds from being used for payments to the U.N. Relief and Works Agency. Israel Security Supplemental Appropriations Act, 2024 This bill provides FY2024 supplemental appropriations for federal departments and agencies to respond to the conflict in Israel. The bill designates the funding as emergency spending, which is exempt from discretionary spending limits. Specifically, the bill provides appropriations to the Department of Defense (DOD), the Federal Emergency Management Agency (FEMA), the Department of State, and the U.S Agency for International Development. The funding is provided for purposes such as supporting current U.S. military operations in the region; replacing defense articles that were provided to Israel; reimbursing DOD for defense services and training provided to Israel; Defense Production Act purchases; procuring Israel's Iron Dome, David's Sling, and Iron Beam defense systems to counter short-range rocket threats; procuring advanced weapons systems, defense articles, and defense services for Israel through the Foreign Military Financing Program; the FEMA Nonprofit Security Grant Program; migration and refugee assistance; international narcotics control and law enforcement; peacekeeping operations; security at U.S. diplomatic facilities; and humanitarian assistance. The bill also includes provisions that (1) expand the authorities of the President to transfer defense articles and services from DOD to foreign countries or international organizations, and (2) prohibit funds from being used for payments to the U.N. Relief and Works Agency. Cosponsors: Rep. Calvert, Ken [R-CA-41], Rep. Diaz-Balart, Mario [R-FL-26] Actions: Pursuant to the provisions of H. Res. 1160, H.R. 8034 is laid on the table. Motion to reconsider laid on the table Agreed to without objection. On passage Passed by the Yeas and Nays: 366 - 58 (Roll no. 152). (text: CR H2607-2610) Passed/agreed to in House: On passage Passed by the Yeas and Nays: 366 - 58 (Roll no. 152). (text: CR H2607-2610) Considered as unfinished business. (consideration: CR H2621-2622) POSTPONED PROCEEDINGS - Pursuant to clause 10 of rule 20, the yeas and nays are ordered. Further proceedings are postponed. The previous question was ordered pursuant to the rule. DEBATE - The House proceeded with 30 minutes of debate on H.R. 8034. Rule provides for consideration of H.R. 8034, H.R. 8035, H.R. 8036 and H.R. 8038. The resolution provides for consideration of H.R. 8034 under a closed rule and H.R. 8035, H.R. 8036, and H.R. 8038 under a structured rule. Provides for 30 minutes of general debate and one motion recommit on each bill. Rule also provides that upon disposition of the bills under consideration, the House will be considered to have taken from the Speaker's table H.R. 815 and to have concurred in the Senate amendment with an amendment inserting the texts of all bills as passed by the House, if passed. Considered under the provisions of rule H. Res. 1160. (consideration: CR H2607-2614) Rules Committee Resolution H. Res. 1160 Reported to House. Rule provides for consideration of H.R. 8034, H.R. 8035, H.R. 8036 and H.R. 8038. The resolution provides for consideration of H.R. 8034 under a closed rule and H.R. 8035, H.R. 8036, and H.R. 8038 under a structured rule. Provides for 30 minutes of general debate and one motion recommit on each bill. Rule also provides that upon disposition of the bills under consideration, the House will be considered to have taken from the Speaker's table H.R. 815 and to have concurred in the Senate amendment with an amendment inserting the texts of all bills as passed by the House, if passed. Referred to the Committee on Appropriations, and in addition to the Committee on the Budget, for a period to be subsequently determined by the Speaker, in each case for consideration of such provisions as fall within the jurisdiction of the committee concerned. Referred to the Committee on Appropriations, and in addition to the Committee on the Budget, for a period to be subsequently determined by the Speaker, in each case for consideration of such provisions as fall within the jurisdiction of the committee concerned. Introduced in House Introduced in House [Congressional Bills 118th Congress] [From the U.S. Government Publishing Office] [H.R. 8034 Introduced in House (IH)] <DOC> 118th CONGRESS 2d Session H. R. 8034 Making emergency supplemental appropriations to respond to the situation in Israel and for related expenses for the fiscal year ending September 30, 2024, and for other purposes. _______________________________________________________________________ IN THE HOUSE OF REPRESENTATIVES April 17, 2024 Mr. Cole (for himself, Mr. Calvert, and Mr. Diaz-Balart) introduced the following bill; which was referred to the Committee on Appropriations, and in addition to the Committee on the Budget, for a period to be subsequently determined by the Speaker, in each case for consideration of such provisions as fall within the jurisdiction of the committee concerned _______________________________________________________________________ A BILL Making emergency supplemental appropriations to respond to the situation in Israel and for related expenses for the fiscal year ending September 30, 2024, and for other purposes. Be it enacted by the Senate and House of Representatives of the United States of America in Congress assembled, That the following sums are appropriated, out of any money in the Treasury not otherwise appropriated, for the fiscal year ending September 30, 2024, and for other purposes, namely: TITLE I DEPARTMENT OF DEFENSE OPERATION AND MAINTENANCE Operation and Maintenance, Defense-Wide (including transfers of funds) For an additional amount for ``Operation and Maintenance, Defense- Wide'', $4,400,000,000, to remain available until September 30, 2025, to respond to the situation in Israel: Provided, That the amount provided under this heading in this Act may be may be transferred to accounts under the headings ``Operation and Maintenance'', ``Procurement'', and ``Revolving and Management Funds'' for replacement, through new procurement or repair of existing unserviceable equipment, of defense articles from the stocks of the Department of Defense, and for reimbursement for defense services of the Department of Defense and military education and training, provided to the government of Israel or identified and notified to Congress for provision to the government of Israel or to foreign countries that have provided support to Israel at the request of the United States: Provided further, That funds transferred pursuant to the preceding proviso shall be merged with and available for the same purposes and for the same time period as the appropriations to which the funds are transferred: Provided further, That the Secretary of Defense shall notify the congressional defense committees of the details of such transfers not less than 15 days before any such transfer: Provided further, That upon a determination that all or part of the funds transferred from this appropriation are not necessary for the purposes provided herein, such amounts may be transferred back and merged with this appropriation: Provided further, That any transfer authority provided herein is in addition to any other transfer authority provided by law: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. PROCUREMENT Procurement of Ammunition, Army For an additional amount for ``Procurement of Ammunition, Army'', $801,400,000, to remain available until September 30, 2026, to respond to the situation in Israel: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Procurement, Defense-Wide For an additional amount for ``Procurement, Defense-Wide'', $5,200,000,000, to remain available until September 30, 2026, to respond to the situation in Israel and for related expenses: Provided, That of the total amount provided under this heading in this Act, $4,000,000,000 shall be for the Secretary of Defense to provide to the Government of Israel for the procurement of the Iron Dome and David's Sling defense systems to counter short-range rocket threats: Provided further, That of the total amount provided under this heading in this Act, $1,200,000,000 shall be for the Secretary of Defense to provide to the Government of Israel for the procurement of the Iron Beam defense system to counter short-range rocket threats: Provided further, That funds in the preceding provisos shall be transferred pursuant to an exchange of letters and are in addition to funds provided pursuant to the U.S.-Israel Iron Dome Procurement Agreement, as amended: Provided further, That nothing under this heading in this Act shall be construed to apply to amounts made available in prior appropriations Acts for the procurement of the Iron Dome and David's Sling defense systems or for the procurement of the Iron Beam defense system: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Defense Production Act Purchases For an additional amount for ``Defense Production Act Purchases'', $198,600,000, to remain available until expended, for activities by the Department of Defense pursuant to sections 108, 301, 302, and 303 of the Defense Production Act of 1950 (50 U.S.C. 4518, 4531, 4532, and 4533): Provided, That such amounts shall be obligated and expended by the Secretary of Defense as if delegated the necessary authorities conferred by the Defense Production Act of 1950: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. GENERAL PROVISIONS--THIS TITLE (including transfers of funds) Sec. 101. For an additional amount for the Department of Defense, $2,440,000,000, to remain available until September 30, 2024, for transfer to military personnel accounts, operation and maintenance accounts, procurement accounts, research, development, test and evaluation accounts, and the Defense Working Capital Funds, in addition to amounts otherwise made available for such purpose, only for U.S. operations, force protection, deterrence, and the replacement of combat expenditures in the United States Central Command region: Provided, That none of the funds provided under this section may be obligated or expended until 30 days after the Secretary of Defense provides to the congressional defense committees an execution plan: Provided further, That not less than 15 days prior to any transfer of funds, the Secretary of Defense shall notify the congressional defense committees of the details of any such transfer: Provided further, That upon transfer, the funds shall be merged with and available for the same purposes, and for the same time period, as the appropriation to which transferred: Provided further, That any transfer authority provided herein is in addition to any other transfer authority provided by law: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985 TITLE II DEPARTMENT OF HOMELAND SECURITY PROTECTION, PREPAREDNESS, RESPONSE, AND RECOVERY Federal Emergency Management Agency operations and support For an additional amount for ``Federal Emergency Management Agency--Operations and Support'', $10,000,000, to remain available until September 30, 2027, for necessary expenses related to the administration of nonprofit security grants: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. federal assistance For an additional amount for ``Federal Emergency Management Agency--Federal Assistance'', $390,000,000, of which $160,000,000 shall remain available until September 30, 2025, and $230,000,000 shall remain available until September 30, 2026, for Nonprofit Security Grant Program under section 2009 of the Homeland Security Act of 2002 (6 U.S.C. 609a) for eligible nonprofit organizations to prevent, prepare for, protect against, and respond to acts of terrorism or other threats: Provided, That the Administrator of the Federal Emergency Management Agency shall make programmatic adjustments as necessary to expedite the disbursement of, and provide flexibility in the use of, amounts made available under this heading in this Act: Provided further, That notwithstanding any provision of 6 U.S.C. 609a, and in addition to amounts available under 6 U.S.C. 609a(c)(2), the Administrator of the Federal Emergency Management Agency may permit a State to use up to two percent of a grant awarded under this heading in this Act to provide outreach and technical assistance to eligible nonprofit organizations to assist them with applying for Nonprofit Security Grant Program awards under this heading in this Act: Provided further, That such outreach and technical assistance should prioritize rural and underserved communities and nonprofit organizations that are traditionally underrepresented in the Program: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. TITLE III DEPARTMENT OF STATE AND RELATED AGENCY DEPARTMENT OF STATE Administration of Foreign Affairs diplomatic programs For an additional amount for ``Diplomatic Programs'', $150,000,000, to remain available until September 30, 2025, to respond to the situation in Israel and areas and countries impacted by the situation in Israel: Provided, That of the total amount provided under this heading in this Act, $100,000,000, to remain available until expended, shall be for Worldwide Security Protection, including to respond to the situation in Israel and areas impacted by the situation in Israel: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. office of inspector general For an additional amount for ``Office of Inspector General'', $4,000,000 to remain available until September 30, 2025: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. emergencies in the diplomatic and consular service For an additional amount for ``Emergencies in the Diplomatic and Consular Service'', $50,000,000, to remain available until expended, to meet unforeseen emergencies arising in the Diplomatic and Consular Service, as authorized: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. UNITED STATES AGENCY FOR INTERNATIONAL DEVELOPMENT Funds Appropriated to the President office of inspector general For an additional amount for ``Office of Inspector General'', $3,000,000, to remain available until September 30, 2025: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. BILATERAL ECONOMIC ASSISTANCE Funds Appropriated to the President international disaster assistance For an additional amount for ``International Disaster Assistance'', $5,655,000,000, to remain available until expended, to address humanitarian needs, including the provision of emergency food and shelter, of vulnerable populations and communities: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Department of State migration and refugee assistance For an additional amount for ``Migration and Refugee Assistance'', $3,495,000,000, to remain available until expended, to address humanitarian needs of vulnerable populations and communities: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. INTERNATIONAL SECURITY ASSISTANCE Department of State international narcotics control and law enforcement For an additional amount for ``International Narcotics Control and Law Enforcement'', $75,000,000, to remain available until September 30, 2025, for assistance for the Middle East, following consultation with the appropriate congressional committees, including to enhance law enforcement capabilities, counter terrorism, combat narcotics trafficking, and meet other critical partner requirements: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. peacekeeping operations For an additional amount for ``Peacekeeping Operations'', $10,000,000, to remain available until September 30, 2025, including for a United States contribution to the Multinational Force and Observers mission in the Sinai to enhance force protection capabilities: Provided, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. Funds Appropriated to the President foreign military financing program For an additional amount for ``Foreign Military Financing Program'', $3,500,000,000, to remain available until September 30, 2025, for assistance for Israel and for related expenses: Provided, That to the extent that the Government of Israel requests that funds be used for such purposes, grants made available for Israel under this heading in this Act shall, as agreed by the United States and Israel, be available for advanced weapons systems, of which up to $769,300,000 may be available for the procurement in Israel of defense articles and defense services: Provided further, That the limitation in the preceding proviso may be exceeded, if agreed by the United States and Israel, following consultation with the Committees on Appropriations: Provided further, That any congressional notification requirement applicable to funds made available under this heading in this Act for Israel may be waived if the Secretary of State determines that to do so is in the national security interest of the United States: Provided further, That up to $5,000,000 of funds made available under this heading in this Act, in addition to funds otherwise available for such purposes, may be used by the Department of State for necessary expenses for the general costs of administering military assistance and sales, including management and oversight of such programs and activities: Provided further, That such amount is designated by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985. GENERAL PROVISIONS--THIS TITLE (including transfers of funds) Sec. 301. During fiscal year 2024, up to $250,000,000 of funds deposited in the Consular and Border Security Programs account in any fiscal year that are available for obligation may be transferred to, and merged with, funds appropriated by any Act making appropriations for the Department of State, foreign operations, and related programs under the headings ``Diplomatic Programs'' (including for Worldwide Security Protection) and ``Emergencies in the Diplomatic and Consular Service'' for emergency evacuations or to prevent or respond to security situations and related requirements: Provided, That such transfer authority is in addition to any other transfer authority provided by law, and any such transfers are subject to prior consultation with, and the regular notification procedures of, the Committees on Appropriations. Sec. 302. During fiscal year 2024, section 506(a)(1) of the Foreign Assistance Act of 1961 (22 U.S.C. 2318(a)(1)) shall be applied by substituting ``$7,800,000,000'' for ``$100,000,000''. Sec. 303. During fiscal year 2024, section 506(a)(2)(B) of the Foreign Assistance Act of 1961 (22 U.S.C. 2318(a)(2)(B)) shall be applied by substituting ``$400,000,000'' for ``$200,000,000'' in the matter preceding clause (i), and by substituting ``$150,000,000'' for ``$75,000,000'' in clause (i). Sec. 304. During fiscal year 2024, section 552(c)(2) of the Foreign Assistance Act of 1961 (22 U.S.C. 2348a(c)(2)) shall be applied by substituting ``$50,000,000'' for ``$25,000,000''. Sec. 305. Section 12001 of the Department of Defense Appropriations Act, 2005 (Public Law 108-287) is amended as follows: (1) In paragraph (2) of subsection (a), by striking ``armor'' and all that follows through the end of the paragraph and inserting ``defense articles that are in the inventory of the Department of Defense as of the date of transfer, are intended for use as reserve stocks for Israel, and are located in a stockpile for Israel as of the date of transfer''. (2) In subsection (b), by striking ``at least equal to the fair market value of the items transferred'' and inserting ``in an amount to be determined by the Secretary of Defense''. (3) In subsection (c), by inserting before the comma in the first sentence the following: ``, or as far in advance of such transfer as is practicable as determined by the President on a case-by-case basis during extraordinary circumstances impacting the national security of the United States''. Sec. 306. For fiscal year 2024, section 514(b) of the Foreign Assistance Act of 1961 (22 U.S.C. 2321h(b)) shall not apply to defense articles to be set aside, earmarked, reserved, or intended for use as reserve stocks in stockpiles in the State of Israel. Sec. 307. (a) Funds appropriated by this Act under the headings ``International Disaster Assistance'' and ``Migration and Refugee Assistance'' may be transferred to, and merged with, funds appropriated by this Act under such headings. (b) Funds appropriated by this Act under the headings ``International Narcotics Control and Law Enforcement'', ``Peacekeeping Operations'', and ``Foreign Military Financing Program'' may be transferred to, and merged with, funds appropriated by this Act under such headings. (c) The transfer authorities provided by this section are in addition to any other transfer authority provided by law, and are subject to prior consultation with, and the regular notification procedures of, the Committees on Appropriations. (d) Upon a determination that all or part of the funds transferred pursuant to the authorities provided by this section are not necessary for such purposes, such amounts may be transferred back to such appropriations. Sec. 308. None of the funds appropriated or otherwise made available by this Act and prior Acts making appropriations for the Department of State, foreign operations, and related programs may be made available for a contribution, grant, or other payment to the United Nations Relief and Works Agency, notwithstanding any other provision of law. Sec. 309. (a) Certification.--The Secretary of State shall certify and report to the appropriate congressional committees not later than fifteen days after the date of enactment of this Act, that-- (1) oversight policies, processes, and procedures have been established by the Department of State and the United States Agency for International Development, as appropriate, and are in use to prevent the diversion, misuse, or destruction of assistance, including through international organizations, to Hamas and other terrorist and extremist entities in Gaza; and (2) such policies, processes, and procedures have been developed in coordination with other bilateral and multilateral donors and the Government of Israel, as appropriate. (b) Oversight Policy and Procedures.--The Secretary of State and the USAID Administrator shall submit to the appropriate congressional committees, concurrent with the submission of the certification required in subsection (a), a written description of the oversight policies, processes, and procedures for funds appropriated by this title that are made available for assistance for Gaza, including specific actions to be taken should such assistance be diverted, misused, or destroyed, and the role of Israel in the oversight of such assistance. (c) Requirement to Inform.--The Secretary of State and USAID Administrator shall promptly inform the appropriate congressional committees of each instance in which funds appropriated by this title that are made available for assistance for Gaza have been diverted, misused, or destroyed, to include the type of assistance, a description of the incident and parties involved, and an explanation of the response of the Department of State or USAID, as appropriate. (d) Third Party Monitoring.--Funds appropriated by this title shall be made available for third party monitoring of assistance for Gaza, including end use monitoring, following consultation with the appropriate congressional committees. (e) Offices of Inspectors General.-- (1) Department of State.--Of the funds appropriated by this title under the heading ``Office of Inspector General'' for the Department of State, $4,000,000 shall be made available for the oversight and monitoring of assistance made available for Gaza by this title and in prior Acts making appropriations for the Department of State, foreign operations, and related programs. (2) United States Agency For International Development.--Of the funds appropriated by this title under the heading ``Office of Inspector General'' for USAID, $3,000,000 shall be made available for the oversight and monitoring of assistance made available for Gaza by this title and in prior Acts making appropriations for the Department of State, foreign operations, and related programs. (f) Report.--Not later than 90 days after the initial obligation of funds appropriated by this title that are made available for assistance for Gaza, and every 90 days thereafter until all such funds are expended, the Secretary of State and the USAID Administrator shall jointly submit to the appropriate congressional committees a report detailing the amount and purpose of such assistance provided during each respective quarter, including a description of the specific entity implementing such assistance. (g) Assessment.--Not later than 90 days after the date of enactment of this Act and every 90 days thereafter until September 30, 2025, the Secretary of State, in consultation with the Director of National Intelligence and other heads of elements of the intelligence community that the Secretary considers relevant, shall submit to the appropriate congressional committees a report assessing whether funds appropriated by this title and made available for assistance for the West Bank and Gaza have been diverted by Hamas or other terrorist and extremist entities in the West Bank and Gaza: Provided, That such report shall include details on the amount and how such funds were made available and used by such entities: Provided further, That such report may be submitted in classified form, if necessary. (h) Consultation.--Not later than 30 days after the date of enactment of this Act but prior to the initial obligation of funds made available by this title for humanitarian assistance for Gaza, the Secretary of State and USAID Administrator, as appropriate, shall consult with the Committees on Appropriations on the amount and anticipated uses of such funds. Sec. 310. Prior to the initial obligation of funds made available in this title in this Act, but not later than 15 days after the date of enactment of this Act, the Secretary of State shall submit to the Committees on Appropriations-- (1) spend plans, as defined in section 7034(s)(4) of the Department of State, Foreign Operations, and Related Programs Appropriations Act, 2023 (division K of Public Law 117-328), at the country, account, and program level, for funds appropriated by this Act under the headings ``International Narcotics Control and Law Enforcement'', ``Peacekeeping Operations'' and ``Foreign Military Financing Program'': Provided, That plans submitted pursuant to this paragraph shall include for each program notified--(A) total funding made available for such program, by account and fiscal year; (B) funding that remains unobligated for such program from prior year base or supplemental appropriations; (C) funding that is obligated but unexpended for such program; and (D) funding committed, but not yet notified for such program; and (2) operating plans, as defined in section 7062 of the Department of State, Foreign Operations, and Related Programs Appropriations Act, 2023 (division K of Public Law 117-328), for funds appropriated by this title under the headings ``Diplomatic Programs'' and ``Emergencies in the Diplomatic and Consular Service''. TITLE IV GENERAL PROVISIONS--THIS ACT Sec. 401. Each amount appropriated or made available by this Act is in addition to amounts otherwise appropriated for the fiscal year involved. Sec. 402. No part of any appropriation contained in this Act shall remain available for obligation beyond the current fiscal year unless expressly so provided herein. Sec. 403. Unless otherwise provided for by this Act, the additional amounts appropriated by this Act to appropriations accounts shall be available under the authorities and conditions applicable to such appropriations accounts for fiscal year 2024. Sec. 404. (a) Not later than 45 days after the date of enactment of this Act, the Secretary of State, in consultation with the heads of other relevant Federal agencies, as appropriate, shall brief the appropriate congressional committees, in classified form, if necessary, on the status and welfare of hostages being held in Gaza. (b) For purposes of this section, the term ``appropriate congressional committees'' means the following: (1) The Committees on Appropriations, Armed Services, and Foreign Relations of the Senate. (2) The Select Committee on Intelligence of the Senate. (3) The Committees on Appropriations, Armed Services, and Foreign Affairs of the House of Representatives. (4) The Permanent Select Committee on Intelligence of the House of Representatives. Sec. 405. Funds appropriated by this Act for foreign assistance (including foreign military sales), for the Department of State, for broadcasting subject to supervision of United States Agency for Global Media, and for intelligence or intelligence related activities are deemed to be specifically authorized by the Congress for the purposes of section 10 of Public Law 91-672 (22 U.S.C. 2412), section 15 of the State Department Basic Authorities Act of 1956 (22 U.S.C. 2680), section 313 of the Foreign Relations Authorization Act, Fiscal Years 1994 and 1995 (22 U.S.C. 6212), and section 504(a)(1) of the National Security Act of 1947 (50 U.S.C. 3094(a)(1)). Sec. 406. Each amount designated in this Act by the Congress as being for an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985 shall be available (or repurposed or rescinded, if applicable) only if the President subsequently so designates all such amounts and transmits such designations to the Congress. Sec. 407. Any amount appropriated by this Act, designated by the Congress as an emergency requirement pursuant to section 251(b)(2)(A)(i) of the Balanced Budget and Emergency Deficit Control Act of 1985, and subsequently so designated by the President, and transferred pursuant to transfer authorities provided by this Act shall retain such designation. spending reduction account Sec. 408. $0. This Act may be cited as the ``Israel Security Supplemental Appropriations Act, 2024''. <all>