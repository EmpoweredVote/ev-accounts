You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-houchin-taxes/labels/coder-2.json. Write JSON only, matching
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

### topic_key: taxes
topic_id: f7e5678d-dadd-4556-a2fc-446e24642ceb  served_revision_id: 44ac21e4-76ad-4318-a5c4-d0d744a8313e
Question: How should government balance what it collects in taxes against what it spends on public services?
  1. Significantly raise taxes on wealthy people and large companies to fund more public services
  2. Moderately raise taxes on wealthy people and large companies to fund existing services
  3. Keep the current tax system mostly as-is, with targeted adjustments — closing loopholes or granting narrow relief
  4. Cut taxes broadly, including the main rates most people pay
  5. Cut taxes as far as possible and shrink what government does

#### Annex

# taxes — served revision 44ac21e4-76ad-4318-a5c4-d0d744a8313e (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. The season pin is an older revision
(`87f8c011-…`); coders code the served text below.

**Question:** "How should government balance what it collects in taxes against what it spends on
public services?"

**Orientation:** standard. Rung 1 raises taxes the most to fund more services, rung 5 cuts taxes as
far as possible and shrinks government. Rungs 1 and 2 differ by **size** and by **what the money
funds**; rungs 3 to 5 differ by **how broad** the cut is.

**Levels with a lever:** federal, state. Congress and state legislatures set
income, corporate and sales taxes; governors sign or veto them. Local officeholders hold no lever on
these taxes.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "income tax rate", "bracket", "flat tax",
"millionaire's tax" / "surtax", "corporate income tax", "capital gains", "estate tax", "loophole",
"tax expenditure", "credit", "deduction", "exemption", "rebate", "tax holiday", "revenue-neutral", "Taxpayer Protection Pledge".

1. **"Significantly raise taxes on wealthy people and large companies to fund more public services"**
   - Means: raise taxes on high earners and large companies by a large amount, and use the money for
     new or bigger public services.
   - Operative clauses: [a] raise taxes on wealthy people and large companies; [b] significantly;
     [c] to fund more public services.
   - Establishing evidence looks like: a tax increase on top earners or large companies whose revenue
     the instrument dedicates to new or expanded programmes, with the person's own words or the
     instrument's size showing it is large.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because "supports higher taxes on top earners to fund public
     services" shows direction only; it cannot separate "significantly" from "moderately" (CLAUDE.md) →
     `direction-only`. The **purpose clause** separates rungs 1 and 2: money for new or expanded
     services → rung 1; for existing services → rung 2. Words of size alone → `direction-only` _(ruled 2026-10-01)_.

2. **"Moderately raise taxes on wealthy people and large companies to fund existing services"**
   - Means: raise taxes on high earners and large companies by a modest amount, to pay for the
     services government already provides.
   - Operative clauses: [a] raise taxes on wealthy people and large companies; [b] moderately;
     [c] to fund existing services.
   - Establishing evidence looks like: a modest rate increase or surtax at the top whose stated use is
     current services or a budget gap, plus something that excludes rung 1.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - Commonly confused with rung 3 because **closing a loophole** used by large companies raises their
     taxes. A loophole closure is rung 3's clause, not a rate increase _(proposed)_.

3. **"Keep the current tax system mostly as-is, with targeted adjustments — closing loopholes or
   granting narrow relief"**
   - Means: leave the main structure and rates alone; change only narrow parts, by closing loopholes
     or giving targeted relief.
   - Operative clauses: [a] the system stays mostly as-is; [b] targeted adjustments (closing
     loopholes **or** narrow relief — either is enough).
   - Establishing evidence looks like: a loophole closure or a narrow credit **plus** evidence that the
     person does not want the main rates changed. A narrow-relief bill alone does not exclude rung 4
     → `direction-only`.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a **small** cut to the main rate looks like a "targeted
     adjustment". Rung 4 is defined by **which tax** is cut, not by how much: a cut to the main rate
     most people pay → rung 4, however small (gold).

4. **"Cut taxes broadly, including the main rates most people pay"**
   - Means: cut taxes widely, and the cut includes the main rates that most people pay.
   - Operative clauses: [a] a broad cut; [b] it includes the main rates most people pay.
   - Establishing evidence looks like: authoring or prime-sponsoring a bill that cuts the main
     individual income tax rate (or the main sales tax rate where that is the main tax).
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3: see rung 3.
   - Commonly confused with rung 5 because both cut the main rates. Rung 5 adds "as far as possible"
     **and** "shrink what government does".
   - Service cuts are no longer part of this rung. A person does not have to back spending cuts to
     sit here.

5. **"Cut taxes as far as possible and shrink what government does"**
   - Means: cut taxes to the lowest level possible and reduce the scope of government.
   - Operative clauses: [a] cut taxes as far as possible; [b] shrink what government does. Compound:
     one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a bill to abolish a main tax (for example the income tax)
     together with spending or scope cuts, or own words calling for both.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Sponsorship over a near-unanimous vote.** When a tax bill passed with fewer than 10% voting No,
  the vote cannot carry the chair (V4.1). A prime sponsorship of the same bill can, because
  sponsorship evidences the bill as filed (gold).
- **Omnibus bills.** A sponsor or co-sponsor of an omnibus that covers many unrelated subjects is not
  shown to support its tax clause; people trade parts to pass the rest → V4 `multi-subject`; BLANK
  `no-evidence` when nothing else survives (gold). A tax-only package with several tax provisions is
  not an omnibus: code the provision that matches the rung _(proposed)_.
- **Pledges (codebook H8).** A no-new-taxes pledge is `statement-answer`. This ladder has no "no tax
  increases" rung, so the pledge alone → `direction-only` _(proposed)_.
- **A cut only to the corporate rate**, capital gains or the estate tax is not "the main rates most
  people pay" → not rung 4 on its own; `direction-only` _(proposed)_.
- **One-time rebates and tax holidays** are narrow relief → rung 3 clause [b] _(proposed)_.
- **Spending caps and balanced-budget rules** limit spending, not taxes → rung 5 clause [b] at most
  _(proposed)_.
- **Budget and appropriations votes** → V4 `multi-subject`.


## Sources

---
snapshot_id: 3e4b1683-122d-5c65-aa93-4ebf4e460b1a
source_kind: own-site (the person's own site or account)
url: https://houchin.house.gov/media/press-releases/congresswoman-erin-houchin-statement-house-passage-one-big-beautiful-bill

Congresswoman Erin Houchin Statement on House Passage of the One Big, Beautiful Bill | Congresswoman Erin Houchin Skip to main content 342 Cannon House Office Building, Washington, DC 20515 Email Me (202) 225-5315 About Committees and Caucuses Our District Votes and Legislation Contact Newsletter Subscribe Office Locations Media Press Releases Issues Agriculture Economy Education Energy Health Veterans Border Security Services Art Competition Congressional App Challenge Congressional Commendations Flags Grant Applicants Help with a Federal Agency Internships Service Academy Nominations Tours and Tickets America 250 Attention Seniors - Fraud Alert! Casework Success Stories Community Project Funding Help for Veterans Subscribe X How Can I Help? Home Media Press Releases Congresswoman Erin Houchin Statement on House Passage of the One Big, Beautiful Bill May 22, 2025 Press Release Washington, D.C. – Today, Congresswoman Erin Houchin (IN-09) released the following statement: “The U.S. House of Representatives passed the One Big, Beautiful Bill this morning—delivering on President Trump’s America First agenda. This is a bill for hardworking American families. No tax on tips, no tax on overtime, and tax relief for seniors on Social Security. It enhances border security, ramps up deportations of criminal aliens, and unleashes American energy production. It also protects and strengthens Medicaid, Medicare, and Social Security for the people who truly need it most—pregnant women, children, individuals with disabilities, and seniors—by ending taxpayer-funded benefits for illegal immigrants and eliminating waste, fraud, and abuse. Democrats have been misleading the public for months—but we stayed focused and got the job done. Simply put—President Trump and House Republicans are keeping our promises by putting America First and, in doing so, will unlock a new golden age of prosperity for our country from sea to shining sea.” Office Locations Washington DC Office 342 Cannon House Office Building Washington, DC 20515 Phone: (202) 225-5315 Salem District Office 104 W Hackberry Street Salem, IN 47167 Phone: (812) 288-3999 Top Copyright Privacy House.gov Accessibility RSS

---
snapshot_id: a4e61ddf-13ed-56c8-8166-fbf1db4338cb
source_kind: public-record
url: https://clerk.house.gov/Votes/2025190

Office of the Clerk, U.S. House of Representatives Find Your Representative Search Office of the Clerk Toggle navigation Search Office of the Clerk Search button Legislative Information Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions 119th Congress, 2nd Session House Not In Session Next Session: October 9th, 2026 at 12:30 PM House Floor Proceedings Watch live.house.gov Additional Resources Votes Legacy View - 2024 119th Congress Nominees Statistics of the 2024 Congressional Election Final House Calendar (118th Congress) Résumé of Congressional Activity Legislative Search Congressional Record U.S. Senate House Schedule Bills This Week House Voting Days Member Information Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Republicans 218 218 Democrats 214 214 Independents 1 1 Vacancies 2 2 Republican Leadership Rep. Mike Johnson Speaker of the House Rep. Steve Scalise Majority Leader Rep. Tom Emmer Majority Whip Rep. Lisa C. McClain Republican Conference Chair Rep. Jay Obernolte Republican Policy Committee Chair Democratic Leadership Rep. Hakeem S. Jeffries Minority Leader Rep. Katherine M. Clark Minority Whip Rep. Pete Aguilar Democratic Caucus Chair Rep. Ted Lieu Democratic Caucus Vice Chair Additional Resources Find Your Representative Official List of Members by State Official Member Telephone Directory Duplicate and Similar Names of Members Terms of Service Mailing Labels [ MS Word | Text File ] Member Data [ Excel | XML | User Guide ] Biographical Directory Members on Congress.gov Committee Information COMMITTEE INFORMATION COMMITTEE PROFILES Agriculture Appropriations Armed Services Budget Education and Workforce Energy and Commerce Ethics Financial Services Foreign Affairs Homeland Security House Administration Judiciary Natural Resources Oversight and Government Reform Rules Science, Space, and Technology Small Business Transportation and Infrastructure Veterans' Affairs Ways and Means Select Intelligence Select Strategic Competition Joint Economic Joint Library Joint Printing Joint Taxation Additional Resources Official List of Members with Committee Assignments Official List of Standing Committees and Subcommittees Committee Repository Committee Reports Committees on Congress.gov Committee Data [ Excel ] Disclosures Disclosures PUBLIC DISCLOSURE Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications Additional Resources Lobbying Disclosures Public Laws Lobbying Disclosure Act About the Clerk About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office The Clerk of the House The Honorable Kevin F. McCumber Clerk of the U.S. House of Representatives Deputy Clerk Michelle H. Reinshuttle Deputy Clerk Contact Information Mailing Address U.S. Capitol Room H154 Washington, DC 20515&ndash;6601 Telephone Number (202) 225&ndash;7000 Office Hours 9:00 AM&ndash;6:00 PM, Monday&ndash;Friday Additional Resources Artificial Intelligence Use Case Inventory [ USHouse-Clerk-1: Comparative Print Suite ] 119th Congress, 2nd Session Back to Previous Page Roll Call 190 | Bill Number: H. R. 1 Share XML View | HTML View Jul 03, 2025, 02:31 PM | 119th Congress, 1st Session Vote Question: On Motion to Concur in the Senate Amendment One Big Beautiful Bill Act Vote Type: Recorded Vote Status: Passed VOTES Aye: 218 No: 214 present: 0 not voting: 0 Remote Voting by Proxy Votes by party votes by party Party Ayes Noes Present Not Voting Republican 218 2 0 0 Democratic 0 212 0 0 Independent 0 0 0 0 Total 218 214 0 0 All votes Keyword Name Party All Parties Republican Democratic Independent State All States Votes All Votes YEA/AYE NAY/NO PRESENT NOT VOTING All votes Representative Party State Vote Adams Adams Democratic North Carolina NC No Aderholt Aderholt Republican Alabama AL Aye Aguilar Aguilar Democratic California CA No Alford Alford Republican Missouri MO Aye Allen Allen Republican Georgia GA Aye Amo Amo Democratic Rhode Island RI No Amodei (NV) Amodei (NV) Republican Nevada NV Aye Ansari Ansari Democratic Arizona AZ No Arrington Arrington Republican Texas TX Aye Auchincloss Auchincloss Democratic Massachusetts MA No Babin Babin Republican Texas TX Aye Bacon Bacon Republican Nebraska NE Aye Baird Baird Republican Indiana IN Aye Balderson Balderson Republican Ohio OH Aye Balint Balint Democratic Vermont VT No Barr Barr Republican Kentucky KY Aye Barragán Barragan Democratic California CA No Barrett Barrett Republican Michigan MI Aye Baumgartner Baumgartner Republican Washington WA Aye Bean (FL) Bean (FL) Republican Florida FL Aye Beatty Beatty Democratic Ohio OH No Begich Begich Republican Alaska AK Aye Bell Bell Democratic Missouri MO No Bentz Bentz Republican Oregon OR Aye Bera Bera Democratic California CA No Bergman Bergman Republican Michigan MI Aye Beyer Beyer Democratic Virginia VA No Bice Bice Republican Oklahoma OK Aye Biggs (AZ) Biggs (AZ) Republican Arizona AZ Aye Biggs (SC) Biggs (SC) Republican South Carolina SC Aye Bilirakis Bilirakis Republican Florida FL Aye Bishop Bishop Democratic Georgia GA No Boebert Boebert Republican Colorado CO Aye Bonamici Bonamici Democratic Oregon OR No Bost Bost Republican Illinois IL Aye Boyle (PA) Boyle (PA) Democratic Pennsylvania PA No Brecheen Brecheen Republican Oklahoma OK Aye Bresnahan Bresnahan Republican Pennsylvania PA Aye Brown Brown Democratic Ohio OH No Brownley Brownley Democratic California CA No Buchanan Buchanan Republican Florida FL Aye Budzinski Budzinski Democratic Illinois IL No Burchett Burchett Republican Tennessee TN Aye Burlison Burlison Republican Missouri MO Aye Bynum Bynum Democratic Oregon OR No Calvert Calvert Republican California CA Aye Cammack Cammack Republican Florida FL Aye Carbajal Carbajal Democratic California CA No Carey Carey Republican Ohio OH Aye Carson Carson Democratic Indiana IN No Carter (GA) Carter (GA) Republican Georgia GA Aye Carter (LA) Carter (LA) Democratic Louisiana LA No Carter (TX) Carter (TX) Republican Texas TX Aye Casar Casar Democratic Texas TX No Case Case Democratic Hawaii HI No Casten Casten Democratic Illinois IL No Castor (FL) Castor (FL) Democratic Florida FL No Castro (TX) Castro (TX) Democratic Texas TX No Cherfilus-McCormick Cherfilus-McCormick Democratic Florida FL No Chu Chu Democratic California CA No Ciscomani Ciscomani Republican Arizona AZ Aye Cisneros Cisneros Democratic California CA No Clark (MA) Clark (MA) Democratic Massachusetts MA No Clarke (NY) Clarke (NY) Democratic New York NY No Cleaver Cleaver Democratic Missouri MO No Cline Cline Republican Virginia VA Aye Cloud Cloud Republican Texas TX Aye Clyburn Clyburn Democratic South Carolina SC No Clyde Clyde Republican Georgia GA Aye Cohen Cohen Democratic Tennessee TN No Cole Cole Republican Oklahoma OK Aye Collins Collins Republican Georgia GA Aye Comer Comer Republican Kentucky KY Aye Conaway Conaway Democratic New Jersey NJ No Correa Correa Democratic California CA No Costa Costa Democratic California CA No Courtney Courtney Democratic Connecticut CT No Craig Craig Democratic Minnesota MN No Crane Crane Republican Arizona AZ Aye Crank Crank Republican Colorado CO Aye Crawford Crawford Republican Arkansas AR Aye Crenshaw Crenshaw Republican Texas TX Aye Crockett Crockett Democratic Texas TX No Crow Crow Democratic Colorado CO No Cuellar Cuellar Democratic Texas TX No Davids (KS) Davids (KS) Democratic Kansas KS No Davidson Davidson Republican Ohio OH Aye Davis (IL) Davis (IL) Democratic Illinois IL No Davis (NC) Davis (NC) Democratic North Carolina NC No De La Cruz De La Cruz Republican Texas TX Aye Dean (PA) Dean (PA) Democratic Pennsylvania PA No DeGette DeGette Democratic Colorado CO No DeLauro DeLauro Democratic Connecticut CT No DelBene DelBene Democratic Washington WA No Deluzio Deluzio Democratic Pennsylvania PA No DeSaulnier DeSaulnier Democratic California CA No DesJarlais DesJarlais Republican Tennessee TN Aye Dexter Dexter Democratic Oregon OR No Diaz-Balart Diaz-Balart Republican Florida FL Aye Dingell Dingell Democratic Michigan MI No Doggett Doggett Democratic Texas TX No Donalds Donalds Republican Florida FL Aye Downing Downing Republican Montana MT Aye Dunn (FL) Dunn (FL) Republican Florida FL Aye Edwards Edwards Republican North Carolina NC Aye Elfreth Elfreth Democratic Maryland MD No Ellzey Ellzey Republican Texas TX Aye Emmer Emmer Republican Minnesota MN Aye Escobar Escobar Democratic Texas TX No Espaillat Espaillat Democratic New York NY No Estes Estes Republican Kansas KS Aye Evans (CO) Evans (CO) Republican Colorado CO Aye Evans (PA) Evans (PA) Democratic Pennsylvania PA No Ezell Ezell Republican Mississippi MS Aye Fallon Fallon Republican Texas TX Aye Fedorchak Fedorchak Republican North Dakota ND Aye Feenstra Feenstra Republican Iowa IA Aye Fields Fields Democratic Louisiana LA No Figures Figures Democratic Alabama AL No Fine Fine Republican Florida FL Aye Finstad Finstad Republican Minnesota MN Aye Fischbach Fischbach Republican Minnesota MN Aye Fitzgerald Fitzgerald Republican Wisconsin WI Aye Fitzpatrick Fitzpatrick Republican Pennsylvania PA No Fleischmann Fleischmann Republican Tennessee TN Aye Fletcher Fletcher Democratic Texas TX No Flood Flood Republican Nebraska NE Aye Fong Fong Republican California CA Aye Foster Foster Democratic Illinois IL No Foushee Foushee Democratic North Carolina NC No Foxx Foxx Republican North Carolina NC Aye Frankel, Lois Frankel, Lois Democratic Florida FL No Franklin, Scott Franklin, Scott Republican Florida FL Aye Friedman Friedman Democratic California CA No Frost Frost Democratic Florida FL No Fry Fry Republican South Carolina SC Aye Fulcher Fulcher Republican Idaho ID Aye Garamendi Garamendi Democratic California CA No Garbarino Garbarino Republican New York NY Aye Garcia (CA) Garcia (CA) Democratic California CA No García (IL) Garcia (IL) Democratic Illinois IL No Garcia (TX) Garcia (TX) Democratic Texas TX No Gill (TX) Gill (TX) Republican Texas TX Aye Gillen Gillen Democratic New York NY No Gimenez Gimenez Republican Florida FL Aye Golden (ME) Golden (ME) Democratic Maine ME No Goldman (NY) Goldman (NY) Democratic New York NY No Goldman (TX) Goldman (TX) Republican Texas TX Aye Gomez Gomez Democratic California CA No Gonzales, Tony Gonzales, Tony Republican Texas TX Aye Gonzalez, V. Gonzalez, V. Democratic Texas TX No Gooden Gooden Republican Texas TX Aye Goodlander Goodlander Democratic New Hampshire NH No Gosar Gosar Republican Arizona AZ Aye Gottheimer Gottheimer Democratic New Jersey NJ No Graves Graves Republican Missouri MO Aye Gray Gray Democratic California CA No Green (TN) Green (TN) Republican Tennessee TN Aye Green, Al (TX) Green, Al (TX) Democratic Texas TX No Greene (GA) Greene (GA) Republican Georgia GA Aye Griffith Griffith Republican Virginia VA Aye Grothman Grothman Republican Wisconsin WI Aye Guest Guest Republican Mississippi MS Aye Guthrie Guthrie Republican Kentucky KY Aye Hageman Hageman Republican Wyoming WY Aye Hamadeh (AZ) Hamadeh (AZ) Republican Arizona AZ Aye Harder (CA) Harder (CA) Democratic California CA No Haridopolos Haridopolos Republican Florida FL Aye Harrigan Harrigan Republican North Carolina NC Aye Harris (MD) Harris (MD) Republican Maryland MD Aye Harris (NC) Harris (NC) Republican North Carolina NC Aye Harshbarger Harshbarger Republican Tennessee TN Aye Hayes Hayes Democratic Connecticut CT No Hern (OK) Hern (OK) Republican Oklahoma OK Aye Higgins (LA) Higgins (LA) Republican Louisiana LA Aye Hill (AR) Hill (AR) Republican Arkansas AR Aye Himes Himes Democratic Connecticut CT No Hinson Hinson Republican Iowa IA Aye Horsford Horsford Democratic Nevada NV No Houchin Houchin Republican Indiana IN Aye Houlahan Houlahan Democratic Pennsylvania PA No Hoyer Hoyer Democratic Maryland MD No Hoyle (OR) Hoyle (OR) Democratic Oregon OR No Hudson Hudson Republican North Carolina NC Aye Huffman Huffman Democratic California CA No Huizenga Huizenga Republican Michigan MI Aye Hunt Hunt Republican Texas TX Aye Hurd (CO) Hurd (CO) Republican Colorado CO Aye Issa Issa Republican California CA Aye Ivey Ivey Democratic Maryland MD No Jack Jack Republican Georgia GA Aye Jackson (IL) Jackson (IL) Democratic Illinois IL No Jackson (TX) Jackson (TX) Republican Texas TX Aye Jacobs Jacobs Democratic California CA No James James Republican Michigan MI Aye Jayapal Jayapal Democratic Washington WA No Jeffries Jeffries Democratic New York NY No Johnson (GA) Johnson (GA) Democratic Georgia GA No Johnson (LA) Johnson (LA) Republican Louisiana LA Aye Johnson (SD) Johnson (SD) Republican South Dakota SD Aye Johnson (TX) Johnson (TX) Democratic Texas TX No Jordan Jordan Republican Ohio OH Aye Joyce (OH) Joyce (OH) Republican Ohio OH Aye Joyce (PA) Joyce (PA) Republican Pennsylvania PA Aye Kamlager-Dove Kamlager-Dove Democratic California CA No Kaptur Kaptur Democratic Ohio OH No Kean Kean Republican New Jersey NJ Aye Keating Keating Democratic Massachusetts MA No Kelly (IL) Kelly (IL) Democratic Illinois IL No Kelly (MS) Kelly (MS) Republican Mississippi MS Aye Kelly (PA) Kelly (PA) Republican Pennsylvania PA Aye Kennedy (NY) Kennedy (NY) Democratic New York NY No Kennedy (UT) Kennedy (UT) Republican Utah UT Aye Khanna Khanna Democratic California CA No Kiggans (VA) Kiggans (VA) Republican Virginia VA Aye Kiley (CA) Kiley (CA) Republican California CA Aye Kim Kim Republican California CA Aye Knott Knott Republican North Carolina NC Aye Krishnamoorthi Krishnamoorthi Democratic Illinois IL No Kustoff Kustoff Republican Tennessee TN Aye LaHood LaHood Republican Illinois IL Aye LaLota LaLota Republican New York NY Aye LaMalfa LaMalfa Republican California CA Aye Landsman Landsman Democratic Ohio OH No Langworthy Langworthy Republican New York NY Aye Larsen (WA) Larsen (WA) Democratic Washington WA No Larson (CT) Larson (CT) Democratic Connecticut CT No Latimer Latimer Democratic New York NY No Latta Latta Republican Ohio OH Aye Lawler Lawler Republican New York NY Aye Lee (FL) Lee (FL) Republican Florida FL Aye Lee (NV) Lee (NV) Democratic Nevada NV No Lee (PA) Lee (PA) Democratic Pennsylvania PA No Leger Fernandez Leger Fernandez Democratic New Mexico NM No Letlow Letlow Republican Louisiana LA Aye Levin Levin Democratic California CA No Liccardo Liccardo Democratic California CA No Lieu Lieu Democratic California CA No Lofgren Lofgren Democratic California CA No Loudermilk Loudermilk Republican Georgia GA Aye Lucas Lucas Republican Oklahoma OK Aye Luna Luna Republican Florida FL Aye Luttrell Luttrell Republican Texas TX Aye Lynch Lynch Democratic Massachusetts MA No Mace Mace Republican South Carolina SC Aye Mackenzie Mackenzie Republican Pennsylvania PA Aye Magaziner Magaziner Democratic Rhode Island RI No Malliotakis Malliotakis Republican New York NY Aye Maloy Maloy Republican Utah UT Aye Mann Mann Republican Kansas KS Aye Mannion Mannion Democratic New York NY No Massie Massie Republican Kentucky KY No Mast Mast Republican Florida FL Aye Matsui Matsui Democratic California CA No McBath McBath Democratic Georgia GA No McBride McBride Democratic Delaware DE No McCaul McCaul Republican Texas TX Aye McClain McClain Republican Michigan MI Aye McClain Delaney McClain Delaney Democratic Maryland MD No McClellan McClellan Democratic Virginia VA No McClintock McClintock Republican California CA Aye McCollum McCollum Democratic Minnesota MN No McCormick McCormick Republican Georgia GA Aye McDonald Rivet McDonald Rivet Democratic Michigan MI No McDowell McDowell Republican North Carolina NC Aye McGarvey McGarvey Democratic Kentucky KY No McGovern McGovern Democratic Massachusetts MA No McGuire McGuire Republican Virginia VA Aye McIver McIver Democratic New Jersey NJ No Meeks Meeks Democratic New York NY No Menendez Menendez Democratic New Jersey NJ No Meng Meng Democratic New York NY No Messmer Messmer Republican Indiana IN Aye Meuser Meuser Republican Pennsylvania PA Aye Mfume Mfume Democratic Maryland MD No Miller (IL) Miller (IL) Republican Illinois IL Aye Miller (OH) Miller (OH) Republican Ohio OH Aye Miller (WV) Miller (WV) Republican West Virginia WV Aye Miller-Meeks Miller-Meeks Republican Iowa IA Aye Mills Mills Republican Florida FL Aye Min Min Democratic California CA No Moolenaar Moolenaar Republican Michigan MI Aye Moore (AL) Moore (AL) Republican Alabama AL Aye Moore (NC) Moore (NC) Republican North Carolina NC Aye Moore (UT) Moore (UT) Republican Utah UT Aye Moore (WI) Moore (WI) Democratic Wisconsin WI No Moore (WV) Moore (WV) Republican West Virginia WV Aye Moran Moran Republican Texas TX Aye Morelle Morelle Democratic New York NY No Morrison Morrison Democratic Minnesota MN No Moskowitz Moskowitz Democratic Florida FL No Moulton Moulton Democratic Massachusetts MA No Mrvan Mrvan Democratic Indiana IN No Mullin Mullin Democratic California CA No Murphy Murphy Republican North Carolina NC Aye Nadler Nadler Democratic New York NY No Neal Neal Democratic Massachusetts MA No Neguse Neguse Democratic Colorado CO No Nehls Nehls Republican Texas TX Aye Newhouse Newhouse Republican Washington WA Aye Norcross Norcross Democratic New Jersey NJ No Norman Norman Republican South Carolina SC Aye Nunn (IA) Nunn (IA) Republican Iowa IA Aye Obernolte Obernolte Republican California CA Aye Ocasio-Cortez Ocasio-Cortez Democratic New York NY No Ogles Ogles Republican Tennessee TN Aye Olszewski Olszewski Democratic Maryland MD No Omar Omar Democratic Minnesota MN No Onder Onder Republican Missouri MO Aye Owens Owens Republican Utah UT Aye Pallone Pallone Democratic New Jersey NJ No Palmer Palmer Republican Alabama AL Aye Panetta Panetta Democratic California CA No Pappas Pappas Democratic New Hampshire NH No Patronis Patronis Republican Florida FL Aye Pelosi Pelosi Democratic California CA No Perez Perez Democratic Washington WA No Perry Perry Republican Pennsylvania PA Aye Peters Peters Democratic California CA No Pettersen Pettersen Democratic Colorado CO No Pfluger Pfluger Republican Texas TX Aye Pingree Pingree Democratic Maine ME No Pocan Pocan Democratic Wisconsin WI No Pou Pou Democratic New Jersey NJ No Pressley Pressley Democratic Massachusetts MA No Quigley Quigley Democratic Illinois IL No Ramirez Ramirez Democratic Illinois IL No Randall Randall Democratic Washington WA No Raskin Raskin Democratic Maryland MD No Reschenthaler Reschenthaler Republican Pennsylvania PA Aye Riley (NY) Riley (NY) Democratic New York NY No Rivas Rivas Democratic California CA No Rogers (AL) Rogers (AL) Republican Alabama AL Aye Rogers (KY) Rogers (KY) Republican Kentucky KY Aye Rose Rose Republican Tennessee TN Aye Ross Ross Democratic North Carolina NC No Rouzer Rouzer Republican North Carolina NC Aye Roy Roy Republican Texas TX Aye Ruiz Ruiz Democratic California CA No Rulli Rulli Republican Ohio OH Aye Rutherford Rutherford Republican Florida FL Aye Ryan Ryan Democratic New York NY No Salazar Salazar Republican Florida FL Aye Salinas Salinas Democratic Oregon OR No Sánchez Sanchez Democratic California CA No Scalise Scalise Republican Louisiana LA Aye Scanlon Scanlon Democratic Pennsylvania PA No Schakowsky Schakowsky Democratic Illinois IL No Schmidt Schmidt Republican Kansas KS Aye Schneider Schneider Democratic Illinois IL No Scholten Scholten Democratic Michigan MI No Schrier Schrier Democratic Washington WA No Schweikert Schweikert Republican Arizona AZ Aye Scott (VA) Scott (VA) Democratic Virginia VA No Scott, Austin Scott, Austin Republican Georgia GA Aye Scott, David Scott, David Democratic Georgia GA No Self Self Republican Texas TX Aye Sessions Sessions Republican Texas TX Aye Sewell Sewell Democratic Alabama AL No Sherman Sherman Democratic California CA No Sherrill Sherrill Democratic New Jersey NJ No Shreve Shreve Republican Indiana IN Aye Simon Simon Democratic California CA No Simpson Simpson Republican Idaho ID Aye Smith (MO) Smith (MO) Republican Missouri MO Aye Smith (NE) Smith (NE) Republican Nebraska NE Aye Smith (NJ) Smith (NJ) Republican New Jersey NJ Aye Smith (WA) Smith (WA) Democratic Washington WA No Smucker Smucker Republican Pennsylvania PA Aye Sorensen Sorensen Democratic Illinois IL No Soto Soto Democratic Florida FL No Spartz Spartz Republican Indiana IN Aye Stansbury Stansbury Democratic New Mexico NM No Stanton Stanton Democratic Arizona AZ No Stauber Stauber Republican Minnesota MN Aye Stefanik Stefanik Republican New York NY Aye Steil Steil Republican Wisconsin WI Aye Steube Steube Republican Florida FL Aye Stevens Stevens Democratic Michigan MI No Strickland Strickland Democratic Washington WA No Strong Strong Republican Alabama AL Aye Stutzman Stutzman Republican Indiana IN Aye Subramanyam Subramanyam Democratic Virginia VA No Suozzi Suozzi Democratic New York NY No Swalwell Swalwell Democratic California CA No Sykes Sykes Democratic Ohio OH No Takano Takano Democratic California CA No Taylor Taylor Republican Ohio OH Aye Tenney Tenney Republican New York NY Aye Thanedar Thanedar Democratic Michigan MI No Thompson (CA) Thompson (CA) Democratic California CA No Thompson (MS) Thompson (MS) Democratic Mississippi MS No Thompson (PA) Thompson (PA) Republican Pennsylvania PA Aye Tiffany Tiffany Republican Wisconsin WI Aye Timmons Timmons Republican South Carolina SC Aye Titus Titus Democratic Nevada NV No Tlaib Tlaib Democratic Michigan MI No Tokuda Tokuda Democratic Hawaii HI No Tonko Tonko Democratic New York NY No Torres (CA) Torres (CA) Democratic California CA No Torres (NY) Torres (NY) Democratic New York NY No Trahan Trahan Democratic Massachusetts MA No Tran Tran Democratic California CA No Turner (OH) Turner (OH) Republican Ohio OH Aye Underwood Underwood Democratic Illinois IL No Valadao Valadao Republican California CA Aye Van Drew Van Drew Republican New Jersey NJ Aye Van Duyne Van Duyne Republican Texas TX Aye Van Orden Van Orden Republican Wisconsin WI Aye Vargas Vargas Democratic California CA No Vasquez Vasquez Democratic New Mexico NM No Veasey Veasey Democratic Texas TX No Velázquez Velazquez Democratic New York NY No Vindman Vindman Democratic Virginia VA No Wagner Wagner Republican Missouri MO Aye Walberg Walberg Republican Michigan MI Aye Wasserman Schultz Wasserman Schultz Democratic Florida FL No Waters Waters Democratic California CA No Watson Coleman Watson Coleman Democratic New Jersey NJ No Weber (TX) Weber (TX) Republican Texas TX Aye Webster (FL) Webster (FL) Republican Florida FL Aye Westerman Westerman Republican Arkansas AR Aye Whitesides Whitesides Democratic California CA No Wied Wied Republican Wisconsin WI Aye Williams (GA) Williams (GA) Democratic Georgia GA No Williams (TX) Williams (TX) Republican Texas TX Aye Wilson (FL) Wilson (FL) Democratic Florida FL No Wilson (SC) Wilson (SC) Republican South Carolina SC Aye Wittman Wittman Republican Virginia VA Aye Womack Womack Republican Arkansas AR Aye Yakym Yakym Republican Indiana IN Aye Zinke Zinke Republican Montana MT Aye No data found 119 Contact Information Room H154, The Capitol Washington, DC 20515-6601 p: (202) 225-7000 For general inquiries: info.clerkweb@mail.house.gov For general technical support: techsupport.clerkweb@mail.house.gov Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Disclosures Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office Committee Information Committee Profiles Clerk Sites Bills This Week Biographical Directory Clerk Kids Committee Repository History, Art & Archives Office of the Chaplain Help & Resources FAQs Privacy Policy Site Map

---
snapshot_id: f7c6cc16-e1e2-5581-93ee-6143d769dc63
source_kind: own-site (the person's own site or account)
url: https://www.erinhouchin.com/issues

Erin Houchin on the Issues &mdash; Erin Houchin for Congress 0 Skip to Content ABOUT ISSUES VOLUNTEER CONTACT DONATE Open Menu Close Menu ABOUT ISSUES VOLUNTEER CONTACT DONATE Open Menu Close Menu ABOUT ISSUES VOLUNTEER CONTACT DONATE ERIN ON THE ISSUES SECURE THE BORDER: Joe Biden let over 10 million individuals illegally invade our country—that we know of. These illegals outnumber the population of Indiana by three million people. Erin visited the border in Texas twice, and witnessed the chaos and destruction firsthand. She fully supports President Trump’s efforts to restore border security—by backing law enforcement, finishing the wall, and deporting criminal illegal aliens to protect American communities. STAND WITH ISRAEL: Erin stands firmly with Israel, our nation’s strongest ally in the Middle East. Even before Hamas’ barbaric terrorist attack on October 7, 2023, she has vocally supported Israel’s right to defend itself, and the right of Israelis to live. Erin believes that we as a nation have a moral obligation to unequivocally defend Israel. She is committed to standing resolute against anti-Semitism in all forms at home and abroad and advocating for the U.S. to cut all aid to any sponsors of terrorism. CUT GOVERNMENT SPENDING: Erin believes our government takes too much of your money, and spends too much. Just as families across Indiana balance their budgets, she believes the federal government should too. It's no question that our growing national debt is a national security concern. Erin is a committed fiscal conservative and has the track record to prove it, and as a champion for Indiana’s Balanced Budget Amendment, she is bringing that same fiscal discipline to Washington. PROTECT THE UNBORN: Erin is pro-life and always has been. She has been a steadfast leader in the fight for the unborn, consistently advocating for the prohibition of late-term abortions, and resources and care for mothers in need. In Congress, she continues to be a voice for the voiceless. National Right to Life and the Susan B. Anthony List have endorsed her, she has earned an A+ rating from the SBA List, and had a consistent 100% pro-life voting record as a member of the Indiana State Senate. STAND FOR CONSERVATIVE VALUES: The strong conservative values instilled in Erin growing up in Scottsburg have become a foundational part of who she is. A strong defender of the Second Amendment, the Right to Life, and the right to worship freely, Erin will always fight for our conservative freedoms and liberties. She will continue standing steadfast for an America First Agenda that allows us to live safely and freely. PROTECT PARENTAL RIGHTS: Parents should be in the driver's seat of their children's education. The pandemic opened American parents' eyes to the reality of our public school system, and millions of parents didn't like what they saw. As a mother of three, Erin knows that parents are the primary stakeholders in their children's education. That's why she voted to pass the Parents Bill of Rights and will continue to support parents in this ongoing effort for transparency and a seat at the table as we prepare the next generation for success. SUPPORT OUR VETERANS: America is blessed with the greatest fighting force in the world, and Erin deeply appreciates our servicemen and women and their families. She is committed to improving the welfare and quality of life for our veterans and their families, our active-duty military members and their spouses. Erin is committed to ensuring we keep our promises to those who fought to defend our freedoms and never let them down. UPHOLD LAW & ORDER: Hoosiers are fortunate to have some of the most dedicated and talented law enforcement and public safety officials in the country, and it’s our duty to have their backs. These brave men and women should be protected by lawmakers instead of being met with hostility and resentment. Erin will always fight to ensure our officers have the necessary resources to do their jobs effectively and safely, and they have the support and compensation they deserve. Erin will never allow radical left-wing politicians to defund the police. CREATE JOBS: Erin knows the best way to create jobs and grow the economy is to get the government out of the way and let small business owners do what they do best – innovate and create new jobs. Indiana has one of the best economies in the nation, a direct result of our conservative values. As a small business owner, Erin continues the fight to cut bureaucratic red tape and support limited government while working to cut taxes, promote free markets, and control government spending. PROTECT THE SECOND AMENDMENT: Erin is a firm believer that the Second Amendment is one of our most important freedoms, and she understands the importance of protecting our constitutional right to bear arms. The founders saw the crucial importance of giving citizens the right to protect themselves, and we must all protect that right. CONTRIBUTE PAID FOR BY HOUCHIN FOR CONGRESS ABOUT | ISSUES | CONTACT Privacy Policy

---
snapshot_id: 6cf3e2ee-1088-539f-a9eb-281c4b6c7191
source_kind: own-site (the person's own site or account)
url: https://houchin.house.gov/media/press-releases/rep-erin-houchin-applauds-house-passage-one-big-beautiful-bill

Rep. Erin Houchin Applauds House Passage of the One Big Beautiful Bill | Congresswoman Erin Houchin Skip to main content 342 Cannon House Office Building, Washington, DC 20515 Email Me (202) 225-5315 About Committees and Caucuses Our District Votes and Legislation Contact Newsletter Subscribe Office Locations Media Press Releases Issues Agriculture Economy Education Energy Health Veterans Border Security Services Art Competition Congressional App Challenge Congressional Commendations Flags Grant Applicants Help with a Federal Agency Internships Service Academy Nominations Tours and Tickets America 250 Attention Seniors - Fraud Alert! Casework Success Stories Community Project Funding Help for Veterans Subscribe X How Can I Help? Home Media Press Releases Rep. Erin Houchin Applauds House Passage of the One Big Beautiful Bill July 7, 2025 Press Release WASHINGTON, D.C. — Congresswoman Erin Houchin (IN-09) released the following statement after the House of Representatives passed the One Big Beautiful Bill, historic legislation that delivers relief to American families, workers, farmers, and small businesses: “Today, House Republicans kept our promise to the American people. The One Big Beautiful Bill is the boldest, most conservative legislation we’ve passed in a generation—and I was proud to help lead the charge. This bill makes the Trump tax cuts permanent, ends taxes on tips and overtime, slashes wasteful spending, secures our border, unleashes American energy, and restores accountability across the federal government. For families in Southern Indiana, it means more money in their pockets, fewer burdens from Washington, and greater opportunity. As we approach Independence Day, this bill is about restoring independence for the American people—independence from government overreach, from crushing taxes, and from bureaucratic control. I look forward to President Trump signing it into law tomorrow, on America’s birthday, and continuing our mission to Make America Great Again.” Office Locations Washington DC Office 342 Cannon House Office Building Washington, DC 20515 Phone: (202) 225-5315 Salem District Office 104 W Hackberry Street Salem, IN 47167 Phone: (812) 288-3999 Top Copyright Privacy House.gov Accessibility RSS