You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-ca-gov-stances/backend/data/stance-research/2026-10-07-shadow-becerra-israel-military-aid/labels/coder-1.json. Write JSON only, matching
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

politician_id: 0f74219c-7d10-4d29-85fe-0f1d834df8a7  office_id: 08454462-a1f0-4d11-9f61-aba7a173a3de
Xavier Becerra — Governor, California (candidate, level: state)
Candidate in the election of 2026-11-03

## Topics (served ladder text — code against these words only)

### topic_key: israel-military-aid
topic_id: 6783e65c-0722-45d9-8579-65327af7c15c  served_revision_id: a9e300f1-8d13-4e34-89f0-e321031676b2
Question: What level of military aid should the U.S. provide to Israel?
Evidence basis at this seat's level (state): OWN WORDS ONLY — no officeholder at this level holds a lever on this topic (codebook V2 "No-lever level").
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
snapshot_id: 487f1530-f0da-5a46-a6fa-5307a915be24
source_kind: own-site (the person's own site or account)
url: https://www.xavierbecerra2026.com/priorities/health-care/

Health Care - Xavier Becerra Contribute Now This is a break-glass moment – for our families, our neighbors, and folks all across our great state. Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Contribute Volunteer About Bio Endorsements Issues Health Care Fighting Donald Trump Housing Economy & Affordability Energy & Utilities Disaster Preparedness Artificial Intelligence Homelessness Film Industry Power Hour Wildfires Take Action News Room Store Volunteer Contribute Priorities Health Care Healthcare has been the throughline of my entire career in public service. I started as a legal advocate for people with mental illness who had no voice. I served twelve terms in Congress and on the Ways and Means Subcommittee on Health, fighting for every family to have the same assurance of care that my family had growing up. As California’s Attorney General, I won a $575 million antitrust settlement against one of the largest health systems in the state, cracked down on pharmaceutical “pay-for-delay” schemes that kept generic drugs off the market, prosecuted Medi-Cal fraud, and led the three-year federal court fight that saved the Affordable Care Act for 133 million Americans with pre-existing conditions. As HHS Secretary, I negotiated drug price reductions of up to 79% on some of the most widely used medications in America, the first time the federal government had ever directly bargained with pharmaceutical companies on behalf of patients. Bringing costs down is not an aspiration for me. It is a record. Now Washington is working to undo all of it. The Trump administration is targeting Medi-Cal, gutting the ACA, and abandoning the drug pricing reforms that were just beginning to deliver savings for families. With the federal government absent from this fight, California must be the firewall. I sued the Trump administration more than 120times as Attorney General and won, and I am ready to do it again. But fighting Washington is not enough. The next governor must do more than play defense. We need to protect coverage for every Californian today while building toward a system where universal access is not a promise deferred but a guarantee delivered. The most effective way to lower healthcare costs is to keep people healthy in the first place. A family without a primary care doctor does not simply go without care. They end up in an emergency room, at far greater cost to the system and far greater harm to themselves. Primary care is the only part of the healthcare system where investment consistently produces longer lives, greater equity, and lower overall spending. As Governor, I will move California toward a system that does not just treat illness but prevents it, with community-based care, robust screening, and the kind of coordination that reaches the people who need it most. None of this works without the people to deliver it. California cannot build toward universal coverage without the providers, nurses, and caregivers to make it real. We face serious shortages in primary care, behavioral health, and rural medicine, and those shortages fall hardest on the communities already carrying the heaviest health burden. I will invest in growing and retaining a healthcare workforce that reflects the full diversity of California and reaches every zip code, because coverage without access is not coverage at all. Guiding Principles Bring Healthcare Costs Down for All Californians. Lower the financial burden Californians face when accessing care, from premiums and out-of-pocket costs to prescription drug prices, using every tool of state purchasing power, regulation, and enforcement available. Guarantee Access and Build Toward Universal Coverage. Protect existing coverage from federal rollbacks and chart a clear path to ensuring that no Californian is left without care, regardless of income, zip code or immigration status. Increase Investment in Primary Care. Make prevention and early intervention the foundation of the system. It costs the state far less to give a family access to a doctor than to wait until a preventable condition lands them in the emergency room. Build, Support, and Invest in a Stronger Healthcare Workforce. Grow and retain the providers, caregivers, and allied health professionals California needs, especially in rural communities, safety-net settings, and underserved specialties, so that coverage always comes with adequate networks and actual access to care. Policy Agenda 1. Protect Healthcare and Keep Hospitals, Clinics, and Medical Practices Open On Day One, I will issue an executive order directing state agencies to maintain coverage continuity for every Californian affected by federal cuts or Medi-Cal rollbacks. I will also direct state agencies to protect access to essential, medically appropriate health services from federal restrictions, including reproductive care and healthcare for immigrant communities, and ensure uninterrupted, equitable access to contraception, abortion, and maternal health support. I will immediately assess which rural hospitals, community clinics, and safety-net providers are most at risk and execute emergency state interventions to prevent cascading closures. And I will fight to fully implement Proposition 35, which California voters passed in November 2024 to dedicate MCO tax revenue exclusively to Medi-Cal, ensuring those funds go to stronger provider payments and expanded access to care, not federal clawbacks. State interventions will ensure that public dollars come with public obligations, including maintaining fair labor standards and respecting the representation rights of the healthcare workforce. 2. Cut Prescription Drug Costs Using State Purchasing Power I negotiated drug price reductions of up to 79% as HHS Secretary, finalizing historic deals on ten high-cost medications including Eliquis, Jardiance, and Xarelto that will save Medicare billions of dollars every year. When I am Governor, California’s full purchasing power goes to work for patients on Day One. I will negotiate maximum reimbursement rates for drugs purchased through state employee health plans, Medi-Cal, and all state-administered programs, and direct agencies to prioritize lower-cost biosimilars and therapeutic alternatives wherever clinically appropriate. 3. Expand CalRx and Build Western States Drug Independence California pioneered CalRx to produce and purchase essential medications at lower cost, and I will accelerate and expand it, moving urgently on high-impact medicines like insulin, inhalers, EpiPens, naloxone, and antibiotics. I will also forge joint purchasing arrangements with other Western states to maximize our collective buying power and build regional pharmaceutical independence, so that a hostile federal administration or a supply chain disruption can never hold California’s patients hostage. 4. Streamline Administrative Oversight to Reduce Waste and Improve Efficiency Too much of what California spends on healthcare goes to paperwork, not patients. I will issue a directive requiring all healthcare oversight agencies to identify and eliminate duplicative requirements that add cost without improving care, produce a unified plan to modernize and consolidate oversight activities, and partner with health plans and providers to review outdated facility standards and operational rules that drive up costs and restrict innovation. Every dollar freed from administrative waste is a dollar that can go toward expanding access. 5. Launch “California Connected Care”: Universal Telehealth Access As HHS Secretary, I oversaw the historic expansion of telehealth during the pandemic and saw firsthand how it saved lives in communities that had never had adequate access to specialists. As Governor, I will issue an executive order requiring all state-regulated payors to reimburse telehealth visits to the fullest extent permitted under law, prioritizing telehealth delivered by California-licensed health care professionals through local and regional providers to provide urgent care for conditions that do not require an in-person visit, and leverage California’s volunteer physician registry to open specialty telehealth access to communities that have never had it. I will also direct our oversight agencies to launch oversight and integrity programs to match the expansion of telehealth services. When a patient with a chronic condition connects online, they will be linked directly to a Federally Qualified Health Center for ongoing care. 6. Launch the “California Prevention First” Initiative The most effective way to lower healthcare costs is to keep people healthy in the first place. I will invest in comprehensive community-based prevention programs targeting the chronic diseases that drive the highest costs, including diabetes, hypertension, cancer, substance use, and more, with community health workers, robust screening programs, and doula care. This initiative will prioritize Medi-Cal populations and disadvantaged communities that bear a disproportionate burden of chronic illness, and will invest in modern data systems that track patient needs and close gaps in care so that prevention is measurable, not just aspirational. As Governor, I will also strengthen public health infrastructure by restoring trust in science and expanding access to safe, effective vaccines, as I recognize immunization as one of the most powerful tools to prevent disease and protect public health. Building on California’s world-leading research institutions and innovation ecosystem, my administration will recommit to fact-based decision-making and double down on science and research to guide policy, improve outcomes, and prepare for emerging public health challenges. 7. Launch the California Healthcare Workforce Investment Fund Coverage without providers is an empty promise. I will establish a long-term dedicated fund to grow the healthcare workforce where it is needed most, offering loan repayment and forgiveness programs, housing assistance in high-cost areas, and targeted incentives for primary care, behavioral health, women’s care, rural medicine, and dental providers. The fund will build lasting partnerships between health systems and California’s community colleges and universities to train the next generation of nurses, medical assistants, physicians, dentists, and allied health professionals, with incentives for health systems that invest in the workforce pipeline. I will also hold health plans accountable for building and maintaining adequate provider networks so patients can access timely, high-quality care when and where they need it. 8. Center Affordability in Every Decision Universal coverage, timely access, and a strong safety net must translate into real savings for real families. I will work with regulatory agencies to ensure that as waste and inefficiency are eliminated, the savings flow back to patients, not to shareholders. I will work with employers and other purchasers of care to drive down premiums and out-of-pocket costs across the board. The goal is a system where doing the right thing for patients is also the most financially sustainable path for providers, plans, and the state. 9. Stop Paying Twice for People Who Never Lost Eligibility California loses hundreds of millions of dollars every year processing the same Medi-Cal cases twice, when eligible enrollees are dropped due to paperwork errors and then re-enroll weeks later. Children’s churn cases alone cost $120 million every three years. I will modernize Medi-Cal’s eligibility infrastructure with automated renewals that verify eligibility through existing state data, consolidate the fragmented county-by-county enrollment system, and ensure that a missed letter or a data entry error never becomes the reason an eligible Californian loses coverage. 10. Crack Down on Waste, Fraud, and Abuse I prosecuted Medi-Cal fraud as California’s Attorney General, and California is still losing billions to fraudulent claims and misused benefits. I will create a dedicated healthcare fraud task force with the authority to hold funds, investigate bad actors, file charges, and see cases through to verdict. Services that are overutilized or delivered through the wrong system, including transportation and hospice abuse, home asthma remediation, and housing benefits that belong in social services will be reined in. Every dollar recovered is a dollar that can go to care for the patients who need it most. 11. Stop Large Employers From Shifting Costs onto Taxpayers Some of California’s largest and most profitable corporations pay wages so low that their workers qualify for taxpayer-funded Medi-Cal, effectively subsidizing their labor costs with public money while disadvantaging competitors who do the right thing. This year’s state budget laid the foundation for this fight through the Fair Share from Big Corporations Act, directing the Department of Finance to bring forward options by March 2027 — and if I have the honor of serving as Governor, I would look forward to working with the Legislature to turn that groundwork into a real, enforceable policy. I will pursue a fee on large employers who do not offer health coverage to their low-wage workers who qualify for Medi-Cal, so that corporations who shift their healthcare costs onto taxpayers pay their fair share. Profitable companies should not get to pass their obligations onto working families. 12. Modernize and Consolidate Medi-Cal Financing to Ensure Long-Term Stability Medi-Cal’s current funding structure is a patchwork of supplemental payments, time-limited tools, and fragmented streams that obscures true costs, limits transparency, and makes long-term planning nearly impossible. I will pursue a unified financing strategy that consolidates duplicative payment structures, strengthens base rates, and ties funding to clear performance and accountability standards, so that Medi-Cal dollars go to access and quality, providers can plan with confidence, and California is no longer vulnerable to federal disruption of the mechanisms we rely on most. Up Next Fighting Donald Trump Contribute Click on an option to get started. If you've saved your payment information with ActBlue Express, your donation will go through immediately. $5 $10 $25 $50 $100 Other OR Volunteer About Issues Take Action News Room Store Privacy Policy Paid for by Becerra for Governor 2026

---
snapshot_id: 278d4779-8e6e-5399-8d37-ca5ab7d85948
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/f53b0041-4efd-41f8-a96d-949294a09a6e

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## Political Breakdown (KQED News) - Interview with Xavier Becerra - OTR page: https://ontherecord.empowered.vote/meetings/f53b0041-4efd-41f8-a96d-949294a09a6e - Video: https://www.youtube.com/watch?v=0-bhl_OtmWY - Date on On the Record: 2026-03-05 - Kind: news_clip · Interview · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5 [0:00] It's a hollow gesture to pass Prop 36 and not provide the funding for mental health services, drug addiction services. Because essentially what you're saying is you can incarcerate all these folks. No. Californians are done with just putting people away behind bars. Cause they know they're eventually gonna get out, most of them. And so we'd rather have folks who are rehabilitated or who are provided the services they need to stand up again. And that's what Prop 36 said. And so absolutely fund it. Yeah. And if you don't, find the money. Let's find the money. If that means we have to raise more money, revenue, then let's raise revenue. [1:30] Scott, great to be with [1:40] Politically? Well, I'm the same person. I, I am personally, I'm the son of immigrants. I have an experience of someone watching two hardworking individuals who never had a chance to go to college, who worked very hard, made very little, but somehow made it possible for their four kids to achieve things they never got to see. I am politically the son of those hardworking parents who recognizes that I have to open the same doors for that next generation of kids so that the next generation of construction workers and clerical workers who are married together will have the chance to do what my parents did, send the, their four kids to college or the military, actually buy a house. And then when it came time to retire, not have to think about going to Idaho or Arizona, but stay here in California. [2:43] Nothing but hard work. They just said, you're gonna prove yourself by your work and so just do hard work and that'll pay off. And they were saying that because that was their experience. They just worked hard and never got a whole lot. But they got a place to live and they got a place for their kids to, to prosper. So they weren't expecting a whole lot. They couldn't tell us what we could grow to do because they never got to experience so many things. But they knew that if we worked hard, we'd have a chance in [3:20] roost? So I was a third of four kids, three sisters In a Latino home, often times the child male gets a lot of preference. It used to be the case, maybe not so much anymore. Fortunately I have three daughters and didn't have to worry about that. We loved them all equally. And they're all phenomenal. But, you know, it's [3:39] one of those things where we were a close-knit family. We did a lot of stuff together. cause we didn't have a lot of money to do it elsewhere. And you just grow up around each other and you grow up weekends, you're spending your time with your cousins at your grandparents' house. And it's a great childhood. Now that I think about it, we were latchkey kids when we'd come home from school. Mom and dad were not there because they were both working, but they didn't have money to pay for childcare. Who has money to pay for childcare today? And so you, you, you bring with you a lot of experiences. So when you raise the question, who am I politically, I really am the person I grew up. I, I lived in my politics so much of what I grew up with. Three [4:32] And you know, it's interesting because I've learned stability, honesty. [4:48] And I'd say it's [4:52] a humility, but it's not a humility that you're shy. It's a, you understand that life has never been as fulfilling for you and you have to go out and make it happen. And for so many women who've been so talented and always been told, you're, you gotta wait, you gotta do it second, they've learned to persevere, to be thoughtful and to recognize my time will come. And it sure helps to be surrounded by women. Most of my staff where I've worked, have also been female. And I, I think it's a, a very sobering and edifying experience to, to get to see how the other half of the world really can not just function, but ultimately start to rule. [6:02] abortion? Ah, that's a great question because raised Catholic and my mom still prays the rosary every day. The sanctity of life is something that's really ingrained in you. Then you realize that for so many Latinas that pregnancy changes their life experience, their opportunity. And in so many ways, so many of the women who re receive abortions are Catholic Latinas. And many of them never get the abortion. And they have wonderful families. Some of them end up not getting to fulfill their wish of going to college and all the rest. But what you do learn is that at the end of the day, that it's pragmatic part. It's the thoughtful part. It's that humble part of being a woman with those experience that helps drive that. So my wife, who's an obstetrician gynecologist, a high risk obstetrician gynecologist, and a a and a adamant defender of a woman's right to make a decision with her body and who's Catholic, recognizes that if you trust a woman, she's gonna make the right decision with regard to that pregnancy. You don't have to worry about politics and you don't have to worry about men. Let that woman make the [7:34] secretary? You know, Scott, quick story. When I graduated from Stanford undergrad, my parents finally revealed to me this notion they had, they said, you know, we didn't want to tell you this before you'd graduated, but when you started work, I started working in construction with my father at an early age. And they said, we were so afraid when you started working construction that you would be so enticed by the high wages of working as a laborer in construction, that you would never go on to college. Now you have to recognize that laborers in construction don't make a ton of money. But for my mom and dad, union wages, that was good money. And so they were concerned that with that good money, I'd say, hey, I don't need college. I, I can make it, make it go it the way it is. That was never a thought of my mind, but for them, what how, could they expect from me? What were, what were their desires from me? They just wanted me to get ahead and however that would be, they were fine with [9:20] office? Right after undergraduate studies, I went to work in the state Capitol as a fellow, a Senate fellow. And so I had the experience working in the state Capitol, enjoyed the policy work, went off to law school, went on to work in the Attorney General's office. And that policy work that I had done and working for a state legislator gave me a chance to meet a lot of folks in the Los Angeles area who, after I had worked for the Attorney General's office for about four years, came to me and said, Xavier, you, never indicated it, but if you're interested in running for office, we'd love to support you. And I had really not given it much thought, but when they posed it and said they'd help out, I, I said, well, let, let's try it. And it [10:26] Yeah, and Scott, I gotta correct you. I had, I had more than just some wins. I had almost all wins. [10:32] so? It was, it was up there, yeah. It was really high. And I mean, there were some significant wins, but what, what do I remember most? Which are the wins that I, I really appreciate being able to talk about. Well, today there are, the Affordable Care Act covers some 40 plus million Americans, and it covers even more Americans, if you wanna talk about those who have a pre-existing condition. But they have their own insurance. Pre-existing conditions are no longer allowable under federal law. So you cannot, as a insurance company, discriminate against an American who has a pre-existing health condition and deny them health insurance coverage. And so the ACA I was the Attorney General who took that case, defended the ACA against the Trump administration all the way to the Supreme Court and won the DACA program for Dreamers in, in America. And California has more dreamers than any other state. These [11:34] That's right. The DACA program created under the Obama administration. Trump tried to get rid of the program, the DACA program, and most people didn't think I could win because that was an executive order by President Obama. And so any president can take down an executive order, but I, I still sued claiming that the way Trump was doing it was not legitimate. And we went to the Supreme Court and I beat him again. And so those are two major victories. But the clean car standards that allow California to have a higher standard when it comes to vehicle emissions, we protected that healthcare access, reproductive care. We protected that. ICE intrusion forcing the state and our local law enforcement agencies to do ICE raids with ICE. We stopped them from forcing us to do that. I can go on. That's a long list. Yeah. Long, long list. [12:38] one. I didn't. I didn't in [12:49] Well, honestly, I had mentioned to the Biden team after the election, before he had become president, that they'd need and worry about asking me about something in the cabinet unless it was Attorney General. I was AG in California, I was having a really successful career as AG and I didn't expect that I would leave unless I saw something like US Attorney General in the offering. And so I said, no, so don't worry about coming to me. But when they offered a chance for me to serve as Secretary of Health and Human Services, having done so much work in Congress on healthcare, having as the Attorney General done so much work, reproductive health, ACA as a AG on health, I, I couldn't just look away and recognizing this is where people are amazed. The Department of Health and Human Services is massive. It is the largest public health enterprise in the world. It has a budget bigger than the Department of Defense. In fact, it has a budget bigger than the Department of Defense and the state of California combined. You do so much Medicare, Medicaid, the Affordable Care Act, NIH, FDA, CDC, So there's so much you do. I said to myself, what an opportunity. And I've always said, if I can make a bigger difference, that's where I'll be. [14:27] - Well, the, the, how should I put this? The launch and the directive for COVID, and remember when President Biden got the keys to the White House from President Trump on January, was it 21st? 2021, more than 4,100 Americans died that day alone. It was, we were in a real crisis. And so the Trump administration left us a mess. The Biden administration before being sworn in, was already on the job. And so they had assembled a team working out of the White House. So when I came in, in March of 2021, there was already a full fledged team working with our HHS personnel at the White House. And much of the decision making, as you would assume was gonna be done at the White House for the biggest peril that our country had faced in what, a [15:26] I, once I became secretary, I was included, I was part of those meetings, obviously, because most of the team working on this stuff, Dr. Fauci and the rest came out of HHS. But clearly the White House was really working with the president to make sure where we went. We executed, like, let's put it this way, HHS, I as secretary. We executed the Biden administration policy on COVID at eventually by the end of 2021, we migrated over the entire operation, which was at the Department of Defense over to the Department of Health and Human [16:34] No doubt I'm gonna have to do more social media, because that is the principle way to communicate today with so many people, including voters. And it's a lot less expensive than trying to do it simply through the TV networks and cable news. Those are the old fashioned ways. So absolutely, you gotta do more of that. But you're right. I, I am not the shiny object. I am not the flame thrower. [16:58] a whiteboard. I, what I do is I get my work. You know, I go back to what I said about my parents. They just wanted me to get my work done. Let your your, let your work product prove who you are. And that's what I've always done, is I've always let my work product prove who I am. And while the White House was calling so many of the shots on COVID, we were the ones at HHS who were executing. [17:57] done? You gotta fund it. I mean the, the, people California spoke and they're right. It's a hollow gesture to pass Prop 36 and not provide the funding for mental health services, drug addiction services. Because essentially what you're saying is you're gonna incarcerate all these folks. No, Californians are done with just putting people away behind bars. Cause they know they're eventually gonna get out, most of them. And so we'd rather have folks who are rehabilitated or who are provided the services, they need to stand up again. And that's what Prop 36 said. And so absolutely fund it. Yeah. And if you don't, find the money. Let's find the money. If that means we have to raise more money, revenue, then let's raise [19:09] Taxation policy should not be a one-time deal. And so the initiative that's on the ballot, I think rightfully targets the mega wealthy, the billionaires who have made a killing in California and haven't done their fair share. But you don't need tax policy to be a one-time shot because you need consistent, predictable revenue in order to manage a budget the size of the state of California. And so that's not tax policy. I'm saying that to you, not just because I don't believe that's the best way to do policy. I'm saying it to you because I was for 20 years on the Ways and Means committee in Congress, a tax policy writer. The Ways and Means committee does all the tax policy in the House of Representatives. Tax policy has to be predictable. It has to be stable. And it has to understand that it's interconnected with everything that goes on. And so we will have revenue, we will raise the revenue we need, but we'll do it in a predictable, stable fashion. [20:12] Well, I would say that baseline way to, to explain it to average California is to say if you are mega wealthy and you're paying at tax rates that are lower than a nurse, a teacher, a firefighter, a police officer, then you're gonna end up paying more when I'm governor because it's not Fair. How, [20:31] how So principally it would be looking at some of the passive income, some of the investment income where, which is where so many wealthy individuals make so much money and pay very low tax rates for that investment income. [20:49] Well the federal government could deal with it, but the feds are gonna keep that money that they raise through federal taxation. This is for state and we, we can do something very similar. [21:14] Yeah. I mean, what is it that Japan, China Europe, everybody can build high speed rail, but the fourth largest economy in the world, California can't, no, it's, that's not the problem. High speed rail makes sense. Talk to all those countries and all those communities that get to move around at fast speed on a train rather than have to always worry about getting on a plane. It absolutely works. It doesn't work though. If you launch a project, you don't have the full support of communities that are gonna be impacted. And the way those communities express that is by going to court and stopping your project over and over and over again. Litigation is expensive. Delays are expensive. And that's what we've encountered. So when I become governor, we're gonna get rid of all these delays in the litigation. I'll sit everybody down who's got some concerns and we will resolve it. But we're gonna build high-speed rail. [22:11] yeah. You know that, look, I found this in so many cases dealing with COVID, trying to get 50 states to be on one, one on one track with us on [22:21] COVID it's tough. 'cause remember the federal government doesn't run healthcare. States do. I had to get 50 states to be on the same page when it came to distribution of vaccines, distribution of paxlovid and all the treatments. It's tough, but you gotta sit everybody down and you don't do it mid-track. You do it at the beginning before you take off. Yeah. [23:20] Well, Scott, don't forget I litigated those policies. SB 54, the Values Act. We defended that in court against the Trump administration the first time that they came after us because of SB 54. And we beat him back. It is constitutional. The state has a right to police do policing authority, not the federal government. has a right to do immigration enforcement, but they don't have a right to do public safety. And what you find is that this ICE is doing far more than just trying to go after somebody for immigration law violations. It's become clear. That's why so, many Americans have now died at the hands of ICE. We will defend it, we will win. Because of the Constitution. ICE is not a policing authority in the state of California. They are an immigration enforcement authority and they must limit themselves to that. If they don't have a warrant, they don't have a basis to be going all over the place in California and just tracking down folks or stopping [24:57] Free Country Democracy. If that's what you think is the best way that you can leverage to stop an entity, a company from doing things that you think harm your neighbors or your state, go to it. I have no problems with that. You have every right to say that you don't have the the right to tell a company not to operate in California. But you could say to somebody, Hey, you should boycott that company because this is the way it operates. [25:24] I'm, I'm not going out there to search for their money. I'm not looking for their [25:30] it? I doubt they're gonna hand me a check. I was one of the guys that was suing on some of these activities. Fair [26:01] What counts is that the votes are counted and they're counted right. We want everyone to vote. And if that means that we're getting ballots that are coming in postmark timely, but coming in the day after or a few days after, so be it. We want your vote to count. If you're a, a soldier working abroad and you barely get your ballot in by postmarked in time, why don't, why would I try to keep your vote from counting? No, absolutely. So long as it's counted and it's counted right. Yeah. Amen. [27:03] Yeah. And gut punch, as I said, never expected it. But here's the thing, you know, whether it's as AG or Secretary of Health Human Services or it's governor, what matters isn't how close you are to someone or how long you work with someone. [27:23] The law is the law and no one is above the law. And so Did betrayal? [27:28] It was something I didn't expect to see. And what I will say is that having served as AG, the authorities have a, a obligation to investigate that thoroughly and then come to some conclusion and every chip fall where they may and, at that point, for me, it was one of those things where it's not what you expect, but again, you keep moving forward. [27:57] My mom's house. Do you [28:03] gosh. You want some Chile verde? Would you like some barbacoa? Would you like she makes a mean fried chicken. You know, it's my mom's house. My, my wife's pretty good too, although it's a little healthier than my mom. But yeah, if I want someone to eat some really good California cooking my mom's house. All right. When we come, [28:24] we

---
snapshot_id: 6d26a4a1-0191-503b-ac4c-bcbdd72ded15
source_kind: transcript
url: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7

# On the Record — Xavier Becerra (0f74219c-7d10-4d29-85fe-0f1d834df8a7) ## California Governor Debate - CNN (General Election) - OTR page: https://ontherecord.empowered.vote/meetings/5a98c7c9-d215-4c80-b403-844ad39fc5c7 - Video: (no video url) - Date on On the Record: 2026-09-30 - Kind: debate · Debate · - Linked races: bc936a36-287c-4ffd-abd8-5e4fd798bae5, bec5ef3b-095b-4d7d-9117-db81e407cb5e [0:26] Absolutely, he's wrong. Uh, what he would do is he would damage our state even further, make it harder for working families. He'd make it tough for folks like my parents who came to this country with, uh, with $12 and they settled in California. They were able to build the California dream, but they had to work hard. They needed to make sure that the government was, was there with them. If you start cutting taxes and Steve Hilton's plan actually goes beyond just, uh, the 150 ,000, he claims he'll try to cut. He wants to give the richest Californians, millionaires and billionaires, a 40 % tax cut. Which means, of course, he'll take it out of our schools, he'll take it out of healthcare, he'll take it out of housing and make the conditions even worse. We have to have sound policy, whether it's tax policy or spending policy, to make sure that we can bring our California dream back to life. Right now, we have a situation where if you start making tax breaks for the wealthiest, you damage our working families like my parents. Mr. Helton? [2:03] Again you're gonna hear a lot of stories a lot of new math a lot of alternative facts from Steve Hilton the math doesn't add up what he's talking about he's gonna have to take it out of somewhere it will come out of our schools 50 close to 40 % of our budget in California is for our schools and so Steve Hilton is talking about making taxes not just 150 ,000 but he's got a plan to give the wealthiest Californians a 40 % tax cut. [2:47] What I said is that you shouldn't [2:50] give the tax breaks to the folks who are making the most money in California. That's your plan. If you look at your plan, you're going to make across -the -board tax cuts. You're going to end up giving the wealthiest Californians, billionaires, a 40 % tax break, the biggest in California history. You only talk about the portion of about 150 ,000, but there's another aspect to it. You don't like to talk about that. No, I do. I'll tell you, I'm very [3:56] with Javier. What I wouldn't do, Steve, is try to convince the people of California that proposing Trump tax policies, promising Trump tax cuts, believing you're gonna get better results than Trump has gotten so far to date, That that is what isn't it the definition of insanity you do the same thing over and over again expecting different results Yes, you're using Trump's like voting Democrat promises you expect different results You're gonna end up with Trump results If you follow Steve Hilton's plans [6:36] We will the housing gap, I've said already that we have to at least double the rate of building of homes. How much can we do? It just depends. How much red tape can we cut? How fast can we try to expand down payment assistant programs? How fast can we make sure Wall Street isn't outbidding the teacher or the firefighter for a home in California? We have to make sure we don't let Wall Street investors buy homes over those people who are working hard in California. And the final thing I'll do is what I did when I was AG. I will enforce the law that requires local governments to build. Mr. Holman? [7:35] that if you like. You did nothing. [7:46] sued [7:47] the [7:47] of Huntington Beach, Steve. That's more red tape, not less. No, no. It's enforcing the law because Huntington Beach was not following state law which required it to encourage building in its community and so they were not following the law as attorney general i enforced the law and guess what we won because huntington beach was denying permits and we have to build and no locality should have the right to try to stop all of our people in california from having the housing they need even [11:00] If you listen closely, you can hear Donald Trump in that response by Steve Hilton. He's not interested in regulating AI. He's not interested in telling these companies, you have to protect not just our kids and not just in school, you have to protect our workers who are looking at the prospect of losing their jobs to AI. You're looking at public safety that may be in danger by having AI penetrate our privacy. You know, it's really interesting. The president got a pinky promise in this forum that he had with AI leaders. That's all he got. No comment. He could go ahead and start an illegal war in Iran. He could go ahead and tear down East Wing or the White House, but he can only get a pinky promise from the largest leaders of AI. That's not what we need. And Steve, it's not a gimmick to ask for guardrails. It's the real thing. You use the word gimmick. It's not a gimmick. We need real enforcement. [12:01] The reason you could trust me, Steve, is because I... How [12:07] You want to answer? The answer is the reason you could trust me is because I have sued Meta, I have sued Amazon, I have sued Google. I have sued these very companies. I have enforced the law against these companies, and I will continue to do so as governor. The difference between us, Steve, is I have a record of having done that. You just say the talk, but [13:02] First, let me correct the record. I have helped create millions of jobs during my service as a member of Congress in preserving the protection for the state of California when I was attorney general, when Trump was attacking us. And as Secretary of Health and Human Services, I expanded healthcare to more Americans, which required more doctors, more hospitals. So unlike what you've just said, Steve, the facts show that I've helped create jobs. But to your point, since when do I have to respond to politicians? I'm running for governor of California. I'm looking for the vote of California voters, not some politician in Washington, D .C. [13:56] Yeah, of course. And I would work with our local communities to make sure that we enforce. This, Dana, the standard I think is pretty straightforward. Having a data center, does that benefit the community they want to locate. If it doesn't benefit them, if they don't see it as an investment in their community, if all you're going to do is rob their energy and electricity and their water, that's not a good deal and we should say no. But if someone wants to come in and build a data center that creates more jobs in the community, adds more energy to our grid, and it actually protects and adds more water capacity, then let's talk. But it has to be good for the community. We can do that, but if you're Donald Trump and his endorsed candidate, you probably want to lay these guys and let them do whatever they want. [15:14] Maybe the difference here, Steve, is that I've gotten the endorsement of our law enforcement peace officers throughout the state of California because they think I'm gonna help public safety. I've gotten the support of carpenters and construction workers. I was a member of the construction field as well for a while before I got to become a lawyer. But what I'm saying to you is this, people who know my policies are supporting me because they think it'll be good for them in their communities creating jobs but pinky promises Steve is that all you can do is that all your your endorser Donald Trump can do to make sure AI safety reaches our communities a pinky promise [16:29] our peace officers and our carpenters and our teachers know that you think it's their fault that we haven't gotten control of these things. [18:44] Steve, you're running for governor of California and you'll enforce Trump's laws at the federal level, but you won't enforce state laws at our level. California welcomed you into California and you welcomed ICE mercenaries into our state in return. How does that, how do you square that? You know, you're an immigrant. I have fought all my life to make life better for immigrants, to represent them well, to defend them, to let them grow and build like my parents. But here's the problem I have with your policies. You seem to welcome immigrants who look like you but deport immigrants who look like me. We need to have a governor who will protect everyone who works hard. I don't need to stand here and listen to you say that you'll enforce Trump's laws but you won't enforce California state laws. [19:45] farm worker in California why only farm workers that's what you [20:27] Trump, Trump, because he is your supporter. You chased his endorsement. [20:32] you just said it too and your policy say it every day. Because you've got nothing to offer Californians except more of the same. Let's use your words. You said Trump's ICE [20:43] immigration policies in his raids were, your words, perfect. You said that every farm worker in California should be deported. Your words. That's simply not true. Those are your words, Steve. [21:07] Do you deny that you said that Trump's immigration raids are perfect? [21:11] All that he's got are these insults. Here's your chance to deny that you said Trump's [21:39] It is good to have a regulated system of immigrants to come into our country, including California. And that's something that I have always pushed for. It is bad when immigrants are being separated from their children. It's bad when immigrants are being killed indiscriminately. It's bad when US citizens are dying through these immigration raids. So let's have regulation of our borders. We have a right as a sovereign nation to do so. I have always been for that. I am not for violating the constitution. I am not for treating immigrants like animals. And I am for recognizing that immigrants lift up our state. They build it every day. And I say that as the son of immigrants, that what we should do is have an immigration reform that will allow us to decide who stays and who goes. But Steve thinks it's perfect to let ICE mercenaries come on into California. And he welcomes it, even though our state laws require that ICE follow federal immigration law. Helm. [23:43] those Retread Trump talking point with the New York Times that Trump and they want to pull it surprise 24 You've used those. [23:53] In fact, every candidate... It was your Democrat colleague, Antonio Gutierrez. Let's let Secretary [24:00] We could follow the rules, Steve. Let me answer the question. Trump left a system for care of these immigrant kids that had been dismantled. Because he doesn't want them here. He made it very clear. Remember, he used to put kids in cages. He used to separate those children from their parents. We changed all that. I am proud of the record and all my life of working on immigration and in protecting immigrant children. What I won't do is do what you've done and welcome ICE raids so they can come and separate kids from their parents that can kill people indiscriminately. I will not be part of that and the record speaks for itself, Steve. You tried this before, it didn't work. You're gonna try it again because you have nothing else. Those aren't the facts, but you can peddle them if you'd like. [24:46] Mr. Helm. [25:22] that's what messing with [25:23] so once again these [25:27] misrepresentations that he's made of fact made of facts the the New York Times story didn't even go into those details about 480 someone the number keeps changing you said it was one one day, now it's another thing. Look, you could continue to do that. The fact remains, Donald Trump has a history of trying to deny immigrants their rights, abusing them, and he did that with kids. We changed that. I'm proud of the record we have when it came to providing care to these kids. What I will tell you is this, we need to fix a broken immigration system because no child should have to spend time in a detention center when they're three or four years of age. [27:43] Well let me unwrap this a bit here. Steve Hilton wants to put polluters in charge of our fossil fuels, of our move towards greener energy. He wants to let the industries decide at what pace and where and how do it. He wants to let Donald Trump take oil leases out of our coast, on our coast. He wants to, he said it himself, drill baby drill. He wants to drill baby drill along the coast of California. Steve, you weren't living here in California at the time, you weren't living in America at the time. We went through that experience. We don't want to see our coastline damaged. And talking about firefighters, Steve, your policy that gives that 40 ,000, 40 % tax cut to the wealthiest, you're going to cut firefighters from fighting [28:29] wildfires. [28:57] $2 more than it was when Donald Trump started the war in Iran. Just tell them [29:01] number. [29:02] It's over $6 a gallon. The national average. [29:05] The national average is over $4 a gallon. What is it exactly? Do you know? It is over... You can't give an exact number because... [29:14] Yeah. And so what I would tell you is this, Steve, more when it comes to diesel if you didn't have Trump's policies on the Iran War. Gentlemen, I'm... That's caused major pain for folks, but if I can answer on this wildfire issue, [29:28] Steve, you just called firefighters bureaucrats, these are the folks that are on the front line fighting fires and you're saying we should go ahead and get rid of them, cut them because they're bureaucrats. No, I'm saying we should call them bureaucrats [30:22] because as attorney general I demanded accountability and I will make sure that as governor I will demand accountability of our local governments who have control of the streets in their cities and in their counties what we will do is we will make sure the encampments are cleared we will make sure that we are enforcing the law because we have a right to make sure that those encampments are cleared we're gonna make sure that we tackle what is one of the major issues that it's involved with these folks who or staying in the streets. Mental health and substance use addiction. We have to be serious about tackling that. And the thing I'll do most because it's so important to work with the cities and the counties to tackle the streets and remove people from the streets and find them shelter. But as a state leader, I can make sure that we're providing the investments it takes to make sure any California who may be by some medical emergency or unexpected loss of a job is now on the verge of losing their home. I want to help them because it's easier to help you stay in your home than pulling you off the streets and trying to get you upright again. It costs way more to let them get on the streets. [32:08] And I guess Steve, you give Donald Trump an A for having denied our local governments the funding they need to tackle the homelessness crisis. Donald Trump has this habit of holding dollars from the state of California. Californians pay more in taxes to the federal treasury than any other state. Yet Donald Trump keeps holding our money back. He's holding money back for homelessness. He's holding 30 billion dollars hostage for the victims and survivors of the Altadena and Pacific Palisades fires because he wants his way on voting. He wants to restrict voting so he won't give that money up until we change our laws. [32:45] That chance, we're gonna fight to get our 30 billion for our victims and our survivors and we're gonna keep our people voting. [33:20] You've got to correct the record. Steve Hilton is saying that the $30 billion is being held up by the state. What about the $2 .5 billion that Gavin Newsom... I said $30 billion. You just said that in the state. Jake, let's clarify this because there are families here in LA who are still waiting for their assistance. From Gavin Newsom? and 30 billion dollars talk to any member of Congress, Republican or Democrat, 30 billion is waiting to go to Pacific Palisades and Altadena. Donald Trump doesn't wanna let it go because Donald Trump isn't getting his way on elections. [34:18] I'm going to vote no. I said that very clearly from the very beginning. Not because I don't agree with so many Californians who think that billionaires haven't paid their fair share because they haven't. It's that this is not the way to do tax policy. I'm the only one on the stage who's done tax policy. I'm the for working families I did it for making construction of affordable housing more easier to do I've done it for families with children I've given tax cuts I've also had to deal with raising revenue and what you don't do is you don't have a policy where it's a one -time tax and it isn't predictable and sustainable we need to have policy that everyone sees is fair it will sustain us going forward because we need to pay for our schools we need to pay for health care we need to pay for housing and we have to make it so that everyone is willing to do it. But no doubt, billionaires in California, too many of them are not paying their fair share. When you can pay a tax rate lower than a teacher, a firefighter, a nurse, you're not paying your fair share. [37:36] Thank you, sir secretary Sarah, I love these stories Steve you spin them all the time I guess it's from your experience being a talking head on Fox News You're so good at that even though they're not factual even they have nothing to do with reality Did Karen Bassett say that? Can we make sure that we don't get interrupted when we try to give responses? That was part of the rule, Steve. It would be helpful if you stopped interrupting. And I hope that's not gonna count against my time. Well, keep going, sir. Okay, so [38:03] Prop 39 is on the ballot. Prop 39 is an initiative that is backed by Donald Trump. He couldn't get his save act out of Congress, which tries to interfere in elections, so he's gone around the country and put initiatives on the ballot. In California, it's Prop 39. Steve Hilton is supporting the Trump back prop 39 that would make it hard for California's to vote We have to all vote no on 39 to send a clear message to Donald Trump and Steve Hilton that we want people to vote We don't want to make it tougher for them to vote mr. [41:23] You said I learned a lot today. Same here. [46:15] Dana, we had nearly eradicated measles. When I left HHS, you rarely heard of a case of measles. You rarely heard of a case of someone dying of measles. Today, children are dying of measles. Today, the spread of measles has reached a proportion we haven't seen since the 1960s, I believe. That's what happens when vaccine deniers take over. And this is what'll happen to California if you let someone who is willing to promote that type of attitude become governor of the state of California. We can't reward those who are willing to let families die. We know vaccines work. And we should continue to enforce, make it possible for us to have the vaccines available. Actually, I have to mention real quickly that one thing that Steve said is absolutely untrue. [47:03] We never forced anyone to get a vaccine. We don't have the power to do that at HHS, Steve. If you knew the law, you would recognize that. The states have the authority to decide who gets vaccinated in their states. Thank you, sir. Mr. [47:14] Did you give [47:26] Falsely. We didn't suggest that. The medical professionals who helped develop the vaccine And then he spoke out against it. Are the ones that decided what we should do with the vaccines, including for children. We never made a vaccine available for a child until the medical professionals and the science community said it was safe. You should know that because your friend, Donald Trump's HHS, oversees those agencies that make those decisions with working with the states. [48:25] We followed the science. This is the problem when you have politicians dictating what we should do in healthcare. When you have politicians telling the medical experts what we should do like on vaccines. We stayed away from trying to force anyone to do anything especially if it didn't follow the medical science. You are willing to let Donald Trump force people to follow your dictates. It's just like with a woman's right to choose whether she should have an abortion. You wanna be able to dictate whether or not a woman should be able to have an abortion. Let's stay with the [50:22] This is what happens when you get to use your own facts, these alternative facts that don't relate to the actual situation at hand. I won't get into it because I don't have enough time, but what I will tell you is this. In rural California, we're going to have hospitals closed. We're going to have community health centers closed. Doctors won't be able to provide services because of Donald Trump's cuts to pay for tax breaks for billionaires and large corporations. that trillion -dollar cut to health care, we're gonna make sure we don't kick people off of health care because it's not what you should do for families who need health care, and it's not what you should do to those providers, those doctors and those hospitals and those clinics that are willing to stay open, but they need to get paid. [51:12] So if he's gonna let me answer the question, I will answer it, because when I was secretary of healthy human services, we had a state, Georgia, that did have work requirements. And what we found was that the way Georgia was implementing those work requirements, it was kicking people off of Medicaid unjustly who did qualify for it. And so if you're gonna make these requirements that make people jump these hurdles when they do qualify for medical benefits, then you better make sure you do it right. And so this is gonna be a requirement that I as governor will have to work with and I will make it work because I'm not gonna kick people off of the health care rules. [52:28] Jake, first, we've lost some 50 ,000 jobs in Los Angeles and California from the film and movie industry. these are middle -class jobs. I'm not talking about the high -paid actors. I'm talking about the grips, the camera people, the people who build the sets. They make a decent living. Those jobs have left. We've got a fight to keep Hollywood in Hollywood and I've said I'll do everything I can to make sure that happens. Here's the rule. Pretty simple. If we give a tax credit, so long as we get more than one dollar back for that dollar in tax credit, we're to do it because Hollywood belongs here. We don't want it to be in Sydney, Australia. It shouldn't be Sydney wood. It shouldn't be in Toronto, Canada, not Toronto wood. It needs to be Hollywood and we'll fight to keep Hollywood business in Hollywood and in California. [54:10] First, he says that I have done nothing on Hollywood. I was in Congress, I was part of the team that enacted the first federal tax credit for film and movie production. So Steve, I was there 20 years ago when you weren't even in California. Secondly, when it comes to this water issue, quit using false statements. I won that case in court on water, not because I was trying to protect little fish. It's because Donald Trump was trying to impose his standards on California when it comes to water infrastructure. We have a right to make sure water in California is regulated by California. I sued and [55:11] We don't see our education system well coordinated. It is not working well. There's too much compliance required. What we have to do is make sure before we pass a child on, we're making sure that they are at grade level. we have to provide the tutoring that they need, we have to start earlier, we've started transitional kindergarten which gets a four -year -old into our schools, but too often when they're one, two, and three years of age, they're not being ready, prepared to get into our school system. So I would fight to make sure that we're working with our teachers because they're the most important people that will make sure their success for this child. I'll make sure that every public dollar, taxpayer dollar that we put in our schools and nine out of 10 kids in California go to public schools, that those taxpayer dollars stay in our public schools. Steve Hilton wants to send those public taxpayer dollars to private for -profit schools, not on my watch. We wanna make sure we let community schools thrive. Steve Hilton would kill those community schools by taking the money out of those communities and sending it to private for -profit institutions. We're not doing that. [57:01] Secretary Becerra? Well, he attacks teachers. He's made that very clear. He doesn't like teachers. I believe that the people who are supposed to train our kids should be treated like professionals. They are underpaid compared to professionals with similar education levels. He attacks them. He says they're doing the wrong thing for our kids. These are the people we put our children's futures in. We should treat them like real professionals and reward them like real professionals. That's what I'll do. Mr. Pelton.