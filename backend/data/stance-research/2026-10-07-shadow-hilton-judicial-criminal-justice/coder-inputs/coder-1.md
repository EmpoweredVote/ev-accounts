You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-judicial-criminal-justice/labels/coder-1.json. Write JSON only, matching
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

politician_id: 9a60d603-194d-410f-ae01-85bd6293f1a7  office_id: 08454462-a1f0-4d11-9f61-aba7a173a3de
Steve Hilton — Governor, California (candidate, level: state)
Candidate in the election of 2026-11-03

## Topics (served ladder text — code against these words only)

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


## Sources

---
snapshot_id: 997405c2-dd2a-54f6-84f9-b17fe29cbedc
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/make-california-the-crypto-capital-of-the-world

Saved from https://stevehiltonforgovernor.com/policies/make-california-the-crypto-capital-of-the-world (rendered page text, built-in browser, 2026-10-07) POLICY MAKE CALIFORNIA THE CRYPTO CAPITAL OF THE WORLD ← POLICY ARCHIVE MAKE CALIFORNIA THE CRYPTO CAPITAL OF THE WORLD THE PROBLEM California should be leading the future of digital finance. Instead, we are driving innovation, investment, and talent out of our state. For decades, California was the best place in the world to build transformative technologies. Today, companies and entrepreneurs are increasingly looking elsewhere because of overregulation, political uncertainty, and rising costs. The global race for leadership in digital assets and blockchain technology is already underway. States like Texas and Wyoming, along with other countries, are competing aggressively for jobs, investment, and innovation. California has every advantage needed to lead, but bad policy decisions are pushing that opportunity away. Digital assets, blockchain networks, and stablecoins are becoming an important part of the future of finance and payments. If California falls behind, America falls behind with it. WHY THIS IS HAPPENING California’s leadership has adopted a “regulate first, figure it out later” approach to innovation. Instead of creating clear rules that encourage responsible growth, policymakers have created uncertainty that drives companies and investment elsewhere. Companies should not have to guess what the rules are before they invest and build here. California has already seen what happens when government makes it too difficult to build, invest, and innovate. We should not repeat those mistakes with one of the most important emerging technologies in the world. THE PLAN 1. CREATE CLEAR RULES FOR DIGITAL ASSETS California should provide transparent and predictable rules for digital asset companies instead of overly broad regulations that create confusion and drive investment elsewhere. California should clean up the Digital Financial Assets Law and ensure state rules complement emerging federal frameworks instead of conflicting with them. 2. PROTECT PARTICIPATION IN THE DIGITAL ECONOMY Californians should be free to securely control their own digital assets and lawfully participate in blockchain networks without unnecessary government interference. California should end its misguided restrictions on staking and allow Californians to participate in lawful staking services. 3. SUPPORT BLOCKCHAIN INNOVATION AND KEEP CRYPTO JOBS IN CALIFORNIA California should be the best place in the world to build crypto companies and blockchain technology. We should lower barriers to building and stop driving companies, investment, and talent to other states and countries. 4. PROTECT CONSUMERS AND CRACK DOWN ON FRAUD Government has a responsibility to aggressively prosecute scams, fraud, and criminal abuse. But enforcement should target bad actors, not crush legitimate innovation and responsible companies. CONCLUSION California became successful because we built the future instead of fearing it. We have the talent, entrepreneurs, and companies needed to lead the world in digital assets and blockchain technology. But leadership requires a governor who supports growth, encourages innovation, and creates clear rules instead of uncertainty and bureaucracy. Instead of driving opportunities away, California should be the place where the future is built. ← Back to all policies

---
snapshot_id: 2519df69-274a-5a24-82bf-e88b088fec6b
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## California Governor Debate - CNN (General Election) - OTR page: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7 - Video: (no video url) - Date on On the Record: 2026-09-30 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, bec5ef3b-095b-4d7d-9117-db81e407cb5e [1:23] I love the way that Javier says the wealthiest are people who are earning less than $150 ,000 a year struggling. But first of all I just want to say thank you to CNN for bringing Javier out of hiding. He's barely been seen in public since the primary four months ago. It's very important we have this debate and the simple point is that the quickest way to get more money in people's pockets is for the government to take less out. That's what I'm going to be doing and it's not coming from the budgets that he describes you know what it's coming from canceling high -speed rail which he's promised to [2:27] So just to be clear you want the people working so hard and barely able to survive I've been in every one of our 58 counties the struggle that people face with the highest cost of living in the country and the highest taxes you want to ask them to continue to pay taxes at same rates? See, again, the misrepresentation. [3:15] happy to talk about that. Javier is right about that. As well as helping working people, [3:23] as well as helping working people, we need to bring jobs back to California. Right now, because of your policies, we have the highest poverty rate and the highest unemployment rate in America. That's because high taxes have driven business out. So we need to incentivize jobs to be created in California instead of sending them to Texas. What I didn't hear was a single thing from Javier about how he would actually help people with the cost of living. And in fact, if we continue with his policies, that's another $11 ,074 a year extra that you would pay [4:52] much more straightforward than I think people realize. There's a couple of simple things that we can do to restore that California dream of home ownership. Number one, the quickest way to reduce the cost of housing is for the government to stop making it more expensive. A recent survey found that the average new home in California is subject to $200 ,000 in government fees and regulations. I'm announcing tonight that I will cap that at $50 ,000. That is $150 ,000 off the price of a new home. Secondly, we need to stop forcing apartment buildings into suburban areas and having all those battles between NIMBYs and YIMBYs when we've got so much space that we could building in in California and then the final part is to build as we used to do in this state the magnificent California dream 10 new cities that's my plan with counties bidding to host the construction of the new communities that will help young people follow their dreams here in California instead of having to move to another state. [6:07] problems Jake is that we've had these kind of top -down targets rather than and they never get met and they make all these promises and exactly as Javier said is the definition of insanity is is doing the same thing and expecting a different result I've got a completely new approach instead of the set of Sacramento forcing this onto communities I want communities to build the housing that meets their needs. [7:09] He hasn't explained how he would actually reduce the cost of housing. We have the highest... No, you didn't. You said that... I would cut red tape. Red tape needs to move fast. What's the track record that you've shown in standing up to the legislature in Sacramento when you were there as attorney general, you did nothing to push back against the and the craziness of that legislature. You can make up the facts. I could get into [7:37] Tell us one thing you did when you were in the, when you were state attorney general to push back against the growth of red tape on housing and everything else. Just one thing. Sure. I [7:47] city [8:18] huntington beach we've got communities up and down the state that want to build but they're being stopped from building by the legislation the regulations and the red tape that his party has put in place. And I said, I would cut the red tape. [8:31] Why should it? It's like your question. The definition of insanity is believing that the people who put the red tape in place are now somehow going to cut it. Gentlemen, [9:10] Well, I think this AI question is actually a different one for California than the rest of the country because these companies are based here and because of the fact that so many businesses have been driven out of the state, our finances are really dependent on these companies. And the problem is that the jobs associated with AI, the high -end manufacturing and infrastructure, that's all going to other states like Texas and Arizona. And the first priority with this industry is to make sure we get all those jobs here in California. The second thing that's very important I think we can all agree on is that this is the least complicated part. At least let's protect children. I think we can all agree on that. And that's why I've said that we should have an immediate pause on AI in the classroom, because right now we're seeing real concerns about something called cognitive stunting, where children's ability to learn is being impeded by AI. In terms of the regulations, I want to make sure that the priority for these companies is safety, making their products safer. Whether that's done by them or we need regulation, we'll see how quickly they act on the promises they've made. [10:28] Well, we'll have to see. They made a number of commitments yesterday. This is very urgent, and I will hold them to that. And as they said in that announcement that they made yesterday, it may require regulation and legislation. I think that should be led in California because this industry is here. You've got a lot of people putting out their opinions on this who really don't know what they're talking about. Here in this state, we lead this industry and I think we need to lead the regulation of this industry as well. [11:48] I just want to ask you a very simple question. How can we possibly trust you on this when you are funded by Big Tech and AI? How much money have you taken from OpenAI and Anthropic? [12:04] much money have you taken from OpenAI and Anthropic? [12:27] you've never done it. [12:28] What I've never done is what you've done in your 36 years as a career politician, where you've never created a job. You've never actually had to make any money of your own. All you've ever done is spend other people's money in every government job you've had. According to your Democrat colleagues, the ones who worked with you, like Susan Rice, who worked with you side by side when you were in the Biden cabinet, she described you as an idiot. She called you bitch ass. Why did Susan Rice, a respected political leader, call you an idiot? [14:42] If you're Javier Becerra and you're the candidate who is supported by the machine in Sacramento, the unions, big business, all these people that for 16 years have given us the highest cost of living in the country, made it impossible to build anything, given us the highest unemployment rate, the highest poverty rate, then we're not going to get the jobs in this state that we so desperately need. And that's why we've got to try something different this time instead of voting for more of the same and expecting a different result. [15:49] is all you can do is point to the same people the same organizations the same policies that have given this state the worst homelessness which you gave Gavin Newsom an A grade for Unbelievably, the highest cost of living, the highest cost of doing anything, the highest unemployment rate, the highest poverty rate. It's impossible for regular working people to live in this state anymore. That's why two million people have left just in the last few years. And all you're offering is more of the same, backed by the same corrupt machine in Sacramento. We've got to change the - I'll let [17:03] Well, as you said, Jake, there is a scope within the law, SB 54, our Sanctuary State Law, as it's known, for there to be cooperation on a long list of categories, specific crimes and specific circumstances. And so I would follow the law. And in fact, my goal here would be to lower the temperature on this whole question. I'm an immigrant. My parents were immigrants from Hungary to England. And so, I want to make sure that we protect our legal immigrant communities and we enforce the law. Everybody agrees that we need secure borders and that we've got to make sure that people who are in this country illegally, who've committed dangerous crimes, should be removed. But that's not happening in California every week, pretty much. We hear horrific stories of crimes that have been committed because of this partisan posturing by the politicians in California that just refuse to follow the law as it's written, even California sanctuary law, which allows for those kinds of criminals to be removed from the country. [18:15] It's about enforcing the law. I mean, the federal law is, immigration law is obviously a federal matter. And my whole aim here would be to lower the temperature. We've got to get this whole debate back to where most people want it to be, which is to prioritize the removal of dangerous criminals. That's not happening in California today and that's because they're playing politics with the issue instead of protecting public safety and that will be my priority. [19:31] You're not enforcing and your party isn't enforcing California law as it is now. And what a disgraceful remark that was. I don't think people want to hear that kind remark in a debate like this and why would you deport every [19:49] said people want to hear it's solutions to their problems not these unpleasant political attacks that don't help anyone immigrant or not with the problems that they're facing the cost of living all of the problems that you have no solutions to whatsoever so all you've got is the talk about your federal politics your All you ever say is Trump, Trump, Trump, and that's nothing but an insult to every Californian who is desperate for something to change in this state and all you're offering is more of the same. Your words, [20:27] Trump, [20:31] That's all you can say on every question because [20:55] Again, because he's got no arguments. Don't try to escape your own words. Because he's got no arguments and no solutions and nothing to say about how he would change anything about how California is run. [22:35] Mr. [22:36] I cannot believe that you're standing there trying to make these arguments. When you were HHS secretary, you were responsible for 479 ,000 unaccompanied migrant children and for their welfare in camps that you ran. You sent them because you dismantled the vetting that should have made sure that they were with a safe, protective family or sponsor, you sent thousands of young children directly into the clutches of child sex and labor traffickers. Hundreds of thousands of children that you were responsible for are still missing today. A hundred thousand of them are under 10 years old. So I cannot believe that you haven't apologized, That you you have any kind of sense of shame or responsibility for what you did to those children and you stand here Lecturing people about immigration when you treated these most vulnerable children unaccompanied children in this way those [24:46] The original investigation that he's now trying to deny was by the New York Times, and it won a Pulitzer Prize. These arguments were made in the primary by other Democrats, including Antonio Villaraigosa, the former mayor of Los Angeles. And you tried the same trick then, to deny responsibility. I cannot believe I've seen the testimony of the victims who were sexually assaulted, and you're proud of putting them into the hands 200 children were sent to one address that turned out to be a contain a lot because you dismantle [26:36] Yes, sensible things that will actually help reduce carbon emissions without hurting every California family and business. For example, it makes absolutely no sense right now to do what we're doing, importing oil halfway around the world from the Middle East and from South America when we have abundant oil reserves here. That actually increases carbon emissions as well as raising gas prices. As long as we're using those energy products in California, let's use what we produce here, which is produced cleaner than anywhere else in the world. Secondly, wildfires. When you have these mega wildfires that burn out of control, they release much more carbon dioxide than is saved by these ineffective and costly climate policies. So we'll have proper forest management to reduce the risk of mega wildfires. That will reduce carbon emissions. And so right through all of these policies, we need to be practical and sensible about these goals rather than just following ideological objectives that increase the cost of living for every California family and business. [28:30] I'm gonna cut the bureaucrats that they've increased in massive numbers that are making everyone's life more expensive and difficult and cancel high speed rail and cancel the payments to nonprofits that are ripping us off when it comes to homelessness. That's how we reduce taxes for every worker. But I just wanna ask you a question about why you're not gonna change. Just look into that camera and tell everyone the national average gas price in America today. [29:01] the [29:40] in Sacramento so that we can give firefighters a tax cut so they're not struggling. Okay, gentlemen, we're gonna [31:25] So Javier gave, when we were asked to give Gavin Newsom a grade on homelessness, he gave him an A. And he's standing there after 16 years where this absolute scandal shames our state saying that suddenly he's gonna go in new direction. This is what's so insulting, actually, about this attitude we get from the Democrats, that just you're going to keep voting for the same thing and you're going to just suck it up because that's what happens in California. We need a plan to change policy for homelessness, not more of the same failed policy. [32:50] I was there in Altadena this week [32:53] and the money that's being withheld is actually the money that Gavin Newsom promised and they said that when you went there, you didn't even, you didn't even bother, you didn't bother to listen, you didn't bother to listen to the stories of local people who feel so terribly let down by the California government. And as usual, all he wants to talk about is federal politics. [35:20] Mr. Helton? I agree that we can't drive more tax revenue out of our state because we need that money here and this initiative would do that. But the priority has to be working people, not just making sure we don't drive the jobs out, but actually we create jobs and that we reduce taxes for people who are struggling. If you earn around $70 ,000 in California just above the typical individual earning, you're paying 9 .3 % tax. That's higher than the top rate in most states. He's got no plans to do anything about that. He's got to help working people. [36:29] votes? As I've said, I've got confidence in what we saw in the primary and in this process, but the thing that I can't believe is the attitude you get from the Democrats who've been running this state about our elections. We just had Karen Bass, the mayor of LA saying, we don't need an election for governor because the Democrat is going to win. And that is the attitude we get from these people who've been in charge of our state for 16 years, and they think that they can just do whatever they want, get whatever bad results, the highest taxes in the country for the worst results, taking everybody for granted, taking their votes for granted. That's why he's not trying to earn anybody's vote. That's why he hasn't been campaigning in this election. They take you for granted. And I just wanna ask every Californian, aren't you tired of that? It's time to try something different Instead of the same thing over and over again. He wasn't even supposed to be the candidate He was the sixth or seventh choice, but they said it doesn't matter as long as it's a D That'll do secretary won't do we need change in, California. Thank you. Just want to try something different. [38:33] Helm There's a majority in this state who agree that it's reasonable to show ID when you vote But the thing that we have to understand is that if we vote just as Javier said earlier if we vote the same way this state as we've been doing we're gonna get the same results and this attitude of just constantly talking about national politics because he's got nothing to offer to change the direction of this state when people are suffering so much and he takes no responsibility for the policies that he supported for the last 16 years of one -party rule is an insult to every California. [44:43] No, I'm pro -vaccine, but I think the data shows, when you look at different ways that this very, very emotional issue for a lot of parents has been handled, particularly since the pandemic, when Javier forced children to be vaccinated, when there was no public health or scientific justification for that whatsoever, forcing little babies and toddlers to wear masks, when there was no justification for that whatsoever, and it's become very contentious. And the evidence shows, as the current head of NIH has made clear, when you look at the data around the world, the places where the requirements, the mandates are lower, are the places where you actually have higher compliance, where parents don't feel that they're being bullied into doing something that they don't want to do. And that's what I wanna see here. [45:40] the law in California, in any case. Well, [45:45] the law much as Javier would like to, I'm sure, in many areas. I would follow the law, and I think that the evidence is that if we can move away from this over -prescriptive attitude where you're telling parents to use so many different vaccines that they're concerned about and actually do it without those kinds of mandates, The evidence from other places is you get higher compliance with the vaccines that are really important for public health. [47:16] guidance to the states? We gave guidance. That's not mandatory. Why did you [47:21] suggest forcefully that children should be given the COVID vaccine? [47:51] When he was HHS secretary, he suggested that children, young children, should wear masks, two and three -year -olds. That's right. mask, there was no public health justification for any of that. He went along with the groupthink. This is why you can't trust him because he's been a bureaucrat and a career politician all his life and he goes along with the groupthink instead of actually standing up for facts and in this case the science. He went against the science and along with the politics and the groupthink. That's why he can't be trusted. [49:16] Yes, and in fact, I will increase affordable, reliable healthcare for Californians. Right now, so many families and individuals have healthcare in name only, where they actually have such a high deductible and such a high premium that it doesn't really mean anything. That's why I've announced my plan for a working class healthcare guarantee that will have a low premium and a low deductible by cutting out the waste and the fraud in the system. The fraud, by the way, that Javier unleashed when he was HHS secretary, he dismantled the fraud unit at HHS. He changed the policy, so that hundreds of billions of dollars were lost in fraud. And when it comes to what he describes as cuts, it shows that first of all, he can't even do math because the amount of money is going up. But secondly, what he's really talking about are work requirements for Medicaid. And the same exact work requirements for Medicaid that have been put in place by the federal government have been matched by Gavin Newsom for the California part of the system. Thank you. So the question for him is, is he going to do that? [51:00] Mr. Helton? If you're against the work requirements, will you then remove them for the California part of the system in the way that Gavin Newsom has imposed them? Will you remove that? [51:45] So you're going to keep the Gavin Newsom [53:19] Mr. Allen, who's been in charge when all those jobs have gone? Donald Trump. When this industry has collapsed. The Democrats, the Democrats in California have run this state for 16 years. He asked me earlier not to interrupt. I see he's not following his own advice. That's okay. [53:36] The Democrats have been in charge for 16 years as the jobs have gone, the industries have gone, and this city, this iconic industry, is on the brink of collapse. And it's the same with so many other industries. Agriculture, which he helped destroy in this state by suing to stop our farmers getting the water that they need. My plan to bring Hollywood home would make us competitive with the best in the world and reduce the bureaucracy and the red tape, which also has been piled on by Javier and his friends. Let me clarify. [56:16] Mr. Hill. Well, none of that is true. What is true is that yet again he's talking as if someone else other than the Democrats, his party and his friends and his legislature in Sacramento that he did nothing to push back against when he was attorney general haven't actually been in charge of California's education system that spends nearly the highest amount in the entire country for some of the worst results. We need reform and change. We need to make sure that every student reads by third grade. We need to use phonics in our school system to teach kids to read. We need accountability for teachers and for individual schools. None of that will happen because he is sponsored by the teacher unions that have been such a big part of the problem in California. [57:27] about him. [57:28] We have some of the worst results in the country after 16 years of Javier and his policies being implemented in California. As you said, Jake, less than half the students read a grade level with math. It's 37%. It's a catastrophe for our young people. We cannot go on like this just as we can't go on with the highest cost of living, with the highest unemployment rate, with the worst homelessness. All of these things are the result of the policies that he wants to see more of. It can't happen in California. We've got to try something different. [58:26] This is the most amazing state in the most amazing country on earth. And it's because we've got this rebel spirit that we do things differently. people build, we can grow anything, build anything, make anything, invent anything. That spirit is being crushed by this bloated nanny state bureaucratic government that Javier has been a part of for 36 years and would continue. It's time to try something different, not least to reduce the cost of living. And so if we have his policies for another four years, the average, the Typical California household will pay $11 ,047 more. If I'm elected governor, the starting point will be to reduce that cost of living. $11 ,000 is what you'd save. And you can check out individually how much you'd save if you go to savewithsteve .vote. It's a practical plan to reduce your costs. And when we do that, we'll make California once again the best place to start and raise a family, to start and grow a business, the best place anywhere in the world.

---
snapshot_id: c2fe85ae-0049-535c-b6fd-9af7337a027e
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/fd106ffe-d61d-4974-be12-12cea7dec518

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## CA Governor Candidates (CBS News) - Sanctuary State - OTR page: https://ontherecord.empowered.vote/meetings/fd106ffe-d61d-4974-be12-12cea7dec518 - Video: https://www.youtube.com/watch?v=gPfi_eDKkYE - Date on On the Record: 2025-11-20 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, dd0efd35-c1ae-47ad-8c11-cf8a52141f22 [6:13] with ICE? Yes. [6:17] are undocumented >> 100%. Um and the reason is that is is to is in everybody's interest that that happens. Why do we have these scenes of confrontation and chaos and crime going on around immigration enforcement? Remember this is federal law. um you may not like the law, but it is the law. And I think generally speaking, it's a good idea to enforce the law. What is the point of passing laws if you don't enforce them? And so I think the situation where you've got federal agencies trying to enforce federal immigration law and then you actively don't get the cooperation of local and state law enforcement. That's why you end up with ICE raids in communities because they say, "Look, if you helped us and if we could cooperate, you just get identify where the people are or you know, hand them over in the wherever it may be in the criminal justice system, then we wouldn't need to go looking in the community." [7:41] up. >> Correct. That's SB54. That was passed in 2017 when Jared Brown was governor. And I totally disagree with it. And again, there's an argument that it's unconstitutional. a good friend of mine, a guy called Michael Gates, he filed a suit in federal court challenging the constitutionality of that law, SB54. That's working its way through the courts. Um, it's perfectly possible, but that by the time I'm governor, the sanctuary state law will have been overturned. [8:21] >> That was the reason for the sanctuary state law to stop that kind of thing happening. I've got to tell you, I'm a legal immigrant. Um we moved here in 2012, visa, green card, citizenship in 2021, 9 years. I believe in immigration. I believe in legal immigration. I don't believe in illegal. The clue is in the name. It's illegal. Um there are many, opportunities for people to come to America the right way. Um, >> but to be fair, [8:51] >> Well, they shouldn't be walking across the border. I mean, it's illegal. It's illegal. [20:45] and >> of course they everyone it's a human right I agree with that everyone should have access to healthcare we're not a barbaric society right other states do it in a much more limited way, not in this goldplated way that we do here in California. So, I don't think there's any excuse because what is that really? That 12 billion of spending that is basically a subsidy to big business so that they can employ illegal immigrant workers and not pay their healthare because the taxpayer is going to bail them out. I think that's totally [21:43] >> It's interesting because you've got to look at the whole picture. So I agree with the point that this shouldn't be a burden on businesses. But of course, who's going to pay for the single pay? That's a massive tactic. Look, I you know, I was in the UK government. We have the National Health Service in the UK, and that is singlepayer. It's it's a massive component of the budget. It's a nightmare, a massive bureaucracy. People are very unhappy with a lot of the um outcomes. The outcomes are much worse. I nearly died as a result of the failings of a singlepayer health care system. The idea that singlepayer healthcare is some perfect nana is just absolutely not true.

---
snapshot_id: b228018d-3f9e-526d-92e9-4980939d7336
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/end-the-war-on-small-business

Saved from https://stevehiltonforgovernor.com/policies/end-the-war-on-small-business (rendered page text, built-in browser, 2026-10-07) POLICY ENDING THE WAR ON SMALL BUSINESS ← POLICY ARCHIVE ENDING THE WAR ON SMALL BUSINESS Small businesses create jobs, keep communities alive and give people the chance to build something of their own. They are an essential part of social mobility and the opportunity to build generational wealth. But the Democrats running California have spent years treating small businesses like a cash machine…or a problem to be managed - rather than a beautiful, vital part of our economic life and social fabric. Owners can owe the state $800 before earning a dollar. They spend hours dealing with rules nobody can understand and money defending extortionate shakedown lawsuits over footling technical discrepancies. Rents, energy and insurance bills keep rising, hiring gets more expensive and projects wait years for approval. It all adds up. Enough is enough. Steve Hilton is the candidate of small business, for small business. ‘Small business owner’ is his actual designation on the ballot. Steve has started and run a range of small businesses, including restaurants. He knows exactly what it’s like to try and stay afloat in the face of tiny margins, tough economic conditions and endless harassment and nonsense from government and bureaucratic agencies. Steve will end the Democrat war on small business, and give this essential part of our economy the freedom and support it needs. California’s small business owners have never had as passionate and committed a champion as Steve Hilton will be as governor. 1. CUT CALIFORNIA’S REGULATIONS BY MORE THAN HALF California has more than 420,000 regulatory requirements and prohibitions. By the end of his first term, Steve will bring that number below 200,000. Each state agency will have a public reduction target and will have to show its progress. A regulation should stay on the books only if it protects against a real harm and its benefit justifies its cost. Any major regulation expected to cost Californians $50 million or more will require an independent cost analysis and a public vote by the Legislature. Elected lawmakers should have to specifically justify regulations that impose undue costs on the public, with the default assumption that they are not justified. Starting a business will no longer mean chasing different agencies for registrations, licenses and permits. California will create one place to complete the state process, recognize comparable occupational licenses from other states and eliminate licenses that no longer serve a public-safety purpose. 2. END SHAKEDOWN LAWSUITS Trial lawyers and unions have turned California law into an extortionate shakedown racket. Small businesses are threatened with ruinous litigation over footling technical discrepancies, obviously manufactured complaints, and failure to comply with insane, pointless, bureaucratic processes created solely to generate more work for the trial lawyers who bribe the politicians that write these ridiculous laws. The legal process is engineered in a way that forces businesses to settle even when nobody has suffered real harm. It’s disgusting. Steve will enact real tort reform. PAGA will be ended by actually following the law as written, with the Labor Commissioner taking the first step in labor law enforcement, as laid out in Steve’s End PAGA plan, published last year. Employers who cheat their workers will still be punished. Private trial lawyers will no longer bring cases in the name of the state and collect enormous fees. A small business that makes an honest first-time mistake will receive clear notice and a reasonable opportunity to correct it before fines or lawsuits begin, provided the violation was not deliberate and caused no serious harm. The same protection will apply to construction-related accessibility claims. Businesses will still have to make their properties accessible, but an owner who promptly fixes a violation will not be forced to pay state statutory damages and attorneys’ fees. Fraud, repeated violations and conduct that puts people in danger will not qualify. 3. CUT THE COST OF EMPLOYING PEOPLE California forces private employers to navigate a separate workplace safety bureaucracy even though a national OSHA standard already exists. Steve’s Safe and Califordable Workplaces plan will move private employers to the federal OSHA baseline. California will keep a state plan for state and local government workers. This will reduce the cost of employing people, especially for small and fast-growing businesses. For a first-time, non-willful violation by a small business, the first response will be help rather than a fine. The business will receive plain-English guidance and 30 days to correct the problem. Written compliance questions will be answered within five business days. Employers who knowingly put workers in danger, retaliate against workers or repeatedly ignore violations will face tough enforcement. California-only rules that do not make workers safer or merely duplicate federal requirements will be repealed or rewritten. Workers’ compensation is supposed to help people injured on the job. Too much of the money is swallowed by lawyers, delays and fraud. Steve will set a first-term goal of cutting California’s workers’ compensation premium burden by at least 25 percent. Legitimate claims will move faster, the legal and administrative costs that drive up premiums will be cut, and fraud will be prosecuted. State Fund will also be reviewed and reformed if it is not lowering costs and helping injured workers. 4. ABOLISH THE $800 SMALL BUSINESS TAX California charges LLCs and many corporations at least $800 every year, even if the business loses money or never opens its doors. Steve will abolish this tax and veto any new state tax or fee that raises the cost of starting or running a small business. A business that earns no profit should not owe the state $800 simply for existing. 5. PAY OFF CALIFORNIA’S UNEMPLOYMENT DEBT California’s federal unemployment debt is driving up payroll taxes for employers every year through FUTA taxes (Federal Unemployment Tax Act). The most recent level is a 2.1% surcharge for every employee. This is an absolutely massive scandal, on so many levels. First, the tens of billions of dollars paid out by the Employment Development Department (EDD) should never have been needed in the first place: it was all a consequence of the cruel and counter-productive covid lockdowns, totally unjustified on any public health grounds, that viciously targeted small businesses while leaving many large businesses able to stay open. Secondly, the utter, disgraceful incompetence of the EDD led to over $30 billion being stolen in fraud, error and identity theft, including checks sent to prisoners on death row and United States Senators. It was an unforgivable dereliction of duty by Xavier Becerra’s Sacramento machine, and still no-one has been held accountable. Third, the gross negligence and incompetence of the Sacramento machine meant that California was the only state to not pay back its federal loan. And now every small business in our state is paying the price for the uselessness of our politicians and their appointed bureaucrats. Steve will pay off the debt by the end of his first term using savings from elsewhere in state government. Small businesses who were first penalized by the covid lockdowns should not be penalized again with a tax increase. Employers who did not create the debt will not be handed another state tax increase to cover it. Steve will also pursue legal remedies against Julie Su, now Deputy Mayor for Economic Justice under Mayor Mamdani in New York, and reduce the pay of all senior EDD officials who were working in the Department during this scandal. 6. PROTECT MAIN STREET FROM THEFT Retail theft is not victimless. Small-business owners pay through lost inventory, higher insurance premiums and added security costs. Proposition 36 will be fully funded and implemented, including the enforcement and treatment voters approved. Business owners should not have to accept theft as another cost of operating in California. Beyond these specific measures to help small business, Steve will cut the taxes, rules, lawsuits and other costs that make it so hard to run a small business in California. In particular, Steve’s other plans to cut energy costs will make a huge difference to every small business in California. Small businesses pay California’s high energy costs through their own gasoline and electricity bills and through the price of everything delivered to them. Steve’s Califordable energy plan will increase production in California and reverse rules that drive investment out of the state. The cost of every proposed energy regulation will have to be disclosed before it is adopted. California will not impose a vehicle mileage tax. The goal is $3.00 gas and cutting electric bills in half. ← Back to all policies

---
snapshot_id: db553313-0f4b-5c2b-8d9c-c12306a7269e
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/crack-down-on-masked-criminals

Saved from https://stevehiltonforgovernor.com/policies/crack-down-on-masked-criminals (rendered page text, built-in browser, 2026-10-07) POLICY CRACK DOWN ON MASKED CRIMINALS ← POLICY ARCHIVE CRACK DOWN ON MASKED CRIMINALS Tougher Penalties for Criminals Who Deliberately Hide Their Identity THE PROBLEM Criminals who wear masks or disguises while committing robberies, burglaries and other serious crimes are not doing it by accident. They are trying to conceal their identity, avoid being recognized and make it harder for police to catch them. California law recognizes that this is wrong, but the penalty is hopelessly outdated. Penal Code Section 185 makes it a misdemeanor to wear a mask or disguise for the purpose of evading identification while committing a crime. The law dates back to the 19th century and still refers to disguises including “false whiskers.” That may have made sense when the law was written. It is not an adequate response to someone who deliberately masks up to commit a serious felony today. California should treat the deliberate concealment of a criminal’s identity for what it is: an aggravating factor that makes the crime more serious and makes it harder to solve. STEVE’S PLAN Steve will work to create new sentencing enhancements for criminals who deliberately conceal their identity while committing a felony. If prosecutors prove that someone committed or attempted to commit a felony while intentionally using a mask, hood, disguise or other facial covering to avoid identification, apprehension or prosecution, the criminal would face an additional one, two or three years in prison. For violent and serious felonies, the additional penalty would increase to two, three or five years. This would not restrict lawful mask wearing. It would apply only when prosecutors prove that the defendant was committing a felony and deliberately concealed their identity in order to help commit the crime or escape responsibility for it. Other states have already adopted similar laws. North Carolina, for example, increased penalties in 2024 for crimes committed while wearing a mask or disguise to conceal the offender’s identity. California should do the same. Someone who deliberately hides their identity while committing a serious crime has made an additional choice to evade law enforcement and avoid accountability. Our criminal law should recognize that choice and punish it accordingly. THE BOTTOM LINE California already has a law against concealing your identity while committing a crime. The problem is that the law is antiquated and the punishment is too weak. Steve will update it to make sure California once again backs law enforcement and comes down hard on criminals who deliberately try to hide who they are. If you deliberately mask up to commit a felony, you should face additional prison time. If you do it while committing a violent or serious felony, the penalty should be even tougher. ← Back to all policies

---
snapshot_id: 9c64c78a-2386-59d3-9cd8-d11fceb3a7b4
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/wait-until-8th-for-smartphones

Saved from https://stevehiltonforgovernor.com/policies/wait-until-8th-for-smartphones (rendered page text, built-in browser, 2026-10-07) POLICY WAIT UNTIL 8TH FOR SMARTPHONES ← POLICY ARCHIVE WAIT UNTIL 8TH FOR SMARTPHONES INTRODUCTION Steve Hilton’s goal is for California to become the world leader in protecting childhood by working towards a voluntary but complete elimination of smartphones for children under 14, in line with the fast-growing “Wait Until 8th” movement which aims to set a social norm that children should not be given smartphones until 8th grade. While there are increasing calls for a complete ban on smartphones - indeed Steve himself floated this idea 11 years ago in his 2015 book ‘More Human’ - a simplistic ban would be neither practical, nor supported by parents and the wider public. THE PROBLEM Smartphones are the scourge of modern childhood. Their vast harms have been well documented, notably by Jonathan Haidt in his recent book ‘The Anxious Generation.’ Children should be connecting and playing with others on a human level, exploring and enjoying the physical world with a sense of fun and adventure, not glued like drones from a dystopian movie to pieces of glass and plastic. Parents instinctively understand this and have been driven to despair by the invasion of toxic technology, wrecking family life, relationships and the simple pleasures of childhood. Not to mention the disastrous impact of smartphones on education and learning. And it is getting worse not better…smartphones, video games, now AI…parents are desperately asking where this is all leading and if it will ever end. Well - the choice is in our hands. With Steve Hilton as governor, parents will no longer be asked to fight this battle one household at a time. Parents who do not want their children to have smartphones feel forced to give in when every other child has one. The companies behind these products know they are addictive and profit from getting children hooked as early as possible. However, current responses to this terrible problem are simply not working. The recent Meta settlement, for example, is a complete waste of time and money. Everyone knows that it will make no real dent in Big Tech addiction and the destruction of childhood caused by the scourge of smartphones. Social media bans, lawsuits, guidelines, exhortations, parental controls will do nothing unless they address the real problem: not the apps but the screens. Specifically, smartphones. Everyone knows that children will find ways to evade measures that aim to manage social media use, just as they are evading Australia's much-hyped social media 'ban' and all the others that have followed. It is time for our society to wake up. We cannot allow children unsupervised access to the internet. It is time to stop the destruction of childhood by focusing on the real problem: smartphones. STEVE’S PLAN WILL MAKE EVERY CALIFORNIA SCHOOL COMPLETELY PHONE-FREE California will adopt a bell to bell ban, strictly enforced. Current state law allows schools merely to limit smartphone use. Steve would require smartphones to be turned off and put away from the first bell to the last, with exceptions only for emergencies, medical needs and disabilities. HELP PARENTS ACT TOGETHER Every class in every school in California will be required to ask all parents to sign a ‘Wait Until 8th’ contract. The default assumption will be participation in the contract; parents will need to proactively opt out. Lists of parents who opt out will be published. A child with a smartphone will be the odd one out. INFORM NEW PARENTS Every maternal and family health provider in California will be required to invite every new parent in California to sign a ‘Wait Until 8th’ pledge. SETTING SOCIAL NORMS IN THE COMMUNITY Any organization receiving funding from the state of California: community groups, after-school clubs, sporting and cultural organizations, faith-based organizations…will be required to commit to a ‘Wait Until 8th’ policy as part of their contract with the state. MAKE BASIC PHONES THE ATTRACTIVE ALTERNATIVE Steve will bring carriers, manufacturers and retailers together to make affordable call-and-text phones widely available and stop pushing full smartphones at young children. Steve will work with the legislature to make knowingly selling smartphones, tablets or other addictive technology to young children a criminal offense. ESTABLISH A CLEAR MINIMUM AGE OF 16 FOR SOCIAL MEDIA Steve will put responsibility on the platforms to keep underage children off their products. This will only work if parents, schools, business and the wider community all move together. The goal is a smartphone-free childhood: a real childhood, to make it normal again for children not to have a toxic, addictive smartphone and to give children time for friends, family, play and the beauty and wonder of the real world. Let’s make California the world leader in making childhood more human. ← Back to all policies

---
snapshot_id: b82d6538-3cce-5e33-a5cb-2c8fc2f47d87
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/build-a-real-california-state-police-force

Saved from https://stevehiltonforgovernor.com/policies/build-a-real-california-state-police-force (rendered page text, built-in browser, 2026-10-07) POLICY BUILD A REAL CALIFORNIA STATE POLICE FORCE ← POLICY ARCHIVE BUILD A REAL CALIFORNIA STATE POLICE FORCE Paid for by cutting Newsom’s bureaucracy, not by overcharging California drivers OVERVIEW California needs more police officers on the streets. Criminal networks operate across city and county lines, and local police and sheriffs cannot be expected to take them on alone. Steve Hilton will turn CHP into a real California State Police Force and give it the manpower and resources to help keep the entire state safe. He will pay for it by cutting the bureaucracy Gavin Newsom built, not by raising taxes or piling more charges onto California drivers. THE PROBLEM CHP is not just traffic cops. It protects state buildings and critical infrastructure, investigates crimes that cross jurisdictions, responds to disasters and works alongside local law enforcement. California’s former State Police was merged into CHP in 1995. The statewide role already exists. CHP has never been built to match it. CHP has around 6,600 sworn officers and an annual budget of about $3.3 billion. That is not enough when organized theft crews, drug traffickers, human traffickers and other criminal networks are operating across the state. Then there is the way California pays for CHP. More than $3.1 billion of its budget comes from the Motor Vehicle Account. The main source of money for that account is vehicle registration fees. Drivers are bankrolling a statewide police force every time they renew their registration. That is ridiculous. CHP works for every Californian. Its budget belongs in the General Fund. Meanwhile, Gavin Newsom’s first budget proposed 215,821 executive-branch positions. His latest proposes around 251,000. He added more than 35,000 state positions while California’s population declined. That tells you everything about the priorities of the people running this state. STEVE’S PLAN 1. GROW CHP TOWARD 10,000 OFFICERS Steve will increase CHP’s annual budget to $4 billion and build the force toward 10,000 sworn officers. This will be phased in as new officers are properly recruited and trained. CHP will continue to keep the highways safe while taking on organized crime, trafficking and other threats that cross city and county lines. Police chiefs and elected sheriffs will remain in charge of local policing. CHP will be a force multiplier, helping local departments with major investigations, specialized capabilities and backup when they need it. 2. STOP USING CAR REGISTRATION AS A CASH MACHINE Steve will move CHP funding out of the Motor Vehicle Account and into the General Fund. This is essential to his Califordable plan to abolish the stand-alone DMV and cut annual vehicle registration to a flat $73. That fee will pay for secure vehicle records and the actual cost of administering registrations. That’s it. Drivers will no longer be forced to fund a statewide police force through excessive registration charges. 3. CUT NEWSOM’S BUREAUCRACY AND PAY FOR POLICE Steve will return executive-branch headcount to its pre-Newsom level. That goes beyond the minimum 10 percent bureaucracy reduction in Operation Zero Waste. Frontline public safety and essential services will be protected. The cuts will fall on the administrative and management bloat Newsom built. CHP will grow within the lower overall state headcount because bureaucratic positions will be cut more deeply. At current salary and benefit costs, returning to the pre-Newsom headcount will save roughly $5 billion a year. Enough to give CHP a $4 billion General Fund budget and start hiring the additional officers California needs. The money is there. Gavin Newsom spent it building a bigger bureaucracy. Steve will use it to put more police officers on the streets. Sources: California Legislative Analyst’s Office analysis of the CHP budget and Motor Vehicle Account; California Highway Patrol staffing; California Department of Finance workforce schedules for 2019-20 and 2026-27. ← Back to all policies

---
snapshot_id: c09a10e7-d1e7-5df0-a8c6-d365831c48f0
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/restoring-second-amendment-rights-in-california

Saved from https://stevehiltonforgovernor.com/policies/restoring-second-amendment-rights-in-california (rendered page text, built-in browser, 2026-10-07) POLICY RESTORING SECOND AMENDMENT RIGHTS IN CALIFORNIA ← POLICY ARCHIVE RESTORING SECOND AMENDMENT RIGHTS IN CALIFORNIA Steve Hilton’s Plan to Defend the Constitutional Rights of Law-Abiding Citizens THE PROBLEM The Second Amendment guarantees Americans the right to keep and bear arms. But after 16 years of one party rule, California Democrats have passed some of the most restrictive gun laws in the country. Instead of focusing on criminals who misuse firearms, Democrats in state government have targeted law abiding citizens with layer after layer of regulation. At the same time, the ability to obtain a concealed carry permit often depends on which county someone lives in. Some counties follow the law. Others impose delays and barriers that effectively deny residents their constitutional rights. Attorney General Rob Bonta has repeatedly defended these restrictions in court, including California’s ban on standard capacity magazines in Duncan v. Bonta and California’s so-called “assault weapon” ban in Miller v. Bonta. Californians deserve a governor who will defend their constitutional rights. STEVE HILTON’S PLAN Steve Hilton will take immediate action to restore Second Amendment rights in California, working in close partnership with his ‘Golden Ticket’ running mate, Attorney General candidate Michael Gates. When Californians elect Michael Gates as Attorney General, California will finally have a Governor and Attorney General aligned in defending constitutional rights instead of attacking them. 1. BRING CALIFORNIA STATE GOVERNMENT INTO COMPLIANCE WITH THE SECOND AMENDMENT As governor, Steve Hilton will issue an executive order directing all state agencies to work with Attorney General Gates to review their policies, regulations, and enforcement practices to ensure they comply with the Second Amendment and recent Supreme Court rulings. This order will require state agencies to work with the Attorney General to identify policies that conflict with the Constitution and take steps to bring those policies into compliance. 2. ENSURE CONCEALED CARRY LAWS ARE APPLIED CONSISTENTLY ACROSS CALIFORNIA California law allows residents to obtain concealed carry permits, but access to those permits varies widely depending on where someone lives. As governor, Steve Hilton will direct Attorney General Gates to ensure every county in California complies with federal and state concealed carry law, including the standards established by the Supreme Court’s decision in New York State Rifle & Pistol Association v. Bruen. Attorney General Gates will work with county sheriffs and local officials to ensure concealed carry permitting is applied fairly and consistently across the state. The Constitution should apply equally in every county in California. 3. REVIEW CALIFORNIA’S FIREARM LAWS FOR CONSTITUTIONALITY California has enacted hundreds of firearm related laws over the past several decades. Many of these laws were written before recent Supreme Court decisions clarified the scope of Second Amendment protections. As governor, Steve Hilton will direct the Governor’s legal team to conduct a comprehensive review of California’s firearm laws to determine which restrictions are unconstitutional under current Supreme Court precedent. Instead of spending taxpayer money defending laws that violate the Constitution, California should focus on enforcing laws against violent criminals. A SIMPLE PRINCIPLE The Second Amendment is part of the Constitution. California should respect it. Steve Hilton will restore Second Amendment rights in California while ensuring laws are applied fairly and consistently across the state. ← Back to all policies