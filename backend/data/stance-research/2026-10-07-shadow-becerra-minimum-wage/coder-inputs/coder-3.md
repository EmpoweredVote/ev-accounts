You are stance coder 3. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-becerra-minimum-wage/labels/coder-3.json. Write JSON only, matching
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

politician_id: 0f74219c-7d10-4d29-85fe-0f1d834df8a7  office_id: 08454462-a1f0-4d11-9f61-aba7a173a3de
Xavier Becerra — Governor, California (candidate, level: state)
Candidate in the election of 2026-11-03

## Topics (served ladder text — code against these words only)

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


## Sources

---
snapshot_id: b636fc2d-eec0-5a18-8e44-deaeef04af6f
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/757023d7-00e3-4a28-a47f-96c43a2021c9

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## California Politics 360 (KCRA 3) - Xavier Becerra Governor - OTR page: https://ontherecord.empowered.vote/meetings/757023d7-00e3-4a28-a47f-96c43a2021c9 - Video: https://www.youtube.com/watch?v=oySceWN-ckU - Date on On the Record: 2026-04-26 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:02] Ashley thank you. [0:09] Because it's a hard job and you need someone who's gone through these tough times and it knows what it's like to have to balance a big budget. Someone who knows what it's like to deal with emergencies, crises, and knows how to get out of them. Someone who knows how to fight and someone who knows how to win. I'm getting to do what my parents didn't have a chance to do and that is live a life based on your dream and I'm getting to do it with people who also want to see California thrive. So why not? [1:09] Both. You got to do a little bit of both. I had to do that when I was secretary at HHS in the midst of the worst pandemic any of us had ever seen. I had to save lives, manage a budget, and do it without making cuts to the most essential programs. We were able to do that. We got the economy and the country out of COVID. Uh It took a lot of work but you have to do it with a mix of measures and I think in the case of California we'll need new revenue and there are people who aren't paying their fair share who have to pay a little bit more. At the same time we have to take a look at programs as I had a look at programs when I was at HHS and we had to make decisions on where to cut to make sure that we balanced our books. [2:03] For the most part, yeah. Think of it this way. I'm not sure what bracket you're in, what tax bracket. All I know is that there are people who are paying doctors, doctors nurses, teachers, firefighters, police officers, folks who you think of in the middle. If you're making way more money than the state, you're going to have to raise taxes on the wealthy. And any of those professionals and you're paying at a tax rate lower than them, you're not paying your fair share. So I think it'll be pretty quick and pretty easy to calculate if you're going to have to pay a little bit more. Because if you're paying less in taxes and make, you're a billionaire and you're paying less than that teacher in your effective tax rate, you're likely going to have to pay more. [2:51] So we would try to have a policy on revenue. That is predictable and consistent. That's one thing I've learned that when I was on the Ways and Means Committee in the Congress. Ways and Means Committee is a tax writing committee. So I did tax policy for about 20 years. What you need to do is give people predictability. You want people to pay their taxes? They got to know more or less what they're going to owe at the end of the year. You want a business to be able to invest in your state? They got to know what they're facing in terms of taxes and regulations. Give them predictability. And so I would make sure that we are developing a tax code that gives people predictability. That means if you know you're paying an effective tax rate lower than that teacher or firefighter, you should expect you're going to be paying more at the end of the year. [3:56] No, no, because think of it. Most of those doctors, lawyers, a lot of those professionals who are making three, four, five hundred thousand, eight, nine hundred thousand, a million dollars. I'm not looking to go after them because they already are paying a sizable tax to the state of California for their income. I'm talking about folks who don't have that wealth because of their income. They have it because of their investments. And investments in this country are taxed at lower rates than the effective tax rate of that firefighter and that teacher. And it's because so many billionaires have their wealth in those investments that they get off without paying a fair share of taxes to the state where they make their living, where they love to enjoy. And, you know, most of the folks that I've encountered who are fairly wealthy? Yeah. Don't mind paying their fair share. And they're willing, so long as they can understand why they're being taxed. So long as it's predictable. Everyone understands we pay a premium to live in this great state of California. Go take a look at the price of the gas pump today. We're paying a premium mostly because Donald Trump got us into this reckless foreign war. But I will tell you, we like California. We want to stay in California, but it's got to be affordable. [5:25] would take a real close look at these homeless programs. We have not had accountability. I believe that every dollar that we invest in homelessness is going to be a very precious dollar. And I'd like to make sure that it leads to results. And results for most of us are when I look at those streets, I don't see people lying there in the morning having slept there. I want to see results. I want to see results. I have accountability. I'm willing to invest in having assistance for those who are homeless. But we have to have results. And if you can't produce the results and that accountability, then you shouldn't get the money. [6:23] would certainly make sure that they are delivering results. And if they can't deliver results, I'll take that dollar to someone who is delivering results. And so we have to make the best use of that dollar because there are always programs that have to deal with something like homelessness. I only have so many of those dollars. If I have to make a decision, I'm going to put that one dollar into that one organization that's delivering accountable results. [7:01] Absolutely. [7:17] I understand what the thinking was. I think that's short -sighted. And it's not costly. So you're going to be able to have a family that's going to be most effective. And Ashley, that one's an easy one. You've got a family, you've got a child, your child's hurting, you don't have money, you don't have insurance. You're going to think of everything you can from going to get the aspirin, to trying the massage in the curandera, if you're from a Mexican home. Whatever you can, that's not going to cost you an arm and a leg. But if your child's still hurting, at some point, you're going to the hospital. And if you don't have insurance, and if you're not a wealthy person, if you're not able to afford to buy, person, that bill will drive you out of your house. Whatever nest egg you had has just gone. So if you were looking to use that to buy a house in the future or to get help pay for your kids tuition to college, gone. But you're going to take your your child to that hospital. Why should we wait till you have to take your child to the hospital? Which means you're probably entering through the emergency room. The most expensive door to walk through in healthcare is the ER door. Why should we wait because you didn't have insurance that you let the situation get so bad that now you have no choice but to save your child you go to the hospital through the emergency room. I'm saying no, no. You're gonna have access to that pediatrician, that family doc, that OBGYN now early upfront. Because it cost me so much less to do it upfront than wait till it gets really expensive at the back end. So tell me someone you don't have insurance condemns them to have to use the back door. You're going to be back in the most expensive care. I'm not going there. And I tell you this from my own experience being Secretary at HHS from defending the Affordable Care Act as AG all the way to the Supreme Court. But I'll tell you where I learned it most. From two great Americans. My mom who said, mi hijo es mejor prevenir que remediar. It is always better to prevent than to try to remediate. And Frederick Douglass who said it about 160 years ago, it is easier to build strong children then to repair broken men. We wait until they go to the emergency room to repair broken men and women. If we had built them strong and healthy at the beginning, we'd be spending a lot less money. I'm not going to wait until they're broken and we spend a ton of money. I'm going to build them strong and smart from the beginning, and that means giving them access to health care. [9:58] Well, if that family's not on Medi -Cal, when they do use the health services at the hospital, who's paying? Not Medi -Cal, so the state may not be paying, but you're putting that now on the county. Or you're putting it on the back of that doctor or that clinic or that hospital that doesn't get paid. And at some point, they're going to say, I can only do business this way so long before I have to close my doors. I don't want clinics, doctors, and hospitals to close their door. Go to rural California. They're already closing hospitals. We can't afford that, and I'm not going to let it happen. Because as much as I think it's morally right, health care should be a right, not a privilege, economically, it is not smart to wait for them to use the most expensive care walking in through an emergency room. It's economically smarter to give people access early so they maintain their health. Our system in health care, unfortunately, and I kept saying this when I was secretary at HHS, our health care system is based on treating illness. Our system of health should be based on promoting wellness. So we avoid the expensive care. That's why the U .S., California, we have the most expensive health care in the world, bar none, and we still leave people without insurance. I [11:39] Well, I see two issues there. And let me start with the first, which I'll piggyback off of what I just finished saying about health care. Okay. You can't wait until a child is entering kindergarten, and now we have transitional kindergarten, when they're four or five years of age to expect them to just launch. If their life from zero to four or five has not been one that's equipped them to learn, they're not going to succeed. And we're setting ourselves up and them for failure. And so it should not surprise us that so many of our children, by the time they're in sixth grade, by the time they get to middle school and high school, they're not at grade level. Mejor prevenir que remediar. Better to start early. Build a strong child. And so I think we make a major mistake that costs us less money to provide early care, education. So not just when they're four or five. Think of all those parents who are struggling to find good daycare for their kids. And I don't mean just daycare where it's just you're watching that child during the day. Someone who can also provide them some basic education when they're two or three years old. So that when they get into pre -K, they're ready to learn a little bit in pre -K. So then when they get into the first grade, they're ready to start learning. [12:56] I would front load a lot of education. So we make pre -K and early care affordable. Most families can't afford to pay tuition, college tuition, for a three -year -old so they can go and work. And that's unfortunately what daycare has become. Child care has become, essentially, paying college tuition for your two - and three -year -old while you go work. That's incredibly hard, difficult to absorb. So early, upfront education first. Secondly, how is it that we expect a teacher to take those children and make them the next doctor, scientist, you name it. Major professional, engineer. We want them to be able to teach our child to become that doctor, scientist, or engineer. But how much do we pay them? Way less than a doctor, a scientist, or engineer. Are you surprised then that there is massive turnover among our teachers' ranks? That after three to five years, they're out of there because they're just not making a good living and they can go make more money doing something else. We need the best and the brightest teachers to make that their career. Let's compensate them right. Let's focus our money. We do put most of our money in our state budget into education. So let's put it where it counts. Getting the best teachers and equipping the best classrooms so those kids who have had some pre -K education are ready to learn. [14:38] Because we have to spend a lot of money in doing remediation. Because so many of our children are... in their grade, but not at grade level. And so we're doing a lot of work to help them catch up. That costs a ton of money. We're also spending too much money on things that have nothing to do with the classroom. Too much bureaucracy. And I would cut some of that out as well. And then focus the money where it counts. Same thing as with health care. I'd rather put my dollar into that doctor instead of that pencil pusher, that money cruncher, that accountant, who's trying to figure out the best way to game the system when it comes to charging or paying for that health care service. Give it to the doctor. Give it to the nurse. Give it to that hospital technician who's helping the doctor or nurse rather than give it to the accountant who's trying to figure out how to scheme and game the system to get the best reimbursement or to avoid paying more than necessary. [15:50] The way I had to do it when I was attorney general. We had to, one, enforce laws. Sometimes people weren't happy. We'd tell them they have to do certain things. We'd say, you should have read the law before you decided to do that business because the law is pretty clear. All we're doing is having you follow the law. So if you. . . Said you were going to pay somebody minimum wage by law, you must pay them minimum wage. You can't steal their money. That's called wage theft. So we enforced the law and said, you hired somebody. You had them work. They provided you labor. Now you owe them the money. And you can't say that, oh, woe is me. I didn't realize I was underpaying. Follow the law. And so we have to enforce the law. We also have to make sure we do constant oversight. Delivery. As I said in my earlier answer to the homelessness question, there's got to be accountability. These are taxpayer dollars. They don't belong to me or anyone else in government. They belong to the taxpayers. I have to show that I've spent their money well. I can demand accountability. Oversight, accountability, and enforcement are the ways you drive this. I had to do that when I was AG all the time. I had to do it when I was Secretary of Health and Human Services because when you're in the midst of a monumental pandemic like COVID was, and I had 50 states screaming at me saying, we need more vaccines. We need more Paxlovid and treatment. We need more ventilators. I had to figure out how I was going to distribute all of those items to save lives to 50 different health authorities, 50 different governors all demanding what they needed. And we didn't have everything that they wanted at every minute of time. So we had to distribute. We needed to know how to do that. The way you do that is by having oversight. The way we were able to know when to send vaccines to certain hotspots is because we demanded the data. We were able to spot the hotspots and then be able to direct the resources where they were needed most. We have to do a much better job in government to make sure that we are enforcing accountability, oversight, and we'll get some things done. [18:30] Yeah. As I said, gut punch. You put your trust in people. But what you also have to remember is as much as you've had a working relationship over years, as much as you've done things together and succeeded in so many ways, at the end of the day, we're all accountable. The law is the law. And no one is above the law. And so when accountability comes knocking your way, you've got to show up. And so I don't think anyone will challenge what the law is. And we all have to face up to it. But it was a real gut punch. [19:33] we were paying for management of a dormant account, making sure that nothing was, no laws were violated. Because I was Secretary of Health and Human Services, a cabinet member, I had to distance myself from anything that looked political or campaign related. I had ethics rules that were in place that required me to distance myself. And so I depended on people that I trusted to be able to manage that the right way. We were going to pay for the management. You always pay for someone to oversee, to file the right documents. And I was willing to pay the price to make sure that I didn't have to worry about it. Lo and behold, while I was willing to pay a price, and by the way, the attorneys of the campaign account signed off on all those payments as well. It wasn't as if there wasn't someone who was checking. The attorneys were checking, and they were saying, you know, everything seemed kosher. What happened was, after the payments, the way the money was used is where the violation occurred. There was no violation in terms of the payment. That's why I and my campaign, you know, I was willing to pay the price. But the attorney's office was not saying nothing about it. I had not been involved in the before and after and after, and the P .A. [21:09] I was getting an opinion whether second or not first or second opinion every time because I had campaign attorneys who were watching over the account as well who I also paid and so never once did they flag that there was anything going on with the payment the payment was substantial but it wasn't by itself something that was illegal and so when we made the payments my attorney said they never objected to the payments the [22:05] just look at my record when it came time to Covid take a look at how we were able to get those vaccines some seven hundred million vaccines by the time we had finished our four years in tenure some 700 million vaccines went into the arms of Americans but perhaps the most important fact there is that never once do we have to ask Americans to pay one penny to get that life -saving treatment because we knew that people who were uninsured or were low -income would probably pass and say I'll take my chances I'll try to be safe which of course meant if they were not safe none of us was safe and so the work that we did there I would tell people take a look at my record as Attorney General if you want to see how I'll do my work if I can be accountable take a look at the work I did to protect our state at a time when Donald Trump was president the first time and was coming at our state trying to assault us and in so many different ways very similar to what he's doing now we stood up we protected our state whether it was health care where I took the Affordable Care Act all the way up to the Supreme Court against Donald Trump and beat him whether it was the DACA program for dreamers where he tried to eliminate it in a wrong way we took him to the Supreme Court we beat him whether it was protecting our clean car standards whether it was protecting the right to choose and have reproductive health care services over and over we proved what we could do if people want to see what I do how I do it and whether I can be accountable I'd say take a look at that record okay [23:45] get to building you're talking to a former construction worker my dad was for decades a construction worker I knew how to wield a hammer before I knew how to throw a baseball and so we're gonna build we're gonna do it right that means and everyone I think every one of the candidates will talk about how we're gonna trim back on some of the regulations that make it tough to move forward we're gonna try to make sure we're working with local governments we we try to eliminate some of the fees that make it very difficult to make a project pencil out we're gonna try to make sure that we look at the projects that are almost ready to go there are thousands of units of housing that are essentially shovel ready except something is missing about 40 ,000 units of affordable housing are essentially shovel ready most in most cases they're just missing that last last tranche of funding let's kick that into gear and let's get to building because it's not just a matter of building the state [24:45] the state does have some resources that I would pull on to try to help but we're gonna need some other resources as well it shouldn't be just on the state local governments need to have that housing as well and we could look at the industry and and find out if they have ways that they can help us do this as well so what we could do is kick those into gear because they are they've checked all the boxes they've got most of their financing there's just one thing missing to kick those in the into gear. Let's get the shovel in the ground and start building those units that we need. I would make sure that within my first 100 days, I have moved to freeze property insurance rates, which have gone sky high, and utility rates, which continue to increase. So these private investor utility companies are making a profit, an automatic profit, guaranteed profit, while we're paying higher and higher bills, and we don't understand why we have to continue to pay so much. So whether it's on property insurance or utilities, I would declare a state of emergency on housing, be able to then freeze those rates on property insurance, do the same on utilities, give myself about three or four months working with the legislature, local government, and the industry to figure out what's going on. Let's pull the curtain open and find out what's behind those property insurance increases. Let's find out what's behind the curtain of those utility rate increases. If they can explain themselves, I think most Californians say, that's okay, I got it. [26:30] first, if they're going to say that, I say, okay, show me. And show them. So the public, what those regulations are. And if it's true, and then we'll hear from the public as well. And maybe those are some of the rates we have to trim. But show me, show me. I don't know about you, Ashley, but last year, my property insurance rates more than doubled. I don't live in fire hazard area. I'm in Sacramento area. I'm not in brush country. Just more overnight. who doubled, than doubled My mom, had, I won't name the company, had been for more than three decades paying property insurance. I don't know if she'd ever filed a claim. She got dropped. Never an explanation. When she finally was able to get new insurance, more than double. I think we just want an explanation. Pull the curtain back, show me. If there's something going on that it's our fault, okay, then we'll deal with that. But show me. [27:35] We have to have goals that are achievable. I had to do that with COVID. I had to constantly tell people, we have to, we have to complete this. If we're going to save lives, we have to deliver results. And so, anything having to do with climate change, cleaner energy, when we have goals, they have to be achievable. Is [28:00] It's looking harder and harder to get there. We should strive for it. We have to get there, but it's looking harder and harder. And what's, what's the measure? How do you measure that? Could my parents meet that goal? My parents were working class family. Could my parents meet that goal? If my parents could meet that goal, and they were working every day hard and hard to just make a living and scratch out the best for their kids, if they could meet them, then it's not a good goal. But if they could, let's, let's keep striving. Let's keep pushing. A [28:38] So my dad, all the, all the years I knew him drove a pickup, and not a new one. [28:46] Would my dad have been able to switch out his pickup for an electric view? [28:52] I'd say chances are no, not right now. But then So if he could, we should. goals that are achievable, not goals that are pie in the sky. I think when these goals were first initiated, there was this belief that we could get there. Things have become very difficult. And we should not be shackled by goals because our families can't be driven day to day by things that are not achievable because they have to achieve. They have to make sure their kids can go to school. They have to make sure they've paid that mortgage or that rent. There's nothing, no striving in paying your rent. You need to pay your rent. You've got to have hard and fast measurable results as a family, but as a state government as well. [29:59] Because I want their families to succeed. That we don't agree on Donald Trump. That's the beauty of America and free speech and the First Amendment. But I want them to succeed. If they're working hard, then I want to fight for them. If they're trying to get their kids to college or the military or an apprenticeship program, I want to see it happen. If they want to buy a house, I'm going to try to help them. If they're tired of paying high utility costs, I'm going to try to find out behind that curtain what's going on. You know, it's governing. You realize you're going to have to do something. You're going to realize real quickly, it's not red or blue. Governing is about me and you and getting it done. And if you don't get it done, you could be red or blue, but you won't be in office very long. And so it's just a matter of getting it done. I'm not looking to be the, have my portrait above every mantle in every home in California. I want everyone to have a mantle and a home. [31:14] you're talking to someone who's had to balance a budget bigger than the budget that Governor Newsom had to balance. You're talking to someone who had to deal with a crisis bigger than perhaps any crisis that the governor of California had to deal with when we had to save lives across the country with COVID. You're talking to someone who took care of the economy and took on a rogue, menacing federal government the way Governor Newsom has had to do that. I did that when I was AG. You [31:44] I'm trying to put it in context. Got it. [31:46] it is important to recognize when you grade someone, understand the shoes they're filling. It's not easy to be a governor of the biggest state, the fourth largest economy. So what I would tell you is this, we became the fourth largest economy under Gavin Newsom. Check. We have expanded health care to more Californians. Check. There are many things that he has done well. The other things, public safety, I think he could have been more ambitious. Homelessness could have been more ambitious, more, have people be more accountable. Uh If I were grading, I'd say Gavin Newsom is going to go on to college because he's going to graduate from my high school. What's the [32:32] What's the threshold? The threshold? Yeah. That he's left us in a place where - So like a C? [32:36] Well, I mean, you could go to college with a C. It's a lot more difficult. But I think he has done many of the things that we have asked him to do. And in some areas, well, when I become governor, I'll make sure - But what's [32:48] I don't know if I can give him a grade. [32:52] Well, I was going to try. But what I'm telling you, I wasn't in his shoes. I know a lot of folks who gave me a grade on COVID say, oh, that guy was terrible. But they're still alive. They get to go out and not have to wear a mask. I mean, you can grade anybody the way you want. It's whether you left the place better than you saw it and you started. I would absolutely say he has. He's tried. And knowing how tough it is to manage an enterprise the size of the state of California, as the Department of Health and Human Services, the largest public health agency in the world, with a budget, as I said, bigger than the state of California, I know what it's like. And it's easy to grade. It's tough to accomplish. Okay. So not [33:38] mean, that's not for me to say. Okay. [33:48] Hmm. [33:54] bold, [33:58] Focused. [34:03] Decisive. [34:07] you, Ashley.