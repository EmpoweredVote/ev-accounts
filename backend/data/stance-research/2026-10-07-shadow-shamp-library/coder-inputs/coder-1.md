You are stance coder 1. You code evidence against the codebook below. You do not search,
fetch or verify anything: every source you may use is in this message, and code checks your
labels afterwards. If the evidence a row needs is named but not included here, put it in
needs_source instead of guessing.

Use only the Write tool, exactly once, to write /Users/chrisandrews/Documents/GitHub/ev-accounts-gold20/backend/data/stance-research/2026-10-07-shadow-shamp-library/labels/coder-1.json. Write JSON only, matching
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

politician_id: 687e6f07-f71a-41b4-8525-b509b2cebb42  office_id: 2aed98f5-ab9e-49d3-b6be-e8fd257518cd
Janae Shamp — State Senator, Arizona (seated, level: state)
Current term: 2023-01-02 (precision: day) to present

## Topics (served ladder text — code against these words only)

### topic_key: education-library-books
topic_id: 1fcff1e8-c913-4d97-91da-1145952d7c65  served_revision_id: f480f827-cb1f-4a2e-83cd-bef8763948b8
Question: How should schools handle challenges to books in libraries and classrooms?
  1. Keep every book available and let professional librarians and educators curate the collection
  2. Keep challenged books available to all, while letting parents limit what their own child can borrow
  3. Remove a challenged book only if a review committee of educators and parents finds it unsuitable
  4. Pull any book a parent challenges until it has been reviewed
  5. Remove any book a parent or community member reports as inappropriate, for all students

#### Annex

# education-library-books — served revision f480f827-cb1f-4a2e-83cd-bef8763948b8 (Season 2)

**Status:** draft (2026-10-01). Lines marked _(proposed)_ are a drafter's reading, not yet ruled;
lines marked _(ruled 2026-10-01)_ carry an operator ruling (Chris Andrews). No
`_owed:_` line is open.

**Question:** "How should schools handle challenges to books in libraries and classrooms?"

**Orientation:** standard. Rung 1 keeps every book and leaves selection to professionals; rung 5
removes a book on any report. The rungs order **what a challenge does to access**: nothing, a limit
for one child, removal after a review finding, removal during review, removal on report.

**Levels with a lever:** local, school, state. The lever is the school board's
reconsideration policy and the state statute that sets the challenge process. A city or county
council governs public libraries, not school libraries → `adjacent` unless the act covers school
collections _(proposed)_.

**Asked at:** federal, state, local, school (`compass_topic_roles`, CA_0302). Own words only at: federal (codebook V2 "No-lever level").

**Synonyms:** "reconsideration policy", "request for reconsideration", "challenged material",
"review committee", "media specialist", "collection development", "weeding", "harmful to minors",
"obscene", "sexual conduct", "freedom to read", "Library Bill of Rights", "parental opt-out",
"restricted list", "classroom library".

1. **"Keep every book available and let professional librarians and educators curate the
   collection"**
   - Means: a challenge does not remove a book; trained librarians and educators decide what the
     collection holds.
   - Operative clauses: [a] challenged books stay available; [b] selection and removal stay with
     professional librarians and educators.
   - Establishing evidence looks like: own words that reject removal on challenge and leave
     selection to professionals; an act that forbids removing books because of their ideas or
     content **and** places selection with professional staff. Routine weeding by professionals
     (worn, outdated) does not contradict [a] _(proposed)_.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 3 because a "freedom to read" act often forbids removal for
     viewpoint but keeps a review process that can remove on other grounds. If a review can still
     remove a challenged book → not [a]; code the review process (rung 3 or 4) _(proposed)_.
   - [a] is an "every" clause: an act that names no removal rule has not said books stay (V4.2
     "Silence is not a clause").

2. **"Keep challenged books available to all, while letting parents limit what their own child can
   borrow"**
   - Means: challenged books stay on the shelf for everyone, and a parent may restrict only their
     own child's borrowing.
   - Operative clauses: [a] challenged books stay available to all; [b] a parent may limit their
     own child's borrowing. Compound: one side only → `compound-partial` (V4.2).
   - Establishing evidence looks like: a policy with a parent-restriction (opt-out) list **and** a
     rule that a challenge does not remove the book for others.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 1 because both keep books. A parent-restriction list meets [b];
     rung 1 has no parent limit.
   - A parent-restriction list beside a review that can remove books for everyone → not [a]; code
     the review process _(proposed)_.

3. **"Remove a challenged book only if a review committee of educators and parents finds it
   unsuitable"**
   - Means: a challenged book stays until a committee of educators and parents reviews it and finds
     it unsuitable; only that finding removes it.
   - Operative clauses: [a] removal only after a review finds the book unsuitable; [b] the reviewer
     is a committee of educators **and** parents. Compound: one side only → `compound-partial`
     (V4.2).
   - Establishing evidence looks like: a reconsideration policy or statute that requires a review
     finding before removal **and** names a committee whose members include educators and parents.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - A process that removes a book after a review finding, but names a different reviewer (the
     board alone, an administrator, a librarian, a state agency) or does not say who reviews → [a]
     only → BLANK `compound-partial`.
   - A committee that recommends while the board decides meets [b] when **the board may remove a book
     only on the committee's finding** (it may keep a book against the committee). If the board can
     remove against the committee's recommendation, [b] fails → `compound-partial` _(ruled 2026-10-01)_.
   - Commonly confused with rung 4 because both review. If the book is pulled **during** the review,
     it is rung 4, not rung 3.

4. **"Pull any book a parent challenges until it has been reviewed"**
   - Means: a parent's challenge removes the book at once, for the time the review takes.
   - Operative clauses: [a] any parent challenge triggers removal; [b] the removal lasts until the
     review ends.
   - Establishing evidence looks like: operative text that removes or restricts a challenged book
     from the filing of the challenge until the review decides.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - [a] is an "any" clause. Removal pending review only for some challenges (for example only for a
     named content category) does not meet [a] → `direction-only` _(proposed)_.
   - A policy silent on access during review does not reach rung 4 (V4.2).

5. **"Remove any book a parent or community member reports as inappropriate, for all students"**
   - Means: a report alone removes the book for every student; no review finding is needed.
   - Operative clauses: [a] a report removes the book, with no review finding; [b] a parent or a
     community member may report; [c] the removal applies to all students.
   - Establishing evidence looks like: operative text that removes a reported book without a review
     finding.
   - Levels that hold a lever: state; school.
   - Known chair-shaped instruments: _(none on file)_.
   - Commonly confused with rung 4 because both remove on challenge. Rung 4's removal ends when a
     review decides; rung 5's does not depend on a review.

**Hard cases:**
- **Content standards.** An act that orders removal of every book meeting a statutory content test
  ("harmful to minors", described sexual conduct) sets **what** may be removed, not what a challenge
  does. Code the process it uses to decide (rung 3, 4 or 5); a content test with no process named →
  `direction-only` _(proposed)_.
- **State law and school boards.** A state law that sets the challenge process for every district
  states the rule → `on-question`. A law that only decides which body hears challenges (state board
  or district) → `adjacent` (V2, H12) _(ruled 2026-10-01)_ A state law is the legislator's act, not a school-board member's..
- **Removing a legal defence** for librarians or teachers (criminal liability for distributing
  material) → `direction-only` _(proposed)_.
- **Ratings, labels, vendor rules and checkout-record access** for parents → `adjacent` _(proposed)_.
- **Assigned texts in a course** are in scope ("classrooms"). A curriculum standard that names no
  challenge process → `adjacent` (curriculum has its own topic).
- **A vote on one book.** A board vote to keep or remove one title shows the person's act on that
  title, not the process → `direction-only`, unless the vote adopts or applies a stated process
  _(proposed)_.
- **Budget or omnibus votes** → V4 `multi-subject`.


## Sources

---
snapshot_id: a3b413d2-e1a1-5333-b0ca-c259e5dbfdd8
source_kind: public-record
url: https://apps.azleg.gov/BillStatus/BillOverview?SessionID=127&BillNumber=SB1700#senate-third

Senate Third Reading - SB1700 schools; school libraries; books; prohibition Action Date Action Vote 03/20/2023 Passed 16-12-2-0-0 ALSTON N BENNETT Y BORRELLI Y BURCH NV CARROLL Y DIAZ N EPSTEIN N FARNSWORTH Y FERNANDEZ N GABALDÓN N GONZALES NV GOWAN Y HATATHLIE N HERNANDEZ N HOFFMAN Y KAISER Y KAVANAGH Y KERN Y KERR Y MARSH N MENDEZ N MESNARD Y MIRANDA N ROGERS Y SHAMP Y SHOPE Y SUNDARESHAN N TERÁN N WADSACK Y PETERSEN Y [Vote detail dialog for SB1700 (2023) Senate Third Reading, saved by browser from apps.azleg.gov BillStatus on 2026-10-07.]

---
snapshot_id: 7dd05169-48e0-58e4-a021-42a191f1b4d9
source_kind: public-record
url: https://www.azleg.gov/legtext/56leg/1R/bills/SB1700S.htm

SB1700 - 561R - S Ver Senate Engrossed schools; school libraries; books; prohibition State of Arizona Senate Fifty-sixth Legislature First Regular Session 2023 SENATE BILL 1700 An Act amending sections 15-102, 15-113 and 15-189.07, Arizona Revised Statutes; amending title 15, chapter 2, article 2, Arizona Revised Statutes, by adding section 15-249.01; amending sections 15-341, 15-362, 15-721 and 15-722, Arizona Revised Statutes; relating to public schools. (TEXT OF BILL BEGINS ON NEXT PAGE) Be it enacted by the Legislature of the State of Arizona: Section 1. Section 15-102, Arizona Revised Statutes, is amended to read: START_STATUTE 15-102. Parental involvement in the school; definition A. Each school district governing board, in consultation with parents, teachers and administrators, shall develop and adopt a policy to promote the involvement of parents and guardians of children enrolled in the schools within the school district, including: 1. A plan for parent participation in the schools that is designed to improve parent and teacher cooperation in such areas as homework, attendance and discipline. The plan shall provide for the administration of a parent-teacher satisfaction survey. 2. Procedures by which parents may learn about the course of study for their children and review learning materials, including the source of any supplemental educational materials. 3. Beginning January 1, 2023, procedures by which parents have access to the school's library collection of available books and materials and parents may receive a list of books and materials borrowed from the library by their children. [deleted: The policy must provide that the following are exempt from the procedures prescribed pursuant to this paragraph: (a) Schools without a full-time library media specialist or an equivalent position. (b) School district libraries that have agreements with county free library districts, municipal libraries or other entities pursuant to section 15-362, subsection D.] 4. Procedures by which parents who object to any learning material or activity on the basis that the material or activity is harmful may withdraw their children from the activity or from the class or program in which the material is used. Objection to a learning material or activity on the basis that the material or activity is harmful includes objection to the material or activity because it questions beliefs or practices in sex, morality or religion. 5. If a school district offers any sex education curricula pursuant to section 15-711 or 15-716 or pursuant to any rules adopted by the state board of education, procedures to prohibit the school district from providing sex education instruction to a [deleted: pupil] student unless the [deleted: pupil's] student's parent provides written permission for the [deleted: child] student to participate in the sex education curricula. 6. Procedures by which parents will be notified in advance of and given the opportunity to opt their children in to any instruction, learning materials or presentations regarding sexuality, in courses other than formal sex education curricula. 7. Procedures by which parents may learn about the nature and purpose of clubs and activities that are part of the school curriculum, extracurricular clubs and activities that have been approved by the school. 8. Procedures by which parents may learn about parental rights and responsibilities under the laws of this state, including the following: (a) The right to opt in to a sex education curriculum if one is provided by the school district. (b) Open enrollment rights pursuant to section 15-816.01. (c) The right to opt out of assignments pursuant to this section. (d) The right to opt out of immunizations pursuant to section 15-873. (e) The promotion requirements prescribed in section 15-701. (f) The minimum course of study and competency requirements for graduation from high school prescribed in section 15-701.01. (g) The right to opt out of instruction on acquired immune deficiency syndrome pursuant to section 15-716. (h) The right to review test results pursuant to section 15-743. (i) The right to participate in gifted programs pursuant to section 15-779.01. (j) The right to access instructional materials pursuant to section 15-730. (k) The right to receive a school report card pursuant to section 15-746. (l) The attendance requirements prescribed in sections 15-802, 15-803 and 15-821. (m) The right to public review of courses of study, textbooks and library books and materials pursuant to sections 15-721 and 15-722. (n) The right to be excused from school attendance for religious purposes pursuant to section 15-806. (o) Policies related to parental involvement pursuant to this section. (p) The right to seek membership on school councils pursuant to section 15-351. (q) Information about the student accountability information system as prescribed in section 15-1041. (r) The right to access the failing schools tutoring fund pursuant to section 15-241. (s) The right to access all written and electronic records of a school district or school district employee concerning the parent's child pursuant to section 15-143. ( t ) The right to review and request the removal of a book that is available to students in the library or that will be used for classroom instruction pursuant to sections 15-113, 15-721 and 15-722. B. The policy adopted by the governing board pursuant to this section may also include the following components: 1. A plan by which parents will be made aware of the district's parental involvement policy and this section, including: (a) Rights under the family educational rights and privacy act of 1974 (20 United States Code section 1232g) relating to access to children's official records. (b) The parent's right to inspect the school district policies and curriculum. 2. Efforts to encourage the development of parenting skills. 3. Communicating to parents techniques that are designed to assist the child's learning experience in the home. 4. Efforts to encourage access to community and support services for children and families. 5. Promoting communication between the school and parents concerning school programs and the academic progress of the parents' children. 6. Identifying opportunities for parents to participate in and support classroom instruction at the school. 7. Efforts to support, with appropriate training, parents as shared decision-makers and to encourage membership on school councils. 8. Recognizing the diversity of parents and developing guidelines that promote widespread parental participation and involvement in the school at various levels. 9. Developing preparation programs and specialized courses for certificated employees and administrators that promote parental involvement. 10. Developing strategies and programmatic structures at schools to encourage and enable parents to participate actively in their children's education. C. The governing board may adopt a policy to provide to parents the information required by this section in an electronic form. D. A parent shall submit a written request for information pursuant to this section during regular business hours to either the school principal at the school site or the superintendent of the school district at the office of the school district. Within ten days after receiving the request for information, the school principal or the superintendent of the school district shall either deliver the requested information to the parent or submit to the parent a written explanation of the reasons for denying the requested information. If the request for information is denied or the parent does not receive the requested information within fifteen days after submitting the request for information, the parent may request the information in writing from the school district governing board, which shall formally consider the request at the next scheduled public meeting of the governing board if the request can be properly noticed on the agenda. If the request cannot be properly noticed on the agenda, the governing board shall formally consider the request at the next subsequent public meeting of the governing board. E. For the purposes of this section, "parent" means the natural or adoptive parent or legal guardian of a minor child. END_STATUTE Sec. 2. Section 15-113, Arizona Revised Statutes, is amended to read: START_STATUTE 15-113. Rights of parents; public educational institutions; objectionable materials and books; definitions A. A parent of a student in a public educational institution has the right to review learning materials and activities in advance[deleted: .] and may take the following actions: 1. A parent who objects to any learning material or activity on the basis that the material or activity is harmful may request to withdraw that parent's student from the activity or from the class or program in which the material is used and request an alternative assignment. 2. A parent who objects to a book that is available to students in the school library or that will be used for classroom instruction may request that the public educational institution remove the book from the library or classroom. B. A parent who objects to a book pursuant to subsection A, paragraph 2 of this section because the parent finds the book to be lewd or sexual in nature, to promote gender fluidity or gender pronouns or to groom children into normalizing pedophilia shall submit the book and the basis for the finding to the department of education pursuant to section 15-249.01. [deleted: B.] C. A charter school may require parents to waive the right to object to learning materials or activities pursuant to subsection A, paragraph 1 of this section as a condition of enrollment if the charter school provides a complete list of books and materials to be used each school year before the student enrolls. If the charter school introduces books or materials that were not disclosed [deleted: prior to] before the student's enrollment, the parent retains the right to object to those materials pursuant to subsection A of this section. [deleted: C.] D. A charter school may require that any request [deleted: to review learning materials or activities or to withdraw the student from learning materials or activities] pursuant to subsection A of this section be made in writing. [deleted: D.] E. A public educational institution shall obtain signed, written consent from a student's parent or guardian before doing either of the following: 1. Using video, audio or electronic materials that may be inappropriate for the age of the student. 2. Providing sex education instruction to the student. At the same time the public educational institution seeks consent, it shall inform the student's parent or guardian of the parent's or guardian's right to review the [deleted: instructional] learning materials and activities. [deleted: E.] F. For the purposes of this section: 1. "Objects to any learning material or activity on the basis that the material or activity is harmful" means objecting to the material or activity because of sexual content, violent content or profane or vulgar language. 2. "Public educational institution" means any of the following: (a) A school district, including its schools. (b) A charter school. (c) An accommodation school. (d) The Arizona state schools for the deaf and the blind. END_STATUTE Sec. 3. Section 15-189.07, Arizona Revised Statutes, is amended to read: START_STATUTE 15-189.07. Library collection; parental access; public review; objections; removal; prohibition A. Each charter school governing body shall do all of the following: 1. Beginning January 1, 2023, in consultation with parents, teachers and administrators, develop and adopt procedures by which parents have access to the charter school's library collection of available books and materials and may receive a list of books and materials borrowed from the library by their children. 2. Make available on the charter school's website for review by the public a list of all books and materials purchased after January 1, 2023 for any of the charter school's school libraries for a period of at least [deleted: sixty] one hundred and twenty days [deleted: after the purchase] BEFORE making the books and materials available to students . Each charter school site shall make available on the school's website for review by the public a list of all books and materials purchased after January 1, 2023 for the school library for a period of at least [deleted: sixty] one hundred and twenty days [deleted: after the purchase] before making the books and materials available to students . This paragraph does not apply to the purchase of a book or material that is intended to replace a lost or damaged book or material. 3. Ensure that each charter school site notifies the parents of each [deleted: pupil] student enrolled at the charter school site of the opening and closing dates of the public review required under paragraph 2 of this [deleted: section] subsection within seven school days before the opening date. [deleted: B. Charter school sites without a full-time library media specialist or an equivalent position are exempt from the requirements of this section and from any procedures adopted pursuant to this section.] B. A parent who objects to a book or material during the public review required under subsection A, paragraph 2 of this section may request that the charter school not make the book or material available to students. C. A parent who objects to a book or material during the public review required under subsection A, paragraph 2 of this section because the parent finds the book to be lewd or sexual in nature, to promote gender fluidity or gender pronouns or to groom children into normalizing pedophilia shall submit the book or material and the basis for the finding to the department of education pursuant to section 15-249.01. END_STATUTE Sec. 4. Title 15, chapter 2, article 2, Arizona Revised Statutes, is amended by adding section 15-249.01, to read: START_STATUTE 15-249.01. Prohibited books; list; parent objections; definition A. The department of education shall establish rules and procedures for establishing and maintaining a list of books that public educational institutions in this state are prohibited from using or making available to students, including procedures for parents to submit books to be included on the list. The department shall post the list on its website. B. A parent may submit a book to the department of education for inclusion on the list described in subsection A of this section if the parent finds the book to be lewd or sexual in nature, to promote gender fluidity or gender pronouns or to groom children into normalizing pedophilia. The Department shall review each submission made by a parent, together with the basis for the parent's findings and, If the department agrees with the parent's findings, the department shall add the book to the list described in subsection A of this section. C. for the purposes of this section, "Book" includes a textbook, a library book and any other material made available to students in an electronic or print format. END_STATUTE Sec. 5. Section 15-341, Arizona Revised Statutes, is amended to read: START_STATUTE 15-341. General powers and duties; immunity; delegation A. The governing board shall: 1. Prescribe and enforce policies and procedures to govern the schools that are not inconsistent with the laws or rules prescribed by the state board of education. 2. Exclude from schools all books, publications, papers or audiovisual materials of a sectarian, partisan or denominational character or that are lewd or sexual in nature, that promote gender fluidity or gender pronouns or that groom children into normalizing pedophilia . This paragraph does not prohibit the elective course allowed by section 15-717.01. 3. Manage and control the school property within its district, except that a district may enter into a partnership with an entity, including a charter school, another school district or a military base, to operate a school or offer educational services in a district building, including at a vacant or partially used building, or in any building on the entity's property pursuant to a written agreement between the parties. 4. Acquire school furniture, apparatus, equipment, library books and supplies for the schools to use. 5. Prescribe the curricula and criteria for the promotion and graduation of pupils as provided in sections 15-701 and 15-701.01. 6. Furnish, repair and insure, at full insurable value, the school property of the district. 7. Construct school buildings on approval by a vote of the district electors. 8. In the name of the district, convey property belonging to the district and sold by the board. 9. Purchase school sites when authorized by a vote of the district at an election conducted as nearly as practicable in the same manner as the election provided in section 15-481 and held on a date prescribed in section 15-491, subsection E, but such authorization shall not necessarily specify the site to be purchased and such authorization shall not be necessary to exchange unimproved property as provided in section 15-342, paragraph 23. 10. Construct, improve and furnish buildings used for school purposes when such buildings or premises are leased from the national park service. 11. Purchase school sites or construct, improve and furnish school buildings from the proceeds of the sale of school property only on approval by a vote of the district electors. 12. Hold pupils to strict account for disorderly conduct on school property. 13. Discipline students for disorderly conduct on the way to and from school. 14. Except as provided in section 15-1224, deposit all monies received by the district as gifts, grants and devises with the county treasurer who shall credit the deposits as designated in the uniform system of financial records. If not inconsistent with the terms of the gifts, grants and devises given, any balance remaining after expenditures for the intended purpose of the monies have been made shall be used to reduce school district taxes for the budget year, except that in the case of accommodation schools the county treasurer shall carry the balance forward for use by the county school superintendent for accommodation schools for the budget year. 15. Provide that, if a parent or legal guardian chooses not to accept a decision of the teacher as provided in paragraph 42 of this subsection, the parent or legal guardian may request in writing that the governing board review the teacher's decision. This paragraph does not release school districts from any liability relating to a child's promotion or retention. 16. Provide for adequate supervision over pupils in instructional and noninstructional activities by certificated or noncertificated personnel. 17. Use school monies received from the state and county school apportionment exclusively to pay salaries of teachers and other employees and contingent expenses of the district. 18. Annually report to the county school superintendent on or before October 1 in the manner and form and on the blanks prescribed by the superintendent of public instruction or county school superintendent. The board shall also report directly to the county school superintendent or the superintendent of public instruction whenever required. 19. Deposit all monies received by school districts other than student activities monies or monies from auxiliary operations as provided in sections 15-1125 and 15-1126 with the county treasurer to the credit of the school district except as provided in paragraph 20 of this subsection and sections 15-1223 and 15-1224, and the board shall spend the monies as provided by law for other school funds. 20. Establish bank accounts in which the board during a month may deposit miscellaneous monies received directly by the district. The board shall remit monies deposited in the bank accounts at least monthly to the county treasurer for deposit as provided in paragraph 19 of this subsection and in accordance with the uniform system of financial records. 21. Prescribe and enforce policies and procedures for disciplinary action against a teacher who engages in conduct that is a violation of the policies of the governing board but that is not cause for dismissal of the teacher or for revocation of the certificate of the teacher. Disciplinary action may include suspension without pay for a period of time not to exceed ten school days. Disciplinary action shall not include suspension with pay or suspension without pay for a period of time longer than ten school days. The procedures shall include notice, hearing and appeal provisions for violations that are cause for disciplinary action. The governing board may designate a person or persons to act on behalf of the board on these matters. 22. Prescribe and enforce policies and procedures for disciplinary action against an administrator who engages in conduct that is a violation of the policies of the governing board regarding duties of administrators but that is not cause for dismissal of the administrator or for revocation of the certificate of the administrator. Disciplinary action may include suspension without pay for a period of time not to exceed ten school days. Disciplinary action shall not include suspension with pay or suspension without pay for a period of time longer than ten school days. The procedures shall include notice, hearing and appeal provisions for violations that are cause for disciplinary action. The governing board may designate a person or persons to act on behalf of the board on these matters. For violations that are cause for dismissal, the provisions of notice, hearing and appeal in chapter 5, article 3 of this title apply. The filing of a timely request for a hearing suspends the imposition of a suspension without pay or a dismissal pending completion of the hearing. 23. Notwithstanding sections 13-3108 and 13-3120, prescribe and enforce policies and procedures that prohibit a person from carrying or possessing a weapon on school grounds unless the person is a peace officer or has obtained specific authorization from the school administrator. 24. Prescribe and enforce policies and procedures relating to the health and safety of all pupils participating in district-sponsored practice sessions or games or other interscholastic athletic activities, including: (a) The provision of water. (b) Guidelines, information and forms, developed in consultation with a statewide private entity that supervises interscholastic activities, to inform and educate coaches, pupils and parents of the dangers of concussions and head injuries and the risks of continued participation in athletic activity after a concussion. The policies and procedures shall require that, before a pupil participates in an athletic activity, the pupil and the pupil's parent sign an information form at least once each school year that states that the parent is aware of the nature and risk of concussion. The policies and procedures shall require that a pupil who is suspected of sustaining a concussion in a practice session, game or other interscholastic athletic activity be immediately removed from the athletic activity and that the pupil's parent or guardian be notified. A coach from the pupil's team or an official or a licensed health care provider may remove a pupil from play. A team parent may also remove the parent's own child from play. A pupil may return to play on the same day if a health care provider rules out a suspected concussion at the time the pupil is removed from play. On a subsequent day, the pupil may return to play if the pupil has been evaluated by and received written clearance to resume participation in athletic activity from a health care provider who has been trained in evaluating and managing concussions and head injuries. A health care provider who is a volunteer and who provides clearance to participate in athletic activity on the day of the suspected injury or on a subsequent day is immune from civil liability with respect to all decisions made and actions taken that are based on good faith implementation of the requirements of this subdivision, except in cases of gross negligence or wanton or wilful neglect. A school district, school district employee, team coach, official or team volunteer or a parent or guardian of a team member is not subject to civil liability for any act, omission or policy undertaken in good faith to comply with the requirements of this subdivision or for a decision made or an action taken by a health care provider. A group or organization that uses property or facilities owned or operated by a school district for athletic activities shall comply with the requirements of this subdivision. A school district and its employees and volunteers are not subject to civil liability for any other person or organization's failure or alleged failure to comply with the requirements of this subdivision. This subdivision does not apply to teams that are based in another state and that participate in an athletic activity in this state. For the purposes of this subdivision, athletic activity does not include dance, rhythmic gymnastics, competitions or exhibitions of academic skills or knowledge or other similar forms of physical noncontact activities, civic activities or academic activities, whether engaged in for the purposes of competition or recreation. For the purposes of this subdivision, "health care provider" means a physician who is licensed pursuant to title 32, chapter 13, 14 or 17, an athletic trainer who is licensed pursuant to title 32, chapter 41, a nurse practitioner who is licensed pursuant to title 32, chapter 15, and a physician assistant who is licensed pursuant to title 32, chapter 25. (c) Guidelines, information and forms that are developed in consultation with a statewide private entity that supervises interscholastic activities to inform and educate coaches, pupils and parents of the dangers of heat-related illnesses, sudden cardiac death and prescription opioid use. Before a pupil participates in any district-sponsored practice session or game or other interscholastic athletic activity, the pupil and the pupil's parent must be provided with information at least once each school year on the risks of heat-related illnesses, sudden cardiac death and prescription opioid addiction. 25. Establish an assessment, data gathering and reporting system as prescribed in chapter 7, article 3 of this title. 26. Provide special education programs and related services pursuant to section 15-764, subsection A to all children with disabilities as defined in section 15-761. 27. Administer competency tests prescribed by the state board of education for the graduation of pupils from high school. 28. Ensure that insurance coverage is secured for all construction projects for purposes of general liability, property damage and workers' compensation and secure performance and payment bonds for all construction projects. 29. Keep in the personnel file of all current and former employees who provide instruction to pupils at a school information about the employee's educational and teaching background and experience in a particular academic content subject area. A school district shall inform parents and guardians of the availability of the information and shall make the information available for inspection on request of parents and guardians of pupils enrolled at a school. This paragraph does not require any school to release personally identifiable information in relation to any teacher or employee, including the teacher's or employee's address, salary, social security number or telephone number. 30. Report to local law enforcement agencies any suspected crime against a person or property that is a serious offense as defined in section 13-706 or that involves a deadly weapon or dangerous instrument or serious physical injury and any conduct that poses a threat of death or serious physical injury to employees, students or anyone on the property of the school. This paragraph does not limit or preclude the reporting by a school district or an employee of a school district of suspected crimes other than those required to be reported by this paragraph. For the purposes of this paragraph, "dangerous instrument", "deadly weapon" and "serious physical injury" have the same meanings prescribed in section 13-105. 31. In conjunction with local law enforcement agencies and emergency response agencies, develop an emergency response plan for each school in the school district in accordance with minimum standards developed jointly by the department of education and the division of emergency management within the department of emergency and military affairs. 32. Provide written notice to the parents or guardians of all students enrolled in the school district at least ten days before a public meeting to discuss closing a school within the school district. The notice shall include the reasons for the proposed closure and the time and place of the meeting. The governing board shall fix a time for a public meeting on the proposed closure not less than ten days before voting in a public meeting to close the school. The school district governing board shall give notice of the time and place of the meeting. At the time and place designated in the notice, the school district governing board shall hear reasons for or against closing the school. The school district governing board is exempt from this paragraph if the governing board determines that the school shall be closed because it poses a danger to the health or safety of the pupils or employees of the school. A governing board may consult with the division of school facilities within the department of administration for technical assistance and for information on the impact of closing a school. The information provided from the division of school facilities within the department of administration shall not require the governing board to take or not take any action. 33. Incorporate instruction on Native American history into appropriate existing curricula. 34. Prescribe and enforce policies and procedures: (a) Allowing pupils who have been diagnosed with anaphylaxis by a health care provider licensed pursuant to title 32, chapter 13, 14, 17 or 25 or by a registered nurse practitioner licensed and certified pursuant to title 32, chapter 15 to carry and self-administer emergency medications, including epinephrine auto-injectors, while at school and at school-sponsored activities. The pupil's name on the prescription label on the medication container or on the medication device and annual written documentation from the pupil's parent or guardian to the school that authorizes possession and self-administration is sufficient proof that the pupil is entitled to possess and self-administer the medication. The policies shall require a pupil who uses an epinephrine auto-injector while at school and at school-sponsored activities to notify the nurse or the designated school staff person of the use of the medication as soon as practicable. A school district and its employees are immune from civil liability with respect to all decisions made and actions taken that are based on good faith implementation of the requirements of this subdivision, except in cases of wanton or wilful neglect. (b) For the emergency administration of epinephrine auto-injectors by a trained employee of a school district pursuant to section 15-157. 35. Allow the possession and self-administration of prescription medication for breathing disorders in handheld inhaler devices by pupils who have been prescribed that medication by a health care professional licensed pursuant to title 32. The pupil's name on the prescription label on the medication container or on the handheld inhaler device and annual written documentation from the pupil's parent or guardian to the school that authorizes possession and self-administration is sufficient proof that the pupil is entitled to possess and self-administer the medication. A school district and its employees are immune from civil liability with respect to all decisions made and actions taken that are based on a good faith implementation of the requirements of this paragraph. 36. Prescribe and enforce policies and procedures to prohibit pupils from harassing, intimidating and bullying other pupils on school grounds, on school property, on school buses, at school bus stops, at school-sponsored events and activities and through the use of electronic technology or electronic communication on school computers, networks, forums and mailing lists that include the following components: (a) A procedure for pupils, parents and school district employees to confidentially report to school officials incidents of harassment, intimidation or bullying. The school shall make available written forms designed to provide a full and detailed description of the incident and any other relevant information about the incident. (b) A requirement that school district employees report in writing suspected incidents of harassment, intimidation or bullying to the appropriate school official and a description of appropriate disciplinary procedures for employees who fail to report suspected incidents that are known to the employee. (c) A requirement that, at the beginning of each school year, school officials provide all pupils with a written copy of the rights, protections and support services available to a pupil who is an alleged victim of an incident reported pursuant to this paragraph. (d) If an incident is reported pursuant to this paragraph, a requirement that school officials provide a pupil who is an alleged victim of the incident with a written copy of the rights, protections and support services available to that pupil. (e) A formal process for documenting reported incidents of harassment, intimidation or bullying and providing for the confidentiality, maintenance and disposition of this documentation. School districts shall maintain documentation of all incidents reported pursuant to this paragraph for at least six years. The school shall not use that documentation to impose disciplinary action unless the appropriate school official has investigated and determined that the reported incidents of harassment, intimidation or bullying occurred. If a school provides documentation of reported incidents to persons other than school officials or law enforcement, all individually identifiable information shall be redacted. (f) A formal process for the appropriate school officials to investigate suspected incidents of harassment, intimidation or bullying, including procedures for notifying the alleged victim and the alleged victim's parent or guardian when a school official or employee becomes aware of the suspected incident of harassment, intimidation or bullying. (g) Disciplinary procedures for pupils who have admitted or been found to have committed incidents of harassment, intimidation or bullying. (h) A procedure that sets forth consequences for submitting false reports of incidents of harassment, intimidation or bullying. (i) Procedures designed to protect the health and safety of pupils who are physically harmed as the result of incidents of harassment, intimidation and bullying, including, if appropriate, procedures to contact emergency medical services or law enforcement agencies, or both. (j) Definitions of harassment, intimidation and bullying. 37. Prescribe and enforce policies and procedures regarding changing or adopting attendance boundaries that include the following components: (a) A procedure for holding public meetings to discuss attendance boundary changes or adoptions that allows public comments. (b) A procedure to notify the parents or guardians of the students affected, including assurance that, if that school remains open as part of the boundary change and capacity is available, students assigned to a new attendance area may stay enrolled in their current school. (c) A procedure to notify the residents of the households affected by the attendance boundary changes. (d) A process for placing public meeting notices and proposed maps on the school district's website for public review, if the school district maintains a website. (e) A formal process for presenting the attendance boundaries of the affected area in public meetings that allows public comments. (f) A formal process for notifying the residents and parents or guardians of the affected area as to the decision of the governing board on the school district's website, if the school district maintains a website. (g) A formal process for updating attendance boundaries on the school district's website within ninety days after an adopted boundary change. The school district shall send a direct link to the school district's attendance boundaries website to the department of real estate. 38. If the state board of education determines that the school district has committed an overexpenditure as defined in section 15-107, provide a copy of the fiscal management report submitted pursuant to section 15-107, subsection H on its website and make copies available to the public on request. The school district shall comply with a request within five business days after receipt. 39. Ensure that the contract for the superintendent is structured in a manner in which up to twenty percent of the total annual salary included for the superintendent in the contract is classified as performance pay. This paragraph does not require school districts to increase total compensation for superintendents. Unless the school district governing board votes to implement an alternative procedure at a public meeting called for this purpose, the performance pay portion of the superintendent's total annual compensation shall be determined as follows: (a) Twenty-five percent of the performance pay shall be determined based on the percentage of academic gain determined by the department of education of pupils who are enrolled in the school district compared to the academic gain achieved by the highest ranking of the fifty largest school districts in this state. For the purposes of this subdivision, the department of education shall determine academic gain by the academic growth achieved by each pupil who has been enrolled at the same school in a school district for at least five consecutive months measured against that pupil's academic results in the 2008-2009 school year. For the purposes of this subdivision, of the fifty largest school districts in this state, the school district with pupils who demonstrate the highest statewide percentage of overall academic gain measured against academic results for the 2008-2009 school year shall be assigned a score of 100 and the school district with pupils who demonstrate the lowest statewide percentage of overall academic gain measured against academic results for the 2008-2009 school year shall be assigned a score of 0. (b) Twenty-five percent of the performance pay shall be determined by the percentage of parents of pupils who are enrolled at the school district who assign a letter grade of "A" to the school on a survey of parental satisfaction with the school district. The parental satisfaction survey shall be administered and scored by an independent entity that is selected by the governing board and that demonstrates sufficient expertise and experience to accurately measure the results of the survey. The parental satisfaction survey shall use standard random sampling procedures and provide anonymity and confidentiality to each parent who participates in the survey. The letter grade scale used on the parental satisfaction survey shall direct parents to assign one of the following letter grades: (i) A letter grade of "A" if the school district is excellent. (ii) A letter grade of "B" if the school district is above average. (iii) A letter grade of "C" if the school district is average. (iv) A letter grade of "D" if the school district is below average. (v) A letter grade of "F" if the school district is a failure. (c) Twenty-five percent of the performance pay shall be determined by the percentage of teachers who are employed at the school district and who assign a letter grade of "A" to the school on a survey of teacher satisfaction with the school. The teacher satisfaction survey shall be administered and scored by an independent entity that is selected by the governing board and that demonstrates sufficient expertise and experience to accurately measure the results of the survey. The teacher satisfaction survey shall use standard random sampling procedures and provide anonymity and confidentiality to each teacher who participates in the survey. The letter grade scale used on the teacher satisfaction survey shall direct teachers to assign one of the following letter grades: (i) A letter grade of "A" if the school district is excellent. (ii) A letter grade of "B" if the school district is above average. (iii) A letter grade of "C" if the school district is average. (iv) A letter grade of "D" if the school district is below average. (v) A letter grade of "F" if the school district is a failure. (d) Twenty-five percent of the performance pay shall be determined by other criteria selected by the governing board. 40. Maintain and store permanent public records of the school district as required by law. Notwithstanding section 39-101, the standards adopted by the Arizona state library, archives and public records for the maintenance and storage of school district public records shall allow school districts to elect to satisfy the requirements of this paragraph by maintaining and storing these records either on paper or in an electronic format, or a combination of a paper and electronic format. 41. Adopt in a public meeting and implement policies for principal evaluations. Before adopting principal evaluation policies, the school district governing board shall provide opportunities for public discussion on the proposed policies. The governing board shall adopt policies that: (a) Are designed to improve principal performance and improve student achievement. (b) Include the use of quantitative data on the academic progress for all students, which shall account for between twenty percent and thirty-three percent of the evaluation outcomes. (c) Include four performance classifications, designated as highly effective, effective, developing and ineffective. (d) Describe both of the following: (i) The methods used to evaluate the performance of principals, including the data used to measure student performance and job effectiveness. (ii) The formula used to determine evaluation outcomes. 42. Prescribe and enforce policies and procedures that define the duties of principals and teachers. These policies and procedures shall authorize teachers to take and maintain daily classroom attendance, make the decision to promote or retain a pupil in a grade in common school or to pass or fail a pupil in a course in high school, subject to review by the governing board in the manner provided in section 15-342, paragraph 11. 43. Prescribe and enforce policies and procedures for the emergency administration by an employee of a school district pursuant to section 36-2267 of naloxone hydrochloride or any other opioid antagonist approved by the United States food and drug administration. 44. In addition to the notification requirements prescribed in paragraph 36 of this subsection, prescribe and enforce reasonable and appropriate policies to notify a pupil's parent or guardian if any person engages in harassing, threatening or intimidating conduct against that pupil. A school district and its officials and employees are immune from civil liability with respect to all decisions made and actions taken that are based on good faith implementation of the requirements of this paragraph, except in cases of gross negligence or wanton or wilful neglect. A person engages in threatening or intimidating if the person threatens or intimidates by word or conduct to cause physical injury to another person or serious damage to the property of another on school grounds. A person engages in harassment if, with intent to harass or with knowledge that the person is harassing another person, the person anonymously or otherwise contacts, communicates or causes a communication with another person by verbal, electronic, mechanical, telephonic or written means in a manner that harasses on school grounds or substantially disrupts the school environment. 45. Each fiscal year, provide to each school district employee a total compensation statement that is broken down by category of benefit or payment and that includes, for that employee, at least all of the following: (a) Base salary and any additional pay. (b) Medical benefits and the value of any employer-paid portions of insurance plan premiums. (c) Retirement benefit plans, including social security. (d) Legally required benefits. (e) Any paid leave. (f) Any other payment made to or on behalf of the employee. (g) Any other benefit provided to the employee. 46. Develop and adopt in a public meeting policies to allow for visits, tours and observations of all classrooms by parents of enrolled pupils and parents who wish to enroll their children in the school district unless a visit, tour or observation threatens the health and safety of pupils and staff. These policies and procedures must be easily accessible from the home page on each school's website. B. Notwithstanding subsection A, paragraphs 7, 9 and 11 of this section, the county school superintendent may construct, improve and furnish school buildings or purchase or sell school sites in the conduct of an accommodation school. C. If any school district acquires real or personal property, whether by purchase, exchange, condemnation, gift or otherwise, the governing board shall pay to the county treasurer any taxes on the property that were unpaid as of the date of acquisition, including penalties and interest. The lien for unpaid delinquent taxes, penalties and interest on property acquired by a school district: 1. Is not abated, extinguished, discharged or merged in the title to the property. 2. Is enforceable in the same manner as other delinquent tax liens. D. The governing board may not locate a school on property that is less than one-fourth mile from agricultural land regulated pursuant to section 3-365, except that the owner of the agricultural land may agree to comply with the buffer zone requirements of section 3-365. If the owner agrees in writing to comply with the buffer zone requirements and records the agreement in the office of the county recorder as a restrictive covenant running with the title to the land, the school district may locate a school within the affected buffer zone. The agreement may include any stipulations regarding the school, including conditions for future expansion of the school and changes in the operational status of the school that will result in a breach of the agreement. E. A school district, its governing board members, its school council members and its employees are immune from civil liability for the consequences of adopting and implementing policies and procedures pursuant to subsection A of this section and section 15-342. This waiver does not apply if the school district, its governing board members, its school council members or its employees are guilty of gross negligence or intentional misconduct. F. A governing board may delegate in writing to a superintendent, principal or head teacher the authority to prescribe procedures that are consistent with the governing board's policies. G. Notwithstanding any other provision of this title, a school district governing board shall not take any action that would result in a reduction of pupil square footage unless the governing board notifies the school facilities oversight board established by section 41-5701.02 of the proposed action and receives written approval from the school facilities oversight board to take the action. A reduction includes an increase in administrative space that results in a reduction of pupil square footage or sale of school sites or buildings, or both. A reduction includes a reconfiguration of grades that results in a reduction of pupil square footage of any grade level. This subsection does not apply to temporary reconfiguration of grades to accommodate new school construction if the temporary reconfiguration does not exceed one year. The sale of equipment that results in a reduction that falls below the equipment requirements prescribed in section 41-5711, subsection B is subject to commensurate withholding of school district district additional assistance monies pursuant to the direction of the school facilities oversight board. Except as provided in section 15-342, paragraph 10, proceeds from the sale of school sites, buildings or other equipment shall be deposited in the school plant fund as provided in section 15-1102. H. Subsections C through G of this section apply to a county board of supervisors and a county school superintendent when operating and administering an accommodation school. I. A school district governing board may delegate authority in writing to the superintendent of the school district to submit plans for new school facilities to the school facilities oversight board for the purpose of certifying that the plans meet the minimum school facility adequacy guidelines prescribed in section 41-5711. J. For the purposes of subsection A, paragraph 37 of this section, attendance boundaries may not be used to require students to attend certain schools based on the student's place of residence. END_STATUTE Sec. 6. Section 15-362, Arizona Revised Statutes, is amended to read: START_STATUTE 15-362. Libraries; powers and duties; authority to contract A. The governing board of a school district may establish and maintain libraries. Such libraries shall be under control of the governing board. The governing board is accountable for the care of the libraries, but the board may appoint district librarians or put the libraries under the direct charge of a teacher or other qualified person. When requested, the governing board shall report on the libraries to the county school superintendent on forms supplied by the superintendent of public instruction. B. The governing board shall: 1. Enforce the rules prescribed for governing school libraries. 2. Exclude from school libraries all books, publications and papers of a sectarian, partisan or denominational character , or that are lewd or sexual in nature, that promote gender fluidity or gender pronouns or that groom children into normalizing pedophilia . This paragraph does not prohibit any materials for the elective course permitted by section 15-717.01. C. A district library is free to all pupils of suitable age who attend the school. Residents of the district may become entitled to library privileges by [deleted: payment of] paying fees and [deleted: compliance] complying with regulations prescribed by the governing board. The governing board may enter into a contract or agreement with the proper authorities of a county free library or other public library possessing facilities to render the desired service for the procurement of reference or other library books or the extension services of the library. The amount expended shall not exceed two percent of the total school district budget for the school year during which the services are [deleted: utilized] used . D. A school district governing board may enter into agreements with counties, county free library districts, municipal libraries, nonprofit and public libraries, tribal libraries, private schools and tribal schools in the county where the school district is located. END_STATUTE Sec. 7. Section 15-721, Arizona Revised Statutes, is amended to read: START_STATUTE 15-721. Common schools; course of study; textbooks; approval; selection; objections; removal; library books and materials; definition A. The governing board shall approve for common schools the course of study, the basic textbook for each course and all units recommended for credit under each general subject title before implementing the course. B. If any course does not include a basic textbook, the governing board shall approve all supplemental books used in the course before approving the course. C. If any course includes a basic textbook and uses supplemental books, the governing board may approve all supplemental books and teaching aids, including instructional computer software, that are used in the course before approving the course. [deleted: D. If the course includes a basic textbook and uses supplemental books that have not been approved by the governing board at the time of approval of the course, a teacher may use the supplemental books at any time during the school year. Use of the supplemental books shall be brought to the attention of the governing board during the school year in which they are added for ratification. E.] D. Notwithstanding any other law, subsections B and C of this section do not apply to supplemental books used in courses or programs instituted pursuant to article 4 of this chapter. [deleted: F.] E. The governing board shall: 1. Enforce the course of study and select all textbooks used in the common schools and purchase the textbooks from the publishers. The governing board may budget and spend district school monies for teaching aids, including instructional computer software. For courses that do not require that each student have a textbook other than for classroom instruction, the school district need only purchase one textbook for each student in the largest group that would be receiving classroom instruction at any one time. 2. Require that all meetings of committees authorized for the purposes of textbook review and selection be open to the public as prescribed in title 38, chapter 3, article 3.1. 3. Make available at the school district office for review by the public, for a period of [deleted: sixty] one hundred twenty days [deleted: prior to formal selection of] before selecting textbooks, a copy of each textbook that is being considered for selection. 4. Make available on the school district's website for review by the public a list of all books and materials purchased after January 1, 2023 for any of the district's school libraries for a period of at least [deleted: sixty] one hundred twenty days [deleted: after the purchase] before making the books and materials available to students . Each school operated by the school district shall make available on the school's website for review by the public a list of all books and materials purchased after January 1, 2023 for the school library for a period of at least [deleted: sixty] one hundred twenty days [deleted: after the purchase] before making the books and materials available to students . This paragraph does not apply to the purchase of a book or material that is intended to replace a lost or damaged book or material. 5. Ensure that each common school that is operated by the school district notifies the parents of each [deleted: pupil] student enrolled in the school of the opening and closing dates of the public review required under paragraph 4 of this subsection within seven school days before the opening date. 6. Allow parents to object to a book or material during the public review required under paragraph 4 of this subsection. A parent who objects to a book or material pursuant to this paragraph because the parent finds the book to be lewd or sexual in nature, to promote gender fluidity or gender pronouns or to groom children into normalizing pedophilia shall submit the book and the basis for the finding to the department of education pursuant to section 15-249.01. [deleted: G. The following are exempt from the requirements of subsection F, paragraphs 4 and 5 of this section: 1. Schools without a full-time library media specialist or an equivalent position. 2. School district libraries that have agreements with county free library districts, municipal libraries or other entities pursuant to section 15-362, subsection D. H.] F. For the purposes of this section, "textbook" means printed instructional materials or digital content, or both, and related printed or nonprinted instructional materials, that are written and published primarily for use in school instruction and that are required by a state educational agency or a local education agency for use by pupils in the classroom, including materials that require the availability of electronic equipment in order to be used as a learning resource. END_STATUTE Sec. 8. Section 15-722, Arizona Revised Statutes, is amended to read: START_STATUTE 15-722. High schools; course of study; textbooks; approval; objections; removal; library books and materials; definition A. The governing board shall approve for high schools the course of study and all units that are recommended for credit under each general subject title before implementing the course. B. The governing board shall approve for high schools the basic textbook for each course and may purchase the textbooks from the publishers if approved by the governing board. Before approving any basic textbook for high schools, the governing board shall do all of the following: 1. Provide information on the school district's website, if the school district maintains a website, on the basic textbooks that are proposed for approval. 2. Require that all meetings of committees authorized for the purposes of textbook review and selection be open to the public pursuant to title 38, chapter 3, article 3.1. 3. Provide an opportunity for public comment for at least [deleted: sixty] one hundred twenty days. Public comment may include written comments, oral comments and comments submitted through email. 4. Make available at the school district office for review by the public, for a period of at least [deleted: sixty] one hundred twenty days before approving the textbooks, a copy of each textbook that is being considered for approval. 5. Make available on the school district's website for review by the public a list of all books and materials purchased after January 1, 2023 for any of the district's school libraries for a period of at least [deleted: sixty] one hundred twenty days [deleted: after the purchase] before making the books and materials available to students . Each school operated by the school district shall make available on the school's website for review by the public a list of all books and materials purchased after January 1, 2023 for the school library for a period of at least [deleted: sixty] one hundred twenty days [deleted: after the purchase] before making the books and materials available to students . This paragraph does not apply to the purchase of a book or material that is intended to replace a lost or damaged book or material. 6. Ensure that each high school that is operated by the school district notifies the parents of each [deleted: pupil] student enrolled in the school of the opening and closing dates of the public review required under paragraph 5 of this subsection within seven school days before the opening date. 7. Allow parents to object to a book or material during the public review required under this subsection. A parent who objects to a book or material pursuant to this paragraph because the parent finds the book to be lewd or sexual in nature, to promote gender fluidity or gender pronouns or to groom children into normalizing pedophilia shall submit the book and the basis for the finding to the department of education pursuant to section 15-249.01. [deleted: C. The following are exempt from the requirements of subsection B, paragraphs 5 and 6 of this section: 1. Schools without a full-time library media specialist or an equivalent position. 2. School district libraries that have agreements with county free library districts, municipal libraries or other entities pursuant to section 15-362, subsection D. D.] C. If any course does not include a basic textbook, the governing board shall approve all supplemental books that are used in the course before usage. [deleted: E.] D. If any course includes a basic textbook and uses supplemental books or instructional computer software, the governing board may approve all supplemental books and instructional computer software that are used in the course before usage. [deleted: F. If the course includes a basic textbook and uses supplemental books that have not been approved by the governing board at the time of approval of the course, a teacher may use the supplemental books at any time during the school year. Use of the supplemental books shall be brought to the attention of the governing board during the school year in which they are added for ratification. G.] E. The governing board shall prescribe up to five textbooks for each course, and the teacher, with the consent of the governing board, may use any one of the prescribed textbooks for the purposes of the teacher's course. [deleted: H.] F. For the purposes of this section, "textbook" means printed instructional materials or digital content, or both, and related printed or nonprinted instructional materials, that are written and published primarily for use in school instruction and that are required by a state educational agency or a local education agency for use by pupils in the classroom, including materials that require the availability of electronic equipment in order to be used as a learning resource. END_STATUTE