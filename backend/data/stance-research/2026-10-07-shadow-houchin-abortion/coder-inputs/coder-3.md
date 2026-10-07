You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-houchin-abortion/labels/coder-3.json. Write JSON only, matching
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

politician_id: 68568faf-1e0f-4ca2-89d9-bda625665712  office_id: b343becb-af7d-4a19-a6a1-2e5df210f344
Erin Houchin — U.S. House of Representatives - Indiana 9th Congressional District, Indiana (seated, level: federal)
Current term: 2023-01-03 (precision: day) to present

## Topics (served ladder text — code against these words only)

### topic_key: abortion
topic_id: af2fdfd6-02c4-49df-b09c-cf8536f4773f  served_revision_id: 085feb9c-f157-4dae-bfd0-7b2736c5d87c
Question: How should the law handle abortion?
  1. keep abortion legal at every stage of pregnancy, with no time limit.
  2. keep abortion legal through the second trimester, and after that only to protect the mother's health.
  3. allow abortion during the first trimester, and after that only to protect the mother's health.
  4. ban abortion except in cases of rape, incest, or a serious risk to the mother's life.
  5. ban abortion in all cases, with no exceptions.

#### Annex

# abortion — served revision 085feb9c-f157-4dae-bfd0-7b2736c5d87c (Season 2)

**Status:** draft (2026-10-01). Lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris
Andrews). Lines marked _(proposed)_ are a drafter's reading, not yet ruled. The season pin is an
older revision (`dab46e5c-…`); coders code the served text below.

**Question:** "How should the law handle abortion?"

**Orientation:** standard. Rung 1 has no legal limit, rung 5 is a ban with no exceptions. The rungs
order **when** abortion is legal and **which exceptions** apply after that point.

**Levels with a lever:** federal, state. The lever is state law;
federal action is national limits or protections; local governments rarely hold one, so a local
officeholder is coded on own words.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "gestational limit", "weeks of gestation", "post-fertilization age", "LMP" (last
menstrual period), "viability", "heartbeat" (an early limit, about 6 weeks), "medical emergency",
"life of the mother", "reproductive freedom", "fundamental right", "fetal personhood".

**Weeks and trimesters.** The rungs state limits in trimesters; laws state them in weeks. The first
trimester ends at about 13 weeks, the second at about 27. **Read the weeks as the law states them**
(LMP or post-fertilization); do not convert _(ruled 2026-10-01)_.

1. **"keep abortion legal at every stage of pregnancy, with no time limit."**
   - Means: no point in pregnancy after which the law forbids abortion.
   - Operative clauses: [a] legal at every stage; [b] no time limit.
   - Establishing evidence looks like: own words that reject every gestational limit; an instrument
     that removes the jurisdiction's limits and says no limit remains _(proposed)_.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a **declared right** reads like "no limit". A text that
     declares a right to abortion and names no limit has said nothing about limits; other law may
     still set them → `direction-only` (V4.2 "Silence is not a clause").
   - Public funding is no longer part of this rung. A funding bill does not move a person along these
     rungs → `adjacent` _(proposed)_.

2. **"keep abortion legal through the second trimester, and after that only to protect the mother's
   health."**
   - Means: abortion is legal until about 27 weeks; after that, only for the mother's health.
   - Operative clauses: [a] legal through the second trimester; [b] after that, a health exception
     only.
   - Establishing evidence looks like: a limit at about 22 weeks or later — up to about 27 weeks, or
     at viability — with a health exception after it.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 when the limit falls between the two thresholds. A limit at
     **16–21 weeks** establishes neither rung → BLANK `direction-only` _(ruled 2026-10-01)_.
   - A limit with **no** stated exception after it does not reach rung 2 on its own (V4.2 "Silence is
     not a clause"). A limit with a **life-only** exception after it → `compound-partial`, the same
     as rung 3 _(proposed, by analogy with the rung-3 ruling)_.

3. **"allow abortion during the first trimester, and after that only to protect the mother's
   health."**
   - Means: abortion is legal early in pregnancy; after that, only for the mother's health.
   - Operative clauses: [a] legal during the first trimester; [b] after that, a health exception
     only.
   - Establishing evidence looks like: a limit at about **12–15 weeks** with a health exception after
     it (a medical emergency that covers serious lasting harm to the mother, not only death) — **but
     only when the law actually permits abortion up to the limit**, either affirmatively or by
     repealing a broader ban. Then it excludes rung 2 (it bans most of the second trimester) and rung
     4 (it allows abortion for any reason before the limit). A 15-week limit is within the ladder's
     precision for "first trimester" _(ruled 2026-10-01, revised the same day)_.
   - **Read the act's construction or savings clause.** A limit that says it does not create or
     recognize a right to abortion, does not make lawful any abortion that is now unlawful, or leaves
     a broader ban in force, evidences **no permitted stage**. A vote for it shows only the
     restrictive side → BLANK `direction-only` _(ruled 2026-10-01)_.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_. A gestational-limit bill is chair-shaped only
     when it permits abortion before the limit (see the construction clause above).
   - Commonly confused with rung 2: see rung 2.
   - A **life-only** exception after the early limit is narrower than "to protect the mother's health"
     → BLANK `compound-partial` _(ruled 2026-10-01)_.
   - A limit with **no** stated exception after it does not reach rung 3 on its own (V4.2).

4. **"ban abortion except in cases of rape, incest, or a serious risk to the mother's life."**
   - Means: abortion is banned, with three exceptions.
   - Operative clauses: [a] a ban; [b] exceptions for rape **and** incest **and** a serious risk to
     the mother's life.
   - Establishing evidence looks like: a ban with all three exceptions. An **early ban** (for example
     at about 6 weeks) with all three exceptions is in practice a ban with those exceptions → rung 4
     _(ruled 2026-10-01)_.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 when the ban has a **life-only** exception. It has an exception, so
     it is not rung 5; it lacks rape and incest, so it is not rung 4 → BLANK `direction-only` _(ruled
     2026-10-01)_. A ban with life and health exceptions but no rape or incest exception → the same
     _(proposed)_.

5. **"ban abortion in all cases, with no exceptions."**
   - Means: abortion is banned at every stage, with no exception at all, including for the mother's
     life.
   - Operative clauses: [a] a ban; [b] no exceptions.
   - Establishing evidence looks like: own words that reject every exception, including the mother's
     life. [b] is an absence clause: a ban that lists no exception does not show that none applies,
     because other law may supply one (V4.2) _(proposed)_.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Criminal penalties for patients and providers are no longer part of this rung → not evidence for
     or against it _(proposed)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Narrow restrictions** that set no gestational limit and no exception rule (parental
  notification, waiting periods, clinic rules, reporting) → `adjacent`; BLANK `no-evidence` when
  nothing else survives.
- **Medication-abortion rules** (who may prescribe, by mail or in person) → `adjacent` _(proposed)_.
- **Fetal-personhood measures** that define life from conception but state no ban or exception rule
  → `direction-only` _(proposed)_.
- **Preemption (codebook V2, H12)** → `adjacent`.
- **Budget and omnibus votes** with an abortion item → V4 `multi-subject`.


## Sources

---
snapshot_id: a1f7f6da-7040-52df-9ff7-b41e976cedc8
source_kind: own-site (the person's own site or account)
url: https://houchin.house.gov/media/press-releases/rep-erin-houchin-introduces-abortion-funding-awareness-act

Rep. Erin Houchin Introduces the Abortion Funding Awareness Act | Congresswoman Erin Houchin Skip to main content 342 Cannon House Office Building, Washington, DC 20515 Email Me (202) 225-5315 About Committees and Caucuses Our District Votes and Legislation Contact Newsletter Subscribe Office Locations Media Press Releases Issues Agriculture Economy Education Energy Health Veterans Border Security Services Art Competition Congressional App Challenge Congressional Commendations Flags Grant Applicants Help with a Federal Agency Internships Service Academy Nominations Tours and Tickets America 250 Attention Seniors - Fraud Alert! Casework Success Stories Community Project Funding Help for Veterans Subscribe X How Can I Help? Home Media Press Releases Rep. Erin Houchin Introduces the Abortion Funding Awareness Act April 29, 2025 Press Release WASHINGTON, D.C. – Congresswoman Erin Houchin (IN-09) has introduced the Abortion Funding Awareness Act, companion legislation to the Senate bill led by Senator Jim Banks (R-IN). This legislation brings long-overdue transparency to how states are using Medicaid funds in connection with abortion providers like Planned Parenthood. This legislation ensures that American taxpayers are not unknowingly footing the bill for abortion-related services and holds state governments accountable for how federal funds are spent. “The Abortion Funding Awareness Act exposes how states are funneling tax dollars to abortion providers,” said Congresswoman Erin Houchin. “For too long, the left has used loopholes and a lack of transparency to prop up Planned Parenthood and others who profit from taking innocent lives. This bill says enough is enough.” Despite federal restrictions on direct abortion funding, states have been quietly steering taxpayer-funded Medicaid dollars to abortion providers under the radar. The Abortion Funding Awareness Act seeks to stop that by requiring states to report all Medicaid payments made to abortion providers, submit annual reports detailing those transactions, and publish this information on their official state websites for the public to see. “This legislation provides the transparency and accountability the American people deserve. I remain committed to defending rights of conscience and the integrity of taxpayer dollars,” said Houchin. Office Locations Washington DC Office 342 Cannon House Office Building Washington, DC 20515 Phone: (202) 225-5315 Salem District Office 104 W Hackberry Street Salem, IN 47167 Phone: (812) 288-3999 Top Copyright Privacy House.gov Accessibility RSS

---
snapshot_id: 149ab2b0-f8ff-5e6f-813e-642e00caadbb
source_kind: public-record
url: https://www.congress.gov/bill/118th-congress/house-bill/26

Born-Alive Abortion Survivors Protection Act Policy area: Crime and Law Enforcement Sponsor: Rep. Wagner, Ann [R-MO-2] Latest action: Read the second time. Placed on Senate Legislative Calendar under General Orders. Calendar No. 2. Born-Alive Abortion Survivors Protection Act This bill establishes requirements for the degree of care a health care practitioner must provide in the case of a child born alive following an abortion or attempted abortion. Specifically, a health care practitioner who is present must (1) exercise the same degree of care as would reasonably be provided to any other child born alive at the same gestational age, and (2) ensure the child is immediately admitted to a hospital. Additionally, a health care practitioner or other employee who has knowledge of a failure to comply with the degree-of-care requirements must immediately report such failure to law enforcement. A health care practitioner who fails to provide the required degree of care, or a health care practitioner or other employee who fails to report such failure, is subject to criminal penalties—a fine, up to five years in prison, or both. An individual who intentionally kills or attempts to kill a child born alive is subject to prosecution for murder. The bill bars the criminal prosecution of a mother of a child born alive under this bill and allows her to bring a civil action against a health care practitioner or other employee for violations. Born-Alive Abortion Survivors Protection Act This bill establishes requirements for the degree of care a health care practitioner must provide in the case of a child born alive following an abortion or attempted abortion. Specifically, a health care practitioner who is present must (1) exercise the same degree of care as would reasonably be provided to any other child born alive at the same gestational age, and (2) ensure the child is immediately admitted to a hospital. Additionally, a health care practitioner or other employee who has knowledge of a failure to comply with the degree-of-care requirements must immediately report such failure to law enforcement. A health care practitioner who fails to provide the required degree of care, or a health care practitioner or other employee who fails to report such failure, is subject to criminal penalties—a fine, up to five years in prison, or both. An individual who intentionally kills or attempts to kill a child born alive is subject to prosecution for murder. The bill bars the criminal prosecution of a mother of a child born alive under this bill and allows her to bring a civil action against a health care practitioner or other employee for violations. Cosponsors: Rep. Scalise, Steve [R-LA-1], Rep. Cammack, Kat [R-FL-3], Rep. Stefanik, Elise M. [R-NY-21], Rep. Fischbach, Michelle [R-MN-7], Rep. Hinson, Ashley [R-IA-2], Rep. Salazar, Maria Elvira [R-FL-27], Rep. Malliotakis, Nicole [R-NY-11], Rep. Harshbarger, Diana [R-TN-1], Rep. Letlow, Julia [R-LA-5], Rep. Van Duyne, Beth [R-TX-24], Rep. Miller, Carol D. [R-WV-1], Rep. McClain, Lisa C. [R-MI-9], Rep. Tenney, Claudia [R-NY-24], Rep. Crenshaw, Dan [R-TX-2], Rep. Rogers, Mike D. [R-AL-3], Rep. Cole, Tom [R-OK-4], Rep. Wittman, Robert J. [R-VA-1], Rep. Grothman, Glenn [R-WI-6], Rep. Aderholt, Robert B. [R-AL-4], Rep. Duncan, Jeff [R-SC-3], Rep. Thompson, Glenn [R-PA-15], Rep. Feenstra, Randy [R-IA-4], Rep. Sessions, Pete [R-TX-17], Rep. McClintock, Tom [R-CA-5], Rep. Bost, Mike [R-IL-12], Rep. Carl, Jerry L. [R-AL-1], Rep. Rutherford, John H. [R-FL-5], Rep. Gimenez, Carlos A. [R-FL-28], Rep. Finstad, Brad [R-MN-1], Rep. Pfluger, August [R-TX-11], Rep. Tiffany, Thomas P. [R-WI-7], Rep. Palmer, Gary J. [R-AL-6], Rep. Gonzales, Tony [R-TX-23], Rep. Reschenthaler, Guy [R-PA-14], Rep. LaTurner, Jake [R-KS-2], Rep. Bergman, Jack [R-MI-1], Rep. Jackson, Ronny [R-TX-13], Rep. Joyce, John [R-PA-13], Rep. Meuser, Daniel [R-PA-9], Rep. Mooney, Alexander X. [R-WV-2], Rep. Houchin, Erin [R-IN-9], Rep. Diaz-Balart, Mario [R-FL-26], Rep. Buck, Ken [R-CO-4], Rep. Fulcher, Russ [R-ID-1], Rep. Hudson, Richard [R-NC-9], Rep. Murphy, Gregory [R-NC-3], Rep. Wenstrup, Brad R. [R-OH-2], Rep. Barr, Andy [R-KY-6], Rep. Guthrie, Brett [R-KY-2], Rep. LaHood, Darin [R-IL-16], Rep. Biggs, Andy [R-AZ-5], Rep. Buchanan, Vern [R-FL-16], Rep. Strong, Dale W. [R-AL-5], Rep. Bishop, Dan [R-NC-8], Rep. Bucshon, Larry [R-IN-8], Rep. Burchett, Tim [R-TN-2], Rep. Fleischmann, Charles J. "Chuck" [R-TN-3], Rep. Allen, Rick W. [R-GA-12], Rep. Smith, Adrian [R-NE-3], Rep. Posey, Bill [R-FL-8], Rep. Gooden, Lance [R-TX-5], Rep. Mann, Tracey [R-KS-1], Rep. Guest, Michael [R-MS-3], Rep. Clyde, Andrew S. [R-GA-9], Rep. Moore, Blake D. [R-UT-1], Rep. Kustoff, David [R-TN-8], Rep. Green, Mark E. [R-TN-7], Rep. Webster, Daniel [R-FL-11], Rep. Newhouse, Dan [R-WA-4], Rep. Cloud, Michael [R-TX-27], Rep. Johnson, Mike [R-LA-4], Rep. Stauber, Pete [R-MN-8], Rep. Self, Keith [R-TX-3], Rep. Smith, Christopher H. [R-NJ-4], Rep. Mast, Brian J. [R-FL-21], Rep. Higgins, Clay [R-LA-3], Rep. Cline, Ben [R-VA-6], Rep. Ellzey, Jake [R-TX-6], Rep. Scott, Austin [R-GA-8], Rep. Johnson, Bill [R-OH-6], Rep. Moolenaar, John R. [R-MI-2], Rep. Timmons, William R. IV [R-SC-4], Rep. Latta, Robert E. [R-OH-5], Rep. Smith, Jason [R-MO-8], Rep. Arrington, Jodey C. [R-TX-19], Rep. Lesko, Debbie [R-AZ-8], Rep. Huizenga, Bill [R-MI-4], Rep. Graves, Garret [R-LA-6], Rep. Perry, Scott [R-PA-10], Rep. Balderson, Troy [R-OH-12], Rep. Greene, Marjorie Taylor [R-GA-14], Rep. Pence, Greg [R-IN-6], Rep. Burgess, Michael C. [R-TX-26], Rep. Womack, Steve [R-AR-3], Rep. Good, Bob [R-VA-5], Rep. Van Drew, Jefferson [R-NJ-2], Rep. Estes, Ron [R-KS-4], Rep. Smucker, Lloyd [R-PA-11], Rep. Davidson, Warren [R-OH-8], Rep. Fitzgerald, Scott [R-WI-5], Rep. Bilirakis, Gus M. [R-FL-12], Rep. Banks, Jim [R-IN-3], Rep. Hern, Kevin [R-OK-1], Rep. Weber, Randy K., Sr. [R-TX-14], Rep. Waltz, Michael [R-FL-6], Rep. Kelly, Mike [R-PA-16], Rep. Carter, Earl L. "Buddy" [R-GA-1], Rep. Babin, Brian [R-TX-36], Rep. Issa, Darrell E. [R-CA-48], Rep. Rose, John W. [R-TN-6], Rep. Luetkemeyer, Blaine [R-MO-3], Rep. Gallagher, Mike [R-WI-8], Rep. Schweikert, David [R-AZ-1], Rep. Valadao, David G. [R-CA-22], Rep. Walberg, Tim [R-MI-5], Rep. Fallon, Pat [R-TX-4], Rep. Curtis, John R. [R-UT-3], Rep. Joyce, David P. [R-OH-14], Rep. Bice, Stephanie I. [R-OK-5], Rep. Ferguson, A. Drew, IV [R-GA-3], Rep. Gaetz, Matt [R-FL-1], Rep. Simpson, Michael K. [R-ID-2], Rep. Harris, Andy [R-MD-1], Rep. Amodei, Mark E. [R-NV-2], Rep. Lucas, Frank D. [R-OK-3], Rep. Kim, Young [R-CA-40], Rep. Foxx, Virginia [R-NC-5], Rep. Calvert, Ken [R-CA-41], Rep. Wilson, Joe [R-SC-2], Rep. Ezell, Mike [R-MS-4], Rep. Langworthy, Nicholas A. [R-NY-23], Rep. Fry, Russell [R-SC-7], Rep. Williams, Roger [R-TX-25], Rep. Armstrong, Kelly [R-ND-At Large], Rep. Miller, Mary E. [R-IL-15], Rep. Steube, W. Gregory [R-FL-17], Rep. Graves, Sam [R-MO-6], Rep. Rosendale Sr., Matthew M. [R-MT-2], Rep. Garbarino, Andrew R. [R-NY-2], Rep. Bacon, Don [R-NE-2], Rep. Spartz, Victoria [R-IN-5], Rep. Westerman, Bruce [R-AR-4], Rep. McHenry, Patrick T. [R-NC-10], Rep. Mace, Nancy [R-SC-1], Rep. Moore, Barry [R-AL-2], Rep. Boebert, Lauren [R-CO-3], Rep. Brecheen, Josh [R-OK-2], Rep. Turner, Michael R. [R-OH-10], Rep. Comer, James [R-KY-1], Rep. Burlison, Eric [R-MO-7], Rep. Hunt, Wesley [R-TX-38], Rep. Rouzer, David [R-NC-7], Rep. Hill, J. French [R-AR-2], Rep. Alford, Mark [R-MO-4], Rep. Moran, Nathaniel [R-TX-1], Rep. Van Orden, Derrick [R-WI-3], Rep. Owens, Burgess [R-UT-4], Rep. Yakym, Rudy [R-IN-2], Rep. McMorris Rodgers, Cathy [R-WA-5], Rep. Franklin, C. Scott [R-FL-18], Rep. Hageman, Harriet M. [R-WY-At Large], Rep. Norman, Ralph [R-SC-5], Rep. Granger, Kay [R-TX-12], Rep. Kelly, Trent [R-MS-1], Rep. Ogles, Andrew [R-TN-5], Rep. Luttrell, Morgan [R-TX-8] Actions: Read the second time. Placed on Senate Legislative Calendar under General Orders. Calendar No. 2. Received in the Senate. Read the first time. Placed on Senate Legislative Calendar under Read the First Time. Motion to reconsider laid on the table Agreed to without objection. On passage Passed by the Yeas and Nays: 220 - 210, 1 Present (Roll no. 29). (text: CR H178) Passed/agreed to in House: On passage Passed by the Yeas and Nays: 220 - 210, 1 Present (Roll no. 29). (text: CR H178) On motion to recommit Failed by the Yeas and Nays: 212 - 219 (Roll no. 28). Considered as unfinished business. (consideration: CR H190-191) POSTPONED PROCEEDINGS - At the conclusion of debate on H.R. 26, the Chair put the question on passage of the motion to recommit and by voice vote, announced that the nays had prevailed. Ms. DeGette demanded the yeas and nays and the Chair postponed further proceedings until a time to be announced. The previous question on the motion to recommit was ordered pursuant to clause 2(b) of rule XIX. Ms. DeGette moved to recommit to the Committee on the Judiciary. (text: CR H187-190) The previous question was ordered pursuant to the rule. DEBATE - The House proceeded with one hour of debate on H.R. 26. Considered under the provisions of rule H. Res. 5. (consideration: CR H178-190) Referred to the House Committee on the Judiciary. Introduced in House [Congressional Bills 118th Congress] [From the U.S. Government Publishing Office] [H.R. 26 Placed on Calendar Senate (PCS)] <DOC> Calendar No. 2 118th CONGRESS 1st Session H. R. 26 _______________________________________________________________________ IN THE SENATE OF THE UNITED STATES January 23 (legislative day, January 3), 2023 Received; read the first time January 25, 2023 Read the second time and placed on the calendar _______________________________________________________________________ AN ACT To amend title 18, United States Code, to prohibit a health care practitioner from failing to exercise the proper degree of care in the case of a child who survives an abortion or attempted abortion. Be it enacted by the Senate and House of Representatives of the United States of America in Congress assembled, SECTION 1. SHORT TITLE. This Act may be cited as the ``Born-Alive Abortion Survivors Protection Act''. SEC. 2. FINDINGS; CONSTITUTIONAL AUTHORITY. (a) Findings.--Congress finds as follows: (1) If an abortion results in the live birth of an infant, the infant is a legal person for all purposes under the laws of the United States, and entitled to all the protections of such laws. (2) Any infant born alive after an abortion or within a hospital, clinic, or other facility has the same claim to the protection of the law that would arise for any newborn, or for any person who comes to a hospital, clinic, or other facility for screening and treatment or otherwise becomes a patient within its care. (b) Constitutional Authority.--In accordance with the above findings, Congress enacts the following pursuant to Congress' power under-- (1) section 5 of the 14th Amendment, including the power to enforce the prohibition on government action denying equal protection of the laws; and (2) section 8 of article I to make all laws necessary and proper for carrying into execution the powers vested by the Constitution of the United States, including the power to regulate commerce under clause 3 of such section. SEC. 3. BORN-ALIVE INFANTS PROTECTION. (a) Requirements Pertaining to Born-Alive Abortion Survivors.-- Chapter 74 of title 18, United States Code, is amended by inserting after section 1531 the following: ``Sec. 1532. Requirements pertaining to born-alive abortion survivors ``(a) Requirements for Health Care Practitioners.--In the case of an abortion or attempted abortion that results in a child born alive (as defined in section 8 of title 1, United States Code (commonly known as the `Born-Alive Infants Protection Act')): ``(1) Degree of care required; immediate admission to a hospital.--Any health care practitioner present at the time the child is born alive shall-- ``(A) exercise the same degree of professional skill, care, and diligence to preserve the life and health of the child as a reasonably diligent and conscientious health care practitioner would render to any other child born alive at the same gestational age; and ``(B) following the exercise of skill, care, and diligence required under subparagraph (A), ensure that the child born alive is immediately transported and admitted to a hospital. ``(2) Mandatory reporting of violations.--A health care practitioner or any employee of a hospital, a physician's office, or an abortion clinic who has knowledge of a failure to comply with the requirements of paragraph (1) shall immediately report the failure to an appropriate State or Federal law enforcement agency, or to both. ``(b) Penalties.-- ``(1) In general.--Whoever violates subsection (a) shall be fined under this title or imprisoned for not more than 5 years, or both. ``(2) Intentional killing of child born alive.--Whoever intentionally performs or attempts to perform an overt act that kills a child born alive described under subsection (a), shall be punished as under section 1111 of this title for intentionally killing or attempting to kill a human being. ``(c) Bar to Prosecution.--The mother of a child born alive described under subsection (a) may not be prosecuted under this section, for conspiracy to violate this section, or for an offense under section 3 or 4 of this title based on such a violation. ``(d) Civil Remedies.-- ``(1) Civil action by a woman on whom an abortion is performed.--If a child is born alive and there is a violation of subsection (a), the woman upon whom the abortion was performed or attempted may, in a civil action against any person who committed the violation, obtain appropriate relief. ``(2) Appropriate relief.--Appropriate relief in a civil action under this subsection includes-- ``(A) objectively verifiable money damage for all injuries, psychological and physical, occasioned by the violation of subsection (a); ``(B) statutory damages equal to 3 times the cost of the abortion or attempted abortion; and ``(C) punitive damages. ``(3) Attorney's fee for plaintiff.--The court shall award a reasonable attorney's fee to a prevailing plaintiff in a civil action under this subsection. ``(4) Attorney's fee for defendant.--If a defendant in a civil action under this subsection prevails and the court finds that the plaintiff's suit was frivolous, the court shall award a reasonable attorney's fee in favor of the defendant against the plaintiff. ``(e) Definitions.--In this section the following definitions apply: ``(1) Abortion.--The term `abortion' means the use or prescription of any instrument, medicine, drug, or any other substance or device-- ``(A) to intentionally kill the unborn child of a woman known to be pregnant; or ``(B) to intentionally terminate the pregnancy of a woman known to be pregnant, with an intention other than-- ``(i) after viability, to produce a live birth and preserve the life and health of the child born alive; or ``(ii) to remove a dead unborn child. ``(2) Attempt.--The term `attempt', with respect to an abortion, means conduct that, under the circumstances as the actor believes them to be, constitutes a substantial step in a course of conduct planned to culminate in performing an abortion.''. (b) Clerical Amendment.--The table of sections for chapter 74 of title 18, United States Code, is amended by inserting after the item pertaining to section 1531 the following: ``1532. Requirements pertaining to born-alive abortion survivors.''. (c) Chapter Heading Amendments.-- (1) Chapter heading in chapter.--The chapter heading for chapter 74 of title 18, United States Code, is amended by striking ``Partial-Birth Abortions'' and inserting ``Abortions''. (2) Table of chapters for part i.--The item relating to chapter 74 in the table of chapters at the beginning of part I of title 18, United States Code, is amended by striking ``Partial-Birth Abortions'' and inserting ``Abortions''. Passed the House of Representatives January 11, 2023. Attest: CHERYL L. JOHNSON, Clerk. Calendar No. 2 118th CONGRESS 1st Session H. R. 26 _______________________________________________________________________ AN ACT To amend title 18, United States Code, to prohibit a health care practitioner from failing to exercise the proper degree of care in the case of a child who survives an abortion or attempted abortion. _______________________________________________________________________ January 25, 2023 Read the second time and placed on the calendar

---
snapshot_id: 3c6cba5a-7385-5a8f-af9b-2b6df86d8f12
source_kind: public-record
url: https://clerk.house.gov/Votes/202329

Office of the Clerk, U.S. House of Representatives Find Your Representative Search Office of the Clerk Toggle navigation Search Office of the Clerk Search button Legislative Information Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions 119th Congress, 2nd Session House Not In Session Next Session: October 9th, 2026 at 12:30 PM House Floor Proceedings Watch live.house.gov Additional Resources Votes Legacy View - 2024 119th Congress Nominees Statistics of the 2024 Congressional Election Final House Calendar (118th Congress) Résumé of Congressional Activity Legislative Search Congressional Record U.S. Senate House Schedule Bills This Week House Voting Days Member Information Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Republicans 218 218 Democrats 214 214 Independents 1 1 Vacancies 2 2 Republican Leadership Rep. Mike Johnson Speaker of the House Rep. Steve Scalise Majority Leader Rep. Tom Emmer Majority Whip Rep. Lisa C. McClain Republican Conference Chair Rep. Jay Obernolte Republican Policy Committee Chair Democratic Leadership Rep. Hakeem S. Jeffries Minority Leader Rep. Katherine M. Clark Minority Whip Rep. Pete Aguilar Democratic Caucus Chair Rep. Ted Lieu Democratic Caucus Vice Chair Additional Resources Find Your Representative Official List of Members by State Official Member Telephone Directory Duplicate and Similar Names of Members Terms of Service Mailing Labels [ MS Word | Text File ] Member Data [ Excel | XML | User Guide ] Biographical Directory Members on Congress.gov Committee Information COMMITTEE INFORMATION COMMITTEE PROFILES Agriculture Appropriations Armed Services Budget Education and Workforce Energy and Commerce Ethics Financial Services Foreign Affairs Homeland Security House Administration Judiciary Natural Resources Oversight and Government Reform Rules Science, Space, and Technology Small Business Transportation and Infrastructure Veterans' Affairs Ways and Means Select Intelligence Select Strategic Competition Joint Economic Joint Library Joint Printing Joint Taxation Additional Resources Official List of Members with Committee Assignments Official List of Standing Committees and Subcommittees Committee Repository Committee Reports Committees on Congress.gov Committee Data [ Excel ] Disclosures Disclosures PUBLIC DISCLOSURE Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications Additional Resources Lobbying Disclosures Public Laws Lobbying Disclosure Act About the Clerk About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office The Clerk of the House The Honorable Kevin F. McCumber Clerk of the U.S. House of Representatives Deputy Clerk Michelle H. Reinshuttle Deputy Clerk Contact Information Mailing Address U.S. Capitol Room H154 Washington, DC 20515&ndash;6601 Telephone Number (202) 225&ndash;7000 Office Hours 9:00 AM&ndash;6:00 PM, Monday&ndash;Friday Additional Resources Artificial Intelligence Use Case Inventory [ USHouse-Clerk-1: Comparative Print Suite ] 119th Congress, 2nd Session Back to Previous Page Roll Call 29 | Bill Number: H. R. 26 Share XML View | HTML View Jan 11, 2023, 04:29 PM | 118th Congress, 1st Session Vote Question: On Passage Born-Alive Abortion Survivors Protection Act Vote Type: Yea-And-Nay Status: Passed VOTES yea: 220 nay: 210 present: 1 not voting: 3 Remote Voting by Proxy Votes by party votes by party Party Yeas Nays Present Not Voting Republican 219 0 0 3 Democratic 1 210 1 0 Independent 0 0 0 0 Total 220 210 1 3 All votes Keyword Name Party All Parties Republican Democratic Independent State All States Votes All Votes YEA/AYE NAY/NO PRESENT NOT VOTING All votes Representative Party State Vote Adams Adams Democratic North Carolina NC Nay Aderholt Aderholt Republican Alabama AL Yea Aguilar Aguilar Democratic California CA Nay Alford Alford Republican Missouri MO Yea Allen Allen Republican Georgia GA Yea Allred Allred Democratic Texas TX Nay Amodei Amodei Republican Nevada NV Yea Armstrong Armstrong Republican North Dakota ND Yea Arrington Arrington Republican Texas TX Yea Auchincloss Auchincloss Democratic Massachusetts MA Nay Babin Babin Republican Texas TX Yea Bacon Bacon Republican Nebraska NE Yea Baird Baird Republican Indiana IN Yea Balderson Balderson Republican Ohio OH Yea Balint Balint Democratic Vermont VT Nay Banks Banks Republican Indiana IN Yea Barr Barr Republican Kentucky KY Yea Barragán Barragan Democratic California CA Nay Bean (FL) Bean (FL) Republican Florida FL Yea Beatty Beatty Democratic Ohio OH Nay Bentz Bentz Republican Oregon OR Yea Bera Bera Democratic California CA Nay Bergman Bergman Republican Michigan MI Yea Beyer Beyer Democratic Virginia VA Nay Bice Bice Republican Oklahoma OK Yea Biggs Biggs Republican Arizona AZ Yea Bilirakis Bilirakis Republican Florida FL Yea Bishop (GA) Bishop (GA) Democratic Georgia GA Nay Bishop (NC) Bishop (NC) Republican North Carolina NC Yea Blumenauer Blumenauer Democratic Oregon OR Nay Blunt Rochester Blunt Rochester Democratic Delaware DE Nay Boebert Boebert Republican Colorado CO Yea Bonamici Bonamici Democratic Oregon OR Nay Bost Bost Republican Illinois IL Yea Bowman Bowman Democratic New York NY Nay Boyle (PA) Boyle (PA) Democratic Pennsylvania PA Nay Brecheen Brecheen Republican Oklahoma OK Yea Brown Brown Democratic Ohio OH Nay Brownley Brownley Democratic California CA Nay Buchanan Buchanan Republican Florida FL Not Voting Buck Buck Republican Colorado CO Yea Bucshon Bucshon Republican Indiana IN Yea Budzinski Budzinski Democratic Illinois IL Nay Burchett Burchett Republican Tennessee TN Yea Burgess Burgess Republican Texas TX Yea Burlison Burlison Republican Missouri MO Yea Bush Bush Democratic Missouri MO Nay Calvert Calvert Republican California CA Yea Cammack Cammack Republican Florida FL Yea Caraveo Caraveo Democratic Colorado CO Nay Carbajal Carbajal Democratic California CA Nay Cárdenas Cardenas Democratic California CA Nay Carey Carey Republican Ohio OH Yea Carl Carl Republican Alabama AL Yea Carson Carson Democratic Indiana IN Nay Carter (GA) Carter (GA) Republican Georgia GA Yea Carter (LA) Carter (LA) Democratic Louisiana LA Nay Carter (TX) Carter (TX) Republican Texas TX Yea Cartwright Cartwright Democratic Pennsylvania PA Nay Casar Casar Democratic Texas TX Nay Case Case Democratic Hawaii HI Nay Casten Casten Democratic Illinois IL Nay Castor (FL) Castor (FL) Democratic Florida FL Nay Castro (TX) Castro (TX) Democratic Texas TX Nay Chavez-DeRemer Chavez-DeRemer Republican Oregon OR Yea Cherfilus-McCormick Cherfilus-McCormick Democratic Florida FL Nay Chu Chu Democratic California CA Nay Cicilline Cicilline Democratic Rhode Island RI Nay Ciscomani Ciscomani Republican Arizona AZ Yea Clark (MA) Clark (MA) Democratic Massachusetts MA Nay Clarke (NY) Clarke (NY) Democratic New York NY Nay Cleaver Cleaver Democratic Missouri MO Nay Cline Cline Republican Virginia VA Yea Cloud Cloud Republican Texas TX Yea Clyburn Clyburn Democratic South Carolina SC Nay Clyde Clyde Republican Georgia GA Yea Cohen Cohen Democratic Tennessee TN Nay Cole Cole Republican Oklahoma OK Yea Collins Collins Republican Georgia GA Yea Comer Comer Republican Kentucky KY Yea Connolly Connolly Democratic Virginia VA Nay Correa Correa Democratic California CA Nay Costa Costa Democratic California CA Nay Courtney Courtney Democratic Connecticut CT Nay Craig Craig Democratic Minnesota MN Nay Crane Crane Republican Arizona AZ Yea Crawford Crawford Republican Arkansas AR Yea Crenshaw Crenshaw Republican Texas TX Yea Crockett Crockett Democratic Texas TX Nay Crow Crow Democratic Colorado CO Nay Cuellar Cuellar Democratic Texas TX Yea Curtis Curtis Republican Utah UT Yea D'Esposito D'Esposito Republican New York NY Yea Davids (KS) Davids (KS) Democratic Kansas KS Nay Davidson Davidson Republican Ohio OH Yea Davis (IL) Davis (IL) Democratic Illinois IL Nay Davis (NC) Davis (NC) Democratic North Carolina NC Nay De La Cruz De La Cruz Republican Texas TX Yea Dean (PA) Dean (PA) Democratic Pennsylvania PA Nay DeGette DeGette Democratic Colorado CO Nay DeLauro DeLauro Democratic Connecticut CT Nay DelBene DelBene Democratic Washington WA Nay Deluzio Deluzio Democratic Pennsylvania PA Nay DeSaulnier DeSaulnier Democratic California CA Nay DesJarlais DesJarlais Republican Tennessee TN Yea Diaz-Balart Diaz-Balart Republican Florida FL Yea Dingell Dingell Democratic Michigan MI Nay Doggett Doggett Democratic Texas TX Nay Donalds Donalds Republican Florida FL Yea Duarte Duarte Republican California CA Yea Duncan Duncan Republican South Carolina SC Yea Dunn (FL) Dunn (FL) Republican Florida FL Yea Edwards Edwards Republican North Carolina NC Yea Ellzey Ellzey Republican Texas TX Yea Emmer Emmer Republican Minnesota MN Yea Escobar Escobar Democratic Texas TX Nay Eshoo Eshoo Democratic California CA Nay Espaillat Espaillat Democratic New York NY Nay Estes Estes Republican Kansas KS Yea Evans Evans Democratic Pennsylvania PA Nay Ezell Ezell Republican Mississippi MS Yea Fallon Fallon Republican Texas TX Yea Feenstra Feenstra Republican Iowa IA Yea Ferguson Ferguson Republican Georgia GA Yea Finstad Finstad Republican Minnesota MN Yea Fischbach Fischbach Republican Minnesota MN Yea Fitzgerald Fitzgerald Republican Wisconsin WI Yea Fitzpatrick Fitzpatrick Republican Pennsylvania PA Yea Fleischmann Fleischmann Republican Tennessee TN Yea Fletcher Fletcher Democratic Texas TX Nay Flood Flood Republican Nebraska NE Yea Foster Foster Democratic Illinois IL Nay Foushee Foushee Democratic North Carolina NC Nay Foxx Foxx Republican North Carolina NC Yea Frankel, Lois Frankel, Lois Democratic Florida FL Nay Franklin, C. Scott Franklin, C. Scott Republican Florida FL Yea Frost Frost Democratic Florida FL Nay Fry Fry Republican South Carolina SC Yea Fulcher Fulcher Republican Idaho ID Yea Gaetz Gaetz Republican Florida FL Yea Gallagher Gallagher Republican Wisconsin WI Yea Gallego Gallego Democratic Arizona AZ Nay Garamendi Garamendi Democratic California CA Nay Garbarino Garbarino Republican New York NY Yea García (IL) Garcia (IL) Democratic Illinois IL Nay Garcia (TX) Garcia (TX) Democratic Texas TX Nay Garcia, Mike Garcia, Mike Republican California CA Yea Garcia, Robert Garcia, Robert Democratic California CA Nay Gimenez Gimenez Republican Florida FL Yea Golden (ME) Golden (ME) Democratic Maine ME Nay Goldman (NY) Goldman (NY) Democratic New York NY Nay Gomez Gomez Democratic California CA Nay Gonzales, Tony Gonzales, Tony Republican Texas TX Yea Gonzalez, Vicente Gonzalez, Vicente Democratic Texas TX Present Good (VA) Good (VA) Republican Virginia VA Yea Gooden (TX) Gooden (TX) Republican Texas TX Yea Gosar Gosar Republican Arizona AZ Yea Gottheimer Gottheimer Democratic New Jersey NJ Nay Granger Granger Republican Texas TX Yea Graves (LA) Graves (LA) Republican Louisiana LA Yea Graves (MO) Graves (MO) Republican Missouri MO Yea Green (TN) Green (TN) Republican Tennessee TN Yea Green (TX) Green (TX) Democratic Texas TX Nay Greene (GA) Greene (GA) Republican Georgia GA Yea Griffith Griffith Republican Virginia VA Yea Grijalva Grijalva Democratic Arizona AZ Nay Grothman Grothman Republican Wisconsin WI Yea Guest Guest Republican Mississippi MS Yea Guthrie Guthrie Republican Kentucky KY Yea Hageman Hageman Republican Wyoming WY Yea Harder (CA) Harder (CA) Democratic California CA Nay Harris Harris Republican Maryland MD Yea Harshbarger Harshbarger Republican Tennessee TN Yea Hayes Hayes Democratic Connecticut CT Nay Hern Hern Republican Oklahoma OK Yea Higgins (LA) Higgins (LA) Republican Louisiana LA Yea Higgins (NY) Higgins (NY) Democratic New York NY Nay Hill Hill Republican Arkansas AR Yea Himes Himes Democratic Connecticut CT Nay Hinson Hinson Republican Iowa IA Yea Horsford Horsford Democratic Nevada NV Nay Houchin Houchin Republican Indiana IN Yea Houlahan Houlahan Democratic Pennsylvania PA Nay Hoyer Hoyer Democratic Maryland MD Nay Hoyle (OR) Hoyle (OR) Democratic Oregon OR Nay Hudson Hudson Republican North Carolina NC Yea Huffman Huffman Democratic California CA Nay Huizenga Huizenga Republican Michigan MI Yea Hunt Hunt Republican Texas TX Not Voting Issa Issa Republican California CA Yea Ivey Ivey Democratic Maryland MD Nay Jackson (IL) Jackson (IL) Democratic Illinois IL Nay Jackson (NC) Jackson (NC) Democratic North Carolina NC Nay Jackson (TX) Jackson (TX) Republican Texas TX Yea Jackson Lee Jackson Lee Democratic Texas TX Nay Jacobs Jacobs Democratic California CA Nay James James Republican Michigan MI Yea Jayapal Jayapal Democratic Washington WA Nay Jeffries Jeffries Democratic New York NY Nay Johnson (GA) Johnson (GA) Democratic Georgia GA Nay Johnson (LA) Johnson (LA) Republican Louisiana LA Yea Johnson (OH) Johnson (OH) Republican Ohio OH Yea Johnson (SD) Johnson (SD) Republican South Dakota SD Yea Jordan Jordan Republican Ohio OH Yea Joyce (OH) Joyce (OH) Republican Ohio OH Yea Joyce (PA) Joyce (PA) Republican Pennsylvania PA Yea Kamlager-Dove Kamlager-Dove Democratic California CA Nay Kaptur Kaptur Democratic Ohio OH Nay Kean (NJ) Kean (NJ) Republican New Jersey NJ Yea Keating Keating Democratic Massachusetts MA Nay Kelly (IL) Kelly (IL) Democratic Illinois IL Nay Kelly (MS) Kelly (MS) Republican Mississippi MS Yea Kelly (PA) Kelly (PA) Republican Pennsylvania PA Yea Khanna Khanna Democratic California CA Nay Kiggans (VA) Kiggans (VA) Republican Virginia VA Yea Kildee Kildee Democratic Michigan MI Nay Kiley Kiley Republican California CA Yea Kilmer Kilmer Democratic Washington WA Nay Kim (CA) Kim (CA) Republican California CA Yea Kim (NJ) Kim (NJ) Democratic New Jersey NJ Nay Krishnamoorthi Krishnamoorthi Democratic Illinois IL Nay Kuster Kuster Democratic New Hampshire NH Nay Kustoff Kustoff Republican Tennessee TN Yea LaHood LaHood Republican Illinois IL Yea LaLota LaLota Republican New York NY Yea LaMalfa LaMalfa Republican California CA Yea Lamborn Lamborn Republican Colorado CO Yea Landsman Landsman Democratic Ohio OH Nay Langworthy Langworthy Republican New York NY Yea Larsen (WA) Larsen (WA) Democratic Washington WA Nay Larson (CT) Larson (CT) Democratic Connecticut CT Nay Latta Latta Republican Ohio OH Yea LaTurner LaTurner Republican Kansas KS Yea Lawler Lawler Republican New York NY Yea Lee (CA) Lee (CA) Democratic California CA Nay Lee (FL) Lee (FL) Republican Florida FL Yea Lee (NV) Lee (NV) Democratic Nevada NV Nay Lee (PA) Lee (PA) Democratic Pennsylvania PA Nay Leger Fernandez Leger Fernandez Democratic New Mexico NM Nay Lesko Lesko Republican Arizona AZ Yea Letlow Letlow Republican Louisiana LA Yea Levin Levin Democratic California CA Nay Lieu Lieu Democratic California CA Nay Lofgren Lofgren Democratic California CA Nay Loudermilk Loudermilk Republican Georgia GA Yea Lucas Lucas Republican Oklahoma OK Yea Luetkemeyer Luetkemeyer Republican Missouri MO Yea Luna Luna Republican Florida FL Yea Luttrell Luttrell Republican Texas TX Yea Lynch Lynch Democratic Massachusetts MA Nay Mace Mace Republican South Carolina SC Yea Magaziner Magaziner Democratic Rhode Island RI Nay Malliotakis Malliotakis Republican New York NY Yea Mann Mann Republican Kansas KS Yea Manning Manning Democratic North Carolina NC Nay Massie Massie Republican Kentucky KY Yea Mast Mast Republican Florida FL Yea Matsui Matsui Democratic California CA Nay McBath McBath Democratic Georgia GA Nay McCarthy McCarthy Republican California CA Yea McCaul McCaul Republican Texas TX Yea McClain McClain Republican Michigan MI Yea McClintock McClintock Republican California CA Yea McCollum McCollum Democratic Minnesota MN Nay McCormick McCormick Republican Georgia GA Yea McGarvey McGarvey Democratic Kentucky KY Nay McGovern McGovern Democratic Massachusetts MA Nay McHenry McHenry Republican North Carolina NC Yea Meeks Meeks Democratic New York NY Nay Menendez Menendez Democratic New Jersey NJ Nay Meng Meng Democratic New York NY Nay Meuser Meuser Republican Pennsylvania PA Yea Mfume Mfume Democratic Maryland MD Nay Miller (IL) Miller (IL) Republican Illinois IL Yea Miller (OH) Miller (OH) Republican Ohio OH Yea Miller (WV) Miller (WV) Republican West Virginia WV Yea Miller-Meeks Miller-Meeks Republican Iowa IA Yea Mills Mills Republican Florida FL Yea Molinaro Molinaro Republican New York NY Yea Moolenaar Moolenaar Republican Michigan MI Yea Mooney Mooney Republican West Virginia WV Yea Moore (AL) Moore (AL) Republican Alabama AL Yea Moore (UT) Moore (UT) Republican Utah UT Yea Moore (WI) Moore (WI) Democratic Wisconsin WI Nay Moran Moran Republican Texas TX Yea Morelle Morelle Democratic New York NY Nay Moskowitz Moskowitz Democratic Florida FL Nay Moulton Moulton Democratic Massachusetts MA Nay Mrvan Mrvan Democratic Indiana IN Nay Mullin Mullin Democratic California CA Nay Murphy Murphy Republican North Carolina NC Yea Nadler Nadler Democratic New York NY Nay Napolitano Napolitano Democratic California CA Nay Neal Neal Democratic Massachusetts MA Nay Neguse Neguse Democratic Colorado CO Nay Nehls Nehls Republican Texas TX Yea Newhouse Newhouse Republican Washington WA Yea Nickel Nickel Democratic North Carolina NC Nay Norcross Norcross Democratic New Jersey NJ Nay Norman Norman Republican South Carolina SC Yea Nunn (IA) Nunn (IA) Republican Iowa IA Yea Obernolte Obernolte Republican California CA Yea Ocasio-Cortez Ocasio-Cortez Democratic New York NY Nay Ogles Ogles Republican Tennessee TN Yea Omar Omar Democratic Minnesota MN Nay Owens Owens Republican Utah UT Yea Pallone Pallone Democratic New Jersey NJ Nay Palmer Palmer Republican Alabama AL Yea Panetta Panetta Democratic California CA Nay Pappas Pappas Democratic New Hampshire NH Nay Pascrell Pascrell Democratic New Jersey NJ Nay Payne Payne Democratic New Jersey NJ Nay Pelosi Pelosi Democratic California CA Nay Peltola Peltola Democratic Alaska AK Nay Pence Pence Republican Indiana IN Yea Perez Perez Democratic Washington WA Nay Perry Perry Republican Pennsylvania PA Yea Peters Peters Democratic California CA Nay Pettersen Pettersen Democratic Colorado CO Nay Pfluger Pfluger Republican Texas TX Yea Phillips Phillips Democratic Minnesota MN Nay Pingree Pingree Democratic Maine ME Nay Pocan Pocan Democratic Wisconsin WI Nay Porter Porter Democratic California CA Nay Posey Posey Republican Florida FL Yea Pressley Pressley Democratic Massachusetts MA Nay Quigley Quigley Democratic Illinois IL Nay Ramirez Ramirez Democratic Illinois IL Nay Raskin Raskin Democratic Maryland MD Nay Reschenthaler Reschenthaler Republican Pennsylvania PA Yea Rodgers (WA) Rodgers (WA) Republican Washington WA Yea Rogers (AL) Rogers (AL) Republican Alabama AL Yea Rogers (KY) Rogers (KY) Republican Kentucky KY Yea Rose Rose Republican Tennessee TN Yea Rosendale Rosendale Republican Montana MT Yea Ross Ross Democratic North Carolina NC Nay Rouzer Rouzer Republican North Carolina NC Yea Roy Roy Republican Texas TX Yea Ruiz Ruiz Democratic California CA Nay Ruppersberger Ruppersberger Democratic Maryland MD Nay Rutherford Rutherford Republican Florida FL Yea Ryan Ryan Democratic New York NY Nay Salazar Salazar Republican Florida FL Yea Salinas Salinas Democratic Oregon OR Nay Sánchez Sanchez Democratic California CA Nay Santos Santos Republican New York NY Yea Sarbanes Sarbanes Democratic Maryland MD Nay Scalise Scalise Republican Louisiana LA Yea Scanlon Scanlon Democratic Pennsylvania PA Nay Schakowsky Schakowsky Democratic Illinois IL Nay Schiff Schiff Democratic California CA Nay Schneider Schneider Democratic Illinois IL Nay Scholten Scholten Democratic Michigan MI Nay Schrier Schrier Democratic Washington WA Nay Schweikert Schweikert Republican Arizona AZ Yea Scott (VA) Scott (VA) Democratic Virginia VA Nay Scott, Austin Scott, Austin Republican Georgia GA Yea Scott, David Scott, David Democratic Georgia GA Nay Self Self Republican Texas TX Yea Sessions Sessions Republican Texas TX Yea Sewell Sewell Democratic Alabama AL Nay Sherman Sherman Democratic California CA Nay Sherrill Sherrill Democratic New Jersey NJ Nay Simpson Simpson Republican Idaho ID Yea Slotkin Slotkin Democratic Michigan MI Nay Smith (MO) Smith (MO) Republican Missouri MO Yea Smith (NE) Smith (NE) Republican Nebraska NE Yea Smith (NJ) Smith (NJ) Republican New Jersey NJ Yea Smith (WA) Smith (WA) Democratic Washington WA Nay Smucker Smucker Republican Pennsylvania PA Yea Sorensen Sorensen Democratic Illinois IL Nay Soto Soto Democratic Florida FL Nay Spanberger Spanberger Democratic Virginia VA Nay Spartz Spartz Republican Indiana IN Yea Stansbury Stansbury Democratic New Mexico NM Nay Stanton Stanton Democratic Arizona AZ Nay Stauber Stauber Republican Minnesota MN Yea Steel Steel Republican California CA Yea Stefanik Stefanik Republican New York NY Yea Steil Steil Republican Wisconsin WI Yea Steube Steube Republican Florida FL Yea Stevens Stevens Democratic Michigan MI Nay Stewart Stewart Republican Utah UT Yea Strickland Strickland Democratic Washington WA Nay Strong Strong Republican Alabama AL Yea Swalwell Swalwell Democratic California CA Nay Sykes Sykes Democratic Ohio OH Nay Takano Takano Democratic California CA Nay Tenney Tenney Republican New York NY Yea Thanedar Thanedar Democratic Michigan MI Nay Thompson (CA) Thompson (CA) Democratic California CA Nay Thompson (MS) Thompson (MS) Democratic Mississippi MS Nay Thompson (PA) Thompson (PA) Republican Pennsylvania PA Yea Tiffany Tiffany Republican Wisconsin WI Yea Timmons Timmons Republican South Carolina SC Yea Titus Titus Democratic Nevada NV Nay Tlaib Tlaib Democratic Michigan MI Nay Tokuda Tokuda Democratic Hawaii HI Nay Tonko Tonko Democratic New York NY Nay Torres (CA) Torres (CA) Democratic California CA Nay Torres (NY) Torres (NY) Democratic New York NY Nay Trahan Trahan Democratic Massachusetts MA Nay Trone Trone Democratic Maryland MD Nay Turner Turner Republican Ohio OH Yea Underwood Underwood Democratic Illinois IL Nay Valadao Valadao Republican California CA Yea Van Drew Van Drew Republican New Jersey NJ Yea Van Duyne Van Duyne Republican Texas TX Yea Van Orden Van Orden Republican Wisconsin WI Yea Vargas Vargas Democratic California CA Nay Vasquez Vasquez Democratic New Mexico NM Nay Veasey Veasey Democratic Texas TX Nay Velázquez Velazquez Democratic New York NY Nay Wagner Wagner Republican Missouri MO Yea Walberg Walberg Republican Michigan MI Yea Waltz Waltz Republican Florida FL Yea Wasserman Schultz Wasserman Schultz Democratic Florida FL Nay Waters Waters Democratic California CA Nay Watson Coleman Watson Coleman Democratic New Jersey NJ Nay Weber (TX) Weber (TX) Republican Texas TX Yea Webster (FL) Webster (FL) Republican Florida FL Yea Wenstrup Wenstrup Republican Ohio OH Yea Westerman Westerman Republican Arkansas AR Yea Wexton Wexton Democratic Virginia VA Nay Wild Wild Democratic Pennsylvania PA Nay Williams (GA) Williams (GA) Democratic Georgia GA Nay Williams (NY) Williams (NY) Republican New York NY Yea Williams (TX) Williams (TX) Republican Texas TX Not Voting Wilson (FL) Wilson (FL) Democratic Florida FL Nay Wilson (SC) Wilson (SC) Republican South Carolina SC Yea Wittman Wittman Republican Virginia VA Yea Womack Womack Republican Arkansas AR Yea Yakym Yakym Republican Indiana IN Yea Zinke Zinke Republican Montana MT Yea No data found 118 Contact Information Room H154, The Capitol Washington, DC 20515-6601 p: (202) 225-7000 For general inquiries: info.clerkweb@mail.house.gov For general technical support: techsupport.clerkweb@mail.house.gov Legislative Information Legislative Activity Roll Call Votes Discharge Petitions live.house.gov Selected Memorials Consensus Calendar Motions Member Information Member Profiles Leadership Election Information Current Vacancies Demographics Member Oaths Disclosures Financial Disclosure Reports Foreign Travel Reports and Expenditures Unsolicited Mass Communications Gift Travel Filings Legal Expense Fund Disclosures Office of Congressional Conduct Post-Employment Notifications About the Clerk Overview and Contact Duties of the Clerk Offices and Services History of the Office Committee Information Committee Profiles Clerk Sites Bills This Week Biographical Directory Clerk Kids Committee Repository History, Art & Archives Office of the Chaplain Help & Resources FAQs Privacy Policy Site Map

---
snapshot_id: 6768bba8-34be-54a1-b4de-3721aa6fe13a
source_kind: own-site (the person's own site or account)
url: https://houchin.house.gov/media/press-releases/video-congresswoman-erin-houchin-delivers-first-remarks-house-floor-pro-life

VIDEO: Congresswoman Erin Houchin Delivers First Remarks on House Floor on Pro-Life Bill | Congresswoman Erin Houchin Skip to main content 342 Cannon House Office Building, Washington, DC 20515 Email Me (202) 225-5315 About Committees and Caucuses Our District Votes and Legislation Contact Newsletter Subscribe Office Locations Media Press Releases Issues Agriculture Economy Education Energy Health Veterans Border Security Services Art Competition Congressional App Challenge Congressional Commendations Flags Grant Applicants Help with a Federal Agency Internships Service Academy Nominations Tours and Tickets America 250 Attention Seniors - Fraud Alert! Casework Success Stories Community Project Funding Help for Veterans Subscribe X How Can I Help? Home Media Press Releases VIDEO: Congresswoman Erin Houchin Delivers First Remarks on House Floor on Pro-Life Bill Image January 11, 2023 Press Release “Hoosiers across Southern Indiana feel that every life is precious and deserves the dignity and respect of life-saving care,” Rep. Houchin. WASHINGTON, D.C. – Today, Congresswoman Erin Houchin (R-Ind.-09) voted in support of the Born-Alive Abortion Survivors Protection Act , H.R. 26, to ensure that infants who are born alive after an abortion attempt have the same protection of the law and degree of care as all other newborn children. “From New Albany, to Salem, to Madison, Hoosiers across Southern Indiana feel that every life is precious and deserves the dignity and respect of life-saving care. Most Americans agree that saving the lives of babies who survive a botched abortion is not just humane, it is necessary and foundational to our constitutional right to life. I’m proud to be an original cosponsor on this important bill, and I will always defend life and support mothers and their children,” said Congresswoman Houchin. In addition to the pro-life bill, Congresswoman Houchin also voted in favor of H.Con.Res.3 to condemn the recent attacks on pro-life facilities, groups, and churches that have occurred in the wake of the Dobbs leak and subsequent decision. “I was proud to pass today’s resolution to condemn the senseless acts of violence and vandalism against pro-life organizations. I’m proud to be an original supporter of this resolution and stand with our Hoosier pro-life community,” said Congresswoman Houchin. To view the video of Congresswoman Houchin’s floor remarks, click here . ### Office Locations Washington DC Office 342 Cannon House Office Building Washington, DC 20515 Phone: (202) 225-5315 Salem District Office 104 W Hackberry Street Salem, IN 47167 Phone: (812) 288-3999 Top Copyright Privacy House.gov Accessibility RSS

---
snapshot_id: e9630556-2125-5b4f-a07b-d4e0adca1713
source_kind: own-site (the person's own site or account)
url: https://www.erinhouchin.com/issues

Erin Houchin on the Issues &mdash; Erin Houchin for Congress 0 Skip to Content ABOUT ISSUES VOLUNTEER CONTACT DONATE Open Menu Close Menu ABOUT ISSUES VOLUNTEER CONTACT DONATE Open Menu Close Menu ABOUT ISSUES VOLUNTEER CONTACT DONATE ERIN ON THE ISSUES SECURE THE BORDER: Joe Biden let over 10 million individuals illegally invade our country—that we know of. These illegals outnumber the population of Indiana by three million people. Erin visited the border in Texas twice, and witnessed the chaos and destruction firsthand. She fully supports President Trump’s efforts to restore border security—by backing law enforcement, finishing the wall, and deporting criminal illegal aliens to protect American communities. STAND WITH ISRAEL: Erin stands firmly with Israel, our nation’s strongest ally in the Middle East. Even before Hamas’ barbaric terrorist attack on October 7, 2023, she has vocally supported Israel’s right to defend itself, and the right of Israelis to live. Erin believes that we as a nation have a moral obligation to unequivocally defend Israel. She is committed to standing resolute against anti-Semitism in all forms at home and abroad and advocating for the U.S. to cut all aid to any sponsors of terrorism. CUT GOVERNMENT SPENDING: Erin believes our government takes too much of your money, and spends too much. Just as families across Indiana balance their budgets, she believes the federal government should too. It's no question that our growing national debt is a national security concern. Erin is a committed fiscal conservative and has the track record to prove it, and as a champion for Indiana’s Balanced Budget Amendment, she is bringing that same fiscal discipline to Washington. PROTECT THE UNBORN: Erin is pro-life and always has been. She has been a steadfast leader in the fight for the unborn, consistently advocating for the prohibition of late-term abortions, and resources and care for mothers in need. In Congress, she continues to be a voice for the voiceless. National Right to Life and the Susan B. Anthony List have endorsed her, she has earned an A+ rating from the SBA List, and had a consistent 100% pro-life voting record as a member of the Indiana State Senate. STAND FOR CONSERVATIVE VALUES: The strong conservative values instilled in Erin growing up in Scottsburg have become a foundational part of who she is. A strong defender of the Second Amendment, the Right to Life, and the right to worship freely, Erin will always fight for our conservative freedoms and liberties. She will continue standing steadfast for an America First Agenda that allows us to live safely and freely. PROTECT PARENTAL RIGHTS: Parents should be in the driver's seat of their children's education. The pandemic opened American parents' eyes to the reality of our public school system, and millions of parents didn't like what they saw. As a mother of three, Erin knows that parents are the primary stakeholders in their children's education. That's why she voted to pass the Parents Bill of Rights and will continue to support parents in this ongoing effort for transparency and a seat at the table as we prepare the next generation for success. SUPPORT OUR VETERANS: America is blessed with the greatest fighting force in the world, and Erin deeply appreciates our servicemen and women and their families. She is committed to improving the welfare and quality of life for our veterans and their families, our active-duty military members and their spouses. Erin is committed to ensuring we keep our promises to those who fought to defend our freedoms and never let them down. UPHOLD LAW & ORDER: Hoosiers are fortunate to have some of the most dedicated and talented law enforcement and public safety officials in the country, and it’s our duty to have their backs. These brave men and women should be protected by lawmakers instead of being met with hostility and resentment. Erin will always fight to ensure our officers have the necessary resources to do their jobs effectively and safely, and they have the support and compensation they deserve. Erin will never allow radical left-wing politicians to defund the police. CREATE JOBS: Erin knows the best way to create jobs and grow the economy is to get the government out of the way and let small business owners do what they do best – innovate and create new jobs. Indiana has one of the best economies in the nation, a direct result of our conservative values. As a small business owner, Erin continues the fight to cut bureaucratic red tape and support limited government while working to cut taxes, promote free markets, and control government spending. PROTECT THE SECOND AMENDMENT: Erin is a firm believer that the Second Amendment is one of our most important freedoms, and she understands the importance of protecting our constitutional right to bear arms. The founders saw the crucial importance of giving citizens the right to protect themselves, and we must all protect that right. CONTRIBUTE PAID FOR BY HOUCHIN FOR CONGRESS ABOUT | ISSUES | CONTACT Privacy Policy

---
snapshot_id: 90f7dcf9-94a1-5322-9e7f-55bbfed465ac
source_kind: public-record
url: https://www.congress.gov/bill/118th-congress/house-bill/7

No Taxpayer Funding for Abortion and Abortion Insurance Full Disclosure Act of 2023 Policy area: Health Sponsor: Rep. Smith, Christopher H. [R-NJ-4] Latest action: Referred to the Subcommittee on Health. No Taxpayer Funding for Abortion and Abortion Insurance Full Disclosure Act of 2023 This bill modifies provisions relating to federal funding for, and health insurance coverage of, abortions. Specifically, the bill prohibits the use of federal funds for abortions or for health coverage that includes abortions. Such restrictions extend to the use of funds in the budget of the District of Columbia. Additionally, abortions may not be provided in a federal health care facility or by a federal employee. Historically, language has been included in annual appropriations bills for the Department of Health and Human Services (HHS) that prohibits the use of federal funds for abortions—such language is commonly referred to as the Hyde Amendment. Similar language is also frequently included in appropriations bills for other federal agencies and the District of Columbia. The bill makes these restrictions permanent and extends the restrictions to all federal funds (rather than specific agencies). The bill's restrictions regarding the use of federal funds do not apply in cases of rape, incest, or where a physical disorder, injury, or illness endangers a woman's life unless an abortion is performed. The Hyde Amendment provides the same exceptions. The bill also prohibits qualified health plans from including coverage for abortions. Currently, qualified health plans may cover abortion, but the portion of the premium attributable to abortion coverage is not eligible for subsidies. Cosponsors: Rep. Fischbach, Michelle [R-MN-7], Rep. Stefanik, Elise M. [R-NY-21], Rep. McMorris Rodgers, Cathy [R-WA-5], Rep. Foxx, Virginia [R-NC-5], Rep. Harshbarger, Diana [R-TN-1], Rep. Bice, Stephanie I. [R-OK-5], Rep. Mace, Nancy [R-SC-1], Rep. Kelly, Mike [R-PA-16], Rep. Johnson, Mike [R-LA-4], Rep. Aderholt, Robert B. [R-AL-4], Rep. Banks, Jim [R-IN-3], Rep. Babin, Brian [R-TX-36], Rep. Latta, Robert E. [R-OH-5], Rep. Estes, Ron [R-KS-4], Rep. Bost, Mike [R-IL-12], Rep. Weber, Randy K., Sr. [R-TX-14], Rep. Wenstrup, Brad R. [R-OH-2], Rep. Balderson, Troy [R-OH-12], Rep. Bergman, Jack [R-MI-1], Rep. Bishop, Dan [R-NC-8], Rep. Burchett, Tim [R-TN-2], Rep. Carter, Earl L. "Buddy" [R-GA-1], Rep. Cline, Ben [R-VA-6], Rep. Clyde, Andrew S. [R-GA-9], Rep. Duncan, Jeff [R-SC-3], Rep. Ellzey, Jake [R-TX-6], Rep. Feenstra, Randy [R-IA-4], Rep. Ferguson, A. Drew, IV [R-GA-3], Rep. Finstad, Brad [R-MN-1], Rep. Fulcher, Russ [R-ID-1], Rep. Gallagher, Mike [R-WI-8], Rep. Graves, Garret [R-LA-6], Rep. Guest, Michael [R-MS-3], Rep. Higgins, Clay [R-LA-3], Rep. Hudson, Richard [R-NC-9], Rep. Issa, Darrell E. [R-CA-48], Rep. Jackson, Ronny [R-TX-13], Rep. Johnson, Dusty [R-SD-At Large], Rep. Joyce, John [R-PA-13], Rep. LaHood, Darin [R-IL-16], Rep. Loudermilk, Barry [R-GA-11], Rep. Luetkemeyer, Blaine [R-MO-3], Rep. Mooney, Alexander X. [R-WV-2], Rep. Moore, Blake D. [R-UT-1], Rep. Perry, Scott [R-PA-10], Rep. Posey, Bill [R-FL-8], Rep. Rose, John W. [R-TN-6], Rep. Thompson, Glenn [R-PA-15], Rep. Walberg, Tim [R-MI-5], Rep. Webster, Daniel [R-FL-11], Rep. Womack, Steve [R-AR-3], Rep. Burgess, Michael C. [R-TX-26], Rep. Stauber, Pete [R-MN-8], Rep. Mast, Brian J. [R-FL-21], Rep. Fallon, Pat [R-TX-4], Rep. Griffith, H. Morgan [R-VA-9], Rep. Smucker, Lloyd [R-PA-11], Rep. Tenney, Claudia [R-NY-24], Rep. Meuser, Daniel [R-PA-9], Rep. Carl, Jerry L. [R-AL-1], Rep. Scott, Austin [R-GA-8], Rep. Fleischmann, Charles J. "Chuck" [R-TN-3], Rep. Hinson, Ashley [R-IA-2], Rep. Kustoff, David [R-TN-8], Rep. Harris, Andy [R-MD-1], Rep. Moolenaar, John R. [R-MI-2], Rep. Good, Bob [R-VA-5], Rep. Simpson, Michael K. [R-ID-2], Rep. Bucshon, Larry [R-IN-8], Rep. Langworthy, Nicholas A. [R-NY-23], Rep. LaMalfa, Doug [R-CA-1], Rep. Kim, Young [R-CA-40], Rep. Huizenga, Bill [R-MI-4], Rep. McClain, Lisa C. [R-MI-9], Rep. Miller, Carol D. [R-WV-1], Rep. Buchanan, Vern [R-FL-16], Rep. Reschenthaler, Guy [R-PA-14], Rep. Timmons, William R. IV [R-SC-4], Rep. Palmer, Gary J. [R-AL-6], Rep. Cloud, Michael [R-TX-27], Rep. Joyce, David P. [R-OH-14], Rep. Waltz, Michael [R-FL-6], Rep. Crenshaw, Dan [R-TX-2], Rep. McClintock, Tom [R-CA-5], Rep. Lamborn, Doug [R-CO-5], Rep. Mann, Tracey [R-KS-1], Rep. Gaetz, Matt [R-FL-1], Rep. Lesko, Debbie [R-AZ-8], Rep. Guthrie, Brett [R-KY-2], Rep. Ezell, Mike [R-MS-4], Rep. Letlow, Julia [R-LA-5], Rep. Wilson, Joe [R-SC-2], Rep. Franklin, C. Scott [R-FL-18], Rep. Houchin, Erin [R-IN-9], Rep. LaTurner, Jake [R-KS-2], Rep. Grothman, Glenn [R-WI-6], Rep. Fry, Russell [R-SC-7], Rep. Brecheen, Josh [R-OK-2], Rep. McHenry, Patrick T. [R-NC-10], Rep. Boebert, Lauren [R-CO-3], Rep. Turner, Michael R. [R-OH-10], Rep. Barr, Andy [R-KY-6], Rep. Armstrong, Kelly [R-ND-At Large], Rep. Green, Mark E. [R-TN-7], Rep. Norman, Ralph [R-SC-5], Rep. Allen, Rick W. [R-GA-12], Rep. Miller, Mary E. [R-IL-15], Rep. Fitzgerald, Scott [R-WI-5], Rep. Dunn, Neal P. [R-FL-2], Rep. Ogles, Andrew [R-TN-5], Rep. Kelly, Trent [R-MS-1], Rep. Rutherford, John H. [R-FL-5], Rep. Sessions, Pete [R-TX-17], Rep. Diaz-Balart, Mario [R-FL-26], Rep. Flood, Mike [R-NE-1], Rep. Rouzer, David [R-NC-7], Rep. Crane, Elijah [R-AZ-2], Rep. Luna, Anna Paulina [R-FL-13], Rep. Yakym, Rudy [R-IN-2], Rep. Pence, Greg [R-IN-6], Rep. Miller-Meeks, Mariannette [R-IA-1], Rep. Pfluger, August [R-TX-11], Rep. McCormick, Richard [R-GA-6], Rep. Crawford, Eric A. "Rick" [R-AR-1], Rep. Hageman, Harriet M. [R-WY-At Large], Rep. Carter, John R. [R-TX-31], Rep. Edwards, Chuck [R-NC-11], Rep. Hill, J. French [R-AR-2], Rep. Van Duyne, Beth [R-TX-24], Rep. Granger, Kay [R-TX-12], Rep. Luttrell, Morgan [R-TX-8], Rep. Gosar, Paul A. [R-AZ-9], Rep. Gooden, Lance [R-TX-5], Rep. Smith, Adrian [R-NE-3], Rep. Miller, Max L. [R-OH-7], Rep. Rogers, Harold [R-KY-5], Rep. Bilirakis, Gus M. [R-FL-12], Rep. Moran, Nathaniel [R-TX-1], Rep. Smith, Jason [R-MO-8], Rep. Self, Keith [R-TX-3], Rep. Biggs, Andy [R-AZ-5], Rep. Tiffany, Thomas P. [R-WI-7], Rep. Westerman, Bruce [R-AR-4], Rep. Wittman, Robert J. [R-VA-1], Rep. Burlison, Eric [R-MO-7], Rep. Ciscomani, Juan [R-AZ-6], Rep. Gonzales, Tony [R-TX-23], Rep. Alford, Mark [R-MO-4], Rep. Carey, Mike [R-OH-15], Rep. Wagner, Ann [R-MO-2], Rep. Graves, Sam [R-MO-6], Rep. Bentz, Cliff [R-OR-2], Rep. Williams, Brandon [R-NY-22], Rep. Davidson, Warren [R-OH-8], Rep. Mills, Cory [R-FL-7], Rep. Zinke, Ryan K. [R-MT-1], Rep. Johnson, Bill [R-OH-6], Rep. Scalise, Steve [R-LA-1], Rep. Lucas, Frank D. [R-OK-3], Rep. Cole, Tom [R-OK-4], Rep. Williams, Roger [R-TX-25], Rep. Rosendale Sr., Matthew M. [R-MT-2], Rep. Bacon, Don [R-NE-2], Rep. Lee, Laurel M. [R-FL-15], Rep. Van Drew, Jefferson [R-NJ-2], Rep. Curtis, John R. [R-UT-3], Rep. Arrington, Jodey C. [R-TX-19], Rep. Steube, W. Gregory [R-FL-17], Rep. Strong, Dale W. [R-AL-5], Rep. Jordan, Jim [R-OH-4], Rep. Rogers, Mike D. [R-AL-3], Rep. Moore, Barry [R-AL-2], Rep. Bean, Aaron [R-FL-4], Rep. Gimenez, Carlos A. [R-FL-28], Rep. Cammack, Kat [R-FL-3], Rep. Buck, Ken [R-CO-4], Rep. Hern, Kevin [R-OK-1], Rep. Murphy, Gregory F. [R-NC-3], Rep. Maloy, Celeste [R-UT-2], Rep. Roy, Chip [R-TX-21], Rep. Fong, Vince [R-CA-20], Rep. Steil, Bryan [R-WI-1], Rep. Greene, Marjorie Taylor [R-GA-14] Actions: Referred to the Subcommittee on Health. Referred to the Committee on Energy and Commerce, and in addition to the Committees on the Judiciary, and Ways and Means, for a period to be subsequently determined by the Speaker, in each case for consideration of such provisions as fall within the jurisdiction of the committee concerned. Referred to the Committee on Energy and Commerce, and in addition to the Committees on the Judiciary, and Ways and Means, for a period to be subsequently determined by the Speaker, in each case for consideration of such provisions as fall within the jurisdiction of the committee concerned. Referred to the Committee on Energy and Commerce, and in addition to the Committees on the Judiciary, and Ways and Means, for a period to be subsequently determined by the Speaker, in each case for consideration of such provisions as fall within the jurisdiction of the committee concerned. Referred to the Subcommittee on Health. Introduced in House Introduced in House [Congressional Bills 118th Congress] [From the U.S. Government Publishing Office] [H.R. 7 Introduced in House (IH)] <DOC> 118th CONGRESS 1st Session H. R. 7 To prohibit taxpayer funded abortions. _______________________________________________________________________ IN THE HOUSE OF REPRESENTATIVES January 9, 2023 Mr. Smith of New Jersey (for himself, Mrs. Fischbach, Ms. Stefanik, Mrs. Rodgers of Washington, Ms. Foxx, Mrs. Harshbarger, Mrs. Bice, Ms. Mace, Mr. Kelly of Pennsylvania, Mr. Johnson of Louisiana, Mr. Aderholt, Mr. Banks, Mr. Babin, Mr. Latta, Mr. Estes, Mr. Bost, Mr. Weber of Texas, Mr. Wenstrup, Mr. Balderson, Mr. Bergman, Mr. Bishop of North Carolina, Mr. Burchett, Mr. Carter of Georgia, Mr. Cline, Mr. Clyde, Mr. Duncan, Mr. Ellzey, Mr. Feenstra, Mr. Ferguson, Mr. Finstad, Mr. Fulcher, Mr. Gallagher, Mr. Graves of Louisiana, Mr. Guest, Mr. Higgins of Louisiana, Mr. Hudson, Mr. Issa, Mr. Jackson of Texas, Mr. Johnson of South Dakota, Mr. Joyce of Pennsylvania, Mr. LaHood, Mr. Loudermilk, Mr. Luetkemeyer, Mr. Mooney, Mr. Moore of Utah, Mr. Perry, Mr. Posey, Mr. Rose, Mr. Thompson of Pennsylvania, Mr. Walberg, Mr. Webster of Florida, Mr. Womack, Mr. Burgess, Mr. Stauber, Mr. Mast, Mr. Fallon, Mr. Griffith, Mr. Smucker, Ms. Tenney, Mr. Meuser, Mr. Carl, Mr. Austin Scott of Georgia, Mr. Fleischmann, Mrs. Hinson, Mr. Kustoff, Mr. Harris, Mr. Moolenaar, Mr. Good of Virginia, Mr. Simpson, Mr. Bucshon, Mr. Langworthy, Mr. LaMalfa, Mrs. Kim of California, Mr. Huizenga, Mrs. McClain, Mrs. Miller of West Virginia, Mr. Buchanan, Mr. Reschenthaler, Mr. Timmons, Mr. Palmer, Mr. Cloud, Mr. Joyce of Ohio, Mr. Waltz, Mr. Crenshaw, Mr. McClintock, Mr. Lamborn, Mr. Mann, Mr. Gaetz, Mrs. Lesko, Mr. Guthrie, Mr. Ezell, Ms. Letlow, Mr. Wilson of South Carolina, Mr. C. Scott Franklin of Florida, Mrs. Houchin, Mr. LaTurner, Mr. Grothman, Mr. Fry, Mr. Brecheen, Mr. McHenry, Mrs. Boebert, Mr. Turner, Mr. Barr, Mr. Armstrong, and Mr. Green of Tennessee) introduced the following bill; which was referred to the Committee on Energy and Commerce, and in addition to the Committees on the Judiciary, and Ways and Means, for a period to be subsequently determined by the Speaker, in each case for consideration of such provisions as fall within the jurisdiction of the committee concerned _______________________________________________________________________ A BILL To prohibit taxpayer funded abortions. Be it enacted by the Senate and House of Representatives of the United States of America in Congress assembled, SECTION 1. SHORT TITLE; TABLE OF CONTENTS. (a) Short Title.--This Act may be cited as the ``No Taxpayer Funding for Abortion and Abortion Insurance Full Disclosure Act of 2023''. (b) Table of Contents.--The table of contents of this Act is as follows: Sec. 1. Short title; table of contents. TITLE I--PROHIBITING FEDERALLY FUNDED ABORTIONS Sec. 101. Prohibiting taxpayer funded abortions. Sec. 102. Amendment to table of chapters. TITLE II--APPLICATION UNDER THE AFFORDABLE CARE ACT Sec. 201. Clarifying application of prohibition to premium credits and cost-sharing reductions under ACA. Sec. 202. Revision of notice requirements regarding disclosure of extent of health plan coverage of abortion and abortion premium surcharges. TITLE I--PROHIBITING FEDERALLY FUNDED ABORTIONS SEC. 101. PROHIBITING TAXPAYER FUNDED ABORTIONS. Title 1, United States Code, is amended by adding at the end the following new chapter: ``CHAPTER 4--PROHIBITING TAXPAYER FUNDED ABORTIONS ``301. Prohibition on funding for abortions. ``302. Prohibition on funding for health benefits plans that cover abortion. ``303. Limitation on Federal facilities and employees. ``304. Construction relating to separate coverage. ``305. Construction relating to the use of non-Federal funds for health coverage. ``306. Non-preemption of other Federal laws. ``307. Construction relating to complications arising from abortion. ``308. Treatment of abortions related to rape, incest, or preserving the life of the mother. ``309. Application to District of Columbia. ``Sec. 301. Prohibition on funding for abortions ``No funds authorized or appropriated by Federal law, and none of the funds in any trust fund to which funds are authorized or appropriated by Federal law, shall be expended for any abortion. ``Sec. 302. Prohibition on funding for health benefits plans that cover abortion ``None of the funds authorized or appropriated by Federal law, and none of the funds in any trust fund to which funds are authorized or appropriated by Federal law, shall be expended for health benefits coverage that includes coverage of abortion. ``Sec. 303. Limitation on Federal facilities and employees ``No health care service furnished-- ``(1) by or in a health care facility owned or operated by the Federal Government; or ``(2) by any physician or other individual employed by the Federal Government to provide health care services within the scope of the physician's or individual's employment, may include abortion. ``Sec. 304. Construction relating to separate coverage ``Nothing in this chapter shall be construed as prohibiting any individual, entity, or State or locality from purchasing separate abortion coverage or health benefits coverage that includes abortion so long as such coverage is paid for entirely using only funds not authorized or appropriated by Federal law and such coverage shall not be purchased using matching funds required for a federally subsidized program, including a State's or locality's contribution of Medicaid matching funds. ``Sec. 305. Construction relating to the use of non-Federal funds for health coverage ``Nothing in this chapter shall be construed as restricting the ability of any non-Federal health benefits coverage provider from offering abortion coverage, or the ability of a State or locality to contract separately with such a provider for such coverage, so long as only funds not authorized or appropriated by Federal law are used and such coverage shall not be purchased using matching funds required for a federally subsidized program, including a State's or locality's contribution of Medicaid matching funds. ``Sec. 306. Non-preemption of other Federal laws ``Nothing in this chapter shall repeal, amend, or have any effect on any other Federal law to the extent such law imposes any limitation on the use of funds for abortion or for health benefits coverage that includes coverage of abortion, beyond the limitations set forth in this chapter. ``Sec. 307. Construction relating to complications arising from abortion ``Nothing in this chapter shall be construed to apply to the treatment of any infection, injury, disease, or disorder that has been caused by or exacerbated by the performance of an abortion. This rule of construction shall be applicable without regard to whether the abortion was performed in accord with Federal or State law, and without regard to whether funding for the abortion is permissible under section 308. ``Sec. 308. Treatment of abortions related to rape, incest, or preserving the life of the mother ``The limitations established in sections 301, 302, and 303 shall not apply to an abortion-- ``(1) if the pregnancy is the result of an act of rape or incest; or ``(2) in the case where a woman suffers from a physical disorder, physical injury, or physical illness that would, as certified by a physician, place the woman in danger of death unless an abortion is performed, including a life-endangering physical condition caused by or arising from the pregnancy itself. ``Sec. 309. Application to District of Columbia ``In this chapter: ``(1) Any reference to funds appropriated by Federal law shall be treated as including any amounts within the budget of the District of Columbia that have been approved by an Act of Congress pursuant to section 446 of the District of Columbia Home Rule Act (or any applicable successor Federal law). ``(2) The term `Federal Government' includes the government of the District of Columbia.''. SEC. 102. AMENDMENT TO TABLE OF CHAPTERS. The table of chapters for title 1, United States Code, is amended by adding at the end the following new item: ``4. Prohibiting taxpayer funded abortions.................. 301''. TITLE II--APPLICATION UNDER THE AFFORDABLE CARE ACT SEC. 201. CLARIFYING APPLICATION OF PROHIBITION TO PREMIUM CREDITS AND COST-SHARING REDUCTIONS UNDER ACA. (a) In General.-- (1) Disallowance of refundable credit and cost-sharing reductions for coverage under qualified health plan which provides coverage for abortion.-- (A) In general.--Subparagraph (A) of section 36B(c)(3) of the Internal Revenue Code of 1986 is amended by inserting before the period at the end the following: ``or any health plan that includes coverage for abortions (other than any abortion or treatment described in section 307 or 308 of title 1, United States Code)''. (B) Option to purchase or offer separate coverage or plan.--Paragraph (3) of section 36B(c) of such Code is amended by adding at the end the following new subparagraph: ``(C) Separate abortion coverage or plan allowed.-- ``(i) Option to purchase separate coverage or plan.--Nothing in subparagraph (A) shall be construed as prohibiting any individual from purchasing separate coverage for abortions described in such subparagraph, or a health plan that includes such abortions, so long as no credit is allowed under this section with respect to the premiums for such coverage or plan. ``(ii) Option to offer coverage or plan.-- Nothing in subparagraph (A) shall restrict any non-Federal health insurance issuer offering a health plan from offering separate coverage for abortions described in such subparagraph, or a plan that includes such abortions, so long as premiums for such separate coverage or plan are not paid for with any amount attributable to the credit allowed under this section (or the amount of any advance payment of the credit under section 1412 of the Patient Protection and Affordable Care Act).''. (2) Disallowance of small employer health insurance expense credit for plan which includes coverage for abortion.-- Subsection (h) of section 45R of the Internal Revenue Code of 1986 is amended-- (A) by striking ``Any term'' and inserting the following: ``(1) In general.--Any term''; and (B) by adding at the end the following new paragraph: ``(2) Exclusion of health plans including coverage for abortion.-- ``(A) In general.--The term `qualified health plan' does not include any health plan that includes coverage for abortions (other than any abortion or treatment described in section 307 or 308 of title 1, United States Code). ``(B) Separate abortion coverage or plan allowed.-- ``(i) Option to purchase separate coverage or plan.--Nothing in subparagraph (A) shall be construed as prohibiting any employer from purchasing for its employees separate coverage for abortions described in such subparagraph, or a health plan that includes such abortions, so long as no credit is allowed under this section with respect to the employer contributions for such coverage or plan. ``(ii) Option to offer coverage or plan.-- Nothing in subparagraph (A) shall restrict any non-Federal health insurance issuer offering a health plan from offering separate coverage for abortions described in such subparagraph, or a plan that includes such abortions, so long as such separate coverage or plan is not paid for with any employer contribution eligible for the credit allowed under this section.''. (3) Conforming aca amendments.--Section 1303(b) of Public Law 111-148 (42 U.S.C. 18023(b)) is amended-- (A) by striking paragraph (2); (B) by striking paragraph (3), as amended by section 202(a); and (C) by redesignating paragraph (4) as paragraph (2). (b) Application to Multi-State Plans.--Paragraph (6) of section 1334(a) of Public Law 111-148 (42 U.S.C. 18054(a)) is amended to read as follows: ``(6) Coverage consistent with federal abortion policy.--In entering into contracts under this subsection, the Director shall ensure that no multi-State qualified health plan offered in an Exchange provides health benefits coverage for which the expenditure of Federal funds is prohibited under chapter 4 of title 1, United States Code.''. (c) Effective Date.--The amendments made by subsection (a) shall apply to taxable years ending after December 31, 2023, but only with respect to plan years beginning after such date, and the amendment made by subsection (b) shall apply to plan years beginning after such date. SEC. 202. REVISION OF NOTICE REQUIREMENTS REGARDING DISCLOSURE OF EXTENT OF HEALTH PLAN COVERAGE OF ABORTION AND ABORTION PREMIUM SURCHARGES. (a) In General.--Paragraph (3) of section 1303(b) of Public Law 111-148 (42 U.S.C. 18023(b)) is amended to read as follows: ``(3) Rules relating to notice.-- ``(A) In general.--The extent of coverage (if any) of services described in paragraph (1)(B)(i) or (1)(B)(ii) by a qualified health plan shall be disclosed to enrollees at the time of enrollment in the plan and shall be prominently displayed in any marketing or advertising materials, comparison tools, or summary of benefits and coverage explanation made available with respect to such plan by the issuer of the plan, by an Exchange, or by the Secretary, including information made available through an Internet portal or Exchange under sections 1311(c)(5) and 1311(d)(4)(C). ``(B) Separate disclosure of abortion surcharges.-- In the case of a qualified health plan that includes the services described in paragraph (1)(B)(i) and where the premium for the plan is disclosed, including in any marketing or advertising materials or any other information referred to in subparagraph (A), the surcharge described in paragraph (2)(B)(i)(II) that is attributable to such services shall also be disclosed and identified separately.''. (b) Effective Date.--The amendment made by subsection (a) shall apply to materials, tools, or other information made available more than 30 days after the date of the enactment of this Act. <all>