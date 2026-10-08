You are stance coder 2. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-becerra-rent-regulation/labels/coder-2.json. Write JSON only, matching
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

politician_id: 0f74219c-7d10-4d29-85fe-0f1d834df8a7  office_id: 08454462-a1f0-4d11-9f61-aba7a173a3de
Xavier Becerra — Governor, California (candidate, level: state)
Candidate in the election of 2026-11-03

## Topics (served ladder text — code against these words only)

### topic_key: rent-regulation
topic_id: c308e8e8-caac-44f5-ab04-dbfecf40bbe2  served_revision_id: 6fa44a68-8006-48e9-b562-6b5e61d58693
Question: What role should government play in regulating rents and protecting tenants?
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


## Sources

---
snapshot_id: 0222bb3f-3a98-5fdb-a7ed-d5b8411a21e1
source_kind: own-site (the person's own site or account)
url: https://www.xavierbecerra2026.com/priorities/energy-utilities/

Energy and Utilities - Xavier Becerra Contribute Now This is a break-glass moment – for our families, our neighbors, and folks all across our great state. Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Contribute Volunteer About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Volunteer Contribute Energy and Utilities Clean Energy. Lower Bills. Shared Benefits. California’s clean-energy transition is necessary and urgent—but too many families are paying the price through rising utility bills, unreliable service, and confusing rate structures. As California’s Governor, I understand one simple truth: climate action only succeeds if it is affordable, reliable, and fair. The goal is to cut pollution and emissions while lowering household energy costs, strengthening public oversight, and ensuring the benefits of clean energy reach everyone. Bill affordability will be at the center of my energy policy, especially for low- and middle-income families. We also need stronger oversight and accountability of our utilities with increased transparency and accountability that can ensure reliability, safety, affordability, and actual emission reductions. I believe that by treating clean energy and grid resilience as public investments—and ensuring renters, low-income households, and workers share in the benefits—California can fight climate change, strengthen reliability, and make energy more affordable for everyone. Up Next Disaster Preparedness Contribute Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other OR Volunteer About Issues Take Action News Room Store Privacy Policy Paid for by Becerra for Governor 2026

---
snapshot_id: 647f07ff-1d93-5087-ba2c-593ccce29a39
source_kind: own-site (the person's own site or account)
url: https://www.xavierbecerra2026.com/priorities/housing/

Housing - Xavier Becerra Contribute Now This is a break-glass moment – for our families, our neighbors, and folks all across our great state. Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Contribute Volunteer About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Volunteer Contribute Build more affordable housing. Make the California Dream possible. Making California More Affordable For too long, California simply hasn’t built enough homes, and working families have paid the price. Soaring rents. Overcrowding. Displacement. The California Dream of owning a home, building wealth, staying in the community you love, isn’t just slipping away. For too many, it’s already gone. I know this story from the inside. My father found work as a union construction worker, and built with his own hands the house I grew up in. That home gave my family a place in this country and gave my father a place in its economy. He taught me the dignity of hard work on my first construction jobs, alongside the values he carried across the border and poured into everything he built. That story, of someone who arrived with little and built something lasting, is what California used to promise. It is too rare today. Consider what we’ve allowed to happen. Californians pay some of the highest rents in the nation, and millions of them are spending so much of every paycheck on housing that there is almost nothing left for groceries, healthcare, or a child’s future. For the families living closest to the edge, housing costs aren’t just a burden. They are the difference between stability and the street. At the heart of it is a shortage of millions of homes – California has not built nearly enough homes, and that shortage is the engine driving costs beyond reach for family after family, pushing people out of their communities and too many out of housing altogether. This is not a personal failure. It is a policy failure, and it is the defining affordability crisis of our time. I have no illusions about what stands between California and the housing it needs. The cost of capital, the direction of interest rates, the broader forces of the national economy, these shape every builder’s decision and every family’s options, and no single office commands them. But a Governor is not powerless in the face of them either. Where the private market stalls, we can use the state’s financing tools, its public land, and its capacity to de-risk development to keep shovels in the ground. Where broken laws and bureaucratic delay are adding years and tens of thousands of dollars to the cost of every home built, we can fix that. Where cities are shirking their obligations, we will enforce the law. Where zoning still locks out affordable housing from entire communities, we will open it up. Where the permitting process takes longer than the construction itself, we will end that absurdity. What I cannot control, I will work around. What I can change, I will, from the first day I take office to the last. Every swing of every hammer will carry that message. As Governor, I will reopen the door that has been slammed shut on families like mine, families who do essential work, contribute to our communities, and deserve the chance to build something here. That is the California I am running to build. GUIDING PRINCIPLES More, For the Many. Our state cannot succeed if working people cannot afford to live here. As Governor, I will bring the anger of every person struggling to pay rent or unable to access housing into every decision I make. Good Homes, Good Jobs . Building at the scale this crisis demands means that California will create hundreds of thousands of new good jobs in construction. That is only possible with the wage and labor standards that working families deserve. We know it’s possible: during the years when California built the most housing in its history, it also had the highest number of union jobs in residential construction. It is time to restart that machine. Government Must Earn the Right to Lead. As we demand more from others, we must fix the delays, fragmentation and dysfunction within our own institutions. Every dollar and every day wasted in government is a cost directly added to the mortgage or rent checks of the people we are trying to help. Growth Must Not Displace. We can build at scale without collateral damage to the people we want to help. In fact, it is imperative we do so. As we pursue a California everyone can call home, I will protect renters, preserve existing affordable housing, protect the environment, and keep communities intact as we build. Building more and accomplishing these things are not competing goals. They are all essential. POLICY AGENDA Day One: Real Authority, Real Action On my first day as Governor, I will issue an executive order declaring California’s housing shortage a state of emergency and directing every state agency to treat housing production and affordability as the paramount priority. I will embed a senior housing delivery team across agencies that report directly to my office, whose sole job is removing obstacles to projects and identifying areas within state government that need reform so we can more swiftly deliver on housing commitments. Cabinet members and agency secretaries will coordinate, as they should, but this team will have the authority to act in furthering this priority and the direct line to my office to support that. Their first mission will be the nearly 40,000 affordable housing units sitting in approved projects across California, awaiting only a final tranche of funding to break ground. Everything will be on the table to close the funding gap – bond measures, state subsidies, public-private partnerships. These homes can and will be built, and when the funding is there, the team will identify, track and move every one of them. Cut the Cost of Building It costs too much to build a home in California, and that cost is passed on to Californians in the form of high rents and high home prices. High fees, fragmented approvals, and layers of regulatory compliance are leading causes. On my first day I will require my administration to identify cost reductions that can be made administratively and legislatively, and will work with the Legislature to comprehensively reform fees statewide. In California, building an apartment costs 2.3 times what it costs in Texas, largely because of process delay and fees. I will also work with the Legislature to end the use of impossibly high affordable housing mandates as a backdoor to kill housing for families – a tactic that some cities actually use to skirt their responsibilities. Under my administration, that abuse ends. To further build at scale, we will reform policy to unlock modular housing by creating scalable statewide uniformity in review, while creating stable union jobs. Together, my administration’s central focus will be to keep prices down for Californians and build at the speed we need. Enforce State Housing Law When I was California’s Attorney General, I pioneered legal strategies to help unblock housing projects, leading to historic wins for housing across the state. Since then, California has enacted even stronger reforms, but a law is only as good as our capacity to enforce it. All too often, cities can slow walk, litigate around or ignore their obligations. California must enforce these laws without exception and without favor. I will direct the California Department of Housing and Community Development to immediately identify cities reneging on their housing element commitments and commence enforcement action, including financial penalties where appropriate. I will expand the Housing Accountability Unit so that it can quickly answer every question of technical assistance where laws are unclear or bring enforcement actions where the law is being ignored. And, I will deepen the partnership between HCD and the Department of Justice to proactively monitor compliance wherever public dollars are at stake. We will use a carrot approach as well: cities meeting their obligations should be first in line for state resources. But we will not be naive enough to think a carrot is the only tool we need. Cities that obstruct housing they have already planned for will face real consequences. Communities should have a voice in this process but they should not have a veto over the obligation. And where accountability laws need strengthening or loopholes need closing, I will lead that work with the Legislature. Reform Zoning to Unlock Housing Supply The vast majority of California’s residential land still excludes affordable housing and apartments. My administration will pursue zoning reform, expand by-right approvals near jobs and transit, and improve the laws allowing entry-level ownership options like duplexes and small condos. Last year’s SB 79 created the zoning for more housing, especially affordable housing, near rail transit, critical to building the housing we need in the places where that housing reduces traffic and carbon emissions the most. But the vast majority of cities in California still effectively ban affordable housing – my administration will build off the success of SB 79 by seeking to end exclusionary zoning around more types of transit and in high-opportunity areas, where children have access to the best schools. My administration will support and defend the progress California has made on “missing middle” housing as well, by, for example, encouraging local governments to opt in to AB 1033, which allows ADUs to be sold as affordable condos. We will also build on the successes of SB 684, zoning more land for townhomes, which are the new popular starter home in much of California. We will expand that option to more Californians. Streamline Approvals and Make the Process Predictable Housing that is planned for on paper but never built is not a solution. My administration will deliver permits, not just plans. We will build on the foundation that SB 330 established, working to create a single predictable standard of review throughout California, and will defend and enhance the streamlining tools created by AB 130, reducing permitting delays and making approvals predictable for builders of all sizes, especially small builders like my father. As Governor, I will push the next phase: tightening litigation timelines, closing loopholes used to obstruct infill projects, and making it harder for bad actors to abuse the process, bringing that same discipline to state government as we have demanded of local governments. Every housing project seeking state review will receive a final response within a defined, clear timeline (e.g., 180 days), and our embedded housing teams will have my personal voice when they go to work every day looking for ways to unblock critically needed housing stuck in red tape. In San Francisco, it can take more than four years to get all the permits needed to build, about three years longer than it takes to actually start and finish construction. The path from submitted application to completed review should not take longer than the home takes to build. Under my administration, it won’t. Get the New Housing Agency Right Creating the California Housing and Homelessness Agency and the Housing Development and Finance Committee is the right structural move, but standing up a new agency is the beginning, not the end. The hard work of turning that framework into something that actually cuts costs and speeds production falls largely to the next governor. I have done this before. At HHS I managed an agency with a budget larger than the size of California’s entire state government, and I know what it takes to build a new entity into something that works: the staffing decisions, the interagency coordination, the accountability structures that keep it from drifting. As Governor, I will resource the Agency to succeed, set the production targets it will be held to publicly, and make clear that California’s housing crisis demands results, not just reorganization. Simplify the State Affordable Housing Funding Process Every additional public funding source a developer must assemble in order to build affordable housing adds four months to the timeline and $20,000 per unit in costs. Not because developers are inefficient, but because we built a system that forces them to navigate six, seven, or eight separate agencies and funding streams just to break ground. I watched the same dysfunction play out in health care, and at HHS we moved to fix it by consolidating programs, eliminating duplicative requirements, and holding agencies to unified goals. California’s affordable housing finance system needs the same treatment: a single coordinated state application process, unified state criteria, and funding. Reform the 7th RHNA Cycle Under my administration, the 7th Regional Housing Needs Allocation cycle will no longer function as a paper exercise. I will convene housing stakeholders and policy experts to transform RHNA from a planning requirement into a genuine driver of housing production, with real accountability for jurisdictions that fall short of their allocations. Expand the Path to Homeownership Owning a home is the California Dream, and too many families are being shut out not because they cannot afford the mortgage, but because they cannot save a down payment fast enough and because there are not enough homes to buy in the first place. I will expand California’s down payment assistance program, increase its funding, and broaden eligibility so more first-time buyers can access it faster. This program more than pays for itself: the state recovers its investment when families sell, recycling those dollars to help the next family. But helping families afford a home only solves half the problem if there are not enough homes to buy. Townhomes and small condos were once a standard entry point into homeownership for working families, and decades of zoning rules effectively regulated them out of existence. For too long, California’s laws have made it far easier to build apartments for rent than homes for sale, and I will reform those laws to change that, because the path to homeownership has to start with homes that are actually available to own. Protect Homeownership from Bulk Investors Institutional investors purchasing California single-family homes and converting them into permanent rentals shrink the inventory available to first-time buyers and drive coordinated pricing that goes unchecked for renters and buyers alike. Building more homes only solves the problem if those homes reach families, not corporate portfolios. I will work with the Legislature to make it harder for large institutional investors to compete with California families for homes. I will push for beneficial ownership disclosure on bulk purchases, public registries of institutional landlords, and stronger enforcement targeting price coordination in the housing market, because whether you’re renting or trying to buy, you deserve a market that works for people, not corporations. Stand Up for Renters and Enforce California’s Tenant Protections Building more housing and protecting the people in homes right now are not competing goals, they are both essential, and we must build more housing and ensure that growth does not push people out. California’s Tenant Protection Act gives us the tools to stop excessive rent increases, require just cause before a family loses their home, and guarantee relocation assistance for displaced tenants. I will enforce those protections fully and stand behind communities that have chosen to protect renters through local rent control, within the statewide framework that keeps housing construction moving forward. We can grow our housing stock and protect the homes people are in right now. What we cannot afford is to let speculation and inaction squeeze working families out while California catches up on supply, and that stops on day one. Keeping families housed is also a matter of prevention. California’s Homeless Housing Assistance and Prevention program has helped people move out of homelessness, but its funding has been cut, made one-time, and left unprotected, forcing localities to use prevention dollars just to keep shelter beds open. A few hundred dollars in rental assistance at the right moment can prevent a family from losing their home and save tens of thousands of dollars in downstream costs. As Governor, I would establish a dedicated, stable targeted homelessness prevention funding stream within the state’s homelessness response, one that communities can plan around year over year, tied to measurable reduction targets and local investment. Build a State Master Plan for Housing Affordability California’s housing system is fragmented, with no common strategy and no clear affordability goal. My administration will develop the first-ever California Housing Affordability Master Plan, setting a target of median-income families being able to afford median-priced homes, and unifying the state’s response across zoning, streamlining, fees, financing, and regulatory costs. Like the Climate Scoping Plan for emissions, the Housing Affordability Master Plan will give every department, agency, city, and stakeholder a shared framework to work toward. We will measure progress and hold ourselves accountable for results. Up Next Economy & Affordability Contribute Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other OR Volunteer About Issues Take Action News Room Store Privacy Policy Paid for by Becerra for Governor 2026

---
snapshot_id: e4b34423-1e70-52af-9b45-85755fda13f4
source_kind: own-site (the person's own site or account)
url: https://www.xavierbecerra2026.com/priorities/homelessness/

Homelessness - Xavier Becerra Contribute Now This is a break-glass moment – for our families, our neighbors, and folks all across our great state. Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Contribute Volunteer About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Volunteer Contribute Homelessness California’s homelessness crisis is a moral emergency and a policy failure decades in the making, and it will not wait any longer. I have led coordinated national responses to this crisis as U.S. Secretary of Health and Human Services and Chair of the U.S. Interagency Council on Homelessness. I know what works and what does not. We have spent billions, and the results are not good enough. That is not a reason to give up; it is a reason to govern differently. This is not a housing crisis alone. It is a mental health crisis. People are dying on our streets because we have failed to treat it as such, and California voters understood that when they passed Proposition 1. I will implement every reform it authorizes, build thousands of treatment beds, and cut whatever red tape stands between the voters’ verdict and results on the ground. From day one, I will declare a housing emergency, direct agencies to eliminate process barriers, and launch public outcomes dashboards so Californians can see exactly where their money is going and what it is producing. No blank checks. Every dollar tied to results. Programs that fail will be defunded; programs that work will be scaled. Prevention is not a secondary strategy; it is the smartest investment this state can make. A few hundred dollars in rental assistance at the right moment can prevent homelessness and save tens of thousands in emergency response costs. California is home to half the nation’s unsheltered homeless population. We will expand shelter capacity and permanent housing, but local infighting and bureaucratic delays have gone on long enough. Communities that coordinate and produce results will be funded. Those that do not will face real consequences. California has the resources, the tools, and the moral obligation to do better. My administration will demand it. GUIDING PRINCIPLES Prevention Matters : My administration will invest in stopping homelessness before it starts, because that is the more humane and cost-effective thing to do. Targeted rental assistance, sometimes even just a few hundred dollars, can be enough to prevent homelessness, saving tens of thousands of dollars for the state and local communities and saving the dignity for the family who gets to stay housed. That is just a smart investment. Housing First, Paired with Care : My administration will deliver proven Housing First approaches, always paired, where needed, with behavioral health and addiction treatment. Accountability for Outcomes, Not Inputs : Tie every state dollar to results: people housed, not processes funded. POLICY AGENDA Governing for Results from Day One On my first day as Governor, I will issue an executive order declaring California’s housing shortage a state of emergency and directing every state agency to treat housing production and affordability as the paramount priority. My administration will launch public outcomes dashboards to track per-unit costs and 12-month housing retention metrics for all state funding. We will immediately expand rental assistance and eviction defense for those most at risk, including seniors, foster youth, and veterans. I will fully enforce California’s Tenant Protection Act, including its cap on excessive rent increases, just cause eviction standards, and relocation assistance for displaced tenants, as a critical front-line tool to prevent homelessness before it starts. Furthermore, I will prioritize funding for local agencies that coordinate effectively and produce measurable results, ensuring that every dollar spent is tied to success rather than bureaucracy. Strengthen Mental Health Infrastructure California’s voters passed Proposition 1 to get people suffering from mental illness and addiction off the streets and into treatment. Bond funds are flowing, beds are being built, and unsheltered homelessness dropped for the first time in 15 years. But deployment and results must go hand-in-hand. I will implement every reform Proposition 1 authorizes, cut whatever red tape stands between the voters’ verdict and results on the ground, and use every lever the law provides to hold local governments accountable. Invest in Prevention A few hundred dollars in rental assistance at the right moment can prevent homelessness and save tens of thousands in emergency response costs. I will establish a dedicated, stable targeted homelessness prevention funding stream within the state’s homelessness response, one that communities can plan around year over year that targets high-displacement neighborhoods and is tied to measurable reduction targets and local investment. I will fund rental assistance, eviction defense, and foreclosure prevention. Seniors, foster youth, and veterans will be prioritized first. Enforcing the California’s Tenant Protection Act and preserving local rent control ordinances consistent with the statewide framework that encourages continued housing construction while protecting the stability of existing housing stock, is also a key pillar of this prevention strategy. Prevention is not a secondary strategy; it is the smartest investment this state can make. Expand Shelter Access California is home to half of the nation’s unsheltered homeless population. The longer someone lives on the street, the less likely they are to ever leave it. My administration will expand shelter capacity as a bridge, not an endpoint, to reduce harm and accelerate the path to permanent housing. But we will not simply open the treasury. Every dollar of shelter funding will be tied to demonstrated performance: people moved off the streets, into safe shelter, and connected to services. Demand Local Coordination and Consequences for Failure Counties and Continuums of Care are essential partners, but too often they are defined by infighting rather than results. My administration will prioritize homelessness funding to communities that coordinate effectively and demonstrate outcomes. For programs and jurisdictions that are failing, there will be a mandatory playbook and real consequences for not following it. Collaboration is not optional when lives are at stake. Fund Results, Not Bureaucracy California has invested billions in homelessness. It is time to demand the outcomes Californians deserve. My administration will restructure state homelessness grants to require 12-month housing retention outcomes, publish per-unit cost dashboards for every funded program, and eliminate the administrative barriers that slow housing placements. We will measure what works, defund what does not, and scale what does. Up Next Film Industry Contribute Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other OR Volunteer About Issues Take Action News Room Store Privacy Policy Paid for by Becerra for Governor 2026

---
snapshot_id: cc4761c1-8cff-5f2c-8791-7c8e5c2002b6
source_kind: own-site (the person's own site or account)
url: https://www.xavierbecerra2026.com/priorities/california-disaster-preparedness-resilience/

California Disaster Preparedness & Resilience - Xavier Becerra Contribute Now This is a break-glass moment – for our families, our neighbors, and folks all across our great state. Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Contribute Volunteer About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Volunteer Contribute California Disaster Preparedness & Resilience Protect People. Prevent Harm. Recover Fairly and Fast. California faces worsening wildfires, floods, heat waves, and the ever-present risk of major earthquakes. Too often, disaster policy focuses on response after lives and homes are already lost. As Governor, I will put protecting Californians at the center of how we prepare for wildfires, floods, earthquakes, and extreme weather. That means shifting from a system that reacts after disaster strikes to one that prevents harm before it happens. I will fight for major investments in wildfire prevention, flood control, and seismic retrofits, prioritizing the communities most at risk. We will strengthen early warning systems, improve evacuation planning, and ensure emergency communications reach everyone—across languages, abilities, and income levels—so families have the information and support they need to stay safe. When disasters do occur, my administration will make sure recovery is fast, fair, and humane. I will protect renters and homeowners from displacement, cut red tape so people can access aid quickly, and ensure assistance reaches workers and small businesses. We will rebuild smarter—making homes and infrastructure safer and more resilient—while holding utilities and public agencies accountable for reducing risk. California can lead the nation by proving that disaster preparedness is not just about infrastructure, but about dignity, equity, and keeping people in their homes and communities. Up Next Take Action Contribute Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other OR Volunteer About Issues Take Action News Room Store Privacy Policy Paid for by Becerra for Governor 2026

---
snapshot_id: 960f1f39-0abf-50f3-8245-d3ddf7a46c81
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/ae234d2f-4fb6-4551-ad7d-846be4d8b29e

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## debate — California Governor's Debate (Nexstar) - OTR page: https://ontherecord.empowered.vote/meetings/ae234d2f-4fb6-4551-ad7d-846be4d8b29e - Video: https://www.youtube.com/watch?v=qRNZ0kuA49k - Date on On the Record: 2026-04-23 - Kind: debate · Governor's Debate (Nexstar) · California - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:36] Listen, I've been confident I can get those voters since the day I jumped in about a year ago. [6:00] Frank, we need to make sure our roads, our highways, the potholes, we take care of business because every day people get in their cars, they take transit, they need to get to work, they need to come home. The last thing they need to see is infrastructure for roads and transportation that doesn't work. I remember when my parents would tell me the stories of when they came with $12 in their pocket. They had to make a life here. They needed to make sure California could work for them. Let's make sure Donald Trump is not starting reckless wars to keep the prices of gasoline down. By up to $2 a gallon, we could reduce the price of that war in Iraq that Donald Trump started would go away. My parents looked at things like this and said, hey, help me make a living here in California. That's why they were able to, at the end of the day, send my three sisters and I to college, buy a house, make it so that they could retire here in California. We need to bring down those prices, but we have to do it the right way. I'll make sure, as governor, I tackle these crisis because I've been through these crisis before and had to handle them. We need someone with experience, someone who doesn't need on -the -job training the moment they get into the governor's office. [12:38] Well, let's think about our commuters and what they would want to see. I know that they want to see roads, bridges, highways that work for them, that let them get to work, that let them pick up their kids. They don't want to have potholes that ruin their vehicle tires and wheels. They want to have roads, bridges, highways that work. So I would say, let's take a look at all of the above. Whatever works, I'm not going to let our transportation infrastructure crumble. We have to make sure it's working for all of us. And so let's consider anything that works that the public can get behind. That's how I would do it. [13:15] If we see that that's one option that people support, I would make sure that we are funding our infrastructure. We can't let that go because what we have is when we let our roads and our bridges crumble, people suffer, commuters suffer, and we pay a higher price. So we will fund our transportation infrastructure. [18:31] Frank, I would say that the governor has made efforts. We've seen him come down to Los Angeles, actually go out and try to clean some of the streets. On effort, I would give him an A. Here's what I would do that's different, though. I would focus on accountability. I would make sure if we're sending billions of dollars down to the local communities, to our cities and our counties, that we would demand accountability for the dollar that we're gonna give them. We need to see results, and results are what you see on the streets. We need to pull folks up, help get them back on their feet, and that's what I would do. But what I will tell you is my principal job as governor, and I'm glad to hear other people are saying this, is I'm gonna keep you housed. If you are in a home right now, renting or owning, if you lose your job unexpectedly, or you have a medical emergency, and now you're about to become homeless as a result of that now unaffordable expense, tell me what you need. How can I help you keep your home? Because it costs me so much more money to pick you off off the streets, provide you with the assistance in the shelter than it does to keep you in the home that you're already paid for. Mr. [19:45] Yeah, Frank, we spend billions, tens of billions of dollars right now to try to pull people off the streets. Do you think it's working? It would cost us a fraction of that amount to help someone who temporarily lost their job stay in the home. If they for two or three months fall behind on the rent, they don't get kicked out because we'll try to support them. If you have a zero interest loan, you can keep them in their home. I save a lot more money by keeping them in the house than watching them hit the streets and then try to find them and pick them up. Far more expensive. [24:19] Well, it's interesting to watch someone who has served as a talking head on a Fox News program telling us how government should run when he never has run any government in his life. And it's fascinating to see that he can do all these things when he's talking about not collecting any revenue to be able to do any of this work. It doesn't add up. The math doesn't work, but then that's what happens. You can be a talking head and not worry about the consequences of what you do. [29:42] Thanks, Nikki. Yeah, you hear rumors all the time about all sorts of things. Rumors are not facts and the caucus, the Democratic caucus is not a place that adjudicates those things. It's law enforcement that does. If someone had come forward, we could then have investigations. I say that as the former attorney general for the state of California. When I was attorney general, we did go after sex trafficking. We did go after those who abuse of young women and take advantage of them. We did prosecute people. There was an individual who was a religious leader who was taking advantage of young women. We prosecuted that individual. Today, he is in jail for his crimes. We have gone after people, but we go after them based on evidence and based on facts. Unfortunately, we have a president today who would go after someone based on rumors. That's not the way we do it in America. We have to have the facts. Rumors are one thing, but getting the facts really gets you to move. Let me just applaud those courageous survivors who stood up and told America what the truth was. And today, Eric Swalt was facing accountability. [40:04] I would definitely push back on the Trump administration on again, a reckless policy. I would make sure that that officer understands that he cannot discriminate against any driver without having a basis to do so. I understood a little bit of what that individual was trying to say. I couldn't see the signs, but it certainly sounded like he was trying to describe what that particular sign was trying to represent. And so we have to be very careful that we're not profiling consumers in California, drivers in California, it is against the law. And our police officers, while they try to do the best job of keeping safety, have to understand, they have to abide by the rules and treat everyone, every motorist the same way. And so if that officer had some basis to be qualified, let's take a look at that. But let's not find that people are being discriminated against because of what they look like. Is that officer asking everyone he pulls over to explain those road signs or is he asking only people who look like me? And if he's doing that, then he's violating the law. [41:05] As far as I know, the Academy does not train CHP officers to be giving English proficiency exams. So that officer has some explaining to do. [49:46] What we need is the best person who can fight those who are attacking California like Donald Trump, someone who's actually taken on Donald Trump, not just fought, but won, not someone who just wants to fight to do more for housing but has and can improve the lives of so many people, has fought for better healthcare. I will support that Democrat in the runoff. Mr. Becerra, thank you. I'm hoping I'm the one that's there. Mr. [52:38] California is going through a crisis and we need someone who knows how to govern in crisis, not someone who's gonna need training wheels the moment they walk into the governor's office. This is a time to have someone who's actually fought those crises, whether it's the manmade crisis coming from Washington, D .C., or whether it's the cost of living crisis that we face here at home. We need someone who's actually fought and won. Beat back Donald Trump to save the Affordable Care Act all the way to the Supreme Court. Beat back Donald Trump in preserving the DACA program for dreamers. Been able to do that and win for the people. [57:18] Well, we have to give those who build the homes the incentive to do so. That means streamlining the regulations and the fees that make it impossible to believe that they can make these projects pencil out. Once we do that, we wanna build smart. We wanna build in the places where it makes sense. Buy transportation so it's easy to get to and from work. Make it so that we don't have commutes that are hour and a half long. We wanna make sure that we help those who wanna buy a house get in a house. Most Californians who are renting are essentially paying a monthly mortgage, except it's called rent. I would convert them into homeowners by helping them with their down payment. We have down payment assistance programs where we will expand the opportunity for a renter to become a homeowner. And the next thing I will do is in the first 100 days, I will make sure that we get all those projects that are essentially shovel -ready, ready to go. And there are some 40 ,000 housing units that are shovel -ready. They just need a little kick over the finish line. I would make sure we do that, whether it's the small tranche of money they need or getting rid of some of the licensing requirements they need. [63:22] It's very rich to hear from someone who's never had to actually run a government. I have had to balance four budgets over the course of my time as Secretary of Health and Human Services. A budget, by the way, that was larger than the budget of the state of California. When I was Attorney General of the state of California, I had a fight, whether it was a corporate attempt to try to take advantage of Californians or whether it was the Trump administration. I got in and I filed lawsuits. They weren't frivolous lawsuits. I won most of my cases because I knew how to put down the details and the facts. So it's easy to say, you haven't done this. It's easier to prove that you actually have. [64:30] Ashley, one of the things that I will do immediately is I will freeze utility rates and I will freeze home insurance policy premiums because I believe it is time that Californians had an understanding of why so many of them are paying so much for both of those charges that they have when they have a home. It is time for us to get behind the curtain and understand why these industries are charging Californians so much and in some cases dropping Californians from their insurance policy without explanation, charging twice as much. It is time for us to freeze those so Californians benefit. [74:21] I won't be as lenient as some of the responses you've heard. I believe that it's time that we get behind the curtain and find out how these insurance companies are operating, because there are still people in Altadena and Pacific Palisades who have not been paid on their claims from back in January, 2025. That is ridiculous. Every month they paid their premiums. Some people had never filed a claim, yet when they finally filed this claim for these wildfires, they still can't get an answer to the question, how much they get and when they'll get it. That is not right. We should hold their feet to the fire. I'll make sure that we take on all the issues of wildfire mitigation. Sure, you have to harden your home. We have to make sure we don't have developers building in high -risk areas. We'll do all those things. But first and foremost, insurers owe those consumers, those rate payers, I'm sorry, people who paid their premiums responses. They paid their premiums. They are owed a response on their claims. It's ridiculous that people have had to wait more than a year. That is not the way you treat a customer. [79:52] Addiction is dangerous. Yes, I would absolutely work with legislators to make sure we can enact such a law. Kids have died as a result of their use of social media. Kids are going into this spiral downhill where they're not doing anything but playing with their phone. It is time for us to act and I will tell you as a former attorney general, I will enforce that law to make sure we are able to manage our children's development over the lifespan. And what I will tell you is this, we also have to help those families that are trying to manage their kids' use of these types of devices. [81:57] I wish I could tell you that I have time to watch streaming shows. I can't tell you that I'm much of a TV watcher.

---
snapshot_id: adb42df1-f71b-5768-b5b4-2846231de14f
source_kind: own-site (the person's own site or account)
url: https://www.xavierbecerra2026.com/housing

Housing - Xavier Becerra Contribute Now This is a break-glass moment – for our families, our neighbors, and folks all across our great state. Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Contribute Volunteer About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Volunteer Contribute Build more affordable housing. Make the California Dream possible. Making California More Affordable For too long, California simply hasn’t built enough homes, and working families have paid the price. Soaring rents. Overcrowding. Displacement. The California Dream of owning a home, building wealth, staying in the community you love, isn’t just slipping away. For too many, it’s already gone. I know this story from the inside. My father found work as a union construction worker, and built with his own hands the house I grew up in. That home gave my family a place in this country and gave my father a place in its economy. He taught me the dignity of hard work on my first construction jobs, alongside the values he carried across the border and poured into everything he built. That story, of someone who arrived with little and built something lasting, is what California used to promise. It is too rare today. Consider what we’ve allowed to happen. Californians pay some of the highest rents in the nation, and millions of them are spending so much of every paycheck on housing that there is almost nothing left for groceries, healthcare, or a child’s future. For the families living closest to the edge, housing costs aren’t just a burden. They are the difference between stability and the street. At the heart of it is a shortage of millions of homes – California has not built nearly enough homes, and that shortage is the engine driving costs beyond reach for family after family, pushing people out of their communities and too many out of housing altogether. This is not a personal failure. It is a policy failure, and it is the defining affordability crisis of our time. I have no illusions about what stands between California and the housing it needs. The cost of capital, the direction of interest rates, the broader forces of the national economy, these shape every builder’s decision and every family’s options, and no single office commands them. But a Governor is not powerless in the face of them either. Where the private market stalls, we can use the state’s financing tools, its public land, and its capacity to de-risk development to keep shovels in the ground. Where broken laws and bureaucratic delay are adding years and tens of thousands of dollars to the cost of every home built, we can fix that. Where cities are shirking their obligations, we will enforce the law. Where zoning still locks out affordable housing from entire communities, we will open it up. Where the permitting process takes longer than the construction itself, we will end that absurdity. What I cannot control, I will work around. What I can change, I will, from the first day I take office to the last. Every swing of every hammer will carry that message. As Governor, I will reopen the door that has been slammed shut on families like mine, families who do essential work, contribute to our communities, and deserve the chance to build something here. That is the California I am running to build. GUIDING PRINCIPLES More, For the Many. Our state cannot succeed if working people cannot afford to live here. As Governor, I will bring the anger of every person struggling to pay rent or unable to access housing into every decision I make. Good Homes, Good Jobs . Building at the scale this crisis demands means that California will create hundreds of thousands of new good jobs in construction. That is only possible with the wage and labor standards that working families deserve. We know it’s possible: during the years when California built the most housing in its history, it also had the highest number of union jobs in residential construction. It is time to restart that machine. Government Must Earn the Right to Lead. As we demand more from others, we must fix the delays, fragmentation and dysfunction within our own institutions. Every dollar and every day wasted in government is a cost directly added to the mortgage or rent checks of the people we are trying to help. Growth Must Not Displace. We can build at scale without collateral damage to the people we want to help. In fact, it is imperative we do so. As we pursue a California everyone can call home, I will protect renters, preserve existing affordable housing, protect the environment, and keep communities intact as we build. Building more and accomplishing these things are not competing goals. They are all essential. POLICY AGENDA Day One: Real Authority, Real Action On my first day as Governor, I will issue an executive order declaring California’s housing shortage a state of emergency and directing every state agency to treat housing production and affordability as the paramount priority. I will embed a senior housing delivery team across agencies that report directly to my office, whose sole job is removing obstacles to projects and identifying areas within state government that need reform so we can more swiftly deliver on housing commitments. Cabinet members and agency secretaries will coordinate, as they should, but this team will have the authority to act in furthering this priority and the direct line to my office to support that. Their first mission will be the nearly 40,000 affordable housing units sitting in approved projects across California, awaiting only a final tranche of funding to break ground. Everything will be on the table to close the funding gap – bond measures, state subsidies, public-private partnerships. These homes can and will be built, and when the funding is there, the team will identify, track and move every one of them. Cut the Cost of Building It costs too much to build a home in California, and that cost is passed on to Californians in the form of high rents and high home prices. High fees, fragmented approvals, and layers of regulatory compliance are leading causes. On my first day I will require my administration to identify cost reductions that can be made administratively and legislatively, and will work with the Legislature to comprehensively reform fees statewide. In California, building an apartment costs 2.3 times what it costs in Texas, largely because of process delay and fees. I will also work with the Legislature to end the use of impossibly high affordable housing mandates as a backdoor to kill housing for families – a tactic that some cities actually use to skirt their responsibilities. Under my administration, that abuse ends. To further build at scale, we will reform policy to unlock modular housing by creating scalable statewide uniformity in review, while creating stable union jobs. Together, my administration’s central focus will be to keep prices down for Californians and build at the speed we need. Enforce State Housing Law When I was California’s Attorney General, I pioneered legal strategies to help unblock housing projects, leading to historic wins for housing across the state. Since then, California has enacted even stronger reforms, but a law is only as good as our capacity to enforce it. All too often, cities can slow walk, litigate around or ignore their obligations. California must enforce these laws without exception and without favor. I will direct the California Department of Housing and Community Development to immediately identify cities reneging on their housing element commitments and commence enforcement action, including financial penalties where appropriate. I will expand the Housing Accountability Unit so that it can quickly answer every question of technical assistance where laws are unclear or bring enforcement actions where the law is being ignored. And, I will deepen the partnership between HCD and the Department of Justice to proactively monitor compliance wherever public dollars are at stake. We will use a carrot approach as well: cities meeting their obligations should be first in line for state resources. But we will not be naive enough to think a carrot is the only tool we need. Cities that obstruct housing they have already planned for will face real consequences. Communities should have a voice in this process but they should not have a veto over the obligation. And where accountability laws need strengthening or loopholes need closing, I will lead that work with the Legislature. Reform Zoning to Unlock Housing Supply The vast majority of California’s residential land still excludes affordable housing and apartments. My administration will pursue zoning reform, expand by-right approvals near jobs and transit, and improve the laws allowing entry-level ownership options like duplexes and small condos. Last year’s SB 79 created the zoning for more housing, especially affordable housing, near rail transit, critical to building the housing we need in the places where that housing reduces traffic and carbon emissions the most. But the vast majority of cities in California still effectively ban affordable housing – my administration will build off the success of SB 79 by seeking to end exclusionary zoning around more types of transit and in high-opportunity areas, where children have access to the best schools. My administration will support and defend the progress California has made on “missing middle” housing as well, by, for example, encouraging local governments to opt in to AB 1033, which allows ADUs to be sold as affordable condos. We will also build on the successes of SB 684, zoning more land for townhomes, which are the new popular starter home in much of California. We will expand that option to more Californians. Streamline Approvals and Make the Process Predictable Housing that is planned for on paper but never built is not a solution. My administration will deliver permits, not just plans. We will build on the foundation that SB 330 established, working to create a single predictable standard of review throughout California, and will defend and enhance the streamlining tools created by AB 130, reducing permitting delays and making approvals predictable for builders of all sizes, especially small builders like my father. As Governor, I will push the next phase: tightening litigation timelines, closing loopholes used to obstruct infill projects, and making it harder for bad actors to abuse the process, bringing that same discipline to state government as we have demanded of local governments. Every housing project seeking state review will receive a final response within a defined, clear timeline (e.g., 180 days), and our embedded housing teams will have my personal voice when they go to work every day looking for ways to unblock critically needed housing stuck in red tape. In San Francisco, it can take more than four years to get all the permits needed to build, about three years longer than it takes to actually start and finish construction. The path from submitted application to completed review should not take longer than the home takes to build. Under my administration, it won’t. Get the New Housing Agency Right Creating the California Housing and Homelessness Agency and the Housing Development and Finance Committee is the right structural move, but standing up a new agency is the beginning, not the end. The hard work of turning that framework into something that actually cuts costs and speeds production falls largely to the next governor. I have done this before. At HHS I managed an agency with a budget larger than the size of California’s entire state government, and I know what it takes to build a new entity into something that works: the staffing decisions, the interagency coordination, the accountability structures that keep it from drifting. As Governor, I will resource the Agency to succeed, set the production targets it will be held to publicly, and make clear that California’s housing crisis demands results, not just reorganization. Simplify the State Affordable Housing Funding Process Every additional public funding source a developer must assemble in order to build affordable housing adds four months to the timeline and $20,000 per unit in costs. Not because developers are inefficient, but because we built a system that forces them to navigate six, seven, or eight separate agencies and funding streams just to break ground. I watched the same dysfunction play out in health care, and at HHS we moved to fix it by consolidating programs, eliminating duplicative requirements, and holding agencies to unified goals. California’s affordable housing finance system needs the same treatment: a single coordinated state application process, unified state criteria, and funding. Reform the 7th RHNA Cycle Under my administration, the 7th Regional Housing Needs Allocation cycle will no longer function as a paper exercise. I will convene housing stakeholders and policy experts to transform RHNA from a planning requirement into a genuine driver of housing production, with real accountability for jurisdictions that fall short of their allocations. Expand the Path to Homeownership Owning a home is the California Dream, and too many families are being shut out not because they cannot afford the mortgage, but because they cannot save a down payment fast enough and because there are not enough homes to buy in the first place. I will expand California’s down payment assistance program, increase its funding, and broaden eligibility so more first-time buyers can access it faster. This program more than pays for itself: the state recovers its investment when families sell, recycling those dollars to help the next family. But helping families afford a home only solves half the problem if there are not enough homes to buy. Townhomes and small condos were once a standard entry point into homeownership for working families, and decades of zoning rules effectively regulated them out of existence. For too long, California’s laws have made it far easier to build apartments for rent than homes for sale, and I will reform those laws to change that, because the path to homeownership has to start with homes that are actually available to own. Protect Homeownership from Bulk Investors Institutional investors purchasing California single-family homes and converting them into permanent rentals shrink the inventory available to first-time buyers and drive coordinated pricing that goes unchecked for renters and buyers alike. Building more homes only solves the problem if those homes reach families, not corporate portfolios. I will work with the Legislature to make it harder for large institutional investors to compete with California families for homes. I will push for beneficial ownership disclosure on bulk purchases, public registries of institutional landlords, and stronger enforcement targeting price coordination in the housing market, because whether you’re renting or trying to buy, you deserve a market that works for people, not corporations. Stand Up for Renters and Enforce California’s Tenant Protections Building more housing and protecting the people in homes right now are not competing goals, they are both essential, and we must build more housing and ensure that growth does not push people out. California’s Tenant Protection Act gives us the tools to stop excessive rent increases, require just cause before a family loses their home, and guarantee relocation assistance for displaced tenants. I will enforce those protections fully and stand behind communities that have chosen to protect renters through local rent control, within the statewide framework that keeps housing construction moving forward. We can grow our housing stock and protect the homes people are in right now. What we cannot afford is to let speculation and inaction squeeze working families out while California catches up on supply, and that stops on day one. Keeping families housed is also a matter of prevention. California’s Homeless Housing Assistance and Prevention program has helped people move out of homelessness, but its funding has been cut, made one-time, and left unprotected, forcing localities to use prevention dollars just to keep shelter beds open. A few hundred dollars in rental assistance at the right moment can prevent a family from losing their home and save tens of thousands of dollars in downstream costs. As Governor, I would establish a dedicated, stable targeted homelessness prevention funding stream within the state’s homelessness response, one that communities can plan around year over year, tied to measurable reduction targets and local investment. Build a State Master Plan for Housing Affordability California’s housing system is fragmented, with no common strategy and no clear affordability goal. My administration will develop the first-ever California Housing Affordability Master Plan, setting a target of median-income families being able to afford median-priced homes, and unifying the state’s response across zoning, streamlining, fees, financing, and regulatory costs. Like the Climate Scoping Plan for emissions, the Housing Affordability Master Plan will give every department, agency, city, and stakeholder a shared framework to work toward. We will measure progress and hold ourselves accountable for results. Up Next Economy & Affordability Contribute Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other OR Volunteer About Issues Take Action News Room Store Privacy Policy Paid for by Becerra for Governor 2026