You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-hilton-school-vouchers/labels/coder-1.json. Write JSON only, matching
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

### topic_key: school-vouchers
topic_id: 00b95a6a-75db-4521-b523-3326bba938de  served_revision_id: 88858826-90c0-41c9-a3a4-1d9f5b8c5307
Question: What role should vouchers and school choice play in the public education system?
  1. Eliminating voucher programs that divert taxpayer money from public schools to private institutions
  2. Opposing voucher programs and blocking their expansion, without moving to eliminate existing ones
  3. Allowing income-based voucher programs, open to a wider range of families under an income cap
  4. Expanding voucher eligibility to most families so parents can choose the school that best fits their child
  5. Providing universal vouchers so that education funding follows the student to any school — public, private, or religious — chosen by the family

#### Annex

# school-vouchers — served revision 88858826-90c0-41c9-a3a4-1d9f5b8c5307 (Season 2)

**Status:** draft (2026-10-01 refresh). Lines marked _(ruled 2026-10-01)_ carry an operator ruling
(Chris Andrews). Lines marked _(proposed)_ are a drafter's reading, not yet ruled.

**Question:** "What role should vouchers and school choice play in the public education system?"

**Orientation:** standard. Rung 1 is most restrictive of vouchers, rung 5 is universal. The rungs
order **who is eligible**: no one, no one new, families under an income cap, most families, every
family.

**Levels with a lever:** federal, state. The lever is the state programme
statute; federal action is mostly tax-credit scholarships (see hard cases). School boards hold no
lever on vouchers.

**Asked at:** federal, state, local (`compass_topic_roles`, CA_0302). Own words only at: local (codebook V2 "No-lever level").

**Synonyms:** "education savings account" (ESA), "empowerment scholarship account", "scholarship",
"tax-credit scholarship", "opportunity scholarship", "Choice Scholarship" (Indiana), "Utah Fits All",
"education freedom account", "qualified student".

1. **"Eliminating voucher programs that divert taxpayer money from public schools to private
   institutions"**
   - Means: end the voucher programmes that exist now.
   - Operative clauses: [a] eliminate existing programmes.
   - Establishing evidence looks like: a repeal bill, or a vote on a repeal amendment; own words
     calling for repeal.
   - Levels that hold a lever: state; federal (federal programmes only).
   - Known chair-shaped instruments: a single-subject repeal bill.
   - Commonly confused with rung 2 when the person only opposes an **expansion**.

2. **"Opposing voucher programs and blocking their expansion, without moving to eliminate existing
   ones"**
   - Means: keep the programmes that exist, but let them grow no further.
   - Operative clauses: [a] oppose expansion; [b] no repeal.
   - Establishing evidence looks like: a No on an expansion bill **plus** evidence against repeal. A No
     vote alone is `direction-only`: it does not separate 1 from 2, and [b] is a "without" clause
     that silence does not meet (V4.2).
   - Levels that hold a lever: state; federal.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1: see rung 1.

3. **"Allowing income-based voucher programs, open to a wider range of families under an income
   cap"**
   - Means: vouchers are acceptable when eligibility is limited by family income.
   - Operative clauses: [a] means-tested (an income cap); [b] open to a wider range of families.
   - Establishing evidence looks like: authoring or a final-passage vote on a means-tested programme
     with a cap.
   - Levels that hold a lever: state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because a high cap can admit most families. Code 4 when the
     passage shows the cap admits most families; code 3 when it shows it does not; when the passage
     does not let you tell → `direction-only` _(proposed)_.
   - This ladder has **no low-income-only rung**. A narrow programme for low-income families is
     income-based → rung 3. Clause [b] "wider range" compares with rung 2 (no growth); it is not a
     separate test of the cap's size. A No on raising an existing cap is still rung-2 territory and
     needs rung 2's evidence _(ruled 2026-10-01)_.

4. **"Expanding voucher eligibility to most families so parents can choose the school that best fits
   their child"**
   - Means: most families qualify, but not all.
   - Operative clauses: [a] most families, not all.
   - Establishing evidence looks like: an expansion bill with a cap high enough to admit most
     families.
   - Levels that hold a lever: state.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 5 when a phase-in ends in universal eligibility: code the end state
     the instrument enacts (so a phased path to universal is rung 5, not rung 4).
   - Commonly confused with rung 5 when every student is eligible but the number of awards or the
     money is capped. The rungs order **eligibility**, not budget size: universal eligibility with a
     capped appropriation or award count is rung 5 (Utah HB215 had a capped first-year
     appropriation). A cap written as an eligibility limit ("only students from …") is coded by who
     can qualify _(ruled 2026-10-01)_.

5. **"Providing universal vouchers so that education funding follows the student to any school —
   public, private, or religious — chosen by the family"**
   - Means: every student qualifies, and the money goes to the school the family picks, religious
     schools included.
   - Operative clauses: [a] universal eligibility; [b] any school, including private and religious.
   - Establishing evidence looks like: a universal ESA or voucher statute (e.g., Utah HB215, 2023). A
     statute that makes **every student eligible to attend a public school** a qualified student is
     universal; the definition does not have to say "all".
   - Levels that hold a lever: state.
   - Known chair-shaped instruments: a single-subject universal ESA or voucher statute.
   - Commonly confused with rung 4: see rung 4.
   - [b] and religious schools: a programme that excludes religious schools is not rung 5. A
     programme whose eligible schools include private schools and does not exclude religious ones
     meets [b] _(proposed — check against V4.2 "Silence is not a clause")_.

**Hard cases:**
- **A tax-credit scholarship is not rung 5.** It is a tax credit to donors, not funding that follows
  the student → `adjacent` (see the V4 omnibus example). This was written for the federal credit;
  the same reasoning applies to a state tax-credit scholarship _(proposed)_.
- **ESA money spent outside a school** (tutoring, therapy, home education). Non-school uses add
  choices; they do not remove the private and religious school option. Code the eligibility clause;
  non-school spending does not exclude rung 5 _(ruled 2026-10-01)_.
- **Charter schools and public open enrollment** move students among public schools → `adjacent`
  (charters have their own topic).
- **A budget vote** that funds an existing programme → V4 `multi-subject`.
- **A governor's signature** is a record; `chair-shaped` when the signed bill is single-subject.


## Sources

---
snapshot_id: 37af14c2-97cb-5046-82b8-7741dd79b733
source_kind: pointer (NOT evidence — you may not rest a chair on it; use it only to name a needs_source)
url: https://www.ontheissues.org/Steve_Hilton.htm

Steve Hilton on the Issues Follow @ontheissuesorg On the issues: Steve Hilton Hilton's Profile Governor Match | Other CA Candidates: Antonio Villaraigosa Eleni Kounalakis Eric Swalwell Gavin Newsom Katie Porter Tom Steyer Xavier Becerra Zoltan Istvan CA Governor (Republican challenger) Steve Hilton On the issues>> Wikipedia Ballotpedia Contact Steve Hilton Take the Quiz! VoteMatch CA politicians Governors (2026 election unless otherwise noted; AK : Mike Dunleavy (R,term-limited) vs. Click Bishop (R) vs. Nancy Dahlstrom (R) vs. Tom Begich (D) vs. Jonathan Kreiss-Tomkins (D) vs. Bernadette Wilson (R) vs. Bill Walker (I) AL : Kay Ivey (R,term-limited) vs. Doug Jones (D) vs. Tommy Tuberville (R) vs. Will Boyd (D) vs. Yolanda Flowers (D) AR : Sarah Huckabee Sanders (R,for re-election) vs. Fredrick Love (D) AZ : Katie Hobbs (D,for re-election) vs. Andy Biggs (R) vs. David Schweikert (R) vs. Karrin Taylor Robson (R,withdrew) CA : Gavin Newsom (D,term-limited) vs. Xavier Becerra (D) vs. …

---
snapshot_id: 4b22c186-405f-516a-bc1b-a350d81185c9
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/444fa3e9-9466-49b6-a1da-307226c0bbe2

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## The Race for Governor (Commonwealth Club World Affairs of California) - Steve Hilton - OTR page: https://ontherecord.empowered.vote/meetings/444fa3e9-9466-49b6-a1da-307226c0bbe2 - Video: https://www.youtube.com/watch?v=tj1fi4wBAa8 - Date on On the Record: 2026-01-23 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [1:01] So we moved here in 2012. My wife and my two sons, to California. But even before we moved here, I was I want to say I'm in love with California. The idea of California. Everything it represented. There was a time, actually. You mentioned David Cameron is before he became prime minister, and I was working for him. And, developing the kind of policy strategy and, and the ideas that we would take into the new administration. And there was a cover story in the Spectator magazine. The main one of the main political weeklies in the UK. And this and the headline was California Dreaming. This must have been around 2008. And the piece was entirely about, how Steve Hilton, David Cameron's policy guru, the that animating idea behind the vision that he's developing for for the future of the UK is to make the UK more like California. And how inspired I am by California. And so there's something very, very deep within me that loves this state so much. Even before we moved here, moved in 2012, my wife, my two sons, as I mentioned, not necessarily intending to stay, it was really for family reasons. When our second son was born, but we stayed here, we fell in love with it. I taught at Stanford, started a business, raised my family here. And as the years went on, including up to the point where I'm hosting a TV show very unexpectedly, I realized that actually, this state means so much to me. Most of my career has been doing things rather than talking. When you're when you're a TV host, it's an amazing opportunity, but you're just talking. And I really wanted to get back into doing things and making change happen. And as I thought about all of that, I realized my real passion was California. Long before I ever thought about running for governor. I actually started getting engaged in some of the big policy issues that affect our state. And the first one that I focused on was housing. So my first step in this direction was actually to try and put together a ballot initiative to deal with our housing crisis. Now we can get into the weeds on the policy of that, but actually the process of doing that, of trying to get something on the ballot, engaging with the legislature when that didn't happen, it really showed me how broken, frankly, everything is in California, including and probably especially our government. And that's the moment when I thought, you know what? I really want to get involved in trying to make things better and actually fix what's broken about California, especially our state government. [4:03] Well, because there's nowhere better than California. I mean, despite everything, of course, I think we can be a lot better than we are. Otherwise, I wouldn't be doing this. But this is the most amazing place on earth as far as I'm concerned. I have the great joy and privilege now, as part of this job of running for governor, of traveling the whole state. Almost every day I see something or I meet someone that just reminds me how incredible this place is. And I always think, just imagine, how great it would be if we had a good government instead of what we have now. So I there's no question. There's nowhere else I'd rather be. And I want to try and, bring that sentiment to everybody, especially the people who are either leaving or thinking of leaving, because we want people to stay here and build the future in California and make this state the best place to be to to whatever it is you want to do, whether you just want a, you know, simple life, you know, raise your family a home of your own, a nice neighborhood, good school for your kids so they have a better life or something incredible, you know, invent the company that's going to help us live on Mars or whatever it may be, whatever your dream, big, small, whatever, however you define it. I think the whole point of California is that there's nowhere on earth better to do it, and we're not there right now. We have been before, and I want us to be that place again. [5:35] Yes, exactly. And I [6:02] before I get to the politics, I just want to I want to say thank you for the. This is a cup of tea. So, as I've now like to say, hot tea, and, you know, I still have the accent. I'm a proud American. Now, just everyone's clear. Became a citizen in 2021. But there's some habits die hard. So I'm still on the tea. I'm a friend. I very much appreciate everything with milk. I know. I just. Terrible. [6:28] So I think that the truth is that, Without you, I mean, I'm sure we will get, into the actual Partizan politics. But even if you take that out of the equation, it's very clear to people that this state isn't working. I mean, you just listen to my Democrat opponents in the governor's race. None of them are out there saying everything's great. Let's keep going. Not a single one. I was really struck. When I actually, the first time that we had all come together. Not all, but, you know, some of the candidates, it was a forum in, Sacramento, and it was, I don't know, 5 or 6 of the governor candidates. We had Katie Porter, Villaraigosa. Tony, Atkins was still in the race. Alan Keyes was still in the race. I can't remember who else. And we were there talking about the issues and everything. I was really struck, actually, with most of the questions where the Democrats were all making the same critique that I was making about. You had Antonio Villaraigosa started? I remember I it really struck me the very it was a Chamber of Commerce event. So the questions were oriented towards their, you know, business concerns. And the very first question. He stood up. I can picture him doing it. And he went to the front of the stage and said, California has the worst business climate in America. We have to do something about that. And you have a lady like you saying, we are terrible at building housing. We got to do something about that. Katie Porter, it's impossible to raise a family here. It's so expensive. Tony Atkins with the regulations in the state are ridiculous. We all know. And so I think there is broad agreement that things aren't working in California, and that you could put numbers behind that. The Pope, PPC polling and other polls very consistently in the last few years show a very clear majority agreeing with the proposition that California is going in the wrong direction. So the way I put that is that there is a majority for change. There's a majority of Californians know we need change. So that's the starting point. That's why I think this is a good opportunity for a candidate from the from the party that's been out of power because people want to change direction. And so I think that's the real, opportunity I see there is, is just this real hunger for doing things differently. [9:18] meet this [10:02] Both my parents are Hungarian. My stepfather, also Hungarian. I was born in, in the UK, grew up in a very regular working class household, not just very, very normal. Not poverty, not wealth. Just a regular, working class family. But really, I think part of that very familiar story for immigrants of, of that sort of desire for upward mobility, climbing the ladder of opportunity. And that's what I was really picked up, which is we're here now. Your cousins are back in Hungary. I mean, for the first few, you know, I mean, when was this? I was born 69. The Berlin 20, you know, first 20 years of my life, it was a communist country. And we would go back to visit family at least once a year. And all my family would. They're stuck in a communist system where you had no freedom, really. I mean, Hungary was the was better than most. It was not as extreme as some of the communist countries. But you couldn't really do you couldn't stop. It was just a very different world than the one that I was born into, and had that sense of opportunity. And my, my mom in particular said, you got to make the most of it. You know, this is just compared what's happening in Hungary with what's going on here. So, you know, worked hard. My stepfather was was really, you know, my my dad left when I was young. And so I grew up with my mom and my stepfather, also Hungarian. He worked construction. He was a refugee. I mean, his story was the most dramatic. He literally with his brother and some friends from a village. They were in a small village in the western side of Hungary. They heard on the radio in 1956, with the Soviet invasion, the Russians are coming. He tells the story that the Russians are coming, okay, where we're going. And they literally ran for their freight. They ran, you know, they were not far from the border with Austria. They. And it's an amazing story, you know, climbing barbed wire fences and going through minefields. Half of them were killed. These are kids. He was 14 years old. That's the same age as my youngest son. Now, it's an amazing thing to think about. Refugee camp ended up in England and didn't really have much of an education. And so I ended up working construction, did well when I was, you know, growing up, we had a small general contracting business. So my childhood was earning a bit of money working on construction sites. But also I worked hard at school. I got to Oxford University. My first job, though, though, was project manager for a construction company. So I've always had that kind of, you know, real world experience. If you, if you, can put it like that. But I also worked for a little while in politics. I very interested in politics, worked at the conservative Party for a little bit when Margaret Thatcher was still prime minister, worked on a general election campaign. Did that for a few years, worked in advertising, is mentioned all over the world. And then inside, you know, really not understanding business from that point of view. Started my own company in, in England, including a restaurant that's a very tough business for anyone who's, you know, trying to make that work. And then while all that was going on, David Cameron, who had, who I'd got to know very well when we were both working, is really young, you know, kids, in the Conservative Party years before he, he'd gone into politics, got elected to parliament and then a certain point, 2005, decided he was going to run for the leadership of the Conservative Party effectively in the, in the party primary asked me to run his campaign. I did that, he won. Then I by then I'd started my own business, as I mentioned, left that worked with David Cameron. He became prime minister in 2010, went with him into ten Downing Street. I was senior advisor. I had my little office, next to the cabinet room and really encountered for the first time directly the how hard it is to make change happen in government. And that experience, which I always look back on, not necessarily as having been fantastically successful in what we try to do. In many ways the opposite, very frustrating. But it does show you it really taught me how hard it is and how you know what it takes to actually implement change in in government. And then as I mentioned, in 2012, we moved here. I mean, just what happened? I was taught at Stanford for a couple of years. Got the bug there for tag. I did a start up, did that for a few as founder and CEO of a startup, and then, very unexpectedly, along the way, wrote a few books along the way. And, and then very unexpectedly got the offer to host a TV show, which really was nothing I'd ever contemplated doing. [14:52] I if you. [14:56] probably not the [14:59] I think the I can't remember exactly, but I think that the actual, the way that happened was that I was in the UK, I wrote a book in 2015, which I think still is the one I'm really, you know, I feel very, you know, it's the it's the sort of broadest expression of, of how I think about the world. A book called More Human Designing a World where people come first. And that theme of the book was the decentralization of power, that things, the modern world has become too big and bureaucratic and centralized, and we need to put things back to a more human scale. And that it came out in 2015. There was a paper back in 2016, which I updated with my position on Brexit. So that was what was going on in 2016. I went back to do the book tour and as it were, it came out in favor of Brexit as, to me, a perfect example of the argument in the book against centralized power. Now, that was pretty controversial because David Cameron, who is a close friend and who I'd worked very closely with, was on the other side of that argument. And it got, you know, I did a few TV appearances. I think that's how I came to the attention of the powers that be at Fox, and that's where it came from. [16:37] Yeah. Gloria Romero. So Gloria and I got to know each other a few years ago when she was working on a ballot initiative for California, for school choice. And Gloria was the state senate leader for the Democrats. So, you know, a big figure in California politics. Very that's a really big role. And she was always, I mean, as she would say, someone who really understood and appreciated working bipartisan. And so that was where she was coming from, trying to make things happen. And that was back in the days when she was there, the there wasn't a supermajority. And you had to work with Republicans to get certain things done. And so she was someone who I've known for. She is someone who I've known for years now. When I started my policy organization, Golden Together, that was really the first step towards this. As I mentioned, housing. And then we worked worked on other issues. Gloria was there with me on that. We've worked together on education policy. But the thing is that, it's true that normally in the in this race for governor, it's and it's literally true that everyone is for the statewide offices elected independently. So it's not like a formal ticket, at the presidential level, for example, where you vote for one and you get both, you have you're going to have to vote for me and Gloria. But actually, it's broader than that because I've always seen this effort to turn around California as a team effort. And I guess that goes back a little bit to my experience in the UK cabinet government. I've seen how that works. It's not just one person. I mean, the Prime minister in the UK system is considered, you know, primas into Paris in the Latin, the first among equals. And it's a team. And it's true. I mean, I've started companies everything that you can't do anything without a good team. And that's why I always saw this race and, my role in it as putting together and leading a team of credible, serious people across the board so that, yes, that's Gloria for lieutenant governor. She's got a ton of experience. I'm an outsider running for governor. She's got a lot of experience in Sacramento. I think that's a good compliment. But broader than that. Last week we announced, as part of what we're calling the golden ticket, for California. Michael Gates, who's running for attorney general. I was there with Gloria to support his launch. Herb Morgan, who's running for state comptroller, very well qualified candidate for that job. We've been working together for months now on on the question of fraud and cutting waste in our state government spending. So that's four of us. And there'll be more. You know, I really see this as a team approach. [19:32] quite. I mean, but let's get into that. But there's a lot you can do without the legislature, of course. So it'd be good to work with the legislature. [19:51] Well, I mean, okay. But for me, the the strongest direct role you can have is through how you run the executive branch, in particular the hundreds of agencies where a lot of the things that are making it so impossible and expensive to do anything in California that's coming through these agencies where you have thousands of appointments and you can direct their work, you know, the Air Resources Board, the Coastal Commission, the state water resources control it, you know, and endless agencies. So that, to me is my focus in terms of what I can actually get done. [20:59] Oh for sure. No, no, no, definitely I'll be the Republican candidate in the top two, I'm sure of that. And the the party endorsement is obviously would be greatly appreciated. But it's not the only thing that matters in this race. [21:20] It does to a certain extent, but I don't know how much, honestly. And I think that it's it's, as I say, always welcome, as is the endorsement of county parties. That process is happening right now. It's, you know, I'm very used to that. I spent the last three years, four years traveling the state, meeting people, including at the local level within the Republican Party structure. And I've enjoyed that greatly. [21:55] Correct. The [22:02] candidates [22:05] seen each other a few times. I have a perfectly cordial relationship. Yeah. [22:14] argument that I make on my on my part and I've tried to avoid being negative about, about other Republicans and my, my, I, as I say, the there's plenty of people out there doing that without me adding to it. I make the positive case, which is that I've got a long track record of business experience, government reform experience, being out there campaigning, a broad policy expertise. I mean, those years of work, not just back in the day when I was, you know, working inside of a government at a very high level, but actually here in California, I mean, my those years where I've been traveling the state, meeting people, learning about the issues and developing policy solutions have really provided the foundation for this. So if you go to obviously there's a campaign website which is, you know, mainly focused on the ways that people can get involved and so on. But my policy organization called and together you go to the the policy section there, you'll see very detailed policy reports written by me on, all the big issues on energy, water, the business, climate, crime, education, you know, the, the there's, there's, a body of work there that really reflects the very high level of preparation I've put in to deal with these policy problems across the board. And I think that's really I would say, I would argue is that is why I'm the best qualified not only to win, but actually to do a good job once I've won. [24:09] Yeah, I'm. afraid I pay attention to the numbers. Very, very detailed race, as I always say. You know, I've started businesses, and you can't do anything without your investors. And this is this is the same. And it's like building a startup. You know, I've never run for office before, so I don't have a base of donors to go to, like my, other opponents. In fact, all of the I think I'm right in saying every single one of the serious candidates has run for office before. And so I had to start from scratch in a way that they didn't, the for the governor's race, it goes in periods of six months and, it goes up to the last period we're in ended December at the end of the year. And then everyone has to report their numbers by the end of January. So there's some people that haven't yet. Most of us have and cumulative. Lee, I think I'm kind of, I don't know, top in the top 2 or 3, but for the six. But it's growing. I mean, we're moving in the right direction. So for the last six month period, I remember I launched my campaign at the end of April. So we didn't have the whole of the first phase. So we've been in the race for less time than most of the other candidates. But for I do know the numbers for the second six month fair. So Antonio, very close to 2 million. Have you Bacerra 2.7 million. Katie Porter 3 million. Eric Swalwell 3 million. I was 4.1. So quite a long way ahead of the others, actually. [25:43] Yeah. I mean, we've got, a really big, broad base. That's one of the most exciting things about it, having, you know, these people who've run for office before, as I mentioned, we haven't done that. But the number of unique donors we have, which is something people look at, because that's really an indication of the breadth of your support and the grassroots support. You have 30,000 plus, which is a high number. I mean, if you look at Gavin Newsom and his donation record for the, the prop for the prop 50 campaign just now, I believe he had about about 100,000, something like that for that campaign he's been in. He's been running for office all his life. So that 30,000 number is a good number. [27:18] You're right. And I think the probably the most interesting thing about the polling is that the largest number is for don't know. Yeah. So 30 something. Exactly. So it's early in one sense. It's not early in another sense. I mean, we've getting to the point where, I think it'll be very clear who's going to make it through. I think that that's why I've been [27:37] very, I know my job is to campaign to, to to be that leading candidate. And that's what I'm doing. And I've, we've, we've we turned up the volume this year in terms of the campaigning. I was out there that two weeks ago with, analysis of. So going back a step forward, a step back, this issue of fraud is a huge issue for a lot of people because it's all come to light through the Minnesota scandal. I remember at the time saying when that really burst onto the scene in said around Thanksgiving last year, look how bad the fraud is in, in in Tim Walz in Minnesota. You can bet that it's a thousand times worse in Gavin Newsom's California. And I because of the just the fact that we've had so many years of one party rule now, 16 years of one party rule, which inevitably means you just get less accountability and challenge and and so on. And it breeds that kind of complacency and corruption and so on. And and then we started putting numbers on it. So the guy I mentioned, Herb Morgan, who's running for state comptroller, he and I teamed up, we put out there a, you know, just with the resources we have in our campaigns. Very simple website. Carly fraud.com to try and try and get tips whistle blows. That was a big part of the Minnesota story. We got hundreds of tips which you've been looking into following up. And then early the first Monday back after the holidays, we put out our estimate of the total. Looking at those tips, the direction that that helped us identify potential areas for fraud, the size of those budgets and so on, and the published fraud numbers that we've already got for 24 all or missing in, budgets that can't be accounted for, homelessness, 24 billion, employment department, 55 billion during the lockdowns, etc. our number was $250 billion. Our lower low end estimate. And it's actually going up the whole time. That's an example of how this year we are really out there campaigning more directly, more strongly yesterday, you know, that would include the announcements of Gloria or Michael Gates and the Golden Ticket last week. This week we're really focusing and it's the beginning of a campaign on the really the key issue, I think, for everyone in California, which is affordability. Yesterday and today we again, we've done a calculation how much more expensive it is to live in California as a direct result of Democrat policies. We just took a very simple calculation. The average cost for all the components of of someone's typical budget. So rent, utilities, gas, groceries and so on. Health care insurance. And we just took the national average for those items and the California average and did a very basic calculation. And here's the number $35,000 more in California, $35,000 published that yesterday. It's actually 34,000 a year. Yeah. Are you. [30:39] Well, extra. That's not the that's the addition. That's that's the surcharge. Well and. There's the San Francisco number which. Is well for everyone. It's different. And so we also published an online calculator. I'm sure you enjoy doing the numbers where you can plug in your own costs and see how much more you're paying for Democrat policies. It's called California Dem tax.com if you're interested. We'll be promoting that again today. But I'm just giving these as an examples of how we're stepping up the pace, raising the volume, and really going to be out there campaigning to do exactly what you said, which is to be the dominant candidate. Certainly on our side of the political fence. [32:05] Well, let's start with the number of people who want a change of direction, the 60, 65%. Well, some. Think it should [32:14] don't. Know about that. You don't [32:18] actually, I don't I think that's about to I there are some people who think that, but it's a very tiny minority. So I think that's the starting point. It's also, yes, registration. You could look at that number, but in the end, that's not how people vote. So a lot it's a big proportion. It used to be the Repub for a while Republican registration was number three. Democrat then declined to, you know, no party preference. And then [32:44] Republicans that's flipped recently Republican registration has been increasing. Democrat registration has been, stagnant. And so it's moving in the right direction for Republicans. But the real point is actually not registration isn't what matters. It's voting. And if you look at the voting numbers, there's been a very there's a there's a basic thing that I think is often overlooked, which is that it is a more Republican state than people think. So when you listen to the commentary sometimes and you'd think it was like an 1820 state, it's really not, the average vote share, I think, for Republican statewide candidates in the last 20 years or so is around 41%. So let's just call it 40%. That's that's a baseline that is higher than a lot of people realize. And of course, it's a big gap. I'm not I've always said this is not going to be easy to win, but it's not impossible. And then the other thing I want to look at when you talk about turnout, I did it just quick back of the envelope calculation, as is often done to try and estimate the turnout at a midterm election this year. And you typically have a lower turnout. But and if you do that and you try and usually you take the average of the last two to get an estimate of what the turnout will be. If you do that, the number, the the projected total number of votes this year in the general election in November is actually 11.7 million. So it's very close to your number. The target to win just over 50% is 5.9 million. That's the number that's in my head. 5.9 million. And then you look at voting in the presidential year last year, how many people voted for President Trump in California without the president even campaigning here? 6.1 million. How many voted for Steve Garvey for Senate? 6.3 million. In other words, when people say you can't win because there aren't enough Republican votes, it's literally not true. There are enough Republican votes. You've got to get them to vote in a midterm election for the governor's race. And there are things you can do to effect that with your campaign, your ground game, all those things that we're working on. And there's another really important factor this year, which is and you mentioned call to me a couple of times, calls a good friend of mine, we've been working together, but he's really been in the lead, along with some others on voter I.D., the ballot initiative on voter ID, which is now pretty much certain to be on the ballot in November. That is a very, very big turnout machine for Republicans, because they really care about their Republican voters. And so I think that things are lining up to, to point is in a direction where we have got the chance to turn out the number of votes we need. Of course, it's true that that's not that you got to do more than that. And I think that this is the second thing I'd say on this, which is the nature of my campaign, the way I'm going about this, and you can see it from the platform that I've put out there. And so it's positive, practical things, pragmatic things to help people in their daily life, working families, small businesses. It's not ideological. It's not divisive. It's all, you know, what are the key things I'm talking about in this campaign? Cutting gas prices $3. Gas, electric bills. Cut your bills in half a home. You can afford to buy your first 100 grand free of state income tax. These are very practical things that I think everyone can get behind. [36:59] First of all, I thought I think prop 50 was I mean, I totally disagree to try to stop it. It's unconstitutional and so on, and made those arguments in court. We ran into a very Partizan judge, so that didn't go anywhere. So I don't want to get into prop 50 other than to say it, it it's very distant from those everyday practical concerns. That's why I think you had a low turnout across the board. It was a low turnout because it's just for regular people who are working incredibly hard, often 2 or 3 jobs to make ends meet because everything's so expensive in California. It's such a distant thing. Something about districts. What are you talking about? It was it was very, you know, distant from their daily experience, whereas this race is very directly related to their daily experience. And of course, that would be my job in the campaign to make that clear. And you can predict exactly as you've done exactly how this campaign is going to go. Well, it's me against whichever Democrat gets into the top two. They will be making the entire thing about Trump, and I will be trying to make the whole thing about California. And that's the battle in the campaign. [38:40] Well, look, the my focus is California, and I think that's really going to stick to that in the campaign, which is that I'm running for governor of California. Here are my plans to make life better here. One of the things I think that will be helpful as governor is that I do have a relationship with the president, and half the cabinet are friends. I think that it's helpful to have someone here in California has a good relationship with, at least for the first two years of the governor's term. It will be a, Republican administration led by President Trump. I think it's going to be helpful. It means that I'll be able to get a better deal for California. So I think that's an argument that you can put against the, how the Democrats will want to characterize it. And I think that beyond that, one of the things that is really, you know, why if you go back to when when Donald Trump, as he then was first came on the scene, the thing that was interesting to me, I just finished writing that book human. [39:40] 2015 and then doing the US version, the US edition, which is like, you know, changing the stories on the data and so on to make it, focus on the US and those and that book is structured in terms of broad issues. So, like, poverty, inequality, food, health, education. And one of the things that I, really took absolutely brought me up short and a very much determined to a certain extent, my orientation politically from then on was this chart, which I think is now become pretty well known, because I was just trying to update data from the UK edition, and this showed the earnings of the majority of American workers. I think the technical economics term is that non managerial, non supervisory workers, it's about 80% of the workforce. And it plotted the earnings since you know for the last few decades, the last half century actually on a chart along with corporate earnings and the earnings of the everyone else the top 20%. So we hear about the top 1%. It's not really that it's the top 20%. That's where the real differences and it's an absolutely stunning chart where basically you've got a hockey stick for corporate earnings, a hockey stick for the top 20%, absolutely flat for the majority, for 80% of American workers. If I'm right, I think the it's since I think 1974 it's amazing after inflation. So basically you've had total stagnation for the majority of workers since the mid 1970s, whether whatever administrations have come and gone, globalization, this stuff totally flat. And I think that really explains so much about what's been going on, what we now think of as the populist movement both on left and right, Bernie Sanders and, President Trump as it was in 2015. They both came up together. Brexit, all of these things. And so the argument I always made make and still make is that Donald Trump was the first Republican to really understand that, actually, and to understand that the majority of American workers have been losing out. And that's the broad basis on which I, identified with him and the arguments he was making. And particularly in that election, I thought, actually, Hillary Clinton doesn't get that. She doesn't. And now people talk about the and all the things he's talked about China, immigration, the role of low wage immigration, who is making that argument about open doors, open borders in 2015 and 2016, Trump and Bernie Sanders together. Bernie Sanders was making the argument for closing the border because because the competition from, cheap low wage immigration, low wage immigration. So I think that's the real driver for me. And I think that remains true. And one thing I would finally say on that is that what you saw and that changed that pattern changed in the first Trump administration up to the pandemic. But for the first time in decades, the earnings of the lowest 20% rose faster than the earnings of the people at the top is a really big change, and I'm optimistic that some of the economic policies that have been put in place last year will have that. And the energy, deregulation, all these things coming together that I think we'll see another boost in economic, result, the positive economic results, especially for working people. So I think we don't by November, but September, October, you know, election time, I think it could be a very different story about, this second Trump administration in terms of the economic impact. [43:48] what right. And I think that the point is that I look, here's another way of looking at it. Gas prices. So we have the highest gas prices in the country, particularly hurts working class Californians who are driving their cars in their trucks. You often hours a day to get to. It does not affect, as I sometimes put it, the Marin County climate worries and that sort of work from home tapping away at their MacBooks right. They're not affected by gas prices. It's working class people who are, we have the highest gas prices in the country, high even than Hawaii in the middle of the Pacific Ocean, even though we have abundant, oil and gas reserves here in California, we there are 40 states now. I my my plan is to get to $3 gas. We have five, six, seven, $8 that there are 40 states in America where it's $3 or below. President Trump is the president in all of those, we have the highest unemployment rate in the country. President Trump is also president, where we have the lowest unemployment rate. We have the highest poverty rate in the country. The president President Trump, is also the president in the states with much lower unemployment. And so there's something to blaming everything on Trump is obviously ridiculous. Now, I know they'll try and do it because they've got nothing else, because 16 years of one party rule by the Democrats have produced total failure on every front. So what else can they do except blame Trump? But if you just think about it for a moment, it's obviously ridiculous. [45:52] bargaining. [46:16] but just to be clear, I don't have a plan, right now for, ending collective bargaining or anything like that, because it's not as simple as just saying, I'd like to do that. What I, what I have done is repeatedly cite and quote, former Democrat Titanic figures in the Democratic Party, starting with, FDR, who argued that the whole concept of government unions is a unconstitutional and b morally wrong, where you have people who are basically on both sides of the negotiating table. When it comes to, bargaining for things that are funded by the taxpayer. And of course, you see the impact most clearly in the devastating results in our public school system, which is so strongly controlled by the teacher unions, that have turned into something that is all about protecting their members rather than promoting education for students. So I just think that I just got to tell the truth about what's happening, by the way, with Quick Story, when when I was working on housing, I remember having a meeting with in the Ledge with a member of the legislature and talking about my plan, and they said, oh, this is fantastic. We transformational. And I said, great, let's work on it together, you know, bipartisan. And they said, well, I couldn't support you publicly. I said, why not? So, well, the unions would hate it. And we were sitting in I remember the office above Sacramento, you could see the capital and this is. Yeah. So they'd hate it. Yeah. Well, they just wave the arm like this. The unions run this place. That's an elected member of the legislature saying, now that's outrageous. only [49:13] Well, I mean. That's what's wrong with the system. I mean the top two system was intended, to promote moderate moderation in our politics. I mean, everything's gone so far left since then. It's completely failed. The top two system, I just think is a joke and should be, we should move away from it. I can't get into those kinds of cynical games. I mean, what am I going to do about it? Be the dominant Republicans so they can do whatever they want with with their, cynical campaigning? It won't work because I'm clearly the leading Republican and the in the, in the situation that you described with God, he was the only one really. [50:02] very happy about the top tier system either. [50:10] want. I'm very confident that I'm going to be the Republican in the top two, and that I will eventually win in November, because the state needs change. Everyone knows that. And how can the people who got us into this mess be the ones to get us out of it? [50:45] Yeah. Are you [50:48] definitely. You know, the bills are so high. You know, one of my, you know, very specific, policy plans is cut your electric bills in half. But remember that a lot of what they do is directed by Democrat policy. So the fact that, for example, they haven't been investing what they should have been doing in fire prevention and clearing brush from near the lines and undergrounding and all the rest of it. Why? Because the governor and the machine in Sacramento has been focused on EV charging stations and all that. You know, the climate crusade. And so I think that they've been in the position of being this, you know, being pushed around and having to there was a very funny line in, Tina Brown's Substack, if you know Tina Brown, she's the former editor of The New Yorker, Vanity Fair, and she, and she wrote this. You just I just read it last night. She talked about Davos and Greenland and Trump and all that, and she had and she had this wonderful line about all the CEOs in Davos who are relieved that they no longer have to pretend to care about climate change. And it was like, and I think that that's the in a sense, the PGA are just a just a creature of this absolutely unbalanced and extreme, climate crusade led by Tom Steyer, who's one of my other opponents. So I think that once they're freed from that PGA, they can get back to what they should be doing, which is providing all of us with affordable, reliable electricity. [52:34] Yeah, I was there for the, one year anniversary. I spoke at the event, where Spencer Pratt announced his, bid for la mer. I mean, it was just shocking to see that's a that is not a Republican. Community at Pacific Palisades. And it was very much a community event. I spoke towards the end. I listened for 2.5 hours, and the rage that they still feel. I mean, it's a year on the the name of that event was called They Let Us Burn. That was what was on the backdrop. They let us burn. I mean, that is an intense sentiment and that's how they feel. And by the way, who's the day Gavin Newsom, Karen Bass it's very simple. We and because we used to this is not none of this complicated. This is what we used to do is common sense. People remember it. You clear the brush. I mean, there in the in the Palisades and in that area, responsible residents who are trying to clear the brush from their property were fined by the Santa Monica mountain Conservancy and other state agencies. They were fined the the the, the, same organization was they were trying to replace wooden, poles with metal ones would be more fire resistance. They were stopped for conservancy reasons because they were trying to protect a plant, the milk vetch. mean, I the it's extreme environmentalism gone mad. All you actually have to do is get back to common sense, which we've done for centuries, which is you manage the fuel load, whether that's in the Sierras, with the forestry, by the way. Then you can re revive our timber industry in California, which used to be a huge part of our economy, particularly rural economy. It's not that long ago we would take around 6 billion board feet. That's the measurement of timber out of our forests. We use it to build houses. Now it's one and a half. It's fallen to a quarter of what it was. We're using more timber. Where's it coming from? Oregon and Canada being trucked in further, more carbon emissions. The forests are overgrown, lumber costs are higher. It's insane. All of this is insane. And so it's actually common sense that we, you know, allow timber to be harvested from our forests. That reduces fire risk, creates jobs and opportunity in those areas. Cheaper construction materials, lower carbon emissions because you're not transporting it. So far. Like it's not complicated. And [55:11] right.

---
snapshot_id: 9151faa5-634a-58d4-a522-2ceeef381059
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/an-elite-business-school-in-east-la

Saved from https://stevehiltonforgovernor.com/policies/an-elite-business-school-in-east-la (rendered page text, built-in browser, 2026-10-07) POLICY WORKING CLASS TO FOUNDER CLASS: AN ELITE BUSINESS SCHOOL IN EAST LA ← POLICY ARCHIVE WORKING CLASS TO FOUNDER CLASS: AN ELITE BUSINESS SCHOOL IN EAST LA A world-class pathway to technology entrepreneurship and business leadership THE PROBLEM California has some of the best universities in the world. But for millions of working Californians, the opportunity they represent is increasingly out of reach. We have among the highest poverty and unemployment rates in America. Social mobility in many parts of our state, and for millions of young Californians, seems to have ground to a halt. California used to offer young people opportunity better than anywhere else in the world. Far too many young Californians today feel as if the only option is to be stuck here with no prospect of ever owning a home, or starting a business – or moving to another state. That failure is especially stark in East LA. A teenager in Palo Alto grows up surrounded by founders, engineers, investors, and people who expect them to aim high. A teenager in East LA may have just as much talent and drive, but far less exposure to those industries, those networks, and those expectations. In East Los Angeles, only 11.4 percent of adults over 25 have a bachelor’s degree, and more than 17 percent live in poverty. Too many talented young people are never shown a credible route from where they are to a career in technology or finance, or to starting a high-growth company of their own. There is nothing wrong with building a restaurant, working in music, or joining a family business. Those are part of the strength of East LA. But they should not be the only visible paths. Young people in East LA should see the same horizon as young people growing up around Silicon Valley: technology, venture capital, finance, product development, and high-growth, high reward entrepreneurship. California’s answer has usually been another workforce program. That is not enough. East LA does not need a second-tier program with lower expectations. It needs an elite institution built to recognize talent, raise aspiration, and open doors. HOW WE GOT HERE California has built a two-tier education system. Students from affluent communities get access to elite universities, powerful alumni networks, prestigious internships, and the confidence that comes from being told they can lead. Working-class students are too often steered toward basic job training and told to be “realistic.” Business success depends on more than classroom instruction. It depends on exposure, mentors, relationships, confidence, and access to capital. Young people absorb what is possible from the people and institutions around them. If they never meet a founder, investor, engineer, or executive, those careers can feel as if they belong to someone else. California’s leading universities regularly promise to expand access and serve the communities around them. Some have begun. UCLA Extension has partnered with the SoLa Foundation to offer tuition-free UCLA courses in South Los Angeles. That is a good start. But a collection of short courses is not the same as an elite, aspirational business school with a rigorous curriculum, a respected credential, a powerful network, and a direct path to building and leading a company. STEVE’S PLAN Steve Hilton will launch an elite, locally rooted business school in East Los Angeles through a competitive partnership with one of California’s leading universities. It will be elite in quality, not restricted by wealth. Students will be admitted for their talent, drive, creativity, and potential, and the program will be tuition-free for income-qualified California residents. BRING AN ELITE UNIVERSITY TO EAST LA UCLA, USC, Claremont McKenna and other leading public and private universities will be invited to compete to become the school’s founding academic partner. The selected university will put its name and academic standing behind the school, design the curriculum, provide faculty and visiting instructors, and open its alumni, employer, and industry networks to students. This will not be a satellite office with a famous logo on the wall. Students will earn a respected university credential and transferable academic credit, with a clear path to further study at the partner university, or another equivalently high-status institution. SET ELITE STANDARDS AND FIND OVERLOOKED TALENT The school will recruit aggressively from East LA high schools, community colleges, churches, and community organizations. Admissions will look beyond family connections and narrow measures of academic success to identify initiative, resilience, creativity, leadership, and the determination to build something. The standards will be demanding. Students who need additional preparation will receive it through a summer bridge program, tutoring, and academic support. The answer to unequal opportunity is not a watered-down curriculum. It is giving talented students the support they need to meet an elite standard. TEACH STUDENTS HOW COMPANIES ARE BUILT Students will study entrepreneurship, finance, accounting, marketing, sales, product development, operations, artificial intelligence, data, leadership, and communication. The goal is not to train students for one narrow job. It is to teach them how a company is created, financed, managed, and scaled. Every student will work on a real company, product, or business plan. They will test ideas with customers, build a budget, make a pitch, and learn from success and failure. Students who want to grow an existing family business will be able to use the same tools to take it further. OPEN THE NETWORK California founders, executives, investors, engineers, accountants, and attorneys will serve as mentors and instructors, and every student will receive paid work experience with a technology company, startup, investment firm, or growing California business. The school will also host founders and investors in residence and regular pitch sessions. Students will leave with relationships, references, experience, and people prepared to open doors for them. GIVE STUDENTS THE CHANCE TO BUILD The school will include a business incubator where students and graduates can develop companies with access to workspace, legal and accounting support, market research, and experienced advisers. A privately backed seed fund will give promising student ventures the chance to compete for early investment. Public dollars will support education. Private investors will decide which businesses to back. REMOVE THE PRICE BARRIERS For income-qualified students, support will cover tuition, books, technology, transportation, and childcare. The school will offer a full-time program, flexible options for working students, and a summer academy that introduces local high school students to technology, entrepreneurship, and business leadership before they choose a college or career path. START IN EAST LA AND PROVE IT WORKS Steve will fund the East LA pilot in his first budget by bringing together existing higher education and workforce resources with matching support from the university partner, employers, and philanthropy. There will be no new state bureaucracy, and no new tax. The first class will begin during Steve’s first term. The state will publish results including completion, transfer, paid internships, job placement, starting pay, companies launched, and outside capital raised. If the model works in East LA, California will take it to other working-class communities across the state. A BETTER WAY FORWARD The point is not to train young people in East LA for the jobs others have decided are “realistic” for them. The point is to give them access to the same knowledge, networks, and expectations that have helped create generations of California business leaders. A young person in East LA should grow up believing they can found the next great California company, finance it, build it, and lead it. Talent is already there. This school will match that talent with elite opportunity: from working class to founder class. ← Back to all policies

---
snapshot_id: bba3bc76-e0e4-5eee-94e7-f1c8df72c113
source_kind: own-site (the person's own site or account)
url: https://stevehiltonforgovernor.com/policies/making-californias-schools-work-again

Saved from https://stevehiltonforgovernor.com/policies/making-californias-schools-work-again (rendered page text, built-in browser, 2026-10-07) POLICY MAKING CALIFORNIA’S SCHOOLS WORK AGAIN: FIX PUBLIC EDUCATION BY 3RD GRADE ← POLICY ARCHIVE MAKING CALIFORNIA’S SCHOOLS WORK AGAIN: FIX PUBLIC EDUCATION BY 3RD GRADE THE PROBLEM California’s public schools are failing millions of students. Only 47% of students meet English language standards, and just 35% meet math standards, compared to the roughly 60% of students nationwide that meet their state’s English standards and 65% that meet state math standards. For Black and Latino students, the numbers are even worse. Nearly 70% of Black students and 64% of Latino students do not meet basic standards in reading. These failures are concentrated in the early grades, where students are falling behind and never catching up. Research shows that if a child cannot read proficiently by the end of 3rd grade, they are four times more likely to drop out of high school. That is why fixing early education and ensuring literacy by 3rd grade must be the cornerstone of any serious education reform. HOW WE GOT HERE California spends more than $22,000 per student each year, among the highest in the nation, yet outcomes continue to decline. This is not a funding problem. It is a leadership and accountability problem. Politicians backed by teachers unions have removed phonics-based reading instruction, abandoned Algebra in middle school, stripped away consequences for failure, and added ideological curricula that crowd out basic skills. At the same time, the state has made it nearly impossible to reward good teachers or remove ineffective ones. Schools are no longer judged by whether students learn, but by whether bureaucratic boxes are checked. In too many places, especially low-income communities, the system seems designed to protect itself rather than serve children. STEVE HILTON’S SOLUTION: 3RD GRADE FIRST As governor, Steve Hilton will make 3rd grade literacy and numeracy a top education priority. His plan includes structural change, immediate classroom reforms, and full accountability to parents. This approach does not require more spending. It requires a new focus on results. 1. RESTORE PHONICS-BASED READING INSTRUCTION IN ALL K–3 CLASSROOMS. Phonics is the most proven method to teach children to read, but California does not require it. Steve Hilton will use executive action and pro-reform appointments to the state Board of Education to mandate phonics instruction statewide. 2. HOLD SCHOOLS ACCOUNTABLE FOR 3RD GRADE READING RESULTS. Every school will receive a clear, public letter grade each year based on student proficiency, starting in 3rd grade. Schools that fail to show improvement will be placed in state-directed “special measures” with new leadership, strategies and greater accountability. 3. REFORM TENURE, TEACHER EVALUATIONS, AND DISMISSAL POLICIES. With Steve Hilton as governor, California will require at least five years of classroom experience before granting tenure. Low-performing teachers must be removed quickly and excellent teachers rewarded. 4. BRING BACK AND EXPAND THE PARENT TRIGGER LAW. Parents will once again be empowered to force reforms at failing schools. If a school receives a D grade two years in a row, parents will have the right to trigger administrative changes, curriculum overhauls, or conversion to a charter model. 5. LAUNCH EDUCATION SAVINGS ACCOUNTS AND CROSS-DISTRICT OPEN ENROLLMENT. To give parents immediate options while traditional schools improve, Hilton will expand choice through ESAs, starting with low-income and special needs students. Parents will be free to move their children to any public school that performs better, regardless of zip code. Steve Hilton believes California can lead the nation in education again. But it starts with getting every child reading properly by 3rd grade. ← Back to all policies

---
snapshot_id: 58382e98-e275-5484-8c63-3736dfdd435e
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/10df0d42-381b-4221-bea7-ad6d0b86e3b7

# On the Record — Steve Hilton (9a60d603-194d-410f-ae01-85bd6293f1a7) ## news_clip — CA CA-Courier-SteveHiltonInterview - OTR page: https://ontherecord.empowered.vote/meetings/10df0d42-381b-4221-bea7-ad6d0b86e3b7 - Video: https://www.youtube.com/watch?v=VIZ1h4OaImU - Date on On the Record: 2026-04-01 - Kind: news_clip · CA-Courier-SteveHiltonInterview · CA - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:04] to be with you. [0:33] Well, the first thing we've got to say is why we need to cut taxes in California because we have an insane level of taxation. We have the highest taxes in the country for the worst results and one of the consequences of that is that we have on all these measures the worst performance of any state. It's really shocking. Right now we have the highest poverty rate in the country tied with Louisiana. We have the highest unemployment rate of all 50 states. We have the highest cost of living. We have the worst business climate according to Chief Executive Magazine for the last 10 years. So businesses are leaving, investment is going, jobs aren't being created. That's why we have high unemployment and high poverty. So a huge part of that is the tax burden and we've got to reduce it and that means you have to reduce spending. So that's the starting point. When you look at who's really suffering as a result of all these things, not just the taxes but the high cost of gas and housing, groceries, all of these the most expensive in the country. Electric bills, the second highest after Hawaii, insurance, all these unbelievable burdens. Working class Californians are hurting the most. Regular working people who work incredibly hard and everything's so expensive and then they're taxed for it. And so the first, I mean in many counties, the official poverty level [1:52] is now $100 ,000. So in many other states, you look at $100 ,000 and think that's a decent income. In California, it doesn't get you very far. So the last thing we should be doing is taxing those people. That's why I wanted to start with that. $100 ,000 to raise the threshold for paying state income tax. That would help millions of Californians, thousands of dollars extra in their budgets every year. That one, I think that we can, I think there's a very real prospect of getting out through the legislature because one thing I've noticed is that my tax plan, that part of it has actually been copied. By some of the other Democrat candidates, including Katie Porter. So I think that actually we can get support for that part of it. That's the pro -worker part. The second part, which is a flat tax above $100 ,000, 7 .5%. Now that is going to be much harder to implement. Partly because a lot of these taxes are not just too high, they're too complicated. We've got endless different tax bans that make it really fiddly and annoying and bureaucratic to do your taxes. And it's a real disincentive to start businesses here. I'm a business owner. Most of my career has been in business. And it's just a nightmare. And the taxes are a big part of it. Now, some of those tax rates that we have have been established by ballot initiative over the years. That's one of the reasons we have this complicated system. So it won't be easy to undo that. But I think we've just got to make the argument. And so my attitude to all of this is your starting point is see what you can get done through the legislature. Then see what you can get done through executive action, through the administrative agencies. And then if none of that works, then for these really major reforms, we probably will have to go to a ballot initiative at some point in the future, after I'm elected and take office in January. [3:53] to. I mean, that's how it works. That's how our system works. So I've got a very strong focus. You know, when I'm the general election candidate, I'm very clear that my responsibility as the top of the ticket in California is to help elect Republicans everywhere. It's not just about my race. It's about the other statewide races. I'm the first candidate ever from either party that's put together a team to run for the other statewide offices. We can get to that a little bit later. But in terms of the legislature, it's going to be a huge priority for me to try and help elect more Republicans this cycle in the assembly and the Senate because then we do have a chance to break the supermajority this year. It's not going to be easy, but it's not impossible. So even if we get rid of the supermajority in one of the two chambers, that's already really helpful because then they won't be able to just block everything. And so you start to create some opportunity there. I think also the truth is that [4:51] when I'm elected this year, nobody expects a Republican to win in terms of the Democrat. They're so arrogant. It's 16 years of one party rule. They think it's going to go on forever. But actually, I think we've got a very good shot this year. When I'm elected, that's going to be a political revolution in California. And I think when I take office in Sacramento in January, it really will change the dynamic. I really believe that. It's hard to imagine it right now, but it's going to be a shock to these Democrats that they've got a Republican governor. And I think we will be able to do that, to work with them. And there's a couple of things I'd add. Number one, I've got experience of doing that. So most of my career, as I said, I've been in business, working around the world, but also starting my own companies, including restaurants, a whole range of different businesses. But I have had a few years working in government at a very high level. I was senior advisor to the prime minister in the UK. I worked in 10 Downing Street. I had a little office there next to the cabinet room and worked to try and make things happen. In a coalition government. So my boss was David Cameron, the conservative prime minister, but it was a coalition with another party, the Liberal Democrat Party. And I shared an office with my opposite number in the other party, Polly McKenzie. We used to argue a lot, but we also worked together to find the areas where we could make change happen. So I've got experience of doing that. It's not easy. And of course, you're not going to get everything done that way, but it's not true to say nothing can happen. And I think that it really will [6:17] change things to have a Republican governor. I think the whole mood in Sacramento will change. A lot of things that are seen as impossible will suddenly start to become more realistic. The other thing I'd point to now talking about the team I've put together to run with me for the other statewide offices, including for lieutenant governor. [6:34] And that's the concept of a ticket has never been done before in California, statewide races. But I think we've got to try new things and do things differently. Gloria Romero, who's running with me for lieutenant governor, she was previously the Democrat leader in the state Senate. So that was many years ago. And she left the party. She used to work across the aisle, but then the party went very left -wing. I met her when she was working with Rick Grinnell on a ballot initiative for school choice. It was Rick who introduced me to Gloria. And she's now a Republican, fully signed up. She's endorsed President Trump, spoke at the Coachella rally. But she still has relationships there. As the lieutenant governor, you're the president of the Senate. And so you have a big role to play. She understands how that system and the process work in the legislature. And so I'm running, I'm obviously an outsider. I've never run for office before. And I'm going there as an outsider to take on all the nonsense in Sacramento. But I think it's gonna be helpful to have by my side someone who has been there and knows how it works and has relationships in the Democrats. I mean, I went there with Gloria. We were launching some policy thing and went into the state Capitol. And it's a long time since she's been there and she's a Republican now. But they invited her onto the Senate floor as a mark of respect. She was previously the leader. I watched it from the gallery. They all stood and cheered. [8:01] Democrats, because there's relationships there. And so I think that it seems very out of reach, the idea that we could actually have something positive happen. But I don't know, I've got a very strong feeling that in these various ways, we really can get some things done. [8:49] Well, the first business I started was 1997, a company called Good Business. And we were a consulting firm. We worked with some of the biggest companies in the world. Then about two years later, we launched, with my business partner, we launched a couple of restaurants in the UK called The Good Cook, which is kind of an offshoot of our consulting business, but it was two real restaurants in London. And they were, that's a really tough business, to be honest. You learn a lot from it, but in some ways we did well, in other ways it was tough. It's very difficult to make money in that business. Then I went back into politics and government, worked in 10 Downing Street for a while. We moved here in 2012 with my wife and my two sons. And for the first couple of years I was here, I talked at Stanford, but then I launched another business here, a tech company, a tech platform called CrowdPak. And that was a crowdfunding platform for politics and candidates and political causes. And so that's an equivalent, you could think of it as a GoFundMe for political candidates and so on. And so that was a business that started, I think, well, I got going 2013, probably launched 2014. Ran that for a few years before being invited to host a show on [10:07] Fox News. And then after that, the final business that I started was a media company, really to produce podcasts and so on. That was CR Productions. So there's been the four in total. So that's that. I don't know what he's talking about with this fast track thing. It's completely ridiculous. We, you know, it wasn't that fast. We moved here in 2012 [10:32] on a visa that [10:34] then got applied for a green card and got that and got my citizenship in 2021, nine years. So I actually genuinely don't understand what that's about. Do you have any more specifics on what the allegation is? [10:52] years? Yes. Is that fast? [11:01] I literally think that is a completely made up, ridiculous smear, which I don't even understand. I don't understand why someone would question the process there when it's just an independent, bureaucratic process. They're saying that everyone has to go through. [11:18] It's really ridiculous. [11:23] So what specifically, that I don't understand. Again, what was the specific thing there? [11:36] Well, partly we've just been discussing how important it's gonna be to be able to work with Democrats in order to make change happen. But actually, I think what's being referred to there is one of my businesses, CrowdPak, which is a crowdfunding platform [11:52] for politics and candidates and so on. And it was an open platform. So like GoFundMe, or like X. So I think what he's getting at there is that Democrats used my business to raise money, as did Republicans, as did anyone who wanted to. So it's a little bit like criticizing Elon Musk for things that Democrats say on X. It's an open platform. Yeah, people can use it. [12:38] Well, again, I think we have to be practical. I've always been really clear that I never wanna say something that can't be delivered just to make people feel good about whatever the issue may be. I always wanna be realistic about what you can do. And on this particular issue, which is so deeply felt and is so personal for so many people, I think there's just a couple of things I'd say. First of all, I do think that it's right that the issue was now, for so many years, it was in the hands of judges and the people felt they didn't have a say. And thanks to President Trump's Supreme Court appointments and where that led, it now has been put back in the hands of the people through their representatives, because states have been able to make their own determinations on that issue. And you've seen a wide range of policies implemented across America. And I totally support that approach, because the idea that you've got one size fits all on something that's so personal and people have such strong views about was always one of the real problems with this issue. People felt that their voices weren't heard. Now, in the end, you've gotta decide what level this is regulated. It has to be regulated at some level. Previously it was the national level, now it's at the state level. And so in different states, they voted for different things. Here in California, in 2022, it was on the ballot [13:57] to be enshrined in the state constitution, the right to abortion. And it was, and it was passed with a two -thirds majority. So that's how it works. That's how the system works. So my attitude to this is what can I get done as governor to move us in this sort of direction of life, towards life, in a way that I can actually deliver. So the first thing I'd say on that is that all the other things that I wanna get done for California to make it, to make our state, as I say, Cal affordable, to make this a place where young people wanna, can see a future where they can start a family here. One of the most heartbreaking things to me is when you talk to young people and they say, well, I can't imagine living in California. It's too expensive. I'll never be able to do it here. I have to move to another state. I want this to be a place where people see the opportunity to start and raise a family and have children and grow their families here in California, something I talked to Charlie Kirk about a lot. He was a good friend of mine and endorsed me on day one. And it was a big thing, big focus for him as well. That ability to, because you hear stories where people say, yeah, I'd love to have more children, but [15:07] it's too expensive or I can't afford, I can only afford a tiny apartment and so I can, et cetera. They've got to change all that. So that's actually part of the story of moving us towards life. More specifically on the issue itself, [15:19] you've got a couple of things. First of all, I think we have to just encourage a culture of responsibility on this. One of the things that I just think is really, I'm gonna use a pretty strong word, it's kind of disgusting actually, is the way that, it's just the way that this issue has evolved, particularly in places like California, is that it's almost as if abortion is now seen as a perfectly acceptable form of birth control, just like any, and I just think that's really, really dark and not where we want to be as a society. So you have to, [15:50] and the governor can, through working with the faith, I've had lots of conversations, for example, with Jack Hibbs, who's a big supporter of mine from Calvary Chapel, Chino Hills, and others in the faith community about how we can work together to encourage more responsibility, a culture of responsibility. So we minimize the number of unwanted pregnancies in the first place. So there's something you can do more actively on that as governor, and I will. Secondly, if you are in that situation, I think it's just outrageous that what you're seeing now from the government in California is actively [16:22] attacking pro -life centers and places that are, I just met someone who runs one of those this morning, encouraging adoption, for example, as an alternative and helping prospective mothers think through that process. That's being discouraged and actually aggressively targeted by the Newsome administration. So that we need to reverse and encourage adoption as an alternative. And then the final piece of it, I just think this whole spending taxpayer money promoting abortion, which is what's happening right now, our money is just not okay, including, [17:02] again, stuff that I just think is really wrong, like what some people have described as abortion tourism, [17:09] where our taxpayer money is being spent on ads in other states, [17:14] saying, come to California, all that's gonna stop. [17:32] Well, again, I don't really understand what he's talking about, because I think what he said something about, the way he framed it was as if what I was saying wasn't true. I've never said anything about him that's not true. Nothing. I mean, the things that I've been pointing out are things that are true about his record, unlike what's been said about me, as we've just discussed, not true at all. And people can watch for themselves. I think what he's getting at is the fact that when he was, as sheriff, during the Black Lives Matter riots in 2020, he took a knee for Black Lives Matter. And he argues that he was praying. I've never said one way or the other. I've just said, and it's clear that he took a knee. That's a physical action, taking a knee. And you can see that. It's documented, there's video, there's photographs. You can watch it, it's on a website, blmbianco .org. So people can see that for themselves. So it's obvious that he took a knee. He challenges the interpretation of that as being something that was done for BLM. And he says he was praying. That's what he says. He said it many times. I've heard him say it many times. Now, people just watch the video and see if that's true. I don't think I've ever said anything about that that's not true. And it's not backed up by documented evidence on the day. The second thing I've pointed out, and maybe he's getting at this, is again, just repeating what he said on an issue that is actually probably the biggest policy area where we really have a disagreement, which is on immigration, where he has said a number of things that I just strongly disagree with. He said that he won't, and his sheriffs in his department, won't work with the federal authorities to enforce immigration law. I disagree with that. The Sanctuary State Law in California allows for cooperation between state and federal law enforcement on immigration. So I don't know why he would not want to do that. But he said that. It's a video, you can watch it. The other part of this that I strongly disagree with is his contention that people who are here, who came across the border during the Biden years, are actually here legally. And his view that, which again, I'm quoting almost word for word now, that it doesn't matter how you came here, the 10 to 11 million people who came under Biden, the illegal immigrants here, we have to give them a pathway to citizenship. I just disagree with that. That's rewarding law breaking. We, as I often point out, we already have a pathway to citizenship. It's called legal immigration. I just took it. And so I just disagree. Now he may not [20:12] like the fact that when this issue comes up, I'm pointing out his past statements, but they're his words. I've never said anything that's not true. [20:26] to be with you. Thank you.