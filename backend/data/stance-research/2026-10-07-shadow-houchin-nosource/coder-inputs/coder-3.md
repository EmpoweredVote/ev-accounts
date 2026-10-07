You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-monroe-stances/backend/data/stance-research/2026-10-07-shadow-houchin-nosource/labels/coder-3.json. Write JSON only, matching
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

### topic_key: campaign-finance
topic_id: 92730f69-ae57-401c-8ad1-2d07834a895d  served_revision_id: ae53ba29-79eb-420f-aac6-ec99f8031ec6
Question: What rules should govern money in political campaigns and elections?
  1. Ban all private money in political campaigns
  2. Strictly limit corporate and dark-money spending
  3. Keep contribution limits at current levels
  4. Reduce restrictions on political donations and spending
  5. Eliminate all campaign finance laws and limits

#### Annex

# campaign-finance — served revision ae53ba29-79eb-420f-aac6-ec99f8031ec6 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. No gold item exists on this topic
yet; every reading below is a drafter's.

**Question:** "What rules should govern money in political campaigns and elections?"

**Orientation:** standard. Rung 1 is the most limit on private money (a ban), rung 5 removes every
law. The rungs order **how much private political money is limited**. Disclosure is a different axis
and is not ordered here.

**Levels with a lever:** federal, local, state. Each level limits money in its
own elections: federal (FECA, the FEC), state (state contribution limits), local (city limits and
city public-financing programmes).

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "contribution limit", "aggregate limit", "independent expenditure", "super PAC",
"dark money", "501(c)(4)", "electioneering communication", "coordination", "soft money",
"Citizens United", "public financing", "clean elections", "matching funds", "democracy vouchers",
"small-dollar", "pay-to-play", "foreign-influenced corporation".

1. **"Ban all private money in political campaigns"**
   - Means: no private person or group may fund a campaign.
   - Operative clauses: [a] a ban; [b] on **all** private money.
   - Establishing evidence looks like: own words or text that forbid every private contribution and
     expenditure. [b] is universal (V4.2).
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Public financing is no longer part of this rung. A **voluntary** public-financing programme
     (matching funds, clean-elections grants, vouchers) leaves private money legal → not rung 1;
     `direction-only` _(proposed)_.

2. **"Strictly limit corporate and dark-money spending"**
   - Means: the law sets strict limits on political spending by corporations and by groups that hide
     their donors.
   - Operative clauses: [a] strict limits; [b] on corporate spending; [c] on dark-money spending.
   - Establishing evidence looks like: operative text that caps or bans corporate political spending
     or outside spending by undisclosed sources; own words calling for it, including a proposed
     constitutional amendment that lets government limit such spending _(proposed)_.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - [b] and [c] are **one clause with two forms**: either is enough. "Strictly" still needs a real
     limit, not a reporting duty _(ruled 2026-10-01)_.
   - A rule that bars spending unless the group discloses its donors is a **limit** on dark-money
     spending. A plain reporting duty is not → `direction-only` _(ruled 2026-10-01)_.
   - Commonly confused with rung 3 when a bill only lowers **contribution** limits to candidates.
     Rung 2 targets spending by corporations and outside groups.
   - A narrow ban (foreign-influenced corporations, government contractors, lobbyists) is not "strictly
     limit corporate spending" → `direction-only` _(proposed)_.

3. **"Keep contribution limits at current levels"**
   - Means: contribution limits stay as they are, neither raised nor lowered.
   - Operative clauses: [a] contribution limits kept at current levels.
   - Establishing evidence looks like: own words that the limits should stay where they are.
     Instruments rarely say this _(proposed)_.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a No on raising limits, or a No on lowering them, shows a
     side but not "keep". Ruling out the other rungs is not evidence for rung 3 (V4.2) →
     `direction-only`.
   - An automatic inflation adjustment keeps limits at current levels in real terms; it is not evidence
     for rung 4 _(proposed)_.
   - Disclosure was taken out of this rung in Season 2 (CA_0041, 2026-08-30): disclosure is now its
     own topic. A disclosure bill does not place anyone here → `adjacent`.

4. **"Reduce restrictions on political donations and spending"**
   - Means: the law allows more political giving and spending than it does now.
   - Operative clauses: [a] fewer or looser restrictions; [b] on donations; [c] on spending.
   - Establishing evidence looks like: a bill that raises contribution limits, removes aggregate or
     coordination limits, or repeals a spending restriction. A bill that loosens limits but keeps them
     excludes rung 5 by its own text _(proposed)_.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - [b] and [c] are one clause with two forms, as in rung 2 _(ruled 2026-10-01)_.
   - A **lawsuit or amicus brief** arguing that a limit violates free speech is a `record` (Q8); the
     substantive claim is the position. A claim against one limit is rung 4, not rung 5 _(proposed)_.

5. **"Eliminate all campaign finance laws and limits"**
   - Means: no law governs campaign money at all — no limits, and no other campaign-finance rule.
   - Operative clauses: [a] eliminate all limits; [b] eliminate all campaign-finance laws.
   - Establishing evidence looks like: own words calling for the end of every limit and every
     campaign-finance law. [a] and [b] are universal (V4.2).
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 when a person wants every **limit** gone but keeps disclosure. [b]
     covers all campaign-finance laws, so that passage → `compound-partial` _(proposed)_.

**Hard cases:**
- **Disclosure and reporting rules** (donor disclosure, reporting deadlines, disclaimers on ads) →
  `adjacent`. Disclosure was split to a separate transparency topic (CA_0041, 2026-08-30).
- **Preemption (codebook V2, H12).** A state law that forbids cities to set their own limits or run
  public financing decides which level may act → `adjacent`.
- **Enforcement and agency votes** (FEC quorum, penalties, nominations) → `adjacent` unless the passage
  names a limit _(proposed)_.
- **Omnibus election bills** with a campaign-finance title → V4 `multi-subject`.
- **A person's own fundraising** (refusing corporate PAC money, small-dollar pledges) is conduct, not a
  rule for others → `adjacent` _(proposed)_.


### topic_key: childcare
topic_id: c1ac1330-47f7-44ec-baf3-c913d926b97c  served_revision_id: 0e9fe0f2-cfab-4553-99cd-c3195d08e236
Question: How should government address the cost and availability of childcare?
  1. Establishing publicly funded universal childcare so that all families have access regardless of income
  2. Significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families
  3. Offering targeted tax credits and subsidies for families below a set income threshold while supporting providers through training and facility grants
  4. Limiting government support to childcare subsidies for the lowest-income families, relying on the private market for everyone else
  5. Leaving childcare to the private market and families, with no government subsidies or mandates that increase costs for providers and taxpayers

#### Annex

# childcare — served revision 0e9fe0f2-cfab-4553-99cd-c3195d08e236 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(ruled 2026-08-30)_ carry an operator ruling (Chris
Andrews, recorded with the rung-4 rewrite). Lines marked _(proposed)_ are a drafter's reading, not
yet ruled. No `_owed:_` line is open.

**Question:** "How should government address the cost and availability of childcare?"

**Orientation:** standard. Rung 1 is universal public childcare, rung 5 leaves childcare to families
and the market. The rungs order **how far public money reaches**: every family, low- and
middle-income families, families under a threshold, the lowest-income families only, no one.

**Levels with a lever:** federal, local, state. Federal money flows through
block grants and tax credits; states run subsidy programmes and license providers; some cities and
counties fund their own programmes.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "child care subsidy", "Child Care and Development Block Grant" (CCDBG), "child care
assistance", "Child and Dependent Care Tax Credit" (CDCTC), "dependent care FSA", "provider grant",
"stabilization grant", "facility grant", "workforce grant", "universal childcare", "universal
pre-K", "Head Start", "licensing", "staff-to-child ratio".

1. **"Establishing publicly funded universal childcare so that all families have access regardless of
   income"**
   - Means: public money pays for a childcare system open to every family, whatever its income.
   - Operative clauses: [a] publicly funded childcare; [b] universal, regardless of income.
   - Establishing evidence looks like: an instrument that creates childcare open to all families with
     no income test, or own words calling for it.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because a programme with a high income cap is broad but not
     universal. Any income test → not rung 1.
   - **Universal pre-K** for one age group is universal in income but not childcare for all families
     with young children → `direction-only` _(proposed)_.

2. **"Significantly expanding subsidies and provider grants to make childcare affordable for low- and
   middle-income families"**
   - Means: much more public money, through subsidies and grants to providers, so childcare is
     affordable for low- and middle-income families.
   - Operative clauses: [a] significantly expand subsidies; [b] and provider grants; [c] reaching low-
     **and** middle-income families.
   - Establishing evidence looks like: a large expansion of a subsidy programme whose eligibility
     reaches middle-income families, paired with provider grants. Compound: subsidies without
     provider grants, or the reverse → `compound-partial` (V4.2) _(proposed)_.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because both fund subsidies and providers. The discriminator is
     [c]: an expansion that reaches middle-income families → rung 2; a programme capped below that →
     rung 3 _(proposed)_.

3. **"Offering targeted tax credits and subsidies for families below a set income threshold while
   supporting providers through training and facility grants"**
   - Means: tax credits and subsidies go to families under an income limit, and providers get
     training and facility grants.
   - Operative clauses: [a] targeted tax credits and subsidies for families below a set income
     threshold; [b] training and facility grants for providers. Compound: one side only →
     `compound-partial` (V4.2).
   - Establishing evidence looks like: a means-tested childcare credit or subsidy **and** a provider
     training or facility grant, in one instrument or two.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_. A childcare facility pilot grant (NC HB 877,
     used in the 2026-08-30 re-seat) meets [b] only.
   - Commonly confused with rung 2: see rung 2.
   - **A general child tax credit is not a childcare credit.** A credit paid per child whatever the
     family spends on care is not a childcare-subsidy measure → V2 `adjacent` (codebook H6). A
     credit for childcare **expenses** (CDCTC-type) is on-question.

4. **"Limiting government support to childcare subsidies for the lowest-income families, relying on
   the private market for everyone else"**
   - Means: public help goes only to the poorest families; everyone else pays the market price.
   - Operative clauses: [a] subsidies for the lowest-income families; [b] no support beyond them;
     [c] the market for everyone else.
   - Establishing evidence looks like: support for keeping a low-income subsidy **plus** opposition to
     extending help above it (a No on an expansion to middle-income families, or own words). A No
     alone → `direction-only`.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - **Provider deregulation is no longer part of this rung.** Licensing exemptions or looser staff
     ratios do not move a person to rung 4 _(ruled 2026-08-30)_.
   - Commonly confused with rung 5 because both rely on the market. Rung 4 keeps the low-income
     subsidy.

5. **"Leaving childcare to the private market and families, with no government subsidies or mandates
   that increase costs for providers and taxpayers"**
   - Means: no public money for childcare and no rules that raise providers' or taxpayers' costs.
   - Operative clauses: [a] no government subsidies; [b] no cost-raising mandates. Both are absence
     clauses (V4.2 "Silence is not a clause"). Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: own words against all childcare subsidies **and** against
     cost-raising rules; a repeal of a subsidy programme.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.
   - A deregulation record touches [b] only → `compound-partial` at most _(proposed)_.

**Hard cases:**
- **Employer childcare credits** (a business credit for on-site care) are not a credit for families
  below a threshold → `direction-only` _(proposed)_.
- **Paid family leave** and parental leave → `adjacent`.
- **Preemption (codebook V2, H12)** of local childcare rules → `adjacent`.
- **Childcare workforce pay** (wage supplements for providers' staff) is a provider grant → rung 2
  [b]; it is not a training or facility grant, so not rung 3 [b] _(proposed)_.
- **Studies and task forces** → V4 `study-directive`.
- **Budget and omnibus votes** with a childcare item → V4 `multi-subject`.


### topic_key: civil-rights
topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762  served_revision_id: 2010cab0-1968-4f24-b74d-ca47c2f90165
Question: What role should government play in addressing racial and social inequality?
  1. mandate racial equity requirements in all institutions
  2. strengthen civil rights enforcement and address systemic discrimination
  3. maintain current civil rights laws while promoting equal opportunity
  4. limit federal civil rights enforcement to clear cases of discrimination
  5. eliminate affirmative action and all race-based government programs

#### Annex

# civil-rights — served revision 2010cab0-1968-4f24-b74d-ca47c2f90165 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "What role should government play in addressing racial and social inequality?"

**Orientation:** standard. Rung 1 is the most government action (equity mandates on every
institution), rung 5 removes race-conscious programmes. Rungs 1–4 order **how much enforcement and
remedy** government supplies; rung 5 is about **race-conscious programmes**, a related but different
dimension. Read each rung's own clauses.

**Levels with a lever:** federal, local, state. Federal law (the Civil Rights
Act, the Fair Housing Act, agency enforcement) is the main lever. States and cities pass and enforce
their own anti-discrimination laws and run their own programmes. Rung 4 names **federal**
enforcement only.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "Title VI", "Title VII", "Civil Rights Act", "Fair Housing Act", "disparate impact",
"intentional discrimination" or "disparate treatment", "EEOC", "Civil Rights Division", "human
rights commission", "protected class" or "protected characteristic", "affirmative action",
"race-conscious admissions", "set-aside", "DBE" or "MBE" (minority business enterprise), "DEI"
(diversity, equity and inclusion), "equity plan", "equity audit", "systemic racism", "colorblind",
"reparations".

1. **"mandate racial equity requirements in all institutions"**
   - Means: the law requires every institution to meet racial-equity requirements.
   - Operative clauses: [a] a mandate (binding text); [b] racial-equity requirements (equity plans,
     audits, outcome targets); [c] in **all** institutions.
   - Establishing evidence looks like: binding operative text that imposes racial-equity requirements
     across sectors (public bodies **and** private employers or institutions); own words calling for
     that.
   - Levels that hold a lever: federal; state; local (for the institutions the city governs).
   - Known chair-shaped instruments: _(none on file)_.
   - An equity requirement on one sector only (state agencies, one city's departments) does not meet
     [c] "all" → `direction-only` _(proposed)_.
   - Reparations are no longer part of this rung (S1 rung 1 had "and provide reparations"). A
     reparations measure does not move a person along these rungs → `adjacent`; a reparations
     **study** is V4 `study-directive` _(proposed)_.

2. **"strengthen civil rights enforcement and address systemic discrimination"**
   - Means: make anti-discrimination law stronger or better enforced, and act on discrimination built
     into systems.
   - Operative clauses: [a] strengthen civil rights enforcement; [b] address systemic
     discrimination. Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: authoring or prime-sponsoring a single-subject bill that widens
     anti-discrimination law or its enforcement (new remedies, more enforcement power, a new form of
     discrimination covered) **and** aims at a systemic pattern _(proposed)_.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - **Permitting a programme is not enforcement.** A measure that only permits a programme
     strengthens no enforcement → at most [b] → BLANK `compound-partial` _(ruled 2026-10-01)_. Reaching rung 2 because rungs 1, 3, 4 and 5 do not fit is not evidence (V4.2
     "Ruling out the other rungs", H14).
   - **A near-unanimous vote** (fewer than 10% No) on an anti-discrimination bill cannot carry the
     chair alone, even when the bill fits rung 2 well (V4.1). Without authorship or own words that tie
     the person to the provision → BLANK `no-evidence`.
   - Commonly confused with rung 1 because a strong enforcement bill is not a mandate on **all**
     institutions.

3. **"maintain current civil rights laws while promoting equal opportunity"**
   - Means: keep the present laws as they are, neither widening nor narrowing them, and promote equal
     opportunity.
   - Operative clauses: [a] maintain current law (no expansion, no rollback); [b] promote equal
     opportunity. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: own words that present law is enough and should stay as it is,
     beside an equal-opportunity measure.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - "Equal opportunity for all" alone names no clause → `rhetorical`.
   - A No on an expansion bill does not show [a] (the person may want a rollback) → `direction-only`.

4. **"limit federal civil rights enforcement to clear cases of discrimination"**
   - Means: federal agencies act only on clear, usually intentional, discrimination, not on
     statistical disparities.
   - Operative clauses: [a] **federal** enforcement; [b] limited to clear cases (for example, ending
     disparate-impact liability).
   - Establishing evidence looks like: a federal bill or vote that removes disparate-impact liability
     or narrows federal enforcement to intentional discrimination; own words calling for that.
   - Levels that hold a lever: federal. State and local officeholders hold no lever on federal
     enforcement → own words only (codebook V2 "No-lever level"). A state law that narrows the state's **own** enforcement does
     not match [a] → `direction-only` _(proposed)_.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because ending a race-conscious programme is not a limit on
     enforcement.

5. **"eliminate affirmative action and all race-based government programs"**
   - Means: government ends affirmative action and every programme that sorts people by race.
   - Operative clauses: [a] eliminate affirmative action; [b] eliminate **all** race-based government
     programmes. Compound: [a] only → `compound-partial`.
   - Establishing evidence looks like: a single-subject measure that bars preferential treatment by
     race in public employment, education **and** contracting; own words calling for an end to all
     such programmes.
   - Levels that hold a lever: federal; state; local (its own programmes).
   - Known chair-shaped instruments: _(none on file)_.
   - A race-preference ban limited to one sector meets the affirmative-action part only →
     `compound-partial`. Closing DEI offices with no ban on preferences → `direction-only`: an office
     is not a programme that allocates by race _(ruled 2026-10-01)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Advocacy-group profiles and legislator directories** → V3 `not-evidence` (codebook V3, [real]).
- **Hate-crime penalties** are criminal law, not a remedy for inequality → `adjacent` _(proposed)_.
- **Policing and voting** have their own topics (`judicial-police-accountability`, `voting-rights`)
  → `adjacent` here.
- **Commemorative resolutions** (a holiday, an apology, a history month) → `rhetorical`.
- **Task forces and disparity studies** → V4 `study-directive`.
- **Protected traits other than race.** Rungs 2–4 speak of civil rights in general, so a
  sex, disability or sexual-orientation anti-discrimination measure is `on-question` for them; rungs
  1 and 5 are about race only _(proposed)_.
- **Preemption (codebook V2, H12).** A state law that forbids **local** governments to run a
  programme → `adjacent`. A state law that binds the state's own bodies too sets the rule →
  `on-question` _(proposed)_.
- **Budget and omnibus votes** → V4 `multi-subject`.


### topic_key: data-centers
topic_id: 4559b513-0fd8-4ed1-babd-f3b554162f40  served_revision_id: c48a03d6-b972-4f27-9a8a-d41b07f4a929
Question: How should government manage the growth of large-scale data centers?
  1. Imposing a moratorium on new data center construction until energy infrastructure can support demand without raising costs for residential ratepayers
  2. Barring utilities from passing any data center energy infrastructure costs to residential customers
  3. Allowing data center development with impact assessments, energy cost-sharing agreements, and community benefit requirements before approval
  4. Encouraging data center development through streamlined permitting while requiring transparency about projected energy demand and rate impacts
  5. Welcoming data center investment with minimal regulatory barriers, trusting that economic growth and tax revenue will benefit all residents

#### Annex

# data-centers — served revision c48a03d6-b972-4f27-9a8a-d41b07f4a929 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should government manage the growth of large-scale data centers?"

**Orientation:** standard. Rung 1 stops new construction, rung 5 welcomes it with minimal rules. The
rungs order **how many conditions government puts on new data centres**: a pause, a ratepayer
cost bar, pre-approval conditions, disclosure with fast permits, almost none.

**Levels with a lever:** federal, local, state. Cost allocation is set by the
state utility commission and legislature (federal for transmission); siting and permits are local
and state; tax treatment is state and local.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "large load", "large-load tariff", "hyperscale", "co-location", "behind-the-meter",
"ratepayer protection", "cost allocation", "cost causation", "community benefit agreement" (CBA),
"impact assessment", "sales tax exemption" (equipment), "microgrid", "public utility commission" (PUC),
"FERC".

1. **"Imposing a moratorium on new data center construction until energy infrastructure can support
   demand without raising costs for residential ratepayers"**
   - Means: no new data centres are built until the grid can serve them without raising household
     power bills.
   - Operative clauses: [a] a moratorium on new construction; [b] lifted when energy infrastructure can
     carry the demand without raising residential costs.
   - Establishing evidence looks like: a prime-sponsored moratorium that holds until a utility
     commission reports on capacity and costs is `chair-shaped` (codebook calibration A1).
   - Levels that hold a lever: state; local (a local construction or zoning moratorium); federal
     rarely.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK when the moratorium has another purpose (water, noise, land use,
     waiting for new zoning rules). [b] ties the pause to energy and ratepayer cost; a pause for
     another reason → `direction-only` _(proposed)_.

2. **"Barring utilities from passing any data center energy infrastructure costs to residential
   customers"**
   - Means: the law forbids utilities to put any data-centre power costs on household bills.
   - Operative clauses: [a] a legal bar on utilities; [b] covering **any** data-centre energy
     infrastructure cost; [c] to residential customers.
   - Establishing evidence looks like: operative text that forbids a utility to recover data-centre
     infrastructure costs from residential rates. [b] is an absence clause ("any"): the text must
     bar all such costs, not a share (V4.2).
   - Levels that hold a lever: state (legislature, utility commission); federal (transmission cost
     allocation); local only for a municipal utility.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a **large-load tariff** that makes data centres pay a set
     share, a minimum bill or a long contract is a cost-sharing arrangement, not a full bar →
     rung 3 clause [b] at most _(proposed)_.
   - Self-supply of power is no longer part of this rung. A rule that data centres build or buy their
     own generation does not reach rung 2 → `direction-only` _(proposed)_.

3. **"Allowing data center development with impact assessments, energy cost-sharing agreements, and
   community benefit requirements before approval"**
   - Means: data centres may be built, but only after approval conditions on impacts, energy costs and
     community benefits are met.
   - Operative clauses: [a] development allowed; [b] an impact assessment; [c] an energy cost-sharing
     agreement; [d] community benefit requirements; [e] all as conditions **before approval**.
   - Establishing evidence looks like: a siting or approval statute that makes all three conditions a
     precondition of approval. Compound: one or two of the three → `compound-partial` (V4.2).
   - Levels that hold a lever: state; local (conditions on a permit or development agreement).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a bill that **orders a study** of data-centre impacts is not
     an impact assessment made a condition of approval → `study-directive`.
   - Commonly confused with rung 4 because both allow development with conditions. Rung 3 conditions
     approval; rung 4 speeds approval and asks only for disclosure.

4. **"Encouraging data center development through streamlined permitting while requiring transparency
   about projected energy demand and rate impacts"**
   - Means: permits come faster, and developers must disclose expected power demand and its effect on
     rates.
   - Operative clauses: [a] streamlined permitting; [b] required disclosure of projected energy demand
     and rate impacts.
   - Establishing evidence looks like: a permitting statute that shortens or simplifies approval
     **and** a disclosure duty on projected demand and rate impacts. Compound: one side only →
     `compound-partial` (V4.2) _(proposed)_.
   - Levels that hold a lever: state; local; federal (federal permits, federal land).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a **reporting duty that is not about projected demand and
     rate impacts** does not meet [b], and has no permitting clause → BLANK `direction-only`.
   - A provision about **large-load utility customers** that never names data centers is not about
     data centers → BLANK `no-evidence` _(ruled 2026-10-01)_.
   - A local project approval "with environmental safeguards" says nothing about permitting speed,
     disclosure or rate impacts → `adjacent` (codebook V2, Moore / data-centers). Coding it as rung 4
     is an unevidenced chair.

5. **"Welcoming data center investment with minimal regulatory barriers, trusting that economic growth
   and tax revenue will benefit all residents"**
   - Means: government invites data centres and keeps rules on them to a minimum, on the view that the
     growth benefits everyone.
   - Operative clauses: [a] welcome investment; [b] minimal regulatory barriers; [c] the stated reason
     — growth and tax revenue benefit all residents.
   - Establishing evidence looks like: own words that call for minimal rules on data centres. [c] is a
     reason; own words can give it, an instrument cannot _(proposed)_. One deregulation law cannot
     show "minimal" — that is a magnitude (codebook V2, refined 2026-09-26) → `direction-only`.
   - Levels that hold a lever: state; local; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because streamlined permits are also fewer barriers. Rung 4 keeps a
     disclosure duty; a passage that keeps one is not rung 5.
   - **Tax incentives** are no longer part of this rung. A data-centre tax exemption or incentive shows
     the welcoming side only → `direction-only` _(proposed)_.

**Hard cases:**
- **Local control (codebook H11).** "If a community doesn't want a data center, there shouldn't be
  someone forcing that data center in there" names no mechanism → V7 `direction`. As stance evidence it
  says which level should decide, not what the rule is → `adjacent` _(proposed, by analogy with Q10)_.
- **Preemption (codebook V2, H12).** A state law that forbids local moratoria or local data-centre
  zoning rules decides which level may act → `adjacent`.
- **Water, noise and land-use rules** that say nothing about energy demand, costs or permitting speed →
  `adjacent` _(proposed)_.
- **Budget and omnibus votes** with a data-centre item → V4 `multi-subject`.


### topic_key: economic-development
topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53  served_revision_id: af855dba-96f3-4fa0-beb7-43c5edb3f499
Question: How should government attract businesses and support economic development?
Evidence basis at this seat's level (federal): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


### topic_key: growth-and-development
topic_id: fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4  served_revision_id: 65e8ffd5-5aac-4d40-8862-a321949eafa4
Question: How should government manage population growth and new development?
Evidence basis at this seat's level (federal): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


### topic_key: homelessness
topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a  served_revision_id: 6958fa99-e317-45d7-8076-d11a0a78c897
Question: How should government address people sleeping or camping in public spaces?
  1. Protecting the right to sleep and shelter in public spaces, with no penalties of any kind
  2. Decriminalizing public sleeping and camping in public spaces
  3. Allowing enforcement only when adequate shelter beds are available, with citations diverting people to services rather than the criminal justice system
  4. Prohibiting encampments on public property, enforced through graduated warnings and civil penalties
  5. Banning public camping and sleeping with criminal penalties to maintain public safety and order

#### Annex

# homelessness — served revision 6958fa99-e317-45d7-8076-d11a0a78c897 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(ruled 2026-08-31)_ carry an operator ruling (Chris
Andrews, recorded with the chair-4 re-audit). Lines marked _(proposed)_ are a drafter's reading, not
yet ruled. Lines marked _(ruled 2026-10-01)_ carry a later ruling. No `_owed:_` line is open.

**Question:** "How should government address people sleeping or camping in public spaces?"

**Orientation:** standard. Rung 1 protects public sleeping with no penalty, rung 5 bans it with
criminal penalties. The rungs order **the penalty** for sleeping or camping in public: none, no
criminal penalty, enforcement only when shelter exists, civil penalties, criminal penalties.

**Levels with a lever:** federal, local, state. The lever is the local
ordinance and the state statute that sets or forbids camping rules. Federal officeholders act only on
federal land and through conditions on grants _(proposed)_.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "camping ban", "unauthorized camping", "public camping", "sit-lie", "encampment
sweep" / "clearance" / "abatement", "move-along order", "right to rest", "infraction",
"Class C misdemeanor", "citation", "diversion", "shelter-bed availability", "Martin v. Boise",
"City of Grants Pass v. Johnson" (2024).

1. **"Protecting the right to sleep and shelter in public spaces, with no penalties of any kind"**
   - Means: people may sleep and shelter in public spaces, and the law imposes no penalty of any
     kind for it.
   - Operative clauses: [a] a protected right to sleep and shelter in public; [b] no penalties of any
     kind, civil or criminal.
   - Establishing evidence looks like: a right-to-rest bill or ordinance that protects public
     sleeping and forbids fines and arrests for it; own words calling for both. [b] is an absence
     clause and must be stated (V4.2 "Silence is not a clause").
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because decriminalizing removes criminal penalties only. A measure
     that keeps a fine or a civil order is not "no penalties of any kind".
   - Housing and service spending is no longer part of this rung. A budget shift from enforcement to
     housing does not move a person to rung 1 → `adjacent` _(proposed)_.

2. **"Decriminalizing public sleeping and camping in public spaces"**
   - Means: sleeping and camping in public are no longer crimes.
   - Operative clauses: [a] remove criminal penalties for public sleeping and camping.
   - Establishing evidence looks like: a repeal of a criminal camping ordinance, or a vote against
     creating one; own words against criminal penalties for sleeping in public.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a law that turns a camping crime into a civil fine both
     decriminalizes (rung 2) and prohibits with civil penalties (rung 4). A law that turns a camping crime
     into a civil fine still prohibits, with a civil penalty → rung 4 (see the 2026-08-31 penalty-type
     ruling) _(ruled 2026-10-01)_.
   - A No on a criminal ban does not separate 1, 2, 3 and 4 → `direction-only`.

3. **"Allowing enforcement only when adequate shelter beds are available, with citations diverting
   people to services rather than the criminal justice system"**
   - Means: camping rules may be enforced only when a shelter bed is open, and a citation sends the
     person to services, not to court.
   - Operative clauses: [a] enforcement only when adequate shelter beds are available; [b] citations
     divert to services rather than the criminal justice system.
   - Establishing evidence looks like: an ordinance that conditions enforcement on an available bed
     **and** routes citations to services. Compound: one side only → `compound-partial` (V4.2).
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because many enforcement ordinances offer shelter first. An offer
     of shelter before a penalty is not [a] unless the law forbids enforcement when no bed is
     available _(proposed)_.

4. **"Prohibiting encampments on public property, enforced through graduated warnings and civil
   penalties"**
   - Means: encampments on public property are prohibited; enforcement starts with warnings and
     ends in civil penalties, not jail.
   - Operative clauses: [a] prohibit encampments on public property; [b] graduated warnings;
     [c] civil penalties.
   - Establishing evidence looks like: a camping prohibition whose penalty is a fine or other civil
     sanction, reached after warnings. A **fine-only Class C misdemeanor** is the civil tier → rung 4
     _(ruled 2026-08-31)_.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: Texas HB 1925 (2021), a statewide camping ban with a fine-only
     Class C misdemeanor, stayed on this rung in the 2026-08-31 re-audit. Check [b] in the text the
     person acted on.
   - Commonly confused with rung 5: the line is **penalty type**. Jail, arrest or prosecution → rung
     5; a fine only → rung 4 _(ruled 2026-08-31)_.
   - Shelter mandates are no longer part of this rung. A requirement to keep shelter beds does not
     move a person to rung 4 → `adjacent` _(proposed)_.

5. **"Banning public camping and sleeping with criminal penalties to maintain public safety and
   order"**
   - Means: public camping and sleeping are banned, and breaking the ban can lead to jail, arrest or
     prosecution.
   - Operative clauses: [a] ban public camping and sleeping; [b] criminal penalties. "To maintain
     public safety and order" is a purpose, not a clause the instrument must state _(proposed)_.
   - Establishing evidence looks like: a camping ordinance or statute with a misdemeanor that carries
     possible jail time, or that authorizes arrest.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: the Fremont camping ordinance (misdemeanor, up to $1,000 and six
     months in jail), Henderson Ordinance 3967, Colorado Springs Ordinance 26-08 (up to 10 days in
     jail); all moved to rung 5 in the 2026-08-31 re-audit.
   - Commonly confused with rung 4: see rung 4. Pairing a jail-backed ban with services, or saying it
     "does not criminalize", does not keep it at rung 4: the instrument's penalty decides _(ruled
     2026-08-31)_.

**Hard cases:**
- **Clearances and sweeps** with notice but no penalty on the person → `compound-partial` for rung 4
  (prohibition and warnings, no penalty clause) _(proposed)_.
- **Shelter, housing and outreach spending** with no penalty rule → `adjacent` (the
  homelessness-response topic covers funding).
- **Preemption (codebook V2, H12).** A state law that forbids cities to allow camping, or orders
  them to enforce a ban, decides which level acts → `adjacent`, unless the state law itself sets the
  penalty (then code that penalty) _(proposed)_.
- **Court rulings** (Martin v. Boise, Grants Pass) are not a person's act. Own words about a ruling
  count only when they name a penalty rule.
- **Budget and omnibus votes** with an enforcement item → V4 `multi-subject`.


### topic_key: jail-capacity
topic_id: c267e137-0ff9-4e7d-9d13-e3cea1756cd0  served_revision_id: 7992fadf-a24c-4f73-bd34-76b5bca4764b
Question: How should government respond to jail overcrowding and criminal justice demand?
Evidence basis at this seat's level (federal): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


### topic_key: judicial-criminal-justice
topic_id: 9db07b16-1076-4b7d-ad89-ebe7b51f4336  served_revision_id: c334f475-05bd-48ba-9d25-f4de593a3f15
Question: When someone breaks the law, how should the system respond?
  1. Focus on support and treatment, not punishment.
  2. Give the person a chance to make things right through service or restitution, rarely punishment.
  3. Each situation is different — some people need support, some need consequences.
  4. Breaking the law needs to have real consequences — accountability is the priority.
  5. Impose the toughest penalties the law allows.

#### Annex

# judicial-criminal-justice — served revision c334f475-05bd-48ba-9d25-f4de593a3f15 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "When someone breaks the law, how should the system respond?"

**Orientation:** standard. Rung 1 rejects punishment (support and treatment), rung 5 is the harshest
penalty the law allows. All five rungs sit on one spine: **the role of punishment in the response to
a person who broke the law**. They are general orientations, not a view on one offense.

**Levels with a lever:** federal, judicial, state. A judge acts through
sentencing; a prosecutor through charging and sentence requests; a legislator through sentencing law.
The rungs are written as orientations so all three can be coded against the same text.

**Asked at:** federal, state, judicial (`compass_topic_roles`, CA_0302).

**Synonyms:** "diversion", "drug court", "mental health court", "problem-solving" or "collaborative"
court, "treatment in lieu of", "restorative justice", "restitution", "community service",
"probation", "alternatives to incarceration", "rehabilitation", "sentencing guidelines", "mandatory
minimum", "sentence enhancement", "three strikes", "serious felony", "truth in sentencing", "earned
time" or "good-time credit".

1. **"Focus on support and treatment, not punishment."**
   - Means: the response should help the person, and punishment should not be the aim.
   - Operative clauses: [a] support and treatment; [b] not punishment.
   - Establishing evidence looks like: own words that put treatment in place of punishment as the
     general response; a record that replaces penalties with treatment across many offenses.
     [b] is an absence clause: a treatment programme that keeps jail as a sanction does not say "not
     punishment" (V4.2 "Silence is not a clause") → `direction-only` _(proposed)_.
   - Levels that hold a lever: judicial (sentencing), state and federal (sentencing law).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because both reduce punishment. Rung 1 names **treatment**; rung
     2 names **making things right** (service, restitution).

2. **"Give the person a chance to make things right through service or restitution, rarely
   punishment."**
   - Means: the person repairs the harm; punishment is a rare last resort.
   - Operative clauses: [a] make things right through service or restitution; [b] rarely punishment.
   - Establishing evidence looks like: a restorative-justice or restitution-first record or own words,
     **plus** a statement or act that keeps punishment for rare cases. Compound: one side only →
     `compound-partial` (V4.2) _(proposed)_.
   - Levels that hold a lever: judicial, state, federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.

3. **"Each situation is different — some people need support, some need consequences."**
   - Means: the response depends on the person and the offense, with neither support nor punishment
     the default.
   - Operative clauses: [a] case by case; [b] support for some, consequences for others.
   - Establishing evidence looks like: own words that state the case-by-case orientation as the
     person's general view.
   - Levels that hold a lever: judicial, state, federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because **a bill that lowers some penalties and keeps others** looks
     like "some support, some consequences". It is not: such a bill is consistent with rungs 2, 3 and
     4, and a mixed record is not a stated orientation → `direction-only`. Rung 3 is not the place for
     a record that points both ways (V4.2 "Ruling out the other rungs is not evidence").

4. **"Breaking the law needs to have real consequences — accountability is the priority."**
   - Means: there must be a real penalty, and holding the person to account comes first.
   - Operative clauses: [a] real consequences; [b] accountability is the priority.
   - Establishing evidence looks like: own words that make consequences the general priority **plus**
     something that excludes rung 5 (the person does not seek the maximum as a rule).
   - Levels that hold a lever: judicial, state, federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because a penalty increase points toward both.

5. **"Impose the toughest penalties the law allows."**
   - Means: seek or give the maximum penalty as the general rule.
   - Operative clauses: [a] the toughest penalties; [b] the law allows (the maximum available).
   - Establishing evidence looks like: own words that the maximum should be the rule; for a judge, a
     stated sentencing practice at the top of the range; for a prosecutor, a policy of seeking the
     maximum. For a legislator, whose act is to set the range, not to impose a sentence, own words are
     the main route _(proposed)_.
   - Levels that hold a lever: judicial (sentencing, charging); state and federal mostly through own
     words _(proposed)_.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **One offense.** A bill that raises or lowers the penalty for **one** offense is on-question and
  shows direction, but one offense cannot set the person's general response to lawbreaking →
  `direction-only`, not `no-evidence`.
- **Victims' rights.** A bill about victims' notice, compensation or participation is about victims,
  not the response to the person who broke the law → `adjacent`; BLANK `no-evidence` when nothing else survives.
- **Pretrial measures** (bail, detention) come before any finding that the person broke the law →
  `adjacent` _(proposed)_.
- **Record clearing** (expungement, sealing) and re-entry aid after a sentence is served → `adjacent`
  _(proposed)_.
- **Policing and jail capacity** have their own topics → `adjacent`.
- **The death penalty** is one penalty for a few offenses → `direction-only` _(proposed)_.
- **Budget and omnibus votes** with a sentencing item → V4 `multi-subject`.
- **Judges.** One sentence in one case is set inside a legal range → `direction-only` at most. A
  stated sentencing philosophy in a questionnaire is `statement-answer` (V3). Ethics rules bar
  candidates from promising outcomes; "tough on crime" or "second chances" with no orientation named
  → `rhetorical` _(proposed)_.


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


### topic_key: redistricting
topic_id: 48cc9585-ec22-4f53-8d42-6839828dd36f  served_revision_id: c7f973fc-33f5-4570-bfe2-bff4ac6141cc
Question: Who should draw electoral district boundaries and how should they be determined?
  1. independent citizens' commissions with no elected officials involved at any level.
  2. independent redistricting commissions with equal representation from both major parties.
  3. bipartisan legislative committees with strict rules requiring supermajority approval.
  4. state legislatures with court oversight to prevent extreme partisan bias.
  5. the party that controls the state legislature without outside interference.

#### Annex

# redistricting — served revision c7f973fc-33f5-4570-bfe2-bff4ac6141cc (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "Who should draw electoral district boundaries and how should they be determined?"

**Orientation:** standard. Rung 1 puts the map-drawer furthest from elected officials, rung 5 gives
the maps to the legislative majority with no check. The rungs order **how insulated the map-drawer is
from the people elected under the maps**. Each rung names an institution and the constraint that
separates it from its neighbour.

**Levels with a lever:** federal, state. The lever is state: constitutions and
statutes say who draws the maps. The federal lever is national redistricting-standards legislation;
for rungs 2 and 3 a federal official's evidence is usually own words (review 2026-08-31, scope kept).

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "independent redistricting commission" (IRC), "citizens redistricting commission",
"advisory commission", "backup commission", "apportionment", "gerrymandering", "partisan fairness",
"communities of interest", "Fair Districts", "mid-decade redistricting", "Elections Clause",
"independent state legislature", "supermajority".

1. **"independent citizens' commissions with no elected officials involved at any level."**
   - Means: ordinary citizens draw the maps, and elected officials take no part at any step.
   - Operative clauses: [a] an independent citizens' commission draws the maps; [b] no elected official
     is involved at any step (choosing members, drawing, approving).
   - Establishing evidence looks like: a measure that creates such a commission and gives elected
     officials no role; own words for it. [b] is an absence clause and must be stated (V4.2).
   - Levels that hold a lever: state; federal (national standards that require such commissions).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because many citizens' commissions also seat equal numbers from the
     two largest parties. A citizens' commission with equal party seats, where legislative leaders take
     part in choosing members, is rung 2: elected officials are involved, so rung 1's absence clause
     fails _(ruled 2026-10-01)_.

2. **"independent redistricting commissions with equal representation from both major parties."**
   - Means: a commission outside the legislature draws the maps, with equal seats for the two largest
     parties.
   - Operative clauses: [a] an independent commission draws the maps; [b] equal representation of the
     two major parties.
   - Establishing evidence looks like: a measure that creates a commission with equal party seats.
   - Levels that hold a lever: state; federal (own words, mostly).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - An **advisory** commission whose maps the legislature may change or reject is not independent →
     not rung 1 or 2; `direction-only` _(proposed)_.

3. **"bipartisan legislative committees with strict rules requiring supermajority approval."**
   - Means: legislators draw the maps in a committee of both parties, and the maps need a supermajority.
   - Operative clauses: [a] a bipartisan legislative committee; [b] supermajority approval.
   - Establishing evidence looks like: a rule or constitutional text that gives the maps to a
     bipartisan legislative committee **and** requires a supermajority. Compound: one side only →
     `compound-partial` (V4.2).
   - Levels that hold a lever: state; federal (own words, mostly).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because both keep the maps in the legislature. Rung 3's check is
     internal (bipartisanship and a supermajority); rung 4's is a court.

4. **"state legislatures with court oversight to prevent extreme partisan bias."**
   - Means: the legislature draws the maps, and courts can strike maps with extreme partisan bias.
   - Operative clauses: [a] the legislature draws; [b] courts can review for partisan bias.
   - Establishing evidence looks like: a measure that leaves the maps with the legislature and sets
     partisan-fairness standards that courts enforce; own words for that arrangement _(proposed)_.
   - Levels that hold a lever: state; federal (national standards enforceable in court).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with BLANK because a **lawsuit asking a court to strike a map** for partisan
     bias shows [b] but not [a]: the plaintiff may want a commission → `direction-only` _(proposed)_.

5. **"the party that controls the state legislature without outside interference."**
   - Means: the legislative majority draws the maps, and no commission or court may change them.
   - Operative clauses: [a] the legislative majority draws; [b] no outside check (no commission, no
     court review).
   - Establishing evidence looks like: a filed lawsuit claiming the Elections Clause gives map-drawing
     "exclusively to state legislatures" is a `record` whose claim is the position (codebook H7,
     Owens / redistricting). Quote the claim as `provision_quote`. If the claim attacks a commission
     but accepts court review, it does not exclude rung 4 → `direction-only` _(proposed)_.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **A change of map-drawer that is not permanent** fits no single rung → BLANK `direction-only`. The measure's own findings or declarations are part of the same
  record, not a separate statement, so there is no `record-vs-statement-conflict`.
- **A vote for a particular map** is about the map's lines, not about who should draw → `adjacent`
  _(proposed)_.
- **Campaign work for a commission initiative** is not a vote. Code the person's own words; an old role
  sourced only to an encyclopedia → V3 `not-evidence`, and the row goes to review (codebook V5, Moore /
  redistricting).
- **Omnibus election bills** that include a commission mandate → V4 `multi-subject`.
- **Preemption.** This ladder is itself about which body decides, so a measure that moves map-drawing
  between bodies is `on-question` (codebook V2, Q10 exception).


### topic_key: religious-freedom
topic_id: 6b9ba6d9-1001-43f5-b073-4d37130696fd  served_revision_id: dfbd847a-294c-49d2-9ac3-69270ea03054
Question: How should the law balance religious freedom with protection from discrimination?
  1. prohibit religious exemptions from civil rights and anti-discrimination laws.
  2. protect religious freedom while ensuring it doesn't override anti-discrimination protections in employment and housing.
  3. balance protecting religious practices with maintaining equal treatment under the law for all citizens.
  4. protect religious freedom and allow faith-based exemptions from laws that conflict with sincere religious beliefs.
  5. strongly protect religious freedom and allow religious organizations complete autonomy in their operations and hiring practices.

#### Annex

# religious-freedom — served revision dfbd847a-294c-49d2-9ac3-69270ea03054 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should the law balance religious freedom with protection from discrimination?"

**Orientation:** standard. Rung 1 gives no religious exemption from anti-discrimination law, rung 5
gives religious organisations complete autonomy. The rungs order **how wide religious exemptions
from anti-discrimination law are**: none, limited, balanced, general, complete.

**Levels with a lever:** federal, local, state. Federal and state law set the
anti-discrimination rules and the general exemption statutes (RFRA). Cities and counties pass their
own human-rights ordinances, with or without religious exemptions, so local officeholders hold a
lever on rungs 1–3; general exemption statutes (rungs 4–5) are state and federal.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302).

**Synonyms:** "Religious Freedom Restoration Act" (RFRA, federal and state versions), "free
exercise", "compelling interest" and "least restrictive means", "substantial burden", "sincerely
held religious belief", "conscience protection", "religious employer exemption" (Title VII section
702), "ministerial exception", "religious liberty", "SOGI" (sexual orientation and gender identity),
"public accommodations", "human rights ordinance".

1. **"prohibit religious exemptions from civil rights and anti-discrimination laws."**
   - Means: no one may use religion to be excused from anti-discrimination law.
   - Operative clauses: [a] prohibit religious exemptions; [b] from civil rights and
     anti-discrimination laws.
   - Establishing evidence looks like: a bill or vote that removes the existing religious exemptions
     from anti-discrimination law; own words that no religious exemption should apply.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - **Church–state separation is no longer part of this rung** (S1 rung 1 began "strictly separate
     religion from all public institutions"). School prayer, religious displays and public money for
     religious schools do not move a person along these rungs → `adjacent`. (The CA_0035 re-audit
     blanked Season 1 rows that rested on separation alone.)
   - A bill that bars religion (RFRA) as a defence to anti-discrimination claims but keeps the
     existing religious-organisation exemptions → rung 2: it keeps exemptions (not rung 1) and stops
     religion overriding the protections (rung 2's text) _(ruled 2026-10-01)_.
   - Commonly confused with rung 2 because limiting **one** exemption route is not prohibiting all
     exemptions.

2. **"protect religious freedom while ensuring it doesn't override anti-discrimination protections in
   employment and housing."**
   - Means: religious freedom is protected, but it does not excuse discrimination in jobs or housing.
   - Operative clauses: [a] protect religious freedom; [b] religion does not override
     anti-discrimination protection in employment and housing. Compound: one side only →
     `compound-partial` (V4.2).
   - [b] names two domains. A passage that states the override rule for one of them meets [b]
     _(proposed)_.
   - Establishing evidence looks like: a measure whose text keeps a religious-organisation exemption
     **and** states that religion is no defence to job or housing discrimination; own words that say
     both.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a law that adds anti-discrimination protection **and**
     religious exemptions together looks like a "balance". When the protection holds in employment
     and housing and the exemption is limited to religious organisations → rung 2 _(proposed)_.

3. **"balance protecting religious practices with maintaining equal treatment under the law for all
   citizens."**
   - Means: weigh religious practice and equal treatment against each other, case by case, with no
     fixed rule for either.
   - Operative clauses: [a] protect religious practice; [b] maintain equal treatment; [c] a balance,
     not a categorical rule.
   - Establishing evidence looks like: own words that describe weighing the two in each case. A
     measure whose exemptions and protections are each limited by context (by type of organisation,
     by service, by domain) _(proposed)_.
   - Levels that hold a lever: federal; state; local.
   - Known chair-shaped instruments: _(none on file)_.
   - "Both are important" names no clause → `rhetorical`.
   - Commonly confused with rung 2: see rung 2. Commonly confused with rung 4: see rung 4.

4. **"protect religious freedom and allow faith-based exemptions from laws that conflict with sincere
   religious beliefs."**
   - Means: a person or organisation may be excused from a law that conflicts with a sincere
     religious belief.
   - Operative clauses: [a] protect religious freedom; [b] allow exemptions from laws in general that
     conflict with sincere belief (individuals and businesses, not only religious bodies).
   - Establishing evidence looks like: authoring or a vote on a general exemption statute (a state
     RFRA); a conscience law that excuses individuals or businesses from anti-discrimination duties.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - A RFRA (strict-scrutiny test: an exemption unless the government shows a compelling interest)
     → rung 4: the exemption is the default; the compelling-interest test limits it _(ruled 2026-10-01)_.
   - An exemption for **one** service or field (adoption agencies, wedding services, one medical
     procedure) shows the exemption side but not "laws that conflict" in general →
     `direction-only` _(proposed)_.

5. **"strongly protect religious freedom and allow religious organizations complete autonomy in
   their operations and hiring practices."**
   - Means: religious organisations decide their own operations and hiring, free of
     anti-discrimination law.
   - Operative clauses: [a] religious organisations; [b] complete autonomy in operations; [c] and in
     hiring. "Complete" is an absence clause: the passage must state it (V4.2).
   - Establishing evidence looks like: own words or an instrument that exempts religious
     organisations from **all** employment and operating rules on discrimination, not only religion-
     based hiring.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Support for the **existing** co-religionist hiring exemption or the ministerial exception is
     not "complete autonomy" → `direction-only` _(proposed)_.
   - Commonly confused with rung 4 because rung 4 is about exemptions for anyone with a sincere
     belief; rung 5 is about organisations' autonomy.

**Hard cases:**
- **Marriage ceremonies.** A clause that lets religious organisations decline to perform marriages
  is coded on `same-sex-marriage`. Here it is a single-service exemption → `direction-only`
  _(proposed)_.
- **Religious-school funding and vouchers** → `adjacent` (church–state, not exemptions).
- **Pandemic limits on worship gatherings** are about public-health rules, not anti-discrimination
  law → `adjacent` _(proposed)_.
- **Amicus briefs and lawsuits** are `record` (Q8); the claim must be about an exemption from
  anti-discrimination law, not a procedural point.
- **Preemption (codebook V2, H12)** → `adjacent`.
- **Budget and omnibus votes** → V4 `multi-subject`.


### topic_key: rent-regulation
topic_id: c308e8e8-caac-44f5-ab04-dbfecf40bbe2  served_revision_id: 6fa44a68-8006-48e9-b562-6b5e61d58693
Question: What role should government play in regulating rents and protecting tenants?
Evidence basis at this seat's level (federal): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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


### topic_key: same-sex-marriage
topic_id: c5ab4eab-702f-49b8-9277-8ea53f3835c6  served_revision_id: 8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f
Question: What legal recognition should same-sex marriages receive?
  1. Guarantee same-sex couples full legal equality — equal marriage plus protection from discrimination (such as in jobs and housing).
  2. Guarantee same-sex marriage the same benefits and protections as any other marriage.
  3. Allow same-sex marriage, but protect religious organizations' right to decline to perform or host these marriages.
  4. Recognize civil unions for same-sex couples, but reserve marriage for opposite-sex couples.
  5. Make same-sex marriage illegal and define marriage as only between one man and one woman.

#### Annex

# same-sex-marriage — served revision 8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "What legal recognition should same-sex marriages receive?"

**Orientation:** standard. Rung 1 is full legal equality, rung 5 makes same-sex marriage illegal. The
rungs order **how much legal equality** same-sex couples get: marriage plus anti-discrimination
protection, equal marriage, marriage with a religious carve-out, civil unions only, nothing. (The S1
rung "let each state decide" is gone: who decides is not on this ladder.)

**Levels with a lever:** federal, state. Since 2015 every state must license
and recognise same-sex marriages, so the live levers are federal recognition law, state
constitutional amendments (to repeal or keep inactive bans), state anti-discrimination law, and
religious-exemption clauses.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "marriage equality", "Respect for Marriage Act" (RFMA, 2022), "Defense of Marriage Act"
(DOMA, 1996), "Obergefell", "civil union", "domestic partnership", "one man and one woman",
"freedom to marry", "sexual orientation" in anti-discrimination law, "SOGI", "Equality Act".

1. **"Guarantee same-sex couples full legal equality — equal marriage plus protection from
   discrimination (such as in jobs and housing)."**
   - Means: equal marriage, and a legal bar on discrimination against same-sex couples outside
     marriage too.
   - Operative clauses: [a] equal marriage; [b] protection from discrimination based on sexual
     orientation (jobs, housing and similar). Compound: one side only → `compound-partial` (V4.2);
     but see rung 2 for marriage-only evidence.
   - Establishing evidence looks like: a marriage passage **plus** a record on a broad
     sexual-orientation anti-discrimination instrument (employment, housing, public
     accommodations); or one instrument that does both.
   - [b] needs a broad anti-discrimination instrument. Bans on conversion therapy, hate-crime laws,
     and marriage-only votes do not meet [b] (the bar used in the CA_0100 re-audit, 2026-09-01).
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2: see rung 2.

2. **"Guarantee same-sex marriage the same benefits and protections as any other marriage."**
   - Means: same-sex marriage is legal and equal to any other marriage in law.
   - Operative clauses: [a] same-sex marriage is guaranteed; [b] the same benefits and protections.
   - Establishing evidence looks like: authoring or carrying a measure that secures the right to
     marry, or full recognition of same-sex marriages, in law.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - **A measure that secures the right to marry and has no anti-discrimination clause is rung 2,
     not rung 1.** It meets every clause of rung 2; it does not need a second passage that rejects
     anti-discrimination law.
   - A Yes on a recognition bill whose religious section only **saves** existing protections (for
     example the RFMA) → rung 2. The operative section governs (V4.1); a savings clause does not show
     that the person insists on the carve-out that rung 3's "but" names. Rung 3 needs own words that
     make the right to decline part of the position _(ruled 2026-10-01)_.

3. **"Allow same-sex marriage, but protect religious organizations' right to decline to perform or
   host these marriages."**
   - Means: same-sex marriage is legal, and religious organisations need not perform or host one.
   - Operative clauses: [a] allow same-sex marriage; [b] protect religious organisations' right to
     decline to perform or host. Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: own words that accept same-sex marriage and name the
     religious-organisation right to decline as part of the position.
   - Levels that hold a lever: federal; state.
   - Known chair-shaped instruments: _(none on file)_.
   - **[real] (codebook V5, H4).** A candidate's debate answer that they "would have voted yes" on the
     RFMA → `statement-answer`; the instrument's operative content (recognition) is the position →
     rung 2, unless the person's own words stress the religious exemption _(ruled 2026-10-01)_. Do not carry the S1
     reading forward.
   - [b] covers religious **organisations** and ceremonies. An exemption for businesses or
     individuals (vendors, clerks) is wider than [b] → `direction-only` here _(proposed)_; code it on
     `religious-freedom`.

4. **"Recognize civil unions for same-sex couples, but reserve marriage for opposite-sex couples."**
   - Means: same-sex couples get civil unions, not marriage.
   - Operative clauses: [a] recognise civil unions; [b] reserve marriage for opposite-sex couples.
     Compound: one side only → `compound-partial`.
   - Establishing evidence looks like: a civil-union statute plus a marriage definition; own words for
     civil unions but not marriage.
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Older records count if chair-shaped (V5: a record has no age limit), but a later passage that
     differs governs (`superseded-by-later`).

5. **"Make same-sex marriage illegal and define marriage as only between one man and one woman."**
   - Means: the law permits only opposite-sex marriage and recognises nothing else as marriage.
   - Operative clauses: [a] same-sex marriage not legally permitted; [b] marriage defined as one man
     and one woman.
   - Establishing evidence looks like: a constitutional amendment or statute that defines marriage
     as one man and one woman **and** bars recognising other unions; own words calling for that.
   - Levels that hold a lever: federal (a constitutional amendment); state (constitutional
     amendments).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a definition-only measure meets rung 4 [b] too. If it
     also bars civil unions → rung 5; if it leaves civil unions in place or creates them → rung 4;
     if it is silent on civil unions → rung 5 when it bars recognition, otherwise `direction-only`
     _(proposed)_.
   - A federal definition for federal purposes only (DOMA) does not make same-sex marriage illegal →
     `direction-only` _(proposed)_.

**Hard cases:**
- **A No on repealing an inactive state ban** shows only a side → `direction-only` _(proposed)_.
- **Positions change.** Many officeholders voted one way before 2015 and another way later. The
  newest evidence governs (V5).
- **Transgender measures, conversion therapy, adoption rules** are other questions → `adjacent`
  _(proposed)_.
- **Preemption (codebook V2, H12)** → `adjacent`.
- **Budget and omnibus votes** → V4 `multi-subject`.


### topic_key: transportation-priorities
topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27  served_revision_id: 555f1618-fcdf-4e0b-8306-7eec8f4d0f4f
Question: Where should government focus its transportation investment?
Evidence basis at this seat's level (federal): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
  1. Prioritize pedestrian infrastructure, cycling networks, and public transit over new road capacity
  2. Invest equally in road capacity and in multimodal options like transit, bike lanes, and sidewalks
  3. Maintain roads while selectively adding transit connections and pedestrian improvements where density supports it
  4. Focus on road capacity and traffic flow; transportation investment should serve the majority who drive
  5. Prioritize highway access and abundant free parking as the foundation of local transportation policy

#### Annex

# transportation-priorities — served revision 555f1618-fcdf-4e0b-8306-7eec8f4d0f4f (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open. The season pin is an older revision
(`c48782d5-…`); coders code the served text below.

**Question:** "Where should government focus its transportation investment?"

**Orientation:** standard. Rung 1 puts walking, cycling and transit ahead of new road capacity, rung 5
puts highways and free parking first. The rungs order **the split of investment** between roads and
other modes.

**Levels with a lever:** local, state. States program highway and transit
money; cities and counties build streets, bike networks, local transit and public parking.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "complete streets", "multimodal", "active transportation", "road diet", "lane
reduction", "bus rapid transit" (BRT), "transit-priority lane", "level of service" (LOS), "vehicle
miles traveled" (VMT), "capacity expansion", "widening", "interchange", "state highway operation and
protection program", "parking minimums", "park-and-ride".

1. **"Prioritize pedestrian infrastructure, cycling networks, and public transit over new road
   capacity"**
   - Means: walking, cycling and transit come before adding road capacity.
   - Operative clauses: [a] invest in pedestrian, cycling and transit infrastructure; [b] over new
     road capacity.
   - Establishing evidence looks like: a record or own words that put these modes **ahead of** road
     capacity: redirect road-widening money to transit, a road diet or lane reduction, a stop to a
     highway expansion in favour of transit. A transit vote alone has no [b] → `direction-only`.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2 because support for transit is on both rungs. The discriminator is
     [b]: rung 1 takes from road capacity; rung 2 funds both _(proposed, from the 2026-08-30
     re-seat)_.
   - "Pedestrian, cycling and transit" names forms of one clause; one form is enough for [a]
     _(proposed)_.

2. **"Invest equally in road capacity and in multimodal options like transit, bike lanes, and
   sidewalks"**
   - Means: road capacity and other modes get equal weight.
   - Operative clauses: [a] invest in road capacity; [b] invest in multimodal options; [c] equally.
   - Establishing evidence looks like: own words for a balanced split, or a single-subject programme
     that funds both at a stated balance. A bill that adds multimodal duties but sets no split
     against road capacity → `direction-only` (gold).
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.
   - Commonly confused with rung 3 because both maintain roads and add other modes. Rung 2 adds road
     **capacity** and invests equally; rung 3 maintains roads and adds other modes only where density
     supports them.
   - The duty to include bike lanes and sidewalks on new road projects is no longer part of this rung.

3. **"Maintain roads while selectively adding transit connections and pedestrian improvements where
   density supports it"**
   - Means: keep the existing roads in repair, and add transit and walking improvements only where
     enough people live or work to use them.
   - Operative clauses: [a] maintain roads; [b] selectively add transit and pedestrian improvements;
     [c] where density supports it.
   - Establishing evidence looks like: own words or a programme that prefers repair over new capacity
     and limits new transit to dense areas. A repaving vote alone → `direction-only`.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 2: see rung 2.

4. **"Focus on road capacity and traffic flow; transportation investment should serve the majority who
   drive"**
   - Means: spending goes first to more road capacity and smoother traffic, for the people who drive.
   - Operative clauses: [a] focus on road capacity and traffic flow; [b] investment serves drivers
     first.
   - Establishing evidence looks like: a record or own words that put road widening, interchanges or
     signal timing ahead of other modes; a vote to move transit money to roads.
   - Levels that hold a lever: local; state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 because both put cars first. Rung 5 needs highways **and** free
     parking as the foundation.

5. **"Prioritize highway access and abundant free parking as the foundation of local transportation
   policy"**
   - Means: highway access and plenty of free parking come first.
   - Operative clauses: [a] prioritize highway access; [b] abundant free parking. Compound: one side
     only → `compound-partial` (V4.2) _(proposed)_.
   - Establishing evidence looks like: own words or records for both, for example a highway-access
     project and a vote to keep public parking free or to add public parking.
   - Levels that hold a lever: local (public parking, local access roads); state (highway access).
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4: see rung 4.

**Hard cases:**
- **Safety rules are not investment.** A law about how cyclists, drivers or pedestrians share the road
  (lane position, passing distance, right-of-way) does not say where money goes → BLANK
  `no-evidence` (gold).
- **Parking rules on private builders.** A law that removes or caps parking minimums for private
  development (for example near transit) is a land-use rule, not transportation investment →
  `adjacent` (gold). A law that **requires** parking minimums → `adjacent` too _(proposed)_.
- **Multimodal duties without a split.** SB 960 (a state bill in the gold set) adds complete-streets and
  transit-priority duties to state highway projects but sets no split against road capacity → BLANK
  `direction-only` (gold, `excluded_from_cert`).
- **Preemption (codebook V2, H12).** A state law that forbids local road diets or congestion pricing
  decides which level acts → `adjacent` _(proposed)_.
- **Large infrastructure packages** that fund roads and transit together (federal or state) → V4
  `multi-subject`; a Yea shows at most direction.
- **Transit fares and operations** (free-fare pilots, service hours) are investment in transit → on
  [a] of rung 1 or [b] of rung 2, never the split on their own → `direction-only` _(proposed)_.
- **Studies and corridor plans** → V4 `study-directive`.


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
snapshot_id: 65ec3ff1-e2f6-5bfb-85f5-ab4a5b1009c2
source_kind: own-site (the person's own site or account)
url: https://www.erinhouchin.com/issues

Erin Houchin on the Issues &mdash; Erin Houchin for Congress 0 Skip to Content ABOUT ISSUES VOLUNTEER CONTACT DONATE Open Menu Close Menu ABOUT ISSUES VOLUNTEER CONTACT DONATE Open Menu Close Menu ABOUT ISSUES VOLUNTEER CONTACT DONATE ERIN ON THE ISSUES SECURE THE BORDER: Joe Biden let over 10 million individuals illegally invade our country—that we know of. These illegals outnumber the population of Indiana by three million people. Erin visited the border in Texas twice, and witnessed the chaos and destruction firsthand. She fully supports President Trump’s efforts to restore border security—by backing law enforcement, finishing the wall, and deporting criminal illegal aliens to protect American communities. STAND WITH ISRAEL: Erin stands firmly with Israel, our nation’s strongest ally in the Middle East. Even before Hamas’ barbaric terrorist attack on October 7, 2023, she has vocally supported Israel’s right to defend itself, and the right of Israelis to live. Erin believes that we as a nation have a moral obligation to unequivocally defend Israel. She is committed to standing resolute against anti-Semitism in all forms at home and abroad and advocating for the U.S. to cut all aid to any sponsors of terrorism. CUT GOVERNMENT SPENDING: Erin believes our government takes too much of your money, and spends too much. Just as families across Indiana balance their budgets, she believes the federal government should too. It's no question that our growing national debt is a national security concern. Erin is a committed fiscal conservative and has the track record to prove it, and as a champion for Indiana’s Balanced Budget Amendment, she is bringing that same fiscal discipline to Washington. PROTECT THE UNBORN: Erin is pro-life and always has been. She has been a steadfast leader in the fight for the unborn, consistently advocating for the prohibition of late-term abortions, and resources and care for mothers in need. In Congress, she continues to be a voice for the voiceless. National Right to Life and the Susan B. Anthony List have endorsed her, she has earned an A+ rating from the SBA List, and had a consistent 100% pro-life voting record as a member of the Indiana State Senate. STAND FOR CONSERVATIVE VALUES: The strong conservative values instilled in Erin growing up in Scottsburg have become a foundational part of who she is. A strong defender of the Second Amendment, the Right to Life, and the right to worship freely, Erin will always fight for our conservative freedoms and liberties. She will continue standing steadfast for an America First Agenda that allows us to live safely and freely. PROTECT PARENTAL RIGHTS: Parents should be in the driver's seat of their children's education. The pandemic opened American parents' eyes to the reality of our public school system, and millions of parents didn't like what they saw. As a mother of three, Erin knows that parents are the primary stakeholders in their children's education. That's why she voted to pass the Parents Bill of Rights and will continue to support parents in this ongoing effort for transparency and a seat at the table as we prepare the next generation for success. SUPPORT OUR VETERANS: America is blessed with the greatest fighting force in the world, and Erin deeply appreciates our servicemen and women and their families. She is committed to improving the welfare and quality of life for our veterans and their families, our active-duty military members and their spouses. Erin is committed to ensuring we keep our promises to those who fought to defend our freedoms and never let them down. UPHOLD LAW & ORDER: Hoosiers are fortunate to have some of the most dedicated and talented law enforcement and public safety officials in the country, and it’s our duty to have their backs. These brave men and women should be protected by lawmakers instead of being met with hostility and resentment. Erin will always fight to ensure our officers have the necessary resources to do their jobs effectively and safely, and they have the support and compensation they deserve. Erin will never allow radical left-wing politicians to defund the police. CREATE JOBS: Erin knows the best way to create jobs and grow the economy is to get the government out of the way and let small business owners do what they do best – innovate and create new jobs. Indiana has one of the best economies in the nation, a direct result of our conservative values. As a small business owner, Erin continues the fight to cut bureaucratic red tape and support limited government while working to cut taxes, promote free markets, and control government spending. PROTECT THE SECOND AMENDMENT: Erin is a firm believer that the Second Amendment is one of our most important freedoms, and she understands the importance of protecting our constitutional right to bear arms. The founders saw the crucial importance of giving citizens the right to protect themselves, and we must all protect that right. CONTRIBUTE PAID FOR BY HOUCHIN FOR CONGRESS ABOUT | ISSUES | CONTACT Privacy Policy